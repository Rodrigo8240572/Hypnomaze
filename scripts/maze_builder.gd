extends Node3D
class_name MazeBuilder

const N := 1
const E := 2
const S := 4
const W := 8

@export var width := 11
@export var height := 11
@export var cell_size := 5.4
@export var wall_h := 3.55
@export var wall_t := 0.18

var grid: Array = []
var start_cell := Vector2i(0, 0)
var exit_cell := Vector2i(10, 10)
var key_cells: Array[Vector2i] = []
var trap_cells: Array[Dictionary] = []

var wall_mat: ShaderMaterial
var wall_accent: ShaderMaterial
var floor_mat: ShaderMaterial
var neon_mat: ShaderMaterial
var screen_mat_a: ShaderMaterial
var screen_mat_b: ShaderMaterial
var ceil_mat: StandardMaterial3D
var frame_mat: StandardMaterial3D


func configure_for_level(level: int) -> void:
	width = 9 + mini(level, 3) * 2
	height = width


func build() -> void:
	_make_mats()
	_carve()
	_place_specials()
	_build_geometry()
	_spawn_props()


func cell_to_world(c: Vector2i) -> Vector3:
	return Vector3((c.x + 0.5) * cell_size, 0.0, (c.y + 0.5) * cell_size)


func _make_mats() -> void:
	wall_mat = ShaderMaterial.new()
	wall_mat.shader = load("res://shaders/wall.gdshader")
	wall_accent = wall_mat.duplicate()
	wall_accent.set_shader_parameter("accent_mix", 0.55)
	floor_mat = ShaderMaterial.new()
	floor_mat.shader = load("res://shaders/floor.gdshader")
	neon_mat = ShaderMaterial.new()
	neon_mat.shader = load("res://shaders/neon.gdshader")
	screen_mat_a = ShaderMaterial.new()
	screen_mat_a.shader = load("res://shaders/screen_feed.gdshader")
	screen_mat_b = screen_mat_a.duplicate()
	screen_mat_b.set_shader_parameter("style", 1)
	ceil_mat = StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.07, 0.072, 0.078)
	ceil_mat.roughness = 0.9
	frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.02, 0.02, 0.025)
	frame_mat.metallic = 0.7
	frame_mat.roughness = 0.35


func _carve() -> void:
	grid.clear()
	grid.resize(width)
	for x in width:
		grid[x] = []
		grid[x].resize(height)
		for y in height:
			grid[x][y] = 0
	var stack: Array[Vector2i] = []
	var visited := {}
	var cur := Vector2i(0, 0)
	visited[cur] = true
	stack.append(cur)
	var dirs := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	var bits := {Vector2i(0, -1): N, Vector2i(1, 0): E, Vector2i(0, 1): S, Vector2i(-1, 0): W}
	var opp := {N: S, E: W, S: N, W: E}
	while not stack.is_empty():
		cur = stack.back()
		var opts: Array[Vector2i] = []
		for d in dirs:
			var n: Vector2i = cur + d
			if n.x < 0 or n.y < 0 or n.x >= width or n.y >= height:
				continue
			if visited.has(n):
				continue
			opts.append(d)
		if opts.is_empty():
			stack.pop_back()
			continue
		var d: Vector2i = opts[randi() % opts.size()]
		var nxt: Vector2i = cur + d
		grid[cur.x][cur.y] |= bits[d]
		grid[nxt.x][nxt.y] |= opp[bits[d]]
		visited[nxt] = true
		stack.append(nxt)
	start_cell = Vector2i(0, 0)
	exit_cell = Vector2i(width - 1, height - 1)


