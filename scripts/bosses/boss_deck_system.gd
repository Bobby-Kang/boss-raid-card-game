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

	var b1: Array[BossCardData] = []
	var b2: Array[BossCardData] = []
	var b3: Array[BossCardData] = []
	for c in phase1_cards:
		b1.append(c)
	for c in phase2_cards:
		b2.append(c)
	for c in phase3_cards:
		b3.append(c)
	b1.shuffle()
	b2.shuffle()
	b3.shuffle()

	deck.append_array(b1)
	deck.append_array(b2)
	deck.append_array(b3)

	deck_changed.emit(deck.size())
	power_zone_updated.emit([])


# 보스 턴 시작 시 호출 — 파워 카운트다운 틱
# 반환값: 이번 틱에 발동된 카드 목록 (UI/배너용)
func tick_powers() -> Array[BossCardData]:
	var triggered: Array[BossCardData] = []
	var remaining: Array = []

	for entry in active_powers:
		entry.tokens -= 1
		if entry.tokens <= 0:
			triggered.append(entry.card)
		else:
			remaining.append(entry)

	active_powers = remaining

	# 발동된 파워: 효과 실행 후 버린 카드 더미로
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
			active_powers.append({card = card, tokens = card.countdown})
			power_zone_updated.emit(active_powers.duplicate())


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
