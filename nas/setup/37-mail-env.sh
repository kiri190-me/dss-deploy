#!/bin/sh
# dss-deploy/nas/setup/37-mail-env.sh — 포털에 메일 설정을 넣는다 (2026-10-24)
#
# 🔴 NAS 에서 돈다. 사람이 `sudo -i` 로 돌린다.
#    md5 를 맞춘다:  md5sum /volume1/dss/setup/37-mail-env.sh
#
# ── 무엇을 하나 ───────────────────────────────────────────────────────
#   A/S 의 설정 파일에 있는 **메일 일곱 줄**을 포털의 설정 파일로 옮긴다.
#   서른다섯째 배포부터 **포털이 결재 알림 메일을 보낸다.** 그런데 포털에는
#   메일 설정이 한 줄도 없다 — 🔴 없으면 **오류 없이 한 통도 안 나간다.**
#
#     가져올 곳 : /volume1/dss/deploy/env/as.env
#     넣을 곳   : /volume1/dss/deploy/env/auth.env
#
#   🔵 설정 이름이 양쪽 **똑같다** — 포털의 메일 코드가 A/S 것을 베껴 왔다.
#      그래서 값을 고칠 것 없이 줄째로 옮기면 된다. 같은 사내 메일 계정이다.
#
# ── 🔴 값을 화면에 한 번도 안 찍는다 ──────────────────────────────────
#   이 스크립트는 **이름만** 보여 준다. 평문은 파일 사이에서만 움직인다.
#
# ── 돌리는 법 ─────────────────────────────────────────────────────────
#     sh /volume1/dss/setup/37-mail-env.sh            재기만 한다
#     sh /volume1/dss/setup/37-mail-env.sh --go       실제로 넣는다
#
#   🔴 **두 번 돌려도 안전하다** — 이미 있으면 아무것도 안 하고 멈춘다.
#      같은 이름이 두 줄이면 **아래가 이기는데**, 그것이 조용한 사고의 단골이다.
set -u

SRC=/volume1/dss/deploy/env/as.env
DST=/volume1/dss/deploy/env/auth.env
BKD=/volume1/dss/backups
STAMP=$(date +%Y%m%d-%H%M%S)

KEYS='MAIL_SMTP_HOST MAIL_SMTP_PORT MAIL_SMTP_SECURE MAIL_SMTP_USER MAIL_SMTP_PASSWORD MAIL_SMTP_LEGACY_TLS MAIL_FROM'

MODE=check
case "${1:-}" in
  ""|--check) MODE=check ;;
  --go)       MODE=go ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --go\n' "$1"; exit 2 ;;
esac

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
say() { printf '    %s\n' "$1"; }

printf '%s\n' "포털에 메일 설정 넣기   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 1. 두 파일이 있는가 ───────────────────────────────────────────────
printf '\n== 1. 파일 둘\n'
[ -f "$SRC" ] && ok "가져올 곳이 있다 ($SRC)" || bad "가져올 곳이 없다: $SRC"
[ -f "$DST" ] && ok "넣을 곳이 있다 ($DST)"   || bad "넣을 곳이 없다: $DST"
[ "$FAIL" = 0 ] || { printf '\n🔴 멈춘다.\n'; exit 1; }

# ── 2. 가져올 일곱이 다 있는가 (이름만) ───────────────────────────────
printf '\n== 2. A/S 쪽에 일곱이 다 있는가 — **이름만** 본다\n'
MISS=""
for k in $KEYS; do
  if grep -qE "^${k}=.+" "$SRC"; then printf '  ✓ %s\n' "$k"; PASS=$((PASS+1))
  else MISS="$MISS $k"; fi
done
[ -z "$MISS" ] || bad "A/S 쪽에 빠졌거나 비었다:$MISS"

