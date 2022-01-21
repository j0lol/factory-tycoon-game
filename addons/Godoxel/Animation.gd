extends Node
class_name GEAnimation


var frames = []
var anim_idx = -1


func _ready():
	pass


func add_frame(frame):
	frames.append(frame)


func get_anim_index():
	return anim_idx


func set_anim_index(index):
	anim_idx = index


