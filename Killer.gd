extends "res://Chest.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var timer = 10

func _process(delta):
	timer -=1
	if timer > 0:
		queue_free()

func _on_Machine_area_shape_entered(_area_rid, area, _area_shape_index, _local_shape_index):
	if "Machine" in area.name or "Chest" in area.name:
		area.queue_free()
	queue_free()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
