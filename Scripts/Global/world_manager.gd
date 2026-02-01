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
	var global_factor = (GameState.current_level - 1) * 0.1
	return zone_difficulty + global_factor

func process_reward(xp_amount: int):
	# Find the player in the current tree dynamically
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.collect_loot(1, xp_amount)
