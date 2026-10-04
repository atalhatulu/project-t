@tool
extends StaticBody2D

# Project T - 3/4 Perspektif Ağaç Nesnesi
# Gövde tabanında çarpışma (Layer 1: World_Solid), üst kısımda Y-Sort ile oyuncunun önünden/arkasından geçiş

@export var tree_radius: float = 24.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	queue_redraw()

func _draw() -> void:
	# 1. Gövde gölgesi
	_draw_oval_shadow(Vector2(0, 10), 16, 8, Color(0, 0, 0, 0.35))

	# 2. Ağaç gövdesi
	draw_rect(Rect2(-5, -6, 10, 16), Color("4a3319"))

	# 3. Ağaç tepesi (Yaprak katmanları - 3/4 açısı)
	# Alt koyu yapraklar
	draw_circle(Vector2(0, -18), tree_radius, Color("1b3d16"))
	# Orta yapraklar
	draw_circle(Vector2(-4, -24), tree_radius * 0.85, Color("2d5a27"))
	# Üst aydınlık yapraklar
	draw_circle(Vector2(2, -28), tree_radius * 0.7, Color("3e7b35"))
	# Tepe parlama
	draw_circle(Vector2(0, -32), tree_radius * 0.45, Color("529e46"))

func _draw_oval_shadow(pos: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(16):
		var rad = (float(i) / 16.0) * TAU
		pts.append(pos + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(pts, col)
