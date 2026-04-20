extends RefinedTest
class_name TestPlayerRepository

# ── Helpers ──────────────────────────────────────────────────────────────────

func _repo() -> PlayerRepository:
	var r := PlayerRepository.new()
	r.init(null)
	return r

func _def(hp: int = 100, dmg: int = 20, level: int = 1) -> CharacterDef:
	var d := CharacterDef.new()
	d.base_max_health = hp
	d.base_damage = dmg
	d.player_level = level
	d.experience = 0
	d.xp_next_level = 100
	d.base_move_speed = 300.0
	d.jump_velocity = -400.0
	return d

func _item(cost: int, heal: int = 0) -> ItemDef:
	var it := ItemDef.new()
	it.cost = cost
	it.heal_amount = heal
	return it

# ── init ─────────────────────────────────────────────────────────────────────

func test_init_null_def_max_health_is_positive() -> void:
	var r := _repo()
	assert_gt(r.max_health, 0, "max_health with null def")

func test_init_sets_current_health_equal_to_max() -> void:
	var r := _repo()
	assert_eq(r.current_health, r.max_health, "current_health == max_health after init")

func test_init_with_def_reads_player_level() -> void:
	var r := PlayerRepository.new()
	r.init(_def(100, 20, 3))
	assert_eq(r.current_level, 3, "current_level from CharacterDef")

func test_init_with_def_reads_experience() -> void:
	var r := PlayerRepository.new()
	var d := _def()
	d.experience = 50
	r.init(d)
	assert_eq(r.experience, 50, "experience from CharacterDef")

func test_init_computes_xp_next_level_from_level() -> void:
	var r := PlayerRepository.new()
	r.init(_def())  # level 1 → int(100 * pow(1, 1.8)) = 100
	assert_eq(r.xp_next_level, 100, "xp_next_level is derived from the level formula")

# ── apply_damage ─────────────────────────────────────────────────────────────

func test_apply_damage_reduces_health() -> void:
	var r := _repo()
	var before := r.current_health
	r.apply_damage(10)
	assert_eq(r.current_health, before - 10, "health reduced by 10")

func test_apply_damage_returns_remaining_health() -> void:
	var r := _repo()
	var before := r.current_health
	var result := r.apply_damage(30)
	assert_eq(result, before - 30, "return value is remaining health")

func test_apply_damage_zero_is_no_op() -> void:
	var r := _repo()
	var before := r.current_health
	r.apply_damage(0)
	assert_eq(r.current_health, before, "zero damage does not change health")

func test_apply_damage_allows_negative_health() -> void:
	var r := _repo()
	r.current_health = 5
	r.apply_damage(10)
	assert_lt(r.current_health, 0, "overkill goes below zero")

func test_apply_damage_full_hp_to_zero() -> void:
	var r := _repo()
	r.apply_damage(r.current_health)
	assert_eq(r.current_health, 0, "exact lethal damage reaches zero")

# ── compute_velocity_x ───────────────────────────────────────────────────────

func test_velocity_with_right_input_is_positive() -> void:
	var r := _repo()
	var v := r.compute_velocity_x(0.0, 1.0, 0.016, 300.0)
	assert_gt(v, 0.0, "moving right yields positive velocity")

func test_velocity_with_left_input_is_negative() -> void:
	var r := _repo()
	var v := r.compute_velocity_x(0.0, -1.0, 0.016, 300.0)
	assert_lt(v, 0.0, "moving left yields negative velocity")

func test_velocity_no_input_decelerates() -> void:
	var r := _repo()
	var v := r.compute_velocity_x(300.0, 0.0, 0.016, 300.0)
	assert_lt(v, 300.0, "no input decelerates")
	assert_ge(v, 0.0, "deceleration does not overshoot zero")

func test_velocity_no_input_from_negative_decelerates_toward_zero() -> void:
	var r := _repo()
	var v := r.compute_velocity_x(-300.0, 0.0, 0.016, 300.0)
	assert_gt(v, -300.0, "friction moves velocity toward zero from negative")
	assert_le(v, 0.0, "friction does not overshoot zero from negative side")

# ── add_loot ─────────────────────────────────────────────────────────────────

func test_add_loot_coin_adds_gold() -> void:
	var r := _repo()
	r.gold = 0
	r.add_loot(0, 10)
	assert_eq(r.gold, 10, "coin type adds gold 1:1")

func test_add_loot_xp_type_adds_experience() -> void:
	var r := _repo()
	r.experience = 0
	r.gold = 0
	r.xp_next_level = 9999
	r.add_loot(1, 10)
	assert_eq(r.experience, 10, "xp reward type adds experience")
	assert_eq(r.gold, 0, "xp reward type does not add gold")

