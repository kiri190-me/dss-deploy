#!/bin/bash
# /volume1/dss/setup/13-deploy.sh — 2026-09-29 휴가 시스템 **첫 설치**
#
# ── 이것은 「갈아 끼우기」가 아니라 「없던 것을 세우는 일」이다 ─────────
#   지금까지의 배포(07~12-deploy.sh)는 이미 서 있는 것을 바꿨다. 이번에는
#   여섯째 사이트가 새로 생긴다. 그래서 검사가 보는 것이 다르다 —
#   「도는 것이 흔들리지 않았나」가 아니라 **「띄울 자리가 다 됐나」**를 본다.
#   (그 차이는 runbook/06-개선요청-배포.md 0절에 표로 적혀 있다.)
#
#   휴가 : dss-leave:0.1 · dss-leave-tools:1 · DB dss_leave · 롤 dss_leave_app
#          컨테이너 안 3700 → 127.0.0.1:13700 → https://leave.dss21.co.kr
#
# ── 🔴 첫 설치 순서. 이 차례로 부른다 ──────────────────────────────────
#
#   1) bash 13-deploy.sh                읽기만. 어긋난 곳을 먼저 고친다
#   2) bash 13-deploy.sh --preload      이미지 둘을 싣는다 (아무것도 안 멈춤)
#   3) bash 13-deploy.sh                다시 읽기만 — 이번엔 지문까지 다 본다
#   4) bash 13-deploy.sh --init         🔴 표를 만들고 직급을 넣는다
#   5) bash 13-deploy.sh --go           앱을 띄운다
#   6) 눈으로 확인 (runbook/13-휴가-설치-점검표.html 7절)
#
#   🔴 4 와 5 는 **합치지 않았다.** 표가 없는 DB 에 앱이 먼저 뜨면 첫 화면에서
#      죽는다(runbook/06 4절 머리말). 그래서 **순서를 강제한다** — 5(--go)는
#      시작하기 전에 「마이그레이션 2줄 · 직급 1개 이상」을 DB 에서 다시 세고,
#      아니면 **앱을 띄우지 않고 멈춘다.** 명령은 둘로 나눠 두고(사람이 DB 를
#      바꾸는 일과 앱을 띄우는 일을 따로 결정한다), 순서만 기계가 지킨다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/13-deploy.sh          ← 읽기만 한다
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#
#   11 · 12-deploy.sh 가 정한 기본값을 그대로 잇는다. 실수로 그냥 돌려도
#   아무것도 바뀌지 않는다(로그 파일 하나만 남는다). 코드로는 이 두 줄이다:
#     · MODE=check       (모드 절의 첫 줄)
#     · FORCE_LOAD=0     (같은 태그를 덮어쓰지 않는다)
#   그리고 DB 를 바꾸는 곳은 --init 한 군데뿐이고, 컨테이너를 띄우는 곳은
#   --go 한 군데뿐이다. --check 는 그 둘을 **부르지 않는다.**
#
#   🔴 한 가지는 정직하게 적어 둔다 — --check 도 이미지 **안을 보려고**
#      컨테이너를 잠깐 띄웠다 지운다(`docker run --rm … sh -c 'ls …'`).
#      검사 2 · 3 과 1-ㅋ 가 그것이다. 디스크에도 DB 에도 아무것도 남기지
#      않고 도는 사이트를 건드리지도 않지만, 「아무것도 안 한다」가 아니라
#      「아무것도 **바꾸지** 않는다」가 정확한 말이다. 안을 세는 검사는 그것
#      없이 할 수 없다(12-deploy.sh 도 같은 방식이다).
#
# ── 모드 여섯 ───────────────────────────────────────────────────────────
#   (없음) · --check   읽기만. 아무것도 안 바꾸고 안 멈춘다        ← 기본값
#   --preload          이미지 둘을 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load       🔴 같은 태그가 이미 있어도 **다시 싣는다** (12 에서 가져옴)
#   --init             🔴 db:migrate → seed:ranks **이 순서로.** DB 가 바뀐다
#   --go               app-leave 를 띄운다 (다른 다섯은 안 멈춘다)
#   --rollback         내리는 명령과 compose 되돌리는 명령을 찍는다
#
#   `--force-load` 는 `--preload` 와 같이 써도 된다:
#     bash 13-deploy.sh --preload --force-load
#
# ── 🔴 이미 끝난 것 (다시 하지 않는다. 이 스크립트는 **검사만** 한다) ──
#   · 이미지 둘을 /volume1/dss/images/ 에 올렸다
#   · DB dss_leave · 롤 dss_leave_app 을 만들고 비밀번호도 넣었다
#     (13-leave-db.sh · 13-leave-pw.sh · TCP 접속 확인까지 끝)
#   · .env.nas 에 LEAVE_APP_PASSWORD 한 줄
#   · 포털 clients 에 dss-leave 등록 (13-leave-client.sh · requires_grant=false)
#   · Cloudflare A 레코드 · DSM 리버스 프록시 · 인증서(dss21.co.kr)
#   · leave.env · compose · 야간 백업 파일을 NAS 로 올려 제자리에 놓았다
#     (13-leave-place.sh)
#
# ══ 🔴 이 스크립트가 **왜 이렇게 의심이 많은가** ═══════════════════════
#
#   2026-09-29 하루에 「겉은 맞는데 속이 틀린 것」을 다섯 번 봤다. 검사 아홉은
#   전부 그중 하나씩에서 나왔다.
#
#   ① 「만든 것」과 「도는 것」은 다르다
#      개선요청 DB 가 9/18~9/29 **11일간 한 번도 백업되지 않았다.** 백업
#      스크립트의 저장소 사본에는 그 줄이 있었는데 **NAS 에 올리지 않았다.**
#      아무 오류도 안 났다 — 없는 줄은 실패하지 않기 때문이다.
#      → 검사 9 가 「오늘 백업이 **다섯**인가」를 센다. 야간 백업을 이번에
#        고쳤으니, 그것이 NAS 에 올라가 **실제로 돌았는지**가 거기서 드러난다.
#
#   ② 태그가 같아도 **속이 다를 수 있다**
#      A/S 도구 이미지가 vendor 를 안 담은 채 9/21~9/29 돌았다. 태그로는
#      구별이 안 됐다. 오늘도 휴가 도구 이미지를 **seed:ranks 가 안 들어가서**
#      다시 구웠다.
#      → 검사 2·3 이 도구 이미지 **안을 센다**(마이그레이션 둘 · seed-ranks.ts).
#
#   ③ 유닉스 소켓으로 한 DB 확인은 **거짓 통과**를 낸다
#      `docker exec … psql` 은 소켓으로 붙는데 소켓은 보통 trust 다 —
#      **비밀번호가 없어도 통과한다.** 오늘 실제로 그 거짓 통과를 봤다.
#      → 검사 4 는 앱이 붙는 길과 같게 **-h 127.0.0.1**(TCP)로 붙어 본다.
#
#   ④ 「문이 열려 있다」와 「문에서 나오는 것이 옳다」는 다르다
#      개선요청의 알림 통로는 401 을 내줘 통과했는데, 그 통로가 만든 링크는
#      `http://172.20.0.7:3500/` 이었다 — 밖에서 안 닿는 주소다.
#      → 1-ㅋ 이 12-deploy.sh 의 notify_href_check 를 그대로 가져왔다. 휴가는
#        SSO_REDIRECT_URI 에서 자기 주소를 뽑는 올바른 방식이지만(env.ts 의
#        appBaseUrlFrom) **그래도 본다.**
#
#   ⑤ 사람이 칠 명령은 **한 줄 76자 안쪽**
#      DSM 의 ash 에 긴 줄을 붙여넣으면 줄바꿈이 끼어들어 **줄이 잘린다.**
#      줄 이어붙임(`\`)도 한 줄짜리 긴 명령도 둘 다 깨졌다.
#      → 이 스크립트가 찍는 명령은 전부 cmd() 를 지난다. 넘으면 스스로 경고한다.
#
# ── 🔴 되돌리기 ────────────────────────────────────────────────────────
#   첫 설치라 「옛 태그로 내린다」가 없다. 되돌리기는 **없던 것으로** 돌린다:
#     · app-leave 를 멈추고 지운다
#     · compose 를 backups/ 의 사본으로 되돌린다
#     · 🔴 **DB 와 포털 등록은 남긴다.** 해가 없고, 다시 띄울 때 그대로 쓴다.
#     · 🔴 **마이그레이션은 되돌리지 않는다.** 표를 만들기만 했고, 이 DB 는
#       휴가 혼자 쓴다 — 다른 사이트가 보는 자리가 아니다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
TODAY=$(date +%F)
CF=$D/deploy/docker-compose.nas.yml
INCOMING=$D/setup/incoming/docker-compose.nas.yml
ENV_NAS=$D/deploy/.env.nas
ENVD=$D/deploy/env
IMAGES=$D/images
BKD=$D/backups

# ── 🔴 이번에 새로 서는 것 **둘** ──────────────────────────────────────
TAG_APP=dss-leave:0.1
TAG_TOOLS=dss-leave-tools:1

# ── tar 둘 · 개발 PC 실측 (2026-09-29) ─────────────────────────────────
# 🔴 `.tar` 다(비압축). 크기와 md5 는 **파일 전송이 온전한지**를 본다 —
#    이미지의 지문(sha256)은 tar_config_id() 가 tar 안에서 따로 읽어 낸다.
#    둘은 다른 것을 본다.
TAR_APP=$IMAGES/dss-leave-0.1.tar
SZ_APP=74208768;    MD5_APP=caaf8f4204449be3d92f69b0e0270888
TAR_TOOLS=$IMAGES/dss-leave-tools-1.tar
SZ_TOOLS=189109760; MD5_TOOLS=3a44e32b83e2230389f8d1136e5030f8

