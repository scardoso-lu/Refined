extends Area2D

# 0 = Coin, 1 = Gem
@export_enum("Coin", "Gem") var type: int = 0
@export var value: int = 10

# Magnet Settings
var target_player: Node2D = null
var speed: float = 0.0
var acceleration: float = 1400.0
var max_speed: float = 600.0

func _ready():
	# 1. Connect signal safely
	body_entered.connect(_on_body_entered)
	
	# 2. visual "Pop" when spawned
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _physics_process(delta):
	# PHASE 1: Detection
	if not target_player:
		var bodies = get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("Player"):
				target_player = body # Locked on!
	
	# PHASE 2: Magnet Movement
	else:
		var direction = global_position.direction_to(target_player.global_position)
		speed = move_toward(speed, max_speed, acceleration * delta)
		global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("Player"):
		# Check if player has the collection function
		if body.has_method("collect_loot"):
			body.collect_loot(type, value)
			queue_free()
