# Project-T

**Project-T**, klasik Zelda benzeri (top-down action RPG) mekanikleri modern sistemlerle harmanlayan, zengin bir 2D piksel aksiyon-macera oyunudur. Keşif, dinamik dövüş, zindanlar, ekonomi, simya, balıkçılık ve fraksiyon itibar sistemleri gibi katmanlı RPG mekaniklerine sahiptir.

---

## Temel Sistemler ve Özellikler

- **Gelişmiş Dövüş Sistemi:**
  - Kılıç saldırıları, yuvarlanma (roll/dash), kalkanla bloklama ve zamanlamaya dayalı savuşturma (parry).
  - Canlı hasar göstergeleri (`damage_number_manager`) ve statü efektleri (zehirlenme, hız iksirleri vb.).
  - Zindan patronları ve elit düşmanlar (Mağara Trolü, Haydut Lideri).
- **Yaşayan Dünya ve Çevre Etkileşimi:**
  - İtilebilir kayalar, ağırlık plakaları, kancalanabilir noktalar (grapple points).
  - Kırılabilir sandıklar, toplanabilir bitkiler, kazılabilir tümsekler ve maden kayaları.
  - Kamp ateşleri, kürekli kayıkla su yolculuğu ve bataklık atmosfer efektleri.
- **Zanaatkarlık, Simya ve Balıkçılık:**
  - Simya kazanı (`alchemy_cauldron`) ile iksir üretimi.
  - Zanaat tezgahı (`crafting_workbench`) ile ekipman ve eşya üretimi.
  - Su kenarlarında balık tutma mekaniği (`fishing_spot`).
- **Ekonomi ve İtibar (Fraksiyon) Sistemi:**
  - Köy esnafı ve tüccarlarla ticaret (`ShopUI`, `EconomyManager`).
  - Bölge fraksiyonları nezdinde itibar derecelendirmesi (`FactionManager`).
- **Keşif ve Harita:**
  - Sis perdesi ve bölge keşif tetikleyicileri (`DiscoveryManager`).
  - Açılabilir dünya haritası (`MapManager`, `map_ui`).
  - Dinamik gün/saat döngüsü (`TimeManager`).
- **Görev ve Günlük:**
  - Çok aşamalı görev takibi ve ödül sistemi (`QuestManager`, `journal_ui`).
- **Test Kapsamı:** Proje genelinde 30'dan fazla otomatik test döngüsü (`tests/test_*.gd`) ile test güdümlü mimari.

---

## Kontroller

| Girdi | Alternatif | Eylem |
| :--- | :--- | :--- |
| **W, A, S, D** | Yön Tuşları | Hareket |
| **Boşluk (Space)** | - | Yuvarlanma / Kaçınma (Roll) |
| **Sol Tık (LMB)** | **K** | Saldırı |
| **Sağ Tık (RMB)** | **L** | Bloklama / Kalkan |
| **E** | - | Etkileşim (Konuşma, Sandık Açma, Eşya Alma) |
| **I** | - | Envanter Aç / Kapat |
| **J** | - | Görev Günlüğü Aç / Kapat |
| **M** | - | Dünya Haritası Aç / Kapat |

---

## Mimari ve Proje Yapısı

```
project-t/
├── autoload/ ve scripts/core/ # Singleton yoneticiler
│   ├── time_manager.gd        # Zaman ve gun/gece dongusu
│   ├── audio_manager.gd       # Muzik ve dinamik ses yonetimi
│   ├── scene_transition.gd    # Sahne ve mekan gecisleri
│   └── region_manager.gd      # Bolgesel yukleme ve dunya yonetimi
├── scripts/
│   ├── creatures/             # Dusman, pasif ve patron yapay zekalari
│   ├── economy/               # Ticaret ve pazar mantigi
│   ├── effects/               # Partikul, su dalgasi ve hasar sayilari
│   ├── interactables/         # Dunyadaki tum etkilesimli objeler
│   ├── inventory/             # Envanter ve esya veritabani
│   ├── quests/                # Gorev motoru ve dunya olaylari
│   ├── reputation/            # Fraksiyon itibar yonetimi
│   └── save/                  # Kayit sistemi
├── scenes/
│   ├── world.tscn             # Ana dunya sahnesi
│   ├── player.tscn            # Oyuncu sahnesi
│   ├── interiors/             # Han, demirci, ev ve zindan ic mekanlari
│   ├── npc/                   # Diyalog kurulabilir karakterler
│   ├── props/                 # Cevre ve etkilesim bilesenleri
│   └── ui/                    # Envanter, harita, gunluk ve diyalog arayuzleri
└── tests/                     # 30+ kapsamli sistem ve entegrasyon testi
```

---

## Teknik Gereksinimler

- **Motor:** Godot Engine 4.7+
- **Isleyici (Renderer):** Forward+
- **Cozunurluk:** 640x360 (Pencere olcegi: 1280x720, Keskin piksel filtreleme)
- **Fizik:** 2D Physics (Snap transforms to pixel aktif)