# ── 🔴 **건드리지 않는 여덟.** ─────────────────────────────────────────
# 전부 지금 운영에서 돌고 있다. compose 에서 이 태그가 흔들렸으면 남의 것이
# 섞인 것이다(두 세션이 같은 저장소를 쓴다 — HANDOFF A절). 고치지 말고 알린다.
KEEP_AUTH=dss-auth:1.5
KEEP_AS=dss-as:1.7
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_METERSTOOLS=dss-meters-tools:1
KEEP_IMP=dss-improvements:0.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_PO=dss-po:0.2

# ── 휴가의 값들 ────────────────────────────────────────────────────────
LEAVE_DB=dss_leave
LEAVE_ROLE=dss_leave_app
LEAVE_ENV=$ENVD/leave.env
LEAVE_SVC=app-leave
LEAVE_TOOLS_SVC=tools-leave
LEAVE_CNAME=dss-leave
LEAVE_PORT=13700
LEAVE_INNER=3700
LEAVE_HOST=leave.dss21.co.kr
LEAVE_BASE=https://leave.dss21.co.kr
CLIENT_ID=dss-leave

# 🔴 실측이다 (dss-leave/drizzle/meta/_journal.json · 2026-09-29).
MIG_TAGS="0000_init 0001_warm_wonder_man"
N_MIG_WANT=2
# 🔴 표 이름도 실측이다 (dss-leave/drizzle/0000_init.sql:101 · CREATE TABLE
#    "web_ranks"). 소프트 삭제 칸(is_deleted)이 있으므로 셀 때 걸러야 한다.
RANK_TABLE=web_ranks
N_RANK_WANT=5     # src/lib/db/base-data.ts — 사원·대리·과장·부장·대표
# 첫 설치가 끝났을 때 public 스키마에 있어야 할 표의 개수(0000 의 10 + 0001 의 1)
N_TABLE_WANT=11

# leave.env 에 **있어야 하는** 여덟 (dss-leave/.env.example · src/lib/env.ts)
ENV_KEYS="SSO_CLIENT_SECRET SSO_CLIENT_ID SSO_ISSUER SSO_REDIRECT_URI"
ENV_KEYS="$ENV_KEYS SSO_TX_SECRET SESSION_COOKIE_SECURE SESSION_HOURS"
ENV_KEYS="$ENV_KEYS DEV_FAKE_LOGIN_ENABLED"
# leave.env 에 **있으면 안 되는** 것 — compose 와 이미지가 넘긴다. 두 곳에
# 같은 값이 있으면 언젠가 한쪽만 바뀌는데, 그때 앱은 **오류 없이** 다른 DB 를 본다.
ENV_FORBIDDEN="DATABASE_URL PORT"

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 둘. 인자가 없으면 이 둘 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 13-deploy.sh                 읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 13-deploy.sh --check         위와 같습니다
  bash 13-deploy.sh --preload       이미지 둘을 싣고 지문을 맞춥니다
  bash 13-deploy.sh --force-load    🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 13-deploy.sh --init          🔴 표를 만들고 직급을 넣습니다 (DB 가 바뀜)
  bash 13-deploy.sh --go            app-leave 를 띄웁니다
  bash 13-deploy.sh --rollback      되돌리기 안내 (아무것도 안 바꿉니다)

  🔴 첫 설치 차례:  (없음) → --preload → (없음) → --init → --go
  🔴 --init 과 --go 는 **따로** 부릅니다. 표가 없는 DB 에 앱이 먼저 뜨면
     첫 화면에서 죽습니다. --go 는 시작 전에 그것을 다시 세어 보고,
     아니면 앱을 띄우지 않고 멈춥니다.
  🔴 --go 가 띄우는 것은 app-leave 하나입니다. 포털 · A/S · 계측기 ·
     개선요청 · PO · DB 는 그대로 돕니다.
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
LOG="$D/setup/logs/13-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11 · 12-deploy.sh 의 것을 그대로 쓴다 ─────────────────────
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
ql()  { "$DOCKER" exec dss-pg-app  sh -c "psql -U \"\$POSTGRES_USER\" -d $LEAVE_DB -Atc \"$1\"" 2>/dev/null; }
qql() { "$DOCKER" exec dss-pg-app  sh -c "psql -U \"\$POSTGRES_USER\" -d $LEAVE_DB -c   \"$1\"" 2>/dev/null; }
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
#    거짓 통과다. (같은 줄이 둘이면 env_dups 가 따로 잡아 준다.)
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
  grep -cE "^[[:space:]]*(export[[:space:]]+)?$2=" "$1" 2>/dev/null || echo 0
}

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 개발 PC 의 `docker image inspect --format {{.Id}}` 가 아니라 **이 값**이
#    NAS 에 실렸을 때의 image ID 가 된다(11-deploy.sh 머리말의 그 까닭).
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

# ── 같은 태그를 덮어쓰는 길 (12-deploy.sh ① 에서 가져왔다) ─────────────
# 태그를 그대로 두고 다시 구운 이미지는 `have_img` 갈래에서 영영 안 실린다.
# 오늘 휴가 도구 이미지가 바로 그 경우였다 — seed:ranks 를 넣어 **같은 태그
# dss-leave-tools:1 로 다시 구웠다.** 그러니 이 길이 이번에 실제로 쓰인다.
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
# 🔴 파일 전체를 grep 하면 안 된다 — 주석 줄(`# image: dss-leave:0.1`)이 그대로
#    걸려서 꺼져 있는 서비스를 「가리킨다」고 세게 된다(11-deploy.sh 의 그 함정).
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
#  오늘(2026-09-29) 실제로 겪은 일이다. `docker exec dss-pg-app psql -U
#  dss_leave_app …` 은 **유닉스 소켓**으로 붙는데, 소켓은 pg_hba 에서 보통
#  trust 다 — **비밀번호가 틀려도, 아예 없어도 통과한다.** 그것으로 「붙는다」를
#  확인하고 넘어가면, 앱이 뜨는 순간 password authentication failed 로 죽는다.
#
#  앱은 compose 가 넘긴 DATABASE_URL 로 **dss-pg-app:5432(TCP)** 에 붙는다.
#  그러니 확인도 TCP 로 한다. 컨테이너 안에서 -h 127.0.0.1 을 주면 소켓이
#  아니라 TCP 를 타고, 같은 pg_hba 의 host 규칙을 지난다.
#
#  🔴 비밀번호는 **표준입력으로만** 흐른다. -e 로 주면 docker inspect 에 남고
#     명령줄에 적으면 ps 에 잠깐 보인다. 화면에는 한 글자도 찍지 않는다.
# ══════════════════════════════════════════════════════════════════════
tcp_db_check() {
  local pw out out2
  if ! pg_up; then
    bad "dss-pg-app 이 떠 있지 않다 — DB 를 볼 수 없다"
    return 1
  fi
  if [ ! -r "$ENV_NAS" ]; then
    bad "$ENV_NAS 를 읽을 수 없다 — sudo -i 로 돌리고 계십니까"
    return 1
  fi
  if ! env_has "$ENV_NAS" LEAVE_APP_PASSWORD; then
    bad ".env.nas 에 LEAVE_APP_PASSWORD 줄이 없다 — 13-leave-pw.sh 를 돌리세요"
    return 1
  fi
  if [ "$(env_dups "$ENV_NAS" LEAVE_APP_PASSWORD)" != 1 ]; then
    bad ".env.nas 에 LEAVE_APP_PASSWORD 가 $(env_dups "$ENV_NAS" LEAVE_APP_PASSWORD)줄이다 — 하나만 남기세요"
    say "      나중 것이 이긴다. 아래 시험은 **나중 것**으로 해 본다."
  fi
  pw=$(env_val "$ENV_NAS" LEAVE_APP_PASSWORD)
  if [ -z "$pw" ]; then
    bad ".env.nas 의 LEAVE_APP_PASSWORD 는 줄만 있고 값이 비었다"
    return 1
  fi
  ok ".env.nas 에 LEAVE_APP_PASSWORD 가 있다 (🔴 값은 안 찍는다)"

  out=$(printf '%s\n' "$pw" | "$DOCKER" exec -i \
        -e R="$LEAVE_ROLE" -e DBN="$LEAVE_DB" dss-pg-app sh -c '
    read -r PW
    PGPASSWORD="$PW" psql -X -tAq -h 127.0.0.1 -U "$R" -d "$DBN" \
      -c "select current_user" 2>&1')
  pw=
  case "$out" in
    *"authentication failed"*)
      bad "🔴 TCP 로 붙지 못했다 — .env.nas 의 값과 롤의 비밀번호가 다르다"
      say "      앱이 뜨는 순간 password authentication failed 로 죽는다."
      say "      다시 맞추는 길:"
      cmd "sh /volume1/dss/setup/13-leave-pw.sh"
      return 1 ;;
    *"no password supplied"*)
      bad "🔴 비밀번호가 안 넘어갔다 — .env.nas 의 값이 비어 있는 듯하다"
      return 1 ;;
    *"could not connect"*|*"Connection refused"*|*"could not translate"*)
      bad "🔴 TCP 로 서버에 닿지 못했다 (127.0.0.1:5432)"
      printf '%s\n' "$out" | sed 's/^/      /' | head -4
      return 1 ;;
    "$LEAVE_ROLE")
      ok "🔴 TCP(-h 127.0.0.1)로 $LEAVE_ROLE 이 $LEAVE_DB 에 붙었다 — 진짜 확인" ;;
    *"$LEAVE_ROLE"*)
      ok "TCP 로 붙었다 (출력에 다른 줄이 섞였지만 $LEAVE_ROLE 로 붙었다)" ;;
    *)
      bad "TCP 접속을 판정하지 못했다 — psql 이 말한 것:"
      printf '%s\n' "$out" | sed 's/^/      /' | head -4
      return 1 ;;
  esac

  # 곁들여 — 그 통과가 **진짜 인증을 지난 것인지**까지 본다.
  # 빈 비밀번호로도 붙으면 host 규칙이 trust 라, 위 ✓ 는 증거가 약하다.
  out2=$("$DOCKER" exec -e R="$LEAVE_ROLE" -e DBN="$LEAVE_DB" dss-pg-app sh -c '
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
#  🔴 알림 링크의 **주소를 실제로 뽑아 본다** (12-deploy.sh 에서 가져왔다)
#
#  왜 있는가: 2026-09-29 오전 배포는 「통로가 있다(401 이 온다)」로 통과했는데,
#  그 통로가 내준 링크가 `http://172.20.0.7:3500/` 이었다. 문이 있는지가 아니라
#  **무엇이 나오는지**를 봐야 잡힌다.
#
#  휴가는 SSO_REDIRECT_URI 에서 자기 주소를 뽑는 **올바른 방식**이다
#  (src/lib/env.ts 의 appBaseUrlFrom · A/S config/sso.ts 의 getAppBaseUrl 과
#  같은 판정). 그래도 본다 — 옳게 만든 것과 옳게 도는 것은 다르다.
# ══════════════════════════════════════════════════════════════════════
NOTIFY_CB=/api/auth/sso/callback

# 값을 그대로 찍지 않는다 — 숫자를 N 으로 가린 앞머리만 남긴다.
href_shape() { # 1 주소
  printf '%s' "$1" | cut -c1-48 | sed 's/[0-9]/N/g'
}

judge_base_url() { # 1 라벨 2 SSO_REDIRECT_URI 원본 3 기대 앞머리
  local label="$1" raw="$2" want="$3" base host
  case "$raw" in
    auto|auto:*|AUTO|"")
      bad "$label · SSO_REDIRECT_URI 가 auto(또는 빈 값)다 — 운영에는 도메인을 적는다"
      say "      auto 는 이 기계의 랜 주소를 집는다. **컨테이너 안에서는 172.x 다.**"
      return 1 ;;
  esac
  case "$raw" in
    *"$NOTIFY_CB") base=${raw%"$NOTIFY_CB"} ;;
    *)
      bad "$label · SSO_REDIRECT_URI 가 $NOTIFY_CB 로 끝나지 않는다"
      say "      앱이 여기서 던진다 — env.ts 의 appBaseUrlFrom 이 그렇게 막는다."
      say "      알림이 통째로 빈 목록이 된다. 꼴: $(href_shape "$raw")"
      return 1 ;;
  esac
  base=$(printf '%s' "$base" | sed 's:/*$::')
  host=${base#*://}; host=${host%%/*}; host=${host%%:*}
  case "$host" in
    172.*|10.*|192.168.*)
      bad "$label · 알림 주소가 **밖에서 닿지 않는 사설 주소**다 — $(href_shape "$base") 꼴"
      say "      2026-09-29 에 개선요청에서 실제로 나간 그 주소다."
      return 1 ;;
    *[!0-9.]*) : ;;   # 글자가 섞여 있다 = 이름(도메인)이다
    *)
      bad "$label · 알림 주소가 이름이 아니라 **IP** 다 — $(href_shape "$base") 꼴"
      return 1 ;;
  esac
  if [ "$base" = "$want" ]; then
    ok "$label · 알림 링크가 $want 로 시작한다"
    return 0
  fi
  bad "$label · 알림 주소가 $want 가 아니다 — $(href_shape "$base") 꼴"
  say "      포털은 「절대 주소이고 http 니까」 그대로 통과시킨다 — **조용히 틀린다.**"
  return 1
}

