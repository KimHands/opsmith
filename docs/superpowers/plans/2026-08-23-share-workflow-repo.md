# my-workflow 공유 저장소 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 김종건의 `~/Ops/` Claude Code 운용체계를 누구나 clone·설치해 쓸 수 있는 탈개인화 저장소로 패키징한다.

**Architecture:** 저장소 안에 이식 가능하게 작성된 `ops/` 템플릿 + `~/.claude` 병합 조각(`claude/`)을 두고, `config.sh`를 읽어 `install.sh` 하나가 `~/Ops` 생성·심링크·훅/권한 멱등 병합·zsh 단축키까지 처리한다. 별도 `docs/`가 설계 사고 과정을 전달한다.

**Tech Stack:** Bash (install/uninstall/scripts), Python 3 stdlib (session-guard, settings 병합), Markdown (규칙·문서). 런타임 외부 의존성 없음.

## Global Constraints

- 저장소 어디에도 실명(`김종건`)·소속(`순천향`)·개인경로(`kimhands`)·개인 데이터·`VibeSession`·`ccpilot`·개인 프로젝트명(`labplatform` 등)이 남아선 안 된다 — Task 8에서 grep 게이트로 강제
- 모든 경로는 `$HOME`/`$USER` 파생. 하드코딩 절대경로 금지
- 되돌리기 어려운 조작(settings·CLAUDE.md·zshrc 변경) 전 반드시 `.bak` 백업
- `install.sh`는 멱등: 두 번 돌려도 중복·손상 없음
- 미포함: ccpilot 일체(링크·언급 포함), 남의 플러그인 코드, Orca 훅, 일회성 이사 스크립트(`dryrun-migration.py`·`migrate-one.sh`)
- 설명 문구 언어는 한국어 기준(원본 유지)
- 대상 플랫폼 1차: macOS. 비-macOS는 사운드 기능만 무시(설치는 진행)

---

### Task 1: 저장소 스캐폴드 + 라이선스 + config 예시

**Files:**
- Create: `LICENSE`
- Create: `.gitignore`
- Create: `config.example.sh`
- Create: 디렉터리 `ops/domains/`, `ops/bin/`, `ops/adr/`, `ops/golden/`, `claude/`, `docs/`, `tests/`

**Interfaces:**
- Produces: `config.example.sh`가 정의하는 env 변수 — `WORKFLOW_NAME`, `WORKFLOW_FIELD`, `WORKFLOW_LANG`, `WORKFLOW_MIRROR_DEST`, `WORKFLOW_SOUND`. 이후 모든 Task가 이 변수명을 참조한다.

- [ ] **Step 1: 디렉터리 골격 생성**

Run:
```bash
cd ~/Desktop/Projects/my-workflow
mkdir -p ops/domains ops/bin ops/adr ops/golden claude docs tests
```

- [ ] **Step 2: LICENSE (MIT) 작성**

`LICENSE` 내용 (연도·저작권자는 일반화):
```
MIT License

Copyright (c) 2026 my-workflow contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: .gitignore 작성**

`.gitignore` 내용:
```
config.sh
*.bak
__pycache__/
.DS_Store
```

- [ ] **Step 4: config.example.sh 작성**

`config.example.sh` 내용:
```bash
# my-workflow 설정. 이 파일을 config.sh 로 복사해 값을 채운 뒤 install.sh 를 실행하세요.
#   cp config.example.sh config.sh

# 전역 규칙(AGENTS.md)에 들어갈 소개. 비워두면 플레이스홀더가 남습니다.
WORKFLOW_NAME=""          # 예: 홍길동
WORKFLOW_FIELD=""         # 예: OO대학교 컴퓨터공학과 (선택)
WORKFLOW_LANG="한국어"     # 설명 언어

# 네이티브 memory를 미러할 대상 절대경로. 비우면 미러 기능을 설치하지 않습니다.
#   예: "$HOME/Library/Mobile Documents/com~apple~CloudDocs/MyVault/50_PROJECTS"
WORKFLOW_MIRROR_DEST=""

# 세션 종료/알림 시 소리(macOS afplay). on|off. 비-macOS에서는 무시됩니다.
WORKFLOW_SOUND="off"
```

- [ ] **Step 5: Commit**

```bash
git add LICENSE .gitignore config.example.sh
git commit -m "chore: 저장소 스캐폴드 + MIT 라이선스 + config 예시"
```

---

### Task 2: ops 규칙 문서 이식 (탈개인화)

**Files:**
- Create: `ops/AGENTS.md.tmpl`
- Create: `ops/domains/deck.md`, `ops/domains/hwp.md`, `ops/domains/paper.md`, `ops/domains/web.md`, `ops/domains/review.md`
- Create: `ops/faillog.md`, `ops/adr/0000-example.md`, `ops/golden/gold-set.example.md`

**Interfaces:**
- Produces: `ops/AGENTS.md.tmpl` — `{{NAME}}`·`{{FIELD}}`·`{{LANG}}` 3개 플레이스홀더를 포함. Task 5의 install.sh가 이를 치환해 `~/Ops/AGENTS.md`를 만든다.

- [ ] **Step 1: AGENTS.md.tmpl 작성**

원본 `~/Ops/AGENTS.md`를 복사하되 §사용자 블록만 치환. `ops/AGENTS.md.tmpl` 전체 내용:
```markdown
# 운용 규칙 (전역)

