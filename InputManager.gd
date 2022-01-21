extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var hotbar = get_node("/root/Root/CanvasLayer/Hotbar")
onready var map = get_node("/root/Root/TileMap")
var rotation_cooldown = 0
var place_cooldown = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func input(): 
	rotation_cooldown -= 1
	place_cooldown -= 1
	if Input.is_action_pressed("rotate"):
		if rotation_cooldown < 1:
			global.rotation += 1
			rotation_cooldown = 15
			global.rotation = library.circular_clamp(global.rotation, 0,3)
	if Input.is_action_just_released("scroll_up"):
		hotbar.selected = clamp(hotbar.selected + 1, 1,8)
	if Input.is_action_just_released("scroll_down"):
		hotbar.selected = clamp(hotbar.selected - 1, 1,8)

func tile_input():
	if Input.is_action_pressed("click"):
		global.tile = 0
		place_tile_mouse(0)
	elif Input.is_action_pressed("rclick"):
		global.tile = -1
		place_tile_mouse(-1)
	else: return false
	return true

func machine_input():
	if place_cooldown < 1:
		place_cooldown = 30
		if Input.is_action_pressed("click"):
			spawn_scene("res://Machine.tscn","Machine")

		elif Input.is_action_pressed("rclick"):
			spawn_scene("res://Killer.tscn","Killer")
	else: return false
	return true

func chest_input():
	if place_cooldown < 1:
		place_cooldown = 30
		if Input.is_action_pressed("click"):
			spawn_scene("res://Chest.tscn","Chest")
		elif Input.is_action_pressed("rclick"):
			spawn_scene("res://Killer.tscn","Killer")
		else: return false
		return true

func place_tile_mouse(tile):
	var coords = library.get_mouse_tile_pos(map)
	map.set_cell(coords.x, coords.y, tile, 
		map.rotations[global.rotation][0], 
		map.rotations[global.rotation][1], 
		map.rotations[global.rotation][2])

func _process(delta):
	input()
	match hotbar.selected:
		1: tile_input()
		2: machine_input()
		3: chest_input()

func spawn_scene(link, name):
	var s = load(link).instance()
	s.name = name
	s.position = get_viewport().get_mouse_position() - Vector2(8,8)
	s.position = s.position.snapped(Vector2(16,16))
	$"..".add_child(s)
