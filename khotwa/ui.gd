class_name UI
extends CanvasLayer

const VIEW_W: = 1920.0
const VIEW_H: = 1080.0
const QUESTION_TIME: = 15.0

const ARIAL: = "res://assets/fonts/arial.ttf"
const ARIAL_BOLD: = "res://assets/fonts/arial_bold.ttf"
const TAHOMA: = "res://assets/fonts/tahoma.ttf"

# Brand color palette — vibrant, kid-friendly, high contrast
const C_BRAND: = Color(0.2, 0.85, 0.45)      # neon green
const C_BRAND_DARK: = Color(0.15, 0.65, 0.35)
const C_ACCENT: = Color(0.95, 0.65, 0.2)     # orange
const C_ACCENT_DARK: = Color(0.75, 0.5, 0.15)
const C_DANGER: = Color(1.0, 0.35, 0.4)      # coral red
const C_DANGER_DARK: = Color(0.8, 0.25, 0.3)
const C_YELLOW: = Color(1.0, 0.85, 0.2)      # bright yellow
const C_YELLOW_DARK: = Color(0.8, 0.65, 0.1)
const C_CYAN: = Color(0.4, 0.85, 1.0)        # sky cyan
const C_CYAN_DARK: = Color(0.3, 0.65, 0.8)
const C_MAGENTA: = Color(0.9, 0.5, 1.0)      # violet
const C_MAGENTA_DARK: = Color(0.7, 0.35, 0.8)
const C_BG_DARK: = Color(0.02, 0.03, 0.08, 1.0)
const C_PANEL: = Color(0.06, 0.08, 0.16, 0.95)

var _ui_font: Font
var _ui_bold: Font
var _arabic: Font

# HUD
var _score_panel: Panel
var _score_label: Label
var _score_value_label: Label
var _coin_label: Label
var _health_fill: ColorRect
var _health_fill_max: = 320.0
var _pause_button: Button

# Pause overlay
var _pause_overlay: ColorRect
var _resume_button: Button

# Game over overlay
var _game_over_overlay: ColorRect
var _game_over_title: Label
var _final_score_label: Label
var _revive_button: Button
var _restart_button: Button

# Question overlay
var _question_overlay: ColorRect
var _question_title: Label
var _question_label: Label
var _timer_label: Label
var _answer_buttons: Array[Button] = []
var _flash: ColorRect

# MENU / start screen
var _menu_bg: ColorRect
var _menu_bg_glow: ColorRect
var _menu_title_shadow: Label
var _menu_title: Label
var _menu_tagline: Label
var _menu_start: Button
var _menu_settings: Button
var _menu_howto: Button
var _menu_icons: Array[Panel] = []
var _menu_anim_time: = 0.0

# Settings panel overlay
var _settings_panel: ColorRect
var _settings_card: Panel
var _tog_music: Button
var _tog_sfx: Button
var _settings_close: Button

# How-to panel overlay
var _howto_panel: ColorRect
var _howto_card: Panel
var _howto_close: Button

var _question_time_left: = 0.0
var _flash_tween: Tween

@onready var game_manager: GameManager = get_node("../GameManager")


func _ready() -> void :
	_load_assets()
	_build_hud()
	_build_pause_overlay()
	_build_game_over()
	_build_question_popup()
	_build_flash()
	_build_menu()
	_build_settings_panel()
	_build_howto_panel()
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


func _process(delta: float) -> void :
	if game_manager.question_active:

		_question_time_left -= delta
		_timer_label.text = "TIME: %d" % ceili(_question_time_left)
		if _question_time_left <= 0.0:
			game_manager.question_timed_out()
		return

	_refresh()

	# Animate menu decorations when on menu
	if game_manager.state == GameManager.GameState.MENU:
		_menu_anim_time += delta
		_animate_menu(delta)


