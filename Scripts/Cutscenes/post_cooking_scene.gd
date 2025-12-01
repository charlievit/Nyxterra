extends Node2D

@onready var mainGameScenePath = "res://Scenes/main.tscn"
@onready var blackScreen = $TextureRect
@onready var suthPlate = $Plate
@onready var elisePlate = $Plate2
var Dinner1 = preload("res://Assets/Images/KitchenPuzzle/dinner1.png")
var Dinner2 = preload("res://Assets/Images/KitchenPuzzle/dinner3.png")
var Dinner3 = preload("res://Assets/Images/KitchenPuzzle/dinnerrabbit.png")
var Dinner4 = preload("res://Assets/Images/KitchenPuzzle/dinner4.png")

func _ready():
	match GameManager.currentDay:
		1:
			suthPlate.texture = Dinner1
			elisePlate.texture = Dinner1
		2:
			suthPlate.texture = Dinner2
			elisePlate.texture = Dinner2
		3:
			suthPlate.texture = Dinner3
			elisePlate.texture = Dinner3
		4:
			suthPlate.texture = Dinner4
			elisePlate.texture = Dinner4
	
	TaskManager.shouldBeHidden = true
	TutorialManager.shouldBeHidden = true
	
	blackScreen.modulate.a = 0.0
	
	await get_tree().create_timer(3.0).timeout
	
	match GameManager.currentDay:
		1:
			Dialogic.start("Day_1 Kitchen Completed")
		2:
			Dialogic.start("Day_2 Kitchen Completed")
		3:
			Dialogic.start("Day_3 Kitchen Completed")
		4:
			Dialogic.start("Day_4 Kitchen Completed")
	
	await Dialogic.timeline_ended
	FadeToBlack()

func FadeToBlack():
	var tween = create_tween()
	
	tween.tween_property(blackScreen, "modulate:a", 1.0, 3.0)
	
	tween.tween_callback(EndScene)

func EndScene():
	if ResourceLoader.exists(mainGameScenePath):
		SceneLoader.change_scene_with_loading(mainGameScenePath)
	else:
		push_error("ERROR: Main game scene path not found.")
