# GameManager.gd
extends Node

#region ENUMS
enum DayState {
	SUN_RISING,
	DAY_IDLE,
	NIGHT_FADING,
	MOON_RISING,
	NIGHT_IDLE
}
#endregion

#region SIGNALS
signal requestDayCycle
signal requestNightCycle

signal showTutorialPopUp(tutorial_id: String)
#endregion

#region VARIABLES
var playerSpawnFloor: int = 3 # default floor is 3 (bedroom and office)
var playerSpawnPosition: Vector2 = Vector2(88, 278) # near the bed (not global_position)
var shouldUseStoredSpawn: bool = false

var currentDay: int = 0 # Starts at -1, becomes 0 on first NewGame
var daySTATE: DayState = DayState.NIGHT_IDLE
var currentTaskStep: int = 0 # Tracks progress WITHIN the day
var hasCompletedTutorial: bool = false # Tracks if Day 0 tips should show

# GLOBAL NEEDS
var needGearBox: bool = false
var needRadio: bool = false 
var needMorse: bool = false 
var needDaughter: bool = false 
var needKitchen: bool = false 
var needLight: bool = false
var needBed: bool = false

# GLOBAL ENDING VARIABLES
var morality: int = 0 # +25 for each correct choice
var moralityNeeded: int = 50 # none:0, 1:25, 2:50, 3:75, all:100
var relationship: int = 0
var isBadEnding: bool
var shouldLightBeOnTonight: bool

# COOKING
var todaysRecipe: String

#save/load
var player: Node = null
#endregion

func _ready():
	todaysRecipe = "BarfitStovies" # defaulting here for testing
	await get_tree().process_frame
	apply_save_data()
	
	StartDay(-1) #Since you forced to start on day -1, save&load unable to overwrite this. 
				 #Make sure it change to currentDay to able loading function 

func StartNewGame():
	# Reset internal variables
	currentDay = -1
	daySTATE = DayState.NIGHT_FADING # Force the correct start state
	todaysRecipe = "BarfitStovies"
	hasCompletedTutorial = false
	morality = 0
	relationship = 0
	isBadEnding = false
	
	# Start the logic for Day -1
	StartDay(-1)

func StartDay(day: int):
	currentDay = day
	currentTaskStep = 0
	
	playerSpawnFloor = 3 
	playerSpawnPosition = Vector2(88, 278)
	
	shouldUseStoredSpawn = true
	#ConsumeSpawnData(get_tree().get_first_node_in_group("player"))
	
	# Start the day visually
	daySTATE = DayState.NIGHT_FADING
	
	# Run the first task of the day
	UpdateObjective()

# Tasks need to call this function when interacted with
# GameManager.CompleteTask("dayZERO_checkDaughter")
func CompleteTask(task_id: String):
	#print("Task Complete: %s. Advancing Story." % task_id)
	TaskManager.CompleteTask(task_id)
	currentTaskStep += 1
	UpdateObjective()

