extends Node

# ============================================================
# SETTINGS — singleton (autoload) pour les préférences de jeu.
# ------------------------------------------------------------
# Persisté dans user://settings.cfg (survit aux mises à jour de
# l'app, comme la progression de WordDB).
# ============================================================

const SETTINGS_PATH := "user://settings.cfg"

var round_time: float = 6.0
var memory_pairs: int = 6


func _ready() -> void:
	_load()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		round_time = cfg.get_value("wordsort", "round_time", round_time)
		memory_pairs = cfg.get_value("memory_match", "pairs", memory_pairs)


func save_round_time(value: float) -> void:
	round_time = value
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("wordsort", "round_time", value)
	cfg.save(SETTINGS_PATH)


func save_memory_pairs(value: int) -> void:
	memory_pairs = value
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("memory_match", "pairs", value)
	cfg.save(SETTINGS_PATH)
