#!/bin/bash
# /volume1/dss/setup/25-deploy.sh — 2026-10-13 사내 게시판 **첫 설치**
#
# ── 이것은 「갈아 끼우기」가 아니라 「없던 것을 세우는 일」이다 ─────────
#   본은 13-deploy.sh(휴가 첫 설치)다. 이미지 교체용인 24-deploy.sh 가 아니다 —
#   첫 설치는 성격이 다르다. 검사가 보는 것이 「도는 것이 흔들리지 않았나」가
#   아니라 **「띄울 자리가 다 됐나」**다.
#   (그 차이는 runbook/06-개선요청-배포.md 0절에 표로 적혀 있다.)
#
#   게시판 : dss-board:0.1 · dss-board-tools:1 · DB dss_board · 롤 dss_board_app
#            컨테이너 안 3400 → 127.0.0.1:13400 → https://board.dss21.co.kr
#            첨부 /volume1/dss/board-uploads → 컨테이너 /data/uploads
#
# ── 🔴 번호가 25 인 까닭 ───────────────────────────────────────────────
#   런북 번호(runbook/14-게시판-설치-점검표.html)와 스크립트 번호는 **별개
#   체계**다. setup/ 에는 이미 14-pg-auth-check.sh 가 있고 24 까지 차 있다.
#   그래서 이 설치의 스크립트는 전부 25- 로 쓴다. 점검표가 부르는 이름도 같다.
#
# ── 🔴 첫 설치 순서. 이 차례로 부른다 ──────────────────────────────────
#
#   1) bash 25-deploy.sh                읽기만. 어긋난 곳을 먼저 고친다
#   2) bash 25-deploy.sh --preload      이미지 둘을 싣는다 (아무것도 안 멈춤)
#   3) bash 25-deploy.sh                다시 읽기만 — 이번엔 지문까지 다 본다
#   4) bash 25-deploy.sh --init         🔴 표 일곱을 만든다 (DB 가 바뀐다)
#   5) bash 25-deploy.sh --go           앱을 띄운다
#   6) 눈으로 확인 (runbook/14-게시판-설치-점검표.html 7절)
#
#   🔴 4 와 5 는 **합치지 않았다.** 표가 없는 DB 에 앱이 먼저 뜨면 첫 화면이
#      42P01 (relation "web_posts" does not exist) 로 죽는다. 「줄이 없다」가
#      아니라 「표가 없다」이므로 앱이 먼저 뜨면 안 된다. 그래서 **순서를
#      강제한다** — 5(--go)는 시작하기 전에 「마이그레이션 1줄 · 표 일곱」을
#      DB 에서 다시 세고, 아니면 **앱을 띄우지 않고 멈춘다.** 명령은 둘로
#      나눠 두고(사람이 DB 를 바꾸는 일과 앱을 띄우는 일을 따로 결정한다),
#      순서만 기계가 지킨다.
#
#   🔵 휴가의 seed:ranks 같은 **채워 넣기는 없다.** 게시판은 빈 표로 시작하고,
#      첫 사람이 로그인하는 순간 web_users 에 행이 생긴다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/25-deploy.sh          ← 읽기만 한다
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#
#   13-deploy.sh 가 정한 기본값을 그대로 잇는다. 실수로 그냥 돌려도 아무것도
#   바뀌지 않는다(로그 파일 하나만 남는다). 코드로는 이 두 줄이다:
#     · MODE=check       (모드 절의 첫 줄)
#     · FORCE_LOAD=0     (같은 태그를 덮어쓰지 않는다)
#   그리고 DB 를 바꾸는 곳은 --init 한 군데뿐이고, 컨테이너를 띄우는 곳은
#   --go 한 군데뿐이다. --check 는 그 둘을 **부르지 않는다.**
#
#   🔴 두 가지는 정직하게 적어 둔다 — --check 도
#      ① 이미지 **안을 보려고** 컨테이너를 잠깐 띄웠다 지운다
#      ② 첨부 폴더에 **쓸 수 있는지** 보려고 파일을 하나 만들었다 지운다
#      「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확한
#      말이다. 안을 세는 검사도 권한 검사도 그것 없이 할 수 없다.
#
# ── 모드 여섯 ───────────────────────────────────────────────────────────
#   (없음) · --check   읽기만. 아무것도 안 바꾸고 안 멈춘다        ← 기본값
#   --preload          이미지 둘을 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load       🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --init             🔴 db:migrate — 표 일곱을 만든다. DB 가 바뀐다
#   --go               app-board 를 띄운다 (다른 여섯은 안 멈춘다)
#   --rollback         내리는 명령과 compose 되돌리는 명령을 찍는다
#
#   --force-load 는 --preload 와 같이 써도 된다:
#     bash 25-deploy.sh --preload --force-load
#
# ── 🔴 이미 끝나 있어야 하는 것 (이 스크립트는 **검사만** 한다) ────────
#   · 이미지 둘을 /volume1/dss/images/ 에 올렸다
#   · DB dss_board · 롤 dss_board_app 을 만들고 비밀번호도 넣었다
#     (25-board-db.sh · 25-board-pw.sh · 25-board-check.sh 까지 끝)
#   · .env.nas 에 BOARD_APP_PASSWORD 한 줄
#   · 포털 clients 에 dss-board 등록 (25-board-client.sh · requires_grant=false)
#   · Cloudflare A 레코드 · DSM 리버스 프록시 · 인증서(dss21.co.kr)
#   · board.env · compose · 야간 백업 파일을 NAS 로 올려 제자리에 놓고,
#     첨부 폴더를 만들어 권한을 맞췄다 (25-board-place.sh)
#
# ══ 🔴 이 스크립트가 **왜 이렇게 의심이 많은가** ═══════════════════════
#
#   이 저장소가 같은 함정에 여러 번 걸렸다. 넷 다 **오류가 안 났다.**
#
#   ① 「만든 것」과 「도는 것」은 다르다
#      개선요청 DB 가 11일간 한 번도 백업되지 않았다. 백업 스크립트의 저장소
#      사본에는 그 줄이 있었는데 **NAS 에 올리지 않았다.** 없는 줄은
#      실패하지 않는다.
#      → 검사 9 가 「오늘 백업이 **여섯**인가」를 센다.
#
#   ② 태그가 같아도 **속이 다를 수 있다**
#      A/S 도구 이미지가 vendor 를 안 담은 채 여드레 돌았다. 휴가 도구 이미지는
#      scripts 가 빠져 있었다. 태그로는 구별이 안 된다.
#      → 검사 2 가 도구 이미지 **안을 센다**(마이그레이션 하나 · 비상구 둘).
#
#   ③ 유닉스 소켓으로 한 DB 확인은 **거짓 통과**를 낸다
#      소켓은 보통 trust 라 **비밀번호가 없어도 통과한다.**
#      → 검사 4 는 앱이 붙는 길과 같게 **-h 127.0.0.1**(TCP)로 붙어 본다.
#
#   ④ 폴더는 「있는가」로 보면 안 된다 — 🔴 **이 설치의 핵심이다**
#      컨테이너는 node(uid 1000)로 도는데 dss 공유폴더에는 시놀로지 ACL 이
#      걸려 있다. 주인이 맞아도 ACL 이 막으면 못 쓴다. 그 결함은 배포할 때
#      전부 통과하고 **사람이 사진을 붙이는 순간** 처음 드러난다.
#      → 검사 7 이 임시 컨테이너를 -u 1000:1000 으로 띄워 **실제로 쓴다.**
#
#   ⑤ 사람이 칠 명령은 **한 줄 76자 안쪽**
#      DSM 의 ash 에 긴 줄을 붙여넣으면 줄바꿈이 끼어들어 **줄이 잘린다.**
#      → 이 스크립트가 찍는 명령은 전부 cmd() 를 지난다. 넘으면 스스로 경고한다.
#
#   ⑥ bash -n 이 못 잡는 둘 — 이 저장소에서 실제로 두 번 깨졌다
#      · 큰따옴표 안의 백틱은 명령 치환으로 읽힌다(운영 --check 에서
#        syntax error 가 났다). → 이 파일에는 백틱이 한 개도 없다.
#      · 읽기 전용 자리의 리다이렉션은 ash 가 셸을 그 자리에서 끝낸다
#        (뒤 줄이 안 돌아 안전검사가 **빈 채로** 지나갔다). → touch 를 쓴다.
#
# ── 🔴 되돌리기 ────────────────────────────────────────────────────────
#   첫 설치라 「옛 태그로 내린다」가 없다. 되돌리기는 **없던 것으로** 돌린다:
#     · app-board 를 멈추고 지운다
#     · compose 를 backups/ 의 사본으로 되돌린다
#     · 🔴 **DB 와 포털 등록은 남긴다.** 해가 없고, 다시 띄울 때 그대로 쓴다.
#     · 🔴 **마이그레이션은 되돌리지 않는다.** 표를 만들기만 했고, 이 DB 는
#       게시판 혼자 쓴다 — 다른 사이트가 보는 자리가 아니다.
#     · 🔴 **첨부 폴더는 건드리지 않는다.** 사람이 올린 사진은 되돌릴 수 없다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
ACLT=/usr/syno/bin/synoacltool
STAMP=$(date +%Y%m%d-%H%M%S)
TODAY=$(date +%F)
CF=$D/deploy/docker-compose.nas.yml
INCOMING=$D/setup/incoming/docker-compose.nas.yml
ENV_NAS=$D/deploy/.env.nas
ENVD=$D/deploy/env
IMAGES=$D/images
BKD=$D/backups

# ── 🔴 이번에 새로 서는 것 **둘** ──────────────────────────────────────
TAG_APP=dss-board:0.1
TAG_TOOLS=dss-board-tools:1

# ── tar 둘 · 개발 PC 실측 (2026-10-13) ─────────────────────────────────
# 🔴 .tar 다(비압축). 크기와 md5 는 **파일 전송이 온전한지**를 본다 —
#    이미지의 지문(sha256)은 tar_config_id() 가 tar 안에서 따로 읽어 낸다.
#    둘은 다른 것을 본다.
# ⚠️ tar 가 이미지의 1/4 쯤인 것은 정상이다(398MB 이미지 → 92MB tar).
#    「빌드가 잘못됐나」로 의심할 일이 아니다.
# 🔴 docker save 를 **다시 돌리면 이 값이 달라질 수 있다.** 이미 뽑아 둔
#    파일을 그대로 올리세요(점검표 4-①).
TAR_APP=$IMAGES/dss-board-0.1.tar
SZ_APP=96508416;     MD5_APP=0e97b46a2472e9d985ddc2102bffe543
TAR_TOOLS=$IMAGES/dss-board-tools-1.tar
SZ_TOOLS=214686720;  MD5_TOOLS=33f62c22ae4d1c8b123e4a721dcfc733

# ── 🔴 **건드리지 않는 열.** ───────────────────────────────────────────
# 전부 지금 운영에서 돌고 있다. compose 에서 이 태그가 흔들렸으면 남의 것이
# 섞인 것이다(두 세션이 같은 저장소를 쓴다 — HANDOFF A절). 고치지 말고 알린다.
KEEP_AUTH=dss-auth:1.6
KEEP_AS=dss-as:2.5
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_METERSTOOLS=dss-meters-tools:1
KEEP_IMP=dss-improvements:0.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_PO=dss-po:0.5
KEEP_LEAVE=dss-leave:0.2
KEEP_LEAVETOOLS=dss-leave-tools:2

# ── 게시판의 값들 ──────────────────────────────────────────────────────
BOARD_DB=dss_board
BOARD_ROLE=dss_board_app
BOARD_ENV=$ENVD/board.env
BOARD_SVC=app-board
BOARD_TOOLS_SVC=tools-board
BOARD_CNAME=dss-board
BOARD_PORT=13400
BOARD_INNER=3400
BOARD_HOST=board.dss21.co.kr
BOARD_BASE=https://board.dss21.co.kr
BOARD_UPLOADS=$D/board-uploads
BOARD_MNT=/data/uploads
CLIENT_ID=dss-board
CB_PATH=/api/auth/callback

# 🔴 실측이다 (dss-board/drizzle/meta/_journal.json · 2026-10-13).
#    마이그레이션은 **하나**이고 그 하나가 표 일곱을 전부 만든다.
MIG_TAGS="0000_blue_taskmaster"
N_MIG_WANT=1
N_TABLE_WANT=7
# 🔴 표 이름도 실측이다 (dss-board/drizzle/0000_blue_taskmaster.sql).
BOARD_TABLES="web_users web_sessions web_posts web_post_files web_post_images web_post_views web_audit_logs"

