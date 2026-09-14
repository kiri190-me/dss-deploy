#!/bin/bash
# /volume1/dss/setup/02-rehearse.sh — NAS 예행: DB 둘 → 격리 검증 → 복원 → 대조 → 앱 셋
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                        ← DSM 비밀번호. 한/영이 영문인지 먼저!
#   (NAS)         bash /volume1/dss/setup/02-rehearse.sh
#
#   처음부터 다시:  bash /volume1/dss/setup/02-rehearse.sh --reset
#                   (예행 DB 두 볼륨을 지우고 새로 만든다 — 예행 자료만 사라진다)
#   멈추기만:       /usr/local/bin/docker compose -f /volume1/dss/deploy/docker-compose.nas.yml \
#                     --env-file /volume1/dss/deploy/.env.nas down      (볼륨은 남는다)
#
# ── 무엇을 올리나 ──────────────────────────────────────────────────────
# 개발 PC 의 2026-09-14 사본이다. 개발 PC 시스템은 그대로 서비스하고, 여기서
# 입력한 것은 전환하는 날 최종 백업으로 다시 덮어쓴다(runbook/01 9절 부록 1번).
#   로그인  전체 · 계측기 전체(이 PC 사본, 사용자 결정) · A/S 표 구조 + 뼈대 20장(결정 D)
#
# 포털 등록 주소는 **NAS 사본에만** NAS 주소를 더한다. 개발 PC 의 로그인 DB 는
# 건드리지 않는다.
#
# 결과는 /volume1/dss/setup/logs/ 에 남는다. Claude 가 그 로그를 읽고 검수한다.
set -u
D=/volume1/dss
DEP=$D/deploy
DUMPS=$D/setup/dumps
DOCKER=/usr/local/bin/docker
NAS_IP=192.168.0.222
COMPOSE=("$DOCKER" compose -f "$DEP/docker-compose.nas.yml" --env-file "$DEP/.env.nas")
RESET=0; [ "${1:-}" = "--reset" ] && RESET=1

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
STAMP=$(date +%Y%m%d-%H%M%S)
LOG="$D/setup/logs/02-rehearse-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

PASS=0; FAIL=0; T0=$SECONDS
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
step() { echo; echo "── $* ($((SECONDS - T0))초)"; }
finish() {
  echo; echo "── 결과 — 통과 $PASS · 실패 $FAIL · 걸린 시간 $((SECONDS - T0))초"
  if [ "$FAIL" = 0 ]; then echo "  → 예행 기동 끝. Claude 에게 '끝났어'라고 알려 주세요."
  else echo "  → 실패가 있습니다. Claude 에게 알려 주세요. 로그: $LOG"; fi
}
die() { bad "$*"; echo "  여기서 멈춥니다."; finish; exit 1; }

# 비밀번호를 변수로만 읽는다. 절대 echo 하지 않는다.
set -a; . "$DEP/.env.nas"; set +a
echo "DSS NAS 예행 · $(date '+%F %T')$([ $RESET = 1 ] && echo ' · --reset')"

# ════════════════════════════════════════════════════════════════════
step "0. 준비물"
if [ -f "$D/setup/incoming/meters.env" ]; then
  cp "$D/setup/incoming/meters.env" "$DEP/env/meters.env" && chown root:root "$DEP/env/meters.env" && chmod 600 "$DEP/env/meters.env" \
    && rm -f "$D/setup/incoming/meters.env" && ok "meters.env 교체 (메일 계정 들어간 것)"
fi
grep -qE '^SMTP_PASSWORD=.+' "$DEP/env/meters.env" && ok "계측기 메일 계정 들어 있음" || bad "계측기 메일 계정 비어 있음 (알림 메일이 안 나간다)"
(cd "$DUMPS" && sha256sum -c --quiet SHA256SUMS) && ok "백업 4개 + 대조 기준 · 지문 일치" || die "백업 파일이 없거나 깨짐"
for t in dss-as dss-auth dss-meters; do "$DOCKER" image inspect "$t:1.1" >/dev/null 2>&1 || die "$t:1.1 이미지 없음 (01-prepare 먼저)"; done
ok "이미지 셋 있음"

