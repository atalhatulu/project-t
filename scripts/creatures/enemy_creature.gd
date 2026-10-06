@tool
extends BaseCreature
class_name EnemyCreature

# Project T - Tehlikeli Canlılar ve Düşmanlar (Kurt, Yaban Domuzu, Haydut)
# Oyuncuyu tespit edince kovalar, vurur ve geri çekilme mesafesine riayet eder

@export_enum("wolf", "boar", "bandit") var enemy_type: String = "wolf":
	set(val):
		enemy_type = val
		_apply_enemy_data()

func _ready() -> void:
	category = CreatureCategory.HOSTILE
	_apply_enemy_data()
	super._ready()

func _apply_enemy_data() -> void:
	match enemy_type:
		"wolf":
			creature_name = "Bozkır Kurdu"
			max_health = 40
			attack_damage = 12
			base_speed = 55.0
			flee_or_chase_speed = 105.0
			detection_range = 130.0
			attack_range = 22.0
			max_chase_distance_from_origin = 220.0
			loot_table = [
				{"item_id": "iron_ore", "amount": 1, "chance": 0.4},
				{"item_id": "shadow_moss", "amount": 2, "chance": 0.7}
			]
		"boar":
			creature_name = "Yaban Domuzu"
			max_health = 60
			attack_damage = 16
			base_speed = 45.0
			flee_or_chase_speed = 95.0
			detection_range = 110.0
			attack_range = 20.0
			max_chase_distance_from_origin = 190.0
			loot_table = [
				{"item_id": "wild_apple", "amount": 2, "chance": 0.8},
				{"item_id": "wood", "amount": 2, "chance": 0.6}
			]
		"bandit":
			creature_name = "Vadi Haydutu"
			max_health = 50
			attack_damage = 14
			base_speed = 50.0
			flee_or_chase_speed = 100.0
			detection_range = 150.0
			attack_range = 24.0
			max_chase_distance_from_origin = 250.0
			loot_table = [
				{"item_id": "cooper_coins", "amount": 15, "chance": 0.95},
				{"item_id": "rusted_sword", "amount": 1, "chance": 0.35}
			]

func _draw() -> void:
	var flash_mod = Color(1, 1, 1, 1) if hit_flash_timer <= 0.0 else Color(1, 0.3, 0.3, 1)

	# Taban gölgesi
	draw_circle(Vector2(0, 5), 8.0, Color(0, 0, 0, 0.35))

	match enemy_type:
		"wolf":
			# Kurt (Gri kürk, sivri kulaklar, kırmızı gözler)
			draw_rect(Rect2(-9, -6, 18, 11), Color("4b5563") * flash_mod) # Gövde
			draw_circle(Vector2(8, -5), 5.0, Color("374151") * flash_mod) # Baş
			draw_line(Vector2(7, -8), Vector2(6, -13), Color("1f2937"), 1.5) # Kulak
			draw_circle(Vector2(10, -5), 1.5, Color("ef4444")) # Kırmızı göz
			# Bacaklar
			draw_rect(Rect2(-7, 5, 3, 5), Color("374151"))
			draw_rect(Rect2(5, 5, 3, 5), Color("374151"))
		"boar":
			# Yaban Domuzu (Koyu kahverengi tıknaz gövde, beyaz dişler)
			draw_rect(Rect2(-11, -8, 22, 14), Color("3d2817") * flash_mod) # Gövde
			draw_circle(Vector2(9, -3), 6.0, Color("4a321d") * flash_mod) # Baş
			draw_rect(Rect2(12, -1, 3, 4), Color("f8fafc")) # Sivri azı dişi
			draw_rect(Rect2(-8, 6, 4, 4), Color("26180d"))
			draw_rect(Rect2(6, 6, 4, 4), Color("26180d"))
		"bandit":
			# Haydut (Deri ceket, kırmızı haydut maskesi, kama)
			draw_rect(Rect2(-6, -8, 12, 14), Color("334155") * flash_mod) # Gövde
			draw_circle(Vector2(0, -12), 4.5, Color("d4a373") * flash_mod) # Baş
			draw_rect(Rect2(-4, -13, 8, 3), Color("dc2626")) # Kırmızı maske
			# Bıçak/Kılıç
			draw_line(Vector2(6, -4), Vector2(13, -1), Color("94a3b8"), 2.0)
			draw_rect(Rect2(-4, 6, 3, 6), Color("1e293b"))
			draw_rect(Rect2(2, 6, 3, 6), Color("1e293b"))
