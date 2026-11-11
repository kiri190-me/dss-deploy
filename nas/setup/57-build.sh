#!/bin/bash
# dss-deploy/nas/setup/57-build.sh — 쉰세째 배포 · 이미지 굽기 (2026-11-11)
#
# 🔵 **파일 번호가 56 이 아니라 57 인 까닭**: 56-stage.sh · 56-templates.sh 는
#    2026-11-11 에 **양식 전용**으로 쓴 번호다(배포가 아니다). 그래서 건너뛴다.
# 🔵 그리고 **배포 회차(쉰세째)와 파일 번호(57)가 어긋나는 것은 이 저장소에서
#    원래 그렇다** — 55번 파일이 쉰두째였다. 배너에 둘 다 적어 둔다.
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · PowerShell 에서 Git Bash 를 부른다) ──────────
#     cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#     & "C:\Program Files\Git\bin\bash.exe" ./57-build.sh --check
#     & "C:\Program Files\Git\bin\bash.exe" ./57-build.sh --go
#
#   🔴 **bash.exe 만 치면 WSL 이 잡힌다**(2026-11-04 에 걸렸다). WSL 에서 돌면
#      도커도 양식도 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 내어 ✗ 가
#      셋 흩어져 난다. 단서는 로그의 뿌리 경로가 **/mnt/c/…** 인 것이다.
#   🔴 **스크립트에 건네는 경로에는 역슬래시를 쓰지 않는다.** 역슬래시를 주면
#      bash 가 그것을 먹어 "C:Users희만Desktop…" 이 되어 No such file 이 난다.
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-53):
#     & "C:\Program Files\Git\bin\bash.exe" ./57-build.sh --go "/d/배포본/_images-53"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다.
#      이 파일을 쓴 쪽은 **한 번도 굽지 않았다** — --check 만 돌려 보았다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **55-build.sh 에서 베꼈다가 「이번 판엔 거짓」이라 뒤집은 것 열**
# ══════════════════════════════════════════════════════════════════════
#   틀과 절 구성은 55-build.sh(쉰두째)를 그대로 썼다. 다만 **그 파일이 참이라고
#   적어 둔 것 중 열 가지가 이번 판에는 거짓**이라, 하나씩 다시 재서 뒤집었다.
#   🔴 「배포본은 지난 판의 전제를 업고 온다」가 이 저장소에 기록된 함정이다.
#
#   ① 🔴 **마이그레이션이 0건이다.** 55번은 2건(0125·0126)이라 「125 → 127 두
#      갈래 · 묶음 필수」였다. 이번은 **기준 SHA 이후 drizzle/ 변경이 0개**이고
#      저장소도 운영 볼륨도 **127 그대로**다. 기대값이 **한 갈래**다.
#   ② 🔴 **DB 기록이 안 움직인다 — 앞뒤가 같다.** 55번은 125 → 127 이었다.
#      🔴 그 글을 베껴 오면 「올린 뒤에 127 이어야 한다」가 **아무것도 안 재는
#      ✓** 가 된다(어차피 127 이다). 그래서 이 판은 **「앞뒤가 같은가」**로 잰다.
#   ③ 🔴 **묶음(as-migrations.tar.gz)을 안 만들고 안 보낸다.** 55번은 필수였다.
#      🔵 보험이 필요하면 **이미 있다** — _images-52/as-migrations.tar.gz 가
#         127장이고 md5 가 ddec2e73f6ef979b6983dd929494eab9 다(2026-11-11 재확인).
#      🔴 그래서 **57-deploy.sh 에는 --migrate 모드가 없다**(그 파일 머리말).
#   ④ 🔵 **--go 의 DB 조건이 「127 이어야 한다」가 아니라 「127 그대로」다.**
#      바뀌는 것이 아니라 **안 바뀌는 것**을 확인하는 자리다.
#   ⑤ 🔴 **공용 스키마(vendor/dss-core)가 안 움직였다.** 55번은 움직였다
#      (460458a → 6688e5d). 이번 기준판과 지금이 **둘 다 6688e5d** 다 —
#      3절의 판정을 **다시 뒤집었다.** 🔴 55번 글을 베끼면 멀쩡한 판이 ✗ 다.
#   ⑥ 🔴 **이미지 안 검사의 증거를 이번 판 것으로 갈았다.** 55번은 toKstDateOnly
#      였다(밤 아홉 시간에만 드러나는 결함을 가르는 글자). 이번 판의 증거는
#      **no-equipment-key** 와 **listRepairCaseIdsWithOrderIssuedDate** 다.
#      🔵 앱 이미지 쪽은 **먼저 재 보고 골랐다** — 아래 「증거를 어떻게 골랐나」.
#   ⑦ 🔴 **「도구 닫힘 안에서 바뀐 아홉」이 이번 판에는 아무것도 안 잰다.**
#      55번이 적어 둔 아홉 중 바뀐 것이 **0개**다(2026-11-11 실측). 그 절을
#      「1개 이상 바뀌어야 ✓」로 베껴 오면 **멀쩡한 판이 ✗** 가 된다.
#      🔵 그래서 기대값을 **0 으로 뒤집고**, 이미지 안 검사는 **이번 판이 바꾼
#         12개**로 갈았다(그쪽이 이 배포를 실제로 재는 목록이다).
#   ⑧ 🔴 **「이번에 생긴 파일 다섯」이 이번 판에는 0개다.** src/ 에 **A(추가)가
#      한 개도 없다** — 열둘 전부 M(수정)이다. 목록을 비우면 0/0 으로 **공짜
#      통과**가 되므로, 절을 **「새 파일이 정말 0개인가」를 값으로 재는 쪽**으로
#      바꿨다(루트의 설명 HTML 하나만 A 다).
#   ⑨ 🔴 **tools 바깥에서 바뀐 파일이 1개이고 drizzle/ 이 아니다.** 55번은
#      5개였고 **전부 drizzle/** 이었다. 이번 하나는 저장소 뿌리의
#      **설명 HTML** 이다.
#      🔴 **그 HTML 은 앱 이미지에 담긴다.** 처음에 「이미지 어느 쪽에도 안
#         담긴다」고 적었다가 **실측에서 틀렸다**(2026-11-11): .next/standalone
#         은 **저장소 뿌리를 그대로 옮기고** .dockerignore 는 .html 을 안 막는다.
#         🔵 **도구 이미지에는 안 담긴다** — tools 스테이지는 폴더를 골라 담는다
#            (package.json · tsconfig · drizzle.config · scripts/ · src/ · vendor/).
#         🔵 덕분에 **앱 이미지에 이번 판을 가르는 수가 하나 더 생겼다** —
#            뿌리의 .html 이 기준판 **18** → 지금 **19** 다.
#   ⑩ 🔵 지난 판 tar 크기 둘을 **이번 판의 상대**(4.8 · tools-15)로 갈았다.
#      출처는 _images-52 에서 stat 한 값이다(2026-11-11 재확인).
#
# ── 이번에 굽는 것 — **저장소 하나, 이미지 둘** ───────────────────────
#     ① A/S 앱    dss-as:4.8        → **dss-as:4.9**        커밋 4  스테이지 기본(runner)
#     ② A/S 도구  dss-as-tools:15   → **dss-as-tools:16**   커밋 4  🔴 --target tools
#
#   🔴 **셋째 산출물이 없다.** 55번에는 마이그레이션 묶음이 있었다 —
#      **이번 판에는 안 만든다**(위 ③).
#
#   🔴 **포털(dss-auth)은 안 굽는다** — HEAD 가 53번이 구운 f87bf7d 그대로다.
#   🔴 **PO(dss-po)도 안 굽는다** — HEAD 가 기준 SHA(9c1b2ef) 그대로다.
#   🔵 **양식(.xlsx)은 한 장도 안 올린다.** 이번 범위에 .xlsx 변경이 **0줄**이다
#      (8절이 열하나의 바이트·md5 를 다시 잰다 — 열하나가 55번 값 그대로였다).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **도구 이미지를 굽는 까닭 — 마이그레이션 수로 정하지 않는다**
# ══════════════════════════════════════════════════════════════════════
#   잣대는 41·48·52~55번이 쓰던 셋 그대로다:
#     ㄱ) npm 명령이 늘었나   ㄴ) 도구의 import 닫힘 안이 바뀌었나
#     ㄷ) **tools 스테이지가 담는 것 중 바뀐 파일이 있나**
#
#   🔴 **이번 판은 ㄷ 하나만 걸린다. 그런데 그 하나로 충분하다.**
#      RF_Service_System/Dockerfile **69줄**이
#          COPY --chown=node:node src ./src
#      다 — **tools 스테이지가 src/ 를 통째로 담는다**(66~79줄: package.json ·
#      tsconfig.json · drizzle.config.ts · scripts/ · src/ · vendor/).
#      이번에 바뀐 12개가 **전부 src/** 라서 **도구 이미지의 내용이 달라진다.**
#      🔵 아래 5절-ㄱ 이 그 COPY 줄들을 **파일에서 직접 읽어** 확인한다.
#
#   ㄱ **안 걸린다.** package.json diff **0줄** · scripts 항목 **39 → 39**.
#   ㄴ **안 걸린다.** 55번이 적어 둔 닫힘 아홉 중 바뀐 것 **0개**이고, 이번에
#      바뀐 12개를 **scripts/ 가 import 로 부르는 곳도 0개**다. 🔵 글자로는
#      scripts/lib/delivered-date-sync-survey.ts 에 'domestic-orders' 가 한 번
#      나오지만 **48줄의 주석**이다 — 그 파일의 import 는 한 줄뿐이고
#      domain/domestic-order-list 다(2026-11-11 실측).
#      🔴 「소스 글자로 재는 검사는 주석을 먼저 센다」가 이 저장소의 기록이다.
#   ㄷ **걸린다.** tools 가 담는 것 중 달라진 파일 **12개**(전부 src/).
#      🔵 바깥은 **1개**이고 drizzle/ 이 아니라 **설명 HTML** 이다.
#
#   🔴 **지난 배포에서 이 판단을 두 번 틀렸다** — 한 번은 안 구워서 도구 안의
#      비상구 둘이 옛 것이 됐고, 다음엔 반대로 보고 Missing script 가 났다.
#      그래서 이 파일은 **「마이그레이션이 몇 건인가」를 굽기 판정에 안 쓴다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이미지 안 검사 — **증거를 어떻게 골랐나** (먼저 재 보고 골랐다)
# ══════════════════════════════════════════════════════════════════════
#   🔴 이번 범위의 **마지막 커밋(4c7eb9fa)은 주석만 고친다** — 비주석 추가 줄이
#      0 이다. 그래서 **앱 이미지(번들)에서는 마지막 커밋을 가를 수 없다.**
#      🔵 도구 이미지는 src/ 를 **글자 그대로** 담으므로 주석도 함께 담긴다 —
#         그쪽에서는 가를 수 있고, 아래 ⑤ 가 그 자리다.
#
#   ── 도구 이미지(dss-as-tools:16) — 소스가 그대로 있다
#      · listRepairCaseIdsWithOrderIssuedDate  (조각 ①)
#      · no-equipment-key                      (조각 ②)
#      · PURCHASE_ORDER_FOLDER_SECTION_NO_EQUIPMENT_KEY_TEXT (조각 ② · 화면)
#      · repair-case-quote-numbers.ts 안의 listRepairCaseIdsWithOrderIssuedDate
#        🔴 **이 한 줄만 마지막 커밋(4c7eb9fa)에 생긴다** — 주석이다.
#           없으면 9fb3669d 를 구운 것이다.
#      기준판(94895136)에서 전부 **0번**이다(2026-11-11 실측).
#
#   ── 앱 이미지(dss-as:4.9) — .next/standalone 이라 번들된 결과물이다
#      🔴 **안 나오는 것을 기대값으로 박으면 가짜 ✗ 가 난다.** 그래서 개발 PC 의
#         .next/standalone/.next/server(2026-11-11 11:16 빌드 · Next 16.2.12 ·
#         Dockerfile 이 돌리는 것과 같은 「npm run build」)에서 **먼저 세어 보았다**:
#            no-equipment-key                     **4 파일**  ← 하드 게이트
#            due_date_row_order                   **5 파일**  ← 뒷걸음 방지
#            listRepairCaseIdsWithOrderIssuedDate **2 파일**  ← ⚠️ 로만 센다
#      🔵 no-equipment-key 는 **응답에 실려 나가는 글자 리터럴**이라 minifier 가
#         이름을 바꿀 수 없다 — 그래서 이것만 ✗ 로 센다.
#      🔵 listRepairCaseIdsWithOrderIssuedDate 는 **식별자**다. 지금 번들러는
#         내보낸 이름을 남기지만 **그것은 번들러가 정하는 일**이라, 0 이 나와도
#         ⚠️ 로만 센다. 🔴 「재서 나왔다」와 「앞으로도 나온다」는 다른 말이다.
#      🔵 due_date_row_order 는 **이번 판이 만든 글자가 아니다** — 쉰두째 것이
#         그대로 있는지 보는 **뒷걸음 방지**다. 그 뜻을 그대로 적어 둔다.
#
# ── 🔴 모드 둘 ────────────────────────────────────────────────────────
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다.
#            🔵 **쓰는 것**: 없다(폴더도 --go 때만 만든다).
#            🔵 **안 쓰는 것**: 전부.
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면
#            굽지 않고 멈춘다. 전부 ✓ 일 때만 둘을 굽고 tar 로 뽑는다.
#            그리고 **이미지 안을 센다**(겉이 아니라 결과).
#            🔵 **쓰는 것**: $OUT 폴더 · tar 둘 · 빌드 로그 둘 · 도커 이미지 둘.
#            🔵 **안 쓰는 것**: 저장소 안의 파일 · 묶음 · NAS · DB.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 tar 크기를 **두 번** 견준다 ────────────────────────────────────
#   ① **지난 판 tar 와** 견준다. 적어 둔 값의 출처:
#        dss-as-4.8.tar       134617600  [실측] 2026-11-11 _images-52 에서 stat
#        dss-as-tools-15.tar  225323520  [실측] 2026-11-11 _images-52 에서 stat
#      🔴 **둘 다 한 판 전이라 25% 를 넘으면 ✗ 다**(strict).
#   ② **그 이미지 자신과** 견준다. 🔴 여기가 함정이라 가지를 둘로 나눴다:
#      · containerd 저장소면 'docker image inspect {{.Size}}' 가 **압축된 내용
#        크기**를 주어 tar 와 거의 같다(90~110%).
#      · 고전 저장소면 그 값이 **펼친 크기**라 tar 는 그 **1/4쯤**이다(10~45%).
#      🔴 **둘 중 어느 쪽인지 미리 못 정한다.** 한 잣대로 재면 **가짜 ✗** 가 난다.
#   🔴 **tar 지문은 'docker image inspect' 의 .Id 와 맞대지 않는다.** 그것은
#      애초에 다른 값이다. 맞댈 상대는 **빌드 로그의 'exporting config sha256:'** 이다.
#
# ── 🔴 이 환경의 함정 (36~55-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싸고, 저장소 자리를
#      이 파일의 자리에서 계산한다(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:/… 를 /c/… 로
#      바꾸고, docker save 는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를
#      막는다 — 5절-ㄴ 이 그것도 잰다). 🔴 그래도 **7절이 3000번을 재서 찍는다** —
#      「.next 를 두고 다툰다」가 이 저장소의 기록이라, 사람이 알고 굽게 한다.
#   ④ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다.** 아래 검사의 이름은 전부 ASCII 다.
#   ⑤ 🔴 **대괄호·괄호가 든 경로를 글롭에 넘기지 않는다.** 이번 판의 파일 중
#      src/app/(app)/… 과 …/[id]/… 가 있다. 🔴 git 의 **pathspec 은 글롭**이라
#      「-- "…/[id]/…"」 로 물으면 **조용히 0줄**이 돌아온다. 그래서 이 파일은
#      바뀐 목록을 **한 번만 뽑아 두고 grep -Fx 로 맞댄다.**
#      🔴 셸 쪽도 같다 — 목록은 **here 문서 + while read** 로만 돌린다.
#      🔴 컨테이너 안에서도 경로를 **큰따옴표**로 감싼다. 「(app)」 은 sh 의 문법이라
#         안 감싸면 **문법 오류**로 죽고, 「[id]」 는 글롭이라 조용히 빗나간다.
#   ⑥ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」
#      같은 안전망을 달면 **하필 바라던 0 에서만** 그것이 터져 값이 "0 ?" 가 된다.
#      이 파일은 그 꼴을 **한 군데도 쓰지 않는다** — 「$( … || true )」 로 종료 코드만 가린다.
#   ⑦ 🔴 **tar | grep -q 를 if 에 바로 물리지 않는다.** set -uo pipefail 때문에
#      grep -q 가 먼저 끝나면 앞의 tar 가 SIGPIPE 로 죽고 **파일이 있을 때 오히려
#      ✗** 가 난다(2026-11-07 쉰째에서 실제로 났다). **세어서 담고 비교하는 꼴**로만 쓴다.
#      🔵 이번 판에는 묶음이 없어 tar 를 읽는 자리가 **하나**뿐이다(tar_config_id).
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안의 백틱은 명령 치환으로 읽힌다 → 이 파일에는 백틱이 **한 개도 없다.**
#   ② 읽기 전용 자리의 콜론과 꺾쇠로 빈 파일을 만드는 꼴은 ash 를 죽인다 →
#      이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   🔴 19·20·21번에는 그 둘이 아직 남아 있다. **거기서 베껴 오지 마라.**
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEV=${DSS_DEV:-$(cd "$SCRIPT_DIR/../../.." && pwd)}

PASS=0; FAIL=0; UNK=0
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
unk()  { UNK=$((UNK+1));   printf '  ? %s — 못 쟀다 (%s)\n' "$1" "$2"; }
note() { printf '  ⚠️ %s\n' "$1"; }
say()  { printf '    %s\n' "$1"; }
# 🔴 ✗ 가 났을 때 그 자리에서 찍는다 — 처음 도는 코드라 기대값이 틀릴 확률이
#    굽기만큼 높다. ✓ 쪽 오판은 영영 안 드러나므로 ✗ 쪽을 크게 적는다.
doubt() { say "🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 이 줄의 기대값이"
          say "   어디서 왔는지는 이 파일 머리말에 적혀 있습니다."; }

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

