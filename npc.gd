extends Node3D
class_name NPC

var items_grabbed: Dictionary[String, int]
var items_prices: Dictionary[String, float]
var shopping_list: Dictionary[String, int]

var selected_woodbox:Woodbox
#var current_state := STATE.IDLE

var idle_time := 0.0
var searching_time := 0.0
var picking_time := 0.0
var is_scale_completed := false
var is_in_shop := false

const SPEED := 2.0

#enum STATE {
	#IDLE,
	#WALKING_IN,
	#WALKING_TO_WOODBOX,
	#GRABBING_ITEMS,
	#WALKING_TO_SCALE,
	#WALKING_OUT
#}

var npc_anim:AnimationPlayer
var astar_box_grid:Dictionary[Vector2i,MeshInstance3D]

var next_path_position:Vector3

func _ready() -> void:
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
		var item_options := Items.get_available_items(Global.game_state.get_level(), true)
		item_options.shuffle()
		#print(item_options)
		for n in randi_range(1, 4):
			shopping_list[item_options.pop_front().item_id] = randi_range(1, 12)
	else:
		var available_types: Array[String] = []
		for r:Rack in get_rack_list():
			if r.has_box:
				if r.current_woodbox.type == "": continue
				if available_types.has(r.current_woodbox.type): continue
				available_types.append(r.current_woodbox.type)
		if available_types.size() > 0:
			available_types.shuffle()
			for n in randi_range(1, min(4, available_types.size())):
				shopping_list[available_types.pop_front()] = randi_range(1, 12)
	#for sh in shopping_list:
	#	items_grabbed[sh] = 0
	$Label3D2.text = ""
	
	npc_anim = $remy/AnimationPlayer
	
	npc_anim.get_animation("Walking").loop_mode = Animation.LoopMode.LOOP_LINEAR
	npc_anim.get_animation("Idle").loop_mode = Animation.LoopMode.LOOP_LINEAR
	npc_anim.play("Idle")

func _process(delta: float) -> void:
	#delta *= Global.time_mult
	$Label3D.text = ""
	#for sl in shopping_list:
	#	$Label3D.text += "\n%s: %d" % [Woodbox.ITEM_TYPE.find_key(sl), shopping_list[sl]]
	#$Label3D.text += "\n---"
	for ig in items_grabbed:
		$Label3D.text += "\n%s: %d" % [ig, items_grabbed[ig]]

