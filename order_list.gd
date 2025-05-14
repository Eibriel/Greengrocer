extends Control

signal buy_completed
signal item_enabled
signal furniture_purchased

var total_label: Label
var buy_button: Button
var buying_amounts:Dictionary[String, SpinBox]

var prev_level:=0

func create_list() -> void:
	for c in %OrderList.get_children():
		c.queue_free()
	for wi in Items.get_available_items(Global.game_state.get_level()):
		if wi.item_id == "": continue
		var hbox := HBoxContainer.new()
		var label := Label.new()
		label.text = wi.item_id
		hbox.add_child(label)
		#
		var market_price := Label.new()
		market_price.text = "$%.1f" % Global.game_state.get_market_price(wi.item_id)
		hbox.add_child(market_price)
		#
		var price := SpinBox.new()
		price.step = 0.1
		price.prefix = "$"
		price.allow_greater = true
		price.value = Global.game_state.get_price(wi.item_id)
		price.connect("value_changed", on_price_change.bind(wi.item_id))
		hbox.add_child(price)
		#
		var box_price := Label.new()
		box_price.text = "$%.1f" % get_box_price(wi)
		hbox.add_child(box_price)
		#
		var buy_amount := SpinBox.new()
		buy_amount.value = 0
		buy_amount.rounded = true
		hbox.add_child(buy_amount)
		buying_amounts[wi.item_id] = buy_amount
		if not Global.game_state.item_enabled[wi.item_id]:
			buy_amount.editable = false
		#
		if not Global.game_state.item_enabled[wi.item_id]:
			var enable_button := Button.new()
			enable_button.text = "Enable $%.1f" % wi.enable_price
			enable_button.connect("pressed", on_enable_item.bind(wi))
			hbox.add_child(enable_button)
		#
		%OrderList.add_child(hbox)
	total_label = Label.new()
	total_label.text = "$0.0"
	%OrderList.add_child(total_label)
	buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.connect("pressed", on_buy)
	%OrderList.add_child(buy_button)
	#
	for c in %FurnitureList.get_children():
		c.queue_free()
	for wi in Items.get_available_furniture(Global.game_state.get_level()):
		if wi.item_id == "": continue
		var hbox := HBoxContainer.new()
		var label := Label.new()
		label.text = wi.item_id
		hbox.add_child(label)
		#
		var enable_button := Button.new()
		enable_button.text = "Buy $%.1f" % wi.price
		enable_button.connect("pressed", on_buy_furniture.bind(wi))
		hbox.add_child(enable_button)
		#
		%FurnitureList.add_child(hbox)
	#
	for c in %ExpansionList.get_children():
		c.queue_free()
	for wi in Items.get_available_expansions(Global.game_state.get_level()):
		var hbox := HBoxContainer.new()
		var label := Label.new()
		label.text = "%d" % wi.id
		hbox.add_child(label)
		#
		if wi.id == Global.game_state.shop_expansion + 1:
			var enable_button := Button.new()
			enable_button.text = "Buy $%.1f" % wi.price
			enable_button.connect("pressed", on_buy_expansion.bind(wi))
			hbox.add_child(enable_button)
		#
		%ExpansionList.add_child(hbox)

func _process(delta:float) -> void:
	total_label.text = "$%.1f" % get_total_amount()
	if prev_level != int(Global.game_state.get_level()):
		create_list()
		print("Create list")
		prev_level = int(Global.game_state.get_level())

func on_price_change(value:float, item_type: String) -> void:
	Global.game_state.prices[item_type] = value

func on_enable_item(item: ItemRes) -> void:
	if Global.game_state.money >= item.enable_price:
		Global.game_state.money -= item.enable_price
		item_enabled.emit(item)
		Global.game_state.item_enabled[item.item_id] = true
		create_list()

func on_buy_furniture(furniture: FurnitureRes) -> void:
	if Global.game_state.money >= furniture.price:
		Global.game_state.money -= furniture.price
		furniture_purchased.emit(furniture)
		create_list()

func on_buy_expansion(expansion: ExpansionRes) -> void:
	if Global.game_state.money >= expansion.price:
		Global.game_state.money -= expansion.price
		Global.game_state.shop_expansion = expansion.id
		create_list()

func get_total_amount() -> float:
	var total_amount := 0.0
	for ba in buying_amounts:
		var wi := Items.ITEMS[ba]
		total_amount += buying_amounts[ba].value * get_box_price(wi)
	return total_amount

func get_box_price(wi: ItemRes) -> float:
	var box_kg = wi.kg * wi.box_amount
	#prints(wi.kg, wi.box_amount)
	return Global.game_state.get_wholesale_price(wi.item_id) * box_kg

func on_buy() -> void:
	if Global.game_state.money >= get_total_amount():
		Global.game_state.money -= get_total_amount()
		var buying: Dictionary[String, int]
		for ba in buying_amounts:
			if buying_amounts[ba].value > 0:
				var wi := Items.ITEMS[ba]
				buying[ba] = int(buying_amounts[ba].value)
			Global.game_state.xp_to_add += 5.0 * buying_amounts[ba].value
			buying_amounts[ba].value = 0
		buy_completed.emit(buying)
