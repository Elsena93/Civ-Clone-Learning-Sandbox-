extends TileMap

onready var MAP_WIDTH = 16
onready var MAP_HEIGHT = 16
onready var HALF_CELL_SIZE = self.cell_size.x * 0.5

onready var as = AStar.new()
onready var a_path = []

onready var CURRENT_CHAR
onready var SELECTOR
onready var OCCUPIED_TILES = {}

onready var disconnected_points = []

func _ready():
	#Create AStar point on each tile
	for x in range(0, MAP_WIDTH):
		for y in range(0, MAP_HEIGHT):
			if (self.get_cell(x, y) != -1):
				var edge_tile_coor = self.map_to_world(Vector2(x, y))
				var centering_offset = Vector2(HALF_CELL_SIZE, HALF_CELL_SIZE)
				var center_tile_coor = edge_tile_coor + centering_offset
				var index = generate_index(x, y)
				var pointx = center_tile_coor.x
				var pointy = center_tile_coor.y
				var vec = Vector3(pointx, pointy, 0.0)
				var cost = check_cost(x, y)
				as.add_point(index, vec, cost)

	#Connect neighbouring points
	for x in range(0, MAP_WIDTH):
		for y in range(0, MAP_HEIGHT):
			for i in range(-1, 2):
				for j in range(-1, 2):
					if (x != (x + i) or y != (y + j)):
						if (self.get_cell(x + i, y + j) != -1):
							var apoint = generate_index(x, y)
							var neighbour = generate_index(x + i, y + j)
							if (as.are_points_connected(apoint, neighbour) == false):
								as.connect_points(apoint, neighbour, true)
	
	#Initiate OCCUPIED_TILES to keep track WorldObject occupied tiles
	for x in range(0, MAP_WIDTH):
		OCCUPIED_TILES[x] = {}
		for y in range(0, MAP_HEIGHT):
			OCCUPIED_TILES[x][y] = null

func tile_to_astar_coor(tilecoor):
	var indx = generate_index(tilecoor.x, tilecoor.y)
	var astar_coordinate = as.get_point_position(indx)
	return Vector2(astar_coordinate.x, astar_coordinate.y)

func check_cost(i, j):
	var cell_id = self.get_cell(i, j)
	var tile_name = self.tile_set.tile_get_name(cell_id)
	match tile_name:
		"Grass" : return(1)
		"Water" : return(10)
		"Dirt" : return(3)
		"Wall" : return(9999)
	
func generate_index(i, j):
	var idx = 0.5 * (i + j) * (i + j + 1 ) + j
	return idx

#Check obstacle in path and freed the point from its neighbours
func check_obstacle_in_path(path):
	var currently_checked = path
	for point in currently_checked:
		#print("DEBUG: Currently checked point: %s" %  [point])
		var point_to_tile = self.world_to_map(Vector2(point.x, point.y))
		var occupier = OCCUPIED_TILES[int(point_to_tile.x)][int(point_to_tile.y)]
		if occupier != null:
			disconnect_neighbouring_points(point_to_tile.x, point_to_tile.y)
			#print("DEGUB: Popped tile: %s ; Popped point: %s" %  [point_to_tile, point])

func disconnect_neighbouring_points(x, y):
	for i in range(-1, 2):
		for j in range(-1, 2):
			var neighbour = Vector2(x+i, y+j)
			var neighbour_id = generate_index(x+i, y+j)
			var home = Vector2(x, y)
			var home_id = generate_index(x, y)
			var connection_before = as.are_points_connected(neighbour_id, home_id)
			#print("DEBUG: %s to %s connection currently %s" % [neighbour, home, connection_before])
			as.disconnect_points(neighbour_id, home_id)
			var connection_after = as.are_points_connected(neighbour_id, home_id)
			#print("DEBUG: %s to %s connection currently %s" % [neighbour, home, connection_after])
	disconnected_points.append(Vector2(x,y))
			

func reconnect_neighbouring_points():
	for point in disconnected_points:
		for i in range(-1, 2):
			for j in range(-1, 2):
				as.connect_points(generate_index(point.x, point.y), generate_index(point.x + i, point.y + j), true)
		disconnected_points.erase(point)

func is_destination_occupied(Vector3_path):
	var destination = Vector3_path[Vector3_path.size() - 1]
	var tile_des = world_to_map(Vector2(destination.x, destination.y))
	if (OCCUPIED_TILES[int(tile_des.x)][int(tile_des.y)] != null):
		return true

func _physics_process(delta):
	CURRENT_CHAR = self.get_node("../Selector").SELECTED
	SELECTOR = self.get_node("../Selector")
	#DEST_OCCUPIED = self.get_node("../Selector").DEST_OCCUPIED
	if SELECTOR.REQUESTING_PATH == true and CURRENT_CHAR != null:
		a_path.resize(0)
		var fintile = world_to_map(get_global_mouse_position())
		var initile = world_to_map(CURRENT_CHAR.position)
		var a_fin = generate_index(fintile.x, fintile.y)
		var a_ini = generate_index(initile.x, initile.y)
		a_path = as.get_point_path(a_ini, a_fin)
		a_path.remove(0)
		if (a_path.size() > 0 and is_destination_occupied(a_path) == true):
			a_path.remove(a_path.size() - 1)
		#print("DEBUG: current path: %s" % [a_path])
		check_obstacle_in_path(a_path)
		#print("DEBUG: currently diconnected: %s" % [disconnected_points])
		a_path = as.get_point_path(a_ini, a_fin)
		a_path.remove(0)
		if (a_path.size() > 0 and is_destination_occupied(a_path) == true):
			a_path.remove(a_path.size() - 1)
		#print("DEBUG: current path: %s" % [a_path])
		reconnect_neighbouring_points()
		#print("DEBUG: currently diconnected: %s" % [disconnected_points])
		#a_path = as.get_point_path(a_ini, a_fin)
		#a_path.remove(0)
		#reconnect_neighbouring_points()
		#if (SELECTOR.DEST_OCCUPIED == true and a_path.size() > 0):
			#a_path.remove(a_path.size() - 1)
			#SELECTOR.DEST_OCCUPIED = false
		SELECTOR.REQUESTING_PATH = false
		if (a_path.size() > 0):
			CURRENT_CHAR.storing_path = true
		else:
			SELECTOR.set_process_unhandled_input(true)

func _on_Button_pressed():
	for x in range(0, MAP_WIDTH):
		for y in range(0, MAP_HEIGHT):
			if (OCCUPIED_TILES[x][y] != null):
				print("DEBUG: (%d, %d) occupied by %s"% [x, y ,OCCUPIED_TILES[x][y]])
	print("DEBUG: Debug message done")

#func _physics_process(delta):
	#currentpos = AVATAR.position
	#if movement == true:
		#var destination = Vector2(a_path[0].x, a_path[0].y)
		#var direction = (destination - currentpos).normalized()
		#AVATAR.move_and_collide(direction * MAX_SPEED * delta)
		#if (abs(currentpos.x - a_path[0].x) < HALF_CELL_SIZE/8 and abs(currentpos.y - a_path[0].y) < HALF_CELL_SIZE/8):
			#AVATAR.set_position(destination)
			#if (a_path.size() > 1):
				#a_path.remove(0)
			#else:
				#movement = false
	#else:
		#pass
		
