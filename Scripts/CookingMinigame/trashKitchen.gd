# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Area2D

func _ready():
	# Connect
	self.body_entered.connect(OnBodyEntered)

func OnBodyEntered(body: Node2D):
	if not "ingredientType" in body:
		return
	
	var type = body.get("ingredientType")
	
	# Only delete solid ingredients. Tools (pourable/shaker) are ignored.
	if type == body.IngredientType.WHOLE or type == body.IngredientType.CHOPPABLE:
		body.queue_free()