if "$DOCKER" volume inspect dss-pg-app-data >/dev/null 2>&1 || "$DOCKER" volume inspect dss-pg-auth-data >/dev/null 2>&1; then
  if [ $RESET = 1 ]; then
    "${COMPOSE[@]}" down -v --remove-orphans >/dev/null 2>&1
    ! "$DOCKER" volume inspect dss-pg-app-data >/dev/null 2>&1 && ok "예행 DB 두 볼륨 지움 (--reset)" || die "볼륨을 지우지 못함"
  else
    die "예행 DB 가 이미 있습니다. 처음부터 다시 하려면 끝에 --reset 을 붙여 실행하세요."
  fi
fi

# ════════════════════════════════════════════════════════════════════
step "1. DB 둘 기동"
"${COMPOSE[@]}" up -d db-app db-auth 2>&1 | grep -vE '^\s*$' | sed 's/^/    /'
wait_healthy() {
  local i s
  for ((i = 0; i < 90; i++)); do
    s=$("$DOCKER" inspect -f '{{.State.Health.Status}}' "$1" 2>/dev/null)
    [ "$s" = healthy ] && return 0; sleep 2
  done; return 1
}
for c in dss-pg-app dss-pg-auth; do
  wait_healthy "$c" && ok "$c 정상 ($((SECONDS - T0))초)" || die "$c 가 정상 상태가 되지 않음 — docker logs $c"
done
"$DOCKER" logs dss-pg-app  2>&1 | grep -q '초기화 완료' && ok "업무 인스턴스 초기화 스크립트 돌았음" || bad "업무 인스턴스 초기화 흔적 없음"
"$DOCKER" logs dss-pg-auth 2>&1 | grep -q '초기화 완료' && ok "인증 인스턴스 초기화 스크립트 돌았음" || bad "인증 인스턴스 초기화 흔적 없음"
[ -z "$("$DOCKER" port dss-pg-app)$("$DOCKER" port dss-pg-auth)" ] && ok "DB 둘 모두 호스트 포트 없음" || bad "DB 에 호스트 포트가 열려 있음 ⚠️"

# ════════════════════════════════════════════════════════════════════
step "2. 격리 검증 — 반드시 거절돼야 하는 것 (runbook/01 6절 · 부록 11번)"
q() { "$DOCKER" exec "$@" >/dev/null 2>&1; }
must_fail() { local d=$1; shift; if q "$@"; then bad "$d — 붙어 버림 ⚠️"; else ok "$d — 거절됨"; fi; }
must_pass() { local d=$1; shift; if q "$@"; then ok "$d"; else bad "$d — 안 붙음"; fi; }
must_fail "계측기 롤 → A/S DB (소켓)"            dss-pg-app  psql -X -U dss_meters_app -d dss_as     -c 'select 1'
must_fail "A/S 롤 → 계측기 DB (소켓)"            dss-pg-app  psql -X -U dss_app        -d dss_meters -c 'select 1'
must_fail "계측기 롤 → A/S DB (TCP·비밀번호)"    -e PGPASSWORD="$METERS_APP_PASSWORD" dss-pg-app psql -X -h 127.0.0.1 -U dss_meters_app -d dss_as     -c 'select 1'
must_fail "A/S 롤 → 계측기 DB (TCP·비밀번호)"    -e PGPASSWORD="$AS_APP_PASSWORD"     dss-pg-app psql -X -h 127.0.0.1 -U dss_app        -d dss_meters -c 'select 1'
must_fail "업무 롤은 인증 인스턴스에 없다"        dss-pg-auth psql -X -U dss_app        -d dss_auth   -c 'select 1'
must_pass "A/S 롤 → A/S DB (TCP·새 비밀번호)"     -e PGPASSWORD="$AS_APP_PASSWORD"     dss-pg-app  psql -X -h 127.0.0.1 -U dss_app        -d dss_as     -c 'select 1'
must_pass "계측기 롤 → 계측기 DB (TCP·새 비밀번호)" -e PGPASSWORD="$METERS_APP_PASSWORD" dss-pg-app  psql -X -h 127.0.0.1 -U dss_meters_app -d dss_meters -c 'select 1'
must_pass "로그인 롤 → 로그인 DB (TCP·새 비밀번호)" -e PGPASSWORD="$AUTH_APP_PASSWORD"   dss-pg-auth psql -X -h 127.0.0.1 -U dss_auth_app   -d dss_auth   -c 'select 1'