func _place_specials() -> void:
	var dead: Array[Vector2i] = []
	for x in width:
		for y in height:
			var opens := _open_count(Vector2i(x, y))
			var c := Vector2i(x, y)
			if opens == 1 and c != start_cell and c != exit_cell:
				dead.append(c)
	dead.shuffle()
	key_cells.clear()
	for i in mini(3, dead.size()):
		key_cells.append(dead[i])
	trap_cells.clear()
	var used := {}
	used[start_cell] = true
	used[exit_cell] = true
	for k in key_cells:
		used[k] = true
	var kinds := ["fracture", "spiral", "goon", "floor", "screen", "goddess", "word"]
	var trap_n := 6 + GameState.level * 2
	var cells: Array[Vector2i] = []
	for x in width:
		for y in height:
			var c := Vector2i(x, y)
			if used.has(c):
				continue
			cells.append(c)
	cells.shuffle()
	var placed := 0
	for c in cells:
		if placed >= trap_n:
			break
		trap_cells.append({"cell": c, "kind": kinds[placed % kinds.size()]})
		used[c] = true
		placed += 1


func _open_count(c: Vector2i) -> int:
	var g: int = grid[c.x][c.y]
	var opens := 0
	if g & N: opens += 1
	if g & E: opens += 1
	if g & S: opens += 1
	if g & W: opens += 1
	return opens


func _build_geometry() -> void:
	var world_w := width * cell_size
	var world_h := height * cell_size
	_box(Vector3(world_w * 0.5, -0.06, world_h * 0.5), Vector3(world_w + 1.2, 0.12, world_h + 1.2), floor_mat)
	_box(Vector3(world_w * 0.5, wall_h + 0.06, world_h * 0.5), Vector3(world_w + 1.2, 0.12, world_h + 1.2), ceil_mat)

	for x in width:
		for y in height:
			var g: int = grid[x][y]
			var cx := (x + 0.5) * cell_size
			var cz := (y + 0.5) * cell_size
			var accent := _cell_is_accent(Vector2i(x, y))
			var mat := wall_accent if accent else wall_mat
			if not (g & N):
				_wall(Vector3(cx, wall_h * 0.5, y * cell_size), Vector3(cell_size + wall_t, wall_h, wall_t), mat)
			if not (g & W):
				_wall(Vector3(x * cell_size, wall_h * 0.5, cz), Vector3(wall_t, wall_h, cell_size + wall_t), mat)
			if x == width - 1 and not (g & E):
				_wall(Vector3(width * cell_size, wall_h * 0.5, cz), Vector3(wall_t, wall_h, cell_size + wall_t), mat)
			if y == height - 1 and not (g & S):
				_wall(Vector3(cx, wall_h * 0.5, height * cell_size), Vector3(cell_size + wall_t, wall_h, wall_t), mat)

	for x in width:
		for y in height:
			var g: int = grid[x][y]
			var cx := (x + 0.5) * cell_size
			var cz := (y + 0.5) * cell_size
			_neon_strip(Vector3(cx, 0.03, y * cell_size + 0.08), Vector3(cell_size * 0.9, 0.04, 0.07))
			_neon_strip(Vector3(x * cell_size + 0.08, 0.03, cz), Vector3(0.07, 0.04, cell_size * 0.9))
			if x == width - 1:
				_neon_strip(Vector3(width * cell_size - 0.08, 0.03, cz), Vector3(0.07, 0.04, cell_size * 0.9))
			if y == height - 1:
				_neon_strip(Vector3(cx, 0.03, height * cell_size - 0.08), Vector3(cell_size * 0.9, 0.04, 0.07))

	for x in range(0, width, 2):
		for y in range(0, height, 2):
			var lamp := OmniLight3D.new()
			lamp.light_color = Color(0.85, 0.9, 0.95)
			lamp.light_energy = 0.85
			lamp.omni_range = 8.5
			lamp.omni_attenuation = 1.4
			lamp.position = cell_to_world(Vector2i(x, y)) + Vector3(0, 2.85, 0)
			lamp.shadow_enabled = false
			add_child(lamp)
			var fixture := MeshInstance3D.new()
			var fm := BoxMesh.new()
			fm.size = Vector3(0.35, 0.08, 0.35)
			fixture.mesh = fm
			var fmat := StandardMaterial3D.new()
			fmat.albedo_color = Color(0.9, 0.92, 0.95)
			fmat.emission_enabled = true
			fmat.emission = Color(0.8, 0.85, 0.9)
			fmat.emission_energy_multiplier = 2.2
			fixture.material_override = fmat
			fixture.position = lamp.position + Vector3(0, 0.4, 0)
			add_child(fixture)