외운 지식 말고 이 문서를 먼저 보고 판단할 것.

## 사용자
{{NAME}}. {{FIELD}}. 설명은 {{LANG}}로.
코드 변경 전에 무엇을 할지 먼저 설명하고, 중요한 변경이나 되돌리기 어려운 변경은 실행 전에 한 번 더 확인한다.

## 코딩 스타일
- 함수는 가능하면 짧게
- 변수명은 의미가 명확하게
- 주석보다는 코드 자체가 읽기 쉽도록

## 폴더 규칙
- `~/Desktop/Projects/<이름>/` — 마감·제출·발표가 있는 것. 폴더 하나 = 산출물 하나
- `~/Desktop/Career/` — 끝이 없는 것 (진로·이력·영업)
- `~/Desktop/Inbox/` — 미분류. 2주 넘으면 승격 아니면 삭제
- `~/Ops/` — 운용 계층. 경로 불변
- **새 프로젝트를 만들면 루트에 `CLAUDE.md`를 만들고 첫 줄에 `@AGENTS.md`를 넣는다**(없으면 프로젝트 규칙이 주입되지 않음)
- **프로젝트 루트 폴더명**은 ASCII 소문자·숫자·하이픈만. **생성 후 개명 금지**(memory가 경로에 묶임)
  (하위 파일·폴더명은 자유. 한글 파일명 무방)
- 세션은 **항상 프로젝트 루트**에서 연다. 서브폴더에서 열면 기억이 갈라진다

## 산출물 형식별 규칙 — 해당 작업 시 그 파일을 먼저 읽을 것
- 발표자료(.pptx) → `~/Ops/domains/deck.md`
- 한글 문서(.hwpx) → `~/Ops/domains/hwp.md`
- 웹·앱 개발 → `~/Ops/domains/web.md`
- 논문·학술 → `~/Ops/domains/paper.md`

## 안전 게이트 — 실행 전 반드시 사람 확인
결제·정산 / 삭제(파일·DB·인프라) / 외부 발송 / 외부 게시·배포 / 권한 변경

## 검증
자기검토는 검증으로 치지 않는다. 되돌리기 어려운 변경의 리뷰는 다른 벤더 모델로 받는다.
절차: `~/Ops/domains/review.md`

## 기록
- 되돌리기 어려운 결정 → `~/Ops/adr/`
- "해봤는데 안 됨" → `~/Ops/faillog.md` 한 줄
```

- [ ] **Step 2: domains 5개 복사 + web.md 스크럽**

Run (deck·hwp·paper·review는 개인정보 없음 — 그대로 복사):
```bash
cp ~/Ops/domains/deck.md   ops/domains/deck.md
cp ~/Ops/domains/hwp.md    ops/domains/hwp.md
cp ~/Ops/domains/paper.md  ops/domains/paper.md
cp ~/Ops/domains/review.md ops/domains/review.md
cp ~/Ops/domains/web.md    ops/domains/web.md
```
그다음 `ops/domains/web.md`에서 ccpilot 출처 문구 제거 — 아래 줄을
```
## 단계별 도구 배치 (ccpilot 프리셋에서 흡수)
```
다음으로 치환:
```
## 단계별 도구 배치
```

- [ ] **Step 3: faillog 빈 골격 작성**

`ops/faillog.md` 내용:
```markdown
# 실패 로그

형식: `YYYY-MM-DD 무엇을 시도 → 왜 안 됐나`

- (여기에 "해봤는데 안 됨"을 한 줄씩 남깁니다. 월 1회 읽고 반복 패턴을 봅니다.)
```

- [ ] **Step 4: ADR 예시 골격 작성**

`ops/adr/0000-example.md` 내용:
```markdown
# ADR 0000 — (예시) 되돌리기 어려운 결정의 기록 틀

날짜 YYYY-MM-DD · 상태 초안|확정

## 결정
1. 무엇을 정했는가

## 버린 대안과 이유
| 대안 | 기각 사유 |
|---|---|
| (버린 것) | (왜) |

## 결과
- 무엇이 달라지는가
```

- [ ] **Step 5: 골든셋 예시 작성**

`ops/golden/gold-set.example.md` 내용:
```markdown
# 골든셋 (예시)

품질 회귀를 재기 위한 고정 질문 모음. **실제 작업물을 훼손하지 않도록 "방법만 설명, 실행 금지" 형태로** 만든다.
"확정성"과 "정확성"을 분리해서 묻는다(확신에 찬 오답에 점수를 주지 않기 위해).

