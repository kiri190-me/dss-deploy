#!/bin/sh
# /volume1/dss/setup/27-transition-go.sh — 전환일 ⑤⑥⑦ : 실자료를 넣는다
#
# 🔴 사람이 sudo -i 로 돌린다.
#     sh /volume1/dss/setup/27-transition-go.sh            ← 읽기만 (기본값)
#     sh /volume1/dss/setup/27-transition-go.sh --go       ← 🔴 **실제로 넣는다**
#
# ══ 🔴 --go 는 한 번만 돌릴 수 있다 ════════════════════════════════════
#
#   import-workbook.ts --real 은 **빈 DB 가 아니면 스스로 거절한다.**
#   되돌리려면 DB 를 비우고 처음부터 다시 해야 한다(절차서 5절).
#   그래서 이 스크립트는 인자 없이 돌리면 **아무것도 바꾸지 않고**
#   들어갈 것과 지금 상태만 보여 준다.
#
#   🔵 넣는 일 자체는 **한 트랜잭션**이다 — 중간에 멈추면 아무것도 안 들어간다.
#
# ══ 무엇을 넣나 ════════════════════════════════════════════════════════
#
#   ⑤ seed-items.ts      항목 19종(기준 자료). 몇 번 돌려도 같다.
#   ⑥ import-workbook.ts --real
#        현황판 : 현황판_최신사본_2026-10-01.xlsx  (담당자 가공본)
#        판정표 : 과거기록_묶음판정_2026-10-02.csv
#        전환일 : 아래 TRANSITION_DATE
#   ⑦ 넣은 뒤 숫자를 **DB 에서 되읽어** 검사 때 숫자와 견준다.
#
#   🔴 2026-10-14 검사 실측(--check-only):
#        부품 319 · 수량 합 10,002
#        사용 1349/237/55/11 = 1652 · 입고 545/85/17/15 = 662
#        못 붙인 26건 · 칸 사정 2건
#      이 숫자와 다르면 **멈추고 알린다.**

set -u
D=/volume1/dss
DATA=$D/inventory-data
CF=$D/deploy/docker-compose.nas.yml
ENVF=$D/deploy/.env.nas
DOCKER=/usr/local/bin/docker

WB="현황판_최신사본_2026-10-01.xlsx"
DEC="과거기록_묶음판정_2026-10-02.csv"
TRANSITION_DATE=2026-10-14
OUT="못붙인_$TRANSITION_DATE.csv"

MODE=check
[ "${1:-}" = "--go" ] && MODE=go
FAIL=0

say()  { echo "$@"; }
ok()   { echo "  ✓ $*"; }
bad()  { echo "  ✗ $*"; FAIL=1; }

# 🔴 DB 사용자 이름은 .env.nas 에 있다 — 'postgres' 로 박지 않는다.
#    27-inventory-check.sh 가 쓰는 그 방식 그대로다(-X 로 .psqlrc 를 안 읽는다).
#    2026-10-14: 이것을 지어냈다가 값이 통째로 빈 채 돌아와 멈춘 적이 있다.
set -a; . "$ENVF" 2>/dev/null; set +a

# 읽기 전용 SQL 한 줄
qa() {
  "$DOCKER" exec -i dss-pg-app psql -X -tAq \
    -U "${APP_POSTGRES_USER:-postgres}" -d dss_inventory -c "$1" 2>/dev/null | tr -d '\r'
}

say "DSS 재고 관리 — 전환일 실자료 넣기 · $(date '+%F %T')"
case "$MODE" in
  check) say "  🔵 인자 없이 돌렸습니다 — **읽기만 합니다. 아무것도 안 바꿉니다.**" ;;
  go)    say "  🔴 --go — **실제로 넣습니다. 한 번만 돌릴 수 있습니다.**" ;;
esac
say "  · 현황판 : $WB"
say "  · 판정표 : $DEC"
say "  · 전환일 : $TRANSITION_DATE"
say

say "══ 1. 들어갈 파일이 제자리에 있나 ══"
for f in "$DATA/import/$WB" "$DATA/import/$DEC"; do
  if [ -s "$f" ]; then
    ok "$(basename "$f") · $(stat -c '%s바이트 %a %u:%g' "$f")"
  else
    bad "$(basename "$f") 가 없다 — 27-transition-files.sh 를 먼저"
  fi
done

say
say "══ 2. 🔴 DB 가 비어 있나 (절차서 전제 3번) ══"
say "  표는 있어야 하고(--init 이 만들었다), 자료는 0 이어야 한다."
T=$(qa "select count(*) from information_schema.tables where table_schema='public'")
# 🔴 「못 물어봤다」와 「0이다」는 다르다. 빈 값을 숫자처럼 다루면 엉뚱한 말을 한다.
if [ -z "$T" ]; then
  bad "DB 에 묻지 못했다 — psql 이 아무것도 안 돌려줬다"
  say "     dss-pg-app 이 떠 있는지, .env.nas 의 APP_POSTGRES_USER 가 맞는지 보세요."
