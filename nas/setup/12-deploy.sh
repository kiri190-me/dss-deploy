#!/bin/bash
# /volume1/dss/setup/12-deploy.sh — 2026-09-29 여덟째 배포
#
# ── 오전에 한 것 (🔴 **이미 끝났다. 통과 103 · 실패 0**) ────────────────
#   계측기 1.2 → 1.3 · 개선요청 0.1 → 0.2 · 개선요청 도구 1 → 2 ·
#   PO / 내자 0.1 → 0.2 · 개선요청 마이그레이션 0003_sad_valkyrie 적용(4줄)
#
# ── 🔴 오후에 이어 붙인 것 — 개선요청만 0.2 → 0.3 ──────────────────────
#   배포가 끝난 뒤 사람이 화면에서 결함을 찾았다(아래 ⑤). 고친 이미지 하나만
#   더 올린다. **나머지 여섯은 이미 운영에서 돌고 있다 — 건드리지 않는다:**
#     포털 dss-auth:1.5 · A/S dss-as:1.7 · A/S 도구 dss-as-tools:1 ·
#     계측기 dss-meters:1.3 · 개선요청 도구 dss-improvements-tools:2 ·
#     PO dss-po:0.2
#   마이그레이션도 오전에 이미 들어갔다(4줄) — **다시 적용하지 않는다.**
#   그래서 이 스크립트가 이제 싣는 tar 는 **하나**고, 멈추는 사이트도 **하나**다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지 먼저!
#   (NAS)         bash /volume1/dss/setup/12-deploy.sh            ← 읽기만 한다
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#
#   11-deploy.sh 가 정한 기본값을 그대로 잇는다 — **인자 없이 돌리면 --check**.
#   실수로 그냥 돌려도 아무것도 바뀌지 않는다(로그 파일 하나만 남는다).
#   코드로는 아래 세 줄이 그 약속이다:
#     · MODE=check        (모드 절의 첫 줄)
#     · FORCE_LOAD=0      (같은 태그를 덮어쓰지 않는다)
#     · PROBE_WRITE=0     (--check 는 폴더에 시험 파일도 만들지 않는다)
#
# ── 모드 다섯 ───────────────────────────────────────────────────────────
#   (없음) · --check     읽기만 한다. 아무것도 안 바꾸고 안 멈춘다      ← 기본값
#   --preload            새 이미지 하나를 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다** (아래 ①)
#   --go                 🔴 **개선요청만** 교체한다 (다른 여섯은 안 멈춘다)
#   --rollback           태그 되돌리기 안내
#
#   `--force-load` 는 `--go` 와 같이 써도 된다 — 그때는 --go 가 싣는 자리에서
#   have_img 검사를 건너뛴다:  bash 12-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 12-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 12-deploy.sh --preload       (새 이미지 하나를 미리 실어 둔다)
#   3) bash 12-deploy.sh                 (다시 읽기만 — 이번엔 지문까지 다 본다)
#   4) bash 12-deploy.sh --go            (개선요청 하나만 교체)
#
# ══ 🔴 2026-09-29 오전(일곱째 배포)에 실제로 걸린 것 넷을 반영했다 ═════
#
# ① 같은 태그로 다시 구운 이미지가 **조용히 안 실렸다**
#    11-deploy.sh 의 bring_img 는 `have_img` 가 참이면 그냥 넘어갔다.
#    `dss-as-tools:1` 처럼 태그를 그대로 두고 다시 구운 것은 그 갈래에서
#    영영 안 실린다 — 지문 검사가 뒤에서 잡아 주긴 했지만 **스크립트가 스스로
#    고칠 길이 없어** 사람이 손으로 `docker load -i` 를 했다(9/18 에도 포털이
#    같은 상황이었다). 이번엔 `--force-load` 로 그 검사를 건너뛴다. 그리고
#    지문이 어긋나면 **「--force-load 로 다시 실으세요」를 그 자리에서 찍는다.**
#    🔴 이번 배포의 `dss-improvements-tools:1 → 2` 는 태그가 올라가므로 그
#       함정에 안 걸린다. 그래도 길을 열어 두는 것은, 굽기를 다시 했는데 태그를
#       안 올린 일이 **두 번** 있었기 때문이다.
#
# ② 폴더 권한은 **컨테이너 안에서 실제로 열어 본다**
#    11-deploy.sh 1-ㅅ 가 `/volume1/dss/kyosan-converted` 를 「주인이 1000:1000
#    이니 컨테이너가 읽는다」로 통과시켰는데 실제로는 EACCES 였다. `scp` 로 만든
#    폴더가 상위의 Synology ACL(`d---------+`, administrators 만)을 물려받았기
#    때문이다. 주인·모드는 그 ACL 을 안 보여 준다.
#    → 이 스크립트는 `ls` 를 **컨테이너 안에서** 돌려 본다(1-ㅂ 절).
#
# ③ 도구 이미지는 **안을 센다**
#    A/S 에서 Dockerfile 의 tools 스테이지가 vendor 를 안 담아 9/21 이후 도구가
#    전부 죽어 있었다. 태그로는 구별이 안 됐다.
#    → `dss-improvements-tools:2` 안의 마이그레이션 `.sql` 이 **넷**인지 세고,
#      `drizzle/meta/_journal.json` 의 tag 도 **넷**인지 본다(1-ㄷ 절).
#      셋이면 9/18 에 구운 옛 이미지다 — 0003 이 안 들어 있다.
#
# ④ 사람이 칠 명령은 **한 줄 80자 안쪽**
#    DSM 의 ash 에 긴 명령을 붙여넣으면 터미널 폭에서 줄바꿈되며 개행이 끼어들어
#    줄이 잘린다. 줄 이어붙임(`\`)도 한 줄짜리 긴 명령도 **둘 다 깨졌다.**
#    → 이 스크립트가 찍는 명령은 `cmd()` 를 지난다. 76자를 넘으면 스스로
#      경고하고, 길 수밖에 없는 것은 「스크립트 파일로 만들어 올리라」고 한다.
#
# ══ 🔴 ⑤ 2026-09-29 **오후**에 놓친 것 — 통로가 아니라 **결과**를 본다 ═══
#
#    오전 배포는 통과 103 · 실패 0 으로 끝났다. 그런데 배포 뒤 사람이 화면에서
#    결함을 찾았다 — A/S 의 알림 종에 개선요청 알림이 뜨는데 **눌러도 개선요청
#    으로 넘어가지 않았다.** 링크 주소를 실측하니 `http://172.20.0.7:3500/`,
#    도커가 컨테이너에 준 내부 주소였다. 밖에서는 닿지 않는 주소다.
#
#    🔴 이 스크립트의 5-ㄷ 이 그것을 **통과시켰다.** 그때 적은 줄은 이랬다:
#        ✓ 개선요청의 알림 통로가 있다 (토큰 없이 부르면 401 이 맞다 — 지금 401)
#    통로가 **열려 있는지**만 봤다. 그 통로가 **내주는 주소**가 밖에서 닿는지는
#    안 봤다. 오전에 연락서 폴더에서 겪은 ② 와 같은 종류다 — 「주인이 1000:1000
#    이니 읽는다」로 통과시켰는데 실제로는 EACCES 였다.
#    **겉(문이 있는가)이 아니라 결과(무엇이 나오는가)를 봐야 잡힌다.**
#
#    → 그래서 1-ㅊ 를 더했다. 앱이 알림 링크를 만들 때 쓰는 계산을 **그대로**
#      해 본다: 컨테이너의 SSO_REDIRECT_URI 에서 콜백 경로를 떼어 내고, 그
#      결과가 `172.` · `10.` · `192.168.` 로 시작하면 **실패**로 본다.
#      그리고 한 겹 더 — **이미지 안에 고친 자리가 들어 있는지**까지 센다.
#      값이 옳아도 옛 이미지는 그 값을 안 읽고 제 랜 주소를 집기 때문이다
#      (0.2 가 바로 그랬다). ③ 과 같은 생각이다: 태그만으로는 안심할 수 없다.
#    → 같은 검사를 **A/S(dss-as:1.7)에도** 돌린다. 지금은 올바른 방식이지만,
#      다음에 누가 그쪽을 건드리면 여기서 잡힌다.
#    → 🔴 이 검사는 **--check 에서도 돈다.** 읽기만 하는 일이다.
#    → 🔴 SSO_REDIRECT_URI 의 값은 **화면에 찍지 않는다.** 판정과 「어떤 꼴인지」
#      (숫자를 N 으로 가린 앞머리)만 남긴다.
#
# ── 알림 시스템의 짝 ───────────────────────────────────────────────────
#   포털 1.5 는 각 사이트의 `/api/integration/notifications` 를 묻는다. 오전에
#   개선요청 0.2 가 올라가 그 통로가 생겼고, 오후의 0.3 은 그 통로가 **내주는
#   주소**를 고친 것이다. 5단계 스모크가 통로를 두드려 보고(5-ㄷ), 이어서
#   1-ㅊ 가 주소까지 본다(5-ㄹ).
#   ⚠️ 계측기 1.3 과 PO 0.2 에는 그 통로가 **없다**(실측 2026-09-29 — 두
#      저장소에 `api/integration` 폴더 자체가 없다). 휴가는 아직 배포 전이다.
#      통로가 있는 곳은 A/S 와 개선요청 **둘뿐**이다. 없는 것을 찾지 않는다.
#
# ── 되돌리기 ────────────────────────────────────────────────────────────
#   개선요청 하나 : 태그를 내리고 다시 띄운다. bash 12-deploy.sh --rollback
#   마이그레이션 : 🔴 **되돌릴 필요가 없다.** 0003 은 표를 하나 **더하기만**
#     한다(notification_acknowledgements). 옛 판(0.2)도 그 표를 알고 쓴다 —
#     0.2 와 0.3 의 차이는 알림 링크의 주소를 어디서 뽑느냐 하나뿐이다.
#     지우는 SQL 은 --rollback 이 마지막에 「꼭 해야 한다면」으로만 찍는다.
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

