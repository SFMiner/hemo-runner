# game_manager.gd
# Manages overall game state, scoring, and win/lose conditions
# Singleton (AutoLoad) - accessible from any script as GameManager
#
# Educational Purpose: Tracks O2 deliveries to reinforce learning about
# the circulatory system's primary function

extends Node

# === SIGNALS ===
signal score_changed(new_score: int)
signal mission_complete()
signal game_over()
signal game_restarted()
signal control_scheme_changed(use_mouse: bool)

# === GAME STATE ===
enum GameState {
	MENU,
	TUTORIAL,
	PLAYING,
	PAUSED,
	MISSION_COMPLETE,
	GAME_OVER
}

var current_state: GameState = GameState.MENU
var previous_state: GameState = GameState.MENU

# === SCORING ===
var deliveries_count: int = 0  # Number of successful O2 deliveries
var total_exchanges: int = 0   # Total exchanges (including CO2 pickups)
var cells_visited: int = 0     # Unique cells that received O2

# === SETTINGS ===
var use_mouse_control: bool = false  # Toggle between WASD and mouse control

# === MISSION TRACKING ===
var mission_completed: bool = false
var continuing_after_mission: bool = false


func _ready() -> void:
	# Initialize random seed
	randomize()


## Reset all game state for a new game
func reset_game() -> void:
	deliveries_count = 0
	total_exchanges = 0
	cells_visited = 0
	mission_completed = false
	continuing_after_mission = false
	current_state = GameState.PLAYING
	game_restarted.emit()


## Record a successful O2 delivery to a tissue cell
func record_delivery() -> void:
	deliveries_count += 1
	cells_visited += 1
	total_exchanges += 1
	score_changed.emit(deliveries_count)
	
	# Check for mission complete
	if not mission_completed and deliveries_count >= GameConstants.DELIVERIES_FOR_MISSION_COMPLETE:
		mission_completed = true
		current_state = GameState.MISSION_COMPLETE
		mission_complete.emit()


## Record a CO2 pickup (for statistics, doesn't count toward mission)
func record_co2_pickup() -> void:
	total_exchanges += 1


## Change game state
func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	match new_state:
		GameState.GAME_OVER:
			game_over.emit()
		GameState.MISSION_COMPLETE:
			mission_complete.emit()


## Toggle control scheme between WASD and mouse
func toggle_control_scheme() -> void:
	use_mouse_control = not use_mouse_control
	control_scheme_changed.emit(use_mouse_control)


## Set control scheme explicitly
func set_control_scheme(use_mouse: bool) -> void:
	if use_mouse_control != use_mouse:
		use_mouse_control = use_mouse
		control_scheme_changed.emit(use_mouse_control)


## Player chose to continue after mission complete
func continue_playing() -> void:
	continuing_after_mission = true
	current_state = GameState.PLAYING


## Player chose to end game after mission complete
func end_game() -> void:
	current_state = GameState.MENU
	# This would trigger return to main menu


## Trigger game over (platelet collision)
func trigger_game_over() -> void:
	change_state(GameState.GAME_OVER)


## Check if game is currently playable
func is_playing() -> bool:
	return current_state == GameState.PLAYING


## Get progress toward mission complete as a percentage
func get_mission_progress() -> float:
	return float(deliveries_count) / float(GameConstants.DELIVERIES_FOR_MISSION_COMPLETE)


## Get formatted score string for UI
func get_score_display() -> String:
	if mission_completed and continuing_after_mission:
		return "Deliveries: %d" % deliveries_count
	else:
		return "Deliveries: %d / %d" % [deliveries_count, GameConstants.DELIVERIES_FOR_MISSION_COMPLETE]
