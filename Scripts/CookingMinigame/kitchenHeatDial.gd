# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Button

# SIGNAL
signal ValueChanged(value: float)

# DEFAULT STARTING POSITION
@export_enum("High (100)", "Off (0)", "Low (25)", "Medium (50)") var initialSetting: int = 1
# don't ask about the order, I messed up something and this fixed it when nothing else did 😭

@export_group("Click Feedback Line")
@export var clickLineColor: Color = Color.CYAN
@export var clickLineWidth: float = 3

# NODES
@onready var dialArt: Sprite2D = $DialArt
@onready var clickIndicatorLine: Line2D = $ClickIndicatorLine

# Mapping
var snapPoints: Array[float] = [100.0, 0.0, 25.0, 50.0]
var _snapAngles: Array[float] = [PI / 2.0, PI, -PI / 2.0, 0.0]

# STATES
var _value: float = 0.0
var _currentSnapIndex: int = 0
var _currentAngle: float = PI / 2.0

var _isDragging: bool = false
var _dragStartAngle: float = 0.0
var _dragStartMouseAngle: float = 0.0

func _ready():
	# set initial angle based on inspector assets
	SetSnapIndex(initialSetting, false)
	
	# connect
	self.button_down.connect(OnButtonDown)
	self.button_up.connect(OnButtonUp)
	
	# setup line
	clickIndicatorLine.width = clickLineWidth # TODO: Investigate why this seems to do nothing :/
	clickIndicatorLine.default_color = clickLineColor
	clickIndicatorLine.points = [Vector2.ZERO, Vector2.ZERO]
	clickIndicatorLine.visible = false
	
	if dialArt:
		dialArt.position = size / 2.0

func GetValue() -> float:
	return _value

func OnButtonDown():
	_isDragging = true
	clickIndicatorLine.visible = true
	
	# Store start angles
	var center = size / 2.0
	var vectorToMouse = get_local_mouse_position() - center
	_dragStartMouseAngle = vectorToMouse.angle()
	_dragStartAngle = _currentAngle
	
	get_viewport().set_input_as_handled()
	DrawClickLine(get_local_mouse_position())

func OnButtonUp():
	_isDragging = false
	clickIndicatorLine.visible = false
	
	# Closest snap point
	var newIndex = FindClosestSnapIndex(_currentAngle)
	SetSnapIndex(newIndex, true)

func _gui_input(event: InputEvent):
	if _isDragging and event is InputEventMouseMotion:
		# new angle based on mouse
		var center = size / 2.0
		var vectorToMouse = event.position - center
		
		var currentMouseAngle = vectorToMouse.angle()
		var angleDelta = angle_difference(_dragStartMouseAngle, currentMouseAngle)
		
		_currentAngle = _dragStartAngle + angleDelta
		
		# Update line
		UpdateArtRotation()
		DrawClickLine(event.position)

func FindClosestSnapIndex(angle: float) -> int:
	var closestIndex = 0
	var minimumDifference = INF
	
	for i in _snapAngles.size():
		var difference = abs(angle_difference(angle, _snapAngles[i]))
		
		if difference < minimumDifference:
			minimumDifference = difference
			closestIndex = i
	
	return closestIndex

func DrawClickLine(localMousePosition: Vector2):
	var center = size / 2.0
	clickIndicatorLine.points = [center, localMousePosition]

func SetSnapIndex(newIndex: int, shouldEmit: bool):
	var isNewSetting = (newIndex != _currentSnapIndex)
	
	_currentSnapIndex = newIndex
	_value = snapPoints[_currentSnapIndex]
	_currentAngle = _snapAngles[_currentSnapIndex]
	
	UpdateArtRotation()
	
	# Only emit if the value actually changed
	if shouldEmit and isNewSetting:
		ValueChanged.emit(_value)

func UpdateArtRotation():
	if dialArt:
		dialArt.rotation = _currentAngle
