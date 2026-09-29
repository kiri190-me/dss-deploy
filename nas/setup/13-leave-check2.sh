#!/bin/sh
# 2단계(비밀번호)가 실제로 됐는지 본다. 🔴 읽기만 한다 — 아무것도 안 바꾼다.
#   실행:  sh /volume1/dss/setup/13-leave-check2.sh
#
# 🔴 값은 한 글자도 화면에 찍지 않는다. 「있나 · 붙나」만 본다.
#
# 왜 필요한가: 점검표(runbook/13)에 13-leave-pw.sh · 13-leave-env.sh 를 적어 두었는데
# 그 두 파일을 아직 만들지 않았다. 손으로 하셨을 수도, 중간에 막히셨을 수도 있어
# 결과만 확인한다. 「했다」가 아니라 「되어 있다」를 보는 것이다 —
# 2026-09-29 에 「만든 것과 도는 것은 다르다」를 네 번 봤다.

set -u
DOCKER=/usr/local/bin/docker
PG=dss-pg-app
DB=dss_leave
ROLE=dss_leave_app
ENVF=/volume1/dss/deploy/.env.nas
FAIL=0

echo "══ 1. .env.nas 에 LEAVE_APP_PASSWORD 줄이 있나 (값은 안 본다) ══"
if [ ! -r "$ENVF" ]; then
  echo "  ✗ $ENVF 를 읽을 수 없다 — sudo -i 로 돌리고 있습니까?"
  FAIL=1
else
  N=$(grep -c '^LEAVE_APP_PASSWORD=' "$ENVF" 2>/dev/null || echo 0)
  case "$N" in
    0) echo "  ✗ LEAVE_APP_PASSWORD 줄이 없다"; FAIL=1 ;;
    1) # 값이 비었는지만 본다. 내용은 안 찍는다.
       EMPTY=$(awk -F= '/^LEAVE_APP_PASSWORD=/{v=substr($0,index($0,"=")+1);
               gsub(/[ \t"'"'"'\r]/,"",v); print (length(v)==0)?"yes":"no"}' "$ENVF")
       if [ "$EMPTY" = yes ]; then
         echo "  ✗ 줄은 있는데 값이 비어 있다"; FAIL=1
       else
         echo "  ✓ 줄이 있고 값이 차 있다"
       fi ;;
    *) echo "  ✗ 같은 줄이 $N 개다 — 나중 것이 이긴다. 하나만 남기세요"; FAIL=1 ;;
  esac
fi

echo
echo "══ 2. 롤에 비밀번호가 붙어 있나 ══"
HASROLE=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "$APP_POSTGRES_USER" -d postgres \
  -c "select 1 from pg_roles where rolname='$ROLE'" 2>/dev/null)
if [ "${HASROLE:-}" != 1 ]; then
  echo "  ✗ 롤 $ROLE 이 없다 — 13-leave-db.sh 를 먼저 돌리세요"
  FAIL=1
else
  # rolpassword 가 비어 있으면 NULL 이다. 값 자체는 보지 않는다.
  HASPW=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "$APP_POSTGRES_USER" -d postgres \
    -c "select case when rolpassword is null then 'no' else 'yes' end
        from pg_authid where rolname='$ROLE'" 2>/dev/null)
  case "${HASPW:-}" in
    yes) echo "  ✓ 롤에 비밀번호가 붙어 있다" ;;
    no)  echo "  ✗ 롤은 있는데 비밀번호가 없다"; FAIL=1 ;;
    *)   echo "  ⚠️ 판정하지 못했다 (pg_authid 를 못 읽었다)" ;;
  esac
fi

echo
echo "══ 3. 🔴 진짜 확인 — 그 비밀번호로 실제로 붙나 ══"
echo "  (.env.nas 의 값으로 dss_leave 에 붙어 본다. 읽기만 한다.)"
if [ -r "$ENVF" ]; then
  set -a; . "$ENVF"; set +a
  OUT=$("$DOCKER" exec -i -e PGPASSWORD="${LEAVE_APP_PASSWORD:-}" "$PG" \
    psql -X -tAq -U "$ROLE" -d "$DB" -c "select 'PING ' || current_user" 2>&1)
  case "$OUT" in
    *"PING $ROLE"*)
      echo "  ✓ 붙었다 — .env.nas 의 값과 롤의 비밀번호가 같다" ;;
    *"password authentication failed"*)
      echo "  ✗ 비밀번호가 다르다 — .env.nas 와 롤에 넣은 값이 어긋났다"
      echo "     둘 중 하나를 고쳐 맞추세요. 어느 쪽이 맞는지는 사람만 압니다."
      FAIL=1 ;;
    *)
      echo "  ⚠️ 판정하지 못했다. psql 이 말한 것:"
      echo "$OUT" | sed 's/^/       /' | head -4
      FAIL=1 ;;
  esac
else
  echo "  · .env.nas 를 못 읽어 건너뛴다"
fi

echo
echo "══ 4. 곁들여 — 포털 등록(1단계)도 됐나 ══"
"$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth -X -tAq \
  -c "select client_id || \" · 활성 \" || is_active || \" · 명단필요 \" || requires_grant
      from clients where client_id = '"'"'dss-leave'"'"'"' 2>/dev/null \
  | sed 's/^/  /' || echo "  ⚠️ 못 읽었다"

echo
if [ "$FAIL" = 0 ]; then
  echo "══ 전부 통과 · 3단계(설정 파일)로 가도 됩니다 ══"
  exit 0
else
  echo "══ 🔴 위 ✗ 를 먼저 해결하세요 ══"
  echo "   비밀번호를 (다시) 넣는 명령 — 입력한 글자는 화면에 안 보입니다:"
  echo
  echo "   /usr/local/bin/docker exec -it $PG \\"
  echo "     psql -X -U \$APP_POSTGRES_USER -d postgres -c '\\password $ROLE'"
  echo
  echo "   .env.nas 는 root 600 입니다 — vi 나 nano 로 여시고"
  echo "   LEAVE_APP_PASSWORD=<같은값> 한 줄을 더하세요."
  exit 1
fi
