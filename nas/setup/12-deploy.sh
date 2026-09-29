#!/bin/bash
# /volume1/dss/setup/12-deploy.sh — 2026-09-29 여덟째 배포
#   (계측기 1.2 → 1.3 · 개선요청 0.1 → 0.2 · 개선요청 도구 1 → 2 ·
#    PO / 내자 0.1 → 0.2 · 🔴 개선요청 마이그레이션 **1개 적용**)
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
#   --preload            이미지 넷을 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다** (아래 ①)
#   --go                 계측기 · 개선요청 · PO 를 교체한다 (마이그레이션 포함)
#   --rollback           태그 되돌리기 안내
#
#   `--force-load` 는 `--go` 와 같이 써도 된다 — 그때는 --go 가 싣는 자리에서
#   have_img 검사를 건너뛴다:  bash 12-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 12-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 12-deploy.sh --preload       (이미지 넷을 미리 실어 둔다)
#   3) bash 12-deploy.sh                 (다시 읽기만 — 이번엔 지문까지 다 본다)
#   4) bash 12-deploy.sh --go            (마이그레이션 → 사이트 셋 교체)
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
# ── 🔴 이번 배포로 알림 시스템의 짝이 맞는다 ───────────────────────────
#   포털 1.5 는 각 사이트의 `/api/integration/notifications` 를 묻는데 개선요청
#   0.1(9/18 판)에는 그 통로가 없어 지금 조용히 빈 목록을 받고 있다(포털이
#   degraded 로 넘어간다 — 오류는 안 보이고 알림만 안 뜬다). 0.2 가 올라가면
#   풀린다. 그래서 5단계 스모크가 그 통로를 직접 두드려 본다.
#   ⚠️ 계측기 1.3 과 PO 0.2 에는 그 통로가 **없다**(실측 2026-09-29 — 두
#      저장소에 `api/integration` 폴더 자체가 없다). 계측기가 이번에 받은 것은
#      종을 **그리는** 쪽이다. 없는 것을 찾지 않는다.
#
# ── 되돌리기 ────────────────────────────────────────────────────────────
#   사이트 셋 : 태그를 내리고 다시 띄운다.  bash 12-deploy.sh --rollback
#   마이그레이션 : 🔴 **되돌릴 필요가 없다.** 0003 은 표를 하나 **더하기만**
#     한다(notification_acknowledgements). 옛 판(0.1)은 그 표를 모르고, 모르는
#     표는 옛 판을 방해하지 않는다. 지우는 SQL 은 --rollback 이 마지막에
#     「꼭 해야 한다면」으로만 찍는다.
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

# ── 이번에 올라가는 것 넷 ──────────────────────────────────────────────
TAG_METERS=dss-meters:1.3
TAG_IMP=dss-improvements:0.2
TAG_IMPTOOLS=dss-improvements-tools:2
TAG_PO=dss-po:0.2
# 되돌릴 자리 (지금 도는 것)
OLD_METERS=dss-meters:1.2
OLD_IMP=dss-improvements:0.1
OLD_IMPTOOLS=dss-improvements-tools:1
OLD_PO=dss-po:0.1
# 🔴 **건드리지 않는 셋.** compose 에서 이 태그가 흔들렸으면 남의 것이 섞인 것이다.
KEEP_AUTH=dss-auth:1.5
KEEP_AS=dss-as:1.7
KEEP_ASTOOLS=dss-as-tools:1

# ── tar 넷 ─────────────────────────────────────────────────────────────
# 🔴 `.tar` 다(비압축). tar_config_id() 가 `.tar.gz` 도 읽지만 이번 것은 비압축이다.
TAR_METERS=$IMAGES/dss-meters-1.3.tar
TAR_IMP=$IMAGES/dss-improvements-0.2.tar
TAR_IMPTOOLS=$IMAGES/dss-improvements-tools-2.tar
TAR_PO=$IMAGES/dss-po-0.2.tar
# 개발 PC 실측 (2026-09-29). **파일 전송이 온전한지** 보는 값이다 —
# 이미지의 지문(sha256)은 아래 tar_config_id() 가 tar 안에서 따로 읽어 낸다.
SZ_METERS=114039808;   MD5_METERS=a0bed756fafd715bcae90338bfc4c11d
SZ_IMP=94989312;       MD5_IMP=a09f539504c2b8516eae5be3a0125de7
SZ_IMPTOOLS=212163584; MD5_IMPTOOLS=84ee7755b471aa6f602d30f351741c86
SZ_PO=95373824;        MD5_PO=6581b7c4a147d3032dd54307b656a5d6

