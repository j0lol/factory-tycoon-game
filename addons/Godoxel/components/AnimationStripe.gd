extends Panel
tool

signal on_frame_pressed(anim, btn)
signal on_add_frame_pressed(anim, btn)
signal on_animation_pressed(anim)

signal on_move_up_pressed(index)
signal on_move_down_pressed(index)
signal on_moved(form, to)

signal on_animation_duplicated(anim)
signal on_animation_selected(anim)

signal on_deleted(anim)

const FrameButton = preload("res://addons/Godoxel/components/FrameButton.tscn")

const StyleNormal = preload("res://addons/Godoxel/themes/AnimationStripe_Panel_normal.tres")
const StyleDragging = preload("res://addons/Godoxel/themes/AnimationStripe_Panel_dragging.tres")
const StyleDraggable = preload("res://addons/Godoxel/themes/AnimationStripe_Panel_draggable.tres")

onready var frame_button_container = find_node("FrameContainer")
onready var anim_button = find_node("AnimationButton")
var frames = []
var animation: GEAnimation


func _ready():
	set("custom_styles/panel", StyleNormal)


var previous_index = -1
var current_index = -1
var dragging = false
var mouse_offset = Vector2.ZERO
func _input(event):
	if not dragging:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				if not dragging and get_global_rect().has_point(get_global_mouse_position()):
					dragging = true
					set("custom_styles/panel", StyleDragging)
					var mp = get_global_mouse_position()
					mouse_offset = mp - rect_global_position
					emit_signal("on_animation_selected", get_index())
		if event is InputEventMouseMotion:
			if get_global_rect().has_point(get_global_mouse_position()):
				set("custom_styles/panel", StyleDraggable)
			else:
				set("custom_styles/panel", StyleNormal)
		return
	
	if dragging and event is InputEventMouseButton:
		if not event.pressed and event.button_index == BUTTON_LEFT:
			dragging = false
			current_index = -1
			current_index = -1
			mouse_offset = Vector2.ZERO
			get_parent().update()
			return
	
	previous_index = current_index
	
	var mp = get_global_mouse_position().y - get_parent().rect_global_position.y
	var y_index = mp / (rect_size.y + get_parent().get("custom_constants/separation"))
	y_index = clamp(int(y_index), 0, get_parent().get_child_count()-1)
	current_index = y_index
	
	if previous_index != current_index and previous_index != -1:
		emit_signal("on_moved", previous_index, current_index)


func set_animation(animation):
	self.animation = animation


func get_animation_name() -> String:
	return anim_button.label.text


func set_animation_name(anim_name: String):
	anim_button.label.text = anim_name
	anim_button.line_edit.text = anim_name


func get_frame_button(idx):
	return frame_button_container.get_child(idx)


func add_new_frame_button():
	var frame_button = FrameButton.instance()
	frame_button_container.add_child(frame_button)
	frame_button.connect("on_frame_pressed", self, "_on_frame_pressed")
	return frame_button


func add_frame(frame):
	var frame_button = add_new_frame_button()
	frame_button.set_frame(frame)
	return frame_button


func remove_frame(idx):
	var child = frame_button_container.get_child(idx)
	frame_button_container.remove_child(child)
	child.queue_free()


func _on_frame_pressed(frame_btn_index):
	emit_signal("on_frame_pressed", get_index(), frame_btn_index)


func _on_AddFrame_pressed():
	var frame_button = add_new_frame_button()
	emit_signal("on_add_frame_pressed", get_index(), frame_button.get_index())


func _on_AnimationButton_on_animation_button_pressed():
	emit_signal("on_animation_pressed", get_index())


func _on_AnimationButton_pressed():
	pass # Replace with function body.


func _on_Up_pressed():
	emit_signal("on_move_up_pressed", get_index())


func _on_Down_pressed():
	emit_signal("on_move_down_pressed", get_index())


func _on_Duplicate_pressed():
	emit_signal("on_animation_duplicated",  get_index())


func _on_Delete_pressed():
	emit_signal("on_deleted",  get_index())

