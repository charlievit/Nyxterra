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
@onready var codeNoteUnfolded: Sprite2D = $letterUnfolded
@onready var codeNoteFolded: Sprite2D = $CodeNote
@onready var codeNoteText: RichTextLabel = $codeText
@onready var backButton: Sprite2D = $backButtonIcon
@onready var letterText: RichTextLabel = $boxOpened/letterText
@onready var readClueButton: Button = $readClueButton
@onready var readLetterButton: Button = $boxOpened/readLetterButton

@onready var sfxPlayer: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var openLetterSound: AudioStream = preload("res://Assets/Audio/Lockbox Puzzle/LetterUnfold.mp3")
@onready var openBoxSound: AudioStream = preload("res://Assets/Audio/Lockbox Puzzle/Opened.mp3")
@onready var musicPlayer: AudioStreamPlayer = AudioStreamPlayer.new()
var backgroundMusic: AudioStream = preload("res://Assets/Audio/Music/gearboxGame.mp3")

var goodEndingScenePath: String = "res://Scenes/Cutscenes/goodEndingCredits.tscn"

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
	
	letterFolded.visible = true
	letterUnfolded.visible = false
	codeNoteUnfolded.visible = false
	lockBoxClosed.visible = true
	lockBoxOpen.visible = false
	codeNoteText.visible = false
	backButton.visible = false
	letterText.visible = false
	
	add_child(musicPlayer)
	musicPlayer.stream = backgroundMusic
	musicPlayer.autoplay = true
	musicPlayer.volume_db = -17.0
	musicPlayer.set_bus("Music")
	musicPlayer.play()
	
	# START TUTORIAL SEQUENCE
	TutorialManager.shouldBeHidden = true
	
	TutorialManager.ShowClickTutorial("lockbox", dialOne.global_position)

func _exit_tree():
	musicPlayer.stop()
	musicPlayer.queue_free()
	

func _process(_delta):
	if boxUnlocked:
		pass
	else:
		CheckCode()
		if dialOneValue > 0:
			TutorialManager.CompleteTutorial("lockbox")
	

func CheckCode():
	dialOneValue = dialOne.ReportValue()
	dialTwoValue = dialTwo.ReportValue()
	dialThreeValue = dialThree.ReportValue()
	dialFourValue = dialFour.ReportValue()
	
	if unlockCodeOne == dialOneValue and unlockCodeTwo == dialTwoValue and unlockCodeThree == dialThreeValue and unlockCodeFour == dialFourValue:
		sfxPlayer.stream = openBoxSound
		sfxPlayer.play()
		
		# MARK LOCKBOX AS PLAYED
		GameManager.hasPlayedLockbox = true
		TutorialManager.ClearTutorial()
		
		boxUnlocked = true
		lockBoxClosed.visible = false
		letterFolded.visible = true
		lockBoxOpen.visible = true
		var tween = create_tween()
		tween.tween_property(musicPlayer, "volume_db", -80.0, 1.5)

func _on_read_letter_button_pressed() -> void:
	if letterRead:
		return
	
	letterRead = true
	letterUnfolded.visible = true
	letterText.visible = true
	sfxPlayer.stream = openLetterSound
	sfxPlayer.play()
	GameManager.CompleteTask(currentTaskID)
	readLetterButton.disabled = true
	Dialogic.start("Day_5 Final Letter")
	
	await Dialogic.timeline_ended
	
	SceneLoader.change_scene_with_loading(goodEndingScenePath)


func _on_code_button_pressed() -> void:
	codeNoteFolded.visible = false
	codeNoteUnfolded.visible = true
	sfxPlayer.stream = openLetterSound
	sfxPlayer.play()
	codeNoteText.visible = true
	backButton.visible = true
	readClueButton.disabled = true
	Dialogic.start("Day_5 Lockbox CodeNote Clue")


func _on_back_button_pressed() -> void:
	codeNoteFolded.visible = true
	codeNoteUnfolded.visible = false
	sfxPlayer.stream = openLetterSound
	sfxPlayer.play()
	codeNoteText.visible = false
	backButton.visible = false
	readClueButton.disabled = false
