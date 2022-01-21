tool
extends FileDialog

enum SaveMode {
	CURRENT_FRAME,
	PROJECT,
	CURRENT_LAYER,
}

var save_mode = SaveMode.CURRENT_FRAME
onready var canvas = get_parent().find_node("Canvas")
var file_path = ""


func _ready():
	# warning-ignore:return_value_discarded
	get_line_edit().connect("text_entered", self, "_on_LineEdit_text_entered")
	invalidate()
	clear_filters()
	add_filter("*.png ; PNG Images")



#######################################################
# dialogs
#######################################################

func open_save_current_frame():
	show()
	invalidate()
	clear_filters()
	add_filter("*.png ; PNG Images")
	save_mode = SaveMode.CURRENT_FRAME


func open_save_project():
	show()
	invalidate()
	clear_filters()
	add_filter("*.godoxel ; Godot - Godoxel")
	save_mode = SaveMode.PROJECT


func open_save_current_layer():
	show()
	invalidate()
	clear_filters()
	add_filter("*.png ; PNG Images")
	save_mode = SaveMode.CURRENT_LAYER



#######################################################
# dialogs
#######################################################

func _on_SaveFileDialog_file_selected(path: String):
	file_path = path
	match save_mode:
		SaveMode.CURRENT_FRAME:
			save_current_frame()
		SaveMode.CURRENT_LAYER:
			save_current_layer()
		SaveMode.PROJECT:
			save_project()


func save_current_layer():
	var image = canvas.get_current_layer_image()
	
	# overwrite image if exists
	var dir = Directory.new()
	if dir.file_exists(file_path):
		dir.remove(file_path)
	
	image.save_png(file_path)
	
	# update file doc if using inside the editor
	if Engine.is_editor_hint():
		EditorPlugin.new().get_editor_interface().get_resource_filesystem().scan()


func save_project():
	var save_data = owner.get_save_project_data()
	
	# overwrite image if exists
	var dir = Directory.new()
	if dir.file_exists(file_path):
		dir.remove(file_path)
	
	var file = File.new()
	file.open(file_path, File.WRITE)
	file.store_string(JSON.print(save_data))
	file.close()
	
	# update file doc if using inside the editor
	if Engine.is_editor_hint():
		EditorPlugin.new().get_editor_interface().get_resource_filesystem().scan()


func save_current_frame():
	var image = canvas.get_current_frame_image()
	
	# overwrite image if exists
	var dir = Directory.new()
	if dir.file_exists(file_path):
		dir.remove(file_path)
	
	image.save_png(file_path)
	
	# update file doc if using inside the editor
	if Engine.is_editor_hint():
		EditorPlugin.new().get_editor_interface().get_resource_filesystem().scan()


func _on_SaveFileDialog_about_to_show():
	invalidate()


func _on_SaveFileDialog_visibility_changed():
	invalidate()


#func _on_LineEdit_text_entered(text):
#	return


func _on_SaveFileDialog_confirmed():
	return
