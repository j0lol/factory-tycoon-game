extends Panel
tool

onready var name_label = find_node("Name")
onready var shortcut_label = find_node("Shortcut")

const select_theme = preload("res://addons/Godoxel/themes/ShortcutPanel_selected.tres")
const deselect_theme = preload("res://addons/Godoxel/themes/ShortcutPanel_deselected.tres")


func _ready():
	set("custom_styles/panel", deselect_theme)


func set_tool(tool_name, tool_shortcut):
	name_label.text = tool_name
	shortcut_label.text = tool_shortcut


func select():
	set("custom_styles/panel", select_theme)


func deselect():
	set("custom_styles/panel", deselect_theme)


func get_shortcut():
	return shortcut_label.text
