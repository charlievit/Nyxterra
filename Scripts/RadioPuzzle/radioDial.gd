extends Button

signal ValueChanged(value: float)

@export var minValue: float = 0.0
@export var maxValue: float = 100.0
@export var value: float = 50.0:
	set(newValue):
		SetValue(newValue, false)
	get:
		return _value

@export_group("Click Feedback Line")
@export var clickLineColor: Color = Color.CYAN
@export var clickLineWidth: float = 0.5

@onready var dialArt: Sprite2D = $DialArt
@onready var clickIndicatorLine: Line2D = $ClickIndicatorLine

var _value: float = 50.0
var _isDragging: bool = false
var _currentAngle: float = 0.0
var _dragStartAngle: float = 0.0
var _dragStartMouseAngle: float = 0.0

func _ready():
	_value = value
	
	# set initial angle based on inspector assets
	UpdateAngleFromValue()
	UpdateArtRotation()
	
	self.button_down.connect(OnButtonDown)
	self.button_up.connect(OnButtonUp)
	
	clickIndicatorLine.width = clickLineWidth
	clickIndicatorLine.default_color = clickLineColor
	clickIndicatorLine.points = [Vector2.ZERO, Vector2.ZERO]
	clickIndicatorLine.visible = false
	
	if dialArt:
		dialArt.position = size / 2.0

func OnButtonDown():
	_isDragging = true
	clickIndicatorLine.visible = true
	
	var center = size / 2.0
	var vectorToMouse = get_local_mouse_position() - center
	
	_dragStartMouseAngle = vectorToMouse.angle()
	_dragStartAngle = _currentAngle
	
	get_viewport().set_input_as_handled()
	
	DrawClickLine(get_local_mouse_position())

func OnButtonUp():
	_isDragging = false
	clickIndicatorLine.visible = false

func _gui_input(event: InputEvent):
	if _isDragging and event is InputEventMouseMotion:
		var center = size / 2.0
		var vectorToMouse = event.position - center
		
		var _currentMouseAngle = vectorToMouse.angle()
		
		var angleDelta = _currentMouseAngle - _dragStartMouseAngle
		
		var newAngle = _dragStartAngle + angleDelta
		
		# wrap the angle to stay between -PI and PI
		newAngle = wrapf(newAngle, -PI, PI)
		
		SetValueFromAngle(newAngle)
		DrawClickLine(event.position)

func SetValueFromAngle(newAngle: float):
	_currentAngle = newAngle
	
	var newValue: float
	var midValue = (minValue + maxValue) / 2.0
	
	if newAngle >= -PI / 2.0 and newAngle <= PI / 2.0:
		# top arch 0-100
		newValue = remap(newAngle, -PI / 2.0, PI / 2.0, minValue, maxValue)
	elif newAngle > PI / 2.0:
		# bottom-left arc 100-50
		newValue = remap(newAngle, PI / 2.0, PI / 2.0, minValue, midValue)
	elif newAngle < -PI / 2.0:
		# bottom-right arc 50-0
		newValue = remap(newAngle, -PI, -PI / 2.0, midValue, minValue)
	
	SetValue(newValue, true)

func DrawClickLine(localMousePosition: Vector2):
	var center = size / 2.0
	
	clickIndicatorLine.points = [center, localMousePosition]


func SetValue(newValue: float, shouldEmit: bool):
	_value = newValue
	
	UpdateArtRotation()
	
	if shouldEmit:
		ValueChanged.emit(_value)

func UpdateAngleFromValue():
	var midValue = (minValue + maxValue) / 2.0
	
	if _value >= midValue:
		_currentAngle = remap(_value, midValue, maxValue, 0.0, PI / 2.0)
	else:
		_currentAngle = remap(_value, minValue, midValue, -PI / 2.0, 0.0)

func UpdateArtRotation():
	if dialArt:
		dialArt.rotation = _currentAngle
