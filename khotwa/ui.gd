class_name UI
extends CanvasLayer










const VIEW_W: = 1920.0
const VIEW_H: = 1080.0
const QUESTION_TIME: = 15.0

const ARIAL: = "res://assets/fonts/arial.ttf"
const ARIAL_BOLD: = "res://assets/fonts/arial_bold.ttf"
const TAHOMA: = "res://assets/fonts/tahoma.ttf"

var _ui_font: Font
var _ui_bold: Font
var _arabic: Font

var _start_button: Button
var _score_panel: Panel
var _score_label: Label
var _coin_label: Label
var _health_fill: ColorRect
var _health_fill_max: = 320.0
var _pause_button: Button

var _pause_overlay: ColorRect
var _resume_button: Button

var _game_over_overlay: ColorRect
var _game_over_title: Label
var _final_score_label: Label
var _revive_button: Button
var _restart_button: Button

var _question_overlay: ColorRect
var _question_title: Label
var _question_label: Label
var _timer_label: Label
var _answer_buttons: Array[Button] = []
var _flash: ColorRect

var _question_time_left: = 0.0
var _flash_tween: Tween

// Start screen assets (loaded in _load_assets)
var _start_bg_texture: Texture2D
var _runner_texture: Texture2D
var _start_btn_texture: Texture2D

// Start screen nodes
var _start_bg: Sprite2D
var _runner_sprite: Sprite2D
var _start_btn_sprite: Sprite2D
var _start_btn_hit_area: Area2D

@onready var game_manager: GameManager = get_node("../GameManager")


func _ready() -> void :
	_load_assets()
	_build_hud()
	_build_pause_overlay()
	_build_game_over()
	_build_question_popup()
	_build_flash()
	_build_start_screen()
	game_manager.score_changed.connect(_on_score_changed)
	game_manager.health_changed.connect(_on_health_changed)
	game_manager.coins_changed.connect(_on_coins_changed)
	game_manager.question_requested.connect(_on_question_requested)
	game_manager.question_resolved.connect(_on_question_resolved)
	_refresh()


func _load_assets() -> void :
	_ui_font = load(ARIAL) as Font
	_ui_bold = load(ARIAL_BOLD) as Font
	_arabic = load(TAHOMA) as Font
	
	_start_bg_texture = load("res://assets/generated/backgrounds/start-background.jpg") as Texture2D
	_runner_texture = load("res://assets/generated/sprites/runner-float.jpg") as Texture2D
	_start_btn_texture = load("res://assets/generated/ui/start-button.jpg") as Texture2D


func _process(delta: float) -> void :
	if game_manager.question_active:

		_question_time_left -= delta
		_timer_label.text = "TIME: %d" % ceili(_question_time_left)
		if _question_time_left <= 0.0:
			game_manager.question_timed_out()
		return
	_refresh()


func _refresh() -> void :
	match game_manager.state:
		GameManager.GameState.MENU:
			_start_bg.visible = true
			_runner_sprite.visible = true
			_start_btn_sprite.visible = true
			_start_btn_hit_area.visible = true
			_score_panel.visible = false
			_pause_button.visible = false
			_pause_overlay.visible = false
			_game_over_overlay.visible = false
		GameManager.GameState.RUNNING:
			_start_bg.visible = false
			_runner_sprite.visible = false
			_start_btn_sprite.visible = false
			_start_btn_hit_area.visible = false
			_score_panel.visible = true
			_pause_button.visible = true
			_pause_overlay.visible = false
			_game_over_overlay.visible = false
			_health_fill.color = _health_color()
		GameManager.GameState.PAUSED:
			_score_panel.visible = false
			_pause_button.visible = false
			_pause_overlay.visible = true
			_game_over_overlay.visible = false
		GameManager.GameState.GAME_OVER:
			_start_bg.visible = false
			_runner_sprite.visible = false
			_start_btn_sprite.visible = false
			_start_btn_hit_area.visible = false
			_score_panel.visible = true
			_pause_button.visible = false
			_pause_overlay.visible = false
			_game_over_overlay.visible = true
			_game_over_title.text = "GAME OVER"
			_final_score_label.text = "Final Score: %s" % _fmt(game_manager.score)
		_:
			pass