func _animate_menu(delta: float) -> void :
	# Bob the icon chips up and down
	var time: = _menu_anim_time
	var i: int = 0
	for icon in _menu_icons:
		var bob: float = sin(time * 3.0 + i * 2.0) * 12.0
		var base_y: float = icon.get("base_y", icon.position.y)
		if icon.get("base_y") == null:
			icon.set("base_y", icon.position.y)
			base_y = icon.position.y
		icon.position = Vector2(icon.position.x, base_y + bob)
		i += 1

	# Pulse the menu background glow
	if _menu_bg_glow != null:
		var pulse: float = 0.4 + 0.3 * sin(time * 2.0)
		_menu_bg_glow.modulate = Color(0.2, 0.6, 1.0, pulse)

	# Pulse the start button scale
	if _menu_start != null:
		var scale_pulse: float = 1.0 + 0.05 * sin(time * 5.0)
		_menu_start.scale = Vector2(scale_pulse, scale_pulse)


func _refresh() -> void :
	match game_manager.state:
		GameManager.GameState.MENU:
			_show_menu()
		GameManager.GameState.RUNNING:
			_hide_menu()
			_settings_panel.visible = false
			_howto_panel.visible = false
			_menu_start.visible = false
			_score_panel.visible = true
			_pause_button.visible = true
			_pause_overlay.visible = false
			_game_over_overlay.visible = false
			_health_fill.color = _health_color()
		GameManager.GameState.PAUSED:
			_hide_menu()
			_settings_panel.visible = false
			_howto_panel.visible = false
			_menu_start.visible = false
			_score_panel.visible = false
			_pause_button.visible = false
			_pause_overlay.visible = true
			_game_over_overlay.visible = false
		GameManager.GameState.GAME_OVER:
			_hide_menu()
			_settings_panel.visible = false
			_howto_panel.visible = false
			_menu_start.visible = false
			_score_panel.visible = true
			_pause_button.visible = false
			_pause_overlay.visible = false
			_game_over_overlay.visible = true
			_game_over_title.text = "GAME OVER"
			_final_score_label.text = "Final Score: %s" % _fmt(game_manager.score)
		_:
			pass


func _show_menu() -> void :
	_menu_bg.visible = true
	_menu_bg_glow.visible = true
	_menu_title_shadow.visible = true
	_menu_title.visible = true
	_menu_tagline.visible = true
	_menu_start.visible = true
	_menu_settings.visible = true
	_menu_howto.visible = true
	for icon in _menu_icons:
		icon.visible = true
		if icon.get("base_y") == null:
			icon.set("base_y", icon.position.y)
	_score_panel.visible = false
	_pause_button.visible = false
	_pause_overlay.visible = false
	_game_over_overlay.visible = false


func _hide_menu() -> void :
	_menu_bg.visible = false
	_menu_bg_glow.visible = false
	_menu_title_shadow.visible = false
	_menu_title.visible = false
	_menu_tagline.visible = false
	_menu_start.visible = false
	_menu_settings.visible = false
	_menu_howto.visible = false
	for icon in _menu_icons:
		icon.visible = false


