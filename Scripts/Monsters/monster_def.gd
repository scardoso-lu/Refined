class_name MonsterDef
extends Resource

@export_group("Visuals")
@export var sprite_frames: SpriteFrames # Drag your animations here
@export var scale: float = 1.0

@export_group("Stats")
@export var max_health: int = 100
@export var damage: int = 10
@export var speed: float = 80.0

@export_group("AI Behavior")
@export var aggro_range: float = 200.0 # How far it sees you
@export var attack_range: float = 100.0 # How close to hit you
