extends Control
class_name GECanvas
tool

export var pixel_size: float = 16 setget set_pixel_size
export(int, 1, 2500) var canvas_width = 48 setget set_canvas_width # == pixels
export(int, 1, 2500) var canvas_height = 28 setget set_canvas_height # == pixels
export var grid_size = 16 setget set_grid_size
export var big_grid_size = 10 setget set_big_grid_size
export var can_draw = true

var mouse_in_region
var mouse_on_top

var frame: GEFrame

#var layers : Array = [] # Key: layer_name, val: GELayer
var active_layer: GELayer
var preview_layer: GELayer
var tool_layer: GELayer
var canvas_layers: Control

var canvas
var grid
var big_grid
var selected_pixels = []

var symmetry_x = false
var symmetry_y = false


func _ready():
	#-------------------------------
	# Set nodes
	#-------------------------------
	canvas = find_node("Canvas")
	grid = find_node("Grid")
	big_grid = find_node("BigGrid")
	canvas_layers = find_node("CanvasLayers")
	
	#-------------------------------
	# setup layers and canvas
	#-------------------------------
	if not is_connected("mouse_entered", self, "_on_mouse_entered"):
		connect("mouse_entered", self, "_on_mouse_entered")
	if not is_connected("mouse_exited", self, "_on_mouse_exited"):
		connect("mouse_exited", self, "_on_mouse_exited")
	
	#-------------------------------
	# setup layers and canvas
	#-------------------------------
	#canvas_size = Vector2(int(rect_size.x / grid_size), int(rect_size.y / grid_size))
	#pixel_size = canvas_size
	
	create_preview_layer()
	create_tool_layer()
	
	set_process(true)


func _process(delta):
	if not is_visible_in_tree():
		return
	var mouse_position = get_local_mouse_position()
	var rect = Rect2(Vector2(0, 0), rect_size)
	mouse_in_region = rect.has_point(mouse_position)


func _draw():
	if preview_layer:
		preview_layer.update_texture()
	if tool_layer:
		tool_layer.update_texture()
#	for layer in layers:
#		layer.update_texture()
	# TODO
	#if frame:
		#frame._draw()


func resize(width: int, height: int):
	if width < 0:
		width = 1
	if height < 0:
		height = 1
	
	# TODO move resize to editor.gd -> for all frames
	
	set_canvas_width(width)
	set_canvas_height(height)
	
	preview_layer.resize(width, height)
	tool_layer.resize(width, height)
	
	#frame.resize(width, height)
	


func set_frame(new_frame):
	frame = new_frame
	if canvas_layers.get_child_count() > 0:
		canvas_layers.remove_child(canvas_layers.get_child(0))
	canvas_layers.add_child(frame)
	
	frame.width = canvas_width
	frame.height = canvas_height
	
	frame.anchor_right = 1
	frame.anchor_bottom = 1
	frame.margin_right = 0
	frame.margin_bottom = 0
	
	if not frame.layers.empty():
		active_layer = frame.layers[owner.current_layer_idx]



################################################################
# Export
################################################################

func get_current_frame_image() -> Image:
	var image = Image.new()
	image.create(canvas_width, canvas_height, true, Image.FORMAT_RGBA8)
	image.lock()
	image.fill(Color.transparent)
	image.unlock()
	image.lock()
	
	for layer in frame.layers:
		if not layer.visible:
			continue
		
		for x in range(frame.width):
			for y in range(frame.height):
				var color = layer.get_pixel(x, y)
				var image_color = image.get_pixel(x, y)
				
				if color.a != 0:
					image.set_pixel(x, y, color)
				else:
					image.set_pixel(x, y, image_color.blend(color))
	image.unlock()
	return image


func get_current_layer_image() -> Image:
	var image = Image.new()
	image.create(canvas_width, canvas_height, true, Image.FORMAT_RGBA8)
	image.lock()
	image.fill(Color.transparent)
	image.unlock()
	image.lock()
	
	for layer in frame.layers:
		if layer != active_layer:
			continue
		
		for x in range(frame.width):
			for y in range(frame.height):
				var color = layer.get_pixel(x, y)
				var image_color = image.get_pixel(x, y)
				
				if color.a != 0:
					image.set_pixel(x, y, color)
				else:
					image.set_pixel(x, y, image_color.blend(color))
	image.unlock()
	return image



