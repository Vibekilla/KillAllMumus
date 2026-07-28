extends SceneTree
## Reproduce item-use crashes for each consumable key (isolated ConsumableSystem).
## Run: godot --path godot --headless --script res://scripts/tools/test_consume_crash.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	await process_frame
	var r := root
	var PS = r.get_node_or_null("/root/ProgressStore")
	var GS = r.get_node_or_null("/root/GameState")
	var IS = r.get_node_or_null("/root/ItemSystem")
	print("[ENV] PS=", PS != null, " GS=", GS != null, " IS=", IS != null)
	if PS == null or GS == null:
		print("[FAIL] missing autoloads")
		quit(1)
		return
	if not (PS.progress is Dictionary):
		PS.progress = {}
	PS.progress["consum"] = {
		"honeycomb": 2, "stardust": 1, "bubbles": 1, "banana": 1,
		"vial": 1, "wormhole": 1, "bulltears": 1, "wagyu": 1,
		"bullsouls": 1, "galaxygas": 1, "clover": 1, "unholy": 1,
	}
	PS.progress["arsenal"] = {
		"i": ["honeycomb", "stardust", "bubbles", "banana", "vial", "wormhole",
			"bulltears", "wagyu", "bullsouls", "galaxygas", "clover", "unholy"],
		"w": ["laser"], "s": ["mech"], "m": ["katana"],
	}
	GS.state = GS.State.PLAY
	GS.lives = 3
	GS.power = 1.0
	GS.special_meter = 0.0

	var player: CharacterBody2D = load("res://scripts/tools/player_stub_for_consum.gd").new()
	player.name = "PlayerStub"
	player.add_to_group("player")
	r.add_child(player)

	var cons = load("res://scripts/systems/ConsumableSystem.gd").new()
	player.add_child(cons)
	await process_frame

	var keys: Array = cons.arsenal_i()
	print("[ENV] arsenal keys=", keys)
	for i in range(keys.size()):
		cons.selected = i
		var k := str(keys[i])
		print("[TRY] ", k, " qty=", cons.qty(k))
		var ok: bool = cons.consume_selected()
		print("[RES] ", k, " ok=", ok, " qty=", cons.qty(k),
			" rapid=", player.rapid_t, " shield=", player.shield_t,
			" phase=", player.phase_t, " vial=", player.vial_t)
		await process_frame
		if IS and IS.has_method("_process"):
			IS._process(1.0 / 60.0)
		await process_frame

	# Corrupt shapes
	print("[TRY] consum as Array — inventory() must stay Dictionary")
	PS.progress["consum"] = []
	var inv = cons.inventory()
	print("[INV] type=", typeof(inv), " val=", inv)
	if not (inv is Dictionary):
		print("[FAIL] inventory() returned non-Dictionary after corrupt consum")
		quit(1)
		return

	PS.progress["consum"] = {"honeycomb": 1}
	PS.progress["arsenal"] = {"i": ["honeycomb"], "w": [], "s": [], "m": []}
	cons.selected = 0
	print("[RES restore] ", cons.consume_selected())

	print("[PASS] consume matrix finished")
	quit(0)
