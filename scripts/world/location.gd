extends Node2D
class_name Location

# Project T - Genişletilmiş Açık Dünya Harita Katmanları Yönetimi
# World of Anterra benzeri katmanlı yapı:
# 1. Ground: Zemin, çimen, kum, kayalık zemin, yosun
# 2. Ground_Details: Çiçekler, küçük çakıl taşları, çalı tabanları
# 3. Paths: Toprak patikalar, meydan taş döşemesi, ahşap köprü kalasları
# 4. Water: Nehir, göl ve gölet su yüzeyleri (Solid çarpışmalı)
# 5. YSort_Entities: Binalar, kule, mağara, ağaçlar, kayalar, çalılar, NPC'ler ve oyuncu
# 6. Above_Player: Yüksek çatılar, gölgelikler

const TilesetGen = preload("res://scripts/world/tileset_generator.gd")

@onready var ground_layer: TileMapLayer = $Ground
@onready var ground_details_layer: TileMapLayer = $Ground_Details
@onready var paths_layer: TileMapLayer = $Paths
@onready var water_layer: TileMapLayer = $Water
@onready var above_player_layer: TileMapLayer = $Above_Player
@onready var ysort_entities: Node2D = $YSort_Entities

# Genişletilmiş Harita Ebatları: 120 x 80 karo = 1920 x 1280 piksel
const MAP_WIDTH: int = 120
const MAP_HEIGHT: int = 80

# Su dalgası zamanlayıcısı
var water_anim_timer: float = 0.0
var water_tiles: Array[Vector2i] = []

func _ready() -> void:
	add_to_group("location")
	setup_tilesets()
	generate_expanded_world()

func _process(delta: float) -> void:
	# Suya hafif animasyon / akıntı parıltısı efekti
	water_anim_timer += delta
	if water_anim_timer >= 0.8:
		water_anim_timer = 0.0
		_animate_water_tiles()

func setup_tilesets() -> void:
	var generated_tileset = TilesetGen.create_placeholder_tileset()
	if ground_layer: ground_layer.tile_set = generated_tileset
	if ground_details_layer: ground_details_layer.tile_set = generated_tileset
	if paths_layer: paths_layer.tile_set = generated_tileset
	if water_layer: water_layer.tile_set = generated_tileset
	if above_player_layer: above_player_layer.tile_set = generated_tileset

