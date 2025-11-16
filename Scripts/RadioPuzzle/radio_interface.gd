# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Node2D

signal stationTuned

#region Variable Declaration
# INSPECTOR
@export var lineLength: int = 500
@export var lineSegments: int = 50
@export var lineWidth: float = 6
@export var lineSpeed: float = 1.0

# SCENE
@onready var playerWave: Line2D = $"RadioFace/Player Wave"
@onready var targetWave: Line2D = $"RadioFace/Target Wave"
@onready var amplitudeDial: Button = $RadioFace/AmplitudeDial
@onready var frequencyDial: Button = $RadioFace/FrequencyDial
@onready var machineOff: Sprite2D = $RadioFace/SineWaveRadioOff
@onready var machineOn: AnimatedSprite2D = $RadioFace/animatedSineWaveRadioFace
@onready var powerButton: Button = $RadioFace/powerButton

# COLORS
@export var playerWaveColor: Color = Color.CYAN
@export var targetWaveColor: Color = Color(1.0, 1.0, 0.5, 0.4) #semi-transparent yellow
@export var tunedInColor: Color = Color.LIME

# PLAYER WAVE
var playerAmplitude: float = 50.0
var playerFrequency: float = 5.0

# TARGET WAVE
var targetAmplitude: float
var targetFrequency: float

# LOGIC & TOLERANCES
var animationPhase: float = 0.0
var currentStationIsTuned: bool = false
var isPoweredOn: bool = false
@export var amplitudeTolerance: float = 2.0 #pixels
@export var frequencyTolerance: float = 0.1 #cycles
# TESTING
#@onready var sensitivityTESTINGLabel = $RadioFace/sensitivityUINum
# -------
#endregion

func _ready():
	# Set the initial wave colors
	playerWave.default_color = playerWaveColor
	targetWave.default_color = targetWaveColor
	
	amplitudeDial.ValueChanged.connect(SetPlayerAmplitude)
	frequencyDial.ValueChanged.connect(SetPlayerFrequency)
	
	machineOn.speed_scale = 1
	
	# TESTING
	SetTargetStation(randf_range(10.0, 100.0), randf_range(1.0, 10.0))
	# -------
	
func _process(delta):
	if not isPoweredOn:
		return
	
	# TESTING
	playerWave.width = lineWidth
	targetWave.width = lineWidth
	# -------
	
	var averageFrequency = (playerFrequency + targetFrequency) / 2.0
	
	machineOn.speed_scale = averageFrequency * lineSpeed
	print(machineOn.speed_scale)
	
	# ANIMATE THE WAVES
	animationPhase += lineSpeed * TAU * delta
	animationPhase = fmod(animationPhase, TAU)
	
	# REDRAW WAVES
	DrawWave(playerWave, playerAmplitude, playerFrequency)
	if targetAmplitude != null:
		DrawWave(targetWave, targetAmplitude, targetFrequency)
	
	if currentStationIsTuned:
		ToggleButtons(currentStationIsTuned)
		return
	
	# CHECK FOR TUNING
	CheckForMatch()

func _on_power_button_pressed():
	isPoweredOn = not isPoweredOn
	
	machineOff.visible = not isPoweredOn
	machineOn.visible = isPoweredOn
	
	playerWave.visible = isPoweredOn
	targetWave.visible = isPoweredOn
	
	if isPoweredOn:
		machineOn.play()
	else:
		machineOn.stop()

func ToggleButtons(toggleState: bool):
	amplitudeDial.disabled = toggleState
	frequencyDial.disabled = toggleState

func DrawWave(line: Line2D, amp: float, freq: float):
	var points = PackedVector2Array()
	var step = lineLength / float(lineSegments)
	
	for i in lineSegments + 1:
		var x = i * step
		
		var angle = (x / lineLength) * TAU * freq + animationPhase
		
		var y = sin(angle) * amp
		
		points.append(Vector2(x, y))
	
	line.points = points

func CheckForMatch():
	if targetAmplitude == null or currentStationIsTuned:
		return
	
	var ampMatch = abs(playerAmplitude - targetAmplitude) < amplitudeTolerance
	var freqMatch = abs(playerFrequency - targetFrequency) < frequencyTolerance

	
	if ampMatch and freqMatch:
		if not currentStationIsTuned:
			playerAmplitude = targetAmplitude
			playerFrequency = targetFrequency
			print("Station tuned in.")
			currentStationIsTuned = true
			ToggleButtons(currentStationIsTuned)
			playerWave.default_color = tunedInColor
			emit_signal("stationTuned")
			# TODO: audioStationNoiseLoopHere.play()

# PUBLIC FUNCTION
# TODO: call this in the main game sript to set the target radio station for the day
func SetTargetStation(newAmp: float, newFreq: float):
	print("New Station Set: A=%.2f, F=%.2f" % [newAmp, newFreq])
	
	targetAmplitude = newAmp
	targetFrequency = newFreq
	
	# reset tuning status
	currentStationIsTuned = false
	ToggleButtons(currentStationIsTuned)
	playerWave.default_color = playerWaveColor

func SetPlayerAmplitude(newAmp: float):
	playerAmplitude = newAmp
	playerAmplitude = clamp(playerAmplitude, 5.0, 100)
	print(playerAmplitude)

func SetPlayerFrequency(newFreq: float):
	playerFrequency = newFreq / 10
	playerFrequency = clamp(playerFrequency, 0.5, 10.0)
	print(playerFrequency)


#region TESTING
#func _on_sensitivity_down_button_pressed() -> void:
#	amplitudeDial.sensitivity -= 0.1
#	frequencyDial.sensitivity -= 0.1

#func _on_sensitivity_up_button_pressed() -> void:
#	amplitudeDial.sensitivity += 0.1
#	frequencyDial.sensitivity += 0.1
#endregion TESTING
