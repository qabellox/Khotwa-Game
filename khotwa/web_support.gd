extends Node

## Web-only support node.
##
## Two jobs, neither touches gameplay:
##  1. Diagnostics: hand the engine's real layout numbers and the UI control
##     rectangles to the HTML shell, so a broken phone can report what happened.
##  2. A start fallback: while the menu is up, a tap anywhere starts the run, so
##     the game is playable even if the on-screen START button is not visible.

var _pixel_checks: int = 0
var _pressed: bool = false
var _press_position: Vector2 = Vector2.ZERO
var _js_start_callback: Variant = null


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	_register_js_start()
	get_tree().root.size_changed.connect(_on_size_changed)
	_report("boot")
	for delay in [0.75, 2.5, 6.0, 12.0, 20.0]:
		await get_tree().create_timer(delay).timeout
		_report("late")


func _manager() -> Node:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("GameManager")


func _in_menu() -> bool:
	var manager: Node = _manager()
	return manager != null and int(manager.get("state")) == 0


func _start_game() -> void:
	if not _in_menu():
		return
	var manager: Node = _manager()
	if manager != null:
		manager.call("start_game")


func _register_js_start() -> void:
	if not ClassDB.class_exists("JavaScriptBridge"):
		return
	_js_start_callback = JavaScriptBridge.create_callback(_on_js_start)
	JavaScriptBridge.get_interface("window").__khotwaStart = _js_start_callback


func _on_js_start(_args: Array) -> void:
	_start_game()


func _input(event: InputEvent) -> void:
	if not OS.has_feature("web"):
		return
	if not _in_menu():
		_pressed = false
		return
	if event is InputEventKey:
		if event.pressed and not event.echo and _is_start_key(event):
			_start_game()
		return
	if event is InputEventScreenTouch:
		_handle_tap(event.pressed, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.pressed, event.position)


func _is_start_key(event: InputEventKey) -> bool:
	return event.keycode == KEY_TAB or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER \
		or event.keycode == KEY_SPACE


func _handle_tap(pressed: bool, position: Vector2) -> void:
	if pressed:
		_pressed = true
		_press_position = position
		return
	if not _pressed:
		return
	_pressed = false
	if position.distance_to(_press_position) >= 48.0:
		return
	# A tap on the real button is handled by the button itself; starting here as
	# well would reset the run twice.
	var button: Button = _find_button(_ui_node(), "START")
	if button != null and button.get_global_rect().has_point(position):
		return
	_start_game()


func _ui_node() -> Node:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("UI")


func _on_size_changed() -> void:
	_report("resize")


func _report(stage: String) -> void:
	if not OS.has_feature("web"):
		return
	if not ClassDB.class_exists("JavaScriptBridge"):
		return
	var root: Window = get_tree().root
	var scene: Node = get_tree().current_scene
	var ui: Node = scene.get_node_or_null("UI") if scene != null else null
	var data: Dictionary = {
		"stage": stage,
		"window": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"screen": [DisplayServer.screen_get_size().x, DisplayServer.screen_get_size().y],
		"viewport": [root.size.x, root.size.y],
		"content_scale": [root.content_scale_size.x, root.content_scale_size.y],
		"content_scale_mode": root.content_scale_mode,
		"content_scale_aspect": root.content_scale_aspect,
		"content_scale_factor": root.content_scale_factor,
		"adapter": RenderingServer.get_video_adapter_name(),
		"vendor": RenderingServer.get_video_adapter_vendor(),
		"method": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name(),
		"ui_present": ui != null,
		"ui_children": ui.get_child_count() if ui != null else 0,
		"game_state": _game_state(scene),
		"start": _control_info(_find_button(ui, "START")),
		"pause": _control_info(_find_button(ui, "II")),
	}
	if stage == "late" and _pixel_checks < 1:
		_pixel_checks += 1
		data["start_pixels"] = _count_start_pixels()
	var payload: String = JSON.stringify(data)
	var quoted: String = JSON.stringify(payload)
	JavaScriptBridge.eval("window.__khotwaProbe && window.__khotwaProbe(JSON.parse(%s));" % quoted, true)


## Counts pixels that match the START button green in the frame the engine
## actually rendered. If the control exists but this is zero, the UI is not
## reaching the screen.
func _count_start_pixels() -> int:
	var image: Image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return -1
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var width: int = image.get_width()
	var height: int = image.get_height()
	if width <= 0 or height <= 0:
		return -1
	var step: int = maxi(1, int(width / 320.0))
	var count: int = 0
	for y in range(0, height, step):
		for x in range(0, width, step):
			var color: Color = image.get_pixel(x, y)
			if color.g > 0.55 and color.r < 0.45 and color.b > 0.22 and color.b < 0.65 and (color.g - color.r) > 0.25:
				count += 1
	return count


func _game_state(scene: Node) -> Variant:
	if scene == null:
		return null
	var manager: Node = scene.get_node_or_null("GameManager")
	if manager == null:
		return null
	return manager.get("state")


func _find_button(node: Node, label: String) -> Button:
	if node == null:
		return null
	if node is Button and (node as Button).text == label:
		return node as Button
	for child in node.get_children():
		var found: Button = _find_button(child, label)
		if found != null:
			return found
	return null


func _control_info(control: Control) -> Variant:
	if control == null:
		return null
	var rect: Rect2 = control.get_global_rect()
	return {
		"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"visible": control.is_visible_in_tree(),
	}
