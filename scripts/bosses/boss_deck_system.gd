class_name BossDeckSystem
extends RefCounted

# 보스 카드덱 시스템 — 에이언즈 엔드 방식
#
# 구조:
#   덱 = [Phase1 카드(내부 셔플)] + [Phase2 카드(내부 셔플)] + [Phase3 카드(내부 셔플)]
#   티어 경계는 고정 — Phase1을 다 써야 Phase2 구간 진입
#   덱 소진 시: 버린 카드 더미 전체를 셔플해 재사용
#
# 카드 타입:
#   ATTACK: 즉시 효과 실행 → 버린 카드 더미
#   POWER:  파워 존에 놓임 → 매 보스 턴 카운트다운 -1 → 0이 되면 발동 → 버린 카드 더미
#
# 공개 범위:
#   덱: 남은 카드 구성 공개 (이름만, 순서 비공개 — 알파벳/가나다 정렬로 표시)
#   파워 존: 항상 공개 (카운트다운 포함)
#   버린 카드 더미: 공개

signal deck_changed(remaining_count: int)
signal power_zone_updated(active_powers: Array)   # Array of {card, tokens}
signal card_discarded(card_data: BossCardData)

var ctx: GameContext
var deck: Array[BossCardData] = []
var discard: Array[BossCardData] = []
var active_powers: Array = []  # Array of Dictionary {card: BossCardData, tokens: int}

# 각 카드의 출처 페이즈 (1/2/3) — UI에서 페이즈별 카운트·뱃지 표시용
# .tres 자체에는 페이즈 정보가 없으므로 setup()에서 기록
var _card_phase: Dictionary = {}


func _init(game_ctx: GameContext) -> void:
	ctx = game_ctx


# 게임 시작 시 덱 구성
# phase1/2/3 각 배열을 내부 셔플 후 순서대로 쌓는다
func setup(
	phase1_cards: Array,
	phase2_cards: Array,
	phase3_cards: Array
) -> void:
	deck.clear()
	discard.clear()
	active_powers.clear()

	_card_phase.clear()

	var b1: Array[BossCardData] = []
	var b2: Array[BossCardData] = []
	var b3: Array[BossCardData] = []
	for c in phase1_cards:
		b1.append(c)
		_card_phase[c] = 1
	for c in phase2_cards:
		b2.append(c)
		_card_phase[c] = 2
	for c in phase3_cards:
		b3.append(c)
		_card_phase[c] = 3
	b1.shuffle()
	b2.shuffle()
	b3.shuffle()

	deck.append_array(b1)
	deck.append_array(b2)
	deck.append_array(b3)

	deck_changed.emit(deck.size())
	power_zone_updated.emit([])


# 보스 턴 시작 시 호출 — 파워 카운트다운 틱
# 다단 효과: 카운트 -1 직전 on_tick_effects 실행, 카운트 0 시 effects 실행 후 버림
# 반환값: 이번 틱에 발동된 카드 목록 (UI/배너용)
func tick_powers() -> Array[BossCardData]:
	var triggered: Array[BossCardData] = []
	var remaining: Array = []

	for entry in active_powers:
		# 매턴 효과 (틱 직전)
		for tick_eff in entry.card.on_tick_effects:
			tick_eff.execute(ctx)
		entry.tokens -= 1
		if entry.tokens <= 0:
			triggered.append(entry.card)
		else:
			remaining.append(entry)

	active_powers = remaining

	# 발동된 파워: 카운트 0 효과 실행 후 버린 카드 더미로
	for card in triggered:
		for effect in card.effects:
			effect.execute(ctx)
		discard.append(card)
		card_discarded.emit(card)

	power_zone_updated.emit(active_powers.duplicate())
	return triggered


# *야수의 외침* 같은 카드용 — 모든 활성 POWER 카운트 -1.
# 카운트 0 도달한 카드는 즉시 발동.
func accelerate_all_powers() -> Array[BossCardData]:
	var triggered: Array[BossCardData] = []
	var remaining: Array = []
	for entry in active_powers:
		entry.tokens -= 1
		if entry.tokens <= 0:
			triggered.append(entry.card)
		else:
			remaining.append(entry)
	active_powers = remaining
	for card in triggered:
		for effect in card.effects:
			effect.execute(ctx)
		discard.append(card)
		card_discarded.emit(card)
	power_zone_updated.emit(active_powers.duplicate())
	return triggered


# 덱 앞에서 카드 1장 드로우 (덱 소진 시 버린 카드 셔플 재사용)
func draw_next() -> BossCardData:
	if deck.is_empty():
		if discard.is_empty():
			return null
		deck.assign(discard.duplicate())
		deck.shuffle()
		discard.clear()
	if deck.is_empty():
		return null
	var card: BossCardData = deck.pop_front()
	deck_changed.emit(deck.size())
	return card


