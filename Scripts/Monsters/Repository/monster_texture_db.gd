extends Node

# --- CONFIGURATION ---

const TIER_DATA = {
	"Tier_1": {
		"min_amount": 1,
		"max_amount": 3,
		"monsters": [
			"res://Data/Monster/bob.tres",
			"res://Data/Monster/small_globin.tres",
			"res://Data/Monster/wood.tres",
			"res://Data/Monster/grass.tres"
		]
	},
	"Tier_2": {
		"min_amount": 2,
		"max_amount": 4,
		"monsters": [
			"res://Data/Monster/bagba.tres",
			"res://Data/Monster/rock.tres",
			"res://Data/Monster/water.tres",
			"res://Data/Monster/half_smile.tres"
		]
	},
	"Tier_3": {
		"min_amount": 3,
		"max_amount": 5,
		"monsters": [
			"res://Data/Monster/fire.tres",
			"res://Data/Monster/eletric.tres",
			"res://Data/Monster/rock_golem.tres",
			"res://Data/Monster/little_dragon.tres"
		]
	}
}

const SIN_POOL = [
	"res://Data/Monster/envy.tres",
	"res://Data/Monster/gluttony.tres",
	"res://Data/Monster/greed.tres",
	"res://Data/Monster/pride.tres",
	"res://Data/Monster/sloth.tres",
	"res://Data/Monster/wrath.tres"
]

# --- MAIN FUNCTION ---

func generate_wave_data(level_name: String, spawn_point: String) -> Array:
	var wave_list = []
	
	# 1. SELECT TIER (Based on Level)
	var level_number = level_name.trim_prefix("level_").to_int()
	var current_tier_key = ""

	if level_number <= 3:
		current_tier_key = "Tier_1"
	elif level_number <= 7:
		current_tier_key = "Tier_2"
	else:
		current_tier_key = "Tier_3"
	
	var tier_config = TIER_DATA[current_tier_key]
	
	# 2. PICK STANDARD MONSTER
	var selected_monster_path = tier_config["monsters"][randi() % tier_config["monsters"].size()]
	
	# 3. DETERMINE AMOUNT (Influenced by Spawn Point)
	var final_amount = 1
	
	if spawn_point.ends_with("01"):
		# "Safe" Spawn Point -> Minimum amount
		final_amount = tier_config["min_amount"]
	else:
		# "Danger" Spawn Point -> Random Range (Min+1 to Max+1)
		var min_c = tier_config["min_amount"] + 1
		var max_c = tier_config["max_amount"] + 1
		final_amount = randi_range(min_c, max_c)

	# 4. ADD STANDARD MONSTERS TO WAVE
	for i in range(final_amount):
		wave_list.append(selected_monster_path)
		
	return wave_list
