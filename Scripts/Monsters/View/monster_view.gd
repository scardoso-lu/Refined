extends Node
class_name MonsterView

@onready var sprite: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var health_bar = $"../HealthBar"
@export var floating_text_scene: PackedScene = preload("res://Scenes/Components/Effects/DamageNumbers.tscn")

func setup_visuals(def: MonsterDef):
	if def.sprite_frames:
		sprite.sprite_frames = def.sprite_frames
		sprite.play("idle")
	sprite.scale = Vector2(def.scale, def.scale)
	health_bar.visible = false

func update_health_bar(current: float, max_hp: float):
	health_bar.max_value = max_hp
	health_bar.value = current
	health_bar.visible = true

func play_damage_fx(amount: int):
	# Flash
	sprite.modulate = Color.RED
	var t = create_tween()
	t.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	# Numbers
	if floating_text_scene:
		var txt = floating_text_scene.instantiate()
		txt.set_values(amount, Color.YELLOW)
		txt.global_position = get_parent().global_position + Vector2(randf_range(-20, 20), -50)
		get_tree().current_scene.add_child(txt)

func update_flip(dir: float, attack_area: Area2D):
	if dir == 0: return
	sprite.flip_h = dir < 0
	attack_area.scale.x = -1 if dir < 0 else 1

func play_anim(anim: String):
	if sprite.animation != anim:
		sprite.play(anim)