# ── 🔴 이번에 올라가는 것 **하나** ─────────────────────────────────────
# 오전 배포(계측기 1.3 · 개선요청 도구 2 · PO 0.2)는 이미 끝났다. 오후에 더
# 올리는 것은 개선요청 하나뿐이다.
TAG_IMP=dss-improvements:0.3
# 되돌릴 자리 (지금 도는 것)
OLD_IMP=dss-improvements:0.2

# ── 🔴 **건드리지 않는 여섯.** ─────────────────────────────────────────
# 전부 지금 운영에서 돌고 있다. compose 에서 이 태그가 흔들렸으면 남의 것이
# 섞인 것이다(두 세션이 같은 저장소를 쓴다 — HANDOFF A절). 고치지 말고 알린다.
KEEP_AUTH=dss-auth:1.5
KEEP_AS=dss-as:1.7
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_PO=dss-po:0.2

# ── tar 하나 ───────────────────────────────────────────────────────────
# 🔴 `.tar` 다(비압축). tar_config_id() 가 `.tar.gz` 도 읽지만 이번 것은 비압축이다.
# 🔴 나머지 여섯의 tar 는 **요구하지 않는다** — 이미 실려서 돌고 있으므로,
#    tar 가 지워졌어도 이 배포에는 아무 상관이 없다. 대신 「NAS 에 그 이미지가
#    실려 있는가」를 1-ㄴ 에서 본다.
TAR_IMP=$IMAGES/dss-improvements-0.3.tar
# 개발 PC 실측 (2026-09-29 13:44). **파일 전송이 온전한지** 보는 값이다 —
# 이미지의 지문(sha256)은 아래 tar_config_id() 가 tar 안에서 따로 읽어 낸다.
SZ_IMP=94988800;       MD5_IMP=30e0006af64d422f93ec275eba3b41f2

# ── 개선요청 마이그레이션 ──────────────────────────────────────────────
# 🔴 **오전에 이미 적용됐다(4줄).** 0.3 은 스키마를 건드리지 않는다 — env.ts
#    한 파일만 고친 판이다. 그래서 여기서 기대하는 상태는 **처음부터 4줄**이고,
#    아래 3단계는 「4줄이면 그냥 넘어간다」로 빠져나간다. DB 는 안 바뀐다.
# 🔴 그래도 적용하는 길을 남겨 둔다 — 3줄로 보이면 오전 적용이 되돌아간 것이고,
#    그때는 사람이 알아야 한다. 이 저장소에는 `db:preflight` 가 **없어서**
#    (package.json 에 db:generate 와 db:migrate 둘뿐 — 2026-09-29 실측) A/S 의
#    preflight 자리를 셋이 대신한다: ① DB 에 이미 몇 줄인가 ② 이미지 안의 .sql 을
#    읽어 **지우는 문장이 있는가** ③ 오늘 백업이 있는가.
IMP_DB=dss_improvements
N_MIG_BEFORE_WANT=3        # 9/18 첫 설치로 들어간 셋 (오전 전의 상태)
N_MIG_WANT=4               # 0003 을 적용한 뒤 = 🔴 **지금 기대하는 값**
MIG_TAGS="0000_real_toad_men 0001_zippy_doctor_faustus 0002_serious_shiver_man 0003_sad_valkyrie"
N_MIG_SQL_WANT=4
NEW_TABLE=notification_acknowledgements

# ── 컨테이너 안에서 실제로 열어 볼 폴더 ────────────────────────────────
UP_IMP=$D/improvements-uploads
MF_METERS=$D/meters-files
ATT=$D/as-attachments
TEMPLATES=$D/as-templates

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 셋. 인자가 없으면 이 셋 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
PROBE_WRITE=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 12-deploy.sh                  읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 12-deploy.sh --check          위와 같습니다
  bash 12-deploy.sh --preload        새 이미지 하나를 싣고 지문만 맞춥니다
  bash 12-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 12-deploy.sh --go             🔴 개선요청 하나만 교체합니다
  bash 12-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 12-deploy.sh --rollback       되돌리기 안내

  🔴 --go 가 멈추는 것은 **dss-improvements 하나**입니다.
     포털 · A/S · 계측기 · PO · DB 는 그대로 돕니다.
USAGE
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)      MODE=check ;;
    --preload)    MODE=preload ;;
    --force-load) FORCE_LOAD=1; [ "$MODE" = check ] && MODE=force-load ;;
    --go)         MODE=go ;;
    --rollback)   MODE=rollback ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "모르는 인자: $1"; usage; exit 2 ;;
  esac
  shift
done
# 🔴 쓰기 시험(폴더에 빈 파일을 놓았다 지운다)은 --go 에서만 한다.
#    --check 가 「아무것도 안 바꾼다」고 말해 놓고 파일을 만들면 그 약속이 거짓이 된다.
[ "$MODE" = go ] && PROBE_WRITE=1

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/12-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11-deploy.sh 의 것을 그대로 쓴다 ──────────────────────────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# ── ④ 사람이 칠 명령은 76자 안쪽으로만 찍는다 ──────────────────────────
# DSM 의 ash 에 긴 줄을 붙여넣으면 터미널 폭에서 자동 줄바꿈되며 개행이 끼어들어
# **줄이 잘린다.** 줄 이어붙임(`\`)도 한 줄짜리 긴 명령도 둘 다 깨졌다(9/29 실측).
# 그래서 이 스크립트가 찍는 명령은 전부 이 함수를 지난다. 넘으면 스스로 일러 준다.
CMDW=76
cmd() { # 1 사람이 그대로 칠 명령 한 줄
  printf '    %s\n' "$1"
  if [ "${#1}" -gt "$CMDW" ]; then
    printf '    ⚠️ 위 줄이 %s자다(%s자 넘음) — 붙여넣으면 잘릴 수 있다.\n' "${#1}" "$CMDW"
    printf '       아래 「스크립트 파일로 만들기」를 쓰세요.\n'
  fi
}
# 길 수밖에 없는 명령은 붙여넣지 말고 파일로 만들어 돌린다.
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

# ── DB 도우미 ──────────────────────────────────────────────────────────
#   qi · qqi : dss-pg-app / dss_improvements  (이번 마이그레이션이 닿는 곳)
# 🔴 이 스크립트가 DB 를 바꾸는 곳은 **개선요청 마이그레이션 한 자리뿐**이다.
#    나머지 SQL 은 전부 SELECT 다.
qi()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $IMP_DB -Atc \"$1\"" 2>/dev/null; }
qqi() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $IMP_DB -c   \"$1\"" 2>/dev/null; }

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 개발 PC 의 `docker image inspect --format {{.Id}}` 가 아니라 **이 값**이
#    NAS 에 실렸을 때의 image ID 가 된다(11-deploy.sh 머리말의 그 까닭).
#    비압축을 먼저 읽고 안 되면 gzip 으로 다시 읽는다 — 둘 다 된다.
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