func _build_hud() -> void :

	_score_panel = _styled_panel(Rect2(30, 24, 360, 110), Color(0, 0, 0, 0.6), 18, C_YELLOW, 3)
	add_child(_score_panel)

	_score_label = _make_label("SCORE", Vector2(20, 10), Vector2(320, 34), 26, C_YELLOW, _ui_bold, HORIZONTAL_ALIGNMENT_LEFT)
	_score_panel.add_child(_score_label)

	var score_val: = _make_label("0", Vector2(20, 44), Vector2(320, 50), 48, Color(1, 1, 1), _ui_bold, HORIZONTAL_ALIGNMENT_LEFT)
	_score_panel.add_child(score_val)
	_score_value_label = score_val

	var coin_icon: = _circle_icon(Vector2(24, 70), 36, C_YELLOW)
	_score_panel.add_child(coin_icon)
	_coin_label = _make_label("x 0", Vector2(70, 64), Vector2(280, 44), 34, Color(1, 1, 1), _ui_bold, HORIZONTAL_ALIGNMENT_LEFT)
	_score_panel.add_child(_coin_label)

	var bar_w: = 420.0
	var bar: = _styled_panel(Rect2(VIEW_W - 450, 24, bar_w, 56), Color(0, 0, 0, 0.6), 14, Color(1, 1, 1, 0.25), 2)
	add_child(bar)

	bar.add_child(_circle_icon(Vector2(8, 8), 32, Color(0.35, 0.9, 0.4)))
	bar.add_child(_circle_icon(Vector2(bar_w - 40, 8), 32, C_DANGER))

	_health_fill = ColorRect.new()
	_health_fill.position = Vector2(44, 14)
	_health_fill_max = bar_w - 88.0
	_health_fill.size = Vector2(_health_fill_max, 28)
	_health_fill.color = _health_color()
	bar.add_child(_health_fill)

	_pause_button = _make_button("II", Vector2(VIEW_W - 120, 90), Vector2(80, 56), Color(0.2, 0.2, 0.32, 0.9), 24, _ui_bold)
	_pause_button.pressed.connect(_on_pause_pressed)
	add_child(_pause_button)


