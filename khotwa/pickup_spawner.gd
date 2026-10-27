class_name PickupSpawner
extends Node2D





const PICKUPS: = [
	{"texture": "res://assets/coin.png", "region": Rect2(94.0, 27.0, 489.0, 315.0), "value": 5}, 
	{"texture": "res://assets/fruit.png", "region": Rect2(133.0, 54.0, 437.0, 265.0), "value": 10}, 
	{"texture": "res://assets/healthy.png", "region": Rect2(133.0, 54.0, 437.0, 265.0), "value": 15}, 
]
const TARGET_HEIGHT: = 130.0
const SPAWN_Y: = -250.0
const DESPAWN_Y: = 1150.0

@export var spawn_interval: = 0.9
@export var min_spawn_interval: = 0.4

var _spawn_timer: = 0.0
var _pool: Array[Dictionary] = []

@onready var game_manager: GameManager = get_node("../GameManager")
@onready var player: Player = get_node("../Player")


func _ready() -> void :
	for entry in PICKUPS:
		var tex: = load(entry.texture) as Texture2D
		if tex:
			_pool.append({"texture": tex, "region": entry.region, "value": entry.value})
	game_manager.game_started.connect(_clear_items)


func _clear_items() -> void :
	for child in get_children():
		child.queue_free()


func _process(delta: float) -> void :
	if game_manager.state != GameManager.GameState.RUNNING:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = maxf(min_spawn_interval, spawn_interval * randf_range(0.8, 1.2))
		_spawn_pickup()
	_move_items(delta)


func _spawn_pickup() -> void :
	if _pool.is_empty():
		return
	var entry: Dictionary = _pool.pick_random()
	var tex: Texture2D = entry.texture
	var region: Rect2 = entry.region
	var lane_index: = randi() % 3

	var item: = Area2D.new()
	var spr: = Sprite2D.new()
	spr.texture = tex
	spr.region_enabled = true
	spr.region_rect = region
	var scale_f: = TARGET_HEIGHT / region.size.y
	spr.scale = Vector2(scale_f, scale_f)
	item.add_child(spr)

	var hit_size: = region.size * scale_f * 0.8
	item.set_meta("hit_size", hit_size)
	item.set_meta("value", entry.value)
	item.add_to_group("pickups")
	item.position = Vector2(game_manager.lane_x(lane_index), SPAWN_Y)
	add_child(item)


func _move_items(delta: float) -> void :
	for child in get_children():
		if child is Node2D and child.is_in_group("pickups"):
			child.position.y += game_manager.game_speed * delta
			if child.position.y > DESPAWN_Y:
				child.queue_free()
