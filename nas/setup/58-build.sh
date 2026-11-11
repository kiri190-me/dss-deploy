#!/bin/bash
# dss-deploy/nas/setup/58-build.sh — 쉰네째 배포 · 이미지 굽기 (2026-11-11)
#
# 🔵 **배포 회차(쉰네째)와 파일 번호(58)가 어긋나는 것은 이 저장소에서 원래
#    그렇다** — 55번 파일이 쉰두째였고 57번이 쉰세째였다. 배너에 둘 다 적어 둔다.
#    (56번은 2026-11-11 의 **양식 전용**이라 배포 번호로 쓰지 않았다.)
#
# 🔴 **판이 4.10 이 아니라 5.0 이다.** 이 저장소의 관례다 — README 에 2.9 → 3.0 ·
#    1.9 → 2.0 사례가 있다. 도구는 16 → 17 로 그냥 하나 는다.
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · PowerShell 에서 Git Bash 를 부른다) ──────────
#     cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#     & "C:\Program Files\Git\bin\bash.exe" ./58-build.sh --check
#     & "C:\Program Files\Git\bin\bash.exe" ./58-build.sh --go
#
#   🔴 **bash.exe 만 치면 WSL 이 잡힌다**(2026-11-04 에 걸렸다). WSL 에서 돌면
#      도커도 양식도 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 내어 ✗ 가
#      셋 흩어져 난다. 단서는 로그의 뿌리 경로가 **/mnt/c/…** 인 것이다.
#   🔴 **스크립트에 건네는 경로에는 역슬래시를 쓰지 않는다.** 역슬래시를 주면
#      bash 가 그것을 먹어 "C:Users희만Desktop…" 이 되어 No such file 이 난다.
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-54):
#     & "C:\Program Files\Git\bin\bash.exe" ./58-build.sh --go "/d/배포본/_images-54"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다.
#      이 파일을 쓴 쪽은 **한 번도 굽지 않았다** — --check 만 돌려 보았다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **57-build.sh 에서 베꼈다가 「이번 판엔 거짓」이라 뒤집은 것 아홉**
# ══════════════════════════════════════════════════════════════════════
#   틀과 절 구성은 57-build.sh(쉰세째)를 그대로 썼다. **57번과 이번은 매우
#   닮았다** — 마이그레이션 0건 · vendor 안 움직임 · 양식 0장 · 포털·PO 안 건드림이
#   전부 같다. 🔴 **닮았다는 것이 곧 위험이다** — 뒤집을 것이 적어서 무심코 베끼면
#   「이 판에서 아무것도 안 재는 ✓」가 조용히 늘어난다.
#   🔴 「배포본은 지난 판의 전제를 업고 온다」가 이 저장소에 기록된 함정이다.
#
#   ① 🔴 **판이 4.10 이 아니라 5.0 이다.** 도구는 16 → 17. 이 저장소의 관례다
#      (README 에 2.9 → 3.0 · 1.9 → 2.0 사례가 있다).
#   ② 🔴 **커밋 5 · 파일 20.** 57번은 4 · 13 이었다. 기준 SHA 도 94895136 이
#      아니라 **4c7eb9fa**(=57번이 올린 HEAD)다.
#   ③ 🔴 **src/ 에 새 파일이 7개다.** 57번은 **0개**였고, 그 파일은
#      「새 파일이 정말 0개인가」를 재고 있었다. 🔴 **그 글을 그대로 베껴 오면
#      멀쩡한 판이 ✗ 다.** 이번엔 반대로 **일곱이 그 일곱 그대로인가**를 재고,
#      도구 이미지 안에서도 **경로 일곱으로** 담겼는지 확인한다.
#      🔵 일곱 = 공용 부품 **둘**(CheckboxFilterDropdown.tsx ·
#         checkbox-filter-dropdown.ts) + 시험 **다섯**.
#      🔴 지시서에는 「다섯(부품 2 + 시험 3)」으로 적혀 있었다 — **실측은 일곱**이다
#         (시험이 셋이 아니라 다섯이다). 세어서 고쳤다.
#   ④ 🔴 **scripts/ 가 2개 바뀐다.** 57번은 **0개**였다. 바뀐 둘은
#      scripts/test-lists/components.txt · unit.txt 다 — 새 시험 다섯을 등록하는
#      목록 파일이고, **그 둘도 tools 스테이지가 담는다**(Dockerfile 68줄).
#   ⑤ 🔴 **tools 바깥에서 바뀐 파일이 0개다.** 57번은 1개(설명 HTML)였다.
#      20개가 **전부 src/ 아니면 scripts/** 다.
#   ⑥ 🔴 **저장소 뿌리의 .html 이 19 → 19 — 안 는다.** 57번은 18 → 19 라 그 수가
#      **앱 이미지에서 판을 가르는 증거**였다. 🔴 **이번 판에는 안 갈린다** —
#      그 글을 베껴 오면 **아무것도 안 재는 ✓** 가 된다. 그래서 그 절을
#      「standalone 이 뿌리 파일을 옮기는가」(0 이면 ✗)로 **뜻을 바꿔** 두고,
#      「이 수로는 이번 판을 못 가른다」를 그 자리에 적어 두었다.
#   ⑦ 🔴 **이미지 안 검사의 증거를 이번 판 것으로 전부 갈았다.** 57번은
#      no-equipment-key · listRepairCaseIdsWithOrderIssuedDate 였다. 이번 판은
#      아래 「증거를 어떻게 골랐나」의 다섯 + 앱 쪽 status=IN_HOUSE 다.
#      🔵 다섯이 **커밋 하나씩을 가른다** — 그렇게 되도록 골랐다(측정으로 확인).
#   ⑧ 🔴 **이번 판의 20개에는 괄호·대괄호가 든 경로가 없다.** 57번은 둘 있었고
#      (src/app/(app)/… · …/[id]/…) 그 때문에 glob 함정 주석이 곳곳에 있다.
#      🔵 **맞대는 방식(grep -Fx · 큰따옴표 · set -f)은 그대로 둔다** — 지금 안
#         걸린다고 방식을 풀면 다음 판에서 조용히 빗나간다. 다만 **「이번 판에
#         그런 경로가 둘 있다」는 글은 거짓이라 고쳤다.**
#   ⑨ 🔵 지난 판 tar 크기 둘을 **이번 판의 상대**(4.9 · tools-16)로 갈았다.
#      출처는 _images-53 에서 stat 한 값이다(2026-11-11 실측).
#
#   ── 🔵 **57번과 같아서 안 뒤집은 것 넷** (그래도 값으로 다시 쟀다)
#      · 마이그레이션 **0건** · DB 기록 **127 그대로**(앞뒤가 같다)
#      · vendor/dss-core · vendor/dss-ui **안 움직였다**(기준판과 지금이 같다)
#      · 양식 **0장** · 포털·PO **안 굽는다**
#      🔴 같다고 절을 지우지 않았다. 「0건·안 움직임·0장」은 **이번 판에서도 참인지
#         재야** 참이다 — 그것이 이 절들이 하는 일이다.
#
# ── 이번에 굽는 것 — **저장소 하나, 이미지 둘** ───────────────────────
#     ① A/S 앱    dss-as:4.9        → **dss-as:5.0**        커밋 5  스테이지 기본(runner)
#     ② A/S 도구  dss-as-tools:16   → **dss-as-tools:17**   커밋 5  🔴 --target tools
#
#   🔴 **셋째 산출물이 없다.** 55번에는 마이그레이션 묶음이 있었다 —
#      **이번 판에도 안 만든다**(마이그레이션 0건).
#      🔵 보험이 필요하면 **이미 있다** — _images-52/as-migrations.tar.gz 가
#         127장이고 md5 가 ddec2e73f6ef979b6983dd929494eab9 다(2026-11-11 재확인).
#      🔴 그래서 **58-deploy.sh 에도 --migrate 모드가 없다**(그 파일 머리말).
#
#   🔴 **포털(dss-auth)은 안 굽는다** — HEAD 가 53번이 구운 f87bf7d 그대로다.
#   🔴 **PO(dss-po)도 안 굽는다** — HEAD 가 기준 SHA(9c1b2ef) 그대로다.
#   🔵 **양식(.xlsx)은 한 장도 안 올린다.** 이번 범위에 .xlsx 변경이 **0줄**이다
#      (8절이 열하나의 바이트·md5 를 다시 잰다).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **도구 이미지를 굽는 까닭 — 마이그레이션 수로 정하지 않는다**
# ══════════════════════════════════════════════════════════════════════
#   잣대는 41·48·52~57번이 쓰던 셋 그대로다:
#     ㄱ) npm 명령이 늘었나   ㄴ) 도구의 import 닫힘 안이 바뀌었나
#     ㄷ) **tools 스테이지가 담는 것 중 바뀐 파일이 있나**
#
#   🔴 **이번 판은 ㄷ 하나만 걸린다. 그런데 그 하나로 충분하다.**
#      RF_Service_System/Dockerfile 의 tools 스테이지가 **src/ 와 scripts/ 를 둘 다
#      통째로 담는다** — [실측 2026-11-11] **68줄** COPY … scripts ./scripts ·
#      **69줄** COPY … src ./src (스테이지는 60줄 FROM … AS tools 에서 시작해
#      90줄 FROM … AS runner 전까지다).
#      이번에 바뀐 20개가 **src/ 18 + scripts/ 2** 라서 **둘 다 걸린다** —
#      도구 이미지의 내용이 달라진다.
#      🔵 아래 5절-ㄱ 이 그 COPY 줄들을 **파일에서 직접 읽어** 줄 번호까지 확인한다.
#      🔴 **마이그레이션 수로 정하지 않는다** — Dockerfile 스테이지가 정한다.
#
#   ㄱ **안 걸린다.** package.json diff **0줄** · scripts 항목 **39 → 39**.
#   ㄴ **안 걸린다.** 57번이 적어 둔 닫힘 아홉 중 바뀐 것 **0개**이고(2026-11-11
#      실측), 이번에 바뀐 모듈을 **scripts/ 가 import 로 부르는 곳도 0개**다.
#      🔴 **글자로는 걸린다** — scripts/test-lists/components.txt 와 unit.txt 에
#         CheckboxFilterDropdown · repair-case-filters · misc-case-list 같은 이름이
#         그대로 적혀 있다. 그것은 **시험 목록 파일**이지 import 가 아니다.
#         그래서 아래 검사는 **/test-lists/ 를 빼고 import 줄로만** 센다.
#      🔴 「소스 글자로 재는 검사는 주석을 먼저 센다」가 이 저장소의 기록이고,
#         이번 판에서는 **주석이 아니라 목록 파일**이 같은 함정을 놓았다.
#   ㄷ **걸린다.** tools 가 담는 것 중 달라진 파일 **20개**(src/ 18 + scripts/ 2).
#      🔵 바깥은 **0개**다 — 57번은 1개(설명 HTML)였다.
#
#   🔴 **지난 배포에서 이 판단을 두 번 틀렸다** — 한 번은 안 구워서 도구 안의
#      비상구 둘이 옛 것이 됐고, 다음엔 반대로 보고 Missing script 가 났다.
#      그래서 이 파일은 **「마이그레이션이 몇 건인가」를 굽기 판정에 안 쓴다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이미지 안 검사 — **증거를 어떻게 골랐나** (먼저 재 보고 골랐다)
# ══════════════════════════════════════════════════════════════════════
#   🔵 **이번 판은 다섯 커밋이 전부 소스를 고친다** — 57번과 달리 「주석만 고친
#      커밋」이 없다. 그래서 **커밋 하나당 표식 하나**를 골라 둘 수 있었다.
#      🔴 아래 다섯은 **각각 한 커밋에서만 생겼다**(git log -S 로 확인 ·
#         2026-11-11 실측). 기준판 4c7eb9fa 의 그 파일에서 전부 **0번**이다.
#
#   ── 도구 이미지(dss-as-tools:17) — 소스가 **글자 그대로** 있다
#      글자                    | 파일                                   | 가르는 커밋
#      status=IN_HOUSE         | components/dashboard/DashboardContent.tsx | 7c02d301
#      IN_HOUSE_STATUSES       | lib/domain/repair-case-filters.ts         | 4edd6a8f
#      isShortcutActive        | components/common/checkbox-filter-dropdown.ts | 82989c74
#      BillingTypeFilterValue  | lib/domain/repair-case-filters.ts         | af816cf7
#      customerNames           | components/misc-cases/MiscCaseFilters.tsx | 242f0f69
#      🔴 마지막 줄이 **마지막 커밋 242f0f69 를 가른다** — MiscCaseFilters.tsx 는
#         이 범위에서 **그 커밋 하나만** 건드렸고, 그 파일에서 customerNames 는
#         기준판 0 → 지금 1 이다.
#      🔵 전부 ASCII 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
#
#   ── 앱 이미지(dss-as:5.0) — .next/standalone 이라 번들된 결과물이다
#      🔴 **안 나오는 것을 기대값으로 박으면 가짜 ✗ 가 난다.**
#      🔴 **이번에는 구운 번들을 못 재 보았다** — 개발 PC 에 .next/standalone 이
#         없다(2026-11-11 확인: .next 는 있으나 standalone 폴더가 없다). 57번은
#         그날 구워 둔 번들에서 세어 보고 골랐다. 🔴 그래서 **하드 게이트를
#         「리터럴이라 minifier 가 못 건드리는 것」 하나로 줄였다.**
#         ① status=IN_HOUSE  — **href 에 들어가는 글자 리터럴**이다
#            ("/repair-cases?status=IN_HOUSE"). 응답 HTML 에 그대로 실려 나가므로
#            번들러가 이름을 바꿀 수 없다. 기준판 src/ 에 **0파일** · 지금 5파일.
#            → **이것만 ✗ 로 센다.**
#         ② no-equipment-key — **뒷걸음 방지**다. 이번 판이 만든 글자가 아니라
#            **쉰세째(57번)가 올린 글자**이고, 57-build.sh 가 2026-11-11 에 구운
#            번들에서 **4 파일**로 실측했다. 기준판에도 지금에도 8파일 있다.
#            → **✗ 로 센다**(더 옛 나무를 구웠는지 가른다).
#         ③ max-h-60 — 새 부품의 Tailwind 클래스 **문자열**이다(기준판 0 → 3파일).
#            리터럴이라 남을 가능성이 높지만 **번들에서 재 보지 못했다.**
#            → **⚠️ 로만 센다.**
#         ④ 「입고품 전체」(한글) — 화면에 나가는 글자라 minifier 가 못 바꾼다.
#            🔴 **명령에 한글을 넣지 않는다** — 컨테이너 안에서 **8진 이스케이프로
#               다시 만들어** 쓴다(16바이트). 만들기가 틀렸을 때 0 이 나와
#               「없다」로 읽히는 길을 막으려고 **바이트 수를 먼저 확인**한다.
#            → **⚠️ 로만 센다**(만드는 길이 하나 더 끼어 있다).
#      🔴 「재서 나왔다」와 「앞으로도 나온다」는 다른 말이다 — ③④ 가 0 이어도
#         ① 이 ✓ 면 판은 맞다. 그 말을 출력에도 적어 둔다.
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
#        dss-as-4.9.tar       134651392  [실측] 2026-11-11 _images-53 에서 stat
#        dss-as-tools-16.tar  225334784  [실측] 2026-11-11 _images-53 에서 stat
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
#   ⑤ 🔴 **대괄호·괄호가 든 경로를 글롭에 넘기지 않는다.**
#      🔵 **이번 판의 20개에는 그런 경로가 하나도 없다**(57번에는 둘 있었다) —
#         그래도 **방식은 그대로 둔다.** 지금 안 걸린다고 풀면 다음 판에서 조용히
#         빗나간다. git 의 **pathspec 은 글롭**이라 「-- "…/[id]/…"」 로 물으면
#         **조용히 0줄**이 돌아온다. 그래서 이 파일은 바뀐 목록을 **한 번만 뽑아
#         두고 grep -Fx 로 맞댄다.**
#      🔴 셸 쪽도 같다 — 목록은 **here 문서 + while read** 로만 돌린다.
#      🔴 컨테이너 안에서도 경로를 **큰따옴표**로 감싸고 set -f 로 글롭을 끈다.
#   ⑥ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」
#      같은 안전망을 달면 **하필 바라던 0 에서만** 그것이 터져 값이 "0 ?" 가 된다.
#      이 파일은 그 꼴을 **한 군데도 쓰지 않는다** — 「$( … || true )」 로 종료 코드만 가린다.
#   ⑦ 🔴 **tar | grep -q 를 if 에 바로 물리지 않는다.** set -uo pipefail 때문에
#      grep -q 가 먼저 끝나면 앞의 tar 가 SIGPIPE 로 죽고 **파일이 있을 때 오히려
#      ✗** 가 난다(2026-11-07 쉰째에서 실제로 났다). **세어서 담고 비교하는 꼴**로만 쓴다.
#      🔵 이번 판에도 묶음이 없어 tar 를 읽는 자리가 **하나**뿐이다(tar_config_id).
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
#      🔴 **이번 판도 0 이다.** 🔴 「0 이면 통과」가 아니라 **적어 둔 수와
#         똑같아야** 한다 — 늘었으면 이 배포의 전제가 깨진 것이다.
#   🔵 일곱째 칸(커밋 수)은 ✗ 로 세지 않고 ⚠️ 로만 센다. A/S **다섯**이다.
#   🔴 'astools' 는 **같은 저장소**를 --target tools 로 한 번 더 굽는 줄이다.
#   🔵 열째 칸: strict = 25% 넘으면 ✗ · loose = 25% ⚠️ · 60% 넘으면 ✗ (머리말).
SITES='
as|RF_Service_System|dss-as:5.0|4c7eb9fa|-|0|5|134651392|dss-as-4.9.tar|strict
astools|RF_Service_System|dss-as-tools:17|4c7eb9fa|tools|0|5|225334784|dss-as-tools-16.tar|strict
'
HOWMANY=2
AS_APP_TAG=dss-as:5.0
AS_TOOLS_TAG=dss-as-tools:17
# 🔵 되돌릴 판 — 58-deploy.sh --rollback 이 쓰는 그것이다.
#    🔴 **4.10 이 아니라 5.0 이다** — 이 저장소의 판 올리기 관례(README).
AS_OLD_TAG=dss-as:4.9
AS_TOOLS_OLD_TAG=dss-as-tools:16

