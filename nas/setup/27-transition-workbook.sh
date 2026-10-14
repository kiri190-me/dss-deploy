#!/bin/sh
# /volume1/dss/setup/27-transition-workbook.sh — 현황판 엑셀이 만들어졌는지 본다
#
# 🔴 사람이 sudo -i 로 돌린다.
#     sh /volume1/dss/setup/27-transition-workbook.sh            ← 읽기만
#     sh /volume1/dss/setup/27-transition-workbook.sh --make     ← 직접 만들어 본다
#
# ══ 무엇을 보나 (절차서 ⑨) ════════════════════════════════════════════
#
#   앱은 가져오기가 남긴 「써야 함」 표시를 보고 **15초쯤 뒤 스스로** 첫 파일을
#   만든다. 그 뒤로는 1분마다 다시 쓴다. 이 스크립트는 **생겼는지**를 본다:
#
#     · 직원이 탐색기로 여는 공유폴더        ← 🔴 여기 생겨야 뜻이 있다
#     · 데이터 폴더의 baseline/ · backup/
#     · 앱 로그에 엑셀 관련 줄
#
#   🔴 공유폴더가 비어 있으면 **로그를 본다.** 못 쓰면 화면에는 아무 오류도
#      안 뜨고 로그에만 남는다 — 그것이 이 시스템의 가장 조용한 고장이다.
#
#   --make 는 scripts/workbook-selftest.ts 를 불러 **직접 만들고** 네 파일이
#   생겼는지 스스로 확인한다. 앱이 이미 만들었으면 다시 쓸 뿐 해롭지 않다.

set -u
D=/volume1/dss
DATA=$D/inventory-data
CF=$D/deploy/docker-compose.nas.yml
ENVF=$D/deploy/.env.nas
DOCKER=/usr/local/bin/docker
SHARE="/volume1/2_AS센터/2. 부품 관리/1. 재고 및 부품 입출고 관리/4. 재고관리 시스템"

MODE=look
[ "${1:-}" = "--make" ] && MODE=make
FAIL=0

say() { echo "$@"; }
ok()  { echo "  ✓ $*"; }
bad() { echo "  ✗ $*"; FAIL=1; }

say "현황판 엑셀 확인 · $(date '+%F %T')"
say

say "══ 1. 🔴 직원이 탐색기로 여는 자리 ══"
say "  $SHARE"
if [ -d "$SHARE" ]; then
  ls -la "$SHARE" | sed 's/^/      /'
  N=$(find "$SHARE" -maxdepth 1 -name '*.xlsx' 2>/dev/null | wc -l)
  if [ "${N:-0}" -ge 1 ]; then
    ok "엑셀 $N 개가 있다 — 직원이 열 수 있다"
  else
    bad "아직 엑셀이 없다 — 아래 로그를 보세요"
  fi
else
  bad "공유폴더가 없다"
fi

say
say "══ 2. 데이터 폴더 (프로그램이 쓰는 자리) ══"
for p in baseline backup; do
  if [ -d "$DATA/$p" ]; then
    say "  · $p/ — 파일 $(find "$DATA/$p" -type f 2>/dev/null | wc -l)개"
  else
    say "  · $p/ — 아직 없다 (첫 파일을 만들 때 생긴다)"
  fi
done
say "  · workbook/ (공유폴더가 덧씌운 자리):"
ls -la "$DATA/workbook" 2>&1 | sed 's/^/      /'

say
say "══ 3. 앱 로그 — 엑셀 관련 줄 (마지막 40줄에서 추린다) ══"
say "  🔴 못 쓰면 화면에는 아무 오류도 안 뜬다. 로그에만 남는다."
"$DOCKER" logs --tail 40 dss-inventory 2>&1 \
  | grep -i "workbook\|엑셀\|xlsx\|EACCES\|EPERM\|permission\|denied\|error" \
  | tail -15 | sed 's/^/      /' || say "      (추려진 줄이 없다)"

say
say "══ 4. 앱이 돌고 있나 ══"
if "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-inventory; then
  ok "dss-inventory 가 돌고 있다 · $("$DOCKER" ps --format '{{.Status}}' --filter name=dss-inventory)"
else
  bad "dss-inventory 가 안 돈다"
fi

if [ "$MODE" = make ]; then
  say
  say "══ 5. --make — 직접 만들어 본다 (workbook-selftest) ══"
  say "  🔴 도구 컨테이너로 돈다. 네 파일을 만들고 스스로 확인한다."
  "$DOCKER" compose -f "$CF" --env-file "$ENVF" --profile tools \
    run --rm tools-inventory npx tsx scripts/workbook-selftest.ts 2>&1 | sed 's/^/  /'
  say
  say "══ 6. 만든 뒤 공유폴더를 다시 본다 ══"
  ls -la "$SHARE" 2>&1 | sed 's/^/      /'
fi

say
say "══════════════════════════════════════════════════════════"
if [ "$FAIL" = 0 ]; then
  say "  ✅ 현황판 엑셀이 공유폴더에 있습니다."
  say "  🔵 직원분들이 여는 자리:"
  say "     \\\\DSS-NAS\\2_AS센터\\2. 부품 관리\\1. 재고 및 부품 입출고 관리\\4. 재고관리 시스템"
else
  say "  🔴 아직입니다. 위 로그를 Claude 에게 보여 주세요."
  say "  🔵 앱이 스스로 만들기를 기다려 보려면 1분 뒤 이 명령을 다시 돌리세요."
  say "  🔵 직접 만들어 보려면:"
  say "     sh /volume1/dss/setup/27-transition-workbook.sh --make"
fi
say "══════════════════════════════════════════════════════════"
exit "$FAIL"
