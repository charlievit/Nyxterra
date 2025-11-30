# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Control

#region VARIABLES
var kitchenGameMusicPlayer: AudioStreamPlayer
var gameDone: bool = false

# EXPORT RETURN SETTINGS
@export_group("Return Settings")
@export var returnFloorIndex = 2
@export var returnPosition: Vector2 = Vector2(80, 340)
@export var mainGameScenePath: String = "res://Scenes/main.tscn"

#region NODES
var heatDial: Button
var potArea: Area2D
var progressBar: ProgressBar
var recipeInstructions: Node
var fireAnimLow: AnimatedSprite2D
var fireAnimMedium: AnimatedSprite2D
var fireAnimHigh: AnimatedSprite2D
var steamAnim: AnimatedSprite2D
var steamUpdate: int = 0
var currentSteamSpeed: float = 0.0
const STEAM_STEP_DELAY: float = 6.0
var oneShotAudioPlayer: AudioStreamPlayer2D
var constantAudioPlayer: AudioStreamPlayer2D
var currentSizzleVolume: float = 0.0
#endregion NODES

#region SOUNDS
var chopSound: AudioStreamMP3
var plopSound: AudioStreamMP3
var boilingSound: AudioStreamMP3
var stoveOffSound: AudioStreamMP3
var stoveOnSound: AudioStreamMP3
var pourSound: AudioStreamMP3
var shakerSounds: Array = []

var burningVAs: Array = ["Burning_1", "Burning_2"]
var hasMentionedBurning: bool = false
var endCookingBadLines: Array = ["EndCookingBad_1", "EndCookingBad_2", "EndCookingBad_3"]
var endCookingGoodLinesEarly: Array = ["EndCookingGood_Day1or2_1", "EndCookingGood_Day1or2_2", "EndCookingGood_Day1or2_3"]
var endCookingGoodLinesLate: Array = ["EndCookingGood_Day3or4_1", "EndCookingGood_Day3or4_2", "EndCookingGood_Day3or4_3"]
#endregion SOUNDS

#region PROGRESS BAR
var barStyleWait: StyleBoxFlat
var barStyleStep: StyleBoxFlat
var barStyleOvertime: StyleBoxFlat

# Colors
const WAIT_COLOR = Color.CYAN
const STEP_START_COLOR = Color.SEA_GREEN
const STEP_MID_COLOR = Color.YELLOW_GREEN
const STEP_END_COLOR = Color.DARK_RED
#endregion Progress Bar Styles

