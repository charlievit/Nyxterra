extends Control

# RETURN SETTINGS
@export_group("Return Settings")
@export var returnFloorIndex = 3
@export var returnPosition: Vector2 = Vector2(150, 275)
@export var mainGameScenePath: String = "res://Scenes/main.tscn"

# --- Timing (seconds) ---
const UNIT := 0.22
const DOT_MAX := UNIT * 1.5
const LETTER_GAP := UNIT * 2.5
const WORD_GAP := UNIT * 6.5

# Fixed sentences per day
const DAY_SENTENCES := {
	0: "ATTACK IMMINENT DISABLE LIGHT",
	1: "FISHING SEASON",
	2: "QUIET SEAS",
	3: "INCOMING SHIPMENT",
	4: "SWEDISH DELIVERY",
}

const MORSE: Dictionary[String, String] = {
	"A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".",
	"F": "..-.", "G": "--.", "H": "....", "I": "..", "J": ".---",
	"K": "-.-", "L": ".-..", "M": "--", "N": "-.", "O": "---",
	"P": ".--.", "Q": "--.-", "R": ".-.", "S": "...", "T": "-",
	"U": "..-", "V": "...-", "W": ".--", "X": "-..-", "Y": "-.--",
	"Z": "--..",
	"1": ".----", "2": "..---", "3": "...--", "4": "....-", "5": ".....",
	"6": "-....", "7": "--...", "8": "---..", "9": "----.", "0": "-----"
}
var REVERSE: Dictionary[String, String] = {}

# --- Nodes ---
@onready var label_target: RichTextLabel  = $TargetLabel
@onready var label_morse: Label      = $MorseLive
@onready var label_out: Label        = $DecodedOut
@onready var label_feedback: Label   = $Feedback
@onready var morse_key: Button       = $MorseKey
@onready var return_button: Button   = $ReturnButton
@onready var sheet: TextureRect      = $Sheet
@onready var background: TextureRect = $Background

# --- Background textures ---
const TEX_UP   := preload("res://Assets/Images/MorseCode/1MorseCodeMachineClipboard.png")
const TEX_DOWN := preload("res://Assets/Images/MorseCode/1MorseCodeMachineDownClickClipboard.png")

# --- State for button-based Morse input ---
var pressing: bool = false
var press_started_at: float = 0.0
var last_release_at: float = 0.0
var current_symbol: String = ""

# --- Sentence / word-by-word state ---
var target_full: String = ""
var target_words: PackedStringArray = []
var word_i: int = 0
var decoded_current_word: String = ""

# Task Key for Game Manager communication
var currentTaskID: String = ""

func _ready() -> void:
	TaskManager.shouldBeHidden = true
	
	for key in TaskManager.activeTasks.keys():
		if String(key).contains("Morse"):
			currentTaskID = key
			break
	
	for letter: String in MORSE.keys():
		REVERSE[MORSE[letter]] = letter

	# Load random sentence and prep UI
	_load_random_sentence()
	_show_target_with_highlight()
	_update_labels()

	# Show BBCode for highlight
	label_target.bbcode_enabled = true

	# Wire buttons
	morse_key.button_down.connect(_on_morse_key_down)
	morse_key.button_up.connect(_on_morse_key_up)
	return_button.pressed.connect(_on_backspace_pressed)
	
	if is_instance_valid(background):
		background.texture = TEX_UP

func _process(_delta: float) -> void:
	# After a release, watch the silence gap to end letter or word
	var now: float = Time.get_ticks_msec() / 1000.0
	if !pressing and last_release_at > 0.0:
		var gap: float = now - last_release_at
		if gap >= WORD_GAP:
			_commit_letter_if_any()
			last_release_at = 0.0
		elif gap >= LETTER_GAP:
			_commit_letter_if_any()
			last_release_at = 0.0

# --- MorseKey handlers (button press duration decides dot vs dash) ---
func _on_morse_key_down() -> void:
	pressing = true
	background.texture = TEX_DOWN
	press_started_at = Time.get_ticks_msec() / 1000.0
	

func _on_morse_key_up() -> void:
	if !pressing:
		return
	pressing = false
	background.texture = TEX_UP
	var now: float = Time.get_ticks_msec() / 1000.0
	var dur: float = now - press_started_at
	current_symbol += "." if dur <= DOT_MAX else "-"
	last_release_at = now
	_update_labels()

