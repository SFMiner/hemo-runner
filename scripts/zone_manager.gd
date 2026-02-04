# zone_manager.gd
# Manages the circulatory loop: Tissue -> Heart -> Lung -> Heart -> Tissue
# Controls zone transitions and heart zone cutscenes
#
# Educational Purpose: Demonstrates the path blood takes through the body -
# from body tissues, through the heart, to the lungs for oxygenation,
# back through the heart, and out to the body again

class_name ZoneManager
extends Node

# === SIGNALS ===
signal zone_changed(new_zone: int)  # int = ZoneType enum value
signal heart_zone_entered(going_to_lungs: bool)
signal heart_zone_exited()
signal lung_zone_entered()
signal lung_zone_exited()

# === STATE ===
var current_zone: int = GameConstants.ZoneType.TISSUE
var zone_timer: float = 0.0
var loop_count: int = 0  # Track full body loops (for platelet spawning)

# === ZONE DURATIONS ===
# These match the constants but can be modified for testing
var tissue_duration: float = GameConstants.TISSUE_ZONE_DURATION
var heart_duration: float = GameConstants.HEART_ZONE_DURATION
var lung_duration: float = GameConstants.LUNG_ZONE_DURATION


func _ready() -> void:
	# Start in tissue zone
	current_zone = GameConstants.ZoneType.TISSUE
	zone_timer = 0.0


func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	
	zone_timer += delta
	
	# Check for zone transitions based on timer
	match current_zone:
		GameConstants.ZoneType.TISSUE:
			if zone_timer >= tissue_duration:
				_transition_to(GameConstants.ZoneType.HEART_TO_LUNGS)
		
		GameConstants.ZoneType.HEART_TO_LUNGS:
			if zone_timer >= heart_duration:
				_transition_to(GameConstants.ZoneType.LUNG)
		
		GameConstants.ZoneType.LUNG:
			if zone_timer >= lung_duration:
				_transition_to(GameConstants.ZoneType.HEART_TO_BODY)
		
		GameConstants.ZoneType.HEART_TO_BODY:
			if zone_timer >= heart_duration:
				_transition_to(GameConstants.ZoneType.TISSUE)
				loop_count += 1


## Transition to a new zone
func _transition_to(new_zone: int) -> void:
	var old_zone: int = current_zone
	current_zone = new_zone
	zone_timer = 0.0
	
	# Emit appropriate signals
	zone_changed.emit(new_zone)
	
	match new_zone:
		GameConstants.ZoneType.HEART_TO_LUNGS:
			heart_zone_entered.emit(true)  # Going to lungs
		
		GameConstants.ZoneType.HEART_TO_BODY:
			heart_zone_entered.emit(false)  # Going to body
		
		GameConstants.ZoneType.LUNG:
			if old_zone == GameConstants.ZoneType.HEART_TO_LUNGS:
				heart_zone_exited.emit()
			lung_zone_entered.emit()
		
		GameConstants.ZoneType.TISSUE:
			if old_zone == GameConstants.ZoneType.HEART_TO_BODY:
				heart_zone_exited.emit()
			lung_zone_exited.emit()


## Get the current zone type
func get_current_zone() -> int:
	return current_zone


## Check if currently in a heart zone (cutscene)
func is_in_heart_zone() -> bool:
	return current_zone == GameConstants.ZoneType.HEART_TO_LUNGS or \
		   current_zone == GameConstants.ZoneType.HEART_TO_BODY


## Check if currently in lung zone
func is_in_lung_zone() -> bool:
	return current_zone == GameConstants.ZoneType.LUNG


## Check if currently in tissue zone (main gameplay)
func is_in_tissue_zone() -> bool:
	return current_zone == GameConstants.ZoneType.TISSUE


## Get the number of completed body loops
func get_loop_count() -> int:
	return loop_count


## Get progress through current zone (0.0 to 1.0)
func get_zone_progress() -> float:
	var duration: float = _get_current_zone_duration()
	if duration > 0.0:
		return zone_timer / duration
	return 0.0


## Get duration of current zone
func _get_current_zone_duration() -> float:
	match current_zone:
		GameConstants.ZoneType.TISSUE:
			return tissue_duration
		GameConstants.ZoneType.HEART_TO_LUNGS, GameConstants.ZoneType.HEART_TO_BODY:
			return heart_duration
		GameConstants.ZoneType.LUNG:
			return lung_duration
	return 1.0


## Get zone name for UI/debug display
func get_zone_name() -> String:
	match current_zone:
		GameConstants.ZoneType.TISSUE:
			return "Body Tissues"
		GameConstants.ZoneType.HEART_TO_LUNGS:
			return "Heart (to Lungs)"
		GameConstants.ZoneType.LUNG:
			return "Lungs"
		GameConstants.ZoneType.HEART_TO_BODY:
			return "Heart (to Body)"
	return "Unknown"


## Reset zone manager for new game
func reset() -> void:
	current_zone = GameConstants.ZoneType.TISSUE
	zone_timer = 0.0
	loop_count = 0