func test_add_loot_adds_experience() -> void:
	var r := _repo()
	r.experience = 0
	r.xp_next_level = 9999
	r.add_loot(1, 25)
	assert_eq(r.experience, 25, "xp type adds experience equal to amount")

func test_add_loot_returns_packet_with_current_gold() -> void:
	var r := _repo()
	r.gold = 5
	var pkt := r.add_loot(0, 10)
	assert_eq(pkt["gold"], 15, "packet reports updated gold total")

func test_add_loot_returns_packet_with_current_xp() -> void:
	var r := _repo()
	r.experience = 0
	r.xp_next_level = 9999
	var pkt := r.add_loot(1, 20)
	assert_eq(pkt["xp"], 20, "packet reports updated xp")

func test_add_loot_triggers_level_up_when_xp_exceeds_threshold() -> void:
	var r := _repo()
	r.experience = 0
	r.xp_next_level = 50
	var pkt := r.add_loot(1, 55)
	assert_true(pkt["leveled_up"], "leveled_up flag set when XP exceeds threshold")

func test_add_loot_level_up_increments_current_level() -> void:
	var r := _repo()
	r.experience = 0
	r.xp_next_level = 50
	var pkt := r.add_loot(1, 55)
	assert_eq(pkt["level"], 2, "current_level increments on level-up")

func test_add_loot_level_up_restores_health() -> void:
	var r := _repo()
	r.current_health = 1
	r.xp_next_level = 10
	r.add_loot(1, 15)
	assert_gt(r.current_health, 1, "health restored on level-up")

func test_add_loot_no_level_up_flag_when_xp_insufficient() -> void:
	var r := _repo()
	r.experience = 0
	r.xp_next_level = 100
	var pkt := r.add_loot(0, 5)
	assert_false(pkt["leveled_up"], "leveled_up is false when XP insufficient")

# ── get_outgoing_damage ───────────────────────────────────────────────────────

func test_outgoing_damage_is_positive() -> void:
	var r := _repo()
	assert_gt(r.get_outgoing_damage(), 0, "outgoing damage is positive")

func test_outgoing_damage_at_least_base_damage() -> void:
	var r := _repo()
	assert_ge(r.get_outgoing_damage(), r.damage, "scaling never reduces damage below base")

# ── try_purchase_item ─────────────────────────────────────────────────────────

func test_purchase_succeeds_with_enough_gold() -> void:
	var r := _repo()
	r.gold = 100
	assert_true(r.try_purchase_item(_item(50)), "purchase succeeds")

func test_purchase_deducts_gold() -> void:
	var r := _repo()
	r.gold = 100
	r.try_purchase_item(_item(50))
	assert_eq(r.gold, 50, "gold reduced by item cost")

func test_purchase_exact_gold_succeeds() -> void:
	var r := _repo()
	r.gold = 50
	assert_true(r.try_purchase_item(_item(50)), "exact gold is sufficient")

func test_purchase_exact_gold_leaves_zero() -> void:
	var r := _repo()
	r.gold = 50
	r.try_purchase_item(_item(50))
	assert_eq(r.gold, 0, "gold reaches zero when exact")

func test_purchase_fails_with_insufficient_gold() -> void:
	var r := _repo()
	r.gold = 30
	assert_false(r.try_purchase_item(_item(50)), "purchase fails with not enough gold")

func test_purchase_does_not_deduct_on_failure() -> void:
	var r := _repo()
	r.gold = 30
	r.try_purchase_item(_item(50))
	assert_eq(r.gold, 30, "gold unchanged when purchase fails")

func test_purchase_zero_cost_always_succeeds() -> void:
	var r := _repo()
	r.gold = 0
	assert_true(r.try_purchase_item(_item(0)), "free items always purchasable")

# ── stat scaling with level ────────────────────────────────────────────────────

func test_higher_level_yields_more_max_health() -> void:
	var r1 := PlayerRepository.new()
	var r5 := PlayerRepository.new()
	r1.init(_def(100, 20, 1))
	r5.init(_def(100, 20, 5))
	assert_gt(r5.max_health, r1.max_health, "level 5 has more HP than level 1")

func test_higher_level_yields_more_damage() -> void:
	var r1 := PlayerRepository.new()
	var r5 := PlayerRepository.new()
	r1.init(_def(100, 20, 1))
	r5.init(_def(100, 20, 5))
	assert_gt(r5.damage, r1.damage, "level 5 hits harder than level 1")

func test_higher_base_hp_def_yields_more_health() -> void:
	var r_low := PlayerRepository.new()
	var r_high := PlayerRepository.new()
	r_low.init(_def(50, 20, 1))
	r_high.init(_def(200, 20, 1))
	assert_gt(r_high.max_health, r_low.max_health, "higher base HP def results in more max health")
