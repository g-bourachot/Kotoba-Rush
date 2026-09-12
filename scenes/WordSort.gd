extends Control

# ============================================================
# TRI RAPIDE — mini-jeu de révision vocabulaire
# ------------------------------------------------------------
# Le mot japonais s'affiche en haut. Deux réponses (une correcte,
# une leurre) apparaissent à gauche/droite. Swipe vers la bonne
# avant la fin du timer. Toute la logique de données (tirage
# pondéré, sauvegarde) vit dans l'autoload WordDB. Le temps par
# manche est réglable (slider) et persisté via l'autoload Settings.
# ============================================================

const GAME_ID := "wordsort"
const SWIPE_MIN_DISTANCE := 80.0
const MIN_ROUND_TIME := 2.0
const MAX_ROUND_TIME := 10.0

@onready var time_slider: HSlider = $VBox/SettingsRow/TimeSlider
@onready var time_value_label: Label = $VBox/SettingsRow/TimeValueLabel
@onready var kanji_label: Label = $VBox/KanjiLabel
@onready var left_answer_label: Label = $VBox/AnswersRow/LeftAnswer
@onready var right_answer_label: Label = $VBox/AnswersRow/RightAnswer
@onready var timer_bar: ProgressBar = $VBox/TimerBar
@onready var feedback_label: Label = $VBox/FeedbackLabel
@onready var next_button: Button = $VBox/NextButton
@onready var score_label: Label = $VBox/ScoreLabel
@onready var best_score_label: Label = $VBox/BestScoreLabel
@onready var back_button: Button = $BackButton

var round_time: float = 6.0
var current_word: Dictionary = {}
var left_is_correct: bool = false
var round_time_left: float = 0.0
var round_active: bool = false
var score: int = 0
var best_score: int = 0

var swipe_start_pos: Vector2 = Vector2.ZERO
var swipe_tracking: bool = false


func _ready() -> void:
	randomize()
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))

	round_time = Settings.round_time
	time_slider.min_value = MIN_ROUND_TIME
	time_slider.max_value = MAX_ROUND_TIME
	time_slider.step = 0.5
	time_slider.value = round_time
	time_slider.value_changed.connect(_on_time_slider_changed)
	_update_time_label()

	next_button.pressed.connect(_on_next_pressed)
	next_button.visible = false

	best_score = Settings.get_best_score(GAME_ID)
	best_score_label.text = "Meilleur score : %d" % best_score

	if WordDB.count() < 2:
		kanji_label.text = "Pas assez de mots dans la base."
		return
	_start_round()


func _on_time_slider_changed(value: float) -> void:
	round_time = value
	Settings.save_round_time(value)
	_update_time_label()


func _update_time_label() -> void:
	time_value_label.text = "%.1fs" % round_time


func _process(delta: float) -> void:
	if not round_active:
		return
	round_time_left -= delta
	timer_bar.value = max(round_time_left / round_time, 0.0) * 100.0
	if round_time_left <= 0.0:
		_resolve_round(false, -1)


func _start_round() -> void:
	feedback_label.text = ""
	next_button.visible = false
	left_answer_label.modulate = Color(1, 1, 1)
	right_answer_label.modulate = Color(1, 1, 1)

	current_word = WordDB.pick_weighted_word()
	var decoy = WordDB.pick_decoy(current_word.get("id"))

	kanji_label.text = current_word.get("kanji", "")
	FX.punch_scale(kanji_label)

	left_is_correct = randi() % 2 == 0
	# Alterne aléatoirement entre tester la lecture et le sens.
	var field := "reading" if randi() % 2 == 0 else "meaning"

	if left_is_correct:
		left_answer_label.text = current_word.get(field, "")
		right_answer_label.text = decoy.get(field, "")
	else:
		left_answer_label.text = decoy.get(field, "")
		right_answer_label.text = current_word.get(field, "")

	round_time_left = round_time
	round_active = true


# chosen_side : 0 = gauche, 1 = droite, -1 = temps écoulé sans choix.
func _resolve_round(correct: bool, chosen_side: int) -> void:
	round_active = false
	WordDB.update_stats(current_word.get("id"), correct)

	if correct:
		score += 1
		if score > best_score:
			best_score = score
			Settings.save_best_score(GAME_ID, best_score)
			best_score_label.text = "Meilleur score : %d" % best_score
	else:
		score = 0
	score_label.text = "Score : %d" % score

	var correct_label: Label = left_answer_label if left_is_correct else right_answer_label
	var chosen_label: Label = null
	if chosen_side == 0:
		chosen_label = left_answer_label
	elif chosen_side == 1:
		chosen_label = right_answer_label

	if chosen_label:
		chosen_label.modulate = UITheme.COLOR_CORRECT if correct else UITheme.COLOR_WRONG
		FX.punch_scale(chosen_label)
	if not correct:
		correct_label.modulate = UITheme.COLOR_REVEAL
		FX.shake(kanji_label)

	feedback_label.text = "%s (%s) — %s" % [
		current_word.get("kanji", ""),
		current_word.get("reading", ""),
		current_word.get("meaning", ""),
	]

	next_button.visible = true


func _on_next_pressed() -> void:
	_start_round()


func _input(event: InputEvent) -> void:
	if not round_active:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start_pos = event.position
			swipe_tracking = true
		else:
			if swipe_tracking:
				_handle_swipe_end(event.position)
			swipe_tracking = false
	# Fallback souris pour tester dans l'éditeur Godot (desktop).
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			swipe_start_pos = event.position
			swipe_tracking = true
		else:
			if swipe_tracking:
				_handle_swipe_end(event.position)
			swipe_tracking = false


func _handle_swipe_end(end_pos: Vector2) -> void:
	var delta: Vector2 = end_pos - swipe_start_pos
	if abs(delta.x) < SWIPE_MIN_DISTANCE:
		return

	var swiped_left: bool = delta.x < 0
	var chose_correct: bool = swiped_left == left_is_correct
	_resolve_round(chose_correct, 0 if swiped_left else 1)
