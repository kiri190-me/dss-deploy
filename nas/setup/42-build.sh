#!/bin/bash
# dss-deploy/nas/setup/42-build.sh — 서른아홉째 배포 · 이미지 굽기 (2026-10-29)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · Git Bash) ────────────────────────────────────
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/42-build.sh" --check
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/42-build.sh" --go
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-39):
#     bash .../42-build.sh --go "/d/배포본/_images-39"
#
# ── 이번에 굽는 것 — **저장소 하나, 이미지 둘** ───────────────────────
#     ① A/S 앱   dss-as:3.4       → **dss-as:3.5**        커밋 3  스테이지 기본(runner)
#     ② A/S 도구 dss-as-tools:2   → **dss-as-tools:3**    커밋 3  🔴 --target tools
#
#   🔵 저장소는 RF_Service_System 하나인데 이미지는 둘이다 — 41-build.sh 가 서른여덟째
#      배포에서 한 것과 같은 모양이다(같은 저장소를 두 번, 한 번은 기본·한 번은
#      --target tools).
#   🔴 **나머지 아홉은 안 굽는다** — 통합 로그인 · PO · 재고 · 게시판 · 계측기 ·
#      개선요청 · RF 이슈관리 · 휴가 · 통합 승인함 아홉은 마지막 커밋이 전부
#      2026-10-27 이전이다. 서른여덟째 배포(10-28) 뒤로 한 줄도 안 쌓였다
#      (2026-10-29 실측).
#
# ── 🔴 마이그레이션 — 이번에도 **0건이다** ────────────────────────────
#   RF_Service_System 의 drizzle/ 이 기준 SHA(eb6feda) 이후 **한 글자도 안
#   바뀌었다**(2026-10-29 'git diff --name-only -- drizzle/' 로 확인, 0줄).
#   🔴 그래서 **as-migrations.tar.gz 를 만들지도 보내지도 않는다.** NAS 의
#      /volume1/dss/as-migrations 는 39번이 올려 둔 121 그대로다.
#
# ── 🔴 A/S 도구를 **이번에도 굽는다** — 그 판정이 넉 달 사이 세 번 어긋났다 ──
#   🔵 **서른여섯째**: 「마이그레이션 0건이니 도구는 안 굽는다」 → **틀렸다.**
#      도구에 비상구 둘이 들어 있었고 못 쓰는 상태였다(README 36번 절).
#   🔵 **서른일곱째**: 잣대를 「그 도구가 실제로 부르는 명령이 바뀌었는가」로
#      바꿔 안 구웠다 → **맞았다**(tools-as 가 부르는 db:migrate·db:preflight
#      둘은 볼륨만 읽어 이미지 안의 src/ 가 무엇이든 상관이 없었다).
#   🔵 **서른여덟째**: 그 잣대로는 「**늘어난** 명령」이 안 걸렸다. package.json 의
#      scripts 에 한 줄이 늘었는데 「바뀌었나」로만 재서 못 잡을 뻔했고, 안 구웠으면
#      'npm error Missing script' 가 날 자리였다. 그래서 잣대를 「바뀌었나」가
#      아니라 「늘거나 줄었나」로 고쳐 적었다.
#   🔴 **서른아홉째(이번)에는 그 고친 잣대로도 안 걸린다.** 'package.json' 이
#      **0줄** 바뀌었기 때문이다(2026-10-29 실측). 그런데 'scripts/' 는
#      **7파일 2,202줄**이 늘었다 — 이번 도구가 **npm 명령이 아니라 직접 호출하는
#      도구**라서다:
#        node --conditions=react-server --import tsx scripts/backfill-kyosan-used-parts.ts
#      npm 을 거치지 않으니 package.json 에 한 줄도 안 늘고, 그래서 지난 판의
#      잣대가 이번엔 「안 구워도 된다」는 **틀린 답**을 준다.
#   🔵 **이번 판의 잣대 — Dockerfile 의 tools 스테이지가 담는 것 전부를 센다**:
#        git diff eb6feda..HEAD -- scripts/ package.json drizzle.config.ts tsconfig.json vendor/
#      하나라도 달라졌으면 굽는다. 아래 5절이 이 셈을 그대로 한다.
#   🔴 **--target tools 로 굽는다.** 안 주면 runner 가 구워지고 그 안에는
#      scripts/ 도 package.json 도 없어 조용히 쓸모없는 이미지가 된다
#      (RF_Service_System/Dockerfile 은 tools 스테이지를 runner **앞에** 둔다 —
#      --target 없이 구우면 마지막 스테이지인 runner 가 기본값이 된다).
#
# ── 🔴 41번과 다른 것 — 도구 이미지 안을 **다른 방식으로** 센다 ────────
#   41번은 'npm run check:part-name-overlap' 을 불러 **「Missing script」냐
#   「DATABASE_URL is not set.」이냐**로 갈랐다. 🔴 **이번엔 그 신호 자체가
#   안 난다** — 이번 도구는 npm 명령이 아니라서 npm 이 할 말이 없다.
#   🔵 발상은 그대로 쓴다. **DATABASE_URL 을 안 준 채 불러 import 단계에서
#      죽는지** 본다 — 'scripts/backfill-kyosan-used-parts.ts' 가 1줄에서
#      './load-env' 를, 9줄에서 '../src/lib/db/connection' 을 **정적 import**
#      하고, 'connection.ts' 12-18줄이 모듈 맨 위에서 동기적으로 던진다
#      ('DATABASE_URL is not set.'). 인자를 안 줘도 파싱까지 안 가고 import
#      에서 막힌다. 그래서 네 단계로 센다:
#        ① /app/package.json 이 있나 (없으면 runner 를 잘못 구운 것)
#        ② 새 파일 셋이 담겼나
#        ③ /app/node_modules/tsx 가 있나 (이 도구는 tsx 로만 돈다)
#        ④ 값으로 받아 본다 — 'DATABASE_URL is not set' 이면 ✓
#   🔴 **「✗ 가 아니면 ✓」로 세지 않는다.** ✓ 조건만 정확히 적고 나머지는 ? 다 —
#      ✓ 쪽 오판은 영영 안 드러난다.
#   🔵 **DB 에 닿지 않는다** — 값을 보되 운영 자료는 안 건드린다.
#
# ── 🔴 모드 둘 ────────────────────────────────────────────────────────
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다.
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면
#            굽지 않고 멈춘다. 전부 ✓ 일 때만 둘을 굽고 tar 로 뽑는다.
#            그리고 도구 이미지 안을 센다(겉이 아니라 결과).
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 이 환경의 함정 (36·37·39·40·41-build.sh 에서 그대로 가져온 처방) ──
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싸고, 저장소 자리를
#      이 파일의 자리에서 계산한다(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:\… 를 /c/… 로
#      바꾸고, docker save 는 작업 폴더로 들어가 **상대경로**로 쓴다.
#   ③ 🔴 **tar 의 Config 를 docker image inspect .Id 와 맞대지 마라.** 맞댈
#      상대는 **빌드 로그의 exporting config sha256:** 이다.
#   ④ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를
#      막는다). 다만 메모리는 다르다 — 열이 떠 있으면 빌드가 죽을 수 있다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안의 백틱은 명령 치환으로 읽힌다 → 이 파일에는 백틱이
#      **한 개도 없다**(주석에도 안 썼다). 쓴 뒤 세었다.
#   ② 읽기 전용 자리의 콜론과 꺾쇠로 빈 파일을 만드는 꼴은 ash 를 죽인다 →
#      이 파일은 개발 PC(Git Bash) 에서만 돌고, 그 꼴이 **한 군데도 없다.**
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

