class_name MarketPanel
extends PanelContainer

# 4-레인 라운드 마켓
# 레인: 공격 / 방어 / 특수 / 골드
# 각 레인은 독립 서브풀에서 페이즈 가중치 추첨으로 1장 진열
# 리롤: 전체 레인 동시 재추첨 (AP 3 또는 골드 3)
# 구매: 해당 레인 슬롯 비움, 다음 refresh까지 유지

signal card_purchased(card_data: CardData)

const CardScene := preload("res://scenes/cards/card.tscn")
const LANE_COUNT := 4
## 리롤 비용은 scripts/data/game_balance.gd 에서 수정하세요.
const REROLL_AP_COST   := GameBalance.MARKET_REROLL_AP
const REROLL_GOLD_COST := GameBalance.MARKET_REROLL_GOLD
## 컴팩트 스트립 — 화면 세로 예산이 마켓에 123px밖에 없어 풀사이즈 카드(170px+)가 안 들어간다.
## 썸네일은 transform scale로 줄여야 폰트까지 함께 축소돼 미니어처로 보인다(size로 줄이면 글자가 넘침).
const CARD_NATURAL  := Vector2(146, 206)   # card.tscn 실제 크기
const THUMB_SCALE   := 0.30                # 썸네일 배율 → 44×62
const PREVIEW_SCALE := 1.15                # 호버 미리보기 배율
const THUMB_SIZE    := Vector2(CARD_NATURAL.x * THUMB_SCALE, CARD_NATURAL.y * THUMB_SCALE)

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

var _preview:          Control = null   # 호버 시 뜬 전체 카드 (1장만 유지)
var _root_vbox:        VBoxContainer
var _slots_hbox:       HBoxContainer
var _reroll_ap_button: Button
var _reroll_gold_button: Button
var _lane_widgets: Array = []  # Array of dicts per lane


func _ready() -> void:
	_apply_panel_frame()
	_attack_pool  = _load_pool(attack_dir)
	_defense_pool = _load_pool(defense_dir)
	_special_pool = _load_pool(special_dir)
	_gold_pool    = _load_pool(gold_dir)
	_build_ui()


# Kenney 장식 프레임을 마켓 패널 배경으로 적용 (게임 전체와 통일)
func _apply_panel_frame() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_stylebox_override("panel", DarkFantasyTheme.kenney_panel(true, 10))


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

	# 4-레인 슬롯 영역 (마진 감싸기)
	var slots_margin := MarginContainer.new()
	slots_margin.add_theme_constant_override("margin_left",   12)
	slots_margin.add_theme_constant_override("margin_right",  12)
	slots_margin.add_theme_constant_override("margin_top",    3)
	slots_margin.add_theme_constant_override("margin_bottom", 3)
	slots_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_margin.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_root_vbox.add_child(slots_margin)

	_slots_hbox = HBoxContainer.new()
	_slots_hbox.add_theme_constant_override("separation", 10)
	_slots_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots_hbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	slots_margin.add_child(_slots_hbox)

	for i in range(LANE_COUNT):
		_lane_widgets.append(_build_lane_widget(i))

	_build_reroll_column()


# 리롤 버튼 — 레인 오른쪽 세로 컬럼.
# 전용 헤더 행을 쓰면 세로 44px를 먹는데, 상시 노출 마켓은 세로가 빠듯하고
# 가로는 남으므로(4레인 560px) 옆으로 뺐다.
func _build_reroll_column() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_slots_hbox.add_child(col)

	var title := Label.new()
	title.text = "↻ 재추첨"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	# 버튼 2개는 가로로 — 세로로 쌓으면 이 컬럼이 레인보다 높아져 마켓 전체 높이를 밀어올린다
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 5)
	col.add_child(btn_row)

	_reroll_ap_button = Button.new()
	_reroll_ap_button.text = "3 ⚡"
	_reroll_ap_button.tooltip_text = "AP 3을 소모해 마켓 전체를 재추첨"
	_reroll_ap_button.custom_minimum_size = Vector2(64, 30)
	_reroll_ap_button.add_theme_font_size_override("font_size", 15)
	_reroll_ap_button.pressed.connect(_on_reroll_ap_pressed)
	btn_row.add_child(_reroll_ap_button)

	_reroll_gold_button = Button.new()
	_reroll_gold_button.text = "3 💰"
	_reroll_gold_button.tooltip_text = "골드 3을 소모해 마켓 전체를 재추첨"
	_reroll_gold_button.custom_minimum_size = Vector2(64, 30)
	_reroll_gold_button.add_theme_font_size_override("font_size", 15)
	_reroll_gold_button.pressed.connect(_on_reroll_gold_pressed)
	btn_row.add_child(_reroll_gold_button)


