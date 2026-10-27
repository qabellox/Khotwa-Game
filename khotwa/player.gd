class_name Player
extends CharacterBody2D









const TARGET_HEIGHT: = 180.0


const RUNNER_TEXTURE: = "res://assets/sprite3.png"
const FRAME_W: = 352.0
const FRAME_H: = 768.0
const FRAME_COUNT: = 4
const PAIN_FPS: = 12.0


const ANIM_STEP: = 32.0




const RUNNER_FEET_Y: = [707.0, 696.0, 696.0, 705.0]
const RUNNER_CHAR_CX: = [231.0, 175.0, 175.0, 125.0]




const PAIN_TEXTURE: = "res://assets/pain.png"






const DEAD_TEXTURE: = "res://assets/dead.png"
const DEAD_FEET_Y: = [538.0, 556.0, 643.0, 615.0]
const DEAD_CHAR_CX: = [240.0, 176.0, 176.0, 111.0]



const DEAD_SCALE: = 0.7


const BOB_PERIOD: = 0.6



const LANE_X: = 960.0



@export var lane_positions: Array[float] = [290.0, 538.0, 816.0]

@export var move_speed: float = 14.0

@onready var sprite: Sprite2D = $Sprite
@onready var game_manager: GameManager = get_node("../GameManager")

var target_y: float = 0.0
var _lane_index: = 1
var _bob_time: = 0.0
var _anim_time: = 0.0
var _anim_dist: = 0.0
var _invuln_timer: = 0.0
var _dead: = false
var _feet_y: = 707.0
var _char_cx: = 176.0
var _hit_size: = Vector2(120.0, 108.0)
const HITBOX_GROUND_OFFSET: = 45.0


func _ready() -> void :
	_build_sprite()
	game_manager.game_started.connect(_on_game_started)
	game_manager.game_finished.connect(_on_game_finished)


	position = Vector2(LANE_X, lane_positions[_lane_index])
	target_y = position.y


func _physics_process(delta: float) -> void :
	if _dead:



		_update_animation()
		sprite.position = Vector2( - _char_cx * DEAD_SCALE, - _feet_y * DEAD_SCALE)
		return
	if game_manager.state != GameManager.GameState.RUNNING:
		return
	_invuln_timer = maxf(_invuln_timer - delta, 0.0)
	_bob_time += delta
	_anim_time += delta
	_anim_dist += game_manager.game_speed * delta
	_update_animation()
	_handle_input()
	_apply_lane_slide(delta)
	_check_overlaps()


func _on_game_started() -> void :
	_lane_index = 1
	target_y = lane_positions[_lane_index]
	_dead = false
	_invuln_timer = 0.0
	_anim_time = 0.0
	_anim_dist = 0.0
	_bob_time = 0.0
	var run_scale: = _run_scale()
	sprite.scale = Vector2(run_scale, run_scale)
	_feet_y = RUNNER_FEET_Y[0]
	_char_cx = RUNNER_CHAR_CX[0]
	sprite.position = Vector2( - _char_cx * run_scale, - _feet_y * run_scale)
	position = Vector2(LANE_X, lane_positions[_lane_index])


func _on_game_finished() -> void :
	_dead = true



	sprite.scale = Vector2(DEAD_SCALE, DEAD_SCALE)
	_update_animation()
	sprite.position = Vector2( - _char_cx * DEAD_SCALE, - _feet_y * DEAD_SCALE)



func get_lane_x(index: int) -> float:
	return game_manager.lane_x(index)


func get_lane_center_y(index: int) -> float:
	return game_manager.lane_center_y(index)


func get_lane_count() -> int:
	return 3


