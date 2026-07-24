extends Node2D
## Single-canvas world pass matching HTML draw() playfield body.
## Orchestrator only — drawers stay modular under scripts/render/drawers/.
## One shared CanvasCompat; entity nodes are data + collision only.
##
## HTML order (public/index.html function draw):
##   clip PF → shake → stage bg → boss ambience → power radiance → floaters →
##   mumus (+stun/charm) → burns → boss → clear gate → items → pshots → bullets →
##   phase veil → Bobina (dash/aura/full drawBobina or victory pose) →
##   fx/particles/melee/score/emotes → bomb flash → slowmo → collect line →
##   dialog → flashMsg → unclip → border

var ctx: RefCounted
var ported: RefCounted
var hud: RefCounted
var combat_fx: RefCounted
var item_draw: RefCounted
var bobina_cache: Node = null
var stage_bg_cache: Node = null
var tick: int = 0
var _bullet_pool: Node = null
var _last_tick: int = -1

func _ready() -> void:
	z_index = 0
	z_as_relative = false
	set_process(true)
	add_to_group("world_draw")
	ctx = load("res://scripts/render/CanvasCompat.gd").new()
	ctx.bind(self)
	ported = load("res://scripts/render/PortedDraw.gd").new()
	ported.setup(ctx)
	hud = load("res://scripts/ui/menu/draw_hud.gd").new()
	hud.setup(ctx)
	combat_fx = load("res://scripts/render/drawers/drawCombatFx.gd").new()
	combat_fx.setup(ctx)
	item_draw = load("res://scripts/render/drawers/drawItem.gd").new()
	item_draw.setup(ctx)
	# Phase 1.2: shared Bobina bake cache for playfield draws
	bobina_cache = get_node_or_null("BobinaDrawCache")
	if bobina_cache == null:
		bobina_cache = load("res://scripts/render/BobinaDrawCache.gd").new()
		bobina_cache.name = "BobinaDrawCache"
		add_child(bobina_cache)
	# Phase 1.3: amortize stage bg + motifs + StageBgFx (~15–20 Hz bake)
	stage_bg_cache = get_node_or_null("StageBgDrawCache")
	if stage_bg_cache == null:
		stage_bg_cache = load("res://scripts/render/StageBgDrawCache.gd").new()
		stage_bg_cache.name = "StageBgDrawCache"
		add_child(stage_bg_cache)
	call_deferred("_bind_pool")

func _bind_pool() -> void:
	var main := get_parent()
	if main:
		_bullet_pool = main.get_node_or_null("BulletPool")

func _process(_d: float) -> void:
	## Redraw gated on sim_frame (fixed 60 Hz source), not display rate.
	var nt := int(SimClock.sim_frame) if SimClock else tick + 1
	if nt == _last_tick:
		return
	# Phase 1.3: non-combat field states need less than 60 Hz
	if GameState.state in [GameState.State.SHOP, GameState.State.STAGE_CLEAR, GameState.State.INTRO]:
		if (nt % 3) != 0:
			return
	elif GameState.state == GameState.State.PAUSED:
		# World under pause is frozen — 6 Hz is enough for invuln flash residual
		if (nt % 10) != 0:
			return
	_last_tick = nt
	tick = nt
	if _is_playish():
		queue_redraw()

func _is_playish() -> bool:
	return GameState.state in [
		GameState.State.PLAY, GameState.State.INTRO, GameState.State.PAUSED,
		GameState.State.STAGE_CLEAR, GameState.State.SHOP
	]

## Playfield cull (clip already hides; skip drawer cost when fully outside)
func _in_pf(x: float, y: float, margin: float = 24.0) -> bool:
	var pf: Rect2 = Config.playfield()
	return (
		x + margin >= pf.position.x
		and x - margin <= pf.position.x + pf.size.x
		and y + margin >= pf.position.y
		and y - margin <= pf.position.y + pf.size.y
	)

