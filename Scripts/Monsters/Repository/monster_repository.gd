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
	max_health = max(5.0, data.base_hp * difficulty)
	current_health = max_health
	current_damage = max(1.0, data.base_damage * difficulty)
	xp_reward = max(1, int(data.base_xp * difficulty))

func apply_damage(amount: int) -> float:
	current_health -= amount
	return current_health

func is_dead() -> bool:
	return current_health <= 0

func get_speed() -> float:
	return data.speed if data else 100.0
