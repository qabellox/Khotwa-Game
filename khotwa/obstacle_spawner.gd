class_name ObstacleSpawner
extends Node2D

## Spawns hazard sprites (drug / cigarette etc.) in random lanes and moves
## them downward at the GameManager's speed. Hitboxes are stored as metadata;
## the Player detects overlaps through the "obstacles" group.

const OBSTACLE_TEXTURES := [
	"res://assets/drug.png",
	"res://assets/unhealthy.png",
]
const TARGET_WIDTH := 130.0
const SPAWN_Y := -250.0     # Above the visible viewport top.
const DESPAWN_Y := 2100.0   # Below the visible viewport bottom.

@export var spawn_interval := 1.1
@export var min_spawn_interval := 0.5

var _spawn_timer := 0.0
var _textures: Array[Texture2D] = []

@onready var game_manager: GameManager = get_node("../GameManager")
@onready var player: Player = get_node("../Player")


func _ready() -> void:
	for path in OBSTACLE_TEXTURES:
		var tex := load(path) as Texture2D
		if tex:
			_textures.append(tex)
	if _textures.is_empty():
		push_error("Obstacle textures missing.")


func _process(delta: float) -> void:
	if game_manager.game_over:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = _next_spawn_interval()
		_spawn_obstacle()
	_move_items(delta)


func _next_spawn_interval() -> float:
	# Difficulty scales with game speed: faster game -> faster spawns.
	var speed_ratio: float = game_manager.game_speed / game_manager.base_speed
	return maxf(min_spawn_interval, spawn_interval / speed_ratio)


func _spawn_obstacle() -> void:
	if _textures.is_empty():
		return
	var tex: Texture2D = _textures.pick_random()
	var lane_index := randi() % player.get_lane_count()

	var item := Area2D.new()
	var spr := Sprite2D.new()
	spr.texture = tex
	var scale_f := TARGET_WIDTH / tex.get_size().x
	spr.scale = Vector2(scale_f, scale_f)
	item.add_child(spr)

	var hit_size := Vector2(tex.get_size()) * scale_f * 0.9
	item.set_meta("hit_size", hit_size)
	item.add_to_group("obstacles")
	item.position = Vector2(player.get_lane_x(lane_index), SPAWN_Y)
	add_child(item)


func _move_items(delta: float) -> void:
	for child in get_children():
		if child is Node2D and child.is_in_group("obstacles"):
			child.position.y += game_manager.game_speed * delta
			if child.position.y > DESPAWN_Y:
				child.queue_free()
