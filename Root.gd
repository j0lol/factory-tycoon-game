extends Node2D


var root = self

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

signal i_am_root

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	emit_signal("i_am_root", self)
	root = self
