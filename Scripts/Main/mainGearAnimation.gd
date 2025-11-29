extends AnimatedSprite2D

func _process(_delta):
	if GameManager.gearBoxSolved:
		if not is_playing():
			play("default")
		return

	match GameManager.currentDay:
		1:
			if is_playing():
				stop()
				frame = 0
		_:
			if not is_playing():
				play("default")