# ── 개선요청 마이그레이션 ──────────────────────────────────────────────
# 🔴 이 저장소에는 `db:preflight` 가 **없다**(package.json 에 db:generate 와
#    db:migrate 둘뿐 — 2026-09-29 실측). A/S 의 preflight 자리를 여기서는 셋이
#    대신한다: ① DB 에 이미 몇 줄인가 ② 이미지 안의 .sql 을 읽어 **지우는 문장이
#    있는가** ③ 오늘 백업이 있는가. 실제로 0003 은 CREATE TABLE 하나다.
IMP_DB=dss_improvements
N_MIG_BEFORE_WANT=3        # 9/18 첫 설치로 들어간 셋
N_MIG_WANT=4               # 0003 을 적용한 뒤
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
  bash 12-deploy.sh --preload        이미지 넷을 싣고 지문만 맞춥니다
  bash 12-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 12-deploy.sh --go             마이그레이션 → 사이트 셋 교체
  bash 12-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 12-deploy.sh --rollback       되돌리기 안내
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
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)

run_checks() {
  # ── 1-ㄱ. 이미지 tar 넷 — 크기 · md5 · tar 안의 지문 ─────────────────
  # 🔴 크기와 md5 는 **파일 전송이 온전한지**를 본다. 지문(sha256)은 그 tar 가
  #    NAS 에 실렸을 때 갖게 될 image ID 다 — 둘은 다른 것을 본다.
  step "1-ㄱ. 이미지 tar 넷 (크기 · md5 · tar 안의 지문)"
  EXP_METERS=$(tar_config_id   "$TAR_METERS"   2>/dev/null) || EXP_METERS=""
  EXP_IMP=$(tar_config_id      "$TAR_IMP"      2>/dev/null) || EXP_IMP=""
  EXP_IMPTOOLS=$(tar_config_id "$TAR_IMPTOOLS" 2>/dev/null) || EXP_IMPTOOLS=""
  EXP_PO=$(tar_config_id       "$TAR_PO"       2>/dev/null) || EXP_PO=""
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
  see_tar "$TAG_METERS"   "$TAR_METERS"   "$EXP_METERS"   "$SZ_METERS"   "$MD5_METERS"
  see_tar "$TAG_IMP"      "$TAR_IMP"      "$EXP_IMP"      "$SZ_IMP"      "$MD5_IMP"
  see_tar "$TAG_IMPTOOLS" "$TAR_IMPTOOLS" "$EXP_IMPTOOLS" "$SZ_IMPTOOLS" "$MD5_IMPTOOLS"
  see_tar "$TAG_PO"       "$TAR_PO"       "$EXP_PO"       "$SZ_PO"       "$MD5_PO"

  # ── 1-ㄴ. NAS 에 실린 이미지의 지문 — ① 이 사는 자리 ────────────────
  step "1-ㄴ. NAS 에 실린 이미지의 지문"
  for rec in "$TAG_METERS|$EXP_METERS" "$TAG_IMP|$EXP_IMP" \
             "$TAG_IMPTOOLS|$EXP_IMPTOOLS" "$TAG_PO|$EXP_PO"; do
    tag=${rec%%|*}; exp=${rec##*|}
    if have_img "$tag"; then
      if [ -n "$exp" ] && ! verify_img "$tag" "$exp"; then
        force_load_hint "$tag"
      fi
    else
      say "  · $tag 는 아직 NAS 에 없다 — --preload 나 --go 가 싣는다"
    fi
  done
  say "  🔴 지문이 어긋나면 **혼자 고쳐지지 않는다.** 태그가 같으면 docker load 를"
  say "     그냥 부르는 것으로는 안 바뀐다 — 위에 찍힌 --force-load 를 쓰세요."

  # ── 1-ㄷ. ③ 도구 이미지 **안을 센다** ───────────────────────────────
  # 태그가 올라갔으니 지문으로도 갈리지만, A/S 에서 「태그는 같은데 속이 빈」
  # 이미지에 9/21~9/29 를 버렸다. 속을 세는 것이 사람이 읽을 수 있는 증거다.
  step "1-ㄷ. $TAG_IMPTOOLS 안의 마이그레이션 — .sql 넷 · _journal 넷"
  if have_img "$TAG_IMPTOOLS"; then
    say "  구운 때: $("$DOCKER" images "$TAG_IMPTOOLS" --format '{{.CreatedAt}}' 2>/dev/null)"
    OUT_SQL=$("$DOCKER" run --rm --entrypoint sh "$TAG_IMPTOOLS" \
              -c 'ls -1 /app/drizzle/*.sql 2>/dev/null' 2>&1)
    N_SQL=$(printf '%s\n' "$OUT_SQL" | grep -c '\.sql$')
    printf '%s\n' "$OUT_SQL" | sed 's/^/      /' | head -10
    if [ "$N_SQL" = "$N_MIG_SQL_WANT" ]; then
      ok "마이그레이션 .sql 이 ${N_SQL}개다"
    else
      bad "마이그레이션 .sql 이 ${N_MIG_SQL_WANT}개가 아니다 (${N_SQL}개)"
      say "    → 셋이면 **9/18 에 구운 옛 이미지**다(0003 이 없다). 다시 굽고 싣는다:"
      cmd "bash $0 --force-load"
    fi
    for t in $MIG_TAGS; do
      printf '%s\n' "$OUT_SQL" | grep -q "/$t\.sql$" \
        && ok "$t.sql 있다" || bad "$t.sql 이 없다 — 옛 이미지다"
    done
    OUT_J=$("$DOCKER" run --rm --entrypoint sh "$TAG_IMPTOOLS" \
            -c 'cat /app/drizzle/meta/_journal.json 2>/dev/null' 2>&1)
    N_J=$(printf '%s\n' "$OUT_J" | grep -c '"tag"')
    [ "$N_J" = "$N_MIG_SQL_WANT" ] && ok "_journal.json 의 tag 가 ${N_J}줄이다" \
      || bad "_journal.json 의 tag 가 ${N_MIG_SQL_WANT}줄이 아니다 (${N_J}줄)"
    for t in $MIG_TAGS; do
      printf '%s\n' "$OUT_J" | grep -q "$t" \
        && ok "_journal 에 $t 가 있다" || bad "_journal 에 $t 가 없다"
    done
  else
    bad "$TAG_IMPTOOLS 가 아직 NAS 에 없다 — 안을 셀 수 없다"
    cmd "bash $0 --preload"
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

  # ── 1-ㅁ. compose — 태그 넷 · 🔴 건드리지 않는 셋 ───────────────────
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
  say "  올라가는 넷:"
  see_tag app-meters         "$TAG_METERS"   계측기
  see_tag app-improvements   "$TAG_IMP"      개선요청
  see_tag tools-improvements "$TAG_IMPTOOLS" 개선요청도구
  see_tag app-po             "$TAG_PO"       PO
  # 🔴 건드리지 않기로 한 셋. 여기가 흔들렸으면 **남의 커밋이 섞인 것**이다 —
  #    두 세션이 같은 저장소를 쓴다(HANDOFF A절). 고치지 말고 먼저 알린다.
  say "  🔴 건드리지 않는 셋 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-auth "$KEEP_AUTH"    "포털 · 그대로"
  see_tag app-as   "$KEEP_AS"      "A/S · 그대로"
  see_tag tools-as "$KEEP_ASTOOLS" "A/S 도구 · 그대로"
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
  # 🔴 이 저장소에는 db:preflight 가 없다. A/S 의 그 자리를 셋이 대신한다.
  step "1-ㅅ. 개선요청 마이그레이션 (읽기만 한다)"
  if "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-app; then
    REG=$(qi "select to_regclass('drizzle.__drizzle_migrations')")
    if [ -n "$REG" ]; then
      N_MIG_NOW=$(qi "select count(*) from drizzle.__drizzle_migrations")
      say "  지금 DB 에 적용된 줄: ${N_MIG_NOW:-?}"
      case "${N_MIG_NOW:-x}" in
        "$N_MIG_BEFORE_WANT") ok "적용 전 상태 그대로다 ($N_MIG_BEFORE_WANT줄) — 0003 하나가 남았다" ;;
        "$N_MIG_WANT")        ok "이미 $N_MIG_WANT줄이다 — 0003 이 이미 들어가 있다(다시 돌려도 안전)" ;;
        *) bad "적용된 줄이 $N_MIG_BEFORE_WANT 도 $N_MIG_WANT 도 아니다 (${N_MIG_NOW:-?})" ;;
      esac
    else
      bad "$IMP_DB 에 drizzle.__drizzle_migrations 가 없다 — 첫 설치가 안 된 DB 다"
    fi
    T_NOW=$(qi "select to_regclass('public.$NEW_TABLE')")
    if [ -n "$T_NOW" ]; then
      say "  · $NEW_TABLE 표가 **이미 있다** — 0003 이 들어간 뒤다"
    else
      say "  · $NEW_TABLE 표가 아직 없다 — 0003 이 그것을 만든다(맞다)"
    fi
  else
    bad "dss-pg-app 이 떠 있지 않다 — 마이그레이션 상태를 못 봤다"
  fi
  # 이미지 안의 0003 을 **읽어서** 지우는 문장이 있는지 본다 (preflight 대신)
  if have_img "$TAG_IMPTOOLS"; then
    SQL0003=$("$DOCKER" run --rm --entrypoint sh "$TAG_IMPTOOLS" \
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
  # tar 넷이 약 516MB, 실은 이미지가 또 그만큼, 덤프가 더 든다.
  if [ "${FREE_KB:-0}" -ge 5000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (tar 넷 약 516MB + 실은 이미지 + 덤프)"
  fi
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
  echo "DSS 여덟째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     사이트 셋을 옛 태그로 내리는 일이다:"
  say "       $TAG_METERS → $OLD_METERS"
  say "       $TAG_IMP → $OLD_IMP"
  say "       $TAG_IMPTOOLS → $OLD_IMPTOOLS"
  say "       $TAG_PO → $OLD_PO"

  step "1. 옛 이미지가 아직 NAS 에 있는지 먼저 본다"
  for t in "$OLD_METERS" "$OLD_IMP" "$OLD_IMPTOOLS" "$OLD_PO"; do
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
  cmd "sed -i 's|$TAG_METERS|$OLD_METERS|' \$F"
  cmd "sed -i 's|$TAG_IMP|$OLD_IMP|' \$F"
  cmd "sed -i 's|$TAG_IMPTOOLS|$OLD_IMPTOOLS|' \$F"
  cmd "sed -i 's|$TAG_PO|$OLD_PO|' \$F"
  say
  say "  ⚠️ 위 넷 중 개선요청 둘은 글자가 겹친다 — dss-improvements:0.2 를 먼저"
  say "     바꿔야 dss-improvements-tools:2 가 안 흔들린다. 위 차례 그대로 치세요."

  step "3. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "D1=/usr/local/bin/docker"
  say "  (2단계에서 F 를 이미 정했으면 아래 두 줄은 건너뜁니다.)"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-meters"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-improvements"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-po"
  script_file_hint "12-rollback"

  step "4. 마이그레이션 — 🔴 **되돌리지 않는다**"
  say "  0003 은 표를 하나 **더하기만** 한다($NEW_TABLE)."
  say "  옛 판(0.1)은 그 표를 모르고, 모르는 표는 옛 판을 방해하지 않는다."
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
  for c in dss-meters dss-improvements dss-po; do
    say "  $c : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$c " || echo '안 돌고 있다')"
  done
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터 check · preload · force-load · go ═════════════════════════
echo "DSS 여덟째 배포 · $(date '+%F %T')"
echo "  $OLD_METERS → $TAG_METERS · $OLD_IMP → $TAG_IMP"
echo "  $OLD_IMPTOOLS → $TAG_IMPTOOLS · $OLD_PO → $TAG_PO"
echo "  🔴 개선요청 마이그레이션 1개(0003_sad_valkyrie) 를 적용합니다"
echo "  · 포털($KEEP_AUTH) 과 A/S($KEEP_AS) 는 **건드리지 않습니다**"
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**" ;;
  preload)    echo "  🔵 --preload — 이미지 넷을 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — 마이그레이션을 적용하고 사이트 셋을 교체한다."
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(폴더 권한 · 백업)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
#    이미지를 싣는 것은 **아무것도 안 멈춘다.**
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "이미지 tar 넷 · 지문"
  EXP_METERS=$(tar_config_id   "$TAR_METERS"   2>/dev/null) || EXP_METERS=""
  EXP_IMP=$(tar_config_id      "$TAR_IMP"      2>/dev/null) || EXP_IMP=""
  EXP_IMPTOOLS=$(tar_config_id "$TAR_IMPTOOLS" 2>/dev/null) || EXP_IMPTOOLS=""
  EXP_PO=$(tar_config_id       "$TAR_PO"       2>/dev/null) || EXP_PO=""
  for rec in "$TAG_METERS|$TAR_METERS|$EXP_METERS|$SZ_METERS|$MD5_METERS" \
             "$TAG_IMP|$TAR_IMP|$EXP_IMP|$SZ_IMP|$MD5_IMP" \
             "$TAG_IMPTOOLS|$TAR_IMPTOOLS|$EXP_IMPTOOLS|$SZ_IMPTOOLS|$MD5_IMPTOOLS" \
             "$TAG_PO|$TAR_PO|$EXP_PO|$SZ_PO|$MD5_PO"; do
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

  step "$TAG_IMPTOOLS 안의 마이그레이션 넷 (태그만으로는 안심할 수 없다)"
  if have_img "$TAG_IMPTOOLS"; then
    say "  구운 때: $("$DOCKER" images "$TAG_IMPTOOLS" --format '{{.CreatedAt}}' 2>/dev/null)"
    OUT_SQL=$("$DOCKER" run --rm --entrypoint sh "$TAG_IMPTOOLS" \
              -c 'ls -1 /app/drizzle/*.sql 2>/dev/null' 2>&1)
    printf '%s\n' "$OUT_SQL" | sed 's/^/      /' | head -10
    N_SQL=$(printf '%s\n' "$OUT_SQL" | grep -c '\.sql$')
    [ "$N_SQL" = "$N_MIG_SQL_WANT" ] && ok "마이그레이션 .sql 이 ${N_SQL}개다" \
      || bad "마이그레이션 .sql 이 ${N_MIG_SQL_WANT}개가 아니다 (${N_SQL}개) — 옛 이미지다"
    OUT_J=$("$DOCKER" run --rm --entrypoint sh "$TAG_IMPTOOLS" \
            -c 'cat /app/drizzle/meta/_journal.json 2>/dev/null' 2>&1)
    N_J=$(printf '%s\n' "$OUT_J" | grep -c '"tag"')
    [ "$N_J" = "$N_MIG_SQL_WANT" ] && ok "_journal.json 의 tag 가 ${N_J}줄이다" \
      || bad "_journal.json 의 tag 가 ${N_MIG_SQL_WANT}줄이 아니다 (${N_J}줄)"
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
    echo "  ✅ 이어서 (앱이 잠깐 멈춥니다):  bash $0 --go"
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
step "2. 이미지 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
bring_img "$TAG_METERS"   "$TAR_METERS"   "$EXP_METERS"   || FAIL2=1
bring_img "$TAG_IMP"      "$TAR_IMP"      "$EXP_IMP"      || FAIL2=1
bring_img "$TAG_IMPTOOLS" "$TAR_IMPTOOLS" "$EXP_IMPTOOLS" || FAIL2=1
bring_img "$TAG_PO"       "$TAR_PO"       "$EXP_PO"       || FAIL2=1
if [ "${FAIL2:-0}" = 1 ]; then
  say
  say "  🔴 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
