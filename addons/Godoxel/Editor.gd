tool
extends Control

enum Tools {
	PAINT,
	BRUSH,
	BUCKET,
	RAINBOW,
	LINE,
	RECT,
	DARKEN,
	BRIGHTEN
	COLORPICKER,
	CUT,
	PASTECUT,
}

var shortcuts = {
	KEY_CONTROL: {
		KEY_Z: "undo_action",
		KEY_Y: "redo_action",
	},
	KEY_SHIFT: {
		KEY_Q: Tools.PAINT,
		KEY_W: Tools.BUCKET,
		KEY_E: Tools.RAINBOW,
		
		KEY_A: Tools.LINE,
		KEY_S: Tools.RECT,
		KEY_D: Tools.COLORPICKER,
		
		KEY_Z: Tools.BRIGHTEN,
		KEY_X: Tools.DARKEN,
		KEY_C: Tools.CUT,
	},
	KEY_Z: "undo_action",
	KEY_Y: "redo_action",
}

const LayerButton = preload("res://addons/Godoxel/LayerButton.tscn")

onready var right_panel: Panel = find_node("RightPanel")
onready var left_panel: Panel = find_node("LeftPanel")
onready var layer_buttons: Control = find_node("LayerButtons")
onready var paint_canvas_container_node = find_node("PaintCanvasContainer")
onready var paint_canvas: GECanvas = find_node("Canvas")
onready var canvas_background: TextureRect = find_node("CanvasBackground")
onready var colors_grid = find_node("Colors")
onready var debug_text = find_node("DebugTextDisplay")
onready var preview_window: Control = find_node("PreviewWindow")
onready var preview_layer_textures = find_node("PreviewLayerTextures")
onready var shift_shortcut_window = find_node("ShortcutWindow")
onready var frame_selection_container = find_node("FrameSelectionContainer")
onready var anim_panel = find_node("AnimationPanel")
onready var color_picker_button = find_node("ColorPicker")

var allow_drawing = true
var selected_color = Color(1, 1, 1, 1) setget set_selected_color
var util = preload("res://addons/Godoxel/Util.gd")

var mouse_in_region = false
var mouse_on_top = false

var _preview_drag_start_pos = null
var _preview_drag_pos = null

var _middle_mouse_pressed_pos = null
var _middle_mouse_pressed_start_pos = null
var _previous_tool
var brush_mode

var _layer_button_ref = {}

var _total_added_layers = 0

var selected_brush_prefab = 0
var _last_drawn_pixel = Vector2.ZERO
var _last_preview_draw_cell_pos = Vector2.ZERO

var _selection_cells = []
var _selection_colors = []

var _cut_pos = Vector2.ZERO
var _cut_size = Vector2.ZERO

var _actions_history = [] # for undo
var _redo_history = []
var _current_action

var _last_mouse_pos_canvas_area = Vector2.ZERO

var _picked_color = false

var mouse_position = Vector2()
var canvas_position = Vector2()
var canvas_mouse_position = Vector2()
var cell_mouse_position = Vector2()
var cell_color = Color()

var last_mouse_position = Vector2()
var last_canvas_position = Vector2()
var last_canvas_mouse_position = Vector2()
var last_cell_mouse_position = Vector2()
var last_cell_color = Color()

const current_layer_highlight = Color(0.354706, 0.497302, 0.769531)
const other_layer_highlight = Color(0.180392, 0.176471, 0.176471)
const locked_layer_highlight = Color(0.098039, 0.094118, 0.094118)

var big_grid_pixels = 4 # 1 grid-box is big_grid_pixels big

var _preview_scale := 1.0

var animations = []
var current_animation_idx = 0
var current_animation: GEAnimation
var current_frame_idx = 0
var current_frame: GEFrame
var current_layer_idx = 0

var animation_looped := true
var animation_playing := false
var animation_fps = 5.0
var next_anim_time = 0.0
var animation_frame_duration: float = 1 / animation_fps

var preview_thread = Thread.new()


func _ready():
	#--------------------
	#Setup nodes
	#--------------------
	selected_color = color_picker_button.color
	_center_element(paint_canvas)
	
	#--------------------
	#connect nodes
	#--------------------
	if not anim_panel.is_connected("on_add_animation", self, "_on_add_animation"):
		anim_panel.connect("on_add_animation", self, "_on_add_animation")
		anim_panel.connect("on_add_frame_pressed", self, "_on_add_frame_pressed")
		anim_panel.connect("on_frame_pressed", self, "_on_frame_pressed")
		anim_panel.connect("on_animation_pressed", self, "_on_animation_pressed")
		anim_panel.connect("on_animation_move", self, "_on_animation_move")
		anim_panel.connect("on_animation_duplicated", self, "_on_animation_duplicated")
		anim_panel.connect("on_animation_selected", self, "_on_animation_selected")
		anim_panel.connect("on_animation_deleted", self, "_on_animation_deleted")
		
	
	if not colors_grid.is_connected("color_change_request", self, "change_color"):
		colors_grid.connect("color_change_request", self, "change_color")
	
	if not is_connected("visibility_changed", self, "_on_Editor_visibility_changed"):
		connect("visibility_changed", self, "_on_Editor_visibility_changed")
	
	canvas_background.material.set_shader_param(
			"pixel_size", 8 * pow(0.5, big_grid_pixels)/paint_canvas.pixel_size)
	
	# ready
	set_tool(Tools.PAINT)
	
	find_node("BrushSizeLabel").text = str(int(find_node("BrushSize").value))
	
	paint_canvas.update()
	
	shift_shortcut_window.setup(shortcuts[KEY_SHIFT])
	
	#--------------------	
	# animation
	#--------------------
	current_animation = add_new_animation()
	current_frame = add_new_frame(current_animation)
	paint_canvas.set_frame(current_frame)
	add_new_layer()
	
#	var animation = GEAnimation.new()
#	animations.append(animation)
#
#	var frame = GEFrame.new()
#	frame.resize(paint_canvas.canvas_width, paint_canvas.canvas_height)
#	animation.add_frame(frame)
#	var layer = frame.add_new_layer(layer_buttons.get_child(0).name)
#
#	anim_panel.set_frame_preview(animations.size()-1, 0, frame)
#
#	var anim = _on_add_animation(anim_panel.add_animation_stripe())
	
	# data
