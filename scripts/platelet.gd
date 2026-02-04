# platelet.gd
# Represents an activated platelet cluster (blood clot hazard)
# Contact is instant game over - no recovery mechanic
#
# Educational Purpose: Demonstrates that blood clots (formed by platelets)
# can be dangerous, blocking blood flow in vessels

class_name Platelet
extends Area2D

# === SIGNALS ===
signal player_trapped(platelet: Platelet)

# === STATE ===
var is_active: bool = true

# === NODE REFERENCES ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	# Connect area signals
	body_entered.connect(_on_body_entered)
	
	# Visual setup - platelets look sticky/dangerous
	if sprite:
		sprite.modulate = Color(0.9, 0.8, 0.6, 1.0)  # Yellowish clot color


## Called when a body (player) enters the platelet area
func _on_body_entered(body: Node2D) -> void:
	if body is Player and is_active:
		_trap_player(body as Player)


## Trap the player - this triggers game over
func _trap_player(player: Player) -> void:
	is_active = false  # Prevent multiple triggers
	
	# Tell player they're stuck
	player.stick_to_platelet()
	
	# Emit signal for effects/sound
	player_trapped.emit(self)
	
	# Visual feedback
	_play_trap_effect()


## Play visual effect when player is trapped
func _play_trap_effect() -> void:
	if not sprite:
		return
	
	# Pulse red to indicate danger
	var tween: Tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.15)
	tween.tween_property(sprite, "modulate", Color(0.9, 0.8, 0.6, 1.0), 0.15)


## Initialize platelet (called by spawner)
func initialize() -> void:
	is_active = true
	
	# Random slight rotation for variety
	if sprite:
		sprite.rotation = randf_range(-0.3, 0.3)