var recipes = {
	"BarfitStovies": [
		{"heat": 50.0, "ingredients": [{"name": "Oil", "type": "Pourable", "amount": 5}], "wait": 10.0, "time": 0.0},
		{"heat": 25.0, "ingredients": [{"name": "Onion (Chopped)", "type": "Whole", "amount": 2}, {"name": "Salt", "type": "Shaker", "amount": 5}], "wait": 45.0, "time": 30.0},
		{"heat": 50.0, "ingredients": [{"name": "Potato (Chopped)", "type": "Whole", "amount": 5}, {"name": "Stock", "type": "Pourable", "amount": 10}], "wait": 30.0, "time": 45.0},
		{"heat": 25.0, "ingredients": [], "wait": 15.0, "time": 99.0},
		{"heat": 25.0, "ingredients": [{"name": "Parsley", "type": "Whole", "amount": 1}, {"name": "Pepper", "type": "Shaker", "amount": 5}], "wait": 5.0, "time": 60.0},
		{"heat": 0.0, "ingredients": [], "wait": 0.0, "time": 0.0}
	],
	"BraisedRoots": [
		{"heat": 50.0, "ingredients": [{"name": "Oil", "type": "Pourable", "amount": 3}], "wait": 10.0, "time": 0.0},
		{"heat": 50.0, "ingredients": [{"name": "Carrot (Chopped)", "type": "Whole", "amount": 2}, {"name": "Potato (Chopped)", "type": "Whole", "amount": 4}, {"name": "Garlic (Chopped)", "type": "Whole", "amount": 1}], "wait": 25.0, "time": 40.0},
		{"heat": 50.0, "ingredients": [{"name": "Stock", "type": "Pourable", "amount": 5}, {"name": "Thyme", "type": "Whole", "amount": 2}, {"name": "Salt", "type": "Shaker", "amount": 3}], "wait": 30.0, "time": 30.0},
		{"heat": 100.0, "ingredients": [], "wait": 15.0, "time": 99.0},
		{"heat": 25.0, "ingredients": [{"name": "Water", "type": "Pourable", "amount": 2}], "wait": 5.0, "time": 8.0},
		{"heat": 0.0, "ingredients": [], "wait": 0.0, "time": 0.0}
	],
	"ScotchTattieSoup": [
		{"heat": 25.0, "ingredients": [{"name": "Oil", "type": "Pourable", "amount": 3}], "wait": 10.0, "time": 0.0},
		{"heat": 50.0, "ingredients": [{"name": "Onion (Chopped)", "type": "Whole", "amount": 1}, {"name": "Pepper", "type": "Shaker", "amount": 6}, {"name": "Salt", "type": "Shaker", "amount": 3}], "wait": 20.0, "time": 30.0},
		{"heat": 50.0, "ingredients": [{"name": "Carrot (Chopped)", "type": "Whole", "amount": 2}, {"name": "Garlic (Chopped)", "type": "Whole", "amount": 1}], "wait": 20.0, "time": 20.0},
		{"heat": 50.0, "ingredients": [{"name": "Stock", "type": "Pourable", "amount": 10}, {"name": "Water", "type": "Pourable", "amount": 5}], "wait": 5.0, "time": 15.0},
		{"heat": 100.0, "ingredients": [], "wait": 25.0, "time": 99.0},
		{"heat": 100.0, "ingredients": [{"name": "Potato (Chopped)", "type": "Whole", "amount": 4}, {"name": "Thyme", "type": "Whole", "amount": 2}], "wait": 40.0, "time": 45.0},
		{"heat": 0.0, "ingredients": [], "wait": 0.0, "time": 0.0}
	],
	"RabbitStew": [
		{"heat": 25.0, "ingredients": [{"name": "Oil", "type": "Pourable", "amount": 2}, {"name": "Pepper", "type": "Shaker", "amount": 2}], "wait": 5.0, "time": 0.0},
		{"heat": 50.0, "ingredients": [{"name": "Onion (Chopped)", "type": "Whole", "amount": 2}], "wait": 15.0, "time": 15.0},
		{"heat": 25.0, "ingredients": [{"name": "Garlic (Chopped)", "type": "Whole", "amount": 1}], "wait": 10.0, "time": 15.0},
		{"heat": 100.0, "ingredients": [{"name": "Potato (Chopped)", "type": "Whole", "amount": 3}, {"name": "Carrot (Chopped)", "type": "Whole", "amount": 1}, {"name": "Water", "type": "Pourable", "amount": 20}], "wait": 20.0, "time": 18.0},
		{"heat": 25.0, "ingredients": [{"name": "Rabbit (Chopped)", "type": "Whole", "amount": 1}, {"name": "Stock", "type": "Pourable", "amount": 10}], "wait": 30.0, "time": 45.0},
		{"heat": 25.0, "ingredients": [{"name": "Thyme", "type": "Whole", "amount": 2}, {"name": "Parsley", "type": "Whole", "amount": 2}, {"name": "Rosemary", "type": "Whole", "amount": 1}], "wait": 10.0, "time": 30.0},
		{"heat": 25.0, "ingredients": [{"name": "Salt", "type": "Shaker", "amount": 10}, {"name": "Pepper", "type": "Shaker", "amount": 2}], "wait": 5.0, "time": 30.0},
		{"heat": 0.0, "ingredients": [], "wait": 0.0, "time": 0.0}
	]
}

#region STATES
var recipeQuality = 100
var activeRecipe: Array = []
var currentRecipeName: String = ""
var currentStepIndex: int = 0
var currentStepData: Dictionary = {}
var currentHeat: float = -1.0
var currentTaskID: String = ""

# Dictionaries for tracking progress through the recipe
var currentStepIngredientsNeeded: Dictionary = {}
var currentStepPartialIngredientsNeeded: Dictionary = {}