#	var frame = paint_canvas.frame
#	var anim = GEAnimation.new()
#	anim.add_frame(frame)
#	animations.append(anim)
#
#	# ui
#	var anim_stripe = anim_panel.add_animation_stripe()
#	anim_stripe.connect("on_frame_pressed", self, "_on_frame_pressed")
#
#	# data -> ui
#	anim_stripe.set_animation(anim)
#	#anim_stripe.add_frame(frame)
#	#anim_panel._on_add_frame_pressed(0, 0) #ugly
	
	#--------------------
	# animation
	#--------------------
	preview_window.update_preview(current_frame)
	anim_panel.set_frame_preview(current_animation_idx, current_frame_idx, current_frame)
	
	set_process(true)
	
	# start thread
#	preview_thread.start(self, "_update_frame_preview")


#func _update_frame_preview(data):
#	while true:
#		print("update preview")
#		current_frame._update_preview()
#		yield(get_tree().create_timer(2.0), "timeout")


func _exit_tree():
	if preview_thread != null and preview_thread.is_active():
		preview_thread.wait_to_finish()


func _input(event: InputEvent) -> void:
	if is_any_menu_open():
		return
	if not is_visible_in_tree():
		return
	if paint_canvas_container_node == null or paint_canvas == null:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and not event.is_echo():
			if is_mouse_in_preview_window():
				_preview_drag_start_pos = preview_layer_textures.get_child(0).rect_position
				_preview_drag_pos = get_global_mouse_position()
			elif is_mouse_in_canvas():
				_middle_mouse_pressed_start_pos = paint_canvas.rect_position
				_middle_mouse_pressed_pos = get_global_mouse_position()
	
	_handle_zoom(event)
	
	if paint_canvas.is_active_layer_locked():
		return
	
	_handle_paint(event)


func _unhandled_input(event:InputEvent):
	if is_any_menu_open():
		return
	if not is_visible_in_tree():
		return
	if paint_canvas_container_node == null or paint_canvas == null:
		return
	
	_handle_shortcuts(event)


func _handle_paint(event: InputEvent):
	if brush_mode == Tools.CUT:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				if not event.pressed:
					commit_action()
	
	if is_mouse_in_canvas():
		if event is InputEventMouseButton:
			match brush_mode:
				Tools.BUCKET:
					if event.button_index == BUTTON_LEFT:
						if event.pressed:
							if _current_action == null:
								_current_action = get_action()
							do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
					
				Tools.COLORPICKER:
					if event.button_index == BUTTON_LEFT:
						if event.pressed:
							if paint_canvas.get_pixel(cell_mouse_position.x, cell_mouse_position.y).a == 0:
								return
							selected_color = paint_canvas.get_pixel(cell_mouse_position.x, cell_mouse_position.y)
							_picked_color = true
							find_node("Colors").add_color_prefab(selected_color)
							color_picker_button.color = selected_color
						elif _picked_color:
							set_tool(_previous_tool)
					elif event.button_index == BUTTON_RIGHT:
						if event.pressed:
							set_tool(_previous_tool)
						
				Tools.PASTECUT:
					if event.button_index == BUTTON_RIGHT:
						if event.pressed:
							commit_action()
							set_tool(Tools.PAINT)


func _process(delta):
	if not is_visible_in_tree():
		return
	if paint_canvas_container_node == null or paint_canvas == null:
		return
	
	_handle_scroll()
	
	if is_any_menu_open():
		return
	
	#Update commonly used variables
	var grid_size = paint_canvas.pixel_size
	mouse_position = get_global_mouse_position() #paint_canvas.get_local_mouse_position()
	canvas_position = paint_canvas.rect_global_position
	canvas_mouse_position = Vector2(mouse_position.x - canvas_position.x, mouse_position.y - canvas_position.y)
	if is_mouse_in_canvas():
		cell_mouse_position = Vector2(
				floor(canvas_mouse_position.x / grid_size),
				floor(canvas_mouse_position.y / grid_size))
		cell_color = paint_canvas.get_pixel(cell_mouse_position.x, cell_mouse_position.y)
	update_text_info()
	
	if animation_playing:
		next_anim_time += delta
		if next_anim_time >= animation_frame_duration:
			next_anim_time = 0
			current_frame_idx += 1
			if current_frame_idx >= current_animation.frames.size():
				current_frame_idx = 0
				if not animation_looped:
					animation_playing = false
					anim_panel.set_play_pause_button(animation_playing)
			_on_frame_pressed(current_animation_idx, current_frame_idx)
	else:
		if is_mouse_in_canvas():
			if not paint_canvas.is_active_layer_locked():
				if is_position_in_canvas(get_global_mouse_position()) or \
						is_position_in_canvas(_last_mouse_pos_canvas_area):
					
					brush_process()
				else:
					print(cell_mouse_position, " not in ", paint_canvas_container_node.rect_size)
					print("not in canvas")
			
			_draw_tool_brush()
	
	#Update last variables with the current variables
	last_mouse_position = mouse_position
	last_canvas_position = canvas_position
	last_canvas_mouse_position = canvas_mouse_position
	last_cell_mouse_position = cell_mouse_position
	last_cell_color = cell_color
	_last_mouse_pos_canvas_area = get_global_mouse_position() 
	#paint_canvas_container_node.get_local_mouse_position()


var ctrl_pressed = false
var shift_pressed = false
func _handle_shortcuts(event: InputEvent):
	if not event is InputEventKey:
		return
	
	# check modifiers
	if event.scancode == KEY_SHIFT:
		shift_pressed = event.pressed
		shift_shortcut_window.visible = shift_pressed
	elif event.scancode == KEY_CONTROL:
		ctrl_pressed = event.pressed
	
	if not event.pressed:
		return
	
	# delegate shortcuts depending on modifiers
	if shift_pressed:
		if shortcuts[KEY_SHIFT].has(event.scancode):
			if shift_shortcut_window.check_input_for_shorcut(event, event.shift):
				if shortcuts[KEY_SHIFT].has(event.scancode):
					_handle_shortcut(shortcuts[KEY_SHIFT][event.scancode])
			accept_event()
			return
	elif ctrl_pressed:
		if shortcuts[KEY_CONTROL].has(event.scancode):
			_handle_shortcut(shortcuts[KEY_CONTROL][event.scancode])
			accept_event()
			return
	elif shortcuts.has(event.scancode):
			accept_event()
			_handle_shortcut(shortcuts[event.scancode])
			return


