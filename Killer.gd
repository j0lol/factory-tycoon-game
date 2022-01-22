extends "res://Chest.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	yield(get_tree().create_timer(0.1), "timeout")
	queue_free()


func _on_Machine_area_shape_entered(_area_rid, area, _area_shape_index, _local_shape_index):
	if "Machine" in area.name or "Chest" in area.name:
		area.queue_free()
	queue_free()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
