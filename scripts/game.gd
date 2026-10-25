extends Node3D

var player: CharacterBody3D
var maze: Node3D
var hud: CanvasLayer
var shatter: CanvasLayer
var spiral: CanvasLayer
var paused := false
var intercom_t := 6.0


func _ready() -> void:
	add_to_group("game_root")
	randomize()
	if GameState.level < 1:
		GameState.reset_run()
	_world()
	_player()
	_rebuild_maze()
	hud = CanvasLayer.new()
	hud.set_script(load("res://scripts/hud.gd"))
	hud.name = "HUD"
	add_child(hud)
	shatter = CanvasLayer.new()
	shatter.set_script(load("res://scripts/shatter_overlay.gd"))
	add_child(shatter)
	spiral = CanvasLayer.new()
	spiral.set_script(load("res://scripts/spiral_overlay.gd"))
	add_child(spiral)

	# Optional: listen when a trap finishes
	if shatter.has_signal("finished"):
		shatter.finished.connect(_on_trap_finished)
	if spiral.has_signal("finished"):
		spiral.finished.connect(_on_trap_finished)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.say("You wake in the wing. Three keys. Do not stare.")
	if GameState.joi_mode:
		GameState.say("JOI protocol is live. The maze will not let you rush.")


func _rebuild_maze() -> void:
	if maze and is_instance_valid(maze):
		maze.queue_free()
	maze = Node3D.new()
	maze.set_script(load("res://scripts/maze_builder.gd"))
	maze.name = "Maze"
	add_child(maze)
	if maze.has_method("configure_for_level"):
		maze.configure_for_level(GameState.level)
	maze.build()
	player.global_position = maze.cell_to_world(maze.start_cell) + Vector3(0, 0.1, 0)
	player.velocity = Vector3.ZERO


func _world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.014, 0.018)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.18, 0.2, 0.24)
	env.ambient_light_energy = 0.28
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.08, 0.09)
	env.fog_density = 0.018
	env.fog_aerial_perspective = 0.25
	env.glow_enabled = true
	env.glow_intensity = 1.15
	env.glow_bloom = 0.35
	env.glow_hdr_threshold = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.12
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssr_enabled = true
	env.ssr_max_steps = 16
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.05
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.08
	sun.light_color = Color(0.55, 0.65, 0.8)
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = false
	add_child(sun)


func _player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.collision_layer = 2
	player.collision_mask = 1
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.7
	col.shape = cap
	col.position.y = 0.85
	player.add_child(col)
	var head := Node3D.new()
	head.name = "Head"
	head.position.y = 1.52
	player.add_child(head)
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.current = true
	cam.fov = 72.0
	cam.near = 0.08
	head.add_child(cam)
	var fl := SpotLight3D.new()
	fl.name = "Flashlight"
	fl.spot_range = 14.0
	fl.spot_angle = 38.0
	fl.light_energy = 0.55
	fl.light_color = Color(0.92, 0.95, 1.0)
	fl.shadow_enabled = false
	fl.spot_attenuation = 0.9
	cam.add_child(fl)
	player.set_script(load("res://scripts/player.gd"))
	add_child(player)


func _process(delta: float) -> void:
	if paused or GameState.run_over or GameState.overlay_locked:
		return
	intercom_t -= delta
	if intercom_t <= 0.0:
		intercom_t = randf_range(14.0, 24.0)
		GameState.say(GameState.random_intercom())
	if GameState.joi_mode:
		GameState.add_fixation(0.28 * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		if GameState.overlay_locked:
			return
		if hud.ending.visible:
			return
		set_paused(not paused)


func set_paused(v: bool) -> void:
	paused = v
	get_tree().paused = v
	hud.show_pause(v)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if v else Input.MOUSE_MODE_CAPTURED


# ===== UPDATED FUNCTION =====
func trigger_trap(kind: String, give_key: bool = false, media_path: String = "") -> void:
	if GameState.overlay_locked or GameState.run_over:
		return

	match kind:
		"fracture", "floor", "word":
			if shatter.has_method("begin"):
				shatter.begin(kind, give_key)
		"spiral", "goon", "goddess":
			if spiral.has_method("begin"):
				spiral.begin(kind, give_key, media_path)
		"screen":
			GameState.say("The glass wants your eyes. Keep walking.")
			GameState.add_fixation(7.0)
		_:
			GameState.say(GameState.random_joi())
			GameState.add_fixation(6.0)


func _on_trap_finished(success: bool) -> void:
	if player and player.has_method("set_locked"):
		player.set_locked(false)


func on_exit_reached() -> void:
	if GameState.keys < GameState.KEYS_NEEDED:
		return
	if GameState.level >= GameState.LEVELS_TO_WIN:
		GameState.win()
		show_ending(true)
		return
	GameState.next_level()
	_rebuild_maze()
	GameState.overlay_locked = false
	if player:
		player.set_locked(false)


func show_ending(won: bool) -> void:
	GameState.overlay_locked = true
	if player:
		player.set_locked(true)
	hud.show_ending(won)
