#!/bin/bash
# dss-deploy/nas/setup/72-build.sh — 예순여덟째 배포 · 이미지 굽기 (2026-11-26)
#
# 🔵 **배포 회차와 파일 번호가 어긋나는 것은 이 저장소에서 원래 그렇다** —
#    66번이 예순두째, 67번이 예순세째, 68번이 예순네째, 69번이 예순다섯째,
#    70번이 예순여섯째, 71번이 예순일곱째였다. (56번은 2026-11-11 의 **양식
#    전용**이라 회차를 안 먹었다.)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴🔴 **맨 먼저 — 어느 판을 왜 베꼈는가** (지난 판 여섯이 전부 이 줄을 적었다)
# ══════════════════════════════════════════════════════════════════════
#   이 파일은 **71-build.sh(예순일곱째 · 2026-11-25)를 복사해 값만 고친 것**이다
#   (2026-11-19 결정 — 「배포본은 복사하고 값만 고친다. 검사는 하나도 안 뺀다.
#   diff 가 곧 검수다」). 🔴 **그래서 이 파일을 검수하는 길은 「diff 71-build.sh
#   72-build.sh」 다.**
#
#   ── 🔴 71번과 **다른 것 넷** (그래서 「빼는」 일이 주가 됐다) ─────────
#        | 71번(예순일곱째)      | 72번(이번)
#     집  | **둘**(A/S + 포털)    | 🔴 **하나**(A/S 만)
#     마이그| 2건 (132 → 134)      | 🔴 **0건** (134 그대로)
#     서브모듈| dss-core 가 움직임  | 🔴 **안 움직임** (191676f 그대로)
#     묶음 | 1 (A/S)               | 🔴 **없음**
#
#   ── 🔵 왜 70번(모양이 같은 판)을 안 베꼈나 ───────────────────────────
#   70번(예순여섯째)이 **집 하나 · 마이그 0건 · 묶음 없음 · 서브모듈 안 움직임**
#   이라 모양은 이번과 토씨 하나 안 틀린다. 🔴 그래도 뼈대는 **71번**이다 —
#   71번이 **첫 --go 에서 데고 고친 자리 넷**을 70번은 모른다:
#     · TOOLS_PAYLOAD 를 **스칼라 정규식 + 잣대 표본**으로 되돌린 것
#       (정규식 안에 | 가 들어 있어 표로 읽으면 grep 이 죽는다 — 2026-11-25)
#     · 「기능 표식을 **코드 줄**에서 따오면 minify 가 지운다」를 값으로 못 박은 것
#       (part.drawingNo, part.note 가 번들에서 **0/0** 이었다)
#     · KO_MARKS 의 **바이트 확인 절**(1-ㄷ)을 70번에서 가져와 자리 잡은 것
#     · inside_check 를 **굽기와 --verify 가 함께 쓰는 한 함수**로 모은 것
#   🔴 70번에서 가져온 것은 **「왜 없는가」를 적는 방식 하나**다(바로 아래).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 파일에 「왜 없는가」를 적어 두는 절 넷**
#    (70·68·67·65·64·63 이 그렇게 했다 — 그 글이 없으면 다음 판이
#     「원래 없는 절」로 읽고, 되살려야 할 때 아무도 되살리지 않는다)
# ══════════════════════════════════════════════════════════════════════
#   ① **묶음(as-migrations.tar.gz)을 만드는 절이 없다**(71-build.sh:2726-2757 의
#      「다섯째 산출물」과 migtar_inside()). 까닭: 이번 범위의 drizzle/ 변경이
#      **0줄**이라 볼륨에 더할 .sql 이 없다 — 4-ㄴ 이 값으로 잰다.
#      🔴 마이그레이션이 **1건이라도** 생기는 판에서는 **71번에서 그 절과
#         migtar_inside() 와 MIGTAR 변수를 통째로 되살려라.** 안 되살리면
#         0132 다음 번호가 운영에 **영영 안 올라가고**, 적용은 **0건으로 조용히**
#         끝나 겉으로는 성공으로 보인다.
#   ② **지우는 문장 잣대와 그 표본 일곱이 없다**(71-build.sh 4-ㄱ ·
#      DESTRUCTIVE_RE · SQL_COMMENT_RE · MIG_DROP_WANT). 까닭: 이번 범위에
#      **잴 .sql 이 없다**. 🔴 .sql 이 한 장이라도 생기면 **그 절부터** 넣어라 —
#      잣대가 없으면 「지우는 문장 0줄」이 **아무것도 안 재는 ✓** 가 된다.
#      🔵 71번이 일곱째 표본(ON DELETE restrict)을 그때 더했다. **그것까지** 가져와라.
#   ③ **공용 스키마에 「더한」 칸을 보는 절이 없다** — 대신 **뒷걸음을 보는 절**로
#      뜻이 뒤집혔다(3-ㄹ). 까닭: 서브모듈이 **안 움직인다**(3-ㄴ 이 0줄로 잰다).
#      🔵 그래도 **예순일곱째가 더한 칸 넷**(confirmed_at · confirmed_by ·
#         share_doc_relative_path ×2)은 작업본에서도 도구 이미지 안에서도 **그대로
#         본다** — 그것이 이 판에서 그 절이 하는 일이다.
#   ④ 🔴 **포털(dss-auth)이 통째로 없다.** REPOS·IMAGES·COPYRULES·APPMARKS·
#      TOOLMARKS·AUTH_KEY_FILES·시험 등록의 ㄴ) 절·count_test_paths() 함수가
#      전부 빠졌다. 까닭: 포털은 **이번 범위에 한 줄도 없다**(808d496 그대로) —
#      66·70번이 그랬듯 **「안 건드리는 집」으로 되돌아갔다.**
#      🔴 포털이 다시 올라가는 판에서는 **71번에서 통째로 되살려라.** 그때 되살릴
#         것은 표 다섯 줄이 아니라 **절 다섯**이다:
#           · REPOS·IMAGES 에 집을 더하고 고리마다 「몇 집을 봤는가」 기대값 올리기
#           · COPYRULES 의 **auth|drizzle|yes**(🔴 A/S 와 **뜻이 반대**다)
#           · 시험 등록 ㄴ) — 포털은 **package.json 의 test 줄에 경로를 나열**한다
#             (A/S 의 목록 파일 방식으로 착각해 빼면 그 집이 아무 검사도 안 받는다)
#           · inside_check 의 authtools 가지(이미지 안 .sql **11장**이 맞다)
#           · 포털 도구의 npm_probe(check:notify · check:delegations)
#      🔵 그 집을 **처음 넣은 판은 62번(쉰여덟째)**이고, 71번이 그것을 가져다 썼다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 올리는 것 — 세 갈래. DB 는 한 글자도 안 바뀐다**
# ══════════════════════════════════════════════════════════════════════
#   ㄱ) **완료된 건에서 [납기일 확정] 묶음이 안 선다.** [내자 정리]에서 줄이
#      완료됐거나 그 회차가 완료됐으면 **[납기일 확정]·「확정 ✓」 표·[확정 해제]
#      셋이 하나도 안 뜬다.** 🔵 **서버 울타리는 한 글자도 안 좁혔다** — 화면에서만
#      감춘다. 🔵 그래서 **이미 찍혀 있는 확정은 안 풀린다.**
#   ㄴ) **PO발행일이 적히면 작업 상태가 [수리 대기]로 간다.** 상태는 저장 칸이
#      아니라 **단계**에서 나오므로 **단계를 실제로 옮긴다**(repair_cases
#      .current_workflow_step_id). 🔴 **A/S 통로 셋에만** 걸려 있고 **PO 시스템에서
#      적으면 안 걸린다**(2026-11-26 결정 — 소스 주석에 그대로 적혀 있다).
#      🔵 앞으로만 간다 · 날짜를 지워도 안 되돌린다 · 이미 그 단계면 UPDATE 도
#         이력도 없다 · 그 상태의 단계가 없는 워크플로(무상)에서는 아무 일도 없다.
#   ㄷ) **고객 안내 현황의 「납품 요청일」**을 수리 건 상세와 **같은 함수**로 고른다
#      (그 건에 적힌 고객 요청 납기일이 먼저, 비면 내자에서 가장 이른 하루를
#      빌린다). 🔵 **꼬리표는 안 붙인다**(2026-11-26 결정).
#
#   🔵 **DB 는 한 글자도 안 건드린다** — 마이그레이션 **0건**. 🔴 까닭: 세 갈래가
#      전부 **이미 있는 칸을 읽고 쓰는 쪽**이다. ㄱ 은 화면 판정이고, ㄴ 이 쓰는
#      current_workflow_step_id·status_change_histories 는 2026-08 부터 있던 칸이며,
#      ㄷ 은 **읽기만** 한다.
#   🔴 **그래서 72-deploy.sh 에는 --migrate 가 없고 그 자리가 --tools 다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **71번의 전제 중 이번에 깨지는 것 아홉 — 하나씩 재서 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴🔴 **집이 하나다**(71번은 둘). 굽는 것이 **넷 → 둘**이고, 2·3·5절의
#      고리가 **한 바퀴**만 돈다. 🔴 「몇 집을 봤는가」 관문의 기대값도 **1** 이다.
#      🔵 고리 꼴은 **그대로 두었다** — 표가 한 줄이어도 고리로 돈다. 집이 다시
#         둘이 되는 날 표에 줄만 더하면 된다(71번이 62번에서 그렇게 가져왔다).
#
#   ② 🔴 **마이그레이션이 0건이다**(71번은 2건). [실측 2026-11-26 · 기준 56effcc8]
#      저장소 .sql **134장** · journal idx **134**(마지막 133) · **0134 는 없다** ·
#      이번 범위의 drizzle/ 변경 **0줄**.
#      🔴 그래서 **묶음도 --migrate 도 없다**(위 「왜 없는가」 ①·②).
#      🔵 4-ㄴ 이 「0133 이 아직 있는가」를 함께 센다 — 번호가 빗나가면 그 줄이 운다
#         (70번이 AS_NEXT_MIG 가 한 칸 빗나가 **두 판 연속 아무것도 안 막은** 것을
#          잡아낸 뒤로 넣은 규율이다).
#
#   ③ 🔴 **서브모듈이 안 움직인다** — 3절의 뜻이 **뒤집힌다.**
#      [실측 2026-11-26] vendor/dss-core **191676f 그대로** · vendor/dss-ui
#      **1210d112 그대로** · 이번 범위의 vendor/ · .gitmodules 변경 **0줄**.
#      🔴 71번의 3-ㄱ 후반은 「**옛 핀이 아닌가**」를 물었다. 이번 판은 핀이 안
#         움직이므로 그 물음을 **그대로 두면 거짓이 된다** — 뜻을 바꿔
#         「**예순여섯째까지의 핀(1e9ec85)으로 뒷걸음치지 않았는가**」를 묻는다.
#      🔴 3-ㄹ 도 「이번 판이 더한 칸 넷」에서 「**예순일곱째가 더한 칸 넷이 아직
#         있는가**」로 뜻이 바뀌었다. **절을 빼지 않았다** — 빼면 서브모듈이
#         되감긴 날 아무도 못 잡는다.
#
#   ④ 🔴 **바뀐 파일이 19장이다**(71번은 179장). [실측 2026-11-26 · 기준 56effcc8]
#      src/ **17** · scripts/ **2** · drizzle/ **0** · vendor+.gitmodules **0** ·
#      새 파일 **5** · 지운 파일 **0** · 괄호 **0** · 대괄호 **0** · 시험 **8**.
#      🔵 scripts/ 둘은 시험 목록 파일이다(unit.txt · db.txt).
#      🔵 **19 = 17 + 2** 라 덮기가 딱 맞는다 — 71번과 달리 **밖에 남는 장이 없다**
#         (71번은 저장소 뿌리의 진행현황 HTML 한 장이 어느 COPY 에도 안 걸렸다).
#
#   ⑤ 🔴 **새 시험이 3장이다**(71번은 43장). [실측] 바뀐 시험 **8장** · 그중 새것
#      **3장**. 목록 줄 수(빈 줄을 뺀 수) **4787 → 4828**
#        unit 2226→2236 · components 1908→1908 · db 639→670 · db-safety 14→14
#      🔴 **A/S 는 목록 파일 방식이라 적어야 돈다** — 빠뜨리면 **오류 없이 조용히
#         안 돈다.** 새 3장을 **한 장씩** 묻는다(줄 수만으로는 못 말한다).
#      🔵 늘어난 41줄 중 셋만 시험 경로다 — 그 목록 파일은 **까닭을 적은 주석**도
#         담는다. 그래서 줄 수는 ⚠️ 로만 보고 **경로를 하나씩** 묻는다.
#
#   ⑥ 🔴🔴 **기능 표식이 둘뿐이다 — 갈래는 셋인데.** 까닭을 값으로 적어 둔다.
#      [실측 2026-11-26 · 세 커밋의 diff 전문을 읽었다]
#        ㄴ 갈래(PO발행일) → **새 글자가 둘 있다. 둘 다 minify 를 견딘다:**
#            autoAdvancedOnPoIssuedDate  객체의 **칸 이름** — 기준 0 → 지금 3파일
#            NO_WAITING_REPAIR_STEP      **대문자 문자열 리터럴**(런타임 값) — 0 → 3
#        ㄱ 갈래(확정 단추) → 🔴 **번들에 가를 글자가 없다.** 더한 것은 함수 이름
#            (showDomesticOrderDueDateConfirmControls)과 지역 변수(visibleUnits)
#            뿐이고 **새 문자열 리터럴도 새 객체 칸 이름도 0개**다.
#        ㄷ 갈래(납품 요청일) → 🔴 **같은 까닭으로 없다.** 더한 것은 **이미 있던**
#            함수 셋을 부르는 import 줄뿐이다(resolveRepairCaseRequestedDueDate ·
#            dueDateBorrowerIds · loadDomesticOrderDueDatesByCaseId — 셋 다
#            기준판에 이미 있던 글자라 **아무것도 안 가른다**).
#      🔴 **export 이름을 기능 표식으로 쓰지 않았다** — 웹팩이 production 에서
#         export 이름을 짧게 줄인다(mangleExports). 71번이 **코드 줄에서 따온
#         글자가 번들에서 0/0** 이었던 그 자리와 같은 함정이다.
#      🔵 그래서 **ㄱ·ㄷ 갈래는 도구 이미지에서 가린다**(TOOLMARKS 가 **둘**이다) —
#         도구에는 소스가 **글자 그대로** 들어 있다. 71번이 포털에서, 62번이
#         계측기에서 똑같이 했다.
#      🔴🔴 **굽기 전이라 번들 수는 아직 못 쟀다.** 71번은 구운 뒤 열여덟을 다
#         세어 적었지만, 이 파일은 **한 번도 굽지 않았다 — 재기만 했다.** 아래
#         APPMARKS 의 수는 전부 **소스에서 센 값**이고, **번들 수는 --go 가 처음
#         찍는다.** 🔴 기능 표식이 0 으로 나오면 **이미지를 되돌리기 전에
#         --verify 로 다시 재고 이 머리말부터 보라**(검사 쪽이 틀릴 자리다).
#
#   ⑦ 🔴 **뒷걸음 표식이 아홉에서 열로 는다.**
#      71번이 기능 표식으로 쓴 **shareDocRelativePath** 는 어제 올라간 글자라
#      오늘은 「있다」가 **아무것도 안 가른다**(기준 36 → 지금 36)[실측].
#      **뒷걸음으로 내렸다.** 🔵 hasLiveApproval·faultTags·radiogroup 이 앞서
#      그랬던 것과 같은 내림이다.
#      🔴 **같은 기준으로 골랐다** — 71번의 기능 표식 셋 중 **객체의 칸 이름**이고
#         번들에서 가장 널리 잡히는 것이다(71번 실측 번들 23개). 🔵 나머지 둘
#         (DOMESTIC_ORDER_DUE_DATE_NEAR·_CONFIRMED)은 알림 종류 코드라 같은
#         갈래를 가리킨다 — 하나면 족하다.
#      🔴 **뒷걸음 열**(하나도 빼지 마라 — 한 번 빼면 다시 넣는 사람이 없다):
#          shareDocRelativePath          예순일곱째 · 기준 36 → 지금 36  ← **이번에 늘린 칸**
#          도번 / 비고                   예순여섯째 · 기준 1  → 지금 1   ← 🔴 **한글**
#          hasLiveApproval               예순네째   · 기준 4  → 지금 4
#          domesticOrders.completedEdit  예순세째   · 기준 12 → 지금 12
#          faultTags                     예순두째   · 기준 13 → 지금 13
#          radiogroup                    예순한째   · 기준 2  → 지금 2
#          "ORDER_ISSUED"                예순째     · 기준 2  → 지금 2
#          domestic-order-status-filter  쉰아홉째   · 기준 3  → 지금 3
#          portal_approval_delegations   쉰여덟째   · 기준 26 → 지금 26
#          domesticOrders.view           쉰여섯째   · 기준 17 → 지금 17
#      🔵 domesticOrders.completedEdit 이 71번의 「기준 11 → 지금 12」에서 **12 → 12**
#         가 됐다 — 71번이 그 판에서 한 장 늘렸고 그것이 이제 기준판에 들어 있다.
#      🔴🔴 **[도번 / 비고] 가 한글이다** — 71번이 데고 고친 자리다. 그 까닭과
#         실측값은 KO_MARKS 의 주석에 그대로 있고, **바이트 확인 절(1-ㄷ)**도
#         그대로 가져왔다.
#
#   ⑧ 🔴 **마지막 커밋 표식이 둘이다 — 집은 하나인데.**
#      71번은 「집마다 하나」라 둘이었다. 이번은 **한 집에 둘**이고 까닭이 다르다:
#      **번들이 못 가리는 갈래 둘**(ㄱ·ㄷ)을 도구에서 가리기 때문이다(머리말 ⑥).
#        · ㄱ : showDomesticOrderDueDateConfirmControls in
#               src/components/domestic-orders/DomesticOrderListScreen.tsx
#               [실측] 그 파일 안에서 기준 **0줄** → 지금 **4줄**
#        · ㄷ : resolveRepairCaseRequestedDueDate in
#               src/lib/db/queries/customer-portal.ts
#               [실측] 그 파일 안에서 기준 **0줄** → 지금 **3줄**
#               🔵 이것이 **마지막 커밋(3d32f5cb)의 과녁**이기도 하다.
#      🔴 **둘 다 기준판에도 있던 파일**이다 — 새로 생긴 파일을 과녁으로 삼으면
#         「기준 0줄」이 **파일이 없어서 0** 인 것이라 아무것도 안 가른다.
#      🔴 그래서 inside_check 의 도구 가지가 **TOOLMARKS 를 고리로 돈다**(71번은
#         row_by_key 로 **한 줄만** 꺼냈다 — 그대로 두면 두 줄이 이어 붙어 표식이
#         깨진다). 몇 개를 돌았는지 **끝에서 단언한다.**
#
#   ⑨ 🔴 **괄호·대괄호가 든 경로가 0장이다**(71번은 4장·5장). 🔴 **그래도 그 셈을
#      빼지 않는다** — 66번이 더했고 67번이 0 이었는데 안 빼서 68번의 [id] 를 잡았다.
#      🔴 **대신 글롭 함정의 실물을 잃는다.** 그래서 AS_KEY_FILES 에 **이번 범위
#         밖의 두 장**을 일부러 넣었다(괄호 하나 · 괄호+대괄호 하나) — 그 둘은
#         「바뀌었는가」를 재는 것이 아니라 **목록을 넘기는 길이 끊겼는가**를 재는
#         잣대다. 끊기면 그 둘이 **먼저** 사라진다.
#
# ── 돌리는 법 (개발 PC · PowerShell 에서 Git Bash 를 부른다) ──────────
#     cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#     & "C:\Program Files\Git\bin\bash.exe" ./72-build.sh --check
#     & "C:\Program Files\Git\bin\bash.exe" ./72-build.sh --go
#
#   🔴 **bash.exe 만 치면 WSL 이 잡힌다**(2026-11-04 에 걸렸다). WSL 에서 돌면
#      도커가 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 내어 ✗ 가 흩어져
#      난다. 단서는 로그의 뿌리 경로가 **/mnt/c/…** 인 것이다 — 0절이 값으로 잰다.
#   🔴 **스크립트에 건네는 경로에는 역슬래시를 쓰지 않는다.** 역슬래시를 주면
#      bash 가 그것을 먹어 "C:Users희만Desktop…" 이 되어 No such file 이 난다.
#
#   둘째 인자로 산출물을 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-72):
#     & "C:\Program Files\Git\bin\bash.exe" ./72-build.sh --go "/d/배포본/_images-72"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다.
#      이 파일을 쓴 쪽은 **한 번도 굽지 않았다** — 재기만 했다.
#
# ── 이번에 굽는 것 — **이미지 둘. 묶음은 없다** ──────────────────────
#     ① A/S 앱    dss-as:6.2       → dss-as:6.3          커밋 3
#     ② A/S 도구  dss-as-tools:29  → dss-as-tools:30     🔴 --target tools
#   🔴 **묶음이 없다**(위 「왜 없는가」 ①). A/S 도구의 /app/drizzle 은 여전히
#      **비어 있고**(5절이 값으로 잰다) 운영에서는 거기에 /volume1/dss/as-migrations
#      가 붙는다 — 이번 판은 **그 볼륨에 더할 .sql 이 없다.**
#   🔴 **나머지 여덟 집은 안 굽는다** — 이번 범위에 한 줄도 없다. 🔵 **포털도 그
#      여덟에 들어간다**(71번에서는 올라가는 집이었다).
#
# ── 🔴 태그 번호를 **지어내지 않았다** ────────────────────────────────
#   [실측 2026-11-26] nas/setup 의 **72번을 뺀 글롭**([0-9][0-9]-*.sh)을 훑어
#   dss-as 태그의 가장 큰 값이 **6.2**, dss-as-tools 의 가장 큰 값이 **29** 임을
#   값으로 확인했다(71-build.sh:415-416 의 IMAGES · 71-deploy.sh:384-385 의 TARS).
#   🔴 **자기 자신을 세면 늘 「이미 최신」이 된다** — 글롭에서 이 판을 빼라.
#
# ── 🔴 모드 셋 ────────────────────────────────────────────────────────
#   --verify 🔴 **이미 구운 둘을 다시 재기만 한다.** docker build 도 docker save 도
#            한 줄 안 돌린다. 🔴 6절의 기대값이 **뒤집힌다** — 태그가 **있어야** 한다.
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다(폴더도).
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면 멈춘다.
#            전부 ✓ 일 때만 **둘을 굽고** tar 로 뽑고 **이미지 안을 센다.**
#   🔵 세 모드가 **같은 함수**로 잰다(check_all · inside_check). 두 벌로 적으면 어긋난다.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 tar 크기를 **두 번** 견준다 ────────────────────────────────────
#   ① **지난 판 tar 와** 견준다(둘 다 값이 있다 — 아래 IMAGES 표 주석).
#   ② **그 이미지 자신과** 견준다. 가지가 둘이다:
#      · containerd 저장소면 inspect .Size 가 **압축된 내용 크기**라 90~110%.
#      · 고전 저장소면 **펼친 크기**라 tar 는 그 **1/4쯤**(10~45%).
#   🔴 **tar 지문은 'docker image inspect' 의 .Id 와 맞대지 않는다.** 그것은 애초에
#      다른 값이다. 맞댈 상대는 **빌드 로그의 'exporting config sha256:'** 이다.
#
# ── 🔴 이 환경의 함정 (36~71-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싼다. 저장소 자리를 적어
#      넣지 않고 **이 파일의 자리에서 계산한다**(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:/… 를 /c/… 로 바꾸고,
#      docker save 는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를 막는다).
#   ④ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다**가 이 판에는 **거짓**이다 —
#      뒷걸음 표식 하나가 한글이다([도번 / 비고]). 그래서 70번의 **바이트 확인
#      절(1-ㄷ)**이 그대로 있다. 까닭은 KO_MARKS 의 주석에 있다.
#   ⑤ 🔴 **이번 범위에는 괄호·대괄호가 든 경로가 0장이다**(머리말 ⑨). 그래도
#      목록을 넘기는 길은 **here 문서 + while read** 와 **grep -Fx** 로만 썼고,
#      컨테이너 안에서도 **set -f** 로 글롭을 끈다. **잣대 두 장**을 범위 밖에서
#      넣어 그 길이 살아 있는지 잰다.
#      🔵 대괄호 폴더의 시험이 조용히 안 돈 적이 이 저장소에 있다 — 거기서 온 규율이다.
#   ⑥ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」 같은
#      안전망을 달면 **하필 바라던 0 에서만** 그것이 터져 값이 "0 ?" 가 된다.
#      이 파일은 그 꼴을 **한 군데도 쓰지 않는다** — 「$( … || true )」 로 받는다.
#   ⑦ 🔴 **tar | grep -q 를 if 에 바로 물리지 않는다.** set -uo pipefail 아래서
#      grep -q 가 먼저 끝나면 앞의 tar 가 SIGPIPE 로 죽어 **파일이 있을 때 오히려
#      ✗** 가 난다. 🔵 이 판은 **tar 를 읽는 자리가 아예 없다**(묶음이 없다).
#   ⑧ 🔴 **CRLF.** 이 저장소들의 작업본은 전부 CRLF 다. Git Bash 의 grep 만 \r 를
#      걷어내고 리눅스 컨테이너의 GNU grep 은 안 걷어낸다. 줄 전체로 맞대는
#      검사(-Fx)는 **읽자마자 tr -d 로 \r 를 걷어낸 뒤** 맞댄다.
#   ⑨ 🔴 **빈 결과는 삼켜진 오류일 수 있다.** 목록을 읽는 자리는 **읽은 줄 수를
#      함께 받아** 너무 적으면 ✗ 로 세고, **없는 경로 하나를 일부러 함께 묻는다.**
#   ⑩ 🔴 **bash 의 $(( )) 는 0 으로 시작하는 수를 8진수로 읽는다** — 0133·0134 를
#      셈에 넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
#   ⑪ 🔴 **Git Bash 가 docker.exe 에 넘기는 「/ 로 시작하고 빈칸 없는」 인자를
#      윈도우 경로로 번역한다.** [실측 2026-11-18] 그것 하나로 **가짜 ✗ 일곱**이 났다.
#      처방 셋을 **다 쓴다**: dockr() 로 **docker 를 부를 때만** 끄고 ·
#      **그것이 정말 꺼졌는지 값으로 재고**(1-ㄴ) · 파일 경로는 **상대로 넘긴다.**
#      🔴 **전역 export 로 끄면 git 이 깨진다 — 실제로 깨뜨려 봤다**(✗ 스물한 개).
#   ⑫ 🔴 **stdin 을 빨아들이는 명령을 고리 안에서 부르면 고리가 한 바퀴만 돈다.**
#      처방 둘을 **함께**: **-i 를 떼고**, **함수 정의에 </dev/null 을 붙인다.**
#      🔴 그리고 **「몇 개를 봤는가」를 고리마다 세어 끝에서 단언한다.**
#      🔵 이번 판은 집이 하나라 「한 바퀴만 돌아도」 티가 안 난다 — 🔴 **그래서
#         관문을 더 꼼꼼히 남겼다.** 집이 둘이 되는 날 그 관문이 일한다.
#   ⑬ 🔴 **기대값이 틀릴 확률이 배포만큼 높다.** ✗ 가지마다 doubt() 가 「검사를
#      먼저 의심하라」를 찍는다. ✓ 쪽 오판은 **영영 안 드러난다.**
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