- G1. (예) 새 발표자료를 만들 때 어떤 스킬을 어떤 순서로 부르는지 설명하라. 실행하지 말 것.
- G2. (예) .hwpx 파일의 참고문헌 번호를 다시 매기는 안전한 방법을 설명하라. 실행하지 말 것.
```

- [ ] **Step 6: Commit**

```bash
git add ops/AGENTS.md.tmpl ops/domains ops/faillog.md ops/adr ops/golden
git commit -m "feat: ops 규칙 문서 이식 (탈개인화)"
```

---

### Task 3: ops/bin 스크립트 이식 (이식 가능하게)

**Files:**
- Create: `ops/bin/session-guard.py`, `ops/bin/new-project.sh`, `ops/bin/mirror-memory.sh`, `ops/bin/backup-now.sh`, `ops/bin/collect-golden.sh`, `ops/bin/loop-run.sh`, `ops/bin/loop-score.sh`, `ops/bin/measure-variance.sh`, `ops/bin/graph-verify.sh`

**Interfaces:**
- Produces: `ops/bin/session-guard.py`(SessionStart 훅 진입점), `ops/bin/mirror-memory.sh`(Stop 훅 진입점; `~/Ops/config.sh`를 소싱해 `WORKFLOW_MIRROR_DEST` 사용), `ops/bin/new-project.sh`(마지막 stdout 줄에 `CD:<경로>` 출력 — Task 5 zsh 함수가 파싱). Task 5의 settings 병합이 앞 두 경로를 참조한다.

- [ ] **Step 1: 개인정보 없는 스크립트 6개 그대로 복사**

Run (이미 `$HOME` 파생·개인정보 없음 — 확인됨):
```bash
cp ~/Ops/bin/session-guard.py   ops/bin/
cp ~/Ops/bin/collect-golden.sh  ops/bin/
cp ~/Ops/bin/loop-run.sh        ops/bin/
cp ~/Ops/bin/loop-score.sh      ops/bin/
cp ~/Ops/bin/measure-variance.sh ops/bin/
cp ~/Ops/bin/graph-verify.sh    ops/bin/
```

- [ ] **Step 2: new-project.sh 복사 + CD 마커 추가**

Run:
```bash
cp ~/Ops/bin/new-project.sh ops/bin/new-project.sh
```
그다음 `ops/bin/new-project.sh` 마지막의
```
echo "  cd $DIR"
```
를 다음으로 치환(zsh 함수가 파싱할 기계용 줄 추가):
```
echo "  cd $DIR"
echo "CD:$DIR"
```

- [ ] **Step 3: mirror-memory.sh 이식 — config 소싱 + HOME 파생 키**

`ops/bin/mirror-memory.sh` 전체 내용(원본에서 VAULT_ROOT를 config로, `key_to_name`을 `$HOME` 파생으로 교체):
```bash
#!/bin/bash
# 네이티브 memory를 외부 볼트로 단방향 미러한다.
# 원본은 항상 ~/.claude/projects/<키>/memory. 볼트 쪽 편집은 반영되지 않는다(의도된 제약).
# Stop 훅에서 async로 자동 실행되므로 조용히 실패하면 안 된다 → 로그와 락을 둔다.
set -euo pipefail

# 미러 대상은 설치 시 저장된 config에서 읽는다. 비어 있으면 아무것도 하지 않는다.
[ -f "$HOME/Ops/config.sh" ] && . "$HOME/Ops/config.sh"
: "${WORKFLOW_MIRROR_DEST:=}"
[ -n "$WORKFLOW_MIRROR_DEST" ] || exit 0

VAULT="$WORKFLOW_MIRROR_DEST"
DB="$HOME/.claude/projects"
LOG="$HOME/Ops/golden/runs/mirror.log"
LOCK="$HOME/Ops/.mirror.lock"
HOME_KEY=$(printf '%s' "$HOME" | sed 's/[^A-Za-z0-9]/-/g')

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG"; }
die() { log "FAIL $*"; exit 1; }

mkdir -p "$(dirname "$LOG")"

if ! mkdir "$LOCK" 2>/dev/null; then log "SKIP 다른 미러가 실행 중"; exit 0; fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

key_to_name() {
  printf '%s' "$1" | sed \
    -e "s|^${HOME_KEY}-Desktop-Projects-||" \
    -e "s|^${HOME_KEY}-Desktop-Career-|career-|" \
    -e "s|^${HOME_KEY}-Desktop-|desktop-|" \
    -e "s|^${HOME_KEY}\$|_global|" \
    -e "s|^${HOME_KEY}-|home-|" \
    -e 's|^-*||'
}

declare -a NAMES=() KEYS=()
for d in "$DB"/*/memory; do
  [ -d "$d" ] || continue
  compgen -G "$d/*.md" >/dev/null || continue
  k=$(basename "$(dirname "$d")"); n=$(key_to_name "$k")
  [ -n "$n" ] || n="$k"
  for existing in "${NAMES[@]:-}"; do
    [ "$existing" = "$n" ] && die "이름 충돌: '$n' — 키 여러 개가 같은 볼트 폴더로 매핑됨. 미러 중단(삭제 안 함)"
  done
  NAMES+=("$n"); KEYS+=("$k")
done
[ "${#KEYS[@]}" -gt 0 ] || { log "OK 미러 대상 없음"; exit 0; }

mkdir -p "$VAULT"
fail=0
for i in "${!KEYS[@]}"; do
  src="$DB/${KEYS[$i]}/memory"; dst="$VAULT/${NAMES[$i]}"
  mkdir -p "$dst"
  if ! rsync -a --delete "$src"/ "$dst"/ 2>>"$LOG"; then
    log "FAIL rsync ${KEYS[$i]} → ${NAMES[$i]}"; fail=$((fail+1))
  fi
done

for d in "$VAULT"/*/; do
  [ -d "$d" ] || continue
  n=$(basename "$d"); found=0
  for x in "${NAMES[@]}"; do [ "$x" = "$n" ] && found=1 && break; done
  [ "$found" = "0" ] && log "WARN 볼트 고아 폴더(원본 없음, 보존함): $n"