# TIMERS
var waitTimer: Timer
var stepTimer: Timer
var overtimeTimer: Timer

# STATEMACHINE FOR TIMERS
var isWaiting: bool = false
var isStepTiming: bool = false
var isOvertime: bool = false
#endregion STATES
#endregion VARIABLES

func _ready():
	# Create timers
	waitTimer = Timer.new()
	waitTimer.name = "WaitTimer"
	waitTimer.one_shot = true
	add_child(waitTimer)
	waitTimer.connect("timeout", OnWaitTimerTimeout)
	
	stepTimer = Timer.new()
	stepTimer.name = "StepTimer"
	stepTimer.one_shot = true
	add_child(stepTimer)
	stepTimer.connect("timeout", OnStepTimerTimeout)
	
	overtimeTimer = Timer.new()
	overtimeTimer.name = "OvertimeTimer"
	overtimeTimer.wait_time = 1.0
	overtimeTimer.one_shot = false
	add_child(overtimeTimer)
	overtimeTimer.connect("timeout", OnOvertimeTimerTimeout)
	
	# Create styleboxes for the progress bar colors
	barStyleWait = StyleBoxFlat.new()
	barStyleWait.bg_color = WAIT_COLOR
	
	barStyleStep = StyleBoxFlat.new()
	barStyleStep.bg_color = STEP_START_COLOR
	
	barStyleOvertime = StyleBoxFlat.new()
	barStyleOvertime.bg_color = STEP_END_COLOR
	
	kitchenGameMusicPlayer = AudioStreamPlayer.new()
	add_child(kitchenGameMusicPlayer)
	kitchenGameMusicPlayer.stream = GameManager.kitchenThemeMusic
	kitchenGameMusicPlayer.volume_db = -25.0
	kitchenGameMusicPlayer.finished.connect(Loop)
	
	set_process(false)

func Loop():
	if gameDone:
		return
	kitchenGameMusicPlayer.play()

func OnLoopSound(player):
	player.play()

func _process(_delta): #this is purely for the progress bar
	if not is_instance_valid(progressBar) or not is_instance_valid(steamAnim):
		set_process(false)
		return
	
	if isWaiting:
		# Blue bar, counts up
		progressBar.visible = true
		progressBar.modulate.a = 1.0
		progressBar.value = waitTimer.wait_time - waitTimer.time_left
	elif isStepTiming:
		# Green-to-Red bar, counts down
		progressBar.visible = true
		progressBar.modulate.a = 1.0
		progressBar.value = stepTimer.time_left
		
		if stepTimer.wait_time > 0:
			var percent = 1.0 - (stepTimer.time_left / stepTimer.wait_time)
			UpdateStepTimerColor(percent)
	elif isOvertime:
		# Flashing red bar, stays full
		progressBar.visible = true
		progressBar.value = progressBar.max_value
		progressBar.modulate.a = (sin(Time.get_ticks_msec() * 0.01) + 1.0) / 2.0
	else:
		# No timers active, hide bar
		progressBar.visible = false
		progressBar.modulate.a = 1.0

func UpdateStepTimerColor(percent: float): # This function lerps the color of the step timer bar
	if percent < 0.5:
		barStyleStep.bg_color = STEP_START_COLOR.lerp(STEP_MID_COLOR, percent * 2.0)
	else:
		barStyleStep.bg_color = STEP_MID_COLOR.lerp(STEP_END_COLOR, (percent - 0.5) * 2.0)
	
	progressBar.add_theme_stylebox_override("fill", barStyleStep)

