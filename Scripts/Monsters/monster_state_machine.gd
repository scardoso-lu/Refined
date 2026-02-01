extends Node
class_name MonsterStateMachine

# --- 1. DEFINITIONS ---
enum MoveState {
	IDLE,
	CHASE,
	KNOCKBACK,
	DEATH # <--- Added Death State
}

enum ActionState {
	NONE,
	ATTACK
}

# State Variables
var current_move_state: MoveState = MoveState.IDLE
var current_action_state: ActionState = ActionState.NONE

# Dependencies
var monster: MonsterController
var attack_cooldown_timer: float = 0.0
var has_dealt_damage: bool = false

# --- 2. SETUP ---
func init(parent: MonsterController) -> void:
	monster = parent

# --- 3. PHYSICS LOOP ---
func physics_update(delta: float) -> void:
	# CRITICAL: If dead, run death logic only and skip the rest
	if current_move_state == MoveState.DEATH:
		_move_death(delta)
		return

	# Global Cooldown Management
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
		
	# Apply Gravity (Legs need gravity to work)
	monster.apply_gravity(delta)

	# UPDATE LAYER 1: MOVEMENT (Legs)
	match current_move_state:
		MoveState.IDLE:      _move_idle(delta)
		MoveState.CHASE:     _move_chase(delta)
		MoveState.KNOCKBACK: _move_knockback(delta)
		# Death is handled at top of function

	# UPDATE LAYER 2: ACTION (Arms)
	match current_action_state:
		ActionState.NONE:    _action_none(delta)
		ActionState.ATTACK:  _action_attack(delta)
		
	# RESOLVE ANIMATIONS
	_resolve_animation()

# ==============================================================================
# LAYER 1: MOVEMENT LOGIC
# ==============================================================================

func change_move_state(new_state: MoveState) -> void:
	current_move_state = new_state
	# No enter/exit logic needed here; Visual Resolver handles the sprite

func _move_idle(delta: float) -> void:
	monster.stop_moving()
	
	# Transition: Player Detected
	if monster.player_ref:
		change_move_state(MoveState.CHASE)

func _move_chase(delta: float) -> void:
	# 1. Safety Check: Lost Player?
	if not monster.player_ref:
		change_move_state(MoveState.IDLE)
		return

	# 2. Ledge Check (Don't fall off cliffs)
	if monster.is_at_ledge():
		monster.stop_moving()
		return 

	# 3. Calculate Speed Modifier
	var speed_modifier = 1.0
	
	# Interaction: If Attacking, stop moving (Classic RPG style)
	if current_action_state == ActionState.ATTACK:
		speed_modifier = 0.0 
	
	# 4. Move
	if speed_modifier > 0:
		monster.move_towards(monster.player_ref.global_position)
		monster.velocity.x *= speed_modifier
	else:
		monster.stop_moving()

func _move_knockback(delta: float) -> void:
	# Apply Friction to slide to a halt
	monster.velocity.x = move_toward(monster.velocity.x, 0, 1000 * delta)
	
	# Transition: Stopped sliding?
	if abs(monster.velocity.x) < 10:
		change_move_state(MoveState.IDLE)

func _move_death(delta: float) -> void:
	# While dying, we still want gravity, but we force friction 
	# so the corpse doesn't slide endlessly if hit while moving.
	monster.apply_gravity(delta)
	monster.velocity.x = move_toward(monster.velocity.x, 0, 500 * delta)
	monster.move_and_slide() # Manual move needed since we return early in physics_update

# ==============================================================================
# LAYER 2: ACTION LOGIC
# ==============================================================================

func change_action_state(new_state: ActionState) -> void:
	current_action_state = new_state
	
	match new_state:
		ActionState.ATTACK:
			has_dealt_damage = false
			monster.sprite.play("attack") # Force immediate visual feedback
		ActionState.NONE:
			pass

func _action_none(_delta: float) -> void:
	# Wait until we have a target
	if not monster.player_ref: return
	
	# Distance Check
	var dist = monster.global_position.distance_to(monster.player_ref.global_position)
	
	if dist <= monster.monster_data.attack_range:
		if attack_cooldown_timer <= 0:
			change_action_state(ActionState.ATTACK)

func _action_attack(_delta: float) -> void:
	
	# 1. Target Validation (Optional: Stop attacking if player teleports away)
	if monster.player_ref:
		var dist = monster.global_position.distance_to(monster.player_ref.global_position)
		if dist > monster.monster_data.attack_range + 50:
			change_action_state(ActionState.NONE)
			return

	# 2. Damage Logic (Sync with animation frame)
	# Assuming the "hit" happens on frame 4 or 5
	if monster.sprite.frame >= 4 and not has_dealt_damage:
		monster.deal_damage()
		has_dealt_damage = true

	# 3. End Logic
	if not monster.sprite.is_playing() or monster.sprite.animation != "attack":
		attack_cooldown_timer = 1.0 # Reset cooldown
		change_action_state(ActionState.NONE)

# ==============================================================================
# PUBLIC INTERRUPTS (Triggers)
# ==============================================================================

func apply_knockback(force: Vector2):
	# Dead monsters don't feel pain
	if current_move_state == MoveState.DEATH: return
	
	monster.velocity = force
	change_move_state(MoveState.KNOCKBACK)
	# Interrupt any attack
	change_action_state(ActionState.NONE)

func trigger_death():
	# Idempotency check: Don't die twice
	if current_move_state == MoveState.DEATH: return
	
	print("☠️ Monster triggering death...")
	
	# 1. State Switch (Stops AI brain)
	current_move_state = MoveState.DEATH
	current_action_state = ActionState.NONE
	
	# 2. DISABLE COMBAT IMMEDIATELY
	# We want the body to exist (visuals), but we don't want it to hurt anyone.
	# Disable the Attack Area monitoring so it can't deal damage.
	if monster.attack_area:
		monster.attack_area.monitoring = false
		monster.attack_area.monitorable = false
	
	# 2. Physics & Collision
	monster.velocity = Vector2.ZERO
	# Optional: Disable collision layer so player walks through corpse
	monster.collision_layer = 0 
	
	# 3. Play Animation Sequence
	if monster.sprite.sprite_frames.has_animation("death"):
		monster.sprite.play("death")
		# Wait for the animation to finish
		await monster.sprite.animation_finished
	else:
		# Fallback: Fade out if no animation
		var tween = monster.create_tween()
		tween.tween_property(monster, "modulate:a", 0.0, 0.5)
		await tween.finished
	
	# 4. Spawn Loot (Delegated to Controller)
	# Now that the body has hit the floor, we drop the item.
	monster.spawn_loot()
	
	# 5. Cleanup
	monster.queue_free()
# ==============================================================================
# VISUAL RESOLVER
# ==============================================================================

func _resolve_animation() -> void:
	# PRIORITY 0: Death overrides everything
	if current_move_state == MoveState.DEATH:
		return # Do not touch the sprite, let trigger_death handle it

	# PRIORITY 1: Action State (Attacking overrides running)
	if current_action_state == ActionState.ATTACK:
		if monster.sprite.animation != "attack":
			monster.sprite.play("attack")
		return

	# PRIORITY 2: Movement State
	match current_move_state:
		MoveState.IDLE:
			monster.sprite.play("idle")
		MoveState.CHASE:
			monster.sprite.play("run")
		MoveState.KNOCKBACK:
			if monster.sprite.sprite_frames.has_animation("hurt"):
				monster.sprite.play("hurt")
			else:
				monster.sprite.play("idle")
