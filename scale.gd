extends Node3D
class_name Scale

var queue :Array[NPC] = []

func register_to_queue(npc: NPC) -> void:
	if not queue.has(npc):
		queue.append(npc)

func execute_queue() -> Array:
	if queue.size() <= 0: return []
	var npc := queue[0]
	if npc.items_grabbed.size() <= 0: return []
	var item_key:String = npc.items_grabbed.keys()[0]
	var item_amount:int = npc.items_grabbed[item_key]
	var item_price:float = npc.items_prices[item_key] * Items.ITEMS[item_key].kg
	npc.items_grabbed.erase(item_key)
	if npc.items_grabbed.size() == 0:
		npc.scale_completed()
		queue.erase(npc)
	Global.game_state.xp_to_add += 5.0
	return [item_key, item_amount, item_price]

func _process(delta: float) -> void:
	$Label3D.text = "%d" % queue.size()
	if queue.size() > 0:
		$Label3D.text += " : %d" % queue[0].items_grabbed.size()
