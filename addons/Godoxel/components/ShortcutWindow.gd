extends Panel
tool

onready var shortcut_container = find_node("ShortcutContainer")

var shortcuts = {}
var shift_pressed = false
var panels = []


func _ready():
	hide()
	panels.clear()
	for child in get_child(0).get_children():
		for panel in child.get_children():
			if panel is Panel:
				panels.append(panel)


func setup(shortcuts: Dictionary):
	self.shortcuts = shortcuts
	var idx = 0
	for panel in panels:
		var tool_name = ""
		if typeof(shortcuts.values()[idx]) == TYPE_STRING:
			tool_name = str(shortcuts.values()[idx])
		else:
			tool_name = str(owner.Tools.keys()[shortcuts.values()[idx]])
			tool_name = tool_name.to_lower().capitalize()
		
		var shortcut = OS.get_scancode_string(shortcuts.keys()[idx])
		panel.set_tool(tool_name, shortcut)
		idx += 1


func check_input_for_shorcut(event: InputEvent, shift_pressed: bool):
	if not event is InputEventKey:
		return
	
	if event.pressed:
		if event.scancode in shortcuts.keys():
			for panel in panels:
				panel.deselect()
			get_panel(event.as_text()).select()
			return true
		else:
			for panel in panels:
				panel.deselect()
	return false


func get_panel(scancode: String):
	var character = scancode.substr(scancode.length() - 1, 1)
	for panel in panels:
		if panel.get_shortcut() == character:
			return panel
	return null