# 이미지 **안에** 그 계산이 들어 있는가 — 태그만으로는 안심할 수 없다.
fix_marker_check() { # 1 라벨 2 이미지태그 3 고친표시 4 대조표시
  local label="$1" tag="$2" marker="$3" control="$4" mark m c
  if ! have_img "$tag"; then
    bad "$label · $tag 가 NAS 에 없다 — 안을 볼 수 없다"
    cmd "bash $0 --preload"
    return 1
  fi
  mark=$("$DOCKER" run --rm -e M="$marker" -e C="$control" --entrypoint sh "$tag" -c '
    m=0; c=0
    grep -rlF -- "$M" /app/.next/server >/dev/null 2>&1 && m=1
    grep -rlF -- "$C" /app/.next/server >/dev/null 2>&1 && c=1
    echo "MARK $m $c"' 2>/dev/null | grep '^MARK ' | head -1)
  m=$(printf '%s' "$mark" | awk '{print $2}')
  c=$(printf '%s' "$mark" | awk '{print $3}')
  if [ "${m:-0}" = 1 ]; then
    ok "$label · $tag 안에 **자기 주소를 뽑는 자리**가 있다 (SSO_REDIRECT_URI 에서)"
    return 0
  fi
  if [ "${c:-0}" = 1 ]; then
    bad "$label · $tag 안에 그 자리가 없다 — 지금 저장소에서 구운 이미지가 아니다"
    say "      대조 표시는 찾았는데 고친 자리가 없다 → 글자를 못 읽은 것이 아니다."
    say "      🔴 다시 굽고 올리세요. 이대로 띄우면 알림 링크가 엉뚱한 주소가 된다."
    return 1
  fi
  say "    ⚠️ $tag 안을 글자로 뒤지지 못했다 — 대조 표시도 안 나왔다."
  say "       까닭 둘 중 하나다: 굽는 도구가 글자를 \\u 로 바꿔 넣었거나,"
  say "       대조 표시로 고른 글자가 코드에서 없어졌다. **판정하지 않는다.**"
  say "       🔴 이때는 사람이 직접 봐야 한다 — 알림을 눌러 어디로 가는지."
  return 0
}

notify_href_check() { # 1 라벨 2 컨테이너 3 env파일 4 기대앞머리 5 태그 6 고친표시 7 대조표시
  local label="$1" cname="$2" envf="$3" want="$4" tag="$5" marker="$6" control="$7"
  local raw="" src=""
  say "  $label — 알림 링크가 무엇으로 시작하는지 본다"

  # ㄱ. SSO_REDIRECT_URI — 🔴 값은 찍지 않는다
  if running "$cname"; then
    raw=$("$DOCKER" exec "$cname" printenv SSO_REDIRECT_URI 2>/dev/null | tr -d '\r')
    [ -n "$raw" ] && src="지금 도는 $cname 안"
  fi
  if [ -z "$raw" ] && [ -f "$envf" ]; then
    raw=$(env_val "$envf" SSO_REDIRECT_URI)
    [ -n "$raw" ] && src="$(basename "$envf")"
  fi
  if [ -z "$raw" ]; then
    bad "$label · SSO_REDIRECT_URI 를 찾지 못했다 — 알림 주소를 계산할 수 없다"
    return 1
  fi
  say "    · $src 에서 읽었다 (🔴 값은 찍지 않는다)"

  # ㄴ. 앱과 같은 계산 → 판정
  judge_base_url "$label" "$raw" "$want"

  # ㄷ. 이미지 안에 **그 계산이 들어 있는가**
  fix_marker_check "$label" "$tag" "$marker" "$control"
}
# 휴가 이미지 안에서 찾을 글자 (dss-leave/src/lib/env.ts 실측)
#   고친 표시 : appBaseUrlFrom 이 던지는 문장 (67행)
#   대조 표시 : required() 가 던지는 문장 — 두 판에 다 있다 (39행)
LEAVE_MARK="이 값에서 이 앱 자신의 주소도 읽습니다"
LEAVE_CTRL=".env.local 파일을 확인하세요"

# ══════════════════════════════════════════════════════════════════════
#  【검사 2】 도구 이미지 **안의 마이그레이션**을 센다
#  【검사 3】 도구 이미지 **안의 seed:ranks** 를 본다
#
#  🔴 오늘 이것 때문에 이미지를 다시 구웠다. Dockerfile 의 tools 스테이지는
#     `COPY . .` 가 아니라 **폴더를 골라 담는다** — scripts 가 빠져 있었다.
#     태그도 지문도 그 사실을 말해 주지 않는다. **안을 세야 보인다.**
#     seed:ranks 가 없으면 직급이 안 들어가고, 직급이 없으면 **직원을 한 명도
#     등록할 수 없다** — 첫 화면에서 운영이 막힌다.
# ══════════════════════════════════════════════════════════════════════
tools_image_check() {
  local out_sql n_sql out_j n_j out_seed t
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
    say "    → 하나면 0001 이 빠진 옛 이미지다. 다시 굽고 올리세요."
  fi
  for t in $MIG_TAGS; do
    printf '%s\n' "$out_sql" | grep -q "/$t\.sql$" \
      && ok "$t.sql 있다" || bad "$t.sql 이 없다 — 옛 이미지다"
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
  return 0
}

seed_image_check() {
  local out
  if ! have_img "$TAG_TOOLS"; then
    bad "$TAG_TOOLS 가 NAS 에 없다 — seed:ranks 가 들어 있는지 볼 수 없다"
    cmd "bash $0 --preload"
    return 1
  fi
  # 🔴 한 번의 docker run 으로 넷을 본다. 파일 · package.json 의 스크립트 ·
  #    db:migrate · ensureRanks 가 사는 모듈.
  out=$("$DOCKER" run --rm --entrypoint sh "$TAG_TOOLS" -c '
    [ -f /app/scripts/seed-ranks.ts ] && echo "SEEDFILE 1" || echo "SEEDFILE 0"
    grep -q "seed:ranks" /app/package.json && echo "SEEDSCRIPT 1" || echo "SEEDSCRIPT 0"
    grep -q "db:migrate" /app/package.json && echo "MIGSCRIPT 1" || echo "MIGSCRIPT 0"
    [ -f /app/src/lib/db/base-data.ts ] && echo "BASEDATA 1" || echo "BASEDATA 0"
    [ -f /app/drizzle.config.ts ] && echo "DRIZZLECFG 1" || echo "DRIZZLECFG 0"
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
  see_one SEEDFILE   "/app/scripts/seed-ranks.ts 가 있다" \
    "🔴 직급을 넣을 수 없다 = 직원을 한 명도 못 넣는다. 다시 굽고 올리세요."
  see_one SEEDSCRIPT "package.json 에 seed:ranks 가 있다" \
    "🔴 npm run seed:ranks 가 「없는 스크립트」로 끝난다."
  see_one MIGSCRIPT  "package.json 에 db:migrate 가 있다" \
    "🔴 표를 만들 수 없다."
  see_one BASEDATA   "src/lib/db/base-data.ts 가 있다 (ensureRanks 가 사는 곳)" \
    "seed-ranks.ts 가 불러오는 모듈이다 — 없으면 돌다 죽는다."
  see_one DRIZZLECFG "drizzle.config.ts 가 있다" \
    "drizzle-kit 이 스키마 자리를 못 찾는다."
  return 0
}

# 🔴 「직급이 실제로 몇 개 들어갔나」 — --init 이 정말 됐는지는 이것으로만 안다.
#    web_ranks 는 소프트 삭제 표라 is_deleted = false 만 센다.
rank_count() { ql "select count(*) from $RANK_TABLE where is_deleted = false"; }
mig_count()  { ql "select count(*) from drizzle.__drizzle_migrations"; }
mig_table()  { ql "select to_regclass('drizzle.__drizzle_migrations')"; }
tbl_count()  { ql "select count(*) from information_schema.tables where table_schema='public'"; }

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다
#     (아직 없는 사이트라 더욱 그렇다).
#
#  🔴 마이그레이션과 직급의 **지금 상태는 ✗ 로 세지 않는다**(1-ㅌ). --check 는
#     --init 보다 먼저 도는 것이 정상 차례라, 「표가 아직 없다」는 흠이 아니다.
#     그것을 ✗ 로 세면 --go 가 영영 못 돌고, --check 가 첫판부터 빨개진다.
#     대신 --go 가 시작 직전에 따로 세어 보고 막는다(go_gate).
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)

run_checks() {
  local tag s p rec f db code t
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
  step "1-ㄴ. NAS 에 실린 이미지 (휴가 둘 + 건드리지 않는 여덟)"
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
  say "  건드리지 않는 여덟 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for tag in "$KEEP_AUTH" "$KEEP_AS" "$KEEP_ASTOOLS" "$KEEP_METERS" \
             "$KEEP_METERSTOOLS" "$KEEP_IMP" "$KEEP_IMPTOOLS" "$KEEP_PO"; do
    have_img "$tag" && ok "$tag 실려 있다 ($(img_id "$tag" | cut -c1-19)…)" \
      || bad "$tag 가 NAS 에 없다 — 🔴 앞선 배포가 되돌아갔거나 누가 지웠다"
  done

  # ── 1-ㄷ. 【검사 2】 도구 이미지 안의 마이그레이션 둘 ────────────────
  step "1-ㄷ. 【검사 2】 $TAG_TOOLS 안의 마이그레이션 — .sql 둘 · _journal 둘"
  tools_image_check

  # ── 1-ㄹ. 【검사 3】 도구 이미지 안의 seed:ranks ─────────────────────
  step "1-ㄹ. 【검사 3】 🔴 $TAG_TOOLS 안에 seed:ranks 가 있는가"
  say "  없으면 직급이 안 들어가고, 직급이 없으면 **직원을 한 명도 못 넣는다.**"
  say "  오늘 이것 때문에 이미지를 다시 구웠다 — tools 스테이지가 scripts 를"
  say "  안 담고 있었다. 태그로는 구별이 안 된다."
  seed_image_check

  # ── 1-ㅁ. 【검사 4】 DB 와 롤 — 🔴 TCP 로 붙어 본다 ──────────────────
  step "1-ㅁ. 【검사 4】 DB $LEAVE_DB · 롤 $LEAVE_ROLE (🔴 TCP 로 실제로 붙는다)"
  if pg_up; then
    ok "dss-pg-app 이 떠 있다"
    [ "$(qpg "select 1 from pg_database where datname='$LEAVE_DB'")" = 1 ] \
      && ok "DB $LEAVE_DB 가 있다" \
      || bad "DB $LEAVE_DB 가 없다 — 13-leave-db.sh 를 먼저 돌리세요"
    [ "$(qpg "select 1 from pg_roles where rolname='$LEAVE_ROLE'")" = 1 ] \
      && ok "롤 $LEAVE_ROLE 이 있다" \
      || bad "롤 $LEAVE_ROLE 이 없다 — 13-leave-db.sh 를 먼저 돌리세요"
    v=$(qpg "select pg_get_userbyid(datdba) from pg_database where datname='$LEAVE_DB'")
    [ "$v" = "$LEAVE_ROLE" ] && ok "DB 의 주인이 $LEAVE_ROLE 이다 (표를 만들 수 있다)" \
      || bad "DB 의 주인이 ${v:-?} 다 — $LEAVE_ROLE 이 표를 못 만든다"
    v=$(qpg "select 1 from pg_authid where rolname='$LEAVE_ROLE' and rolpassword is not null")
    [ "$v" = 1 ] && ok "롤에 비밀번호가 붙어 있다" \
      || bad "롤에 비밀번호가 없다 — 13-leave-pw.sh 를 돌리세요"
  else
    bad "dss-pg-app 이 떠 있지 않다 — DB 를 하나도 볼 수 없다"
  fi
  tcp_db_check

  # ── 1-ㅂ. 【검사 5】 leave.env ───────────────────────────────────────
  # 🔴 **값은 화면에 찍지 않는다.** 있나/없나와 판정만 남긴다.
  step "1-ㅂ. 【검사 5】 $LEAVE_ENV (이름·모드·판정만. 값은 안 찍는다)"
  if [ -f "$LEAVE_ENV" ]; then
    ok "leave.env 가 제자리에 있다"
    perm=$(stat -c '%a' "$LEAVE_ENV" 2>/dev/null)
    own=$(stat -c '%U:%G' "$LEAVE_ENV" 2>/dev/null)
    [ "$perm" = 600 ] && ok "모드 600" \
      || bad "모드가 ${perm:-?} 다 (600 이어야 한다 — 남이 읽는다)"
    [ "$own" = "root:root" ] && ok "주인이 root:root 다" \
      || bad "주인이 ${own:-?} 다 (root:root 이어야 한다)"
    miss=""
    for t in $ENV_KEYS; do
      if env_has "$LEAVE_ENV" "$t"; then
        # 🔴 같은 이름이 두 줄이면 **나중 것이 이긴다**(compose 가 그렇게 읽는다).
        #    그러면 사람이 눈으로 고친 앞 줄은 아무 일도 안 한다 — 조용히 틀린다.
        if [ "$(env_dups "$LEAVE_ENV" "$t")" != 1 ]; then
          bad "$t 줄이 $(env_dups "$LEAVE_ENV" "$t")개다 — 나중 것이 이긴다. 하나만 남기세요"
          continue
        fi
        v=$(env_val "$LEAVE_ENV" "$t")
        if [ -n "$v" ]; then ok "$t 줄이 하나고 값이 차 있다"
        else bad "$t 줄은 있는데 **값이 비었다**"; fi
      else
        bad "$t 가 없다"; miss="$miss $t"
      fi
    done
    [ -z "$miss" ] && ok "여덟 개가 다 있다" \
      || say "    → 없는 것:$miss  (dss-leave/.env.example 을 본으로 채운다)"
    for t in $ENV_FORBIDDEN; do
      env_has "$LEAVE_ENV" "$t" \
        && bad "leave.env 에 $t 가 **있다** — 지우세요(compose·이미지가 넘긴다)" \
        || ok "leave.env 에 $t 가 없다 (맞다)"
    done
    env_has "$LEAVE_ENV" DSS_LEAVE_DB_PASSWORD \
      && say "    ⚠️ DSS_LEAVE_DB_PASSWORD 가 있다 — 개발 PC 의 DB 상자를 띄우는 값이다."
    # 🔴 켜진 채 나가면 아무나 남의 계정으로 들어간다. 코드는 글자 그대로
    #    "true" 일 때만 켠다 (src/lib/env.ts 의 flag()).
    v=$(env_val "$LEAVE_ENV" DEV_FAKE_LOGIN_ENABLED)
    case "$v" in
      true)
        bad "🔴 DEV_FAKE_LOGIN_ENABLED 가 켜져 있다 — **아무나 남의 계정으로 들어간다**"
        say "      운영에서는 꺼야 한다. leave.env 의 그 줄을 false 로 고치세요."
        say "      (코드는 글자 그대로 \"true\" 일 때만 켭니다 — env.ts 의 flag())" ;;
      false)
        ok "🔴 DEV_FAKE_LOGIN_ENABLED 가 꺼져 있다 (임시 로그인 안 됨)" ;;
      "")
        ok "DEV_FAKE_LOGIN_ENABLED 에 값이 없다 — 꺼진 것과 같다" ;;
      *)
        ok "DEV_FAKE_LOGIN_ENABLED 가 true 가 아니다 — 꺼진 것과 같다"
        say "    ⚠️ 그래도 false 라고 또렷이 적어 두는 편이 낫다." ;;
    esac
    # 사내 주소가 https 다. 쿠키에 secure 가 안 붙으면 사내망을 지나는 동안
    # 세션 쿠키가 평문으로 흐를 수 있다.
    v=$(env_val "$LEAVE_ENV" SESSION_COOKIE_SECURE)
    [ "$v" = true ] && ok "SESSION_COOKIE_SECURE 가 켜져 있다 (https 라 맞다)" \
      || say "    ⚠️ SESSION_COOKIE_SECURE 가 true 가 아니다 — https 사이트에서는 켜는 것이 맞다."
  else
    bad "leave.env 가 없다: $LEAVE_ENV"
    say "    → 🔴 **없는 env_file 하나면 docker compose 명령이 통째로 안 먹는다.**"
    say "      compose 의 app-leave·tools-leave 가 이 파일을 가리킨다."
    cmd "sh /volume1/dss/setup/13-leave-place.sh"
  fi

  # ── 1-ㅅ. 【검사 6】 compose ─────────────────────────────────────────
  step "1-ㅅ. 【검사 6】 compose ($CF_EFF)"
  if compose_at "$CF_EFF" config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_at "$CF_EFF" config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  SVCS=$(compose_at "$CF_EFF" config --services 2>/dev/null)
  say "  새로 생기는 둘:"
  for s in "$LEAVE_SVC" "$LEAVE_TOOLS_SVC"; do
    echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
      || bad "서비스 목록에 $s 가 없다 — 주석으로 꺼져 있거나 파일이 옛것이다"
  done
  say "  🔴 건드리지 않는 여덟 (하나라도 없으면 남의 것이 섞인 것이다):"
  for s in app-auth app-as tools-as app-meters tools-meters \
           app-improvements tools-improvements app-po; do
    echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
      || bad "서비스 목록에 $s 가 없다"
  done
  see_tag() { # 1 서비스 2 태그 3 사람이 읽을 이름
    svc_block "$CF_EFF" "$1" | grep -q "image: $2$" \
      && ok "$1 가 $2 를 가리킨다 ($3)" \
      || bad "$1 의 태그가 $2 가 아니다 ($3) — 지금 값: $(svc_image "$CF_EFF" "$1")"
  }
  say "  새로 생기는 둘의 태그:"
  see_tag "$LEAVE_SVC"       "$TAG_APP"   "휴가"
  see_tag "$LEAVE_TOOLS_SVC" "$TAG_TOOLS" "휴가 도구"
  say "  🔴 건드리지 않는 여덟의 태그 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-auth           "$KEEP_AUTH"       "포털 · 그대로"
  see_tag app-as             "$KEEP_AS"         "A/S · 그대로"
  see_tag tools-as           "$KEEP_ASTOOLS"    "A/S 도구 · 그대로"
  see_tag app-meters         "$KEEP_METERS"     "계측기 · 그대로"
  see_tag tools-meters       "$KEEP_METERSTOOLS" "계측기 도구 · 그대로"
  see_tag app-improvements   "$KEEP_IMP"        "개선요청 · 그대로"
  see_tag tools-improvements "$KEEP_IMPTOOLS"   "개선요청 도구 · 그대로"
  see_tag app-po             "$KEEP_PO"         "PO · 그대로"
  # 포트 — 한 글자가 틀리면 리버스 프록시가 502 를 계속 낸다.
  svc_block "$CF_EFF" "$LEAVE_SVC" | grep -q "127.0.0.1:$LEAVE_PORT:$LEAVE_INNER" \
    && ok "$LEAVE_SVC 가 127.0.0.1:$LEAVE_PORT 으로만 열린다" \
    || bad "$LEAVE_SVC 의 포트가 127.0.0.1:$LEAVE_PORT:$LEAVE_INNER 가 아니다"
  # 설정 파일을 가리키는가
  svc_block "$CF_EFF" "$LEAVE_SVC" | grep -q './env/leave.env' \
    && ok "$LEAVE_SVC 가 ./env/leave.env 를 읽는다" \
    || bad "$LEAVE_SVC 가 ./env/leave.env 를 안 읽는다"
  # 도구는 평소에 뜨지 않아야 한다
  svc_block "$CF_EFF" "$LEAVE_TOOLS_SVC" | grep -q 'profiles:.*tools' \
    && ok "$LEAVE_TOOLS_SVC 에 profiles: [tools] 가 있다 (up -d 로 안 뜬다)" \
    || bad "$LEAVE_TOOLS_SVC 에 profiles 가 없다 — 🔴 상시 서비스가 하나 늘어난다"
  # 🔴 DATABASE_URL 이 없으면 도구가 「.env.local 파일을 확인하세요」로 죽는다.
  #    그 문장이 개발 PC 용이라, NAS 에서 그 줄만 보면 없는 파일을 찾아 헤맨다.
  svc_block "$CF_EFF" "$LEAVE_TOOLS_SVC" | grep -q 'DATABASE_URL:' \
    && ok "$LEAVE_TOOLS_SVC 에 DATABASE_URL 이 있다" \
    || bad "🔴 $LEAVE_TOOLS_SVC 에 DATABASE_URL 이 없다 — --init 이 곧장 죽는다"
  svc_block "$CF_EFF" "$LEAVE_SVC" | grep -q 'DATABASE_URL:' \
    && ok "$LEAVE_SVC 에 DATABASE_URL 이 있다" \
    || bad "🔴 $LEAVE_SVC 에 DATABASE_URL 이 없다 — 앱이 뜨자마자 죽는다"
  # 휴가는 파일을 올리지 않는다 — 볼륨이 없는 것이 맞다(더하지 마라).
  svc_block "$CF_EFF" "$LEAVE_SVC" | grep -qE '^[[:space:]]*volumes:' \
    && say "    ⚠️ $LEAVE_SVC 에 볼륨이 붙어 있다 — 이 앱은 파일을 올리지 않는다." \
    || ok "$LEAVE_SVC 에 볼륨이 없다 (맞다 — 이 앱에는 업로드가 없다)"

  # ── 1-ㅇ. 【검사 7】 포털 등록 ───────────────────────────────────────
  step "1-ㅇ. 【검사 7】 포털(clients)에 $CLIENT_ID 가 등록돼 있는가"
  if running dss-pg-auth; then
    ROW=$(qa "select is_active, requires_grant, launcher_url, length(client_secret_hash) from clients where client_id='$CLIENT_ID'")
    if [ -z "$ROW" ]; then
      bad "clients 에 $CLIENT_ID 가 **없다** — 로그인이 아예 안 된다"
      cmd "sh /volume1/dss/setup/13-leave-client.sh"
    else
      ok "clients 에 $CLIENT_ID 가 있다"
      IFS='|' read -r C_ACT C_GRANT C_URL C_HLEN <<EOF
