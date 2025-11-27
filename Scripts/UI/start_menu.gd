extends Control

const GAME_SCENE := "res://Scenes/main.tscn"
const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "audio"
const SETTINGS_KEY_VOLUME := "master_volume"   # linear 0..1
const SETTINGS_KEY_VOICE  := "voice_volume"

@onready var animScreen: AnimatedSprite2D = $TextureRect
@onready var start_button: Button   = $CenterContainer/Buttons/StartButton
@onready var options_button: Button = $CenterContainer/Buttons/OptionsButton
@onready var socials_button: Button = $CenterContainer/Buttons/SocialsButton
@onready var quit_button: Button    = $CenterContainer/Buttons/QuitButton
@onready var Contain: VBoxContainer = $CenterContainer/Buttons
@onready var options_panel: Control = $OptionsPanel
@onready var socialsPanel: Panel = $SocialsPanel
@onready var volume_slider: HSlider = $OptionsPanel/VolumeSlider
@onready var apply_button: Button   = $OptionsPanel/ApplyButton
@onready var options_back_button: Button = $OptionsPanel/BackButton
@onready var socialsBackButton: Button = $SocialsPanel/BackButton
@onready var continue_button: Button = $CenterContainer/Buttons/ContinueButton
@onready var volume_slider2: HSlider = $OptionsPanel/VolumeSlider2
#region Socials
# CyberSugar Studios
@onready var CS_instaButton: Button = $SocialsPanel/CyberSugar/instagramButton
var CS_instaLink: String = "https://www.instagram.com/cybersugarstudios"
@onready var CS_itchButton: Button = $SocialsPanel/CyberSugar/itchButton
var CS_itchLink: String = "https://cybersugarstudios.itch.io"
@onready var CS_xButton: Button = $SocialsPanel/CyberSugar/xButton
var CS_xLink: String = "https://x.com/CyberSugarGames"
@onready var CS_tikTokButton: Button = $SocialsPanel/CyberSugar/tikTokButton
var CS_tikTokLink: String = "https://www.tiktok.com/@cybersugarstudios"
#endregion

var _cached_volume_db: float = 0.0   # for Return (revert)
var _cached_voice_db:  float = 0.0
var _master_bus: int = 0
var _voice_bus:  int = 0

var titleScreenMusicPlayer: AudioStreamPlayer
var titleScreenMusic: AudioStream = preload("res://Assets/Audio/Music/Music 1 lighthouse.wav")

func _ready() -> void:
	animScreen.play("default")
	TaskManager.shouldBeHidden = true
	
	titleScreenMusicPlayer = AudioStreamPlayer.new()
	add_child(titleScreenMusicPlayer)
	titleScreenMusicPlayer.stream = titleScreenMusic
	_master_bus = AudioServer.get_bus_index("Master")
	_voice_bus  = AudioServer.get_bus_index("Character Voice")
	# Load saved volume (default 0.8 if no file yet)
	var saved_master := _load_volume(SETTINGS_KEY_VOLUME, 0.8)
	var saved_voice  := _load_volume(SETTINGS_KEY_VOICE, 0.8)

	_set_master_linear(saved_master)
	_set_bus_linear(saved_voice)   # Character Voice bus

	volume_slider.value  = saved_master
	volume_slider2.value = saved_voice
	
	titleScreenMusicPlayer.play()
	
	# Signals
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	socials_button.pressed.connect(OnSocialsPressed)
	quit_button.pressed.connect(_on_quit_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.disabled = !SaveManager.has_save()
	apply_button.pressed.connect(_on_apply_pressed)
	options_back_button.pressed.connect(_on_back_pressed)
	socialsBackButton.pressed.connect(OnSocialsBackPressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_slider2.value_changed.connect(_on_voice_volume_changed)   
	# Social Signals
	CS_instaButton.pressed.connect(CS_InstaClicked)
	CS_itchButton.pressed.connect(CS_ItchClicked)
	CS_xButton.pressed.connect(CS_X_ButtonClicked)
	CS_tikTokButton.pressed.connect(CS_TikTokClicked)

	options_panel.visible = false
	socialsPanel.visible = false

func _on_start_pressed() -> void:
	SaveManager.clear_save()
	GameManager.StartNewGame()
	SceneLoader.change_scene_with_loading(GAME_SCENE)

func _on_options_pressed() -> void:
	_cached_volume_db = AudioServer.get_bus_volume_db(_master_bus)
	_cached_voice_db  = AudioServer.get_bus_volume_db(_voice_bus)
	Contain.visible = false
	options_panel.visible = true

func OnSocialsPressed():
	socialsPanel.visible = true

func _on_apply_pressed() -> void:
	_save_volume(SETTINGS_KEY_VOLUME, volume_slider.value)
	_save_volume(SETTINGS_KEY_VOICE,  volume_slider2.value)
	options_panel.visible = false
	Contain.visible = true;
	
func _on_back_pressed() -> void:
	# revert previewed changes
	AudioServer.set_bus_volume_db(_master_bus, _cached_volume_db)
	AudioServer.set_bus_volume_db(_voice_bus,  _cached_voice_db)
	volume_slider.value = db_to_linear(_cached_volume_db)
	volume_slider2.value  = db_to_linear(_cached_voice_db)

	options_panel.visible = false
	Contain.visible = true;

func OnSocialsBackPressed():
	socialsPanel.visible = false

func _on_quit_pressed() -> void:
	if OS.has_feature("web"):
		print("Quit not supported on Web. Please close the tab.")
	else:
		get_tree().quit()

func _on_continue_pressed() -> void:
	if SaveManager.has_save():
		SaveManager.reload_from_disk()
		GameManager.apply_save_data()
		GameManager.load_from_save_next_main = true
		var path := SaveManager.current_save.current_scene_path
		if path != "":
			SceneLoader.change_scene_with_loading(path)

	else:
		print("No save file found.")
		
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

#region Social Buttons
func CS_InstaClicked():
	OS.shell_open(CS_instaLink)

func CS_ItchClicked():
	OS.shell_open(CS_itchLink)

func CS_X_ButtonClicked():
	OS.shell_open(CS_xLink)

func CS_TikTokClicked():
	OS.shell_open(CS_tikTokLink)
#endregion
