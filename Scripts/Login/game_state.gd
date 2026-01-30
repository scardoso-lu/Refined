# game_state.gd (Autoload)
extends Node

# --- 1. THE DATABASE (CONFIGURATION) ---
const CHARACTER_DB = {
	"hero_samurai": "res://Data/Player/samurai.tres",
	"hero_void": "res://Data/Player/void.tres",
	"hero_ninja": "res://Data/Player/ninja.tres",
	"hero_lifebinder": "res://Data/Player/lifebinder.tres",
	"hero_warrior": "res://Data/Player/warrior.tres"
}

# --- 2. SELECTION STATE ---
var selected_character_id: String = "hero_samurai" # Default fallback

# ... (Existing code for CHARACTER_DB, current_hp, etc) ...

const SAVE_FILE_PATH = "user://saved__game.dat"

# --- 3. SESSION STATE ---
# These variables remember the player's status between levels.
# -1 indicates "Fresh Start" (use max stats from CharacterDef)
var current_hp: int = -1 
var current_gold: int = 0
var current_xp: int = 0
var current_level: int = 1

# --- 4. NAVIGATION STATE  ---
# Where should the player appear in the next scene?
var current_scene: String = "level_01.tscn"
var target_spawn_tag: String = "Default" 

# --- FUNCTIONS ---

# (Existing) Gets the static data (Max HP, Sprite, Speed)
func get_selected_character_data() -> CharacterDef:
	if not CHARACTER_DB.has(selected_character_id):
		push_error("Error: ID '%s' not found in DB" % selected_character_id)
		return null
	return load(CHARACTER_DB[selected_character_id])

# (New) Called by the Portal before changing scenes
func save_player_state(player_node):
	current_hp = player_node.current_health
	current_gold = player_node.gold
	current_xp = player_node.experience
	current_level = player_node.current_level
	save_game(player_node.current_scene)

# 1. SAVE TO DISK
func save_game(current_scene_path: String):
	var save_data = {
		"hp": current_hp,
		"gold": current_gold,
		"xp": current_xp,
		"level": current_level,
		"scene": current_scene_path, # <--- We save "res://Levels/Level_50.tscn"
		"character_id": selected_character_id
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	print("Game Saved!")

# 2. LOAD FROM DISK
func load_game():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return false # No save file found
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var data = JSON.parse_string(content)
	
	# Restore State to RAM
	current_hp = data["hp"]
	current_gold = data["gold"]
	current_xp = data["xp"]
	current_level = data["level"]
	selected_character_id = data["character_id"]
	
	# Return the scene path so the Main Menu knows where to go
	return data["scene"]
