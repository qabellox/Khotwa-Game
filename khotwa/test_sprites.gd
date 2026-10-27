extends SceneTree






var _frames: = 0
var _main: Node
var _started: = false
var _checked_pain: = false
var _checked_dead: = false


func _process(_delta: float) -> bool:
	_frames += 1
	if _main == null or not is_instance_valid(_main):
		_main = (load("res://main.tscn") as PackedScene).instantiate()
		root.add_child(_main)
	if not _started:
		_started = true
		_main.get_node("GameManager").start_game()

	var player: = _main.get_node("Player")
	var gm: Node = _main.get_node("GameManager")

	if _frames == 20 and not _checked_pain:
		_checked_pain = true
		print("BGM stream=", gm._bgm.stream.resource_path if gm._bgm.stream != null else "NULL", " playing=", gm._bgm.playing)
		print("SFX coin=", gm._coin_sfx.stream.resource_path if gm._coin_sfx.stream != null else "NULL")
		print("SFX pain=", gm._pain_sfx.stream.resource_path if gm._pain_sfx.stream != null else "NULL")
		print("SFX death=", gm._death_sfx.stream.resource_path if gm._death_sfx.stream != null else "NULL")
		print("SFX heal=", gm._heal_sfx.stream.resource_path if gm._heal_sfx.stream != null else "NULL")

		player._invuln_timer = 0.5
		player._update_animation()
		print("PAIN texture=", player.sprite.texture.resource_path, " region=", player.sprite.region_rect)
	elif _frames == 25 and not _checked_dead:
		_checked_dead = true

		gm.take_damage(100)
		print("DEAD state=", gm.state, " player._dead=", player._dead)
		print("DEAD texture=", player.sprite.texture.resource_path, " region=", player.sprite.region_rect)
		print("DEAD lying frame region=", player.sprite.region_rect, " feet=", player._feet_y, " cx=", player._char_cx)
		quit()
		return true
	return false
