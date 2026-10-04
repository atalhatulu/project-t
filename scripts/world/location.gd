extends Node2D
class_name Location

# Project T - Konum / Harita Katmanları Yönetimi
# World of Anterra benzeri katmanlı yapı:
# 1. Ground: Zemin, çimen, kum
# 2. Ground_Details: Çiçekler, küçük çakıl taşları
# 3. Paths: Toprak patikalar, meydan taş döşemesi
# 4. Water: Gölet ve su yüzeyleri (Solid çarpışmalı)
# 5. YSort_Entities: Binalar, ağaçlar, kayalar ve oyuncu (Y-sorting ile doğru derinlik)
# 6. Above_Player: Yüksek çatılar, gölgelikler, hava efektleri

const TilesetGen = preload("res://scripts/world/tileset_generator.gd")

@onready var ground_layer: TileMapLayer = $Ground
@onready var ground_details_layer: TileMapLayer = $Ground_Details
@onready var paths_layer: TileMapLayer = $Paths
@onready var water_layer: TileMapLayer = $Water
@onready var above_player_layer: TileMapLayer = $Above_Player
@onready var ysort_entities: Node2D = $YSort_Entities

# Harita ebatları (Karo cinsinden: 60x40 karo = 960x640 piksel test bölgesi)
const MAP_WIDTH: int = 60
const MAP_HEIGHT: int = 40

func _ready() -> void:
	setup_tilesets()
	generate_test_region()

func setup_tilesets() -> void:
	var generated_tileset = TilesetGen.create_placeholder_tileset()
	if ground_layer: ground_layer.tile_set = generated_tileset
	if ground_details_layer: ground_details_layer.tile_set = generated_tileset
	if paths_layer: paths_layer.tile_set = generated_tileset
	if water_layer: water_layer.tile_set = generated_tileset
	if above_player_layer: above_player_layer.tile_set = generated_tileset

func generate_test_region() -> void:
	# 1. ZEMİN (Çimen ile doldur)
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0)) # Çimen

	# 2. KÖY MEYDANI & YOLLAR
	# Meydan (x: 25..35, y: 15..25 arası)
	for x in range(25, 36):
		for y in range(15, 26):
			paths_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 1)) # Taş Zemin

	# Doğu-Batı Ana Yolu
	for x in range(5, 55):
		for y in range(19, 22):
			paths_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 0)) # Toprak Yol

	# Kuzey-Güney Köy Yolu
	for y in range(5, 35):
		for x in range(29, 32):
			paths_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 0)) # Toprak Yol

	# 3. GÖLET (Water Katmanı - Güneydoğu: x: 42..54, y: 26..35)
	for x in range(42, 55):
		for y in range(26, 36):
			var dist = Vector2(x - 48, y - 30).length()
			if dist < 5.5:
				water_layer.set_cell(Vector2i(x, y), 0, Vector2i(2, 0)) # Su
			elif dist < 6.5:
				ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 1)) # Kıyı kumu

	# 4. ZEMİN DETAYLARI (Çiçekler ve çakıllar)
	var rng = RandomNumberGenerator.new()
	rng.seed = 1337
	for i in range(70):
		var rx = rng.randi_range(2, MAP_WIDTH - 3)
		var ry = rng.randi_range(2, MAP_HEIGHT - 3)
		# Su ve meydan üstüne rastgele koyma
		if not water_layer.get_cell_source_id(Vector2i(rx, ry)) != -1 and not paths_layer.get_cell_source_id(Vector2i(rx, ry)) != -1:
			var tile_coord = Vector2i(3, 0) if (i % 2 == 0) else Vector2i(2, 1)
			ground_details_layer.set_cell(Vector2i(rx, ry), 0, tile_coord)
