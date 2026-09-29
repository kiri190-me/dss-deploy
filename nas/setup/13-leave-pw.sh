#!/bin/sh
# 휴가 DB 비밀번호를 한 번에 정한다 — 롤 · .env.nas · TCP 로 붙는지 확인까지.
#   실행:  sh /volume1/dss/setup/13-leave-pw.sh      (sudo -i 상태에서)
#
# 왜 한 스크립트인가: 같은 값이 두 곳에 들어가야 한다.
#   ① NAS 의 DB 롤 dss_leave_app   ② /volume1/dss/deploy/.env.nas 의 LEAVE_APP_PASSWORD
# 따로 하면 어긋나고, 어긋나면 앱이 뜨면서 password authentication failed 로 죽는다.
#
# 왜 손으로 하나: nas/init/app/01-roles.sh 가 A/S·계측기·개선요청의 롤을 만들 때
# 비밀번호까지 넣었지만, 그 스크립트는 **DB 상자가 처음 만들어질 때 한 번만** 돈다
# (2026-09-14). 그 뒤에 생긴 사이트는 손으로 넣는다 — 개선요청도 그랬다(런북 06 ㄷ).
#
# 🔴 입력한 글자는 화면에 보이지 않는다. 파일에도 root 600 으로만 남는다.
# 🔴 비밀번호는 **표준입력으로만** 흐른다. 명령줄에 적으면 ps 목록에 잠깐 보인다.
#
# ── 2026-09-29 첫 판에서 틀렸던 것 둘 (같은 실수를 막으려 적어 둔다) ──
#   ① psql -c "…" 안에서는 psql 변수(:'pw')가 **풀리지 않는다.** 서버가 `:` 를
#      그대로 받아 문법 오류를 낸다. 변수는 표준입력으로 준 SQL 에서만 풀린다.
#      → 아예 변수를 쓰지 않고, SQL 문자열을 여기서 조립해 표준입력으로 넘긴다.
#      (따옴표·백슬래시를 아래에서 막으므로 리터럴로 안전하다.)
#   ② 확인을 `docker exec … psql` 로 하면 **유닉스 소켓**으로 붙는다. 소켓은 보통
#      trust 라 **비밀번호가 없어도 통과**한다 — 실제로 거짓 통과를 냈다.
#      앱은 TCP(dss-pg-app:5432)로 붙으므로 확인도 **-h 127.0.0.1** 로 한다.

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

INENV=$(grep -cE '^[[:space:]]*(export[[:space:]]+)?LEAVE_APP_PASSWORD=' "$ENVF" 2>/dev/null || true)
echo "  .env.nas 의 LEAVE_APP_PASSWORD 줄: ${INENV:-0} 개"

echo
echo "══ 새 비밀번호를 정합니다 ══"
echo "  🔴 화면에 안 보입니다. 8글자 이상, 따옴표(\" ')와 백슬래시(\\)는 쓰지 마세요."
echo "     사람이 쓸 일이 없는 값이라 아무렇게나 길게 치셔도 됩니다."
printf "  새 비밀번호: "; stty -echo 2>/dev/null; read PW1; stty echo 2>/dev/null; echo
printf "  한 번 더   : "; stty -echo 2>/dev/null; read PW2; stty echo 2>/dev/null; echo

[ "$PW1" = "$PW2" ]   || { echo "🔴 두 번 입력한 값이 다릅니다. 아무것도 안 바꿨습니다."; exit 1; }
[ ${#PW1} -ge 8 ]     || { echo "🔴 8글자 이상이어야 합니다. 아무것도 안 바꿨습니다."; exit 1; }
case "$PW1" in
  *\"*|*\'*|*\\*) echo "🔴 따옴표나 백슬래시가 들어 있습니다. 아무것도 안 바꿨습니다."; exit 1 ;;
esac

echo
echo "══ 1. 롤에 넣습니다 ══"
# SQL 을 여기서 조립해 **표준입력으로** 넘긴다 — 명령줄에 안 적는다.
# psql 변수를 쓰지 않는 까닭은 머리말 ① 참조.
printf "ALTER ROLE %s PASSWORD '%s';\n" "$ROLE" "$PW1" \
  | "$DOCKER" exec -i "$PG" sh -c 'psql -X -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres' \
  || { echo "🔴 롤에 넣지 못했습니다. 아무것도 안 바꿨습니다(.env.nas 는 그대로)."; exit 1; }
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
echo "══ 3. 🔴 진짜 확인 — TCP 로 실제로 붙나 ══"
echo "  (앱이 붙는 길과 같게 -h 127.0.0.1 로 붙습니다. 소켓으로 붙으면 비밀번호가"
echo "   없어도 통과해 버려 확인이 되지 않습니다 — 첫 판이 그래서 거짓 통과를 냈습니다.)"
OUT=$(printf '%s' "$PW1" | "$DOCKER" exec -i "$PG" sh -c '
  read -r PW
  PGPASSWORD="$PW" psql -X -tAq -h 127.0.0.1 -U '"$ROLE"' -d '"$DB"' \
    -c "select '"'"'PING '"'"' || current_user" 2>&1')
case "$OUT" in
  *"PING $ROLE"*)
    echo "  ✓ 붙었다 — 롤과 .env.nas 가 같은 값이고, TCP 로 인증이 통과합니다" ;;
  *"password authentication failed"*)
    echo "  ✗ 비밀번호가 틀렸습니다 — 방금 넣었는데 안 붙습니다. 알려 주세요."; exit 1 ;;
  *)
    echo "  ⚠️ 판정하지 못했습니다. psql 이 말한 것:"
    echo "$OUT" | sed 's/^/     /' | head -5
    echo "  🔴 .env.nas 사본이 옆에 있습니다." ; exit 1 ;;
esac

echo
echo "══ 4. 곁들여 — 비밀번호 없이는 못 붙는 것이 맞나 ══"
OUT2=$("$DOCKER" exec -i "$PG" sh -c '
  PGPASSWORD="" psql -X -tAq -h 127.0.0.1 -U '"$ROLE"' -d '"$DB"' -c "select 1" 2>&1')
case "$OUT2" in
  *"authentication failed"*|*"no password supplied"*)
    echo "  ✓ 빈 비밀번호로는 거절당한다 — 인증이 실제로 걸려 있습니다" ;;
  1*) echo "  ⚠️ 빈 비밀번호로도 붙습니다. TCP 인증이 trust 로 열려 있다는 뜻입니다."
      echo "     지금 설치에는 지장이 없지만 알아 두실 값어치가 있습니다." ;;
  *)  echo "  · 판정 안 함" ;;
esac

PW1=; PW2=
echo
echo "══ 끝났습니다 ══"
echo "  이 비밀번호를 다시 칠 일은 없습니다 — compose 가 .env.nas 에서 읽어"
echo "  DATABASE_URL 을 조립합니다. 다음은 4단계(파일 올리기)입니다."