func _cell_is_accent(c: Vector2i) -> bool:
	for t in trap_cells:
		if t["cell"] == c and String(t["kind"]) in ["screen", "spiral", "goon", "goddess"]:
			return true
	return false


func _wall(pos: Vector3, size: Vector3, mat: Material) -> void:
	_box(pos, size, mat, true)


func _neon_strip(pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = neon_mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _box(pos: Vector3, size: Vector3, mat: Material, collide: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var col := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		col.shape = sh
		body.add_child(col)
		mi.add_child(body)
	return mi


func _spawn_props() -> void:
	for i in key_cells.size():
		_spawn_key(key_cells[i], i)
	_spawn_exit(exit_cell)
	for t in trap_cells:
		_spawn_trap(t["cell"], String(t["kind"]))
	_spawn_start_glyph(start_cell)


func _spawn_key(cell: Vector2i, idx: int) -> void:
	var root := Area3D.new()
	root.name = "EveKey_%d" % idx
	root.position = cell_to_world(cell) + Vector3(0, 0.0, 0)
	root.collision_layer = 4
	root.collision_mask = 2
	root.monitoring = true
	root.body_entered.connect(_on_key_body.bind(root))
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.85
	col.shape = sph
	col.position.y = 0.7
	root.add_child(col)

	var pedestal := MeshInstance3D.new()
	var pmesh := CylinderMesh.new()
	pmesh.top_radius = 0.22
	pmesh.bottom_radius = 0.28
	pmesh.height = 0.72
	pedestal.mesh = pmesh
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.04, 0.045, 0.05)
	pmat.metallic = 0.7
	pmat.roughness = 0.25
	pedestal.material_override = pmat
	pedestal.position = Vector3(0, 0.36, 0)
	root.add_child(pedestal)

	var gem := MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = 0.13
	gm.height = 0.26
	gem.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.55, 1.0, 0.9)
	gmat.emission_enabled = true
	gmat.emission = Color(0.2, 1.0, 0.75)
	gmat.emission_energy_multiplier = 6.0
	gem.material_override = gmat
	gem.position = Vector3(0, 0.88, 0)
	root.add_child(gem)

	var l := OmniLight3D.new()
	l.light_color = Color(0.35, 1.0, 0.82)
	l.light_energy = 2.4
	l.omni_range = 5.5
	l.position = Vector3(0, 0.9, 0)
	root.add_child(l)
	add_child(root)


func _on_key_body(body: Node, root: Area3D) -> void:
	if not body.is_in_group("player"):
		return
	if not is_instance_valid(root):
		return
	root.queue_free()
	GameState.add_key()


func _spawn_exit(cell: Vector2i) -> void:
	var root := Area3D.new()
	root.name = "ExitDoor"
	root.position = cell_to_world(cell) + Vector3(0, 1.15, 0)
	root.collision_mask = 2
	root.body_entered.connect(_on_exit)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.7, 2.5, 1.7)
	col.shape = sh
	root.add_child(col)
	var frame := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(1.9, 2.7, 0.16)
	frame.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.06, 0.08, 0.07)
	fmat.emission_enabled = true
	fmat.emission = Color(0.15, 1.0, 0.45)
	fmat.emission_energy_multiplier = 1.8
	frame.material_override = fmat
	root.add_child(frame)
	var label := Label3D.new()
	label.text = "EXIT"
	label.font_size = 64
	label.modulate = Color(0.35, 1.0, 0.55)
	label.position = Vector3(0, 1.55, 0.12)
	root.add_child(label)
	add_child(root)