$ROW
EOF
      [ "$C_ACT" = t ] && ok "is_active 가 참이다" \
        || bad "is_active 가 참이 아니다 (${C_ACT:-?}) — 포털이 거절한다"
      # 🔴 PO 와 다르다. 휴가는 전 직원 공개라 명단(user_client_grants)이 없다.
      if [ "$C_GRANT" = f ]; then
        ok "🔴 requires_grant 가 거짓이다 — 전 직원이 바로 쓴다 (맞다)"
      else
        bad "🔴 requires_grant 가 참이다 (${C_GRANT:-?}) — 명단에 없는 사람이 다 막힌다"
        say "      휴가는 전 직원 공개다(개선요청·계측기와 같다). PO 만 참이다."
      fi
      [ "$C_URL" = "$LEAVE_BASE/" ] && ok "launcher_url 이 $LEAVE_BASE/ 다" \
        || bad "launcher_url 이 $LEAVE_BASE/ 가 아니다 (${C_URL:-?})"
      [ "$C_HLEN" = 64 ] && ok "client_secret_hash 가 64글자다 (sha256 hex)" \
        || bad "client_secret_hash 가 64글자가 아니다 (${C_HLEN:-?}글자)"
      # redirect_uri 는 포털이 **글자 단위로** 대조한다. 한 글자만 달라도
      # 로그인 끝에 「redirect_uri mismatch」로 돌아온다.
      v=$(qa "select 1 from clients where client_id='$CLIENT_ID' and '$LEAVE_BASE$NOTIFY_CB' = any(redirect_uris)")
      [ "$v" = 1 ] && ok "redirect_uris 에 $LEAVE_BASE$NOTIFY_CB 가 있다" \
        || bad "redirect_uris 에 그 주소가 없다 — 로그인이 끝에서 거절된다"
    fi
  else
    bad "dss-pg-auth 가 떠 있지 않다 — 포털 등록을 볼 수 없다"
  fi

  # ── 1-ㅈ. 【검사 8】 바깥 주소 ───────────────────────────────────────
  # 🔴 502 는 흠이 아니다. 「프록시와 인증서는 제대로 걸렸는데 갈 곳(앱)이 아직
  #    없다」는 뜻이다 — 첫 설치 전에는 그것이 **정상**이다.
  step "1-ㅈ. 【검사 8】 바깥 주소 $LEAVE_BASE (앱 전에는 502 가 정상)"
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$LEAVE_BASE/" 2>/dev/null)
  case "$code" in
    502)
      ok "→ 502 · **앱이 뜨기 전이면 이것이 정상이다**"
      say "      뜻: DNS 도 DSM 리버스 프록시도 인증서도 제대로 걸렸다. 다만"
      say "      localhost:$LEAVE_PORT 에 아직 아무도 없다. --go 뒤에는 307 이 된다." ;;
    2??|3??)
      ok "→ $code · 앱이 이미 대답하고 있다 (--go 를 이미 돌린 뒤다)" ;;
    000|"")
      bad "→ 대답이 없다 — DNS 나 DSM 리버스 프록시가 아직 없다"
      say "      점검표 5절(Cloudflare A 레코드 · 역방향 프록시)을 먼저." ;;
    404|503)
      bad "→ $code — 프록시 규칙이 다른 곳을 가리킨다(대상이 localhost:$LEAVE_PORT 인가)" ;;
    *)
      bad "→ $code — 뜻을 모르겠다. 프록시 규칙과 인증서를 보세요" ;;
  esac
  say "  🔴 건드리지 않는 다섯 — 지금도 그대로여야 한다:"
  for t in login as meters improvements po; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$t.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$t.dss21.co.kr → $code" ;;
      *)       bad "🔴 https://$t.dss21.co.kr → ${code:-없음} — 건드리지 않은 쪽이 흔들렸다" ;;
    esac
  done

  # ── 1-ㅊ. 【검사 9】 백업 다섯 · 디스크 · 지금 도는 것 ───────────────
  # 🔴 이 검사가 「야간 백업 스크립트를 고쳐 NAS 에 올렸고 실제로 돌았는가」를
  #    드러낸다. 개선요청은 그 세 가지 중 하나(올리기)를 빠뜨려 11일을 잃었다.
  step "1-ㅊ. 【검사 9】 오늘($TODAY) 백업이 **다섯**인가 · 디스크 · 도는 것"
  n=0
  for db in dss_auth dss_meters dss_as dss_improvements dss_leave; do
    f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
      n=$((n + 1))
    else
      bad "오늘($TODAY) 뜬 $db 백업이 없다"
    fi
  done
  if [ "$n" = 5 ]; then
    ok "🔴 오늘 백업이 다섯이다 — 고친 야간 백업이 NAS 에서 **실제로 돌았다**"
  else
    bad "🔴 오늘 백업이 ${n}개뿐이다 (다섯이어야 한다)"
    say "    → dss_leave 가 빠졌다면 고친 backup-nightly.sh 를 **NAS 에 올리지**"
    say "      않았거나, 올리고 한 번도 안 돌린 것이다. 올린 뒤 손으로 한 번:"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    say "      종료 코드 0 이고 ✓ dss_leave 줄이 찍혀야 한다."
    say "    🔴 이 백업이 --init 의 되돌릴 자리다. 없으면 --init 이 멈춘다."
  fi
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  # tar 둘이 약 251MB, 실은 이미지가 또 그만큼, 덤프가 더 든다.
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (tar 둘 약 251MB + 실은 이미지 + 덤프)"
  fi
  if pg_up && running dss-pg-auth; then
    ok "DB 둘 다 떠 있다 (이 설치에서 DB 컨테이너는 멈추지 않는다)"
  else
    bad "DB 컨테이너가 떠 있지 않다"
  fi
  for t in dss-auth dss-as dss-meters dss-improvements dss-po; do
    running "$t" && ok "$t 가 돌고 있다" \
      || bad "$t 가 안 돌고 있다 — 이 설치는 그것을 건드리지 않는다"
  done
  if running "$LEAVE_CNAME"; then
    say "  · $LEAVE_CNAME 이 이미 돌고 있다 — --go 를 이미 돌린 뒤다"
  else
    say "  · $LEAVE_CNAME 은 아직 없다 (맞다 — --go 가 띄운다)"
  fi

  # ── 1-ㅋ. 알림 링크의 주소 (곁들여 · 읽기만) ─────────────────────────
  step "1-ㅋ. 알림 링크의 주소 (통로가 아니라 **나오는 주소**를 본다)"
  say "  12-deploy.sh 에서 그대로 가져왔다. 오늘 개선요청이 여기서 걸렸다 —"
  say "  통로는 401 을 내줬는데 링크가 http://172.20.0.7:3500/ 이었다."
  notify_href_check 휴가 "$LEAVE_CNAME" "$LEAVE_ENV" \
    "$LEAVE_BASE" "$TAG_APP" "$LEAVE_MARK" "$LEAVE_CTRL"

  # ── 1-ㅌ. 마이그레이션·직급의 지금 상태 (🔴 ✗ 로 세지 않는다) ────────
  step "1-ㅌ. 표와 직급의 지금 상태 (읽기만 · ✗ 로 세지 않는다)"
  say "  🔴 --check 는 --init 보다 **먼저** 도는 것이 정상 차례다. 그래서 여기서"
  say "     「아직 없다」가 나오는 것은 흠이 아니다 — 무엇을 할 차례인지만 알린다."
  show_db_state hint
}

