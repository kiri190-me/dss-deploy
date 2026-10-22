#!/bin/sh
# /volume1/dss/setup/32-rf-trouble-check.sh
#   서른두째 — 아홉째 사이트 **RF 이슈관리**(dss-trouble) 를 세우기 **전** 상태를
#   재기만 한다. 🔴 **아무것도 고치지 않는다.**
#
#   실행:  sudo -i  뒤에   sh /volume1/dss/setup/32-rf-trouble-check.sh
#
# ══ 🔴 먼저 알아야 하는 것 — 이 집은 앞의 여덟과 다르다 ════════════════
#
#   ① **DB 가 없다.** 자료가 data/ 폴더의 **파일**이다(이슈 · 색인 · 첨부 ·
#      세션 서명 열쇠 .session-secret). 마이그레이션 · DB 초기화 절차가
#      **통째로 없다.** 대신 **백업 대상이 폴더**다.
#   ② **Next.js 가 아니다.** server.js 한 장 + 정적 HTML 이고 의존성이 0 이라
#      package.json 자체가 없다. 그래서 도구 이미지(tools-*)도 없다 —
#      부를 npm script 가 없기 때문이다. 빠뜨린 것이 아니다.
#   ③ 🔴 **팀 비밀번호 로그인이 이미 걷혔다**(그 저장소 2026-10-21 커밋
#      9a52287). 들어오는 길은 통합 로그인 하나뿐이다 —
#      🔴 **포털이 멈추면 아무도 못 들어온다.** 되돌릴 비상구가 없다.
#   ④ 🔴 콜백 경로가 다른 여덟과 **다르다**. 다른 집은
#      /api/**auth**/sso/callback 인데 이 집은 **/api/sso/callback** 이다
#      (auth 한 겹이 없다). 27-inventory-client.sh 를 베껴 쓰면 그대로 틀린다.
#   ⑤ 🔴 클라이언트 열쇠는 **dss-rf-trouble** 이다 — 저장소 이름
#      (dss-trouble)과 다르다. 포털 src/lib/notifications/sources.ts 에 그
#      글자로 박혀 있다(2026-10-22 읽어서 확인).
#
# ══ 🔴 2026-10-22 쓰는 분이 정한 것 둘 — 다시 묻지 않는다 ════════════
#   ① **공유폴더 둘은 이번에 안 붙인다.** 파일 위치는 배포판 이후에
#      시스템에서 고르기로 했다. 없어도 앱은 뜬다(코드로 확인했다) —
#      비는 것은 「자료 파일 열기·내려받기」와 「엑셀 자동 재색인」 둘뿐이다.
#      자세한 것은 5절의 「적어 두는 줄」에 있다.
#   ② **컨테이너는 1026:100 으로 돈다.** [실측] id 1026 →
#      uid=1026(swhur) gid=100(users). 다른 집들의 1001 과 다르다.
#
# ══ 🔴 이 파일을 NAS 로 옮기는 법 ═════════════════════════════════════
#   DSM 터미널은 **긴 명령을 잘라 먹는다**(2026-10-13 에 하루 네 번 깨졌다).
#   그래서 손으로 치지 말고 **파일로 올리고 md5 를 맞춘다.**
#     (개발 PC · PowerShell)  scp -O 32-rf-trouble-check.sh dss-nas:/volume1/dss/setup/
#     (개발 PC · PowerShell)  Get-FileHash -Algorithm MD5 .\32-rf-trouble-check.sh
#     (NAS)                   md5sum /volume1/dss/setup/32-rf-trouble-check.sh
#   🔴 scp 에 -O 를 붙인다. 없으면 sftp 가 없어 실패한다.
#
# ══ 🔴 ✓ / ✗ / ? 로 센다 ═════════════════════════════════════════════
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. ✗ 든 ? 든 하나라도 있으면 종료 코드 1 이다.
#   🔴 「아직 안 만든 것」은 ✗ 가 아니다 — 세우기 **전**이 정상 상태이므로
#      ✓ 로 센다. 그 줄에는 「아직 없다(기대한 상태)」라고 적는다.
#   🔴 기대값을 박을 때는 출처를 주석에 적는다 — [설문] 31-survey.sh 실측 ·
#      [저장소] dss-trouble/dss-auth 코드 · [결정] 2026-10-22 쓰는 분 결정.
#      🔴 추측이면 박지 않는다.
#
# ══ 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ═══════════════════════
#   ① 큰따옴표 안의 백틱은 명령 치환으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 주석에도 안 썼다.
#   ② 읽기 전용 자리에 리다이렉션으로 빈 파일을 만들면(콜론 하나 뒤에 꺾쇠)
#      NAS 의 ash 가 셸을 그 자리에서 끝낸다(2026-10-12 실제 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch 로 만든다.
#
# ══ 🔴 비밀값을 찍지 않는다 ═══════════════════════════════════════════
#   .env 는 **이름이 있는가/없는가**만 본다. 값도, 값의 길이도 찍지 않는다.
#   공개 주소(SSO_ISSUER · SSO_REDIRECT_URI)만 글자 대조로 보여 준다.

