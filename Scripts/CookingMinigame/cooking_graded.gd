extends Control

@onready var GradeScore = $Score
@onready var DinnerAsset = $Dinner1
@onready var steam = $Steam
@onready var steam2 = $Steam2

var Dinner1 = preload("res://Assets/Images/KitchenPuzzle/dinner1.png")
var Dinner2 = preload("res://Assets/Images/KitchenPuzzle/dinner3.png")
var Dinner3 = preload("res://Assets/Images/KitchenPuzzle/dinnerrabbit.png")
var Dinner4 = preload("res://Assets/Images/KitchenPuzzle/dinner4.png")

var pathToDinnerScene: String = "res://Scenes/Cutscenes/post_cooking_scene.tscn"
var pathToKitchenRetry: String = "res://Scenes/Kitchen Puzzle/kitchen_puzzle.tscn"

var counterSound: AudioStream = preload("res://Assets/Audio/Cutscenes/SpinNoise.mp3")
var counterSoundPlayer: AudioStreamPlayer = AudioStreamPlayer.new()

var currentTaskID

func _ready() -> void:
	TutorialManager.shouldBeHidden = true
	TaskManager.shouldBeHidden = true
	
	if GameManager.recipeQuality < 0:
		GameManager.recipeQuality = 0
	
	for key in TaskManager.activeTasks.keys():
		if String(key).contains("_cookMeal"):
			currentTaskID = key
	
	add_child(counterSoundPlayer)
	counterSoundPlayer.stream = counterSound
	counterSoundPlayer.volume_db = -20.0
	
	steam.play("default")
	steam2.frame = 6
	steam2.play("default")
	
	match GameManager.currentDay:
		1: DinnerAsset.texture = Dinner1
		2: DinnerAsset.texture = Dinner2
		3: DinnerAsset.texture = Dinner3
		4: DinnerAsset.texture = Dinner4
	await get_tree().create_timer(1.5).timeout
	
	if not GameManager.recipeQuality == 0:
		counterSoundPlayer.play()
		
		var tween = create_tween()
		tween.tween_method(func(val):
			GradeScore.text = str(int(val)), 0, GameManager.recipeQuality, 4.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_interval(2.0)
		tween.tween_callback(CheckFailure)
	else:
		CheckFailure()

func CheckFailure():
	if GameManager.recipeQuality <= 50:
		Dialogic.start("FailureState")
		
		await Dialogic.timeline_ended
		
		if Dialogic.VAR.wantsRetry:
			SceneLoader.change_scene_with_loading(pathToKitchenRetry)
		else:
			ProceedToDinnerScene()
	else:
		ProceedToDinnerScene()

func ProceedToDinnerScene():
	GameManager.CompleteTask(currentTaskID)
	SceneLoader.change_scene_with_loading(pathToDinnerScene)
