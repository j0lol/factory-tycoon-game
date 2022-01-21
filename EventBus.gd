extends Node


var timer = 0
var ttt = 30 # Time 'til tick
signal tick()

func _process(delta):
	timer += 1
	timer = library.circular_clamp(timer, 0,ttt)
	if timer == 0:
		emit_signal("tick")
