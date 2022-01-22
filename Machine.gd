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
	input_pickable = true

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

var mouse_over = false
var root
func _process(delta):
	root = get_parent().root
	if mouse_over:
		print("mouse over")
		if Input.is_action_pressed("click"):
			var t = Label.new()
			t.text = inventory
			add_child(t)
			print(inventory)





func _on_Machine_mouse_entered():
	mouse_over = true
	print("hi")



func _on_Machine_mouse_exited():
	mouse_over = true