func _handle_shortcut(shortcut):
	if typeof(shortcut) == TYPE_STRING:
		call(shortcut)
	else:
		set_tool(shortcut)


func _draw_tool_brush():
	paint_canvas.tool_layer.clear()
	
	match brush_mode:
		Tools.PASTECUT:
			for idx in range(_selection_cells.size()):
				var pixel = _selection_cells[idx]
#				if pixel.x < 0 or pixel.y < 0:
#					print(pixel)
				var color = _selection_colors[idx]
				pixel -= _cut_pos + _cut_size / 2
				pixel += cell_mouse_position
				paint_canvas._set_pixel_v(paint_canvas.tool_layer, pixel, color)
		Tools.BRUSH:
			var pixels = BrushPrefabs.get_brush(selected_brush_prefab, find_node("BrushSize").value)
			for pixel in pixels:
				
				paint_canvas._set_pixel(paint_canvas.tool_layer,
						cell_mouse_position.x + pixel.x, cell_mouse_position.y + pixel.y, selected_color)
		
		Tools.RAINBOW:
			paint_canvas._set_pixel(paint_canvas.tool_layer,
					cell_mouse_position.x, cell_mouse_position.y, Color(0.46875, 0.446777, 0.446777, 0.196078))
		
		Tools.COLORPICKER:
			paint_canvas._set_pixel(paint_canvas.tool_layer,
					cell_mouse_position.x, cell_mouse_position.y, Color(0.866667, 0.847059, 0.847059, 0.196078))
		_:
			paint_canvas._set_pixel(paint_canvas.tool_layer,
					cell_mouse_position.x, cell_mouse_position.y, selected_color)
	
	paint_canvas.update()
	#TODO add here brush prefab drawing
	paint_canvas.tool_layer.update_texture()



############################################
# Animation Panel
############################################

var change_grid = true
func _on_AnimationPanel_on_play_pause_pressed():
	animation_playing = not animation_playing
	
	if animation_playing and not paint_canvas.grid.visible:
		change_grid = false
	
	if change_grid:
		if animation_playing:
			paint_canvas.hide_grid()
		elif not paint_canvas.grid.visible:
			paint_canvas.show_grid()


func _on_AnimationPanel_on_animation_loop_toggled():
	animation_looped = not animation_looped


func _on_AnimationPanel_on_animation_frame_rate_changed(new_frame_rate):
	animation_fps = new_frame_rate
	animation_frame_duration = 1.0 / animation_fps



############################################
# Frames
############################################

func _create_new_frame():
	var frame = GEFrame.new()
	frame.resize(paint_canvas.canvas_width, paint_canvas.canvas_height)
	
	for idx in range(get_layer_count()):
		var layer = _create_layer(get_layer_name(idx), frame.width, frame.height)
		frame.add_frame_layer(layer)
	
	return frame


func add_new_frame(animation):
	var frame = _create_new_frame()
	animation.add_frame(frame)
	
	anim_panel.set_frame_preview(current_animation_idx, current_frame_idx, frame)
	_update_anim_and_frame_idx(current_animation_idx, current_frame_idx)
	
	return frame


func duplicate_frame():
	pass


func copy_current_frame_to_all_frames():
	pass


func _on_frame_pressed(anim_idx, frame_idx):
	_update_anim_and_frame_idx(anim_idx, frame_idx)
	paint_canvas.set_frame(current_frame)
	preview_window.update_preview(current_frame)


func _on_add_frame_pressed(anim_idx, frame_idx):
	current_animation_idx = anim_idx
	current_frame_idx = frame_idx
	add_new_frame(animations[anim_idx])


func _update_anim_and_frame_idx(anim_idx, frame_idx):
	current_animation_idx = anim_idx
	current_animation = animations[current_animation_idx]
	current_frame_idx = min(frame_idx, animations[current_animation_idx].frames.size() - 1)
	current_frame = animations[current_animation_idx].frames[current_frame_idx]



############################################
# Animations
############################################

func _on_add_animation():
	var animation = add_new_animation()
	add_new_frame_to_animation(animation)
	return animation


func add_new_frame_to_animation(animation: GEAnimation):
	var frame = _create_new_frame()
	animation.add_frame(frame)
	
	anim_panel.set_frame_preview(animation.get_anim_index(), animation.frames.size()-1, frame)
	
	return frame


func add_new_animation():
	var animation = GEAnimation.new()
	animation.set_anim_index(animations.size())
	animations.append(animation)
	
	anim_panel.add_animation_stripe()
	return animation


func add_animation():
	var animation = GEAnimation.new()
	animations.append(animation)
	
	var frame = GEFrame.new()
	frame.resize(paint_canvas.canvas_width, paint_canvas.canvas_height)
	animation.add_frame(frame)
	
	for idx in range(preview_layer_textures.get_child_count()):
		frame.add_new_layer(layer_buttons.get_child(idx).name)
	
	anim_panel.set_frame_preview(animations.size()-1, 0, frame)
	return animation


func _on_animation_pressed(anim_idx):
	current_animation_idx = anim_idx
	_update_anim_and_frame_idx(current_animation_idx, current_frame_idx)
	paint_canvas.set_frame(current_frame)
	preview_window.update_preview(current_frame)


func _on_animation_selected(anim_idx):
	current_animation_idx = anim_idx
	_update_anim_and_frame_idx(current_animation_idx, current_frame_idx)
	paint_canvas.set_frame(current_frame)
	preview_window.update_preview(current_frame)


