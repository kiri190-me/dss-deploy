#!/bin/bash
# dss-deploy/nas/setup/47-build.sh — 마흔네째 배포 · 이미지 굽기 (2026-10-29)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · Git Bash) ────────────────────────────────────
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/47-build.sh" --check
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/47-build.sh" --go
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-44):
#     bash .../47-build.sh --go "/d/배포본/_images-44"
#
# ── 이번에 굽는 것 — **저장소 하나, 이미지 둘** ───────────────────────
#     ① A/S 앱   dss-as:3.9       → **dss-as:4.0**        커밋 1  스테이지 기본(runner)
#     ② A/S 도구 dss-as-tools:6   → **dss-as-tools:7**    커밋 1  🔴 --target tools
#
#   🔵 저장소는 RF_Service_System 하나인데 이미지는 둘이다 — 43·44·45-build.sh 가
#      한 것과 같은 모양이다(같은 저장소를 두 번, 한 번은 기본·한 번은
#      --target tools). 🔵 **46-build.sh 만 한 줄짜리였다** — 그 판은 도구를 안
#      구웠다. 이 파일은 그 줄을 45-build.sh 에서 도로 가져왔다.
#   🔴 **나머지 아홉은 안 굽는다** — 통합 로그인 · PO · 재고 · 게시판 · 계측기 ·
#      개선요청 · RF 이슈관리 · 휴가 · 통합 승인함 아홉은 이번 범위에 커밋이
#      한 줄도 없다.
#   🔵 **앱 태그가 3.9 에서 4.0 으로 넘어간다.** 자릿수가 바뀌는 자리라 tar 이름
#      (dss-as-4.0.tar) · SITES 표 · 47-deploy.sh 의 tar2tag() 를 한 벌로 봐야 한다.
#
# ── 🔴 마이그레이션 — 이번에도 **0건이다** ────────────────────────────
#   RF_Service_System 의 drizzle/ 이 기준 SHA(081439b) 이후 **한 글자도 안
#   바뀌었다**(2026-10-29 'git diff --name-only 081439b..HEAD -- drizzle/' 로
#   확인, 0줄).
#   🔴 그래서 **as-migrations.tar.gz 를 만들지도 보내지도 않는다.** NAS 의
#      /volume1/dss/as-migrations 는 39번이 올려 둔 121 그대로다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 A/S 도구를 **왜 굽는가** — 한 판 만에 다시 「굽는다」로 돌아왔다
# ══════════════════════════════════════════════════════════════════════
#   🔵 이 판정이 넉 달 사이 여러 번 어긋났고, 어긋난 자리마다 잣대가 한 칸씩
#      넓어졌다. 이력부터 한 줄씩 적는다:
#        · **서른여섯째(39번)**: 「마이그레이션 0건이니 도구는 안 굽는다」로 쟀다
#          → **틀렸다**(도구에 비상구 둘이 못 쓰는 채로 들어 있었다).
#        · **서른일곱째(40번)**: 「그 도구가 **부르는 명령**이 바뀌었는가」로 쟀고
#          안 구웠다 → **맞았다**(db:migrate · db:preflight 둘 다 볼륨만 읽는다).
#        · **서른여덟째(41번)**: 그 잣대로는 「**늘어난** 명령」이 안 걸렸다.
#          안 올렸으면 'npm error Missing script' 가 날 자리였다 → 구웠다.
#        · **서른아홉째(42번)**: package.json 이 0줄인데 scripts/ 에 백필 도구가
#          새로 생겼다. 잣대를 「tools 스테이지가 **담는 것 전부**」로 넓혔다 → 구웠다.
#        · **마흔째(43번)**: 도구가 **부르는 코드**(src/lib/kyosan/ 둘)가 바뀌어 구웠다.
#        · **마흔한째(44번)**: 도구가 **안 부르는** used-part-display.ts 가 바뀌었는데도
#          「잣대를 사람이 그때그때 뒤집지 않는다」로 구웠다.
#        · **마흔두째(45번)**: 도구의 import 닫힘 안에 바뀐 파일이 **넷** 있었다 —
#          까닭이 「**부르니까**」였다.
#        · **마흔세째(46번)**: 닫힘 안에 **하나도 없었다**(닫힘 161개 · 바뀐 아홉 ·
#          겹침 0). 다섯 판을 내리 구운 뒤 처음으로 **안 구웠다.**
#
#   🔴 **마흔네째(이번)는 닫힘 안에 하나 있다. 그래서 다시 굽는다.**
#
#   🔵 **실측 — 2026-10-29. 46번이 쓴 방법을 글자 그대로 다시 썼다.**
#      scripts/backfill-kyosan-used-parts.ts 에서 시작해 상대경로 · '@/' ·
#      '@dss/core/schema' · '@dss/core/ui/*' · '@dss/ui' 를 따라 import 를 끝까지
#      펼친다('export … from' 과 타입 전용 import 까지 따라간다).
#        · 나온 파일 **161개**. 못 푼 상대경로 **0개**. 🔵 46번이 적은 수와 같다.
#        · **펼치개를 맞대어 봤다**: 46번이 「닫힘 안」이라 이름 붙인 열 개가 이
#          161개에서 **열 다 나오고**, 45번이 「닫힘 밖」이라 바로잡은
#          used-part-display.ts 는 **안 나온다.** 46번과 같은 답이다.
#        · 이번에 달라진 파일은 **열다섯**이고, 161개와 맞대면 **하나가 겹친다**:
#            src/lib/domain/inventory-gateway.ts
#
#   🔴 **그 하나의 diff 는 주석뿐이다.** 그것도 직접 읽고 적는다 —
#      'git diff 081439b..HEAD -- src/lib/domain/inventory-gateway.ts' 를 돌리면
#      resolveInventoryIssuedPartsTrace 안의 **주석 두 줄이 다섯 줄로** 바뀌었을
#      뿐이고, 바로 아래 실행문(line.issued 가 1 이상이면 줄 수를 하나 더한다)은
#      **문맥 줄로 그대로 있다.** 즉 **도는 코드는 한 글자도 안 바뀌었다.**
#
#   🔴 **그런데도 굽는다. 까닭을 다섯으로 적는다 — 다음 사람이 다시 판단할 수 있게.**
#     ㄱ) 46번이 세운 잣대는 「**부르는 파일**이 바뀌었나」이고, 그 잣대의 단위는
#        **파일**이다. 이번에 재면 **1 > 0** 이라 「굽는다」가 나온다.
#     ㄴ) 39번에 넓혀 둔 잣대(「tools 스테이지가 **담는 것**이 바뀌었나」)로 재면
#        **15 > 0** 이라 역시 「굽는다」다.
#     ㄷ) 🔵 **이번엔 두 잣대가 안 어긋난다.** 46번은 둘이 어긋났고(담는 것 9 ·
#        부르는 것 0) 좁은 쪽이 이겼다. 이번은 둘 다 같은 답이라 다툴 것이 없다.
#     ㄹ) 🔴 「**주석만이니 안 굽는다**」는 **셋째 잣대**이고 아무도 쓴 적이 없다.
#        그 잣대는 **사람이 매번 diff 를 끝까지 읽어야** 성립한다. 한 번 규칙으로
#        세워 두면 다음 판에 **주석 아닌 것이 섞여도 같은 길로 간다** — 「그 파일
#        주석만 바뀐 거죠」 한마디로 넘어가고, 그때는 **오류가 한 줄도 안 난다.**
#        39번이 틀렸던 모양이 정확히 그것이었다(비상구 둘이 못 쓰는 채로 들어 있었다).
#        🔵 치르는 값은 **tar 하나를 더 굽고 올리는 것**뿐이다. 값이 싸고 되돌릴
#           필요도 없는 쪽을 고른다.
#     ㅁ) 🔴 **46번이 알고 진 빚을 함께 갚는다.** 46번은 「안 굽는다」를 고르면서
#        「도구 이미지 안의 src/ 가 커밋 하나만큼 낡은 채로 남는다 · 44번 머리말 ㉡
#        (도구와 앱의 src/ 가 같은 판이어야 한다)이 이 판에서 깨진다」고 적어 두었다.
#        지금 NAS 의 dss-as-tools:6 은 **4e918c7 판의 src/** 를 메고 있어 **두 판
#        (커밋 2개 · 파일 19개)** 낡았다(2026-10-29 실측). 이번에 구우면 그 ㉡ 가
#        **다시 참이 된다.**
#
#   🔵 **다음 사람이 같은 판단을 다시 하는 법** — 명령 세 줄이다:
#        ① git -C RF_Service_System diff --name-only <기준SHA>..HEAD
#        ② scripts/backfill-kyosan-used-parts.ts 에서 import 를 끝까지 펼쳐 닫힘을
#           만든다(위에 적은 규칙대로. 161개가 나오고 못 푼 상대경로가 0이면 맞다).
#        ③ ①과 ②를 맞댄다. **겹치는 것이 하나라도 있으면 굽는다.** 0 이면 46번처럼
#           안 구워도 된다 — 그때는 46-build.sh 를 베껴 오면 된다.
#      🔴 ③ 에서 「겹치긴 하는데 주석만이다」가 나와도 **굽는 쪽을 고른다**(위 ㄹ).
#      🔴 ②를 건너뛰고 ①만 보고 「src/ 가 바뀌었으니 굽는다」로 가도 **이번 판은
#         같은 답**이지만, 46번 같은 판에서는 틀린 답이 된다. 둘 다 재라.
#
# ── 🔴 46번에서 **도로 가져온 것**(출처는 45-build.sh) ────────────────
#   ㄱ) SITES 표의 'astools' 줄 · 'TOOLS_TAG' · HOWMANY 1 → 2
#       🔵 저장소를 두 번 세지 않도록 'astools' 건너뛰기도 함께 가져왔다.
#   ㄴ) Dockerfile 의 tools 스테이지 검사 다섯 + .dockerignore
#   ㄷ) 백필 도구 파일 셋 · src/ 파일이 **저장소에** 있는지 보는 줄
#       🔴 45번은 다섯을 셌다. 이 파일은 **여섯**이다 — 이번에 닫힘 안에서 바뀐
#          src/lib/domain/inventory-gateway.ts 를 더했다.
#   ㄹ) 굽기 고리 끝의 「도구 이미지 안을 센다」 여섯 단계
#
# ── 🔴 46번에서 **남겨 둔 것**(안전장치는 하나도 안 뺐다) ─────────────
#   5절의 ㄱ·ㄴ·ㄷ 세 검사를 **그대로 둔다.** 다만 **엄함이 바뀐다** — 46번에서
#   그 셋은 「**안 구울** 까닭이 아직 참인가」였고 ✗ 였다. 이 파일에서는 굽기로
#   했으므로 셋 중 둘이 ⚠️ 로 내려간다. 어느 줄이 왜 내려갔는지는 그 줄 옆에
#   한 줄씩 적어 두었다. 🔴 **내려간 줄도 재기는 그대로 잰다** — 지운 것이 아니다.
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
# ── 🔴 이 환경의 함정 (36~46-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싸고, 저장소 자리를
#      이 파일의 자리에서 계산한다(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:\… 를 /c/… 로
#      바꾸고, docker save 는 작업 폴더로 들어가 **상대경로**로 쓴다.
#   ③ 🔴 **tar 의 Config 를 docker image inspect .Id 와 맞대지 마라.** 맞댈
#      상대는 **빌드 로그의 exporting config sha256:** 이다.
#   ④ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를
#      막는다). 다만 메모리는 다르다 — 열이 떠 있으면 빌드가 죽을 수 있다.
#   ⑤ 🔵 **이번 판의 파일 목록에는 대괄호가 없다**(46번에는 '[id]' 가 있었다).
#      그래도 아래 5절은 목록을 **따옴표로 감싼 여러 줄 변수**로만 다룬다 — 다음
#      판에 대괄호가 다시 들어와도 그대로 선다.
#   ⑥ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다.** 한글을 argv 로 넘기면
#      깨지는 길이 열린다 — 그래서 아래 '새 판인가' 검사의 이름 셋은 전부 ASCII 다.
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