# tar 안 manifest.json 의 Config 지문 (39·40·41-build.sh 의 것을 글자 그대로)
tar_config_id() { # 1 tar
  tar -xOf "$1" manifest.json 2>/dev/null \
    | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 \
    | sed 's|blobs/sha256/|sha256:|'
}

# 한 저장소의 drizzle/ 을 센다 → ".sql수 journal수"
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
#      이번엔 **0 이어야** 맞다 — drizzle/ 이 한 글자도 안 바뀌었다.
#   🔵 일곱째 칸(커밋 수)은 ✗ 로 세지 않고 ⚠️ 로만 센다 — 적어 둔 수와
#      어긋나면 표가 낡았다는 뜻이라 사람이 봐야 한다. 이번 셋은
#      b4ee9c4 · 7e6ea8c · a728418 이다.
#   🔴 'astools' 는 **같은 저장소**(RF_Service_System)를 --target tools 로 한 번
#      더 굽는 줄이다. 저장소를 세는 자리에서는 이 줄을 건너뛴다(41번과 같은
#      처리) — 두 번 세면 ✗ 도 두 번 센다.
SITES='
as|RF_Service_System|dss-as:3.5|eb6feda|-|0|3
astools|RF_Service_System|dss-as-tools:3|eb6feda|tools|0|3
'
HOWMANY=2
TOOLS_TAG=dss-as-tools:3

