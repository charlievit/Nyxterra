# res://UI/PauseMenu.gd
extends Control

# Change if your start menu scene has a different path
const MAIN_MENU_SCENE := "res://Scenes/UI/start_menu.tscn"

@onready var resume_button: Button     = $CenterContainer/VBoxContainer/ResumeButton
@onready var save_button: Button       = $CenterContainer/VBoxContainer/SaveButton
@onready var load_button: Button       = $CenterContainer/VBoxContainer/LoadButton
@onready var main_menu_button: Button  = $CenterContainer/VBoxContainer/MainMenuButton

func _ready() -> void:
	# Pause menu must still work while the game is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Start hidden
	hide()

	# Wire buttons
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	_update_load_button_state()


func _update_load_button_state() -> void:
	# Disable the Load button if there is no save file.
	# Uses the same SaveGame autoload as your start menu:
	#   SaveGame.has_save()
	var has_save := false
	if !Engine.is_editor_hint():
		has_save = SaveManager.has_save()
	load_button.disabled = !has_save


func open() -> void:
	get_tree().paused = true
	_update_load_button_state()
	show()


func close() -> void:
	get_tree().paused = false
	hide()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _on_resume_pressed() -> void:
	close()


func _on_save_pressed() -> void:
	GameManager.write_save_data()
	var player := GameManager.player
	player.write_save_data()
	
	#Dialogue Save
	Dialogic.Save.save()
	
	SaveManager.save_game()
	_update_load_button_state()


func _on_load_pressed() -> void:
	get_tree().paused = false
	hide()

	SaveManager.reload_from_disk()
	GameManager.apply_save_data()
	var player:=GameManager.player
	player.apply_save_data()
	GameManager.load_from_save_next_main = true	
	# Switch to the saved scene
	var path := SaveManager.current_save.current_scene_path
	if path != "":
		SceneLoader.change_scene_with_loading(path)

func _on_main_menu_pressed() -> void:
	# Optional: auto-save here if you want
	# SaveGame.save_game()
	get_tree().paused = false
	SceneLoader.change_scene_with_loading(MAIN_MENU_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Esc toggles the menu
		toggle()
		get_viewport().set_input_as_handled()
