# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Control

#region Variable Declaration
# SIGNALS
signal puzzle_solved #Need to connect all Gear Buttons ("gearButtonPressed") signal to this function

# CONSTANTS
const SNAP_DISTANCE = 20

# PRELOADS
const heldGearScene = preload("res://Scenes/GearPuzzle/heldGear.tscn")
const placedGearScene = preload("res://Scenes/GearPuzzle/placedGear.tscn")

# SCENE NODES
@onready var startingGear: Area2D = $clippingMaskForGears/GearContainer/StartingGear
@onready var endingGear: Area2D = $clippingMaskForGears/GearContainer/EndingGear
@onready var pegContainer: Node2D = $clippingMaskForGears/PegContainer
@onready var gearContainer: Node2D = $clippingMaskForGears/GearContainer

# STATES
var isHoldingGear = false
var heldGearInstance = null 
var heldGearData = {}

var allGears = []
var puzzleSolved = false
#endregion

func _ready():
	# setup for gear removal
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Assign the start and end gear
	allGears = get_tree().get_nodes_in_group("Gears")
	
	# Start the puzzle
	startingGear.isPowered = true
	startingGear.rotationSpeed = 1.0
	
	# Connect all the buttons
	var allButtons = get_tree().get_nodes_in_group("Gear Buttons")
	for button in allButtons:
		button.gearButtonPressed.connect(onGearButtonPressed)

# Called by the Gear Button signal to assign data to the instantiated held gear
func onGearButtonPressed(buttonData: Dictionary):
	if isHoldingGear:
		returnHeldGear()
	
	isHoldingGear = true
	heldGearData = buttonData
	
	heldGearInstance = heldGearScene.instantiate()
	add_child(heldGearInstance)
	
	heldGearInstance.setup(
		heldGearData["texture"],
		heldGearData["radius"],
		heldGearData["smallScale"]
	)

#region Only needed if not holding a gear
func _input(event: InputEvent) -> void:
	if not isHoldingGear or puzzleSolved:
		return
	
	# check for mouse release
	if event is InputEventMouseButton and not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		handleGearDrop(get_viewport().get_mouse_position())
#endregion

func isPlacementJammed(pegPosition: Vector2, gearRadius: float) -> bool:
	const MAX_ALLOWED_OVERLAP = 20.0
	
	for existingGear in allGears:
		var requiredDistance = gearRadius + existingGear.radius
		var actualDistance = pegPosition.distance_to(existingGear.global_position)
		
		if actualDistance < (requiredDistance - MAX_ALLOWED_OVERLAP):
			print("Placement failed: Jammed against ", existingGear.name)
			return true
	
	return false

func handleGearDrop(_mousePosition: Vector2):
	var closestPeg = null
	var minimumDistance = INF
	
	var heldGearPosition = heldGearInstance.global_position
	
	# FIRST: Find the closest, unoccupied peg
	for peg in pegContainer.get_children():
		if not "isOccupied" in peg: # safety check here to skip anything that I might have accidentally added to this group
			continue
		
		if peg.isOccupied:
			continue
		
		var distance = heldGearPosition.distance_to(peg.global_position)
		print(distance)
		if distance < minimumDistance:
			minimumDistance = distance
			closestPeg = peg
	
	# THEN: Check if we are close enough to snap
	if closestPeg and minimumDistance <= SNAP_DISTANCE:
		# before placing, ensure the gear isn't "jammed" too close to another
		var potentialPosition = closestPeg.global_position
		var potentialRadius = heldGearData["radius"]
		if isPlacementJammed(potentialPosition, potentialRadius):
			returnHeldGear()
		else:
			placeGearOnPeg(closestPeg)
	else:
		returnHeldGear()

func placeGearOnPeg(peg: Node2D):
	# FIRST: Create and add a new "permanent" gear
	var newGear = placedGearScene.instantiate()
	gearContainer.add_child(newGear)
	newGear.setup(
		heldGearData["radius"],
		heldGearData["teeth"],
		heldGearData["texture"],
		heldGearData["button"],
		peg
	)
	newGear.global_position = peg.global_position
	
	# SECOND: Add to arrap of gears for rotation checks
	allGears.append(newGear)
	
	# THIRD: Connect the remove gear signal
	newGear.gear_clicked.connect(_on_placed_gear_clicked.bind(newGear))
	
	# THIRD: Mark the peg as occupied and the button as used
	peg.isOccupied = true
	heldGearData["button"].set_disabled(true) #button remains hidden
	
	# FOURTH: Clean up
	heldGearInstance.queue_free()
	heldGearInstance = null
	isHoldingGear = false

func _on_placed_gear_clicked(gearToRemove: Area2D):
	if isHoldingGear or puzzleSolved:
		return

	if gearToRemove.originatingButton:
		gearToRemove.originatingButton.returnGear()
	
	if gearToRemove.currentPeg:
		gearToRemove.currentPeg.isOccupied = false
	
	allGears.erase(gearToRemove)
	
	gearToRemove.queue_free()

func returnHeldGear():
	#tell the original button to reappear
	heldGearData["button"].returnGear()
	
	#Clean up
	heldGearInstance.queue_free()
	heldGearInstance = null
	isHoldingGear = false

func _process(_delta):
	if puzzleSolved:
		return
	# ROTATION LOGIC
	# This has to recalculate the entire power grid every frame so that it can handle instantly
	# adding and removing gears.
	# FIRST: Reset all gears, except the start gear
	for gear in allGears:
		if gear != startingGear:
			if not gear.isPowered:
				gear.currentDriver = null
			gear.isPowered = false
			gear.rotationSpeed = 0.0
	
	# SECOND: Create a queue of gears to check, starting with the source of power
	var processingQueue = [startingGear]
	var i = 0
	
	while i < processingQueue.size():
		var driverGear = processingQueue[i]
		i += 1
		
		#check this gear against all other gears
		for otherGear in allGears:
			#skip if: it's itself, or already powered
			if otherGear == driverGear or otherGear.isPowered == true:
				continue
			
			# check if they are meshing using the Area2D overlap
			if driverGear.isMeshingWith(otherGear):
				#power that gear
				otherGear.powerOn(driverGear)
				#add it to the queue
				processingQueue.append(otherGear)
	
	# WIN CHECK
	if not puzzleSolved and endingGear.isPowered == true:
		puzzleSolved = true
		emit_signal("puzzle_solved")
		print("Puzzle Solved!")
