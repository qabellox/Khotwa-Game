class_name GameManager
extends Node

## Central game progression / state manager.
##
## - Owns the explicit game state machine (MENU, RUNNING, PAUSED,
##   REVIVAL_HOTLINE, GAME_OVER).
## - Tracks Score and Health, and ramps Game Speed over time.
## - Hazards deal damage and apply mechanical friction (speed cut).
##   Healthy pickups restore score and health.
## - Emits signals so HUD components (NCS Orb, bars) can subscribe instead of
##   polling the loop.
## - Prints the run status to the console.

signal score_changed(new_score: int)
signal health_changed(new_health: int)
signal speed_changed(new_speed: float)
signal game_finished

enum GameState { MENU, RUNNING, PAUSED, REVIVAL_HOTLINE, GAME_OVER }

@export var base_speed := 400.0         # px/s obstacle fall speed.
@export var max_speed := 1200.0
@export var speed_increment := 10.0     # added every speed tick.
@export var speed_tick_interval := 2.5  # seconds between speed increases.
@export var max_health := 100
@export var hazard_damage := 25
@export var score_per_second := 1

var state := GameState.RUNNING
var score := 0
var health := max_health
var game_speed := base_speed
var game_over := false

var _score_accumulator := 0.0
var _speed_tick_accumulator := 0.0


func _ready() -> void:
	health = max_health
	score = 0
	game_speed = base_speed
	state = GameState.RUNNING
	game_over = false
	_print_status()


func _process(delta: float) -> void:
	if state != GameState.RUNNING:
		return

	# Score increases once per second.
	_score_accumulator += delta
	while _score_accumulator >= 1.0:
		_score_accumulator -= 1.0
		_add_score(score_per_second)

	# Game speed ramps up over time (capped).
	_speed_tick_accumulator += delta
	if _speed_tick_accumulator >= speed_tick_interval:
		_speed_tick_accumulator = 0.0
		game_speed = minf(game_speed + speed_increment, max_speed)
		speed_changed.emit(game_speed)


func on_pickup(value: int) -> void:
	_add_score(value)
	health = mini(health + 5, max_health)
	health_changed.emit(health)


func on_obstacle_hit() -> void:
	take_damage(hazard_damage)


func take_damage(amount: int) -> void:
	if game_over:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health)
	# Mechanical friction: a hazard cuts momentum for a moment.
	game_speed = maxf(game_speed * 0.6, base_speed * 0.6)
	_print_status()
	if health <= 0:
		_on_game_over()


func _add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)
	_print_status()


func _on_game_over() -> void:
	state = GameState.GAME_OVER
	game_over = true
	game_finished.emit()
	print("GAME OVER - final score: %d" % score)


func _print_status() -> void:
	print("Score: %d | Health: %d | Speed: %.0f px/s" % [score, health, game_speed])
