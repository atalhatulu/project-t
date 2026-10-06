@tool
extends StaticBody2D
class_name ClimbableCliff

# Project T - Veri Odaklı Tırmanılabilir Kaya / Uçurum Yüzeyi
# 3/4 Perspektif derinliği: Taban ve tepe kotu (elevation level)
# Oyuncu yaklaştığında E ile veya doğrudan duvara doğru hareket ederek tırmanabilir

@export var cliff_id: String = "cliff_01"
@export var cliff_height: float = 32.0 # Tırmanma yüksekliği
@export var base_elevation: int = 0
@export var top_elevation: int = 1
@export var cliff_width: float = 48.0

var climb_area: Area2D

func _ready() -> void:
	add_to_group("climbable")
	collision_layer = 1
	collision_mask = 0
	_setup_components()
	queue_redraw()

func _setup_components() -> void:
	var col = get_node_or_null("CollisionShape2D")
	if not col:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var shape = RectangleShape2D.new()
		shape.size = Vector2(cliff_width, 16.0)
		col.shape = shape
		add_child(col)

	climb_area = get_node_or_null("ClimbArea")
	if not climb_area:
		climb_area = Area2D.new()
		climb_area.name = "ClimbArea"
		climb_area.collision_layer = 32
		climb_area.collision_mask = 2
		var a_col = CollisionShape2D.new()
		var a_shape = RectangleShape2D.new()
		a_shape.size = Vector2(cliff_width + 8.0, cliff_height + 16.0)
		a_col.shape = a_shape
		climb_area.add_child(a_col)
		add_child(climb_area)

func _draw() -> void:
	var w = cliff_width
	var h = cliff_height

	# 1. Taban Gölgesi
	draw_rect(Rect2(-w * 0.5, 4, w, 8), Color(0, 0, 0, 0.4))

	# 2. Kaya / Uçurum Ön Yüzü (Dikey katmanlar ve basamaklar)
	var col_rock_base = Color("383e47")
	var col_rock_dark = Color("2d323a")
	var col_rock_ledge = Color("687382")
	var col_moss = Color("2e5a27")

	draw_rect(Rect2(-w * 0.5, -h, w, h), col_rock_base)
	draw_rect(Rect2(-w * 0.5, -h, 4, h), col_rock_dark)
	draw_rect(Rect2(w * 0.5 - 4, -h, 4, h), col_rock_dark)

	# Tırmanma tutamakları / yatay çatlaklar
	var steps = int(h / 8.0)
	for i in range(steps):
		var y_pos = -h + i * 8.0 + 4.0
		draw_line(Vector2(-w * 0.4, y_pos), Vector2(w * 0.4, y_pos), col_rock_ledge, 1.5)
		if i % 2 == 0:
			draw_rect(Rect2(-w * 0.2 + (i * 4), y_pos - 2, 6, 2), col_moss)

	# 3. Zirve / Tepe Kenarı (Top ledge)
	draw_rect(Rect2(-w * 0.5 - 2, -h - 3, w + 4, 4), col_rock_ledge)
	draw_rect(Rect2(-w * 0.5 - 2, -h - 3, w + 4, 2), Color("8793a3"))
