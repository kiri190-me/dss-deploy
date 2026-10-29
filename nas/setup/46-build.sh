#!/bin/bash
# dss-deploy/nas/setup/46-build.sh — 마흔세째 배포 · 이미지 굽기 (2026-10-29)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · Git Bash) ────────────────────────────────────
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/46-build.sh" --check
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/46-build.sh" --go
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-43):
#     bash .../46-build.sh --go "/d/배포본/_images-43"
#
# ── 이번에 굽는 것 — **저장소 하나, 이미지 하나** ─────────────────────
#     ① A/S 앱   dss-as:3.8       → **dss-as:3.9**        커밋 1  스테이지 기본(runner)
#
#   🔴 **A/S 도구(dss-as-tools)는 이번에 안 굽는다.** 45번까지 다섯 판 내리
#      굽던 것을 이번에 안 굽는다 — 까닭과 실측은 바로 아래 절에 통째로 적었다.
#      🔵 그래서 45-build.sh 에 있던 'astools' 줄 · 'TOOLS_TAG' · 도구 tar ·
#         「이미지 안을 센다」 여섯 단계가 이 파일에는 **없다.** 지운 것이 아니라
#         **이번 판에 할 일이 아니어서 안 담은 것**이고, 다음에 도구를 다시
#         구울 판이 오면 45-build.sh 에서 그대로 베껴 오면 된다.
#   🔴 **나머지 아홉은 안 굽는다** — 통합 로그인 · PO · 재고 · 게시판 · 계측기 ·
#      개선요청 · RF 이슈관리 · 휴가 · 통합 승인함 아홉은 이번 범위에 커밋이
#      한 줄도 없다.
#
# ── 🔴 마이그레이션 — 이번에도 **0건이다** ────────────────────────────
#   RF_Service_System 의 drizzle/ 이 기준 SHA(4e918c7) 이후 **한 글자도 안
#   바뀌었다**(2026-10-29 'git diff --name-only 4e918c7..HEAD -- drizzle/' 로
#   확인, 0줄).
#   🔴 그래서 **as-migrations.tar.gz 를 만들지도 보내지도 않는다.** NAS 의
#      /volume1/dss/as-migrations 는 39번이 올려 둔 121 그대로다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 A/S 도구를 **왜 안 굽는가** — 여섯 판 만의 「안 굽는다」
# ══════════════════════════════════════════════════════════════════════
#   🔵 **처음은 아니다. 그러나 다섯 판을 내리 구운 뒤의 첫 '안 굽는다'다.**
#      이력부터 한 줄씩 적는다 — 이 판정이 넉 달 사이 여러 번 어긋났고,
#      어긋난 자리마다 잣대가 한 칸씩 넓어졌기 때문이다:
#        · **서른여섯째(39번)**: 「마이그레이션 0건이니 도구는 안 굽는다」로 쟀다
#          → **틀렸다**(도구에 비상구 둘이 못 쓰는 채로 들어 있었다).
#        · **서른일곱째(40번)**: 「그 도구가 **부르는 명령**이 바뀌었는가」로 쟀고
#          안 구웠다 → **맞았다**(db:migrate · db:preflight 둘 다 볼륨만 읽는다).
#          🔵 이 파일이 서 있는 자리가 바로 그 40번 자리다.
#        · **서른여덟째(41번)**: 그 잣대로는 「**늘어난** 명령」이 안 걸렸다.
#          안 올렸으면 'npm error Missing script' 가 날 자리였다 → 구웠다.
#        · **서른아홉째(42번)**: package.json 이 0줄인데 scripts/ 에 백필 도구가
#          새로 생겼다. 그래서 잣대를 「tools 스테이지가 **담는 것 전부**」로
#          넓혀 적었다 → 구웠다.
#        · **마흔째(43번)**: 도구가 **부르는 코드**(src/lib/kyosan/ 둘)가 바뀌어
#          구웠다 — 까닭이 분명했다.
#        · **마흔한째(44번)**: 도구가 **안 부르는** used-part-display.ts 가
#          바뀌었는데도 「잣대를 사람이 그때그때 뒤집지 않는다」로 구웠다.
#        · **마흔두째(45번)**: 도구의 import 닫힘 안에 바뀐 파일이 **넷** 있었다.
#          까닭이 「잣대대로」가 아니라 「**부르니까**」였다.
#
#   🔴 **마흔세째(이번)는 그 반대다 — 닫힘 안에 하나도 없다.**
#
#   🔵 **실측 — 2026-10-29. 재는 법과 결과를 둘 다 적어 둔다.**
#      45번이 쓴 방법을 글자 그대로 썼다:
#      scripts/backfill-kyosan-used-parts.ts 에서 시작해 상대경로 · '@/' ·
#      '@dss/core/*' 를 따라 import 를 끝까지 펼친다.
#        · 나온 파일 **161개**. 못 푼 상대경로 **0개**.
#        · 🔵 45번은 같은 자리에서 **99개**라고 적었다. 이 판이 그보다 많은 것은
#          이번에 쓴 펼치개가 'export … from' 과 타입 전용 import 까지 따라가고
#          vendor/dss-core 의 스키마 배럴을 통째로 펼쳤기 때문이다 — 즉 **더 넓게
#          잡은 수**다. 🔴 넓게 잡고도 아래 결과가 0 이라는 점이 중요하다.
#          (**펼치개를 맞대어 봤다**: 45번이 「닫힘 안에 있다」고 적은 넷을 이
#          161개에서 찾으면 **넷 다 나오고**, 45번이 「닫힘 밖이다」라고 바로잡은
#          used-part-display.ts 는 **안 나온다.** 같은 답이다.)
#        · 이번에 달라진 파일은 **아홉**이고, 161개와 맞대면 **겹치는 것이 0개**다.
#
#      달라진 아홉(전부 src/ 안이다):
#        src/app/(app)/product-models/[id]/page.tsx
#        src/components/product-models/ProductModelDetailScreen.tsx
#        src/components/product-models/product-model-fault-part-detail.test.tsx
#        src/components/product-models/product-model-fault-part-warning.test.tsx
#        src/components/product-models/product-model-history-period.test.tsx
#        src/lib/domain/product-model-breakdown.test.ts
#        src/lib/domain/product-model-breakdown.ts
#        src/lib/server/product-model-issued-parts.test.ts
#        src/lib/server/product-model-issued-parts.ts
#
#      🔵 **왜 하나도 안 겹치나** — 손으로도 따라가 봤다:
#        · 'product-model-issued-parts.ts' 를 import 하는 곳은 저장소에 **한
#          군데**뿐이다 — 제품 모델 상세 화면(src/app/(app)/product-models/[id]/page.tsx).
#        · 'product-model-breakdown.ts' 를 import 하는 곳은 그 화면 조각들과
#          'src/lib/db/queries/product-models.ts'(타입만) 인데, 그 queries 파일도
#          **도구 닫힘 161개에 없다.**
#        · 즉 이번 변경은 **제품 모델 상세 화면과 그 화면 전용 서버 조회**에서
#          끝난다. 백필은 그 길을 한 번도 밟지 않는다.
#
#   🔴 **그런데 39번에 넓혀 둔 잣대로 재면 「구워라」가 나온다. 그것도 적어 둔다.**
#      「tools 스테이지가 담는 것 중 달라진 파일」을 세면 이번 판은 **아홉**이다
#      (아홉이 전부 src/ 안이고, Dockerfile 의 tools 스테이지가 COPY src ./src 를
#      한다). 그 잣대만 보면 1 이상이라 구워야 한다.
#      🔵 그 잣대는 **「담기는 것이 바뀌었나」**를 재고, 이 파일은 **「부르는 것이
#         바뀌었나」**를 잰다. 45번이 둘을 **함께** 재면서 뒤엣것을 「굽는 까닭」으로
#         적어 두었다 — 이번 판은 그 뒤엣것이 0 이라 안 굽는다.
#      🔴 **치르는 값도 정직하게 적는다**: 안 구우면 도구 이미지 안의 src/ 는
#         커밋 하나만큼 낡은 채로 남는다. 44번 머리말 ㉡ 의 「도구와 앱의 src/ 가
#         같은 판이어야 한다」는 이번 판에서 **깨진다.**
#         🔵 그래도 **도는 코드는 한 글자도 다르지 않다** — 낡게 남는 파일 아홉은
#            도구가 import 하지 않는 파일이다(위 실측). 다음에 도구를 굽는 판에서
#            저절로 맞춰진다.
#      🔴 **그러니 이 판정은 「이번 커밋이 그 아홉뿐일 때만」 유효하다.** 아래 5절이
#         그것을 **ㄱ·ㄴ·ㄷ 세 가지로** 다시 잰다 — 목록이 달라졌거나, 도구 닫힘의
#         이름난 파일이 하나라도 바뀌었거나, package.json 이 한 줄이라도 바뀌면
#         **✗ 로 멈춘다.** 그때는 사람이 닫힘을 다시 재고 도구도 함께 구워야 한다.
#
# ── 🔴 45번에서 **덜어낸 것**과 그 자리의 까닭 ────────────────────────
#   ㄱ) SITES 표의 'astools' 줄 · 'TOOLS_TAG' · HOWMANY 2 → 1
#       → 굽지 않으니 표에 줄이 없다. 저장소를 두 번 세던 'astools' 건너뛰기도
#         함께 없앴다(줄이 하나라 두 번 셀 일이 없다).
#   ㄴ) 굽기 고리 끝의 「도구 이미지 안을 센다」 여섯 단계
#       → 이번에 굽는 이미지가 아니다. 🔵 **대신 NAS 쪽에서는 그 이미지가 아직
#         있는지만 본다**(46-deploy.sh 1절) — 연락서 폴더 검사가 그 이미지를
#         실제로 띄워 쓰기 때문이다.
#   ㄷ) Dockerfile 의 tools 스테이지 검사 다섯(COPY scripts/package.json/src/
#       vendor · .dockerignore)
#       → 전부 **도구를 굽는 날**에만 값이 있는 줄이다. 굽지 않는 판에서 재면
#         「재는 줄이 하나 늘었을 뿐」이고, 늘어난 줄은 다음 판에서 까닭 없이
#         복사된다(45번이 fault-part-inventory.ts 를 안 넣은 것과 같은 까닭).
#   ㄹ) 백필 도구 파일 셋 · src/ 파일 다섯이 **저장소에** 있는지 보던 줄
#       → 그것들은 「도구 이미지에 담길 것이 있나」를 보던 줄이다. 담을 일이 없다.
#       🔵 **대신 5절이 그 파일들이 '안 바뀌었나'를 센다** — 쓰임이 반대로 뒤집혔다.
#   🔵 **덜어내지 않은 것**(45번 그대로): 저장소 미커밋·미푸시·**안 받은 것** ·
#      기준 SHA 조상 확인 · drizzle 수 맞대기 · 서브모듈 둘 · drizzle 121 ·
#      기준 SHA 두 벌 맞대기 · 태그 있나 · tar 자리 · tar 지문을 **빌드 로그**와
#      맞대기 · ✓/✗/? 셈.
#
# ── 🔴 모드 둘 ────────────────────────────────────────────────────────
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다.
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면
#            굽지 않고 멈춘다. 전부 ✓ 일 때만 하나를 굽고 tar 로 뽑는다.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 이 환경의 함정 (36~45-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싸고, 저장소 자리를
#      이 파일의 자리에서 계산한다(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:\… 를 /c/… 로
#      바꾸고, docker save 는 작업 폴더로 들어가 **상대경로**로 쓴다.
#   ③ 🔴 **tar 의 Config 를 docker image inspect .Id 와 맞대지 마라.** 맞댈
#      상대는 **빌드 로그의 exporting config sha256:** 이다.
#   ④ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를
#      막는다). 다만 메모리는 다르다 — 열이 떠 있으면 빌드가 죽을 수 있다.
#   ⑤ 🔴 **파일 이름에 대괄호와 괄호가 들어 있다**(product-models/[id]/page.tsx).
#      아래 5절은 그 목록을 **따옴표로 감싼 여러 줄 변수**로만 다룬다 — 따옴표
#      없이 펼치면 셸이 '[id]' 를 글자 묶음 패턴으로 읽는다.
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

