# Boss Raid Card Game

1:1 보스 레이드 카드 게임 — Godot 4.6

## 개요

덱을 **섞지 않는** 카드 게임입니다. 버린 카드의 순서가 그대로 다음 드로우 순서가 되므로, 매 턴 어떤 순서로 카드를 버릴지가 핵심 전략입니다.

## 현재 구현된 기능

- **카드 시스템**: CardData 리소스 + 효과 클래스 패턴 (데미지, 방어, 금 획득, 마나 획득, 드로우, 밑장빼기)
- **스타터 덱 10장**: 엽전 생성 x5, 화염부 x2, 부적 방패 x2, 밑장 빼기 x1
- **턴 사이클**: 드로우 → 카드 사용 → 턴 종료(버리기 순서 선택) → 보스 차례 → 드로우
- **자원 관리**: 금/마나 오브 UI (최대 10)
- **전투 UI**: 플레이어/보스 HP 및 방어력 표시
- **페이즈 배너**: 보스 차례/플레이어 차례 전환 시 화면 중앙 알림

## 기술 스택

- **엔진**: Godot 4.6.2 (D3D12, Mobile Renderer)
- **해상도**: 1280x800, stretch mode canvas_items
- **패턴**: CardData Resource + CardEffect 상속 구조, GameContext 공유 상태, 시그널 기반 UI 갱신

## 프로젝트 구조

```
├── assets/art/          # 카드 아트워크, 카드 뒷면 스프라이트
├── resources/cards/     # 카드 데이터 (.tres)
├── scenes/
│   ├── cards/           # 카드 씬
│   ├── main/            # 메인 전투 씬
│   └── ui/              # 턴 종료 오버레이, 페이즈 배너
└── scripts/
    ├── cards/           # 카드 로직, CardData, 효과 클래스
    │   └── effects/     # DamageEffect, BlockEffect 등
    ├── main/            # 메인 씬 컨트롤러, GameContext
    └── ui/              # 자원 바, 골드/마나 매니저, 오버레이
```
