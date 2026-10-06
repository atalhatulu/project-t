@tool
extends Node
class_name WeatherManager

# Project T - Modüler Dinamik Hava Durumu Yöneticisi (WeatherManager)
# Hava Durumları: Açık (CLEAR), Yağmurlu (RAIN), Sisli (FOG), Fırtınalı (STORM)
# Ortam kararması, parçacık efektleri, rüzgâr, hız cezaları ve ateş söndürme

signal weather_changed(new_weather: WeatherType)

enum WeatherType {
	CLEAR,  # Açık (Güneşli / Normal)
	RAIN,   # Yağmurlu (Yağmur damlaları, ateşi söndürür)
	FOG,    # Sisli (Düşük görüş mesafesi, sis perdesi)
	STORM   # Fırtınalı (Şiddetli yağmur, rüzgâr direnci, şimşek parlaması)
}

@export var current_weather: WeatherType = WeatherType.CLEAR
@export var weather_duration_hours: float = 6.0
var weather_timer_hours: float = 6.0

# Hava Durumu Etkileri
var speed_multiplier: float = 1.0
var weather_darkness_tint: Color = Color.WHITE
var wind_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("weather_manager")
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.hour_changed.connect(_on_hour_changed)
	_apply_weather_effects()

func _on_hour_changed(_new_hour: int) -> void:
	weather_timer_hours -= 1.0
	if weather_timer_hours <= 0.0:
		weather_timer_hours = randf_range(4.0, 8.0)
		_pick_next_weather()

func set_weather(weather: WeatherType) -> void:
	current_weather = weather
	_apply_weather_effects()
	weather_changed.emit(current_weather)

func _pick_next_weather() -> void:
	# Biyoma veya varsayılan ağırlığa göre seç
	var roll = randf()
	var next_w = WeatherType.CLEAR
	if roll < 0.45:
		next_w = WeatherType.CLEAR
	elif roll < 0.75:
		next_w = WeatherType.RAIN
	elif roll < 0.90:
		next_w = WeatherType.FOG
	else:
		next_w = WeatherType.STORM
	set_weather(next_w)

func _apply_weather_effects() -> void:
	match current_weather:
		WeatherType.CLEAR:
			speed_multiplier = 1.0
			weather_darkness_tint = Color(1.0, 1.0, 1.0, 1.0)
			wind_vector = Vector2(10.0, 5.0)
		WeatherType.RAIN:
			speed_multiplier = 0.92 # Hafif yavaşlama (cezalandırıcı değil)
			weather_darkness_tint = Color(0.78, 0.82, 0.92, 1.0) # Yağmur loşluğu
			wind_vector = Vector2(40.0, 15.0)
			_extinguish_open_fires()
		WeatherType.FOG:
			speed_multiplier = 0.95
			weather_darkness_tint = Color(0.85, 0.88, 0.88, 1.0) # Soluk sis rengi
			wind_vector = Vector2(5.0, 2.0)
		WeatherType.STORM:
			speed_multiplier = 0.84 # Rüzgâr ve çamur direnci
			weather_darkness_tint = Color(0.60, 0.65, 0.78, 1.0) # Fırtına karanlığı
			wind_vector = Vector2(90.0, 30.0)
			_extinguish_open_fires()

func _extinguish_open_fires() -> void:
	# Yağmurda açık fenerlerin ve kamp ateşlerinin sönmesi
	var lanterns = get_tree().get_nodes_in_group("smart_lantern")
	for lantern in lanterns:
		if lantern.has_method("set_extinguished"):
			lantern.set_extinguished(true)

func is_raining() -> bool:
	return current_weather == WeatherType.RAIN or current_weather == WeatherType.STORM