func _draw_stage_bg_cached_or_live(pf: Rect2) -> void:
	## Phase 1.3: blit PF-sized StageBg bake; live drawer until first tex lands.
	# Boss fights: always live-draw so HSL-correct StageBgFx + dual_freeze soft path apply
	# (stale cache can hold pre-fix neon mandalas and wipe out ambience parity)
	var boss_live := false
	for b in get_tree().get_nodes_in_group("bosses"):
		if is_instance_valid(b) and not bool(b.get("dead")):
			boss_live = true
			break
	if not boss_live and stage_bg_cache != null and stage_bg_cache.has_method("get_texture"):
		var tex: Texture2D = stage_bg_cache.get_texture(tick)
		if tex != null and ctx.has_method("draw_image"):
			ctx.draw_image(tex, pf.position.x, pf.position.y, pf.size.x, pf.size.y)
			# Soft PF border (draw_hud.drawStageBg also strokes this)
			ctx.stroke_style("rgba(255,120,190,0.35)")
			ctx.line_width(2)
			ctx.begin_path()
			if ctx.has_method("round_rect"):
				ctx.round_rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y, 4)
			else:
				ctx.rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y)
			ctx.stroke()
			return
	if hud.has_method("drawStageBg"):
		hud.drawStageBg()

func _draw() -> void:
	if ctx == null or ported == null:
		return
	if not _is_playish():
		return
	ctx.begin_frame()
	if ported.has_method("set_tick"):
		ported.set_tick(tick)
	if hud.has_method("set_tick"):
		hud.set_tick(tick)
	if combat_fx.has_method("set_tick"):
		combat_fx.set_tick(tick)
	if item_draw.has_method("set_tick"):
		item_draw.set_tick(tick)

	var pf: Rect2 = Config.playfield()
	var tree := get_tree()
	var player = tree.get_first_node_in_group("player") if tree else null

	# HTML: ctx.save(); clip playfield
	ctx.save()
	ctx.begin_path()
	ctx.rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y)
	ctx.clip()

	# --- stage bg (cached) + boss ambience (live) ---
	_draw_stage_bg_cached_or_live(pf)
	if GameState.state == GameState.State.PLAY or GameState.state == GameState.State.PAUSED:
		if hud.has_method("drawBossAmbience"):
			hud.drawBossAmbience()

	# --- power radiance early (HTML before floaters) ---
	if player and is_instance_valid(player) and combat_fx:
		var pst := _player_state(player)
		if not bool(pst.get("dead", false)):
			combat_fx.drawPowerRadiance(pst)

	# --- floaters (confused.gif) ---
	if ItemSystem:
		for f in ItemSystem.floaters:
			if _in_pf(float(f.get("x", 0)), float(f.get("y", 0)), 30.0):
				_draw_floater(f)

	# --- enemies then burns then bosses (HTML order) ---
	if tree:
		for e in tree.get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or e.is_in_group("bosses"):
				continue
			var er := float(e.get("radius")) if e.get("radius") != null else 15.0
			if not _in_pf(e.global_position.x, e.global_position.y, er):
				continue
			_draw_enemy(e)
	if ItemSystem:
		for bn in ItemSystem.burns:
			var br := float(bn.get("reach", bn.get("r", 40)))
			if _in_pf(float(bn.get("x", 0)), float(bn.get("y", 0)), br):
				_draw_burn(bn)
	if tree:
		for b in tree.get_nodes_in_group("bosses"):
			if is_instance_valid(b):
				_draw_boss_node(b)

	# --- field clear gate ---
	if StageFlow and StageFlow.has_method("is_field_cleared") and StageFlow.is_field_cleared():
		if StageFlow.has_method("draw_clear_gate_world"):
			StageFlow.draw_clear_gate_world(ctx)

	# --- items ---
	if ItemSystem and item_draw:
		for it in ItemSystem.items:
			if it is Dictionary and _in_pf(float(it.get("x", 0)), float(it.get("y", 0)), 20.0):
				item_draw.drawItem(it)

	# --- pshots then enemy bullets (one pool pass, HTML order) ---
	if _bullet_pool == null:
		_bind_pool()
	if _bullet_pool and _bullet_pool.has_method("iter_active"):
		var pshots: Array = []
		var ebullets: Array = []
		for b in _bullet_pool.iter_active():
			if not is_instance_valid(b) or not b.active:
				continue
			var br2 := float(b.radius) if b.get("radius") != null else 4.0
			if not _in_pf(b.global_position.x, b.global_position.y, br2):
				continue
			if int(b.team) == 0:
				pshots.append(b)
			else:
				ebullets.append(b)
		for b in pshots:
			_draw_bullet_node(b)
		for b in ebullets:
			_draw_bullet_node(b)

	# --- phase veil under Bobina ---
	if hud.has_method("drawPhaseVeil"):
		hud.drawPhaseVeil()

	# --- Bobina full drawBobina + auras / consumable rings ---
	if player and is_instance_valid(player):
		_draw_player(player)

	# --- fx / particles / melee / score / bomb / slowmo ---
	# Special FX + consumable bubbles/stardust (ItemSystem.fx)
	if ported.has_method("drawFx"):
		var fx_list: Array = []
		if CombatHelpers and "fx" in CombatHelpers:
			fx_list = CombatHelpers.fx.duplicate() if CombatHelpers.fx is Array else []
		if player and is_instance_valid(player) and player.get("specials") != null:
			var sp = player.specials
			if sp and sp.get("fx") is Array:
				for f in sp.fx:
					fx_list.append(f)
		if ItemSystem and ItemSystem.get("fx") is Array:
			for f2 in ItemSystem.fx:
				fx_list.append(f2)
		ported.drawFx(fx_list)

	if CombatHelpers:
		# Batch particles by color to cut fill_style thrash on dense sparks
		var by_col: Dictionary = {}
		for p in CombatHelpers.particles:
			var col := str(p.get("c", "#ff8ac0"))
			if not by_col.has(col):
				by_col[col] = []
			by_col[col].append(p)
		for col in by_col.keys():
			ctx.fill_style(str(col))
			for p in by_col[col]:
				var life := float(p.get("life", 0))
				ctx.global_alpha(clampf(life / 30.0, 0.0, 1.0))
				ctx.begin_path()
				ctx.arc(float(p.get("x", 0)), float(p.get("y", 0)), 2.2, 0, TAU)
				ctx.fill()
			ctx.global_alpha(1.0)
		if ported.has_method("drawMeleeFx"):
			var mfx: Array = []
			if "melee_fx" in CombatHelpers:
				mfx = CombatHelpers.melee_fx.duplicate() if CombatHelpers.melee_fx is Array else []
			# MeleeSystem.swipe_fx is the live slash list (HTML meleeFx)
			if player and is_instance_valid(player) and player.get("melee") != null:
				var ms = player.melee
				if ms and ms.get("swipe_fx") is Array:
					for f in ms.swipe_fx:
						mfx.append(f)
			ported.drawMeleeFx(mfx, player)
		for s in CombatHelpers.score_texts:
			var life2 := float(s.get("life", 0))
			ctx.global_alpha(clampf(life2 / 44.0, 0.0, 1.0))
			ctx.fill_style(str(s.get("color", "#fff")))
			ctx.font("bold 12px monospace")
			ctx.text_align("center")
			ctx.fill_text(str(s.get("txt", "")), float(s.get("x", 0)), float(s.get("y", 0)))
			ctx.text_align("left")
			ctx.global_alpha(1.0)
		# bomb pink flash
		if player and is_instance_valid(player):
			var bfx := float(player.bomb_fx) if player.get("bomb_fx") != null else 0.0
			if bfx > 0.0:
				ctx.fill_style("rgba(255,180,230," + str(bfx / 46.0 * 0.5) + ")")
				ctx.fill_rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y)
		# flashMsg (wrapped like HTML)
		if CombatHelpers.flash_msg.has("txt") and float(CombatHelpers.flash_msg.get("t", 0)) > 0.0:
			_draw_flash_msg(pf)

	if hud.has_method("drawSlowmoFx"):
		hud.drawSlowmoFx()

	# collect line hint when focused
	var focused := false
	if player and is_instance_valid(player) and player.get("focus") != null:
		focused = bool(player.focus)
	if focused:
		var cl := pf.position.y + pf.size.y * 0.72
		if Config.has_method("collect_line"):
			cl = float(Config.collect_line())
		elif "COLLECT_LINE" in Config:
			cl = float(Config.COLLECT_LINE)
		ctx.stroke_style("rgba(255,255,255,0.12)")
		ctx.line_width(1)
		ctx.begin_path()
		ctx.move_to(pf.position.x, cl)
		ctx.line_to(pf.position.x + pf.size.x, cl)
		ctx.stroke()

	# Hell portals on bosses
	if tree and hud.has_method("drawHellPortal"):
		for b in tree.get_nodes_in_group("bosses"):
			if not is_instance_valid(b):
				continue
			var hell_r := float(b.get("hellR")) if b.get("hellR") != null else 0.0
			var hell_on := bool(b.get("hell")) if b.get("hell") != null else false
			if hell_on or hell_r > 1.0:
				var rad := float(b.get("radius")) if b.get("radius") != null else 40.0
				var ht := float(b.get("t")) if b.get("t") != null else float(tick)
				hud.drawHellPortal({
					"x": b.global_position.x, "y": b.global_position.y,
					"hellR": hell_r if hell_r > 1.0 else rad,
					"hellT": ht, "hy": b.global_position.y,
				})

	ctx.restore()
	# Playfield border (HTML after clip restore)
	ctx.stroke_style("rgba(255,140,200,0.5)")
	ctx.line_width(2)
	ctx.stroke_rect(pf.position.x - 1, pf.position.y - 1, pf.size.x + 2, pf.size.y + 2)

