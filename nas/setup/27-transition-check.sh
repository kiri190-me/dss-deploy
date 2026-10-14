#!/bin/sh
# /volume1/dss/setup/27-transition-check.sh — 전환일 가져오기를 **재 보기만** 한다
#
# 🔴 사람이 sudo -i 로 돌린다.
#     sh /volume1/dss/setup/27-transition-check.sh 1     ← 담당자 가공본
#     sh /volume1/dss/setup/27-transition-check.sh 2     ← 공유폴더 원본
#
# ══ 🔴 DB 에 아무것도 쓰지 않는다 ══════════════════════════════════════
#
#   import-workbook.ts 의 --check-only 를 부른다. 읽고 세기만 하고 끝난다.
#   실자료를 넣는 것은 27-transition-go.sh 이고 그것은 따로 승인받는다.
#
# ══ 왜 둘을 견주나 ═════════════════════════════════════════════════════
#
#   ① 현황판_최신사본_2026-10-01.xlsx (217KB)
#      정영빈 님이 가공한 것 — 세 시트 · 수식 없음 · 담당자 컨펌본.
#      전환일 절차서가 전제한 입력 꼴이다.
#   ② 현황판_공유폴더_2026-10-12.xlsx (1,029KB)
#      사내 공유폴더의 원본. **11일 더 최신**이지만 수식과 서식이 그대로다.
#
#   🔴 ②가 ①보다 새롭다고 무조건 낫지 않다. 꼴이 달라 덜 읽힐 수 있다.
#      **숫자로 가린다** — 부품 수 · 사용/입고 줄 수 · 못 붙인 건수.
#      기대값(2026-10-07 시험): 부품 319 · 사용 1,349/237/55/11 ·
#      입고 545/85/17/15 · 못 붙인 26건 · 칸 사정 2건.
#      🔴 못 붙인 건수가 크게 늘었으면 현황판에 새 줄이 생긴 것이다 —
#         못붙인 CSV 를 열어 보고 판정표에 줄을 더할지는 **사람이 정한다.**

set -u
D=/volume1/dss
DATA=$D/inventory-data
CF=$D/deploy/docker-compose.nas.yml
ENVF=$D/deploy/.env.nas
DOCKER=/usr/local/bin/docker

WHICH=${1:-}
case "$WHICH" in
  1) WB="현황판_최신사본_2026-10-01.xlsx";  LABEL="① 담당자 가공본 (2026-10-01 · 세 시트 · 수식 없음)" ;;
  2) WB="현황판_공유폴더_2026-10-12.xlsx";  LABEL="② 공유폴더 원본 (2026-10-12 · 11일 더 최신)" ;;
  *)
    echo "🔴 어느 것을 잴지 적어 주세요."
    echo "   sh $0 1     ← 담당자 가공본 (2026-10-01)"
    echo "   sh $0 2     ← 공유폴더 원본 (2026-10-12)"
    exit 2 ;;
esac

DEC="과거기록_묶음판정_2026-10-02.csv"
OUT="못붙인_검사_$WHICH.csv"

echo "══ 재 보기 — $LABEL ══"
echo "  🔴 **DB 에 아무것도 쓰지 않습니다.** 읽고 세기만 합니다."
echo "  · 현황판 : $WB"
echo "  · 판정표 : $DEC"
echo "  · 못 붙인 줄을 적을 곳 : import/$OUT"
echo

if [ ! -s "$DATA/import/$WB" ]; then
  echo "  ✗ import/$WB 가 없다 — 27-transition-files.sh 를 먼저 돌리세요"
  exit 1
fi
if [ ! -s "$DATA/import/$DEC" ]; then
  echo "  ✗ import/$DEC 가 없다 — 27-transition-files.sh 를 먼저 돌리세요"
  exit 1
fi

echo "── 도구 컨테이너로 돌린다 (profiles: tools · 평소엔 안 뜬다) ──"
echo

"$DOCKER" compose -f "$CF" --env-file "$ENVF" --profile tools \
  run --rm tools-inventory \
  npx tsx scripts/import-workbook.ts --check-only \
    "/data/import/$WB" \
    --decisions "/data/import/$DEC" \
    --unmatched "/data/import/$OUT" 2>&1 | sed 's/^/  /'

RC=$?
echo
echo "── 끝 (종료 코드 $RC) ──"
echo
echo "🔴 Claude 에게 보여 줄 것:"
echo "   · 위 숫자 전부 (부품 · 사용 · 입고 · 못 붙인 건수)"
echo "   · 기대값과 견주기: 부품 319 · 못 붙인 26건 (2026-10-07 시험값)"
echo
echo "🔵 못 붙인 줄을 눈으로 보려면:"
echo "   head -20 '$DATA/import/$OUT'"
exit "$RC"
