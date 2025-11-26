extends Area2D

@onready var label: RichTextLabel = $ButtonPrompt

var baseLabelPos: Vector2
var playerBody: CharacterBody2D = null

@export var gearboxScenePath: String = "res://Scenes/GearPuzzle/gearbox_puzzle.tscn"

func _ready():
	# Connect signals
	self.body_entered.connect(OnBodyEntered)
	self.body_exited.connect(OnBodyExited)
	
	if label:
		# Hide label and store its position for bobbing
		label.visible = false
		baseLabelPos = label.position
	else:
		push_error("ERROR: label missing")

func _process(_delta):
	# Animate the label
	if playerBody and label:
		# Bob up and down
		label.position.y = baseLabelPos.y + (sin(Time.get_ticks_msec() * 0.005) * 3.0)
	
	if playerBody:
		if Input.is_action_pressed("ui_accept") and GameManager.needGearBox:
			Radio_Dialogue()
			await Dialogic.timeline_ended
			if ResourceLoader.exists(gearboxScenePath):
				SceneLoader.change_scene_with_loading(gearboxScenePath)
			else:
				push_error("ERROR: Main game scene path not found.")

func OnBodyEntered(body):
	if body.is_in_group("player") and GameManager.needGearBox:
		playerBody = body # Store the player
		if label:
			label.visible = true

func OnBodyExited(body):
	if body.is_in_group("player"):
		playerBody = null # Clear the player
		if label:
			label.visible = false

func Radio_Dialogue() -> void:
	match GameManager.currentDay:
		-1:
			Dialogic.start("Day_-1 GearBox Dialogue")
		0:
			Dialogic.start("Day_0 GearBox Dialogue")
		1:
			Dialogic.start("Day_1 GearBox Dialogue")
		2:
			Dialogic.start("Day_2 GearBox Dialogue")
		3:
			Dialogic.start("Day_3 GearBox Dialogue")
		4:
			Dialogic.start("Day_4 GearBox Dialogue")
	