done

if [ "$fail" -gt 0 ]; then log "DONE 프로젝트 ${#KEYS[@]}개 중 ${fail}개 실패"; exit 1; fi
log "OK 프로젝트 ${#KEYS[@]}개 미러 완료"
echo "미러 완료: 프로젝트 ${#KEYS[@]}개 → $VAULT"
```

- [ ] **Step 4: backup-now.sh 이식 — 복원검증을 일반화**

원본 `~/Ops/bin/backup-now.sh`를 복사한 뒤, 하드코딩된 `labplatform`/`-Users-kimhands-` 복원검증 블록(원본 20~29행)을 아래로 교체. `ops/bin/backup-now.sh`의 해당 블록:
```bash
# 복원 표본 검증 — memory가 있는 아무 프로젝트 하나를 골라 왕복 검증한다
T=$(mktemp -d)
SAMPLE=$(find "$HOME/.claude/projects" -maxdepth 2 -type d -name memory 2>/dev/null | head -1)
if [ -n "$SAMPLE" ]; then
  REL="${SAMPLE#"$HOME"/.claude/}"        # 예: projects/<키>/memory
  tar -xzf "$B/claude-projects-$D.tar.gz" -C "$T" "$REL" 2>/dev/null || true
  if diff -rq "$T/$REL" "$SAMPLE" >/dev/null 2>&1; then
    log "복원 검증 통과 ($REL)"
  else
    log "WARN 복원 검증 실패 — 백업을 신뢰하지 말 것"
  fi
else
  log "복원 검증 건너뜀 — memory 표본 없음"
