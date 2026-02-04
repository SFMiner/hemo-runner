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
var needs_exchange: bool = false  # Does this cell need O2?
var has_exchanged: bool = false   # Has exchange already occurred?
var texture_variant: int = 0      # Which visual variant to use

# === NODE REFERENCES ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	# Determine if this cell needs O2 exchange
	needs_exchange = GameConstants.cell_needs_exchange()
	
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
	
	if needs_exchange and not has_exchanged:
		# Cell needs O2 - appears oxygen-starved (bluer/darker)
		sprite.modulate = GameConstants.COLOR_CELL_NEEDS_O2
	else:
		# Cell is healthy or already received O2
		sprite.modulate = GameConstants.COLOR_CELL_HEALTHY


## Called when a body (player) enters this cell's area
func _on_body_entered(body: Node2D) -> void:
	if body is Player and needs_exchange and not has_exchanged:
		_attempt_exchange(body as Player)


## Attempt O2/CO2 exchange with the player
func _attempt_exchange(player: Player) -> void:
	var cargo: Node = player.get_cargo_manager()
	if cargo and cargo.has_method("exchange_with_tissue"):
		var success: bool = cargo.exchange_with_tissue()
		if success:
			has_exchanged = true
			needs_exchange = false
			_update_visual()
			exchange_completed.emit(self)
			
			# Play exchange animation/effect
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


## Check if this cell still needs O2
func still_needs_exchange() -> bool:
	return needs_exchange and not has_exchanged


## Force set the exchange state (for testing/special cases)
func set_needs_exchange(value: bool) -> void:
	needs_exchange = value
	has_exchanged = false
	_update_visual()
