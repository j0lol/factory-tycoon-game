extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	global.in_ui = true
	pass # Replace with function body.


func on_click():
	global.in_ui = false
	get_tree().change_scene("res://Node2D.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
