@tool
extends CharacterBody2D
class_name PushableRock

# Project T - İtilebilir Ağır Zindan Kayası (PushableRock)
# Oyuncu kayaya doğru yürüdüğünde veya etkileşime girdiğinde ızgara/piksel mesafesinde kayar.

@export var rock_id: String = "rock_puzzle_01"
@export var push_speed: float = 40.0
@export var is_moving: bool = false

var target_position: Vector2 = Vector2.ZERO
var start_push_timer: float = 0.0

func _ready() -> void:
	add_to_group("pushable_rock")
	add_to_group("interactable")
	collision_layer = 4 # Object Layer
	collision_mask = 1 | 2 # World Solid (1) ve Player (2)
	target_position = global_position
	
	var col = get_node_or_null("CollisionShape2D")
	if not col:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var box = RectangleShape2D.new()
		box.size = Vector2(26, 24)
		col.shape = box
		add_child(col)
	
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_moving:
		global_position = global_position.move_toward(target_position, push_speed * delta)
		if global_position.distance_to(target_position) < 1.0:
			global_position = target_position
			is_moving = false
			velocity = Vector2.ZERO
		return

	# Oyuncunun kayaya doğru itme temasını kontrol et
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < 26.0:
			var push_dir = (global_position - player.global_position).normalized()
			# Baskın ekseni seç (Izgara yönü: Yukarı, Aşağı, Sol, Sağ)
			var grid_dir = Vector2.ZERO
			if abs(push_dir.x) > abs(push_dir.y):
				grid_dir = Vector2.RIGHT if push_dir.x > 0 else Vector2.LEFT
			else:
				grid_dir = Vector2.DOWN if push_dir.y > 0 else Vector2.UP
			
			start_push_timer += delta
			if start_push_timer >= 0.25: # Kısa süreli itişten sonra kayar
				start_push_timer = 0.0
				try_push(grid_dir)
		else:
			start_push_timer = 0.0

func try_push(dir: Vector2) -> bool:
	if is_moving:
		return false
	
	var new_pos = global_position + dir * 32.0 # 2 karo mesafesi kayar
	
	# Raycast ile önünde duvar/engel var mı kontrol et
	if is_inside_tree() and get_world_2d() != null:
		var space = get_world_2d().direct_space_state
		if space:
			var query = PhysicsRayQueryParameters2D.create(global_position, new_pos)
			query.collision_mask = 1 # Solid obstacle
			query.exclude = [self]
			var hit = space.intersect_ray(query)
			if not hit.is_empty():
				return false
	
	target_position = new_pos
	is_moving = true
	
	# Ses
	var am = get_node_or_null("/root/AudioManager")
	if am and is_inside_tree() and am.has_method("play_footstep"):
		am.play_footstep(2) # Taş sürtünme sesi
	return true

func _draw() -> void:
	# Taban gölgesi
	draw_circle(Vector2(0, 8), 14.0, Color(0, 0, 0, 0.4))
	
	# Oyuklu kadim kaya
	draw_circle(Vector2(0, 0), 13.0, Color("475569"))
	draw_circle(Vector2(-3, -3), 11.0, Color("64748b"))
	draw_circle(Vector2(-5, -5), 8.0, Color("94a3b8"))
	
	# Üzerindeki rün / itme sembolü
	draw_line(Vector2(-4, 0), Vector2(4, 0), Color("38bdf8"), 1.5)
	draw_line(Vector2(0, -4), Vector2(0, 4), Color("38bdf8"), 1.5)

func get_save_data() -> Dictionary:
	return {
		"id": rock_id,
		"position": [global_position.x, global_position.y]
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("position") and data["position"] is Array and data["position"].size() >= 2:
		global_position = Vector2(data["position"][0], data["position"][1])
		target_position = global_position
