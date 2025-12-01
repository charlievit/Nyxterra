extends Control

# Variables for display logic
var relationshipStart: int
var relationshipEnd: int
var moralityStart: int
var moralityEnd: int

var madeTheRightChoice: bool = false
var choiceText: String = ""
var canProceed: bool = false

# UI References
@onready var moralityLabel: RichTextLabel = $"Morality and Relationship Area/Morality Area (L)/Morality Score"
@onready var relationshipLabel: RichTextLabel = $"Morality and Relationship Area/Relationship Area (R)/Relationship Score"
@onready var continuePrompt: RichTextLabel = $"Continue Prompt"
@onready var choiceLabel: RichTextLabel = $"Choice Text"
@onready var choiceImage: TextureRect = $"Morality and Relationship Area/Morality Area (L)/Morality Image"

var mainGameScenePath: String = "res://Scenes/main.tscn"

var countSound = preload("res://Assets/Audio/Cutscenes/SpinNoise.mp3")
var countSoundPlayer = AudioStreamPlayer.new()

func _ready():
	TaskManager.shouldBeHidden = true
	TutorialManager.shouldBeHidden = true
	
	add_child(countSoundPlayer)
	countSoundPlayer.stream = countSound
	countSoundPlayer.volume_db = -20.0
	
	moralityEnd = GameManager.CheckMorality() 
	moralityStart = GameManager.yesterdaysMorality
	
	relationshipEnd = GameManager.relationship
	relationshipStart = GameManager.yesterdaysRelationship

	moralityLabel.text = str(moralityStart)
	relationshipLabel.text = str(relationshipStart)
	
	DetermineDayText()
	
	choiceLabel.text = choiceText
	
	madeTheRightChoice = moralityEnd > moralityStart
	
	choiceImage.flip_h = madeTheRightChoice
	
	continuePrompt.modulate.a = 0.0
	
	# Start Animation after a short delay
	await get_tree().create_timer(1.0).timeout
	
	moralityStart = 0
	moralityEnd = 25
	
	relationshipStart = 50
	relationshipEnd = 60
	
	UpdateValues()

func DetermineDayText():
	match GameManager.currentDay:
		1:
			if Dialogic.VAR.Day1_response == "Yes":
				choiceText = "Tonight, you chose to turn the light on..."
			else:
				choiceText = "Tonight, you chose to keep the light off..."
		2:
			if Dialogic.VAR.Day2_response == "No":
				choiceText = "Tonight, you chose to keep the light off..."
			else:
				choiceText = "Tonight, you chose to turn the light on..."
		3:
			if Dialogic.VAR.Day3_response == "Yes":
				choiceText = "Tonight, you chose to turn the light on..."
			else:
				choiceText = "Tonight, you chose to keep the light off..."
		4:
			if Dialogic.VAR.Day4_response == "No":
				choiceText = "Tonight, you chose to keep the light off..."
			else:
				choiceText = "Tonight, you chose to turn the light on..."
		_:
			choiceText = "Tonight, the night passes..."

func UpdateValues():
	var tween = create_tween()
	if moralityStart != moralityEnd:
		countSoundPlayer.play()
	
	tween.tween_method(func(val):
		moralityLabel.text = str(int(val)), 
		moralityStart, 
		moralityEnd, 
		4.2
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_interval(0.5)
	
	tween.tween_callback(func():
		if relationshipStart != relationshipEnd:
			countSoundPlayer.play())
	
	tween.tween_method(func(val):
		relationshipLabel.text = str(int(val)), 
		relationshipStart, 
		relationshipEnd, 
		4.2
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(AllowToProceed)

func AllowToProceed():
	canProceed = true
	var tween = create_tween()
	# Fade in "Press any key" prompt
	tween.tween_property(continuePrompt, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(StartPulsingPrompt)

func StartPulsingPrompt():
	var pulseTween = create_tween().set_loops()
	pulseTween.tween_property(continuePrompt, "modulate:a", 0.25, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulseTween.tween_property(continuePrompt, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _unhandled_input(event):
	if canProceed and event.is_pressed():
		if event is InputEventKey or event is InputEventMouseButton:
			LoadNextDay()

func LoadNextDay():
	canProceed = false
	set_process_unhandled_input(false)
	
	for key in TaskManager.activeTasks.keys():
		if String(key).contains("goToBed"):
			TaskManager.CompleteTask(key)
	
	GameManager.StartDay(GameManager.currentDay + 1)
	
	if ResourceLoader.exists(mainGameScenePath):
		SceneLoader.change_scene_with_loading(mainGameScenePath)
	else:
		push_error("ERROR: Main game scene path not found.")
