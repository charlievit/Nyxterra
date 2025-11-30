extends TextureButton

func onToggleTutorial() -> void:
	GameManager.tutorialMode = not GameManager.tutorialMode
	# self.focus_mode = false
	print(GameManager.tutorialMode)
	TaskManager.ToggleTaskKey()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.pressed.connect(onToggleTutorial)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