# ── ① 같은 태그를 덮어쓰는 길 ──────────────────────────────────────────
# 11-deploy.sh:244 의 bring_img 는 have_img 가 참이면 **그냥 넘어갔다.** 태그를
# 그대로 두고 다시 구운 이미지는 그 갈래에서 영영 안 실린다. 여기서는
# FORCE_LOAD=1 이면 그 검사를 건너뛰고, 지문이 어긋나면 그 자리에서 고칠 명령을
# 찍는다 — 사람이 스스로 다음 수를 알 수 있어야 한다.
force_load_hint() { # 1 태그
  say "    🔴 같은 태그로 **다시 구운** 이미지일 수 있다. 덮어쓰려면:"
  cmd "bash $0 --force-load"
  say "       (교체까지 한 번에 하려면:)"
  cmd "bash $0 --go --force-load"
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
# 🔴 파일 전체를 grep 하면 안 된다 — 주석 줄(`# image: dss-po:0.1`)이 그대로
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
#  ② 폴더를 **컨테이너 안에서 실제로 열어 본다**
#
#  🔴 주인(uid)과 모드(755)만 보면 통과하는데 실제로는 EACCES 인 일이 있다.
#     Synology ACL 이 상위에서 내려오면 `ls -ld` 에는 끝의 `+` 하나로만 보이고,
#     `stat -c %u:%g` 는 그것을 아예 안 보여 준다. 9/29 오전에 kyosan-converted
#     가 그래서 통과했다가 러너가 EACCES 로 끝났다.
#     → 판정은 커널에게 맡긴다. 컨테이너 안에서 `ls` 를 돌려 본다.
#
#  PATHS 는 "경로:모드" 를 빈칸으로 나열한 것이다 (모드: ro | rw).
#  🔴 쓰기 시험은 PROBE_WRITE=1 (즉 --go) 일 때만 한다.
# ══════════════════════════════════════════════════════════════════════
PROBE_SH='id
for p in $PATHS; do
  d=${p%%:*}; m=${p##*:}
  if ls -1 "$d" >/dev/null 2>&1; then r=READ_OK; else r=READ_FAIL; fi
  w=WRITE_SKIP
  if [ "$m" = rw ]; then
    t="$d/.dss-write-test"
    if : > "$t" 2>/dev/null; then w=WRITE_OK; rm -f "$t"; else w=WRITE_FAIL; fi
  fi
  echo "PROBE $d $r $w"
done'

perm_fix_hint() { # 나머지: 호스트 폴더들
  local h
  say "    ╔══════════════════════════════════════════════════════════════╗"
  say "    ║ 🔴 주인·모드로는 통과하는데 **컨테이너가 실제로는 못 연다.**   ║"
  say "    ╚══════════════════════════════════════════════════════════════╝"
  say "    상위 공유폴더의 Synology ACL(d---------+ · administrators 만)을"
  say "    물려받은 것이다. scp 나 mkdir 로 새로 생긴 폴더에서 일어난다."
  say "    먼저 눈으로 본다:"
  for h in "$@"; do
    cmd "ls -ld $h"
    cmd "synoacltool -get $h"
  done
  say "    고친다 — 🔴 Synology 는 chmod 하면 ACL 을 벗고 Linux mode 가 된다:"
  for h in "$@"; do
    cmd "chown -R 1000:1000 $h"
    cmd "find $h -type d -exec chmod 750 {} +"
    cmd "find $h -type f -exec chmod 640 {} +"
  done
  say "    🔴 /volume1/3_견적… 같은 **직원이 쓰는 공유폴더에는 하지 마라** —"
  say "       거기서 ACL 을 걷으면 탐색기 접근이 끊긴다(app-as 주석의 그 까닭)."
}

probe_svc() { # 1 서비스 2 컨테이너이름 3 사람이읽을이름 4 "경로:모드 …" 5 "호스트폴더 …"
  local svc="$1" cname="$2" label="$3" paths="$4" hosts="$5"
  local img out how anybad=0 d r w
  if "$DOCKER" ps --format '{{.Names}}' | grep -qx "$cname"; then
    how="지금 도는 컨테이너 $cname 안에서"
    out=$("$DOCKER" exec -e PATHS="$paths" "$cname" sh -c "$PROBE_SH" 2>&1)
  else
    img=$(svc_image "$CF_EFF" "$svc")
    if [ -n "$img" ] && have_img "$img"; then
      how="새 컨테이너($svc · $img)를 잠깐 띄워"
      out=$(compose_at "$CF_EFF" run --rm --no-deps -e PATHS="$paths" \
            --entrypoint sh "$svc" -c "$PROBE_SH" 2>&1)
    else
      say "  · $label — $cname 도 안 돌고 ${img:-이미지}도 아직 없다. **못 열어 봤다**"
      say "    → 먼저 이미지를 실으세요:"
      cmd "bash $0 --preload"
      return 0
    fi
  fi
  say "  $label — $how 본 것:"
  printf '%s\n' "$out" | grep -E '^(uid=|PROBE )' | sed 's/^/      /'
  if ! printf '%s\n' "$out" | grep -q '^PROBE '; then
    bad "$label 의 폴더를 열어 보지 못했다 — 아래가 그대로의 출력이다"
    printf '%s\n' "$out" | sed 's/^/      /' | head -8
    return 1
  fi
  while read -r _ d r w; do
    [ -n "${d:-}" ] || continue
    case "$r" in
      READ_OK) ok "$label · $d 를 읽는다" ;;
      *)       bad "$label · $d 를 **못 읽는다**(EACCES)"; anybad=1 ;;
    esac
    case "$w" in
      WRITE_OK)   ok "$label · $d 에 쓸 수 있다" ;;
      WRITE_SKIP) : ;;
      *)          bad "$label · $d 에 **못 쓴다**"; anybad=1 ;;
    esac
  done <<EOF
$(printf '%s\n' "$out" | grep '^PROBE ')
EOF
  [ "$anybad" = 0 ] || perm_fix_hint $hosts
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  ⑤ 알림 링크의 **주소를 실제로 뽑아 본다** (1-ㅊ 가 부른다)
#
#  🔴 왜 이것이 있는가는 머리말 ⑤ 에 적었다. 요약: 2026-09-29 오전 배포는
#     「통로가 있다(401 이 온다)」로 통과했는데, 그 통로가 내준 링크가
#     `http://172.20.0.7:3500/` 이었다. 문이 있는지가 아니라 **무엇이 나오는지**
#     를 봐야 잡힌다.
#
#  ── 어떻게 보는가 (세 겹) ──────────────────────────────────────────
#   ㄱ) 컨테이너의 SSO_REDIRECT_URI 를 읽는다. 🔴 **값은 찍지 않는다.**
#   ㄴ) 앱이 하는 계산을 그대로 한다 — 끝의 콜백 경로를 떼어 낸 것이 알림
#       링크의 앞머리가 된다(개선요청 env.ts 의 ownBaseUrlFrom · A/S
#       config/sso.ts 의 getAppBaseUrl. 둘이 같은 판정이다).
#       그 결과가 사설 주소(172. · 10. · 192.168.)거나 IP 면 **실패**다.
#   ㄷ) 🔴 그리고 **이미지 안에 그 계산이 들어 있는지**까지 센다. 값이 옳아도
#       옛 판은 그 값을 안 읽고 제 랜 주소를 집는다 — 0.2 가 그랬다. ③ 과 같은
#       생각이다(태그만으로는 안심할 수 없다). 고친 판에만 있는 글자를 이미지
#       안에서 찾는다.
#       ⚠️ 굽는 도구가 글자를 `\u` 로 바꿔 넣으면 찾지 못한다. 그래서 **두 판에
#          다 있는 글자(대조 표시)**를 함께 찾는다 — 그것도 못 찾았으면 「글자를
#          못 읽은 것」이라 판정하지 않고, 찾았는데 고친 자리만 없으면 옛 판이다.
# ══════════════════════════════════════════════════════════════════════
NOTIFY_CB=/api/auth/sso/callback

# 값을 그대로 찍지 않는다 — 숫자를 N 으로 가린 앞머리만 남긴다.
# (172.20.0.7 → NNN.NN.N.N · improvements.dss21.co.kr → improvements.dssNN.co.kr)
href_shape() { # 1 주소
  printf '%s' "$1" | cut -c1-48 | sed 's/[0-9]/N/g'
}

