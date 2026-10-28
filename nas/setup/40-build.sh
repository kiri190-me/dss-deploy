#!/bin/bash
# dss-deploy/nas/setup/40-build.sh — 서른일곱째 배포 · 이미지 굽기 (2026-10-28)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · Git Bash) ────────────────────────────────────
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/40-build.sh" --check
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/40-build.sh" --go
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-37):
#     bash .../40-build.sh --go "/d/배포본/_images-37"
#
# ── 이번에 굽는 것 — **둘뿐이다** ─────────────────────────────────────
#     ① A/S       dss-as:3.2          → **dss-as:3.3**          커밋 8 (조각 13 전체)
#     ② RF 이슈관리 dss-rf-trouble:0.2 → **dss-rf-trouble:0.3**  커밋 1
#
#   🔴 **나머지 여덟은 안 굽는다** — 포털 1.9 · 재고 0.6 · PO 0.7 · 게시판 0.3 ·
#      계측기 1.4 · 개선요청 0.5 · 휴가 0.4 · 통합 승인함 0.1 은
#      기준 SHA 이후 커밋이 **0** 이다(2026-10-28 실측).
#
#   🔵 39-build.sh(서른여섯째)는 넷을 굽고 **다섯째 산출물**(as-migrations.tar.gz)
#      도 만들었다. 이번엔 **마이그레이션이 0건**이라 그 다섯째가 없다 — 아래 절.
#
# ── 🔴 마이그레이션 — 이번엔 **0건이다** ──────────────────────────────
#   RF_Service_System 의 drizzle/ 이 기준 SHA(7ff139f) 이후 **한 글자도 안
#   바뀌었다**(2026-10-28 'git diff --name-only -- drizzle/' 로 확인, 0줄).
#   🔴 그래서 **as-migrations.tar.gz 를 만들지도 보내지도 않는다.** NAS 의
#      /volume1/dss/as-migrations 는 이미 39번이 121 로 올려 둔 그대로다.
#
# ── 🔴 A/S 도구를 왜 안 굽는가 — 판정 잣대는 「담는가」가 아니라 「부르는
#      명령이 바뀌었는가」다 ────────────────────────────────────────────
#   🔵 지난 판(39번)에서 「마이그레이션 0건이니 도구는 안 굽는다」가 틀린
#      전제였던 적이 있다(포털 도구 — README 36번 절 참고). 그래서 이번엔
#      **다른 잣대**로 판정했다.
#
#   'tools-as' 로 부르는 명령은 **'db:migrate' 와 'db:preflight' 둘뿐**이다
#   (README·nas/ 문서 전수 grep, 2026-10-28). 그 둘의 실제 몸통은:
#     db:migrate     "drizzle-kit migrate"                    ← 볼륨의 drizzle/ 만 읽는다
#     db:preflight   "tsx scripts/check-pending-migrations.ts" ← 이 파일은 안 바뀌었다
#   🔴 'drizzle-kit migrate' 는 **이미지 안의 src/ 를 안 본다** — 도구 이미지가
#      무엇을 담든 상관이 없는 명령이다.
#
#   이번 조각 13 이 'scripts/' 에서 바꾼 것은 **다섯**뿐이다(실측):
#     scripts/check-inventory-contract.ts
#     scripts/check-inventory-contract-bad-token.test.ts
#     scripts/test-lists/components.txt
#     scripts/test-lists/db.txt
#     scripts/test-lists/unit.txt
#   🔵 시험 목록 셋은 'npm test' 류가 읽지 'tools-as' 가 읽지 않는다.
#      'check-inventory-contract*.ts' 는 **개발 PC 전용 점검**(재고 계약 확인)이라
#      'db:preflight' 가 부르는 'check-pending-migrations.ts' 와 다른 파일이다.
#   🔴 **그러므로 tools-as 가 부르는 두 명령 중 어느 것도 이번 변경에 안 닿는다.**
#      'dss-as-tools:1' 을 그대로 둔다 — **안 굽는다.**
#
# ── 🔴 39번(지난 판)과 다른 것 ─────────────────────────────────────────
#   ① 저장소 둘(A/S · RF 이슈관리)뿐이고 **이미지도 저장소 수와 같다** — 39번은
#      저장소 셋에 이미지 넷(포털 도구가 따로)이었다. 이번엔 도구를 안 굽는다.
#   ② 🔴 **마이그레이션 묶음이 없다.** A/S 가 볼륨을 쓰는 것은 39번과 같지만,
#      이번엔 드리즐 폴더 자체가 안 바뀌어 묶을 것이 없다.
#   ③ 🔵 RF 이슈관리는 **DB 가 없다**(JSON 파일 + config.json). drizzle 검사
#      자체가 그 저장소에는 해당하지 않는다.
#   ④ 🔴 RF 이슈관리 쪽은 **동작이 바뀌는 자리**(쿠키 다섯을 한 함수가 짓는다 ·
#      포트를 127.0.0.1 로 좁힌다)가 있다. 운영 compose 는 이미 포트를
#      127.0.0.1:13900 으로 좁혀 두었으므로(32-rf-trouble-deploy.sh) **그 변경은
#      영향이 없다** — 포트 좁히기는 저장소의 standalone compose.yaml 쪽 이야기다.
#      🔴 영향이 있는 쪽은 **쿠키**다 — 굽기 전에 소스로, 구운 뒤에는 이미지
#      안을 직접 열어 cookieAttrs 가 들어갔는지를 센다(④ 절).
#
# ── 🔴 이 환경의 함정 (36·37·39-build.sh 에서 그대로 가져온 처방) ──────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싸고, 저장소 자리를
#      이 파일의 자리에서 계산한다(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:\… 를 /c/… 로
#      바꾸고, docker save 는 작업 폴더로 들어가 **상대경로**로 쓴다.
#   ③ 🔴 **tar 의 Config 를 docker image inspect .Id 와 맞대지 마라.** 맞댈
#      상대는 **빌드 로그의 exporting config sha256:** 이다.
#   ④ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를
#      막는다). 다만 메모리는 다르다 — 열이 떠 있으면 빌드가 죽을 수 있다.
#
# ── 🔴 모드 둘 ────────────────────────────────────────────────────────
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다.
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면
#            굽지 않고 멈춘다. 전부 ✓ 일 때만 둘을 굽고 tar 로 뽑는다.
#            그리고 RF 이슈관리 이미지 안을 세어 쿠키 함수가 들어갔는지 본다.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안의 백틱은 명령 치환으로 읽힌다 → 이 파일에는 백틱이
#      **한 개도 없다**(주석에도 안 썼다). 쓴 뒤 세었다.
#   ② 읽기 전용 자리의 ': >' 는 ash 를 죽인다 → 이 파일은 개발 PC(Git Bash)
#      에서만 돌고, 그 꼴이 **한 군데도 없다.**
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEV=${DSS_DEV:-$(cd "$SCRIPT_DIR/../../.." && pwd)}

