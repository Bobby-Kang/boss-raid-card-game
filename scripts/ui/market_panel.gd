class_name MarketPanel
extends PanelContainer

# 라운드 마켓
# - 라운드 시작 시 card_pool에서 SLOT_COUNT장을 랜덤 추출해 진열
# - 각 카드별 고정 골드 가격 (CardData.gold_cost)
# - 리롤: AP 3 또는 Gold 3 소모 (플레이어 턴에만)
# - 구매: 카드의 gold_cost 만큼 골드 소모, 슬롯에서 제거 후 card_purchased 시그널 emit
# - 보스 턴에는 모든 버튼 비활성

signal card_purchased(card_data: CardData)

const CardScene := preload("res://scenes/cards/card.tscn")
const SLOT_COUNT := 3
const REROLL_AP_COST := 3
const REROLL_GOLD_COST := 3
const CARD_WIDTH := 144
const CARD_HEIGHT := 204

@export var card_pool: Array[CardData] = []

# 페이즈별 티어 가중치 테이블
# phase 1: T1만
# phase 2: T2 메인, T1은 낮은 확률로 등장
# phase 3: T3 메인, T2 보조, T1 거의 안 나옴
const TIER_WEIGHTS := {
	1: {1: 100, 2: 0,   3: 0},
	2: {1: 20,  2: 100, 3: 0},
	3: {1: 5,   2: 30,  3: 100},
}

var ap_manager: ApManager
var gold_manager: GoldManager
var slots: Array[CardData] = []
var is_player_turn: bool = false
var current_phase: int = 1

var _root_vbox: VBoxContainer
var _slots_hbox: HBoxContainer
var _reroll_ap_button: Button
var _reroll_gold_button: Button
var _slot_widgets: Array = []  # Array of dicts {slot, card_holder, card, buy_btn}


func _ready() -> void:
	_build_ui()


func setup(ap_mgr: ApManager, gold_mgr: GoldManager) -> void:
	ap_manager = ap_mgr
	gold_manager = gold_mgr
	if gold_manager:
		gold_manager.gold_changed.connect(_on_gold_changed)
	if ap_manager:
		ap_manager.ap_changed.connect(_on_ap_changed)


func refresh_slots() -> void:
	slots.clear()
	if card_pool.is_empty():
		_render_slots()
		return
	var weights: Dictionary = TIER_WEIGHTS.get(current_phase, TIER_WEIGHTS[1])
	var available := card_pool.duplicate()
	for i in range(mini(SLOT_COUNT, available.size())):
		var card := _weighted_pick(available, weights)
		if card == null:
			break
		slots.append(card)
		available.erase(card)
	_render_slots()


func set_player_turn(value: bool) -> void:
	is_player_turn = value
	_refresh_button_states()


func set_phase(phase: int) -> void:
	# 진행 중인 슬롯은 유지, 다음 refresh부터 적용
	current_phase = phase


func _weighted_pick(pool: Array, weights: Dictionary) -> CardData:
	var total := 0
	for c in pool:
		total += int(weights.get(c.tier, 0))
	if total <= 0:
		return null
	var roll := randi() % total
	var acc := 0
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

	# 헤더 (제목 + 리롤 버튼 2개)
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
	_reroll_ap_button.add_theme_font_size_override("font_size", 16)
	_reroll_ap_button.pressed.connect(_on_reroll_ap_pressed)
	header.add_child(_reroll_ap_button)

	_reroll_gold_button = Button.new()
	_reroll_gold_button.text = "리롤 (3 G)"
	_reroll_gold_button.add_theme_font_size_override("font_size", 16)
	_reroll_gold_button.pressed.connect(_on_reroll_gold_pressed)
	header.add_child(_reroll_gold_button)

	# 슬롯 영역
	_slots_hbox = HBoxContainer.new()
	_slots_hbox.add_theme_constant_override("separation", 8)
	_slots_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_vbox.add_child(_slots_hbox)

	for i in range(SLOT_COUNT):
		_slot_widgets.append(_build_slot_widget(i))


func _build_slot_widget(index: int) -> Dictionary:
	# 카드 한 장 + 구매 버튼을 세로로 묶음
	var slot_vbox := VBoxContainer.new()
	slot_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot_vbox.add_theme_constant_override("separation", 4)
	_slots_hbox.add_child(slot_vbox)

	# 카드 자리 (실제 카드 크기 그대로)
	var card_holder := Control.new()
	card_holder.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	slot_vbox.add_child(card_holder)

	# 구매 버튼
	var buy_btn := Button.new()
	buy_btn.text = "구매"
	buy_btn.add_theme_font_size_override("font_size", 17)
	buy_btn.custom_minimum_size = Vector2(CARD_WIDTH, 36)
	buy_btn.pressed.connect(func() -> void: _on_buy_pressed(index))
	slot_vbox.add_child(buy_btn)

	return {
		"slot": slot_vbox,
		"card_holder": card_holder,
		"card": null,
		"buy_btn": buy_btn,
	}


# === 렌더링 ===

func _render_slots() -> void:
	for i in range(SLOT_COUNT):
		var widget: Dictionary = _slot_widgets[i]
		# 기존 카드 인스턴스 제거
		if widget.card != null and is_instance_valid(widget.card):
			widget.card.queue_free()
			widget.card = null

		if i < slots.size():
			var card_data: CardData = slots[i]
			widget.slot.visible = true
			# 새 카드 인스턴스 생성 (마켓용 — 비활성, 드래그 불가)
			var card: Control = CardScene.instantiate()
			card.data = card_data
			card.is_face_up = true
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			widget.card_holder.add_child(card)
			widget.card = card
			# _ready 후 비활성 처리 (드래그 차단 + 시각적 dim 제거)
			card.set_active(false)
			card.modulate.a = 1.0  # 비활성이라도 마켓 카드는 또렷하게
			widget.buy_btn.text = "구매 (%d G)" % card_data.gold_cost
		else:
			widget.slot.visible = false
	_refresh_button_states()


func _refresh_button_states() -> void:
	var has_ap := ap_manager != null and ap_manager.has(REROLL_AP_COST)
	var has_gold_for_reroll := gold_manager != null and gold_manager.current >= REROLL_GOLD_COST

	_reroll_ap_button.disabled = not is_player_turn or not has_ap
	_reroll_gold_button.disabled = not is_player_turn or not has_gold_for_reroll

	for i in range(SLOT_COUNT):
		var widget: Dictionary = _slot_widgets[i]
		if i >= slots.size():
			continue
		var card_data: CardData = slots[i]
		var afford := gold_manager != null and gold_manager.current >= card_data.gold_cost
		widget.buy_btn.disabled = not is_player_turn or not afford


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


func _on_buy_pressed(index: int) -> void:
	if not is_player_turn:
		return
	if index < 0 or index >= slots.size():
		return
	var card_data: CardData = slots[index]
	if gold_manager == null or gold_manager.current < card_data.gold_cost:
		return
	gold_manager.spend(card_data.gold_cost)
	slots.remove_at(index)
	card_purchased.emit(card_data)
	_render_slots()


func _on_gold_changed(_current: int, _max_value: int) -> void:
	_refresh_button_states()


func _on_ap_changed(_current: int, _max_value: int) -> void:
	_refresh_button_states()