# 🔵 **count_test_paths() 가 없다** — 그것은 **포털 전용**이었다(package.json 의
#    「test」 줄에 경로를 나열하는 방식을 세는 함수). 이 판에는 포털이 없다.
#    🔴 포털이 다시 올라가는 판에서는 **71-build.sh:386-388 에서 되살려라** —
#       A/S 의 목록 파일 방식으로 착각해 그 절을 빼면 그 집의 시험 등록이
#       **아무 검사도 안 받는다.**

# ══════════════════════════════════════════════════════════════════════
# ══ 이번 판의 값 — 한자리에 모아 둔다 ═════════════════════════════════
# ══════════════════════════════════════════════════════════════════════
#
# ── 🔴 저장소 **하나** (71번의 REPOS 표 꼴을 그대로 두고 줄만 줄였다) ──
#   열쇠|폴더|사람이 부르는 이름|기준 SHA|기준→main 커밋 수|개발 포트|public 이 있나
#   🔴 기준 SHA 의 출처:
#      A/S   56effcc8  예순일곱째(71번)가 올린 마지막 커밋 — 「[현황판] 「배포는
#                      A/S 하나로 끝난다」를 바로잡는다」[실측으로 확인했다]
#   🔴 **포털(dss-auth)은 이 표에 없다** — 이번 범위에 한 줄도 없다(808d496 그대로).
#      까닭과 되살리는 법은 머리말의 「왜 없는가」 ④ 에 적어 두었다.
#   🔵 **표 꼴은 71번 그대로다** — 집이 다시 둘이 되는 날 줄만 더하면 된다.
REPOS='
as|RF_Service_System|A/S관리|56effcc8|3|3000|yes
'
REPOS_WANT=1
# 🔵 DB 는 dss-pg-app(5442) · dss-pg-auth(5444)가 개발 PC 에 떠 있다. 🔴 **끄지
#    않는다** — 이 파일은 DB 에 한 번도 안 붙는다(개발 PC 에서는 운영 DB 를 못 본다).
#    🔵 5444(포털 DB)는 **이번 판이 안 건드리는 집**의 것이다 — 그래도 찍어 둔다.
DB_PORTS='5442 5444'
# 🔴 7-ㄴ 의 관문이 보는 수 — 저장소 1 + DB 2 = **3**. 71번은 4 였다(집이 둘).
PORTS_WANT=3

# ── 🔴 굽는 **둘** (71번의 행 꼴 — 저장소 칸이 둘째다) ────────────────
#   열쇠|저장소폴더|새 태그|타깃(-=기본 runner)|지난판 tar 이름|지난판 tar 바이트|엄함
#   🔴 지난판 바이트의 출처는 아래에 적어 두었다.
#   🔵 엄함: strict = 25% 넘으면 ✗ · loose = 25% ⚠️ · 60% 넘으면 ✗ · none = 건너뛴다
#   🔴 **둘 다 strict 다** — [실측] 의존성 파일이 **한 장도 안 바뀌었다**(5-ㄷ).
IMAGES='
as|RF_Service_System|dss-as:6.3|-|dss-as-6.2.tar|136900096|strict
astools|RF_Service_System|dss-as-tools:30|tools|dss-as-tools-29.tar|227168256|strict
'
HOWMANY=2
# 🔴 **태그 번호를 지어내지 않았다.** 읽은 자리:
#    dss-as:6.2 · dss-as-tools:29       → 71-build.sh:415-416 (IMAGES)
#    지난판 바이트 136900096 · 227168256 → 71-deploy.sh:384-385 (TARS · 구운 뒤 채운 값)
#    🔵 [실측 2026-11-26] nas/setup 의 **72번을 뺀 글롭**([0-9][0-9]-*.sh)을 훑어
#       dss-as 의 가장 큰 태그가 **6.2**, dss-as-tools 가 **29** 임을 값으로 확인했다.
#       🔴 **자기 자신을 세면 늘 「이미 최신」이 된다.**

