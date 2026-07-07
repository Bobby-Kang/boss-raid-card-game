extends Control

const CardScene := preload("res://scenes/cards/card.tscn")
## 수치 조정은 scripts/data/game_balance.gd 에서 하세요.
const DRAW_COUNT      := GameBalance.PLAYER_DRAW_COUNT
const TURNS_PER_ROUND := GameBalance.TURNS_PER_ROUND

# 카드 종류 (공용 스타터 4종)
const CARD_GOLD := preload("res://resources/cards/starter_gold.tres")
const CARD_ATTACK := preload("res://resources/cards/starter_attack.tres")
const CARD_BLOCK := preload("res://resources/cards/starter_block.tres")
const CARD_DRAW := preload("res://resources/cards/starter_draw.tres")

# 전사 전용 모듈
const MODULE_COUNTER_STANCE := preload("res://resources/cards/warrior/module_counter_stance.tres")

# 버그베어 보스 카드덱 (Phase별 티어 블록)
const BUGBEAR_PHASE1: Array = [
	preload("res://resources/bosses/bugbear/phase1/bugbear_scratch.tres"),
	preload("res://resources/bosses/bugbear/phase1/bugbear_growl.tres"),
	preload("res://resources/bosses/bugbear/phase1/bugbear_crouch.tres"),
	preload("res://resources/bosses/bugbear/phase1/bugbear_toxic_claw.tres"),
	preload("res://resources/bosses/bugbear/phase1/bugbear_intimidate.tres"),
	preload("res://resources/bosses/bugbear/phase1/bugbear_hunt_start.tres"),
]
const BUGBEAR_PHASE2: Array = [
	preload("res://resources/bosses/bugbear/phase2/bugbear_heavy_strike.tres"),
	preload("res://resources/bosses/bugbear/phase2/bugbear_rage_roar.tres"),
	preload("res://resources/bosses/bugbear/phase2/bugbear_iron_wall.tres"),
	preload("res://resources/bosses/bugbear/phase2/bugbear_combo_scratch.tres"),
	preload("res://resources/bosses/bugbear/phase2/bugbear_cruel_blow.tres"),
	preload("res://resources/bosses/bugbear/phase2/bugbear_beast_cry.tres"),
]
const BUGBEAR_PHASE3: Array = [
	preload("res://resources/bosses/bugbear/phase3/bugbear_frenzy.tres"),
	preload("res://resources/bosses/bugbear/phase3/bugbear_crush.tres"),
	preload("res://resources/bosses/bugbear/phase3/bugbear_despair_roar.tres"),
	preload("res://resources/bosses/bugbear/phase3/bugbear_last_stand.tres"),
	preload("res://resources/bosses/bugbear/phase3/bugbear_mad_charge.tres"),
	preload("res://resources/bosses/bugbear/phase3/bugbear_blood_chase.tres"),
]

# Rage UI
const RAGE_COLOR := Color(1.0, 0.55, 0.15, 1.0)
const RAGE_EMPTY_COLOR := Color(0.35, 0.35, 0.35, 1.0)
const RAGE_ORB_SIZE := 12

# Phase UI
const PHASE_COLORS := {
	1: Color(1, 1, 1, 1),
	2: Color(0.5, 0.7, 1.0, 1),
	3: Color(1.0, 0.4, 0.4, 1),
}

# 골드 3 · 베기 4 · 막기 2 · 집중 1 (10장)
# 스타터는 순수 기본기(공격·방어·드로우·자원)만. 콤보(인접 등)는 마켓에서.
# 시작 시 1회 셔플하므로 배열 순서는 무의미 (게임 중엔 섞지 않음 — 파이프 컨셉 유지)
const STARTER_DECK: Array = [
	CARD_GOLD, CARD_GOLD, CARD_GOLD, CARD_ATTACK, CARD_ATTACK,
	CARD_ATTACK, CARD_ATTACK, CARD_BLOCK, CARD_BLOCK, CARD_DRAW
]

# 손패 존
@onready var hand_belt: HBoxContainer = %HandBelt
# 타임라인 파이프
@onready var pipe_queue: VBoxContainer = %PipeQueue
@onready var queue_card_holder: Control = %QueueCardHolder

@onready var resource_bar: PanelContainer = %ResourceBar
@onready var hp_label: Label = %HpLabel
@onready var block_label: Label = %BlockLabel
@onready var boss_hp_label: Label = %BossHpLabel
@onready var boss_block_label: Label = %BossBlockLabel
@onready var turn_indicator_label: Label = %TurnIndicatorLabel
@onready var market_button: Button = %MarketButton
@onready var market_window: Control = %MarketWindow
@onready var market_close_button: Button = %MarketCloseButton
@onready var market_dim_bg: ColorRect = %DimBg
@onready var end_turn_button: Button = %EndTurnButton
@onready var end_turn_overlay: CanvasLayer = %EndTurnOverlay
@onready var phase_banner: CanvasLayer = %PhaseBanner
@onready var game_result_screen: CanvasLayer = %GameResultScreen
@onready var round_label: Label = %RoundLabel
@onready var phase_label: Label = %PhaseLabel
@onready var turn_slots_container: HBoxContainer = %TurnSlotsContainer

# 드롭 존
@onready var play_drop_zone: PanelContainer = %PlayDropZone
@onready var timeline_pipe_panel: PanelContainer = %TimelinePipePanel
@onready var active_slot_1: PanelContainer = %ActiveSlot1
@onready var active_slot_2: PanelContainer = %ActiveSlot2

# Rage UI (전사 투기 발산)
@onready var rage_label: Label = %RageLabel
@onready var rage_orbs: HBoxContainer = %RageOrbs
@onready var rage_button: Button = %RageButton

# 마켓 (MarketPanel — class_name 등록 race 회피 위해 PanelContainer로 타이핑)
@onready var market_panel: PanelContainer = %MarketPanel

# 보스 카드 UI
@onready var boss_deck_count_label: Label = %BossDeckCountLabel
@onready var boss_discard_label: Label = %BossDiscardLabel
@onready var boss_next_card_container: Control = %BossNextCardContainer
@onready var boss_power_zone: VBoxContainer = %BossPowerZone

# 캐릭터 아바타 (배틀 연출용)
@onready var boss_face: PanelContainer = %BossFace
@onready var boss_face_texture: TextureRect = %BossFaceTexture
@onready var boss_intent_label: Label = %BossIntentLabel
@onready var player_face: PanelContainer = %PlayerFace
@onready var player_face_texture: TextureRect = %PlayerFaceTexture

# 카드 배열
var hand_cards: Array[Control] = []    # 손패 (최대 5장, 사용 가능)
var queue_cards: Array[Control] = []   # 타임라인 파이프 (대기 중)

var game_ctx: GameContext
var rage_system: WarriorRageSystem
var phase_system: BossPhaseSystem
var boss_deck_system: BossDeckSystem
var is_discarding_from_effect: bool = false
var game_over: bool = false

# === 게임 로그 (A: 모달 전체 로그 / B: 파이프 오른쪽 미니 로그) ===
const _LOG_MAX := 150
const _MINI_LOG_LINES := 5
var _game_log: Array = []   # [{short: String, full: String}] — B는 short, A 모달은 full
var _log_button: Button
var _log_layer: CanvasLayer
var _log_root: Control
var _log_list_vbox: VBoxContainer
var _log_scroll: ScrollContainer
var _mini_log_label: Label

# === Scene 헬퍼 (분리된 책임) ===
var combat_fx: CombatFeedback           # 플래시·셰이크·Hit-stop
var card_hover: CardHoverPreview        # 호버 효과 라벨 + 파이프 카드 프리뷰
var exile_animator: ExileAnimator       # 카드 영구 소멸 연출
var boss_presenter: BossActionPresenter # 보스 턴 행동 카드 연출
var tutorial: TutorialOverlay           # 첫 플레이 스포트라이트 튜토리얼
var _tutorial_shown: bool = false       # 이번 세션에서 이미 표시했는지

# === 페이즈 보상 큐 (시그널 콜백 도중 await race 회피) ===
# 각 항목은 _grant_card_removal_reward에 넘길 reason_lines: Array[String]
var _pending_rewards: Array = []

# 액티브 슬롯
var active_cards: Array[Control] = [null, null]

# 라운드/턴
var current_round: int = 1
var current_turn: int = 0
var turn_order: Array[String] = []
var turn_slot_labels: Array[Label] = []

# === HP 바 / 데미지 팝업 ===
var _player_hp_fill: ColorRect = null   # 플레이어 HP 바 채움 rect
var _boss_hp_fill:   ColorRect = null   # 보스 HP 바 채움 rect
var _prev_player_hp: int = -1           # 이전 HP (데미지 팝업 계산용)
var _prev_boss_hp:   int = -1


func _ready() -> void:
	theme = DarkFantasyTheme.build()   # 전체 UI 다크 판타지 테마 적용
	_setup_background_atmosphere()
	_setup_helpers()
	_setup_phase_deck_chips()   # 보스 덱 카운트 → 3-페이즈 칩 행 교체
	_setup_game_context()
	_setup_drop_zones()
	_setup_game_log()   # 로그 UI를 먼저 만들어 _init_starter_deck의 첫 로그부터 반영
	_init_starter_deck()
	resource_bar.gold_manager.set_to(0)
	resource_bar.ap_manager.set_to(3)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	end_turn_overlay.order_confirmed.connect(_on_end_turn_order_confirmed)
	end_turn_overlay.cancelled.connect(_on_end_turn_cancelled)
	# 마켓 토글 (상점 버튼으로 오버레이 열고/닫기)
	market_button.pressed.connect(_toggle_market)
	market_close_button.pressed.connect(_close_market)
	market_dim_bg.gui_input.connect(_on_market_dim_input)
	market_window.visible = false
	# Phase 1 BGM 시작
	AudioManager.play_bgm(SfxLibrary.BGM_PHASE_1, 1.0)


