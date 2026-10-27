class_name GameManager
extends Node















signal score_changed(new_score: int)
signal health_changed(new_health: int)
signal speed_changed(new_speed: float)
signal coins_changed(new_coins: int)
signal game_finished
signal game_started
signal question_requested(question: Dictionary, context: int)
signal question_resolved(correct: bool)

enum GameState{MENU, RUNNING, PAUSED, REVIVAL_HOTLINE, GAME_OVER}
enum QuestionContext{REVIVE}





const LANE_X: = 960.0



const LANE_GROUND_Y: = [290.0, 538.0, 816.0]

const PLAYER_SPRITE_HALF: = 110.0

@export var base_speed: = 430.0
@export var max_speed: = 1600.0
@export var speed_increment: = 15.0
@export var speed_tick_interval: = 1.6
@export var speed_ramp_rate: = 70.0
@export var max_health: = 100
@export var hazard_damage: = 25
@export var score_per_second: = 1

var state: = GameState.MENU
var score: = 0
var coins: = 0
var health: = max_health
var game_speed: = base_speed
var _target_speed: = base_speed
var game_over: = false
var question_active: = false
var _question_context: = QuestionContext.REVIVE
var _question_manager: Node

var _score_accumulator: = 0.0
var _speed_tick_accumulator: = 0.0



var _bgm: AudioStreamPlayer
var _pain_sfx: AudioStreamPlayer
var _death_sfx: AudioStreamPlayer
var _coin_sfx: AudioStreamPlayer
var _heal_sfx: AudioStreamPlayer


func _ready() -> void :
	_setup_audio()
	_question_manager = get_node_or_null("../QuestionManager")
	_reset_run()
	state = GameState.MENU


func _process(delta: float) -> void :
	if state != GameState.RUNNING:
		return


	_score_accumulator += delta
	while _score_accumulator >= 1.0:
		_score_accumulator -= 1.0
		_add_score(score_per_second)



	_speed_tick_accumulator += delta
	if _speed_tick_accumulator >= speed_tick_interval:
		_speed_tick_accumulator = 0.0
		_target_speed = minf(_target_speed + speed_increment, max_speed)
	game_speed = move_toward(game_speed, _target_speed, speed_ramp_rate * delta)
	speed_changed.emit(game_speed)



func lane_x(_lane_index: int) -> float:
	return LANE_X



func lane_ground_y(lane_index: int) -> float:
	return LANE_GROUND_Y[clampi(lane_index, 0, 2)]




func lane_center_y(lane_index: int) -> float:
	return LANE_GROUND_Y[clampi(lane_index, 0, 2)]



func lane_item_y(lane_index: int) -> float:
	return LANE_GROUND_Y[clampi(lane_index, 0, 2)]



func lane_pos(lane_index: int) -> Vector2:
	return Vector2(lane_x(lane_index), lane_ground_y(lane_index))


func on_pickup(value: int, heal: int = 0) -> void :


	_add_score(value)
	if heal > 0:
		health = mini(health + heal, max_health)
		health_changed.emit(health)
		_play_sfx(_heal_sfx)
	else:
		coins += 1
		coins_changed.emit(coins)
		_play_sfx(_coin_sfx)


func on_obstacle_hit() -> void :
	take_damage(hazard_damage)


func take_damage(amount: int) -> void :
	if game_over:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health)

	_print_status()
	if health <= 0:
		_on_game_over()
	else:
		_play_sfx(_pain_sfx)


func _add_score(amount: int) -> void :
	score += amount
	score_changed.emit(score)
	_print_status()


func _on_game_over() -> void :
	state = GameState.GAME_OVER
	game_over = true
	game_finished.emit()
	_stop_bgm()
	_play_sfx(_death_sfx)
	print("GAME OVER - final score: %d" % score)


func pause_game() -> void :
	if state == GameState.RUNNING and not question_active:
		state = GameState.PAUSED


func resume_game() -> void :
	if state == GameState.PAUSED and not question_active:
		state = GameState.RUNNING




func ask_revival_question() -> void :
	if question_active:
		return
	_question_context = QuestionContext.REVIVE
	_begin_question()


func _begin_question() -> void :
	question_active = true
	state = GameState.PAUSED
	var q: Dictionary = {}
	if _question_manager != null:
		q = _question_manager.get_random_question()
	question_requested.emit(q, _question_context)



func submit_answer(answer_index: int) -> void :
	if not question_active:
		return
	var correct: = false
	if _question_manager != null:
		var q: Dictionary = _question_manager.current_question()
		if not q.is_empty():
			correct = (answer_index == int(q.get("correct", -1)))
	_resolve_question(correct)



func question_timed_out() -> void :
	if question_active:
		_resolve_question(false)


func _resolve_question(correct: bool) -> void :
	question_active = false
	question_resolved.emit(correct)
	if correct:
		_play_sfx(_coin_sfx)
	else:
		_play_sfx(_pain_sfx)
	if correct:

		revive_game()
	else:

		state = GameState.GAME_OVER


func start_game() -> void :
	_reset_run()
	state = GameState.RUNNING
	game_started.emit()
	_play_bgm()


func restart_game() -> void :
	_reset_run()
	state = GameState.RUNNING
	game_started.emit()
	_play_bgm()





func revive_game() -> void :
	game_over = false
	health = max_health
	health_changed.emit(health)
	_add_score(100)
	state = GameState.RUNNING
	game_started.emit()
	_play_bgm()


func _reset_run() -> void :
	score = 0
	coins = 0
	health = max_health
	game_speed = base_speed
	_target_speed = base_speed
	game_over = false
	_score_accumulator = 0.0
	_speed_tick_accumulator = 0.0
	score_changed.emit(score)
	coins_changed.emit(coins)
	health_changed.emit(health)
	speed_changed.emit(game_speed)
	_print_status()


func _setup_audio() -> void :
	_bgm = _make_player("res://assets/bgm.mp3", true)
	_pain_sfx = _make_player("res://assets/pain.mp3", false)
	_death_sfx = _make_player("res://assets/death.mp3", false)
	_coin_sfx = _make_player("res://assets/coin_collect.mp3", false)
	_heal_sfx = _make_player("res://assets/heal.mp3", false)


func _make_player(path: String, loop: bool) -> AudioStreamPlayer:
	var p: = AudioStreamPlayer.new()
	var stream: = load(path) as AudioStream
	if stream != null:
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = loop
		elif stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = loop
	p.stream = stream
	add_child(p)
	return p


func _play_bgm() -> void :
	if _bgm != null and not _bgm.playing:
		_bgm.play()


func _stop_bgm() -> void :
	if _bgm != null and _bgm.playing:
		_bgm.stop()


func _play_sfx(player: AudioStreamPlayer) -> void :
	if player == null:
		return

	player.stop()
	player.play()


func _print_status() -> void :
	print("Score: %d | Health: %d | Speed: %.0f px/s" % [score, health, game_speed])
