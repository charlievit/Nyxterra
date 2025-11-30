extends Node

#region ENUMS
enum DayState {
	SUN_RISING,
	DAY_IDLE,
	NIGHT_FADING,
	MOON_RISING,
	NIGHT_IDLE
}

enum ReturnSource { NONE, RADIO, MORSE, KITCHEN, GEARBOX }
#endregion

var completedTutorials: Dictionary = {}
var tutorialMode = false

#region SIGNALS
signal requestDayCycle
signal requestNightCycle
#endregion

#region VARIABLES
var playerSpawnFloor: int = 3
var playerSpawnPosition: Vector2 = Vector2(88, 278)
var shouldUseStoredSpawn: bool = false

var currentDay: int = 2
var isNewDay: bool = false
var daySTATE: DayState = DayState.NIGHT_IDLE
var currentTaskStep: int = 0 

# GLOBAL NEEDS
var needGearBox: bool = false
var needRadio: bool = false 
var needMorse: bool = false 
var needDaughter: bool = false 
var needKitchen: bool = false 
var needLight: bool = false
var needBed: bool = false
var needLockbox: bool = false

# GLOBAL ENDING VARIABLES
var yesterdaysMorality: int = 0
var morality: int = 0
var moralityNeeded: int = 50 
var yesterdaysRelationship: int = 50
var relationship: int = 50
var isBadEnding: bool = false
var shouldLightBeOnTonight: bool = false
var choseLightToBeOn: bool = false

# COOKING
var todaysRecipe: String
var recipeQuality: int

# CUTSCENES / DIALOGUE
var introPlayed: bool = false
var usedStairs: bool = false
var usedRadio: bool = false
var usedMorse: bool = false
var usedKitchen: bool = false
var usedSwitch: bool = false
var usedTalk: bool = false
var usedBed: bool = false
var usedMovement: bool = false
var usedMorseClicker: bool = false
var introScenePlayed: bool = false
var isIntroPlayed: bool = false # Dialogue flag
var pending_post_source: int = ReturnSource.NONE
var load_from_save_next_main: bool = false
var smithTalkedToDay1: bool = false
var gearBoxSolved: bool = false
var chopSpeakCooldown = 50

var player: Node = null

@onready var musicPlayer: AudioStreamPlayer = AudioStreamPlayer.new()
var backgroundMusic123: AudioStream = preload("res://Assets/Audio/Music/day1 2 and 3music.mp3")
var backgroundMusic045: AudioStream = preload("res://Assets/Audio/Music/Day 0 4 and 5 if good end.mp3")

# MUSIC
var music1 = preload("res://Assets/Audio/Music/Music 1 lighthouse.wav")
var kitchenThemeMusic = preload("res://Assets/Audio/Music/kitchen minigame idea.wav")
var radioThemeMusic = preload("res://Assets/Audio/Music/Radio theme.wav")

var LightKeeperMusic = preload("res://Assets/Audio/Music/Light keeper.mp3")
#endregion

func _ready():
	todaysRecipe = "BarfitStovies" 
	await get_tree().process_frame
	# Auto-load if needed, otherwise wait for StartNewGame
	
func StartNewGame():
	# Reset all internal state
	currentDay = 2
	currentTaskStep = 0
	
	isIntroPlayed = false
	introPlayed = false
	introScenePlayed = false
	
	load_from_save_next_main = false
	pending_post_source = ReturnSource.NONE
	shouldUseStoredSpawn = false
	
	relationship = 50
	yesterdaysRelationship = 50
	
	ResetDailyFlags()
	TaskManager.CompleteDay()
	
	daySTATE = DayState.SUN_RISING
	todaysRecipe = "BarfitStovies"
	
	morality = 0
	relationship = 0
	isBadEnding = false
	
	# Start Day 0 Gameplay directly
	StartDay(0)

func StartDay(day: int):
	print("GAMEMANAGER: Starting Day ", day)
	currentDay = day
	isNewDay = true
	currentTaskStep = 0
	
	# Reset spawn to bedroom for a new day
	playerSpawnFloor = 3 
	playerSpawnPosition = Vector2(88, 278)
	shouldUseStoredSpawn = true
	
	# Start the day visually
	if currentDay == 5:
		daySTATE = DayState.DAY_IDLE
	else:
		daySTATE = DayState.SUN_RISING
	emit_signal("requestDayCycle")
	
	UpdateObjective()
	
	match currentDay:
		0, 4, 5:
			if not isBadEnding:
				add_child(musicPlayer)
				musicPlayer.stream = backgroundMusic045
				musicPlayer.autoplay = true
				musicPlayer.volume_db = -5.0
				musicPlayer.set_bus("Music")
				musicPlayer.play()
		1, 2, 3:
			add_child(musicPlayer)
			musicPlayer.stream = backgroundMusic123
			musicPlayer.autoplay = true
			musicPlayer.volume_db = -15.0
			musicPlayer.set_bus("Music")
			musicPlayer.play()

