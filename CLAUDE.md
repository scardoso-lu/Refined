# CLAUDE.md — Refined

## Project Overview

**Refined** is a cross-platform 2D action RPG built with **Godot 4.6** using the GDScript language.

- **Engine:** Godot 4.6 (GL Compatibility renderer)
- **Language:** GDScript
- **Platforms:** Windows Desktop, Android
- **Build outputs:** `builds/Refined.exe`, `builds/Refined.apk` (gitignored)

---

## Repository Structure

```
Refined/
├── Scripts/          # 30 GDScript files — all game logic, organized by domain
├── Scenes/           # 21 .tscn scene files — node trees for gameplay objects and UI
├── Data/             # 30 .tres resource files — game data (characters, monsters, items)
├── Assets/           # Sprites, map images
├── project.godot     # Godot project configuration, autoloads, input bindings, layer names
└── export_presets.cfg # Export profiles (Windows/Android)
```

### Scripts/ domain layout

```
Scripts/
├── Player/           # Player controller, state machine, view, repository
├── Monsters/         # Enemy controller, state machine, view, repository, data
├── Shop/             # Merchant controller, UI, item definitions
├── Global/           # WorldManager, PortalManager, HUD, mobile controls
├── Levels/           # LevelManager, monster spawner
├── Login/            # Character selection, GameState session cache
├── Boss/             # Boss controller
└── Components/       # Reusable UI/FX: HUD widgets, damage numbers, loot items
```

Each domain follows the same three-layer folder structure: `Controller/`, `Repository/`, `View/`.

---

## Architecture: Repository / Controller / View

The codebase uses a consistent **3-tier MVC variant** across every domain.

| Layer | Folder | Responsibility |
|---|---|---|
| **Repository** | `[Domain]/Repository/` | Holds runtime state and performs data calculations. No side effects on the scene tree. |
| **Controller** | `[Domain]/Controller/` | Coordinates between Repository and View. Owns the state machine. Exposes the public API for other systems. |
| **View** | `[Domain]/View/` | Captures input and drives visuals/animations. Emits signals upward to Controller. No business logic. |

### Setup flow example (player)

```gdscript
# player_controller.gd
func setup_character(def: CharacterDef) -> void:
    repository.init(def)      # push data into Model
    view.setup_visuals(def)   # configure visuals
```

---

## Autoload Singletons

Defined in `project.godot`. Available globally without `get_node()`.

| Name | Script | Purpose |
|---|---|---|
| `GameState` | `Scripts/Login/game_state.gd` | Session cache: selected character, current HP/gold/XP/level between scene transitions |
| `MonsterDB` | `Scripts/Monsters/Repository/monster_texture_db.gd` | Enemy texture lookup and tier-based spawn pool |
| `WorldManager` | `Scripts/Global/Managers/world_manager.gd` | Global event bus: difficulty, monster kills, shop open |
| `ShopItemDb` | `Scripts/Shop/Repository/shop_item_db.gd` | Item catalog; maps shop ID → `Array[ItemDef]` |

### WorldManager signals (global event bus)

```gdscript
signal difficulty_updated(new_mult)
signal monster_slain(xp_reward)
signal shop_opened(shop_id: String)
```

---

## Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Script files | `snake_case.gd` | `player_controller.gd` |
| Resource class files | `PascalCase.gd` | `CharacterDef.gd`, `MonsterDef.gd` |
| Class names | `PascalCase` (always declared with `class_name`) | `class_name PlayerController` |
| Functions | `snake_case` | `setup_character()`, `apply_damage()` |
| Private functions | `_snake_case` | `_recalculate_stats()`, `_move_idle()` |
| Variables | `snake_case` | `current_health`, `attack_cooldown_timer` |
| Private variables | `_snake_case` | `_current_input_dir` |
| Constants | `UPPER_CASE` | `CHARACTER_DB`, `TIER_DATA` |
| Signals | `snake_case`, past-tense for completion | `health_changed`, `player_died`, `level_up` |
| Enums | `PascalCase` name, `UPPER_CASE` values | `enum MoveState { IDLE, RUN, AIR, DEATH }` |

---

## State Machine Pattern

Every entity uses a **dual-layer Finite State Machine** — movement state and action state run in parallel. State machine scripts live at `[Domain]/Controller/*_state_machine.gd`.

```gdscript
# player_state_machine.gd
enum MoveState  { IDLE, RUN, AIR, DEATH }
enum ActionState { NONE, ATTACK }

func physics_update(delta: float) -> void:
    match current_move_state:
        MoveState.IDLE: _move_idle(delta)
        MoveState.RUN:  _move_run(delta)
        # ...
    match current_action_state:
        ActionState.NONE:   _action_none(delta)
        ActionState.ATTACK: _action_attack(delta)
```

