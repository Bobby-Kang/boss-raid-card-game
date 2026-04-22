class_name MarketPanel
extends PanelContainer

# 4-레인 라운드 마켓
# 레인: 공격 / 방어 / 특수 / 골드
# 각 레인은 독립 서브풀에서 페이즈 가중치 추첨으로 1장 진열
# 리롤: 전체 레인 동시 재추첨 (AP 3 또는 골드 3)
# 구매: 해당 레인 슬롯 비움, 다음 refresh까지 유지

signal card_purchased(card_data: CardData)

const CardScene := preload("res://scenes/cards/card.tscn")
const LANE_COUNT    := 4
const REROLL_AP_COST   := 3
const REROLL_GOLD_COST := 3
const CARD_WIDTH  := 120
const CARD_HEIGHT := 170

# 레인별 카드 풀 (씬에서 익스포트)
@export var attack_pool:  Array[CardData] = []   # ⚔ 공격
@export var defense_pool: Array[CardData] = []   # 🛡 방어
@export var special_pool: Array[CardData] = []   # ✨ 특수 (드로우·모듈)
@export var gold_pool:    Array[CardData] = []   # 💰 골드·경제

# 레인 표시 메타
const LANE_META := [
	{"label": "⚔ 공격",  "color": Color(1.0,  0.5,  0.5,  1)},
	{"label": "🛡 방어",  "color": Color(0.5,  0.8,  1.0,  1)},
	{"label": "✨ 특수",  "color": Color(0.8,  0.6,  1.0,  1)},
	{"label": "💰 골드",  "color": Color(1.0,  0.85, 0.3,  1)},
]

# 페이즈별 티어 가중치
const TIER_WEIGHTS := {
	1: {1: 100, 2: 0,   3: 0},
	2: {1: 20,  2: 100, 3: 0},
	3: {1: 5,   2: 30,  3: 100},
}

var ap_manager:   ApManager
var gold_manager: GoldManager
var lane_cards:   Array = [null, null, null, null]  # CardData or null (레인별 진열 카드)
var is_player_turn: bool = false
var current_phase:  int  = 1

var _root_vbox:        VBoxContainer
var _slots_hbox:       HBoxContainer
var _reroll_ap_button: Button
var _reroll_gold_button: Button
var _lane_widgets: Array = []  # Array of dicts per lane


func _ready() -> void:
	_build_ui()


func setup(ap_mgr: ApManager, gold_mgr: GoldManager) -> void:
	ap_manager   = ap_mgr
	gold_manager = gold_mgr
	if gold_manager:
		gold_manager.gold_changed.connect(_on_gold_changed)
	if ap_manager:
		ap_manager.ap_changed.connect(_on_ap_changed)


# 라운드 시작 시 각 레인에서 1장씩 추첨
func refresh_slots() -> void:
	var weights: Dictionary = TIER_WEIGHTS.get(current_phase, TIER_WEIGHTS[1])
	var pools: Array = [attack_pool, defense_pool, special_pool, gold_pool]
	for i in range(LANE_COUNT):
		var pool: Array = pools[i]
		lane_cards[i] = _weighted_pick(pool, weights) if not pool.is_empty() else null
	_render_slots()


func set_player_turn(value: bool) -> void:
	is_player_turn = value
	_refresh_button_states()


func set_phase(phase: int) -> void:
	current_phase = phase


# 가중치 기반 무작위 추첨
func _weighted_pick(pool: Array, weights: Dictionary) -> CardData:
	var total := 0
	for c in pool:
		total += int(weights.get(c.tier, 0))
	if total <= 0:
		return null
	var roll := randi() % total
	var acc  := 0
	for c in pool:
		acc += int(weights.get(c.tier, 0))
		if roll < acc:
			return c
	return pool[0]


# === UI 빌드 ===

func _build_ui() -> void:
	_root_vbox = VBoxContainer.new()
	_root_vbox.add_theme_constant_override("separation", 4)
	add_child(_root_vbox)

	# 헤더 — 제목 + 리롤 버튼
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	_root_vbox.add_child(header)

	var title := Label.new()
	title.text = "마켓"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_reroll_ap_button = Button.new()
	_reroll_ap_button.text = "리롤 (3 AP)"
	_reroll_ap_button.add_theme_font_size_override("font_size", 14)
	_reroll_ap_button.pressed.connect(_on_reroll_ap_pressed)
	header.add_child(_reroll_ap_button)

	_reroll_gold_button = Button.new()
	_reroll_gold_button.text = "리롤 (3 G)"
	_reroll_gold_button.add_theme_font_size_override("font_size", 14)
	_reroll_gold_button.pressed.connect(_on_reroll_gold_pressed)
	header.add_child(_reroll_gold_button)

	# 4-레인 슬롯 영역
	_slots_hbox = HBoxContainer.new()
	_slots_hbox.add_theme_constant_override("separation", 6)
	_slots_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots_hbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_root_vbox.add_child(_slots_hbox)

	for i in range(LANE_COUNT):
		_lane_widgets.append(_build_lane_widget(i))


