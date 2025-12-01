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
@onready var team_gitHubButton: Button = $SocialsPanel/githubRepoButton
var team_gitHubLink: String = "https://github.com/charlievit/Nyxterra"

# Toxic_Humble
@onready var TH_linkedInButton: Button = $SocialsPanel/Toxic_Humble/linkedInButton
var TH_linkedInLink: String = "https://www.linkedin.com/in/ben-ho-4857002bb/"

# Rissa Baker
@onready var RB_instaButton: Button = $"SocialsPanel/Rissa Baker/instagramButton"
var RB_instaLink: String = "https://www.instagram.com/rissazinks/"

# CyberSugar Studio
@onready var CS_instaButton: Button = $SocialsPanel/CyberSugar/instagramButton
var CS_instaLink: String = "https://www.instagram.com/cybersugarstudios"
@onready var CS_itchButton: Button = $SocialsPanel/CyberSugar/itchButton
var CS_itchLink: String = "https://cybersugarstudios.itch.io"
@onready var CS_xButton: Button = $SocialsPanel/CyberSugar/xButton
var CS_xLink: String = "https://x.com/CyberSugarGames"
@onready var CS_tikTokButton: Button = $SocialsPanel/CyberSugar/tikTokButton
var CS_tikTokLink: String = "https://www.tiktok.com/@cybersugarstudios"

# Phren
@onready var CS_P_artStationButton: Button = $SocialsPanel/Phren/artStationButton
var CS_P_artStationLink: String = "https://www.artstation.com/phren"

# NyxForge Studio
@onready var NF_itchButton: Button = $"SocialsPanel/NyxForge Studio/itchButton"
var NF_itchLink: String = "https://itch.io/profile/nyxforgestudio"
@onready var NF_instaButton: Button = $"SocialsPanel/NyxForge Studio/instagramButton2"
var NF_instaLink: String = "https://www.instagram.com/nyxforgestudio"

# Dragonsight Studio
@onready var DS_instaButton: Button = $"SocialsPanel/Dragonsight Studio/instagramButton"
var DS_instaLink: String = "https://www.instagram.com/karma97090/"
@onready var DS_redditButton: Button = $"SocialsPanel/Dragonsight Studio/redditButton"
var DS_redditLink: String = "https://www.reddit.com/user/PixelDragon9709/"

# GodSnail
@onready var GS_soundCloudButton: Button = $SocialsPanel/GodSnail/soundCloudButton
var GS_soundCloudLink: String = "https://www.soundcloud.com/tetaban-moi"
@onready var GS_bandLabButton: Button = $SocialsPanel/GodSnail/bandLabButton
var GS_bandLabLink: String = "https://www.bandlab.com/tetebanmortaccio"
#endregion

var _cached_volume_db: float = 0.0   # for Return (revert)
var _cached_voice_db:  float = 0.0
var _master_bus: int = 0
var _voice_bus:  int = 0

var oceanPlayer: AudioStreamPlayer
var windPlayer: AudioStreamPlayer
var musicPlayer: AudioStreamPlayer
var oceanSounds: AudioStream = preload("res://Assets/Audio/Cutscenes/Ocean Waves.mp3")
var windSounds: AudioStream = preload("res://Assets/Audio/Cutscenes/Wind.mp3")
var music: AudioStream = preload("res://Assets/Audio/Music/Music 1 lighthouse.wav")

func _ready() -> void:
	animScreen.play("default")
	TaskManager.shouldBeHidden = true
	TutorialManager.shouldBeHidden = true
	
	oceanPlayer = AudioStreamPlayer.new()
	windPlayer = AudioStreamPlayer.new()
	musicPlayer = AudioStreamPlayer.new()
	
	add_child(oceanPlayer)
	add_child(windPlayer)
	add_child(musicPlayer)
	
	oceanPlayer.stream = oceanSounds
	windPlayer.stream = windSounds
	musicPlayer.stream = music
	
	_master_bus = AudioServer.get_bus_index("Master")
	_voice_bus  = AudioServer.get_bus_index("Character Voice")
	# Load saved volume (default 0.8 if no file yet)
	var saved_master := _load_volume(SETTINGS_KEY_VOLUME, 0.8)
	var saved_voice  := _load_volume(SETTINGS_KEY_VOICE, 0.8)

	_set_master_linear(saved_master)
	_set_bus_linear(saved_voice)   # Character Voice bus

	volume_slider.value  = saved_master
	volume_slider2.value = saved_voice
	
	oceanPlayer.volume_db = -20.0
	windPlayer.volume_db = -20.0
	
	oceanPlayer.play()
	windPlayer.play()
	musicPlayer.play()
	
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
	team_gitHubButton.pressed.connect(Team_GitHubClicked)
	
	TH_linkedInButton.pressed.connect(TH_LinkedInClicked)
	
	RB_instaButton.pressed.connect(RB_InstaClicked)
	
	CS_instaButton.pressed.connect(CS_InstaClicked)
	CS_itchButton.pressed.connect(CS_ItchClicked)
	CS_xButton.pressed.connect(CS_X_ButtonClicked)
	CS_tikTokButton.pressed.connect(CS_TikTokClicked)
	
	CS_P_artStationButton.pressed.connect(CS_P_ArtStationClicked)
	
	NF_instaButton.pressed.connect(NF_InstaClicked)
	NF_itchButton.pressed.connect(NF_ItchClicked)
	
	DS_instaButton.pressed.connect(DS_InstaClicked)
	DS_redditButton.pressed.connect(DS_RedditClicked)
	
	GS_bandLabButton.pressed.connect(GS_BandLabClicked)
	GS_soundCloudButton.pressed.connect(GS_SoundCloudClicked)
	
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
func Team_GitHubClicked():
	OS.shell_open(team_gitHubLink)

func RB_InstaClicked():
	OS.shell_open(RB_instaLink)

func TH_LinkedInClicked():
	OS.shell_open(TH_linkedInLink)

func CS_InstaClicked():
	OS.shell_open(CS_instaLink)
func CS_ItchClicked():
	OS.shell_open(CS_itchLink)
func CS_X_ButtonClicked():
	OS.shell_open(CS_xLink)
func CS_TikTokClicked():
	OS.shell_open(CS_tikTokLink)

func CS_P_ArtStationClicked():
	OS.shell_open(CS_P_artStationLink)

func NF_InstaClicked():
	OS.shell_open(NF_instaLink)
func NF_ItchClicked():
	OS.shell_open(NF_itchLink)

func DS_InstaClicked():
	OS.shell_open(DS_instaLink)
func DS_RedditClicked():
	OS.shell_open(DS_redditLink)

func GS_BandLabClicked():
	OS.shell_open(GS_bandLabLink)
func GS_SoundCloudClicked():
	OS.shell_open(GS_soundCloudLink)
#endregion
