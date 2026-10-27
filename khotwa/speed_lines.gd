class_name SpeedLines
extends Node2D





const LINE_COUNT: = 20
const VIEW_W: = 1920.0
const SPAWN_W: = VIEW_W + 800.0

@onready var game_manager: GameManager = get_node("../GameManager")

var _xs: Array[float] = []
var _ys: Array[float] = []


func _ready() -> void :
	for i in range(LINE_COUNT):
		_xs.append(randf() * SPAWN_W - 400.0)
		_ys.append(60.0 + randf() * 760.0)


func _process(delta: float) -> void :
	if game_manager.state != GameManager.GameState.RUNNING:
		return
	var speed: float = game_manager.game_speed
	for i in range(LINE_COUNT):
		_xs[i] -= speed * 1.6 * delta
		if _xs[i] < -400.0:
			_xs[i] += SPAWN_W
	queue_redraw()


func _draw() -> void :
	var speed: float = game_manager.game_speed
	var line_len: = clampf(24.0 + speed * 0.04, 24.0, 96.0)
	var alpha: = clampf(0.1 + speed / 2600.0, 0.1, 0.3)
	var width: = clampf(1.0 + speed / 900.0, 1.0, 2.5)
	for i in range(LINE_COUNT):
		var y: float = _ys[i]
		draw_line(Vector2(_xs[i], y), Vector2(_xs[i] + line_len, y), Color(1.0, 1.0, 1.0, alpha), width)