# ── 🔴 기대값과 그 출처 — 전부 [실측] 2026-11-11 개발 PC ───────────────
#   🔴 기준 SHA 는 **출처 둘을 맞대어** 확인했다:
#      ㄱ) 57-build.sh 가 올린 HEAD 가 4c7eb9fa 다(그 파일의 AS_HEAD_FULL).
#      ㄴ) dss-deploy/README.md 의 쉰세째 기록도 범위를 94895136..**4c7eb9fa**
#          로 적고 판을 4.9 로 적는다. **둘이 맞았다.**
AS_BASE=4c7eb9fa
AS_HEAD_SHORT=242f0f69
AS_HEAD_FULL=242f0f69d3655a2bc169f1042d73f9a661aee40e
AUTH_BASE=f87bf7d
PO_BASE=9c1b2ef

# 🔴 A/S drizzle — **127 그대로.** 이번 판에도 새 마이그레이션이 없다.
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
#    🔴 **dss-core 는 이번 판에도 안 움직였다** (기준판과 지금이 둘 다 6688e5d).
AS_CORE_PIN=6688e5d71939d8f36fc89eedfeb1e5b437bd9bb2
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425
PO_CORE_PIN=8730c9433b4388a038349ab9a11ec633659da782

# 🔵 A/S — 저장소 전체 **20** · tools 스테이지가 담는 것 **20** · 바깥 **0**.
#    🔴 57번은 13 · 12 · 1(설명 HTML) 이었다. **이번 판은 바깥이 0 이다** —
#       20개가 전부 src/(18) 아니면 scripts/(2) 다.
AS_ALL_CHANGED_WANT=20
AS_TOOLS_CHANGED_WANT=20
AS_OUTSIDE_WANT=0
# 🔴 바깥이 0 이므로 drizzle/ 도 당연히 0 이다. 그래도 **따로 센다** —
#    「바깥이 0」과 「drizzle 이 0」은 한쪽만 깨질 수 있는 다른 말이다.
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

# ══ 🔴 A/S 도구 닫힘 — **이번 판에도 하나도 안 바뀌었다** ══════════════
#   🔵 2026-11-11 실측(아홉 다 저장소에 있고, 이번 범위에서 바뀐 것은 0개).
#   🔴 **그 파일이 아직 저장소에 있나** 가드를 그대로 둔다 — 이름이 바뀌었는데
#      0 이 나와 「안 바뀌었다」로 조용히 지나가는 길을 막는다.
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

# ══ 🔴 **이번 판이 바꾼 20개** — tools 이미지가 담는 자리다 ════════════
#   🔵 src/ **18** + scripts/ **2**. 🔴 57번은 src/ 12 · scripts/ 0 이었다.
#   🔵 **괄호·대괄호가 든 경로가 하나도 없다**(57번에는 둘 있었다) — 그래도
#      맞대는 방식은 그대로 쓴다(머리말 ⑧).
#   🔴 이 중 **일곱이 A(새로 생긴 것)** 다 — 아래 AS_BORN_SRC 가 그 일곱이다.
AS_CHANGED_SRC='
src/components/common/CheckboxFilterDropdown.test.tsx
src/components/common/CheckboxFilterDropdown.tsx
src/components/common/checkbox-filter-dropdown.test.ts
src/components/common/checkbox-filter-dropdown.ts
src/components/dashboard/DashboardContent.tsx
src/components/misc-cases/MiscCaseFilters.tsx
src/components/misc-cases/MiscCaseListScreen.tsx
src/components/misc-cases/misc-case-list-screens.test.tsx
src/components/misc-cases/misc-case-multi-select-filters.test.ts
src/components/repair-cases/FilterDisclosure.test.tsx
src/components/repair-cases/RepairCaseFilters.tsx
src/components/repair-cases/RepairCaseListPage.tsx
src/components/repair-cases/repair-case-multi-select-filters.test.ts
src/lib/domain/in-house-filter-matches-dashboard.test.ts
src/lib/domain/misc-case-list.test.ts
src/lib/domain/misc-case-list.ts
src/lib/domain/repair-case-filters.test.ts
src/lib/domain/repair-case-filters.ts
'
AS_CHANGED_SRC_WANT=18
# 🔴 **scripts/ 쪽 둘** — 57번에는 이 목록 자체가 없었다(scripts/ 변경 0개).
#    🔵 새 시험 다섯을 등록하는 **목록 파일**이다. 이 저장소의 시험은 글롭이 아니라
#       이 파일에 적어야 돌므로, 빠지면 **오류 없이 조용히 안 돈다.**
#    🔴 그리고 tools 스테이지가 scripts/ 를 통째로 담으므로(Dockerfile 68줄)
#       **도구 이미지의 내용이 이 둘 때문에도 달라진다.**
AS_CHANGED_SCRIPTS='
scripts/test-lists/components.txt
scripts/test-lists/unit.txt
'
AS_CHANGED_SCRIPTS_WANT=2
# 🔴 **이번에 새로 생긴 일곱** — 57번은 0개라 그 파일은 「0개인가」를 재고 있었다.
#    🔴 그 글을 베껴 오면 멀쩡한 판이 ✗ 다. 이번엔 **일곱이 그 일곱인가**를 잰다.
#    🔵 공용 부품 둘 + 시험 다섯. (지시서는 「다섯(부품 2 + 시험 3)」이라 적었지만
#       실측은 일곱이다 — 시험이 다섯이다.)
AS_BORN_SRC='
src/components/common/CheckboxFilterDropdown.test.tsx
src/components/common/CheckboxFilterDropdown.tsx
src/components/common/checkbox-filter-dropdown.test.ts
src/components/common/checkbox-filter-dropdown.ts
src/components/misc-cases/misc-case-multi-select-filters.test.ts
src/components/repair-cases/repair-case-multi-select-filters.test.ts
src/lib/domain/in-house-filter-matches-dashboard.test.ts
'
AS_BORN_SRC_WANT=7
# 🔵 새 파일은 **전부 src/ 안**이다 — 저장소 뿌리에는 한 장도 안 생겼다.
AS_BORN_ROOT_WANT=7
# 🔴 [실측] 2026-11-11 — git -c core.quotePath=false ls-tree --name-only <ref> -- .
#    🔵 한글 파일명이라 **quotePath 를 꺼야** 센다. 안 끄면 git 이 "\354…" 로
#       따옴표를 둘러 내보내어 '.html$' 가 안 맞고 **조용히 0** 이 나온다.
#    🔴 **이번 판은 19 → 19 다 — 안 는다.** 57번은 18 → 19 였고 그 수가 앱
#       이미지에서 판을 가르는 증거였다. **이 판에서는 아무것도 안 가른다** —
#       그래서 아래 이미지 안 검사에서 그 절의 **뜻을 바꿨다**(머리말 ⑥).
AS_ROOT_HTML_WAS=19
AS_ROOT_HTML_NOW=19

