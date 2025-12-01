extends CanvasLayer

@onready var toggleButton = $ToggleTutorial
@onready var cursor = $Cursor

# State Tracking
var shouldBeHidden: bool = false:
	set(value):
		shouldBeHidden = value
		RefreshCursorState() # Immediately update when hidden state changes

var currentTutorialID: String = ""
var currentTutorialConfig: Dictionary = {}
var lastKnownMode: bool = false

func _ready():
	# Initialize state from GameManager
	lastKnownMode = GameManager.tutorialMode
	toggleButton.button_pressed = GameManager.tutorialMode
	
	cursor.visible = false
	cursor.scale = Vector2(2.5, 2.5)
	
	# Initial visibility check
	RefreshCursorState()

func _process(_delta):
	
	if shouldBeHidden:
		self.visible = false
	else:
		self.visible = true
	
	# Detect if the global GameManager mode changed
	if GameManager.tutorialMode != lastKnownMode:
		lastKnownMode = GameManager.tutorialMode
		
		# Sync button visual state
		if toggleButton.button_pressed != GameManager.tutorialMode:
			toggleButton.button_pressed = GameManager.tutorialMode
			
		# NOTE: We no longer refresh cursor state based on mode change
		# because minigame tutorials are now disconnected from this toggle.
			

	# Sync manual button press to GameManager
	if toggleButton.button_pressed != GameManager.tutorialMode:
		# This case handles if the button was clicked this frame
		GameManager.tutorialMode = toggleButton.button_pressed
		lastKnownMode = GameManager.tutorialMode

func ShowClickTutorial(id: String, targetGlobalPosition: Vector2, animationName: String = "Continuous Clicking"):
	currentTutorialID = id
	currentTutorialConfig = {
		"type": "click",
		"position": targetGlobalPosition,
		"animation": animationName
	}
	RefreshCursorState()

func ShowDragTutorial(id: String, startPosition: Vector2, endPosition: Vector2):
	currentTutorialID = id
	currentTutorialConfig = {
		"type": "drag",
		"start": startPosition,
		"end": endPosition
	}
	RefreshCursorState()

func ShowDialTutorial(id: String, targetControlNode: Control):
	currentTutorialID = id
	currentTutorialConfig = {
		"type": "dial",
		"target": targetControlNode
	}
	RefreshCursorState()

func ShowClickMoveClickTutorial(id: String, startPosition: Vector2, endPostition: Vector2):
	currentTutorialID = id
	currentTutorialConfig = {
		"type": "clickMoveClick",
		"start": startPosition,
		"end": endPostition
	}
	RefreshCursorState()

func CompleteTutorial(id: String):
	# Always mark as complete in GameManager, regardless of current mode
	if "completedTutorials" in GameManager:
		GameManager.completedTutorials[id] = true
	else:
		GameManager.set("completedTutorials", {id: true})
	
	# If this was the active tutorial, hide it immediately
	if id == currentTutorialID:
		cursor.StopTutorial()
		currentTutorialID = ""
		currentTutorialConfig = {}

func ClearTutorial():
	cursor.StopTutorial()
	currentTutorialID = ""
	currentTutorialConfig = {}

func RefreshCursorState():
	# 1. Global overrides (Minigame decides if manager is active)
	if shouldBeHidden:
		cursor.StopTutorial()
		return
		
	# 2. Check if specific tutorial is already completed
	var isCompleted = false
	if "completedTutorials" in GameManager and GameManager.completedTutorials.has(currentTutorialID):
		isCompleted = true
		
	if isCompleted:
		cursor.StopTutorial()
		return
		
	# 3. If we got here, we should show the tutorial
	# (Decoupled from GameManager.tutorialMode)
	if not currentTutorialConfig.is_empty():
		match currentTutorialConfig["type"]:
			"click":
				cursor.SetupStatic(currentTutorialConfig["position"], currentTutorialConfig["animation"])
			"drag":
				cursor.SetupDrag(currentTutorialConfig["start"], currentTutorialConfig["end"])
			"dial":
				cursor.SetupDial(currentTutorialConfig["target"])
			"clickMoveClick":
				cursor.SetupClickMoveClick(currentTutorialConfig["start"], currentTutorialConfig["end"])
			_:
				cursor.StopTutorial()
	else:
		cursor.StopTutorial()

func UpdateVisibility():
	visible = !shouldBeHidden
	RefreshCursorState()
