extends CanvasLayer

# Project T - Zaman & NPC Sosyal İzleme Paneli (Debug UI)
# Ekran köşesinde saat, gün, dönem ve 3 NPC'nin (Boran, Mira, Kemal) durumlarını ve aralarındaki etkileşimi gösterir.

@onready var label_time: Label = $PanelContainer/VBoxContainer/LabelTime
@onready var label_period: Label = $PanelContainer/VBoxContainer/LabelPeriod
@onready var label_boran: Label = $PanelContainer/VBoxContainer/LabelBoran
@onready var label_mira: Label = $PanelContainer/VBoxContainer/LabelMira
@onready var label_kemal: Label = $PanelContainer/VBoxContainer/LabelKemal
@onready var label_social: Label = $PanelContainer/VBoxContainer/LabelSocial
@onready var btn_speed: Button = $PanelContainer/VBoxContainer/BtnSpeed

var speed_multipliers: Array[float] = [1.0, 10.0, 60.0]
var current_speed_idx: int = 0

func _ready() -> void:
	if btn_speed:
		btn_speed.pressed.connect(_on_speed_button_pressed)
	_update_speed_button_text()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			_cycle_speed()

func _process(_delta: float) -> void:
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		if label_time:
			label_time.text = "Saat: %s (Gün %d)" % [tm.get_time_string(), tm.current_day]
		if label_period:
			var period_tr = ""
			match tm.current_period:
				"dawn": period_tr = "Şafak"
				"day": period_tr = "Gündüz"
				"dusk": period_tr = "Alacakaranlık"
				"night": period_tr = "Gece"
			label_period.text = "Dönem: %s" % period_tr

	# 3 NPC'yi bul ve durumlarını yaz
	var boran = get_node_or_null("../Region/TestLocation/YSort_Entities/BlacksmithBoran")
	var mira = get_node_or_null("../Region/TestLocation/YSort_Entities/InnkeeperMira")
	var kemal = get_node_or_null("../Region/TestLocation/YSort_Entities/FarmerKemal")

	if boran and label_boran:
		label_boran.text = "Boran: %s" % _state_to_text(boran.current_state)
	if mira and label_mira:
		var extra = " (Biliyor: Orak)" if mira.memory and mira.memory.has_info("kemal_lost_tool") else ""
		label_mira.text = "Mira: %s%s" % [_state_to_text(mira.current_state), extra]
	if kemal and label_kemal:
		label_kemal.text = "Kemal: %s" % _state_to_text(kemal.current_state)

	if label_social:
		if (boran and boran.current_state == BaseNPC.State.CHATTING) or (mira and mira.current_state == BaseNPC.State.CHATTING) or (kemal and kemal.current_state == BaseNPC.State.CHATTING):
			label_social.text = "Sosyal: NPC'ler Sohbet Ediyor!"
			label_social.modulate = Color(0.4, 1.0, 0.4)
		else:
			label_social.text = "Sosyal: Normal akış"
			label_social.modulate = Color(0.7, 0.7, 0.7)

func _state_to_text(st: int) -> String:
	match st:
		BaseNPC.State.IDLE: return "Boşta"
		BaseNPC.State.WALK: return "Yürüyor"
		BaseNPC.State.WORK: return "Çalışıyor"
		BaseNPC.State.SOCIALIZE: return "Meydanda/Handa"
		BaseNPC.State.SLEEP: return "Uyuyor"
		BaseNPC.State.EAT: return "Yemek Yiyor"
		BaseNPC.State.REST: return "Dinleniyor"
		BaseNPC.State.CHATTING: return "SOHBET EDİYOR"
	return "Bilinmiyor"

func _cycle_speed() -> void:
	current_speed_idx = (current_speed_idx + 1) % speed_multipliers.size()
	var new_scale = speed_multipliers[current_speed_idx]
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.set_time_scale(new_scale)
	_update_speed_button_text()

func _update_speed_button_text() -> void:
	if btn_speed:
		var cur_scale = speed_multipliers[current_speed_idx]
		btn_speed.text = "Hız: %.0fx (T)" % cur_scale

func _on_speed_button_pressed() -> void:
	_cycle_speed()
