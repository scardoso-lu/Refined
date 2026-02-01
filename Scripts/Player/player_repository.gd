extends Node
class_name PlayerRepository

# --- DATA STATE (The "Truth") ---
# This mirrors what your Go server will store later.
var stats: CharacterDef

#### ZONE
var current_scene: String = "level_01.tscn"

# Runtime Stats
var max_health: int = 100
var current_health: int = 100
var damage: int = 20
var acceleration: float = 1200.0
var friction: float = 1600.0

# Progression
var gold: int = 0
var experience: int = 0
var xp_next_level: int = 100
var current_level: int = 1

# Scaling Config
var damage_scale_A := 0.002
var hp_scale_B := 0.004
var xp_scale_X := 120

# --- INITIALIZATION ---
func init(def: CharacterDef):
	stats = def
	# Initial calculation based on definition
	if def:
		current_level = def.player_level
		experience = def.experience
		xp_next_level = def.xp_next_level
	
	_recalculate_stats()
	current_health = max_health

# --- LOGIC ACTIONS ---

# Pure Math: Calculates velocity. Returns the new X velocity.
func compute_velocity_x(current_vel_x: float, direction: float, delta: float, speed_limit: float) -> float:
	if direction:
		return move_toward(current_vel_x, direction * speed_limit, acceleration * delta)
	else:
		return move_toward(current_vel_x, 0, friction * delta)

func apply_damage(amount: int) -> int:
	current_health -= amount
	# Logic check: Health can't be negative (unless you want overkill mechanics)
	return current_health

func add_loot(type_id: int, amount: int) -> Dictionary:
	# Returns a "Packet" of changes
	var leveled_up = false
	var final_level = current_level
	
	match type_id:
		0: # COIN
			gold += amount
		1: # GEM
			experience += amount
			leveled_up = _check_level_up()
			final_level = current_level
			
	return {
		"gold": gold,
		"xp": experience,
		"xp_next": xp_next_level,
		"level": final_level,
		"leveled_up": leveled_up
	}

func get_outgoing_damage() -> int:
	var scaled = _scaled_n_log_n(damage)
	return int(damage * (1.0 + damage_scale_A * scaled))

func get_base_move_speed() -> float:
	return stats.base_move_speed if stats else 300.0

func get_jump_force() -> float:
	return stats.jump_velocity if stats else -400.0

# --- INTERNAL MATH (Private) ---

func _check_level_up() -> bool:
	var did_level = false
	while experience >= xp_next_level:
		experience -= xp_next_level
		current_level += 1
		did_level = true
		_recalculate_stats()
		xp_next_level = int(xp_scale_X * _scaled_n_log_n(float(current_level)))
		current_health = max_health # Heal on level up
	return did_level

func _recalculate_stats():
	var level = max(1, current_level)
	var log_term = log(level + 1)
	var growth = level * log_term
	
	# Load base stats or defaults
	var base_hp = stats.base_max_health if stats else 100
	var base_dmg = stats.base_damage if stats else 20
	
	max_health = int(max(10, base_hp * pow(growth, 0.95)))
	current_health = min(current_health, max_health)
	
	damage = int(max(1, base_dmg * pow(growth, 0.85)))
	
	# Scaling acceleration slightly
	acceleration = 1200.0 * (1.0 + log_term * 0.05)

func _scaled_n_log_n(n: float) -> float:
	return n * log(n + 1.0)
