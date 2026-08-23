#!/bin/bash
# 검증 그래프를 실행한다.
#
#   [사람] 문제정의·판단기준  ← 인자로 받음 (위임 불가)
#        ↓
#   [Claude] 구현            ← 이미 끝난 산출물이 입력
#        ↓
#   [Codex] 검증             ← 다른 벤더. 자기검토는 검증에 산입 안 함
#        ↓ 지적 있음 → 루프백 (상한 2회)
#        ↓ 상한 초과 → [사람] 판정
#   [사람] 승인 게이트        ← 배포·발송·삭제는 여기서만
#
# usage: graph-verify.sh <검증대상경로> "<무엇을 검증하는가>"
set -euo pipefail
[ $# -ge 2 ] || { echo "usage: graph-verify.sh <대상경로> \"<무엇을 검증하는가>\""; exit 1; }
TARGET="$1"; shift; CLAIM="$*"
[ -e "$TARGET" ] || { echo "FAIL 대상 없음: $TARGET"; exit 1; }

MAX=2                                   # 반복 상한 — 무한 개정 루프 방지
RUN="$HOME/Ops/golden/runs/graph-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN"
echo "검증 그래프 시작 → $RUN"
echo "  대상: $TARGET"
echo "  주장: $CLAIM"

round=1
while [ "$round" -le "$MAX" ]; do
  echo
  echo "── 라운드 $round/$MAX : [Codex] 검증 노드"
  OUT="$RUN/round-$round.md"
  codex exec --skip-git-repo-check > "$OUT" 2>&1 <<EOF || true
당신은 다른 벤더(OpenAI) 모델로서 **적대적 교차검증**을 합니다. 같은 벤더끼리는 편향을 공유하므로
당신이 검증자입니다. **동의하지 말고 반박하세요.** 결론은 한국어로.

## 검증 대상
경로: \`$TARGET\`
주장: $CLAIM

먼저 대상을 직접 읽으세요. 읽지 않고 추측하지 마세요.

## 답할 것 (각각 나눠서)
1. **사실 오류** — 대상이 사실과 다르게 말하는 곳. 근거와 함께.
2. **가장 그럴듯한 실패 시나리오 3가지** — 무엇부터 무너지는가.
3. **빠진 것** — 반드시 다뤄야 하는데 없는 것.
4. **과잉설계** — 빼도 되는 것.
5. **판정** — 마지막 줄에 정확히 다음 중 하나만 쓰세요:
   \`VERDICT: PASS\`  (지적사항 없음, 이대로 진행 가능)
   \`VERDICT: FIX\`   (고쳐야 할 것이 있음)

추측이면 추측이라고 밝히세요. 아첨 금지.
EOF
  echo "   → $OUT"
  v=$(grep -oE 'VERDICT: (PASS|FIX)' "$OUT" | tail -1 || true)
  echo "   판정: ${v:-판정문 없음}"

  if [ "$v" = "VERDICT: PASS" ]; then
    echo
    echo "✅ 검증 통과 (라운드 $round)"
    echo "── [사람] 승인 게이트"
    echo "   배포·외부발송·삭제는 여기서 사람이 실행합니다. 스크립트는 대신하지 않습니다."
    exit 0
  fi

  echo "   지적사항 있음 → 루프백"
  if [ "$round" -eq "$MAX" ]; then
    echo
    echo "⚠ 반복 상한 ${MAX}회 도달 → [사람] 판정 필요"
    echo "   지적사항: $RUN/round-*.md"
    echo "   상한을 늘리지 말고, 무엇을 수용하고 무엇을 기각할지 사람이 정하세요."
    echo "   판정 결과는 대상 문서에 표로 남기고, 되돌리기 어려운 결정이면 ~/Ops/adr/ 에 기록하세요."
    exit 2
  fi
  echo
  echo "   지적사항을 반영한 뒤 Enter를 누르면 라운드 $((round+1))로 갑니다. (중단은 Ctrl-C)"
  read -r _ || true
  round=$((round+1))
done