func _build_lane_widget(index: int) -> Dictionary:
	var meta: Dictionary = LANE_META[index]

	var lane_vbox := VBoxContainer.new()
	lane_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lane_vbox.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	lane_vbox.add_theme_constant_override("separation", 3)
	_slots_hbox.add_child(lane_vbox)

	# 레인 이름
	var header_lbl := Label.new()
	header_lbl.text = meta["label"]
	header_lbl.add_theme_font_size_override("font_size", 13)
	header_lbl.add_theme_color_override("font_color", meta["color"])
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_lbl.custom_minimum_size  = Vector2(CARD_WIDTH, 0)
	lane_vbox.add_child(header_lbl)

	# 카드 자리
	var card_holder := Control.new()
	card_holder.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	lane_vbox.add_child(card_holder)

	# 구매 버튼
	var buy_btn := Button.new()
	buy_btn.text = "구매"
	buy_btn.add_theme_font_size_override("font_size", 14)
	buy_btn.custom_minimum_size = Vector2(CARD_WIDTH, 32)
	buy_btn.pressed.connect(func() -> void: _on_buy_pressed(index))
	lane_vbox.add_child(buy_btn)

	return {
		"lane_vbox":   lane_vbox,
		"header_lbl":  header_lbl,
		"card_holder": card_holder,
		"card":        null,
		"buy_btn":     buy_btn,
	}


# === 렌더링 ===

func _render_slots() -> void:
	for i in range(LANE_COUNT):
		var w: Dictionary  = _lane_widgets[i]
		var cd: CardData   = lane_cards[i]

		# 기존 카드 인스턴스 제거
		if w.card != null and is_instance_valid(w.card):
			w.card.queue_free()
			w.card = null

		if cd != null:
			var card: Control = CardScene.instantiate()
			card.data         = cd
			card.is_face_up   = true
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			w.card_holder.add_child(card)
			w.card = card
			card.set_active(false)
			card.modulate.a = 1.0
			w.buy_btn.text    = "구매 (%d G)" % cd.gold_cost
			w.buy_btn.visible = true
		else:
			w.buy_btn.text    = "매진"
			w.buy_btn.visible = false

	_refresh_button_states()


func _refresh_button_states() -> void:
	var has_ap         := ap_manager   != null and ap_manager.has(REROLL_AP_COST)
	var has_gold_roll  := gold_manager != null and gold_manager.current >= REROLL_GOLD_COST
	_reroll_ap_button.disabled   = not is_player_turn or not has_ap
	_reroll_gold_button.disabled = not is_player_turn or not has_gold_roll

	for i in range(LANE_COUNT):
		var w:  Dictionary = _lane_widgets[i]
		var cd: CardData   = lane_cards[i]
		if cd == null:
			continue
		var afford := gold_manager != null and gold_manager.current >= cd.gold_cost
		w.buy_btn.disabled = not is_player_turn or not afford


# === 핸들러 ===

func _on_reroll_ap_pressed() -> void:
	if not is_player_turn or ap_manager == null:
		return
	if not ap_manager.has(REROLL_AP_COST):
		return
	ap_manager.spend(REROLL_AP_COST)
	refresh_slots()


func _on_reroll_gold_pressed() -> void:
	if not is_player_turn or gold_manager == null:
		return
	if gold_manager.current < REROLL_GOLD_COST:
		return
	gold_manager.spend(REROLL_GOLD_COST)
	refresh_slots()


func _on_buy_pressed(lane_index: int) -> void:
	if not is_player_turn:
		return
	var cd: CardData = lane_cards[lane_index]
	if cd == null:
		return
	if gold_manager == null or gold_manager.current < cd.gold_cost:
		return
	gold_manager.spend(cd.gold_cost)
	lane_cards[lane_index] = null
	card_purchased.emit(cd)
	_render_slots()


func _on_gold_changed(_current: int, _max_value: int) -> void:
	_refresh_button_states()


func _on_ap_changed(_current: int, _max_value: int) -> void:
	_refresh_button_states()
