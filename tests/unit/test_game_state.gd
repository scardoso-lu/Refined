extends RefinedTest
class_name TestGameState

# game_state.gd is an autoload (no class_name).  We instantiate a fresh copy
# of the script for each test so we never mutate the live singleton.
const _SCRIPT := preload("res://Scripts/Login/game_state.gd")

func _gs() -> Node:
	var n := Node.new()
	n.set_script(_SCRIPT)
	return n

# ── initial state ─────────────────────────────────────────────────────────────

func test_default_selected_character_is_hero_samurai() -> void:
	var gs := _gs()
	assert_eq(gs.selected_character_id, "hero_samurai", "default character is hero_samurai")

func test_default_current_hp_is_minus_one() -> void:
	var gs := _gs()
	assert_eq(gs.current_hp, -1, "default hp sentinel is -1 (use base max HP)")

func test_default_gold_is_zero() -> void:
	var gs := _gs()
	assert_eq(gs.current_gold, 0, "default gold is 0")

func test_default_xp_is_zero() -> void:
	var gs := _gs()
	assert_eq(gs.current_xp, 0, "default XP is 0")

func test_default_level_is_one() -> void:
	var gs := _gs()
	assert_eq(gs.current_level, 1, "default level is 1")

# ── update_session_cache ──────────────────────────────────────────────────────

func test_update_session_cache_stores_hp() -> void:
	var gs := _gs()
	gs.update_session_cache(75, 0, 0, 1)
	assert_eq(gs.current_hp, 75, "session cache stores HP")

func test_update_session_cache_stores_gold() -> void:
	var gs := _gs()
	gs.update_session_cache(100, 500, 0, 1)
	assert_eq(gs.current_gold, 500, "session cache stores gold")

func test_update_session_cache_stores_xp() -> void:
	var gs := _gs()
	gs.update_session_cache(100, 0, 320, 1)
	assert_eq(gs.current_xp, 320, "session cache stores XP")

func test_update_session_cache_stores_level() -> void:
	var gs := _gs()
	gs.update_session_cache(100, 0, 0, 7)
	assert_eq(gs.current_level, 7, "session cache stores level")

func test_update_session_cache_overwrites_previous_values() -> void:
	var gs := _gs()
	gs.update_session_cache(50, 100, 200, 3)
	gs.update_session_cache(80, 250, 400, 5)
	assert_eq(gs.current_hp, 80, "second update overwrites HP")
	assert_eq(gs.current_gold, 250, "second update overwrites gold")
	assert_eq(gs.current_level, 5, "second update overwrites level")

# ── reset_session_health ──────────────────────────────────────────────────────

func test_reset_session_health_sets_hp_to_sentinel() -> void:
	var gs := _gs()
	gs.update_session_cache(50, 100, 0, 1)
	gs.reset_session_health()
	assert_eq(gs.current_hp, -1, "reset sets hp back to -1 sentinel")

func test_reset_session_health_does_not_clear_gold() -> void:
	var gs := _gs()
	gs.update_session_cache(50, 999, 0, 1)
	gs.reset_session_health()
	assert_eq(gs.current_gold, 999, "reset does not touch gold")

# ── character database ────────────────────────────────────────────────────────

func test_character_db_contains_all_five_heroes() -> void:
	var gs := _gs()
	var expected := ["hero_samurai", "hero_void", "hero_ninja", "hero_lifebinder", "hero_warrior"]
	for hero_id in expected:
		assert_true(gs.CHARACTER_DB.has(hero_id), "CHARACTER_DB contains %s" % hero_id)

func test_get_selected_character_data_returns_null_for_invalid_id() -> void:
	var gs := _gs()
	gs.selected_character_id = "hero_does_not_exist"
	var result = gs.get_selected_character_data()
	assert_eq(result, null, "invalid character ID returns null")

func test_get_selected_character_data_returns_character_def() -> void:
	var gs := _gs()
	gs.selected_character_id = "hero_samurai"
	var result = gs.get_selected_character_data()
	assert_true(result is CharacterDef, "valid ID returns a CharacterDef resource")
