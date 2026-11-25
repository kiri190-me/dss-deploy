#!/bin/bash
# dss-deploy/nas/setup/71-build.sh — 예순일곱째 배포 · 이미지 굽기 (2026-11-25)
#
# 🔵 **배포 회차와 파일 번호가 어긋나는 것은 이 저장소에서 원래 그렇다** —
#    66번이 예순두째, 67번이 예순세째, 68번이 예순네째, 69번이 예순다섯째,
#    70번이 예순여섯째였다. (56번은 2026-11-11 의 **양식 전용**이라 회차를 안 먹었다.)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴🔴 **맨 먼저 — 어느 판을 왜 베꼈는가** (지난 판 다섯이 전부 이 줄을 적었다)
# ══════════════════════════════════════════════════════════════════════
#   이 파일은 **66-build.sh(예순두째 · 2026-11-19)를 뼈대로** 쓰고, **집을 둘
#   다루는 법만 62-build.sh(쉰여덟째 · 2026-11-18)에서** 가져왔다.
#
#   ── 🔴 왜 **직전 판(70번)이 아닌가** ─────────────────────────────────
#   70번은 **집 하나(A/S) · 마이그레이션 0건**이라 **--migrate 도 place_migs() 도
#   묶음을 만드는 절도 아예 없다.** 70-deploy.sh 가 제 머리말에 이렇게 적어 두었다:
#       「묶음 값(MIGTAR_SIZE·MIGTAR_MD5)은 아예 없다 — 이번 판은 묶음을 안 만든다.
#        🔴 66번에는 그 변수 둘이 있었다. 묶음이 생기는 판에서는 **거기서 되살려라**」
#   🔴 **이번 판은 마이그레이션이 2건**(0132·0133)이고 A/S 의 마이그레이션은
#      **볼륨에서 돈다.** 70번을 베끼면 **0131 다음이 운영에 영영 안 올라간다.**
#
#   ── 🔴 왜 **66번인가** ───────────────────────────────────────────────
#   「A/S 마이그레이션이 **볼륨에서** 돈다」는 구조가 지금과 **토씨 하나 안 틀린다**:
#     · 묶음을 만드는 절(66-build.sh:2073-2132)
#     · 묶음을 푸는 place_migs()(66-deploy.sh:1653-1692)
#     · AS_VOL_SQL_WAS/WANT 로 **단계를 갈라** 재는 2-ㄷ 절
#     · go_gate 의 DB 관문(「도는가」가 아니라 **「답하는가」**)
#     · 서브모듈 핀 검사 3절(66-build.sh:804-899) — **이번 판도 dss-core 가 움직인다**
#
#   ── 🔴 62번에서 가져온 것 — **집이 둘이라서** ────────────────────────
#   「A/S 와 포털을 **같은 파일의 같은 표·같은 루프**로 올린」 유일한 판이 62번이다.
#     · IMAGES 표에 **저장소 칸**을 둔 행 꼴(62-build.sh:490-502)
#     · 굽기 고리가 그 칸으로 「cd」 하는 꼴(62-build.sh:2114-2134)
#     · REPOS 표로 집마다 기준 SHA·커밋 수·포트를 들고 다니는 꼴(62-build.sh:463-471)
#     · 집마다 다른 COPYRULES(62-build.sh:489-504) — 🔴 **A/S 는 drizzle 을 안 담고
#       포털은 담는다.** 한 줄로 베끼면 둘 중 하나가 **가짜 ✗** 가 된다.
#     · 「핵심 파일 표본」으로 ask_files 를 돌리는 꼴(62-build.sh:639-…) —
#       🔴 이번 A/S 는 바뀐 파일이 **179장**이라 전부를 넘길 수 없다.
#
#   🔴 **62-build.sh:34-35 의 경고를 그대로 지켰다**: A/S 전용 변수를 그대로 베끼면
#      **다른 집은 아무것도 안 재는 ✓** 가 된다. 이 파일의 집별 값은 **전부 표**에
#      들어 있고, 고리마다 「몇 집을 봤는가」를 끝에서 단언한다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **무엇이 없고 왜 없는가** — 다음 판이 「원래 없는 절」로 읽지 않게
# ══════════════════════════════════════════════════════════════════════
#   · **포털 쪽 묶음이 없다.** 포털은 마이그레이션이 **이미지 안에 구워져** 가고
#     (COPYRULES 의 auth|drizzle|yes), 이번 범위에 그 폴더가 **0줄** 바뀌었다.
#     🔴 그래서 묶음은 **A/S 하나뿐**이다. 「집이 둘이니 묶음도 둘」이 아니다.
#   · **포털 앱 번들의 기능 표식이 없다.** [실측] 이번 포털 커밋이 더한 코드에
#     **새 문자열 리터럴이 한 개도 없다** — 더한 것은 「tone?: number」(타입은 지워진다) ·
#     「TONE_COUNT = 16」(수) · 「toneIndex()」(지역 이름은 minify 가 줄인다) ·
#     객체 칸 이름 「tone」 뿐이다. 🔴 그리고 「tone」 은 번들에서 **"stone"·"milestone"
#     같은 낱말에도 걸려** ≥1 이 공짜다 — 판정에 쓰면 **아무것도 안 재는 ✓** 가 된다.
#     🔴 그래서 포털의 새 코드는 **도구 이미지에서 가린다**(소스가 글자 그대로 있다):
#       TONE_COUNT in src/lib/notifications/merge.ts — 기준 **0줄** → 지금 **3줄**.
#     🔵 62번이 계측기에서 똑같이 했다(62-build.sh:1842-1846 — 「계측기 앱은 마지막
#        커밋을 가리지 못합니다 … 마지막 커밋은 **도구 이미지**에서 가립니다」).
#   · **--verify 의 묶음 다시 만들기가 없다.** 만들면 md5 가 바뀐다(66번 그대로).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 올리는 것 — 세 갈래**
# ══════════════════════════════════════════════════════════════════════
#   ㄱ) **납기요청일 회차에 [납기일 확정]** 이 생긴다. 확정한 회차는 **종의 「납기
#      임박」에서 빠진다.** 🔴 DB 에 칸 **둘**이 는다(0133):
#        domestic_order_due_dates.confirmed_at (timestamptz, NULL 허용)
#        domestic_order_due_dates.confirmed_by (uuid, NULL 허용 · users 참조)
#   ㄴ) **기타건 납기 임박** — 수리 건이 안 붙은 내자 줄의 납기요청일이 다가오면
#      종이 운다(새 알림 종류 DOMESTIC_ORDER_DUE_DATE_NEAR). DB 칸은 안 는다.
#   ㄷ) **절차/진단 노드에 「관련 파일」 한 자리**가 생긴다. 🔴 DB 에 칸 **둘**이
#      는다(0132): procedure_template_nodes.share_doc_relative_path ·
#      repair_case_flowchart_nodes.share_doc_relative_path (둘 다 text · NULL 허용).
#   ㄹ) 🔴 **포털도 올라간다** — A/S 가 보내기 시작한 **색 칸 번호(tone)**를 받아
#      종까지 나른다. 🔴 **포털은 이번에 「안 건드리는 집」이 아니다.**
#
#   [실측 2026-11-25] 두 .sql 을 합쳐 — RENAME **0** · DROP/DELETE/TRUNCATE **0** ·
#   INSERT **0** · CREATE TABLE **0** · ADD COLUMN **4**. 🔵 ON DELETE 가 0133 에
#   **1줄** 있다(restrict) — 🔴 그것은 「지우는 문장」이 아니다. 잣대가 그것을
#   안 세는지 4-ㄱ 이 **표본으로 먼저** 잰다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **66번의 전제 중 이번에 깨지는 것 아홉 — 하나씩 재서 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴🔴 **집이 둘이다**(66번은 하나). 굽는 것이 **둘 → 넷**이고, 2·3·5절의
#      고리가 전부 **집마다** 돈다. 🔴 「몇 집을 봤는가」 관문도 **둘**이 기대값이다.
#
#   ② 🔴 **마이그레이션이 1건이 아니라 2건이다**(0132 · 0133).
#      [실측] 저장소 .sql **134장** · journal idx **134** · 0134 는 **없다** ·
#      이번 범위의 drizzle/ 변경 **5줄**(.sql 둘 · 스냅샷 둘 · _journal.json).
#      🔴 66번의 AS_THIS_MIG(한 글자)를 **목록 AS_NEW_MIGS 로** 바꿨다 — 한 글자로
#         두면 둘째 장이 **아무 검사도 안 받는다.**
#      🔴 **drizzle 는 밀린 것을 한 트랜잭션에 넣는다** — 둘이 한 판에 올라간다.
#         두 .sql 다 **더하기만** 하므로 섞여도 안전하다(4-ㄷ 이 값으로 잰다).
#
#   ③ 🔴 **바뀐 파일이 179장이다**(66번은 24장). [실측 · 기준 59d853ab]
#      src/ **165** · scripts/ **7** · drizzle/ **5** · vendor **1** · 그 밖 1 ·
#      새 파일 **63** · 지운 파일 **0** · 괄호 **4** · 대괄호 **5**.
#      🔴 **그래서 ask_files 에 179장을 다 넘기지 않는다** — 62번처럼 **핵심 파일
#         스무 장**을 골라 넘긴다(괄호·대괄호가 든 줄 **셋**을 일부러 넣었다).
#      🔵 그 밖 1장은 저장소 뿌리의 진행현황 HTML 이다 — **이미지에 안 들어간다**
#         (Dockerfile 의 COPY 가 src·scripts·vendor·설정 넷만 담는다).
#
#   ④ 🔴🔴 **기준 SHA 뒤로 커밋이 하나 더 밀렸다 — 그래도 파일 수는 179 그대로다.**
#      지시서는 「기준 59d853ab → 18e35c9a · **50커밋** · 179파일」로 왔는데
#      [실측 2026-11-25] main 이 **56effcc8** 이고 **51커밋**이다. 더 밀린 한 커밋은
#        56effcc8 [현황판] 「배포는 A/S 하나로 끝난다」를 바로잡는다
#      이고 **그 HTML 한 장만** 고쳤다 — 그 장은 18e35c9a 까지의 179장에 이미 들어
#      있어서 **파일 수가 안 늘었다.** 🔴 그래서 AS_COMMITS_WANT 는 **51** 이다.
#      🔵 커밋 수 어긋남은 **⚠️ 로만** 센다(66번과 같다) — 굽기 전에 또 하나 밀릴 수
#         있다. 🔴 다만 **파일 수가 늘면** 5-ㅁ 이 먼저 ⚠️ 를 내므로 거기서 멈춰 보라.
#
#   ⑤ 🔴 **새 시험이 43장이다**(66번은 5장). [실측] 바뀐 시험 **86장** ·
#      그중 새것 **43장**. 🔴 목록 줄 수 **4200 → 4787**.
#        unit 2067→2226 · components 1528→1908 · db 591→639 · db-safety 14→14
#      🔴 **A/S 는 목록 파일 방식이라 적어야 돈다** — 빠뜨리면 **오류 없이 조용히
#         안 돈다.** 새 43장을 **한 장씩** 묻는다(줄 수만으로는 못 말한다).
#      🔵 **포털은 방식이 다르다** — package.json 의 「test」 줄에 **경로를 하나씩**
#         나열한다. [실측] 기준 **64개** → 지금 **64개**(새 시험 0장 · 바뀐 둘은
#         이미 적혀 있다). 🔴 **글롭 방식으로 착각해 이 절을 빼면** 포털의 시험
#         등록이 아무 검사도 안 받는다.
#
#   ⑥ 🔴 **표식을 전부 갈았다. 뒷걸음은 여덟 → 아홉으로 한 칸 늘렸다.**
#      🔴 기능 표식이 **셋**이다 — 이 배포가 세 갈래라서다. 하나로 두면 **둘째·셋째
#         갈래가 안 담긴 이미지**를 못 가른다.
#          shareDocRelativePath              기준 0 → 지금 36파일 (객체의 칸 이름)
#          DOMESTIC_ORDER_DUE_DATE_NEAR      기준 0 → 지금  6파일 (알림 종류 코드)
#          DOMESTIC_ORDER_DUE_DATE_CONFIRMED 기준 0 → 지금  5파일 (알림 종류 코드)
#      🔵 셋 다 **minify 를 견디는 꼴**이다 — 앞은 객체 칸 이름이고(minify 는 칸
#         이름을 기본으로 안 건드린다 — 건드리면 JSON 과 어긋난다) 뒤 둘은
#         **대문자 문자열 리터럴**이다.
#      🔴 **곁들이**(판정에 안 쓴다) = share_doc_relative_path — DB 칸 이름이고
#         vendor/dss-core 의 text("share_doc_relative_path") **리터럴**로 번들에
#         들어간다. [실측] src/ 에서 기준 0 → 지금 5파일.
#      🔴 **뒷걸음 아홉**(하나도 빼지 마라 — 한 번 빼면 다시 넣는 사람이 없다):
#          도번 / 비고                   예순여섯째 · 기준 1  → 지금 1   ← **이번에 늘린 칸 · 🔴 한글**
#          hasLiveApproval               예순네째   · 기준 4  → 지금 4
#          domesticOrders.completedEdit  예순세째   · 기준 11 → 지금 12
#          faultTags                     예순두째   · 기준 13 → 지금 13
#          radiogroup                    예순한째   · 기준 2  → 지금 2
#          "ORDER_ISSUED"                예순째     · 기준 2  → 지금 2
#          domestic-order-status-filter  쉰아홉째   · 기준 3  → 지금 3
#          portal_approval_delegations   쉰여덟째   · 기준 26 → 지금 26
#          domesticOrders.view           쉰여섯째   · 기준 17 → 지금 17
#      🔴🔴 **맨 위의 그 한 줄이 한글이다 — 첫 --go 에서 ✗ 가 났고 고친 자리다.**
#         처음에는 「표식은 전부 ASCII」를 지키려고 같은 커밋의 ASCII 쪽
#         (part.drawingNo, part.note)을 골랐는데, 🔴 **그것은 70번의 TOOLMARK_ASCII**
#         **(도구 이미지용)이고 번들용이 아니었다.** part 가 지역 이름이라 minify 가
#         갈아 치워 **번들에서 0/0** 이다[실측 · dss-as:6.2].
#         🔴 70번이 **번들에서 실제로 쓴 글자는 한글**(placeholder 의 문자열 리터럴)
#            이고, 그것만이 그 판을 가린다. [실측] 옛 판 6.1 **1/1** · 새 판 6.2 **1/1**.
#         🔴 그래서 **「이 파일의 표식은 전부 ASCII」가 이 판에는 거짓**이다 —
#            대신 70번의 **바이트 확인 절(1-ㄷ)**을 함께 가져왔다. 자세한 까닭과
#            실측값은 KO_MARKS 의 주석에 있다.
#
#   ⑦ 🔴 **마지막 커밋 표식이 집마다 하나씩 둘이다.**
#      · A/S  : ExecutionNodeShareDocRow in
#               src/components/procedures/execution/CurrentTaskCard.tsx
#               [실측] 그 파일 안에서 기준 **0줄** → 지금 **2줄**(import + 쓰는 줄).
#        🔴 **새로 생긴 파일을 과녁으로 안 삼았다** — 새 파일이면 「기준 0줄」이
#           파일이 없어서 0 인 것이라 아무것도 안 가른다. 이 과녁은 **기준판에도
#           있던 화면**이고, **마지막 코드 커밋(c9e5721f)에서만** 바뀌었다.
#        🔴 **18e35c9a·56effcc8 은 둘 다 진행현황 HTML 한 장짜리라 이미지에 아무
#           자취도 안 남긴다** — 그래서 「마지막 커밋」의 과녁은 c9e5721f 다.
#      · 포털 : TONE_COUNT in src/lib/notifications/merge.ts
#               [실측] 기준 **0줄** → 지금 **3줄**.
#
#   ⑧ 🔴 **tar 크기 견주기 기준값이 넷으로 는다 — 전부 strict.**
#      지난 판 바이트의 출처(이 저장소의 배포본에 적힌 값을 눈으로 맞댄 것):
#        dss-as-6.1.tar        136193536   70-deploy.sh 의 TARS
#        dss-as-tools-28.tar   226646528   70-deploy.sh 의 TARS
#        dss-auth-2.2.tar      113711104   62-deploy.sh 의 TARS
#        dss-auth-tools-5.tar  212409856   62-deploy.sh 의 TARS
#      [실측] 두 집 다 package.json·package-lock.json·tsconfig.json·
#      drizzle.config.ts 의 변경이 **0장**이다 — 라이브러리가 한 개도 안 늘었다.
#      🔴 그래서 **넷 다 strict**(25% 넘으면 ✗)로 둔다.
#
#   ⑨ 🔴 **서브모듈이 또 움직인다 — 그리고 README 의 옛 핀이 낡았다.**
#      [실측 2026-11-25] dss-core **1e9ec85 → 191676f**(커밋 **2** · 파일 **3**) ·
#      dss-ui **1210d112 그대로**(A/S·포털 둘 다).
#      🔴 **README.md:558 에 적힌 옛 핀 b79e5ab8 을 베끼지 마라** — 그것은
#         **쉰여덟째(62번) 때 값**이고, 예순두째(66번)가 이미 1e9ec85 로 한 번 더
#         옮겼다. **71번의 옛 핀은 1e9ec85** 다. (README 를 고치는 것은 배포가 끝난
#         뒤의 일이라 이 조각은 안 건드렸다 — 보고에만 적었다.)
#      🔵 **포털에도 서브모듈이 하나 있다**(vendor/dss-ui · 62번에 처음 생겼다).
#         🔴 포털 **tools 는 vendor 를 안 담는다** — builder 만 @dss/ui 를 쓴다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **66번에서 그대로 살린 것 — 한 번 빼면 다시 넣는 사람이 없다**
# ══════════════════════════════════════════════════════════════════════
#   · 0절 Git Bash 판정(/mnt/ 로 시작하면 ✗)            → 참. 그대로.
#   · 🔴 **1-ㄴ 경로 번역 검사**(MSYS_NO_PATHCONV)       → 참. **맨 앞에 둔다.**
#     이것이 없어서 쉰여덟째에 **가짜 ✗ 일곱**을 헤맸다.
#   · 2절 「미푸시 0 과 **안 받은 것도 센다**」          → 참. 집마다.
#   · 「굽기 전에 서브모듈 작업본이 체크아웃돼 있는가」 → 참.
#   · tar 크기를 **두 번** 견주기(지난 판 tar 와 · 그 이미지 자신과) → 참.
#   · 「grep -c 는 0 일 때 종료 코드 1」·「tar | grep -q 는 SIGPIPE」·
#     「bash -n 이 못 잡는 둘」·「8진수로 읽히는 0132·0133」 → 전부 참. 같은 규율.
#   · 함수 정의에 붙인 **</dev/null** · 고리마다 **「몇 개를 봤는가」 관문** → 참.
#   · 「✗ 가 나도 지문 줄만은 찍는다」 → 참. **세 자리**에서 찍는다.
#     🔴 묶음 값 둘(MIGTAR_SIZE·MIGTAR_MD5)도 함께 찍는다.
#   · 「docker build 는 dev 서버를 안 내려도 된다(.dockerignore 가 .next 를 막는다)」
#     → 참. 🔵 **3000·3100·5442·5444 가 떠 있는 것이 정상이다** — 7-ㄴ 이 값으로
#     찍기만 하고 판정에 안 쓴다.
#   · --verify 모드(이미 구운 것을 **다시 굽지 않고** 안만 재고 지문만 찍는다) → 참.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **66·65번에서 가져온 결함 고침 둘 — 빠뜨리면 같은 일이 또 난다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 **stdin 을 빨아들이는 명령을 고리 안에서 부르면 고리가 한 바퀴만 돈다.**
#      처방 둘을 **함께**: **-i 를 떼고**, **함수 정의에 </dev/null 을 붙인다.**
#      🔴 그리고 **「몇 개를 봤는가」를 고리마다 세어 끝에서 단언한다.**
#      🔴 **이번 판은 집이 둘이라 이 결함이 실제로 터질 수 있다** — 66·70번은 집이
#         하나라 「한 바퀴만 돌아도」 티가 안 났다.
#   ② 🔴 **Git Bash 가 docker.exe 에 넘기는 「/ 로 시작하고 빈칸 없는」 인자를
#      윈도우 경로로 번역한다.** [실측 2026-11-18] 그것 하나로 **가짜 ✗ 일곱**이 났다.
#      처방 셋을 **다 쓴다**: dockr() 로 **docker 를 부를 때만** 끄고 ·
#      **그것이 정말 꺼졌는지 값으로 재고**(1-ㄴ) · 파일 경로는 **상대로 넘긴다.**
#      🔴 **전역 export 로 끄면 git 이 깨진다 — 실제로 깨뜨려 봤다**(✗ 스물한 개).
#
# ── 돌리는 법 (개발 PC · PowerShell 에서 Git Bash 를 부른다) ──────────
#     cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#     & "C:\Program Files\Git\bin\bash.exe" ./71-build.sh --check
#     & "C:\Program Files\Git\bin\bash.exe" ./71-build.sh --go
#
#   🔴 **bash.exe 만 치면 WSL 이 잡힌다**(2026-11-04 에 걸렸다). WSL 에서 돌면
#      도커가 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 내어 ✗ 가 흩어져
#      난다. 단서는 로그의 뿌리 경로가 **/mnt/c/…** 인 것이다 — 0절이 값으로 잰다.
#   🔴 **스크립트에 건네는 경로에는 역슬래시를 쓰지 않는다.** 역슬래시를 주면
#      bash 가 그것을 먹어 "C:Users희만Desktop…" 이 되어 No such file 이 난다.
#
#   둘째 인자로 산출물을 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-71):
#     & "C:\Program Files\Git\bin\bash.exe" ./71-build.sh --go "/d/배포본/_images-71"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다.
#      이 파일을 쓴 쪽은 **한 번도 굽지 않았다** — 재기만 했다.
#
# ── 이번에 굽는 것 — **이미지 넷 + 묶음 하나** ───────────────────────
#     ① A/S 앱    dss-as:6.1       → dss-as:6.2          커밋 51
#     ② A/S 도구  dss-as-tools:28  → dss-as-tools:29     🔴 --target tools
#     ③ 포털 앱   dss-auth:2.2     → dss-auth:2.3        커밋 1
#     ④ 포털 도구 dss-auth-tools:5 → dss-auth-tools:6    🔴 --target tools
#     ⑤ 🔴 **묶음 as-migrations.tar.gz** — drizzle/ **134장** (A/S 전용)
#   🔴 **묶음을 빠뜨리면 마이그레이션이 운영에 안 올라간다.** A/S 도구 이미지의
#      /app/drizzle 은 **비어 있고**(5절이 값으로 잰다) 운영에서는 거기에
#      /volume1/dss/as-migrations 가 붙는다 — 0132·0133 은 **이 묶음으로만** 간다.
#   🔴 **나머지 일곱 집은 안 굽는다** — 이번 범위에 한 줄도 없다.
#
# ── 🔴 모드 셋 ────────────────────────────────────────────────────────
#   --verify 🔴 **이미 구운 넷을 다시 재기만 한다.** docker build 도 docker save 도
#            한 줄 안 돌린다. 🔴 6절의 기대값이 **뒤집힌다** — 태그가 **있어야** 한다.
#            🔴 **묶음도 다시 안 만든다** — 있으면 열어서 재고 지문만 찍는다.
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다(폴더도).
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면 멈춘다.
#            전부 ✓ 일 때만 **넷을 굽고** tar 로 뽑고 **이미지 안을 세고**
#            **묶음을 만들어 그 안까지 센다.**
#   🔵 세 모드가 **같은 함수**로 잰다(check_all · inside_check). 두 벌로 적으면 어긋난다.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 tar 크기를 **두 번** 견준다 ────────────────────────────────────
#   ① **지난 판 tar 와** 견준다(넷 다 값이 있다 — 아래 IMAGES 표 주석).
#   ② **그 이미지 자신과** 견준다. 가지가 둘이다:
#      · containerd 저장소면 inspect .Size 가 **압축된 내용 크기**라 90~110%.
#      · 고전 저장소면 **펼친 크기**라 tar 는 그 **1/4쯤**(10~45%).
#   🔴 **tar 지문은 'docker image inspect' 의 .Id 와 맞대지 않는다.** 그것은 애초에
#      다른 값이다. 맞댈 상대는 **빌드 로그의 'exporting config sha256:'** 이다.
#
# ── 🔴 이 환경의 함정 (36~70-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싼다. 저장소 자리를 적어
#      넣지 않고 **이 파일의 자리에서 계산한다**(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:/… 를 /c/… 로 바꾸고,
#      docker save 와 **묶음 만들기**는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를 막는다).
#   ④ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다.** 이 파일의 표식은 **전부
#      ASCII** 다 — 8진 이스케이프가 한 군데도 없다.
#   ⑤ 🔴 **이번 범위에는 괄호가 든 경로가 4장 · 대괄호가 든 경로가 5장 있다.**
#      목록을 넘기는 길은 **here 문서 + while read** 와 **grep -Fx** 로만 썼고,
#      컨테이너 안에서도 **set -f** 로 글롭을 끈다.
#      🔵 대괄호 폴더의 시험이 조용히 안 돈 적이 이 저장소에 있다 — 거기서 온 규율이다.
#   ⑥ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」 같은
#      안전망을 달면 **하필 바라던 0 에서만** 그것이 터져 값이 "0 ?" 가 된다.
#      이 파일은 그 꼴을 **한 군데도 쓰지 않는다** — 「$( … || true )」 로 받는다.
#   ⑦ 🔴 **tar | grep -q 를 if 에 바로 물리지 않는다.** set -uo pipefail 아래서
#      grep -q 가 먼저 끝나면 앞의 tar 가 SIGPIPE 로 죽어 **파일이 있을 때 오히려
#      ✗** 가 난다. 이 파일에서 tar 를 읽는 자리는 **전부 세어서 담는 꼴**
#      (grep -c · grep -o)로만 적었고 grep -q 에 무는 자리가 한 군데도 없다.
#   ⑧ 🔴 **CRLF.** 이 저장소들의 작업본은 전부 CRLF 다. Git Bash 의 grep 만 \r 를
#      걷어내고 리눅스 컨테이너의 GNU grep 은 안 걷어낸다. 줄 전체로 맞대는
#      검사(-Fx)는 **읽자마자 tr -d 로 \r 를 걷어낸 뒤** 맞댄다.
#   ⑨ 🔴 **빈 결과는 삼켜진 오류일 수 있다.** 목록을 읽는 자리는 **읽은 줄 수를
#      함께 받아** 너무 적으면 ✗ 로 세고, **없는 경로 하나를 일부러 함께 묻는다.**
#   ⑩ 🔴 **bash 의 $(( )) 는 0 으로 시작하는 수를 8진수로 읽는다** — 0132·0133·0134 를
#      셈에 넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
#   ⑪ 🔴 **drizzle 는 밀린 마이그레이션을 한 트랜잭션에 넣는다.** 이번은 **2건**이라
#      둘이 한 판에 들어간다 — 둘 다 **더하기만** 하는지 4-ㄷ 이 **장마다** 잰다.
#      그리고 **0134 가 생겼는지**를 값으로 본다(생기면 전제가 깨진다).
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안의 백틱은 명령 치환으로 읽힌다 → 이 파일에는 백틱이 **한 개도 없다.**
#   ② 읽기 전용 자리의 콜론과 꺾쇠로 빈 파일을 만드는 꼴은 ash 를 죽인다 →
#      이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   🔴 19·20·21번에는 그 둘이 아직 남아 있다. **거기서 베껴 오지 마라.**
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail

# ══════════════════════════════════════════════════════════════════════
# 🔴 **Git Bash 가 /app/… 을 C:/Program Files/Git/app/… 으로 바꾼다** (결함 ②)
# ══════════════════════════════════════════════════════════════════════
#   docker.exe 는 **윈도우 프로그램**이라 MSYS 런타임이 인자를 넘기기 전에
#   「유닉스 절대경로처럼 생긴 것」을 윈도우 경로로 **조용히 번역한다.** 값에
#   빈칸이 없고 / 로 시작하면 걸린다:
#
#       docker run -e F="/app/src/x.ts" …  →  컨테이너 안에서 $F 가
#       C:/Program Files/Git/app/src/x.ts  가 되어 [ -f "$F" ] 가 거짓이 된다
#
#   🔴 **전역 export 로 끄지 않는다** — git 이 깨진다. docker 를 부르는 자리에만
#      붙인다. 같은 셸에서 git 은 그대로다.
dockr() { MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker "$@" </dev/null; }
# 🔵 </dev/null 은 결함 ① 의 처방이다. docker run 은 -i 가 없으면 stdin 을 안 읽지만,
#    나중에 누가 -i 를 되살려도 **고리가 살아남게** 함수 정의에 붙여 둔다.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEV=${DSS_DEV:-$(cd "$SCRIPT_DIR/../../.." && pwd)}

PASS=0; FAIL=0; UNK=0
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
unk()  { UNK=$((UNK+1));   printf '  ? %s — 못 쟀다 (%s)\n' "$1" "$2"; }
note() { printf '  ⚠️ %s\n' "$1"; }
say()  { printf '    %s\n' "$1"; }
step() { printf '\n%s\n' "── $1"; }
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

