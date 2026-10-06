@tool
extends BaseInteractable
class_name ScenePortal

# Project T - Yeniden Kullanılabilir Kapı / Mekân Geçiş Altyapısı (ScenePortal)
# E tuşu ile etkileşime girildiğinde hedef sahneye veya hedef konuma geçiş sağlar
# Kararma (Fade to black) animasyonu, hedef konum aktarımı ve veri sürekliliği

signal transition_started(target_scene_path: String, target_portal_id: String)

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_portal_id: String = ""
@export var portal_tag: String = "entrance" # Bu portalın kendi kimliği (örn: "inn_front_door")
@export var arrival_offset: Vector2 = Vector2(0, 16) # Oyuncu bu portaldan çıktığında önünde belireceği ofset
@export var is_locked: bool = false
@export var required_key_id: String = ""
@export var locked_message: String = "Kapı kilitli. Açmak için uygun bir anahtar gerekiyor."

func _init() -> void:
	super._init()
	prompt_action_text = "Gir"
	interactable_name = "Kapı"

func _ready() -> void:
	if interactable_id == "":
		interactable_id = "portal_" + (portal_tag if portal_tag != "" else str(get_instance_id()))
	add_to_group("scene_portal")
	super._ready()

func get_action_prompt_text() -> String:
	return "Aç" if is_locked else prompt_action_text

func _on_interacted(player: CharacterBody2D) -> void:
	if is_locked:
		# Oyuncunun envanterinde anahtar var mı kontrol et
		if player != null and player.has_method("get_inventory") and required_key_id != "":
			var inv: Inventory = player.get_inventory()
			if inv != null and inv.has_item(required_key_id, 1):
				is_locked = false
				prompt_action_text = "Gir"
				var dm = get_node_or_null("/root/DialogueManager")
				if dm and is_inside_tree():
					dm.start_dialogue("Kilit Açıldı", "Anahtarı kilitte çevirdin. Ağır demir sürgü tık sesiyle açıldı!")
				return
		
		# Kilitli uyarısı
		var dm = get_node_or_null("/root/DialogueManager")
		if dm and is_inside_tree():
			dm.start_dialogue("Kilitli", locked_message)
		return

	if target_scene_path == "" and target_portal_id == "":
		return

	# Ses
	var am = get_node_or_null("/root/AudioManager")
	if am and is_inside_tree() and am.has_method("play_interact_sound"):
		am.play_interact_sound("chest")

	# Geçişi başlat
	_trigger_transition(player)

func _trigger_transition(player: CharacterBody2D) -> void:
	transition_started.emit(target_scene_path, target_portal_id)

	# Sahne yöneticisi varsa onu kullan, yoksa doğrudan sahne değiştir / ışınla
	var root_node = get_tree().root
	var transition_mgr = root_node.get_node_or_null("TransitionManager")
	if transition_mgr and transition_mgr.has_method("change_scene"):
		transition_mgr.change_scene(target_scene_path, target_portal_id)
	else:
		# Kendi kendine geçiş (aynı sahne içinde veya doğrudan sahne değişimi)
		if target_scene_path != "":
			var st = get_node_or_null("/root/SceneTransition")
			if st and st.has_method("change_scene"):
				st.change_scene(target_scene_path, target_portal_id)
			else:
				get_tree().change_scene_to_file(target_scene_path)
		elif target_portal_id != "" and player != null:
			# Aynı sahne içinde başka bir portala ışınlanma
			var portals = get_tree().get_nodes_in_group("scene_portal")
			for p in portals:
				if p != self and p.portal_tag == target_portal_id:
					player.global_position = p.global_position + p.arrival_offset
					break

func get_arrival_position() -> Vector2:
	return global_position + arrival_offset
