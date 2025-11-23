extends Node2D

signal dayArrived
signal nightArrived

#region Variable Declaration
# Camera Variables
@onready var player = $Player
@onready var mainCamera = $MainStaticCamera
@onready var zoomCamera = $"Control_GAME SCREEN UI/SubViewportContainer/SubViewport/ZoomCamera"
@onready var subVPort = $"Control_GAME SCREEN UI/SubViewportContainer/SubViewport"
@onready var subVPortContainer = $"Control_GAME SCREEN UI/SubViewportContainer"
var viewportMapShownSize: Vector2i = Vector2i(817, 648)
var viewportMapShowPosition: Vector2 = Vector2(335, 0)
var viewportMapHiddenSize: Vector2i = Vector2i(1150, 648)
var viewportMapHiddenPosition: Vector2 = Vector2(0, 0)
var isMapHidden: bool = false

# Camera Boundaries
@export_group("Camera Limits")
@export var cameraLimitLeft: int = 68
@export var cameraLimitRight: int = 264

# FIX: Use GameManager.DayState
@export var currentState = GameManager.DayState.NIGHT_IDLE
var cycleProgress: float = 0.0

@export var riseDuration: float = 500.0
@export var sunStartPosition: Vector2 = Vector2(75, 300)
@export var moonStartPosition: Vector2 = Vector2(180, 300)
@export var endY_Pos: float = 10.0

@export var gradientStartPosition: Vector2 = Vector2(120, 600)
@export var gradientPeakY: float = 350

@onready var sunBackground: Sprite2D = $SkyDayBackground
@onready var sun: Sprite2D = $Sun
@onready var sunRiseGradient: Sprite2D = $SunRiseAndSetGradient
@onready var nightBackground: Sprite2D = $SkyNightBackground
@onready var moon: Sprite2D = $Moon
@onready var moonPhase: Sprite2D = $Moon/MoonPhaseCutOut
@onready var snowFall: TileMap = $AnimatedSnowMap

@onready var hapticClickSound = preload("res://Assets/Audio/UI/HapticClick.mp3")

#save & load
@onready var pause_menu : Control = $"Control_GAME SCREEN UI/PauseMenu"
#endregion

func _ready() -> void:
	# CONNECT TO GAMEMANAGER
	# This allows the story to control the sun/moon
	GameManager.requestDayCycle.connect(StartDayCycle)
	GameManager.requestNightCycle.connect(StartNightCycle)
	
	# Initialize camera settings
	mainCamera.enabled = false
	zoomCamera.enabled = true
	zoomCamera.make_current()
	subVPort.world_2d = get_world_2d()
	
	# Initial visual setup (will be overwritten by SyncVisualsToState below)
	sun.position = sunStartPosition
	moon.position = moonStartPosition
	nightBackground.modulate.a = 1.0
	snowFall.modulate.a = 1.0
	
	currentState = GameManager.DayState.NIGHT_IDLE
	
	TaskManager.shouldBeHidden = false
	
	if GameManager.currentDay == -1:
		currentState = GameManager.DayState.NIGHT_FADING
		GameManager.ConsumeSpawnData(player)
	elif GameManager.shouldUseStoredSpawn:
		GameManager.ConsumeSpawnData(player)
	elif SaveManager.has_save():
		SaveManager.reload_from_disk()
		GameManager.apply_save_data()
		player.apply_save_data()
		
	TaskManager.SyncTasksFromGameManagerOnLoad()
	
	currentState = GameManager.daySTATE
	SyncVisualsToState()
	
	#Dialogue System
	var visibleSize = Vector2(subVPort.size) / zoomCamera.zoom
	var halfWidth = visibleSize.x / 2.0
	
	var minX = cameraLimitLeft + halfWidth
	var maxX = cameraLimitRight - halfWidth
	
	var targetPosition = player.global_position
	
	if maxX > minX:
		targetPosition.x = clamp(targetPosition.x, minX, maxX)
	
	zoomCamera.global_position = targetPosition
	add_child(Dialogic.start("Intro"))
		
