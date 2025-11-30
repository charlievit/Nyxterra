extends AnimatedSprite2D

var movementTween: Tween
var dialCenter: Vector2
var dialRadius: float

func SetupClickMoveClick(startPosition: Vector2, endPosition: Vector2, duration: float = 1.0):
	ResetTween()
	visible = true
	
	movementTween = create_tween().set_loops()
	
	movementTween.tween_callback(func():
		global_position = startPosition
		play("Single Click"))
	
	movementTween.tween_interval(0.4)
	
	movementTween.tween_callback(func():
		stop()
		frame = 2)
	
	movementTween.tween_property(self, "global_position", endPosition, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	movementTween.tween_callback(func():
		play("Single Click"))
	movementTween.tween_interval(0.6)
	

func SetupStatic(targetPosition: Vector2, animationName: String):
	ResetTween()
	global_position = targetPosition
	play(animationName)
	visible = true

func SetupDrag(startPosition: Vector2, endPosition: Vector2, duration: float = 1.0):
	ResetTween()
	visible = true
	play("Hold Click")
	
	movementTween = create_tween().set_loops()
	
	movementTween.tween_callback(func(): global_position = startPosition)
	movementTween.tween_interval(0.2)
	movementTween.tween_property(self, "global_position", endPosition, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	movementTween.tween_interval(0.2)

func SetupDial(targetNode: Control, duration: float = 2.0):
	ResetTween()
	visible = true
	play("Hold Click")
	
	var rect = targetNode.get_global_rect()
	dialCenter = rect.get_center()
	
	dialRadius = (rect.size.x / 2.0) * 0.7
	
	UpdateCirclePosition(-PI / 2.0)
	
	movementTween = create_tween()
	
	if movementTween:
		movementTween.set_loops()
		movementTween.tween_method(UpdateCirclePosition, -PI / 2.0, 3 * PI / 2.0, duration)

func UpdateCirclePosition(angleRadius: float):
	var dialOffset = Vector2(cos(angleRadius), sin(angleRadius)) * dialRadius
	global_position = dialCenter + dialOffset

func StopTutorial():
	ResetTween()
	stop()
	visible = false

func ResetTween():
	if movementTween:
		movementTween.kill()
		movementTween = null
