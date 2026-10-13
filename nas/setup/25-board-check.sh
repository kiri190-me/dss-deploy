#!/bin/sh
# 설치 준비가 **실제로 됐는지** 본다. 🔴 거의 읽기만 한다 — 아무것도 안 바꾼다.
#   실행:  sh /volume1/dss/setup/25-board-check.sh
#
# 🔴 값은 한 글자도 화면에 찍지 않는다. 「있나 · 붙나」만 본다.
#   (딱 하나 바꾸는 것: 6번의 쓰기 시험이 첨부 폴더에 파일을 하나 만들었다
#    **바로 지운다.** 「있는가」가 아니라 「쓸 수 있는가」는 그렇게만 알 수 있다.)
#
# 왜 필요한가: 1·2단계(포털 등록 · DB · 비밀번호 · 폴더)는 사람이 여러 스크립트로
# 나눠 하는 일이라 중간에 막혔는지 알기 어렵다. 「했다」가 아니라 「되어 있다」를
# 본다 — 2026-09-29 에 「만든 것과 도는 것은 다르다」를 네 번 봤다.
#
# 여기가 전부 ✓ 면 3단계(설정 파일)로 가도 된다.

set -u
DOCKER=/usr/local/bin/docker
ACLT=/usr/syno/bin/synoacltool
PG=dss-pg-app
DB=dss_board
ROLE=dss_board_app
KEY=BOARD_APP_PASSWORD
CLIENT_ID=dss-board
BASE=https://board.dss21.co.kr
UP=/volume1/dss/board-uploads
ENVF=/volume1/dss/deploy/.env.nas
FAIL=0

echo "══ 1. .env.nas 에 $KEY 줄이 있나 (값은 안 본다) ══"
if [ ! -r "$ENVF" ]; then
  echo "  ✗ $ENVF 를 읽을 수 없다 — sudo -i 로 돌리고 있습니까?"
  FAIL=1
else
  # 🔴 「|| echo 0」을 붙이지 않는다. grep -c 는 0건일 때도 0 을 찍고 종료코드만
  #    1 이라, 붙이면 값이 "0" 두 줄이 되어 아래 case 가 0 과 안 맞는다.
  N=$(grep -c "^$KEY=" "$ENVF" 2>/dev/null)
  case "${N:-0}" in
    0) echo "  ✗ $KEY 줄이 없다 — 25-board-pw.sh 를 돌리세요"; FAIL=1 ;;
    1) # 값이 비었는지만 본다. 내용은 안 찍는다.
       EMPTY=$(awk -F= -v k="^$KEY=" '$0 ~ k {v=substr($0,index($0,"=")+1);
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
echo "══ 2. DB 와 롤이 있나 · 롤에 비밀번호가 붙어 있나 ══"
set -a; . "$ENVF" 2>/dev/null; set +a
HASDB=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "${APP_POSTGRES_USER:-postgres}" -d postgres \
  -c "select 1 from pg_database where datname='$DB'" 2>/dev/null)
[ "${HASDB:-}" = 1 ] && echo "  ✓ DB $DB 가 있다" \
  || { echo "  ✗ DB $DB 가 없다 — 25-board-db.sh 를 먼저 돌리세요"; FAIL=1; }
OWNER=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "${APP_POSTGRES_USER:-postgres}" -d postgres \
  -c "select pg_get_userbyid(datdba) from pg_database where datname='$DB'" 2>/dev/null)
[ "${OWNER:-}" = "$ROLE" ] && echo "  ✓ DB 의 주인이 $ROLE 이다 (표를 만들 수 있다)" \
  || { echo "  ✗ DB 의 주인이 ${OWNER:-?} 다 — $ROLE 이 표를 못 만든다"; FAIL=1; }
HASROLE=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "${APP_POSTGRES_USER:-postgres}" -d postgres \
  -c "select 1 from pg_roles where rolname='$ROLE'" 2>/dev/null)
if [ "${HASROLE:-}" != 1 ]; then
  echo "  ✗ 롤 $ROLE 이 없다 — 25-board-db.sh 를 먼저 돌리세요"
  FAIL=1
else
  # rolpassword 가 비어 있으면 NULL 이다. 값 자체는 보지 않는다.
  HASPW=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "${APP_POSTGRES_USER:-postgres}" -d postgres \
    -c "select case when rolpassword is null then 'no' else 'yes' end
        from pg_authid where rolname='$ROLE'" 2>/dev/null)
  case "${HASPW:-}" in
    yes) echo "  ✓ 롤에 비밀번호가 붙어 있다" ;;
    no)  echo "  ✗ 롤은 있는데 비밀번호가 없다 — 25-board-pw.sh 를 돌리세요"; FAIL=1 ;;
    *)   echo "  ⚠️ 판정하지 못했다 (pg_authid 를 못 읽었다)" ;;
  esac
fi

