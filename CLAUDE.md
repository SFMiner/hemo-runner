# Hemo-Runner

An educational Godot 4.5 game about blood flow and gas exchange in the circulatory system. The player controls a red blood cell (RBC) navigating through the bloodstream, delivering oxygen to tissues and picking up carbon dioxide.

## Project Structure

```
hemo-runner/
├── autoloads/           # Singleton scripts (global access)
│   ├── game_constants.gd   # All game constants, enums, utility functions
│   └── game_manager.gd     # Game state, scoring, win/lose conditions
├── scripts/             # Scene-attached scripts
│   ├── main.gd            # Main scene controller, world scrolling
│   ├── player.gd          # RBC player character (CharacterBody2D)
│   ├── cargo_manager.gd   # Manages 4 hemoglobin cargo slots
│   ├── zone_manager.gd    # Circulatory loop zones (tissue/heart/lung)
│   ├── spawner.gd         # Spawns tissue cells and platelets
│   ├── tissue_cell.gd     # Cells that need O2 delivery
│   ├── platelet.gd        # Obstacles that can trap the player
│   └── ui_manager.gd      # HUD and UI elements
├── scenes/              # .tscn scene files
│   ├── main.tscn          # Main game scene
│   ├── player.tscn        # Player scene with CargoManager child
│   ├── tissue_cell.tscn   # Tissue cell prefab
│   └── platelet.tscn      # Platelet obstacle prefab
└── assets/graphics/     # SVG sprites
```

## Core Game Mechanics

### Movement System ("Submarine" Style)
- The world scrolls right at `FLOW_SPEED` (200 px/s) simulating blood flow
- Player moves relative to screen at `PLAYER_SPEED` (400 px/s)
- If player stops moving, they drift left relative to screen
- Falling off the left edge = game over

### Cargo System
- Player has 4 cargo slots representing hemoglobin molecules
- Slots can contain: `EMPTY`, `O2`, `CO2`, or `CO` (future feature)
- In tissue zone: deliver O2 to cells, pick up CO2
- In lung zone: all CO2 exchanged for O2 automatically

### Zone Cycle
1. **Tissue Zone** (55s) - Main gameplay, deliver O2 to tissue cells
2. **Heart to Lungs** (3s) - Cutscene, background spins
3. **Lung Zone** (5s) - Cargo refills with O2
4. **Heart to Body** (3s) - Cutscene, return to tissues

### Win/Lose Conditions
- **Win**: Deliver 10 O2 (configurable via `DELIVERIES_FOR_MISSION_COMPLETE`)
- **Lose**: Fall off left edge of screen (from being stuck on platelet or not moving)

## Key Autoloads

Access these singletons from any script:
- `GameConstants` - All constants, enums, colors, utility functions
- `GameManager` - Game state, scoring, signals for score/game over/mission complete

## Important Constants (in game_constants.gd)

```gdscript
FLOW_SPEED = 200.0          # Base scroll speed
PLAYER_SPEED = 400.0        # Player movement speed
CARGO_SLOTS = 4             # Hemoglobin slots
TISSUE_ZONE_DURATION = 55.0 # Seconds in main gameplay
DELIVERIES_FOR_MISSION_COMPLETE = 10
```

## Common Patterns

### Accessing Player Cargo
```gdscript
var cargo: Node = player.get_cargo_manager()
if cargo.has_o2():
    cargo.exchange_with_tissue()
```

### Zone Transitions
Connect to `ZoneManager` signals:
- `zone_changed(new_zone: int)`
- `heart_zone_entered(going_to_lungs: bool)`
- `lung_zone_entered()`

### Game State Checks
```gdscript
if GameManager.is_playing():
    # Game logic here
```

## Controls
- **WASD** - Move the RBC
- **Mouse** - Alternative control (toggle via `GameManager.toggle_control_scheme()`)

## Development Notes

- Godot version: 4.5
- Renderer: GL Compatibility (for broader hardware support)
- Resolution: 1280x720 with canvas_items stretch mode
- All scripts use static typing for GDScript
- Educational comments explain biological concepts in code
