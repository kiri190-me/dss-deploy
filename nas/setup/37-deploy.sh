#!/bin/bash
# dss-deploy/nas/setup/37-deploy.sh — 서른다섯째 배포 ① (2026-10-24)
#
# 🔴 NAS 에서 돈다. DSM 터미널은 긴 명령을 잘라 먹으므로 **파일로 올려** 돌린다.
#    md5 를 맞춘다:  md5sum /volume1/dss/setup/37-deploy.sh
#
# ── 갈아 끼우는 것 넷 ─────────────────────────────────────────────────
#     ① 포털      dss-auth:1.8      → **dss-auth:1.9**        커밋 4
#     ② A/S       dss-as:3.0        → **dss-as:3.1**          커밋 2
#     ③ 재고      dss-inventory:0.4 → **dss-inventory:0.5**   커밋 2
#     ④ 휴가      dss-leave:0.3     → **dss-leave:0.4**       커밋 2
#   그리고 도구 하나:
#     ⑤ 포털도구  dss-auth-tools:1  → **dss-auth-tools:2**    🔴 마이그레이션용
#
#   🔵 **나머지 다섯은 안 건드린다** — PO 0.7 · 게시판 0.3 · 계측기 1.4 ·
#      개선요청 0.5 · RF 이슈관리 0.2 는 기준 SHA 이후 커밋이 **0** 이다(실측).
#
# ── 이 배포가 하는 일 ─────────────────────────────────────────────────
#   **결재가 생기면 그 자리에서 메일이 나간다.** 세 시스템(A/S·재고·휴가)이
#   결재를 만든 뒤 포털을 찌르고, 포털이 제 눈으로 다시 물어 메일을 짓는다.
#   🔵 통합 승인함 **사이트는 이번에 안 올라간다**(DNS·프록시가 끝난 뒤 따로).
#      승인함이 없어도 메일은 나간다 — 메일에서 **주소 줄만** 빠진다.
#
# ── 🔴 36 번과 다른 것 둘 ─────────────────────────────────────────────
#   ① 🔴 **`--migrate` 가 있다.** 포털에 마이그레이션 둘이 늘었다(0008 · 0009).
#        36 번에는 이 단계가 없었다. 🔴 **--migrate 와 --go 는 따로 부른다** —
#        마이그레이션이 덜 된 DB 에 새 판을 올리면 조용히 깨진다.
#   ② 🔴 **메일 설정 일곱 줄이 필요하다.** 포털이 메일을 보내는 것은 이번이
#        처음이다. `env/auth.env` 에 없으면 **오류 없이 한 통도 안 나간다.**
#        이 스크립트는 **이름만** 센다(값은 안 읽고 안 찍는다).
#
# ── 모드 다섯 ─────────────────────────────────────────────────────────
#   (기본)   --check      아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --preload             tar 다섯을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --migrate             🔴 **DB 가 바뀐다.** 도구 태그도 :1 → :2 로 고친다
#   --go                  compose 의 앱 태그 넷을 바꾸고 다시 띄운다
#   --rollback            앱 넷을 옛 판으로 되돌린다
#
#   🔴 차례:  --check → --preload → --migrate → --go
#   🔴 **마이그레이션은 되돌아가지 않는다.** --rollback 은 앱만 되돌린다.
#      0008·0009 가 더하는 것은 **표 셋뿐**이고 기존 표를 안 건드리므로, 옛 판이
#      그 표들을 몰라도 멀쩡히 돈다(그래서 되돌릴 수 있다).
set -uo pipefail

D=/volume1/dss
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BKDB=$D/backups/db
AUTHENV=$D/deploy/env/auth.env
BK=$D/backups/docker-compose.nas.yml.v35-$(date +%Y%m%d-%H%M%S)

