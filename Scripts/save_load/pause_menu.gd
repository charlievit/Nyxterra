# res://UI/PauseMenu.gd
extends Control

func _ready() -> void:
	# Pause menu must still work while the game is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Start hidden
	hide()

func close() -> void:
	TaskManager.shouldBeHidden = not get_tree().paused
	await get_tree().create_timer(0.1).timeout
	get_tree().paused = false
	hide()


func _on_resume_pressed() -> void:
	close()