else
  say "  · 표 $T 개 (13 이어야 한다)"
  [ "$T" -ge 13 ] && ok "표가 섰다" || bad "표가 모자라다 — 27-deploy.sh --init 을 먼저"
fi
for t in parts stock_entries legacy_records; do
  N=$(qa "select count(*) from $t")
  if [ -z "$N" ]; then
    bad "$t 를 세지 못했다 — 표가 없거나 묻지 못했다"
  elif [ "$N" = "0" ]; then
    ok "$t 가 0줄이다"
  else
    bad "🔴 $t 에 $N 줄이 이미 있다 — **빈 DB 가 아니다.** 넣지 않는다"
  fi
done

if [ "$FAIL" != 0 ]; then
  say
  say "══ 🔴 위 ✗ 를 먼저 보세요. 아무것도 하지 않았습니다 ══"
  exit 1
fi

if [ "$MODE" = check ]; then
  say
  say "══ 준비가 됐습니다 ══"
  say "  🔴 넣으려면 **--go** 를 붙여 다시 돌리세요:"
  say "     sh /volume1/dss/setup/27-transition-go.sh --go"
  say
  say "  🔴 그 전에 확인해 주세요:"
  say "     · 사람들에게 **엑셀 기입 중단**을 알렸습니까"
  say "     · 전환일을 $TRANSITION_DATE 로 둘 것입니까"
  say "  🔵 넣는 일은 한 트랜잭션입니다 — 중간에 멈추면 아무것도 안 들어갑니다."
  exit 0
fi

say
say "══ 3. ⑤ 항목 19종 (몇 번 돌려도 같다) ══"
"$DOCKER" compose -f "$CF" --env-file "$ENVF" --profile tools \
  run --rm tools-inventory npx tsx scripts/seed-items.ts 2>&1 | sed 's/^/  /'
say

say "══ 4. ⑥ 🔴 실자료 가져오기 — 한 트랜잭션 ══"
"$DOCKER" compose -f "$CF" --env-file "$ENVF" --profile tools \
  run --rm tools-inventory \
  npx tsx scripts/import-workbook.ts --real \
    "/data/import/$WB" \
    --decisions "/data/import/$DEC" \
    --unmatched "/data/import/$OUT" \
    --transition-date "$TRANSITION_DATE" 2>&1 | sed 's/^/  /'
say

say "══ 5. ⑦ 🔴 DB 에서 **되읽어** 검사 때 숫자와 견준다 ══"
say "  「넣었다」가 아니라 「들어갔나」를 본다."
say

P=$(qa "select count(*) from parts where is_deleted = false")
PMIN=$(qa "select coalesce(min(no),0) from parts where is_deleted = false")
PMAX=$(qa "select coalesce(max(no),0) from parts where is_deleted = false")
say "  · 부품 $P 개 (No. $PMIN ~ $PMAX) — 기대 319 · 1 ~ 319"
[ "${P:-0}" = "319" ] && ok "부품 수가 맞다" || bad "부품 수가 다르다"

Q=$(qa "select coalesce(sum(quantity),0) from stock_balances")
Z=$(qa "select count(*) from stock_balances where quantity = 0")
say "  · 수량 합 $Q · 0인 부품 $Z 개 — 기대 10,002 · 61"
[ "${Q:-0}" = "10002" ] && ok "수량 합이 맞다" || bad "수량 합이 다르다 (기대 10002)"

L=$(qa "select count(*) from legacy_records")
say "  · 과거 기록 $L 건 — 기대 2,288"
[ "${L:-0}" = "2288" ] && ok "과거 기록 수가 맞다" || bad "과거 기록 수가 다르다 (기대 2288)"

say "  · 과거 기록 갈래:"
qa "select match_status || ' : ' || count(*) from legacy_records group by 1 order by 1" | sed 's/^/      /'

TD=$(qa "select value from app_settings where key = 'transition_date'")
say "  · 전환일 $TD — 기대 $TRANSITION_DATE"
[ "$TD" = "$TRANSITION_DATE" ] && ok "전환일이 맞다" || bad "전환일이 다르다"

A=$(qa "select count(*) from audit_logs where action = 'WORKBOOK_IMPORT'")
say "  · 가져오기 감사 기록 $A 줄 — 기대 1"
[ "${A:-0}" = "1" ] && ok "감사 기록이 남았다" || bad "감사 기록이 1줄이 아니다"

say
say "══════════════════════════════════════════════════════════"
if [ "$FAIL" = 0 ]; then
  say "  ✅ 숫자가 전부 맞습니다."
  say
  say "  다음 — 앱이 현황판 엑셀을 만드는지 봅니다:"
  say "     sh /volume1/dss/setup/27-transition-workbook.sh"
  say
  say "  🔵 앱은 이미 돌고 있습니다. 15초쯤 뒤 스스로 첫 파일을 만듭니다."
else
  say "  🔴 숫자가 어긋납니다. **여기서 멈추고 Claude 에게 알리세요.**"
  say "     되돌리려면 DB 를 비우고 처음부터 (절차서 5절)."
fi
say "══════════════════════════════════════════════════════════"
exit "$FAIL"
