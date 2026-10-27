class_name PickupSpawner
extends Node2D

## Spawns healthy pickups (fruit / healthy / coin) in random lanes. Collecting
## them boosts score and restores health. Collision runs through the
## "pickups" group.

const PICKUPS := [
	{"texture": "res://assets/fruit.png", "value": 10},
	{"texture": "res://assets/healthy.png", "value": 15},
	{"texture": "res://assets/coin.png", "value": 5},
]
const TARGET_WIDTH := 90.0
const SPAWN_Y := -250.0     # Above the visible viewport top.
const DESPAWN_Y := 2100.0   # Below the visible viewport bottom.

@export var spawn_interval := 0.9
@export var min_spawn_interval := 0.4

var _spawn_timer := 0.0
var _pool: Array[Dictionary] = []

@onready var game_manager: GameManager = get_node("../GameManager")
@onready var player: Player = get_node("../Player")


func _ready() -> void:
	for entry in PICKUPS:
		var tex := load(entry.texture) as Texture2D
		if tex:
			_pool.append({"texture": tex, "value": entry.value})


func _process(delta: float) -> void:
	if game_manager.game_over:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = maxf(min_spawn_interval, spawn_interval * randf_range(0.8, 1.2))
		_spawn_pickup()
	_move_items(delta)


func _spawn_pickup() -> void:
	if _pool.is_empty():
		return
	var entry: Dictionary = _pool.pick_random()
	var tex: Texture2D = entry.texture
	var lane_index := randi() % player.get_lane_count()

	var item := Area2D.new()
	var spr := Sprite2D.new()
	spr.texture = tex
	var scale_f := TARGET_WIDTH / tex.get_size().x
	spr.scale = Vector2(scale_f, scale_f)
	item.add_child(spr)

	var hit_size := Vector2(tex.get_size()) * scale_f * 0.8
	item.set_meta("hit_size", hit_size)
	item.set_meta("value", entry.value)
	item.add_to_group("pickups")
	item.position = Vector2(player.get_lane_x(lane_index), SPAWN_Y)
	add_child(item)


func _move_items(delta: float) -> void:
	for child in get_children():
		if child is Node2D and child.is_in_group("pickups"):
			child.position.y += game_manager.game_speed * delta
			if child.position.y > DESPAWN_Y:
				child.queue_free()