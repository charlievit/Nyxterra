extends Control

@onready var black: TextureRect = $"Black Background"
@onready var animation: AnimatedSprite2D = $Animation
@onready var credits: RichTextLabel = $Credits

var windSoundPlayer: AudioStreamPlayer
var oceanPlayer: AudioStreamPlayer
var songPlayer: AudioStreamPlayer

var windSound: AudioStream = preload("res://Assets/Audio/Cutscenes/Wind.mp3")
var oceanSound: AudioStream = preload("res://Assets/Audio/Cutscenes/Ocean Waves.mp3")
var song: AudioStream = preload("res://Assets/Audio/Music/Light keeper.mp3")

var timeLeft: float = 181.56

func _ready():
	TaskManager.shouldBeHidden = true
	TutorialManager.shouldBeHidden = true
	
	# Set up audio players
	windSoundPlayer = AudioStreamPlayer.new()
	oceanPlayer = AudioStreamPlayer.new()
	songPlayer = AudioStreamPlayer.new()
	
	add_child(windSoundPlayer)
	add_child(oceanPlayer)
	add_child(songPlayer)
	
	windSoundPlayer.stream = windSound
	oceanPlayer.stream = oceanSound
	songPlayer.stream = song
	
	windSoundPlayer.play()
	oceanPlayer.play()
	songPlayer.play()
	
	windSoundPlayer.volume_db = -80.0
	oceanPlayer.volume_db = -80.0
	songPlayer.volume_db = -80.0
	
	animation.modulate.a = 0.0
	animation.play("default")
	
	await get_tree().create_timer(2.0).timeout
	Begin()

func Begin():
	var tween = create_tween()
	var fadeInTime = 18.0
	timeLeft -= fadeInTime
	tween.set_parallel(true)
	tween.tween_property(animation, "modulate:a", 1.0, 18.0)
	tween.tween_property(windSoundPlayer, "volume_db", -20.0, 18.0)
	tween.tween_property(oceanPlayer, "volume_db", -20.0, 18.0)
	tween.tween_property(songPlayer, "volume_db", -5.0, 18.0)
	tween.set_parallel(false)
	tween.tween_callback(RollCredits)

func RollCredits():
	var tween = create_tween()
	
	tween.tween_property(credits, "position:y", -6964, timeLeft)
	
	tween.tween_callback(FadeToBlack)

func FadeToBlack():
	await get_tree().create_timer(6.0).timeout
	
	var tween = create_tween()
	
	tween.tween_property(animation, "modulate:a", 0.0, 6.0)
	tween.set_parallel(true)
	tween.tween_property(oceanPlayer, "volume_db", -80.0, 6.0)
	tween.tween_property(windSoundPlayer, "volume_db", -80.0, 6.0)
	tween.set_parallel(false)
	
	tween.tween_callback(Fin)

func Fin():
	CutsceneManager.EndGame()