func UpdateObjective():
	# FIRST. Reset all needs
	ResetNeeds()
	
	# SECOND. State machine to control the tasks for the day
	match currentDay:
		-1: # DEV TESTING DAY
			match currentTaskStep:
				0:
					needDaughter = true
					TaskManager.AddTask("test_checkDaughter", "(Test) Check on daughter.")
					if not hasCompletedTutorial:
						emit_signal("showTutorialPopUp", "movementTutorial")
				1:
					needRadio = true
					TaskManager.AddTask("test_checRadio", "(Test) Check radio.")
					if not hasCompletedTutorial:
						emit_signal("showTutorialPopUp", "radioTutorial")
				2:
					needGearBox = true
					TaskManager.AddTask("test_checkGearBox", "(Test) Check gearbox.")
					if not hasCompletedTutorial:
						emit_signal("showTutorialPopUp", "interactionTutorial")
				3:
					needMorse = true
					TaskManager.AddTask("test_checkMorse", "(Test) Check Morse.")
					if not hasCompletedTutorial:
						emit_signal("showTutorialPopUp", "morseTutorial")
				4:
					emit_signal("requestNightCycle")
					daySTATE = DayState.MOON_RISING
					needKitchen = true
					TaskManager.AddTask("test_cookMeal", "(Test) Kitchen Puzzle.")
					if not hasCompletedTutorial:
						emit_signal("showTutorialPopUp", "kitchenTutorial")
				5:
					needLight = true
					TaskManager.AddTask("test_decision", "(Test) Choose light switch position.")
					if not hasCompletedTutorial:
						emit_signal("showTutorialPopUp", "lightSwitchTutorial")
				6:
					needBed = true
					TaskManager.AddTask("test_goToBed", "(Test) End Day, Go To Bed.")
					if not hasCompletedTutorial:
						emit_signal("showTutorialPopUp", "endDayTutorial")
				7:
					TaskManager.CompleteDay()
					StartDay(currentDay + 1)
		0: # DAY 0: TUTORIAL
			match currentTaskStep:
				0:
					needDaughter = true
					TaskManager.AddTask("dayZERO_checkDaughter", "Check on [DaughterName]")
					if not hasCompletedTutorial:
						emit_signal("showTutorialPopUp", "movementTutorial")
				1:
					needRadio = true
					TaskManager.AddTask("dayZERO_checkRadio", "Check the radio on the 3rd floor.")
					if not hasCompletedTutorial:
						emit_signal("showTutorialPopUp", "interactionTutorial")
				2:
					needMorse = true
					TaskManager.AddTask("dayZERO_checkMorse", "Check the morse code signal")
					if not hasCompletedTutorial:
						emit_signal("showTutorialPopUp", "morseCodeTutorial")
				3:
					# TRIGGER NIGHT
					emit_signal("requestNightCycle")
					daySTATE = DayState.MOON_RISING
					needMorse = true
					TaskManager.AddTask("nightZERO_checkMorse", "Check morse code.")
				4:
					# Day 0 End
					# Bombing attack occurs
					pass
				5:
					TaskManager.CompleteDay()
					StartDay(1) 

		1: # DAY 1: FIRST REAL DAY
			match currentTaskStep:
				0:
					# Start in bedroom
					needDaughter = true
					TaskManager.AddTask("dayONE_checkDaughter", "Check on [DaughterName]")
				1:
					# Exposition
					needRadio = true
					TaskManager.AddTask("dayONE_checkRadio_beforeSmith", "Check the radio.")
				2:
					# Gearbox assignment
					needGearBox = true
					TaskManager.AddTask("dayONE_oneTimeGearBoxPuzzle", "Check gearbox on 4th floor.")
					if not hasCompletedTutorial:
						emit_signal("showTutoiralPopUp", "gearBoxTutorial")
				3:
					# Report back
					needRadio = true
					TaskManager.AddTask("dayONE_checkRadio_afterGearbox", "Check with Smith on the radio.")
				4:
					# Morse routine
					needMorse = true
					TaskManager.AddTask("dayONE_checkMorse", "Send morse code.")
				5:
					# TRIGGER NIGHT
					emit_signal("requestNightCycle")
					daySTATE = DayState.MOON_RISING
					needKitchen = true
					TaskManager.AddTask("dayONE_cookMeal", "Make your daughter dinner.")
					if not hasCompletedTutorial:
						emit_signal("showTutoiralPopUp", "cookingTutorial")
					todaysRecipe = "BarfitStovies"
				6:
					# Light decision
					needLight = true
					TaskManager.AddTask("dayONE_decision", "Decide if the light should be on or off.")
					if not hasCompletedTutorial:
						emit_signal("showTutoiralPopUp", "lightSwitchTutorial")
					hasCompletedTutorial = true # all tutorial messages have been shown
				7:
					# Bed
					TaskManager.AddTask("dayONE_goToBed", "Go to bed.")
				8:
					StartDay(2)

		2: # DAY 2
			match currentTaskStep:
				0:
					needDaughter = true
					TaskManager.AddTask("dayTWO_checkDaughter", "Check on [DaughterName]")
				1:
					needRadio = true
					TaskManager.AddTask("dayTWO_checkRadio", "Check radio.")
				2:
					needMorse = true
					TaskManager.AddTask("dayTWO_checkMorse", "Check the morse code signal.")
				3:
					# TRIGGER NIGHT
					emit_signal("requestNightCycle")
					daySTATE = DayState.MOON_RISING
					needKitchen = true
					TaskManager.AddTask("dayTWO_cookMeal", "Make dinner (Braised Roots).")
					todaysRecipe = "BraisedRoots"
				4:
					needLight = true
					TaskManager.AddTask("dayTWO_decision", "Decide on the light.")
				5:
					TaskManager.AddTask("dayTWO_goToBed", "Go to bed.")
				6:
					StartDay(3)

		3: # DAY 3
			match currentTaskStep:
				0:
					needDaughter = true
					TaskManager.AddTask("dayTHREE_checkDaughter", "Check on [DaughterName]")
				1:
					needRadio = true
					TaskManager.AddTask("dayTHREE_checkRadio", "Check radio.")
				2:
					needMorse = true
					TaskManager.AddTask("dayTHREE_checkMorse", "Check the morse code signal.")
				3:
					# TRIGGER NIGHT
					emit_signal("requestNightCycle")
					daySTATE = DayState.MOON_RISING
					needKitchen = true
					TaskManager.AddTask("dayTHREE_cookMeal", "Make dinner.")
					todaysRecipe = "ScotchTattieSoup"
				4:
					needLight = true
					TaskManager.AddTask("dayTHREE_decision", "Decide on the light.")
				5:
					TaskManager.AddTask("dayTHREE_goToBed", "Go to bed.")
				6:
					StartDay(4)

		4: # DAY 4
			match currentTaskStep:
				0:
					needDaughter = true
					TaskManager.AddTask("dayFOUR_checkDaughter", "Check on [DaughterName]")
				1:
					needRadio = true
					TaskManager.AddTask("dayFOUR_checkRadio", "Check radio.")
				2:
					needMorse = true
					TaskManager.AddTask("dayFOUR_checkMorse", "Check the morse code signal.")
				3:
					# TRIGGER NIGHT
					emit_signal("requestNightCycle")
					daySTATE = DayState.MOON_RISING
					needKitchen = true
					TaskManager.AddTask("dayFOUR_cookMeal", "Make dinner (Rabbit Stew).")
					todaysRecipe = "RabbitStew"
				4:
					needLight = true
					TaskManager.AddTask("dayFOUR_decision", "Decide on the light.")
				5:
					TaskManager.AddTask("dayFOUR_goToBed", "Go to bed.")
				6:
					StartDay(5)

		5: # DAY 5
			if isBadEnding:
				# Bad ending stuff here
				pass
			else:
				match currentTaskStep:
					0:
						needDaughter = true
						TaskManager.AddTask("lastDay_checkDaughter", "Is someone cooking?")
					1:
						TaskManager.AddTask("lastDay_openLockBox", "Find the code.")
					2:
						TaskManager.AddTask("lastDay_readLetter", "Read the letter.")
					3:
						# END GAME SCENES AND THEN CREDITS
						pass

