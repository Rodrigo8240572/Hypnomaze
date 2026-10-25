extends CanvasLayer

signal finished(success: bool)

var active := false
var watch := 0.0
var kind := "fracture"
var target_clicks := 5
var clicks := 0
var word := ""
var typed := ""
var hold_time := 0.0
var need_hold := 3.5
var rings: Array[Control] = []
var difficulty := 1.0
var awards_key := false

@onready var root: Control
@onready var prompt: Label
@onready var word_label: Label
@onready var progress: ProgressBar
@onready var media_rect: TextureRect   # placeholder for image/video

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

func _build_ui() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.0, 0.04, 0.82)
	root.add_child(bg)

	# Media placeholder (replace texture later with user image/video frame)
	media_rect = TextureRect.new()
	media_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	media_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	media_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	media_rect.modulate = Color(1, 1, 1, 0.55)
	root.add_child(media_rect)

	prompt = Label.new()
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.anchor_left = 0.1
	prompt.anchor_right = 0.9
	prompt.anchor_top = 0.12
	prompt.offset_bottom = 80
	prompt.add_theme_font_size_override("font_size", 28)
	prompt.modulate = Color(0.95, 0.85, 0.95)
	root.add_child(prompt)

	word_label = Label.new()
	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_label.anchor_left = 0.2
	word_label.anchor_right = 0.8
	word_label.anchor_top = 0.45
	word_label.add_theme_font_size_override("font_size", 42)
	word_label.modulate = Color(0.7, 1.0, 0.9)
	root.add_child(word_label)

	progress = ProgressBar.new()
	progress.anchor_left = 0.25
	progress.anchor_right = 0.75
	progress.anchor_top = 0.78
	progress.offset_bottom = 24
	progress.max_value = 1.0
	progress.value = 0.0
	root.add_child(progress)

func begin(k: String = "fracture", give_key: bool = false) -> void:
	if active:
		return
	kind = k
	awards_key = give_key
	active = true
	visible = true
	GameState.overlay_locked = true
	watch = 0.0
	GameState.current_trap_watch = 0.0
	clicks = 0
	typed = ""
	hold_time = 0.0
	difficulty = 1.0
	_clear_rings()

	match kind:
		"word":
			word = GameState.random_word()
			prompt.text = "Type the word. Do not look away."
			word_label.text = "_ " .repeat(word.length())
			word_label.visible = true
		"floor", "fracture":
			prompt.text = "Click the white rings. Order will change."
			word_label.visible = false
			_spawn_rings()
		_:
			prompt.text = "Hold still. Any movement resets the timer."
			word_label.visible = false
			need_hold = 3.2 + difficulty

	# Placeholder media — later load user file here
	# media_rect.texture = load("res://media/placeholder_trap.png")

func _process(delta: float) -> void:
	if not active:
		return
	watch += delta
	GameState.current_trap_watch = watch
	GameState.total_watch_time += delta
	difficulty = GameState.difficulty_from_watch(watch)
	progress.value = clampf(watch / 25.0, 0.0, 1.0)

	# Slow fixation bleed while trapped
	GameState.add_fixation(0.35 * difficulty * delta)

	if kind == "floor" or kind == "fracture":
		# rings already handle clicks
		pass
	elif kind == "word":
		pass
	else:
		# hold still mode
		var moved := Input.get_last_mouse_velocity().length() > 18.0
		if moved:
			hold_time = 0.0
			prompt.text = "You moved. Start over."
		else:
			hold_time += delta
			prompt.text = "Hold still… %.1f" % (need_hold - hold_time)
			if hold_time >= need_hold:
				_succeed()

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.pressed and kind == "word":
		var ch := char(event.unicode).to_upper()
		if ch.length() == 1 and ch.is_valid_identifier():
			typed += ch
			_update_word_display()
			if typed == word:
				_succeed()
			elif not word.begins_with(typed):
				typed = ""
				_update_word_display()
				GameState.add_fixation(4.0)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if kind in ["floor", "fracture"]:
			# simple global click count for now; rings can be improved
			clicks += 1
			if clicks >= target_clicks + int(difficulty * 2):
				_succeed()

func _update_word_display() -> void:
	var display := ""
	for i in word.length():
		if i < typed.length():
			display += typed[i] + " "
		else:
			display += "_ "
	word_label.text = display

func _spawn_rings() -> void:
	_clear_rings()
	target_clicks = 4 + int(difficulty * 2)
	for i in 6:
		var r := ColorRect.new()
		r.size = Vector2(48, 48)
		r.color = Color(1, 1, 1, 0.85)
		r.position = Vector2(randf_range(200, 1000), randf_range(180, 550))
		r.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed:
				r.queue_free()
				clicks += 1
				if clicks >= target_clicks:
					_succeed()
		)
		root.add_child(r)
		rings.append(r)

func _clear_rings() -> void:
	for r in rings:
		if is_instance_valid(r):
			r.queue_free()
	rings.clear()

func _succeed() -> void:
	_end(true)

func _fail() -> void:
	_end(false)

func _end(success: bool) -> void:
	active = false
	visible = false
	GameState.overlay_locked = false
	_clear_rings()
	if success:
		GameState.say("You broke the pattern. Keep moving.")
		if awards_key:
			GameState.add_key()
		# small reward — reduce fixation a bit
		GameState.fixation = maxf(0.0, GameState.fixation - 8.0)
		GameState.fixation_changed.emit(GameState.fixation)
	else:
		GameState.say("The pattern kept you a little longer.")
		GameState.add_fixation(12.0 + difficulty * 4.0)
		if watch > 14.0:
			GameState.install_trigger("soft_eyes")
	finished.emit(success)
