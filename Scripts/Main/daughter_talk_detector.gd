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
	if not GameManager.needDaughter:
		return
	
	# Animate the label
	if playerBody and label:
		# Bob up and down
		label.position.y = baseLabelPos.y + (sin(Time.get_ticks_msec() * 0.005) * 3.0)
	
	if playerBody and GameManager.needDaughter:
		if Input.is_action_pressed("ui_accept") and GameManager.needDaughter:
			GameManager.usedTalk = true
			GameManager.player.set_physics_process(false)
			OnBodyExited(playerBody)
			#Dialogue system
			await Dialogue_system()
			GameManager.player.set_physics_process(true)
			var currentTask: String = ""
			for key in TaskManager.activeTasks.keys():
				if String(key).contains("Daughter"):
					currentTask = key
			GameManager.CompleteTask(currentTask)

func OnBodyEntered(body):
	if body.is_in_group("player"):
		playerBody = body # Store the player
		if (body.is_in_group("player") and GameManager.needDaughter and not GameManager.usedTalk) or (body.is_in_group("player") and GameManager.needDaughter and GameManager.tutorialMode):
			label.visible = true

func OnBodyExited(body):
	if body == null:
		return
	
	if body.is_in_group("player"):
		playerBody = null # Clear the player
		if label:
			label.visible = false

func Dialogue_system() -> void:
	match GameManager.currentDay:
		0:
			Dialogic.start("Day_0 Elise Dialogue")
		1:
			Dialogic.start("Day_1 Elise Dialogue")
		2:
			Dialogic.start("Day_2 Elise Dialogue")
		3:
			Dialogic.start("Day_3 Elise Dialogue")
		4:
			Dialogic.start("Day_4 Elise Dialogue")
		5: #end game good ending
			Dialogic.start("Day_5 Elise Dialogue")
	await Dialogic.timeline_ended
