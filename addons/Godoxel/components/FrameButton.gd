extends Button
tool

signal on_frame_pressed(btn)

onready var frame_preview := find_node("TextureRect")

var frame: GEFrame


func _ready():
	pass


func set_frame(frame: GEFrame):
	self.frame = frame
	update_preview()


func set_layer_visibility(layer_idx: int, visibility: bool):
	frame.layers[layer_idx].visible = visibility


func update_preview():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	for layer in frame.layers:
		if not layer.visible:
			continue
		var texture_rect = TextureRect.new()
		add_child(texture_rect)
		texture_rect.expand = true
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.anchor_bottom = 1
		texture_rect.anchor_right = 1
		texture_rect.margin_left = 3
		texture_rect.margin_top = 3
		texture_rect.margin_right = -3
		texture_rect.margin_bottom = -3
		
		texture_rect.texture = layer.texture


func move_layer_forward():
	pass


func move_layer_back():
	pass


func _on_FrameButton_pressed():
	emit_signal("on_frame_pressed", get_index())
