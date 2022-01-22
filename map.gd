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





