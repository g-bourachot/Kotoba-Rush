extends Control

# ============================================================
# PHRASE À TROUS — mini-jeu de révision vocabulaire
# ------------------------------------------------------------
# Une phrase japonaise avec un mot manquant s'affiche. Il faut
# choisir, parmi 3 kanji proposés, celui qui rend la phrase
# cohérente en SENS — jamais de traduction affichée, le joueur
# doit se rappeler ce que le mot veut dire pour juger.
# ------------------------------------------------------------
# Contenu (data/sentences.json) : banc de phrases pré-écrites,
# indépendant du word_db.json (qui reste synchronisé avec Notion).
# Chaque entrée référence un word_id (mot ciblé) et deux decoy_ids
# (leurres choisis à la main pour rester grammaticalement plausibles).
# ============================================================

const GAME_ID := "trou"
const SENTENCES_PATH := "res://data/sentences.json"

@onready var sentence_label: Label = $VBox/SentenceLabel
@onready var choice_buttons: Array[Button] = [
	$VBox/ChoicesRow/Choice1,
	$VBox/ChoicesRow/Choice2,
	$VBox/ChoicesRow/Choice3,
]
@onready var feedback_label: Label = $VBox/FeedbackLabel
@onready var next_button: Button = $VBox/NextButton
@onready var score_label: Label = $VBox/ScoreLabel
@onready var best_score_label: Label = $VBox/BestScoreLabel
@onready var back_button: Button = $BackButton

var sentences: Array = []
var current_target_id = null
var choice_word_ids: Array = []
var round_active: bool = false
var score: int = 0
var best_score: int = 0


func _ready() -> void:
	randomize()
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))

	for i in range(choice_buttons.size()):
		choice_buttons[i].pressed.connect(_on_choice_pressed.bind(i))

	next_button.pressed.connect(_on_next_pressed)
	next_button.visible = false

	best_score = Settings.get_best_score(GAME_ID)
	best_score_label.text = "Meilleur score : %d" % best_score

	_load_sentences()

	if sentences.is_empty():
		sentence_label.text = "Aucune phrase disponible pour l'instant."
		return

	_start_round()


func _load_sentences() -> void:
	if not FileAccess.file_exists(SENTENCES_PATH):
		sentences = []
		return
	var f := FileAccess.open(SENTENCES_PATH, FileAccess.READ)
	var content := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(content)
	sentences = parsed if typeof(parsed) == TYPE_ARRAY else []


func _find_word(word_id) -> Dictionary:
	for w in WordDB.words:
		if w.get("id") == word_id:
			return w
	return {}


func _start_round() -> void:
	round_active = false
	feedback_label.text = ""
	next_button.visible = false
	for b in choice_buttons:
		b.disabled = false
		b.modulate = Color(1, 1, 1)

	var entry: Dictionary = sentences[randi() % sentences.size()]
	current_target_id = entry.get("word_id")

	sentence_label.text = entry.get("sentence", "")

	choice_word_ids = [current_target_id]
	for d in entry.get("decoy_ids", []):
		choice_word_ids.append(d)
	choice_word_ids.shuffle()

	for i in range(choice_buttons.size()):
		if i < choice_word_ids.size():
			var w: Dictionary = _find_word(choice_word_ids[i])
			choice_buttons[i].text = w.get("kanji", "?")
			choice_buttons[i].visible = true
		else:
			choice_buttons[i].visible = false

	score_label.text = "Score : %d" % score
	round_active = true


func _on_choice_pressed(idx: int) -> void:
	if not round_active:
		return
	round_active = false

	var correct: bool = choice_word_ids[idx] == current_target_id

	for b in choice_buttons:
		b.disabled = true

	choice_buttons[idx].modulate = Color(0.4, 0.9, 0.4) if correct else Color(0.9, 0.4, 0.4)
	if not correct:
		var correct_idx: int = choice_word_ids.find(current_target_id)
		if correct_idx >= 0 and correct_idx != idx:
			choice_buttons[correct_idx].modulate = Color(0.4, 0.6, 1.0)

	WordDB.update_stats(current_target_id, correct)
	if correct:
		score += 1
		if score > best_score:
			best_score = score
			Settings.save_best_score(GAME_ID, best_score)
			best_score_label.text = "Meilleur score : %d" % best_score
	else:
		score = 0
	score_label.text = "Score : %d" % score

	var target_word: Dictionary = _find_word(current_target_id)
	feedback_label.text = "%s (%s) — %s" % [
		target_word.get("kanji", ""),
		target_word.get("reading", ""),
		target_word.get("meaning", ""),
	]

	next_button.visible = true


func _on_next_pressed() -> void:
	_start_round()