# ── 🔴 기대값과 그 출처 ───────────────────────────────────────────────
#   [저장소] 2026-10-29 개발 PC 의 저장소에서 센 값
AS_SQL_WANT=121       # [저장소] RF_Service_System/drizzle/*.sql — 안 늘어야 한다(0120 까지 그대로)
CORE_PIN=05018b077a780922b484a7a539665f35d5207c82   # vendor/dss-core 포인터 — 안 움직였다
# 🔴 5절이 쓰는 기준 SHA. **SITES 표의 넷째 칸과 같은 값이어야 한다** — 41번에서는
#    이 값이 표와 따로 적혀 있어 한쪽만 고치면 조용히 어긋날 자리였다. 5절 첫 줄이
#    둘을 맞대어 본다.
AS_BASE=eb6feda

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-39"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

printf '%s\n' "서른아홉째 배포 · 이미지 굽기   $(date '+%Y-%m-%d %H:%M:%S')"
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

# ── 2. 저장소 하나 (이미지 둘) ────────────────────────────────────────
printf '\n== 2. 저장소 하나 (이미지 둘)\n'
printf '%s\n' "🔴 미커밋·미푸시가 있으면 구운 이미지를 나중에 재현하지 못한다."
printf '%s\n' "🔴 **안 받은 것도 센다** — 낡은 코드를 굽고도 모른다."
printf '%s\n' "$SITES" | while IFS='|' read -r KEY REPO TAG BASE TGT WANTMIG WANTN; do
  [ -n "${KEY:-}" ] || continue
  [ "$KEY" = astools ] && continue   # 🔵 A/S 앱에서 이미 쟀다. 같은 저장소다.
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
  [ "$KEY" = astools ] && continue   # 🔵 이미 셌다. 두 번 세면 ✗ 도 두 번이다.
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
if [ "$REPO_BAD" = "0" ]; then ok "저장소 하나 깨끗하고 drizzle 변경 수가 적어 둔 그대로(0)"
else bad "저장소 검사에서 어긋난 것 ${REPO_BAD}가지 — 위 ✗ 를 보세요"; fi