# tar 안 manifest.json 의 Config 지문 (39~46-build.sh 의 것을 글자 그대로)
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
#        3bde67e 고장 부품을 줄 수가 아니라 실제 수량으로 센다
#   🔴 'astools' 는 **같은 저장소**(RF_Service_System)를 --target tools 로 한 번
#      더 굽는 줄이다. 저장소를 세는 자리에서는 이 줄을 건너뛴다(41~45번과 같은
#      처리) — 두 번 세면 ✗ 도 두 번 센다.
#   🔵 앱 태그가 **3.9 에서 4.0 으로** 넘어간다. tar 이름은 tar_name() 이 태그에서
#      바로 만들므로(콜론을 빼기표로) dss-as-4.0.tar 가 되고, 47-deploy.sh 의
#      tar2tag() 도 그 이름을 써야 한다.
SITES='
as|RF_Service_System|dss-as:4.0|081439b|-|0|1
astools|RF_Service_System|dss-as-tools:7|081439b|tools|0|1
'
HOWMANY=2
TOOLS_TAG=dss-as-tools:7

# ── 🔴 기대값과 그 출처 ───────────────────────────────────────────────
#   [저장소] 2026-10-29 개발 PC 의 저장소에서 센 값
AS_SQL_WANT=121       # [저장소] RF_Service_System/drizzle/*.sql — 안 늘어야 한다(0120 까지 그대로)
CORE_PIN=05018b077a780922b484a7a539665f35d5207c82   # vendor/dss-core 포인터 — 안 움직였다
# 🔴 5절이 쓰는 기준 SHA. **SITES 표의 넷째 칸과 같은 값이어야 한다** — 41번에서는
#    이 값이 표와 따로 적혀 있어 한쪽만 고치면 조용히 어긋날 자리였다. 5절 첫 줄이
#    둘을 맞대어 본다.
AS_BASE=081439b
# 🔵 tools 스테이지가 담는 것 중 달라진 파일 수 — 적어 둔 값(2026-10-29 실측 15).
#    🔵 이번 판에서는 이 수가 **굽는 까닭 가운데 하나**다(머리말 ㄴ). ⚠️ 로만 센다 —
#       ✗ 는 「1개 이상인가」쪽이 맡는다.
TOOLS_CHANGED_WANT=15
# 🔵 도구 닫힘 안에서 바뀐 파일 수 — 적어 둔 값(2026-10-29 실측 1).
#    🔴 **이것이 이번 판의 가장 센 까닭이다**(머리말 ㄱ).
TOOLS_CALLED_WANT=1

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-44"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

