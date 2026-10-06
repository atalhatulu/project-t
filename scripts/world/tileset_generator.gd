@tool
extends Node2D

# Project T - Zengin Pixel Art TileSet Üreteci (World of Anterra & Modern Indie Stili)
# Kontrollü renk paleti, organik dithering/ton geçişleri, ot püskülleri, çakıl taşları,
# su kıyı kırılımları ve derin taş kaplamaları.

const TILE_SIZE: int = 16

static func create_placeholder_tileset() -> TileSet:
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Su çarpışma katmanı (Layer 1: World_Solid)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 0)

	# 8x4 karo ızgarası: 128 x 64 piksel
	var img = Image.create(128, 64, false, Image.FORMAT_RGBA8)

	# 1. Zengin Pixel Art Taban Renkleri
	var col_grass = Color("2e5a27")        # 0,0: Çimen
	var col_path = Color("8a6f4d")         # 1,0: Toprak Patika
	var col_water_shallow = Color("2b7a78") # 2,0: Sığ Su
	var col_flowers = Color("386b2f")      # 3,0: Çiçekli Çimen
	var col_bridge = Color("5c4028")       # 4,0: Ahşap Köprü Kalasları
	var col_cliff = Color("4b535d")        # 5,0: Kayalık Tepe Zemini
	var col_glade = Color("234b1d")        # 6,0: Derin Orman Açıklığı
	var col_water_foam = Color("4ca1a3")   # 7,0: Köpüklü Dalgalı Su

	var col_stone_square = Color("6b7280") # 0,1: Köy Meydanı Parke Taş
	var col_sand = Color("c2a66d")         # 1,1: Kıyı Kumu
	var col_swamp = Color("2d3b24")        # 2,1: Bataklık Balçığı
	var col_water_deep = Color("174d5c")   # 3,1: Derin Göl/Nehir Suyu
	var col_cliff_moss = Color("3e473a")   # 5,1: Yosunlu Dağ Zemini
	var col_path_edge = Color("735b3e")    # 6,1: Patika Kenar Geçişi
	var col_shore_edge = Color("8c734b")   # 7,1: Kıyı Kenar Geçişi

	# Tabanları boya
	_fill_tile(img, 0, 0, col_grass)
	_fill_tile(img, 1, 0, col_path)
	_fill_tile(img, 2, 0, col_water_shallow)
	_fill_tile(img, 3, 0, col_flowers)
	_fill_tile(img, 4, 0, col_bridge)
	_fill_tile(img, 5, 0, col_cliff)
	_fill_tile(img, 6, 0, col_glade)
	_fill_tile(img, 7, 0, col_water_foam)

	_fill_tile(img, 0, 1, col_stone_square)
	_fill_tile(img, 1, 1, col_sand)
	_fill_tile(img, 2, 1, col_swamp)
	_fill_tile(img, 3, 1, col_water_deep)
	_fill_tile(img, 5, 1, col_cliff_moss)
	_fill_tile(img, 6, 1, col_path_edge)
	_fill_tile(img, 7, 1, col_shore_edge)

	# -------------------------------------------------------------
	# 2. AYRINTILI PİKSEL SANATI DOKULANDIRMA (Dithering & Highlights)
	# -------------------------------------------------------------

	# (0,0) ÇİMEN: Ot püskülleri, ışık kırılımları ve gölgeli derinlik
	var g_high = Color("3d7335")
	var g_dark = Color("23451e")
	var g_deep = Color("1a3516")
	# Ot tutamları
	_draw_grass_clump(img, 2, 3, g_high, g_dark)
	_draw_grass_clump(img, 9, 8, g_high, g_dark)
	_draw_grass_clump(img, 12, 2, g_high, g_dark)
	_draw_grass_clump(img, 5, 12, g_high, g_dark)
	# Rastgele gölge benekleri (dümdüzlüğü kıran dither)
	img.set_pixel(1, 9, g_dark)
	img.set_pixel(7, 4, g_deep)
	img.set_pixel(14, 14, g_dark)

	# (3,0) ÇİÇEKLİ ÇİMEN: Sarı düğünçiçekleri, beyaz papatyalar ve kırmızı dağ sümbülleri
	_draw_grass_clump(img, 48 + 3, 3, Color("46853e"), Color("254a1f"))
	_draw_grass_clump(img, 48 + 11, 10, Color("46853e"), Color("254a1f"))
	# Çiçek 1: Sarı
	img.set_pixel(48 + 5, 5, Color("facc15"))
	img.set_pixel(48 + 6, 5, Color("fef08a"))
	img.set_pixel(48 + 5, 6, Color("ca8a04"))
	# Çiçek 2: Beyaz/Mavi papatya
	img.set_pixel(48 + 11, 4, Color("ffffff"))
	img.set_pixel(48 + 12, 4, Color("93c5fd"))
	img.set_pixel(48 + 11, 5, Color("e2e8f0"))
	# Çiçek 3: Kızıl çiçek
	img.set_pixel(48 + 4, 11, Color("ef4444"))
	img.set_pixel(48 + 5, 11, Color("f87171"))
	img.set_pixel(48 + 4, 12, Color("b91c1c"))

	# (1,0) TOPRAK PATİKA: Çakıllar, tekerlek izi gölgeleri ve aşınmış toprak
	var p_high = Color("9c805c")
	var p_dark = Color("6d5438")
	var p_pebble = Color("4a3723")
	var p_light_pebble = Color("b59873")
	# Çakıl taşları (küçük piksel grupları)
	img.set_pixel(16 + 4, 4, p_light_pebble)
	img.set_pixel(16 + 5, 4, p_pebble)
	img.set_pixel(16 + 10, 9, p_light_pebble)
	img.set_pixel(16 + 11, 9, p_pebble)
	# Patika boyunca organik aşınma lekeleri
	for x in range(2, 14):
		if x % 3 == 0:
			img.set_pixel(16 + x, 6, p_dark)
			img.set_pixel(16 + x, 12, p_high)

	# (6,1) PATİKA KENAR GEÇİŞİ (Çimenle karışan toprak)
	for x in range(16):
		if (x * 7) % 3 == 0:
			img.set_pixel(96 + x, 16 + 2, g_dark)
			img.set_pixel(96 + x, 16 + 13, g_high)

	# (4,0) AHŞAP KÖPRÜ: Derin derzler, ahşap damarları ve paslı çiviler
	for py in range(TILE_SIZE):
		if py % 4 == 0:
			for px in range(TILE_SIZE):
				img.set_pixel(64 + px, py, Color("302012")) # Kalas boşluğu
		elif py % 4 == 1:
			for px in range(TILE_SIZE):
				img.set_pixel(64 + px, py, Color("6f4d30")) # Üst ışık
		else:
			# Paslı çiviler
			img.set_pixel(64 + 1, py, Color("20140b"))
			img.set_pixel(64 + 2, py, Color("8a6341"))
			img.set_pixel(64 + 13, py, Color("8a6341"))
			img.set_pixel(64 + 14, py, Color("20140b"))

	# (0,1) KÖY MEYDANI PARKE TAŞ (Özenli Taş Döşeme)
	for py in range(16, 32):
		for px in range(16):
			var local_y = py - 16
			# Taş derz çizgileri
			if local_y % 5 == 0 or (local_y < 5 and px % 8 == 0) or (local_y >= 5 and local_y < 10 and (px + 4) % 8 == 0) or (local_y >= 10 and px % 8 == 0):
				img.set_pixel(px, py, Color("374151")) # Koyu harç
			elif (px + local_y) % 7 == 1:
				img.set_pixel(px, py, Color("9ca3af")) # Işıltılı taş yüzeyi
			elif (px * 3 + local_y * 2) % 11 == 0:
				img.set_pixel(px, py, Color("525a66")) # Gölgeli taş yüzeyi

	# (2,0) SIĞ SU & (3,1) DERİN SU: Güneş pırıltıları ve akıntı çizgileri
	# Sığ su (2,0)
	var w_sh_high = Color("45b5b0")
	var w_sh_sparkle = Color("e0fdfd")
	img.set_pixel(32 + 3, 4, w_sh_high)
	img.set_pixel(32 + 4, 4, w_sh_sparkle)
	img.set_pixel(32 + 5, 4, w_sh_high)
	img.set_pixel(32 + 10, 11, w_sh_high)
	img.set_pixel(32 + 11, 11, w_sh_sparkle)
	img.set_pixel(32 + 12, 11, w_sh_high)
	# Derin su (3,1)
	var w_dp_dark = Color("0e333d")
	var w_dp_light = Color("23697a")
	img.set_pixel(48 + 4, 16 + 3, w_dp_light)
	img.set_pixel(48 + 5, 16 + 3, w_dp_light)
	img.set_pixel(48 + 11, 16 + 9, w_dp_light)
	img.set_pixel(48 + 12, 16 + 9, w_dp_light)
	img.set_pixel(48 + 8, 16 + 14, w_dp_dark)

	# (7,0) KÖPÜKLÜ DALGALI SU: Organik kıyı dalga köpükleri
	for px in range(2, 14):
		img.set_pixel(112 + px, 6, Color("f0fdfa"))
		img.set_pixel(112 + px, 7, Color("99f6e4"))
		if px % 3 != 0:
			img.set_pixel(112 + px, 8, Color("2dd4bf"))

	# (5,0) KAYALIK TEPE & (5,1) YOSUNLU DAĞ: Pürüzlü kayalık fasetleri
	var r_dark = Color("33373d")
	var r_high = Color("6b7280")
	var r_moss = Color("4d7c0f")
	# Kayalık 5,0
	img.set_pixel(80 + 3, 3, r_high)
	img.set_pixel(80 + 4, 3, r_high)
	img.set_pixel(80 + 3, 4, r_dark)
	img.set_pixel(80 + 11, 8, r_high)
	img.set_pixel(80 + 12, 9, r_dark)
	# Yosunlu kaya 5,1
	img.set_pixel(80 + 4, 16 + 4, r_moss)
	img.set_pixel(80 + 5, 16 + 4, r_moss)
	img.set_pixel(80 + 6, 16 + 5, Color("65a30d"))
	img.set_pixel(80 + 10, 16 + 11, r_moss)

	var texture = ImageTexture.create_from_image(img)
	var source = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# 8x4 Grid Karolarını Tanımla
	for x in range(8):
		for y in range(4):
			source.create_tile(Vector2i(x, y))

	tileset.add_source(source, 0)
	return tileset

static func _fill_tile(img: Image, tile_x: int, tile_y: int, col: Color) -> void:
	var start_x = tile_x * TILE_SIZE
	var start_y = tile_y * TILE_SIZE
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			img.set_pixel(start_x + x, start_y + y, col)

static func _draw_grass_clump(img: Image, start_x: int, start_y: int, high_col: Color, shadow_col: Color) -> void:
	# 3 piksellik sevimli ot tutamı
	img.set_pixel(start_x, start_y, high_col)
	img.set_pixel(start_x - 1, start_y + 1, high_col)
	img.set_pixel(start_x + 1, start_y + 1, high_col)
	img.set_pixel(start_x, start_y + 2, shadow_col)
