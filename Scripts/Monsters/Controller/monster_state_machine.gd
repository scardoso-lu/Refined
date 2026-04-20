extends Node
class_name MonsterStateMachine

# --- 1. DEFINITIONS ---
enum MoveState { IDLE, PATROL, CHASE, KNOCKBACK, DEATH }
enum ActionState { NONE, ATTACK }

var current_move_state: MoveState = MoveState.IDLE
var current_action_state: ActionState = ActionState.NONE

# Dependencies
var monster: MonsterController
var attack_cooldown_timer: float = 0.0
var has_dealt_damage: bool = false

# Patrol
const PATROL_SPEED: float = 40.0  # px/s — much slower than chase
const PATROL_TIME: float = 3.0    # seconds of walking before pausing
const IDLE_TIME: float = 1.5      # seconds standing still before walking again
var _patrol_dir: float = 1.0
var _patrol_timer: float = 0.0
var _patrol_flip_cooldown: float = 0.0

# --- 2. SETUP ---
func init(parent: MonsterController) -> void:
	monster = parent
	monster.view.sprite.animation_finished.connect(_on_animation_finished)

# --- 3. PHYSICS LOOP ---
func physics_update(delta: float) -> void:
	if current_move_state == MoveState.DEATH:
		_move_death(delta)
		return

	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	monster.apply_gravity(delta)

	match current_move_state:
		MoveState.IDLE:      _move_idle(delta)
		MoveState.PATROL:    _move_patrol(delta)
		MoveState.CHASE:     _move_chase(delta)
		MoveState.KNOCKBACK: _move_knockback(delta)

	match current_action_state:
		ActionState.NONE:    _action_none(delta)
		ActionState.ATTACK:  _action_attack(delta)

	_resolve_animation()

# ==============================================================================
# LAYER 1: MOVEMENT LOGIC
# ==============================================================================

func change_move_state(new_state: MoveState) -> void:
	match new_state:
		MoveState.IDLE:   _patrol_timer = IDLE_TIME
		MoveState.PATROL: _patrol_timer = PATROL_TIME
	current_move_state = new_state

func _move_idle(delta: float) -> void:
	monster.stop_moving()
	if monster.has_target():
		change_move_state(MoveState.CHASE)
		return
	_patrol_timer -= delta
	if _patrol_timer <= 0.0:
		change_move_state(MoveState.PATROL)

func _move_patrol(delta: float) -> void:
	if monster.has_target():
		change_move_state(MoveState.CHASE)
		return

	# Reverse direction at ledges or walls (with cooldown to avoid jitter)
	_patrol_flip_cooldown -= delta
	if _patrol_flip_cooldown <= 0.0 and (monster.is_at_ledge() or monster.is_on_wall()):
		_patrol_dir *= -1.0
		_patrol_flip_cooldown = 0.5

	monster.velocity.x = move_toward(monster.velocity.x, _patrol_dir * PATROL_SPEED, 400.0 * delta)
	monster.view.update_flip(_patrol_dir, monster.attack_area)

	_patrol_timer -= delta
	if _patrol_timer <= 0.0:
		change_move_state(MoveState.IDLE)

func _move_chase(_delta: float) -> void:
	if not monster.has_target():
		change_move_state(MoveState.IDLE)
		return

	if monster.is_at_ledge():
		monster.stop_moving()
		return

	if current_action_state == ActionState.ATTACK:
		monster.stop_moving()
		return

	monster.move_towards(monster.get_target_position())

func _move_knockback(delta: float) -> void:
	monster.velocity.x = move_toward(monster.velocity.x, 0, 1000 * delta)
	if abs(monster.velocity.x) < 10:
		change_move_state(MoveState.IDLE)

func _move_death(delta: float) -> void:
	monster.apply_gravity(delta)
	monster.velocity.x = move_toward(monster.velocity.x, 0, 500 * delta)
	monster.move_and_slide()

# ==============================================================================
# LAYER 2: ACTION LOGIC
# ==============================================================================

func change_action_state(new_state: ActionState) -> void:
	current_action_state = new_state
	match new_state:
		ActionState.ATTACK:
			has_dealt_damage = false
			monster.view.play_anim("attack")
		ActionState.NONE:
			pass

func _action_none(_delta: float) -> void:
	if not monster.has_target(): return

	var dist = monster.global_position.distance_to(monster.get_target_position())
	if dist <= monster.monster_data.attack_range:
		if attack_cooldown_timer <= 0:
			change_action_state(ActionState.ATTACK)

func _action_attack(_delta: float) -> void:
	if monster.has_target():
		var dist = monster.global_position.distance_to(monster.get_target_position())
		if dist > monster.monster_data.attack_range + 50:
			change_action_state(ActionState.NONE)
			return

	# Trigger damage at the midpoint of the attack animation so it works
	# regardless of how many frames the animation has.
	var sprite := monster.view.sprite
	var total_frames := 2
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
		total_frames = max(2, sprite.sprite_frames.get_frame_count("attack"))
	var hit_frame := total_frames / 2

	if sprite.frame >= hit_frame and not has_dealt_damage:
		monster.deal_damage()
		has_dealt_damage = true

	if not sprite.is_playing() or sprite.animation != "attack":
		attack_cooldown_timer = monster.monster_data.attack_cooldown
		change_action_state(ActionState.NONE)

# ==============================================================================
# PUBLIC INTERRUPTS
# ==============================================================================

func apply_knockback(force: Vector2):
	if current_move_state == MoveState.DEATH: return
	monster.velocity = force
	change_move_state(MoveState.KNOCKBACK)
	change_action_state(ActionState.NONE)

func trigger_death():
	if current_move_state == MoveState.DEATH: return

	current_move_state = MoveState.DEATH
	current_action_state = ActionState.NONE

	if monster.attack_area:
		monster.attack_area.monitoring = false
		monster.attack_area.monitorable = false

	monster.velocity = Vector2.ZERO
	monster.collision_layer = 0

	# Death Visual Sequence via View
	if monster.view.sprite.sprite_frames.has_animation("death"):
		monster.view.play_anim("death")
	else:
		var tween = monster.create_tween()
		tween.tween_property(monster, "modulate:a", 0.0, 0.5)
		await tween.finished
		_on_death_completed()

func _on_animation_finished():
	if monster.view.sprite.animation == "death":
		_on_death_completed()

func _on_death_completed():
	monster.spawn_loot()
	monster.queue_free()

# ==============================================================================
# VISUAL RESOLVER
# ==============================================================================

func _resolve_animation() -> void:
	if current_move_state == MoveState.DEATH:
		return

	if current_action_state == ActionState.ATTACK:
		return

	match current_move_state:
		MoveState.IDLE:
			monster.view.play_anim("idle")
		MoveState.PATROL, MoveState.CHASE:
			monster.view.play_anim("run")
		MoveState.KNOCKBACK:
			if monster.view.sprite.sprite_frames.has_animation("hurt"):
				monster.view.play_anim("hurt")
			else:
				monster.view.play_anim("idle")
