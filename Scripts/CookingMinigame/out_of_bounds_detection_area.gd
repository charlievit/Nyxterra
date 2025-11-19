# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Area2D

func _ready():
	# Connect
	self.body_entered.connect(OnBodyEntered)

func OnBodyEntered(body: RigidBody2D):
	# Check if an ingredient entered
	if not "ingredientType" in body:
		return
	
	var type = body.get("ingredientType")
	print(type)
	if type == 0 or type == 1:
		body.queue_free()
	elif type == 2 or type == 3:
		body.call_deferred("ResetPosition")
