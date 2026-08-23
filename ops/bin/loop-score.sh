#!/bin/bash
# 루프 나머지: 채점 읽기 → 직전 회차와 비교 → 회귀 시 경고 → 이력 기록
# usage: loop-score.sh <라벨>
set -euo pipefail
[ $# -eq 1 ] || { echo "usage: loop-score.sh <라벨>"; exit 1; }
L="$1"; G="$HOME/Ops/golden"; SHEET="$G/runs/$L.md"; SET="$G/gold-set.md"
[ -f "$SHEET" ] || { echo "FAIL 채점표 없음: $SHEET"; exit 1; }
[ -f "$SET" ]   || { echo "FAIL 시험지 없음: $SET"; exit 1; }

# 1) 유효 문항을 시험지에서 읽는다 (하드코딩 금지)
VALID=$(grep -oE '유효 문항은 [0-9]+개\(([^)]*)\)' "$SET" | sed -E 's/.*\((.*)\).*/\1/' | tr '·' ' ')
[ -n "$VALID" ] || { echo "FAIL 시험지에서 유효 문항 선언을 못 찾음 ('유효 문항은 N개(G1·G2…)' 형식 필요)"; exit 1; }
DECL=$(grep -oE '유효 문항은 [0-9]+개' "$SET" | grep -oE '[0-9]+' | head -1)
EXPECT=$(printf '%s\n' $VALID | wc -w | tr -d ' ')
[ "$DECL" = "$EXPECT" ] || { echo "FAIL 시험지 선언 불일치: '${DECL}개'라 했는데 목록은 ${EXPECT}개"; exit 1; }
echo "유효 문항($EXPECT): $VALID"

# 2) 채점 읽기 — O/X 와 ✔/✘ 둘 다 수용, 유효 문항만 집계
o=0; n=0; missing=""; got=""
NL=$(printf "\n")
for g in $VALID; do
  cnt=$(grep -cE "^\| *$g *\|" "$SHEET" || true)
  [ "$cnt" -le 1 ] || { echo "FAIL 채점표에 $g 행이 ${cnt}개 중복"; exit 1; }
  row=$(grep -E "^\| *$g *\|" "$SHEET" | head -1 || true)
  if [ -z "$row" ]; then missing="$missing $g(행없음)"; continue; fi
  m=$(printf '%s' "$row" | awk -F'|' '{gsub(/[ \t]/,"",$3); print $3}')
  case "$m" in
    O|o|✔) o=$((o+1)); n=$((n+1)); got="$got$NL   $g ✔";;
    X|x|✘)            n=$((n+1)); got="$got$NL   $g ✘";;
    *)     missing="$missing $g(미채점:'${m:-빈칸}')";;
  esac
done
[ -z "$missing" ] || { echo "FAIL 채점되지 않은 항목:$missing"; exit 1; }
[ "$n" = "$EXPECT" ] || { echo "FAIL 집계 수 불일치: 기대 $EXPECT / 실제 $n"; exit 1; }
echo "점수: $o / $n"; printf '%s\n' "$got" | grep -v '^$'

# 3) 직전 회차와 비교 — 분모를 무시하지 않는다
prev=""; prev_row=""
while IFS= read -r r; do
  case "$r" in *"| $L |"*) continue;; esac
  v=$(printf '%s' "$r" | awk -F'|' '{gsub(/[* ]/,"",$4); print $4}')
  printf '%s' "$v" | grep -qE '^[0-9]+/[0-9]+$' || continue
  prev="$v"; prev_row="$r"
done < <(grep -E '^\| 20[0-9]{2}-[0-9]{2}-[0-9]{2} \|' "$SET")
st="유지"
if [ -z "$prev_row" ]; then
  echo; echo "ℹ 직전 이력 없음 — 이번이 기준선입니다"; st="기준선"
else
  po=${prev%%/*}; pn=${prev##*/}
  if [ $((o * pn)) -lt $((po * n)) ]; then
    echo; echo "🚨 회귀 감지: 직전 $prev → 이번 $o/$n"
    echo "   (감지일 뿐 원인 확정이 아닙니다. 직전 변경을 되돌려 다시 재면 원인 여부가 갈립니다)"
    echo "   원인 규명 전까지 다음 변경으로 넘어가지 마세요 — 한 번에 하나만 변경."
    st="🚨 회귀"
  else
    echo; echo "✓ 회귀 없음 (직전 $prev)"
  fi
fi

# 4) 이력 기록 — 같은 라벨이 이미 있으면 덮어쓴다(중복 append 방지)
python3 - "$SET" "$L" "$o" "$n" "$st" <<'PY'
import sys, re, pathlib
p, label, o, n, st = pathlib.Path(sys.argv[1]), *sys.argv[2:]
line = f"| {__import__('datetime').date.today()} | {label} | **{o}/{n}** | {st} |"
s = p.read_text()
pat = re.compile(rf'^\|[^|]*\| *{re.escape(label)} *\|.*$', re.M)
existed = bool(pat.search(s))
s = pat.sub(line, s) if existed else s.rstrip() + "\n" + line + "\n"
p.write_text(s)
print(f"   이력 {'갱신' if existed else '추가'}됨 → {p}")
PY