func _draw_flash_msg(pf: Rect2) -> void:
	var ft := float(CombatHelpers.flash_msg.get("t", 0))
	var txt := str(CombatHelpers.flash_msg.get("txt", ""))
	ctx.global_alpha(minf(1.0, ft / 20.0))
	ctx.fill_style("#fff")
	ctx.font("900 26px \"Trebuchet MS\"")
	ctx.text_align("center")
	var max_w := pf.size.x - 30.0
	var words := txt.split(" ")
	var line := ""
	var lines: Array = []
	for wd in words:
		var test := (line + " " + wd).strip_edges() if line != "" else wd
		# approximate width: 13px avg for bold 26
		if line != "" and float(test.length()) * 13.0 > max_w:
			lines.append(line)
			line = wd
		else:
			line = test
	if line != "":
		lines.append(line)
	var lh := 30.0
	var y0 := pf.get_center().y - (float(lines.size()) - 1.0) * lh / 2.0
	for i in range(lines.size()):
		ctx.fill_text(str(lines[i]), pf.get_center().x, y0 + float(i) * lh)
	ctx.text_align("left")
	ctx.global_alpha(1.0)

func _draw_floater(f: Dictionary) -> void:
	## HTML drawFloater — confused.gif (animated via AssetBank)
	var life := float(f.get("life", 30))
	var sc := float(f.get("scale", 0.7)) * 46.0
	var x := float(f.get("x", 0))
	var y := float(f.get("y", 0))
	ctx.global_alpha(clampf(life / 30.0, 0.0, 1.0))
	var tex: Texture2D = null
	if AssetBank and AssetBank.has_method("get_tex"):
		tex = AssetBank.get_tex("confused")
	if tex:
		ctx.draw_image(tex, x - sc / 2.0, y - sc / 2.0, sc, sc)
	else:
		ctx.fill_style("#5a3d2b")
		ctx.begin_path()
		ctx.arc(x, y, sc / 2.0, 0, TAU)
		ctx.fill()
	ctx.global_alpha(1.0)

