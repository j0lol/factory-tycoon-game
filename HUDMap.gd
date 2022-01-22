extends TileMap


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global.in_ui:
		return
	self.clear()
	var tile = world_to_map(get_global_mouse_position())
	set_cell(tile.x, tile.y, 0)