# ── 🔴 마이그레이션 — **0건** ────────────────────────────────────────
#   🔴 **134 에서 한 칸도 안 움직인다.** 71번이 0132·0133 을 올려 134 가 됐고,
#      이번 범위는 drizzle/ 을 **0줄** 건드렸다[실측 2026-11-26].
AS_SQL_WANT=134
AS_SQL_WAS=134
AS_DRIZZLE_DIFF_WANT=0
#   🔴 「생기면 안 되는 것」은 **0134** 다. 🔵 번호를 **글자로** 적어 글자로 맞댄다
#      — $(( )) 는 0 으로 시작하는 수를 8진수로 읽는다.
AS_NEXT_MIG=0134
#   🔴 **「없다」만 재면 번호가 빗나가도 통과한다** — 반대쪽 「있는가」를 같은 줄에서
#      함께 센다. 70번이 AS_NEXT_MIG 가 한 칸 빗나가 **두 판 연속 아무것도 안 막은**
#      것을 잡아낸 뒤로 생긴 규율이다.
AS_LAST_MIG=0133
# 🔵 **운영이 지금 들고 있어야 하는 수** — 개발 PC 에서는 못 잰다. 72-deploy.sh 가
#    DB 에 물어 확인하고, **바뀌었으면 거기서 멈춘다.** 여기서는 찍어 두기만 한다.
PROD_MIGS_NOTE='A/S 134(그대로) · 재고 28 · 휴가 5 · 포털 11 · 계측기 3 — **다섯 집 다 안 바뀐다**'
#
# 🔴🔴 **여기에 있던 것이 71번에는 더 있었다 — 왜 없는지 머리말 ①②에 적어 두었다:**
#    AS_NEW_MIGS · AS_NEW_MIGS_WANT · AS_ADDCOL_WANT · AS_KEEP_MIGS(창 안 일곱) ·
#    DESTRUCTIVE_RE · SQL_COMMENT_RE · MIG_DROP_WANT · MIGTAR.
#    🔴 **.sql 이 한 장이라도 생기는 판에서는 71-build.sh 에서 그 여덟을 통째로
#       되살려라.** 그중 DESTRUCTIVE_RE 의 **표본 일곱**(4-ㄱ)을 빠뜨리면
#       「지우는 문장 0줄」이 **아무것도 안 재는 ✓** 가 된다.

# ══ 🔴 서브모듈 — **이번 판은 안 움직인다** ═══════════════════════════
#   [실측 2026-11-26] dss-core **191676f 그대로** · dss-ui **1210d112 그대로**.
#   🔴 **뜻이 71번과 뒤집혔다**(머리말 ③) — 71번은 「움직였는가」를 쟀고, 이 판은
#      「**뒷걸음치지 않았는가**」를 잰다. 재는 값은 거의 같고 판정만 다르다.
#   🔴 **README.md:558 의 옛 핀 b79e5ab8 은 낡았다** — 그것은 쉰여덟째(62번) 때
#      값이다. 예순두째(66번)가 1e9ec85 로, 예순일곱째(71번)가 191676f 로 옮겼다.
#      (README 를 고치는 것은 배포가 끝난 뒤의 일이라 이 조각은 안 건드렸다.)
AS_CORE_PIN=191676fa65fe7dfe285c21d6926c4d47a75d3a59
# 🔴 **예순여섯째까지의 핀.** 지금 핀이 이 값이면 **71번이 되감긴 것**이다.
AS_CORE_PREV_PIN=1e9ec85535a2718901879639dd4dd3557d8af357
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425
# 🔵 작업본이 **그 핀 위에** 서 있어야 한다 — 핀보다 앞서 있으면 안 올라간 커밋을 굽는다.
AS_CORE_COMMITS_WANT=0
# 🔴 예순여섯째 핀 → 지금 핀 사이의 커밋 수 · 바뀐 파일 수.
#    🔵 **71번이 움직인 폭**이고, 그것이 **아직 그대로인지**를 값으로 보인다.
AS_CORE_MOVED_COMMITS=2
AS_CORE_MOVED_FILES=3
# 🔴 **핀만 보면 빈 서브모듈도 통과한다** — 쉰여덟째가 올린 것이 거기 있는지 함께 본다.
AS_CORE_KEEP_FILE=src/schema/portal-approval-delegations.ts
AS_CORE_KEEP_TABLE=portal_approval_delegations
AS_CORE_KEEP_EXPORT=portal-approval-delegations
# 🔴 **예순일곱째가 그 안에 더한 것 — 파일 셋에 칸 넷**(머리말 ③ · 「왜 없는가」 ③).
#   파일|DB 칸 이름|속성 이름
#   🔴 넷을 **다** 본다. 하나만 보면 「세 갈래 중 하나만 담긴 공용 스키마」를 못 가른다.
#   🔵 이 판에서 이 표의 뜻은 「**이번에 더했다**」가 아니라 「**아직 있다**」다 —
#      서브모듈이 되감긴 채로 구우면 어제 올린 기능이 조용히 사라진다.
AS_CORE_NEW='
src/schema/domestic-order-due-dates.ts|confirmed_at|confirmedAt
src/schema/domestic-order-due-dates.ts|confirmed_by|confirmedBy
src/schema/procedure-template-nodes.ts|share_doc_relative_path|shareDocRelativePath
src/schema/repair-case-flowchart-nodes.ts|share_doc_relative_path|shareDocRelativePath
'
AS_CORE_NEW_WANT=4

# ══ 🔴 바뀐 파일 수 — [실측 2026-11-26 · 기준 56effcc8] ═══════════════
#   열쇠|전체|src/|scripts/|drizzle/|vendor+.gitmodules|새 파일|지운 파일|괄호|대괄호|시험
#   🔴 **71번과 한 자리도 같지 않다**(머리말 ④).
#   🔵 **17 + 2 = 19** 라 덮기가 딱 맞는다 — 71번과 달리 어느 COPY 에도 안 걸리는
#      장이 **하나도 없다**(71번에는 저장소 뿌리의 진행현황 HTML 이 있었다).
#   🔵 scripts/ 둘은 시험 목록 파일이다(unit.txt · db.txt).
#   🔴 **괄호도 대괄호도 0장이다**(머리말 ⑨). 🔴 **그래도 그 셈을 빼지 않는다** —
#      67번이 0 이었는데 안 빼서 68번의 [id] 를 잡았다.
CHANGED='
as|19|17|2|0|0|5|0|0|0|8
'
CHANGED_WANT=1

# ══ 🔴 npm 명령 수 — [실측 2026-11-26] ════════════════════════════════
#   열쇠|기준|지금
#   🔴 「안 걸린다」도 **값으로 잰다.** 바뀌었는데 안 적어 두면 다음 판이 그 거짓을
#      근거로 「안 구워도 된다」를 꺼낸다(41번이 Missing script 로 데였다).
NPMCOUNT='
as|39|39
'
NPMCOUNT_WANT=1

# ══ 🔴 **도구를 굽는 까닭** — 값으로 가린다 ═══════════════════════════
#   ㄴ) tools 스테이지가 담는 것 중 바뀐 파일 수.
#      🔴 A/S 는 **19 중 19** — 빠지는 것이 **하나도 없다**(src/ 17 + scripts/ 2).
#         🔵 71번은 179 중 173 이었다(drizzle/ 다섯과 뿌리의 HTML 한 장이 빠졌다).
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
payload_re() { # 1 집 열쇠
  case "$1" in
    as)   printf '%s' "$AS_PAYLOAD_RE" ;;
  esac
}
TOOLS_PAYLOAD='
as|19
'
TOOLS_PAYLOAD_WANT=1
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
as|^COPY .*scripts \./scripts|yes|A/S tools 가 scripts/ 를 담는다 (바뀐 시험 목록 2장이 여기다)
as|^COPY .*src \./src|yes|🔴 A/S tools 가 src/ 를 담는다 — 바뀐 17장이 전부 여기다
as|^COPY .*vendor \./vendor|yes|🔴 A/S tools 가 vendor/ 를 담는다 — 🔵 **이번 판은 그 안이 안 바뀌었다**(3-ㄴ)
as|^COPY .*drizzle \./drizzle|no|🔴 A/S tools 는 drizzle/ 을 **안 담는다** — 볼륨이 정본이다(이번 판은 거기에 더할 것이 0건)
'
COPYRULES_WANT=4

# ══ 🔴 앱 번들에서 쓸 표식 — **전부 리터럴 · 하나는 한글** ════════════
#   열쇠|갈래(feature|keep|side)|글자|사람이 읽을 말
#   🔴 **공백이 든 표식이 있고 하나는 한글이다**(도번 / 비고).
#      그래서 이 표는 tr -d ' ' 로 읽지 않고 **here 문서 + IFS='|' read** 로만 읽는다.
#   🔴 **표식에 | 가 든 것은 하나도 없다**[값으로 확인] — 정규식을 이 꼴의 표에
#      넣었다가 깨진 자리가 따로 있다(TOOLS_PAYLOAD 의 주석).
#
#   🔴🔴 **기능 표식을 「코드 줄」에서 따오지 않았다** — minify 가 지역 이름을 갈아
#      치우고, 웹팩이 production 에서 **export 이름까지 줄인다**(mangleExports).
#      71번이 그 함정에 데었다: part.drawingNo, part.note 가 소스에는 1줄인데
#      **번들에서는 0/0** 이었다. 🔴 그래서 고른 것은 **둘뿐**이고 둘 다 꼴이 다르다:
#        autoAdvancedOnPoIssuedDate  — 객체의 **칸 이름**(minify 는 칸 이름을 기본으로
#                                      안 건드린다 — 건드리면 JSON 과 어긋난다)
#        NO_WAITING_REPAIR_STEP      — **대문자 문자열 리터럴**(런타임 값이라 코드에
#                                      그대로 남는다. 타입 union 이 아니라 실제로
#                                      reason: "NO_WAITING_REPAIR_STEP" 으로 쓰인다)
#   🔴🔴 **기능 표식이 둘뿐인 까닭** — 갈래는 셋인데 ㄱ·ㄷ 갈래가 번들에 **새 글자를
#      한 개도 안 남긴다**(머리말 ⑥). 그 둘은 **도구 이미지**에서 가린다(TOOLMARKS).
#      🔴 **그래서 「기능 표식이 ✓ 니까 세 갈래가 다 담겼다」가 거짓이다.** 도구
#         이미지의 TOOLMARKS 둘이 ✓ 여야 세 갈래가 다 담긴 것이다.
#
#   🔴🔴 **아래 수는 전부 「소스에서 센 값」이다 — 번들 수가 아니다.**
#      71번은 구운 뒤 열여덟을 번들에서 다 세어 적었지만, 이 파일은 **한 번도 굽지
#      않았다 — 재기만 했다.** 🔴 --go 가 번들 수를 **처음** 찍는다. 그때 기능 표식이
#      0 으로 나오면 **되돌리기 전에 --verify 로 다시 재고 이 주석부터 보라.**
#      🔵 71번이 번들에서 실제로 센 값 중 이 판에도 쓰는 것(참고):
#        shareDocRelativePath 23 · 도번 / 비고 2 · hasLiveApproval 3 ·
#        domesticOrders.completedEdit 5 · faultTags 19 · radiogroup 5 ·
#        "ORDER_ISSUED" 2 · domestic-order-status-filter 2 ·
#        portal_approval_delegations 23 · domesticOrders.view 8
#        🔴 **뒷걸음 열 중 아홉이 번들에서 ≥1 임이 이미 확인돼 있다.** 새로 올라온
#           shareDocRelativePath 도 71번이 **23개**로 세어 두었다.
#
#   🔴 feature = 기준 0 → 지금 1 이상이어야 한다(안 그러면 아무것도 안 가른다)
#      keep    = 기준에도 지금에도 1 이상이어야 한다(뒷걸음을 재는 자리)
#      side    = 🔵 **판정에 안 쓴다.** 값만 찍는다.
APPMARKS='
as|feature|autoAdvancedOnPoIssuedDate|🔴 ㄴ갈래 PO발행일→[수리 대기] — 기준 0 → 지금 3파일 (이력 metadata 의 **객체 칸 이름**)
as|feature|NO_WAITING_REPAIR_STEP|🔴 ㄴ갈래 같은 자리 — 기준 0 → 지금 3파일 (**대문자 문자열 리터럴** · 런타임 값이다)
as|side|PO_ISSUED_REPAIR_WAITING_METADATA|🔵 곁들이 — 그 상수의 **export 이름**. 기준 0 → 지금 4파일. 🔴 번들 판정에 안 쓴다(mangleExports 가 줄인다)
as|side|showDomesticOrderDueDateConfirmControls|🔵 곁들이 — ㄱ갈래의 함수 이름. 기준 0 → 지금 4파일. 🔴 번들 판정에 안 쓴다(도구에서 가린다)
as|keep|shareDocRelativePath|예순일곱째가 올린 칸 이름 — 기준 36 → 지금 36파일 (🔵 71번의 기능 표식이 뒷걸음으로 내려왔다)
as|keep|도번 / 비고|🔴 **한글**. 예순여섯째가 올린 placeholder 꼬리 — 소스 기준 1 → 지금 1파일 · 71번 실측 번들 server 1 · static 1
as|keep|hasLiveApproval|예순네째가 올린 프롭 이름 — 기준 4 → 지금 4파일
as|keep|domesticOrders.completedEdit|예순세째가 올린 권한 열쇠 — 기준 12 → 지금 12파일
as|keep|faultTags|예순두째가 올린 칸 이름 — 기준 13 → 지금 13파일
as|keep|radiogroup|예순한째가 올린 DOM 속성 값 — 기준 2 → 지금 2파일
as|keep|"ORDER_ISSUED"|예순째가 올린 상태 값 — 기준 2 → 지금 2파일
as|keep|domestic-order-status-filter|쉰아홉째가 올린 DOM id — 기준 3 → 지금 3파일
as|keep|portal_approval_delegations|쉰여덟째가 올린 글자 — 기준 26 → 지금 26파일
as|keep|domesticOrders.view|쉰여섯째가 올린 권한 열쇠 — 기준 17 → 지금 17파일
'
# 🔴 기능 2 + 곁들이 2 + 뒷걸음 10 = **14** (71번은 집이 둘이라 18 이었다)
MARKS_WANT=14
#   🔴 갈래별로도 센다 — 표가 깨져 한 갈래가 통째로 빠지는 것을 막는다.
MARKS_FEATURE_WANT=2
MARKS_KEEP_WANT=10
MARKS_SIDE_WANT=2
# 🔴 번들에서 **판정에 쓰는** 표식 수(기능 + 뒷걸음) — inside_check 의 관문이 쓴다.
#    🔵 71번은 A/S 12 · 포털 3 이었다. 이 판은 A/S 하나뿐이고 **12** 로 같다
#       (기능이 하나 줄고 뒷걸음이 하나 늘었다).
MARKS_JUDGE_WANT=12