# 지금 DB 가 어디까지 와 있는지 — 여러 곳에서 부른다.
# 1 에 hint 를 주면 「다음에 칠 명령」까지 찍는다. --init 안에서 부를 때는
# 주지 않는다 — 이미 그것을 돌리는 중에 그 명령을 또 찍으면 헷갈린다.
show_db_state() { # [hint]
  if ! pg_up; then
    say "  · dss-pg-app 이 떠 있지 않아 못 봤다"
    return 0
  fi
  if [ -z "$(mig_table)" ]; then
    say "  · drizzle.__drizzle_migrations 가 아직 없다 → **--init 을 아직 안 돌렸다**"
    if [ "${1:-}" = hint ]; then
      say "    다음:"
      cmd "bash $0 --init"
    fi
    return 0
  fi
  say "  · 적용된 마이그레이션: $(mig_count)줄 (기대 $N_MIG_WANT)"
  say "  · public 스키마의 표: $(tbl_count)개 (기대 $N_TABLE_WANT)"
  say "  · 살아 있는 직급($RANK_TABLE): $(rank_count)개 (기대 $N_RANK_WANT)"
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  compose 갈아 끼우기 — 12-deploy.sh 의 것을 그대로 쓴다
#
#  🔴 보통은 할 일이 없다. 휴가의 compose 는 13-leave-place.sh 가 이미
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
  echo "DSS 휴가 첫 설치 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "  🔴 첫 설치라 「옛 태그로 내린다」가 없다. 되돌리기는 **없던 것으로**"
  say "     돌리는 일이다. 다른 다섯 사이트는 아무 상관이 없다."
  say
  say "  남기는 것 (지우지 않는다):"
  say "    · DB $LEAVE_DB 와 롤 $LEAVE_ROLE — 해가 없고, 다시 띄울 때 그대로 쓴다"
  say "    · 포털 clients 의 $CLIENT_ID — 지우지 말고 급하면 is_active 만 끈다"
  say "    · 마이그레이션 — 🔴 **되돌리지 않는다.** 표를 만들기만 했고"
  say "      이 DB 는 휴가 혼자 쓴다. 다른 사이트가 보는 자리가 아니다"
  say "    · 직급(web_ranks) — 다시 넣을 값이고, 지워서 좋을 것이 없다"

  step "1. 지금 상태"
  if running "$LEAVE_CNAME"; then
    say "  $LEAVE_CNAME : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$LEAVE_CNAME " || echo '?')"
  else
    say "  $LEAVE_CNAME 은 돌고 있지 않다 — 이미 내려간 뒤다"
  fi
  show_db_state

  step "2. 앱을 내린다 — 🔴 아래를 **한 줄씩** 친다"
  say "  (DSM 의 ash 는 긴 줄을 자른다. 줄 이어붙임 \\ 도 깨졌다 — 한 줄씩.)"
  say "  🔴 인자 없는 down 을 부르지 않는다 — DB 까지 내려간다."
  cmd "cd /volume1/dss/deploy"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "C=\"compose -f \$F --env-file .env.nas\""
  cmd "\$D1 \$C stop $LEAVE_SVC"
  cmd "\$D1 \$C rm -f $LEAVE_SVC"
  script_file_hint "13-rollback"

  step "3. compose 를 백업본으로 되돌린다"
  say "  🔴 compose 에서 휴가 둘만 지우는 것이 아니라 **통째로 옛 파일로** 되돌린다."
  say "     손으로 지우면 들여쓰기 한 칸에 여덟 사이트가 함께 넘어간다."
  say "  있는 사본 (최근 다섯):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -5 | sed 's/^/      /' \
    || say "      (없다)"
  if [ -z "$(ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -1)" ]; then
    say "  ⚠️ 사본이 하나도 없다. 13-leave-place.sh 도 이 스크립트도 옛 compose 를"
    say "     $BKD/docker-compose.nas.yml.<시각> 으로 남기므로,"
    say "     그것이 없다는 것은 compose 를 갈아 끼운 적이 없다는 뜻이다 —"
    say "     그러면 되돌릴 것도 없다. 휴가 둘만 손으로 지우려면 개발 PC 의"
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
  say "  디스크가 급할 때만(약 251MB):"
  cmd "\$D1 image rm $TAG_APP $TAG_TOOLS"

  step "5. 주소"
  say "  $LEAVE_BASE 는 다시 **502** 가 된다 — 그것이 맞다."
  say "  Cloudflare 레코드와 DSM 프록시 규칙은 남겨 두세요. 다시 띄울 때 씁니다."
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit 0
fi

