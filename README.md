# Boss Raid Card Game

1:1 보스 레이드 카드 게임 — Godot 4.6

## 개요

덱을 **섞지 않는** 카드 게임입니다 (Aeon's End 방식). 버린 카드의 역순으로 다시 뽑으므로, 매 턴 어떤 순서로 카드를 버릴지가 핵심 전략입니다.

카드를 **드래그&드롭**으로 사용합니다. 가운데 영역에 드롭하면 카드를 사용하고, 버린더미에 드롭하면 효과 없이 버립니다.

## 구현된 기능

- **드래그&드롭 카드 사용**: 가운데 플레이존 드롭 → 사용 / 버린더미 드롭 → 버리기
- **AP 시스템**: 최대 3 AP, 플레이어 턴 시작 시 리셋. 카드 비용만큼 소모
- **골드 시스템**: 재화 카드로 획득, 턴 종료 시 증발
- **스타터 덱 10장**: 골드 카드 x5, 베기(1AP/2데미지) x2, 막기(1AP/3방어) x2, 집중(드로우1) x1
- **라운드/턴 오더 시스템**: 5턴/라운드. 턴1 항상 플레이어, 턴2~5는 [플레이어x2, 보스x2] 랜덤 배치 (보스 3연속 방지)
- **MiddleArea UI**: 라운드 정보 + 턴 오더 표시 / 라운드 마켓(예정) / 행동 로그(예정)
- **예비 슬롯**: 재화 카드 1장을 다음 턴으로 이월
- **액티브 슬롯**: MODULE 타입 카드 2장 장착 (장착 시 기존 모듈은 손패로 복귀)
- **전투 UI**: 플레이어/보스 HP·방어력 표시, 페이즈 배너

## 기술 스택

- **엔진**: Godot 4.6.2 (D3D12, Mobile Renderer)
- **해상도**: 1280x800, stretch mode canvas_items
- **패턴**: CardData Resource + CardEffect 상속, GameContext 공유 상태, 시그널 기반 UI 갱신, DropZone 드래그&드롭

## 프로젝트 구조

```
├── resources/cards/     # 카드 데이터 (.tres) — 4종
├── scenes/
│   ├── cards/           # 카드 씬 (드래그&드롭)
│   ├── main/            # 메인 전투 씬
│   └── ui/              # 턴 종료 오버레이, 페이즈 배너
└── scripts/
    ├── cards/           # 카드 로직, CardData, 효과 클래스
    │   └── effects/     # DamageEffect, BlockEffect, GainGoldEffect, DrawEffect 등
    ├── main/            # 메인 씬 컨트롤러, GameContext
    └── ui/              # ResourceBar, ApManager, GoldManager, DropZone
```

## 개발 환경

Claude Code + Godot MCP(`gopeak`) 로 개발. `.claude/` 디렉토리에 훅 및 설정 포함.