# === 헬퍼 노드 (분리된 책임) ===

# 배경 깊이감 — 세로 그라데이션 + 가장자리 비네팅
func _setup_background_atmosphere() -> void:
	# 1) 세로 그라데이션 (상단 갈색 → 하단 흑갈색)
	var grad := GradientTexture2D.new()
	grad.fill = GradientTexture2D.FILL_LINEAR
	grad.fill_from = Vector2(0.5, 0.0)
	grad.fill_to = Vector2(0.5, 1.0)
	var g := Gradient.new()
	g.set_color(0, DarkFantasyTheme.BG_MID)
	g.set_color(1, DarkFantasyTheme.BG_DEEP)
	grad.gradient = g
	var grad_rect := TextureRect.new()
	grad_rect.name = "BgGradient"
	grad_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	grad_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grad_rect.texture = grad
	grad_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grad_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(grad_rect)
	move_child(grad_rect, 1)   # Background ColorRect 바로 위 (트리 순서로 위에 그려짐)

	# 2) 가장자리 비네팅 (radial: 중앙 투명 → 가장자리 어둠)
	var vig_grad := GradientTexture2D.new()
	vig_grad.fill = GradientTexture2D.FILL_RADIAL
	vig_grad.fill_from = Vector2(0.5, 0.5)
	vig_grad.fill_to = Vector2(1.0, 0.5)
	var vg := Gradient.new()
	vg.set_color(0, Color(0, 0, 0, 0.0))
	vg.set_color(1, Color(0, 0, 0, 0.55))
	vig_grad.gradient = vg
	var vig := TextureRect.new()
	vig.name = "BgVignette"
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.texture = vig_grad
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(vig)
	move_child(vig, 2)   # gradient 위, BattleField 아래


func _setup_helpers() -> void:
	combat_fx = CombatFeedback.new()
	add_child(combat_fx)
	combat_fx.setup(self)

	card_hover = CardHoverPreview.new()
	add_child(card_hover)
	# game_ctx + 앵커는 _setup_game_context 끝에서 setup

	exile_animator = ExileAnimator.new()
	add_child(exile_animator)
	exile_animator.setup(self)

	boss_presenter = BossActionPresenter.new()
	add_child(boss_presenter)
	boss_presenter.setup(combat_fx, boss_face_texture, player_face_texture)

	tutorial = TutorialOverlay.new()
	add_child(tutorial)

	_setup_status_indicators()


# === 상태 인디케이터 (드로우 봉인 / 취약 / 피 냄새) ===

var _draw_lock_label: Label = null
var _vuln_label: Label = null
var _blood_vignette: TextureRect = null
var _blood_pulse_tween: Tween = null


func _make_status_label(font_color: Color) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", font_color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 90
	lbl.visible = false
	add_child(lbl)
	return lbl


func _setup_status_indicators() -> void:
	# 드로우 봉인 — 손패 영역 상단
	_draw_lock_label = _make_status_label(Color(0.7, 0.85, 1.0, 1))
	# 취약 — 플레이어 HP 라벨 옆
	_vuln_label = _make_status_label(Color(1.0, 0.45, 0.55, 1))

	# 피 냄새 — 화면 가장자리 핏빛 비네팅 (radial gradient)
	var grad := GradientTexture2D.new()
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.fill_from = Vector2(0.5, 0.5)
	grad.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(0.6, 0.0, 0.0, 0.0))   # 중앙 투명
	g.set_color(1, Color(0.6, 0.0, 0.0, 0.5))   # 가장자리 핏빛
	grad.gradient = g
	_blood_vignette = TextureRect.new()
	_blood_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blood_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blood_vignette.z_index = 80
	_blood_vignette.visible = false
	_blood_vignette.texture = grad
	_blood_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_blood_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_blood_vignette)


# === 게임 컨텍스트 ===

func _setup_game_context() -> void:
	game_ctx = GameContext.new()
	game_ctx.gold_manager = resource_bar.gold_manager
	game_ctx.ap_manager = resource_bar.ap_manager
	game_ctx.draw_cards = _draw_extra_cards
	game_ctx.discard_cards = _discard_cards_with_selection
	game_ctx.exile_cards = _exile_cards_from_hand
	game_ctx.request_card_removal = _on_request_card_removal_from_effect
	# 파이프 메커니즘 (단련/조작/인접)
	game_ctx.peek_pipe_front = _peek_pipe_front
	game_ctx.reorder_pipe_to_front = _reorder_pipe_to_front
	game_ctx.rewind_pipe = _rewind_pipe
	game_ctx.player_hp_changed.connect(_on_player_hp_changed)
	game_ctx.player_block_changed.connect(_on_player_block_changed)
	game_ctx.boss_hp_changed.connect(_on_boss_hp_changed)
	game_ctx.boss_block_changed.connect(_on_boss_block_changed)
	# 신규 디버프·상태 가시화
	game_ctx.draw_lock_changed.connect(_on_draw_lock_changed)
	game_ctx.vulnerability_changed.connect(_on_vulnerability_changed)
	game_ctx.blood_scent_changed.connect(_on_blood_scent_changed)
	game_ctx.boss_attack_buffed.connect(_on_boss_attack_buffed)
	_on_player_hp_changed(game_ctx.player_hp, game_ctx.player_max_hp)
	_on_player_block_changed(game_ctx.player_block)
	_on_boss_hp_changed(game_ctx.boss_hp, game_ctx.boss_max_hp)
	_on_boss_block_changed(game_ctx.boss_block)

	# 전사 전용 — 투기 발산 시스템
	rage_system = WarriorRageSystem.new(game_ctx)
	game_ctx.rage_system = rage_system  # 효과가 투기 접근하기 위함
	rage_system.rage_changed.connect(_on_rage_changed)
	_create_rage_orbs(GameBalance.RAGE_MAX_STACKS)
	rage_button.pressed.connect(_on_rage_button_pressed)
	_on_rage_changed(rage_system.stacks, GameBalance.RAGE_MAX_STACKS)

	# 라운드 마켓
	market_panel.setup(resource_bar.ap_manager, resource_bar.gold_manager)
	market_panel.card_purchased.connect(_on_market_card_purchased)
	market_panel.set_player_turn(false)

	# 보스 페이즈 시스템 (HP/라운드 트리거 → 마켓 티어 매칭)
	phase_system = BossPhaseSystem.new(game_ctx)
	phase_system.phase_changed.connect(_on_phase_changed)
	_apply_phase_label(phase_system.current_phase)

	# HP 바 생성 (레이블 아래에 삽입)
	_player_hp_fill = _create_hp_bar(hp_label)
	_boss_hp_fill   = _create_hp_bar(boss_hp_label)

	# 카드 호버 프리뷰 — game_ctx + 앵커 라벨 주입
	card_hover.setup(self, CardScene, game_ctx, boss_hp_label, block_label, hp_label)

	# 보스 덱 시스템 (에이언즈 엔드 방식 — 티어 블록 FIFO, 파워 카운트다운)
	boss_deck_system = BossDeckSystem.new(game_ctx)
	game_ctx.boss_deck_system = boss_deck_system   # 보스 효과(야수의 외침)가 접근하기 위함
	boss_deck_system.deck_changed.connect(_on_boss_deck_changed)
	boss_deck_system.power_zone_updated.connect(_on_boss_power_zone_updated)
	boss_deck_system.card_discarded.connect(_on_boss_card_discarded)
	boss_deck_system.setup(BUGBEAR_PHASE1, BUGBEAR_PHASE2, BUGBEAR_PHASE3)
	# 보스 카드 연출 프리젠터에 덱 시스템 연결 (페이즈 뱃지/스트립 표시용)
	if boss_presenter:
		boss_presenter.set_deck_system(boss_deck_system)
	_on_boss_deck_changed(boss_deck_system.get_remaining_count())
	_on_boss_power_zone_updated([])


func _on_player_hp_changed(current: int, max_hp: int) -> void:
	hp_label.text = "❤ %d / %d" % [current, max_hp]
	_update_hp_bar(_player_hp_fill, current, max_hp)
	if _prev_player_hp > 0 and current < _prev_player_hp:
		var dmg := _prev_player_hp - current
		DamagePopup.spawn(self, hp_label.get_global_rect().get_center() - global_position, dmg, false)
		# 취약 강화 피격이면 강조 텍스트
		if game_ctx and game_ctx.last_hit_vulnerable:
			_spawn_floating_text("🩸 취약! ×1.5", Color(1.0, 0.4, 0.5, 1), hp_label)
			game_ctx.last_hit_vulnerable = false
			combat_fx.shake_screen(10.0, 0.32)   # 더 큰 흔들림
		else:
			combat_fx.shake_screen(7.0, 0.28)
		AudioManager.play_sfx("combat.hit_player", 0.0, 0.05)
		combat_fx.flash_recoil(player_face_texture, -22.0)
		combat_fx.hit_stop()
	elif _prev_player_hp >= 0 and current > _prev_player_hp:
		var heal := current - _prev_player_hp
		DamagePopup.spawn(self, hp_label.get_global_rect().get_center() - global_position, heal, true)
		AudioManager.play_sfx("combat.heal")
	_prev_player_hp = current
	if current <= 0 and not game_over:
		_trigger_game_over(false)

func _on_player_block_changed(block: int) -> void:
	block_label.text = "🛡 %d" % block
	block_label.visible = block > 0

func _on_boss_hp_changed(current: int, max_hp: int) -> void:
	boss_hp_label.text = "❤ %d / %d" % [current, max_hp]
	_update_hp_bar(_boss_hp_fill, current, max_hp)
	if _prev_boss_hp > 0 and current < _prev_boss_hp:
		var dmg := _prev_boss_hp - current
		DamagePopup.spawn(self, boss_hp_label.get_global_rect().get_center() - global_position, dmg, false)
		AudioManager.play_sfx("combat.hit_boss", 0.0, 0.05)
		combat_fx.flash_recoil(boss_face_texture, 22.0)
		combat_fx.hit_stop()
	_prev_boss_hp = current
	if phase_system:
		phase_system.check_hp_trigger()
	_update_blood_vignette()   # 피 냄새 — HP 50% 임계 진입/이탈 반영
	if current <= 0 and not game_over:
		_trigger_game_over(true)

