# main.gd
# Main game scene controller
# Manages world scrolling, zone transitions, and coordinates all systems
#
# Educational Purpose: Creates the immersive experience of flowing through
# the circulatory system as a red blood cell

extends Node2D

# === NODE REFERENCES ===
@onready var world_scroll_anchor: Node2D = $WorldScrollAnchor
@onready var camera: Camera2D = $WorldScrollAnchor/Camera2D
@onready var player: Player = $Player
@onready var spawner: Spawner = $Spawner
@onready var zone_manager: ZoneManager = $ZoneManager
@onready var ui_manager: UIManager = $UI
@onready var entities: Node2D = $Entities  # Parent for spawned cells/platelets
@onready var background: Sprite2D = $Background

# === SCROLL STATE ===
var world_scroll_offset: float = 0.0
var scroll_active: bool = true

# === HEART ZONE VISUALS ===
var background_spin_active: bool = false
var background_spin_speed: float = 0.0


func _ready() -> void:
	# Set up spawner
	if spawner:
		spawner.set_spawn_parent(entities)
	
	# Connect zone manager signals
	if zone_manager:
		zone_manager.zone_changed.connect(_on_zone_changed)
		zone_manager.heart_zone_entered.connect(_on_heart_zone_entered)
		zone_manager.heart_zone_exited.connect(_on_heart_zone_exited)
		zone_manager.lung_zone_entered.connect(_on_lung_zone_entered)
	
	# Connect player signals
	if player:
		player.left_screen.connect(_on_player_left_screen)
		player.stuck_on_platelet.connect(_on_player_stuck)
		
		# Connect UI to cargo manager
		var cargo: Node = player.get_cargo_manager()
		if cargo and ui_manager:
			ui_manager.connect_cargo_manager(cargo)
	
	# Connect UI signals
	if ui_manager:
		ui_manager.tutorial_completed.connect(_on_tutorial_completed)
	
	# Initialize game
	_start_game()


func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	
	# Update world scroll
	if scroll_active:
		_update_world_scroll(delta)
	
	# Update spawner position
	if spawner:
		spawner.set_world_scroll_position(world_scroll_offset)
	
	# Update player world offset
	if player:
		player.set_world_offset(world_scroll_offset)
	
	# Handle heart zone background spin
	if background_spin_active and background:
		background.rotation += background_spin_speed * delta
	
	# Update zone display
	if zone_manager and ui_manager:
		ui_manager.update_zone_display(zone_manager.get_zone_name())
	
	# Clean up off-screen entities
	_cleanup_entities()


## Update the world scroll (camera moves right at FLOW_SPEED)
func _update_world_scroll(delta: float) -> void:
	world_scroll_offset += GameConstants.FLOW_SPEED * delta
	
	if world_scroll_anchor:
		world_scroll_anchor.position.x = world_scroll_offset


## Start the game (or restart)
func _start_game() -> void:
	# Reset game state
	GameManager.reset_game()
	
	if zone_manager:
		zone_manager.reset()
	
	if spawner:
		spawner.reset()
	
	# Reset scroll
	world_scroll_offset = 0.0
	if world_scroll_anchor:
		world_scroll_anchor.position.x = 0.0
	
	# Reset background rotation
	if background:
		background.rotation = 0.0
	background_spin_active = false
	
	# Position player at center-left of screen
	if player:
		player.global_position = Vector2(200, GameConstants.RESOLUTION.y / 2.0)
	
	# Clear existing entities
	_clear_all_entities()
	
	# Start tutorial
	if ui_manager:
		ui_manager.start_tutorial()
	
	# Pause game until tutorial is done
	GameManager.change_state(GameManager.GameState.TUTORIAL)


## Handle zone changes
func _on_zone_changed(new_zone: int) -> void:
	match new_zone:
		GameConstants.ZoneType.TISSUE:
			_enter_tissue_zone()
		GameConstants.ZoneType.HEART_TO_LUNGS, GameConstants.ZoneType.HEART_TO_BODY:
			pass  # Handled by specific signals
		GameConstants.ZoneType.LUNG:
			_enter_lung_zone()


## Enter heart zone (cutscene)
func _on_heart_zone_entered(going_to_lungs: bool) -> void:
	# Start background spinning
	background_spin_active = true
	background_spin_speed = randf_range(-3.0, 3.0)  # Random spin direction/speed
	if abs(background_spin_speed) < 1.0:
		background_spin_speed = 2.0 if randf() > 0.5 else -2.0
	
	# Put player in cutscene mode
	if player:
		player.enter_cutscene()
		# Center player on screen during cutscene
		var tween: Tween = create_tween()
		tween.tween_property(player, "global_position", 
			Vector2(GameConstants.RESOLUTION.x / 2.0, GameConstants.RESOLUTION.y / 2.0), 
			0.5)
	
	# Show heart zone message
	if ui_manager:
		ui_manager.show_heart_zone_message(going_to_lungs)


## Exit heart zone
func _on_heart_zone_exited() -> void:
	# Stop background spinning
	background_spin_active = false
	
	# Smoothly return background to normal
	if background:
		var tween: Tween = create_tween()
		tween.tween_property(background, "rotation", 0.0, 0.5)
	
	# Return player control
	if player:
		player.exit_cutscene()


## Enter lung zone
func _on_lung_zone_entered() -> void:
	# Exchange CO2 for O2 in player's cargo
	if player:
		var cargo: Node = player.get_cargo_manager()
		if cargo and cargo.has_method("exchange_in_lungs"):
			cargo.exchange_in_lungs()
	
	# Visual feedback - maybe tint background pink
	if background:
		var tween: Tween = create_tween()
		tween.tween_property(background, "modulate", Color(1.0, 0.8, 0.85), 0.5)


## Enter tissue zone (main gameplay)
func _enter_tissue_zone() -> void:
	# Return background to normal color
	if background:
		var tween: Tween = create_tween()
		tween.tween_property(background, "modulate", Color.WHITE, 0.5)


## Enter lung zone
func _enter_lung_zone() -> void:
	pass  # Already handled by signal


## Player left the screen (game over)
func _on_player_left_screen() -> void:
	scroll_active = false


## Player stuck on platelet
func _on_player_stuck() -> void:
	# Player is now being dragged by flow - game over imminent
	# Could add warning UI here
	pass


## Tutorial completed - start actual gameplay
func _on_tutorial_completed() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)


## Clean up entities that have scrolled off screen
func _cleanup_entities() -> void:
	if not entities:
		return
	
	var cleanup_x: float = world_scroll_offset - 100.0  # Clean up things 100px off left
	
	for child in entities.get_children():
		if child is Node2D:
			if child.global_position.x < cleanup_x:
				child.queue_free()


## Clear all spawned entities
func _clear_all_entities() -> void:
	if not entities:
		return
	
	for child in entities.get_children():
		child.queue_free()


## Handle game restart (called from UI)
func restart_game() -> void:
	_start_game()
