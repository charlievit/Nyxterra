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

func _ready() -> void:
	TutorialManager.shouldBeHidden = true
	TaskManager.shouldBeHidden = true
	
	steam.play("default")
	steam2.frame = 6
	steam2.play("default")
	
	match GameManager.currentDay:
		1: DinnerAsset.texture = Dinner1
		2: DinnerAsset.texture = Dinner2
		3: DinnerAsset.texture = Dinner3
		4: DinnerAsset.texture = Dinner4
	await get_tree().create_timer(1.5).timeout
	var tween = create_tween()
	tween.tween_method(func(val):
		GradeScore.text = str(int(val)), 0, GameManager.recipeQuality, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(2.0)
	tween.tween_callback(ProceedToDinnerScene)

func ProceedToDinnerScene():
	SceneLoader.change_scene_with_loading(pathToDinnerScene)
