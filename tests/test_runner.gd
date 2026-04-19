extends Node

const SUITES: Array[String] = [
	"res://tests/unit/test_player_repository.gd",
	"res://tests/unit/test_monster_repository.gd",
	"res://tests/unit/test_monster_texture_db.gd",
	"res://tests/unit/test_game_state.gd",
]

func _ready() -> void:
	_run_all()

func _run_all() -> void:
	var total_pass := 0
	var total_fail := 0

	print("\n╔══════════════════════════════════════╗")
	print("║       REFINED  UNIT  TEST  SUITE     ║")
	print("╚══════════════════════════════════════╝\n")

	for path in SUITES:
		var script: GDScript = load(path)
		var suite: RefinedTest = script.new()
		add_child(suite)

		var result: Dictionary = suite.run_tests()
		total_pass += result["passes"]
		total_fail += result["failures"]

		var icon := "✓" if result["failures"] == 0 else "✗"
		print("%s  %s  (%d passed, %d failed)" % [
			icon, result["suite"], result["passes"], result["failures"]
		])
		for err in result["errors"]:
			print("     → %s" % err)

		suite.queue_free()

	print("\n──────────────────────────────────────")
	print("TOTAL: %d passed, %d failed" % [total_pass, total_fail])
	print("──────────────────────────────────────\n")

	if not OS.has_feature("editor"):
		get_tree().quit(1 if total_fail > 0 else 0)
