extends Node

# ============================================================
# FX — singleton (autoload) d'animations courtes réutilisables
# pour donner du peps aux mini-jeux (pop, secousse) sans dupliquer
# de code Tween dans chaque scène.
# ============================================================


func punch_scale(node: Control, amount: float = 1.25, duration: float = 0.28) -> void:
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2(amount, amount)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func shake(node: Control, strength: float = 10.0, duration: float = 0.3) -> void:
	var base_x: float = node.position.x
	var steps := 6
	var tw := node.create_tween()
	for i in range(steps):
		var offset: float = strength * (1.0 - float(i) / steps) * (1.0 if i % 2 == 0 else -1.0)
		tw.tween_property(node, "position:x", base_x + offset, duration / steps)
	tw.tween_property(node, "position:x", base_x, duration / steps)
