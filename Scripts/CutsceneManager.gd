extends Node

var nextDayIndex: int = -1

var mainGameScenePath: String = "res://Scenes/main.tscn"

func PlayCutscene(cutscenePath: String, dayToStartAfter: int = -1):
	nextDayIndex = dayToStartAfter
	get_tree().change_scene_to_file(cutscenePath)

func FinishCutscene():
	get_tree().change_scene_to_file(mainGameScenePath)

func CheckForPendingDayStart():
	if nextDayIndex != -1:
		GameManager.StartDay(nextDayIndex)
		nextDayIndex = -1
