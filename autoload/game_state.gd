extends Node

signal keys_changed(count: int)
signal fixation_changed(value: float)
signal subtitle(text: String)
signal run_reset()
signal level_changed(level: int)

const KEYS_NEEDED := 3
const FIXATION_MAX := 100.0
const LEVELS_TO_WIN := 3

var keys: int = 0
var fixation: float = 0.0
var mouse_sens: float = 0.0022
var reduce_flashes: bool = false
var overlay_locked: bool = false
var run_over: bool = false
var won: bool = false
var joi_mode: bool = false
var level: int = 1
var looking_at_feed: bool = false

var intercom_lines := [
	"There is nowhere else you were supposed to be.",
	"The corridor remembers your footsteps.",
	"Keep walking. Looking is optional. You will look anyway.",
	"Three keys. That is the story you tell yourself.",
	"The screens are patient. They can wait longer than you can.",
	"If you feel warm, that is just the lights. Sure.",
	"Breathe with the hum. It is already counting for you.",
	"You can leave when you have earned the door. Not before.",
	"It's just a video. It's just a silly screen.",
	"There is a lot going on. You can handle it. Mostly.",
]

var joi_lines := [
	"Slow. Match the pulse in the floor.",
	"Do not rush the edge. Let it sit in your hands.",
	"Eyes on the glow. Hands where they want to be.",
	"Good. Stay in that loop. Again.",
	"If you finish now you fail the room. Hold.",
	"Count with me. One. Two. Not yet.",
	"Leak a little focus. That is allowed. The maze likes it.",
	"When I say wait, you wait. When I say look, you look.",
	"Your hand moved. That's alright. Put it back.",
]

var resist_words := ["AWAKE", "FOCUS", "OUT", "BREATHE", "STAY", "CLEAR", "LEAVE"]

var shatter_lines := [
	"It is only a hallway. Prove it.",
	"Click the rings if you still think you choose.",
	"Type the word like you mean it.",
	"Do not move. Motion tells me you are still fighting.",
	"Your eyes want the pretty thing. Steal them back.",
	"Don't move your eyes — hold. Fight. Repeat.",
	"Play the stubborn game. Five seconds. Then another.",
]


func reset_run() -> void:
	keys = 0
	fixation = 8.0 if joi_mode else 0.0
	overlay_locked = false
	run_over = false
	won = false
	level = 1
	looking_at_feed = false
	keys_changed.emit(keys)
	fixation_changed.emit(fixation)
	level_changed.emit(level)
	run_reset.emit()


func next_level() -> void:
	keys = 0
	level += 1
	add_fixation(6.0)
	keys_changed.emit(keys)
	level_changed.emit(level)
	say("Wing %d. The lights learned your name." % level)


func add_key() -> void:
	keys = mini(keys + 1, KEYS_NEEDED)
	keys_changed.emit(keys)
	say("Eve key %d of %d. The door noticed." % [keys, KEYS_NEEDED])


func add_fixation(amount: float) -> void:
	if run_over:
		return
	fixation = clampf(fixation + amount, 0.0, FIXATION_MAX)
	fixation_changed.emit(fixation)
	if fixation >= FIXATION_MAX:
		lose()


func say(text: String) -> void:
	subtitle.emit(text)


func win() -> void:
	if run_over:
		return
	run_over = true
	won = true
	say("The lock opens. You still remember your name. Leave.")


func lose() -> void:
	if run_over:
		return
	run_over = true
	won = false
	say("The maze keeps you. That was always an ending.")


func random_word() -> String:
	return resist_words[randi() % resist_words.size()]


func random_joi() -> String:
	return joi_lines[randi() % joi_lines.size()]


func random_intercom() -> String:
	return intercom_lines[randi() % intercom_lines.size()]
