@tool
extends Node2D

# Project T - Prosedürel Placeholder TileSet ve Dünya Üreticisi
# Lisanssız dış asset indirmeden, Godot 4 TileMapLayer uyumlu 16x16 karo seti ve dünya katmanlarını oluşturur.

const TILE_SIZE: int = 16

# Karo indeksleri (Atlas koordinatları)
# 0,0: Çimen (Ground)
# 1,0: Toprak Yol (Paths)
# 2,0: Su (Water)
# 3,0: Çiçek / Zemin Detay (Ground_Details)
# 0,1: Taş Zemin / Meydan (Paths)
# 1,1: Kum / Kıyı (Ground)
# 2,1: Çakıl Taş (Ground_Details)
# 3,1: Derin Su (Water)

static func create_placeholder_tileset() -> TileSet:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	
	# Renk paleti (World of Anterra tarzı doğal tonlar)
	var col_grass = Color("2d4a22")
	var col_grass_dark = Color("233b1b")
	var col_dirt = Color("5c442c")
	var col_dirt_light = Color("6e5337")
	var col_water = Color("1e3f5a")
	var col_water_light = Color("2c567a")
	var col_flowers = Color("b33939")
	var col_stone_floor = Color("4b535d")
	var col_sand = Color("8c734b")

	# 0,0: Çimen
	_fill_tile_noise(img, 0, 0, col_grass, col_grass_dark)
	# 1,0: Yol / Toprak
	_fill_tile_noise(img, 16, 0, col_dirt, col_dirt_light)
	# 2,0: Su
	_fill_tile_noise(img, 32, 0, col_water, col_water_light)
	# 3,0: Çiçekli Çimen
	_fill_tile_noise(img, 48, 0, col_grass, col_grass_dark)
	_draw_dots(img, 48, 0, col_flowers)

	# 0,1: Meydan Taş Zemin
	_fill_tile_noise(img, 0, 16, col_stone_floor, Color("3a4049"))
	# 1,1: Kum
	_fill_tile_noise(img, 16, 16, col_sand, Color("79633e"))
	# 2,1: Çakıl
	_fill_tile_noise(img, 32, 16, col_dirt, Color("7a8288"))
	_draw_dots(img, 32, 16, Color("95a5a6"))
	# 3,1: Derin Su
	_fill_tile_noise(img, 48, 16, Color("142c40"), Color("0d1e2d"))

	var texture = ImageTexture.create_from_image(img)
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Su için fizik katmanı (Layer 1: World_Solid)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1) # Layer 1
	tileset.set_physics_layer_collision_mask(0, 0)

	var source = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Atlas karolarını tanımla
	for x in range(4):
		for y in range(2):
			source.create_tile(Vector2i(x, y))

	# Önce kaynağı TileSet'e bağla, böylece TileData fizik katmanına erişebilir
	tileset.add_source(source, 0)

	# Su karolarına (2,0 ve 3,1) tam blok çarpışma ekle
	var water_coords = [Vector2i(2, 0), Vector2i(3, 1)]
	var poly = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8),
		Vector2(8, 8), Vector2(-8, 8)
	])

	for wc in water_coords:
		var tile_data = source.get_tile_data(wc, 0)
		if tile_data:
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, poly)

	return tileset

static func _fill_tile_noise(img: Image, ox: int, oy: int, c1: Color, c2: Color) -> void:
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var col = c1 if ((x + y + (x * y)) % 3 != 0) else c2
			# Dış kenar 1 piksel hafif ton
			if x == 0 or y == 0:
				col = col.lerp(Color.BLACK, 0.1)
			img.set_pixel(ox + x, oy + y, col)

static func _draw_dots(img: Image, ox: int, oy: int, dot_color: Color) -> void:
	img.set_pixel(ox + 4, oy + 4, dot_color)
	img.set_pixel(ox + 5, oy + 4, dot_color)
	img.set_pixel(ox + 11, oy + 9, dot_color)
	img.set_pixel(ox + 10, oy + 10, dot_color)