# ══ 🔴 「이번 판인가」를 글자로 가르는 표식 다섯 ═══════════════════════
#   🔴 전부 **기준판(4c7eb9fa)의 그 파일에 0번 · 지금 판에 1번 이상**이다
#      (2026-11-11 실측). 이름은 모두 ASCII 다.
#   🔴 **다섯이 커밋 하나씩을 가른다** — git log -S 로 확인했다:
#        status=IN_HOUSE        → 7c02d301 (대시보드 카드의 href)
#        IN_HOUSE_STATUSES      → 4edd6a8f (「입고품 전체」가 펼쳐지는 상태 열하나)
#        isShortcutActive       → 82989c74 (단축 단추를 **눌린 토글**로)
#        BillingTypeFilterValue → af816cf7 (나머지 네 필터도 복수 선택)
#        customerNames          → 242f0f69 (기타건 두 필터 · **마지막 커밋**)
#   형식: 글자|파일
AS_MARKS='
status=IN_HOUSE|src/components/dashboard/DashboardContent.tsx
IN_HOUSE_STATUSES|src/lib/domain/repair-case-filters.ts
isShortcutActive|src/components/common/checkbox-filter-dropdown.ts
BillingTypeFilterValue|src/lib/domain/repair-case-filters.ts
customerNames|src/components/misc-cases/MiscCaseFilters.tsx
'
AS_MARKS_WANT=5

# 🔴 **구운 앱 이미지 안에서 쓸 표식.** 기준판 src/ 에 **0파일** · 지금 판에 5파일.
#    🔵 번들에 남는 까닭: href 에 들어가는 **글자 리터럴**("/repair-cases?status=
#       IN_HOUSE")이라 minifier 가 이름을 바꿀 수 없다.
#    🔴 **이번에는 구운 번들에서 못 재 보았다**(개발 PC 에 .next/standalone 이 없다).
#       그래서 앱 쪽 하드 게이트는 **이것과 아래 KEEP_MARK 둘뿐**이다.
BUILD_MARK=status=IN_HOUSE
# 🔵 **뒷걸음 방지** — **쉰세째(57번)가 올린 글자**다. 이번 판이 만든 것이 아니다.
#    기준판에도 지금 판에도 src/ 에 8파일 있고, 57-build.sh 가 2026-11-11 에 구운
#    번들에서 **4 파일**로 실측했다. 그래서 이것은 ✗ 로 세도 된다.
KEEP_MARK=no-equipment-key
# 🔵 ⚠️ 로만 세는 보조 표식 — 새 부품의 Tailwind 클래스 **문자열**이다.
#    리터럴이라 남을 가능성이 높지만 **번들에서 재 보지 못했다.**
SOFT_MARK=max-h-60
# 🔵 ⚠️ 로만 세는 보조 표식 둘째 — 화면에 나가는 **한글** 글자 「입고품 전체」.
#    🔴 **명령에 한글을 넣지 않는다**(머리말 함정 ④). 컨테이너 안에서 8진
#       이스케이프로 다시 만들어 쓴다. 만들기가 틀리면 0 이 나와 「없다」로 읽히므로
#       **바이트 수(16)를 먼저 확인**하고, 16 이 아니면 ⚠️ 로 「못 쟀다」라고 말한다.
#    [실측 2026-11-11] 이 이스케이프가 16바이트 · src/ 에 10파일 · 기준판 0파일.
SOFT_MARK_KO_OCT='\354\236\205\352\263\240\355\222\210 \354\240\204\354\262\264'
SOFT_MARK_KO_BYTES=16

# 🔴 **도구 셋이 아직 읽기만 하는가** — 54번이 올린 그 셋이다. 부르는 꼴로 센다.
#    🔴 '--apply' 글자로 재지 않는다 — check-delivered-date-sync.ts 의 **주석**에
#       그 낱말이 1번 나와서, 그렇게 재면 멀쩡한 도구가 ✗ 가 된다.
#    🔵 이번 판이 만든 도구는 **없다**(scripts/ 에서 바뀐 둘은 시험 목록 파일이다).
#       그래도 계속 재는 까닭은 「한 번 열리면 아무도 안 닫는다」이다.
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
#   🔴 **이번 판에도 올릴 양식이 없다.** 열하나가 전부 55·57번이 적어 둔 값
#      그대로여야 한다. 🔵 이번 범위에 .xlsx 변경이 **0줄**이다(아래 8절이 저장소
#      쪽에서도 따로 확인한다). 🔴 그래도 **파일 자체는 다시 잰다** — 양식은
#      저장소에 없고 사람이 따로 고칠 수 있다.
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
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-54"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

ASDIR="$DEV/RF_Service_System"
AUTHDIR="$DEV/dss-auth"
PODIR="$DEV/dss-po"
COREDIR="$ASDIR/vendor/dss-core"

printf '%s\n' "쉰네째 배포 · 이미지 굽기 (파일 번호 58)   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  🔵 회차(쉰네째)와 파일 번호(58)가 어긋나는 것은 이 저장소에서 원래 그렇다 — 57번이 쉰세째였다."
printf '%s\n' "  🔴 판이 **4.10 이 아니라 5.0** 이다 — 이 저장소의 관례(README 의 2.9→3.0 · 1.9→2.0)."
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  저장소 뿌리: $DEV"
printf '%s\n' "  tar 둘을 둘 자리: $OUT"
printf '%s\n' "  굽는 것: $AS_APP_TAG · $AS_TOOLS_TAG  (저장소 **하나** · 이미지 **둘**)"
printf '%s\n' "  올릴 HEAD: A/S $AS_HEAD_SHORT (기준 $AS_BASE 이후 커밋 5 · 파일 20)"
printf '%s\n' "     🔵 파일 20 = src/ $AS_CHANGED_SRC_WANT + scripts/ $AS_CHANGED_SCRIPTS_WANT · 그중 **새 파일 $AS_BORN_SRC_WANT 개**"
printf '%s\n' "  🔵 **마이그레이션 0건** — 저장소도 운영 볼륨도 $AS_SQL_WANT 그대로다 (4절)"
printf '%s\n' "     🔵 **묶음(as-migrations.tar.gz)을 안 만들고 안 보낸다.**"
printf '%s\n' "  🔵 공용 스키마 vendor/dss-core 가 **안 움직였다** — ${AS_CORE_PIN:0:7} 그대로 (3절)"
printf '%s\n' "  🔴 도구를 굽는 까닭은 **Dockerfile 의 tools 스테이지가 src/ 와 scripts/ 를 둘 다**"
printf '%s\n' "     **통째로 담기 때문**이다 (68·69줄 — 5절-ㄱ 이 줄 번호까지 읽어 확인한다)"
printf '%s\n' "     🔵 npm 명령은 안 늘었고($AS_NPM_WAS → $AS_NPM_NOW) 도구 닫힘도 **0개** 바뀌었다."
printf '%s\n' "  🔵 포털(dss-auth)은 **안 굽는다** — HEAD 가 53번이 구운 $AUTH_BASE 그대로다(2절)"
printf '%s\n' "  🔵 PO 도 **안 굽는다** — HEAD 가 기준 $PO_BASE 그대로다(2절)"
printf '%s\n' "  🔵 양식은 **0장** — 열하나가 55·57번 값 그대로다(8절)"
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
      printf '%s\n' "         58-deploy.sh 꼬리말의 「볼 곳」과 5절의 파일 목록이다 — 사람이 보세요."
      git -C "$DIR" log --oneline "$BASE..HEAD" 2>/dev/null | head -12 | sed 's/^/      /'
    fi
    # 🔴 「0 이면 통과」가 아니다. 적어 둔 수와 **똑같아야** 한다.
    #    🔵 이번 판은 그 수가 0 이다 — **마이그레이션이 0건이라는 말의 근거 하나**다.
    if [ "${m:-x}" = "$WANTMIG" ]; then
      printf '  ✓ %s drizzle/ 에서 달라진 파일 %s개 — 적어 둔 그대로 (**마이그레이션 0건**의 근거 ①)\n' "$REPO" "$m"
    else
      printf '  ✗ %s drizzle/ 에서 달라진 파일 %s개 — **%s개를 기대했다**. 멈추고 알릴 것\n' "$REPO" "${m:-?}" "$WANTMIG"
      printf '%s\n' "      🔴 늘었다면 **이 배포는 묶음을 안 보낸다는 전제로 쓰였다** — 58-deploy.sh 에는"
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

# ── 3. 🔴 서브모듈 — 이번에도 **dss-core 가 안 움직였다** ─────────────
printf '\n== 3. 서브모듈 (🔵 이번 판에도 dss-core 가 **안 움직였다** — 57번과 같다)\n'
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
#    🔵 55번은 여기가 반대였다(기준판이 옛 값이어야 「움직였다」가 섰다). 57번이
#       이미 뒤집어 두었고 **이번 판도 같은 쪽**이다.
#    🔴 이 절은 「같은가」를 **값으로** 재므로, 움직인 판에서 베껴 가면 그 자리에서
#       ✗ 가 난다 — 그때는 55-build.sh 의 3-ㄴ 절을 되살리라는 뜻이다.
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
  ok "${AS_SQL_WANT}장이다 — 🔵 55번이 올린 $AS_PROD_SQL_NOW **그대로**다 (57번도 안 건드렸다)"
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
  say "🔴 이 배포에도 **묶음도 --migrate 모드도 없다.** 생겼다면 55번 판을 되살려야 한다."
  doubt
fi
if [ -s "$ASDIR/drizzle/$AS_LAST_MIG_FILE" ]; then
  ok "drizzle/$AS_LAST_MIG_FILE 이 있다 (55번이 올린 마지막 — 57번에 이어 이번 판의 마지막이기도 하다)"
else
  bad "🔴 drizzle/$AS_LAST_MIG_FILE 이 **없다**"
  ls -1 "$ASDIR/drizzle/${AS_LAST_MIG}_"*.sql 2>/dev/null | sed 's/^/      /'
  doubt