# ── 3. 🔴 A/S 의 서브모듈 둘 — 빈 폴더면 빌드가 크게 실패한다 ─────────
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
printf '\n== 4. A/S 의 drizzle/ — 전체가 %s 그대로여야 한다\n' "$AS_SQL_WANT"
AS_COUNTS=$(count_drizzle "$ASDIR"); AS_SQL=${AS_COUNTS%% *}; AS_JRN=${AS_COUNTS##* }
say "RF_Service_System/drizzle — .sql ${AS_SQL}장 · meta/_journal.json 의 idx ${AS_JRN}개"
if [ "${AS_SQL:-0}" = "$AS_SQL_WANT" ] && [ "${AS_JRN:-0}" = "$AS_SQL_WANT" ]; then
  ok "${AS_SQL_WANT} 그대로다 (이번 판은 마이그레이션이 없다 — 볼륨은 39번 것을 그대로 쓴다)"
else
  bad "drizzle 이 .sql ${AS_SQL:-?} · idx ${AS_JRN:-?} 다 — **${AS_SQL_WANT} 그대로여야 한다.** 전제가 깨졌으니 멈추고 알릴 것"
fi

# ── 5. 🔴 A/S 도구 — 소스가 새 도구를 담고 있어야 한다 ────────────────
#  🔴 이번 판의 까닭이 여기다. .dockerignore 나 Dockerfile 이 어긋나면
#     이미지는 멀쩡히 구워지고 **새 도구만 조용히 빠진다.**
printf '\n== 5. A/S 도구 — 소스가 새 도구를 담고 있어야 한다\n'
# 🔴 기준 SHA 가 표와 이 절에 **두 벌로** 적혀 있다. 한쪽만 고치면 조용히 어긋나므로
#    먼저 맞대어 본다.
AS_ROW_BASE=$(printf '%s\n' "$SITES" | tr -d ' ' | grep '^as|' | head -1 | cut -d'|' -f4)
if [ "${AS_ROW_BASE:-}" = "$AS_BASE" ]; then
  ok "기준 SHA 가 SITES 표와 이 절에서 같다 ($AS_BASE)"
else
  bad "기준 SHA 가 어긋난다 — SITES 표는 ${AS_ROW_BASE:-못 읽음} · 이 절은 $AS_BASE. 둘을 맞추세요"
fi
if grep -q '^FROM .* AS tools' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "Dockerfile 에 tools 스테이지가 있다 (--target tools 가 선다)"
else
  bad "Dockerfile 에 tools 스테이지가 없다 — --target tools 가 실패한다"
fi
if grep -qE '^COPY .*scripts \./scripts' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 scripts/ 를 담는다 (새 도구의 파일이 들어간다)"
else
  bad "Dockerfile 이 scripts/ 를 안 담는다 — 새 도구가 통째로 빠진다"
fi
if grep -qE '^COPY .*package\.json' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 package.json·tsconfig.json 을 담는다 (tsx 가 paths 를 읽는 길)"
else
  bad "Dockerfile 이 package.json 을 안 담는다"
fi
# 🔵 이번 도구는 npm 명령이 아니라 **직접 호출**이라 src/ 와 vendor/ 가 41번보다
#    더 중요하다 — 백필이 '../src/lib/db/connection' 을 정적 import 하고 그 끝이
#    vendor/dss-core 의 스키마다. 2026-09-21 에 스키마를 서브모듈로 옮긴 뒤
#    vendor 를 빠뜨려 운영 도구가 전부 죽은 적이 있다(Dockerfile 71-76줄 주석).
if grep -qE '^COPY .*src \./src' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 src/ 를 담는다 (백필이 connection.ts 를 찾는 길)"
else
  bad "Dockerfile 이 src/ 를 안 담는다 — 백필이 connection.ts 를 못 찾는다"
fi
if grep -qE '^COPY .*vendor \./vendor' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 vendor/ 를 담는다 (@dss/core 스키마를 찾는 길)"
else
  bad "Dockerfile 이 vendor/ 를 안 담는다 — Cannot find module @dss/core/schema 가 난다"
fi
for d in scripts; do
  if grep -qE "^${d}/?\$" "$ASDIR/.dockerignore" 2>/dev/null; then
    bad ".dockerignore 가 ${d}/ 을 막는다 — 빈 폴더가 구워진다"
  else
    ok ".dockerignore 가 ${d}/ 을 막지 않는다"
  fi
done
# 🔴 이번에 굽는 까닭이 되는 파일 셋. 하나라도 없으면 담을 것이 없다.
for f in scripts/backfill-kyosan-used-parts.ts \
         scripts/lib/kyosan-used-parts-backfill.ts \
         scripts/lib/kyosan-used-parts-backfill-plan.ts; do
  if [ -s "$ASDIR/$f" ]; then
    ok "$f 가 저장소에 있다"
  else
    bad "$f 가 없다 — 담을 것이 없다"
  fi
done
# 🔴 **이번 판의 핵심 확인.** 「도구를 구울 까닭이 있나」를 **tools 스테이지가 담는
#    것 전부**로 센다. package.json 의 scripts 줄만 보면 이번엔 0 이 나와
#    「안 구워도 된다」는 틀린 답이 나온다(머리말).
#    🔴 **src/ 를 빠뜨리지 마라.** Dockerfile 의 tools 스테이지가 COPY src ./src
#       를 한다(바로 위에서 그것을 검사하고 있다). 도구들은 src/lib/db/… 를
#       import 하므로, **src/ 만 바뀐 판**에서 이 목록에 src 가 없으면 0 이 나와
#       「안 구워도 된다」는 **바로 이 절이 막으려던 틀린 답**이 다시 나온다.
TOOLS_PATHS="scripts/ src/ package.json drizzle.config.ts tsconfig.json vendor/"
TOOLS_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | wc -l | tr -d ' ')
PKG_LINES=$(git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | wc -l | tr -d ' ')
say "tools 스테이지가 담는 것 중 달라진 파일 ${TOOLS_CHANGED:-못 쟀다}개 · 그중 package.json 의 diff 는 ${PKG_LINES:-못 쟀다}줄"
if isnum "${TOOLS_CHANGED:-}" && [ "${TOOLS_CHANGED:-0}" -ge 1 ]; then
  ok "도구를 구울 까닭이 있다 — 기준 $AS_BASE 이후 달라진 파일 ${TOOLS_CHANGED}개"
  git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | head -10 | sed 's/^/      /'
