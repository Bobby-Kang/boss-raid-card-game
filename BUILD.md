# 빌드 & 배포 가이드

사람들에게 게임을 나눠주기 위한 빌드 방법입니다. **Windows 단일 exe**와 **웹(HTML5)** 두 가지 프리셋이 `export_presets.cfg`에 준비돼 있습니다.

---

## 0. 사전 준비 — Export Template 설치 (최초 1회)

빌드에는 **export template**(빌드용 런타임, ~600MB)이 필요합니다. 아직 설치돼 있지 않으니 한 번만 받으면 됩니다.

1. Godot 에디터로 이 프로젝트 열기
2. 상단 메뉴 **`편집기(Editor)` → `내보내기 템플릿 관리(Manage Export Templates)`**
3. **`다운로드 후 설치(Download and Install)`** 클릭 → 4.6.2 템플릿 자동 다운로드·설치
4. (인터넷 필요, 한 번 받으면 이후 재사용)

> 이 단계만 사람이 직접 해야 합니다. 이후 빌드는 클릭 몇 번 또는 명령 한 줄.

---

## 1. Windows 단일 exe (파일 1개) — 가장 간편한 배포

### 에디터에서
1. **`프로젝트(Project)` → `내보내기(Export)`**
2. 좌측 **`Windows Desktop`** 프리셋 선택
3. **`프로젝트 내보내기(Export Project)`** 클릭
4. 저장 위치 확인(기본 `build/windows/BossRaidCardGame.exe`) → 내보내기
5. 완성! `build/windows/BossRaidCardGame.exe` **한 파일**만 전달하면 됩니다 (PCK 내장 = embed_pck).

> 카톡/USB/디스코드로 그 `.exe` 하나만 주면 상대가 더블클릭으로 바로 실행합니다.
> ⚠️ Windows SmartScreen 경고가 뜰 수 있어요(서명 안 된 exe라 정상) — "추가 정보 → 실행"으로 통과.

### 명령줄(CLI)로 — 에디터 없이
Godot 실행파일 경로를 안다고 가정:
```bash
"<Godot실행파일>" --headless --path "E:/Project/boss-raid-card-game" --export-release "Windows Desktop" "build/windows/BossRaidCardGame.exe"
```

---

## 2. 웹(HTML5) — 링크만 공유 (설치 불필요)

### 에디터에서
1. **`프로젝트 → 내보내기`** → **`Web`** 프리셋 선택 → **`프로젝트 내보내기`**
2. `build/web/` 폴더에 `index.html` 외 여러 파일이 생성됨
3. **`build/web/` 폴더 전체를 zip으로 압축** → [itch.io](https://itch.io) 새 프로젝트에 업로드 (Kind: HTML, "This file will be played in the browser" 체크)
4. itch.io가 준 **링크만 공유** → 누구나 브라우저에서 플레이 (PC·모바일)

### 명령줄(CLI)로
```bash
"<Godot실행파일>" --headless --path "E:/Project/boss-raid-card-game" --export-release "Web" "build/web/index.html"
```

> 웹은 파일이 여러 개라 **폴더째 zip**으로 다루거나 itch.io/웹서버에 올려야 합니다. 로컬에서 `index.html`을 그냥 더블클릭하면 CORS 때문에 안 열리니, itch.io 업로드가 가장 쉬워요.

---

## 참고
- 빌드 산출물(`build/`)은 `.gitignore`에 제외돼 있어 저장소에 안 올라갑니다.
- 아이콘·버전 정보는 `export_presets.cfg`의 `application/*`에서 조정 가능.
- 오디오/아트 에셋은 모두 `res://`로 내장되므로 exe 하나에 전부 포함됩니다.
