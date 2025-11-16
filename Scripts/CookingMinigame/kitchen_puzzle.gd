# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Control

#region VARIABLES
#region NODES
var heatDial: Button
var potArea: Area2D
var progressBar: ProgressBar
var recipeInstructions: Node
#endregion NODES
#region DELETE THIS LATER
var TESTING_RECIPE_NOTIFICATION_FEED: RichTextLabel
	#region _PRIVATES
var _newText: String
var _indent: String = "\n"
	#endregion _PRIVATES
#endregion DELETE THIS LATER

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

# Recipes are created as a Dictionary of Arrays of Dictionaries
# 	Each one has a Title and steps
# 	Each step has a heat, list of ingredients with amounts, a wait (cook) time, and timer time
# 	Heat is a value set by the kitchen dial, it can be set to low (25), medium (50), high (100), or off (0)
# 	Ingredients have names, types, and amounts.
#		Types are Whole, Shaker, and Pourable
#			Whole ingredients can also be Choppable, meaning they can be interacted with to make then " (Chopped)"
#			Shakers are coded to have to be held and shook over the pot to add their ingredients
#			Pourables are coded to have to be held over the pot and wait for their amounts to pour
#	Wait time is the amount of time it takes to cook those ingredients
#	"time" is the challenge timer, the amount of time you have to complete the step before you risk burning or overcooking the food
#		a "time" of 0.0 means that there is no time limit to this step (rewarding mise en place)
var recipes = { # TODO: make easier recipes for early-game
	"TestRecipeHard": [
		{"heat": 50.0, "ingredients": [
			{"name": "Oil", "type": "Pourable", "amount": 2}
		], "wait": 2.0, "time": 0.0},
		
		{"heat": 50.0, "ingredients": [
			{"name": "Onion (Chopped)", "type": "Whole", "amount": 2}
		], "wait": 2.0, "time": 30.0},
		
		{"heat": 25.0, "ingredients": [
			{"name": "Garlic (Chopped)", "type": "Whole", "amount": 1}
		], "wait": 2.0, "time": 35.0},
		
		{"heat": 100.0, "ingredients": [
			{"name": "Potato (Chopped)", "type": "Whole", "amount": 3},
			{"name": "Carrot (Chopped)", "type": "Whole", "amount": 1},
			{"name": "Water", "type": "Pourable", "amount": 10}
		], "wait": 2.0, "time": 45.0},
		
		{"heat": 25.0, "ingredients": [
			{"name": "Rabbit (Chopped)", "type": "Whole", "amount": 1},
			{"name": "Stock", "type": "Pourable", "amount": 5},
		], "wait": 2.0, "time": 30.0},
		
		{"heat": 25.0, "ingredients": [
			{"name": "Thyme", "type": "Whole", "amount": 2},
			{"name": "Parsley", "type": "Whole", "amount": 2},
			{"name": "Rosemary", "type": "Whole", "amount": 1}
		], "wait": 2.0, "time": 30.0},
		
		{"heat": 25.0, "ingredients": [
			{"name": "Salt", "type": "Shaker", "amount": 8},
			{"name": "Pepper", "type": "Shaker", "amount": 4}
		], "wait": 2.0, "time": 15.0},
		
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
	
	set_process(false)

func _process(_delta): #this is purely for the progress bar
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

func RegisterNodes(heatDialNode: Button, potAreaNode: Area2D, progressBarNode: ProgressBar, notifications: RichTextLabel, recipeParser: Node):
	# This func is called by the Autoload to reference all needed nodes
	heatDial = heatDialNode
	potArea = potAreaNode
	progressBar = progressBarNode
	TESTING_RECIPE_NOTIFICATION_FEED = notifications
	recipeInstructions = recipeParser
	
	# Connect to the heat dial's signal
	if heatDial:
		heatDial.connect("ValueChanged", OnHeatDialValueChanged)
		if heatDial.has_method("GetValue"):
			currentHeat = heatDial.GetValue()
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

# Reset the recipe if beyond a failure threshold or on button press at player-will
func ResetRecipe():
	if activeRecipe.is_empty():
		print("No active recipe to reset.")
		# disable button here?
		return
	
	print("Resetting recipe...")
	StartRecipe(currentRecipeName)

func StartRecipe(recipeName: String):
	print("Starting recipe: %s" % recipeName)
	TESTING_RECIPE_NOTIFICATION_FEED.text = "Starting recipe: %s" % recipeName
	
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
	_newText = "STEP %d" % (index + 1)
	TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
	TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
	print("Set heat to: %.0f" % currentStepData["heat"])
	_newText = "Set heat to: %.0f" % currentStepData["heat"]
	TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
	TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
	
	# Logic checks to ingredients needed
	for solidName in currentStepIngredientsNeeded:
		var solidData = currentStepIngredientsNeeded[solidName]
		print("Add: %d of %s" % [solidData.needed, solidName])
		_newText = "Add: %d of %s" % [solidData.needed, solidName]
		TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
		TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
	for liquidName in currentStepPartialIngredientsNeeded:
		var liquidData = currentStepPartialIngredientsNeeded[liquidName]
		print("Add: %.0f of %s" % [liquidData.needed, liquidName])
		_newText = "Add: %.0f of %s" % [liquidData.needed, liquidName]
		TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
		TESTING_RECIPE_NOTIFICATION_FEED.text += _newText

func OnHeatDialValueChanged(newHeatValue: float):
	print("Heat set to: %.0f" % newHeatValue)
	_newText = "Heat set to: %.0f" % newHeatValue
	TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
	TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
	currentHeat = newHeatValue
	
	# Check for wrong heat
	if currentHeat != currentStepData["heat"]:
		print("WRONG HEAT! Expected %.0f" % currentStepData["heat"])
		_newText = "WRONG HEAT! Expected %.0f" % currentStepData["heat"]
		TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
		TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
	else:
		print("Correct heat set.")
		_newText = "Correct heat set."
		TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
		TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
	
	# Check if this step is done now
	CheckStepComplete()

func OnPotIngredientAdded(ingredientName: String): # This is for the WHOLE or CHOPPED ingredients
	print("Solid ingredient added to pot: %s" % ingredientName)
	_newText = "Solid ingredient added to pot: %s" % ingredientName
	TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
	TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
	
	# Reduce quality if heat is wrong
	if currentHeat != currentStepData["heat"]:
		print("Added %s at the wrong temperature! Expected %.0f." % [ingredientName, currentStepData["heat"]])
		_newText = "Added %s at the wrong temperature! Expected %.0f." % [ingredientName, currentStepData["heat"]]
		TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
		TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
		recipeQuality -= 5

	if currentStepIngredientsNeeded.has(ingredientName):
		# Ingredient needed, update
		var solidData = currentStepIngredientsNeeded[ingredientName]
		solidData.current += 1
		
		if solidData.current > solidData.needed:
			# Too many added
			print("Added too many %s. (%d / %d)" % [ingredientName, solidData.current, solidData.needed])
			_newText = "Added too many %s. (%d / %d)" % [ingredientName, solidData.current, solidData.needed]
			TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
			TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
			recipeQuality -= 5 # Penalty for over-adding
		else:
			# Correct additions
			print("Correctly added %s. (%d / %d)" % [ingredientName, solidData.current, solidData.needed])
			_newText = "Correctly added %s. (%d / %d)" % [ingredientName, solidData.current, solidData.needed]
			TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
			TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
	else:
		# Ingredient was not needed
		print("%s not needed for this step." % ingredientName)
		_newText = "%s not needed for this step." % ingredientName
		TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
		TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
		recipeQuality -= 5
	
	# Check to end this step
	CheckStepComplete()

func AddPartialIngredient(ingredientName: String, amount: float): # This is for the shaker and pourables
	# Ensure correct heat, or else
	if currentHeat != currentStepData["heat"]:
		print("Added %s at the wrong temperature." % ingredientName)
		_newText = "Added %s at the wrong temperature." % ingredientName
		TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
		TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
		recipeQuality -= 5
	
	if currentStepPartialIngredientsNeeded.has(ingredientName):
		# Ingredient needed
		var liquidData = currentStepPartialIngredientsNeeded[ingredientName]
		liquidData.current += amount
		print("Added %.0f of %s. Total: %.0f / %.0f" % [amount, ingredientName, liquidData.current, liquidData.needed])
		_newText = "Added %.0f of %s. Total: %.0f / %.0f" % [amount, ingredientName, liquidData.current, liquidData.needed]
		TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
		TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
		CheckStepComplete()
	else:
		# Ingredient not needed
		print("%s not needed for this step." % ingredientName)
		_newText = "%s not needed for this step." % ingredientName
		TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
		TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
		recipeQuality -= 5

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
		_newText = "Step %d complete." % (currentStepIndex + 1)
		TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
		TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
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
			_newText = "Too much %s by %.0f." % [liquidName, overdose]
			TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
			TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
	recipeQuality -= floor(totalOverdose)
	
	# FIFTH. Start wait timer
	StartWaitTimer()

func StartWaitTimer():
	var waitTime = currentStepData["wait"]
	isWaiting = true
	
	if waitTime > 0:
		if waitTimer.is_stopped():
			print("Waiting %.0f seconds..." % waitTime)
			_newText = "Waiting %.0f seconds..." % waitTime
			TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
			TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
			progressBar.visible = true
			progressBar.max_value = waitTime
			progressBar.value = 0
			progressBar.add_theme_stylebox_override("fill", barStyleWait) # Set to blue
			waitTimer.wait_time = waitTime
			waitTimer.start()
	else:
		print("No wait time, proceed to next step.")
		_newText = "No wait time, proceed to next step."
		TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
		TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
		OnWaitTimerTimeout()

func OnWaitTimerTimeout():
	waitTimer.stop()
	isWaiting = false
	print("Wait complete.")
	_newText = "Wait complete."
	TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
	TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
	
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
	_newText = "Food is being overcooked."
	TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
	TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
	
	progressBar.add_theme_stylebox_override("fill", barStyleOvertime) # setting to red
	progressBar.value = progressBar.max_value
	overtimeTimer.start()

func OnOvertimeTimerTimeout():
	recipeQuality -= 1
	print("Overcooked | -1 quality. Total %d" % recipeQuality)
	_newText = "Overcooked | -1 quality. Total %d" % recipeQuality
	TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
	TESTING_RECIPE_NOTIFICATION_FEED.text += _newText

func AdvanceToNextStep():
	currentStepIndex += 1
	
	if currentStepIndex >= activeRecipe.size():
		# Recipe finished
		print("Recipe complete. Final Quality: %d" % recipeQuality)
		_newText = "Recipe complete. Final Quality: %d" % recipeQuality
		TESTING_RECIPE_NOTIFICATION_FEED.text += _indent
		TESTING_RECIPE_NOTIFICATION_FEED.text += _newText
		progressBar.visible = false
	else:
		# Load next step and start new timer
		LoadStep(currentStepIndex)
		StartStepTimer()
