extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var root
# Called when the node enters the scene tree for the first time.
func ready():
	EventBus.connect("tick", self, "_on_Tick")
	print("hi")

func _on_Root_i_am_root(new_root):
	   root = new_root

func _on_Tick():
	var s = preload("res://Item.tscn").instance()
	s.name = "Item"
	s.position = Vector2(8,8) + Vector2(32,16)
	$"..".add_child(s)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
