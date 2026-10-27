extends SceneTree




var _main: Node
var _frames: = 0
var _started: = false


func _process(_delta: float) -> bool:
	_frames += 1
	if _main == null or not is_instance_valid(_main):
		_main = (load("res://main.tscn") as PackedScene).instantiate()
		root.add_child(_main)
	if not _started:
		_started = true
		_main.get_node("GameManager").start_game()

	var gm: Node = _main.get_node("GameManager")
	var ui: Node = _main.get_node("UI")

	if _frames == 30:
		root.get_viewport().get_texture().get_image().save_png("F:/Khotwa-Game/frame_capture/ui_hud.png")

		gm.on_pickup(10, 25)
		print("question popup shown: ", ui._question_overlay.visible)
	if _frames == 60:
		root.get_viewport().get_texture().get_image().save_png("F:/Khotwa-Game/frame_capture/ui_question.png")
		print("question text: ", ui._question_label.text)
		print("timer text: ", ui._timer_label.text)
		print("answer count: ", ui._answer_buttons.size())
		quit()
		return true
	return false
