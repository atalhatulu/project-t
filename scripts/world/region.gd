extends Node2D
class_name Region

# Project T - Bölge Yöneticisi (World -> Region -> Location mimarisi)
# İlk test bölgemiz: "Kızıl Bozkır - Başlangıç Köyü ve Çevresi"

@export var region_id: String = "region_01_greenwood"
@export var region_name: String = "Kızıl Vadi Sınırı"
@export var region_size: Vector2 = Vector2(1920, 1280)

@onready var location: Node2D = get_node_or_null("TestLocation")

func _ready() -> void:
	add_to_group("region")
	if not location:
		for child in get_children():
			if child is Location or child.name.ends_with("Location"):
				location = child
				break

func get_region_bounds() -> Rect2:
	return Rect2(global_position, region_size)