func RegisterNodes(heatDialNode: Button, potAreaNode: Area2D, progressBarNode: ProgressBar, recipeParser: Node, fireAnimNodeLow: AnimatedSprite2D, fireAnimNodeMedium: AnimatedSprite2D, fireAnimNodeHigh: AnimatedSprite2D, steamAnimNode: AnimatedSprite2D, oneShotAudioNode: AudioStreamPlayer2D, constantAudioNode: AudioStreamPlayer2D):
	# This func is called by the Autoload to reference all needed nodes
	heatDial = heatDialNode
	potArea = potAreaNode
	progressBar = progressBarNode
	recipeInstructions = recipeParser
	fireAnimLow = fireAnimNodeLow
	fireAnimMedium = fireAnimNodeMedium
	fireAnimHigh = fireAnimNodeHigh
	steamAnim = steamAnimNode
	steamAnim.speed_scale = 1.0
	oneShotAudioPlayer = oneShotAudioNode
	constantAudioPlayer = constantAudioNode
	
	# Connect to the heat dial's signal
	if heatDial:
		heatDial.connect("ValueChanged", OnHeatDialValueChanged)
		if heatDial.has_method("GetValue"):
			currentHeat = heatDial.GetValue()
			SetFireAndSteamAnimations(currentHeat)
			print("Heat Dial Value: %.0f" % currentHeat)
		else:
			push_error("ERROR: Heat dial missing GetValue() method") 
	else:
		push_error("KitchenController: Cannot find 'HeatDial' node.")

	# Connect to the pot's signal
	if potArea:
		potArea.connect("IngredientAdded", OnPotIngredientAdded)
	else:
		push_error("KitchenController: Cannot find 'PotArea' node.")
	
	if progressBar:
		progressBar.visible = false
		progressBar.value = 0
	else:
		push_error("KitchenController: Cannot find 'ProgressBar' node.")
	
	set_process(true)

func PrepareSounds(chopSoundFile, plopSoundFile, boilingSoundFile, stoveOffSoundFile, stoveOnSoundFile, pourSoundFile, shakerSoundFiles):
	chopSound = chopSoundFile
	plopSound = plopSoundFile
	boilingSound = boilingSoundFile
	stoveOffSound = stoveOffSoundFile
	stoveOnSound = stoveOnSoundFile
	pourSound = pourSoundFile
	shakerSounds = shakerSoundFiles

# Reset the recipe if beyond a failure threshold or on button press at player-will
func ResetRecipe():
	if activeRecipe.is_empty():
		print("No active recipe to reset.")
		# disable button here?
		return
	
	print("Resetting recipe...")
	StartRecipe(currentRecipeName)

func ApplyPenalty(amount: int):
	recipeQuality -= amount
	print("Penalty applied: -%d. New quality: %d" % [amount, recipeQuality])

func StartRecipe(recipeName: String):
	print("Starting recipe: %s" % recipeName)
	gameDone = false
	kitchenGameMusicPlayer.play()
	
	currentRecipeName = recipeName #store in case of reset needed
	
	activeRecipe = recipes[recipeName]
	currentStepIndex = 0
	recipeQuality = 100
	
	# Stop all timers and reset states
	isWaiting = false
	isStepTiming = false
	isOvertime = false
	waitTimer.stop()
	stepTimer.stop()
	overtimeTimer.stop()
	
	# Load step 0 and start the step timer for it
	LoadStep(currentStepIndex)
	StartStepTimer()

func LoadStep(index: int):
	currentStepData = activeRecipe[index]
	
	# Clear the previous step
	currentStepIngredientsNeeded.clear()
	currentStepPartialIngredientsNeeded.clear()
	
	# Populate this step's requirements
	for ingredient in currentStepData["ingredients"]:
		var type = ingredient["type"]
		if type == "Whole":
			currentStepIngredientsNeeded[ingredient["name"]] = {
				"needed": ingredient["amount"],
				"current": 0
			}
		elif type == "Pourable" or type == "Shaker":
			currentStepPartialIngredientsNeeded[ingredient["name"]] = {
				"needed": ingredient["amount"],
				"current": 0.0
			}
	
	# Print debug stuff for playtesting
	print("STEP %d" % (index + 1))
	print("Set heat to: %.0f" % currentStepData["heat"])
	
	# Logic checks to ingredients needed
	for solidName in currentStepIngredientsNeeded:
		var solidData = currentStepIngredientsNeeded[solidName]
		print("Add: %d of %s" % [solidData.needed, solidName])
	for liquidName in currentStepPartialIngredientsNeeded:
		var liquidData = currentStepPartialIngredientsNeeded[liquidName]
		print("Add: %.0f of %s" % [liquidData.needed, liquidName])

