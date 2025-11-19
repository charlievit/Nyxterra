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
@onready var daySky: Sprite2D = $SkyDayBackground
@onready var nightSky: Sprite2D = $SkyNightBackground

@export var fireAnimLow: AnimatedSprite2D
@export var fireAnimMedium: AnimatedSprite2D
@export var fireAnimHigh: AnimatedSprite2D

@export var steamAnim: AnimatedSprite2D

@export var oneShotAudioPlayer: AudioStreamPlayer2D
@export var constantAudioPlayer: AudioStreamPlayer2D

@export var recipeDisplayLocation: RichTextLabel
var recipeText: String

# PRELOAD
var chopSound = preload("res://Assets/Audio/Cooking Minigame/Chop.mp3")
var plopSound = preload("res://Assets/Audio/Cooking Minigame/Plop.mp3")
var boilingSound = preload("res://Assets/Audio/Cooking Minigame/Boiling.mp3")
var stoveOffSound = preload("res://Assets/Audio/Cooking Minigame/StoveOff.mp3")
var stoveOnSound = preload("res://Assets/Audio/Cooking Minigame/StoveOn.mp3")

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

	KitchenController.RegisterNodes(heatDial, potArea, progressBar, recipeParser, fireAnimLow, fireAnimMedium, fireAnimHigh, steamAnim, oneShotAudioPlayer, constantAudioPlayer)
	
	KitchenController.PrepareSounds(chopSound, plopSound, boilingSound, stoveOffSound, stoveOnSound)
	
	KitchenController.StartRecipe("RabbitStew")
	
	recipeText = recipeParser.ParseRecipeToInstructions("RabbitStew")
	recipeDisplayLocation.text = recipeText
	
	recipeBookScreen.visible = false
	
	snowWeather.visible = true
	daySky.visible = false
	nightSky.visible = true

func _on_close_pressed() -> void:
	recipeBookScreen.visible = false


func _on_recipe_book_button_pressed() -> void:
	recipeBookScreen.visible = true
