extends Control

func _ready():
	# Start hidden
	hide()

func show_game_over():
	show()

func _on_try_again_pressed():
	print("_on_try_again_pressed")
	# 1. Clear the "Dead" HP from the local cache
	GameState.reset_session_health()	
	# 2. Reload the current level
	get_tree().reload_current_scene()
	

func _on_back_to_vilage_pressed():
	# Usually, going back to the village heals the player
	GameState.reset_session_health()
	# Change this path to your actual Main Menu scene
	get_tree().change_scene_to_file("res://Scenes/Login/CharacterSelect.tscn")
