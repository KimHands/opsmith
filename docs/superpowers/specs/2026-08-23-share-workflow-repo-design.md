# my-workflow 공유 저장소 — 설계 문서

날짜 2026-08-23 · 상태 초안(사용자 검토 대기)

## 1. 목적

김종건의 개인 Claude Code 운용체계(`~/Ops/` 계층)를 **누구나 clone 후 설치해 쓸 수 있는
저장소**로 만든다. 코드(설치물)와 문서(설계 사고 과정)를 한 저장소에 담는다.

핵심 가치: 남이 파일을 그대로 베끼는 것이 아니라 **"왜 이렇게 설계했는가"를 가져가게** 한다.

## 2. 무엇을 공유하는가 / 무엇을 제외하는가

### 공유 대상 — `~/Ops/` 운용체계 (ccpilot 제외)
- 전역 규칙(`AGENTS.md`)과 형식별 도메인 규칙(`domains/*.md`)
- 자동화 스크립트 11개(`bin/`) — 새 프로젝트 생성, SessionStart 가드, 메모리 미러,
  회귀 측정 루프, 교차검증 루프, 백업
- 기록 체계(`adr/`, `faillog.md`, `golden/`)
- 훅·권한 설정 조각(`~/.claude/settings.json` 병합분)

### 명시적 제외
- **ccpilot 일체.** 링크·언급 포함 전부 제외. 2026-08-13 개편 때 실측 사용량 근거로
  워크플로우에서 의도적으로 비활성화된 별개 프로젝트이므로 이 저장소는 그것을 다루지 않는다.
- 남의 플러그인(superpowers·codex·kesekit 등) — README에서 "설치 권장"으로만 언급, 코드 미포함
- 개인 데이터 전량: 실제 memory·history·sessions·golden runs·실제 골든 문항
- Orca IDE 통합 훅(남의 IDE)

## 3. 패키징 방식 — 설정기반 자동 설치기 (A안, 확정)

수동 배치가 아니라 `config.sh` + `install.sh` 하나로 설치한다.
근거: 이 워크플로우의 핵심 철학이 "규칙은 자동 주입, 수동 단계는 자동화"이며,
faillog에 "손으로 치게 하는 규칙은 결국 안 지켜진다 → 자동화"가 기록돼 있다.
공유물도 같은 원칙을 따라야 일관된다.

멱등·기존설정 보존 병합 패턴을 사용한다(설치를 여러 번 돌려도 안전, 항상 `.bak` 백업).

## 4. 저장소 구조

```
my-workflow/
├── README.md              철학 요약 + 60초 설치 (진입점)
├── LICENSE                MIT
├── config.example.sh      사용자가 채우는 값 (이름·언어·미러대상·사운드 on/off)
├── install.sh             멱등 설치: ~/Ops 생성·심링크·훅/권한 병합·zsh 단축키
├── uninstall.sh           병합분만 되돌림(백업에서 복원)
├── ops/                   → ~/Ops 로 설치될 템플릿
│   ├── AGENTS.md.tmpl        전역 규칙 (이름/언어 플레이스홀더)
│   ├── domains/*.md         deck·hwp·web·paper·review (탈개인화)
│   ├── bin/*                11개 스크립트 ($HOME·$USER 변수화)
│   ├── adr/                 골격 + 예시 1개
│   ├── golden/gold-set.example.md
│   └── faillog.md           빈 골격
├── claude/
│   └── settings.snippet.json  훅 2개 + Read 권한 (installer가 병합)
├── docs/                  "문서" 절반 (왜 이렇게 설계했나)
│   ├── WORKFLOW.md          운용 설명서 (탈개인화)
│   ├── philosophy.md        4대 원칙 (ADR 0001 요약)
│   └── decisions.md         버린 대안과 이유 (ccpilot 이름 없이 일반화)
└── tests/install-smoke.sh   설치 스모크 테스트
```

## 5. 컴포넌트 명세

각 유닛은 하나의 목적을 가지며 독립적으로 이해·테스트된다.

### 5.1 `config.example.sh`
사용자가 `config.sh`로 복사해 채우는 값. 셸 변수 형식.
- `WORKFLOW_NAME` — 사용자 이름(AGENTS.md 치환용). 미설정 시 플레이스홀더 유지
- `WORKFLOW_FIELD` — 소속/분야(선택)
- `WORKFLOW_LANG` — 설명 언어(기본 자유 문구, 예 "한국어")
- `WORKFLOW_MIRROR_DEST` — 메모리 미러 대상 절대경로. **빈 값이면 미러 기능 전체 비활성**
- `WORKFLOW_SOUND` — `on`/`off`. macOS `afplay` 알림음. 비-macOS에서는 무시

### 5.2 `install.sh` (멱등)
1. `config.sh` 존재 확인 — 없으면 복사 안내 후 exit
2. `ops/` → `~/Ops/` 복사. `.tmpl`은 config값으로 치환(`{{NAME}}`·`{{FIELD}}`·`{{LANG}}`).
   `ops/bin/*` 스크립트는 **저장소에 이미 이식 가능하게 작성**돼 있어(하드코딩 경로 없음,
   `$HOME`/`$USER` 파생, mirror의 `key_to_name`도 `$USER` 기반) 복사만 한다
