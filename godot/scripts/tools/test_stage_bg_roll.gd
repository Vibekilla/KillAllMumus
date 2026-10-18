extends SceneTree
## S6: one loadStage roll, shared by every stage-bg drawer. S3: pause fold hides the bar.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var root := get_root()
	var sf = root.get_node_or_null("StageFlow")
	if sf == null or not sf.has_method("roll_stage_bg"):
		print("[BG] FAIL StageFlow.roll_stage_bg missing")
		quit(1)
		return
	var before := int(sf.bg_roll)
	sf.on_stage_start(1.0)
	if int(sf.bg_roll) != before + 1:
		print("[BG] FAIL on_stage_start must roll once, got ", sf.bg_roll, " from ", before)
		ok = false
	var petals := int(sf.bg_petals)
	if petals != 3 and petals != 5 and petals != 7 and petals != 9:
		print("[BG] FAIL petals ", petals)
		ok = false
	var hue := float(sf.bg_hue_seed)
	if hue < -30.0 or hue > 30.0:
		print("[BG] FAIL hue ", hue)
		ok = false
	var sc = load("res://scripts/render/drawers/drawStageBg.gd")
	var a = sc.new()
	var b = sc.new()
	a.sync_seeds()
	b.sync_seeds()
	if not is_equal_approx(float(a.bg_seed), float(sf.bg_seed)) or not is_equal_approx(float(b.bg_seed), float(a.bg_seed)):
		print("[BG] FAIL drawers diverged ", a.bg_seed, " ", b.bg_seed, " ", sf.bg_seed)
		ok = false
	if int(a.bg_petals) != int(b.bg_petals) or int(a.bg_petals) != petals:
		print("[BG] FAIL petal share ", a.bg_petals, " ", b.bg_petals)
		ok = false
	var roll_now := int(sf.bg_roll)
	sf.on_stage_start(1.0)
	if int(sf.bg_roll) != roll_now + 1:
		print("[BG] FAIL second loadStage did not roll")
		ok = false
	a.sync_seeds()
	b.sync_seeds()
	if not is_equal_approx(float(a.bg_seed), float(b.bg_seed)):
		print("[BG] FAIL drawers diverged after second roll")
		ok = false
	if is_equal_approx(float(a.bg_seed), float(sf.bg_seed)) == false:
		print("[BG] FAIL drawer missed second roll")
		ok = false
	var cache_src := FileAccess.get_file_as_string("res://scripts/render/StageBgDrawCache.gd")
	if cache_src.find("reroll_seeds") >= 0:
		print("[BG] FAIL cache must not roll its own stream")
		ok = false
	if cache_src.find("sync_seeds") < 0:
		print("[BG] FAIL cache must sync shared seeds")
		ok = false

	var packed := load("res://scenes/ui/PauseMenu.tscn")
	var menu = packed.instantiate()
	root.add_child(menu)
	var gs = root.get_node_or_null("GameState")
	if gs and gs.has_method("set_state"):
		gs.set_state(gs.State.PAUSED)
	menu.visible = true
	await process_frame
	var panel := menu.get_node_or_null("Panel") as PanelContainer
	if panel and menu.has_method("_center_panel"):
		menu._center_panel(panel, 380.0)
		for _i in range(8):
			await process_frame
		var scroll := panel.get_node_or_null("Scroll") as ScrollContainer
		var resume := menu.find_child("ResumeBtn", true, false) as Control
		var display := menu.find_child("DisplayBtn", true, false) as Control
		if scroll == null or resume == null or display == null:
			print("[PAUSE] FAIL missing scroll/resume/display")
			ok = false
		else:
			var mode := int(scroll.vertical_scroll_mode)
			var show_never := int(ScrollContainer.SCROLL_MODE_SHOW_NEVER)
			var disabled := int(ScrollContainer.SCROLL_MODE_DISABLED)
			if mode != show_never and mode != disabled:
				print("[PAUSE] FAIL scroll mode ", mode)
				ok = false
			var view := scroll.get_global_rect()
			var resume_bottom := resume.get_global_rect().end.y
			var display_top := display.get_global_rect().position.y
			if mode == show_never:
				if resume_bottom > view.end.y + 2.0:
					print("[PAUSE] FAIL Resume clipped ", resume_bottom, " view ", view.end.y)
					ok = false
				if display_top < view.end.y - 1.0 and display.get_global_rect().end.y > view.position.y:
					print("[PAUSE] FAIL Display sliver top ", display_top, " view ", view.end.y)
					ok = false
			print("[PAUSE] mode=", mode, " resume_bottom=", snapped(resume_bottom, 0.1), " display_top=", snapped(display_top, 0.1), " view=", snapped(view.end.y, 0.1))
	else:
		print("[PAUSE] FAIL could not center pause card")
		ok = false

	var settings_packed := load("res://scenes/ui/SettingsMenu.tscn")
	var settings = settings_packed.instantiate()
	root.add_child(settings)
	settings.visible = true
	for _s in range(6):
		await process_frame
	var done := settings.find_child("CloseBtn", true, false) as Control
	var ver := settings.find_child("Ver", true, false) as Control
	var view_h := 540.0
	var cfg = root.get_node_or_null("Config")
	if cfg and "H" in cfg:
		view_h = float(cfg.H)
	if done == null or ver == null:
		print("[SET] FAIL missing Done or version line")
		ok = false
	else:
		var done_r := done.get_global_rect()
		var ver_r := ver.get_global_rect()
		print("[SET] done_bottom=", snapped(done_r.end.y, 0.1), " ver_bottom=", snapped(ver_r.end.y, 0.1), " view=", view_h)
		if done_r.end.y > view_h + 1.0 or ver_r.end.y > view_h + 1.0:
			print("[SET] FAIL footer below the 540p view")
			ok = false
		if ver_r.position.y < done_r.position.y:
			print("[SET] FAIL version line is above Done")
			ok = false

	if ok:
		print("[BG] PASS")
		quit(0)
	else:
		print("[BG] FAIL")
		quit(1)