printf '%s\n' "마흔네째 배포 · 이미지 굽기   $(date '+%Y-%m-%d %H:%M:%S')"
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
      printf '%s\n' "      🔵 커밋이 늘어도 **굽는 판정은 안 흔들린다**(이미 굽는다). 흔들리는 것은"
      printf '%s\n' "         47-deploy.sh 꼬리말의 「볼 곳」과 5절의 파일 목록이다 — 사람이 보세요."
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

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 A/S 도구를 **구울 까닭이 있나** · 소스가 새 코드를 담고 있나 ─
# ══════════════════════════════════════════════════════════════════════
#  🔴 46번의 5절은 「도구를 **안 구울** 까닭이 아직 참인가」였다. 이 절은 그것을
#     **45번 쪽으로 되돌린 것**이다 — 「도구를 **구울** 까닭이 있나」.
#  🔵 46번이 넣어 둔 세 검사(ㄱ 목록 맞대기 · ㄴ 닫힘 안 이름난 파일 · ㄷ
#     package.json)는 **하나도 안 뺐다.** 엄함만 판정에 맞게 바뀐다.
#  🔴 .dockerignore 나 Dockerfile 이 어긋나면 이미지는 멀쩡히 구워지고 **바뀐
#     코드만 조용히 빠진다.** 그래서 담는 길부터 센다.
printf '\n== 5. A/S 도구를 구울 까닭이 있나 · 소스가 새 코드를 담고 있나\n'
# 🔴 기준 SHA 가 표와 이 절에 **두 벌로** 적혀 있다. 한쪽만 고치면 조용히 어긋나므로
#    먼저 맞대어 본다.
AS_ROW_BASE=$(printf '%s\n' "$SITES" | tr -d ' ' | grep '^as|' | head -1 | cut -d'|' -f4)
if [ "${AS_ROW_BASE:-}" = "$AS_BASE" ]; then
  ok "기준 SHA 가 SITES 표와 이 절에서 같다 ($AS_BASE)"
