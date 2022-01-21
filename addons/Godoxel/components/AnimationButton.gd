extends Button
tool

signal on_animation_button_pressed()

onready var line_edit = $LineEdit
onready var label = $Label

var press_pos
var release_pos
var moved = false


func _ready():
	line_edit.hide()
	set_process_input(false)


func _input(event: InputEvent):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			line_edit.hide()
			line_edit.text = label.text
	elif event is InputEventMouseButton:
		if line_edit.visible and event.pressed and event.button_index == BUTTON_LEFT:
			line_edit.hide()
			line_edit.text = label.text


func _on_TextButton_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if not event.pressed:
				if !moved:
					if not line_edit.visible:
						line_edit.show()
						line_edit.grab_focus()
						line_edit.grab_click_focus()
						line_edit.caret_position = line_edit.text.length() - 1
					else:
						line_edit.hide()
				elif line_edit.visible:
					line_edit.hide()
			else:
				moved = false
	elif event is InputEventMouseMotion:
		moved = true


func _on_LineEdit_focus_exited():
	label.text = line_edit.text
	if not Rect2(rect_global_position, rect_size).has_point(get_global_mouse_position()):
		line_edit.hide()


func _on_LineEdit_text_entered(new_text: String):
	label.text = new_text
	line_edit.hide()


func _on_AnimationButton_pressed():
	line_edit.hide()
	emit_signal("on_animation_button_pressed")
#	if line_edit.visible:
#		line_edit.hide()
#	else:
#		line_edit.show()
#		line_edit.grab_focus()
#		line_edit.grab_click_focus()


func _on_LineEdit_visibility_changed():
	set_process_input(line_edit.visible)
