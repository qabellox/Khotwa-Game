class_name Track
extends Node2D

## Parallax scrolling track background. Stacks copies of the road texture
## vertically, scrolls them down at the GameManager's speed, and recycles
## them below the screen for endless forward motion.

const VIEW_WIDTH := 1080.0
const VIEW_HEIGHT := 1920.0
const TRACK_TEXTURES := ["res://assets/track_new.jpeg", "res://assets/track.png"]

@export var parallax_factor := 1.0

var _texture: Texture2D
var _copies: Array[Sprite2D] = []
var _scaled_height := 0.0
var _total_height := 0.0

@onready var game_manager: GameManager = get_node("../GameManager")


func _ready() -> void:
	for path in TRACK_TEXTURES:
		_texture = load(path) as Texture2D
		if _texture:
			break
	if _texture == null:
		push_error("Track textures missing.")
		return

	var scale_f := VIEW_WIDTH / _texture.get_size().x
	_scaled_height = _texture.get_size().y * scale_f
	var copy_count := int(ceil(VIEW_HEIGHT / _scaled_height)) + 2
	_total_height = _scaled_height * copy_count

	for i in copy_count:
		var copy := Sprite2D.new()
		copy.texture = _texture
		copy.centered = false
		copy.scale = Vector2(scale_f, scale_f)
		copy.position = Vector2(0.0, i * _scaled_height)
		add_child(copy)
		_copies.append(copy)


func _process(delta: float) -> void:
	if _texture == null or game_manager.game_over:
		return
	var speed: float = game_manager.game_speed * parallax_factor
	for copy in _copies:
		copy.position.y += speed * delta
		if copy.position.y > VIEW_HEIGHT:
			copy.position.y -= _total_height