fi

# ══ 3. 🔴 마이그레이션 — 여기가 되돌리기 어려운 자리다 ═════════════════
#
# 🔴 A/S 의 db:preflight 에 해당하는 것이 이 저장소에는 없다. 그 자리를 셋이
#    대신한다: ① 오늘 백업을 **작업 직전에 다시** 본다 ② 지금 적용된 줄 수를
#    센다 ③ 20초를 준다. (0003 은 CREATE TABLE 하나라 자료가 사라지지 않는다 —
#    1-ㅅ 이 그 SQL 을 실제로 읽어 확인했다.)
step "3. 🔴 개선요청 마이그레이션 — 적용 직전 확인"
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

# ══ 4. 사이트 셋 교체 — 🔴 여기부터 정지 창 ════════════════════════════
#
# 🔴 인자 없이 `up -d` 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다(포털·A/S 까지 흔들린다).
#    셋을 하나씩 부르고 하나씩 대답을 기다린다.
step "4. 사이트 셋 교체  ⏱ 여기부터 직원이 잠깐 못 쓴다 (포털·A/S 는 그대로)"
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"

say "  4-ㄱ. 계측기 ($TAG_METERS)"
"${COMPOSE[@]}" up -d --no-deps app-meters 2>&1 | sed 's/^/    /'
wait_http "계측기" 13300 / dss-meters