fi
if ls -1 "$ASDIR/drizzle/${AS_NEXT_MIG}_"*.sql >/dev/null 2>&1; then
  bad "🔴 drizzle 에 $AS_NEXT_MIG 번이 **생겼다** — 이 배포는 **$AS_LAST_MIG 까지**를 전제로 쓰였다"
  say "🔴 58-deploy.sh 에는 --migrate 모드가 **없다.** 멈추고 알릴 것."
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
printf '%s\n' "       🔴 그래도 **운영 볼륨이 127 인지는 58-deploy.sh 가 잰다** — 마이그레이션은"
printf '%s\n' "          이미지 안이 아니라 **볼륨에서** 돈다. 이미지만 세면 0건으로 조용히 끝난다."
printf '%s\n' "       🔵 보험이 필요하면 이미 있다: _images-52/as-migrations.tar.gz (127장 ·"
printf '%s\n' "          md5 ddec2e73f6ef979b6983dd929494eab9 — 2026-11-11 재확인)."
printf '%s\n' "          55-deploy.sh --migrate 가 그것을 푼다."

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 담는 길 · 도구 판정 · 소스가 새 코드를 담고 있나 ────────────
# ══════════════════════════════════════════════════════════════════════
#  🔴 .dockerignore 나 Dockerfile 이 어긋나면 이미지는 멀쩡히 구워지고 **바뀐
#     코드만 조용히 빠진다.** 그래서 담는 길부터 센다.
#  🔴 **이번 판도 이 절이 굽는 까닭 전부를 쥐고 있다** — ㄱ·ㄴ 이 안 걸리고
#     ㅁ(담기는 것) 하나만 걸린다. 🔵 57번과 다른 것은 **담기는 것이 src/ 뿐이
#     아니라는 점**이다 — scripts/test-lists 둘도 함께 걸린다.
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
check_copy "$ASDIR/Dockerfile" '^COPY .*scripts \./scripts'   yes "🔴 A/S tools 가 **scripts/ 를 통째로 담는다** — 이번에 바뀐 test-lists 둘이 여기다 (**굽는 까닭 ①**)"
check_copy "$ASDIR/Dockerfile" '^COPY .*package\.json'        yes "A/S tools 가 package.json·tsconfig.json 을 담는다"
check_copy "$ASDIR/Dockerfile" '^COPY .*src \./src'           yes "🔴 A/S tools 가 **src/ 를 통째로 담는다** — 이번에 바뀐 18개가 전부 여기다 (**굽는 까닭 ②**)"
check_copy "$ASDIR/Dockerfile" '^COPY .*vendor \./vendor'     yes "A/S tools 가 vendor/ 를 담는다 (🔵 이번 판에도 그 안이 안 바뀌었다)"
check_copy "$ASDIR/Dockerfile" '^COPY .*drizzle \./drizzle'   no  "A/S tools 는 drizzle/ 을 **안 담는다** (🔵 그래서 마이그레이션은 볼륨에서 돈다)"
# 🔴 그 COPY 줄들이 **tools 스테이지 안**에 있는가 — 줄번호로 가른다. 바깥에 있으면
#    위 grep 은 통과하는데 도구에는 안 담긴다.
#    🔴 **이번 판은 scripts/ 쪽도 함께 가른다** — 57번은 src/ 만 봤다. 이번에 바뀐
#       20개 중 둘이 scripts/ 라, 그 COPY 가 스테이지 밖이면 그 둘이 조용히 빠진다.
LT=$(grep -n '^FROM .* AS tools'  "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
LR=$(grep -n '^FROM .* AS runner' "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
LS=$(grep -n '^COPY .*src \./src' "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
LC=$(grep -n '^COPY .*scripts \./scripts' "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
say "tools ${LT:-?}줄 · 'COPY … scripts ./scripts' ${LC:-?}줄 · 'COPY … src ./src' ${LS:-?}줄 · runner ${LR:-?}줄"
say "🔵 [실측 2026-11-11] 그 자리는 tools 60 · scripts 68 · src 69 · runner 90 이다."
if isnum "${LT:-}" && isnum "${LS:-}" && isnum "${LR:-}" && [ "$LT" -lt "$LS" ] && [ "$LS" -lt "$LR" ]; then
  ok "src/ 를 담는 COPY 가 **tools 스테이지 안**에 있다 (${LS}줄)"
else
  bad "🔴 'COPY … src ./src' 가 tools 스테이지 안이 아니다 (tools ${LT:-?} · COPY ${LS:-?} · runner ${LR:-?})"
  say "🔴 그러면 **이번에 바뀐 src/ 18개가 도구에 안 담긴다** — 판정을 다시 해야 한다. 멈추고 알릴 것."
  doubt
fi
if isnum "${LT:-}" && isnum "${LC:-}" && isnum "${LR:-}" && [ "$LT" -lt "$LC" ] && [ "$LC" -lt "$LR" ]; then
  ok "scripts/ 를 담는 COPY 가 **tools 스테이지 안**에 있다 (${LC}줄 — 🔴 이번 판은 여기도 걸린다)"
else
  bad "🔴 'COPY … scripts ./scripts' 가 tools 스테이지 안이 아니다 (tools ${LT:-?} · COPY ${LC:-?} · runner ${LR:-?})"
  say "🔴 그러면 **이번에 바뀐 test-lists 둘이 도구에 안 담긴다.** 멈추고 알릴 것."
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
    bad "🔴 A/S 의 .dockerignore 가 scripts/ 를 막는다 — 도구가 통째로 빠지고 **이번에 바뀐 test-lists 둘도 빠진다**"
  else
    ok "A/S 의 .dockerignore 가 scripts/ 를 막지 않는다 (이번에 바뀐 test-lists 둘이 들어간다)"
  fi
  if grep -qE '^src/?$' "$DIG" 2>/dev/null; then
    bad "🔴 A/S 의 .dockerignore 가 src/ 를 막는다 — **이번에 고친 18개가 통째로 빠진다**"
  else
    ok "A/S 의 .dockerignore 가 src/ 를 막지 않는다 (이번에 고친 18개가 들어간다)"
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
#   🔵 **이번 판의 20개에는 괄호·대괄호가 없다**(57번에는 둘 있었다). 그래도 표본은
#      **괄호·대괄호가 든 경로로 둔다** — 잣대가 살아 있는지 재는 자리이지 이번 판의
#      목록을 재는 자리가 아니다. 다음 판에 그런 경로가 돌아와도 이 줄이 먼저 운다.
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
# 🔴 **이번 판의 목록에 괄호·대괄호가 정말 없는가** — 머리말 ⑧ 의 주장을 값으로 잰다.
#    🔵 있으면 ⚠️ 다(막지 않는다) — 다만 머리말의 그 글이 거짓이 된다.
BRK=$(printf '%s\n' "$AS_CHANGED_SRC" "$AS_CHANGED_SCRIPTS" | grep -c '[][()]' || true)
say "이번 판의 목록에서 괄호·대괄호가 든 경로 ${BRK:-0}개 (기대 0 — 🔵 57번은 2 였다)"
if [ "${BRK:-x}" = "0" ]; then
  ok "이번 판의 목록에는 괄호·대괄호가 든 경로가 없다 (머리말 ⑧ 이 참이다)"
else
  note "괄호·대괄호가 든 경로가 ${BRK}개다 — 머리말 ⑧ 을 고쳐야 한다. **굽기는 막지 않는다**"
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
# 🔴 **반대 방향으로도 한 번 더 센다** — 이번에 바뀐 모듈을 scripts/ 가 부르는가.
#    🔴 **이번 판에서는 글자로 다섯이 걸리는데 전부 scripts/test-lists/*.txt 다** —
#       그것은 **시험 목록 파일**이지 import 가 아니다(2026-11-11 실측:
#       CheckboxFilterDropdown · checkbox-filter-dropdown · repair-case-filters ·
#       misc-case-list · dashboard-metrics 가 거기 적혀 있다).
#       57번에서는 같은 함정이 **주석**이었다. 재는 길은 같다 — **import 줄로만** 센다.
#    🔵 아래 표본이 그 가름이 살아 있는지 먼저 보여 준다.
printf '\n  ── 🔴 이번에 바뀐 것을 scripts/ 가 **import 로** 부르는가 (기대 0 · 목록 파일은 안 센다)\n'
RAW_HIT=0; IMP_HIT=0
for key in CheckboxFilterDropdown checkbox-filter-dropdown repair-case-filters misc-case-list dashboard-metrics in-house-filter; do
  n=$(grep -rlE "^import .*$key|from \"[^\"]*$key" "$ASDIR/scripts" 2>/dev/null | grep -v '/test-lists/' | wc -l | tr -d ' ')
  r=$(grep -rl "$key" "$ASDIR/scripts" 2>/dev/null | wc -l | tr -d ' ')
  printf '      %-30s import %s개 · (참고) 글자만 든 파일 %s개\n' "$key" "${n:-0}" "${r:-0}"
  IMP_HIT=$((IMP_HIT + ${n:-0}))
  RAW_HIT=$((RAW_HIT + ${r:-0}))
done
say "scripts/ 가 이번 판의 모듈을 import 하는 파일 ${IMP_HIT}개 (기대 0)"
say "🔵 글자만 든 파일은 ${RAW_HIT}개다 — **전부 scripts/test-lists/*.txt 라고 적어 두었다.**"
if [ "$IMP_HIT" = "0" ]; then
  ok "도구는 이번에 바뀐 코드를 **부르지 않는다** — 🔵 그래서 도구의 **동작**은 안 바뀐다"
  say "🔴 그래도 굽는다 — **담기는 것이 달라지기 때문**이다(Dockerfile 68·69줄). 그 둘은 다른 말이다."
else
  note "scripts/ 가 ${IMP_HIT}개 부른다 — 0 을 적어 두었다. 🔵 굽는 판정은 안 흔들린다. 사람이 보세요"
fi
# 🔴 **글자만 든 파일이 정말 목록 파일뿐인가** — 「주석이라서/목록이라서 안 센다」를
#    값으로 받쳐 둔다. 그러지 않으면 위 「import 0개」가 공짜 통과처럼 보인다.
RAW_OUT=$(grep -rl 'CheckboxFilterDropdown\|checkbox-filter-dropdown\|repair-case-filters\|misc-case-list\|dashboard-metrics\|in-house-filter' "$ASDIR/scripts" 2>/dev/null | grep -vc '/test-lists/' || true)
say "그중 test-lists 밖의 파일 ${RAW_OUT:-0}개 (기대 0)"
if [ "${RAW_OUT:-x}" = "0" ]; then
  ok "글자가 걸린 곳이 **전부 scripts/test-lists/ 안**이다 (목록 파일이지 import 가 아니다)"
else
  note "test-lists 밖에서도 ${RAW_OUT}개 걸린다 — 0 을 기대했다. 사람이 그 파일을 보세요"
  grep -rl 'CheckboxFilterDropdown\|checkbox-filter-dropdown\|repair-case-filters\|misc-case-list\|dashboard-metrics\|in-house-filter' "$ASDIR/scripts" 2>/dev/null | grep -v '/test-lists/' | head -5 | sed 's/^/      /'
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
# 🔴 **이번 판은 바깥이 0 이다** — 57번은 1(설명 HTML)이었고 55번은 5(전부 drizzle/)였다.
OUTSIDE=$((${AS_ALL_CHANGED:-0} - ${AS_TOOLS_CHANGED:-0}))
say "A/S  tools 바깥에서 달라진 파일 ${OUTSIDE}개 (적어 둔 수 $AS_OUTSIDE_WANT — **20개가 전부 src/ 나 scripts/ 다**)"
if [ "${AS_TOOLS_CHANGED:-x}" = "$AS_TOOLS_CHANGED_WANT" ] && [ "${AS_ALL_CHANGED:-x}" = "$AS_ALL_CHANGED_WANT" ]; then
  ok "담기는 것 ${AS_TOOLS_CHANGED_WANT} · 전체 ${AS_ALL_CHANGED_WANT} · 바깥 ${AS_OUTSIDE_WANT} — 적어 둔 그대로"
else
  note "담기는 것 ${AS_TOOLS_CHANGED:-?} · 전체 ${AS_ALL_CHANGED:-?} · 바깥 ${OUTSIDE} 다 — 적어 둔 것은 ${AS_TOOLS_CHANGED_WANT}·${AS_ALL_CHANGED_WANT}·${AS_OUTSIDE_WANT} 다"
  printf '%s\n' "      ── 바깥에서 바뀐 것"
  printf '%s\n' "$CHANGED_ALL" \
    | grep -vE '^(scripts/|src/|package\.json$|drizzle\.config\.ts$|tsconfig\.json$|vendor/)' | head -10 | sed 's/^/      /'
fi
# 🔴 **drizzle/ 이 0 인가** — 바깥이 0 이면 당연히 0 이지만 **따로 센다.**
#    🔵 한쪽만 깨질 수 있는 다른 말이다(예: drizzle/ 이 늘고 바깥 셈이 어긋난 경우).
NDRZ=$(printf '%s\n' "$CHANGED_ALL" | grep -c '^drizzle/' || true)
say "drizzle/ 에서 바뀐 파일 ${NDRZ:-0}개 (기대 $AS_OUTSIDE_DRIZZLE_WANT — 🔵 55번은 5 였다)"
if [ "${NDRZ:-x}" = "$AS_OUTSIDE_DRIZZLE_WANT" ]; then
  ok "drizzle/ 에서 바뀐 파일이 ${AS_OUTSIDE_DRIZZLE_WANT}개다 — **마이그레이션 0건**의 근거 ③"
else
  bad "🔴 drizzle/ 에서 ${NDRZ}개가 바뀌었다 — ${AS_OUTSIDE_DRIZZLE_WANT}개를 기대했다. **묶음이 필요한 판이다**"
  doubt
fi
# 🔴 **바깥이 정말 비었는가** — 0 이면 아래 목록이 한 줄도 안 나와야 한다.
#    🔵 57번은 여기서 설명 HTML 하나를 찍었다. **이번 판은 빈 것이 정답**이라,
#       「빈 결과는 삼켜진 오류일 수 있다」를 피하려고 **수를 함께** 찍는다.
OUTLIST=$(printf '%s\n' "$CHANGED_ALL" \
  | grep -vE '^(scripts/|src/|package\.json$|drizzle\.config\.ts$|tsconfig\.json$|vendor/)' || true)
OUTN=$(printf '%s\n' "$OUTLIST" | grep -c . || true)
say "── tools 바깥의 목록 ${OUTN:-0}줄 (기대 $AS_OUTSIDE_WANT — 비어 있는 것이 정답이다)"
printf '%s\n' "$OUTLIST" | grep -v '^[[:space:]]*$' | head -5 | sed 's/^/      /'
if [ "${OUTN:-x}" = "$AS_OUTSIDE_WANT" ]; then
  ok "tools 바깥에서 바뀐 파일이 ${AS_OUTSIDE_WANT}개다 — 🔵 그래서 **앱 이미지에만 담기는 변경이 없다**"
else
  note "바깥 목록이 ${OUTN:-?}줄이다 — ${AS_OUTSIDE_WANT}줄을 기대했다. 위 목록을 사람이 보세요"
fi

# ── ㅂ) 🔴 이번 판이 바꾼 **20개가 정말 그 스무 개인가** ──────────────
#   🔴 「담기는 것이 20개다」와 「그 20개가 내가 아는 20개다」는 다른 말이다.
#   🔴 **src/ 18 과 scripts/ 2 를 따로 센다** — 57번에는 scripts/ 쪽이 없었다.
printf '\n  ── 🔴 이번 판이 바꾼 src/ 파일 %s개가 **그 열여덟 그대로인가**\n' "$AS_CHANGED_SRC_WANT"
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
  ok "src/ 변경 ${AS_CHANGED_SRC_WANT}개가 적어 둔 열여덟과 **정확히 같다** (더도 덜도 없다)"
else
  bad "🔴 적어 둔 ${SRC_SEEN} · 맞은 것 ${SRC_OK} · 실제 ${NSRC:-?} 다 — 셋 다 ${AS_CHANGED_SRC_WANT} 여야 한다"
  printf '%s\n' "$CHANGED_SRC" | head -20 | sed 's/^/      /'
  doubt
fi
# 🔴 **scripts/ 쪽 둘** — 57번에는 이 절이 아예 없었다(scripts/ 변경 0개).
#    🔴 여기가 빠지면 「도구를 굽는 까닭 ①」이 **아무 데서도 안 재진다.**
printf '\n  ── 🔴 이번 판이 바꾼 scripts/ 파일 %s개 (🔵 57번은 0개라 이 절이 없었다)\n' "$AS_CHANGED_SCRIPTS_WANT"
CHANGED_SCR=$(printf '%s\n' "$CHANGED_ALL" | grep '^scripts/' || true)
SCR_SEEN=0; SCR_OK=0
while IFS= read -r f; do
  [ -n "${f:-}" ] || continue
  SCR_SEEN=$((SCR_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 지금 저장소에 없다 — 목록이 낡았다"; continue
  fi
  if printf '%s\n' "$CHANGED_SCR" | grep -Fxq "$f"; then
    SCR_OK=$((SCR_OK+1)); say "🔴 바뀌었다 · 도구 이미지에 담긴다 — $f"
  else
    bad "🔴 $f 가 **이번 범위에서 안 바뀌었다** — 목록이 낡았다"
  fi
done <<SCREOF
$(printf '%s\n' "$AS_CHANGED_SCRIPTS" | grep -v '^[[:space:]]*$')
SCREOF
NSCR=$(printf '%s\n' "$CHANGED_SCR" | grep -c . || true)
say "적어 둔 ${SCR_SEEN}개 중 실제로 바뀐 것 ${SCR_OK}개 · 범위의 scripts/ 변경은 ${NSCR:-0}개"
if [ "$SCR_SEEN" = "$AS_CHANGED_SCRIPTS_WANT" ] && [ "$SCR_OK" = "$AS_CHANGED_SCRIPTS_WANT" ] && [ "${NSCR:-x}" = "$AS_CHANGED_SCRIPTS_WANT" ]; then
  ok "scripts/ 변경 ${AS_CHANGED_SCRIPTS_WANT}개가 적어 둔 그 둘과 **정확히 같다**"
  say "🔵 둘 다 **시험 목록 파일**이다 — 이 저장소의 시험은 글롭이 아니라 이 목록에"
  say "   적어야 돌므로, 빠지면 **오류 없이 조용히 안 돈다.**"
else
  bad "🔴 적어 둔 ${SCR_SEEN} · 맞은 것 ${SCR_OK} · 실제 ${NSCR:-?} 다 — 셋 다 ${AS_CHANGED_SCRIPTS_WANT} 여야 한다"
  printf '%s\n' "$CHANGED_SCR" | head -10 | sed 's/^/      /'
  doubt
fi
# 🔴 **18 + 2 = 20 인가** — 두 목록이 저장소 전체 변경을 남김없이 덮는지 본다.
if [ "$((${NSRC:-0} + ${NSCR:-0}))" = "$AS_ALL_CHANGED_WANT" ]; then
  ok "src/ ${NSRC} + scripts/ ${NSCR} = ${AS_ALL_CHANGED_WANT} — 저장소 전체 변경과 **딱 맞는다**(남는 것이 없다)"
else
  bad "🔴 src/ ${NSRC:-?} + scripts/ ${NSCR:-?} 가 ${AS_ALL_CHANGED_WANT} 가 아니다 — 어느 쪽에도 안 든 변경이 있다"
  doubt
fi
# 🔴 **새로 생긴 일곱** — 🔴 57번은 여기가 **0개**였고 「0개인가」를 재고 있었다.
#    그 글을 그대로 베껴 오면 **멀쩡한 판이 ✗** 다. 이번 판은 **일곱이 그 일곱인가**다.
#    🔵 공용 부품 둘(CheckboxFilterDropdown.tsx · checkbox-filter-dropdown.ts) +
#       시험 다섯. 시험 다섯은 **목록 파일 둘에 등록돼 있어야** 실제로 돈다.
printf '\n  ── 🔴 이번에 **새로 생긴 파일 %s개**가 그 일곱 그대로인가 (57번은 0개였다)\n' "$AS_BORN_SRC_WANT"
BORN_SEEN=0; BORN_OK=0
while IFS= read -r f; do
  [ -n "${f:-}" ] || continue
  BORN_SEEN=$((BORN_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 지금 저장소에 없다 — 목록이 낡았다"; continue
  fi
  if printf '%s\n' "$BORN_ALL" | grep -Fxq "$f"; then
    BORN_OK=$((BORN_OK+1)); say "🔵 새로 생겼다 — $f"
  else
    bad "🔴 $f 가 **이번 범위에서 새로 생긴 것이 아니다** — 목록이 낡았다"
  fi
done <<BORNEOF
$(printf '%s\n' "$AS_BORN_SRC" | grep -v '^[[:space:]]*$')
BORNEOF
BORN_SRC=$(printf '%s\n' "$BORN_ALL" | grep -c '^src/' || true)
BORN_N=$(printf '%s\n' "$BORN_ALL" | grep -c . || true)
say "적어 둔 ${BORN_SEEN}개 중 실제로 새것 ${BORN_OK}개 · 범위의 새 파일 — src/ 안 ${BORN_SRC:-0}개 · 전체 ${BORN_N:-0}개"
if [ "$BORN_SEEN" = "$AS_BORN_SRC_WANT" ] && [ "$BORN_OK" = "$AS_BORN_SRC_WANT" ] && [ "${BORN_SRC:-x}" = "$AS_BORN_SRC_WANT" ]; then
  ok "새 파일 ${AS_BORN_SRC_WANT}개가 적어 둔 그 일곱과 **정확히 같다**"
else
  bad "🔴 적어 둔 ${BORN_SEEN} · 맞은 것 ${BORN_OK} · 실제 src/ ${BORN_SRC:-?} 다 — 셋 다 ${AS_BORN_SRC_WANT} 여야 한다"
  printf '%s\n' "$BORN_ALL" | head -10 | sed 's/^/      /'
  doubt
fi
if [ "${BORN_N:-x}" = "$AS_BORN_ROOT_WANT" ]; then
  ok "새 파일이 모두 ${AS_BORN_ROOT_WANT}개다 — **전부 src/ 안**이다 (뿌리에는 한 장도 안 생겼다)"
else
  note "새 파일이 ${BORN_N:-?}개다 — ${AS_BORN_ROOT_WANT}개를 기대했다. 사람이 보세요"
fi
# 🔴 **새 시험 다섯이 목록 파일에 등록돼 있는가** — 등록을 빠뜨리면 **오류 없이
#    조용히 안 돈다**(이 저장소에 기록된 함정). 🔵 시험을 돌리지는 않는다 —
#    이 파일은 아무것도 안 바꾸고 아무것도 안 돌린다. **등록 여부만** 본다.
#
# 🔴 **목록 파일은 CRLF 다 — 줄 전체로 맞대는 「-Fx」 가 「\r」 때문에 안 맞는다.**
#    [실측 2026-11-11] components.txt 1322줄 · unit.txt 1938줄이 **전부 CRLF** 다.
#    🔴 그래서 **반드시 「tr -d」 로 \r 를 걷어낸 뒤에** 맞댄다.
#    🔴 **개발 PC 에서는 이 결함이 안 드러난다** — Git Bash 의 grep 은 파일을 텍스트
#       모드로 열어 \r 를 스스로 걷어내므로 「-Fx」 가 그냥 맞는다. **리눅스 컨테이너
#       안의 GNU grep 은 안 그런다.** 2026-11-11 「--go」 에서 이미지 안 검사가
#       **0/5 로 가짜 ✗** 를 냈다(이미지는 멀쩡했다). 그래서 **여기도 같은 처방**을
#       해 둔다 — 두 자리가 같은 잣대를 써야 한쪽이 거짓말을 안 한다.
#    🔵 「-Fx」(줄 전체 일치)는 **살린다.** 경로 일부만 겹치는 다른 줄에 걸리면 안 된다.
#
# 🔴 **「무조건 yes」인 검사가 되지 않게** 없는 경로 하나를 **일부러 함께 묻는다.**
#    그 한 줄이 no 로 안 나오면 아래 다섯의 yes 도 못 믿는다.
REG_PROBE_MISS=src/__dss_probe_not_registered__.test.ts
printf '\n  ── 🔴 새 시험 다섯이 scripts/test-lists 에 **등록돼 있는가** (빠지면 조용히 안 돈다)\n'
say "🔴 목록 파일은 **CRLF** 다 — \\r 를 걷어낸 뒤 줄 전체로 맞댄다(그냥 -Fx 면 안 맞는다)."
REG_LIST=$(cat "$ASDIR"/scripts/test-lists/*.txt 2>/dev/null | tr -d '\r')
REG_LINES=$(printf '%s\n' "$REG_LIST" | grep -c . || true)
say "목록 파일을 \\r 걷어내고 ${REG_LINES:-0}줄 읽었다 (0 이면 아래 수가 전부 못 믿을 값이다)"
REG_SEEN=0; REG_OK=0
for t in src/components/common/CheckboxFilterDropdown.test.tsx \
         src/components/common/checkbox-filter-dropdown.test.ts \
         src/components/misc-cases/misc-case-multi-select-filters.test.ts \
         src/components/repair-cases/repair-case-multi-select-filters.test.ts \
         src/lib/domain/in-house-filter-matches-dashboard.test.ts; do
  REG_SEEN=$((REG_SEEN+1))
  n=$(printf '%s\n' "$REG_LIST" | grep -cFx -- "$t" || true)
  printf '      %-62s 목록에 적힌 줄 %s개\n' "$t" "${n:-0}"
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then REG_OK=$((REG_OK+1)); fi
done
REG_MISS_N=$(printf '%s\n' "$REG_LIST" | grep -cFx -- "$REG_PROBE_MISS" || true)
printf '      %-62s 목록에 적힌 줄 %s개 (표본 · 기대 0)\n' "$REG_PROBE_MISS" "${REG_MISS_N:-0}"
if [ "${REG_LINES:-0}" -lt 100 ] 2>/dev/null; then
  bad "🔴 목록을 ${REG_LINES:-0}줄밖에 못 읽었다 — **빈 결과는 삼켜진 오류일 수 있다.** 멈추세요"
  doubt
elif [ "${REG_MISS_N:-1}" != "0" ]; then
  bad "🔴 **없는 경로가 걸렸다** — 줄 전체 일치가 깨졌다. 아래 다섯의 yes 도 못 믿는다"
  doubt
elif [ "$REG_SEEN" = "5" ] && [ "$REG_OK" = "5" ]; then
  ok "새 시험 다섯이 전부 목록에 등록돼 있다 (돌 수 있는 상태다 · 없는 경로는 안 걸렸다)"
else
  bad "🔴 등록된 것이 ${REG_OK}/${REG_SEEN} 개다 — 다섯을 기대했다. **빠진 시험은 조용히 안 돈다**"
  doubt
fi
# ── 🔴 저장소 뿌리의 .html — 🔴 **이번 판은 19 → 19 라 아무것도 안 가른다** ──
#   🔴 57번은 18 → 19 였고 그 수가 **앱 이미지에서 판을 가르는 증거**였다.
#      🔴 그 글을 그대로 베껴 오면 **아무것도 안 재는 ✓** 가 된다(어차피 19다).
#   🔵 그래서 이 절의 **뜻을 바꿨다**: 여기서는 「기준판과 지금이 같은가」만 보고,
#      이미지 안에서는 「standalone 이 뿌리 파일을 **옮기기는 하는가**」만 본다.
#   🔴 **quotePath 를 꺼야 센다**(한글 파일명). 안 끄면 git 이 따옴표를 둘러
#      내보내어 '.html$' 가 안 맞고 **조용히 0** 이 나온다.
say "── 저장소 뿌리의 .html — 🔴 **이번 판은 안 는다.** 그래서 판을 가르는 데 못 쓴다"
HW=$(git -c core.quotePath=false -C "$ASDIR" ls-tree --name-only "$AS_BASE" -- . 2>/dev/null | grep -c '\.html$' || true)
HN=$(git -c core.quotePath=false -C "$ASDIR" ls-tree --name-only HEAD -- . 2>/dev/null | grep -c '\.html$' || true)
say "저장소 뿌리의 .html — 기준 ${HW:-?} → 지금 ${HN:-?} (적어 둔 값 $AS_ROOT_HTML_WAS → $AS_ROOT_HTML_NOW · **같아야 한다**)"
if [ "${HW:-x}" = "$AS_ROOT_HTML_WAS" ] && [ "${HN:-x}" = "$AS_ROOT_HTML_NOW" ] && [ "${HW:-x}" = "${HN:-y}" ]; then
  ok "뿌리의 .html 이 기준판과 지금 **둘 다 $AS_ROOT_HTML_NOW** 다 (이번 범위에 .html 변경이 없다)"
  say "🔴 **그래서 이 수로는 이번 판을 못 가른다** — 앱 이미지 쪽 검사는 이 수를"
  say "   「standalone 이 뿌리 파일을 옮기기는 하는가」로만 씁니다(0 이면 ✗)."
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
#   🔵 **다섯이 커밋 하나씩을 가른다**(머리말의 표). 마지막 줄 customerNames 가
#      **마지막 커밋 242f0f69 를 가른다** — MiscCaseFilters.tsx 는 이 범위에서
#      그 커밋 하나만 건드렸다.
printf '\n  ── A/S 이번 판의 표식 다섯 (기준판에 0 · 지금 판에 1 이상 · 커밋 하나씩을 가른다)\n'
MK_SEEN=0; MK_OK=0
while IFS='|' read -r s f; do
  [ -n "${s:-}" ] || continue
  MK_SEEN=$((MK_SEEN+1))
  # 🔴 -F 로 **글자 그대로** 센다. 표식에 '=' 와 '-' 가 섞여 있고, 정규식으로
  #    읽히면 같은 글자가 다른 뜻이 되는 날이 온다.
  was=$(git -C "$ASDIR" show "$AS_BASE:$f" 2>/dev/null | grep -cF -- "$s" || true)
  now=$(grep -cF -- "$s" "$ASDIR/$f" 2>/dev/null || true)
  printf '      %-52s %-72s 기준 %s → 지금 %s\n' "$s" "$f" "${was:-0}" "${now:-0}"
  if [ "${was:-1}" = "0" ] && [ "${now:-0}" -ge 1 ] 2>/dev/null; then MK_OK=$((MK_OK+1)); fi
done <<MKEOF
$(printf '%s\n' "$AS_MARKS" | grep -v '^[[:space:]]*$')
MKEOF
if [ "$MK_SEEN" = "$AS_MARKS_WANT" ] && [ "$MK_OK" = "$AS_MARKS_WANT" ]; then
  ok "표식 $AS_MARKS_WANT 개가 전부 **이번에 생겼다** (옛 판이 아니다)"
  say "🔵 마지막 줄(MiscCaseFilters.tsx 안의 customerNames)이 **마지막 커밋 $AS_HEAD_SHORT 을 가른다** —"
  say "   그 파일은 이 범위에서 그 커밋 하나만 건드렸습니다."
else
  bad "🔴 표식이 ${MK_OK}/${MK_SEEN} 개다 — $AS_MARKS_WANT/$AS_MARKS_WANT 을 기대했다. 목록이 낡았거나 범위가 틀렸다"
  doubt
fi
# 🔴 구운 **앱** 이미지에서 쓸 표식이 기준판 src/ 에 **0파일**인가.
#    🔵 -F 로 센다 — BUILD_MARK 에 '=' 가 들어 있다.
ASMW=$(git -C "$ASDIR" grep -lF "$BUILD_MARK" "$AS_BASE" -- src/ 2>/dev/null | wc -l | tr -d ' ')
ASMN=$(git -C "$ASDIR" grep -lF "$BUILD_MARK" HEAD        -- src/ 2>/dev/null | wc -l | tr -d ' ')
say "$BUILD_MARK 가 든 src/ 파일 — 기준 ${ASMW:-?} → 지금 ${ASMN:-?} (기대 0 → 1 이상 · 2026-11-11 실측 0 → 5)"
if [ "${ASMW:-1}" = "0" ] && [ "${ASMN:-0}" -ge 1 ] 2>/dev/null; then
  ok "앱 표식 $BUILD_MARK 이 **이번에 생겼다** — 번들 안에서 이 한 글자로 판을 가른다"
  say "🔵 href 에 들어가는 **글자 리터럴**이라 번들러가 이름을 못 바꿉니다 — 그래서 이것만 ✗ 로 셉니다."
else
  bad "🔴 앱 표식이 기준 ${ASMW:-?} → 지금 ${ASMN:-?} 다 — 0 → 1 이상을 기대했다"
  doubt
fi
# 🔵 뒷걸음 방지 표식 — **쉰세째(57번)가 올린 글자**다. **기준판에도 있어야** 한다.
KPW=$(git -C "$ASDIR" grep -lF "$KEEP_MARK" "$AS_BASE" -- src/ 2>/dev/null | wc -l | tr -d ' ')
KPN=$(git -C "$ASDIR" grep -lF "$KEEP_MARK" HEAD        -- src/ 2>/dev/null | wc -l | tr -d ' ')
say "$KEEP_MARK 가 든 src/ 파일 — 기준 ${KPW:-?} → 지금 ${KPN:-?} (둘 다 1 이상 — **이번 판이 만든 글자가 아니다**)"
if [ "${KPW:-0}" -ge 1 ] 2>/dev/null && [ "${KPN:-0}" -ge 1 ] 2>/dev/null; then
  ok "뒷걸음 방지 표식 $KEEP_MARK 이 기준판에도 지금에도 있다 (쉰세째 것이 안 사라졌다)"
else
  bad "🔴 $KEEP_MARK 이 기준 ${KPW:-?} · 지금 ${KPN:-?} 다 — 둘 다 1 이상이어야 한다"
  doubt
fi
# 🔵 ⚠️ 보조 표식 둘 — 앱 번들에서 **재 보지 못한** 것들이다.
#    🔴 여기서 재는 것은 **소스 쪽**이다. 「소스에 있다」와 「번들에 남는다」는
#       다른 말이라, 이미지 안 검사에서는 이 둘을 ⚠️ 로만 센다.
SMW=$(git -C "$ASDIR" grep -lF "$SOFT_MARK" "$AS_BASE" -- src/ 2>/dev/null | wc -l | tr -d ' ')
SMN=$(git -C "$ASDIR" grep -lF "$SOFT_MARK" HEAD        -- src/ 2>/dev/null | wc -l | tr -d ' ')
say "$SOFT_MARK 가 든 src/ 파일 — 기준 ${SMW:-?} → 지금 ${SMN:-?} (2026-11-11 실측 0 → 3)"
if [ "${SMW:-1}" = "0" ] && [ "${SMN:-0}" -ge 1 ] 2>/dev/null; then
  ok "보조 표식 $SOFT_MARK 도 이번에 생겼다 (소스 쪽 · 번들에서는 ⚠️ 로만 센다)"
else
  note "보조 표식이 기준 ${SMW:-?} → 지금 ${SMN:-?} 다 — 0 → 1 이상을 적어 두었다. **막지 않는다**"
fi
# 🔴 한글 표식은 **8진 이스케이프로 다시 만들어** 쓴다. 만들기가 틀리면 0 이 나와
#    「없다」로 읽히므로 **바이트 수를 먼저 본다**(기대 $SOFT_MARK_KO_BYTES).
KOS=$(printf "$SOFT_MARK_KO_OCT")
KOB=$(printf '%s' "$KOS" | wc -c | tr -d ' ')
say "한글 표식을 8진 이스케이프로 다시 만들었다 — ${KOB}바이트 (기대 $SOFT_MARK_KO_BYTES)"
if [ "${KOB:-0}" = "$SOFT_MARK_KO_BYTES" ]; then
  KOW=$(git -C "$ASDIR" grep -lF "$KOS" "$AS_BASE" -- src/ 2>/dev/null | wc -l | tr -d ' ')
  KON=$(git -C "$ASDIR" grep -lF "$KOS" HEAD        -- src/ 2>/dev/null | wc -l | tr -d ' ')
  say "그 글자가 든 src/ 파일 — 기준 ${KOW:-?} → 지금 ${KON:-?} (2026-11-11 실측 0 → 10)"
  if [ "${KOW:-1}" = "0" ] && [ "${KON:-0}" -ge 1 ] 2>/dev/null; then
    ok "한글 표식을 만드는 길이 살아 있고 그 글자가 **이번에 생겼다** (소스 쪽)"
  else
    note "한글 표식이 기준 ${KOW:-?} → 지금 ${KON:-?} 다 — 0 → 1 이상을 적어 두었다. **막지 않는다**"
  fi
else
  note "한글 표식을 못 만들었다 (${KOB:-?}바이트) — 🔴 **이미지 안 검사에서 0 이 나와도 「없다」가 아니다**"
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
# 🔵 **되돌릴 판이 개발 PC 에 남아 있는가** — NAS 쪽은 58-deploy.sh 가 따로 센다.
for t in "$AS_OLD_TAG" "$AS_TOOLS_OLD_TAG"; do
  if docker image inspect "$t" >/dev/null 2>&1; then say "🔵 옛 판 $t 가 개발 PC 에 있다"
  else say "🔵 옛 판 $t 가 개발 PC 에 없다 — NAS 쪽에 있으면 되돌리기는 된다(거기서 센다)"; fi
done
say "🔵 포털은 dss-auth:2.1 · dss-auth-tools:4 그대로 둔다 — 이번에도 안 굽고 안 갈아 끼운다."
say "🔵 PO 는 dss-po:0.9 그대로 둔다 — 같다."

# ── 7. tar 둘을 둘 자리 + 🔴 3000번 개발 서버 ────────────────────────
printf '\n== 7. tar 둘을 둘 자리\n'
if [ "$MODE" = "--go" ]; then
  mkdir -p "$OUT" 2>/dev/null
fi
if [ -d "$OUT" ]; then ok "$OUT 가 있다"
elif [ "$MODE" = "--check" ]; then note "$OUT 가 아직 없다 (--go 가 만든다)"
else bad "$OUT 를 못 만들었다"; fi
# 🔵 tar 둘이면 360MB 쯤이다. 🔴 **이번 판에도 묶음이 없다** — 그만큼 덜 쓴다.
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
printf '\n== 8. 양식 파일 — 열하나가 55·57번 값 그대로인가 (경로는 안 찍는다)\n'
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
  ok "양식 $TPL_COUNT_WANT 개가 **전부 55·57번이 적어 둔 md5 그대로**다 — 🔵 **올릴 양식이 0장이다**"
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
      printf '%s\n' "      🔵 이번 판은 **소스 20개만 고친 판**이라 크기가 거의 안 움직여야 정상입니다."
      printf '%s\n' "         (새 파일이 일곱 늘었지만 전부 소스·시험이라 바이트로는 티가 안 납니다.)"
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
      # ② 🔴 **이번 판의 글자가 번들에 있는가.** 🔵 status=IN_HOUSE 는 대시보드
      #    카드의 href 에 들어가는 **글자 리터럴**("/repair-cases?status=IN_HOUSE")
      #    이라 minifier 가 이름을 못 바꾼다.
      #    🔴 이것이 없으면 「옛 판을 구웠다」이고, 그때 증상은 **아무 일도 안
      #       일어나는 것**이다 — 배포는 성공하고 기능만 없다.
      #    🔴 **.next/server 와 .next/static 을 둘 다 본다.** runner 가 static 을
      #       따로 복사해 담으므로(Dockerfile), 서버 쪽에만 묻는 것은 반쪽이다.
      #    🔴 글자에 '=' 가 있어 **큰따옴표로 감싸** 넘긴다.
      v=$(docker run --rm -e M="$BUILD_MARK" --entrypoint sh "$TAG" -c 'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
      bs=$(printf '%s' "$v" | awk '{print $1}'); bt=$(printf '%s' "$v" | awk '{print $2}')
      printf '    %s 가 든 파일 — .next/server %s개 · .next/static %s개 (합이 1 이상이어야 한다)\n' "$BUILD_MARK" "${bs:-?}" "${bt:-?}"
      if isnum "${bs:-}" && isnum "${bt:-}" && [ "$((bs + bt))" -ge 1 ]; then
        printf '  ✓ 번들에 이번 판의 글자가 있다 (옛 판이 아니다)\n'
      else
        printf '  ✗ 번들에 %s 가 없다 — **옛 판을 구웠다.** 캐시를 의심하세요\n' "$BUILD_MARK"; IMGFAIL=1
        printf '%s\n' "      🔵 **검사 자신도 의심하세요** — 이 판을 구운 뒤 번들에서 이 글자를 직접"
        printf '%s\n' "         세어 본 적이 없습니다(개발 PC 에 .next/standalone 이 없었습니다)."
      fi
      # ③ 🔵 **뒷걸음 방지** — **쉰세째(57번)가 올린 글자**가 아직 있는가.
      #    🔴 이것은 **이번 판이 만든 글자가 아니다.** 「더 옛날 나무를 구웠나」를 본다.
      #    🔵 57-build.sh 가 2026-11-11 에 구운 번들에서 **4 파일**로 실측한 글자라,
      #       이것은 ✗ 로 세도 가짜 ✗ 가 날 자리가 아니다.
      v=$(docker run --rm -e M="$KEEP_MARK" --entrypoint sh "$TAG" -c 'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
      ks=$(printf '%s' "$v" | awk '{print $1}'); kt=$(printf '%s' "$v" | awk '{print $2}')
      printf '    %s 가 든 파일 — server %s개 · static %s개 (쉰세째 것 · 그때 server 에서 4)\n' "$KEEP_MARK" "${ks:-?}" "${kt:-?}"
      if isnum "${ks:-}" && isnum "${kt:-}" && [ "$((ks + kt))" -ge 1 ]; then
        printf '  ✓ 쉰세째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)\n'
      else
        printf '  ✗ %s 가 없다 — **쉰세째보다 옛 나무를 구웠다.** 올리지 마세요\n' "$KEEP_MARK"; IMGFAIL=1
      fi
      # ④ 🔵 보조 표식 둘 — **번들에서 재 보지 못한 것들**이다. ⚠️ 로만 센다.
      #    🔴 「재서 나왔다」와 「앞으로도 나온다」는 다른 말이고, **재 본 적이 없는
      #       것**은 그보다 더 약하다. ✗ 로 세면 가짜 ✗ 가 난다.
      v=$(docker run --rm -e M="$SOFT_MARK" --entrypoint sh "$TAG" -c 'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
      ss=$(printf '%s' "$v" | awk '{print $1}'); st=$(printf '%s' "$v" | awk '{print $2}')
      printf '    %s 가 든 파일 — server %s개 · static %s개 (새 부품의 클래스 글자 — ⚠️ 로만 셉니다)\n' "$SOFT_MARK" "${ss:-?}" "${st:-?}"
      if isnum "${ss:-}" && isnum "${st:-}" && [ "$((ss + st))" -ge 1 ]; then
        printf '  ✓ 새 부품의 클래스 글자도 번들에 남아 있다 (보조 증거)\n'
      else
        printf '  ⚠️ %s 가 번들에 안 보인다 — 🔵 **번들에서 재 본 적이 없는 글자입니다.**\n' "$SOFT_MARK"
        printf '%s\n' "      🔵 위 ② 가 ✓ 라면 **판은 맞습니다** — 이 줄만으로 올리기를 막지 않습니다."
      fi
      # ⑤ 🔵 보조 표식 — 화면에 나가는 **한글** 「입고품 전체」.
      #    🔴 **명령에 한글을 넣지 않는다.** 컨테이너 안에서 8진 이스케이프로 다시
      #       만든다. 🔴 만들기가 틀리면 0 이 나와 「없다」로 읽히므로 **바이트 수를
      #       함께 받아** 가른다(기대 16). 16 이 아니면 「못 쟀다」라고 말한다.
      v=$(docker run --rm -e O="$SOFT_MARK_KO_OCT" --entrypoint sh "$TAG" -c 'k=$(printf "$O"); n=$(printf "%s" "$k" | wc -c); printf "%s %s %s\n" "$n" "$(grep -rlF "$k" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$k" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
      kb=$(printf '%s' "$v" | awk '{print $1}'); qs=$(printf '%s' "$v" | awk '{print $2}'); qt=$(printf '%s' "$v" | awk '{print $3}')
      printf '    한글 표식 — 만든 글자 %s바이트(기대 %s) · server %s개 · static %s개\n' "${kb:-?}" "$SOFT_MARK_KO_BYTES" "${qs:-?}" "${qt:-?}"
      if [ "${kb:-0}" != "$SOFT_MARK_KO_BYTES" ]; then
        printf '  ⚠️ 컨테이너 안에서 한글 표식을 **못 만들었다**(%s바이트) — 🔴 아래 0 은 「없다」가 아니다\n' "${kb:-?}"
      elif isnum "${qs:-}" && isnum "${qt:-}" && [ "$((qs + qt))" -ge 1 ]; then
        printf '  ✓ 화면에 나가는 한글 글자가 번들에 있다 (보조 증거 · minifier 가 못 바꾸는 글자다)\n'
      else
        printf '  ⚠️ 그 한글 글자가 번들에 안 보인다 — 🔵 **번들에서 재 본 적이 없습니다.**\n'
        printf '%s\n' "      🔵 위 ② 가 ✓ 라면 **판은 맞습니다** — 이 줄만으로 올리기를 막지 않습니다."
      fi
      # ⑥ 🔵 public/ 이 담겼는가 — 없으면 아이콘·정적 파일이 404 가 된다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/public && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '    /app/public: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ public/ 이 담겼다\n'
      else printf '  ✗ public/ 이 없다 — 정적 파일이 404 가 된다\n'; IMGFAIL=1; fi
      # ⑦ 🔴 **뿌리의 .html — 이번 판은 이 수로 판을 못 가른다.**
      #    🔴 57번은 기준 18 → 이번 19 라 **이 수가 판을 가르는 증거**였다.
      #       🔴 **이번 판은 19 → 19 다.** 그 글을 그대로 베껴 오면 「19 면 이번
      #          판이다」가 되는데, 그것은 **옛 판에서도 참**이라 아무것도 안 재는
      #          ✓ 가 된다. 그래서 **뜻을 바꿨다.**
      #    🔵 여기서 보는 것은 하나뿐이다: **standalone 이 저장소 뿌리를 옮기기는
      #       하는가.** 0 이면 이미지의 생김새 자체가 지금까지와 다르다(✗).
      #    🔵 19 가 아니면 ⚠️ 다 — 뿌리에 문서를 더하거나 지우면 바뀌는 수다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "ls -1 /app/*.html 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '    /app 바로 아래 .html: %s개 (기준판 %s → 이번 %s — **같은 수다**)\n' "${v:-?}" "$AS_ROOT_HTML_WAS" "$AS_ROOT_HTML_NOW"
      if ! isnum "${v:-}" || [ "${v:-0}" = "0" ]; then
        printf '  ✗ /app 바로 아래에 .html 이 %s개다 — standalone 이 뿌리 파일을 안 옮겼다\n' "${v:-못 읽음}"; IMGFAIL=1
      elif [ "${v:-0}" = "$AS_ROOT_HTML_NOW" ]; then
        printf '  ✓ 뿌리의 .html 이 %s개다 (standalone 이 저장소 뿌리를 옮겼다)\n' "$AS_ROOT_HTML_NOW"
        printf '%s\n' "      🔴 **이 수는 이번 판을 가르지 않습니다** — 기준판도 같은 수입니다."
        printf '%s\n' "         판을 가르는 것은 위 ② 뿐입니다(57번과 다른 자리입니다)."
      else
        printf '  ⚠️ 뿌리의 .html 이 %s개다 — %s개를 기대했다. 그 사이에 문서를 더하거나 지우셨나요\n' "${v:-?}" "$AS_ROOT_HTML_NOW"
        printf '%s\n' "      🔵 **판정과는 무관합니다** — 이 수는 이번 판을 가르지 않습니다."
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
      # ③ 🔴 **이번 판이 바꾼 20개가 담겼는가** — 55번의 「닫힘 아홉」을 갈아 끼운 자리다.
      #    🔴 그 아홉은 이번 판에도 **하나도 안 바뀐다** — 그것을 세면 **아무것도 안
      #       재는 ✓** 다(어느 판에서나 있는 파일이다).
      #    🔴 **57번과 달리 scripts/ 둘을 함께 넣는다** — 그쪽이 안 담기면 새 시험
      #       다섯이 등록 안 된 이미지가 된다.
      #    🔵 이번 판의 목록에는 괄호·대괄호가 없다. 그래도 **환경변수로 넘겨
      #       큰따옴표로 받는** 방식은 그대로 둔다(머리말 ⑧).
      v=$(docker run --rm -e DSS_FILES="$AS_CHANGED_SRC$AS_CHANGED_SCRIPTS" --entrypoint sh "$TAG" -c 'printf "%s\n" "$DSS_FILES" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      seen=$(printf '%s\n' "$v" | grep -cE '^(yes|no ) ' || true)
      printf '      본 것 %s개 · 있는 것 %s개 (기대 %s · %s — src/ %s + scripts/ %s)\n' "${seen:-0}" "${got:-0}" "$AS_ALL_CHANGED_WANT" "$AS_ALL_CHANGED_WANT" "$AS_CHANGED_SRC_WANT" "$AS_CHANGED_SCRIPTS_WANT"
      if [ "${seen:-0}" = "$AS_ALL_CHANGED_WANT" ] && [ "${got:-0}" = "$AS_ALL_CHANGED_WANT" ]; then
        printf '  ✓ 이번 판이 바꾼 %s개가 다 담겼다 (표본이 비지 않았다)\n' "$AS_ALL_CHANGED_WANT"
      else
        printf '  ✗ 본 것 %s · 있는 것 %s 다 — %s/%s 를 기대했다\n' "${seen:-0}" "${got:-0}" "$AS_ALL_CHANGED_WANT" "$AS_ALL_CHANGED_WANT"; IMGFAIL=1
      fi
      # ③-ㄴ 🔴 **새로 생긴 일곱이 경로로 담겼는가** — 57번에는 없던 절이다
      #    (그 판은 새 파일이 0개였다). 🔵 ③ 에 포함돼 있지만 **따로 찍는다** —
      #    새 파일은 「빠져도 오류가 안 나는」 쪽이라 눈에 보이게 세워 둔다.
      v=$(docker run --rm -e DSS_BORN="$AS_BORN_SRC" --entrypoint sh "$TAG" -c 'printf "%s\n" "$DSS_BORN" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      seen=$(printf '%s\n' "$v" | grep -cE '^(yes|no ) ' || true)
      printf '      새 파일 — 본 것 %s개 · 있는 것 %s개 (기대 %s · %s)\n' "${seen:-0}" "${got:-0}" "$AS_BORN_SRC_WANT" "$AS_BORN_SRC_WANT"
      if [ "${seen:-0}" = "$AS_BORN_SRC_WANT" ] && [ "${got:-0}" = "$AS_BORN_SRC_WANT" ]; then
        printf '  ✓ 이번에 생긴 %s개가 다 담겼다 (공용 부품 둘 + 시험 다섯)\n' "$AS_BORN_SRC_WANT"
      else
        printf '  ✗ 새 파일이 %s/%s 개다 — **옛 소스가 담겼다.** 캐시를 의심하세요\n' "${got:-0}" "$AS_BORN_SRC_WANT"; IMGFAIL=1
      fi
      # ③-ㄷ 🔴 **새 시험 다섯이 이미지 안의 목록 파일에도 등록돼 있는가.**
      #    🔴 「파일이 담겼다」와 「그 시험이 돈다」는 다른 말이다 — 이 저장소의
      #       시험은 글롭이 아니라 목록에 적어야 돈다. 담겨 있고 등록이 빠지면
      #       **오류 없이 조용히 안 돈다.**
      #
      #    🔴 **목록 파일은 CRLF 다 — 줄 전체로 맞대는 「-Fx」 가 「\r」 때문에 안 맞는다.**
      #       🔴 2026-11-11 「--go」 에서 이 줄이 **0/5 로 가짜 ✗** 를 냈다. 이미지는
      #          멀쩡했고(파일명으로 grep 하면 다섯 다 있었다) **검사가 틀렸다.**
      #       🔴 개발 PC 의 Git Bash grep 은 \r 를 스스로 걷어내서 **거기서는 안
      #          드러난다.** 리눅스 컨테이너의 GNU grep 은 안 그런다.
      #       🔵 그래서 **「tr -d」 로 \r 를 걷어낸 뒤** 맞댄다. 「-Fx」 는 **살린다** —
      #          경로 일부만 겹치는 다른 줄에 걸리면 안 된다.
      #    🔴 **cat 의 글롭은 「set -f」 앞에서 푼다** — 뒤에 두면 글롭이 꺼져 있어
      #       「*.txt」 가 글자 그대로 남고 **파일을 한 줄도 못 읽는다.**
      #    🔴 **없는 경로 하나를 일부러 함께 묻는다** — 그 줄이 no 로 안 나오면
      #       「무조건 yes」인 검사라는 뜻이고, 다섯의 yes 도 못 믿는다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'L=$(cat /app/scripts/test-lists/*.txt 2>/dev/null | tr -d "\r"); echo "lines $(printf "%s\n" "$L" | grep -c .)"; set -f; for t in src/components/common/CheckboxFilterDropdown.test.tsx src/components/common/checkbox-filter-dropdown.test.ts src/components/misc-cases/misc-case-multi-select-filters.test.ts src/components/repair-cases/repair-case-multi-select-filters.test.ts src/lib/domain/in-house-filter-matches-dashboard.test.ts src/__dss_probe_not_registered__.test.ts; do n=$(printf "%s\n" "$L" | grep -cFx -- "$t"); if [ "${n:-0}" -ge 1 ]; then echo "yes $t"; else echo "no  $t"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      probe=$(printf '%s\n' "$v" | grep -c '^no  src/__dss_probe_not_registered__' || true)
      lines=$(printf '%s\n' "$v" | sed -n 's/^lines //p')
      printf '      \\r 를 걷어내고 읽은 목록 줄 수: %s개 (0 이면 아래 수가 전부 못 믿을 값이다)\n' "${lines:-?}"
      if ! isnum "${lines:-}" || [ "${lines:-0}" -lt 100 ]; then
        printf '  ✗ 이미지 안 목록을 %s줄밖에 못 읽었다 — **빈 결과는 삼켜진 오류일 수 있다**\n' "${lines:-못 읽음}"; IMGFAIL=1
      elif [ "${probe:-0}" != "1" ]; then
        printf '  ✗ **없는 경로가 no 로 안 나왔다** — 줄 전체 일치가 깨졌다. 아래 yes 도 못 믿는다\n'; IMGFAIL=1
      elif [ "${got:-0}" = "5" ]; then
        printf '  ✓ 새 시험 다섯이 이미지 안의 목록에도 등록돼 있다 (담기기만 한 것이 아니다)\n'
        printf '%s\n' "      🔵 없는 경로 하나는 **no** 로 나왔습니다 — 「무조건 yes」인 검사가 아닙니다."
      else
        printf '  ✗ 등록된 것이 %s/5 개다 — **옛 목록 파일이 담겼다.** 그 시험들은 조용히 안 돕니다\n' "${got:-0}"; IMGFAIL=1
      fi
      # ④ 🔴 **그 안에 이번 판의 글자가 있는가** — 「파일이 있다」와 다른 말이다.
      #    🔴 다섯이 **커밋 하나씩을 가른다**(머리말의 표). 마지막 짝 customerNames 가
      #       **마지막 커밋 242f0f69 를 가른다.**
      # 🔴 **set -f 로 글롭을 끈다.** 🔵 이번 판의 경로에는 대괄호가 없지만, 끄는
      #    것이 기본값이다 — 켜 두면 다음 판에서 조용히 빗나간다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'set -f; for pair in "status=IN_HOUSE /app/src/components/dashboard/DashboardContent.tsx" "IN_HOUSE_STATUSES /app/src/lib/domain/repair-case-filters.ts" "isShortcutActive /app/src/components/common/checkbox-filter-dropdown.ts" "BillingTypeFilterValue /app/src/lib/domain/repair-case-filters.ts" "customerNames /app/src/components/misc-cases/MiscCaseFilters.tsx"; do set -- $pair; if grep -qF -- "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "$AS_MARKS_WANT" ]; then
        printf '  ✓ 이번 판의 표식 %s개가 이미지 안에 있다 (옛 판이 아니다)\n' "$AS_MARKS_WANT"
        printf '%s\n' "      🔵 다섯이 **커밋 하나씩을 가릅니다** — 마지막 줄(customerNames)이"
        printf '%s\n' "         **마지막 커밋 242f0f69 를 가릅니다.**"
      else
        printf '  ✗ 이번 판의 표식이 %s/%s 개다 — **옛 판이 담겼다.** 캐시를 의심하세요\n' "${got:-0}" "$AS_MARKS_WANT"; IMGFAIL=1
      fi
      # ⑤ 🔵 **공용 스키마가 담겼는가** — 없으면 Cannot find module 이 난다.
      #    🔵 이번 판에도 **안 바뀌었다.** 그래서 「새 칸이 있나」가 아니라 「있나」만 본다.
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
      #    🔵 이번 판은 도구를 하나도 안 만들었다. 그래서 이 목록은 **48~55번 것** 그대로다.
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
      # ⑪ 🔵 **drizzle-kit 이 있는가.** 이번 판도 마이그레이션이 0건이라 db:migrate 를
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
      #    🔴 이번 판도 묶음을 안 보내므로 **운영 볼륨이 그대로 쓰인다.** 여기에 .sql 이
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

# ══ 🔴 58-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 58-deploy.sh 의 TARS 는 **이름만 적힌 채로** 올라간다. 지문 칸이 비어 있으면
#     --check 에서 ? 로 세고 **--preload·--go 에서는 ✗ 다** — 아래 **두 줄**로
#     그 두 줄을 통째로 갈아 끼운다.
#  🔴 **쉰세째 때 이 출력을 잘라 버려 빈 표가 NAS 로 올라갔고 --preload 가 ✗ 둘로
#     멈췄다.** 그래서 이 파일은 그 두 줄을 **꼬리말 맨 끝에서 한 번 더** 찍는다.
printf '\n%s\n' "════════ 58-deploy.sh 의 TARS 에 붙여 넣을 것 (두 줄) ════════"
printf '%s' "$TARTABLE"
echo "  🔴 위 두 줄로 TARS 의 두 줄을 통째로 갈아 끼운다."
echo "  🔵 **셋째 줄(묶음)은 없다** — 이번 판도 마이그레이션이 0건이라 묶음을 안 만든다."
echo "     🔴 55번에는 MIGTAR_SIZE·MIGTAR_MD5 가 있었다. 58-deploy.sh 에는 **그 변수가 없다.**"
printf '\n%s\n' "✅ 둘 다 구웠다. tar 와 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'

printf '\n%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **올리는 차례 — 이번 판도 tar 둘뿐이다 (묶음 없음)**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  🔵 **마이그레이션이 0건입니다.** 볼륨도 DB 도 $AS_SQL_WANT 그대로입니다."
printf '%s\n' "     🔴 그래서 **58-deploy.sh 에는 --migrate 모드가 없습니다.** 치면 거절합니다."
printf '%s\n' "     🔵 대신 --check 가 **「올릴 것이 정말 0건인가」를 값으로** 확인합니다"
printf '%s\n' "        (볼륨 127 · DB 기록 127 · 적용 대기 0건 · db:preflight 종료 코드 0)."
printf '%s\n' "  🔵 양식은 **한 장도 안 올립니다** — 열하나가 55·57번 값 그대로입니다(8절)."
printf '%s\n' "  🔵 포털(dss-auth)·PO 는 **안 건드립니다.**"
printf '%s\n' ""
printf '%s\n' "  🔴 PowerShell 경로는 **슬래시**로 적습니다. 역슬래시는 bash·scp 가 먹습니다."
printf '%s\n' "  🔴 **Tee-Object 로 로그를 받지 마세요** — PowerShell 이 UTF-16 으로 써서"
printf '%s\n' "     나중에 grep 이 한 줄도 못 찾습니다. 화면을 그대로 복사하시거나"
printf '%s\n' "     NAS 쪽 로그 파일(스크립트가 스스로 남깁니다)을 보세요."
printf '%s\n' ""
printf '%s\n' "  ① (개발 PC · PowerShell) **스크립트부터 올린다**"
printf '%s\n' "       cd \"C:/Users/희만/Desktop/Development/dss-deploy/nas/setup\""
printf '%s\n' "       scp -O 58-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "       Get-FileHash -Algorithm MD5 58-deploy.sh"
printf '%s\n' "     🔵 NAS 에서 md5sum 을 쳐 **눈으로 맞댑니다**(DSM 터미널이 긴 것을 잘라 먹습니다)."
printf '%s\n' "     🔴 **TARS 두 줄을 먼저 채운 뒤에 올리세요** — 위 표가 그 두 줄입니다."
printf '%s\n' ""
printf '%s\n' "  ② (NAS) 지금 상태를 잰다 — 아직 아무것도 안 바뀐다"
printf '%s\n' "       sudo -i"
printf '%s\n' "       bash /volume1/dss/setup/58-deploy.sh            ← --check"
printf '%s\n' "       bash /volume1/dss/setup/58-deploy.sh --count    ← 올리기 전 수"
printf '%s\n' "     🔵 2절의 마이그레이션 수가 **$AS_SQL_WANT** 로 나와야 합니다 (앞뒤가 같습니다)."
printf '%s\n' ""
printf '%s\n' "  ③ (개발 PC · PowerShell) **tar 둘을 보낸다 — 한 줄에 하나씩**"
printf '%s\n' "       cd \"$(printf '%s' "$OUT" | sed 's|^/c/|C:/|')\""
printf '%s\n' "       scp -O dss-as-5.0.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "       scp -O dss-as-tools-17.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "     🔴 **-O 를 빼지 마세요** — DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' "     🔵 **묶음은 안 보냅니다.** 55번에는 셋째 줄이 있었습니다 — 이번엔 없습니다."
printf '%s\n' ""
printf '%s\n' "  ④ (NAS) **들여놓고 → 다시 재고 → 갈아 끼운다**"
printf '%s\n' "       bash /volume1/dss/setup/58-deploy.sh --preload"
printf '%s\n' "       bash /volume1/dss/setup/58-deploy.sh            ← 다시 --check"
printf '%s\n' "       bash /volume1/dss/setup/58-deploy.sh --go       ⏱ 정지 창 (앱 **하나**)"
printf '%s\n' "       bash /volume1/dss/setup/58-deploy.sh --count    ← 올린 뒤 수"
printf '%s\n' "     🔵 **--migrate 단계가 없습니다.** --go 가 앱과 도구의 image: 줄 **둘**을 고칩니다."
printf '%s\n' ""
printf '%s\n' "🔴 **되돌리기**: --rollback 은 app-as 를 $AS_OLD_TAG 로 되돌립니다."
printf '%s\n' "   🔵 도구는 $AS_TOOLS_TAG 그대로 둡니다(39·41~57번과 같은 판단)."
printf '%s\n' "   🔵 **DB 는 되돌릴 것이 없습니다** — 이 배포는 DB 를 한 글자도 안 바꿉니다."
printf '%s\n' ""
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **배포 뒤에 눈으로 볼 곳 — 이번 판은 다섯 커밋이 전부 화면입니다**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  🔵 사용자 개선요청 **둘**입니다."
printf '%s\n' ""
printf '%s\n' "  ① 🔴 **대시보드 [현재 입고 수] 카드를 누르세요.**"
printf '%s\n' "     전에는 조건 없이 [전체 A/S 현황]이 열려 **카드에 적힌 수와 목록 건수가"
printf '%s\n' "     달랐습니다**(출하 완료까지 다 보였습니다). 이제 [현재 상태]에"
printf '%s\n' "     「입고품 전체」가 눌린 채로 열리고 **두 수가 같아야** 합니다."
printf '%s\n' "     🔵 주소는 /repair-cases?status=IN_HOUSE 입니다 — 옛 즐겨찾기도 그대로 됩니다."
printf '%s\n' ""
printf '%s\n' "  ② 🔴 **필터 일곱이 복수 선택입니다.**"
printf '%s\n' "     · [전체 A/S 현황] 다섯 — 현재 상태 · 제품군 · 유·무상 · 고객사 · 우선순위"
printf '%s\n' "     · [기타건 현황] 둘   — 상태 · 공급처"
printf '%s\n' "     누르면 **체크박스 목록**이 펼쳐집니다. 닫힌 칸에는 「전체」 / 고른 이름 /"
printf '%s\n' "     「첫째 이름 외 N개」가 적힙니다."
printf '%s\n' "     🔴 **[현재 상태]에만 「입고품 전체」 단추가 있습니다**(나머지 여섯은 없습니다)."
printf '%s\n' "        그 단추는 **눌린 토글**입니다 — 손으로 상태를 하나씩 체크해 같은 묶음을"
printf '%s\n' "        만들어도 저절로 눌린 모습이 되고, 눌린 상태에서 다시 누르면 다 풀립니다."
printf '%s\n' "     🔵 바깥을 누르거나 Esc 로 접힙니다. **안을 눌러도 안 접혀야** 합니다 —"
printf '%s\n' "        접히면 체크 하나 누를 때마다 닫혀 복수 선택이 사실상 안 됩니다."
printf '%s\n' "     🔵 기타건 공급처의 「미지정」은 **목록의 한 줄**입니다(단축 단추가 아닙니다)."
printf '%s\n' ""
printf '%s\n' "  🔴 **눈에 안 보이는 커밋이 없습니다** — 다섯이 전부 화면을 바꿉니다."
printf '%s\n' "     🔵 그래서 「아무것도 안 바뀐 것 같다」면 **앱이 정말 새 태그로 도는지**"
printf '%s\n' "        먼저 보세요(58-deploy.sh 의 7절)."
printf '%s\n' ""
printf '%s\n' "🔴 **알고도 안 고친 것 — PO 가 모르는 것이 셋입니다**(55번에서 넘어옴)"
printf '%s\n' "   ① dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 APPROVAL_REQUIRED 가 없습니다."
printf '%s\n' "   ② PO 는 납품일 칸(delivered_date·delivered_by)을 모릅니다."
printf '%s\n' "   ③ PO 는 회차 승인(due_date_row_order)을 모른 채 같은 표를 고칩니다."
printf '%s\n' "   🔵 **지금은 안전합니다** — 운영에서 직원의 PO 접근 권한을 모두 빼 두셨습니다"
printf '%s\n' "      (2026-11-08). 🔴 **PO 를 다시 여는 날 셋을 한 묶음으로 이식해야 합니다.**"
printf '%s\n' "────────────────────────────────────────────────────────────"
# 🔴 **TARS 두 줄을 꼬리말 맨 끝에서 한 번 더 찍는다.**
#    쉰세째 때 위쪽 출력을 잘라 버려 **빈 표가 NAS 로 올라갔고 --preload 가 ✗ 둘로
#    멈췄다.** 출력이 잘려도 마지막 몇 줄은 남으므로, 여기서 다시 찍는다.
printf '\n%s\n' "🔴🔴🔴 **58-deploy.sh 의 TARS 두 줄 (다시 찍습니다 — 여기만 복사해도 됩니다)**"
printf '%s' "$TARTABLE"
printf '%s\n' "🔴🔴🔴 위 두 줄을 58-deploy.sh 의 TARS 에 **그대로** 붙여 넣은 뒤 scp 하세요."
printf '%s\n' "       (NAS 에서 재서 채우지 마세요 — 자기가 잰 값으로 자기를 재면 영영 통과합니다.)"
