extends Node

var racks:Node3D
var npcs:Node3D
var scale:Scale
var is_open:=false
var game_state:GameState

var time_mult := 2.0

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