# ════════════════════════════════════════════════════════════════════
step "3. 복원 (한 트랜잭션씩 — 실패하면 그 DB 는 비어 있는 채로 남는다)"
restore() { # 설명 컨테이너 파일 pg_restore 인자...
  local d=$1 c=$2 f=$3 t=$SECONDS; shift 3
  if "$DOCKER" exec -i "$c" pg_restore --exit-on-error --single-transaction "$@" \
       < "$DUMPS/$f" > "$D/setup/logs/restore-$STAMP-$f.txt" 2>&1; then
    ok "$d · $((SECONDS - t))초"
  else
    bad "$d — $(tail -3 "$D/setup/logs/restore-$STAMP-$f.txt" | tr '\n' ' ')"
  fi
}
restore "로그인 DB (전체)"                 dss-pg-auth auth.dump        -U dss_auth_app   -d dss_auth   --no-owner --role=dss_auth_app
restore "계측기 DB (전체)"                 dss-pg-app  meters.dump      -U dss_meters_app -d dss_meters --no-owner --role=dss_meters_app
restore "A/S 표 구조 (마이그레이션 98건의 모양)" dss-pg-app  as-schema.dump   -U dss_app        -d dss_as     --no-owner --role=dss_app
# 뼈대 표끼리 서로를 가리키는 외래키가 있어(pg_dump 경고) 자료만 넣을 때는 순서에 기대지
# 않도록 관리자 롤로 트리거를 잠시 끄고 넣는다. 한 트랜잭션이라 중간에 실패하면 없던 일이 된다.
restore "A/S 뼈대 20장 + 마이그레이션 기록"   dss-pg-app  as-skeleton.dump -U "$APP_POSTGRES_USER" -d dss_as --data-only --disable-triggers

# ════════════════════════════════════════════════════════════════════
step "4. 대조 — 표마다 행 수 (개발 PC 에서 뜬 값과 같아야 한다)"
counts() { # 컨테이너 롤 DB
  "$DOCKER" exec "$1" psql -X -At -U "$2" -d "$3" -c "SELECT '$3'||E'\t'||table_schema||'.'||table_name||E'\t'||(xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', table_schema, table_name), false, true, '')))[1]::text FROM information_schema.tables WHERE table_schema IN ('public','drizzle') AND table_type='BASE TABLE'"
}
ACT="$D/setup/logs/counts-$STAMP.tsv"
{ counts dss-pg-auth dss_auth_app dss_auth; counts dss-pg-app dss_meters_app dss_meters; counts dss-pg-app dss_app dss_as; } | LC_ALL=C sort > "$ACT"
if LC_ALL=C sort "$DUMPS/expected-counts.tsv" | diff -q - "$ACT" >/dev/null; then
  ok "세 DB 표 $(wc -l < "$ACT")개 · 행 수 전부 일치"
else
  bad "행 수가 다른 표가 있음 (< 기대 · > 실제):"
  LC_ALL=C sort "$DUMPS/expected-counts.tsv" | diff - "$ACT" | grep '^[<>]' | head -20 | sed 's/^/      /'
fi
awk -F'\t' '$1=="dss_as" && $2=="public.repair_cases"{exit ($3==0)?0:1}' "$ACT" && ok "A/S 수리 접수 0건 (결정 D — 1번부터 시작)" || bad "A/S 수리 접수가 0이 아님"
awk -F'\t' '$1=="dss_meters" && $2=="public.web_meters"{exit ($3==79)?0:1}' "$ACT" && ok "계측기 79대 (기준선 그대로)" || bad "계측기 대수가 79가 아님"
S=$("$DOCKER" exec dss-pg-app psql -X -At -U dss_meters_app -d dss_meters -c "select string_agg(x, ' < ' order by x) from unnest(array['가나','Zebra','apple','123','다람쥐']) x")
[ "$S" = "123 < 가나 < 다람쥐 < apple < Zebra" ] && ok "한글 정렬 (ICU ko-KR): $S" || bad "정렬이 예상과 다름: $S"

