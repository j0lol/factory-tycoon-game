extends TileMap


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var tile = -1

var current_rotation: int = 0
var current_rotation_cooldown: int = 0

var rotations = [[false, false, false],
				 [false, false, true],
				 [true,  true,  false],
				 [true,  true,  true]]


func input(): 
	current_rotation_cooldown -= 1
	if Input.is_action_pressed("rotate"):
		if current_rotation_cooldown < 1:
			current_rotation += 1
			current_rotation_cooldown = 15
			current_rotation = library.circular_clamp(current_rotation, 0,3)

func tile_input():
	if Input.is_action_pressed("click"):
		tile = 0
	elif Input.is_action_pressed("rclick"):
		tile = -1
	else: return false
	return true

func place_tile_mouse(tile):
	var coords = library.get_mouse_tile_pos(self)
	set_cell(coords.x, coords.y, tile, 
		rotations[current_rotation][0], 
		rotations[current_rotation][1], 
		rotations[current_rotation][2])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	input()
	if !tile_input(): return
	