# 🔴 여기만 떼어 내 시험할 수 있게 도커를 안 쓴다 (개발 PC 에서 실제로 시험했다).
judge_base_url() { # 1 라벨 2 SSO_REDIRECT_URI 원본 3 기대 앞머리
  local label="$1" raw="$2" want="$3" base host
  # `auto` 와 `auto:<포트>` 둘 다 auto 다 (두 저장소의 isAutoValue 가 그렇다).
  case "$raw" in
    auto|auto:*|AUTO|"")
      bad "$label · SSO_REDIRECT_URI 가 auto(또는 빈 값)다 — 운영에서는 도메인을 적는다"
      say "      auto 는 이 기계의 랜 주소를 집는다. **컨테이너 안에서는 172.x 가 잡힌다.**"
      return 1 ;;
  esac
  case "$raw" in
    *"$NOTIFY_CB") base=${raw%"$NOTIFY_CB"} ;;
    *)
      bad "$label · SSO_REDIRECT_URI 가 $NOTIFY_CB 로 끝나지 않는다"
      say "      앱은 여기서 던지고 **알림이 통째로 빈 목록**이 된다. 꼴: $(href_shape "$raw")"
      return 1 ;;
  esac
  base=$(printf '%s' "$base" | sed 's:/*$::')
  host=${base#*://}; host=${host%%/*}; host=${host%%:*}
  case "$host" in
    172.*|10.*|192.168.*)
      bad "$label · 알림 주소가 **밖에서 닿지 않는 사설 주소**다 — $(href_shape "$base") 꼴"
      say "      2026-09-29 에 실제로 나간 그 주소다. 눌러도 아무 데도 못 간다."
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

# ㄷ. 이미지 **안에** 고친 자리가 들어 있는가 — ③ 과 같은 생각이다.
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
    ok "$label · $tag 안에 **고친 자리**가 있다 (SSO_REDIRECT_URI 에서 뽑는다)"
    return 0
  fi
  if [ "${c:-0}" = 1 ]; then
    bad "$label · $tag 는 **옛 판**이다 — 알림 주소를 이 기계의 랜 주소로 만든다"
    say "      대조 표시는 찾았는데 고친 자리가 없다 → 글자를 못 읽은 것이 아니다."
    if [ "$label" = 개선요청 ]; then
      say "      🔴 개선요청은 **0.3 이상**이 필요하다(커밋 858a472). 다시 굽고 올리세요."
    else
      say "      🔴 $label 의 이미지가 뒤로 갔다. 이 배포는 그쪽을 건드리지 않았으니"
      say "         **남의 변경이 섞인 것**이다 — 고치지 말고 먼저 알리세요."
    fi
    return 1
  fi
  say "    ⚠️ $tag 안을 글자로 뒤지지 못했다 — 대조 표시도 안 나왔다."
  say "       까닭 둘 중 하나다: 굽는 도구가 글자를 \\u 로 바꿔 넣었거나,"
  say "       대조 표시로 고른 글자가 코드에서 없어졌다. **판정하지 않는다.**"
  say "       🔴 이때는 사람이 직접 봐야 한다 — 알림을 눌러 어디로 가는지."
  return 0
}

