# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Area2D

# Keep track of all choppable items in the area
var ingredientsInArea: Array = []

func _ready():
	# Connect
	self.body_entered.connect(OnBodyEntered)
	self.body_exited.connect(OnBodyExited)

func OnBodyEntered(body: Node2D):
	# Check the body to ensure it is an ingredient AND is choppable
	if "ingredientType" in body and body.get("isChoppable"):
		TutorialManager.CompleteTutorial("kitchenDragBoard")
		KitchenController.UpdateTutorialState("KNIFE")
		if not ingredientsInArea.has(body):
			ingredientsInArea.append(body)
			print("Entered: %s" % body.name)

func OnBodyExited(body: Node2D):
	# Remove the ingredient when it leaves
	if ingredientsInArea.has(body):
		ingredientsInArea.erase(body)

func _on_chop_button_pressed() -> void:
	if ingredientsInArea.is_empty():
		return
	
	var ingredientToChop = ingredientsInArea.back() # I think this will still chop something that has entered and left TODO: FIX
	
	if "Chop" in ingredientToChop:
		ingredientToChop.Chop() #chop! chop! chop!