# board.env 에 **있어야 하는** 일곱 (dss-board/.env.example · src/lib/env.ts)
ENV_KEYS="OIDC_ISSUER OIDC_CLIENT_ID OIDC_CLIENT_SECRET OIDC_REDIRECT_URI"
ENV_KEYS="$ENV_KEYS AUTH_STATE_SECRET SESSION_COOKIE_SECURE SESSION_HOURS"
# board.env 에 **있으면 안 되는** 다섯. 앞 넷은 compose 와 이미지가 넘긴다 —
# 같은 값이 두 곳에 있으면 언젠가 한쪽만 바뀌는데, 그때 앱은 **오류 없이**
# 다른 DB 를 보거나 엉뚱한 자리에 사진을 쌓는다.
# 🔴 SEED_DEV_ENABLED 는 성격이 다르다 — 개발용 가짜 글을 넣는 울타리이고
#    없으면 꺼진 것이다. 운영 DB 를 가리킨 채 켜져 있으면 가짜 글이 들어간다.
ENV_FORBIDDEN="DATABASE_URL PORT STORAGE_ROOT TZ SEED_DEV_ENABLED"

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 둘. 인자가 없으면 이 둘 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 25-deploy.sh                 읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 25-deploy.sh --check         위와 같습니다
  bash 25-deploy.sh --preload       이미지 둘을 싣고 지문을 맞춥니다
  bash 25-deploy.sh --force-load    🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 25-deploy.sh --init          🔴 표 일곱을 만듭니다 (DB 가 바뀜)
  bash 25-deploy.sh --go            app-board 를 띄웁니다
  bash 25-deploy.sh --rollback      되돌리기 안내 (아무것도 안 바꿉니다)

  🔴 첫 설치 차례:  (없음) → --preload → (없음) → --init → --go
  🔴 --init 과 --go 는 **따로** 부릅니다. 표가 없는 DB 에 앱이 먼저 뜨면
     첫 화면이 42P01 로 죽습니다. --go 는 시작 전에 표를 다시 세어 보고,
     아니면 앱을 띄우지 않고 멈춥니다.
  🔴 --go 가 띄우는 것은 app-board 하나입니다. 포털 · A/S · 계측기 ·
     개선요청 · PO · 휴가 · DB 는 그대로 돕니다.
USAGE
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)      MODE=check ;;
    --preload)    MODE=preload ;;
    --force-load) FORCE_LOAD=1; [ "$MODE" = check ] && MODE=force-load ;;
    --init)       MODE=init ;;
    --go)         MODE=go ;;
    --rollback)   MODE=rollback ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "모르는 인자: $1"; usage; exit 2 ;;
  esac
  shift
done

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/25-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 13-deploy.sh 의 것을 그대로 쓴다 ──────────────────────────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# ── ⑤ 사람이 칠 명령은 76자 안쪽으로만 찍는다 ──────────────────────────
CMDW=76
cmd() { # 1 사람이 그대로 칠 명령 한 줄
  printf '    %s\n' "$1"
  if [ "${#1}" -gt "$CMDW" ]; then
    printf '    ⚠️ 위 줄이 %s자다(%s자 넘음) — 붙여넣으면 잘릴 수 있다.\n' "${#1}" "$CMDW"
    printf '       아래 「스크립트 파일로 만들기」를 쓰세요.\n'
  fi
}
script_file_hint() { # 1 파일이름(확장자 없이)
  say "    ── 길면 붙여넣지 말고 파일로 만드세요 ──"
  cmd "cat > /volume1/dss/setup/$1.sh"
  say "      (여기에 위 줄들을 붙여넣고 Ctrl+D)"
  cmd "bash /volume1/dss/setup/$1.sh"
}

COMPOSE=("$DOCKER" compose -f "$CF" --env-file "$ENV_NAS" --profile tools)
# 아직 갈아 끼우지 않은 compose 를 **시험만** 해 볼 때 쓴다.
compose_at() { # 1 compose파일  나머지: compose 에 넘길 인자
  local f="$1"; shift
  "$DOCKER" compose --project-directory "$D/deploy" -f "$f" --env-file "$ENV_NAS" --profile tools "$@"
}

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미
#
#  🔴 이 스크립트가 DB 를 바꾸는 곳은 **--init 한 군데뿐**이다. 아래 것들은
#     전부 SELECT 다.
#  🔴 아래 넷은 컨테이너 안에서 **유닉스 소켓**으로 붙는다(superuser). 읽기에는
#     그것으로 충분하지만, **비밀번호가 맞는지는 이것으로 알 수 없다** —
#     소켓은 보통 trust 라 거짓 통과를 낸다. 그 확인은 tcp_db_check() 가
#     -h 127.0.0.1 로 따로 한다(머리말 ③).
# ══════════════════════════════════════════════════════════════════════
qpg() { "$DOCKER" exec dss-pg-app  sh -c "psql -U \"\$POSTGRES_USER\" -d postgres  -Atc \"$1\"" 2>/dev/null; }
qb()  { "$DOCKER" exec dss-pg-app  sh -c "psql -U \"\$POSTGRES_USER\" -d $BOARD_DB -Atc \"$1\"" 2>/dev/null; }
qqb() { "$DOCKER" exec dss-pg-app  sh -c "psql -U \"\$POSTGRES_USER\" -d $BOARD_DB -c   \"$1\"" 2>/dev/null; }
qa()  { "$DOCKER" exec dss-pg-auth sh -c "psql -U \"\$POSTGRES_USER\" -d dss_auth  -Atc \"$1\"" 2>/dev/null; }

pg_up() { "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-app; }
running() { "$DOCKER" ps --format '{{.Names}}' | grep -qx "$1"; }

# ── 설정 파일에서 값 하나를 꺼낸다 ─────────────────────────────────────
# 🔴 부르는 쪽은 이 값을 **절대 화면에 찍지 않는다.** 판정에만 쓴다.
#
# 🔴 같은 이름이 두 줄 있으면 **나중 것**을 읽는다(head 가 아니라 tail).
#    docker compose 가 그렇게 읽기 때문이다 — env_file 도 --env-file 도 뒤에
#    나온 줄이 앞의 것을 덮는다. 앞 줄을 읽고 판정하면 「내가 본 값」과
#    「앱이 받는 값」이 달라진다. 그것이 이 스크립트가 가장 피하려는 종류의
#    거짓 통과다.
env_val() { # 1 파일 2 키
  local v
  [ -r "$1" ] || { printf ''; return 1; }
  v=$(sed -n "s/^[[:space:]]*\(export[[:space:]][[:space:]]*\)\?$2=//p" "$1" 2>/dev/null | tail -1 | tr -d '\r')
  v=${v#\"}; v=${v%\"}
  v=${v#\'}; v=${v%\'}
  printf '%s' "$v"
}
env_has() { # 1 파일 2 키  → 줄이 있으면 0
  grep -qE "^[[:space:]]*(export[[:space:]]+)?$2=" "$1" 2>/dev/null
}
env_dups() { # 1 파일 2 키  → 줄 수
  # 🔴 「|| echo 0」을 붙이지 않는다. grep -c 는 0건일 때도 0 을 찍고 종료코드만
  #    1 이라, 붙이면 값이 두 줄("0" 다음에 또 "0")이 되어 비교가 전부 어긋난다.
  grep -cE "^[[:space:]]*(export[[:space:]]+)?$2=" "$1" 2>/dev/null
}

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 개발 PC 의 docker image inspect 가 아니라 **이 값**이 NAS 에 실렸을 때의
#    image ID 가 된다(11-deploy.sh 머리말의 그 까닭).
tar_config_id() { # 1 tar 경로  → sha256:<지문>
  local raw v
  raw=$(tar -xOf  "$1" manifest.json 2>/dev/null) || raw=""
  [ -n "$raw" ] || raw=$(tar -xzOf "$1" manifest.json 2>/dev/null) || raw=""
  v=$(printf '%s' "$raw" \
      | sed -n 's/.*"Config"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  v=${v##*/}; v=${v%.json}
  [ -n "$v" ] || return 1
  echo "sha256:$v"
}
have_img() { "$DOCKER" image inspect "$1" >/dev/null 2>&1; }
img_id()   { "$DOCKER" image inspect "$1" --format '{{.Id}}' 2>/dev/null; }

verify_img() { # 1 태그 2 기대지문
  local got
  got=$(img_id "$1")
  if [ "$got" != "$2" ]; then
    bad "$1 지문이 tar 와 다르다 (NAS ${got:-없음} / tar $2)"
    return 1
  fi
  ok "$1 지문 맞음 ($(echo "$2" | cut -c1-19)…)"
}

# ── 같은 태그를 덮어쓰는 길 ────────────────────────────────────────────
# 태그를 그대로 두고 다시 구운 이미지는 have_img 갈래에서 영영 안 실린다.
force_load_hint() { # 1 태그
  say "    🔴 같은 태그로 **다시 구운** 이미지일 수 있다. 덮어쓰려면:"
  cmd "bash $0 --preload --force-load"
}
bring_img() { # 1 태그 2 tar 3 지문
  if [ "$FORCE_LOAD" = 1 ]; then
    say "  · --force-load — $1 가 이미 있어도 **다시 싣는다**"
    "$DOCKER" load -i "$2" >/dev/null 2>&1 && ok "$1 다시 실었다" \
      || { bad "$1 싣기 실패 ($2)"; return 1; }
  elif have_img "$1"; then
    say "  · $1 는 이미 실려 있다 — 다시 싣지 않는다 (덮어쓰려면 --force-load)"
  else
    "$DOCKER" load -i "$2" >/dev/null 2>&1 && ok "$1 실었다" \
      || { bad "$1 싣기 실패 ($2)"; return 1; }
  fi
  verify_img "$1" "$3" || { force_load_hint "$1"; return 1; }
}

wait_http() { # 1 이름 2 포트 3 경로 4 컨테이너
  local i code
  for i in $(seq 1 90); do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://127.0.0.1:$2$3" 2>/dev/null)
    case "$code" in 2??|3??) ok "$1 응답 $code ($((SECONDS - T0))초)"; return 0 ;; esac
    sleep 2
  done
  bad "$1 이 180초 안에 대답하지 않았다 (마지막 ${code:-없음})"
  say "    로그:"
  cmd "$DOCKER logs --tail 50 $4"
  return 1
}

# ── compose 파일에서 서비스 한 덩어리만 잘라 낸다 ──────────────────────
# 🔴 파일 전체를 grep 하면 안 된다 — 주석 줄이 그대로 걸려서 꺼져 있는
#    서비스를 「가리킨다」고 세게 된다(11-deploy.sh 의 그 함정).
#    🔴 이번 설치에서는 그것이 특히 중요하다. app-board 와 tools-board 는
#       **주석으로 들어가 있다가** 3단계에서 벗겨진다. 안 벗긴 판에서도
#       파일 전체 grep 은 전부 ✓ 를 낸다 — 그러면 이 검사가 쓸모가 없다.
svc_block() { # 1 compose파일 2 서비스이름
  awk -v s="  $2:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$1" | sed '/^[[:space:]]*#/d'
}
svc_image() { # 1 compose파일 2 서비스이름
  svc_block "$1" "$2" | sed -n 's/^[[:space:]]*image:[[:space:]]*//p' | head -1
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 검사 4 의 핵심 — DB 에 **TCP 로** 붙어 본다
#
#  docker exec dss-pg-app psql -U dss_board_app … 은 **유닉스 소켓**으로 붙는데,
#  소켓은 pg_hba 에서 보통 trust 다 — **비밀번호가 틀려도, 아예 없어도
#  통과한다.** 그것으로 「붙는다」를 확인하고 넘어가면, 앱이 뜨는 순간
#  password authentication failed 로 죽는다.
#
#  앱은 compose 가 넘긴 DATABASE_URL 로 **dss-pg-app:5432(TCP)** 에 붙는다.
#  그러니 확인도 TCP 로 한다.
#
#  🔴 비밀번호는 **표준입력으로만** 흐른다. 화면에는 한 글자도 안 찍는다.
# ══════════════════════════════════════════════════════════════════════
tcp_db_check() {
  local pw out out2 n
  if ! pg_up; then
    bad "dss-pg-app 이 떠 있지 않다 — DB 를 볼 수 없다"
    return 1
  fi
  if [ ! -r "$ENV_NAS" ]; then
    bad "$ENV_NAS 를 읽을 수 없다 — sudo -i 로 돌리고 계십니까"
    return 1
  fi
  if ! env_has "$ENV_NAS" BOARD_APP_PASSWORD; then
    bad ".env.nas 에 BOARD_APP_PASSWORD 줄이 없다 — 25-board-pw.sh 를 돌리세요"
    return 1
  fi
  n=$(env_dups "$ENV_NAS" BOARD_APP_PASSWORD)
  if [ "${n:-0}" != 1 ]; then
    bad ".env.nas 에 BOARD_APP_PASSWORD 가 ${n}줄이다 — 하나만 남기세요"
    say "      나중 것이 이긴다. 아래 시험은 **나중 것**으로 해 본다."
  fi
  pw=$(env_val "$ENV_NAS" BOARD_APP_PASSWORD)
  if [ -z "$pw" ]; then
    bad ".env.nas 의 BOARD_APP_PASSWORD 는 줄만 있고 값이 비었다"
    return 1
  fi
  ok ".env.nas 에 BOARD_APP_PASSWORD 가 있다 (🔴 값은 안 찍는다)"

  out=$(printf '%s\n' "$pw" | "$DOCKER" exec -i \
        -e R="$BOARD_ROLE" -e DBN="$BOARD_DB" dss-pg-app sh -c '
    read -r PW
    PGPASSWORD="$PW" psql -X -tAq -h 127.0.0.1 -U "$R" -d "$DBN" \
      -c "select current_user" 2>&1')
  pw=
  # 🔴 갈래 차례가 중요하다. 실패 문장이 롤 이름을 품고 있어서,
  #    성공 갈래를 먼저 두면 실패가 ✓ 로 둔갑한다.
  case "$out" in
    *"authentication failed"*)
      bad "🔴 TCP 로 붙지 못했다 — .env.nas 의 값과 롤의 비밀번호가 다르다"
      say "      앱이 뜨는 순간 password authentication failed 로 죽는다."
      say "      다시 맞추는 길(둘을 한꺼번에 맞춘다):"
      cmd "sh /volume1/dss/setup/25-board-pw.sh"
      return 1 ;;
    *"no password supplied"*)
      bad "🔴 비밀번호가 안 넘어갔다 — .env.nas 의 값이 비어 있는 듯하다"
      return 1 ;;
    *"could not connect"*|*"Connection refused"*|*"could not translate"*)
      bad "🔴 TCP 로 서버에 닿지 못했다 (127.0.0.1:5432)"
      printf '%s\n' "$out" | sed 's/^/      /' | head -4
      return 1 ;;
    "$BOARD_ROLE")
      ok "🔴 TCP(-h 127.0.0.1)로 $BOARD_ROLE 이 $BOARD_DB 에 붙었다 — 진짜 확인" ;;
    *"$BOARD_ROLE"*)
      ok "TCP 로 붙었다 (출력에 다른 줄이 섞였지만 $BOARD_ROLE 로 붙었다)" ;;
    *)
      bad "TCP 접속을 판정하지 못했다 — psql 이 말한 것:"
      printf '%s\n' "$out" | sed 's/^/      /' | head -4
      return 1 ;;
  esac

  # 곁들여 — 그 통과가 **진짜 인증을 지난 것인지**까지 본다.
  out2=$("$DOCKER" exec -e R="$BOARD_ROLE" -e DBN="$BOARD_DB" dss-pg-app sh -c '
    PGPASSWORD="" psql -X -tAq -h 127.0.0.1 -U "$R" -d "$DBN" -c "select 1" 2>&1')
  case "$out2" in
    *"authentication failed"*|*"no password supplied"*)
      ok "빈 비밀번호로는 거절당한다 — TCP 인증이 실제로 걸려 있다" ;;
    1)
      say "  ⚠️ 빈 비밀번호로도 붙는다 — host 규칙이 trust 다. 위 ✓ 는 증거가"
      say "     약하다(비밀번호가 틀려도 붙었을 수 있다). 지금 설치에는 지장이"
      say "     없지만 알아 두세요." ;;
    *)
      say "  · 빈 비밀번호 시험은 판정하지 않는다" ;;
  esac
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 검사 7 — 첨부 폴더에 **uid 1000 이 실제로 쓰는가**
#
#  이 설치에서 가장 조용한 결함이 여기 있다. 폴더가 있고 주인이 맞아도
#  시놀로지 ACL 이 남아 있으면 컨테이너가 못 쓴다. 배포 검사는 전부
#  통과하고 **사람이 글에 사진을 붙이는 순간** 처음 드러난다.
#
#  🔴 리다이렉션으로 시험하지 않는다. 쓰기가 막히면 ash 가 셸을 그 자리에서
#     끝내 뒤 줄이 아예 안 돌고 판정이 **빈 채로** 지나간다(2026-10-12 실측).
#     touch 는 외부 명령이라 실패해도 셸이 산다.
# ══════════════════════════════════════════════════════════════════════
probe_image() { # 쓰기 시험에 쓸 이미지 하나를 고른다
  local t
  for t in "$TAG_APP" "$KEEP_LEAVE" "$KEEP_IMP" "$KEEP_AS" "$KEEP_AUTH"; do
    if have_img "$t"; then printf '%s' "$t"; return 0; fi
  done
  printf ''
  return 1
}

