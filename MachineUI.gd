extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var inventory = []

# Called when the node enters the scene tree for the first time.
func _ready():
	global.in_ui = true



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var job = get_parent().current_job

	if get_parent().working:
		get_node("CanvasLayer/CurrentJob/GridContainer/Slot1/Sprite").texture = load(
			"res://images/"+global.items[job[0]]+".png")
		get_node("CanvasLayer/CurrentJob/GridContainer/Slot2/Sprite").texture = load(
			"res://images/"+global.items[job[1]]+".png")
	else:
		get_node("CanvasLayer/CurrentJob/GridContainer/Slot1/Sprite").texture = null
		get_node("CanvasLayer/CurrentJob/GridContainer/Slot2/Sprite").texture = null
	
	for i in range (0,8):
		if i <= inventory.size() - 1:
			print("CanvasLayer/Panel/GridContainer/Slot%s/Sprite" % [i+1])
			get_node("CanvasLayer/Panel/GridContainer/Slot%s/Sprite" % [i+1]).texture = load(
				"res://images/"+global.items[inventory[i]]+".png")
		else:
			get_node("CanvasLayer/Panel/GridContainer/Slot%s/Sprite" % [i+1]).texture = null
	
	if Input.is_action_pressed("ui_cancel"):
		queue_free()
		global.in_ui = false