set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
CF=$D/deploy/docker-compose.nas.yml
ENVD=$D/deploy/env
ENV_NAS=$D/deploy/.env.nas
IMAGES=$D/images
IN=$D/setup/incoming
BKDB=$D/backups/db
JOB=$D/jobs/backup-nightly.sh

# ══ 이번에 세우는 것 — 한자리에 모아 둔다 ═════════════════════════════
TAG=dss-rf-trouble:0.1          # [결정] 다른 여덟과 같은 이름 규칙(dss-<이름>:<판>)
TARF=dss-rf-trouble-0.1.tar
SVC=app-rf-trouble
CNAME=dss-rf-trouble
HPORT=13900                     # [설문] 31-survey.sh 8절이 비어 있음을 확인했다
CPORT=7331                      # [저장소] dss-trouble/Dockerfile 의 ENV PORT
BASE=https://issues.dss21.co.kr # [결정] 2026-10-22
CLIENT_ID=dss-rf-trouble        # [저장소] dss-auth sources.ts 에 박힌 글자
ISSUER=https://login.dss21.co.kr
REDIR=$BASE/api/sso/callback    # 🔴 auth 한 겹이 없다
BACKCH=$BASE/api/sso/backchannel-logout
DATA=$D/rf-trouble-data
BKDIR=$D/rf-trouble-backup
ENVF=$ENVD/rf-trouble.env
# ══ 🔴 컨테이너가 도는 번호 — [실측] 2026-10-22 NAS 에서 id 1026 ═══════
#   uid=1026(swhur) gid=100(users) · groups=100,101(administrators),65537,65536
#   🔵 다른 집들(1001)과 다르다. 이 저장소의 compose.yaml 이 적고 있던 번호이고
#      NAS 에 **실재한다** — 바꾸지 마라.
APP_UID=1026
APP_GID=100
# compose 에 넣을 자리를 고를 때 쓰는 표시. [저장소] 27-inventory-place.sh 가
# 주석을 벗길 때 **표시 줄 자체는 그대로 두므로** NAS 의 compose 에도 남아 있다.
ANCHOR=DSS-INVENTORY-UNCOMMENT-END-TOOLS
# compose 에 반드시 그대로 있어야 하는 서비스 열여섯 [설문] 31-deploy.sh 의 목록
SVC_ALL="db-app db-auth app-auth app-as tools-as app-meters tools-meters"
SVC_ALL="$SVC_ALL app-improvements tools-improvements app-po app-leave tools-leave"
SVC_ALL="$SVC_ALL app-board tools-board app-inventory tools-inventory"
# 건드리지 않는 바깥 주소 여덟 [설문]
HOSTS8="login as meters improvements po leave board inventory"

