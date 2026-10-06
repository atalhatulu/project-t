@tool
extends Node

# Project T - Dinamik Ekonomi ve Ticaret Yöneticisi (EconomyManager)
# Autoload Singleton: EconomyManager
# Tüccar stokları, yenilenme döngüsü, bölgesel fiyat çarpanları ve zanaat tarifleri

signal transaction_completed(merchant_id: String, item_id: String, amount: int, total_price: int, is_buy: bool)
signal item_crafted(recipe_id: String, result_item_id: String)

# Tüccar Stok Modelleri:
# merchant_id -> { "name": String, "stock": Array[Dictionary], "last_restock_day": int }
# stock item: { "item_id": String, "current_stock": int, "max_stock": int, "price_multiplier": float }
var merchants: Dictionary = {}

# Bölgesel Kıtlık Çarpanları (Kategori bazında veya eşya bazında)
# Örneğin Bozkır bölgesinde demir cevheri boldur (0.9x), şifalı ot ve taze meyve kıttır (1.4x)
var regional_price_modifiers: Dictionary = {
	"red_herb": 1.4,
	"meat_stew": 1.2,
	"iron_ore": 0.9,
	"crafted_axe": 1.1
}

# Basit Üretim Tarifleri (Crafting Recipes)
# recipe_id -> { "name": String, "result_item": String, "result_amount": int, "ingredients": Array[Dictionary] }
var crafting_recipes: Dictionary = {}

func _ready() -> void:
	_init_merchants()
	_init_recipes()
	var tm = get_node_or_null("/root/TimeManager") if is_inside_tree() else null
	if tm:
		if not tm.day_changed.is_connected(_on_day_changed):
			tm.day_changed.connect(_on_day_changed)

func _init_merchants() -> void:
	# 1. Hancı Mira (Yiyecek ve İçecekler)
	var mira_stock: Array[Dictionary] = [
		{"item_id": "inn_bread", "current_stock": 8, "max_stock": 8, "price_mult": 1.0},
		{"item_id": "meat_stew", "current_stock": 5, "max_stock": 5, "price_mult": 1.0},
		{"item_id": "wild_apple", "current_stock": 12, "max_stock": 12, "price_mult": 0.9}
	]
	merchants["mira"] = {
		"name": "Hancı Mira",
		"title": "Kızıl Han Erzak Tezgâhı",
		"stock": mira_stock,
		"last_restock_day": 1
	}

	# 2. Demirci Boran (Malzemeler, Silahlar ve Aletler)
	var boran_stock: Array[Dictionary] = [
		{"item_id": "iron_ore", "current_stock": 15, "max_stock": 15, "price_mult": 1.0},
		{"item_id": "wood", "current_stock": 20, "max_stock": 20, "price_mult": 1.0},
		{"item_id": "rusted_sword", "current_stock": 2, "max_stock": 2, "price_mult": 1.0},
		{"item_id": "crafted_axe", "current_stock": 3, "max_stock": 3, "price_mult": 1.1}
	]
	merchants["boran"] = {
		"name": "Demirci Boran",
		"title": "Boran'ın Demir Ocağı",
		"stock": boran_stock,
		"last_restock_day": 1
	}

func _init_recipes() -> void:
	# Tarif 1: Demirci Baltası = 2 Odun + 2 Demir Cevheri
	crafting_recipes["craft_axe"] = {
		"recipe_id": "craft_axe",
		"name": "Demirci Baltası Üret",
		"result_item": "crafted_axe",
		"result_amount": 1,
		"description": "2 Odun ve 2 Demir Cevheri kullanarak sağlam bir iş baltası yap.",
		"ingredients": [
			{"item_id": "wood", "amount": 2},
			{"item_id": "iron_ore", "amount": 2}
		]
	}

	# Tarif 2: Ahşap Sopa = 3 Odun
	crafting_recipes["craft_club"] = {
		"recipe_id": "craft_club",
		"name": "Ahşap Sopa Yont",
		"result_item": "wooden_club",
		"result_amount": 1,
		"description": "3 Odun parçasını yontarak acil durum sopası hazırla.",
		"ingredients": [
			{"item_id": "wood", "amount": 3}
		]
	}

