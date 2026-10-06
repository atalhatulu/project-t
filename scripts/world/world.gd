extends Node2D
class_name World

# Project T - Ana Dünya Yöneticisi (Root World Node)
# Mimari: World -> Region -> Location

@export var current_region_id: String = "region_01_greenwood"

@onready var active_region: Region = get_node_or_null("Region")

func _ready() -> void:
	add_to_group("world")
	var rm = get_node_or_null("/root/RegionManager")
	if rm:
		if active_region:
			rm.loaded_regions[active_region.region_id] = active_region
			rm.active_region_id = active_region.region_id
		if not rm.active_region_changed.is_connected(_on_active_region_changed):
			rm.active_region_changed.connect(_on_active_region_changed)
	
	var r_name = active_region.region_name if active_region else "Yok"
	print("[Project T] Dünya başlatıldı. Aktif Bölge: ", r_name)

func _on_active_region_changed(_old_id: String, new_id: String) -> void:
	current_region_id = new_id
	var rm = get_node_or_null("/root/RegionManager")
	if rm and rm.loaded_regions.has(new_id):
		active_region = rm.loaded_regions[new_id]
