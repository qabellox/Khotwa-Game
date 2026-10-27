class_name ObstacleSpawner
extends Node2D





const OBSTACLES: = [
	{"texture": "res://assets/drug.png", "region": Rect2(196.0, 55.0, 296.0, 262.0)}, 
	{"texture": "res://assets/unhealthy.png", "region": Rect2(196.0, 55.0, 296.0, 262.0)}, 
]
const TARGET_HEIGHT: = 150.0
const SPAWN_Y: = -250.0
const DESPAWN_Y: = 1150.0

@export var spawn_interval: = 1.1
@export var min_spawn_interval: = 0.5

var _spawn_timer: = 0.0
var _pool: Array[Dictionary] = []

@onready var game_manager: GameManager = get_node("../GameManager")
@onready var player: Player = get_node("../Player")


func _ready() -> void :
	for entry in OBSTACLES:
		var tex: = load(entry.texture) as Texture2D
		if tex:
			_pool.append({"texture": tex, "region": entry.region})
	game_manager.game_started.connect(_clear_items)


func _clear_items() -> void :
	for child in get_children():
		child.queue_free()


func _process(delta: float) -> void :
	if game_manager.state != GameManager.GameState.RUNNING:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = _next_spawn_interval()
		_spawn_obstacle()
	_move_items(delta)


func _next_spawn_interval() -> float:

	var speed_ratio: float = game_manager.game_speed / game_manager.base_speed
	return maxf(min_spawn_interval, spawn_interval / speed_ratio)


func _spawn_obstacle() -> void :
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

	var hit_size: = region.size * scale_f * 0.85
	item.set_meta("hit_size", hit_size)
	item.add_to_group("obstacles")
	item.position = Vector2(game_manager.lane_x(lane_index), SPAWN_Y)
	add_child(item)


func _move_items(delta: float) -> void :
	for child in get_children():
		if child is Node2D and child.is_in_group("obstacles"):
			child.position.y += game_manager.game_speed * delta
			if child.position.y > DESPAWN_Y:
				child.queue_free()
