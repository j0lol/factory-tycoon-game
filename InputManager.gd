extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var mouse_collide = false
var mouse_collide_big = false

onready var hotbar = get_node("/root/Root/CanvasLayer/Hotbar")
onready var map = get_node("/root/Root/TileMap")
var rotation_cooldown = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	input()
	match hotbar.selected:
		1: tile_input()
		2: object_input("res://Machine.tscn","Machine", true)
		3: object_input("res://Chest.tscn","Chest", false)


func input(): 
	rotation_cooldown -= 1
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


func object_input(link, name, big):
	if big:
		if Input.is_action_pressed("click"):
			if !mouse_collide_big:
				spawn_scene(link,name)
		elif Input.is_action_pressed("rclick"):
				spawn_scene("res://Killer.tscn","Killer")
	else:
		if Input.is_action_pressed("click"):
			if !mouse_collide:
				spawn_scene(link,name)
		elif Input.is_action_pressed("rclick"):
				spawn_scene("res://Killer.tscn","Killer")


func place_tile_mouse(tile):
	var coords = library.get_mouse_tile_pos(map)
	map.set_cell(coords.x, coords.y, tile, 
		map.rotations[global.rotation][0], 
		map.rotations[global.rotation][1], 
		map.rotations[global.rotation][2])

func _physics_process(delta):
	query_space()
	
func query_space():
	var physics := get_world_2d().direct_space_state

	var hits = physics.intersect_ray(get_viewport().get_mouse_position(), 
				get_viewport().get_mouse_position() + Vector2(0,1), [],
				0x7FFFFFFF, false, true)
	if hits:
		mouse_collide = true
		mouse_collide_big = true
	else:
		mouse_collide = false
	
	var hits1 = physics.intersect_ray(get_viewport().get_mouse_position() + Vector2(0,16), 
			get_viewport().get_mouse_position() + Vector2(16,16), [],
			0x7FFFFFFF, false, true)
	var hits2 = physics.intersect_ray(get_viewport().get_mouse_position(), 
			get_viewport().get_mouse_position() + Vector2(16,0), [],
			0x7FFFFFFF, false, true)
	if hits1 or hits2:
		mouse_collide_big = true
	else:
		mouse_collide_big = false

func spawn_scene(link, name):
	var s = load(link).instance()
	s.name = name
	s.position = get_viewport().get_mouse_position() - Vector2(8,8)
	s.position = s.position.snapped(Vector2(16,16))
	$"..".add_child(s)
