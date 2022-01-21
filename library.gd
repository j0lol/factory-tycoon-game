extends Reference
class_name library



static func get_mouse_tile_pos(t: TileMap):
	return t.world_to_map(t.get_viewport().get_mouse_position())


static func circular_clamp(val: int, minimum: int, maximum: int):
	if (val < minimum): return maximum
	elif (val > maximum): return minimum
	else: return val
