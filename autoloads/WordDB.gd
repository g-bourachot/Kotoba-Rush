extends Node

# ============================================================
# WordDB — singleton (autoload) qui gère la base de mots.
# ------------------------------------------------------------
# - Au premier lancement, copie le JSON embarqué (res://data/word_db.json,
#   généré depuis ton Tracker Notion) vers user:// (zone accessible en écriture).
# - Ensuite, TOUJOURS lire/écrire depuis user:// pour ne pas perdre
#   les progrès de jeu à chaque mise à jour de l'app.
# - Chaque mot : {id, kanji, reading, meaning, error_count,
#   success_count, last_seen, statut}
#   statut vient de ton tracker Notion (normal / vigilance / renforcement).
# ============================================================

const BUNDLED_PATH := "res://data/word_db.json"
const USER_PATH := "user://word_db.json"

var words: Array = []


func _ready() -> void:
	_ensure_user_copy()
	load_words()


# Copie le JSON embarqué vers user:// s'il n'existe pas encore là-bas.
# Ne JAMAIS écraser une base user:// existante (on perdrait la progression).
func _ensure_user_copy() -> void:
	if FileAccess.file_exists(USER_PATH):
		return
	if not FileAccess.file_exists(BUNDLED_PATH):
		push_error("Aucun word_db.json embarqué trouvé à %s" % BUNDLED_PATH)
		return
	var src := FileAccess.open(BUNDLED_PATH, FileAccess.READ)
	var content := src.get_as_text()
	src.close()
	var dst := FileAccess.open(USER_PATH, FileAccess.WRITE)
	dst.store_string(content)
	dst.close()


func load_words() -> void:
	if not FileAccess.file_exists(USER_PATH):
		words = []
		return
	var f := FileAccess.open(USER_PATH, FileAccess.READ)
	var content := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(content)
	words = parsed if typeof(parsed) == TYPE_ARRAY else []


func save_words() -> void:
	var f := FileAccess.open(USER_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(words))
	f.close()


func count() -> int:
	return words.size()


# Poids de tirage :
# - "renforcement" (🔴 dans Notion) sort beaucoup plus souvent
# - "vigilance" (🟡) un peu plus souvent
# - error_count et l'ancienneté de la dernière session pèsent aussi
func pick_weighted_word() -> Dictionary:
	return _pick_weighted_from(words)


# Tire n mots distincts (mêmes pondérations que pick_weighted_word,
# sans remise) — utilisé par les mini-jeux qui ont besoin de plusieurs
# mots à la fois (ex. paires mémoire).
func pick_weighted_words(n: int) -> Array:
	var pool: Array = words.duplicate()
	var picked: Array = []
	var count: int = min(n, pool.size())
	for i in range(count):
		var w: Dictionary = _pick_weighted_from(pool)
		picked.append(w)
		pool.erase(w)
	return picked


func _pick_weighted_from(pool: Array) -> Dictionary:
	var total_weight := 0.0
	var weights: Array = []
	var now := Time.get_unix_time_from_system()

	for w in pool:
		var err = w.get("error_count", 0)
		var last_seen = w.get("last_seen", now)
		var days_since = max((now - last_seen) / 86400.0, 0.0)
		var statut = w.get("statut", "normal")

		var statut_multiplier := 1.0
		if statut == "renforcement":
			statut_multiplier = 4.0
		elif statut == "vigilance":
			statut_multiplier = 2.0

		var weight = (1.0 + float(err) * 2.0 + min(days_since, 14.0)) * statut_multiplier
		weights.append(weight)
		total_weight += weight

	var r := randf() * total_weight
	var acc := 0.0
	for i in range(pool.size()):
		acc += weights[i]
		if r <= acc:
			return pool[i]
	return pool[pool.size() - 1]


func pick_decoy(exclude_id) -> Dictionary:
	var candidates = words.filter(func(w): return w.get("id") != exclude_id)
	return candidates[randi() % candidates.size()]


# Un mot est "tout en hiragana" quand son champ kanji est identique à
# sa lecture (ex. "けれども") — il n'a pas de kanji à proprement parler.
func is_all_hiragana(word: Dictionary) -> bool:
	return word.get("kanji", "") == word.get("reading", "")


func ends_with_hiragana(text: String) -> bool:
	if text.length() == 0:
		return false
	var code: int = text.unicode_at(text.length() - 1)
	return code >= 0x3040 and code <= 0x309F


# Comme pick_decoy, mais si le mot cible se termine par de l'hiragana
# visible (okurigana, ex. 変わる), on force un leurre qui se termine par
# le même caractère — sinon on peut deviner la bonne réponse juste en
# comparant la fin du mot affiché, sans en connaître le sens.
func pick_decoy_matching_ending(exclude_id, kanji: String) -> Dictionary:
	if not ends_with_hiragana(kanji):
		return pick_decoy(exclude_id)

	var last_char: String = kanji.substr(kanji.length() - 1, 1)
	var candidates: Array = words.filter(func(w):
		return w.get("id") != exclude_id and String(w.get("kanji", "")).ends_with(last_char)
	)
	if candidates.is_empty():
		return pick_decoy(exclude_id)
	return candidates[randi() % candidates.size()]


# Tire n leurres distincts (aucun rapport avec exclude_id) — pas besoin
# de pondération ici, c'est juste du bruit pour un mini-jeu à choix
# multiples (ex. Chute).
func pick_decoys(exclude_id, n: int) -> Array:
	var candidates: Array = words.filter(func(w): return w.get("id") != exclude_id)
	candidates.shuffle()
	return candidates.slice(0, min(n, candidates.size()))


func update_stats(word_id, correct: bool) -> void:
	for w in words:
		if w.get("id") == word_id:
			if correct:
				w["success_count"] = w.get("success_count", 0) + 1
			else:
				w["error_count"] = w.get("error_count", 0) + 1
			w["last_seen"] = Time.get_unix_time_from_system()
			break
	save_words()
