extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var inventory = []

signal item_added
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _on_Machine_area_shape_entered(_area_rid, area, _area_shape_index, _local_shape_index):
	if "Item" in area.name:
		inventory.push_back(area._item)
		emit_signal("item_added")
		print(inventory)
	area.queue_free()


func _on_Machine_item_added():
	yield(get_tree().create_timer(2), "timeout")
	var s = preload("res://Item.tscn").instance()
	s._item = inventory.pop_back()
	if s._item == 6:
		s._item = 0
	s.name = "Item"
	s.position = Vector2(8,8) + Vector2(32,16)
	add_child(s)
	
	print_tree_pretty()

var root
func _on_Node2D_i_am_root(new_root):
	   root = new_root
