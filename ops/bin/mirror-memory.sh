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