# tar 안 manifest.json 의 Config 지문 (39~45-build.sh 의 것을 글자 그대로)
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
#      어긋나면 표가 낡았다는 뜻이라 사람이 봐야 한다. 이번엔 **하나**다:
#        081439b 반출 조회의 건수 상한을 없애고 시간 예산으로 바꾼다
#   🔵 45번에 있던 'astools' 줄이 이 표에 **없다** — 머리말의 「안 굽는 까닭」.
#      줄이 하나뿐이라 45번이 두 번 세지 않으려고 두었던 건너뛰기도 없앴다.
#   🔴 다섯째 칸은 '-' 다(기본 runner). 🔵 '--target' 가지는 아래 굽기 고리에
#      **그대로 남겨 둔다** — 표가 모는 자리라 다음 판에서 줄만 더하면 선다.
SITES='
as|RF_Service_System|dss-as:3.9|4e918c7|-|0|1
'
HOWMANY=1

# ── 🔴 기대값과 그 출처 ───────────────────────────────────────────────
#   [저장소] 2026-10-29 개발 PC 의 저장소에서 센 값
AS_SQL_WANT=121       # [저장소] RF_Service_System/drizzle/*.sql — 안 늘어야 한다(0120 까지 그대로)
CORE_PIN=05018b077a780922b484a7a539665f35d5207c82   # vendor/dss-core 포인터 — 안 움직였다
# 🔴 5절이 쓰는 기준 SHA. **SITES 표의 넷째 칸과 같은 값이어야 한다** — 41번에서는
#    이 값이 표와 따로 적혀 있어 한쪽만 고치면 조용히 어긋날 자리였다. 5절 첫 줄이
#    둘을 맞대어 본다.
AS_BASE=4e918c7
# 🔵 tools 스테이지가 담는 것 중 달라진 파일 수 — 적어 둔 값(2026-10-29 실측 9).
#    🔴 45번에서는 이 수가 「굽는 까닭」이었지만, 이번 판에서는 **까닭이 아니다**
#       (머리말: 담기는 것이 바뀌어도 부르지 않으면 안 굽는다). 그래서 ⚠️ 로만
#       센다 — ✗ 는 아래 ㄱ·ㄴ·ㄷ 이 맡는다.
TOOLS_CHANGED_WANT=9

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-43"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

