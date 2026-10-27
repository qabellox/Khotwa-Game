class_name Track
extends Node2D





const VIEW_WIDTH: = 1920.0
const VIEW_HEIGHT: = 1080.0
const TRACK_TEXTURE: = "res://assets/railway.png"

const SCROLL_SHADER: = "\r\nshader_type canvas_item;\r\n\r\nuniform float scroll;\r\nuniform float tile_w;\r\n\r\nvoid fragment() {\r\n\tvec2 uv = UV;\r\n\t// Tile the seamless loop horizontally so the track covers the full width,\r\n\t// while each tile is still drawn at its natural size (no stretching).\r\n\tuv.x = fract(uv.x / tile_w + scroll);\r\n\tCOLOR = texture(TEXTURE, uv);\r\n}\r\n"














var _material: ShaderMaterial
var _scroll: = 0.0
var _texture: Texture2D
var _scroll_per_px: = 0.0

@onready var game_manager: GameManager = get_node("../GameManager")


func _ready() -> void :
	_texture = load(TRACK_TEXTURE) as Texture2D
	if _texture == null:
		push_error("Track texture missing: " + TRACK_TEXTURE)
		return

	var tex_size: = _texture.get_size()

	var natural_w: float = VIEW_HEIGHT / tex_size.y * tex_size.x

	var sprite: = Sprite2D.new()
	sprite.texture = _texture
	sprite.centered = false


	sprite.scale = Vector2(VIEW_WIDTH / tex_size.x, VIEW_HEIGHT / tex_size.y)
	sprite.position = Vector2.ZERO
	add_child(sprite)

	var shader: = Shader.new()
	shader.code = SCROLL_SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	sprite.material = _material


	_material.set_shader_parameter("tile_w", natural_w / VIEW_WIDTH)

	_scroll_per_px = 1.0 / natural_w


func _process(delta: float) -> void :
	if _texture == null or game_manager.state != GameManager.GameState.RUNNING:
		return

	_scroll = fmod(_scroll + game_manager.game_speed * delta * _scroll_per_px, 1.0)
	_material.set_shader_parameter("scroll", _scroll)
