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
			GameManager.usedMorse = true
			if ResourceLoader.exists(morseScenePath):
				SceneLoader.change_scene_with_loading(morseScenePath)
			else:
				push_error("ERROR: Morse game scene path not found.")
		if Input.is_action_pressed("ui_accept") and GameManager.needRadio:
			GameManager.usedRadio = true
			GameManager.player.set_physics_process(false)
			self.set_process(false)
			OnBodyExited(playerBody)
			await Radio_Dialogue()
			self.set_process(true)
			GameManager.player.set_physics_process(true)
			
			if GameManager.gearBoxSolved and GameManager.currentDay == 1:
				Dialogic.start("Day_1 Smith Dialogue")
				var currentTaskID
				for key in TaskManager.activeTasks.keys():
					if String(key).contains("afterGearbox"):
						currentTaskID = key
				GameManager.CompleteTask(currentTaskID)
				return # don't play minigame
			
			if ResourceLoader.exists(radioScenePath):
				SceneLoader.change_scene_with_loading(radioScenePath)
			else:
				push_error("ERROR: Radio game scene path not found.")
				
func OnBodyEntered(body):
	if body.is_in_group("player"):
		playerBody = body # Store the player
		if (GameManager.needRadio and not GameManager.usedRadio) or (GameManager.needRadio and GameManager.tutorialMode):
			if label:
				label.visible = true
		elif (GameManager.needMorse and not GameManager.usedMorse) or (GameManager.needMorse and GameManager.tutorialMode):
			if label:
				label.visible = true

func OnBodyExited(body):
	if body.is_in_group("player"):
		playerBody = null # Clear the player
		if label:
			label.visible = false

func Radio_Dialogue() -> void:
	match GameManager.currentDay:
		0:
			Dialogic.start("Day_0 Radio Dialogue")
			await Dialogic.timeline_ended
		1 or 2 or 3 or 4:
			return
	
