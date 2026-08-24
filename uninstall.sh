#!/usr/bin/env bash
set -euo pipefail
CDIR="$HOME/.claude"; ZRC="$HOME/.zshrc"; A="# >>> opsmith >>>"; B="# <<< opsmith <<<"

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
perm = f"Read(//{home.lstrip('/')}/Ops/**)"
if perm in d.get("permissions",{}).get("allow",[]):
    d["permissions"]["allow"].remove(perm)
with open(p,"w") as f: json.dump(d, f, ensure_ascii=False, indent=1)
print("제거: ~/.claude/settings.json 훅/권한")
PY

# 2b) 전역 git 훅 원복 (opsmith가 걸어둔 hooksPath만 해제/복원)
if command -v git >/dev/null 2>&1; then
  CUR="$(git config --global core.hooksPath 2>/dev/null || true)"
  if [ "$CUR" = "$HOME/Ops/git-hooks" ]; then
    PREV="$(git config --global opsmith.prevHooksPath 2>/dev/null || true)"
    if [ -n "$PREV" ]; then
      git config --global core.hooksPath "$PREV"
      git config --global --unset opsmith.prevHooksPath
      echo "복원: core.hooksPath → $PREV"
    else
      git config --global --unset core.hooksPath
      echo "제거: 전역 core.hooksPath (커밋 메시지 훅)"
    fi
  fi
fi

# 3) 심링크 원복
LINK="$CDIR/CLAUDE.md"
if [ -L "$LINK" ]; then
  rm -f "$LINK"
  [ -f "$LINK.bak" ] && mv "$LINK.bak" "$LINK" && echo "복원: CLAUDE.md.bak"
  echo "제거: CLAUDE.md 심링크"
fi

echo "완료. ~/Ops 의 데이터는 그대로 둡니다(삭제는 직접 확인 후): rm -rf ~/Ops"