uploads_check() {
  local mode acln img out left
  if [ ! -d "$BOARD_UPLOADS" ]; then
    bad "$BOARD_UPLOADS 가 없다 — 25-board-place.sh 를 돌리세요"
    cmd "sh /volume1/dss/setup/25-board-place.sh"
    return 1
  fi
  # 🔴 판정은 **숫자**(%u:%g)로 한다. DSM 에 uid 1000 짜리 계정이 있으면 %U 가
  #    그 이름으로 보여 「1000 이 아니다」로 잘못 읽는다. 이름은 보여 주기만 한다.
  mode=$(stat -c '%u:%g %a' "$BOARD_UPLOADS" 2>/dev/null)
  say "  · $BOARD_UPLOADS · $mode (숫자) · $(stat -c '%U:%G' "$BOARD_UPLOADS" 2>/dev/null) (이름)"
  case "$mode" in
    *" 750") ok "모드 750" ;;
    *) bad "모드가 750 이 아니다 ($mode)" ;;
  esac
  case "$mode" in
    "1000:1000 "*) ok "주인이 uid 1000 (node)이다" ;;
    *) bad "주인이 uid 1000 이 아니다 ($mode) — 컨테이너가 못 쓴다" ;;
  esac
  acln=$("$ACLT" -get "$BOARD_UPLOADS" 2>&1 | grep -cE ':(allow|deny):')
  [ "${acln:-1}" = 0 ] && ok "ACL 항목 0개 (걷혔다)" \
    || bad "ACL 항목이 ${acln}개 남아 있다 — 주인이 맞아도 못 쓴다"

  img=$(probe_image)
  if [ -z "$img" ]; then
    bad "쓰기 시험에 쓸 이미지를 하나도 찾지 못했다 — **시험을 못 했다**"
    return 1
  fi
  say "  · 쓰기 시험에 쓴 이미지: $img"
  out=$("$DOCKER" run --rm --network none -u 1000:1000 \
        -v "$BOARD_UPLOADS:$BOARD_MNT" --entrypoint sh "$img" -c '
          id
          if touch /data/uploads/.dss-write-test 2>/dev/null; then
            echo "PROBE WRITE_OK"
            rm -f /data/uploads/.dss-write-test 2>/dev/null
          else
            echo "PROBE WRITE_FAIL"
          fi' 2>&1)
  printf '%s\n' "$out" | grep -E '^(uid=|PROBE )' | sed 's/^/      /'
  case "$out" in
    *"PROBE WRITE_OK"*)
      ok "🔴 uid 1000 이 $BOARD_UPLOADS 에 **실제로 썼다** (바로 지웠다)" ;;
    *"PROBE WRITE_FAIL"*)
      bad "🔴 uid 1000 이 못 쓴다 — 사람이 사진을 붙이는 순간 깨진다"
      say "      고치는 길:"
      cmd "sh /volume1/dss/setup/25-board-place.sh" ;;
    *)
      bad "쓰기 시험을 판정하지 못했다 — 아래가 그대로의 출력이다"
      printf '%s\n' "$out" | sed 's/^/      /' | head -6 ;;
  esac
  left=$(find "$BOARD_UPLOADS" -maxdepth 1 -name '.dss-write-test' 2>/dev/null | wc -l)
  [ "${left:-0}" = 0 ] && ok "시험 파일이 남지 않았다" \
    || bad "시험 파일이 남아 있다 — rm -f $BOARD_UPLOADS/.dss-write-test"
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 주소 넷이 글자 단위로 같은가 — 가장 자주 나는 고장
#
#  증상은 「로그인이 안 된다」 하나로 뭉뚱그려진다. 포털은 redirect_uri 를
#  **글자 단위로** 대조한다 — 와일드카드도 정규화도 없다.
#
#  🔴 개발 PC 의 .env.local 은 OIDC_ISSUER · OIDC_REDIRECT_URI 가 auto 다.
#     **컨테이너 안에서 auto 는 도커가 준 주소(172.x)를 집는다.**
# ══════════════════════════════════════════════════════════════════════
# 값을 그대로 찍지 않는다 — 숫자를 N 으로 가린 앞머리만 남긴다.
href_shape() { printf '%s' "$1" | cut -c1-48 | sed 's/[0-9]/N/g'; }

judge_redirect_uri() { # 1 라벨 2 원본값
  local label="$1" raw="$2" host base
  case "$raw" in
    auto|auto:*|AUTO|"")
      bad "$label · OIDC_REDIRECT_URI 가 auto(또는 빈 값)다 — 운영에는 도메인을 적는다"
      say "      auto 는 이 기계의 랜 주소를 집는다. **컨테이너 안에서는 172.x 다.**"
      return 1 ;;
  esac
  case "$raw" in
    *"$CB_PATH") base=${raw%"$CB_PATH"} ;;
    *)
      bad "$label · OIDC_REDIRECT_URI 가 $CB_PATH 로 끝나지 않는다"
      say "      꼴: $(href_shape "$raw")"
      return 1 ;;
  esac
  host=${base#*://}; host=${host%%/*}; host=${host%%:*}
  case "$host" in
    172.*|10.*|192.168.*)
      bad "$label · **밖에서 닿지 않는 사설 주소**다 — $(href_shape "$base") 꼴"
      return 1 ;;
  esac
  if [ "$raw" = "$BOARD_BASE$CB_PATH" ]; then
    ok "$label · OIDC_REDIRECT_URI 가 $BOARD_BASE$CB_PATH 다"
    return 0
  fi
  bad "$label · OIDC_REDIRECT_URI 가 기대값과 다르다 — $(href_shape "$raw") 꼴"
  say "      기대: $BOARD_BASE$CB_PATH"
  return 1
}

judge_issuer() { # 1 라벨 2 원본값
  local label="$1" raw="$2"
  case "$raw" in
    auto|auto:*|AUTO|"")
      bad "$label · OIDC_ISSUER 가 auto(또는 빈 값)다 — 운영에는 도메인을 적는다"
      return 1 ;;
    https://login.dss21.co.kr)
      ok "$label · OIDC_ISSUER 가 https://login.dss21.co.kr 다"
      return 0 ;;
    https://login.dss21.co.kr/*|https://login.dss21.co.kr/)
      bad "$label · OIDC_ISSUER 끝에 슬래시나 경로가 붙었다 — 글자 단위로 대조한다"
      return 1 ;;
    *)
      bad "$label · OIDC_ISSUER 가 https://login.dss21.co.kr 가 아니다 — $(href_shape "$raw") 꼴"
      return 1 ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════
