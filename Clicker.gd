# credit https://godotengine.org/qa/89677/solved-with-solution-how-to-click-only-the-top-area2d
extends Node2D


var click_all = false
var ignore_unclickable = true


func _input(event):
	
	if get_node("/root/Root/CanvasLayer/Hotbar").selected != 8:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == 1: # Left mouse click
		var shapes = get_world_2d().direct_space_state.intersect_point(get_global_mouse_position(), 32, [], 0x7FFFFFFF, true, true) # The last 'true' enables Area2D intersections, previous four values are all defaults

		for shape in shapes:
			if shape["collider"].has_method("on_click"):
				shape["collider"].on_click()

				if !click_all and ignore_unclickable:
					break # Thus clicks only the topmost clickable

			if !click_all and !ignore_unclickable:
				break # Thus stops on the first shape
