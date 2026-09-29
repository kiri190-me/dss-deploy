#!/bin/sh
# 휴가 DB 비밀번호를 한 번에 정한다 — 만들고 · 롤에 넣고 · .env.nas 에 적고 · 확인까지.
#   실행:  sh /volume1/dss/setup/13-leave-pw.sh      (sudo -i 상태에서)
#
# 🔴 스크립트가 **무작위로 만든다.** 사람이 정하지 않는다.
#    이 값은 사람이 쓸 일이 없다 — 앱이 DB 에 붙을 때만 쓴다. 그런데 이 값은
#    compose 가 조립하는 **URL 안에** 들어가므로 URL 규칙을 따라야 한다.
#    2026-09-29 에 사람이 정한 값에 `?` 가 들어가 URL 이 통째로 깨졌다
#    (`TypeError: Invalid URL` — `?` 는 URL 에서 쿼리 시작 표시다).
#    영문·숫자만 쓰면 그 갈래가 아예 없어진다.
#
# 같은 값이 두 곳에 들어간다:
#   ① NAS 의 DB 롤 dss_leave_app   ② /volume1/dss/deploy/.env.nas 의 LEAVE_APP_PASSWORD
# 어긋나면 앱이 뜨면서 password authentication failed 로 죽는다. 그래서 한자리에서 한다.
#
# 왜 손으로 하나: nas/init/app/01-roles.sh 가 A/S·계측기·개선요청의 롤을 만들 때
# 비밀번호까지 넣었지만, 그 스크립트는 **DB 상자가 처음 만들어질 때 한 번만** 돈다
# (2026-09-14). 그 뒤에 생긴 사이트는 손으로 넣는다 — 개선요청도 그랬다(런북 06 ㄷ).
#
# 🔴 값은 화면에 한 번도 안 찍는다. 파일에 root 600 으로만 남는다.
# 🔴 비밀번호는 **표준입력으로만** 흐른다. 명령줄에 적으면 ps 목록에 잠깐 보인다.
#
# ── 앞선 판에서 틀렸던 것 셋 (같은 실수를 막으려 적어 둔다) ──────────
#   ① psql -c "…" 안에서는 psql 변수(:'pw')가 **풀리지 않는다.** 서버가 `:` 를
#      그대로 받아 문법 오류를 낸다. → SQL 을 조립해 표준입력으로 넘긴다.
#   ② 확인을 `docker exec … psql` 로만 하면 **유닉스 소켓**으로 붙는다. 소켓은
#      보통 trust 라 비밀번호가 없어도 통과한다. → **-h 127.0.0.1** 로 확인한다.
#   ③ 따옴표·백슬래시만 막고 **URL 특수문자를 안 막았다.** `?` 하나로 깨졌다.
#      → 아예 사람에게 안 묻고 영문·숫자로 만든다.

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
echo "  롤 비밀번호: $([ "${HASPW:-}" = yes ] && echo '이미 있음 → 새것으로 덮어씁니다' || echo '없음')"
INENV=$(grep -cE '^[[:space:]]*(export[[:space:]]+)?LEAVE_APP_PASSWORD=' "$ENVF" 2>/dev/null || true)
echo "  .env.nas 의 LEAVE_APP_PASSWORD 줄: ${INENV:-0} 개"

echo
echo "══ 1. 새 비밀번호를 만듭니다 (영문·숫자 32글자) ══"
# openssl 이 있으면 그것으로, 없으면 /dev/urandom 으로. 둘 다 없으면 멈춘다.
# 🔴 영문·숫자만 남긴다 — URL·셸·SQL 어디에서도 특별한 뜻이 없는 글자들이다.
if command -v openssl >/dev/null 2>&1; then
  PW=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | cut -c1-32)
else
  PW=$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 32)
fi
[ ${#PW} -eq 32 ] || { echo "🔴 만들지 못했습니다(길이 ${#PW}). 알려 주세요."; exit 1; }
echo "  ✓ 만들었습니다 (32글자 · 영문과 숫자만 · 화면에 안 찍습니다)"

echo
echo "══ 2. 롤에 넣습니다 ══"
# SQL 을 조립해 **표준입력으로** 넘긴다 — 명령줄에 안 적는다(머리말 ①).
printf "ALTER ROLE %s PASSWORD '%s';\n" "$ROLE" "$PW" \
  | "$DOCKER" exec -i "$PG" sh -c 'psql -X -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres' \
  || { echo "🔴 롤에 넣지 못했습니다. .env.nas 는 그대로입니다."; exit 1; }
echo "  ✓ 넣었다"

echo
echo "══ 3. .env.nas 에 적습니다 ══"
cp -a "$ENVF" "$ENVF.bak-$(date +%Y%m%d-%H%M%S)" || exit 1
echo "  · 먼저 사본을 떴습니다"
# 있던 줄은 지우고 새로 붙인다 — 같은 이름이 둘이면 나중 것이 이겨 헷갈린다.
grep -vE '^[[:space:]]*(export[[:space:]]+)?LEAVE_APP_PASSWORD=' "$ENVF" > "$ENVF.new" || exit 1
printf 'LEAVE_APP_PASSWORD=%s\n' "$PW" >> "$ENVF.new" || exit 1
chown root:root "$ENVF.new" && chmod 600 "$ENVF.new" && mv "$ENVF.new" "$ENVF" || exit 1
echo "  ✓ 적었다 (root 600) · 줄 수 $(grep -cE '^LEAVE_APP_PASSWORD=' "$ENVF") 개 (1 이어야 합니다)"

echo
echo "══ 4. 🔴 URL 로 조립해도 멀쩡한가 ══"
# compose 가 만드는 것과 같은 꼴로 만들어 파싱해 본다. 2026-09-29 에 `?` 하나로
# drizzle-kit 이 TypeError: Invalid URL 을 냈다 — 그때는 이 검사가 없었다.
URLOK=$(printf '%s' "$PW" | "$DOCKER" exec -i "$PG" sh -c '
  read -r PW
  U="postgres://'"$ROLE"':$PW@dss-pg-app:5432/'"$DB"'"
  case "$U" in *[\?\#\[\]\ ]*) echo BAD ;; *) echo OK ;; esac')
case "$URLOK" in
  OK) echo "  ✓ URL 에서 뜻을 가지는 글자가 없다 (? # [ ] 공백)" ;;
  *)  echo "  ✗ URL 을 깨뜨릴 글자가 들어갔습니다 — 다시 돌려 주세요."; exit 1 ;;
esac

echo
echo "══ 5. 🔴 진짜 확인 — TCP 로 붙나 ══"
OUT=$(printf '%s' "$PW" | "$DOCKER" exec -i "$PG" sh -c '
  read -r PW
  PGPASSWORD="$PW" psql -X -tAq -h 127.0.0.1 -U '"$ROLE"' -d '"$DB"' \
    -c "select '"'"'PING '"'"' || current_user" 2>&1')
case "$OUT" in
  *"PING $ROLE"*) echo "  ✓ 붙었다" ;;
  *) echo "  ✗ 못 붙었습니다. psql 이 말한 것:"; echo "$OUT" | sed 's/^/     /' | head -4; exit 1 ;;
esac

PW=
echo
echo "══ 끝났습니다 ══"
echo "  이 값을 사람이 칠 일은 없습니다 — compose 가 .env.nas 에서 읽어 씁니다."
echo "  나중에 볼 일이 있으면:  grep LEAVE_APP /volume1/dss/deploy/.env.nas"
echo
echo "  다음:  bash /volume1/dss/setup/13-deploy.sh --init"
