extends Node2D

@onready var mainGameScenePath = "res://Scenes/main.tscn"
@onready var blackScreen = $TextureRect

func _ready():
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