func _draw_burn(bn: Dictionary) -> void:
	## HTML drawBurns — radial wedge flame field
	var life := float(bn.get("life", 1))
	var maxl := float(bn.get("max", bn.get("maxLife", 90)))
	if maxl <= 0.0:
		maxl = 90.0
	var life_f := clampf(life / maxl, 0.0, 1.0)
	var x := float(bn.get("x", 0))
	var y := float(bn.get("y", 0))
	var reach := float(bn.get("reach", bn.get("r", 40)))
	var dir := float(bn.get("dir", 0))
	var half := float(bn.get("half", 0.8))
	ctx.save()
	if ctx.has_method("global_composite_operation"):
		ctx.global_composite_operation("lighter")
	elif ctx.has_method("set_gco"):
		ctx.set_gco("lighter")
	ctx.translate(x, y)
	var a0 := dir - half
	var a1 := dir + half
	# approximate radial gradient with layered arcs
	ctx.global_alpha(0.16 * life_f)
	ctx.fill_style("rgba(255,140,50,1)")
	ctx.begin_path()
	ctx.move_to(0, 0)
	ctx.arc(0, 0, reach, a0, a1)
	ctx.close_path()
	ctx.fill()
	ctx.global_alpha(0.11 * life_f)
	ctx.fill_style("rgba(255,60,60,1)")
	ctx.begin_path()
	ctx.move_to(0, 0)
	ctx.arc(0, 0, reach * 0.7, a0, a1)
	ctx.close_path()
	ctx.fill()
	ctx.global_alpha(1.0)
	if ctx.has_method("global_composite_operation"):
		ctx.global_composite_operation("source-over")
	ctx.restore()

