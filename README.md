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
            └─ 보스 턴: 덱에서 카드 드로우 → 카드 연출(슬램/흡수) → ATTACK 즉시 발동 / POWER 파워 존 배치
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
- 효과 클래스: `DamageEffect`, `BlockEffect`, `BlockDamageEffect`, `GainGoldEffect`, `DrawEffect`, `ExileEffect`
- 카드 타입: `ATTACK`, `SKILL`, `POWER`, `MODULE`
- `tier: int` 필드 — 마켓 가중치 추첨 등급 (1=기본 / 2=중급 / 3=고급)
- **카드 비주얼** — 아트워크를 카드 전체 배경으로 깔고 이름·설명·타입은 반투명 오버레이 (Slay the Spire 스타일)

### 스타터 덱 (10장)
> 시작 시 1회 셔플 → 매 판 다른 시작 (게임 중엔 섞지 않음)

| 카드 | 수량 | 비용 | 효과 |
|------|------|------|------|
| 골드 카드 | 3 | 1 AP | 골드 +3 |
| 베기 | 4 | 1 AP | 보스에게 3 피해 |
| 막기 | 2 | 1 AP | 방어력 +3 |
| 집중 | 1 | 0 AP | 카드 1장 드로우 |

### 자원
- **AP** (최대 3): 카드 사용 비용, 플레이어 턴 시작 시 3으로 리셋. 남은 AP → 전사 투기 스택 (부수 공급)
- **골드** (최대 10): GainGoldEffect로 획득, **턴 종료 시 증발**. 라운드 마켓 구매 + 리롤(3골드)에 사용
- **방어도**: 피해 흡수. **라운드 종료 시 리셋** (한 라운드 내 누적 유지)

### 라운드/턴 오더
- **4턴 고정 교대**: 플레이어 → 보스 → 플레이어 → 보스
- 라운드 경계에서 방어도 리셋, 턴 오더 UI는 MiddleArea에 표시
- **보상형 카드 제거**: 페이즈 전환 시(P1→2, P2→3) "전사의 깨달음" 보상으로 손패/파이프 카드 1장 영구 제거 가능 (스킵 가능). 추가로 마켓 *각인의 의식* 카드(5골드, T2)를 사면 능동적으로 제거 기회 획득 — 카드 자체도 사용 후 소멸. 빌드 농도를 플레이어가 직접 다듬는 도구

### 🕰 타임라인 전쟁 (파이프·보스 덱 상호 조작)
- **파이프 메커니즘 5종**: 🔨단련(돌수록 강화) / 🔀조작(재배치·역행) / 🔗인접(다음 카드 타입 보너스) / 🚩**선봉**(손패 첫 장으로 드로우 시 보너스 — 턴 종료 순서 지정이 직접 보상) / ⏮**보스 타임라인 간섭**
- **보스 덱 간섭 카드 4장**: 밀어내기(다음 예고를 덱 뒤로) · 시간의 족쇄(POWER 카운트 +1) · 파워 브레이커(카운트 2+ POWER 파괴) · 예지의 일격(보스 다음이 공격이면 +6)
- **파이프 UI**: 5장마다 `▼ N턴 뒤 손패` 구분선 — 순서 지정 = 미래 손패 조립이 눈에 보임

### 보스 카드덱 시스템 (에이언즈 엔드 방식)
- Phase1 → Phase2 → Phase3 순서로 덱을 쌓음, 티어 경계 고정. 덱 소진 시 버린 카드 전체 재셔플
- 카드 타입:
  - **ATTACK**: 즉시 실행 후 버린 카드 더미로
  - **POWER**: 파워 존에 배치되어 매 보스 턴마다 카운트다운 -1, 0 도달 시 발동 (다단 효과: `on_draw_effects`/`on_tick_effects`)