3. `~/.claude/CLAUDE.md` → `~/Ops/AGENTS.md` 심링크. 기존 파일 있으면 `.bak`로 백업 후 교체
4. `~/.claude/settings.json`에 훅 2개(SessionStart guard·Stop mirror)+`Read(~/Ops/**)` 권한
   **병합**. 이미 있으면 중복 추가 안 함(멱등). 병합 전 `settings.json.bak` 저장.
   미러 대상이 비었으면 Stop mirror 훅은 설치하지 않음.
5. `~/.zshrc`에 `newproj`/`proj`/`ops` 단축키를 마커 블록(`# >>> my-workflow >>>` … `# <<<`)으로
   추가. 마커가 이미 있으면 블록만 갱신(재실행 안전)
6. 완료 요약 출력: 설치 위치, 사용 가능한 명령, 재시작 안내

### 5.3 `uninstall.sh`
install이 만든 것만 되돌린다: zshrc 마커 블록 제거, settings 병합분 제거(가능하면 `.bak` 복원),
심링크 원복. `~/Ops/` 사용자 데이터는 지우지 않고 안내만 한다(안전 게이트: 삭제는 사람 확인).

### 5.4 `ops/` 템플릿
현재 `~/Ops/`의 탈개인화 사본. 스크럽 계획은 §6.

### 5.5 `claude/settings.snippet.json`
병합 소스. SessionStart→`$HOME/Ops/bin/session-guard.py`, Stop→`$HOME/Ops/bin/mirror-memory.sh`,
permissions.allow→`Read(//$HOME/Ops/**)`. install.sh가 실제 절대경로로 전개해 병합.

### 5.6 `docs/`
- `philosophy.md` — 4대 원칙: (1) 폴더는 "마감 있는가"로, (2) 규칙은 항상 주입되는 문서로,
  (3) 기억의 원본은 로컬 네이티브 memory, (4) 검증은 다른 벤더로
- `decisions.md` — 버린 대안과 이유(형식기준 폴더·MCP 자동회상·멀티에이전트 상시화·
  측정 안 되는 커스텀 하네스). ccpilot 이름은 쓰지 않고 "커스텀 프리셋 하네스"로 일반화
- `WORKFLOW.md` — 현행 `~/Ops/docs/WORKFLOW.md`의 탈개인화 판

## 6. 탈개인화 / 스크럽 계획

| 대상 | 현재 | 조치 |
|---|---|---|
| `/Users/kimhands/` | 전 파일 하드코딩 | `$HOME` |
| 이름·소속·이메일 | AGENTS.md 실명 | `config.sh`값 치환, 미설정 시 플레이스홀더 |
| iCloud VibeSession 경로 | mirror 스크립트 고정 | `WORKFLOW_MIRROR_DEST`(빈 값=미러 끔) |
| `kimhands` sed 규칙 | mirror `key_to_name` | `$USER` 파생 |
| `afplay` 사운드 | macOS 전용 | 유지 + `WORKFLOW_SOUND` 토글, 비-macOS 무시 |
| Orca 훅 | settings 존재 | 미포함 |
| 실제 골든 문항 | 개인 작업물 | 예시 문항으로 대체 |
| domains/web.md 출처 문구 | "ccpilot 프리셋에서 흡수" | 출처 언급 제거 |

## 7. 안전 / 에러 처리

- 모든 파괴적/되돌리기 어려운 조작 전 백업(`.bak`) — settings·CLAUDE.md·zshrc
- 병합은 멱등: 재설치가 중복이나 손상을 만들지 않는다
- mirror 스크립트의 기존 안전장치(이름충돌 사전검사·락·삭제금지) 보존
- uninstall은 사용자 데이터(`~/Ops/`)를 지우지 않는다 — 삭제는 사람 확인(워크플로우 안전 게이트)
- config 미설정 값은 기능 비활성으로 안전 축약(미러 대상 없음 → 미러 훅 미설치)

## 8. 테스트

`tests/install-smoke.sh`: 임시 `HOME`으로 install.sh 실행 → `~/Ops` 생성·심링크·
settings 병합·zshrc 마커 존재 확인 → 재실행해 멱등성 확인 → uninstall로 원복 확인.
실제 사용자 환경을 건드리지 않도록 `HOME`을 임시 디렉터리로 격리한다.

## 9. 성공 기준

- 깨끗한 계정에서 `git clone && cp config.example.sh config.sh && (값 채움) && bash install.sh`
  만으로 동작하는 운용체계가 선다
- install.sh를 두 번 돌려도 손상이 없다(멱등)
- 저장소 어디에도 실명·개인경로·개인 데이터·ccpilot 언급이 없다
- docs/만 읽어도 "왜 이렇게 설계했는가"가 전달된다

## 10. 범위 밖(YAGNI)

- Linux/Windows 완전 지원(1차는 macOS 기준, 비-macOS는 사운드만 무시하는 수준)
- 미러 대상의 Obsidian 외 백엔드
- GUI/TUI 설치기
- ccpilot 관련 일체
