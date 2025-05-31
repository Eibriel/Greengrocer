extends Node3D
class_name Scale

var queue :Array[NPC] = []
var slots :Array[NPC] = []

func register_to_queue(npc: NPC) -> void:
	if not queue.has(npc):
		queue.append(npc)
		$StateChart.send_event("npc_bring_item")

func register_to_slots(npc: NPC) -> void:
	if not slots.has(npc):
		slots.append(npc)

func unregister_to_slots(npc: NPC) -> void:
	if slots.has(npc):
		slots.erase(npc)

func get_free_npc_slot(npc:NPC) -> Node3D:
	var npc_slots := $NPCSlots.get_children()
	var npc_count = min(npc_slots.size()-1, max(0,slots.find(npc)))
	#npc_slots.reverse()
	return npc_slots[npc_count]

func get_last_npc_slot() -> Node3D:
	var npc_slots := $NPCSlots.get_children()
	return npc_slots.front()

func get_player_slot() -> Node3D:
	return $PlayerSlot

func player_in_scale(in_scale:bool=true) -> void:
	if in_scale:
		$StateChart.send_event("player_enters_scale")
	else:
		$StateChart.send_event("player_leaves_scale")

func execute_queue() -> Array:
	if queue.size() <= 0: return []
	var npc := queue[0]
	if npc.items_grabbed.size() <= 0: return []
	if %ItemInCounter.active:
		$StateChart.send_event("player_weights_item")
		return []
	elif %ItemInScale.active:
		var item_key:String = npc.items_grabbed.keys()[0]
		var item_amount:int = npc.items_grabbed[item_key]
		var item_price:float = npc.items_prices[item_key] * Items.ITEMS[item_key].kg
		npc.items_grabbed.erase(item_key)
		if npc.items_grabbed.size() == 0:
			npc.scale_completed()
			queue.erase(npc)
			$StateChart.send_event("all_items_weighted")
		else:
			$StateChart.send_event("npc_bring_item")
		Global.game_state.xp_to_add += 5.0
		return [item_key, item_amount, item_price]
	return []

func _process(delta: float) -> void:
	$LabelQueueSize.text = "%d" % queue.size()
	if queue.size() > 0:
		$LabelQueueSize.text += " : %d" % queue[0].items_grabbed.size()

func _on_item_in_counter_state_entered() -> void:
	if queue.size() <= 0: return
	var npc := queue[0]
	var item_key:String = npc.items_grabbed.keys()[0]
	var item_amount:int = npc.items_grabbed[item_key]
	$LabelItemsInCounter.text = "%s %d" % [item_key, item_amount]
	$LabelItemsInScale.text = ""
	enable_area($ProductArea)
	disable_area($ScaleArea)


func _on_without_player_state_entered() -> void:
	enable_area($CursorArea)

func _on_with_player_state_entered() -> void:
	disable_area($CursorArea)

func _on_item_in_scale_state_entered() -> void:
	if queue.size() <= 0: return
	var npc := queue[0]
	var item_key:String = npc.items_grabbed.keys()[0]
	var item_amount:int = npc.items_grabbed[item_key]
	$LabelItemsInCounter.text = ""
	$LabelItemsInScale.text = "%s %d" % [item_key, item_amount]
	disable_area($ProductArea)
	enable_area($ScaleArea)

func _on_item_in_scale_state_exited() -> void:
	$LabelItemsInScale.text = ""

func disable_area(area:Area3D) -> void:
	area.set_collision_layer_value(9, false)

func enable_area(area:Area3D) -> void:
	area.set_collision_layer_value(9, true)
