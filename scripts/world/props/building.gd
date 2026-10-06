@tool
extends StaticBody2D

# Project T - 3/4 Perspektif Pixel Art Köy Binası
# Ahşap kirişler, taş temel, kiremit çatı dokusu ve pencerelerde gece/gündüz ışığı

@export var building_name: String = "Köy Binası"
@export var building_width: float = 96.0
@export var building_height: float = 72.0
@export var roof_color: Color = Color("6b3512")
@export var wall_color: Color = Color("422a18")

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	queue_redraw()

func _draw() -> void:
	var hw = building_width * 0.5
	var wall_h = building_height * 0.55
	var roof_h = building_height * 0.45

	# 1. Taban Gölgesi
	draw_rect(Rect2(-hw + 8, wall_h * 0.5, building_width, 14), Color(0, 0, 0, 0.42))

	# 2. Taş Temel (Plinth - 6 piksel gri taş kaide)
	var plinth_rect = Rect2(-hw - 2, wall_h * 0.5 - 6, building_width + 4, 8)
	draw_rect(plinth_rect, Color("374151"))
	draw_line(Vector2(-hw - 2, wall_h * 0.5 - 6), Vector2(hw + 2, wall_h * 0.5 - 6), Color("6b7280"), 1.0)

	# 3. Ahşap Kirişli Duvar (Timber-frame duvarlar)
	var wall_rect = Rect2(-hw, -wall_h * 0.5, building_width, wall_h - 4)
	draw_rect(wall_rect, wall_color)

	# Duvar sol gölge ve sağ ışık şeridi
	draw_rect(Rect2(-hw, -wall_h * 0.5, 4, wall_h - 4), wall_color.darkened(0.3))
	draw_rect(Rect2(hw - 4, -wall_h * 0.5, 4, wall_h - 4), wall_color.lightened(0.15))

	# Ahşap dikey destek kolonları (Timber beams)
	var beam_col = Color("2e1a0d")
	draw_rect(Rect2(-hw, -wall_h * 0.5, 5, wall_h - 4), beam_col)
	draw_rect(Rect2(hw - 5, -wall_h * 0.5, 5, wall_h - 4), beam_col)
	draw_rect(Rect2(-12, -wall_h * 0.5, 4, wall_h - 4), beam_col)
	draw_rect(Rect2(8, -wall_h * 0.5, 4, wall_h - 4), beam_col)

	# 4. Ahşap Kapı
	var door_w = 18.0
	var door_h = 24.0
	var door_rect = Rect2(-door_w * 0.5, wall_rect.end.y - door_h, door_w, door_h)
	draw_rect(door_rect, Color("1f140a"))
	# Kapı pervazı ve kemeri
	draw_rect(Rect2(-door_w * 0.5 - 1, wall_rect.end.y - door_h - 1, door_w + 2, 2), beam_col)
	# Demir kapı kolu
	draw_rect(Rect2(4, wall_rect.end.y - 12, 2, 3), Color("9ca3af"))

	# 5. Pencereler (Kafesli cam ve ahşap pervaz)
	var win_w = 14.0
	var win_h = 14.0
	var win_left_x = -hw + 14
	var win_right_x = hw - 28
	var win_y = -wall_h * 0.25

	for wx in [win_left_x, win_right_x]:
		# Pervaz
		draw_rect(Rect2(wx - 1, win_y - 1, win_w + 2, win_h + 2), beam_col)
		# Cam
		draw_rect(Rect2(wx, win_y, win_w, win_h), Color("1e293b"))
		# Ahşap cam haçı (Grid)
		draw_line(Vector2(wx + win_w * 0.5, win_y), Vector2(wx + win_w * 0.5, win_y + win_h), beam_col, 1.0)
		draw_line(Vector2(wx, win_y + win_h * 0.5), Vector2(wx + win_w, win_y + win_h * 0.5), beam_col, 1.0)
		# Cam parıltısı (Highlight)
		draw_line(Vector2(wx + 2, win_y + 2), Vector2(wx + 5, win_y + 5), Color("60a5fa"), 1.0)

	# 6. Katmanlı Kiremit Çatı (Shingle Tile Rows)
	var roof_base_y = -wall_h * 0.5
	var roof_apex_y = roof_base_y - roof_h

	var roof_pts = PackedVector2Array([
		Vector2(-hw - 8, roof_base_y),
		Vector2(hw + 8, roof_base_y),
		Vector2(0, roof_apex_y)
	])
	draw_colored_polygon(roof_pts, roof_color)

	# Çatının sağ güneşli tarafı (İki tonlu derinlik)
	var roof_right_pts = PackedVector2Array([
		Vector2(0, roof_apex_y),
		Vector2(hw + 8, roof_base_y),
		Vector2(0, roof_base_y)
	])
	draw_colored_polygon(roof_right_pts, roof_color.lightened(0.12))

	# Kiremit yatay sıraları (Shingle lines)
	for i in range(1, 4):
		var t = float(i) / 4.0
		var ly = lerp(roof_base_y, roof_apex_y, t)
		var lx1 = lerp(-hw - 8, 0.0, t)
		var lx2 = lerp(hw + 8, 0.0, t)
		draw_line(Vector2(lx1, ly), Vector2(lx2, ly), roof_color.darkened(0.25), 1.5)

	# Çatı saçak tahtası (Fascia board)
	draw_line(Vector2(-hw - 8, roof_base_y), Vector2(hw + 8, roof_base_y), beam_col, 2.5)
