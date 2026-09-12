extends Control

# ============================================================
# PAIRES MÉMOIRE — mini-jeu de révision vocabulaire
# ------------------------------------------------------------
# Écran de config (nombre de paires, réglable) puis grille de
# cartes retournées. Chaque mot occupe deux cartes : une avec
# le kanji, une avec sa lecture OU son sens (au hasard). Il faut
# retrouver les deux cartes d'un même mot. Une paire trouvée
# valide le mot auprès de WordDB (update_stats).
# ============================================================

const MIN_PAIRS := 4
const MAX_PAIRS := 10
const GRID_COLUMNS := 4
const CARD_SIZE := Vector2(150, 140)
const READ_DELAY := 1.4

@onready var setup_panel: VBoxContainer = $SetupPanel
@onready var pairs_slider: HSlider = $SetupPanel/PairsRow/PairsSlider
@onready var pairs_value_label: Label = $SetupPanel/PairsRow/PairsValueLabel
@onready var start_button: Button = $SetupPanel/StartButton

@onready var game_panel: VBoxContainer = $GamePanel
@onready var status_label: Label = $GamePanel/StatusLabel
@onready var grid: GridContainer = $GamePanel/ScrollContainer/CenterContainer/Grid
@onready var restart_button: Button = $GamePanel/RestartButton
@onready var back_button: Button = $BackButton

var pair_count: int = 6

var card_buttons: Array[Button] = []
var card_word_id: Array = []
var card_is_kanji: Array[bool] = []
var card_matched: Array[bool] = []
var card_text: Array[String] = []

var flipped_indices: Array[int] = []
var pairs_found: int = 0
var input_locked: bool = false


func _ready() -> void:
	randomize()
	grid.columns = GRID_COLUMNS
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))

	pair_count = Settings.memory_pairs
	pairs_slider.min_value = MIN_PAIRS
	pairs_slider.max_value = MAX_PAIRS
	pairs_slider.step = 1
	pairs_slider.value = pair_count
	pairs_slider.value_changed.connect(_on_pairs_slider_changed)
	_update_pairs_label()

	start_button.pressed.connect(_show_game)
	restart_button.pressed.connect(_show_setup)

	_show_setup()


func _on_pairs_slider_changed(value: float) -> void:
	pair_count = int(value)
	Settings.save_memory_pairs(pair_count)
	_update_pairs_label()


func _update_pairs_label() -> void:
	pairs_value_label.text = "%d paires (%d cartes)" % [pair_count, pair_count * 2]


func _show_setup() -> void:
	game_panel.visible = false
	setup_panel.visible = true


func _show_game() -> void:
	setup_panel.visible = false
	game_panel.visible = true
	_start_game()


func _start_game() -> void:
	pairs_found = 0
	flipped_indices.clear()
	input_locked = false

	for child in grid.get_children():
		child.queue_free()
	card_buttons.clear()
	card_word_id.clear()
	card_is_kanji.clear()
	card_matched.clear()
	card_text.clear()

	if WordDB.count() < pair_count:
		status_label.text = "Pas assez de mots dans la base."
		return

	var chosen_words: Array = WordDB.pick_weighted_words(pair_count)
	var slots: Array = []
	for w in chosen_words:
		var field: String = "reading" if randi() % 2 == 0 else "meaning"
		slots.append({"word_id": w.get("id"), "text": w.get("kanji", ""), "is_kanji": true})
		slots.append({"word_id": w.get("id"), "text": w.get(field, ""), "is_kanji": false})
	slots.shuffle()

	for slot in slots:
		card_word_id.append(slot["word_id"])
		card_is_kanji.append(slot["is_kanji"])
		card_text.append(slot["text"])
		card_matched.append(false)

		var btn := Button.new()
		btn.custom_minimum_size = CARD_SIZE
		btn.text = "?"
		btn.clip_text = true
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn.add_theme_font_size_override("font_size", 20)
		grid.add_child(btn)
		card_buttons.append(btn)

		var idx: int = card_buttons.size() - 1
		btn.pressed.connect(_on_card_pressed.bind(idx))

	status_label.text = "Paires trouvées : 0 / %d" % pair_count


func _on_card_pressed(idx: int) -> void:
	if input_locked or card_matched[idx] or flipped_indices.has(idx):
		return

	_flip_card(idx, true)
	flipped_indices.append(idx)

	if flipped_indices.size() == 2:
		input_locked = true
		await get_tree().create_timer(READ_DELAY).timeout
		_check_match()


func _flip_card(idx: int, face_up: bool) -> void:
	card_buttons[idx].text = card_text[idx] if face_up else "?"


func _check_match() -> void:
	var a: int = flipped_indices[0]
	var b: int = flipped_indices[1]
	var is_match: bool = card_word_id[a] == card_word_id[b]

	if is_match:
		card_matched[a] = true
		card_matched[b] = true
		card_buttons[a].disabled = true
		card_buttons[b].disabled = true
		WordDB.update_stats(card_word_id[a], true)
		pairs_found += 1
		status_label.text = "Paires trouvées : %d / %d" % [pairs_found, pair_count]
	else:
		_flip_card(a, false)
		_flip_card(b, false)

	flipped_indices.clear()
	input_locked = false

	if pairs_found == pair_count:
		status_label.text = "Bravo ! Toutes les paires trouvées."