#  【검사 2】 도구 이미지 **안**을 센다
#
#  🔴 태그도 지문도 「무엇이 든 판인지」를 말해 주지 않는다. Dockerfile 의
#     tools 스테이지는 COPY . . 가 아니라 **폴더를 골라 담는다** — 휴가에서
#     scripts 가 빠진 채로 구워졌던 자리다. **안을 세야 보인다.**
#
#  게시판의 도구 이미지가 들고 있어야 하는 것:
#    · drizzle/0000_blue_taskmaster.sql  (표 일곱을 만드는 **하나뿐인** 파일)
#    · drizzle/meta/_journal.json 의 tag 한 줄
#    · package.json 의 db:migrate
#    · 🔴 비상구 둘 — make:admin · cleanup:orphans
#      make:admin 은 포털이 막혔을 때 관리자를 지정하는 **유일한 길**이다.
#      비상구는 쓸 일이 생긴 뒤에 넣을 수 없다.
#    · drizzle.config.ts (drizzle-kit 이 스키마 자리를 찾는 곳)
# ══════════════════════════════════════════════════════════════════════
tools_image_check() {
  local out_sql n_sql out_j n_j out t
  if ! have_img "$TAG_TOOLS"; then
    bad "$TAG_TOOLS 가 NAS 에 없다 — 안을 셀 수 없다"
    cmd "bash $0 --preload"
    return 1
  fi
  say "  구운 때: $("$DOCKER" images "$TAG_TOOLS" --format '{{.CreatedAt}}' 2>/dev/null)"

  out_sql=$("$DOCKER" run --rm --entrypoint sh "$TAG_TOOLS" \
            -c 'ls -1 /app/drizzle/*.sql 2>/dev/null' 2>&1)
  n_sql=$(printf '%s\n' "$out_sql" | grep -c '\.sql$')
  printf '%s\n' "$out_sql" | sed 's/^/      /' | head -10
  if [ "$n_sql" = "$N_MIG_WANT" ]; then
    ok "마이그레이션 .sql 이 ${n_sql}개다"
  else
    bad "마이그레이션 .sql 이 ${N_MIG_WANT}개가 아니다 (${n_sql}개)"
    say "    → 늘었으면 이 스크립트가 모르는 판이다. 고치지 말고 알리세요."
  fi
  for t in $MIG_TAGS; do
    printf '%s\n' "$out_sql" | grep -q "/$t\.sql$" \
      && ok "$t.sql 있다" || bad "$t.sql 이 없다 — 다른 판이다"
  done

  out_j=$("$DOCKER" run --rm --entrypoint sh "$TAG_TOOLS" \
          -c 'cat /app/drizzle/meta/_journal.json 2>/dev/null' 2>&1)
  n_j=$(printf '%s\n' "$out_j" | grep -c '"tag"')
  [ "$n_j" = "$N_MIG_WANT" ] && ok "_journal.json 의 tag 가 ${n_j}줄이다" \
    || bad "_journal.json 의 tag 가 ${N_MIG_WANT}줄이 아니다 (${n_j}줄)"
  for t in $MIG_TAGS; do
    printf '%s\n' "$out_j" | grep -q "$t" \
      && ok "_journal 에 $t 가 있다" || bad "_journal 에 $t 가 없다"
  done

  # 🔴 한 번의 docker run 으로 다섯을 본다.
  out=$("$DOCKER" run --rm --entrypoint sh "$TAG_TOOLS" -c '
    grep -q "db:migrate"      /app/package.json && echo "MIGSCRIPT 1"  || echo "MIGSCRIPT 0"
    grep -q "make:admin"      /app/package.json && echo "ADMINSCRIPT 1" || echo "ADMINSCRIPT 0"
    grep -q "cleanup:orphans" /app/package.json && echo "ORPHANSCRIPT 1" || echo "ORPHANSCRIPT 0"
    [ -f /app/scripts/make-admin.ts ]     && echo "ADMINFILE 1"   || echo "ADMINFILE 0"
    [ -f /app/scripts/cleanup-orphans.ts ] && echo "ORPHANFILE 1" || echo "ORPHANFILE 0"
    [ -f /app/drizzle.config.ts ]         && echo "DRIZZLECFG 1"  || echo "DRIZZLECFG 0"
    [ -f /app/src/lib/env.ts ]            && echo "ENVTS 1"       || echo "ENVTS 0"
    ' 2>&1)
  printf '%s\n' "$out" | grep -E '^[A-Z]+ [01]$' | sed 's/^/      /'
  see_one() { # 1 표시 2 사람이 읽을 것 3 없을 때 할 말
    if printf '%s\n' "$out" | grep -qx "$1 1"; then
      ok "$2"
    else
      bad "$2 — **없다**"
      say "    → $3"
    fi
  }
  see_one MIGSCRIPT     "package.json 에 db:migrate 가 있다" \
    "🔴 표를 만들 수 없다. --init 이 「없는 스크립트」로 끝난다."
  see_one ADMINSCRIPT   "package.json 에 make:admin 이 있다" \
    "🔴 포털이 막히면 관리 화면에 들어갈 길이 하나도 없다."
  see_one ORPHANSCRIPT  "package.json 에 cleanup:orphans 가 있다" \
    "글에 못 붙은 사진을 치울 길이 없다."
  see_one ADMINFILE     "scripts/make-admin.ts 가 있다 (비상구)" \
    "🔴 tools 스테이지가 scripts 를 안 담았다. 다시 굽고 올리세요."
  see_one ORPHANFILE    "scripts/cleanup-orphans.ts 가 있다" \
    "같은 까닭이다 — scripts 가 빠졌다."
  see_one DRIZZLECFG    "drizzle.config.ts 가 있다" \
    "drizzle-kit 이 스키마 자리를 못 찾는다."
  see_one ENVTS         "src/lib/env.ts 가 있다 (DATABASE_URL 을 읽는 곳)" \
    "src 가 빠졌다 — 도구가 돌다 죽는다."
  return 0
}

# ── 표를 센다 — 「돌았다」가 아니라 「섰다」를 본다 ─────────────────────
mig_table()  { qb "select to_regclass('drizzle.__drizzle_migrations')"; }
mig_count()  { qb "select count(*) from drizzle.__drizzle_migrations"; }
tbl_count()  { qb "select count(*) from information_schema.tables where table_schema='public'"; }
tbl_has()    { qb "select count(*) from information_schema.tables where table_schema='public' and table_name='$1'"; }

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다
#     (아직 없는 사이트라 더욱 그렇다).
#
#  🔴 마이그레이션의 **지금 상태는 ✗ 로 세지 않는다**(1-ㅌ). --check 는
#     --init 보다 먼저 도는 것이 정상 차례라, 「표가 아직 없다」는 흠이 아니다.
#     대신 --go 가 시작 직전에 따로 세어 보고 막는다.
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)

run_checks() {
  local tag s rec f db code t
  local perm own v n miss

  # ── 1-ㄱ. 【검사 1】 이미지 tar 둘 ───────────────────────────────────
  step "1-ㄱ. 【검사 1】 이미지 tar 둘 (크기 · md5 · tar 안의 지문)"
  EXP_APP=$(tar_config_id   "$TAR_APP"   2>/dev/null) || EXP_APP=""
  EXP_TOOLS=$(tar_config_id "$TAR_TOOLS" 2>/dev/null) || EXP_TOOLS=""
  see_tar() { # 1 태그 2 tar 3 지문 4 바이트 5 md5
    local n m
    if [ ! -s "$2" ]; then
      bad "$1 의 tar 가 없다: $2"
      say "    → 개발 PC 에서 올리세요. 🔴 scp 에는 -O 를 붙입니다(DSM 에 sftp 가 없다)."
      return 1
    fi
    n=$(stat -c '%s' "$2" 2>/dev/null)
    [ "$n" = "$4" ] && ok "$1 · 바이트 $n" \
      || bad "$1 의 바이트가 $4 가 아니다 ($n) — 올리다 끊겼다"
    m=$(md5sum "$2" 2>/dev/null | awk '{print $1}')
    [ "$m" = "$5" ] && ok "$1 · md5 $m" \
      || bad "$1 의 md5 가 $5 가 아니다 (${m:-못 읽음}) — 파일이 상했다"
    [ -n "$3" ] && ok "$1 · 기대 지문 $(echo "$3" | cut -c1-19)…" \
      || bad "$1 의 tar 에서 manifest.json 을 읽지 못했다: $2"
  }
  see_tar "$TAG_APP"   "$TAR_APP"   "$EXP_APP"   "$SZ_APP"   "$MD5_APP"
  see_tar "$TAG_TOOLS" "$TAR_TOOLS" "$EXP_TOOLS" "$SZ_TOOLS" "$MD5_TOOLS"

  # ── 1-ㄴ. NAS 에 실린 이미지 ────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (게시판 둘 + 건드리지 않는 열)"
  say "  새로 서는 둘 — 지문까지 맞춘다:"
  for rec in "$TAG_APP|$EXP_APP" "$TAG_TOOLS|$EXP_TOOLS"; do
    tag=${rec%%|*}; t=${rec##*|}
    if have_img "$tag"; then
      if [ -n "$t" ] && ! verify_img "$tag" "$t"; then
        force_load_hint "$tag"
      fi
    else
      say "  · $tag 는 아직 NAS 에 없다 — --preload 가 싣는다"
    fi
  done
  say "  🔴 지문이 어긋나면 **혼자 고쳐지지 않는다.** 태그가 같으면 docker load 를"
  say "     그냥 부르는 것으로는 안 바뀐다 — 위에 찍힌 --force-load 를 쓰세요."
  say "  건드리지 않는 열 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for tag in "$KEEP_AUTH" "$KEEP_AS" "$KEEP_ASTOOLS" "$KEEP_METERS" \
             "$KEEP_METERSTOOLS" "$KEEP_IMP" "$KEEP_IMPTOOLS" "$KEEP_PO" \
             "$KEEP_LEAVE" "$KEEP_LEAVETOOLS"; do
    have_img "$tag" && ok "$tag 실려 있다 ($(img_id "$tag" | cut -c1-19)…)" \
      || bad "$tag 가 NAS 에 없다 — 🔴 앞선 배포가 되돌아갔거나 누가 지웠다"
  done

  # ── 1-ㄷ. 【검사 2】 도구 이미지 안 ──────────────────────────────────
  step "1-ㄷ. 【검사 2】 $TAG_TOOLS 안 — 마이그레이션 하나 · 비상구 둘"
  tools_image_check

  # ── 1-ㄹ. 【검사 3】 DB 와 롤 — 🔴 TCP 로 붙어 본다 ──────────────────
  step "1-ㄹ. 【검사 3】 DB $BOARD_DB · 롤 $BOARD_ROLE (🔴 TCP 로 실제로 붙는다)"
  if pg_up; then
    ok "dss-pg-app 이 떠 있다"
    [ "$(qpg "select 1 from pg_database where datname='$BOARD_DB'")" = 1 ] \
      && ok "DB $BOARD_DB 가 있다" \
      || bad "DB $BOARD_DB 가 없다 — 25-board-db.sh 를 먼저 돌리세요"
    [ "$(qpg "select 1 from pg_roles where rolname='$BOARD_ROLE'")" = 1 ] \
      && ok "롤 $BOARD_ROLE 이 있다" \
      || bad "롤 $BOARD_ROLE 이 없다 — 25-board-db.sh 를 먼저 돌리세요"
    v=$(qpg "select pg_get_userbyid(datdba) from pg_database where datname='$BOARD_DB'")
    [ "$v" = "$BOARD_ROLE" ] && ok "DB 의 주인이 $BOARD_ROLE 이다 (표를 만들 수 있다)" \
      || bad "DB 의 주인이 ${v:-?} 다 — $BOARD_ROLE 이 표를 못 만든다"
    v=$(qpg "select 1 from pg_authid where rolname='$BOARD_ROLE' and rolpassword is not null")
    [ "$v" = 1 ] && ok "롤에 비밀번호가 붙어 있다" \
      || bad "롤에 비밀번호가 없다 — 25-board-pw.sh 를 돌리세요"
    # 🔴 정렬이 다른 DB 와 같아야 글 목록 차례가 사이트마다 안 달라진다.
    v=$(qpg "select datcollate from pg_database where datname='$BOARD_DB'")
    n=$(qpg "select datcollate from pg_database where datname='dss_leave'")
    [ -n "$v" ] && [ "$v" = "$n" ] && ok "정렬이 dss_leave 와 같다 ($v)" \
      || say "    ⚠️ 정렬이 dss_leave 와 다르다 (게시판 ${v:-?} / 휴가 ${n:-?})"
  else
    bad "dss-pg-app 이 떠 있지 않다 — DB 를 하나도 볼 수 없다"
  fi
  tcp_db_check

  # ── 1-ㅁ. 【검사 4】 board.env ───────────────────────────────────────
  # 🔴 **값은 화면에 찍지 않는다.** 있나/없나와 판정만 남긴다.
  step "1-ㅁ. 【검사 4】 $BOARD_ENV (이름·모드·판정만. 값은 안 찍는다)"
  if [ -f "$BOARD_ENV" ]; then
    ok "board.env 가 제자리에 있다"
    perm=$(stat -c '%a' "$BOARD_ENV" 2>/dev/null)
    own=$(stat -c '%U:%G' "$BOARD_ENV" 2>/dev/null)
    [ "$perm" = 600 ] && ok "모드 600" \
      || bad "모드가 ${perm:-?} 다 (600 이어야 한다 — 남이 읽는다)"
    [ "$own" = "root:root" ] && ok "주인이 root:root 다" \
      || bad "주인이 ${own:-?} 다 (root:root 이어야 한다)"
    miss=""
    for t in $ENV_KEYS; do
      if env_has "$BOARD_ENV" "$t"; then
        # 🔴 같은 이름이 두 줄이면 **나중 것이 이긴다**(compose 가 그렇게 읽는다).
        #    그러면 사람이 눈으로 고친 앞 줄은 아무 일도 안 한다 — 조용히 틀린다.
        n=$(env_dups "$BOARD_ENV" "$t")
        if [ "${n:-0}" != 1 ]; then
          bad "$t 줄이 ${n}개다 — 나중 것이 이긴다. 하나만 남기세요"
          continue
        fi
        v=$(env_val "$BOARD_ENV" "$t")
        if [ -n "$v" ]; then ok "$t 줄이 하나고 값이 차 있다"
        else bad "$t 줄은 있는데 **값이 비었다**"; fi
      else
        bad "$t 가 없다"; miss="$miss $t"
      fi
    done
    [ -z "$miss" ] && ok "일곱 개가 다 있다" \
      || say "    → 없는 것:$miss  (점검표 3단계의 일곱 줄을 본으로 채운다)"
    for t in $ENV_FORBIDDEN; do
      env_has "$BOARD_ENV" "$t" \
        && bad "board.env 에 $t 가 **있다** — 지우세요" \
        || ok "board.env 에 $t 가 없다 (맞다)"
    done
    # 🔴 주소 넷 중 둘이 여기 있다. 나머지 둘은 포털에 있고 검사 8 이 본다.
    judge_issuer       board.env "$(env_val "$BOARD_ENV" OIDC_ISSUER)"
    judge_redirect_uri board.env "$(env_val "$BOARD_ENV" OIDC_REDIRECT_URI)"
    v=$(env_val "$BOARD_ENV" OIDC_CLIENT_ID)
    [ "$v" = "$CLIENT_ID" ] && ok "OIDC_CLIENT_ID 가 $CLIENT_ID 다" \
      || bad "OIDC_CLIENT_ID 가 $CLIENT_ID 가 아니다 (${v:-빔})"
    # 사내 주소가 https 다. 쿠키에 secure 가 안 붙으면 사내망을 지나는 동안
    # 세션 쿠키가 평문으로 흐를 수 있다.
    v=$(env_val "$BOARD_ENV" SESSION_COOKIE_SECURE)
    [ "$v" = true ] && ok "SESSION_COOKIE_SECURE 가 켜져 있다 (https 라 맞다)" \
      || say "    ⚠️ SESSION_COOKIE_SECURE 가 true 가 아니다 — https 사이트에서는 켜는 것이 맞다."
    # 포털 SSO 세션의 절대 만료 12시간을 넘기지 않는다(넘기면 앱이 12로 깎는다).
    v=$(env_val "$BOARD_ENV" SESSION_HOURS)
    case "$v" in
      12) ok "SESSION_HOURS 가 12 다" ;;
      *)  say "    ⚠️ SESSION_HOURS 가 ${v:-빔} 이다 — 12 를 넘기면 앱이 12로 깎는다." ;;
    esac
  else
    bad "board.env 가 없다: $BOARD_ENV"
    say "    → 🔴 **없는 env_file 하나면 docker compose 명령이 통째로 안 먹는다.**"
    say "      compose 의 app-board·tools-board 가 이 파일을 가리킨다."
    cmd "sh /volume1/dss/setup/25-board-place.sh"
  fi

  # ── 1-ㅂ. 【검사 5】 compose ─────────────────────────────────────────
  step "1-ㅂ. 【검사 5】 compose ($CF_EFF)"
  if compose_at "$CF_EFF" config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_at "$CF_EFF" config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  SVCS=$(compose_at "$CF_EFF" config --services 2>/dev/null)
  say "  새로 생기는 둘 (🔴 주석을 벗겼어야 보인다):"
  for s in "$BOARD_SVC" "$BOARD_TOOLS_SVC"; do
    echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
      || bad "서비스 목록에 $s 가 없다 — 주석으로 꺼져 있거나 파일이 옛것이다"
  done
  say "  🔴 건드리지 않는 열 (하나라도 없으면 남의 것이 섞인 것이다):"
  for s in app-auth app-as tools-as app-meters tools-meters \
           app-improvements tools-improvements app-po app-leave tools-leave; do
    echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
      || bad "서비스 목록에 $s 가 없다"
  done
  see_tag() { # 1 서비스 2 태그 3 사람이 읽을 이름
    svc_block "$CF_EFF" "$1" | grep -q "image: $2$" \
      && ok "$1 가 $2 를 가리킨다 ($3)" \
      || bad "$1 의 태그가 $2 가 아니다 ($3) — 지금 값: $(svc_image "$CF_EFF" "$1")"
  }
  say "  새로 생기는 둘의 태그:"
  see_tag "$BOARD_SVC"       "$TAG_APP"   "게시판"
  see_tag "$BOARD_TOOLS_SVC" "$TAG_TOOLS" "게시판 도구"
  say "  🔴 건드리지 않는 열의 태그 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-auth           "$KEEP_AUTH"        "포털 · 그대로"
  see_tag app-as             "$KEEP_AS"          "A/S · 그대로"
  see_tag tools-as           "$KEEP_ASTOOLS"     "A/S 도구 · 그대로"
  see_tag app-meters         "$KEEP_METERS"      "계측기 · 그대로"
  see_tag tools-meters       "$KEEP_METERSTOOLS" "계측기 도구 · 그대로"
  see_tag app-improvements   "$KEEP_IMP"         "개선요청 · 그대로"
  see_tag tools-improvements "$KEEP_IMPTOOLS"    "개선요청 도구 · 그대로"
  see_tag app-po             "$KEEP_PO"          "PO · 그대로"
  see_tag app-leave          "$KEEP_LEAVE"       "휴가 · 그대로"
  see_tag tools-leave        "$KEEP_LEAVETOOLS"  "휴가 도구 · 그대로"
  # 포트 — 한 글자가 틀리면 리버스 프록시가 502 를 계속 낸다.
  svc_block "$CF_EFF" "$BOARD_SVC" | grep -q "127.0.0.1:$BOARD_PORT:$BOARD_INNER" \
    && ok "$BOARD_SVC 가 127.0.0.1:$BOARD_PORT 으로만 열린다" \
    || bad "$BOARD_SVC 의 포트가 127.0.0.1:$BOARD_PORT:$BOARD_INNER 가 아니다"
  # 설정 파일을 가리키는가
  svc_block "$CF_EFF" "$BOARD_SVC" | grep -q './env/board.env' \
    && ok "$BOARD_SVC 가 ./env/board.env 를 읽는다" \
    || bad "$BOARD_SVC 가 ./env/board.env 를 안 읽는다"
  # 도구는 평소에 뜨지 않아야 한다
  svc_block "$CF_EFF" "$BOARD_TOOLS_SVC" | grep -q 'profiles:.*tools' \
    && ok "$BOARD_TOOLS_SVC 에 profiles: [tools] 가 있다 (up -d 로 안 뜬다)" \
    || bad "$BOARD_TOOLS_SVC 에 profiles 가 없다 — 🔴 상시 서비스가 하나 늘어난다"
  # 🔴 DATABASE_URL 이 없으면 도구가 「.env.local 파일을 확인하세요」로 죽는다.
  #    그 문장이 개발 PC 용이라, NAS 에서 그 줄만 보면 없는 파일을 찾아 헤맨다.
  svc_block "$CF_EFF" "$BOARD_TOOLS_SVC" | grep -q 'DATABASE_URL:' \
    && ok "$BOARD_TOOLS_SVC 에 DATABASE_URL 이 있다" \
    || bad "🔴 $BOARD_TOOLS_SVC 에 DATABASE_URL 이 없다 — --init 이 곧장 죽는다"
  svc_block "$CF_EFF" "$BOARD_SVC" | grep -q 'DATABASE_URL:' \
    && ok "$BOARD_SVC 에 DATABASE_URL 이 있다" \
    || bad "🔴 $BOARD_SVC 에 DATABASE_URL 이 없다 — 앱이 뜨자마자 죽는다"
  # 🔴 볼륨 — 이 설치에서 가장 중요한 한 줄이다. 빠지면 올린 사진이 컨테이너 안
  #    임시 디스크에 쌓이고, **다음 배포에서 컨테이너를 새로 만드는 순간 전부
  #    사라진다.** 화면에는 첨부가 있는데 바이트만 없는 상태가 된다.
  for s in "$BOARD_SVC" "$BOARD_TOOLS_SVC"; do
    svc_block "$CF_EFF" "$s" | grep -q "$BOARD_UPLOADS:$BOARD_MNT" \
      && ok "$s 에 $BOARD_UPLOADS:$BOARD_MNT 볼륨이 있다" \
      || bad "🔴 $s 에 업로드 볼륨이 없다 — 올린 사진이 컨테이너와 함께 사라진다"
    svc_block "$CF_EFF" "$s" | grep -q "STORAGE_ROOT: $BOARD_MNT" \
      && ok "$s 의 STORAGE_ROOT 가 $BOARD_MNT 다" \
      || bad "$s 의 STORAGE_ROOT 가 $BOARD_MNT 가 아니다 — 볼륨과 짝이 안 맞는다"
  done
  # 🔴 db-app 은 건드리지 않았어야 한다. 거기에 줄을 더하면 설정 지문이 바뀌어
  #    인자 없는 up -d 가 **DB 컨테이너를 다시 만든다.**
  svc_block "$CF_EFF" db-app | grep -q 'BOARD_APP_PASSWORD' \
    && bad "🔴 db-app 에 BOARD_APP_PASSWORD 가 들어갔다 — DB 가 다시 만들어진다" \
    || ok "db-app 에 더해진 줄이 없다 (맞다 — 롤과 DB 는 손으로 만들었다)"

  # ── 1-ㅅ. 【검사 6】 🔴 첨부 폴더 — 쓸 수 있는가 ─────────────────────
  step "1-ㅅ. 【검사 6】 🔴 첨부 폴더 $BOARD_UPLOADS — **쓸 수 있는가**"
  say "  「있는가」가 아니라 「제 일을 하는가」를 본다. 이 결함은 배포 때 안 보이고"
  say "  **사람이 글에 사진을 붙이는 순간** 처음 드러난다."
  uploads_check

  # ── 1-ㅇ. 【검사 7】 포털 등록 ───────────────────────────────────────
  step "1-ㅇ. 【검사 7】 포털(clients)에 $CLIENT_ID 가 등록돼 있는가"
  if running dss-pg-auth; then
    ROW=$(qa "select is_active, requires_grant, launcher_url, length(client_secret_hash), length(launcher_icon), upper(to_hex(ascii(launcher_icon))) from clients where client_id='$CLIENT_ID'")
    if [ -z "$ROW" ]; then
      bad "clients 에 $CLIENT_ID 가 **없다** — 로그인이 아예 안 된다"
      cmd "sh /volume1/dss/setup/25-board-client.sh"
    else
      ok "clients 에 $CLIENT_ID 가 있다"
      IFS='|' read -r C_ACT C_GRANT C_URL C_HLEN C_ILEN C_ICODE <<EOF
