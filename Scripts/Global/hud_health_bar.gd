extends CanvasLayer

@onready var health_bar = $Control/MarginContainer/HBoxContainer/HealthBar
@onready var avatar = $Control/MarginContainer/HBoxContainer/AvatarFrame

# We call this when the level starts
func setup_hud(player_ref: CharacterBody2D, char_data: CharacterDef):
	# 1. Setup Avatar
	if char_data.avatar_texture:
		avatar.texture = char_data.avatar_texture
	
	# 2. Setup Health Bar
	health_bar.max_value = player_ref.max_health # Ensure player has this var!
	health_bar.value = player_ref.current_health
	
	# 3. Connect Signals (Crucial!)
	# We need the player to tell us when they get hurt.
	# We will add this signal to the player in a moment.
	if not player_ref.health_changed.is_connected(_on_health_changed):
		player_ref.health_changed.connect(_on_health_changed)

func _on_health_changed(new_health):
	# Animate the bar for smoothness (Optional)
	var tween = create_tween()
	tween.tween_property(health_bar, "value", new_health, 0.2)
