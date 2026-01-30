extends Area2D

# --- CONFIGURATION ---
# 1. Drag the target level file here (e.g., Level_02.tscn)
@export_file("*.tscn") var next_scene_path: String

# 2. The name of the Marker2D in the next level where you want to land.
# Example: "From_Lvl1" or "North_Gate"
@export var target_spawn_tag: String = "Default"

# 3. Should this portal save the game to disk immediately?
@export var auto_save_on_enter: bool = true

func _ready():
	# Connect the signal via code to ensure it's always linked
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# DEBUG: See what is hitting the portal
	print("Hit Portal: ", body.name) 

	# 1. FILTER: Ignore the TileMap or Enemies
	if not body.is_in_group("Player"):
		return # Stop here! Do not proceed.
	elif body.is_in_group("Player"):	
		# Only the Player can trigger portals
		print("Body entered on portal", body)
		
		# --- STEP 1: SAVE STATE TO RAM ---
		# Snapshots the player's current Health, Gold, and XP into the Global GameState.
		# This ensures they don't reset to full health in the next room.
		if GameState.has_method("save_player_state"):
			GameState.save_player_state(body)
			
			# --- STEP 2: SAVE TO DISK (Optional) ---
			# Persist progress so they can "Continue" after closing the game.
			# We save the *Next Scene* as the resume point.
		if auto_save_on_enter and GameState.has_method("save_game"):
			if next_scene_path != "":
				GameState.save_game(next_scene_path)
		
			# --- STEP 3: PREPARE DESTINATION ---
			# Tell GameState which Marker2D to look for in the new scene.
		GameState.target_spawn_tag = target_spawn_tag
			
		# --- STEP 4: CHANGE SCENE ---
		if next_scene_path == "":
			push_error("❌ PORTAL ERROR: No 'next_scene_path' assigned in Inspector!")
			return
				
			# Use call_deferred to safely switch scenes during a physics callback
		call_deferred("_change_scene_safe")

func _change_scene_safe():
	get_tree().change_scene_to_file(next_scene_path)
