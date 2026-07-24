extends SceneTree
## All HTML sfx() types exist in SfxSynth; melee release plays weapon snd.
## Run: godot --path godot --headless --script res://scripts/tools/test_sfx_envelopes.gd

const TYPES := [
	"shoot", "hit", "kill", "graze", "item", "power", "extend", "bomb", "hurt",
	"card", "win", "slash", "whip", "thud", "boom", "claw", "warp",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var src := FileAccess.get_file_as_string("res://scripts/audio/SfxSynth.gd")
	for t in TYPES:
		if ('"%s"' % t) not in src and ("'%s'" % t) not in src:
			print("[FAIL] missing sfx type ", t)
			ok = false
		else:
			print("[SFX] ", t, " ok")
	var ms := FileAccess.get_file_as_string("res://scripts/systems/MeleeSystem.gd")
	if 'm.get("snd"' not in ms and "m.get(\"snd\"" not in ms:
		print("[FAIL] melee must play m.snd")
		ok = false
	else:
		print("[SFX] melee snd wire ok")
	if 'sfx("graze")' not in ms:
		print("[FAIL] melee should also graze sfx")
		ok = false
	else:
		print("[SFX] melee graze sfx ok")
	# Fire synth once headless (should not crash)
	var synth = load("res://scripts/audio/SfxSynth.gd").new()
	root.add_child(synth)
	await process_frame
	for t in TYPES:
		if synth.has_method("play"):
			synth.play(t, 0.01)
	await process_frame
	print("[SFX] play all smoke ok")
	print("[PASS]" if ok else "[FAIL]")
	quit(0 if ok else 1)
