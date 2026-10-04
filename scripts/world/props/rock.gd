@tool
extends StaticBody2D

# Project T - 3/4 Perspektif Kaya Nesnesi

@export var rock_size: Vector2 = Vector2(28, 18)

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	queue_redraw()

func _draw() -> void:
	# Gölge
	_draw_oval_shadow(Vector2(2, 6), rock_size.x * 0.55, rock_size.y * 0.45, Color(0, 0, 0, 0.35))

	# Kaya gövdesi (Çokgen)
	var pts = PackedVector2Array([
		Vector2(-rock_size.x * 0.5, 0),
		Vector2(-rock_size.x * 0.35, -rock_size.y * 0.6),
		Vector2(rock_size.x * 0.2, -rock_size.y * 0.7),
		Vector2(rock_size.x * 0.5, -rock_size.y * 0.2),
		Vector2(rock_size.x * 0.45, rock_size.y * 0.3),
		Vector2(-rock_size.x * 0.2, rock_size.y * 0.4)
	])
	draw_colored_polygon(pts, Color("4b535d"))

	# Kaya aydınlık yüzeyi (Üst ışık)
	var light_pts = PackedVector2Array([
		Vector2(-rock_size.x * 0.3, -rock_size.y * 0.5),
		Vector2(rock_size.x * 0.15, -rock_size.y * 0.65),
		Vector2(rock_size.x * 0.35, -rock_size.y * 0.2),
		Vector2(0, -rock_size.y * 0.1)
	])
	draw_colored_polygon(light_pts, Color("6b7280"))

func _draw_oval_shadow(pos: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(16):
		var rad = (float(i) / 16.0) * TAU
		pts.append(pos + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(pts, col)
