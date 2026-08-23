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
