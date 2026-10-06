extends CanvasLayer

# Project T - Keşif ve Bildirim Yöneticisi (DiscoveryManager)
# Autoload Singleton: DiscoveryManager
# Yeni konumlar (Açıklık, Gözetleme Kulesi, Mağara) ilk keşfedildiğinde zarif pixel-art bildirim gösterir.

signal location_discovered(location_id: String, location_title: String)

var discovered_locations: Dictionary = {}

@onready var panel: PanelContainer = $PanelContainer
@onready var label_title: Label = $PanelContainer/MarginContainer/VBoxContainer/LabelTitle
@onready var label_subtitle: Label = $PanelContainer/MarginContainer/VBoxContainer/LabelSubtitle

var display_timer: float = 0.0

func _ready() -> void:
	if panel:
		panel.visible = false
		panel.modulate.a = 0.0

func _process(delta: float) -> void:
	if display_timer > 0.0:
		display_timer -= delta
		if panel:
			# Yumuşak belirme ve kaybolma (Fade-in / Fade-out)
			if display_timer > 3.2:
				panel.modulate.a = lerp(panel.modulate.a, 1.0, delta * 5.0)
			elif display_timer < 0.8:
				panel.modulate.a = lerp(panel.modulate.a, 0.0, delta * 4.0)
			else:
				panel.modulate.a = 1.0

		if display_timer <= 0.0 and panel:
			panel.visible = false

# Konum keşfi fonksiyonu - Sadece ilk keşifte bildirim oluşturur
func discover_location(loc_id: String, loc_title: String, subtitle: String = "Yeni Bölge Keşfedildi") -> bool:
	if discovered_locations.has(loc_id):
		return false # Daha önce keşfedilmiş, tekrar tetikleme!

	discovered_locations[loc_id] = true
	location_discovered.emit(loc_id, loc_title)

	if label_title:
		label_title.text = loc_title
	if label_subtitle:
		label_subtitle.text = subtitle

	if panel:
		panel.visible = true
		panel.modulate.a = 0.0
		display_timer = 4.0 # 4 saniye ekranda kalır

	return true

func is_discovered(loc_id: String) -> bool:
	return discovered_locations.has(loc_id)
