extends CanvasLayer
class_name SpiralOverlay

signal finished(success: bool)

var active := false
var hold := 0.0
var needed := 4.2
var bg: ColorRect
var portrait: ColorRect
var title: Label
var body: Label
var soft: Button
var resist: Button
var vbar: ColorRect
var vfill: ColorRect


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func _build() -> void:
	bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sh := ShaderMaterial.new()
	sh.shader = load("res://shaders/spiral.gdshader")
	bg.material = sh
	bg.color = Color.WHITE
	add_child(bg)

	portrait = ColorRect.new()
	portrait.anchor_left = 0.5
	portrait.anchor_right = 0.5
	portrait.anchor_top = 0.5
	portrait.anchor_bottom = 0.5
	portrait.offset_left = -170
	portrait.offset_right = 170
	portrait.offset_top = -250
	portrait.offset_bottom = 210
	var fm := ShaderMaterial.new()
	fm.shader = load("res://shaders/shatter_fx.gdshader")
	portrait.material = fm
	portrait.color = Color.WHITE
	add_child(portrait)

	var frame := ColorRect.new()
	frame.anchor_left = 0.5
	frame.anchor_right = 0.5
	frame.anchor_top = 0.5
	frame.anchor_bottom = 0.5
	frame.offset_left = -176
	frame.offset_right = 176
	frame.offset_top = -256
	frame.offset_bottom = 216
	frame.color = Color(0.02, 0.01, 0.03, 0.0)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	title = Label.new()
	title.text = "MY EYES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.anchor_left = 0
	title.anchor_right = 1
	title.offset_top = 28
	title.offset_bottom = 82
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.95, 0.72, 1.0))
	add_child(title)

	body = Label.new()
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.anchor_left = 0.15
	body.anchor_right = 0.85
	body.anchor_top = 1.0
	body.anchor_bottom = 1.0
	body.offset_top = -78
	body.offset_bottom = -28
	body.add_theme_font_size_override("font_size", 16)
	add_child(body)

	vbar = ColorRect.new()
	vbar.anchor_left = 0.0
	vbar.anchor_top = 0.22
	vbar.anchor_right = 0.0
	vbar.anchor_bottom = 0.78
	vbar.offset_left = 28
	vbar.offset_right = 40
	vbar.color = Color(0.08, 0.06, 0.1, 0.8)
	add_child(vbar)
	vfill = ColorRect.new()
	vfill.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	vfill.color = Color(0.85, 0.25, 0.75)
	vbar.add_child(vfill)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.offset_left = -200
	row.offset_right = 200
	row.offset_top = 160
	row.offset_bottom = 206
	row.add_theme_constant_override("separation", 20)
	add_child(row)

	soft = Button.new()
	soft.text = "SOFTEN"
	soft.custom_minimum_size = Vector2(140, 40)
	soft.pressed.connect(_on_soften)
	row.add_child(soft)

	resist = Button.new()
	resist.text = "LOOK AWAY"
	resist.custom_minimum_size = Vector2(140, 40)
	resist.pressed.connect(_on_resist)
	row.add_child(resist)


func begin(kind: String) -> void:
	active = true
	visible = true
	hold = 0.0
	needed = 4.2 if kind == "goddess" else 5.2
	if kind == "goon":
		needed = 6.0
	GameState.overlay_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if bg.material is ShaderMaterial:
		(bg.material as ShaderMaterial).set_shader_parameter("reduce_flash", 1.0 if GameState.reduce_flashes else 0.0)
		(bg.material as ShaderMaterial).set_shader_parameter("speed", 0.35 if kind == "goon" else 0.62)
		(bg.material as ShaderMaterial).set_shader_parameter("hole", 0.32)
	if kind == "goon":
		body.text = GameState.random_joi() + "  Hands slow. Eyes on me."
	elif kind == "goddess":
		body.text = "She is only light in a hallway. That is not the same as leaving."
	else:
		body.text = "Your hand moved. That's alright. Put it back on my eyes and leave it there."
	GameState.say(body.text)


func _process(delta: float) -> void:
	if not active:
		return
	hold += delta
	GameState.add_fixation(5.2 * delta)
	var p := clampf(hold / needed, 0.0, 1.0)
	vfill.anchor_top = 1.0 - p
	vfill.offset_top = 0
	vfill.offset_bottom = 0
	if hold >= needed:
		_end(false)


func _on_soften() -> void:
	if not active:
		return
	needed += 2.4
	GameState.add_fixation(10.0)
	body.text = "That's it. Softer. The numbers can wait. The door can wait."
	GameState.say("You chose the pretty thing.")


func _on_resist() -> void:
	if not active:
		return
	_end(true)


func _end(success: bool) -> void:
	if not active:
		return
	active = false
	visible = false
	GameState.overlay_locked = false
	if not GameState.run_over:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if success:
		GameState.add_fixation(-8.0)
		GameState.say("You dragged your eyes off it. Good enough.")
	else:
		GameState.add_fixation(16.0)
		GameState.say("The spiral lets you walk. It does not let you go.")
	finished.emit(success)
