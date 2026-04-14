# 보스 레이드 카드게임 — Claude 가이드

## 프로젝트 개요
- **장르**: 1:1 보스 레이드 카드게임 (턴제)
- **엔진**: Godot 4.6.2, Mobile Renderer, D3D12
- **뷰포트**: 1280x800
- **언어**: GDScript

## 핵심 아키텍처

### 자원 시스템
- **AP** (최대 3): 카드 사용 비용. 플레이어 턴 시작 시 3으로 리셋
- **골드**: 재화 카드로 획득, 턴 종료 시 증발(evaporate)
- `ApManager` (`scripts/ui/ap_manager.gd`), `GoldManager` (`scripts/ui/gold_manager.gd`)
- `ResourceBar` (`scripts/ui/resource_bar.gd`): UI 통합 관리

### 카드 시스템
- `CardData` Resource (`scripts/cards/card_data.gd`): 카드 데이터 (.tres 파일)
- `CardEffect` 계층 (`scripts/cards/effects/`): 효과 클래스들
  - `DamageEffect`, `BlockEffect`, `GainGoldEffect`, `DrawEffect`, `DiscardEffect`
- `GameContext` (`scripts/main/game_context.gd`): 공유 상태 + Callable 등록
  - `draw_cards: Callable`, `discard_cards: Callable`
- 드래그&드롭: `DropZone` (`scripts/ui/drop_zone.gd`) — PLAY/DISCARD/RESERVE/ACTIVE

### 덱 시스템 (Aeon's End 방식)
- 섞지 않음: 버린 순서의 역순으로 다시 뽑음
- 뽑을 더미(`draw_pile_cards`) → 손패(`deck_cards`) → 버린 더미(`discard_cards`)

### 라운드/턴 시스템
- 5턴/라운드: 턴1 항상 플레이어, 턴2~5는 [player, player, boss, boss] 셔플
- 보스 3연속 방지 검증 (`_validate_turn_order()`)
- `main_scene.gd`: `_advance_turn()` → `_begin_player_turn()` / `_begin_boss_turn()`

### 슬롯 시스템
- **예비 슬롯** (`%ReserveSlot`): 재화 카드 1장 다음 턴으로 이월
- **액티브 슬롯** (`%ActiveSlot1`, `%ActiveSlot2`): MODULE 타입 카드 장착

## 코딩 규칙
- `unique_name_in_owner = true` + `%NodeName` 접근 패턴 사용
- 신호(Signal) 기반 UI 업데이트
- 효과는 `CardEffect.execute(ctx: GameContext)` 인터페이스 준수
- `.tres` 파일은 4종만 유지: `starter_gold`, `starter_attack`, `starter_block`, `starter_draw`

## 주요 파일
```
scripts/
  main/
    main_scene.gd      # 게임 루프, 턴 관리, 드롭 핸들러
    game_context.gd    # 공유 상태 (HP, 블록, Callable)
  cards/
    card.gd            # 카드 노드 (드래그&드롭)
    card_data.gd       # CardData Resource
    effects/           # 효과 클래스들
  ui/
    drop_zone.gd       # 드롭 존 (PLAY/DISCARD/RESERVE/ACTIVE)
    resource_bar.gd    # AP + 골드 UI
    ap_manager.gd      # AP 상태 관리
    gold_manager.gd    # 골드 상태 관리
scenes/
  main/main_scene.tscn
  cards/card.tscn
resources/cards/       # .tres 카드 리소스 (4종)
```

## 반드시 지킬 규칙
1. **코드 수정 전 계획을 먼저 제시하고 승인받을 것**
2. 불필요한 파일/코드 추가 금지 (필요한 것만)
3. `print()` 디버그 출력은 임시용 — 배포 전 제거
4. 씬 파일(.tscn) 수정 시 노드 경로 깨짐 주의
