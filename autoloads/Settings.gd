extends Node

# ============================================================
# SETTINGS — singleton (autoload) pour les préférences de jeu.
# ------------------------------------------------------------
# Persisté dans user://settings.cfg (survit aux mises à jour de
# l'app, comme la progression de WordDB).
# ============================================================

const SETTINGS_PATH := "user://settings.cfg"

# Chaque mini-jeu a sa propre section dans settings.cfg, identifiée
# par cet id (ex. "wordsort", "chute", "trou").
const GAME_IDS := ["wordsort", "chute", "trou"]

var round_time: float = 6.0
var memory_pairs: int = 6
var best_scores: Dictionary = {}


func _ready() -> void:
	_load()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		round_time = cfg.get_value("wordsort", "round_time", round_time)
		memory_pairs = cfg.get_value("memory_match", "pairs", memory_pairs)
		for game_id in GAME_IDS:
			best_scores[game_id] = cfg.get_value(game_id, "best_score", 0)
	else:
		for game_id in GAME_IDS:
			best_scores[game_id] = 0


func get_best_score(game_id: String) -> int:
	return best_scores.get(game_id, 0)


func save_best_score(game_id: String, value: int) -> void:
	best_scores[game_id] = value
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(game_id, "best_score", value)
	cfg.save(SETTINGS_PATH)


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
