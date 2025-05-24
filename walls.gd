extends Node3D

const WALL_BLOCK = preload("res://wall_block.tscn")
const size := Vector2i(6, 4)

var active_blocks:Array
var current_expansion := -1

const expansions := [
	[Vector2i(2,2), Vector2i(3,2), Vector2i(2,3), Vector2i(3,3)],
	[Vector2i(1,3)],
	[Vector2i(1,2)],
	[Vector2i(1,1)],
	#
	[Vector2i(2,1)],
	[Vector2i(3,1)],
	[Vector2i(4,1)],
	#
	[Vector2i(4,2)],
	[Vector2i(4,3)],
	#
	[Vector2i(0,3)],
	[Vector2i(0,2)],
	[Vector2i(0,1)],
	[Vector2i(0,0)],
	#
	[Vector2i(1,0)],
	[Vector2i(2,0)],
	[Vector2i(3,0)],
	[Vector2i(4,0)],
	[Vector2i(5,0)],
	#
	[Vector2i(5,1)],
	[Vector2i(5,2)],
	[Vector2i(5,3)],
]

func _ready() -> void:
	var start := Vector2i(-3, -4)
	var block_size := 4.0
	for x in size.x:
		var blocks := []
		for y in size.y:
			var wb := WALL_BLOCK.instantiate()
			wb.position.x = (x+start.x)*block_size + block_size*0.5
			wb.position.z = (y+start.y)*block_size + block_size*0.5
			add_child(wb)
			blocks.append(wb)
		active_blocks.append(blocks)
	
	#hide_block(active_blocks[2][2])
	#hide_block(active_blocks[3][2])
	#hide_block(active_blocks[2][3])
	#hide_block(active_blocks[3][3])

func _process(delta: float) -> void:
	if current_expansion == Global.game_state.shop_expansion: return
	current_expansion = Global.game_state.shop_expansion
	#current_expansion=20
	for x in size.x:
		for y in size.y:
			show_block(active_blocks[x][y])
	for en in current_expansion+1:
		for b in expansions[en]:
			hide_block(active_blocks[b.x][b.y])

func hide_block(block: Node3D) -> void:
	block.position.y = -20

func show_block(block: Node3D) -> void:
	block.position.y = 0
