@tool
extends StaticBody2D

# Project T - 3/4 Perspektif Köy Binası
# Alt duvar kısmında katı çarpışma (Layer 1: World_Solid), çatı kısmı ise oyuncu arkasına geçtiğinde doğru Y-sort sağlar.

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

	# 1. Gölge (Güneş açısına göre sağ alta düşer)
	draw_rect(Rect2(-hw + 8, wall_h * 0.5, building_width, 12), Color(0, 0, 0, 0.35))

	# 2. Ön Duvar (Taban Y: 0 civarı)
	var wall_rect = Rect2(-hw, -wall_h * 0.5, building_width, wall_h)
	draw_rect(wall_rect, wall_color)

	# 3. Kapı
	var door_w = 18.0
	var door_h = 24.0
	var door_rect = Rect2(-door_w * 0.5, wall_rect.end.y - door_h, door_w, door_h)
	draw_rect(door_rect, Color("1a1109"))

	# 4. Pencereler
	draw_rect(Rect2(-hw + 12, -wall_h * 0.2, 12, 12), Color("1a2c3d"))
	draw_rect(Rect2(hw - 24, -wall_h * 0.2, 12, 12), Color("1a2c3d"))

	# 5. Çatı (3/4 Açı Piramit / Üçgen tonlama)
	var roof_top = Vector2(0, -wall_h * 0.5 - roof_h)
	var roof_pts = PackedVector2Array([
		Vector2(-hw - 6, -wall_h * 0.5),
		Vector2(hw + 6, -wall_h * 0.5),
		roof_top
	])
	draw_colored_polygon(roof_pts, roof_color)

	# Çatı saçak çizgisi
	draw_line(Vector2(-hw - 6, -wall_h * 0.5), Vector2(hw + 6, -wall_h * 0.5), roof_color.lightened(0.2), 2.0)
