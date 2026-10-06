@tool
extends Node
class_name Inventory

# Project T - Modüler Envanter Yöneticisi
# 24 Slotlu Envanter Veri Modeli
# İstifleme, ekleme, çıkarma, taşıma ve slot takasları.

signal inventory_changed
signal item_added(item_id: String, amount: int)
signal inventory_full(item_id: String, remaining_amount: int)

const SLOT_COUNT: int = 24

# Her slot: {"item_id": String, "amount": int} veya boş ise {"item_id": "", "amount": 0}
var slots: Array[Dictionary] = []

func _init() -> void:
	clear()

func clear() -> void:
	slots.clear()
	for i in range(SLOT_COUNT):
		slots.append({"item_id": "", "amount": 0})

func is_slot_empty(index: int) -> bool:
	if index < 0 or index >= SLOT_COUNT:
		return true
	return slots[index]["item_id"] == "" or slots[index]["amount"] <= 0

func set_slot(index: int, item_id: String, amount: int) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	slots[index] = {
		"item_id": item_id,
		"amount": amount
	}
	inventory_changed.emit()

func is_full() -> bool:
	for i in range(SLOT_COUNT):
		if is_slot_empty(i):
			return false
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_count(item_id) >= amount

func get_item_count(item_id: String) -> int:
	var total = 0
	for i in range(SLOT_COUNT):
		if slots[i]["item_id"] == item_id:
			total += slots[i]["amount"]
	return total

func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= SLOT_COUNT:
		return {"item_id": "", "amount": 0}
	return slots[index]

# Envantere belirli miktar eşya eklemeyi dener.
# Eklenemeyen (artan) miktarı döner. Eğer tamamı eklendiyse 0 döner.
func add_item(item_id: String, amount: int) -> int:
	if item_id == "" or amount <= 0:
		return 0

	var item_data = ItemDatabase.get_item(item_id)
	if not item_data:
		push_warning("Bilinmeyen eşya ID: " + item_id)
		return amount

	var remaining = amount

	# 1. Aşama: Mevcut istiflenebilir slotlara doldur
	if item_data.max_stack > 1:
		for i in range(SLOT_COUNT):
			if slots[i]["item_id"] == item_id and slots[i]["amount"] < item_data.max_stack:
				var space = item_data.max_stack - slots[i]["amount"]
				var to_add = min(remaining, space)
				slots[i]["amount"] += to_add
				remaining -= to_add
				if remaining <= 0:
					break

	# 2. Aşama: Kalan miktarı boş slotlara doldur
	if remaining > 0:
		for i in range(SLOT_COUNT):
			if is_slot_empty(i):
				var to_add = min(remaining, item_data.max_stack)
				slots[i] = {
					"item_id": item_id,
					"amount": to_add
				}
				remaining -= to_add
				if remaining <= 0:
					break

	var added = amount - remaining
	if added > 0:
		item_added.emit(item_id, added)
		inventory_changed.emit()

	if remaining > 0:
		inventory_full.emit(item_id, remaining)

	return remaining

# Belirli bir eşyayı envantere sığıp sığmayacağını test eder (Simülasyon)
func can_add_item(item_id: String, amount: int) -> bool:
	if item_id == "" or amount <= 0:
		return true

	var item_data = ItemDatabase.get_item(item_id)
	if not item_data:
		return false

	var needed = amount
	if item_data.max_stack > 1:
		for i in range(SLOT_COUNT):
			if slots[i]["item_id"] == item_id and slots[i]["amount"] < item_data.max_stack:
				needed -= (item_data.max_stack - slots[i]["amount"])
				if needed <= 0:
					return true

	for i in range(SLOT_COUNT):
		if is_slot_empty(i):
			needed -= item_data.max_stack
			if needed <= 0:
				return true

	return false

