extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var delta
export var _item=22
var items = [
	"gear-copper",
	"gear-gold",
	"gear-iron",
	"item-battery",
	"item-belt",
	"item-circuit",
	"item-copper",
	"item-energy",
	"item-fire",
	"item-gold",
	"item-iron",
	"item-machine",
	"item-wood",
	"item-wrench",
	"liquid-oil",
	"liquid-water",
	"plate-copper",
	"plate-gold",
	"plate-iron",
	"plate-plastic",
	"wire-copper",
	"wire-fiberoptic",
	"wire-red"
]

var root
# Called when the node enters the scene tree for the first time.
func _ready():
	get_child(0).texture = load("res://images/"+items[_item]+".png")
	EventBus.connect("tick", self, "_on_Tick")
	root = get_parent().root
	print(get_parent())



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(d):
	delta = d

onready var tween = $Tween
onready var ray = $RayCast2D

func _on_Tick():
	var map = root.get_node("TileMap")
	var coords = map.world_to_map(Vector2(global_position.x, global_position.y))
	if map.get_cell(coords.x, coords.y) == 0:
		var rot
		match [map.is_cell_x_flipped(coords.x, coords.y), map.is_cell_y_flipped(coords.x, coords.y), map.is_cell_transposed(coords.x, coords.y)]:
			[false, false, false]: rot = Vector2.RIGHT
			[false, false, true]: rot = Vector2.DOWN
			[true,  true,  false]: rot = Vector2.LEFT
			[true,  true,  true]: rot = Vector2.UP
			_: return
		
		move(rot)

	# item detects conveyor
	# item gets conveyor position
	# item moves

func move(dir):
	ray.cast_to = dir * global.tile_size
	ray.force_raycast_update()
	if !ray.is_colliding():
		move_tween(dir)
		
func move_tween(dir):
	tween.interpolate_property(self, "position",
		position, position + dir * global.tile_size,
		0.6/global.speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