PASS=0; FAIL=0; UNK=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
unk()  { echo "  ? $*"; UNK=$((UNK + 1)); }
say()  { echo "$*"; }
sec()  { echo; echo "══════════════════════════════════════════════════════════"; echo " $*"; echo "══════════════════════════════════════════════════════════"; }
isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }

# 🔴 로그 파일을 스스로 만들지 않는다. 27-inventory-check.sh 와 같은 모양이다 —
#    읽기만 하는 점검이라 **출력을 그대로 복사해** 주시면 된다. 남기고 싶으면:
#      sh 32-rf-trouble-check.sh 2>&1 | tee /volume1/dss/setup/logs/32-check.log
echo "RF 이슈관리 세우기 전 점검 · $(date '+%F %T')"

# ── 1 ────────────────────────────────────────────────────────────────
sec "1. 도커와 compose 가 멀쩡한가 (읽기만)"
if [ -x "$DOCKER" ]; then
  ok "docker 가 있다 ($("$DOCKER" --version 2>/dev/null | head -1))"
else
  bad "docker 를 못 찾았다: $DOCKER"
fi
if [ -f "$CF" ]; then
  ok "compose 가 있다 ($(wc -l < "$CF") 줄)"
else
  bad "compose 가 없다: $CF"
fi
CFG="$DOCKER compose --project-directory $D/deploy -f $CF --env-file $ENV_NAS --profile tools"
if $CFG config --quiet >/dev/null 2>&1; then
  ok "지금 compose 의 문법이 통과한다"
else
  bad "🔴 지금 compose 가 문법에서 걸린다 — **세우기 전에** 사람이 봐야 한다"
  $CFG config --quiet 2>&1 | sed 's/^/     /' | head -8
fi
SVCS=$($CFG config --services 2>/dev/null)
for s in $SVC_ALL; do
  printf '%s\n' "$SVCS" | grep -qx "$s" && ok "서비스 $s 가 있다" \
    || bad "🔴 서비스 $s 가 없다 — 올라온 compose 가 낡았다. 고치지 말고 알리세요"
done
N=$(printf '%s\n' "$SVCS" | grep -cx "$SVC")
if [ "${N:-0}" = 0 ]; then
  ok "$SVC 가 아직 없다 (기대한 상태 — 세우는 날 넣는다)"
else
  bad "🔴 $SVC 가 이미 ${N}개 있다 — 누가 먼저 넣었다. 고치지 말고 알리세요"
fi

# ── 2 ────────────────────────────────────────────────────────────────
sec "2. 넣을 자리와 포트"
say "🔵 compose 에 블록을 넣을 자리를 **표시 줄 하나**로 고른다. 그 줄은"
say "   27-inventory-place.sh 가 주석을 벗길 때도 그대로 남긴 줄이다."
N=$(grep -c "$ANCHOR" "$CF" 2>/dev/null)
if [ "${N:-0}" = 1 ]; then
  ok "넣을 자리 표시가 한 줄이다 ($ANCHOR)"
  say "     $(grep -n "$ANCHOR" "$CF" | head -1 | cut -c1-70)"
else
  bad "🔴 넣을 자리 표시가 ${N:-0}줄이다 (하나여야 한다) — --init 이 멈춘다"
  say "     고치지 말고 알리세요. 넣을 자리를 다시 골라야 합니다."
fi
say
say "    ── 🔴 호스트 포트 $HPORT 이 비어 있는가  [설문] 31-survey.sh 8절"
if grep -q "127\.0\.0\.1:$HPORT:" "$CF" 2>/dev/null; then
  bad "compose 에 $HPORT 이 이미 쓰이고 있다 — 다른 번호를 고르세요"
else
  ok "compose 에 $HPORT 이 아직 안 쓰인다"
