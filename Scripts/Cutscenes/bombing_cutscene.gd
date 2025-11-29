extends Node2D

@onready var black: TextureRect = $"Black Background"
@onready var animation: AnimatedSprite2D = $Animation

var windSoundPlayer: AudioStreamPlayer
var engineSoundPlayer: AudioStreamPlayer
var hatchSoundPlayer: AudioStreamPlayer
var bombPlayer: AudioStreamPlayer
var oceanPlayer: AudioStreamPlayer

var windSound: AudioStream = preload("res://Assets/Audio/Cutscenes/Wind.mp3")
var engingSound: AudioStream = preload("res://Assets/Audio/Cutscenes/airplane noise.mp3")
var hatchSound: AudioStream = preload("res://Assets/Audio/Cutscenes/hatch opening.mp3")
var bombSound: AudioStream = preload("res://Assets/Audio/Cutscenes/Bombing.mp3")
var oceanSound: AudioStream = preload("res://Assets/Audio/Cutscenes/Ocean Waves.mp3")

var originalScale
var originalPosition

func _ready():
	TaskManager.shouldBeHidden = true
	
	originalScale = animation.scale
	originalPosition = animation.global_position
	
	# Set up audio players
	windSoundPlayer = AudioStreamPlayer.new()
	engineSoundPlayer = AudioStreamPlayer.new()
	hatchSoundPlayer = AudioStreamPlayer.new()
	bombPlayer = AudioStreamPlayer.new()
	oceanPlayer = AudioStreamPlayer.new()
	
	add_child(windSoundPlayer)
	add_child(engineSoundPlayer)
	add_child(hatchSoundPlayer)
	add_child(bombPlayer)
	add_child(oceanPlayer)
	
	windSoundPlayer.stream = windSound
	engineSoundPlayer.stream = engingSound
	hatchSoundPlayer.stream = hatchSound
	bombPlayer.stream = bombSound
	oceanPlayer.stream = oceanSound
	
	windSoundPlayer.play()
	engineSoundPlayer.play(1.33)
	
	oceanPlayer.play()
	oceanPlayer.volume_db = -80.0
	
	animation.modulate.a = 0.0
	animation.play("planeFlyNight")
	BeginFadeIn()

func BeginFadeIn():
	var tween = create_tween()
	
	tween.tween_property(animation, "modulate:a", 1.0, 1.0)
	tween.tween_property(engineSoundPlayer, "volume_db", 0.0, 1.0)
	
	tween.tween_interval(0.5)
	tween.tween_callback(BeginZoom)

func BeginZoom():
	var tween = create_tween()
	
	tween.set_parallel(true)
	tween.tween_property(animation, "global_scale", Vector2(4.8, 4.8), 4.0)
	tween.tween_property(animation, "global_position", Vector2(11, 149), 4.0)
	tween.set_parallel(false)
	tween.tween_callback(CutToHatch)

func CutToHatch():
	hatchSoundPlayer.play()
	animation.scale = originalScale
	animation.global_position = originalPosition
	animation.play("bombDropNight")
	engineSoundPlayer.play(7.35)
	FadeToBlack()

func FadeToBlack():
	var tween = create_tween()
	
	tween.tween_property(animation, "modulate:a", 0.0, 2.45)
	
	tween.tween_callback(PlayBomb)

func PlayBomb():
	var tween = create_tween()
	bombPlayer.play()
	
	tween.tween_property(animation, "modulate:a", 0.0, 4.0)
	tween.tween_property(bombPlayer, "volume_db", -80.0, 3.0)
	
	tween.tween_callback(CutToSmokePlume)

func CutToSmokePlume():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(windSoundPlayer, "volume_db", -30.0, 1.5)
	tween.tween_property(oceanPlayer, "volume_db", -5.0, 3.0)
	tween.set_parallel(false)
	animation.play("smokePlume")
	tween.set_parallel(true)
	tween.tween_property(animation, "modulate:a", 1.0, 3.0)
	tween.tween_property(engineSoundPlayer, "volume_db", -80.0, 3.0)
	tween.set_parallel(false)
	tween.tween_callback(End)

func End():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(oceanPlayer, "volume_db", -80.0, 32.0)
	tween.tween_property(windSoundPlayer, "volume_db", -80.0, 32.0)
	
	await get_tree().create_timer(8.0).timeout
	
	if GameManager.isBadEnding:
		print("Bad Ending Reached. Ending Game.")
		CutsceneManager.EndGame()
	else:
		print("Day 0 Transition: Playing Intro/Arrival Cutscene.")
		GameManager.introPlayed = true
		CutsceneManager.PlayCutscene("res://Scenes/Cutscenes/arrival_cutscene.tscn")
