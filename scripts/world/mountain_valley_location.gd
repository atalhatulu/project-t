extends Node2D

# Project T - Dağ Eteği Vadisi Konumu (Mountain Valley Location)
# İkinci örnek bölge: Dağ etekleri, çam ağaçları, dağ pınarı, avcı kulübesi ve keşif noktaları

const TilesetGen = preload("res://scripts/world/tileset_generator.gd")

@onready var ground_layer: TileMapLayer = $Ground
@onready var ground_details_layer: TileMapLayer = $Ground_Details
@onready var paths_layer: TileMapLayer = $Paths
@onready var water_layer: TileMapLayer = $Water
@onready var ysort_entities: Node2D = $YSort_Entities

const MAP_WIDTH: int = 120
const MAP_HEIGHT: int = 80

func _ready() -> void:
	add_to_group("location")
	setup_tilesets()
	generate_mountain_valley()

func setup_tilesets() -> void:
	var generated_tileset = TilesetGen.create_placeholder_tileset()
	if ground_layer: ground_layer.tile_set = generated_tileset
	if ground_details_layer: ground_details_layer.tile_set = generated_tileset
	if paths_layer: paths_layer.tile_set = generated_tileset
	if water_layer: water_layer.tile_set = generated_tileset

func generate_mountain_valley() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 3042
	
	# 1. Zemin (Dağ eteği, yosunlu kayalıklar ve dağ çayırı)
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var tile_coord = Vector2i(5, 0) # Kayalık zemin
			if y > 40:
				tile_coord = Vector2i(0, 0) # Vadinin tabanı yeşil çayır
			elif y > 25 and rng.randf() < 0.5:
				tile_coord = Vector2i(5, 1) # Yosunlu dağ zemini
			ground_layer.set_cell(Vector2i(x, y), 0, tile_coord)
	
	# 2. Dağ Pınarı / Akarsu (Kuzeyden güneye süzülen kaynak suyu)
	for y in range(MAP_HEIGHT):
		var spring_x = int(45.0 + sin(float(y) * 0.15) * 6.0)
		for sx in range(spring_x - 1, spring_x + 2):
			if sx >= 0 and sx < MAP_WIDTH:
				water_layer.set_cell(Vector2i(sx, y), 0, Vector2i(2, 0))
	
	# 3. Dağ Patikası (Batıdan vadiye inen yol)
	for x in range(MAP_WIDTH):
		var py = int(50.0 + sin(float(x) * 0.08) * 4.0)
		paths_layer.set_cell(Vector2i(x, py), 0, Vector2i(1, 0))
		paths_layer.set_cell(Vector2i(x, py + 1), 0, Vector2i(1, 0))

	# 4. Kanyon / Uçurum Boşluğu (x: 68..75, y: 15..55 - Kanca veya köprü gerektiren yarık)
	for y in range(15, 56):
		var cx = int(70.0 + sin(float(y) * 0.2) * 2.0)
		for off in range(-2, 3):
			if (cx + off) < MAP_WIDTH:
				ground_layer.set_cell(Vector2i(cx + off, y), 0, Vector2i(3, 1)) # Derin uçurum gölgesi

func get_biome_at_world_pos(world_pos: Vector2) -> BiomeData:
	var tile_pos = Vector2i(int(world_pos.x / 16.0), int(world_pos.y / 16.0))
	if water_layer and water_layer.get_cell_source_id(tile_pos) != -1:
		return BiomeData.create_biome(BiomeData.BiomeType.COAST)
	if ground_layer:
		var g_coord = ground_layer.get_cell_atlas_coords(tile_pos)
		if g_coord == Vector2i(0, 0):
			return BiomeData.create_biome(BiomeData.BiomeType.MEADOW)
	return BiomeData.create_biome(BiomeData.BiomeType.MOUNTAIN)
