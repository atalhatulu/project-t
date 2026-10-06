extends Node

# Project T - Küresel Zaman Yöneticisi (TimeManager)
# Autoload / Global Singleton: TimeManager
# 24 saatlik döngü, ayarlanabilir akış (varsayılan: 1 oyun günü = 30 gerçek dakika = 1800 saniye)

signal time_tick(hour: int, minute: int)
signal hour_changed(new_hour: int)
signal day_changed(new_day: int)
signal period_changed(period_name: String) # "dawn", "day", "dusk", "night"

const REAL_SECONDS_PER_DAY_DEFAULT: float = 1800.0 # 30 dakika

# Dışarıdan ayarlanabilir değişkenler
var real_seconds_per_day: float = REAL_SECONDS_PER_DAY_DEFAULT
var time_scale: float = 1.0 # Hızlandırma katsayısı (debug/test için)
var is_paused: bool = false

# Güncel zaman durumu
var total_game_seconds: float = 0.0 # Gün içi geçen oyun saniyesi (0 .. 86400)
var current_day: int = 1
var current_hour: int = 8 # Varsayılan sabah 08:00
var current_minute: int = 0

var current_period: String = "day"

func _ready() -> void:
	# Başlangıç saati 08:00 olarak ayarla (8 * 3600 = 28800 oyun saniyesi)
	total_game_seconds = float(current_hour * 3600)
	_update_time_values(true)

func _process(delta: float) -> void:
	if is_paused or real_seconds_per_day <= 0.0:
		return

	# 1 gerçek saniyede geçen oyun saniyesi = 86400 / real_seconds_per_day
	var game_seconds_per_real_second = (86400.0 / real_seconds_per_day) * time_scale
	total_game_seconds += delta * game_seconds_per_real_second

	if total_game_seconds >= 86400.0:
		var days_passed = int(total_game_seconds / 86400.0)
		total_game_seconds = fmod(total_game_seconds, 86400.0)
		current_day += days_passed
		day_changed.emit(current_day)

	_update_time_values(false)

func _update_time_values(force_signals: bool) -> void:
	var total_minutes = int(total_game_seconds / 60.0)
	var new_hour = int(total_minutes / 60) % 24
	var new_minute = total_minutes % 60

	var minute_changed = (new_minute != current_minute) or force_signals
	var hour_has_changed = (new_hour != current_hour) or force_signals

	current_hour = new_hour
	current_minute = new_minute

	if minute_changed:
		time_tick.emit(current_hour, current_minute)

	if hour_has_changed:
		hour_changed.emit(current_hour)

	# Dönem kontrolü
	var new_period = get_period_for_hour(current_hour)
	if new_period != current_period or force_signals:
		current_period = new_period
		period_changed.emit(current_period)

func get_period_for_hour(hour: int) -> String:
	if hour >= 5 and hour < 8:
		return "dawn"      # Şafak (05:00 - 07:59)
	elif hour >= 8 and hour < 18:
		return "day"       # Gündüz (08:00 - 17:59)
	elif hour >= 18 and hour < 21:
		return "dusk"      # Gün batımı / Akşam (18:00 - 20:59)
	else:
		return "night"     # Gece (21:00 - 04:59)

# 0.0 ile 24.0 arasında float saat döner (ışık geçişleri ve lerp hesapları için)
func get_decimal_hour() -> float:
	return float(current_hour) + (float(current_minute) / 60.0)

# Saat metni ("08:45" formatı)
func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

# Zaman hızını ayarla (Örn: 1.0 = normal, 10.0 = 10x hızlı)
func set_time_scale(scale_val: float) -> void:
	time_scale = max(0.0, scale_val)

# Zamanı doğrudan belirli bir saat kadar ilerlet (Hızlı seyahat vb. için)
func advance_time(hours: float) -> void:
	var added_seconds = hours * 3600.0
	total_game_seconds += added_seconds
	if total_game_seconds >= 86400.0:
		var days_passed = int(total_game_seconds / 86400.0)
		total_game_seconds = fmod(total_game_seconds, 86400.0)
		current_day += days_passed
		day_changed.emit(current_day)
	_update_time_values(true)