$ROW
EOF
      [ "$C_ACT" = t ] && ok "is_active 가 참이다" \
        || bad "is_active 가 참이 아니다 (${C_ACT:-?}) — 포털이 거절한다"
      # 🔴 PO 와 다르다. 게시판은 전 직원 공개라 명단(user_client_grants)이 없다.
      if [ "$C_GRANT" = f ]; then
        ok "🔴 requires_grant 가 거짓이다 — 전 직원이 바로 쓴다 (맞다)"
      else
        bad "🔴 requires_grant 가 참이다 (${C_GRANT:-?}) — 명단에 없는 사람이 다 막힌다"
        say "      게시판은 전 직원 공개다(개선요청·휴가와 같다). PO 만 참이다."
      fi
      [ "$C_URL" = "$BOARD_BASE/" ] && ok "launcher_url 이 $BOARD_BASE/ 다" \
        || bad "launcher_url 이 $BOARD_BASE/ 가 아니다 (${C_URL:-?})"
      [ "$C_HLEN" = 64 ] && ok "client_secret_hash 가 64글자다 (sha256 hex)" \
        || bad "client_secret_hash 가 64글자가 아니다 (${C_HLEN:-?}글자)"
      # 🔴 아이콘은 글자가 아니라 **코드값**으로 본다. 터미널 글꼴이 없으면
      #    네모로 보여서 눈으로는 깨진 것과 멀쩡한 것을 가릴 수 없다.
      if [ "$C_ILEN" = 1 ] && [ "$C_ICODE" = 1FAA7 ]; then
        ok "launcher_icon 이 U+1FAA7 한 글자다 (코드로 되읽었다)"
      else
        bad "launcher_icon 이 U+1FAA7 이 아니다 (글자수 ${C_ILEN:-?} · 코드 ${C_ICODE:-?})"
        say "      전송이나 터미널에서 깨진 것이다. 다시:"
        cmd "sh /volume1/dss/setup/25-board-client.sh"
      fi
      # redirect_uri 는 포털이 **글자 단위로** 대조한다. 한 글자만 달라도
      # 로그인 끝에 redirect_uri mismatch 로 돌아온다.
      v=$(qa "select 1 from clients where client_id='$CLIENT_ID' and '$BOARD_BASE$CB_PATH' = any(redirect_uris)")
      [ "$v" = 1 ] && ok "redirect_uris 에 $BOARD_BASE$CB_PATH 가 있다" \
        || bad "redirect_uris 에 그 주소가 없다 — 로그인이 끝에서 거절된다"
      v=$(qa "select 1 from clients where client_id='$CLIENT_ID' and backchannel_logout_uri = '$BOARD_BASE/api/auth/backchannel-logout'")
      [ "$v" = 1 ] && ok "backchannel_logout_uri 가 맞다" \
        || bad "backchannel_logout_uri 가 다르다 — 포털에서 로그아웃해도 안 끊긴다"
      v=$(qa "select 1 from clients where client_id='$CLIENT_ID' and 'MEMBER' = any(available_roles::text[]) and 'ADMIN' = any(available_roles::text[])")
      [ "$v" = 1 ] && ok "available_roles 에 MEMBER · ADMIN 이 있다" \
        || bad "available_roles 가 MEMBER · ADMIN 이 아니다"
    fi
  else
    bad "dss-pg-auth 가 떠 있지 않다 — 포털 등록을 볼 수 없다"
  fi

  # ── 1-ㅈ. 【검사 8】 바깥 주소 ───────────────────────────────────────
  # 🔴 502 는 흠이 아니다. 「프록시와 인증서는 제대로 걸렸는데 갈 곳(앱)이 아직
  #    없다」는 뜻이다 — 첫 설치 전에는 그것이 **정상**이다.
  step "1-ㅈ. 【검사 8】 바깥 주소 $BOARD_BASE (앱 전에는 502 가 정상)"
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$BOARD_BASE/" 2>/dev/null)
  case "$code" in
    502)
      ok "→ 502 · **앱이 뜨기 전이면 이것이 정상이다**"
      say "      뜻: DNS 도 DSM 리버스 프록시도 인증서도 제대로 걸렸다. 다만"
      say "      localhost:$BOARD_PORT 에 아직 아무도 없다. --go 뒤에는 307 이 된다." ;;
    2??|3??)
      ok "→ $code · 앱이 이미 대답하고 있다 (--go 를 이미 돌린 뒤다)" ;;
    000|"")
      bad "→ 대답이 없다 — DNS 나 DSM 리버스 프록시가 아직 없다"
      say "      점검표 5절(Cloudflare A 레코드 · 역방향 프록시)을 먼저." ;;
    404|503)
      bad "→ $code — 프록시 규칙이 다른 곳을 가리킨다(대상이 localhost:$BOARD_PORT 인가)" ;;
    *)
      bad "→ $code — 뜻을 모르겠다. 프록시 규칙과 인증서를 보세요" ;;
  esac
  say "  🔴 건드리지 않는 여섯 — 지금도 그대로여야 한다:"
  for t in login as meters improvements po leave; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$t.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$t.dss21.co.kr → $code" ;;
      *)       bad "🔴 https://$t.dss21.co.kr → ${code:-없음} — 건드리지 않은 쪽이 흔들렸다" ;;
    esac
  done

  # ── 1-ㅊ. 【검사 9】 백업 여섯 · 디스크 · 지금 도는 것 ───────────────
  # 🔴 이 검사가 「야간 백업 스크립트를 고쳐 NAS 에 올렸고 실제로 돌았는가」를
  #    드러낸다. 개선요청은 그 셋 중 하나(올리기)를 빠뜨려 11일을 잃었다.
  step "1-ㅊ. 【검사 9】 오늘($TODAY) 백업이 **여섯**인가 · 디스크 · 도는 것"
  n=0
  for db in dss_auth dss_meters dss_as dss_improvements dss_leave dss_board; do
    f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
      n=$((n + 1))
    else
      bad "오늘($TODAY) 뜬 $db 백업이 없다"
    fi
  done
  if [ "$n" = 6 ]; then
    ok "🔴 오늘 백업이 여섯이다 — 고친 야간 백업이 NAS 에서 **실제로 돌았다**"
  else
    bad "🔴 오늘 백업이 ${n}개뿐이다 (여섯이어야 한다)"
    say "    → dss_board 가 빠졌다면 고친 backup-nightly.sh 를 **NAS 에 올리지**"
    say "      않았거나, 올리고 한 번도 안 돌린 것이다. 올린 뒤 손으로 한 번:"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    say "      종료 코드 0 이고 ✓ dss_board 줄이 찍혀야 한다."
    say "    🔴 이 백업이 --init 의 되돌릴 자리다. 없으면 --init 이 멈춘다."
  fi
  # 백업 폴더 목록에 게시판 첨부가 들어갔는지도 본다 (DB 와 따로다).
  if [ -d "$BKD/files/board-uploads" ]; then
    ok "백업에 files/board-uploads 가 있다 ($(find "$BKD/files/board-uploads" -type f | wc -l)개)"
  else
    say "    ⚠️ 백업에 files/board-uploads 가 아직 없다 — 올린 사진이 하나도 없으면"
    say "       rsync 가 빈 폴더만 만든다. 야간 백업을 한 번 돌리면 생긴다."
  fi
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  # tar 둘이 약 297MB, 실은 이미지가 또 그만큼, 덤프가 더 든다.
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (tar 둘 약 297MB + 실은 이미지 + 덤프)"
  fi
  if pg_up && running dss-pg-auth; then
    ok "DB 둘 다 떠 있다 (이 설치에서 DB 컨테이너는 멈추지 않는다)"
  else
    bad "DB 컨테이너가 떠 있지 않다"
  fi
  for t in dss-auth dss-as dss-meters dss-improvements dss-po dss-leave; do
    running "$t" && ok "$t 가 돌고 있다" \
      || bad "$t 가 안 돌고 있다 — 이 설치는 그것을 건드리지 않는다"
  done
  if running "$BOARD_CNAME"; then
    say "  · $BOARD_CNAME 이 이미 돌고 있다 — --go 를 이미 돌린 뒤다"
  else
    say "  · $BOARD_CNAME 은 아직 없다 (맞다 — --go 가 띄운다)"
  fi

  # ── 1-ㅋ. 표의 지금 상태 (🔴 ✗ 로 세지 않는다) ──────────────────────
  step "1-ㅋ. 표의 지금 상태 (읽기만 · ✗ 로 세지 않는다)"
  say "  🔴 --check 는 --init 보다 **먼저** 도는 것이 정상 차례다. 그래서 여기서"
  say "     「아직 없다」가 나오는 것은 흠이 아니다 — 무엇을 할 차례인지만 알린다."
  show_db_state hint
}

