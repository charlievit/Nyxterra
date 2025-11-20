# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Area2D

#region VARIABLES
@export_enum("Up", "Down", "None") var direction: String = "None"
@export var targetFloor: int = 1
@export var targetTeleporter: NodePath

@onready var label: RichTextLabel = $ButtonPrompt

var baseLabelPos: Vector2
var playerBody: CharacterBody2D = null

@export var centerOfTower: float = 167 # used for flipping character on teleport
#endregion VARIABLES

func _ready():
	# Connect signals
	self.body_entered.connect(OnBodyEntered)
	self.body_exited.connect(OnBodyExited)
	
	if label:
		# Hide label and store its position for bobbing
		label.visible = false
		baseLabelPos = label.position
	else:
		push_error("ERROR: label missing")

func _process(_delta):
	# Animate the label
	if playerBody and label:
		# Bob up and down
		label.position.y = baseLabelPos.y + (sin(Time.get_ticks_msec() * 0.005) * 3.0)
	
	if playerBody:
		if direction == "Up" and Input.is_action_pressed("ui_up"):
			DoTeleport(playerBody)
		elif direction == "Down" and Input.is_action_pressed("ui_down"):
			DoTeleport(playerBody)

func OnBodyEntered(body):
	if body.is_in_group("player"):
		playerBody = body # Store the player
		if label:
			label.visible = true
		
		if body.has_method("EnterTeleporterArea"):
			body.EnterTeleporterArea(self)

func OnBodyExited(body):
	if body.is_in_group("player"):
		playerBody = null # Clear the player
		if label:
			label.visible = false
		
		if body.has_method("ExitTeleporterArea"):
			body.ExitTeleporterArea(self)

func DoTeleport(body):
	# Find the target
	var target = get_node_or_null(targetTeleporter)
	
	if not target:
		push_error("No target teleporter assigned to " + self.name)
		return
	
	# FIRST: Teleport the player
	body.global_position = target.global_position
	
	# SECOND: Rotate the payer to face correctly
	var shouldFlip: bool = body.global_position.x > centerOfTower
	body.sprite.flip_h = shouldFlip
	
	# LAST: Update floor
	if body.has_method("SetFloor"):
		body.SetFloor(targetFloor)
