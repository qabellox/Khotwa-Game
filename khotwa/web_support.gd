extends Node

## Web-only support node.
##
## Two jobs, neither touches gameplay:
##  1. Diagnostics: hand the engine's real layout numbers and the UI control
##     rectangles to the HTML shell, so a broken phone can report what happened.
##  2. A start fallback: while the menu is up, a tap anywhere starts the run, so
##     the game is playable even if the on-screen START button is not visible.

var _pressed: bool = false
var _press_position: Vector2 = Vector2.ZERO
var _js_start_callback: Variant = null
var _js_ping_callback: Variant = null
var _js_action_callback: Variant = null
var _ui_healed: bool = false
var _ui_checked: bool = false
var _ui_drawn: bool = true
var _tick: float = 0.0
var _question_override: bool = false

const DESIGN_SIZE := Vector2i(1920, 1080)


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	_register_js_start()
	get_tree().root.size_changed.connect(_on_size_changed)
	_report("boot")
	_show_start_screen_html()
	for delay in [0.75, 2.5, 6.0, 12.0, 20.0]:
		await get_tree().create_timer(delay).timeout
		if delay == 2.5:
			await _verify_ui_drawn()
		_report("late")


func _process(delta: float) -> void:
	if not OS.has_feature("web"):
		return
	_tick += delta
	if _tick < 0.25:
		return
	_tick = 0.0
	_keep_ui_alive()
	if _ui_checked and not _ui_drawn:
		_push_hud()


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
	_js_ping_callback = JavaScriptBridge.create_callback(_on_js_ping)
	JavaScriptBridge.get_interface("window").__khotwaPing = _js_ping_callback
	_js_action_callback = JavaScriptBridge.create_callback(_on_js_action)
	JavaScriptBridge.get_interface("window").__khotwaAction = _js_action_callback


func _show_start_screen_html() -> void:
	if not OS.has_feature("web"):
		return
	# Ensure we're in MENU state
	var manager = _manager()
	if manager != null:
		manager.set("state", 0)
	if not _in_menu():
		return
	var js_code = "
		var existing = document.getElementById('khotwa-start-screen-html');
		if (existing) { existing.remove(); }
		var div = document.createElement('div');
		div.id = 'khotwa-start-screen-html';
		div.innerHTML = '<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>Khotwa - Break Free</title><style>* { margin: 0; padding: 0; box-sizing: border-box; }html, body { width: 100%; height: 100%; overflow: hidden; background: #0b0d12; }body { font-family: system-ui, -apple-system, \\'Segoe UI\\', Roboto, Arial, sans-serif; touch-action: none; }#start-screen { position: fixed; inset: 0; z-index: 100; display: flex; flex-direction: column; align-items: center; justify-content: center; background: linear-gradient(180deg, #ff8c42 0%, #e65c3a 30%, #ff2d6e 60%, #9b59b6 100%); }#runner { width: 200px; height: 300px; position: absolute; pointer-events: none; animation: float 3s ease-in-out infinite; mix-blend-mode: screen; }@keyframes float { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-20px); } }#start-button { position: relative; padding: 24px 48px; font-size: 32px; font-weight: 700; color: #fff; background: transparent; border: 4px solid #ffd140; border-radius: 12px; cursor: pointer; z-index: 10; transition: all 0.3s ease; animation: pulse 2s ease-in-out infinite; }@keyframes pulse { 0%, 100% { transform: scale(1); box-shadow: 0 0 20px rgba(255, 209, 64, 0.5); } 50% { transform: scale(1.08); box-shadow: 0 0 30px rgba(255, 209, 64, 0.8); } }#start-button:hover { transform: scale(1.05); }#start-hit-area { position: fixed; inset: 0; z-index: 99; cursor: pointer; }#game-canvas { position: fixed; inset: 0; z-index: 1; background: #0b0d12; }#instructions { margin-top: 32px; color: #fff; text-align: center; max-width: 80%; line-height: 1.6; }</style></head><body><div id=\"start-hit-area\"></div><div id=\"start-screen\"><img id=\"runner\" src=\"khotwa/assets/generated/sprites/runner.png\" alt=\"Khotwa runner\" style=\"width: 200px; height: auto; transform: translateX(-50%);\"><button id=\"start-button\">START GAME</button><div id=\"instructions\"><p>Dodge drugs and junk food, collect healthy items</p><p>Answer awareness questions to revive after death</p><p>Use Arrow keys or tap lanes to move</p></div></div></div><canvas id=\"game-canvas\"></canvas><script>const startScreen = document.getElementById(\"start-screen\");const startButton = document.getElementById(\"start-button\");const hitArea = document.getElementById(\"start-hit-area\");const gameCanvas = document.getElementById(\"game-canvas\");function startGame() {startScreen.style.display = \"none\";gameCanvas.style.display = \"block\";var startEvent = new CustomEvent(\"khotwa:start\", { detail: { source: \"ui\" } });document.dispatchEvent(startEvent);console.log(\"Khotwa game started from UI\");}startButton.addEventListener(\"click\", startGame);hitArea.addEventListener(\"click\", startGame);document.addEventListener(\"keydown\", (e) => {if (e.key === \"Enter\" || e.key === \" \") {e.preventDefault();startGame();}});gameCanvas.style.display = \"none\";document.addEventListener(\"DOMContentLoaded\", () => {if (window.__khotwaStart) {document.addEventListener(\"khotwa:start\", () => {console.log(\"Engine start signal received\");});} else {let lastTime = 0;function animate(time) {requestAnimationFrame(animate);const t = time / 1000;gameCanvas.style.background = `radial-gradient(circle at ${300 + 100*Math.sin(t)}px ${200 + 100*Math.cos(t)}px, #1a1d26, #0b0d12)`;}requestAnimationFrame(animate);}});</script></body></html>';var div = document.createElement('div');div.id = 'khotwa-start-screen-html';document.body.insertBefore(div, document.body.firstChild);var existingCanvas = document.getElementById('game-canvas');if (existingCanvas) {existingCanvas.style.display = 'none';}var startScreen = document.getElementById('start-screen');if (startScreen) {startScreen.style.display = 'block';}var startButton = document.getElementById('start-button');if (startButton) {startButton.focus();}var hitArea = document.getElementById('start-hit-area');if (hitArea) {hitArea.addEventListener('click', function() {var e = new CustomEvent('khotwa:start');document.dispatchEvent(e);});}var ks = document.getElementById('start-button');if (ks) {ks.addEventListener('click', function() {var e = new CustomEvent('khotwa:start');document.dispatchEvent(e);});}"
	JavaScriptBridge.eval(js_code, true)