# tar 안 manifest.json 의 Config 지문 (39~55-build.sh 의 것을 글자 그대로)
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
  j=$(grep -o '"idx"' "$1/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  printf '%s %s' "${s:-0}" "${j:-0}"
}

# 두 수의 차이가 몇 퍼센트인가 (정수). 0 으로 나누지 않는다.
pct_diff() { # 1 새값 2 옛값 → 퍼센트(정수). 못 재면 아무것도 안 찍는다.
  local a b d
  a=$1; b=$2
  isnum "$a" || return 1
  isnum "$b" || return 1
  [ "$b" -gt 0 ] || return 1
  if [ "$a" -ge "$b" ]; then d=$((a - b)); else d=$((b - a)); fi
  printf '%s' $((d * 100 / b))
}

# package.json 의 scripts 블록 **안**만 센다.
count_scripts() { # stdin = package.json
  awk '
    /^  "scripts": \{/ { inb = 1; next }
    inb && /^  \}/      { inb = 0 }
    inb && /^    "/     { n++ }
    END { print n + 0 }
  '
}

# ══ 이번에 굽는 것 — 한자리에 모아 둔다 ═══════════════════════════════
#   열쇠|저장소 폴더|새 태그|기준 SHA|--target(없으면 -)|기대 drizzle 변경 수|기대 커밋 수|지난판 tar 바이트|지난판 tar 이름|크기 엄함
#
#   🔴 여섯째 칸은 「기준 SHA 이후 drizzle/ 에서 **달라진 파일 수**」다.
#      🔴 **이번 판은 0 이다.** 55번은 5 였다. 🔴 「0 이면 통과」가 아니라
#         **적어 둔 수와 똑같아야** 한다 — 늘었으면 이 배포의 전제가 깨진 것이다.
#   🔵 일곱째 칸(커밋 수)은 ✗ 로 세지 않고 ⚠️ 로만 센다. A/S **넷**이다.
#   🔴 'astools' 는 **같은 저장소**를 --target tools 로 한 번 더 굽는 줄이다.
#   🔵 열째 칸: strict = 25% 넘으면 ✗ · loose = 25% ⚠️ · 60% 넘으면 ✗ (머리말).
SITES='
as|RF_Service_System|dss-as:4.9|94895136|-|0|4|134617600|dss-as-4.8.tar|strict
astools|RF_Service_System|dss-as-tools:16|94895136|tools|0|4|225323520|dss-as-tools-15.tar|strict
'
HOWMANY=2
AS_APP_TAG=dss-as:4.9
AS_TOOLS_TAG=dss-as-tools:16
# 🔵 되돌릴 판 — 57-deploy.sh --rollback 이 쓰는 그것이다.
AS_OLD_TAG=dss-as:4.8
AS_TOOLS_OLD_TAG=dss-as-tools:15

# ── 🔴 기대값과 그 출처 — 전부 [실측] 2026-11-11 개발 PC ───────────────
#   🔴 기준 SHA 는 **출처 둘을 맞대어** 확인했다:
#      ㄱ) 55-build.sh 97줄의 범위가 4bbf0df1..94895136 이고 그 HEAD 가 쉰두째가
#          올린 것이다.
#      ㄴ) dss-deploy/README.md 301줄의 기준 SHA 표(2026-11-09 02:10 갱신 ·
#          쉰두째까지)도 A/S 를 **4.8 · 94895136** 으로 적는다. **둘이 맞았다.**
AS_BASE=94895136
AS_HEAD_SHORT=4c7eb9fa
AS_HEAD_FULL=4c7eb9fa1d43f4dfceb8378284f18017ad653d25
AUTH_BASE=f87bf7d
PO_BASE=9c1b2ef

# 🔴 A/S drizzle — **127 그대로.** 이번 판에는 새 마이그레이션이 없다.
AS_SQL_WANT=127
AS_PROD_SQL_NOW=127   # 🔵 운영 볼륨이 지금 들고 있는 수(55번이 올린 127)
AS_LAST_MIG=0126      # 🔴 저장소의 마지막 — 55번이 올렸다
AS_NEXT_MIG=0127      # 🔴 이것이 생겼으면 전제(0건)가 깨진 것이다
# 🔴 **다음 번호를 셈으로 만들지 않는다.** bash 의 $(( )) 는 0 으로 시작하는 수를
#    **8진수**로 읽어 0126+1 이 87 이 된다 — 오류 없이 엉뚱한 파일을 찾는다.
AS_LAST_MIG_FILE=0126_faulty_otto_octavius.sql
# 🔴 **이번에 생긴 마이그레이션은 0건이다.** 55번은 둘이었다.
AS_NEW_MIGS_WANT=0
# 🔵 묶음을 안 보내지만 **저장소 쪽이 온전한지는 센다** — 48번의 셋 + 0124 + 55번의 둘.
AS_KEEP_MIGS='0121 0122 0123 0124 0125 0126'
AS_KEEP_MIGS_WANT=6

# 🔵 **이번 판이 묶음을 안 보내므로 「지우는 문장」 검사가 없다.**
#    🔴 그렇다고 잣대를 지우지는 않는다 — 4절이 **새 .sql 이 0장인가**를 먼저
#       재고, 0 이 아니면 그 자리에서 멈춰 사람에게 넘긴다.
#    🔵 묶음이 필요해지는 판이면 55-build.sh 의 셋째 산출물 절을 되살린다.

# 서브모듈 포인터 둘.
#    🔴 **dss-core 는 이번 판에 안 움직였다** (55번은 움직였다).
AS_CORE_PIN=6688e5d71939d8f36fc89eedfeb1e5b437bd9bb2
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425
PO_CORE_PIN=8730c9433b4388a038349ab9a11ec633659da782

# 🔵 A/S — 저장소 전체 13 · tools 스테이지가 담는 것 12 · 바깥 **1**(설명 HTML).
AS_ALL_CHANGED_WANT=13
AS_TOOLS_CHANGED_WANT=12
AS_OUTSIDE_WANT=1
# 🔴 **바깥 하나가 drizzle/ 이 아니다.** 55번은 다섯이 전부 drizzle/ 이었다.
AS_OUTSIDE_DRIZZLE_WANT=0
# 🔴 포털·PO 는 0 이어야 한다(안 굽는다).
AUTH_CHANGED_WANT=0
PO_CHANGED_WANT=0

# 🔴 npm 명령 수 — **이번 판에도 안 늘었다.** 41번 잣대가 **안 걸린다.**
AS_NPM_WAS=39;  AS_NPM_NOW=39
AS_PKG_LINES_WANT=0
AS_NEW_NPM_WANT=0
# 🔴 사라지면 안 되는 A/S 명령 아홉 — 48·52~55번이 올린 것 그대로.
AS_KEEP_NPM="check:target-shipment-missing check:due-date-inverted check:requested-due-date-sync check:due-date-overdue check:delivered-date-sync procedures:export procedures:import db:preflight db:migrate"
AS_KEEP_NPM_WANT=9

# ══ 🔴 A/S 도구 닫힘 — **이번 판에는 하나도 안 바뀌었다** ══════════════
#   🔵 2026-11-11 실측. 🔴 **그 파일이 아직 저장소에 있나** 가드를 그대로 둔다 —
#      이름이 바뀌었는데 0 이 나와 「안 바뀌었다」로 조용히 지나가는 길을 막는다.
#   🔴 55번은 여기가 **3** 이었고 그것이 굽는 첫째 까닭이었다. **이번엔 0 이다.**
AS_TOOLS_CALLED='
scripts/check-delivered-date-sync.ts
scripts/check-due-date-overdue.ts
scripts/lib/delivered-date-sync-survey.ts
src/lib/db/queries/repair-case-domestic-order-due-dates.ts
src/lib/db/queries/repair-case-overdue-notifications.ts
src/lib/domain/due-date-inversion.ts
src/lib/domain/notifications.ts
src/lib/domain/repair-case-overdue.ts
src/lib/domain/types.ts
'
AS_TOOLS_CALLED_WANT=9
AS_TOOLS_CALLED_CHANGED_WANT=0

# ══ 🔴 **이번 판이 바꾼 12개** — tools 이미지가 담는 src/ 안이다 ═══════
#   🔴 괄호와 대괄호가 든 경로가 둘 있다. **글롭에 넘기지 않는다**(머리말 ⑤).
#   🔵 열둘 전부 **M(수정)** 이다 — A(추가)가 하나도 없다.
AS_CHANGED_SRC='
src/app/(app)/repair-cases/[id]/purchase-orders/page.tsx
src/app/api/repair-cases/[id]/purchase-order-folder/entries/route-source.test.ts
src/app/api/repair-cases/[id]/purchase-order-folder/entries/route.ts
src/components/repair-cases/purchase-orders/PurchaseOrderFolderSection.test.tsx
src/components/repair-cases/purchase-orders/PurchaseOrderFolderSection.tsx
src/lib/db/queries/domestic-orders.integration.test.ts
src/lib/db/queries/domestic-orders.ts
src/lib/db/queries/repair-case-quote-numbers.ts
src/lib/server/services/complete-domestic-order.ts
src/lib/storage/purchase-order-archive-source.test.ts
src/lib/storage/purchase-order-archive.test.ts
src/lib/storage/purchase-order-archive.ts
'
AS_CHANGED_SRC_WANT=12
# 🔴 src/ 에 **새로 생긴 파일이 0개**여야 한다. 55번은 다섯이었다.
AS_BORN_SRC_WANT=0
# 🔵 저장소 뿌리에 생긴 **설명 HTML 하나.**
#    🔴 **도구 이미지에는 안 담기고 앱 이미지에는 담긴다**(머리말 ⑨). 그래서
#       앱 이미지 안 검사가 뿌리의 .html 수를 **18 → 19** 로 센다.
AS_BORN_ROOT_WANT=1
# 🔴 [실측] 2026-11-11 — git -c core.quotePath=false ls-tree --name-only <ref> -- .
#    🔵 한글 파일명이라 **quotePath 를 꺼야** 센다. 안 끄면 git 이 "\354…" 로
#       따옴표를 둘러 내보내어 '.html$' 가 안 맞고 **조용히 0** 이 나온다.
AS_ROOT_HTML_WAS=18
AS_ROOT_HTML_NOW=19

# ══ 🔴 「이번 판인가」를 글자로 가르는 표식 다섯 ═══════════════════════
#   🔴 전부 **기준판에 0번 · 지금 판에 1번 이상**이다(2026-11-11 실측).
#      이름은 모두 ASCII 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
#   형식: 글자|파일
#   🔴 마지막 줄이 **마지막 커밋(4c7eb9fa)을 가른다** — 주석만 고친 커밋이라
#      앱 번들로는 못 가르고 **도구 이미지에서만** 갈린다.
AS_MARKS='
listRepairCaseIdsWithOrderIssuedDate|src/lib/db/queries/domestic-orders.ts
no-equipment-key|src/lib/storage/purchase-order-archive.ts
no-equipment-key|src/app/api/repair-cases/[id]/purchase-order-folder/entries/route.ts
PURCHASE_ORDER_FOLDER_SECTION_NO_EQUIPMENT_KEY_TEXT|src/components/repair-cases/purchase-orders/PurchaseOrderFolderSection.tsx
listRepairCaseIdsWithOrderIssuedDate|src/lib/db/queries/repair-case-quote-numbers.ts
'
AS_MARKS_WANT=5

# 🔴 **구운 앱 이미지 안에서 쓸 표식.** 기준판 src/ 에 **0파일** · 지금 판에 8파일이다.
#    🔵 번들에 남는 까닭: 응답 본문에 실려 나가는 **글자 리터럴**이라 이름이 안 바뀐다.
#       개발 PC 의 .next/standalone/.next/server 에서 **4 파일**로 쟀다(2026-11-11).
BUILD_MARK=no-equipment-key
# 🔵 **뒷걸음 방지** — 쉰두째가 올린 글자다. 이번 판이 만든 것이 아니다.
#    기준판에도 지금 판에도 있어야 한다(개발 PC 번들에서 5 파일).
KEEP_MARK=due_date_row_order
# 🔵 ⚠️ 로만 세는 보조 표식 — **식별자**라 번들러가 이름을 바꿀 수 있다.
SOFT_MARK=listRepairCaseIdsWithOrderIssuedDate

# 🔴 **도구 셋이 아직 읽기만 하는가** — 54번이 올린 그 셋이다. 부르는 꼴로 센다.
#    🔴 '--apply' 글자로 재지 않는다 — check-delivered-date-sync.ts 의 **주석**에
#       그 낱말이 1번 나와서, 그렇게 재면 멀쩡한 도구가 ✗ 가 된다.
#    🔵 이번 판이 만든 도구는 **없다.** 그래도 계속 재는 까닭은 「한 번 열리면
#       아무도 안 닫는다」이다.
RO_WRITE_RE='\.insert\(|\.update\(|\.delete\('
RO_TOOLS='
scripts/check-due-date-overdue.ts
scripts/check-delivered-date-sync.ts
scripts/lib/delivered-date-sync-survey.ts
'
RO_TOOLS_WANT=3
RO_TEST=scripts/check-tools-read-only-source.test.ts

# 🔴 PO 쪽에서 **모르는 거절 코드** — 53번에서 넘어온 것이다. 고치지 않고 세어서 알린다.
PO_GATEWAY=src/lib/server/as-gateway.ts
PO_MISSING_CODE=APPROVAL_REQUIRED
PO_MUT=src/lib/db/mutations/domestic-orders.ts

# ══ 🔴 양식 파일 — 이름|바이트|md5 ════════════════════════════════════
#   🔴 **이번 판에도 올릴 양식이 없다.** 열하나가 전부 55번이 적어 둔 값 그대로여야 한다
#      (2026-11-11 재측정 — 바이트도 md5 도 열하나 전부 같았다).
#   🔴 **경로는 여기 없다.** 이름과 바이트와 md5 뿐이다.
TPLS='
QUOTE_TEMPLATE_PATH|내자견적서.xlsx|85942|981edf1f1d4a1b4bf2747167c41149d5
OH_QUOTE_TEMPLATE_PATH|제너레이터 OH 견적서.xlsx|62101|4ef6d9dc75f797efb7088b43e9b4c3f9
MATCHER_QUOTE_TEMPLATE_PATH|매쳐 내자 견적서.xlsx|40079|a9f1f7e75e2ac718d86c288efec41d43
MATCHER_OH_QUOTE_TEMPLATE_PATH|매쳐 OH 견적서.xlsx|40664|fc4ee94678b99e5c7b60ca7d1fd94c57
CABLE_QUOTE_TEMPLATE_PATH|케이블 견적서.xlsx|50996|5450deb6182ccf4c76c2c7ea14b143d8
REPAIR_REPORT_TEMPLATE_PATH|수리보고서.xlsx|190710|403b642d7c700a118ee515e20e4d659e
INSPECTION_REPORT_TEMPLATE_PATH|검사보고서.xlsx|190589|f7dd2fe0dbf03e6a44fa48a00ee4413e
MATCHER_REPAIR_REPORT_TEMPLATE_PATH|수리보고서_매쳐.xlsx|191911|ab25c06be1799952e593c2eef810885e
MATCHER_INSPECTION_REPORT_TEMPLATE_PATH|검사보고서_매쳐.xlsx|191929|5701e075c3aac71f63d29fe28ed68e0f
GENERATOR_REPAIR_REPORT_TEMPLATE_PATH|수리보고서_제너레이터.xlsx|190340|f3b2c76d359c8decd33c01d8b4b0235b
GENERATOR_INSPECTION_REPORT_TEMPLATE_PATH|검사보고서_제너레이터.xlsx|190507|ef7edda07812f937381f82819fc79d22
'
TPL_COUNT_WANT=11

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-53"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

ASDIR="$DEV/RF_Service_System"
AUTHDIR="$DEV/dss-auth"
PODIR="$DEV/dss-po"
COREDIR="$ASDIR/vendor/dss-core"

printf '%s\n' "쉰세째 배포 · 이미지 굽기 (파일 번호 57)   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  🔵 회차(쉰세째)와 파일 번호(57)가 어긋나는 것은 이 저장소에서 원래 그렇다 — 55번이 쉰두째였다."
printf '%s\n' "  🔵 56번은 2026-11-11 의 **양식 전용**(56-stage.sh · 56-templates.sh)이라 건너뛴다."
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  저장소 뿌리: $DEV"
printf '%s\n' "  tar 둘을 둘 자리: $OUT"
printf '%s\n' "  굽는 것: $AS_APP_TAG · $AS_TOOLS_TAG  (저장소 **하나** · 이미지 **둘**)"
printf '%s\n' "  올릴 HEAD: A/S $AS_HEAD_SHORT (기준 $AS_BASE 이후 커밋 4 · 파일 13)"
printf '%s\n' "  🔵 **마이그레이션 0건** — 저장소도 운영 볼륨도 $AS_SQL_WANT 그대로다 (4절)"
printf '%s\n' "     🔵 **묶음(as-migrations.tar.gz)을 안 만들고 안 보낸다.** 55번과 정반대다."
printf '%s\n' "  🔵 공용 스키마 vendor/dss-core 가 **안 움직였다** — ${AS_CORE_PIN:0:7} 그대로 (3절)"
printf '%s\n' "  🔴 도구를 굽는 까닭은 **Dockerfile 69줄이 src/ 를 통째로 담기 때문**이다 (5절-ㄱ)"
printf '%s\n' "     🔵 npm 명령은 안 늘었고($AS_NPM_WAS → $AS_NPM_NOW) 도구 닫힘도 **0개** 바뀌었다."
printf '%s\n' "  🔵 포털(dss-auth)은 **안 굽는다** — HEAD 가 53번이 구운 $AUTH_BASE 그대로다(2절)"
printf '%s\n' "  🔵 PO 도 **안 굽는다** — HEAD 가 기준 $PO_BASE 그대로다(2절)"
printf '%s\n' "  🔵 양식은 **0장** — 열하나가 55번 값 그대로다(8절)"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 1. 도커가 도는가 ──────────────────────────────────────────────────
printf '\n== 1. 도커\n'
if docker version --format '{{.Server.Version}}' >/dev/null 2>&1; then
  ok "도커가 돈다 (서버 $(docker version --format '{{.Server.Version}}' 2>/dev/null))"
