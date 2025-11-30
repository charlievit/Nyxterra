extends Resource
class_name SaveData

@export var player_position: Vector2 = Vector2.ZERO
@export var current_scene_path: String = ""

# Add more as your game grows:
@export var player_floor: int = 3

# --- GameManager data to persist ---
@export var tutorial_mode: bool = false
@export var completed_tutorials: Dictionary = {}
@export var current_day: int = 0
@export var currentTaskStep : int = 0
@export var need_gear_box: bool = false
@export var hasCompletedTutorial : bool = false
@export var need_radio: bool = false
@export var need_morse: bool = false
@export var need_daughter: bool = false
@export var need_kitchen: bool = false
@export var need_light: bool = false
@export var need_bed: bool = false
@export var morality: int = 0
@export var morality_needed: int
@export var relationship: int = 0
@export var should_light_be_on_tonight: bool
@export var day_state: int
@export var introPlayed: bool = false
@export var introScenePlayed: bool = false
@export var pending_post_source: int = GameManager.ReturnSource.NONE
@export var isIntroPlayed: bool = false

#store task panel data as a Dictionary
@export var task_data: Dictionary = {}