func _build_hud() -> void :

	_score_panel = _styled_panel(Rect2(30, 24, 360, 100), Color(0, 0, 0, 0.55), 14, Color(1, 0.85, 0.2, 0.5), 2)
	add_child(_score_panel)

	_score_label = _make_label("SCORE: 0", Vector2(20, 8), Vector2(320, 46), 32, Color(1, 0.85, 0.2), _ui_bold)
	_score_panel.add_child(_score_label)

	var coin_icon: = _circle_icon(Vector2(24, 58), 30, Color(1.0, 0.82, 0.25))
	_score_panel.add_child(coin_icon)
	_coin_label = _make_label("x 0", Vector2(64, 54), Vector2(280, 38), 26, Color(1, 1, 1), _ui_bold)
	_score_panel.add_child(_coin_label)


	var bar_w: = 420.0
	var bar: = _styled_panel(Rect2(VIEW_W - 450, 24, bar_w, 44), Color(0, 0, 0, 0.55), 10, Color(1, 1, 1, 0.25), 1)
	add_child(bar)

	bar.add_child(_circle_icon(Vector2(8, 8), 28, Color(0.35, 0.9, 0.4)))
	bar.add_child(_circle_icon(Vector2(bar_w - 36, 8), 28, Color(1.0, 0.3, 0.3)))

	_health_fill = ColorRect.new()
	_health_fill.position = Vector2(44, 8)
	_health_fill_max = bar_w - 88.0
	_health_fill.size = Vector2(_health_fill_max, 28)
	_health_fill.color = _health_color()
	bar.add_child(_health_fill)

	_pause_button = _make_button("II", Vector2(VIEW_W - 110, 80), Vector2(70, 50), Color(0.2, 0.2, 0.32, 0.9), 22, _ui_bold)
	_pause_button.pressed.connect(_on_pause_pressed)
	add_child(_pause_button)


	


