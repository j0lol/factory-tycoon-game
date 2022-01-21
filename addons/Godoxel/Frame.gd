extends Control
class_name GEFrame
tool


var layers = []

var width: int
var height: int

var preview_texture: ImageTexture = ImageTexture.new()
var preview_dirty = false
var preview_updated = true


func _ready():
	pass


func _draw():
#	return
#	if not preview_dirty:
#		return
#	preview_dirty = false
	for layer in layers:
		layer.update_texture()
	#_update_preview()


func _update_preview():
	var image = Image.new()
	image.create(width, height, true, Image.FORMAT_RGBA8)
	image.lock()
	image.fill(Color.transparent)
	image.unlock()
	image.lock()
	
	for layer in layers:
		if not layer.visible:
			continue
		
		for x in range(width):
			for y in range(height):
				var color = layer.get_pixel(x, y)
				var image_color = image.get_pixel(x, y)
				
				if color.a != 0:
					image.set_pixel(x, y, color)
				else:
					image.set_pixel(x, y, image_color.blend(color))
	image.unlock()
	preview_texture.create_from_image(image)
	preview_updated = true


func get_preview_texture():
	return preview_texture


func set_layers(new_layers: Array):
	for layer in new_layers:
		add_frame_layer(layer)


func add_frame_layer(layer: GELayer):
	layers.append(layer)
	add_child(layer.texture_rect_ref, true)
	return layer


func resize(width: int, height: int):
	self.width = width
	self.height = height
	for layer in layers:
		layer.resize(width, height)


func get_content_margin() -> Rect2:
	var rect = Rect2(999999, 999999, -999999, -999999)
	for layer in layers:
		var r = layer.image.get_used_rect()
		if r.position.x < rect.position.x:
			rect.position.x = r.position.x
		if r.position.y < rect.position.y:
			rect.position.y = r.position.y
		if r.size.x > rect.size.x:
			rect.size.x = r.size.x
		if r.size.y > rect.size.y:
			rect.size.y = r.size.y
	return rect


func crop_to_content():
	var rect = get_content_margin()
	
	#print(rect)
	
	for layer in layers:
		layer.image
	
#	set_canvas_width(rect.size.x)
#	set_canvas_height(rect.size.x)
	
#	preview_layer.resize(width, height)
#	tool_layer.resize(width, height)
#	for layer in layers:
#		layer.resize(width, height)