func _on_animation_deleted(anim_idx):
	if animations.size() <= 1:
		return
	animations.remove(anim_idx)
	var anim_stripe = anim_panel.anim_button_container.get_child(anim_idx)
	anim_panel.anim_button_container.remove_child(anim_stripe)
	anim_stripe.queue_free()
	
	if current_animation_idx >= anim_idx:
		current_animation_idx -= 1
	_update_anim_and_frame_idx(current_animation_idx, current_frame_idx)


func _on_animation_duplicated(anim_idx):
	var anim = add_new_animation()
		
	for i in range(animations[anim_idx].frames.size()):
		if i > 0:
			anim_panel.get_last_animation_stripe().add_new_frame_button()
		var frame = add_new_frame_to_animation(anim)
		
		frame.width = animations[anim_idx].frames[i].width
		frame.height = animations[anim_idx].frames[i].height
	
	for frame_idx in range(anim.frames.size()):
		for layer_idx in range(anim.frames[frame_idx].layers.size()):
			var layer = animations[anim_idx].frames[frame_idx].layers[layer_idx]
			var dup_layer = anim.frames[frame_idx].layers[layer_idx]
			dup_layer.image.copy_from(layer.image)
			dup_layer.update_texture()


func _on_animation_move(from, to):
	var anim = animations[to]
	animations[to] = animations[from]
	animations[from] = anim
	
	if current_animation_idx == from:
		current_animation_idx = to
		_update_anim_and_frame_idx(current_animation_idx, current_frame_idx)
	elif current_animation_idx == to:
		current_animation_idx = from
		_update_anim_and_frame_idx(current_animation_idx, current_frame_idx)



############################################
# Save/Load
############################################

func get_save_project_data():
	var data = {}
	data["canvas"] = {
		"width": paint_canvas.canvas_width,
		"height": paint_canvas.canvas_height,
	}
	data["animations"] = {}
	var anim_idx = 0
	for anim in animations:
		data["animations"][anim_idx] = {
			"name": anim_panel.get_animation_stripe(anim_idx).get_animation_name(),
			"frames": {}
		}
		
		var frame_idx = 0
		for frame in anim.frames:
			data["animations"][anim_idx]["frames"][frame_idx] = {
				"layers": {}
			}
			
			var layer_idx = 0
			for layer in frame.layers:
				data["animations"][anim_idx]["frames"][frame_idx]["layers"][layer_idx] = {}
				data["animations"][anim_idx]["frames"][frame_idx]["layers"][layer_idx] = {
					"name": str(anim_idx) + " - "+ str(frame_idx) + " - " + str(layer_idx),
					"image_data": Array(layer.image.save_png_to_buffer())
				}
				layer_idx += 1
			frame.layers
			frame_idx += 1
		anim_idx += 1
	return data


func load_project(data):
	resize(data.canvas.width, data.canvas.height)
	
	var layer_amount = 0
	var anim_amount = 0
	var frame_amounts = []
	for anim in data.animations:
		var frame_amount = 0
		for frame in data.animations[anim].frames:
			layer_amount = 0
			for layer in data.animations[anim].frames[frame].layers:
				layer_amount += 1
			frame_amount += 1
		frame_amounts.append(frame_amount)
		anim_amount += 1
	
	print("Loading...")
	print("Animations: ", anim_amount)
	print("Frames: ", frame_amounts)
	print("Layers: ", layer_amount)
	
	reset_project()
	current_animation_idx = 0 
	current_frame_idx = 0 
	
	for i in range(layer_amount):
		add_new_layer()
	
	for anim_key in data.animations:
		var frames_data = data.animations[anim_key].frames
		var anim = add_new_animation()
		var anim_stripe = anim_panel.get_last_animation_stripe()
		if "name" in data.animations[anim_key]:
			anim_stripe.set_animation_name(data.animations[anim_key].name)
		for frame_key in frames_data:
			if current_frame_idx > 0:
				anim_stripe.add_new_frame_button()
			var frame = add_new_frame_to_animation(anim)
			var layer_data = frames_data[frame_key].layers
			for layer_key in layer_data:
				var new_img = layer_data[layer_key]
				var img_data = Array(new_img.image_data)
				frame.layers[int(layer_key)].image.load_png_from_buffer(img_data)
				frame.layers[int(layer_key)].update_texture()
			current_frame_idx += 1
		current_frame_idx = 0 
		current_animation_idx += 1
	
	for anim_idx in range(animations.size()):
		if current_animation == null and not animations[anim_idx].frames.empty():
			current_animation = animations[anim_idx]
			current_animation_idx = anim_idx
			current_frame_idx = 0
			current_frame = animations[anim_idx].frames[current_frame_idx]
	
	if get_layer_count() <= 0:
		add_new_layer()
	
	current_layer_idx = 0
	paint_canvas.set_frame(current_frame)
	preview_window.update_preview(current_frame)


func reset_project():
	anim_panel.clear_all()
	for layer_button in layer_buttons.get_children():
		layer_buttons.remove_child(layer_button)
		layer_button.queue_free()
	animations.clear()
	_total_added_layers = 0
	for preview_texture in preview_layer_textures.get_children():
		preview_layer_textures.remove_child(preview_texture)
		preview_texture.queue_free()
	paint_canvas.frame = null
	paint_canvas.update()
	
	current_animation = null
	current_frame = null
	current_layer_idx = -1
	current_frame_idx = -1
	current_animation_idx = -1


func delete_current_animation():
	delete_animation(current_animation_idx)


func delete_animation(anim_idx):
	animations.remove(anim_idx)


func delete_current_frame():
	delete_frame(current_animation_idx, current_frame_idx)


func delete_frame(anim_idx, frame_idx):
	if animations[anim_idx].frames.size() <= 1:
		return
	animations[anim_idx].frames.remove(frame_idx)
	anim_panel.get_last_animation_stripe().remove_frame(frame_idx)
	
	if current_frame_idx >= frame_idx:
		current_frame_idx -= 1
	
	_update_anim_and_frame_idx(current_animation_idx, current_frame_idx)
	paint_canvas.set_frame(current_frame)
	preview_window.update_preview(current_frame)


#######################################################
# Zoom & Scroll
#######################################################

