# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Button

# Ingredient to spawn
@export var ingredientScene: PackedScene
# Where to spawn if PickupAndHold fails
@export var spawnParentNode: Node2D

var numSpawned = 0 # tracker for naming (for debugging)

func _ready():
	# Connect
	self.button_down.connect(OnSpawnIngredient)

func OnSpawnIngredient():
	if not ingredientScene:
		push_error("NO INGREDIENT SET.")
		return
	if not is_instance_valid(spawnParentNode):
		push_error("NO SPAWN ASSIGNED")
		return
	
	numSpawned += 1
	
	# Create new ingredient
	var newIngredient = ingredientScene.instantiate()
	# Name it (for debugging)
	newIngredient.name = str(newIngredient["ingredientName"], " ", numSpawned)
	spawnParentNode.add_child(newIngredient)
	
	# Wait one frame for the node to be ready
	await get_tree().physics_frame
	
	if not is_instance_valid(newIngredient):
		return
	
	# Follow the mouse
	if newIngredient.has_method("PickupAndHold"):
		newIngredient.PickupAndHold()
	else: # ✅TESTED: Shouldn't need this but keeping out of paranoia
		push_error("Ingredient scene broken.")
		# Fallback if not set up
		newIngredient.global_position = get_global_mouse_position()