func _draw_enemy(e: Node) -> void:
	var st := {
		"x": e.global_position.x,
		"y": e.global_position.y,
		"r": float(e.get("radius")) if e.get("radius") != null else 15.0,
		"t": float(e.get("age_frames")) if e.get("age_frames") != null else float(tick),
		"flash": float(e.get("flash")) if e.get("flash") != null else 0.0,
		"icy": bool(e.get("icy")) if e.get("icy") != null else false,
		"kind": str(e.get("kind")) if e.get("kind") != null else "lil",
		"elite": str(e.get("elite_type")) if e.get("elite_type") != null else "",
	}
	if str(st["kind"]) == "elite":
		ported.drawElite(st)
	else:
		ported.drawMumu(st)
	# stun stars (skip dual-frozen elites — dual uses stun as a freeze latch)
	var dual_fr := e.has_meta("dual_freeze") and bool(e.get_meta("dual_freeze"))
	var stun := float(e.get("stun")) if e.get("stun") != null else 0.0
	if stun > 0.0 and not dual_fr:
		ctx.save()
		ctx.translate(st["x"], st["y"] - st["r"] - 5.0)
		ctx.text_align("center")
		ctx.font("9px monospace")
		ctx.fill_style("#ffe08a")
		for i in range(3):
			var a := float(tick) * 0.12 + float(i) * 2.094
			ctx.fill_text("★", cos(a) * 8.0, sin(a) * 3.0 + 3.0)
		ctx.text_align("left")
		ctx.restore()
	# charm hearts
	var charm := float(e.get("charm")) if e.get("charm") != null else 0.0
	if charm > 0.0:
		ctx.save()
		ctx.global_alpha(0.7 + 0.3 * sin(float(tick) * 0.3))
		ctx.font("13px serif")
		ctx.text_align("center")
		ctx.fill_text("💗", st["x"], st["y"] - st["r"] - 5.0)
		ctx.text_align("left")
		ctx.restore()

func _draw_boss_node(b: Node) -> void:
	var data = b.get("data") if b.get("data") != null else {}
	# BossController uses snake_case (max_hp / hud_name); HTML drawBoss uses maxhp / hudName
	var maxhp := 1.0
	if b.get("max_hp") != null:
		maxhp = float(b.max_hp)
	elif b.get("maxhp") != null:
		maxhp = float(b.maxhp)
	var hud := ""
	if b.get("hud_name") != null and str(b.hud_name) != "":
		hud = str(b.hud_name)
	elif b.get("hudName") != null:
		hud = str(b.hudName)
	var st := {
		"x": b.global_position.x,
		"y": b.global_position.y,
		"r": float(b.get("radius")) if b.get("radius") != null else 40.0,
		"t": float(b.get("t")) if b.get("t") != null else float(tick),
		"hp": float(b.get("hp")) if b.get("hp") != null else 1.0,
		"maxhp": maxhp,
		"phase": int(b.get("phase")) if b.get("phase") != null else 0,
		"intro": float(b.get("intro")) if b.get("intro") != null else 0.0,
		"dead": bool(b.get("dead")) if b.get("dead") != null else false,
		"data": data if data is Dictionary else {},
		"hudName": hud,
		"portrait": str(data.get("portrait", "")) if data is Dictionary else "",
		"flash": float(b.get("flash")) if b.get("flash") != null else 0.0,
		"face": float(b.get("face")) if b.get("face") != null else (PI / 2.0),
		"twin": bool(b.get("twin")) if b.get("twin") != null else false,
		"active": str(b.get("active_twin")) if b.get("active_twin") != null else "",
	}
	ported.drawBoss(st)

