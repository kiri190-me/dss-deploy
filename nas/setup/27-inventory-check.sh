#!/bin/sh
# 설치 준비가 **실제로 됐는지** 본다. 🔴 거의 읽기만 한다 — 아무것도 안 바꾼다.
#   실행:  sh /volume1/dss/setup/27-inventory-check.sh
#
# 🔴 값은 한 글자도 화면에 찍지 않는다. 「있나 · 붙나 · 쓰나」만 본다.
#   (딱 하나 바꾸는 것: 6번의 쓰기 시험이 데이터 폴더에 파일과 폴더를 하나씩
#    만들었다 **바로 지운다.** 「있는가」가 아니라 「쓸 수 있는가」는 그렇게만
#    알 수 있다.)
#
# 왜 필요한가: 앞 단계(DB · 비밀번호 · 포털 등록 · 파일 · 폴더)는 사람이 여러
# 스크립트로 나눠 하는 일이라 중간에 막혔는지 알기 어렵다. 「했다」가 아니라
# 「되어 있다」를 본다 — 2026-09-29 에 「만든 것과 도는 것은 다르다」를 네 번 봤다.
#
# 🔴 이 설치에만 있는 것 셋 (게시판 점검에 없던 것):
#   · 데이터 폴더의 주인이 uid **1001** 이다 (앞의 일곱은 1000)
#   · 앱이 **1분마다** 그 폴더에 쓴다 — 못 쓰면 화면은 멀쩡한데 엑셀만 멈춘다
#   · 야간 백업에 **DB 와 데이터 폴더 둘 다** 들어가야 한다. 전환 절차서가
#     「없으면 실자료를 넣지 않는다」를 전제 1번으로 못 박았다
#
# 여기가 전부 ✓ 면 배포(27-deploy.sh)로 가도 된다.

set -u
DOCKER=/usr/local/bin/docker
ACLT=/usr/syno/bin/synoacltool
PG=dss-pg-app
DB=dss_inventory
ROLE=dss_inventory_app
KEY=INVENTORY_APP_PASSWORD
CLIENT_ID=dss-inventory
BASE=https://inventory.dss21.co.kr
CB_PATH=/api/auth/sso/callback
BC_PATH=/api/auth/sso/backchannel-logout
DATA=/volume1/dss/inventory-data
UID_APP=1001
GID_APP=1001
ENVF=/volume1/dss/deploy/.env.nas
BKD=/volume1/dss/backups
JOBS=/volume1/dss/jobs
TODAY=$(date +%F)
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
    0) echo "  ✗ $KEY 줄이 없다 — 27-inventory-pw.sh 를 돌리세요"; FAIL=1 ;;
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
  || { echo "  ✗ DB $DB 가 없다 — 27-inventory-db.sh 를 먼저 돌리세요"; FAIL=1; }
OWNER=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "${APP_POSTGRES_USER:-postgres}" -d postgres \
  -c "select pg_get_userbyid(datdba) from pg_database where datname='$DB'" 2>/dev/null)
[ "${OWNER:-}" = "$ROLE" ] && echo "  ✓ DB 의 주인이 $ROLE 이다 (표를 만들 수 있다)" \
  || { echo "  ✗ DB 의 주인이 ${OWNER:-?} 다 — $ROLE 이 표를 못 만든다"; FAIL=1; }
HASROLE=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "${APP_POSTGRES_USER:-postgres}" -d postgres \
  -c "select 1 from pg_roles where rolname='$ROLE'" 2>/dev/null)
if [ "${HASROLE:-}" != 1 ]; then
  echo "  ✗ 롤 $ROLE 이 없다 — 27-inventory-db.sh 를 먼저 돌리세요"
  FAIL=1
