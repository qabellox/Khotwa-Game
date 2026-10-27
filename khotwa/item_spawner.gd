class_name ItemSpawner
extends Node2D






const SPAWN_X: = 2020.0
const DESPAWN_X: = -140.0




const HAZARDS: = [
	{"texture": "res://assets/drug.png", "region": Rect2(196.0, 55.0, 296.0, 262.0), "glow": Color(1.0, 0.25, 0.3), "cx": 0.0}, 
	{"texture": "res://assets/unhealthy.png", "region": Rect2(196.0, 55.0, 296.0, 262.0), "glow": Color(1.0, 0.25, 0.3), "cx": 0.0}, 
]
const PICKUPS: = [
	{"texture": "res://assets/coin.png", "region": Rect2(94.0, 27.0, 489.0, 315.0), "value": 5, "heal": 0, "glow": Color(1.0, 0.82, 0.25), "cx": 0.0}, 
	{"texture": "res://assets/fruit.png", "region": Rect2(133.0, 54.0, 437.0, 265.0), "value": 10, "heal": 25, "glow": Color(0.4, 1.0, 0.55), "cx": 0.0}, 
	{"texture": "res://assets/healthy.png", "region": Rect2(133.0, 54.0, 437.0, 265.0), "value": 15, "heal": 40, "glow": Color(0.4, 1.0, 0.55), "cx": 0.0}, 
]

@export var spawn_interval: = 1.05
@export var min_spawn_interval: = 0.6
@export var hazard_chance: = 0.5


const GLOW_TEX_SIZE: = 256.0
const GLOW_RADIUS: = 2.3
const BOB_AMPLITUDE: = 6.0
const BOB_SPEED: = 2.5

var _spawn_timer: = 0.0
var _bob_time: = 0.0
var _last_lane: = -1
var _hazards: Array[Dictionary] = []
var _pickups: Array[Dictionary] = []

@onready var game_manager: GameManager = get_node("../GameManager")


func _ready() -> void :
	for e in HAZARDS:
		var t: = load(e.texture) as Texture2D
		if t:
			_hazards.append({"texture": t, "region": e.region, "glow": e.glow, "cx": e.get("cx", 0.0)})
	for e in PICKUPS:
		var t: = load(e.texture) as Texture2D
		if t:
			_pickups.append({"texture": t, "region": e.region, "value": e.value, "heal": e.get("heal", 0), "glow": e.glow, "cx": e.get("cx", 0.0)})
	game_manager.game_started.connect(_clear_items)


func _clear_items() -> void :
	for child in get_children():
		child.queue_free()


func _process(delta: float) -> void :
	if game_manager.state != GameManager.GameState.RUNNING:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = _next_interval()
		_spawn_item()
	_move_items(delta)


func _next_interval() -> float:

	var ratio: float = game_manager.game_speed / game_manager.base_speed
	return maxf(min_spawn_interval, spawn_interval / ratio)



func _make_glow(color: Color) -> GradientTexture2D:
	var grad: = Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 0.55))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var tex: = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = GLOW_TEX_SIZE
	tex.height = GLOW_TEX_SIZE
	return tex


func _spawn_item() -> void :
	if _hazards.is_empty() and _pickups.is_empty():
		return


	var is_hazard: = false
	if _pickups.is_empty():
		is_hazard = true
	elif _hazards.is_empty():
		is_hazard = false
	else:
		is_hazard = randf() < hazard_chance



	var lane: = randi() % 3
	if lane == _last_lane:
		lane = (lane + 1) % 3
	_last_lane = lane

	var item: = Area2D.new()
	var aura: = Sprite2D.new()
	item.add_child(aura)
	var spr: = Sprite2D.new()
	item.add_child(spr)

	if is_hazard:
		var e: Dictionary = _hazards.pick_random()
		aura.texture = _make_glow(e.glow)
		var aura_s: = 150.0 * GLOW_RADIUS / GLOW_TEX_SIZE
		aura.scale = Vector2(aura_s, aura_s)
		item.set_meta("aura_scale", aura_s)
		spr.texture = e.texture
		spr.region_enabled = true
		spr.region_rect = e.region
		var s: float = 150.0 / e.region.size.y
		spr.scale = Vector2(s, s)


		spr.position.x = - e.cx * s

		var hit: Vector2 = e.region.size * s * 1.02
		item.set_meta("hit_size", Vector2(hit.x, minf(hit.y, 120.0)))
		item.add_to_group("obstacles")
	else:
		var e: Dictionary = _pickups.pick_random()
		aura.texture = _make_glow(e.glow)
		var aura_s: = 130.0 * GLOW_RADIUS / GLOW_TEX_SIZE
		aura.scale = Vector2(aura_s, aura_s)
		item.set_meta("aura_scale", aura_s)
		spr.texture = e.texture
		spr.region_enabled = true
		spr.region_rect = e.region
		var s: float = 130.0 / e.region.size.y
		spr.scale = Vector2(s, s)
		spr.position.x = - e.cx * s

		var hit: Vector2 = e.region.size * s * 0.96
		item.set_meta("hit_size", Vector2(hit.x, minf(hit.y, 120.0)))
		item.set_meta("value", e.value)
		item.set_meta("heal", e.heal)
		item.add_to_group("pickups")


	item.position = Vector2(SPAWN_X, game_manager.lane_item_y(lane))
	item.set_meta("bob_phase", randf() * TAU)
	add_child(item)


func _move_items(delta: float) -> void :
	_bob_time += delta
	var speed: float = game_manager.game_speed
	for child in get_children():
		if child is Area2D:
			child.position.x -= speed * delta

			var phase: float = child.get_meta("bob_phase", 0.0)
			var bob: float = sin(_bob_time * BOB_SPEED + phase) * BOB_AMPLITUDE
			child.get_child(0).position.y = bob
			child.get_child(1).position.y = bob

			var base: float = child.get_meta("aura_scale", 1.0)
			var pulse: = 1.0 + sin(_bob_time * BOB_SPEED * 0.6 + phase) * 0.08
			child.get_child(0).scale = Vector2(base * pulse, base * pulse)
			if child.position.x < DESPAWN_X:
				child.queue_free()