func _on_exit(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if GameState.keys >= GameState.KEYS_NEEDED:
		get_tree().call_group("game_root", "on_exit_reached")
	else:
		GameState.say("The door wants %d more keys." % (GameState.KEYS_NEEDED - GameState.keys))


func _spawn_start_glyph(cell: Vector2i) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 1.6)
	mi.mesh = q
	mi.rotation_degrees = Vector3(-90, 0, 0)
	mi.position = cell_to_world(cell) + Vector3(0, 0.02, 0)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/screen_feed.gdshader")
	mat.set_shader_parameter("heat", 0.12)
	mi.material_override = mat
	add_child(mi)


func _closed_wall_basis(cell: Vector2i) -> Dictionary:
	var g: int = grid[cell.x][cell.y]
	var half := cell_size * 0.46
	if not (g & S):
		return {"offset": Vector3(0, 0, half), "yaw": 0.0}
	if not (g & N):
		return {"offset": Vector3(0, 0, -half), "yaw": 180.0}
	if not (g & E):
		return {"offset": Vector3(half, 0, 0), "yaw": -90.0}
	if not (g & W):
		return {"offset": Vector3(-half, 0, 0), "yaw": 90.0}
	return {"offset": Vector3(0, 0, half), "yaw": 0.0}


func _spawn_trap(cell: Vector2i, kind: String) -> void:
	var root := Area3D.new()
	root.name = "Trap_%s_%d_%d" % [kind, cell.x, cell.y]
	root.position = cell_to_world(cell) + Vector3(0, 1.0, 0)
	root.collision_layer = 4
	root.collision_mask = 2
	root.set_meta("kind", kind)
	root.set_meta("armed", true)
	root.set_meta("heat_source", kind in ["screen", "spiral", "goon", "goddess"])

	# ~28% chance this trap hides a key
	var hides_key := false
	if kind in ["spiral", "goon", "goddess", "fracture"] and randf() < 0.28:
		hides_key = true
	root.set_meta("hides_key", hides_key)

	# Media path (leave empty for now, or put a real path later)
	var media_path := ""
	# Example later: media_path = "res://media/trap_01.png"
	root.set_meta("media_path", media_path)

	root.body_entered.connect(_on_trap.bind(root))

	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(cell_size * 0.62, 2.2, cell_size * 0.62)
	col.shape = sh
	root.add_child(col)

	if kind in ["screen", "spiral", "goon", "fracture", "goddess", "word"]:
		var face: Dictionary = _closed_wall_basis(cell)
		var wall_off: Vector3 = face["offset"]
		var inward := -wall_off.normalized() * 0.14
		var yaw: float = face["yaw"]

		var frame := MeshInstance3D.new()
		var fq := QuadMesh.new()
		fq.size = Vector2(2.78, 1.68)
		frame.mesh = fq
		frame.position = wall_off + inward * 0.35 + Vector3(0, 0.25, 0)
		frame.rotation_degrees = Vector3(0, yaw, 0)
		frame.material_override = frame_mat
		root.add_child(frame)

		var panel := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(2.52, 1.46)
		panel.mesh = qm
		panel.position = wall_off + inward * 0.28 + Vector3(0, 0.25, 0)
		panel.rotation_degrees = Vector3(0, yaw, 0)

		if kind in ["screen", "spiral", "goon", "goddess"]:
			panel.material_override = screen_mat_a if randf() < 0.5 else screen_mat_b
		else:
			var pmat := StandardMaterial3D.new()
			pmat.albedo_color = Color(0.08, 0.02, 0.12)
			pmat.emission_enabled = true
			pmat.emission = Color(0.6, 0.1, 0.5)
			pmat.emission_energy_multiplier = 1.8
			panel.material_override = pmat
		root.add_child(panel)

	add_child(root)


func _on_trap(body: Node, root: Area3D) -> void:
	if not body.is_in_group("player"):
		return
	if not root.get_meta("armed", true):
		return

	# Make it one-shot so it doesn't retrigger immediately
	root.set_meta("armed", false)

	var kind: String = String(root.get_meta("kind", "spiral"))
	var hides_key: bool = bool(root.get_meta("hides_key", false))
	var media_path: String = String(root.get_meta("media_path", ""))

	get_tree().call_group("game_root", "trigger_trap", kind, hides_key, media_path)