else
  # rolpassword 가 비어 있으면 NULL 이다. 값 자체는 보지 않는다.
  HASPW=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "${APP_POSTGRES_USER:-postgres}" -d postgres \
    -c "select case when rolpassword is null then 'no' else 'yes' end
        from pg_authid where rolname='$ROLE'" 2>/dev/null)
  case "${HASPW:-}" in
    yes) echo "  ✓ 롤에 비밀번호가 붙어 있다" ;;
    no)  echo "  ✗ 롤은 있는데 비밀번호가 없다 — 27-inventory-pw.sh 를 돌리세요"; FAIL=1 ;;
    *)   echo "  ⚠️ 판정하지 못했다 (pg_authid 를 못 읽었다)" ;;
  esac
fi
# 🔴 표가 아직 없는 것이 **정상**이다. 마이그레이션은 27-deploy.sh --init 이,
#    실자료는 전환일 절차가 따로 한다. 여기서는 몇 개인지만 알린다.
NTBL=$("$DOCKER" exec -i "$PG" psql -X -tAq -U "${APP_POSTGRES_USER:-postgres}" -d "$DB" \
  -c "select count(*) from information_schema.tables where table_schema='public'" 2>/dev/null)
echo "  · public 스키마의 표: ${NTBL:-?}개 (배포 전에는 0 이 정상 · --init 뒤 13)"

echo
echo "══ 3. 🔴 진짜 확인 — 그 비밀번호로 **TCP 로** 붙나 ══"
echo "  (.env.nas 의 값으로 $DB 에 붙어 본다. 읽기만 한다.)"
echo "  🔴 소켓으로 재면 trust 라 그냥 통과한다 — 앱이 쓰는 길(TCP)로 잰다."
if [ -r "$ENVF" ]; then
  # 🔴 비밀번호는 **표준입력으로만** 흐른다. 명령줄에 적으면 ps 에 잠깐 보인다.
  OUT=$(printf '%s\n' "${INVENTORY_APP_PASSWORD:-}" | "$DOCKER" exec -i \
        -e R="$ROLE" -e DBN="$DB" "$PG" sh -c '
    read -r PW
    PGPASSWORD="$PW" psql -X -tAq -h 127.0.0.1 -U "$R" -d "$DBN" \
      -c "select current_user" 2>&1')
  # 🔴 갈래 차례가 중요하다. 실패 문장이 「… for user "dss_inventory_app"」라서
  #    롤 이름을 **품고 있다** — 성공 갈래를 먼저 두면 실패가 ✓ 로 둔갑한다.
  case "$OUT" in
    *"authentication failed"*)
      echo "  ✗ 비밀번호가 다르다 — .env.nas 와 롤에 넣은 값이 어긋났다"
      echo "     27-inventory-pw.sh 를 다시 돌리면 둘을 한꺼번에 맞춥니다."
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
echo "══ 4. 포털 등록도 됐나 ══"
# 🔴 boolean 을 || 로 이으면 PostgreSQL 이 'true'/'false' 로 바꾼다. psql 이
#    칸으로 찍을 때의 't'/'f' 와 다르다 — 2026-10-13 게시판 첫 설치에서 멀쩡한
#    등록이 ✗ 둘로 보였다. case when 으로 't'/'f' 를 **직접 만들어** 셸 판정과 맞춘다.
ROW=$("$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth -X -tAq' <<SQL 2>/dev/null
select case when is_active      then 't' else 'f' end
       || '|' || case when requires_grant then 't' else 'f' end
       || '|' || launcher_url
       || '|' || length(client_secret_hash)
       || '|' || length(launcher_icon)
       || '|' || upper(to_hex(ascii(launcher_icon)))
       || '|' || array_to_string(available_roles::text[], ',')
       || '|' || case when '$BASE$CB_PATH' = any(redirect_uris) then 'y' else 'n' end
       || '|' || case when backchannel_logout_uri = '$BASE$BC_PATH' then 'y' else 'n' end
from clients where client_id = '$CLIENT_ID';
SQL
)
if [ -z "$ROW" ]; then
  echo "  ✗ clients 에 $CLIENT_ID 가 **없다** — 로그인이 아예 안 된다"
  echo "     sh /volume1/dss/setup/27-inventory-client.sh"
  FAIL=1
else
  IFS='|' read -r C_ACT C_GRANT C_URL C_HLEN C_ILEN C_ICODE C_ROLES C_CB C_BC <<EOF
