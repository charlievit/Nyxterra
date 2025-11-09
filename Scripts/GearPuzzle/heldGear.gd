extends Sprite2D

@export var puzzleAreaX_threshold: int = 336
@export var transitionSpeed: float = 8.0 #need to adjust to make size change look good

var fullScale: float = 2.0
var smallScale: float = 1.0

func setup(tex: Texture, rad: int, sScale: float):
	self.texture = tex
	smallScale = sScale
	
	self.centered = true
	
	if self.texture:
		fullScale = rad / (self.texture.get_width() / 2.0)
	
	self.scale = Vector2(smallScale, smallScale)
	
func _process(delta):
	self.global_position = get_viewport().get_mouse_position()
	
	var targetScale: Vector2
	
	if self.global_position.x > puzzleAreaX_threshold:
		targetScale = Vector2(fullScale, fullScale)
	else:
		targetScale = Vector2(smallScale, smallScale)
	
	self.scale = self.scale.lerp(targetScale, delta * transitionSpeed)
