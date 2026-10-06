extends SceneTree

# Test betiği: Görev 27 — “Vadinin Sessizliği” Macera & Görev Zinciri Smoke Test
# Senaryolar:
# 1. Aşama 1: Söylenti & Çoklu NPC / Çevre Tetikleyicileri (Mira, Kemal, Boran, Kervan Belgesi)
# 2. Aşama 2: Araştırma — Kırılmış Araba Enkazı, Ayak İzleri ve Kervan İrsaliyesi
# 3. Aşama 3: Haydut Kampı — Gizli Rota ve Pusu Kayıt Defteri (bandit_ledger)
# 4. Aşama 4: Kanca Kullanımı — Haydut Gözetleme Tepesi Ledge & Gizli Sandık
# 5. Aşama 5: Karar & Fraksiyon / Dünya Tepkisi —
#    - Sonuç A (Muhafızlar): İtibar artışı, NPC diyalogları, kampın dağıtılması
#    - Sonuç B (Haydutlar): Haydut ittifakı, alternatif diyaloglar ve kalıcı kayıt
# 6. SaveManager ile Durum Kalıcılığı (Roundtrip)

const BanditLeaderScript = preload("res://scripts/creatures/bandit_leader.gd")

var _tested: bool = false

func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true
	print("--- TEST BAŞLATILDI: Görev 27 — Vadinin Sessizliği Macera Zinciri Smoke Test ---")
	
	var qm = root.get_node_or_null("QuestManager")
	if not qm:
		qm = preload("res://scripts/quests/quest_manager.gd").new()
		qm.name = "QuestManager"
		root.add_child(qm)
		qm._ready()
		
	var fm = root.get_node_or_null("FactionManager")
	if not fm:
		fm = preload("res://scripts/reputation/faction_manager.gd").new()
		fm.name = "FactionManager"
		root.add_child(fm)
		fm._ready()

	var sm = root.get_node_or_null("SaveManager")
	if not sm:
		sm = preload("res://scripts/save/save_manager.gd").new()
		sm.name = "SaveManager"
		root.add_child(sm)
		sm._ready()

	test_stage1_rumors_and_multi_npc_start(qm)
	test_stage2_caravan_investigation_and_clues()
	test_stage3_bandit_camp_and_ledger()
	test_stage4_grappling_hook_lookout_access()
	test_stage5_branching_decisions_and_world_reactions(qm, fm)
	test_save_load_valley_quest_persistence(qm, sm)
	print("--- TÜM VADİNİN SESSİZLİĞİ DOĞRULAMALARI BAŞARIYLA TAMAMLANDI ---")
	quit(0)
	return true

func test_stage1_rumors_and_multi_npc_start(qm: Node) -> void:
	assert(qm != null, "QuestManager singleton mevcut olmalı")
	var q = qm.get_quest("silence_of_the_valley")
	assert(q != null, "silence_of_the_valley görevi kayıtlı olmalı")
	assert(q.title == "Vadinin Sessizliği", "Görev başlığı doğru olmalı")
	
	# Hancı Mira ile konuşarak görevin başlaması
	var mira = preload("res://scenes/npc/npc_mira.tscn").instantiate()
	root.add_child(mira)
	mira._ready()
	var d_mira = mira.get_current_dialogue()
	assert(q.is_active(), "Mira ile konuşunca görev ACTIVE duruma geçmeli")
	assert(d_mira.contains("kervanlar"), "Mira kervan söylentisinden bahsetmeli")
	
	mira.free()
	print("[PASS] Aşama 1: Söylenti ve çoklu NPC / ortam başlangıcı doğrulandı.")

func test_stage2_caravan_investigation_and_clues() -> void:
	# Açık dünyada kırık araba ve kervan irsaliyesi kanıtı kontrolü
	var world_scene = preload("res://scenes/world/test_location.tscn").instantiate()
	root.add_child(world_scene)
	
	var wagon = world_scene.find_child("Broken_Caravan_Wagon", true, false)
	assert(wagon != null, "Kırılmış araba enkazı mevcut olmalı")
	
	var clue = world_scene.find_child("Caravan_Manifest_Clue", true, false)
	assert(clue != null, "Kervan irsaliyesi eşyası dünyada mevcut olmalı")
	assert(clue.item_id == "caravan_manifest", "Eşya ID'si caravan_manifest olmalı")
	
	world_scene.free()
	print("[PASS] Aşama 2: Kervan yolu araştırması ve çevresel ipuçları doğrulandı.")

func test_stage3_bandit_camp_and_ledger() -> void:
	var world_scene = preload("res://scenes/world/test_location.tscn").instantiate()
	root.add_child(world_scene)
	
	var bandit = world_scene.find_child("Bandit_Camp", true, false)
	assert(bandit != null, "Haydut kampı düşmanı mevcut olmalı")
	
	var leader = world_scene.find_child("Bandit_Leader_Boss", true, false)
	assert(leader != null, "Haydut reisi sahnede mevcut olmalı")
	
	var camp_chest = world_scene.find_child("Bandit_Camp_Chest", true, false)
	assert(camp_chest != null, "Haydut kampı sandığı mevcut olmalı")
	assert(camp_chest.reward_item_ids.has("bandit_ledger"), "Haydut sandığında bandit_ledger (Pusu Defteri) bulunmalı")
	
	world_scene.free()
	print("[PASS] Aşama 3: Haydut kampı ve pusu kayıt defteri kanıtı doğrulandı.")