else
  bad "기준 SHA 가 어긋난다 — SITES 표는 ${AS_ROW_BASE:-못 읽음} · 이 절은 $AS_BASE. 둘을 맞추세요"
fi
# 🔵 표의 'astools' 줄이 정말 --target tools 인지도 본다. 여기가 '-' 면 runner 가
#    구워지고, 그 이미지는 **오류 없이** 쓸모가 없다.
AS_TOOLS_ROW_TGT=$(printf '%s\n' "$SITES" | tr -d ' ' | grep '^astools|' | head -1 | cut -d'|' -f5)
AS_TOOLS_ROW_TAG=$(printf '%s\n' "$SITES" | tr -d ' ' | grep '^astools|' | head -1 | cut -d'|' -f3)
if [ "${AS_TOOLS_ROW_TGT:-}" = "tools" ] && [ "${AS_TOOLS_ROW_TAG:-}" = "$TOOLS_TAG" ]; then
  ok "SITES 표의 astools 줄이 $TOOLS_TAG · --target tools 다"
else
  bad "SITES 표의 astools 줄이 어긋난다 — 태그 ${AS_TOOLS_ROW_TAG:-없음} · target ${AS_TOOLS_ROW_TGT:-없음} (기대 $TOOLS_TAG · tools)"
fi
if grep -q '^FROM .* AS tools' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "Dockerfile 에 tools 스테이지가 있다 (--target tools 가 선다)"
else
  bad "Dockerfile 에 tools 스테이지가 없다 — --target tools 가 실패한다"
fi
if grep -qE '^COPY .*scripts \./scripts' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 scripts/ 를 담는다 (백필 도구의 파일이 들어간다)"
else
  bad "Dockerfile 이 scripts/ 를 안 담는다 — 백필 도구가 통째로 빠진다"
fi
if grep -qE '^COPY .*package\.json' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 package.json·tsconfig.json 을 담는다 (tsx 가 paths 를 읽는 길)"
else
  bad "Dockerfile 이 package.json 을 안 담는다"