# ══ 여기부터 check · preload · force-load · init · go ══════════════════
echo "DSS 휴가 시스템 **첫 설치** · $(date '+%F %T')"
echo "  🔴 새로 서는 것 둘:  $TAG_APP · $TAG_TOOLS"
echo "  🔴 멈추는 것은 **없다** — 여섯째 사이트를 하나 더 띄우는 일이다."
echo "  · 주소 $LEAVE_BASE → 127.0.0.1:$LEAVE_PORT"
echo "  · 건드리지 않는 여덟 — $KEEP_AUTH · $KEEP_AS · $KEEP_ASTOOLS"
echo "    · $KEEP_METERS · $KEEP_METERSTOOLS · $KEEP_IMP"
echo "    · $KEEP_IMPTOOLS · $KEEP_PO"
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**" ;;
  preload)    echo "  🔵 --preload — 이미지 둘을 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  init)       echo "  🔴 --init — 표를 만들고 직급을 넣는다. **DB 가 바뀐다.**" ;;
  go)         echo "  🔴 --go — app-leave 를 띄운다. 다른 다섯은 안 멈춘다."
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
  step "【검사 2】 $TAG_TOOLS 안의 마이그레이션 둘"
  tools_image_check
  step "【검사 3】 🔴 $TAG_TOOLS 안의 seed:ranks"
  seed_image_check
  step "$TAG_APP 안에 자기 주소를 뽑는 자리가 있는가"
  if have_img "$TAG_APP"; then
    say "  구운 때: $("$DOCKER" images "$TAG_APP" --format '{{.CreatedAt}}' 2>/dev/null)"
    fix_marker_check 휴가 "$TAG_APP" "$LEAVE_MARK" "$LEAVE_CTRL"
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
# 🔴 순서가 있다: db:migrate 로 표를 만든 **뒤에** seed:ranks 가 들어간다.
#    반대로 하면 seed:ranks 가 없는 표를 찾다 죽는다.
# 🔴 다시 돌려도 안전하다:
#      · db:migrate 는 이미 적용된 것을 건너뛴다(drizzle 기록을 본다)
#      · seed:ranks 는 없는 직급만 넣는다(ensureRanks — 중복이 안 생긴다)
#    그래서 중간에 막혔을 때 그냥 다시 부르면 된다.
# 🔴 seed:dev 는 **절대 부르지 않는다** — 가짜 사람까지 넣는 개발 전용이다.
if [ "$MODE" = init ]; then
  step "--init · 여기서만 DB 가 바뀐다"
  say "  차례: db:migrate (표를 만든다) → seed:ranks (직급을 넣는다)"
  say "  🔴 둘 다 **다시 돌려도 안전하다.** 이미 있는 것은 건너뛴다."
  say "  🔴 seed:dev 는 부르지 않는다 — 가짜 사람까지 넣는다."

  # ── 적용 전 — 꼭 필요한 것만 본다 (전체 검사는 --check 가 한다) ──────
  step "1. 적용 전 확인"
  if ! pg_up; then
    bad "dss-pg-app 이 떠 있지 않다"
    stop "DB 가 없습니다. **아무것도 바꾸지 않았습니다.**"
  fi
  ok "dss-pg-app 이 떠 있다"
  [ "$(qpg "select 1 from pg_database where datname='$LEAVE_DB'")" = 1 ] \
    && ok "DB $LEAVE_DB 가 있다" || bad "DB $LEAVE_DB 가 없다"
  tcp_db_check
  if ! have_img "$TAG_TOOLS"; then
    bad "$TAG_TOOLS 가 NAS 에 없다"
    say "    → 먼저:"
    cmd "bash $0 --preload"
  fi
  tools_image_check
  seed_image_check
  if ! compose_at "$CF" config --services 2>/dev/null | grep -qx "$LEAVE_TOOLS_SVC"; then
    bad "지금 쓰는 compose 에 $LEAVE_TOOLS_SVC 가 없다"
    say "    → compose 가 아직 제자리에 없다. 먼저 놓으세요:"
    cmd "sh /volume1/dss/setup/13-leave-place.sh"
    stop "도구를 부를 수 없습니다. **아무것도 바꾸지 않았습니다.**"
  fi
  ok "compose 에 $LEAVE_TOOLS_SVC 가 있다"

  # 🔴 백업을 **작업 직전에 다시** 찾는다. purge-nightly.sh 가 하는 방식이다.
  #    --check 에서 봤다는 것으로는 부족하다 — 그 뒤에 지워졌을 수 있고,
  #    무엇보다 --check 를 안 돌리고 바로 여기로 올 수 있다.
  step "2. 🔴 오늘 백업을 **지금 다시** 찾는다"
  BK=$(ls -1t "$BKD/db/${LEAVE_DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
  if [ -n "$BK" ] && [ -s "$BK" ]; then
    ok "오늘 백업 — $(basename "$BK") ($(du -h "$BK" | cut -f1))"
  else
    say "  🔴 오늘($TODAY) 뜬 $LEAVE_DB 백업을 **지금 찾지 못했습니다.**"
    say "     먼저 이것부터 (종료 코드 0 이어야 합니다):"
    cmd "bash $D/jobs/backup-nightly.sh"
    say "     ✓ dss_leave 줄이 찍혀야 합니다. 안 찍히면 고친 backup-nightly.sh"
    say "     를 NAS 에 아직 안 올린 것입니다."
    stop "백업 없이 DB 를 바꾸지 않습니다. **DB 는 그대로입니다.**"
  fi

  step "3. 지금 DB 상태"
  show_db_state
  if [ "$FAIL" != 0 ]; then
    stop "위 ✗ 를 먼저 해결해야 합니다. **DB 는 그대로입니다.**"
  fi

  MIG_BEFORE=$(mig_count); MIG_BEFORE=${MIG_BEFORE:-0}
  RANK_BEFORE=$(rank_count); RANK_BEFORE=${RANK_BEFORE:-0}
  say
  say "  🔴 이제 DB 를 바꿉니다. 그만두려면 **20초 안에 Ctrl+C**."
  say "     지금 Ctrl+C 하면 DB 도 앱도 손대지 않은 채로 남습니다."
  sleep 20

  # ── 4. 표를 만든다 ──────────────────────────────────────────────────
  step "4. db:migrate — 표를 만든다"
  "${COMPOSE[@]}" run --rm "$LEAVE_TOOLS_SVC" npm run db:migrate 2>&1 | sed 's/^/  /'
  rc=${PIPESTATUS[0]}
  if [ "$rc" = 0 ]; then
    ok "db:migrate 끝 (종료 코드 0)"
  else
    bad "db:migrate 실패 (종료 코드 $rc)"
    say "    🔴 「.env.local 파일을 확인하세요」가 보이면 그 파일이 아니라"
    say "       compose 의 $LEAVE_TOOLS_SVC 에 DATABASE_URL 이 없는 것입니다."
    stop "직급은 넣지 않았습니다. 위 오류를 보세요."
  fi
  MIG_MID=$(mig_count)
  [ "${MIG_MID:-0}" = "$N_MIG_WANT" ] && ok "마이그레이션 ${MIG_MID}줄" \
    || bad "마이그레이션이 ${N_MIG_WANT}줄이 아니다 (${MIG_MID:-?}) — 직급을 넣기 전에 멈춘다"
  [ "$FAIL" = 0 ] || stop "표가 다 만들어지지 않았습니다. 직급은 넣지 않았습니다."

  # ── 5. 직급을 넣는다 — 🔴 표가 있어야 들어간다 ──────────────────────
  step "5. seed:ranks — 직급을 넣는다 (🔴 4 가 끝난 뒤여야 한다)"
  say "  여러 번 돌려도 중복이 생기지 않는다 — 없는 것만 넣는다(ensureRanks)."
  "${COMPOSE[@]}" run --rm "$LEAVE_TOOLS_SVC" npm run seed:ranks 2>&1 | sed 's/^/  /'
  rc=${PIPESTATUS[0]}
  [ "$rc" = 0 ] && ok "seed:ranks 끝 (종료 코드 0)" \
    || { bad "seed:ranks 실패 (종료 코드 $rc)"; stop "표는 만들어졌습니다. 직급만 다시 넣으면 됩니다."; }

  # ── 6. SQL 로 직접 세어 본다 ────────────────────────────────────────
  # 🔴 스크립트가 「했다」고 말하는 것과 DB 에 「들어 있다」는 다른 일이다.
  step "6. 🔴 SQL 로 직접 센다 (「했다」가 아니라 「들어 있다」를 본다)"
  MIG_AFTER=$(mig_count)
  TBL_AFTER=$(tbl_count)
  RANK_AFTER=$(rank_count)
  [ "${MIG_AFTER:-0}" = "$N_MIG_WANT" ] \
    && ok "마이그레이션 기록 ${MIG_AFTER}줄 (전 ${MIG_BEFORE}줄)" \
    || bad "마이그레이션이 ${N_MIG_WANT}줄이 아니다 (${MIG_AFTER:-?})"
  [ "${TBL_AFTER:-0}" -ge "$N_TABLE_WANT" ] \
    && ok "public 스키마의 표 ${TBL_AFTER}개 (기대 $N_TABLE_WANT 이상)" \
    || bad "표가 ${TBL_AFTER:-?}개뿐이다 (기대 $N_TABLE_WANT)"
  [ "${RANK_AFTER:-0}" = "$N_RANK_WANT" ] \
    && ok "직급 ${RANK_AFTER}개 (전 ${RANK_BEFORE}개) — 기대 $N_RANK_WANT" \
    || bad "직급이 ${N_RANK_WANT}개가 아니다 (${RANK_AFTER:-?}개)"
  say "  들어간 직급:"
  qql "select name, sort_order, can_approve from $RANK_TABLE where is_deleted = false order by sort_order" \
    | sed 's/^/    /'
  say "  만들어진 표:"
  ql "select table_name from information_schema.tables where table_schema='public' order by 1" \
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
    echo "🔵 db:migrate 도 seed:ranks 도 **다시 돌려도 안전합니다**:"
    echo "     bash $0 --init"
    exit "$FAIL"
  fi
  echo
  echo "✅ 이어서 앱을 띄웁니다 (다른 다섯은 안 멈춥니다):"
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
    elif [ -z "$(mig_table)" ] || [ "$(rank_count)" = 0 ]; then
      echo "  ✅ 이어서 (🔴 DB 가 바뀝니다):     bash $0 --init"
    elif ! running "$LEAVE_CNAME"; then
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
# 🔴 왜 막는가: 표가 없는 DB 에 앱이 뜨면 첫 화면에서 죽는다(runbook/06 4절).
#    직급이 비어 있으면 뜨기는 해도 **직원을 한 명도 등록할 수 없어** 운영을
#    시작할 수 없다. 둘 다 --init 이 하는 일이고, --init 은 따로 부르는
#    명령이라 **빠뜨릴 수 있다.** 그래서 명령은 나눠 두고 순서만 기계가 지킨다.
step "2. 🔴 --init 이 끝났는지 다시 센다 (앱을 띄우기 전에)"
if [ -z "$(mig_table)" ]; then
  say "  ✗ drizzle.__drizzle_migrations 가 없다 — **--init 을 아직 안 돌렸다**"
  say "    먼저:"
  cmd "bash $0 --init"
  stop "표가 없는 DB 에 앱을 띄우지 않습니다. **아무것도 안 바꿨습니다.**"
fi
MIG_NOW=$(mig_count);  MIG_NOW=${MIG_NOW:-0}
RANK_NOW=$(rank_count); RANK_NOW=${RANK_NOW:-0}
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
if [ "$RANK_NOW" = 0 ]; then
  say "  ✗ 직급이 하나도 없다 — seed:ranks 가 안 돌았다"
  say "    이대로 띄우면 뜨기는 해도 **직원을 한 명도 등록할 수 없다.**"
  cmd "bash $0 --init"
  stop "앱을 띄우지 않았습니다. **아무것도 안 바꿨습니다.**"
fi
[ "$RANK_NOW" = "$N_RANK_WANT" ] && ok "직급 ${RANK_NOW}개 — seed:ranks 가 끝났다" \
  || say "  ⚠️ 직급이 ${RANK_NOW}개다(기대 $N_RANK_WANT). 사람이 늘리거나 줄인 것일 수 있어 막지 않는다."

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

# ══ 4. app-leave 를 띄운다 ═════════════════════════════════════════════
#
# 🔴 인자 없이 `up -d` 를 부르지 않는다 — compose 에 있는 것을 전부 띄우려
#    들고 DB 컨테이너까지 다시 만든다. `--no-deps` 로 **이름을 적은 하나만**.
# 🔴 이번에는 **멈추는 것이 없다.** 없던 서비스를 하나 더 세우는 일이다 —
#    다른 다섯 사이트는 그대로 대답한다.
step "4. $LEAVE_SVC 를 띄운다  (🔴 멈추는 것은 없다 — 새로 하나 세운다)"
say "  그대로 도는 것: 포털 · A/S · 계측기 · 개선요청 · PO · DB 둘."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  띄운 시각: $STOP_AT"
"${COMPOSE[@]}" up -d --no-deps "$LEAVE_SVC" 2>&1 | sed 's/^/    /'
wait_http "휴가" "$LEAVE_PORT" / "$LEAVE_CNAME"
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 띄운 시각 $STOP_AT → 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 5. 스모크 ══════════════════════════════════════════════════════════
step "5. 스모크 — 통로 · 🔴 알림 주소 · 🔴 직급 · 바깥 주소"

say "  5-ㄱ. 컨테이너가 살아 있는가"
if running "$LEAVE_CNAME"; then
  ok "$LEAVE_CNAME 이 돌고 있다"
  say "      $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$LEAVE_CNAME " || true)"
