# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Control

# NODES
@export var heatDial: Button
@export var potArea: Area2D
@export var progressBar: ProgressBar
@export var TESTING_RECIPE_NOTIFICATION_FEED: RichTextLabel
@export var recipeParser: Node

@onready var recipeBookScreen: Control = $RecipeBookScreen
@onready var recipeBookOpenButton: Button = $"Ingredients Area/RecipeBookButton"
@onready var recipeBookCloseButton: Button = $RecipeBookScreen/Close

@export var recipeDisplayLocation: RichTextLabel
var recipeText: String

func _ready():
	# DEBUG SAFETY CHECKS, should be safe to remove (I will not be doing that)
	if not heatDial:
		push_error("No heatdial")
		return
	if not potArea:
		push_error("No potArea")
		return
	if not progressBar:
		push_error("No progressBar")
	if not recipeParser:
		push_error("No parser found")

	KitchenController.RegisterNodes(heatDial, potArea, progressBar, TESTING_RECIPE_NOTIFICATION_FEED, recipeParser)
	
	KitchenController.StartRecipe("TestRecipeHard")
	
	recipeText = recipeParser.ParseRecipeToInstructions("TestRecipeHard")
	recipeDisplayLocation.text = recipeText
	
	recipeBookScreen.visible = false


func _on_close_pressed() -> void:
	recipeBookScreen.visible = false


func _on_recipe_book_button_pressed() -> void:
	recipeBookScreen.visible = true
