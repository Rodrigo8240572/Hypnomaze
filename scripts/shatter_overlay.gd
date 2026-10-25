extends CanvasLayer
class_name ShatterOverlay

signal finished(success: bool)

enum Task { RINGS, WORD, STILL }

var active := false
var task: Task = Task.RINGS
var break_amt := 0.0
var time_left := 8.0
var word := "AWAKE"
var still_fail := 0.0
var title: Label
var prompt: Label
var hint: Label
var bar: ColorRect
var fill: ColorRect
var dim: ColorRect
var word_label: Label
var rings_host: Control
var word_edit: LineEdit
var mantra: Label


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func _build() -> void:
	dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sh := ShaderMaterial.new()
	sh.shader = load("res://shaders/shatter_fx.gdshader")
	dim.material = sh
	dim.color = Color.WHITE
	add_child(dim)

	rings_host = Control.new()
	rings_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rings_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rings_host)

	title = Label.new()
	title.text = "SHATTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 36
	title.offset_bottom = 80
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1, 0.78, 0.86))
	add_child(title)

	mantra = Label.new()
	mantra.text = "Play the stubborn game. It always costs five seconds."
	mantra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mantra.set_anchors_preset(Control.PRESET_CENTER_TOP)
	mantra.anchor_left = 0.15
	mantra.anchor_right = 0.85
	mantra.offset_top = 78
	mantra.offset_bottom = 110
	mantra.add_theme_font_size_override("font_size", 13)
	mantra.modulate = Color(0.85, 0.75, 0.82, 0.85)
	add_child(mantra)

	bar = ColorRect.new()
	bar.color = Color(0.1, 0.08, 0.12, 0.85)
	bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bar.anchor_left = 0.28
	bar.anchor_right = 0.72
	bar.offset_top = 112
	bar.offset_bottom = 124
	add_child(bar)
	fill = ColorRect.new()
	fill.color = Color(0.35, 0.95, 0.7)
	fill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	fill.anchor_right = 0.0
	bar.add_child(fill)

	var cap := Label.new()
	cap.text = "BREAKING FREE  —  SLOWLY"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.set_anchors_preset(Control.PRESET_CENTER_TOP)
	cap.anchor_left = 0.2
	cap.anchor_right = 0.8
	cap.offset_top = 128
	cap.offset_bottom = 148
	cap.add_theme_font_size_override("font_size", 12)
	cap.modulate = Color(0.45, 0.95, 0.75, 0.9)
	add_child(cap)

	prompt = Label.new()
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.set_anchors_preset(Control.PRESET_CENTER_TOP)
	prompt.anchor_left = 0.1
	prompt.anchor_right = 0.9
	prompt.offset_top = 158
	prompt.offset_bottom = 198
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_color_override("font_color", Color(1, 0.55, 0.7))
	add_child(prompt)

	hint = Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.anchor_left = 0.1
	hint.anchor_right = 0.9
	hint.offset_top = -90
	hint.offset_bottom = -40
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 18)
	add_child(hint)

	word_label = Label.new()
	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_label.set_anchors_preset(Control.PRESET_CENTER)
	word_label.offset_left = -200
	word_label.offset_right = 200
	word_label.offset_top = 20
	word_label.offset_bottom = 70
	word_label.add_theme_font_size_override("font_size", 36)
	word_label.visible = false
	add_child(word_label)

	word_edit = LineEdit.new()
	word_edit.visible = false
	word_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_edit.set_anchors_preset(Control.PRESET_CENTER)
	word_edit.offset_left = -120
	word_edit.offset_right = 120
	word_edit.offset_top = 80
	word_edit.offset_bottom = 116
	word_edit.text_changed.connect(_on_typed)
	add_child(word_edit)


func begin(kind: String) -> void:
	active = true
	visible = true
	break_amt = 0.12
	time_left = 9.5
	still_fail = 0.0
	for c in rings_host.get_children():
		c.queue_free()
	if dim.material is ShaderMaterial:
		(dim.material as ShaderMaterial).set_shader_parameter("reduce_flash", 1.0 if GameState.reduce_flashes else 0.0)
		(dim.material as ShaderMaterial).set_shader_parameter("intensity", 0.85)
	match kind:
		"fracture":
			task = Task.RINGS
			prompt.text = "CLICK THE WHITE RINGS"
		"floor":
			task = Task.STILL
			prompt.text = "BE COMPLETELY STILL"
		_:
			task = Task.WORD
			prompt.text = "TYPE THE WORD"
	word = GameState.random_word()
	word_label.visible = task == Task.WORD
	word_edit.visible = task == Task.WORD
	word_label.text = word
	word_edit.text = ""
	hint.text = GameState.shatter_lines[randi() % GameState.shatter_lines.size()]
	GameState.overlay_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if task == Task.WORD:
		word_edit.grab_focus()
	if task == Task.RINGS:
		_spawn_ring()
		_spawn_ring()
		_spawn_ring()


func _process(delta: float) -> void:
	if not active:
		return
	time_left -= delta
	GameState.add_fixation(1.6 * delta)

	if task == Task.STILL:
		var moving := Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() > 0.05
		if moving or Input.get_last_mouse_velocity().length() > 18.0:
			still_fail += delta
			break_amt -= delta * 0.12
			GameState.add_fixation(8.0 * delta)
		else:
			break_amt += delta * 0.16
		hint.text = "Don't fidget. The room drinks movement."

	if task == Task.RINGS and rings_host.get_child_count() < 3 and randf() < 0.04:
		_spawn_ring()

	break_amt = clampf(break_amt, 0.0, 1.0)
	fill.size = Vector2(bar.size.x * break_amt, bar.size.y)

	if break_amt >= 1.0:
		_end(true)
	elif time_left <= 0.0:
		_end(false)


func _spawn_ring() -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(58, 58)
	b.text = " "
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.05)
	sb.border_color = Color(1, 1, 1, 0.95)
	sb.set_border_width_all(3)
	sb.corner_radius_top_left = 30
	sb.corner_radius_top_right = 30
	sb.corner_radius_bottom_left = 30
	sb.corner_radius_bottom_right = 30
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	var vp := get_viewport().get_visible_rect().size
	b.position = Vector2(randf_range(80.0, vp.x - 120.0), randf_range(200.0, vp.y - 160.0))
	b.pressed.connect(func() -> void:
		break_amt += 0.2
		b.queue_free()
	)
	rings_host.add_child(b)


func _on_typed(t: String) -> void:
	if t.to_upper().strip_edges() == word:
		break_amt = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if not active or task != Task.WORD:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER:
			if word_edit.text.to_upper().strip_edges() == word:
				break_amt = 1.0


func _end(success: bool) -> void:
	if not active:
		return
	active = false
	visible = false
	word_edit.release_focus()
	GameState.overlay_locked = false
	if not GameState.run_over:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if success:
		GameState.add_fixation(-14.0)
		GameState.say("The overlay cracks. Keep moving.")
	else:
		GameState.add_fixation(22.0)
		GameState.say("It takes a little more of you. The hallway smiles.")
	finished.emit(success)