# 지금 DB 가 어디까지 와 있는지 — 여러 곳에서 부른다.
show_db_state() { # [hint]
  if ! pg_up; then
    say "  · dss-pg-app 이 떠 있지 않아 못 봤다"
    return 0
  fi
  if [ -z "$(mig_table)" ]; then
    say "  · drizzle.__drizzle_migrations 가 아직 없다 → **--init 을 아직 안 돌렸다**"
    say "    🔴 이대로 앱을 띄우면 첫 화면이 42P01 로 죽는다. DB 가 먼저다."
    if [ "${1:-}" = hint ]; then
      say "    다음:"
      cmd "bash $0 --init"
    fi
    return 0
  fi
  say "  · 적용된 마이그레이션: $(mig_count)줄 (기대 $N_MIG_WANT)"
  say "  · public 스키마의 표: $(tbl_count)개 (기대 $N_TABLE_WANT)"
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  compose 갈아 끼우기
#
#  🔴 보통은 할 일이 없다. 게시판의 compose 는 25-board-place.sh 가 이미
#     제자리에 놓았다. 그래도 남겨 둔 것은, incoming 에 새 파일이 남아 있는
#     채로 여기까지 오는 일이 실제로 있기 때문이다.
#  🔴 --check 는 **갈아 끼우지 않는다.** 대신 incoming 의 그 파일을 들여다본다.
# ══════════════════════════════════════════════════════════════════════
compose_incoming() {
  local e MISS
  [ -s "$INCOMING" ] || return 0
  if cmp -s "$INCOMING" "$CF"; then
    say "  · incoming 의 compose 가 지금 것과 같다 — 할 일이 없다"
    return 0
  fi
  step "새 compose 를 먼저 시험한다 (바꾸기 전에)"
  MISS=""
  for e in $(sed '/^[[:space:]]*#/d' "$INCOMING" | grep -oE '\./env/[A-Za-z0-9_.-]+\.env' | sort -u); do
    [ -f "$D/deploy/${e#./}" ] || MISS="$MISS ${e#./}"
  done
  if [ -n "$MISS" ]; then
    bad "새 compose 가 **없는 설정 파일**을 가리킨다:$MISS"
    say "    → 하나만 없어도 docker compose 가 통째로 실패한다."
    return 1
  fi
  if compose_at "$INCOMING" config --quiet >/dev/null 2>&1; then
    ok "새 compose 문법 통과"
  else
    bad "새 compose 에 문법 오류가 있다"
    compose_at "$INCOMING" config --quiet 2>&1 | sed 's/^/    /' | head -10
    return 1
  fi
  if [ "$MODE" = go ]; then
    mkdir -p "$BKD"
    cp -p "$CF" "$BKD/docker-compose.nas.yml.$STAMP"
    cp "$INCOMING" "$CF"
    chown root:root "$CF"; chmod 644 "$CF"
    rm -f "$INCOMING"
    ok "compose 새것으로 (옛것: backups/docker-compose.nas.yml.$STAMP)"
    CF_EFF=$CF
  else
    CF_EFF=$INCOMING
    say "  🔵 --check 라서 **갈아 끼우지 않았다.** 아래 검사는 incoming 의 파일을 본 것이다:"
    say "     $INCOMING"
    say "     갈아 끼우는 것은 --go 가 한다."
  fi
  return 0
}

# ══ 되돌리기 ═══════════════════════════════════════════════════════════
if [ "$MODE" = rollback ]; then
  echo "DSS 게시판 첫 설치 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "  🔴 첫 설치라 「옛 태그로 내린다」가 없다. 되돌리기는 **없던 것으로**"
  say "     돌리는 일이다. 다른 여섯 사이트는 아무 상관이 없다."
  say
  say "  남기는 것 (지우지 않는다):"
  say "    · DB $BOARD_DB 와 롤 $BOARD_ROLE — 해가 없고, 다시 띄울 때 그대로 쓴다"
  say "    · 포털 clients 의 $CLIENT_ID — 지우지 말고 급하면 is_active 만 끈다"
  say "    · 마이그레이션 — 🔴 **되돌리지 않는다.** 표를 만들기만 했고"
  say "      이 DB 는 게시판 혼자 쓴다. 다른 사이트가 보는 자리가 아니다"
  say "    · 🔴 **첨부 폴더 $BOARD_UPLOADS — 건드리지 않는다.**"
  say "      사람이 올린 사진·첨부는 **되돌릴 수 없는 유일한 것**이다."
  say "      폴더를 지우면 그 바이트는 돌아오지 않는다."

  step "1. 지금 상태"
  if running "$BOARD_CNAME"; then
    say "  $BOARD_CNAME : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$BOARD_CNAME " || echo '?')"
  else
    say "  $BOARD_CNAME 은 돌고 있지 않다 — 이미 내려간 뒤다"
  fi
  show_db_state
  if [ -d "$BOARD_UPLOADS" ]; then
    say "  첨부 폴더: 파일 $(find "$BOARD_UPLOADS" -type f 2>/dev/null | wc -l)개 · $(du -sh "$BOARD_UPLOADS" 2>/dev/null | cut -f1)"
  fi

  step "2. 앱을 내린다 — 🔴 아래를 **한 줄씩** 친다"
  say "  (DSM 의 ash 는 긴 줄을 자른다. 줄 이어붙임도 깨졌다 — 한 줄씩.)"
  say "  🔴 인자 없는 down 을 부르지 않는다 — DB 까지 내려간다."
  cmd "cd /volume1/dss/deploy"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "C=\"compose -f \$F --env-file .env.nas\""
  cmd "\$D1 \$C stop $BOARD_SVC"
  cmd "\$D1 \$C rm -f $BOARD_SVC"
  script_file_hint "25-rollback"

  step "3. compose 를 백업본으로 되돌린다"
  say "  🔴 compose 에서 게시판 둘만 지우는 것이 아니라 **통째로 옛 파일로** 되돌린다."
  say "     손으로 지우면 들여쓰기 한 칸에 열 사이트가 함께 넘어간다."
  say "  있는 사본 (최근 다섯):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -5 | sed 's/^/      /' \
    || say "      (없다)"
  if [ -z "$(ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -1)" ]; then
    say "  ⚠️ 사본이 하나도 없다. 25-board-place.sh 도 이 스크립트도 옛 compose 를"
    say "     $BKD/docker-compose.nas.yml.<시각> 으로 남기므로,"
    say "     그것이 없다는 것은 compose 를 갈아 끼운 적이 없다는 뜻이다 —"
    say "     그러면 되돌릴 것도 없다. 게시판 둘만 손으로 지우려면 개발 PC 의"
    say "     저장소에서 옛 판을 받아 올리세요(손으로 지우지 마세요)."
  else
    say "  위에서 **되돌릴 것 하나를 고른 뒤**:"
    cmd "B=/volume1/dss/backups"
    cmd "ls -1t \$B/docker-compose.nas.yml.* | head -5"
    cmd "cp -p \$B/docker-compose.nas.yml.<고른것> \$F"
    cmd "chown root:root \$F && chmod 644 \$F"
    cmd "\$D1 \$C config --quiet"
  fi

  step "4. 이미지는 지우지 않는다"
  say "  $TAG_APP · $TAG_TOOLS 를 남겨 둔다 — 다시 띄울 때 그대로 쓴다."
  say "  디스크가 급할 때만(약 297MB):"
  cmd "\$D1 image rm $TAG_APP $TAG_TOOLS"

  step "5. 주소"
  say "  $BOARD_BASE 는 다시 **502** 가 된다 — 그것이 맞다."
  say "  Cloudflare 레코드와 DSM 프록시 규칙은 남겨 두세요. 다시 띄울 때 씁니다."
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit 0
fi

# ══ 여기부터 check · preload · force-load · init · go ══════════════════
echo "DSS 사내 게시판 **첫 설치** · $(date '+%F %T')"
echo "  🔴 새로 서는 것 둘:  $TAG_APP · $TAG_TOOLS"
echo "  🔴 멈추는 것은 **없다** — 일곱째 사이트를 하나 더 띄우는 일이다."
echo "  · 주소 $BOARD_BASE → 127.0.0.1:$BOARD_PORT"
echo "  · 첨부 $BOARD_UPLOADS → 컨테이너 $BOARD_MNT"
echo "  · 건드리지 않는 열 — $KEEP_AUTH · $KEEP_AS · $KEEP_ASTOOLS"
echo "    · $KEEP_METERS · $KEEP_METERSTOOLS · $KEEP_IMP"
echo "    · $KEEP_IMPTOOLS · $KEEP_PO · $KEEP_LEAVE · $KEEP_LEAVETOOLS"
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**" ;;
  preload)    echo "  🔵 --preload — 이미지 둘을 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  init)       echo "  🔴 --init — 표 일곱을 만든다. **DB 가 바뀐다.**" ;;
  go)         echo "  🔴 --go — app-board 를 띄운다. 다른 여섯은 안 멈춘다."
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(백업 · 주소)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
#    이미지를 싣는 것은 **아무것도 안 멈춘다.**
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "이미지 tar 둘 · 지문"
  EXP_APP=$(tar_config_id   "$TAR_APP"   2>/dev/null) || EXP_APP=""
  EXP_TOOLS=$(tar_config_id "$TAR_TOOLS" 2>/dev/null) || EXP_TOOLS=""
  for rec in "$TAG_APP|$TAR_APP|$EXP_APP|$SZ_APP|$MD5_APP" \
             "$TAG_TOOLS|$TAR_TOOLS|$EXP_TOOLS|$SZ_TOOLS|$MD5_TOOLS"; do
    IFS='|' read -r tag tarf exp sz md5 <<EOF
