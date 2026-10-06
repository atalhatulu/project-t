@tool
extends StaticBody2D
class_name SecretWall

# Project T - Kırılabilir / Gizli Mağara Duvarı (SecretWall)
# Kılıçla 3 kez vurulduğunda veya anahtarla tetiklendiğinde parçalanıp arkasındaki gizli odayı açar.

signal wall_broken

@export var wall_id: String = "secret_wall_01"
@export var hits_required: int = 3
@export var is_broken: bool = false

var current_hits: int = 0
var hurtbox: Area2D
var col_shape: CollisionShape2D

func _ready() -> void:
	add_to_group("secret_wall")
	add_to_group("interactable")
	collision_layer = 1 # Solid Wall
	collision_mask = 0
	
	col_shape = get_node_or_null("CollisionShape2D")
	if not col_shape:
		col_shape = CollisionShape2D.new()
		col_shape.name = "CollisionShape2D"
		var box = RectangleShape2D.new()
		box.size = Vector2(32, 24)
		col_shape.shape = box
		add_child(col_shape)
	
	hurtbox = get_node_or_null("Hurtbox")
	if not hurtbox:
		hurtbox = Area2D.new()
		hurtbox.name = "Hurtbox"
		hurtbox.collision_layer = 16 # Layer 5: Hurtbox
		hurtbox.collision_mask = 8   # Layer 4: Hitbox
		var h_col = CollisionShape2D.new()
		var h_box = RectangleShape2D.new()
		h_box.size = Vector2(34, 26)
		h_col.shape = h_box
		hurtbox.add_child(h_col)
		add_child(hurtbox)
	
	if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	if is_broken:
		break_wall(false)
	queue_redraw()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_broken:
		return
	if area.name == "SwordHitbox" or area.collision_layer == 8:
		take_hit()

func take_hit() -> void:
	current_hits += 1
	
	# Darbe titreşimi ve parçacık
	modulate = Color(1.8, 1.8, 1.8, 1.0)
	if is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(self, "modulate", Color.WHITE, 0.12)
	
	var am = get_node_or_null("/root/AudioManager")
	if am and is_inside_tree() and am.has_method("play_break_sound"):
		am.play_break_sound()
	
	queue_redraw()
	
	if current_hits >= hits_required:
		break_wall(true)

func break_wall(emit_sig: bool = true) -> void:
	is_broken = true
	collision_layer = 0
	if hurtbox:
		hurtbox.queue_free()
	if col_shape:
		col_shape.set_deferred("disabled", true)
	if emit_sig:
		wall_broken.emit()
	queue_redraw()

func _draw() -> void:
	if is_broken:
		# Yere saçılmış taş kırıntıları
		for i in range(8):
			var rx = sin(i * 2.3) * 12.0
			var ry = cos(i * 1.7) * 8.0
			draw_circle(Vector2(rx, ry), 2.5, Color("334155"))
		return
	
	# Çatlaklı taş duvar
	draw_rect(Rect2(-16, -12, 32, 24), Color("1e293b"))
	draw_rect(Rect2(-14, -10, 28, 20), Color("334155"))
	
	# Çatlaklar (Darbe aldıkça belirginleşir)
	var crack_col = Color("64748b") if current_hits > 0 else Color("1e293b")
	draw_line(Vector2(-8, -6), Vector2(0, 2), crack_col, 1.5)
	if current_hits >= 2:
		draw_line(Vector2(0, 2), Vector2(10, -4), Color("94a3b8"), 2.0)
		draw_line(Vector2(0, 2), Vector2(4, 8), Color("94a3b8"), 1.8)

func get_save_data() -> Dictionary:
	return {
		"id": wall_id,
		"is_broken": is_broken,
		"current_hits": current_hits
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("is_broken") and data["is_broken"]:
		break_wall(false)
	elif data.has("current_hits"):
		current_hits = data["current_hits"]
