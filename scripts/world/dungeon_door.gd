@tool
extends BaseInteractable
class_name DungeonDoor

# Project T - Zindan / Mağara Kapısı (DungeonDoor)
# Basit anahtar mekanizması (required_key_id) veya zemin tetikleyicisiyle açılır

signal door_opened

@export var is_locked: bool = true
@export var is_open: bool = false
@export var required_key_id: String = "dungeon_key"
@export var key_display_name: String = "Paslı Zindan Anahtarı"

var door_col: CollisionShape2D

func _init() -> void:
	super._init()
	prompt_action_text = "Kilidi Aç"
	interactable_name = "Kilitli Demir Parmaklık"

func _ready() -> void:
	if interactable_id == "":
		interactable_id = "dungeon_door_" + str(get_instance_id())
	_setup_collision()
	_apply_door_state()
	super._ready()

func _setup_collision() -> void:
	door_col = get_node_or_null("CollisionShape2D")
	if not door_col:
		door_col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(36, 16)
		door_col.shape = shape
		add_child(door_col)

func get_action_prompt_text() -> String:
	if is_open:
		return "Açık"
	return "Kilidi Aç" if is_locked else "Aç"

func _on_interacted(player: CharacterBody2D) -> void:
	if is_open:
		return

	if is_locked:
		if player != null and player.has_method("get_inventory") and required_key_id != "":
			var inv: Inventory = player.get_inventory()
			if inv != null and inv.has_item(required_key_id, 1):
				# Anahtar kullanıldı!
				inv.remove_from_slot(_find_key_slot(inv, required_key_id), 1)
				unlock_and_open()
				var dm = get_node_or_null("/root/DialogueManager")
				if dm and is_inside_tree():
					dm.start_dialogue("Kilit Açıldı", key_display_name + " parmaklık kilidini açtı. Geçit temizlendi!")
				return
		
		var dm = get_node_or_null("/root/DialogueManager")
		if dm and is_inside_tree():
			dm.start_dialogue("Kilitli Parmaklık", "Demir kapı paslı kalın bir zincirle kilitlenmiş. Mağarada " + key_display_name + " aramalısın.")
		return
	else:
		unlock_and_open()

func _find_key_slot(inv: Inventory, key_id: String) -> int:
	for i in range(inv.SLOT_COUNT):
		if inv.slots[i]["item_id"] == key_id:
			return i
	return -1

func unlock_and_open() -> void:
	is_locked = false
	is_open = true
	is_interactable = false
	collision_layer = 0 # Geçilebilir
	_apply_door_state()
	door_opened.emit()
	queue_redraw()

func _apply_door_state() -> void:
	if is_open:
		collision_layer = 0
		if prompt_node:
			prompt_node.hide_prompt()
	else:
		collision_layer = 1

func _draw() -> void:
	if not is_open:
		# Kilitli Demir Parmaklık
		draw_rect(Rect2(-18, -12, 36, 16), Color("2b303a"))
		# Dikey demir parmaklıklar
		for i in range(-14, 15, 6):
			draw_line(Vector2(i, -12), Vector2(i, 4), Color("6b7280"), 2.0)
		# Kilit ve zincir
		draw_circle(Vector2(0, -4), 4.0, Color("f59e0b") if not is_locked else Color("9ca3af"))
	else:
		# Açık Parmaklık (Kenara çekilmiş)
		draw_rect(Rect2(-18, -12, 6, 16), Color("4b5563"))
		draw_rect(Rect2(12, -12, 6, 16), Color("4b5563"))
