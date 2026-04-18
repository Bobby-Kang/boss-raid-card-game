# Boss Raid Card Game

1:1 보스 레이드 카드 게임 — Godot 4.6.2

> **덱을 섞지 않습니다.** 버린 순서의 역순으로 다시 뽑히므로, 어떤 순서로 카드를 버릴지가 핵심 전략입니다.

## 빠른 시작

Godot 4.6.2 에디터에서 프로젝트를 열고 실행하면 타이틀 화면에서 시작됩니다.
(`project.godot`의 메인 씬: `scenes/main/title_screen.tscn`)

## 게임 흐름

```
타이틀 화면 → [게임 시작]
  └─ 캐릭터 선택 화면 → 보스(버그베어) vs 플레이어(전사) 확인 → [전투 시작]
       └─ 전투 (라운드 반복)
            ├─ 라운드 시작 → 턴 오더 결정 (5턴) → 마켓 카드 진열
            ├─ 플레이어 턴: AP 3 지급 → 카드 5장 드로우 → 카드 드래그&드롭 → 턴 종료
            └─ 보스 턴: 고정 패턴 공격
       └─ 승리/패배 결과 화면 → [타이틀로]
```

## 카드 조작

| 행동 | 방법 |
|------|------|
| 카드 사용 | 손패에서 **가운데(플레이존)**으로 드래그 |
| 카드 버리기 | 손패에서 **버린더미**로 드래그 |
| 모듈 장착 | MODULE 카드를 **액티브 슬롯 1·2**로 드래그 |

## 현재 구현 상태

### 씬 구조
- **타이틀 화면** (`title_screen.tscn`): "프로젝트: 타임라인" 로고 + 게임 시작 버튼
- **캐릭터 선택 화면** (`character_select.tscn`): 보스(버그베어) vs 플레이어(전사) 정보 표시
- **전투 화면** (`main_scene.tscn`): 메인 전투 루프
- **결과 화면** (`game_result_screen.tscn`): 승리/패배 연출 + 타이틀 복귀 버튼

### 카드 시스템
- `CardData` Resource + `CardEffect` 상속 구조
- 효과 클래스: `DamageEffect`, `BlockEffect`, `GainGoldEffect`, `DrawEffect`, `DiscardEffect`
- 카드 타입: `ATTACK`, `SKILL`, `POWER`, `MODULE`
- `tier: int` 필드 — 마켓 가중치 추첨 등급 (1=기본 / 2=중급 / 3=고급)

### 스타터 덱 (10장)
| 카드 | 수량 | 비용 | 효과 |
|------|------|------|------|
| 골드 카드 | 5 | 0 AP | 골드 +1 |
| 베기 | 2 | 1 AP | 보스에게 2 피해 |
| 막기 | 2 | 1 AP | 방어력 +3 |
| 집중 | 1 | 0 AP | 카드 1장 드로우 |

### 자원
- **AP** (최대 3): 카드 사용 비용, 플레이어 턴 시작 시 3으로 리셋
- **골드**: GainGoldEffect로 획득, **턴 종료 시 증발**. 라운드 마켓 구매 + 리롤(3골드)에 사용
- **방어도**: 피해 흡수. **라운드 종료 시 리셋** (한 라운드 5턴 동안 누적 유지)

### 라운드/턴 오더
- 5턴/라운드. 턴1 항상 플레이어
- 턴2~5: `[플레이어, 플레이어, 보스, 보스]` 랜덤 셔플 (보스 3연속 방지)
- MiddleArea에 턴 오더 UI 표시

### 보스 페이즈 시스템
- 3단계 페이즈 (`BossPhaseSystem`) — HP 임계 OR 라운드 임계 중 빠른 쪽 발화, 단방향
- Phase 1→2: HP ≤ 66% 또는 R3 도달 / Phase 2→3: HP ≤ 33% 또는 R5 도달
- 페이즈 전환 시 `%PhaseLabel` 갱신 + 배너 안내

### 라운드 마켓
- 라운드 시작 시 페이즈 가중치 추첨으로 3장 진열
- 구매 즉시 파이프 맨 뒤에 추가 / 리롤: AP 3 또는 골드 3
- **Tier 1** (Phase 1 주력): 강타·굳건한 방패·돌격·명상
- **Tier 2** (Phase 2+ 주력): 참격·강철 의지·속공·재정비

### 슬롯
- **액티브 슬롯 ×2**: MODULE 카드 장착. 슬롯1 = "반격 태세" 기본 장착

### 전사 고유 시스템
- **투기 발산**: 턴 종료 시 남은 AP → 투기 스택 (최대 10). 10스택 → 보스 10 피해 + 방어도 +10
- **반격 태세 모듈**: 보스 턴 종료 시 방어도 1+ 남으면 보스에게 2 피해

## 기술 스택

- **엔진**: Godot 4.6.2 (D3D12, Mobile Renderer, 1920×1080)
- **언어**: GDScript
- **패턴**: Resource + 상속 효과 클래스, GameContext 공유 상태, 시그널 기반 UI, DropZone 드래그&드롭

## 프로젝트 구조

```
resources/cards/
  starter_*.tres            # 스타터 덱 카드 (4종)
  warrior/
    module_counter_stance.tres
    market/                 # 전사 마켓 Tier 1 (4종)
    market/tier2/           # 전사 마켓 Tier 2 (4종)
scenes/
  main/
    title_screen.tscn       # 타이틀 화면 (메인 씬)
    character_select.tscn   # 캐릭터 선택 화면
    main_scene.tscn         # 전투 씬
  cards/card.tscn
  ui/
    game_result_screen.tscn # 승리/패배 결과 화면
scripts/
  main/
    title_screen.gd
    character_select.gd
    main_scene.gd           # 게임 루프, 턴/라운드 관리
    game_context.gd         # 공유 상태 (HP, 블록, Callable)
  bosses/
    boss_phase_system.gd    # 3단계 페이즈 (HP/라운드 OR 트리거)
  characters/warrior/
    rage_system.gd
    counter_stance_ability.gd
  cards/
    card.gd
    card_data.gd
    effects/
    modules/
  ui/
    drop_zone.gd
    resource_bar.gd
    ap_manager.gd
    gold_manager.gd
    market_panel.gd
    game_result_screen.gd
```

## 기획서

자세한 기획 내용은 [GDD.md](GDD.md) 및 [GDD_warrior.md](GDD_warrior.md)를 참고하세요.