printf '%s\n' "마흔세째 배포 · 이미지 굽기   $(date '+%Y-%m-%d %H:%M:%S')"
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

# ── 2. 저장소 하나 (이미지 하나) ──────────────────────────────────────
printf '\n== 2. 저장소 하나 (이미지 하나)\n'
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
      printf '%s\n' "      🔴 커밋이 늘었으면 **도구를 안 굽기로 한 판정이 흔들린다** — 5절을 꼭 보세요."
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

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 A/S 도구를 **안 굽는 까닭이 아직 참인가** ───────────────────
# ══════════════════════════════════════════════════════════════════════
#  🔴 45번의 5절은 「도구를 **구울** 까닭이 있나」를 쟀다. 이 절은 그것을 **뒤집은
#     것**이다 — 「도구를 **안 구울** 까닭이 아직 참인가」.
#  🔵 머리말의 실측(닫힘 161개와 바뀐 아홉이 0개 겹침)은 **사람이 2026-10-29 에
#     한 번 잰 값**이다. 셸은 import 를 펼칠 수 없으므로, 이 절은 그 실측의
#     **입력이 그대로인지**를 센다. 입력이 달라지면 실측을 다시 해야 한다.
#  🔴 세 가지를 잰다. **하나라도 어긋나면 ✗ 다**:
#     ㄱ) 기준 이후 달라진 파일 목록이 **적어 둔 아홉과 글자 그대로** 같은가
#     ㄴ) 도구 닫힘 안의 **이름난 파일 열**이 하나도 안 바뀌었는가
#     ㄷ) package.json 이 **0줄** 바뀌었는가 (38번의 교훈 — 늘어난 npm 명령)
printf '\n== 5. A/S 도구를 안 굽는 까닭이 아직 참인가\n'
# 🔴 기준 SHA 가 표와 이 절에 **두 벌로** 적혀 있다. 한쪽만 고치면 조용히 어긋나므로
#    먼저 맞대어 본다.
AS_ROW_BASE=$(printf '%s\n' "$SITES" | tr -d ' ' | grep '^as|' | head -1 | cut -d'|' -f4)
if [ "${AS_ROW_BASE:-}" = "$AS_BASE" ]; then
  ok "기준 SHA 가 SITES 표와 이 절에서 같다 ($AS_BASE)"
