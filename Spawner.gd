extends Node2D

var collide
var spawns = [6,9,10]
var tock = false
# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.connect("tick", self, "_on_Tick")
	
	
func _on_Tick():
	tock = !tock
	if tock or collide:
		return
	library.delay(0.1, self)

	var s = preload("res://Item.tscn").instance()
	s.name = "Item"
	s._item = spawns[randi() % spawns.size()]
	s.position = position
	$"..".add_child(s)

func _physics_process(delta):
	query_space()
	
func query_space():
	var physics := get_world_2d().direct_space_state

	var hits = physics.intersect_ray(position, 
				position, [],
				0x7FFFFFFF, false, true)
	if hits:
		collide = true
	else:
		collide = false
