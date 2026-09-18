#!/bin/bash
# /volume1/dss/setup/10-deploy.sh — 2026-09-18 배포
#   (포털 1.3 → 1.4 · A/S 1.4 → 1.5 + 마이그레이션 여섯 · 계측기 1.1 → 1.2)
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지 먼저!
#   (NAS)         bash /volume1/dss/setup/10-deploy.sh
#
#   먼저 실어만 두고 싶으면 (앱을 하나도 멈추지 않는다 · 아무 때나 해도 된다):
#   (NAS)         bash /volume1/dss/setup/10-deploy.sh --preload
#
#   계측기까지 같은 창 안에서 올리려면 뒤에 --with-meters 를 붙인다(기본은 안 한다).
#
# **앱이 멈춘다.** 멈추는 것은 통합 로그인과 A/S 둘이고, DB 와 계측기는 내내 떠
# 있다(결정 E — 무중단으로 가지 않는다). 지난 배포는 51초였지만 이번에는
# 마이그레이션이 여섯이고 그중 둘이 자료를 옮긴다 — **창은 30분 잡는다**.
#
# ── 무엇이 바뀌나 ───────────────────────────────────────────────────────
#   통합 로그인  dss-auth:1.3 → 1.4   로그인할 때 「쓸 수 있는 시스템 목록」을
#                                     ID 토큰에 함께 싣는다. 마이그레이션 없음.
#                                     🔴 이것이 먼저 가야 메뉴바가 뜬다.
#   A/S          dss-as:1.4   → 1.5   공용 메뉴바 · 견적서 결재 · 케이블 견적서 ·
#                                     작업비 세 몫. 🔴 **마이그레이션 0100~0105 여섯.**
#   계측기       dss-meters:1.1 → 1.2 공용 메뉴바 · 폰 화면 손질. 마이그레이션 없음.
#                                     🔴 기본으로는 **올리지 않는다** (12단계).
#   개선요청     이 스크립트에 없다 — 첫 설치는 runbook/06 이 따로 담는다.
#
#   env/*.env 는 **건드리지 않는다.** 이번 배포에 새 환경변수가 하나도 없다
#   (런북 07 10절 3번). 이 스크립트는 as.env 를 **읽어 보기만** 한다.
#
# ── 🔴 되돌리기 — A/S 는 태그만으로 안 된다 ────────────────────────────
#
#   포털·계측기 : 이미지만 내리면 끝난다 (마이그레이션이 없다)
#     sed -i 's/dss-auth:1.4/dss-auth:1.3/; s/dss-meters:1.2/dss-meters:1.1/' \
#            /volume1/dss/deploy/docker-compose.nas.yml
#     /usr/local/bin/docker compose -f /volume1/dss/deploy/docker-compose.nas.yml \
#       --env-file /volume1/dss/deploy/.env.nas up -d --no-deps app-auth app-meters
#
#   🔴 A/S : **덤프 복원이 유일한 길이다.**
#     0100 의 power_test_tasks.scope 가 NOT NULL·기본값 없음이라 옛 이미지가 통전
#     건명을 넣지 못하고, 0103(DELETE + DROP COLUMN)·0104(DROP TABLE)가 지운 것은
#     스키마에서 아예 사라졌다. 0101·0105 가 더한 enum 값 둘은 PostgreSQL 이
#     지우지 못한다. 그러므로 「태그만 1.4 로」는 통하지 않는다.
#
#     bash /volume1/dss/setup/10-deploy.sh --rollback
#
#     4단계에서 뜬 pre-deploy-<시각>/dss_as.dump · dss_auth.dump 로 되돌리고,
#     이미지 태그를 내리는 명령을 찍어 준다. 🔴 **덤프를 뜬 뒤에 들어온 자료는
#     사라진다** — 되돌릴지 말지는 **정지 창 안에서** 정한다. 다음 날 발견하면
#     사실상 되돌릴 수 없다(runbook/05 9절의 「라」).
#
#   첨부 파일 : 4단계가 cp -al 로 하드링크 스냅숏을 남긴다. 되돌릴 때는 사람이
#     손으로 바꿔 끼운다 — 이 스크립트는 자동으로 되돌리지 않는다(끝에 안내).
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
BK=$D/backups/pre-deploy-$STAMP
CF=$D/deploy/docker-compose.nas.yml
ENV_NAS=$D/deploy/.env.nas
AS_ENV=$D/deploy/env/as.env
TEMPLATES=$D/as-templates
IMAGES=$D/images
ATT=$D/as-attachments

TAG_AUTH=dss-auth:1.4
TAG_AS=dss-as:1.5
TAG_METERS=dss-meters:1.2
TAR_AUTH=$IMAGES/dss-auth-1.4.tar.gz
TAR_AS=$IMAGES/dss-as-1.5.tar.gz
TAR_METERS=$IMAGES/dss-meters-1.2.tar.gz
# 이미지 안에서 찾을 표식 — 「굽기는 됐는데 내용이 옛것」을 가른다 (runbook/07 2절).
MARK_AUTH=dss_services     # 포털이 ID 토큰에 싣는 클레임 이름
MARK_AS=dss-menu           # @dss/ui 메뉴바의 CSS 클래스 이름
MARK_METERS=dss-menu
N_SQL_WANT=106             # 0000~0105
N_MIG_WANT=106             # 적용 뒤 drizzle.__drizzle_migrations 의 줄 수

MODE=""; WITH_METERS=0; YES=0
for a in "$@"; do
  case "$a" in
    --rollback)    MODE=rollback ;;
    --preload)     MODE=preload ;;
    --with-meters) WITH_METERS=1 ;;
    --yes|-y)      YES=1 ;;
    *) echo "모르는 인자: $a"
       echo "쓰는 법: bash $0 [--preload] [--with-meters] [--yes] [--rollback]"
       exit 2 ;;
  esac
