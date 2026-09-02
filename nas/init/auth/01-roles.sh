#!/bin/bash
# 인증용 인스턴스(dss-pg-auth)의 롤·DB·권한.
#
# 이 인스턴스는 **혼자 산다.** 여기에 업무 DB를 얹지 않는다.
# 서명 개인키·카카오 시크릿·클라이언트 시크릿 해시를 다루는 곳이라 등급이 다르고,
# 업무 DB가 전부 털려도 여기에 닿지 못해야 dss-auth의 설계 원칙이 실제로 성립한다
# (dss-auth/src/lib/db/schema/users.ts 머리말 참고).
#
# 앱 DB가 하나뿐이라 CONNECT 분리가 형식처럼 보이지만 그대로 건다.
# 나중에 이 인스턴스에 무언가 하나라도 더 생기면, 그때는 이미 늦다.
#
# 필요한 환경변수:
#   AUTH_APP_PASSWORD   dss_auth_app 의 비밀번호

set -euo pipefail

: "${AUTH_APP_PASSWORD:?AUTH_APP_PASSWORD 가 필요합니다}"

psql -v ON_ERROR_STOP=1 \
     --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
     -v auth_pw="$AUTH_APP_PASSWORD" <<-'SQL'

	CREATE ROLE dss_auth_app LOGIN PASSWORD :'auth_pw';

	CREATE DATABASE dss_auth
	  OWNER dss_auth_app
	  ENCODING 'UTF8'
	  LOCALE_PROVIDER icu ICU_LOCALE 'ko-KR'
	  LOCALE 'C.UTF-8'
	  TEMPLATE template0;

	REVOKE CONNECT ON DATABASE dss_auth FROM PUBLIC;
	GRANT  CONNECT ON DATABASE dss_auth TO dss_auth_app;

SQL

echo "dss-pg-auth 초기화 완료 — dss_auth, 롤 하나"