- 보스 디버프: **드로우 봉인**, **취약**(받는 피해 ×1.5), **피 냄새**(HP 50% 이하 시 공격 강화)
- 버그베어 카드 총 18장 — 페이즈별 정체성: P1 🐺 추적자(취약·드로우 봉인 깔기) / P2 💢 광폭화(즉발 강타·자기 강화) / P3 💀 광기(큰 즉발). **POWER 3장 (페이즈당 시그니처 1장 — 진짜 필살기)** + ATTACK 15장: 사냥의 시작(피 냄새+10+취약3) / 강철 벽(방어+15·회복+10) / 최후의 발악(28 피해 결정타)
- UI: **3-페이즈 칩 행**(`P1·n / P2·n / P3·n`, 페이즈 색 + 소진 디밍 + 페이즈별 카드 툴팁) / 버린 카드 수 / 파워 존 / 다음 예고(큰 카드)
- **보스 행동 카드 연출** (`BossActionPresenter`): 보스 턴마다 실제 카드를 화면 중앙 큰 카드로 제시 → ATTACK 슬램+임팩트 / POWER 파워존 흡수 / 발동·무효화 별도 연출 (텍스트 배너 대체)
- **카드 페이즈 가시화** (`BossCardDisplay`): 모든 보스 카드 표시에 **좌측 컬러 스트립 + 좌상단 P1/P2/P3 뱃지** — 다음 예고·연출·파워존에서 페이즈 즉시 식별

### 보스 페이즈 시스템
- 3단계 페이즈 (`BossPhaseSystem`) — **HP 임계 트리거만 사용**, 단방향
- Phase 1→2: HP ≤ 66% / Phase 2→3: HP ≤ 33%
- **페이즈 전환 시네마틱**: 페이즈 색 화면 섬광 + 강한 흔들림 + 보스 얼굴 각성 펄스 + 큰 컬러 타이틀(`⚔ PHASE N ⚔`)
- 페이즈 전환 시 `%PhaseLabel` 갱신 + 마켓 가중치 테이블 갱신 + BGM 크로스페이드

### 라운드 마켓 (4-레인)
- 공격 / 방어 / 특수 / 골드 4개 레인, 라운드 시작 시 각 레인에서 페이즈 가중치로 1장씩 추첨
- 구매 즉시 파이프 맨 뒤에 추가 / 리롤: AP 3 또는 골드 3 (횟수 제한 없음)
- 가중치 테이블 (Phase별 T1·T2·T3): P1 `100·0·0` / P2 `20·100·0` / P3 `5·30·100`

### 슬롯
- **액티브 슬롯 ×2**: MODULE 카드 장착. 슬롯1 = "반격 태세" 기본 장착

### 전사 고유 시스템
- **투기 발산**: **공격 카드 사용 시 투기 +1** (주 공급, *휘두를수록 달아오른다*) + 턴 종료 시 남은 AP 치환 (부수). 10스택 → 0 AP로 보스 10 피해 + 방어도 +10
- **반격 태세 모듈**: 보스 턴 종료 시 방어도 1+ 남으면 보스에게 2 피해
- **견고한 갑옷 모듈**: 플레이어 턴 시작 시 방어도 +2 (`IronArmorAbility`)

### 아트워크
- Gemini 생성 이미지 적용: 전사·버그베어 초상화, 스타터 4종(베기·막기·집중·골드), 반격 태세 모듈
- 메인 씬 상단에 버그베어 풀커버 초상화, 캐릭터 선택 화면은 양쪽 초상화 영역 꽉 채움

### UI 테마 (다크 판타지 프리미엄)
- `DarkFantasyTheme` (코드 빌드 Theme) 루트 적용 — 패널/버튼/라벨/구분선 통일 (흑갈색 배경 / 양피지 텍스트 / 금색 액센트)
- 배경 세로 그라데이션 + 가장자리 비네팅, 카드 이미지 mipmap+Linear 필터로 축소 에일리어싱 제거
- 상단 슬림바(라운드 · 턴 인디케이터 · **원형 턴 토큰** · `🛒 상점`) + 1:1 대결 무대 확대 + 하단(자원·손패·파이프)
- **마켓 모달 토글**: `🛒 상점` 버튼으로 여닫는 중앙 팝업 (평소 숨김 → 대결 무대 공간 확보)

### UX 보조 시스템
- **드롭존 가시화**: 카드 드래그 시작 시 모든 드롭존에 라벨 + 색 오버레이 표시 (수용 가능 청색 펄스 / 불가 빨강 디밍)
- **카드 호버 프리뷰**: 손패 카드 위에 커서를 올리면 효과를 분석해 보스 HP/플레이어 블록 옆에 부동 라벨로 미리보기 (`−N` / `+N 🛡` / `+N 드로우` / `+N 💰`)
- **턴 인디케이터 + 원형 토큰**: 화면 상단에 현재 턴 + 4턴 교대 순서를 원형 토큰(플레이어 청/보스 적, 현재 턴 금테)으로 표기
- **컨텍스트 디밍**: 보스 턴 동안 손패/마켓을 어둡게 표시해 입력 불가 상태를 시각화
- **캐릭터 피격 리액션**: 피격 시 얼굴 빨간 플래시 + 스케일 펀치 + Hit-stop (`combat_feedback.gd`)

