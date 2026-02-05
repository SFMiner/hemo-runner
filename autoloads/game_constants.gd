# game_constants.gd
# Global constants and utility functions for Hemo-Runner
# Singleton (AutoLoad) - accessible from any script as GameConstants
#
# Educational Purpose: Simulates blood flow physics and gas exchange mechanics

extends Node

# === FLOW & MOVEMENT CONSTANTS ===
# ADJUST THESE VALUES to tune game feel
const FLOW_SPEED: float = 200.0  # px/s - Base speed of blood flow (camera movement)
const PLAYER_SPEED_MULTIPLIER: float = 2.0  # Player moves at 2x flow speed relative to screen
const PLAYER_SPEED: float = FLOW_SPEED * PLAYER_SPEED_MULTIPLIER  # 400 px/s

# === DISPLAY CONSTANTS ===
const RESOLUTION: Vector2i = Vector2i(1280, 720)
const LEFT_EDGE_BUFFER: float = 10.0  # Pixels from left edge before game over

# === CARGO SYSTEM ===
const CARGO_SLOTS: int = 4  # Red blood cells carry 4 hemoglobin molecules

# Slot states for the cargo system
enum SlotState {
	EMPTY,
	O2,   # Oxygen - delivered to tissue cells
	CO2,  # Carbon Dioxide - picked up from tissue cells
	CO    # Carbon Monoxide - future feature (permanently blocks slot)
}

# === ZONE TIMING ===
const TISSUE_ZONE_DURATION: float = 15.0  # Seconds in tissue zone
const LUNG_ZONE_DURATION: float = 5.0     # Seconds in lung zone
const HEART_ZONE_DURATION: float = 3.0    # Seconds for heart transition
const FULL_LOOP_DURATION: float = TISSUE_ZONE_DURATION + (HEART_ZONE_DURATION * 2) + LUNG_ZONE_DURATION

# Zone types for the circulatory loop
enum ZoneType {
	TISSUE,      # Main gameplay - deliver O2
	HEART_TO_LUNGS,  # Cutscene - pulmonary artery
	LUNG,        # Reload O2
	HEART_TO_BODY    # Cutscene - aorta
}

# === SPAWNING CONSTANTS ===
const CELL_GROUP_MIN: int = 3
const CELL_GROUP_MAX: int = 50
const CELL_GAP_MIN: float = 1.0   # Seconds between groups
const CELL_GAP_MAX: float = 4.0
const TISSUE_CELL_TEXTURE_VARIANTS: int = 4
const EXCHANGE_CHANCE: float = 0.7  # 70% of cells need O2 exchange
const PLATELET_CHANCE_PER_LOOP: float = 0.5  # 50% chance per full body loop

# Cell exchange amounts (0-2 O2 needed, 0-2 CO2 to give)
const CELL_O2_NEED_MIN: int = 0
const CELL_O2_NEED_MAX: int = 2
const CELL_CO2_GIVE_MIN: int = 0
const CELL_CO2_GIVE_MAX: int = 2

# === WIN CONDITION ===
const DELIVERIES_FOR_MISSION_COMPLETE: int = 10

# === COLORS ===
# Visual feedback colors for slot states
const COLOR_EMPTY: Color = Color(0.5, 0.5, 0.5, 0.5)  # Gray, semi-transparent
const COLOR_O2: Color = Color(1.0, 0.2, 0.2, 1.0)     # Bright red
const COLOR_CO2: Color = Color(0.3, 0.3, 0.6, 1.0)    # Blue/maroon
const COLOR_CO: Color = Color(0.4, 0.4, 0.4, 1.0)     # Dark gray

# Tissue cell visual states
const COLOR_CELL_NEEDS_O2: Color = Color(0.4, 0.5, 0.8, 1.0)  # Bluer/darker
const COLOR_CELL_HEALTHY: Color = Color(0.6, 0.8, 0.6, 1.0)   # Healthier green-ish

# === UTILITY FUNCTIONS ===

## Get the color for a given slot state
func get_slot_color(state: SlotState) -> Color:
	match state:
		SlotState.EMPTY:
			return COLOR_EMPTY
		SlotState.O2:
			return COLOR_O2
		SlotState.CO2:
			return COLOR_CO2
		SlotState.CO:
			return COLOR_CO
	return COLOR_EMPTY


## Get a random gap time between cell groups
func get_random_cell_gap() -> float:
	return randf_range(CELL_GAP_MIN, CELL_GAP_MAX)


## Get a random cell group size
func get_random_group_size() -> int:
	return randi_range(CELL_GROUP_MIN, CELL_GROUP_MAX)


## Determine if a tissue cell needs O2 exchange
## Simulates that other RBCs are also doing work in the bloodstream
func cell_needs_exchange() -> bool:
	return randf() < EXCHANGE_CHANCE


## Get random amount of O2 a cell needs (0-2)
func get_cell_o2_need() -> int:
	return randi_range(CELL_O2_NEED_MIN, CELL_O2_NEED_MAX)


## Get random amount of CO2 a cell has to give (0-2)
func get_cell_co2_available() -> int:
	return randi_range(CELL_CO2_GIVE_MIN, CELL_CO2_GIVE_MAX)


## Calculate screen position from world position given camera offset
func world_to_screen(world_pos: Vector2, camera_offset: float) -> Vector2:
	return Vector2(world_pos.x - camera_offset, world_pos.y)


## Check if a world position is off the left edge of the screen
func is_off_left_edge(world_x: float, camera_offset: float) -> bool:
	var screen_x: float = world_x - camera_offset
	return screen_x < -LEFT_EDGE_BUFFER