func _handle_scroll():
	if is_mouse_in_preview_window():
		_handle_preview_scroll()
	elif control_has_point(anim_panel, get_global_mouse_position()):
		pass
	elif control_has_point(self, get_global_mouse_position()):
		_handle_canvas_scroll()


func _handle_preview_scroll():
	if is_preview_dragging():
		if Input.is_mouse_button_pressed(BUTTON_MIDDLE):
			if not is_preview_dragging():
				return
			for child in preview_layer_textures.get_children():
				child.rect_position = _preview_drag_start_pos
				child.rect_position += get_global_mouse_position() - _preview_drag_pos
		elif is_preview_dragging():
			_preview_drag_start_pos = null


func _handle_canvas_scroll():
	if is_dragging():
		if Input.is_mouse_button_pressed(BUTTON_MIDDLE):
			if not is_dragging():
				return
			paint_canvas.rect_position = _middle_mouse_pressed_start_pos
			paint_canvas.rect_position += get_global_mouse_position() - _middle_mouse_pressed_pos
			if paint_canvas.rect_position.y < -paint_canvas.rect_size.y:
				paint_canvas.rect_position.y = -paint_canvas.rect_size.y
			if paint_canvas.rect_position.x < -paint_canvas.rect_size.x:
				paint_canvas.rect_position.x = -paint_canvas.rect_size.x
				
			if paint_canvas.rect_position.x > rect_global_position.x + rect_size.x:
				paint_canvas.rect_position.x = rect_global_position.x + rect_size.x
			
			if paint_canvas.rect_position.y > rect_global_position.y + rect_size.y:
				paint_canvas.rect_position.y = rect_global_position.y + rect_size.y
			
			
		elif is_dragging():
			_middle_mouse_pressed_start_pos = null


func is_dragging() -> bool:
	return _middle_mouse_pressed_start_pos != null


func is_preview_dragging() -> bool:
	return _preview_drag_start_pos != null


const max_zoom_out = 0.25
const max_zoom_in = 50

func _handle_zoom(event):
	if not event is InputEventMouseButton:
		return
	if is_mouse_in_preview_window():
		_handle_preview_zoom(event)
	elif control_has_point(anim_panel, get_global_mouse_position()):
		pass
	elif is_mouse_in_canvas():
		_handle_canvas_zoom(event)


func _handle_preview_zoom(event: InputEvent):
	if event.is_pressed():
		if event.button_index == BUTTON_WHEEL_UP:
			set_preview_scale(_preview_scale * 2)
			_update_preview_layers_size()
			for child in preview_layer_textures.get_children():
				child.rect_position -= child.get_local_mouse_position()
				child.rect_position.x = clamp(child.rect_position.x, 
					-child.rect_size.x * 0.8, 
					rect_size.x)
				child.rect_position.y = clamp(child.rect_position.y, 
					-child.rect_size.y * 0.8, 
					rect_size.y)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			set_preview_scale(_preview_scale / 2)
			_update_preview_layers_size()
			for child in preview_layer_textures.get_children():
				child.rect_position += child.get_local_mouse_position()
				child.rect_position.x = clamp(child.rect_position.x, 
					-child.rect_size.x * 0.8, 
					rect_size.x)
				child.rect_position.y = clamp(child.rect_position.y, 
					-child.rect_size.y * 0.8, 
					rect_size.y)


func _handle_canvas_zoom(event: InputEvent):
	if event.is_pressed():
		if event.button_index == BUTTON_WHEEL_UP:
			var px = min(paint_canvas.pixel_size * 2, max_zoom_in)
			if px == paint_canvas.pixel_size:
				return
			paint_canvas.set_pixel_size(px)
			find_node("CanvasBackground").material.set_shader_param(
					"pixel_size", 8 * pow(0.5, big_grid_pixels)/paint_canvas.pixel_size)
			paint_canvas.rect_position -= paint_canvas.get_local_mouse_position()
			paint_canvas.rect_position.x = clamp(paint_canvas.rect_position.x, 
					-paint_canvas.rect_size.x * 0.8, 
					rect_size.x)
			paint_canvas.rect_position.y = clamp(paint_canvas.rect_position.y, 
					-paint_canvas.rect_size.y * 0.8, 
					rect_size.y)
					
		elif event.button_index == BUTTON_WHEEL_DOWN:
			var px = max(paint_canvas.pixel_size / 2.0, max_zoom_out)
			if px == paint_canvas.pixel_size:
				return
			paint_canvas.set_pixel_size(px)
			find_node("CanvasBackground").material.set_shader_param(
					# 4 2 1
					"pixel_size", 8 * pow(0.5, big_grid_pixels)/paint_canvas.pixel_size)
			paint_canvas.rect_position += paint_canvas.get_local_mouse_position() / 2
			paint_canvas.rect_position.x = clamp(paint_canvas.rect_position.x, 
					-paint_canvas.rect_size.x * 0.8, 
					rect_size.x)
			paint_canvas.rect_position.y = clamp(paint_canvas.rect_position.y, 
					-paint_canvas.rect_size.y * 0.8, 
					rect_size.y)


func _handle_cut():
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		paint_canvas.clear_preview_layer()
		set_tool(_previous_tool)
		return
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		for pixel_pos in GEUtils.get_pixels_in_line(cell_mouse_position, last_cell_mouse_position):
			for idx in range(_selection_cells.size()):
				var pixel = _selection_cells[idx]
				var color = _selection_colors[idx]
				pixel -= _cut_pos + _cut_size / 2
				pixel += pixel_pos
				paint_canvas.set_pixel_v(pixel, color)
	else:
		if _last_preview_draw_cell_pos == cell_mouse_position:
			return
		paint_canvas.clear_preview_layer()
		for idx in range(_selection_cells.size()):
			var pixel = _selection_cells[idx]
			var color = _selection_colors[idx]
			pixel -= _cut_pos + _cut_size / 2
			pixel += cell_mouse_position
			paint_canvas.set_preview_pixel_v(pixel, color)
		_last_preview_draw_cell_pos = cell_mouse_position


