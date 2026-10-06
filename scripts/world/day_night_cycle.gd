extends CanvasModulate

# Project T - Dinamik Çevre Aydınlatması (DayNightCycle)
# CanvasModulate rengini günün saatine göre yumuşakça (lerp) değiştirir.
# Sabah (05-08), Öğle (08-18), Akşam (18-21), Gece (21-05) renk paletleri

@export var dawn_color: Color = Color("e09268")   # Şafak (Sıcak turuncu/pembe)
@export var day_color: Color = Color("ffffff")    # Gündüz (Tam net parlak beyaz)
@export var dusk_color: Color = Color("9d5c63")   # Gün batımı (Kızıl-mor alacakaranlık)
@export var night_color: Color = Color("1e2238")  # Gece (Derin lacivert/mavi)

func _ready() -> void:
	update_lighting()

func _process(_delta: float) -> void:
	update_lighting()

func update_lighting() -> void:
	var tm = get_node_or_null("/root/TimeManager")
	var hour_dec = tm.get_decimal_hour() if tm else 12.0

	var target_color: Color = day_color

	if hour_dec >= 5.0 and hour_dec < 8.0:
		# 05:00 - 08:00 : Gece -> Şafak -> Gündüz
		if hour_dec < 6.5:
			var t = (hour_dec - 5.0) / 1.5
			target_color = night_color.lerp(dawn_color, t)
		else:
			var t = (hour_dec - 6.5) / 1.5
			target_color = dawn_color.lerp(day_color, t)
	elif hour_dec >= 8.0 and hour_dec < 18.0:
		# 08:00 - 18:00 : Gündüz
		target_color = day_color
	elif hour_dec >= 18.0 and hour_dec < 21.0:
		# 18:00 - 21:00 : Gündüz -> Gün batımı -> Gece
		if hour_dec < 19.5:
			var t = (hour_dec - 18.0) / 1.5
			target_color = day_color.lerp(dusk_color, t)
		else:
			var t = (hour_dec - 19.5) / 1.5
			target_color = dusk_color.lerp(night_color, t)
	else:
		# 21:00 - 05:00 : Gece
		target_color = night_color

	# Hava Durumu ve Biyom Tonu ile harmanlama
	var wm = get_tree().get_first_node_in_group("weather_manager")
	if wm and "weather_darkness_tint" in wm:
		target_color = target_color * wm.weather_darkness_tint

	var loc = get_tree().get_first_node_in_group("location")
	var player = get_tree().get_first_node_in_group("player")
	if loc and player and loc.has_method("get_biome_at_world_pos"):
		var biome: BiomeData = loc.get_biome_at_world_pos(player.global_position)
		if biome:
			target_color = target_color * biome.ambient_color_tint

	color = target_color
