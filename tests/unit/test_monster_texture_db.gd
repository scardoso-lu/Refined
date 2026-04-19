extends RefinedTest
class_name TestMonsterTextureDb

# monster_texture_db.gd has no class_name, so we load the script directly.
# generate_wave_data() only returns path strings — no resources are loaded.
const _DB_SCRIPT := preload("res://Scripts/Monsters/Repository/monster_texture_db.gd")

func _db() -> Node:
	var n := Node.new()
	n.set_script(_DB_SCRIPT)
	return n

# ── tier selection ────────────────────────────────────────────────────────────

func test_level_01_uses_tier_1_monsters() -> void:
	var db := _db()
	for _i in range(10):
		var wave: Array = db.generate_wave_data("level_01", "spawn_01")
		for path in wave:
			assert_true(path in db.TIER_DATA["Tier_1"]["monsters"],
					"level_01 path not in Tier_1: %s" % path)

func test_level_03_uses_tier_1_monsters() -> void:
	var db := _db()
	for _i in range(5):
		for path in db.generate_wave_data("level_03", "spawn_01"):
			assert_true(path in db.TIER_DATA["Tier_1"]["monsters"], "level_03 is Tier_1")

func test_level_04_uses_tier_2_monsters() -> void:
	var db := _db()
	for _i in range(10):
		for path in db.generate_wave_data("level_04", "spawn_01"):
			assert_true(path in db.TIER_DATA["Tier_2"]["monsters"],
					"level_04 path not in Tier_2: %s" % path)

func test_level_07_uses_tier_2_monsters() -> void:
	var db := _db()
	for _i in range(5):
		for path in db.generate_wave_data("level_07", "spawn_01"):
			assert_true(path in db.TIER_DATA["Tier_2"]["monsters"], "level_07 is Tier_2")

func test_level_08_uses_tier_3_monsters() -> void:
	var db := _db()
	for _i in range(10):
		for path in db.generate_wave_data("level_08", "spawn_01"):
			assert_true(path in db.TIER_DATA["Tier_3"]["monsters"],
					"level_08 path not in Tier_3: %s" % path)

func test_level_20_uses_tier_3_monsters() -> void:
	var db := _db()
	for _i in range(5):
		for path in db.generate_wave_data("level_20", "spawn_02"):
			assert_true(path in db.TIER_DATA["Tier_3"]["monsters"], "level_20 is Tier_3")

# ── safe spawn count (ends with "01") ────────────────────────────────────────

func test_safe_spawn_tier_1_returns_exactly_min_amount() -> void:
	var db := _db()
	var expected: int = db.TIER_DATA["Tier_1"]["min_amount"]
	for _i in range(20):
		var wave: Array = db.generate_wave_data("level_01", "spawn_01")
		assert_eq(wave.size(), expected, "safe spawn size should equal Tier_1 min_amount")

func test_safe_spawn_tier_2_returns_exactly_min_amount() -> void:
	var db := _db()
	var expected: int = db.TIER_DATA["Tier_2"]["min_amount"]
	for _i in range(20):
		var wave: Array = db.generate_wave_data("level_04", "spawn_01")
		assert_eq(wave.size(), expected, "safe spawn size should equal Tier_2 min_amount")

# ── danger spawn count (does not end with "01") ───────────────────────────────

func test_danger_spawn_count_at_least_min_plus_one() -> void:
	var db := _db()
	var min_expected: int = db.TIER_DATA["Tier_1"]["min_amount"] + 1
	for _i in range(30):
		var wave: Array = db.generate_wave_data("level_01", "spawn_02")
		assert_ge(wave.size(), min_expected, "danger spawn has at least min+1 monsters")

func test_danger_spawn_count_at_most_max_plus_one() -> void:
	var db := _db()
	var max_expected: int = db.TIER_DATA["Tier_1"]["max_amount"] + 1
	for _i in range(30):
		var wave: Array = db.generate_wave_data("level_01", "spawn_02")
		assert_le(wave.size(), max_expected, "danger spawn has at most max+1 monsters")

# ── output format ─────────────────────────────────────────────────────────────

func test_wave_is_never_empty() -> void:
	var db := _db()
	for level in ["level_01", "level_05", "level_10"]:
		var wave: Array = db.generate_wave_data(level, "spawn_01")
		assert_gt(wave.size(), 0, "wave must never be empty")

func test_wave_entries_are_strings() -> void:
	var db := _db()
	for entry in db.generate_wave_data("level_05", "spawn_03"):
		assert_true(entry is String, "each wave entry is a path string")

func test_wave_entries_start_with_res_prefix() -> void:
	var db := _db()
	for entry in db.generate_wave_data("level_05", "spawn_02"):
		assert_true((entry as String).begins_with("res://"), "wave paths start with res://")
