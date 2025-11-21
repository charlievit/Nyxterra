extends Node2D

@onready var lockSection: AnimatedSprite2D = $AnimatedSprite2D
@onready var button: Button = $Button

var animations: Array = ["0", "0to1", "1to2", "2to3", "3to4", "4to5", "5to6", "6to7", "7to8", "8to9", "9to0"]
var currentAnimationIndex: int = 0
var currentDialValue = 0

@onready var dialSoundPlayer: AudioStreamPlayer2D = $AudioStreamPlayer2D

@onready var clickSound: AudioStream = preload("res://Assets/Audio/Lockbox Puzzle/Input.mp3")

func _ready():
	currentAnimationIndex = 0
	lockSection.animation = "0"
	currentDialValue = 0
	dialSoundPlayer.stream = clickSound

func Increment():
	dialSoundPlayer.play()
	currentAnimationIndex += 1
	currentDialValue += 1
	if currentDialValue > 9:
		currentDialValue = 0
	print(currentDialValue)
	if currentAnimationIndex > animations.size() - 1:
		currentAnimationIndex = 1
	lockSection.play(animations[currentAnimationIndex])

func ReportValue() -> int:
	return currentDialValue
	
func _on_button_pressed() -> void:
	Increment()