func brush_process():
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		if _current_action == null:
			_current_action = get_action()
		if brush_mode == Tools.COLORPICKER:
			_current_action = null
		#TODO only draw if cell != last cell pos AND! already drawn
		#		-> last_drawn_at .. 
#		if cell_mouse_position == last_cell_mouse_position:
#			return
		
		
		match brush_mode:
			Tools.PAINT:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.BRUSH:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color,
						selected_brush_prefab, find_node("BrushSize").value])
			Tools.LINE:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.RECT:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.DARKEN:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.BRIGHTEN:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.COLORPICKER:
				pass
			Tools.CUT:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.PASTECUT:
				do_action([cell_mouse_position, last_cell_mouse_position,
						_selection_cells, _selection_colors,
						_cut_pos, _cut_size])
			Tools.RAINBOW:
				do_action([cell_mouse_position, last_cell_mouse_position])
		paint_canvas.update()
		if current_frame:
			current_frame.preview_dirty = true
	
	elif Input.is_mouse_button_pressed(BUTTON_RIGHT):
		paint_canvas.update()
		if _current_action == null:
			_current_action = get_action()
		
		match brush_mode:
			Tools.PAINT:
				do_action([cell_mouse_position, last_cell_mouse_position, Color.transparent])
			Tools.BRUSH:
				do_action([cell_mouse_position, last_cell_mouse_position, Color.transparent,
						selected_brush_prefab, find_node("BrushSize").value])
		current_frame.preview_dirty = true
		
	else:
		if _current_action and _current_action.can_commit():
			commit_action()
			paint_canvas.update()
			if current_frame:
				current_frame.preview_dirty = true
	paint_canvas.active_layer.update_texture()


func update_text_info():
	var text = ""
	
	var cell_color_text = cell_color
	cell_color_text = Color(0, 0, 0, 0)
	
	text += \
	str("FPS %s\t" + \
	"Mouse Position %s\t" + \
	"Canvas Mouse Position %s \t" + \
	"Canvas Position %s\t\n" + \
	"Cell Position %s \t" + \
	"Cell Color %s\t" + \
	"inside canvas %s\t") % [
		str(Engine.get_frames_per_second()),
		str(mouse_position),
		str(canvas_mouse_position),
		str(canvas_position),
		str(cell_mouse_position),
		str(cell_color_text),
		str(is_mouse_in_canvas())
	]
	
	
	debug_text.display_text(text)


func _on_Save_pressed():
	get_node("SaveFileDialog").show()



##################################################
# Actions
##################################################

func do_action(data: Array):
	if _current_action == null:
		#print("clear redo")
		_redo_history.clear()
	_current_action.do_action(paint_canvas, data)


func commit_action():
	if not _current_action:
		return
	
	var commit_data = _current_action.commit_action(paint_canvas)
	var action = get_action()
	action.action_data = _current_action.action_data.duplicate(true)
	_actions_history.push_back(action)
	_redo_history.clear()
	
	match brush_mode:
		Tools.CUT:
			_cut_pos = _current_action.mouse_start_pos
			_cut_size = _current_action.mouse_end_pos - _current_action.mouse_start_pos
			_selection_cells = _current_action.action_data.redo.cells.duplicate()
			_selection_colors = _current_action.action_data.redo.colors.duplicate()
			set_tool(Tools.PASTECUT)
		_:
			_current_action = null


func redo_action():
	if _redo_history.empty():
		print("Godoxel: Nothing to redo.")
		return
	var action = _redo_history.pop_back()
	if not action:
		return
	_actions_history.append(action)
	action.redo_action(paint_canvas)
	paint_canvas.update()
	print("Godoxel: redo.")


func undo_action():
	var action = _actions_history.pop_back()
	if not action:
		print("Godoxel: Nothing to undo.")
		return
	_redo_history.append(action)
	action.undo_action(paint_canvas)
	update()
	paint_canvas.update()
	print("Godoxel: undo.")


func get_action():
	match brush_mode:
		Tools.PAINT:
			return GEPencil.new()
		Tools.BRUSH:
			return GEBrush.new()
		Tools.LINE:
			return GELine.new()
		Tools.RAINBOW:
			return GERainbow.new()
		Tools.BUCKET:
			return GEBucket.new()
		Tools.RECT:
			return GERect.new()
		Tools.DARKEN:
			return GEDarken.new()
		Tools.BRIGHTEN:
			return GEBrighten.new()
		Tools.CUT:
			return GECut.new()
		Tools.PASTECUT:
			return GEPasteCut.new()
		_:
			#print("no tool!")
			return null



############################################
# Brushes
############################################

func set_selected_color(color):
	selected_color = color


func set_tool(new_mode):
	if brush_mode == new_mode:
		return
	_previous_tool = brush_mode
	brush_mode = new_mode
	
	_current_action = get_action()
	
	match _previous_tool:
		Tools.CUT:
			paint_canvas.clear_preview_layer()
		Tools.PASTECUT:
			_selection_cells.clear()
			_selection_colors.clear()
		Tools.BUCKET:
			_current_action = null
	#print("Selected: ", Tools.keys()[brush_mode])


func change_color(new_color):
	if new_color.a == 0:
		return
	selected_color = new_color
	color_picker_button.color = selected_color


func _on_ColorPicker_color_changed(color):
	selected_color = color


func _on_PaintTool_pressed():
	set_tool(Tools.PAINT)


func _on_BucketTool_pressed():
	set_tool(Tools.BUCKET)


func _on_RainbowTool_pressed():
	set_tool(Tools.RAINBOW)


func _on_BrushTool_pressed():
	set_tool(Tools.BRUSH)


func _on_LineTool_pressed():
	set_tool(Tools.LINE)


func _on_RectTool_pressed():
	set_tool(Tools.RECT)


func _on_DarkenTool_pressed():
	set_tool(Tools.DARKEN)


func _on_BrightenTool_pressed():
	set_tool(Tools.BRIGHTEN)


func _on_ColorPickerTool_pressed():
	set_tool(Tools.COLORPICKER)


func _on_CutTool_pressed():
	set_tool(Tools.CUT)


func _on_Editor_visibility_changed():
	pause_mode = not visible



############################################
# Preview
############################################

