extends Node
class_name MonsterStateMachine

# --- 1. DEFINITIONS ---
enum MoveState {
	IDLE,
	CHASE,
	KNOCKBACK
}

enum ActionState {
	NONE,
	ATTACK
}

var current_move_state: MoveState = MoveState.IDLE
var current_action_state: ActionState = ActionState.NONE

var monster: MonsterController
var attack_cooldown_timer: float = 0.0
var has_dealt_damage: bool = false

# --- 2. SETUP ---
func init(parent: MonsterController) -> void:
	monster = parent

# --- 3. PHYSICS LOOP ---
func physics_update(delta: float) -> void:
	# Global Cooldown
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
		
	monster.apply_gravity(delta)

	# UPDATE LAYER 1: MOVEMENT (Legs)
	match current_move_state:
		MoveState.IDLE:      _move_idle(delta)
		MoveState.CHASE:     _move_chase(delta)
		MoveState.KNOCKBACK: _move_knockback(delta)

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
	# No enter/exit logic strictly needed here since Animation Resolver handles visuals

func _move_idle(delta: float) -> void:
	monster.stop_moving()
	
	# Transitions
	if monster.player_ref:
		change_move_state(MoveState.CHASE)

func _move_chase(delta: float) -> void:
	# 1. Safety Check: Lost Player?
	if not monster.player_ref:
		change_move_state(MoveState.IDLE)
		return

	# 2. Ledge Check
	if monster.is_at_ledge():
		monster.velocity.x = 0
		return # Wait at the edge (or you could switch to IDLE)

	# 3. Calculate Speed
	# Default: Run full speed
	var speed_modifier = 1.0
	
	# INTERACTION: If Attacking, should we stop?
	if current_action_state == ActionState.ATTACK:
		# Option A: Stop completely (Classic RPG style)
		speed_modifier = 0.0 
		# Option B: Slow down (Zombie style)
		# speed_modifier = 0.5
	
	# 4. Move
	if speed_modifier > 0:
		monster.move_towards_target(monster.player_ref.global_position)
		monster.velocity.x *= speed_modifier
	else:
		monster.stop_moving()

func _move_knockback(delta: float) -> void:
	# Apply Friction
	monster.velocity = monster.velocity.move_toward(Vector2.ZERO, 1000 * delta)
	
	# Transition: Stopped sliding?
	if monster.velocity.length() < 10:
		change_move_state(MoveState.IDLE)

# ==============================================================================
# LAYER 2: ACTION LOGIC
# ==============================================================================

func change_action_state(new_state: ActionState) -> void:
	current_action_state = new_state
	
	match new_state:
		ActionState.ATTACK:
			has_dealt_damage = false
			monster.sprite.play("attack") # Force play immediately
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
	# 1. Interrupt Logic (Optional)
	# If knockback happened, the Public Interrupt function below handles the reset.
	# But if player runs too far away mid-swing?
	if monster.player_ref:
		var dist = monster.global_position.distance_to(monster.player_ref.global_position)
		if dist > monster.monster_data.attack_range + 50:
			# Player escaped! Cancel attack.
			change_action_state(ActionState.NONE)
			return

	# 2. Damage Logic
	# Adjust '5' to the correct frame index
	if monster.sprite.frame >= 5 and not has_dealt_damage:
		monster.deal_damage_to_player()
		has_dealt_damage = true

	# 3. End Logic
	if not monster.sprite.is_playing() or monster.sprite.animation != "attack":
		attack_cooldown_timer = 1.0 # Reset cooldown
		change_action_state(ActionState.NONE)

# ==============================================================================
# INTERRUPTS (Knockback)
# ==============================================================================

func apply_knockback(force: Vector2):
	# 1. Physics Interrupt
	monster.velocity = force
	change_move_state(MoveState.KNOCKBACK)
	
	# 2. Action Interrupt (Stun the monster)
	change_action_state(ActionState.NONE)

# ==============================================================================
# VISUAL RESOLVER
# ==============================================================================

func _resolve_animation() -> void:
	# Priority 1: Action State (Attacking usually overrides running)
	if current_action_state == ActionState.ATTACK:
		if monster.sprite.animation != "attack":
			monster.sprite.play("attack")
		return

	# Priority 2: Movement State
	match current_move_state:
		MoveState.IDLE:
			monster.sprite.play("idle")
		MoveState.CHASE:
			monster.sprite.play("run")
		MoveState.KNOCKBACK:
			# If you have a "hurt" animation, play it here.
			# Otherwise, IDLE or the last frame is fine.
			if monster.sprite.sprite_frames.has_animation("hurt"):
				monster.sprite.play("hurt")
			else:
				monster.sprite.play("idle")
