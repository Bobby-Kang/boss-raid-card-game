# Boss Raid Card Game

1:1 보스 레이드 카드 게임 — Godot 4.6.2

> **덱을 섞지 않습니다.** 버린 순서의 역순으로 다시 뽑히므로, 어떤 순서로 카드를 버릴지가 핵심 전략입니다.

## 빠른 시작

Godot 4.6.2 에디터에서 `scenes/main/main_scene.tscn`을 열고 실행합니다.

## 게임 흐름

```
라운드 시작 → 턴 오더 결정 (5턴)
  ├─ 플레이어 턴: AP 3 지급 → 카드 5장 드로우 → 카드 드래그&드롭 → 턴 종료
  └─ 보스 턴: 고정 패턴 공격 (현재: 5 피해)
라운드 종료 → 다음 라운드
```

## 카드 조작

| 행동 | 방법 |
|------|------|
| 카드 사용 | 손패에서 **가운데(플레이존)**으로 드래그 |
| 카드 버리기 | 손패에서 **버린더미**로 드래그 |
| 재화 보관 | 골드 카드를 **예비 슬롯**으로 드래그 (다음 턴 복귀) |
| 모듈 장착 | MODULE 카드를 **액티브 슬롯 1·2**로 드래그 |

## 현재 구현 상태

### 카드 시스템
- `CardData` Resource + `CardEffect` 상속 구조
- 효과 클래스: `DamageEffect`, `BlockEffect`, `GainGoldEffect`, `DrawEffect`, `DiscardEffect`
- 카드 타입: `ATTACK`, `SKILL`, `POWER`, `MODULE`

### 스타터 덱 (10장)
| 카드 | 수량 | 비용 | 효과 |
|------|------|------|------|
| 골드 카드 | 5 | 0 AP | 골드 +1 |
| 베기 | 2 | 1 AP | 보스에게 2 피해 |
| 막기 | 2 | 1 AP | 방어력 +3 |
| 집중 | 1 | 0 AP | 카드 1장 드로우 |

### 자원
- **AP** (최대 3): 카드 사용 비용, 플레이어 턴 시작 시 3으로 리셋
- **골드**: GainGoldEffect로 획득, 턴 종료 시 증발

### 라운드/턴 오더
- 5턴/라운드. 턴1 항상 플레이어
- 턴2~5: `[플레이어, 플레이어, 보스, 보스]` 랜덤 셔플 (보스 3연속 방지)
- MiddleArea에 턴 오더 UI 표시

### 슬롯
- **예비 슬롯**: 골드 카드 1장을 다음 턴으로 이월
- **액티브 슬롯 ×2**: MODULE 카드 장착. 교체 시 기존 모듈은 손패로 복귀

### 전투 수치
- 플레이어 HP 50, 보스 HP 100
- 방어력: 피해를 먼저 흡수, 턴 종료 시 리셋

## 기술 스택

- **엔진**: Godot 4.6.2 (D3D12, Mobile Renderer, 1280×800)
- **언어**: GDScript
- **패턴**: Resource + 상속 효과 클래스, GameContext 공유 상태, 시그널 기반 UI, DropZone 드래그&드롭

## 프로젝트 구조

```
resources/cards/          # .tres 카드 리소스 (4종)
scenes/
  cards/card.tscn         # 카드 노드 (드래그&드롭)
  main/main_scene.tscn    # 메인 전투 씬
  ui/                     # 턴 종료 오버레이, 페이즈 배너
scripts/
  cards/
    card.gd               # 카드 드래그&드롭 로직
    card_data.gd          # CardData Resource 정의
    effects/              # 효과 클래스들
  main/
    main_scene.gd         # 게임 루프, 턴/라운드 관리
    game_context.gd       # 공유 상태 (HP, 블록, Callable)
  ui/
    drop_zone.gd          # DropZone (PLAY/DISCARD/RESERVE/ACTIVE)
    resource_bar.gd       # AP + 골드 UI 통합
    ap_manager.gd
    gold_manager.gd
```

## 기획서

자세한 기획 내용은 [GDD.md](GDD.md)를 참고하세요.