################################################################
# Pixel/Grid size
################################################################

func set_pixel_size(size: float):
	pixel_size = size
	set_grid_size(grid_size)
	set_big_grid_size(big_grid_size)
	set_canvas_width(canvas_width)
	set_canvas_height(canvas_height)


func set_grid_size(size):
	grid_size = size
	if not find_node("Grid"):
		return
	find_node("Grid").size = size * pixel_size


func set_big_grid_size(size):
	big_grid_size = size
	if not find_node("BigGrid"):
		return
	find_node("BigGrid").size = size * pixel_size


func set_canvas_width(val: int):
	canvas_width = val
	rect_size.x = canvas_width * pixel_size


func set_canvas_height(val: int):
	canvas_height = val
	rect_size.y = canvas_height * pixel_size



#-------------------------------
# Layer
#-------------------------------

func toggle_alpha_locked(layer_name: String):
	var layer = find_layer_by_name(layer_name)
	layer.toggle_alpha_locked()


func is_alpha_locked() -> bool:
	return active_layer.alpha_locked


func get_content_margin() -> Rect2:
	return frame.get_content_margin()


func crop_to_content():
	frame.crop_to_content()


func get_active_layer() -> GELayer:
	return active_layer


func get_preview_layer():
	return preview_layer


func clear_active_layer():
	active_layer.clear()


func clear_preview_layer():
	preview_layer.clear()


func clear_layer(layer_name: String):
	for layer in frame.layers:
		if layer.name == layer_name:
			layer.clear()
			break


func remove_layer(layer_name: String):
	# change current layer if the active layer is removed
	var del_layer = find_layer_by_name(layer_name)
	del_layer.clear()
	if del_layer == active_layer:
		for layer in frame.layers:
			if layer == preview_layer or layer == active_layer or layer == tool_layer:
				continue
			active_layer = layer
			print("Select active layer: ", active_layer)
			break
	frame.layers.erase(del_layer)
	return active_layer


func create_preview_layer():
	var layer = GELayer.new()
	layer.create($PreviewLayer, canvas_width, canvas_height)
	preview_layer = layer
	return layer


func create_tool_layer():
	var layer = GELayer.new()
	layer.create($ToolPreviewLayer, canvas_width, canvas_height)
	tool_layer = layer
	return layer


func duplicate_layer(layer: GELayer):
	for existing_layer in frame.layers:
		if layer.name == existing_layer.name:
			return
	
	var new_layer: GELayer = GELayer.new()
	new_layer.image.copy_from(layer.image)
	return new_layer


func toggle_layer_visibility(layer_name: String):
	var layer_idx = get_layer_index(layer_name)
	assert(layer_idx != -1, "Layer name not found!")
	var layer = frame.layers[layer_idx]
	layer.visible = not layer.visible
	return layer.visible


func get_layer_index(layer_name: String):
	var idx = 0
	for layer in frame.layers:
		if layer.name == layer_name:
			return idx
		idx += 1
	return -1


func find_layer_by_name(layer_name: String):
	for layer in frame.layers:
		if layer.name == layer_name:
			return layer
	return null


func toggle_lock_layer(layer_name: String):
	find_layer_by_name(layer_name).toggle_lock()


func is_active_layer_locked() -> bool:
	return active_layer.locked


func get_active_layer_index() -> int:
	return get_layer_index(active_layer.name)


func move_layer_forward(layer_name: String):
	var layer = find_layer_by_name(layer_name).texture_rect_ref
	var new_idx = max(layer.get_index() - 1, 0)
	layer.get_parent().move_child(layer, new_idx)


func move_layer_back(layer_name: String):
	var layer = find_layer_by_name(layer_name).texture_rect_ref
	layer.get_parent().move_child(layer, layer.get_index() + 1)


func select_layer(layer: GELayer):
	active_layer = layer


#-------------------------------
# Check
#-------------------------------

func _on_mouse_entered():
	mouse_on_top = true