# ══ 🔴🔴 **한글 표식 — 이 판에도 하나 있다** (70→71 에서 그대로 가져왔다) ══
#   🔴 **71번의 첫 --go 에서 ✗ 가 났던 자리다. 그 까닭을 그대로 적어 둔다 —**
#      **이 판도 같은 글자를 뒷걸음 표식으로 쓰기 때문이다.**
#      71번은 처음에 예순여섯째의 뒷걸음 표식으로 **part.drawingNo, part.note** 를
#      썼다. 「표식은 전부 ASCII」라는 규율을 지키려고 70번의 한글 대신 **같은
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
#                        **dss-as:6.2** server 1 · static 1 → **뒷걸음을 잴 수 있다.**
#      🔵 **이 판은 dss-as:6.3 에서 같은 값이 나와야 한다** — 그 placeholder 를
#         건드린 커밋이 이번 범위에 **0장**이다[실측 · 5-ㅂ 이 소스에서 1→1 로 잰다].
#   🔴 **그래서 「이 파일의 표식은 전부 ASCII」가 이 판에도 거짓이다** — 머리말의
#      그 줄을 그대로 고쳐 두었다. 70번의 **바이트 확인 절(1-ㄷ)**도 그대로다:
#      한글을 컨테이너로 보내고 **되돌려 받아 글자와 바이트 수를 맞댄다.**
#      「한글을 HTTP 머리말·argv 에 넣으면 요청이 아예 안 나간다」가 이 저장소에
#      적혀 있어, 70번이 그 자리에 세워 둔 울타리다.
#      [실측 2026-11-25 · dss-as:6.2] 보낸 [도번 / 비고] **15바이트** → 받은 15바이트 ·
#                                      보낸 [재고 관리에서 찾기] **26바이트** → 받은 26바이트.
#      🔵 70번이 2026-11-20 에 잰 값과 **같다.** 🔴 이 판에서도 **같은 15·26 이
#         나와야** 한다 — 바이트 수는 글자가 안 바뀌는 한 안 바뀐다.
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

# ══ 🔴🔴 도구 이미지에서 쓸 표식 — **한 집에 둘이다** ═════════════════
#   열쇠|표식|그 표식이 있어야 하는 파일|기준 줄 수|지금 줄 수
#   🔴 **71번은 「집마다 하나」라 둘이었다. 이 판은 「한 집에 둘」이고 까닭이 다르다** —
#      **번들이 못 가리는 갈래 둘**(ㄱ·ㄷ)을 여기서 가린다(머리말 ⑥·⑧).
#      도구 이미지에는 소스가 **글자 그대로** 들어 있어 minify 를 안 탄다.
#   🔴 **과녁 둘 다 기준판에도 있던 파일**이다 — 새로 생긴 파일을 과녁으로 삼으면
#      「기준 0줄」이 **파일이 없어서 0** 인 것이라 아무것도 안 가른다.
#      (po-issued-repair-waiting.ts 는 **새 파일**이라 과녁으로 안 썼다.)
#   🔵 둘째(customer-portal.ts)가 **마지막 커밋 3d32f5cb 의 과녁**이기도 하다.
#   🔴 **inside_check 가 이 표를 고리로 돈다** — 71번은 row_by_key 로 **한 줄만**
#      꺼냈다. 그대로 두면 두 줄이 이어 붙어 표식이 통째로 깨진다.
TOOLMARKS='
astools|showDomesticOrderDueDateConfirmControls|src/components/domestic-orders/DomesticOrderListScreen.tsx|0|4
astools|resolveRepairCaseRequestedDueDate|src/lib/db/queries/customer-portal.ts|0|3
'
TOOLMARKS_WANT=2
# 🔴 도구 이미지 하나가 **몇 개를 돌아야 하는가** — 고리가 한 바퀴만 돌면 잡힌다.
TOOLMARKS_PER_IMAGE_WANT=2
# 🔴 그 표식이 가리키는 **짝 파일**도 이미지에 있어야 한다 — 없으면 화면이
#    import 에서 죽는다. 열쇠|파일
#    🔵 넷째 줄은 ㄴ 갈래의 짝이다 — 번들 표식이 가리키는 모듈을 **부르는 쪽**이다.
TOOLMARK_PAIRS='
astools|src/lib/domain/domestic-order-completed-edit-access.ts
astools|src/lib/domain/requested-due-date-link.ts
astools|src/lib/db/queries/repair-case-domestic-order-due-dates.ts
astools|src/lib/db/mutations/po-issued-repair-waiting.ts
'
TOOLMARK_PAIRS_WANT=4

# ══ 🔴 public/ 기대값 ═════════════════════════════════════════════════
#   열쇠|기대(yes|no)|이미지 안 파일 수(참고 · 판정에 안 쓴다)
#   🔵 [실측 2026-11-26 · 작업본] A/S 9개.
PUBLIC_WANT='
as|yes|9
'
PUBLIC_WANT_N=1

# ══ 🔴 **핵심 파일 표본** — 도구 이미지가 담고 있어야 한다 ════════════
#   🔵 이번 범위는 **19장**이라 전부 넘겨도 되지만, 71번의 꼴을 그대로 두고
#      **열두 장**을 고른다 — 세 갈래가 **각각 몇 장씩** 들어 있는지 눈에 보이게.
#   🔴🔴 **끝의 두 장은 이번 범위 밖이다 — 일부러 그렇다.**
#      이번 범위에는 **괄호도 대괄호도 든 경로가 0장**이라(머리말 ⑨) 글롭 함정의
#      실물이 사라졌다. 그래서 **범위 밖에서 두 장**을 끌어왔다:
#        src/app/(app)/domestic-orders/page.tsx   ← 괄호
#        src/app/(app)/customers/[id]/page.tsx    ← 괄호 **그리고** 대괄호
#      🔴 그 둘은 「바뀌었는가」를 재는 것이 **아니다** — **목록을 넘기는 길이
#         끊겼는가**를 재는 잣대다. 끊기면 그 둘이 **먼저** no 로 떨어진다.
#      🔵 대괄호 폴더의 시험이 조용히 안 돈 적이 이 저장소에 있다 — 거기서 온 규율이다.
#   🔴 **없는 경로 하나를 함께 묻는다** — 「무조건 yes」인 검사인지 가른다.
PROBE_MISS=src/__dss_probe_no_such_file__.ts
AS_KEY_FILES='
src/lib/domain/po-issued-repair-waiting.ts
src/lib/db/mutations/po-issued-repair-waiting.ts
src/lib/db/mutations/domestic-order-issue-dates.ts
src/lib/db/mutations/domestic-orders.ts
src/lib/domain/domestic-order-completed-edit-access.ts
src/components/domestic-orders/DomesticOrderListScreen.tsx
src/lib/db/queries/customer-portal.ts
src/lib/db/queries/repair-case-domestic-order-due-dates.ts
src/lib/domain/customer-portal-forms.ts
src/components/customer-portal/CustomerPortalScreen.tsx
src/app/(app)/domestic-orders/page.tsx
src/app/(app)/customers/[id]/page.tsx
'
AS_KEY_FILES_WANT=12

# ══ 🔴 시험 등록 — **A/S 는 목록 파일 방식이다** ══════════════════════
#   🔴 **적어야 돈다** — scripts/test-lists/*.txt 에 경로를 적지 않으면 그 시험은
#      **오류 없이 조용히 안 돈다.**
#   🔴 그 파일들은 **CRLF** 라 \r 를 걷고 -Fx 로 줄 전체를 맞댄다.
#   🔴 **71번에 있던 ㄴ) 포털 절(package.json 의 test 줄)은 없다** — 까닭과 되살리는
#      법은 머리말의 「왜 없는가」 ④ 에 적어 두었다. **글롭 방식인 저장소에서**
#      **베끼면 이 절이 통째로 없어진다**는 경고도 거기 그대로 있다.
AS_TESTLIST_MIN_LINES=4000
#   🔵 **빈 줄을 뺀 수**다(grep -c . 로 센다). [실측 2026-11-26]
#      unit 2226→2236 · components 1908→1908 · db 639→670 · db-safety 14→14
AS_TESTLIST_LINES_WANT=4828
AS_TESTLIST_LINES_WAS=4787
AS_NEW_TESTS_WANT=3
AS_TESTLIST_FILES='
scripts/test-lists/unit.txt
scripts/test-lists/components.txt
scripts/test-lists/db.txt
scripts/test-lists/db-safety.txt
'
AS_TESTLIST_FILES_WANT=4
#   🔴 **새로 생긴 시험 셋** — 이것이 「등록돼 있는가」의 표본이다.
#      [실측 2026-11-26] 셋 다 목록 파일에 **1줄씩** 적혀 있다.
#   🔵 **이번 셋에는 대괄호가 든 경로가 없다.** 71번에는 하나 있었고, 그 줄은
#      목록 파일에 **별표로** 적혀 있었다(App Router 의 [id] 를 그대로 적으면
#      node 가 글롭 문자클래스로 읽어 「tests 0」 으로 지나간다 —
#      그 저장소의 scripts/run-test-list.mjs 머리말).
#      🔴 **대괄호가 든 시험이 다시 생기면 여기에는 「목록에 적힌 꼴」(별표)을**
#      **적어야 한다.** 실제 경로를 적으면 멀쩡한 등록이 **가짜 ✗** 가 된다.
#      🔵 AS_KEY_FILES 는 반대다 — 거기는 이미지 안에서 [ -f ] 로 묻는 자리라
#         **실제 경로(대괄호)**를 적어야 한다. 두 표가 같은 파일을 **다른 꼴**로
#         들고 있는 것이 맞다.
AS_NEW_TESTS='
src/lib/db/mutations/po-issued-repair-waiting.integration.test.ts
src/lib/db/queries/customer-portal-requested-due-date.integration.test.ts
src/lib/domain/po-issued-repair-waiting.test.ts
'
#   🔵 **바뀐 8장 중 새것이 아닌 5장**은 표로 안 적고 **git 에서 그 자리에서 뽑아**
#      한 장씩 묻는다 — 손으로 적으면 한 줄만 틀려도 ✗ 가 흩어진다.
#      🔴 대신 **뽑은 수를 단언한다**(8 − 3 = 5). 안 그러면 0장을 묻고 ✓ 가 된다.
AS_OLD_TESTS_WANT=5

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-72"; fi
# 🔵 **묶음 자리(MIGTAR)가 없다** — 이번 판은 묶음을 안 만든다(머리말 「왜 없는가」 ①).
#    🔴 마이그레이션이 생기는 판에서는 **71-build.sh 에서 되살려라.**

case "$MODE" in
  --check|--go|--verify) ;;
  *) printf '쓰는 법: %s [--check|--go|--verify] [산출물폴더]\n' "$0"; exit 2 ;;
esac

printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' " 72-build.sh — 예순여덟째 배포 · 이미지 굽기 ($MODE)"
printf '%s\n' "   저장소 뿌리 : $DEV"
printf '%s\n' "   산출물 자리 : $OUT"
printf '%s\n' "   굽는 것     : 이미지 $HOWMANY (A/S 앱·도구) · 🔵 **묶음 없음**"
printf '%s\n' "   마이그레이션: 🔵 **0건** (저장소도 운영도 $AS_SQL_WANT 장 그대로)"
printf '%s\n' "   서브모듈    : 🔵 **안 움직인다** (dss-core · dss-ui 둘 다 그대로)"
printf '%s\n' "   🔵 **포털은 이번에 「안 건드리는 집」으로 되돌아갔다** (71번에서는 올라갔다)"
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
COREDIR="$ASD/vendor/dss-core"
UIDIR="$ASD/vendor/dss-ui"

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
    say "       & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./72-build.sh $MODE"
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
    say "         & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./72-build.sh $MODE"
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
      say "      🔵 **71번에 실제로 그 일이 있었습니다** — 지시서는 50커밋이었고 재 보니"
      say "         51 이었습니다. 더 밀린 한 커밋이 진행현황 HTML 한 장짜리라 **이미지에**"
      say "         **아무 자취도 안 남겼습니다.**"
      say "      🔴 **이번 범위에는 그런 「자취 없는 커밋」이 한 장도 없습니다** — 셋이"
      say "         전부 src/ 와 scripts/ 를 건드립니다. 그래서 커밋이 늘면 **5-ㅁ 의**"
      say "         **파일 수도 거의 반드시 함께 어긋납니다.**"
      say "      🔴 **표식·파일 수 기대값이 전부 그 범위에서 나온 값**입니다 —"
      say "         5-ㅁ 이 함께 어긋나면 **거기서 멈추고 사람에게 알리세요.**"
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

# ── 3. 🔴 서브모듈 — **「안 움직였다」를 값으로 잰다** ────────────────
step "3. 🔴 서브모듈 — **이번 판은 안 움직인다.** 뒷걸음을 안 쳤는지 잰다"
say "🔴 **71번과 뜻이 뒤집힌 절입니다**(머리말 ③) — 71번은 「움직였는가」를 쟀고"
say "   이 판은 「**되감기지 않았는가**」를 잽니다. 재는 값은 거의 같고 판정이 다릅니다."
say "🔴 [실측 2026-11-26] dss-core **${AS_CORE_PIN:0:8} 그대로** · dss-ui **${UI_PIN:0:8} 그대로**."
say "🔵 예순여섯째까지의 핀은 ${AS_CORE_PREV_PIN:0:8} 였고, 예순일곱째가 거기서 커밋 $AS_CORE_MOVED_COMMITS ·"
say "   파일 $AS_CORE_MOVED_FILES 만큼 옮겨 지금 자리가 됐습니다."
say "🔴 **README.md:558 의 옛 핀(b79e5ab8)을 베끼지 마세요** — 그것은 쉰여덟째 때"
say "   값입니다. 예순두째가 ${AS_CORE_PREV_PIN:0:8} 로, 예순일곱째가 ${AS_CORE_PIN:0:8} 로 옮겼습니다."
say "🔴 핀 글자가 맞아도 **안이 비어 있을 수 있습니다** — 3-ㄷ 이 안의 파일을"
say "   값으로 세고, **예순일곱째가 더한 칸 넷이 아직 있는지**까지 봅니다."
ASD="$DEV/$(field "$(row_by_key "$REPOS" as)" 2)"
COREDIR="$ASD/vendor/dss-core"
UIDIR="$ASD/vendor/dss-ui"
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
say "── 3-ㄱ. 핀 값 — 🔵 **둘 다 그대로여야 한다** (서브모듈 둘을 본다)"
check_pin "$ASD"   vendor/dss-core "$AS_CORE_PIN" "🔵 예순일곱째가 올린 핀 — **이번 판은 안 움직인다**"
check_pin "$ASD"   vendor/dss-ui   "$UI_PIN"      "🔵 A/S — 안 움직였다"
[ "$SUB_SEEN" = "2" ] && ok "서브모듈 핀 둘을 다 봤다 (표본이 비지 않았다)" \
  || bad "서브모듈 핀을 ${SUB_SEEN}개만 봤다 — 2개를 기대했다"
say "      🔵 71번은 여기가 **셋**이었습니다(포털의 vendor/dss-ui 가 더 있었습니다)."
# 🔴 **뒷걸음치지 않았는가**를 따로 묻는다 — 위의 ✓ 는 「적어 둔 값과 같다」일
#    뿐이고, 적어 둔 값 자체를 잘못 베껴 왔으면 그 ✓ 가 **옛 핀을 통과시킨다.**
#    🔴 **71번과 뜻이 뒤집힌 자리다**(머리말 ③) — 거기서는 「옛 핀이면 안 움직인
#       것」이었고, 여기서는 「옛 핀이면 **어제 올린 것이 되감긴 것**」이다.
cp0=$(pin_of "$ASD" vendor/dss-core)
say "dss-core 핀: ${cp0:-못 읽음} (예순여섯째 핀 $AS_CORE_PREV_PIN 이면 안 된다)"
if [ -z "${cp0:-}" ]; then
  unk "dss-core 핀이 되감겼는가" "포인터를 못 읽었다"