else
  bad "기준 SHA 가 어긋난다 — SITES 표는 ${AS_ROW_BASE:-못 읽음} · 이 절은 $AS_BASE. 둘을 맞추세요"
fi

# 🔵 먼저 45번이 쓰던 수를 그대로 찍어 둔다 — 「담기는 것이 바뀌었나」.
#    🔴 **이 수는 이번 판에서 판정 기준이 아니다**(머리말). 9 가 나와도 안 굽는다.
TOOLS_PATHS="scripts/ src/ package.json drizzle.config.ts tsconfig.json vendor/"
TOOLS_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | wc -l | tr -d ' ')
say "tools 스테이지가 담는 것 중 달라진 파일 ${TOOLS_CHANGED:-못 쟀다}개 (적어 둔 수는 $TOOLS_CHANGED_WANT)"
say "🔵 39번 잣대로는 1 이상이면 '구워라'다. 🔴 이번 판은 그 잣대를 쓰지 않는다 —"
say "   **담기는 것이 아니라 부르는 것**으로 가른다(이 파일 머리말)."
if [ "${TOOLS_CHANGED:-x}" != "$TOOLS_CHANGED_WANT" ]; then
  note "달라진 파일이 ${TOOLS_CHANGED:-?}개다 — 적어 둔 것은 ${TOOLS_CHANGED_WANT}개다. 아래 ㄱ 이 ✗ 로 받는다"