fi
# 🔴 **이번 판에서 가장 중요한 줄이 이것이다.** 바뀐 열다섯이 **전부 src/ 안**이다.
#    src/ 가 안 담기면 도구는 멀쩡히 구워지고 **옛 판의 src/ 를 메고 다닌다**.
#    🔵 42번 주석이 적어 둔 더 급한 길도 그대로다: 백필이
#    '../src/lib/db/connection' 을 정적 import 하고 그 끝이 vendor/dss-core 의
#    스키마다. 2026-09-21 에 스키마를 서브모듈로 옮긴 뒤 vendor 를 빠뜨려 운영
#    도구가 전부 죽은 적이 있다(Dockerfile 71-76줄 주석).
if grep -qE '^COPY .*src \./src' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 src/ 를 담는다 (**이번에 고친 코드가 들어가는 유일한 길**)"
else
  bad "Dockerfile 이 src/ 를 안 담는다 — 이번에 고친 코드가 통째로 빠진다"
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
# 🔵 백필 도구 파일 셋 — **이번 판에서도 한 글자도 안 바뀌었다.** 그래도 검사는
#    그대로 둔다: 이 파일들은 여전히 이미지에 있어야 백필을 부를 수 있다.
for f in scripts/backfill-kyosan-used-parts.ts \
         scripts/lib/kyosan-used-parts-backfill.ts \
         scripts/lib/kyosan-used-parts-backfill-plan.ts; do
  if [ -s "$ASDIR/$f" ]; then
    ok "$f 가 저장소에 있다"
  else
    bad "$f 가 없다 — 담을 것이 없다"
  fi
done
# 🔵 앞의 다섯은 43·44·45번이 넣은 줄이고 **그대로 둔다.**
# 🔴 **여섯째가 이번 판에 더한 것이다** — src/lib/domain/inventory-gateway.ts 는
#    이번에 **도구 닫힘 안에서 바뀐 바로 그 파일**이다(머리말의 실측).
for f in src/lib/kyosan/parts-detail-sheet.ts \
         src/lib/kyosan/report-preview.ts \
         src/lib/domain/used-part-display.ts \
         src/lib/auth/repair-case-used-parts-authorization.ts \
         src/lib/server/inventory-gateway.ts \
         src/lib/domain/inventory-gateway.ts; do
  if [ -s "$ASDIR/$f" ]; then
    ok "$f 가 저장소에 있다"
  else
    bad "$f 가 없다 — 이미지에 담길 것이 없다"
  fi
done