func _process(delta):
	# Force the zoomed-in camera to follow the player
	var visibleSize = Vector2(subVPort.size) / zoomCamera.zoom
	var halfWidth = visibleSize.x / 2.0
	
	var minX = cameraLimitLeft + halfWidth
	var maxX = cameraLimitRight - halfWidth
	
	var targetPosition = player.global_position
	
	if maxX > minX:
		targetPosition.x = clamp(targetPosition.x, minX, maxX)
	
	zoomCamera.global_position = targetPosition
	
	# Update GameManager with current int value
	GameManager.daySTATE = currentState
	
	match currentState:
		GameManager.DayState.SUN_RISING:
			cycleProgress += delta / riseDuration
			
			sun.position.y = lerp(sunStartPosition.y, endY_Pos, cycleProgress)
			nightBackground.modulate.a = lerp(1.0, 0.0, cycleProgress * 2.5)
			snowFall.modulate.a = lerp(1.0, 0.0, cycleProgress * 2.5)
			
			if cycleProgress <= 0.5:
				var upProgress = cycleProgress * 2.0
				sunRiseGradient.position.y = lerp(gradientStartPosition.y, gradientPeakY, upProgress)
			else:
				var downProgress = (cycleProgress - 0.5) * 2.0
				sunRiseGradient.position.y = lerp(gradientPeakY, gradientStartPosition.y, downProgress)
			
			if cycleProgress >= 1.0:
				cycleProgress = 0.0
				currentState = GameManager.DayState.DAY_IDLE
				
				sun.position.y = endY_Pos
				nightBackground.modulate.a = 0.0
				snowFall.modulate.a = 0.0
				emit_signal("dayArrived")
		
		GameManager.DayState.DAY_IDLE:
			sun.position.y = endY_Pos
			sunRiseGradient.position = gradientStartPosition
			nightBackground.modulate.a = 0.0
			snowFall.modulate.a = 0.0
		
		GameManager.DayState.NIGHT_FADING:
			cycleProgress += delta / riseDuration
			nightBackground.modulate.a = lerp(0.0, 1.0, cycleProgress)
			snowFall.modulate.a = lerp(0.0, 1.0, cycleProgress)
			
			if cycleProgress >= 1.0:
				cycleProgress = 0.0
				currentState = GameManager.DayState.MOON_RISING
				moon.position = moonStartPosition
				nightBackground.modulate.a = 1.0
				snowFall.modulate.a = 1.0
		
		GameManager.DayState.MOON_RISING:
			cycleProgress += delta / riseDuration
			moon.position.y = lerp(moonStartPosition.y, endY_Pos, cycleProgress)
			
			if cycleProgress >= 1.0:
				cycleProgress = 0.0
				currentState = GameManager.DayState.NIGHT_IDLE 
				moon.position.y = endY_Pos
				emit_signal("nightArrived")

		GameManager.DayState.NIGHT_IDLE:
			moon.position.y = endY_Pos
			nightBackground.modulate.a = 1.0
			snowFall.modulate.a = 1.0
			sunRiseGradient.position = gradientStartPosition

# FIX: New function to snap visuals to the correct state instantly on load
func SyncVisualsToState():
	cycleProgress = 0.0 # Reset progress on load to avoid mid-transition weirdness
	
	match currentState:
		GameManager.DayState.SUN_RISING:
			# If we loaded mid-rise, we reset to start of rise. 
			# (Ideally you'd save cycleProgress too, but starting rise is safer than broken state)
			sun.position = sunStartPosition
			nightBackground.modulate.a = 1.0
			snowFall.modulate.a = 1.0
			
		GameManager.DayState.DAY_IDLE:
			sun.position.y = endY_Pos
			sunRiseGradient.position = gradientStartPosition
			nightBackground.modulate.a = 0.0
			snowFall.modulate.a = 0.0
			
		GameManager.DayState.NIGHT_FADING:
			# Reset to start of fade
			sun.position.y = endY_Pos
			nightBackground.modulate.a = 1.0
			snowFall.modulate.a = 1.0
			
		GameManager.DayState.MOON_RISING:
			# Reset to start of moon rise
			moon.position = moonStartPosition
			nightBackground.modulate.a = 1.0
			snowFall.modulate.a = 1.0
			
		GameManager.DayState.NIGHT_IDLE:
			moon.position.y = endY_Pos
			nightBackground.modulate.a = 1.0
			snowFall.modulate.a = 1.0

func StartNightCycle():
	if currentState == GameManager.DayState.DAY_IDLE or currentState == GameManager.DayState.SUN_RISING or currentState == GameManager.DayState.NIGHT_IDLE: 
		print("MAIN: Starting night cycle.")
		currentState = GameManager.DayState.NIGHT_FADING
		cycleProgress = 0.0

func StartDayCycle():
	if currentState == GameManager.DayState.NIGHT_IDLE or currentState == GameManager.DayState.MOON_RISING:
		print("MAIN: Starting day cycle.")
		currentState = GameManager.DayState.SUN_RISING
		cycleProgress = 0.0
		
		sun.position = sunStartPosition
		sunRiseGradient.position = gradientStartPosition

func _input(input: InputEvent):
	if input.is_action_pressed("toggleMap"):
		ToggleMap()

func ToggleMap():
	isMapHidden = !isMapHidden
	var targetPosition = viewportMapShowPosition if not isMapHidden else viewportMapHiddenPosition
	var targetSize = viewportMapShownSize if not isMapHidden else viewportMapHiddenSize
	
	var tweenPosition = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var tweenSize = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tweenPosition.tween_property(subVPortContainer, "position", targetPosition, 1.0)
	tweenSize.tween_property(subVPort, "size", targetSize, 1.0)
	
	var clickPlayer: AudioStreamPlayer2D
	clickPlayer = AudioStreamPlayer2D.new()
	add_child(clickPlayer)
	clickPlayer.stream = hapticClickSound
	clickPlayer.play()
	await get_tree().create_timer(0.5).timeout
	clickPlayer.queue_free()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		pause_menu.toggle()

func _on_toggle_map_pressed() -> void:
	ToggleMap()
