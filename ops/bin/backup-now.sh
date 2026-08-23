#!/bin/bash
# Desktop + Claude 기억을 로컬로 백업하고 복원 가능성을 검증한다.
# ⚠ 같은 디스크에 저장하므로 디스크 고장에는 무력하다. Time Machine/외장을 대체하지 않는다.
set -euo pipefail
D=$(date +%F)
B="$HOME/Backups"; mkdir -p "$B"
LOG="$B/backup.log"
log(){ printf '%s %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG"; }

log "백업 시작"
tar -cf "$B/desktop-$D.tar" -C "$HOME" Desktop
tar -czf "$B/claude-projects-$D.tar.gz" -C "$HOME/.claude" projects
tar -czf "$B/ops-$D.tar.gz" -C "$HOME" Ops

a=$(tar -tf "$B/desktop-$D.tar" | wc -l | tr -d ' ')
b=$(find "$HOME/Desktop" | wc -l | tr -d ' ')
[ "$a" = "$b" ] || log "WARN 항목수 불일치 아카이브=${a} 원본=${b}"
log "desktop ${a} entries / memory $(find "$HOME/.claude/projects"/*/memory -name '*.md' 2>/dev/null | wc -l | tr -d ' ') files"

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

# 30일 넘은 백업 정리
find "$B" -name 'desktop-*.tar' -mtime +30 -delete 2>/dev/null || true
find "$B" -name 'claude-projects-*.tar.gz' -mtime +30 -delete 2>/dev/null || true
find "$B" -name 'ops-*.tar.gz' -mtime +30 -delete 2>/dev/null || true
log "백업 완료 — $(du -sh "$B" | cut -f1)"
