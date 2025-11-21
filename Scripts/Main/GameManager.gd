# GameManager.gd
extends Node

# Global reference to the player node
var player: Node = null

#region VARIABLES
var playerSpawnFloor: int = 3 # defaul is floor 3...
var playerSpawnPosition: Vector2 = Vector2(88, 278) # near the bed (not global_position)
var shouldUseStoredSpawn: bool = false

var currentDay: int = 0 ## Default is -1 for beginning of the game, is set to day 0 on NewDay()
var currentNight: int = 0
var needGearBox: bool = false # day 1
var needRadio: bool = false # all days
var needMorse: bool = false # all days
var needDaughter: bool = false # all days
var needKitchen: bool = false # day 1-4
var needLight: bool = false # day 1-4
#endregion

func _ready():
	await get_tree().process_frame
	
	NewDay()
	AssignDailyTasks(currentDay)

func NewDay():
	currentDay += 1
	playerSpawnFloor = 3 # defaul is floor 3...
	playerSpawnPosition= Vector2(88, 278) # near the bed (not global_position)
	
	needDaughter = false
	needRadio = false
	needMorse = false
	needGearBox = false
	needKitchen = false
	needLight = false

func AssignDailyTasks(day: int): # roughly putting plot into code here, will need more logic
	match day:
		0: # New game.
			# Start in bedroom
			needRadio = true
			needMorse = true
			needDaughter = true
			TaskManager.AddTask("dayZERO_checkDaughter", "Check on [DaughterName]")
			TaskManager.AddTask("dayZERO_checkRadio", "Check the radio")
			TaskManager.AddTask("dayZERO_checkMorse", "Check the morse code signal")
			#DayAdvancer(go to night)
			TaskManager.AddTask("nightZERO_checkMorse", "Check morse code")
			#StoryAdvancer(first attack)
			#OpeningCredits()
		1: # First day
			# Start in bedroom
			# Expositional monologue here
			needGearBox = true
			needKitchen = true
			needRadio = true
			needMorse = true
			needDaughter = true
			TaskManager.AddTask("dayONE_checkDaughter", "Check on [DaughterName]")
			TaskManager.AddTask("dayONE_checkRadio_beforeSmith", "Check the radio.")
			# Gearbox assignment from Smith
			TaskManager.AddTask("dayONE_oneTimeGearBoxPuzzle", "Check gearbox on 4th floor: 'The damn thing has been slippy since the attack...'")
			TaskManager.AddTask("dayONE_checkRadio_afterGearbox", "Check with Smith on the radio.")
			TaskManager.AddTask("dayONE_checkMorse", "Send morsecode.")
			# Move to night
			needKitchen = true
			needLight = true
			# Recipe assignment: Tutorial, "BarfitStovies"
			TaskManager.AddTask("dayONE_cookMeal", "Make your daughter dinner: 'Cooking hasn't been going well, I hope I can manage...")
			TaskManager.AddTask("dayONE_decision", "Decide if the light should be on or off.")
			TaskManager.AddTask("dayONE_goToBed", "Go to bed.")
			# Sleep screen (Morality and relationship)
		2:
			# Start in bedroom
			needDaughter = true
			needRadio = true
			needMorse = true
			TaskManager.AddTask("dayTWO_checkDaughter", "Check on [DaughterName]")
			TaskManager.AddTask("dayTWO_checkRadio", "Check radio.")
			TaskManager.AddTask("dayTWO_checkMorse", "Check the morse code signal.")
			# Move to night
			needKitchen = true
			needLight = true
			# Recipe assignment: Easy, "BraisedRoots"
			TaskManager.AddTask("dayTWO_cookMeal", "Make dinner.")
			TaskManager.AddTask("dayTWO_decision", "Decide if the light should be on or off.")
			TaskManager.AddTask("dayTWO_goToBed", "Go to bed.")
			# Sleep screen
		3:
			# Start in bedroom
			needDaughter = true
			needRadio = true
			needMorse = true
			TaskManager.AddTask("dayTHREE_checkDaughter", "Check on [DaughterName]")
			TaskManager.AddTask("dayTHREE_checkRadio", "Check radio.")
			TaskManager.AddTask("dayTHREE_checkMorse", "Check the morse code signal.")
			# Move to night
			needKitchen = true
			needLight = true
			# Recipe assignment: Moderate, "ScotchTattieSoup"
			TaskManager.AddTask("dayTHREE_cookMeal", "Make dinner.")
			TaskManager.AddTask("dayTHREE_decision", "Decide if the light should be on or off.")
			TaskManager.AddTask("dayTHREE_goToBed", "Go to bed.")
			# Sleep screen
		4:
			# Start in bedroom
			needDaughter = true
			needRadio = true
			needMorse = true
			TaskManager.AddTask("dayFOUR_checkDaughter", "Check on [DaughterName]")
			TaskManager.AddTask("dayFOUR_checkRadio", "Check radio.")
			TaskManager.AddTask("dayFOUR_checkMorse", "Check the morse code signal.")
			# Move to night
			needKitchen = true
			needLight = true
			# Recipe assignment: Hard, "RabbitStew"
			TaskManager.AddTask("dayFOUR_cookMeal", "Make dinner.")
			TaskManager.AddTask("dayFOUR_decision", "Decide if the light should be on or off.")
			TaskManager.AddTask("dayFOUR_goToBed", "Go to bed.")
			# Sleep screen
		5:
			#BAD END
			# Play audio
			# end game
			
			# GOOD END
			TaskManager.AddTask("finalDay_checkDaughter", "Someone is cooking, it smells amazing...")
			# Dialogue
			TaskManager.AddTask("finalDay_openLockbox", "Find the code to open the lockbox.")
			TaskManager.AddTask("finalDay_readLetter", "Read the letter.")
			# end game

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
		
#save & load
func write_save_data() -> void:
	# Copy GameManager runtime state into SaveData
	var data := SaveManager.current_save

	data.current_day = currentDay
	data.current_night = currentNight

	data.need_gear_box = needGearBox
	data.need_radio = needRadio
	data.need_morse = needMorse
	data.need_daughter = needDaughter
	data.need_kitchen = needKitchen
	data.need_light = needLight


func apply_save_data() -> void:
	# Read from SaveData back into GameManager
	var data := SaveManager.current_save

	currentDay = data.current_day
	currentNight = data.current_night

	needGearBox = data.need_gear_box
	needRadio = data.need_radio
	needMorse = data.need_morse
	needDaughter = data.need_daughter
	needKitchen = data.need_kitchen
	needLight = data.need_light
	
