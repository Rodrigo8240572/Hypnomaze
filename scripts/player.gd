extends CharacterBody3D

const WALK := 4.05
const SPRINT := 6.4
const GRAVITY := 22.0

@onready var head: Node3D = $Head
@onready var cam: Camera3D = $Head/Camera3D
@onready var light: SpotLight3D = $Head/Camera3D/Flashlight

var bob_t := 0.0
var locked := false
var stare := 0.0


func _ready() -> void:
	add_to_group("player")


func set_locked(v: bool) -> void:
	locked = v
	if v:
		velocity = Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if locked or GameState.overlay_locked or GameState.run_over:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * GameState.mouse_sens)
		head.rotate_x(-event.relative.y * GameState.mouse_sens)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	if locked or GameState.overlay_locked or GameState.run_over:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var sluggish := remap(GameState.fixation, 0.0, 100.0, 1.0, 0.48)
	var spd := (SPRINT if Input.is_action_pressed("sprint") else WALK) * sluggish
	if wish != Vector3.ZERO:
		velocity.x = wish.x * spd
		velocity.z = wish.z * spd
		bob_t += delta * spd * 1.6
	else:
		velocity.x = move_toward(velocity.x, 0.0, spd * 6.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, spd * 6.0 * delta)

	move_and_slide()
	var bob := sin(bob_t) * 0.028
	cam.position.y = bob
	cam.fov = lerpf(72.0, 58.0, GameState.fixation / 100.0)
	light.light_energy = lerpf(0.55, 0.2, GameState.fixation / 100.0)
	light.shadow_enabled = false
	_gaze(delta)


func _gaze(delta: float) -> void:
	var space := get_world_3d().direct_space_state
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * 10.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 4
	q.collide_with_areas = true
	var hit := space.intersect_ray(q)
	if hit and hit.collider:
		var n: Object = hit.collider
		if n.has_meta("heat_source") and bool(n.get_meta("heat_source")):
			GameState.looking_at_feed = true
			stare += delta
			var heat := 4.5 + GameState.level * 0.8
			if GameState.joi_mode:
				heat += 2.0
			GameState.add_fixation(heat * delta)
			if stare > 2.8 and not GameState.overlay_locked:
				var kind := "screen"
				if n.has_meta("kind"):
					kind = String(n.get_meta("kind"))
				stare = 0.0
				get_tree().call_group("game_root", "trigger_trap", kind)
			return
	GameState.looking_at_feed = false
	stare = move_toward(stare, 0.0, delta * 1.4)
