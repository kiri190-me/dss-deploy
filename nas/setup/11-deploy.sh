#!/bin/bash
# /volume1/dss/setup/11-deploy.sh — 2026-09-28 배포
#   (A/S 1.6 → 1.7 · 도구 dss-as-tools:1 다시 굽기 · 포털 1.4 → 1.5 ·
#    🔴 PO / 내자 dss-po:0.1 **첫 배포** · 그리고 연락서 469장 이식)
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지 먼저!
#   (NAS)         bash /volume1/dss/setup/11-deploy.sh            ← 읽기만 한다
#
# ══ 🔴 10-deploy.sh 와 다른 점 — 기본값이 뒤집혔다 ═════════════════════
#
#   10-deploy.sh 는 **인자 없이 돌리면 배포**였다(앱을 멈추고 마이그레이션을
#   돌렸다). 이번에는 다르다 — **인자 없이 돌리면 `--check`, 즉 읽기만 한다.**
#
#   까닭 셋:
#     ① 이번 배포에는 **없던 사이트(PO)가 생긴다.** 실수로 한 번 돌아가면
#        되돌리는 것이 태그를 내리는 일이 아니라 「띄운 것을 내리는 일」이다.
#     ② 같은 창구에서 **연락서 469장이 운영 DB 에 들어간다.** 코드와 달리
#        들어간 자료는 남는다. 그래서 스크립트는 **그것을 넣지 않는다** —
#        계획을 읽고 승인하는 것은 사람의 일이고, 여기서는 명령만 찍어 준다.
#     ③ 이 파일은 `runbook/11-배포-점검표.html` 을 **기계가 대신 해 주는 것**이다.
#        점검표는 원래 「보는」 문서다. 보는 것이 기본이어야 맞는다.
#
#   그래서 이 스크립트를 실수로 그냥 돌려도 **아무것도 바뀌지 않는다.**
#   (로그 파일 하나만 `setup/logs/` 에 남는다 — 10 과 같은 관행이다.)
#
# ── 모드 여덟 ───────────────────────────────────────────────────────────
#   (없음) · --check          읽기만 한다. 아무것도 안 바꾸고 안 멈춘다   ← 기본값
#   --preload                 이미지 넷을 싣고 지문을 맞춘다. 안 멈춘다
#   --go                      포털 교체 → A/S 교체 → **연락서 안내를 찍고 멈춘다**
#   --go --po                 그다음에 부른다. PO 를 띄운다(첫 기동)
#   --kyosan-verify <회차>    연락서 이식 결과를 SQL 로 본다(읽기만)
#   --grant-preview           PO 권한을 **누가 받게 되는지**만 본다(읽기만)
#   --grant <주는사람메일>    🔴 **이 모드만 DB 에 쓴다.** PO 권한을 넣는다
#   --rollback                태그 되돌리기 안내 + PO 내리기
#
# ── 🔴 순서 — 연락서가 먼저, PO 가 나중 ────────────────────────────────
#
#   1) bash 11-deploy.sh                      (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 11-deploy.sh --preload            (이미지만 미리 실어 둔다)
#   3) bash 11-deploy.sh --go                 (포털 · A/S 교체 → 여기서 멈춘다)
#   4) 사람이 연락서 계획을 돌리고 읽고 승인하고 --apply 한다 (3 이 명령을 찍어 준다)
#   5) bash 11-deploy.sh --kyosan-verify <회차>
#   6) 🔴 **확인 게이트** — 연락서가 탈 없이 들어간 것을 본 뒤에만
#   7) bash 11-deploy.sh --go --po            (PO 첫 기동)
#
#   합치지 않는 까닭: 문제가 났을 때 **어느 쪽 탓인지 못 가린다**
#   (runbook/09 머리말 · 2026-09-28 사용자 결정).
#
# ── 🔴 PO 는 앞의 넷과 근본이 다르다 ───────────────────────────────────
#
#   · **DB 를 새로 만들지 않는다.** A/S 와 같은 `dss_as` 를 같은 롤 `dss_app`
#     으로 본다. 그래서 PO 에는 마이그레이션이 없다.
#   · **첨부 폴더도 A/S 와 같은 것**(`/volume1/dss/as-attachments`)을 쓴다.
#     같은 `attachments` 표를 보는데 표에는 **상대 경로만** 있어서, 폴더를
#     나누면 서로의 파일을 못 찾는다.
#   · **도구 이미지(tools-po)가 없다.** 야간 완전삭제는 `tools-as` 가 계속
#     맡고, 같은 표라 그것이 PO 의 휴지통도 함께 비운다.
#   이 셋이 이 배포의 핵심이라 1-ㅁ 절이 compose 에서 **글자로 대조**한다.
#
# ── 🔴 되돌리기 — 셋이 서로 다르다 ─────────────────────────────────────
#
#   A/S · 포털 : 태그를 내리고 다시 띄운다. 이번 배포에는 **자료를 지우는
#     마이그레이션이 없다**(있으면 1-ㅊ 의 preflight 가 말해 준다).
#       bash /volume1/dss/setup/11-deploy.sh --rollback   ← 명령을 찍어 준다
#
#   PO : 띄운 것을 내리면 끝이다. 🔴 **DB 와 첨부 폴더는 건드리지 않는다** —
#     PO 가 올린 파일은 A/S 에서도 그대로 보인다(같은 표 · 같은 폴더).
#     지우면 A/S 쪽 화면이 깨진다.
#
#   연락서 : 🔴 **자동으로 되돌리지 않는다.** 회차 번호를 이 스크립트가 모른다
#     (사람이 종이에 적은 값이다). `--rollback` 이 명령을 찍어 주면 사람이
#     회차 번호를 넣어 돌린다. 계획이 기본이고 `--apply` 를 붙여야 지운다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
TODAY=$(date +%F)
CF=$D/deploy/docker-compose.nas.yml
INCOMING=$D/setup/incoming/docker-compose.nas.yml
ENV_NAS=$D/deploy/.env.nas
PO_ENV=$D/deploy/env/po.env
TEMPLATES=$D/as-templates
IMAGES=$D/images
ATT=$D/as-attachments
BKD=$D/backups

# ── 이번에 올라가는 것 ─────────────────────────────────────────────────
TAG_AUTH=dss-auth:1.5
TAG_AS=dss-as:1.7
TAG_TOOLS=dss-as-tools:1
TAG_PO=dss-po:0.1
# 되돌릴 자리 (지금 도는 것)
OLD_AUTH=dss-auth:1.4
OLD_AS=dss-as:1.6
# 🔴 이번 tar 는 `.tar` 다 — 이 저장소의 지난 배포들은 `.tar.gz` 였다.
#    runbook/11 1단계가 `docker save … -o *.tar` 로 적어 두었고 압축을 걸지
#    않았다. tar_config_id() 가 둘 다 읽게 고쳐 둔 까닭이 이것이다(아래).
TAR_AUTH=$IMAGES/dss-auth-1.5.tar
TAR_AS=$IMAGES/dss-as-1.7.tar
TAR_TOOLS=$IMAGES/dss-as-tools-1.tar
TAR_PO=$IMAGES/dss-po-0.1.tar

# ── 연락서 이식이 쓰는 것 ──────────────────────────────────────────────
KYO_CONV=$D/kyosan-converted
N_CONV_WANT=143            # 2026-09-28 개발 PC 실측
BYTES_CONV_WANT=436850078  # 같은 실측. 개수만 보면 파생 파일이 빠진 것을 놓친다

# ── po.env 에 **있어야 하는** 이름 열여섯 ──────────────────────────────
# 🔴 값은 절대 찍지 않는다. 이름이 있다/없다만 본다(10-deploy.sh 1-ㄹ 과 같다).
PO_ENV_WANT="AUTH_SESSION_SECRET SESSION_COOKIE_SECURE SESSION_HOURS
SSO_ISSUER SSO_CLIENT_ID SSO_CLIENT_SECRET SSO_REDIRECT_URI SSO_TX_SECRET
QUOTE_TEMPLATE_PATH OH_QUOTE_TEMPLATE_PATH MATCHER_QUOTE_TEMPLATE_PATH
MATCHER_OH_QUOTE_TEMPLATE_PATH CABLE_QUOTE_TEMPLATE_PATH
QUOTE_ARCHIVE_DIR QUOTE_ARCHIVE_UNC_ROOT AS_APP_BASE_URL"
# ── po.env 에 **있으면 안 되는** 이름 셋 ───────────────────────────────
# compose 와 이미지가 넘긴다. 두 곳에 있으면 언젠가 한쪽만 바뀌는데,
# 그때 앱은 오류를 내지 않고 **조용히 다른 DB·다른 폴더를 본다.**
PO_ENV_FORBID="DATABASE_URL UPLOADS_DIR PORT"

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값은 check 다. 인자 없이 돌아가도 아무것도 바뀌지 않는다(머리말).
MODE=check; WITH_PO=0; BATCH=""; GRANT_EMAIL=""
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 11-deploy.sh                    읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 11-deploy.sh --check            위와 같습니다
  bash 11-deploy.sh --preload          이미지 넷을 싣고 지문만 맞춥니다 (안 멈춥니다)
  bash 11-deploy.sh --go               포털 · A/S 교체 → 연락서 안내를 찍고 멈춥니다
  bash 11-deploy.sh --go --po          그다음에 — PO / 내자를 띄웁니다 (첫 기동)
  bash 11-deploy.sh --kyosan-verify <회차>   연락서 이식 결과를 봅니다 (읽기만)
  bash 11-deploy.sh --grant-preview    누가 받게 되는지 봅니다 (읽기만)
  bash 11-deploy.sh --grant <메일>     🔴 PO 명단에 넣습니다 (DB 에 씁니다)
  bash 11-deploy.sh --rollback         되돌리기 안내 + PO 내리기