func _draw_bullet_node(b: Node) -> void:
	var col: Color = b.color if b.get("color") != null else Color(1, 0.4, 0.6)
	var col_hex := "#%02x%02x%02x" % [int(col.r * 255), int(col.g * 255), int(col.b * 255)]
	var r := float(b.radius) if b.get("radius") != null else 4.0
	var team := int(b.team) if b.get("team") != null else 1
	var pshot := bool(b.pshot) if b.get("pshot") != null else false
	if team == 0 and pshot:
		var st := {
			"x": b.global_position.x, "y": b.global_position.y, "r": r,
			"vx": b.velocity.x if b.get("velocity") != null else 0.0,
			"vy": b.velocity.y if b.get("velocity") != null else 0.0,
			"gat": bool(b.gat) if b.get("gat") != null else false,
			"nade": bool(b.nade) if b.get("nade") != null else false,
			"vrip": bool(b.vrip) if b.get("vrip") != null else false,
			"petal": bool(b.petal) if b.get("petal") != null else false,
			"zap": bool(b.zap) if b.get("zap") != null else false,
			"laser": bool(b.laser) if b.get("laser") != null else false,
			"shell": bool(b.shell) if b.get("shell") != null else false,
			"home": bool(b.home) if b.get("home") != null else false,
			"foc": bool(b.foc) if b.get("foc") != null else false,
			"voidbolt": bool(b.voidbolt) if b.get("voidbolt") != null else false,
			"wv": float(b.wv) if b.get("wv") != null else 0.0,
			"col": col_hex,
			# life_frames defaults to -1 (unlimited); only pass when timed
			"life": (float(b.life_frames) if float(b.life_frames) >= 0.0 else null) if b.get("life_frames") != null else null,
		}
		ported.drawPShot(st)
	else:
		ported.drawBullet({
			"x": b.global_position.x, "y": b.global_position.y,
			"r": r, "col": col_hex,
			"hp": float(b.hp) if b.get("hp") != null else 0.0,
		})

func _player_state(player: Node) -> Dictionary:
	# HTML trail points are absolute {x,y}; Player stores world {wx,wy}
	var trail_abs: Array = []
	if player.get("trail") != null:
		for q in player.trail:
			if q is Dictionary:
				trail_abs.append({
					"x": float(q.get("x", q.get("wx", player.global_position.x))),
					"y": float(q.get("y", q.get("wy", player.global_position.y))),
				})
	# Dual stills: force upright face + zero walk so Bobina matches HTML freeze pose
	var dual_lock: bool = player.has_meta("dual_lock_pose") and bool(player.get_meta("dual_lock_pose"))
	var face_v: float = -PI / 2.0
	if dual_lock:
		if player.has_meta("dual_aim"):
			face_v = float(player.get_meta("dual_aim"))
	elif player.get("aim") != null:
		face_v = float(player.aim)
	var vx_v: float = 0.0
	var vy_v: float = 0.0
	if not dual_lock and player.get("velocity") != null:
		vx_v = float(player.velocity.x)
		vy_v = float(player.velocity.y)
	var st := {
		"x": player.global_position.x,
		"y": player.global_position.y,
		"outfit": GameState.selected_outfit,
		"tick": tick,
		"power": float(GameState.power),
		"focus": bool(player.focus) if player.get("focus") != null else false,
		"iframe": float(player.invuln) if player.get("invuln") != null else 0.0,
		"vx": vx_v,
		"vy": vy_v,
		"face": face_v,
		"walk": 0.0,
		"bombFx": float(player.bomb_fx) if player.get("bomb_fx") != null else 0.0,
		"dash": float(player.dash) if player.get("dash") != null else 0.0,
		"dashAng": float(player.dash_ang) if player.get("dash_ang") != null else 0.0,
		"slashDash": bool(player.slash_dash) if player.get("slash_dash") != null else false,
		"trail": trail_abs,
		"phase_t": float(player.phase_t) if player.get("phase_t") != null else 0.0,
		"phaseT": float(player.phase_t) if player.get("phase_t") != null else 0.0,
		"shield_t": float(player.shield_t) if player.get("shield_t") != null else 0.0,
		"shieldT": float(player.shield_t) if player.get("shield_t") != null else 0.0,
		"rapid_t": float(player.rapid_t) if player.get("rapid_t") != null else 0.0,
		"rapidT": float(player.rapid_t) if player.get("rapid_t") != null else 0.0,
		"vialHits": int(player.vial_hits) if player.get("vial_hits") != null else 0,
		"vialT": float(player.vial_t) if player.get("vial_t") != null else 0.0,
		"dead": false,
	}
	# Dual / celebration: optional expr override (HTML play is null = Auto/smile)
	if player.has_meta("dual_expr"):
		var de = player.get_meta("dual_expr")
		if de != null and str(de) != "":
			st["expr"] = str(de)
		# dual_expr meta set to empty string means explicit Auto (null expr → smile)
	elif player.get("expr") != null:
		st["expr"] = player.get("expr")
	return st

