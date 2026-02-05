# tissue_cell.gd
# Represents a body tissue cell that can receive O2 and release CO2
# Not all cells need exchange (simulates other RBCs doing work)
#
# Educational Purpose: Demonstrates that tissue cells need oxygen for
# cellular respiration and produce carbon dioxide as a waste product

class_name TissueCell
extends Area2D

# === SIGNALS ===
signal exchange_completed(cell: TissueCell)

# === STATE ===
var o2_needed: int = 0      # How much O2 this cell needs (0-2)
var co2_available: int = 0  # How much CO2 this cell has to give (0-2)
var texture_variant: int = 0  # Which visual variant to use

# === NODE REFERENCES ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	# Determine how much O2 this cell needs and CO2 it has
	if GameConstants.cell_needs_exchange():
		o2_needed = GameConstants.get_cell_o2_need()
		co2_available = GameConstants.get_cell_co2_available()
	else:
		o2_needed = 0
		co2_available = 0

	# Set up visual appearance based on state
	_update_visual()

	# Connect area signals
	body_entered.connect(_on_body_entered)


## Initialize the cell with a specific texture variant
func initialize(variant: int = -1) -> void:
	if variant < 0:
		texture_variant = randi() % GameConstants.TISSUE_CELL_TEXTURE_VARIANTS
	else:
		texture_variant = variant
	
	# Texture loading would happen here when assets are available
	_update_visual()


## Update visual appearance based on whether cell needs O2
func _update_visual() -> void:
	if not sprite:
		return

	if o2_needed > 0:
		# Cell needs O2 - appears oxygen-starved (bluer/darker)
		# More O2 needed = more blue
		var intensity: float = float(o2_needed) / float(GameConstants.CELL_O2_NEED_MAX)
		sprite.modulate = GameConstants.COLOR_CELL_HEALTHY.lerp(GameConstants.COLOR_CELL_NEEDS_O2, intensity)
	else:
		# Cell is healthy or already received O2
		sprite.modulate = GameConstants.COLOR_CELL_HEALTHY


## Called when a body (player) enters this cell's area
func _on_body_entered(body: Node2D) -> void:
	if body is Player and (o2_needed > 0 or co2_available > 0):
		_attempt_exchange(body as Player)


## Attempt O2/CO2 exchange with the player
func _attempt_exchange(player: Player) -> void:
	var cargo: Node = player.get_cargo_manager()
	if not cargo:
		return

	var any_exchange: bool = false

	# Deliver O2 to the cell (cell receives O2, player loses O2)
	while o2_needed > 0 and cargo.has_method("deliver_o2") and cargo.has_o2():
		if cargo.deliver_o2():
			o2_needed -= 1
			any_exchange = true

	# Pick up CO2 from the cell (cell gives CO2, player gains CO2)
	while co2_available > 0 and cargo.has_method("pickup_co2") and cargo.has_empty_slot():
		if cargo.pickup_co2():
			co2_available -= 1
			any_exchange = true

	if any_exchange:
		_update_visual()
		exchange_completed.emit(self)
		_play_exchange_effect()


## Play visual/audio feedback for successful exchange
func _play_exchange_effect() -> void:
	# Flash effect
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_property(sprite, "modulate", GameConstants.COLOR_CELL_HEALTHY, 0.2)
	
	# Scale pulse
	var original_scale: Vector2 = sprite.scale
	var pulse_tween: Tween = create_tween()
	pulse_tween.tween_property(sprite, "scale", original_scale * 1.2, 0.1)
	pulse_tween.tween_property(sprite, "scale", original_scale, 0.15)


## Check if this cell still needs O2 or has CO2 to give
func still_needs_exchange() -> bool:
	return o2_needed > 0 or co2_available > 0


## Force set the exchange amounts (for testing/special cases)
func set_exchange_amounts(o2: int, co2: int) -> void:
	o2_needed = o2
	co2_available = co2
	_update_visual()
