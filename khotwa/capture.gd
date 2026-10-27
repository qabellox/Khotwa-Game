extends SceneTree

var _main: Node
var _frames: = 0
var _started: = false

func _process(_delta: float) -> bool:
	_frames += 1
	if _main == null or not is_instance_valid(_main):
		_main = root.get_node_or_null("Main")
		if _main == null:
			var scene: PackedScene = load("res://main.tscn")
			_main = scene.instantiate()
			root.add_child(_main)
	if not _started:
		_started = true
		var gm0: Node = _main.get_node("GameManager")
		if gm0.state == gm0.GameState.MENU:
			gm0.start_game()

	var player: Node = _main.get_node("Player")
	var gm: Node = _main.get_node("GameManager")

	if _frames == 30:
		print("lanes:", gm.lane_pos(0), gm.lane_pos(1), gm.lane_pos(2))
		print("runner:", player.position, " sprite_scale=", player.sprite.scale, " hitbox=", player._hitbox())
		root.get_viewport().get_texture().get_image().save_png("F:/Khotwa-Game/frame_capture/wide_lanes_mid.png")
	if _frames >= 100 and _frames <= 400:
		player._lane_index = 0
	if _frames == 420:
		print("forced lane0:", player.position, " target=", gm.lane_pos(0))
		var spawner: Node = _main.get_node("ItemSpawner")
		var rows: = ""
		for c in spawner.get_children():
			if c is Node2D:
				rows += " (%.0f,%.0f)" % [(c as Node2D).position.x, (c as Node2D).position.y]
		print("items:" + rows)
		root.get_viewport().get_texture().get_image().save_png("F:/Khotwa-Game/frame_capture/wide_lanes_top.png")
		quit()
		return true
	return false