# tar 안 manifest.json 의 Config 지문 (39~70-build.sh 의 것을 글자 그대로)
tar_config_id() { # 1 tar
  tar -xOf "$1" manifest.json 2>/dev/null \
    | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 \
    | sed 's|blobs/sha256/|sha256:|'
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

# 🔵 포털의 시험 등록은 package.json 의 「test」 줄에 **경로를 나열**하는 방식이다.
#    그 줄에서 *.test.ts 꼴을 세어 돌려준다. (A/S 는 목록 파일 방식이라 다르다.)
count_test_paths() { # stdin = package.json
  sed -n 's/.*"test": "\(.*\)",/\1/p' | tr ' ' '\n' | grep -c '\.test\.ts' || true
}

# ══════════════════════════════════════════════════════════════════════
# ══ 이번 판의 값 — 한자리에 모아 둔다 ═════════════════════════════════
# ══════════════════════════════════════════════════════════════════════
#
# ── 🔴 저장소 **둘** (62번의 REPOS 표를 가져왔다) ─────────────────────
#   열쇠|폴더|사람이 부르는 이름|기준 SHA|기준→main 커밋 수|개발 포트|public 이 있나
#   🔴 기준 SHA 의 출처:
#      A/S   59d853ab  예순여섯째(70번)가 올린 커밋 — 「[부품요청] 재고의 비고로도
#                      부품을 찾는다」[실측으로 확인했다]
#      포털  e05f233   쉰여덟째(62번)가 올린 커밋
REPOS='
as|RF_Service_System|A/S관리|59d853ab|51|3000|yes
auth|dss-auth|통합로그인포털|e05f233|1|3100|yes
'
REPOS_WANT=2
# 🔵 DB 는 dss-pg-app(5442) · dss-pg-auth(5444)가 개발 PC 에 떠 있다. 🔴 **끄지
#    않는다** — 이 파일은 DB 에 한 번도 안 붙는다(개발 PC 에서는 운영 DB 를 못 본다).
DB_PORTS='5442 5444'

# ── 🔴 굽는 **넷** (62번의 행 꼴 — 저장소 칸이 둘째다) ────────────────
#   열쇠|저장소폴더|새 태그|타깃(-=기본 runner)|지난판 tar 이름|지난판 tar 바이트|엄함
#   🔴 지난판 바이트의 출처는 머리말 ⑧ 에 적어 두었다.
#   🔵 엄함: strict = 25% 넘으면 ✗ · loose = 25% ⚠️ · 60% 넘으면 ✗ · none = 건너뛴다
#   🔴 **넷 다 strict 다** — [실측] 두 집 다 의존성 파일이 **한 장도 안 바뀌었다**.
IMAGES='
as|RF_Service_System|dss-as:6.2|-|dss-as-6.1.tar|136193536|strict
astools|RF_Service_System|dss-as-tools:29|tools|dss-as-tools-28.tar|226646528|strict
auth|dss-auth|dss-auth:2.3|-|dss-auth-2.2.tar|113711104|strict
authtools|dss-auth|dss-auth-tools:6|tools|dss-auth-tools-5.tar|212409856|strict
'
HOWMANY=4
# 🔴 **태그 번호를 지어내지 않았다.** 읽은 자리:
#    dss-as:6.1 · dss-as-tools:28       → 70-build.sh:393-394 (IMAGES) · 70-deploy.sh:336-337 (TARS)
#    dss-auth:2.2 · dss-auth-tools:5    → 62-build.sh:493-494 (IMAGES) · 62-deploy.sh:319-320 (TARS)
#    🔵 **포털은 62번(쉰여덟째) 뒤로 한 번도 안 올라갔다** — nas/setup 전체를 훑어
#       dss-auth 태그의 가장 큰 값이 2.2 · tools 5 임을 값으로 확인했다.

# ── 🔴 마이그레이션 — **A/S 2건 · 포털 0건** ─────────────────────────
#   저장소가 들고 있어야 하는 수 · 운영이 지금 들고 있는 수 · 그 다음 번호
#   🔴 **132 → 134 로 는다.** 이 수가 묶음 검사에도 그대로 쓰인다.
AS_SQL_WANT=134
AS_SQL_WAS=132
#   🔴 이번 범위의 drizzle/ 변경은 **5줄**이다:
#      drizzle/0132_powerful_galactus.sql · drizzle/0133_brown_green_goblin.sql ·
#      drizzle/meta/0132_snapshot.json · drizzle/meta/0133_snapshot.json ·
#      drizzle/meta/_journal.json
AS_DRIZZLE_DIFF_WANT=5
#   🔴 **이번 판이 올리는 번호는 둘이다**(66번은 하나였다 — 한 글자로 두면 둘째
#      장이 아무 검사도 안 받는다). 「생기면 안 되는 것」은 0134 다.
AS_NEW_MIGS='0132 0133'
AS_NEW_MIGS_WANT=2
AS_NEXT_MIG=0134
#   🔴 두 .sql 을 합친 기대값 — 4-ㄷ 이 **장마다** 재고 합도 본다.
AS_ADDCOL_WANT=4
# ── 🔵 포털은 **0건**이다 — 그래도 절을 빼지 않는다 ──────────────────
#   🔴 포털은 마이그레이션이 **이미지 안**에서 돈다(COPYRULES 의 auth|drizzle|yes).
#      그래서 묶음이 없고, 도구를 구우면 그 안에 11장이 그대로 실려 간다.
AUTH_SQL_WANT=11
AUTH_DRIZZLE_DIFF_WANT=0
# 🔵 **운영이 지금 들고 있어야 하는 수** — 개발 PC 에서는 못 잰다. 71-deploy.sh 가
#    DB 에 물어 확인하고, **바뀌었으면 거기서 멈춘다.** 여기서는 찍어 두기만 한다.
PROD_MIGS_NOTE='A/S 132 → 134 · 재고 28 · 휴가 5 · 포털 11(그대로) · 계측기 3'

# ══ 🔴 마이그레이션 안전 잣대 — 62·66번에서 글자 그대로 가져왔다 ══════
#   🔴 **잣대가 죽어 있으면 「지우는 문장 0줄」이 아무것도 안 재는 ✓ 가 된다.**
#      그래서 4-ㄱ 이 표본 **일곱**으로 **잣대부터** 잰다.
#   🔴 **이번 판에 표본이 하나 늘었다** — 0133 에 「ON DELETE restrict」 가 **1줄**
#      있다. 「ON DELETE 가 「지우는 문장」 검사에 걸린다」가 이 저장소에 적혀 있고,
#      그때는 **표만 더하는 판이 ✗** 가 됐다. 🔴 그래서 「ON DELETE 를 안 세는가」를
#      **표본으로 못 박았다.**
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
SQL_COMMENT_RE='^[[:space:]]*--'
MIG_DROP_WANT=0
# 🔴 **묶음을 통째로 갈아 끼우므로 창 안을 다 본다** — .sql 과 스냅샷이 짝인가.
AS_KEEP_MIGS='0127 0128 0129 0130 0131 0132 0133'
AS_KEEP_MIGS_WANT=7

# ══ 🔴 서브모듈 — **dss-core 가 또 움직인다** ═════════════════════════
#   [실측 2026-11-25] dss-core 1e9ec85 → 191676f (커밋 2 · 파일 3) ·
#                     dss-ui 1210d112 그대로(A/S·포털 둘 다).
#   🔴 **README.md:558 의 옛 핀 b79e5ab8 은 낡았다**(머리말 ⑨). 71번의 옛 핀은 1e9ec85 다.
AS_CORE_PIN=191676fa65fe7dfe285c21d6926c4d47a75d3a59
AS_CORE_PREV_PIN=1e9ec85535a2718901879639dd4dd3557d8af357
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425
# 🔵 작업본이 **새 핀 위에** 서 있어야 한다 — 핀보다 앞서 있으면 안 올라간 커밋을 굽는다.
AS_CORE_COMMITS_WANT=0
# 🔴 옛 핀 → 새 핀 사이의 커밋 수 · 바뀐 파일 수. **움직였다는 것을 값으로 잰다.**
AS_CORE_MOVED_COMMITS=2
AS_CORE_MOVED_FILES=3
# 🔴 **핀만 보면 빈 서브모듈도 통과한다** — 쉰여덟째가 올린 것이 거기 있는지 함께 본다.
AS_CORE_KEEP_FILE=src/schema/portal-approval-delegations.ts
AS_CORE_KEEP_TABLE=portal_approval_delegations
AS_CORE_KEEP_EXPORT=portal-approval-delegations
# 🔴 **이번 판이 그 안에 더한 것 — 파일 셋에 칸 넷이다.**
#   파일|DB 칸 이름|속성 이름
#   🔴 셋을 **다** 본다. 하나만 보면 「세 갈래 중 하나만 담긴 공용 스키마」를 못 가른다.
AS_CORE_NEW='
src/schema/domestic-order-due-dates.ts|confirmed_at|confirmedAt
src/schema/domestic-order-due-dates.ts|confirmed_by|confirmedBy
src/schema/procedure-template-nodes.ts|share_doc_relative_path|shareDocRelativePath
src/schema/repair-case-flowchart-nodes.ts|share_doc_relative_path|shareDocRelativePath
'
AS_CORE_NEW_WANT=4

# ══ 🔴 바뀐 파일 수 — 집마다 [실측 2026-11-25] ════════════════════════
#   열쇠|전체|src/|scripts/|drizzle/|vendor+.gitmodules|새 파일|지운 파일|괄호|대괄호|시험
#   🔴 **A/S 는 66번과 한 자리도 같지 않다**(머리말 ③).
#   🔵 A/S 의 165+7+5+1 = 178 이고 나머지 1장은 **저장소 뿌리의 진행현황 HTML**이다
#      — 이미지에 안 들어간다.
#   🔵 포털은 src/ 5 + docs/ 1 = 6 이다. 새 파일 0 · 지운 파일 0 · 괄호 0 · 대괄호 0.
CHANGED='
as|179|165|7|5|1|63|0|4|5|86
auth|6|5|0|0|0|0|0|0|0|2
'
CHANGED_WANT=2

# ══ 🔴 npm 명령 수 — 집마다 [실측 2026-11-25] ═════════════════════════
#   열쇠|기준|지금
#   🔴 「안 걸린다」도 **값으로 잰다.** 바뀌었는데 안 적어 두면 다음 판이 그 거짓을
#      근거로 「안 구워도 된다」를 꺼낸다(41번이 Missing script 로 데였다).
NPMCOUNT='
as|39|39
auth|26|26
'
NPMCOUNT_WANT=2

# ══ 🔴 **도구를 굽는 까닭** — 값으로 가린다 ═══════════════════════════
#   ㄴ) tools 스테이지가 담는 것 중 바뀐 파일 수.
#      🔴 A/S 는 **179 중 173**(빠지는 여섯은 drizzle/ 다섯과 뿌리의 HTML 한 장 —
#         A/S tools 는 drizzle 을 **안 담는다**). 포털은 **6 중 5**(빠지는 하나는 docs/).
#
#   🔴🔴 **정규식을 | 로 나누는 표에 넣지 않는다 — 정규식 안에 | 가 들어 있다.**
#      [실측 2026-11-25 · 첫 --go] 처음에는 「열쇠|정규식|기대 수」 로 적었는데,
#      IFS='|' read 가 **정규식을 토막 내어** RE 가 「^(src/」 가 됐다. 그래서
#        grep: Unmatched ( or \(
#      로 grep 이 죽고 수가 **?** 가 되어 **⚠️ 둘**이 났다. 기대값 칸에는 정규식의
#      꼬리가 들어가 메시지까지 깨졌다.
#      🔵 **66번은 TOOLS_PAYLOAD_RE 가 스칼라 하나**라 이 함정이 없었다 — 집이 둘이
#         되면서 표로 옮긴 것이 화근이다. **정규식은 스칼라로 되돌리고** 표에는
#         **열쇠와 기대 수만** 둔다.
#      🔴 **다른 표들은 괜찮다** — COPYRULES 의 정규식에는 | 가 없고(값으로 확인),
#         APPMARKS 의 표식에도 없다. 이 한 자리만 정규식에 | 가 있었다.
AS_PAYLOAD_RE='^(src/|scripts/|vendor/|package\.json|tsconfig\.json|drizzle\.config\.ts)'
AUTH_PAYLOAD_RE='^(src/|scripts/|package\.json|tsconfig\.json|drizzle\.config\.ts)'
payload_re() { # 1 집 열쇠
  case "$1" in
    as)   printf '%s' "$AS_PAYLOAD_RE" ;;
    auth) printf '%s' "$AUTH_PAYLOAD_RE" ;;
  esac
}
TOOLS_PAYLOAD='
as|173
auth|5
'
TOOLS_PAYLOAD_WANT=2
# 🔴 **잣대가 살아 있는가를 표본으로 먼저 잰다** — 이것이 있었으면 위 결함이
#    첫 --check 에서 잡혔다. 담기는 줄 하나와 안 담기는 줄 하나를 함께 묻는다.
PAYLOAD_PROBE_HIT='src/lib/x.ts'
PAYLOAD_PROBE_MISS='docs/x.md'
#   ㄷ) 🔴 **도구의 import 닫힘** — scripts/ 가 그 모듈을 import 로 부르는 자리.
#      파일|그 파일이 import 하는 모듈
#   🔵 **이번 판에도 이 잣대가 안 걸린다** — 과녁(domestic-order-list.ts)이 이번
#      범위에 **0줄**이다. 🔴 그래도 절을 빼지 않고 **잣대가 살아 있는지**를 잰다:
#      그 둘이 아직 그 모듈을 부르는가(2장 · 각 1줄) · 과녁이 바뀐 목록에 몇 줄인가(0).
#      빼면 다음 판이 「ㄷ 는 원래 없는 절」로 읽는다.
TOOL_IMPORTERS='
scripts/lib/delivered-date-sync-survey.ts|../../src/lib/domain/domestic-order-list
scripts/lib/requested-due-date-sync-survey.ts|../../src/lib/domain/domestic-order-list
'
TOOL_IMPORTERS_WANT=2
TOOL_IMPORT_TARGET=src/lib/domain/domestic-order-list.ts
TOOL_IMPORT_TARGET_WANT=0

# ══ 🔴 Dockerfile 이 담는 길 — **집마다 다르다** ══════════════════════
#   열쇠|정규식|있어야 하나(yes/no)|사람이 읽을 말
#   🔴 **no 줄이 뜻하는 것이 집마다 반대다**(62-build.sh 의 그 표를 그대로 가져왔다):
#      A/S 의 「drizzle 을 안 담는다」는 **볼륨이 정본**이라는 뜻이고,
#      포털의 「drizzle 을 담는다」는 **이미지 안에서 돈다**는 뜻이다.
#   🔴 한 줄로 베끼면 둘 중 하나가 **가짜 ✗** 가 된다 — 62-build.sh:34-35 의 경고다.
COPYRULES='
as|^COPY .*scripts \./scripts|yes|A/S tools 가 scripts/ 를 담는다 (시험 목록 3장이 여기다)
as|^COPY .*src \./src|yes|🔴 A/S tools 가 src/ 를 담는다 — 바뀐 165장이 전부 여기다
as|^COPY .*vendor \./vendor|yes|🔴 A/S tools 가 vendor/ 를 담는다 — **이번 판은 그 안이 바뀌었다(굽는 까닭 ㄹ)**
as|^COPY .*drizzle \./drizzle|no|🔴 A/S tools 는 drizzle/ 을 **안 담는다** — 그래서 0132·0133 은 **묶음으로만** 간다
auth|^COPY .*src \./src|yes|포털 tools 가 src/ 를 담는다 (바뀐 5장이 여기다)
auth|^COPY .*drizzle \./drizzle|yes|🔴 포털 tools 가 drizzle/ 을 **담는다** — 11장이 이미지 안에서 돈다
auth|^COPY .*scripts \./scripts|yes|포털 tools 가 scripts/ 를 담는다 (check:notify·check:delegations 가 여기다)
auth|^COPY .*vendor \./vendor|no|🔵 포털 tools 는 vendor/ 를 **안 담는다** — builder 만 @dss/ui 를 쓴다
'
COPYRULES_WANT=8

# ══ 🔴 앱 번들에서 쓸 표식 — **전부 리터럴 · 하나는 한글** ════════════
#   열쇠|갈래(feature|keep|side)|글자|사람이 읽을 말
#   🔴 **공백이 든 표식이 있고 하나는 한글이다**(도번 / 비고).
#      그래서 이 표는 tr -d ' ' 로 읽지 않고 **here 문서 + IFS='|' read** 로만 읽는다.
#   🔴 **표식에 | 가 든 것은 하나도 없다**[값으로 확인] — 정규식을 이 꼴의 표에
#      넣었다가 깨진 자리가 따로 있다(TOOLS_PAYLOAD 의 주석).
#   🔴 **전부 리터럴이어야 한다** — 코드 줄에서 따오면 minify 가 지운다.
#      [실측 2026-11-25 · 구운 dss-as:6.2 · dss-auth:2.3 번들에서 **열여덟을 다 세었다**]
#        feature shareDocRelativePath 23 · DOMESTIC_ORDER_DUE_DATE_NEAR 9 ·
#                DOMESTIC_ORDER_DUE_DATE_CONFIRMED 6
#        keep(A/S) 도번 / 비고 2 · hasLiveApproval 3 · domesticOrders.completedEdit 5 ·
#                faultTags 19 · radiogroup 5 · "ORDER_ISSUED" 2 ·
#                domestic-order-status-filter 2 · portal_approval_delegations 23 ·
#                domesticOrders.view 8
#        keep(포털) dss.delegations.write 5 · approval_mail_kinds 2 ·
#                notification_dismissals 1
#        side share_doc_relative_path 5 · TONE_COUNT **0** · tone 5
#      🔵 **판정에 쓰는 열다섯이 전부 ≥1 이다.** 0 인 둘은 **판정에 안 쓰는 곁들이**다 —
#         TONE_COUNT 가 번들에서 0 이라는 것이 「포털 앱은 도구에서 가린다」는
#         설계가 맞았다는 값 증거다(판정에 썼으면 ✗ 가 났다).
#   🔴 feature = 기준 0 → 지금 1 이상이어야 한다(안 그러면 아무것도 안 가른다)
#      keep    = 기준에도 지금에도 1 이상이어야 한다(뒷걸음을 재는 자리)
#      side    = 🔵 **판정에 안 쓴다.** 값만 찍는다.
APPMARKS='
as|feature|shareDocRelativePath|🔴 노드 파일 자리 — 기준 0 → 지금 36파일 (객체의 칸 이름 · minify 가 안 건드린다)
as|feature|DOMESTIC_ORDER_DUE_DATE_NEAR|🔴 기타건 납기 임박 — 기준 0 → 지금 6파일 (알림 종류 코드 · 대문자 리터럴)
as|feature|DOMESTIC_ORDER_DUE_DATE_CONFIRMED|🔴 납기일 확정 — 기준 0 → 지금 5파일 (알림 종류 코드 · 대문자 리터럴)
as|side|share_doc_relative_path|🔵 곁들이 — DB 칸 이름. vendor 의 text("…") 리터럴로 들어간다 (기준 0 → 지금 5파일)
as|keep|도번 / 비고|🔴 **한글**. 예순여섯째가 올린 placeholder 꼬리 — 소스 기준 1 → 지금 1파일 · 번들 server 1 · static 1
as|keep|hasLiveApproval|예순네째가 올린 프롭 이름 — 기준 4 → 지금 4파일
as|keep|domesticOrders.completedEdit|예순세째가 올린 권한 열쇠 — 기준 11 → 지금 12파일
as|keep|faultTags|예순두째가 올린 칸 이름 — 기준 13 → 지금 13파일
as|keep|radiogroup|예순한째가 올린 DOM 속성 값 — 기준 2 → 지금 2파일
as|keep|"ORDER_ISSUED"|예순째가 올린 상태 값 — 기준 2 → 지금 2파일
as|keep|domestic-order-status-filter|쉰아홉째가 올린 DOM id — 기준 3 → 지금 3파일
as|keep|portal_approval_delegations|쉰여덟째가 올린 글자 — 기준 26 → 지금 26파일
as|keep|domesticOrders.view|쉰여섯째가 올린 권한 열쇠 — 기준 17 → 지금 17파일
auth|keep|dss.delegations.write|쉰여덟째가 올린 권한 열쇠 — 기준 4 → 지금 4파일
auth|keep|approval_mail_kinds|결재 메일 갈래 — 기준 3 → 지금 3파일
auth|keep|notification_dismissals|종 지움 표 이름 — 기준 6 → 지금 6파일
auth|side|TONE_COUNT|🔵 곁들이 — 기준 0 → 지금 2파일. 🔴 **번들에서는 판정에 안 쓴다**(export 이름이 남는지 모른다)
auth|side|tone|🔵 곁들이 — 기준 0 → 지금 5파일. 🔴 **번들에서는 "stone" 같은 낱말에도 걸려 ≥1 이 공짜다**
'
# 🔴 기능 3 + 곁들이 1 + 뒷걸음 9 (A/S) + 뒷걸음 3 + 곁들이 2 (포털) = **18**
MARKS_WANT=18
#   🔴 갈래별로도 센다 — 표가 깨져 한 갈래가 통째로 빠지는 것을 막는다.
MARKS_FEATURE_WANT=3
MARKS_KEEP_WANT=12
MARKS_SIDE_WANT=3
# 🔴 **포털에는 feature 가 0 이다.** 머리말의 「무엇이 없고 왜 없는가」에 까닭을
#    적어 두었다 — 이번 포털 커밋이 더한 코드에 **새 문자열 리터럴이 없다.**
#    그 갈래는 **포털 도구 이미지**에서 가린다(아래 TOOLMARKS).
AUTH_FEATURE_WANT=0

# ══ 🔴🔴 **한글 표식 — 이 판에 하나 있다** (70번에서 길을 통째로 가져왔다) ══
#   🔴 **첫 --go 에서 ✗ 가 난 자리다. 까닭을 적어 둔다.**
#      처음에는 예순여섯째의 뒷걸음 표식으로 **part.drawingNo, part.note** 를 썼다.
#      「이 파일의 표식은 전부 ASCII」라는 규율을 지키려고 70번의 한글 대신 **같은
#      커밋의 ASCII 쪽**을 고른 것인데, 🔴 **쓰임이 다른 표식을 가져왔다** —
#      그 글자는 70-build.sh 의 **TOOLMARK_ASCII**(70-build.sh:161)이고 **도구
#      이미지용**이다(거기는 소스가 글자 그대로 있다). **번들용이 아니다.**
#      [실측 2026-11-25 · 구운 dss-as:6.2 안] server **0** · static **0**.
#      까닭: src/lib/domain/inventory-gateway.ts:466 의
#        const haystack = [part.name, …, part.drawingNo, part.note]
#      에서 **part 는 지역 이름**이라 minify 가 한 글자로 갈아 치운다 — 칸 이름
#      (drawingNo·note)은 남아도 **part. 접두사가 사라진다.**
#   🔴 **70번이 번들에서 실제로 쓴 글자는 한글**이다 — placeholder 의 **문자열
#      리터럴**이라 minify 가 내용을 안 바꾼다.
#      [실측 2026-11-25] 옛 판 **dss-as:6.1** server 1 · static 1 ·
#                        새 판 **dss-as:6.2** server 1 · static 1 → **뒷걸음을 잴 수 있다.**
#   🔴 **그래서 「이 파일의 표식은 전부 ASCII」가 이 판에는 거짓이다** — 머리말의
#      그 줄을 고쳤다. 대신 70번의 **바이트 확인 절(1-ㄷ)**을 함께 가져왔다:
#      한글을 컨테이너로 보내고 **되돌려 받아 글자와 바이트 수를 맞댄다.**
#      「한글을 HTTP 머리말·argv 에 넣으면 요청이 아예 안 나간다」가 이 저장소에
#      적혀 있어, 70번이 그 자리에 세워 둔 울타리다.
#      [실측 2026-11-25 · dss-as:6.2] 보낸 [도번 / 비고] **15바이트** → 받은 15바이트 ·
#                                      보낸 [재고 관리에서 찾기] **26바이트** → 받은 26바이트.
#      🔵 70번이 2026-11-20 에 잰 값과 **같다.**
#   🔵 **ASCII 로 바꾸고 싶으면 번들에서 먼저 세라.** 소스에서 센 수를 근거로
#      고르면 이번과 같은 ✗ 가 또 난다 — 소스에는 1줄, 번들에는 0줄이었다.
#      [실측] 70번 커밋이 번들에 남긴 ASCII 글자는 **없다**(drawingNo 는 그 커밋
#      전에도 있었다 — 16/5 로 잡히지만 **아무것도 안 가른다**).
KO_MARKS='
도번 / 비고
재고 관리에서 찾기
'
KO_MARKS_WANT=2
# 🔵 둘째는 **판정에 안 쓰는 짝**이다 — 같은 placeholder 의 앞부분이라, 경계가
#    멀쩡한지 **두 글자로** 재면 「우연히 한 글자만 통과」를 가른다.

# ══ 🔴 도구 이미지에서 쓸 **마지막 커밋 표식** — 집마다 하나 ══════════
#   열쇠|표식|그 표식이 있어야 하는 파일|기준 줄 수|지금 줄 수
#   🔴 **과녁은 기준판에도 있던 파일**이다 — 새로 생긴 파일을 과녁으로 삼으면
#      「기준 0줄」이 **파일이 없어서 0** 인 것이라 아무것도 안 가른다.
TOOLMARKS='
astools|ExecutionNodeShareDocRow|src/components/procedures/execution/CurrentTaskCard.tsx|0|2
authtools|TONE_COUNT|src/lib/notifications/merge.ts|0|3
'
TOOLMARKS_WANT=2
# 🔴 그 표식이 가리키는 **짝 파일**도 이미지에 있어야 한다 — 없으면 화면이
#    import 에서 죽는다. 열쇠|파일
TOOLMARK_PAIRS='
astools|src/components/procedures/execution/ExecutionNodeShareDocRow.tsx
authtools|src/lib/notifications/merge.ts
'
TOOLMARK_PAIRS_WANT=2

# ══ 🔴 public/ 기대값 — **집마다 다르다** ═════════════════════════════
#   열쇠|기대(yes|no)|이미지 안 파일 수(참고 · 판정에 안 쓴다)
#   🔵 [실측 2026-11-25 · 작업본] A/S 9개 · 포털 6개.
PUBLIC_WANT='
as|yes|9
auth|yes|6
'
PUBLIC_WANT_N=2

# ══ 🔴 **핵심 파일 표본** — 도구 이미지가 담고 있어야 한다 ════════════
#   🔴 A/S 는 바뀐 파일이 **179장**이라 전부를 컨테이너에 넘길 수 없다. 62번처럼
#      **핵심 스무 장**을 고른다. 🔴 **괄호·대괄호가 든 줄 셋을 일부러 넣었다** —
#      글롭 함정이 살아 있어서, 목록을 넘기는 길이 끊기면 그 줄들이 먼저 사라진다.
#   🔴 **없는 경로 하나를 함께 묻는다** — 「무조건 yes」인 검사인지 가른다.
PROBE_MISS=src/__dss_probe_no_such_file__.ts
AS_KEY_FILES='
src/app/api/procedure-templates/[id]/share-folder/entries/route.ts
src/app/api/repair-cases/[id]/flowchart/share-folder/entries/route.ts
src/components/procedures/execution/ExecutionNodeShareDocRow.tsx
src/components/procedures/execution/CurrentTaskCard.tsx
src/components/procedures/visual/ProcedureCanvasToolPicker.tsx
src/components/repair-cases/flowchart/CaseFlowchartNodeShareDocPicker.tsx
src/lib/db/queries/domestic-order-due-date-near-notifications.ts
src/lib/domain/procedure-editor-delete-key.ts
src/lib/domain/procedure-editor-node-deletion.ts
src/lib/domain/procedure-editor-structural-changes.ts
src/lib/domain/procedure-editor-structural-preview.ts
src/lib/domain/procedure-editor-structural-save.ts
src/lib/domain/procedure-editor-structural-undo.ts
src/lib/graph-editor-core/box-selection.ts
src/lib/graph-editor-core/straighten-selection.ts
src/lib/validation/flowchart-node-share-doc-path.ts
scripts/lib/xlsx/technical-task-next-procedure-plan.ts
src/app/(app)/misc-cases/page.tsx
src/app/(app)/procedures/[id]/edit/page.tsx
src/app/(app)/domestic-orders/[id]/layout.tsx
'
AS_KEY_FILES_WANT=20
AUTH_KEY_FILES='
src/lib/notifications/merge.ts
src/lib/notifications/site-service.ts
src/app/apps/page.tsx
src/lib/notifications/merge.test.ts
src/lib/notifications/bell-wiring.test.ts
'
AUTH_KEY_FILES_WANT=5