func _on_boss_block_changed(block: int) -> void:
	boss_block_label.text = "🛡 %d" % block
	boss_block_label.visible = block > 0


# === 드롭 존 설정 ===

func _setup_drop_zones() -> void:
	play_drop_zone.accept_filter = _can_accept_card
	timeline_pipe_panel.accept_filter = _can_accept_card
	active_slot_1.accept_filter = _can_accept_card
	active_slot_2.accept_filter = _can_accept_card

	play_drop_zone.card_dropped.connect(_on_play_zone_dropped)
	timeline_pipe_panel.card_dropped.connect(_on_pipe_dropped)
	active_slot_1.card_dropped.connect(_on_active_slot_1_dropped)
	active_slot_2.card_dropped.connect(_on_active_slot_2_dropped)


func _can_accept_card(card: Control, zone_type: DropZone.ZoneType) -> bool:
	# 손패에 있는 카드만 허용
	if card not in hand_cards:
		return false
	var is_module: bool = card.data.card_type == CardData.CardType.MODULE
	match zone_type:
		DropZone.ZoneType.PLAY:
			# 모듈은 사용 불가 (장착 전용)
			return not is_module
		DropZone.ZoneType.DISCARD:
			# 모듈은 파이프로 버릴 수 없음 (장착 전용)
			return not is_module
		DropZone.ZoneType.ACTIVE:
			return is_module
	return false


func _on_play_zone_dropped(card: Control) -> void:
	_play_card(card)


func _on_pipe_dropped(card: Control) -> void:
	# 손패 → 파이프 맨 뒤 (효과 없이 버리기)
	_send_to_pipe_back(card)


func _on_active_slot_1_dropped(card: Control) -> void:
	_equip_module(card, 0)


func _on_active_slot_2_dropped(card: Control) -> void:
	_equip_module(card, 1)


func _equip_module(card: Control, slot_index: int) -> void:
	var slot: PanelContainer = active_slot_1 if slot_index == 0 else active_slot_2
	if active_cards[slot_index] != null:
		var old := active_cards[slot_index]
		old.reparent(hand_belt)
		hand_cards.append(old)
		_update_hand_display()
	active_cards[slot_index] = card
	hand_cards.erase(card)
	card.reparent(slot)
	card.position = Vector2.ZERO
	_update_hand_display()


# === 덱 초기화 ===

func _make_card(cdata: CardData, face_up: bool = true) -> Control:
	var c: Control = CardScene.instantiate()
	c.data = cdata.duplicate()
	c.is_face_up = face_up
	if c.has_signal("hover_changed") and card_hover:
		c.hover_changed.connect(card_hover.on_card_hover_changed)
	return c


func _init_starter_deck() -> void:
	_clear_cards()
	# 스타터 구성으로 카드 생성 후 파이프를 1회만 셔플 → 매 판 첫 손패가 달라져 고착화 방지.
	# (게임 중에는 섞지 않음 — 파이프의 '예측 가능성' 컨셉은 유지)
	var starter: Array = STARTER_DECK.duplicate()
	starter.shuffle()
	for card_data: CardData in starter:
		var card: Control = _make_card(card_data, true)
		queue_card_holder.add_child(card)
		queue_cards.append(card)
	_rebuild_pipe_ui()
	_equip_warrior_modules()
	_start_round()


func _equip_warrior_modules() -> void:
	# 반격 태세를 액티브 슬롯 1에 기본 장착 (파이프/손패와 별개)
	var card: Control = _make_card(MODULE_COUNTER_STANCE, true)
	active_slot_1.add_child(card)
	card.position = Vector2.ZERO
	active_cards[0] = card
	card.set_active(false)


# === 손패 드로우 ===

func _draw_hand() -> void:
	# 파이프 앞에서 DRAW_COUNT장 꺼내 손패로. 드로우 봉인 N이면 -N장.
	var lock: int = game_ctx.consume_draw_lock() if game_ctx else 0
	var target: int = maxi(DRAW_COUNT - lock, 0)
	var count := mini(target, queue_cards.size())
	for i in count:
		var card: Control = queue_cards.pop_front()
		card.reparent(hand_belt)
		card.set_active(true)
		hand_cards.append(card)
	if count > 0:
		AudioManager.play_sfx("card.draw", 0.0, 0.05)
	# 봉인으로 인해 덜 드로우한 경우 배너 안내
	if lock > 0 and phase_banner:
		var lock_msgs: Array[String] = ["🔒 드로우 봉인 발동", "%d장만 드로우 (–%d)" % [count, lock]]
		phase_banner.show_sequence(lock_msgs)
		await phase_banner.banner_finished
	_update_hand_display()
	_rebuild_pipe_ui()


func _draw_extra_cards(count: int) -> void:
	# 효과에 의한 추가 드로우
	var actual := mini(count, queue_cards.size())
	for i in actual:
		var card: Control = queue_cards.pop_front()
		card.reparent(hand_belt)
		card.set_active(true)
		hand_cards.append(card)
	_update_hand_display()
	_rebuild_pipe_ui()


func _start_player_turn() -> void:
	end_turn_button.disabled = false
	_draw_hand()
	_maybe_show_tutorial()


# 첫 플레이(라운드 1) 최초 플레이어 턴에 스포트라이트 튜토리얼 표시
func _maybe_show_tutorial() -> void:
	if _tutorial_shown or current_round != 1:
		return
	if _has_seen_tutorial():
		return
	_tutorial_shown = true
	_mark_tutorial_seen()
	tutorial.show_tutorial(_build_tutorial_steps())


# 상단 튜토리얼 버튼 → 언제든 다시 보기
func _replay_tutorial() -> void:
	if tutorial:
		tutorial.show_tutorial(_build_tutorial_steps())


func _build_tutorial_steps() -> Array:
	return [
		{"target": boss_face, "text": "💀 [b]버그베어[/b](보스)입니다. HP를 [b]0으로[/b] 만들면 승리! 내 HP가 0이 되면 패배예요."},
		{"target": boss_next_card_container, "text": "보스의 [b]다음 행동[/b]이 미리 공개됩니다. 뭐가 올지 보고 대비하세요."},
		{"target": hand_belt, "text": "🃏 [b]손패[/b]입니다. 카드를 [b]드래그[/b]해서 사용해요. (AP를 소모)"},
		{"target": timeline_pipe_panel, "text": "📜 [b]타임라인 파이프[/b] — 덱을 [b]섞지 않아요.[/b] 다음에 올 카드 순서가 다 보입니다. 카드를 여기로 끌면 그냥 버려요."},
		{"target": resource_bar, "text": "⚡ [b]AP 3[/b]으로 카드를 씁니다. [b]공격할 때마다[/b] 🔥[b]투기 +1[/b] (남은 AP도 투기로), 7이 되면 [b]투기 발산[/b]!"},
		{"target": market_button, "text": "🛒 [b]상점[/b]에서 골드로 카드를 삽니다. 골드는 [b]턴이 끝나면 사라지니[/b] 그 턴에 쓰세요!"},
	]


func _has_seen_tutorial() -> bool:
	return FileAccess.file_exists("user://tutorial_seen")


func _mark_tutorial_seen() -> void:
	var f := FileAccess.open("user://tutorial_seen", FileAccess.WRITE)
	if f:
		f.store_string("1")
		f.close()


# === 파이프로 보내기 ===

func _send_to_pipe_back(card: Control) -> void:
	hand_cards.erase(card)
	card.set_active(false)
	# 단련 — 파이프 맨 뒤로 돌아갈 때마다 +1 (한 바퀴 카운트)
	if "temper" in card:
		card.temper += 1
	card.reparent(queue_card_holder)
	queue_cards.append(card)
	_update_hand_display()
	_rebuild_pipe_ui()


# === 파이프 메커니즘 (단련/조작/인접) ===

# 파이프 앞 count장의 CardData 미리보기 (인접 판정용)
func _peek_pipe_front(count: int) -> Array:
	var result: Array = []
	for i in mini(count, queue_cards.size()):
		var c: Control = queue_cards[i]
		result.append(c.data if c else null)
	return result


# 파이프 맨 뒤 count장을 맨 앞으로 이동 (시간 역행 — 방금 버린 카드 회수)
func _rewind_pipe(count: int) -> void:
	var n: int = mini(count, queue_cards.size())
	if n <= 0:
		return
	# 맨 뒤 n장을 떼어 (순서 유지) 맨 앞에 삽입
	var tail: Array[Control] = []
	for i in range(queue_cards.size() - n, queue_cards.size()):
		tail.append(queue_cards[i])
	queue_cards = queue_cards.slice(0, queue_cards.size() - n)
	for i in range(tail.size() - 1, -1, -1):
		queue_cards.push_front(tail[i])
	AudioManager.play_sfx("card.draw", 0.0, 0.05)
	_rebuild_pipe_ui()


# 파이프 카드 1장을 선택해 맨 앞으로 (운명 재배치 — 핀포인트)
func _reorder_pipe_to_front() -> void:
	if queue_cards.is_empty():
		return
	# 파이프 카드들로 선택 UI 표시 (end_turn_overlay 재사용, 1장 선택)
	is_discarding_from_effect = true
	end_turn_overlay.show_overlay_select(queue_cards.duplicate(), 1, "맨 앞으로 당길")
	var chosen: Array[Control] = await end_turn_overlay.order_confirmed
	is_discarding_from_effect = false
	if chosen.is_empty():
		return
	var card: Control = chosen[0]
	queue_cards.erase(card)
	queue_cards.push_front(card)
	AudioManager.play_sfx("card.draw", 0.0, 0.05)
	_rebuild_pipe_ui()


