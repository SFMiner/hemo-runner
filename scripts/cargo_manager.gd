# cargo_manager.gd
# Manages the 4 cargo slots on the Red Blood Cell
# Handles O2/CO2 exchange logic
#
# Educational Purpose: Demonstrates how hemoglobin in RBCs binds to oxygen
# in the lungs and releases it to tissues, picking up CO2 in return

class_name CargoManager
extends Node

# === SIGNALS ===
signal slot_changed(slot_index: int, new_state: int)  # int = SlotState enum value
signal o2_delivered()
signal co2_picked_up()
signal all_slots_changed()

# === CARGO STATE ===
# Array of 4 slots, each can be EMPTY, O2, CO2, or CO
var slots: Array[int] = []  # Using int to store SlotState enum values

# === VISUAL INDICATORS ===
var o2_indicators: Array[CanvasItem] = []
var co2_indicators: Array[CanvasItem] = []


func _ready() -> void:
	# Initialize all slots as empty
	slots.resize(GameConstants.CARGO_SLOTS)
	for i in range(GameConstants.CARGO_SLOTS):
		slots[i] = GameConstants.SlotState.EMPTY

	# Get references to visual indicators after scene tree is ready
	call_deferred("_deferred_setup")


## Deferred setup to ensure all sibling nodes exist
func _deferred_setup() -> void:
	_setup_visual_indicators()
	_update_visual_indicators()


## Set up references to O2 and CO2 visual indicator nodes
func _setup_visual_indicators() -> void:
	var player := get_parent()
	if not player:
		return

	# Get O2 indicators - all children of the O2 node
	var o2_parent := player.get_node_or_null("O2")
	if o2_parent:
		for child in o2_parent.get_children():
			if child is CanvasItem:
				o2_indicators.append(child)
				child.visible = false

	# Get CO2 indicators - all children of the CO2 node
	var co2_parent := player.get_node_or_null("CO2")
	if co2_parent:
		for child in co2_parent.get_children():
			if child is CanvasItem:
				co2_indicators.append(child)
				child.visible = false


## Update visual indicators based on current cargo
func _update_visual_indicators() -> void:
	var o2_count := count_o2()
	var co2_count := count_co2()

	# Show O2 indicators based on count
	for i in range(o2_indicators.size()):
		o2_indicators[i].visible = i < o2_count

	# Show CO2 indicators based on count
	for i in range(co2_indicators.size()):
		co2_indicators[i].visible = i < co2_count


## Fill all slots with O2 (called when passing through lung zone)
func fill_with_o2() -> void:
	for i in range(slots.size()):
		if slots[i] == GameConstants.SlotState.CO2 or slots[i] == GameConstants.SlotState.EMPTY:
			slots[i] = GameConstants.SlotState.O2
			slot_changed.emit(i, slots[i])
	all_slots_changed.emit()
	_update_visual_indicators()


## Attempt to exchange O2 for CO2 with a tissue cell (legacy - kept for compatibility)
## Returns true if at least one exchange occurred
func exchange_with_tissue() -> bool:
	return deliver_o2()


## Deliver one O2 to a tissue cell (O2 slot becomes EMPTY)
## Returns true if successful
func deliver_o2() -> bool:
	for i in range(slots.size()):
		if slots[i] == GameConstants.SlotState.O2:
			slots[i] = GameConstants.SlotState.EMPTY
			slot_changed.emit(i, slots[i])
			o2_delivered.emit()
			GameManager.record_delivery()
			_update_visual_indicators()
			return true
	return false


## Pick up one CO2 from a tissue cell (EMPTY slot becomes CO2)
## Returns true if successful
func pickup_co2() -> bool:
	for i in range(slots.size()):
		if slots[i] == GameConstants.SlotState.EMPTY:
			slots[i] = GameConstants.SlotState.CO2
			slot_changed.emit(i, slots[i])
			co2_picked_up.emit()
			GameManager.record_co2_pickup()
			_update_visual_indicators()
			return true
	return false


## Check if there's an empty slot available
func has_empty_slot() -> bool:
	for slot in slots:
		if slot == GameConstants.SlotState.EMPTY:
			return true
	return false


## Exchange all CO2 for O2 (lung zone behavior)
func exchange_in_lungs() -> void:
	for i in range(slots.size()):
		if slots[i] == GameConstants.SlotState.CO2:
			slots[i] = GameConstants.SlotState.O2
			slot_changed.emit(i, slots[i])
		elif slots[i] == GameConstants.SlotState.EMPTY:
			# Lungs also fill empty slots
			slots[i] = GameConstants.SlotState.O2
			slot_changed.emit(i, slots[i])
	all_slots_changed.emit()
	_update_visual_indicators()


## Get the current state of a specific slot
func get_slot_state(index: int) -> int:
	if index >= 0 and index < slots.size():
		return slots[index]
	return GameConstants.SlotState.EMPTY


## Get the color for a specific slot (for UI display)
func get_slot_color(index: int) -> Color:
	var state: int = get_slot_state(index)
	return GameConstants.get_slot_color(state)


## Count how many O2 molecules are currently carried
func count_o2() -> int:
	var count: int = 0
	for slot in slots:
		if slot == GameConstants.SlotState.O2:
			count += 1
	return count


## Count how many CO2 molecules are currently carried
func count_co2() -> int:
	var count: int = 0
	for slot in slots:
		if slot == GameConstants.SlotState.CO2:
			count += 1
	return count


## Check if there's any O2 available for delivery
func has_o2() -> bool:
	return count_o2() > 0


## Check if there's any CO2 to exchange in lungs
func has_co2() -> bool:
	return count_co2() > 0


## Block a slot with CO (Carbon Monoxide) - future feature
## Once blocked, slot cannot be used for O2/CO2
func block_slot_with_co(index: int) -> void:
	if index >= 0 and index < slots.size():
		if slots[index] != GameConstants.SlotState.CO:
			slots[index] = GameConstants.SlotState.CO
			slot_changed.emit(index, slots[index])
			_update_visual_indicators()


## Get array of all slot states (for save/load or UI refresh)
func get_all_slots() -> Array[int]:
	return slots.duplicate()
