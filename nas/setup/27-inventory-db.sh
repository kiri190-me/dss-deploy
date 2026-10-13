#!/bin/sh
# 재고 관리(dss-inventory)의 DB 와 롤을 만든다. 🔴 사람이 sudo -i 로 돌린다.
#   실행:  sh /volume1/dss/setup/27-inventory-db.sh
#
# 게시판(25-board-db.sh) · 휴가(13-leave-db.sh)와 같은 절차다. 그것을 베꼈다.
# 🔴 새 DB 컨테이너를 만들지 않는다 — 이미 도는 dss-pg-app 안에 만든다.
#    dss-pg-app 은 2026-09-14 에 만들어졌으므로 nas/init/app/01-roles.sh 를
#    고쳐도 저절로 적용되지 않는다(그 스크립트는 볼륨이 빌 때 한 번만 돈다).
#    여기서 손으로 만든다. 이 절을 건너뛰면 DB 가 없어 앱이 뜨자마자 죽는다.
#
# 🔴 비밀번호는 이 파일에 적지 않는다. 다 만든 뒤 27-inventory-pw.sh 가
#    무작위로 만들어 롤과 .env.nas 두 곳에 한꺼번에 넣는다.
#
# 🔴 **이 스크립트는 표를 만들지 않는다.** 빈 DB 를 만들 뿐이다. 표(열셋)는
#    27-deploy.sh --init 이 마이그레이션으로 세운다 — 사용자 승인 뒤에.
#    실자료(부품·과거 기록 수천 줄)는 **여기에도 거기에도 없다.** 그것은
#    전환일 작업이고 전용 절차서가 따로 있다
#    (dss-inventory/docs/전환일_절차서_2026-10-12.md).
#
# 두 번 돌려도 안전하다 — 이미 있으면 만들지 않고 건너뛴다.

set -u
DOCKER=/usr/local/bin/docker
PG=dss-pg-app
DB=dss_inventory
ROLE=dss_inventory_app

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
  echo "  ✓ 롤 $ROLE 을 만들었다 (비밀번호는 아직 없다 — 27-inventory-pw.sh 가 넣는다)"
fi

if [ "${HAS_DB:-}" = 1 ]; then
  echo "  · DB 는 건너뛴다"
else
  # 🔴 인코딩·정렬을 다른 DB 와 **글자 그대로** 같게 맞춘다 — 한국어 정렬(ICU ko-KR).
  #    다르면 목록 차례가 사이트마다 달라진다. 25-board-db.sh 가 쓴 값 그대로다.
  #    🔴 재고 관리는 부품 품명·도번으로 정렬하는 목록이 많아 더 직접적으로 드러난다.
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
  echo "  ✓ DB $DB 를 만들었다 (빈 DB 다 — 표는 아직 하나도 없다)"
fi

echo
echo "══ 3. 확인 — 나란히 놓고 본다 ══"
echo "   🔴 주인과 정렬 칸이 다른 DB 와 **같은 줄**이어야 합니다."
"$DOCKER" exec -i "$PG" psql -X -U "$APP_POSTGRES_USER" -d postgres <<SQL
\pset border 2
-- 🔴 칸 이름을 늘리지 않는다. PostgreSQL 17 에서 daticulocale 이 datlocale 로
--    바뀌었다 — 판에 따라 없는 칸을 적으면 이 확인이 통째로 오류가 된다.
select datname as DB, pg_get_userbyid(datdba) as 주인,
       datcollate as 정렬, datctype as 글자종류,
       pg_encoding_to_char(encoding) as 인코딩,
       datlocprovider as 정렬제공자
from pg_database
where datname in ('dss_as','dss_meters','dss_improvements','dss_leave','dss_board','$DB')
order by datname;
SQL

echo
echo "══ 4. 표가 **없는지** 다시 본다 (0 이어야 합니다) ══"
echo "   🔴 여기서 0 이 아니면 누가 이미 마이그레이션을 돌린 것입니다."
echo "      전환 절차서는 「운영 DB 가 비어 있다」를 전제 3번으로 못 박고 있습니다 —"
echo "      실자료 가져오기는 빈 DB 가 아니면 스스로 거절합니다. 멈추고 알리세요."
"$DOCKER" exec -i "$PG" psql -X -U "$APP_POSTGRES_USER" -d "$DB" <<SQL
\pset border 2
select count(*) as public스키마_표 from information_schema.tables where table_schema='public';
SQL

echo
echo "══ 5. 다음 — 비밀번호를 한자리에서 정합니다 ══"
echo "   🔴 사람이 값을 정하지 않습니다. 스크립트가 무작위로 만들어"
echo "      롤과 .env.nas 두 곳에 **같은 값**을 넣고 TCP 로 붙어 확인까지 합니다."
echo
echo "     sh /volume1/dss/setup/27-inventory-pw.sh"
echo
echo "   (2026-09-29 에 사람이 정한 값에 ? 가 들어가 DATABASE_URL 이 통째로"
echo "    깨졌습니다 — 그래서 묻지 않고 영문·숫자로만 만듭니다.)"