func _on_day_changed(new_day: int) -> void:
	# Günlük sınırlı stok yenilenmesi (Restock)
	for m_id in merchants:
		var m = merchants[m_id]
		m["last_restock_day"] = new_day
		for s in m["stock"]:
			s["current_stock"] = s["max_stock"]

# Fiyat Hesaplama (Kıtlık çarpanı ve tüccar marjı dahil)
func get_item_price(item_id: String, merchant_mult: float = 1.0, is_buying: bool = true) -> int:
	var item = ItemDatabase.get_item(item_id)
	if not item: return 1
	
	var regional_mult = regional_price_modifiers.get(item_id, 1.0)
	var calculated: float = float(item.base_price) * regional_mult * merchant_mult
	
	if not is_buying:
		# Oyuncu satarken %60 değerine alır (tüccar kâr payı)
		calculated *= 0.6
	
	return maxi(1, int(round(calculated)))

# Oyuncunun mevcut parasını döner (cooper_coins miktarı)
func get_player_gold(player_inventory: Inventory) -> int:
	if not player_inventory: return 0
	var total = 0
	for s in player_inventory.slots:
		if s["item_id"] == "cooper_coins":
			total += s["amount"]
	return total

# Atomik Satın Alma (Oyuncu Tüccardan Alır)
func buy_from_merchant(merchant_id: String, item_id: String, amount: int, player_inventory: Inventory) -> bool:
	if not merchants.has(merchant_id) or not player_inventory or amount <= 0:
		return false
	
	var m = merchants[merchant_id]
	var stock_entry = null
	for s in m["stock"]:
		if s["item_id"] == item_id:
			stock_entry = s
			break
	
	if not stock_entry or stock_entry["current_stock"] < amount:
		return false # Yetersiz stok
	
	var unit_price = get_item_price(item_id, stock_entry.get("price_mult", 1.0), true)
	var total_cost = unit_price * amount
	var current_gold = get_player_gold(player_inventory)
	
	if current_gold < total_cost:
		return false # Yetersiz para
	
	if not player_inventory.can_add_item(item_id, amount):
		return false # Envanter dolu
	
	# Atomik işlem: Para eksilt, eşyayı ver, tüccar stoğunu düşür
	player_inventory.remove_item("cooper_coins", total_cost)
	player_inventory.add_item(item_id, amount)
	stock_entry["current_stock"] -= amount
	
	transaction_completed.emit(merchant_id, item_id, amount, total_cost, true)
	return true

# Atomik Satış (Oyuncu Tüccara Satar)
func sell_to_merchant(merchant_id: String, item_id: String, amount: int, player_inventory: Inventory) -> bool:
	if item_id == "cooper_coins" or not merchants.has(merchant_id) or not player_inventory or amount <= 0:
		return false
	
	if not player_inventory.has_item(item_id, amount):
		return false # Oyuncuda o kadar eşya yok
	
	var unit_price = get_item_price(item_id, 1.0, false)
	var total_payout = unit_price * amount
	
	if not player_inventory.can_add_item("cooper_coins", total_payout):
		return false
	
	# Atomik işlem: Eşyayı al, parayı ver
	player_inventory.remove_item(item_id, amount)
	player_inventory.add_item("cooper_coins", total_payout)
	
	transaction_completed.emit(merchant_id, item_id, amount, total_payout, false)
	return true

# Atomik Üretim (Crafting)
func can_craft_recipe(recipe_id: String, player_inventory: Inventory) -> bool:
	if not crafting_recipes.has(recipe_id) or not player_inventory:
		return false
	
	var rec = crafting_recipes[recipe_id]
	for ing in rec["ingredients"]:
		if not player_inventory.has_item(ing["item_id"], ing["amount"]):
			return false
	
	if not player_inventory.can_add_item(rec["result_item"], rec["result_amount"]):
		return false
	
	return true

func craft_recipe(recipe_id: String, player_inventory: Inventory) -> bool:
	if not can_craft_recipe(recipe_id, player_inventory):
		return false
	
	var rec = crafting_recipes[recipe_id]
	# Atomik: Malzemeleri tüket
	for ing in rec["ingredients"]:
		player_inventory.remove_item(ing["item_id"], ing["amount"])
	
	# Sonuç eşyasını ekle
	player_inventory.add_item(rec["result_item"], rec["result_amount"])
	item_crafted.emit(recipe_id, rec["result_item"])
	return true