USAGE
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)          MODE=check ;;
    --preload)        MODE=preload ;;
    --go)             MODE=go ;;
    --po)             WITH_PO=1 ;;
    --rollback)       MODE=rollback ;;
    --grant-preview)  MODE=grant-preview ;;
    --kyosan-verify)
      shift
      BATCH="${1:-}"
      [ -n "$BATCH" ] || { echo "🔴 --kyosan-verify 뒤에 회차 번호를 붙이세요."; usage; exit 2; }
      MODE=kyosan-verify ;;
    --grant)
      shift
      GRANT_EMAIL="${1:-}"
      # 🔴 메일이 없으면 아무것도 하지 않는다. granted_by 칸이 NOT NULL 이라
      #    「누가 줬는가」 없이는 한 줄도 못 넣는다 — 그 칸이 곧 기록이다.
      [ -n "$GRANT_EMAIL" ] || { echo "🔴 --grant 뒤에 **주는 사람의 메일**을 붙이세요."; usage; exit 2; }
      MODE=grant ;;
    -h|--help)        usage; exit 0 ;;
    *) echo "모르는 인자: $1"; usage; exit 2 ;;
  esac
  shift
done
if [ "$WITH_PO" = 1 ] && [ "$MODE" != go ]; then
  echo "🔴 --po 는 --go 와 함께만 씁니다:  bash $0 --go --po"
  exit 2
fi

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/11-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 10-deploy.sh 의 것을 그대로 쓴다 ──────────────────────────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

COMPOSE=("$DOCKER" compose -f "$CF" --env-file "$ENV_NAS" --profile tools)
# 아직 갈아 끼우지 않은 compose 를 **시험만** 해 볼 때 쓴다.
compose_at() { # 1 compose파일  나머지: compose 에 넘길 인자
  local f="$1"; shift
  "$DOCKER" compose --project-directory "$D/deploy" -f "$f" --env-file "$ENV_NAS" --profile tools "$@"
}

# ── DB 도우미 — 🔴 **DB 가 둘이다.** 이름을 갈라 둔다 ──────────────────
#   q  · qq   : dss-pg-app  / dss_as    (A/S 와 PO 가 **함께** 보는 DB)
#   qa · qqa  : dss-pg-auth / dss_auth  (포털. clients · users · 명단)
# 🔴 이 스크립트의 SQL 은 **--grant 하나를 빼고 전부 SELECT 다.**
#    그 예외는 아래 「PO 명단」 절 머리말에 따로 적어 두었다.
q()   { "$DOCKER" exec dss-pg-app  sh -c "psql -U \"\$POSTGRES_USER\" -d dss_as   -Atc \"$1\"" 2>/dev/null; }
qq()  { "$DOCKER" exec dss-pg-app  sh -c "psql -U \"\$POSTGRES_USER\" -d dss_as   -c   \"$1\"" 2>/dev/null; }
qa()  { "$DOCKER" exec dss-pg-auth sh -c "psql -U \"\$POSTGRES_USER\" -d dss_auth -Atc \"$1\"" 2>/dev/null; }
qqa() { "$DOCKER" exec dss-pg-auth sh -c "psql -U \"\$POSTGRES_USER\" -d dss_auth -c   \"$1\"" 2>/dev/null; }
# 쓰는 질의는 **오류를 삼키지 않는다** — 무엇이 막혔는지 사람이 봐야 한다.
qa_write() { "$DOCKER" exec dss-pg-auth sh -c "psql -U \"\$POSTGRES_USER\" -d dss_auth -v ON_ERROR_STOP=1 -Atc \"$1\""; }

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 개발 PC 의 `docker image inspect --format {{.Id}}` 가 아니라 **이 값**이
#    NAS 에 실렸을 때의 image ID 가 된다(09-16 에 여기서 헛걸음했다 —
#    README 「다음 배포 때」 2번). 2026-09-28 개발 PC 에서 다시 확인했다:
#    dss-po-0.1.tar 의 Config 는 fd162fe4… 인데 개발 PC 의 .Id 는 eaa99b12… 로
#    **서로 다르다.** 대조는 반드시 tar 쪽 값으로 한다.
#
# 🔴 10-deploy.sh 에서 **고친 곳** — 그 판은 `tar -xzOf`(gzip 전제) 하나뿐이었다.
#    이번 tar 넷은 `docker save … -o *.tar` 로 만든 **비압축**이라 그대로 쓰면
#    `gzip: stdin: not in gzip format` 으로 조용히 빈 값이 나온다. 그래서
#    **비압축을 먼저 시도하고 안 되면 gzip 으로 다시 읽는다.** 둘 다 되므로
#    다음 배포가 `.tar.gz` 로 돌아가도 이 함수는 그대로 쓸 수 있다.
#
# ⚠️ 요즘 docker 의 manifest 는 `"Config":"blobs/sha256/<지문>"` 이고 옛 판은
#    `"<지문>.json"` 이다. 아래 두 줄이 그 둘을 다 걷는다.
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

# 🔴 10-deploy.sh 의 verify_img 는 「이미지 안에 표식 글자가 있는가」까지 봤다
#    (`grep -rq dss-menu /app/.next`). 이번에는 **그 검사를 넣지 않았다** —
#    이번 판에만 있는 글자를 고르려면 새 소스를 눈으로 짚어 정해야 하는데,
#    잘못 고르면 **멀쩡한 이미지를 실패로 센다.** 대신 도구 이미지에는 훨씬
#    단단한 검사가 따로 있다(1-ㄷ — 러너 파일 넷이 실제로 있는가).
verify_img() { # 1 태그 2 기대지문
  local got
  got=$("$DOCKER" image inspect "$1" --format '{{.Id}}' 2>/dev/null)
  if [ "$got" != "$2" ]; then
    bad "$1 지문이 tar 와 다르다 (NAS ${got:-없음} / tar $2)"
    return 1
  fi
  ok "$1 지문 맞음 ($(echo "$2" | cut -c1-19)…)"
}
bring_img() { # 1 태그 2 tar 3 지문
  if have_img "$1"; then
    say "  · $1 는 이미 실려 있다 — 다시 싣지 않는다"
  else
    "$DOCKER" load -i "$2" >/dev/null 2>&1 && ok "$1 실었다" || { bad "$1 싣기 실패 ($2)"; return 1; }
  fi
  verify_img "$1" "$3"
}
wait_http() { # 1 이름 2 포트 3 경로 4 컨테이너
  local i code
  for i in $(seq 1 90); do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://127.0.0.1:$2$3" 2>/dev/null)
    case "$code" in 2??|3??) ok "$1 응답 $code ($((SECONDS - T0))초)"; return 0 ;; esac
    sleep 2
  done
  bad "$1 이 180초 안에 대답하지 않았다 (마지막 ${code:-없음})"
  say "    로그: $DOCKER logs --tail 50 $4"
  return 1
}

# ── compose 파일에서 서비스 한 덩어리만 잘라 낸다 ──────────────────────
# 🔴 파일 전체를 grep 하면 안 된다. 「tools-as 에 연락서 볼륨이 붙었는가」를
#    물을 때 다른 서비스에 붙은 같은 글자가 잡히고, 더 나쁜 것은 **주석**이다 —
#    `app-po` 는 지금 통째로 주석으로 꺼져 있어서 주석까지 세면 「벗기지
#    않았는데 벗긴 것」으로 읽힌다(10-deploy.sh 1-ㄴ 이 개선요청에서 겪은 함정).
#    들여쓰기 두 칸 서비스 이름부터 다음 서비스 직전까지만 자르고 주석을 뺀다.
svc_block() { # 1 compose파일 2 서비스이름
  awk -v s="  $2:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$1" | sed '/^[[:space:]]*#/d'
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
#     runbook/11-배포-점검표.html 의 항목을 순서대로 옮긴 것이다.
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)

