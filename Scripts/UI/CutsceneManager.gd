extends Node

var nextDayIndex: int = -1

var mainGameScenePath: String = "res://Scenes/main.tscn"
var mainMenuScenePath: String = "res://Scenes/UI/start_menu.tscn"

func PlayCutscene(cutscenePath: String, dayToStartAfter: int = -1):
	if dayToStartAfter != -1:
		nextDayIndex = dayToStartAfter
	
	get_tree().change_scene_to_file(cutscenePath)

func FinishCutscene():
	get_tree().change_scene_to_file(mainGameScenePath)

func EndGame():
	if ResourceLoader.exists(mainMenuScenePath):
		get_tree().change_scene_to_file(mainMenuScenePath)
	else:
		get_tree().quit()

func CheckForPendingDayStart():
	if nextDayIndex != -1:
		GameManager.StartDay(nextDayIndex)
		nextDayIndex = -1