else
  bad "도커가 안 돈다 — Docker Desktop 을 켜세요"
fi

# ── 2. 저장소 하나 (이미지 둘) ───────────────────────────────────────
printf '\n== 2. 저장소 하나 (이미지 둘)\n'
printf '%s\n' "🔴 미커밋·미푸시가 있으면 구운 이미지를 나중에 재현하지 못한다."
printf '%s\n' "🔴 **안 받은 것도 센다** — 낡은 코드를 굽고도 모른다."
printf '%s\n' "$SITES" | while IFS='|' read -r KEY REPO TAG BASE TGT WANTMIG WANTN PREVSZ PREVTAR STRICT; do
  [ -n "${KEY:-}" ] || continue
  case "$KEY" in (astools) continue ;; esac   # 🔵 같은 저장소다. 위에서 이미 쟀다.
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
      printf '%s\n' "         57-deploy.sh 꼬리말의 「볼 곳」과 5절의 파일 목록이다 — 사람이 보세요."
      git -C "$DIR" log --oneline "$BASE..HEAD" 2>/dev/null | head -12 | sed 's/^/      /'
    fi
    # 🔴 「0 이면 통과」가 아니다. 적어 둔 수와 **똑같아야** 한다.
    #    🔵 이번 판은 그 수가 0 이다 — **마이그레이션이 0건이라는 말의 근거 하나**다.
    if [ "${m:-x}" = "$WANTMIG" ]; then
      printf '  ✓ %s drizzle/ 에서 달라진 파일 %s개 — 적어 둔 그대로 (**마이그레이션 0건**의 근거 ①)\n' "$REPO" "$m"
    else
      printf '  ✗ %s drizzle/ 에서 달라진 파일 %s개 — **%s개를 기대했다**. 멈추고 알릴 것\n' "$REPO" "${m:-?}" "$WANTMIG"
      printf '%s\n' "      🔴 늘었다면 **이 배포는 묶음을 안 보낸다는 전제로 쓰였다** — 57-deploy.sh 에는"
      printf '%s\n' "         --migrate 모드가 아예 없다. 멈추고 알리세요."
      git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | head -8 | sed 's/^/      /'
    fi
  else
    printf '  ✗ %s — 기준 SHA %s 가 조상이 아니다 (표가 낡았거나 가지가 갈렸다)\n' "$REPO" "$BASE"
  fi
  printf '    지금 HEAD: %s\n' "$(git -C "$DIR" log -1 --format='%h %s' 2>/dev/null)"
done

