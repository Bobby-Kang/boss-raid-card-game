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
            ├─ 라운드 시작 → 마켓 카드 진열(페이즈 가중치 추첨)
            ├─ 플레이어 턴: AP 3 지급 → 카드 5장 드로우 → 드래그&드롭 → 턴 종료
            └─ 보스 턴: 덱에서 카드 드로우 → ATTACK 즉시 발동 / POWER 파워 존 배치
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
- **캐릭터 선택 화면** (`character_select.tscn`): 보스(버그베어) vs 플레이어(전사) 초상화 + 스탯
- **전투 화면** (`main_scene.tscn`): 메인 전투 루프 — 보스 얼굴 / 덱 / 버린 카드 / 파워 존 / 마켓 / 손패 / 파이프
- **결과 화면** (`game_result_screen.tscn`): 승리/패배 연출 + 타이틀 복귀 버튼

### 카드 시스템
- `CardData` Resource + `CardEffect` 상속 구조
- 효과 클래스: `DamageEffect`, `BlockEffect`, `GainGoldEffect`, `DrawEffect`, `DiscardEffect`, `BlockDamageEffect`, `ExileEffect`
- 카드 타입: `ATTACK`, `SKILL`, `POWER`, `MODULE`
- `tier: int` 필드 — 마켓 가중치 추첨 등급 (1=기본 / 2=중급 / 3=고급)
- **카드 비주얼** — 아트워크를 카드 전체 배경으로 깔고 이름·설명·타입은 반투명 오버레이 (Slay the Spire 스타일)

### 스타터 덱 (10장)
| 카드 | 수량 | 비용 | 효과 |
|------|------|------|------|
| 골드 카드 | 5 | 0 AP | 골드 +1 |
| 베기 | 2 | 1 AP | 보스에게 2 피해 |
| 막기 | 2 | 1 AP | 방어력 +3 |
| 집중 | 1 | 0 AP | 카드 1장 드로우 |

### 자원
- **AP** (최대 3): 카드 사용 비용, 플레이어 턴 시작 시 3으로 리셋. 남은 AP → 전사 투기 스택
- **골드** (최대 10): GainGoldEffect로 획득, **턴 종료 시 증발**. 라운드 마켓 구매 + 리롤(3골드)에 사용
- **방어도**: 피해 흡수. **라운드 종료 시 리셋** (한 라운드 내 누적 유지)

### 라운드/턴 오더
- **4턴 고정 교대**: 플레이어 → 보스 → 플레이어 → 보스
- 라운드 경계에서 방어도 리셋, 턴 오더 UI는 MiddleArea에 표시

### 보스 카드덱 시스템 (에이언즈 엔드 방식)
- Phase1 → Phase2 → Phase3 순서로 덱을 쌓음, 티어 경계 고정. 덱 소진 시 버린 카드 전체 재셔플
- 카드 타입:
  - **ATTACK**: 즉시 실행 후 버린 카드 더미로
  - **POWER**: 파워 존에 배치되어 매 보스 턴마다 카운트다운 -1, 0 도달 시 발동
- 버그베어 카드 총 13장 (Phase1: 5장, Phase2: 4장, Phase3: 4장)
- UI: 덱 장수 + 이름 목록 / 버린 카드 수 / 이번 턴 행동 / 파워 존 / 다음 예고

### 보스 페이즈 시스템
- 3단계 페이즈 (`BossPhaseSystem`) — **HP 임계 트리거만 사용**, 단방향
- Phase 1→2: HP ≤ 66% / Phase 2→3: HP ≤ 33%
- 페이즈 전환 시 `%PhaseLabel` 갱신 + 배너 안내 + 마켓 가중치 테이블 갱신

### 라운드 마켓 (4-레인)
- 공격 / 방어 / 특수 / 골드 4개 레인, 라운드 시작 시 각 레인에서 페이즈 가중치로 1장씩 추첨
- 구매 즉시 파이프 맨 뒤에 추가 / 리롤: AP 3 또는 골드 3 (횟수 제한 없음)
- 가중치 테이블 (Phase별 T1·T2·T3): P1 `100·0·0` / P2 `20·100·0` / P3 `5·30·100`

### 슬롯
- **액티브 슬롯 ×2**: MODULE 카드 장착. 슬롯1 = "반격 태세" 기본 장착

### 전사 고유 시스템
- **투기 발산**: 턴 종료 시 남은 AP → 투기 스택 (최대 10). 10스택 → 0 AP로 보스 10 피해 + 방어도 +10
- **반격 태세 모듈**: 보스 턴 종료 시 방어도 1+ 남으면 보스에게 2 피해
- **견고한 갑옷 모듈**: 턴 시작 시 방어도 +1 (`IronArmorAbility`)

### 아트워크
- Gemini 생성 이미지 적용: 전사·버그베어 초상화, 스타터 4종(베기·막기·집중·골드), 반격 태세 모듈
- 메인 씬 상단에 버그베어 풀커버 초상화, 캐릭터 선택 화면은 양쪽 초상화 영역 꽉 채움

## 기술 스택

- **엔진**: Godot 4.6.2 (D3D12, Mobile Renderer, 1920×1080)
- **언어**: GDScript
- **패턴**: Resource + 상속 효과 클래스, GameContext 공유 상태, 시그널 기반 UI, DropZone 드래그&드롭

## 프로젝트 구조

```
assets/art/gemini_image/     # Gemini 생성 아트워크 (초상화·카드 일러스트)
resources/
  bosses/bugbear/
    phase1~3/                # 버그베어 카드 13장 (BossCardData .tres)
  cards/
    starter_*.tres           # 스타터 덱 카드 (4종)
    warrior/
      module_counter_stance.tres
      module_iron_armor.tres
      market/
        attack/ defense/ special/ gold/  # 4-레인, T1·T2 카드
scenes/
  main/
    title_screen.tscn        # 타이틀 화면 (메인 씬)
    character_select.tscn    # 캐릭터 선택 화면
    main_scene.tscn          # 전투 씬
  cards/card.tscn            # 풀커버 아트 + 오버레이 구조
  ui/
    game_result_screen.tscn
    phase_banner.tscn
    end_turn_overlay.tscn
scripts/
  data/
    game_balance.gd          # ★ HP·AP·골드·투기·마켓 비용 수치 일괄 관리
  main/
    title_screen.gd
    character_select.gd
    main_scene.gd            # 게임 루프, 턴/라운드, 드롭 핸들러
    game_context.gd          # 공유 상태 (HP, 블록, Callable)
  bosses/
    boss_phase_system.gd     # 3단계 페이즈 (HP 임계 트리거, 단방향)
    boss_deck_system.gd      # 에이언즈 엔드 방식 카드덱
    boss_card_data.gd        # BossCardData Resource
    effects/                 # BossDamage/Block/ForceDiscard 등 보스 전용 효과
  characters/warrior/
    rage_system.gd
    counter_stance_ability.gd
    iron_armor_ability.gd
  cards/
    card.gd
    card_data.gd
    boss_card_display.gd     # 보스 카드 시각 위젯 (읽기 전용)
    effects/
    modules/
  ui/
    drop_zone.gd
    resource_bar.gd
    ap_manager.gd
    gold_manager.gd
    market_panel.gd          # 4-레인 가중치 추첨
    damage_popup.gd
    game_result_screen.gd
```

## 기획서

자세한 기획 내용은 [GDD.md](GDD.md) 및 [GDD_warrior.md](GDD_warrior.md)를 참고하세요.
