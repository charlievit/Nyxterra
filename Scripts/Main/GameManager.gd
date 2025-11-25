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
var yesterdaysMorality: int = 0
var morality: int = 1000 # +25 for each correct choice
var moralityNeeded: int = 50 # none:0, 1:25, 2:50, 3:75, all:100
var yesterdaysRelationship: int = 0
var relationship: int = 1000
var isBadEnding: bool
var shouldLightBeOnTonight: bool
var choseLightToBeOn: bool

# COOKING
var todaysRecipe: String

#save/load
var player: Node = null
#endregion

#region VOICE LINES
# ELISE
var dayZERO_daughterCheck2 = preload("res://Assets/Audio/VA/Elise/I’m Drawing a Rabbit.mp3") #audio blown out and loud, hopefully reducing volume will suffice
var dayZERO_cathDeathCry = preload("res://Assets/Audio/VA/Elise/Day 0 Crying.mp3") # will want to layer this on loop with other cathDeath VA line

var dayONE_daughterCheck2 = preload("res://Assets/Audio/VA/Elise/Im Tired Im Going to Sleep.mp3")
var dayONE_cookingGood = preload("res://Assets/Audio/VA/Elise/Not Bad Actually.mp3")
var dayONE_cookingBad = preload("res://Assets/Audio/VA/Elise/I Miss Mom.mp3")

var dayTWO_daughterCheck1 = preload("res://Assets/Audio/VA/Elise/Remember how she used to sing.mp3")
var dayTWO_cookingGood = preload("res://Assets/Audio/VA/Elise/Thanks Dad its actually really nice.mp3")
var dayTWO_cookingBad = preload("res://Assets/Audio/VA/Elise/I Think I’ll just go to Bed Early.mp3")

var dayTHREE_daughterCheck2 = preload("res://Assets/Audio/VA/Elise/Really.mp3")
var dayTHREE_daughterCheck4 = preload("res://Assets/Audio/VA/Elise/Thanks Dad.mp3")
var dayTHREE_cookingGood = preload("res://Assets/Audio/VA/Elise/It tastes just like when she used to make it.mp3")
var dayTHREE_cookingBad = preload("res://Assets/Audio/VA/Elise/It’s Ok Dad.mp3")

var dayFOUR_daughterCheck2 = preload("res://Assets/Audio/VA/Elise/Aye its a beautiful day.mp3")
var dayFOUR_daughterCheck4 = preload("res://Assets/Audio/VA/Elise/Thanks Dad.mp3")
var dayFOUR_cookingGood = preload("res://Assets/Audio/VA/Elise/Wow This is Delicious.mp3")
var dayFOUR_cookingBad = preload("res://Assets/Audio/VA/Elise/Take Out.mp3")

#var lastDay_goodEnding2 = preload("I made you breakfast") # VA LINE MISSING

# SUTHERLAND
var dayZERO_intro = preload("res://Assets/Audio/VA/Sutherland/Family holds steady.mp3")
var dayZERO_daughterCheck1 = preload("res://Assets/Audio/VA/Sutherland/wee lass.mp3") # a little loud, might need to reduce db on this one
var dayZERO_radioCheckStart = preload("res://Assets/Audio/VA/Sutherland/Never works the first time.mp3")
var dayZERO_smithTalk1 = preload("res://Assets/Audio/VA/Sutherland/wee hours with your mother.mp3")
var dayZERO_beforeMorseCheck = preload("res://Assets/Audio/VA/Sutherland/Cath must be making elises favorite.mp3") #will need to add *sniffs the air* to the subtitles in dialogic for this one
var dayZERO_afterMorseDecode = preload("res://Assets/Audio/VA/Sutherland/No no.mp3")
var dayZERO_cathDeath = preload("res://Assets/Audio/VA/Sutherland/Cath No.mp3")

