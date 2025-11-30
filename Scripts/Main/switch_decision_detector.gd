extends Area2D

@onready var label: RichTextLabel = $ButtonPrompt
@onready var switch: AnimatedSprite2D = $".."

var baseLabelPos: Vector2
var playerBody: CharacterBody2D = null

var hasBeenPrompted = false
var activePopUp: Control = null

var currentTaskID: String = ""

func _ready():
	for key in TaskManager.activeTasks.keys():
		if String(key).contains("decision"):
			currentTaskID = key
			break
	
	# Connect signals
	
	self.body_entered.connect(OnBodyEntered)
	self.body_exited.connect(OnBodyExited)
	Dialogic.signal_event.connect(_On_Switch_Pressed)
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
		if Input.is_action_just_pressed("ui_accept") and GameManager.needLight:
			GameManager.usedKitchen = true
			#Dialogue system
			GameManager.player.set_physics_process(false)
			OnBodyExited(playerBody)
			await Dialogue_system()
			GameManager.player.set_physics_process(true)
			
			if hasBeenPrompted:
				return
			
			#SpawnDecisionPopUp()

func OnBodyEntered(body):
	if body.is_in_group("player"):
		playerBody = body # Store the player
	if (body.is_in_group("player") and GameManager.needLight and not hasBeenPrompted and not GameManager.usedSwitch) or (body.is_in_group("player") and GameManager.needLight and not hasBeenPrompted and GameManager.tutorialMode):
		if label:
			label.visible = true

func OnBodyExited(body):
	if body.is_in_group("player"):
		playerBody = null # Clear the player
		if label:
			label.visible = false

func SpawnDecisionPopUp():
	hasBeenPrompted = true
	
	playerBody.controlsDisabled = true
	label.visible = false
	
	var uiLayer = get_tree().current_scene.find_child("Control_GAME SCREEN UI", true, false)
	
	if uiLayer:
		uiLayer.add_child(activePopUp)
		
		# 4. Connect the buttons
		var yesButton = activePopUp.get_node("YesButton")
		var noButton = activePopUp.get_node("NoButton")
		
		if yesButton: yesButton.pressed.connect(OnYesPressed)
		if noButton: noButton.pressed.connect(OnNoPressed)

func OnYesPressed():
	#ClosePopUp()
	if switch:
		switch.play("turnOn") 
	GameManager.CompleteTask(currentTaskID)

func OnNoPressed():
	# Close everything up
	#ClosePopUp()
	GameManager.CompleteTask(currentTaskID)

func ClosePopUp():
	if activePopUp:
		activePopUp.queue_free()
		activePopUp = null
	
	if playerBody:
		playerBody.controlsDisabled = false

func Dialogue_system() -> void:
	match GameManager.currentDay:
		0:
			Dialogic.start("Day_0 Light Dialogue")
			OnNoPressed()
		1:
			Dialogic.start("Day_1 Light Dialogue")
		2:
			Dialogic.start("Day_2 Light Dialogue")
		3:
			Dialogic.start("Day_3 Light Dialogue")
		4:
			Dialogic.start("Day_4 Light Dialogue")
	await Dialogic.timeline_ended

func _On_Switch_Pressed(argument: String) -> void:
	if argument == "Yes":
		switch.play("turnOn") 
		GameManager.CompleteTask(currentTaskID)
		print("Yes")
	elif argument == "No":
		GameManager.CompleteTask(currentTaskID)
		print("No")
