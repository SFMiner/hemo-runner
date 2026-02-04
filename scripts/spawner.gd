# spawner.gd
# Manages spawning of tissue cells and platelets
# Spawns groups of 3-50 cells with 1-4 second gaps
#
# Educational Purpose: Simulates the continuous flow of the bloodstream
# past tissue cells that need oxygen delivery

class_name Spawner
extends Node

# === SIGNALS ===
signal cell_group_spawned(count: int)
signal platelet_spawned()

# === REFERENCES ===
var tissue_cell_scene: PackedScene
var platelet_scene: PackedScene

# === SPAWN STATE ===
var spawn_timer: float = 0.0
var current_gap_duration: float = 2.0
var is_spawning_group: bool = false
var cells_remaining_in_group: int = 0
var cell_spawn_delay: float = 0.1  # Time between individual cells in a group

var last_group_end_x: float = 0.0  # Track when last group ended

# === SPAWN POSITION ===
var spawn_x_offset: float = 100.0  # Spawn this far off right edge
var world_scroll_position: float = 0.0

# === PLATELET TRACKING ===
var platelet_spawned_this_loop: bool = false
var last_loop_count: int = 0

# === PARENT FOR SPAWNED OBJECTS ===
var spawn_parent: Node2D


func _ready() -> void:
	# Load scenes
	tissue_cell_scene = preload("res://scenes/tissue_cell.tscn")
	platelet_scene = preload("res://scenes/platelet.tscn")
	
	# Set initial gap
	current_gap_duration = GameConstants.get_random_cell_gap()


func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	
	# Only spawn in tissue zone
	var zone_manager: ZoneManager = _get_zone_manager()
	if zone_manager and not zone_manager.is_in_tissue_zone():
		return
	
	# Check for new loop (for platelet spawning)
	_check_loop_reset(zone_manager)
	
	# Handle spawning
	if is_spawning_group:
		_process_group_spawn(delta)
	else:
		_process_gap_timer(delta)


## Process spawning cells within a group
func _process_group_spawn(delta: float) -> void:
	spawn_timer += delta
	
	if spawn_timer >= cell_spawn_delay and cells_remaining_in_group > 0:
		spawn_timer = 0.0
		_spawn_single_cell()
		cells_remaining_in_group -= 1
		
		if cells_remaining_in_group <= 0:
			# Group complete
			is_spawning_group = false
			current_gap_duration = GameConstants.get_random_cell_gap()
			spawn_timer = 0.0
			
			# Record where this group ends (for gap timing)
			last_group_end_x = world_scroll_position + GameConstants.RESOLUTION.x + spawn_x_offset


## Process the gap timer between groups
func _process_gap_timer(delta: float) -> void:
	spawn_timer += delta
	
	if spawn_timer >= current_gap_duration:
		# Start new group
		_start_new_group()


## Start spawning a new group of cells
func _start_new_group() -> void:
	is_spawning_group = true
	cells_remaining_in_group = GameConstants.get_random_group_size()
	spawn_timer = 0.0
	
	cell_group_spawned.emit(cells_remaining_in_group)
	
	# Maybe spawn a platelet with this group
	_maybe_spawn_platelet()


## Spawn a single tissue cell
func _spawn_single_cell() -> void:
	if not tissue_cell_scene or not spawn_parent:
		return
	
	var cell: TissueCell = tissue_cell_scene.instantiate() as TissueCell
	if cell:
		# Position off right edge of screen
		var spawn_x: float = world_scroll_position + GameConstants.RESOLUTION.x + spawn_x_offset
		var spawn_y: float = randf_range(50.0, GameConstants.RESOLUTION.y - 50.0)
		
		cell.global_position = Vector2(spawn_x, spawn_y)
		cell.initialize()
		
		spawn_parent.add_child(cell)


## Check if we should spawn a platelet
func _maybe_spawn_platelet() -> void:
	if platelet_spawned_this_loop:
		return
	
	# 50% chance per loop, but only try once per loop
	if randf() < GameConstants.PLATELET_CHANCE_PER_LOOP:
		_spawn_platelet()
		platelet_spawned_this_loop = true


## Spawn a platelet hazard
func _spawn_platelet() -> void:
	if not platelet_scene or not spawn_parent:
		return
	
	var platelet: Platelet = platelet_scene.instantiate() as Platelet
	if platelet:
		# Position off right edge, random Y
		var spawn_x: float = world_scroll_position + GameConstants.RESOLUTION.x + spawn_x_offset + 50.0
		var spawn_y: float = randf_range(80.0, GameConstants.RESOLUTION.y - 80.0)
		
		platelet.global_position = Vector2(spawn_x, spawn_y)
		platelet.initialize()
		
		spawn_parent.add_child(platelet)
		platelet_spawned.emit()


## Check if a new loop has started (reset platelet flag)
func _check_loop_reset(zone_manager: ZoneManager) -> void:
	if not zone_manager:
		return
	
	var current_loop: int = zone_manager.get_loop_count()
	if current_loop > last_loop_count:
		last_loop_count = current_loop
		platelet_spawned_this_loop = false


## Get reference to ZoneManager (assumes it's a sibling or we find it)
func _get_zone_manager() -> ZoneManager:
	var parent: Node = get_parent()
	if parent:
		for child in parent.get_children():
			if child is ZoneManager:
				return child
	return null


## Set the parent node for spawned objects
func set_spawn_parent(parent: Node2D) -> void:
	spawn_parent = parent


## Update world scroll position (called by Main scene)
func set_world_scroll_position(pos: float) -> void:
	world_scroll_position = pos


## Reset spawner state for new game
func reset() -> void:
	spawn_timer = 0.0
	current_gap_duration = GameConstants.get_random_cell_gap()
	is_spawning_group = false
	cells_remaining_in_group = 0
	platelet_spawned_this_loop = false
	last_loop_count = 0
