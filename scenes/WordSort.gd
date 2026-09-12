extends Control

# ============================================================
# TRI RAPIDE — mini-jeu de révision vocabulaire
# ------------------------------------------------------------
# Le mot japonais s'affiche en haut. Deux réponses (une correcte,
# une leurre) apparaissent à gauche/droite. Swipe vers la bonne
# avant la fin du timer. Toute la logique de données (tirage
# pondéré, sauvegarde) vit dans l'autoload WordDB.
# ============================================================

const ROUND_TIME := 4.0
const SWIPE_MIN_DISTANCE := 80.0

@onready var kanji_label: Label = $VBox/KanjiLabel
@onready var left_answer_label: Label = $VBox/AnswersRow/LeftAnswer
@onready var right_answer_label: Label = $VBox/AnswersRow/RightAnswer
@onready var timer_bar: ProgressBar = $VBox/TimerBar
@onready var score_label: Label = $VBox/ScoreLabel
@onready var back_button: Button = $BackButton

var current_word: Dictionary = {}
var left_is_correct: bool = false
var round_time_left: float = ROUND_TIME
var round_active: bool = false
var score: int = 0

var swipe_start_pos: Vector2 = Vector2.ZERO
var swipe_tracking: bool = false


func _ready() -> void:
	randomize()
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	if WordDB.count() < 2:
		kanji_label.text = "Pas assez de mots dans la base."
		return
	_start_round()


func _process(delta: float) -> void:
	if not round_active:
		return
	round_time_left -= delta
	timer_bar.value = max(round_time_left / ROUND_TIME, 0.0) * 100.0
	if round_time_left <= 0.0:
		_resolve_round(false)


func _start_round() -> void:
	current_word = WordDB.pick_weighted_word()
	var decoy = WordDB.pick_decoy(current_word.get("id"))

	kanji_label.text = current_word.get("kanji", "")

	left_is_correct = randi() % 2 == 0
	# Alterne aléatoirement entre tester la lecture et le sens.
	var field := "reading" if randi() % 2 == 0 else "meaning"

	if left_is_correct:
		left_answer_label.text = current_word.get(field, "")
		right_answer_label.text = decoy.get(field, "")
	else:
		left_answer_label.text = decoy.get(field, "")
		right_answer_label.text = current_word.get(field, "")

	round_time_left = ROUND_TIME
	round_active = true


func _resolve_round(correct: bool) -> void:
	round_active = false
	WordDB.update_stats(current_word.get("id"), correct)

	if correct:
		score += 1
	score_label.text = "Score : %d" % score

	# TODO: feedback visuel/sonore (flash vert/rouge) avant la manche suivante.
	await get_tree().create_timer(0.4).timeout
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

	var swiped_left := delta.x < 0
	var chose_correct := swiped_left == left_is_correct
	_resolve_round(chose_correct)
