extends Node2D

@onready var black: TextureRect = $"Black Background"
@onready var animation: AnimatedSprite2D = $Animation
@onready var credits: RichTextLabel = $Credits

var windSoundPlayer: AudioStreamPlayer
var engineSoundPlayer: AudioStreamPlayer
var hatchSoundPlayer: AudioStreamPlayer
var bombPlayer: AudioStreamPlayer
var oceanPlayer: AudioStreamPlayer
var songPlayer: AudioStreamPlayer

var windSound: AudioStream = preload("res://Assets/Audio/Cutscenes/Wind.mp3")
var engingSound: AudioStream = preload("res://Assets/Audio/Cutscenes/airplane noise.mp3")
var hatchSound: AudioStream = preload("res://Assets/Audio/Cutscenes/hatch opening.mp3")
var bombSound: AudioStream = preload("res://Assets/Audio/Cutscenes/Bombing.mp3")
var oceanSound: AudioStream = preload("res://Assets/Audio/Cutscenes/Ocean Waves.mp3")
var song: AudioStream = preload("res://Assets/Audio/Music/Light keeper.mp3")

var originalScale
var originalPosition

func _ready():
	songPlayer = AudioStreamPlayer.new()
	add_child(songPlayer)
	songPlayer.stream = song
	songPlayer.play()
	songPlayer.volume_db = -80.0
	TaskManager.shouldBeHidden = true
	TutorialManager.shouldBeHidden = true
	
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
	engineSoundPlayer.play()
	
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
	bombPlayer.play()
	
	var tween = create_tween()
	tween.tween_property(animation, "modulate:a", 0.0, 4.0)
	tween.tween_property(bombPlayer, "volume_db", -80.0, 3.0)
	
	tween.tween_callback(func() -> void:
		bombPlayer.stop()

		if GameManager.isBadEnding:
			Dialogic.start("Day_5 BadEnding Dialogue")
		else:
			# Start the dialogue
			Dialogic.start("Bombing_Cutscene Dialogue")

		# Wait until the timeline finishes
		await Dialogic.timeline_ended

		# Now call your existing function
		_fade_out_all_audio_and_check()
	)

func CheckForEnding():
	#GameManager.isBadEnding = true # TESTING
	Dialogic.end_timeline()

	if GameManager.isBadEnding:
		CutToSmokePlume()
	else:
		#play cath death audio
		print("Day 0 Transition: Playing Intro/Arrival Cutscene.")
		GameManager.introPlayed = true
		CutsceneManager.PlayCutscene("res://Scenes/Cutscenes/arrival_cutscene.tscn")

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
	tween.tween_callback(EndingCredits)

func _fade_out_all_audio_and_check() -> void:
	var tween := create_tween()
	tween.set_parallel(true)

	# Fade every player you care about
	if is_instance_valid(windSoundPlayer):
		tween.tween_property(windSoundPlayer, "volume_db", -80.0, 2.0)
	if is_instance_valid(engineSoundPlayer):
		tween.tween_property(engineSoundPlayer, "volume_db", -80.0, 2.0)
	if is_instance_valid(oceanPlayer):
		tween.tween_property(oceanPlayer, "volume_db", -80.0, 2.0)
	if is_instance_valid(hatchSoundPlayer):
		tween.tween_property(hatchSoundPlayer, "volume_db", -80.0, 2.0)
	if is_instance_valid(bombPlayer):
		tween.tween_property(bombPlayer, "volume_db", -80.0, 2.0)

	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		# fully stop them once faded
		if is_instance_valid(windSoundPlayer): windSoundPlayer.stop()
		if is_instance_valid(engineSoundPlayer): engineSoundPlayer.stop()
		if is_instance_valid(oceanPlayer): oceanPlayer.stop()
		if is_instance_valid(hatchSoundPlayer): hatchSoundPlayer.stop()
		if is_instance_valid(bombPlayer): bombPlayer.stop()

		CheckForEnding()
	)

func EndingCredits():
	
	var tween = create_tween()
	
	tween.tween_property(songPlayer, "volume_db", -5.0, 18.0)
	
	tween.tween_property(credits, "position:y", -6303, 120.0)
	tween.tween_property(animation, "modulate:a", 0.0, 3.0)
	tween.tween_callback(EndTheGame)

func EndTheGame():
	CutsceneManager.EndGame()
