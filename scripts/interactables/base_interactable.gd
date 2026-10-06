@tool
extends StaticBody2D
class_name BaseInteractable

# Project T - Temel Etkileşimli Çevre Nesnesi
# Benzersiz ID, durum takibi, prompt entegrasyonu ve diyalog/dünya geri bildirimi

signal interacted(player_node: CharacterBody2D)
signal state_changed(new_state: String)

@export var interactable_id: String = ""
@export var interactable_name: String = "Nesne"
@export var prompt_action_text: String = "İncele"
@export var is_interactable: bool = true

var current_state: String = "default"
var interact_area: Area2D
var prompt_node: InteractablePrompt

func _init() -> void:
	prompt_node = InteractablePrompt.new()
	prompt_node.name = "InteractablePrompt"
	add_child(prompt_node)

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 0
	_setup_interaction_components()
	_apply_state()

func _setup_interaction_components() -> void:
	interact_area = get_node_or_null("InteractionArea")
	if not interact_area:
		interact_area = Area2D.new()
		interact_area.name = "InteractionArea"
		interact_area.collision_layer = 32 # Layer 6: Interactions
		interact_area.collision_mask = 2  # Layer 2: Player
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 22.0
		col.shape = shape
		interact_area.add_child(col)
		add_child(interact_area)

	prompt_node = get_node_or_null("InteractablePrompt")
	if not prompt_node:
		prompt_node = InteractablePrompt.new()
		prompt_node.name = "InteractablePrompt"
		add_child(prompt_node)

func set_prompt_highlight(active: bool) -> void:
	if not prompt_node:
		_setup_interaction_components()

	if not prompt_node or not is_interactable:
		if prompt_node:
			prompt_node.hide_prompt()
		return

	if active:
		prompt_node.show_prompt(get_action_prompt_text())
	else:
		prompt_node.hide_prompt()

func get_action_prompt_text() -> String:
	return prompt_action_text

# Oyuncu E bastığında çağrılır
func interact_with(_player: CharacterBody2D) -> void:
	if not is_interactable:
		return
	interacted.emit(_player)
	_on_interacted(_player)

func _on_interacted(_player: CharacterBody2D) -> void:
	pass

func _apply_state() -> void:
	queue_redraw()

func get_save_data() -> Dictionary:
	return {
		"id": interactable_id,
		"state": current_state,
		"is_interactable": is_interactable
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("state"):
		current_state = data["state"]
	if data.has("is_interactable"):
		is_interactable = data["is_interactable"]
	_apply_state()

func _draw_oval_shadow(pos: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(16):
		var rad = (float(i) / 16.0) * TAU
		pts.append(pos + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(pts, col)