# ── 3. 포털 쪽에 이미 있는가 ──────────────────────────────────────────
printf '\n== 3. 포털 쪽에 이미 있는가\n'
HAVE=$(grep -oE "^MAIL_[A-Z_]+" "$DST" 2>/dev/null | sort -u | tr '\n' ' ')
if [ -n "$HAVE" ]; then
  say "이미 있다: $HAVE"
  printf '%s\n' "🔵 **아무것도 안 한다.** 겹쳐 넣으면 같은 이름이 두 줄이 되고,"
  printf '%s\n' "   그때는 **아래 줄이 이긴다** — 위를 고치고 아래에 또 적는 사고가"
  printf '%s\n' "   하루에 네 번 난 적이 있다. 고치실 것이 있으면 손으로 고치세요."
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s\n' "$PASS" "$FAIL"
  exit 0
fi
ok "포털 쪽에 MAIL_ 이름이 하나도 없다 (겹칠 걱정 없음)"

if [ "$FAIL" != 0 ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s\n' "$PASS" "$FAIL"
  printf '%s\n' "🔴 위 ✗ 를 먼저 보세요. **아무것도 안 바꿨다.**"
  exit 1
fi

if [ "$MODE" = check ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s\n' "$PASS" "$FAIL"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.** 넣으려면: sh $0 --go"
  exit 0
fi

# ── 4. 넣는다 ─────────────────────────────────────────────────────────
printf '\n== 4. 넣는다\n'
mkdir -p "$BKD"
BK="$BKD/auth.env.$STAMP"
cp -p "$DST" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
chmod 600 "$BK"
ok "사본 $BK ($(wc -l < "$BK") 줄)"

L0=$(wc -l < "$DST")
{
  printf '\n'
  printf '# 결재 알림 메일 (2026-10-24, 37-mail-env.sh) — A/S 와 같은 계정\n'
  for k in $KEYS; do grep -E "^${k}=" "$SRC" | head -1; done
} >> "$DST"
L1=$(wc -l < "$DST")

# 🔴 주인과 모드를 원래대로 되돌린다 — 되읽어서 확인한다.
chown root:root "$DST" 2>/dev/null
chmod 600 "$DST"
# 🔵 보통 아홉 늘어난다(일곱 + 빈 줄 + 주석). 🔴 다만 원래 파일이 줄바꿈으로
#    끝나지 않았으면 여덟이 된다 — 첫 printf 가 그 마지막 줄을 닫는 데 쓰인다.
#    그래서 여기서 멈추지 않는다. **진짜 잣대는 아래의 「이름마다 꼭 한 줄」이다.**
say "줄 수 $L0 → $L1 (늘어난 것 $((L1 - L0)) — 여덟이나 아홉이면 정상)"
if [ "$((L1 - L0))" = "9" ] || [ "$((L1 - L0))" = "8" ]; then ok "줄 수가 그만큼 늘었다"
else bad "줄 수가 $((L1 - L0)) 늘었다 — 여덟이나 아홉이어야 한다"; fi

printf '    들어간 이름:\n'
for k in $KEYS; do
  n=$(grep -cE "^${k}=.+" "$DST")
  if [ "$n" = "1" ]; then printf '      ✓ %s\n' "$k"; PASS=$((PASS+1))
  else bad "$k 가 ${n}줄이다 (하나여야 한다)"; fi
done

# 🔴 주인·모드를 **되읽어** 확인한다. chmod 를 불렀다는 것과 그렇게 됐다는 것은 다르다.
OWN=$(ls -l "$DST" | awk '{print $3":"$4}')
PERM=$(ls -l "$DST" | awk '{print $1}')
say "주인 $OWN · 모드 $PERM"
printf '%s' "$PERM" | grep -q '^-rw-------' && ok "다른 사람은 못 읽는다 (600)" || bad "모드가 $PERM 다 — 600 이어야 한다"

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s\n' "$PASS" "$FAIL"
if [ "$FAIL" = 0 ]; then
  printf '%s\n' "✅ 넣었다. **평문은 한 번도 안 찍혔다.**"
  printf '%s\n' "  🔴 포털을 다시 띄워야 읽는다 — 37-deploy.sh --go 가 그 일을 한다."
  printf '%s\n' "  사본: $BK"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  cp -p $BK $DST"
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
