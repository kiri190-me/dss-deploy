#!/bin/sh
# PostgreSQL 인증이 지금 어떻게 열려 있는지 본다. 🔴 읽기만 한다.
#   실행:  sh /volume1/dss/setup/14-pg-auth-check.sh      (sudo -i 상태)
#
# ── 2026-09-29 결론: **고칠 것이 없다.** 그 까닭을 여기 남긴다 ──────────
#
# pg_hba.conf 가 이렇게 되어 있다:
#     local  all all                  trust   ← 유닉스 소켓
#     host   all all 127.0.0.1/32     trust   ← 루프백
#     host   all all ::1/128          trust   ← 루프백(IPv6)
#     host   all all all  scram-sha-256       ← 🔴 그 밖의 모든 곳
#
# 🔴 **앱은 `dss-pg-app:5432` 로 붙는다** — 도커 네트워크 주소(172.x)다.
#    그건 마지막 줄에 걸려 **이미 비밀번호 인증을 쓴다.**
#    trust 인 것은 컨테이너 안에서 자기 자신에게 붙을 때뿐이고, 밖에서는 닿지 않는다.
#
# 🔴 처음에 「trust 다」라고 잘못 읽은 까닭: 확인을 `-h 127.0.0.1` 로 했다.
#    소켓을 피하려고 TCP 를 쓴 것인데 **하필 루프백도 trust** 였다.
#    → 확인은 **앱이 실제로 쓰는 길**로 해야 한다. 이 스크립트 3번이 그것이다.
#
# 🔴 값은 한 글자도 안 찍는다. 있나/없나와 길이만.

set -u
DOCKER=/usr/local/bin/docker
ENVF=/volume1/dss/deploy/.env.nas

[ -r "$ENVF" ] || { echo "🔴 $ENVF 를 못 읽습니다. sudo -i 로 돌리고 계십니까?"; exit 1; }
set -a; . "$ENVF"; set +a

for PG in dss-pg-app dss-pg-auth; do
  echo "══════════════════════════════════════════════════════"
  echo "  $PG"
  echo "══════════════════════════════════════════════════════"

  echo "── 1. pg_hba.conf — 주석 뺀 실제 규칙"
  "$DOCKER" exec -i "$PG" sh -c \
    'grep -vE "^[[:space:]]*#|^[[:space:]]*$" "$PGDATA/pg_hba.conf"' 2>&1 | sed 's/^/    /'
  echo "    ↑ 맨 아래 줄이 앱에 적용된다. scram-sha-256 이어야 맞다."

  echo
  echo "── 2. 이미지가 trust 를 강제하나 (POSTGRES_HOST_AUTH_METHOD)"
  M=$("$DOCKER" exec -i "$PG" sh -c 'printf "%s" "${POSTGRES_HOST_AUTH_METHOD:-(없음)}"' 2>&1)
  echo "    $M   $([ "$M" = "(없음)" ] && echo '✓ 없다 — 좋다' || echo '🔴 있으면 컨테이너 재생성 때 되돌아간다')"

  echo
  echo "── 3. 롤마다 비밀번호가 붙어 있나 (값은 안 본다)"
  "$DOCKER" exec -i "$PG" sh -c "psql -X -U \"\$POSTGRES_USER\" -d postgres -tAF' | ' -c \"
    select rolname,
           case when rolpassword is null then 'X 없음'
                when rolpassword like 'SCRAM-SHA-256%' then 'O SCRAM'
                else '! 옛방식(md5)'
           end
    from pg_authid
    where rolcanlogin and rolname not like 'pg\\_%'
    order by rolname\"" 2>&1 | sed 's/^/    /'

  echo
  echo "── 4. 지금 붙어 있는 연결"
  "$DOCKER" exec -i "$PG" sh -c "psql -X -U \"\$POSTGRES_USER\" -d postgres -tAF' | ' -c \"
    select coalesce(usename,'(없음)'), coalesce(datname,'(없음)'), count(*)
    from pg_stat_activity where usename is not null
    group by 1,2 order by 1,2\"" 2>&1 | sed 's/^/    /'
  echo
