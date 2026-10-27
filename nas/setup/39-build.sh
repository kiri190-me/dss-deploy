#!/bin/bash
# dss-deploy/nas/setup/39-build.sh — 서른여섯째 배포 · 이미지 굽기 (2026-10-27)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · Git Bash) ────────────────────────────────────
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/39-build.sh" --check
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/39-build.sh" --go
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-36):
#     bash .../39-build.sh --go "/d/배포본/_images-36"
#
# ── 이번에 굽는 것 넷 ─────────────────────────────────────────────────
#     ① 포털      dss-auth:1.9         → **dss-auth:2.0**         커밋 1
#     ② 포털도구  dss-auth-tools:2     → **dss-auth-tools:3**     🔴 --target tools
#     ③ A/S       dss-as:3.1           → **dss-as:3.2**           커밋 8  🔴 마이그레이션 2건
#     ④ 재고      dss-inventory:0.5    → **dss-inventory:0.6**    커밋 2
#
#   🔵 저장소는 셋인데 이미지는 넷이다 — 포털에서 앱과 도구 둘을 굽는다.
#   🔵 **나머지 일곱은 안 굽는다** — PO 0.7 · 게시판 0.3 · 계측기 1.4 ·
#      개선요청 0.5 · RF 이슈관리 0.2 · 휴가 0.4 · 통합 승인함 0.1 은
#      기준 SHA 이후 커밋이 **0** 이다(2026-10-27 실측).
#
#   🔴 그리고 **다섯째 산출물**이 있다 — A/S 마이그레이션 묶음 as-migrations.tar.gz.
#      A/S 의 drizzle/ 은 **이미지에 안 굽는다**(28MB 라 볼륨이다). NAS 의
#      /volume1/dss/as-migrations 를 tools-as 가 :ro 로 읽는다. 그래서 이미지
#      넷만 올리면 **마이그레이션이 0건으로 조용히 끝난다.**
#
# ── 🔴 왜 포털 도구를 굽는가 — **마이그레이션 때문이 아니다** ─────────
#   🔴 포털 마이그레이션은 이번에도 **0건**이다. 도구를 굽는 까닭은 따로 있다.
#
#   포털의 이번 커밋 하나(52cbb19)가 고친 여섯은 Dockerfile · package.json ·
#   scripts/*.ts 넷이다. 그런데 포털의 **runner 스테이지는 .next/standalone ·
#   .next/static · public 셋만 담는다** — package.json 도 scripts/ 도 거기 없다
#   (dss-auth/Dockerfile 150~192줄). 담는 쪽은 **tools 스테이지**다:
#        package.json · tsconfig.json · drizzle.config.ts · src · drizzle · scripts
#   🔴 그러므로 **앱만 구우면 dss-auth:2.0 은 1.9 와 동작이 같다.**
#
#   🔵 그 커밋이 풀려던 셋 중 purge-expired.ts(감사 로그 3년 보관)는 **이미 돌고
#      있다** — 야간 정리가 npm run 을 안 거치는 길로 2026-10-25 에 풀렸다.
#   🔴 **남은 둘이 까닭이다 — admin:promote · admin:emergency 가 아직 컨테이너에서
#      못 돈다.** 포털은 사내 모든 시스템의 로그인이라 **관리자가 잠기면 되돌릴 다른
#      길이 없다.** 그 비상구 둘을 못 쓰는 채로 두는 것이 위험이라 함께 올린다.
#      (2026-10-27 사용자 승인)
#
# ── 🔴 37번(지난 판)과 다른 것 넷 ─────────────────────────────────────
#   ① 🔴 **도구를 굽는 까닭이 다르다.** 37번은 포털 마이그레이션 둘(0008·0009)을
#      돌리려고 구웠다. 이번엔 **비상구 둘을 쓸 수 있게** 하려고 굽는다.
#      🔴 그래서 39-deploy.sh 에 **포털 DB 를 건드리는 단계가 없다** — 포털은
#      「10 그대로, 늘면 ✗」다.
#   ② 🔴 **마이그레이션이 A/S 쪽이고, 길이 다르다.** 포털은 이미지 안에서 돌았고
#      A/S 는 **볼륨**에서 돈다. 그 길은 31-deploy.sh 가 쓴 것이다.
#   ③ 🔴 **기대하는 마이그레이션 수가 집마다 다르다.** A/S 는 **늘어야** 맞고
#      (119 → 121), 포털·재고는 **그대로여야** 맞다(10 · 26). 둘 다 어긋나면 ✗ 다.
#      🔴 「0 이면 통과」가 아니고 「늘면 통과」도 아니다. **적어 둔 수와 똑같아야** 한다.
#   ④ 🔵 A/S 의 서브모듈 둘(vendor/dss-core · vendor/dss-ui)을 굽기 **전에** 센다.
#      빈 폴더면 빌드가 크게 실패하거나(모듈 없음) 조용히 옛 화면이 구워진다.
#
# ── 🔴 도구 이미지는 --target tools 로 굽는다 ─────────────────────────
#   🔴 안 주면 **runner 가 구워진다.** 그 안에는 scripts/ 도 drizzle/ 도 없어
#      오류 없이 **조용히 쓸모없는 이미지**가 된다(37번 머리말의 그 경고).
#   🔴 그래서 이 파일은 굽고 나서 **이미지 안을 넷으로 센다** — .sql · journal ·
#      비상구 스크립트 둘 · package.json 의 그 깃발. 그리고 🔴 **이미지 안의 node 가
#      --env-file-if-exists 를 실제로 아는지 값을 받아 본다.** 그것이 52cbb19 가
#      기대는 바로 그 동작이고, 모르면 비상구가 그 자리에서 또 죽는다.
#
# ── 🔴 모드 둘 ────────────────────────────────────────────────────────
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다.
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면
#            굽지 않고 멈춘다. 전부 ✓ 일 때만 넷을 굽고 tar 로 뽑는다.
#            그리고 도구 이미지 안을 세고, A/S 마이그레이션 묶음을 만들어 안을 센다.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 이 환경의 함정 (36·37-build.sh 에서 그대로 가져온 처방) ─────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싸고, 저장소 자리를 적어
#      넣지 않고 **이 파일의 자리에서 계산한다**(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:\… 를 /c/… 로
#      바꾸고, docker save 와 마이그레이션 묶기는 **작업 폴더로 들어가 상대경로**로 쓴다.
#   ③ 🔴 **tar 의 Config 를 docker image inspect .Id 와 맞대지 마라.** 요즘
#      Docker 는 그 둘이 애초에 다른 값이다(하나는 config 블롭, 하나는 매니페스트).
#      맞댈 상대는 **빌드 로그의 exporting config sha256:** 이다.
#   ④ 🔵 docker build 는 개발 서버를 안 내려도 된다 — .dockerignore 가 .next 를
#      막아 호스트의 .next 가 빌드 문맥에 아예 안 들어간다. 다만 **메모리**는
#      다르다. 열이 떠 있으면 빌드가 죽을 수 있다.
#   ⑤ 🔴 **마이그레이션 묶음은 git archive 로 뽑지 마라** — 서브모듈이 빈 폴더로
#      나온다(31번의 그 주석). 작업 폴더의 drizzle/ 을 그대로 묶는다.
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