func _build_sprite() -> void :
	var tex: = load(RUNNER_TEXTURE) as Texture2D
	if tex == null:
		push_error("Runner texture missing: " + RUNNER_TEXTURE)
		return
	sprite.texture = tex
	sprite.region_enabled = true



	sprite.centered = false
	var scale_f: = _run_scale()
	sprite.scale = Vector2(scale_f, scale_f)


	_feet_y = RUNNER_FEET_Y[0]
	_char_cx = RUNNER_CHAR_CX[0]
	sprite.position = Vector2( - _char_cx * scale_f, - _feet_y * scale_f)
	_update_animation()


func _update_animation() -> void :



	if _dead:


		_apply_sheet(DEAD_TEXTURE, DEAD_FEET_Y, DEAD_CHAR_CX, 0)
		return
	if _invuln_timer > 0.0:

		var f: = int(_anim_time * PAIN_FPS) % FRAME_COUNT
		_apply_sheet(PAIN_TEXTURE, RUNNER_FEET_Y, RUNNER_CHAR_CX, f)
		return


	var f: = int(_anim_dist / ANIM_STEP) % FRAME_COUNT
	_apply_sheet(RUNNER_TEXTURE, RUNNER_FEET_Y, RUNNER_CHAR_CX, f)


func _run_scale() -> float:
	return TARGET_HEIGHT / FRAME_H


func _apply_sheet(texture_path: String, feet_arr: Array, cx_arr: Array, frame: int) -> void :
	var tex: = load(texture_path) as Texture2D
	if tex == null:
		return
	if sprite.texture != tex:
		sprite.texture = tex
	sprite.region_rect = Rect2(frame * FRAME_W, 0.0, FRAME_W, FRAME_H)
	_feet_y = feet_arr[frame]
	_char_cx = cx_arr[frame]


func _handle_input() -> void :




	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_left"):
		_lane_index = maxi(_lane_index - 1, 0)
		target_y = lane_positions[_lane_index]
	elif Input.is_action_just_pressed("duck") or Input.is_action_just_pressed("move_right"):
		_lane_index = mini(_lane_index + 1, lane_positions.size() - 1)
		target_y = lane_positions[_lane_index]





func _unhandled_input(event: InputEvent) -> void :
	if game_manager.state != GameManager.GameState.RUNNING:
		return
	var screen_y: = -1.0
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		screen_y = event.position.y
	elif event is InputEventScreenTouch and event.pressed:
		screen_y = event.position.y
	if screen_y >= 0.0:
		var best: = 0
		var best_d: = 1000000000.0
		for i in range(lane_positions.size()):
			var d: float = absf(screen_y - lane_positions[i])
			if d < best_d:
				best_d = d
				best = i
		_lane_index = best
		target_y = lane_positions[_lane_index]

func _apply_lane_slide(delta: float) -> void :



	position.y = move_toward(position.y, target_y, move_speed * 60.0 * delta)



	var bob: float = sin(_bob_time * TAU / BOB_PERIOD) * 3.0
	sprite.position.x = - _char_cx * sprite.scale.x
	sprite.position.y = - _feet_y * sprite.scale.x + bob


func _check_overlaps() -> void :
	var my_rect: = _hitbox()

	for node in get_tree().get_nodes_in_group("obstacles"):
		if my_rect.intersects(_item_rect(node)) and _invuln_timer <= 0.0:
			_invuln_timer = 0.6
			game_manager.on_obstacle_hit()
			node.queue_free()

	for node in get_tree().get_nodes_in_group("pickups"):
		if my_rect.intersects(_item_rect(node)):
			game_manager.on_pickup(node.get_meta("value", 10), node.get_meta("heal", 0))
			node.queue_free()


func _hitbox() -> Rect2:


	var center: = global_position + Vector2(0.0, - HITBOX_GROUND_OFFSET)
	return Rect2(center - _hit_size * 0.5, _hit_size)


func _item_rect(node: Node) -> Rect2:
	var item: = node as Node2D
	if item == null:
		return Rect2()
	var size: Vector2 = node.get_meta("hit_size", Vector2(100.0, 100.0))
	return Rect2(item.global_position - size * 0.5, size)
