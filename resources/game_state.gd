extends Resource
class_name GameState

@export var money := 5000.0
@export var prices: Dictionary[String, float]
@export var market_prices: Dictionary[String, float]
@export var wholesale_prices: Dictionary[String, float]
@export var item_enabled: Dictionary[String, bool]

@export var day := 1 # Starts with 1
@export var time := 0.0 #60.0*12.0
@export var xp:= 0.0 #+ 4000.0
@export var xp_to_add:=0.0

@export var shop_expansion := 0

@export var days_stats: Array[DayStats]

func get_price(item_id: String) -> float:
	if not prices.has(item_id): return 0.0
	return prices[item_id]

func get_market_price(item_id: String) -> float:
	if not market_prices.has(item_id): return 0.0
	return market_prices[item_id]

func get_wholesale_price(item_id: String) -> float:
	if not wholesale_prices.has(item_id): return 0.0
	return wholesale_prices[item_id]

func set_day_stat(prop_name:String, value: Variant, add_function:=true) -> void:
	#TODO repeated code
	days_stats.resize(day)
	if days_stats[day-1] == null:
		days_stats[day-1] = DayStats.new()
	var current_day := days_stats[day-1]
	var prop_list:Array[String] = []
	for p in current_day.get_property_list():
		# Change number for actual flags
		if p.usage == 4102:
			print(p.name)
			prop_list.append(p.name)
	if typeof(current_day[prop_name]) != typeof(value):
		push_error("Types don't match")
	current_day[prop_name] += value

func get_day_stat() -> DayStats:
	#TODO repeated code
	days_stats.resize(day)
	if days_stats[day-1] == null:
		days_stats[day-1] = DayStats.new()
	return days_stats[day-1]

func get_npc_amount() -> int:
	var amount := 0
	var level := get_level()
	var ll :Dictionary[int,int]= {
		2: 2,
		5: 3,
		9: 4,
		14: 5,
		20: 6,
		27: 7,
		35: 8,
		44: 9,
		54: 10,
		65: 11,
		77: 12,
		90: 13,
		100: 14,
	}
	for l in ll:
		if l <= level:
			amount += ll[l]
			break
	var le: Dictionary[int,int]= {
		0: 1,
		2: 2,
		5: 3,
		9: 5,
		14: 6,
		20: 7,
	}
	for l in le:
		if l <= level:
			amount += le[l]
			break
	return amount

func get_level() -> float:
	return get_level_xp(xp)

func get_level_xp(xp: float) -> float:
	var levels:Array[int] = [
		0,
		250,
		460,
		690,
		940,
		1210,
		1500,
		1810,
		2140,
		2490,
		2860,
		3250,
		3660,
		4090,
		4540,
		5010,
		5500,
		6010,
		6540,
		7090,
		7660,
		8250,
		8860,
		9490,
		10140,
		10810,
		11500,
		12210,
		12940,
		13690,
		14460,
		15250,
		16060,
		16890,
		17740,
		18610,
		19500,
		20410,
		21340,
		22290,
		23260,
		24250,
		25260,
		26290,
		27340,
		28410,
		29500,
		30610,
		31740,
		32890,
		34060,
		35250,
		36460,
		37690,
		38940,
		40210,
		41500,
		42810,
		44140,
		45490,
		46860,
		48250,
		49660,
		51090,
		52540,
		54010,
		55500,
		57010,
		58540,
		60090,
		61660,
		63250,
		64860,
		66490,
		68140,
		69810,
		71500,
		73210,
		74940,
		76690
	]
	
	var level := 0.0
	for l in levels:
		if l > xp:
			break
		level += 1.0
	
	var frac_l := 0.0
	if xp < levels.back():
		var min_l := levels[level-1]
		var max_l := levels[level]
		frac_l = remap(xp, min_l, max_l, 0.0, 1.0)
	
		#prints("Min", min_l)
		#prints("Max", max_l)
		#prints("Frac", frac_l)
	
	return level + frac_l
