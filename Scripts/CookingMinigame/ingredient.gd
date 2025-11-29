# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends RigidBody2D

# Define ingredient types, WHOLE and CHOPPABLE are kinda the same type but used in a boolean style for recipes
enum IngredientType {WHOLE, CHOPPABLE, POURABLE, SHAKER}

#region VARIABLES
#region INGREDIENT LOGIC
@onready var sprite = $Sprite

@export var ingredientName: String = "WARNING: UNNAMED INGREDIENT"
@export var ingredientType: IngredientType = IngredientType.WHOLE

@export_group("Choppable")
@export var isChoppable: bool = false
@export var chopsNeeded: int = 5
@export var isChopped: bool = false
@onready var choppedSprite: Sprite2D = $ChoppedSprite
var chopCount: int = 0

@export_group("PourableOrShaker")
@export var pourRate: float = 1.0 ## units per second
@export var shakeAmount: int = 1 ## units per shake
@export var shakeThreshold: float = 1000.0 ## mouse velocity threshold to "shake"

# NODES
@export var potDetectorArea: Area2D
@export var amountLabel: RichTextLabel
@onready var collisionShape = $CollisionShape2D

# STATES
var isOverPot: bool = false
var spawnPosition: Vector2
var currentAmount: float = 0.0
var isPouring = false
var pourPlayer: AudioStreamPlayer2D

# PHYSICS TIMER
var resetTimer: Timer
#endregion INGREDIENT LOGIC

#region CONTROLS
@export var followSpeed: float = 30.0 # snappiness of the object to the mouse cursor
@export var defaultGravityScale: float = 1.0
var isHeld: bool = false

# Variables to track the mouse's velocity for a "throw" effect on drop
var mouseVelocity: Vector2 = Vector2.ZERO
var lastMousePosition: Vector2 = Vector2.ZERO
var lastMouseVelocity: Vector2 = Vector2.ZERO # shake detections
#endregion CONTROLS
#endregion VARIABLES

func _ready() -> void:
	# Set up defaults
	gravity_scale = defaultGravityScale
	set_pickable(true)
	if is_inside_tree():
		lastMousePosition = get_global_mouse_position()
	
	spawnPosition = global_position #initial position for resetting shakers and pourables
	
	# CONNECTIONS
	if not potDetectorArea:
		push_error("ERROR: NEEDS POT DETECTOR IN SCENE!")
	else:
		potDetectorArea.area_entered.connect(OnPotAreaEntered)
		potDetectorArea.area_exited.connect(OnPotAreaExited)
	
	if not amountLabel:
		push_error("ERROR: AMOUNT LABEL MISSING")
	else:
		amountLabel.text = ""
	
	if (sprite and sprite is AnimatedSprite2D):
		sprite.frame = 0
	
	resetTimer = Timer.new()
	resetTimer.one_shot = true
	resetTimer.wait_time = 0.1
	resetTimer.connect("timeout", OnResetTimerTimeout)
	add_child(resetTimer)
	
	if self.IngredientType.POURABLE:
		print(self.name)
		pourPlayer = AudioStreamPlayer2D.new()
		add_child(pourPlayer)

func OnPotAreaEntered(area: Area2D):
	if area.is_in_group("pot"):
		isOverPot = true
		if pourPlayer.stream == null:
			if KitchenController.pourSound:
				pourPlayer.stream = KitchenController.pourSound
			else:
				push_error("Kitchen Controller missing pour sound.")
	if (sprite and sprite is AnimatedSprite2D):
		sprite.play("default")

func OnPotAreaExited(area: Area2D):
	if area.is_in_group("pot"):
		isOverPot = false
		rotation_degrees = 0.0
		StopPouring()
	if (sprite and sprite is AnimatedSprite2D):
		sprite.play_backwards("default")

