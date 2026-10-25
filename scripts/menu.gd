extends Control

var sens: HSlider
var flash: CheckBox
var warn: Label


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.022, 0.03)
	add_child(bg)

	var spiral := ColorRect.new()
	spiral.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/spiral.gdshader")
	sm.set_shader_parameter("speed", 0.18)
	sm.set_shader_parameter("reduce_flash", 0.45)
	sm.set_shader_parameter("hole", 0.0)
	spiral.material = sm
	spiral.modulate = Color(1, 1, 1, 0.42)
	add_child(spiral)

	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.02, 0.01, 0.04, 0.58)
	add_child(veil)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	box.offset_left = 80
	box.offset_top = -250
	box.offset_right = 560
	box.offset_bottom = 280
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var kicker := Label.new()
	kicker.text = "HYPNO MAZE"
	kicker.add_theme_font_size_override("font_size", 16)
	kicker.modulate = Color(0.55, 0.95, 0.82, 0.85)
	box.add_child(kicker)

	var title := Label.new()
	title.text = "SPIRAL\nPROTOCOL"
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.98))
	box.add_child(title)

	var tag := Label.new()
	tag.text = "surrender feels so good"
	tag.add_theme_font_size_override("font_size", 16)
	tag.modulate = Color(0.55, 1.0, 0.82, 0.9)
	box.add_child(tag)

	warn = Label.new()
	warn.text = "18+   flashing lights   adult hypno / JOI themes\nOriginal maze. Not the creator's videos or assets."
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warn.add_theme_font_size_override("font_size", 14)
	warn.modulate = Color(0.75, 0.7, 0.8, 0.85)
	box.add_child(warn)

	box.add_child(_btn("BEGIN", _start.bind(false)))
	box.add_child(_btn("JOI", _start.bind(true)))

	var sens_l := Label.new()
	sens_l.text = "Mouse sensitivity"
	box.add_child(sens_l)
	sens = HSlider.new()
	sens.min_value = 0.0008
	sens.max_value = 0.005
	sens.step = 0.0001
	sens.value = GameState.mouse_sens
	box.add_child(sens)

	flash = CheckBox.new()
	flash.text = "Reduce flashes / slow spirals"
	flash.button_pressed = GameState.reduce_flashes
	box.add_child(flash)

	box.add_child(_btn("QUIT", func() -> void: get_tree().quit()))

	var how := Label.new()
	how.text = "WASD move  •  Shift sprint  •  Mouse look  •  Esc pause\nFind 3 Eve keys each wing. Don't stare. Shatter the traps. Clear 3 wings."
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.add_theme_font_size_override("font_size", 14)
	how.modulate = Color(0.7, 0.75, 0.8, 0.8)
	box.add_child(how)


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.pressed.connect(cb)
	return b


func _start(joi: bool) -> void:
	GameState.mouse_sens = sens.value
	GameState.reduce_flashes = flash.button_pressed
	GameState.joi_mode = joi
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