- Transitions use explicit methods: `change_move_state(MoveState.RUN)`, `change_action_state(ActionState.ATTACK)`
- The Controller calls `state_machine.physics_update(delta)` each frame from `_physics_process`

---

## Signal / Event Patterns

### Declaration and emission

```gdscript
# At top of class
signal health_changed(new_amount)
signal currency_updated(new_gold, xp, level, xp_next_max)

# Emission
health_changed.emit(repository.current_health)
currency_updated.emit(result.gold, result.xp, result.level, result.xp_next)
```

### Connection

```gdscript
player_ref.health_changed.connect(health_widget._on_player_health_changed)
```

### Safe connect utility (avoids duplicate connections)

```gdscript
# hud.gd
func _safe_connect(sig: Signal, method: Callable):
    if sig.is_connected(method):
        sig.disconnect(method)
    sig.connect(method)
```

Use `_safe_connect` when a node may be re-initialized without being freed.

---

## Resource / Data Pattern

Game data lives in `.tres` files under `Data/`. Resource scripts use `class_name` and `@export` for Inspector editing.

```gdscript
# character_def.gd
class_name CharacterDef
extends Resource

@export var character_name: String
@export var base_max_health: int
@export var base_damage: int
```

- **`preload()`** — compile-time loading for known paths (used in databases/repositories)
- **`load()`** — runtime loading from dynamic paths (used in `GameState` for character selection)

### Core data models

| Class | File | Used for |
|---|---|---|
| `CharacterDef` | `Scripts/Player/Repository/character_def.gd` | Playable character stats |
| `MonsterDef` | `Scripts/Monsters/Repository/monster_def.gd` | Enemy stats and behavior data |
| `ItemDef` | `Scripts/Shop/Repository/ItemDef.gd` | Shop item definition |

### Data files

| Directory | Contents |
|---|---|
| `Data/Player/` | 5 characters: samurai, void, ninja, lifebinder, warrior |
| `Data/Monster/` | 18 monsters across elemental and sin-themed tiers |
| `Data/Items/` | 4 shop items: Potion, Potion_Max, Bomb_Mega, Upgrade_Sword |
| `Data/Global/` | gold coin loot type, portal, shop definitions |

---

## Physics Layers

Defined in `project.godot` (layer names). Use these when setting collision masks.

| Layer | Name |
|---|---|
| 1 | Walls |
| 2 | Player |
| 3 | Enemy |
| 4 | Coin |
| 5 | Shops |

---

## Node Groups

Groups enable dynamic lookup without hard-coded node paths.

| Group | Used by |
|---|---|
| `"Player"` | Portal detection, HUD wiring (`portal_manager.gd`, `hud.gd`) |
| `"Portal"` | Level transition detection |

```gdscript
add_to_group("Player")             # player_controller.gd
if body.is_in_group("Player"):     # portal_manager.gd
```

---

## Input Actions

Defined in `project.godot`. Support keyboard and gamepad.

| Action | Keyboard | Gamepad |
|---|---|---|
| `move_left` | A | Left analog |
| `move_right` | D | Left analog |
| `jump` | Space | A button |
| `base_attack` | — | X button |
| `interact` | E | — |

---

## Level Progression & Monster Spawning

`MonsterDB` (`monster_texture_db.gd`) manages tier-based spawning:

- **Tier_1:** Low-level monsters (levels 1–n)
- **Tier_2:** Mid-level monsters
- **Tier_3:** High-level monsters

Spawn count scales with spawn point ID ("01" = minimum enemies).

### Portal / scene transitions

`PortalManager` (`Scripts/Global/Managers/portal_manager.gd`):
1. Saves current player state to `GameState` before transition
2. Calls `get_tree().change_scene_to_file(next_scene_path)`
3. Target scene restores state from `GameState` on `_ready()`

---

## Common Patterns

### @onready for node references

```gdscript
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var view: PlayerView = $PlayerView
@onready var repository: PlayerRepository = $PlayerRepository
```

### Tween for UI/VFX animations

```gdscript
var tween = create_tween()
tween.set_parallel(true)
tween.tween_property(self, "position:y", position.y - 30, 0.5)
tween.tween_property(self, "modulate:a", 0.0, 0.5)
```

### Stat scaling formula

Player stats use logarithmic progression in `player_repository.gd`:

```gdscript
func _recalculate_stats() -> void:
    max_health = base_max_health + int(log(current_level + 1) * scaling_factor)
    # similar pattern for damage, defense
```

### Controller accessor pattern

Controllers expose a simplified public API that delegates to Repository:

```gdscript
func get_damage() -> int: return repository.get_outgoing_damage()
func get_level() -> int:  return repository.current_level
```

---

## Development Workflow

### Running the game

Open `project.godot` in Godot 4.6 and press F5 (or the Play button). No external build tools required.

### Exporting

Use **Project → Export** in the Godot editor. Presets for Windows Desktop and Android are configured in `export_presets.cfg`. Outputs go to `builds/` (gitignored).

### Testing

A lightweight built-in test framework lives in `tests/`. No external dependencies are required.

**Running tests:**
1. Open `project.godot` in Godot 4.6.
2. Run the scene `tests/test_runner.tscn` (Scene → Run Specific Scene, or F6 after opening the file).
3. Results print to the Godot Output panel.

**Headless / CI:**
```
godot --headless --path /path/to/Refined tests/test_runner.tscn
```
The process exits with code `0` (all pass) or `1` (any failure).

**Test structure:**
```
tests/
├── test_base.gd          # class_name RefinedTest — assertion helpers
├── test_runner.gd        # Discovers and runs all suites; prints summary
├── test_runner.tscn      # Minimal Node scene that drives test_runner.gd
└── unit/
    ├── test_player_repository.gd    # PlayerRepository logic (~35 assertions)
    ├── test_monster_repository.gd   # MonsterRepository scaling (~15 assertions)
    ├── test_monster_texture_db.gd   # Wave generation / tier logic (~13 assertions)
    └── test_game_state.gd           # GameState session cache (~13 assertions)
```

**Adding a new test suite:**
1. Create `tests/unit/test_<feature>.gd` that `extends RefinedTest` with `class_name Test<Feature>`.
2. Add methods named `test_*` — each calls `assert_*` helpers from `RefinedTest`.
3. Add the path to the `SUITES` array in `tests/test_runner.gd`.

**Available assertions** (in `tests/test_base.gd`):
`assert_eq`, `assert_ne`, `assert_true`, `assert_false`, `assert_gt`, `assert_ge`, `assert_lt`, `assert_le`, `assert_between`

**What is tested:**
| Suite | Covers |
|---|---|
| `test_player_repository` | `init`, `apply_damage`, `compute_velocity_x`, `add_loot`, level-up, `get_outgoing_damage`, `try_purchase_item`, stat scaling |
| `test_monster_repository` | `init`/scaling by difficulty, `apply_damage`, `is_dead`, `get_speed` |
| `test_monster_texture_db` | Tier selection by level, safe vs. danger spawn counts, output format |
| `test_game_state` | Session cache defaults, `update_session_cache`, `reset_session_health`, CHARACTER_DB, `get_selected_character_data` |

**What is not tested** (scene-tree dependent):
- `PlayerController`, `MonsterController`, `PlayerStateMachine` — require a running scene for `CharacterBody2D` physics.
- `HUD`, `HealthWidget`, `ShopWidget` — UI nodes.
- `WorldManager.process_reward` — uses `get_tree().get_first_node_in_group()`.

### Gitignored paths

```
.godot/          # Godot cache — never commit
android/         # Android SDK files
builds/          # Export outputs
sounds/          # Audio assets (large files)
```

---

## Key Files Reference

| File | Purpose |
|---|---|
| `project.godot` | Engine config, autoloads, input bindings, physics layer names |
| `export_presets.cfg` | Windows/Android export profiles |
| `Scripts/Login/game_state.gd` | Global session cache (character, HP, gold, XP, level) |
| `Scripts/Global/Managers/world_manager.gd` | Global event bus |
| `Scripts/Global/Managers/portal_manager.gd` | Scene transition with state persistence |
| `Scripts/Global/View/HUD.gd` | Main HUD — wires player signals to widgets |
| `Scripts/Player/Controller/player_controller.gd` | Player entry point, public API |
| `Scripts/Player/Controller/player_state_machine.gd` | Player FSM (movement + action layers) |
| `Scripts/Player/Repository/player_repository.gd` | Player stats, scaling math |
| `Scripts/Player/View/player_view.gd` | Player input capture, animation |
| `Scripts/Monsters/Controller/enemy_controller.gd` | Enemy logic (mirrors player pattern) |
| `Scripts/Monsters/Repository/monster_texture_db.gd` | Tier-based spawn pool (autoload: MonsterDB) |
| `Scripts/Shop/Repository/shop_item_db.gd` | Item catalog (autoload: ShopItemDb) |
| `Scripts/Levels/monster_spawner.gd` | Spawns enemies based on level tier |
| `Data/Player/` | CharacterDef .tres files for all 5 playable characters |
| `Data/Monster/` | MonsterDef .tres files for all 18 enemies |