# ── ㄴ) 🔴 **도구 닫힘 안의 이름난 파일 열 중 몇이 바뀌었나** ──────────
#   🔴 **이것이 이번 판의 가장 센 까닭이다** — 1개 이상이면 「부르니까 굽는다」다.
#   🔵 아래 열은 46번이 2026-10-29 에 닫힘 161개 안에 있다고 확인한 그 목록이고,
#      이 파일을 쓰면서 **같은 펼치개로 다시 재어 열 다 들어 있음을 확인했다.**
#      앞의 넷은 도구 자신의 몸이고(백필 셋 + DB 연결), 뒤의 여섯은 45번이
#      「도구가 부른다」고 적은 넷과 43번이 적은 kyosan 둘이다.
#   🔴 **used-part-display.ts 는 여기 없다.** 45번이 바로잡은 그대로 — 그 파일은
#      닫힘 **밖**이다. 닫힘 밖의 파일을 이 목록에 넣으면 셈이 부풀려진다.
#   🔵 46번이 넣어 둔 「그 파일이 아직 저장소에 있나」 가드를 **그대로 둔다** —
#      이름이 바뀌었는데 0 이 나와 「안 바뀌었다」로 조용히 지나가는 길을 막는다.
#      (표본이 비어서 공짜로 통과하는 꼴.)
TOOLS_CALLED="scripts/backfill-kyosan-used-parts.ts scripts/lib/kyosan-used-parts-backfill.ts scripts/lib/kyosan-used-parts-backfill-plan.ts src/lib/db/connection.ts src/lib/auth/repair-case-used-parts-authorization.ts src/lib/db/queries/repair-case-used-parts.ts src/lib/domain/inventory-gateway.ts src/lib/server/inventory-gateway.ts src/lib/kyosan/parts-detail-sheet.ts src/lib/kyosan/report-preview.ts"
CALLED_HIT=0
CALLED_SEEN=0
for f in $TOOLS_CALLED; do
  CALLED_SEEN=$((CALLED_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 저장소에 없다 — **도구 닫힘 목록이 낡았다.** 닫힘을 다시 재세요"
    continue
  fi
  if git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- "$f" 2>/dev/null | grep -q .; then
    CALLED_HIT=$((CALLED_HIT+1)); say "🔴 바뀌었다 · 도구가 부른다 — $f"
  fi
done
say "도구 닫힘의 이름난 파일 ${CALLED_SEEN}개를 봤고, 그중 바뀐 것 ${CALLED_HIT}개 (적어 둔 수는 $TOOLS_CALLED_WANT)"
if [ "$CALLED_SEEN" = "10" ]; then
  ok "닫힘 목록 열을 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
else
  bad "닫힘 목록을 ${CALLED_SEEN}개만 봤다 — 열을 기대했다. 목록이 깨졌다"
fi
if isnum "${CALLED_HIT:-}" && [ "${CALLED_HIT:-0}" -ge 1 ]; then
  ok "도구가 부르는 파일이 ${CALLED_HIT}개 바뀌었다 — **부르니까 굽는다**(머리말 ㄱ)"
  say "🔵 그 하나의 diff 는 주석뿐이지만 **그래도 굽는다** — 까닭은 머리말 ㄹ 이다."
else
  # 🔵 ⚠️ 다. 0 이 나와도 「굽지 마라」는 뜻은 아니다(44번이 그런 판이었다) —
  #    「부르니까 굽는다」는 이번 판의 **까닭이 사라졌다**는 뜻이라 사람이 봐야 한다.
  #    🔴 그때는 46-build.sh 쪽(안 굽는 판)을 베끼는 것이 맞는지 먼저 재세요.
  note "도구가 부르는 길에서 바뀐 파일이 0개다 — ${TOOLS_CALLED_WANT}개를 적어 두었다. 굽는 까닭이 사라졌다. 사람이 보세요"
fi

# ── 🔴 **「담기는 것」으로도 센다** (39번에 넓혀 둔 잣대) ──────────────
#   🔴 **src/ 를 빠뜨리지 마라.** Dockerfile 의 tools 스테이지가 COPY src ./src
#      를 한다(바로 위에서 그것을 검사하고 있다).
TOOLS_PATHS="scripts/ src/ package.json drizzle.config.ts tsconfig.json vendor/"
TOOLS_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | wc -l | tr -d ' ')
PKG_LINES=$(git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | wc -l | tr -d ' ')
say "tools 스테이지가 담는 것 중 달라진 파일 ${TOOLS_CHANGED:-못 쟀다}개 · 그중 package.json 의 diff 는 ${PKG_LINES:-못 쟀다}줄"
if isnum "${TOOLS_CHANGED:-}" && [ "${TOOLS_CHANGED:-0}" -ge 1 ]; then
  ok "도구를 구울 까닭이 있다 — 기준 $AS_BASE 이후 달라진 파일 ${TOOLS_CHANGED}개 (적어 둔 수는 $TOOLS_CHANGED_WANT)"
  git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | head -16 | sed 's/^/      /'
else
  bad "달라진 파일이 ${TOOLS_CHANGED:-못 쟀다}개다 — 도구를 구울 까닭이 없다. 전제가 깨졌으니 멈추고 알릴 것"
fi
# 🔵 적어 둔 수와 다르면 ⚠️ 로만 센다(45번 그대로) — 표가 낡았다는 뜻이지 굽지
#    말라는 뜻이 아니다. 🔵 아래 ㄱ 이 **어느 파일이** 달라졌는지까지 찍어 준다.
if [ "${TOOLS_CHANGED:-x}" != "$TOOLS_CHANGED_WANT" ]; then
  note "달라진 파일이 ${TOOLS_CHANGED:-?}개다 — 적어 둔 것은 ${TOOLS_CHANGED_WANT}개다. 커밋이 더 쌓였는지 사람이 보세요"
fi

# ── ㄱ) 🔵 **달라진 파일 목록이 적어 둔 열다섯과 글자 그대로 같은가** ──
#   🔴 46번에서 이 줄은 ✗ 였다 — 그 판의 「안 굽는다」가 통째로 이 목록 위에
#      서 있었기 때문이다. 🔵 **이 파일에서는 ⚠️ 다.** 굽기로 했으므로 목록이
#      달라져도 굽는 판정은 안 흔들린다. 흔들리는 것은 **머리말의 실측과
#      47-deploy.sh 꼬리말의 「볼 곳」**이고, 그것은 사람이 읽어야 한다.
#      🔴 **재기는 그대로 잰다 — 뺀 검사가 아니다.**
#   🔴 **따옴표로 감싼 여러 줄 변수**로 둔다 — 이번 목록에는 대괄호가 없지만
#      46번 목록에는 '[id]' 가 있었다. 따옴표 없이 펼치면 셸이 글자 묶음 패턴으로
#      읽는다(머리말 함정 ⑤).
TOOLS_CHANGED_LIST='
src/components/product-models/ProductModelHistoryBreakdown.tsx
src/components/product-models/product-model-fault-part-detail.test.tsx
src/components/product-models/product-model-fault-part-warning.test.tsx
src/components/product-models/product-model-history-period.test.tsx
src/lib/db/queries/product-models.integration.test.ts
src/lib/db/queries/product-models.ts
src/lib/domain/fault-part-inventory.test.ts
src/lib/domain/inventory-gateway.ts
src/lib/domain/pie-slices.test.ts
src/lib/domain/pie-slices.ts
src/lib/domain/product-model-breakdown.test.ts
src/lib/domain/product-model-breakdown.ts
src/lib/domain/product-model-fault-parts.test.ts
src/lib/domain/product-model-fault-parts.ts
src/lib/domain/product-model-period-filter.test.ts
'
WANT_LIST=$(printf '%s\n' "$TOOLS_CHANGED_LIST" | grep -v '^[[:space:]]*$' | sort)
GOT_LIST=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | sort)
if [ -z "${GOT_LIST:-}" ]; then
  unk "달라진 파일 목록" "git diff 가 아무것도 안 돌려줬다 — 기준 SHA 를 보세요"
