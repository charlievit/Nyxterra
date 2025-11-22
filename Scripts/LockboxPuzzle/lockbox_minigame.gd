extends Node2D

var dialOneValue
var dialTwoValue
var dialThreeValue
var dialFourValue

@onready var dialOne = $boxClosed/LockSection
@onready var dialTwo = $boxClosed/LockSection2
@onready var dialThree = $boxClosed/LockSection3
@onready var dialFour = $boxClosed/LockSection4

@onready var lockBoxClosed: Sprite2D = $boxClosed
var boxUnlocked: bool = false
@export_group("Lockbox Code")
@export var unlockCodeOne: int = 1
@export var unlockCodeTwo: int = 9
@export var unlockCodeThree: int = 3
@export var unlockCodeFour: int = 2

@onready var lockBoxOpen: Sprite2D = $boxOpened
@onready var letterFolded: Sprite2D = $boxOpened/letterFolded
var letterRead = false
@onready var letterUnfolded: Sprite2D = $boxOpened/letterUnfolded

@onready var sfxPlayer: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var openLetterSound: AudioStream = preload("res://Assets/Audio/Lockbox Puzzle/LetterUnfold.mp3")
@onready var openBoxSound: AudioStream = preload("res://Assets/Audio/Lockbox Puzzle/Opened.mp3")

var currentTaskID: String = ""

func _ready():
	TaskManager.shouldBeHidden = true
	
	for key in TaskManager.activeTasks.keys():
		if String(key).contains("LockBox"):
			currentTaskID = key
			break
	
	dialOneValue = 0
	dialTwoValue = 0
	dialThreeValue = 0
	dialFourValue = 0
	
	letterFolded.visible = false
	letterUnfolded.visible = false
	lockBoxClosed.visible = true
	lockBoxOpen.visible = false

func _process(_delta):
	if boxUnlocked:
		pass
	else:
		CheckCode()
	

func CheckCode():
	dialOneValue = dialOne.ReportValue()
	dialTwoValue = dialTwo.ReportValue()
	dialThreeValue = dialThree.ReportValue()
	dialFourValue = dialFour.ReportValue()
	
	if unlockCodeOne == dialOneValue and unlockCodeTwo == dialTwoValue and unlockCodeThree == dialThreeValue and unlockCodeFour == dialFourValue:
		sfxPlayer.stream = openBoxSound
		sfxPlayer.play()
		boxUnlocked = true
		lockBoxClosed.visible = false
		letterFolded.visible = true
		lockBoxOpen.visible = true


func _on_read_letter_button_pressed() -> void:
	if letterRead:
		return
	
	letterRead = true
	letterUnfolded.visible = true
	sfxPlayer.stream = openLetterSound
	sfxPlayer.play()
	GameManager.CompleteTask(currentTaskID)