func _adjust_preview_layer_size():
	_preview_scale = max_preview_scale
	_on_canvas_resized()
	var width = paint_canvas.canvas_width
	var height = paint_canvas.canvas_height
	
	while _preview_scale > min_preview_scale:
		if width * _preview_scale < preview_layer_textures.rect_size.x:
			break
		set_preview_scale(_preview_scale / 2)
		
	while _preview_scale > min_preview_scale:
		if height * _preview_scale < preview_layer_textures.rect_size.y:
			break
		set_preview_scale(_preview_scale / 2)
	
	_update_preview_layers_size()


const max_preview_scale = pow(2, 10)
const min_preview_scale = pow(0.5, 10)

func set_preview_scale(new_scale: float):
	_preview_scale = clamp(new_scale, min_preview_scale, max_preview_scale)


func _update_preview_layers_size():
	for child in preview_layer_textures.get_children():
		child.rect_scale.x = _preview_scale
		child.rect_scale.y = _preview_scale
		_center_element(child)
	preview_window.set_title(str("Preview (x", _preview_scale, ")"))


func _add_preview_layer():
	var preview_texture = TextureRect.new()
	preview_texture.expand = false
	preview_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	preview_layer_textures.add_child(preview_texture)
	preview_texture.owner = owner
	preview_texture.set_anchors_preset(Control.PRESET_CENTER)
	
	_adjust_preview_layer_size()


# only updates preview atm
func _on_canvas_resized():
	if not paint_canvas.frame:
		return
	for idx in range(preview_layer_textures.get_child_count()):
		preview_layer_textures.get_child(idx).texture = paint_canvas.frame.layers[idx].texture
		_center_element(preview_layer_textures.get_child(idx))


func _center_element(element: Control):
	var width  = element.get_rect().size.x / 2
	var height = element.get_rect().size.y / 2
	element.margin_left = -width
	element.margin_top = -height
	element.margin_right = width
	element.margin_bottom = height



############################################
# Layer
############################################


func get_layer_count():
	return _total_added_layers


func get_layer_name(index: int):
	return layer_buttons.get_child(index).name


func resize(width: int, height: int):
	paint_canvas.resize(width, height)
	
	for anim in animations:
		for frame in anim.frames:
			frame.resize(width, height)
	
	_adjust_preview_layer_size()


func highlight_layer(layer_name: String):
	if animations.empty() or animations[0].frames.empty():
		return
	for button in layer_buttons.get_children():
		if paint_canvas.find_layer_by_name(button.name).locked:
			button.get("custom_styles/panel").set("bg_color", locked_layer_highlight)
		elif button.name == layer_name:
			button.get("custom_styles/panel").set("bg_color", current_layer_highlight)
		else:
			button.get("custom_styles/panel").set("bg_color", other_layer_highlight)


func toggle_layer_visibility(button, layer_name: String):
	var index = paint_canvas.get_layer_index(layer_name)
	preview_layer_textures.get_child(index).visible = paint_canvas.toggle_layer_visibility(layer_name)
	
	for anim_stripe in anim_panel.anim_button_container.get_children():
		for frame_button in anim_stripe.frame_button_container.get_children():
			frame_button.set_layer_visibility(index, preview_layer_textures.get_child(index).visible)
			frame_button.update_preview()
	
	_update_frame_button_previews()


func select_layer(layer_button):
	current_layer_idx = layer_button.get_index()
	var layer = paint_canvas.find_layer_by_name(layer_button.name)
	paint_canvas.select_layer(layer)
	highlight_layer(layer_button.name)


func lock_layer(button, layer_name: String):
	paint_canvas.toggle_lock_layer(layer_name)
	highlight_layer(paint_canvas.get_active_layer().name)


func _add_layer_button():
	var layer_button = LayerButton.instance()
	layer_buttons.add_child(layer_button, true)
	_total_added_layers += 1
	layer_button.find_node("Select").text = "Layer " + str(get_layer_count())
	_layer_button_ref[layer_button.name] = layer_button
	_connect_layer_buttons()
	return layer_button


func _create_layer(layer_name: String, width: int, height: int):
	var layer: GELayer = GELayer.new()
	layer.name = layer_name
	var texture_rect = TextureRect.new()
	texture_rect.expand = true
	texture_rect.anchor_right = 1
	texture_rect.anchor_bottom = 1
	texture_rect.margin_right = 0
	texture_rect.margin_bottom = 0
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.create(texture_rect, width, height)
	return layer


func add_new_layer():
	var layer_button = _add_layer_button()
	
	for anim in animations:
		for frame in anim.frames:
			var layer: GELayer = _create_layer(layer_button.name, 
					paint_canvas.canvas_width, paint_canvas.canvas_height)
			frame.add_frame_layer(layer)
	
	_add_preview_layer()
	
	if current_frame:
		preview_window.update_preview(current_frame)
		paint_canvas.set_frame(current_frame)
	highlight_layer(paint_canvas.get_active_layer().name)
	
	_update_frame_button_previews()


func duplicate_active_layer():
	var layer_button = _add_layer_button()
	for anim in animations:
		for frame in anim.frames:
			var new_layer: GELayer = _create_layer(layer_button.name, 
					paint_canvas.canvas_width, paint_canvas.canvas_height)
			new_layer.copy_from(frame.layers[paint_canvas.get_active_layer_index()])
			frame.add_frame_layer(new_layer)
			new_layer.update_texture()
	
	_add_preview_layer()
	
	if current_frame:
		preview_window.update_preview(current_frame)
		paint_canvas.set_frame(current_frame)
	
	# update highlight
	highlight_layer(paint_canvas.get_active_layer().name)
	_update_frame_button_previews()


func remove_active_layer():
	if layer_buttons.get_child_count() <= 1:
		return
	var layer_name = paint_canvas.active_layer.name
	var index = paint_canvas.get_layer_index(paint_canvas.active_layer.name)
	paint_canvas.remove_layer(layer_name)
	layer_buttons.remove_child(_layer_button_ref[layer_name])
	_layer_button_ref[layer_name].queue_free()
	_layer_button_ref.erase(layer_name)
	
	var preview_layer = preview_layer_textures.get_child(index)
	preview_layer.remove_child(preview_layer)
	preview_layer.queue_free()
	
	_update_frame_button_previews()
	
	highlight_layer(paint_canvas.get_active_layer().name)


