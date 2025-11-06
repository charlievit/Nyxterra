extends Node2D

@onready var player = $PlayerPlaceholder
@onready var mainCamera = $MainStaticCamera
@onready var zoomCamera = $"Control_GAME SCREEN UI/SubViewportContainer/SubViewport/ZoomCamera"
@onready var SubVPort = $"Control_GAME SCREEN UI/SubViewportContainer/SubViewport"

func _ready() -> void:
	mainCamera.enabled = false
	zoomCamera.enabled = true
	zoomCamera.make_current()
	
	SubVPort.world_2d = get_world_2d()
	
func _process(_delta):
	zoomCamera.global_position = player.global_position
