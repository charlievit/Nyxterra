extends Node

# Path of the scene we want to load after the loading screen
var target_scene_path: String = ""


func change_scene_with_loading(path: String) -> void:
	# Store the path so the loading screen knows what to load
	target_scene_path = path

	# Go to the loading screen scene
	get_tree().change_scene_to_file("res://Scenes/UI/loading_screen.tscn")