func ResetDailyFlags():
	usedTalk = false
	usedRadio = false
	usedMorse = false
	usedKitchen = false
	usedSwitch = false
	usedBed = false
	usedStairs = false

func CompleteTask(task_id: String):
	TaskManager.CompleteTask(task_id)
	currentTaskStep += 1
	UpdateObjective()

func AddCookingScore(quality: int):
	recipeQuality = quality
	# Relationship increases by an amount equal to the recipe quality /10 rounded up
	var increase = ceil(quality / 10.0)
	if currentDay == 3: # double relationship bonus for making Elise's favorite meal
		increase *= 2
	yesterdaysRelationship = relationship
	relationship += int(increase)
	print("Cooking Quality: %d. Relationship increased by %d. Total: %d" % [quality, increase, relationship])

func CheckMorality() -> int:
	yesterdaysMorality = morality
	match currentDay:
		1:
			if Dialogic.VAR.Day1_response == "Yes":
				morality += 25
		2:
			if Dialogic.VAR.Day2_response == "No":
				morality += 25
		3:
			if Dialogic.VAR.Day3_response == "Yes":
				morality += 25
		4:
			if Dialogic.VAR.Day4_responce == "No":
				morality += 25
	return morality

func UpdateObjective():
	# 1. Reset needs for the new step
	ResetNeeds()
	
	# 2. Check Day/Step
	match currentDay:
		0: # DAY 0: TUTORIAL
			match currentTaskStep:
				0:
					needDaughter = true
					TaskManager.AddTask("dayZERO_checkDaughter", "Check on Elise.")
				1:
					needRadio = true
					TaskManager.AddTask("dayZERO_checkRadio", "Check the radio.")
				2:
					# TRIGGER NIGHT
					emit_signal("requestNightCycle")
					daySTATE = DayState.NIGHT_FADING
					needMorse = true
					TaskManager.AddTask("nightZERO_checkMorse", "Check for morse code messages.")
				3:
					needLight = true
					TaskManager.AddTask("dayZERO_decision", "Turn off the Light")
				4:
					# END OF DAY 0 -> BOMBING CUTSCENE -> ARRIVAL -> DAY 1
					TaskManager.CompleteDay()
					introPlayed = true
					# We request Day 1 here. CutsceneManager will hold this index through the bombing AND arrival cutscenes.
					CutsceneManager.PlayCutscene("res://Scenes/Cutscenes/bombing_cutscene.tscn", 1)
					
		1: # DAY 1
			match currentTaskStep:
				0:
					needDaughter = true
					TaskManager.AddTask("dayONE_checkDaughter", "Check on Elise.")
				1:
					needRadio = true
					TaskManager.AddTask("dayONE_checkRadio_beforeSmith", "Check the radio.")
				2:
					needGearBox = true
					TaskManager.AddTask("dayONE_oneTimeGearBoxPuzzle", "Fix the gearbox (4th floor).")
				3:
					needRadio = true
					TaskManager.AddTask("dayONE_checkRadio_afterGearbox", "Report back to Smith.")
				4:
					needMorse = true
					TaskManager.AddTask("dayONE_checkMorse", "Check for morse code messages.")
				5:
					# NIGHT
					emit_signal("requestNightCycle")
					daySTATE = DayState.MOON_RISING
					needKitchen = true
					TaskManager.AddTask("dayONE_cookMeal", "Make dinner (Barfit Stovies).")
					todaysRecipe = "BarfitStovies"
				6:
					needLight = true
					TaskManager.AddTask("dayONE_decision", "Turn the light On or Off?")
				7:
					needBed = true
					TaskManager.AddTask("dayONE_goToBed", "Go to bed.")
				8:
					TaskManager.CompleteDay()
					StartDay(2)

		2: # DAY 2
			match currentTaskStep:
				0:
					needDaughter = true
					TaskManager.AddTask("dayTWO_checkDaughter", "Check on Elise.")
				1:
					needRadio = true
					TaskManager.AddTask("dayTWO_checkRadio", "Check radio.")
				2:
					needMorse = true
					TaskManager.AddTask("dayTWO_checkMorse", "Check for morse code messages.")
				3:
					emit_signal("requestNightCycle")
					daySTATE = DayState.MOON_RISING
					needKitchen = true
					TaskManager.AddTask("dayTWO_cookMeal", "Make dinner (Braised Roots).")
					todaysRecipe = "BraisedRoots"
				4:
					needLight = true
					TaskManager.AddTask("dayTWO_decision", "Light On or Off?")
				5:
					needBed = true
					TaskManager.AddTask("dayTWO_goToBed", "Go to bed.")
				6:
					TaskManager.CompleteDay()
					StartDay(3)

		3: # DAY 3
			match currentTaskStep:
				0:
					needDaughter = true
					TaskManager.AddTask("dayTHREE_checkDaughter", "Check on Elise.")
				1:
					needRadio = true
					TaskManager.AddTask("dayTHREE_checkRadio", "Check radio.")
				2:
					needMorse = true
					TaskManager.AddTask("dayTHREE_checkMorse", "Check for morse code messages.")
				3:
					emit_signal("requestNightCycle")
					daySTATE = DayState.MOON_RISING
					needKitchen = true
					TaskManager.AddTask("dayTHREE_cookMeal", "Make dinner (Scotch Tattie Soup).")
					todaysRecipe = "ScotchTattieSoup"
				4:
					needLight = true
					TaskManager.AddTask("dayTHREE_decision", "Light On or Off?")
				5:
					needBed = true
					TaskManager.AddTask("dayTHREE_goToBed", "Go to bed.")
				6:
					TaskManager.CompleteDay()
					StartDay(4)

		4: # DAY 4
			match currentTaskStep:
				0:
					needDaughter = true
					TaskManager.AddTask("dayFOUR_checkDaughter", "Check on Elise.")
				1:
					needRadio = true
					TaskManager.AddTask("dayFOUR_checkRadio", "Check radio.")
				2:
					needMorse = true
					TaskManager.AddTask("dayFOUR_checkMorse", "Check for morse code messages.")
				3:
					emit_signal("requestNightCycle")
					daySTATE = DayState.MOON_RISING
					needKitchen = true
					TaskManager.AddTask("dayFOUR_cookMeal", "Make dinner (Rabbit Stew).")
					todaysRecipe = "RabbitStew"
				4:
					needLight = true
					TaskManager.AddTask("dayFOUR_decision", "Light On or Off?")
				5:
					needBed = true
					TaskManager.AddTask("dayFOUR_goToBed", "Go to bed.")
				6:
					TaskManager.CompleteDay()
					StartDay(5)

		5: # DAY 5 (Endings)
			if isBadEnding:
				# Trigger Bad Ending Sequence
				# We loop back to bombing cutscene, but isBadEnding flag will trigger Game Over in the cutscene script
				GameManager.StopBGM()
				CutsceneManager.PlayCutscene("res://Scenes/Cutscenes/bombing_cutscene.tscn", -1)
			else:
				# GOOD ENDING FLOW
				match currentTaskStep:
					0:
						needDaughter = true
						TaskManager.AddTask("lastDay_checkDaughter", "Is someone cooking?")
					1:
						needLockbox = true
						TaskManager.AddTask("lastDay_openLockBox", "Find the code.")
					2:
						TaskManager.AddTask("lastDay_readLetter", "Read the letter.")
					3:
						# Trigger Credits / Victory Scene
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
		playerNode.position = playerSpawnPosition
		if playerNode.has_method("SetFloor"):
			playerNode.SetFloor(playerSpawnFloor)
		shouldUseStoredSpawn = false
		