elif [ "$cp0" = "$AS_CORE_PREV_PIN" ]; then
  bad "🔴 dss-core 가 **예순여섯째 핀으로 되감겼다** — 예순일곱째가 올린 칸 넷이 사라진다"
  say "      🔴 그대로 구우면 도구와 앱이 **confirmed_at·share_doc_relative_path 를"
  say "         모르는 스키마**로 돕니다 — 어제 올린 기능이 조용히 죽습니다."
  doubt
else
  ok "dss-core 가 예순여섯째 핀(${AS_CORE_PREV_PIN:0:8})이 **아니다** — 되감기지 않았다"
fi

say ""
say "── 3-ㄴ. 🔴 **A/S 범위가 vendor/ 를 건드렸는가** — **0줄**이어야 한다"
say "🔴 **71번과 기대값이 반대입니다**(거기는 1줄이어야 했습니다). 0 이 아니면"
say "   누가 공용 묶음을 함께 고친 것이고, 그러면 **이 배포본의 전제가 깨집니다** —"
say "   72-deploy.sh 는 공용 스키마가 **어제 그대로**라는 전제로 쓰였습니다."
CHROW=$(row_by_key "$CHANGED" as)
CH_VENDOR=$(field "$CHROW" 6)
VLIST=$(git -C "$ASD" diff --name-only "$(repo_base as)..main" 2>/dev/null | tr -d '\r' | grep -E '^(vendor/|\.gitmodules)' || true)
vn=$(printf '%s\n' "$VLIST" | grep -c . || true)
say "vendor/ · .gitmodules 변경 ${vn:-?}줄 (기대 $CH_VENDOR)"
[ -n "${VLIST:-}" ] && printf '%s\n' "$VLIST" | sed 's/^/        /'
if [ "${vn:-x}" = "$CH_VENDOR" ]; then
  ok "A/S 범위가 vendor/ 를 **${CH_VENDOR}줄 건드렸다** (공용 스키마가 안 움직였다)"
  say "      🔵 그래서 **굽는 까닭 ㄹ 이 이번에는 안 걸립니다**(5-ㄹ 이 같은 값으로 잽니다)."
else
  bad "vendor/ 변경이 ${vn:-?}줄이다 — $CH_VENDOR 을 기대했다"
  say "      🔴 **멈추고 알리세요.** 공용 스키마가 움직였으면 71번처럼 3-ㄹ 을"
  say "         「이번 판이 더한 칸」으로 되돌리고 핀 값도 다시 적어야 합니다."
  doubt
fi
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
  # 🔴 **예순여섯째 핀 → 지금 핀 사이에 무엇이 들었나** — 「예순일곱째가 올린 것이
  #    아직 그 사이에 있다」를 값으로 보인다. 🔵 이 판은 그 폭을 **안 늘린다.**
  if git -C "$COREDIR" cat-file -e "$AS_CORE_PREV_PIN^{commit}" 2>/dev/null; then
    mc=$(git -C "$COREDIR" rev-list --count "$AS_CORE_PREV_PIN..$AS_CORE_PIN" 2>/dev/null)
    mf=$(git -C "$COREDIR" diff --name-only "$AS_CORE_PREV_PIN..$AS_CORE_PIN" 2>/dev/null | tr -d '\r' | grep -c . || true)
    say "dss-core 예순여섯째 핀 → 지금 핀: 커밋 ${mc:-?}개 · 바뀐 파일 ${mf:-?}장 (기대 $AS_CORE_MOVED_COMMITS · $AS_CORE_MOVED_FILES)"
    git -C "$COREDIR" log --oneline "$AS_CORE_PREV_PIN..$AS_CORE_PIN" 2>/dev/null | sed 's/^/        /'
    git -C "$COREDIR" diff --name-only "$AS_CORE_PREV_PIN..$AS_CORE_PIN" 2>/dev/null | sed 's/^/        /'
    if [ "${mc:-x}" = "$AS_CORE_MOVED_COMMITS" ] && [ "${mf:-x}" = "$AS_CORE_MOVED_FILES" ]; then
      ok "예순일곱째가 옮긴 폭(커밋 ${AS_CORE_MOVED_COMMITS}개 · 파일 ${AS_CORE_MOVED_FILES}장)이 **그대로다**"
    else
      note "그 폭이 커밋 ${mc:-?} · 파일 ${mf:-?} 다 — $AS_CORE_MOVED_COMMITS · $AS_CORE_MOVED_FILES 를 기대했다. **사람이 보세요**"
      say "      🔵 늘었으면 누가 공용 묶음을 더 올린 것입니다 — 3-ㄴ 의 0줄과 함께 보세요."
    fi
  else
    unk "예순일곱째가 옮긴 폭" "예순여섯째 핀 ${AS_CORE_PREV_PIN:0:8} 가 그 저장소에 없다"
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
[ "$SUBFILE_SEEN" = "2" ] && ok "서브모듈 작업본 둘을 다 봤다 (표본이 비지 않았다)" \
  || bad "서브모듈 작업본을 ${SUBFILE_SEEN}개만 봤다 — 2개를 기대했다"
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

# 🔴 **예순일곱째가 그 안에 더한 칸 넷이 아직 있는가** — 하나라도 없으면 어제 올린
#    기능이 조용히 죽는다(화면은 뜨고 그 칸만 사라진다).
say ""
say "── 3-ㄹ. 🔴 **예순일곱째가 공용 스키마에 더한 칸 넷이 아직 있는가** (뒷걸음 방지)"
say "🔴 **71번과 뜻이 뒤집힌 절입니다**(머리말 ③ · 「왜 없는가」 ③) — 거기서는"
say "   「이번 판이 더했는가」였고, 여기서는 「**아직 있는가**」입니다. 🔴 **절을**"
say "   **빼지 않았습니다** — 빼면 서브모듈이 되감긴 날 아무도 못 잡습니다."
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
  ok "공용 스키마가 **예순일곱째의 칸 넷을 아직 다 선언한다** (되감기지 않았다)"
else
  bad "본 칸 ${NEWCOL_SEEN} · 갖춘 칸 ${NEWCOL_OK} 다 — $AS_CORE_NEW_WANT 을 기대했다"
  say "      🔴 **서브모듈을 안 받았거나 예순여섯째 핀으로 되감겼습니다.** 3-ㄱ 을 다시 보세요."
  doubt
fi

# ── 4. 🔵 마이그레이션 — **0건이다.** 「안 늘었는가」를 값으로 잰다 ──
step "4. 🔵 마이그레이션 — **0건** (전 $AS_SQL_WAS 장 → 후 $AS_SQL_WANT 장 · 한 칸도 안 움직인다)"
say "🔴 **71번은 2건이었습니다**(0132·0133). 그 판에는 여기에 절이 넷이었습니다 —"
say "   4-ㄱ(지우는 문장 잣대 표본 일곱) · 4-ㄴ(수 세기) · 4-ㄷ(장마다 생김새) ·"
say "   4-ㄹ(창 안 일곱). 🔴 **이번 판에는 4-ㄴ 하나만 있습니다.**"
say "   🔴 **왜 없는지**는 이 파일 머리말의 「왜 없는가」 ①②에 적어 두었습니다 —"
say "      잴 .sql 이 **한 장도 없기** 때문입니다. **.sql 이 한 장이라도 생기면**"
say "      **71-build.sh 에서 그 세 절과 DESTRUCTIVE_RE 를 통째로 되살리세요.**"
say "🔵 그래서 72-deploy.sh 에는 **--migrate 가 없고 그 자리가 --tools** 입니다."

