# game_state.gd (Autoload)
extends Node

# --- 1. THE DATABASE ---
# Map your Server IDs to your File Paths here.
const CHARACTER_DB = {
	#page 1
	"hero_samurai": "res://Data/Player/samurai.tres",
	"hero_void": "res://Data/Player/void.tres",
	"hero_ninja": "res://Data/Player/ninja.tres",
	"hero_lifebinder": "res://Data/Player/lifebinder.tres",
	
	#page 2
	"hero_warrior": "res://Data/Player/warrior.tres"
	
}

# --- 2. THE STATE ---
# This is the variable your Server updates.
var selected_character_id: String 

# --- 3. THE HELPER FUNCTION ---
# The Level calls this to get the correct file.
func get_selected_character_data() -> CharacterDef:
	# Check if ID exists
	if not CHARACTER_DB.has(selected_character_id):
		push_error("Error: ID '%s' not found in DB" % selected_character_id)
		return null
		
	# Load and return the Resource
	return load(CHARACTER_DB[selected_character_id])