func StopBGM():
	if musicPlayer.is_playing():
		musicPlayer.stop()

func PlayBGM():
	# If music is already playing, do nothing
	if musicPlayer.is_playing():
		return

	# Logic to determine which track to play based on the current day
	# This duplicates the logic from StartDay to ensure the right track is loaded and played.
	match currentDay:
		0, 4, 5:
			if not isBadEnding:
				musicPlayer.stream = backgroundMusic045
				musicPlayer.volume_db = -5.0
				musicPlayer.play()
		1, 2, 3:
			musicPlayer.stream = backgroundMusic123
			musicPlayer.volume_db = -15.0
			musicPlayer.play()

#save & load
func write_save_data() -> void:
	var data := SaveManager.current_save
	data.tutorial_mode = tutorialMode
	data.completed_tutorials = completedTutorials
	data.day_state = daySTATE
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
	data.pending_post_source = pending_post_source
	data.introPlayed = introPlayed
	data.introScenePlayed = introScenePlayed
	data.isIntroPlayed = isIntroPlayed
	data.task_data = TaskManager.get_save_data()
	
func apply_save_data() -> void:
	var data := SaveManager.current_save
	@warning_ignore("int_as_enum_without_cast")
	daySTATE = data.day_state
	tutorialMode = data.tutorial_mode
	completedTutorials = data.completed_tutorials
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
	introPlayed = data.introPlayed
	introScenePlayed = data.introScenePlayed
	pending_post_source = data.pending_post_source
	isIntroPlayed = data.isIntroPlayed
	
	if data.task_data.size() > 0:
		TaskManager.load_from_save(data.task_data)
	else:
		TaskManager.CompleteDay()