# === 손패 UI 갱신 ===

func _update_hand_display() -> void:
	if hand_cards.is_empty():
		return
	var spacing := hand_cards[0].custom_minimum_size.x + 8
	for i in hand_cards.size():
		var card: Control = hand_cards[i]
		var tween := create_tween()
		tween.tween_property(card, "position", Vector2(i * spacing, 0), 0.18)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


# === 파이프 UI 재빌드 ===

func _rebuild_pipe_ui() -> void:
	# 기존 UI 행 제거 + 떠있던 카드 프리뷰 정리
	if card_hover:
		card_hover.clear_pipe_card_preview()
	for child in pipe_queue.get_children():
		child.queue_free()

	# 큐 카드마다 행 생성
	for i in queue_cards.size():
		var card: Control = queue_cards[i]
		var row := _create_pipe_row(i + 1, card)
		pipe_queue.add_child(row)


func _create_pipe_row(index: int, card: Control) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	# 순서 번호
	var num_label := Label.new()
	num_label.text = str(index)
	num_label.custom_minimum_size = Vector2(18, 0)
	num_label.add_theme_font_size_override("font_size", 16)
	num_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	num_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(num_label)

	# 미니 카드 패널
	var mini_panel := PanelContainer.new()
	mini_panel.custom_minimum_size = Vector2(0, 28)
	mini_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 호버 활성화 — 효과 프리뷰 + 풀사이즈 카드 프리뷰 + 툴팁
	mini_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if card.data:
		mini_panel.tooltip_text = "%s\n비용: %d AP\n%s" % [
			card.data.card_name,
			card.data.cost,
			card.data.get_description_text(),
		]
	if card_hover:
		mini_panel.mouse_entered.connect(card_hover.on_pipe_row_hover.bind(card, mini_panel, true))
		mini_panel.mouse_exited.connect(card_hover.on_pipe_row_hover.bind(card, mini_panel, false))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.20, 0.18, 0.9)
	style.border_color = Color(0.55, 0.45, 0.3, 1)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	mini_panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)

	var cost_lbl := Label.new()
	cost_lbl.text = "[%d]" % card.data.cost
	cost_lbl.add_theme_font_size_override("font_size", 15)
	cost_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 0.4, 1))
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(cost_lbl)

	var name_lbl := Label.new()
	name_lbl.text = card.data.card_name
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_lbl)

	# 단련 뱃지 — 파이프를 돈 바퀴 수 (TemperedDamageEffect 카드만 의미 있음)
	if "temper" in card and card.temper > 0:
		var temper_lbl := Label.new()
		temper_lbl.text = "🔨%d" % card.temper
		temper_lbl.add_theme_font_size_override("font_size", 14)
		temper_lbl.add_theme_color_override("font_color", Color(0.95, 0.7, 0.35, 1))
		temper_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		temper_lbl.tooltip_text = "단련 %d회 — 파이프를 돈 횟수" % card.temper
		hbox.add_child(temper_lbl)

	mini_panel.add_child(hbox)
	row.add_child(mini_panel)
	return row


# === 버리기 선택 (이펙트용) ===

func _discard_cards_with_selection(count: int) -> void:
	if hand_cards.is_empty():
		return
	is_discarding_from_effect = true
	var actual := mini(count, hand_cards.size())
	end_turn_overlay.show_overlay_select(hand_cards.duplicate(), actual)
	var ordered: Array[Control] = await end_turn_overlay.order_confirmed
	for card in ordered:
		_send_to_pipe_back(card)
	is_discarding_from_effect = false


# === 카드 소멸 (영구, 파이프로 복귀 안 함) ===

func _exile_cards_from_hand(count: int) -> void:
	if hand_cards.is_empty():
		return
	is_discarding_from_effect = true
	var actual := mini(count, hand_cards.size())
	end_turn_overlay.show_overlay_select(hand_cards.duplicate(), actual, "소멸시킬")
	var selected: Array[Control] = await end_turn_overlay.order_confirmed
	for card in selected:
		hand_cards.erase(card)
		card.queue_free()
	is_discarding_from_effect = false
	_update_hand_display()
	_rebuild_pipe_ui()


# === 카드 사용 ===

func _play_card(card: Control) -> void:
	if not card.data:
		return
	var cost: int = card.data.cost
	if not resource_bar.ap_manager.has(cost):
		return
	resource_bar.ap_manager.spend(cost)
	AudioManager.play_sfx("card.play", 0.0, 0.08)
	# 콤보 트래커 — ATTACK 카드 사용 시 카운트 (연환격 등에서 참조)
	# + 투기 리워크: 공격할 때마다 투기 +1 (휘두를수록 달아오른다)
	if card.data.card_type == CardData.CardType.ATTACK:
		game_ctx.attacks_this_turn += 1
		if rage_system:
			rage_system.add(1)
	# 카드 사용 임팩트 이펙트 (효과 종류 기반 — 슬래시/방어 쉬머)
	_play_card_impact(card)
	# 효과 실행 — 파이프로 보내기 *전*에 실행해야 인접(파이프 맨 앞) 판정이 정확
	# acting_card 세팅 → 단련 효과가 이 카드의 temper를 읽음
	game_ctx.acting_card = card
	for effect in card.data.effects:
		effect.execute(game_ctx)
	game_ctx.acting_card = null
	_log("🗡 %s" % card.data.card_name, "🗡 %s — %s" % [card.data.card_name, card.data.get_description_text()])
	# 소비(consume) 카드는 파이프로 안 돌아가고 영구 소멸
	if card.data.consume:
		hand_cards.erase(card)
		_update_hand_display()
		if is_instance_valid(card):
			card.queue_free()
	else:
		_send_to_pipe_back(card)


# === 라운드/턴 시스템 ===

func _start_round() -> void:
	_build_turn_order()
	_update_round_label()
	_update_turn_order_ui()
	_log("━━ 라운드 %d ━━" % current_round)
	current_turn = 0
	if market_panel:
		market_panel.refresh_slots()
	_advance_turn()


func _build_turn_order() -> void:
	turn_order.clear()
	# 고정 교대 순서: 플레이어 → 보스 → 플레이어 → 보스
	turn_order = ["player", "boss", "player", "boss"]


func _advance_turn() -> void:
	if game_over:
		return
	current_turn += 1
	if current_turn > TURNS_PER_ROUND:
		# 라운드 종료 — 방어도 리셋
		game_ctx.reset_block()
		current_round += 1
		_start_round()
		return
	_update_turn_order_ui()
	var who: String = turn_order[current_turn - 1]
	if who == "player":
		_begin_player_turn()
	else:
		_begin_boss_turn()


func _begin_player_turn() -> void:
	resource_bar.ap_manager.set_to(3)
	game_ctx.attacks_this_turn = 0   # 연환격 등 콤보 카드용 트래커 초기화
	_set_turn_focus(true)
	_update_turn_indicator(true, "")
	# 보스 머리 위 인텐트 갱신 (다음 행동 예고)
	if boss_deck_system:
		_update_boss_intent(boss_deck_system.peek_next(), true)

	# 누적된 페이즈 보상 (보스 턴 도중 발생한 것) 처리
	await _drain_pending_rewards()

	# 장착된 모듈의 플레이어 턴 시작 훅 실행
	for card in active_cards:
		if card and card.data and card.data.module_ability:
			card.data.module_ability.on_player_turn_start(game_ctx)

	var messages: Array[String] = ["플레이어 차례입니다"]
	phase_banner.show_sequence(messages)
	await phase_banner.banner_finished
	if market_panel:
		market_panel.set_player_turn(true)
	_start_player_turn()


func _begin_boss_turn() -> void:
	if market_panel:
		market_panel.set_player_turn(false)
	_set_turn_focus(false)

	# 1. 파워 카운트다운 틱 (0이 된 파워 카드 즉시 발동)
	var triggered: Array[BossCardData] = boss_deck_system.tick_powers()

	# 2. 다음 카드 드로우
	var drawn: BossCardData = boss_deck_system.draw_next()

	# 3. 턴 인디케이터 / 인텐트 갱신
	var indicator_hint := drawn.card_name if drawn else ""
	_update_turn_indicator(false, indicator_hint)
	_update_boss_intent(drawn, false)

	# 4. 발동된 파워 카드 연출 (효과는 tick_powers에서 이미 적용됨)
	for card in triggered:
		await boss_presenter.present(card, BossActionPresenter.Kind.TRIGGER)
		_log("💥 파워 발동: %s" % card.card_name, "💥 파워 발동: %s — %s" % [card.card_name, card.description])

	# 5. 드로우 카드 연출 + 실행 동기화 (resolve_cb가 임팩트 순간 효과 적용)
	if drawn:
		if game_ctx.negate_next_boss_action:
			game_ctx.negate_next_boss_action = false
			await boss_presenter.present(drawn, BossActionPresenter.Kind.NEGATED,
				func() -> void: boss_deck_system.discard_without_play(drawn))
			_log("🛡 보스 무효화: %s" % drawn.card_name)
		else:
			var kind: int = BossActionPresenter.Kind.POWER if drawn.card_type == BossCardData.BossCardType.POWER else BossActionPresenter.Kind.ATTACK
			await boss_presenter.present(drawn, kind,
				func() -> void: boss_deck_system.play_card(drawn))
			_log("💀 보스: %s" % drawn.card_name, "💀 보스: %s — %s" % [drawn.card_name, drawn.description])

	# 6. 장착된 모듈의 보스 턴 종료 훅 실행
	for card in active_cards:
		if card and card.data and card.data.module_ability:
			card.data.module_ability.on_boss_turn_end(game_ctx)
	_advance_turn()


# === 보스 덱 UI 핸들러 ===

