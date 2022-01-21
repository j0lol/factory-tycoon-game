extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.connect("tick", self, "_on_Tick")
	
	
func _on_Tick():

	var s = preload("res://Item.tscn").instance()
	s.name = "Item"
	s._item = 6
	s.position = position
	$"..".add_child(s)
