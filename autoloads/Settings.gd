extends Node

# ============================================================
# SETTINGS — singleton (autoload) pour les préférences de jeu.
# ------------------------------------------------------------
# Persisté dans user://settings.cfg (survit aux mises à jour de
# l'app, comme la progression de WordDB).
# ============================================================

const SETTINGS_PATH := "user://settings.cfg"

var round_time: float = 6.0


func _ready() -> void:
	_load()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		round_time = cfg.get_value("wordsort", "round_time", round_time)


func save_round_time(value: float) -> void:
	round_time = value
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("wordsort", "round_time", value)
	cfg.save(SETTINGS_PATH)