fi
say "      지금 compose 가 쓰는 번호:"
grep -oE '127\.0\.0\.1:1[0-9]{4}:' "$CF" 2>/dev/null | sort -u | sed 's/^/        /'
if netstat -tln 2>/dev/null | grep -q ":$HPORT "; then
  bad "🔴 지금 $HPORT 을 **누가 듣고 있다** — 그대로 띄우면 부딪힌다"
  netstat -tln 2>/dev/null | grep ":$HPORT " | sed 's/^/        /'
else
  ok "지금 $HPORT 을 듣는 것이 없다"
fi
say "    🔵 컨테이너 안 포트는 $CPORT 그대로다 [저장소] Dockerfile 의 ENV PORT."
say "       앞의 여덟이 쓰던 「앞에 1 을 붙인 번호」 규칙을 쓸 수 없어 호스트"
say "       쪽만 $HPORT 을 쓴다."

# ── 3 ────────────────────────────────────────────────────────────────
sec "3. 이미지와 tar"
if "$DOCKER" image inspect "$TAG" >/dev/null 2>&1; then
  ok "$TAG 가 이미 실려 있다"
  "$DOCKER" image inspect "$TAG" --format '{{.Id}} {{.Size}}' 2>/dev/null | sed 's/^/     /'
  say "    🔵 이미지가 **어떤 번호를 들고 있는지**도 본다. 같을 필요는 없다 —"
  say "       compose 의 user: 가 $APP_UID:$APP_GID 로 덮어쓴다. 다르다는 것을"
  say "       눈으로 보게 하려고 찍는다. 컨테이너를 잠깐 띄웠다 지운다:"
  WHO=$("$DOCKER" run --rm --network none --entrypoint sh "$TAG" -c 'id' 2>&1 | head -1)
  case "$WHO" in
    uid=*) ok "이미지가 들고 있는 번호: $WHO (compose 가 $APP_UID:$APP_GID 로 덮어쓴다)" ;;
    *)     unk "이미지 안의 번호를 못 읽었다 — 아래가 그대로의 출력이다"
           printf '%s\n' "$WHO" | sed 's/^/       /' | head -3 ;;
  esac
else
  ok "$TAG 가 아직 안 실렸다 (기대한 상태 — --preload 가 싣는다)"
  say "    🔴 이미지는 **사람이 개발 PC 에서 굽는다.** Claude 는 굽지 않는다:"
  say "         docker build -t $TAG ."
  say "         docker save $TAG -o $TARF"
fi
if [ -s "$IMAGES/$TARF" ]; then
  ok "tar 가 와 있다 · 바이트 $(stat -c '%s' "$IMAGES/$TARF") · md5 $(md5sum "$IMAGES/$TARF" | awk '{print $1}')"
  say "    🔴 위 md5 를 **개발 PC 에서 잰 값과 맞춰야** 합니다. 눈으로만 보지 말고"
  say "       적어 두세요 — 32-rf-trouble-deploy.sh 가 그 파일을 읽어 기계로 셉니다:"
  say "       (개발 PC · PowerShell)  Get-FileHash -Algorithm MD5 .\\$TARF"
  say "       (NAS)                   vi $IN/rf-trouble-image.txt"
  say "                                 MD5=<소문자 32자>"
  say "                                 SIZE=<바이트>"
  if [ -r "$IN/rf-trouble-image.txt" ]; then
    ok "기대값 파일이 와 있다 (MD5 줄 $(grep -c '^[[:space:]]*MD5=' "$IN/rf-trouble-image.txt")개)"
  else
    unk "기대값 파일이 아직 없다 — 이대로면 --go 가 막힌다(막히는 것이 맞다)"
  fi
else
  ok "tar 가 아직 안 왔다 (기대한 상태)"
  say "    올릴 때:  scp -O $TARF dss-nas:/volume1/dss/images/"
fi

