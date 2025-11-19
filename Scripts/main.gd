extends Node2D

enum DayState {
	SUN_RISING,
	DAY_IDLE,
	NIGHT_FADING,
	MOON_RISING,
	NIGHT_IDLE
}

signal dayArrived
signal nightArrived

#region Variable Declaration
# Camera Variables
@onready var player = $Player
@onready var mainCamera = $MainStaticCamera
@onready var zoomCamera = $"Control_GAME SCREEN UI/SubViewportContainer/SubViewport/ZoomCamera"
@onready var SubVPort = $"Control_GAME SCREEN UI/SubViewportContainer/SubViewport"

# Camera Boundaries
@export_group("Camera Limits")
@export var cameraLimitLeft: int = 68
@export var cameraLimitRight: int = 264

@export var currentState = DayState.NIGHT_IDLE
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
#endregion

func _ready() -> void:
	# Initialize camera settings for the "reverse minimap" effect.
	mainCamera.enabled = false
	zoomCamera.enabled = true
	zoomCamera.make_current()
	SubVPort.world_2d = get_world_2d()
	
	sun.position = sunStartPosition
	moon.position = moonStartPosition
	nightBackground.modulate.a = 1.0
	snowFall.modulate.a = 1.0
	
	currentState = DayState.NIGHT_IDLE
	
	TaskManager.shouldBeHidden = false
	
func _process(delta):
	# Force the zoomed-in camera to follow the player every frame without showing off-screen details
	var visibleSize = Vector2(SubVPort.size) / zoomCamera.zoom
	var halfWidth = visibleSize.x / 2.0
	
	var minX = cameraLimitLeft + halfWidth
	var maxX = cameraLimitRight - halfWidth
	
	var targetPosition = player.global_position
	
	if maxX > minX:
		targetPosition.x = clamp(targetPosition.x, minX, maxX)
	
	zoomCamera.global_position = targetPosition
	
	#print(player.global_position)
	#print(zoomCamera.global_position)
	#print("State: ", DayState.keys()[currentState]) # Debugging done, safe to remove
	
	match currentState:
		DayState.SUN_RISING:
			#print("Sun rising.")
			cycleProgress += delta / riseDuration
			
			# Move Sun Up and fade night sky out
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
				currentState = DayState.DAY_IDLE
				
				# Force final values to prevent visual floating point errors
				sun.position.y = endY_Pos
				nightBackground.modulate.a = 0.0
				snowFall.modulate.a = 0.0
				
				#print("Sun risen. Wait to start night...")
				emit_signal("dayArrived")
		
		DayState.DAY_IDLE:
			sun.position.y = endY_Pos
			sunRiseGradient.position = gradientStartPosition
			nightBackground.modulate.a = 0.0
			snowFall.modulate.a = 0.0
			#print("Day idling.")
			StartNightCycle()
		
		DayState.NIGHT_FADING:
			#print("Night fading.")
			cycleProgress += delta / riseDuration
			
			# Sun is still off screen, fade the night sky back in
			nightBackground.modulate.a = lerp(0.0, 1.0, cycleProgress)
			snowFall.modulate.a = lerp(0.0, 1.0, cycleProgress)
			
			if cycleProgress >= 1.0:
				cycleProgress = 0.0
				currentState = DayState.MOON_RISING
				
				# Reset Moon position
				moon.position = moonStartPosition
				nightBackground.modulate.a = 1.0
				snowFall.modulate.a = 1.0
		
		DayState.MOON_RISING:
			#print("Moon rising.")
			cycleProgress += delta / riseDuration
			
			# Move Moon Up
			moon.position.y = lerp(moonStartPosition.y, endY_Pos, cycleProgress)
			# Night background stays dark
			
			if cycleProgress >= 1.0:
				cycleProgress = 0.0
				currentState = DayState.NIGHT_IDLE # Go to new pause state
				
				moon.position.y = endY_Pos
				emit_signal("nightArrived")

		DayState.NIGHT_IDLE:
			moon.position.y = endY_Pos
			nightBackground.modulate.a = 1.0
			snowFall.modulate.a = 1.0
			sunRiseGradient.position = gradientStartPosition
			#print("Night idling.")
			StartDayCycle()

func StartNightCycle():
	if currentState == DayState.NIGHT_IDLE:
		#print("Starting night cycle.")
		currentState = DayState.NIGHT_FADING
		cycleProgress = 0.0
	else:
		currentState = DayState.NIGHT_IDLE
		StartNightCycle()

func StartDayCycle():
	if currentState == DayState.NIGHT_IDLE:
		#print("Starting day cycle.")
		currentState = DayState.SUN_RISING
		cycleProgress = 0.0
		
		sun.position = sunStartPosition
		sunRiseGradient.position = gradientStartPosition
	else:
		currentState = DayState.NIGHT_IDLE
		StartDayCycle()
