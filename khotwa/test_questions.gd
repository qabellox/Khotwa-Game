extends SceneTree






var _frames: = 0
var _main: Node
var _started: = false
var _phase: = 0


func _process(_delta: float) -> bool:
	_frames += 1
	if _main == null or not is_instance_valid(_main):
		_main = (load("res://main.tscn") as PackedScene).instantiate()
		root.add_child(_main)
	if not _started:
		_started = true
		_main.get_node("GameManager").start_game()

	var gm: Node = _main.get_node("GameManager")
	var qm: Node = _main.get_node("QuestionManager")

	if _frames == 30 and _phase == 0:
		_phase = 1
		gm.take_damage(25)
		gm.on_pickup(10, 25)
		print("FRUIT: state=", gm.state, " q_active=", gm.question_active, " health=", gm.health, " (expect RUNNING, false, 100)")
	elif _frames == 60 and _phase == 1:
		_phase = 2
		gm.take_damage(1000)
		print("DEAD: state=", gm.state)
		gm.ask_revival_question()
		print("REVIVE Q: state=", gm.state, " q_active=", gm.question_active)
		var q: Dictionary = qm.current_question()
		gm.submit_answer(int(q.correct))
		print("CORRECT revive: state=", gm.state, " health=", gm.health, " score=", gm.score, " game_over=", gm.game_over)
	elif _frames == 90 and _phase == 2:
		_phase = 3
		gm.take_damage(1000)
		gm.ask_revival_question()
		var q2: Dictionary = qm.current_question()
		gm.submit_answer((int(q2.correct) + 1) % 4)
		print("WRONG revive: state=", gm.state, " game_over=", gm.game_over, " (expect GAME_OVER)")
		quit()
		return true
	return false
