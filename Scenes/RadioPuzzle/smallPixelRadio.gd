extends Node2D

@onready var sineWaveRadioSprite: AnimatedSprite2D = $RadioSprite

func _ready():
	sineWaveRadioSprite.play("sineWaveRadio")
