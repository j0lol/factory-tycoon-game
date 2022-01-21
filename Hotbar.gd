extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var bg_selected = StyleBoxFlat.new()
var bg_unselected = StyleBoxFlat.new()
var selected = 3

# Called when the node enters the scene tree for the first time.
func _ready():

	bg_selected.set_bg_color(Color(0.7,0.7,0.7,1))
	bg_unselected.set_bg_color(Color(0.4,0.4,0.4,1))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_node("Panel/GridContainer/Slot%s" % selected).add_stylebox_override("panel", bg_selected)
	for i in range(1,9):
		if i == selected:
			pass
		else:
			get_node("Panel/GridContainer/Slot%s" % i).add_stylebox_override("panel", bg_unselected)
