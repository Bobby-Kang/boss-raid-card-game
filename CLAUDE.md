# 보스 레이드 카드게임 — Claude 가이드

## 프로젝트 개요
- **장르**: 1:1 보스 레이드 카드게임 (턴제)
- **엔진**: Godot 4.6.2, Mobile Renderer, D3D12
- **뷰포트**: 1920x1080 (개발용)
- **언어**: GDScript

## 핵심 아키텍처

### 자원 시스템
- **AP** (최대 3): 카드 사용 비용. 플레이어 턴 시작 시 3으로 리셋. 턴 종료 시 남은 AP → 전사 투기 스택
- **골드** (최대 10): 재화 카드로 획득. **턴 종료 시 증발**. 라운드 마켓 카드 구매 + 마켓 리롤(3 골드)에 사용
- **방어도**: 피해 흡수. **라운드 종료 시 리셋** (한 라운드 5턴 동안 누적/유지)
- `ApManager` (`scripts/ui/ap_manager.gd`), `GoldManager` (`scripts/ui/gold_manager.gd`)
- `ResourceBar` (`scripts/ui/resource_bar.gd`): AP/골드 UI 통합 관리

### 카드 시스템
- `CardData` Resource (`scripts/cards/card_data.gd`): 카드 데이터. `effects: Array[CardEffect]` + `module_ability: ModuleAbility` + `gold_cost: int`(마켓 가격) + `tier: int`(마켓 추첨 가중치 등급, 1=기본/2=중/3=고)
- `CardEffect` 계층 (`scripts/cards/effects/`): `DamageEffect`, `BlockEffect`, `GainGoldEffect`, `DrawEffect`, `DiscardEffect`
- `ModuleAbility` 계층 (`scripts/cards/modules/`): 모듈 카드의 패시브 훅 베이스 (`on_boss_turn_end` 등)
- `GameContext` (`scripts/main/game_context.gd`): 공유 상태(HP, 방어도) + Callable (`draw_cards`, `discard_cards`)
- 드래그&드롭: `DropZone` (`scripts/ui/drop_zone.gd`) — `PLAY` / `DISCARD` / `ACTIVE`
  - MODULE 카드는 `ACTIVE`만 허용, `PLAY`/`DISCARD` 거부

### 덱 시스템 (타임라인 파이프)
- 섞지 않는 FIFO 큐 (`queue_cards[]`)
- 손패(`hand_cards[]`) ← 파이프 앞 5장 드로우 → 사용/버리기 → 파이프 맨 뒤로
- 턴 종료 시 남은 손패는 플레이어가 순서 지정 후 파이프 맨 뒤에 삽입

### 라운드/턴 시스템
- 5턴/라운드: 턴1 항상 플레이어, 턴2~5는 [player, player, boss, boss] 셔플
- 보스 3연속 방지 검증 (`_validate_turn_order()`)
- `main_scene.gd`: `_advance_turn()` → `_begin_player_turn()` / `_begin_boss_turn()`
- 라운드 경계(`current_turn > TURNS_PER_ROUND`)에서 방어도 리셋

### 보스 페이즈 시스템
- `BossPhaseSystem` (`scripts/bosses/boss_phase_system.gd`, RefCounted): 3단계(1·2·3) 페이즈 상태 + 전환 판정
- 전환 트리거: **HP 임계** OR **라운드 임계** (둘 중 빠른 쪽). HP 임계 = `[0.66, 0.33]`(boss_max_hp 비율), 라운드 임계 = `[3, 5]`. 단방향(올라가기만)
- 평가 시점: 보스 HP 변경(`_on_boss_hp_changed` → `check_hp_trigger()`), 라운드 시작(`_start_round` → `check_round_trigger(current_round)`, 마켓 refresh 이전)
- `phase_changed(new, old)` 시그널 → `MarketPanel.set_phase(new)` 다음 refresh 가중치 반영, `%PhaseLabel` 텍스트·색 갱신, `phase_banner` 안내
- **GameContext와 분리**: 페이즈는 보스 전용 상태이므로 공유 컨텍스트에 추가하지 않음. ctx 참조만 위임
- 마켓 가중치 (`MarketPanel.TIER_WEIGHTS`): Phase 1 = T1 100·T2 0·T3 0 / Phase 2 = T1 20·T2 100·T3 0 / Phase 3 = T1 5·T2 30·T3 100. 누적이지만 하위 티어 가중치 급감

### 슬롯 시스템
- **액티브 슬롯** (`%ActiveSlot1`, `%ActiveSlot2`): MODULE 타입 카드 장착. 슬롯1은 시작 시 반격 태세 기본 장착

