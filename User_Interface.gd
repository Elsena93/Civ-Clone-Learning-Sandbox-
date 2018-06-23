extends Control

func _ready():
	pass

func _process(delta):
	var camera = get_node("../MouseNode/Camera2D")
	var camera_center = camera.get_camera_screen_center()
	var vp_size = get_viewport_rect().size
	#print(camera_center)
	#print(size)
	self.rect_position = Vector2(camera_center.x + vp_size.x/2 - self.rect_size.x, camera_center.y - vp_size.y/2)