func _on_boss_deck_changed(_remaining: int) -> void:
	# 페이즈별 칩 갱신 (P1·P2·P3 장수 + 페이즈 색 + 툴팁)
	_update_phase_deck_chips()
	# 다음 카드 미리보기 갱신
	_refresh_boss_next_card_preview()


# === 보스 덱 카운트 — 3-페이즈 칩 행 ===
var _phase_chip_panels: Array = []   # PanelContainer ×3 (P1/P2/P3)
var _phase_chip_labels: Array = []   # Label ×3

func _setup_phase_deck_chips() -> void:
	if boss_deck_count_label == null:
		return
	var parent_box: Node = boss_deck_count_label.get_parent()
	if parent_box == null:
		return
	var insert_index: int = boss_deck_count_label.get_index()
	# 원본 라벨은 숨김 (씬 구조 보존 — 다른 곳에서 참조해도 안전)
	boss_deck_count_label.visible = false

	var chip_row := HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 6)
	parent_box.add_child(chip_row)
	parent_box.move_child(chip_row, insert_index)

	_phase_chip_panels.clear()
	_phase_chip_labels.clear()
	for phase in [1, 2, 3]:
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(5)
		style.set_border_width_all(1)
		style.content_margin_left = 9
		style.content_margin_right = 9
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		chip.add_theme_stylebox_override("panel", style)
		chip_row.add_child(chip)

		var lbl := Label.new()
		lbl.text = "P%d·0" % phase
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lbl.add_theme_constant_override("outline_size", 3)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(lbl)

		_phase_chip_panels.append(chip)
		_phase_chip_labels.append(lbl)


func _update_phase_deck_chips() -> void:
	if _phase_chip_panels.is_empty() or boss_deck_system == null:
		return
	var counts: Dictionary = boss_deck_system.get_remaining_counts_by_phase()
	var names_by_phase: Dictionary = boss_deck_system.get_remaining_names_by_phase()
	for i in 3:
		var phase: int = i + 1
		var n: int = int(counts.get(phase, 0))
		var pc: Color = PHASE_COLORS.get(phase, Color.WHITE)
		var chip: PanelContainer = _phase_chip_panels[i]
		var lbl: Label = _phase_chip_labels[i]

		lbl.text = "P%d·%d" % [phase, n]
		var style: StyleBoxFlat = chip.get_theme_stylebox("panel")
		if n > 0:
			style.bg_color = Color(pc.r * 0.25, pc.g * 0.25, pc.b * 0.25, 0.85)
			style.border_color = pc
			lbl.add_theme_color_override("font_color", pc)
			chip.modulate = Color(1, 1, 1, 1)
		else:
			# 소진된 페이즈 — 어둡게 디밍
			style.bg_color = Color(0.10, 0.09, 0.08, 0.55)
			style.border_color = Color(0.30, 0.27, 0.22, 0.7)
			lbl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42, 1))
			chip.modulate = Color(1, 1, 1, 0.6)

		# 툴팁 — 해당 페이즈 남은 카드 이름
		var names: Array = names_by_phase.get(phase, [])
		if names.is_empty():
			chip.tooltip_text = "Phase %d — 소진됨" % phase
		else:
			var lines: PackedStringArray = ["Phase %d — %d장 남음" % [phase, names.size()]]
			for card_name in names:
				lines.append("· " + card_name)
			chip.tooltip_text = "\n".join(lines)


# 다음 예고 패널 갱신 — 텍스트 라벨로 컴팩트 표시 + 호버 시 풀사이즈 카드 프리뷰
const _NEXT_CARD_SIZE := Vector2(175, 245)

func _refresh_boss_next_card_preview() -> void:
	_clear_boss_card_container(boss_next_card_container)
	var next_card := boss_deck_system.peek_next()
	if next_card == null:
		# 덱 소진 → 재편성 예정 안내
		var lbl := Label.new()
		lbl.text = "재편성"
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		boss_next_card_container.add_child(lbl)
		return
	# 다음 예고 — 큰 카드 모양으로 직접 표시 (반투명으로 "예고" 느낌)
	var display := BossCardDisplay.new()
	boss_next_card_container.add_child(display)
	var next_phase: int = boss_deck_system.get_phase_of(next_card) if boss_deck_system else 0
	display.setup(next_card, next_card.countdown, _NEXT_CARD_SIZE, next_phase)
	display.modulate = Color(1, 1, 1, 0.85)

func _on_boss_card_discarded(_card: BossCardData) -> void:
	boss_discard_label.text = "🗑 %d" % boss_deck_system.get_discard_count()

func _on_boss_power_zone_updated(active_powers: Array) -> void:
	_clear_boss_card_preview()
	_clear_boss_card_container(boss_power_zone)
	if active_powers.is_empty():
		_show_boss_empty_label(boss_power_zone)
	else:
		for entry in active_powers:
			var lbl := Label.new()
			lbl.text = "%s %s (%d턴)" % [entry.card.intent_icon, entry.card.card_name, entry.tokens]
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			lbl.clip_text = false
			lbl.tooltip_text = "%s\n%s" % [entry.card.card_name, entry.card.description]
			# 카운트 1턴 남으면 임박 경고 — 빨간색 + 깜빡임 / 그 외 오렌지
			if entry.tokens <= 1:
				lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.25, 1))
				var blink := lbl.create_tween().set_loops()
				blink.tween_property(lbl, "modulate:a", 0.4, 0.45).set_trans(Tween.TRANS_SINE)
				blink.tween_property(lbl, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
			else:
				lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.25, 1))
			# 호버 시 풀사이즈 보스 카드 프리뷰 + 카운트다운 표시
			lbl.mouse_filter = Control.MOUSE_FILTER_STOP
			lbl.mouse_entered.connect(_on_boss_card_label_hover.bind(entry.card, lbl, entry.tokens, true))
			lbl.mouse_exited.connect(_on_boss_card_label_hover.bind(entry.card, lbl, entry.tokens, false))
			boss_power_zone.add_child(lbl)


# 컨테이너 자식을 모두 제거
func _clear_boss_card_container(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()


# 카드 없음 표시 ("—" 라벨)
func _show_boss_empty_label(container: Control) -> void:
	var lbl := Label.new()
	lbl.text = "—"
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(lbl)


# === 턴 오더 UI ===

func _update_round_label() -> void:
	round_label.text = "R%d" % current_round


const _TOKEN_SIZE := 34
const _TOKEN_PLAYER := Color(0.30, 0.52, 0.92, 1)   # 플레이어 청색
const _TOKEN_BOSS   := Color(0.82, 0.28, 0.26, 1)   # 보스 적색

func _update_turn_order_ui() -> void:
	if turn_slot_labels.is_empty():
		for i in range(TURNS_PER_ROUND):
			var slot := PanelContainer.new()
			slot.custom_minimum_size = Vector2(_TOKEN_SIZE, _TOKEN_SIZE)
			slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var lbl := Label.new()
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 16)
			lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
			lbl.add_theme_constant_override("outline_size", 3)
			slot.add_child(lbl)
			turn_slots_container.add_child(slot)
			turn_slot_labels.append(lbl)

	# 원형 토큰 뱃지 — 플레이어=청 / 보스=적, 현재 턴 강조(금테+확대), 지난 턴 디밍
	for i in range(TURNS_PER_ROUND):
		var lbl := turn_slot_labels[i]
		var slot: PanelContainer = lbl.get_parent()
		var turn_num := i + 1
		var who: String = turn_order[i]
		var base: Color = _TOKEN_PLAYER if who == "player" else _TOKEN_BOSS

		lbl.text = "P" if who == "player" else "B"
		lbl.tooltip_text = "T%d — %s" % [turn_num, "플레이어 턴" if who == "player" else "보스 턴"]

		var token := StyleBoxFlat.new()
		token.set_corner_radius_all(int(_TOKEN_SIZE / 2.0))   # 원형
		token.content_margin_left = 2
		token.content_margin_right = 2
		if turn_num == current_turn:
			# 현재 턴 — 밝게 + 금색 테두리 + 확대
			token.bg_color = base
			token.set_border_width_all(3)
			token.border_color = DarkFantasyTheme.GOLD_BRIGHT
			slot.scale = Vector2(1.18, 1.18)
			slot.pivot_offset = Vector2(_TOKEN_SIZE, _TOKEN_SIZE) / 2.0
			slot.modulate = Color(1, 1, 1, 1)
		elif turn_num < current_turn:
			# 지난 턴 — 어둡게
			token.bg_color = base.darkened(0.5)
			token.set_border_width_all(1)
			token.border_color = base.darkened(0.3)
			slot.scale = Vector2.ONE
			slot.modulate = Color(1, 1, 1, 0.4)
		else:
			# 다음 턴 — 중간
			token.bg_color = base.darkened(0.25)
			token.set_border_width_all(1)
			token.border_color = base
			slot.scale = Vector2.ONE
			slot.modulate = Color(1, 1, 1, 0.85)
		slot.add_theme_stylebox_override("panel", token)


# === 턴 종료 ===

func _on_end_turn_pressed() -> void:
	if hand_cards.is_empty():
		_finish_turn()
		return
	end_turn_button.disabled = true
	end_turn_overlay.show_overlay(hand_cards.duplicate())


func _on_end_turn_order_confirmed(ordered_cards: Array[Control]) -> void:
	if is_discarding_from_effect:
		return
	for card in ordered_cards:
		_send_to_pipe_back(card)
	end_turn_button.disabled = false
	_finish_turn()


func _on_end_turn_cancelled() -> void:
	end_turn_button.disabled = false


func _finish_turn() -> void:
	AudioManager.play_sfx("ui.turn_end")
	# 남은 AP를 투기 스택으로 치환 (플레이어 턴 종료 시)
	rage_system.add(resource_bar.ap_manager.current)
	# 골드는 턴 종료 시 증발, 방어도는 라운드 종료까지 유지
	resource_bar.gold_manager.reset()
	end_turn_button.disabled = true
	if market_panel:
		market_panel.set_player_turn(false)
	_advance_turn()