# ── 4 ────────────────────────────────────────────────────────────────
sec "4. 설정 파일 — 🔴 **이름만** 본다 (값도 길이도 안 찍는다)"
if [ -f "$ENVF" ]; then
  say "  🔵 rf-trouble.env 가 이미 있다 — 누가 먼저 올려 두었다."
  say "     주인·모드: $(stat -c '%U:%G %a' "$ENVF")"
  # [저장소] dss-trouble/docker.env.example 에서 뽑은 이름 넷
  for k in SSO_ISSUER SSO_CLIENT_ID SSO_CLIENT_SECRET SSO_REDIRECT_URI; do
    N=$(grep -cE "^[[:space:]]*(export[[:space:]]+)?$k=" "$ENVF" 2>/dev/null)
    if [ "${N:-0}" = 1 ]; then ok "$k 가 한 줄 있다"
    elif [ "${N:-0}" = 0 ]; then bad "$k 가 **없다**"
    else bad "$k 가 ${N}줄이다 — 🔴 나중 것이 이긴다. 하나만 남기세요"
    fi
  done
  # 🔴 여기 있으면 안 되는 이름. [저장소] docker.env.example 주석 ·
  #    Dockerfile 의 ENV · compose.dev.yaml 전용 값.
  for k in NAS_USER NAS_PASS TEAM_PASSWORD PORT HOST TZ WORKLOG; do
    N=$(grep -cE "^[[:space:]]*(export[[:space:]]+)?$k=" "$ENVF" 2>/dev/null)
    [ "${N:-0}" = 0 ] && ok "$k 가 없다 (맞다 — 이미지·compose 가 넘긴다)" \
      || bad "$k 가 **있다** (${N}줄) — 지우세요"
  done
  N=$(grep -ciE '^[[:space:]]*SSO=off' "$ENVF" 2>/dev/null)
  [ "${N:-0}" = 0 ] && ok "SSO=off 줄이 없다 (맞다 — 있으면 로그인이 꺼진다)" \
    || bad "🔴 SSO=off 가 있다 — 로그인이 꺼지고 바깥에서 아예 못 닿는다"
else
  ok "rf-trouble.env 가 아직 없다 (기대한 상태 — --init 이 **이름만** 적은 틀을 만든다)"
fi
say
say "  🔴 채워야 하는 값 넷 — 이름만 적는다. 값은 사람이 넣는다:"
say "       SSO_ISSUER         $ISSUER   (끝 빗금 없이)"
say "       SSO_CLIENT_ID      $CLIENT_ID"
say "       SSO_CLIENT_SECRET  (사람이 만든 값 · 어디에도 적지 않는다)"
say "       SSO_REDIRECT_URI   $REDIR"
say "  🔵 선택: OPENAI_API_KEY — config.json 의 ai.enabled 를 켤 때만."

# ── 5 ────────────────────────────────────────────────────────────────
sec "5. 자리 — 데이터 폴더 · 설정 파일 · 공유폴더"
if [ -d "$DATA" ]; then
  say "  🔵 $DATA 가 이미 있다"
  say "     $(stat -c '%u:%g %a' "$DATA") (숫자) · $(stat -c '%U:%G' "$DATA") (이름)"
  ls -la "$DATA" 2>/dev/null | sed 's/^/     /' | head -12
else
  ok "$DATA 가 아직 없다 (기대한 상태 — --init 이 만든다)"
fi
if [ -d "$BKDIR" ]; then
  say "  🔵 $BKDIR 이 이미 있다 · $(stat -c '%u:%g %a' "$BKDIR")"
else
  ok "$BKDIR 이 아직 없다 (기대한 상태 — --init 이 만든다)"
fi
if [ -e "$DATA/config.json" ]; then
  if [ -f "$DATA/config.json" ]; then
    ok "config.json 이 **파일**이다 ($(stat -c '%u:%g %a' "$DATA/config.json"))"
    say "     🔴 안을 찍지 않는다 — 공유폴더 경로가 들어 있다."
  else
    bad "🔴 config.json 자리에 파일이 아닌 것이 있다 — 도커가 만든 빈 폴더일 수 있다"
  fi