$rec
EOF
    if [ ! -s "$tarf" ]; then bad "$tag 의 tar 가 없다: $tarf"; continue; fi
    n=$(stat -c '%s' "$tarf" 2>/dev/null)
    if [ "$n" != "$sz" ]; then
      bad "$tag 의 바이트가 $sz 가 아니다 ($n) — 올리다 끊겼다. 싣지 않는다"
      continue
    fi
    m=$(md5sum "$tarf" 2>/dev/null | awk '{print $1}')
    if [ "$m" != "$md5" ]; then
      bad "$tag 의 md5 가 $md5 가 아니다 (${m:-못 읽음}) — 파일이 상했다. 싣지 않는다"
      continue
    fi
    ok "$tag · 바이트 $n · md5 맞음"
    if [ -z "$exp" ]; then bad "$tag 의 tar 에서 manifest.json 을 읽지 못했다"; continue; fi
    bring_img "$tag" "$tarf" "$exp"
  done

  # 🔴 실어 놓고 **안을 본다.** 태그와 지문이 맞아도 「무엇이 든 판인지」는
  #    사람이 읽을 수 있는 증거로 한 번 더 남긴다.
  step "【검사 2】 $TAG_TOOLS 안 — 마이그레이션 하나 · 비상구 둘"
  tools_image_check
  if have_img "$TAG_APP"; then
    step "$TAG_APP — 구운 때와 안의 모양"
    say "  구운 때: $("$DOCKER" images "$TAG_APP" --format '{{.CreatedAt}}' 2>/dev/null)"
    OUTA=$("$DOCKER" run --rm --entrypoint sh "$TAG_APP" -c '
      [ -f /app/server.js ] && echo "SERVER 1" || echo "SERVER 0"
      [ -d /app/.next/static ] && echo "STATIC 1" || echo "STATIC 0"
      echo "PORT $(printenv PORT)"
      echo "ROOT $(printenv STORAGE_ROOT)"' 2>&1)
    printf '%s\n' "$OUTA" | grep -E '^[A-Z]+ ' | sed 's/^/      /'
    printf '%s\n' "$OUTA" | grep -qx "SERVER 1" && ok "server.js 가 있다 (standalone 빌드)" \
      || bad "server.js 가 없다 — 앱 이미지가 아니다(도구를 앱으로 구웠나)"
    printf '%s\n' "$OUTA" | grep -qx "PORT $BOARD_INNER" && ok "이미지가 PORT=$BOARD_INNER 를 들고 있다" \
      || bad "이미지의 PORT 가 $BOARD_INNER 가 아니다"
  fi

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 멈추지 않았다**"
  if [ "$FAIL" != 0 ] && [ "$FORCE_LOAD" != 1 ]; then
    echo "  🔴 지문이 어긋난 것이 있으면 **같은 태그로 다시 구운 것**이다:"
    echo "       bash $0 --preload --force-load"
  fi
  echo "  🔵 나머지 항목은 안 봤다. 이어서: bash $0        (읽기만)"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ --init — 🔴 첫 설치의 핵심. 여기서만 DB 가 바뀐다 ═════════════════
#
# 🔴 표 일곱이 서야 첫 화면이 뜬다. 없으면 42P01 로 죽는다.
# 🔴 다시 돌려도 안전하다 — db:migrate 는 이미 적용된 것을 건너뛴다
#    (drizzle 기록을 본다). 그래서 중간에 막혔을 때 그냥 다시 부르면 된다.
# 🔴 seed:dev 는 **절대 부르지 않는다** — 가짜 글을 넣는 개발 전용이다.
#    (board.env 에 SEED_DEV_ENABLED 를 넣지 않는 것과 같은 까닭이다.)
if [ "$MODE" = init ]; then
  step "--init · 여기서만 DB 가 바뀐다"
  say "  하는 일: db:migrate 하나. 표 일곱이 선다."
  say "  🔴 다시 돌려도 안전하다. 이미 있는 것은 건너뛴다."
  say "  🔵 휴가의 seed:ranks 같은 **채워 넣기는 없다.** 게시판은 빈 표로 시작하고"
  say "     첫 사람이 로그인하는 순간 web_users 에 행이 생긴다."

  # ── 적용 전 — 꼭 필요한 것만 본다 (전체 검사는 --check 가 한다) ──────
  step "1. 적용 전 확인"
  if ! pg_up; then
    bad "dss-pg-app 이 떠 있지 않다"
    stop "DB 가 없습니다. **아무것도 바꾸지 않았습니다.**"
  fi
  ok "dss-pg-app 이 떠 있다"
  [ "$(qpg "select 1 from pg_database where datname='$BOARD_DB'")" = 1 ] \
    && ok "DB $BOARD_DB 가 있다" || bad "DB $BOARD_DB 가 없다"
  tcp_db_check
  if ! have_img "$TAG_TOOLS"; then
    bad "$TAG_TOOLS 가 NAS 에 없다"
    say "    → 먼저:"
    cmd "bash $0 --preload"
  fi
  tools_image_check
  if ! compose_at "$CF" config --services 2>/dev/null | grep -qx "$BOARD_TOOLS_SVC"; then
    bad "지금 쓰는 compose 에 $BOARD_TOOLS_SVC 가 없다"
    say "    → compose 의 주석을 안 벗겼거나 제자리에 없다. 먼저 놓으세요:"
    cmd "sh /volume1/dss/setup/25-board-place.sh"
    stop "도구를 부를 수 없습니다. **아무것도 바꾸지 않았습니다.**"
  fi
  ok "compose 에 $BOARD_TOOLS_SVC 가 있다"

  # 🔴 백업을 **작업 직전에 다시** 찾는다. --check 에서 봤다는 것으로는
  #    부족하다 — 그 뒤에 지워졌을 수 있고, 무엇보다 --check 를 안 돌리고
  #    바로 여기로 올 수 있다.
  step "2. 🔴 오늘 백업을 **지금 다시** 찾는다"
  BK=$(ls -1t "$BKD/db/${BOARD_DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
  if [ -n "$BK" ] && [ -s "$BK" ]; then
    ok "오늘 백업 — $(basename "$BK") ($(du -h "$BK" | cut -f1))"
  else
    say "  🔴 오늘($TODAY) 뜬 $BOARD_DB 백업을 **지금 찾지 못했습니다.**"
    say "     먼저 이것부터 (종료 코드 0 이어야 합니다):"
    cmd "bash $D/jobs/backup-nightly.sh"
    say "     ✓ dss_board 줄이 찍혀야 합니다. 안 찍히면 고친 backup-nightly.sh"
    say "     를 NAS 에 아직 안 올린 것입니다."
    stop "백업 없이 DB 를 바꾸지 않습니다. **DB 는 그대로입니다.**"
  fi

  step "3. 지금 DB 상태"
  show_db_state
  if [ "$FAIL" != 0 ]; then
    stop "위 ✗ 를 먼저 해결해야 합니다. **DB 는 그대로입니다.**"
  fi

  MIG_BEFORE=$(mig_count); MIG_BEFORE=${MIG_BEFORE:-0}
  TBL_BEFORE=$(tbl_count); TBL_BEFORE=${TBL_BEFORE:-0}
  say
  say "  🔴 이제 DB 를 바꿉니다. 그만두려면 **20초 안에 Ctrl+C**."
  say "     지금 Ctrl+C 하면 DB 도 앱도 손대지 않은 채로 남습니다."
  sleep 20

  # ── 4. 표를 만든다 ──────────────────────────────────────────────────
  step "4. db:migrate — 표 일곱을 만든다"
  "${COMPOSE[@]}" run --rm "$BOARD_TOOLS_SVC" npm run db:migrate 2>&1 | sed 's/^/  /'
  rc=${PIPESTATUS[0]}
  if [ "$rc" = 0 ]; then
    ok "db:migrate 끝 (종료 코드 0)"
  else
    bad "db:migrate 실패 (종료 코드 $rc)"
    say "    🔴 「.env.local 파일을 확인하세요」가 보이면 그 파일이 아니라"
    say "       compose 의 $BOARD_TOOLS_SVC 에 DATABASE_URL 이 없는 것입니다."
    stop "표가 다 만들어지지 않았습니다. 위 오류를 보세요."
  fi

  # ── 5. SQL 로 직접 센다 ─────────────────────────────────────────────
  # 🔴 스크립트가 「했다」고 말하는 것과 DB 에 「섰다」는 다른 일이다.
  step "5. 🔴 SQL 로 직접 센다 (「돌았다」가 아니라 「섰다」를 본다)"
  MIG_AFTER=$(mig_count)
  TBL_AFTER=$(tbl_count)
  [ "${MIG_AFTER:-0}" = "$N_MIG_WANT" ] \
    && ok "마이그레이션 기록 ${MIG_AFTER}줄 (전 ${MIG_BEFORE}줄)" \
    || bad "마이그레이션이 ${N_MIG_WANT}줄이 아니다 (${MIG_AFTER:-?})"
  [ "${TBL_AFTER:-0}" -ge "$N_TABLE_WANT" ] \
    && ok "public 스키마의 표 ${TBL_AFTER}개 (전 ${TBL_BEFORE}개 · 기대 $N_TABLE_WANT 이상)" \
    || bad "표가 ${TBL_AFTER:-?}개뿐이다 (기대 $N_TABLE_WANT)"
  # 🔴 개수만으로는 부족하다. **이름을 하나씩** 센다 — 첫 화면이 보는 표가
  #    web_posts 이고, 그것 하나가 없으면 42P01 로 죽는다.
  for t in $BOARD_TABLES; do
    [ "$(tbl_has "$t")" = 1 ] && ok "표 $t 가 섰다" || bad "표 $t 가 없다"
  done
  say "  만들어진 표:"
  qb "select table_name from information_schema.tables where table_schema='public' order by 1" \
    | sed 's/^/    /'

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL"
  echo "  🔴 DB 를 바꿨습니다. 앱은 **아직 안 떴습니다.**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  if [ "$FAIL" != 0 ]; then
    echo
    echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
    echo "🔵 db:migrate 는 **다시 돌려도 안전합니다**:"
    echo "     bash $0 --init"
    exit "$FAIL"
  fi
  echo
  echo "✅ 이어서 앱을 띄웁니다 (다른 여섯은 안 멈춥니다):"
  echo "     bash $0 --go"
  exit 0
fi

# ══ 1. 먼저 볼 것 (check · go 가 같이 지난다) ══════════════════════════
#
# 🔴 규칙 하나: **앱을 띄우기 전에 볼 것을 다 보고, 어긋나면 아무것도 하지
#    않은 채로 멈춘다.** 여기서 끝나면 아무 일도 일어나지 않는다.
step "1. 점검표를 기계로 옮긴 것 (아직 아무것도 안 바꿨다)"
compose_incoming || stop "compose 를 바꾸지 않았습니다. 아무것도 안 띄웠습니다."
run_checks

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  if [ "$FAIL" = 0 ]; then
    if ! have_img "$TAG_APP" || ! have_img "$TAG_TOOLS"; then
      echo "  ✅ 이어서 (아무것도 안 멈춥니다):  bash $0 --preload"
    elif [ -z "$(mig_table)" ]; then
      echo "  ✅ 이어서 (🔴 DB 가 바뀝니다):     bash $0 --init"
    elif ! running "$BOARD_CNAME"; then
      echo "  ✅ 이어서 (앱을 띄웁니다):         bash $0 --go"
    else
      echo "  ✅ 다 됐습니다. 눈으로 확인할 차례입니다 (점검표 7절)."
    fi
  else
    echo "  ✗ 위 ✗ 를 먼저 해결하세요. Claude 에게 알려 주세요."
  fi
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ --go ═══════════════════════════════════════════════════════════════
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 띄우지 않았습니다.**"

# ── 2. 🔴 --init 이 끝났는지 **여기서 막는다** ─────────────────────────
#
# 🔴 왜 막는가: 표가 없는 DB 에 앱이 뜨면 첫 화면이 42P01 로 죽는다.
#    「줄이 없다」가 아니라 「표가 없다」이므로 앱이 먼저 뜨면 안 된다.
#    --init 은 따로 부르는 명령이라 **빠뜨릴 수 있다.** 그래서 명령은
#    나눠 두고 순서만 기계가 지킨다.
step "2. 🔴 --init 이 끝났는지 다시 센다 (앱을 띄우기 전에)"
if [ -z "$(mig_table)" ]; then
  say "  ✗ drizzle.__drizzle_migrations 가 없다 — **--init 을 아직 안 돌렸다**"
  say "    먼저:"
  cmd "bash $0 --init"
  stop "표가 없는 DB 에 앱을 띄우지 않습니다. **아무것도 안 바꿨습니다.**"
fi
MIG_NOW=$(mig_count);  MIG_NOW=${MIG_NOW:-0}
if [ "$MIG_NOW" != "$N_MIG_WANT" ]; then
  say "  ✗ 마이그레이션이 ${MIG_NOW}줄이다 ($N_MIG_WANT 이어야 한다)"
  if [ "$MIG_NOW" -lt "$N_MIG_WANT" ]; then
    say "    덜 들어갔다. 다시 돌려도 안전하다:"
    cmd "bash $0 --init"
  else
    say "    🔴 기대보다 **많다.** 이 설치가 모르는 마이그레이션이 들어갔다 —"
    say "    남의 변경이 섞였을 수 있다. 고치지 말고 먼저 알리세요."
  fi
  stop "앱을 띄우지 않았습니다. **아무것도 안 바꿨습니다.**"
fi
ok "마이그레이션 ${MIG_NOW}줄 — --init 이 끝났다"
for t in $BOARD_TABLES; do
  if [ "$(tbl_has "$t")" != 1 ]; then
    say "  ✗ 표 $t 가 없다 — 이대로 띄우면 첫 화면이 42P01 로 죽는다"
    cmd "bash $0 --init"
    stop "앱을 띄우지 않았습니다. **아무것도 안 바꿨습니다.**"
  fi
done
ok "표 일곱이 다 서 있다"

# ── 3. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 띄웠다) ───────────
step "3. 이미지 확인 · 필요하면 싣기 (tar 의 Config ↔ NAS 의 .Id)"
EXP_APP=$(tar_config_id "$TAR_APP" 2>/dev/null) || EXP_APP=""
if [ -z "$EXP_APP" ]; then
  bad "$TAR_APP 에서 manifest.json 을 읽지 못했다"
  stop "이미지를 확인하지 못했습니다. **아무것도 안 띄웠습니다.**"
fi
bring_img "$TAG_APP" "$TAR_APP" "$EXP_APP" || FAIL2=1
if [ "${FAIL2:-0}" = 1 ]; then
  say
  say "  🔴 이미지가 기대한 것과 다릅니다. **아직 아무것도 띄우지 않았습니다.**"
  stop "띄우기를 시작하지 않았습니다."
fi

# ══ 4. app-board 를 띄운다 ═════════════════════════════════════════════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — compose 에 있는 것을 전부 띄우려
#    들고 DB 컨테이너까지 다시 만든다. --no-deps 로 **이름을 적은 하나만**.
# 🔴 이번에는 **멈추는 것이 없다.** 없던 서비스를 하나 더 세우는 일이다 —
#    다른 여섯 사이트는 그대로 대답한다.
step "4. $BOARD_SVC 를 띄운다  (🔴 멈추는 것은 없다 — 새로 하나 세운다)"
say "  그대로 도는 것: 포털 · A/S · 계측기 · 개선요청 · PO · 휴가 · DB 둘."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  띄운 시각: $STOP_AT"
"${COMPOSE[@]}" up -d --no-deps "$BOARD_SVC" 2>&1 | sed 's/^/    /'
wait_http "게시판" "$BOARD_PORT" / "$BOARD_CNAME"
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 띄운 시각 $STOP_AT → 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 5. 스모크 ══════════════════════════════════════════════════════════
step "5. 스모크 — 통로 · 🔴 로그인이 **어디로 보내는가** · 표 · 🔴 첨부 · 바깥 주소"

say "  5-ㄱ. 컨테이너가 살아 있는가"
if running "$BOARD_CNAME"; then
  ok "$BOARD_CNAME 이 돌고 있다"
  say "      $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$BOARD_CNAME " || true)"
else
  bad "$BOARD_CNAME 이 안 돌고 있다 — 떴다가 죽었다"
  cmd "$DOCKER logs --tail 50 $BOARD_CNAME"
fi

# ══════════════════════════════════════════════════════════════════════
#  🔴 5-ㄴ 이 이 설치에서 가장 값진 한 줄이다
#
#  /api/auth/login 은 그냥 열리는 통로가 아니다. 앱이
#    ① OIDC_ISSUER 로 **실제로 나가서** 설정(discovery)을 받아 오고
#    ② 거기서 받은 /authorize 주소에 ③ OIDC_REDIRECT_URI 를 붙여
#    ④ 307 로 되돌려 준다.
#  그러니 그 **Location 값 하나**가 주소 넷 중 둘(issuer · redirect_uri)과
#  컨테이너가 바깥으로 나갈 수 있는지(dss-edge 망)를 한꺼번에 증명한다.
#
#  🔴 설정이 덜 되면 오류가 아니라 /login?error=not-ready 로 **조용히** 샌다.
#     그래서 「200 이 왔다」로는 못 잡는다. **나오는 주소**를 본다.
# ══════════════════════════════════════════════════════════════════════
say "  5-ㄴ. 🔴 로그인 통로가 **어디로 보내는가** (통로가 아니라 나오는 것을 본다)"
LOGIN_LOC=$(curl -s -o /dev/null -w '%{redirect_url}' -m 20 \
            "http://127.0.0.1:$BOARD_PORT/api/auth/login" 2>/dev/null)
LOGIN_HEAD=${LOGIN_LOC%%[?]*}
say "      보내는 곳(물음표 앞까지): ${LOGIN_HEAD:-없음}"
case "$LOGIN_LOC" in
  "")
    bad "🔴 아무 데로도 안 보낸다 — 307 이 안 왔다"
    cmd "$DOCKER logs --tail 50 $BOARD_CNAME" ;;
  *"/login?error=not-ready"*)
    bad "🔴 not-ready 로 샜다 — OIDC 설정이 덜 됐거나 포털에 못 닿는다"
    say "      보는 곳 둘: board.env 의 OIDC_ 다섯 · compose 의 networks 에"
    say "      dss-edge 가 있는가(없으면 화면은 뜨는데 **로그인만** 안 된다)." ;;
  https://login.dss21.co.kr/*)
    ok "🔴 포털 https://login.dss21.co.kr 로 보낸다 — issuer 가 살아 있다"
    case "$LOGIN_LOC" in
      *172.*|*192.168.*)
        bad "🔴 주소에 사설 IP 가 섞였다 — board.env 에 auto 가 남은 것이다" ;;
    esac
    case "$LOGIN_LOC" in
      *"board.dss21.co.kr"*)
        ok "🔴 redirect_uri 가 board.dss21.co.kr 다 — 주소 넷이 맞는다" ;;
      *)
        bad "🔴 redirect_uri 에 board.dss21.co.kr 가 없다 — 끝에서 거절된다" ;;
    esac ;;
  *)
    bad "🔴 뜻밖의 곳으로 보낸다 — ${LOGIN_HEAD:-?}"
    say "      board.env 의 OIDC_ISSUER 를 보세요." ;;
