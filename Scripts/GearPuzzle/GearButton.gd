extends Button

# CUSTOM SIGNAL
signal gearButtonPressed(buttonData: Dictionary) # send data to the main puzzle controller script

# INSPECTOR VARIABLES
# Set this variables in the inspector to ensure that the game knows which button holds which gear
@export var gearRadius: int = 48
@export var gearSmallScale: float = 1.0 #scale when in the UI

var originalIconTexture: Texture


func _ready():
	self.pressed.connect(_on_pressed)
	
	if self.icon:
		originalIconTexture = self.icon
		print(originalIconTexture)

func _on_pressed():
	print("Pressed")
	self.icon = null
	set_disabled(true)
	print(originalIconTexture)
	# Package up data
	var data = {
		"button": self,
		"radius": gearRadius,
		"texture": originalIconTexture,
		"smallScale": gearSmallScale
	}
	emit_signal("gearButtonPressed", data)

func returnGear():
	self.icon = originalIconTexture
	set_disabled(false)