say "  4-ㄴ. 개선요청 ($TAG_IMP)"
"${COMPOSE[@]}" up -d --no-deps app-improvements 2>&1 | sed 's/^/    /'
wait_http "개선요청" 13500 / dss-improvements

say "  4-ㄷ. PO / 내자 ($TAG_PO)"
"${COMPOSE[@]}" up -d --no-deps app-po 2>&1 | sed 's/^/    /'
wait_http "PO / 내자" 13600 / dss-po

UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 5. 스모크 ══════════════════════════════════════════════════════════
step "5. 스모크 — 폴더 · 알림 통로 · 바깥 주소"

# ② 새 컨테이너로 폴더를 **실제로 열어 본다.** 이번엔 쓰기까지 본다.
say "  5-ㄱ. 폴더를 새 컨테이너 안에서 실제로 연다 (읽기 + 쓰기)"
probe_svc app-improvements dss-improvements 개선요청 "/data/uploads:rw" "$UP_IMP"
probe_svc app-meters       dss-meters       계측기   "/data:rw"         "$MF_METERS"
probe_svc app-po           dss-po           PO       "/data:rw /templates:ro" "$ATT $TEMPLATES"

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

# 🔴 이번 배포의 핵심 — 포털이 물어볼 통로가 생겼는가.
say "  5-ㄷ. 🔴 알림 통로 — 포털 $KEEP_AUTH 가 묻는 자리"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 \
       http://127.0.0.1:13500/api/integration/notifications 2>/dev/null)
