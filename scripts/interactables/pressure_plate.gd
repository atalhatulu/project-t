@tool
extends Node2D
class_name PressurePlate

# Project T - Basılabilir Zemin Anahtarı / Ağırlık Plakası
# Oyuncu veya itilebilir kaya üzerine geldiğinde aktifleşir; bağlı kapıyı/mekanizmayı tetikler.

signal activated
signal deactivated

@export var plate_id: String = "plate_01"
@export var is_pressed: bool = false
@export var target_door_path: NodePath
@export var stays_pressed: bool = true # Bir kez basılınca kilitli mi kalsın

var overlapping_bodies: Array[Node2D] = []

func _ready() -> void:
	add_to_group("pressure_plate")
	add_to_group("interactable")
	
	var area = get_node_or_null("Area2D")
	if not area:
		area = Area2D.new()
		area.name = "Area2D"
		area.collision_layer = 0
		area.collision_mask = 2 | 4 # Player (2) ve Nesneler/Kaya (4)
		var shape = CollisionShape2D.new()
		var box = RectangleShape2D.new()
		box.size = Vector2(24, 24)
		shape.shape = box
		area.add_child(shape)
		add_child(area)
	
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)
	if not area.body_exited.is_connected(_on_body_exited):
		area.body_exited.connect(_on_body_exited)
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if not overlapping_bodies.has(body):
		overlapping_bodies.append(body)
	if not is_pressed:
		press_plate()

func _on_body_exited(body: Node2D) -> void:
	if overlapping_bodies.has(body):
		overlapping_bodies.erase(body)
	if overlapping_bodies.is_empty() and not stays_pressed and is_pressed:
		release_plate()

func press_plate() -> void:
	is_pressed = true
	queue_redraw()
	activated.emit()
	
	# Ses efekti
	var am = get_node_or_null("/root/AudioManager")
	if am and is_inside_tree() and am.has_method("play_interact_sound"):
		am.play_interact_sound("chest")
	
	# Bağlı kapıyı aç
	if target_door_path != NodePath(""):
		var door = get_node_or_null(target_door_path)
		if door and door.has_method("unlock_and_open"):
			door.unlock_and_open()

func release_plate() -> void:
	is_pressed = false
	queue_redraw()
	deactivated.emit()

func _draw() -> void:
	# Kare taş kaide
	draw_rect(Rect2(-14, -14, 28, 28), Color("1e293b"))
	draw_rect(Rect2(-12, -12, 24, 24), Color("334155"))
	
	# İç düğme/plaka
	var col_plate = Color("38bdf8") if is_pressed else Color("64748b")
	var size_inset = 18.0 if not is_pressed else 20.0
	var offset = -size_inset * 0.5
	draw_rect(Rect2(offset, offset, size_inset, size_inset), col_plate)
	if is_pressed:
		draw_rect(Rect2(offset + 3, offset + 3, size_inset - 6, size_inset - 6), Color("0284c7"))

func get_save_data() -> Dictionary:
	return {
		"id": plate_id,
		"is_pressed": is_pressed
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("is_pressed") and data["is_pressed"]:
		press_plate()