func OnHeatDialValueChanged(newHeatValue: float):
	print("Heat set to: %.0f" % newHeatValue)
	if newHeatValue > currentHeat:
		oneShotAudioPlayer.volume_db = -6.0
		oneShotAudioPlayer.stream = stoveOnSound
		oneShotAudioPlayer.play()
	else:
		oneShotAudioPlayer.stream = stoveOffSound
		oneShotAudioPlayer.play()
	
	if currentHeat == 0 and newHeatValue > 0:
		constantAudioPlayer.volume_db = -85.0
		constantAudioPlayer.stream = boilingSound
		constantAudioPlayer.play()
		constantAudioPlayer.autoplay = true
	
	currentHeat = newHeatValue
	
	SetFireAndSteamAnimations(currentHeat)
	
	# Check for wrong heat
	if currentHeat != currentStepData["heat"]:
		print("WRONG HEAT! Expected %.0f" % currentStepData["heat"])
	else:
		print("Correct heat set.")
	
	# Check if this step is done now
	CheckStepComplete()

func SetFireAndSteamAnimations(heatLevel: float):
	if not fireAnimLow or not fireAnimMedium or not fireAnimHigh or not steamAnim:
		return
	
	# FIRST: Reset everything 
	fireAnimLow.visible = false
	fireAnimLow.stop()
	fireAnimMedium.visible = false
	fireAnimMedium.stop()
	fireAnimHigh.visible = false
	fireAnimHigh.stop()
	
	var targetSteamSpeed: float = 0.0
	var targetVolume: float = -80.0
	
	# SECOND: Set targets based on heat level
	match heatLevel:
		0.0:
			targetSteamSpeed = 0.0
			targetVolume = -80.0
			pass
		25.0:
			fireAnimLow.visible = true
			fireAnimLow.play("default")
			targetSteamSpeed = 1.0
			targetVolume = -12.0
		50.0:
			fireAnimMedium.visible = true
			fireAnimMedium.play("default")
			targetSteamSpeed = 2.0
			targetVolume = -8.0
		100.0:
			fireAnimHigh.visible = true
			fireAnimHigh.play("default")
			targetSteamSpeed = 3.0
			targetVolume = -4.0
		_:
			push_error("Heat value (%f) outside expected ranges." % heatLevel)
			return
	
	# THIRD: Calculate the sync between the steam animation and the boiling sounds
	var speedDiff = abs(targetSteamSpeed - currentSteamSpeed)
	var fadeDuration = speedDiff * STEAM_STEP_DELAY
	
	# FOURTH: Tween the audio slowly to target value
	var audioTween = get_tree().create_tween()
	
	if heatLevel > 0.0:
		if not constantAudioPlayer.playing:
			constantAudioPlayer.volume_db = -80.0
			constantAudioPlayer.play()
		
		audioTween.tween_property(constantAudioPlayer, "volume_db", targetVolume, fadeDuration)
	else:
		audioTween.tween_property(constantAudioPlayer, "volume_db", targetVolume, fadeDuration)
	
	# FIFTH: Update steam animation to target values
	steamUpdate += 1
	var currentUpdate = steamUpdate
	
	var startSpeed = currentSteamSpeed
	var endSpeed = targetSteamSpeed
	
	if startSpeed < endSpeed: # Heating up
		var speedToSet = startSpeed + 1.0
		
		while speedToSet <= endSpeed:
			await get_tree().create_timer(STEAM_STEP_DELAY).timeout
			
			if not steamAnim:
				return
			
			if currentUpdate != steamUpdate:
				return
			
			steamAnim.visible = true
			if not steamAnim.is_playing():
				steamAnim.play("default")
			
			await  get_tree().create_timer(STEAM_STEP_DELAY).timeout
			steamAnim.speed_scale = speedToSet
			currentSteamSpeed = speedToSet
			
			speedToSet += 1
	elif startSpeed > endSpeed: # Cooling down
		var speedToSet = startSpeed - 1.0
		
		while speedToSet >= endSpeed:
			await get_tree().create_timer(STEAM_STEP_DELAY).timeout
			
			if not steamAnim:
				return
			
			if currentUpdate != steamUpdate:
				return
			
			currentSteamSpeed = speedToSet
			
			if speedToSet == 0.0:
				steamAnim.visible = false
				steamAnim.stop()
			else:
				steamAnim.speed_scale = speedToSet
			
			speedToSet -= 1.0
	
	# FINAL: Cleanup
	if heatLevel == 0.0:
		if audioTween.is_running():
			await audioTween.finished
		# Quick check to see if new targets assigned while waiting
		if currentUpdate == steamUpdate:
			constantAudioPlayer.stop()
	