$ROW
EOF
  [ "$C_ACT" = t ] && echo "  ✓ is_active 가 참이다" \
    || { echo "  ✗ is_active 가 참이 아니다 (${C_ACT:-?})"; FAIL=1; }
  # 🔴 게시판 · 휴가 · 개선요청과 **반대**다. 재고 관리는 기본 역할이 없어
  #    명단에 없는 사람은 앱이 거절한다 — 그럴 바에 포털에서 막는 것이 낫다.
  if [ "$C_GRANT" = t ]; then
    echo "  ✓ requires_grant 가 참이다 — 명단에 있는 사람만 (맞다 · PO 와 같다)"
  else
    echo "  ✗ requires_grant 가 거짓이다 (${C_GRANT:-?})"
    echo "     🔴 전 직원이 포털은 통과하고 **앱에서 거절당한다**(no_role)."
    echo "     재고 관리에는 기본 역할이 없습니다 — 27-inventory-client.sh 를 다시."
    FAIL=1
  fi
  [ "$C_URL" = "$BASE/" ] && echo "  ✓ launcher_url 이 $BASE/ 다" \
    || { echo "  ✗ launcher_url 이 $BASE/ 가 아니다 (${C_URL:-?})"; FAIL=1; }
  [ "$C_HLEN" = 64 ] && echo "  ✓ client_secret_hash 가 64글자다 (sha256 hex)" \
    || { echo "  ✗ client_secret_hash 가 64글자가 아니다 (${C_HLEN:-?}글자)"; FAIL=1; }
  # 🔴 주소가 게시판과 다르다 — /api/auth/sso/callback 이다(sso 가 한 칸 더 있다).
  [ "$C_CB" = y ] && echo "  ✓ redirect_uris 에 $BASE$CB_PATH 가 있다" \
    || { echo "  ✗ redirect_uris 에 $BASE$CB_PATH 가 없다 — 로그인 끝에서 거절된다"; FAIL=1; }
  [ "$C_BC" = y ] && echo "  ✓ backchannel_logout_uri 가 $BASE$BC_PATH 다" \
    || { echo "  ✗ backchannel_logout_uri 가 다르다 — 포털에서 로그아웃해도 안 끊긴다"; FAIL=1; }
  # 🔴 아이콘은 글자가 아니라 **코드값**으로 본다. 터미널 글꼴이 없으면 네모로
  #    보여서 눈으로는 깨진 것과 멀쩡한 것을 가릴 수 없다.
  if [ "$C_ILEN" = 1 ] && [ "$C_ICODE" = 1F4E6 ]; then
    echo "  ✓ launcher_icon 이 U+1F4E6 한 글자다 (코드로 되읽었다)"
  else
    echo "  ✗ launcher_icon 이 U+1F4E6 이 아니다 (글자수 ${C_ILEN:-?} · 코드 ${C_ICODE:-?})"
    echo "     전송이나 터미널에서 깨진 것이다 — 27-inventory-client.sh 를 다시 돌리세요."
    FAIL=1
  fi
  # 🔴 역할 셋이 **글자 그대로** 같아야 한다. 모르는 값이 오면 앱이 로그인을 거절한다
  #    (dss-inventory/src/lib/auth/role.ts — REJECT).
  MISS=""
  for r in VIEWER STAFF ADMIN; do
    case "$C_ROLES" in *"$r"*) : ;; *) MISS="$MISS $r" ;; esac
  done
  [ -z "$MISS" ] && echo "  ✓ available_roles 에 VIEWER · STAFF · ADMIN 이 있다 ($C_ROLES)" \
    || { echo "  ✗ available_roles 에 없는 것:$MISS  (지금 값: ${C_ROLES:-?})"; FAIL=1; }
fi

