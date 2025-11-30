extends Node2D

@onready var mainGameScenePath = "res://Scenes/main.tscn"

func _ready():
	TaskManager.shouldBeHidden = true
	TutorialManager.shouldBeHidden = true
	
	await get_tree().create_timer(6.0).timeout
	
	match GameManager.currentDay:
		1:
			Dialogic.start("Day_1 Kitchen Completed")
		2:
			Dialogic.start("Day_2 Kitchen Completed")
		3:
			Dialogic.start("Day_3 Kitchen Completed")
		4:
			Dialogic.start("Day_4 Kitchen Completed")
	
	await Dialogic.end_timeline()
	
	if ResourceLoader.exists(mainGameScenePath):
		SceneLoader.change_scene_with_loading(mainGameScenePath)
	else:
		push_error("ERROR: Main game scene path not found.")
