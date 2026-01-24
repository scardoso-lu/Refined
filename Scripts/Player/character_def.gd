# character_data.gd
class_name CharacterDef
extends Resource

@export_group("Visuals")
@export var sprite_frames: SpriteFrames
# Add this new line!
@export var portrait: Texture2D

@export_group("Stats")
@export var move_speed : float = 400
@export var current_health: int = 100

@export_group("Movement")
@export var speed: float = 300.0
@export var jump_velocity: float = -400.0

@export_group("Hitbox")
# This is the variable the error says is missing!
@export var collider_size: Vector2 = Vector2(10, 24)


@export_group("Abilities")
# You can even link other resources here for modular skills
@export var primary_projectile: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