# 드로우한 카드를 실행한다
# ATTACK: 즉시 효과 실행 후 버린 카드 더미
# POWER: 파워 존에 추가
func play_card(card: BossCardData) -> void:
	match card.card_type:
		BossCardData.BossCardType.ATTACK:
			for effect in card.effects:
				effect.execute(ctx)
			discard.append(card)
			card_discarded.emit(card)
		BossCardData.BossCardType.POWER:
			# 다단 효과: 드로우 시 즉시 효과 실행
			for draw_eff in card.on_draw_effects:
				draw_eff.execute(ctx)
			active_powers.append({card = card, tokens = card.countdown})
			power_zone_updated.emit(active_powers.duplicate())


## 효과 발동 없이 카드만 버린 카드 더미로 보냄 (불멸의 방패 등 무효화 시 사용).
## POWER 카드도 파워 존 배치 없이 버려진다.
func discard_without_play(card: BossCardData) -> void:
	discard.append(card)
	card_discarded.emit(card)


# 덱 앞 카드를 제거하지 않고 참조 (의도 미리보기용)
# 덱이 비었을 때 버린 카드 더미가 있으면 "재편성 예정" 의미로 null 반환
func peek_next() -> BossCardData:
	if deck.is_empty():
		return null
	return deck[0]


func get_remaining_count() -> int:
	return deck.size()


func get_discard_count() -> int:
	return discard.size()


# 덱에 남은 카드 이름 목록 — 순서를 숨기기 위해 가나다순 정렬
func get_remaining_names_sorted() -> Array[String]:
	var names: Array[String] = []
	for card in deck:
		names.append(card.card_name)
	names.sort()
	return names


func get_active_powers() -> Array:
	return active_powers.duplicate()


# === 플레이어 간섭 동사 (타임라인 전쟁) ===

## 밀어내기 — 덱 맨 앞(다음 예고) 카드를 뒤로 slots칸 이동 (기본 3).
## "맨 뒤"가 아니라 몇 장 뒤라서, 회피하되 카드가 게임에서 삭제되진 않는다.
## 밀린 카드 반환 (없으면 null).
func push_front_back(slots: int = 3) -> BossCardData:
	if deck.size() < 2:
		return null   # 0~1장이면 밀어도 의미 없음
	var card: BossCardData = deck.pop_front()
	var idx: int = mini(slots, deck.size())   # 남은 덱 크기로 클램프
	deck.insert(idx, card)
	deck_changed.emit(deck.size())
	return card


## 시간의 족쇄 — 모든 활성 POWER 카운트 +n (발동 지연)
func delay_all_powers(n: int = 1) -> int:
	var affected: int = 0
	for entry in active_powers:
		entry.tokens += n
		affected += 1
	if affected > 0:
		power_zone_updated.emit(active_powers.duplicate())
	return affected


## 파워 브레이커 — 카운트 min_tokens 이상인 활성 POWER 1장을 발동 없이 파괴.
## 임박한(카운트 1) 파워는 못 부숨 — 예고를 보고 미리 대응해야 한다.
## 파괴된 카드 반환 (대상 없으면 null).
func break_ready_power(min_tokens: int = 2) -> BossCardData:
	var best_i: int = -1
	for i in active_powers.size():
		var entry = active_powers[i]
		if entry.tokens >= min_tokens:
			if best_i < 0 or entry.tokens > active_powers[best_i].tokens:
				best_i = i
	if best_i < 0:
		return null
	var card: BossCardData = active_powers[best_i].card
	active_powers.remove_at(best_i)
	discard.append(card)
	card_discarded.emit(card)
	power_zone_updated.emit(active_powers.duplicate())
	return card


# === 페이즈 메타 (UI 시각화용) ===

# 주어진 카드의 출처 페이즈(1/2/3). 모르면 1 반환.
func get_phase_of(card: BossCardData) -> int:
	if card == null:
		return 1
	return int(_card_phase.get(card, 1))


# 덱(남은 카드)의 페이즈별 장수 — {1: n, 2: n, 3: n}
func get_remaining_counts_by_phase() -> Dictionary:
	var counts := {1: 0, 2: 0, 3: 0}
	for c in deck:
		var p: int = get_phase_of(c)
		counts[p] = int(counts.get(p, 0)) + 1
	return counts


# 덱 남은 카드 이름을 페이즈별로 묶음 (정렬됨) — 칩 툴팁용
func get_remaining_names_by_phase() -> Dictionary:
	var by_phase := {1: [], 2: [], 3: []}
	for c in deck:
		var p: int = get_phase_of(c)
		(by_phase[p] as Array).append(c.card_name)
	for p in by_phase:
		(by_phase[p] as Array).sort()
	return by_phase
