extends Node2D
class_name World

# Project T - Ana Dünya Yöneticisi (Root World Node)
# Mimari: World -> Region -> Location

@export var current_region_id: String = "region_01_greenwood"

@onready var active_region: Region = $Region

func _ready() -> void:
	print("[Project T] Dünya başlatıldı. Aktif Bölge: ", active_region.region_name if active_region else "Yok")
