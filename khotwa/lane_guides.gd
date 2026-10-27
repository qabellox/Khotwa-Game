class_name LaneGuides
extends Node2D





@onready var game_manager: GameManager = get_node("../GameManager")
@onready var player: Player = get_node("../Player")


func _process(_delta: float) -> void :
	queue_redraw()


func _draw() -> void :
	if game_manager == null or player == null:
		return


	for i in range(3):
		var gy: float = game_manager.lane_ground_y(i)
		var on: bool = i == player._lane_index
		var color: = Color(1.0, 0.85, 0.3, 0.95) if on else Color(1.0, 0.85, 0.3, 0.35)
		var strip_h: = 18.0 if on else 10.0


		draw_rect(Rect2(Vector2(780.0, gy + 6.0), Vector2(360.0, strip_h)), color)