done

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/10-deploy-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

COMPOSE=("$DOCKER" compose -f "$CF" --env-file "$ENV_NAS" --profile tools)
q()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d dss_as -Atc \"$1\"" 2>/dev/null; }
qq() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d dss_as -c \"$1\"" 2>/dev/null; }

# tar 가 들고 있는 지문을 꺼낸다. 🔴 개발 PC 의 .Id 가 아니라 **이 값**이 NAS 의
# image ID 가 된다 — 09-16 에 여기서 한 번 헛걸음했다(README 「다음 배포 때」 2번).
tar_config_id() { # 1 tar 경로  → sha256:<지문>
  local v
  v=$(tar -xzOf "$1" manifest.json 2>/dev/null \
      | sed -n 's/.*"Config"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  v=${v##*/}; v=${v%.json}
  [ -n "$v" ] || return 1
  echo "sha256:$v"
}
have_img() { "$DOCKER" image inspect "$1" >/dev/null 2>&1; }
verify_img() { # 1 태그 2 기대지문 3 표식
  local got
  got=$("$DOCKER" image inspect "$1" --format '{{.Id}}' 2>/dev/null)
  if [ "$got" != "$2" ]; then
    bad "$1 지문이 tar 와 다르다 (NAS ${got:-없음} / tar $2)"
    return 1
  fi
  ok "$1 지문 맞음 ($(echo "$2" | cut -c1-19)…)"
  if "$DOCKER" run --rm --entrypoint sh "$1" -c "grep -rq '$3' /app/.next" >/dev/null 2>&1; then
    ok "$1 안에 「$3」이 들어 있다 — 내용이 새것이다"
  else
    bad "$1 안에서 「$3」을 찾지 못했다 — 맞는 이미지가 아닐 수 있다"
    return 1
  fi
}
bring_img() { # 1 태그 2 tar 3 지문 4 표식
  if have_img "$1"; then
    say "  · $1 는 이미 실려 있다 — 다시 싣지 않는다"
  else
    "$DOCKER" load -i "$2" >/dev/null 2>&1 && ok "$1 실었다" || { bad "$1 싣기 실패 ($2)"; return 1; }
  fi
  verify_img "$1" "$3" "$4"
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

# ══ 되돌리기 ═══════════════════════════════════════════════════════════
if [ "$MODE" = rollback ]; then
  LAST=$(ls -1dt "$D"/backups/pre-deploy-* 2>/dev/null | head -1)
  [ -n "$LAST" ] || stop "되돌릴 덤프가 없습니다."
  echo "되돌립니다 — $LAST"
  ls -l "$LAST" | sed 's/^/    /'
  echo "⚠️ 그 덤프를 뜬 뒤에 들어온 자료는 사라집니다. 계속하려면 20초 안에 Ctrl+C 를 누르지 마세요."
  sleep 20
  "${COMPOSE[@]}" stop app-as app-auth
  for pair in "dss_as:$LAST/dss_as.dump" "dss_auth:$LAST/dss_auth.dump"; do
    db=${pair%%:*}; f=${pair#*:}
    [ -s "$f" ] || { bad "$f 가 없다"; continue; }
    box=dss-pg-app; [ "$db" = dss_auth ] && box=dss-pg-auth
    "$DOCKER" exec -i "$box" sh -c "pg_restore -U \"\$POSTGRES_USER\" -d $db --clean --if-exists --no-owner" < "$f" \
      && ok "$db 되돌림" || bad "$db 되돌리기 실패"
  done
  echo
  echo "이미지 태그를 내린 뒤 띄우세요:"
  echo "  sed -i 's/dss-auth:1.4/dss-auth:1.3/; s/dss-as:1.5/dss-as:1.4/; s/dss-meters:1.2/dss-meters:1.1/' $CF"
  echo "  $DOCKER compose -f $CF --env-file $ENV_NAS up -d --no-deps app-auth app-as"
  echo
  echo "첨부 파일을 되돌려야 하면(사진·도면이 이상할 때만) 스냅숏이 여기 있습니다:"
  echo "  $LAST/as-attachments  ← cp -al 하드링크. 바꿔 끼우는 것은 사람이 합니다."
  exit "$FAIL"
fi

echo "DSS 배포 · $(date '+%F %T')"
echo "  dss-auth 1.3 → 1.4 · dss-as 1.4 → 1.5 · 마이그레이션 0100~0105 여섯"
[ "$WITH_METERS" = 1 ] && echo "  계측기 1.1 → 1.2 도 같은 창 안에서 한다 (--with-meters)" \
                       || echo "  계측기는 이번 실행에서 올리지 않는다 (--with-meters 를 주면 한다)"
[ "$MODE" = preload ] && echo "  🔵 --preload — 볼 것만 보고 이미지를 실어 둔다. **아무것도 멈추지 않는다.**"

# ══ 1. 먼저 볼 것 — 여기서는 앱을 멈추지 않는다 ════════════════════════
#
# 🔴 이 단계의 규칙 하나: **앱을 멈추기 전에 볼 것을 다 보고, 어긋나면 앱이
#    살아 있는 채로 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
step "1. 먼저 볼 것 (앱은 살아 있다)"

# ── 1-ㄱ. 이미지 tar 셋과 그 지문
say "  이미지 tar — 셋이다 (개선요청은 이 배포에 없다)"
EXP_AUTH=$(tar_config_id "$TAR_AUTH" 2>/dev/null) || EXP_AUTH=""
EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
EXP_METERS=$(tar_config_id "$TAR_METERS" 2>/dev/null) || EXP_METERS=""
see_tar() { # 1 태그 2 tar 3 지문
  [ -s "$2" ] || { bad "$1 의 tar 가 없다: $2"; return 1; }
  [ -n "$3" ] || { bad "$1 의 tar 에서 manifest.json 을 읽지 못했다: $2"; return 1; }
  ok "$1 · tar $(du -h "$2" | cut -f1) · 기대 지문 $(echo "$3" | cut -c1-19)…"
}
see_tar "$TAG_AUTH"   "$TAR_AUTH"   "$EXP_AUTH"
see_tar "$TAG_AS"     "$TAR_AS"     "$EXP_AS"
see_tar "$TAG_METERS" "$TAR_METERS" "$EXP_METERS"

# 이미 실려 있는 것은 **지금** 대조한다 — 앱이 살아 있는 동안 보는 것이 싸다.
# 아직 없으면 5단계(정지 창 안)에서 싣는다. --preload 로 미리 실어 두면 이
# 검사가 통째로 정지 창 밖으로 나온다.
for rec in "$TAG_AUTH|$EXP_AUTH|$MARK_AUTH" "$TAG_AS|$EXP_AS|$MARK_AS" "$TAG_METERS|$EXP_METERS|$MARK_METERS"; do
  tag=${rec%%|*}; rest=${rec#*|}; exp=${rest%%|*}; mark=${rest##*|}
  if have_img "$tag"; then
    [ -n "$exp" ] && verify_img "$tag" "$exp" "$mark"
  else
    say "  · $tag 는 아직 NAS 에 없다 — 5단계에서 싣는다"
  fi
done

# ── 1-ㄴ. compose 들이기. 🔴 바꾸기 **전에** 새 파일을 먼저 시험한다.
#    07~09 는 바꾼 뒤에 봤다. 그런데 이번 compose 에는 개선요청(app-improvements)이
#    들어 있고, 그 서비스의 env_file(./env/improvements.env)은 **아직 NAS 에 없다**
#    (첫 설치가 runbook/06 이라 아직 안 했다). 없는 env_file 하나면 docker compose
#    명령이 **통째로** 실패한다 — 멈춘 앱을 다시 띄우지도 못하게 된다.
INCOMING=$D/setup/incoming/docker-compose.nas.yml
if [ -s "$INCOMING" ] && ! cmp -s "$INCOMING" "$CF"; then
  MISS=""
  for e in $(grep -oE '\./env/[A-Za-z0-9_.-]+\.env' "$INCOMING" | sort -u); do
    [ -f "$D/deploy/${e#./}" ] || MISS="$MISS ${e#./}"
  done
  if [ -n "$MISS" ]; then
    bad "새 compose 가 **없는 설정 파일**을 가리킨다:$MISS"
    say "    → 하나만 없어도 docker compose 가 통째로 실패한다."
    say "    → 개선요청은 아직 첫 설치 전이다(runbook/06 2-ㅅ 가 env/improvements.env 를 만든다)."
    say "      이번에 개선요청을 올리지 않는다면, 새 compose 에서 app-improvements 블록을 빼고 다시 올리세요."
    stop "compose 를 바꾸지 않았습니다. 앱은 그대로 돕니다."
  fi
  if "$DOCKER" compose --project-directory "$D/deploy" -f "$INCOMING" --env-file "$ENV_NAS" --profile tools config --quiet >/dev/null 2>&1; then
    ok "새 compose 문법 통과 (바꾸기 전에 봤다)"
  else
    bad "새 compose 에 문법 오류가 있다"
    "$DOCKER" compose --project-directory "$D/deploy" -f "$INCOMING" --env-file "$ENV_NAS" --profile tools config --quiet 2>&1 | sed 's/^/    /' | head -10
    stop "compose 를 바꾸지 않았습니다. 앱은 그대로 돕니다."
  fi
  mkdir -p "$D/backups"
  cp -p "$CF" "$D/backups/docker-compose.nas.yml.$STAMP"
  cp "$INCOMING" "$CF"
  chown root:root "$CF"; chmod 644 "$CF"
  rm -f "$INCOMING"
  ok "compose 새것으로 (옛것: backups/docker-compose.nas.yml.$STAMP)"
fi

# ── 1-ㄷ. compose 가 이번 배포를 가리키나
grep -q "image: $TAG_AUTH"   "$CF" && ok "compose 가 $TAG_AUTH 를 가리킨다"   || bad "compose 의 포털 태그가 1.4 가 아니다"
grep -q "image: $TAG_AS"     "$CF" && ok "compose 가 $TAG_AS 를 가리킨다"     || bad "compose 의 A/S 태그가 1.5 가 아니다"
grep -q "image: $TAG_METERS" "$CF" && ok "compose 가 $TAG_METERS 를 가리킨다" || bad "compose 의 계측기 태그가 1.2 가 아니다"
grep -q "^  tools-as:" "$CF" && ok "compose 에 tools-as 가 있다" || bad "compose 에 tools-as 가 없다 — 마이그레이션을 돌릴 수 없다"
grep -q 'group_add: \["100"\]' "$CF" && ok "app-as 에 group_add 100 이 있다" || bad "compose 에 group_add 100 이 없다 — 견적서 공유폴더를 못 쓴다"
grep -q '^[[:space:]]*CABLE_QUOTE_TEMPLATE_PATH:' "$CF" \
  && ok "compose 에 CABLE_QUOTE_TEMPLATE_PATH 가 있다 (커밋 f2cc6e8)" \
  || bad "compose 에 CABLE_QUOTE_TEMPLATE_PATH 가 없다 — 파일이 있어도 케이블 견적서만 조용히 안 나온다"
"${COMPOSE[@]}" config --quiet >/dev/null 2>&1 && ok "지금 compose 문법 통과" || bad "지금 compose 에 문법 오류가 있다"

# ── 1-ㄹ. as.env 의 견적서 공유폴더 세 줄. 🔴 **값은 절대 찍지 않는다 — 있다/없다만.**
#    이 PC 사본을 올리면 이 줄들이 사라진다. 그래서 env 는 손대지 않고 여기서 본다.
for k in QUOTE_ARCHIVE_DIR QUOTE_ARCHIVE_UNC_ROOT QUOTE_ARCHIVE_UNC_ROOT_ALT; do
  grep -q "^$k=" "$AS_ENV" && ok "as.env 에 $k 가 있다" \
    || bad "as.env 에 $k 가 없다 — 누군가 옛 사본을 올렸다"
done

# ── 1-ㅁ. 양식 일곱. 🔴 케이블이 이번에 새로 올라온 것이라 여기서 본다.
step "1-ㅁ. 견적서·보고서 양식 (케이블이 새로 들어왔다)"
N_XLSX=$(ls -1 "$TEMPLATES"/*.xlsx 2>/dev/null | wc -l)
[ "$N_XLSX" = 7 ] && ok "$TEMPLATES 에 xlsx 7개" || bad "$TEMPLATES 의 xlsx 가 7개가 아니다 ($N_XLSX)"
ls -1 "$TEMPLATES"/*.xlsx 2>/dev/null | sed "s|^$TEMPLATES/|      |"

N_DECL=0
while IFS= read -r p; do
  [ -n "$p" ] || continue
  N_DECL=$((N_DECL + 1))
  host="$TEMPLATES/${p#/templates/}"
  [ -f "$host" ] || bad "compose 가 적은 양식이 NAS 에 없다: $p"
done < <(grep -E '^[[:space:]]+[A-Z_]+TEMPLATE_PATH:' "$CF" | sed 's/^[^:]*:[[:space:]]*"\([^"]*\)".*/\1/')
[ "$N_DECL" = 7 ] && ok "compose 의 양식 경로 7개가 모두 NAS 에 있다" \
                  || bad "compose 의 양식 경로가 7개가 아니다 ($N_DECL)"

CABLE="$TEMPLATES/케이블 견적서.xlsx"
if [ -f "$CABLE" ]; then
  OWNER=$(stat -c '%u:%g' "$CABLE" 2>/dev/null)
  [ "$OWNER" = "1000:1000" ] && ok "케이블 견적서.xlsx 주인 $OWNER" \
    || bad "케이블 견적서.xlsx 주인이 ${OWNER:-?} 다 (1000:1000 이어야 한다)"
  say "      모드 $(stat -c '%a' "$CABLE" 2>/dev/null) · $(stat -c '%s' "$CABLE" 2>/dev/null) 바이트"
else
  bad "케이블 견적서.xlsx 가 없다: $CABLE"
fi

# 🔴 「있다」와 「컨테이너가 읽는다」는 다르다. 갓 올라온 파일에는 Synology ACL 이
#    붙어 chmod 를 눌러 이긴다(커밋 f2cc6e8 의 함정 ②). 지금 도는 컨테이너
#    (uid 1000 · 같은 :ro 볼륨)로 **실제로 읽어 본다.**
if "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-as; then
  OUT=$("$DOCKER" exec dss-as sh -c \
    'n=0; for f in /templates/*.xlsx; do [ -f "$f" ] || continue; head -c 1 "$f" >/dev/null 2>&1 || { echo "READFAIL:$f"; exit 1; }; n=$((n+1)); done; echo "OK:$n"' 2>&1)
  case "$OUT" in
    OK:7) ok "도는 컨테이너(uid 1000)가 양식 일곱을 다 읽는다" ;;
    OK:*) bad "컨테이너가 읽은 양식이 ${OUT#OK:}개다 (7 이어야 한다)" ;;
    *)    bad "컨테이너가 양식을 읽지 못했다 — $OUT" ;;
  esac
  # 견적서 공유폴더도 같은 김에 본다 (07 2단계 · 08 2단계 · 09 4단계와 같은 검사).
  "$DOCKER" exec dss-as sh -c 'set -e; t=/quote-archive/.dss-write-test; : > "$t"; rm -f "$t"' >/dev/null 2>&1 \
    && ok "견적서 공유폴더에 쓸 수 있다" || bad "견적서 공유폴더에 쓸 수 없다"
else
  bad "dss-as 컨테이너가 떠 있지 않다 — 양식 읽기를 시험하지 못했다"
fi

# ── 1-ㅂ. 마이그레이션 볼륨 — tar 를 풀어 두고 .sql 을 센다
step "1-ㅂ. 마이그레이션 파일"
TARBALL=$D/setup/incoming/as-migrations.tar.gz
if [ -s "$TARBALL" ]; then
  rm -rf "$D/as-migrations.new"; mkdir -p "$D/as-migrations.new"
  if tar -xzf "$TARBALL" -C "$D/as-migrations.new" --strip-components=1; then
    rm -rf "$D/as-migrations.old"
    [ -d "$D/as-migrations" ] && mv "$D/as-migrations" "$D/as-migrations.old"
    mv "$D/as-migrations.new" "$D/as-migrations"
    rm -f "$TARBALL"
    chown -R root:root "$D/as-migrations"; chmod -R a+rX "$D/as-migrations"
    ok "as-migrations 새것으로 (옛것: as-migrations.old)"
  else
    bad "as-migrations 풀기 실패"
  fi
fi
N_SQL=$(ls -1 "$D/as-migrations"/*.sql 2>/dev/null | wc -l)
[ "$N_SQL" = "$N_SQL_WANT" ] && ok "마이그레이션 파일 ${N_SQL_WANT}건" \
  || bad "마이그레이션 파일이 ${N_SQL_WANT}건이 아니다 ($N_SQL) — incoming 의 tar 를 올렸나요"
for t in 0100 0101 0102 0103 0104 0105; do
  ls -1 "$D/as-migrations/${t}_"*.sql >/dev/null 2>&1 && ok "$t 있다" || bad "$t 가 없다"
done

# ── 1-ㅅ. DB 와 디스크
step "1-ㅅ. DB · 디스크"
if "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-app && "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-auth; then
  ok "DB 둘 다 떠 있다 (이 배포에서 DB 는 멈추지 않는다)"
else
  bad "DB 가 떠 있지 않다"
fi
FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
if [ "${FREE_KB:-0}" -ge 5000000 ]; then ok "디스크 여유 $FREE_H"; else bad "디스크 여유가 $FREE_H 뿐이다 (5G 이상 있어야 이미지 셋과 덤프가 들어간다)"; fi

# ── 1-ㅇ. 🔴 바꾸기 전 값 — 0100·0103 이 건드리는 표를 로그에 남긴다
step "1-ㅇ. 바꾸기 전 값 (0100·0103 이 이 표를 건드린다)"
say "  repair_labor_settings — 0100 이 investigation_hours·document_hours 를 더한다"
qq "select equipment_kind, base_cost, hourly_rate, power_test_hours from repair_labor_settings order by equipment_kind"
say "  part_unit_prices — 0103 이 같은 부품의 여러 줄을 **DELETE 로 합치고** owner 칸을 지운다"
qq "select part_id, owner, unit_price from part_unit_prices order by part_id, owner"
PU_BEFORE=$(q "select count(*) from part_unit_prices")
say "  → part_unit_prices 지금 ${PU_BEFORE:-?}줄 (개발에서는 5줄 → 3줄이었다. 운영 수는 다르다)"
IMP_ROWS=$(q "select count(*) from improvement_requests")
IMP_ATT=$(q "select count(*) from attachments where improvement_request_id is not null")
say "  → improvement_requests 지금 ${IMP_ROWS:-?}건 · 그 첨부 ${IMP_ATT:-?}건 — 0104 가 통째로 지운다"

[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 바꾸지 않았고 앱은 살아 있습니다.**"

# ══ 2. 백업 확인 — 🔴 대신 뜨지 않는다. 사람이 먼저 한 일을 본다 ═══════
step "2. 백업 확인 (스크립트가 대신 뜨지 않는다)"
TODAY=$(date +%F)
for db in dss_as dss_auth dss_meters; do
  f=$(ls -1t "$D/backups/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
  if [ -n "$f" ] && [ -s "$f" ]; then
    ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
  else
    bad "오늘($TODAY) 뜬 $db 백업이 없다"
    say "    → 먼저 이것부터: bash $D/jobs/backup-nightly.sh   (종료 코드 0 이어야 한다)"
  fi
done

# 🔴 0104 는 개선요청을 통째로 DROP 한다. 그 자료는 덤프 안에 있어도 칸이 사라진
#    뒤에는 되돌려 넣지 못한다 — 「읽어서 새 사이트에 다시 적는 것」이다.
#    그 뽑기(런북 07 3-3)를 사람이 먼저 했는지만 본다.
IMPB=$(ls -1dt "$D"/backups/improvements-before-0104-* 2>/dev/null | head -1)
if [ -n "$IMPB" ]; then
  ok "0104 자료 뽑기 폴더가 있다 — $(basename "$IMPB")"
  ls -1 "$IMPB" 2>/dev/null | sed 's/^/      /'
  [ -s "$IMPB/improvement_requests.csv" ] && ok "  사람이 읽는 CSV 도 있다" \
    || bad "  폴더는 있는데 improvement_requests.csv 가 없거나 비었다"
else
  bad "0104 자료 뽑기 폴더가 없다 ($D/backups/improvements-before-0104-*)"
  say "    → 런북 07 3-3 을 먼저 하세요. 0104 가 improvement_requests 를 DROP 합니다."
  say "      그 뒤에는 되돌려 넣을 수 없습니다 — 첨부의 improvement_request_id 칸이 사라집니다."
fi

[ "$FAIL" = 0 ] || stop "백업이 없으면 시작하지 않습니다. **앱은 아직 살아 있습니다.**"

# ══ --preload — 여기까지만 하고 이미지를 실어 둔다 ═════════════════════
if [ "$MODE" = preload ]; then
  step "미리 싣기 (--preload) — 앱을 멈추지 않는다"
  bring_img "$TAG_AUTH"   "$TAR_AUTH"   "$EXP_AUTH"   "$MARK_AUTH"
  bring_img "$TAG_AS"     "$TAR_AS"     "$EXP_AS"     "$MARK_AS"
  bring_img "$TAG_METERS" "$TAR_METERS" "$EXP_METERS" "$MARK_METERS"
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 멈추지 않았다**"
  echo "  이어서 (정지 창을 열 준비가 되면): bash $0"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 3. 멈춘다 — 🔴 여기부터 정지 창 ════════════════════════════════════
step "3. 앱 정지  ⏱ 여기부터 직원이 못 쓴다"
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"
"${COMPOSE[@]}" stop app-as app-auth && ok "app-as · app-auth 정지 (DB·계측기는 그대로)" || bad "정지 실패"

# ══ 4. 덤프 — 🔴 유일한 되돌리기 지점 ══════════════════════════════════
step "4. 최종 덤프 · 첨부 스냅숏  🔴 이것이 유일한 되돌리기 지점이다"
mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
dump() { # 1 DB 2 컨테이너 3 파일
  "$DOCKER" exec "$2" sh -c "pg_dump -U \"\$POSTGRES_USER\" -d $1 -Fc" > "$3.part" 2>/dev/null \
    && "$DOCKER" exec -i "$2" pg_restore -l < "$3.part" >/dev/null 2>&1 \
    && mv "$3.part" "$3" && ok "$1 덤프 $(du -h "$3" | cut -f1)" \
    || { rm -f "$3.part"; bad "$1 덤프 실패"; }
}
dump dss_as   dss-pg-app  "$BK/dss_as.dump"
dump dss_auth dss-pg-auth "$BK/dss_auth.dump"

if [ -d "$ATT" ]; then
  cp -al "$ATT" "$BK/as-attachments" 2>/dev/null \
    && ok "첨부 스냅숏 (cp -al 하드링크 — 즉시·공간 0)" || bad "첨부 스냅숏 실패"
else
  bad "$ATT 가 없다"
fi

if [ "$FAIL" != 0 ]; then
  say
  say "  🔴 덤프가 없으면 되돌릴 수 없습니다. **지금 바로 되돌립니다** — 아직 DB 는 그대로입니다."
  "${COMPOSE[@]}" up -d --no-deps app-auth app-as 2>&1 | sed 's/^/  /'
  wait_http "통합 로그인" 13100 /signin dss-auth
  wait_http "A/S" 13000 /dashboard dss-as
  stop "덤프에 실패해 옛 이미지로 되돌렸습니다. DB 는 건드리지 않았습니다."
fi

# ══ 5. 이미지를 싣고 지문을 맞춘다 ═════════════════════════════════════
step "5. 이미지 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
bring_img "$TAG_AUTH"   "$TAR_AUTH"   "$EXP_AUTH"   "$MARK_AUTH"   || FAIL5=1
bring_img "$TAG_AS"     "$TAR_AS"     "$EXP_AS"     "$MARK_AS"     || FAIL5=1
bring_img "$TAG_METERS" "$TAR_METERS" "$EXP_METERS" "$MARK_METERS" || FAIL5=1
if [ "${FAIL5:-0}" = 1 ]; then
  say
  say "  🔴 이미지가 기대한 것과 다릅니다. **DB 는 아직 하나도 바뀌지 않았습니다.**"
  say "  옛 이미지로 되돌리려면 (1분):"
  say "    sed -i 's/dss-auth:1.4/dss-auth:1.3/; s/dss-as:1.5/dss-as:1.4/; s/dss-meters:1.2/dss-meters:1.1/' $CF"
  say "    $DOCKER compose -f $CF --env-file $ENV_NAS up -d --no-deps app-auth app-as"
  stop "마이그레이션을 시작하지 않았습니다."
fi

# ══ 6. preflight — 🔴 「되돌리기 불가」는 **예정된 것**이다 ═════════════
step "6. 마이그레이션 적용 전 확인 (db:preflight)"
"${COMPOSE[@]}" run --rm tools-as npm run db:preflight 2>&1 | sed 's/^/  /'
PRC=${PIPESTATUS[0]}
say
say "  ┌──────────────────────────────────────────────────────────────┐"
say "  │ 🔴 위에 「사라질 자료가 있는 항목」이 나오는 것은 **예정된 것**이다. │"
say "  └──────────────────────────────────────────────────────────────┘"
say "    · 0103 — 같은 부품의 여러 줄을 DELETE 로 합치고 owner 칸을 DROP 한다"
say "    · 0104 — improvement_requests 를 DROP TABLE, 그 첨부 줄을 DELETE 한다"
say "    둘 다 되돌릴 수 없다. 그래서 스크립트는 여기서 멈추지 않는다 — 대신 확인한다:"
say "    ✔ 0104 자료 뽑기 폴더 : ${IMPB:-없음}"
say "    ✔ 조금 전 뜬 덤프     : $BK"
say "    (preflight 종료 코드 $PRC — 사라질 자료가 있으면 1 이 정상이다)"
if [ "$YES" != 1 ]; then
  say
  say "  🔴 이제부터가 되돌릴 수 없는 자리입니다. 그만두려면 **20초 안에 Ctrl+C**."
  say "     지금 Ctrl+C 하면 DB 는 손대지 않은 채로 남습니다. 앱만 다시 띄우면 됩니다:"
  say "       $DOCKER compose -f $CF --env-file $ENV_NAS up -d --no-deps app-auth app-as"
  say "       (compose 태그를 1.3 / 1.4 로 먼저 내리세요 — 위 5단계의 sed 한 줄)"
  sleep 20
fi

# ══ 7. 마이그레이션 ════════════════════════════════════════════════════
step "7. 마이그레이션 적용 (0100 ~ 0105)"
"${COMPOSE[@]}" run --rm tools-as npm run db:migrate 2>&1 | sed 's/^/  /'
rc=${PIPESTATUS[0]}
[ "$rc" = 0 ] && ok "적용 끝" || { bad "적용 실패 (종료 코드 $rc)"; stop "되돌리려면: bash $0 --rollback"; }

N_MIG=$(q "select count(*) from drizzle.__drizzle_migrations")
[ "$N_MIG" = "$N_MIG_WANT" ] && ok "DB 의 마이그레이션 기록 ${N_MIG}건" \
  || bad "마이그레이션 기록이 ${N_MIG_WANT}건이 아니다 (${N_MIG:-?})"
"${COMPOSE[@]}" run --rm tools-as npm run db:preflight 2>&1 | sed 's/^/  /'

# ══ 8. 🔴 0100 확인 — 알리되 멈추지 않는다 ═════════════════════════════
step "8. 0100 이 옮긴 값 (1-ㅇ 의 표와 대조)"
qq "select equipment_kind, base_cost, hourly_rate, power_test_hours, investigation_hours, document_hours from repair_labor_settings order by equipment_kind"
NULLS=$(q "select count(*) from repair_labor_settings where investigation_hours is null")
if [ "${NULLS:-0}" = 0 ]; then
  ok "investigation_hours 가 NULL 인 줄이 없다"
else
  ok "마이그레이션은 성공했다 (아래는 사람이 할 일이지 실패가 아니다)"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 사람이 할 일 — investigation_hours 가 NULL 인 줄 ${NULLS}건        ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  qq "select equipment_kind, base_cost, hourly_rate, power_test_hours from repair_labor_settings where investigation_hours is null order by equipment_kind"
  say "    → A/S 화면의 **작업 비용 설정**에서 그 장비의 조사 공수시간을 채워 주세요."
  say "    → 채우기 전까지 **그 장비의 기본 작업비가 0** 이 됩니다 (견적서 금액이 틀립니다)."
  say "    → 배포는 성공한 것입니다. 되돌리지 않습니다."
fi
say "  document_hours 는 전부 NULL 인 것이 맞다 — 새 개념이라 옮길 값이 없다."
say "  part_unit_prices: ${PU_BEFORE:-?}줄 → $(q "select count(*) from part_unit_prices")줄 (0103 이 합쳤다)"

# ══ 9. 띄운다 ══════════════════════════════════════════════════════════
#
# 🔴 인자 없이 `up -d` 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 개선요청(이미지가 아직 없다)까지 띄우려 든다.
step "9. 새 이미지로 기동 (up -d --no-deps app-auth app-as)"
"${COMPOSE[@]}" up -d --no-deps app-auth app-as 2>&1 | sed 's/^/  /'

# ══ 10. 대답할 때까지 기다린다 ═════════════════════════════════════════
#
# ⚠️ `docker ps` 에 보이는 것과 앱이 **대답하는** 것은 다르다(09-16 에 여기서
#    걸렸다). 대답한 시각이 곧 직원이 다시 쓸 수 있게 된 때다.
step "10. 대답할 때까지 기다린다"
wait_http "통합 로그인" 13100 /signin dss-auth
wait_http "A/S" 13000 /dashboard dss-as
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 11. 스모크 ═════════════════════════════════════════════════════════
step "11. 스모크 (런북 07 7-E)"

# 🔴 양식 일곱을 **새 컨테이너 안에서** 실제로 읽어 본다. 케이블이 새로 들어왔고,
#    하나라도 못 읽으면 그 출력(견적서·보고서)이 통째로 죽는다.
OUT=$("$DOCKER" exec dss-as sh -c \
  'n=0; for f in /templates/*.xlsx; do [ -f "$f" ] || continue; head -c 1 "$f" >/dev/null 2>&1 || { echo "READFAIL:$f"; exit 1; }; n=$((n+1)); done; echo "OK:$n"' 2>&1)
case "$OUT" in
  OK:7) ok "새 컨테이너가 양식 일곱을 다 읽는다" ;;
  OK:*) bad "새 컨테이너가 읽은 양식이 ${OUT#OK:}개다 (7 이어야 한다)" ;;
  *)    bad "새 컨테이너가 양식을 읽지 못했다 — $OUT" ;;
esac
for v in QUOTE_TEMPLATE_PATH OH_QUOTE_TEMPLATE_PATH MATCHER_QUOTE_TEMPLATE_PATH \
         MATCHER_OH_QUOTE_TEMPLATE_PATH CABLE_QUOTE_TEMPLATE_PATH \
         INSPECTION_REPORT_TEMPLATE_PATH REPAIR_REPORT_TEMPLATE_PATH; do
  "$DOCKER" exec dss-as sh -c "p=\$(printenv $v); [ -n \"\$p\" ] && head -c 1 \"\$p\" >/dev/null 2>&1" \
    && ok "$v 가 가리키는 파일을 읽는다" || bad "$v 가 비었거나 그 파일을 못 읽는다"
done

"$DOCKER" exec dss-as sh -c 'set -e; t=/quote-archive/.dss-write-test; : > "$t"; rm -f "$t"' >/dev/null 2>&1 \
  && ok "견적서 공유폴더에 쓸 수 있다" || bad "견적서 공유폴더에 쓸 수 없다"

iss=$(curl -s -m 10 http://127.0.0.1:13100/.well-known/openid-configuration | grep -o '"issuer":"[^"]*"' | cut -d'"' -f4)
[ "$iss" = "https://login.dss21.co.kr" ] && ok "포털 iss $iss" || bad "포털 iss 가 '$iss'"

# 307 이라 -L 로 따라가고, React 가 쪼갠 <!-- --> 를 걷는다.
# ⚠️ **화면 번호는 v1.3 이 정상이다.** 소식 목록(dss-auth 의 release-notes.ts)에
#    1.4 항목을 아직 안 넣었다 — 런북 07 10절 11번이 그 할 일이다. 이미지가
#    1.4 인 것은 5단계의 지문이 이미 증명했으므로 여기서는 찍기만 한다.
ver=$(curl -sL -m 15 http://127.0.0.1:13100/signin | sed 's/<!--[^>]*-->//g' | grep -oE 'v[0-9]+\.[0-9]+' | head -1)
say "  로그인 화면의 번호: ${ver:-못 찾음}  (v1.3 이 지금은 정상 — 소식에 1.4 항목을 아직 안 넣었다)"

# 마이그레이션이 실제로 바꾼 것 — 화면 말고 DB 로 본다
[ "$(q "select to_regclass('public.quote_approvals') is not null")" = t ] \
  && ok "0105 — quote_approvals 표가 생겼다" || bad "0105 — quote_approvals 표가 없다"
[ "$(q "select count(*) from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = 'shipment_approval_route_scope' and e.enumlabel = 'QUOTE'")" = 1 ] \
  && ok "0105 — 결재선에 「견적서」 용도가 생겼다" || bad "0105 — 결재선 QUOTE 값이 없다"
[ "$(q "select count(*) from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = 'quote_kind' and e.enumlabel = 'CABLE'")" = 1 ] \
  && ok "0101 — 견적서 종류에 CABLE 이 생겼다" || bad "0101 — quote_kind 에 CABLE 이 없다"
[ "$(q "select to_regclass('public.repair_case_used_parts') is not null")" = t ] \
  && ok "0102 — repair_case_used_parts 표가 생겼다" || bad "0102 — repair_case_used_parts 표가 없다"
[ "$(q "select to_regclass('public.improvement_requests') is null")" = t ] \
  && ok "0104 — improvement_requests 가 사라졌다 (예정된 것)" || bad "0104 — improvement_requests 가 아직 있다"
[ "$(q "select count(*) from information_schema.columns where table_name = 'part_unit_prices' and column_name = 'owner'")" = 0 ] \
  && ok "0103 — part_unit_prices 의 owner 칸이 사라졌다" || bad "0103 — owner 칸이 아직 있다"

# 포트가 새지 않았나 — 127.0.0.1 에만 열려 있어야 한다
say "  열린 포트 (127.0.0.1 만이어야 한다):"
netstat -tln 2>/dev/null | grep ':13[0-9]\{3\}' | sed 's/^/      /'

# 밖에서 주소가 닿나 (NAS 자신이 DSM 프록시를 거쳐 들어간다)
for h in login as meters; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in 2??|3??) ok "https://$h.dss21.co.kr → $code" ;; *) bad "https://$h.dss21.co.kr → ${code:-없음}" ;; esac
done

# 계측기는 멈추지 않았지만 같이 본다
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 http://127.0.0.1:13300/ 2>/dev/null)
case "$code" in 2??|3??) ok "계측기도 그대로 대답한다 ($code)" ;; *) bad "계측기가 $code" ;; esac

# ══ 12. 계측기 — 기본은 하지 않는다 ════════════════════════════════════
#
# 🔴 마이그레이션이 없어 되돌리기가 1분이다. 정지 창을 짧게 유지하려고 기본에서
#    뺐다 — 포털·A/S 가 대답한 시각으로 정지 창을 닫고, 계측기는 그 뒤 아무 때나
#    올린다. 같은 창 안에서 하려면 --with-meters.
step "12. 계측기"
if [ "$WITH_METERS" = 1 ]; then
  M0=$SECONDS
  "${COMPOSE[@]}" up -d --no-deps app-meters 2>&1 | sed 's/^/  /'
  T0=$M0
  wait_http "계측기" 13300 / dss-meters
  ok "계측기 1.2 로 올렸다 (정지 창은 위의 ${DOWN}초와 별개다)"
else
  say "  이번에는 올리지 않았다 — 계측기는 아직 **1.1** 로 돈다."
  say "  ⚠️ compose 는 이미 dss-meters:1.2 를 가리킨다. 다음에 누가 app-meters 를"
  say "     다시 띄우면 그때 1.2 가 된다 — 모르고 당하지 않도록 지금 올리는 편이 낫다:"
  say "       $DOCKER compose -f $CF --env-file $ENV_NAS up -d --no-deps app-meters"
  say "       curl -s -o /dev/null -w '%{http_code}\\n' http://127.0.0.1:13300/"
  say "  되돌리기는 태그만 1.1 로 내리고 같은 명령 (1분)."
fi

# ══ 끝 ═════════════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  멈춘 시각 $STOP_AT → 대답한 시각 $UP_AT · 약 ${DOWN}초"
echo "  덤프(유일한 되돌리기 지점): $BK"
echo "  0104 자료 뽑기: ${IMPB:-없음}"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" = 0 ]; then
  if [ "$WITH_METERS" = 1 ]; then
    METERS_LINE="이번에 1.2 로 올렸습니다 — 여기에도 메뉴바가 보여야 합니다."
  else
    METERS_LINE="이번에는 올리지 않았습니다 — 아직 1.1 이라 메뉴바가 안 보입니다."
  fi
  cat <<ANNOUNCE

브라우저로 확인해 주세요 (사내망 · DSSTECH5):
  1. https://login.dss21.co.kr 로 **로그아웃했다 다시 로그인**합니다.
     🔴 메뉴바 목록은 **로그인할 때만** 토큰에 실립니다 — 다시 로그인하지 않으면
        옛 토큰 그대로라 메뉴가 안 보입니다.
  2. https://as.dss21.co.kr — 머리말에 **드롭다운 단추 하나**가 보이고, 누르면
     쓸 수 있는 시스템 목록이 펼쳐지는지. 바깥을 누르거나 Esc 로 접히는지.
  3. 견적서 화면 — [견적서 결재] 탭이 있는지, 결재선에 「견적서」 용도가 보이는지.
  4. 케이블 견적서를 한 건 만들어 **내려받아 열어** 보세요 (양식이 이번에 새로
     올라온 것이라 여기서 처음 쓰입니다).
  5. https://meters.dss21.co.kr — $METERS_LINE

🔴 사람이 이어서 할 일:
  · investigation_hours 가 NULL 인 줄을 A/S 「작업 비용 설정」에서 채웁니다
    (안 채우면 그 장비의 기본 작업비가 0 이 됩니다).
  · 포털 「업데이트 소식」에 1.4 · A/S 1.5 항목을 넣습니다 (dss-auth 저장소).
  · 개선요청 첫 설치는 runbook/06 을 따로 봅니다 — 이 배포에 들어 있지 않습니다.

되돌리려면 (🔴 정지 창 안에서만 뜻이 있습니다):
  bash $0 --rollback
ANNOUNCE
else
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
  echo "되돌리기: bash $0 --rollback"
fi
exit "$FAIL"
