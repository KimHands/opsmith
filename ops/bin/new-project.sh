#!/bin/bash
# 새 프로젝트를 규칙에 맞게 만든다. 폴더 + CLAUDE.md + AGENTS.md 골격.
# usage: new-project.sh <이름> [dev|deck|hwp|paper|career]
set -euo pipefail
[ $# -ge 1 ] || { cat <<USAGE
usage: new-project.sh <이름> [종류]
  이름 : ASCII 소문자·숫자·하이픈만. 생성 후 개명 금지(memory가 경로에 묶임)
  종류 : dev(기본) | deck | hwp | paper | career
예시  : new-project.sh kcc-2026-talk deck
USAGE
exit 1; }

NAME="$1"; KIND="${2:-dev}"

# 이름 규칙 강제 — 나중에 못 고치므로 여기서 막는다
printf '%s' "$NAME" | grep -qE '^[a-z0-9][a-z0-9-]*$' \
  || { echo "FAIL 이름은 ASCII 소문자·숫자·하이픈만, 소문자/숫자로 시작: '$NAME'"; exit 1; }

case "$KIND" in
  career) BASE="$HOME/Desktop/Career";  DOMAIN="";                        DESC="끝이 없는 활동";;
  deck)   BASE="$HOME/Desktop/Projects"; DOMAIN='~/Ops/domains/deck.md';  DESC="발표자료";;
  hwp)    BASE="$HOME/Desktop/Projects"; DOMAIN='~/Ops/domains/hwp.md';   DESC="한글 문서";;
  paper)  BASE="$HOME/Desktop/Projects"; DOMAIN='~/Ops/domains/paper.md'; DESC="논문·학술";;
  dev)    BASE="$HOME/Desktop/Projects"; DOMAIN='~/Ops/domains/web.md';   DESC="개발";;
  *) echo "FAIL 알 수 없는 종류: $KIND (dev|deck|hwp|paper|career)"; exit 1;;
esac
DIR="$BASE/$NAME"
[ -e "$DIR" ] && { echo "FAIL 이미 존재: $DIR"; exit 1; }

# 기존 memory 키와 충돌하는지 — 과거에 같은 경로를 쓴 적이 있으면 옛 기억이 붙는다
KEY=$(printf '%s' "$DIR" | sed 's/[^A-Za-z0-9]/-/g')
if [ -d "$HOME/.claude/projects/$KEY" ]; then
  echo "⚠ 같은 경로의 옛 기억이 남아 있습니다: ~/.claude/projects/$KEY"
  echo "  이어서 쓰려면 그대로, 새로 시작하려면 그 디렉터리를 ~/Ops/archive 로 옮기세요."
fi

mkdir -p "$DIR"
printf '@AGENTS.md\n' > "$DIR/CLAUDE.md"
{
  echo "# $NAME"
  echo
  echo "$DESC. (한 줄로 이 프로젝트가 무엇인지 적으세요)"
  echo
  echo "## 이 프로젝트에서 항상 지킬 것"
  [ -n "$DOMAIN" ] && echo "- 형식 규칙: \`$DOMAIN\`"
  echo "- (작업하다 \"또 이걸 어겼네\" 싶은 게 생기면 여기에 한 줄씩 추가하세요)"
  echo
  echo "> 규칙은 3~6개면 충분합니다. 매번 어기기 쉬운 것과 어기면 되돌리기 어려운 것만."
  echo "> 형식 규칙은 복사하지 말고 위 경로로 참조만 하세요."
} > "$DIR/AGENTS.md"

echo "생성 완료: $DIR"
echo "  CLAUDE.md  @AGENTS.md 임포트 (규칙 스위치)"
echo "  AGENTS.md  $(wc -l < "$DIR/AGENTS.md" | tr -d ' ')줄 골격"
echo
echo "  cd $DIR"
echo "CD:$DIR"