# === 정리 ===

func _clear_cards() -> void:
	for card in hand_cards:
		card.queue_free()
	for card in queue_cards:
		card.queue_free()
	hand_cards.clear()
	queue_cards.clear()
	_rebuild_pipe_ui()


# === 투기 발산 UI (전사 전용) ===

func _create_rage_orbs(count: int) -> void:
	for child in rage_orbs.get_children():
		child.queue_free()
	for i in range(count):
		var orb := ColorRect.new()
		orb.custom_minimum_size = Vector2(RAGE_ORB_SIZE, RAGE_ORB_SIZE)
		orb.color = RAGE_EMPTY_COLOR
		rage_orbs.add_child(orb)


func _on_rage_changed(stacks: int, max_stacks: int) -> void:
	rage_label.text = "🔥 %d/%d" % [stacks, max_stacks]
	var orbs := rage_orbs.get_children()
	for i in range(orbs.size()):
		orbs[i].color = RAGE_COLOR if i < stacks else RAGE_EMPTY_COLOR
	rage_button.disabled = stacks < max_stacks


# === 게임 로그 시스템 ===

func _setup_game_log() -> void:
	# 상단바 상점 버튼 왼쪽에 [❓ 튜토리얼] [📜 기록] 순으로 배치
	if market_button and market_button.get_parent():
		var bar: Node = market_button.get_parent()

		var tut_btn := Button.new()
		tut_btn.text = "❓ 튜토리얼"
		tut_btn.custom_minimum_size = Vector2(120, 0)
		tut_btn.pressed.connect(_replay_tutorial)
		bar.add_child(tut_btn)
		bar.move_child(tut_btn, market_button.get_index())

		_log_button = Button.new()
		_log_button.text = "📜 기록"
		_log_button.custom_minimum_size = Vector2(110, 0)
		_log_button.pressed.connect(_toggle_log)
		bar.add_child(_log_button)
		bar.move_child(_log_button, market_button.get_index())
	else:
		_log_button = Button.new()
		_log_button.text = "📜 기록"
		_log_button.pressed.connect(_toggle_log)
	_build_log_window()
	_build_mini_log()


# A: 전체 로그 모달 (마켓 모달과 동일 패턴)
func _build_log_window() -> void:
	_log_layer = CanvasLayer.new()
	_log_layer.layer = 13
	add_child(_log_layer)

	_log_root = Control.new()
	_log_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_log_root.visible = false
	_log_layer.add_child(_log_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close_log())
	_log_root.add_child(dim)

	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.offset_left = -420
	frame.offset_right = 420
	frame.offset_top = -320
	frame.offset_bottom = 320
	_log_root.add_child(frame)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	frame.add_child(vb)

	var header := HBoxContainer.new()
	vb.add_child(header)
	var title := Label.new()
	title.text = "📜 전투 기록"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", DarkFantasyTheme.GOLD_BRIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "✕ 닫기"
	close_btn.pressed.connect(_close_log)
	header.add_child(close_btn)

	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(_log_scroll)

	_log_list_vbox = VBoxContainer.new()
	_log_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_list_vbox.add_theme_constant_override("separation", 3)
	_log_scroll.add_child(_log_list_vbox)


# B: 파이프 오른쪽 미니 로그 (최근 N줄 상시 표시)
func _build_mini_log() -> void:
	var zones: Node = timeline_pipe_panel.get_parent() if timeline_pipe_panel else null
	if zones == null:
		return
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_FILL
	panel.size_flags_stretch_ratio = 0.5   # 파이프 오른쪽 영역 축소
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vb)

	var title := Label.new()
	title.text = "📜 기록"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", DarkFantasyTheme.GOLD_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	_mini_log_label = Label.new()
	_mini_log_label.add_theme_font_size_override("font_size", 13)
	_mini_log_label.add_theme_color_override("font_color", DarkFantasyTheme.TEXT_DIM)
	_mini_log_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_mini_log_label.clip_text = true
	_mini_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mini_log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_mini_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_mini_log_label)

	zones.add_child(panel)   # 파이프가 마지막 자식이므로 그 오른쪽에 배치됨


# 로그 1줄 추가 — full 생략 시 short와 동일. B(미니)는 short, A(모달)는 full 표시.
func _log(short: String, full: String = "") -> void:
	if full == "":
		full = short
	var prefix: String = "R%d · " % current_round
	_game_log.append({"short": prefix + short, "full": prefix + full})
	if _game_log.size() > _LOG_MAX:
		_game_log.pop_front()
	_update_mini_log()
	if _log_root and _log_root.visible:
		_refresh_log_panel()


func _update_mini_log() -> void:
	if _mini_log_label == null:
		return
	var start_i: int = maxi(0, _game_log.size() - _MINI_LOG_LINES)
	var lines: PackedStringArray = []
	for e in _game_log.slice(start_i):
		lines.append(e["short"])
	_mini_log_label.text = "\n".join(lines)


func _toggle_log() -> void:
	if _log_root == null:
		return
	if _log_root.visible:
		_close_log()
	else:
		_refresh_log_panel()
		_log_root.visible = true
		# 최신 로그가 보이도록 맨 아래로 스크롤
		await get_tree().process_frame
		if _log_scroll:
			_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)


func _close_log() -> void:
	if _log_root:
		_log_root.visible = false


func _refresh_log_panel() -> void:
	if _log_list_vbox == null:
		return
	for c in _log_list_vbox.get_children():
		c.queue_free()
	for e in _game_log:
		var lbl := Label.new()
		lbl.text = e["full"]
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", DarkFantasyTheme.TEXT)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_log_list_vbox.add_child(lbl)


# === 마켓 ===

func _on_market_card_purchased(card_data: CardData) -> void:
	# 구매한 카드는 파이프 맨 뒤에 추가됨
	var card: Control = _make_card(card_data, true)
	queue_card_holder.add_child(card)
	card.set_active(false)
	queue_cards.append(card)
	AudioManager.play_sfx("ui.market_buy")
	_log("🛒 구매: %s" % card_data.card_name)
	_rebuild_pipe_ui()


func _on_rage_button_pressed() -> void:
	# 플레이어 턴일 때만 발동 가능 (턴 종료 버튼이 활성 상태 == 플레이어 턴)
	if end_turn_button.disabled:
		return
	if not rage_system.can_consume():
		return
	# 투기 발산 — 화면 전체 분노 플래시 + 보스 슬래시 + 강한 셰이크
	if combat_fx:
		combat_fx.screen_flash(Color(1.0, 0.45, 0.1), 0.5, 0.55)
		combat_fx.shake_screen(11.0, 0.35)
	_spawn_slash_fx(boss_face_texture)
	AudioManager.play_sfx("rage.consume", 2.0, 0.05)
	rage_system.consume()
	_log("🔥 투기 발산! 보스 %d 피해 + 방어 %d" % [GameBalance.RAGE_BURST_DAMAGE, GameBalance.RAGE_BURST_BLOCK])


# === 보스 페이즈 ===

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	if market_panel:
		market_panel.set_phase(new_phase)
	_apply_phase_label(new_phase)
	AudioManager.play_sfx("boss.phase_change")
	# 페이즈별 BGM 크로스페이드
	match new_phase:
		2: AudioManager.crossfade_bgm(SfxLibrary.BGM_PHASE_2, 1.5)
		3: AudioManager.crossfade_bgm(SfxLibrary.BGM_PHASE_3, 1.5)
	_log("💢 페이즈 %d 진입!" % new_phase)
	_play_phase_transition_fx(new_phase)
	# 페이즈 전환 보상 — 카드 1장 영구 제거 기회 (큐잉, 안전 시점에 처리)
	var reward_lines: Array[String] = [
		"🌟 전사의 깨달음",
		"보스의 약점이 보인다 — 카드 1장을 영구 제거할 수 있다",
	]
	_pending_rewards.append(reward_lines)


func _apply_phase_label(phase: int) -> void:
	if not phase_label:
		return
	phase_label.text = "페이즈 %d" % phase
	var color: Color = PHASE_COLORS.get(phase, Color.WHITE)
	phase_label.add_theme_color_override("font_color", color)


# 페이즈별 타이틀 부제
const PHASE_SUBTITLES := {
	2: "버그베어가 분노한다",
	3: "최후의 발악이 시작된다",
}

# 페이즈 전환 시네마틱 — 화면 섬광 + 흔들림 + 보스 각성 + 컬러 타이틀
func _play_phase_transition_fx(phase: int) -> void:
	var color: Color = PHASE_COLORS.get(phase, Color(0.9, 0.4, 0.3, 1))
	if combat_fx:
		combat_fx.screen_flash(color, 0.5, 0.7)
		combat_fx.shake_screen(13.0, 0.45)
	# 보스 각성 — 스케일 펀치 + 페이즈 색 밝은 틴트 펄스
	if boss_face_texture:
		boss_face_texture.pivot_offset = boss_face_texture.size / 2.0
		var flash := color.lightened(0.4)
		flash = Color(flash.r * 1.4, flash.g * 1.4, flash.b * 1.4, 1)
		var roar := create_tween()
		roar.tween_property(boss_face_texture, "scale", Vector2(1.16, 1.16), 0.18).set_ease(Tween.EASE_OUT)
		roar.parallel().tween_property(boss_face_texture, "modulate", flash, 0.18)
		roar.tween_property(boss_face_texture, "scale", Vector2.ONE, 0.42)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		roar.parallel().tween_property(boss_face_texture, "modulate", Color.WHITE, 0.42)
	# 큰 컬러 타이틀
	if phase_banner:
		var sub: String = PHASE_SUBTITLES.get(phase, "보스가 각성한다")
		phase_banner.show_title("⚔  PHASE %d  ⚔" % phase, sub, color)


# === HP 바 ===