else
  ok "config.json 이 아직 없다 (기대한 상태 — **사람이 만든다**)"
  say "     🔴 이 파일이 없으면 도커가 그 자리에 **빈 폴더를 만들어** 붙인다."
  say "        그러면 앱이 설정을 못 읽는데 **오류가 안 난다.** --go 가 먼저 센다."
fi
say
say "    ── 🔵 **적어 두는 줄** — 컨테이너가 돌 번호"
say "       uid $APP_UID · gid $APP_GID   [실측] 2026-10-22 NAS 에서 id 1026"
say "       uid=1026(swhur) gid=100(users)."
say "       🔵 다른 집들(1001)과 **다르다.** 이 저장소의 compose 가 적고 있던"
say "          번호이고 NAS 에 실재한다 — 바꾸지 마세요."
say "       🔵 gid 100(users)인 까닭: 공유폴더의 시놀로지 ACL 이 이름 기반이라"
say "          그 그룹이어야 직원 폴더를 읽는다(나중에 붙이는 날 필요하다)."
say
say "    ── 🔵 **적어 두는 줄** — 공유폴더는 **이번에 안 붙인다**"
say "       2026-10-22 쓰는 분 결정: 파일 위치는 배포판 이후에 시스템에서 고른다."
say "       🔴 ✓ 로 세지 않는다 — 「맞게 됐다」가 아니라 「지금은 이렇다」이다."
say "          붙이는 날 여기와 견준다(그날 볼륨이 0 에서 둘로 는다)."
say "       🔴 없어도 앱은 뜬다 — 코드로 확인했다(2026-10-22). 시작하는 길에"
say "          공유폴더를 보는 자리가 하나도 없다(server.js 는 data/ 만 읽는다)."
say "       비는 것 둘:"
say "         · 자료 파일 **열기·내려받기** — 검색에 이름은 나오는데 못 찾는다"
say "         · 엑셀 **자동 재색인** — 설정·정보의 「자동 갱신」에 실패가 적힌다"
say "           🔵 kb.json 은 덮어써지지 않는다(build-kb.js 가 쓰기 전에 죽는다)"
say "       🔵 그 밖(이슈 등록·검색·주간보고·출장일정·첨부)은 **전부 그대로** 된다."
say "       🔵 config.json 의 autoRefreshSec 를 0 으로 두면 헛걸음과 경고가 없다."
say
# ── 6 ────────────────────────────────────────────────────────────────
sec "6. 포털 clients — 아홉째 자리"
say "🔵 열쇠는 **$CLIENT_ID** 다. 저장소 이름(dss-trouble)과 다르다."
say "   [저장소] dss-auth/src/lib/notifications/sources.ts 에 그 글자로 박혀 있다."
if "$DOCKER" ps --format '{{.Names}}' 2>/dev/null | grep -qx dss-pg-auth; then
  say "    ── 등록된 시스템 (🔴 비밀값 칸은 안 뽑는다)"
  # 🔴 SQL 은 **표준입력의 heredoc** 으로만 넘긴다. -c "…" 안에 작은따옴표를
  #    섞으면 셸이 먼저 먹어 조용히 다른 문장이 된다(27번이 그렇게 적고 있다).
  "$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL' 2>/dev/null | sed 's/^/      /'
\pset border 2
select client_id, is_active, requires_grant, sort_order
from clients order by sort_order, client_id;
SQL
  V=$("$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth -X -tAq' <<'SQL' 2>/dev/null | head -1 | tr -d ' \r'
select count(*) from clients where client_id = 'dss-rf-trouble';
SQL
)
  if isnum "${V:-}"; then
    if [ "$V" = 0 ]; then
      ok "$CLIENT_ID 이 아직 없다 (기대한 상태 — 32-rf-trouble-client.sh 가 넣는다)"
      say "     🔴 등록되기 전까지 포털은 그 집을 **부르러 가지도 않는다.**"
    else
      say "  🔵 $CLIENT_ID 이 이미 $V 줄 있다 — 누가 먼저 등록했다."
      say "     🔴 주소 넷을 글자 단위로 대조하세요(아래)."
      PASS=$((PASS + 1))
    fi
  else
    unk "clients 의 $CLIENT_ID 줄 수를 못 쟀다 — psql 이 수를 안 돌려줬다"
  fi