func _on_js_action(args: Array) -> void:
	var manager: Node = _manager()
	if manager == null:
		return
	var action: String = str(args[0]) if args.size() > 0 else ""
	match action:
		"start":
			manager.call("start_game")
		"pause":
			manager.call("pause_game")
		"resume":
			manager.call("resume_game")
		"revive":
			manager.call("ask_revival_question")
		"restart":
			manager.call("restart_game")
		"answer":
			manager.call("submit_answer", int(args[1]) if args.size() > 1 else 0)


func _on_js_ping(_args: Array) -> void:
	_report("ping")


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


## The HUD is built and refreshed by ui.gd. On some phones that script's own
## loop or signal wiring stops early: the world and the game logic keep running,
## but the score bar, the health bar, the pause button and the game-over /
## revive question never appear. This does not change gameplay; it only makes
## sure the UI layer is on screen, wired to the game manager and refreshed.
func _keep_ui_alive() -> void:
	var root: Window = get_tree().root
	if root.content_scale_size != DESIGN_SIZE:
		root.content_scale_size = DESIGN_SIZE
		_ui_healed = true
	if root.content_scale_mode != Window.CONTENT_SCALE_MODE_CANVAS_ITEMS:
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		_ui_healed = true
	if root.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_KEEP:
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		_ui_healed = true

	var manager: Node = _manager()
	var ui: Node = _ui_node()
	if ui == null:
		return

	if ui is CanvasLayer:
		var layer: CanvasLayer = ui as CanvasLayer
		if not layer.visible:
			layer.visible = true
			_ui_healed = true
		if layer.layer < 100:
			layer.layer = 100
			_ui_healed = true
		if layer.offset != Vector2.ZERO:
			layer.offset = Vector2.ZERO
			_ui_healed = true
		if layer.transform != Transform2D.IDENTITY:
			layer.transform = Transform2D.IDENTITY
			_ui_healed = true
		if layer.follow_viewport_enabled:
			layer.follow_viewport_enabled = false
			_ui_healed = true

	# Only when the UI script never finished building are the controls missing
	# entirely. Rebuild once in that case.
	if ui.get("_score_panel") == null and ui.get_script() != null:
		ui.call("_ready")
		_ui_healed = true

	if manager == null:
		return
	if ui.get("game_manager") == null:
		ui.set("game_manager", manager)
		_ui_healed = true

	# Re-wire the state signals if the UI stopped before connecting them.
	_connect_once(manager, "score_changed", "_on_score_changed")
	_connect_once(manager, "health_changed", "_on_health_changed")
	_connect_once(manager, "coins_changed", "_on_coins_changed")
	_connect_once(manager, "question_requested", "_on_question_requested")
	_connect_once(manager, "question_resolved", "_on_question_resolved")

	if ui.get("_score_panel") == null or ui.get("_question_overlay") == null \
			or not ui.has_method("_refresh"):
		return

	# Drive the panels ourselves so they appear even if the UI's own _process
	# stopped. Skipped while a question is up, exactly like ui.gd does, so it
	# can never hide the question.
	if not bool(manager.get("question_active")):
		ui.call("_refresh")
		_question_override = false
		return

	# A question that was already waiting before the wiring was repaired would
	# otherwise stay invisible. Show it once.
	if _question_override:
		return
	var overlay: Control = ui.get("_question_overlay")
	if overlay != null and not overlay.visible and ui.has_method("_on_question_requested"):
		var questions: Node = manager.get("_question_manager")
		if questions != null and questions.has_method("current_question"):
			ui.call("_on_question_requested", questions.call("current_question"), int(manager.get("_question_context")))
			_question_override = true
			_ui_healed = true


