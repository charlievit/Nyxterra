# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Area2D

# SIGNAL SET UP
signal IngredientAdded(ingredientName: String)

func _ready():
	# Connect
	self.body_entered.connect(OnBodyEntered)

func OnBodyEntered(body: Node2D):
	# Check if an ingredient entered
	if not "ingredientType" in body:
		return
	
	var type = body.get("ingredientType")
	
	if type == body.IngredientType.WHOLE or type == body.IngredientType.CHOPPABLE:
		var ingredientID = body.get("ingredientName")
		if body.get("isChopped"): # check against recipe
			if not "(Chopped)" in ingredientID:
				ingredientID += " (Chopped)"
		
		# Send name to KitchenController
		IngredientAdded.emit(ingredientID)
		
		# Delete the ingredient to prevent stacking in the pot and overflow
		body.queue_free()
	elif type == body.IngredientType.POURABLE or type == body.IngredientType.SHAKER: #this shouldn't be needed, but keeping just in case player manages to push containers into the pot
		if body.has_method("ResetPosition"):
			body.ResetPosition()