esac

say "  5-ㄷ. 표 일곱이 서 있는가 (SQL 로 센다)"
for t in $BOARD_TABLES; do
  [ "$(tbl_has "$t")" = 1 ] && ok "표 $t" || bad "표 $t 가 없다"
done

# 🔴 도는 컨테이너 **안에서** 쓴다. --check 의 임시 컨테이너와 다른 것을 본다 —
#    compose 가 실제로 붙인 볼륨이 맞는지까지 드러난다.
say "  5-ㄹ. 🔴 도는 컨테이너가 $BOARD_MNT 에 **실제로 쓰나**"
say "      (임시 컨테이너가 아니라 **지금 사람을 받는 그 컨테이너**로 본다.)"
OUTW=$("$DOCKER" exec "$BOARD_CNAME" sh -c '
  if touch /data/uploads/.dss-write-test 2>/dev/null; then
    echo "LIVE WRITE_OK"
    rm -f /data/uploads/.dss-write-test 2>/dev/null
  else
    echo "LIVE WRITE_FAIL"
  fi' 2>&1)
case "$OUTW" in
  *"LIVE WRITE_OK"*)
    ok "🔴 도는 컨테이너가 썼다 (바로 지웠다) — 사진 붙이기가 열려 있다" ;;
  *"LIVE WRITE_FAIL"*)
    bad "🔴 도는 컨테이너가 못 쓴다 — **사람이 사진을 붙이는 순간 깨진다**"
    say "      화면은 멀쩡하게 뜹니다. 그래서 여기서 잡아야 합니다." ;;
  *)
    bad "판정하지 못했다 — 아래가 그대로의 출력이다"
    printf '%s\n' "$OUTW" | sed 's/^/      /' | head -6 ;;
esac
# 🔴 볼륨이 **진짜로 밖을 가리키는가.** 컨테이너 안에만 쓰이고 있으면 다음
#    배포에서 바이트가 통째로 사라진다 — 화면에는 첨부가 있는데 바이트만 없다.
"$DOCKER" exec "$BOARD_CNAME" sh -c 'touch /data/uploads/.dss-mount-test 2>/dev/null' >/dev/null 2>&1
if [ -f "$BOARD_UPLOADS/.dss-mount-test" ]; then
  ok "🔴 컨테이너가 쓴 것이 NAS 폴더에 **보인다** — 볼륨이 제대로 붙었다"
  rm -f "$BOARD_UPLOADS/.dss-mount-test"
else
  bad "🔴 컨테이너가 쓴 것이 NAS 폴더에 **안 보인다** — 볼륨이 안 붙었다"
  say "      그 바이트는 컨테이너 안에 있고 **다음 배포에서 전부 사라진다.**"
  say "      compose 의 app-board 볼륨 한 줄을 보세요."
  "$DOCKER" exec "$BOARD_CNAME" sh -c 'rm -f /data/uploads/.dss-mount-test' >/dev/null 2>&1
fi

say "  5-ㅁ. 바깥 주소"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$BOARD_BASE/" 2>/dev/null)
case "$code" in
  307) ok "$BOARD_BASE → $code (로그인으로 넘긴다 — 이것이 기대한 값이다)" ;;
  2??|3??) ok "$BOARD_BASE → $code" ;;
  502) bad "$BOARD_BASE → 502 — 앱은 떴는데 프록시가 못 닿는다"
       say "      DSM 프록시의 대상이 localhost:$BOARD_PORT 인지 보세요." ;;
  *)   bad "$BOARD_BASE → ${code:-없음} — DNS · DSM 리버스 프록시 · 인증서" ;;
esac
say "  🔴 건드리지 않은 여섯이 그대로인가:"
for h in login as meters improvements po leave; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code (그대로다)" ;;
    *)       bad "🔴 https://$h.dss21.co.kr → ${code:-없음} — 건드리지 않은 쪽이 흔들렸다" ;;
  esac
done
say "  열린 포트 (127.0.0.1 만이어야 한다):"
netstat -tln 2>/dev/null | grep ':13[0-9]\{3\}' | sed 's/^/      /'
say "  지금 도는 이미지:"
"$DOCKER" ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | sed 's/^/      /'
say "  메모리 — 🔴 일곱째입니다. compose 맨 아래 예산표를 이 값으로 다시 적습니다:"
"$DOCKER" stats --no-stream --format '{{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}' 2>/dev/null \
  | sed 's/^/      /'

# ══ 6. 마무리 ══════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  띄운 시각 $STOP_AT → 대답한 시각 $UP_AT · 약 ${DOWN}초"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" != 0 ]; then
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
  echo "되돌리기 안내:  bash $0 --rollback"
  exit "$FAIL"
fi
cat <<ANNOUNCE

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. https://board.dss21.co.kr — 포털을 거쳐 로그인이 됩니까
      · 🔴 인증서 경고가 뜨면 DSM 프록시에 dss21.co.kr 인증서를
        지정하지 않은 것입니다(기본값이 synology.com 입니다).
   2. 게시판에서 로그아웃 → 포털 세션도 함께 끝납니까
   3. 🔴 포털에서 로그아웃한 뒤 게시판 탭을 새로고침 → 로그인 화면이 뜹니까
      · 백채널 로그아웃이 도는지를 보는 **유일한 길**입니다.
      · 오류가 안 납니다 — 그래서 눈으로만 잡힙니다.
   4. 🔴 **글에 사진을 붙여 보세요** — 이 설치의 핵심입니다.
      글을 쓰고 사진을 붙여 저장 → 목록에서 다시 열어 보이는지 →
      첨부 파일도 하나 붙여 내려받아지는지.
      · 그 뒤 NAS 폴더에 바이트가 실제로 놓였는지:
          find /volume1/dss/board-uploads -type f | tail -5
      · 🔴 화면에는 보이는데 여기가 비어 있으면 **멈추고 알려 주세요.**
   5. 머리말 메뉴바가 보입니까
      · 🔴 안 보이면 **고장이 아니라 재로그인 문제**일 수 있습니다. 한 번
        로그아웃하고 다시 들어와 보세요.
   6. https://login.dss21.co.kr 의 타일에 게시판이 보입니까
      · requires_grant 가 꺼져 있어 **전 직원에게 바로** 보여야 합니다.
   7. 🔴 **관리 화면** — ADMIN 을 받은 분으로 /admin/users 가 열립니까.
      **일반 직원으로는 안 열려야** 합니다(둘 다 봅니다).
      · 먼저 그 사람이 **한 번 로그인해야** web_users 에 행이 생깁니다.
      · 역할은 포털 관리 화면에서 줍니다. 비상구는 make:admin 입니다.
   8. 🔴 **포털 · A/S · 계측기 · 개선요청 · PO · 휴가가 그대로입니까** —
      이 설치는 그 여섯을 건드리지 않았습니다.

🔴 사람이 이어서 할 일:
  · 내일 아침 백업을 한 번 더 보세요 — 스케줄러가 실제로 돌려서
    dss_board 덤프가 생기는지가 진짜 확인입니다:
      ls -lt /volume1/dss/backups/db/ | head -8
  · 위 메모리 값을 Claude 에게 알려 주세요 — compose 의 예산표를 다시 적습니다.
  · 직원에게 알립니다 — 「사내 게시판이 열렸다」.

되돌리기 안내:  bash $0 --rollback
ANNOUNCE
exit "$FAIL"