elif [ "$GOT_LIST" = "$WANT_LIST" ]; then
  ok "달라진 파일이 **적어 둔 열다섯 그대로**다 — 2026-10-29 의 닫힘 실측이 이 커밋을 덮는다"
else
  note "달라진 파일이 적어 둔 열다섯과 **다르다** — 굽는 것은 그대로 굽되, 머리말의 닫힘 실측과 47-deploy.sh 꼬리말을 사람이 다시 보세요"
  say "🔵 닫힘을 다시 재는 법은 이 파일 머리말에 명령 세 줄로 적어 두었다."
  say "── 적어 둔 것에 없는데 바뀐 것"
  printf '%s\n' "$GOT_LIST" | grep -vxF -f <(printf '%s\n' "$WANT_LIST") | head -12 | sed 's/^/      /'
  say "── 적어 두었는데 안 바뀐 것"
  printf '%s\n' "$WANT_LIST" | grep -vxF -f <(printf '%s\n' "$GOT_LIST") | head -12 | sed 's/^/      /'
fi

# ── ㄷ) 🔵 **package.json 이 0줄 바뀌었는가** ─────────────────────────
#   🔴 46번에서는 이 줄이 ✗ 였다 — **도구를 안 굽는 판**에서 npm 명령이 늘면
#      38번의 'npm error Missing script' 가 그대로 돌아오기 때문이다.
#   🔵 이 파일에서는 ⚠️ 다(45번과 같다). 굽고 올리므로 늘어난 명령도 함께 간다.
#      다만 **늘었다면 그 이름을 사람이 확인해야** 한다 — 47-deploy.sh 가 그 이름을
#      부를 자리를 적어 두어야 할 수도 있다.
if [ "${PKG_LINES:-x}" = "0" ]; then
  ok "package.json 이 한 줄도 안 바뀌었다 — 이번에도 npm 명령이 아니라 **직접 호출**이다 (적어 둔 그대로)"
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
  #    scripts/ 도 package.json 도 없어 오류 없이 쓸모없는 이미지가 된다
  #    (RF_Service_System/Dockerfile 은 tools 스테이지를 runner **앞에** 둔다 —
  #    --target 없이 구우면 마지막 스테이지인 runner 가 기본값이 된다).
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
  #    🔵 단계는 45번의 여섯 그대로고, ③-ㄱ 이 다섯에서 여섯으로 · ③-ㄴ 의 이름
  #       셋이 **이번 판의 것으로** 바뀐다(아래 주석).
  #    🔴 앱 이미지 안은 안 센다 — 앱이 제대로 구워졌는지는 NAS 에서 **실제로 떠서
  #       응답하는지**로 재는 것이 더 센 신호다(47-deploy.sh 7절).
  if [ "$KEY" = "astools" ]; then
    printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TAG"
    IMGFAIL=0
    # ① runner 가 아니라 tools 인가 — runner 에는 /app/package.json 이 없다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '      /app/package.json: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tools 스테이지가 맞다\n'
    else printf '  ✗ /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다\n'; IMGFAIL=1; fi
    # ② 백필 도구 파일 셋이 다 담겼는가 — 하나라도 없으면 ✗.
    #    🔵 이번 판에서 이 셋은 한 글자도 안 바뀌었지만, 있어야 부를 수 있다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts /app/scripts/lib/kyosan-used-parts-backfill-plan.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "3" ]; then printf '  ✓ 백필 도구 파일 셋이 다 들어갔다\n'
    else printf '  ✗ 백필 도구 파일이 %s/3 개다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
    # ③-ㄱ 🔴 **src/ 가 온전히 담겼는가 — 파일 여섯으로 센다.**
    #    앞의 다섯은 43·44·45번이 넣은 줄이고 **그대로 둔다.** 여섯째가 이번에 더한
    #    것이고, **이번에 도구 닫힘 안에서 바뀐 바로 그 파일**이다.
    #    🔴 **여섯이 다 있어야 ✓.**
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/src/lib/kyosan/parts-detail-sheet.ts /app/src/lib/kyosan/report-preview.ts /app/src/lib/domain/used-part-display.ts /app/src/lib/auth/repair-case-used-parts-authorization.ts /app/src/lib/server/inventory-gateway.ts /app/src/lib/domain/inventory-gateway.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "6" ]; then printf '  ✓ src/ 의 파일 여섯이 다 들어갔다 (도구와 앱이 같은 판이다)\n'
    else printf '  ✗ src/ 의 파일이 %s/6 개다 — src/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
    # ③-ㄴ 🔴 **그 src/ 가 '이번 판' 인가 — 글자로 센다.** ㄱ 은 「있나」만 본다.
    #    낡은 src/ 가 담겨도 파일 이름은 그대로라 ㄱ 은 통과한다.
    #    🔴 **여기가 45번과 크게 다른 자리다.** 45번은 닫힘 안에서 바뀐 파일에서
    #       새 이름을 뽑았다. 이번 판은 닫힘 안에서 바뀐 파일이 하나뿐이고 그 하나는
    #       **주석만** 바뀌어 **새 이름이 아예 없다.** 그래서 이름 셋을 닫힘 밖,
    #       그러나 **이번 커밋에서 새로 생긴** 자리에서 뽑았다.
    #       🔵 그래도 되는 까닭: 이 검사가 묻는 것은 「도구가 무엇을 부르나」가
    #          아니라 「**이 이미지의 src/ 가 어느 판인가**」다. tools 스테이지는
    #          COPY src ./src 로 src/ 를 **통째로** 담으므로, src/ 어디서 뽑은
    #          이름이든 판을 똑같이 가른다.
    #    🔵 셋 다 기준 081439b 판의 그 파일에는 **0번** 나오고 지금 판에는 나온다
    #       (2026-10-29 git show 로 파일마다 세어 확인: 0 → 8 · 0 → 9 · 0 → 1).
    #    🔴 이름은 전부 **ASCII** 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for pair in "faultPartQuantity /app/src/lib/domain/product-model-fault-parts.ts" "weightOf /app/src/lib/domain/pie-slices.ts" "requestedQuantity /app/src/lib/db/queries/product-models.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "3" ]; then printf '  ✓ 이번 판의 이름 셋이 이미지 안에 있다 (옛 src/ 가 아니다)\n'
    else printf '  ✗ 이번 판의 이름이 %s/3 개다 — **옛 src/ 가 담겼다.** 캐시를 의심하세요\n' "${got:-0}"; IMGFAIL=1; fi
    # ④ tsx 가 있는가 — 이 도구는 tsx 로만 돈다(운영 이미지에는 없는 devDependency다).
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '      /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tsx 가 있다\n'
    else printf '  ✗ tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
    # ⑤ 🔴 **값을 받아 본다.** DATABASE_URL 을 안 주고 부른다 — 백필이 1·9줄에서
    #    './load-env' 와 '../src/lib/db/connection' 을 정적 import 하고,
    #    connection.ts 가 모듈 맨 위에서 던진다. 인자를 안 줘도 파싱까지 안 가고
    #    import 에서 막힌다. **DB 에는 한 글자도 안 닿는다.**
    #    🔴 이 단계가 말해 주는 것은 **import 가 선다**까지다. 🔵 이번 판에서도
    #       백필을 다시 돌리지 않으므로(47-deploy.sh 꼬리말) 도구가 선다는 것을
    #       확인할 자리가 **여기 말고 없다.**
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
    # ⑥ 🔵 이미지 안의 drizzle/ 은 **비어 있어야** 한다 — 볼륨으로 붙는 자리다.
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

