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

# 레인별 카드 디렉토리 경로 (씬에서 오버라이드 가능, 기본값은 전사)
@export var attack_dir:  String = "res://resources/cards/warrior/market/attack"
@export var defense_dir: String = "res://resources/cards/warrior/market/defense"
@export var special_dir: String = "res://resources/cards/warrior/market/special"
@export var gold_dir:    String = "res://resources/cards/warrior/market/gold"

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

# 런타임에 디렉토리 스캔으로 채워지는 내부 풀 (씬 설정 불필요)
var _attack_pool:  Array[CardData] = []
var _defense_pool: Array[CardData] = []
var _special_pool: Array[CardData] = []
var _gold_pool:    Array[CardData] = []

var _root_vbox:        VBoxContainer
var _slots_hbox:       HBoxContainer
var _reroll_ap_button: Button
var _reroll_gold_button: Button
var _lane_widgets: Array = []  # Array of dicts per lane


func _ready() -> void:
	_attack_pool  = _load_pool(attack_dir)
	_defense_pool = _load_pool(defense_dir)
	_special_pool = _load_pool(special_dir)
	_gold_pool    = _load_pool(gold_dir)
	_build_ui()


# 디렉토리 안의 .tres 파일을 모두 로드해 CardData 배열로 반환
func _load_pool(dir_path: String) -> Array[CardData]:
	var result: Array[CardData] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("MarketPanel: 디렉토리를 열 수 없음 — %s" % dir_path)
		return result
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var res := load(dir_path + "/" + fname)
			if res is CardData:
				result.append(res as CardData)
			else:
				push_warning("MarketPanel: CardData가 아닌 파일 무시 — %s" % fname)
		fname = dir.get_next()
	dir.list_dir_end()
	return result


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
	var pools: Array = [_attack_pool, _defense_pool, _special_pool, _gold_pool]
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

	# 4-레인 슬롯 영역 (마진 감싸기)
	var slots_margin := MarginContainer.new()
	slots_margin.add_theme_constant_override("margin_left",   12)
	slots_margin.add_theme_constant_override("margin_right",  12)
	slots_margin.add_theme_constant_override("margin_top",    6)
	slots_margin.add_theme_constant_override("margin_bottom", 6)
	slots_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_margin.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_root_vbox.add_child(slots_margin)

	_slots_hbox = HBoxContainer.new()
	_slots_hbox.add_theme_constant_override("separation", 36)
	_slots_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots_hbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	slots_margin.add_child(_slots_hbox)

	for i in range(LANE_COUNT):
		_lane_widgets.append(_build_lane_widget(i))


func _build_lane_widget(index: int) -> Dictionary:
	var meta: Dictionary = LANE_META[index]

	var lane_vbox := VBoxContainer.new()
	lane_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lane_vbox.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	lane_vbox.add_theme_constant_override("separation", 4)
	_slots_hbox.add_child(lane_vbox)

	# 레인 이름
	var header_lbl := Label.new()
	header_lbl.text = meta["label"]
	header_lbl.add_theme_font_size_override("font_size", 13)
	header_lbl.add_theme_color_override("font_color", meta["color"])
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_lbl.custom_minimum_size  = Vector2(CARD_WIDTH, 0)
	lane_vbox.add_child(header_lbl)

	# 래퍼: 카드 + 구매 버튼 오버레이를 하나의 Control로 묶음
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	lane_vbox.add_child(wrapper)

	# 카드가 들어갈 영역 (래퍼 전체)
	var card_holder := Control.new()
	card_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(card_holder)

	# 구매 버튼 — 카드 하단에 딱 붙인 오버레이
	# anchor top=1/bottom=1 → 래퍼 하단 기준, offset_top으로 높이 지정
	var buy_btn := Button.new()
	buy_btn.anchor_left   = 0.0
	buy_btn.anchor_right  = 1.0
	buy_btn.anchor_top    = 1.0
	buy_btn.anchor_bottom = 1.0
	buy_btn.offset_left   = 0
	buy_btn.offset_right  = 0
	buy_btn.offset_top    = -36
	buy_btn.offset_bottom = 0
	buy_btn.add_theme_font_size_override("font_size", 15)
	buy_btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85, 1))
	buy_btn.pressed.connect(func() -> void: _on_buy_pressed(index))
	_style_buy_button(buy_btn, meta["color"])
	wrapper.add_child(buy_btn)  # 카드 위(z+1)에 렌더링

	return {
		"lane_vbox":   lane_vbox,
		"header_lbl":  header_lbl,
		"card_holder": card_holder,
		"card":        null,
		"buy_btn":     buy_btn,
	}


func _style_buy_button(btn: Button, lane_color: Color) -> void:
	# Normal — 레인 색 기반, 하단만 둥근 모서리 (카드 하단과 자연스럽게 결합)
	var normal := StyleBoxFlat.new()
	normal.bg_color = lane_color.darkened(0.3)
	normal.bg_color.a = 0.92
	normal.border_color = lane_color
	normal.set_border_width_all(0)
	normal.border_width_top = 1
	normal.corner_radius_bottom_left  = 6
	normal.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal)

	# Hover — 밝게
	var hover := StyleBoxFlat.new()
	hover.bg_color = lane_color.darkened(0.1)
	hover.bg_color.a = 0.96
	hover.border_color = lane_color.lightened(0.25)
	hover.set_border_width_all(0)
	hover.border_width_top = 1
	hover.corner_radius_bottom_left  = 6
	hover.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", hover)

	# Pressed
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = lane_color.darkened(0.5)
	pressed.bg_color.a = 1.0
	pressed.set_border_width_all(0)
	pressed.corner_radius_bottom_left  = 6
	pressed.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("pressed", pressed)

	# Disabled — 어두운 반투명
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color(0.1, 0.1, 0.1, 0.75)
	disabled.set_border_width_all(0)
	disabled.corner_radius_bottom_left  = 6
	disabled.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4, 1))


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