# 레이블 아래에 HP 바를 삽입, fill ColorRect 반환
# PanelContainer는 다중 자식을 지원 안 하므로 조부모 레벨에 삽입
func _create_hp_bar(label: Label) -> ColorRect:
	var insert_parent := label.get_parent()
	var insert_index  := label.get_index() + 1
	if insert_parent is PanelContainer:
		insert_index  = insert_parent.get_index() + 1
		insert_parent = insert_parent.get_parent()

	var container := Control.new()
	container.custom_minimum_size = Vector2(0, 9)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insert_parent.add_child(container)
	insert_parent.move_child(container, insert_index)

	# 배경
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.04, 0.04, 0.9)
	container.add_child(bg)

	# 채움 (anchor_right로 비율 표현)
	var fill := ColorRect.new()
	fill.anchor_left   = 0.0
	fill.anchor_right  = 1.0
	fill.anchor_top    = 0.0
	fill.anchor_bottom = 1.0
	fill.color = Color(0.15, 0.82, 0.2, 1)
	container.add_child(fill)

	return fill


func _update_hp_bar(fill: ColorRect, current: int, max_hp: int) -> void:
	if fill == null:
		return
	var ratio := clampf(float(current) / float(max_hp), 0.0, 1.0) if max_hp > 0 else 0.0
	fill.anchor_right = ratio
	if ratio > 0.6:
		fill.color = Color(0.15, 0.82, 0.2,  1)   # 초록
	elif ratio > 0.3:
		fill.color = Color(0.95, 0.78, 0.08, 1)   # 노랑
	else:
		fill.color = Color(0.95, 0.2,  0.1,  1)   # 빨강


# === 게임 종료 ===

func _trigger_game_over(is_win: bool) -> void:
	game_over = true
	# 모든 입력 차단
	end_turn_button.disabled = true
	if market_panel:
		market_panel.set_player_turn(false)
	# 결과 화면 표시 (배너가 재생 중이라면 잠깐 기다렸다가)
	if phase_banner and phase_banner.visible:
		await phase_banner.banner_finished
	game_result_screen.show_result(is_win)


# === 턴 인디케이터 + 컨텍스트 디밍 ===

func _update_turn_indicator(is_player: bool, _hint: String) -> void:
	# 턴 슬롯과 통합된 상단 바의 턴 상태 라벨
	var accent: Color = Color(0.45, 0.7, 1.0, 1) if is_player else Color(1.0, 0.4, 0.4, 1)
	if turn_indicator_label:
		turn_indicator_label.text = "🔵 내 턴" if is_player else "🔴 보스 턴"
		turn_indicator_label.add_theme_color_override("font_color", accent)


# === 마켓 토글 ===

func _toggle_market() -> void:
	if market_window.visible:
		_close_market()
	else:
		_open_market()


func _open_market() -> void:
	market_window.visible = true
	AudioManager.play_sfx("ui.button")


func _close_market() -> void:
	market_window.visible = false
	AudioManager.play_sfx("ui.button")


func _on_market_dim_input(event: InputEvent) -> void:
	# 어두운 배경 클릭 시 닫기
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_market()


func _set_turn_focus(is_player_turn: bool) -> void:
	# 컨텍스트 디밍: 보스 턴엔 손패/마켓을 흐리게, 내 턴엔 보스 영역을 살짝 흐리게
	var active_alpha := 1.0
	var inactive_alpha := 0.55
	if hand_belt:
		hand_belt.modulate.a = active_alpha if is_player_turn else inactive_alpha
	if market_panel:
		market_panel.modulate.a = active_alpha if is_player_turn else inactive_alpha


# === 신규 상태 가시화 핸들러 ===

func _on_draw_lock_changed(stacks: int) -> void:
	if _draw_lock_label == null:
		return
	if stacks <= 0:
		_draw_lock_label.visible = false
		return
	_draw_lock_label.text = "🔒 다음 턴 드로우 −%d" % stacks
	_draw_lock_label.visible = true
	# 손패 벨트 위쪽에 배치
	if hand_belt:
		var r := hand_belt.get_global_rect()
		_draw_lock_label.global_position = r.position + Vector2(0, -28)
	# 등장 강조
	_draw_lock_label.scale = Vector2(1.3, 1.3)
	_draw_lock_label.pivot_offset = _draw_lock_label.size / 2.0
	create_tween().tween_property(_draw_lock_label, "scale", Vector2.ONE, 0.25)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _on_vulnerability_changed(stacks: int) -> void:
	if _vuln_label == null:
		return
	if stacks <= 0:
		_vuln_label.visible = false
		return
	_vuln_label.text = "🩸 취약 %d" % stacks
	_vuln_label.visible = true
	# 플레이어 HP 라벨 옆 (위쪽)
	if hp_label:
		var r := hp_label.get_global_rect()
		_vuln_label.global_position = r.position + Vector2(0, -26)
	_vuln_label.scale = Vector2(1.3, 1.3)
	_vuln_label.pivot_offset = _vuln_label.size / 2.0
	create_tween().tween_property(_vuln_label, "scale", Vector2.ONE, 0.25)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _on_blood_scent_changed(active: bool) -> void:
	# 피 냄새 활성화 시 배너 + 비네팅 켜기 (실제 표시는 HP 조건과 함께 _update_blood_vignette)
	if active and phase_banner:
		var msgs: Array[String] = ["🐺 피 냄새!", "버그베어가 피를 쫓는다 — HP 50% 이하 시 공격 강화"]
		phase_banner.show_sequence(msgs)
	_update_blood_vignette()


# 분노의 포효 등으로 보스 공격력 영구 증가 시 — 보스 얼굴 붉은 글로우 펀치
func _on_boss_attack_buffed(new_bonus: int) -> void:
	if boss_face_texture:
		boss_face_texture.pivot_offset = boss_face_texture.size / 2.0
		var tween := create_tween()
		boss_face_texture.modulate = Color(1.8, 1.2, 0.5, 1)   # 황금빛 강화 플래시
		tween.tween_property(boss_face_texture, "modulate", Color.WHITE, 0.5)\
			.set_ease(Tween.EASE_OUT)
	# 보스 인텐트 라벨 옆에 강화 표시
	if boss_intent_label:
		var anchor: Control = (boss_face_texture as Control) if boss_face_texture else (boss_intent_label as Control)
		_spawn_floating_text("⚔ 공격력 +%d!" % new_bonus, Color(1.0, 0.6, 0.2, 1), anchor)


# === 카드 사용 임팩트 이펙트 ===

const _DAMAGE_KINDS := [
	"damage", "rage_scale_damage", "execute_damage",
	"chain_damage", "gold_scale_damage", "block_damage",
	"tempered_damage", "adjacency_damage",
]
const _BLOCK_KINDS := ["block", "rage_scale_block", "adjacency_block"]


# 카드 효과 종류에 따라 적절한 임팩트 연출 분기 (경쾌한 돌진 + 대상 반응)
func _play_card_impact(card: Control) -> void:
	if not card.data:
		return
	var has_damage := false
	var has_block := false
	var has_gold := false
	var adj_bonus := false   # 인접 보너스 조건 충족 여부 ("연계!" 강조용)
	for eff in card.data.effects:
		if eff == null:
			continue
		var info: Dictionary = eff.get_preview_summary()
		var kind: String = info.get("kind", "")
		if kind in _DAMAGE_KINDS:
			has_damage = true
		elif kind in _BLOCK_KINDS:
			has_block = true
		elif kind == "gold":
			has_gold = true
		# 인접 효과는 파이프 맨 앞 조건이 충족됐을 때만 "연계!" 강조
		if (kind == "adjacency_damage" or kind == "adjacency_block") and game_ctx:
			if game_ctx.pipe_front_has_type(int(info.get("require_type", 0)), int(info.get("peek_count", 1))):
				adj_bonus = true

	# 돌진 대상 — 공격은 보스, 방어는 플레이어, 그 외(드로우·조작·골드)는 파이프 쪽
	var target: Control = null
	if has_damage:
		target = boss_face_texture
	elif has_block:
		target = player_face_texture

	# 임팩트 순간 콜백 (돌진 착지 시점)
	var on_impact := func() -> void:
		if has_damage:
			_spawn_slash_fx(boss_face_texture)
			if combat_fx:
				combat_fx.flash_recoil(boss_face_texture, 18.0)
				combat_fx.shake_screen(5.0, 0.18)
		if has_block and combat_fx:
			combat_fx.flash_buff(player_face_texture, Color(0.5, 0.85, 1.4, 1))
		if has_gold:
			_spawn_floating_text("💰", Color(0.95, 0.82, 0.35, 1), player_face_texture)
		if adj_bonus:
			var anchor: Control = target if target else boss_face_texture
			_spawn_floating_text("⚡ 연계!", Color(1.0, 0.9, 0.4, 1), anchor)

	# 돌진은 "타격" 연출 — 공격/방어처럼 대상이 있을 때만.
	# 골드·드로우·조작 등 비전투 카드는 돌진 없이 팝업만 (어색한 큰 잔상 방지)
	if target != null:
		_spawn_card_lunge(card, target, on_impact)
	else:
		on_impact.call()