run_checks() {
  # ── 1-ㄱ. 이미지 tar 넷과 그 지문 ────────────────────────────────────
  step "1-ㄱ. 이미지 tar — 넷이다"
  EXP_AUTH=$(tar_config_id  "$TAR_AUTH"  2>/dev/null) || EXP_AUTH=""
  EXP_AS=$(tar_config_id    "$TAR_AS"    2>/dev/null) || EXP_AS=""
  EXP_TOOLS=$(tar_config_id "$TAR_TOOLS" 2>/dev/null) || EXP_TOOLS=""
  EXP_PO=$(tar_config_id    "$TAR_PO"    2>/dev/null) || EXP_PO=""
  see_tar() { # 1 태그 2 tar 3 지문
    [ -s "$2" ] || { bad "$1 의 tar 가 없다: $2"; return 1; }
    [ -n "$3" ] || { bad "$1 의 tar 에서 manifest.json 을 읽지 못했다: $2"; return 1; }
    ok "$1 · tar $(du -h "$2" | cut -f1) · 기대 지문 $(echo "$3" | cut -c1-19)…"
  }
  see_tar "$TAG_AUTH"  "$TAR_AUTH"  "$EXP_AUTH"
  see_tar "$TAG_AS"    "$TAR_AS"    "$EXP_AS"
  see_tar "$TAG_TOOLS" "$TAR_TOOLS" "$EXP_TOOLS"
  see_tar "$TAG_PO"    "$TAR_PO"    "$EXP_PO"

  # ── 1-ㄴ. 이미 실려 있는 것은 **지금** 대조한다 ──────────────────────
  # 앱이 살아 있는 동안 보는 것이 싸다. 아직 없으면 --preload 나 --go 가 싣는다.
  step "1-ㄴ. NAS 에 실린 이미지의 지문"
  for rec in "$TAG_AUTH|$EXP_AUTH" "$TAG_AS|$EXP_AS" "$TAG_TOOLS|$EXP_TOOLS" "$TAG_PO|$EXP_PO"; do
    tag=${rec%%|*}; exp=${rec##*|}
    if have_img "$tag"; then
      [ -n "$exp" ] && verify_img "$tag" "$exp"
    else
      say "  · $tag 는 아직 NAS 에 없다 — --preload 나 --go 가 싣는다"
    fi
  done
  # 🔴 넷 중 dss-as-tools:1 이 가장 위험하다. **태그가 예전 것과 같아서**
  #    `docker images` 로는 옛것과 구별이 안 된다. 지문이 다르면 「굽기는
  #    했는데 NAS 에 안 올라간 것」이고, 그러면 연락서 러너가 없다.
  say "  🔴 위 넷 중 $TAG_TOOLS 를 특히 보라 — 태그가 예전 것과 같아 눈으로는 구별이 안 된다."

  # ── 1-ㄷ. 🔴 도구 이미지에 연락서 러너가 실제로 들어 있는가 ──────────
  # 지문이 맞아도 한 번 더 본다. 사람이 읽을 수 있는 증거가 이것뿐이다.
  # (runbook/09 3-ㄴ · 점검표 4단계의 그 항목)
  step "1-ㄷ. $TAG_TOOLS 안의 연락서 러너 넷"
  if have_img "$TAG_TOOLS"; then
    say "  구운 때: $("$DOCKER" images "$TAG_TOOLS" --format '{{.CreatedAt}}' 2>/dev/null)"
    for f in /app/scripts/import-kyosan-reports.ts \
             /app/scripts/revert-kyosan-import.ts \
             /app/scripts/lib/kyosan-import-run.ts \
             /app/scripts/lib/kyosan-import-revert.ts; do
      if "$DOCKER" run --rm --entrypoint sh "$TAG_TOOLS" -c "test -f $f" >/dev/null 2>&1; then
        ok "$f 있다"
      else
        bad "$f 가 없다 — **옛 이미지다**(2026-09-16 것). 다시 굽고 load 하세요"
      fi
    done
  else
    bad "$TAG_TOOLS 가 아직 NAS 에 없다 — 러너를 확인할 수 없다"
  fi

  # ── 1-ㄹ. po.env — 🔴 **값은 절대 찍지 않는다. 이름만 본다** ─────────
  # 10-deploy.sh 1-ㄹ 이 as.env 를 보던 것과 같은 방식이다. 이 파일에는
  # 세션 비밀값과 SSO 시크릿이 들어 있어 한 줄도 화면에 내보내지 않는다.
  step "1-ㄹ. env/po.env (PO 첫 배포 · 이름만 본다)"
  if [ -f "$PO_ENV" ]; then
    ok "po.env 가 있다"
    PERM=$(stat -c '%a' "$PO_ENV" 2>/dev/null)
    OWN=$(stat -c '%U:%G' "$PO_ENV" 2>/dev/null)
    [ "$PERM" = 600 ] && ok "모드 600" || bad "모드가 ${PERM:-?} 다 (600 이어야 한다 — 남이 읽는다)"
    [ "$OWN" = "root:root" ] && ok "주인 root:root" || bad "주인이 ${OWN:-?} 다 (root:root 이어야 한다)"
    for k in $PO_ENV_WANT; do
      grep -q "^$k=" "$PO_ENV" && ok "po.env 에 $k 가 있다" \
        || bad "po.env 에 $k 가 없다 — 앱이 뜨자마자 그 이름을 찍고 죽는다"
    done
    # 🔴 있으면 안 되는 셋. compose 와 이미지가 넘기는 값이라 두 곳에 있으면
    #    언젠가 한쪽만 바뀌는데, 그때 앱은 **오류 없이** 다른 DB·다른 폴더를 본다.
    for k in $PO_ENV_FORBID; do
      grep -q "^$k=" "$PO_ENV" && bad "po.env 에 $k 가 **있다** — 지우세요(compose 가 넘긴다)" \
        || ok "po.env 에 $k 가 없다 (맞다)"
    done
    # ⚠️ runbook/08 3-ㅁ 은 QUOTE_ARCHIVE_UNC_ROOT_ALT 도 적으라고 한다. 이
    #    스크립트의 「열여섯」에는 들어 있지 않아 **실패로 세지 않고** 알리기만
    #    한다 — 없으면 [폴더 열기]의 둘째 주소만 안 선다(앱은 그대로 돈다).
    if grep -q "^QUOTE_ARCHIVE_UNC_ROOT_ALT=" "$PO_ENV"; then
      say "  · QUOTE_ARCHIVE_UNC_ROOT_ALT 도 있다 (runbook/08 3-ㅁ 이 권한 것)"
    else
      say "  ⚠️ QUOTE_ARCHIVE_UNC_ROOT_ALT 가 없다 — 실패는 아니다. as.env 의 같은 줄을 베끼면 된다"
    fi
  else
    bad "po.env 가 없다: $PO_ENV"
    say "    → 이것이 없는데 compose 의 app-po 를 켜면 **docker compose 명령이 통째로** 안 먹는다."
    say "      멈춘 앱을 다시 띄우지도 못하게 된다 — 먼저 올리세요(runbook/08 3-ㅁ)."
  fi

  # ── 1-ㅁ. compose ────────────────────────────────────────────────────
  step "1-ㅁ. compose ($CF_EFF)"
  if compose_at "$CF_EFF" config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_at "$CF_EFF" config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  # 서비스 목록은 `config --services` 로 본다 — 주석으로 꺼 둔 것은 여기 안 나온다.
  SVCS=$(compose_at "$CF_EFF" config --services 2>/dev/null)
  echo "$SVCS" | grep -qx app-po \
    && ok "서비스 목록에 app-po 가 있다 (주석을 벗겼다)" \
    || bad "서비스 목록에 app-po 가 없다 — 아직 주석으로 꺼져 있다(runbook/08 3-ㅂ)"
  echo "$SVCS" | grep -qx tools-as && ok "서비스 목록에 tools-as 가 있다" \
    || bad "tools-as 가 없다 — 연락서 러너를 돌릴 수 없다"
  # 태그 넷 — 🔴 파일 전체를 grep 하면 안 된다. `# image: dss-po:0.1` 이라는
  #   **주석 줄**이 그대로 걸려서, 아직 꺼져 있는 서비스를 「가리킨다」고 세게
  #   된다. svc_block 이 주석을 걷어 낸 그 서비스 덩어리 안에서만 본다.
  see_tag() { # 1 서비스 2 태그 3 사람이 읽을 이름
    svc_block "$CF_EFF" "$1" | grep -q "image: $2$" \
      && ok "$1 가 $2 를 가리킨다" \
      || bad "$1 의 $3 태그가 $2 가 아니다"
  }
  see_tag app-auth "$TAG_AUTH"  포털
  see_tag app-as   "$TAG_AS"    A/S
  see_tag tools-as "$TAG_TOOLS" 도구
  see_tag app-po   "$TAG_PO"    PO

  # 🔴 이 배포의 핵심 — PO 가 A/S 와 **같은 DB · 같은 첨부 폴더**를 보는가.
  #    글자 하나가 틀리면 앱은 오류 없이 뜨고, 그 상태로 사람이 쓰면
  #    **자료가 두 곳으로 갈라진다**(점검표 6단계 확인표 4·5번).
  #    ⚠️ 값을 찍지 않고 **같은지 다른지만** 말한다.
  AS_DBURL=$(svc_block "$CF_EFF" app-as | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  PO_DBURL=$(svc_block "$CF_EFF" app-po | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  if [ -n "$PO_DBURL" ] && [ "$AS_DBURL" = "$PO_DBURL" ]; then
    ok "app-po 의 DATABASE_URL 이 app-as 와 **글자까지 같다**"
  else
    bad "app-po 의 DATABASE_URL 이 app-as 와 다르다 — 🔴 PO 가 엉뚱한 DB 를 본다"
  fi
  if svc_block "$CF_EFF" app-po | grep -q "$ATT:/data"; then
    ok "app-po 가 A/S 와 **같은 첨부 폴더**($ATT)를 붙인다"
  else
    bad "app-po 의 첨부 볼륨이 $ATT 가 아니다 — 🔴 서로의 파일을 못 찾는다"
  fi
  svc_block "$CF_EFF" app-po | grep -q 'group_add: \["100"\]' \
    && ok "app-po 에 group_add 100 이 있다" \
    || bad "app-po 에 group_add 100 이 없다 — 견적서 발행이 Permission denied 로 끝난다"
  svc_block "$CF_EFF" app-po | grep -q '13600:3600' \
    && ok "app-po 가 127.0.0.1:13600 으로 열린다" \
    || bad "app-po 의 포트가 13600 이 아니다"
  # 🔴 tools-po 를 만들지 않았는가 — 있으면 설계에 없던 것이 들어온 것이다.
  echo "$SVCS" | grep -qx tools-po \
    && bad "tools-po 라는 서비스가 있다 — PO 에는 도구 이미지가 없다(runbook/08 3-ㅂ)" \
    || ok "tools-po 가 없다 (맞다 — PO 에는 마이그레이션도 야간 작업도 없다)"

  # tools-as 에 연락서 볼륨 둘 + group_add
  svc_block "$CF_EFF" tools-as | grep -q '/kyosan-src' \
    && ok "tools-as 에 /kyosan-src 가 붙었다 (원본 360장)" \
    || bad "tools-as 에 /kyosan-src 가 없다 — 러너가 원본을 못 본다(runbook/09 3-ㅁ)"
  svc_block "$CF_EFF" tools-as | grep -q '/kyosan-converted' \
    && ok "tools-as 에 /kyosan-converted 가 붙었다 (변환본 143장)" \
    || bad "tools-as 에 /kyosan-converted 가 없다 — 143장이 통째로 빠진다"
  svc_block "$CF_EFF" tools-as | grep -q 'group_add: \["100"\]' \
    && ok "tools-as 에 group_add 100 이 있다" \
    || bad "tools-as 에 group_add 100 이 없다 — 원본 공유폴더를 ACL 이 막는다"

  # ── 1-ㅂ. 연락서 원본 공유폴더 ───────────────────────────────────────
  # 🔴 **한글을 직접 쓰지 않는다.** 실제 경로는
  #    /volume1/2_AS센터/1. 수리 관련/3. 연락서(활용)/2. 연락서 이고 **AS 가
  #    대문자**다(2026-09-28 실측 — 소문자로 적었다가 No such file or directory
  #    를 만났다. 탐색기에는 2_as센터 로 보이는데 윈도우가 대소문자를 안 가려서다).
  #    게다가 터미널·인코딩을 지나며 한글이 깨진다. 글롭으로 건너뛰면 그 문제가
  #    통째로 사라진다.
  step "1-ㅂ. 연락서 원본 공유폴더 (글롭으로 찾는다 — 한글을 안 친다)"
  KYO_SRC=$(ls -1d /volume1/2_AS*/1.*/3.*/2.* 2>/dev/null | head -1)
  if [ -n "$KYO_SRC" ] && [ -d "$KYO_SRC" ]; then
    ok "원본 폴더를 찾았다 · 파일 $(find "$KYO_SRC" -type f 2>/dev/null | wc -l)개"
    say "    $KYO_SRC"
  else
    bad "원본 폴더를 못 찾았다 (/volume1/2_AS*/1.*/3.*/2.*)"
    say "    → 그 공유가 다른 볼륨에 있는 것이다. DSM 제어판 › 공유 폴더에서 위치를 본다."
    say "    → **추측으로 넘어가지 마라** — 엉뚱한 폴더를 붙이면 러너가 「문서 아님」만"
    say "      잔뜩 세고 끝난다(실패가 아니라 조용한 0건이라 더 헷갈린다)."
  fi

  # ── 1-ㅅ. 변환본 143장 ───────────────────────────────────────────────
  # ⚠️ 개수만 보지 않는다. 총 바이트도 본다 — 파생 파일이 백업에서 빠져 있던
  #    적이 있다. 🔴 크기는 `ls -l` 의 다섯째 칸으로 센다. DSM 의 find 는
  #    `-printf` 를 모를 수 있다(busybox 판).
  step "1-ㅅ. 변환본 143장 ($KYO_CONV)"
  if [ -d "$KYO_CONV" ]; then
    N_CONV=$(find "$KYO_CONV" -type f 2>/dev/null | wc -l)
    B_CONV=$(find "$KYO_CONV" -type f -exec ls -l {} + 2>/dev/null | awk '{s+=$5} END {print s+0}')
    [ "$N_CONV" = "$N_CONV_WANT" ] && ok "장수 $N_CONV" \
      || bad "장수가 $N_CONV_WANT 가 아니다 ($N_CONV) — 올리다 끊겼나요"
    [ "$B_CONV" = "$BYTES_CONV_WANT" ] && ok "총바이트 $B_CONV" \
      || bad "총바이트가 $BYTES_CONV_WANT 가 아니다 ($B_CONV)"
    OWN=$(stat -c '%u:%g' "$KYO_CONV" 2>/dev/null)
    if [ "$OWN" = "1000:1000" ]; then
      ok "폴더 주인 1000:1000 (컨테이너가 읽는다)"
    else
      say "  ⚠️ 폴더 주인이 ${OWN:-?} 다 — 컨테이너(uid 1000)가 못 읽으면 이것부터:"
      say "     chown -R 1000:1000 $KYO_CONV"
    fi
  else
    bad "$KYO_CONV 가 없다 — 변환본 143장을 아직 안 올렸다(점검표 1단계)"
  fi

  # ── 1-ㅇ. 양식 다섯 ──────────────────────────────────────────────────
  # 🔴 po.env 가 **가리키는 이름으로** 본다. 이름이 NAS 의 파일과 글자 하나까지
  #    같아야 하고, 하나라도 못 읽으면 그 종류의 견적서 출력이 통째로 죽는다.
  #    ⚠️ 여기서 읽는 것은 양식 경로 다섯뿐이다 — 비밀값 줄은 손대지 않는다.
  #    (10-deploy.sh 1-ㅁ 이 compose 에서 일곱을 같은 방식으로 세었다.)
  step "1-ㅇ. 견적서 양식 다섯 (PO 는 다섯만 쓴다 — 보고서 둘은 A/S 것이다)"
  if [ -f "$PO_ENV" ]; then
    N_T=0
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      key=${line%%=*}
      p=${line#*=}
      # 따옴표를 씌워 적었을 수도 있어 걷어 낸다
      p=${p%\"}; p=${p#\"}; p=${p%\'}; p=${p#\'}
      case "$p" in
        /templates/*) ;;
        *) bad "$key 가 /templates 로 시작하지 않는다"; continue ;;
      esac
      N_T=$((N_T + 1))
      host="$TEMPLATES/${p#/templates/}"
      [ -f "$host" ] && ok "$key → 파일이 있다" || bad "$key 가 가리키는 파일이 NAS 에 없다: $host"
    done <<EOF
$(grep -E '^[A-Z_]*TEMPLATE_PATH=' "$PO_ENV")
EOF
    [ "$N_T" = 5 ] && ok "po.env 의 양식 경로가 다섯이다" \
      || bad "po.env 의 양식 경로가 다섯이 아니다 ($N_T)"
  else
    bad "po.env 가 없어 양식을 확인하지 못했다"
  fi

  # ── 1-ㅈ. 포털에 PO 가 등록됐는가 ────────────────────────────────────
  # 🔴 인증 DB(dss-pg-auth)를 읽는다. A/S·PO 가 쓰는 dss-pg-app 이 아니다.
  step "1-ㅈ. 포털 등록 (인증 DB — 읽기만 한다)"
  if "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-auth; then
    N_CL=$(qa "select count(*) from clients where client_id = 'dss-po'")
    if [ "${N_CL:-0}" = 1 ]; then
      ok "clients 에 dss-po 가 있다"
      [ "$(qa "select is_active from clients where client_id = 'dss-po'")" = t ] \
        && ok "is_active 가 참이다" || bad "is_active 가 거짓이다 — 로그인이 막힌다"
      if [ "$(qa "select requires_grant from clients where client_id = 'dss-po'")" = t ]; then
        ok "requires_grant 가 참이다 (명단에 있는 사람만 — A/S 와 같다)"
      else
        say "  ⚠️ requires_grant 가 거짓이다 — 전 직원이 들어온다. 정한 값은 참이었다(점검표 2단계)"
      fi
      L=$(qa "select length(client_secret_hash) from clients where client_id = 'dss-po'")
      [ "${L:-0}" = 64 ] && ok "client_secret_hash 가 64글자다 (sha256)" \
        || bad "client_secret_hash 가 64글자가 아니다 (${L:-없음}) — 시크릿을 다시 넣으세요"
      LU=$(qa "select coalesce(launcher_url, '') from clients where client_id = 'dss-po'")
      [ -n "$LU" ] && ok "launcher_url 이 있다 ($LU)" \
        || bad "launcher_url 이 비었다 — 다른 사이트의 **메뉴바에 PO 가 안 뜬다**"
    else
      bad "clients 에 dss-po 가 없다 (${N_CL:-?}건) — 포털 등록을 먼저 하세요(runbook/08 3-ㄹ)"
    fi

    # 🔴 등록만 하고 명단을 안 넣으면 **아무도 못 들어간다.**
    N_GRANT=$(qa "select count(*) from user_client_grants g join clients c on c.id = g.client_id where c.client_id = 'dss-po'")
    if [ "${N_GRANT:-0}" -gt 0 ] 2>/dev/null; then
      ok "PO 명단에 오른 사람 ${N_GRANT}명"
    else
      bad "PO 명단에 오른 사람이 0명이다"
      say "  ╔══════════════════════════════════════════════════════════════╗"
      say "  ║ 🔴 **아무도 PO 에 들어가지 못합니다.**                        ║"
      say "  ╚══════════════════════════════════════════════════════════════╝"
      say "    PO 는 requires_grant = true — 「명단에 있는 사람만」입니다."
      say "    포털 타일에도 안 보이고 로그인도 막힙니다."
      say "    → 누가 받게 되는지 먼저 보기 :  bash $0 --grant-preview"
      say "    → 실제로 넣기               :  bash $0 --grant <주는사람메일>"
    fi
    say "  참고 — A/S(rf-service-system) 명단에 오른 사람: $(qa "select count(*) from user_client_grants g join clients c on c.id = g.client_id where c.client_id = 'rf-service-system'")명"
  else
    bad "dss-pg-auth 가 떠 있지 않다 — 포털 등록을 확인하지 못했다"
  fi

  # ── 1-ㅊ. 마이그레이션 — 읽기만 ──────────────────────────────────────
  # PO 에는 마이그레이션이 없다(스키마의 주인은 A/S 하나뿐이다). 여기서 보는
  # 것은 **A/S 1.7 이 들고 온 것**이다. preflight 는 DB 를 바꾸지 않는다.
  step "1-ㅊ. 마이그레이션 preflight (읽기만 한다)"
  if have_img "$TAG_TOOLS"; then
    "${COMPOSE[@]}" run --rm tools-as npm run db:preflight 2>&1 | sed 's/^/  /'
    PRC=${PIPESTATUS[0]}
    case "$PRC" in
      0) ok "preflight 종료 코드 0 — 적용할 것이 없거나 안전하다" ;;
      1) say "  ⚠️ preflight 종료 코드 1 — **사라질 자료가 있는 항목**이 있다는 뜻이다."
         say "     실패가 아니다. 위 출력을 사람이 읽고, 예정된 것인지 정한다."
         say "     (이 스크립트는 마이그레이션을 **돌리지 않는다** — 사람이 한다:"
         say "      compose … --profile tools run --rm tools-as npm run db:migrate)" ;;
      *) bad "preflight 가 돌지 못했다 (종료 코드 $PRC)" ;;
    esac
  else
    bad "$TAG_TOOLS 가 없어 preflight 를 돌리지 못했다"
  fi

  # ── 1-ㅋ. 백업 — 🔴 **대신 뜨지 않는다** ─────────────────────────────
  # 10-deploy.sh 2단계와 같은 태도다. 사람이 먼저 한 일을 **보기만** 한다.
  # 🔴 이 배포는 운영 DB 에 **자료를 넣는** 첫 작업이다. 코드와 달리 되돌려도
  #    흔적이 남는다 — 백업 없이 시작하지 않는다.
  step "1-ㅋ. 백업 (스크립트가 대신 뜨지 않는다)"
  for db in dss_as dss_auth; do
    f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
    else
      bad "오늘($TODAY) 뜬 $db 백업이 없다"
      say "    → 먼저 이것부터: bash $D/jobs/backup-nightly.sh   (종료 코드 0 이어야 한다)"
    fi
  done
  # 첨부 폴더 — 같은 야간 작업이 rsync 로 함께 거울을 뜬다(jobs/backup-nightly.sh).
  # 🔴 이식이 **연락서 파일을 첨부로 붙인다**(개발 4건에서 84개). 그래서 본다.
  # ⚠️ rsync 는 쌓아 올리기만 해서 「오늘 돌았다」는 자국이 폴더에 안 남는다.
  #    위의 오늘 dss_as 덤프가 곧 그 증거다 — 같은 스크립트가 둘을 함께 한다.
  if [ -d "$BKD/files/as-attachments" ]; then
    ok "첨부 백업 거울이 있다 · 파일 $(find "$BKD/files/as-attachments" -type f 2>/dev/null | wc -l)개"
  else
    bad "첨부 백업 거울이 없다 ($BKD/files/as-attachments)"
  fi

  # ── 1-ㅌ. 디스크 · 도는 것 ───────────────────────────────────────────
  step "1-ㅌ. 디스크 · DB"
  if "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-app && "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-auth; then
    ok "DB 둘 다 떠 있다 (이 배포에서 DB 는 멈추지 않는다)"
  else
    bad "DB 가 떠 있지 않다"
  fi
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  if [ "${FREE_KB:-0}" -ge 5000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (이미지 넷 약 515MB + 변환본 417MB + 덤프가 들어간다)"
  fi
}

# ══════════════════════════════════════════════════════════════════════
#  compose 갈아 끼우기
#
#  🔴 --check 는 **갈아 끼우지 않는다.** 읽기만 한다는 약속이 먼저다. 대신
#     incoming 에 새 파일이 있으면 **그 파일을** 들여다보고, 갈아 끼우는 것은
#     --go 가 한다고 알려 준다. (10-deploy.sh 는 기본이 배포라 1-ㄴ 에서 바로
#     갈아 끼웠다 — 이번에는 기본이 읽기라 그 자리를 모드로 갈랐다.)
#  🔴 바꾸기 **전에** 새 파일을 먼저 시험한다(10-deploy.sh 1-ㄴ 과 같다).
#     없는 env_file 하나면 docker compose 명령이 **통째로** 실패해서, 앱을 멈춘
#     뒤에 그걸 알게 되면 다시 띄우지도 못한다.
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
    say "    → po.env 를 먼저 올리세요(runbook/08 3-ㅁ). 🔴 ㅂ 은 ㅁ 뒤여야 한다."
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
  echo "DSS 되돌리기 · $(date '+%F %T')"
  step "1. PO 를 내린다"
  # 🔴 `down app-po` 로 적지 않는다. compose 판에 따라 서비스 이름을 안 받고
  #    **통째로** 내리는 수가 있다 — 그러면 DB 까지 멈춘다. stop + rm 은
  #    어느 판에서나 그 서비스 하나만 건드린다(볼륨·네트워크는 그대로).
  if "$DOCKER" ps -a --format '{{.Names}}' | grep -qx dss-po; then
    "${COMPOSE[@]}" stop app-po 2>&1 | sed 's/^/  /'
    "${COMPOSE[@]}" rm -f app-po 2>&1 | sed 's/^/  /'
    ok "app-po 내렸다"
  else
    say "  · app-po 가 떠 있지 않다 — 내릴 것이 없다"
  fi
  say
  say "  🔴 **DB 와 첨부 폴더는 건드리지 않았다.** PO 가 올린 파일은 A/S 에서도"
  say "     그대로 보인다(같은 표 · 같은 폴더). 지우면 A/S 쪽 화면이 깨진다."
  say "  🔴 프록시 규칙과 DNS 는 남겨 둬도 해가 없다(닿을 곳이 없으면 502 다)."

  step "2. A/S · 포털 태그를 내린다 — 🔴 아래를 사람이 친다"
  echo "  sed -i 's|$TAG_AS|$OLD_AS|; s|$TAG_AUTH|$OLD_AUTH|' $CF"
  echo "  $DOCKER compose -f $CF --env-file $ENV_NAS up -d --no-deps app-auth app-as"
  say
  say "  ⚠️ 옛 이미지가 NAS 에 아직 있어야 한다. 확인:"
  echo "  $DOCKER image inspect $OLD_AS --format '{{.Id}}'"
  echo "  $DOCKER image inspect $OLD_AUTH --format '{{.Id}}'"

  step "3. 연락서 — 🔴 자동으로 되돌리지 않는다"
  say "  회차 번호를 이 스크립트가 모른다(사람이 종이에 적은 값이다)."
  say "  계획만 (기본 — 한 글자도 안 지운다):"
  echo "  $DOCKER compose -f $CF --env-file $ENV_NAS --profile tools \\"
  echo "    run --rm tools-as npx tsx scripts/revert-kyosan-import.ts --batch <회차>"
  say "  그 계획을 읽고 승인한 뒤에만:"
  echo "  $DOCKER compose -f $CF --env-file $ENV_NAS --profile tools \\"
  echo "    run --rm tools-as npx tsx scripts/revert-kyosan-import.ts --batch <회차> --apply"
  say
  say "  · 파일은 지우지 않고 치워 둔다. 되돌린 뒤에도 원본은 남는다."
  say "  · 회차를 모르면 한 건씩도 된다: --case D210101 · --trace <흔적 id>"
  say "  · 회차 번호를 아주 잃었으면 이것으로 찾는다:"
  qq "select metadata->>'importBatchId' as 회차, count(*) as 흔적, min(created_at) as 처음 from status_change_histories where metadata->>'source' = 'KYOSAN_REPORT' group by 1 order by 3 desc nulls last"
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · 로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 연락서 이식 결과 보기 — 읽기만 한다 ════════════════════════════════
if [ "$MODE" = kyosan-verify ]; then
  # 🔴 회차 번호를 SQL 에 그대로 끼워 넣으므로 글자를 먼저 거른다.
  #    따옴표 하나가 섞이면 질의가 엉뚱하게 갈린다.
  case "$BATCH" in
    *[!A-Za-z0-9._-]*) stop "회차 번호에 쓸 수 없는 글자가 있습니다: $BATCH" ;;
  esac
  echo "DSS 연락서 이식 확인 · $(date '+%F %T')"
  echo "  회차 $BATCH · **읽기만 합니다**"
  "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-app || stop "dss-pg-app 이 떠 있지 않습니다."

  step "1. 이 회차로 들어간 흔적 · 첨부 · 사용 부품"
  # 🔴 이식 흔적은 전용 표가 아니라 status_change_histories 에 있다.
  #    전용 표를 찾으면 없다(2026-09-28 개발 DB 로 확인).
  qq "select count(*) as 흔적, sum(jsonb_array_length(coalesce(metadata->'attachmentIds','[]'::jsonb))) as 첨부, sum(jsonb_array_length(coalesce(metadata->'usedPartIds','[]'::jsonb))) as 사용부품 from status_change_histories where metadata->>'source' = 'KYOSAN_REPORT' and metadata->>'importBatchId' = '$BATCH'"
  N_TRACE=$(q "select count(*) from status_change_histories where metadata->>'source' = 'KYOSAN_REPORT' and metadata->>'importBatchId' = '$BATCH'")
  if [ "${N_TRACE:-0}" -gt 0 ] 2>/dev/null; then
    ok "회차 $BATCH 로 들어간 흔적 ${N_TRACE}건"
  else
    bad "회차 $BATCH 로 들어간 흔적이 없다 — 회차 번호를 잘못 적었을 수 있다"
    say "    → 회차 목록을 본다:"
    qq "select metadata->>'importBatchId' as 회차, count(*) as 흔적, min(created_at) as 처음 from status_change_histories where metadata->>'source' = 'KYOSAN_REPORT' group by 1 order by 3 desc nulls last"
  fi

  step "2. 🔴 회차 번호가 안 실린 흔적"
  # 🔴 보는 법은 「0 인가」가 아니라 **「넣기 전과 뒤가 같은가」**다.
  #    화면(/excel-imports/kyosan-report)으로 한 장씩 넣은 옛 장이 있으면
  #    0 이 아닌 것이 정상이다 — 회차 번호를 싣는 기능이 2026-09-28 에 생겼다
  #    (개발 DB 실측도 4장이 그렇다).
  NOBATCH=$(q "select count(*) from status_change_histories where metadata->>'source' = 'KYOSAN_REPORT' and metadata->>'importBatchId' is null")
  say "  회차 없는 흔적: ${NOBATCH:-?}건"
  say "  🔴 이 수를 **넣기 전 값과 비교**하세요. 같으면 정상입니다."
  say "     늘었다면 그 장들은 --batch 로 되돌려지지 않습니다(손으로 --case <접수번호>)."

  step "3. 갈래별로 훑어보기"
  qq "select action, count(*) from status_change_histories where metadata->>'source' = 'KYOSAN_REPORT' and metadata->>'importBatchId' = '$BATCH' group by 1 order by 2 desc"

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  🔴 SQL 이 「행이 있다」고 해도 **사람이 못 보면 들어간 것이 아닙니다.**"
  echo "     A/S 에서 수리 건을 아무거나 열어 연락서가 붙어 있고 파일이 열리는지 보세요."
  echo "  그다음: bash $0 --go --po   (🔴 확인 게이트를 지난 뒤에만)"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══════════════════════════════════════════════════════════════════════
#  PO 명단 — 누가 PO 에 들어갈 수 있는가
#
#  🔴 **이 스크립트에서 DB 에 쓰는 곳은 여기 하나뿐이다.** 다른 모드의 SQL 은
#     전부 SELECT 다. 이 예외를 둔 까닭: PO 는 포털에 requires_grant = true 로
#     등록된다 — 「명단에 있는 사람만」 들어온다. 등록만 하고 명단을 안 넣으면
#     **포털 타일에도 안 보이고 로그인도 막힌다.** 그 한 줄 때문에 사람이 psql 에
#     붙어 긴 SQL 을 손으로 치고 있었다(2026-09-28 사용자 지시로 이 모드를 더했다).
#
#  ── 기준: 「지금 A/S 를 쓸 수 있는 사람 전원」 (2026-09-28 사용자 결정) ──
#     A/S 의 client_id 는 `rf-service-system` 이다. 지금 견적서·내자를 쓰는
#     사람들이 그대로 PO 로 이어지는 것이 사용자가 정한 기준이다.
#
#  ── role 은 비운다(NULL) ──
#     PO 의 available_roles 가 비어 있다. PO 는 포털 역할을 안 쓴다(개발 포털의
#     PO 줄도 role 이 비어 있다). **화면별 권한은 A/S 의 「사용자 관리 › 역할별
#     접근 권한」이 정하고 두 시스템이 같은 설정을 본다.** 포털 명단이 정하는
#     것은 「이 사이트에 들어갈 수 있는가」까지다.
#
#  ── 🔴 NOT EXISTS 를 절대 빼지 마라 ──
#     같은 사람을 두 번 넣는 것을 막는다. 2026-09-28 에 dss-auth 저장소의
#     스키마와 마이그레이션으로 확인한 것은 이렇다: `user_client_grants` 에는
#     (user_id, client_id) 위에 **고유 인덱스**가 있다(drizzle/0000 이 만든
#     `user_client_grants_unique`). 그래서 줄이 둘 생기지는 **않지만**,
#     NOT EXISTS 가 없으면 그 인덱스가 **duplicate key 오류로 문장을 통째로
#     되돌린다** — 새로 들어올 사람까지 한 명도 못 들어간다. NOT EXISTS 가
#     있으면 몇 번을 돌려도 「새로 받을 사람만」 들어가고 오류가 안 난다.
#     **다시 돌릴 수 있는 것**이 이 모드의 안전장치다.
#     ⚠️ information_schema.table_constraints 에는 PK 와 외래키만 보인다 —
#        고유 **인덱스**는 제약이 아니라 거기 안 나온다. 없는 것이 아니다.
#
#  ── 🔴 지우는 길은 넣지 않았다 ──
#     잘못 넣은 것은 포털 화면에서 사람이 지우는 편이 안전하다. 지우는 SQL 을
#     스크립트에 두면 실수로 돌렸을 때 크게 다친다. 그래도 꼭 손으로 해야 하면
#     이 모양이다(사람이 psql 에서 직접 친다):
#
#       delete from user_client_grants g
#        using clients c, users u
#        where c.id = g.client_id and u.id = g.user_id
#          and c.client_id = 'dss-po' and u.email = '<뺄사람메일>';
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = grant-preview ] || [ "$MODE" = grant ]; then
  echo "DSS PO 명단 · $(date '+%F %T')"
  "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-auth || stop "dss-pg-auth 가 떠 있지 않습니다."

  # ── 붙을 자리가 있는가 ───────────────────────────────────────────────
  [ "$(qa "select count(*) from clients where client_id = 'dss-po'")" = 1 ] \
    || stop "포털의 clients 에 dss-po 가 없습니다. 등록을 먼저 하세요(runbook/08 3-ㄹ)."
  ok "포털에 dss-po 가 등록돼 있다"
  [ "$(qa "select count(*) from clients where client_id = 'rf-service-system'")" = 1 ] \
    || stop "포털의 clients 에 rf-service-system(A/S)이 없습니다. 기준이 될 명단을 못 찾습니다."

  step "1. 누가 받게 되는가 — A/S 는 쓰는데 PO 명단에는 아직 없는 사람"
  qqa "SELECT u.email, u.display_name, u.status FROM user_client_grants g JOIN users u ON u.id = g.user_id JOIN clients c ON c.id = g.client_id WHERE c.client_id = 'rf-service-system' AND NOT EXISTS (SELECT 1 FROM user_client_grants g2 JOIN clients c2 ON c2.id = g2.client_id WHERE g2.user_id = u.id AND c2.client_id = 'dss-po') ORDER BY u.email"
  N_NEW=$(qa "SELECT count(*) FROM user_client_grants g JOIN users u ON u.id = g.user_id JOIN clients c ON c.id = g.client_id WHERE c.client_id = 'rf-service-system' AND NOT EXISTS (SELECT 1 FROM user_client_grants g2 JOIN clients c2 ON c2.id = g2.client_id WHERE g2.user_id = u.id AND c2.client_id = 'dss-po')")
  N_HAVE=$(qa "select count(*) from user_client_grants g join clients c on c.id = g.client_id where c.client_id = 'dss-po'")
  say "  새로 받을 사람 ${N_NEW:-?}명 · 이미 있는 사람 ${N_HAVE:-?}명"
  say "  ⚠️ status 가 ACTIVE 가 아닌 사람도 위에 보일 수 있습니다 — 줄은 들어가지만"
  say "     포털이 로그인 자체를 막습니다. 그대로 두어도 해가 없습니다."

  if [ "$MODE" = grant-preview ]; then
    echo
    echo "════════════════════════════════════════════════════════════"
    echo "  **아무것도 바꾸지 않았습니다.** 실제로 넣으려면:"
    echo "    bash $0 --grant <주는사람메일>"
    echo "  로그: $LOG"
    echo "════════════════════════════════════════════════════════════"
    exit 0
  fi

  # ── 주는 사람 ────────────────────────────────────────────────────────
  # 🔴 granted_by 는 NOT NULL 이다 — 「누가 줬는가」가 곧 기록이다. 메일을 SQL 에
  #    끼워 넣으므로 글자를 먼저 거른다. 따옴표 하나가 섞이면 질의가 엉뚱하게
  #    갈린다. 꼴이 아니거나 users 에 없으면 **아무것도 하지 않고 멈춘다.**
  case "$GRANT_EMAIL" in
    *[!A-Za-z0-9._%+@-]*) stop "메일에 쓸 수 없는 글자가 있습니다: $GRANT_EMAIL" ;;
  esac
  printf '%s' "$GRANT_EMAIL" | grep -qE '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z][A-Za-z]+$' \
    || stop "메일 꼴이 아닙니다: $GRANT_EMAIL"
  [ "$(qa "select count(*) from users where email = '$GRANT_EMAIL'")" = 1 ] \
    || stop "포털의 users 에 $GRANT_EMAIL 이 없습니다. **아무것도 넣지 않았습니다.**"
  ok "주는 사람: $GRANT_EMAIL ($(qa "select display_name from users where email = '$GRANT_EMAIL'"))"

  if [ "${N_NEW:-0}" = 0 ]; then
    echo
    echo "════════════════════════════════════════════════════════════"
    echo "  새로 받을 사람이 없습니다 — 이미 ${N_HAVE:-?}명이 명단에 있습니다."
    echo "  **아무것도 바꾸지 않았습니다.**"
    echo "════════════════════════════════════════════════════════════"
    exit 0
  fi

  step "2. 🔴 여기부터 DB 에 씁니다"
  # --rollback 과 같은 방식으로 20초를 준다. 무엇이 들어갈지 위에서 다 보여 준 뒤다.
  say "  위 ${N_NEW}명을 PO 명단에 넣습니다 (role 은 비웁니다 — PO 는 포털 역할을 안 씁니다)."
  say "  ⚠️ 계속하려면 20초 안에 Ctrl+C 를 누르지 마세요."
  sleep 20

  # 🔴 NOT EXISTS 를 빼지 마라 — 위 머리말의 그 까닭이다.
  OUT=$(qa_write "INSERT INTO user_client_grants (user_id, client_id, role, granted_by) SELECT u.id, po.id, NULL, giver.id FROM user_client_grants g JOIN users u ON u.id = g.user_id JOIN clients c ON c.id = g.client_id CROSS JOIN clients po CROSS JOIN users giver WHERE c.client_id = 'rf-service-system' AND po.client_id = 'dss-po' AND giver.email = '$GRANT_EMAIL' AND NOT EXISTS (SELECT 1 FROM user_client_grants g2 WHERE g2.user_id = u.id AND g2.client_id = po.id)" 2>&1)
  RC=$?
  echo "$OUT" | sed 's/^/  /'
  if [ "$RC" = 0 ]; then
    ok "넣었다 — psql 이 말한 결과: $(echo "$OUT" | tr -d '\r' | tail -1)"
  else
    bad "넣기 실패 (종료 코드 $RC)"
    stop "위 오류를 보세요. **되돌릴 것이 없습니다** — psql 이 한 문장을 통째로 되돌립니다."
  fi

  step "3. 확인 — 지금 PO 명단에 있는 사람"
  qqa "SELECT u.email, coalesce(g.role, '(역할 없음)') AS role FROM user_client_grants g JOIN users u ON u.id = g.user_id JOIN clients c ON c.id = g.client_id WHERE c.client_id = 'dss-po' ORDER BY u.email"
  N_AFTER=$(qa "select count(*) from user_client_grants g join clients c on c.id = g.client_id where c.client_id = 'dss-po'")
  WANT=$((${N_HAVE:-0} + ${N_NEW:-0}))
  if [ "${N_AFTER:-0}" = "$WANT" ]; then
    ok "명단 ${N_AFTER}명 (전 ${N_HAVE} + 새 ${N_NEW} = $WANT — 맞다)"
    ok "이 수는 --check 의 「PO 명단에 오른 사람」과 같아야 한다"
  else
    bad "명단이 ${N_AFTER:-?}명이다 ($WANT 이어야 한다)"
    say "    → 다시 한 번 돌려도 안전합니다(NOT EXISTS 가 있어 두 번 안 들어갑니다)."
  fi
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL"
  echo "  🔴 이것은 **「이 사이트에 들어갈 수 있는가」까지**입니다."
  echo "     화면별 권한은 A/S 의 「사용자 관리 › 역할별 접근 권한」이 정하고,"
  echo "     두 시스템이 같은 설정을 봅니다."
  echo "  잘못 넣은 것은 포털 화면에서 빼세요(이 스크립트에 지우는 길을 두지 않았습니다)."
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터 check · preload · go ══════════════════════════════════════
echo "DSS 배포 · $(date '+%F %T')"
echo "  $OLD_AUTH → $TAG_AUTH · $OLD_AS → $TAG_AS · $TAG_TOOLS 다시 굽기 · 🔴 $TAG_PO 첫 배포"
case "$MODE" in
  check)   echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**" ;;
  preload) echo "  🔵 --preload — 이미지 넷을 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  go)      if [ "$WITH_PO" = 1 ]; then
             echo "  🔴 --go --po — **PO 를 띄운다**(첫 기동). 확인 게이트를 지났습니까?"
           else
             echo "  🔴 --go — 포털 · A/S 를 교체한다. **앱이 잠깐 멈춘다.**"
           fi ;;
esac

# ══ --preload — 이미지만 본다 ══════════════════════════════════════════
#
# 🔴 10-deploy.sh 의 --preload 는 1·2단계를 다 돌린 뒤에 실었다. 이번에는
#    **이미지 절만** 본다. 까닭: 점검표의 순서상 이미지를 굽는 1단계가
#    po.env·compose·포털 등록(2단계)보다 **앞**이다. 이미지를 실어 두려는
#    시점에는 뒤 항목들이 아직 비어 있는 것이 정상인데, 거기서 멈추면
#    「미리 실어 두기」 자체를 못 한다. 이미지를 싣는 것은 아무것도 안 멈춘다.
if [ "$MODE" = preload ]; then
  step "이미지 tar 넷 · 지문"
  EXP_AUTH=$(tar_config_id  "$TAR_AUTH"  2>/dev/null) || EXP_AUTH=""
  EXP_AS=$(tar_config_id    "$TAR_AS"    2>/dev/null) || EXP_AS=""
  EXP_TOOLS=$(tar_config_id "$TAR_TOOLS" 2>/dev/null) || EXP_TOOLS=""
  EXP_PO=$(tar_config_id    "$TAR_PO"    2>/dev/null) || EXP_PO=""
  for rec in "$TAG_AUTH|$TAR_AUTH|$EXP_AUTH" "$TAG_AS|$TAR_AS|$EXP_AS" \
             "$TAG_TOOLS|$TAR_TOOLS|$EXP_TOOLS" "$TAG_PO|$TAR_PO|$EXP_PO"; do
    tag=${rec%%|*}; rest=${rec#*|}; tarf=${rest%%|*}; exp=${rest##*|}
    if [ ! -s "$tarf" ]; then bad "$tag 의 tar 가 없다: $tarf"; continue; fi
    if [ -z "$exp" ]; then bad "$tag 의 tar 에서 manifest.json 을 읽지 못했다: $tarf"; continue; fi
    bring_img "$tag" "$tarf" "$exp"
  done
  step "$TAG_TOOLS 안의 연락서 러너 넷 (태그가 같아 지문만으로는 안심할 수 없다)"
  if have_img "$TAG_TOOLS"; then
    say "  구운 때: $("$DOCKER" images "$TAG_TOOLS" --format '{{.CreatedAt}}' 2>/dev/null)"
    for f in /app/scripts/import-kyosan-reports.ts \
             /app/scripts/revert-kyosan-import.ts \
             /app/scripts/lib/kyosan-import-run.ts \
             /app/scripts/lib/kyosan-import-revert.ts; do
      "$DOCKER" run --rm --entrypoint sh "$TAG_TOOLS" -c "test -f $f" >/dev/null 2>&1 \
        && ok "$f 있다" || bad "$f 가 없다 — **옛 이미지다**"
    done
  fi
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 멈추지 않았다**"
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
    echo "  ✅ 이어서 (앱을 잠깐 멈춥니다):  bash $0 --go"
  else
    echo "  ✗ 위 ✗ 를 먼저 해결하세요. Claude 에게 알려 주세요."
  fi
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ --go ═══════════════════════════════════════════════════════════════
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 바꾸지 않았고 앱은 살아 있습니다.**"

# ── 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ──────────────
step "2. 이미지 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
bring_img "$TAG_AUTH"  "$TAR_AUTH"  "$EXP_AUTH"  || FAIL2=1
bring_img "$TAG_AS"    "$TAR_AS"    "$EXP_AS"    || FAIL2=1
bring_img "$TAG_TOOLS" "$TAR_TOOLS" "$EXP_TOOLS" || FAIL2=1
bring_img "$TAG_PO"    "$TAR_PO"    "$EXP_PO"    || FAIL2=1
if [ "${FAIL2:-0}" = 1 ]; then
  say
  say "  🔴 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
fi

# ══ PO 를 띄우는 갈래 — --go --po ══════════════════════════════════════
#
# 🔴 여기까지 오려면 **확인 게이트**를 지나야 한다. 연락서가 탈 없이 들어간
#    것을 본 뒤에만 PO 를 띄운다 — 뒤에 문제가 났을 때 어느 쪽 탓인지 가릴 수
#    있어야 하기 때문이다(runbook/09 4-7 · 점검표의 그 게이트).
if [ "$WITH_PO" = 1 ]; then
  step "3. PO / 내자 첫 기동"
  T0=$SECONDS
  say "  🔴 없던 것이 생깁니다. A/S 는 멈추지 않습니다 — PO 하나만 뜹니다."
  "${COMPOSE[@]}" up -d --no-deps app-po 2>&1 | sed 's/^/  /'
  if ! wait_http "PO / 내자" 13600 / dss-po; then
    say "  로그를 봅니다 — 설정이 빠졌으면 **빠진 이름이 그대로 찍힙니다**:"
    "$DOCKER" logs --tail 60 dss-po 2>&1 | sed 's/^/    /'
  fi
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 https://po.dss21.co.kr/ 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://po.dss21.co.kr → $code" ;;
    *) bad "https://po.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시를 보세요(점검표 2단계)" ;;
  esac
  say "  열린 포트 (127.0.0.1 만이어야 한다):"
  netstat -tln 2>/dev/null | grep ':13[0-9]\{3\}' | sed 's/^/      /'

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · 로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  if [ "$FAIL" = 0 ]; then
    cat <<ANNOUNCE

브라우저로 확인해 주세요 (사내망 · 이 순서로 — 점검표 6단계 확인표):
   1. https://po.dss21.co.kr — 로그인이 됩니까
      (안 되면 redirect_uri 가 글자 단위로 같은지 · **명단에 넣었는지**)
      → 명단은 이 스크립트가 넣습니다:  bash $0 --grant-preview  그다음  --grant <메일>
   2. 머리말 메뉴바에 다섯 사이트가 보입니까 (안 보이면 포털의 launcher_url)
   3. 🔴 **A/S 에서 만든 견적서가 보입니까** (/quotes 목록)
   4. 🔴 **A/S 에서 붙인 파일이 열립니까** (견적서 → 내려받기)
   5. 견적서 받기(엑셀) · 미리보기가 됩니까 (양식 다섯)
   6. 🔴 **발행이 공유폴더에 파일을 놓습니까** (탐색기에서 눈으로)
   7. [폴더 열기]가 탐색기를 엽니까
   8. 내자 인수번호가 A/S 로 갑니까 (글자로만 보이면 AS_APP_BASE_URL)
   9. 결재가 돕니까 (결재선은 A/S 에서 설정합니다)

🔴 **3·4 번이 이 배포의 핵심입니다.** 둘 중 하나라도 어긋난 채 사람이 쓰면
   **자료가 두 곳으로 갈라집니다.** 바로 내리고 compose 를 고치세요:
     bash $0 --rollback

🔴 사람이 이어서 할 일:
  · https://login.dss21.co.kr/release-notes 맨 위에 **PO / 내자** 항목이
    보이는지 봅니다(포털은 이미 $TAG_AUTH 로 올라갔습니다).
  · 「사람이 골라야 하는」 연락서를 화면에서 한 장씩 고릅니다
    (A/S → /excel-imports/kyosan-report · 대표 사례 D210103).
  · 직원에게 알립니다 — 「견적서·내자가 PO / 내자로 옮겨졌고,
    **A/S 에도 당분간 그대로 있다**」가 가장 중요합니다.
ANNOUNCE
  else
    echo
    echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
    echo "되돌리기: bash $0 --rollback"
  fi
  exit "$FAIL"
fi

# ══ 포털 · A/S 교체 — 🔴 여기부터 정지 창 ══════════════════════════════
step "3. 포털 교체 ($TAG_AUTH)  ⏱ 여기부터 직원이 못 쓴다"
# 🔴 포털이 먼저다. 로그인이 먼저 살아 있어야 나머지를 확인할 수 있다.
# 🔴 인자 없이 `up -d` 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다(**PO 까지 여기서 떠 버린다**).
#    PO 는 확인 게이트 뒤에 --go --po 로만 뜬다.
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"
"${COMPOSE[@]}" up -d --no-deps app-auth 2>&1 | sed 's/^/  /'
wait_http "통합 로그인" 13100 /signin dss-auth

step "4. A/S 교체 ($TAG_AS)"
"${COMPOSE[@]}" up -d --no-deps app-as 2>&1 | sed 's/^/  /'
wait_http "A/S" 13000 /dashboard dss-as
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → 대답한 시각 $UP_AT · **약 ${DOWN}초**"

step "5. 스모크 — 양식 · 공유폴더 · 바깥 주소"
if "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-as; then
  OUT=$("$DOCKER" exec dss-as sh -c \
    'n=0; for f in /templates/*.xlsx; do [ -f "$f" ] || continue; head -c 1 "$f" >/dev/null 2>&1 || { echo "READFAIL:$f"; exit 1; }; n=$((n+1)); done; echo "OK:$n"' 2>&1)
  case "$OUT" in
    OK:7) ok "새 A/S 컨테이너가 양식 일곱을 다 읽는다" ;;
    OK:*) bad "새 컨테이너가 읽은 양식이 ${OUT#OK:}개다 (7 이어야 한다)" ;;
    *)    bad "새 컨테이너가 양식을 읽지 못했다 — $OUT" ;;
  esac
  "$DOCKER" exec dss-as sh -c 'set -e; t=/quote-archive/.dss-write-test; : > "$t"; rm -f "$t"' >/dev/null 2>&1 \
    && ok "견적서 공유폴더에 쓸 수 있다" || bad "견적서 공유폴더에 쓸 수 없다"
else
  bad "dss-as 컨테이너가 떠 있지 않다"
fi
iss=$(curl -s -m 10 http://127.0.0.1:13100/.well-known/openid-configuration | grep -o '"issuer":"[^"]*"' | cut -d'"' -f4)
[ "$iss" = "https://login.dss21.co.kr" ] && ok "포털 iss $iss" || bad "포털 iss 가 '$iss'"
for h in login as; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in 2??|3??) ok "https://$h.dss21.co.kr → $code" ;; *) bad "https://$h.dss21.co.kr → ${code:-없음}" ;; esac
done

# ══ 6. 🔴 여기서 멈춘다 — 연락서는 사람이 넣는다 ═══════════════════════
#
# 🔴 스크립트는 연락서를 **넣지 않는다.** 계획을 읽고 승인하는 것이 사람의
#    일이기 때문이다(2026-09-28 승인 절차 · runbook/09 4절). 여기서는 그대로
#    복사해 쓸 명령만 찍는다.
step "6. 🔴 연락서 469장 — 여기서 멈춥니다. **사람이 합니다**"
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  멈춘 시각 $STOP_AT → 대답한 시각 $UP_AT · 약 ${DOWN}초"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" != 0 ]; then
  echo
  echo "✗ 가 있습니다. **연락서로 넘어가지 마세요.** Claude 에게 로그를 알려 주세요."
  echo "되돌리기: bash $0 --rollback"
  exit "$FAIL"
fi
cat <<KYOSAN

🔴 먼저 A/S 에 로그인해 화면이 뜨는지 보세요. **여기서 이상하면 연락서로
   넘어가지 마세요.**

── ① 계획만 돌린다 (--apply 가 없으면 한 글자도 쓰지 않습니다) ──────────
🔴 --conditions=react-server 가 없으면 모듈을 읽는 순간 던집니다.

cd /volume1/dss/deploy
$DOCKER compose -f $CF --env-file $ENV_NAS --profile tools \\
  run --rm tools-as \\
  node --conditions=react-server --import tsx scripts/import-kyosan-reports.ts \\
    --dir /kyosan-src --dir /kyosan-converted

── ② 🔴 표를 읽습니다 — 여기가 사람이 보는 자리입니다 ───────────────────
  · 갈래별 합계 — 「문서 아님」이 크면 **폴더 경로가 틀린 것**입니다
  · 🔴 **부품 건너뛰기 장수** — 출하가 잠긴 건에서 사용 부품이 말없이
    건너뛰어집니다. 이 수가 크면 **「부품을 넣을지 말지」가 새 결정**입니다.
    개발에서 0장이었던 것은 표본이 3장뿐이라 그런 것이지 「안 일어난다」가 아닙니다.
  · 「사람이 골라야 하는」 장수 — 러너가 안 넣습니다. 화면에서 한 장씩 고릅니다.

── ③ 승인 — 여기서 멈출 수 있습니다. 아직 아무것도 안 들어갔습니다 ──────

── ④ --apply 로 넣습니다. 🔴 **회차 번호를 종이에 적으세요** ────────────
🔴 --out 은 /app 밖이어야 합니다(안이면 스크립트가 거절합니다).

cd /volume1/dss/deploy
$DOCKER compose -f $CF --env-file $ENV_NAS --profile tools \\
  run --rm tools-as \\
  node --conditions=react-server --import tsx scripts/import-kyosan-reports.ts \\
    --dir /kyosan-src --dir /kyosan-converted \\
    --apply --out /data/kyosan-import-$TODAY.json

  회차 번호(importBatchId)는 러너가 **맨 처음과 맨 끝에** 찍습니다. 그 번호
  하나로 469장을 통째로 되돌립니다. 「복사해 두기」는 중간에 다른 것을 복사하면
  날아갑니다 — **종이에 적으세요.**

── ⑤ 결과를 봅니다 ─────────────────────────────────────────────────────

  bash $0 --kyosan-verify <회차>

  🔴 SQL 이 「행이 있다」고 해도 **사람이 못 보면 들어간 것이 아닙니다.**
     A/S 에서 수리 건을 열어 연락서가 붙어 있고 파일이 열리는지 보세요.

── ⑥ 🔴 확인 게이트 ────────────────────────────────────────────────────
  연락서가 제대로 들어간 것을 확인하기 전에 PO 를 띄우지 않습니다.
  탈이 없으면:

  bash $0 --go --po

  이상하면 되돌립니다 (회차 번호가 필요합니다):

  bash $0 --rollback

KYOSAN
exit "$FAIL"
