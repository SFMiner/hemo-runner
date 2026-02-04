# Hemo-Runner

An educational 2D side-scrolling game about blood flow and gas exchange in the circulatory system.

## Overview

You play as a Red Blood Cell (RBC) navigating through the bloodstream. Your mission is to deliver oxygen (O₂) to tissue cells that need it and return carbon dioxide (CO₂) to the lungs for exchange.

## Educational Goals

- Understand the path blood takes through the circulatory system
- Learn how red blood cells transport oxygen and carbon dioxide
- Visualize the continuous flow of blood through the body
- Recognize the role of the heart in pumping blood to lungs and body

## Controls

- **WASD Keys** or **Mouse Movement** - Control the RBC
- Toggle control scheme in Settings menu

## Gameplay

### The Delivery Loop
1. Start with O₂ loaded in your 4 cargo slots
2. Navigate to blue tissue cells that need oxygen
3. Passing over them exchanges O₂ → CO₂
4. Return to the lung zone to exchange CO₂ → O₂
5. Repeat!

### Zones
- **Tissue Zone** (~55 seconds) - Main gameplay area with tissue cells
- **Heart Zones** - Transition cutscenes showing passage through the heart
- **Lung Zone** (~5 seconds) - Reload your O₂ supply

### Hazards
- **Platelets** - Sticky blood clot clusters
- Collision = Game Over (no recovery)
- Rare occurrence (~50% chance per full body loop)

### Win Condition
- Deliver O₂ to 10 tissue cells that need exchange
- Choose to end game or continue in endless mode

## Project Structure

```
hemo-runner/
├── project.godot          # Godot project configuration
├── icon.svg               # Project icon
├── assets/
│   ├── graphics/          # Sprite images (SVG placeholders included)
│   │   ├── rbc_player.svg
│   │   ├── tissue_cell.svg
│   │   └── platelet.svg
│   └── sounds/            # Audio files (add your own)
├── autoloads/
│   ├── game_constants.gd  # Global constants and utilities
│   └── game_manager.gd    # Game state management
├── scenes/
│   ├── main.tscn          # Main game scene
│   ├── player.tscn        # Player (RBC) scene
│   ├── tissue_cell.tscn   # Tissue cell scene
│   └── platelet.tscn      # Platelet hazard scene
└── scripts/
    ├── main.gd            # Main scene controller
    ├── player.gd          # Player movement and state
    ├── cargo_manager.gd   # O₂/CO₂ slot management
    ├── zone_manager.gd    # Circulatory loop management
    ├── spawner.gd         # Cell and platelet spawning
    ├── tissue_cell.gd     # Tissue cell behavior
    ├── platelet.gd        # Platelet hazard behavior
    └── ui_manager.gd      # HUD and popup management
```

## Getting Started

1. Open the project in Godot 4.5+
2. The placeholder SVG graphics will display as colored shapes
3. Replace with your own artwork as desired
4. Add sound effects to `assets/sounds/`
5. Run the main scene!

## Key Constants

Adjust these in `autoloads/game_constants.gd`:

```gdscript
const FLOW_SPEED: float = 200.0      # Blood flow speed (px/s)
const PLAYER_SPEED_MULTIPLIER: float = 2.0  # Player speed relative to flow
const DELIVERIES_FOR_MISSION_COMPLETE: int = 10  # Win condition
const EXCHANGE_CHANCE: float = 0.7   # % of cells that need O₂
```

## Technical Notes

- Target resolution: 1280×720
- Uses relative velocity system ("submarine" movement)
- Player moves at 2× flow speed relative to screen
- Collision layers: Player (1), Cells/Hazards (2)

## Requirements

- Godot 4.5 or later
- No external dependencies

## License

Educational use. See GDD for full design documentation.

---

*Developed with Claude 4.5 Suite (Opus, Sonnet, Haiku)*
