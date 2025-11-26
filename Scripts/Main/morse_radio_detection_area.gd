extends Area2D

@onready var label: RichTextLabel = $ButtonPrompt

var baseLabelPos: Vector2
var playerBody: CharacterBody2D = null

@export var radioScenePath: String = "res://Scenes/RadioPuzzle/radio_interface.tscn"
@export var morseScenePath: String = "res://Scenes/Morse Code Puzzle/morse_puzzle.tscn"

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
		if Input.is_action_pressed("ui_accept") and GameManager.needMorse:
			Morse_Dialogue()
			await Dialogic.timeline_ended
			if ResourceLoader.exists(morseScenePath):
				SceneLoader.change_scene_with_loading(morseScenePath)
			else:
				push_error("ERROR: Morse game scene path not found.")
		if Input.is_action_pressed("radio_accept") and GameManager.needRadio:
			Radio_Dialogue()
			await Dialogic.timeline_ended
			if ResourceLoader.exists(radioScenePath):
				SceneLoader.change_scene_with_loading(radioScenePath)
			else:
				push_error("ERROR: Radio game scene path not found.")
				
func OnBodyEntered(body):
	if body.is_in_group("player"):
		if GameManager.needRadio or GameManager.needMorse:
			playerBody = body # Store the player
			if label:
				label.visible = true

func OnBodyExited(body):
	if body.is_in_group("player"):
		playerBody = null # Clear the player
		if label:
			label.visible = false

func Morse_Dialogue() -> void:
	match GameManager.currentDay:
		-1:
			Dialogic.start("Day_-1 Morse Dialogue")
		0:
			Dialogic.start("Day_0 Morse Dialogue")
		1:
			Dialogic.start("Day_1 Morse Dialogue")
		2:
			Dialogic.start("Day_2 Morse Dialogue")
		3:
			Dialogic.start("Day_3 Morse Dialogue")
		4:
			Dialogic.start("Day_4 Morse Dialogue")

func Radio_Dialogue() -> void:
	match GameManager.currentDay:
		-1:
			Dialogic.start("Day_-1 Radio Dialogue")
		0:
			Dialogic.start("Day_0 Radio Dialogue")
		1:
			Dialogic.start("Day_1 Radio Dialogue")
		2:
			Dialogic.start("Day_2 Radio Dialogue")
		3:
			Dialogic.start("Day_3 Radio Dialogue")
		4:
			Dialogic.start("Day_4 Radio Dialogue")
