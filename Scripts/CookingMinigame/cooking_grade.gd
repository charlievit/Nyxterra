# res://UI/PauseMenu.gd
extends Control

@onready var GradeScore = $Label2

func _ready() -> void:
	GameManager.recipeQuality = 75
	var tween = create_tween()
	# Pause menu must still work while the game is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	# morality value counts up or down
	tween.tween_method(func(val):
		GradeScore.text = str(int(val)), 0, GameManager.recipeQuality, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Start hidden
	hide()

func close() -> void:
	TaskManager.shouldBeHidden = not get_tree().paused
	await get_tree().create_timer(0.1).timeout
	get_tree().paused = false
	hide()


func _on_resume_pressed() -> void:
	close()
