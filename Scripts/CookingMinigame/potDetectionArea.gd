# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Area2D

# SIGNAL SET UP
signal IngredientAdded(ingredientName: String)

func _ready():
	# Connect
	self.body_entered.connect(OnBodyEntered)

func OnBodyEntered(body: RigidBody2D):
	KitchenController.oneShotAudioPlayer.stream = KitchenController.plopSound
	KitchenController.oneShotAudioPlayer.play()
	
	# Check if an ingredient entered
	if not "ingredientType" in body:
		return
	
	var type = body.get("ingredientType")
	print(type)
	if type == 0 or type == 1:
		var ingredientID = body.get("ingredientName")
		if body.get("isChopped"): # check against recipe
			if not "(Chopped)" in ingredientID:
				ingredientID += " (Chopped)"
		
		# Send name to KitchenController
		IngredientAdded.emit(ingredientID)
		
		# Delete the ingredient to prevent stacking in the pot and overflow
		body.queue_free()
	elif type == 2 or type == 3:
		print("Opps, that doesn't go there!")
		body.call_deferred("ResetPosition")
		if type == 2:
			KitchenController.ApplyPenalty(1)
		else:
			KitchenController.ApplyPenalty(2)