# 4-ㄴ. 수 세기 — 🔵 **134 그대로 · 범위의 drizzle/ 변경 0줄 · 0134 없음**
say ""
say "── 4-ㄴ. 저장소 drizzle/ 을 센다 (.sql 수 == meta/_journal.json 의 idx 수)"
MIGCK_SEEN=0
s=$(ls -1 "$ASD/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
j=$(grep -o '"idx"' "$ASD/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
MIGCK_SEEN=$((MIGCK_SEEN+1))
say "A/S .sql ${s:-?}장 · idx ${j:-?}개 (기대 $AS_SQL_WANT · $AS_SQL_WANT)"
if [ "${s:-x}" = "$AS_SQL_WANT" ] && [ "${j:-x}" = "$AS_SQL_WANT" ]; then
  ok "A/S drizzle/ 이 ${AS_SQL_WANT}장이고 목록도 ${AS_SQL_WANT}개다 (운영과 같은 수다 — 올릴 것이 없다)"
else
  bad "A/S 가 .sql ${s:-?} · idx ${j:-?} 다 — ${AS_SQL_WANT}·${AS_SQL_WANT} 를 기대했다"
  say "      🔴 **.sql 과 idx 가 다르면** 목록에 없는 파일이 있다는 뜻이고,"
  say "         drizzle 이 그것을 **아예 모릅니다**(적용이 0건으로 조용히 끝납니다)."
  say "      🔴 **수가 늘었으면 이 배포본의 전제가 깨집니다** — 묶음도 --migrate 도"
  say "         없는 판입니다. 멈추고 알리세요."
  doubt
fi
MIGCK_SEEN=$((MIGCK_SEEN+1))
dn=$(git -C "$ASD" diff --name-only "$(repo_base as)..main" -- drizzle 2>/dev/null | tr -d '\r' | grep -c . || true)
say "A/S 범위의 drizzle/ 변경 ${dn:-?}줄 (기대 $AS_DRIZZLE_DIFF_WANT)"
git -C "$ASD" diff --name-only "$(repo_base as)..main" -- drizzle 2>/dev/null | sed 's/^/        /'
if [ "${dn:-x}" = "$AS_DRIZZLE_DIFF_WANT" ]; then
  ok "A/S 범위가 drizzle/ 을 **한 줄도 안 건드렸다** — 🔴 **올릴 마이그레이션이 0건이다**"
  say "      🔴 그래서 이 파일은 **묶음을 안 만들고** 72-deploy.sh 에는 **--migrate 가**"
  say "         **없습니다**(그 자리가 --tools 입니다)."
else
  bad "A/S 의 drizzle/ 변경이 ${dn:-?}줄이다 — $AS_DRIZZLE_DIFF_WANT 을 기대했다"
  say "      🔴 이 배포본은 **0건**을 전제로 쓰였습니다. 멈추고 알리세요 —"
  say "         **묶음을 만드는 절과 --migrate 를 71번에서 되살려야** 합니다."
  doubt
fi
# 🔴 **「없다」만 재면 번호가 빗나가도 통과한다** — 반대쪽 「있는가」를 같은 줄에서
#    함께 센다. 70번이 AS_NEXT_MIG 가 한 칸 빗나가 **두 판 연속 아무것도 안 막은**
#    것을 잡아낸 뒤로 생긴 규율이다.
MIGCK_SEEN=$((MIGCK_SEEN+1))
lastn=$(ls -1 "$ASD/drizzle/${AS_LAST_MIG}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
nx=$(ls -1 "$ASD/drizzle/${AS_NEXT_MIG}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
say "$AS_LAST_MIG 이 아직 있는가: ${lastn:-?}개 (기대 1) · $AS_NEXT_MIG 이 생겼는가: ${nx:-?}개 (기대 0)"
if [ "${lastn:-0}" = "1" ] && [ "${nx:-1}" = "0" ]; then
  ok "마지막이 $AS_LAST_MIG 이고 $AS_NEXT_MIG 은 없다 (예순일곱째가 올린 자리에서 안 움직였다)"
  say "      🔵 **두 쪽을 함께 세는 까닭**: 「$AS_NEXT_MIG 이 없다」만 재면 번호를"
  say "         잘못 적어 둔 날에도 **영영 ✓** 가 됩니다."
elif [ "${lastn:-0}" != "1" ]; then
  bad "$AS_LAST_MIG 이 ${lastn:-?}개다 — 1 을 기대했다. 🔴 **번호가 빗나갔거나 되감겼다**"
  doubt
else
  bad "$AS_NEXT_MIG 이 **생겼다** — 이 배포본은 $AS_LAST_MIG 까지를 전제로 쓰였다. 멈추고 알릴 것"
  say "      🔴 **묶음을 만드는 절과 --migrate 를 71번에서 되살려야** 합니다."
fi
[ "$MIGCK_SEEN" = "3" ] && ok "마이그레이션 수 검사 셋을 다 돌았다 (표본이 비지 않았다)" \
  || bad "마이그레이션 수 검사를 ${MIGCK_SEEN}개만 돌았다 — 3개를 기대했다"

say ""
say "🔵 **운영이 지금 들고 있어야 하는 수** — $PROD_MIGS_NOTE"
say "   🔴 **개발 PC 에서는 못 잽니다.** 72-deploy.sh --check 가 DB 에 물어 확인하고,"
say "      어긋나면 **거기서 멈춥니다.** 어긋나면 그것은 **이 배포와 무관한 다른 사고**입니다."
say "   🔴 A/S 는 마이그레이션이 **볼륨**에서 돕니다(/volume1/dss/as-migrations) —"
say "      **이미지 안에는 .sql 이 한 장도 없습니다**(5절이 값으로 잽니다)."
say "      🔵 **이번 판은 그 볼륨에 더할 것이 없습니다** — 그래서 묶음을 안 보냅니다."
say "      🔴 **옛 폴더(_images-58 … _images-71)의 묶음을 보내지 마세요** — 그것들은"
say "         128·129·131·132·134장짜리이고, 보내면 **엉뚱한 판이 볼륨을 덮습니다.**"

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 담는 길 · 굽는 까닭 · 소스가 새 코드를 담고 있나 ────────────
# ══════════════════════════════════════════════════════════════════════
step "5. 🔴 담는 길 · 굽는 까닭 · 소스가 새 코드를 담고 있나"

# 5-ㄱ. Dockerfile 이 담는 길
say "── 5-ㄱ. Dockerfile 의 COPY 줄 — 🔴 **drizzle 줄의 기대값이 no 다**"
say "🔴 A/S 의 「drizzle 을 **안 담는다**」는 **볼륨이 정본**이라는 뜻입니다."
say "   🔵 71번에는 포털 줄 넷이 더 있었고, 거기서는 같은 줄의 기대값이 **yes** 였습니다"
say "      (포털은 .sql 이 **이미지 안**에서 돕니다). 🔴 한 줄로 베끼면 둘 중 하나가"
say "      **가짜 ✗** 가 됩니다(62-build.sh:34-35 의 경고 — 포털을 되살릴 때 보세요)."
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
say "🔴 **둘 다 strict 로 둔 근거가 위 두 줄입니다** — 라이브러리가 한 개도 안 늘었습니다."
# 🔵 뒷걸음 — 쉰여덟째가 더한 heic2any 가 그대로 있는가(빠지면 아이폰 사진이 다시 막힌다)
n=$(grep -c '"heic2any"' "$ASD/package.json" 2>/dev/null || true)
say "heic2any (쉰여덟째가 더한 것) — ${n:-?}줄 (기대 1)"
[ "${n:-x}" = "1" ] && ok "heic2any 가 그대로 있다 (뒷걸음친 나무가 아니다)" \
  || bad "heic2any 가 ${n:-?}줄이다 — 1 을 기대했다"

# 5-ㄹ. 🔴 **굽는 까닭 ㄴ·ㄷ·ㄹ**
say ""
say "── 5-ㄹ. 🔴 굽는 까닭 **ㄴ** — tools 가 담는 것 중 바뀐 파일"
AS_LIST=$(git -C "$ASD" diff --name-only "$(repo_base as)..main" 2>/dev/null | tr -d '\r')
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
say "🔵 **이번에는 빠지는 장이 하나도 없습니다**(19 중 19) — src/ 17 + scripts/ 2 입니다."
say "   🔴 71번은 179 중 173 이었습니다(drizzle/ 다섯과 뿌리의 진행현황 HTML 한 장이"
say "      빠졌습니다 — A/S tools 는 drizzle 을 안 담고, 뿌리의 HTML 은 어느 COPY 에도"
say "      안 걸립니다). **이번 범위에는 그 둘이 한 장도 없습니다.**"

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
say "ㄹ) 🔵 **공용 스키마(vendor/*)가 움직였나** — 🔴 **이번에는 안 걸린다.** 잣대만 재 둔다"
say "   🔵 3-ㄴ 과 **같은 값을 여기서 다시 셉니다** — 3절은 「포인터가 움직였는가」를,"
say "      여기는 「**굽는 까닭이 되는가**」를 말합니다. 뜻이 다르면 질의도 따로 두는"
say "      것이 이 저장소의 규율입니다. 🔴 **절을 빼지 않았습니다.**"
ven0=$(printf '%s\n' "$AS_LIST" | grep -cE '^(vendor/|\.gitmodules)' || true)
say "   A/S 의 vendor/ · .gitmodules ${ven0:-?}줄 (기대 $CH_VENDOR)"
if [ "${ven0:-x}" = "$CH_VENDOR" ]; then
  if [ "${ven0:-0}" -ge 1 ] 2>/dev/null; then
    ok "🔴 **ㄹ 잣대가 걸린다** — 공용 스키마가 움직였다"
  else
    ok "ㄹ 잣대가 **안 걸린다** (공용 스키마가 안 움직였다 — 71번과 반대다)"
    say "      🔵 그래도 **도구는 굽습니다** — ㄴ 하나로 충분합니다(src/ 17 + scripts/ 2)."
    say "      🔵 그리고 **옛 핀으로 되감기지 않았는지**는 3-ㄱ 이 따로 쟀습니다."
  fi
else
  bad "A/S 의 vendor/ 변경이 ${ven0:-?}줄이다 — $CH_VENDOR 을 기대했다"
  doubt
fi
say "   그 핀이 origin 에 올라가 있나: ${CORE_ORIGIN_OK:-0} (기대 1 — 3-ㄴ 에서 쟀다)"
[ "${CORE_ORIGIN_OK:-0}" = "1" ] && ok "지금 핀의 커밋이 **origin 에도 있다** (다른 PC 가 같은 이미지를 만들 수 있다)" \
  || bad "그 커밋이 origin 에 없다 — **이 PC 에서만 되는 이미지가 된다.** 3-ㄴ 을 보세요"
say ""
say "ㅁ) 🔵 **마이그레이션이 0건이다** — 4절이 값으로 쟀다"
say "   🔵 71번에서 이 자리는 **묶음을 만드는 까닭**이었습니다. 이번 판은 올릴 .sql 이"
say "      없어 **묶음을 안 만듭니다**(머리말 「왜 없는가」 ①)."
say "   🔴 A/S tools 가 drizzle/ 을 **안 담는다**는 사실은 그대로입니다(5-ㄱ) —"
say "      .sql 이 생기는 판에서는 **반드시 묶음을 만들어 보내야** 합니다."
say ""
say "🔴 **결론: 둘을 다 굽는다. 묶음은 안 만든다.**"
say "   · A/S  — **ㄴ(19장)만 걸린다.** ㄱ(npm 명령) · ㄷ(import 닫힘) · ㄹ(공용 스키마) ·"
say "     ㅁ(마이그레이션)은 **넷 다 안 걸립니다.**"
say "   🔴 **그래도 도구를 굽습니다** — src/ 17장이 도구 이미지 안으로 들어가고,"
say "      그 안에서 db:preflight·check:* 가 **그 소스로** 돕니다. 안 구우면 운영의"
say "      도구가 **옛 몸통**으로 돕니다."
say "   🔵 반대 방향의 사고도 이 저장소에 적혀 있습니다 — 「마이그레이션 0건이니"
say "      도구는 안 굽는다」가 틀려 비상구 둘을 못 올린 적이 있고, 이튿날에는"
say "      거꾸로 「명령이 늘어난 것」을 놓쳐 Missing script 가 났습니다."

# 5-ㅁ. 바뀐 파일 수
say ""
say "── 5-ㅁ. 바뀐 파일 수 (🔴 2절의 ⚠️ 와 짝인 자리다)"
CH_SEEN=0
while IFS='|' read -r RK WALL WSRC WSCR WDRZ WVEN WNEW WDEL WPAR WBRK WTST; do
  [ -n "${RK:-}" ] || continue
  CH_SEEN=$((CH_SEEN+1))
  RD=$(repo_dir "$RK"); RN=$(repo_name "$RK"); RB=$(repo_base "$RK")
  case "$RK" in
    as)   L="$AS_LIST" ;;
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
    say "         **코드가 더 밀린 것**이고, 아래 표식 기대값이 전부 그 범위에서 나온"
    say "         값이라 함께 어긋납니다."
  fi
  if [ "${del:-1}" = "$WDEL" ]; then ok "$RN 지운 파일 ${WDEL}장"
  else bad "🔴 $RN 이 파일을 ${del}장 **지웠다** — $WDEL 을 기대했다. 멈추고 알릴 것"; fi
done <<ENDCH
$(rows_of "$CHANGED")
ENDCH
[ "$CH_SEEN" = "$CHANGED_WANT" ] && ok "바뀐 파일 수를 ${CHANGED_WANT}집에서 다 봤다" \
  || bad "바뀐 파일 수를 ${CH_SEEN}집만 봤다"
say "🔵 **이번 범위에는 괄호도 대괄호도 든 경로가 0장입니다**(아래가 비면 그것이 맞습니다):"
printf '%s\n' "$AS_LIST" | grep -F '(' | sed 's/^/        /'
printf '%s\n' "$AS_LIST" | grep -F '[' | sed 's/^/        /'
say "   🔴 **그래도 그 셈을 빼지 않았습니다** — 67번이 0 이었는데 안 빼서 68번의 [id]"
say "      를 잡았습니다. 🔴 **대신 글롭 함정의 실물을 잃었으므로** AS_KEY_FILES 에"
say "      **범위 밖의 두 장**(괄호 하나 · 괄호+대괄호 하나)을 일부러 넣었습니다."
say "   🔵 목록을 넘기는 길은 here 문서 + grep -Fx 로만 썼고 컨테이너 안에서는"
say "      set -f 로 글롭을 끕니다."

# 5-ㅂ. 🔴 표식 — 소스에서 먼저 센다
say ""
say "── 5-ㅂ. 🔴 표식 — **소스에서 먼저 센다** (기능 0→N · 뒷걸음 N→N · 곁들이는 찍기만)"
say "🔴 기능 표식이 **둘**입니다 — 갈래는 **셋**인데 둘뿐인 까닭은 머리말 ⑥ 에 있습니다:"
say "   ㄱ(확정 단추)·ㄷ(납품 요청일) 갈래는 번들에 **새 글자를 한 개도 안 남깁니다**"
say "   (더한 것이 함수 이름과 지역 변수뿐이고, 웹팩이 export 이름까지 줄입니다)."
say "   🔴 **그 둘은 도구 이미지에서 가립니다**(5-ㅅ 의 TOOLMARKS **둘**)."
say "🔴 **그래서 「기능 표식 둘이 ✓ 니까 세 갈래가 다 담겼다」가 거짓입니다.**"
say "🔴 **아래 수는 전부 소스에서 센 값입니다** — 번들 수는 --go 가 처음 찍습니다."
MK_SEEN=0; MK_FEAT=0; MK_KEEP=0; MK_SIDE=0
while IFS='|' read -r RK KIND MK NOTE1; do
  [ -n "${RK:-}" ] || continue
  MK_SEEN=$((MK_SEEN+1))
  RD=$(repo_dir "$RK"); RN=$(repo_name "$RK"); RB=$(repo_base "$RK")
  a=$(mark_was "$RD" "$RB" "$MK"); b=$(mark_now "$RD" "$MK")
  printf '      %-10s %-7s %-44s 기준 %-4s → 지금 %-4s  (%s)\n' "$RN" "$KIND" "[$MK]" "${a:-?}" "${b:-?}" "$NOTE1"
  case "$KIND" in
    feature)
      MK_FEAT=$((MK_FEAT+1))
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
say "🔵 뒷걸음 표식이 **열**인 까닭: 예순일곱째부터 쉰여섯째까지가 올린 글자를"
say "   하나씩 잡고 있습니다 — **하나도 빼지 마세요.**"
say "🔴 **이번에 하나 늘었습니다** — 71번의 기능 표식 [shareDocRelativePath] 가"
say "   어제 올라가 오늘은 「있다」가 아무것도 안 가르므로 **뒷걸음으로 내렸습니다**"
say "   (기준 36 → 지금 36). 🔵 71번이 번들에서 **23개**로 세어 두었습니다."
say "🔴 그중 [도번 / 비고] 가 **한글입니다**(예순여섯째가 올린 것)."
say "   🔴 71번이 그 자리에서 데었습니다 — ASCII 로 쓰려고 같은 커밋의"
say "      part.drawingNo, part.note 를 골랐는데, 그것은 70번의 **도구 이미지용**"
say "      표식이라 **번들에서 0/0** 이었습니다(part 가 지역 이름이라 minify 가"
say "      갈아 치웁니다). [실측 2026-11-25 · dss-as:6.2]"
say "   🔵 한글이 경계를 건너가는지는 **1-ㄷ 절이 바이트로** 쟀습니다."

# 5-ㅅ. 🔴 도구 이미지용 표식 — **한 집에 둘**
say ""
say "── 5-ㅅ. 🔴 **도구 이미지용 표식 둘** — 소스에서 먼저 센다"
say "🔴 **71번은 「집마다 하나」라 둘이었고, 이 판은 「한 집에 둘」이라 둘입니다** —"
say "   수는 같지만 까닭이 다릅니다. **번들이 못 가리는 갈래 둘**(ㄱ·ㄷ)을 여기서"
say "   가립니다(머리말 ⑥·⑧). 도구에는 소스가 **글자 그대로** 들어 있습니다."
say "🔴 **기준에 0줄이었다는 것도 git 에서 직접 셉니다**(적어 둔 값을 안 믿습니다)."
say "🔴 **과녁 둘 다 기준판에도 있던 파일**입니다 — 새로 생긴 파일을 과녁으로 삼으면"
say "   「기준 0줄」이 **파일이 없어서 0** 인 것이라 아무것도 안 가릅니다."
say "   🔵 그래서 po-issued-repair-waiting.ts(새 파일)는 과녁으로 안 썼습니다."
say "🔵 둘째(customer-portal.ts)가 **마지막 커밋 3d32f5cb 의 과녁**이기도 합니다."
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
  if [ "${n:-x}" = "$NOW_WANT" ]; then ok "$RN 의 도구 표식이 그 파일에 ${n}줄 있다"
  elif [ "${n:-0}" -ge 1 ] 2>/dev/null; then note "$RN 에서 그 글자가 ${n}줄이다 — $NOW_WANT 을 기대했다. 사람이 보세요"
  else bad "$RN 의 도구 표식이 그 파일에 **없다** — 표가 틀렸다"; fi
done <<ENDTM
$(rows_of "$TOOLMARKS")
ENDTM
[ "$TM_SEEN" = "$TOOLMARKS_WANT" ] && ok "도구 표식 ${TOOLMARKS_WANT}개를 다 봤다 (갈래 ㄱ 과 ㄷ 을 하나씩 가린다)" \
  || bad "도구 표식을 ${TM_SEEN}개만 봤다 — ${TOOLMARKS_WANT}개를 기대했다. TOOLMARKS 표가 깨졌다"
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
  || bad "짝 파일을 ${TP_SEEN}장만 봤다 — ${TOOLMARK_PAIRS_WANT}장을 기대했다"
say "🔴 **ㄱ·ㄷ 갈래를 가르는 자리가 바로 이것입니다**(머리말 ⑥) — 그 둘은 앱 번들에"
say "   **가를 글자가 없어서**, 71번이 포털에서 · 62번이 계측기에서 한 그대로"
say "   **도구 이미지**에서 가립니다."
say "🔵 넷째 짝(po-issued-repair-waiting.ts)은 **ㄴ 갈래**의 것입니다 — 그 갈래는"
say "   번들 표식 둘이 따로 가리지만, 짝 파일이 없으면 도구가 import 에서 죽습니다."

# 5-ㅇ. 🔴 시험 등록 — **A/S 는 목록 파일 방식**
say ""
say "── 5-ㅇ. 🔴 시험 등록 — **A/S 는 목록 파일 방식이다**"
say "🔴 **방식이 저장소마다 다릅니다.** 한 집의 방식을 다른 집에 베끼면 그 집의"
say "   시험 등록이 **아무 검사도 안 받습니다.**"
say "   🔵 71번에는 여기에 **ㄴ) 포털 절**이 더 있었습니다(package.json 의 test 줄에"
say "      경로를 나열하는 방식). 🔴 포털이 다시 올라가는 판에서는 **71번에서**"
say "      **되살리세요** — 머리말의 「왜 없는가」 ④ 에 적어 두었습니다."
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
  say "      🔴 **등록이 통째로 빠졌습니다.** 그 셋은 조용히 안 돕니다."
  doubt
else
  ok "목록이 ${TLBASE} → ${lines} 로 **늘었다** (새 시험 ${AS_NEW_TESTS_WANT}장이 등록된 꼴이다)"
  say "      🔴 **줄 수만으로는 「셋이 등록됐다」를 말할 수 없습니다** — 이 저장소의"
  say "         목록 파일은 **까닭을 적은 주석**도 담습니다(이번에 늘어난 41줄 중 시험"
  say "         경로는 **셋뿐**입니다). 아래가 **경로를 하나씩** 묻습니다."
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
  # ── ① 새 시험 셋이 목록에 등록돼 있는가 (이 절의 본체다)
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
    say "      🔵 **이번 셋에는 대괄호가 든 경로가 없습니다** — 71번에는 하나 있었고,"
    say "         그 줄은 목록에 **별표로** 적혀 있었습니다(그 표의 머리말)."
  else
    bad "등록된 것이 ${got}/${AS_NEW_TESTS_WANT} 개다 — 🔴 **빠진 것은 오류 없이 조용히 안 돈다**"
    doubt
  fi
  # ── ② 바뀐 시험 중 **새것이 아닌 것**이 아직 적혀 있는가 (git 에서 뽑는다)
  # 🔴🔴 **새 파일을 가릴 때 AS_NEW_TESTS 표를 쓰지 않는다.** 그 표는 **목록 파일에
  #    적힌 꼴**을 들고 있어서 대괄호 자리가 **별표**가 될 수 있다(그 표의 머리말).
  #    git 이 주는 것은 **실제 경로(대괄호)**라 둘이 안 맞고, 그러면 그 한 장이
  #    「새것이 아닌 것」으로 흘러들어 **멀쩡한 판에서 seen 이 하나 더** 나온다 —
  #    71번에서 실제로 그 ✗ 가 날 자리였다. 🔴 **가리는 쪽도 git 에서 뽑는다.**
  #    🔵 이번 셋에는 별표가 하나도 없지만 **길은 그대로 둔다** — 다시 생기는 날
  #       이 주석을 읽을 사람이 있어야 한다.
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
    say "      🔴 **본 것이 0 이면 그 고리가 안 돈 것**입니다 — 8 − 3 = 5 가 기대값입니다."
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
say "   ㄴ) 🔵 **포털 절이 없습니다** — 71번에는 여기에 「package.json 의 test 줄에"
say "      경로를 하나씩 나열하는가」를 재는 절이 있었습니다. 이번 판에는 **포털이**"
say "      **올라가지 않습니다**(808d496 그대로)."
say "      🔴 **포털이 다시 올라가는 판에서는 71-build.sh:1920-1961 과 count_test_paths()"
say "         를 통째로 되살리세요** — **글롭 방식인 저장소에서 베끼면 이 절이 통째로**"
say "         **없어지고**, 그 집의 시험 등록이 아무 검사도 안 받습니다."

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
      say "         & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./72-build.sh --verify"
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
say "🔵 **A/S(3000) 와 DB 둘(5442·5444)이 떠 있는 것이 정상입니다** — 🔴 **끄지 마세요.**"
say "   🔵 5444 는 **포털 DB** 입니다 — 이번 판이 **안 건드리는 집**의 것이지만"
say "      값으로 찍어 둡니다(71번은 포털 dev 서버 3100 도 함께 봤습니다)."
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
[ "$PORT_SEEN" = "$PORTS_WANT" ] && ok "포트 ${PORTS_WANT}개를 다 봤다" \
  || bad "포트를 ${PORT_SEEN}개만 봤다 — ${PORTS_WANT}개를 기대했다"
say "🔴 **next dev 는 포트가 차면 조용히 옆으로 비켜섭니다** — 위 수만으로 「안 떠 있다」를"
say "   단정하지 마세요. 이 줄은 판정에 쓰이지 않습니다."

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
}

# ══════════════════════════════════════════════════════════════════════
# ══ 이미지 안을 재는 길 — 🔴 **갈래마다 다른 것을 잰다** ══════════════
# ══════════════════════════════════════════════════════════════════════
#   🔴 앱과 도구는 담긴 것이 다르다 — 앱은 **번들**, 도구는 **소스 그대로**다.
#   🔵 71번에는 여기에 **포털 가지**가 더 있었다(authtools) — 거기는 drizzle 의
#      기대값이 A/S 와 **반대**(11장이 있어야 ✓)였다. 🔴 포털을 되살릴 때
#      **한 잣대로 베끼지 마라** — 둘 중 하나가 가짜 ✗ 가 된다.
IMGFAIL=0
INSIDE_RAN=0
dock() { dockr run --rm --entrypoint sh "$@" 2>/dev/null | tr -d '\r'; }

# 🔴 목록 하나를 이미지 안에서 한 장씩 묻는다 — **없는 경로 하나를 함께** 묻는다.
#    🔴 set -f 로 글롭을 끈다. **이번 A/S 목록에는 괄호·대괄호가 든 경로가 둘 있다**
#       (이번 범위 밖에서 일부러 끌어온 잣대 두 장이다 — AS_KEY_FILES 의 주석)
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
    printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 🔴 **이 파일의 표식은 번들에서 한 번도"
    printf '%s\n' "         안 세어 봤습니다** — 이 판은 굽기 전에 쓰였고, 여기가 **처음** 세는"
    printf '%s\n' "         자리입니다(71번은 구운 뒤 열여덟을 다 세어 적었습니다)."
    printf '%s\n' "      🔵 71번이 **구운 번들에서** 확인해 둔 것(참고): 뒷걸음 열 중 아홉이 ≥1 이고"
    printf '%s\n' "         shareDocRelativePath 는 **23개**였습니다. **뒷걸음이 0 이면 진짜 결함**입니다."
    printf '%s\n' "      🔴 **기능 표식이 0 이면** 그것이 **객체 칸 이름**(autoAdvancedOnPoIssuedDate)인지"
    printf '%s\n' "         **문자열 리터럴**(NO_WAITING_REPAIR_STEP)인지 보세요 — 뒤쪽이 0 이면"
    printf '%s\n' "         **그 코드가 안 담긴 것**이고, 앞쪽만 0 이면 **minify 가 칸 이름까지 줄인 것**"
    printf '%s\n' "         입니다(그때는 이미지가 아니라 **이 검사**를 고치세요)."
    printf '%s\n' "      🔴 **그 글자가 한글이면 1-ㄷ 절부터 보세요** — ASCII 표식이 ✓ 인데"
    printf '%s\n' "         한글만 0 이면 그것은 **검사 탓**입니다(이미지를 되돌리지 마세요)."
    printf '%s\n' "      🔴 **코드 줄에서 따온 글자는 번들에 안 남습니다** — 지역 이름은 minify 가"
    printf '%s\n' "         갈아 치우고 export 이름은 웹팩이 줄입니다(part.drawingNo, part.note 가"
    printf '%s\n' "         71번에서 그 실물이었습니다 — 소스 1줄 · 번들 0/0)."
    if [ -n "${4:-}" ] && isnum "${ds:-}" && isnum "${dt:-}" && [ "$((ds + dt))" -ge 1 ]; then
      printf '%s\n' "      🔴 **곁들이 글자는 1 이상입니다** — 즉 이미지가 통째로 비어 있지는 않습니다."
      printf '%s\n' "         🔵 이 판의 곁들이는 **export 이름**(PO_ISSUED_REPAIR_WAITING_METADATA ·"
      printf '%s\n' "            showDomesticOrderDueDateConfirmControls)이라 **남는 것이 오히려 뜻밖**입니다."
      printf '%s\n' "         🔵 이미지를 다시 굽기 전에 **이 검사를 먼저 보세요** — 다른 글자로"
      printf '%s\n' "            재면 지문이 안 바뀝니다(72-build.sh --verify)."
    else
      printf '%s\n' "      🔴 **곁들이 글자도 0 입니다** — 옛 소스를 구웠거나, 경로 번역이 살아"
      printf '%s\n' "         있습니다(1-ㄴ 절이 ✓ 였는지 보세요)."
      printf '%s\n' "         🔵 다만 이 판의 곁들이는 **export 이름**이라 **멀쩡한 판에서도 0 일 수**"
      printf '%s\n' "            **있습니다** — 곁들이 0 만으로 결함이라 단정하지 마세요."
    fi
  fi
}

