extends Node2D

#region Variable Declaration
# Camera Variables
@onready var player = $Player
@onready var mainCamera = $MainStaticCamera
@onready var zoomCamera = $"Control_GAME SCREEN UI/SubViewportContainer/SubViewport/ZoomCamera"
@onready var SubVPort = $"Control_GAME SCREEN UI/SubViewportContainer/SubViewport"
#endregion

func _ready() -> void:
	# Initialize camera settings for the "reverse minimap" effect.
	mainCamera.enabled = false
	zoomCamera.enabled = true
	zoomCamera.make_current()
	SubVPort.world_2d = get_world_2d()
	
func _process(_delta):
	# Force the zoomed-in camera to follow the player every frame
	zoomCamera.global_position = player.global_position
