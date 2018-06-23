extends Area2D

onready var mouse_pos
onready var center_tile_direction
onready var tilenode
onready var HALF_CELL_SIZE

onready var SELECTED
#onready var DEST_OCCUPIED = false
onready var REQUESTING_PATH = false


func _ready():
	pass

func _unhandled_input(event):
	tilenode = self.get_node("../TileMap")
	HALF_CELL_SIZE = tilenode.HALF_CELL_SIZE
	mouse_pos = get_global_mouse_position()
	center_tile_direction = tilenode.map_to_world(tilenode.world_to_map(mouse_pos))
	self.set_position((center_tile_direction + Vector2(HALF_CELL_SIZE, HALF_CELL_SIZE)))

	if (Input.is_action_just_released("left_click")):
		if (SELECTED == null):
			var overlap = self.get_overlapping_bodies()
			if overlap.size() > 0:
				SELECTED = overlap[0]
		elif (SELECTED != null) :
			#var overlap = self.get_overlapping_bodies()
			#if overlap.size() > 0:
				#DEST_OCCUPIED = true
			set_process_unhandled_input(false)
			REQUESTING_PATH = true
		else:
			pass
	elif (Input.is_action_just_released("right_click")):
			SELECTED = null
	else:
		pass