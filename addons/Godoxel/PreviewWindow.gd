extends GEDraggableWindow
tool

onready var preview_layers = $PreviewLayerTextures


func _ready() -> void:
	show()


func update_preview(frame: GEFrame):
	for idx in range(preview_layers.get_child_count()):
		preview_layers.get_child(idx).texture = frame.layers[idx].texture