# --- Commit helpers ---
func _commit_letter_if_any() -> void:
	if current_symbol != "":
		var ch: String = REVERSE.get(current_symbol, "?") as String
		decoded_current_word += ch
		current_symbol = ""
		_update_labels()
		_check_word_progress()

# The player completes the word, then we auto-advance and reset.
func _check_word_progress() -> void:
	if word_i >= target_words.size():
		return
	var goal := target_words[word_i]
	if decoded_current_word == goal:
		label_feedback.text = "Word ✓"
		label_feedback.modulate = Color(0, 1, 0)
		word_i += 1
		decoded_current_word = ""
		_show_target_with_highlight()
		_update_labels()
		if word_i >= target_words.size():
			_on_sentence_solved()
	else:
		# Gentle hint if mismatch
		if goal.begins_with(decoded_current_word):
			label_feedback.text = ""
		else:
			label_feedback.text = "Mismatch. Backspace or continue."
			label_feedback.modulate = Color(1, 0.6, 0.4)

func _on_sentence_solved() -> void:
	label_feedback.text = "Correct! The light will guide you tonight."
	label_feedback.modulate = Color(0, 1, 0)
	
	# DAY 0 EXCEPTION HANDLING
	# On Day 0, CompleteTask() triggers the Bombing Cutscene via GameManager logic.
	# We simply return, ensuring we don't accidentally set a return spawn point or change scene.
	# The Cutscene Manager will eventually trigger GameManager.StartDay(1), which handles the spawn.
	if GameManager.currentDay == 0:
		self.set_process(false)
		await _Dialogue_System()
		self.set_process(true)
		GameManager.CompleteTask(currentTaskID)
		return

	# STANDARD DAY HANDLING (Day 1+)
	# 1. Set return spawn so Player is back at the machine in Main scene
	GameManager.SetPlayerSpawn(returnFloorIndex, returnPosition)
	
	# 2. Complete the task
	GameManager.CompleteTask(currentTaskID)
	
	# 3. Set dialogue flag and return to Main
	GameManager.pending_post_source = GameManager.ReturnSource.MORSE
	
	if ResourceLoader.exists(mainGameScenePath):
		SceneLoader.change_scene_with_loading(mainGameScenePath)
	else:
		push_error("ERROR: Main game scene path not found.")

# --- Backspace edits current word only ---
func _on_backspace_pressed() -> void:
	if decoded_current_word.length() > 0:
		decoded_current_word = decoded_current_word.substr(0, decoded_current_word.length() - 1)
		label_feedback.text = ""
		_update_labels()

# ---sanitizing / target render ---
func _load_random_sentence() -> void:
	if DAY_SENTENCES.has(GameManager.currentDay):
		target_full = _sanitize_sentence(DAY_SENTENCES[GameManager.currentDay])

	# Common setup for both cases
	target_words = target_full.split(" ", false)
	word_i = 0
	decoded_current_word = ""
	current_symbol = ""
	label_feedback.text = ""

func _sanitize_sentence(s: String) -> String:
	# Keep A-Z, 0-9, spaces. Remove punctuation. Collapse spaces.
	var up := s.to_upper()
	var out := ""
	for i in up.length():
		var c := up[i]
		if (c >= "A" and c <= "Z") or (c >= "0" and c <= "9") or c == " ":
			out += c
	out = out.strip_edges()
	while out.find("  ") != -1:
		out = out.replace("  ", " ")
	return out

func _show_target_with_highlight() -> void:
	if target_words.is_empty():
		label_target.text = "Target: (none)"
		return
	var bb := "[b]Target:[/b] "
	for idx in target_words.size():
		var w := target_words[idx]
		if idx == word_i:
			bb += "[color=yellow]%s[/color]" % w
		else:
			bb += w
		if idx < target_words.size() - 1:
			bb += " "
	label_target.text = bb

func _update_labels() -> void:
	label_morse.text = "Current letter: %s" % current_symbol
	var prefix := ""
	if word_i > 0:
		for i in range(word_i):
			prefix += target_words[i]
			if i < word_i - 1:
				prefix += " "
		prefix += " "  

	var display := (prefix + decoded_current_word).strip_edges()
	label_out.text = "You typed: %s" % display

func _Dialogue_System() -> void:
	Dialogic.start("Day_0 Morse Completed")
	await Dialogic.timeline_ended