var dayONE_daughterCheck1 = preload("res://Assets/Audio/VA/Sutherland/Elise Im Sorry.mp3") # will cut this short on "sorry" as Elise interrupts
var dayONE_radioCheck_talkToSelf = preload("res://Assets/Audio/VA/Sutherland/I cant do this today.mp3") #to be overlayed with dayONE_radioCheckSolved between lines
var dayONE_gearboxStart = preload("res://Assets/Audio/VA/Sutherland/neglecting you.mp3") #either play on minigame start or on body entered trigger
var dayONE_radioSmithBackAfterGearsFixed = preload("res://Assets/Audio/VA/Sutherland/Operational.mp3")
var dayONE_fishermanResponse = preload("res://Assets/Audio/VA/Sutherland/Light the Way.mp3")
var dayONE_onMorseFinish = preload("res://Assets/Audio/VA/Sutherland/Salty Lass.mp3")
var dayONE_turnLightOn = preload("res://Assets/Audio/VA/Sutherland/Not losing you to the sea.mp3")
var dayONE_leaveLightOff = preload("res://Assets/Audio/VA/Sutherland/I cant risk her life.mp3")
var dayONE_END_lightOn = preload("res://Assets/Audio/VA/Sutherland/I go on to remember her.mp3")
var dayONE_END_lightOff = preload("res://Assets/Audio/VA/Sutherland/I dont know who I am.mp3")

var dayTWO_daughterCheck2 = preload("res://Assets/Audio/VA/Sutherland/She should have been.mp3")
var dayTWO_radioCheck2 = preload("res://Assets/Audio/VA/Sutherland/American my Arse.mp3")
var dayTWO_radioCheck3 = preload("res://Assets/Audio/VA/Sutherland/heard over.mp3")
var dayTWO_morseCheck = preload("res://Assets/Audio/VA/Sutherland/Hmm Odd.mp3")
var dayTWO_turnLightOn = preload("res://Assets/Audio/VA/Sutherland/Cant do much harm.mp3")
var dayTWO_leaveLightOff = preload("res://Assets/Audio/VA/Sutherland/Nice try ye bastards.mp3")
var dayTWO_END_lightOn = preload("res://Assets/Audio/VA/Sutherland/Id protect elise with my life.mp3")
var dayTWO_END_lightOff = preload("res://Assets/Audio/VA/Sutherland/Im sorry Elise.mp3")

var dayTHREE_daughterCheck1 = preload("res://Assets/Audio/VA/Sutherland/Making your favorite.mp3")
var dayTHREE_daughterCheck3 = preload("res://Assets/Audio/VA/Sutherland/You deserve it.mp3") # little too loud
var dayTHREE_radioCheck2_talkToSelf = preload("res://Assets/Audio/VA/Sutherland/Container Ship.mp3")
var dayTHREE_radioCheck3 = preload("res://Assets/Audio/VA/Sutherland/Aye all clear.mp3")
var dayTHREE_radioCheck4 = preload("res://Assets/Audio/VA/Sutherland/Bright as a star.mp3")
var dayTHREE_morseCheck_talkToSelf = preload("res://Assets/Audio/VA/Sutherland/Checks out.mp3")
#var dayTHREE_turnLightOn = preload("Don't want the americans getting lost.") # VA LINE MISSING
var dayTHREE_leaveLightOff = preload("res://Assets/Audio/VA/Sutherland/Isolation.mp3")
var dayTHREE_END_lightOn = preload("res://Assets/Audio/VA/Sutherland/Tides are turning.mp3")
var dayTHREE_END_lightOff = preload("res://Assets/Audio/VA/Sutherland/Unforgiving beast.mp3")

var dayFOUR_daughterCheck1 = preload("res://Assets/Audio/VA/Sutherland/Headed out.mp3")
#var dayFOUR_daughterCheck3 = preload("Yeah...before you go...I love you...") # VA LINE MISSING
var dayFOUR_radioCheck2 = preload("res://Assets/Audio/VA/Sutherland/Doesnt sound swedish.mp3")
var dayFOUR_readioCheck3_talkToSelf = preload("res://Assets/Audio/VA/Sutherland/Heard Over 2.mp3")
var dayFOUR_turnLightOn = preload("res://Assets/Audio/VA/Sutherland/Knew they were coming.mp3")
var dayFOUR_turnLightOff1 = preload("res://Assets/Audio/VA/Sutherland/Never again.mp3")
var dayFOUR_turnLightOff2 = preload("res://Assets/Audio/VA/Sutherland/Ill take care of Elise.mp3")
var dayFOUR_END_lightOn1 = preload("res://Assets/Audio/VA/Sutherland/Start over.mp3")
var dayFOUR_END_lightOn2 = preload("res://Assets/Audio/VA/Sutherland/Doesnt have to mean bad.mp3")
var dayFOUR_END_lightOn3 = preload("res://Assets/Audio/VA/Sutherland/I have to move on.mp3")
var dayFOUR_END_lightOff = preload("res://Assets/Audio/VA/Sutherland/The world ended.mp3")

