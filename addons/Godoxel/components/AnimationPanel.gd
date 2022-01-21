extends Panel
tool

signal on_add_animation()
signal on_frame_pressed(anim, frame_button)
signal on_add_frame_pressed(anim, frame_button)
signal on_animation_pressed(anim)

signal on_play_pause_pressed()
signal on_animation_frame_rate_changed(new_frame_rate)
signal on_animation_loop_toggled()

signal on_animation_move(from, to)
signal on_animation_duplicated(anim)

signal on_animation_selected(anim)
signal on_animation_deleted(anim)


const AnimationStripe = preload("res://addons/Godoxel/components/AnimationStripe.tscn")

onready var anim_button_container = find_node("AnimationButtons")
onready var play_pause_button = find_node("PlayPause")
onready var add_animation_button = find_node("AddAnimation") # for dragging


func _ready():
	pass


func _on_moved(from, to):
	if from > to:
		_move_animation_up(from, to)
	elif from != to:
		_move_animation_up(from, to)
	anim_button_container.queue_sort()


func _move_animation_up(anim_idx, pos):
	anim_button_container.move_child(anim_button_container.get_child(anim_idx), pos)
	emit_signal("on_animation_move", anim_idx, pos)


func move_animation_up(anim_idx):
	var pos = max(anim_idx - 1, 0)
	anim_button_container.move_child(anim_button_container.get_child(anim_idx), pos)
	emit_signal("on_animation_move", anim_idx, pos)


func move_animation_down(anim_idx):
	var pos = min(anim_idx + 1, anim_button_container.get_child_count() - 1)
	anim_button_container.move_child(anim_button_container.get_child(anim_idx), pos)
	emit_signal("on_animation_move", anim_idx, pos)


func clear_all():
	for anim_button in anim_button_container.get_children():
		anim_button_container.remove_child(anim_button)
		anim_button.queue_free()


func update_all_frame_button_previews():
	for anim_stripe in anim_button_container.get_children():
		for frame_button in anim_stripe.frame_button_container.get_children():
			for layer in frame_button.frame.layers:
				layer.update_texture()
			frame_button.update_preview()


func set_frame_preview(anim_idx, frame_idx, frame):
	if anim_button_container.get_child(anim_idx).get_frame_button(frame_idx):
		anim_button_container.get_child(anim_idx).get_frame_button(frame_idx).set_frame(frame)


func get_frame_button(anim_idx, frame_idx):
	return anim_button_container.get_child(anim_idx).get_frame_button(frame_idx)


func get_animation_stripe(anim_idx):
	return anim_button_container.get_child(anim_idx)


func get_last_animation_stripe():
	return get_animation_stripe(anim_button_container.get_child_count()-1)


func _on_AddAnimation_pressed():
	emit_signal("on_add_animation")


func add_animation_stripe():
	var anim_stripe = AnimationStripe.instance()
	anim_button_container.add_child(anim_stripe)
	anim_stripe.connect("on_frame_pressed", self, "_on_frame_pressed")
	anim_stripe.connect("on_add_frame_pressed", self, "_on_add_frame_pressed")
	anim_stripe.connect("on_animation_pressed", self, "_on_animation_pressed")
	anim_stripe.connect("on_move_down_pressed", self, "move_animation_down")
	anim_stripe.connect("on_move_up_pressed", self, "move_animation_up")
	anim_stripe.connect("on_moved", self, "_on_moved")
	anim_stripe.connect("on_animation_duplicated", self, "_on_animation_duplicated")
	anim_stripe.connect("on_animation_selected", self, "_on_animation_selected")
	anim_stripe.connect("on_deleted", self, "_on_deleted")
	
	anim_stripe.add_new_frame_button()
	
	return anim_stripe


func _on_animation_pressed(anim_idx):
	emit_signal("on_animation_pressed", anim_idx)


func _on_add_frame_pressed(anim, frame_button):
	emit_signal("on_add_frame_pressed", anim, frame_button)


func _on_frame_pressed(anim, frame_button):
	emit_signal("on_frame_pressed", anim, frame_button)


func get_animation_container():
	return anim_button_container


func set_play_pause_button(playing: bool):
	if playing:
		play_pause_button.text = "Pause"
	else: 
		play_pause_button.text = "Play"


func _on_PlayPause_pressed():
	if play_pause_button.text == "Play":
		play_pause_button.text = "Pause"
	else: 
		play_pause_button.text = "Play"
	emit_signal("on_play_pause_pressed")


func _on_FrameRate_value_changed(value):
	emit_signal("on_animation_frame_rate_changed", value)


func _on_ToggleAnimationLoop_pressed():
	emit_signal("on_animation_loop_toggled")


func _on_animation_duplicated(anim):
	emit_signal("on_animation_duplicated", anim)


func _on_animation_selected(anim):
	emit_signal("on_animation_selected", anim)


func _on_deleted(anim):
	emit_signal("on_animation_deleted", anim)
