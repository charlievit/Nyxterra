extends CanvasLayer

# CONFIG
@export var slideSpeed: float = 0.3
var closedPosition: Vector2 = Vector2(940, -110)
var openPosition: Vector2 = Vector2(940, 103)
var shouldBeHidden: bool = false

# NODES
@onready var slideController = $SlideController
@onready var taskList = $SlideController/TaskPanel/VBox/ScrollContainer/TaskList
@onready var arrowIcon = $SlideController/TabButton/ArrowIcon
@onready var alertIcon = $SlideController/TabButton/AlertIcon
@onready var tabButton = $SlideController/TabButton

# STATES
var isOpen: bool = false
var isAnimating: bool = false
var shakeTween: Tween

# TASKS
var activeTasks: Dictionary = {}

func _ready():
	slideController.position = closedPosition
	tabButton.pressed.connect(ToggleWindow)
	
	alertIcon.visible = false
	alertIcon.rotation = 0

func _process(_delta):
	if shouldBeHidden:
		self.visible = false
	else:
		self.visible = true

func _input(event):
	if event.is_action_pressed("toggle_tasks"):
		ToggleWindow()

# CORE LOGIC
func ToggleWindow():
	if isAnimating: return
	
	if not isOpen:
		ClearNotification()
	
	isAnimating = true
	var targetPosition = openPosition if not isOpen else closedPosition
	
	# Slide Animation
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(slideController, "position", targetPosition, slideSpeed)
	tween.finished.connect(func(): isAnimating = false)
	
	# Arrow Rotation
	var targetRotation = 180 if not isOpen else 0
	var arrowTween = create_tween()
	arrowTween.tween_property(arrowIcon, "rotation_degrees", targetRotation, slideSpeed / 3.0)
	
	isOpen = not isOpen

# NOTIFICATION SYSTEM
func TriggerNotification():
	if isOpen: return
	
	alertIcon.visible = true
	StartShakeCycle()

func StartShakeCycle():
	if shakeTween: shakeTween.kill()
	
	shakeTween = create_tween()
	
	var waitTime = randf_range(1.0, 3.0)
	shakeTween.tween_interval(waitTime)
	
	shakeTween.tween_callback(PerformShakeAnimation)
	
	shakeTween.tween_callback(StartShakeCycle)

func PerformShakeAnimation():
	var t = create_tween()

	t.tween_property(alertIcon, "rotation_degrees", 15, 0.1)
	t.tween_property(alertIcon, "rotation_degrees", -15, 0.1)
	t.tween_property(alertIcon, "rotation_degrees", 10, 0.1)
	t.tween_property(alertIcon, "rotation_degrees", -10, 0.1)
	t.tween_property(alertIcon, "rotation_degrees", 0, 0.1)

func ClearNotification():
	alertIcon.visible = false
	if shakeTween:
		shakeTween.kill()
		shakeTween = null
	alertIcon.rotation = 0

# NEW TASKS
func AddTask(taskID: String, taskText: String):
	# Prevent duplicate IDs
	if taskID in activeTasks: return

	# 1. Create a container for the row
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE # Player cannot click the row
	
	# 2. Create the Checkbox (Visual only)
	var checkbox = CheckBox.new()
	checkbox.mouse_filter = Control.MOUSE_FILTER_IGNORE # Player cannot click the box
	checkbox.focus_mode = Control.FOCUS_NONE # Removes the blue outline
	row.add_child(checkbox)
	
	# 3. Create the Text (RichTextLabel allows strikethrough)
	var label = RichTextLabel.new()
	label.text = taskText
	label.bbcode_enabled = true
	label.fit_content = true # Auto-height
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE # Player cannot highlight text
	
	# Layout settings to make the text take up the rest of the space
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	row.add_child(label)
	taskList.add_child(row)

	# 4. Store references so we can find them later
	activeTasks[taskID] = {
		"box": checkbox,
		"label": label,
		"text": taskText,
		"row_node": row
	}

	TriggerNotification()

func CompleteTask(taskID: String):
	print("Completing task...")
	if not taskID in activeTasks:
		print("Error: Task ID not found -> ", taskID)
		return
	
	var taskData = activeTasks[taskID]
	
	# 1. Check the box programmatically
	taskData["box"].button_pressed = true
	
	# 2. Apply Strikethrough and dim color using BBCode
	# [s] = strikethrough, [color] = gray
	var finalText = "[color=#888888][s]" + taskData["text"] + "[/s][/color]"
	taskData["label"].text = finalText
