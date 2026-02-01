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
var selected_character_id: String = "hero_samurai"

# --- 3. SESSION STATE (The Cache) ---
# Used by Level Manager to inject data into the Player Controller
var current_hp: int = -1 
var current_gold: int = 0
var current_xp: int = 0
var current_level: int = 1

# --- 4. NAVIGATION ---
var target_spawn_tag: String = "Default" 

# --- FUNCTIONS ---

# Purely a Data Provider
func get_selected_character_data() -> CharacterDef:
	if not CHARACTER_DB.has(selected_character_id):
		return null
	return load(CHARACTER_DB[selected_character_id])

# Call this when "Try Again" is pressed
func reset_session_health():
	# Setting to -1 tells the Level Manager to use 
	# the Base Max HP from the CharacterDef instead of the cache
	current_hp = -1 

# The Portal calls this to move data between levels
func update_session_cache(hp: int, gold: int, xp: int, level: int):
	current_hp = hp
	current_gold = gold
	current_xp = xp
	current_level = level
