# GameManager.gd
extends Node

#region VARIABLES
var playerSpawnFloor: int = 3 # defaul is floor 3...
var playerSpawnPosition: Vector2 = Vector2(88, 278) # near the bed (not global_position)
var shouldUseStoredSpawn: bool = false

var currentDay: int = 1 ## Default is 0 for beginning of the game
var needGearBox: bool = false # day 1
var needRadio: bool = false # day 
var needMorse: bool = false # day
var needDaughter: bool = false # day 0, 1, 2, 3
var needKitchen: bool = false # day 1-4
#endregion

func _ready():
	await get_tree().process_frame
	
	AssignDailyTasks(currentDay)

func AssignDailyTasks(day: int):
	match day:
		0:
			pass
		1:
			needGearBox = true
			needKitchen = true
			needRadio = true
			needMorse = true
			TaskManager.AddTask("oneTime_gearBox", "Check gearbox on 4th floor: 'The damn thing has been slippy since the attack...'")
			TaskManager.AddTask("daily_cookingMinigame", "Make your daughter dinner: 'Cooking hasn't been going well, I hope I can manage...")
			TaskManager.AddTask("daily_radioMinigame", "Check the radio.")
			TaskManager.AddTask("daily_morsecodeMinigame", "Send morsecode.")
		2:
			pass
		3:
			pass
		4:
			pass
		5:
			pass

func SetPlayerSpawn(targetFloor: int, targetPosition: Vector2):
	playerSpawnFloor = targetFloor
	playerSpawnPosition = targetPosition
	shouldUseStoredSpawn = true

func ConsumeSpawnData(playerNode):
	if shouldUseStoredSpawn:
		playerNode.global_position = playerSpawnPosition
		# Check if player has the SetFloor function before calling it
		if playerNode.has_method("SetFloor"):
			playerNode.SetFloor(playerSpawnFloor)
			print("Player floor set to %d, at x location: %d, and y location: %d" % [playerSpawnFloor, playerSpawnPosition.x, playerSpawnPosition.y])
		
		# Reset
		shouldUseStoredSpawn = false
