extends Control

@onready var word_count_label: Label = $VBoxContainer/WordCountLabel
@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var play_best_label: Label = $VBoxContainer/PlayBestLabel
@onready var memory_button: Button = $VBoxContainer/MemoryButton
@onready var chute_button: Button = $VBoxContainer/ChuteButton
@onready var chute_best_label: Label = $VBoxContainer/ChuteBestLabel
@onready var trou_button: Button = $VBoxContainer/TrouButton
@onready var trou_best_label: Label = $VBoxContainer/TrouBestLabel


func _ready() -> void:
	word_count_label.text = "%d mots chargés" % WordDB.count()
	play_button.pressed.connect(_on_play_pressed)
	memory_button.pressed.connect(_on_memory_pressed)
	chute_button.pressed.connect(_on_chute_pressed)
	trou_button.pressed.connect(_on_trou_pressed)

	play_best_label.text = "Meilleur score : %d" % Settings.get_best_score("wordsort")
	chute_best_label.text = "Meilleur score : %d" % Settings.get_best_score("chute")
	trou_best_label.text = "Meilleur score : %d" % Settings.get_best_score("trou")


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/WordSort.tscn")


func _on_memory_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MemoryMatch.tscn")


func _on_chute_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Chute.tscn")


func _on_trou_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Trou.tscn")
