extends Path2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var c = Node2D.new()
	var p = PathFollow2D.new()
	var s = preload("res://Item.tscn").instance()
	c.set_script(preload("res://pathfollow.gd"))
	c.add_child(s)
	p.add_child(c)
	p.offset = 0
	p.rotate = false
	p.loop = false
	p.name = "pathfollow"
	add_child(p)
	self.curve.add_point(Vector2(0,-8))
	print_tree_pretty()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
