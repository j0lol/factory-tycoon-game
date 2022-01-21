extends Node2D


# Declare member variables here. Examples:
var timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.connect("tick", self, "_on_Tick")
	

func _process(delta):
	if timer == 0:
		$RichTextLabel.text = "!"
	elif timer > 5:
		$RichTextLabel.text = ""
	timer += 1
	
func _on_Tick():
	timer = 0
