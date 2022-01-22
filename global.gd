extends Node

var in_ui = false

func _process(delta):
	if in_ui:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


var tile_size = 16
var speed = 3

var rotation = 0
var tile = -1

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