#func _process_old(delta:float) -> void:
	#match current_state:
		#STATE.IDLE:
			#var max_npcs_allowed := Global.game_state.get_npc_amount()
			##prints(Global.get_npc_count(), max_npcs_allowed)
			#if Global.is_open and Global.get_npc_count() < max_npcs_allowed:
				#Global.game_state.set_day_stat("customer_amount", 1)
				#current_state = STATE.WALKING_IN
			#else:
				#idle_time += delta
				#if idle_time > 30.0:
					#current_state = STATE.WALKING_OUT
		#STATE.WALKING_IN:
			#var shop_center := Vector3(0,0,-1)
			#if position.distance_to(shop_center) < 0.5:
				#switch_animation("Idle")
				#var found := false
				##print(get_rack_list().size())
				##for r:Rack in get_rack_list():
					##prints("Rack!", r.has_box)
				#for r:Rack in get_rack_list():
					#if not r.has_box: continue
					#print(r.current_woodbox.type)
					#if shopping_list.has(r.current_woodbox.type):
						#selected_woodbox = r.current_woodbox
						#current_state = STATE.WALKING_TO_WOODBOX
						#found = true
						#searching_time = 0.0
						#break
				#if not found:
					#searching_time += delta
					#if searching_time > 10.0:
						#if shopping_list.size() > 0:
							#$Label3D2.text = "Can't find %s" % shopping_list.keys()[0]
						#if items_grabbed.size() > 0:
							#current_state = STATE.WALKING_TO_SCALE
						#else:
							#$Label3D2.text = "ERROR 1"
							#current_state = STATE.WALKING_OUT
			#else:
				#switch_animation("Walking")
				#move_towards(shop_center, delta)
		#STATE.WALKING_TO_WOODBOX:
			#var woodbox_pos := selected_woodbox.global_position
			#woodbox_pos.y = 0
			#if not selected_woodbox or selected_woodbox.is_queued_for_deletion():
				#current_state = STATE.WALKING_IN
			#elif position.distance_to(woodbox_pos) < 0.1:
				#switch_animation("Idle")
				#var sw_type = selected_woodbox.type
				#if selected_woodbox.amount > 0:
					#if not is_price_ok(selected_woodbox):
						#$Label3D2.text = "%s is fkn expensive" % sw_type
						#shopping_list.erase(sw_type)
						#check_shopping_list()
					#else:
						#items_prices[sw_type] = Global.game_state.get_price(sw_type)
						#current_state = STATE.GRABBING_ITEMS
				#else:
					#$Label3D2.text = "ERROR 2"
					#shopping_list.erase(sw_type)
					#check_shopping_list()
			#else:
				#switch_animation("Walking")
				#move_towards(woodbox_pos, delta)
		#STATE.GRABBING_ITEMS:
			#switch_animation("Pick")
			#if not selected_woodbox or selected_woodbox.is_queued_for_deletion():
				#current_state = STATE.WALKING_IN
			#elif not shopping_list.has(selected_woodbox.type):
				#current_state = STATE.WALKING_IN
			#elif selected_woodbox.amount > 0:
				#if picking_time > 0.0:
					#picking_time -= delta
				#else:
					#picking_time = 1.0
					##current_state = STATE.GRABBING_ITEMS
					#var sw_type = selected_woodbox.type
					#items_grabbed.get_or_add(sw_type, 0)
					#items_grabbed[sw_type] += 1
					#selected_woodbox.remove(1)
					#if items_grabbed[sw_type] >= shopping_list[sw_type]:
						#$Label3D2.text = "ERROR 3"
						#shopping_list.erase(sw_type)
						#check_shopping_list()
			#else:
				#current_state = STATE.WALKING_IN
		#STATE.WALKING_TO_SCALE:
			#if position.distance_to(Global.scale.position) < 0.2:
				#Global.scale.register_to_queue(self)
				#switch_animation("Idle")
			#else:
				#switch_animation("Walking")
				#move_towards(Global.scale.position, delta)
		#STATE.WALKING_OUT:
			#var out_pos := Vector3(5, 0, 14)
			#if position.distance_to(out_pos) < 0.5:
				#queue_free()
			#else:
				#switch_animation("Walking")
				#move_towards(out_pos, delta)
	


func _physics_process(delta: float) -> void:
	var npc_pos := position
	npc_pos.y = 0
	if $NavigationAgent3D.is_navigation_finished():
		next_path_position = $NavigationAgent3D.target_position
	elif $NavigationAgent3D.get_final_position().distance_to(npc_pos) < 0.5:
		next_path_position = $NavigationAgent3D.target_position
	else:
		next_path_position = $NavigationAgent3D.get_next_path_position()
		next_path_position.y = 0


func switch_animation(animation_id: String) -> void:
	if npc_anim.current_animation != animation_id:
		npc_anim.play(animation_id)
		if animation_id == "Walking":
			npc_anim.speed_scale = 1.2

func get_rack_list() -> Array[Rack]:
	var racks: Array[Rack] = []
	for display in Global.racks.get_children():
		racks.append_array(display.get_node("Racks").get_children())
	return racks

func scale_completed() -> void:
	#current_state = STATE.WALKING_OUT
	is_scale_completed = true

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
	pathfinding(target_pos)
	var direction := position.direction_to(next_path_position)
	direction.y = 0
	#translate(direction*SPEED*delta)
	position += direction*SPEED*delta
	look_at(next_path_position, Vector3.UP, true)

func pathfinding(target_pos:Vector3) -> void:
	if $NavigationAgent3D.target_position != target_pos:
		$NavigationAgent3D.target_position = target_pos


func _on_walking_in_state_processing(delta: float) -> void:
	var shop_front := Vector3(2,0,3)
	switch_animation("Walking")
	move_towards(shop_front, delta)
	
	if position.distance_to(shop_front) < 0.5:
		$StateChart.send_event("in_shop_front")

func _on_waiting_outside_state_entered() -> void:
	switch_animation("Idle")