func ResetNeeds():
	needDaughter = false
	needRadio = false
	needMorse = false
	needGearBox = false
	needKitchen = false
	needLight = false
	needBed = false

func SetPlayerSpawn(targetFloor: int, targetPosition: Vector2):
	playerSpawnFloor = targetFloor
	playerSpawnPosition = targetPosition
	shouldUseStoredSpawn = true

func ConsumeSpawnData(playerNode):
	if shouldUseStoredSpawn:
		playerNode.global_position = playerSpawnPosition
		if playerNode.has_method("SetFloor"):
			playerNode.SetFloor(playerSpawnFloor)
		shouldUseStoredSpawn = false
		
#save & load
func write_save_data() -> void:
	# Copy GameManager runtime state into SaveData
	var data := SaveManager.current_save
	
	data.day_state = daySTATE
	data.hasCompletedTutorial = hasCompletedTutorial
	data.current_day = currentDay
	data.currentTaskStep = currentTaskStep
	data.need_gear_box = needGearBox
	data.need_radio = needRadio
	data.need_morse = needMorse
	data.need_daughter = needDaughter
	data.need_kitchen = needKitchen
	data.need_light = needLight
	data.need_bed = needBed
	data.morality = morality
	data.morality_needed = moralityNeeded
	data.relationship = relationship
	data.should_light_be_on_tonight = shouldLightBeOnTonight

func apply_save_data() -> void:
	# Read from SaveData back into GameManager
	var data := SaveManager.current_save
	
	@warning_ignore("int_as_enum_without_cast")
	daySTATE = data.day_state
	hasCompletedTutorial = data.hasCompletedTutorial
	currentDay = data.current_day
	currentTaskStep = data.currentTaskStep
	needGearBox = data.need_gear_box
	needRadio = data.need_radio
	needMorse = data.need_morse
	needDaughter = data.need_daughter
	needKitchen = data.need_kitchen
	needLight = data.need_light
	needBed = data.need_bed
	morality = data.morality
	moralityNeeded = data.morality_needed
	relationship = data.relationship
	shouldLightBeOnTonight = data.should_light_be_on_tonight
