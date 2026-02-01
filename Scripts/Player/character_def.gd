# character_data.gd
extends Resource
class_name CharacterDef

# =============================================================================
# VISUALS
# =============================================================================
@export_group("Visuals")
@export var sprite_frames: SpriteFrames
@export var portrait: Texture2D
@export var avatar_texture: Texture2D

# =============================================================================
# PROGRESSION
# =============================================================================
@export_group("Progression")
@export var player_level: int = 1
@export var experience: int = 0
@export var xp_next_level: int = 100

# =============================================================================
# BASE STATS (Never modified at runtime)
# =============================================================================
@export_group("Base Stats")
@export var base_max_health: int = 100
@export var base_damage: int = 20
@export var base_move_speed: float = 300.0
@export var vitality: int = 10
# =============================================================================
# MOVEMENT
# =============================================================================
@export_group("Movement")
@export var jump_velocity: float = -400.0

# =============================================================================
# COLLISION
# =============================================================================
@export_group("Hitbox")
@export var collider_size: Vector2 = Vector2(10, 24)

# =============================================================================
# ABILITIES
# =============================================================================
@export_group("Abilities")
@export var primary_projectile: PackedScene
