extends RefinedTest
class_name TestMonsterRepository

# ── Helpers ──────────────────────────────────────────────────────────────────

func _def(hp: int = 100, dmg: int = 10, xp: int = 50, spd: float = 80.0) -> MonsterDef:
	var d := MonsterDef.new()
	d.base_hp = hp
	d.base_damage = dmg
	d.base_xp = xp
	d.speed = spd
	return d

func _repo(d: MonsterDef = null, difficulty: float = 1.0) -> MonsterRepository:
	var r := MonsterRepository.new()
	r.init(d if d else _def(), difficulty)
	return r

# ── init / scaling ────────────────────────────────────────────────────────────

func test_init_sets_positive_max_health() -> void:
	assert_gt(_repo().max_health, 0.0, "max_health is positive after init")

func test_init_sets_current_health_equal_to_max() -> void:
	var r := _repo()
	assert_eq(r.current_health, r.max_health, "current_health == max_health after init")

func test_init_sets_positive_damage() -> void:
	assert_gt(_repo().current_damage, 0.0, "current_damage is positive after init")

func test_init_sets_positive_xp_reward() -> void:
	assert_gt(_repo().xp_reward, 0, "xp_reward is positive after init")

func test_higher_difficulty_increases_max_health() -> void:
	var easy := _repo(_def(), 1.0)
	var hard := _repo(_def(), 3.0)
	assert_gt(hard.max_health, easy.max_health, "difficulty 3 gives more HP than difficulty 1")

func test_higher_difficulty_increases_xp_reward() -> void:
	var easy := _repo(_def(), 1.0)
	var hard := _repo(_def(), 3.0)
	assert_gt(hard.xp_reward, easy.xp_reward, "higher difficulty gives more XP")

func test_higher_base_hp_def_yields_more_health() -> void:
	var weak := _repo(_def(50))
	var tough := _repo(_def(200))
	assert_gt(tough.max_health, weak.max_health, "higher base HP gives more max_health")

# ── apply_damage ─────────────────────────────────────────────────────────────

func test_apply_damage_reduces_health() -> void:
	var r := _repo()
	var before := r.current_health
	r.apply_damage(10)
	assert_lt(r.current_health, before, "health decreases after damage")

func test_apply_damage_returns_remaining_health() -> void:
	var r := _repo()
	var before := r.current_health
	var result := r.apply_damage(5)
	assert_eq(result, before - 5, "return value is remaining health")

# ── is_dead ───────────────────────────────────────────────────────────────────

func test_not_dead_when_health_positive() -> void:
	assert_false(_repo().is_dead(), "full HP monster is not dead")

func test_dead_when_health_zero() -> void:
	var r := _repo()
	r.current_health = 0.0
	assert_true(r.is_dead(), "monster is dead at exactly 0 HP")

func test_dead_when_health_negative() -> void:
	var r := _repo()
	r.current_health = -1.0
	assert_true(r.is_dead(), "monster is dead at negative HP")

func test_lethal_damage_triggers_death() -> void:
	var r := _repo()
	r.apply_damage(int(r.max_health) + 100)
	assert_true(r.is_dead(), "fatal damage kills the monster")

# ── get_speed ─────────────────────────────────────────────────────────────────

func test_get_speed_returns_def_speed() -> void:
	var r := _repo(_def(100, 10, 50, 120.0))
	assert_eq(r.get_speed(), 120.0, "get_speed matches the MonsterDef speed")
