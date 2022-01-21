extends GEDraggableWindow
tool


var width_comp: SpinBox
var height_comp: SpinBox


func _ready() -> void:
	connect("on_ok", self, "_on_ConfirmationDialog_confirmed")
	connect("visibility_changed", self, "_on_ChangeCanvasSize_visibility_changed")
	
	yield(owner, "ready")
	
	width_comp = add_component_float("Width (px)", owner.paint_canvas.canvas_width, 1, 5000)
	height_comp = add_component_float("Height (px)", owner.paint_canvas.canvas_height, 1, 5000)


func _on_ConfirmationDialog_confirmed():
	var width = width_comp.value
	var height = height_comp.value
	print("change canvas size: ", width, " ", height)
	owner.resize(width, height)


func _on_ChangeCanvasSize_visibility_changed():
	if visible:
		width_comp.value = owner.paint_canvas.canvas_width
		height_comp.value = owner.paint_canvas.canvas_height
