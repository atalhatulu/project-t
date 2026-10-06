@tool
extends Resource
class_name ItemData

# Project T - Eşya Veri Modeli
# Resource tabanlı, genişletilebilir eşya tanımı.

enum ItemCategory { MATERIAL, FOOD, WEAPON, QUEST }

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var category: ItemCategory = ItemCategory.MATERIAL
@export var max_stack: int = 99
@export var base_price: int = 10 # Temel alım/satım değeri (Bakır Sikke)
@export var icon_color: Color = Color("e5a93b") # Pixel art placeholder için birincil renk
@export var secondary_color: Color = Color("ffffff") # İkincil detay rengi
@export var icon_shape: String = "circle" # "circle", "rect", "cross", "gem", "potion"

func get_category_name() -> String:
	match category:
		ItemCategory.MATERIAL:
			return "Malzeme"
		ItemCategory.FOOD:
			return "Yiyecek"
		ItemCategory.WEAPON:
			return "Silah"
		ItemCategory.QUEST:
			return "Görev Eşyası"
		_:
			return "Genel"