func _draw_bobina_cached_or_live(st: Dictionary) -> void:
	## Phase 1.2: SubViewport-baked drawBobina when state is cacheable.
	## High-motion states (dash/bomb) stay live for exact FX.
	var dash := float(st.get("dash", 0))
	var bomb := float(st.get("bombFx", 0))
	var use_cache := bobina_cache != null and dash <= 0.0 and bomb <= 0.0
	if use_cache and bobina_cache.has_method("get_play_texture"):
		var tex: Texture2D = bobina_cache.get_play_texture(st)
		if tex != null and ctx.has_method("draw_image"):
			var tw := float(tex.get_width())
			var th := float(tex.get_height())
			var px := float(st.get("x", 0))
			var py := float(st.get("y", 0))
			# iframe flash (HTML: alpha 0.5 every other 4 frames of invuln)
			var iframe := float(st.get("iframe", 0))
			var flash := iframe > 0.0 and (int(floorf(iframe / 4.0)) % 2) == 1
			if flash:
				ctx.global_alpha(0.5)
			ctx.draw_image(tex, px - tw * 0.5, py - th * 0.5, tw, th)
			if flash:
				ctx.global_alpha(1.0)
			return
	# Live full drawer (cache miss or dash/bomb)
	ported.drawBobina(st)

func _draw_player(player: Node) -> void:
	var st := _player_state(player)
	if combat_fx:
		combat_fx.drawDashComet(st)
		combat_fx.drawPowerAura(st)
	# Full drawBobina — cache bake when possible; live fallback (never a placeholder circle)
	_draw_bobina_cached_or_live(st)
	if combat_fx:
		combat_fx.drawOptions(true)
	# shield / rapid / vial / phase rings — HTML overlays on Bobina
	var shield_t := float(st.get("shieldT", 0))
	if shield_t > 0.0:
		var a := 0.55 * (shield_t / 50.0 if shield_t < 50.0 else 1.0)
		ctx.save()
		ctx.translate(st["x"], st["y"])
		ctx.global_alpha(a)
		ctx.stroke_style("#e8a860")
		ctx.line_width(2.5)
		ctx.begin_path()
		ctx.arc(0, 0, 23, 0, TAU)
		ctx.stroke()
		ctx.restore()
	var rapid_t := float(st.get("rapidT", 0))
	if rapid_t > 0.0:
		ctx.save()
		ctx.translate(st["x"], st["y"])
		ctx.global_alpha(0.5)
		ctx.fill_style("#ffe14a")
		for i in range(3):
			ctx.begin_path()
			ctx.arc(randf_range(-6, 6), 10 + randf() * 8, 1.6, 0, TAU)
			ctx.fill()
		ctx.restore()
	var vial_hits := int(st.get("vialHits", 0))
	var vial_t := float(st.get("vialT", 0))
	if vial_hits > 0:
		var vf := vial_t / 50.0 if vial_t < 50.0 else 1.0
		ctx.save()
		ctx.translate(st["x"], st["y"])
		ctx.global_alpha(0.62 * vf)
		ctx.stroke_style("#9d6bff")
		ctx.line_width(2.4)
		ctx.begin_path()
		ctx.arc(0, 0, 25, 0, TAU)
		ctx.stroke()
		ctx.global_alpha(vf)
		ctx.fill_style("#c9a6ff")
		for i in range(vial_hits):
			var ang := float(tick) * 0.06 + float(i) * (TAU / 3.0)
			ctx.begin_path()
			ctx.arc(cos(ang) * 25.0, sin(ang) * 25.0, 3.4, 0, TAU)
			ctx.fill()
		ctx.restore()
	var phase_t := float(st.get("phaseT", 0))
	if phase_t > 0.0:
		ctx.save()
		ctx.translate(st["x"], st["y"])
		if ctx.has_method("global_composite_operation"):
			ctx.global_composite_operation("lighter")
		for k in range(2):
			ctx.stroke_style("rgba(150,120,255,0.5)" if k else "rgba(90,220,255,0.55)")
			ctx.line_width(1.6)
			var rr := 24.0 + sin(float(tick) * 0.2 + float(k) * 2.1) * 4.0
			ctx.begin_path()
			ctx.arc(3.0 if k else -3.0, 0, rr, 0, TAU)
			ctx.stroke()
		if ctx.has_method("global_composite_operation"):
			ctx.global_composite_operation("source-over")
		ctx.stroke_style("rgba(180,240,255,0.78)")
		ctx.line_width(2)
		ctx.begin_path()
		ctx.arc(0, 0, 28, -PI / 2.0, -PI / 2.0 + TAU * (phase_t / 180.0))
		ctx.stroke()
		ctx.restore()
