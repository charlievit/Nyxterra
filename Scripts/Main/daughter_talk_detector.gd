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
		if Input.is_action_pressed("ui_accept") and GameManager.needDaughter:
			#Dialogue system
			Dialogue_system()
			
			var currentTask: String = ""
			for key in TaskManager.activeTasks.keys():
				if String(key).contains("Daughter"):
					currentTask = key
			GameManager.CompleteTask(currentTask)
			OnBodyExited(playerBody)

func OnBodyEntered(body):
	if body.is_in_group("player") and GameManager.needDaughter:
		playerBody = body # Store the player
		if label:
			label.visible = true

func OnBodyExited(body):
	if body.is_in_group("player"):
		playerBody = null # Clear the player
		if label:
			label.visible = false

func Dialogue_system() -> void:
	var dlg
	var dlg_parent = get_tree().get_root().get_node("Main")
	match GameManager.currentDay:
		-1:
			dlg = Dialogic.start("Day_0 Elise Dialogue")
		0:
			dlg = Dialogic.start("Day_0 Elise Dialogue")
		1:
			dlg = Dialogic.start("Day_1 Elise Dialogue")
		2:
			dlg = Dialogic.start("Day_2 Elise Dialogue")
		3:
			dlg = Dialogic.start("Day_3 Elise Dialogue")
		4:
			dlg = Dialogic.start("Day_4 Elise Dialogue")
	dlg_parent.add_child(dlg)
