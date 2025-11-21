extends Resource
class_name SaveData

@export var player_position: Vector2 = Vector2.ZERO
@export var current_scene_path: String = ""

# Add more as your game grows:
@export var morse_is_solved: bool = false
@export var player_floor: int = 3

# --- GameManager data to persist ---
@export var current_day: int = 0
@export var current_night: int = 0

@export var need_gear_box: bool = false
@export var need_radio: bool = false
@export var need_morse: bool = false
@export var need_daughter: bool = false
@export var need_kitchen: bool = false
@export var need_light: bool = false
