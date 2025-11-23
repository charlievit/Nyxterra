extends Control

var relationship: int
var yesterdaysRelationship: int
var morality: int
var yesterdaysMorality: int
var madeTheRightChoice: bool
var choiceText = "Tonight, you chose to "
var canProceed: bool = false

@onready var moralityLabel: RichTextLabel = $"Morality and Relationship Area/Morality Area (L)/Morality Score"
@onready var relationshipLabel: RichTextLabel = $"Morality and Relationship Area/Relationship Area (R)/Relationship Score"
@onready var continuePrompt: RichTextLabel = $"Continue Prompt"
@onready var choiceLabel: RichTextLabel = $"Choice Text"
@onready var choiceImage: TextureRect = $"Morality and Relationship Area/Morality Area (L)/Morality Image"

var mainGameScenePath: String = "res://Scenes/main.tscn"
var currentTaskID: String = ""

func _ready():
	TaskManager.shouldBeHidden = true
	
	for key in TaskManager.activeTasks.keys():
		if String(key).contains("_goToBed"):
			currentTaskID = key
	
	yesterdaysMorality = GameManager.yesterdaysMorality
	morality = GameManager.morality
	yesterdaysRelationship = GameManager.yesterdaysRelationship
	relationship = GameManager.relationship
	
	moralityLabel.text = str(yesterdaysMorality)
	relationshipLabel.text = str(yesterdaysRelationship)
	
	madeTheRightChoice = yesterdaysMorality < morality
	choiceImage.flip_h = madeTheRightChoice
	
	if GameManager.choseLightToBeOn:
		choiceText = "Tonight, you chose to turn the light on..."
	else:
		choiceText = "Tonight, you chose to keep the light off..."
	choiceLabel.text = choiceText
	
	continuePrompt.modulate.a = 0.0
	
	await get_tree().create_timer(1.0).timeout
	UpdateValues()

func UpdateValues():
	var tween = create_tween()
	# morality value counts up or down
	tween.tween_method(func(val):
		moralityLabel.text = str(int(val)), yesterdaysMorality, morality, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# short pause
	tween.tween_interval(1.0)
	# relationship value counts up or down
	tween.tween_method(func(val):
		relationshipLabel.text = str(int(val)), yesterdaysRelationship, relationship, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(AllowToProceed)

func AllowToProceed():
	canProceed = true
	var tween = create_tween()
	# slowly fade in the continue prompt
	tween.tween_property(continuePrompt, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	# then
	# slowly pulse the opacity from 100% to 25% and back until we proceed
	tween.finished.connect(StartPulsingPrompt)

func StartPulsingPrompt():
	var pulseTween = create_tween().set_loops()
	
	pulseTween.tween_property(continuePrompt, "modulate:a", 0.25, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulseTween.tween_property(continuePrompt, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _unhandled_input(event): # if any key is pressed, the game loads next day
	if canProceed and event.is_pressed():
		if event is InputEventKey or event is InputEventMouseButton:
			LoadNextDay()

func LoadNextDay():
	canProceed = false
	set_process_unhandled_input(false)
	
	GameManager.CompleteTask(currentTaskID)
	
	if ResourceLoader.exists(mainGameScenePath):
		SceneLoader.change_scene_with_loading(mainGameScenePath)
	else:
		push_error("ERROR: Main game scene path not found.")
