extends CanvasLayer
class_name GameHUD

var keys_label: Label
var fix_label: Label
var sub_label: Label
var bar: ColorRect
var bar_fill: ColorRect
var chrome: ColorRect
var pause_panel: Control
var ending: Control
var ending_title: Label
var ending_body: Label
var level_label: Label
var post: ColorRect


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	GameState.keys_changed.connect(_on_keys)
	GameState.fixation_changed.connect(_on_fix)
	GameState.subtitle.connect(_on_sub)
	GameState.level_changed.connect(_on_level)
	_on_keys(GameState.keys)
	_on_fix(GameState.fixation)
	_on_level(GameState.level)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	post = ColorRect.new()
	post.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pm := ShaderMaterial.new()
	pm.shader = load("res://shaders/post_fx.gdshader")
	post.material = pm
	post.color = Color.WHITE
	root.add_child(post)

	chrome = ColorRect.new()
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.color = Color(0.7, 0.05, 0.4, 0.0)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(chrome)

	keys_label = Label.new()
	keys_label.position = Vector2(28, 22)
	keys_label.add_theme_font_size_override("font_size", 15)
	keys_label.modulate = Color(0.82, 0.86, 0.9, 0.8)
	root.add_child(keys_label)

	level_label = Label.new()
	level_label.position = Vector2(28, 42)
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.modulate = Color(0.55, 0.9, 0.75, 0.7)
	root.add_child(level_label)

	var wrap := Control.new()
	wrap.anchor_left = 0.0
	wrap.anchor_top = 1.0
	wrap.anchor_right = 0.0
	wrap.anchor_bottom = 1.0
	wrap.offset_left = 22
	wrap.offset_top = -108
	wrap.offset_right = 210
	wrap.offset_bottom = -14
	root.add_child(wrap)
	fix_label = Label.new()
	fix_label.add_theme_font_size_override("font_size", 44)
	fix_label.position = Vector2(6, 0)
	fix_label.modulate = Color(0.92, 0.93, 0.95)
	wrap.add_child(fix_label)
	var cap := Label.new()
	cap.text = "FIXATION"
	cap.add_theme_font_size_override("font_size", 11)
	cap.modulate = Color(0.55, 0.7, 0.85, 0.75)
	cap.position = Vector2(8, 46)
	wrap.add_child(cap)
	bar = ColorRect.new()
	bar.color = Color(0.12, 0.14, 0.18, 0.75)
	bar.size = Vector2(132, 4)
	bar.position = Vector2(8, 66)
	wrap.add_child(bar)
	bar_fill = ColorRect.new()
	bar_fill.color = Color(0.75, 0.22, 0.7)
	bar_fill.size = Vector2(0, 4)
	bar_fill.position = Vector2(8, 66)
	wrap.add_child(bar_fill)

	sub_label = Label.new()
	sub_label.anchor_left = 0.18
	sub_label.anchor_right = 0.82
	sub_label.anchor_top = 1.0
	sub_label.anchor_bottom = 1.0
	sub_label.offset_top = -86
	sub_label.offset_bottom = -42
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_label.add_theme_font_size_override("font_size", 18)
	sub_label.add_theme_color_override("font_color", Color(0.93, 0.9, 0.92))
	sub_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	sub_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(sub_label)

	_build_pause(root)
	_build_ending(root)


func _build_pause(root: Control) -> void:
	pause_panel = ColorRect.new()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.color = Color(0.02, 0.02, 0.04, 0.72)
	pause_panel.visible = false
	root.add_child(pause_panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.offset_left = -140
	col.offset_right = 140
	col.offset_top = -80
	col.offset_bottom = 80
	pause_panel.add_child(col)
	var t := Label.new()
	t.text = "PAUSED"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 28)
	col.add_child(t)
	var resume := Button.new()
	resume.text = "Resume"
	resume.pressed.connect(func() -> void: get_tree().call_group("game_root", "set_paused", false))
	col.add_child(resume)
	var menu := Button.new()
	menu.text = "Menu"
	menu.pressed.connect(func() -> void:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	)
	col.add_child(menu)


func _build_ending(root: Control) -> void:
	ending = ColorRect.new()
	ending.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending.color = Color(0.01, 0.0, 0.03, 0.88)
	ending.visible = false
	root.add_child(ending)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -280
	box.offset_right = 280
	box.offset_top = -120
	box.offset_bottom = 140
	box.add_theme_constant_override("separation", 16)
	ending.add_child(box)
	ending_title = Label.new()
	ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_title.add_theme_font_size_override("font_size", 40)
	box.add_child(ending_title)
	ending_body = Label.new()
	ending_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_body.add_theme_font_size_override("font_size", 18)
	box.add_child(ending_body)
	var b := Button.new()
	b.text = "Return to menu"
	b.pressed.connect(func() -> void:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	)
	box.add_child(b)


func _on_keys(n: int) -> void:
	keys_label.text = "EVE KEYS  %d / %d" % [n, GameState.KEYS_NEEDED]


func _on_level(n: int) -> void:
	level_label.text = "WING %d / %d" % [n, GameState.LEVELS_TO_WIN]


func _on_fix(v: float) -> void:
	fix_label.text = str(int(round(v)))
	bar_fill.size.x = 132.0 * (v / 100.0)
	chrome.color.a = clampf((v - 35.0) / 140.0, 0.0, 0.32)
	if post.material is ShaderMaterial:
		var sm := post.material as ShaderMaterial
		sm.set_shader_parameter("tint_amt", clampf(v / 180.0, 0.0, 0.45))
		sm.set_shader_parameter("aberration", lerpf(0.0015, 0.008, v / 100.0))
		sm.set_shader_parameter("vignette", lerpf(0.35, 0.7, v / 100.0))


func _on_sub(text: String) -> void:
	sub_label.text = text


func show_pause(v: bool) -> void:
	pause_panel.visible = v


func show_ending(won: bool) -> void:
	ending.visible = true
	if won:
		ending_title.text = "YOU LEFT"
		ending_title.modulate = Color(0.55, 1.0, 0.85)
		ending_body.text = "Three wings. You walked out with your name still attached. The maze will wait."
	else:
		ending_title.text = "KEPT"
		ending_title.modulate = Color(0.95, 0.35, 0.75)
		ending_body.text = "Fixation filled the corridor. The screens have you now. That is an ending too."
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
