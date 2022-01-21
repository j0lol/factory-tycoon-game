extends Control
class_name GEDraggableWindow
tool

signal on_cancel()
signal on_ok()

export(bool) var show_ok_cancel = true setget set_ok_cancel_visible
export(bool) var show_close = true setget set_close_visible
export(String) var title = "" setget set_title

onready var title_bar = find_node("TitleBar")
onready var close_button = find_node("CloseButton")
onready var title_label = find_node("Title")
onready var main = find_node("Main")
var _main_child = null

var dragging = false
var mouse_offset = Vector2.ZERO
var children = []


func _ready() -> void:
	_main_child = main.get_child(0)
	
	set_title(title)
	set_ok_cancel_visible(show_ok_cancel)
	set_close_visible(show_close)
	
	hide()


func set_title(new_title: String):
	title = new_title
	
	if title_label:
		title_label.text = title


func set_ok_cancel_visible(new_visible: bool):
	show_ok_cancel = new_visible
	if _main_child:
		_main_child.visible = show_ok_cancel


func set_close_visible(new_visible: bool):
	show_close = new_visible
	if close_button:
		close_button.visible = show_close


func _add_child(child, legible_unique_name=false):
	main.add_child(child, legible_unique_name)
	_main_child.raise()


func _input(event: InputEvent) -> void:
	if not dragging or not visible:
		return
	rect_global_position = get_global_mouse_position() - mouse_offset
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and not event.pressed:
			dragging = false


func _on_ColorRect2_gui_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event is InputEventMouseButton:
		if not Rect2(title_bar.rect_global_position, title_bar.rect_size).has_point(
				get_global_mouse_position()):
			return
		if event.button_index == BUTTON_LEFT and event.pressed:
			dragging = true
			mouse_offset = get_global_mouse_position() - rect_global_position



##################################################
# Components
##################################################

func add_component_float(comp_name: String, 
		default: float, from: float = -1, to: float = -1) -> SpinBox:
	var label = Label.new()
	label.text = comp_name
	
	var spinbox = SpinBox.new()
	spinbox.value = default
	
	if not is_equal_approx(from, to):
		spinbox.min_value = from
		spinbox.max_value = to
	
	var hbox = HBoxContainer.new()
	hbox.add_child(label)
	hbox.add_child(spinbox)
	label.size_flags_horizontal = Label.SIZE_EXPAND_FILL
	label.size_flags_vertical = Label.SIZE_EXPAND_FILL
	spinbox.size_flags_horizontal = Label.SIZE_EXPAND_FILL
	spinbox.size_flags_vertical = Label.SIZE_EXPAND_FILL
	
	_add_child(hbox)
	
	return spinbox



##################################################
# Signals
##################################################

func _on_Button_pressed() -> void:
	hide()
	emit_signal("on_cancel")


func _on_Ok_pressed() -> void:
	emit_signal("on_ok")
	hide()


func _on_Cancel_pressed() -> void:
	hide()
	emit_signal("on_cancel")