notify_href_check() { # 1 라벨 2 컨테이너 3 env파일 4 기대앞머리 5 이미지태그 6 고친표시 7 대조표시
  local label="$1" cname="$2" envf="$3" want="$4" tag="$5" marker="$6" control="$7"
  local raw="" src=""
  say "  $label — 알림 링크가 무엇으로 시작하는지 본다"

  # ㄱ. SSO_REDIRECT_URI — 🔴 값은 찍지 않는다
  if "$DOCKER" ps --format '{{.Names}}' | grep -qx "$cname"; then
    raw=$("$DOCKER" exec "$cname" printenv SSO_REDIRECT_URI 2>/dev/null | tr -d '\r')
    [ -n "$raw" ] && src="지금 도는 $cname 안"
  fi
  if [ -z "$raw" ] && [ -f "$envf" ]; then
    raw=$(sed -n 's/^SSO_REDIRECT_URI=//p' "$envf" | head -1 | tr -d '\r')
    raw=${raw#\"}; raw=${raw%\"}
    raw=${raw#\'}; raw=${raw%\'}
    [ -n "$raw" ] && src="$(basename "$envf")"
  fi
  if [ -z "$raw" ]; then
    bad "$label · SSO_REDIRECT_URI 를 찾지 못했다 — 알림 주소를 계산할 수 없다"
    return 1
  fi
  say "    · $src 에서 읽었다 (🔴 값은 찍지 않는다)"

  # ㄴ. 앱과 같은 계산 → 판정
  judge_base_url "$label" "$raw" "$want"

  # ㄷ. 이미지 안에 **그 계산이 들어 있는가** (값이 옳아도 옛 판은 안 읽는다)
  fix_marker_check "$label" "$tag" "$marker" "$control"
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)

run_checks() {
  # ── 1-ㄱ. 이미지 tar 하나 — 크기 · md5 · tar 안의 지문 ───────────────
  # 🔴 크기와 md5 는 **파일 전송이 온전한지**를 본다. 지문(sha256)은 그 tar 가
  #    NAS 에 실렸을 때 갖게 될 image ID 다 — 둘은 다른 것을 본다.
  # 🔴 tar 는 하나만 본다. 나머지 여섯은 이미 실려서 돌고 있으므로 tar 가
  #    있든 없든 상관없다 — 그것들은 1-ㄴ 에서 **이미지로** 본다.
  step "1-ㄱ. 새 이미지 tar 하나 (크기 · md5 · tar 안의 지문)"
  EXP_IMP=$(tar_config_id      "$TAR_IMP"      2>/dev/null) || EXP_IMP=""
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
  see_tar "$TAG_IMP"      "$TAR_IMP"      "$EXP_IMP"      "$SZ_IMP"      "$MD5_IMP"

  # ── 1-ㄴ. NAS 에 실린 이미지 — ① 이 사는 자리 ───────────────────────
  step "1-ㄴ. NAS 에 실린 이미지"
  say "  올라가는 하나 — 지문까지 맞춘다:"
  if have_img "$TAG_IMP"; then
    if [ -n "$EXP_IMP" ] && ! verify_img "$TAG_IMP" "$EXP_IMP"; then
      force_load_hint "$TAG_IMP"
    fi
  else
    say "  · $TAG_IMP 는 아직 NAS 에 없다 — --preload 나 --go 가 싣는다"
  fi
  say "  🔴 지문이 어긋나면 **혼자 고쳐지지 않는다.** 태그가 같으면 docker load 를"
  say "     그냥 부르는 것으로는 안 바뀐다 — 위에 찍힌 --force-load 를 쓰세요."
  # 🔴 건드리지 않는 여섯 — **다시 싣지 않는다.** 여기서는 「있는가」만 본다.
  #    지문은 안 본다. 그 tar 를 요구하지 않기로 했으므로 대조할 값이 없다.
  say "  건드리지 않는 여섯 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for tag in "$KEEP_AUTH" "$KEEP_AS" "$KEEP_ASTOOLS" \
             "$KEEP_METERS" "$KEEP_IMPTOOLS" "$KEEP_PO"; do
    have_img "$tag" && ok "$tag 실려 있다 ($(img_id "$tag" | cut -c1-19)…)" \
      || bad "$tag 가 NAS 에 없다 — 🔴 오전 배포가 되돌아갔거나 누가 지웠다"
  done

  # ── 1-ㄷ. ③ 도구 이미지 **안을 센다** ───────────────────────────────
  # 태그가 올라갔으니 지문으로도 갈리지만, A/S 에서 「태그는 같은데 속이 빈」
  # 이미지에 9/21~9/29 를 버렸다. 속을 세는 것이 사람이 읽을 수 있는 증거다.
  # 🔴 오후에는 이 이미지를 **다시 싣지 않는다**(오전에 실렸다). 그래도 세어
  #    둔다 — 3단계가 「4줄이 아니다」로 갈리면 이 이미지로 적용하게 된다.
  step "1-ㄷ. $KEEP_IMPTOOLS 안의 마이그레이션 — .sql 넷 · _journal 넷"
  if have_img "$KEEP_IMPTOOLS"; then
    say "  구운 때: $("$DOCKER" images "$KEEP_IMPTOOLS" --format '{{.CreatedAt}}' 2>/dev/null)"
    OUT_SQL=$("$DOCKER" run --rm --entrypoint sh "$KEEP_IMPTOOLS" \
              -c 'ls -1 /app/drizzle/*.sql 2>/dev/null' 2>&1)
    N_SQL=$(printf '%s\n' "$OUT_SQL" | grep -c '\.sql$')
    printf '%s\n' "$OUT_SQL" | sed 's/^/      /' | head -10
    if [ "$N_SQL" = "$N_MIG_SQL_WANT" ]; then
      ok "마이그레이션 .sql 이 ${N_SQL}개다"
    else
      bad "마이그레이션 .sql 이 ${N_MIG_SQL_WANT}개가 아니다 (${N_SQL}개)"
      say "    → 셋이면 **9/18 에 구운 옛 이미지**다(0003 이 없다). 오전 배포가"
      say "      되돌아간 것이니 고치지 말고 먼저 알리세요."
    fi
    for t in $MIG_TAGS; do
      printf '%s\n' "$OUT_SQL" | grep -q "/$t\.sql$" \
        && ok "$t.sql 있다" || bad "$t.sql 이 없다 — 옛 이미지다"
    done
    OUT_J=$("$DOCKER" run --rm --entrypoint sh "$KEEP_IMPTOOLS" \
            -c 'cat /app/drizzle/meta/_journal.json 2>/dev/null' 2>&1)
    N_J=$(printf '%s\n' "$OUT_J" | grep -c '"tag"')
    [ "$N_J" = "$N_MIG_SQL_WANT" ] && ok "_journal.json 의 tag 가 ${N_J}줄이다" \
      || bad "_journal.json 의 tag 가 ${N_MIG_SQL_WANT}줄이 아니다 (${N_J}줄)"
    for t in $MIG_TAGS; do
      printf '%s\n' "$OUT_J" | grep -q "$t" \
        && ok "_journal 에 $t 가 있다" || bad "_journal 에 $t 가 없다"
    done
  else
    bad "$KEEP_IMPTOOLS 가 NAS 에 없다 — 🔴 오전에 실은 것이 사라졌다"
  fi

  # ── 1-ㄹ. env 파일 셋 — 🔴 **값은 절대 찍지 않는다** ────────────────
  # 셋 다 이미 NAS 에 있다(9/18 · 9/29 첫 설치에서 만들었다). 이번 판은 새로
  # 요구하는 이름이 없다 — 세 저장소의 .env.example 이 그대로다(2026-09-29 실측).
  # 그래서 여기서는 **있는가 · 모드가 600 인가 · 금지 이름이 안 들어왔는가**만 본다.
  step "1-ㄹ. env 파일 셋 (이름·모드만 본다. 값은 안 찍는다)"
  for e in meters.env improvements.env po.env; do
    f="$ENVD/$e"
    if [ -f "$f" ]; then
      PERM=$(stat -c '%a' "$f" 2>/dev/null)
      OWN=$(stat -c '%U:%G' "$f" 2>/dev/null)
      [ "$PERM" = 600 ] && ok "$e 있다 · 모드 600" \
        || bad "$e 의 모드가 ${PERM:-?} 다 (600 이어야 한다 — 남이 읽는다)"
      [ "$OWN" = "root:root" ] || bad "$e 의 주인이 ${OWN:-?} 다 (root:root 이어야 한다)"
      # compose 와 이미지가 넘기는 값이 여기에도 있으면 언젠가 한쪽만 바뀌는데,
      # 그때 앱은 **오류 없이** 다른 DB·다른 폴더를 본다.
      for k in DATABASE_URL UPLOADS_DIR PORT FILE_STORAGE_ROOT; do
        grep -q "^$k=" "$f" && bad "$e 에 $k 가 **있다** — 지우세요(compose 가 넘긴다)"
      done
    else
      bad "$e 가 없다: $f"
      say "    → 없는 env_file 하나면 docker compose 명령이 **통째로** 안 먹는다."
    fi
  done

  # ── 1-ㅁ. compose — 태그 하나 · 🔴 건드리지 않는 여섯 ───────────────
  step "1-ㅁ. compose ($CF_EFF)"
  if compose_at "$CF_EFF" config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_at "$CF_EFF" config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  SVCS=$(compose_at "$CF_EFF" config --services 2>/dev/null)
  for s in app-auth app-as tools-as app-meters tools-meters \
           app-improvements tools-improvements app-po; do
    echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
      || bad "서비스 목록에 $s 가 없다 — 주석으로 꺼져 있다"
  done
  see_tag() { # 1 서비스 2 태그 3 사람이 읽을 이름
    svc_block "$CF_EFF" "$1" | grep -q "image: $2$" \
      && ok "$1 가 $2 를 가리킨다 ($3)" \
      || bad "$1 의 태그가 $2 가 아니다 ($3) — 지금 값: $(svc_image "$CF_EFF" "$1")"
  }
  say "  올라가는 하나:"
  see_tag app-improvements   "$TAG_IMP"      개선요청
  # 🔴 건드리지 않기로 한 여섯. 여기가 흔들렸으면 **남의 커밋이 섞인 것**이다 —
  #    두 세션이 같은 저장소를 쓴다(HANDOFF A절). 고치지 말고 먼저 알린다.
  say "  🔴 건드리지 않는 여섯 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-auth           "$KEEP_AUTH"    "포털 · 그대로"
  see_tag app-as             "$KEEP_AS"      "A/S · 그대로"
  see_tag tools-as           "$KEEP_ASTOOLS" "A/S 도구 · 그대로"
  see_tag app-meters         "$KEEP_METERS"  "계측기 · 그대로"
  see_tag tools-improvements "$KEEP_IMPTOOLS" "개선요청 도구 · 그대로"
  see_tag app-po             "$KEEP_PO"      "PO · 그대로"
  # 볼륨과 포트 — 한 글자가 틀리면 앱은 **오류 없이** 뜨고 자료가 갈라진다.
  svc_block "$CF_EFF" app-improvements | grep -q "$UP_IMP:/data/uploads" \
    && ok "app-improvements 가 $UP_IMP 를 붙인다" \
    || bad "app-improvements 의 업로드 볼륨이 $UP_IMP 가 아니다 — 🔴 첨부가 사라진다"
  svc_block "$CF_EFF" app-meters | grep -q "$MF_METERS:/data" \
    && ok "app-meters 가 $MF_METERS 를 붙인다" \
    || bad "app-meters 의 파일 볼륨이 $MF_METERS 가 아니다"
  svc_block "$CF_EFF" app-po | grep -q "$ATT:/data" \
    && ok "app-po 가 A/S 와 **같은 첨부 폴더**($ATT)를 붙인다" \
    || bad "app-po 의 첨부 볼륨이 $ATT 가 아니다 — 🔴 서로의 파일을 못 찾는다"
  AS_DBURL=$(svc_block "$CF_EFF" app-as | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  PO_DBURL=$(svc_block "$CF_EFF" app-po | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  if [ -n "$PO_DBURL" ] && [ "$AS_DBURL" = "$PO_DBURL" ]; then
    ok "app-po 의 DATABASE_URL 이 app-as 와 **글자까지 같다**"
  else
    bad "app-po 의 DATABASE_URL 이 app-as 와 다르다 — 🔴 PO 가 엉뚱한 DB 를 본다"
  fi
  for rec in "app-meters|13300:3300" "app-improvements|13500:3500" "app-po|13600:3600"; do
    s=${rec%%|*}; p=${rec##*|}
    svc_block "$CF_EFF" "$s" | grep -q "$p" && ok "$s 가 127.0.0.1:${p%%:*} 으로 열린다" \
      || bad "$s 의 포트가 $p 가 아니다"
  done
  echo "$SVCS" | grep -qx tools-po \
    && bad "tools-po 라는 서비스가 있다 — PO 에는 도구 이미지가 없다" \
    || ok "tools-po 가 없다 (맞다 — PO 에는 마이그레이션이 없다)"

  # ── 1-ㅂ. ② 폴더를 컨테이너 안에서 **실제로 열어 본다** ─────────────
  step "1-ㅂ. 폴더 — 주인·모드가 아니라 컨테이너 안에서 실제로 연다"
  if [ "$PROBE_WRITE" = 1 ]; then
    say "  (읽기 + 쓰기를 본다. 시험 파일은 만들었다가 바로 지운다.)"
  else
    say "  🔵 --check 라서 **읽기만** 해 본다 — 아무 파일도 만들지 않는다."
    say "     쓰기는 --go 의 스모크에서 본다. 지금 손으로 보려면:"
    cmd "D1=/usr/local/bin/docker"
    cmd "\$D1 exec dss-improvements sh -c \"touch /data/uploads/.t\""
    cmd "\$D1 exec dss-improvements sh -c \"rm /data/uploads/.t\""
  fi
  M=ro; [ "$PROBE_WRITE" = 1 ] && M=rw
  probe_svc app-improvements dss-improvements 개선요청 \
    "/data/uploads:$M" "$UP_IMP"
  probe_svc app-meters dss-meters 계측기 \
    "/data:$M" "$MF_METERS"
  probe_svc app-po dss-po PO \
    "/data:$M /templates:ro" "$ATT $TEMPLATES"
  # 🔴 견적서 공유폴더는 위 틀에 안 넣는다 — 경로에 빈칸과 괄호가 있고, 무엇보다
  #    여기서는 ACL 을 **걷으면 안 된다**(직원의 탐색기 접근이 끊긴다). 쓰기
  #    시험만 --go 의 스모크에서 따로 한다(5단계).

  # ── 1-ㅅ. 마이그레이션 — 읽기만 한다 ────────────────────────────────
  # 🔴 오후 배포에서 기대하는 값은 **4줄**이다(오전에 적용됐다). 0.3 은 스키마를
  #    건드리지 않으므로 3단계는 그냥 넘어간다.
  step "1-ㅅ. 개선요청 마이그레이션 (읽기만 한다 · 기대값 $N_MIG_WANT줄)"
  if "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-app; then
    REG=$(qi "select to_regclass('drizzle.__drizzle_migrations')")
    if [ -n "$REG" ]; then
      N_MIG_NOW=$(qi "select count(*) from drizzle.__drizzle_migrations")
      say "  지금 DB 에 적용된 줄: ${N_MIG_NOW:-?}"
      case "${N_MIG_NOW:-x}" in
        "$N_MIG_WANT")        ok "$N_MIG_WANT줄이다 — 오전에 들어간 그대로다. 3단계는 **그냥 넘어간다**" ;;
        "$N_MIG_BEFORE_WANT") ok "$N_MIG_BEFORE_WANT줄이다 — 🔴 오전 적용이 되돌아갔다. 3단계가 0003 을 적용한다" ;;
        *) bad "적용된 줄이 $N_MIG_WANT 도 $N_MIG_BEFORE_WANT 도 아니다 (${N_MIG_NOW:-?})" ;;
      esac
    else
      bad "$IMP_DB 에 drizzle.__drizzle_migrations 가 없다 — 첫 설치가 안 된 DB 다"
    fi
    T_NOW=$(qi "select to_regclass('public.$NEW_TABLE')")
    if [ -n "$T_NOW" ]; then
      say "  · $NEW_TABLE 표가 **이미 있다** — 0003 이 들어간 뒤다(맞다)"
    else
      say "  · $NEW_TABLE 표가 아직 없다 — 🔴 오전 적용이 되돌아갔다"
    fi
  else
    bad "dss-pg-app 이 떠 있지 않다 — 마이그레이션 상태를 못 봤다"
  fi
  # 이미지 안의 0003 을 **읽어서** 지우는 문장이 있는지 본다 (preflight 대신)
  if have_img "$KEEP_IMPTOOLS"; then
    SQL0003=$("$DOCKER" run --rm --entrypoint sh "$KEEP_IMPTOOLS" \
              -c 'cat /app/drizzle/0003_sad_valkyrie.sql 2>/dev/null' 2>&1)
    say "  0003 이 실제로 하는 일:"
    printf '%s\n' "$SQL0003" | sed 's/^/      /' | head -12
    if printf '%s\n' "$SQL0003" | grep -qiE 'DROP TABLE|DROP COLUMN|TRUNCATE|DELETE FROM'; then
      bad "🔴 0003 에 **자료가 사라지는 문장**이 있다 — 사람이 읽고 정하세요"
    else
      ok "0003 에 자료가 사라지는 문장이 없다 (표를 하나 더하기만 한다)"
    fi
  fi

  # ── 1-ㅇ. 백업 — 🔴 **대신 뜨지 않는다. 오늘 것인지만 본다** ────────
  step "1-ㅇ. 백업이 오늘 것인가 (스크립트가 대신 뜨지 않는다)"
  for db in dss_improvements dss_as dss_auth dss_meters; do
    f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
    else
      bad "오늘($TODAY) 뜬 $db 백업이 없다"
      say "    → 먼저 이것부터 (종료 코드 0 이어야 한다):"
      cmd "bash $D/jobs/backup-nightly.sh"
    fi
  done
  for p in improvements-uploads meters-files as-attachments; do
    if [ -d "$BKD/files/$p" ]; then
      ok "$p 백업 거울이 있다 · 파일 $(find "$BKD/files/$p" -type f 2>/dev/null | wc -l)개"
    else
      bad "$p 백업 거울이 없다 ($BKD/files/$p)"
    fi
  done

  # ── 1-ㅈ. 디스크 · 도는 것 ──────────────────────────────────────────
  step "1-ㅈ. 디스크 · DB · 지금 도는 것"
  if "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-app \
     && "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-auth; then
    ok "DB 둘 다 떠 있다 (이 배포에서 DB 는 멈추지 않는다)"
  else
    bad "DB 가 떠 있지 않다"
  fi
  for c in dss-auth dss-as dss-meters dss-improvements dss-po; do
    "$DOCKER" ps --format '{{.Names}}' | grep -qx "$c" \
      && ok "$c 가 돌고 있다" || bad "$c 가 안 돌고 있다"
  done
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  # 새 tar 가 약 91MB, 실은 이미지가 또 그만큼, 덤프가 더 든다.
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (새 tar 약 91MB + 실은 이미지 + 덤프)"
  fi

  # ── 1-ㅊ. 🔴 ⑤ 알림 링크의 **주소** — 이번 결함을 잡았을 검사 ───────
  #
  # 🔴 이것이 이 판에서 새로 생긴 유일한 검사다. 오전에는 5-ㄷ 이 「401 이 오니
  #    통로가 있다」로 통과시켰고, 그 통로가 내준 링크는 172.20.0.7 이었다.
  #    여기서는 **그 링크가 무엇으로 시작하는지**를 본다. 읽기만 하는 일이라
  #    --check 에서도 돈다.
  # 🔴 통로가 있는 곳은 A/S 와 개선요청 **둘뿐**이다(계측기·PO 에는 api/integration
  #    폴더가 없다. 휴가는 아직 배포 전). A/S 는 지금 올바른 방식이지만 함께
  #    본다 — 다음에 누가 그쪽을 건드리면 여기서 잡힌다.
  step "1-ㅊ. 알림 링크의 주소 (통로가 아니라 **나오는 주소**를 본다)"
  notify_href_check 개선요청 dss-improvements "$ENVD/improvements.env" \
    "https://improvements.dss21.co.kr" "$TAG_IMP" \
    "이 값에서 이 사이트 자신의 주소도 읽습니다" \
    ".env.local 파일을 확인하세요"
  notify_href_check "A/S" dss-as "$ENVD/as.env" \
    "https://as.dss21.co.kr" "$KEEP_AS" \
    "is also read as this app" \
    "SSO_REDIRECT_URI"
}

# ══════════════════════════════════════════════════════════════════════
#  compose 갈아 끼우기
#
#  🔴 --check 는 **갈아 끼우지 않는다.** 읽기만 한다는 약속이 먼저다. 대신
#     incoming 에 새 파일이 있으면 **그 파일을** 들여다보고, 갈아 끼우는 것은
#     --go 가 한다고 알려 준다.
#  🔴 바꾸기 **전에** 새 파일을 먼저 시험한다. 없는 env_file 하나면
#     docker compose 명령이 **통째로** 실패해서, 앱을 멈춘 뒤에 그걸 알게 되면
#     다시 띄우지도 못한다.
# ══════════════════════════════════════════════════════════════════════
compose_incoming() {
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
  echo "DSS 개선요청 0.3 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     개선요청 **하나만** 옛 태그로 내리는 일이다:"
  say "       $TAG_IMP → $OLD_IMP"
  say "  🔴 되돌리면 9/29 오전의 그 결함(알림 링크가 172.20.0.7)이 **돌아온다.**"
  say "     알림 종을 못 쓰는 것과 개선요청 사이트를 못 쓰는 것 중 무엇이 급한지"
  say "     보고 정하세요."

  step "1. 옛 이미지가 아직 NAS 에 있는지 먼저 본다"
  for t in "$OLD_IMP"; do
    if have_img "$t"; then
      ok "$t 있다 ($(img_id "$t" | cut -c1-19)…)"
    else
      bad "$t 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"
    fi
  done

  step "2. 태그를 내린다 — 🔴 아래를 **한 줄씩** 친다"
  say "  (DSM 의 ash 는 긴 줄을 자른다. 줄 이어붙임 \\ 도 깨졌다 — 한 줄씩.)"
  cmd "cd /volume1/dss/deploy"
  cmd "F=docker-compose.nas.yml"
  cmd "sed -i 's|$TAG_IMP|$OLD_IMP|' \$F"
  say
  say "  ⚠️ 위 한 줄만 친다. 🔴 dss-improvements-tools:2 는 글자가 겹치지만"
  say "     위 sed 는 태그까지 붙여 갈아 끼우므로 흔들리지 않는다 — 확인:"
  cmd "grep -n 'image: dss-improvements' \$F"

  step "3. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "D1=/usr/local/bin/docker"
  say "  (2단계에서 F 를 이미 정했으면 아래 한 줄은 건너뜁니다.)"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-improvements"
  script_file_hint "12-rollback"

  step "4. 마이그레이션 — 🔴 **되돌리지 않는다**"
  say "  0003 은 오전에 들어갔고 0.3 은 스키마를 건드리지 않았다."
  say "  0.2 도 $NEW_TABLE 표를 알고 쓴다 — 표를 두어야 0.2 가 제대로 돈다."
  say "  🔴 그러니 되돌릴 일이 없다. 꼭 지워야 하는 사정이 생겼을 때만:"
  cmd "D1=/usr/local/bin/docker"
  cmd "\$D1 exec -it dss-pg-app psql -U postgres -d $IMP_DB"
  say "    그 안에서 (🔴 이 표에 쌓인 「읽음 표시」가 함께 사라진다):"
  cmd "drop table if exists $NEW_TABLE;"
  say "    그리고 기록에서도 마지막 줄을 뺀다 — 🔴 id 는 세어 보고 정한다:"
  cmd "select id from drizzle.__drizzle_migrations order by id;"
  say "    맨 아래 id 를 보고(넷이면 보통 4 다, 그러나 확인하고):"
  cmd "delete from drizzle.__drizzle_migrations where id = <ID>;"
  say "    ⚠️ 둘 중 하나만 하면 다음 db:migrate 가 어긋난다. 둘 다 하거나 둘 다 마세요."

  step "5. 지금 상태"
  for c in dss-improvements; do
    say "  $c : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$c " || echo '안 돌고 있다')"
  done
  say "  (계측기 · PO · 포털 · A/S 는 이번에 건드리지 않았으므로 그대로다.)"
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터 check · preload · force-load · go ═════════════════════════
echo "DSS 여덟째 배포 · 오후 이어붙임 · $(date '+%F %T')"
echo "  🔴 올라가는 것은 **하나**:  $OLD_IMP → $TAG_IMP"
echo "  🔴 멈추는 것도 **하나**:  dss-improvements"
echo "  · 마이그레이션은 오전에 이미 들어갔습니다(4줄) — **다시 적용하지 않습니다**"
echo "  · 건드리지 않는 여섯 — $KEEP_AUTH · $KEEP_AS · $KEEP_ASTOOLS"
echo "    · $KEEP_METERS · $KEEP_IMPTOOLS · $KEEP_PO"
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**" ;;
  preload)    echo "  🔵 --preload — 새 이미지 하나를 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — 개선요청 하나만 교체한다. 다른 여섯은 안 멈춘다."
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(폴더 권한 · 백업)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
#    이미지를 싣는 것은 **아무것도 안 멈춘다.**
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "새 이미지 tar 하나 · 지문"
  EXP_IMP=$(tar_config_id      "$TAR_IMP"      2>/dev/null) || EXP_IMP=""
  for rec in "$TAG_IMP|$TAR_IMP|$EXP_IMP|$SZ_IMP|$MD5_IMP"; do
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
  #    사람이 읽을 수 있는 증거로 한 번 더 남긴다 (③ · ⑤ 와 같은 생각).
  step "$TAG_IMP 안에 9/29 오후의 고친 자리가 있는가"
  if have_img "$TAG_IMP"; then
    say "  구운 때: $("$DOCKER" images "$TAG_IMP" --format '{{.CreatedAt}}' 2>/dev/null)"
    fix_marker_check 개선요청 "$TAG_IMP" \
      "이 값에서 이 사이트 자신의 주소도 읽습니다" \
      ".env.local 파일을 확인하세요"
  fi

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 멈추지 않았다**"
  if [ "$FAIL" != 0 ] && [ "$FORCE_LOAD" != 1 ]; then
    echo "  🔴 지문이 어긋난 것이 있으면 **같은 태그로 다시 구운 것**이다:"
    echo "       bash $0 --force-load"
  fi
  echo "  🔵 나머지 항목은 안 봤다. 이어서: bash $0        (읽기만)"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 1. 먼저 볼 것 ══════════════════════════════════════════════════════
#
# 🔴 규칙 하나: **앱을 멈추기 전에 볼 것을 다 보고, 어긋나면 앱이 살아 있는
#    채로 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
step "1. 점검표를 기계로 옮긴 것 (앱은 살아 있다)"
compose_incoming || stop "compose 를 바꾸지 않았습니다. 앱은 그대로 돕니다."
run_checks

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  if [ "$FAIL" = 0 ]; then
    echo "  ✅ 이어서 (개선요청만 잠깐 멈춥니다):  bash $0 --go"
  else
    echo "  ✗ 위 ✗ 를 먼저 해결하세요. Claude 에게 알려 주세요."
  fi
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ --go ═══════════════════════════════════════════════════════════════
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 바꾸지 않았고 앱은 살아 있습니다.**"

# ── 2. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ───────────
# 🔴 **하나만 싣는다.** 나머지 여섯은 이미 실려서 돌고 있다 — 다시 싣지 않는다.
#    (1-ㄴ 이 그 여섯이 NAS 에 있는지 이미 확인했다.)
step "2. 새 이미지 하나 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
bring_img "$TAG_IMP"      "$TAR_IMP"      "$EXP_IMP"      || FAIL2=1
if [ "${FAIL2:-0}" = 1 ]; then
  say
  say "  🔴 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
fi

# ══ 3. 마이그레이션 — 🔴 **이번에는 적용하지 않는다** ═════════════════
#
# 🔴 0003 은 오전에 들어갔다(4줄). 0.3 은 스키마를 건드리지 않으므로 아래는
#    「4줄이면 그냥 넘어간다」로 빠져나간다 — **DB 는 안 바뀐다.**
#    적용하는 길을 남겨 둔 것은 3줄로 보이면 오전 적용이 되돌아간 뜻이라서다.
#    그때는 예전 그대로 한다: ① 오늘 백업을 **작업 직전에 다시** 본다
#    ② 지금 적용된 줄 수를 센다 ③ 20초를 준다. (0003 은 CREATE TABLE 하나라
#    자료가 사라지지 않는다 — 1-ㅅ 이 그 SQL 을 실제로 읽어 확인했다.)
step "3. 개선요청 마이그레이션 — 4줄이면 그냥 넘어간다"
BK_IMP=$(ls -1t "$BKD/db/${IMP_DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
if [ -n "$BK_IMP" ] && [ -s "$BK_IMP" ]; then
  ok "오늘 백업 다시 확인 — $(basename "$BK_IMP") ($(du -h "$BK_IMP" | cut -f1))"
else
  say "  🔴 오늘($TODAY) 뜬 $IMP_DB 백업을 **지금 다시 찾지 못했습니다.**"
  say "     먼저 이것부터 (종료 코드 0 이어야 합니다):"
  cmd "bash $D/jobs/backup-nightly.sh"
  stop "백업 없이 마이그레이션을 시작하지 않습니다. **DB 는 그대로입니다.**"
fi
N_MIG_BEFORE=$(qi "select count(*) from drizzle.__drizzle_migrations")
say "  적용 전 줄 수: ${N_MIG_BEFORE:-?}"
if [ "${N_MIG_BEFORE:-x}" = "$N_MIG_WANT" ]; then
  ok "이미 $N_MIG_WANT줄이다 — 적용할 것이 없다. 그냥 넘어간다"
else
  say
  say "  🔴 이제 DB 를 바꿉니다. 그만두려면 **20초 안에 Ctrl+C**."
  say "     지금 Ctrl+C 하면 DB 도 앱도 손대지 않은 채로 남습니다."
  sleep 20

  step "3-ㄴ. 적용 (tools-improvements npm run db:migrate)"
  "${COMPOSE[@]}" run --rm tools-improvements npm run db:migrate 2>&1 | sed 's/^/  /'
  rc=${PIPESTATUS[0]}
  [ "$rc" = 0 ] && ok "적용 끝" \
    || { bad "적용 실패 (종료 코드 $rc)"; stop "앱은 아직 옛 판 그대로 돕니다. 위 오류를 보세요."; }
fi

step "3-ㄷ. 확인 — 줄 수와 새 표"
N_MIG_AFTER=$(qi "select count(*) from drizzle.__drizzle_migrations")
[ "${N_MIG_AFTER:-0}" = "$N_MIG_WANT" ] && ok "DB 의 마이그레이션 기록 ${N_MIG_AFTER}줄" \
  || bad "마이그레이션 기록이 ${N_MIG_WANT}줄이 아니다 (${N_MIG_AFTER:-?})"
[ -n "$(qi "select to_regclass('public.$NEW_TABLE')")" ] \
  && ok "$NEW_TABLE 표가 생겼다" || bad "$NEW_TABLE 표가 없다 — 적용이 덜 됐다"
qqi "select column_name, data_type from information_schema.columns where table_name = '$NEW_TABLE' order by ordinal_position"
[ "$FAIL" = 0 ] || stop "마이그레이션 확인에 ✗ 가 있습니다. **앱은 아직 옛 판 그대로입니다.**"

# ══ 4. 개선요청 **하나만** 교체 — 🔴 여기부터 정지 창 ══════════════════
#
# 🔴 인자 없이 `up -d` 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다(포털·A/S 까지 흔들린다).
#    `--no-deps` 로 **이름을 적은 하나만** 부른다.
step "4. 개선요청 하나만 교체  ⏱ 여기부터 정지 창"
say "  🔴 **멈추는 것은 dss-improvements 하나뿐이다.**"
say "     그대로 도는 것: 포털 · A/S · 계측기 · PO · DB 둘."
say "     즉 https://improvements.dss21.co.kr 만 몇십 초 대답하지 않는다."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"

say "  4-ㄱ. 개선요청 ($OLD_IMP → $TAG_IMP)"
"${COMPOSE[@]}" up -d --no-deps app-improvements 2>&1 | sed 's/^/    /'
wait_http "개선요청" 13500 / dss-improvements

UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 5. 스모크 ══════════════════════════════════════════════════════════
step "5. 스모크 — 폴더 · 알림 통로 · 🔴 알림 주소 · 바깥 주소"

# ② 새 컨테이너로 폴더를 **실제로 열어 본다.**
# 🔴 쓰기까지 보는 것은 **이번에 새로 뜬 개선요청**뿐이다. 계측기·PO 는 이번에
#    교체하지 않았으니(컨테이너가 그대로다) 「아직 읽히는가」만 본다.
say "  5-ㄱ. 폴더를 컨테이너 안에서 실제로 연다"
probe_svc app-improvements dss-improvements 개선요청 "/data/uploads:rw" "$UP_IMP"
probe_svc app-meters       dss-meters       계측기   "/data:ro"         "$MF_METERS"
probe_svc app-po           dss-po           PO       "/data:ro /templates:ro" "$ATT $TEMPLATES"

# 견적서 공유폴더 — 🔴 여기서는 ACL 을 걷으면 안 된다(직원의 탐색기가 끊긴다).
say "  5-ㄴ. 견적서 공유폴더 (PO 가 발행할 자리)"
if "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-po; then
  "$DOCKER" exec dss-po sh -c 'set -e; t=/quote-archive/.dss-write-test; : > "$t"; rm -f "$t"' >/dev/null 2>&1 \
    && ok "PO 가 견적서 공유폴더에 쓸 수 있다" \
    || { bad "PO 가 견적서 공유폴더에 못 쓴다 — 발행이 Permission denied 로 끝난다"
         say "    🔴 여기는 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기 접근이 끊긴다."
         say "       compose 의 app-po 에 group_add: [\"100\"] 이 있는지부터 보세요."; }
else
  bad "dss-po 컨테이너가 떠 있지 않다"
fi

# 통로가 **있는가** — 이것만으로는 부족하다. 바로 아래 5-ㄹ 가 그 이유다.
say "  5-ㄷ. 알림 통로 — 포털 $KEEP_AUTH 가 묻는 자리"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 \
       http://127.0.0.1:13500/api/integration/notifications 2>/dev/null)
case "$code" in
  404) bad "개선요청의 /api/integration/notifications 가 404 다 — **옛 이미지다**" ;;
  000|"") bad "개선요청의 알림 통로가 대답하지 않는다 (${code:-없음})" ;;
  *)   ok "개선요청의 알림 통로가 있다 (토큰 없이 부르면 401 이 맞다 — 지금 $code)" ;;
