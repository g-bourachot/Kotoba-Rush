extends Node

# ============================================================
# UITHEME — singleton (autoload) qui construit et applique un
# thème visuel coloré/arcade à toute la fenêtre au démarrage.
# ------------------------------------------------------------
# Centralise aussi la palette (couleurs de feedback correct /
# incorrect / révélation) pour que tous les mini-jeux restent
# cohérents visuellement sans dupliquer les valeurs.
# ============================================================

const COLOR_BG := Color(0.114, 0.086, 0.196)
const COLOR_ACCENT := Color(1.0, 0.42, 0.34)
const COLOR_ACCENT_ALT := Color(0.22, 0.75, 0.71)
const COLOR_GOLD := Color(1.0, 0.82, 0.25)
const COLOR_TEXT := Color(0.97, 0.96, 1.0)
const COLOR_BUTTON_TEXT := Color(0.12, 0.08, 0.18)
const COLOR_CORRECT := Color(0.30, 0.85, 0.45)
const COLOR_WRONG := Color(0.95, 0.35, 0.4)
const COLOR_REVEAL := Color(0.35, 0.65, 1.0)


func _ready() -> void:
	get_window().theme = _build_theme()
	RenderingServer.set_default_clear_color(COLOR_BG)


func _build_theme() -> Theme:
	var theme := Theme.new()

	theme.set_stylebox("normal", "Button", _button_style(COLOR_ACCENT, 0))
	theme.set_stylebox("hover", "Button", _button_style(COLOR_ACCENT.lightened(0.15), 0))
	theme.set_stylebox("pressed", "Button", _button_style(COLOR_ACCENT.darkened(0.15), 2))
	theme.set_stylebox("disabled", "Button", _button_style(COLOR_ACCENT.darkened(0.35), 0))
	theme.set_color("font_color", "Button", COLOR_BUTTON_TEXT)
	theme.set_color("font_hover_color", "Button", COLOR_BUTTON_TEXT)
	theme.set_color("font_pressed_color", "Button", COLOR_BUTTON_TEXT)
	theme.set_color("font_disabled_color", "Button", COLOR_BUTTON_TEXT.lightened(0.1))
	theme.set_font_size("font_size", "Button", 22)

	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_font_size("font_size", "Label", 18)

	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(0, 0, 0, 0.35)
	_round_corners(pb_bg, 10)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = COLOR_GOLD
	_round_corners(pb_fill, 10)
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)

	return theme


func _button_style(color: Color, shadow_extra: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	_round_corners(sb, 16)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4 + shadow_extra)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


func _round_corners(sb: StyleBoxFlat, radius: int) -> void:
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