echo
echo "══ 3. 🔴 진짜 확인 — 그 비밀번호로 **TCP 로** 붙나 ══"
echo "  (.env.nas 의 값으로 $DB 에 붙어 본다. 읽기만 한다.)"
echo "  🔴 소켓으로 재면 trust 라 그냥 통과한다 — 앱이 쓰는 길(TCP)로 잰다."
if [ -r "$ENVF" ]; then
  # 🔴 비밀번호는 **표준입력으로만** 흐른다. 명령줄에 적으면 ps 에 잠깐 보인다.
  OUT=$(printf '%s\n' "${BOARD_APP_PASSWORD:-}" | "$DOCKER" exec -i \
        -e R="$ROLE" -e DBN="$DB" "$PG" sh -c '
    read -r PW
    PGPASSWORD="$PW" psql -X -tAq -h 127.0.0.1 -U "$R" -d "$DBN" \
      -c "select current_user" 2>&1')
  # 🔴 갈래 차례가 중요하다. 실패 문장이 「… for user "dss_board_app"」라서
  #    롤 이름을 **품고 있다** — 성공 갈래를 먼저 두면 실패가 ✓ 로 둔갑한다.
  case "$OUT" in
    *"authentication failed"*)
      echo "  ✗ 비밀번호가 다르다 — .env.nas 와 롤에 넣은 값이 어긋났다"
      echo "     25-board-pw.sh 를 다시 돌리면 둘을 한꺼번에 맞춥니다."
      FAIL=1 ;;
    *"no password supplied"*)
      echo "  ✗ 비밀번호가 안 넘어갔다 — .env.nas 의 값이 비어 있는 듯하다"
      FAIL=1 ;;
    *"could not connect"*|*"Connection refused"*)
      echo "  ✗ TCP 로 서버에 닿지 못했다 (127.0.0.1:5432)"
      echo "$OUT" | sed 's/^/       /' | head -4
      FAIL=1 ;;
    "$ROLE"|*"$ROLE"*)
      echo "  ✓ 붙었다 — .env.nas 의 값과 롤의 비밀번호가 같다" ;;
    *)
      echo "  ⚠️ 판정하지 못했다. psql 이 말한 것:"
      echo "$OUT" | sed 's/^/       /' | head -4
      FAIL=1 ;;
  esac
else
  echo "  · .env.nas 를 못 읽어 건너뛴다"
fi

echo
echo "══ 4. 포털 등록(1단계)도 됐나 ══"
ROW=$("$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth -X -tAq' <<SQL 2>/dev/null
select is_active || '|' || requires_grant || '|' || launcher_url
       || '|' || length(client_secret_hash)
       || '|' || length(launcher_icon)
       || '|' || upper(to_hex(ascii(launcher_icon)))
       || '|' || array_to_string(available_roles::text[], ',')
from clients where client_id = '$CLIENT_ID';
SQL
)
if [ -z "$ROW" ]; then
  echo "  ✗ clients 에 $CLIENT_ID 가 **없다** — 로그인이 아예 안 된다"
  echo "     sh /volume1/dss/setup/25-board-client.sh"
  FAIL=1
else
  IFS='|' read -r C_ACT C_GRANT C_URL C_HLEN C_ILEN C_ICODE C_ROLES <<EOF
$ROW
EOF
  [ "$C_ACT" = t ] && echo "  ✓ is_active 가 참이다" \
    || { echo "  ✗ is_active 가 참이 아니다 (${C_ACT:-?})"; FAIL=1; }
  [ "$C_GRANT" = f ] && echo "  ✓ requires_grant 가 거짓이다 — 전 직원이 바로 쓴다 (맞다)" \
    || { echo "  ✗ requires_grant 가 참이다 — 명단에 없는 사람이 다 막힌다"; FAIL=1; }
  [ "$C_URL" = "$BASE/" ] && echo "  ✓ launcher_url 이 $BASE/ 다" \
    || { echo "  ✗ launcher_url 이 $BASE/ 가 아니다 (${C_URL:-?})"; FAIL=1; }
  [ "$C_HLEN" = 64 ] && echo "  ✓ client_secret_hash 가 64글자다 (sha256 hex)" \
    || { echo "  ✗ client_secret_hash 가 64글자가 아니다 (${C_HLEN:-?}글자)"; FAIL=1; }
  # 🔴 아이콘은 글자가 아니라 **코드값**으로 본다. 터미널 글꼴이 없으면 네모로
  #    보여서 눈으로는 깨진 것과 멀쩡한 것을 가릴 수 없다.
  if [ "$C_ILEN" = 1 ] && [ "$C_ICODE" = 1FAA7 ]; then
    echo "  ✓ launcher_icon 이 U+1FAA7 한 글자다 (코드로 되읽었다)"
  else
    echo "  ✗ launcher_icon 이 U+1FAA7 이 아니다 (글자수 ${C_ILEN:-?} · 코드 ${C_ICODE:-?})"
    echo "     전송이나 터미널에서 깨진 것이다 — 25-board-client.sh 를 다시 돌리세요."
    FAIL=1
  fi
  case "$C_ROLES" in
    *MEMBER*) case "$C_ROLES" in
                *ADMIN*) echo "  ✓ available_roles 에 MEMBER · ADMIN 이 있다 ($C_ROLES)" ;;
                *) echo "  ✗ available_roles 에 ADMIN 이 없다 ($C_ROLES)"; FAIL=1 ;;
              esac ;;
    *) echo "  ✗ available_roles 에 MEMBER 가 없다 (${C_ROLES:-?})"; FAIL=1 ;;
  esac
