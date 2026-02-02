extends Node
class_name MonsterRepository

var data: MonsterDef
var max_health: float
var current_health: float
var current_damage: float
var xp_reward: int

func init(def: MonsterDef, difficulty: float):
	data = def
	_apply_scaling(difficulty)

func _apply_scaling(difficulty: float):
	var level_zone = 1 # Could be passed in based on map
	var log_term := log(level_zone + 1.0)
	var growth = level_zone * log_term

	max_health = data.base_hp * pow(growth, 0.95) * difficulty
	max_health = max(5.0, max_health)
	current_health = max_health

	current_damage = data.base_damage * pow(growth, 0.85)
	current_damage = max(1.0, current_damage)

	xp_reward = int(data.base_xp * log_term * difficulty)
	xp_reward = max(1, xp_reward)

func apply_damage(amount: int) -> float:
	current_health -= amount
	return current_health

func is_dead() -> bool:
	return current_health <= 0

func get_speed() -> float:
	return data.speed if data else 100.0