# tar 안 manifest.json 의 Config 지문 (37-build.sh 의 것을 글자 그대로)
tar_config_id() { # 1 tar
  tar -xOf "$1" manifest.json 2>/dev/null \
    | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 \
    | sed 's|blobs/sha256/|sha256:|'
}

# 한 저장소의 drizzle/ 을 센다 → ".sql수 journal수"
count_drizzle() { # 1 저장소 폴더
  local s j
  s=$(ls -1 "$1/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  # 🔴 _journal.json 은 drizzle/ 바로 아래가 아니라 **meta/ 안**이다.
  #    drizzle/ 에서 찾으면 0 이 나와 가짜 ✗ 가 난다.
  j=$(grep -o '"idx"' "$1/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  printf '%s %s' "${s:-0}" "${j:-0}"
}

# ══ 이번에 굽는 것 — 한자리에 모아 둔다 ═══════════════════════════════
#   열쇠|저장소 폴더|새 태그|기준 SHA|--target(없으면 -)|기대 drizzle 파일 수|기대 커밋 수
#
#   🔴 여섯째 칸은 「기준 SHA 이후 drizzle/ 에서 **달라진 파일 수**」다.
#      마이그레이션 둘이면 .sql 둘 + meta/snapshot 둘 + _journal.json 하나 = **5** 다.
#      「0 이면 통과」가 아니라 **적어 둔 수와 똑같아야** 통과다.
#   🔵 일곱째 칸(커밋 수)은 ✗ 로 세지 않고 ⚠️ 로만 센다 — 현황판 같은 문서 커밋이
#      하나 더 붙어도 **구워지는 것은 달라지지 않기** 때문이다. 다만 **줄어들면**
#      표가 낡았다는 뜻이라 사람이 봐야 한다. 그래서 어긋나면 목록을 찍는다.
#   🔴 authtools 는 **같은 저장소**(dss-auth)를 --target tools 로 한 번 더 굽는 줄이다.
#      그래서 저장소를 세는 자리에서는 이 줄을 건너뛴다 — 두 번 세면 ✗ 도 두 번 센다.
SITES='
auth|dss-auth|dss-auth:2.0|069d670|-|0|1
authtools|dss-auth|dss-auth-tools:3|069d670|tools|0|1
as|RF_Service_System|dss-as:3.2|0fe76d4|-|5|8
inventory|dss-inventory|dss-inventory:0.6|6bbd5b3|-|0|2
'
HOWMANY=4
TOOLS_TAG=dss-auth-tools:3

# ── 🔴 기대값과 그 출처 ───────────────────────────────────────────────
#   [저장소] 2026-10-27 개발 PC 의 저장소에서 센 값
#   [볼륨]   2026-10-27 운영 /volume1/dss/as-migrations 를 읽어서 센 값
AS_SQL_WANT=121       # [저장소] RF_Service_System/drizzle/*.sql — 0120 까지면 121장
AUTH_SQL_WANT=10      # [저장소] dss-auth/drizzle — **그대로여야** 한다
INV_SQL_WANT=26       # [저장소] dss-inventory/drizzle — **그대로여야** 한다
CORE_PIN=05018b077a780922b484a7a539665f35d5207c82   # vendor/dss-core 포인터

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-36"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

printf '%s\n' "서른여섯째 배포 · 이미지 굽기   $(date '+%Y-%m-%d %H:%M:%S')"
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

# ── 2. 저장소 셋 ──────────────────────────────────────────────────────
#  🔵 저장소는 셋인데 이미지는 넷이다 — 포털에서 앱과 도구 둘을 굽는다.
printf '\n== 2. 저장소 셋 (이미지 넷)\n'
printf '%s\n' "🔴 미커밋·미푸시가 있으면 구운 이미지를 나중에 재현하지 못한다."
printf '%s\n' "🔴 **안 받은 것도 센다** — 낡은 코드를 굽고도 모른다."
printf '%s\n' "$SITES" | while IFS='|' read -r KEY REPO TAG BASE TGT WANTMIG WANTN; do
  [ -n "${KEY:-}" ] || continue
  [ "$KEY" = authtools ] && continue   # 🔵 포털은 위에서 이미 쟀다. 같은 저장소다.
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
#    🔵 커밋 수는 여기서 세지 않는다 — 위에서 ⚠️ 로만 다뤘다.
REPO_BAD=0
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}
  rest=${rest#*|}; BASE=${rest%%|*}; rest=${rest#*|}; TGT=${rest%%|*}
  rest=${rest#*|}; WANTMIG=${rest%%|*}
  [ "$KEY" = authtools ] && continue   # 🔵 포털은 이미 셌다. 두 번 세면 ✗ 도 두 번이다.
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
if [ "$REPO_BAD" = "0" ]; then ok "저장소 셋 전부 깨끗하고 drizzle 변경 수가 적어 둔 그대로"
else bad "저장소 검사에서 어긋난 것 ${REPO_BAD}가지 — 위 ✗ 를 보세요"; fi

# ── 3. 🔴 A/S 의 서브모듈 둘 — 빈 폴더면 빌드가 크게 실패한다 ─────────
#  🔴 A/S 의 tsconfig paths 가 vendor/dss-core 를 가리키고, 화면은 vendor/dss-ui 의
#     @dss/ui 를 쓴다. 서브모듈을 안 받아 두면 **빌드가 모듈을 못 찾고 죽는다.**
#     죽지 않고 지나가는 쪽이 더 나쁘다 — 옛 메뉴바가 구워져도 오류가 없다.
printf '\n== 3. A/S 의 서브모듈 둘\n'
ASDIR="$DEV/RF_Service_System"
# 🔴 tr 의 지우기 집합에서 빼기표는 **맨 끝**에 둔다. '+- ' 로 적으면 tr 이
#    「+ 부터 공백까지의 범위」로 읽고 ASCII 차례가 거꾸로라 그 자리에서 죽는다
#    (2026-10-27 실측: range-endpoints are in reverse collating sequence order).
#    awk 가 이미 앞뒤 공백을 떼므로 지울 것은 상태 글자 +/- 둘뿐이다.
COREPIN=$(git -C "$ASDIR" submodule status vendor/dss-core 2>/dev/null | awk '{print $1}' | tr -d '+-')
if [ "${COREPIN:-}" = "$CORE_PIN" ]; then
  ok "vendor/dss-core 포인터가 ${CORE_PIN:0:7} 다 (적어 둔 그대로)"
elif [ -n "${COREPIN:-}" ]; then
  bad "vendor/dss-core 포인터가 ${COREPIN:0:7} 다 — **${CORE_PIN:0:7} 을 기대했다.** 멈추고 알릴 것"
else
  bad "vendor/dss-core 포인터를 못 읽었다 — 서브모듈이 아예 없다"
fi
# 🔴 포인터만 맞는 것으로는 모자라다 — 실제로 **파일이 있는지** 본다.
if [ -s "$ASDIR/vendor/dss-core/package.json" ]; then ok "vendor/dss-core 에 파일이 있다 (빈 폴더가 아니다)"
else bad "vendor/dss-core 가 **빈 폴더**다 — git submodule update --init 을 먼저"; fi
if [ -s "$ASDIR/vendor/dss-ui/package.json" ]; then ok "vendor/dss-ui 에 파일이 있다 (빈 폴더가 아니다)"
else bad "vendor/dss-ui 가 **빈 폴더**다 — 메뉴바·알림 종이 안 구워진다"; fi

# ── 4. 🔴 A/S 마이그레이션 묶음이 담을 것 ─────────────────────────────
#  🔴 A/S 는 drizzle/ 을 **이미지에 안 굽는다**(28MB). NAS 의 볼륨
#     /volume1/dss/as-migrations 를 tools-as 가 :ro 로 읽는다.
#     그래서 여기서 재는 것은 「이미지 안」이 아니라 **저장소의 drizzle/** 이다.
#  🔴 .sql 만으로는 모자라다 — meta/_journal.json 에 없는 .sql 은 drizzle 이
#     **아예 모르고** 적용이 0건으로 조용히 끝난다(30번이 당한 그것).
printf '\n== 4. A/S 마이그레이션 묶음이 담을 것 (볼륨으로 간다)\n'
AS_COUNTS=$(count_drizzle "$ASDIR"); AS_SQL=${AS_COUNTS%% *}; AS_JRN=${AS_COUNTS##* }
say "RF_Service_System/drizzle — .sql ${AS_SQL}장 · meta/_journal.json 의 idx ${AS_JRN}개"
if [ "${AS_SQL:-0}" = "$AS_SQL_WANT" ]; then ok ".sql 이 ${AS_SQL}장이다 (0120 까지면 ${AS_SQL_WANT}장)"
else bad ".sql 이 ${AS_SQL:-?}장이다 — **${AS_SQL_WANT}장을 기대했다**"; fi
if [ "${AS_JRN:-0}" = "$AS_SQL_WANT" ]; then ok "_journal.json 의 idx 가 ${AS_JRN}개다 (.sql 수와 같다)"
else bad "_journal.json 의 idx 가 ${AS_JRN:-?}개다 — 🔴 목록에 없는 .sql 은 **안 돈다**"; fi
for t in 0119 0120; do
  f=$(ls -1 "$ASDIR/drizzle/${t}_"*.sql 2>/dev/null | head -1)
  s=$(ls -1 "$ASDIR/drizzle/meta/${t}_snapshot.json" 2>/dev/null | head -1)
  if [ -n "$f" ] && [ -n "$s" ]; then ok "$t — .sql 과 meta/${t}_snapshot.json 이 둘 다 있다"
  else bad "$t — .sql 또는 meta/${t}_snapshot.json 이 없다 (sql ${f:-없음} / snapshot ${s:-없음})"; fi
done
# 🔴 「지우는 문장」 — 앱의 migration-safety.ts 와 같은 잣대. 기대 0줄이다.
#    🔵 ON DELETE restrict 는 여기 안 걸린다(DELETE FROM 만 센다). 19번이
#       그 자리에서 넘어졌으므로 잣대를 그대로 베껴 쓴다.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
DN=0
for t in 0119 0120; do
  f=$(ls -1 "$ASDIR/drizzle/${t}_"*.sql 2>/dev/null | head -1)
  [ -n "$f" ] || continue
  c=$(grep -ciE "$DESTRUCTIVE_RE" "$f" 2>/dev/null); DN=$((DN + ${c:-0}))
done
if [ "$DN" = "0" ]; then ok "0119·0120 에 지우는 문장이 **없다** (더하기만 한다 → 되돌릴 수 있다)"
else bad "0119·0120 에 지우는 문장이 ${DN}줄 있다 — 고치지 말고 **먼저 알릴 것**"; fi

# ── 5. 🔴 포털 · 재고는 **그대로여야** 맞다 ───────────────────────────
#  🔴 「늘면 멈춘다」가 이 절의 일이다. 도구 이미지를 굽기는 하지만 39-deploy.sh 에
#     **포털 DB 를 건드리는 단계가 없다** — 도구는 비상구 둘을 쓰려고 굽는 것이지
#     마이그레이션 때문이 아니다. 재고도 돌릴 길이 없다(도구를 안 굽는다).
#     늘었다면 이 배포의 설계 자체가 틀린 것이다.
printf '\n== 5. 포털 · 재고의 drizzle — **그대로여야** 한다\n'
AU_COUNTS=$(count_drizzle "$DEV/dss-auth");      AU_SQL=${AU_COUNTS%% *}; AU_JRN=${AU_COUNTS##* }
IN_COUNTS=$(count_drizzle "$DEV/dss-inventory"); IN_SQL=${IN_COUNTS%% *}; IN_JRN=${IN_COUNTS##* }
say "dss-auth/drizzle — .sql ${AU_SQL}장 · idx ${AU_JRN}개  (기대 ${AUTH_SQL_WANT})"
say "dss-inventory/drizzle — .sql ${IN_SQL}장 · idx ${IN_JRN}개  (기대 ${INV_SQL_WANT})"
if [ "${AU_SQL:-0}" = "$AUTH_SQL_WANT" ] && [ "${AU_JRN:-0}" = "$AUTH_SQL_WANT" ]; then
  ok "포털이 ${AUTH_SQL_WANT} 그대로다 (이번에 돌릴 마이그레이션이 없다)"
else
  bad "포털이 .sql ${AU_SQL:-?} · idx ${AU_JRN:-?} 다 — **${AUTH_SQL_WANT} 그대로여야 한다.** 늘었다면 도구 이미지가 필요하다"
fi
if [ "${IN_SQL:-0}" = "$INV_SQL_WANT" ] && [ "${IN_JRN:-0}" = "$INV_SQL_WANT" ]; then
  ok "재고가 ${INV_SQL_WANT} 그대로다 (이번에 돌릴 마이그레이션이 없다)"
else
  bad "재고가 .sql ${IN_SQL:-?} · idx ${IN_JRN:-?} 다 — **${INV_SQL_WANT} 그대로여야 한다**"
fi

# ── 6. 🔴 포털 도구 이미지가 담을 것 (굽기 전에 Dockerfile 로 본다) ───
#  🔴 여기를 안 재면 **쓸모없는 도구 이미지가 조용히 구워지는** 길이 열린다.
#     .dockerignore 가 scripts/ 나 drizzle/ 을 막으면 빈 폴더가 담기고 오류가 안 난다.
#     🔵 굽고 나서 **이미지 안을 다시 센다**(아래 「도구 이미지 안을 센다」 절).
#        이 절은 「담을 수 있나」, 그 절은 「담겼나」다 — 둘 다 본다.
printf '\n== 6. 포털 도구 이미지가 담을 것\n'
AUTHDIR="$DEV/dss-auth"
if grep -q '^FROM .* AS tools' "$AUTHDIR/Dockerfile" 2>/dev/null; then
  ok "Dockerfile 에 tools 스테이지가 있다 (--target tools 가 선다)"
else
  bad "Dockerfile 에 tools 스테이지가 없다 — --target tools 가 실패한다"
fi
# 🔴 비상구 둘이 이번 판의 까닭이다. scripts/ 를 안 담으면 올려도 못 쓴다.
if grep -qE '^COPY .*scripts \./scripts' "$AUTHDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 scripts/ 를 담는다 (비상구 둘이 들어간다)"
else
  bad "Dockerfile 이 scripts/ 를 안 담는다 — **비상구 둘이 그대로 못 쓴다**"
fi
if grep -qE '^COPY .*drizzle \./drizzle' "$AUTHDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 drizzle/ 을 담는다"
else
  bad "Dockerfile 이 drizzle/ 을 안 담는다"
fi
if grep -qE '^COPY .*package\.json' "$AUTHDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 package.json 을 담는다 (npm run 이름으로 부르는 길)"
else
  bad "Dockerfile 이 package.json 을 안 담는다 — npm run 으로 못 부른다"
fi
# 🔴 .dockerignore 가 막으면 **빈 폴더가 구워지고 오류가 안 난다.**
for d in drizzle scripts; do
  if grep -qE "^${d}/?\$" "$AUTHDIR/.dockerignore" 2>/dev/null; then
    bad ".dockerignore 가 ${d}/ 을 막는다 — 빈 폴더가 구워진다"
  else
    ok ".dockerignore 가 ${d}/ 을 막지 않는다"
  fi
done
# 🔴 저장소 쪽에 비상구 둘이 실제로 있는가. 없으면 담을 것이 없다.
for s in promote-admin create-emergency-admin; do
  if [ -s "$AUTHDIR/scripts/$s.ts" ]; then ok "scripts/$s.ts 가 있다"
  else bad "scripts/$s.ts 가 없다 — 담을 것이 없다"; fi
done
# 🔴 **이번 커밋의 핵심.** 이 두 줄이 옛 --env-file= 이면 컨테이너에서 그 자리에
#    죽는다(.env.local 이 없기 때문). 글자로 확인한다.
for k in admin:promote admin:emergency; do
  if grep -q "\"$k\": \"node --env-file-if-exists=" "$AUTHDIR/package.json" 2>/dev/null; then
    ok "package.json 의 $k 가 --env-file-if-exists 다 (컨테이너에서 산다)"
  else
    bad "package.json 의 $k 가 --env-file-if-exists 가 아니다 — **컨테이너에서 그 자리에 죽는다**"
    grep -n "\"$k\"" "$AUTHDIR/package.json" 2>/dev/null | head -2 | sed 's/^/      /'
  fi
done

# ── 7. 태그가 이미 있나 ───────────────────────────────────────────────
printf '\n== 7. 새 태그가 이미 있나\n'
printf '%s\n' "🔵 있으면 **덮어쓴다** — 같은 커밋이면 같은 것이 나오므로 해롭지 않다."
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  rest=${row#*|}; rest=${rest#*|}; TAG=${rest%%|*}
  if docker image inspect "$TAG" >/dev/null 2>&1; then note "$TAG — 이미 있다 (덮어쓴다)"
  else ok "$TAG — 아직 없다"; fi
done

# ── 8. tar 둘 자리 ────────────────────────────────────────────────────
printf '\n== 8. tar 둘 자리\n'
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
  #    scripts/ 도 drizzle/ 도 없어 오류 없이 쓸모없는 이미지가 된다.
  #    🔵 Dockerfile 이 tools 를 runner **앞에** 두는 까닭도 그것이다 —
  #       마지막 스테이지가 docker build 의 기본 대상이라, 뒤에 두면 --target 없이
  #       구운 이미지가 앱이 아니라 도구가 된다(dss-auth/Dockerfile 72~74줄).
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
  #    🔴 PowerShell 로 남긴 로그라면 UTF-16 이라 grep 이 한 줄도 못 찾는다.
  #       이 스크립트는 Git Bash 의 tee 라 UTF-8 이지만, 읽는 쪽을 안전하게 둔다.
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
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  구운 것 %s / %s · 실패 %s\n' "$BUILT" "$HOWMANY" "$BFAIL"
if [ "$BFAIL" != "0" ]; then printf '%s\n' "🔴 실패가 있다. 위를 보세요."; exit 1; fi

# ══ 🔴 도구 이미지 **안**을 센다 — 겉이 아니라 결과 ═══════════════════
#  🔴 --target tools 를 빠뜨렸거나 .dockerignore 가 막았으면 이미지는 멀쩡히
#     구워지고 **안이 비어 있다.** 그때 증상은 비상구를 써야 하는 날의
#     「그런 파일 없음」 한 줄뿐이고, 그날은 되돌릴 다른 길이 없는 날이다.
printf '\n%s\n' "════════ 도구 이미지 안을 센다 ════════"
TFAIL=0
tsh() { docker run --rm --entrypoint sh "$TOOLS_TAG" -c "$1" 2>/dev/null | tr -d '\r' | tail -1; }
# ① 이것이 runner 가 아니라 tools 인가 — runner 에는 /app/package.json 이 없다.
INPKG=$(tsh 'test -f /app/package.json && echo yes || echo no')
printf '    /app/package.json: %s\n' "${INPKG:-못 읽음}"
if [ "${INPKG:-}" = "yes" ]; then printf '  ✓ tools 스테이지가 맞다 (package.json 이 있다)\n'
else printf '  ✗ /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다\n'; TFAIL=1; fi
# ② 마이그레이션 — 이번엔 안 돌리지만, 비어 있으면 다음 판이 조용히 0건이 된다.
INSQLT=$(tsh 'ls /app/drizzle/*.sql 2>/dev/null | wc -l')
INJRNT=$(tsh 'grep -o "\"idx\"" /app/drizzle/meta/_journal.json 2>/dev/null | wc -l')
printf '    /app/drizzle — .sql %s장 · idx %s개 (기대 %s · %s)\n' "${INSQLT:-?}" "${INJRNT:-?}" "$AUTH_SQL_WANT" "$AUTH_SQL_WANT"
if [ "${INSQLT:-0}" = "$AUTH_SQL_WANT" ] && [ "${INJRNT:-0}" = "$AUTH_SQL_WANT" ]; then
  printf '  ✓ 개발 PC 의 drizzle/ 과 같다\n'
else printf '  ✗ 이미지 안이 개발 PC(%s)와 다르다\n' "$AUTH_SQL_WANT"; TFAIL=1; fi
# ③ 🔴 **비상구 둘** — 이번 판의 까닭이다.
INSCR=$(tsh 'ls /app/scripts/promote-admin.ts /app/scripts/create-emergency-admin.ts 2>/dev/null | wc -l')
printf '    비상구 스크립트: %s개 (기대 2)\n' "${INSCR:-?}"
if [ "${INSCR:-0}" = "2" ]; then printf '  ✓ promote-admin.ts · create-emergency-admin.ts 가 들어 있다\n'
else printf '  ✗ 비상구가 %s개다 — scripts/ 가 안 담겼다\n' "${INSCR:-?}"; TFAIL=1; fi
# ④ 🔴 package.json 의 그 두 줄이 **이미지 안에서도** 새 깃발인가.
#    🔵 정규식을 쓰지 않고 grep -F 로 **글자 그대로** 찾는다 — 정규식은 셸·sh·grep
#       세 겹을 지나며 역슬래시가 한 겹씩 삼켜져 조용히 0 이 된다.
INFLAG=$(tsh 'n=0; for k in promote emergency; do grep -qF "\"admin:$k\": \"node --env-file-if-exists=" /app/package.json && n=$((n+1)); done; echo $n')
printf '    이미지 안 package.json 의 --env-file-if-exists 비상구 줄: %s개 (기대 2)\n' "${INFLAG:-?}"
if [ "${INFLAG:-0}" = "2" ]; then printf '  ✓ 비상구 둘이 컨테이너에서 사는 꼴로 들어갔다\n'
else printf '  ✗ %s개다 — 옛 --env-file= 이 섞였다. **컨테이너에서 그 자리에 죽는다**\n' "${INFLAG:-?}"; TFAIL=1; fi
# ⑤ 🔴 **값을 받아 본다.** 이미지 안의 node 가 그 깃발을 실제로 아는가.
#    없는 파일을 주고도 조용히 지나가야 맞다 — 그것이 52cbb19 가 기대는 동작이다.
#    🔵 비상구 스크립트를 돌리지 않는다. 깃발만 재는 자리다(DB 에 닿지 않는다).
INNODE=$(docker run --rm --entrypoint node "$TOOLS_TAG" \
           --env-file-if-exists=/nonexistent.env -e "console.log('FLAG_OK')" 2>&1 | tr -d '\r' | tail -1)
printf '    node --env-file-if-exists=<없는 파일> → %s\n' "${INNODE:-없음}"
if [ "${INNODE:-}" = "FLAG_OK" ]; then printf '  ✓ 이미지 안 node 가 그 깃발을 안다 (파일이 없어도 지나간다)\n'
else printf '  ✗ FLAG_OK 가 아니다 — node 가 그 깃발을 모른다. 비상구가 또 죽는다\n'; TFAIL=1; fi
if [ "$TFAIL" != "0" ]; then printf '%s\n' "🔴 도구 이미지가 온전하지 않다. 올리지 마세요."; exit 1; fi

# ══ 🔴 다섯째 산출물 — A/S 마이그레이션 묶음 ══════════════════════════
#  🔴 이것이 없으면 이미지 넷을 다 올려도 **마이그레이션이 0건으로 끝난다.**
#  🔴 git archive 로 뽑지 않는다 — 서브모듈이 빈 폴더로 나온다. 작업 폴더의
#     drizzle/ 을 그대로 묶는다(drizzle/ 안에는 서브모듈이 없다).
#  🔴 묶은 뒤 **안을 센다.** 「파일이 생겼다」와 「담겼다」는 다르다.
printf '\n%s\n' "════════ A/S 마이그레이션 묶음 ════════"
MIGTAR="$OUT/as-migrations.tar.gz"
rm -f "$MIGTAR" 2>/dev/null
if ( cd "$ASDIR" && tar -czf "$MIGTAR" drizzle ) </dev/null; then
  msz=$(stat -c %s "$MIGTAR" 2>/dev/null || wc -c < "$MIGTAR")
  mm5=$(md5sum "$MIGTAR" | awk '{print $1}')
  printf '  ✓ as-migrations.tar.gz (%s바이트)\n' "$msz"
  printf '    md5  %s\n' "$mm5"
else
  printf '  ✗ 묶기 실패\n'; exit 1
fi
# 🔴 안을 센다 — .sql 과 meta/_journal.json 의 idx 둘 다.
INSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -c '^drizzle/[0-9].*\.sql$')
INJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
IN19=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -c '^drizzle/meta/0119_snapshot\.json$')
IN20=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -c '^drizzle/meta/0120_snapshot\.json$')
printf '    묶음 안 .sql %s장 · _journal.json 의 idx %s개 · 0119 스냅샷 %s · 0120 스냅샷 %s\n' \
  "${INSQL:-?}" "${INJRN:-?}" "${IN19:-?}" "${IN20:-?}"
MFAIL=0
[ "${INSQL:-0}" = "$AS_SQL_WANT" ] || { printf '  ✗ 묶음 안 .sql 이 %s장이다 (%s장이어야 한다)\n' "${INSQL:-?}" "$AS_SQL_WANT"; MFAIL=1; }
[ "${INJRN:-0}" = "$AS_SQL_WANT" ] || { printf '  ✗ 묶음 안 idx 가 %s개다 (%s개여야 한다) — 🔴 적용이 0건으로 끝난다\n' "${INJRN:-?}" "$AS_SQL_WANT"; MFAIL=1; }
[ "${IN19:-0}" = "1" ] || { printf '  ✗ meta/0119_snapshot.json 이 묶음에 없다\n'; MFAIL=1; }
[ "${IN20:-0}" = "1" ] || { printf '  ✗ meta/0120_snapshot.json 이 묶음에 없다\n'; MFAIL=1; }
if [ "$MFAIL" = "0" ]; then printf '  ✓ 묶음 안이 저장소와 같다 (%s · %s · 스냅샷 둘)\n' "$AS_SQL_WANT" "$AS_SQL_WANT"
else printf '%s\n' "🔴 묶음이 온전하지 않다. 올리지 마세요."; exit 1; fi

# ══ 🔴 39-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 39-deploy.sh 의 TARS 는 **비어 있는 채로** 올라갔다. 비어 있으면 그 파일이
#     ? 로 세고 「옮기다 깨진 것」만 잡는다 — 「개발 PC 에서 구운 그것이 맞나」는
#     못 본다. 아래 네 줄을 그 파일의 TARS 에 그대로 붙여 넣는다.
printf '\n%s\n' "════════ 39-deploy.sh 의 TARS 에 붙여 넣을 것 ════════"
printf '%s' "$TARTABLE"
printf 'as-migrations.tar.gz|%s|%s|-\n' "$msz" "$mm5"
printf '%s\n' "  🔴 앞 네 줄은 TARS 에, 마지막 줄(묶음)은 MIGTAR_SIZE · MIGTAR_MD5 에 넣는다."

printf '\n%s\n' "✅ 넷 다 구웠다. tar · 묶음 · 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'
printf '\n%s\n' "🔵 다음 — 올릴 곳이 **셋**이다 (대화에서 내가 한다):"
printf '%s\n' "    · 이미지 tar 넷  → NAS 의 /volume1/dss/images/"
printf '%s\n' "      (앱 셋 + 🔴 dss-auth-tools-3.tar — 도구를 빠뜨리면 비상구가 그대로다)"
printf '%s\n' "    · as-migrations.tar.gz → NAS 의 /volume1/dss/setup/incoming/"
printf '%s\n' "    · 39-deploy.sh 자신 → NAS 의 /volume1/dss/setup/  (md5 를 맞춘다)"
printf '%s\n' "────────────────────────────────────────────────────────────"
