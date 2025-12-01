# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Control

# NODES
@export var heatDial: Button
@export var potArea: Area2D
@export var progressBar: ProgressBar
@export var recipeParser: Node

@onready var recipeBookScreen: Control = $RecipeBookScreen
@onready var recipeBookOpenButton: Button = $"Ingredients Area/RecipeBookButton"
@onready var recipeBookCloseButton: Button = $RecipeBookScreen/Close

@onready var snowWeather: TileMap = $AnimatedSnowMap
@onready var nightSky: Sprite2D = $SkyNightBackground
@onready var oceanAnim: AnimatedSprite2D = $Ocean/AnimatedSprite2D

@export var fireAnimLow: AnimatedSprite2D
@export var fireAnimMedium: AnimatedSprite2D
@export var fireAnimHigh: AnimatedSprite2D

@export var steamAnim: AnimatedSprite2D

@export var oneShotAudioPlayer: AudioStreamPlayer2D
@export var constantAudioPlayer: AudioStreamPlayer2D

@export var recipeDisplayLocation: RichTextLabel
@export var recipeDisplayLocation2: RichTextLabel
var recipeText: Dictionary

var todaysRecipe: String = ""
var todaysTaskID: String = ""

# PRELOAD
var chopSound = preload("res://Assets/Audio/Cooking Minigame/Chop.mp3")
var plopSound = preload("res://Assets/Audio/Cooking Minigame/Plop.mp3")
var boilingSound = preload("res://Assets/Audio/Cooking Minigame/Boiling.mp3")
var stoveOffSound = preload("res://Assets/Audio/Cooking Minigame/StoveOff.mp3")
var stoveOnSound = preload("res://Assets/Audio/Cooking Minigame/StoveOn.mp3")
var pourSound = preload("res://Assets/Audio/Cooking Minigame/Pour.mp3")

var shakeSoundOne = preload("res://Assets/Audio/Cooking Minigame/Shake1.mp3")
var shakeSoundTwo = preload("res://Assets/Audio/Cooking Minigame/Shake2.mp3")
var shakeSoundThree = preload("res://Assets/Audio/Cooking Minigame/Shake.mp3")

@export_group("TUTORIAL AREAS")
@export var knifeButton: Button
@export var cuttingBoardArea: Area2D
@export var ingredientShelf: HBoxContainer
@export var recipeBook: Button
@export var potAreaDrop: Area2D

func _ready():
	TutorialManager.shouldBeHidden = true
	
	#region DEBUG SAFETY CHECKS, should be safe to remove (I will not be doing that)
	if not heatDial:
		push_error("No heatdial")
		return
	if not potArea:
		push_error("No potArea")
		return
	if not progressBar:
		push_error("No progressBar")
		return
	if not recipeParser:
		push_error("No parser found")
		return
	if not fireAnimLow:
		push_error("No low fire animation found")
		return
	if not fireAnimMedium:
		push_error("No medium fire animation found")
		return
	if not fireAnimHigh:
		push_error("No high fire animation found")
		return
	if not steamAnim:
		push_error("No steam animation found")
		return
	if not oneShotAudioPlayer:
		push_error("No oneshot audio player found")
		return
	if not constantAudioPlayer:
		push_error("No constant audio player found")
	#endregion
	
	KitchenController.RegisterNodes(heatDial, potArea, progressBar, recipeParser, fireAnimLow, fireAnimMedium, fireAnimHigh, steamAnim, oneShotAudioPlayer, constantAudioPlayer, knifeButton, cuttingBoardArea, ingredientShelf, recipeBook, potAreaDrop)
	
	KitchenController.PrepareSounds(chopSound, plopSound, boilingSound, stoveOffSound, stoveOnSound, pourSound, [shakeSoundOne, shakeSoundTwo, shakeSoundThree])
	
	todaysRecipe = GameManager.todaysRecipe
	
	for key in TaskManager.activeTasks.keys():
		if String(key).contains("_cookMeal"):
			todaysTaskID = key
			KitchenController.currentTaskID = todaysTaskID
			break
	
	KitchenController.StartRecipe(todaysRecipe)
	
	recipeText = recipeParser.ParseRecipeToInstructions(todaysRecipe)
	recipeDisplayLocation.bbcode_enabled = true
	if recipeDisplayLocation2:
		recipeDisplayLocation2.bbcode_enabled = true
	
	# Call the new parser function
	recipeText = recipeParser.ParseRecipeToInstructions(todaysRecipe)
	
	# Assign text to respective labels
	recipeDisplayLocation.text = recipeText["left"]
	if recipeDisplayLocation2:
		recipeDisplayLocation2.text = recipeText["right"]
	
	recipeBookScreen.visible = false
	
	snowWeather.visible = true
	nightSky.visible = true
	oceanAnim.play("default")

func _on_close_pressed() -> void:
	recipeBookScreen.visible = false
	KitchenController.UpdateTutorialState("DIAL")

func _on_recipe_book_button_pressed() -> void:
	recipeBookScreen.visible = true
	TutorialManager.CompleteTutorial("kitchenOpenBook")

func _exit_tree():
	KitchenController.CleanUpReferences()
