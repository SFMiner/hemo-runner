# player.gd
# Controls the Red Blood Cell (RBC) player character
# Implements the "submarine" relative velocity movement system
#
# Educational Purpose: The player physically represents a red blood cell
# navigating through the bloodstream, carrying oxygen to tissues

class_name Player
extends CharacterBody2D

# === SIGNALS ===
signal stuck_on_platelet()
signal freed_from_platelet()
signal left_screen()  # Game over trigger

# === PLAYER STATE ===
enum State {
	NORMAL,
	STUCK,      # Trapped by platelet
	CUTSCENE    # During heart zone transitions
}

var current_state: State = State.NORMAL

# === MOVEMENT ===
var screen_velocity: Vector2 = Vector2.ZERO  # Velocity relative to screen
var world_offset: float = 0.0  # Current camera/world scroll offset

# === NODE REFERENCES ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var cargo_manager: Node = $CargoManager

# === SQUASH & STRETCH ===
var base_scale: Vector2 = Vector2.ONE
const SQUASH_AMOUNT: float = 0.15
const SQUASH_SPEED: float = 8.0


func _ready() -> void:
	base_scale = sprite.scale
	# Start with full O2 cargo (simulating coming from lungs)
	if cargo_manager:
		cargo_manager.fill_with_o2()


func _physics_process(delta: float) -> void:
	match current_state:
		State.NORMAL:
			_handle_normal_movement(delta)
		State.STUCK:
			_handle_stuck_state(delta)
		State.CUTSCENE:
			_handle_cutscene_state(delta)
	
	# Check for left edge game over
	_check_left_edge()
	
	# Apply squash and stretch based on movement
	_apply_squash_stretch(delta)


## Handle normal player-controlled movement
func _handle_normal_movement(delta: float) -> void:
	var input_direction: Vector2 = _get_input_direction()

	# Player moves at PLAYER_SPEED relative to the screen/parent
	screen_velocity = input_direction * GameConstants.PLAYER_SPEED

	# Player is a child of WorldScrollAnchor, so movement is in local space
	# No need to compensate for world scroll - the parent handles that
	velocity = screen_velocity
	move_and_slide()

	# Clamp to screen bounds (top/bottom only - left edge is game over)
	_clamp_to_screen_bounds()


## Get input direction based on current control scheme
func _get_input_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO
	
	if GameManager.use_mouse_control:
		# Mouse control: move toward cursor position
		var mouse_pos: Vector2 = get_global_mouse_position()
		var to_mouse: Vector2 = mouse_pos - global_position
		
		# Only move if mouse is far enough away (dead zone)
		if to_mouse.length() > 10.0:
			direction = to_mouse.normalized()
	else:
		# WASD control: standard directional input
		direction.x = Input.get_axis("move_left", "move_right")
		direction.y = Input.get_axis("move_up", "move_down")
		
		if direction.length() > 1.0:
			direction = direction.normalized()
	
	return direction


## Handle state when stuck on a platelet
## The player cannot move; they drift left relative to the screen
func _handle_stuck_state(delta: float) -> void:
	# Player is child of WorldScrollAnchor which moves right
	# To drift left on screen, we need negative velocity in local space
	# This simulates being stuck in the bloodstream while camera moves on
	velocity = Vector2(-GameConstants.FLOW_SPEED, 0)
	move_and_slide()


## Handle movement during heart zone cutscenes
func _handle_cutscene_state(delta: float) -> void:
	# During cutscenes, player is auto-moved (centered on screen)
	# Movement is controlled by the ZoneManager
	pass


## Clamp player position to screen bounds
func _clamp_to_screen_bounds() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var half_size: float = 32.0  # Approximate collision radius

	# Player is child of WorldScrollAnchor, position is in local/screen space
	# Clamp vertical position
	position.y = clamp(
		position.y,
		half_size,
		viewport_size.y - half_size
	)

	# Clamp right edge (can't go off right side of screen)
	var max_x: float = viewport_size.x - half_size
	if position.x > max_x:
		position.x = max_x


## Check if player has been pushed off the left edge (game over)
func _check_left_edge() -> void:
	var half_width: float = 32.0  # Approximate collision radius

	# Player position is in local/screen space, check against screen left
	if position.x < -half_width:
		left_screen.emit()
		GameManager.trigger_game_over()


## Apply squash and stretch effect based on velocity
func _apply_squash_stretch(delta: float) -> void:
	if not sprite:
		return
	
	var target_scale: Vector2 = base_scale
	
	if screen_velocity.length() > 10.0:
		# Calculate squash based on movement direction
		var speed_factor: float = screen_velocity.length() / GameConstants.PLAYER_SPEED
		var squash: float = SQUASH_AMOUNT * speed_factor
		
		# Squash perpendicular to movement, stretch along movement
		if abs(screen_velocity.x) > abs(screen_velocity.y):
			# Moving horizontally - stretch X, squash Y
			target_scale.x = base_scale.x * (1.0 + squash)
			target_scale.y = base_scale.y * (1.0 - squash * 0.5)
		else:
			# Moving vertically - stretch Y, squash X
			target_scale.x = base_scale.x * (1.0 - squash * 0.5)
			target_scale.y = base_scale.y * (1.0 + squash)
	
	# Lerp to target scale for smooth effect
	sprite.scale = sprite.scale.lerp(target_scale, SQUASH_SPEED * delta)


## Called when player collides with a platelet
func stick_to_platelet() -> void:
	if current_state == State.NORMAL:
		current_state = State.STUCK
		stuck_on_platelet.emit()


## Enter cutscene mode (heart zone transition)
func enter_cutscene() -> void:
	current_state = State.CUTSCENE


## Exit cutscene mode
func exit_cutscene() -> void:
	current_state = State.NORMAL


## Update the world scroll offset (called by Main scene)
func set_world_offset(offset: float) -> void:
	world_offset = offset


## Get current cargo manager for external access
func get_cargo_manager() -> Node:
	return cargo_manager


## Reset player state for new game
func reset() -> void:
	current_state = State.NORMAL
	screen_velocity = Vector2.ZERO
	world_offset = 0.0
	velocity = Vector2.ZERO
	if cargo_manager and cargo_manager.has_method("fill_with_o2"):
		cargo_manager.fill_with_o2()