func move_up(layer_btn):
	var index = layer_btn.get_index()
	var new_idx = min(index + 1, layer_buttons.get_child_count() - 1)
	if index == new_idx:
		return
	
	# layer buttons
	layer_buttons.move_child(layer_btn, new_idx)
	# canvas
	paint_canvas.move_layer_forward(layer_btn.name)
	# preview window
	preview_layer_textures.move_child(preview_layer_textures.get_child(index), new_idx)
	# Frame previews
	for anim_idx in range(animations.size()):
		var anim = animations[anim_idx]
		for frame_idx in range(anim.frames.size()):
			var frame = anim.frames[frame_idx]
			var layer = frame.layers[index]
			frame.layers.remove(index)
			frame.layers.insert(new_idx, layer)
			anim_panel.set_frame_preview(anim_idx, frame_idx, frame)
	
	_update_frame_button_previews()


func move_down(layer_btn):
	var index = layer_btn.get_index()
	var new_idx = max(index - 1, 0)
	if index == new_idx:
		return
	
	# layer buttons
	layer_buttons.move_child(layer_btn, new_idx)
	# canvas
	paint_canvas.move_layer_forward(layer_btn.name)
	# preview window
	preview_layer_textures.move_child(preview_layer_textures.get_child(index), new_idx)
	# Frame previews
	for anim_idx in range(animations.size()):
		var anim = animations[anim_idx]
		for frame_idx in range(anim.frames.size()):
			var frame = anim.frames[frame_idx]
			var layer = frame.layers[index]
			frame.layers.remove(index)
			frame.layers.insert(new_idx, layer)
			anim_panel.set_frame_preview(anim_idx, frame_idx, frame)
	
	_update_frame_button_previews()


func _connect_layer_buttons():
	for layer_btn in layer_buttons.get_children():
		if layer_btn.find_node("Select").is_connected("pressed", self, "select_layer"):
			continue
		layer_btn.find_node("Select").connect("pressed", self, "select_layer", [layer_btn])
		layer_btn.find_node("Visible").connect("pressed", self, "toggle_layer_visibility",
				[layer_btn.find_node("Visible"), layer_btn.name])
		layer_btn.find_node("Up").connect("pressed", self, "move_down", [layer_btn])
		layer_btn.find_node("Down").connect("pressed", self, "move_up", [layer_btn])
		layer_btn.find_node("Lock").connect("pressed", self, "lock_layer",
				[layer_btn, layer_btn.name])


func _on_AddNewLayer_pressed():
	add_new_layer()
	#_update_frame_button_previews()


func _update_frame_button_previews():
	for anim_stripe in anim_panel.anim_button_container.get_children():
		for frame_button in anim_stripe.frame_button_container.get_children():
			frame_button.update_preview()


func _on_PaintCanvasContainer_mouse_entered():
	if mouse_on_top:
		return
	mouse_on_top = true
	paint_canvas.tool_layer.clear()
	paint_canvas.update()
	paint_canvas.tool_layer.update_texture()


func _on_PaintCanvasContainer_mouse_exited():
	if not mouse_on_top:
		return
	mouse_on_top = false
	paint_canvas.tool_layer.clear()
	paint_canvas.update()
	paint_canvas.tool_layer.update_texture()


func _on_ColorPicker_popup_closed():
	find_node("Colors").add_color_prefab(color_picker_button.color)



############################################
# MISC
############################################

func is_position_in_canvas(pos):
	if control_has_point(left_panel, pos):
		return false
	if control_has_point(right_panel, pos):
		return false
	if control_has_point(preview_window, pos):
		return false
	
	return control_has_point(paint_canvas_container_node, pos)


func control_has_point(control, point) -> bool:
	if not control.visible:
		return false
	return Rect2(control.rect_global_position, control.rect_size).has_point(point)


func is_mouse_in_canvas() -> bool:
	return is_position_in_canvas(get_global_mouse_position())


func is_mouse_in_preview_window() -> bool:
	return control_has_point(preview_window, get_global_mouse_position())


func is_any_menu_open() -> bool:
	return $ChangeCanvasSize.visible or \
			$ChangeGridSizeDialog.visible or \
			$Settings.visible or \
			$LoadFileDialog.visible or \
			$SaveFileDialog.visible or \
			find_node("Navbar").is_any_menu_open()


func _on_LockAlpha_pressed():
	var checked = find_node("LockAlpha").pressed
	paint_canvas.active_layer.toggle_alpha_locked()
	for i in range(find_node("Layer").get_popup().get_item_count()):
		if find_node("Layer").get_popup().get_item_text(i) == "Toggle Alpha Locked":
			find_node("Layer").get_popup().set_item_checked(i, 
					not find_node("Layer").get_popup().is_item_checked(i))


func _on_BrushRect_pressed():
	if brush_mode != Tools.BRUSH:
		set_tool(Tools.BRUSH)
	selected_brush_prefab = BrushPrefabs.Type.RECT


func _on_BrushCircle_pressed():
	if brush_mode != Tools.BRUSH:
		set_tool(Tools.BRUSH)
	selected_brush_prefab = BrushPrefabs.Type.CIRCLE


func _on_BrushVLine_pressed():
	if brush_mode != Tools.BRUSH:
		set_tool(Tools.BRUSH)
	selected_brush_prefab = BrushPrefabs.Type.V_LINE


func _on_BrushHLine_pressed():
	if brush_mode != Tools.BRUSH:
		set_tool(Tools.BRUSH)
	selected_brush_prefab = BrushPrefabs.Type.H_LINE


func _on_BrushSize_value_changed(value: float):
	find_node("BrushSizeLabel").text = str(int(value))


func _on_XSymmetry_pressed():
	paint_canvas.symmetry_x = not paint_canvas.symmetry_x


func _on_YSymmetry_pressed():
	paint_canvas.symmetry_y = not paint_canvas.symmetry_y