PASS=0; FAIL=0; UNK=0
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
unk()  { UNK=$((UNK+1));   printf '  ? %s — 못 쟀다 (%s)\n' "$1" "$2"; }
note() { printf '  ⚠️ %s\n' "$1"; }
say()  { printf '    %s\n' "$1"; }

isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }

# 🔴 C:\… 또는 C:/… 를 /c/… 로. tar 는 드라이브 문자를 원격 호스트로 읽는다.
to_unix() { # 1 경로
  local p=${1//\\//}
  case "$p" in
    [A-Za-z]:/*) p=/$(printf '%s' "${p%%:*}" | tr 'A-Z' 'a-z')${p#?:} ;;
  esac
  printf '%s' "$p"
}

tar_name() { printf '%s.tar' "$(printf '%s' "$1" | tr ':' '-')"; }

# tar 안 manifest.json 의 Config 지문 (39-build.sh 의 것을 글자 그대로)
tar_config_id() { # 1 tar
  tar -xOf "$1" manifest.json 2>/dev/null \
    | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 \
    | sed 's|blobs/sha256/|sha256:|'
}

# 한 저장소의 drizzle/ 을 센다 → ".sql수 journal수" (A/S 에만 쓴다 — 트러블은 DB 가 없다)
count_drizzle() { # 1 저장소 폴더
  local s j
  s=$(ls -1 "$1/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  j=$(grep -o '"idx"' "$1/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  printf '%s %s' "${s:-0}" "${j:-0}"
}

# ══ 이번에 굽는 것 — 한자리에 모아 둔다 ═══════════════════════════════
#   열쇠|저장소 폴더|새 태그|기준 SHA|--target(없으면 -)|기대 drizzle 파일 수|기대 커밋 수
#
#   🔴 여섯째 칸은 「기준 SHA 이후 drizzle/ 에서 **달라진 파일 수**」다.
#      이번엔 **둘 다 0 이어야** 맞다 — A/S 는 드리즐이 안 바뀌었고,
#      RF 이슈관리는 애초에 drizzle/ 이 없다(DB 가 없다).
#   🔵 일곱째 칸(커밋 수)은 ✗ 로 세지 않고 ⚠️ 로만 센다 — 적어 둔 수와
#      어긋나면 표가 낡았다는 뜻이라 사람이 봐야 한다.
SITES='
as|RF_Service_System|dss-as:3.3|7ff139f|-|0|8
trouble|dss-trouble|dss-rf-trouble:0.3|6a844cb|-|0|1
'
HOWMANY=2

# ── 🔴 기대값과 그 출처 ───────────────────────────────────────────────
#   [저장소] 2026-10-28 개발 PC 의 저장소에서 센 값
AS_SQL_WANT=121       # [저장소] RF_Service_System/drizzle/*.sql — 안 늘어야 한다(0120 까지 그대로)
CORE_PIN=05018b077a780922b484a7a539665f35d5207c82   # vendor/dss-core 포인터 — 안 움직였다

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-37"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

printf '%s\n' "서른일곱째 배포 · 이미지 굽기   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  저장소 뿌리: $DEV"
printf '%s\n' "  tar 둘 자리: $OUT"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 1. 도커가 도는가 ──────────────────────────────────────────────────
printf '\n== 1. 도커\n'
if docker version --format '{{.Server.Version}}' >/dev/null 2>&1; then
  ok "도커가 돈다 (서버 $(docker version --format '{{.Server.Version}}' 2>/dev/null))"
else
  bad "도커가 안 돈다 — Docker Desktop 을 켜세요"
fi

# ── 2. 저장소 둘 ──────────────────────────────────────────────────────
printf '\n== 2. 저장소 둘\n'
printf '%s\n' "🔴 미커밋·미푸시가 있으면 구운 이미지를 나중에 재현하지 못한다."
printf '%s\n' "🔴 **안 받은 것도 센다** — 낡은 코드를 굽고도 모른다."
printf '%s\n' "$SITES" | while IFS='|' read -r KEY REPO TAG BASE TGT WANTMIG WANTN; do
  [ -n "${KEY:-}" ] || continue
  DIR="$DEV/$REPO"
  printf '  ── %s (%s → %s)\n' "$KEY" "$REPO" "$TAG"
  if [ ! -d "$DIR/.git" ] && [ ! -f "$DIR/.git" ]; then
    printf '  ✗ %s — git 저장소가 아니다 (%s)\n' "$REPO" "$DIR"; continue
  fi
  dirty=$(git -C "$DIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if isnum "${dirty:-}" && [ "$dirty" -eq 0 ]; then printf '  ✓ %s 미커밋 0\n' "$REPO"
  else printf '  ✗ %s 미커밋 %s 줄\n' "$REPO" "${dirty:-?}"; git -C "$DIR" status --porcelain=v1 2>/dev/null | head -5 | sed 's/^/      /'; fi
  if git -C "$DIR" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    up=$(git -C "$DIR" log --oneline '@{u}..HEAD' 2>/dev/null | wc -l | tr -d ' ')
    dn=$(git -C "$DIR" log --oneline 'HEAD..@{u}' 2>/dev/null | wc -l | tr -d ' ')
    if [ "${up:-1}" = "0" ] && [ "${dn:-1}" = "0" ]; then printf '  ✓ %s 미푸시 0 · 안받음 0\n' "$REPO"
    else printf '  ✗ %s 미푸시 %s · 안받음 %s\n' "$REPO" "${up:-?}" "${dn:-?}"; fi
  else
    printf '  ? %s 미푸시 — 올려다볼 가지가 없다\n' "$REPO"
  fi
  # 🔵 기준 SHA 가 조상인지 — 아니면 표가 낡았거나 가지가 갈렸다.
  if git -C "$DIR" merge-base --is-ancestor "$BASE" HEAD 2>/dev/null; then
    n=$(git -C "$DIR" log --oneline "$BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
    m=$(git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | wc -l | tr -d ' ')
    if [ "${n:-x}" = "$WANTN" ]; then
      printf '  ✓ %s 기준 %s 이후 커밋 %s개 — 적어 둔 그대로\n' "$REPO" "$BASE" "$n"
    else
      printf '  ⚠️ %s 기준 %s 이후 커밋 %s개 — **%s개를 적어 두었다**. 아래를 보고 사람이 판단할 것\n' "$REPO" "$BASE" "${n:-?}" "$WANTN"
      git -C "$DIR" log --oneline "$BASE..HEAD" 2>/dev/null | head -12 | sed 's/^/      /'
    fi
    # 🔴 「0 이면 통과」가 아니다. 적어 둔 수와 **똑같아야** 한다.
    if [ "${m:-x}" = "$WANTMIG" ]; then
      printf '  ✓ %s drizzle/ 에서 달라진 파일 %s개 — 적어 둔 그대로\n' "$REPO" "$m"
    else
      printf '  ✗ %s drizzle/ 에서 달라진 파일 %s개 — **%s개를 기대했다**. 전제가 깨졌으니 멈추고 알릴 것\n' "$REPO" "${m:-?}" "$WANTMIG"
      git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | head -8 | sed 's/^/      /'
    fi
  else
    printf '  ✗ %s — 기준 SHA %s 가 조상이 아니다 (표가 낡았거나 가지가 갈렸다)\n' "$REPO" "$BASE"
  fi
  printf '    지금 HEAD: %s\n' "$(git -C "$DIR" log -1 --format='%h %s' 2>/dev/null)"
done

# 🔴 위 while 이 파이프라인 안이라 **셈이 안 넘어온다.** 다시 세어 FAIL 에 싣는다.
REPO_BAD=0
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}
  rest=${rest#*|}; BASE=${rest%%|*}; rest=${rest#*|}; TGT=${rest%%|*}
  rest=${rest#*|}; WANTMIG=${rest%%|*}
  DIR="$DEV/$REPO"
  d=$(git -C "$DIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  u=$(git -C "$DIR" log --oneline '@{u}..HEAD' 2>/dev/null | wc -l | tr -d ' ')
  n=$(git -C "$DIR" log --oneline 'HEAD..@{u}' 2>/dev/null | wc -l | tr -d ' ')
  m=$(git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | wc -l | tr -d ' ')
  git -C "$DIR" merge-base --is-ancestor "$BASE" HEAD 2>/dev/null || REPO_BAD=$((REPO_BAD+1))
  [ "${d:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
  [ "${u:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
  [ "${n:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
  [ "${m:-x}" = "$WANTMIG" ] || REPO_BAD=$((REPO_BAD+1))
done
if [ "$REPO_BAD" = "0" ]; then ok "저장소 둘 전부 깨끗하고 drizzle 변경 수가 적어 둔 그대로(0)"
else bad "저장소 검사에서 어긋난 것 ${REPO_BAD}가지 — 위 ✗ 를 보세요"; fi

# ── 3. 🔴 A/S 의 서브모듈 둘 — 빈 폴더면 빌드가 크게 실패한다 ─────────
#  🔴 A/S 의 tsconfig paths 가 vendor/dss-core 를 가리키고, 화면은 vendor/dss-ui 의
#     @dss/ui 를 쓴다. 서브모듈을 안 받아 두면 **빌드가 모듈을 못 찾고 죽는다.**
printf '\n== 3. A/S 의 서브모듈 둘\n'
ASDIR="$DEV/RF_Service_System"
# 🔴 tr 의 지우기 집합에서 빼기표는 **맨 끝**에 둔다(ASCII 역순이면 죽는다).
COREPIN=$(git -C "$ASDIR" submodule status vendor/dss-core 2>/dev/null | awk '{print $1}' | tr -d '+-')
if [ "${COREPIN:-}" = "$CORE_PIN" ]; then
  ok "vendor/dss-core 포인터가 ${CORE_PIN:0:7} 다 (안 움직였다 — 적어 둔 그대로)"
elif [ -n "${COREPIN:-}" ]; then
  bad "vendor/dss-core 포인터가 ${COREPIN:0:7} 다 — **${CORE_PIN:0:7} 을 기대했다.** 멈추고 알릴 것"
else
  bad "vendor/dss-core 포인터를 못 읽었다 — 서브모듈이 아예 없다"
fi
if [ -s "$ASDIR/vendor/dss-core/package.json" ]; then ok "vendor/dss-core 에 파일이 있다 (빈 폴더가 아니다)"
else bad "vendor/dss-core 가 **빈 폴더**다 — git submodule update --init 을 먼저"; fi
if [ -s "$ASDIR/vendor/dss-ui/package.json" ]; then ok "vendor/dss-ui 에 파일이 있다 (빈 폴더가 아니다)"
else bad "vendor/dss-ui 가 **빈 폴더**다 — 메뉴바·알림 종이 안 구워진다"; fi

# ── 4. 🔴 A/S 의 drizzle/ — 전체가 그대로여야 한다(121) ───────────────
#  🔴 이번 판은 마이그레이션이 0건이다. NAS 의 /volume1/dss/as-migrations 는
#     39번이 이미 121 로 올려 둔 그대로라, 이번엔 묶음을 **만들지도 보내지도
#     않는다.** 여기서는 저장소의 drizzle/ 총량이 그 121 과 어긋나지 않는지만
#     본다 — 어긋나면 누군가 그 사이 마이그레이션을 더한 것이라 전제가 깨진다.
printf '\n== 4. A/S 의 drizzle/ — 전체가 %s 그대로여야 한다\n' "$AS_SQL_WANT"
AS_COUNTS=$(count_drizzle "$ASDIR"); AS_SQL=${AS_COUNTS%% *}; AS_JRN=${AS_COUNTS##* }
say "RF_Service_System/drizzle — .sql ${AS_SQL}장 · meta/_journal.json 의 idx ${AS_JRN}개"
if [ "${AS_SQL:-0}" = "$AS_SQL_WANT" ] && [ "${AS_JRN:-0}" = "$AS_SQL_WANT" ]; then
  ok "${AS_SQL_WANT} 그대로다 (이번 판은 마이그레이션이 없다 — 볼륨은 39번 것을 그대로 쓴다)"
else
  bad "drizzle 이 .sql ${AS_SQL:-?} · idx ${AS_JRN:-?} 다 — **${AS_SQL_WANT} 그대로여야 한다.** 전제가 깨졌으니 멈추고 알릴 것"
fi
# 🔵 RF 이슈관리는 DB 가 없다 — drizzle/ 폴더 자체가 없어야 정상이다.
TRDIR="$DEV/dss-trouble"
if [ -d "$TRDIR/drizzle" ]; then
  bad "dss-trouble 에 drizzle/ 폴더가 **생겼다** — 이 저장소는 DB 가 없는 것이 전제였다. 멈추고 알릴 것"
else
  ok "dss-trouble 에 drizzle/ 폴더가 없다 (DB 가 없는 저장소 — 전제 그대로)"
fi

# ── 5. 🔴 RF 이슈관리 — 코드가 담고 있어야 할 것(굽기 전에 소스로 본다) ─
#  🔴 이번 판의 동작 변경은 **쿠키 다섯을 한 자리(cookieAttrs)에서 짓는 것**과
#     **포트를 127.0.0.1 로 좁히는 것** 둘이다. 굽고 나서 다시 이미지 안을
#     세지만(아래 「굽은 이미지 안을 센다」절), 여기서는 소스가 그것을 담고
#     있는지 먼저 본다 — 속이 빈 커밋을 굽는 일을 막는다.
printf '\n== 5. RF 이슈관리 — 소스가 담고 있어야 할 것\n'
if grep -qE 'const[[:space:]]+cookieAttrs[[:space:]]*=' "$TRDIR/tools/auth.js" 2>/dev/null; then
  ok "tools/auth.js 에 cookieAttrs 가 있다 (다섯 쿠키를 한 자리에서 짓는 그 함수)"
else
  bad "tools/auth.js 에 cookieAttrs 가 없다 — 쿠키 통합이 소스에 없다"
fi
if grep -qF 'auth.cookieAttrs(req, maxAgeSec, TX_PATH)' "$TRDIR/tools/sso.js" 2>/dev/null; then
  ok "tools/sso.js 가 cookieAttrs 를 쓴다 (왕복 쿠키 rfsso 가 그것을 쓴다)"
else
  bad "tools/sso.js 가 cookieAttrs 를 안 쓴다 — rfsso 가 따로 적는 옛 모양일 수 있다"
fi
if grep -qE '^\s*ports:\s*$' "$TRDIR/compose.yaml" 2>/dev/null && grep -qF '"127.0.0.1:7331:7331"' "$TRDIR/compose.yaml" 2>/dev/null; then
  ok "compose.yaml 의 포트가 127.0.0.1 로 좁혀 있다"
else
  bad "compose.yaml 의 포트 줄을 못 찾았다 — 127.0.0.1:7331:7331 인지 보세요"
fi
if grep -q 'COOKIE_SECURE' "$TRDIR/docker.env.example" 2>/dev/null; then
  ok "docker.env.example 에 COOKIE_SECURE 자리가 있다 (기본 auto, 안 적어도 된다)"
else
  bad "docker.env.example 에 COOKIE_SECURE 가 없다"
fi
# 🔵 .dockerignore 가 tools/ 를 막으면 cookieAttrs 가 이미지에 아예 안 들어간다.
if grep -qE '^tools/?$' "$TRDIR/.dockerignore" 2>/dev/null; then
  bad ".dockerignore 가 tools/ 를 막는다 — 이미지가 빈 채로 구워진다"
else
  ok ".dockerignore 가 tools/ 를 막지 않는다"
fi

# ── 6. 태그가 이미 있나 ───────────────────────────────────────────────
printf '\n== 6. 새 태그가 이미 있나\n'
printf '%s\n' "🔵 있으면 **덮어쓴다** — 같은 커밋이면 같은 것이 나오므로 해롭지 않다."
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  rest=${row#*|}; rest=${rest#*|}; TAG=${rest%%|*}
  if docker image inspect "$TAG" >/dev/null 2>&1; then note "$TAG — 이미 있다 (덮어쓴다)"
  else ok "$TAG — 아직 없다"; fi
done

# ── 7. tar 둘 자리 ────────────────────────────────────────────────────
printf '\n== 7. tar 둘 자리\n'
if [ "$MODE" = "--go" ]; then
  mkdir -p "$OUT" 2>/dev/null
fi
if [ -d "$OUT" ]; then ok "$OUT 가 있다"
elif [ "$MODE" = "--check" ]; then note "$OUT 가 아직 없다 (--go 가 만든다)"
else bad "$OUT 를 못 만들었다"; fi

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
if [ "$FAIL" != "0" ] || [ "$UNK" != "0" ]; then
  printf '%s\n' "🔴 멈춘다 — 위 ✗ / ? 를 먼저 보세요. **아무것도 안 구웠다.**"
  exit 1
fi
if [ "$MODE" = "--check" ]; then
  printf '%s\n' "🔵 **아무것도 안 구웠다.** 전부 통과했으니 이어서: --go"
  exit 0
fi

# ══ 굽기 ══════════════════════════════════════════════════════════════
printf '\n%s\n' "════════ 굽는다 ════════"
BUILT=0; BFAIL=0; TARTABLE=""
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}
  rest=${rest#*|}; BASE=${rest%%|*}; rest=${rest#*|}; TGT=${rest%%|*}
  DIR="$DEV/$REPO"
  FILE=$(tar_name "$TAG")
  LOG="$OUT/build-$(printf '%s' "$TAG" | tr ':' '-').log"
  printf '\n── %s  (%s)\n' "$TAG" "$REPO"

  if [ "$TGT" = "-" ]; then
    printf '    스테이지: 기본(runner)\n'
    ( cd "$DIR" && docker build -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG" | tail -3
    RC=${PIPESTATUS[0]}
  else
    printf '    스테이지: --target %s\n' "$TGT"
    ( cd "$DIR" && docker build --target "$TGT" -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG" | tail -3
    RC=${PIPESTATUS[0]}
  fi
  if [ "${RC:-1}" = "0" ]; then
    printf '  ✓ 구웠다\n'
  else
    printf '  ✗ 굽기 실패 — %s 를 보세요\n' "$LOG"; BFAIL=$((BFAIL+1)); continue
  fi

  # 🔴 docker save 는 작업 폴더로 들어가 **상대경로**로 쓴다(tar 의 드라이브 문자 함정).
  if ( cd "$OUT" && docker save "$TAG" -o "$FILE" ) </dev/null; then
    sz=$(stat -c %s "$OUT/$FILE" 2>/dev/null || wc -c < "$OUT/$FILE")
    printf '  ✓ tar %s (%s바이트)\n' "$FILE" "$sz"
  else
    printf '  ✗ tar 내보내기 실패\n'; BFAIL=$((BFAIL+1)); continue
  fi

  # 🔴 tar 의 Config 를 **빌드 로그의 exporting config** 와 맞댄다.
  cfg=$(tar_config_id "$OUT/$FILE")
  exp=$(tr -d '\000' < "$LOG" | grep -oE "exporting config sha256:[0-9a-f]+" | tail -1 | grep -oE "sha256:[0-9a-f]+")
  printf '    tar  %s\n' "${cfg:-못 읽음}"
  printf '    로그 %s\n' "${exp:-없음}"
  if [ -n "$cfg" ] && [ -n "$exp" ] && [ "$cfg" = "$exp" ]; then printf '  ✓ 지문이 빌드 로그와 같다\n'
  elif [ -z "$exp" ]; then printf '  ⚠️ 빌드 로그에 exporting config 가 없다 (buildx 판에 따라 안 찍힌다)\n'
  else printf '  ✗ 지문이 다르다\n'; BFAIL=$((BFAIL+1)); continue; fi

  m5=$(md5sum "$OUT/$FILE" | awk '{print $1}')
  printf '    md5  %s\n' "$m5"
  TARTABLE="$TARTABLE$FILE|$sz|$m5|${cfg:-없음}
"
  BUILT=$((BUILT+1))

  # 🔴 RF 이슈관리는 구운 뒤 **이미지 안**을 다시 센다 — 겉이 아니라 결과.
  #    .dockerignore 나 COPY 가 어긋나면 이미지는 멀쩡히 구워지고 안이 옛것이다.
  if [ "$KEY" = "trouble" ]; then
    printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TAG"
    IMGFAIL=0
    v=$(docker run --rm --entrypoint sh "$TAG" -c "grep -c 'const cookieAttrs' /app/tools/auth.js" 2>/dev/null | tr -d '\r')
    printf '      /app/tools/auth.js 의 cookieAttrs 줄: %s개 (기대 1 이상)\n' "${v:-0}"
    if isnum "${v:-}" && [ "${v:-0}" -ge 1 ]; then printf '  ✓ 이미지 안에 cookieAttrs 가 있다\n'
    else printf '  ✗ 이미지 안에 cookieAttrs 가 없다 — .dockerignore 나 COPY 를 보세요\n'; IMGFAIL=1; fi
    v=$(docker run --rm --entrypoint sh "$TAG" -c "grep -cF 'auth.cookieAttrs(req, maxAgeSec, TX_PATH)' /app/tools/sso.js" 2>/dev/null | tr -d '\r')
    printf '      /app/tools/sso.js 가 cookieAttrs 를 쓰는 줄: %s개 (기대 1 이상)\n' "${v:-0}"
    if isnum "${v:-}" && [ "${v:-0}" -ge 1 ]; then printf '  ✓ rfsso(왕복 쿠키)가 같은 함수를 쓴다\n'
    else printf '  ✗ rfsso 가 그 함수를 안 쓴다 — Secure 가 다시 빠질 수 있다\n'; IMGFAIL=1; fi
    if [ "$IMGFAIL" != 0 ]; then
      printf '%s\n' "🔴 이미지 안이 온전하지 않다. 올리지 마세요."
      BFAIL=$((BFAIL+1))
    fi
  fi
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  구운 것 %s / %s · 실패 %s\n' "$BUILT" "$HOWMANY" "$BFAIL"
if [ "$BFAIL" != "0" ]; then printf '%s\n' "🔴 실패가 있다. 위를 보세요."; exit 1; fi

# ══ 🔴 40-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 40-deploy.sh 의 TARS 는 **비어 있는 채로** 올라간다. 비어 있으면 그
#     파일이 ? 로 세고 「옮기다 깨진 것」만 잡는다 — 아래 두 줄을 그 파일의
#     TARS 에 그대로 붙여 넣는다. 🔴 **이번엔 다섯째 줄(마이그레이션 묶음)이 없다.**
printf '\n%s\n' "════════ 40-deploy.sh 의 TARS 에 붙여 넣을 것 ════════"
printf '%s' "$TARTABLE"
printf '%s\n' "  🔴 위 두 줄을 TARS 에 넣는다. 🔵 as-migrations.tar.gz 는 이번엔 없다 — 만들지 않았다."

printf '\n%s\n' "✅ 둘 다 구웠다. tar · 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'
printf '\n%s\n' "🔵 다음 — 올릴 곳이 **둘**이다 (대화에서 내가 한다):"
printf '%s\n' "    · 이미지 tar 둘  → NAS 의 /volume1/dss/images/"
printf '%s\n' "      (dss-as-3.3.tar · dss-rf-trouble-0.3.tar)"
printf '%s\n' "    · 40-deploy.sh 자신 → NAS 의 /volume1/dss/setup/  (md5 를 맞춘다)"
printf '%s\n' "🔵 **마이그레이션 묶음은 없다** — 이번 판은 drizzle/ 이 0건이다."
printf '%s\n' "────────────────────────────────────────────────────────────"
