extends Control
class_name HealthWidget

@onready var health_bar = $MarginContainer/HBoxContainer/HealthBar
@onready var avatar = $MarginContainer/HBoxContainer/AvatarFrame

func init_widget(char_data: CharacterDef, current_health: int):
	if char_data:
		health_bar.max_value = char_data.base_max_health
		if char_data.avatar_texture:
			avatar.texture = char_data.avatar_texture
	else:
		health_bar.max_value = 100
		
	health_bar.value = current_health

# This specific signature matches the player's 'health_changed' signal
func _on_player_health_changed(new_health: int):
	var tween = create_tween()
	tween.tween_property(health_bar, "value", new_health, 0.2)
