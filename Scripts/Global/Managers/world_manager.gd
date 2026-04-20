extends Node

# Global Signals for component communication
signal difficulty_updated(new_mult)
signal monster_slain(xp_reward)
signal shop_opened(shop_id: String)

var zone_difficulty: float = 1.0

func _ready():
	# Connect global signal to player reward logic
	monster_slain.connect(process_reward)
	difficulty_updated.connect(get_difficulty_multiplier)

func get_difficulty_multiplier() -> float:
	var level := float(GameState.current_level)
	var growth := max(1.0, level * log(level + 1.0))
	return zone_difficulty * pow(growth, 0.85)

func process_reward(xp_amount: int, spawn_level: int = 0):
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
	if spawn_level > 0 and player.get_level() - spawn_level > 5:
		return
	player.collect_loot(1, xp_amount)