func _build_pause_overlay() -> void :
	_pause_overlay = ColorRect.new()
	_pause_overlay.color = Color(0, 0, 0, 0.55)
	_pause_overlay.position = Vector2.ZERO
	_pause_overlay.size = Vector2(VIEW_W, VIEW_H)
	_pause_overlay.visible = false
	add_child(_pause_overlay)

	var t: = _make_label("PAUSED", Vector2(660, 340), Vector2(600, 130), 100, Color(1, 1, 1), _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	_pause_overlay.add_child(t)
	_resume_button = _make_button("RESUME", Vector2(810, 540), Vector2(300, 90), Color(0.2, 0.8, 0.4), 36, _ui_bold)
	_resume_button.pressed.connect(_on_resume_pressed)
	_pause_overlay.add_child(_resume_button)


func _build_game_over() -> void :
	_game_over_overlay = ColorRect.new()
	_game_over_overlay.color = Color(0, 0, 0, 0.5)
	_game_over_overlay.position = Vector2.ZERO
	_game_over_overlay.size = Vector2(VIEW_W, VIEW_H)
	_game_over_overlay.visible = false
	add_child(_game_over_overlay)

	_game_over_title = _make_label("GAME OVER", Vector2(560, 260), Vector2(800, 150), 108, Color(0.95, 0.15, 0.15), _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	_game_over_overlay.add_child(_game_over_title)
	_final_score_label = _make_label("Final Score: 0", Vector2(660, 440), Vector2(600, 70), 44, Color(1, 1, 1), _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	_game_over_overlay.add_child(_final_score_label)
	_revive_button = _make_button("REVIVE", Vector2(760, 540), Vector2(400, 90), Color(0.2, 0.8, 0.4), 36, _ui_bold)
	_revive_button.pressed.connect(_on_revive_pressed)
	_game_over_overlay.add_child(_revive_button)
	_restart_button = _make_button("RESTART", Vector2(760, 650), Vector2(400, 80), Color(0.2, 0.7, 0.9), 30, _ui_bold)
	_restart_button.pressed.connect(_on_restart_pressed)
	_game_over_overlay.add_child(_restart_button)


func _build_question_popup() -> void :
	_question_overlay = ColorRect.new()
	_question_overlay.color = Color(0, 0, 0, 0.6)
	_question_overlay.position = Vector2.ZERO
	_question_overlay.size = Vector2(VIEW_W, VIEW_H)
	_question_overlay.visible = false
	add_child(_question_overlay)

	var panel: = _styled_panel(Rect2(360, 90, 1200, 900), Color(0.05, 0.08, 0.16, 0.96), 26, Color(0.3, 0.85, 1.0, 0.8), 3)
	_question_overlay.add_child(panel)

	_question_title = _make_label("HEALTH CHECK", Vector2(0, 34), Vector2(1200, 70), 52, Color(0.35, 0.92, 1.0), _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	panel.add_child(_question_title)

	_question_label = _make_label("", Vector2(70, 140), Vector2(1060, 190), 30, Color(1, 1, 1), _arabic, HORIZONTAL_ALIGNMENT_CENTER)
	_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_question_label)

	_timer_label = _make_label("TIME: 15", Vector2(0, 330), Vector2(1200, 56), 36, Color(1, 0.65, 0.2), _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	panel.add_child(_timer_label)

	var colors: = [
		Color(0.2, 0.72, 0.42), 
		Color(0.22, 0.55, 0.9), 
		Color(0.95, 0.62, 0.2), 
		Color(0.68, 0.36, 0.92), 
	]
	for i in range(4):
		var b: = _make_button("", Vector2(120, 400 + i * 108), Vector2(960, 92), colors[i], 27, _arabic)
		b.pressed.connect(_on_answer_pressed.bind(i))
		panel.add_child(b)
		_answer_buttons.append(b)


func _build_flash() -> void :
	_flash = ColorRect.new()
	_flash.color = Color(0, 0, 0, 0)
	_flash.position = Vector2.ZERO
	_flash.size = Vector2(VIEW_W, VIEW_H)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


func _build_start_screen() -> void :
	// Background sprite (full screen)
	_start_bg = Sprite2D.new()
	_start_bg.texture = _start_bg_texture
	_start_bg.position = Vector2.ZERO
	_start_bg.size = Vector2(VIEW_W, VIEW_H)
	add_child(_start_bg)
	
	// Runner sprite - floats gently up and down
	_runner_sprite = Sprite2D.new()
	_runner_sprite.texture = _runner_texture
	_runner_sprite.position = Vector2(960, 500)
	_runner_sprite.scale = Vector2(2.0, 2.0)
	add_child(_runner_sprite)
	
	// Float animation: up-down loop
	var tween_runner = create_tween()
	tween_runner.tween_property(_runner_sprite, "position:y", 450, 2.0)
	tween_runner.set_loops(-1)
	tween_runner.yoyo = true
	
	// Start button sprite
	_start_btn_sprite = Sprite2D.new()
	_start_btn_sprite.texture = _start_btn_texture
	_start_btn_sprite.position = Vector2(860, 470)
	_start_btn_sprite.scale = Vector2(2.0, 2.0)
	add_child(_start_btn_sprite)
	
	// Pulsing animation on the button
	var tween_btn = create_tween()
	tween_btn.tween_property(_start_btn_sprite, "scale", Vector2(2.3, 2.3), 1.5)
	tween_btn.set_loops(-1)
	tween_btn.yoyo = true
	
	// Hit area for the button (invisible, covers the button)
	_start_btn_hit_area = Area2D.new()
	_start_btn_hit_area.position = Vector2(860 - 100, 470 - 45)
	_start_btn_hit_area.size = Vector2(400, 180)
	add_child(_start_btn_hit_area)
	
	_start_btn_hit_area.input_event.connect(_on_start_btn_pressed)
	
	// Initial tweens - start them after a brief delay
	await get_tree().create_timer(0.5).timeout
	tween_runner.start()
	tween_btn.start()


func _on_start_btn_pressed(event: InputEvent) -> void :
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_start_btn_hit_area.visible = false
			_transition_to_game()


func _transition_to_game() -> void :
	// Fade out start screen elements
	if _start_bg != null:
		_start_bg.visible = false
	if _runner_sprite != null:
		_runner_sprite.visible = false
	if _start_btn_sprite != null:
		_start_btn_sprite.visible = false
	
	// Wait then start the game
	await get_tree().create_timer(0.5).timeout
	game_manager.start_game()


func _styled_panel(rect: Rect2, bg: Color, radius: float, border: Color, border_w: float) -> Panel:
	var p: = Panel.new()
	p.position = rect.position
	p.size = rect.size
	var sb: = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(radius))
	sb.border_color = border
	sb.set_border_width_all(int(border_w))
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 12
	p.add_theme_stylebox_override("panel", sb)
	return p


func _circle_icon(pos: Vector2, size: float, color: Color) -> Panel:
	var p: = Panel.new()
	p.position = pos
	p.size = Vector2(size, size)
	var sb: = StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(size / 2.0))
	sb.border_color = Color(1, 1, 1, 0.5)
	sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _make_label(text: String, pos: Vector2, size: Vector2, font_size: int, color: Color, font: Font, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l: = Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 3)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font != null:
		l.add_theme_font_override("font", font)
	return l


func _make_button(text: String, pos: Vector2, size: Vector2, bg: Color, font_size: int, font: Font) -> Button:
	var b: = Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	if font != null:
		b.add_theme_font_override("font", font)
	var sb: = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(12)
	sb.border_color = Color(1, 1, 1, 0.35)
	sb.set_border_width_all(2)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	b.add_theme_stylebox_override("normal", sb)
	var hover: = StyleBoxFlat.new()
	hover.bg_color = bg.lightened(0.25)
	hover.set_corner_radius_all(12)
	hover.border_color = Color(1, 1, 1, 0.8)
	hover.set_border_width_all(2)
	hover.shadow_color = Color(0, 0, 0, 0.35)
	hover.shadow_size = 8
	b.add_theme_stylebox_override("hover", hover)
	var pressed: = StyleBoxFlat.new()
	pressed.bg_color = bg.darkened(0.25)
	pressed.set_corner_radius_all(12)
	pressed.border_color = Color(1, 1, 1, 0.4)
	pressed.set_border_width_all(2)
	b.add_theme_stylebox_override("pressed", pressed)
	return b






func _on_start_pressed() -> void :
	game_manager.start_game()


func _on_pause_pressed() -> void :
	game_manager.pause_game()


func _on_resume_pressed() -> void :
	game_manager.resume_game()


func _on_revive_pressed() -> void :

	game_manager.ask_revival_question()


func _on_restart_pressed() -> void :

	game_manager.restart_game()


func _on_answer_pressed(index: int) -> void :
	game_manager.submit_answer(index)


func _on_score_changed(new_score: int) -> void :
	_score_label.text = "SCORE: %s" % _fmt(new_score)


func _on_coins_changed(new_coins: int) -> void :
	_coin_label.text = "x %d" % new_coins


func _on_health_changed(new_health: int) -> void :
	_health_fill.size.x = _health_fill_max * float(new_health) / float(game_manager.max_health)
	_health_fill.color = _health_color()


func _health_color() -> Color:
	var p: = float(game_manager.health) / float(game_manager.max_health)
	if p > 0.5:
		return Color(0.25, 0.85, 0.35)
	if p > 0.25:
		return Color(0.95, 0.8, 0.2)
	return Color(0.9, 0.2, 0.2)


func _on_question_requested(question: Dictionary, _context: int) -> void :
	_question_time_left = QUESTION_TIME
	_question_label.text = str(question.get("q", "?"))
	var opts: Array = question.get("options", [])
	var letters: = ["أ", "ب", "ج", "د"]
	for i in range(_answer_buttons.size()):
		if i < opts.size():
			_answer_buttons[i].text = "%s) %s" % [letters[i], str(opts[i])]
			_answer_buttons[i].visible = true
		else:
			_answer_buttons[i].visible = false
	_question_overlay.visible = true
	_pause_overlay.visible = false
	_game_over_overlay.visible = false


func _on_question_resolved(correct: bool) -> void :
	_question_overlay.visible = false
	_do_flash(correct)


func _do_flash(correct: bool) -> void :
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash.color = Color(0.2, 1.0, 0.4, 0.35) if correct else Color(1.0, 0.2, 0.2, 0.4)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, 0.6)


func _fmt(n: int) -> String:
	var s: = str(n)
	var out: = ""
	var count: = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
