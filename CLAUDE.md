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

### 보스 카드덱 시스템 (에이언즈 엔드 방식)
- `BossDeckSystem` (`scripts/bosses/boss_deck_system.gd`, RefCounted): 보스 카드 덱 관리
- 구조: Phase1 카드(내부 셔플) → Phase2 카드(내부 셔플) → Phase3 카드(내부 셔플) 순으로 쌓음. 티어 경계 고정, 덱 소진 시 버린 카드 전체 재셔플
- 카드 타입: **ATTACK** (즉시 실행 → 버린 카드), **POWER** (파워 존에 배치 → 매 보스 턴 카운트다운 -1 → 0 시 발동)
- 공개 범위: 덱 장수만 표시(내용 비공개), 파워 존 항상 공개(카운트다운 포함), 버린 카드 더미 공개
- `BossCardData` (`scripts/bosses/boss_card_data.gd`, Resource): 카드명/타입/카운트다운/아이콘/설명/효과 배열
- 보스 전용 효과 (`scripts/bosses/effects/`): `BossDamageEffect`(플레이어 피해), `BossBlockEffect`(보스 방어도), `BossForceDiscardEffect`(강제 버리기)
- 보스 턴 흐름: ① 파워 틱(0 도달 시 즉시 발동) → ② 카드 드로우 → ③ 배너 표시 → ④ 카드 실행 → ⑤ 모듈 훅
- UI: `%BossDeckCountLabel`(덱 장수+이름목록), `%BossDiscardLabel`(버린 카드 수), `%BossCurrentCardContainer`(이번 턴 카드 — BossCardDisplay 인스턴스), `%BossPowerZone`(활성 파워 카드 — BossCardDisplay 인스턴스 목록)
- `BossCardDisplay` (`scripts/cards/boss_card_display.gd`, Control): 보스 카드 시각 위젯 (드래그 없음). 아이콘·이름·설명·타입 표시. POWER 카드에는 우상단 오렌지 카운트다운 뱃지 표시. 118×168px
- 버그베어 카드: `resources/bosses/bugbear/phase1~3/` (총 13장 — Phase1: 5장, Phase2: 4장, Phase3: 4장)

### 보스 페이즈 시스템
- `BossPhaseSystem` (`scripts/bosses/boss_phase_system.gd`, RefCounted): 3단계(1·2·3) 페이즈 상태 + 전환 판정
- 전환 트리거: **HP 임계만** (라운드 트리거 제거됨). HP 임계 = `[0.66, 0.33]`(boss_max_hp 비율). 단방향(올라가기만)
- 평가 시점: 보스 HP 변경(`_on_boss_hp_changed` → `check_hp_trigger()`)
- `phase_changed(new, old)` 시그널 → `MarketPanel.set_phase(new)` 다음 refresh 가중치 반영, `%PhaseLabel` 텍스트·색 갱신, `phase_banner` 안내
- **GameContext와 분리**: 페이즈는 보스 전용 상태이므로 공유 컨텍스트에 추가하지 않음. ctx 참조만 위임
- 마켓 가중치 (`MarketPanel.TIER_WEIGHTS`): Phase 1 = T1 100·T2 0·T3 0 / Phase 2 = T1 20·T2 100·T3 0 / Phase 3 = T1 5·T2 30·T3 100. 누적이지만 하위 티어 가중치 급감

### 슬롯 시스템
- **액티브 슬롯** (`%ActiveSlot1`, `%ActiveSlot2`): MODULE 타입 카드 장착. 슬롯1은 시작 시 반격 태세 기본 장착

### 라운드 마켓
- `MarketPanel` (`scripts/ui/market_panel.gd`): MiddleArea 가운데 패널. **4-레인** (공격·방어·특수·골드), 라운드 시작 시 각 레인에서 1장씩 추첨
- `_load_pool(dir)`: `DirAccess`로 레인 디렉토리 스캔 → 풀 자동 빌드 (씬 파일에 카드 개별 등록 불필요)
- 카드별 고정 골드 가격(`CardData.gold_cost`). 구매 시 골드 차감 + `card_purchased` 시그널 → `main_scene._on_market_card_purchased`가 파이프 맨 뒤에 추가
- 리롤: AP 3 또는 골드 3 (플레이어 턴 한정, 횟수 제한 없음, 4레인 전체 동시 재추첨)
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
  data/
    game_balance.gd            # ★ 밸런스 수치 모음 (HP·AP·골드·투기·마켓 비용 등)
                               #   초보자가 수치를 바꾸려면 이 파일만 보면 됩니다
  main/
    main_scene.gd              # 게임 루프, 턴 관리, 드롭 핸들러
    game_context.gd            # 공유 상태 (HP, 블록, Callable). 직업 고유 상태 금지
  cards/
    card.gd                    # 카드 노드 (드래그&드롭, 플레이어용)
    card_data.gd               # CardData Resource (effects, module_ability)
    effects/                   # [공유] 카드 효과 클래스 계층 (CardEffect 상속)
    modules/
      module_ability.gd        # [공유] 모듈 능력 베이스 클래스 (훅 인터페이스)
  characters/                  # 직업별 고유 시스템 루트
    warrior/
      rage_system.gd           # 전사 투기 스택 + 발산 로직
      counter_stance_ability.gd  # 전사 "반격 태세" 모듈 구현
      iron_armor_ability.gd      # 전사 "견고한 갑옷" 모듈 구현
  bosses/                      # 보스 시스템 루트
    boss_phase_system.gd       # 3단계 페이즈 (HP 임계 트리거, 단방향)
    boss_card_display.gd       # 보스 카드 표시 위젯 (읽기 전용, 드래그 없음)
  ui/
    drop_zone.gd               # 드롭 존 (PLAY/DISCARD/ACTIVE)
    resource_bar.gd            # AP + 골드 UI
    ap_manager.gd              # AP 상태 관리
    gold_manager.gd            # 골드 상태 관리
    market_panel.gd            # 4-레인 마켓 (공격·방어·특수·골드, DirAccess 자동 스캔)
    damage_popup.gd            # 피해·회복 숫자 팝업 (Tween 애니메이션)

scenes/
  main/main_scene.tscn
  cards/card.tscn

resources/
  cards/
    starter_*.tres             # 모든 직업 공용 스타터 카드 (4종)
    warrior/                   # 전사 고유 카드/모듈 리소스
      module_counter_stance.tres
      market/                  # 전사 마켓 카드 풀 (레인별 디렉토리)
        attack/                # ⚔ 공격 레인 (7장: T1 5종 + T2 2종)
        defense/               # 🛡 방어 레인 (4장: T1 3종 + T2 1종)
        special/               # ✨ 특수 레인 (3장: T1 2종 + T2 1종)
        gold/                  # 💰 골드 레인 (4장: T1 3종 + T2 1종)
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
