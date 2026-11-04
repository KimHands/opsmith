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
count_hook() {
  EVENT="$1" CMD="$2" python3 -c "import json,os; d=json.load(open(os.environ['HOME']+'/.claude/settings.json')); \
  print(sum(h['command']==os.environ['CMD'] for b in d['hooks'].get(os.environ['EVENT'],[]) for h in b['hooks']))"
}
user_settings_kept() {
  python3 -c "import json,os; d=json.load(open(os.environ['HOME']+'/.claude/settings.json')); \
  assert d['model']=='x'; assert 'Bash(ls)' in d['permissions']['allow']; \
  assert any(h['command']=='mine.sh' for b in d['hooks']['Stop'] for h in b['hooks'])"
}

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
python3 -c "import json,os; d=json.load(open(os.environ['HOME']+'/.claude/settings.json')); \
  assert not any('afplay' in h['command'] for b in d['hooks'].get('Stop',[]) for h in b['hooks']), 'sound=off인데 Stop에 afplay 존재'; \
  assert not any('Ping' in h['command'] for b in d['hooks'].get('Notification',[]) for h in b['hooks']), 'sound=off인데 Notification에 Ping 존재'" \
  || fail "sound=off 검증 실패"
grep -q ">>> opsmith >>>" "$HOME/.zshrc" || fail "zshrc 마커 없음"
[ -f "$HOME/Ops/golden/gold-set.md" ] || fail "gold-set.md 미생성"
for p in pw pw_route commands agents skills project-presets.json route-rules.json; do
  [ ! -e "$HOME/.claude/$p" ] || fail "opsmith 설치가 ccpilot 경로를 만듦: $p"
done
pass "1차 설치"

# 멱등성: 다시 돌려도 훅/마커가 중복되지 않아야 한다
bash install.sh >/dev/null
SC=$(python3 -c "import json,os; d=json.load(open(os.environ['HOME']+'/.claude/settings.json')); \
  print(sum('session-guard' in h['command'] for b in d['hooks']['SessionStart'] for h in b['hooks']))")
[ "$SC" = "1" ] || fail "멱등성 위반: guard 훅 $SC개"
MC=$(grep -c ">>> opsmith >>>" "$HOME/.zshrc")
[ "$MC" = "1" ] || fail "멱등성 위반: zshrc 마커 $MC개"
pass "멱등성"

# ccpilot 공존: 사용자 설정이 있는 HOME에서, 공백 경로의 클론을 다른 위치에서 설치한다
export HOME="$TMP/h2"
mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/settings.json" <<'EOF'
{"model":"x","permissions":{"allow":["Bash(ls)"]},"hooks":{"Stop":[{"hooks":[{"type":"command","command":"mine.sh"}]}]}}
EOF
CLONE="$TMP/with space"
cp -R "$WORK" "$CLONE"
install_ccpilot() { (cd / && bash "$CLONE/modules/ccpilot/install.sh" >/dev/null); }
CCPILOT_HOOK='python3 ~/.claude/pw/hook_sessionstart.py'
GUARD_HOOK="python3 $HOME/Ops/bin/session-guard.py"

install_ccpilot
[ -f "$HOME/.claude/pw/cli.py" ] || fail "ccpilot pw 미설치"
[ -f "$HOME/.claude/skills/project-kickoff/SKILL.md" ] || fail "ccpilot 스킬 미설치"
bash install.sh >/dev/null
install_ccpilot
bash install.sh >/dev/null
[ "$(count_hook SessionStart "$CCPILOT_HOOK")" = "1" ] || fail "ccpilot 훅 개수 이상"
[ "$(count_hook SessionStart "$GUARD_HOOK")" = "1" ] || fail "guard 훅 개수 이상"
user_settings_kept || fail "사용자 설정 유실"
pass "ccpilot 공존"

bash uninstall.sh >/dev/null
[ "$(count_hook SessionStart "$CCPILOT_HOOK")" = "1" ] || fail "opsmith 제거가 ccpilot 훅을 지움"
[ "$(count_hook SessionStart "$GUARD_HOOK")" = "0" ] || fail "guard 훅이 남음"
user_settings_kept || fail "제거 후 사용자 설정 유실"
pass "opsmith 제거 후 ccpilot 보존"

echo "SMOKE OK"