func OnPotIngredientAdded(ingredientName: String): # This is for the WHOLE or CHOPPED ingredients
	print("Solid ingredient added to pot: %s" % ingredientName)
	
	# Reduce quality if heat is wrong
	if currentHeat != currentStepData["heat"]:
		print("Added %s at the wrong temperature! Expected %.0f." % [ingredientName, currentStepData["heat"]])
		ApplyPenalty(5)

	if currentStepIngredientsNeeded.has(ingredientName):
		# Ingredient needed, update
		var solidData = currentStepIngredientsNeeded[ingredientName]
		solidData.current += 1
		
		if solidData.current > solidData.needed:
			# Too many added
			print("Added too many %s. (%d / %d)" % [ingredientName, solidData.current, solidData.needed])
			ApplyPenalty(5) # Penalty for over-adding
		else:
			# Correct additions
			print("Correctly added %s. (%d / %d)" % [ingredientName, solidData.current, solidData.needed])
	else:
		# Ingredient was not needed
		print("%s not needed for this step." % ingredientName)
		ApplyPenalty(5)
	
	# Check to end this step
	CheckStepComplete()

func AddPartialIngredient(ingredientName: String, amount: float): # This is for the shaker and pourables
	# Ensure correct heat, or else
	if currentHeat != currentStepData["heat"]:
		print("Added %s at the wrong temperature." % ingredientName)
		ApplyPenalty(5)
	
	if currentStepPartialIngredientsNeeded.has(ingredientName):
		# Ingredient needed
		var liquidData = currentStepPartialIngredientsNeeded[ingredientName]
		liquidData.current += amount
		print("Added %.0f of %s. Total: %.0f / %.0f" % [amount, ingredientName, liquidData.current, liquidData.needed])
		CheckStepComplete()
	else:
		# Ingredient not needed
		print("%s not needed for this step." % ingredientName)
		ApplyPenalty(10)

func CheckStepComplete():
	# This is the main logic, called after any player action
	
	# Leave if still waiting (shouldn't happen, but paranoid)
	if isWaiting:
		return
	
	# FIRST. Check if heat is correct
	if currentHeat != currentStepData["heat"]:
		return
	
	# SECOND. Check if all solid ingredients are added
	for solidName in currentStepIngredientsNeeded:
		var solidData = currentStepIngredientsNeeded[solidName]
		if solidData.current < solidData.needed:
			return # Not all solid ingredients added
	
	# THIRD. Check if all partial ingredients are added
	for liquidName in currentStepPartialIngredientsNeeded:
		var liquidData = currentStepPartialIngredientsNeeded[liquidName]
		if liquidData.current < liquidData.needed:
			return # Not all partial ingredients added
	# All good
	print("All conditions met. Starting timer.")
	# Reset timers
	if isStepTiming or isOvertime:
		print("Step %d complete." % (currentStepIndex + 1))
		stepTimer.stop()
		overtimeTimer.stop()
		isStepTiming = false
		isOvertime = false
	
	# FOURTH. Apply penalties
	var totalOverdose = 0
	for liquidName in currentStepPartialIngredientsNeeded:
		var liquidData = currentStepPartialIngredientsNeeded[liquidName]
		var overdose = liquidData.current - liquidData.needed
		if overdose > 0:
			totalOverdose += overdose
			print("Too much %s by %.0f." % [liquidName, overdose])
	ApplyPenalty(floor(totalOverdose))
	
	# FIFTH. Start wait timer
	StartWaitTimer()