# 🔴 위 while 이 파이프라인 안이라 **셈이 안 넘어온다.** 다시 세어 FAIL 에 싣는다.
REPO_BAD=0; REPO_SEEN=0
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}
  rest=${rest#*|}; BASE=${rest%%|*}; rest=${rest#*|}; TGT=${rest%%|*}
  rest=${rest#*|}; WANTMIG=${rest%%|*}
  case "$KEY" in (astools) continue ;; esac   # 🔵 이미 셌다.
  REPO_SEEN=$((REPO_SEEN+1))
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
# 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다 — 저장소 **하나**를 봤는가.
if [ "$REPO_SEEN" = "1" ]; then ok "저장소 하나를 봤다 (표본이 비지 않았다 — 이번 판은 A/S 뿐이다)"
else bad "저장소를 ${REPO_SEEN}개 봤다 — 하나를 기대했다. SITES 표가 깨졌다"; fi
if [ "$REPO_BAD" = "0" ]; then ok "A/S 가 깨끗하고 drizzle 변경 수가 적어 둔 그대로다 (0)"
else bad "저장소 검사에서 어긋난 것 ${REPO_BAD}가지 — 위 ✗ 를 보세요"; doubt; fi

# 🔴 **HEAD 가 정말 그 커밋인가** — 짧은 SHA 만 보면 다른 커밋을 구울 길이 있다.
ASHEAD=$(git -C "$ASDIR" rev-parse HEAD 2>/dev/null)
say "A/S HEAD 전체: ${ASHEAD:-못 읽음}"
if [ "${ASHEAD:-}" = "$AS_HEAD_FULL" ]; then
  ok "A/S HEAD 가 적어 둔 그 커밋이다 ($AS_HEAD_SHORT — 지시서의 올릴 HEAD 와 같다)"
else
  bad "🔴 A/S HEAD 가 ${ASHEAD:-못 읽음} 다 — $AS_HEAD_FULL 을 기대했다. **다른 나무를 구우려 한다**"
  doubt
fi

# 🔴 **안 굽는 아홉도 재 둔다** — 「이번 범위에 커밋이 없다」를 짐작으로 적지 않는다.
#    🔵 ✗ 가 나도 **이 배포를 막지 않는다**(⚠️ 로만 센다).
printf '\n  ── 안 굽는 아홉 (HEAD 가 기준 SHA 그대로여야 한다)\n'
IDLE='
dss-auth|f87bf7d
dss-inventory|e0d84e8
dss-board|7d4f390
dss-leave|f568fc0
njlee|a234878
dss-improvements|38fc0ef
dss-trouble|c3da85d
dss-approvals|8ab36fd
dss-po|9c1b2ef
'
IDLE_WANT=9
IDLE_SEEN=0
for row in $(printf '%s\n' "$IDLE" | tr -d ' ' | grep -v '^$'); do
  R=${row%%|*}; B=${row#*|}
  IDLE_SEEN=$((IDLE_SEEN+1))
  DIR="$DEV/$R"
  if [ ! -d "$DIR/.git" ] && [ ! -f "$DIR/.git" ]; then
    note "$R — 저장소가 여기 없다 ($DIR). 못 쟀으니 사람이 보세요"; continue
  fi
  h=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
  c=$(git -C "$DIR" rev-list --count "$B..HEAD" 2>/dev/null)
  if [ "${c:-x}" = "0" ]; then
    printf '      %-18s 기준 %s · HEAD %s · 이후 커밋 0\n' "$R" "$B" "${h:-?}"
  else
    note "$R — 기준 $B 이후 커밋 ${c:-못 쟀다}개다. **다음 판의 범위가 늘었다.** 사람이 보세요"
    git -C "$DIR" log --oneline "$B..HEAD" 2>/dev/null | head -5 | sed 's/^/      /'
  fi
done
if [ "$IDLE_SEEN" = "$IDLE_WANT" ]; then ok "안 굽는 아홉을 다 봤다 (표본이 비지 않았다)"
else bad "안 굽는 저장소를 ${IDLE_SEEN}개만 봤다 — ${IDLE_WANT}을 기대했다. IDLE 표가 깨졌다"; fi
# 🔵 55번과 같다 — 포털을 안 굽는 판이므로 IDLE 에 dss-auth 가 **있어야** 한다.
if printf '%s\n' "$IDLE" | tr -d ' ' | grep -q '^dss-auth|'; then
  ok "IDLE 표에 dss-auth 가 있다 (이번 판도 포털을 **안 굽는다**)"
else
  bad "🔴 IDLE 표에 dss-auth 가 없다 — **이번 판은 포털을 안 굽는다**"
  doubt
fi

# ── 3. 🔴 서브모듈 — 이번엔 **dss-core 가 안 움직였다** ──────────────
printf '\n== 3. 서브모듈 (🔵 이번 판에는 dss-core 가 **안 움직였다** — 55번과 반대다)\n'
# 🔴 tr 의 지우기 집합에서 빼기표는 **맨 끝**에 둔다(ASCII 역순이면 죽는다).
pin_of() { git -C "$1" submodule status "$2" 2>/dev/null | awk '{print $1}' | tr -d '+-'; }

check_pin() { # 1 저장소 2 서브모듈경로 3 기대 4 사람이 부르는 이름
  local got
  got=$(pin_of "$1" "$2")
  if [ "${got:-}" = "$3" ]; then
    ok "$4 $2 포인터가 ${3:0:7} 다 (적어 둔 그대로)"
  elif [ -n "${got:-}" ]; then
    bad "$4 $2 포인터가 ${got:0:7} 다 — **${3:0:7} 을 기대했다.** 멈추고 알릴 것"
    doubt
  else
    bad "$4 $2 포인터를 못 읽었다 — 서브모듈이 아예 없다"
  fi
}
check_pin "$ASDIR" vendor/dss-core "$AS_CORE_PIN" "A/S"
check_pin "$ASDIR" vendor/dss-ui   "$UI_PIN"      "A/S"

# 🔴 **정말 안 움직였는가** — 기준판의 포인터가 **지금과 같아야** 「안 움직였다」가 선다.
#    🔵 55번은 여기가 반대였다(기준판이 옛 값이어야 「움직였다」가 섰다).
#    🔴 55번 글을 그대로 베끼면 **멀쩡한 판이 ✗** 가 난다 — 뒤집은 자리다.
WASPIN=$(git -C "$ASDIR" ls-tree "$AS_BASE" vendor/dss-core 2>/dev/null | awk '{print $3}')
say "기준판 $AS_BASE 의 vendor/dss-core = ${WASPIN:0:7}  (지금 ${AS_CORE_PIN:0:7})"
if [ "${WASPIN:-}" = "$AS_CORE_PIN" ]; then
  ok "vendor/dss-core 가 기준판과 **같다** — 이번 판에 안 움직였다 (적어 둔 그대로)"
  say "🔵 그래서 **공용 스키마를 재는 절이 없다** — 55번의 3-ㄴ 절은 이 판에 쓸 일이 없다."
  say "   🔴 다음 판에서 또 움직이면 55-build.sh 의 3-ㄴ 절(628~676줄)을 되살리세요."
elif [ -z "${WASPIN:-}" ]; then
  unk "기준판의 vendor/dss-core 포인터" "git ls-tree 가 아무것도 안 돌려줬다 — 기준 SHA 를 보세요"
else
  bad "🔴 기준판의 vendor/dss-core 가 ${WASPIN:0:7} 다 — **${AS_CORE_PIN:0:7} 을 기대했다**(안 움직였어야 한다)"
  say "🔴 움직였다면 **도구가 읽는 스키마가 바뀐 것**이다 — 55-build.sh 의 3-ㄴ 절을 되살려야 한다."
  doubt
fi
# 🔵 dss-ui 도 안 움직였다.
WASUI=$(git -C "$ASDIR" ls-tree "$AS_BASE" vendor/dss-ui 2>/dev/null | awk '{print $3}')
say "기준판 $AS_BASE 의 vendor/dss-ui = ${WASUI:0:7}  (지금 ${UI_PIN:0:7})"
if [ "${WASUI:-}" = "$UI_PIN" ]; then
  ok "vendor/dss-ui 가 기준판과 **같다** — 이번 판에 안 움직였다 (적어 둔 그대로)"
elif [ -z "${WASUI:-}" ]; then
  unk "기준판의 vendor/dss-ui 포인터" "git ls-tree 가 아무것도 안 돌려줬다"
else
  bad "🔴 vendor/dss-ui 가 기준판 ${WASUI:0:7} → 지금 ${UI_PIN:0:7} 로 움직였다 — 안 움직인다고 적어 두었다"
  doubt
fi
# 🔴 서브모듈 **안**이 깨끗한가 — 미커밋이 있으면 나중에 재현이 안 된다.
if [ -d "$COREDIR/.git" ] || [ -f "$COREDIR/.git" ]; then
  CORE_DIRTY=$(git -C "$COREDIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${CORE_DIRTY:-1}" = "0" ]; then ok "vendor/dss-core 에 미커밋 0"
  else bad "vendor/dss-core 에 미커밋 ${CORE_DIRTY}줄 — 구운 이미지를 나중에 재현하지 못한다"; fi
else
  unk "vendor/dss-core 안" "그 폴더가 git 저장소가 아니다 — git submodule update --init 을 먼저"
fi

# 🔵 PO 는 **이번에 안 굽는다.** 핀이 어긋나도 이 배포를 막을 일이 아니다 — ⚠️ 로만 센다.
printf '\n'
for pair in "vendor/dss-core $PO_CORE_PIN" "vendor/dss-ui $UI_PIN"; do
  set -- $pair
  got=$(pin_of "$PODIR" "$1")
  if [ "${got:-}" = "$2" ]; then say "🔵 PO $1 포인터 ${2:0:7} — 적어 둔 그대로 (이번에 안 굽는다)"
  else note "PO $1 포인터가 ${got:0:7} 다 — ${2:0:7} 을 적어 두었다. **이번 배포는 안 막는다**(PO 를 안 굽는다)"; fi
done
say "🔴 A/S dss-core ${AS_CORE_PIN:0:7} · PO dss-core ${PO_CORE_PIN:0:7} — **서로 다른 것이 맞다.**"
say "   🔵 **이번 판은 그 차이를 더 벌리지 않는다** — 공용 스키마를 한 글자도 안 건드렸다."
say "   🔴 쉰두째에서 벌어진 차이(칸 넷)는 그대로다. PO 를 여는 날 함께 이식한다."
# 🔴 빈 폴더가 아닌가 — 포인터는 맞는데 안이 비어 있는 경우가 실제로 있다.
check_not_empty() { # 1 서브모듈 폴더 2 사람이 부르는 이름
  if [ -s "$1/package.json" ]; then ok "$2 에 파일이 있다 (빈 폴더가 아니다)"
  else bad "$2 가 **빈 폴더**다 — git submodule update --init 을 먼저"; fi
}
check_not_empty "$COREDIR"             "A/S-core"
check_not_empty "$ASDIR/vendor/dss-ui" "A/S-ui"

# ── 4. 🔴 drizzle/ — **127 그대로. 마이그레이션 0건** ────────────────
#   🔴 55번과 가장 크게 다른 절이다. 거기는 125 → 127 이었고 묶음이 필수였다.
#   🔵 여기서 재는 것은 **「올릴 것이 없다」를 값으로 확인하는 일**이다 —
#      「0건이니까 안 본다」가 아니다. 그렇게 두면 **아무도 안 보는 자리**가 된다.
printf '\n== 4. drizzle/ — A/S %s 장 (운영 볼륨도 %s · **올릴 것 0건**)\n' "$AS_SQL_WANT" "$AS_PROD_SQL_NOW"
AS_COUNTS=$(count_drizzle "$ASDIR"); AS_SQL=${AS_COUNTS%% *}; AS_JRN=${AS_COUNTS##* }
say "RF_Service_System/drizzle — .sql ${AS_SQL}장 · meta/_journal.json 의 idx ${AS_JRN}개"
if [ "${AS_SQL:-0}" = "$AS_SQL_WANT" ] && [ "${AS_JRN:-0}" = "$AS_SQL_WANT" ]; then
  ok "${AS_SQL_WANT}장이다 — 🔵 55번이 올린 $AS_PROD_SQL_NOW **그대로**다 (앞뒤가 같다)"
else
  bad "drizzle 이 .sql ${AS_SQL:-?} · idx ${AS_JRN:-?} 다 — **${AS_SQL_WANT} 여야 한다.** 멈추고 알릴 것"
  doubt
fi
# 🔴 **.sql 과 idx 가 서로 어긋나면** 목록에 없는 파일이 생긴 것이다 — 그쪽이 더 위험하다.
if [ "${AS_SQL:-0}" != "${AS_JRN:-1}" ]; then
  bad "🔴 .sql ${AS_SQL:-?}장과 idx ${AS_JRN:-?}개가 **다르다** — 목록에 없는 .sql 은 **안 돈다**"
  doubt
else
  ok ".sql 수와 _journal.json 의 idx 수가 같다 (목록에서 빠진 .sql 이 없다)"
fi
# 🔵 두 상수가 이어지는 번호인가 — 한쪽만 고치면 아래 검사가 조용히 빗나간다.
#    🔴 10# 을 붙여 **10진수로 강제**한다. 안 붙이면 0126 이 8진수로 읽힌다.
if [ "$(printf '%04d' "$((10#$AS_LAST_MIG + 1))")" = "$AS_NEXT_MIG" ]; then
  ok "번호 둘이 이어진다 ($AS_LAST_MIG → $AS_NEXT_MIG)"
else
  bad "🔴 $AS_LAST_MIG · $AS_NEXT_MIG 가 안 이어진다 — 한쪽만 고쳤다"
fi
# 🔴 **기준판과 지금의 .sql 수가 같은가** — 「0건」의 둘째 근거다.
#    🔵 2절이 git diff 로 쟀고, 여기는 **나무 양쪽을 따로 세어** 맞댄다. 길이 둘이다.
WASSQL=$(git -C "$ASDIR" ls-tree --name-only "$AS_BASE" drizzle/ 2>/dev/null | grep -c '[.]sql$' || true)
say "기준판 $AS_BASE 의 drizzle/*.sql ${WASSQL:-못 쟀다}장 (지금 ${AS_SQL:-?}장)"
if [ "${WASSQL:-x}" = "${AS_SQL:-y}" ]; then
  ok "기준판과 지금의 .sql 수가 같다 — **이번 범위에 새 마이그레이션이 0건이다**(근거 ②)"
else
  bad "🔴 기준판 ${WASSQL:-?}장 · 지금 ${AS_SQL:-?}장 — **마이그레이션이 생겼다.** 멈추고 알릴 것"
  say "🔴 이 배포에는 **묶음도 --migrate 모드도 없다.** 생겼다면 55번 판을 되살려야 한다."
  doubt
fi
if [ -s "$ASDIR/drizzle/$AS_LAST_MIG_FILE" ]; then
  ok "drizzle/$AS_LAST_MIG_FILE 이 있다 (55번이 올린 마지막 — 이번 판의 마지막이기도 하다)"
else
  bad "🔴 drizzle/$AS_LAST_MIG_FILE 이 **없다**"
  ls -1 "$ASDIR/drizzle/${AS_LAST_MIG}_"*.sql 2>/dev/null | sed 's/^/      /'
  doubt
fi
if ls -1 "$ASDIR/drizzle/${AS_NEXT_MIG}_"*.sql >/dev/null 2>&1; then
  bad "🔴 drizzle 에 $AS_NEXT_MIG 번이 **생겼다** — 이 배포는 **$AS_LAST_MIG 까지**를 전제로 쓰였다"
  say "🔴 57-deploy.sh 에는 --migrate 모드가 **없다.** 멈추고 알릴 것."
  doubt
else
  ok "$AS_NEXT_MIG 번이 없다 (마지막이 $AS_LAST_MIG — **올릴 것이 0건**이 맞다)"
fi
# 🔵 48·53·55번이 올린 여섯이 그대로 있는가 — 묶음을 안 보내도 **나무는 온전해야** 한다.
KEEPMIG_SEEN=0; KEEPMIG_OK=0
for t in $AS_KEEP_MIGS; do
  KEEPMIG_SEEN=$((KEEPMIG_SEEN+1))
  if ls -1 "$ASDIR/drizzle/${t}_"*.sql >/dev/null 2>&1 && [ -s "$ASDIR/drizzle/meta/${t}_snapshot.json" ]; then
    KEEPMIG_OK=$((KEEPMIG_OK+1))
  else
    bad "$t 의 .sql 또는 스냅샷이 없다 — 저장소의 drizzle/ 이 온전하지 않다"
  fi
done
if [ "$KEEPMIG_SEEN" = "$AS_KEEP_MIGS_WANT" ] && [ "$KEEPMIG_OK" = "$AS_KEEP_MIGS_WANT" ]; then
  ok "0121~0126 여섯이 .sql 과 스냅샷까지 그대로 있다"
else
  bad "본 것 ${KEEPMIG_SEEN} · 온전한 것 ${KEEPMIG_OK} 다 — ${AS_KEEP_MIGS_WANT}/${AS_KEEP_MIGS_WANT} 을 기대했다"
fi
# 🔴 「삼켜진 0」을 여기서 가른다 — PO 에 drizzle/ 이 없는 것이 맞다.
if [ -d "$PODIR/drizzle" ]; then
  bad "🔴 dss-po 에 drizzle/ 폴더가 **생겼다** — 2026-09-28 부터 없던 것이다. 사람이 보세요"
  doubt
else
  ok "dss-po 에 drizzle/ 폴더가 없다 (없는 것이 맞다 — 스키마의 주인은 A/S 하나뿐이다)"
fi
printf '%s\n' "    🔵 **묶음(as-migrations.tar.gz)은 안 만든다.** 올릴 것이 0건이기 때문이다."
printf '%s\n' "       🔴 그래도 **운영 볼륨이 127 인지는 57-deploy.sh 가 잰다** — 마이그레이션은"
printf '%s\n' "          이미지 안이 아니라 **볼륨에서** 돈다. 이미지만 세면 0건으로 조용히 끝난다."
printf '%s\n' "       🔵 보험이 필요하면 이미 있다: _images-52/as-migrations.tar.gz (127장 ·"
printf '%s\n' "          md5 ddec2e73f6ef979b6983dd929494eab9). 55-deploy.sh --migrate 가 그것을 푼다."

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 담는 길 · 도구 판정 · 소스가 새 코드를 담고 있나 ────────────
# ══════════════════════════════════════════════════════════════════════
#  🔴 .dockerignore 나 Dockerfile 이 어긋나면 이미지는 멀쩡히 구워지고 **바뀐
#     코드만 조용히 빠진다.** 그래서 담는 길부터 센다.
#  🔴 **이번 판은 이 절이 굽는 까닭 전부를 쥐고 있다** — ㄱ·ㄴ 이 안 걸리고
#     ㅁ(담기는 것) 하나만 걸린다.
printf '\n== 5. 담는 길 · 도구 판정 · 소스가 새 코드를 담고 있나\n'
# 🔴 기준 SHA 가 표와 이 절에 **두 벌로** 적혀 있다. 한쪽만 고치면 조용히 어긋난다.
row_f() { printf '%s\n' "$SITES" | tr -d ' ' | grep "^$1|" | head -1 | cut -d'|' -f"$2"; }
AS_ROW_BASE=$(row_f as 4)
if [ "${AS_ROW_BASE:-}" = "$AS_BASE" ]; then ok "A/S 기준 SHA 가 SITES 표와 이 절에서 같다 ($AS_BASE)"
else bad "A/S 기준 SHA 가 어긋난다 — 표는 ${AS_ROW_BASE:-못 읽음} · 이 절은 $AS_BASE"; fi
# 🔴 포털·PO 기준 SHA 는 SITES 에 없다(안 굽는다). IDLE 표와 맞댄다.
for pair in "dss-auth $AUTH_BASE" "dss-po $PO_BASE"; do
  set -- $pair
  IB=$(printf '%s\n' "$IDLE" | tr -d ' ' | grep "^$1|" | head -1 | cut -d'|' -f2)
  if [ "${IB:-}" = "$2" ]; then ok "$1 기준 SHA 가 IDLE 표와 이 절에서 같다 ($2)"
  else bad "$1 기준 SHA 가 어긋난다 — IDLE 표는 ${IB:-못 읽음} · 이 절은 $2"; fi
done
# 🔵 도구 줄이 정말 --target tools 인지. 여기가 '-' 면 runner 가 구워지고,
#    그 이미지는 **오류 없이** 쓸모가 없다.
t=$(row_f astools 5); g=$(row_f astools 3)
if [ "${t:-}" = "tools" ] && [ "${g:-}" = "$AS_TOOLS_TAG" ]; then
  ok "SITES 표의 astools 줄이 $AS_TOOLS_TAG · --target tools 다"
else
  bad "SITES 표의 astools 줄이 어긋난다 — 태그 ${g:-없음} · target ${t:-없음} (기대 $AS_TOOLS_TAG · tools)"
fi

# ── ㄱ) 🔴 A/S Dockerfile 이 담는 길 — **굽는 까닭이 여기 있다** ─────
#   🔴 A/S 의 tools 는 drizzle/ 을 **안 담는다**(볼륨이다).
#   🔴 **그리고 src/ 를 통째로 담는다** — 이번에 바뀐 12개가 들어가는 길이다.
check_copy() { # 1 Dockerfile 2 정규식 3 있어야 하나(yes/no) 4 사람이 읽을 말
  if grep -qE "$2" "$1" 2>/dev/null; then
    if [ "$3" = yes ]; then ok "$4"; else bad "🔴 $4"; fi
  else
    if [ "$3" = yes ]; then bad "🔴 $4"; else ok "$4"; fi
  fi
}
printf '\n  ── A/S Dockerfile — **tools 스테이지가 무엇을 담는가** (굽는 판정의 근거)\n'
if grep -q '^FROM .* AS tools' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "A/S 에 tools 스테이지가 있다 (--target tools 가 선다)"
else
  bad "A/S 에 tools 스테이지가 없다 — --target tools 가 실패한다"
fi
# 🔴 **COPY 줄을 통째로 찍는다** — 「담는다/안 담는다」를 사람이 눈으로 본다.
printf '%s\n' "      ── tools 스테이지의 COPY 줄 (파일에서 그대로 읽었다)"
awk '/^FROM .* AS tools/{inb=1} inb && /^FROM .* AS runner/{inb=0} inb && /^COPY /{print "      " NR "줄  " $0}' "$ASDIR/Dockerfile"
check_copy "$ASDIR/Dockerfile" '^COPY .*scripts \./scripts'   yes "A/S tools 가 scripts/ 를 담는다"
check_copy "$ASDIR/Dockerfile" '^COPY .*package\.json'        yes "A/S tools 가 package.json·tsconfig.json 을 담는다"
check_copy "$ASDIR/Dockerfile" '^COPY .*src \./src'           yes "🔴 A/S tools 가 **src/ 를 통째로 담는다** — 이번에 바뀐 12개가 전부 여기다 (**굽는 까닭**)"
check_copy "$ASDIR/Dockerfile" '^COPY .*vendor \./vendor'     yes "A/S tools 가 vendor/ 를 담는다 (🔵 이번 판에는 그 안이 안 바뀌었다)"
check_copy "$ASDIR/Dockerfile" '^COPY .*drizzle \./drizzle'   no  "A/S tools 는 drizzle/ 을 **안 담는다** (🔵 그래서 마이그레이션은 볼륨에서 돈다)"
# 🔴 그 COPY 줄이 **tools 스테이지 안**에 있는가 — 줄번호로 가른다. 바깥에 있으면
#    위 grep 은 통과하는데 도구에는 안 담긴다.
LT=$(grep -n '^FROM .* AS tools'  "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
LR=$(grep -n '^FROM .* AS runner' "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
LS=$(grep -n '^COPY .*src \./src' "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
say "tools ${LT:-?}줄 · 'COPY … src ./src' ${LS:-?}줄 · runner ${LR:-?}줄"
if isnum "${LT:-}" && isnum "${LS:-}" && isnum "${LR:-}" && [ "$LT" -lt "$LS" ] && [ "$LS" -lt "$LR" ]; then
  ok "src/ 를 담는 COPY 가 **tools 스테이지 안**에 있다 (${LS}줄 — 지시서가 적은 69줄 자리다)"
else
  bad "🔴 'COPY … src ./src' 가 tools 스테이지 안이 아니다 (tools ${LT:-?} · COPY ${LS:-?} · runner ${LR:-?})"
  say "🔴 그러면 **도구 이미지를 구울 까닭이 사라진다** — 판정을 다시 해야 한다. 멈추고 알릴 것."
  doubt
fi
# 🔴 tools 가 runner **앞**이어야 한다 — 마지막 스테이지가 docker build 의 기본 대상이다.
if isnum "${LT:-}" && isnum "${LR:-}" && [ "$LT" -lt "$LR" ]; then
  ok "A/S Dockerfile 이 tools(${LT}줄) 를 runner(${LR}줄) **앞**에 둔다 (--target 없이 구우면 runner 가 나온다)"
else
  bad "🔴 A/S Dockerfile 의 차례가 tools ${LT:-?} · runner ${LR:-?} 다 — **--target 없이 구운 것이 도구가 된다**"
  doubt
fi

# ── ㄴ) .dockerignore ───────────────────────────────────────────────
printf '\n'
DIG="$ASDIR/.dockerignore"
if [ ! -s "$DIG" ]; then
  bad "A/S 에 .dockerignore 가 없거나 비었다 — .env 와 .git 이 이미지로 따라 들어간다"
else
  if grep -qE '^scripts/?$' "$DIG" 2>/dev/null; then
    bad "A/S 의 .dockerignore 가 scripts/ 를 막는다 — 도구가 통째로 빠진다"
  else
    ok "A/S 의 .dockerignore 가 scripts/ 를 막지 않는다"
  fi
  if grep -qE '^src/?$' "$DIG" 2>/dev/null; then
    bad "🔴 A/S 의 .dockerignore 가 src/ 를 막는다 — **이번에 고친 12개가 통째로 빠진다**"
  else
    ok "A/S 의 .dockerignore 가 src/ 를 막지 않는다 (이번에 고친 12개가 들어간다)"
  fi
  if grep -qE '^vendor/?$' "$DIG" 2>/dev/null; then
    bad "🔴 A/S 의 .dockerignore 가 vendor/ 를 막는다 — 공용 스키마가 빠진다"
  else
    ok "A/S 의 .dockerignore 가 vendor/ 를 막지 않는다 (공용 스키마가 들어간다)"
  fi
  if grep -qE '^\.next/?$' "$DIG" 2>/dev/null; then
    ok "A/S 의 .dockerignore 가 .next 를 막는다 (개발 서버를 띄워 둔 채로 구워도 된다)"
  else
    bad "A/S 의 .dockerignore 가 .next 를 안 막는다 — 호스트의 .next 가 빌드 문맥에 들어간다"
  fi
fi

# ── ㄷ) 🔵 npm 명령 — **이번 판도 안 늘었다.** 41번 잣대가 안 걸린다 ──
printf '\n  ── npm 명령 (🔵 이번 판도 **안 늘었다** — 굽는 까닭이 아니다)\n'
PL=$(git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | wc -l | tr -d ' ')
say "A/S package.json 의 diff ${PL:-못 쟀다}줄 (적어 둔 값 $AS_PKG_LINES_WANT)"
if [ "${PL:-x}" = "$AS_PKG_LINES_WANT" ]; then
  ok "package.json 이 안 바뀌었다 (0줄) — 🔵 **41번 잣대는 이번 판에 안 걸린다**"
  say "🔴 그렇다고 도구를 안 굽는 것이 아니다 — **ㅁ(담기는 것)** 이 걸린다."
else
  note "package.json 이 ${PL:-?}줄 바뀌었다 — $AS_PKG_LINES_WANT 줄을 적어 두었다. 아래 diff 를 사람이 보세요"
  git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | head -24 | sed 's/^/      /'
fi
NN=$(count_scripts < "$ASDIR/package.json" 2>/dev/null | tr -d ' ')
WW=$(git -C "$ASDIR" show "$AS_BASE:package.json" 2>/dev/null | count_scripts | tr -d ' ')
say "A/S scripts 항목 — 기준 ${WW:-?} → 지금 ${NN:-?} (적어 둔 값 $AS_NPM_WAS → $AS_NPM_NOW)"
if [ "${WW:-x}" = "$AS_NPM_WAS" ] && [ "${NN:-x}" = "$AS_NPM_NOW" ]; then
  ok "명령 수가 적어 둔 그대로다 ($AS_NPM_WAS → $AS_NPM_NOW · 안 늘고 안 줄었다)"
elif isnum "${NN:-}" && isnum "${WW:-}" && [ "${NN:-0}" -lt "${WW:-0}" ]; then
  bad "🔴 명령이 ${WW} 에서 ${NN} 로 **줄었다** — 사라진 명령을 그날 부르면 Missing script 다"
  doubt
else
  note "명령 수가 기준 ${WW:-?} → 지금 ${NN:-?} 다 — $AS_NPM_WAS → $AS_NPM_NOW 를 적어 두었다. 사람이 보세요"
fi
NEWCNT=$(git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | grep -c '^+    "' || true)
say "A/S package.json 에서 **새로 더해진 scripts 줄** ${NEWCNT:-0}개 (기대 $AS_NEW_NPM_WANT)"
if [ "${NEWCNT:-x}" = "$AS_NEW_NPM_WANT" ]; then
  ok "새 npm 명령이 $AS_NEW_NPM_WANT 개다 — 🔵 **이번 판의 목적물은 도구가 아니라 앱 기능**이다"
else
  note "새 명령 줄이 ${NEWCNT:-?}개다 — $AS_NEW_NPM_WANT 을 기대했다. 늘었으면 꼬리말을 고쳐야 한다"
fi
# 🔴 사라지면 안 되는 아홉
printf '\n  ── 사라지면 안 되는 npm 명령 아홉\n'
KEEP_SEEN=0; KEEP_OK=0
for s in $AS_KEEP_NPM; do
  KEEP_SEEN=$((KEEP_SEEN+1))
  now=$(grep -c "\"$s\"" "$ASDIR/package.json" 2>/dev/null || true)
  printf '      %-34s 지금 %s\n' "$s" "${now:-0}"
  if [ "${now:-0}" -ge 1 ] 2>/dev/null; then KEEP_OK=$((KEEP_OK+1)); fi
done
if [ "$KEEP_SEEN" = "$AS_KEEP_NPM_WANT" ]; then ok "지킬 명령 $AS_KEEP_NPM_WANT 개를 다 봤다 (표본이 비지 않았다)"
else bad "명령을 ${KEEP_SEEN}개만 봤다 — $AS_KEEP_NPM_WANT 개를 기대했다. 목록이 깨졌다"; fi
if [ "$KEEP_OK" = "$AS_KEEP_NPM_WANT" ]; then ok "지킬 명령 $AS_KEEP_NPM_WANT 개가 **지금 판에 다 있다** (부르는 날 Missing script 가 안 난다)"
else bad "🔴 지금 판에 있는 명령이 ${KEEP_OK}/$AS_KEEP_NPM_WANT 개다 — **사라진 것이 있다**"; doubt; fi

# ══ 🔴 바뀐 목록을 **한 번만 뽑아 둔다** — pathspec 글롭 함정을 피한다 ══
#   🔴 src/app/(app)/… 과 …/[id]/… 를 git 의 pathspec 으로 물으면 **글롭**으로
#      읽혀 조용히 0줄이 돌아온다. 그래서 목록을 통째로 받아 **grep -Fx** 로 맞댄다.
CHANGED_ALL=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" 2>/dev/null)
CHANGED_SRC=$(printf '%s\n' "$CHANGED_ALL" | grep '^src/' || true)
BORN_ALL=$(git -C "$ASDIR" diff --name-only --diff-filter=A "$AS_BASE..HEAD" 2>/dev/null)
# 🔵 잣대가 살아 있는지 표본으로 본다 — 안 그러면 아래 「0개」가 공짜 통과다.
PROBE_FX=$(printf '%s\n' 'src/app/(app)/repair-cases/[id]/purchase-orders/page.tsx' \
  | grep -Fxc 'src/app/(app)/repair-cases/[id]/purchase-orders/page.tsx' || true)
PROBE_FY=$(printf '%s\n' 'src/app/x/repair-cases/i/purchase-orders/page.tsx' \
  | grep -Fxc 'src/app/(app)/repair-cases/[id]/purchase-orders/page.tsx' || true)
say "표본 — 괄호·대괄호가 든 경로를 글자 그대로 맞대기 ${PROBE_FX:-?}(기대 1) · 글롭으로 풀린 꼴 ${PROBE_FY:-?}(기대 0)"
if [ "${PROBE_FX:-0}" = "1" ] && [ "${PROBE_FY:-1}" = "0" ]; then
  ok "경로 맞대기 잣대가 살아 있다 (괄호·대괄호를 **글자 그대로** 본다)"
else
  bad "🔴 경로 맞대기 잣대가 죽었다 — 아래 수가 전부 못 믿을 값이다. 멈추세요"
  doubt
fi

# ── ㄹ) 🔵 도구 닫힘 — **이번 판에는 하나도 안 바뀌었다**(55번과 반대) ──
#   🔴 55번은 여기가 「1개 이상 바뀌어야 ✓」였다. 그 글을 그대로 베껴 오면
#      **멀쩡한 판이 ✗** 가 난다 — 이번 판의 기대값은 **0** 이다.
#   🔵 그래도 목록을 **지우지 않는다**: 「아직 그 파일들이 저장소에 있는가」와
#      「정말 안 바뀌었는가」를 둘 다 값으로 재야 「안 걸린다」가 근거를 갖는다.
printf '\n  ── A/S 도구 닫힘 (목록 %s개 · 바뀐 것 %s개를 기대 — 🔵 55번과 반대다)\n' "$AS_TOOLS_CALLED_WANT" "$AS_TOOLS_CALLED_CHANGED_WANT"
CL_SEEN=0; CL_HIT=0
while IFS= read -r f; do
  [ -n "${f:-}" ] || continue
  CL_SEEN=$((CL_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 저장소에 없다 — **닫힘 목록이 낡았다.** 닫힘을 다시 재세요"
    continue
  fi
  if printf '%s\n' "$CHANGED_ALL" | grep -Fxq "$f"; then
    CL_HIT=$((CL_HIT+1)); say "🔴 바뀌었다 · 도구가 부른다 — $f"
  else
    say "🔵 안 바뀌었다 — $f"
  fi
done <<CLEOF
$(printf '%s\n' "$AS_TOOLS_CALLED" | grep -v '^[[:space:]]*$')
CLEOF
say "닫힘 목록 ${CL_SEEN}개를 봤고, 그중 바뀐 것 ${CL_HIT}개 (적어 둔 수 $AS_TOOLS_CALLED_CHANGED_WANT)"
if [ "$CL_SEEN" = "$AS_TOOLS_CALLED_WANT" ]; then ok "닫힘 목록 $AS_TOOLS_CALLED_WANT 개를 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
else bad "닫힘 목록을 ${CL_SEEN}개만 봤다 — $AS_TOOLS_CALLED_WANT 개를 기대했다. 목록이 깨졌다"; fi
if [ "${CL_HIT:-x}" = "$AS_TOOLS_CALLED_CHANGED_WANT" ]; then
  ok "도구가 부르는 길에서 바뀐 파일이 ${CL_HIT}개다 — 적어 둔 그대로 (**ㄴ 잣대는 안 걸린다**)"
else
  note "도구가 부르는 길에서 ${CL_HIT:-?}개가 바뀌었다 — $AS_TOOLS_CALLED_CHANGED_WANT 개를 적어 두었다"
  say "🔵 늘어도 **굽는 판정은 안 흔들린다**(ㅁ 때문에 이미 굽는다). 사람이 보세요."
fi
# 🔴 **반대 방향으로도 한 번 더 센다** — 이번에 바뀐 12개를 scripts/ 가 부르는가.
#    🔵 글자로는 하나 걸리는데 그것은 **주석**이다(머리말). 그래서 import 줄로만 센다.
printf '\n  ── 🔴 이번에 바뀐 것을 scripts/ 가 **import 로** 부르는가 (기대 0 · 주석은 안 센다)\n'
IMP_HIT=0
for key in domestic-orders purchase-order-archive repair-case-quote-numbers complete-domestic-order PurchaseOrderFolderSection purchase-order-folder; do
  n=$(grep -rlE "^import .*$key|from \"[^\"]*$key" "$ASDIR/scripts" 2>/dev/null | grep -v '/test-lists/' | wc -l | tr -d ' ')
  printf '      %-30s scripts/ 의 import %s개\n' "$key" "${n:-0}"
  IMP_HIT=$((IMP_HIT + ${n:-0}))
done
say "scripts/ 가 이번 판의 모듈을 import 하는 파일 ${IMP_HIT}개 (기대 0)"
if [ "$IMP_HIT" = "0" ]; then
  ok "도구는 이번에 바뀐 코드를 **부르지 않는다** — 🔵 그래서 도구의 **동작**은 안 바뀐다"
  say "🔴 그래도 굽는다 — **담기는 것이 달라지기 때문**이다(Dockerfile 69줄). 그 둘은 다른 말이다."
else
  note "scripts/ 가 ${IMP_HIT}개 부른다 — 0 을 적어 두었다. 🔵 굽는 판정은 안 흔들린다. 사람이 보세요"
fi

# ── ㅁ) 🔴 **「담기는 것」으로 센다 — 이번 판이 굽는 유일한 까닭** ────
printf '\n  ── 담기는 것으로 세기 (🔴 이번 판이 굽는 **유일한 까닭**)\n'
AS_TOOLS_PATHS="scripts/ src/ package.json drizzle.config.ts tsconfig.json vendor/"
AS_TOOLS_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $AS_TOOLS_PATHS 2>/dev/null | wc -l | tr -d ' ')
AS_ALL_CHANGED=$(printf '%s\n' "$CHANGED_ALL" | grep -c . || true)
say "A/S  tools 가 담는 것 중 달라진 파일 ${AS_TOOLS_CHANGED:-못 쟀다}개 (적어 둔 수 $AS_TOOLS_CHANGED_WANT)"
say "A/S  저장소 전체에서 달라진 파일 ${AS_ALL_CHANGED:-못 쟀다}개 (적어 둔 수 $AS_ALL_CHANGED_WANT)"
if isnum "${AS_TOOLS_CHANGED:-}" && [ "${AS_TOOLS_CHANGED:-0}" -ge 1 ]; then
  ok "🔴 A/S 도구를 구울 까닭이 있다 — 담기는 것 중 달라진 파일 ${AS_TOOLS_CHANGED}개"
else
  bad "🔴 담기는 것 중 달라진 파일이 ${AS_TOOLS_CHANGED:-못 쟀다}개다 — **도구를 구울 까닭이 없다.** 멈추고 알릴 것"
  doubt
fi
# 🔴 **이번 판은 바깥이 1 이고 drizzle/ 이 아니다** — 55번은 5 였고 전부 drizzle/ 이었다.
OUTSIDE=$((${AS_ALL_CHANGED:-0} - ${AS_TOOLS_CHANGED:-0}))
say "A/S  tools 바깥에서 달라진 파일 ${OUTSIDE}개 (적어 둔 수 $AS_OUTSIDE_WANT — **설명 HTML 하나**)"
if [ "${AS_TOOLS_CHANGED:-x}" = "$AS_TOOLS_CHANGED_WANT" ] && [ "${AS_ALL_CHANGED:-x}" = "$AS_ALL_CHANGED_WANT" ]; then
  ok "담기는 것 ${AS_TOOLS_CHANGED_WANT} · 전체 ${AS_ALL_CHANGED_WANT} · 바깥 ${AS_OUTSIDE_WANT} — 적어 둔 그대로"
else
  note "담기는 것 ${AS_TOOLS_CHANGED:-?} · 전체 ${AS_ALL_CHANGED:-?} · 바깥 ${OUTSIDE} 다 — 적어 둔 것은 ${AS_TOOLS_CHANGED_WANT}·${AS_ALL_CHANGED_WANT}·${AS_OUTSIDE_WANT} 다"
  printf '%s\n' "      ── 바깥에서 바뀐 것"
  printf '%s\n' "$CHANGED_ALL" \
    | grep -vE '^(scripts/|src/|package\.json$|drizzle\.config\.ts$|tsconfig\.json$|vendor/)' | head -10 | sed 's/^/      /'
fi
# 🔴 **바깥 하나가 drizzle/ 이 아닌가** — 55번은 전부 drizzle/ 이었다. 여기가 뒤집힌 자리다.
NDRZ=$(printf '%s\n' "$CHANGED_ALL" | grep -c '^drizzle/' || true)
say "바깥에서 drizzle/ 인 파일 ${NDRZ:-0}개 (기대 $AS_OUTSIDE_DRIZZLE_WANT — 🔵 55번은 5 였다)"
if [ "${NDRZ:-x}" = "$AS_OUTSIDE_DRIZZLE_WANT" ]; then
  ok "drizzle/ 에서 바뀐 파일이 ${AS_OUTSIDE_DRIZZLE_WANT}개다 — **마이그레이션 0건**의 근거 ③"
else
  bad "🔴 drizzle/ 에서 ${NDRZ}개가 바뀌었다 — ${AS_OUTSIDE_DRIZZLE_WANT}개를 기대했다. **묶음이 필요한 판이다**"
  doubt
fi
printf '%s\n' "      ── 바깥 하나가 무엇인가 (🔵 도구에는 안 담기고 **앱에는 담긴다**)"
printf '%s\n' "$CHANGED_ALL" \
  | grep -vE '^(scripts/|src/|package\.json$|drizzle\.config\.ts$|tsconfig\.json$|vendor/)' | head -5 | sed 's/^/      /'

# ── ㅂ) 🔴 이번 판이 바꾼 **12개가 정말 그 열둘인가** ────────────────
#   🔴 「담기는 것이 12개다」와 「그 12개가 내가 아는 12개다」는 다른 말이다.
printf '\n  ── 🔴 이번 판이 바꾼 src/ 파일 %s개가 **그 열둘 그대로인가**\n' "$AS_CHANGED_SRC_WANT"
SRC_SEEN=0; SRC_OK=0
while IFS= read -r f; do
  [ -n "${f:-}" ] || continue
  SRC_SEEN=$((SRC_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 지금 저장소에 없다 — 목록이 낡았다"; continue
  fi
  if printf '%s\n' "$CHANGED_SRC" | grep -Fxq "$f"; then
    SRC_OK=$((SRC_OK+1))
  else
    bad "🔴 $f 가 **이번 범위에서 안 바뀌었다** — 목록이 낡았다"
  fi
done <<SRCEOF
$(printf '%s\n' "$AS_CHANGED_SRC" | grep -v '^[[:space:]]*$')
SRCEOF
NSRC=$(printf '%s\n' "$CHANGED_SRC" | grep -c . || true)
say "적어 둔 ${SRC_SEEN}개 중 실제로 바뀐 것 ${SRC_OK}개 · 범위의 src/ 변경은 ${NSRC:-0}개"
if [ "$SRC_SEEN" = "$AS_CHANGED_SRC_WANT" ] && [ "$SRC_OK" = "$AS_CHANGED_SRC_WANT" ] && [ "${NSRC:-x}" = "$AS_CHANGED_SRC_WANT" ]; then
  ok "src/ 변경 ${AS_CHANGED_SRC_WANT}개가 적어 둔 열둘과 **정확히 같다** (더도 덜도 없다)"
else
  bad "🔴 적어 둔 ${SRC_SEEN} · 맞은 것 ${SRC_OK} · 실제 ${NSRC:-?} 다 — 셋 다 ${AS_CHANGED_SRC_WANT} 여야 한다"
  printf '%s\n' "$CHANGED_SRC" | head -20 | sed 's/^/      /'
  doubt
fi
# 🔴 **새로 생긴 파일** — src/ 에는 0개, 뿌리에 설명 HTML 하나.
#    🔵 55번에는 「이번에 생긴 다섯」 절이 있었다. 이번 판은 0 이라 **그 절을 뒤집었다** —
#       빈 목록을 돌리면 0/0 으로 공짜 통과가 되므로, **0 인 것 자체를 잰다.**
BORN_SRC=$(printf '%s\n' "$BORN_ALL" | grep -c '^src/' || true)
BORN_N=$(printf '%s\n' "$BORN_ALL" | grep -c . || true)
say "새로 생긴 파일 — src/ 안 ${BORN_SRC:-0}개 (기대 $AS_BORN_SRC_WANT) · 전체 ${BORN_N:-0}개 (기대 $AS_BORN_ROOT_WANT)"
printf '%s\n' "$BORN_ALL" | head -5 | sed 's/^/      /'
if [ "${BORN_SRC:-x}" = "$AS_BORN_SRC_WANT" ]; then
  ok "src/ 에 새 파일이 ${AS_BORN_SRC_WANT}개다 — 열둘이 전부 **고친 것**이다 (55번은 다섯이 새 파일이었다)"
else
  note "src/ 에 새 파일이 ${BORN_SRC:-?}개다 — ${AS_BORN_SRC_WANT}개를 기대했다. 이미지 안 검사 목록을 사람이 보세요"
fi
if [ "${BORN_N:-x}" = "$AS_BORN_ROOT_WANT" ]; then
  ok "새 파일이 모두 ${AS_BORN_ROOT_WANT}개다 (설명 HTML 하나)"
else
  note "새 파일이 ${BORN_N:-?}개다 — ${AS_BORN_ROOT_WANT}개를 기대했다. 사람이 보세요"
fi
# ── 🔴 그 설명 HTML 이 **어느 이미지에 담기나** ─────────────────────
#   🔴 처음에 「이미지 어느 쪽에도 안 담긴다」고 적었다가 **실측에서 틀렸다**
#      (2026-11-11). .next/standalone 은 **저장소 뿌리를 그대로 옮기고**
#      .dockerignore 는 .html 을 안 막는다 — 그래서 **앱 이미지에는 담긴다.**
#      🔵 도구 이미지에는 안 담긴다(tools 는 폴더를 골라 담는다).
#   🔵 덕분에 앱 이미지에 **이번 판을 가르는 수가 하나 더** 생겼다 — 18 → 19.
#   🔴 **quotePath 를 꺼야 센다**(한글 파일명). 안 끄면 git 이 따옴표를 둘러
#      내보내어 '.html$' 가 안 맞고 **조용히 0** 이 나온다.
say "── 그 설명 HTML 은 **앱 이미지에 담긴다** (도구에는 안 담긴다)"
HW=$(git -c core.quotePath=false -C "$ASDIR" ls-tree --name-only "$AS_BASE" -- . 2>/dev/null | grep -c '\.html$' || true)
HN=$(git -c core.quotePath=false -C "$ASDIR" ls-tree --name-only HEAD -- . 2>/dev/null | grep -c '\.html$' || true)
say "저장소 뿌리의 .html — 기준 ${HW:-?} → 지금 ${HN:-?} (적어 둔 값 $AS_ROOT_HTML_WAS → $AS_ROOT_HTML_NOW)"
if [ "${HW:-x}" = "$AS_ROOT_HTML_WAS" ] && [ "${HN:-x}" = "$AS_ROOT_HTML_NOW" ]; then
  ok "뿌리의 .html 이 $AS_ROOT_HTML_WAS → $AS_ROOT_HTML_NOW 다 — 앱 이미지 안에서 **이 수로도 판을 가른다**"
else
  note "뿌리의 .html 이 ${HW:-?} → ${HN:-?} 다 — $AS_ROOT_HTML_WAS → $AS_ROOT_HTML_NOW 를 적어 두었다"
  say "🔵 **굽는 판정은 안 흔들린다.** 다만 아래 이미지 안 검사의 기대값을 사람이 고쳐야 한다."
fi

# ── ㅅ) 🔴 포털·PO 쪽에서 달라진 파일 — **둘 다 0 이어야 한다** ───────
printf '\n  ── 안 굽는 둘에서 달라진 파일 (둘 다 0이어야 한다)\n'
for pair in "dss-auth $AUTH_BASE $AUTH_CHANGED_WANT" "dss-po $PO_BASE $PO_CHANGED_WANT"; do
  set -- $pair
  N=$(git -C "$DEV/$1" diff --name-only "$2..HEAD" 2>/dev/null | wc -l | tr -d ' ')
  say "$1 에서 달라진 파일 ${N:-못 쟀다}개 (적어 둔 수 $3 — 안 굽는다)"
  if [ "${N:-x}" = "$3" ]; then
    ok "$1 에서 달라진 파일이 0개다 — **안 굽는 것이 맞다**"
  else
    bad "🔴 $1 에서 달라진 파일이 ${N:-못 쟀다}개다 — 0개를 기대했다. **그쪽도 구워야 할 수 있다.** 멈추고 알릴 것"
    git -C "$DEV/$1" diff --name-only "$2..HEAD" 2>/dev/null | head -20 | sed 's/^/      /'
    doubt
  fi
done

# ── ㅇ) 🔴 **이번 판인가를 글자로 가른다** ───────────────────────────
#   🔴 「파일이 바뀌었다」와 「그 안에 새 코드가 있다」는 다른 말이다.
#   🔴 마지막 줄이 **마지막 커밋(4c7eb9fa)을 가른다** — 주석만 고친 커밋이라
#      앱 번들로는 못 가르고 **도구 이미지에서만** 갈린다.
printf '\n  ── A/S 이번 판의 표식 다섯 (기준판에 0 · 지금 판에 1 이상)\n'
MK_SEEN=0; MK_OK=0
while IFS='|' read -r s f; do
  [ -n "${s:-}" ] || continue
  MK_SEEN=$((MK_SEEN+1))
  was=$(git -C "$ASDIR" show "$AS_BASE:$f" 2>/dev/null | grep -c "$s" || true)
  now=$(grep -c "$s" "$ASDIR/$f" 2>/dev/null || true)
  printf '      %-52s %-72s 기준 %s → 지금 %s\n' "$s" "$f" "${was:-0}" "${now:-0}"
  if [ "${was:-1}" = "0" ] && [ "${now:-0}" -ge 1 ] 2>/dev/null; then MK_OK=$((MK_OK+1)); fi
done <<MKEOF
$(printf '%s\n' "$AS_MARKS" | grep -v '^[[:space:]]*$')
MKEOF
if [ "$MK_SEEN" = "$AS_MARKS_WANT" ] && [ "$MK_OK" = "$AS_MARKS_WANT" ]; then
  ok "표식 $AS_MARKS_WANT 개가 전부 **이번에 생겼다** (옛 판이 아니다)"
  say "🔵 마지막 줄(repair-case-quote-numbers.ts 안의 $SOFT_MARK)이 **마지막 커밋 $AS_HEAD_SHORT 을 가른다.**"
  say "   🔴 그 커밋은 **주석만** 고친다 — 그래서 앱 번들로는 못 가르고 도구 이미지에서만 갈린다."
else
  bad "🔴 표식이 ${MK_OK}/${MK_SEEN} 개다 — $AS_MARKS_WANT/$AS_MARKS_WANT 을 기대했다. 목록이 낡았거나 범위가 틀렸다"
  doubt
fi
# 🔴 구운 **앱** 이미지에서 쓸 표식이 기준판 src/ 에 **0파일**인가.
ASMW=$(git -C "$ASDIR" grep -l "$BUILD_MARK" "$AS_BASE" -- src/ 2>/dev/null | wc -l | tr -d ' ')
ASMN=$(git -C "$ASDIR" grep -l "$BUILD_MARK" HEAD        -- src/ 2>/dev/null | wc -l | tr -d ' ')
say "$BUILD_MARK 가 든 src/ 파일 — 기준 ${ASMW:-?} → 지금 ${ASMN:-?} (기대 0 → 1 이상)"
if [ "${ASMW:-1}" = "0" ] && [ "${ASMN:-0}" -ge 1 ] 2>/dev/null; then
  ok "앱 표식 $BUILD_MARK 이 **이번에 생겼다** — 번들 안에서 이 한 글자로 판을 가른다"
  say "🔵 **글자 리터럴**이라 번들러가 이름을 못 바꾼다 — 그래서 이것만 ✗ 로 셉니다."
else
  bad "🔴 앱 표식이 기준 ${ASMW:-?} → 지금 ${ASMN:-?} 다 — 0 → 1 이상을 기대했다"
  doubt
fi
# 🔵 뒷걸음 방지 표식 — 쉰두째 것이다. **기준판에도 있어야** 한다.
KPW=$(git -C "$ASDIR" grep -l "$KEEP_MARK" "$AS_BASE" -- src/ 2>/dev/null | wc -l | tr -d ' ')
KPN=$(git -C "$ASDIR" grep -l "$KEEP_MARK" HEAD        -- src/ 2>/dev/null | wc -l | tr -d ' ')
say "$KEEP_MARK 가 든 src/ 파일 — 기준 ${KPW:-?} → 지금 ${KPN:-?} (둘 다 1 이상 — **이번 판이 만든 글자가 아니다**)"
if [ "${KPW:-0}" -ge 1 ] 2>/dev/null && [ "${KPN:-0}" -ge 1 ] 2>/dev/null; then
  ok "뒷걸음 방지 표식 $KEEP_MARK 이 기준판에도 지금에도 있다 (쉰두째 것이 안 사라졌다)"
else
  bad "🔴 $KEEP_MARK 이 기준 ${KPW:-?} · 지금 ${KPN:-?} 다 — 둘 다 1 이상이어야 한다"
  doubt
fi

# ── ㅈ) 🔴 **도구 셋이 아직 읽기만 하는가** ──────────────────────────
#   🔵 이번 판이 만든 도구는 없다. 그래도 재는 까닭은 **한 번 열리면 아무도 안 닫는다**이다.
#   🔴 '--apply' 글자로 재지 않는다 — check-delivered-date-sync.ts 의 **주석**에
#      그 낱말이 1번 나와서, 그렇게 재면 멀쩡한 도구가 ✗ 가 된다.
printf '\n  ── 🔴 도구 셋이 읽기만 하는가 (부르는 꼴로 센다 · 주석에 속지 않는다)\n'
PROBE_W=$(printf '%s\n' 'await db.update(repairCases).set({});' | grep -cE "$RO_WRITE_RE" || true)
PROBE_C=$(printf '%s\n' ' * 그 도구에는 --apply 깃발이 없다. INSERT·UPDATE·DELETE 도 없다.' | grep -cE "$RO_WRITE_RE" || true)
say "표본 — 진짜 쓰는 줄 ${PROBE_W:-?}(기대 1) · 그 낱말이 든 주석 줄 ${PROBE_C:-?}(기대 0)"
if [ "${PROBE_W:-0}" = "1" ]; then ok "읽기 전용 잣대가 살아 있다 (진짜 쓰는 줄 하나를 제대로 잡았다)"
else bad "🔴 읽기 전용 잣대가 죽었다 — 아래 「0줄」이 공짜 통과다. 멈추세요"; fi
if [ "${PROBE_C:-1}" = "0" ]; then ok "낱말만 적힌 주석은 **안 센다** (멀쩡한 도구가 가짜 ✗ 를 안 받는다)"
else bad "🔴 주석의 낱말을 쓰는 문장으로 센다 — **머리말에 설명을 적은 도구가 전부 빨개진다**"; fi
RO_SEEN=0; RO_OK=0
for f in $RO_TOOLS; do
  RO_SEEN=$((RO_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then bad "🔴 $f 가 없다 — 목록이 낡았다"; continue; fi
  w=$(grep -cE "$RO_WRITE_RE" "$ASDIR/$f" || true)
  tx=$(grep -c 'db.transaction' "$ASDIR/$f" || true)
  ap=$(grep -cF -- '--apply' "$ASDIR/$f" || true)
  printf '      %-46s 쓰는 꼴 %s · 트랜잭션 %s · (참고) --apply 글자 %s\n' "$f" "${w:-0}" "${tx:-0}" "${ap:-0}"
  if [ "${w:-1}" = "0" ] && [ "${tx:-1}" = "0" ]; then RO_OK=$((RO_OK+1)); fi
done
if [ "$RO_SEEN" = "$RO_TOOLS_WANT" ] && [ "$RO_OK" = "$RO_TOOLS_WANT" ]; then
  ok "도구 $RO_TOOLS_WANT 개가 **쓰는 문장 0 · 트랜잭션 0** 이다 (운영에서 돌려도 한 글자도 안 바뀐다)"
  say "🔵 위 「--apply 글자」가 1 로 나오는 줄이 있어도 **주석**입니다 — 그래서 그 수로 재지 않습니다."
else
  bad "🔴 읽기 전용인 것이 ${RO_OK}/${RO_SEEN} 개다 — ${RO_TOOLS_WANT}/${RO_TOOLS_WANT} 을 기대했다"
  say "🔴 **운영 DB 에 쓸 수 있는 도구를 굽는 판이다.** 멈추고 알리세요."
  doubt
fi
if [ -s "$ASDIR/$RO_TEST" ]; then
  ok "$RO_TEST 가 저장소에 있다 (이 규율을 원본 글자로 지키는 짝이 아직 있다)"
else
  note "$RO_TEST 가 없다 — 54번이 올린 것으로 적어 두었다. 사람이 보세요"
fi

# ── ㅊ) 🔴 **알고도 안 고친 것** — PO 가 새 거절 코드를 모른다 ───────
#   🔵 53번에서 넘어온 것이다. 이번 판도 안 고친다(PO 를 안 굽는다). ⚠️ 라 배포를 막지 않는다.
printf '\n  ── 🔴 PO 가 A/S 의 거절 코드를 아는가 (53번에서 넘어온 할 일)\n'
if [ -s "$PODIR/$PO_GATEWAY" ]; then
  PCODE=$(grep -c "$PO_MISSING_CODE" "$PODIR/$PO_GATEWAY" || true)
  ASCODE=$(grep -c "$PO_MISSING_CODE" "$ASDIR/$PO_MUT" || true)
  say "A/S $PO_MUT 의 $PO_MISSING_CODE ${ASCODE:-0}번"
  say "PO  $PO_GATEWAY 의 $PO_MISSING_CODE ${PCODE:-0}번 (53~55번 실측 0 — **아직 모른다**)"
  if [ "${ASCODE:-0}" -ge 1 ] 2>/dev/null && [ "${PCODE:-1}" = "0" ]; then
    note "🔴 **PO 는 아직 $PO_MISSING_CODE 를 모른다.** PO 에서 기타건을 [완료 처리] 하면"
    say "   A/S 가 적어 보낸 안내 문장이 **화면에 안 뜨고** 「모르는 응답」으로 떨어집니다."
    say "   🔵 자료는 안 깨집니다 — A/S 는 한 글자도 안 쓴 채 거절합니다."
    say "   🔵 지금 운영에서는 **직원이 PO 에 못 들어갑니다**(2026-11-08 사용자) — 실질적으로 닫혀 있습니다."
    say "   🔴 **PO 를 다시 여는 날 이식할 것이 셋입니다**(이 코드 · 납품일 새 칸 · 회차 승인)."
  elif [ "${PCODE:-0}" -ge 1 ] 2>/dev/null; then
    ok "PO 가 $PO_MISSING_CODE 를 안다 — 🔵 그 사이에 PO 가 고쳐졌다. 꼬리말의 그 줄은 이제 거짓이다"
  else
    note "A/S 쪽 $PO_MISSING_CODE 가 ${ASCODE:-0}번이다 — 1 이상을 기대했다. 사람이 보세요"
  fi
else
  unk "PO 의 as-gateway" "$PODIR/$PO_GATEWAY 를 못 읽었다"
fi

# ── 6. 태그가 이미 있나 ───────────────────────────────────────────────
printf '\n== 6. 새 태그가 이미 있나\n'
printf '%s\n' "🔵 있으면 **덮어쓴다** — 같은 커밋이면 같은 것이 나오므로 해롭지 않다."
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  rest=${row#*|}; rest=${rest#*|}; TAG=${rest%%|*}
  if docker image inspect "$TAG" >/dev/null 2>&1; then note "$TAG — 이미 있다 (덮어쓴다)"
  else ok "$TAG — 아직 없다"; fi
done
# 🔵 **되돌릴 판이 개발 PC 에 남아 있는가** — NAS 쪽은 57-deploy.sh 가 따로 센다.
for t in "$AS_OLD_TAG" "$AS_TOOLS_OLD_TAG"; do
  if docker image inspect "$t" >/dev/null 2>&1; then say "🔵 옛 판 $t 가 개발 PC 에 있다"
  else say "🔵 옛 판 $t 가 개발 PC 에 없다 — NAS 쪽에 있으면 되돌리기는 된다(거기서 센다)"; fi
done
say "🔵 포털은 dss-auth:2.1 · dss-auth-tools:4 그대로 둔다 — 이번에 안 굽고 안 갈아 끼운다."
say "🔵 PO 는 dss-po:0.9 그대로 둔다 — 같다."

# ── 7. tar 둘을 둘 자리 + 🔴 3000번 개발 서버 ────────────────────────
printf '\n== 7. tar 둘을 둘 자리\n'
if [ "$MODE" = "--go" ]; then
  mkdir -p "$OUT" 2>/dev/null
fi
if [ -d "$OUT" ]; then ok "$OUT 가 있다"
elif [ "$MODE" = "--check" ]; then note "$OUT 가 아직 없다 (--go 가 만든다)"
else bad "$OUT 를 못 만들었다"; fi
# 🔵 tar 둘이면 360MB 쯤이다. 🔴 **이번 판에는 묶음이 없다** — 그만큼 덜 쓴다.
FREEKB=$(df -Pk "$(dirname "$OUT")" 2>/dev/null | awk 'NR==2 {print $4}')
if isnum "${FREEKB:-}"; then
  say "남은 자리 $((FREEKB / 1024))MB (tar 둘이 약 360MB · 🔵 묶음은 안 만든다)"
  if [ "$FREEKB" -ge 1000000 ]; then ok "자리가 넉넉하다"
  else bad "자리가 모자란다 — 1GB 이상을 권한다"; fi
else
  unk "남은 자리" "df 가 수를 안 돌려줬다"
fi
# ── 🔴 7-ㄴ. 3000번에 개발 서버가 떠 있는가 ─────────────────────────
#   🔵 .dockerignore 가 .next 를 막으므로 **굽기는 된다**(5절-ㄴ 이 그것을 쟀다).
#   🔴 그래도 재서 찍는다 — 「3000번이 떠 있으면 .next 를 두고 다툰다」가 이
#      저장소의 기록이고, tsc 오류가 그 탓이었던 적이 있다. 사람이 알고 굽게 한다.
#   🔴 **✗ 로 세지 않는다.** 떠 있어도 docker build 는 멀쩡하다 — 여기서 막으면
#      멀쩡한 판이 못 구워진다.
printf '\n  ── 🔴 3000번 개발 서버 (떠 있어도 **굽기는 막지 않는다**)\n'
DEVPORT=$(netstat -ano 2>/dev/null | grep -cE '[^0-9.]3000[[:space:]]' || true)
DEVCODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:3000/ 2>/dev/null)
say "3000번이 보이는 줄 ${DEVPORT:-못 쟀다}개 · HTTP 응답 ${DEVCODE:-없음}"
# 🔴 **한 줄에 || 와 && 를 섞지 않는다** — 셸은 왼쪽부터 묶어 (A||B)&&C 가 되고,
#    그러면 「포트는 떴는데 응답을 못 받은」 판이 **안 떴다**로 읽힌다. 깃발로 가른다.
DEVUP=no
if isnum "${DEVPORT:-}" && [ "${DEVPORT:-0}" -ge 1 ]; then DEVUP=yes; fi
case "${DEVCODE:-000}" in (000|'') ;; (*) DEVUP=yes ;; esac
say "판정: 개발 서버 떠 있음 = $DEVUP"
if [ "$DEVUP" = yes ]; then
  note "개발 서버가 **떠 있다** — 🔵 .dockerignore 가 .next 를 막아 **굽기는 됩니다.**"
  say "🔴 다만 이 PC 에서 'npm run build' 를 따로 돌리지 마세요 — 그쪽이 .next 를 두고 다툽니다."
  say "🔵 docker build 는 **빌드 문맥 안에서** 굽습니다(호스트의 .next 를 안 씁니다)."
else
  ok "3000번에 개발 서버가 안 떠 있다 (.next 를 다툴 상대가 없다)"
fi

# ══════════════════════════════════════════════════════════════════════
# ── 8. 🔴 양식 파일 — **이번 판에도 올릴 것이 없다. 그래도 잰다** ─────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **경로를 찍지 않는다.** 이름 · 바이트 · md5 · 수정 시각만 찍는다.
#   🔴 **md5 가 적어 둔 것과 다르면 ✗ 가 아니라 ⚠️ 다** — 사용자가 양식을 고쳤다는
#      뜻이고, 그러면 **올릴 것이 생긴다.** 굽기를 막을 일은 아니다.
printf '\n== 8. 양식 파일 — 열하나가 55번 값 그대로인가 (경로는 안 찍는다)\n'
# 🔵 .env.local 에서 그 이름의 값을 읽는다. **같은 이름이 두 줄이면 아래가 이긴다**
#    — 그래서 tail -1 이다. 값은 안 찍는다.
tpl_path() { # 1 변수 이름 → 경로(없으면 빈 줄). 🔴 찍지 말 것.
  local v q
  v=$(grep -E "^$1=" "$ASDIR/.env.local" 2>/dev/null | tail -1 | cut -d= -f2-)
  v=$(printf '%s' "$v" | tr -d '\r')
  q=$(printf '%s' "'")
  v=${v#\"}; v=${v%\"}
  v=${v#"$q"}; v=${v%"$q"}
  v=${v# }; v=${v% }
  [ -n "$v" ] || return 0
  to_unix "$v"
}
TPL_SEEN=0; TPL_SAME=0; TPL_DIFF=0; TPL_MISS=0
# 🔴 양식 이름에는 **공백과 한글**이 둘 다 있다. 그래서 while/IFS 로 한 줄씩 읽는다.
#    🔵 while 이 파이프라인 안이면 셈이 안 넘어오므로 **여기 문서**로 먹인다.
while IFS='|' read -r VAR NAME WSZ WM5; do
  [ -n "${VAR:-}" ] || continue
  TPL_SEEN=$((TPL_SEEN+1))
  P=$(tpl_path "$VAR")
  if [ -z "${P:-}" ]; then
    printf '  ✗ %-42s %s — .env.local 에 그 이름이 없다\n' "$VAR" "$NAME"
    TPL_MISS=$((TPL_MISS+1)); continue
  fi
  if [ ! -s "$P" ]; then
    printf '  ✗ %-42s %s — 그 자리에 파일이 없다 (경로는 안 찍는다)\n' "$VAR" "$NAME"
    TPL_MISS=$((TPL_MISS+1)); continue
  fi
  GOTNAME=${P##*/}
  SZ=$(stat -c %s "$P" 2>/dev/null)
  M5=$(md5sum "$P" 2>/dev/null | awk '{print $1}')
  MT=$(date -r "$P" '+%Y-%m-%d %H:%M' 2>/dev/null)
  printf '      %-42s %-26s %8s바이트  %s  %s\n' "$VAR" "$GOTNAME" "${SZ:-?}" "${MT:-?}" "${M5:-?}"
  if [ "$GOTNAME" != "$NAME" ]; then
    printf '  ⚠️ %s 가 가리키는 파일 이름이 %s 다 — **%s 를 적어 두었다.** 운영 쪽도 함께 봐야 한다\n' "$VAR" "$GOTNAME" "$NAME"
  fi
  if [ "${M5:-x}" = "$WM5" ] && [ "${SZ:-x}" = "$WSZ" ]; then
    TPL_SAME=$((TPL_SAME+1))
  else
    TPL_DIFF=$((TPL_DIFF+1))
    printf '  ⚠️ %s 가 적어 둔 것과 **다르다** (적어 둔 %s바이트 %s)\n' "$NAME" "$WSZ" "$WM5"
    printf '%s\n' "      🔵 양식을 고치셨다는 뜻입니다. **굽기는 막지 않습니다.**"
    printf '%s\n' "      🔴 그러면 **올릴 양식이 생긴 것**입니다 — 이 파일에는 양식을 복사하는"
    printf '%s\n' "         절이 없습니다. 되살릴 곳: 51-build.sh 의 8절·꼬리말 ·"
    printf '%s\n' "         51-deploy.sh 의 --templates-prep(1056~1172줄)·--templates-apply(1174~1341줄)."
    printf '%s\n' "         🔵 2026-11-11 에 양식만 올리는 56-stage.sh · 56-templates.sh 도 있습니다."
  fi
done <<TPLEOF
$(printf '%s\n' "$TPLS" | grep -v '^[[:space:]]*$')
TPLEOF
say "양식 ${TPL_SEEN}개를 봤다 (적어 둔 수 $TPL_COUNT_WANT)"
say "적어 둔 것과 같은 것 ${TPL_SAME}개 · 다른 것 ${TPL_DIFF}개 · 못 찾은 것 ${TPL_MISS}개"
if [ "$TPL_SEEN" = "$TPL_COUNT_WANT" ]; then ok "양식 $TPL_COUNT_WANT 개를 다 봤다 (표본이 비지 않았다)"
else bad "양식을 ${TPL_SEEN}개만 봤다 — $TPL_COUNT_WANT 개를 기대했다. TPLS 표가 깨졌다"; fi
if [ "$TPL_MISS" = "0" ]; then ok "양식 $TPL_COUNT_WANT 개가 전부 제자리에 있다"
else bad "양식 ${TPL_MISS}개를 못 찾았다"; doubt; fi
if [ "$TPL_DIFF" = "0" ]; then
  ok "양식 $TPL_COUNT_WANT 개가 **전부 55번이 적어 둔 md5 그대로**다 — 🔵 **올릴 양식이 0장이다**"
else
  note "양식 ${TPL_DIFF}개가 적어 둔 것과 다르다 — 위를 보세요. **굽기는 막지 않는다**"
fi
# 🔵 그리고 **이번 범위에 .xlsx 변경이 0줄인가** — 저장소 쪽에서도 따로 본다.
XLSX=$(printf '%s\n' "$CHANGED_ALL" | grep -ci '\.xlsx$' || true)
say "A/S 범위에서 달라진 .xlsx ${XLSX:-0}개 (기대 0)"
if [ "${XLSX:-1}" = "0" ]; then ok "범위에 .xlsx 변경이 0줄이다 (양식 절이 없는 까닭이다)"
else note "범위에 .xlsx 가 ${XLSX}개 있다 — 0 을 기대했다. 양식 올리는 절이 필요할 수 있다"; fi

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
printf '\n%s\n' "════════ 굽는다 (둘) ════════"
BUILT=0; BFAIL=0; TARTABLE=""
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}
  rest=${rest#*|}; BASE=${rest%%|*}; rest=${rest#*|}; TGT=${rest%%|*}
  rest=${rest#*|}; WANTMIG=${rest%%|*}; rest=${rest#*|}; WANTN=${rest%%|*}
  rest=${rest#*|}; PREVSZ=${rest%%|*}; rest=${rest#*|}; PREVTAR=${rest%%|*}
  rest=${rest#*|}; STRICT=${rest%%|*}
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
  #    'docker image inspect' 의 .Id 와는 **애초에 다른 값**이다.
  cfg=$(tar_config_id "$OUT/$FILE")
  exp=$(tr -d '\000' < "$LOG" | grep -oE "exporting config sha256:[0-9a-f]+" | tail -1 | grep -oE "sha256:[0-9a-f]+")
  printf '    tar  %s\n' "${cfg:-못 읽음}"
  printf '    로그 %s\n' "${exp:-없음}"
  if [ -n "$cfg" ] && [ -n "$exp" ] && [ "$cfg" = "$exp" ]; then printf '  ✓ 지문이 빌드 로그와 같다\n'
  elif [ -z "$exp" ]; then printf '  ⚠️ 빌드 로그에 exporting config 가 없다 (buildx 판에 따라 안 찍힌다)\n'
  else printf '  ✗ 지문이 다르다\n'; BFAIL=$((BFAIL+1)); continue; fi

  # ── 🔴 크기 견주기 ① — **지난 판 tar 와** ────────────────────────────
  p=$(pct_diff "$sz" "$PREVSZ")
  if [ -n "${p:-}" ]; then
    printf '    지난 판 %s %s바이트 → 이번 %s바이트 (차이 %s%%)\n' "$PREVTAR" "$PREVSZ" "$sz" "$p"
    if [ "$p" -le 25 ]; then
      printf '  ✓ 지난 판 tar 와 크기가 비슷하다 (차이 %s%% · 25%% 이내)\n' "$p"
    elif [ "$STRICT" = "loose" ] && [ "$p" -le 60 ]; then
      printf '  ⚠️ 지난 판 tar 와 %s%% 다르다 — 기준값이 오래된 줄이라 막지 않습니다.\n' "$p"
    else
      printf '  ✗ 지난 판 tar 와 크기가 %s%% 다르다 — %s 에서는 그만큼이면 멈춘다\n' "$p" "$STRICT"
      printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 라이브러리가 늘거나 베이스 이미지가"
      printf '%s\n' "         바뀌면 정상적으로도 이만큼 뜁니다. 까닭을 알면 SITES 표의 여덟째 칸을"
      printf '%s\n' "         고쳐 적으면 됩니다. 모르겠으면 **멈추고 알리세요.**"
      printf '%s\n' "      🔵 이번 판은 **소스 12개만 고친 판**이라 크기가 거의 안 움직여야 정상입니다."
      BFAIL=$((BFAIL+1)); continue
    fi
  else
    printf '  ✗ 크기를 못 쟀다 (이번 %s · 지난 판 %s)\n' "${sz:-없음}" "${PREVSZ:-없음}"
    BFAIL=$((BFAIL+1)); continue
  fi

  # ── 🔴 크기 견주기 ② — **그 이미지 자신과** (가지를 둘로 나눈다) ───
  isz=$(docker image inspect "$TAG" --format '{{.Size}}' 2>/dev/null)
  if isnum "${isz:-}" && [ "${isz:-0}" -gt 0 ]; then
    r=$((sz * 100 / isz))
    printf '    이미지 inspect .Size %s바이트 · tar 는 그 %s%%\n' "$isz" "$r"
    if [ "$r" -ge 90 ] && [ "$r" -le 110 ]; then
      printf '  ✓ tar 가 이미지 내용 크기와 거의 같다 (%s%% — containerd 저장소다)\n' "$r"
    elif [ "$r" -ge 10 ] && [ "$r" -le 45 ]; then
      printf '  ✓ tar 가 이미지의 1/4 쯤이다 (%s%% — 고전 저장소다)\n' "$r"
    else
      printf '  ✗ tar 가 이미지의 %s%% 다 — 90~110%% 나 10~45%% 를 기대했다\n' "$r"
      printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 이 비는 docker 의 저장소 방식이 정합니다."
      BFAIL=$((BFAIL+1)); continue
    fi
  else
    printf '  ? 이미지 크기를 못 쟀다 — docker image inspect 가 수를 안 돌려줬다\n'
    BFAIL=$((BFAIL+1)); continue
  fi

  m5=$(md5sum "$OUT/$FILE" | awk '{print $1}')
  printf '    md5  %s\n' "$m5"
  TARTABLE="$TARTABLE$FILE|$sz|$m5|${cfg:-없음}
"
  BUILT=$((BUILT+1))

  # ══ 🔴 이미지 **안**을 센다 — 겉이 아니라 결과 ═══════════════════════
  #   🔴 갈래가 둘이라 **갈래마다 다른 것을 잰다.** 한 잣대로 재면 가짜 ✗ 가 난다.
  #   🔴 **앱과 도구는 담긴 것이 다르다** — 앱은 번들, 도구는 소스 그대로다.
  #      그래서 **같은 글자를 같은 방식으로 묻지 않는다.**
  IMGFAIL=0
  case "$KEY" in
    as)
      printf '\n    ── %s 안을 센다 (번들이다 — 소스가 없다)\n' "$TAG"
      # ① runner 가 맞는가 — tools 에는 /app/server.js 가 없다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/server.js && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '    /app/server.js: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ runner 스테이지가 맞다 (node server.js 를 안다)\n'
      else printf '  ✗ /app/server.js 가 없다 — **runner 가 아닌 것을 구웠다.** 올리지 마세요\n'; IMGFAIL=1; fi
      # ② 🔴 **이번 판의 글자가 번들에 있는가.** 🔵 no-equipment-key 는 응답에
      #    실려 나가는 **글자 리터럴**이라 minifier 가 이름을 못 바꾼다.
      #    🔵 개발 PC 의 .next/standalone/.next/server 에서 **4 파일**로 쟀다(2026-11-11).
      #    🔴 이것이 없으면 「옛 판을 구웠다」이고, 그때 증상은 **아무 일도 안
      #       일어나는 것**이다 — 배포는 성공하고 기능만 없다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "grep -rlF $BUILD_MARK /app/.next/server 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '    /app/.next/server 안에서 %s 가 든 파일: %s개 (기대 1 이상 · 개발 PC 번들에서 4)\n' "$BUILD_MARK" "${v:-?}"
      if isnum "${v:-}" && [ "${v:-0}" -ge 1 ]; then
        printf '  ✓ 번들에 이번 판의 글자가 있다 (옛 판이 아니다)\n'
      else
        printf '  ✗ 번들에 %s 가 없다 — **옛 판을 구웠다.** 캐시를 의심하세요\n' "$BUILD_MARK"; IMGFAIL=1
      fi
      # ③ 🔵 **뒷걸음 방지** — 쉰두째가 올린 글자가 아직 있는가.
      #    🔴 이것은 **이번 판이 만든 글자가 아니다.** 「더 옛날 나무를 구웠나」를 본다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "grep -rlF $KEEP_MARK /app/.next/server 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '    %s 가 든 파일: %s개 (기대 1 이상 · 쉰두째 것 · 개발 PC 번들에서 5)\n' "$KEEP_MARK" "${v:-?}"
      if isnum "${v:-}" && [ "${v:-0}" -ge 1 ]; then
        printf '  ✓ 쉰두째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)\n'
      else
        printf '  ✗ %s 가 없다 — **쉰두째보다 옛 나무를 구웠다.** 올리지 마세요\n' "$KEEP_MARK"; IMGFAIL=1
      fi
      # ④ 🔵 보조 표식 — **식별자**라 번들러가 이름을 바꿀 수 있다. ⚠️ 로만 센다.
      #    🔴 「재서 나왔다」와 「앞으로도 나온다」는 다른 말이다 — ✗ 로 세면 가짜 ✗ 가 난다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "grep -rlF $SOFT_MARK /app/.next/server 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '    %s 가 든 파일: %s개 (개발 PC 번들에서 2 — ⚠️ 로만 셉니다)\n' "$SOFT_MARK" "${v:-?}"
      if isnum "${v:-}" && [ "${v:-0}" -ge 1 ]; then
        printf '  ✓ 조각 ① 의 이름도 번들에 남아 있다 (보조 증거)\n'
      else
        printf '  ⚠️ %s 가 번들에 안 보인다 — 🔵 **식별자라 번들러가 이름을 줄였을 수 있습니다.**\n' "$SOFT_MARK"
        printf '%s\n' "      🔵 위 ② 가 ✓ 라면 **판은 맞습니다** — 이 줄만으로 올리기를 막지 않습니다."
      fi
      # ⑤ 🔵 public/ 이 담겼는가 — 없으면 아이콘·정적 파일이 404 가 된다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/public && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '    /app/public: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ public/ 이 담겼다\n'
      else printf '  ✗ public/ 이 없다 — 정적 파일이 404 가 된다\n'; IMGFAIL=1; fi
      # ⑥ 🔴 **뿌리의 .html 수로도 판을 가른다** — 기준 18 → 이번 19.
      #    🔴 처음에 「설명 HTML 은 이미지에 안 담긴다」고 적었다가 **실측에서
      #       틀렸다**(2026-11-11). standalone 은 **저장소 뿌리를 그대로 옮기고**
      #       .dockerignore 는 .html 을 안 막는다. 🔵 도구 이미지에는 안 담긴다.
      #    🔴 **0 이면 ✗ 다** — standalone 이 뿌리 파일을 아예 안 옮겼다는 뜻이고,
      #       그러면 이 이미지의 생김새 자체가 지금까지와 다르다.
      #    🔵 **19 가 아니면 ⚠️ 다** — 뿌리에 문서를 더하거나 지우면 바뀌는 수라
      #       ✗ 로 두면 가짜 ✗ 가 난다. 대신 무엇을 뜻하는지 적어 둔다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "ls -1 /app/*.html 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '    /app 바로 아래 .html: %s개 (기준판 %s → 이번 %s)\n' "${v:-?}" "$AS_ROOT_HTML_WAS" "$AS_ROOT_HTML_NOW"
      if ! isnum "${v:-}" || [ "${v:-0}" = "0" ]; then
        printf '  ✗ /app 바로 아래에 .html 이 %s개다 — standalone 이 뿌리 파일을 안 옮겼다\n' "${v:-못 읽음}"; IMGFAIL=1
      elif [ "${v:-0}" = "$AS_ROOT_HTML_NOW" ]; then
        printf '  ✓ 뿌리의 .html 이 %s개다 (기준판 %s + 이번 설명 HTML 하나 — **이 수로도 이번 판이다**)\n' "$AS_ROOT_HTML_NOW" "$AS_ROOT_HTML_WAS"
      elif [ "${v:-0}" = "$AS_ROOT_HTML_WAS" ]; then
        printf '  ⚠️ 뿌리의 .html 이 %s개다 — **기준판과 같은 수**입니다. 설명 HTML 이 빠졌을 수 있습니다\n' "$AS_ROOT_HTML_WAS"
        printf '%s\n' "      🔵 위 ② 가 ✓ 라면 **판은 맞습니다** — 이 줄만으로 올리기를 막지 않습니다."
      else
        printf '  ⚠️ 뿌리의 .html 이 %s개다 — %s개를 기대했다. 그 사이에 문서를 더하거나 지우셨나요\n' "${v:-?}" "$AS_ROOT_HTML_NOW"
      fi
      ;;
    astools)
      printf '\n    ── %s 안을 센다 (겉이 아니라 결과 · 🔵 소스가 **글자 그대로** 있다)\n' "$TAG"
      # ① runner 가 아니라 tools 인가
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '      /app/package.json: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ tools 스테이지가 맞다\n'
      else printf '  ✗ /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다\n'; IMGFAIL=1; fi
      # ② 🔴 운영에서 불릴 npm 명령 **아홉**이 이미지 안 package.json 에 있는가(41번의 자리).
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync check-due-date-overdue check-delivered-date-sync procedures:export procedures:import db:preflight db:migrate; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "9" ]; then printf '  ✓ npm 명령 아홉이 이미지 안에 있다 (Missing script 가 안 난다)\n'
      else printf '  ✗ 명령이 %s/9 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다**\n' "${got:-0}"; IMGFAIL=1; fi
      # ③ 🔴 **이번 판이 바꾼 12개가 담겼는가** — 55번의 「닫힘 아홉」을 **갈아 끼운 자리**다.
      #    🔴 그 아홉은 이번 판에 **하나도 안 바뀐다** — 그것을 세면 **아무것도 안 재는 ✓** 다
      #       (어느 판에서나 있는 파일이다). 이 목록은 **이 배포를 실제로 재는 열둘**이다.
      #    🔴 경로에 괄호와 대괄호가 있다 — **환경변수로 넘겨 큰따옴표로 받는다.**
      #       안 감싸면 (app) 은 sh 의 문법이라 죽고 [id] 는 글롭이라 조용히 빗나간다.
      v=$(docker run --rm -e DSS_FILES="$AS_CHANGED_SRC" --entrypoint sh "$TAG" -c 'printf "%s\n" "$DSS_FILES" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      seen=$(printf '%s\n' "$v" | grep -cE '^(yes|no ) ' || true)
      printf '      본 것 %s개 · 있는 것 %s개 (기대 %s · %s)\n' "${seen:-0}" "${got:-0}" "$AS_CHANGED_SRC_WANT" "$AS_CHANGED_SRC_WANT"
      if [ "${seen:-0}" = "$AS_CHANGED_SRC_WANT" ] && [ "${got:-0}" = "$AS_CHANGED_SRC_WANT" ]; then
        printf '  ✓ 이번 판이 바꾼 %s개가 다 담겼다 (표본이 비지 않았다)\n' "$AS_CHANGED_SRC_WANT"
      else
        printf '  ✗ 본 것 %s · 있는 것 %s 다 — %s/%s 를 기대했다. 괄호·대괄호 경로가 빗나갔는지 보세요\n' "${seen:-0}" "${got:-0}" "$AS_CHANGED_SRC_WANT" "$AS_CHANGED_SRC_WANT"; IMGFAIL=1
      fi
      # ④ 🔴 **그 안에 이번 판의 글자가 있는가** — 「파일이 있다」와 다른 말이다.
      #    🔴 마지막 짝이 **마지막 커밋(4c7eb9fa)을 가른다** — 주석이라 번들에는 안 남는다.
      # 🔴 **set -f 로 글롭을 끈다** — 경로에 [id] 가 들어 있다. 글롭이 살아 있으면
      #    sh 가 그것을 문자 집합으로 읽고, 안 맞으면 글자 그대로 남겨 **운에 기댄다.**
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'set -f; for pair in "listRepairCaseIdsWithOrderIssuedDate /app/src/lib/db/queries/domestic-orders.ts" "no-equipment-key /app/src/lib/storage/purchase-order-archive.ts" "no-equipment-key /app/src/app/api/repair-cases/[id]/purchase-order-folder/entries/route.ts" "PURCHASE_ORDER_FOLDER_SECTION_NO_EQUIPMENT_KEY_TEXT /app/src/components/repair-cases/purchase-orders/PurchaseOrderFolderSection.tsx" "listRepairCaseIdsWithOrderIssuedDate /app/src/lib/db/queries/repair-case-quote-numbers.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "$AS_MARKS_WANT" ]; then
        printf '  ✓ 이번 판의 표식 %s개가 이미지 안에 있다 (옛 판이 아니다)\n' "$AS_MARKS_WANT"
        printf '%s\n' "      🔵 마지막 줄(repair-case-quote-numbers.ts)이 **마지막 커밋을 가릅니다** —"
        printf '%s\n' "         그 커밋은 주석만 고치므로 **도구 이미지에서만** 갈립니다."
      else
        printf '  ✗ 이번 판의 표식이 %s/%s 개다 — **옛 판이 담겼다.** 캐시를 의심하세요\n' "${got:-0}" "$AS_MARKS_WANT"; IMGFAIL=1
      fi
      # ⑤ 🔵 **공용 스키마가 담겼는가** — 없으면 Cannot find module 이 난다.
      #    🔵 이번 판에는 **안 바뀌었다.** 그래서 「새 칸이 있나」가 아니라 「있나」만 본다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'd=/app/vendor/dss-core/src/schema; if [ -d "$d" ]; then echo "miss=0"; echo "n=$(ls -1 "$d" | wc -l)"; else echo "miss=1"; fi' 2>/dev/null | tr -d ' \r')
      printf '%s\n' "$v" | sed 's/^/      /'
      cm=$(printf '%s\n' "$v" | sed -n 's/^miss=//p'); cn=$(printf '%s\n' "$v" | sed -n 's/^n=//p')
      if [ "${cm:-1}" != "0" ]; then
        printf '  ✗ 이미지에 vendor/dss-core 의 스키마 폴더가 **없다** — Cannot find module 이 난다\n'; IMGFAIL=1
      elif [ "${cn:-0}" -ge 1 ] 2>/dev/null; then
        printf '  ✓ 공용 스키마가 담겼다 (파일 %s개)\n' "$cn"
      else
        printf '  ✗ 공용 스키마 폴더가 비었다 — **빈 서브모듈이 담겼다.** 올리지 마세요\n'; IMGFAIL=1
      fi
      # ⑥ 🔵 쉰두째가 올린 칸이 공용 스키마에 **그대로** 있는가 (뒷걸음 방지).
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for pair in "delivered_date /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "completed_at /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "due_date_row_order /app/vendor/dss-core/src/schema/repair-case-approvals.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "3" ]; then printf '  ✓ 쉰두째가 더한 칸 셋이 공용 스키마에 그대로 있다 (뒷걸음친 서브모듈이 아니다)\n'
      else printf '  ✗ 그 칸이 %s/3 개다 — **옛 공용 스키마가 담겼다.** 올리지 마세요\n' "${got:-0}"; IMGFAIL=1; fi
      # ⑦ 🔵 지난 판들이 올린 도구가 **아직 있는가** — 한 번 빼면 다시 넣는 사람이 없다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts /app/scripts/check-delivered-date-sync.ts /app/scripts/lib/delivered-date-sync-survey.ts /app/scripts/import-procedure-bundle.ts /app/scripts/export-procedure-bundle.ts /app/scripts/lib/procedure-template-bundle.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "9" ]; then printf '  ✓ 48~55번이 올린 도구 아홉이 다 들어갔다\n'
      else printf '  ✗ 도구 파일이 %s/9 개다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
      # ⑧ 🔴 **도구 셋이 이미지 안에서도 읽기만 하는가** — 부르는 꼴로 센다.
      #    🔴 「grep -c」 는 0 일 때 종료 코드 1 을 낸다. 파일 없음과 0번을 **갈래로** 가른다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/check-due-date-overdue.ts /app/scripts/check-delivered-date-sync.ts /app/scripts/lib/delivered-date-sync-survey.ts; do if [ -f "$f" ]; then echo "miss=0 $f"; echo "w=$(grep -cE "\.insert\(|\.update\(|\.delete\(" "$f") $f"; echo "t=$(grep -c "db.transaction" "$f") $f"; else echo "miss=1 $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      nmiss=$(printf '%s\n' "$v" | grep -c '^miss=1' || true)
      nwrite=$(printf '%s\n' "$v" | grep -cE '^w=[1-9]' || true)
      ntx=$(printf '%s\n' "$v" | grep -cE '^t=[1-9]' || true)
      nok=$(printf '%s\n' "$v" | grep -c '^miss=0' || true)
      if [ "${nmiss:-1}" != "0" ]; then
        printf '  ✗ 도구 중 이미지에 **없는 것**이 %s개다\n' "$nmiss"; IMGFAIL=1
      elif [ "${nok:-0}" != "3" ]; then
        printf '  ✗ 도구 셋 중 %s개만 봤다 — 셋을 기대했다\n' "${nok:-0}"; IMGFAIL=1
      elif [ "${nwrite:-1}" = "0" ] && [ "${ntx:-1}" = "0" ]; then
        printf '  ✓ 도구 셋이 이미지 안에서도 **읽기만 한다** (쓰는 꼴 0 · 트랜잭션 0)\n'
      else
        printf '  ✗ 쓰는 꼴이 든 파일 %s개 · 트랜잭션이 든 파일 %s개 — **운영 DB 에 쓸 수 있는 판이다.** 올리지 마세요\n' "${nwrite:-?}" "${ntx:-?}"; IMGFAIL=1
      fi
      # ⑨ 🔵 엑셀 읽개 둘은 **개발 DB 자물쇠**를 그대로 부르는가(53번의 그 절).
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/import-technical-task-procedures.ts /app/scripts/link-technical-task-next-procedures.ts; do if grep -q checkDevelopmentWriteTarget "$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "2" ]; then printf '  ✓ 엑셀 읽개 둘이 개발 DB 자물쇠를 부른다 (NAS 에서 부르면 막힌다)\n'
      else printf '  ✗ 자물쇠를 부르는 것이 %s/2 개다. **운영 DB 에 쓸 수 있는 판이다.** 올리지 마세요\n' "${got:-0}"; IMGFAIL=1; fi
      # ⑩ tsx 가 있는가 — 이 도구들은 tsx 로만 돈다. 🔴 db:preflight 도 tsx 다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '      /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ tsx 가 있다\n'
      else printf '  ✗ tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
      # ⑪ 🔵 **drizzle-kit 이 있는가.** 이번 판은 마이그레이션이 0건이라 db:migrate 를
      #    부를 일이 없다. 🔴 그래도 센다 — **다음 판이 그것으로 DB 를 바꾼다.**
      #    🔵 「이번에 안 쓴다」와 「없어도 된다」는 다른 말이다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/drizzle-kit && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '      /app/node_modules/drizzle-kit: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ drizzle-kit 이 있다 (db:preflight·db:migrate 가 선다)\n'
      else printf '  ✗ drizzle-kit 이 없다 — db:migrate 가 그 자리에서 죽는다. 올리지 마세요\n'; IMGFAIL=1; fi
      # ⑫ 🔴 **값을 받아 본다.** 'node …' 가 아니라 **'npm run …'** 이어야 Missing script 가 드러난다.
      #    🔵 DATABASE_URL 을 안 준다. 맨 위에서 connection.ts 를 정적 import 하고
      #       그것이 모듈 꼭대기에서 던진다 — **DB 에는 한 글자도 안 닿는다.**
      for cmdname in db:preflight check:due-date-overdue check:delivered-date-sync procedures:import; do
        v=$(docker run --rm --entrypoint sh "$TAG" -c "cd /app && npm run $cmdname 2>&1 | head -40" 2>&1 | tr -d '\r')
        if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
          printf '  ✗ npm run %s — **Missing script** (41번과 같은 실패다)\n' "$cmdname"
          printf '%s\n' "$v" | head -20 | sed 's/^/      /'; IMGFAIL=1
        elif printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
          printf '  ✓ npm run %s 가 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)\n' "$cmdname"
        elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
          printf '  ✗ npm run %s 가 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다\n' "$cmdname"
          printf '%s\n' "$v" | head -20 | sed 's/^/      /'; IMGFAIL=1
        else
          printf '  ? npm run %s 의 답이 기대와 다르다 — 아래 20줄을 사람이 보세요\n' "$cmdname"
          printf '%s\n' "$v" | head -20 | sed 's/^/      /'; IMGFAIL=1
        fi
      done
      # ⑬ 🔵 이미지 안의 drizzle/ 은 **비어 있어야** 한다 — 볼륨으로 붙는 자리다.
      #    🔴 이번 판은 묶음을 안 보내므로 **운영 볼륨이 그대로 쓰인다.** 여기에 .sql 이
      #       들어 있으면 볼륨과 이미지 중 어느 것이 돌았는지 알 수 없게 된다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '      /app/drizzle 안 .sql: %s개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)\n' "${v:-?}"
      if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ drizzle/ 이 비어 있다 (🔴 그래서 마이그레이션은 **볼륨에서** 돈다)\n'
      else printf '  ✗ drizzle/ 에 .sql 이 들었다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다\n'; IMGFAIL=1; fi
      # ⑭ 🔵 **양식은 이미지에 안 들어간다** — 들어갔으면 도장과 계좌번호가 구워진 것이다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "ls /templates 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '      /templates 안 파일: %s개 (기대 0 — 양식은 볼륨으로 붙는다)\n' "${v:-?}"
      if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ 양식이 이미지에 안 들어갔다\n'
      else printf '  ✗ 이미지 안에 /templates 가 %s개 있다 — 도장·계좌번호가 구워졌다. 사람이 보세요\n' "${v:-?}"; IMGFAIL=1; fi
      ;;
  esac
  if [ "$IMGFAIL" != 0 ]; then
    printf '%s\n' "🔴 $TAG 의 안이 온전하지 않다. 올리지 마세요."
    BFAIL=$((BFAIL+1))
  fi
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  구운 것 %s / %s · 실패 %s\n' "$BUILT" "$HOWMANY" "$BFAIL"
if [ "$BFAIL" != "0" ]; then printf '%s\n' "🔴 실패가 있다. 위를 보세요."; exit 1; fi

# 🔴 **굽고 나서 저장소가 더러워졌는가** — next build 가 tsconfig.json 을 다시 접는다.
#    🔵 docker build 는 빌드 문맥 안에서 굽지만, 그래도 **값으로 확인한다.**
printf '\n%s\n' "════════ 구운 뒤 저장소가 그대로인가 ════════"
DIRTY_AFTER=$(git -C "$ASDIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
printf '  A/S 미커밋 %s줄 (기대 0)\n' "${DIRTY_AFTER:-?}"
if [ "${DIRTY_AFTER:-1}" = "0" ]; then
  printf '  ✓ 저장소가 그대로다 (굽기가 파일을 안 건드렸다)\n'
else
  printf '  ⚠️ 굽고 나니 미커밋이 %s줄 생겼다 — **사람에게 알리세요**\n' "$DIRTY_AFTER"
  git -C "$ASDIR" status --porcelain=v1 2>/dev/null | head -10 | sed 's/^/      /'
  printf '%s\n' "     🔴 next build 가 tsconfig.json 을 다시 접은 적이 있습니다(눈에 안 띕니다)."
  printf '%s\n' "     🔵 **tar 는 이미 구워졌습니다** — 되돌릴지 그대로 둘지는 사람이 정하세요."
fi

# ══ 🔴 57-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 57-deploy.sh 의 TARS 는 **이름만 적힌 채로** 올라간다. 지문 칸이 비어 있으면
#     --check 에서 ? 로 세고 **--preload·--go 에서는 ✗ 다** — 아래 **두 줄**로
#     그 두 줄을 통째로 갈아 끼운다.
printf '\n%s\n' "════════ 57-deploy.sh 의 TARS 에 붙여 넣을 것 (두 줄) ════════"
printf '%s' "$TARTABLE"
echo "  🔴 위 두 줄로 TARS 의 두 줄을 통째로 갈아 끼운다."
echo "  🔵 **셋째 줄(묶음)은 없다** — 이번 판은 마이그레이션이 0건이라 묶음을 안 만든다."
echo "     🔴 55번에는 MIGTAR_SIZE·MIGTAR_MD5 가 있었다. 57-deploy.sh 에는 **그 변수가 없다.**"
printf '\n%s\n' "✅ 둘 다 구웠다. tar 와 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'

printf '\n%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **올리는 차례 — 이번 판은 tar 둘뿐이다 (묶음 없음)**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  🔵 **마이그레이션이 0건입니다.** 볼륨도 DB 도 $AS_SQL_WANT 그대로입니다."
printf '%s\n' "     🔴 그래서 **57-deploy.sh 에는 --migrate 모드가 없습니다.** 치면 거절합니다."
printf '%s\n' "     🔵 대신 --check 가 **「올릴 것이 정말 0건인가」를 값으로** 확인합니다"
printf '%s\n' "        (볼륨 127 · DB 기록 127 · 적용 대기 0건 · db:preflight 종료 코드 0)."
printf '%s\n' "  🔵 양식은 **한 장도 안 올립니다** — 열하나가 55번 값 그대로입니다(8절)."
printf '%s\n' "  🔵 포털(dss-auth)·PO 는 **안 건드립니다.**"
printf '%s\n' ""
printf '%s\n' "  🔴 PowerShell 경로는 **슬래시**로 적습니다. 역슬래시는 bash·scp 가 먹습니다."
printf '%s\n' "  🔴 **Tee-Object 로 로그를 받지 마세요** — PowerShell 이 UTF-16 으로 써서"
printf '%s\n' "     나중에 grep 이 한 줄도 못 찾습니다. 화면을 그대로 복사하시거나"
printf '%s\n' "     NAS 쪽 로그 파일(스크립트가 스스로 남깁니다)을 보세요."
printf '%s\n' ""
printf '%s\n' "  ① (개발 PC · PowerShell) **스크립트부터 올린다**"
printf '%s\n' "       cd \"C:/Users/희만/Desktop/Development/dss-deploy/nas/setup\""
printf '%s\n' "       scp -O 57-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "       Get-FileHash -Algorithm MD5 57-deploy.sh"
printf '%s\n' "     🔵 NAS 에서 md5sum 을 쳐 **눈으로 맞댑니다**(DSM 터미널이 긴 것을 잘라 먹습니다)."
printf '%s\n' ""
printf '%s\n' "  ② (NAS) 지금 상태를 잰다 — 아직 아무것도 안 바뀐다"
printf '%s\n' "       sudo -i"
printf '%s\n' "       bash /volume1/dss/setup/57-deploy.sh            ← --check"
printf '%s\n' "       bash /volume1/dss/setup/57-deploy.sh --count    ← 올리기 전 수"
printf '%s\n' "     🔵 2절의 마이그레이션 수가 **$AS_SQL_WANT** 로 나와야 합니다 (앞뒤가 같습니다)."
printf '%s\n' ""
printf '%s\n' "  ③ (개발 PC · PowerShell) **tar 둘을 보낸다 — 한 줄에 하나씩**"
printf '%s\n' "       cd \"$(printf '%s' "$OUT" | sed 's|^/c/|C:/|')\""
printf '%s\n' "       scp -O dss-as-4.9.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "       scp -O dss-as-tools-16.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "     🔴 **-O 를 빼지 마세요** — DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' "     🔵 **묶음은 안 보냅니다.** 55번에는 셋째 줄이 있었습니다 — 이번엔 없습니다."
printf '%s\n' ""
printf '%s\n' "  ④ (NAS) **들여놓고 → 다시 재고 → 갈아 끼운다**"
printf '%s\n' "       bash /volume1/dss/setup/57-deploy.sh --preload"
printf '%s\n' "       bash /volume1/dss/setup/57-deploy.sh            ← 다시 --check"
printf '%s\n' "       bash /volume1/dss/setup/57-deploy.sh --go       ⏱ 정지 창 (앱 **하나**)"
printf '%s\n' "       bash /volume1/dss/setup/57-deploy.sh --count    ← 올린 뒤 수"
printf '%s\n' "     🔵 **--migrate 단계가 없습니다.** --go 가 앱과 도구의 image: 줄 **둘**을 고칩니다."
printf '%s\n' ""
printf '%s\n' "🔴 **되돌리기**: --rollback 은 app-as 를 $AS_OLD_TAG 로 되돌립니다."
printf '%s\n' "   🔵 도구는 $AS_TOOLS_TAG 그대로 둡니다(39·41~55번과 같은 판단)."
printf '%s\n' "   🔵 **DB 는 되돌릴 것이 없습니다** — 이 배포는 DB 를 한 글자도 안 바꿉니다."
printf '%s\n' ""
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **배포 뒤에 눈으로 볼 곳 — 동작이 바뀌는 것은 둘뿐입니다**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  ① 🔴 **수리가 끝난 건의 [발주서] 탭** — 내자 줄이 완료된 건을 여세요."
printf '%s\n' "     전에는 「아직 발주발행일이 적혀 있지 않습니다」가 떴습니다. 이제 공유폴더를"
printf '%s\n' "     봅니다(발주발행일이 적혀 있다면)."
printf '%s\n' "  ② 🔴 **「못 찾았다」가 두 문장으로 갈렸습니다.**"
printf '%s\n' "     · L/N 이나 S/N 이 비어 있는 건 → 「L/N 과 S/N 이 둘 다 적혀 있어야…」"
printf '%s\n' "       (할 일은 **접수 정보 적기**)"
printf '%s\n' "     · 열쇠는 있는데 폴더가 없는 건 → 「공유폴더를 찾아봤지만 … 없습니다」"
printf '%s\n' "       (할 일은 **공유폴더 정리**)"
printf '%s\n' "     🔵 둘 다 **200 입니다 — 실패가 아닙니다.**"
printf '%s\n' ""
printf '%s\n' "  🔵 **나머지 커밋 둘은 눈에 안 보입니다** — 설명 HTML 한 장과 주석 셋입니다."
printf '%s\n' "     🔵 설명 HTML 은 **앱 이미지에는 담깁니다** — standalone 이 저장소 뿌리를"
printf '%s\n' "        그대로 옮기고 .dockerignore 가 .html 을 안 막습니다(2026-11-11 실측)."
printf '%s\n' "        🔵 **도구 이미지에는 안 담깁니다**(tools 는 폴더를 골라 담습니다)."
printf '%s\n' "        🔵 화면에는 안 나옵니다 — 앱이 그 파일을 서빙하지 않습니다."
printf '%s\n' ""
printf '%s\n' "🔴 **알고도 안 고친 것 — PO 가 모르는 것이 셋입니다**(55번에서 넘어옴)"
printf '%s\n' "   ① dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 APPROVAL_REQUIRED 가 없습니다."
printf '%s\n' "   ② PO 는 납품일 칸(delivered_date·delivered_by)을 모릅니다."
printf '%s\n' "   ③ PO 는 회차 승인(due_date_row_order)을 모른 채 같은 표를 고칩니다."
printf '%s\n' "   🔵 **지금은 안전합니다** — 운영에서 직원의 PO 접근 권한을 모두 빼 두셨습니다"
printf '%s\n' "      (2026-11-08). 🔴 **PO 를 다시 여는 날 셋을 한 묶음으로 이식해야 합니다.**"
printf '%s\n' "────────────────────────────────────────────────────────────"
