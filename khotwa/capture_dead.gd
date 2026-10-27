extends SceneTree




var _main: Node
var _frames: = 0
var _started: = false
var _died: = false


func _process(_delta: float) -> bool:
	_frames += 1
	if _main == null or not is_instance_valid(_main):
		_main = (load("res://main.tscn") as PackedScene).instantiate()
		root.add_child(_main)
	if not _started:
		_started = true
		_main.get_node("GameManager").start_game()

		var gm0: Node = _main.get_node("GameManager")
		gm0.game_speed = 0.0
		gm0._target_speed = 0.0

		_main.get_node("Player").set_physics_process(false)
		_main.get_node("Player").set_process(false)

		var spawner: Node = _main.get_node("ItemSpawner")
		spawner.set_process(false)
		for c in spawner.get_children():
			c.queue_free()

		_main.get_node("UI").visible = false

	var player: Node = _main.get_node("Player")
	var gm: Node = _main.get_node("GameManager")

	if _frames == 25:
		player._lane_index = 0
		player.target_y = 290.0
		player.position = Vector2(960.0, 290.0)
		player.visible = false
		root.get_viewport().get_texture().get_image().save_png("F:/Khotwa-Game/frame_capture/bg_top.png")
	if _frames == 30:
		player.visible = true
		player.position = Vector2(960.0, 290.0)
		print("LIVE player pos=", player.position)
		root.get_viewport().get_texture().get_image().save_png("F:/Khotwa-Game/frame_capture/live_top.png")
	if _frames == 40 and not _died:
		_died = true
		gm.take_damage(1000)
	if _frames == 70:
		player.position = Vector2(960.0, 290.0)
		print("player pos=", player.position)
		print("sprite pos=", player.sprite.position, " scale=", player.sprite.scale)
		print("region=", player.sprite.region_rect, " tex=", player.sprite.texture.resource_path)
		root.get_viewport().get_texture().get_image().save_png("F:/Khotwa-Game/frame_capture/dead_top.png")
		quit()
		return true
	return false
