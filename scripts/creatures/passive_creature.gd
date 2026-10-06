@tool
extends BaseCreature
class_name PassiveCreature

# Project T - Pasif Canlılar (Tavşan, Geyik, Kuş)
# Oyuncuyu veya yırtıcıyı görünce kaçar, zarar vermez

@export_enum("rabbit", "deer", "bird") var species: String = "rabbit":
	set(val):
		species = val
		_apply_species_data()

func _ready() -> void:
	category = CreatureCategory.PASSIVE
	_apply_species_data()
	super._ready()

func _apply_species_data() -> void:
	match species:
		"rabbit":
			creature_name = "Kır Tavşanı"
			max_health = 15
			base_speed = 50.0
			flee_or_chase_speed = 125.0
			detection_range = 100.0
			loot_table = [
				{"item_id": "wild_apple", "amount": 1, "chance": 0.6}
			]
		"deer":
			creature_name = "Orman Geyiği"
			max_health = 35
			base_speed = 45.0
			flee_or_chase_speed = 135.0
			detection_range = 140.0
			loot_table = [
				{"item_id": "wood", "amount": 2, "chance": 0.8}
			]
		"bird":
			creature_name = "Dağ Kuşu"
			max_health = 10
			base_speed = 60.0
			flee_or_chase_speed = 150.0
			detection_range = 80.0
			loot_table = [
				{"item_id": "shadow_moss", "amount": 1, "chance": 0.4}
			]

func _draw() -> void:
	var flash_mod = Color(1, 1, 1, 1) if hit_flash_timer <= 0.0 else Color(1, 0.4, 0.4, 1)

	# Taban gölgesi
	draw_circle(Vector2(0, 4), 6.0, Color(0, 0, 0, 0.3))

	match species:
		"rabbit":
			# Tavşan gövdesi ve kulakları
			draw_circle(Vector2(0, 0), 5.0, Color("d4a373") * flash_mod)
			draw_rect(Rect2(-3, -9, 2, 5), Color("e2e8f0") * flash_mod) # Kulak 1
			draw_rect(Rect2(1, -9, 2, 5), Color("e2e8f0") * flash_mod)  # Kulak 2
			draw_circle(Vector2(3, -2), 1.0, Color("1a1a1a")) # Göz
		"deer":
			# Geyik gövdesi, bacakları ve boynuzları
			draw_rect(Rect2(-8, -5, 16, 9), Color("8d5b32") * flash_mod) # Gövde
			draw_circle(Vector2(7, -8), 4.0, Color("a66d3b") * flash_mod) # Baş
			draw_line(Vector2(6, -11), Vector2(4, -16), Color("5c3a1c"), 1.5) # Boynuz
			draw_line(Vector2(8, -11), Vector2(10, -16), Color("5c3a1c"), 1.5)
			# Bacaklar
			draw_rect(Rect2(-6, 4, 2, 6), Color("5c3a1c"))
			draw_rect(Rect2(4, 4, 2, 6), Color("5c3a1c"))
		"bird":
			# Kuş kanatları ve gagası
			draw_circle(Vector2(0, -2), 4.0, Color("3b82f6") * flash_mod) # Mavi tüyler
			draw_rect(Rect2(3, -3, 3, 2), Color("f59e0b")) # Sarı gaga
			draw_line(Vector2(-4, -2), Vector2(-7, -4), Color("1e3a8a"), 1.5) # Kanat