### 라운드 마켓
- `MarketPanel` (`scripts/ui/market_panel.gd`): MiddleArea 가운데 패널. 라운드 시작 시 `card_pool`에서 3장 무작위 진열
- 카드별 고정 골드 가격(`CardData.gold_cost`). 구매 시 골드 차감 + `card_purchased` 시그널 → `main_scene._on_market_card_purchased`가 파이프 맨 뒤에 추가
- 리롤: AP 3 또는 골드 3 (플레이어 턴 한정, 횟수 제한 없음)
- 풀: 직업별 `resources/cards/<job>/market/*.tres` + `tier2/*.tres` (전사 T1: 강타·굳건한 방패·돌격·명상, T2: 참격·강철 의지·속공·재정비)
- 추첨: 페이즈별 가중치 기반 (`_weighted_pick`). 페이즈가 올라가면 상위 티어가 주력으로 등장
- 보스 턴/턴 종료 시 `set_player_turn(false)` 호출로 모든 버튼 비활성

### 전사 고유 시스템
- **투기 스택** (`WarriorRageSystem`): 플레이어 턴 종료 시 남은 AP → 스택 (최대 10). 10스택 시 0 AP로 보스 10 피해 + 방어도 +10
- **반격 태세 모듈** (`CounterStanceAbility`): 보스 턴 종료 시 방어도 1+ 남으면 보스 2 피해
- UI: `BuffBar` 패널 내부에 `%RageLabel` + `%RageOrbs` + `%RageButton`

## 코딩 규칙
- `unique_name_in_owner = true` + `%NodeName` 접근 패턴 사용
- 신호(Signal) 기반 UI 업데이트
- 효과는 `CardEffect.execute(ctx: GameContext)` 인터페이스 준수
- 모듈 능력은 `ModuleAbility` 훅(`on_boss_turn_end` 등) 오버라이드
- **직업 고유 기능은 `GameContext`(공유 상태)와 섞지 말 것** — 전용 클래스로 분리

## 디렉토리 구조
```
scripts/
  main/
    main_scene.gd              # 게임 루프, 턴 관리, 드롭 핸들러
    game_context.gd            # 공유 상태 (HP, 블록, Callable). 직업 고유 상태 금지
  cards/
    card.gd                    # 카드 노드 (드래그&드롭)
    card_data.gd               # CardData Resource (effects, module_ability)
    effects/                   # [공유] 카드 효과 클래스 계층 (CardEffect 상속)
    modules/
      module_ability.gd        # [공유] 모듈 능력 베이스 클래스 (훅 인터페이스)
  characters/                  # 직업별 고유 시스템 루트
    warrior/
      rage_system.gd           # 전사 투기 스택 + 발산 로직
      counter_stance_ability.gd  # 전사 "반격 태세" 모듈 구현
  bosses/                      # 보스 시스템 루트
    boss_phase_system.gd       # 3단계 페이즈 (HP/라운드 OR 트리거)
  ui/
    drop_zone.gd               # 드롭 존 (PLAY/DISCARD/ACTIVE)
    resource_bar.gd            # AP + 골드 UI
    ap_manager.gd              # AP 상태 관리
    gold_manager.gd            # 골드 상태 관리
    market_panel.gd            # 라운드 마켓 (3슬롯 + 리롤)

scenes/
  main/main_scene.tscn
  cards/card.tscn

resources/
  cards/
    starter_*.tres             # 모든 직업 공용 스타터 카드 (4종)
    warrior/                   # 전사 고유 카드/모듈 리소스
      module_counter_stance.tres
      market/                  # 전사 마켓 Tier 1 카드 풀
        market_strike.tres
        market_bulwark.tres
        market_charge.tres
        market_meditation.tres
        tier2/                 # 전사 마켓 Tier 2 카드 풀
          market_cleave.tres
          market_iron_will.tres
          market_swift_blow.tres
          market_regroup.tres
```

### 새 직업 추가 가이드
1. `scripts/characters/<job>/` 디렉토리 생성
2. 직업 고유 시스템 클래스(예: `rage_system.gd` 대응) 추가
3. 직업 고유 모듈은 `ModuleAbility`를 상속하여 동일 디렉토리에 배치
4. 리소스는 `resources/cards/<job>/`에 배치
5. `main_scene`에서 해당 직업 시스템을 인스턴스화 + 시작 모듈 장착

## 반드시 지킬 규칙
1. **코드 수정 전 계획을 먼저 제시하고 승인받을 것**
2. 불필요한 파일/코드 추가 금지 (필요한 것만)
3. `print()` 디버그 출력은 임시용 — 배포 전 제거
4. 씬 파일(.tscn) 수정 시 노드 경로 깨짐 주의
