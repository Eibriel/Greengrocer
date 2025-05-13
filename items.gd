extends Node

var ITEMS: Dictionary[String, ItemRes]
var FURNITURE: Dictionary[String, FurnitureRes]
var EXPANSIONS: Dictionary[int, ExpansionRes]

func _ready() -> void:
	var file = FileAccess.open("res://item_table.csv", FileAccess.READ)
	file.get_csv_line() # Discard titles
	while !file.eof_reached():
		var csv_data := file.get_csv_line()
		if csv_data.size() < 6:
			break
		var new_item := ItemRes.new()
		assert(!ITEMS.has(csv_data[0]), "Item %s is duplicated" % csv_data[0])
		new_item.item_id = csv_data[0]
		new_item.available_level = int(csv_data[1])
		new_item.kg = float(fix_decimal(csv_data[2]))
		new_item.market_price_kg = float(fix_decimal(csv_data[3]))
		new_item.wholesale_price_kg = float(fix_decimal(csv_data[4]))
		new_item.box_amount = int(csv_data[5])
		new_item.enable_price = float(fix_decimal(csv_data[6]))
		ITEMS[csv_data[0]] = new_item
		# process csv data - for example just print it
		print("CSV data is %s" % ", ".join(csv_data))
	#
	var file_b = FileAccess.open("res://furniture_table.csv", FileAccess.READ)
	file_b.get_csv_line() # Discard titles
	while !file_b.eof_reached():
		var csv_data := file_b.get_csv_line()
		if csv_data.size() < 4:
			break
		var new_furniture := FurnitureRes.new()
		assert(!FURNITURE.has(csv_data[0]), "Furniture %s is duplicated" % csv_data[0])
		new_furniture.item_id = csv_data[0]
		new_furniture.available_level = int(csv_data[1])
		new_furniture.price = float(fix_decimal(csv_data[2]))
		FURNITURE[csv_data[0]] = new_furniture
		print("CSV data is %s" % ", ".join(csv_data))
	#
	var file_c = FileAccess.open("res://shop_expansions_table.csv", FileAccess.READ)
	file_c.get_csv_line() # Discard titles
	while !file_c.eof_reached():
		var csv_data := file_c.get_csv_line()
		if csv_data.size() < 3:
			break
		var new_expansion := ExpansionRes.new()
		assert(!EXPANSIONS.has(int(csv_data[0])), "Expansion %s is duplicated" % csv_data[0])
		new_expansion.id = int(csv_data[0])
		new_expansion.available_level = int(csv_data[1])
		new_expansion.price = float(csv_data[2])
		EXPANSIONS[new_expansion.id] = new_expansion
		print("CSV data is %s" % ", ".join(csv_data))
		

func get_available_items(max_level:int, include_next:=false) -> Array[ItemRes]:
	var res: Array[ItemRes]
	for r in get_available_from_dict(ITEMS, max_level, include_next):
		res.append(r)
	return res

func get_available_furniture(max_level:int, include_next:=false) -> Array[FurnitureRes]:
	var res: Array[FurnitureRes]
	for r in get_available_from_dict(FURNITURE, max_level, include_next):
		res.append(r)
	return res

func get_available_expansions(max_level:int, include_next:=false) -> Array[ExpansionRes]:
	var res: Array[ExpansionRes]
	for r in get_available_from_dict(EXPANSIONS, max_level, include_next):
		res.append(r)
	return res

func get_available_from_dict(garray:Dictionary, max_level:int, include_next:=false) -> Array:
	var available_items:Array = []
	if include_next:
		max_level += 1
	for i in garray.values():
		if i.available_level <=max_level:
			available_items.append(i)
	return available_items

func fix_decimal(data:String) -> String:
	return data.replace(",", ".")