func StartWaitTimer():
	var waitTime = currentStepData["wait"]
	isWaiting = true
	
	if waitTime > 0:
		if waitTimer.is_stopped():
			print("Waiting %.0f seconds..." % waitTime)
			progressBar.visible = true
			progressBar.max_value = waitTime
			progressBar.value = 0
			progressBar.add_theme_stylebox_override("fill", barStyleWait) # Set to blue
			waitTimer.wait_time = waitTime
			waitTimer.start()
	else:
		print("No wait time, proceed to next step.")
		OnWaitTimerTimeout()

func OnWaitTimerTimeout():
	waitTimer.stop()
	isWaiting = false
	print("Wait complete.")
	
	AdvanceToNextStep()

func StartStepTimer():
	var stepTime = currentStepData.get("time", 0.0)
	
	if stepTime > 0:
		isStepTiming = true
		progressBar.visible = true
		progressBar.max_value = stepTime
		progressBar.value = stepTime
		UpdateStepTimerColor(0.0) # Set to green
		
		stepTimer.wait_time = stepTime
		stepTimer.start()
	else:
		isStepTiming = false
		progressBar.visible = false

func OnStepTimerTimeout():
	stepTimer.stop()
	isStepTiming = false
	isOvertime = true
	print("Food is being overcooked.")
	
	progressBar.add_theme_stylebox_override("fill", barStyleOvertime) # setting to red
	progressBar.value = progressBar.max_value
	hasMentionedBurning = false
	overtimeTimer.start()

func OnOvertimeTimerTimeout():
	ApplyPenalty(1)
	if not hasMentionedBurning:
		Dialogic.start(burningVAs.pick_random())
		hasMentionedBurning = true

func AdvanceToNextStep():
	currentStepIndex += 1
	
	if currentStepIndex >= activeRecipe.size():
		# Recipe finished
		progressBar.visible = false
		CleanUpReferences()
		
		# Set dialogue flags
		if recipeQuality >= 50 and recipeQuality <= 100:
			Dialogic.VAR.Cooking_Response = "Good"
			
			if GameManager.currentDay == 1 or GameManager.currentDay == 2:
				Dialogic.start(endCookingGoodLinesEarly.pick_random())
			else:
				Dialogic.start(endCookingGoodLinesLate.pick_random())
		else:
			Dialogic.VAR.Cooking_Response = "Bad"
			Dialogic.start(endCookingBadLines.pick_random())
			
		print("Recipe complete. Final Quality: %d" % recipeQuality)
		gameDone = true
		
		GameManager.AddCookingScore(recipeQuality)
		
		await get_tree().create_timer(8.0).timeout
		kitchenGameMusicPlayer.stop()
		GameManager.CompleteTask(currentTaskID)
		GameManager.SetPlayerSpawn(returnFloorIndex, returnPosition)
		GameManager.pending_post_source = GameManager.ReturnSource.KITCHEN
		if ResourceLoader.exists(mainGameScenePath):
			SceneLoader.change_scene_with_loading(mainGameScenePath)
		else:
			push_error("ERROR: Main game scene path not found.")
	else:
		# Load next step and start new timer
		LoadStep(currentStepIndex)
		StartStepTimer()

#DEBUG ONLY
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("H"):
		recipeQuality = 100
		AdvanceToNextStep()
	elif event.is_action_pressed("J"):
		recipeQuality = 30
		AdvanceToNextStep()

	
func CleanUpReferences():
	print("KitchenController: Cleaning up node references.")
	
	set_process(false)
	
	if waitTimer: waitTimer.stop()
	if stepTimer: stepTimer.stop()
	if overtimeTimer: overtimeTimer.stop()
	
	heatDial = null
	potArea = null
	progressBar = null
	recipeInstructions = null
	fireAnimLow = null
	fireAnimMedium = null
	fireAnimHigh = null
	steamAnim = null
	oneShotAudioPlayer = null
	constantAudioPlayer = null
	
	activeRecipe.clear()
	currentRecipeName = ""
	currentHeat = -1.0
	isWaiting = false
	isStepTiming = false
	isOvertime = false
