# save_manager.gd
extends Node

const SAVE_PATH := "user://save_game.tres"

var current_save: SaveData


func _ready() -> void:
	# On startup, either load existing save resource or create a fresh one
	if ResourceLoader.exists(SAVE_PATH):
		current_save = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		current_save = SaveData.new()


func has_save() -> bool:
	return ResourceLoader.exists(SAVE_PATH)


func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveManager] Save file deleted.")
	current_save = SaveData.new()


func save_game() -> void:
	var player = GameManager.player
	if player:
		current_save.player_position = player.global_position
		current_save.player_floor = player.currentFloor

	var current_scene := get_tree().current_scene
	if current_scene:
		current_save.current_scene_path = current_scene.scene_file_path

	var err := ResourceSaver.save(current_save, SAVE_PATH)
	if err != OK:
		push_error("[SaveManager] Failed to save game: %s" % err)
	else:
		print("[SaveManager] Game saved to: ", SAVE_PATH)


func reload_from_disk() -> void:
	# Just refresh current_save from file.
	if ResourceLoader.exists(SAVE_PATH):
		var loaded := ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		if loaded is SaveData:
			current_save = loaded
