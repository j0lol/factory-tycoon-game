extends "res://Machine.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _on_Tick():
	pass

func _on_Machine_area_shape_entered(_area_rid, area, _area_shape_index, _local_shape_index):
	if "Item" in area.name:
		inventory.push_back(area._item)
		area.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
