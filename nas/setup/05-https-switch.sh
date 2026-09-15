#!/bin/bash
# /volume1/dss/setup/05-https-switch.sh — 사내 주소를 https://*.dss21.co.kr 로 바꾼다 (되돌리기 포함)
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                                   ← 한/영이 영문인지 먼저!
#   (NAS)         bash /volume1/dss/setup/05-https-switch.sh             ← 전환
#   (NAS)         bash /volume1/dss/setup/05-https-switch.sh --rollback  ← 마지막 전환 전으로 되돌리기
#
# ── 먼저 끝나 있어야 하는 것 ─────────────────────────────────────────────
#   · 04-https-cert.sh (인증서) · DSM 리버스 프록시 HTTPS 규칙 셋 + 인증서 지정
#   · 카카오 개발자 콘솔에 https://login.dss21.co.kr/api/kakao/callback 등록 (옛 http 값은 남긴다)
#
# ── 하는 일 ─────────────────────────────────────────────────────────────
#   1. 먼저 볼 것 — 아무것도 바꾸지 않는다. 하나라도 틀리면 멈춘다.
#      · env 세 파일의 아홉 줄이 지금 http 값인가
#      · 앱 컨테이너 안에서 https://login.dss21.co.kr 에 닿는가 (토큰 교환 길)
#      · 포털 컨테이너 안에서 https://as·meters.dss21.co.kr 에 닿는가 (로그아웃 통보 길)
#   2. 되돌릴 거리 — env 세 파일 사본 + 포털 등록을 되돌리는 SQL → backups/https-switch-<시각>/
#   3. 포털 등록 — https 주소를 더한다. 옛 http 값은 남긴다: OIDC_ALLOW_HTTP_REDIRECT_URIS=false 면
#      포털이 http 주소를 대조 전에 거르므로 해가 없고, 되돌리기가 DB 를 덜 건드린다.
#      로그아웃 통보·런처 주소는 값이 하나라 바꾼다.
#   4. env 세 파일 — 아래 CHANGES 아홉 줄
#   5. 앱 셋만 다시 띄운다 — DB 는 건드리지 않는다 (1분 안팎 멈춤)
#   6. 확인 — 포털 iss, 두 시스템의 로그인 시작이 https 로 가고 포털이 그 주소를 받아 주는가
#
# 결과는 /volume1/dss/setup/logs/05-https-*.log. env 파일에서 찍는 것은 아래 아홉 줄(주소·스위치)뿐이다.
#
# ── 왜 두 값을 함께 바꾸나 ───────────────────────────────────────────────
# 포털은 OIDC_ISSUER 가 https 인데 OIDC_ALLOW_HTTP_REDIRECT_URIS=true 면 **시작을 거부한다**
# (dss-auth/src/lib/config/transport-check.ts). 한쪽만 바꾸면 포털이 뜨지 않는다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DEP=$D/deploy
DOCKER=/usr/local/bin/docker
COMPOSE=("$DOCKER" compose -f "$DEP/docker-compose.nas.yml" --env-file "$DEP/.env.nas")
OLD=http://192.168.0.222
LOGIN=https://login.dss21.co.kr
AS=https://as.dss21.co.kr
METERS=https://meters.dss21.co.kr

# 파일|키|지금 값|새 값
CHANGES=(
  "auth.env|OIDC_ISSUER|$OLD:3100|$LOGIN"
  "auth.env|KAKAO_REDIRECT_URI|$OLD:3100/api/kakao/callback|$LOGIN/api/kakao/callback"
  "auth.env|OIDC_ALLOW_HTTP_REDIRECT_URIS|true|false"
  "as.env|SSO_ISSUER|$OLD:3100|$LOGIN"
  "as.env|SSO_REDIRECT_URI|$OLD:3000/api/auth/sso/callback|$AS/api/auth/sso/callback"
  "meters.env|SSO_ISSUER|$OLD:3100|$LOGIN"
  "meters.env|SSO_REDIRECT_URI|$OLD:3300/api/auth/sso/callback|$METERS/api/auth/sso/callback"
  "meters.env|SESSION_COOKIE_SECURE|false|true"
  "meters.env|SITE_URL|$OLD:3300|$METERS"
)

