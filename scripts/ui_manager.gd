# ui_manager.gd
# Manages all UI elements: HUD, cargo display, popups, tutorial
#
# Educational Purpose: Provides feedback to reinforce learning about
# oxygen delivery and the circulatory system journey

class_name UIManager
extends CanvasLayer

# === SIGNALS ===
signal tutorial_completed()
signal popup_dismissed()
signal mission_dialog_choice(continue_playing: bool)

# === NODE REFERENCES ===
@onready var cargo_display: HBoxContainer = $HUD/CargoDisplay
@onready var score_label: Label = $HUD/ScoreLabel
@onready var zone_label: Label = $HUD/ZoneLabel
@onready var popup_panel: PanelContainer = $PopupPanel
@onready var popup_label: Label = $PopupPanel/MarginContainer/PopupLabel
@onready var tutorial_panel: PanelContainer = $TutorialPanel
@onready var tutorial_label: Label = $TutorialPanel/MarginContainer/VBoxContainer/TutorialLabel
@onready var tutorial_button: Button = $TutorialPanel/MarginContainer/VBoxContainer/ContinueButton
@onready var mission_dialog: PanelContainer = $MissionDialog
@onready var end_button: Button = $MissionDialog/MarginContainer/VBoxContainer/HBoxContainer/EndButton
@onready var continue_button: Button = $MissionDialog/MarginContainer/VBoxContainer/HBoxContainer/ContinueButton

# === CARGO SLOT REFERENCES ===
var cargo_slots: Array[ColorRect] = []

# === TUTORIAL STATE ===
var tutorial_panels: Array[String] = [
	"You are a Red Blood Cell.\nMove with WASD or Mouse.",
	"Carry O₂ (red) to blue Tissue Cells that need it.",
	"Avoid sticky Platelets — they'll trap you!",
	"Pass through the Lungs to reload O₂.\nThe Heart pumps you there and back!"
]
var current_tutorial_index: int = 0
var tutorial_active: bool = false

# === POPUP STATE ===
var popup_queue: Array[String] = []
var popup_visible: bool = false
var popup_auto_hide_timer: float = 0.0
const POPUP_DURATION: float = 3.0


func _ready() -> void:
	# Set up cargo slot display
	_setup_cargo_display()
	
	# Connect signals
	if tutorial_button:
		tutorial_button.pressed.connect(_on_tutorial_continue)
	if end_button:
		end_button.pressed.connect(_on_end_game_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	
	# Connect to GameManager signals
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.mission_complete.connect(_on_mission_complete)
	GameManager.game_over.connect(_on_game_over)
	
	# Hide dialogs initially
	if popup_panel:
		popup_panel.visible = false
	if tutorial_panel:
		tutorial_panel.visible = false
	if mission_dialog:
		mission_dialog.visible = false
	
	# Initial UI update
	_update_score_display()


func _process(delta: float) -> void:
	# Handle popup auto-hide
	if popup_visible and popup_auto_hide_timer > 0:
		popup_auto_hide_timer -= delta
		if popup_auto_hide_timer <= 0:
			_hide_popup()
			_show_next_popup()


## Set up the cargo slot visual display
func _setup_cargo_display() -> void:
	if not cargo_display:
		return
	
	cargo_slots.clear()
	
	# Create 4 cargo slot indicators
	for i in range(GameConstants.CARGO_SLOTS):
		var slot: ColorRect = ColorRect.new()
		slot.custom_minimum_size = Vector2(32, 32)
		slot.color = GameConstants.COLOR_EMPTY
		cargo_display.add_child(slot)
		cargo_slots.append(slot)


## Update a single cargo slot's visual
func update_cargo_slot(index: int, state: int) -> void:
	if index >= 0 and index < cargo_slots.size():
		cargo_slots[index].color = GameConstants.get_slot_color(state)


## Update all cargo slots from an array of states
func update_all_cargo_slots(states: Array[int]) -> void:
	for i in range(min(states.size(), cargo_slots.size())):
		cargo_slots[i].color = GameConstants.get_slot_color(states[i])


## Update score display
func _update_score_display() -> void:
	if score_label:
		score_label.text = GameManager.get_score_display()


func _on_score_changed(new_score: int) -> void:
	_update_score_display()


## Update zone display
func update_zone_display(zone_name: String) -> void:
	if zone_label:
		zone_label.text = zone_name


## Show a popup message
func show_popup(message: String, auto_hide: bool = true) -> void:
	popup_queue.append(message)
	
	if not popup_visible:
		_show_next_popup()


## Show the next queued popup
func _show_next_popup() -> void:
	if popup_queue.is_empty():
		return
	
	var message: String = popup_queue.pop_front()
	
	if popup_panel and popup_label:
		popup_label.text = message
		popup_panel.visible = true
		popup_visible = true
		popup_auto_hide_timer = POPUP_DURATION


## Hide the current popup
func _hide_popup() -> void:
	if popup_panel:
		popup_panel.visible = false
	popup_visible = false
	popup_dismissed.emit()


## Start the tutorial sequence
func start_tutorial() -> void:
	tutorial_active = true
	current_tutorial_index = 0
	_show_tutorial_panel()


## Show current tutorial panel
func _show_tutorial_panel() -> void:
	if not tutorial_panel or not tutorial_label:
		return
	
	if current_tutorial_index < tutorial_panels.size():
		tutorial_label.text = tutorial_panels[current_tutorial_index]
		tutorial_panel.visible = true
		
		if tutorial_button:
			if current_tutorial_index == tutorial_panels.size() - 1:
				tutorial_button.text = "Start!"
			else:
				tutorial_button.text = "Continue"


## Handle tutorial continue button
func _on_tutorial_continue() -> void:
	current_tutorial_index += 1
	
	if current_tutorial_index >= tutorial_panels.size():
		# Tutorial complete
		tutorial_active = false
		if tutorial_panel:
			tutorial_panel.visible = false
		tutorial_completed.emit()
	else:
		_show_tutorial_panel()


## Show mission complete dialog
func _on_mission_complete() -> void:
	if mission_dialog:
		mission_dialog.visible = true


## Handle end game button
func _on_end_game_pressed() -> void:
	if mission_dialog:
		mission_dialog.visible = false
	mission_dialog_choice.emit(false)
	GameManager.end_game()


## Handle continue button
func _on_continue_pressed() -> void:
	if mission_dialog:
		mission_dialog.visible = false
	mission_dialog_choice.emit(true)
	GameManager.continue_playing()


## Show game over screen
func _on_game_over() -> void:
	show_popup("GAME OVER\nYou were trapped by a blood clot!", false)


## Show heart zone message
func show_heart_zone_message(going_to_lungs: bool) -> void:
	if going_to_lungs:
		show_popup("Going through the heart\non the way to the lungs!")
	else:
		show_popup("Now oxygenated!\nBack to the body cells!")


## Connect to a CargoManager for live updates
func connect_cargo_manager(cargo_manager: Node) -> void:
	if cargo_manager.has_signal("slot_changed"):
		cargo_manager.slot_changed.connect(update_cargo_slot)
	if cargo_manager.has_signal("all_slots_changed"):
		cargo_manager.all_slots_changed.connect(_refresh_all_slots.bind(cargo_manager))


func _refresh_all_slots(cargo_manager: Node) -> void:
	if cargo_manager.has_method("get_all_slots"):
		var slots: Array[int] = cargo_manager.get_all_slots()
		update_all_cargo_slots(slots)
