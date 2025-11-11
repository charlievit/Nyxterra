extends Area2D

signal gear_clicked

@onready var gearSprite: Sprite2D = $Sprite
@onready var meshShape: CollisionShape2D = $MeshShape

@export var radius: int = 0
@export var toothCount: int = 0

var isPowered: bool = false
var rotationSpeed: float = 0.0
var currentDriver: Area2D = null

var originatingButton: Button = null
var currentPeg: Node2D = null

func _ready():
	monitoring = true
	monitorable = true
	
	self.input_event.connect(_on_input_event)
	
	if radius > 0:
		if gearSprite and gearSprite.texture:
			var scaleValue = radius / (gearSprite.texture.get_width() / 2.0)
			gearSprite.scale = Vector2(scaleValue, scaleValue)
		
		if meshShape:
			meshShape.shape.radius = radius

func setup(rad: int, teeth: int, tex: Texture, button: Button, peg: Node2D):
	monitoring = true
	monitorable = true
	
	input_pickable = true
	
	radius = rad
	toothCount = teeth
	
	originatingButton = button
	currentPeg = peg
	
	if gearSprite:
		gearSprite.texture = tex
	
		if gearSprite.texture:
			var scaleValue = radius / (gearSprite.texture.get_width() / 2.0)
			gearSprite.scale = Vector2(scaleValue, scaleValue)
	else:
		print_debug("BaseGear Error: Node 'Sprite' not found! Gear will be invisible.")
	
	if meshShape:
		meshShape.shape.radius = radius
	else:
		print_debug("BaseGear Error: Node 'MeshShape' not found! Gear will have no collision.")

func _process(delta):
	if isPowered:
		gearSprite.rotate(rotationSpeed * delta)

func powerOn(driverGear: Area2D):
	# FIRST: calculate the speet ratio using teeth numbers
	var gearRatio = float(driverGear.toothCount) / float(self.toothCount)
	var newSpeed = -driverGear.rotationSpeed * gearRatio
	
	# SECOND: snap the initial rotation only if the driver gear has changed
	if currentDriver != driverGear:
		# calculate the angle (in radians) for a single tooth on each gear
		var selfToothAngle = TAU / float(self.toothCount)
		# calculate the angle of the line connecting the two gears
		var contactAngle = driverGear.global_position.angle_to_point(self.global_position)
		# get the driver gear's current sprite rotation
		var driverGearRotation = driverGear.gearSprite.rotation
		# calculate the new rotation using gear ratio formulas
		var newRotation = -driverGearRotation * gearRatio - contactAngle * (gearRatio + 1.0) - (TAU / 2.0) + (selfToothAngle / 2.0)
		# set the gear's rotation
		self.gearSprite.rotation = newRotation
		# store this gear as our new driver gear
		currentDriver = driverGear
	
	# FINALLY: set the states for this frame
	isPowered = true
	rotationSpeed = newSpeed

func isMeshingWith(otherGear: Area2D) -> bool:
	var required_distance = self.radius + otherGear.radius
	
	var actual_distance = self.global_position.distance_to(otherGear.global_position)
	
	var MESH_TOLERANCE = 5.0 
	
	return actual_distance <= (required_distance + MESH_TOLERANCE)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("gear_clicked")