else
  bad "$LEAVE_CNAME 이 안 돌고 있다 — 떴다가 죽었다"
  cmd "$DOCKER logs --tail 50 $LEAVE_CNAME"
fi

# 통로가 **있는가** — 이것만으로는 부족하다. 바로 아래 5-ㄷ 가 그 이유다.
say "  5-ㄴ. 알림 통로 — 포털 $KEEP_AUTH 가 묻는 자리"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 \
       "http://127.0.0.1:$LEAVE_PORT/api/integration/notifications" 2>/dev/null)
case "$code" in
  401) ok "알림 통로가 있다 (토큰 없이 부르면 401 이 맞다 — 지금 $code)" ;;
  404) bad "404 다 — 🔴 이 앱은 SSO 설정이 덜 되면 404 를 낸다(route.ts 의 ssoConfigured)"
       say "      leave.env 의 SSO_ 다섯이 다 차 있는지 보세요(검사 5)." ;;
  000|"") bad "알림 통로가 대답하지 않는다 (${code:-없음})" ;;
  *)   ok "알림 통로가 대답한다 (지금 $code · 401 이 가장 맞다)" ;;
esac
say "      🔴 **이 줄 하나로는 9/29 오전의 결함을 못 잡았다.** 아래 5-ㄷ 를 보세요."