fi

# ── ㄱ) 🔴 **달라진 파일 목록이 적어 둔 아홉과 글자 그대로 같은가** ────
#   🔴 이것이 이 절에서 제일 센 줄이다. 커밋이 하나라도 더 쌓이면 목록이 달라지고,
#      그러면 **머리말의 닫힘 실측이 더 이상 그 커밋을 안 덮는다.**
#   🔴 **따옴표로 감싼 여러 줄 변수**로 둔다 — '[id]' 가 들어 있어 따옴표 없이
#      펼치면 셸이 글자 묶음 패턴으로 읽는다(머리말 함정 ⑤).
TOOLS_UNCALLED='
src/app/(app)/product-models/[id]/page.tsx
src/components/product-models/ProductModelDetailScreen.tsx
src/components/product-models/product-model-fault-part-detail.test.tsx
src/components/product-models/product-model-fault-part-warning.test.tsx
src/components/product-models/product-model-history-period.test.tsx
src/lib/domain/product-model-breakdown.test.ts
src/lib/domain/product-model-breakdown.ts
src/lib/server/product-model-issued-parts.test.ts
src/lib/server/product-model-issued-parts.ts
'
WANT_LIST=$(printf '%s\n' "$TOOLS_UNCALLED" | grep -v '^[[:space:]]*$' | sort)
GOT_LIST=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | sort)
if [ -z "${GOT_LIST:-}" ]; then
  unk "달라진 파일 목록" "git diff 가 아무것도 안 돌려줬다 — 기준 SHA 를 보세요"
elif [ "$GOT_LIST" = "$WANT_LIST" ]; then
  ok "달라진 파일이 **적어 둔 아홉 그대로**다 — 2026-10-29 의 닫힘 실측이 이 커밋을 덮는다"
