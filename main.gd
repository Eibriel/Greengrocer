extends Node3D

enum TASKS {
	NONE,
	GRABBING_WOODBOX,
	DROP,
	RACKING,
	TRASHING,
	GRABBING_DISPLAY
}

var current_task := TASKS.NONE
var grabbing_item := false
var grabbed_item
var current_rack: Rack

var player: Player

var game_state: GameState

#var npc_times:Array[float]
var npc_time := 0.0

const DAY_TIME := 60.0*13.0
var running_time := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Global.racks = $Racks
	Global.scale = $Scale
	Global.npcs = $NPCs
	player = $Player
	player.movement_locked = false
	game_state = GameState.new()
	Global.game_state = game_state
	
	for i in Items.ITEMS:
		game_state.prices[i] = Items.ITEMS[i].market_price_kg
		game_state.market_prices[i] = Items.ITEMS[i].market_price_kg
		game_state.wholesale_prices[i] = Items.ITEMS[i].wholesale_price_kg
		#TODO what is this?
		if Items.ITEMS[i].available_level > 1:
			game_state.item_enabled[i] = false
		else:
			game_state.item_enabled[i] = true
	
	%OrderList.create_list()
	%OrderList.visible = false

	#for _n in 26 * 4.0:
		#npc_times.append(randf_range(0, 14*60))
	#npc_times.sort()
	
	print(game_state.get_level_xp(76690*2))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("notepad"):
		#get_tree().quit()
		%OrderList.visible = !%OrderList.visible
		if %OrderList.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif  event.is_action_pressed("pause"):
		%PauseMenu.pause()
	elif  event.is_action_pressed("end_day"):
		end_day()
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				1:
					fire_ray(event.button_index)
				2:
					current_task = TASKS.DROP
		else:
			release_action_button()

func _process(delta: float) -> void:
	delta *= Global.time_mult
	if game_state.time < DAY_TIME:
		if running_time:
			game_state.time += delta
	else:
		Global.is_open = false
		game_state.time = DAY_TIME
	
	match current_task:
		TASKS.GRABBING_WOODBOX:
			grabbed_item.get_parent_node_3d().remove_child(grabbed_item)
			if grabbed_item is Display:
				$Racks.add_child(grabbed_item)
			else:
				add_child(grabbed_item)
			var grab_transform := player.get_grab_transform()
			grabbed_item.global_transform = grab_transform
			grabbing_item = true
		TASKS.DROP:
			current_task = TASKS.NONE
			grabbed_item.global_position.y = 0
			grabbed_item.global_rotation = Vector3.ZERO
			grabbing_item = false
		TASKS.RACKING:
			current_task = TASKS.NONE
			var rack_transform := current_rack.get_rack_transform()
			current_rack.set_current_woodbox(grabbed_item)
			grabbing_item = false
		TASKS.TRASHING:
			current_task = TASKS.NONE
			if grabbing_item:
				grabbed_item.queue_free()
				grabbing_item = false
	
	var time_hour := int(game_state.time / 60.0)
	var time_minute := int(game_state.time - (time_hour*60))
	$Control/Label.text = "$%.1f - %d - %02d:%02d - XP: %.2f - Level: %.2f - Stats Cust: %d - Expa: %d" % [
		game_state.money,
		game_state.day,
		(time_hour + 8),
		time_minute,
		game_state.xp,
		game_state.get_level(),
		game_state.get_day_stat().customer_amount,
		game_state.shop_expansion
		]
	
	#if npc_times.size()>0 and game_state.time > npc_times[0]:
		#npc_times.pop_at(0)
	npc_time -= delta
	if npc_time < 0.0:
		npc_time = randf_range(0.0, 15.0)
		var new_npc := preload("res://npc.tscn").instantiate()
		$NPCs.add_child(new_npc)
		new_npc.position = Vector3(0,0,14)
		#var all_racks: Array[Rack] = []
		#for r in $Racks.get_children():
			#if r.has_box and r.current_woodbox.amount > 0:
				#all_racks.append(r)
		#if all_racks.size() > 0:
			#var sel_rack: Rack = all_racks.pick_random()
			#if sel_rack.has_box:
				#var box:Woodbox = sel_rack.current_woodbox
				#if box.amount > 0:
					#var buy_amount := randi_range(1, box.amount)
					#box.remove(buy_amount)
					#game_state.money += buy_amount * game_state.get_price(box.type)

	#$SunRotation.rotate_z(0.1*delta)
	$WorldEnvironment.environment.sky.sky_material.energy_multiplier = \
		clamp(remap(game_state.time, 0.0, 60.0*14, 0.3, 0.0), 0.0, 0.3)

func end_day() -> void:
	if game_state.time == DAY_TIME:
		running_time = false
		Global.is_open = false
		game_state.day += 1
		game_state.time = 0.0
	for npc in Global.npcs.get_children():
		#TODO what to do with items
		# NPCs are hlding?
		npc.queue_free()

func release_action_button() -> void:
	#task_timer = 0.0
	#current_task = TASKS.NONE
	pass

