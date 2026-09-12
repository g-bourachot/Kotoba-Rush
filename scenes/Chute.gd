extends Control

# ============================================================
# CHUTE — mini-jeu de révision vocabulaire
# ------------------------------------------------------------
# Le kanji cible s'affiche en haut. Plusieurs réponses (une
# correcte, les autres leurres) tombent en colonnes depuis le
# haut de l'écran. Il faut toucher la bonne avant qu'elle
# atteigne le sol.
# ============================================================

const GAME_ID := "chute"
const FALL_ITEMS_COUNT := 3
const FALL_SPEED := 140.0
const ITEM_SIZE := Vector2(180, 64)
const STAGGER_OFFSET := 220.0
const ROUND_END_DELAY := 0.7

@onready var kanji_label: Label = $KanjiLabel
@onready var score_label: Label = $ScoreLabel
@onready var best_score_label: Label = $BestScoreLabel
@onready var play_field: Control = $PlayField
@onready var back_button: Button = $BackButton

var current_word: Dictionary = {}
var falling_buttons: Array[Button] = []
var falling_is_correct: Array[bool] = []
var falling_y: Array[float] = []
var falling_active: Array[bool] = []
var round_active: bool = false
var score: int = 0
var best_score: int = 0
var ground_y: float = 0.0


func _ready() -> void:
	randomize()
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))

	best_score = Settings.get_best_score(GAME_ID)
	best_score_label.text = "Meilleur score : %d" % best_score

	if WordDB.count() < FALL_ITEMS_COUNT:
		kanji_label.text = "Pas assez de mots dans la base."
		return

	ground_y = play_field.size.y - ITEM_SIZE.y
	_start_round()


func _process(delta: float) -> void:
	if not round_active:
		return

	for i in range(falling_buttons.size()):
		if not falling_active[i]:
			continue
		falling_y[i] += FALL_SPEED * delta
		falling_buttons[i].position.y = falling_y[i]
		if falling_y[i] >= ground_y:
			falling_active[i] = false
			falling_buttons[i].position.y = ground_y
			if falling_is_correct[i]:
				_resolve_round(false, i)
				return


func _start_round() -> void:
	round_active = false
	for b in falling_buttons:
		b.queue_free()
	falling_buttons.clear()
	falling_is_correct.clear()
	falling_y.clear()
	falling_active.clear()

	current_word = WordDB.pick_weighted_word()
	var field: String = "reading" if randi() % 2 == 0 else "meaning"
	kanji_label.text = current_word.get("kanji", "")

	var decoys: Array = WordDB.pick_decoys(current_word.get("id"), FALL_ITEMS_COUNT - 1)
	var entries: Array = [{"word": current_word, "is_correct": true}]
	for d in decoys:
		entries.append({"word": d, "is_correct": false})
	entries.shuffle()

	var lane_width: float = play_field.size.x / entries.size()

	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var word: Dictionary = entry["word"]

		var btn := Button.new()
		btn.text = word.get(field, "")
		btn.custom_minimum_size = ITEM_SIZE
		btn.size = ITEM_SIZE
		btn.clip_text = true
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

		var x: float = lane_width * i + (lane_width - ITEM_SIZE.x) / 2.0
		var start_y: float = -(ITEM_SIZE.y + i * STAGGER_OFFSET)
		btn.position = Vector2(x, start_y)
		play_field.add_child(btn)

		falling_buttons.append(btn)
		falling_is_correct.append(entry["is_correct"])
		falling_y.append(start_y)
		falling_active.append(true)

		var idx: int = falling_buttons.size() - 1
		btn.pressed.connect(_on_item_pressed.bind(idx))

	score_label.text = "Score : %d" % score
	round_active = true


func _on_item_pressed(idx: int) -> void:
	if not round_active or not falling_active[idx]:
		return
	_resolve_round(falling_is_correct[idx], idx)


func _resolve_round(correct: bool, triggered_idx: int) -> void:
	round_active = false
	for b in falling_buttons:
		b.disabled = true

	falling_buttons[triggered_idx].modulate = Color(0.4, 0.9, 0.4) if correct else Color(0.9, 0.4, 0.4)
	if not correct:
		var correct_idx: int = falling_is_correct.find(true)
		if correct_idx >= 0 and correct_idx != triggered_idx:
			falling_buttons[correct_idx].modulate = Color(0.4, 0.6, 1.0)

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

	await get_tree().create_timer(ROUND_END_DELAY).timeout
	_start_round()