else
  bad "🔴 달라진 파일이 적어 둔 아홉과 **다르다** — **도구 닫힘을 다시 재야 한다.** 멈추고 알릴 것"
  say "🔵 다시 재는 법은 이 파일 머리말에 그대로 있다(백필에서 import 를 끝까지 펼쳐"
  say "   달라진 파일과 맞댄다). 겹치는 것이 하나라도 있으면 **도구도 함께 굽는다** —"
  say "   그때는 45-build.sh 의 'astools' 줄과 「이미지 안을 센다」를 베껴 오면 된다."
  say "── 적어 둔 것에 없는데 바뀐 것"
  printf '%s\n' "$GOT_LIST" | grep -vxF -f <(printf '%s\n' "$WANT_LIST") | head -12 | sed 's/^/      /'
  say "── 적어 두었는데 안 바뀐 것"
  printf '%s\n' "$WANT_LIST" | grep -vxF -f <(printf '%s\n' "$GOT_LIST") | head -12 | sed 's/^/      /'
fi

# ── ㄴ) 🔴 **도구 닫힘 안의 이름난 파일 열이 하나도 안 바뀌었는가** ────
#   🔵 ㄱ 이 이미 모든 변경을 잡지만, 이 줄은 **진단 이름을 달아 준다** — ✗ 가 났을
#      때 「도구가 부르는 바로 그 파일이 바뀌었다」를 그 자리에서 읽을 수 있다.
#   🔵 아래 열은 2026-10-29 실측에서 **닫힘 161개 안에 있다고 확인한 파일**이다.
#      앞의 넷은 도구 자신의 몸이고(백필 셋 + DB 연결), 뒤의 여섯은 45번이
#      「도구가 부른다」고 적은 넷과 43번이 적은 kyosan 둘이다.
#   🔴 **used-part-display.ts 는 여기 없다.** 45번이 바로잡은 그대로 — 그 파일은
#      닫힘 **밖**이다(이번 펼치개로도 안 나왔다). 닫힘 밖의 파일을 이 목록에 넣으면
#      안 구워도 되는 판에서 ✗ 가 난다.
TOOLS_CALLED="scripts/backfill-kyosan-used-parts.ts scripts/lib/kyosan-used-parts-backfill.ts scripts/lib/kyosan-used-parts-backfill-plan.ts src/lib/db/connection.ts src/lib/auth/repair-case-used-parts-authorization.ts src/lib/db/queries/repair-case-used-parts.ts src/lib/domain/inventory-gateway.ts src/lib/server/inventory-gateway.ts src/lib/kyosan/parts-detail-sheet.ts src/lib/kyosan/report-preview.ts"
CALLED_HIT=0
CALLED_SEEN=0
for f in $TOOLS_CALLED; do
  CALLED_SEEN=$((CALLED_SEEN+1))
  # 🔵 먼저 **그 파일이 아직 저장소에 있는지** 본다 — 이름이 바뀌었는데 0 이 나와
  #    「안 바뀌었다」로 통과하는 길을 막는다(표본이 비어서 공짜로 통과하는 꼴).
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 저장소에 없다 — **도구 닫힘 목록이 낡았다.** 닫힘을 다시 재세요"
    continue
  fi
  if git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- "$f" 2>/dev/null | grep -q .; then
    CALLED_HIT=$((CALLED_HIT+1)); say "🔴 바뀌었다 · 도구가 부른다 — $f"
  fi
done
say "도구 닫힘의 이름난 파일 ${CALLED_SEEN}개를 봤고, 그중 바뀐 것 ${CALLED_HIT}개 (기대 0)"
if [ "$CALLED_SEEN" = "10" ]; then
  ok "닫힘 목록 열을 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
else
  bad "닫힘 목록을 ${CALLED_SEEN}개만 봤다 — 열을 기대했다. 목록이 깨졌다"
fi
if [ "$CALLED_HIT" = "0" ]; then
  ok "도구가 부르는 파일이 **하나도 안 바뀌었다** — 안 굽는 까닭이 그대로 참이다"
else
  bad "🔴 도구가 부르는 파일이 ${CALLED_HIT}개 바뀌었다 — **도구를 함께 구워야 한다.** 멈추고 알릴 것"
fi