MODE=switch; [ "${1:-}" = "--rollback" ] && MODE=rollback
[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
STAMP=$(date +%Y%m%d-%H%M%S)
LOG="$D/setup/logs/05-https-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

PASS=0; FAIL=0; T0=$SECONDS
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
step() { echo; echo "── $* ($((SECONDS - T0))초)"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# 파일 안에서 "키=" 로 시작하는 줄의 값. 값을 찍지 않는 곳에서만 쓴다.
getv() { awk -v k="$2" 'index($0, k"=") == 1 { print substr($0, length(k) + 2); n++ } END { exit n != 1 }' "$DEP/env/$1"; }
# 한 줄만 바꾼다. 소유자·권한(root 600)을 지키려고 새 파일로 바꿔치지 않고 내용만 덮어쓴다.
setv() {
  local f="$DEP/env/$1"
  awk -v k="$2" -v v="$3" 'index($0, k"=") == 1 { print k "=" v; n++; next } { print } END { exit n != 1 }' "$f" > "$f.new" \
    && cat "$f.new" > "$f"
  local rc=$?; rm -f "$f.new"; return $rc
}
# 컨테이너 안에서 주소를 불러 상태 코드만 받는다 (리다이렉트는 따라가지 않는다)
cfetch() {
  "$DOCKER" exec "$1" node -e "fetch(process.argv[1],{redirect:'manual'}).then(r=>console.log(r.status)).catch(e=>console.log('ERR '+((e.cause&&e.cause.code)||e.message)))" "$2" 2>&1 | tail -1
}
psql_auth() { "$DOCKER" exec -i dss-pg-auth psql -X -q -v ON_ERROR_STOP=1 -U dss_auth_app -d dss_auth "$@"; }
alive() { # 이름 포트 경로 → 90초 안에 2xx/3xx
  local i code
  for ((i = 0; i < 45; i++)); do
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://127.0.0.1:$2$3")
    case "$code" in 2*|3*) ok "$1 응답 $code ($((SECONDS - T0))초)"; return 0;; esac
    sleep 2
  done
  bad "$1 응답 없음 (마지막 코드 $code) — docker logs 확인"; return 1
}
issuer_of() { curl -s --max-time 8 "$1/.well-known/openid-configuration" | sed -n 's/.*"issuer" *: *"\([^"]*\)".*/\1/p'; }
recreate() {
  step "앱 셋 다시 띄우기 — DB 는 그대로"
  local t=$SECONDS
  "${COMPOSE[@]}" up -d --no-deps --force-recreate app-auth app-as app-meters 2>&1 | grep -vE '^\s*$' | sed 's/^/    /'
  alive "통합 로그인 127.0.0.1:13100" 13100 /.well-known/openid-configuration
  alive "A/S         127.0.0.1:13000" 13000 /
  alive "계측기      127.0.0.1:13300" 13300 /
  echo "    멈춰 있던 시간 약 $((SECONDS - t))초"
}

echo "DSS 주소 전환 ($MODE) · $(date '+%F %T')"

# ════════════════════════════════════════════════════════════════════
if [ "$MODE" = rollback ]; then
  BK=$(ls -1dt "$D"/backups/https-switch-* 2>/dev/null | head -1)
  step "되돌리기 — ${BK:-없음}"
  [ -n "$BK" ] && [ -s "$BK/auth.env" ] && [ -s "$BK/as.env" ] && [ -s "$BK/meters.env" ] && [ -s "$BK/clients-rollback.sql" ] \
    || stop "되돌릴 사본이 없습니다. 아무것도 바꾸지 않았습니다."
  for f in auth.env as.env meters.env; do cat "$BK/$f" > "$DEP/env/$f" && ok "$f 되돌림"; done
  { echo "BEGIN;"; cat "$BK/clients-rollback.sql"; echo "COMMIT;"; } | psql_auth >/dev/null && ok "포털 등록 되돌림" || bad "포털 등록을 되돌리지 못함"
  recreate
  ISS=$(issuer_of http://127.0.0.1:13100)
  [ "$ISS" = "$OLD:3100" ] && ok "포털 iss = $ISS" || bad "포털 iss = '$ISS' ($OLD:3100 이어야 함)"
  echo; echo "── 결과 ✓ $PASS · ✗ $FAIL"
  [ "$FAIL" = 0 ] && echo "→ 되돌렸습니다. 옛 주소 http://192.168.0.222:3100·3000·3300 으로 돌아갔습니다. Claude 에게 알려 주세요." \
                  || { echo "→ ✗ 줄이 있습니다. Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }
  exit 0
fi

# ════════════════════════════════════════════════════════════════════
step "1. 먼저 볼 것 — 아무것도 바꾸지 않는다"
DONE=0
for c in "${CHANGES[@]}"; do
  IFS='|' read -r f k old new <<<"$c"
  cur=$(getv "$f" "$k") || { bad "$f 에 $k 줄이 없거나 둘 이상"; continue; }
  if   [ "$cur" = "$old" ]; then ok "$f  $k=$cur"
  elif [ "$cur" = "$new" ]; then ok "$f  $k=$cur (이미 바뀜)"; DONE=$((DONE + 1))
  else bad "$f  $k 이 예상과 다름 — '$cur' ('$old' 이어야 함)"; fi
done
[ "$DONE" = "${#CHANGES[@]}" ] && stop "아홉 줄이 이미 모두 바뀌어 있습니다. 다시 할 것이 없습니다."
for c in dss-as dss-meters; do
  s=$(cfetch "$c" "$LOGIN/.well-known/openid-configuration")
  [ "$s" = 200 ] && ok "$c 안에서 $LOGIN 에 닿음 (토큰 교환 길)" || bad "$c 안에서 $LOGIN 에 못 닿음 — $s"
done
for u in "$AS/" "$METERS/"; do
  s=$(cfetch dss-auth "$u")
  case "$s" in 2*|3*) ok "dss-auth 안에서 $u 에 닿음 $s (로그아웃 통보 길)";; *) bad "dss-auth 안에서 $u 에 못 닿음 — $s";; esac
done
[ "$FAIL" = 0 ] || stop "아무것도 바꾸지 않았습니다."

# ════════════════════════════════════════════════════════════════════
step "2. 되돌릴 거리"
BK=$D/backups/https-switch-$STAMP
mkdir -p "$BK" && chown root:root "$BK" && chmod 700 "$BK"
for f in auth.env as.env meters.env; do cp -p "$DEP/env/$f" "$BK/$f"; done
"$DOCKER" exec dss-pg-auth psql -X -At -U dss_auth_app -d dss_auth -c \
  "select format('UPDATE clients SET redirect_uris=%L::text[], post_logout_redirect_uris=%L::text[], backchannel_logout_uri=%L, launcher_url=%L, updated_at=now() WHERE client_id=%L;', redirect_uris, post_logout_redirect_uris, backchannel_logout_uri, launcher_url, client_id) from clients" \
  > "$BK/clients-rollback.sql"
chmod 600 "$BK"/*
n=$(grep -c '^UPDATE clients' "$BK/clients-rollback.sql")
[ -s "$BK/auth.env" ] && [ -s "$BK/as.env" ] && [ -s "$BK/meters.env" ] && [ "$n" -ge 2 ] \
  && ok "$BK — env 셋 · 포털 등록 ${n}개" || stop "되돌릴 거리를 만들지 못했습니다. 아무것도 바꾸지 않았습니다."

# ════════════════════════════════════════════════════════════════════
step "3. 포털 등록 — https 주소를 더한다"
sub() { printf "replace(replace(replace(%s,'$OLD:3000','$AS'),'$OLD:3300','$METERS'),'$OLD:3100','$LOGIN')" "$1"; }
psql_auth >/dev/null <<SQL
BEGIN;
UPDATE clients c SET
  redirect_uris = ARRAY(SELECT DISTINCT u FROM unnest(c.redirect_uris
      || ARRAY(SELECT $(sub x) FROM unnest(c.redirect_uris) x)) u),
  post_logout_redirect_uris = ARRAY(SELECT DISTINCT u FROM unnest(c.post_logout_redirect_uris
      || ARRAY(SELECT $(sub x) FROM unnest(c.post_logout_redirect_uris) x)) u),
  backchannel_logout_uri = $(sub c.backchannel_logout_uri),
  launcher_url = $(sub c.launcher_url),
  updated_at = now();
COMMIT;
SQL
"$DOCKER" exec dss-pg-auth psql -X -At -U dss_auth_app -d dss_auth -F ' | ' -c \
  "select client_id, array_to_string(array(select u from unnest(redirect_uris) u where u like 'https://%'), ' '), coalesce(backchannel_logout_uri,'-'), coalesce(launcher_url,'-') from clients order by client_id" \
  | sed 's/^/    /'
n=$("$DOCKER" exec dss-pg-auth psql -X -At -U dss_auth_app -d dss_auth -c \
  "select count(*) from clients where ('$AS/api/auth/sso/callback' = any(redirect_uris) and backchannel_logout_uri like '$AS/%')
                                  or ('$METERS/api/auth/sso/callback' = any(redirect_uris) and backchannel_logout_uri like '$METERS/%')")
if [ "$n" = 2 ]; then ok "A/S · 계측기 모두 https 로 로그인·로그아웃 통보 가능"
else
  bad "https 가 들어간 시스템 ${n}개 (2개여야 함) — 포털 등록을 되돌린다"
  { echo "BEGIN;"; cat "$BK/clients-rollback.sql"; echo "COMMIT;"; } | psql_auth >/dev/null
  stop "env 파일은 바꾸지 않았고 포털 등록은 되돌렸습니다."
fi

# ════════════════════════════════════════════════════════════════════
step "4. env 세 파일"
for c in "${CHANGES[@]}"; do
  IFS='|' read -r f k old new <<<"$c"
  if setv "$f" "$k" "$new" && [ "$(getv "$f" "$k")" = "$new" ]; then ok "$f  $k=$new"
  else bad "$f  $k 를 바꾸지 못함"; fi
done
if [ "$FAIL" != 0 ]; then
  for f in auth.env as.env meters.env; do cat "$BK/$f" > "$DEP/env/$f"; done
  { echo "BEGIN;"; cat "$BK/clients-rollback.sql"; echo "COMMIT;"; } | psql_auth >/dev/null
  stop "env 와 포털 등록을 모두 전환 전으로 되돌렸습니다. 앱은 다시 띄우지 않았습니다."
fi

# ════════════════════════════════════════════════════════════════════
recreate
[ "$FAIL" = 0 ] || stop "앱이 뜨지 않았습니다. 되돌리려면: bash $0 --rollback"

# ════════════════════════════════════════════════════════════════════
step "6. 확인"
ISS=$(issuer_of "$LOGIN")
[ "$ISS" = "$LOGIN" ] && ok "포털 iss = $ISS" || bad "포털 iss = '$ISS' ($LOGIN 이어야 함)"
for c in dss-as dss-meters; do
  s=$(cfetch "$c" "$LOGIN/.well-known/openid-configuration")
  [ "$s" = 200 ] && ok "$c → 포털 (토큰 교환 길) 200" || bad "$c → 포털 $s"
done
check_start() { # 이름 시스템주소
  local enc loc err
  enc=$(printf %s "$2/api/auth/sso/callback" | sed 's#:#%3A#g; s#/#%2F#g')
  loc=$(curl -s -o /dev/null --max-time 8 -w '%{redirect_url}' "$2/api/auth/sso/start")
  case "$loc" in
    "$LOGIN/"*redirect_uri=$enc*) ok "$1 로그인 시작 → 포털 (redirect_uri = $2/api/auth/sso/callback)" ;;
    *) bad "$1 로그인 시작이 예상과 다름 → ${loc:-없음}"; return ;;
  esac
  err=$(curl -s -o /dev/null --max-time 8 -w '%{redirect_url}' "$loc")
  case "$err" in
    *oauth-error*) bad "$1 — 포털이 그 주소를 받지 않음 → $err" ;;
    *) ok "$1 — 포털이 받아 줌 → ${err%%\?*}" ;;
  esac
}
check_start "A/S   " "$AS"
check_start "계측기" "$METERS"
echo "    [참고] 옛 주소에서 로그인을 시작하면 → $(curl -s -o /dev/null --max-time 8 -w '%{redirect_url}' "$OLD:3000/api/auth/sso/start" | cut -c1-60)…"
for c in dss-auth dss-as dss-meters; do
  echo "    [$c 로그 끝]"; "$DOCKER" logs --tail 4 "$c" 2>&1 | sed 's/^/      /'
done

echo; echo "── 결과 ✓ $PASS · ✗ $FAIL · 걸린 시간 $((SECONDS - T0))초"
if [ "$FAIL" = 0 ]; then
  echo "→ 전환했습니다. 브라우저로 https://login.dss21.co.kr 에서 로그인해 보고 Claude 에게 알려 주세요."
  echo "  되돌리려면: bash $0 --rollback   (사본: $BK)"
else
  echo "→ ✗ 줄이 있습니다. Claude 에게 알려 주세요 (로그: $LOG)"
  echo "  되돌리려면: bash $0 --rollback"; exit 1
fi
