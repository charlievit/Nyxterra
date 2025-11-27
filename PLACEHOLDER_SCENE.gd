extends AnimatedSprite2D

var musicPlayer: AudioStreamPlayer

var music: AudioStream = preload("res://Assets/Audio/Music/Music 1 lighthouse.wav")

func _ready():
	
	TaskManager.shouldBeHidden = true
	
	musicPlayer = AudioStreamPlayer.new()
	add_child(musicPlayer)
	
	musicPlayer.stream = music
	
	musicPlayer.play(2.0)
	
	self.play("default")
	
