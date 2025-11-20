extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "audio"
const SETTINGS_KEY_VOLUME := "master_volume"   # linear 0..1

@onready var start_button: Button   = $CenterContainer/Buttons/StartButton
@onready var options_button: Button = $CenterContainer/Buttons/OptionsButton
@onready var quit_button: Button    = $CenterContainer/Buttons/QuitButton
@onready var Contain: VBoxContainer = $CenterContainer/Buttons
@onready var options_panel: Control = $OptionsPanel
@onready var volume_slider: HSlider = $OptionsPanel/VolumeSlider
@onready var apply_button: Button   = $OptionsPanel/ApplyButton
@onready var back_button: Button    = $OptionsPanel/BackButton
@onready var continue_button: Button = $CenterContainer/Buttons/ContinueButton

var _cached_volume_db: float = 0.0   # for Return (revert)
var _master_bus: int = 0

func _ready() -> void:
	_master_bus = AudioServer.get_bus_index("Master")

	# Load saved volume (default 0.8 if no file yet)
	var saved_vol := _load_volume()
	_set_master_linear(saved_vol)
	volume_slider.value = saved_vol

	# Signals
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.disabled = !SaveManager.has_save()
	apply_button.pressed.connect(_on_apply_pressed)
	back_button.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)

	options_panel.visible = false

func _on_start_pressed() -> void:
	SaveManager.clear_save()
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_options_pressed() -> void:
	_cached_volume_db = AudioServer.get_bus_volume_db(_master_bus)
	Contain.visible = false
	options_panel.visible = true

func _on_apply_pressed() -> void:
	_save_volume(volume_slider.value)
	options_panel.visible = false
	Contain.visible = true;
	
func _on_back_pressed() -> void:
	# revert previewed changes
	AudioServer.set_bus_volume_db(_master_bus, _cached_volume_db)
	volume_slider.value = db_to_linear(_cached_volume_db)
	options_panel.visible = false
	Contain.visible = true;
	
func _on_quit_pressed() -> void:
	if OS.has_feature("web"):
		print("Quit not supported on Web. Please close the tab.")
	else:
		get_tree().quit()

func _on_continue_pressed() -> void:
	if SaveManager.has_save():
		# Reload save resource from disk to be safe
		SaveManager.reload_from_disk()

		# Use the scene path stored in the save
		if SaveManager.current_save.current_scene_path != "":
			get_tree().change_scene_to_file(SaveManager.current_save.current_scene_path)
		else:
			# Fallback: if no path saved, just start main scene
			get_tree().change_scene_to_file(GAME_SCENE)
	else:
		print("No save file found.")
		
# --- Volume helpers ---
func _on_volume_changed(value: float) -> void:
	_set_master_linear(value)  # live preview

func _set_master_linear(value: float) -> void:
	var db := -80.0 if value <= 0.001 else linear_to_db(value)
	AudioServer.set_bus_volume_db(_master_bus, db)

func _get_master_linear() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(_master_bus))

# --- Persistence (ConfigFile) ---
func _save_volume(value: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # ok if file doesn’t exist yet
	cfg.set_value(SETTINGS_SECTION, SETTINGS_KEY_VOLUME, clamp(value, 0.0, 1.0))
	cfg.save(SETTINGS_PATH)

func _load_volume() -> float:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err == OK and cfg.has_section_key(SETTINGS_SECTION, SETTINGS_KEY_VOLUME):
		return float(cfg.get_value(SETTINGS_SECTION, SETTINGS_KEY_VOLUME))
	return 0.8  
