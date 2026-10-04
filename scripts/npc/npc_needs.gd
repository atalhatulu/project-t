extends Node
class_name NPCNeeds

# Project T - NPC İhtiyaç Sistemi (Needs System)
# Açlık, Enerji, Sosyal (0 - 100 arası değerler)
# Dünya zamanına (TimeManager) göre tükenir ve artar.

signal need_critical(need_name: String, value: float)

@export var hunger: float = 85.0   # 100 = Tam tok, 0 = Açlıktan ölüyor (< 25 kritik)
@export var energy: float = 90.0   # 100 = Zinde, 0 = Bitkin (< 20 kritik)
@export var social: float = 75.0   # 100 = Sosyal doyum, 0 = Yalnız (< 25 kritik)

# 1 oyun saatinde (3600 oyun saniyesi) doğal değişim oranları
@export var hunger_depletion_per_hour: float = 4.5
@export var energy_depletion_per_hour: float = 3.5
@export var social_depletion_per_hour: float = 4.0

# Eşik değerleri (Histerezis)
const CRITICAL_HUNGER_THRESHOLD: float = 25.0
const SATISFIED_HUNGER_THRESHOLD: float = 80.0

const CRITICAL_ENERGY_THRESHOLD: float = 20.0
const SATISFIED_ENERGY_THRESHOLD: float = 85.0

const CRITICAL_SOCIAL_THRESHOLD: float = 20.0
const SATISFIED_SOCIAL_THRESHOLD: float = 75.0

func update_needs(delta_game_hours: float, current_state: int) -> void:
	# Doğal tükenme
	hunger = clamp(hunger - hunger_depletion_per_hour * delta_game_hours, 0.0, 100.0)
	energy = clamp(energy - energy_depletion_per_hour * delta_game_hours, 0.0, 100.0)
	social = clamp(social - social_depletion_per_hour * delta_game_hours, 0.0, 100.0)

	# Eyleme göre yenilenme
	# State: IDLE=0, WALK=1, WORK=2, SOCIALIZE=3, SLEEP=4, EAT=5, REST=6
	match current_state:
		2: # WORK (Enerji daha hızlı düşer, açlık artar)
			energy = clamp(energy - 2.0 * delta_game_hours, 0.0, 100.0)
		3: # SOCIALIZE (Sosyal ihtiyaç hızla dolar)
			social = clamp(social + 25.0 * delta_game_hours, 0.0, 100.0)
		4: # SLEEP (Enerji hızla dolar)
			energy = clamp(energy + 30.0 * delta_game_hours, 0.0, 100.0)
		5: # EAT (Açlık hızla doyar)
			hunger = clamp(hunger + 40.0 * delta_game_hours, 0.0, 100.0)
		6: # REST (Enerji orta hızda dinlenir)
			energy = clamp(energy + 15.0 * delta_game_hours, 0.0, 100.0)

	if is_critically_hungry():
		need_critical.emit("hunger", hunger)
	elif is_critically_exhausted():
		need_critical.emit("energy", energy)
	elif is_critically_lonely():
		need_critical.emit("social", social)

func is_critically_hungry() -> bool:
	return hunger <= CRITICAL_HUNGER_THRESHOLD

func is_critically_exhausted() -> bool:
	return energy <= CRITICAL_ENERGY_THRESHOLD

func is_critically_lonely() -> bool:
	return social <= CRITICAL_SOCIAL_THRESHOLD
