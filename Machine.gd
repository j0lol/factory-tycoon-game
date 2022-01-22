extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var inventory = []

var jobs = {
			6:0,
			9:1,
			10:2
		}

# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.connect("tick", self, "_on_Tick")

func _on_Tick():
	if inventory.size() > 0:
		#yield(get_tree().create_timer(2), "timeout")
		var s = preload("res://Item.tscn").instance()
		s._item = inventory.pop_front()
		if jobs.has(s._item): 
			s._item = jobs[s._item]
		s.name = "Item"
		s.position = Vector2(8,8) + Vector2(32,16) + position
		$"..".add_child(s)
	
func _on_Machine_area_shape_entered(_area_rid, area, _area_shape_index, _local_shape_index):
	if "Item" in area.name:
		inventory.push_back(area._item)
		area.queue_free()


var root
func _process(delta):
	root = get_parent().root