# ── ㄷ) 🔴 **package.json 이 0줄 바뀌었는가** ─────────────────────────
#   🔴 45번에서는 이 줄이 ⚠️ 였다(어차피 굽고 있었다). 이번 판에서는 **✗ 다** —
#      38번의 교훈이 바로 이 자리다: npm 명령이 **늘어난 것**은 잣대에 안 걸려서
#      안 올렸고, 그래서 'npm error Missing script' 가 날 자리였다. 도구를 안 굽는
#      판에서 package.json 이 바뀌면 그 사고가 그대로 돌아온다.
PKG_LINES=$(git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | wc -l | tr -d ' ')
say "package.json 의 diff ${PKG_LINES:-못 쟀다}줄 (기대 0)"
if [ "${PKG_LINES:-x}" = "0" ]; then
  ok "package.json 이 한 줄도 안 바뀌었다 — 도구가 부를 npm 명령이 늘지도 줄지도 않았다"
else
  bad "🔴 package.json 이 ${PKG_LINES}줄 바뀌었다 — **도구를 안 굽기로 한 전제가 깨졌다**(38번의 사고). 멈추고 알릴 것"
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

# ── 7. tar 자리 ───────────────────────────────────────────────────────
printf '\n== 7. tar 자리\n'
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

  # 🔵 이번 판의 표에는 '--target' 를 쓰는 줄이 없다(도구를 안 굽는다). 그래도
  #    가지를 남겨 둔다 — 표가 모는 자리라, 다음 판에서 줄만 더하면 그대로 선다.
  #    🔴 도구를 다시 굽는 날 '--target tools' 를 빠뜨리면 runner 가 구워지고 그
  #       안에는 scripts/ 도 package.json 도 없어 조용히 쓸모없는 이미지가 된다
  #       (RF_Service_System/Dockerfile 은 tools 스테이지를 runner **앞에** 둔다).
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
  # 🔵 45번은 여기서 'astools' 일 때 **이미지 안을 여섯 단계로** 셌다. 이번 판에는
  #    그 줄이 없다 — 도구를 굽지 않으니 셀 이미지가 없다. 🔴 앱 이미지 안을 대신
  #    세지도 않는다: 45번도 앱은 안 셌고, 앱이 제대로 구워졌는지는 NAS 에서
  #    **실제로 떠서 응답하는지**로 재는 것이 더 센 신호다(46-deploy.sh 7절).
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  구운 것 %s / %s · 실패 %s\n' "$BUILT" "$HOWMANY" "$BFAIL"
if [ "$BFAIL" != "0" ]; then printf '%s\n' "🔴 실패가 있다. 위를 보세요."; exit 1; fi

# ══ 🔴 46-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 46-deploy.sh 의 TARS 는 **이름만 적힌 채로** 올라간다. 지문 칸이 비어 있으면
#     그 파일이 ? 로 세고 「옮기다 깨진 것」만 잡는다 — 아래 한 줄로 그 한 줄을
#     **통째로 갈아 끼운다.** 🔵 마이그레이션 묶음은 이번에도 없다.
printf '\n%s\n' "════════ 46-deploy.sh 의 TARS 에 붙여 넣을 것 ════════"
printf '%s' "$TARTABLE"
printf '%s\n' "  🔴 위 한 줄로 TARS 의 한 줄을 통째로 갈아 끼운다. 🔵 as-migrations.tar.gz 는 이번에도 없다."

printf '\n%s\n' "✅ 하나 구웠다. tar · 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'
printf '\n%s\n' "🔵 다음 — 올릴 곳이 **둘**이다 (대화에서 내가 한다):"
printf '%s\n' "    · 이미지 tar 하나 → NAS 의 /volume1/dss/images/"
printf '%s\n' "      (dss-as-3.9.tar — 🔴 **도구 tar 는 이번에 없다.** 머리말의 '안 굽는 까닭')"
printf '%s\n' "    · 46-deploy.sh 자신 → NAS 의 /volume1/dss/setup/  (md5 를 맞춘다)"
printf '%s\n' "🔵 **마이그레이션 묶음은 없다** — 이번 판도 drizzle/ 이 0건이다."
printf '%s\n' "────────────────────────────────────────────────────────────"