# ════════════════════════════════════════════════════════════════════
step "5. 포털 등록 주소 — NAS 사본에만 NAS 주소를 더한다"
# {lan} 은 컨테이너 안에서 172.x 로 펼쳐져 쓸모가 없다. 옛 값은 남겨 두고(해가 없다)
# {lan} 을 NAS 주소로 바꾼 값을 더한다. 백채널·런처는 값이 하나라 바꾼다.
"$DOCKER" exec -i dss-pg-auth psql -X -q -v ON_ERROR_STOP=1 -U dss_auth_app -d dss_auth <<SQL >/dev/null
UPDATE clients c SET
  redirect_uris = ARRAY(SELECT DISTINCT u FROM unnest(c.redirect_uris
      || ARRAY(SELECT replace(x, '{lan}', '$NAS_IP') FROM unnest(c.redirect_uris) x)) u),
  post_logout_redirect_uris = ARRAY(SELECT DISTINCT u FROM unnest(c.post_logout_redirect_uris
      || ARRAY(SELECT replace(x, '{lan}', '$NAS_IP') FROM unnest(c.post_logout_redirect_uris) x)) u),
  backchannel_logout_uri = replace(c.backchannel_logout_uri, '{lan}', '$NAS_IP'),
  launcher_url = replace(c.launcher_url, '{lan}', '$NAS_IP'),
  updated_at = now();
SQL
"$DOCKER" exec dss-pg-auth psql -X -At -U dss_auth_app -d dss_auth -F ' | ' -c \
  "select client_id, array_to_string(array(select u from unnest(redirect_uris) u where u like '%$NAS_IP%'), ' '), backchannel_logout_uri, coalesce(launcher_url,'-') from clients order by client_id" \
  | sed 's/^/    /'
n=$("$DOCKER" exec dss-pg-auth psql -X -At -U dss_auth_app -d dss_auth -c "select count(*) from clients where exists (select 1 from unnest(redirect_uris) u where u like 'http://$NAS_IP:%/api/auth/sso/callback') and backchannel_logout_uri like 'http://$NAS_IP:%'")
[ "$n" = 2 ] && ok "두 시스템 모두 NAS 주소로 로그인·로그아웃 통보 가능" || bad "NAS 주소가 들어간 시스템 ${n}개 (2개여야 함)"

# ════════════════════════════════════════════════════════════════════
step "6. 앱 셋 기동"
"${COMPOSE[@]}" up -d app-auth app-as app-meters 2>&1 | grep -vE '^\s*$' | sed 's/^/    /'
alive() { # 이름 포트 경로 → 90초 안에 2xx/3xx
  local i code
  for ((i = 0; i < 45; i++)); do
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://127.0.0.1:$2$3")
    case "$code" in 2*|3*) ok "$1 응답 $code ($((SECONDS - T0))초)"; return 0;; esac
    sleep 2
  done
  bad "$1 응답 없음 (마지막 코드 $code) — docker logs 확인"; return 1
}
alive "통합 로그인 127.0.0.1:13100" 13100 /.well-known/openid-configuration
alive "A/S         127.0.0.1:13000" 13000 /
alive "계측기      127.0.0.1:13300" 13300 /
ISS=$(curl -s --max-time 5 http://127.0.0.1:13100/.well-known/openid-configuration | sed -n 's/.*"issuer" *: *"\([^"]*\)".*/\1/p')
[ "$ISS" = "http://$NAS_IP:3100" ] && ok "포털 iss = $ISS (컨테이너 주소 아님)" || bad "포털 iss = '$ISS' (http://$NAS_IP:3100 이어야 함)"
BAD_BIND=$(netstat -tln 2>/dev/null | awk '{print $4}' | grep -E ':(13000|13100|13300)$' | grep -v '^127\.0\.0\.1:' || true)
[ -z "$BAD_BIND" ] && ok "앱 포트는 127.0.0.1 에만 열림 (사내망에 안 보임)" || bad "사내망에 열린 앱 포트: $BAD_BIND"

step "7. 자원 · 로그"
"$DOCKER" stats --no-stream --format '    {{.Name}}  메모리 {{.MemUsage}}  CPU {{.CPUPerc}}' $("${COMPOSE[@]}" ps -q) 2>/dev/null
echo "    NAS 전체: $(free -m | awk '/^Mem:/{printf "사용 %dMB · 가용 %dMB / %dMB", $3, $7, $2}')"
for c in dss-auth dss-as dss-meters; do
  echo "    [$c 로그 끝]"; "$DOCKER" logs --tail 6 "$c" 2>&1 | sed 's/^/      /'
done

finish