func _connect_once(manager: Node, signal_name: String, method_name: String) -> void:
	var ui: Node = _ui_node()
	if ui == null or not ui.has_method(method_name):
		return
	var callback: Callable = Callable(ui, method_name)
	if manager.is_connected(signal_name, callback):
		return
	manager.connect(signal_name, callback)
	_ui_healed = true


## Decides whether the game's own UI really reaches the screen. Two frames are
## grabbed with the whole tree paused: one with the UI layer visible and one with
## it hidden. If the frames are pixel-identical the layer draws nothing, which is
## exactly what the failing phones show, and the HTML HUD takes over.
func _verify_ui_drawn() -> void:
	if _ui_checked:
		return
	var ui: Node = _ui_node()
	if ui == null or not (ui is CanvasLayer):
		return
	_ui_checked = true
	var diff: float = await _ui_visibility_diff(ui)
	if diff < 0.0:
		_ui_drawn = true
		return
	_ui_drawn = diff > 0.0005
	if not _ui_drawn:
		_ui_healed = true


func _ui_visibility_diff(hider: Node) -> float:
	get_tree().paused = true
	await _wait_frames(4)
	var shown: Image = await _snapshot()
	hider.visible = false
	await _wait_frames(6)
	var hidden: Image = await _snapshot()
	hider.visible = true
	get_tree().paused = false
	return _difference(shown, hidden)


func _wait_frames(count: int) -> void:
	for i in range(count):
		await RenderingServer.frame_post_draw


func _snapshot() -> Image:
	var image: Image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return null
	image.resize(96, 54, Image.INTERPOLATE_BILINEAR)
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image


func _difference(a: Image, b: Image) -> float:
	if a == null or b == null or a.get_size() != b.get_size():
		return -1.0
	var total: float = 0.0
	var brightness: float = 0.0
	for y in range(a.get_height()):
		for x in range(a.get_width()):
			var ca: Color = a.get_pixel(x, y)
			var cb: Color = b.get_pixel(x, y)
			total += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			brightness += (ca.r + ca.g + ca.b) / 3.0
	var count: float = float(a.get_width() * a.get_height())
	if brightness / count < 0.02:
		# A black frame only means the readback failed, not that the UI is gone.
		return -2.0
	return total / (count * 3.0)


## Sends the real game state to the HTML HUD. Only used when the engine's own
## UI cannot reach the screen.
func _push_hud() -> void:
	if not ClassDB.class_exists("JavaScriptBridge"):
		return
	var manager: Node = _manager()
	if manager == null:
		return
	var ui: Node = _ui_node()
	var data: Dictionary = {
		"state": int(manager.get("state")),
		"score": int(manager.get("score")),
		"coins": int(manager.get("coins")),
		"health": int(manager.get("health")),
		"max_health": int(manager.get("max_health")),
		"question": bool(manager.get("question_active")),
		"question_text": "",
		"options": [],
		"time": 0,
	}
	if data["question"] and ui != null:
		var questions: Node = manager.get("_question_manager")
		if questions != null and questions.has_method("current_question"):
			var question: Dictionary = questions.call("current_question")
			data["question_text"] = str(question.get("q", ""))
			data["options"] = question.get("options", [])
		data["time"] = ceili(float(ui.get("_question_time_left")))
	var payload: String = JSON.stringify(data)
	JavaScriptBridge.eval("window.__khotwaHud && window.__khotwaHud(JSON.parse(%s));" % JSON.stringify(payload), true)


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
		"ui_healed": _ui_healed,
		"ui_drawn": _ui_drawn,
		"game_state": _game_state(scene),
		"fps": Engine.get_frames_per_second(),
		"player": _player_info(scene),
		"start": _control_info(_find_button(ui, "START")),
		"pause": _control_info(_find_button(ui, "II")),
		"score_panel": _control_info(ui.get("_score_panel") if ui != null else null),
		"health": _control_info(ui.get("_health_fill") if ui != null else null),
		"game_over": _control_info(ui.get("_game_over_overlay") if ui != null else null),
		"revive": _control_info(ui.get("_revive_button") if ui != null else null),
	}
	var payload: String = JSON.stringify(data)
	var quoted: String = JSON.stringify(payload)
	JavaScriptBridge.eval("window.__khotwaProbe && window.__khotwaProbe(JSON.parse(%s));" % quoted, true)


func _game_state(scene: Node) -> Variant:
	if scene == null:
		return null
	var manager: Node = scene.get_node_or_null("GameManager")
	if manager == null:
		return null
	return manager.get("state")


func _player_info(scene: Node) -> Variant:
	if scene == null:
		return null
	var player: Node = scene.get_node_or_null("Player")
	if player == null:
		return null
	var pos: Vector2 = player.get("position")
	return {
		"y": pos.y,
		"target": player.get("target_y"),
		"lane": player.get("_lane_index"),
	}


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
