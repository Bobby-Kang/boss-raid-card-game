class_name GameContext
extends RefCounted

signal player_hp_changed(current: int, max_hp: int)
signal player_block_changed(block: int)
signal boss_hp_changed(current: int, max_hp: int)
signal boss_block_changed(block: int)

var gold_manager: GoldManager
var ap_manager: ApManager

# 카드 조작 Callable (main_scene에서 등록)
var draw_cards: Callable    # func(count: int) -> void
var discard_cards: Callable # func(count: int) -> void (선택 UI 포함)
var exile_cards: Callable   # func(count: int) -> void (영구 소멸, 파이프로 복귀 안 함)
var request_card_removal: Callable  # func() -> void (손패+파이프에서 1장 영구 제거 선택)

# === 파이프(타임라인) 메커니즘 ===
# 효과 실행 직전 main_scene이 acting_card를 세팅 → 효과가 자기 카드의 단련 횟수를 조회
var acting_card: Control = null            # 지금 실행 중인 카드 노드 (단련 조회용)
var peek_pipe_front: Callable              # func(count: int) -> Array[CardData] (파이프 앞 N장 미리보기 — 인접 판정)
var reorder_pipe_to_front: Callable        # func() -> void (파이프 카드 1장 선택해 맨 앞으로)
var rewind_pipe: Callable                  # func(count: int) -> void (맨 뒤 N장을 맨 앞으로)

# acting_card의 단련 횟수(파이프를 돈 바퀴 수). 없으면 0.
func get_acting_card_temper() -> int:
	if acting_card != null and "temper" in acting_card:
		return int(acting_card.temper)
	return 0

# 파이프 맨 앞 카드가 특정 타입인지 (인접 판정용). count장 중 하나라도 해당 타입이면 true.
func pipe_front_has_type(card_type: int, count: int = 1) -> bool:
	if not peek_pipe_front.is_valid():
		return false
	var fronts: Array = peek_pipe_front.call(count)
	for cd in fronts:
		if cd != null and cd.card_type == card_type:
			return true
	return false

var player_hp: int     = GameBalance.PLAYER_MAX_HP
var player_max_hp: int = GameBalance.PLAYER_MAX_HP
var player_block: int  = 0

var boss_hp: int     = GameBalance.BOSS_MAX_HP
var boss_max_hp: int = GameBalance.BOSS_MAX_HP
var boss_block: int  = 0

# === 콤보 트래커 (턴/카드 단위 카운터) ===
var attacks_this_turn: int = 0           # 연환격 등 — 이번 턴 ATTACK 카드 사용 횟수
var negate_next_boss_action: bool = false  # 불멸의 방패 등 — 다음 보스 행동 1회 무효
# 직업 시스템 (전사 등)이 등록 — 효과가 투기 자원에 접근하기 위함
var rage_system: WarriorRageSystem = null
# 보스 덱 시스템 참조 — 야수의 외침 같은 효과가 POWER 카운트 조작하기 위함
var boss_deck_system: BossDeckSystem = null

# === 보스 디버프·상태 ===
signal draw_lock_changed(stacks: int)
signal vulnerability_changed(stacks: int)
signal blood_scent_changed(active: bool)
signal boss_attack_buffed(new_bonus: int)

var draw_lock_stacks: int = 0             # 다음 플레이어 턴 드로우 -N (1회성)
var vulnerability_stacks: int = 0         # 받는 다음 N번 피해 ×1.5 (스택당 1회 소진)
var blood_scent_active: bool = false      # 피 냄새 — 보스 HP ≤50% 시 공격 ×1.2
var boss_attack_bonus: int = 0            # 분노의 포효 등 — 보스 공격력 영구 +N
var last_hit_vulnerable: bool = false     # 직전 플레이어 피격이 취약 강화였는지 (팝업 강조용)


func add_boss_attack_bonus(amount: int) -> void:
	boss_attack_bonus += amount
	boss_attack_buffed.emit(boss_attack_bonus)


func apply_draw_lock(stacks: int) -> void:
	draw_lock_stacks += stacks
	draw_lock_changed.emit(draw_lock_stacks)


func consume_draw_lock() -> int:
	var stacks: int = draw_lock_stacks
	draw_lock_stacks = 0
	draw_lock_changed.emit(0)
	return stacks


func apply_vulnerability(stacks: int) -> void:
	vulnerability_stacks += stacks
	vulnerability_changed.emit(vulnerability_stacks)


# 플레이어가 피해 받을 때 자동 호출됨 — 취약 1스택 소비 + 피해 ×1.5
func _apply_vulnerability_multiplier(damage: int) -> int:
	if vulnerability_stacks <= 0:
		last_hit_vulnerable = false
		return damage
	vulnerability_stacks -= 1
	vulnerability_changed.emit(vulnerability_stacks)
	last_hit_vulnerable = true
	return int(damage * 1.5)


func activate_blood_scent() -> void:
	if blood_scent_active:
		return
	blood_scent_active = true
	blood_scent_changed.emit(true)


# 보스의 모든 ATTACK 피해에 적용되는 배율 (피 냄새 + 공격력 보너스)
func get_boss_attack_modifier(base_damage: int) -> int:
	var total: int = base_damage + boss_attack_bonus
	if blood_scent_active and boss_hp * 2 <= boss_max_hp:
		total = int(total * 1.2)
	return total


func deal_damage_to_boss(amount: int) -> void:
	var blocked := mini(amount, boss_block)
	boss_block -= blocked
	var remaining := amount - blocked
	boss_hp = maxi(boss_hp - remaining, 0)
	boss_block_changed.emit(boss_block)
	boss_hp_changed.emit(boss_hp, boss_max_hp)


func add_boss_block(amount: int) -> void:
	boss_block += amount
	boss_block_changed.emit(boss_block)


func reset_boss_block() -> void:
	boss_block = 0
	boss_block_changed.emit(boss_block)


func deal_damage_to_player(amount: int, pierce: bool = false) -> void:
	# 취약 적용 — 1스택 소비, 피해 ×1.5
	var adjusted: int = _apply_vulnerability_multiplier(amount)
	var remaining: int = adjusted
	if not pierce:
		var blocked := mini(adjusted, player_block)
		player_block -= blocked
		remaining = adjusted - blocked
		player_block_changed.emit(player_block)
	player_hp = maxi(player_hp - remaining, 0)
	player_hp_changed.emit(player_hp, player_max_hp)


func add_block(amount: int) -> void:
	player_block += amount
	player_block_changed.emit(player_block)


func reset_block() -> void:
	player_block = 0
	player_block_changed.emit(player_block)


func heal_player(amount: int) -> void:
	player_hp = mini(player_hp + amount, player_max_hp)
	player_hp_changed.emit(player_hp, player_max_hp)
