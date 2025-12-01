extends Area2D

@onready var label: RichTextLabel = $ButtonPrompt

var baseLabelPos: Vector2
var playerBody: CharacterBody2D = null
var hasEntered: bool = false

@export var kitchenScenePath: String = "res://Scenes/Kitchen Puzzle/kitchen_puzzle.tscn"

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
		if Input.is_action_pressed("ui_accept") and GameManager.needKitchen:
			GameManager.usedKitchen = true
			if ResourceLoader.exists(kitchenScenePath):
				SceneLoader.change_scene_with_loading(kitchenScenePath)
				GameManager.StopBGM()
			else:
				push_error("ERROR: Main game scene path not found.")

func OnBodyEntered(body):
	if body.is_in_group("player"):
		playerBody = body # Store the player
		if GameManager.needKitchen:
			if GameManager.tutorialMode:
				label.visible = true
			elif not GameManager.usedKitchen:
				label.visible = true

func OnBodyExited(body):
	if body.is_in_group("player"):
		playerBody = null # Clear the player
		if label:
			label.visible = false