# 🔵 **판정에 안 쓰고 찍기만 하는 곁들이.**
#    🔴 이 판의 곁들이 둘은 **export 이름**이라 번들에 남는지 모른다 — 그래서
#       ✗ 를 안 내고 값만 남긴다. 다음 판이 「그때 번들에 남았나」를 이 로그에서
#       읽을 수 있다(71번이 TONE_COUNT 로 같은 일을 했고, 그 값은 **0** 이었다).
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
inside_check() { # 1 열쇠(as|astools) 2 태그 3 타깃(-=앱)
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
    #    🔵 이 판은 A/S 하나뿐이고 **기능 둘 + 뒷걸음 열**이다(71번은 A/S 기능 셋 +
    #       뒷걸음 아홉, 포털 기능 0 + 뒷걸음 셋이었다). **고리 꼴은 그대로 둔다.**
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
    printf '      이 집에서 **판정에 쓴 표식** %s개 (기대 %s)\n' "$MKRAN" "$MARKS_JUDGE_WANT"
    if [ "$MKRAN" = "$MARKS_JUDGE_WANT" ]; then
      printf '  ✓ A/S 번들 표식 %s개(기능 %s + 뒷걸음 %s)를 다 돌았다\n' \
        "$MARKS_JUDGE_WANT" "$MARKS_FEATURE_WANT" "$MARKS_KEEP_WANT"
      printf '%s\n' "      🔴 **기능 표식 둘은 ㄴ 갈래(PO발행일) 하나만 가립니다** — ㄱ(확정 단추)과"
      printf '%s\n' "         ㄷ(납품 요청일) 갈래는 번들에 **가를 글자가 없어서** 도구 이미지의"
      printf '%s\n' "         TOOLMARKS 둘이 가립니다(머리말 ⑥·⑧). **여기만 ✓ 라고 세 갈래가**"
      printf '%s\n' "         **다 담긴 것이 아닙니다.**"
    else
      printf '  ✗ A/S 번들 표식을 %s개만 돌았다 — %s개를 기대했다. APPMARKS 표가 깨졌다\n' "$MKRAN" "$MARKS_JUDGE_WANT"; IMGFAIL=1
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
    # 🔴🔴 **도구 표식이 둘이라 고리로 돈다** — 71번은 row_by_key 로 **한 줄만**
    #    꺼냈다. 그 함수는 맞는 줄을 **이어 붙여** 돌려주므로 두 줄이면 글자가
    #    통째로 깨진다. 🔴 **몇 개를 돌았는지 끝에서 단언한다**(고리가 한 바퀴만
    #    돌면 ㄱ 갈래만 재고 ㄷ 갈래는 **아무 검사도 안 받는다**).
    #    🔵 경로를 **상대로 넘기고** /app/ 를 컨테이너 안에서 붙인다(함정 ⑪).
    #    🔵 yes/no 가 아니라 **센 줄 수**를 받는다 — 0 과 「못 읽음」을 가른다.
    TMRAN=0
    while IFS='|' read -r TK TMK TMF TMWAS TMW; do
      [ -n "${TK:-}" ] || continue
      [ "$TK" = "$KEY" ] || continue
      TMRAN=$((TMRAN+1))
      v=$(dockr run --rm -e M="$TMK" -e F="$TMF" --entrypoint sh "$TAG" -c \
        'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s\n" "$(grep -cF -- "$M" "$p")"; else printf "missing 0\n"; fi' 2>/dev/null | tr -d '\r')
      tst=$(printf '%s' "$v" | awk '{print $1}'); tn=$(printf '%s' "$v" | awk '{print $2}')
      printf '      도구 표식 [%s] in %s — 파일 %s · 그 글자 %s줄 (기대 hit · %s)\n' \
        "$TMK" "$TMF" "${tst:-못 읽음}" "${tn:-?}" "${TMW:-1}"
      if [ "${tst:-}" = "hit" ] && [ "${tn:-0}" -ge 1 ] 2>/dev/null; then
        printf '  ✓ **그 갈래의 코드가 담겼다** (%s줄)\n' "$tn"
        printf '%s\n' "      🔵 앱 이미지는 **같은 작업본에서 같은 실행으로** 굽습니다 — 2절이 그"
        printf '%s\n' "         작업본의 HEAD 와 미커밋 0 을 확인했으므로 앱에도 들어 있습니다."
      elif [ "${tst:-}" = "hit" ]; then
        printf '  ✗ 그 파일은 있는데 그 글자가 **0줄**이다 — **옛 소스가 담긴 이미지다**\n'; IMGFAIL=1
      elif [ "${tst:-}" = "missing" ]; then
        printf '  ✗ 그 파일 자체가 이미지에 없다 — src/ 가 온전히 안 담겼다\n'; IMGFAIL=1
        printf '%s\n' "      🔵 **경로 번역부터 의심하세요** — 1-ㄴ 절이 ✓ 였는지 보세요."
      else
        printf '  ✗ 못 읽었다 (받은 값 [%s])\n' "${v:-}"; IMGFAIL=1
      fi
    done <<ENDTMIMG
$(rows_of "$TOOLMARKS")
ENDTMIMG
    printf '      이 이미지에서 돈 도구 표식 %s개 (기대 %s)\n' "$TMRAN" "$TOOLMARKS_PER_IMAGE_WANT"
    if [ "$TMRAN" = "$TOOLMARKS_PER_IMAGE_WANT" ]; then
      printf '  ✓ 도구 표식 %s개를 다 돌았다 (갈래 ㄱ 과 ㄷ 을 하나씩 가렸다)\n' "$TOOLMARKS_PER_IMAGE_WANT"
    else
      printf '  ✗ 도구 표식을 %s개만 돌았다 — %s개를 기대했다. **한 갈래가 아무 검사도 안 받았다**\n' \
        "$TMRAN" "$TOOLMARKS_PER_IMAGE_WANT"; IMGFAIL=1
    fi
    # ── 🔴 여기부터 **집마다 갈린다** (🔵 이 판은 A/S 하나뿐이라 가지가 하나다)
    #    🔴 71번에는 여기에 **authtools 가지**가 더 있었다 — 거기는 drizzle 의
    #       기대값이 **11장**이고 vendor 는 **없어야** ✓ 였다(A/S 와 둘 다 반대).
    #       포털을 되살릴 때 **한 가지로 뭉뚱그리지 마라.**
    case "$KEY" in
      astools)
        ask_files "$TAG" "$AS_KEY_FILES" "$AS_KEY_FILES_WANT" "A/S 의 핵심 파일"
        printf '%s\n' "      🔵 그 열두 장 중 **끝의 둘은 이번 범위 밖**입니다 — 괄호와 대괄호가 든"
        printf '%s\n' "         경로라 **글롭 함정이 살아 있는지 재는 잣대**입니다(이번 범위에는 그런"
        printf '%s\n' "         경로가 0장입니다). 길이 끊기면 **그 둘이 먼저 no 로** 떨어집니다."
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
        if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then
          printf '  ✓ drizzle/ 이 비어 있다 (볼륨이 정본이다)\n'
          printf '%s\n' "      🔵 **이번 판은 그 볼륨에 더할 것이 0건**이라 묶음을 안 보냅니다 —"
          printf '%s\n' "         운영의 볼륨은 ${AS_SQL_WANT}장 그대로입니다."
        else printf '  ✗ drizzle/ 에 .sql 이 들었다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다\n'; IMGFAIL=1; fi
        # 🔴 **공용 스키마가 담겼는가** — 핀이 맞아도 **빈 서브모듈이 담길 수 있다**.
        v=$(dock "$TAG" -c 'd=/app/vendor/dss-core/src/schema; if [ -d "$d" ]; then echo "miss=0"; echo "n=$(ls -1 "$d" | wc -l)"; else echo "miss=1"; fi')
        v=$(printf '%s\n' "$v" | tr -d ' ')
        printf '%s\n' "$v" | sed 's/^/        /'
        c=$(printf '%s\n' "$v" | sed -n 's/^miss=//p'); g=$(printf '%s\n' "$v" | sed -n 's/^n=//p')
        if [ "${c:-1}" != "0" ]; then printf '  ✗ 이미지에 vendor/dss-core 의 스키마 폴더가 **없다** — Cannot find module 이 난다\n'; IMGFAIL=1
        elif [ "${g:-0}" -ge 1 ] 2>/dev/null; then printf '  ✓ 공용 스키마가 담겼다 (파일 %s개)\n' "$g"
        else printf '  ✗ 공용 스키마 폴더가 비었다 — **빈 서브모듈이 담겼다.** 올리지 마세요\n'; IMGFAIL=1; fi
        # 🔴 **일곱 그대로 둔다** — 71번이 셋에서 일곱으로 늘린 자리다. 🔵 이 판에서는
        #    **일곱이 전부 뒷걸음**이다(이번 판은 공용 스키마에 한 글자도 안 더했다).
        #    🔴 **하나라도 빼지 마라** — 서브모듈이 되감긴 날 이 줄만이 그것을 잡는다.
        v=$(dock "$TAG" -c 'for pair in "portal_approval_delegations /app/vendor/dss-core/src/schema/portal-approval-delegations.ts" "portal-approval-delegations /app/vendor/dss-core/src/schema/index.ts" "fault_tags /app/vendor/dss-core/src/schema/repair-case-flowcharts.ts" "confirmed_at /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "confirmed_by /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "share_doc_relative_path /app/vendor/dss-core/src/schema/procedure-template-nodes.ts" "share_doc_relative_path /app/vendor/dss-core/src/schema/repair-case-flowchart-nodes.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1 $2"; fi; done')
        printf '%s\n' "$v" | sed 's/^/        /'
        g=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
        if [ "${g:-0}" = "7" ]; then
          printf '  ✓ **공용 스키마가 일곱 다 담겼다** (🔵 이 판에서는 일곱이 전부 **뒷걸음**이다)\n'
        else
          printf '  ✗ 일곱 중 %s개만 있다 — **옛 공용 스키마가 담겼다.** 올리지 마세요\n' "${g:-0}"; IMGFAIL=1
          printf '%s\n' "      🔴 뒤의 넷(confirmed_* · share_doc_*)만 no 면 **서브모듈이 예순여섯째"
          printf '%s\n' "         핀으로 되감긴 것**입니다 — 어제 올린 기능이 통째로 사라집니다(3-ㄱ)."
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
        printf '%s\n' "      🔵 **이번 판은 db:migrate 가 올릴 것이 0건입니다**(71번은 2건이었습니다)."
        printf '%s\n' "         🔴 **그래도 이 두 줄을 빼지 않습니다** — 여기서 재는 것은 「그 명령이"
        printf '%s\n' "            import 까지 가는가」이고, src/ 17장이 바뀐 판에서 그 길이 끊기면"
        printf '%s\n' "            **Cannot find module** 로 여기서 드러납니다."
        printf '%s\n' "         🔵 개발 PC 에서는 운영 DB 에 못 닿으므로 DATABASE_URL 쪽 답이 기대한 답입니다."
        printf '%s\n' "         🔴 **db:migrate 는 오류를 삼키고 exit 1 만 남기는 성질이 있습니다** —"
        printf '%s\n' "            그래서 72-deploy.sh 는 --tools 뒤에 **수를 다시 세어** ${AS_SQL_WANT} 인지 봅니다."
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
# 🔵 **묶음 안을 세는 함수(migtar_inside)가 없다** — 묶음을 안 만든다
# ══════════════════════════════════════════════════════════════════════
#   🔴 71-build.sh:2260-2343 에 그 함수가 있었다. 까닭은 머리말의 「왜 없는가」 ①
#      에 적어 두었다 — 이번 범위의 drizzle/ 변경이 **0줄**이다(4-ㄴ 이 값으로 잰다).
#   🔴 **마이그레이션이 1건이라도 생기는 판에서는 그 함수와 MIGTAR 변수와
#      「다섯째 산출물」 절을 71번에서 통째로 되살려라.** 셋이 한 벌이다 —
#      하나만 되살리면 묶음을 만들고도 **안을 한 번도 안 세게** 된다.
#   🔵 그래서 이 판에는 **tar 를 읽는 자리가 한 군데도 없다** — 함정 ⑦
#      (tar | grep -q 의 SIGPIPE)이 이번에는 걸릴 자리가 없다.

