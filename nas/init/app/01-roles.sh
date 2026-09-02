#!/bin/bash
# 업무용 인스턴스(dss-pg-app)의 롤·DB·권한.
#
# 컨테이너가 **처음 만들어질 때 한 번만** 돈다. 볼륨이 이미 있으면 실행되지 않는다.
# 나중에 고쳐도 반영되지 않으니, 바꿀 일이 생기면 psql로 직접 적용한다.
#
# .sql이 아니라 .sh인 이유: 비밀번호를 파일에 박지 않기 위해서다. docker의
# initdb는 .sql에 psql 변수를 넘길 방법이 없어서, 여기서 -v로 환경변수를 건넨다.
#
# 필요한 환경변수 (compose의 environment로 넘긴다):
#   AS_APP_PASSWORD      dss_app 의 비밀번호
#   METERS_APP_PASSWORD  dss_meters_app 의 비밀번호
# 둘은 **서로 달라야 한다.** 같은 값을 돌려쓰면 롤을 나눈 의미가 절반으로 준다.

set -euo pipefail

: "${AS_APP_PASSWORD:?AS_APP_PASSWORD 가 필요합니다}"
: "${METERS_APP_PASSWORD:?METERS_APP_PASSWORD 가 필요합니다}"

if [ "$AS_APP_PASSWORD" = "$METERS_APP_PASSWORD" ]; then
  echo "두 롤의 비밀번호가 같습니다. 서로 다른 값을 쓰세요." >&2
  exit 1
fi

psql -v ON_ERROR_STOP=1 \
     --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
     -v as_pw="$AS_APP_PASSWORD" \
     -v meters_pw="$METERS_APP_PASSWORD" <<-'SQL'

	-- 부트스트랩 슈퍼유저(POSTGRES_USER)는 앱이 쓰지 않는다.
	-- 앱마다 롤 하나, 그 롤이 소유하는 DB 하나.

	CREATE ROLE dss_app        LOGIN PASSWORD :'as_pw';
	CREATE ROLE dss_meters_app LOGIN PASSWORD :'meters_pw';

	-- ICU 로케일을 쓰는 이유: 계측기·고객 이름에 한글·영문·숫자·한자가 섞인다.
	-- 순수 한글만이면 바이트 순서로도 가나다 순이 되지만(U+AC00–U+D7A3이 이미
	-- 가나다 순이라), 섞이는 순간 어긋난다.
	CREATE DATABASE dss_as
	  OWNER dss_app
	  ENCODING 'UTF8'
	  LOCALE_PROVIDER icu ICU_LOCALE 'ko-KR'
	  LOCALE 'C.UTF-8'
	  TEMPLATE template0;

	CREATE DATABASE dss_meters
	  OWNER dss_meters_app
	  ENCODING 'UTF8'
	  LOCALE_PROVIDER icu ICU_LOCALE 'ko-KR'
	  LOCALE 'C.UTF-8'
	  TEMPLATE template0;

	-- ⚠️ 이 네 줄이 통합의 안전을 지탱한다.
	-- PostgreSQL 기본값은 "모든 롤이 모든 DB에 접속 가능"이다. PUBLIC에 CONNECT가
	-- 기본으로 부여돼 있기 때문이다. 걷어내지 않으면 dss_meters_app으로 dss_as에
	-- 그냥 붙을 수 있고, 그러면 롤을 나눴다는 것이 착각이 된다.
	REVOKE CONNECT ON DATABASE dss_as     FROM PUBLIC;
	REVOKE CONNECT ON DATABASE dss_meters FROM PUBLIC;
	GRANT  CONNECT ON DATABASE dss_as     TO dss_app;
	GRANT  CONNECT ON DATABASE dss_meters TO dss_meters_app;

	-- PostgreSQL 15부터 public 스키마의 CREATE 권한이 PUBLIC에서 기본 제거됐다.
	-- 17을 쓰므로 여기서 추가로 할 일은 없다.

SQL

echo "dss-pg-app 초기화 완료 — dss_as / dss_meters, 롤 둘, CONNECT 분리"
echo "다음: 격리 검증을 돌린다 (runbook/01-postgres-통합.md 6절)"