echo
echo "══ 5. 🔴 명단 — 들어올 수 있는 사람이 하나라도 있나 ══"
echo "  requires_grant 가 참이라 **명단에 있는 사람만** 들어옵니다."
echo "  🔴 user_client_grants.client_id 는 글자가 아니라 clients.id(uuid)다 —"
echo "     글자로 비교하면 조용히 0건이 나온다. clients 와 이어서 센다."
GRANTS=$("$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth -X -tAq' <<SQL 2>/dev/null
select count(*) filter (where g.role is not null)
       || '|' || count(*) filter (where g.role is null)
from user_client_grants g
join clients c on c.id = g.client_id
where c.client_id = '$CLIENT_ID';
SQL
)
[ -n "${GRANTS:-}" ] || GRANTS="0|0"
IFS='|' read -r G_OK G_NULL <<EOF
$GRANTS
EOF
if [ "${G_OK:-0}" -ge 1 ]; then
  echo "  ✓ 역할을 받은 사람 ${G_OK}명 — 적어도 한 사람은 들어올 수 있다"
else
  echo "  ✗ 역할을 받은 사람이 **하나도 없다** — 아무도 못 들어간다"
  echo "     🔴 재고 관리에는 비상구(make:admin 류)가 **없습니다.** 포털이 유일한"
  echo "        길입니다. 포털 관리 화면에서 **정영빈 님을 ADMIN** 으로 먼저 넣으세요."
  FAIL=1
fi
if [ "${G_NULL:-0}" -ge 1 ]; then
  echo "  ⚠️ 역할이 비어 있는 줄이 ${G_NULL}개 있다 — 그 사람들은 거절된다"
  echo "     포털이 role 클레임을 아예 안 싣고, 앱은 처음 로그인을 no_role 로 막는다."
fi

echo
echo "══ 6. 데이터 폴더가 있나 · 주인과 모드 (🔴 uid $UID_APP) ══"
if [ -d "$DATA" ]; then
  # 🔴 판정은 **숫자**(%u:%g)로 한다. DSM 에 그 번호짜리 계정이 있으면 %U 가
  #    그 이름으로 보여 「$UID_APP 이 아니다」로 잘못 읽는다.
  DMODE=$(stat -c '%u:%g %a' "$DATA")
  echo "  ✓ $DATA 가 있다 · $DMODE (숫자) · $(stat -c '%U:%G' "$DATA") (이름)"
  case "$DMODE" in
    "$UID_APP:$GID_APP 750") echo "  ✓ 주인 uid $UID_APP · 모드 750" ;;
    *) echo "  ✗ 주인이나 모드가 다르다 ($DMODE · $UID_APP:$GID_APP 750 이어야 한다)"; FAIL=1 ;;
  esac
  OTHERS=$(find "$DATA" ! -uid "$UID_APP" 2>/dev/null | wc -l)
  if [ "${OTHERS:-1}" = 0 ]; then
    echo "  ✓ 폴더 아래 전부가 uid $UID_APP 것이다"
  else
    echo "  ✗ 주인이 다른 것이 ${OTHERS}개 있다 — 그 파일에서만 조용히 막힌다"
    echo "     🔴 도구 컨테이너는 root 로 돈다. /data 에 쓰는 전환일 명령을 돌렸다면"
    echo "        그 뒤에  chown -R $UID_APP:$GID_APP $DATA  를 해야 한다."
    find "$DATA" ! -uid "$UID_APP" 2>/dev/null | head -5 | sed 's/^/       /'
    FAIL=1
  fi
  ACLN=$("$ACLT" -get "$DATA" 2>&1 | grep -cE ':(allow|deny):')
  [ "${ACLN:-1}" = 0 ] && echo "  ✓ ACL 항목 0개 (걷혔다)" \
    || { echo "  ✗ ACL 항목이 ${ACLN}개 남아 있다 — 주인이 맞아도 컨테이너가 막힌다"; FAIL=1; }
  for sub in templates import workbook; do
    [ -d "$DATA/$sub" ] && echo "  ✓ $sub/ 가 있다" \
      || { echo "  ✗ $sub/ 가 없다 — 27-inventory-place.sh 를 돌리세요"; FAIL=1; }
  done
  # 🔵 양식 두 벌은 **전환일에 사람이 넣는다.** 설치하는 날 없는 것이 정상이다.
  #    🔴 그래도 「언제 넣어야 하는지」를 여기서 알린다 — 프로그램이 다시 만들 수
  #       없는 **입력물**이고, 없으면 현황판 엑셀이 아예 안 만들어진다.
  NTPL=$(find "$DATA/templates" -maxdepth 1 -name '*.xlsx' 2>/dev/null | wc -l)
  if [ "${NTPL:-0}" -ge 2 ]; then
    echo "  ✓ templates/ 에 xlsx 가 ${NTPL}개 있다"
    find "$DATA/templates" -maxdepth 1 -name '*.xlsx' 2>/dev/null | sed 's/^/       /'
  else
    echo "  ⚠️ templates/ 에 xlsx 가 ${NTPL:-0}개다 — 설치하는 날에는 **정상**이다"
    echo "     🔴 전환일 전에 양식 **두 벌**을 넣어야 한다(사람이 넣는다):"
    echo "        재고 및 견적 현황판 틀_과거줄포함.xlsx   ← 현황판을 만드는 양식"
    echo "        재고 현황 내려받기 틀.xlsx"
    echo "     이름이 compose 의 STOCK_*_PATH 와 **글자 하나까지** 같아야 한다."
  fi
