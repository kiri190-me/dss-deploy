#!/bin/sh
# 휴가 DB 비밀번호를 한 번에 정한다 — 롤 · .env.nas · 붙는지 확인까지.
#   실행:  sh /volume1/dss/setup/13-leave-pw.sh      (sudo -i 상태에서)
#
# 왜 한 스크립트인가: 같은 값이 두 곳에 들어가야 한다.
#   ① NAS 의 DB 롤 dss_leave_app   ② /volume1/dss/deploy/.env.nas 의 LEAVE_APP_PASSWORD
# 따로 하면 어긋나고, 어긋나면 앱이 뜨면서 password authentication failed 로 죽는다.
# 그때 원인을 찾느라 헤맨다. 그래서 한자리에서 넣고 **실제로 붙는 것까지** 본다.
#
# 🔴 입력한 글자는 화면에 보이지 않는다. 파일에도 root 600 으로만 남는다.

set -u
DOCKER=/usr/local/bin/docker
PG=dss-pg-app
DB=dss_leave
ROLE=dss_leave_app
ENVF=/volume1/dss/deploy/.env.nas

[ -r "$ENVF" ] || { echo "🔴 $ENVF 를 읽을 수 없습니다. sudo -i 로 돌리고 계십니까?"; exit 1; }
set -a; . "$ENVF"; set +a
: "${APP_POSTGRES_USER:?APP_POSTGRES_USER 가 .env.nas 에 없습니다}"

echo "══ 지금 상태 ══"
HASROLE=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "$APP_POSTGRES_USER" -d postgres \
  -c "select 1 from pg_roles where rolname='$ROLE'" 2>/dev/null)
[ "${HASROLE:-}" = 1 ] || { echo "🔴 롤 $ROLE 이 없습니다 — 13-leave-db.sh 를 먼저 돌리세요"; exit 1; }
echo "  ✓ 롤 $ROLE 있음"

HASPW=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "$APP_POSTGRES_USER" -d postgres \
  -c "select case when rolpassword is null then 'no' else 'yes' end from pg_authid where rolname='$ROLE'" 2>/dev/null)
echo "  롤 비밀번호: $([ "${HASPW:-}" = yes ] && echo '이미 있음(덮어씁니다)' || echo '없음')"

INENV=$(grep -cE '^[[:space:]]*(export[[:space:]]+)?LEAVE_APP_PASSWORD=' "$ENVF" 2>/dev/null)
echo "  .env.nas 의 LEAVE_APP_PASSWORD 줄: ${INENV:-0} 개"

echo
echo "══ 새 비밀번호를 정합니다 ══"
echo "  🔴 화면에 안 보입니다. 8글자 이상, 따옴표(\" ')와 백슬래시(\\)는 쓰지 마세요"
echo "     — 설정 파일에서 따로 처리해야 해서 어긋나기 쉽습니다."
printf "  새 비밀번호: "; stty -echo 2>/dev/null; read PW1; stty echo 2>/dev/null; echo
printf "  한 번 더   : "; stty -echo 2>/dev/null; read PW2; stty echo 2>/dev/null; echo

[ "$PW1" = "$PW2" ]   || { echo "🔴 두 번 입력한 값이 다릅니다. 아무것도 안 바꿨습니다."; exit 1; }
[ ${#PW1} -ge 8 ]     || { echo "🔴 8글자 이상이어야 합니다. 아무것도 안 바꿨습니다."; exit 1; }
case "$PW1" in
  *\"*|*\'*|*\\*) echo "🔴 따옴표나 백슬래시가 들어 있습니다. 아무것도 안 바꿨습니다."; exit 1 ;;
esac

echo
echo "══ 1. 롤에 넣습니다 ══"
# 🔴 비밀번호를 명령줄에 적지 않는다 — ps 목록에 잠깐 보인다. 표준입력으로 넘긴다.
printf "%s" "$PW1" | "$DOCKER" exec -i "$PG" sh -c '
  read -r PW
  PGPASSWORD="" psql -X -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres \
    -v pw="$PW" -c "ALTER ROLE '"$ROLE"' PASSWORD :'"'"'pw'"'"'"
' || { echo "🔴 롤에 넣지 못했습니다."; exit 1; }
echo "  ✓ 넣었다"

echo
echo "══ 2. .env.nas 에 적습니다 ══"
cp -a "$ENVF" "$ENVF.bak-$(date +%Y%m%d-%H%M%S)" || exit 1
echo "  · 먼저 사본을 떴습니다 ($ENVF.bak-…)"
# 있던 줄은 지우고 새로 붙인다 — 같은 이름이 둘이면 나중 것이 이겨서 헷갈린다.
grep -vE '^[[:space:]]*(export[[:space:]]+)?LEAVE_APP_PASSWORD=' "$ENVF" > "$ENVF.new" || exit 1
printf 'LEAVE_APP_PASSWORD=%s\n' "$PW1" >> "$ENVF.new" || exit 1
chown root:root "$ENVF.new" && chmod 600 "$ENVF.new" && mv "$ENVF.new" "$ENVF" || exit 1
echo "  ✓ 적었다 (root 600)"
echo "  · 줄 수: $(grep -cE '^LEAVE_APP_PASSWORD=' "$ENVF") 개 (1 이어야 합니다)"

echo
echo "══ 3. 🔴 진짜 확인 — 그 값으로 실제로 붙나 ══"
OUT=$(printf "%s" "$PW1" | "$DOCKER" exec -i "$PG" sh -c '
  read -r PW
  PGPASSWORD="$PW" psql -X -tAq -U '"$ROLE"' -d '"$DB"' -c "select 1" 2>&1')
case "$OUT" in
  1*) echo "  ✓ 붙었다 — 롤과 .env.nas 가 같은 값입니다" ;;
  *)  echo "  ✗ 못 붙었습니다. psql 이 말한 것:"
      echo "$OUT" | sed 's/^/     /' | head -4
      echo "  🔴 .env.nas 사본이 옆에 있습니다. 알려 주세요."
      exit 1 ;;
esac

PW1=; PW2=
echo
echo "══ 끝났습니다 ══"
echo "  이제 3단계(설정 파일)로 갑니다. 이 비밀번호를 다시 칠 일은 없습니다 —"
echo "  compose 가 .env.nas 에서 읽어 DATABASE_URL 을 조립합니다."
