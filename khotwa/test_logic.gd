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

	var gm: Node = _main.get_node("GameManager")

	if _frames == 30:
		print("START  score=", gm.score, " health=", gm.health, " speed=", gm.game_speed)

		gm.on_pickup(5, 0)
		print("AFTER COIN(heal=0)  score=", gm.score, " health=", gm.health, " (health unchanged)")

		var sp_before: float = gm.game_speed
		gm.take_damage(25)
		print("AFTER DRUG  score=", gm.score, " health=", gm.health, " speed=", gm.game_speed, " (speed unchanged from ", sp_before, ")")

		gm.on_pickup(10, 25)
		print("AFTER FRUIT(heal=25) score=", gm.score, " health=", gm.health, " (75 + 25 = 100)")
	elif _frames == 900:

		print("LATER  speed=", gm.game_speed, " (ramped from base ", gm.base_speed, ")")
		for i in range(10):
			gm.take_damage(25)
		print("AFTER DRAIN  health=", gm.health, " state=", gm.state, " (expect GAME_OVER)")
		quit()
		return true
	return false
