extends Control

func _ready():
	# Start hidden
	hide()

func show_game_over():
	show()

func _on_try_again_pressed():
	print("_on_try_again_pressed")

	# Option A: Reload the exact same level (Quick Restart)
	# get_tree().reload_current_scene()
	
	# Option B: Reload from Disk (The RPG Way)
	var saved_scene = GameState.load_game()
	if saved_scene:
		get_tree().change_scene_to_file(saved_scene)
	else:
		# Fallback if no save exists
		get_tree().change_scene_to_file("res://Scenes/Levels/level_01.tscn")

func _on_back_to_vilage_pressed():
	print("_on_back_to_vilage_pressed")
	# Change this path to your actual Main Menu scene
	get_tree().change_scene_to_file("res://Scenes/Login/CharacterSelect.tscn")