func _build_lane_widget(index: int) -> Dictionary:
	var meta: Dictionary = LANE_META[index]

	var lane_vbox := VBoxContainer.new()
	lane_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # 4레인 균등 분산
	lane_vbox.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	lane_vbox.add_theme_constant_override("separation", 2)
	_slots_hbox.add_child(lane_vbox)

	# 레인 이름
	var header_lbl := Label.new()
	header_lbl.text = meta["label"]
	header_lbl.add_theme_font_size_override("font_size", 14)
	header_lbl.add_theme_color_override("font_color", meta["color"])
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lane_vbox.add_child(header_lbl)

	# 본문 — [썸네일][이름 + 구매] 가로 배치 (세로 절약).
	# 레인 슬롯이 넓어도 내용은 가운데로 모은다 (EXPAND_FILL이면 버튼이 레인 폭만큼 늘어남)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	lane_vbox.add_child(row)

	# 썸네일 자리 — 호버 시 전체 카드 미리보기
	var card_holder := Control.new()
	card_holder.custom_minimum_size = THUMB_SIZE
	card_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card_holder.mouse_filter = Control.MOUSE_FILTER_PASS
	card_holder.tooltip_text = "마우스를 올리면 카드를 크게 봅니다"
	card_holder.mouse_entered.connect(_show_preview.bind(index))
	card_holder.mouse_exited.connect(_hide_preview)
	row.add_child(card_holder)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	info.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.custom_minimum_size = Vector2(104, 0)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86, 1))
	info.add_child(name_lbl)

	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(104, 26)
	buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	buy_btn.add_theme_font_size_override("font_size", 14)
	buy_btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85, 1))
	buy_btn.pressed.connect(func() -> void: _on_buy_pressed(index))
	_style_buy_button(buy_btn, meta["color"])
	info.add_child(buy_btn)

	return {
		"lane_vbox":   lane_vbox,
		"header_lbl":  header_lbl,
		"card_holder": card_holder,
		"card":        null,
		"name_lbl":    name_lbl,
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
	_hide_preview()   # 리롤/구매로 카드가 바뀌면 떠 있던 미리보기는 무효
	for i in range(LANE_COUNT):
		var w: Dictionary  = _lane_widgets[i]
		var cd: CardData   = lane_cards[i]

		# 기존 카드 인스턴스 제거
		if w.card != null and is_instance_valid(w.card):
			w.card.queue_free()
			w.card = null

		if cd != null:
			var card: Control = _make_card_visual(cd, THUMB_SCALE)
			w.card_holder.add_child(card)
			w.card = card
			w.name_lbl.text   = cd.card_name
			w.buy_btn.text    = "구매 (%d G)" % cd.gold_cost
			w.buy_btn.visible = true
		else:
			w.name_lbl.text   = "—"
			w.buy_btn.text    = "매진"
			w.buy_btn.visible = false

	_refresh_button_states()


# 카드 비주얼 1장 생성. size가 아닌 transform scale로 축소해야 글자까지 함께 줄어든다.
func _make_card_visual(cd: CardData, card_scale: float) -> Control:
	var card: Control = CardScene.instantiate()
	card.data         = cd
	card.is_face_up   = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size = CARD_NATURAL
	card.size         = CARD_NATURAL
	card.pivot_offset = Vector2.ZERO      # 좌상단 기준 축소 → holder에 딱 맞음
	card.scale        = Vector2(card_scale, card_scale)
	card.set_active(false)
	card.modulate.a   = 1.0
	return card


# === 호버 미리보기 — 썸네일만으론 효과를 못 읽으므로 전체 카드를 위에 띄운다 ===

func _show_preview(index: int) -> void:
	_hide_preview()
	var cd: CardData = lane_cards[index]
	if cd == null:
		return
	var w: Dictionary = _lane_widgets[index]
	var holder: Control = w.card_holder
	var card := _make_card_visual(cd, PREVIEW_SCALE)
	card.z_index = 200
	add_child(card)
	_preview = card
	# 썸네일 바로 위, 가로 중앙 정렬 (마켓 패널 로컬 좌표)
	var local: Vector2 = holder.global_position - global_position
	var pw: float = CARD_NATURAL.x * PREVIEW_SCALE
	var ph: float = CARD_NATURAL.y * PREVIEW_SCALE
	card.position = Vector2(
		local.x + holder.size.x * 0.5 - pw * 0.5,
		local.y - ph - 10)


func _hide_preview() -> void:
	if _preview != null and is_instance_valid(_preview):
		_preview.queue_free()
	_preview = null


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