else
  unk "dss-pg-auth 가 안 돌고 있어 포털 쪽을 못 쟀다"
fi
say
say "  🔴 포털에 넣을 주소 넷 — **글자 단위로 대조한다. 와일드카드도 정규화도 없다**"
say "       SSO_ISSUER            $ISSUER"
say "       SSO_REDIRECT_URI      $REDIR"
say "       redirect_uris         $REDIR"
say "       backchannel_logout    $BACKCH"
say "  🔴 콜백이 /api/sso/callback 이다 — 다른 여덟(/api/auth/sso/callback)과 다르다."

# ── 7 ────────────────────────────────────────────────────────────────
sec "7. 야간 백업 — 🔴 2026-09-29 에 11일을 잃은 그 함정"
say "🔴 이 시스템은 **DB 가 없다.** 백업 대상이 폴더 하나(rf-trouble-data)뿐이라"
say "   그 한 줄이 빠지면 **전부가** 백업되지 않는다. 개선요청은 같은 모양으로"
say "   11일간 아무 오류 없이 백업되지 않았다."
if [ -f "$JOB" ]; then
  ok "야간 백업 스크립트가 제자리에 있다 ($(stat -c '%U:%G %a' "$JOB"))"
  say "     md5 $(md5sum "$JOB" | awk '{print $1}')"
  N=$(grep -c 'rf-trouble-data' "$JOB" 2>/dev/null)
  if [ "${N:-0}" -ge 1 ]; then
    ok "🔴 NAS 의 그 파일에 rf-trouble-data 줄이 ${N}개 **있다**"
  else
    ok "rf-trouble-data 줄이 아직 없다 (기대한 상태 — --init 이 새 판을 놓는다)"
    say "     🔴 「고쳤다」와 「올렸다」는 다른 일이다. --init 이 올린 뒤 다시 센다."
  fi
  if bash -n "$JOB" 2>/dev/null; then ok "야간 백업 문법 통과"; else bad "🔴 야간 백업에 문법 오류가 있다"; fi
else
  bad "🔴 야간 백업 스크립트가 없다: $JOB"
fi
if [ -d "$BKDB" ]; then
  N=$(find "$BKDB" -name '*.dump' -mtime -2 2>/dev/null | wc -l | tr -d ' ')
  if isnum "${N:-}" && [ "$N" -ge 7 ]; then
    ok "이틀 안에 뜬 덤프가 ${N}개 (DB 일곱 이상)"
  else
    bad "🔴 이틀 안에 뜬 덤프가 ${N:-?}개다 — 일곱을 기대했다. **세우기 전에 백업부터**"
  fi
else
  unk "야간 백업 폴더를 못 봤다: $BKDB"
fi

# ── 8 ────────────────────────────────────────────────────────────────
sec "8. 바깥 주소 — 지금은 안 열리는 것이 정상이다"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$BASE/" 2>/dev/null)
case "$code" in
  2??|3??) say "  🔵 $BASE → $code — **벌써 무언가 받고 있다.** 사람이 확인하세요."
           PASS=$((PASS + 1)) ;;
  *)       ok "$BASE → ${code:-없음} (아직 안 열렸다 — 기대한 상태)" ;;
esac
say "  🔴 건드리지 않는 여덟이 그대로인가:"
for h in $HOSTS8; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code" ;;
    *)       bad "🔴 https://$h.dss21.co.kr → ${code:-없음} — 세우기 전부터 흔들려 있다" ;;
  esac