done

echo "══════════════════════════════════════════════════════"
echo "  🔴 5. 앱이 실제로 쓰는 길로 붙어 본다"
echo "══════════════════════════════════════════════════════"
echo "  (-h 127.0.0.1 이 아니라 -h <컨테이너 이름> 이다. 도커 네트워크 주소로"
echo "   해석돼 pg_hba 의 마지막 줄(scram-sha-256)에 걸린다 — 앱과 같은 길이다.)"
echo

try_app() { # 1 컨테이너 2 롤 3 DB 4 비밀번호변수이름
  R=$2; DBN=$3
  PW=$(eval "printf '%s' \"\${$4:-}\"")
  if [ -z "$PW" ]; then printf "  %-22s · %-18s ⚠️ .env.nas 에 %s 가 없다\n" "$R" "$DBN" "$4"; return; fi

  OUT=$(printf '%s' "$PW" | "$DOCKER" exec -i "$1" sh -c "
    read -r P
    PGPASSWORD=\"\$P\" psql -X -tAq -h $1 -U $R -d $DBN -c 'select 1' 2>&1")
  case "$OUT" in
    1*) GOOD="✓ 맞는 비밀번호로 붙는다" ;;
    *"authentication failed"*) GOOD="🔴 비밀번호가 다르다 — .env.nas 와 롤이 어긋났다" ;;
    *) GOOD="⚠️ 판정 못 함: $(echo "$OUT" | head -1)" ;;
  esac

  BAD=$("$DOCKER" exec -i "$1" sh -c "
    PGPASSWORD='틀린값입니다' psql -X -tAq -h $1 -U $R -d $DBN -c 'select 1' 2>&1")
  case "$BAD" in
    *"authentication failed"*) GUARD="✓ 틀린 값은 거절" ;;
    1*) GUARD="🔴 틀린 값으로도 붙는다 — 인증이 안 걸려 있다" ;;
    *) GUARD="⚠️ 판정 못 함" ;;
  esac

  printf "  %-22s · %-18s %s · %s\n" "$R" "$DBN" "$GOOD" "$GUARD"
}

try_app dss-pg-app  dss_app               dss_as           AS_APP_PASSWORD
try_app dss-pg-app  dss_meters_app        dss_meters       METERS_APP_PASSWORD
try_app dss-pg-app  dss_improvements_app  dss_improvements IMPROVEMENTS_APP_PASSWORD
try_app dss-pg-app  dss_leave_app         dss_leave        LEAVE_APP_PASSWORD
try_app dss-pg-auth dss_auth_app          dss_auth         AUTH_APP_PASSWORD

echo
echo "══════════════════════════════════════════════════════"
echo "  .env.nas 의 앱 비밀번호 (값은 안 찍는다)"
echo "══════════════════════════════════════════════════════"
for K in AS_APP_PASSWORD METERS_APP_PASSWORD IMPROVEMENTS_APP_PASSWORD \
         LEAVE_APP_PASSWORD AUTH_APP_PASSWORD \
         APP_POSTGRES_PASSWORD AUTH_POSTGRES_PASSWORD; do
  V=$(eval "printf '%s' \"\${$K:-}\"")
  if [ -z "$V" ]; then printf "  %-26s ✗ 없다\n" "$K"; continue; fi
  case "$V" in
    *[\?\#\[\]\ \@\/\:\%]*) F="🔴 URL 을 깨뜨릴 글자가 있다" ;;
    *) F="✓ URL 안전" ;;
  esac
  printf "  %-26s 길이 %-3s %s\n" "$K" "${#V}" "$F"
done

echo
echo "══ 읽기만 했습니다. 아무것도 안 바꿨습니다. ══"
echo
echo "  🔴 5번이 전부 「✓ 맞는 비밀번호로 붙는다 · ✓ 틀린 값은 거절」이면"
echo "     **고칠 것이 없습니다.** 인증은 이미 제대로 걸려 있습니다."
