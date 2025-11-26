extends Node2D

@onready var background: TextureRect = $Background
@onready var trueStoryText: RichTextLabel = $"Background/True Story Text"
@onready var choicesText: RichTextLabel = $"Background/Choices Text"
@onready var animation: AnimatedSprite2D = $Animation
@onready var title: RichTextLabel = $Solais
var cutsceneMusicPlayer: AudioStreamPlayer2D
var introMusic: AudioStream = preload("res://Assets/Audio/Music/Music 1 lighthouse.wav")

func _ready():
	self.visible = false
	title.modulate.a = 0.0
	trueStoryText.modulate.a = 0.0
	choicesText.modulate.a = 0.0

func Begin():
	TaskManager.shouldBeHidden = true
	self.visible = true
	animation.play("default")
	
	cutsceneMusicPlayer = AudioStreamPlayer2D.new()
	add_child(cutsceneMusicPlayer)
	cutsceneMusicPlayer.stream = introMusic
	cutsceneMusicPlayer.play(2.0)
	
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
	tween.tween_property(cutsceneMusicPlayer, "volume_db", -80.0, 3.0)
	
	await get_tree().create_timer(3.0).timeout
	LastStep()

func LastStep():
	var tween = create_tween()
	
	tween.tween_property(trueStoryText, "modulate:a", 1.0, 5.0)
	tween.tween_property(choicesText, "modulate:a", 1.0, 5.0)
	
	tween.tween_interval(2.0)
	
	tween.tween_property(trueStoryText, "modulate:a", 0.0, 2.5)
	tween.tween_interval(1.25)
	tween.tween_property(choicesText, "modulate:a", 0.0, 2.5)
	
	tween.tween_interval(2.5)
	tween.tween_callback(ContinueToGame)

func ContinueToGame():
	var tween = create_tween()
	
	tween.tween_property(background, "modulate:a", 0.0, 1.0)
	
	await get_tree().create_timer(2.0).timeout
	
	TaskManager.shouldBeHidden = false
	self.visible = false
	animation.stop()
	cutsceneMusicPlayer.stop()