# ══ 이번에 갈아 끼우는 앱 넷 ══════════════════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
SITES='
auth|app-auth|dss-auth|dss-auth:1.9|dss-auth:1.8|dss-auth-1.9.tar|13100
as|app-as|dss-as|dss-as:3.1|dss-as:3.0|dss-as-3.1.tar|13000
inventory|app-inventory|dss-inventory|dss-inventory:0.5|dss-inventory:0.4|dss-inventory-0.5.tar|13800
leave|app-leave|dss-leave|dss-leave:0.4|dss-leave:0.3|dss-leave-0.4.tar|13700
'
# ══ tar 다섯의 지문 — 🔴 [배포본] 37-build.sh 가 굽고 **바로 잰 값**이다 ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 하나라도 어긋나면 옮기다 깨진 것이다. 통과로 세지 않는다.
TARS='
dss-auth-1.9.tar|113688576|63722183fe5b002974033541dcb11ed9|sha256:74646e8a3ed03d4e3c70923446c7255eff95f19af10cc59e1f77582348cabdec
dss-auth-tools-2.tar|212256256|aad5847de2730347953904e75246d128|sha256:dce1716e7509f78de44710774329c9c02910d10ffed23e7d4c70c59df47aff41
dss-as-3.1.tar|132441088|3201d29ac366e0b5e815aa8102611899|sha256:b248233cefa6f7a59dde91154cb1f3fc709d272e0aed368fdd8123566074b090
dss-inventory-0.5.tar|95443456|9fd397e66b669d52eea27e6296e39ce5|sha256:e160ea7727cd17dad9a54efdf223654f5f700b6f4ae4948e110e5b1713a75b4f
dss-leave-0.4.tar|75085824|9b08d681a2c5d9e9671495eda0771a6b|sha256:0c616d88e5529d382e94ecf166dd831e84c85ca2808a08bae569879d4c79019a
'
TOOLS_OLD=dss-auth-tools:1
TOOLS_NEW=dss-auth-tools:2

# 🔴 포털이 메일을 보내려면 있어야 하는 이름 일곱. **값은 안 읽는다.**
MAILKEYS='MAIL_SMTP_HOST MAIL_SMTP_PORT MAIL_SMTP_SECURE MAIL_SMTP_USER MAIL_SMTP_PASSWORD MAIL_SMTP_LEGACY_TLS MAIL_FROM'

MODE=check
case "${1:-}" in
  --check|"")  MODE=check ;;
  --preload)   MODE=preload ;;
  --migrate)   MODE=migrate ;;
  --go)        MODE=go ;;
  --rollback)  MODE=rollback ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --preload · --migrate · --go · --rollback\n' "$1"; exit 2 ;;
esac