# Birden fazla eşyanın (ör. sandık ödülleri) envantere aynı anda sığıp sığmayacağını simüle eder
func can_add_items(item_ids: Array[String], amounts: Array[int]) -> bool:
	var sim_slots = slots.duplicate(true)
	for i in range(item_ids.size()):
		var item_id = item_ids[i]
		var amount = amounts[i] if i < amounts.size() else 1
		if item_id == "" or amount <= 0:
			continue
		var item_data = ItemDatabase.get_item(item_id)
		if not item_data:
			return false

		var remaining = amount
		if item_data.max_stack > 1:
			for s in range(SLOT_COUNT):
				if sim_slots[s]["item_id"] == item_id and sim_slots[s]["amount"] < item_data.max_stack:
					var space = item_data.max_stack - sim_slots[s]["amount"]
					var to_add = min(remaining, space)
					sim_slots[s]["amount"] += to_add
					remaining -= to_add
					if remaining <= 0:
						break

		if remaining > 0:
			for s in range(SLOT_COUNT):
				if sim_slots[s]["item_id"] == "" or sim_slots[s]["amount"] <= 0:
					var to_add = min(remaining, item_data.max_stack)
					sim_slots[s] = {"item_id": item_id, "amount": to_add}
					remaining -= to_add
					if remaining <= 0:
						break

		if remaining > 0:
			return false

	return true

# Belirtilen slottan miktar eksiltir veya tamamen kaldırır
func remove_from_slot(index: int, amount: int = 1) -> bool:
	if index < 0 or index >= SLOT_COUNT or is_slot_empty(index):
		return false

	if slots[index]["amount"] <= amount:
		slots[index] = {"item_id": "", "amount": 0}
	else:
		slots[index]["amount"] -= amount

	inventory_changed.emit()
	return true

# Belirli bir eşyadan belirtilen miktarda siler
func remove_item(item_id: String, amount: int = 1) -> bool:
	if not has_item(item_id, amount):
		return false
	var remaining = amount
	for i in range(SLOT_COUNT):
		if slots[i]["item_id"] == item_id:
			if slots[i]["amount"] <= remaining:
				remaining -= slots[i]["amount"]
				slots[i] = {"item_id": "", "amount": 0}
			else:
				slots[i]["amount"] -= remaining
				remaining = 0
			if remaining <= 0:
				break
	inventory_changed.emit()
	return true

# İki slot arasında taşıma veya birleştirme (swap / merge)
func move_or_merge_slot(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= SLOT_COUNT or to_index < 0 or to_index >= SLOT_COUNT:
		return false
	if from_index == to_index or is_slot_empty(from_index):
		return false

	var from_slot = slots[from_index].duplicate()
	var to_slot = slots[to_index].duplicate()

	# Hedef boşsa: Doğrudan taşı
	if is_slot_empty(to_index):
		slots[to_index] = from_slot
		slots[from_index] = {"item_id": "", "amount": 0}
		inventory_changed.emit()
		return true

	# Aynı eşya ise: İstifle
	if from_slot["item_id"] == to_slot["item_id"]:
		var item_data = ItemDatabase.get_item(from_slot["item_id"])
		if item_data and item_data.max_stack > 1:
			var space = item_data.max_stack - to_slot["amount"]
			if space > 0:
				var to_move = min(from_slot["amount"], space)
				to_slot["amount"] += to_move
				from_slot["amount"] -= to_move
				slots[to_index] = to_slot
				if from_slot["amount"] <= 0:
					slots[from_index] = {"item_id": "", "amount": 0}
				else:
					slots[from_index] = from_slot
				inventory_changed.emit()
				return true

	# Farklı eşya ise: Takas yap (Swap)
	slots[to_index] = from_slot
	slots[from_index] = to_slot
	inventory_changed.emit()
	return true

# Kayıt / Yükleme Veri Yapısı
func get_save_data() -> Array:
	return slots.duplicate(true)

func load_save_data(data: Array) -> void:
	clear()
	for i in range(min(data.size(), SLOT_COUNT)):
		if data[i] is Dictionary and data[i].has("item_id") and data[i].has("amount"):
			slots[i] = {
				"item_id": data[i]["item_id"],
				"amount": int(data[i]["amount"])
			}
	inventory_changed.emit()
