extends Node

var nextDayIndex: int = -1

var mainGameScenePath: String = "res://Scenes/main.tscn"
var goodEndMenuPath: String = "res://Scenes/UI/start_menu_good_end.tscn"
var badEndMenuPath: String = "res://Scenes/UI/start_menu_bad_end.tscn"

func PlayCutscene(cutscenePath: String, dayToStartAfter: int = -1):
	if dayToStartAfter != -1:
		nextDayIndex = dayToStartAfter
	
	get_tree().change_scene_to_file(cutscenePath)

func FinishCutscene():
	get_tree().change_scene_to_file(mainGameScenePath)

func EndGame():
	if GameManager.isBadEnding:
		if ResourceLoader.exists(badEndMenuPath):
			get_tree().change_scene_to_file(badEndMenuPath)
		else:
			get_tree().quit()
	else:
		if ResourceLoader.exists(goodEndMenuPath):
			get_tree().change_scene_to_file(goodEndMenuPath)
		else:
			get_tree().quit()

func CheckForPendingDayStart():
	if nextDayIndex != -1:
		GameManager.StartDay(nextDayIndex)
		nextDayIndex = -1
