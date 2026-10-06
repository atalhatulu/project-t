@tool
extends StaticBody2D

# Project T - 3/4 Perspektif Organik Pixel Art Kaya Nesnesi
# Sert fasetler, gölge kenarları, üst ışık ve yosun kaplamaları

@export_enum("small", "medium", "large") var rock_size_preset: String = "medium"

var rock_size: Vector2 = Vector2(28, 18)

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_apply_preset()
	queue_redraw()

func _apply_preset() -> void:
	match rock_size_preset:
		"small":
			rock_size = Vector2(18, 12)
			var col = get_node_or_null("CollisionShape2D")
			if col and col.shape is CapsuleShape2D:
				(col.shape as CapsuleShape2D).radius = 4.0
				(col.shape as CapsuleShape2D).height = 12.0
		"medium":
			rock_size = Vector2(28, 18)
			var col = get_node_or_null("CollisionShape2D")
			if col and col.shape is CapsuleShape2D:
				(col.shape as CapsuleShape2D).radius = 6.0
				(col.shape as CapsuleShape2D).height = 20.0
		"large":
			rock_size = Vector2(44, 26)
			var col = get_node_or_null("CollisionShape2D")
			if col and col.shape is CapsuleShape2D:
				(col.shape as CapsuleShape2D).radius = 9.0
				(col.shape as CapsuleShape2D).height = 34.0

func _draw() -> void:
	# 1. Taban Gölgesi
	_draw_oval_shadow(Vector2(2, 6), rock_size.x * 0.58, rock_size.y * 0.45, Color(0, 0, 0, 0.42))

	var col_shadow = Color("23272d")
	var col_dark = Color("383e47")
	var col_base = Color("4b535d")
	var col_light = Color("687382")
	var col_high = Color("8793a3")
	var col_moss = Color("38572b")

	# 2. Kaya Gövdesi (Fasetli sert kenarlar)
	var pts_base = PackedVector2Array([
		Vector2(-rock_size.x * 0.5, 2),
		Vector2(-rock_size.x * 0.38, -rock_size.y * 0.65),
		Vector2(rock_size.x * 0.15, -rock_size.y * 0.8),
		Vector2(rock_size.x * 0.48, -rock_size.y * 0.25),
		Vector2(rock_size.x * 0.42, rock_size.y * 0.35),
		Vector2(-rock_size.x * 0.25, rock_size.y * 0.45)
	])
	draw_colored_polygon(pts_base, col_dark)

	# 3. Ön ve Sol Gölgeli Faset
	var pts_front = PackedVector2Array([
		Vector2(-rock_size.x * 0.45, 0),
		Vector2(-rock_size.x * 0.1, -rock_size.y * 0.3),
		Vector2(rock_size.x * 0.35, -rock_size.y * 0.1),
		Vector2(rock_size.x * 0.38, rock_size.y * 0.3),
		Vector2(-rock_size.x * 0.2, rock_size.y * 0.4)
	])
	draw_colored_polygon(pts_front, col_base)

	# 4. Sol-Üst Işık Alan Fasetler (Güneş sol-üstten vurur)
	var pts_top = PackedVector2Array([
		Vector2(-rock_size.x * 0.35, -rock_size.y * 0.6),
		Vector2(rock_size.x * 0.12, -rock_size.y * 0.75),
		Vector2(rock_size.x * 0.28, -rock_size.y * 0.35),
		Vector2(-rock_size.x * 0.1, -rock_size.y * 0.25)
	])
	draw_colored_polygon(pts_top, col_light)

	# Çatlak ve faset vurgu çizgisi
	draw_line(Vector2(-rock_size.x * 0.1, -rock_size.y * 0.25), Vector2(rock_size.x * 0.12, -rock_size.y * 0.75), col_high, 1.5)
	draw_line(Vector2(-rock_size.x * 0.1, -rock_size.y * 0.25), Vector2(rock_size.x * 0.38, rock_size.y * 0.3), col_shadow, 1.5)

	# 5. Yosun Kaplaması (Üst köşe girintisinde)
	var pts_moss = PackedVector2Array([
		Vector2(-rock_size.x * 0.28, -rock_size.y * 0.45),
		Vector2(-rock_size.x * 0.05, -rock_size.y * 0.55),
		Vector2(rock_size.x * 0.1, -rock_size.y * 0.35),
		Vector2(-rock_size.x * 0.15, -rock_size.y * 0.3)
	])
	draw_colored_polygon(pts_moss, col_moss)

func _draw_oval_shadow(pos: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(16):
		var rad = (float(i) / 16.0) * TAU
		pts.append(pos + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(pts, col)
