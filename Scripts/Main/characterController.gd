# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends CharacterBody2D

#region VARIABLES
@export var moveSpeed: float = 90.0

@export_group("Floor Effects")
@export var scalePerFloor: float = 0.1
@export var darkenPerFloor: float = 0.25

# PLACEHOLDER
@onready var sprite: Sprite2D = $Sprite2D
@onready var animSprite: AnimatedSprite2D = $Sprite

# Stores the current floor the player is of for latter mapping of Y-values
var currentFloor: int = 1

# Stores the sprite's starting scale and color (this should be the same at the bottom of each floor)
var baseScale: Vector2 = Vector2.ONE
var animBaseScale: Vector2 = Vector2(0.124, 0.124)
var baseModulation: Color = Color.WHITE

# Y-boundaries
var currentFloorBottomY: float = 425.0
var currentFloorTopY: float = 408.0

var overlappingTeleporters: Array[Area2D] = []
#endregion VARIABLES


func _ready():

	#save & load
	GameManager.player = self
	GameManager.ConsumeSpawnData(self)
	
	self.position = GameManager.playerSpawnPosition
	currentFloor = GameManager.playerSpawnFloor
	
	# Store the sprite's default state
	if sprite:
		baseScale = sprite.scale
		baseModulation = sprite.modulate
	if animSprite:
		animBaseScale = animSprite.scale
	
	# Set initial floor boundaries
	SetFloor(currentFloor)


func _physics_process(_delta):
	# Get input direction and set velocity
	var inputVector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = inputVector * moveSpeed
	
	# Move the character and update the sprite
	move_and_slide()
	UpdateSpriteEffects()
	
	# Update Animation NOTE: PLACEHOLDER
	UpdateAnimation(inputVector)
	
	if Input.is_action_pressed("sprint"):
		moveSpeed = 120
		animSprite.speed_scale = 2.0
	else:
		moveSpeed = 60
		animSprite.speed_scale = 1.0


func _unhandled_input(event: InputEvent):
	# Do nothing if we aren't in a teleporter
	if overlappingTeleporters.is_empty():
		return
	
	# Get the teleporter we are in
	var teleporter = overlappingTeleporters.front()
	
	# Check for 'E' key
	if event.is_action_pressed("ui_accept"):
		if teleporter.has_method("DoTeleport"):
			teleporter.DoTeleport(self)

# called by teleporter on enter
func EnterTeleporterArea(area: Area2D):
	if not overlappingTeleporters.has(area):
		overlappingTeleporters.append(area)

# called by teleporter on exit
func ExitTeleporterArea(area: Area2D):
	if overlappingTeleporters.has(area):
		overlappingTeleporters.erase(area)

func SetFloor(newFloor: int):
	currentFloor = newFloor
	print("Player is now on floor: ", currentFloor)
	
	# Set the Y boundaries based on the floor
	match currentFloor:
		1:
			currentFloorBottomY = 573.0
			currentFloorTopY = 553.0
		2:
			currentFloorBottomY = 482.0
			currentFloorTopY = 462.0
		3:
			currentFloorBottomY = 392.0
			currentFloorTopY = 372.0
		4:
			currentFloorBottomY = 302.0
			currentFloorTopY = 281.0
		5:
			currentFloorBottomY = 211.0
			currentFloorTopY = 195.0

func UpdateSpriteEffects(): # Runs every frame
	if not sprite:
		return
	
	# Calculate how far up the floor the player is (0.0 at bottom, 1.0 at top)
	var percentage = inverse_lerp(currentFloorBottomY, currentFloorTopY, global_position.y)
	
	# Clamp the value
	percentage = clamp(percentage, 0.0, 1.0)
	
	# Calculate the new scale and color amounts
	var scaleAmount = lerp(1.0, 1.0 - scalePerFloor, percentage)
	var colorAmount = lerp(1.0, 1.0 - darkenPerFloor, percentage)
	
	# Apply the new values
	sprite.scale = baseScale * scaleAmount
	animSprite.scale = animBaseScale * scaleAmount
	
	# Modulate RGB only, keeping alpha unchanged
	sprite.modulate.r = baseModulation.r * colorAmount
	sprite.modulate.g = baseModulation.g * colorAmount
	sprite.modulate.b = baseModulation.b * colorAmount
	sprite.modulate.a = baseModulation.a
	
	animSprite.modulate.r = baseModulation.r * colorAmount
	animSprite.modulate.g = baseModulation.g * colorAmount
	animSprite.modulate.b = baseModulation.b * colorAmount
	animSprite.modulate.a = baseModulation.a


func UpdateAnimation(_inputVector: Vector2):
	if velocity.length() > 0:
		# Player is moving
		animSprite.visible = true
		sprite.visible = false
		animSprite.play("walk")
		
		
		# Simple flip for placeholder sprite
		if velocity.x < 0:
			sprite.flip_h = true
			animSprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false
			animSprite.flip_h = false
	else:
		animSprite.visible = false
		sprite.visible = true
		pass