case "$code" in
  404) bad "개선요청의 /api/integration/notifications 가 404 다 — **옛 이미지다**" ;;
  000|"") bad "개선요청의 알림 통로가 대답하지 않는다 (${code:-없음})" ;;
  *)   ok "개선요청의 알림 통로가 있다 (토큰 없이 부르면 401 이 맞다 — 지금 $code)" ;;
esac
say "      ⚠️ 계측기·PO 에는 이 통로가 없다(두 저장소에 그 폴더가 없다). 찾지 않는다."

say "  5-ㄹ. 바깥 주소"
for h in meters improvements po; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code" ;;
    *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
  esac
done
# 🔴 건드리지 않기로 한 둘이 그대로인지 본다. 흔들렸으면 이 배포가 건드린 것이다.
for h in login as; do
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
   2. 🔴 **머리말의 알림 종** — 다른 시스템의 밀린 일이 보입니까
      (이번 배포의 핵심입니다. 종이 비어 있어도 오류가 아닙니다 —
       밀린 일이 없으면 비는 것이 맞습니다.)
   3. 🔴 **A/S 나 계측기의 종에 개선요청 알림이 섞여 보입니까**
      (9/18 판에는 통로가 없어 포털이 조용히 빈 목록을 받고 있었습니다.
       이번에 짝이 맞습니다.)
   4. 스크린샷을 **끌어다 놓아** 올려집니까 (새 글 폼 · 목록 줄)
   5. 지운 첨부를 되살릴 수 있습니까
   6. 올린 파일이 NAS 폴더에 보입니까:
        find /volume1/dss/improvements-uploads -type f | tail -3
   7. https://meters.dss21.co.kr — 머리말 종 · 탭 아이콘(회사 로고)
   8. https://po.dss21.co.kr — 견적서 목록 · 발행 · [폴더 열기]
   9. 🔴 **포털과 A/S 가 그대로입니까** — 이번 배포는 그 둘을 건드리지
      않았습니다. 이상하면 남의 변경이 섞인 것입니다.

🔴 사람이 이어서 할 일:
  · 직원에게 알립니다 — 「알림 종이 이제 세 사이트에서 함께 보인다」.
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.

되돌리기 안내:  bash $0 --rollback
ANNOUNCE
exit "$FAIL"