func generate_expanded_world() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 2026

	# 1. ZEMİN TABANI (Çimen ve bölgesel doğal geçişler)
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var tile_coord = Vector2i(0, 0) # Normal Çimen
			
			# Kuzeydoğu Kayalık Tepeler (x: 75..115, y: 5..35)
			if x > 72 and y < 38:
				var dist_rock = Vector2(x - 95, y - 18).length()
				if dist_rock < 22.0:
					tile_coord = Vector2i(5, 0) # Kayalık Tepe Zemini
				elif dist_rock < 26.0 and rng.randf() < 0.6:
					tile_coord = Vector2i(5, 1) # Yosunlu Dağ Zemini

			# Batı Gizli Orman Açıklığı (x: 10..26, y: 12..28)
			var dist_glade = Vector2(x - 18, y - 20).length()
			if dist_glade < 7.5:
				tile_coord = Vector2i(6, 0) # Derin Orman Açıklığı

			# Güneybatı Gölgeli Bataklık (x: 14..36, y: 54..76)
			var dist_swamp = Vector2(x - 25, y - 65).length()
			if dist_swamp < 11.0:
				tile_coord = Vector2i(2, 1) # Bataklık Balçığı

			ground_layer.set_cell(Vector2i(x, y), 0, tile_coord)

	# 2. DOĞAL KIVRIMLI NEHİR & GÖL
	for y in range(MAP_HEIGHT):
		var river_center = int(58.0 + sin(float(y) * 0.12) * 8.5)
		var river_width = 3 if (y < 45 or y > 58) else 4
		for rx in range(river_center - river_width, river_center + river_width + 1):
			if rx >= 0 and rx < MAP_WIDTH:
				var is_deep = (abs(rx - river_center) <= 1)
				var water_tile = Vector2i(3, 1) if is_deep else Vector2i(2, 0)
				water_layer.set_cell(Vector2i(rx, y), 0, water_tile)
				water_tiles.append(Vector2i(rx, y))

				# Doğal çimen-kıyı kum geçişleri (Kenar karosu 7,1)
				if rx == river_center - river_width:
					ground_layer.set_cell(Vector2i(rx - 1, y), 0, Vector2i(7, 1))
				elif rx == river_center + river_width:
					ground_layer.set_cell(Vector2i(rx + 1, y), 0, Vector2i(7, 1))

	# Güneydoğu Doğal Gölü (x: 82..102, y: 48..70)
	for x in range(78, 108):
		for y in range(45, 75):
			var lake_dist = Vector2((x - 92) * 0.85, y - 58).length()
			if lake_dist < 11.0:
				var is_deep = lake_dist < 6.5
				water_layer.set_cell(Vector2i(x, y), 0, Vector2i(3, 1) if is_deep else Vector2i(2, 0))
				water_tiles.append(Vector2i(x, y))
			elif lake_dist < 13.5:
				ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 1)) # Kıyı kumu

	# 3. KÖY MEYDANI, YOLLAR VE DOĞAL PATİKALAR
	# Köy Meydanı (x: 26..36, y: 36..46)
	for x in range(26, 37):
		for y in range(36, 47):
			paths_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 1)) # Parke Taş Meydan

	# Doğu Yolu: Köy Meydanından Nehir Köprüsüne (y: 40..42, x: 36..70)
	for x in range(36, 75):
		for y in range(40, 43):
			# Nehir kesişiminde (x: 52..65) ahşap köprü kalasları döşe!
			if water_layer.get_cell_source_id(Vector2i(x, y)) != -1:
				paths_layer.set_cell(Vector2i(x, y), 0, Vector2i(4, 0)) # Ahşap Köprü Kalasları
				water_layer.erase_cell(Vector2i(x, y))
			else:
				# Yol kenarı çimen-toprak geçiş karosu (6,1)
				if (y == 40 or y == 42) and rng.randf() < 0.4:
					paths_layer.set_cell(Vector2i(x, y), 0, Vector2i(6, 1))
				else:
					paths_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 0)) # Toprak Patika

	# Kuzey Patikası: Köyden Orman Açıklığına (x: 31, y: 20..36)
	for y in range(20, 37):
		var px = int(31.0 + sin(float(y) * 0.25) * 2.0)
		paths_layer.set_cell(Vector2i(px, y), 0, Vector2i(1, 0))
		paths_layer.set_cell(Vector2i(px + 1, y), 0, Vector2i(1, 0))

	# Batı Patikası: Orman Açıklığına Giriş (y: 20, x: 18..31)
	for x in range(18, 32):
		var py = int(20.0 + cos(float(x) * 0.3) * 1.5)
		paths_layer.set_cell(Vector2i(x, py), 0, Vector2i(1, 0))

	# Doğu Dağ Patikası: Köprüden Tepeye ve Gözetleme Kulesine (x: 72..96, y: 18..41)
	for step in range(32):
		var t = float(step) / 31.0
		var tx = int(lerp(72.0, 95.0, t))
		var ty = int(lerp(41.0, 18.0, t) + sin(t * PI * 2) * 2.5)
		paths_layer.set_cell(Vector2i(tx, ty), 0, Vector2i(1, 0))
		paths_layer.set_cell(Vector2i(tx + 1, ty), 0, Vector2i(1, 0))

	# Mağara Patikası: Tepeden Gizli Mağara Girişine (x: 95..108, y: 18..24)
	for x in range(95, 109):
		paths_layer.set_cell(Vector2i(x, 22), 0, Vector2i(5, 1) if x >= 106 else Vector2i(1, 0))

	# 4. ZEMİN DETAYLARI (Çiçek tarlaları, çakıl taşları)
	for i in range(180):
		var rx = rng.randi_range(3, MAP_WIDTH - 4)
		var ry = rng.randi_range(3, MAP_HEIGHT - 4)
		if water_layer.get_cell_source_id(Vector2i(rx, ry)) == -1 and paths_layer.get_cell_source_id(Vector2i(rx, ry)) == -1:
			var detail_tile = Vector2i(3, 0) if (i % 3 == 0) else Vector2i(2, 1)
			ground_details_layer.set_cell(Vector2i(rx, ry), 0, detail_tile)

	update_valley_quest_world_state()

