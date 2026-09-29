#!/bin/sh
# 휴가 시스템(dss-leave)의 DB 와 롤을 만든다. 🔴 사람이 sudo -i 로 돌린다.
#   실행:  sh /volume1/dss/setup/13-leave-db.sh
#
# 개선요청(runbook/06 ㄷ절)과 같은 절차다. dss-pg-app 은 2026-09-14 에 이미
# 만들어졌으므로 nas/init/app/01-roles.sh 를 고쳐도 저절로 적용되지 않는다 —
# 여기서 손으로 만든다. 이 절을 건너뛰면 DB 가 없어 앱이 뜨자마자 죽는다.
#
# 🔴 비밀번호는 이 파일에 적지 않는다. 다 만든 뒤 마지막 안내대로 psql 이
#    물어보게 한다 — 명령줄에 적으면 ps 목록에 잠깐 보인다.
#
# 두 번 돌려도 안전하다 — 이미 있으면 만들지 않고 건너뛴다.

set -u
DOCKER=/usr/local/bin/docker
PG=dss-pg-app
DB=dss_leave
ROLE=dss_leave_app

echo "══ 1. 지금 무엇이 있나 (읽기만) ══"
set -a; . /volume1/dss/deploy/.env.nas; set +a     # 🔴 값은 화면에 안 찍는다

HAS_ROLE=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "$APP_POSTGRES_USER" -d postgres \
  -c "select 1 from pg_roles where rolname='$ROLE'" 2>/dev/null)
HAS_DB=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "$APP_POSTGRES_USER" -d postgres \
  -c "select 1 from pg_database where datname='$DB'" 2>/dev/null)

echo "  롤 $ROLE : $([ "${HAS_ROLE:-}" = 1 ] && echo '이미 있다' || echo '없다 — 만든다')"
echo "  DB  $DB : $([ "${HAS_DB:-}" = 1 ] && echo '이미 있다' || echo '없다 — 만든다')"

echo
echo "══ 2. 만든다 ══"
if [ "${HAS_ROLE:-}" = 1 ]; then
  echo "  · 롤은 건너뛴다"
else
  "$DOCKER" exec -i "$PG" psql -X -q -v ON_ERROR_STOP=1 \
    -U "$APP_POSTGRES_USER" -d postgres <<SQL || exit 1
CREATE ROLE $ROLE LOGIN;
SQL
  echo "  ✓ 롤 $ROLE 을 만들었다 (비밀번호는 아직 없다 — 3번에서 넣는다)"
fi

if [ "${HAS_DB:-}" = 1 ]; then
  echo "  · DB 는 건너뛴다"
else
  # 🔴 정렬은 다른 DB 와 같게 맞춘다 — 한국어 정렬(ICU ko-KR).
  #    다르면 목록 차례가 사이트마다 달라진다.
  "$DOCKER" exec -i "$PG" psql -X -q -v ON_ERROR_STOP=1 \
    -U "$APP_POSTGRES_USER" -d postgres <<SQL || exit 1
CREATE DATABASE $DB
  OWNER $ROLE
  ENCODING 'UTF8'
  LOCALE_PROVIDER icu ICU_LOCALE 'ko-KR'
  LOCALE 'C.UTF-8'
  TEMPLATE template0;

REVOKE CONNECT ON DATABASE $DB FROM PUBLIC;
GRANT  CONNECT ON DATABASE $DB TO $ROLE;
SQL
  echo "  ✓ DB $DB 를 만들었다"
fi

echo
echo "══ 3. 확인 ══"
"$DOCKER" exec -i "$PG" psql -X -U "$APP_POSTGRES_USER" -d postgres <<SQL
\pset border 2
select datname as DB, pg_get_userbyid(datdba) as 주인, datcollate as 정렬
from pg_database where datname in ('dss_as','dss_meters','dss_improvements','$DB')
order by datname;
SQL

echo
echo "🔴 4. 비밀번호를 넣습니다 — 이 명령을 따로 치세요"
echo "   (입력한 글자는 화면에 안 보입니다)"
echo
echo "   /usr/local/bin/docker exec -it $PG \\"
echo "     psql -X -U \$APP_POSTGRES_USER -d postgres -c '\\password $ROLE'"
echo
echo "   🔴 .env.nas 에 적을 LEAVE_APP_PASSWORD 와 **글자 하나까지 같아야** 합니다."
echo "      틀리면 앱 로그에 password authentication failed 가 찍힙니다."