# ══ 🔴 47-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 47-deploy.sh 의 TARS 는 **이름만 적힌 채로** 올라간다. 지문 칸이 비어 있으면
#     그 파일이 ? 로 세고 「옮기다 깨진 것」만 잡는다 — 아래 두 줄로 그 두 줄을
#     **통째로 갈아 끼운다.** 🔵 마이그레이션 묶음은 이번에도 없다.
printf '\n%s\n' "════════ 47-deploy.sh 의 TARS 에 붙여 넣을 것 ════════"
printf '%s' "$TARTABLE"
printf '%s\n' "  🔴 위 두 줄로 TARS 의 두 줄을 통째로 갈아 끼운다. 🔵 as-migrations.tar.gz 는 이번에도 없다."

printf '\n%s\n' "✅ 둘 다 구웠다. tar · 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'
printf '\n%s\n' "🔵 다음 — 올릴 곳이 **둘**이다 (대화에서 내가 한다):"
printf '%s\n' "    · 이미지 tar 둘  → NAS 의 /volume1/dss/images/"
printf '%s\n' "      (dss-as-4.0.tar · dss-as-tools-7.tar)"
printf '%s\n' "    · 47-deploy.sh 자신 → NAS 의 /volume1/dss/setup/  (md5 를 맞춘다)"
printf '%s\n' "🔵 **마이그레이션 묶음은 없다** — 이번 판도 drizzle/ 이 0건이다."
printf '%s\n' "────────────────────────────────────────────────────────────"
