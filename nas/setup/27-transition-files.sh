#!/bin/sh
# /volume1/dss/setup/27-transition-files.sh — 전환일 입력물을 제자리에 놓는다
#
# 🔴 사람이 sudo -i 로 돌린다.  sh /volume1/dss/setup/27-transition-files.sh
#
# ══ 무엇을 하나 ════════════════════════════════════════════════════════
#
#   ① incoming 의 **양식 두 벌**을 데이터 폴더 templates/ 로
#   ② incoming 의 **묶음 판정표**와 **현황판 사본(담당자 가공본)**을 import/ 로
#   ③ 사내 공유폴더의 **최신 현황판 원본**을 import/ 로 (이름을 알기 쉽게 바꿔서)
#   ④ 전부 uid 1001 것으로 맞추고 **되읽어** 확인한다
#
#   🔴 DB 는 건드리지 않는다. 앱도 멈추지 않는다. 파일만 놓는다.
#   🔴 덮어쓰기 전에 있던 것은 .bak-<시각> 으로 남긴다(지우지 않는다).
#
# ══ 🔴 왜 이름이 중요한가 ══════════════════════════════════════════════
#
#   templates/ 의 두 이름은 compose 의 STOCK_*_TEMPLATE_PATH 와 **글자 하나까지**
#   같아야 한다. 다르면 현황판 엑셀이 안 만들어지는데 **화면은 멀쩡하다.**
#     STOCK_WORKBOOK_TEMPLATE_PATH = /data/templates/재고 및 견적 현황판 틀_과거줄포함.xlsx
#     STOCK_DOWNLOAD_TEMPLATE_PATH = /data/templates/재고 현황 내려받기 틀.xlsx
#
# ══ 🔴 현황판이 둘인 까닭 ══════════════════════════════════════════════
#
#   · 현황판_최신사본_2026-10-01.xlsx  — 정영빈 님이 **가공**한 것(세 시트 ·
#     수식 없음 · 담당자 컨펌본, 217KB). 전환일 절차서가 전제한 입력 꼴이다.
#   · 현황판_공유폴더_2026-10-12.xlsx  — 사내 공유폴더의 **원본**(1,029KB).
#     11일 더 최신이지만 수식과 서식이 그대로다.
#   🔴 둘 다 놓고 「--check-only」 로 각각 재 본 뒤 **사람이 고른다.**
#      --check-only 는 DB 에 아무것도 쓰지 않는다.

set -u
D=/volume1/dss
IN=$D/setup/incoming
DATA=$D/inventory-data
UID_APP=1001
GID_APP=1001
STAMP=$(date +%Y%m%d-%H%M%S)
FAIL=0

SHARE_SRC="/volume1/2_AS센터/2. 부품 관리/1. 재고 및 부품 입출고 관리/1. AS 관련 부품/2026.10.12 - 1. 재고 및 견적 현황판 (version 3).xlsx"
SHARE_DST_NAME="현황판_공유폴더_2026-10-12.xlsx"

say()  { echo "$@"; }
ok()   { echo "  ✓ $*"; }
bad()  { echo "  ✗ $*"; FAIL=1; }

# 1 원본경로  2 놓을폴더  3 보여줄이름
place() {
  _src=$1; _dir=$2; _name=$3
  if [ ! -s "$_src" ]; then
    bad "$_name — 원본이 없다: $_src"
    return 1
  fi
  if [ -e "$_dir/$(basename "$_src")" ] || [ -e "$_dir/$_name" ]; then
    _old=$_dir/$_name
    [ -e "$_old" ] && cp -a "$_old" "$_old.bak-$STAMP" && say "  · 옛것 사본: $(basename "$_old").bak-$STAMP"
  fi
  cp "$_src" "$_dir/$_name" || { bad "$_name — 복사 실패"; return 1; }
  return 0
}

say "══ 1. 양식 두 벌 → templates/ ══"
say "  🔴 이름이 compose 의 STOCK_*_TEMPLATE_PATH 와 글자 하나까지 같아야 한다."
place "$IN/재고 및 견적 현황판 틀_과거줄포함.xlsx" "$DATA/templates" "재고 및 견적 현황판 틀_과거줄포함.xlsx"
place "$IN/재고 현황 내려받기 틀.xlsx"             "$DATA/templates" "재고 현황 내려받기 틀.xlsx"

say
say "══ 2. 묶음 판정표와 담당자 가공본 → import/ ══"
place "$IN/과거기록_묶음판정_2026-10-02.csv"  "$DATA/import" "과거기록_묶음판정_2026-10-02.csv"
place "$IN/현황판_최신사본_2026-10-01.xlsx"   "$DATA/import" "현황판_최신사본_2026-10-01.xlsx"

say
say "══ 3. 사내 공유폴더의 최신 현황판 원본 → import/ ══"
say "  🔴 **읽기만** 한다. 공유폴더의 원본은 건드리지 않는다."
say "  $SHARE_SRC"
place "$SHARE_SRC" "$DATA/import" "$SHARE_DST_NAME"

say
say "══ 4. 주인을 맞추고 **되읽어** 본다 (uid $UID_APP) ══"
chown -R "$UID_APP:$GID_APP" "$DATA/templates" "$DATA/import" || bad "주인을 못 바꿨다 — sudo 로 돌리고 있나요?"
say "  · templates/"
ls -la "$DATA/templates" | sed 's/^/      /'
say "  · import/"
ls -la "$DATA/import" | sed 's/^/      /'

say
say "══ 5. 판정 ══"
# 🔴 「놓았다」가 아니라 「제자리에 제 이름으로 있는가」를 센다.
for f in "$DATA/templates/재고 및 견적 현황판 틀_과거줄포함.xlsx" \
         "$DATA/templates/재고 현황 내려받기 틀.xlsx" \
         "$DATA/import/과거기록_묶음판정_2026-10-02.csv" \
         "$DATA/import/현황판_최신사본_2026-10-01.xlsx" \
         "$DATA/import/$SHARE_DST_NAME"; do
  if [ -s "$f" ]; then
    ok "$(basename "$f") · $(stat -c '%s바이트 %u:%g' "$f")"
  else
    bad "$(basename "$f") 가 없거나 비었다"
  fi
done

OTHERS=$(find "$DATA/templates" "$DATA/import" ! -uid "$UID_APP" 2>/dev/null | wc -l)
[ "${OTHERS:-0}" = 0 ] && ok "둘 다 전부 uid $UID_APP 것이다" \
  || bad "주인이 다른 것이 ${OTHERS}개 있다"

say
if [ "$FAIL" = 0 ]; then
  say "══ 다 됐습니다 — 다음은 **검사**입니다 (DB 에 아무것도 안 씁니다) ══"
  say
  say "  🔴 현황판이 둘입니다. **각각** 재서 숫자를 견주세요."
  say
  say "  ① 담당자 가공본 (세 시트 · 수식 없음 · 2026-10-01):"
  say "     sh /volume1/dss/setup/27-transition-check.sh 1"
  say
  say "  ② 공유폴더 원본 (11일 더 최신 · 2026-10-12):"
  say "     sh /volume1/dss/setup/27-transition-check.sh 2"
  say
  say "  🔵 둘 다 돌려 보고 **출력을 Claude 에게 보여 주세요.**"
  say "     기대값(2026-10-07 시험): 부품 319 · 못 붙인 26건."
else
  say "══ 🔴 위 ✗ 를 보세요. 다음으로 가지 마세요 ══"
fi
exit "$FAIL"