fi

echo
echo "══ 5. 첨부 폴더가 있나 · 주인과 모드 ══"
if [ -d "$UP" ]; then
  # 🔴 판정은 **숫자**(%u:%g)로 한다. DSM 에 uid 1000 짜리 계정이 있으면 %U 가
  #    그 이름으로 보여 「1000 이 아니다」로 잘못 읽는다.
  UPMODE=$(stat -c '%u:%g %a' "$UP")
  echo "  ✓ $UP 가 있다 · $UPMODE (숫자) · $(stat -c '%U:%G' "$UP") (이름)"
  case "$UPMODE" in
    "1000:1000 750") echo "  ✓ 주인 uid 1000 · 모드 750" ;;
    *) echo "  ✗ 주인이나 모드가 다르다 ($UPMODE · 1000:1000 750 이어야 한다)"; FAIL=1 ;;
  esac
  ACLN=$("$ACLT" -get "$UP" 2>&1 | grep -cE ':(allow|deny):')
  [ "${ACLN:-1}" = 0 ] && echo "  ✓ ACL 항목 0개 (걷혔다)" \
    || { echo "  ✗ ACL 항목이 ${ACLN}개 남아 있다 — 컨테이너가 막힌다"; FAIL=1; }
else
  echo "  ✗ $UP 가 없다 — 25-board-place.sh 를 돌리세요"
  FAIL=1
fi

echo
echo "══ 6. 🔴 「있는가」가 아니라 「쓸 수 있는가」 ══"
echo "  임시 컨테이너를 uid 1000 으로 띄워 파일을 만들었다 지웁니다."
PROBE_IMG=""
for t in dss-board:0.1 dss-leave:0.2 dss-improvements:0.3 dss-as:2.5 dss-auth:1.6; do
  if "$DOCKER" image inspect "$t" >/dev/null 2>&1; then PROBE_IMG=$t; break; fi
done
if [ ! -d "$UP" ]; then
  echo "  · 폴더가 없어 건너뛴다"
elif [ -z "$PROBE_IMG" ]; then
  echo "  ⚠️ 시험에 쓸 이미지를 하나도 찾지 못했다 — **못 했다**(판정하지 않는다)"
else
  echo "  · 시험에 쓴 이미지: $PROBE_IMG"
  # 🔴 콜론과 리다이렉션으로 빈 파일을 만드는 방식을 쓰지 마라 — 쓰기가 막히면
  #    ash 가 셸을 그 자리에서 끝내, 뒤 줄이 아예 안 돌고 판정이 **빈 채로**
  #    지나간다(2026-10-12 실측). touch 는 외부 명령이라 실패해도 셸이 산다.
  OUT=$("$DOCKER" run --rm --network none -u 1000:1000 \
        -v "$UP:/data/uploads" --entrypoint sh "$PROBE_IMG" -c '
          if touch /data/uploads/.dss-write-test 2>/dev/null; then
            echo "PROBE WRITE_OK"
            rm -f /data/uploads/.dss-write-test 2>/dev/null
          else
            echo "PROBE WRITE_FAIL"
          fi' 2>&1)
  case "$OUT" in
    *"PROBE WRITE_OK"*)   echo "  ✓ uid 1000 이 실제로 썼다 (바로 지웠다)" ;;
    *"PROBE WRITE_FAIL"*) echo "  ✗ uid 1000 이 못 쓴다 — 사람이 사진을 붙일 때 깨진다"; FAIL=1 ;;
    *) echo "  ✗ 판정하지 못했다 — 아래가 그대로의 출력이다"
       printf '%s\n' "$OUT" | sed 's/^/     /' | head -6; FAIL=1 ;;
  esac
fi

echo
if [ "$FAIL" = 0 ]; then
  echo "══ 전부 통과 · 3단계(설정 파일)로 가도 됩니다 ══"
  exit 0
else
  echo "══ 🔴 위 ✗ 를 먼저 해결하세요 ══"
  echo "   되돌아갈 자리:"
  echo "     포털 등록   sh /volume1/dss/setup/25-board-client.sh"
  echo "     DB · 롤     sh /volume1/dss/setup/25-board-db.sh"
  echo "     비밀번호    sh /volume1/dss/setup/25-board-pw.sh"
  echo "     폴더 · 파일 sh /volume1/dss/setup/25-board-place.sh"
  exit 1
fi
