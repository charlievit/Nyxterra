extends Area2D

@onready var label: RichTextLabel = $ButtonPrompt

var baseLabelPos: Vector2
var playerBody: CharacterBody2D = null

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
		if Input.is_action_pressed("ui_accept") and GameManager.needBed:
			GameManager.usedBed = true
			GameManager.set_physics_process(false)
			OnBodyExited(playerBody)
			await Dialogue_system()
			GameManager.set_physics_process(true)
			print("going to bed...")
			var currentTask: String = ""
			for key in TaskManager.activeTasks.keys():
				if String(key).contains("Bed"):
					currentTask = key
			GameManager.CompleteTask(currentTask)

func OnBodyEntered(body):
	if body.is_in_group("player") and GameManager.needBed:
		playerBody = body # Store the player
		if not GameManager.usedBed or GameManager.tutorialMode:
			if label:
				label.visible = true

func OnBodyExited(body):
	if body.is_in_group("player"):
		playerBody = null # Clear the player
		if label:
			label.visible = false

func Dialogue_system() -> void:
	match GameManager.currentDay:
		1:
			Dialogic.start("Day_1 Bed Dialogue")
		2:
			Dialogic.start("Day_2 Bed Dialogue")
		3:
			Dialogic.start("Day_3 Bed Dialogue")
		4:
			Dialogic.start("Day_4 Bed Dialogue")
		5: #end game good ending
			Dialogic.start("Day_5 Bed Dialogue")
	await Dialogic.timeline_ended