var lastDay_goodEnding1 = preload("res://Assets/Audio/VA/Sutherland/that smell.mp3")
var lastDay_badEnding = preload("res://Assets/Audio/VA/Sutherland/Cant take her from me.mp3")
#SMITH
var dayZERO_radioCheckFinish = preload("res://Assets/Audio/VA/Smith/Wake-Up.mp3")
var dayZERO_smithTalk2 = preload("res://Assets/Audio/VA/Smith/Bastard.mp3")
var dayZERO_bombWarning = preload("res://Assets/Audio/VA/Smith/Get-Out.mp3")

var dayONE_radioCheckSolved = preload("res://Assets/Audio/VA/Smith/How Are You Doing.mp3") # will need to cut this early in code or try to time the overlay as Suth talks to himself
var dayONE_afterGearResponse = preload("res://Assets/Audio/VA/Smith/Unsavory-Folks.mp3")

var dayTHREE_radioSolved_wrongChoiceOnDayTWO = preload("res://Assets/Audio/VA/Smith/Bad-Attack.mp3")

# OTHER
#var dayONE_radioAfterSmith = preload("scottishFisherman") #awaiting lines for this one

var dayTWO_radioCheck1 = preload("res://Assets/Audio/VA/Misc Radio/Radio-German-American.mp3")

var dayTHREE_radioCheck1 = preload("res://Assets/Audio/VA/Misc Radio/Radio American.mp3")

var dayFOUR_radioCheck1 = preload("res://Assets/Audio/VA/Misc Radio/Radio-German-Swedish.mp3")

# COOKING MINIGAME
var onTriggerGood_early: Array = [preload("res://Assets/Audio/VA/Sutherland/Cooking/Actually Smells Good.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/Not as hard as I thought.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/I think I get it.mp3")]
var onTriggerGood_later: Array = [preload("res://Assets/Audio/VA/Sutherland/Cooking/Im getting the hang of this.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/Cath would be angry.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/Delicious.mp3")] # *slurp* on the last one here
var onTriggerBad: Array = [preload("res://Assets/Audio/VA/Sutherland/Cooking/What am I doing.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/gears and switches.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/Leftovers.mp3")]
var onTriggerBurning: Array = [preload("res://Assets/Audio/VA/Sutherland/Cooking/Burning.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/No no no.mp3")]
var onTriggerEnd_okay: Array = [preload("res://Assets/Audio/VA/Sutherland/Cooking/Its edible.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/hope elise likes it.mp3")]
var onTriggerEnd_good: Array = [preload("res://Assets/Audio/VA/Sutherland/Cooking/Actually quite good.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/Elise will love this.mp3")]
var onTriggerEnd_excellent: Array = [preload("res://Assets/Audio/VA/Sutherland/Cooking/Sorted.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/Cath would be proud.mp3")]
var onTriggerEnd_bad: Array = [preload("res://Assets/Audio/VA/Sutherland/Cooking/Isnt fit for.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/Smells like my boots.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/Did I kill it.mp3"), preload("res://Assets/Audio/VA/Sutherland/Cooking/Scrubbing for Hours.mp3")]
var onTriggerChopping_early = preload("res://Assets/Audio/VA/Sutherland/Cooking/Chop chop chop ow.mp3")
var onTriggerChopping_later = preload("res://Assets/Audio/VA/Sutherland/Cooking/Chop chop chop.mp3")
#endregion

func _ready():
	#Dialogue Signal
	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)
	todaysRecipe = "BarfitStovies" # defaulting here for testing
	await get_tree().process_frame
	apply_save_data()
	
	StartDay(-1) #Since you forced to start on day -1, save&load unable to overwrite this. 
				 #Make sure it change to currentDay to able loading function 

func _on_dialogue_started(): #commenting out for now so I can test collision map
	#get_tree().paused = true
	pass

func _on_dialogue_ended():
	get_tree().paused = false
	
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
	emit_signal("requestDayCycle")
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
