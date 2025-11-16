# save_manager.gd
extends Node

# The file path where the save file will be stored
const SAVE_PATH := "user://save_game.tres"

# This holds your in-memory save data (loaded from disk or newly created)
var current_save: SaveData


func _ready() -> void:
	# When the game starts, decide whether to load an existing save
	# or create a new empty SaveData object.

	# If a save file exists, read it immediately into current_save.
	if ResourceLoader.exists(SAVE_PATH):
		current_save = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		# If no save file is found, start with a brand-new SaveData resource.
		current_save = SaveData.new()


func has_save() -> bool:
	return ResourceLoader.exists(SAVE_PATH)

# Deletes the save file completely and resets current_save to defaults.
func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveManager] Save file deleted.")
	current_save = SaveData.new()

# Main function responsible for saving gameplay progress.
# Copies the current game state into current_save, then writes it to disk.
func save_game() -> void:
	#Save the current scene
	var current_scene := get_tree().current_scene
	if current_scene:
		current_save.current_scene_path = current_scene.scene_file_path

	#write the SaveData resource to SAVE_PATH
	var err := ResourceSaver.save(current_save, SAVE_PATH)
	if err != OK:
		push_error("[SaveManager] Failed to save game: %s" % err)
	else:
		print("[SaveManager] Game saved to: ", SAVE_PATH)

# Re-read the current save file from disk.
# This does NOT apply the data to the game; it only refreshes current_save.
# Scene scripts are responsible for applying saved values (e.g., player pos).
func reload_from_disk() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		var loaded := ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		if loaded is SaveData:
			current_save = loaded
