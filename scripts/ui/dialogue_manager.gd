extends CanvasLayer

# Project T - Küresel Diyalog Sistemi (DialogueManager)
# Autoload Singleton: DialogueManager

signal dialogue_started(speaker_name: String, text: String)
signal dialogue_ended

var is_dialogue_active: bool = false
var current_speaker: String = ""
var current_text: String = ""

# E ile açıldıktan hemen sonra aynı karede kapanmasını önleyen tampon zamanlayıcı
var input_cooldown: float = 0.0

@onready var panel: PanelContainer = $PanelContainer
@onready var label_name: Label = $PanelContainer/MarginContainer/VBoxContainer/LabelSpeaker
@onready var label_dialogue: Label = $PanelContainer/MarginContainer/VBoxContainer/LabelText
@onready var label_hint: Label = $PanelContainer/MarginContainer/VBoxContainer/LabelHint

func _ready() -> void:
	if panel:
		panel.visible = false

func _process(delta: float) -> void:
	if input_cooldown > 0.0:
		input_cooldown -= delta

func _unhandled_input(event: InputEvent) -> void:
	if not is_dialogue_active:
		return

	if input_cooldown > 0.0:
		return

	# E tuşu, Boşluk veya Enter ile diyaloğu kapat
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if not event.is_echo():
			get_viewport().set_input_as_handled()
			end_dialogue()

func start_dialogue(speaker: String, text: String) -> void:
	is_dialogue_active = true
	input_cooldown = 0.25 # 250ms basma koruması (aynı E tuşunun kapanışı tetiklemesini önler)
	current_speaker = speaker
	current_text = text

	if label_name:
		label_name.text = speaker
	if label_dialogue:
		label_dialogue.text = text
	if panel:
		panel.visible = true

	dialogue_started.emit(speaker, text)

func end_dialogue() -> void:
	if not is_dialogue_active:
		return
	is_dialogue_active = false
	input_cooldown = 0.25
	if panel:
		panel.visible = false
	dialogue_ended.emit()