# 카드 잔상이 손패에서 대상으로 빠르게 돌진했다 사라지는 연출 (경쾌·타격감)
func _spawn_card_lunge(card: Control, target: Control, on_impact: Callable) -> void:
	if card == null or not card.data:
		on_impact.call()
		return
	# 시작점 = 전사 얼굴 (카드를 휘두르는 주체). 없으면 플레이존(무대 중앙) → 손패 순 폴백.
	var start: Vector2
	if player_face_texture != null and is_instance_valid(player_face_texture):
		start = player_face_texture.get_global_rect().get_center() - global_position
	elif play_drop_zone != null:
		start = play_drop_zone.get_global_rect().get_center() - global_position
	else:
		start = card.get_global_rect().get_center() - global_position
	var dest: Vector2 = start
	if target != null and is_instance_valid(target):
		dest = target.get_global_rect().get_center() - global_position
	else:
		dest = start + Vector2(0, -130)   # 파이프(상단) 방향으로 가볍게

	# 손패 카드 크기의 2배로 (card.size 우선, 없으면 custom_minimum_size 폴백)
	var ghost_size: Vector2 = card.size if card.size.length() > 1.0 else card.custom_minimum_size
	if ghost_size.length() < 1.0:
		ghost_size = Vector2(144, 204)
	ghost_size *= 2.0
	var half := ghost_size * 0.5
	var ghost := TextureRect.new()
	ghost.texture = card.data.artwork
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 145
	add_child(ghost)
	# add_child 후 anchor·size 강제 (레이아웃이 size를 텍스처 원본으로 키우는 것 방지)
	ghost.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ghost.custom_minimum_size = ghost_size
	ghost.size = ghost_size
	ghost.pivot_offset = half
	ghost.position = start - half
	ghost.modulate = Color(1, 1, 1, 0.92)

	# 제자리(방어 등)면 더 오래 보여주고, 멀리 돌진(공격)이면 빠른 타격감
	var stationary: bool = start.distance_to(dest) < 30.0
	var hold: float = 0.4 if stationary else 0.06
	var fade: float = 0.3 if stationary else 0.16

	# 대상 70% 지점까지 가속 돌진 → 착지 임팩트 → 체류 → 페이드아웃
	var land: Vector2 = start.lerp(dest, 0.7) - half
	var tween := create_tween()
	tween.tween_property(ghost, "position", land, 0.16).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(on_impact)
	tween.tween_interval(hold)
	tween.tween_property(ghost, "modulate:a", 0.0, fade)
	tween.tween_callback(ghost.queue_free)


# 보스 얼굴을 가로지르는 대각선 슬래시 연출
func _spawn_slash_fx(target: Control) -> void:
	if target == null:
		return
	var rect := target.get_global_rect()
	var center := rect.get_center() - global_position
	var half := rect.size * 0.42
	var line := Line2D.new()
	line.width = 7.0
	line.default_color = Color(1, 1, 1, 0.95)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.z_index = 150
	line.add_point(center + Vector2(-half.x, -half.y))
	line.add_point(center + Vector2(half.x, half.y))
	add_child(line)
	# 짧게 번쩍였다 사라짐
	line.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 1.0, 0.05)
	tween.tween_property(line, "modulate:a", 0.0, 0.22).set_ease(Tween.EASE_IN)
	tween.tween_callback(line.queue_free)
	AudioManager.play_sfx("combat.hit_boss", -3.0, 0.1)


# 앵커 노드 위에 잠깐 떠올랐다 사라지는 강조 텍스트 (공통 헬퍼)
func _spawn_floating_text(text: String, color: Color, anchor: Control) -> void:
	if anchor == null:
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 110
	add_child(lbl)
	var r := anchor.get_global_rect()
	lbl.global_position = r.get_center() - global_position + Vector2(-40, -20)
	lbl.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(lbl, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(lbl, "position:y", lbl.position.y - 24, 0.6)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.5)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.3)
	tween.tween_callback(lbl.queue_free)


# 피 냄새 활성 + 보스 HP ≤50% 일 때만 비네팅 표시 (보스 HP 변경 시에도 호출)
func _update_blood_vignette() -> void:
	if _blood_vignette == null or game_ctx == null:
		return
	var should_show: bool = game_ctx.blood_scent_active and game_ctx.boss_hp * 2 <= game_ctx.boss_max_hp
	if should_show == _blood_vignette.visible:
		return
	if should_show:
		_blood_vignette.visible = true
		_blood_vignette.modulate.a = 0.0
		if _blood_pulse_tween and _blood_pulse_tween.is_running():
			_blood_pulse_tween.kill()
		_blood_pulse_tween = create_tween().set_loops()
		_blood_pulse_tween.tween_property(_blood_vignette, "modulate:a", 1.0, 1.0)\
			.set_trans(Tween.TRANS_SINE)
		_blood_pulse_tween.tween_property(_blood_vignette, "modulate:a", 0.5, 1.0)\
			.set_trans(Tween.TRANS_SINE)
	else:
		if _blood_pulse_tween and _blood_pulse_tween.is_running():
			_blood_pulse_tween.kill()
		_blood_vignette.visible = false


# === 보스 카드 호버 프리뷰 (다음 예고 / 파워 존) ===

var _boss_card_preview: BossCardDisplay = null


func _on_boss_card_label_hover(card: BossCardData, anchor: Control, tokens: int, entered: bool) -> void:
	if entered:
		_spawn_boss_card_preview(card, anchor, tokens)
	else:
		_clear_boss_card_preview()


func _spawn_boss_card_preview(card: BossCardData, anchor: Control, tokens: int) -> void:
	_clear_boss_card_preview()
	if card == null or not is_instance_valid(anchor):
		return
	var preview := BossCardDisplay.new()
	add_child(preview)
	var preview_phase: int = boss_deck_system.get_phase_of(card) if boss_deck_system else 0
	preview.setup(card, tokens, Vector2.ZERO, preview_phase)
	preview.z_index = 250
	preview.scale = Vector2(1.15, 1.15)
	# 우측 컬럼이므로 프리뷰는 라벨 좌측에 배치
	var anchor_rect := anchor.get_global_rect()
	var preview_size := Vector2(BossCardDisplay.CARD_W, BossCardDisplay.CARD_H) * preview.scale
	var target := anchor_rect.position \
		+ Vector2(-preview_size.x - 16, anchor_rect.size.y * 0.5 - preview_size.y * 0.5) \
		- global_position
	# 좌측 잘림 시 우측에 배치
	if target.x < 8:
		target.x = anchor_rect.end.x + 16 - global_position.x
	# 상/하단 잘림 보정
	var vp := get_viewport_rect().size
	target.y = clampf(target.y, 8.0, vp.y - preview_size.y - 8.0)
	preview.position = target
	# 페이드 인 + 살짝 떠오름
	preview.modulate.a = 0.0
	var start_y := target.y + 6.0
	preview.position.y = start_y
	var tween := create_tween().set_parallel(true)
	tween.tween_property(preview, "modulate:a", 1.0, 0.12)
	tween.tween_property(preview, "position:y", start_y - 6.0, 0.18)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_boss_card_preview = preview


func _clear_boss_card_preview() -> void:
	if is_instance_valid(_boss_card_preview):
		_boss_card_preview.queue_free()
	_boss_card_preview = null


# === 보스 머리 위 인텐트 라벨 ===

var _intent_tween: Tween = null

func _update_boss_intent(card: BossCardData, is_preview: bool) -> void:
	if boss_intent_label == null:
		return
	if card == null:
		boss_intent_label.text = ""
		return
	var prefix := "다음 " if is_preview else "이번 턴 "
	boss_intent_label.text = "%s%s %s" % [prefix, card.intent_icon, card.card_name]
	if is_preview:
		boss_intent_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0, 0.95))
		return
	# 행동 직전 — 강조 펄스 (이전 트윈 살아있으면 정리)
	boss_intent_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3, 1))
	if _intent_tween and _intent_tween.is_running():
		_intent_tween.kill()
	boss_intent_label.scale = Vector2(1.25, 1.25)
	boss_intent_label.pivot_offset = boss_intent_label.size / 2.0
	_intent_tween = create_tween()
	_intent_tween.tween_property(boss_intent_label, "scale", Vector2.ONE, 0.25)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


# === 보상형 카드 영구 제거 ===
# 페이즈 전환 보상 / 마켓 "각인의 의식" 카드 효과 모두 사용.
# 손패+파이프 통합 선택 UI, 1장 선택 또는 스킵 가능.

# 마켓 효과(RemoveCardEffect)에서 호출됨
func _on_request_card_removal_from_effect() -> void:
	var lines: Array[String] = ["✨ 각인의 의식", "카드 1장을 영구 제거하라"]
	_grant_card_removal_reward(lines)


func _grant_card_removal_reward(reason_lines: Array[String]) -> void:
	var all_cards: Array[Control] = []
	all_cards.append_array(hand_cards)
	all_cards.append_array(queue_cards)
	if all_cards.is_empty():
		return
	if phase_banner and reason_lines.size() > 0:
		phase_banner.show_sequence(reason_lines)
		await phase_banner.banner_finished
	is_discarding_from_effect = true
	end_turn_overlay.show_overlay_select(all_cards, 1, "영구 제거할")
	# confirm 또는 cancel 둘 중 무엇이든 풀림
	var resolved: Array = [false]
	var picked: Array[Control] = []
	var on_confirm := func(cards: Array) -> void:
		if resolved[0]: return
		resolved[0] = true
		for c in cards: picked.append(c)
	var on_cancel := func() -> void:
		if resolved[0]: return
		resolved[0] = true
	end_turn_overlay.order_confirmed.connect(on_confirm, CONNECT_ONE_SHOT)
	end_turn_overlay.cancelled.connect(on_cancel, CONNECT_ONE_SHOT)
	while not resolved[0]:
		await get_tree().process_frame
	is_discarding_from_effect = false
	if picked.is_empty():
		return
	var chosen: Control = picked[0]
	if chosen in hand_cards:
		hand_cards.erase(chosen)
	elif chosen in queue_cards:
		queue_cards.erase(chosen)
	await exile_animator.play(chosen)
	if is_instance_valid(chosen):
		chosen.queue_free()
	_update_hand_display()
	_rebuild_pipe_ui()


# 페이즈 보상 큐 — 시그널 콜백 도중 await race 방지
# _begin_player_turn 시작 시 안전하게 처리
func _drain_pending_rewards() -> void:
	while not _pending_rewards.is_empty():
		var raw: Array = _pending_rewards.pop_front()
		var lines: Array[String] = []
		for l in raw:
			lines.append(str(l))
		await _grant_card_removal_reward(lines)
