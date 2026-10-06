@tool
extends CanvasLayer
class_name WeatherVisualController

# Project T - Dinamik Hava Durumu Görsel Efektleri (Parçacıklar, Sis Perdesi, Ortam Karartması)
# Yağmur çizgileri, rüzgâr sapması, fırtına şimşeği ve sis katmanı

var weather_manager: WeatherManager = null
var rain_drops: Array[Dictionary] = []
var fog_particles: Array[Dictionary] = []
var flash_timer: float = 0.0
var flash_alpha: float = 0.0

var darkness_overlay: ColorRect
var custom_drawer: Control

const MAX_RAIN_DROPS: int = 140
const MAX_FOG_PARTICLES: int = 24

func _ready() -> void:
	layer = 20
	_setup_components()
	_init_particles()

func _setup_components() -> void:
	darkness_overlay = ColorRect.new()
	darkness_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	darkness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	darkness_overlay.color = Color(0, 0, 0, 0)
	add_child(darkness_overlay)

	custom_drawer = Control.new()
	custom_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_drawer.draw.connect(_on_custom_draw)
	add_child(custom_drawer)

func _init_particles() -> void:
	var vp = Vector2(640, 360)
	rain_drops.clear()
	for i in range(MAX_RAIN_DROPS):
		rain_drops.append({
			"pos": Vector2(randf() * vp.x, randf() * vp.y),
			"speed": randf_range(280.0, 420.0),
			"len": randf_range(8.0, 14.0)
		})

	fog_particles.clear()
	for i in range(MAX_FOG_PARTICLES):
		fog_particles.append({
			"pos": Vector2(randf() * vp.x, randf() * vp.y),
			"radius": randf_range(40.0, 80.0),
			"speed": randf_range(10.0, 25.0),
			"alpha": randf_range(0.08, 0.18)
		})

func _process(delta: float) -> void:
	if not weather_manager:
		weather_manager = get_tree().get_first_node_in_group("weather_manager") as WeatherManager
		if not weather_manager:
			return

	var vp = custom_drawer.get_viewport_rect().size
	if vp.x <= 0 or vp.y <= 0:
		vp = Vector2(640, 360)

	var cur_w = weather_manager.current_weather
	var is_storm = (cur_w == WeatherManager.WeatherType.STORM)
	var is_rain = (cur_w == WeatherManager.WeatherType.RAIN or is_storm)
	var is_fog = (cur_w == WeatherManager.WeatherType.FOG)

	# 1. Ortam Karartma Rengi
	var target_darkness = 0.0
	if is_rain: target_darkness = 0.22
	if is_fog: target_darkness = 0.15
	if is_storm: target_darkness = 0.38
	darkness_overlay.color.a = lerp(darkness_overlay.color.a, target_darkness, delta * 2.0)

	# 2. Şimşek Parlaması (Sadece Fırtınada)
	if is_storm:
		flash_timer -= delta
		if flash_timer <= 0.0:
			flash_timer = randf_range(3.5, 9.0)
			flash_alpha = 0.65 # Şimşek çakışı
		if flash_alpha > 0.0:
			flash_alpha = move_toward(flash_alpha, 0.0, delta * 2.8)

	# 3. Yağmur Parçacıkları Güncelleme
	if is_rain:
		var wind_x = weather_manager.wind_vector.x
		for d in rain_drops:
			d["pos"].y += d["speed"] * delta
			d["pos"].x += wind_x * delta
			if d["pos"].y > vp.y:
				d["pos"].y = -10.0
				d["pos"].x = randf() * vp.x
			if d["pos"].x > vp.x:
				d["pos"].x = 0.0

	# 4. Sis Parçacıkları Güncelleme
	if is_fog:
		for f in fog_particles:
			f["pos"].x += f["speed"] * delta
			if f["pos"].x - f["radius"] > vp.x:
				f["pos"].x = -f["radius"]
				f["pos"].y = randf() * vp.y

	custom_drawer.queue_redraw()

func _on_custom_draw() -> void:
	if not weather_manager:
		return

	var cur_w = weather_manager.current_weather
	var is_storm = (cur_w == WeatherManager.WeatherType.STORM)
	var is_rain = (cur_w == WeatherManager.WeatherType.RAIN or is_storm)
	var is_fog = (cur_w == WeatherManager.WeatherType.FOG)

	# Şimşek beyazlığı
	if flash_alpha > 0.01:
		custom_drawer.draw_rect(custom_drawer.get_viewport_rect(), Color(1, 1, 1, flash_alpha))

	# Sis tabakası
	if is_fog:
		for f in fog_particles:
			custom_drawer.draw_circle(f["pos"], f["radius"], Color(0.85, 0.9, 0.92, f["alpha"]))

	# Yağmur damlaları
	if is_rain:
		var wind_x = weather_manager.wind_vector.x * 0.06
		var col_drop = Color("93c5fd", 0.65) if is_storm else Color("bfdbfe", 0.45)
		for d in rain_drops:
			var start_p = d["pos"]
			var end_p = start_p + Vector2(wind_x, d["len"])
			custom_drawer.draw_line(start_p, end_p, col_drop, 1.2)
