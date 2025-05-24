extends Node

var racks:Node3D
var npcs:Node3D
var scale:Scale
var is_open:=false
var game_state:GameState

var time_mult := 1.0

var astar_grid: AStarGrid2D

func _ready() -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(-16, -16, 32, 32)
	astar_grid.cell_size = Vector2(0.5, 0.5)
	#astar_grid.region.position *= astar_grid.cell_size
	#astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

func _process(delta: float) -> void:
	if game_state.xp_to_add > 0:
		var amount_to_move = min(1.0, game_state.xp_to_add)
		game_state.xp += amount_to_move
		game_state.xp_to_add -= amount_to_move

func get_npc_count() -> int:
	var count := 0
	for npc:NPC in npcs.get_children():
		if not [NPC.STATE.IDLE, NPC.STATE.WALKING_OUT].has(npc.current_state):
			count += 1
	return count

func astar_get_path(from: Vector2, to:Vector2) -> PackedVector2Array:
	var from_id := astar_closest_id(from)
	var to_id := astar_closest_id(to)
	
	#astar_grid.update()
	# print(astar_grid.get_id_path(Vector2i(0, 0), Vector2i(3, 4))) # Prints [(0, 0), (1, 1), (2, 2), (3, 3), (3, 4)]
	return astar_grid.get_point_path(from_id, to_id)

func astar_closest_id(pos:Vector2) -> Vector2i:
	var closest:Vector2i
	var min_dist := 99999.0
	for x in astar_grid.region.size.x:
		for y in astar_grid.region.size.y:
			var id := Vector2i(x,y) + astar_grid.region.position
			var id_pos := astar_grid.get_point_position(id) *0.5
			var dist := id_pos.distance_to(pos)
			if dist < min_dist:
				min_dist = dist
				closest = id
	return closest

func navigation_path() -> void:
	pass
	NavigationPolygon
