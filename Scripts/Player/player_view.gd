extends Node
class_name PlayerView

# --- SIGNALS (Sent to Controller) ---
signal direction_changed(dir: float)
signal jump_pressed
signal jump_released
signal attack_requested

# --- REFERENCES ---
# Assumes structure: PlayerController -> [PlayerView, AnimatedSprite2D, WeaponArea]
@onready var sprite: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var weapon_area = $"../WeaponArea"

func setup_visuals(def: CharacterDef):
	if def and def.sprite_frames:
		sprite.sprite_frames = def.sprite_frames
		sprite.play("idle")

# --- INPUT HANDLING ---
func _physics_process(_delta):
	# 1. Capture Input
	var dir = Input.get_axis("move_left", "move_right")
	
	# 2. Update Local Visuals (Client Prediction)
	if dir:
		sprite.flip_h = dir < 0
		weapon_area.scale.x = -1 if dir < 0 else 1
		
	# 3. Inform Controller
	direction_changed.emit(dir)

func _input(event):
	if event.is_action_pressed("jump"):
		jump_pressed.emit()
	if event.is_action_released("jump"):
		jump_released.emit()
	if event.is_action_pressed("base_attack"):
		attack_requested.emit()

# --- VISUAL REACTIONS (Called by Controller) ---
func play_anim(anim_name: String):
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func play_damage_effect():
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func play_level_up_effect():
	sprite.modulate = Color.GREEN
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)

func get_current_animation() -> String:
	return sprite.animation