else
  echo "  ✗ $DATA 가 없다 — 27-inventory-place.sh 를 돌리세요"
  FAIL=1
fi

echo
echo "══ 7. 🔴 「있는가」가 아니라 「쓸 수 있는가」 ══"
echo "  임시 컨테이너를 uid $UID_APP 으로 띄워 파일과 폴더를 만들었다 지웁니다."
echo "  🔴 앱은 **1분마다** 여기에 씁니다 — 못 쓰면 화면은 멀쩡한데 엑셀만 멈춥니다."
PROBE_IMG=""
for t in dss-inventory:0.1 dss-board:0.1 dss-leave:0.2 dss-improvements:0.3 dss-as:2.5 dss-auth:1.6; do
  if "$DOCKER" image inspect "$t" >/dev/null 2>&1; then PROBE_IMG=$t; break; fi
done
if [ ! -d "$DATA" ]; then
  echo "  · 폴더가 없어 건너뛴다"
elif [ -z "$PROBE_IMG" ]; then
  echo "  ⚠️ 시험에 쓸 이미지를 하나도 찾지 못했다 — **못 했다**(판정하지 않는다)"
else
  echo "  · 시험에 쓴 이미지: $PROBE_IMG"
  # 🔴 콜론과 리다이렉션으로 빈 파일을 만드는 방식을 쓰지 마라 — 쓰기가 막히면
  #    ash 가 셸을 그 자리에서 끝내, 뒤 줄이 아예 안 돌고 판정이 **빈 채로**
  #    지나간다(2026-10-12 실측). touch 와 mkdir 은 외부 명령이라 실패해도 셸이 산다.
  OUT=$("$DOCKER" run --rm --network none -u "$UID_APP:$GID_APP" \
        -v "$DATA:/data" --entrypoint sh "$PROBE_IMG" -c '
          if touch /data/.dss-write-test 2>/dev/null; then
            echo "PROBE WRITE_OK"
            rm -f /data/.dss-write-test 2>/dev/null
          else
            echo "PROBE WRITE_FAIL"
          fi
          if mkdir -p /data/.dss-mkdir-test 2>/dev/null; then
            echo "PROBE MKDIR_OK"
            rmdir /data/.dss-mkdir-test 2>/dev/null
          else
            echo "PROBE MKDIR_FAIL"
          fi' 2>&1)
  case "$OUT" in
    *"PROBE WRITE_OK"*)   echo "  ✓ uid $UID_APP 이 실제로 썼다 (바로 지웠다)" ;;
    *"PROBE WRITE_FAIL"*) echo "  ✗ uid $UID_APP 이 못 쓴다 — 앱이 첫 1분부터 조용히 멈춘다"; FAIL=1 ;;
    *) echo "  ✗ 판정하지 못했다 — 아래가 그대로의 출력이다"
       printf '%s\n' "$OUT" | sed 's/^/     /' | head -6; FAIL=1 ;;
  esac
  case "$OUT" in
    *"PROBE MKDIR_OK"*)   echo "  ✓ 폴더도 만들 수 있다 (baseline · backup · OLD 가 이렇게 생긴다)" ;;
    *"PROBE MKDIR_FAIL"*) echo "  ✗ 폴더를 못 만든다 — 백업 폴더가 영영 안 생긴다"; FAIL=1 ;;
  esac
  LEFT=$(find "$DATA" -maxdepth 1 -name '.dss-*-test' 2>/dev/null | wc -l)
  [ "${LEFT:-0}" = 0 ] && echo "  ✓ 시험 흔적이 남지 않았다" \
    || { echo "  ✗ 시험 흔적이 남아 있다 — 손으로 지우세요"
         find "$DATA" -maxdepth 1 -name '.dss-*-test' 2>/dev/null | sed 's/^/       /'; }
