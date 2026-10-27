extends SceneTree





var _main: Node
var _frames: = 0
var _started: = false


func _process(_delta: float) -> bool:
	_frames += 1
	if _main == null or not is_instance_valid(_main):
		_main = root.get_node_or_null("Main")
		if _main == null:
			_main = (load("res://main.tscn") as PackedScene).instantiate()
			root.add_child(_main)
	if not _started:
		_started = true
		(_main.get_node("GameManager") as Node).start_game()

	var player: Node = _main.get_node("Player")
	var gm: Node = _main.get_node("GameManager")

	if _frames == 30:
		print("START  lane=", player._lane_index, " pos=", player.position, " lanes=", gm.lane_ground_y(0), ",", gm.lane_ground_y(1), ",", gm.lane_ground_y(2))
		Input.action_press("duck")
		Input.action_release("duck")
	elif _frames == 130:
		print("AFTER DOWN  lane=", player._lane_index, " pos=", player.position, " (expect lane 2, y=816)")
		Input.action_press("jump")
		Input.action_release("jump")
	elif _frames == 230:
		print("AFTER UP    lane=", player._lane_index, " pos=", player.position, " (expect lane 1, y=538)")
		Input.action_press("jump")
		Input.action_release("jump")
	elif _frames == 330:
		print("AFTER UP2   lane=", player._lane_index, " pos=", player.position, " (expect lane 0, y=290)")

		var ev: = InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		ev.position = Vector2(960.0, 816.0)
		player._unhandled_input(ev)
	elif _frames == 430:
		print("AFTER CLICK bottom  lane=", player._lane_index, " pos=", player.position, " (expect lane 2, y=816)")

		var ev: = InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		ev.position = Vector2(960.0, 290.0)
		player._unhandled_input(ev)
	elif _frames == 530:
		print("AFTER CLICK top     lane=", player._lane_index, " pos=", player.position, " (expect lane 0, y=290)")
		var spawner: Node = _main.get_node("ItemSpawner")
		var n: = 0
		var rows: = ""
		for c in spawner.get_children():
			if c is Node2D:
				n += 1
				rows += " y=%d" % int((c as Node2D).position.y)
		print("ITEM count=", n, rows, " (should be on track rows 290/538/816)")
		print("lane_item_y=", gm.lane_item_y(0), ",", gm.lane_item_y(1), ",", gm.lane_item_y(2))

		player._lane_index = 1
		player.target_y = player.lane_positions[1]
	elif _frames == 700:

		player.position = Vector2(960.0, 290.0)
		player.target_y = 538.0
		for i in range(60):
			player._apply_lane_slide(1.0 / 60.0)
		print("GLIDE to lane1 pos=", player.position, " (expect ~(960,538))")

		var hp0: int = gm.health
		player.position = Vector2(960.0, gm.lane_item_y(1))
		player._invuln_timer = 0.0
		var hazard: = Area2D.new()
		hazard.add_to_group("obstacles")
		hazard.position = Vector2(960.0, gm.lane_item_y(1))
		hazard.set_meta("hit_size", Vector2(120.0, 90.0))
		_main.add_child(hazard)
		player._check_overlaps()
		print("COLLISION hp ", hp0, " -> ", gm.health, " (expect drop by hazard_damage)")
		quit()
		return true
	return false
