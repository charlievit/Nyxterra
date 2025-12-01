extends TextureButton

func onToggleTutorial() -> void:
	# Toggle the global state
	GameManager.tutorialMode = not GameManager.tutorialMode
	
	# Force TutorialManager to update visuals immediately
	TutorialManager.RefreshCursorState()
	
	self.focus_mode = Control.FOCUS_NONE
	TaskManager.ToggleTaskKey()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.pressed.connect(onToggleTutorial)
	# Set initial button state to match global setting
	self.button_pressed = GameManager.tutorialMode

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Keep visual state in sync if changed elsewhere (e.g. TutorialManager script)
	if self.button_pressed != GameManager.tutorialMode:
		self.button_pressed = GameManager.tutorialMode