else
  bad "달라진 파일이 ${TOOLS_CHANGED:-못 쟀다}개다 — 도구를 구울 까닭이 없다. 전제가 깨졌으니 멈추고 알릴 것"
fi
# 🔵 그리고 **package.json 이 0줄인 것이 맞다** — 이번 도구는 npm 명령이 아니다.
#    ⚠️ 로만 센다(✗ 가 아니다). 늘었다면 그것은 「굽지 마라」가 아니라
#    「부를 이름이 하나 더 생겼다」는 뜻이고, 사람이 그 이름을 확인해야 한다.
if [ "${PKG_LINES:-x}" = "0" ]; then
  ok "package.json 은 0줄 바뀌었다 — 이번 도구는 npm 명령이 아니라 **직접 호출**이다 (적어 둔 그대로)"
else
  note "package.json 이 ${PKG_LINES}줄 바뀌었다 — 적어 둔 것은 0줄이다. 새 npm 명령이 늘었다면 그 이름도 함께 확인하세요"
  git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | grep -E '^[-+] ' | head -8 | sed 's/^/      /'
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

  # 🔴 도구 이미지만 --target tools 다. 안 주면 **runner 가 구워지고** 그 안에는
  #    scripts/ 도 package.json 도 없어 오류 없이 쓸모없는 이미지가 된다.
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

  # 🔴 A/S 도구는 구운 뒤 **이미지 안**을 다시 센다 — 겉이 아니라 결과.
  #    🔴 41번과 달리 npm 을 거치지 않는다 — 이번 도구는 npm 명령이 아니다.
  if [ "$KEY" = "astools" ]; then
    printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TAG"
    IMGFAIL=0
    # ① runner 가 아니라 tools 인가 — runner 에는 /app/package.json 이 없다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '      /app/package.json: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tools 스테이지가 맞다\n'
    else printf '  ✗ /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다\n'; IMGFAIL=1; fi
    # ② 새 파일 셋이 다 담겼는가 — 하나라도 없으면 ✗.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts /app/scripts/lib/kyosan-used-parts-backfill-plan.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "3" ]; then printf '  ✓ 새 도구 파일 셋이 다 들어갔다\n'
    else printf '  ✗ 새 도구 파일이 %s/3 개다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
    # ③ tsx 가 있는가 — 이 도구는 tsx 로만 돈다(운영 이미지에는 없는 devDependency다).
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '      /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tsx 가 있다\n'
    else printf '  ✗ tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
    # ④ 🔴 **값을 받아 본다.** DATABASE_URL 을 안 주고 부른다 — 백필이 1·9줄에서
    #    './load-env' 와 '../src/lib/db/connection' 을 정적 import 하고,
    #    connection.ts 가 모듈 맨 위에서 던진다. 인자를 안 줘도 파싱까지 안 가고
    #    import 에서 막힌다. **DB 에는 한 글자도 안 닿는다.**
    #    🔴 ✓ 조건만 정확히 적는다. 「✗ 가 아니면 ✓」로 세지 않는다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'cd /app && node --conditions=react-server --import tsx scripts/backfill-kyosan-used-parts.ts 2>&1 | head -40' 2>&1 | tr -d '\r')
    if printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
      printf '  ✓ import 까지 갔고 DB 에는 안 닿았다 (DATABASE_URL is not set — 기대한 답)\n'
    elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
      printf '  ✗ 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다\n'
      printf '%s\n' "$v" | head -20 | sed 's/^/      /'
      IMGFAIL=1
    else
      printf '  ? 기대한 답이 아니다 — 아래 20줄을 사람이 보세요\n'
      printf '%s\n' "$v" | head -20 | sed 's/^/      /'
      IMGFAIL=1
    fi
    # ⑤ 🔵 이미지 안의 drizzle/ 은 **비어 있어야** 한다 — 볼륨으로 붙는 자리다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d '\r')
    printf '      /app/drizzle 안 .sql: %s개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)\n' "${v:-?}"
    if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ drizzle/ 이 비어 있다 (이미지에 안 굽는다)\n'
    else printf '  ✗ drizzle/ 에 .sql 이 들었다 — 이미지가 28MB 를 더 메고 다닌다\n'; IMGFAIL=1; fi
    if [ "$IMGFAIL" != 0 ]; then
      printf '%s\n' "🔴 이미지 안이 온전하지 않다. 올리지 마세요."
      BFAIL=$((BFAIL+1))
    fi
  fi
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  구운 것 %s / %s · 실패 %s\n' "$BUILT" "$HOWMANY" "$BFAIL"
if [ "$BFAIL" != "0" ]; then printf '%s\n' "🔴 실패가 있다. 위를 보세요."; exit 1; fi