fi

echo
echo "══ 8. 🔴 야간 백업에 들어 있나 (DB 와 데이터 폴더 **둘 다**) ══"
echo "  전환 절차서 전제 1번: 「없으면 실자료를 넣지 않는다」."
echo "  개선요청은 이 한 줄이 빠져 11일간 아무 오류 없이 백업되지 않았다."
if [ -r "$JOBS/backup-nightly.sh" ]; then
  N=$(grep -c 'dss_inventory' "$JOBS/backup-nightly.sh")
  [ "${N:-0}" -ge 1 ] && echo "  ✓ backup-nightly.sh 에 dss_inventory 줄이 ${N}개 있다" \
    || { echo "  ✗ 🔴 backup-nightly.sh 에 dss_inventory 가 없다 — DB 가 백업되지 않는다"; FAIL=1; }
  N=$(grep -c 'inventory-data' "$JOBS/backup-nightly.sh")
  [ "${N:-0}" -ge 1 ] && echo "  ✓ backup-nightly.sh 에 inventory-data 줄이 ${N}개 있다" \
    || { echo "  ✗ 🔴 backup-nightly.sh 에 inventory-data 가 없다 — **양식 두 벌이 백업되지 않는다**"
         echo "       그것은 프로그램이 다시 만들 수 없는 입력물이다. 잃으면 현황판을 못 만든다."
         FAIL=1; }
  # 🔴 현황판 공유폴더는 위 inventory-data 의 **밖**이라 따로 세야 한다
  #    (2026-10-14 에 compose 가 /data/workbook 을 사내 공유폴더로 덧씌웠다).
  #    그쪽이 받는 것은 프로그램이 다시 못 만드는 둘이다 —
  #    현황판_사람수정_*.xlsx (사람이 적은 것) 와 OLD/ (월별 영구 백업).
  N=$(grep -c 'inventory-workbook' "$JOBS/backup-nightly.sh")
  [ "${N:-0}" -ge 1 ] && echo "  ✓ backup-nightly.sh 에 inventory-workbook 줄이 ${N}개 있다" \
    || { echo "  ✗ 🔴 backup-nightly.sh 에 inventory-workbook 이 없다 — **현황판 공유폴더가 백업되지 않는다**"
         echo "       수기입을 치워 둔 파일과 OLD/ 는 프로그램이 다시 만들지 못한다."
         FAIL=1; }
else
  echo "  ✗ $JOBS/backup-nightly.sh 를 읽을 수 없다 (sudo -i 로 돌리고 있습니까)"
  FAIL=1