# ══════════════════════════════════════════════════════════════════════
# ── 🔴 --verify : **이미 구운 둘을 다시 재기만 한다** ────────────────
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
    printf '\n%s\n' "════════ 72-deploy.sh 의 TARS 에 넣을 줄 (tar 에서 다시 쟀습니다) ════════"
    printf '%s' "$TARTABLE"
  fi
  # 🔵 **묶음을 재는 절이 없다** — 이번 판은 묶음을 안 만든다(머리말 「왜 없는가」 ①).
  #    🔴 71-build.sh:2323-2337 에 그 절이 있었다. 묶음이 생기는 판에서는
  #       **migtar_inside() 와 함께** 되살려라 — 거기서 MIGTAR_SIZE·MIGTAR_MD5 를
  #       **다시 만들지 않고 열어서만 재어** 찍어 준다(만들면 md5 가 바뀐다).
  printf '\n%s\n' "════════ 묶음 — 🔵 **이번 판에는 없습니다** (마이그레이션 0건) ════════"
  printf '%s\n' "   🔴 .sql 이 생기는 판에서는 71-build.sh 에서 묶음 절을 되살리세요."
  printf '\n'
  if [ "$FAIL" = "0" ] && [ "$UNK" = "0" ] && [ "$VFAIL" = "0" ]; then
    printf '%s\n' "✅ --verify 전부 통과입니다. **아무것도 안 굽고 안 바꿨습니다.**"
    exit 0
  fi
  printf '%s\n' "🔴 ✗ 가 남아 있습니다 (앞 절 ✗ $FAIL · ? $UNK · 이미지 $VFAIL)"
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
printf '%s\n' "🔵 **둘입니다.** 10~20분쯤 걸릴 수 있습니다 — 중간에 끊지 마세요."
printf '%s\n' "🔵 dev 서버(3000)와 DB(5442·5444)는 **켜 둔 채로 둬도 됩니다** — .dockerignore 가"
printf '%s\n' "   .next 를 막고(5-ㄴ), 이 파일은 호스트의 npm run build 를 한 번도 안 부릅니다."
BUILT=0; BFAIL=0; TARTABLE=""; BUILD_SEEN=0
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
    printf '%s\n' "      🔵 **vendor 를 먼저 의심하세요** — vendor/dss-core 나 vendor/dss-ui 가"
    printf '%s\n' "         비어 있으면 Module not found 로 죽습니다(3-ㄷ)."
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
        printf '%s\n' "         바뀌면 정상적으로도 이만큼 뜁니다. 🔴 다만 이번 판은 package.json ·"
        printf '%s\n' "         package-lock.json 이 **0줄** 바뀌었습니다(5-ㄷ) — 그래서 strict 입니다."
        printf '%s\n' "         🔵 **지난 판 바이트는 71번(2026-11-25) 것**이라 하루 차이입니다 —"
        printf '%s\n' "            그 사이 베이스 이미지가 바뀌었을 확률이 낮습니다. 까닭을 모르면"
        printf '%s\n' "            **멈추고 알리세요.**"
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
# 🔵 **「다섯째 산출물 — 마이그레이션 묶음」 절이 없다**
# ══════════════════════════════════════════════════════════════════════
#   🔴 71-build.sh:2466-2497 에 그 절이 있었다. 까닭은 머리말의 「왜 없는가」 ① —
#      이번 범위의 drizzle/ 변경이 **0줄**이라 볼륨에 더할 .sql 이 없다(4-ㄴ).
#   🔴 **A/S 도구의 /app/drizzle 은 여전히 비어 있고**(inside_check 가 값으로 쟀다)
#      운영에서는 거기에 /volume1/dss/as-migrations 가 붙는다. 🔴 **.sql 이 한 장이라도
#      생기는 판에서는 이 절과 migtar_inside() 와 MIGTAR 변수를 71번에서 통째로
#      되살려라** — 안 되살리면 적용이 **0건으로 조용히** 끝나고 겉으로는 성공으로
#      보인다. 베껴 쓰면서 이 절을 빠뜨리는 것이 **그 판의 가장 큰 위험**이다.
#   🔵 그래서 이 판은 **보낼 것이 tar 둘뿐**이고 setup/incoming 에는 아무것도 안 간다.
printf '\n%s\n' "════════ 묶음 — 🔵 **이번 판에는 없습니다** (마이그레이션 0건) ════════"
printf '%s\n' "   🔵 보낼 것은 **tar 둘뿐**입니다 — setup/incoming 에는 아무것도 안 보냅니다."
printf '%s\n' "   🔴 **옛 폴더(_images-58 … _images-71)의 묶음을 보내지 마세요** — 보내면"
printf '%s\n' "      --migrate 가 없는 판에서 아무 일도 안 일어나지만, 다음 판이 그것을"
printf '%s\n' "      **이번 것으로 착각**합니다(쉰여섯째·쉰일곱째가 두 판 연속 밟았습니다)."

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  본 줄 %s / %s · 구운 것 %s / %s · **안을 실제로 센 횟수 %s** · 실패 %s\n' \
  "$BUILD_SEEN" "$HOWMANY" "$BUILT" "$HOWMANY" "$INSIDE_RAN" "$BFAIL"
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
  printf '%s\n' "       (이름|바이트|md5|Config 지문 — 72-deploy.sh 의 TARS 에 넣을 꼴입니다)"
  if [ -n "${TARTABLE:-}" ]; then printf '%s' "$TARTABLE"
  else printf '%s\n' "       (tar 가 한 줄도 없습니다 — 하나도 안 구워졌다는 뜻입니다.)"; fi
  printf '%s\n' "       🔵 **묶음 값(MIGTAR_SIZE·MIGTAR_MD5)은 아예 없습니다** — 이번 판은"
  printf '%s\n' "          묶음을 안 만듭니다. 묶음이 생기는 판에서는 71번에서 되살리세요."
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
for p in "$COREDIR:vendor/dss-core(A/S)" "$UIDIR:vendor/dss-ui(A/S)"; do
  pd=${p%%:*}; pn=${p#*:}
  d=$(git -C "$pd" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${d:-1}" = "0" ]; then printf '  ✓ %s 미커밋 0줄\n' "$pn"
  else printf '  ⚠️ %s 에 미커밋이 %s줄 생겼다 — 사람에게 알리세요\n' "$pn" "$d"; fi
done
printf '%s\n' "  🔵 **tar 는 이미 구워졌습니다** — 되돌릴지 그대로 둘지는 사람이 정하세요."

# ══ 🔴 72-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
printf '\n%s\n' "════════ 72-deploy.sh 에 붙여 넣을 것 (TARS **두 줄**) ════════"
printf '%s' "$TARTABLE"
printf '%s\n' "  🔴 위 **두 줄**로 TARS 를 통째로 갈아 끼웁니다 — 지금은 **비어 있습니다.**"
printf '%s\n' "  🔵 **묶음 값 둘(MIGTAR_SIZE·MIGTAR_MD5)은 이번 판에 아예 없습니다** —"
printf '%s\n' "     72-deploy.sh 에도 그 변수가 없습니다. 묶음이 생기는 판에서는 71번에서"
printf '%s\n' "     **셋을 한 벌로**(변수 둘 · 3-ㄴ 절 · place_migs) 되살리세요."
printf '%s\n' "  🔴 **NAS 에서 재서 채우지 마세요** — 자기가 잰 값으로 자기를 재면 영영 통과합니다."
printf '%s\n' "  🔵 그리고 위 **두 줄의 바이트를 README 에 적어 두세요** — 다음 판이 ①번"
printf '%s\n' "     크기 견주기에 그 값을 씁니다."
printf '\n%s\n' "✅ 둘을 다 구웠습니다. 산출물이 여기 있습니다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'

printf '\n%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **올리는 차례 — tar 둘. 묶음은 없다**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  🔴 PowerShell 경로는 **슬래시**로 적습니다. 역슬래시는 bash·scp 가 먹습니다."
printf '%s\n' "  🔴 **Tee-Object 로 로그를 받지 마세요** — PowerShell 이 UTF-16 으로 써서"
printf '%s\n' "     나중에 grep 이 한 줄도 못 찾습니다. NAS 쪽 로그 파일을 보세요."
printf '%s\n' "  🔴 **-O 를 빼지 마세요** — DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' ""
printf '%s\n' "  ① (개발 PC · PowerShell) **스크립트부터 올린다**"
printf '%s\n' "       cd \"C:/Users/희만/Desktop/Development/dss-deploy/nas/setup\""
printf '%s\n' "       scp -O 72-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "       Get-FileHash -Algorithm MD5 72-deploy.sh"
printf '%s\n' "     🔴 **TARS 두 줄을 먼저 채운 뒤에 올리세요.**"
printf '%s\n' "     🔴 **DSM 터미널은 긴 명령을 잘라 먹습니다** — 그래서 NAS 것은 스크립트"
printf '%s\n' "        파일로 올리고 **md5 를 맞댑니다.** 72-deploy.sh 가 돌 때 제 md5 를"
printf '%s\n' "        스스로 찍으니 위 Get-FileHash 값과 **눈으로 맞대세요.**"
printf '%s\n' ""
printf '%s\n' "  ② (NAS 터미널(SSH)) 지금 상태를 잰다 — 아직 아무것도 안 바뀐다"
printf '%s\n' "       sudo -i"
printf '%s\n' "       bash /volume1/dss/setup/72-deploy.sh            ← --check"
printf '%s\n' "       bash /volume1/dss/setup/72-deploy.sh --count    ← 올리기 전 수"
printf '%s\n' ""
printf '%s\n' "  ③ (개발 PC · PowerShell) **tar 둘을 보낸다 — 한 줄에 하나씩**"
printf '%s\n' "       cd \"$(printf '%s' "$OUT" | sed 's|^/c/|C:/|')\""
SCP_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  SCP_SEEN=$((SCP_SEEN+1))
  printf '%s\n' "       scp -O $(tar_name "$(field "$r" 3)") dss-nas:/volume1/dss/images/"
done <<ENDSCP
$(rows_of "$IMAGES")
ENDSCP
printf '%s\n' "     (보낼 tar $SCP_SEEN / $HOWMANY · 🔵 **묶음 없음**)"
printf '%s\n' "     🔴 **setup/incoming 에는 아무것도 안 보냅니다** — 이번 판은 묶음이 없습니다."
printf '%s\n' "        옛 폴더(_images-58 … _images-71)의 as-migrations.tar.gz 를 보내지 마세요."
printf '%s\n' ""
printf '%s\n' "  ④ (NAS 터미널(SSH)) **들여놓고 → 다시 재고 → 도구를 갈고 → 앱을 갈아 끼운다**"
printf '%s\n' "       bash /volume1/dss/setup/72-deploy.sh --preload"
printf '%s\n' "       bash /volume1/dss/setup/72-deploy.sh            ← 다시 --check"
printf '%s\n' "       bash /volume1/dss/setup/72-deploy.sh --tools    🔵 **DB 는 한 글자도 안 바뀐다**"
printf '%s\n' "       bash /volume1/dss/setup/72-deploy.sh --go       ⏱ 정지 창 (앱 **하나**)"
printf '%s\n' "       bash /volume1/dss/setup/72-deploy.sh --count    ← 올린 뒤 수"
printf '%s\n' "     🔴 **--migrate 는 없습니다** — 이번 판은 마이그레이션이 **0건**이라 그 자리가"
printf '%s\n' "        **--tools** 입니다(덤프를 뜨고 · 도구 태그 한 줄을 갈고 · 새 도구로"
printf '%s\n' "        db:preflight 를 돌려 **대기 0건**을 값으로 받습니다)."
printf '%s\n' "     🔴 **--tools 를 건너뛰고 --go 로 가지 마세요** — 운영의 도구가 **옛 몸통**으로"
printf '%s\n' "        남고, 거기서 도는 check:* 가 **어제 소스**로 셉니다."
printf '%s\n' ""
printf '%s\n' "🔴 **되돌리기**: --rollback 은 앱 **하나**를 옛 태그(dss-as:6.2)로 되돌립니다."
printf '%s\n' "   🔵 도구는 새 판 그대로 둡니다(39·41~71번과 같은 판단)."
printf '%s\n' "   🔵 **DB 는 되돌릴 것이 없습니다** — 이 배포는 한 글자도 안 바꿉니다."
printf '%s\n' "────────────────────────────────────────────────────────────"
printf '\n%s\n' "🔴🔴🔴 **72-deploy.sh 에 넣을 값 (다시 찍습니다 — 여기만 복사해도 됩니다)**"
printf '%s\n' "── TARS 두 줄"
printf '%s' "$TARTABLE"
printf '%s\n' "🔵 **묶음 값은 없습니다** — 이번 판은 묶음을 안 만듭니다."
printf '%s\n' "🔴🔴🔴 위를 72-deploy.sh 에 **그대로** 적은 뒤 scp 하세요."
