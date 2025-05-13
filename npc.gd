extends Node3D
class_name NPC

var items_grabbed: Dictionary[String, int]
var items_prices: Dictionary[String, float]
var shopping_list: Dictionary[String, int]

var selected_woodbox:Woodbox
var current_state := STATE.IDLE

var idle_time := 0.0
var searching_time := 0.0

enum STATE {
	IDLE,
	WALKING_IN,
	WALKING_TO_WOODBOX,
	GRABBING_ITEMS,
	WALKING_TO_SCALE,
	WALKING_OUT
}

func _ready() -> void:
	var item_options := Items.get_available_items(Global.game_state.get_level(), true)
	#item_options.erase(Woodbox.ITEM_TYPE.EMPTY)
	var chance := 0.05 # Chance of predefined list
	var level := Global.game_state.get_level()
	if level <= 2:
		chance = 0.05
	elif level <= 4:
		chance = 0.12
	elif level <= 9:
		chance = 0.25
	else:
		chance = 0.4
	if chance > randf():
		for n in randi_range(1, 4):
			item_options.shuffle()
			shopping_list[item_options.pop_front().item_id] = randi_range(1, 12)
	else:
		var available_types: Array[String] = []
		for r:Rack in get_rack_list():
			if r.has_box:
				if r.current_woodbox.type == "": continue
				if available_types.has(r.current_woodbox.type): continue
				available_types.append(r.current_woodbox.type)
		if available_types.size() > 0:
			for n in randi_range(1, min(4, available_types.size())):
				available_types.shuffle()
				shopping_list[available_types.pop_front()] = randi_range(1, 12)
	#for sh in shopping_list:
	#	items_grabbed[sh] = 0
	$Label3D2.text = ""

func _process(delta: float) -> void:
	delta *= Global.time_mult
	match current_state:
		STATE.IDLE:
			var max_npcs_allowed := Global.game_state.get_npc_amount()
			if Global.is_open and Global.get_npc_count() < max_npcs_allowed:
				Global.game_state.set_day_stat("customer_amount", 1)
				current_state = STATE.WALKING_IN
			else:
				idle_time += delta
				if idle_time > 30.0:
					current_state = STATE.WALKING_OUT
		STATE.WALKING_IN:
			if position.distance_to(Vector3.ZERO) < 0.5:
				var found := false
				for r:Rack in get_rack_list():
					if not r.has_box: continue
					if shopping_list.has(r.current_woodbox.type):
						selected_woodbox = r.current_woodbox
						current_state = STATE.WALKING_TO_WOODBOX
						found = true
						searching_time = 0.0
						break
				if not found:
					searching_time += delta
					if searching_time > 10.0:
						if shopping_list.size() > 0:
							$Label3D2.text = "Can't find %s" % shopping_list.keys()[0]
						if items_grabbed.size() > 0:
							current_state = STATE.WALKING_TO_SCALE
						else:
							current_state = STATE.WALKING_OUT
			else:
				move_towards(Vector3.ZERO, delta)
		STATE.WALKING_TO_WOODBOX:
			if not selected_woodbox or selected_woodbox.is_queued_for_deletion():
				current_state = STATE.WALKING_IN
			elif position.distance_to(selected_woodbox.position) < 0.5:
				var sw_type = selected_woodbox.type
				if selected_woodbox.amount > 0:
					if not is_price_ok(selected_woodbox):
						$Label3D2.text = "%s is fkn expensive" % sw_type
						shopping_list.erase(sw_type)
						check_shopping_list()
					else:
						items_prices[sw_type] = Global.game_state.get_price(sw_type)
						current_state = STATE.GRABBING_ITEMS
				else:
					shopping_list.erase(sw_type)
					check_shopping_list()
			else:
				move_towards(selected_woodbox.position, delta)
		STATE.GRABBING_ITEMS:
			if not selected_woodbox or selected_woodbox.is_queued_for_deletion():
				current_state = STATE.WALKING_IN
			elif not shopping_list.has(selected_woodbox.type):
				current_state = STATE.WALKING_IN
			elif selected_woodbox.amount > 0:
				current_state = STATE.GRABBING_ITEMS
				var sw_type = selected_woodbox.type
				items_grabbed.get_or_add(sw_type, 0)
				items_grabbed[sw_type] += 1
				selected_woodbox.remove(1)
				if items_grabbed[sw_type] >= shopping_list[sw_type]:
					shopping_list.erase(sw_type)
					if shopping_list.size() > 0:
						current_state = STATE.WALKING_IN
					else:
						if items_grabbed.size() > 0:
							current_state = STATE.WALKING_TO_SCALE
						else:
							current_state = STATE.WALKING_OUT
			else:
				current_state = STATE.WALKING_IN
		STATE.WALKING_TO_SCALE:
			if position.distance_to(Global.scale.position) < 0.5:
				Global.scale.register_to_queue(self)
			else:
				move_towards(Global.scale.position, delta)
		STATE.WALKING_OUT:
			var out_pos := Vector3(0, 0, 14)
			if position.distance_to(out_pos) < 0.5:
				queue_free()
			else:
				move_towards(out_pos, delta)
	
	$Label3D.text = ""
	#for sl in shopping_list:
	#	$Label3D.text += "\n%s: %d" % [Woodbox.ITEM_TYPE.find_key(sl), shopping_list[sl]]
	#$Label3D.text += "\n---"
	for ig in items_grabbed:
		$Label3D.text += "\n%s: %d" % [ig, items_grabbed[ig]]

func get_rack_list() -> Array[Rack]:
	var racks: Array[Rack] = []
	for rb in Global.racks.get_children():
		racks.append_array(rb.get_node("Racks").get_children())
	return racks

func check_shopping_list() -> void:
	if shopping_list.size() > 0:
		current_state = STATE.WALKING_IN
	else:
		if items_grabbed.size() > 0:
			current_state = STATE.WALKING_TO_SCALE
		else:
			current_state = STATE.WALKING_OUT

func scale_completed() -> void:
	current_state = STATE.WALKING_OUT

func is_price_ok(woodbox: Woodbox) -> bool:
	var item_type := woodbox.type
	var item_price := Global.game_state.get_price(item_type)
	var item_market_price := Global.game_state.get_market_price(item_type)
	var ratio := (item_price / item_market_price) - 1.0
	var chance := 1.0
	prints(item_price, item_market_price, ratio, chance)
	if ratio < -0.2:
		chance = 1.0
	elif ratio < -0.1:
		chance = 0.95
	elif ratio < 0.0:
		chance = 0.9
	elif ratio < 0.1:
		chance = 0.75
	elif ratio < 0.2:
		chance = 0.6
	elif ratio < 0.3:
		chance = 0.45
	elif ratio < 0.4:
		chance = 0.15
	elif ratio < 0.5:
		chance = 0.05
	elif ratio < 0.6:
		chance = 0.01
	else:
		return false
	if chance >= randf():
		return true
	else:
		return false

func move_towards(target_pos: Vector3, delta:float) -> void:
	var direction := position.direction_to(target_pos)
	translate(direction*1.0*delta)
