extends Area2D

@onready var label: RichTextLabel = $ButtonPrompt
@onready var EliseCollision: CollisionShape2D = $CollisionShape2D
@onready var EliseTutorial: RichTextLabel = $ButtonPrompt
@onready var sprite = $".."

var baseLabelPos: Vector2
var playerBody: CharacterBody2D = null

var footStepsPlayer: AudioStreamPlayer2D
@onready var footStepsSound = preload("res://Assets/Audio/Player/SFX/Footstep.mp3")
var stepRightFoot: bool = false

func _ready():
	UpdateEliseState()

	# Connect signals
	self.body_entered.connect(OnBodyEntered)
	self.body_exited.connect(OnBodyExited)
	
	footStepsPlayer = AudioStreamPlayer2D.new()
	add_child(footStepsPlayer)
	footStepsPlayer.stream = footStepsSound
	footStepsPlayer.volume_db = -8.0
	
	if label:
		# Hide label and store its position for bobbing
		label.visible = false
		baseLabelPos = label.position
	else:
		push_error("ERROR: label missing")

func UpdateEliseState():
	match GameManager.currentDay:
		0:
			EliseCollision.scale = Vector2(0.3,0.7)
			EliseCollision.position = Vector2(27.384,10.695)
			EliseTutorial.scale = Vector2(1.282,1.282)
			EliseTutorial.position = Vector2(21.341,-73.721)
		1, 2, 3: 
			EliseCollision.scale = Vector2(1,1)
			EliseCollision.position = Vector2(-60.291,-29.374)
			EliseTutorial.scale = Vector2(3.365,3.365)
			EliseTutorial.position = Vector2(-43.78,-214.165)
		4, 5: 
			EliseCollision.scale = Vector2(0.2,0.4)
			EliseCollision.position = Vector2(-1.231,4.121)
			EliseTutorial.scale = Vector2(0.758,0.758)
			EliseTutorial.position = Vector2(-7.973,-45.317)

func _process(_delta):
	if GameManager.isNewDay and not GameManager.currentDay == 5:
		return
	
	if not GameManager.needDaughter:
		if label and label.visible:
			label.visible = false
		return
	
	# Animate the label
	if playerBody and label:
		# Bob up and down
		label.position.y = baseLabelPos.y + (sin(Time.get_ticks_msec() * 0.005) * 3.0)
	
	if playerBody and GameManager.needDaughter:
		if Input.is_action_just_pressed("ui_accept") and GameManager.needDaughter:
			GameManager.usedTalk = true
			GameManager.player.set_physics_process(false)
			
			if label:
				label.visible = false
			OnBodyExited(playerBody)
			
			#Dialogue system
			await Dialogue_system()
			
			GameManager.player.set_physics_process(true)
			
			var currentTask: String = ""
			for key in TaskManager.activeTasks.keys():
				if String(key).contains("Daughter"):
					currentTask = key
			
			if GameManager.currentDay > 3:
				await MoveElise()
			
			if currentTask != "":
				GameManager.CompleteTask(currentTask)
			else:
				print("WARNING: Elise talk finishes without task.") # DEBUG

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
			Dialogic.start("Day_5 Smell Dialogue")
	await Dialogic.timeline_ended

func MoveElise():
	var player = get_tree().get_first_node_in_group("player")
	player.controlsDisabled = true
	
	sprite.play("walk")
	sprite.flip_h = GetWalkDirection()
	sprite.scale = Vector2(0.350, 0.350)
	sprite.position.y += 4
	
	var tween = create_tween()
	tween.tween_property(sprite, "position:x", GetDirection(), GetDuration()).as_relative()
	tween.tween_callback(func():
		sprite.visible = false
		player.controlsDisabled = false)
	
	while sprite.visible:
		PlayFootStep()
		if not sprite.visible:
			break
		await get_tree().create_timer(0.6).timeout

func PlayFootStep():
	stepRightFoot = !stepRightFoot
	
	var basePitch = 2.0
	
	if stepRightFoot:
		footStepsPlayer.pitch_scale = basePitch + 0.1
	else:
		footStepsPlayer.pitch_scale = basePitch - 0.05
	
	footStepsPlayer.pitch_scale += randf_range(-0.05, 0.05)
	
	footStepsPlayer.play()

func GetDuration() -> float:
	match GameManager.currentDay:
		4:
			return 5.0
		5:
			return 4.0
		_:
			return 4.0

func GetDirection() -> float:
	match GameManager.currentDay:
		4:
			return -95.0 #left
		5:
			return 65.0 #right
		_:
			return 65.0

func GetWalkDirection() -> bool:
	match GameManager.currentDay:
		4:
			return true #left
		5: 
			return false #right
		_: 
			return false