# ══ 🔴 시험 등록 — **집마다 방식이 다르다** ═══════════════════════════
#   🔴 **A/S 는 목록 파일** 방식이다 — scripts/test-lists/*.txt 에 **적어야 돈다.**
#      빠뜨리면 **오류 없이 조용히 안 돈다.**
#   🔴 **포털은 package.json 의 「test」 줄에 경로를 하나씩 나열**한다.
#      🔴 **글롭 방식인 저장소에서 베끼면 이 절이 통째로 없어진다.**
#   🔴 그 파일들은 **CRLF** 라 \r 를 걷고 -Fx 로 줄 전체를 맞댄다.
AS_TESTLIST_MIN_LINES=4000
AS_TESTLIST_LINES_WANT=4787
AS_TESTLIST_LINES_WAS=4200
AS_NEW_TESTS_WANT=43
AS_TESTLIST_FILES='
scripts/test-lists/unit.txt
scripts/test-lists/components.txt
scripts/test-lists/db.txt
scripts/test-lists/db-safety.txt
'
AS_TESTLIST_FILES_WANT=4
#   🔴 **새로 생긴 시험 마흔셋** — 이것이 「등록돼 있는가」의 표본이다.
#
#   🔴🔴 **맨 첫 줄이 대괄호가 아니라 별표다 — 일부러 그렇다. 고치지 마라.**
#      [실측 2026-11-25] 그 시험의 **실제 파일 경로**는
#        src/app/api/repair-cases/[id]/flowchart/share-folder/entries/route-source.test.ts
#      인데, **목록 파일에는 별표로 적혀 있다**(scripts/test-lists/unit.txt:2315):
#        src/app/api/repair-cases/*/flowchart/share-folder/entries/route-source.test.ts
#      🔴 까닭은 그 저장소의 scripts/run-test-list.mjs 머리말에 적혀 있다 —
#         「App Router 의 [id] 폴더를 그대로 적으면 node 가 **글롭 문자클래스**로
#          읽어 「tests 0」 으로 지나간다 — 그 칸은 별표로 적는다」.
#      🔴 **이 절은 목록 파일과 줄 전체를 맞대는 검사**이므로 여기에는 **목록에 적힌
#         꼴**을 적어야 한다. 실제 경로를 적으면 **멀쩡한 등록이 「안 적힘」으로** 나와
#         **가짜 ✗** 가 난다 — 처음 쓸 때 실제로 그 ✗ 가 났고, 값으로 재서 고쳤다.
#      🔵 **AS_KEY_FILES 는 반대다** — 거기는 이미지 안에서 [ -f ] 로 묻는 자리라
#         **실제 경로(대괄호)**를 적어야 한다. 두 표가 같은 파일을 **다른 꼴**로
#         들고 있는 것이 맞다.
AS_NEW_TESTS='
src/app/api/repair-cases/*/flowchart/share-folder/entries/route-source.test.ts
src/components/domestic-orders/domestic-order-due-date-confirm-screens.test.ts
src/components/misc-cases/misc-case-due-date-near-badge.test.tsx
src/components/procedures/editor/procedure-node-share-doc.test.tsx
src/components/procedures/execution/execution-node-share-doc.test.tsx
src/components/procedures/procedure-box-selection-tool.test.ts
src/components/procedures/procedure-editor-delete-key-ui.test.ts
src/components/procedures/procedure-flow-graph-layout-memory.test.ts
src/components/procedures/procedure-multi-node-delete-ui.test.ts
src/components/procedures/procedure-multi-node-drag-plumbing.test.ts
src/components/procedures/procedure-node-delete-cascade-ui.test.ts
src/components/procedures/procedure-node-type-badge.test.ts
src/components/procedures/procedure-straighten-selected-edges-ui.test.ts
src/components/procedures/procedure-structural-deferred-save.test.ts
src/components/repair-cases/detail/due-date-confirmed-reject-notice.test.ts
src/components/repair-cases/flowchart/case-flowchart-box-selection-tool.test.ts
src/components/repair-cases/flowchart/case-flowchart-delete-key-ui.test.ts
src/components/repair-cases/flowchart/case-flowchart-multi-node-delete-ui.test.ts
src/components/repair-cases/flowchart/case-flowchart-multi-node-drag-plumbing.test.ts
src/components/repair-cases/flowchart/case-flowchart-node-delete-cascade-ui.test.ts
src/components/repair-cases/flowchart/case-flowchart-node-share-doc.test.tsx
src/components/repair-cases/flowchart/case-flowchart-straighten-selected-edges-ui.test.ts
src/components/repair-cases/flowchart/case-flowchart-structural-deferred-save.test.ts
src/lib/db/mutations/domestic-order-due-date-confirmation.integration.test.ts
src/lib/db/mutations/procedure-node-share-doc.integration.test.ts
src/lib/db/mutations/repair-case-due-date-confirmed-guard.integration.test.ts
src/lib/db/queries/domestic-order-due-date-near-notifications.integration.test.ts
src/lib/db/queries/due-date-near-confirmation.integration.test.ts
src/lib/db/schema/flowchart-node-share-doc-path-shape.test.ts
src/lib/domain/domestic-order-due-date-near-notification.test.ts
src/lib/domain/due-date-confirmation-silences-bell.test.ts
src/lib/domain/misc-case-due-date-near.test.ts
src/lib/domain/procedure-auto-layout-stability.test.ts
src/lib/domain/procedure-editor-delete-key.test.ts
src/lib/domain/procedure-editor-node-deletion.test.ts
src/lib/domain/procedure-editor-structural-changes.test.ts
src/lib/domain/procedure-editor-structural-preview.test.ts
src/lib/domain/procedure-editor-structural-save.test.ts
src/lib/domain/procedure-editor-structural-undo.test.ts
src/lib/graph-editor-core/box-selection.test.ts
src/lib/graph-editor-core/straighten-selection.test.ts
src/lib/validation/procedure-node-share-doc-path.test.ts
src/lib/validation/repair-case-flowchart-node-share-doc-path.test.ts
'
#   🔵 **바뀐 86장 중 새것이 아닌 43장**은 표로 안 적고 **git 에서 그 자리에서 뽑아**
#      한 장씩 묻는다 — 86줄을 손으로 적으면 한 줄만 틀려도 ✗ 가 흩어진다.
#      🔴 대신 **뽑은 수를 단언한다**(86 − 43 = 43). 안 그러면 0장을 묻고 ✓ 가 된다.
AS_OLD_TESTS_WANT=43
# ── 🔵 포털 — package.json 의 「test」 줄 ──────────────────────────────
AUTH_TESTPATHS_WAS=64
AUTH_TESTPATHS_WANT=64
AUTH_NEW_TESTS_WANT=0
AUTH_TOUCHED_TESTS='
src/lib/notifications/merge.test.ts
src/lib/notifications/bell-wiring.test.ts
'
AUTH_TOUCHED_TESTS_WANT=2

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-71"; fi
# 🔴 **묶음 자리** — 66번에서 가져왔다. 70번에는 이 줄이 없었다.
MIGTAR="$OUT/as-migrations.tar.gz"

case "$MODE" in
  --check|--go|--verify) ;;
  *) printf '쓰는 법: %s [--check|--go|--verify] [산출물폴더]\n' "$0"; exit 2 ;;
esac

printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' " 71-build.sh — 예순일곱째 배포 · 이미지 굽기 ($MODE)"
printf '%s\n' "   저장소 뿌리 : $DEV"
printf '%s\n' "   산출물 자리 : $OUT"
printf '%s\n' "   굽는 것     : 이미지 $HOWMANY (A/S 앱·도구 · 포털 앱·도구) · 🔴 **묶음 1**"
printf '%s\n' "   마이그레이션: 🔴 **A/S 2건** ($AS_SQL_WAS → $AS_SQL_WANT) · 🔵 포털 **0건**"
printf '%s\n' "   서브모듈    : 🔴 **dss-core 가 움직인다** (dss-ui 는 두 집 다 그대로)"
printf '%s\n' "   🔴 **포털은 이번에 「안 건드리는 집」이 아니다 — 올라간다**"
printf '%s\n' "══════════════════════════════════════════════════════════════"

# ══ 표를 읽는 길 ══════════════════════════════════════════════════════
#   🔴 **공백이 든 표(COPYRULES·APPMARKS)는 tr -d ' ' 로 읽지 않는다** — 말이 뭉개진다.
#      그 표는 while IFS='|' read 로만 읽는다.
rows_of() { printf '%s\n' "$1" | grep -v '^[[:space:]]*$'; }
field() { printf '%s' "$1" | cut -d'|' -f"$2"; }
row_by_key() { # 1 표 2 열쇠
  rows_of "$1" | while IFS= read -r r; do
    [ "$(field "$r" 1)" = "$2" ] && printf '%s' "$r"
  done
}
repo_dir()  { printf '%s/%s' "$DEV" "$(field "$(row_by_key "$REPOS" "$1")" 2)"; }
repo_name() { field "$(row_by_key "$REPOS" "$1")" 3; }
repo_base() { field "$(row_by_key "$REPOS" "$1")" 4; }
# 🔴 도구 열쇠(astools)에서 저장소 열쇠(as)를 뽑는다 — IMAGES 표의 둘째 칸을
#    믿지 않고 이름 규칙으로 뽑으면 표를 고친 날 한 곳만 바뀐다. 그래서 **표에서**
#    저장소 폴더를 꺼내 쓰고, 이 함수는 **표식 표를 찾는 데만** 쓴다.
repo_key_of() { printf '%s' "${1%tools}"; }

# 「기준 SHA 때 그 글자가 든 src/ 파일 수」 — 🔴 pathspec 에 글롭이 든 경로를
# 넘기지 않는다(src 하나만 넘긴다).
mark_was() { git -C "$1" grep -lF -- "$3" "$2" -- src 2>/dev/null </dev/null | wc -l | tr -d ' '; }
mark_now() { grep -rlF -- "$2" "$1/src" 2>/dev/null | wc -l | tr -d ' '; }

# 🔴 **자주 쓰는 자리는 여기서 한 번 계산한다** — check_all 안에서만 잡으면
#    --verify 가 그 함수를 건너뛰는 날 빈 값으로 돈다(아무것도 안 재는 ✓).
ASD="$DEV/$(field "$(row_by_key "$REPOS" as)" 2)"
AUTHD="$DEV/$(field "$(row_by_key "$REPOS" auth)" 2)"
COREDIR="$ASD/vendor/dss-core"
UIDIR="$ASD/vendor/dss-ui"
AUTHUIDIR="$AUTHD/vendor/dss-ui"

# ══════════════════════════════════════════════════════════════════════
check_all() {
PASS=0; FAIL=0; UNK=0

# ── 0. 🔴 Git Bash 인가 (WSL 이면 ✗ 가 흩어져 난다) ──────────────────
step "0. 🔴 Git Bash 에서 도는가 — WSL 이면 여기서 멈춘다"
say "뿌리 경로: $DEV"
case "$DEV" in
  /mnt/*)
    bad "🔴 **WSL 에서 돌고 있다**(뿌리가 /mnt/ 로 시작한다) — 여기서 구우면 유령 diff 가 난다"
    say "    → PowerShell 에서 이렇게 부르세요:"
    say "       & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./71-build.sh $MODE"
    ;;
  /[a-z]/*)
    ok "Git Bash 다 (뿌리가 /c/ 꼴이다)"
    ;;
  *)
    unk "셸 갈래" "뿌리가 /mnt/ 도 /c/ 도 아니다 — $DEV"
    ;;
esac
u=$(uname -s 2>/dev/null)
say "uname -s: ${u:-못 읽음}"
case "${u:-}" in
  MINGW*|MSYS*) ok "uname 도 Git Bash 를 가리킨다 ($u)" ;;
  Linux)        bad "uname 이 Linux 다 — **WSL 이다**" ;;
  *)            note "uname 이 ${u:-못 읽음} 다 — 사람이 보세요" ;;
esac

# ── 1. 도커가 도는가 ──────────────────────────────────────────────────
step "1. 도커가 도는가"
if docker version --format '{{.Server.Version}}' >/dev/null 2>&1; then
  v=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
  ok "도커가 돈다 (서버 ${v:-판 못 읽음})"
else
  bad "도커가 안 돈다 — Docker Desktop 을 켜세요"
fi

# ── 1-ㄴ. 🔴 **경로 번역이 정말 꺼졌는가** — 값으로 잰다 (결함 ②) ────
#   🔴 이 절이 없어서 쉰여덟째의 첫 굽기에 **가짜 ✗ 일곱**이 났다. 번역이 켜져
#      있으면 아래 절들의 ✗ 가 **진짜 결함처럼 보인다.**
#   🔵 컨테이너가 하나 필요하다 — 옛 판이든 새 판이든 **있는 것**을 쓴다.
say ""
say "── 1-ㄴ. 🔴 Git Bash 의 경로 번역이 꺼졌는가 (MSYS_NO_PATHCONV)"
PROBE_IMG=""
PROBEIMG_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  PROBEIMG_SEEN=$((PROBEIMG_SEEN+1))
  t=$(field "$r" 3)
  if [ -z "${PROBE_IMG:-}" ] && docker image inspect "$t" >/dev/null 2>&1; then PROBE_IMG=$t; fi
  t2=$(field "$r" 5); t2=$(printf '%s' "${t2%.tar}" | sed 's/-\([0-9][0-9.]*\)$/:\1/')
  if [ -z "${PROBE_IMG:-}" ] && docker image inspect "$t2" >/dev/null 2>&1; then PROBE_IMG=$t2; fi
done <<ENDPROBEIMG
$(rows_of "$IMAGES")
ENDPROBEIMG
say "잴 후보로 본 줄 ${PROBEIMG_SEEN}개 (기대 $HOWMANY)"
if [ "$PROBEIMG_SEEN" != "$HOWMANY" ]; then
  bad "IMAGES 표를 ${PROBEIMG_SEEN}줄만 읽었다 — ${HOWMANY}줄을 기대했다. 표가 깨졌다"
fi
if [ -z "${PROBE_IMG:-}" ]; then
  unk "경로 번역" "잴 이미지가 하나도 없다 — 옛 판도 새 판도 이 PC 에 없다"
  say "      🔴 **이 줄이 ? 면 아래 이미지 안 검사를 믿지 마세요.**"
else
  say "재는 데 쓴 이미지: $PROBE_IMG"
  v=$(dockr run --rm -e DSSPROBE="/app/dss-pathconv-probe" --entrypoint sh "$PROBE_IMG" -c 'printf "%s" "$DSSPROBE"' 2>/dev/null | tr -d '\r')
  say "넘긴 값 [/app/dss-pathconv-probe] → 컨테이너가 받은 값 [${v:-못 읽음}]"
  if [ "${v:-}" = "/app/dss-pathconv-probe" ]; then
    ok "경로 번역이 **꺼져 있다** (아래 이미지 안 검사를 믿을 수 있다)"
  elif [ -z "${v:-}" ]; then
    unk "경로 번역" "컨테이너에서 값을 못 받았다"
  else
    bad "🔴 경로 번역이 **살아 있다** — 받은 값이 [${v}] 다"
    say "      🔴 이대로 두면 아래의 표식·파일 검사가 **가짜 ✗** 를 냅니다."
    say "      → PowerShell 에서 이렇게 부르세요(Git Bash 로):"
    say "         & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./71-build.sh $MODE"
    say "      → 그래도 안 꺼지면 이 파일 맨 위의 dockr() 줄을 보세요."
  fi
fi

# ── 1-ㄷ. 🔴🔴 **한글이 컨테이너 경계를 글자 그대로 건너가는가** ─────
#   🔴 **70번에서 통째로 가져왔다**(70-build.sh:741-786). 이 판의 뒷걸음 표식 하나가
#      **한글**이기 때문이다 — 그 까닭은 KO_MARKS 의 주석에 길게 적어 두었다.
#   🔵 길은 1-ㄴ 과 **같다**: 보내고 **되돌려 받아** 글자와 **바이트 수**를 맞댄다.
#      🔴 8진 이스케이프로 우회하지 않았다. 백슬래시 한 겹이 조용히 삼켜지는
#         함정이 이 PC 에 적혀 있어 **그 길이 더 위험**하다.
say ""
say "── 1-ㄷ. 🔴🔴 **한글이 컨테이너 안까지 글자 그대로 가는가** (뒷걸음 표식 하나가 한글이다)"
say "🔴 이 줄이 ✗ 면 **이미지가 아니라 검사가 깨진 것**입니다 — 아래 한글 표식의"
say "   0 을 결함으로 읽지 마세요."
say "🔵 이 판은 **기능 표식 셋이 전부 ASCII** 라, 한글만 0 이고 ASCII 가 ≥1 이면"
say "   그것 자체가 「한글 grep 이 안 되는 것」이라는 증거입니다(ASCII 대조)."
if [ -z "${PROBE_IMG:-}" ]; then
  unk "한글 경계" "잴 이미지가 없다 (1-ㄴ 과 같은 까닭)"
else
  KO_SEEN=0; KO_OK=0
  ko_probe() { # 1 글자
    local hb v got cb
    KO_SEEN=$((KO_SEEN+1))
    hb=$(printf '%s' "$1" | wc -c | tr -d ' ')
    v=$(dockr run --rm -e DSSKO="$1" --entrypoint sh "$PROBE_IMG" -c \
      'printf "%s|%s\n" "$DSSKO" "$(printf "%s" "$DSSKO" | wc -c | tr -d " ")"' 2>/dev/null | tr -d '\r')
    got=$(printf '%s' "$v" | cut -d'|' -f1)
    cb=$(printf '%s' "$v" | cut -d'|' -f2)
    printf '      보낸 [%s] %s바이트 → 받은 [%s] %s바이트\n' "$1" "$hb" "${got:-못 읽음}" "${cb:-?}"
    if [ "${got:-}" = "$1" ] && [ "${cb:-x}" = "$hb" ]; then
      KO_OK=$((KO_OK+1))
    else
      bad "한글이 경계에서 **달라졌다** — 받은 [${got:-못 읽음}] ${cb:-?}바이트 (보낸 ${hb}바이트)"
      say "      🔴 **이미지를 의심하지 마세요.** 로케일이나 인자 전달이 깨진 것입니다."
      doubt
    fi
  }
  while IFS= read -r km; do
    [ -n "$km" ] || continue
    ko_probe "$km"
  done <<ENDKO
$(rows_of "$KO_MARKS")
ENDKO
  say "본 한글 ${KO_SEEN}개 · 그대로 건너간 것 ${KO_OK}개 (기대 $KO_MARKS_WANT · $KO_MARKS_WANT)"
  if [ "$KO_SEEN" = "$KO_MARKS_WANT" ] && [ "$KO_OK" = "$KO_MARKS_WANT" ]; then
    ok "한글 ${KO_MARKS_WANT}개가 **컨테이너까지 글자 그대로 간다** (번들의 0 을 결함으로 읽어도 된다)"
    say "      🔵 [실측 2026-11-25 · dss-as:6.2] [도번 / 비고] 15바이트 ·"
    say "         [재고 관리에서 찾기] 26바이트. 🔵 70번이 2026-11-20 에 잰 값과 같습니다."
  else
    bad "본 것 ${KO_SEEN} · 그대로인 것 ${KO_OK} 다 — ${KO_MARKS_WANT} 를 기대했다"
    say "      🔴 **아래 한글 표식의 ✗ 는 전부 이 줄의 결과입니다.** 이미지를 되돌리지 마세요."
  fi
fi

# ── 2. 🔴 저장소 **둘** ───────────────────────────────────────────────
step "2. 🔴 저장소 **둘** — 깨끗한가 · 올라가 있나 · 범위가 맞나"
say "🔴 구운 이미지는 **그때 그 작업 폴더의 사진**입니다. 커밋 안 된 줄이 섞이면"
say "   나중에 같은 이미지를 다시 못 만듭니다."
say "🔴 **66·70번은 집이 하나였습니다** — 여기서부터 고리가 **두 바퀴** 돕니다."
REPO_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  RK=$(field "$r" 1); RD="$DEV/$(field "$r" 2)"; RN=$(field "$r" 3)
  RB=$(field "$r" 4); RC=$(field "$r" 5)
  REPO_SEEN=$((REPO_SEEN+1))
  printf '\n    ── %s (%s)\n' "$RN" "$RD"
  if [ ! -d "$RD/.git" ]; then
    bad "$RN — 저장소가 없다 ($RD)"
    continue
  fi
  br=$(git -C "$RD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ "$br" = "main" ] && ok "$RN 가지가 main 이다" || bad "$RN 가지가 ${br:-못 읽음} 다 — main 이어야 한다"
  dirty=$(git -C "$RD" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${dirty:-1}" = "0" ]; then ok "$RN 미커밋 0줄"
  else
    bad "$RN 에 미커밋이 ${dirty}줄 있다 — 굽기 전에 정리하세요"
    git -C "$RD" status --porcelain=v1 2>/dev/null | head -8 | sed 's/^/        /'
  fi
  h=$(git -C "$RD" rev-parse --short HEAD 2>/dev/null)
  o=$(git -C "$RD" rev-parse --short origin/main 2>/dev/null)
  say "HEAD $h · origin/main ${o:-없음}"
  if [ -n "${o:-}" ] && [ "$h" = "$o" ]; then
    ok "$RN main == origin/main (올라가 있다)"
  else
    ab=$(git -C "$RD" rev-list --left-right --count main...origin/main 2>/dev/null)
    bad "$RN main 과 origin/main 이 다르다 (왼쪽=안 올린 것 오른쪽=안 받은 것: ${ab:-못 읽음})"
    say "      🔴 **「미푸시 0」은 받았다는 뜻이 아닙니다** — 오른쪽 수도 보세요."
  fi
  if git -C "$RD" cat-file -e "$RB^{commit}" 2>/dev/null; then
    n=$(git -C "$RD" rev-list --count "$RB..main" 2>/dev/null)
    say "기준 $RB..main 커밋 ${n:-못 읽음}개 (적어 둔 값 $RC)"
    git -C "$RD" log --oneline "$RB..main" 2>/dev/null | head -12 | sed 's/^/        /'
    if [ "${n:-x}" = "$RC" ]; then
      ok "$RN 범위가 적어 둔 것과 같다 ($RC 커밋)"
    else
      note "$RN 커밋이 ${n:-?}개다 — $RC 을 적어 두었다. **사람이 보세요**"
      say "      🔵 ⚠️ 로만 셉니다 — 그 사이에 하나 더 밀었을 수 있습니다."
      say "      🔴 **이번 판에 실제로 그 일이 있었습니다**(머리말 ④) — 지시서는 50"
      say "         커밋이었고 재 보니 51 이었습니다. 더 밀린 한 커밋은 진행현황 HTML"
      say "         한 장짜리라 **이미지에 아무 자취도 안 남깁니다.**"
      say "      🔴 그래도 **표식·파일 수 기대값이 전부 그 범위에서 나온 값**입니다 —"
      say "         5-ㅁ 의 파일 수가 함께 어긋나면 **거기서 멈추고 사람에게 알리세요.**"
    fi
  else
    bad "$RN 기준 SHA $RB 가 이 저장소에 없다 — 표가 틀렸다"
  fi
done <<ENDREPO
$(rows_of "$REPOS")
ENDREPO
say ""
[ "$REPO_SEEN" = "$REPOS_WANT" ] && ok "저장소 ${REPOS_WANT}곳을 다 봤다 (표본이 비지 않았다)" \
  || bad "저장소를 ${REPO_SEEN}곳만 봤다 — ${REPOS_WANT}곳을 기대했다. REPOS 표가 깨졌다"

# ── 3. 🔴 서브모듈 — **「움직였다」를 값으로 잰다** ───────────────────
step "3. 🔴 서브모듈 — **dss-core 가 또 움직인다.** 그것을 값으로 잰다"
say "🔴 [실측 2026-11-25] dss-core **${AS_CORE_PREV_PIN:0:8} → ${AS_CORE_PIN:0:8}** (커밋 $AS_CORE_MOVED_COMMITS · 파일 $AS_CORE_MOVED_FILES)."
say "🔴 **README.md:558 의 옛 핀(b79e5ab8)을 베끼지 마세요** — 그것은 쉰여덟째 때"
say "   값입니다. 예순두째가 이미 ${AS_CORE_PREV_PIN:0:8} 로 한 번 더 옮겼습니다."
say "🔵 vendor/dss-ui 는 **A/S·포털 둘 다** 안 움직입니다."
say "🔴 핀 글자가 맞아도 **안이 비어 있을 수 있습니다** — 3-ㄷ 이 안의 파일을"
say "   값으로 세고, **이번 판이 더한 칸 넷까지** 봅니다."
ASD="$DEV/$(field "$(row_by_key "$REPOS" as)" 2)"
AUTHD="$DEV/$(field "$(row_by_key "$REPOS" auth)" 2)"
COREDIR="$ASD/vendor/dss-core"
UIDIR="$ASD/vendor/dss-ui"
AUTHUIDIR="$AUTHD/vendor/dss-ui"
pin_of() { git -C "$1" submodule status "$2" 2>/dev/null </dev/null | awk '{print $1}' | tr -d '+-'; }
SUB_SEEN=0
check_pin() { # 1 저장소 2 서브모듈경로 3 기대 핀 4 사람이 읽을 말
  local p
  SUB_SEEN=$((SUB_SEEN+1))
  p=$(pin_of "$1" "$2")
  if [ -z "${p:-}" ]; then
    bad "$1 의 $2 포인터를 못 읽었다 — 서브모듈이 없거나 init 이 안 됐다"
    return
  fi
  if [ "$p" = "$3" ]; then ok "$2 = ${3:0:8} — **적어 둔 핀과 같다** ($4)"
  else
    bad "$2 가 ${p:0:8} 다 — ${3:0:8} 을 기대했다 (🔴 **이 배포본의 전제가 깨졌다**)"
    say "      🔴 멈추고 알리세요. 이 배포본은 그 핀을 전제로 쓰였습니다."
    doubt
  fi
}
say ""
say "── 3-ㄱ. 핀 값 — 🔴 **dss-core 는 움직여 있어야 한다** (서브모듈 셋을 본다)"
check_pin "$ASD"   vendor/dss-core "$AS_CORE_PIN" "🔴 **이번 판이 올리는 핀** — 옛 핀은 ${AS_CORE_PREV_PIN:0:8} 였다"
check_pin "$ASD"   vendor/dss-ui   "$UI_PIN"      "🔵 A/S — 안 움직였다"
check_pin "$AUTHD" vendor/dss-ui   "$UI_PIN"      "🔵 포털 — 안 움직였다 (62번에 처음 생긴 서브모듈이다)"
[ "$SUB_SEEN" = "3" ] && ok "서브모듈 핀 셋을 다 봤다 (표본이 비지 않았다)" \
  || bad "서브모듈 핀을 ${SUB_SEEN}개만 봤다 — 3개를 기대했다"
# 🔴 **옛 핀이 아닌가**를 따로 묻는다 — 위의 ✓ 는 「적어 둔 값과 같다」일 뿐이고,
#    적어 둔 값 자체를 잘못 베껴 왔으면 그 ✓ 가 **옛 핀을 통과시킨다.**
cp0=$(pin_of "$ASD" vendor/dss-core)
say "dss-core 핀: ${cp0:-못 읽음} (옛 핀 $AS_CORE_PREV_PIN 이면 안 된다)"
if [ -z "${cp0:-}" ]; then
  unk "dss-core 핀이 옛 것인가" "포인터를 못 읽었다"
elif [ "$cp0" = "$AS_CORE_PREV_PIN" ]; then
  bad "🔴 dss-core 가 **옛 핀 그대로다** — 이번 판은 그 핀이 움직여야 한다"
  say "      🔴 그대로 구우면 도구와 앱이 **confirmed_at·share_doc_relative_path 를"
  say "         모르는 스키마**로 돕니다."
  doubt
else
  ok "dss-core 가 옛 핀(${AS_CORE_PREV_PIN:0:8})이 **아니다** — 움직였다"
fi

say ""
say "── 3-ㄴ. 🔴 **A/S 범위가 vendor/ 를 건드렸는가** — 1줄이어야 한다"
say "🔴 0줄이면 서브모듈 포인터를 **안 올린 것**이고, 그러면 다른 PC 가 받아도"
say "   옛 스키마를 굽습니다."
CHROW=$(row_by_key "$CHANGED" as)
CH_VENDOR=$(field "$CHROW" 6)
VLIST=$(git -C "$ASD" diff --name-only "$(repo_base as)..main" 2>/dev/null | tr -d '\r' | grep -E '^(vendor/|\.gitmodules)' || true)
vn=$(printf '%s\n' "$VLIST" | grep -c . || true)
say "vendor/ · .gitmodules 변경 ${vn:-?}줄 (기대 $CH_VENDOR)"
[ -n "${VLIST:-}" ] && printf '%s\n' "$VLIST" | sed 's/^/        /'
if [ "${vn:-x}" = "$CH_VENDOR" ]; then
  ok "A/S 범위가 vendor/ 를 **${CH_VENDOR}줄 건드렸다** (서브모듈 포인터가 올라갔다)"
else
  bad "vendor/ 변경이 ${vn:-?}줄이다 — $CH_VENDOR 을 기대했다"
  doubt
fi
# 🔵 포털 쪽은 **0줄이어야** 한다 — 포털의 dss-ui 핀은 안 움직인다.
av=$(git -C "$AUTHD" diff --name-only "$(repo_base auth)..main" 2>/dev/null | tr -d '\r' | grep -cE '^(vendor/|\.gitmodules)' || true)
say "포털의 vendor/ · .gitmodules 변경 ${av:-?}줄 (기대 0 — 포털 핀은 안 움직인다)"
[ "${av:-x}" = "0" ] && ok "포털은 vendor/ 를 **안 건드렸다**" \
  || bad "포털의 vendor/ 가 ${av:-?}줄 바뀌었다 — 0 을 기대했다. 멈추고 알릴 것"
# 🔴 서브모듈 **안으로 들어가** 센다 — 포인터 글자만 맞대면 「같은 핀을 다른
#    저장소가 들고 있는」 꼴을 못 가른다.
CORE_ORIGIN_OK=0
if [ -d "$COREDIR/.git" ] || [ -f "$COREDIR/.git" ]; then
  if git -C "$COREDIR" cat-file -e "$AS_CORE_PIN^{commit}" 2>/dev/null; then
    n=$(git -C "$COREDIR" rev-list --count "$AS_CORE_PIN..HEAD" 2>/dev/null)
    say "dss-core 안: 적어 둔 핀 → 지금 HEAD 커밋 ${n:-못 읽음}개 (기대 $AS_CORE_COMMITS_WANT)"
    if [ "${n:-x}" = "$AS_CORE_COMMITS_WANT" ]; then
      ok "dss-core 작업본이 **그 핀 위에 서 있다** (핀보다 앞선 커밋이 없다)"
    else
      bad "dss-core 작업본이 핀보다 ${n:-?}커밋 앞서 있다 — $AS_CORE_COMMITS_WANT 을 기대했다"
      say "      🔴 앞서 있으면 **아직 A/S 에 안 올린 커밋을 굽는 것**입니다."
      git -C "$COREDIR" log --oneline "$AS_CORE_PIN..HEAD" 2>/dev/null | head -5 | sed 's/^/        /'
    fi
  else
    unk "dss-core 커밋 수" "적어 둔 핀 ${AS_CORE_PIN:0:8} 가 그 저장소에 없다"
  fi
  # 🔴 **옛 핀 → 새 핀 사이에 무엇이 들었나** — 「움직였다」를 값으로 보인다.
  if git -C "$COREDIR" cat-file -e "$AS_CORE_PREV_PIN^{commit}" 2>/dev/null; then
    mc=$(git -C "$COREDIR" rev-list --count "$AS_CORE_PREV_PIN..$AS_CORE_PIN" 2>/dev/null)
    mf=$(git -C "$COREDIR" diff --name-only "$AS_CORE_PREV_PIN..$AS_CORE_PIN" 2>/dev/null | tr -d '\r' | grep -c . || true)
    say "dss-core 옛 핀 → 새 핀: 커밋 ${mc:-?}개 · 바뀐 파일 ${mf:-?}장 (기대 $AS_CORE_MOVED_COMMITS · $AS_CORE_MOVED_FILES)"
    git -C "$COREDIR" log --oneline "$AS_CORE_PREV_PIN..$AS_CORE_PIN" 2>/dev/null | sed 's/^/        /'
    git -C "$COREDIR" diff --name-only "$AS_CORE_PREV_PIN..$AS_CORE_PIN" 2>/dev/null | sed 's/^/        /'
    if [ "${mc:-x}" = "$AS_CORE_MOVED_COMMITS" ] && [ "${mf:-x}" = "$AS_CORE_MOVED_FILES" ]; then
      ok "dss-core 가 **커밋 ${AS_CORE_MOVED_COMMITS}개 · 파일 ${AS_CORE_MOVED_FILES}장**만큼 움직였다"
    else
      note "dss-core 가 커밋 ${mc:-?} · 파일 ${mf:-?} 만큼 움직였다 — $AS_CORE_MOVED_COMMITS · $AS_CORE_MOVED_FILES 를 기대했다. **사람이 보세요**"
    fi
  else
    unk "dss-core 가 움직인 폭" "옛 핀 ${AS_CORE_PREV_PIN:0:8} 가 그 저장소에 없다"
  fi
  # 🔴🔴 **origin 에 올라가 있는가** — 안 올라가 있으면 다른 PC 가 그 핀을 못 받아
  #    submodule update 가 그 자리에서 죽는다. 🔵 이 PC 에서는 멀쩡히 구워진다 —
  #    그래서 **여기서 안 재면 영영 안 드러난다.**
  ro=$(git -C "$COREDIR" rev-parse origin/main 2>/dev/null)
  say "dss-core origin/main: ${ro:-못 읽음} (핀 $AS_CORE_PIN 과 같아야 한다)"
  if [ -z "${ro:-}" ]; then
    unk "dss-core 가 origin 에 올라갔는가" "origin/main 을 못 읽었다 — 원격이 없거나 fetch 전이다"
  elif [ "$ro" = "$AS_CORE_PIN" ]; then
    CORE_ORIGIN_OK=1
    ok "dss-core 의 그 커밋이 **origin/main 에 올라가 있다** (다른 PC 도 받을 수 있다)"
  else
    if git -C "$COREDIR" merge-base --is-ancestor "$AS_CORE_PIN" "$ro" 2>/dev/null; then
      CORE_ORIGIN_OK=1
      ok "핀이 origin/main 의 **조상이다** — 올라가 있다 (origin 이 ${ro:0:8} 로 더 앞서 있을 뿐)"
    else
      bad "🔴 dss-core 의 핀이 **origin 에 없다** — 다른 PC 는 그 핀을 못 받는다"
      say "      🔴 먼저 vendor/dss-core 를 밀어 두세요. 안 그러면 submodule update 가"
      say "         그 자리에서 죽고, 이 PC 에서만 되는 이미지가 됩니다."
      doubt
    fi
  fi
else
  bad "vendor/dss-core 가 **비어 있다**(.git 이 없다) — submodule update --init 이 필요하다"
fi

say ""
say "── 3-ㄷ. 🔴 **핀만 보면 빈 서브모듈도 통과한다** — 안의 파일을 값으로 센다"
SUBFILE_SEEN=0
check_sub() { # 1 폴더 2 이름
  SUBFILE_SEEN=$((SUBFILE_SEEN+1))
  local n d
  n=$(ls -1 "$1" 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -ge 3 ] 2>/dev/null; then ok "$2 작업본에 파일이 ${n}개 있다"
  else bad "$2 작업본이 비었다(${n:-?}개) — submodule update --init 이 필요하다"; fi
  d=$(git -C "$1" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${d:-1}" = "0" ]; then ok "$2 미커밋 0줄"
  else bad "$2 에 미커밋이 ${d}줄 있다 — 🔴 서브모듈 안을 고치지 마세요"; fi
}
check_sub "$COREDIR"   "A/S-core"
check_sub "$UIDIR"     "A/S-ui"
check_sub "$AUTHUIDIR" "포털-ui"
[ "$SUBFILE_SEEN" = "3" ] && ok "서브모듈 작업본 셋을 다 봤다 (표본이 비지 않았다)" \
  || bad "서브모듈 작업본을 ${SUBFILE_SEEN}개만 봤다 — 3개를 기대했다"
if [ -f "$COREDIR/$AS_CORE_KEEP_FILE" ]; then
  ok "쉰여덟째가 올린 공용 스키마가 **작업본에 있다** ($AS_CORE_KEEP_FILE)"
  n=$(grep -cF "$AS_CORE_KEEP_TABLE" "$COREDIR/$AS_CORE_KEEP_FILE" 2>/dev/null || true)
  if isnum "${n:-}" && [ "${n:-0}" -ge 1 ]; then
    ok "그 파일이 표 이름 $AS_CORE_KEEP_TABLE 을 적는다 (${n}줄)"
  else
    bad "그 파일에 표 이름 $AS_CORE_KEEP_TABLE 이 없다 — 다른 것을 보고 있다"
  fi
else
  bad "공용 스키마 파일이 **작업본에 없다** — 🔴 핀만 맞고 **파일이 비었다**"
  say "      🔴 그대로 구우면 도구가 @dss/core/schema 에서 그 표를 **못 찾습니다.**"
  say "      → git -C \"$ASD\" submodule update --init --recursive"
fi
n=$(grep -c "$AS_CORE_KEEP_EXPORT" "$COREDIR/src/schema/index.ts" 2>/dev/null || true)
if isnum "${n:-}" && [ "${n:-0}" -ge 1 ]; then
  ok "index.ts 가 그 스키마를 **내보낸다** (${n}줄)"
  say "      🔵 안 내보내면 도구가 Cannot find export 로 죽습니다 — 2026-09-21 에"
  say "         운영에서 도구가 전부 죽은 그 자리입니다."
else
  bad "index.ts 가 그 스키마를 안 내보낸다 — Cannot find export 가 난다"
fi

# 🔴 **이번 판이 그 안에 더한 칸 넷** — 하나라도 없으면 마이그레이션만 올라가고
#    코드는 그 칸을 모르는 어긋난 판이 된다.
say ""
say "── 3-ㄹ. 🔴 **이번 판이 공용 스키마에 더한 칸 넷** — 파일 셋에 흩어져 있다"
say "🔴 **하나만 보면 안 됩니다** — 이 배포는 갈래가 셋이고, 칸도 셋에 나뉘어"
say "   있습니다. 하나만 재면 **나머지 갈래가 안 담긴 공용 스키마**를 못 가릅니다."
say "🔵 칸 이름(snake)과 속성 이름(camel)을 **둘 다** 봅니다 — 한쪽만 있으면 선언이 반쪽입니다."
NEWCOL_SEEN=0; NEWCOL_OK=0
while IFS='|' read -r CF CN CP; do
  [ -n "${CF:-}" ] || continue
  NEWCOL_SEEN=$((NEWCOL_SEEN+1))
  if [ ! -f "$COREDIR/$CF" ]; then
    bad "$CF 이 **작업본에 없다** — 서브모듈을 안 받았다"
    continue
  fi
  a=$(grep -cF -- "$CN" "$COREDIR/$CF" 2>/dev/null || true)
  b=$(grep -cF -- "$CP" "$COREDIR/$CF" 2>/dev/null || true)
  printf '      %-44s [%s] %s줄 · [%s] %s줄\n' "$CF" "$CN" "${a:-?}" "$CP" "${b:-?}"
  if [ "${a:-0}" -ge 1 ] 2>/dev/null && [ "${b:-0}" -ge 1 ] 2>/dev/null; then
    NEWCOL_OK=$((NEWCOL_OK+1))
  else
    bad "$CF 에 $CN / $CP 가 없다 — 칸 이름 ${a:-?}줄 · 속성 ${b:-?}줄 (둘 다 1 이상이어야 한다)"
  fi
done <<ENDNEWCOL
$(rows_of "$AS_CORE_NEW")
ENDNEWCOL
say "본 칸 ${NEWCOL_SEEN} · 갖춘 칸 ${NEWCOL_OK} (기대 $AS_CORE_NEW_WANT · $AS_CORE_NEW_WANT)"
if [ "$NEWCOL_SEEN" = "$AS_CORE_NEW_WANT" ] && [ "$NEWCOL_OK" = "$AS_CORE_NEW_WANT" ]; then
  ok "공용 스키마가 **이번 판의 칸 넷을 다 선언한다**"
else
  bad "본 칸 ${NEWCOL_SEEN} · 갖춘 칸 ${NEWCOL_OK} 다 — $AS_CORE_NEW_WANT 을 기대했다"
  say "      🔴 **서브모듈을 안 받았거나 옛 핀입니다.** 3-ㄱ 을 다시 보세요."
  doubt
fi

# ── 4. 🔴 마이그레이션 — **A/S 2건 · 포털 0건** ──────────────────────
step "4. 🔴 마이그레이션 — **A/S 2건** ($AS_SQL_WAS → $AS_SQL_WANT) · 🔵 **포털 0건**"
say "🔴 **66번은 1건이었습니다** — 한 글자(AS_THIS_MIG)로 들고 있었는데, 이번은"
say "   **둘**이라 그대로 베끼면 **둘째 장이 아무 검사도 안 받습니다.** 목록으로 바꿨습니다."
say "🔴 **drizzle 는 밀린 것을 한 트랜잭션에 넣습니다** — 0132·0133 이 한 판에"
say "   들어갑니다. 둘 다 **더하기만** 하는지 4-ㄷ 이 **장마다** 잽니다."

# 4-ㄱ. 🔴 **잣대가 살아 있는가를 먼저 잰다** — 표본 일곱
say ""
say "── 4-ㄱ. 🔴 지우는 문장 잣대가 **살아 있는가** (표본 일곱으로 먼저 잰다)"
say "🔴 표본이 비어서 공짜로 통과하는 일을 막는 절입니다. 잣대가 죽어 있으면"
say "   아래 「지우는 문장 0줄」이 **아무것도 안 재는 ✓** 가 됩니다."
say "🔴 **이번 판에 표본이 하나 늘었습니다** — 0133 에 ON DELETE restrict 가 1줄"
say "   있습니다. 「ON DELETE 가 「지우는 문장」 검사에 걸린다」가 이 저장소에 적혀"
say "   있고, 그때는 **표만 더하는 판이 ✗** 가 됐습니다."
PROBE_SEEN=0
probe_destructive() { # 1 글 2 기대(hit|miss) 3 이름
  local n
  PROBE_SEEN=$((PROBE_SEEN+1))
  n=$(printf '%s\n' "$1" | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
  case "$2" in
    hit)  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then ok "잣대가 $3 를 **잡는다**"; else bad "잣대가 $3 를 **못 잡는다** — 잣대가 죽었다"; fi ;;
    miss) if [ "${n:-1}" = "0" ]; then ok "잣대가 $3 를 **안 센다** (맞다)"; else bad "잣대가 $3 를 **센다** — 멀쩡한 판이 ✗ 가 된다"; fi ;;
  esac
}
probe_destructive 'DROP TABLE "x";'                          hit  "DROP TABLE"
probe_destructive 'TRUNCATE "x";'                            hit  "TRUNCATE"
probe_destructive 'DELETE FROM "x" WHERE id = 1;'            hit  "DELETE FROM"
probe_destructive '-- DELETE FROM "x" 는 안 한다'            miss "주석 속 DELETE FROM"
probe_destructive 'ALTER TABLE "x" ADD COLUMN "y" text;'     miss "ADD COLUMN (이번 판의 실물)"
probe_destructive 'ALTER TABLE "x" DROP COLUMN "y";'         hit  "DROP COLUMN (뒤집은 짝)"
probe_destructive 'REFERENCES "u"("id") ON DELETE restrict'  miss "🔴 ON DELETE restrict (0133 의 실물)"
say "본 표본 ${PROBE_SEEN}개 (기대 7)"
[ "$PROBE_SEEN" = "7" ] && ok "잣대 표본 일곱을 다 돌았다 (표본이 비지 않았다)" \
  || bad "잣대 표본을 ${PROBE_SEEN}개만 돌았다 — 7개를 기대했다"
say "🔵 다섯째·여섯째가 **짝**입니다 — 이번 판의 ADD COLUMN 은 안 세고, 글자 하나"
say "   다른 DROP COLUMN 은 잡습니다. 하나만 두면 잣대가 어느 쪽으로 죽었는지 모릅니다."
say "🔴 일곱째가 **이번 판에 새로 넣은 표본**입니다 — 0133 의 외래키 줄입니다."

# 4-ㄴ. 수 세기 — 🔴 **A/S 132 → 134 · 포털 11 그대로**
say ""
say "── 4-ㄴ. 저장소 drizzle/ 을 센다 (.sql 수 == meta/_journal.json 의 idx 수)"
MIGCK_SEEN=0
s=$(ls -1 "$ASD/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
j=$(grep -o '"idx"' "$ASD/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
MIGCK_SEEN=$((MIGCK_SEEN+1))
say "A/S .sql ${s:-?}장 · idx ${j:-?}개 (기대 $AS_SQL_WANT · $AS_SQL_WANT)"
if [ "${s:-x}" = "$AS_SQL_WANT" ] && [ "${j:-x}" = "$AS_SQL_WANT" ]; then
  ok "A/S drizzle/ 이 ${AS_SQL_WANT}장이고 목록도 ${AS_SQL_WANT}개다 (운영 ${AS_SQL_WAS}장에 두 장 더한 수다)"
else
  bad "A/S 가 .sql ${s:-?} · idx ${j:-?} 다 — ${AS_SQL_WANT}·${AS_SQL_WANT} 를 기대했다"
  say "      🔴 **.sql 과 idx 가 다르면** 목록에 없는 파일이 있다는 뜻이고,"
  say "         drizzle 이 그것을 **아예 모릅니다**(적용이 0건으로 조용히 끝납니다)."
  doubt
fi
MIGCK_SEEN=$((MIGCK_SEEN+1))
s=$(ls -1 "$AUTHD/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
j=$(grep -o '"idx"' "$AUTHD/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
say "포털 .sql ${s:-?}장 · idx ${j:-?}개 (기대 $AUTH_SQL_WANT · $AUTH_SQL_WANT — **안 는다**)"
if [ "${s:-x}" = "$AUTH_SQL_WANT" ] && [ "${j:-x}" = "$AUTH_SQL_WANT" ]; then
  ok "포털 drizzle/ 이 ${AUTH_SQL_WANT}장 그대로다 (🔵 그래서 묶음이 **A/S 하나뿐**이다)"
  say "      🔴 포털은 .sql 이 **이미지 안**에 구워져 갑니다 — 도구를 구우면 11장이"
  say "         그대로 실려 가고, 운영의 수는 안 바뀝니다."
else
  bad "포털이 .sql ${s:-?} · idx ${j:-?} 다 — ${AUTH_SQL_WANT} 을 기대했다"
  doubt
fi
MIGCK_SEEN=$((MIGCK_SEEN+1))
dn=$(git -C "$ASD" diff --name-only "$(repo_base as)..main" -- drizzle 2>/dev/null | tr -d '\r' | grep -c . || true)
say "A/S 범위의 drizzle/ 변경 ${dn:-?}줄 (기대 $AS_DRIZZLE_DIFF_WANT)"
git -C "$ASD" diff --name-only "$(repo_base as)..main" -- drizzle 2>/dev/null | sed 's/^/        /'
if [ "${dn:-x}" = "$AS_DRIZZLE_DIFF_WANT" ]; then
  ok "A/S 범위가 drizzle/ 을 **${AS_DRIZZLE_DIFF_WANT}줄 건드렸다** — 🔴 **올릴 마이그레이션이 2건 있다**"
  say "      🔴 그래서 71-deploy.sh 에는 **--migrate 모드가 되살아나 있습니다**(70번엔 없었습니다)."
  say "      🔴 그리고 이 파일이 **묶음 as-migrations.tar.gz 를 만듭니다** — A/S 는"
  say "         마이그레이션이 **볼륨**에서 돌아 이미지로는 안 갑니다."
else
  bad "A/S 의 drizzle/ 변경이 ${dn:-?}줄이다 — $AS_DRIZZLE_DIFF_WANT 을 기대했다"
  say "      🔴 이 배포본은 **0132·0133 두 건**을 전제로 쓰였습니다. 멈추고 알리세요."
  doubt
fi
MIGCK_SEEN=$((MIGCK_SEEN+1))
an=$(git -C "$AUTHD" diff --name-only "$(repo_base auth)..main" -- drizzle 2>/dev/null | tr -d '\r' | grep -c . || true)
say "포털 범위의 drizzle/ 변경 ${an:-?}줄 (기대 $AUTH_DRIZZLE_DIFF_WANT)"
if [ "${an:-x}" = "$AUTH_DRIZZLE_DIFF_WANT" ]; then
  ok "포털 범위가 drizzle/ 을 **한 줄도 안 건드렸다** (포털 DB 는 안 바뀐다)"
else
  bad "포털의 drizzle/ 변경이 ${an:-?}줄이다 — $AUTH_DRIZZLE_DIFF_WANT 을 기대했다"
  say "      🔴 포털에 마이그레이션이 생겼으면 **이 배포본의 전제가 깨집니다** —"
  say "         71-deploy.sh 의 MIGS_KEEP 에 포털이 **「안 바뀌는 집」**으로 들어 있습니다."
  doubt
fi
MIGCK_SEEN=$((MIGCK_SEEN+1))
TN=0
for t in $AS_NEW_MIGS; do
  a=$(ls -1 "$ASD/drizzle/${t}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  printf '      %-6s .sql %s개 (기대 1)\n' "$t" "${a:-0}"
  [ "${a:-0}" = "1" ] && TN=$((TN+1))
done
say "이번 판이 올릴 ${AS_NEW_MIGS_WANT}장 중 있는 것 ${TN}장"
if [ "$TN" = "$AS_NEW_MIGS_WANT" ]; then
  ok "$AS_NEW_MIGS 이 다 있다 (**이 배포의 목적물이다**)"
else
  bad "이번 판이 올릴 .sql 이 ${TN}/${AS_NEW_MIGS_WANT} 장이다. 이 배포본의 전제가 깨졌다"
  doubt
fi
MIGCK_SEEN=$((MIGCK_SEEN+1))
nx=$(ls -1 "$ASD/drizzle/${AS_NEXT_MIG}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
say "$AS_NEXT_MIG 이 생겼는가: ${nx:-?}개 (기대 0)"
if [ "${nx:-1}" = "0" ]; then
  ok "$AS_NEXT_MIG 이 없다 (마지막이 0133 — 적용 대기 **2건**)"
  say "      🔴 **drizzle 는 밀린 것을 한 트랜잭션에 넣습니다** — 셋이 되면 이 배포본의"
  say "         전제가 깨지고, 쪼개도 안 넘어가는 판이 섞일 수 있습니다."
else
  bad "$AS_NEXT_MIG 이 **생겼다** — 이 배포본은 0133 까지를 전제로 쓰였다. 멈추고 알릴 것"
fi
[ "$MIGCK_SEEN" = "6" ] && ok "마이그레이션 수 검사 여섯을 다 돌았다 (표본이 비지 않았다)" \
  || bad "마이그레이션 수 검사를 ${MIGCK_SEEN}개만 돌았다 — 6개를 기대했다"

# 4-ㄷ. 🔴 **장마다** 생김새를 본다 — 더하기만 하는가
say ""
say "── 4-ㄷ. 🔴 **0132·0133 의 생김새** — **장마다** 본다 (합도 본다)"
say "🔴 66번은 한 장이라 한 번만 봤습니다. **둘을 한 잣대로 뭉뚱그리면** 한 장이"
say "   더럽혀져도 다른 장의 ✓ 에 묻힙니다."
MIGSHAPE_SEEN=0; MIGSHAPE_OK=0; ACSUM=0
for t in $AS_NEW_MIGS; do
  MIGSHAPE_SEEN=$((MIGSHAPE_SEEN+1))
  P=$(ls -1 "$ASD/drizzle/${t}"_*.sql 2>/dev/null | head -1)
  if [ -z "${P:-}" ] || [ ! -f "$P" ]; then
    bad "$t 의 .sql 을 못 찾았다"
    continue
  fi
  REL=${P#"$ASD/"}
  added=$(git -C "$ASD" diff --diff-filter=A --name-only "$(repo_base as)..main" -- drizzle 2>/dev/null | tr -d '\r' | grep -cFx "$REL" || true)
  raw=$(grep -ciE "$DESTRUCTIVE_RE" "$P" 2>/dev/null || true)
  net=$(grep -v "$SQL_COMMENT_RE" "$P" 2>/dev/null | grep -ciE "$DESTRUCTIVE_RE" || true)
  ct=$(grep -v "$SQL_COMMENT_RE" "$P" 2>/dev/null | grep -c 'CREATE TABLE' || true)
  ins=$(grep -v "$SQL_COMMENT_RE" "$P" 2>/dev/null | grep -c 'INSERT INTO' || true)
  rn=$(grep -ciE 'RENAME' "$P" 2>/dev/null || true)
  ac=$(grep -v "$SQL_COMMENT_RE" "$P" 2>/dev/null | grep -c 'ADD COLUMN' || true)
  ond=$(grep -cF 'ON DELETE' "$P" 2>/dev/null || true)
  isnum "${ac:-}" && ACSUM=$((ACSUM + ac))
  printf '      %-6s %s\n' "$t" "$REL"
  printf '        새파일 %s · 지우는문장 날것 %s/걷은뒤 %s(기대 %s) · ADD COLUMN %s · RENAME %s(기대 0)\n' \
    "${added:-0}" "${raw:-?}" "${net:-?}" "$MIG_DROP_WANT" "${ac:-?}" "${rn:-?}"
  printf '        CREATE TABLE %s(기대 0) · INSERT %s(기대 0) · (참고) ON DELETE %s줄\n' \
    "${ct:-?}" "${ins:-?}" "${ond:-?}"
  if [ "${added:-0}" = "1" ] && [ "${net:-x}" = "$MIG_DROP_WANT" ] && [ "${ins:-1}" = "0" ] \
     && [ "${ct:-1}" = "0" ] && [ "${rn:-1}" = "0" ] && [ "${ac:-0}" -ge 1 ] 2>/dev/null; then
    MIGSHAPE_OK=$((MIGSHAPE_OK+1))
    ok "$t 이 **이번 범위의 새 파일**이고 **칸을 더하기만 한다**"
  else
    bad "$t 이 기대와 다르다 — 새파일 ${added:-?} · 지우는문장 ${net:-?} · INSERT ${ins:-?} · CREATE TABLE ${ct:-?} · RENAME ${rn:-?} · ADD COLUMN ${ac:-?}"
    say "      🔴 RENAME 이 0 이 아니면 **칸이 둔갑하는 판**입니다 — db:generate 가 TTY"
    say "         없이 물어볼 수 없을 때 「이름 바꾸기」로 답한 판이 그런 꼴로 나옵니다."
    doubt
  fi
done
say "본 장 ${MIGSHAPE_SEEN} · 온전한 장 ${MIGSHAPE_OK} (기대 $AS_NEW_MIGS_WANT · $AS_NEW_MIGS_WANT) · ADD COLUMN 합 ${ACSUM} (기대 $AS_ADDCOL_WANT)"
if [ "$MIGSHAPE_SEEN" = "$AS_NEW_MIGS_WANT" ] && [ "$MIGSHAPE_OK" = "$AS_NEW_MIGS_WANT" ]; then
  ok "두 장을 **다 보고 다 온전했다** (표본이 비지 않았다)"
else
  bad "본 장 ${MIGSHAPE_SEEN} · 온전한 장 ${MIGSHAPE_OK} 다 — $AS_NEW_MIGS_WANT 을 기대했다"
fi
if [ "$ACSUM" = "$AS_ADDCOL_WANT" ]; then
  ok "두 장이 더하는 칸이 **합쳐 ${AS_ADDCOL_WANT}개다** (확정 둘 + 파일 자리 둘)"
else
  note "ADD COLUMN 합이 ${ACSUM} 이다 — $AS_ADDCOL_WANT 를 기대했다. **사람이 보세요**"
fi

# 4-ㄹ. 🔵 창 안 일곱 — 묶음을 통째로 갈아 끼우므로 창 안을 다 본다
say ""
say "── 4-ㄹ. 🔵 창 안 일곱($AS_KEEP_MIGS) — .sql 과 스냅샷이 짝으로 있는가"
say "🔴 **묶음은 drizzle/ 폴더를 통째로 갈아 끼웁니다** — 한 장이라도 스냅샷이"
say "   빠지면 다음 판의 db:generate 가 엉뚱한 차이를 만들어 냅니다."
KEEP_MISS=""
KEEP_SEEN=0
for t in $AS_KEEP_MIGS; do
  KEEP_SEEN=$((KEEP_SEEN+1))
  a=$(ls -1 "$ASD/drizzle/${t}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  b=$(ls -1 "$ASD/drizzle/meta/${t}"_snapshot.json 2>/dev/null | wc -l | tr -d ' ')
  printf '      %-6s .sql %s · 스냅샷 %s\n' "$t" "${a:-0}" "${b:-0}"
  [ "${a:-0}" -ge 1 ] 2>/dev/null || KEEP_MISS="$KEEP_MISS $t(sql)"
  [ "${b:-0}" -ge 1 ] 2>/dev/null || KEEP_MISS="$KEEP_MISS $t(snapshot)"
done
if [ "$KEEP_SEEN" = "$AS_KEEP_MIGS_WANT" ] && [ -z "${KEEP_MISS:-}" ]; then
  ok "창 안 ${AS_KEEP_MIGS_WANT}장이 .sql 과 스냅샷을 다 갖췄다"
else
  bad "본 것 ${KEEP_SEEN}장 · 빠진 것:${KEEP_MISS:- 없음} (${AS_KEEP_MIGS_WANT}장을 기대했다)"
fi

say ""
say "🔵 **운영이 지금 들고 있어야 하는 수** — $PROD_MIGS_NOTE"
say "   🔴 **개발 PC 에서는 못 잽니다.** 71-deploy.sh --check 가 DB 에 물어 확인하고,"
say "      어긋나면 **거기서 멈춥니다.** 어긋나면 그것은 **이 배포와 무관한 다른 사고**입니다."
say "   🔴 A/S 는 마이그레이션이 **볼륨**에서 돕니다(/volume1/dss/as-migrations) —"
say "      **이미지 안에는 .sql 이 한 장도 없습니다**(5절이 값으로 잽니다). 그래서"
say "      **묶음을 보내 볼륨에 풀어야** $AS_SQL_WAS → $AS_SQL_WANT 가 됩니다."
say "   🔵 **포털은 반대입니다** — 이미지 안에서 돌고, 이번 판은 올릴 것이 0건입니다."

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 담는 길 · 굽는 까닭 · 소스가 새 코드를 담고 있나 ────────────
# ══════════════════════════════════════════════════════════════════════
step "5. 🔴 담는 길 · 굽는 까닭 · 소스가 새 코드를 담고 있나 (**집마다**)"

# 5-ㄱ. Dockerfile 이 담는 길 — 🔴 **집마다 뜻이 반대인 줄이 있다**
say "── 5-ㄱ. Dockerfile 의 COPY 줄 — 🔴 **A/S 와 포털이 drizzle 에서 갈린다**"
say "🔴 A/S 의 「drizzle 을 **안 담는다**」는 **볼륨이 정본**이라는 뜻이고,"
say "   포털의 「drizzle 을 **담는다**」는 **이미지 안에서 돈다**는 뜻입니다."
say "   🔴 한 줄로 베끼면 둘 중 하나가 **가짜 ✗** 가 됩니다(62-build.sh:34-35 의 경고)."
COPY_SEEN=0
while IFS='|' read -r RK RE WANT MSG; do
  [ -n "${RK:-}" ] || continue
  COPY_SEEN=$((COPY_SEEN+1))
  DF="$(repo_dir "$RK")/Dockerfile"
  if [ ! -f "$DF" ]; then bad "$(repo_name "$RK") 의 Dockerfile 이 없다 ($DF)"; continue; fi
  n=$(grep -cE "$RE" "$DF" 2>/dev/null || true)
  ln=$(grep -nE "$RE" "$DF" 2>/dev/null | head -1 | cut -d: -f1)
  if [ "$WANT" = "yes" ]; then
    if [ "${n:-0}" -ge 1 ] 2>/dev/null; then ok "$MSG (${ln:-?}줄)"
    else bad "$(repo_name "$RK") 의 Dockerfile 에 그 COPY 가 **없다** — $MSG"; doubt; fi
  else
    if [ "${n:-1}" = "0" ]; then ok "$MSG"
    else bad "$(repo_name "$RK") 의 Dockerfile 에 그 COPY 가 **있다**(${ln}줄) — $MSG"; doubt; fi
  fi
done <<ENDCOPY
$(rows_of "$COPYRULES")
ENDCOPY
[ "$COPY_SEEN" = "$COPYRULES_WANT" ] && ok "COPY 규칙 ${COPYRULES_WANT}줄을 다 봤다 (표본이 비지 않았다)" \
  || bad "COPY 규칙을 ${COPY_SEEN}줄만 봤다 — ${COPYRULES_WANT}줄을 기대했다. 표가 깨졌다"

# 5-ㄴ. .dockerignore 가 .next 를 막는가 — **집마다**
say ""
say "── 5-ㄴ. .dockerignore 가 .next 를 막는가 — 막아야 dev 서버를 안 내려도 된다"
DI_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  RK=$(field "$r" 1); RN=$(field "$r" 3)
  DI_SEEN=$((DI_SEEN+1))
  DI="$(repo_dir "$RK")/.dockerignore"
  if [ ! -f "$DI" ]; then bad "$RN 에 .dockerignore 가 없다 — 🔴 호스트의 .next 가 섞여 들어간다"; continue; fi
  n=$(grep -c '^\.next' "$DI" 2>/dev/null || true)
  say "$RN 의 .dockerignore 에 ^.next 줄 ${n:-?}개 (기대 1 이상)"
  [ "${n:-0}" -ge 1 ] 2>/dev/null && ok "$RN .dockerignore 가 .next 를 막는다" \
    || bad "$RN .dockerignore 가 .next 를 **안 막는다** — dev 서버를 내리고 구워야 한다"
done <<ENDDI
$(rows_of "$REPOS")
ENDDI
[ "$DI_SEEN" = "$REPOS_WANT" ] && ok ".dockerignore 를 ${REPOS_WANT}집에서 다 봤다" \
  || bad ".dockerignore 를 ${DI_SEEN}집만 봤다"

# 5-ㄷ. 🔴 **굽는 까닭 ㄱ** — npm 명령 수 (집마다)
say ""
say "── 5-ㄷ. 🔴 굽는 까닭 **ㄱ** — npm 명령이 늘었나 (scripts 블록 안만 센다)"
say "🔴 「안 걸린다」도 **값으로 잽니다.** 바뀌었는데 0 으로 적어 두면 다음 판이"
say "   그 거짓을 근거로 「안 구워도 된다」를 꺼냅니다(41번이 Missing script 로 데였습니다)."
NPM_SEEN=0
while IFS='|' read -r RK WAS NOW; do
  [ -n "${RK:-}" ] || continue
  NPM_SEEN=$((NPM_SEEN+1))
  RD=$(repo_dir "$RK"); RN=$(repo_name "$RK"); RB=$(repo_base "$RK")
  a=$(git -C "$RD" show "$RB:package.json" 2>/dev/null </dev/null | count_scripts)
  b=$(count_scripts < "$RD/package.json")
  say "$RN npm 명령 — 기준 ${a:-?} → 지금 ${b:-?} (적어 둔 값 $WAS → $NOW)"
  if [ "${a:-x}" = "$WAS" ] && [ "${b:-x}" = "$NOW" ]; then
    if [ "$WAS" = "$NOW" ]; then ok "$RN npm 명령이 안 늘었다 — **ㄱ 잣대가 안 걸린다**"
    else ok "$RN npm 명령이 $WAS → $NOW 로 늘었다 — 🔴 **ㄱ 잣대가 걸린다**"; fi
  else
    bad "$RN npm 명령이 ${a:-?} → ${b:-?} 다 — $WAS → $NOW 를 기대했다"
    say "      🔴 늘었으면 **도구를 안 구우면 Missing script** 가 납니다."
    doubt
  fi
  pk=$(git -C "$RD" diff --numstat "$RB..main" -- package.json package-lock.json tsconfig.json drizzle.config.ts 2>/dev/null | wc -l | tr -d ' ')
  say "   $RN 의 의존성·설정 파일 넷 중 바뀐 것 ${pk:-?}장 (기대 0)"
  if [ "${pk:-1}" = "0" ]; then
    ok "$RN 의 의존성·설정 파일이 **한 장도 안 바뀌었다**"
  else
    note "$RN 에서 그 넷 중 ${pk}장이 바뀌었다 — 0을 기대했다. **이미지 크기가 뛸 수 있습니다.** 사람이 보세요"
  fi
done <<ENDNPM
$(rows_of "$NPMCOUNT")
ENDNPM
[ "$NPM_SEEN" = "$NPMCOUNT_WANT" ] && ok "npm 명령 수를 ${NPMCOUNT_WANT}집에서 다 봤다" \
  || bad "npm 명령 수를 ${NPM_SEEN}집만 봤다"
say "🔴 **넷 다 strict 로 둔 근거가 위 두 줄입니다** — 라이브러리가 한 개도 안 늘었습니다."
# 🔵 뒷걸음 — 쉰여덟째가 더한 heic2any 가 그대로 있는가(빠지면 아이폰 사진이 다시 막힌다)
n=$(grep -c '"heic2any"' "$ASD/package.json" 2>/dev/null || true)
say "heic2any (쉰여덟째가 더한 것) — ${n:-?}줄 (기대 1)"
[ "${n:-x}" = "1" ] && ok "heic2any 가 그대로 있다 (뒷걸음친 나무가 아니다)" \
  || bad "heic2any 가 ${n:-?}줄이다 — 1 을 기대했다"

# 5-ㄹ. 🔴 **굽는 까닭 ㄴ·ㄷ·ㄹ**
say ""
say "── 5-ㄹ. 🔴 굽는 까닭 **ㄴ** — tools 가 담는 것 중 바뀐 파일 (집마다)"
AS_LIST=$(git -C "$ASD" diff --name-only "$(repo_base as)..main" 2>/dev/null | tr -d '\r')
AUTH_LIST=$(git -C "$AUTHD" diff --name-only "$(repo_base auth)..main" 2>/dev/null | tr -d '\r')
PAY_SEEN=0
while IFS='|' read -r RK WANT; do
  [ -n "${RK:-}" ] || continue
  PAY_SEEN=$((PAY_SEEN+1))
  RN=$(repo_name "$RK")
  # 🔴 **정규식은 표가 아니라 스칼라에서 꺼낸다**(그 까닭은 표 주석에).
  RE=$(payload_re "$RK")
  if [ -z "${RE:-}" ]; then
    bad "$RN 의 담기는 길 정규식을 못 꺼냈다 — payload_re 에 그 열쇠가 없다"
    continue
  fi
  # 🔴 **잣대부터 잰다** — 정규식이 깨져 있으면 아래 수가 통째로 거짓이 된다.
  #    [실측 2026-11-25] 처음 판은 여기가 없어서 깨진 정규식이 ⚠️ 로만 새어 나왔다.
  ph=$(printf '%s\n' "$PAYLOAD_PROBE_HIT" | grep -cE "$RE" 2>/dev/null || true)
  pm=$(printf '%s\n' "$PAYLOAD_PROBE_MISS" | grep -cE "$RE" 2>/dev/null || true)
  say "$RN 잣대 표본 — [$PAYLOAD_PROBE_HIT] ${ph:-?}(기대 1) · [$PAYLOAD_PROBE_MISS] ${pm:-?}(기대 0)"
  if [ "${ph:-x}" = "1" ] && [ "${pm:-x}" = "0" ]; then
    ok "$RN 의 담기는 길 정규식이 **살아 있다** (아래 수를 믿을 수 있다)"
  else
    bad "$RN 의 정규식이 **깨졌다** — 표본이 ${ph:-?}·${pm:-?} 다 (1·0 을 기대했다)"
    say "      🔴 grep 이 Unmatched ( 로 죽으면 아래 수가 **?** 가 됩니다 — 그 꼴을"
    say "         이 줄이 먼저 잡습니다(2026-11-25 에 실제로 그 일이 있었습니다)."
    doubt
    continue
  fi
  case "$RK" in
    as)   L="$AS_LIST" ;;
    auth) L="$AUTH_LIST" ;;
    *)    L="" ;;
  esac
  all=$(printf '%s\n' "$L" | grep -c . || true)
  pay=$(printf '%s\n' "$L" | grep -cE "$RE" || true)
  say "$RN — tools 가 담는 것 중 바뀐 파일 ${pay:-?} / ${all:-?} 장 (적어 둔 값 $WANT)"
  if [ "${pay:-x}" = "$WANT" ]; then
    if [ "${pay:-0}" -ge 1 ] 2>/dev/null; then
      ok "🔴 $RN 의 **ㄴ 잣대가 걸린다** — ${pay}장이 도구 이미지 안으로 들어간다"
    else
      ok "$RN 의 ㄴ 잣대가 안 걸린다 (도구가 담는 것 중 바뀐 것이 0장이다)"
    fi
  else
    note "$RN 의 ㄴ 수가 ${pay:-?} 다 — $WANT 을 기대했다. **사람이 보세요**"
    say "      🔵 커밋이 하나 더 밀렸으면 여기가 먼저 어긋납니다(2절의 ⚠️ 와 짝입니다)."
  fi
done <<ENDPAY
$(rows_of "$TOOLS_PAYLOAD")
ENDPAY
[ "$PAY_SEEN" = "$TOOLS_PAYLOAD_WANT" ] && ok "ㄴ 잣대를 ${TOOLS_PAYLOAD_WANT}집에서 다 봤다" \
  || bad "ㄴ 잣대를 ${PAY_SEEN}집만 봤다"
say "🔵 A/S 에서 빠지는 여섯은 **drizzle/ 다섯과 뿌리의 진행현황 HTML 한 장**입니다 —"
say "   A/S tools 는 drizzle 을 안 담고(5-ㄱ), 뿌리의 HTML 은 어느 COPY 에도 안 걸립니다."
say "🔵 포털에서 빠지는 하나는 **docs/ 의 문서**입니다."

say ""
say "ㄷ) 🔵 **도구의 import 닫힘** — 🔴 **이번 판에도 안 걸린다.** 잣대만 재 둔다"
say "🔴 **그래도 절을 빼지 않습니다** — 빼면 다음 판이 「ㄷ 는 원래 없는 절」로 읽고,"
say "   그 둘이 옛 몸통으로 도는 사고를 아무도 못 잡습니다."
IMP_SEEN=0; IMP_OK=0
tn=$(printf '%s\n' "$AS_LIST" | grep -cFx "$TOOL_IMPORT_TARGET" || true)
say "바뀐 목록에 $TOOL_IMPORT_TARGET 이 ${tn:-?}줄 (기대 $TOOL_IMPORT_TARGET_WANT)"
if [ "${tn:-x}" = "$TOOL_IMPORT_TARGET_WANT" ]; then
  ok "그 모듈이 **이번 범위에 ${TOOL_IMPORT_TARGET_WANT}줄이다** — ㄷ 잣대는 안 걸린다"
else
  note "그 모듈이 바뀐 목록에 ${tn:-?}줄이다 — $TOOL_IMPORT_TARGET_WANT 을 기대했다. **사람이 보세요**"
  say "      🔵 1 이면 ㄷ 가 되살아난 것이라 **굽는 까닭이 하나 더 는 것**입니다 —"
  say "         그래서 ⚠️ 로만 셉니다(막을 일이 아닙니다)."
fi
while IFS='|' read -r F IMP; do
  [ -n "${F:-}" ] || continue
  IMP_SEEN=$((IMP_SEEN+1))
  if [ ! -f "$ASD/$F" ]; then bad "$F 가 없다 — 표가 틀렸다"; continue; fi
  n=$(grep -cF -- "$IMP" "$ASD/$F" 2>/dev/null || true)
  printf '      %-48s [%s] %s줄\n' "$F" "$IMP" "${n:-?}"
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then IMP_OK=$((IMP_OK+1))
  else bad "$F 가 그 모듈을 안 부른다 — 표가 틀렸다"; fi
done <<ENDIMP
$(rows_of "$TOOL_IMPORTERS")
ENDIMP
say "본 것 ${IMP_SEEN} · 부르는 것 ${IMP_OK} (기대 $TOOL_IMPORTERS_WANT · $TOOL_IMPORTERS_WANT)"
if [ "$IMP_SEEN" = "$TOOL_IMPORTERS_WANT" ] && [ "$IMP_OK" = "$TOOL_IMPORTERS_WANT" ]; then
  ok "ㄷ 잣대가 **살아 있다** — 도구 스크립트 ${IMP_OK}장이 아직 그 모듈을 부른다"
else
  bad "본 것 ${IMP_SEEN} · 부르는 것 ${IMP_OK} 다 — ${TOOL_IMPORTERS_WANT} 을 기대했다"
  doubt
fi

say ""
say "ㄹ) 🔴 **공용 스키마(vendor/*)가 움직였나** — 3-ㄴ 과 **같은 값을 여기서 다시 센다**"
say "   🔵 두 번 세는 까닭: 3절은 「포인터가 올라갔는가」를, 여기는 「굽는 까닭이"
say "      되는가」를 말합니다. 뜻이 다르면 질의도 따로 두는 것이 이 저장소의 규율입니다."
ven0=$(printf '%s\n' "$AS_LIST" | grep -cE '^(vendor/|\.gitmodules)' || true)
say "   A/S 의 vendor/ · .gitmodules ${ven0:-?}줄 (기대 $CH_VENDOR)"
if [ "${ven0:-x}" = "$CH_VENDOR" ] && [ "${ven0:-0}" -ge 1 ] 2>/dev/null; then
  ok "🔴 **ㄹ 잣대가 걸린다** — 공용 스키마가 움직였다"
  say "      🔴 **안 구우면 도구가 confirmed_at·share_doc_relative_path 를 모르는"
  say "         스키마로 돕니다.**"
else
  bad "A/S 의 vendor/ 변경이 ${ven0:-?}줄이다 — $CH_VENDOR 을 기대했다"
  doubt
fi
say "   그 핀이 origin 에 올라가 있나: ${CORE_ORIGIN_OK:-0} (기대 1 — 3-ㄴ 에서 쟀다)"
[ "${CORE_ORIGIN_OK:-0}" = "1" ] && ok "굽는 까닭 ㄹ 의 커밋이 **origin 에도 있다** (다른 PC 가 같은 이미지를 만들 수 있다)" \
  || bad "그 커밋이 origin 에 없다 — **이 PC 에서만 되는 이미지가 된다.** 3-ㄴ 을 보세요"
say ""
say "ㅁ) 🔴 **마이그레이션이 A/S 2건이다** — 4절이 값으로 쟀다"
say "   🔴 이것은 **이미지를 굽는 까닭이 아니라 묶음을 만드는 까닭**입니다."
say "      A/S tools 는 drizzle/ 을 **안 담으므로**(5-ㄱ) 0132·0133 은 묶음으로만 갑니다."
say ""
say "🔴 **결론: 넷을 다 굽고 묶음도 만든다.**"
say "   · A/S  — ㄴ(173장) · ㄹ(공용 스키마) · ㅁ(마이그 2건)이 걸린다"
say "   · 포털 — ㄴ(5장)이 걸린다. 🔴 **포털 도구도 굽는다** — merge.ts 가 바뀌었고"
say "     check:notify·check:delegations 가 그 소스로 돕니다."
say "   🔵 반대 방향의 사고도 이 저장소에 적혀 있습니다 — 「마이그레이션 0건이니"
say "      도구는 안 굽는다」가 틀려 비상구 둘을 못 올린 적이 있고, 이튿날에는"
say "      거꾸로 「명령이 늘어난 것」을 놓쳐 Missing script 가 났습니다."

# 5-ㅁ. 바뀐 파일 수 — 집마다
say ""
say "── 5-ㅁ. 바뀐 파일 수 — **집마다** (🔴 2절의 ⚠️ 와 짝인 자리다)"
CH_SEEN=0
while IFS='|' read -r RK WALL WSRC WSCR WDRZ WVEN WNEW WDEL WPAR WBRK WTST; do
  [ -n "${RK:-}" ] || continue
  CH_SEEN=$((CH_SEEN+1))
  RD=$(repo_dir "$RK"); RN=$(repo_name "$RK"); RB=$(repo_base "$RK")
  case "$RK" in
    as)   L="$AS_LIST" ;;
    auth) L="$AUTH_LIST" ;;
    *)    L="" ;;
  esac
  all=$(printf '%s\n' "$L" | grep -c . || true)
  src=$(printf '%s\n' "$L" | grep -c '^src/' || true)
  scr=$(printf '%s\n' "$L" | grep -c '^scripts/' || true)
  drz=$(printf '%s\n' "$L" | grep -c '^drizzle/' || true)
  ven=$(printf '%s\n' "$L" | grep -cE '^(vendor/|\.gitmodules)' || true)
  par=$(printf '%s\n' "$L" | grep -cF '(' || true)
  brk=$(printf '%s\n' "$L" | grep -cF '[' || true)
  tst=$(printf '%s\n' "$L" | grep -cE '\.test\.tsx?$' || true)
  new=$(git -C "$RD" diff --diff-filter=A --name-only "$RB..main" 2>/dev/null | grep -c . || true)
  del=$(git -C "$RD" diff --diff-filter=D --name-only "$RB..main" 2>/dev/null | grep -c . || true)
  printf '      %-10s 전체 %-4s src %-4s scripts %-3s drizzle %-3s vendor %-2s 새 %-3s 지움 %-2s 괄호 %-2s 대괄호 %-2s 시험 %s\n' \
    "$RN" "${all:-?}" "${src:-?}" "${scr:-?}" "${drz:-?}" "${ven:-?}" "${new:-?}" "${del:-?}" "${par:-?}" "${brk:-?}" "${tst:-?}"
  printf '      %-10s (적어 둔 값) %-4s     %-4s         %-3s         %-3s        %-2s    %-3s      %-2s      %-2s        %-2s      %s\n' \
    "" "$WALL" "$WSRC" "$WSCR" "$WDRZ" "$WVEN" "$WNEW" "$WDEL" "$WPAR" "$WBRK" "$WTST"
  if [ "${all:-x}" = "$WALL" ] && [ "${src:-x}" = "$WSRC" ] && [ "${scr:-x}" = "$WSCR" ] \
     && [ "${drz:-x}" = "$WDRZ" ] && [ "${ven:-x}" = "$WVEN" ] && [ "${new:-x}" = "$WNEW" ] \
     && [ "${par:-x}" = "$WPAR" ] && [ "${brk:-x}" = "$WBRK" ] && [ "${tst:-x}" = "$WTST" ]; then
    ok "$RN 바뀐 파일 수가 적어 둔 것과 전부 같다"
  else
    note "$RN 바뀐 파일 수가 적어 둔 것과 다르다 — **사람이 보세요**"
    say "      🔴 **2절에서 커밋 수가 어긋났고 여기까지 어긋나면 멈추세요** — 그때는"
    say "         진행현황 HTML 한 장이 아니라 **코드가 더 밀린 것**입니다."
  fi
  if [ "${del:-1}" = "$WDEL" ]; then ok "$RN 지운 파일 ${WDEL}장"
  else bad "🔴 $RN 이 파일을 ${del}장 **지웠다** — $WDEL 을 기대했다. 멈추고 알릴 것"; fi
done <<ENDCH
$(rows_of "$CHANGED")
ENDCH
[ "$CH_SEEN" = "$CHANGED_WANT" ] && ok "바뀐 파일 수를 ${CHANGED_WANT}집에서 다 봤다" \
  || bad "바뀐 파일 수를 ${CH_SEEN}집만 봤다"
say "🔴 **A/S 범위에는 괄호가 든 경로가 4장 · 대괄호가 든 경로가 5장 있습니다:**"
printf '%s\n' "$AS_LIST" | grep -F '(' | sed 's/^/        /'
printf '%s\n' "$AS_LIST" | grep -F '[' | sed 's/^/        /'
say "   🔵 목록을 넘기는 길은 here 문서 + grep -Fx 로만 썼고 컨테이너 안에서는"
say "      set -f 로 글롭을 끕니다 — 66번은 그런 경로가 **1장**이었습니다."

# 5-ㅂ. 🔴 표식 — 소스에서 먼저 센다 (집마다)
say ""
say "── 5-ㅂ. 🔴 표식 — **소스에서 먼저 센다** (기능 0→N · 뒷걸음 N→N · 곁들이는 찍기만)"
say "🔴 기능 표식이 **셋**입니다 — 이 배포가 **세 갈래**라서입니다. 하나로 두면"
say "   둘째·셋째 갈래가 안 담긴 이미지를 못 가릅니다."
say "🔴 **포털에는 기능 표식이 0 입니다** — 이번 포털 커밋이 더한 코드에 **새 문자열"
say "   리터럴이 한 개도 없습니다.** 그 갈래는 **포털 도구 이미지**에서 가립니다(5-ㅅ)."
MK_SEEN=0; MK_FEAT=0; MK_KEEP=0; MK_SIDE=0; MK_AUTH_FEAT=0
while IFS='|' read -r RK KIND MK NOTE1; do
  [ -n "${RK:-}" ] || continue
  MK_SEEN=$((MK_SEEN+1))
  RD=$(repo_dir "$RK"); RN=$(repo_name "$RK"); RB=$(repo_base "$RK")
  a=$(mark_was "$RD" "$RB" "$MK"); b=$(mark_now "$RD" "$MK")
  printf '      %-10s %-7s %-34s 기준 %-4s → 지금 %-4s  (%s)\n' "$RN" "$KIND" "[$MK]" "${a:-?}" "${b:-?}" "$NOTE1"
  case "$KIND" in
    feature)
      MK_FEAT=$((MK_FEAT+1))
      [ "$RK" = "auth" ] && MK_AUTH_FEAT=$((MK_AUTH_FEAT+1))
      if [ "${a:-x}" = "0" ] && [ "${b:-0}" -ge 1 ] 2>/dev/null; then
        ok "$RN 기능 표식 [$MK] 이 **이번 판에만 있다**"
      else
        bad "$RN 기능 표식 [$MK] 이 기준 ${a:-?} → 지금 ${b:-?} 다 — 0 → 1 이상을 기대했다"
        say "      🔴 기준판에도 있으면 그 표식은 **아무것도 안 가릅니다.**"
        doubt
      fi
      ;;
    keep)
      MK_KEEP=$((MK_KEEP+1))
      if [ "${a:-0}" -ge 1 ] 2>/dev/null && [ "${b:-0}" -ge 1 ] 2>/dev/null; then
        ok "$RN 뒷걸음 표식 [$MK] 이 기준에도 지금에도 있다 (뒷걸음을 잴 수 있다)"
      else
        bad "$RN 뒷걸음 표식 [$MK] 이 기준 ${a:-?} · 지금 ${b:-?} 다 — 둘 다 1 이상이어야 한다"
        doubt
      fi
      ;;
    side)
      MK_SIDE=$((MK_SIDE+1))
      say "      🔵 **판정에 안 씁니다** — 번들에서 함께 찍어 ✗ 의 까닭을 가르는 데만 씁니다."
      ;;
  esac
done <<ENDMK
$(rows_of "$APPMARKS")
ENDMK
say "본 표식 ${MK_SEEN} (기대 $MARKS_WANT) · 기능 ${MK_FEAT}(기대 $MARKS_FEATURE_WANT) · 뒷걸음 ${MK_KEEP}(기대 $MARKS_KEEP_WANT) · 곁들이 ${MK_SIDE}(기대 $MARKS_SIDE_WANT)"
if [ "$MK_SEEN" = "$MARKS_WANT" ] && [ "$MK_FEAT" = "$MARKS_FEATURE_WANT" ] \
   && [ "$MK_KEEP" = "$MARKS_KEEP_WANT" ] && [ "$MK_SIDE" = "$MARKS_SIDE_WANT" ]; then
  ok "표식 ${MARKS_WANT}개를 갈래별로 다 봤다 (표본이 비지 않았다)"
else
  bad "표식 수가 어긋난다 — APPMARKS 표가 깨졌다"
fi
[ "$MK_AUTH_FEAT" = "$AUTH_FEATURE_WANT" ] && ok "포털의 기능 표식이 **${AUTH_FEATURE_WANT}개다** (머리말에 까닭을 적어 두었다)" \
  || bad "포털의 기능 표식이 ${MK_AUTH_FEAT}개다 — $AUTH_FEATURE_WANT 을 기대했다"
say "🔵 뒷걸음 표식이 **아홉(A/S)**인 까닭: 예순여섯째부터 쉰여섯째까지가 올린 글자를"
say "   하나씩 잡고 있습니다 — **하나도 빼지 마세요.**"
say "🔴 그중 [도번 / 비고] 가 **이번에 늘린 칸**입니다(70번이 올린 것)."
say "   🔴 **그 하나만 한글입니다.** 처음에는 ASCII 로 쓰려고 같은 커밋의"
say "      part.drawingNo, part.note 를 골랐는데, 그것은 70번의 **도구 이미지용**"
say "      표식이라 **번들에서 0/0** 이었습니다 — part 가 지역 이름이라 minify 가"
say "      갈아 치웁니다. [실측 2026-11-25 · dss-as:6.2]"
say "   🔵 한글이 경계를 건너가는지는 **1-ㄷ 절이 바이트로** 쟀습니다."

# 5-ㅅ. 🔴 마지막 커밋 표식 — 집마다 하나
say ""
say "── 5-ㅅ. 🔴 **마지막 커밋 표식**(도구 이미지용) — 소스에서 먼저 센다"
say "🔴 **기준에 0줄이었다는 것도 git 에서 직접 셉니다**(적어 둔 값을 안 믿습니다)."
say "🔴 **A/S 의 마지막 두 커밋(18e35c9a·56effcc8)은 진행현황 HTML 한 장짜리**라"
say "   이미지에 아무 자취도 안 남깁니다 — 그래서 과녁은 **마지막 코드 커밋**"
say "   (c9e5721f)에서만 바뀐 화면입니다."
TM_SEEN=0
while IFS='|' read -r TK MK FILE WAS_WANT NOW_WANT; do
  [ -n "${TK:-}" ] || continue
  TM_SEEN=$((TM_SEEN+1))
  RK=$(repo_key_of "$TK")
  RD=$(repo_dir "$RK"); RN=$(repo_name "$RK"); RB=$(repo_base "$RK")
  if [ ! -f "$RD/$FILE" ]; then bad "$RN — $FILE 이 없다 (표식을 둘 자리가 없다)"; continue; fi
  # 🔴 **과녁 파일이 기준판에도 있었는가** — 없었으면 「기준 0줄」이 공짜 ✓ 다.
  if git -C "$RD" cat-file -e "$RB:$FILE" 2>/dev/null; then
    ok "$RN 의 과녁 파일이 **기준판에도 있었다** (「기준 0줄」이 공짜 ✓ 가 아니다)"
  else
    bad "$RN 의 과녁 파일이 기준판에 **없었다** — 그러면 기준 0줄은 아무것도 안 가른다"
    say "      🔴 기준판에도 있던 파일을 과녁으로 고르세요."
    doubt
  fi
  was=$(git -C "$RD" show "$RB:$FILE" 2>/dev/null </dev/null | grep -cF -- "$MK" || true)
  n=$(grep -cF -- "$MK" "$RD/$FILE" 2>/dev/null || true)
  say "$RN [$MK] in $FILE — 기준 ${was:-?}줄 → 지금 ${n:-?}줄 (기대 $WAS_WANT → $NOW_WANT)"
  if [ "${was:-x}" = "$WAS_WANT" ]; then
    ok "$RN 의 그 파일 안에서는 기준판에 **${WAS_WANT}줄**이었다 (이 표식이 판을 **가른다**)"
  else
    bad "$RN 의 기준판 그 파일에 그 글자가 ${was:-?}줄 있다 — $WAS_WANT 을 기대했다"
    say "      🔴 0 이 아니면 그 표식은 **이 판을 안 가릅니다.** 다른 글자를 고르세요."
    doubt
  fi
  if [ "${n:-x}" = "$NOW_WANT" ]; then ok "$RN 의 마지막 커밋 표식이 그 파일에 ${n}줄 있다"
  elif [ "${n:-0}" -ge 1 ] 2>/dev/null; then note "$RN 에서 그 글자가 ${n}줄이다 — $NOW_WANT 을 기대했다. 사람이 보세요"
  else bad "$RN 의 마지막 커밋 표식이 그 파일에 **없다** — 표가 틀렸다"; fi
done <<ENDTM
$(rows_of "$TOOLMARKS")
ENDTM
[ "$TM_SEEN" = "$TOOLMARKS_WANT" ] && ok "마지막 커밋 표식 ${TOOLMARKS_WANT}개를 다 봤다" \
  || bad "마지막 커밋 표식을 ${TM_SEEN}개만 봤다"
# 🔴 그 표식이 가리키는 **짝 파일**이 작업본에 있는가
TP_SEEN=0
while IFS='|' read -r TK PF; do
  [ -n "${TK:-}" ] || continue
  TP_SEEN=$((TP_SEEN+1))
  RD=$(repo_dir "$(repo_key_of "$TK")")
  if [ -f "$RD/$PF" ]; then ok "짝 파일이 작업본에 있다 ($PF)"
  else bad "$PF 이 작업본에 **없다** — 화면이 import 에서 죽는다"; fi
done <<ENDTP
$(rows_of "$TOOLMARK_PAIRS")
ENDTP
[ "$TP_SEEN" = "$TOOLMARK_PAIRS_WANT" ] && ok "짝 파일 ${TOOLMARK_PAIRS_WANT}장을 다 봤다" \
  || bad "짝 파일을 ${TP_SEEN}장만 봤다"
say "🔴 **포털의 새 코드를 가르는 자리가 바로 이것입니다**(머리말의 「무엇이 없고"
say "   왜 없는가」) — 포털 앱 번들에는 가를 글자가 없어서, 62번이 계측기에서 한"
say "   그대로 **도구 이미지**에서 가립니다."

# 5-ㅇ. 🔴 시험 등록 — **집마다 방식이 다르다**
say ""
say "── 5-ㅇ. 🔴 시험 등록 — **A/S 는 목록 파일 · 포털은 package.json 의 test 줄**"
say "🔴 **방식이 저장소마다 다릅니다.** 한 집의 방식을 다른 집에 베끼면 그 집의"
say "   시험 등록이 **아무 검사도 안 받습니다.**"
say ""
say "   ㄱ) A/S — scripts/test-lists/*.txt 에 **적어야 돕니다.** 빠뜨리면 그 시험은"
say "      **오류 없이 조용히 안 돕니다.**"
TL=$(cat "$ASD"/scripts/test-lists/*.txt 2>/dev/null | tr -d '\r')
lines=$(printf '%s\n' "$TL" | grep -c . || true)
TLBASE=0; TLB_SEEN=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  TLB_SEEN=$((TLB_SEEN+1))
  n=$(git -C "$ASD" show "$(repo_base as):$f" 2>/dev/null </dev/null | tr -d '\r' | grep -c . || true)
  isnum "${n:-}" || n=0
  TLBASE=$((TLBASE + n))
done <<ENDTLB
$(rows_of "$AS_TESTLIST_FILES")
ENDTLB
say "목록 줄 수 — 기준 ${TLBASE} (본 파일 ${TLB_SEEN}장) → 지금 ${lines:-?} (적어 둔 값 $AS_TESTLIST_LINES_WAS → $AS_TESTLIST_LINES_WANT)"
if [ "$TLB_SEEN" != "$AS_TESTLIST_FILES_WANT" ]; then
  bad "기준판 목록을 ${TLB_SEEN}장만 봤다 — ${AS_TESTLIST_FILES_WANT}장을 기대했다"
fi
if ! isnum "${lines:-}" || [ "${lines:-0}" -lt "$AS_TESTLIST_MIN_LINES" ]; then
  bad "목록을 ${lines:-못 읽음}줄밖에 못 읽었다 — 🔴 **빈 결과는 삼켜진 오류일 수 있다.** 아래를 못 믿는다"
elif [ "${TLBASE:-0}" -lt "$AS_TESTLIST_MIN_LINES" ]; then
  bad "기준판 목록이 ${TLBASE}줄이다 — git show 가 비었을 수 있다. 아래를 못 믿는다"
elif [ "${lines}" -lt "${TLBASE}" ]; then
  bad "목록이 ${TLBASE} → ${lines} 로 **줄었다** — 🔴 누가 시험 등록을 **지웠다**"
  say "      🔴 등록이 빠지면 그 시험은 **오류 없이 조용히 안 돕니다.** 멈추고 알리세요."
elif [ "${lines}" = "${TLBASE}" ]; then
  bad "목록 줄 수가 ${lines} **그대로다** — 새 시험이 ${AS_NEW_TESTS_WANT}장인데 한 줄도 안 늘었다"
  say "      🔴 **등록이 통째로 빠졌습니다.** 그 마흔셋은 조용히 안 돕니다."
  doubt
else
  ok "목록이 ${TLBASE} → ${lines} 로 **늘었다** (새 시험 ${AS_NEW_TESTS_WANT}장이 등록된 꼴이다)"
  say "      🔴 **줄 수만으로는 「마흔셋이 등록됐다」를 말할 수 없습니다** — 이 저장소의"
  say "         목록 파일은 **까닭을 적은 주석**도 담습니다. 아래가 **경로를 하나씩** 묻습니다."
  [ "${lines}" = "$AS_TESTLIST_LINES_WANT" ] && ok "적어 둔 값 $AS_TESTLIST_LINES_WANT 과도 같다" \
    || note "적어 둔 값은 $AS_TESTLIST_LINES_WANT 인데 ${lines} 다 — 사람이 보세요"
  [ "${TLBASE}" = "$AS_TESTLIST_LINES_WAS" ] && ok "기준판 줄 수도 적어 둔 값 $AS_TESTLIST_LINES_WAS 과 같다" \
    || note "기준판이 ${TLBASE}줄이다 — $AS_TESTLIST_LINES_WAS 을 기대했다. 사람이 보세요"
fi
nt=$(git -C "$ASD" diff --diff-filter=A --name-only "$(repo_base as)..main" 2>/dev/null | tr -d '\r' | grep -cE '\.test\.tsx?$' || true)
say "A/S 에서 **새로 생긴** 시험 파일 ${nt:-?}개 (기대 $AS_NEW_TESTS_WANT)"
if [ "${nt:-x}" = "$AS_NEW_TESTS_WANT" ]; then
  ok "새 시험 파일이 ${AS_NEW_TESTS_WANT}개다 (🔴 **그러면 등록 여부를 재야 한다** — 아래가 잰다)"
else
  bad "새 시험 파일이 ${nt:-?}개다 — $AS_NEW_TESTS_WANT 을 기대했다"
  doubt
fi
if [ "${lines:-0}" -ge "$AS_TESTLIST_MIN_LINES" ] 2>/dev/null; then
  # ── ① 새 시험 마흔셋이 목록에 등록돼 있는가 (이 절의 본체다)
  got=0; seen=0
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    seen=$((seen+1))
    n=$(printf '%s\n' "$TL" | grep -cFx -- "$t" || true)
    if [ "${n:-0}" -ge 1 ] 2>/dev/null; then got=$((got+1)); else printf '        🔴 안 적힘 %s\n' "$t"; fi
  done <<ENDNEWT
$(rows_of "$AS_NEW_TESTS")
ENDNEWT
  probe=$(printf '%s\n' "$TL" | grep -cFx -- "$PROBE_MISS" || true)
  say "새 시험 — 본 것 ${seen} · 적혀 있는 것 ${got} (기대 $AS_NEW_TESTS_WANT · $AS_NEW_TESTS_WANT) · 없는 경로 ${probe:-?}줄(기대 0)"
  if [ "${probe:-1}" != "0" ]; then
    bad "**없는 경로가 목록에 있다고 나왔다** — 줄 전체 일치가 깨졌다. 위 수도 못 믿는다"
  elif [ "$seen" = "$AS_NEW_TESTS_WANT" ] && [ "$got" = "$AS_NEW_TESTS_WANT" ]; then
    ok "🔴 **새 시험 ${AS_NEW_TESTS_WANT}개가 전부 목록에 등록돼 있다** (조용히 안 도는 시험이 없다)"
    say "      🔵 그중 하나는 **대괄호가 든 경로**입니다 — 글롭 함정의 실물입니다."
  else
    bad "등록된 것이 ${got}/${AS_NEW_TESTS_WANT} 개다 — 🔴 **빠진 것은 오류 없이 조용히 안 돈다**"
    doubt
  fi
  # ── ② 바뀐 시험 중 **새것이 아닌 것**이 아직 적혀 있는가 (git 에서 뽑는다)
  # 🔴🔴 **새 파일을 가릴 때 AS_NEW_TESTS 표를 쓰지 않는다.** 그 표는 **목록 파일에
  #    적힌 꼴**을 들고 있어서 대괄호 자리가 **별표**다(그 표의 머리말). git 이 주는
  #    것은 **실제 경로(대괄호)**라 둘이 안 맞고, 그러면 그 한 장이 「새것이 아닌 것」
  #    으로 흘러들어 **멀쩡한 판에서 seen 이 44, got 이 43** 이 된다 — 처음 쓸 때
  #    실제로 그 ✗ 가 날 자리였다. 🔴 **가리는 쪽도 git 에서 뽑는다.**
  got=0; seen=0
  OLDT=$(printf '%s\n' "$AS_LIST" | grep -E '\.test\.tsx?$' || true)
  NEWT=$(git -C "$ASD" diff --diff-filter=A --name-only "$(repo_base as)..main" 2>/dev/null | tr -d '\r' | grep -E '\.test\.tsx?$' || true)
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    # 새 파일이면 건너뛴다 — 위 ① 이 이미 물었다.
    # 🔴 **grep -q 를 if 에 바로 물리지 않는다**(함정 ⑦) — **세어서 담는다.**
    isnew=$(printf '%s\n' "$NEWT" | grep -cFx -- "$t" || true)
    isnum "${isnew:-}" || isnew=0
    [ "${isnew}" -ge 1 ] && continue
    seen=$((seen+1))
    n=$(printf '%s\n' "$TL" | grep -cFx -- "$t" || true)
    if [ "${n:-0}" -ge 1 ] 2>/dev/null; then got=$((got+1)); else printf '        🔴 안 적힘 %s\n' "$t"; fi
  done <<ENDOLDT
$OLDT
ENDOLDT
  say "바뀐 시험 중 **새것이 아닌 것** — 본 것 ${seen} · 적혀 있는 것 ${got} (기대 $AS_OLD_TESTS_WANT · $AS_OLD_TESTS_WANT)"
  if [ "$seen" = "$AS_OLD_TESTS_WANT" ] && [ "$got" = "$AS_OLD_TESTS_WANT" ]; then
    ok "앞선 판들이 등록한 ${AS_OLD_TESTS_WANT}장이 **아직 다 적혀 있다** (등록을 지운 사람이 없다)"
  else
    bad "본 것 ${seen} · 적혀 있는 것 ${got} 다 — ${AS_OLD_TESTS_WANT} 을 기대했다"
    say "      🔴 **본 것이 0 이면 그 고리가 안 돈 것**입니다 — 86 − 43 = 43 이 기대값입니다."
    doubt
  fi
fi
n=0; tlseen=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  tlseen=$((tlseen+1))
  [ -f "$ASD/$f" ] && n=$((n+1)) || printf '        없음 %s\n' "$f"
done <<ENDASL
$(rows_of "$AS_TESTLIST_FILES")
ENDASL
say "목록 파일 — 본 것 ${tlseen} · 있는 것 ${n} (기대 $AS_TESTLIST_FILES_WANT)"
if [ "$tlseen" = "$AS_TESTLIST_FILES_WANT" ] && [ "$n" = "$AS_TESTLIST_FILES_WANT" ]; then
  ok "A/S 시험 목록 파일 ${AS_TESTLIST_FILES_WANT}장이 다 있다"
else
  bad "A/S 목록 파일이 ${n}/${AS_TESTLIST_FILES_WANT} 장이다"
fi
say ""
say "   ㄴ) 🔴 포털 — **package.json 의 「test」 줄에 경로를 하나씩 나열**합니다."
say "      🔴 **글롭 방식으로 착각해 이 절을 빼면** 포털의 시험 등록이 아무 검사도"
say "         안 받습니다. [실측] 기준 ${AUTH_TESTPATHS_WAS}개 → 지금 ${AUTH_TESTPATHS_WANT}개 (새 시험 ${AUTH_NEW_TESTS_WANT}장)."
atb=$(git -C "$AUTHD" show "$(repo_base auth):package.json" 2>/dev/null </dev/null | count_test_paths)
atn=$(count_test_paths < "$AUTHD/package.json")
say "포털 test 줄의 경로 수 — 기준 ${atb:-?} → 지금 ${atn:-?} (적어 둔 값 $AUTH_TESTPATHS_WAS → $AUTH_TESTPATHS_WANT)"
if ! isnum "${atb:-}" || [ "${atb:-0}" -lt 40 ]; then
  bad "포털의 기준판 test 줄을 ${atb:-못 읽음}개밖에 못 읽었다 — 🔴 **빈 결과는 삼켜진 오류일 수 있다**"
elif [ "${atn:-0}" -lt "${atb:-0}" ] 2>/dev/null; then
  bad "포털의 등록 경로가 ${atb} → ${atn} 로 **줄었다** — 누가 시험 등록을 **지웠다**"
  doubt
elif [ "${atb:-x}" = "$AUTH_TESTPATHS_WAS" ] && [ "${atn:-x}" = "$AUTH_TESTPATHS_WANT" ]; then
  ok "포털의 등록 경로가 ${AUTH_TESTPATHS_WAS} → ${AUTH_TESTPATHS_WANT} 다 (새 시험이 0장이라 안 느는 것이 맞다)"
else
  note "포털의 등록 경로가 ${atb:-?} → ${atn:-?} 다 — $AUTH_TESTPATHS_WAS → $AUTH_TESTPATHS_WANT 를 기대했다. 사람이 보세요"
fi
ant=$(git -C "$AUTHD" diff --diff-filter=A --name-only "$(repo_base auth)..main" 2>/dev/null | tr -d '\r' | grep -cE '\.test\.tsx?$' || true)
say "포털에서 **새로 생긴** 시험 파일 ${ant:-?}개 (기대 $AUTH_NEW_TESTS_WANT)"
[ "${ant:-x}" = "$AUTH_NEW_TESTS_WANT" ] && ok "포털의 새 시험이 ${AUTH_NEW_TESTS_WANT}개다 (등록이 안 늘어야 맞다)" \
  || note "포털의 새 시험이 ${ant:-?}개다 — $AUTH_NEW_TESTS_WANT 을 기대했다. 사람이 보세요"
# 🔴 바뀐 둘이 아직 그 줄에 적혀 있는가 — 지워졌으면 조용히 안 돈다.
ATL=$(sed -n 's/.*"test": "\(.*\)",/\1/p' "$AUTHD/package.json" | tr ' ' '\n')
got=0; seen=0
while IFS= read -r t; do
  [ -n "$t" ] || continue
  seen=$((seen+1))
  n=$(printf '%s\n' "$ATL" | grep -cFx -- "$t" || true)
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then got=$((got+1)); else printf '        🔴 안 적힘 %s\n' "$t"; fi
done <<ENDATT
$(rows_of "$AUTH_TOUCHED_TESTS")
ENDATT
aprobe=$(printf '%s\n' "$ATL" | grep -cFx -- "$PROBE_MISS" || true)
say "포털의 바뀐 시험 — 본 것 ${seen} · 적혀 있는 것 ${got} (기대 $AUTH_TOUCHED_TESTS_WANT) · 없는 경로 ${aprobe:-?}(기대 0)"
if [ "${aprobe:-1}" != "0" ]; then
  bad "포털 — **없는 경로가 적혀 있다고 나왔다**. 줄 전체 일치가 깨졌다"
elif [ "$seen" = "$AUTH_TOUCHED_TESTS_WANT" ] && [ "$got" = "$AUTH_TOUCHED_TESTS_WANT" ]; then
  ok "포털의 바뀐 시험 ${AUTH_TOUCHED_TESTS_WANT}장이 **아직 test 줄에 적혀 있다**"
else
  bad "포털의 바뀐 시험이 ${got}/${AUTH_TOUCHED_TESTS_WANT} 장만 적혀 있다 — 빠진 것은 조용히 안 돈다"
  doubt
fi

# ── 6. 태그 ───────────────────────────────────────────────────────────
#   🔴 **기대값이 모드마다 뒤집힌다.**
#      --check·--go : 아직 **없어야** 한다(같은 태그를 덮으면 되돌릴 판이 사라진다)
#      --verify     : **있어야** 한다(이미 구운 것을 다시 재는 모드다)
if [ "$MODE" = "--verify" ]; then
  step "6. 태그가 **있나** — --verify 는 이미 구운 것을 다시 재는 모드다"
else
  step "6. 태그가 이미 있나 — 같은 태그를 다시 구우면 **되돌릴 판이 사라진다**"
fi
IMG_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  TAG=$(field "$r" 3)
  IMG_SEEN=$((IMG_SEEN+1))
  if docker image inspect "$TAG" >/dev/null 2>&1; then
    if [ "$MODE" = "--verify" ]; then ok "$TAG 가 있다 (이것을 다시 잰다)"
    else
      bad "$TAG 가 **이미 있다** — 다른 판을 그 태그로 덮으면 되돌릴 것이 없어진다"
      say "      🔵 이미 구우셨다면 **다시 굽지 말고** --verify 로 그것을 재세요:"
      say "         & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./71-build.sh --verify"
      say "      → 정말 지우려면: docker image rm $TAG"
    fi
  else
    if [ "$MODE" = "--verify" ]; then bad "$TAG 가 **없다** — --verify 는 구운 뒤에 쓰는 모드다"
    else ok "$TAG 가 아직 없다 (새로 굽는다)"; fi
  fi
done <<ENDIMG1
$(rows_of "$IMAGES")
ENDIMG1
[ "$IMG_SEEN" = "$HOWMANY" ] && ok "태그 ${HOWMANY}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "태그를 ${IMG_SEEN}개만 봤다 — ${HOWMANY}개를 기대했다. IMAGES 표가 깨졌다"
say ""
say "🔵 되돌릴 옛 판이 개발 PC 에 있는지도 찍습니다(없어도 막지 않습니다 — NAS 에 있으면 됩니다)."
OLD_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  OLD_SEEN=$((OLD_SEEN+1))
  PT=$(field "$r" 5)
  OLDTAG=$(printf '%s' "${PT%.tar}" | sed 's/-\([0-9][0-9.]*\)$/:\1/')
  if docker image inspect "$OLDTAG" >/dev/null 2>&1; then say "옛 판 있음 $OLDTAG"
  else say "옛 판 없음 $OLDTAG (개발 PC 에만 없는 것일 수 있습니다)"; fi
done <<ENDIMG2
$(rows_of "$IMAGES")
ENDIMG2
[ "$OLD_SEEN" = "$HOWMANY" ] && ok "옛 판 ${HOWMANY}개를 다 찍었다" \
  || bad "옛 판을 ${OLD_SEEN}개만 찍었다"

# ── 7. 산출물을 둘 자리 + 🔴 dev 서버 ────────────────────────────────
step "7. 산출물을 둘 자리"
if [ -d "$OUT" ]; then
  n=$(ls -1 "$OUT" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$MODE" = "--verify" ]; then
    say "$OUT 안 ${n}개 (--verify 는 **이미 구운 뒤**라 차 있는 것이 정상입니다)"
    ls -1 "$OUT" 2>/dev/null | head -15 | sed 's/^/        /'
    if [ "${n:-0}" -ge 1 ] 2>/dev/null; then ok "산출물 폴더에 파일이 ${n}개 있다"
    else bad "산출물 폴더가 비었다 — --verify 는 구운 뒤에 쓰는 모드다"; fi
  elif [ "${n:-0}" = "0" ]; then ok "$OUT 가 있고 비어 있다"
  else
    note "$OUT 에 이미 파일이 ${n}개 있다 — 아래를 보세요"
    ls -1 "$OUT" | head -15 | sed 's/^/        /'
    say "      🔴 **옛 tar 가 섞여 있으면 보낼 때 헷갈립니다.** 보내기 전에 이 폴더에서"
    say "         옛 tar 를 먼저 지우세요(쉰여섯째·쉰일곱째가 **두 판 연속** 그 자리를 밟았습니다)."
    say "      🔴 **이번 판은 묶음이 있습니다**(as-migrations.tar.gz · ${AS_SQL_WANT}장). 여기 보이는"
    say "         묶음이 **옛 판의 것**일 수 있습니다 — --go 가 **지우고 다시 만듭니다.**"
  fi
else
  say "$OUT 가 아직 없다 — --go 때 만든다 (--check 는 아무것도 안 만든다)"
  ok "산출물 자리를 쓸 수 있다"
fi
# 🔴 7-ㄴ. dev 서버 — 🔵 **떠 있는 것이 정상이다**
say ""
say "── 7-ㄴ. dev 서버 — **막지는 않는다. 값으로 찍는다**"
say "🔵 docker build 는 dev 서버를 안 내려도 됩니다(.dockerignore 가 .next 를 막습니다 — 5-ㄴ)."
say "🔵 **A/S(3000) · 포털(3100) · DB 둘(5442·5444)이 떠 있는 것이 정상입니다** — 🔴 **끄지 마세요.**"
say "🔴 그래도 찍는 까닭: 그 포트가 떠 있으면 **호스트의 npm run build** 가 .next 를"
say "   두고 다투고, 그 탓에 난 tsc 오류를 코드 탓으로 오해한 적이 있습니다."
say "   🔵 이 파일은 **호스트의 npm run build 를 한 번도 안 부릅니다** — docker build 만 합니다."
PORT_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  PORT_SEEN=$((PORT_SEEN+1))
  pn=$(field "$r" 6); nm=$(field "$r" 3)
  if netstat -an 2>/dev/null | grep -q "[:.]$pn[^0-9].*LISTEN"; then
    say "$nm dev 서버 ($pn) — **떠 있다** (🔵 정상입니다)"
  else
    say "$nm dev 서버 ($pn) — 안 떠 있다"
  fi
done <<ENDPORT
$(rows_of "$REPOS")
ENDPORT
for pn in $DB_PORTS; do
  PORT_SEEN=$((PORT_SEEN+1))
  if netstat -an 2>/dev/null | grep -q "[:.]$pn[^0-9].*LISTEN"; then
    say "개발 DB ($pn) — **떠 있다** (🔵 정상입니다)"
  else
    say "개발 DB ($pn) — 안 떠 있다"
  fi
done
[ "$PORT_SEEN" = "4" ] && ok "포트 넷을 다 봤다" || bad "포트를 ${PORT_SEEN}개만 봤다 — 4개를 기대했다"
say "🔴 **next dev 는 포트가 차면 조용히 옆으로 비켜섭니다** — 위 수만으로 「안 떠 있다」를"
say "   단정하지 마세요. 이 줄은 판정에 쓰이지 않습니다."

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
}

# ══════════════════════════════════════════════════════════════════════
# ══ 이미지 안을 재는 길 — 🔴 **갈래마다 · 집마다 다른 것을 잰다** ═════
# ══════════════════════════════════════════════════════════════════════
#   🔴 앱과 도구는 담긴 것이 다르다 — 앱은 **번들**, 도구는 **소스 그대로**다.
#   🔴 그리고 **A/S 와 포털이 drizzle 에서 반대다.** 한 잣대로 재면 가짜 ✗ 가 난다.
IMGFAIL=0
INSIDE_RAN=0
dock() { dockr run --rm --entrypoint sh "$@" 2>/dev/null | tr -d '\r'; }

# 🔴 목록 하나를 이미지 안에서 한 장씩 묻는다 — **없는 경로 하나를 함께** 묻는다.
#    🔴 set -f 로 글롭을 끈다. **이번 A/S 목록에는 괄호·대괄호가 든 경로가 셋 있다**
#       — set -f 가 없으면 그 줄이 파일 이름 확장으로 읽혀 **없는 것으로 나온다.**
ask_files() { # 1 태그 2 목록(줄바꿈) 3 기대 수 4 사람이 부르는 말
  local v got seen probe
  v=$(dockr run --rm -e DSS_FILES="$2" -e DSS_MISS="$PROBE_MISS" --entrypoint sh "$1" -c \
    'set -f; printf "%s\n%s\n" "$DSS_FILES" "$DSS_MISS" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/        /'
  seen=$(printf '%s\n' "$v" | grep -c '^\(yes\|no \)' || true)
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  probe=$(printf '%s\n' "$v" | grep -c "^no  $PROBE_MISS" || true)
  printf '      %s — 본 것 %s · 있는 것 %s (기대 %s · %s) · 없는 경로가 no 로 나왔나 %s(기대 1)\n' \
    "$4" "${seen:-0}" "${got:-0}" "$(( $3 + 1 ))" "$3" "${probe:-0}"
  if [ "${probe:-0}" != "1" ]; then
    printf '  ✗ **없는 경로가 no 로 안 나왔다** — 「무조건 yes」인 검사다. 위 yes 도 못 믿는다\n'; IMGFAIL=1
  elif [ "${seen:-0}" = "$(( $3 + 1 ))" ] && [ "${got:-0}" = "$3" ]; then
    printf '  ✓ %s %s장이 다 담겼다 (표본이 비지 않았다)\n' "$4" "$3"
  else
    printf '  ✗ 본 것 %s · 있는 것 %s 다 — %s 를 기대했다\n' "${seen:-0}" "${got:-0}" "$3"; IMGFAIL=1
    printf '%s\n' "      🔴 본 것이 모자라면 **목록을 넘기는 길이 끊긴 것**(글롭 함정)이고,"
    printf '%s\n' "         있는 것만 모자라면 **옛 소스가 담긴 이미지**입니다."
  fi
}

# 🔴 번들 안에서 글자 하나를 센다 — **.next/server 와 .next/static 을 둘 다** 본다.
#    🔵 넷째 인자는 **판정에 안 쓰는 곁들이 값**이다.
bundle_mark() { # 1 태그 2 글자 3 사람이 부르는 말 4 (선택) 곁들여 찍을 글자
  local v s t d ds dt
  v=$(dockr run --rm -e M="$2" --entrypoint sh "$1" -c \
    'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  s=$(printf '%s' "$v" | awk '{print $1}'); t=$(printf '%s' "$v" | awk '{print $2}')
  printf '      [%s] — .next/server %s개 · .next/static %s개 (🔴 합이 1 이상이어야 한다)\n' "$2" "${s:-?}" "${t:-?}"
  if [ -n "${4:-}" ]; then
    d=$(dockr run --rm -e M="$4" --entrypoint sh "$1" -c \
      'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
    ds=$(printf '%s' "$d" | awk '{print $1}'); dt=$(printf '%s' "$d" | awk '{print $2}')
    printf '      [%s] — server %s개 · static %s개 (🔵 **판정에 안 쓰는 곁들이 값**)\n' "$4" "${ds:-?}" "${dt:-?}"
  fi
  if isnum "${s:-}" && isnum "${t:-}" && [ "$((s + t))" -ge 1 ]; then
    printf '  ✓ %s\n' "$3"
  else
    printf '  ✗ %s — **없다.** 올리지 마세요\n' "$3"; IMGFAIL=1
    printf '%s\n' "      🔵 **검사 자신도 의심하세요.** 이 파일의 열여덟 표식은 2026-11-25 에"
    printf '%s\n' "         **구운 번들 안에서 한 번씩 세어 보았습니다**(판정에 쓰는 열다섯이 전부 ≥1)."
    printf '%s\n' "         🔴 그래도 0 이 나왔다면 **옛 이미지를 구웠거나 표식을 바꾼 것**입니다."
    printf '%s\n' "      🔴 **그 글자가 한글이면 1-ㄷ 절부터 보세요** — ASCII 기능 표식이 ✓ 인데"
    printf '%s\n' "         한글만 0 이면 그것은 **검사 탓**입니다(이미지를 되돌리지 마세요)."
    printf '%s\n' "      🔴 **코드 줄에서 따온 글자는 번들에 안 남습니다** — 지역 이름은 minify 가"
    printf '%s\n' "         갈아 치웁니다(part.drawingNo, part.note 가 그 실물이었습니다)."
    if [ -n "${4:-}" ] && isnum "${ds:-}" && isnum "${dt:-}" && [ "$((ds + dt))" -ge 1 ]; then
      printf '%s\n' "      🔴 **곁들이 글자는 1 이상입니다** — 즉 이미지가 통째로 비어 있지는 않습니다."
      printf '%s\n' "         곁들이는 **스키마의 문자열 리터럴**이고 판정 글자는 **객체의 칸 이름**이라,"
      printf '%s\n' "         이 꼴은 **앱 코드가 안 들어왔거나 minify 가 칸 이름까지 줄인 것**입니다."
      printf '%s\n' "         🔵 이미지를 다시 굽기 전에 **이 검사를 먼저 보세요** — 다른 글자로"
      printf '%s\n' "            재면 지문이 안 바뀝니다(71-build.sh --verify)."
    else
      printf '%s\n' "      🔴 **곁들이 글자도 0 입니다** — 옛 소스를 구웠거나, 경로 번역이 살아"
      printf '%s\n' "         있습니다(1-ㄴ 절이 ✓ 였는지 보세요)."
    fi
  fi
}

# 🔵 **판정에 안 쓰고 찍기만 하는 곁들이** — 포털 앱 번들에서 쓴다.
#    🔴 포털에는 **가를 글자가 없다**(머리말). 그래서 ✗ 를 안 내고 값만 남긴다 —
#       다음 판이 「그때 번들에 TONE_COUNT 가 남았나」를 이 로그에서 읽을 수 있다.
bundle_note() { # 1 태그 2 글자 3 사람이 부르는 말
  local v s t
  v=$(dockr run --rm -e M="$2" --entrypoint sh "$1" -c \
    'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  s=$(printf '%s' "$v" | awk '{print $1}'); t=$(printf '%s' "$v" | awk '{print $2}')
  printf '      [%s] — server %s개 · static %s개 (🔵 **판정에 안 씀** — %s)\n' "$2" "${s:-?}" "${t:-?}" "$3"
}

# 🔴 npm 명령을 **값으로 받아 본다** — Missing script 와 Cannot find module 을 가른다.
npm_probe() { # 1 태그 2 명령
  local v
  v=$(dockr run --rm --entrypoint sh "$1" -c "cd /app && npm run $2 2>&1 | head -40" 2>&1 | tr -d '\r')
  if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
    printf '  ✗ npm run %s — **Missing script** (41번과 같은 실패다)\n' "$2"; IMGFAIL=1
    printf '%s\n' "$v" | head -15 | sed 's/^/        /'
  elif printf '%s' "$v" | grep -qE 'Cannot find module|ERR_MODULE_NOT_FOUND|Cannot find package'; then
    printf '  ✗ npm run %s 가 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다\n' "$2"; IMGFAIL=1
    printf '%s\n' "$v" | head -15 | sed 's/^/        /'
  elif printf '%s' "$v" | grep -qiE 'DATABASE_URL|환경변수|connection string|ECONNREFUSED|getaddrinfo|AUTH_|PORTAL_'; then
    printf '  ✓ npm run %s 가 import 까지 갔고 바깥에는 안 닿았다 (기대한 답)\n' "$2"
  else
    printf '  ⚠️ npm run %s 의 답이 기대와 다르다 — 아래 15줄을 사람이 보세요\n' "$2"
    printf '%s\n' "$v" | head -15 | sed 's/^/        /'
  fi
}

# ══════════════════════════════════════════════════════════════════════
# ══ 🔴 이미지 **안**을 세는 함수 — 굽기와 --verify 가 **함께 쓴다** ══
# ══════════════════════════════════════════════════════════════════════
#   🔴 **두 벌로 적지 않는다.** 두 벌이면 한쪽만 고쳐져 어긋난다.
#   🔵 바깥에 IMGFAIL 을 남긴다(local 로 가리지 않는다).
inside_check() { # 1 열쇠(as|astools|auth|authtools) 2 태그 3 타깃(-=앱)
  # 🔴 **몇 번 실제로 돌았는지 센다.** [실측 2026-11-18] 이 함수를 쓰는 자리보다
  #    **뒤에** 정의해 두었더니 「command not found」만 한 줄 찍히고 --verify 가
  #    **✗ 0 으로 통과**했다. 아무것도 안 재는 ✓ 의 실물이다.
  INSIDE_RAN=$((INSIDE_RAN + 1))
  KEY=$1; TAG=$2; TGT=$3
  IMGFAIL=0
  RK=$(repo_key_of "$KEY")
  PR=$(row_by_key "$PUBLIC_WANT" "$RK")
  PW=$(field "$PR" 2); PN_WANT=$(field "$PR" 3)
  if [ "$TGT" = "-" ]; then
    # ── 앱 이미지 (번들이다 — 소스가 없다)
    printf '\n    ── %s 안을 센다 (**번들**이다 — 소스가 없다)\n' "$TAG"
    v=$(dock "$TAG" -c "test -f /app/server.js && echo yes || echo no")
    printf '      /app/server.js: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ runner 스테이지가 맞다 (node server.js 를 안다)\n'
    else printf '  ✗ /app/server.js 가 없다 — **runner 가 아닌 것을 구웠다.** 올리지 마세요\n'; IMGFAIL=1; fi
    v=$(dock "$TAG" -c 'if [ -d /app/public ]; then printf "yes %s\n" "$(ls -1 /app/public 2>/dev/null | wc -l)"; else printf "no 0\n"; fi')
    pst=$(printf '%s' "$v" | awk '{print $1}'); pn=$(printf '%s' "$v" | awk '{print $2}')
    printf '      /app/public: %s (파일 %s개 · 기대 %s · 참고 %s개)\n' "${pst:-못 읽음}" "${pn:-?}" "${PW:-?}" "${PN_WANT:-?}"
    if [ "${pst:-}" = "${PW:-}" ] && [ "${pn:-0}" -ge 1 ] 2>/dev/null; then
      printf '  ✓ public/ 이 담겼다 (%s개)\n' "$pn"
    elif [ "${pst:-}" = "${PW:-}" ]; then
      printf '  ✗ public/ 은 있는데 **비어 있다** — %s개를 기대했다\n' "${PN_WANT:-?}"; IMGFAIL=1
    else
      printf '  ✗ /app/public 이 %s 다 — %s 를 기대했다\n' "${pst:-못 읽음}" "${PW:-?}"; IMGFAIL=1
      printf '%s\n' "      🔵 없으면 정적 파일이 404 가 됩니다(새 사이트에서 걸리는 셋 중 하나)."
    fi
    # 🔴 **표식을 APPMARKS 표에서 그 집 것만 꺼내 돈다** — 집마다 다르다.
    #    🔴 A/S 는 기능 셋 + 뒷걸음 아홉, 포털은 기능 0 + 뒷걸음 셋이다.
    SIDE=$(rows_of "$APPMARKS" | while IFS='|' read -r R K M N; do
             [ "$R" = "$RK" ] && [ "$K" = "side" ] && printf '%s\n' "$M"; done | head -1)
    MKRAN=0
    while IFS='|' read -r R K M N; do
      [ -n "${R:-}" ] || continue
      [ "$R" = "$RK" ] || continue
      case "$K" in
        feature)
          MKRAN=$((MKRAN+1))
          bundle_mark "$TAG" "$M" "번들에 **이번 판의 글자**가 있다 ($N)" "${SIDE:-}"
          ;;
        keep)
          MKRAN=$((MKRAN+1))
          bundle_mark "$TAG" "$M" "지난 판이 올린 글자가 그대로 있다 — 뒷걸음친 나무가 아니다 ($N)"
          ;;
        side)
          bundle_note "$TAG" "$M" "$N"
          ;;
      esac
    done <<ENDBM
$(rows_of "$APPMARKS")
ENDBM
    printf '      이 집에서 **판정에 쓴 표식** %s개\n' "$MKRAN"
    if [ "$RK" = "as" ]; then
      if [ "$MKRAN" = "12" ]; then printf '  ✓ A/S 번들 표식 12개(기능 3 + 뒷걸음 9)를 다 돌았다\n'
      else printf '  ✗ A/S 번들 표식을 %s개만 돌았다 — 12개를 기대했다. APPMARKS 표가 깨졌다\n' "$MKRAN"; IMGFAIL=1; fi
    else
      if [ "$MKRAN" = "3" ]; then
        printf '  ✓ 포털 번들 표식 3개(뒷걸음만)를 다 돌았다\n'
        printf '%s\n' "      🔴 **포털에는 기능 표식이 없습니다** — 이번 포털 커밋이 더한 코드에"
        printf '%s\n' "         **새 문자열 리터럴이 한 개도 없습니다**(머리말). 포털의 새 코드는"
        printf '%s\n' "         **도구 이미지**에서 TONE_COUNT 로 가립니다 — 62번이 계측기에서 한 그대로입니다."
      else printf '  ✗ 포털 번들 표식을 %s개만 돌았다 — 3개를 기대했다. APPMARKS 표가 깨졌다\n' "$MKRAN"; IMGFAIL=1; fi
    fi
  else
    # ── 도구 이미지 (소스가 글자 그대로 있다)
    printf '\n    ── %s 안을 센다 (**소스가 글자 그대로** 있다)\n' "$TAG"
    v=$(dock "$TAG" -c "test -f /app/package.json && echo yes || echo no")
    printf '      /app/package.json: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tools 스테이지가 맞다\n'
    else printf '  ✗ /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다\n'; IMGFAIL=1; fi
    v=$(dock "$TAG" -c "test -d /app/node_modules/tsx && echo yes || echo no")
    printf '      /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tsx 가 있다\n'
    else printf '  ✗ tsx 가 없다 — tsx 로 도는 도구가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
    # 🔴 **마지막 커밋 표식** — 경로를 **상대로 넘기고** /app/ 를 컨테이너 안에서 붙인다.
    #    그리고 yes/no 가 아니라 **센 줄 수**를 받는다 — 0 과 「못 읽음」을 가른다.
    TR=$(row_by_key "$TOOLMARKS" "$KEY")
    TMK=$(field "$TR" 2); TMF=$(field "$TR" 3); TMW=$(field "$TR" 5)
    if [ -z "${TMF:-}" ]; then
      printf '  ✗ %s 의 마지막 커밋 표식이 TOOLMARKS 표에 **없다** — 표가 깨졌다\n' "$KEY"; IMGFAIL=1
    else
      v=$(dockr run --rm -e M="$TMK" -e F="$TMF" --entrypoint sh "$TAG" -c \
        'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s\n" "$(grep -cF -- "$M" "$p")"; else printf "missing 0\n"; fi' 2>/dev/null | tr -d '\r')
      tst=$(printf '%s' "$v" | awk '{print $1}'); tn=$(printf '%s' "$v" | awk '{print $2}')
      printf '      마지막 커밋 표식 [%s] in %s — 파일 %s · 그 글자 %s줄 (기대 hit · %s)\n' \
        "$TMK" "$TMF" "${tst:-못 읽음}" "${tn:-?}" "${TMW:-1}"
      if [ "${tst:-}" = "hit" ] && [ "${tn:-0}" -ge 1 ] 2>/dev/null; then
        printf '  ✓ **마지막 커밋이 담겼다** (%s줄)\n' "$tn"
        printf '%s\n' "      🔵 앱 이미지는 **같은 작업본에서 같은 실행으로** 굽습니다 — 2절이 그"
        printf '%s\n' "         작업본의 HEAD 와 미커밋 0 을 확인했으므로 앱에도 들어 있습니다."
      elif [ "${tst:-}" = "hit" ]; then
        printf '  ✗ 그 파일은 있는데 마지막 커밋의 글자가 **0줄**이다 — 커밋 하나가 빠진 판이다\n'; IMGFAIL=1
      elif [ "${tst:-}" = "missing" ]; then
        printf '  ✗ 그 파일 자체가 이미지에 없다 — src/ 가 온전히 안 담겼다\n'; IMGFAIL=1
        printf '%s\n' "      🔵 **경로 번역부터 의심하세요** — 1-ㄴ 절이 ✓ 였는지 보세요."
      else
        printf '  ✗ 못 읽었다 (받은 값 [%s])\n' "${v:-}"; IMGFAIL=1
      fi
    fi
    # ── 🔴 여기부터 **집마다 갈린다**
    case "$KEY" in
      astools)
        ask_files "$TAG" "$AS_KEY_FILES" "$AS_KEY_FILES_WANT" "A/S 의 핵심 파일"
        printf '%s\n' "      🔵 그 스무 장 중 **셋이 괄호·대괄호가 든 경로**입니다 — 글롭 함정의 실물입니다."
        # 🔵 **ㄷ 잣대가 살아 있는 자리** — import 하는 scripts/ 둘이 이미지 안에도 있는가.
        v=$(dockr run --rm --entrypoint sh "$TAG" -c \
          'set -f; n=0; for f in scripts/lib/delivered-date-sync-survey.ts scripts/lib/requested-due-date-sync-survey.ts; do [ -f "/app/$f" ] && n=$((n+1)); done; echo "n=$n"' 2>/dev/null | tr -d '\r')
        g=$(printf '%s' "$v" | sed -n 's/^n=//p')
        printf '      ㄷ 잣대의 scripts/ 둘: %s개 (기대 2)\n' "${g:-?}"
        if [ "${g:-x}" = "2" ]; then printf '  ✓ 그 둘이 이미지에 담겼다 (scripts/ 가 온전히 담겼다)\n'
        else printf '  ✗ 그 둘이 %s/2 개다 — scripts/ 가 온전히 안 담겼다\n' "${g:-?}"; IMGFAIL=1; fi
        # 🔴 A/S 는 drizzle 을 **안 담아야** 한다 — 볼륨이 붙는 자리다.
        v=$(dock "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
        printf '      /app/drizzle 안 .sql: %s개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)\n' "${v:-?}"
        if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ drizzle/ 이 비어 있다 (🔴 그래서 **묶음을 보내야** %s → %s 가 된다)\n' "$AS_SQL_WAS" "$AS_SQL_WANT"
        else printf '  ✗ drizzle/ 에 .sql 이 들었다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다\n'; IMGFAIL=1; fi
        # 🔴 **공용 스키마가 담겼는가** — 핀이 맞아도 **빈 서브모듈이 담길 수 있다**.
        v=$(dock "$TAG" -c 'd=/app/vendor/dss-core/src/schema; if [ -d "$d" ]; then echo "miss=0"; echo "n=$(ls -1 "$d" | wc -l)"; else echo "miss=1"; fi')
        v=$(printf '%s\n' "$v" | tr -d ' ')
        printf '%s\n' "$v" | sed 's/^/        /'
        c=$(printf '%s\n' "$v" | sed -n 's/^miss=//p'); g=$(printf '%s\n' "$v" | sed -n 's/^n=//p')
        if [ "${c:-1}" != "0" ]; then printf '  ✗ 이미지에 vendor/dss-core 의 스키마 폴더가 **없다** — Cannot find module 이 난다\n'; IMGFAIL=1
        elif [ "${g:-0}" -ge 1 ] 2>/dev/null; then printf '  ✓ 공용 스키마가 담겼다 (파일 %s개)\n' "$g"
        else printf '  ✗ 공용 스키마 폴더가 비었다 — **빈 서브모듈이 담겼다.** 올리지 마세요\n'; IMGFAIL=1; fi
        # 🔴 **일곱으로 늘렸다** — 앞의 셋은 뒷걸음(지난 판들이 올린 것), 뒤의 넷은
        #    **이번 판이 더한 칸**이다. 넷 중 하나라도 없으면 그 갈래가 안 담긴 것이다.
        v=$(dock "$TAG" -c 'for pair in "portal_approval_delegations /app/vendor/dss-core/src/schema/portal-approval-delegations.ts" "portal-approval-delegations /app/vendor/dss-core/src/schema/index.ts" "fault_tags /app/vendor/dss-core/src/schema/repair-case-flowcharts.ts" "confirmed_at /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "confirmed_by /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "share_doc_relative_path /app/vendor/dss-core/src/schema/procedure-template-nodes.ts" "share_doc_relative_path /app/vendor/dss-core/src/schema/repair-case-flowchart-nodes.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1 $2"; fi; done')
        printf '%s\n' "$v" | sed 's/^/        /'
        g=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
        if [ "${g:-0}" = "7" ]; then
          printf '  ✓ **공용 스키마가 일곱 다 담겼다** (지난 판들의 셋 + 🔴 **이번 판의 칸 넷**)\n'
        else
          printf '  ✗ 일곱 중 %s개만 있다 — **옛 공용 스키마가 담겼다.** 올리지 마세요\n' "${g:-0}"; IMGFAIL=1
          printf '%s\n' "      🔴 뒤의 넷만 no 면 **서브모듈 핀이 옛 것**입니다(3-ㄱ 을 보세요)."
        fi
        # 🔵 양식이 이미지에 안 들어갔는가 — 들어갔으면 도장과 계좌번호가 구워진 것이다.
        v=$(dock "$TAG" -c "ls /templates 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
        printf '      /templates 안 파일: %s개 (기대 0 — 양식은 볼륨으로 붙는다)\n' "${v:-?}"
        if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ 양식이 이미지에 안 들어갔다\n'
        else printf '  ✗ 이미지 안에 /templates 가 %s개 있다 — 도장·계좌번호가 구워졌다. 사람이 보세요\n' "${v:-?}"; IMGFAIL=1; fi
        v=$(dock "$TAG" -c "test -d /app/node_modules/drizzle-kit && echo yes || echo no")
        printf '      /app/node_modules/drizzle-kit: %s (기대 yes)\n' "${v:-못 읽음}"
        if [ "${v:-}" = "yes" ]; then printf '  ✓ drizzle-kit 이 있다 (db:preflight 가 이것으로 돈다)\n'
        else printf '  ✗ drizzle-kit 이 없다 — **db:preflight 가 그 자리에서 죽는다.** 올리지 마세요\n'; IMGFAIL=1; fi
        npm_probe "$TAG" db:preflight
        npm_probe "$TAG" db:migrate
        printf '%s\n' "      🔴 **이번 판은 db:migrate 가 실제로 2건을 올립니다**(70번은 0건이었습니다)."
        printf '%s\n' "         🔵 여기서 재는 것은 「그 명령이 import 까지 가는가」뿐입니다 — 개발"
        printf '%s\n' "            PC 에서는 운영 DB 에 못 닿으므로 DATABASE_URL 쪽 답이 기대한 답입니다."
        printf '%s\n' "         🔴 **db:migrate 는 오류를 삼키고 exit 1 만 남기는 성질이 있습니다** —"
        printf '%s\n' "            그래서 71-deploy.sh 는 적용 뒤 **수를 다시 세어** 134 인지 봅니다."
        ;;
      authtools)
        ask_files "$TAG" "$AUTH_KEY_FILES" "$AUTH_KEY_FILES_WANT" "포털의 핵심 파일"
        # 🔴 포털은 drizzle 을 **담아야** 한다 — 11장이 이미지 안에서 돈다.
        v=$(dock "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
        printf '      /app/drizzle 안 .sql: %s개 (기대 %s — 🔴 **포털은 이미지 안에서 돈다**)\n' "${v:-?}" "$AUTH_SQL_WANT"
        if [ "${v:-x}" = "$AUTH_SQL_WANT" ]; then
          printf '  ✓ 포털 마이그레이션 %s장이 이미지에 구워졌다\n' "$AUTH_SQL_WANT"
          printf '%s\n' "      🔵 **이번 판은 올릴 것이 0건입니다** — 그래도 수가 맞아야 합니다. 모자라면"
          printf '%s\n' "         옛 판이 운영에서 db:migrate 를 돌릴 때 **되감기는 판**이 됩니다."
        else printf '  ✗ .sql 이 %s장이다 — %s 을 기대했다\n' "${v:-?}" "$AUTH_SQL_WANT"; IMGFAIL=1; fi
        v=$(dock "$TAG" -c "grep -c 'idx' /app/drizzle/meta/_journal.json 2>/dev/null")
        v=$(printf '%s' "$v" | tr -d ' ')
        printf '      meta/_journal.json 을 읽을 수 있나: %s (0 이면 목록이 안 담긴 것)\n' "${v:-?}"
        if isnum "${v:-}" && [ "${v:-0}" -ge 1 ] 2>/dev/null; then printf '  ✓ 목록 파일도 담겼다 (목록에 없는 .sql 은 drizzle 이 모른다)\n'
        else printf '  ✗ meta/_journal.json 을 못 읽었다 — 적용이 0건으로 조용히 끝난다\n'; IMGFAIL=1; fi
        # 🔵 포털 tools 는 vendor 를 **안 담는다** — Dockerfile 과 같은지 값으로 본다.
        v=$(dock "$TAG" -c "test -d /app/vendor && echo yes || echo no")
        printf '      /app/vendor: %s (기대 no — 포털 tools 는 vendor 를 안 담는다)\n' "${v:-못 읽음}"
        if [ "${v:-}" = "no" ]; then printf '  ✓ 포털 도구에 vendor 가 없다 (Dockerfile 과 같다)\n'
        else printf '  ⚠️ 포털 도구에 vendor 가 있다 — Dockerfile 이 바뀐 것 같습니다. 사람이 보세요\n'; fi
        v=$(dock "$TAG" -c "test -d /app/node_modules/drizzle-kit && echo yes || echo no")
        printf '      /app/node_modules/drizzle-kit: %s (기대 yes)\n' "${v:-못 읽음}"
        if [ "${v:-}" = "yes" ]; then printf '  ✓ drizzle-kit 이 있다\n'
        else printf '  ✗ drizzle-kit 이 없다 — db:migrate 가 죽는다\n'; IMGFAIL=1; fi
        npm_probe "$TAG" db:migrate
        npm_probe "$TAG" check:delegations
        npm_probe "$TAG" check:notify
        printf '%s\n' "      🔴 **check:notify 가 이번 판의 새 코드를 지나갑니다** — 종 알림을 모으는"
        printf '%s\n' "         길이 merge.ts 를 부릅니다. 그래서 **포털 도구도 굽습니다.**"
        ;;
    esac
  fi
}

# ══ 재기 ══════════════════════════════════════════════════════════════
check_all
if [ "$MODE" = "--check" ]; then
  if [ "$FAIL" = "0" ] && [ "$UNK" = "0" ]; then
    printf '\n%s\n' "✅ 전부 ✓ 입니다. 구우려면 --go 로 다시 부르세요."
    exit 0
  fi
  printf '\n%s\n' "🔴 ✗ 나 ? 가 있습니다. 위를 보세요 — 고친 뒤 --go 로 가세요."
  printf '%s\n' "   🔵 **검사 자신을 먼저 의심하세요** — 처음 도는 코드라 기대값이 틀릴 확률이"
  printf '%s\n' "      굽기만큼 높습니다. 기대값의 출처는 이 파일 머리말에 적혀 있습니다."
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════
# ══ 🔴 묶음 안을 세는 함수 — --go 와 --verify 가 **함께 쓴다** ═══════
# ══════════════════════════════════════════════════════════════════════
#   🔴 **두 벌로 적지 않는다.** 66번은 --go 쪽과 --verify 쪽에 따로 적어 두어
#      기대값이 어긋날 자리가 있었다 — 여기서는 한 함수로 모았다.
#   🔴 tar 를 **grep -q 에 물리지 않는다**(함정 ⑦). 전부 세어서 담는다.
MIGCHK_FAIL=0
migtar_inside() { # 1 묶음 경로
  local a b s j n m
  MIGCHK_FAIL=0
  s=$(tar -tzf "$1" 2>/dev/null | grep -cE '^drizzle/[0-9]{4}_.*[.]sql$' || true)
  j=$(tar -xzOf "$1" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
  printf '    묶음 안 — .sql %s장 · meta/_journal.json 의 idx %s개 (기대 %s · %s)\n' \
    "${s:-?}" "${j:-?}" "$AS_SQL_WANT" "$AS_SQL_WANT"
  if [ "${s:-x}" = "$AS_SQL_WANT" ] && [ "${j:-x}" = "$AS_SQL_WANT" ]; then
    printf '  ✓ 묶음 안이 %s장이고 목록도 %s개다 (목록에서 빠진 .sql 이 없다)\n' "$AS_SQL_WANT" "$AS_SQL_WANT"
  else
    printf '  ✗ 묶음 안이 .sql %s · idx %s 다 — %s·%s 를 기대했다\n' "${s:-?}" "${j:-?}" "$AS_SQL_WANT" "$AS_SQL_WANT"
    printf '%s\n' "      🔴 목록에 없는 .sql 은 drizzle 이 **아예 모르고**, 적용이 0건으로 조용히 끝납니다."
    MIGCHK_FAIL=$((MIGCHK_FAIL+1))
  fi
  # 🔴 **이번 판이 올릴 두 장**이 .sql·스냅샷 **짝으로** 들어 있는가.
  n=0; m=0
  for t in $AS_NEW_MIGS; do
    n=$((n+1))
    a=$(tar -tzf "$1" 2>/dev/null | grep -cE "^drizzle/${t}_.*[.]sql" || true)
    b=$(tar -tzf "$1" 2>/dev/null | grep -cE "^drizzle/meta/${t}_snapshot[.]json" || true)
    printf '    묶음 안의 %s — .sql %s개 · 스냅샷 %s개 (기대 1 · 1)\n' "$t" "${a:-?}" "${b:-?}"
    [ "${a:-0}" = "1" ] && [ "${b:-0}" = "1" ] && m=$((m+1))
  done
  if [ "$n" = "$AS_NEW_MIGS_WANT" ] && [ "$m" = "$AS_NEW_MIGS_WANT" ]; then
    printf '  ✓ **이번 판이 올릴 %s장이 묶음 안에 짝으로 있다**\n' "$AS_NEW_MIGS_WANT"
  else
    printf '  ✗ 본 장 %s · 짝으로 있는 장 %s 다 — %s 를 기대했다. **보내지 마세요**\n' "$n" "$m" "$AS_NEW_MIGS_WANT"
    MIGCHK_FAIL=$((MIGCHK_FAIL+1))
  fi
  a=$(tar -tzf "$1" 2>/dev/null | grep -cE "^drizzle/${AS_NEXT_MIG}_.*[.]sql" || true)
  printf '    묶음 안의 %s: %s개 (기대 0)\n' "$AS_NEXT_MIG" "${a:-?}"
  if [ "${a:-1}" = "0" ]; then
    printf '  ✓ 묶음에 %s 가 없다 (마지막이 0133 — 적용 대기가 2건이 된다)\n' "$AS_NEXT_MIG"
  else
    printf '  ✗ 묶음에 %s 가 **있다** — 이 배포는 0133 까지를 전제로 쓰였다. 멈추고 알릴 것\n' "$AS_NEXT_MIG"
    MIGCHK_FAIL=$((MIGCHK_FAIL+1))
  fi
  # 🔵 창 안 일곱 — 폴더를 통째로 갈아 끼우므로 .sql 과 스냅샷이 짝인지 본다.
  KEEPIN_MISS=""; KEEPIN_SEEN=0
  for t in $AS_KEEP_MIGS; do
    KEEPIN_SEEN=$((KEEPIN_SEEN+1))
    a=$(tar -tzf "$1" 2>/dev/null | grep -cE "^drizzle/${t}_.*[.]sql" || true)
    b=$(tar -tzf "$1" 2>/dev/null | grep -cE "^drizzle/meta/${t}_snapshot[.]json" || true)
    printf '      %-6s .sql %s · 스냅샷 %s\n' "$t" "${a:-0}" "${b:-0}"
    [ "${a:-0}" -ge 1 ] 2>/dev/null || KEEPIN_MISS="$KEEPIN_MISS $t(sql)"
    [ "${b:-0}" -ge 1 ] 2>/dev/null || KEEPIN_MISS="$KEEPIN_MISS $t(snapshot)"
  done
  if [ "$KEEPIN_SEEN" = "$AS_KEEP_MIGS_WANT" ] && [ -z "${KEEPIN_MISS:-}" ]; then
    printf '  ✓ 묶음에 창 안 %s장의 .sql 과 스냅샷이 다 있다 (폴더를 통째로 갈아 끼워도 안전하다)\n' "$AS_KEEP_MIGS_WANT"
  else
    printf '  ✗ 본 것 %s장 · 묶음에서 빠진 것:%s\n' "$KEEPIN_SEEN" "${KEEPIN_MISS:- 없음}"
    MIGCHK_FAIL=$((MIGCHK_FAIL+1))
  fi
  # 🔴 묶음 안의 두 장이 기대한 생김새인가 — **보내는 것은 저장소가 아니라 이 묶음이다.**
  n=0; m=0
  for t in $AS_NEW_MIGS; do
    n=$((n+1))
    NM=$(tar -tzf "$1" 2>/dev/null | grep -E "^drizzle/${t}_.*[.]sql" | head -1)
    if [ -z "${NM:-}" ]; then
      printf '  ✗ 묶음 안의 %s 을 못 읽었다\n' "$t"; MIGCHK_FAIL=$((MIGCHK_FAIL+1)); continue
    fi
    TB=$(tar -xzOf "$1" "$NM" 2>/dev/null)
    traw=$(printf '%s\n' "$TB" | grep -ciE "$DESTRUCTIVE_RE" || true)
    tnet=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
    tins=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'INSERT INTO' || true)
    tct=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'CREATE TABLE' || true)
    tac=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'ADD COLUMN' || true)
    trn=$(printf '%s\n' "$TB" | grep -ciE 'RENAME' || true)
    tond=$(printf '%s\n' "$TB" | grep -cF 'ON DELETE' || true)
    printf '    묶음 안 %s — 지우는 문장 날것 %s/걷은뒤 %s(기대 0) · ADD COLUMN %s · INSERT %s(기대 0) · CREATE TABLE %s(기대 0) · RENAME %s(기대 0) · (참고) ON DELETE %s\n' \
      "$t" "${traw:-?}" "${tnet:-?}" "${tac:-?}" "${tins:-?}" "${tct:-?}" "${trn:-?}" "${tond:-?}"
    if [ "${tnet:-x}" = "0" ] && [ "${tins:-1}" = "0" ] && [ "${tct:-1}" = "0" ] \
       && [ "${trn:-1}" = "0" ] && [ "${tac:-0}" -ge 1 ] 2>/dev/null; then
      m=$((m+1))
    else
      printf '  ✗ 묶음 안의 %s 이 기대와 다르다 — 보내지 마세요\n' "$t"; MIGCHK_FAIL=$((MIGCHK_FAIL+1))
    fi
  done
  if [ "$n" = "$AS_NEW_MIGS_WANT" ] && [ "$m" = "$AS_NEW_MIGS_WANT" ]; then
    printf '  ✓ 묶음 안의 %s장이 **전부 칸을 더하기만 한다** (자료를 안 건드린다)\n' "$AS_NEW_MIGS_WANT"
    printf '%s\n' "      🔵 0133 의 ON DELETE restrict 는 **지우는 문장이 아닙니다** — 4-ㄱ 의"
    printf '%s\n' "         일곱째 표본이 그것을 값으로 보였습니다."
  fi
}

# ══════════════════════════════════════════════════════════════════════
# ── 🔴 --verify : **이미 구운 넷을 다시 재기만 한다** ────────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **아무것도 굽지 않고 아무 파일도 만들지 않는다.** docker build 도
#      docker save 도 한 줄 없다 — 구운 지문(md5)이 바뀌면 안 되기 때문이다.
if [ "$MODE" = "--verify" ]; then
  printf '\n%s\n' "════════ --verify — 이미 구운 $HOWMANY 을 **다시 잰다** (굽지 않는다) ════════"
  printf '%s\n' "🔴 docker build 도 docker save 도 돌리지 않습니다 — 지문이 바뀌면 안 됩니다."
  VFAIL=0; VSEEN=0; TARTABLE=""; INSIDE_RAN=0
  # 🔴 **함수가 정말 있는가** — 없으면 「command not found」 한 줄만 찍히고
  #    나머지가 통째로 건너뛰어진다(2026-11-18 에 실제로 그렇게 통과했다).
  if ! command -v inside_check >/dev/null 2>&1; then
    printf '  ✗ inside_check 함수가 **없다** — 이 파일의 차례가 깨졌다. 아무것도 안 쟀다\n'
    exit 1
  fi
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    KEY=$(field "$row" 1); TAG=$(field "$row" 3); TGT=$(field "$row" 4)
    VSEEN=$((VSEEN+1))
    printf '\n── %s\n' "$TAG"
    if ! docker image inspect "$TAG" >/dev/null 2>&1; then
      printf '  ✗ %s 가 없다 — 굽지 않았거나 지웠다\n' "$TAG"; VFAIL=$((VFAIL+1)); continue
    fi
    IMGFAIL=0
    inside_check "$KEY" "$TAG" "$TGT"
    if [ "$IMGFAIL" != 0 ]; then
      printf '%s\n' "🔴 $TAG 의 안이 온전하지 않다."
      VFAIL=$((VFAIL+1))
    fi
    # 🔵 tar 가 아직 있으면 지문 줄을 **다시 찍어 준다** — 굽지 않고도 TARS 를 채울 수 있다.
    FILE=$(tar_name "$TAG")
    if [ -f "$OUT/$FILE" ]; then
      sz=$(stat -c %s "$OUT/$FILE" 2>/dev/null || wc -c < "$OUT/$FILE")
      m5=$(md5sum "$OUT/$FILE" | awk '{print $1}')
      cfg=$(tar_config_id "$OUT/$FILE")
      TARTABLE="$TARTABLE$FILE|$sz|$m5|${cfg:-없음}
"
    fi
  done <<ENDVERIFY
$(rows_of "$IMAGES")
ENDVERIFY
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  본 이미지 %s / %s · **안을 실제로 센 횟수 %s** · 안이 온전하지 않은 것 %s\n' \
    "$VSEEN" "$HOWMANY" "$INSIDE_RAN" "$VFAIL"
  if [ "$VSEEN" != "$HOWMANY" ]; then
    printf '  ✗ 이미지를 %s개만 봤다 — %s개를 기대했다. IMAGES 표가 깨졌다\n' "$VSEEN" "$HOWMANY"
    VFAIL=$((VFAIL+1))
  fi
  # 🔴 **표본이 비어서 공짜로 통과하지 않게** 한다.
  if [ "$INSIDE_RAN" != "$HOWMANY" ]; then
    printf '  ✗ 이미지 안을 %s번만 쟀다 — %s번을 기대했다. **아무것도 안 잰 통과다**\n' "$INSIDE_RAN" "$HOWMANY"
    VFAIL=$((VFAIL+1))
  else
    printf '  ✓ 이미지 안을 %s번 다 쟀다 (표본이 비지 않았다)\n' "$INSIDE_RAN"
  fi
  if [ -n "${TARTABLE:-}" ]; then
    printf '\n%s\n' "════════ 71-deploy.sh 의 TARS 에 넣을 줄 (tar 에서 다시 쟀습니다) ════════"
    printf '%s' "$TARTABLE"
  fi
  # 🔴 **묶음도 다시 만들지 않는다** — 만들면 md5 가 바뀐다. 있으면 **열어서 재고**
  #    지문 줄만 찍는다.
  printf '\n%s\n' "════════ 묶음 — **다시 만들지 않고 열어서만 잽니다** ════════"
  if [ -f "$MIGTAR" ]; then
    msz=$(stat -c %s "$MIGTAR" 2>/dev/null || wc -c < "$MIGTAR")
    mm5=$(md5sum "$MIGTAR" | awk '{print $1}')
    printf '    as-migrations.tar.gz %s바이트 · md5 %s\n' "${msz:-?}" "${mm5:-?}"
    migtar_inside "$MIGTAR"
    if [ "$MIGCHK_FAIL" != "0" ]; then VFAIL=$((VFAIL + MIGCHK_FAIL)); fi
    printf '\n%s\n' "════════ 71-deploy.sh 의 묶음 값 둘 (묶음에서 다시 쟀습니다) ════════"
    printf '%s\n' "MIGTAR_SIZE=${msz}"
    printf '%s\n' "MIGTAR_MD5=${mm5}"
  else
    printf '  ⚠️ 묶음이 아직 없습니다 (--go 전이면 정상입니다) — %s\n' "$MIGTAR"
  fi
  printf '\n'
  if [ "$FAIL" = "0" ] && [ "$UNK" = "0" ] && [ "$VFAIL" = "0" ]; then
    printf '%s\n' "✅ --verify 전부 통과입니다. **아무것도 안 굽고 안 바꿨습니다.**"
    exit 0
  fi
  printf '%s\n' "🔴 ✗ 가 남아 있습니다 (앞 절 ✗ $FAIL · ? $UNK · 이미지·묶음 $VFAIL)"
  printf '%s\n' "   🔵 **검사 자신을 먼저 의심하세요** — 1-ㄴ 절(경로 번역)이 ✓ 였는지 보세요."
  exit 1
fi

if [ "$FAIL" != "0" ] || [ "$UNK" != "0" ]; then
  printf '\n%s\n' "🔴 ✗ 나 ? 가 있어 **굽지 않습니다.** (✗ $FAIL · ? $UNK)"
  printf '%s\n' "   구운 이미지는 그때 그 작업 폴더의 사진입니다 — 어긋난 채로 구우면"
  printf '%s\n' "   나중에 같은 이미지를 다시 못 만듭니다."
  exit 1
fi

mkdir -p "$OUT" || { printf '%s\n' "🔴 $OUT 를 못 만들었다"; exit 1; }

# ══ 굽기 ══════════════════════════════════════════════════════════════
printf '\n%s\n' "════════ 굽는다 ($HOWMANY) ════════"
printf '%s\n' "🔵 **넷입니다.** 20~40분쯤 걸릴 수 있습니다 — 중간에 끊지 마세요."
printf '%s\n' "🔵 dev 서버(3000·3100)와 DB(5442·5444)는 **켜 둔 채로 둬도 됩니다** — .dockerignore 가"
printf '%s\n' "   .next 를 막고(5-ㄴ), 이 파일은 호스트의 npm run build 를 한 번도 안 부릅니다."
BUILT=0; BFAIL=0; TARTABLE=""; BUILD_SEEN=0; MIGLINE=""
while IFS= read -r row; do
  [ -n "$row" ] || continue
  KEY=$(field "$row" 1); REPO=$(field "$row" 2); TAG=$(field "$row" 3)
  TGT=$(field "$row" 4); PREVTAR=$(field "$row" 5); PREVSZ=$(field "$row" 6)
  STRICT=$(field "$row" 7)
  DIR="$DEV/$REPO"
  BUILD_SEEN=$((BUILD_SEEN+1))
  FILE=$(tar_name "$TAG")
  LOG="$OUT/build-$(printf '%s' "$TAG" | tr ':' '-').log"
  printf '\n── %s/%s  %s  (%s)\n' "$BUILD_SEEN" "$HOWMANY" "$TAG" "$REPO"

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
    printf '  ✗ 굽기 실패 — %s 를 보세요\n' "$LOG"; BFAIL=$((BFAIL+1))
    printf '%s\n' "      🔵 **vendor 를 먼저 의심하세요** — A/S 는 vendor/dss-core 와 vendor/dss-ui,"
    printf '%s\n' "         포털은 vendor/dss-ui 가 비어 있으면 Module not found 로 죽습니다(3-ㄷ)."
    printf '%s\n' "         → git -C \"$DIR\" submodule update --init --recursive"
    continue
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
  if [ "$STRICT" = "none" ]; then
    printf '  ⚠️ 지난 판 %s 의 바이트가 **이 저장소에 적힌 곳이 없다** — ①번 견주기를 건너뛴다\n' "$PREVTAR"
    printf '%s\n' "      🔵 0 을 기대값으로 쓰면 「차이 무한%」로 **가짜 ✗** 가 납니다."
  else
    p=$(pct_diff "$sz" "$PREVSZ")
    if [ -n "${p:-}" ]; then
      printf '    지난 판 %s %s바이트 → 이번 %s바이트 (차이 %s%%)\n' "$PREVTAR" "$PREVSZ" "$sz" "$p"
      if [ "$p" -le 25 ]; then
        printf '  ✓ 지난 판 tar 와 크기가 비슷하다 (차이 %s%% · 25%% 이내)\n' "$p"
      elif [ "$STRICT" = "loose" ] && [ "$p" -le 60 ]; then
        printf '  ⚠️ 지난 판 tar 와 %s%% 다르다 — 이 줄은 loose 라 막지 않습니다\n' "$p"
      else
        printf '  ✗ 지난 판 tar 와 크기가 %s%% 다르다 — %s 에서는 그만큼이면 멈춘다\n' "$p" "$STRICT"
        printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 라이브러리가 늘거나 베이스 이미지가"
        printf '%s\n' "         바뀌면 정상적으로도 이만큼 뜁니다. 🔴 다만 이번 판은 두 집 다"
        printf '%s\n' "         package.json 이 **0줄** 바뀌었습니다(5-ㄷ) — 그래서 strict 로 두었습니다."
        printf '%s\n' "         🔵 **포털의 지난 판 바이트는 62번(2026-11-18) 것**이라 그 사이에 베이스"
        printf '%s\n' "            이미지가 바뀌었을 수 있습니다. 까닭을 모르면 **멈추고 알리세요.**"
        BFAIL=$((BFAIL+1)); continue
      fi
    else
      printf '  ✗ 크기를 못 쟀다 (이번 %s · 지난 판 %s)\n' "${sz:-없음}" "${PREVSZ:-없음}"
      BFAIL=$((BFAIL+1)); continue
    fi
  fi

  # ── 🔴 크기 견주기 ② — **그 이미지 자신과** (가지를 둘로 나눈다) ───
  isz=$(docker image inspect "$TAG" --format '{{.Size}}' 2>/dev/null)
  if isnum "${isz:-}" && [ "${isz:-0}" -gt 0 ]; then
    rr=$((sz * 100 / isz))
    printf '    이미지 inspect .Size %s바이트 · tar 는 그 %s%%\n' "$isz" "$rr"
    if [ "$rr" -ge 90 ] && [ "$rr" -le 110 ]; then
      printf '  ✓ tar 가 이미지 내용 크기와 거의 같다 (%s%% — containerd 저장소다)\n' "$rr"
    elif [ "$rr" -ge 10 ] && [ "$rr" -le 45 ]; then
      printf '  ✓ tar 가 이미지의 1/4 쯤이다 (%s%% — 고전 저장소다)\n' "$rr"
    else
      printf '  ✗ tar 가 이미지의 %s%% 다 — 90~110%% 나 10~45%% 를 기대했다\n' "$rr"
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
  inside_check "$KEY" "$TAG" "$TGT"
  if [ "$IMGFAIL" != 0 ]; then
    printf '%s\n' "🔴 $TAG 의 안이 온전하지 않다. 올리지 마세요."
    BFAIL=$((BFAIL+1))
  fi
done <<ENDBUILD
$(rows_of "$IMAGES")
ENDBUILD

# ══════════════════════════════════════════════════════════════════════
# ── 🔴 **다섯째 산출물 — A/S 마이그레이션 묶음** (66번에서 되살렸다) ──
# ══════════════════════════════════════════════════════════════════════
#   🔴 **A/S 만 그렇다.** 포털은 마이그레이션이 **도구 이미지 안**에 구워져 가므로
#      묶음이 없다(5-ㄱ 의 auth|drizzle|yes). A/S 도구의 /app/drizzle 은 **비어 있고**
#      운영에서는 거기에 /volume1/dss/as-migrations 가 붙는다 — 그래서 0132·0133 은
#      **이 묶음으로만** 간다. 🔴 안 보내면 적용이 0건으로 **조용히** 끝나고 겉으로는
#      성공으로 보인다.
#   🔴 **70·69·68·67 번에는 이 절이 통째로 없었다**(마이그레이션 0건이었다).
#      베껴 쓰면서 이 절을 빠뜨리는 것이 **이번 판의 가장 큰 위험**이다.
printf '\n%s\n' "════════ 다섯째 산출물 — A/S 마이그레이션 묶음 ($AS_SQL_WANT 장) ════════"
printf '%s\n' "🔵 **포털 쪽 묶음은 없습니다** — 포털은 .sql 이 도구 이미지 안에서 돕니다."
MIGOK=1; msz=""; mm5=""
# 🔴 옛 판의 묶음이 남아 있을 수 있다 — **지우고 다시 만든다.**
rm -f "$MIGTAR" 2>/dev/null
# 🔴 **tar 는 상대경로로 묶는다** — 작업 폴더로 들어가 drizzle 만 넘긴다.
#    드라이브 문자가 섞이면 tar 가 그것을 **원격 호스트 이름**으로 읽어 깨진다.
if ( cd "$ASD" && tar -czf "$MIGTAR" drizzle ) </dev/null; then
  msz=$(stat -c %s "$MIGTAR" 2>/dev/null || wc -c < "$MIGTAR")
  mm5=$(md5sum "$MIGTAR" | awk '{print $1}')
  printf '  ✓ as-migrations.tar.gz (%s바이트)\n' "$msz"
  printf '    md5  %s\n' "$mm5"
  printf '%s\n' "    🔵 66번(132장)의 묶음은 2,620,436바이트였습니다 — 그보다 조금 큰 것이 정상입니다."
else
  printf '  ✗ 묶음을 못 만들었다 — 🔴 **A/S 는 묶음이 필수다**\n'
  BFAIL=$((BFAIL+1)); MIGOK=0
fi
if [ "$MIGOK" = "1" ]; then
  migtar_inside "$MIGTAR"
  if [ "$MIGCHK_FAIL" != "0" ]; then BFAIL=$((BFAIL + MIGCHK_FAIL)); fi
  MIGLINE="as-migrations.tar.gz|${msz}|${mm5}|-"
fi

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  본 줄 %s / %s · 구운 것 %s / %s · **안을 실제로 센 횟수 %s** · 묶음 %s · 실패 %s\n' \
  "$BUILD_SEEN" "$HOWMANY" "$BUILT" "$HOWMANY" "$INSIDE_RAN" "$MIGOK" "$BFAIL"
# 🔴 **표본이 비어서 공짜로 통과하지 않게** 한다 — 고리가 한 바퀴만 돌아도 잡힌다.
if [ "$BUILD_SEEN" != "$HOWMANY" ]; then
  printf '  ✗ IMAGES 표를 %s줄만 돌았다 — %s줄을 기대했다. **고리가 끊겼다**\n' "$BUILD_SEEN" "$HOWMANY"
  BFAIL=$((BFAIL+1))
fi
if [ "$INSIDE_RAN" != "$HOWMANY" ]; then
  printf '  ✗ 이미지 안을 %s번만 쟀다 — %s번을 기대했다. **아무것도 안 잰 통과다**\n' "$INSIDE_RAN" "$HOWMANY"
  BFAIL=$((BFAIL+1))
fi

# ══ 🔴 **✗ 가 나도 지문 줄만은 찍는다** ═══════════════════════════════
#   🔴 쉰세째·쉰네째에 **두 번 연속으로 지문을 못 받았다.** 그래서 **세 자리**에서 찍는다.
if [ "$BFAIL" != "0" ]; then
  printf '\n%s\n' "🔴🔴🔴 **실패가 있지만 지금까지 만든 산출물의 지문은 아래가 전부입니다**"
  printf '%s\n' "       (이름|바이트|md5|Config 지문 — 71-deploy.sh 의 TARS 에 넣을 꼴입니다)"
  if [ -n "${TARTABLE:-}" ]; then printf '%s' "$TARTABLE"
  else printf '%s\n' "       (tar 가 한 줄도 없습니다 — 하나도 안 구워졌다는 뜻입니다.)"; fi
  if [ -n "${MIGLINE:-}" ]; then
    printf '%s\n' "       MIGTAR_SIZE=${msz}"
    printf '%s\n' "       MIGTAR_MD5=${mm5}"
  else
    printf '%s\n' "       (묶음 줄이 없습니다 — 묶음이 안 만들어졌다는 뜻입니다.)"
  fi
  printf '%s\n' "🔴🔴🔴 **실패를 고친 뒤 다시 구우면 지문이 바뀝니다** — 위 값을 그대로 쓰지"
  printf '%s\n' "       마시고, 다시 구운 뒤의 값을 쓰세요."
  printf '%s\n' "       🔵 **검사 쪽이 틀린 것이면 다시 굽지 말고 --verify 를 쓰세요** —"
  printf '%s\n' "          지문이 바뀌지 않습니다."
  printf '\n%s\n' "🔴 실패가 있다. 위를 보세요."
  exit 1
fi

# 🔴 **굽고 나서 저장소가 더러워졌는가** — next build 가 tsconfig.json 을 다시 접는다.
printf '\n%s\n' "════════ 구운 뒤 저장소가 그대로인가 ════════"
printf '%s\n' "🔴 next build 가 tsconfig.json 을 다시 접은 적이 있습니다(눈에 안 띕니다)."
DIRTY_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  DIRTY_SEEN=$((DIRTY_SEEN+1))
  RD="$DEV/$(field "$r" 2)"; RN=$(field "$r" 3)
  d=$(git -C "$RD" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${d:-1}" = "0" ]; then printf '  ✓ %s 미커밋 0줄\n' "$RN"
  else
    printf '  ⚠️ %s 에 미커밋이 %s줄 생겼다 — **사람에게 알리세요**\n' "$RN" "$d"
    git -C "$RD" status --porcelain=v1 2>/dev/null | head -6 | sed 's/^/        /'
  fi
done <<ENDDIRTY
$(rows_of "$REPOS")
ENDDIRTY
printf '  (본 저장소 %s / %s)\n' "$DIRTY_SEEN" "$REPOS_WANT"
for p in "$COREDIR:vendor/dss-core(A/S)" "$UIDIR:vendor/dss-ui(A/S)" "$AUTHUIDIR:vendor/dss-ui(포털)"; do
  pd=${p%%:*}; pn=${p#*:}
  d=$(git -C "$pd" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${d:-1}" = "0" ]; then printf '  ✓ %s 미커밋 0줄\n' "$pn"
  else printf '  ⚠️ %s 에 미커밋이 %s줄 생겼다 — 사람에게 알리세요\n' "$pn" "$d"; fi
done
printf '%s\n' "  🔵 **tar 는 이미 구워졌습니다** — 되돌릴지 그대로 둘지는 사람이 정하세요."

# ══ 🔴 71-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
printf '\n%s\n' "════════ 71-deploy.sh 에 붙여 넣을 것 (TARS **네 줄** + 묶음 값 **둘**) ════════"
printf '%s' "$TARTABLE"
printf '%s\n' "  🔴 위 **네 줄**로 TARS 를 통째로 갈아 끼웁니다 — 지금은 **비어 있습니다.**"
printf '%s\n' "  🔴 그리고 **묶음 값 둘**을 아래 그대로 적습니다 (TARS 가 아니라 따로 있는 변수입니다):"
printf '%s\n' "       MIGTAR_SIZE=${msz}"
printf '%s\n' "       MIGTAR_MD5=${mm5}"
printf '%s\n' "  🔴 **NAS 에서 재서 채우지 마세요** — 자기가 잰 값으로 자기를 재면 영영 통과합니다."
printf '%s\n' "  🔵 그리고 위 **네 줄의 바이트를 README 에 적어 두세요** — 다음 판이 ①번"
printf '%s\n' "     크기 견주기에 그 값을 씁니다. 🔴 **포털 바이트는 특히 적어 두세요** —"
printf '%s\n' "     이번에 62-deploy.sh 까지 거슬러 올라가 찾아야 했습니다."
printf '\n%s\n' "✅ 넷을 다 굽고 묶음도 만들었습니다. 산출물이 여기 있습니다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'

printf '\n%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **올리는 차례 — tar 넷 + 묶음 하나**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  🔴 PowerShell 경로는 **슬래시**로 적습니다. 역슬래시는 bash·scp 가 먹습니다."
printf '%s\n' "  🔴 **Tee-Object 로 로그를 받지 마세요** — PowerShell 이 UTF-16 으로 써서"
printf '%s\n' "     나중에 grep 이 한 줄도 못 찾습니다. NAS 쪽 로그 파일을 보세요."
printf '%s\n' "  🔴 **-O 를 빼지 마세요** — DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' ""
printf '%s\n' "  ① (개발 PC · PowerShell) **스크립트부터 올린다**"
printf '%s\n' "       cd \"C:/Users/희만/Desktop/Development/dss-deploy/nas/setup\""
printf '%s\n' "       scp -O 71-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "       Get-FileHash -Algorithm MD5 71-deploy.sh"
printf '%s\n' "     🔴 **TARS 네 줄과 MIGTAR_SIZE·MIGTAR_MD5 를 먼저 채운 뒤에 올리세요.**"
printf '%s\n' "     🔴 **DSM 터미널은 긴 명령을 잘라 먹습니다** — 그래서 NAS 것은 스크립트"
printf '%s\n' "        파일로 올리고 **md5 를 맞댑니다.** 71-deploy.sh 가 돌 때 제 md5 를"
printf '%s\n' "        스스로 찍으니 위 Get-FileHash 값과 **눈으로 맞대세요.**"
printf '%s\n' ""
printf '%s\n' "  ② (NAS 터미널(SSH)) 지금 상태를 잰다 — 아직 아무것도 안 바뀐다"
printf '%s\n' "       sudo -i"
printf '%s\n' "       bash /volume1/dss/setup/71-deploy.sh            ← --check"
printf '%s\n' "       bash /volume1/dss/setup/71-deploy.sh --count    ← 올리기 전 수"
printf '%s\n' ""
printf '%s\n' "  ③ (개발 PC · PowerShell) **tar 넷과 묶음 하나를 보낸다 — 한 줄에 하나씩**"
printf '%s\n' "       cd \"$(printf '%s' "$OUT" | sed 's|^/c/|C:/|')\""
SCP_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  SCP_SEEN=$((SCP_SEEN+1))
  printf '%s\n' "       scp -O $(tar_name "$(field "$r" 3)") dss-nas:/volume1/dss/images/"
done <<ENDSCP
$(rows_of "$IMAGES")
ENDSCP
printf '%s\n' "       scp -O as-migrations.tar.gz dss-nas:/volume1/dss/setup/incoming/"
printf '%s\n' "     (보낼 tar $SCP_SEEN / $HOWMANY · 묶음 1)"
printf '%s\n' "     🔴 **묶음은 images/ 가 아니라 setup/incoming/ 으로 갑니다** — 자리가 다릅니다."
printf '%s\n' "     🔴 **옛 폴더(_images-58·…·_images-70)의 묶음을 보내지 마세요** — 그것들은"
printf '%s\n' "        128·129·131·132장짜리라 **엉뚱한 판이 볼륨을 덮습니다.** 보낼 것은"
printf '%s\n' "        방금 만든 **${AS_SQL_WANT}장짜리** 하나뿐입니다."
printf '%s\n' ""
printf '%s\n' "  ④ (NAS 터미널(SSH)) **들여놓고 → 다시 재고 → DB 를 올리고 → 앱을 갈아 끼운다**"
printf '%s\n' "       bash /volume1/dss/setup/71-deploy.sh --preload"
printf '%s\n' "       bash /volume1/dss/setup/71-deploy.sh            ← 다시 --check"
printf '%s\n' "       bash /volume1/dss/setup/71-deploy.sh --migrate  🔴 **여기서 DB 가 바뀐다** (${AS_SQL_WAS} → ${AS_SQL_WANT})"
printf '%s\n' "       bash /volume1/dss/setup/71-deploy.sh --go       ⏱ 정지 창 (앱 **둘**)"
printf '%s\n' "       bash /volume1/dss/setup/71-deploy.sh --count    ← 올린 뒤 수"
printf '%s\n' "     🔴 **--migrate 가 하는 일**: 덤프(dss_as) → compose 사본 → **묶음을 볼륨에"
printf '%s\n' "        풀고**(${AS_SQL_WAS} → ${AS_SQL_WANT}) → **도구 태그 둘을 갈고** → db:preflight 로 **대기 2건**을"
printf '%s\n' "        값으로 받고 → db:migrate(**A/S 만**) → **수를 다시 세어 ${AS_SQL_WANT} 인지** 확인합니다."
printf '%s\n' "     🔵 **포털 도구도 --migrate 에서 함께 갑니다** — 포털은 올릴 .sql 이 0건이지만"
printf '%s\n' "        merge.ts 가 바뀌어서 check:notify 가 옛 소스로 돌면 안 됩니다."
printf '%s\n' "     🔴 **--migrate 를 건너뛰고 --go 로 가지 마세요** — 새 A/S 앱이 confirmed_at 과"
printf '%s\n' "        share_doc_relative_path 를 읽고 쓰므로 칸이 없으면 **42703 으로 터집니다.**"
printf '%s\n' ""
printf '%s\n' "🔴 **되돌리기**: --rollback 은 앱 **둘**을 옛 태그로 되돌립니다."
printf '%s\n' "   🔵 도구는 새 판 그대로 둡니다(39·41~70번과 같은 판단)."
printf '%s\n' "   🔴 **DB 는 자동으로 안 되돌립니다** — 0132·0133 은 **칸을 더하기만** 하므로"
printf '%s\n' "      옛 앱은 그 칸을 쳐다보지도 않습니다(읽는 코드가 없습니다)."
printf '%s\n' "────────────────────────────────────────────────────────────"
printf '\n%s\n' "🔴🔴🔴 **71-deploy.sh 에 넣을 값 (다시 찍습니다 — 여기만 복사해도 됩니다)**"
printf '%s\n' "── TARS 네 줄"
printf '%s' "$TARTABLE"
printf '%s\n' "── 묶음 값 둘 (TARS 가 아니라 따로 있는 변수다)"
printf '%s\n' "MIGTAR_SIZE=${msz}"
printf '%s\n' "MIGTAR_MD5=${mm5}"
printf '%s\n' "🔴🔴🔴 위를 71-deploy.sh 에 **그대로** 적은 뒤 scp 하세요."
