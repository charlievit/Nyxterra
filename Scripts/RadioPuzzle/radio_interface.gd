# Copyright (C) 2025 Nyxterra Team & CyberSugar Studios
extends Node2D
#var to hold the copyright string, printed in _ready()
var C = "Copyright (C) 2025 Nyxterra Team & CyberSugar Studios"


#region Variable Declaration
# INSPECTOR VARIABLES
# These variables are marked with @export to adjust them in the Inpector panel
@export var lineLength: int = 500 # The total horizontal length of the line in pixels.
@export var lineSegments: int = 1000 # The number of points used to draw the line. More segments = a smoother, more detailed curve.
@export var lineWidth: float = 2.5 # The thickness (width) of the line in pixels.
@export var speed: float = 1.0 # Controls the animation speed of the wave. 1.0 is normal, 2.0 is double speed, 0.5 is half speed.

# SCENE VARIABLES
@onready var wave: Line2D = $"Screen Space Area/Signal Line" # A direct reference to the Line2D node that will be drawn to.

# WAVE SHAPE VARIABLES
var amplitude: float = 50 # The maximum height (and depth) of the wave from the center line, in pixels.
var frequency: float = 5 # The number of full wave cycles that will appear across the 'lineLength'.
var phase: float # The starting offset of the wave, in radians. This value is animated over time to make the wave move.
#endregion

func _ready():
	print(C) # Print Copyright info to the console.

# Each frame, update the phase of the line to animate it. Then, draw the updated line.
# TAU = 2 * Pi (a full circle measured in radians)
func _process(delta):
	wave.width = lineWidth # Allow the line width to be updated live from the inspector.
	
	# ANIMATE THE WAVE
	# To make the wave move, we continuously add to its phase offset.
	# We multiply by 'speed' to control the rate.
	# We multiply by 'TAU' to work in radians (one full cycle).
	# We multiply by 'delta' to make the animation smooth and frame-rate independent.
	phase += speed * TAU * delta
	
	# WRAP THE PHASE
	# We use fmod (floating-point modulo) to wrap the phase value back to the 0.0 to TAU range. This prevents 'phase' from becoming an infinitely large number, which can lead to floating-point precision errors over time.
	phase = fmod(phase, TAU)
	
	# After we have recaculated the phase for this phrame, we redraw the line.
	_drawWaves()

# This function calculates and sets all the points for the Line2D.
func _drawWaves():
	# Create an empty array to hold all the (x, y) coordinates for our line.
	var points = PackedVector2Array()
	
	# Calculate the horizontal distance (x-step) between each point.
	var step = lineLength / float(lineSegments)
	
	# Loop from 0 to lineSegments. We use 'lineSegments + 1' because N segments require N+1 points.
	for i in lineSegments + 1:
		var x = i * step # The x position is simply the current point index (i) times the step distance.
		
		# CALCULATE THE Y POSITION
		# 1. x / lineLength normalized x from 0.0 to 1.0
		# 2. Multiplying by TAU scales this from 0.0 to TAU (a full radian circle)
		# 3. Multiplying by frequency is to draw the cycles across the line's length
		# 4. Adding phase applies the time-based offset to animate the wave
		var angle = (x / lineLength) * TAU * frequency + phase
		
		# 5. sin(angle) produces a value between -1.0 and 1.0
		# 6. Muliplying by amplitude scales this value to the desired wave height
		var y = sin(angle) * amplitude
		
		# x and y are calculated, append that point to our array
		points.append(Vector2(x, y))
	
	# Finally, assign the completeled array of points to the Line2D node.
	wave.points = points