done
say "  열린 포트 (127.0.0.1 만이어야 한다):"
netstat -tln 2>/dev/null | grep ':13[0-9]\{3\}' | sed 's/^/     /'
say "  메모리:"
free -m 2>/dev/null | sed 's/^/     /'
say "  🔴 아홉째를 켜면 상한 합계가 늘어난다. compose 맨 아래 예산표를 세운 뒤"
say "     docker stats --no-stream 으로 **실측**해 다시 적는다."

# ── 9 ────────────────────────────────────────────────────────────────
sec "9. 🔴 사람이 먼저 하거나 정해야 하는 것"
cat <<'TODO'
  ① 🔵 공유폴더 두 자리와 uid 는 **정해졌다. 할 일이 없다.**
     · 공유폴더는 **이번에 안 붙인다**(2026-10-22 결정 — 파일 위치는 배포판
       이후에 시스템에서 고른다). 위 5절의 「적어 두는 줄」이 그 자리다.
     · uid 는 1026:100 으로 박아 두었다([실측] id 1026).
  ② 이미지 굽기 — 개발 PC 에서. Claude 는 굽지 않는다.
       docker build -t dss-rf-trouble:0.1 .
       docker save dss-rf-trouble:0.1 -o dss-rf-trouble-0.1.tar
       scp -O dss-rf-trouble-0.1.tar dss-nas:/volume1/dss/images/
  ③ 클라이언트 비밀값 — 사람이 만든다. 평문은 NAS 의 rf-trouble.env 한 곳,
     포털에는 sha256 64자만 넣는다. 🔴 채팅·로그·스크립트에 적지 않는다.
       (만드는 법은 32-rf-trouble-client.sh 머리말에 있다)
  ④ Cloudflare 에 A 레코드 issues 를 하나 더한다.
  ⑤ 🔴 DSM 리버스 프록시 — 사람이 넣는다. 다른 여덟과 같은 모양이다:
       DSM → 제어판 → 로그인 포털 → 고급 → 리버스 프록시 → 만들기
         설명      RF 이슈관리
         원본      HTTPS · issues.dss21.co.kr · 포트 443
         대상      HTTP  · localhost          · 포트 13900
         사용자 지정 머리글 → 만들기 → WebSocket  (다른 여덟과 같게)
       🔴 인증서 탭에서 **dss21.co.kr 와일드카드**를 고른다.
          기본값이 synology.com 이라 그대로 두면 경고가 뜬다.
  ⑥ config.json — 사람이 만든다. 저장소의 config.docker.example.json 을
     복사해 아래에 둔다:
       /volume1/dss/rf-trouble-data/config.json
     🔵 공유폴더를 아직 안 붙였으므로 이번에는 이렇게 두기를 권한다:
       · backup.dir 은 "/backup" (절대 경로 — compose 가 붙인 자리다)
       · autoRefreshSec 는 0 (헛걸음할 공유폴더가 없다)
       · sourceExcel · baseDir · pathMap 은 붙이는 날 채운다. 그날
         pathMap 오른쪽을 /mnt/nas7 · /mnt/nas1 로 맞춘다.
     🔴 놓은 뒤 주인을 맞춘다:  chown 1026:100 .../config.json
TODO

# ── 끝 ───────────────────────────────────────────────────────────────
echo
echo "══════════════════════════════════════════════════════════"
printf '요약 — ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
if [ "$UNK" -gt 0 ]; then
  echo "🔴 **못 쟀거나 사람이 정해야 하는 것이 $UNK 개 있다.** 통과로 세지 않는다."
fi
if [ "$FAIL" -gt 0 ]; then
  echo "🔴 **어긋난 것이 $FAIL 개 있다.**"
  echo "🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 기대값의 출처는 그 줄"
  echo "   바로 옆 주석에 적혀 있습니다([설문]·[저장소]·[결정])."
fi
echo "이 출력을 그대로 복사해 주세요."
echo "다음:  sh /volume1/dss/setup/32-rf-trouble-client.sh   (포털 등록)"
echo "══════════════════════════════════════════════════════════"
if [ "$UNK" -gt 0 ] || [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
