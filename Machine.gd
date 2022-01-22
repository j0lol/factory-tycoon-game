extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var working = false
var current_job = [0,0,0]
var inventory = []

var jobs = {
			6:0,
			9:1,
			10:2
		}

# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.connect("tick", self, "_on_Tick")
	input_pickable = true

func _on_Tick():	
	if inventory.size() > 0 and working == false:
		set_collision_layer_bit(5, true)
		working = true
		var s = preload("res://Item.tscn").instance()
		s._item = inventory.pop_front()
		current_job = [s._item, jobs[s._item], 2]
		yield(get_tree().create_timer(2), "timeout")

		if jobs.has(s._item): 
			s._item = jobs[s._item]
		s.name = "Item"
		s.position = Vector2(8,8) + Vector2(32,16) + position
		$"..".add_child(s)
		set_collision_layer_bit(5, false)
		working = false
	
func _on_Machine_area_shape_entered(_area_rid, area, _area_shape_index, _local_shape_index):
	if "Item" in area.name:
		inventory.push_back(area._item)
		area.queue_free()





func on_click():
	var s = preload("res://MachineUI.tscn").instance()
	s.inventory = inventory
	s.rect_position = -position
	add_child(s)
	print(inventory)

