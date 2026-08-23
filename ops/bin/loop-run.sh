#!/bin/bash
# 루프 1바퀴: 평가(수집) → 채점표 생성 → 사람 채점 대기
# usage: loop-run.sh <라벨>     예) loop-run.sh 2026-08-20-skills-batch1
set -euo pipefail
[ $# -eq 1 ] || { echo "usage: loop-run.sh <라벨>"; exit 1; }
L="$1"; G="$HOME/Ops/golden"; R="$G/runs/$L"

echo "── 1단계: 응답 수집"
"$HOME/Ops/bin/collect-golden.sh" "$L" >/dev/null
echo "   수집 완료 → $R"

echo "── 2단계: 채점표 생성"
SHEET="$G/runs/$L.md"
{
  echo "# 골든셋 채점 — $L"
  echo
  echo "채점: 각 행의 \`?\`를 \`O\` 또는 \`X\`로 바꾸고 저장한 뒤 \`loop-score.sh $L\` 실행."
  echo "판정 기준은 \`~/Ops/golden/gold-set.md\` 참조. **G3는 점수 제외**(참고용)."
  echo
  echo "| # | 판정 | 응답 |"
  echo "|---|---|---|"
  for g in G1 G2 G4 G5 G6 G7; do
    f="$R/$g.txt"; [ -f "$f" ] || { echo "| $g | ? | (수집 실패) |"; continue; }
    echo "| $g | ? | \`runs/$L/$g.txt\` ($(wc -c <"$f" | tr -d ' ')B) |"
  done
  echo
  echo "## 응답 전문"
  for g in G1 G2 G4 G5 G6 G7; do
    echo; echo "### $g"; echo '```'; cat "$R/$g.txt" 2>/dev/null; echo '```'
  done
  echo; echo "### G3 (점수 제외 · 참고)"; echo '```'; cat "$R/G3.txt" 2>/dev/null; echo '```'
} > "$SHEET"
echo "   채점표 → $SHEET"

echo "── 3단계: 사람 채점 대기"
echo
echo "   다음을 하세요:"
echo "     1) $SHEET 를 열어 판정 열의 ? 를 O/X 로 바꾸고 저장"
echo "     2) ~/Ops/bin/loop-score.sh $L"