PASS=0; FAIL=0; WARN=0
ok()  { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
hm()  { WARN=$((WARN+1)); printf '  ? %s\n' "$1"; }
say() { printf '    %s\n' "$1"; }

rows()  { printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'; }
trows() { printf '%s\n' "$TARS"  | tr -d ' ' | grep -v '^$'; }
fld()   { printf '%s' "$1" | cut -d'|' -f"$2"; }

printf '%s\n' "서른다섯째 배포 ① — 포털 · A/S · 재고 · 휴가   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 공통: compose 에서 그 서비스의 image: 줄을 찾는다 ─────────────────
# 🔴 그 블록 안의 것 하나만 고쳐야 한다. 서비스 머리부터 다음 서비스 머리 전까지.
img_line() { # 1 서비스
  local s=$1 start next
  start=$(grep -n "^  ${s}:" "$CF" | head -1 | cut -d: -f1)
  [ -n "$start" ] || return 1
  next=$(awk -v s="$start" 'NR>s && /^  [a-z]/ {print NR; exit}' "$CF")
  awk -v s="$start" -v e="${next:-999999}" 'NR>s && NR<e && /^[[:space:]]*image:/ {print NR; exit}' "$CF"
}
tag_at() { awk -v n="$1" 'NR==n {print $2}' "$CF"; }

# 포털 DB 를 센다. 🔴 앱이 쓰는 길(컨테이너 안 psql)로 잰다.
pg() { docker exec -i dss-pg-auth sh -c "psql -U \"\$POSTGRES_USER\" -d dss_auth -X -tAq -c \"$1\"" 2>/dev/null | head -1 | tr -d ' \r'; }

# ── 1. 지금 상태 ──────────────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
[ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
say "compose 줄 수 $(wc -l < "$CF") · image: 줄 $(grep -c '^ *image:' "$CF")개"
for r in $(rows); do
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  L=$(img_line "$SVC") || { bad "$SVC — compose 에서 image: 줄을 못 찾았다"; continue; }
  CUR=$(tag_at "$L")
  ST=$(docker inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$(docker inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  say "$SVC — ${L}줄 · compose ${CUR} · 도는 것 ${RUN:-없음} (${ST:-?})"
  if [ "$CUR" = "$OLD" ]; then ok "$SVC 가 옛 판 $OLD 다 (갈아 끼울 준비)"
  elif [ "$CUR" = "$NEW" ]; then hm "$SVC 가 이미 $NEW 다 (다시 돌리는 중인가)"
  else bad "$SVC 의 태그가 $CUR 다 — 옛 판도 새 판도 아니다. 멈추고 알릴 것"; fi
done
TL=$(img_line tools-auth)
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  say "tools-auth — ${TL}줄 · $TCUR"
  if [ "$TCUR" = "$TOOLS_OLD" ]; then ok "tools-auth 가 $TOOLS_OLD 다 (--migrate 가 올린다)"
  elif [ "$TCUR" = "$TOOLS_NEW" ]; then hm "tools-auth 가 이미 $TOOLS_NEW 다"
  else bad "tools-auth 의 태그가 $TCUR 다 — 멈추고 알릴 것"; fi
else
  bad "compose 에 tools-auth 가 없다 — 마이그레이션을 돌릴 길이 없다"
fi

# ── 2. 🔴 메일 설정 일곱 (값은 안 읽는다) ─────────────────────────────
printf '\n== 2. 포털의 메일 설정 — **이름만** 센다\n'
printf '%s\n' "🔴 없으면 오류 없이 **한 통도 안 나간다.** 그래서 여기서 막는다."
if [ -f "$AUTHENV" ]; then
  MISS=""
  for k in $MAILKEYS; do
    if grep -qE "^${k}=.+" "$AUTHENV" 2>/dev/null; then :; else MISS="$MISS $k"; fi
  done
  if [ -z "$MISS" ]; then ok "일곱 이름이 다 있고 값이 비지 않았다"
  else bad "빠졌거나 비었다:$MISS  → $AUTHENV 에 넣으세요 (A/S 의 env/as.env 와 같은 값)"; fi
  # 🔴 같은 이름이 두 줄이면 **아래가 이긴다.** 조용한 사고의 단골이다.
  DUP=$(grep -oE "^MAIL_[A-Z_]+" "$AUTHENV" 2>/dev/null | sort | uniq -d | tr '\n' ' ')
  [ -z "$DUP" ] && ok "겹친 이름이 없다" || bad "이름이 겹쳤다: $DUP (아래 줄이 이긴다)"
else
  bad "$AUTHENV 가 없다"
fi
# 🔵 승인함 주소는 아직 없어도 된다 — 메일에서 주소 줄만 빠진다.
if grep -qE "^APPROVAL_INBOX_URL=.+" "$AUTHENV" 2>/dev/null; then
  ok "APPROVAL_INBOX_URL 이 있다 (메일에 주소 줄이 생긴다)"
else
  hm "APPROVAL_INBOX_URL 이 없다 — 괜찮다. 메일은 나가고 **주소 줄만** 빠진다"
fi

# ── 3. tar 다섯 ───────────────────────────────────────────────────────
printf '\n== 3. 들여올 이미지 다섯\n'
for t in $(trows); do
  TAR=$(fld "$t" 1); WSZ=$(fld "$t" 2); WM5=$(fld "$t" 3); WCFG=$(fld "$t" 4)
  T=$IMGD/$TAR
  if [ ! -f "$T" ]; then bad "$TAR 가 없다: $T — 먼저 올리세요"; continue; fi
  SZ=$(stat -c %s "$T" 2>/dev/null)
  M5=$(md5sum "$T" | awk '{print $1}')
  CFG=$(tar -xOf "$T" manifest.json 2>/dev/null | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 | sed 's|blobs/sha256/|sha256:|')
  say "$TAR — ${SZ}바이트 · md5 $M5"
  [ "$SZ"  = "$WSZ"  ] && ok "$TAR 크기가 구울 때와 같다" || bad "$TAR 크기가 다르다 (${SZ} ≠ ${WSZ}) — 옮기다 깨졌다"
  [ "$M5"  = "$WM5"  ] && ok "$TAR md5 가 같다"           || bad "$TAR md5 가 다르다 — 옮기다 깨졌다"
  [ "$CFG" = "$WCFG" ] && ok "$TAR 지문이 같다"           || bad "$TAR 지문이 다르다 (${CFG:-못 읽음})"
done
for r in $(rows); do
  OLD=$(fld "$r" 5)
  if docker image inspect "$OLD" >/dev/null 2>&1; then ok "$OLD 이 남아 있다 (되돌릴 길)"
  else hm "$OLD 이 없다 — 그 시스템은 --rollback 을 못 쓴다"; fi
done

# ── 4. 백업 (DB 가 바뀐다) ────────────────────────────────────────────
#
# 🔴 **야간 백업(02:30)에 기대지 않는다.** 이 배포는 자정을 넘겨 도는 일이 잦고
#    (서른다섯째도 01:43 에 준비했다), 그러면 「오늘 백업이 없다」로 막힌다.
#    기다리는 것보다 **--migrate 가 그 자리에서 덤프를 뜨는** 편이 낫다 —
#    더 최신이고 시각에 안 매인다. 31-deploy.sh 도 같은 판단이었다.
#    🔵 그래서 여기서는 **재기만 하고 막지 않는다.** 막는 자리는 --migrate 다.
printf '\n== 4. 백업 — **DB 가 바뀌는 배포다**\n'
TODAY=$(date +%Y%m%d)
if [ -d "$BKDB" ]; then
  say "최근 백업 여섯:"
  ls -1t "$BKDB" 2>/dev/null | head -6 | sed 's/^/      /'
  HIT=$(ls -1 "$BKDB" 2>/dev/null | grep -c "$TODAY")
  if [ "${HIT:-0}" -gt 0 ]; then ok "오늘($TODAY) 백업이 ${HIT}개 있다"
  else hm "오늘($TODAY) 야간 백업이 아직 없다 (02:30 에 돈다) — 🔵 --migrate 가 그 자리에서 뜬다"; fi
  ok "백업 폴더에 닿는다 ($BKDB)"
else
  bad "$BKDB 가 없거나 못 읽는다 — 🔴 root 로 돌리고 있는지 보세요"
fi

# ── 5. 🔴 포털 DB 의 지금 (마이그레이션 전) ───────────────────────────
printf '\n== 5. 포털 DB 의 지금\n'
MIG0=$(pg "select count(*) from drizzle.__drizzle_migrations")
TBL0=$(pg "select count(*) from information_schema.tables where table_schema='public'")
APP0=$(pg "select count(*) from information_schema.tables where table_schema='public' and table_name like 'approval%'")
say "마이그레이션 기록 ${MIG0:-?} · 표 ${TBL0:-?} · approval* 표 ${APP0:-?}"
if [ -n "${MIG0:-}" ] && [ -n "${TBL0:-}" ]; then
  ok "포털 DB 에 붙어 잴 수 있다"
  say "🔵 --migrate 뒤 기대값: 기록 $((MIG0 + 2)) · 표 $((TBL0 + 3)) · approval* $((APP0 + 3))"
  say "   (0008 이 표 둘 · 0009 가 표 하나를 더한다. **기존 표는 안 건드린다**)"
else
  bad "포털 DB 를 못 쟀다 — dss-pg-auth 가 도는지 보세요"
fi

if [ "$MODE" = check ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.** 다음: --preload → --migrate → --go"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 6. --preload : tar 를 들여놓는다 ──────────────────────────────────
if [ "$MODE" = preload ] || [ "$MODE" = migrate ] || [ "$MODE" = go ]; then
  printf '\n== 6. tar 를 들여놓는다\n'
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 하고 멈춘다.**\n'; exit 1; fi
  for t in $(trows); do
    TAR=$(fld "$t" 1); WCFG=$(fld "$t" 4)
    T=$IMGD/$TAR
    # tar 이름에서 태그를 되돌린다: dss-auth-1.9.tar → dss-auth:1.9
    NEW=$(printf '%s' "${TAR%.tar}" | sed 's/-\([0-9][0-9.]*\)$/:\1/')
    if docker image inspect "$NEW" --format '{{.Id}}' 2>/dev/null | grep -q "$WCFG"; then
      ok "$NEW 는 이미 있고 지문이 같다 (건너뜀)"; continue
    fi
    docker load -i "$T" 2>&1 | sed 's/^/    /'
    FULL=$(docker image inspect "$NEW" --format '{{.Id}}' 2>/dev/null)
    if [ "$FULL" = "$WCFG" ]; then ok "$NEW 가 올라왔고 지문이 tar 와 같다"
    elif [ -n "$FULL" ]; then bad "$NEW 지문이 다르다 — 기대 $WCFG / 실제 $FULL"
    else bad "$NEW 가 안 올라왔다"; fi
  done
fi

if [ "$MODE" = preload ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **들여놓기만 했다 — 아직 안 갈아 끼웠다.** 다음: --migrate"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 7. --migrate : 🔴 DB 가 바뀐다 ────────────────────────────────────
if [ "$MODE" = migrate ]; then
  printf '\n== 7. 🔴 마이그레이션 — DB 가 바뀐다\n'
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **DB 를 안 건드리고 멈춘다.**\n'; exit 1; fi

  # ── 7-ㄱ. 🔴 지금 이 자리에서 덤프를 뜬다 ───────────────────────────
  #   🔴 **이것이 되돌릴 길이다.** 야간 백업(02:30)을 기다리지 않는다.
  #      마이그레이션은 되돌아가지 않으므로, 덤프 없이는 시작하지 않는다.
  printf '\n    ── 먼저 덤프를 뜬다\n'
  mkdir -p "$BKDB" 2>/dev/null
  DUMP="$BKDB/dss_auth-v35-$(date +%Y%m%d-%H%M%S).dump"
  if docker exec -i dss-pg-auth sh -c 'pg_dump -U "$POSTGRES_USER" -d dss_auth -Fc' > "$DUMP" 2>/dev/null; then
    DSZ=$(stat -c %s "$DUMP" 2>/dev/null || wc -c < "$DUMP")
    say "덤프 $DUMP (${DSZ:-?}바이트)"
    # 🔴 「파일이 생겼다」와 「쓸 만한 덤프다」는 다르다. 빈 파일도 생긴다.
    if [ "${DSZ:-0}" -gt 10240 ]; then ok "덤프가 ${DSZ}바이트다 (10KB 넘음)"
    else bad "덤프가 ${DSZ:-0}바이트뿐이다 — 쓸 수 없다. **DB 를 안 건드리고 멈춘다**"; fi
    # 🔴 **속을 본다.** 「파일이 생겼다」는 빈 파일로도 참이 된다.
    #    -Fc 덤프는 첫 다섯 글자가 PGDMP 다. 파이프로 pg_restore 를 먹이는 길은
    #    판에 따라 「읽을 수 없는 보관본」으로 죽으므로 쓰지 않는다.
    MAGIC=$(head -c 5 "$DUMP" 2>/dev/null)
    say "덤프 머리 다섯 글자: ${MAGIC:-없음}"
    [ "$MAGIC" = "PGDMP" ] && ok "제대로 된 -Fc 덤프다" || bad "머리가 PGDMP 가 아니다 — 덤프가 아니거나 깨졌다"
    # 🔴 표 이름이 실제로 들어 있는지도 본다 (-Fc 는 압축이라 글자가 안 보일 수
    #    있으므로, 못 찾았다고 ✗ 로 세지 않고 ? 로 둔다).
    if strings "$DUMP" 2>/dev/null | grep -q 'users'; then ok "덤프 안에 표 이름이 보인다"
    else hm "덤프 안에서 표 이름을 못 찾았다 (-Fc 압축이면 정상이다)"; fi
    chmod 600 "$DUMP" 2>/dev/null
  else
    bad "덤프를 못 떴다 — **DB 를 안 건드리고 멈춘다**"
  fi
  if [ "$FAIL" != 0 ]; then printf '\n🔴 되돌릴 길이 없다 — **멈춘다.**\n'; exit 1; fi

  # 🔴 도구 태그를 먼저 올린다. :1 로 돌리면 0008·0009 가 그 안에 없어
  #    **0건으로 조용히 끝난다.**
  cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
  ok "사본 $BK"
  L0=$(wc -l < "$CF"); IMGS0=$(grep -c '^ *image:' "$CF"); BEFORE=$(grep -n '^ *image:' "$CF")
  TL=$(img_line tools-auth) || { bad "tools-auth 를 못 찾았다"; exit 1; }
  TMP=$(mktemp) || exit 1
  awk -v n="$TL" -v to="$TOOLS_NEW" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
  cp "$TMP" "$CF"; rm -f "$TMP"
  AFTER=$(grep -n '^ *image:' "$CF"); DIFFN=$(diff <(printf '%s\n' "$BEFORE") <(printf '%s\n' "$AFTER") | grep -c '^[<>]')
  [ "$(tag_at "$TL")" = "$TOOLS_NEW" ] && ok "tools-auth → $TOOLS_NEW (${TL}줄)" || bad "tools-auth 태그가 $(tag_at "$TL") 다"
  [ "$(wc -l < "$CF")" = "$L0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
  [ "$(grep -c '^ *image:' "$CF")" = "$IMGS0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
  [ "$((DIFFN / 2))" = "1" ] && ok "image: 줄이 꼭 하나만 달라졌다" || bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — 남의 것을 건드렸다"
  docker compose -f "$CF" config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 어긋났다 — **사본으로 되돌리고 DB 는 안 건드린다.**\n'; cp "$BK" "$CF"; exit 1; fi

  # 🔴 돌리기 **직전에** 도구 이미지 안을 센다. 겉이 아니라 결과다 —
  #    drizzle/ 이 비어도 「0건 적용」으로 조용히 성공한다.
  printf '\n    ── 도구 이미지 안을 센다\n'
  INSQL=$(docker run --rm --entrypoint sh "$TOOLS_NEW" -c 'ls /app/drizzle/*.sql 2>/dev/null | wc -l' 2>/dev/null | tr -d ' \r')
  say "$TOOLS_NEW 안의 .sql: ${INSQL:-?}개 (0009 까지면 10개)"
  [ "${INSQL:-0}" = "10" ] && ok "도구 이미지가 0009 까지 담고 있다" || bad "도구 이미지 안이 ${INSQL:-?}개다 — 0건으로 끝날 수 있다"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 되돌리고 멈춘다.\n'; cp "$BK" "$CF"; exit 1; fi

  printf '\n    ── 돌린다\n'
  ( cd "$D/deploy" && docker compose -f "$CF" --env-file .env.nas --profile tools \
      run --rm tools-auth npm run db:migrate ) 2>&1 | tail -20 | sed 's/^/    /'

  printf '\n    ── 🔴 값으로 확인 (겉이 아니라 결과)\n'
  MIG1=$(pg "select count(*) from drizzle.__drizzle_migrations")
  TBL1=$(pg "select count(*) from information_schema.tables where table_schema='public'")
  APP1=$(pg "select count(*) from information_schema.tables where table_schema='public' and table_name like 'approval%'")
  say "기록 ${MIG0:-?} → ${MIG1:-?} · 표 ${TBL0:-?} → ${TBL1:-?} · approval* ${APP0:-?} → ${APP1:-?}"
  [ "${MIG1:-x}" = "$((MIG0 + 2))" ] && ok "마이그레이션 기록이 둘 늘었다" || bad "기록이 ${MIG0}→${MIG1:-?} 다 — 둘 늘어야 한다"
  [ "${TBL1:-x}" = "$((TBL0 + 3))" ] && ok "표가 셋 늘었다"             || bad "표가 ${TBL0}→${TBL1:-?} 다 — 셋 늘어야 한다"
  for t in approval_mail_kinds approval_mail_deliveries approval_inbox_views; do
    n=$(pg "select count(*) from information_schema.tables where table_schema='public' and table_name='$t'")
    [ "${n:-0}" = "1" ] && ok "표 $t 가 생겼다" || bad "표 $t 가 없다"
  done

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$FAIL" = 0 ]; then
    printf '%s\n' "✅ DB 가 바뀌었다. **앱은 아직 옛 판이다.** 다음: --go"
    printf '%s\n' "  🔵 0008·0009 는 표 셋을 더하기만 한다 — 옛 판이 그 표를 몰라도 멀쩡히 돈다."
    printf '%s\n' "  🔴 되돌릴 길(마이그레이션 전 덤프): $DUMP"
    printf '%s\n' "     쓸 일은 거의 없다 — 표를 더하기만 했으므로 그냥 두어도 해롭지 않다."
  else
    printf '%s\n' "🔴 위 ✗ 를 보세요. compose 사본: $BK"
  fi
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 8. --go / --rollback : 앱 태그 넷을 바꾼다 ────────────────────────
printf '\n== 8. compose 의 앱 태그 넷을 바꾼다\n'
if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi

# 🔴 --go 는 마이그레이션이 끝난 뒤여야 한다. 안 끝났으면 새 판이 없는 표를 읽는다.
if [ "$MODE" = go ]; then
  NEEDED=$((MIG0))   # 지금 값. 0008·0009 가 적용됐다면 여기엔 이미 반영돼 있다.
  for t in approval_mail_kinds approval_mail_deliveries approval_inbox_views; do
    n=$(pg "select count(*) from information_schema.tables where table_schema='public' and table_name='$t'")
    [ "${n:-0}" = "1" ] && ok "표 $t 가 있다 (마이그레이션이 끝났다)" || bad "표 $t 가 없다 — 🔴 --migrate 를 먼저 돌리세요"
  done
  if [ "$FAIL" != 0 ]; then printf '\n🔴 마이그레이션이 덜 됐다 — **멈춘다.**\n'; exit 1; fi
fi

cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
ok "사본 $BK"
L0=$(wc -l < "$CF"); IMGS0=$(grep -c '^ *image:' "$CF")
BEFORE=$(grep -n '^ *image:' "$CF")
# 🔴 공유폴더 두 줄(RF 이슈관리)이 살아남는지도 센다.
C7_0=$(grep -cE '^[[:space:]]*- .*:/mnt/nas7:ro' "$CF"); C1_0=$(grep -cE '^[[:space:]]*- .*:/mnt/nas1:ro' "$CF")

for r in $(rows); do
  SVC=$(fld "$r" 2); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  [ "$MODE" = rollback ] && { TO=$OLD; } || { TO=$NEW; }
  L=$(img_line "$SVC") || { bad "$SVC — image: 줄을 못 찾았다"; continue; }
  TMP=$(mktemp) || exit 1
  awk -v n="$L" -v to="$TO" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
  cp "$TMP" "$CF"; rm -f "$TMP"
  NOW=$(tag_at "$L")
  if [ "$NOW" = "$TO" ]; then ok "$SVC → $TO (${L}줄)"; else bad "$SVC 의 태그가 $NOW 다"; fi
done

L1=$(wc -l < "$CF"); IMGS1=$(grep -c '^ *image:' "$CF")
AFTER=$(grep -n '^ *image:' "$CF")
DIFFN=$(diff <(printf '%s\n' "$BEFORE") <(printf '%s\n' "$AFTER") | grep -c '^[<>]')
C7_1=$(grep -cE '^[[:space:]]*- .*:/mnt/nas7:ro' "$CF"); C1_1=$(grep -cE '^[[:space:]]*- .*:/mnt/nas1:ro' "$CF")
say "줄 수 $L0 → $L1 · image: 줄 $IMGS0 → $IMGS1 · 달라진 image: 줄 $((DIFFN / 2))개"
[ "$L1" = "$L0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
[ "$IMGS1" = "$IMGS0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
# 🔴 **남의 image: 줄을 건드리면 안 된다.** 달라진 것이 꼭 넷이어야 한다.
[ "$((DIFFN / 2))" = "4" ] && ok "image: 줄이 꼭 넷만 달라졌다 (우리 것)" || bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — 남의 것을 건드렸다"
[ "$C7_1" = "$C7_0" ] && [ "$C1_1" = "$C1_0" ] && ok "RF 이슈관리의 공유폴더 두 줄이 그대로다" || bad "공유폴더 줄이 달라졌다 ($C7_0→$C7_1 · $C1_0→$C1_1)"
docker compose -f "$CF" config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 9. 넷을 다시 띄운다 ───────────────────────────────────────────────
printf '\n== 9. 넷을 다시 띄운다\n'
printf '%s\n' "🔴 --no-deps 다 — 이 넷만 갈아 끼운다. 나머지 다섯과 DB 는 안 건드린다."
for r in $(rows); do
  CN=$(fld "$r" 3)
  say "$CN 지금: $(docker inspect -f '{{.Id}}' "$CN" 2>/dev/null | cut -c1-12)"
done
T0=$SECONDS
SVCS=$(for r in $(rows); do printf '%s ' "$(fld "$r" 2)"; done)
( cd "$D/deploy" && docker compose -f "$CF" --env-file .env.nas up -d --no-deps $SVCS ) 2>&1 | sed 's/^/    /'
say "뜨는 것을 20초 기다린다…"; sleep 20
say "정지 구간 $((SECONDS - T0))초"

# ── 10. 값으로 확인 ───────────────────────────────────────────────────
printf '\n== 10. 값으로 확인\n'
for r in $(rows); do
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5); PORT=$(fld "$r" 7)
  [ "$MODE" = rollback ] && TO=$OLD || TO=$NEW
  ST=$(docker inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$(docker inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  HL=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}없음{{end}}' "$CN" 2>/dev/null)
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$PORT/" 2>/dev/null)
  say "$CN — ${ST:-?} · 건강 ${HL:-?} · 이미지 ${RUN:-?} · 127.0.0.1:$PORT → ${CODE:-없음}"
  [ "$ST" = running ] && ok "$CN 가 돈다" || bad "$CN 가 안 돈다 (${ST:-못 찾음})"
  [ "$RUN" = "$TO" ] && ok "$CN 가 $TO 로 돈다" || bad "$CN 가 $RUN 로 돈다"
  printf '%s' "$CODE" | grep -qE '200|30[12]|307' && ok "$CN 가 응답한다 ($CODE)" || bad "$CN 응답이 ${CODE:-없음}"
done

# 🔴 새 통로가 실제로 서는지 — **값을 받아 본다.** 「있는가」는 조용히 통과한다.
printf '\n    ── 새 통로 (자격 없이 부르면 401 이 맞다)\n'
NC=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 -X POST \
      -d 'approverSub=none' http://127.0.0.1:13100/api/integration/approval-created 2>/dev/null)
say "POST /api/integration/approval-created → ${NC:-없음}"
if [ "${NC:-}" = "401" ]; then ok "새 통로가 서 있고 자격 없는 호출을 막는다"
elif [ "${NC:-}" = "404" ]; then bad "404 다 — 옛 판이 돌고 있다"
else hm "${NC:-없음} 이다 — 401 을 기대했다. 로그를 보세요"; fi

# 🔴 **안 건드린 다섯이 그대로 도는지** 센다 — 「옆으로 안 샜다」는 증거다.
printf '\n    ── 안 건드린 것들 (그대로여야 한다)\n'
for c in dss-meters dss-po dss-board dss-improvements dss-rf-trouble; do
  s=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  i=$(docker inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
  [ "$s" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
done

printf '\n    ── 최근 로그 (각 10줄)\n'
for r in $(rows); do
  CN=$(fld "$r" 3)
  printf '      ── %s\n' "$CN"
  docker logs --since 3m "$CN" 2>&1 | tail -10 | sed 's/^/        /'
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
if [ "$FAIL" = 0 ]; then
  printf '%s\n' "✅ 기계로 잴 수 있는 것은 전부 통과했다."
  printf '%s\n' "  compose 사본: $BK"
  printf '%s\n' "🔴 **마지막은 눈이다** — 쓰는 분이 볼 곳:"
  printf '%s\n' "     · 포털 /admin/notifications 에서 [시험 메일 보내기] 가 되는가"
  printf '%s\n' "     · 거기서 **갈래를 켠다** — 🔴 기본이 전부 꺼짐이라 안 켜면 한 통도 안 간다"
  printf '%s\n' "     · 결재를 하나 올리고 — 메일이 **바로** 오는가"
  printf '%s\n' "     · A/S · 재고 · 휴가가 평소대로 도는가"
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (앱만 되돌린다. 표 셋은 남는다)"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
