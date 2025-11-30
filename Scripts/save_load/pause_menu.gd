extends Control

# Change if your start menu scene has a different path
const MAIN_MENU_SCENE := "res://Scenes/UI/start_menu.tscn"
const SETTINGS_KEY_VOLUME := "master_volume"   # linear 0..1
const SETTINGS_KEY_VOICE  := "voice_volume"
const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "audio"

@onready var resume_button: Button     = $CenterContainer/Buttons/ResumeButton
@onready var save_button: Button       = $CenterContainer/Buttons/SaveButton
@onready var load_button: Button       = $CenterContainer/Buttons/LoadButton
@onready var main_menu_button: Button  = $CenterContainer/Buttons/MainMenuButton
@onready var options_button: Button = $CenterContainer/Buttons/OptionsButton
@onready var options_panel: Control = $OptionsPanel
@onready var options_back_button: Button = $OptionsPanel/BackButton
@onready var volume_slider: HSlider = $OptionsPanel/VolumeSlider
@onready var apply_button: Button   = $OptionsPanel/ApplyButton
@onready var volume_slider2: HSlider = $OptionsPanel/VolumeSlider2
@onready var Contain: VBoxContainer = $CenterContainer/Buttons

var _cached_volume_db: float = 0.0   # for Return (revert)
var _cached_voice_db:  float = 0.0
var _master_bus: int = 0
var _voice_bus:  int = 0

func _ready() -> void:
	# Pause menu must still work while the game is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Start hidden
	hide()

	var saved_master := _load_volume(SETTINGS_KEY_VOLUME, 0.8)
	var saved_voice  := _load_volume(SETTINGS_KEY_VOICE, 0.8)

	volume_slider.value  = saved_master
	volume_slider2.value = saved_voice

	options_button.pressed.connect(_on_options_pressed)
	options_back_button.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_slider2.value_changed.connect(_on_voice_volume_changed) 
	apply_button.pressed.connect(_on_apply_pressed)

	# Wire buttons
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	_update_load_button_state()

	options_panel.visible = false


func _update_load_button_state() -> void:
	# Disable the Load button if there is no save file.
	# Uses the same SaveGame autoload as your start menu:
	#   SaveGame.has_save()
	var has_save := false
	if !Engine.is_editor_hint():
		has_save = SaveManager.has_save()
	load_button.disabled = !has_save


func open() -> void:
	TaskManager.shouldBeHidden = not get_tree().paused
	await get_tree().create_timer(0.1).timeout
	get_tree().paused = true
	_update_load_button_state()
	show()


func close() -> void:
	TaskManager.shouldBeHidden = not get_tree().paused
	await get_tree().create_timer(0.1).timeout
	get_tree().paused = false
	_update_load_button_state()
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

func _on_options_pressed() -> void:
	_cached_volume_db = AudioServer.get_bus_volume_db(_master_bus)
	_cached_voice_db  = AudioServer.get_bus_volume_db(_voice_bus)
	Contain.visible = false
	options_panel.visible = true


func _on_back_pressed() -> void:
	# revert previewed changes
	AudioServer.set_bus_volume_db(_master_bus, _cached_volume_db)
	AudioServer.set_bus_volume_db(_voice_bus,  _cached_voice_db)
	volume_slider.value = db_to_linear(_cached_volume_db)
	volume_slider2.value  = db_to_linear(_cached_voice_db)

	options_panel.visible = false
	Contain.visible = true;

func _on_apply_pressed() -> void:
	_save_volume(SETTINGS_KEY_VOLUME, volume_slider.value)
	_save_volume(SETTINGS_KEY_VOICE,  volume_slider2.value)
	options_panel.visible = false
	Contain.visible = true;

# --- Volume helpers ---
func _on_volume_changed(value: float) -> void:
	_set_master_linear(value)  # live preview

func _on_voice_volume_changed(value: float) -> void:
	_set_bus_linear(value)   # live preview

func _set_master_linear(value: float) -> void:
	var db := -80.0 if value <= 0.001 else linear_to_db(value)
	AudioServer.set_bus_volume_db(_master_bus, db)

func _set_bus_linear(value: float) -> void:
	var db := -80.0 if value <= 0.001 else linear_to_db(value)
	AudioServer.set_bus_volume_db(_voice_bus, db)

func _get_master_linear() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(_master_bus))

# --- Persistence (ConfigFile) ---
func _save_volume(key: String, value: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # ok if file doesn’t exist yet
	cfg.set_value(SETTINGS_SECTION, key, clamp(value, 0.0, 1.0))
	cfg.save(SETTINGS_PATH)

func _load_volume(key: String, default_value: float) -> float:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err == OK and cfg.has_section_key(SETTINGS_SECTION, key):
		return float(cfg.get_value(SETTINGS_SECTION, key))
	return default_value
