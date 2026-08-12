extends SceneTree
## Phase 7: UI / render / modals helpers — structure + HTML constant parity.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true

	# --- presence of Phase 7 mapped files ---
	var required := [
		"res://scripts/ui/menu/MenuHelpers.gd",
		"res://scripts/ui/menu/draw_hud.gd",
		"res://scripts/ui/menu/draw_flow.gd",
		"res://scripts/ui/menu/draw_debug.gd",
		"res://scripts/ui/menu/draw_menus.gd",
		"res://scripts/ui/menu/HelpData.gd",
		"res://scripts/ui/menu/P2Meta.gd",
		"res://scripts/ui/FlowUI.gd",
		"res://scripts/ui/PauseMenu.gd",
		"res://scripts/ui/SettingsMenu.gd",
		"res://scripts/ui/DisplayMenu.gd",
		"res://scripts/ui/EndScreen.gd",
		"res://scripts/ui/TitleScreen.gd",
		"res://scripts/ui/HelpCanvas.gd",
		"res://scripts/ui/KeybindsMenu.gd",
		"res://scripts/stages/StageFlow.gd",
		"res://scripts/render/PortedDraw.gd",
		"res://scripts/render/FxLayer.gd",
		"res://scripts/render/drawers/drawCombatFx.gd",
		"res://scripts/render/drawers/drawBullet.gd",
		"res://scripts/render/drawers/drawPShot.gd",
		"res://scripts/render/drawers/drawMeleeFx.gd",
		"res://scripts/render/drawers/drawHoneyBadger.gd",
		"res://scripts/render/drawers/drawBogdanoff.gd",
		"res://scripts/render/drawers/drawRobotnik.gd",
		"res://scripts/render/drawers/drawTitle.gd",
		"res://scripts/render/drawers/drawPortraitBust.gd",
		"res://scripts/html_parity/AssetBank.gd",
		"res://scripts/html_parity/WorldDraw.gd",
		"res://scripts/input/InputRouter.gd",
	]
	for path in required:
		if not FileAccess.file_exists(path):
			print("[P7] FAIL missing ", path)
			ok = false

	var hud: String = FileAccess.get_file_as_string("res://scripts/ui/menu/draw_hud.gd")
	var flow: String = FileAccess.get_file_as_string("res://scripts/ui/menu/draw_flow.gd")
	var mh: String = FileAccess.get_file_as_string("res://scripts/ui/menu/MenuHelpers.gd")
	var sf: String = FileAccess.get_file_as_string("res://scripts/stages/StageFlow.gd")
	var es: String = FileAccess.get_file_as_string("res://scripts/ui/EndScreen.gd")
	var fui: String = FileAccess.get_file_as_string("res://scripts/ui/FlowUI.gd")
	var wd: String = FileAccess.get_file_as_string("res://scripts/html_parity/WorldDraw.gd")
	var ir: String = FileAccess.get_file_as_string("res://scripts/input/InputRouter.gd")
	var pm: String = FileAccess.get_file_as_string("res://scripts/ui/PauseMenu.gd")
	var sm: String = FileAccess.get_file_as_string("res://scripts/ui/SettingsMenu.gd")
	var dm: String = FileAccess.get_file_as_string("res://scripts/ui/DisplayMenu.gd")
	var hc: String = FileAccess.get_file_as_string("res://scripts/ui/HelpCanvas.gd")
	var hd: String = FileAccess.get_file_as_string("res://scripts/ui/menu/HelpData.gd")
	var title: String = FileAccess.get_file_as_string("res://scripts/render/drawers/drawTitle.gd")
	var menus: String = FileAccess.get_file_as_string("res://scripts/ui/menu/draw_menus.gd")
	var dbg: String = FileAccess.get_file_as_string("res://scripts/ui/menu/draw_debug.gd")

	# --- HUD drawers ---
	for frag in ["func drawStageBg", "func drawStageBgFx", "func drawBossAmbience",
			"func drawPanel", "func drawEmblemToasts", "func drawPhaseVeil",
			"func drawSlowmoFx", "func drawHellPortal", "func _draw_heart",
			"func _hex_rgb", "func _hex_a"]:
		if hud.find(frag) < 0:
			print("[P7] FAIL hud missing ", frag)
			ok = false

	# drawPhaseVeil HTML constants: veil alpha, edge thresholds 162/26, lane speeds
	for frag in ["0.66", "162.0", "26.0", "rgba(14,4,34", "sp2", "0.28 * edge"]:
		if hud.find(frag) < 0:
			print("[P7] FAIL phase veil ", frag)
			ok = false

	# drawSlowmoFx HTML: 45 / 300 / 0.25 / ring expand 95
	for frag in ["45.0", "300.0", "0.25", "95.0", "0.09"]:
		if hud.find(frag) < 0:
			print("[P7] FAIL slowmo ", frag)
			ok = false

	# drawHellPortal HTML ellipse ratios
	for frag in ["1.16", "0.76", "0.12", "0.4", "0.26", "#ff5a1a"]:
		if hud.find(frag) < 0:
			print("[P7] FAIL hell portal ", frag)
			ok = false

	# drawHeart HTML color + bezier
	if hud.find("#ff4d8d") < 0 or hud.find("bezier_curve_to") < 0:
		print("[P7] FAIL drawHeart HUD")
		ok = false
	if es.find("#ff4d8d") < 0 or es.find("bezier_curve_to") < 0:
		print("[P7] FAIL drawHeart EndScreen")
		ok = false

	# drawShareBtn size
	if es.find("272.0") < 0 and es.find("272") < 0:
		print("[P7] FAIL share btn w 272")
		ok = false
	if es.find("func _draw_share_btn") < 0:
		print("[P7] FAIL drawShareBtn")
		ok = false

	# emblem toasts 210/16/22 / 308×54
	for frag in ["210.0", "16.0", "22.0", "308.0", "54.0", "EMBLEM UNLOCKED"]:
		if hud.find(frag) < 0:
			print("[P7] FAIL emblem toast ", frag)
			ok = false

	# stage bg palette (HTML s0/s5/default)
	for frag in ["#0b2412", "#0a0a1e", "#4e1019"]:
		if hud.find(frag) < 0:
			print("[P7] FAIL stage bg ", frag)
			ok = false

	# boss ambience rage / mandala
	for frag in ["1.6", "0.005", "seg", "0.16 + 0.14"]:
		if hud.find(frag) < 0:
			print("[P7] FAIL boss ambience ", frag)
			ok = false

	# --- flow / dialog / shop ---
	for frag in ["func drawDialog", "func drawShop", "func _shop_list", "func drawIntro",
			"func drawStageClear", "func drawClearGate"]:
		if flow.find(frag) < 0:
			print("[P7] FAIL flow missing ", frag)
			ok = false
	# dialog heights
	for frag in ["88.0", "52.0", "Collector of Debts", "Danmaku Bear"]:
		if flow.find(frag) < 0:
			print("[P7] FAIL dialog ", frag)
			ok = false
	# shop buy messages / consumable path
	for frag in ["consumable", "Not enough heads", "Already in your arsenal", "HONEY"]:
		if flow.find(frag) < 0 and fui.find(frag) < 0:
			print("[P7] FAIL shop ", frag)
			ok = false
	if fui.find("func _shop_buy") < 0:
		print("[P7] FAIL shopBuySelected path")
		ok = false

	# --- StageFlow neutralize / bobinaSay ---
	if sf.find("func neutralize_inputs") < 0:
		print("[P7] FAIL neutralizeInputs")
		ok = false
	if sf.find("neutralize_lmb") < 0 or sf.find("_shift_tap_t") < 0:
		print("[P7] FAIL neutralize latch fields")
		ok = false
	if sf.find("func bobina_say") < 0:
		print("[P7] FAIL bobinaSay")
		ok = false
	if sf.find("hurt") < 0 or sf.find("60.0") < 0:
		print("[P7] FAIL bobinaSay defaults")
		ok = false
	if sf.find("func shop_buy_selected") < 0:
		print("[P7] FAIL shop_buy_selected")
		ok = false

	# --- modals / menus ---
	if mh.find("func any_modal_open") < 0 and mh.find("any_modal_open") < 0:
		print("[P7] FAIL anyModalOpen")
		ok = false
	if mh.find("h_esc") < 0 and mh.find("&amp;") < 0:
		print("[P7] FAIL _hEsc")
		ok = false
	if mh.find("func wrap_text") < 0:
		print("[P7] FAIL wrapText")
		ok = false
	if ir.find("any_modal_open") < 0:
		print("[P7] FAIL InputRouter modal gate")
		ok = false
	if pm.find("_sync_ui") < 0 or pm.find("_on_resume") < 0 or pm.find("_on_menu") < 0:
		print("[P7] FAIL PauseMenu sync/resume/return")
		ok = false
	if pm.find("PAUSED") < 0:
		print("[P7] FAIL pause title")
		ok = false
	if sm.find("_sync_ui") < 0:
		print("[P7] FAIL syncSettingsUI")
		ok = false
	if dm.find("open_menu") < 0 or dm.find("close_menu") < 0 or dm.find("_refresh") < 0:
		print("[P7] FAIL DisplayMenu open/close/sync")
		ok = false
	if hc.find("open_help") < 0 or hc.find("close_help") < 0:
		print("[P7] FAIL openHelp/closeHelp")
		ok = false
	if hd.find("func tabs") < 0 or hd.find("controls") < 0:
		print("[P7] FAIL buildHelp/HelpData")
		ok = false

	# --- stun stars in WorldDraw (HTML drawStunStars) ---
	for frag in ["0.12", "2.094", "★", "8.0"]:
		if wd.find(frag) < 0:
			print("[P7] FAIL stun stars ", frag)
			ok = false

	# --- drawers presence ---
	for path in [
		"res://scripts/render/drawers/drawBullet.gd",
		"res://scripts/render/drawers/drawPShot.gd",
		"res://scripts/render/drawers/drawMeleeFx.gd",
		"res://scripts/render/drawers/drawHoneyBadger.gd",
		"res://scripts/render/drawers/drawBogdanoff.gd",
		"res://scripts/render/drawers/drawRobotnik.gd",
		"res://scripts/render/drawers/drawPortraitBust.gd",
	]:
		var body := FileAccess.get_file_as_string(path)
		if body.length() < 80:
			print("[P7] FAIL empty drawer ", path)
			ok = false
	if title.find("drawMaidDance") < 0 and title.find("afk_dance") < 0:
		print("[P7] FAIL drawMaidDance")
		ok = false
	if menus.find("drawPosedFigure") < 0 and menus.find("posed") < 0:
		# may be named differently
		if menus.find("pose") < 0:
			print("[P7] FAIL drawPosedFigure")
			ok = false

	# debug layer
	if dbg.find("draw_debug_layer") < 0 and dbg.find("DEBUG") < 0:
		print("[P7] FAIL drawDebugLayer")
		ok = false

	# P2Meta shoutouts
	var p2: String = FileAccess.get_file_as_string("res://scripts/ui/menu/P2Meta.gd")
	if p2.find("open_shoutouts") < 0 or p2.find("close_shoutouts") < 0:
		print("[P7] FAIL shoutouts open/close")
		ok = false

	# AssetBank gif frames
	var ab: String = FileAccess.get_file_as_string("res://scripts/html_parity/AssetBank.gd")
	for frag in ["talk", "confused", "leek"]:
		if ab.find(frag) < 0:
			print("[P7] FAIL gif asset ", frag)
			ok = false

	# runtime: bobina_say + neutralize if autoloads up
	var SF = root.get_node_or_null("/root/StageFlow")
	var GS = root.get_node_or_null("/root/GameState")
	if SF and GS:
		if SF.has_method("bobina_say"):
			SF.bobina_say("test", 60.0, true)
			if SF.dialog == null:
				print("[P7] FAIL bobina_say runtime null dialog")
				ok = false
			elif not bool(SF.dialog.get("hurt", false)):
				print("[P7] FAIL bobina_say hurt flag")
				ok = false
			elif absf(float(SF.dialog.get("timer", 0)) - 60.0) > 0.1:
				print("[P7] FAIL bobina_say timer ", SF.dialog.get("timer"))
				ok = false
			# non-hurt should not clobber hurt? actually HTML: if dialog && !dialog.hurt return
			# so if hurt dialog active, non-hurt is blocked; if non-hurt active, hurt can replace
			SF.dialog = {"boss": null, "queue": [{"w": 1, "t": "x"}], "i": 0, "timer": 30.0, "hurt": false}
			SF.bobina_say("blocked", 10.0, false)
			if str(SF.dialog.get("queue", [{}])[0].get("t", "")) == "blocked":
				print("[P7] FAIL bobina_say clobbered non-hurt")
				ok = false
			SF.dialog = null
		if SF.has_method("neutralize_inputs"):
			SF.neutralize_inputs()  # should not crash without player

	# MenuHelpers runtime
	var MH = load("res://scripts/ui/menu/MenuHelpers.gd")
	if MH:
		var esc: String = MH.h_esc("<a>&")
		if esc.find("&lt;") < 0 or esc.find("&amp;") < 0:
			print("[P7] FAIL h_esc runtime ", esc)
			ok = false
		if not MH.has_method("any_modal_open"):
			print("[P7] FAIL any_modal_open method")
			ok = false
		else:
			# no modals in headless → false
			if MH.any_modal_open():
				print("[P7] WARN any_modal_open true with no UI (may be ok)")
	else:
		print("[P7] FAIL load MenuHelpers")
		ok = false

	if ok:
		print("[P7] Phase 7 UI/render/modals PASS")
		quit(0)
	else:
		print("[P7] FAIL")
		quit(1)
