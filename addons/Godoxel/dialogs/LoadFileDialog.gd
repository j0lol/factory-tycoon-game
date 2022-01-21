tool
extends FileDialog


enum LoadMode {
	IMPORT_IMAGE,
	LOAD_PROJECT,
}

var canvas: GECanvas
var file_path = ""
var load_mode = LoadMode.IMPORT_IMAGE


func _ready():
	get_line_edit().connect("text_entered", self, "_on_LineEdit_text_entered")
	invalidate()
	clear_filters()
	add_filter("*.png ; PNG Images")


func _on_LineEdit_text_entered(_text):
	return
#	print(_text)
	#load_img()
#	print("hsadfasd")



#######################################################
# dialogs
#######################################################

func open_load_project():
	invalidate()
	clear_filters()
	add_filter("*.godoxel ; Godot - Godoxel")
	load_mode = LoadMode.LOAD_PROJECT
	show()


func open_import_image():
	invalidate()
	clear_filters()
	add_filter("*.png ; PNG Images")
	load_mode = LoadMode.IMPORT_IMAGE
	show()



#######################################################
# dialogs
#######################################################

func _on_LoadFileDialog_file_selected(path):
	file_path = path
	
	match load_mode:
		LoadMode.IMPORT_IMAGE:
			import_image()
		LoadMode.LOAD_PROJECT:
			load_project()


func load_project():
	var file = File.new()
	file.open(file_path, File.READ)
	var data = JSON.parse(file.get_as_text()).result
	file.close()
	
	owner.load_project(data)


func import_image():
	var image = Image.new()
	if image.load(file_path) != OK:
		print("couldn't load image!")
		return
	
	var image_data = image.get_data()
	var layer: GELayer = owner.add_new_layer()
	
	var width = image.get_width()
	var height = image.get_height()
	
	if owner.paint_canvas.canvas_width < width:
		owner.resize(width, owner.paint_canvas.canvas_height)

	if owner.paint_canvas.canvas_height < height:
		owner.resize(owner.paint_canvas.canvas_width, height)
	
	for i in range(image_data.size() / 4):
		var color = Color(image_data[i*4] / 255.0, image_data[i*4+1] / 255.0, image_data[i*4+2] / 255.0, image_data[i*4+3] / 255.0)
		var pos = GEUtils.to_2D(i, image.get_width())
		if pos.x > layer.layer_width:
			continue
			
		layer.set_pixel(pos.x, pos.y, color)
	layer.update_texture()
	owner._update_frame_button_previews()


func _on_LoadFileDialog_confirmed():
	return


func _on_LoadFileDialog_about_to_show():
	invalidate()


func _on_LoadFileDialog_visibility_changed():
	invalidate()
