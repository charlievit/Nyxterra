# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Area2D

# Keep track of all choppable items in the area
var ingredientsInArea: Array = []

#region PROGRESS BAR
var barStyleWait: StyleBoxFlat
var barStyleStep: StyleBoxFlat
var barStyleOvertime: StyleBoxFlat

# Colors
const PROGRESS_COLOR = Color("#4a795c")
#endregion Progress Bar Styles

var chopTimer: Timer
var chopButton: Button
@onready var chopProgress: ProgressBar = $ChopProgressBar
@onready var knifeSprite: Sprite2D = $Knife
const REST_ROTATION: float = 15.0 # Initial 'stabbed' rotation
const CHOP_ROTATION: float = 90.0 # 'Parallel to board' rotation
const CHOP_OFFSET: float = 65.0 # How far down the knife moves when chopping
var defaultKnifePosition: Vector2

func _ready():
	# Create styleboxes for the progress bar colors
	barStyleWait = StyleBoxFlat.new()
	barStyleWait.bg_color = PROGRESS_COLOR
	if chopProgress:
		# Create a transparent style box for the background (the empty part)
		var barStyleBackground = StyleBoxFlat.new()
		barStyleBackground.bg_color = Color(0, 0, 0, 0) # Explicitly transparent
		# 1. Apply the custom StyleBox to the filled part, using "fill" (as seen in working script)
		chopProgress.add_theme_stylebox_override("fill", barStyleWait)
		# 2. Apply the transparent StyleBox to the background
		chopProgress.add_theme_stylebox_override("bg", barStyleBackground)
	# Create the chop timer and connect its signal
	chopTimer = Timer.new()
	chopTimer.wait_time = 0.2 # Adjust this value (seconds) to change chop speed
	chopTimer.one_shot = false
	chopTimer.connect("timeout", OnChopTimerTimeout)
	add_child(chopTimer)
	
	if knifeSprite: defaultKnifePosition = knifeSprite.position + Vector2(0,0) # Shift rest position 5 pixels Up and Left
	
	# Connect
	self.body_entered.connect(OnBodyEntered)
	self.body_exited.connect(OnBodyExited)
	
	# --- State Monitoring Setup ---
	 # Get the reference to the button (assuming "ChopButton" is a direct child)
	chopButton = get_node_or_null("ChopButton") 
	if not chopButton:
		# Pushes error if the button isn't found
		push_error("Chopping button not found! Check path in chopping_area.gd.")
		
	set_process(true)
	if chopProgress: chopProgress.visible = false
# ----------------------------

func _process(_delta): 
	
	# 1. EARLY EXIT/CLEANUP: Check if we have an ingredient
	if ingredientsInArea.is_empty():
		if chopProgress: chopProgress.visible = false
		return
	
	var chop_state = get_total_chop_state()
	var total_needed = chop_state.needed
	var total_count = chop_state.count
	chopProgress.visible = total_count < total_needed
	var is_done = total_count >= total_needed

	# 2. START LOGIC (Runs when button is HELD DOWN)
	if chopButton and chopButton.is_pressed():
		if chopTimer.is_stopped():
			chopTimer.start()
	
		# PROGRESS BAR UPDATE LOGIC (only run if button held)
		if chopProgress:
			if knifeSprite:
				var target_rot = CHOP_ROTATION
				if is_done:
					target_rot = REST_ROTATION
					if not chopTimer.is_stopped(): chopTimer.stop()
				if is_done:
					knifeSprite.position = knifeSprite.position.lerp(defaultKnifePosition, _delta * 15.0)
			
				knifeSprite.rotation_degrees = lerp(knifeSprite.rotation_degrees, target_rot, _delta * 15.0)
			
			chopProgress.max_value = total_needed
	
	# 3. STOP LOGIC (Runs when button is RELEASED)
	else: 
		if not chopTimer.is_stopped():
			chopTimer.stop()
			if chopProgress: chopProgress.visible = false
			if knifeSprite:
				knifeSprite.rotation_degrees = lerp(knifeSprite.rotation_degrees, REST_ROTATION, _delta * 15.0)
				knifeSprite.position = knifeSprite.position.lerp(defaultKnifePosition, _delta * 15.0)

func OnBodyEntered(body: Node2D):
	# Check the body to ensure it is an ingredient AND is choppable
	if "ingredientType" in body and body.get("isChoppable"):
		TutorialManager.CompleteTutorial("kitchenDragBoard")
		KitchenController.UpdateTutorialState("KNIFE")
		if not ingredientsInArea.has(body):
			ingredientsInArea.append(body)
			print("Entered: %s" % body.name)

func OnBodyExited(body: Node2D):
	# Remove the ingredient when it leaves
	if ingredientsInArea.has(body):
		ingredientsInArea.erase(body)

func OnChopTimerTimeout():
	# This function executes every time the timer times out (e.g., every 0.2 seconds)
	if ingredientsInArea.is_empty():
		chopTimer.stop()
		return

	var chop_performed = false

	for ingredient in ingredientsInArea:
		if "Chop" in ingredient and ingredient.chopCount < ingredient.chopsNeeded:
			ingredient.Chop()
			chop_performed = true
			break
	if chop_performed:
		AnimateKnifeChop()
		# Update progress bar with new cumulative totals
		var chop_state = get_total_chop_state()
		var total_needed = chop_state.needed
		var total_count = chop_state.count
		if chopProgress:
			chopProgress.value = total_count
			# Check for complete finish across all ingredients
			if total_count >= total_needed:
				if chopProgress: chopProgress.visible = false
				chopTimer.stop()
			
func AnimateKnifeChop():
	if not knifeSprite: return
	var tween = create_tween()
	# Move down (stab into board) quickly
	tween.tween_property(knifeSprite, "position:y", defaultKnifePosition.y + CHOP_OFFSET, 0.05)
	# Move up (lift off board) more slowly
	tween.tween_property(knifeSprite, "position:y", defaultKnifePosition.y, 0.15).set_delay(0.05)
	
func get_total_chop_state() -> Dictionary:
	var total_chops_needed = 0
	var total_chops_count = 0
	
	for ingredient in ingredientsInArea:
		# Check if the ingredient object has the required properties
		if "chopsNeeded" in ingredient and "chopCount" in ingredient:
			total_chops_needed += ingredient.chopsNeeded
			total_chops_count += ingredient.chopCount
			
	return {
		"needed": total_chops_needed,
		"count": total_chops_count
	}
func _on_chop_button_pressed():
	# This function is empty because the chopping logic is now handled in _process().
	pass 

func _on_chop_button_released():
	# This function is empty because the chopping logic is now handled in _process().
	pass