# Vadinin Sessizliği görev seçimine göre dünya durumu güncellemesi
func update_valley_quest_world_state() -> void:
	var qm = get_node_or_null("/root/QuestManager") if is_inside_tree() else null
	if not qm:
		return
	var choice = qm.valley_quest_choice
	var q_valley = qm.get_quest("silence_of_the_valley")
	if not q_valley or not q_valley.is_completed():
		return

	# Kervan Yolu (x: 72..78, y: 19..22 civarı)
	if choice == "guards":
		# Muhafızlar yolu emniyete aldı: Kervan yolu temizlenir, fener ve güvenlik işareti
		if paths_layer:
			paths_layer.set_cell(Vector2i(74, 20), 0, Vector2i(0, 1)) # Taş nöbet noktası
		var camp = get_node_or_null("YSort_Entities/Bandit_Camp")
		if camp:
			camp.visible = false
			camp.process_mode = Node.PROCESS_MODE_DISABLED
	elif choice == "bandits":
		# Haydutlarla anlaşıldı: Haydut kampı serbest ve dostane kalır, yola çete barikatı/işareti
		if ground_details_layer:
			ground_details_layer.set_cell(Vector2i(74, 20), 0, Vector2i(2, 1))

func _animate_water_tiles() -> void:
	if water_tiles.is_empty():
		return
	for i in range(12):
		var cell = water_tiles.pick_random()
		var cur_tile = water_layer.get_cell_atlas_coords(cell)
		if cur_tile == Vector2i(2, 0):
			water_layer.set_cell(cell, 0, Vector2i(7, 0)) # Köpüklü akıntı
		elif cur_tile == Vector2i(7, 0):
			water_layer.set_cell(cell, 0, Vector2i(2, 0)) # Normal sığ su

func get_biome_at_world_pos(world_pos: Vector2) -> BiomeData:
	var tile_pos = Vector2i(int(world_pos.x / 16.0), int(world_pos.y / 16.0))

	# 1. Kıyı / Su
	if water_layer:
		var w_coord = water_layer.get_cell_atlas_coords(tile_pos)
		if w_coord != Vector2i(-1, -1):
			return BiomeData.create_biome(BiomeData.BiomeType.COAST)

	# 2. Zemin Katmanı Kontrolü
	if ground_layer:
		var g_coord = ground_layer.get_cell_atlas_coords(tile_pos)
		if g_coord == Vector2i(5, 0) or g_coord == Vector2i(5, 1):
			return BiomeData.create_biome(BiomeData.BiomeType.MOUNTAIN)
		elif g_coord == Vector2i(6, 0):
			return BiomeData.create_biome(BiomeData.BiomeType.FOREST)
		elif g_coord == Vector2i(2, 1):
			return BiomeData.create_biome(BiomeData.BiomeType.SWAMP) # Bataklık
		elif g_coord == Vector2i(1, 1) or g_coord == Vector2i(7, 1):
			return BiomeData.create_biome(BiomeData.BiomeType.COAST)

	# Varsayılan: Çayır
	return BiomeData.create_biome(BiomeData.BiomeType.MEADOW)
