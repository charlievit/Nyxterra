extends Control

@onready var percent_label: Label = $PercentLabel
@onready var loadingAnimation: AnimatedSprite2D = $LoadingScreen

var _target_path: String = ""
var _elapsed: float = 0.0
var _is_fading_out: bool = false

const MIN_DISPLAY_TIME := 3.0    # how long the loading screen stays visible
const FADE_TIME := 1.0          # fade in/out duration


func _ready() -> void:
	TaskManager.shouldBeHidden = true
	TutorialManager.shouldBeHidden = true
	
	if GameManager.daySTATE == GameManager.DayState.SUN_RISING or GameManager.daySTATE == GameManager.DayState.DAY_IDLE:
		loadingAnimation.play("day")
	else:
		loadingAnimation.play("default")
	
	# Get the target scene path from SceneLoader
	_target_path = SceneLoader.target_scene_path
	print("[DEBUG] Target path: ", _target_path)

	if _target_path == "":
		push_error("[LoadingScreen] No target scene path set.")
		return

	# Start fully transparent, then fade in
	modulate.a = 0.0
	_fade_in()

	# Start at 0%
	percent_label.text = "0%"


func _process(delta: float) -> void:
	if _is_fading_out:
		return

	_elapsed += delta

	# Progress goes linearly from 0 to 1 over MIN_DISPLAY_TIME seconds
	var t := clampf(_elapsed / MIN_DISPLAY_TIME, 0.0, 1.0)
	var p := int(t * 100.0)
	percent_label.text = str(p) + "%"

	# When time is up, start fading out and then switch scenes
	if _elapsed >= MIN_DISPLAY_TIME and not _is_fading_out:
		_start_fade_out()


func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_TIME)


func _start_fade_out() -> void:
	_is_fading_out = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tween.finished.connect(_on_fade_out_finished)


func _on_fade_out_finished() -> void:
	if _target_path != "":
		get_tree().change_scene_to_file(_target_path)
	else:
		push_error("[LoadingScreen] No target path when fade-out finished.")