func _on_mouse_exited():
	mouse_on_top = false


func is_inside_canvas(x, y):
	if x < 0 or y < 0:
		return false
	if x >= canvas_width or y >= canvas_height:
		return false
	return true



#-------------------------------
# Basic pixel-layer options
#-------------------------------


#Note: Arrays are always passed by reference. To get a copy of an array which
#      can be modified independently of the original array, use duplicate.
# (https://docs.godotengine.org/en/stable/classes/class_array.html)
func set_pixel_arr(pixels: Array, color: Color):
	for pixel in pixels:
		_set_pixel(active_layer, pixel.x, pixel.y, color)


func set_pixel_v(pos: Vector2, color: Color):
	set_pixel(pos.x, pos.y, color)


func set_pixel(x: int, y: int, color: Color):
	_set_pixel(active_layer, x, y, color)


func _set_pixel_v(layer: GELayer, v: Vector2, color: Color):
	_set_pixel(layer, v.x, v.y, color)


func _set_pixel(layer: GELayer, x: int, y: int, color: Color):
	if not is_inside_canvas(x, y):
		return
	layer.set_pixel(x, y, color)


func get_pixel_v(pos: Vector2):
	return get_pixel(pos.x, pos.y)


func get_pixel(x: int, y: int):
	if active_layer:
		return active_layer.get_pixel(x, y)
	return null


func set_preview_pixel_v(pos: Vector2, color: Color):
	set_preview_pixel(pos.x, pos.y, color)


func set_preview_pixel(x:int, y: int, color: Color):
	if not is_inside_canvas(x, y):
		return
	preview_layer.set_pixel(x, y, color)


func get_preview_pixel_v(pos: Vector2):
	return get_preview_pixel(pos.x, pos.y)


func get_preview_pixel(x: int, y: int):
	if not preview_layer:
		return null
	return preview_layer.get_pixel(x, y)



#-------------------------------
# Grid
#-------------------------------


func toggle_grid():
	$Grid.visible = not $Grid.visible


func show_grid():
	$Grid.show()


func hide_grid():
	$Grid.hide()


#-------------------------------
# Handy tools
#-------------------------------


func select_color(x, y):
	print("???")
	var same_color_pixels = []
	var color = get_pixel(x, y)
	for x in range(active_layer.layer_width):
		for y in range(active_layer.layer_height):
			var pixel_color = active_layer.get_pixel(x, y)
			if pixel_color == color:
				same_color_pixels.append(color)
	return same_color_pixels


func select_same_color(x, y):
	return get_neighbouring_pixels(x, y)


# returns array of Vector2
# yoinked from
# https://www.geeksforgeeks.org/flood-fill-algorithm-implement-fill-paint/
func get_neighbouring_pixels(pos_x: int, pos_y: int) -> Array:
	var pixels = []
	
	var to_check_queue = []
	var checked_queue = []
	
	to_check_queue.append(GEUtils.to_1D(pos_x, pos_y, canvas_width))
	
	var color = get_pixel(pos_x, pos_y)
	
	while not to_check_queue.empty():
		var idx = to_check_queue.pop_front()
		var p = GEUtils.to_2D(idx, canvas_width)
		
		if idx in checked_queue:
			continue
		
		checked_queue.append(idx)
		
		if get_pixel(p.x, p.y) != color:
			continue
		
		# add to result
		pixels.append(p)
		
		# check neighbours
		var x = p.x - 1
		var y = p.y
		if is_inside_canvas(x, y):
			idx = GEUtils.to_1D(x, y, canvas_width)
			to_check_queue.append(idx)
		
		x = p.x + 1
		if is_inside_canvas(x, y):
			idx = GEUtils.to_1D(x, y, canvas_width)
			to_check_queue.append(idx)
		
		x = p.x
		y = p.y - 1
		if is_inside_canvas(x, y):
			idx = GEUtils.to_1D(x, y, canvas_width)
			to_check_queue.append(idx)
		
		y = p.y + 1
		if is_inside_canvas(x, y):
			idx = GEUtils.to_1D(x, y, canvas_width)
			to_check_queue.append(idx)
	
	return pixels

