@tool
extends Resource
class_name BiomeData

# Project T - Veri Odaklı Biyom Kaynağı (BiomeData)
# Orman, Çayır, Bataklık, Dağ, Kıyı

enum BiomeType {
	MEADOW,  # Çayır (Açık bozkır)
	FOREST,  # Orman (Ağaçlık, gölgeli)
	SWAMP,   # Bataklık (Çamurlu, yavaşlatıcı su/sazlık)
	MOUNTAIN,# Dağ (Kayalık, rüzgarlı, tırmanılabilir tepeler)
	COAST    # Kıyı (Kumul, su kenarı, nemli)
}

@export var biome_type: BiomeType = BiomeType.MEADOW
@export var biome_name: String = "Çayır"
@export var ambient_color_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var movement_speed_multiplier: float = 1.0 # Bataklıkta 0.7 gibi yavaşlatıcı
@export var default_weather_weights: Dictionary = {
	"clear": 0.6,
	"rain": 0.25,
	"fog": 0.1,
	"storm": 0.05
}

static func create_biome(type: BiomeType) -> BiomeData:
	var b = BiomeData.new()
	b.biome_type = type
	match type:
		BiomeType.MEADOW:
			b.biome_name = "Kızıl Çayır"
			b.ambient_color_tint = Color(1.0, 1.0, 1.0, 1.0)
			b.movement_speed_multiplier = 1.0
			b.default_weather_weights = {"clear": 0.60, "rain": 0.25, "fog": 0.10, "storm": 0.05}
		BiomeType.FOREST:
			b.biome_name = "Kadim Yeşil Orman"
			b.ambient_color_tint = Color(0.85, 0.95, 0.85, 1.0)
			b.movement_speed_multiplier = 0.95
			b.default_weather_weights = {"clear": 0.40, "rain": 0.35, "fog": 0.20, "storm": 0.05}
		BiomeType.SWAMP:
			b.biome_name = "Gölgeli Bataklık"
			b.ambient_color_tint = Color(0.82, 0.90, 0.78, 1.0)
			b.movement_speed_multiplier = 0.68 # Bataklık balçığı yavaşlatır!
			b.default_weather_weights = {"clear": 0.15, "rain": 0.35, "fog": 0.45, "storm": 0.05}
		BiomeType.MOUNTAIN:
			b.biome_name = "Rüzgarlı Dağ Tepeleri"
			b.ambient_color_tint = Color(0.92, 0.92, 1.0, 1.0)
			b.movement_speed_multiplier = 0.9
			b.default_weather_weights = {"clear": 0.40, "rain": 0.20, "fog": 0.15, "storm": 0.25}
		BiomeType.COAST:
			b.biome_name = "Nehir & Göl Kıyısı"
			b.ambient_color_tint = Color(0.95, 1.0, 1.0, 1.0)
			b.movement_speed_multiplier = 0.9
			b.default_weather_weights = {"clear": 0.50, "rain": 0.30, "fog": 0.15, "storm": 0.05}
	return b
