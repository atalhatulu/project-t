@tool
extends Node
class_name ItemDatabase

# Project T - Eşya Veritabanı ve Fabrikası
# Tanımlı tüm temel eşyaların kayıtları

static var _items: Dictionary = {}

static func get_item(item_id: String) -> ItemData:
	if _items.is_empty():
		_register_default_items()
	return _items.get(item_id, null)

static func _register_default_items() -> void:
	# 1. Malzemeler
	_add_item("wood", "Odun", "Sağlam meşe dalı ve kereste parçası. Yapı ve alet üretiminde temel malzeme.", ItemData.ItemCategory.MATERIAL, 99, 4, Color("8a5a36"), Color("5c3a1c"), "rect")
	_add_item("iron_ore", "Demir Cevheri", "Kayalıklardan ve maden damarlarından çıkarılan işlenmemiş ham demir cevheri.", ItemData.ItemCategory.MATERIAL, 99, 8, Color("717b8a"), Color("383e47"), "gem")
	_add_item("red_herb", "Kızıl Vadi Otu", "Vadide yetişen, yara sarıcı ve canlandırıcı şifalı yabani bitki.", ItemData.ItemCategory.MATERIAL, 99, 6, Color("e74c3c"), Color("2e5a27"), "potion")
	_add_item("shadow_moss", "Gölge Yosunu", "Gizli açıklıkların nemli taşlarında üreyen karanlık ve şifalı yosun.", ItemData.ItemCategory.MATERIAL, 99, 7, Color("2d5a27"), Color("1b3617"), "circle")
	_add_item("water_mint", "Su Nanesi", "Nehir kıyılarında açan tazeleyici, keskin kokulu su bitkisi.", ItemData.ItemCategory.MATERIAL, 99, 5, Color("4ca1a3"), Color("2b7a78"), "potion")

	# 2. Yiyecekler
	_add_item("wild_apple", "Yaban Elması", "Ağaçların gölgesinden toplanmış sulu ve hafif ekşi elma.", ItemData.ItemCategory.FOOD, 30, 3, Color("c0392b"), Color("27ae60"), "circle")
	_add_item("inn_bread", "Hancı Ekmeği", "Kızıl Han'ın taş fırınında Mira tarafından pişirilmiş sıcak somun.", ItemData.ItemCategory.FOOD, 20, 6, Color("d35400"), Color("f39c12"), "rect")
	_add_item("meat_stew", "Sıcak Yahni", "Kızıl Han'ın doyurucu, etli sebze yahnisi.", ItemData.ItemCategory.FOOD, 10, 15, Color("b91c1c"), Color("f59e0b"), "circle")

	# 3. Silahlar ve Aletler
	_add_item("rusted_sword", "Paslı Kılıç", "Eski savaşlardan kalma, kenarları çentikli ama güvenilir çelik kılıç.", ItemData.ItemCategory.WEAPON, 1, 25, Color("95a5a6"), Color("34495e"), "cross")
	_add_item("wooden_club", "Ahşap Sopa", "Acil durumlarda savunma için kullanılabilecek ağır sopa.", ItemData.ItemCategory.WEAPON, 1, 10, Color("795548"), Color("4e342e"), "rect")
	_add_item("crafted_axe", "Demirci Baltası", "Odun ve demir cevherinden dövülmüş sağlam iş baltası.", ItemData.ItemCategory.WEAPON, 1, 35, Color("94a3b8"), Color("78350f"), "cross")

	# 4. Görev ve Zindan Eşyaları
	_add_item("ancient_medallion", "Kadim Madalyon", "Üzerinde unutulmuş bir hanedanın mührü kazınmış gizemli madalyon.", ItemData.ItemCategory.QUEST, 1, 50, Color("f1c40f"), Color("e67e22"), "gem")
	_add_item("kemal_sickle", "Kemal'in Yadigâr Orağı", "Çiftçi Kemal'in dedesinden kalma, otların arasında kaybolmuş çelik orak.", ItemData.ItemCategory.QUEST, 1, 30, Color("95a5a6"), Color("d35400"), "cross")
	_add_item("caravan_goods", "Tüccar Sandığı", "Kervan kafilesine ait mühürlü ticaret sandığı.", ItemData.ItemCategory.QUEST, 1, 60, Color("f39c12"), Color("78561d"), "rect")
	_add_item("lost_hammer", "Kemal'in Kayıp Aleti", "Çiftçi Kemal'in tarlada kaybettiğini söylediği paslı alet.", ItemData.ItemCategory.QUEST, 1, 20, Color("7f8c8d"), Color("d35400"), "cross")
	_add_item("dungeon_key", "Paslı Zindan Anahtarı", "Mağaranın derinliklerindeki demir parmaklıkları açan ağır demir anahtar.", ItemData.ItemCategory.QUEST, 1, 40, Color("e5a93b"), Color("5c3a1c"), "cross")
	_add_item("grappling_hook", "Gezgin Kancası", "Uçurumlardan ve derin çukurlardan karşıya geçmeyi sağlayan sağlam kanca.", ItemData.ItemCategory.QUEST, 1, 150, Color("38bdf8"), Color("0f172a"), "cross")
	_add_item("caravan_manifest", "Kayıp Kervan İrsaliyesi", "Kervan yolunda araba enkazının yanında bulunmuş yırtık tüccar belgesi.", ItemData.ItemCategory.QUEST, 1, 15, Color("e2e8f0"), Color("94a3b8"), "rect")
	_add_item("bandit_ledger", "Haydut Pusu Kayıtları", "Haydutların kervan baskınlarını ve vadideki gizli gözlem noktalarını belgeleyen gizli defter.", ItemData.ItemCategory.QUEST, 1, 35, Color("7f1d1d"), Color("f59e0b"), "rect")
	_add_item("mountain_flower", "Dağ Kardeleni", "Sarp dağ kayalıklarında açan dirençli ve şifalı beyaz dağ çiçeği.", ItemData.ItemCategory.MATERIAL, 99, 9, Color("f8fafc"), Color("38bdf8"), "potion")
	_add_item("cooper_coins", "Bakır Sikkeler", "Kızıl Vadi'de geçerli olan eski ticaret paraları.", ItemData.ItemCategory.MATERIAL, 999, 1, Color("d35400"), Color("e67e22"), "circle")

static func _add_item(id: String, name: String, desc: String, cat: ItemData.ItemCategory, max_stk: int, price: int, col1: Color, col2: Color, shape: String) -> void:
	var item = ItemData.new()
	item.id = id
	item.name = name
	item.description = desc
	item.category = cat
	item.max_stack = max_stk
	item.base_price = price
	item.icon_color = col1
	item.secondary_color = col2
	item.icon_shape = shape
	_items[id] = item
