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
import json, os, shutil
p = os.environ["SETTINGS"]; home = os.environ["HOME"]
mirror = os.environ.get("MIRROR",""); sound = os.environ.get("SOUND","off")
if os.path.exists(p):
    shutil.copy2(p, p+".bak")
try:
    with open(p) as f: d = json.load(f)
except (FileNotFoundError, ValueError):
    d = {}
d.setdefault("permissions", {}).setdefault("allow", [])
d.setdefault("hooks", {})

def has_cmd(event, needle):
    for block in d["hooks"].get(event, []):
        for h in block.get("hooks", []):
            if needle in h.get("command",""): return True
    return False

def add(event, cmd, extra=None):
    if has_cmd(event, cmd): return
    hook = {"type":"command","command":cmd}
    if extra: hook.update(extra)
    d["hooks"].setdefault(event, []).append({"hooks":[hook]})

perm = f"Read(//{home.lstrip('/')}/Ops/**)"
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
[ -n "$WORKFLOW_MIRROR_DEST" ] && echo "  메모리 미러: $WORKFLOW_MIRROR_DEST" || echo "  메모리 미러: 비활성(config 비어 있음)"
echo "  새 zsh: source ~/.zshrc · Claude Code 재시작 시 훅 로드"