fi
# 🔴 「고쳤다」가 아니라 「돌았다」를 본다. 오늘 덤프가 실제로 있는가.
F=$(ls -1t "$BKD/db/${DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
if [ -n "$F" ] && [ -s "$F" ]; then
  echo "  ✓ 오늘($TODAY) 뜬 $DB 덤프가 있다 — $(basename "$F") ($(du -h "$F" | cut -f1))"
else
  echo "  ✗ 오늘($TODAY) 뜬 $DB 덤프가 없다 — 고친 백업을 **한 번도 안 돌린 것**이다"
  echo "     bash /volume1/dss/jobs/backup-nightly.sh"
  echo "     ✓ dss_inventory 줄과 ✓ inventory-data 줄이 찍혀야 합니다."
  echo "     🔴 현황판 공유폴더 줄(inventory-workbook)도 **함께** 찍힙니다 — 다만"
  echo "     첫 설치 전에는 ✓ 가 아니라 「공유폴더가 아직 없다」로 찍히는 것이 정상입니다."
  FAIL=1
fi
if [ -d "$BKD/files/inventory-data" ]; then
  echo "  ✓ 백업에 files/inventory-data 가 있다 ($(find "$BKD/files/inventory-data" -type f | wc -l)개)"
else
  echo "  ⚠️ 백업에 files/inventory-data 가 아직 없다 — 데이터 폴더가 비어 있으면"
  echo "     rsync 가 빈 폴더만 만든다. 야간 백업을 한 번 돌리면 생긴다."
fi
if [ -d "$BKD/files/inventory-workbook" ]; then
  echo "  ✓ 백업에 files/inventory-workbook 이 있다 ($(find "$BKD/files/inventory-workbook" -type f | wc -l)개)"
else
  echo "  ⚠️ 백업에 files/inventory-workbook 이 아직 없다 — 첫 설치 전이면 공유폴더"
  echo "     자체가 없어 **정상이다**(흠으로 세지 않는다). 공유폴더가 선 뒤 야간"
  echo "     백업을 한 번 돌리면 생긴다."
fi

echo
echo "══ 9. 바깥 주소 $BASE (앱 전에는 502 가 정상) ══"
# 🔴 502 는 흠이 아니다. 「프록시와 인증서는 제대로 걸렸는데 갈 곳(앱)이 아직
#    없다」는 뜻이다 — 첫 설치 전에는 그것이 **정상**이다.
CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$BASE/" 2>/dev/null)
case "$CODE" in
  502)
    echo "  ✓ → 502 · **앱이 뜨기 전이면 이것이 정상이다**"
    echo "     뜻: DNS 도 DSM 리버스 프록시도 인증서도 제대로 걸렸다. 다만"
    echo "     localhost:13800 에 아직 아무도 없다. 배포 뒤에는 307 이 된다." ;;
  2??|3??)
    echo "  ✓ → $CODE · 앱이 이미 대답하고 있다 (배포를 이미 한 뒤다)" ;;
  000|"")
    echo "  ✗ → 대답이 없다 — DNS(Cloudflare A 레코드 inventory)나 DSM 리버스"
    echo "     프록시가 아직 없다. 사람이 먼저 넣어야 한다."
    FAIL=1 ;;
  404|503)
    echo "  ✗ → $CODE — 프록시 규칙이 다른 곳을 가리킨다(대상이 localhost:13800 인가)"
    FAIL=1 ;;
  *)
    echo "  ✗ → $CODE — 뜻을 모르겠다. 프록시 규칙과 인증서를 보세요"
    FAIL=1 ;;
esac

echo
if [ "$FAIL" = 0 ]; then
  echo "══ 전부 통과 · 배포(27-deploy.sh)로 가도 됩니다 ══"
  echo "   bash /volume1/dss/setup/27-deploy.sh        ← 읽기만 합니다"
  exit 0
else
  echo "══ 🔴 위 ✗ 를 먼저 해결하세요 ══"
  echo "   되돌아갈 자리:"
  echo "     DB · 롤       sh /volume1/dss/setup/27-inventory-db.sh"
  echo "     비밀번호      sh /volume1/dss/setup/27-inventory-pw.sh"
  echo "     포털 등록     sh /volume1/dss/setup/27-inventory-client.sh"
  echo "     파일 · 폴더   sh /volume1/dss/setup/27-inventory-place.sh"
  echo "     야간 백업     bash /volume1/dss/jobs/backup-nightly.sh"
  exit 1
fi
