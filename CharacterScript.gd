extends KinematicBody2D

onready var TILE_INIT_POS = Vector2(0, 0)
onready var MAX_SPEED = 400
onready var movement = false
onready var currentpos = self.position
onready var TILENODE
onready var SELECTOR
onready var as_path
onready var HALF_CELL_SIZE
onready var storing_path

func _ready():
	pass

func _physics_process(delta):
	TILENODE = self.get_node("../../TileMap")
	SELECTOR = self.get_node("../../Selector")
	HALF_CELL_SIZE = TILENODE.HALF_CELL_SIZE
	if storing_path == true:
		as_path = TILENODE.a_path
		storing_path = false
		if as_path.size() >= 1:
			movement = true
	currentpos = self.position
	if movement == true:
		var destination = Vector2(as_path[0].x, as_path[0].y)
		var direction = (destination - currentpos).normalized()
		self.move_and_collide(direction * MAX_SPEED * delta)
		if (abs(currentpos.x - as_path[0].x) < HALF_CELL_SIZE/8 and abs(currentpos.y - as_path[0].y) < HALF_CELL_SIZE/8):
			self.set_position(destination)
			as_path.remove(0)
		if (as_path.size() == 0):
			movement = false
			SELECTOR.set_process_unhandled_input(true)
	else:
		pass