func _on_waiting_outside_state_processing(delta: float) -> void:
	var max_npcs_allowed := Global.game_state.get_npc_amount()
	#prints(Global.get_npc_count(), max_npcs_allowed)
	if Global.is_open and Global.get_npc_count() < max_npcs_allowed:
		Global.game_state.set_day_stat("customer_amount", 1)
		$StateChart.send_event("allowed_to_enter")
	else:
		idle_time += delta
		if idle_time > 30.0:
			$StateChart.send_event("bored_waiting_to_open")

func _on_searching_item_state_entered() -> void:
	switch_animation("Idle")
	is_in_shop = true

func _on_searching_item_state_processing(delta: float) -> void:
	var found := false
	for r:Rack in get_rack_list():
		if not r.has_box: continue
		if shopping_list.has(r.current_woodbox.type):
			selected_woodbox = r.current_woodbox
			$StateChart.send_event("item_found")
			found = true
			searching_time = 0.0
			break
	if not found:
		searching_time += delta
		if searching_time > 10.0:
			if shopping_list.size() > 0:
				$Label3D2.text = "Can't find %s" % shopping_list.keys()[0]
			if items_grabbed.size() > 0:
				$StateChart.send_event("all_items_grabbed")
			else:
				$Label3D2.text = "ERROR 1"
				$StateChart.send_event("shop_complete")

func _on_walking_to_item_state_entered() -> void:
	switch_animation("Walking")

func _on_walking_to_item_state_processing(delta: float) -> void:
	var woodbox_pos := selected_woodbox.global_position
	woodbox_pos.y = 0
	move_towards(woodbox_pos, delta)
	if position.distance_to(woodbox_pos) < 0.1:
		$StateChart.send_event("at_item_grabbing_position")

func _on_grabbing_item_state_entered() -> void:
	switch_animation("Pick")

func _on_grabbing_item_state_processing(delta: float) -> void:
	if not selected_woodbox or selected_woodbox.is_queued_for_deletion():
		$StateChart.send_event("grabbing_complete")
	elif not shopping_list.has(selected_woodbox.type):
		$StateChart.send_event("grabbing_complete")
	elif selected_woodbox.amount > 0:
		if picking_time > 0.0:
			picking_time -= delta
		else:
			picking_time = 1.0
			var sw_type = selected_woodbox.type
			items_grabbed.get_or_add(sw_type, 0)
			items_grabbed[sw_type] += 1
			selected_woodbox.remove(1)
			if items_grabbed[sw_type] >= shopping_list[sw_type]:
				$Label3D2.text = "ERROR 3"
				shopping_list.erase(sw_type)
				$StateChart.send_event(check_shopping_list())
	else:
		$StateChart.send_event("grabbing_complete")


func _on_walking_to_line_state_entered() -> void:
	switch_animation("Walking")

func _on_walking_to_line_state_processing(delta: float) -> void:
	move_towards(Global.scale.position, delta)
	if position.distance_to(Global.scale.position) < 0.2:
		$StateChart.send_event("at_scale")

func _on_handing_item_state_entered() -> void:
	switch_animation("Idle")
	Global.scale.register_to_queue(self)

func _on_handing_item_state_processing(delta: float) -> void:
	if is_scale_completed:
		$StateChart.send_event("all_items_handed")

func _on_walking_out_state_entered() -> void:
	switch_animation("Walking")
	is_in_shop = false

func _on_walking_out_state_processing(delta: float) -> void:
	var out_pos := Vector3(20,0,3)
	move_towards(out_pos, delta)
	if position.distance_to(out_pos) < 0.5:
		queue_free()


func _on_check_item_price_state_entered() -> void:
	switch_animation("Idle")

func _on_check_item_price_state_processing(delta: float) -> void:
	var sw_type = selected_woodbox.type
	if selected_woodbox.amount > 0:
		if not is_price_ok(selected_woodbox):
			$Label3D2.text = "%s is fkn expensive" % sw_type
			shopping_list.erase(sw_type)
			$StateChart.send_event(check_shopping_list())
		else:
			items_prices[sw_type] = Global.game_state.get_price(sw_type)
			$StateChart.send_event("item_grab_allowed")
	else:
		$Label3D2.text = "ERROR 2"
		shopping_list.erase(sw_type)
		$StateChart.send_event(check_shopping_list())


func check_shopping_list() -> String:
	if shopping_list.size() > 0:
		return "grabbing_complete"
	else:
		if items_grabbed.size() > 0:
			return "all_items_grabbed"
		else:
			return "shop_complete"
