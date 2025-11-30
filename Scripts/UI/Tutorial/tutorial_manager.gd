extends CanvasLayer

@onready var toggleButton = $ToggleTutorial
@onready var cursor = $Cursor

# State Tracking
var shouldBeHidden: bool = false:
	set(value):
		shouldBeHidden = value
		UpdateVisibility()

var currentTutorialID: String = ""
var currentTutorialConfig: Dictionary = {}
var lastKnownMode: bool = false

func _ready():
	# Initialize state from GameManager
	lastKnownMode = GameManager.tutorialMode
	toggleButton.button_pressed = GameManager.tutorialMode
	
	cursor.visible = false
	cursor.scale = Vector2(2.5, 2.5)
	UpdateVisibility()

func _process(_delta):
	if GameManager.tutorialMode != lastKnownMode:
		lastKnownMode = GameManager.tutorialMode
		
		if toggleButton.button_pressed != GameManager.tutorialMode:
			toggleButton.button_pressed = GameManager.tutorialMode
			
		RefreshCursorState()
		
	if toggleButton.button_pressed != GameManager.tutorialMode:
		pass

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
	if id == currentTutorialID:
		if "completed_tutorials" in GameManager:
			GameManager.completed_tutorials[id] = true
		else:
			GameManager.set("completed_tutorials", {id: true}) 
		
		cursor.StopTutorial()

func ClearTutorial():
	cursor.StopTutorial()
	currentTutorialID = ""
	currentTutorialConfig = {}

func RefreshCursorState():
	if shouldBeHidden:
		cursor.StopTutorial()
		return
	
	var isCompleted = false
	if "completed_tutorials" in GameManager and GameManager.completed_tutorials.has(currentTutorialID):
		isCompleted = true

	var shouldShow = GameManager.tutorialMode or not isCompleted
	
	if shouldShow and not currentTutorialConfig.is_empty():
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

func UpdateVisibility():
	visible = !shouldBeHidden
	if shouldBeHidden:
		cursor.StopTutorial()