func _build_menu() -> void :
	# Deep dark background
	_menu_bg = ColorRect.new()
	_menu_bg.color = C_BG_DARK
	_menu_bg.position = Vector2.ZERO
	_menu_bg.size = Vector2(VIEW_W, VIEW_H)
	add_child(_menu_bg)

	# Animated glow behind title
	_menu_bg_glow = ColorRect.new()
	_menu_bg_glow.color = Color(0.2, 0.6, 1.0, 0.0)
	_menu_bg_glow.position = Vector2(560, 100)
	_menu_bg_glow.size = Vector2(800, 300)
	add_child(_menu_bg_glow)

	# Title shadow for depth
	_menu_title_shadow = _make_label("KHOTWA", Vector2(4, 184), Vector2(VIEW_W, 130), 115, Color(0, 0, 0, 0.5), _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_menu_title_shadow)

	# Main brand title
	_menu_title = _make_label("KHOTWA", Vector2(0, 170), Vector2(VIEW_W, 130), 115, Color(1, 1, 1), _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	_menu_title.add_theme_color_override("font_shadow_color", C_CYAN)
	_menu_title.add_theme_constant_override("shadow_offset_x", 4)
	_menu_title.add_theme_constant_override("shadow_offset_y", 4)
	add_child(_menu_title)

	# Arabic tagline
	_menu_tagline = _make_label("خطوة نحو التعافي   —   A step toward recovery", Vector2(0, 320), Vector2(VIEW_W, 60), 36, C_YELLOW, _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_menu_tagline)

	# Big animated Start button
	_menu_start = _make_button("ابدأ اللعب — START", Vector2(730, 640), Vector2(460, 110), C_BRAND, 44, _ui_bold)
	_menu_start.pressed.connect(_on_start_pressed)
	add_child(_menu_start)

	# Settings button
	_menu_settings = _make_button("الإعدادات — SETTINGS", Vector2(520, 790), Vector2(320, 72), C_CYAN, 28, _ui_bold)
	_menu_settings.pressed.connect(_on_menu_settings_pressed)
	add_child(_menu_settings)

	# How-to button
	_menu_howto = _make_button("كيف ألعب — HOW TO PLAY", Vector2(1080, 790), Vector2(320, 72), C_ACCENT, 28, _ui_bold)
	_menu_howto.pressed.connect(_on_menu_howto_pressed)
	add_child(_menu_howto)

	# Decorative floating icon chips in vibrant colors
	var chip_data: Array[Dictionary] = [
		{"color": C_YELLOW,  "pos": Vector2(260, 520), "label": "coin"},   # coin
		{"color": Color(0.5, 1, 0.6), "pos": Vector2(480, 480), "label": "fruit"},    # fruit
		{"color": C_CYAN,    "pos": Vector2(780, 540), "label": "healthy"},    # healthy
		{"color": C_DANGER,  "pos": Vector2(1100, 490), "label": "hazard"},  # hazard
		{"color": C_MAGENTA, "pos": Vector2(1380, 560), "label": "sparkle"},   # sparkle
		{"color": C_YELLOW,  "pos": Vector2(1620, 460), "label": "coin2"},
		{"color": C_CYAN,    "pos": Vector2(140, 620), "label": "fruit2"},
		{"color": C_MAGENTA, "pos": Vector2(1500, 660), "label": "sparkle2"},
	]
	for data in chip_data:
		var chip: = _circle_icon(data.pos, 72, data.color)
		add_child(chip)
		_menu_icons.append(chip)


func _build_settings_panel() -> void :
	_settings_panel = ColorRect.new()
	_settings_panel.color = Color(0, 0, 0, 0.75)
	_settings_panel.position = Vector2.ZERO
	_settings_panel.size = Vector2(VIEW_W, VIEW_H)
	add_child(_settings_panel)

	_settings_card = _styled_panel(Rect2(460, 200, 1000, 680), C_PANEL, 34, C_CYAN, 4)
	_settings_panel.add_child(_settings_card)

	var title: = _make_label("الإعدادات", Vector2(0, 50), Vector2(1000, 70), 64, C_CYAN, _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	_settings_card.add_child(title)

	var subtitle: = _make_label("ضبط تفضيلات اللعبة", Vector2(0, 140), Vector2(1000, 40), 28, C_YELLOW, _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	_settings_card.add_child(subtitle)

	_tog_music = _make_button("موسيقى: تشغيل", Vector2(150, 250), Vector2(700, 76), Color(0.2, 0.6, 1, 0.95), 32, _ui_bold)
	_tog_music.pressed.connect(_on_toggle_music)
	_settings_card.add_child(_tog_music)

	_tog_sfx = _make_button("التأثيرات الصوتية: تشغيل", Vector2(150, 360), Vector2(700, 76), Color(0.2, 0.6, 1, 0.95), 32, _ui_bold)
	_tog_sfx.pressed.connect(_on_toggle_sfx)
	_settings_card.add_child(_tog_sfx)

	var note: = _make_label("النصيحة الصحية: اسأل شخصًا موثوقًا إذا شعرت بحاجة للمساعدة", Vector2(0, 500), Vector2(1000, 60), 26, Color(0.8, 0.85, 1), _arabic, HORIZONTAL_ALIGNMENT_CENTER)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_settings_card.add_child(note)

	_settings_close = _make_button("رجوع — BACK", Vector2(350, 620), Vector2(300, 76), C_BRAND, 32, _ui_bold)
	_settings_close.pressed.connect(_on_settings_close)
	_settings_card.add_child(_settings_close)


func _build_howto_panel() -> void :
	_howto_panel = ColorRect.new()
	_howto_panel.color = Color(0, 0, 0, 0.75)
	_howto_panel.position = Vector2.ZERO
	_howto_panel.size = Vector2(VIEW_W, VIEW_H)
	add_child(_howto_panel)

	_howto_card = _styled_panel(Rect2(460, 200, 1000, 680), C_PANEL, 34, C_ACCENT, 4)
	_howto_panel.add_child(_howto_card)

	var title: = _make_label("كيف تلعب", Vector2(0, 50), Vector2(1000, 70), 64, C_YELLOW, _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	_howto_card.add_child(title)

	var steps: Array[String] = [
		"1) حرك بين المسارات الثلاثة باللمس أو الأسهم",
		"2) اجمع العملات والفواكه والأطعمة الصحية لزيادة النقاط والصحة",
		"3) تجنب المخدرات والأطعمة غير الصحية — كل لمسة تفقدك 25 نقطة صحة",
		"4) عند انتهاء الصحة، أجب على سؤال صحي للعودة إلى اللعب",
		"5) السرعة تزداد مع مرور الوقت — كن يقظاً وسريع البديهة",
	]
	var y: float = 160
	for step in steps:
		var s: = _make_label(step, Vector2(80, y), Vector2(840, 56), 30, Color(1, 1, 1), _arabic)
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_howto_card.add_child(s)
		y += 86

	_howto_close = _make_button("رجوع — BACK", Vector2(350, 590), Vector2(300, 76), C_BRAND, 32, _ui_bold)
	_howto_close.pressed.connect(_on_howto_close)
	_howto_card.add_child(_howto_close)


func _build_pause_overlay() -> void :
	_pause_overlay = ColorRect.new()
	_pause_overlay.color = Color(0, 0, 0, 0.6)
	_pause_overlay.position = Vector2.ZERO
	_pause_overlay.size = Vector2(VIEW_W, VIEW_H)
	add_child(_pause_overlay)

	var t: = _make_label("مؤقتاً", Vector2(660, 320), Vector2(600, 140), 110, Color(1, 1, 1), _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	t.add_theme_color_override("font_shadow_color", C_CYAN)
	t.add_theme_constant_override("shadow_offset_x", 4)
	t.add_theme_constant_override("shadow_offset_y", 4)
	_pause_overlay.add_child(t)

	_resume_button = _make_button("استئناف — RESUME", Vector2(810, 520), Vector2(300, 86), C_BRAND, 34, _ui_bold)
	_resume_button.pressed.connect(_on_resume_pressed)
	_pause_overlay.add_child(_resume_button)


func _build_game_over() -> void :
	_game_over_overlay = ColorRect.new()
	_game_over_overlay.color = Color(0, 0, 0, 0.55)
	_game_over_overlay.position = Vector2.ZERO
	_game_over_overlay.size = Vector2(VIEW_W, VIEW_H)
	add_child(_game_over_overlay)

	_game_over_title = _make_label("GAME OVER", Vector2(560, 240), Vector2(800, 160), 115, C_DANGER, _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	_game_over_title.add_theme_color_override("font_shadow_color", Color(0.5, 0, 0, 0.8))
	_game_over_title.add_theme_constant_override("shadow_offset_x", 4)
	_game_over_title.add_theme_constant_override("shadow_offset_y", 4)
	_game_over_overlay.add_child(_game_over_title)

	_final_score_label = _make_label("Final Score: 0", Vector2(660, 420), Vector2(600, 70), 48, Color(1, 1, 1), _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	_game_over_overlay.add_child(_final_score_label)

	_revive_button = _make_button("إحياء بالسؤال الصحي — REVIVE", Vector2(720, 540), Vector2(480, 86), C_BRAND, 32, _ui_bold)
	_revive_button.pressed.connect(_on_revive_pressed)
	_game_over_overlay.add_child(_revive_button)

	_restart_button = _make_button("بدء من جديد — RESTART", Vector2(720, 650), Vector2(480, 80), C_CYAN, 30, _ui_bold)
	_restart_button.pressed.connect(_on_restart_pressed)
	_game_over_overlay.add_child(_restart_button)


func _build_question_popup() -> void :
	_question_overlay = ColorRect.new()
	_question_overlay.color = Color(0, 0, 0, 0.65)
	_question_overlay.position = Vector2.ZERO
	_question_overlay.size = Vector2(VIEW_W, VIEW_H)
	add_child(_question_overlay)

	var panel: = _styled_panel(Rect2(360, 80, 1200, 920), C_PANEL, 32, C_CYAN, 4)
	_question_overlay.add_child(panel)

	_question_title = _make_label("فحص صحي", Vector2(0, 30), Vector2(1200, 70), 56, C_CYAN, _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	panel.add_child(_question_title)

	_question_label = _make_label("", Vector2(60, 130), Vector2(1080, 200), 34, Color(1, 1, 1), _arabic, HORIZONTAL_ALIGNMENT_CENTER)
	_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_question_label)

	_timer_label = _make_label("TIME: 15", Vector2(0, 360), Vector2(1200, 60), 40, C_YELLOW, _ui_bold, HORIZONTAL_ALIGNMENT_CENTER)
	panel.add_child(_timer_label)

	var colors: = [
		C_BRAND, C_CYAN, C_ACCENT, C_MAGENTA,
	]
	for i in range(4):
		var b: = _make_button("", Vector2(120, 460 + i * 100), Vector2(960, 86), colors[i], 28, _arabic)
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


func _styled_panel(rect: Rect2, bg: Color, radius: float, border: Color, border_w: float) -> Panel:
	var p: = Panel.new()
	p.position = rect.position
	p.size = rect.size
	var sb: = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(radius))
	sb.border_color = border
	sb.set_border_width_all(int(border_w))
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 16
	p.add_theme_stylebox_override("panel", sb)
	return p


func _circle_icon(pos: Vector2, size: float, color: Color) -> Panel:
	var p: = Panel.new()
	p.position = pos
	p.size = Vector2(size, size)
	var sb: = StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(size / 2.0))
	sb.border_color = Color(1, 1, 1, 0.6)
	sb.set_border_width_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 10
	p.add_theme_stylebox_override("panel", sb)
	return p


func _make_label(text: String, pos: Vector2, size: Vector2, font_size: int, color: Color, font: Font, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l: = Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
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
	sb.set_corner_radius_all(int(size.y / 2.0))
	sb.border_color = Color(1, 1, 1, 0.4)
	sb.set_border_width_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 12
	b.add_theme_stylebox_override("normal", sb)

	var hover: = StyleBoxFlat.new()
	hover.bg_color = bg.lightened(0.3)
	hover.set_corner_radius_all(int(size.y / 2.0))
	hover.border_color = Color(1, 1, 1, 0.8)
	hover.set_border_width_all(3)
	hover.shadow_color = Color(0, 0, 0, 0.6)
	hover.shadow_size = 16
	b.add_theme_stylebox_override("hover", hover)

	var pressed: = StyleBoxFlat.new()
	pressed.bg_color = bg.darkened(0.25)
	pressed.set_corner_radius_all(int(size.y / 2.0))
	pressed.border_color = Color(1, 1, 1, 0.5)
	pressed.set_border_width_all(3)
	pressed.shadow_color = Color(0, 0, 0, 0.4)
	pressed.shadow_size = 8
	b.add_theme_stylebox_override("pressed", pressed)

	return b


func _on_start_pressed() -> void :
	game_manager.start_game()


func _on_menu_settings_pressed() -> void :
	_settings_panel.visible = true


func _on_menu_howto_pressed() -> void :
	_howto_panel.visible = true


func _on_toggle_music() -> void :
	_tog_music.text = "موسيقى: إيقاف" if _tog_music.text == "موسيقى: تشغيل" else "موسيقى: تشغيل"


func _on_toggle_sfx() -> void :
	_tog_sfx.text = "التأثيرات الصوتية: إيقاف" if _tog_sfx.text == "التأثيرات الصوتية: تشغيل" else "التأثيرات الصوتية: تشغيل"


func _on_settings_close() -> void :
	_settings_panel.visible = false


func _on_howto_close() -> void :
	_howto_panel.visible = false


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
	if _score_value_label != null:
		_score_value_label.text = str(new_score)


func _on_coins_changed(new_coins: int) -> void :
	_coin_label.text = "x %d" % new_coins


func _on_health_changed(new_health: int) -> void :
	var target_w: float = _health_fill_max * float(new_health) / float(game_manager.max_health)
	var tween: = create_tween()
	tween.tween_property(_health_fill, "size:x", target_w, 0.4)
	_health_fill.color = _health_color()


func _health_color() -> Color:
	var p: = float(game_manager.health) / float(game_manager.max_health)
	if p > 0.6:
		return C_BRAND
	if p > 0.3:
		return C_YELLOW
	return C_DANGER


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
	_flash.color = Color(0.2, 1.0, 0.4, 0.35) if correct else Color(1.0, 0.2, 0.2, 0.45)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, 0.5)


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