### 오디오 시스템
- `AudioManager` Autoload + `SfxLibrary` 매핑 구조 — 에셋 미배치 시 조용히 스킵
- BGM 자동 루프 (`.ogg`/`.mp3`/`.wav` 형식별 루프 속성 자동 설정)
- 페이즈 전환 시 BGM 크로스페이드 연출 지원 (현재는 단일 트랙)
- SFX 훅: 카드 드로우/사용, 피격(플레이어/보스), 마켓 구매, 페이즈 전환, 턴 종료 등

## 기술 스택

- **엔진**: Godot 4.6.2 (D3D12, Mobile Renderer, 1920×1080)
- **언어**: GDScript
- **패턴**: Resource + 상속 효과 클래스, GameContext 공유 상태, 시그널 기반 UI, DropZone 드래그&드롭

## 프로젝트 구조

```
assets/art/gemini_image/     # Gemini 생성 아트워크 (초상화·카드 일러스트)
resources/
  bosses/bugbear/
    phase1~3/                # 버그베어 카드 18장 (BossCardData .tres, Phase별 6장)
  cards/
    starter_*.tres           # 스타터 덱 카드 (4종)
    warrior/
      module_counter_stance.tres   # 시작 시 슬롯1 기본 장착
      market/
        attack/ defense/ special/ gold/  # 4-레인, T1·T2 카드 (견고한 갑옷 모듈은 special/market_iron_armor.tres)
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
    game_context.gd          # 공유 상태 (HP, 블록, Callable, 디버프 트래커)
    scene_helpers/           # main_scene에서 분리된 책임 (Node 헬퍼)
      combat_feedback.gd       # 화면 섬광·셰이크·피격 리액션·Hit-stop
      card_hover_preview.gd    # 카드 호버 효과 프리뷰 + 파이프 카드 프리뷰
      exile_animator.gd        # 카드 영구 소멸 연출
      boss_action_presenter.gd # 보스 턴 행동 카드 연출 (슬램/흡수/발동/무효)
  bosses/
    boss_phase_system.gd     # 3단계 페이즈 (HP 임계 트리거, 단방향)
    boss_deck_system.gd      # 에이언즈 엔드 방식 카드덱
    boss_card_data.gd        # BossCardData Resource (다단 POWER 효과)
    boss_card_display.gd     # 보스 카드 시각 위젯 (읽기 전용)
    effects/                 # BossDamage/DrawLock/Vulnerability 등 보스 전용 효과
  characters/warrior/
    rage_system.gd
    counter_stance_ability.gd
    iron_armor_ability.gd
  cards/
    card.gd
    card_data.gd
    effects/
    modules/
  ui/
    drop_zone.gd             # 드래그 시 라벨 오버레이 + accept/reject 시각화
    resource_bar.gd
    ap_manager.gd
    gold_manager.gd
    market_panel.gd          # 4-레인 가중치 추첨
    damage_popup.gd
    game_result_screen.gd
  audio/
    audio_manager.gd         # Autoload — BGM/SFX 라우팅 + 루프 자동
    sfx_library.gd           # SFX 키 → 경로 매핑 + BGM 상수
assets/
  audio/
    Pixel-City-Cruising.ogg  # 메인 BGM
    kenny_audio/             # Kenney SFX 4팩 (CC0)
```

## 기획서

자세한 기획 내용은 [GDD.md](GDD.md) 및 [GDD_warrior.md](GDD_warrior.md)를 참고하세요.

## 크레딧 (Credits)

### 음악 (Music)
- **"Pixel City Cruising"** by Eric Matyas — [soundimage.org](https://soundimage.org/action-4/)
  - Licensed under Creative Commons: By Attribution 4.0
  - https://creativecommons.org/licenses/by/4.0/

### 효과음 (Sound Effects)
- **Kenney Audio Packs** by Kenney — [kenney.nl](https://kenney.nl/)
  - UI Audio / Casino Audio / Impact Sounds / RPG Audio
  - Licensed under CC0 1.0 Universal (Public Domain)
  - https://creativecommons.org/publicdomain/zero/1.0/

### 아트워크 (Artwork)
- 캐릭터 초상화·카드 일러스트: Google Gemini 생성 이미지

### 엔진
- [Godot Engine](https://godotengine.org/) 4.6.2 — MIT License
