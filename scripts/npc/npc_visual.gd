@tool
extends Node2D

# Project T - NPC Görsel Çizimi (Placeholder Anatomik Piksel Görünüm)
# Mesleğe göre gömlek ve önlük rengi özelleştirilebilir.

@export var skin_color: Color = Color("d4a373")
@export var hair_color: Color = Color("3d2314")
@export var shirt_color: Color = Color("78350f") # Demirci kahverengisi / deri
@export var apron_color: Color = Color("451a03") # Demirci deri önlüğü

var walk_cycle: float = 0.0

func _process(delta: float) -> void:
	var parent_body = get_parent() as CharacterBody2D
	if parent_body and parent_body.velocity.length() > 5.0:
		walk_cycle += delta * 10.0
		queue_redraw()
	elif walk_cycle != 0.0:
		walk_cycle = 0.0
		queue_redraw()

func _draw() -> void:
	var leg_offset = sin(walk_cycle) * 2.0
	var body_bob = abs(sin(walk_cycle)) * 1.0

	# 1. Taban Gölgesi
	_draw_oval_shadow(Vector2(0, 14), 9.0, 4.0, Color(0, 0, 0, 0.35))

	# 2. Bacaklar / Pantolon
	draw_rect(Rect2(-5, 4 - leg_offset, 4, 10), Color("1c1917"))
	draw_rect(Rect2(1, 4 + leg_offset, 4, 10), Color("1c1917"))

	# 3. Gövde & Gömlek
	draw_rect(Rect2(-6, -7 - body_bob, 12, 11), shirt_color)

	# 4. Deri Demirci Önlüğü
	draw_rect(Rect2(-4, -5 - body_bob, 8, 11), apron_color)

	# 5. Kollar
	draw_rect(Rect2(-8, -6 - body_bob, 2, 8), shirt_color)
	draw_rect(Rect2(6, -6 - body_bob, 2, 8), shirt_color)

	# 6. Kafa
	draw_circle(Vector2(0, -11 - body_bob), 4.0, skin_color)

	# 7. Saç & Sakal
	draw_rect(Rect2(-4, -15 - body_bob, 8, 3), hair_color)
	draw_rect(Rect2(-3, -10 - body_bob, 6, 2), hair_color) # Sakal

func _draw_oval_shadow(pos: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(12):
		var rad = (float(i) / 12.0) * TAU
		pts.append(pos + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(pts, col)
