extends Node2D
class_name Region

# Project T - Bölge Yöneticisi (World -> Region -> Location mimarisi)
# İlk test bölgemiz: "Kızıl Bozkır - Başlangıç Köyü ve Çevresi"

@export var region_id: String = "region_01_greenwood"
@export var region_name: String = "Kızıl Vadi Sınırı"

@onready var location: Location = $TestLocation
