extends Node2D

@onready var background: TextureRect = $Background
@onready var trueStoryText: RichTextLabel = $"Background/True Story Text"
@onready var choicesText: RichTextLabel = $"Background/Choices Text"
@onready var animation: AnimatedSprite2D = $Animation
@onready var title: RichTextLabel = $Solais
var cutsceneMusicPlayer: AudioStreamPlayer2D
var introMusic: AudioStream = preload("res://Assets/Audio/Music/Light keeper.mp3")
var cutsceneWavesPlayer: AudioStreamPlayer2D
var waveSound: AudioStream = preload("res://Assets/Audio/Cutscenes/Ocean Waves.mp3")

func _ready():
	TaskManager.shouldBeHidden = true
	TutorialManager.shouldBeHidden = true
	
	print("Cutscene running")
	Begin()

func Begin():
	animation.play("default")
	title.modulate.a = 0.0
	trueStoryText.modulate.a = 0.0
	choicesText.modulate.a = 0.0
	
	cutsceneWavesPlayer = AudioStreamPlayer2D.new()
	add_child(cutsceneWavesPlayer)
	cutsceneWavesPlayer.stream = waveSound
	cutsceneWavesPlayer.volume_db = -3.0 # Set a lower volume for background
	cutsceneWavesPlayer.play()
	cutsceneMusicPlayer = AudioStreamPlayer2D.new()
	add_child(cutsceneMusicPlayer)
	cutsceneMusicPlayer.stream = introMusic
	cutsceneMusicPlayer.play(18.0)
	cutsceneMusicPlayer.volume_db = 5.0
	
	await get_tree().create_timer(9.0).timeout
	FadeInTitle()

func FadeInTitle():
	var tween = create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 2.0)
	await get_tree().create_timer(11.0).timeout
	FadeToBlack()

func FadeToBlack():
	var tween = create_tween()
	tween.tween_property(animation, "modulate:a", 0.0, 7.0)
	await get_tree().create_timer(7.0).timeout
	EndScene()

func EndScene():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title, "modulate:a", 0.0, 3.0)
	await get_tree().create_timer(3.0).timeout
	LastStep()

func LastStep():
	var tween = create_tween()
	tween.tween_property(trueStoryText, "modulate:a", 1.0, 2.5)
	tween.tween_property(choicesText, "modulate:a", 1.0, 2.5)
	tween.tween_interval(2.0)
	tween.tween_property(trueStoryText, "modulate:a", 0.0, 1.5)
	tween.tween_interval(1.25)
	tween.tween_property(choicesText, "modulate:a", 0.0, 1.5)
	tween.tween_property(cutsceneMusicPlayer, "volume_db", -80.0, 3.0)
	tween.tween_property(cutsceneWavesPlayer, "volume_db", -40.0, 3.0) # NEW: Waves fade-out
	tween.tween_callback(ContinueToGame)

func ContinueToGame():
	GameManager.introScenePlayed = true
	GameManager.PlayBGM()
	# This triggers CutsceneManager to load Main. 
	# CutsceneManager will see the pending Day 1 (preserved from Bombing) and trigger GameManager.StartDay(1)
	CutsceneManager.FinishCutscene()
