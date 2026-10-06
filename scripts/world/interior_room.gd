@tool
extends Node2D
class_name InteriorRoom

# Project T - 3/4 Perspektif İç Mekân Temel Odası (İç Mekân / Zindan Şablonu)
# Ahşap parke zemin, taş/tuğla duvarlar, süpürgelik ve tavan gölgesi

@export var room_title: String = "İç Mekân"
@export var room_width: float = 320.0
@export var room_height: float = 240.0
@export var wall_color: Color = Color("382315")
@export var floor_color: Color = Color("5c3a1c")

func _ready() -> void:
	add_to_group("interior_room")
	queue_redraw()

func _draw() -> void:
	var w = room_width
	var h = room_height
	var wall_top_h = 36.0

	# 1. Dış Çevre Zifiri Karanlık Boşluk (Void)
	draw_rect(Rect2(-w * 0.5 - 100, -h * 0.5 - 100, w + 200, h + 200), Color("080a0f"))

	# 2. Zemin (Ahşap Parke veya Taş Zemin)
	var floor_rect = Rect2(-w * 0.5, -h * 0.5 + wall_top_h, w, h - wall_top_h)
	draw_rect(floor_rect, floor_color)

	# Parke kalas çizgileri
	var plank_w = 20.0
	for px in range(int(-w * 0.5), int(w * 0.5), int(plank_w)):
		draw_line(Vector2(px, floor_rect.position.y), Vector2(px, floor_rect.end.y), floor_color.darkened(0.2), 1.0)

	# 3. Kuzey Duvarı (Ön Cephe Duvarı)
	var north_wall = Rect2(-w * 0.5, -h * 0.5, w, wall_top_h)
	draw_rect(north_wall, wall_color)
	# Duvar süpürgeliği
	draw_rect(Rect2(-w * 0.5, -h * 0.5 + wall_top_h - 4, w, 4), wall_color.darkened(0.4))

	# 4. Sol ve Sağ Duvarlar (Kenarlıklar)
	draw_rect(Rect2(-w * 0.5 - 12, -h * 0.5, 12, h), wall_color.darkened(0.3))
	draw_rect(Rect2(w * 0.5, -h * 0.5, 12, h), wall_color.darkened(0.3))

	# 5. Güney Duvarı (Giriş kenarlığı)
	draw_rect(Rect2(-w * 0.5 - 12, h * 0.5, w + 24, 16), wall_color.darkened(0.4))