func build_ray() -> Dictionary:
	var ray_range := 6.0
	var center := Vector2(get_viewport().get_visible_rect().size / 2)
	var cam := get_viewport().get_camera_3d()
	var ray_origin := cam.project_ray_origin(center)
	var ray_end := ray_origin + (cam.project_ray_normal(center) * ray_range)
	var new_intersection := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1<<8)
	new_intersection.collide_with_areas = true
	new_intersection.collide_with_bodies = false
	var intersection := get_world_3d().direct_space_state.intersect_ray(new_intersection)
	return intersection

func fire_ray(button_index: int) -> void:
	var intersection := build_ray()
	if not intersection.is_empty():
		var coll: Node3D = intersection.collider.get_parent()
		#print(coll.name)
		if coll is Woodbox:
			print("woobox")
			if current_task == TASKS.NONE and not grabbing_item:
				grabbed_item = coll
				current_task = TASKS.GRABBING_WOODBOX
			elif current_task == TASKS.GRABBING_WOODBOX:
				move_item(grabbed_item, coll)
		elif coll is Rack:
			print("rack")
			if coll.has_box:
				if current_task == TASKS.NONE and not grabbing_item:
					grabbed_item = coll.current_woodbox
					current_task = TASKS.GRABBING_WOODBOX
					coll.free_rack()
				if current_task == TASKS.GRABBING_WOODBOX:
					move_item(grabbed_item, coll.current_woodbox)
			elif current_task == TASKS.GRABBING_WOODBOX and \
					grabbed_item is Woodbox:
				current_rack = coll
				current_task = TASKS.RACKING
		#elif coll is DeliveryBoard:
			#print("delivery")
			#var types := Items.TYPE.values()
			#types.pop_front() # Remove empty
			#var buy_type:Items.TYPE = types.pick_random()
			#var buy_amount := 100
			#var buy_price := game_state.get_market_price(buy_type) * buy_amount
			#if game_state.money >= buy_price:
				#game_state.money -= buy_price
				#var new_box := preload("res://woodbox.tscn").instantiate()
				#new_box.add(buy_amount, buy_type)
				#add_child(new_box)
		elif coll is TrashCan:
			current_task = TASKS.TRASHING
		elif coll is Scale:
			var res:Array = coll.execute_queue()
			if res.size() == 3:
				var scale_type = res[0]
				var scale_amount = res[1]
				var scale_price = res[2]
				# TODO price should be the price set at the moment
				# the NPC took the item
				game_state.money += scale_amount * scale_price
		elif coll is OpenSign:
			coll.change_state()
			if Global.is_open:
				running_time = true
		elif coll is Display:
			grabbed_item = coll
			current_task = TASKS.GRABBING_WOODBOX
			grabbing_item = true
		elif coll is Pot:
			grabbed_item = coll
			current_task = TASKS.GRABBING_WOODBOX
			grabbing_item = true
		elif coll is Dirt:
			if current_task == TASKS.GRABBING_WOODBOX and \
					grabbed_item is Woodbox:
				if grabbed_item.type != "":
					if grabbed_item.amount > 0 and coll.amount == 0:
						if coll.type == "":
							coll.type = grabbed_item.type
						if coll.type == grabbed_item.type:
							coll.amount += 1
							grabbed_item.amount -= 1
					elif coll.type == grabbed_item.type and coll.amount > 0:
						coll.amount -= 1
						grabbed_item.amount += 1
				else:
					if coll.amount > 0:
						grabbed_item.type = coll.type
						coll.amount -= 1
						grabbed_item.amount += 1

func move_item(from: Woodbox, to: Woodbox) -> void:
	var from_type := from.type
	if from.remove(1):
		if not to.add(1, from_type):
			from.add(1, from_type)
	#if grabbed_item.type == to.type or to.type == Items.TYPE.EMPTY:
		#if grabbed_item.amount > 0:
			#from.amount -= 1
			#to.amount += 1
			#if to.amount >= 0:
				#to.type = grabbed_item.type
			#if grabbed_item.amount == 0:
				#grabbed_item.type = Items.TYPE.EMPTY


func _on_order_list_buy_completed(buying: Dictionary[String, int]) -> void:
	for by in buying:
		for _n in buying[by]:
			var new_box := preload("res://woodbox.tscn").instantiate()
			new_box.add(100, by)
			new_box.position = Vector3(randf(), 0, 12+randf())
			add_child(new_box)


func _on_order_list_item_enabled(item: ItemRes) -> void:
	pass # Replace with function body.


func _on_order_list_furniture_purchased(furniture: FurnitureRes) -> void:
	var new_furniture: Node3D
	match furniture.item_id:
		"DIAGONAL_2x1":
			new_furniture = preload("res://furniture/diagonal_2x1.tscn").instantiate()
		"VERTICAL_4x3":
			new_furniture = preload("res://furniture/vertical_4x3.tscn").instantiate()
		"CART_3x2":
			new_furniture = preload("res://furniture/cart_3x2.tscn").instantiate()
		# POTS
		"POT_1x1":
			new_furniture = preload("res://furniture/pot_1x1.tscn").instantiate()
	new_furniture.position = Vector3(randf(), 0, 12+randf())
	if new_furniture is Display:
		Global.racks.add_child(new_furniture)
	else:
		add_child(new_furniture)
