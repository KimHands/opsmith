#!/bin/bash
# 기준선을 N회 반복 측정해 변동폭을 본다.
# AGENTS.md 심링크를 잠시 떼고 원본 CLAUDE.md로 되돌린 뒤 측정하고, 무조건 원복한다.
set -uo pipefail
LINK="$HOME/.claude/CLAUDE.md"; ORIG="$HOME/Ops/CLAUDE.md.orig"; TARGET="$HOME/Ops/AGENTS.md"
[ -f "$ORIG" ] || { echo "FAIL: 원본 백업 없음 — 중단"; exit 1; }
restore() {
  rm -f "$LINK"; ln -s "$TARGET" "$LINK"
  echo "심링크 원복: $(ls -l "$LINK" | sed 's/.*CLAUDE.md/CLAUDE.md/')"
}
trap restore EXIT INT TERM
rm -f "$LINK"; cp "$ORIG" "$LINK"
echo "심링크 해제 · 원본 CLAUDE.md 복원 (측정용)"
for i in "$@"; do
  echo "── 반복 측정: $i"
  "$HOME/Ops/bin/collect-golden.sh" "$i"
done