fi
rm -rf "$T"
```

- [ ] **Step 5: 실행권한 부여 + 개인정보 게이트**

Run:
```bash
chmod +x ops/bin/*.sh ops/bin/*.py
! grep -rn "kimhands\|VibeSession\|ccpilot\|labplatform\|김종건\|순천향\|Project/Setting" ops/bin
```
Expected: grep이 아무것도 못 찾아 종료코드 0 (앞의 `!`로 성공 처리). 뭔가 찍히면 실패로 보고 스크럽.

- [ ] **Step 6: Commit**

```bash
git add ops/bin
git commit -m "feat: ops/bin 스크립트 9종 이식 (경로 이식성 확보, 일회성 이사 도구 제외)"
```

---

### Task 4: claude/settings.snippet.json (병합 소스)

**Files:**
- Create: `claude/settings.snippet.json`

**Interfaces:**
- Produces: `claude/settings.snippet.json` — install.sh가 읽어 사용자 `~/.claude/settings.json`에 병합할 훅/권한의 참조 정의. `$HOME`은 리터럴 문자열이며 install.sh가 실제 경로로 전개한다.

- [ ] **Step 1: 스니펫 작성**

`claude/settings.snippet.json` 내용(설치기가 참고하는 명세; 실제 병합은 Task 5의 python이 수행):
```json
{
  "permissions": {
    "allow": ["Read(//$HOME/Ops/**)"]
  },
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "python3 $HOME/Ops/bin/session-guard.py" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "$HOME/Ops/bin/mirror-memory.sh", "async": true } ] }
    ]
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add claude/settings.snippet.json
git commit -m "feat: settings 병합 스니펫 (SessionStart 가드 + Stop 미러 + Read 권한)"
```

---

### Task 5: install.sh (멱등 설치) + 스모크 테스트

**Files:**
- Create: `install.sh`
- Create: `tests/install-smoke.sh`

**Interfaces:**
- Consumes: `config.sh`(Task 1의 변수), `ops/`(Task 2·3), `claude/settings.snippet.json`(Task 4)
- Produces: `install.sh`가 만든 `~/Ops/`, `~/.claude/CLAUDE.md` 심링크, 병합된 `~/.claude/settings.json`, `~/.zshrc` 마커 블록. Task 6의 uninstall이 같은 마커·백업 규약을 되돌린다.

- [ ] **Step 1: 스모크 테스트 먼저 작성 (실패하는 상태)**

`tests/install-smoke.sh` 내용:
```bash
#!/usr/bin/env bash
# 격리된 임시 HOME에서 install.sh를 돌려 결과와 멱등성을 검증한다. 실제 홈을 건드리지 않는다.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
mkdir -p "$HOME"

WORK="$TMP/repo"
cp -R "$REPO" "$WORK"
cd "$WORK"
cat > config.sh <<'EOF'
WORKFLOW_NAME="테스트유저"
WORKFLOW_FIELD="테스트분야"
WORKFLOW_LANG="한국어"
WORKFLOW_MIRROR_DEST="$HOME/vault"
WORKFLOW_SOUND="off"
EOF

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; exit 1; }

bash install.sh >/dev/null

[ -f "$HOME/Ops/AGENTS.md" ] || fail "Ops/AGENTS.md 없음"
grep -q "테스트유저" "$HOME/Ops/AGENTS.md" || fail "이름 치환 안 됨"
[ ! -f "$HOME/Ops/AGENTS.md.tmpl" ] || fail "tmpl이 남음"
[ -L "$HOME/.claude/CLAUDE.md" ] || fail "CLAUDE.md 심링크 없음"
[ -f "$HOME/Ops/bin/mirror-memory.sh" ] || fail "bin 미복사"
python3 -c "import json,os; d=json.load(open(os.environ['HOME']+'/.claude/settings.json')); \
  assert any('session-guard' in h['command'] for b in d['hooks']['SessionStart'] for h in b['hooks']), 'guard 훅 없음'; \
  assert any('mirror-memory' in h['command'] for b in d['hooks']['Stop'] for h in b['hooks']), 'mirror 훅 없음'; \
  assert any('Ops' in p for p in d['permissions']['allow']), 'Read 권한 없음'" || fail "settings 병합 검증 실패"
grep -q ">>> my-workflow >>>" "$HOME/.zshrc" || fail "zshrc 마커 없음"
pass "1차 설치"

# 멱등성: 다시 돌려도 훅/마커가 중복되지 않아야 한다
bash install.sh >/dev/null
SC=$(python3 -c "import json,os; d=json.load(open(os.environ['HOME']+'/.claude/settings.json')); \
  print(sum('session-guard' in h['command'] for b in d['hooks']['SessionStart'] for h in b['hooks']))")
[ "$SC" = "1" ] || fail "멱등성 위반: guard 훅 $SC개"
MC=$(grep -c ">>> my-workflow >>>" "$HOME/.zshrc")
[ "$MC" = "1" ] || fail "멱등성 위반: zshrc 마커 $MC개"
pass "멱등성"

echo "SMOKE OK"
```

- [ ] **Step 2: 테스트 실행해 실패 확인**

Run: `bash tests/install-smoke.sh`
Expected: FAIL — `install.sh`가 아직 없어 `bash install.sh`에서 중단.

- [ ] **Step 3: install.sh 작성**

`install.sh` 내용:
```bash
#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$REPO/config.sh"
[ -f "$CONFIG" ] || { echo "config.sh 없음 → cp config.example.sh config.sh 후 값을 채우세요."; exit 1; }
# shellcheck disable=SC1090
. "$CONFIG"
: "${WORKFLOW_NAME:=}"; : "${WORKFLOW_FIELD:=}"; : "${WORKFLOW_LANG:=한국어}"
: "${WORKFLOW_MIRROR_DEST:=}"; : "${WORKFLOW_SOUND:=off}"

OPS="$HOME/Ops"; CDIR="$HOME/.claude"
mkdir -p "$OPS" "$CDIR"

# 1) ops/ 복사 + tmpl 치환
cp -R "$REPO/ops/." "$OPS/"
NAME="${WORKFLOW_NAME:-사용자}"; FIELD="${WORKFLOW_FIELD:-분야 미기재}"
sed -e "s|{{NAME}}|$NAME|g" -e "s|{{FIELD}}|$FIELD|g" -e "s|{{LANG}}|$WORKFLOW_LANG|g" \
  "$OPS/AGENTS.md.tmpl" > "$OPS/AGENTS.md"
rm -f "$OPS/AGENTS.md.tmpl"
chmod +x "$OPS"/bin/*.sh "$OPS"/bin/*.py 2>/dev/null || true
cp "$CONFIG" "$OPS/config.sh"      # mirror 스크립트가 소싱

# 2) ~/.claude/CLAUDE.md → ~/Ops/AGENTS.md 심링크 (기존 실파일은 백업)
LINK="$CDIR/CLAUDE.md"
if [ -e "$LINK" ] && [ ! -L "$LINK" ]; then cp "$LINK" "$LINK.bak"; fi
ln -sfn "$OPS/AGENTS.md" "$LINK"

# 3) settings.json 병합 (멱등, .bak 백업)
SETTINGS="$CDIR/settings.json" MIRROR="$WORKFLOW_MIRROR_DEST" SOUND="$WORKFLOW_SOUND" \
python3 - <<'PY'
import json, os
p = os.environ["SETTINGS"]; home = os.environ["HOME"]
mirror = os.environ.get("MIRROR",""); sound = os.environ.get("SOUND","off")
try:
    with open(p) as f: d = json.load(f)
except (FileNotFoundError, ValueError):
    d = {}
if os.path.exists(p):
    with open(p+".bak","w") as f: json.dump(d, f, ensure_ascii=False, indent=1)
d.setdefault("permissions", {}).setdefault("allow", [])
d.setdefault("hooks", {})

def has_cmd(event, needle):
    for block in d["hooks"].get(event, []):
        for h in block.get("hooks", []):
            if needle in h.get("command",""): return True
    return False

def add(event, cmd, extra=None):
    if has_cmd(event, cmd.split()[0] if " " in cmd else cmd): return
    hook = {"type":"command","command":cmd}
    if extra: hook.update(extra)
    d["hooks"].setdefault(event, []).append({"hooks":[hook]})

perm = f"Read(//{home}/Ops/**)"
if perm not in d["permissions"]["allow"]:
    d["permissions"]["allow"].append(perm)

if not has_cmd("SessionStart", "session-guard.py"):
    add("SessionStart", f"python3 {home}/Ops/bin/session-guard.py")
if mirror and not has_cmd("Stop", "mirror-memory.sh"):
    add("Stop", f"{home}/Ops/bin/mirror-memory.sh", {"async": True})
if sound == "on":
    if not has_cmd("Stop", "afplay /System/Library/Sounds/Glass.aiff"):
        add("Stop", "afplay /System/Library/Sounds/Glass.aiff", {"async": True})
    if not has_cmd("Notification", "afplay /System/Library/Sounds/Ping.aiff"):
        add("Notification", "afplay /System/Library/Sounds/Ping.aiff", {"async": True})

with open(p,"w") as f: json.dump(d, f, ensure_ascii=False, indent=1)
print("settings 병합 완료")
PY

# 4) ~/.zshrc 단축키 (마커 블록, 재실행 안전)
ZRC="$HOME/.zshrc"; A="# >>> my-workflow >>>"; B="# <<< my-workflow <<<"
touch "$ZRC"
if grep -qF "$A" "$ZRC"; then
  awk -v a="$A" -v b="$B" '$0==a{s=1} !s{print} $0==b{s=0}' "$ZRC" > "$ZRC.tmp" && mv "$ZRC.tmp" "$ZRC"
fi
cat >> "$ZRC" <<EOF
$A
newproj() {
  local out; out="\$(bash "\$HOME/Ops/bin/new-project.sh" "\$@")" || { echo "\$out"; return 1; }
  echo "\$out" | grep -v '^CD:'
  local d; d="\$(echo "\$out" | sed -n 's|^CD:||p' | tail -1)"
  [ -n "\$d" ] && cd "\$d"
}
proj() { cd "\$HOME/Desktop/Projects/\$1"; }
alias ops="cd \$HOME/Ops"
$B
EOF

echo "설치 완료: $OPS · $LINK"
echo "  단축키: newproj <이름> [dev|deck|hwp|paper|career] · proj <이름> · ops"
[ -n "$MIRROR" ] && echo "  메모리 미러: $WORKFLOW_MIRROR_DEST" || echo "  메모리 미러: 비활성(config 비어 있음)"
echo "  새 zsh: source ~/.zshrc · Claude Code 재시작 시 훅 로드"
```

- [ ] **Step 4: 스모크 테스트 실행해 통과 확인**

Run: `bash tests/install-smoke.sh`
Expected: `PASS 1차 설치` / `PASS 멱등성` / `SMOKE OK`

- [ ] **Step 5: Commit**

```bash
chmod +x install.sh tests/install-smoke.sh
git add install.sh tests/install-smoke.sh
git commit -m "feat: 멱등 install.sh + 격리 스모크 테스트"
```

---

### Task 6: uninstall.sh

**Files:**
- Create: `uninstall.sh`

**Interfaces:**
- Consumes: Task 5가 심은 zshrc 마커(`>>> my-workflow >>>`)·settings 훅·`.bak` 백업 규약

- [ ] **Step 1: uninstall.sh 작성**

`uninstall.sh` 내용:
```bash
#!/usr/bin/env bash
set -euo pipefail
CDIR="$HOME/.claude"; ZRC="$HOME/.zshrc"; A="# >>> my-workflow >>>"; B="# <<< my-workflow <<<"

# 1) zshrc 마커 블록 제거
if [ -f "$ZRC" ] && grep -qF "$A" "$ZRC"; then
  awk -v a="$A" -v b="$B" '$0==a{s=1} !s{print} $0==b{s=0}' "$ZRC" > "$ZRC.tmp" && mv "$ZRC.tmp" "$ZRC"
  echo "제거: ~/.zshrc 단축키 블록"
fi

# 2) settings 훅/권한 제거
SETTINGS="$CDIR/settings.json" python3 - <<'PY'
import json, os
p = os.environ["SETTINGS"]; home = os.environ["HOME"]
try:
    with open(p) as f: d = json.load(f)
except (FileNotFoundError, ValueError):
    raise SystemExit(0)
def strip(event, needle):
    if event not in d.get("hooks",{}): return
    d["hooks"][event] = [b for b in d["hooks"][event]
        if not any(needle in h.get("command","") for h in b.get("hooks",[]))]
    if not d["hooks"][event]: del d["hooks"][event]
strip("SessionStart","session-guard.py")
strip("Stop","mirror-memory.sh")
strip("Stop","Glass.aiff"); strip("Notification","Ping.aiff")
perm = f"Read(//{home}/Ops/**)"
if perm in d.get("permissions",{}).get("allow",[]):
    d["permissions"]["allow"].remove(perm)
with open(p,"w") as f: json.dump(d, f, ensure_ascii=False, indent=1)
print("제거: ~/.claude/settings.json 훅/권한")
PY

# 3) 심링크 원복
LINK="$CDIR/CLAUDE.md"
if [ -L "$LINK" ]; then
  rm -f "$LINK"
  [ -f "$LINK.bak" ] && mv "$LINK.bak" "$LINK" && echo "복원: CLAUDE.md.bak"
  echo "제거: CLAUDE.md 심링크"
fi

echo "완료. ~/Ops 의 데이터는 그대로 둡니다(삭제는 직접 확인 후): rm -rf ~/Ops"
```

- [ ] **Step 2: uninstall이 스모크 환경에서 되돌리는지 확인**

Run:
```bash
bash -c 'set -e; TMP=$(mktemp -d); export HOME=$TMP; W=$TMP/r; cp -R . "$W"; cd "$W";
  printf "WORKFLOW_MIRROR_DEST=\"\$HOME/v\"\n" > config.sh;
  bash install.sh >/dev/null; bash uninstall.sh >/dev/null;
  grep -q ">>> my-workflow >>>" "$HOME/.zshrc" && { echo FAIL 마커잔존; exit 1; };
  python3 -c "import json,os;d=json.load(open(os.environ[\"HOME\"]+\"/.claude/settings.json\"));
assert not any(\"session-guard\" in h[\"command\"] for b in d.get(\"hooks\",{}).get(\"SessionStart\",[]) for h in b[\"hooks\"])";
  echo UNINSTALL_OK; rm -rf "$TMP"'
```
Expected: `UNINSTALL_OK`

- [ ] **Step 3: Commit**

```bash
chmod +x uninstall.sh
git add uninstall.sh
git commit -m "feat: uninstall.sh (병합분만 되돌림, 사용자 데이터 보존)"
```

---

### Task 7: docs/ — 설계 사고 과정

**Files:**
- Create: `docs/philosophy.md`, `docs/decisions.md`, `docs/WORKFLOW.md`

**Interfaces:**
- Consumes: 원본 `~/Ops/docs/WORKFLOW.md`, `~/Ops/adr/0001-workflow-overhaul.md`(사고 출처)

- [ ] **Step 1: philosophy.md 작성**

`docs/philosophy.md` 내용:
```markdown
# 설계 철학 — 4대 원칙

이 워크플로우는 네 가지 결정 위에 서 있다.

1. **폴더는 "마감이 있는가"로 나눈다.** 산출물 형식(PPT·한글·코드)이 아니라 성격으로.
   형식으로 나누면 프로젝트 하나가 여러 조각으로 쪼개지고 기억도 갈라진다.
2. **규칙은 스킬이 아니라 항상 주입되는 문서로 전달한다.** `~/Ops/AGENTS.md`가
   `~/.claude/CLAUDE.md`로 심링크되어 모든 세션에 자동으로 들어간다. 모델이 판단해
   호출하는 방식은 "필요할 때 안 꺼내봄"을 피할 수 없다.
3. **기억의 원본은 로컬 네이티브 memory.** 외부 볼트에는 단방향 사본(미러)만 보낸다.
   핵심 기억을 여러 동기화 계층 위에 올리지 않는다.
4. **검증은 다른 벤더 모델로 받는다.** 같은 벤더끼리는 편향을 공유한다.
   자기검토는 검증으로 치지 않는다.
```

- [ ] **Step 2: decisions.md 작성 (ccpilot 이름 없이 일반화)**

`docs/decisions.md` 내용:
```markdown
# 버린 대안과 이유

무엇을 넣었는가보다 무엇을 왜 뺐는가가 이 워크플로우를 더 잘 설명한다.

| 대안 | 기각 사유 |
|---|---|
| 산출물 형식 기준 폴더 (개발/PPT/한글) | 프로젝트 하나가 논문·발표·구현으로 영구 분리되고 기억도 여러 키로 갈라진다 |
| 기억을 외부 볼트로 심링크 | 핵심 기억을 여러 동기화 계층 의존 위에 올리게 된다. 캐시 축출 하나로 조용히 빈 내용이 읽힐 수 있다 |
| 모델이 판단해 호출하는 자동 회상(MCP) | "필요할 때 안 꺼내봄"을 피하지 못한다. 항상 주입되는 문서가 이미 이긴 방식이다 |
| 멀티에이전트 상시화 | 토큰 비용이 급증한다. 상시로 정당화할 근거가 없다 |
| 측정되지 않는 커스텀 프리셋 하네스 | 기준선이 이미 충분히 높아 이득을 측정할 수 없었다. 단순함만으로 상시 유지를 정당화 못 함 → 걷어냄 |

**원칙:** 장치를 더할 때는 이득을 측정할 수 있어야 한다. 측정되지 않으면 단순함이 이긴다.
```

- [ ] **Step 3: WORKFLOW.md 이식 (탈개인화)**

Run:
```bash
cp ~/Ops/docs/WORKFLOW.md docs/WORKFLOW.md
```
그다음 `docs/WORKFLOW.md`에서 아래를 스크럽:
- iCloud `VibeSession/`·`LLM Wiki Brain/` 등 개인 볼트명 → "외부 볼트(미러 대상)"로 일반화
- "§9 도구 현황"·"§10 아직 안 된 것"의 개인 저장소명(`2026-crypto-contest`·`vibecoding`·`ganggun`·`toeic`)·개인 사정 줄 삭제
- 다른 벤더 검증 문단의 `Codex` 고유명 → "다른 벤더 모델(예: 다른 회사 CLI)"로 일반화
- 남은 `~/Ops/...` 경로 참조는 그대로 둔다(설치 후 실제 경로라 유효)

- [ ] **Step 4: 개인정보 게이트**

Run:
```bash
! grep -rn "kimhands\|VibeSession\|ccpilot\|김종건\|순천향\|labplatform\|Codex\|crypto-contest\|vibecoding\|ganggun\|toeic" docs
```
Expected: 아무것도 안 찍히고 종료(스크럽 완료). 찍히면 해당 줄 마저 일반화.

- [ ] **Step 5: Commit**

```bash
git add docs/philosophy.md docs/decisions.md docs/WORKFLOW.md
git commit -m "docs: 설계 철학·버린 대안·운용 설명서 (탈개인화)"
```

---

### Task 8: README + 최종 개인정보 게이트

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: 전체 저장소 (설치 안내·구조 설명)

- [ ] **Step 1: README.md 작성**

`README.md` 내용:
```markdown
# my-workflow

**Claude Code를 위한 개인 운용체계(operating layer) 템플릿.**
규칙은 항상 주입되는 문서로, 반복 작업은 스크립트로, 검증은 다른 벤더로 —
이 세 가지를 `~/Ops/` 한 곳에 모아 누구나 설치해 쓸 수 있게 만든 것.

설계 배경은 [`docs/philosophy.md`](docs/philosophy.md)와
[`docs/decisions.md`](docs/decisions.md)를 먼저 읽으면 이해가 빠릅니다.

## 무엇이 설치되나

- `~/Ops/AGENTS.md` → `~/.claude/CLAUDE.md` 심링크로 **모든 세션에 자동 주입**되는 전역 규칙
- `~/Ops/domains/*.md` — 발표자료·한글문서·웹개발·논문·검증의 형식별 규칙
- `~/Ops/bin/*` — 새 프로젝트 생성, SessionStart 가드, 메모리 미러, 회귀 측정 루프,
  교차검증 루프, 백업 스크립트
- `~/.claude/settings.json`에 훅 2개(SessionStart 가드 · Stop 미러)와 `~/Ops` 읽기 권한 **병합**
- `~/.zshrc`에 `newproj` · `proj` · `ops` 단축키

## 설치

**요구사항:** [Claude Code](https://code.claude.com) · Python 3 · bash · git. (외부 의존성 없음, 표준 라이브러리만.)

```bash
git clone https://github.com/<your>/my-workflow.git
cd my-workflow
cp config.example.sh config.sh    # 이름·언어·미러대상·사운드를 채운다
bash install.sh
source ~/.zshrc                    # 단축키 즉시 반영
# Claude Code 재시작 → 훅 로드
```

**멱등 설치** — 여러 번 돌려도 안전하며 기존 설정을 덮어쓰지 않고 병합합니다(항상 `.bak` 백업).

제거: `bash uninstall.sh` (병합분만 되돌리고 `~/Ops` 데이터는 보존).

## 하루 사용법

```bash
newproj my-talk deck     # 규칙에 맞는 새 프로젝트 생성 + 이동
proj my-talk             # 기존 프로젝트로 이동
ops                      # ~/Ops 로 이동
```

새 프로젝트는 폴더명 규칙(ASCII 소문자·숫자·하이픈, 개명 금지)을 강제하고,
루트에 `CLAUDE.md`(→`@AGENTS.md`) 골격을 만듭니다. 세션을 열면 SessionStart 가드가
누락된 `CLAUDE.md`를 자동 생성하고 규칙 위반을 경고합니다(막지는 않음).

## 저장소 구조

```
ops/          ~/Ops 로 설치될 템플릿 (규칙·domains·bin·adr·golden)
claude/       ~/.claude 에 병합될 훅/권한 스니펫
config.example.sh  사용자가 채우는 값
install.sh · uninstall.sh
docs/         설계 철학·버린 대안·운용 설명서
tests/        격리 스모크 테스트
```

## 검증

```bash
bash tests/install-smoke.sh   # 임시 HOME에서 설치·멱등성 검증 (실제 홈 무해)
```

## 라이선스

MIT
```

- [ ] **Step 2: 저장소 전체 최종 개인정보 게이트**

Run:
```bash
git ls-files | xargs grep -n "kimhands\|VibeSession\|ccpilot\|김종건\|순천향\|labplatform\|Codex\|crypto-contest\|vibecoding\|ganggun\|toeic\|Project/Setting" ; echo "exit=$?"
```
Expected: 매치 없음(grep exit=1로 `exit=1` 출력). 무엇이든 찍히면 그 파일을 스크럽 후 재실행.

- [ ] **Step 3: 전체 스모크 재확인**

Run: `bash tests/install-smoke.sh`
Expected: `SMOKE OK`

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: README (설치·사용·구조·검증)"
```

---

## Self-Review

- **Spec coverage:** §2 공유/제외 → Task 2·3(이식)·Global Constraints(제외). §3 설치기 → Task 5. §4 구조 → Task 1~8 전 파일. §5 컴포넌트 → config(T1)·install(T5)·uninstall(T6)·snippet(T4)·docs(T7). §6 스크럽 → 각 Task의 게이트 + T8 최종 게이트. §7 안전 → `.bak`·멱등·mirror 안전장치 보존(T3·T5). §8 테스트 → T5 스모크. §9 성공기준 → T8 게이트+스모크. 누락 없음.
- **일회성 이사 스크립트 제외**는 spec §2의 "운용체계(steady-state)" 의도에 부합 — 핸드오프에서 사용자에게 고지.
- **Placeholder scan:** 모든 코드 스텝에 실제 내용 포함, TODO/TBD 없음.
- **Type/이름 일관성:** `WORKFLOW_*` 변수·`>>> my-workflow >>>` 마커·`session-guard.py`/`mirror-memory.sh` needle·`CD:` 마커가 Task 3·5·6에서 일치.
