class_name MarketPanel
extends PanelContainer

# 라운드 마켓
# - 라운드 시작 시 card_pool에서 SLOT_COUNT장을 랜덤 추출해 진열
# - 각 카드별 고정 골드 가격 (CardData.gold_cost)
# - 리롤: AP 3 또는 Gold 3 소모 (플레이어 턴에만)
# - 구매: 카드의 gold_cost 만큼 골드 소모, 슬롯에서 제거 후 card_purchased 시그널 emit
# - 보스 턴에는 모든 버튼 비활성

signal card_purchased(card_data: CardData)

const SLOT_COUNT := 3
const REROLL_AP_COST := 3
const REROLL_GOLD_COST := 3

@export var card_pool: Array[CardData] = []

var ap_manager: ApManager
var gold_manager: GoldManager
var slots: Array[CardData] = []
var is_player_turn: bool = false

var _root_vbox: VBoxContainer
var _slots_hbox: HBoxContainer
var _reroll_ap_button: Button
var _reroll_gold_button: Button
var _slot_widgets: Array = []  # Array of dictionaries {root, name_lbl, desc_lbl, cost_lbl, buy_btn}


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
	var pool := card_pool.duplicate()
	pool.shuffle()
	var n := mini(SLOT_COUNT, pool.size())
	for i in range(n):
		slots.append(pool[i])
	_render_slots()


func set_player_turn(value: bool) -> void:
	is_player_turn = value
	_refresh_button_states()


# === UI 빌드 ===

func _build_ui() -> void:
	_root_vbox = VBoxContainer.new()
	_root_vbox.add_theme_constant_override("separation", 4)
	add_child(_root_vbox)

	# 헤더
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	_root_vbox.add_child(header)

	var title := Label.new()
	title.text = "마켓"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_reroll_ap_button = Button.new()
	_reroll_ap_button.text = "리롤 (3 AP)"
	_reroll_ap_button.add_theme_font_size_override("font_size", 10)
	_reroll_ap_button.pressed.connect(_on_reroll_ap_pressed)
	header.add_child(_reroll_ap_button)

	_reroll_gold_button = Button.new()
	_reroll_gold_button.text = "리롤 (3 G)"
	_reroll_gold_button.add_theme_font_size_override("font_size", 10)
	_reroll_gold_button.pressed.connect(_on_reroll_gold_pressed)
	header.add_child(_reroll_gold_button)

	# 슬롯 영역
	_slots_hbox = HBoxContainer.new()
	_slots_hbox.add_theme_constant_override("separation", 6)
	_slots_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_vbox.add_child(_slots_hbox)

	for i in range(SLOT_COUNT):
		_slot_widgets.append(_build_slot_widget(i))


func _build_slot_widget(index: int) -> Dictionary:
	var slot := PanelContainer.new()
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.16, 0.13, 0.9)
	style.border_color = Color(0.55, 0.45, 0.3, 1)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	slot.add_theme_stylebox_override("panel", style)

	_slots_hbox.add_child(slot)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	slot.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 1))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_lbl)

	var cost_lbl := Label.new()
	cost_lbl.add_theme_font_size_override("font_size", 11)
	cost_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "구매"
	buy_btn.add_theme_font_size_override("font_size", 10)
	buy_btn.pressed.connect(func() -> void: _on_buy_pressed(index))
	vbox.add_child(buy_btn)

	return {
		"root": slot,
		"name_lbl": name_lbl,
		"desc_lbl": desc_lbl,
		"cost_lbl": cost_lbl,
		"buy_btn": buy_btn,
	}


# === 렌더링 ===

func _render_slots() -> void:
	for i in range(SLOT_COUNT):
		var widget: Dictionary = _slot_widgets[i]
		if i < slots.size():
			var card_data: CardData = slots[i]
			widget.root.visible = true
			widget.name_lbl.text = "[%d AP] %s" % [card_data.cost, card_data.card_name]
			widget.desc_lbl.text = card_data.get_description_text()
			widget.cost_lbl.text = "%d 골드" % card_data.gold_cost
			widget.buy_btn.text = "구매"
		else:
			widget.root.visible = false
	_refresh_button_states()


func _refresh_button_states() -> void:
	var has_ap := ap_manager != null and ap_manager.has(REROLL_AP_COST)
	var has_gold := gold_manager != null and gold_manager.current >= REROLL_GOLD_COST

	_reroll_ap_button.disabled = not is_player_turn or not has_ap
	_reroll_gold_button.disabled = not is_player_turn or not has_gold

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
