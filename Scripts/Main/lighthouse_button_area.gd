extends Control

@onready var lockbox = $BOTTOM/MiniLockbox
@onready var wallCrack = $BOTTOM/Cracks
@onready var window = $MIDDLE/Window
@onready var brokenWindow = $MIDDLE/WindowBoarded

func _ready() -> void:
	lockbox.visible = GameManager.lockBoxVisible
	wallCrack.visible = GameManager.introScenePlayed
	window.visible = not GameManager.introScenePlayed
	brokenWindow.visible = GameManager.introScenePlayed
