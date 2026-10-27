class_name Player
extends CharacterBody2D

## 3-lane runner controller using the real character sprites.
##
## - Smooth lerp lane switching (Left/Right or A/D).
## - Jump (Up/W) and Duck (Down/S) with gravity math on the sprite.
## - Plays the runner1/runner2 run animation.
## - Detects overlaps with hazards and pickups via manual AABB. It only knows
##   the "obstacles" and "pickups" groups, so it stays decoupled from the
##   spawner nodes.

const LANE_CENTER_X := 540.0
const LANE_OFFSET := 250.0
const LANE_X := [LANE_CENTER_X - LANE_OFFSET, LANE_CENTER_X, LANE_CENTER_X + LANE_OFFSET]
const GROUND_Y := 1400.0
const TARGET_HEIGHT := 240.0   # On-screen sprite height in pixels.

const RUNNER_1 := "res://assets/runner1.png"
const RUNNER_2 := "res://assets/runner2.png"

@export var lane_lerp_weight := 12.0
@export var gravity := 4600.0
@export var jump_velocity := -1650.0
@export var duck_scale_y := 0.5
@export var hitbox_shrink := 0.7

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var game_manager: GameManager = get_node("../GameManager")

var _lane_index := 1
var _grounded := true
var _ducking := false
var _vertical_velocity := 0.0
var _jump_offset := 0.0
var _hit_size := Vector2(120.0, 200.0)
var _invuln_timer := 0.0


func _ready() -> void:
	_build_animation()
	position = Vector2(LANE_X[_lane_index], GROUND_Y)


func _physics_process(delta: float) -> void:
	if game_manager.game_over:
		return
	_invuln_timer = maxf(_invuln_timer - delta, 0.0)
	_handle_input()
	_apply_lane_slide(delta)
	_apply_jump(delta)
	_apply_duck(delta)
	_check_overlaps()


## Public lane API: single source of truth for the spawner nodes.
func get_lane_x(index: int) -> float:
	return LANE_X[clampi(index, 0, LANE_X.size() - 1)]


func get_lane_count() -> int:
	return LANE_X.size()


func _build_animation() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("run")
	frames.set_animation_speed("run", 12.0)
	var f1 := load(RUNNER_1) as Texture2D
	var f2 := load(RUNNER_2) as Texture2D
	if f1:
		frames.add_frame("run", f1)
	if f2:
		frames.add_frame("run", f2)
	if frames.get_frame_count("run") == 0:
		push_error("Runner textures missing: %s / %s" % [RUNNER_1, RUNNER_2])
		return
	sprite.frames = frames
	sprite.play("run")

	var base_tex: Texture2D = frames.get_frame_texture("run", 0)
	var scale_f := TARGET_HEIGHT / base_tex.get_size().y
	sprite.scale = Vector2(scale_f, scale_f)
	sprite.position = Vector2.ZERO
	_hit_size = Vector2(base_tex.get_size()) * scale_f * hitbox_shrink


func _handle_input() -> void:
	if Input.is_action_just_pressed("move_left"):
		_lane_index = clampi(_lane_index - 1, 0, LANE_X.size() - 1)
	elif Input.is_action_just_pressed("move_right"):
		_lane_index = clampi(_lane_index + 1, 0, LANE_X.size() - 1)

	if Input.is_action_just_pressed("jump") and _grounded:
		_vertical_velocity = jump_velocity
		_grounded = false

	_ducking = Input.is_action_pressed("duck")


func _apply_lane_slide(delta: float) -> void:
	position.x = lerpf(position.x, LANE_X[_lane_index], 1.0 - exp(-lane_lerp_weight * delta))


func _apply_jump(delta: float) -> void:
	if _grounded:
		return
	_jump_offset += _vertical_velocity * delta
	_vertical_velocity += gravity * delta
	if _jump_offset >= 0.0:
		_jump_offset = 0.0
		_vertical_velocity = 0.0
		_grounded = true


func _apply_duck(delta: float) -> void:
	var ducking := _ducking and _grounded
	var target_scale_y: float = sprite.scale.x * (duck_scale_y if ducking else 1.0)
	sprite.scale.y = lerpf(sprite.scale.y, target_scale_y, 1.0 - exp(-20.0 * delta))
	var duck_drop: float = _hit_size.y * (1.0 - duck_scale_y) * 0.5 if ducking else 0.0
	sprite.position.y = -_jump_offset + duck_drop


func _check_overlaps() -> void:
	var my_rect := _hitbox()

	for node in get_tree().get_nodes_in_group("obstacles"):
		if my_rect.intersects(_item_rect(node)) and _invuln_timer <= 0.0:
			_invuln_timer = 0.6
			game_manager.on_obstacle_hit()
			node.queue_free()

	for node in get_tree().get_nodes_in_group("pickups"):
		if my_rect.intersects(_item_rect(node)):
			game_manager.on_pickup(node.get_meta("value", 10))
			node.queue_free()


func _hitbox() -> Rect2:
	# Follows the sprite: jump lifts it, duck shrinks its height.
	var h := _hit_size.y * (sprite.scale.y / sprite.scale.x)
	var center := global_position + sprite.position
	return Rect2(center - Vector2(_hit_size.x, h) * 0.5, Vector2(_hit_size.x, h))


func _item_rect(node: Node) -> Rect2:
	var item := node as Node2D
	if item == null:
		return Rect2()
	var size: Vector2 = node.get_meta("hit_size", Vector2(100.0, 100.0))
	return Rect2(item.global_position - size * 0.5, size)