func Chop():
	if not isChoppable or isChopped:
		return
	
	var randomChanceToSpeak = randf_range(0, 100)
	GameManager.chopSpeakCooldown -= 1
	if randomChanceToSpeak >= 95 and GameManager.chopSpeakCooldown <= 0:
		if GameManager.currentDay < 3:
			Dialogic.start("Chop_Day1or2")
			GameManager.chopSpeakCooldown = 50
		else:
			Dialogic.start("Chop_Day3or4")
			GameManager.chopSpeakCooldown = 50
	
	KitchenController.oneShotAudioPlayer.stream = KitchenController.chopSound
	KitchenController.oneShotAudioPlayer.volume_db = 0.0
	KitchenController.oneShotAudioPlayer.play()
	chopCount += 1
	
	print("Chop! %d / %d" % [chopCount, chopsNeeded])
	#KitchenController.TESTING_RECIPE_NOTIFICATION_FEED.text += "\n"
	#KitchenController.TESTING_RECIPE_NOTIFICATION_FEED.text += "Chop! %d / %d" % [chopCount, chopsNeeded]
	
	if chopCount >= chopsNeeded:
		isChopped = true
		sprite.visible = false
		choppedSprite.visible = true
		if not "(Chopped)" in ingredientName:
			ingredientName += " (Chopped)"
		print("Chopped. It's now: %s" % ingredientName)
		choppedSprite.visible = isChopped
		sprite.visible = not isChopped

func ResetPosition(): # just for shaker and pourables so their "containers" can't be added to the pot
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	StopPouring()
		# Return to start position
	global_position = spawnPosition
	rotation_degrees = 0.0
	isHeld = false
	currentAmount = 0.0
	if amountLabel:
		amountLabel.text = ""
	
	set_sleeping(false)
	freeze = false
	gravity_scale = defaultGravityScale
	resetTimer.stop()
	# Reset
	resetTimer.start()

func OnResetTimerTimeout():
	pass

func PickupAndHold():
	isHeld = true
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	freeze = true
	set_sleeping(false)
	
	# NOTE: Turning off collision while holding the object to prevent knocking around things accidentally
	collisionShape.disabled = true
	
	if is_inside_tree():
		global_position = get_global_mouse_position()
		lastMousePosition = get_global_mouse_position()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int): #initial click on ingredient
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			PickupAndHold()

func _input(event: InputEvent): # release click on ingredient
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			if isHeld: # Drop it
				isHeld = false
				collisionShape.disabled = false
				freeze = false
				gravity_scale = defaultGravityScale
				linear_velocity = mouseVelocity
				set_sleeping(false)
				StopPouring()
				
				if ingredientType == IngredientType.POURABLE or ingredientType == IngredientType.SHAKER:
					var amountToSend = floor(currentAmount)
					if amountToSend > 0.0:
						KitchenController.AddPartialIngredient(ingredientName, amountToSend)
					ResetPosition()

func StopPouring():
	if isPouring:
		isPouring = false
		pourPlayer.stop()

func _physics_process(delta: float):
	# FIRST: Track the mouse velocity
	var currentMousePosition: Vector2 = get_global_mouse_position()
	# Then Calculate velocity
	if lastMousePosition != Vector2.ZERO:
		mouseVelocity = (currentMousePosition - lastMousePosition) / delta
	# Then update mouse position for next frame
	lastMousePosition = currentMousePosition
	
	if amountLabel:
		amountLabel.rotation_degrees = -self.rotation_degrees
	
	# SECOND: make object follow the mouse
	if isHeld:
		var newPosisiton = global_position.lerp(currentMousePosition, delta * followSpeed)
		set_global_position(newPosisiton)
		
		# THIRD: handle held item logic
		if isOverPot and amountLabel:
			if ingredientType == IngredientType.POURABLE:
				if not isPouring:
					isPouring = true
					pourPlayer.play()
				# Pout over time and tilt
				currentAmount += pourRate * delta
				amountLabel.text = str(floor(currentAmount))
				rotation_degrees = lerp(rotation_degrees, -45.0, delta * 5.0)
			elif ingredientType == IngredientType.SHAKER:
				# Check for a mouse "shake"
				var mouseVel = mouseVelocity
				if abs(mouseVel.x) > shakeThreshold and sign(mouseVel.x) != sign(lastMouseVelocity.x):
					currentAmount += shakeAmount
					KitchenController.oneShotAudioPlayer.stream = KitchenController.shakerSounds.pick_random()
					KitchenController.oneShotAudioPlayer.play()
					amountLabel.text = str(floor(currentAmount))
				
				lastMouseVelocity.x = mouseVel.x
				# Tilt over pot
				rotation_degrees = lerp(rotation_degrees, -145.0, delta * 5.0)
		else:
			# Not over pot, reset tilt
			rotation_degrees = lerp(rotation_degrees, 0.0, delta * 5.0)
			if ingredientType == IngredientType.SHAKER:
				lastMouseVelocity = Vector2.ZERO
			StopPouring()