esac
say "      ⚠️ 계측기·PO 에는 이 통로가 없다(두 저장소에 그 폴더가 없다). 찾지 않는다."
say "      🔴 **이 줄 하나로는 9/29 오전의 결함을 못 잡았다.** 아래 5-ㄹ 를 보세요."

# 🔴 이번 판의 핵심 — 그 통로가 **내주는 주소**가 밖에서 닿는가.
say "  5-ㄹ. 🔴 알림 링크의 주소 — 새로 뜬 컨테이너로 다시 본다"
say "      (1-ㅊ 와 같은 검사다. 교체 **뒤에** 한 번 더 보는 것이 이 자리의 일이다.)"
notify_href_check 개선요청 dss-improvements "$ENVD/improvements.env" \
  "https://improvements.dss21.co.kr" "$TAG_IMP" \
  "이 값에서 이 사이트 자신의 주소도 읽습니다" \
  ".env.local 파일을 확인하세요"
notify_href_check "A/S" dss-as "$ENVD/as.env" \
  "https://as.dss21.co.kr" "$KEEP_AS" \
  "is also read as this app" \
  "SSO_REDIRECT_URI"

say "  5-ㅁ. 바깥 주소"
for h in improvements; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code" ;;
    *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
  esac
done
# 🔴 건드리지 않기로 한 넷이 그대로인지 본다. 흔들렸으면 이 배포가 건드린 것이다.
for h in login as meters po; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code (건드리지 않은 쪽 · 그대로다)" ;;
    *)       bad "🔴 https://$h.dss21.co.kr → ${code:-없음} — 건드리지 않기로 한 쪽이 흔들렸다" ;;
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
echo "  멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · 약 ${DOWN}초"
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

   1. https://improvements.dss21.co.kr — 로그인이 됩니까
   2. 🔴 **A/S 의 알림 종을 열고, 개선요청 알림을 누르세요.**
      (이것이 이 판의 전부입니다. 오전에는 눌러도 아무 데도 못 갔습니다 —
       링크가 http://172.20.0.7:3500/ 이었습니다.)
      · 개선요청 화면으로 넘어가야 맞습니다.
      · 주소창이 https://improvements.dss21.co.kr 로 시작하는지 보세요.
      · 🔴 종이 비어 있으면 **밀린 일이 없는 것**입니다 — 오류가 아닙니다.
        그때는 개선요청에 새 요청을 하나 올려 두고 다시 보세요.
   3. 개선요청의 머리말 종도 같은 방식으로 한 번 눌러 보세요.
   4. 스크린샷을 **끌어다 놓아** 올려집니까 (새 글 폼 · 목록 줄)
   5. 지운 첨부를 되살릴 수 있습니까
   6. 올린 파일이 NAS 폴더에 보입니까:
        find /volume1/dss/improvements-uploads -type f | tail -3
   7. 🔴 **포털 · A/S · 계측기 · PO 가 그대로입니까** — 이번 판은 그 넷을
      건드리지 않았습니다. 이상하면 남의 변경이 섞인 것입니다.

🔴 사람이 이어서 할 일:
  · 직원에게 알립니다 — 「종의 개선요청 알림이 이제 눌러서 넘어간다」.
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.

되돌리기 안내:  bash $0 --rollback
ANNOUNCE
exit "$FAIL"