# 🔴 그 통로가 **내주는 주소**가 밖에서 닿는가.
say "  5-ㄷ. 🔴 알림 링크의 주소 — 새로 뜬 컨테이너로 본다"
notify_href_check 휴가 "$LEAVE_CNAME" "$LEAVE_ENV" \
  "$LEAVE_BASE" "$TAG_APP" "$LEAVE_MARK" "$LEAVE_CTRL"

# 🔴 --init 이 정말 됐는지는 이것으로만 안다.
say "  5-ㄹ. 🔴 직급이 실제로 몇 개 들어갔나"
RANK_END=$(rank_count)
[ "${RANK_END:-0}" = "$N_RANK_WANT" ] && ok "직급 ${RANK_END}개 ($RANK_TABLE)" \
  || bad "직급이 ${N_RANK_WANT}개가 아니다 (${RANK_END:-?}개) — 직원 등록이 막힌다"
qql "select name, sort_order, can_approve from $RANK_TABLE where is_deleted = false order by sort_order" \
  | sed 's/^/      /'

say "  5-ㅁ. 바깥 주소"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$LEAVE_BASE/" 2>/dev/null)
case "$code" in
  307) ok "$LEAVE_BASE → $code (로그인으로 넘긴다 — 이것이 기대한 값이다)" ;;
  2??|3??) ok "$LEAVE_BASE → $code" ;;
  502) bad "$LEAVE_BASE → 502 — 앱은 떴는데 프록시가 못 닿는다"
       say "      DSM 프록시의 대상이 localhost:$LEAVE_PORT 인지 보세요." ;;
  *)   bad "$LEAVE_BASE → ${code:-없음} — DNS · DSM 리버스 프록시 · 인증서" ;;
esac
say "  🔴 건드리지 않은 다섯이 그대로인가:"
for h in login as meters improvements po; do
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

   1. https://leave.dss21.co.kr — 포털을 거쳐 로그인이 됩니까
      · 🔴 인증서 경고가 뜨면 DSM 프록시에 dss21.co.kr 인증서를
        지정하지 않은 것입니다(기본값이 synology.com 입니다).
   2. https://login.dss21.co.kr 의 타일에 🌴 휴가가 보입니까
      · requires_grant 가 꺼져 있어 **전 직원에게 바로** 보여야 합니다.
   3. 🔴 **직원을 한 명 넣어 보세요** — 직급 칸에 다섯이 다 보입니까.
      (--init 이 제대로 됐는지는 이 화면으로만 확인됩니다.)
   4. 🔴 **알림 링크가 밖에서 닿습니까** — 휴가에서 결재 알림이 생기게 한 뒤
      A/S 나 개선요청의 종에서 그 줄에 마우스를 올려 주소를 보세요.
      · https://leave.dss21.co.kr/… 여야 합니다.
      · 172. 로 시작하면 컨테이너 주소라 안 열립니다(9/29 개선요청이 그랬습니다).
   5. 메뉴바와 알림 종이 보입니까
      · 🔴 안 보이면 **고장이 아니라 재로그인 문제**일 수 있습니다. 한 번
        로그아웃하고 다시 들어와 보세요.
      · 🔴 알림이 하나도 없으면 종은 원래 안 보입니다(빈 종을 안 그립니다).
   6. 🔴 **포털 · A/S · 계측기 · 개선요청 · PO 가 그대로입니까** — 이 설치는
      그 다섯을 건드리지 않았습니다. 이상하면 남의 변경이 섞인 것입니다.

🔴 사람이 이어서 할 일:
  · 내일 아침 백업을 한 번 더 보세요 — 스케줄러가 실제로 돌려서
    dss_leave 덤프가 생기는지가 진짜 확인입니다:
      ls -lt /volume1/dss/backups/db/ | head -6
  · 직원에게 알립니다 — 「휴가 시스템이 열렸다」.

되돌리기 안내:  bash $0 --rollback
ANNOUNCE
exit "$FAIL"