# ══ 🔴 42-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 42-deploy.sh 의 TARS 는 **이름만 적힌 채로** 올라간다. 지문 칸이 비어 있으면
#     그 파일이 ? 로 세고 「옮기다 깨진 것」만 잡는다 — 아래 두 줄로 그 두 줄을
#     **통째로 갈아 끼운다.** 🔵 마이그레이션 묶음은 이번에도 없다.
printf '\n%s\n' "════════ 42-deploy.sh 의 TARS 에 붙여 넣을 것 ════════"
printf '%s' "$TARTABLE"
printf '%s\n' "  🔴 위 두 줄로 TARS 의 두 줄을 통째로 갈아 끼운다. 🔵 as-migrations.tar.gz 는 이번에도 없다."

printf '\n%s\n' "✅ 둘 다 구웠다. tar · 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'
printf '\n%s\n' "🔵 다음 — 올릴 곳이 **둘**이다 (대화에서 내가 한다):"
printf '%s\n' "    · 이미지 tar 둘  → NAS 의 /volume1/dss/images/"
printf '%s\n' "      (dss-as-3.5.tar · dss-as-tools-3.tar)"
printf '%s\n' "    · 42-deploy.sh 자신 → NAS 의 /volume1/dss/setup/  (md5 를 맞춘다)"
printf '%s\n' "🔵 **마이그레이션 묶음은 없다** — 이번 판도 drizzle/ 이 0건이다."
printf '%s\n' "────────────────────────────────────────────────────────────"
