<div align="center">

# opsmith

**Claude Code를 위한 개인 운용 계층(operating layer)**

규칙은 항상 주입되는 문서로 · 반복은 스크립트로 · 검증은 다른 벤더로.
이 세 가지를 `~/Ops/` 한 곳에 모아, 누구나 설치해 쓰도록 만든 것.

![Claude Code](https://img.shields.io/badge/Claude_Code-operating_layer-8A2BE2)
![Python 3](https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white)
![bash](https://img.shields.io/badge/install-bash-4EAA25?logo=gnubash&logoColor=white)
![Dependencies](https://img.shields.io/badge/dependencies-none_(stdlib)-success)
![License](https://img.shields.io/badge/License-MIT-black)

</div>

> **무엇이 아닌가** — opsmith은 스킬·플러그인이 **아닙니다**. 특정 도구에 묶이지 않는
> **규칙·스크립트·훅으로 된 운용 계층**을 `~/Ops`에 설치하고, `~/.claude`에는 훅·권한만 얹습니다.
> 기존 설정을 덮어쓰지 않고 병합하며, 언제든 `uninstall.sh`로 되돌립니다.

---

## 🖥 데모

```console
$ cp config.example.sh config.sh   # 이름·언어·미러대상·사운드를 채운다
$ bash install.sh
설치 완료: ~/Ops · ~/.claude/CLAUDE.md
  단축키: newproj <이름> [dev|deck|hwp|paper|career] · proj <이름> · ops
  메모리 미러: 비활성(config 비어 있음)
  새 zsh: source ~/.zshrc · Claude Code 재시작 시 훅 로드

$ newproj kcc-2026-talk deck
생성 완료: ~/Desktop/Projects/kcc-2026-talk
  CLAUDE.md  @AGENTS.md 임포트 (규칙 스위치)
  → cd 완료

# 이후 어떤 세션을 열든 SessionStart 가드가 규칙을 자동 주입하고,
# 루트에 CLAUDE.md가 없으면 만들어 준다 (막지 않고 경고만)
```

---

## ✨ 핵심 아이디어

- **규칙은 항상 주입되는 문서로** — `~/Ops/AGENTS.md`가 `~/.claude/CLAUDE.md`로 심링크되어 **모든 세션에 자동 주입**. 모델이 "필요할 때 스킬을 호출"하기를 기대하지 않는다
- **폴더는 "마감이 있는가"로 나눈다** — 산출물 형식(PPT·한글·코드)이 아니라 성격으로. 프로젝트 하나가 여러 조각으로 갈라지지 않게
- **기억의 원본은 로컬 네이티브 memory** — 외부 볼트에는 단방향 사본(미러)만 보낸다
- **검증은 다른 벤더 모델로** — 같은 벤더끼리는 편향을 공유한다. 자기검토는 검증으로 치지 않는다
- **더할 땐 측정할 수 있어야 한다** — 이득을 못 재면 단순함이 이긴다

설계 배경 전문은 [`docs/philosophy.md`](docs/philosophy.md) · [`docs/decisions.md`](docs/decisions.md) 참고.

---

## 🧠 컨텍스트는 어떻게 전달되나

```
~/Ops/AGENTS.md ──심링크── ~/.claude/CLAUDE.md        모든 세션에 자동 주입
        │
        ├─ ~/Ops/domains/deck.md    발표자료(.pptx) 작업 시
        ├─ ~/Ops/domains/hwp.md     한글 문서(.hwpx) 작업 시
        ├─ ~/Ops/domains/web.md     웹·앱 개발 시
        ├─ ~/Ops/domains/paper.md   논문·학술 작업 시
        └─ ~/Ops/domains/review.md  검증받을 때
<프로젝트>/CLAUDE.md ──@import── <프로젝트>/AGENTS.md    그 프로젝트에서만 주입
~/.claude/projects/<키>/memory/*.md                     자동 축적 → 외부 볼트로 단방향 미러
```

---

## 🗂 저장소 구조

```
opsmith/
├── ops/                    ~/Ops 로 설치될 템플릿
│   ├── AGENTS.md.tmpl       전역 규칙 (이름·언어 플레이스홀더)
│   ├── domains/            형식별 규칙 (deck·hwp·web·paper·review)
│   ├── bin/                운용 스크립트 9종
│   ├── adr/                되돌리기 어려운 결정 기록 (골격)
│   └── golden/             품질 회귀 골든셋 (예시)
├── claude/                 ~/.claude 에 병합될 훅/권한 스니펫
├── config.example.sh       사용자가 채우는 값 (config.sh 로 복사)
├── install.sh              멱등 설치기
├── uninstall.sh            병합분만 되돌림 (사용자 데이터 보존)
├── docs/                   설계 철학·버린 대안·운용 설명서
└── tests/                  격리 스모크 테스트
```

> `claude/settings.snippet.json`은 예시용입니다 — 안의 `$HOME`은 `install.sh`가 실행 시점에 실제 경로로 치환합니다. 직접 복사하지 말고 반드시 `install.sh`를 통해 설치하세요.

---

## 🚀 빠른 시작

### 1. 요구사항
- [Claude Code](https://code.claude.com)
- Python 3 · bash · git (런타임 외부 의존성 없음 — 표준 라이브러리만)

### 2. 클론 & 설치

```bash
git clone https://github.com/KimHands/opsmith.git
cd opsmith
cp config.example.sh config.sh    # 이름·언어·미러대상·사운드를 채운다
bash install.sh
source ~/.zshrc                    # 단축키 즉시 반영
# Claude Code 재시작 → 훅 로드
```

**멱등 설치** — 여러 번 돌려도 안전하며, 기존 `settings.json`·`.zshrc`를 덮어쓰지 않고 병합합니다(항상 `.bak` 백업).

### 3. 제거

```bash
bash uninstall.sh   # 병합분만 되돌림. ~/Ops 데이터는 보존
```

---

## 🧰 하루 사용법

```bash
newproj my-talk deck     # 규칙에 맞는 새 프로젝트 생성 + 이동
proj my-talk             # 기존 프로젝트로 이동
ops                      # ~/Ops 로 이동
```

새 프로젝트는 폴더명 규칙(ASCII 소문자·숫자·하이픈, **생성 후 개명 금지**)을 강제하고, 루트에 `CLAUDE.md`(→`@AGENTS.md`) 골격을 만듭니다. 세션을 열면 SessionStart 가드가 누락된 `CLAUDE.md`를 자동 생성하고 규칙 위반을 경고합니다(막지는 않음).

---

## 🔧 운용 스크립트 (`ops/bin`)

| 스크립트 | 역할 | 비고 |
|---------|------|------|
| `new-project.sh` | 규칙에 맞는 새 프로젝트 골격 생성 | 이름 규칙 강제 · 옛 memory 충돌 경고 |
| `session-guard.py` | SessionStart 훅 | 누락 `CLAUDE.md` 자동 생성 · 규칙 위반 경고 |
| `mirror-memory.sh` | Stop 훅 | 네이티브 memory → 외부 볼트 단방향 미러 |
| `backup-now.sh` | Desktop·Claude 기억 로컬 백업 | 복원 표본 검증까지 자동 |
| `collect-golden.sh` | 골든셋 응답 수집 | 측정용 (실작업 훼손 금지 형태) |
| `loop-run.sh` | 회귀 측정 루프 | 수집 + 채점표 생성 |
| `loop-score.sh` | 회귀 측정 루프 | 채점 + 직전 대비 회귀 경고 |
| `measure-variance.sh` | 하네스 on/off 응답 분산 측정 | 장치의 순이득 확인 |
| `graph-verify.sh` | 교차검증 루프 | 다른 벤더 모델로 반박·수정 (상한 2회) |

---

## ✅ 검증

```bash
bash tests/install-smoke.sh   # 임시 HOME에서 설치·멱등성 검증 (실제 홈 무해)
```

---

## 📚 문서

| 파일 | 내용 |
|------|------|
| [`docs/philosophy.md`](docs/philosophy.md) | 설계 4원칙 |
| [`docs/decisions.md`](docs/decisions.md) | 버린 대안과 이유 |
| [`docs/WORKFLOW.md`](docs/WORKFLOW.md) | 운용 설명서 (폴더 정책·기록·측정) |

---

## 📄 라이선스

이 프로젝트는 [MIT License](LICENSE)로 배포됩니다.