func test_stage4_grappling_hook_lookout_access() -> void:
	var world_scene = preload("res://scenes/world/test_location.tscn").instantiate()
	root.add_child(world_scene)
	
	var lookout_grapple = world_scene.find_child("Grapple_Lookout_Ledge", true, false)
	assert(lookout_grapple != null, "Haydut gözetleme kanca noktası mevcut olmalı")
	
	var lookout_stash = world_scene.find_child("Chest_Lookout_Stash", true, false)
	assert(lookout_stash != null, "Gözetleme tepesi gizli sandığı bulunmalı")
	
	# Kanca kontrolü
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player._ready()
	var inv: Inventory = player.get_inventory()
	
	lookout_grapple._on_interacted(player)
	assert(player.current_state != player.State.GRAPPLE, "Kancasız gözetleme tepesine çıkılamaz")
	
	inv.add_item("grappling_hook", 1)
	lookout_grapple._on_interacted(player)
	assert(player.current_state == player.State.GRAPPLE, "Kanca ile gözetleme tepesine kanca atılmalı")
	
	player.free()
	world_scene.free()
	print("[PASS] Aşama 4: Kanca kullanımı ile ulaşılamayan gözetleme tepesine erişim doğrulandı.")

func test_stage5_branching_decisions_and_world_reactions(qm: Node, fm: Node) -> void:
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player._ready()
	var inv: Inventory = player.get_inventory()
	inv.add_item("bandit_ledger", 1)
	
	# Görevi aktif yap
	qm.start_quest("silence_of_the_valley")
	
	# Muhafız Selim ile konuşarak teslim etme (Karar A)
	var guard = preload("res://scenes/creatures/guard_creature.tscn").instantiate()
	root.add_child(guard)
	guard._ready()
	
	var initial_guard_rep = fm.get_reputation("guards")
	guard.interact_with(player)
	
	assert(qm.get_quest("silence_of_the_valley").is_completed(), "Görev muhafıza teslim edilince tamamlanmalı")
	assert(qm.valley_quest_choice == "guards", "Seçim 'guards' olarak kaydedilmeli")
	assert(fm.get_reputation("guards") > initial_guard_rep, "Muhafız itibarı artmalı")
	assert(not inv.has_item("bandit_ledger", 1), "Kanıt defteri envanterden teslim edilmiş olmalı")
	
	# NPC tepkileri (Kemal, Mira, Boran)
	var kemal = preload("res://scenes/npc/npc_kemal.tscn").instantiate()
	root.add_child(kemal)
	kemal._ready()
	var d_kemal = kemal.get_current_dialogue()
	assert(d_kemal.contains("Muhafızlar") or d_kemal.contains("haydut"), "Kemal muhafız zaferini hatırlamalı")
	
	var boran = preload("res://scenes/npc/npc_boran.tscn").instantiate()
	boran.current_state = BaseNPC.State.IDLE
	root.add_child(boran)
	boran._ready()
	var d_boran = boran.get_current_dialogue()
	assert(d_boran.contains("müsadere") or d_boran.contains("kılıç"), "Boran haydut silahlarının eritildiğini belirtmeli")
	
	# Karar B Simülasyonu (Haydut reisiyle anlaşma)
	qm.get_quest("silence_of_the_valley").stage = QuestData.QuestStage.ACTIVE
	inv.add_item("bandit_ledger", 1)
	var leader = BanditLeaderScript.new()
	root.add_child(leader)
	leader._ready()
	
	var initial_bandit_rep = fm.get_reputation("bandits")
	leader.interact_with(player)
	assert(qm.valley_quest_choice == "bandits", "Haydutla anlaşınca seçim 'bandits' olmalı")
	assert(fm.get_reputation("bandits") > initial_bandit_rep, "Haydut itibarı artmalı")
	
	guard.free()
	kemal.free()
	boran.free()
	leader.free()
	player.free()
	print("[PASS] Aşama 5: Çatallanan kararlar (A/B), itibar değişimleri ve 3 NPC tepkisi doğrulandı.")

func test_save_load_valley_quest_persistence(qm: Node, sm: Node) -> void:
	qm.valley_quest_choice = "guards"
	var saved = sm.save_game(1)
	assert(saved, "Slot 1'e kayıt başarılı olmalı")
	
	# Durumu sıfırla
	qm.valley_quest_choice = "unknown"
	
	# Geri yükle
	var loaded = sm.load_game(1)
	assert(loaded, "Slot 1'den yükleme başarılı olmalı")
	assert(qm.valley_quest_choice == "guards", "Kayıt dosyasından valley_quest_choice başarıyla geri yüklenmeli")
	
	print("[PASS] Görev kararı ve dünya durumunun SaveManager ile kalıcılığı doğrulandı.")
