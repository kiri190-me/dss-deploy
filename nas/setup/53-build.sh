#!/bin/bash
# dss-deploy/nas/setup/53-build.sh — 쉰째 배포 · 이미지 굽기 (2026-11-07)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · PowerShell 에서 Git Bash 를 부른다) ──────────
#     cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#     & "C:\Program Files\Git\bin\bash.exe" ./53-build.sh --check
#     & "C:\Program Files\Git\bin\bash.exe" ./53-build.sh --go
#
#   🔴 **bash.exe 만 치면 WSL 이 잡힌다**(2026-11-04 에 걸렸다). WSL 에서 돌면
#      도커도 양식도 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 내어 ✗ 가
#      셋 흩어져 난다. 단서는 로그의 뿌리 경로가 **/mnt/c/…** 인 것이다.
#      그래서 위처럼 **Git Bash 의 전체 경로를 큰따옴표로 묶어** 부른다.
#   🔴 **스크립트에 건네는 경로에는 역슬래시를 쓰지 않는다.** 역슬래시를 주면
#      bash 가 그것을 먹어 "C:Users희만Desktop…" 이 되어 No such file 이 난다.
#      위처럼 **폴더로 먼저 들어가서 ./53-build.sh** 로 부르면 그 함정이 없다.
#      🔵 51-deploy.sh 의 6~9줄 · 1152줄 · 1333줄에 역슬래시 예시가 아직 남아
#         있다. **거기서 베껴 오지 마라.**
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-50):
#     & "C:\Program Files\Git\bin\bash.exe" ./53-build.sh --go "/d/배포본/_images-50"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다.
#      이 파일을 쓴 쪽은 **한 번도 굽지 않았다** — --check 만 돌려 보았다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이번 판은 **지난 열네 판과 모양이 다르다** — 여기부터 읽어라
# ══════════════════════════════════════════════════════════════════════
#   ① **포털(dss-auth)도 굽는다.** 40~52번은 전부 A/S 만 구웠다. 포털을 구운
#      마지막은 **39-build.sh**(dss-auth:1.9 → 2.0, 2026-10-27)이고 **14판 전**이다.
#      🔴 그래서 39번에서 **포털을 다루는 부분만** 참고했고, 거기 적힌 값·경로·
#         서비스 이름은 **하나도 그대로 믿지 않고 다시 쟀다**(아래 2·5·6절).
#      🔵 틀·절·검사 방식은 **52-build.sh** 를 베꼈다 — 지금 관례다.
#   ② **마이그레이션이 1건 있다 — 0124.** 48번(0121·0122·0123) 이후 처음이다.
#      그래서 **as-migrations.tar.gz 를 반드시 보내야 한다**(볼륨이 124 → 125).
#      🔵 52번은 0건이라 「안 보내도 된다」였다. **그 글을 베껴 오면 안 된다.**
#
# ── 이번에 굽는 것 — **저장소 둘, 이미지 넷** ─────────────────────────
#     ① A/S 앱    dss-as:4.5        → **dss-as:4.6**        커밋 10  스테이지 기본(runner)
#     ② A/S 도구  dss-as-tools:12   → **dss-as-tools:13**   커밋 10  🔴 --target tools
#     ③ 포털 앱   dss-auth:2.0      → **dss-auth:2.1**      커밋 1   스테이지 기본(runner)
#     ④ 포털 도구 dss-auth-tools:3  → **dss-auth-tools:4**  커밋 1   🔴 --target tools
#
#   🔵 그리고 **다섯째 산출물** — A/S 마이그레이션 묶음 as-migrations.tar.gz.
#      A/S 의 drizzle/ 은 **이미지에 안 굽는다**(28MB 라 볼륨이다). 이번 판은
#      마이그레이션이 **1건**이라 이 묶음을 **반드시 보내야** 적용이 된다.
#
#   🔴 **PO(dss-po)는 안 굽는다** — HEAD 가 기준 SHA(9c1b2ef) 와 글자 그대로 같고
#      이후 커밋이 **0** 이다(2026-11-07 실측. 아래 2절이 다시 잰다).
#
#   🔵 **양식(.xlsx)은 한 장도 안 올린다.** 이번 범위에 .xlsx 변경이 **0줄**이고,
#      개발 PC 의 양식 열하나가 52번이 적어 둔 바이트·md5 와 **전부 같았다**
#      (2026-11-07 실측 — 8절이 다시 잰다). 그래서 이 파일에는 **양식을 복사하는
#      절이 없다.** 🔴 **양식이 바뀌는 날 되살릴 곳**: 51-build.sh 의 8절과 꼬리말,
#      51-deploy.sh 의 --templates-prep(1056~1172줄) · --templates-apply(1174~1341줄).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 기준 SHA — **출처 둘을 맞대어 확인했다** (2026-11-07)
# ══════════════════════════════════════════════════════════════════════
#   ㄱ) **A/S — c6b2b271.**
#        · dss-deploy/README.md 의 「기준 SHA … (2026-11-06 09:30 갱신)」 표:
#            | A/S 관리 | RF_Service_System | **4.5** | **c6b2b271** |
#        · 49번 배포 기록(README 12~32줄)의 범위가 8a98e461..**c6b2b271** 이고
#          「커밋 13 · 파일 83」이다 — 49번이 실제로 구운 HEAD 다.
#   ㄴ) **포털 — 52cbb19.** 같은 표: | 통합 로그인 | dss-auth | **2.0** | **52cbb19** |
#        · 36번(스크립트 39) 기록이 「포털 커밋 1 · 52cbb19 · dss-auth:1.9 → 2.0」
#          이라고 적는다 — 포털을 마지막으로 구운 HEAD 다. **두 출처가 같다.**
#   ㄷ) **PO — 9c1b2ef.** 같은 표: | PO | dss-po | **0.9** | **9c1b2ef** |
#   🔴 아래 2절이 **merge-base --is-ancestor** 로 다시 잰다. 표가 낡았거나 가지가
#      갈렸으면 거기서 ✗ 가 난다 — 머리말의 글이 아니라 저장소가 답한다.
#
# ── 🔴 지시서의 커밋 수가 **하나 모자랐다** — 여기를 꼭 읽어라 ────────
#   이 파일을 쓰라는 지시서는 A/S 를 「커밋 9개 · 161파일」이라고 적었다.
#   🔴 **그 수는 기준 SHA 가 541287aa 일 때의 값이다.** 운영에 올라간 기준은
#      **c6b2b271** 이고, 그 사이에 **541287aa 「짐을 설비 유형으로 나눠 뜬다」**
#      가 **아직 안 나갔다.** 그래서 진짜 범위는 **커밋 10 · 파일 163** 이다
#      (2026-11-07 실측: git log --oneline c6b2b271..HEAD 가 10 · diff 가 163).
#   🔵 이것이 README 가 「이 표 하나만 믿지 마라」라고 적어 둔 바로 그 함정이고,
#      이 저장소의 「배포 범위는 기준 SHA 로 센다 — 최근 N개로 세다 가운데 셋을
#      놓쳤다」와 같은 모양이다. 🔴 **고치지 말고 보고한 뒤 이 값으로 갔다.**
#
# ── 이번 범위의 커밋 — A/S **열** · 포털 **하나** · PO **0** ──────────
#   A/S  c6b2b271..62a42be8  (2026-11-07 실측: 커밋 10 · 파일 163)
#     62a42be8 기타건은 승인이 끝나야 [완료] 처리가 된다 · 기본정보를 두 박스로
#     59673488 기타건 결재가 종·통합 승인함·메일에 뜬다 · 종 배지는 보이는 줄 수다
#     37536966 기타건 현황 — 수리건 안 붙은 내자 줄을 모아 본다
#     570ec2b9 기타건 상세의 승인 탭 — 기타건 최종 출하승인을 따로 받는다
#     7447c6e1 기타건 상세의 발주서 탭 — 내자에 적힌 번호로 폴더를 찾는다
#     060863dd 기타건 상세의 견적서 탭 — 연결된 견적서, 없으면 번호로 공유폴더
#     bc2108c2 기타건 상세를 세운다 — 내자정리의 [형식]을 누르면 열린다
#     137ad2d6 기타 견적서를 만들면 내자정리에 줄이 하나 선다
#     45617812 견적서 공급처를 고르개로 — 고객사 마스터와 잇는다
#     541287aa 짐을 설비 유형으로 나눠 뜬다 — 작성자를 RFG·MB 따로 적으려고
#   포털 52cbb19..f87bf7d  (커밋 1 · 파일 13)
#     f87bf7d 종 배지는 보이는 줄 수다 · 기타건 결재 갈래를 메일 표에 등록
#   PO   9c1b2ef..9c1b2ef → **0줄.** 구울 것이 없다.
#
#   🔵 **공용 스키마(vendor/dss-core)도 한 칸 움직인다** — 20bb394 → **460458a**.
#      그 커밋이 고치는 둘은 src/schema/repair-case-approvals.ts ·
#      src/schema/shipment-approval-routes.ts 다(2026-11-07 실측). 🔴 서브모듈은
#      **별도 저장소가 아니라 A/S 의 포인터로 따라 들어간다** — 3절이 핀을 잰다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 마이그레이션 0124 — 「지우는 문장」이 **0** 이고 「살펴볼 문장」이 **2**
# ══════════════════════════════════════════════════════════════════════
#   drizzle/0124_deep_masked_marvel.sql 이 하는 일(2026-11-07 그 파일을 읽어 적음):
#     ALTER TYPE repair_case_approval_type   ADD VALUE 'DOMESTIC_ORDER_FINAL_SHIPMENT'
#     ALTER TYPE shipment_approval_route_scope ADD VALUE 'DOMESTIC_ORDER_FINAL_SHIPMENT'
#     ALTER TABLE repair_case_approvals DROP CONSTRAINT …delegation_only_for_final_shipment
#     ALTER TABLE repair_case_approvals DROP CONSTRAINT …route_only_for_final_shipment
#     ADD COLUMN domestic_order_id uuid
#     ADD CONSTRAINT …_fk FOREIGN KEY … ON DELETE set null
#     CREATE UNIQUE INDEX …_one_active_domestic_request  /  CREATE INDEX …_domestic_order_id_idx
#     ADD CONSTRAINT … CHECK (…) **넷** — 위에서 뗀 둘을 **넓혀서 다시 세우는 것 포함**
#
#   🔴 ① **ON DELETE set null 을 「지우는 문장」으로 세면 안 된다.** 이 저장소에
#      기록돼 있다 — 「표만 더하는 판이 ✗ 가 된다, 앱의 migration-safety 와 **같은
#      잣대**로 세고 새 배포본은 **19번을 베낀다**」. 그래서 19-deploy.sh 의 그 잣대
#      (그 파일 452줄 DESTRUCTIVE_RE)를 **글자 그대로** 가져왔다:
#          DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM
#      앱 쪽 원본은 RF_Service_System/src/lib/db/migration-safety.ts 의
#      findDestructiveOperations 다 — DROP TABLE/COLUMN/SCHEMA · TRUNCATE ·
#      DELETE FROM 만 세고 **DROP CONSTRAINT 도 ON DELETE 도 안 센다.**
#      🔵 2026-11-07 실측: 0124 에 **0건.** 가짜 DROP 표본으로 잣대가 살아 있는지
#         확인하고(1 이 나와야 한다), ON DELETE 표본으로 안 걸리는지 확인한다(0).
#
#   🔴 ② **「살펴볼 문장」은 따로 센다 — 기대 2건.** 앱의 findRiskyOperations 가
#      DROP CONSTRAINT 를 그 갈래로 잡는다. 🔵 앱의 db:preflight 가 이 판을
#      **「자료는 그대로지만 살펴볼 문장 2건」**으로 통과시킨다(종료 코드 0 — 그
#      갈래는 종료 코드에 관여하지 않는다. check-pending-migrations.ts 187줄).
#      🔴 **0 으로 기대하면 안 되고, 안 세도 안 된다.** 안 세면 「제약 둘이 빠진
#         판」과 「빠졌다 다시 선 판」이 구별되지 않는다 — 이 파일은 **다시 세우는
#         ADD CONSTRAINT 둘까지** 글자로 확인한다(4절).
#
#   🔴 ③ **enum 새 값과 CHECK 이 한 트랜잭션에 함께 들어간다.** drizzle 은 밀린
#      마이그레이션을 전부 한 트랜잭션에 넣고, PostgreSQL 은 같은 트랜잭션에서
#      방금 더한 enum 값을 **쓰지 못한다.** 이 판이 통과하는 까닭은 CHECK 을
#      「approval_type::text = …」 로 적었기 때문이다 — enum 리터럴이 아니다.
#      🔵 개발에서 한 번 멈췄다가 그렇게 고친 자리이고, **운영에서도 같은 명령**
#         (npm run db:migrate)을 쓴다. 🔴 53-deploy.sh 는 **종료 코드만 보고
#         「성공」이라 말하지 않는다** — 적용 뒤 DB 를 다시 읽어 칸·enum·제약·
#         인덱스를 **값으로** 센다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 도구 이미지 **둘 다** 굽는다 — 잣대를 저장소마다 따로 쟀다
# ══════════════════════════════════════════════════════════════════════
#   잣대는 41·48·52번이 쓰던 셋 그대로다:
#     ㄱ) npm 명령이 늘었나   ㄴ) 도구의 import 닫힘 안이 바뀌었나
#     ㄷ) tools 스테이지가 담는 것 중 바뀐 파일이 있나
#
#   ── A/S 도구(dss-as-tools:13) — ㄴ·ㄷ 이 굽는다 ─────────────────────
#     ㄱ **안 걸린다.** package.json diff **0줄** · scripts 항목 **37 → 37**
#        (2026-11-07 실측). 🔴 52번은 여기가 걸렸지만 **이번 판은 아니다** —
#        52번의 「41번 잣대가 되살아났다」를 그대로 베끼면 가짜 ✗ 가 난다.
#     ㄴ **걸린다.** 등록된 명령 스물셋 + 백필 하나 = **시작점 24** 에서 닫힘을
#        다시 재어 **233개**(못 푼 상대경로 0). 그 233 과 바뀐 163 이 겹치는 것이
#        **10개**다. 그중 **넷은 기준판에 아예 없던 파일**이다:
#              src/lib/domain/domestic-order-approval-rules.ts  ← NEW
#              src/lib/domain/domestic-order-detail-link.ts     ← NEW
#              src/lib/domain/domestic-order-detail-tabs.ts     ← NEW
#              src/lib/domain/domestic-order-display.ts         ← NEW
#              scripts/export-procedure-bundle.ts
#              src/lib/auth/permission-areas.ts
#              src/lib/auth/permission-baseline.ts
#              src/lib/domain/notifications.ts
#              src/lib/domain/shipment-approval-route.ts
#              src/lib/validation/quote-input.ts
#        🔴 그리고 **공용 스키마 둘이 닫힘 안에 있다** —
#              vendor/dss-core/src/schema/repair-case-approvals.ts
#              vendor/dss-core/src/schema/shipment-approval-routes.ts
#           둘 다 460458a 가 고친 그 둘이다. 도구가 그 스키마로 DB 를 읽는다.
#     ㄷ **걸린다.** tools 스테이지가 담는 것(package.json · tsconfig.json ·
#        drizzle.config.ts · scripts/ · src/ · vendor/) 중 바뀐 파일 **158개**.
#        바깥은 **다섯** — API_FOR_INTERNAL_SYSTEMS.md · 진행현황.html · drizzle/ 셋.
#     🔵 그리고 **procedures:export 가 --prefix 를 받게 됐다**(541287aa). 그 도구는
#        개발 PC 에서만 돌지만 **담기는 것 안**이라 이미지가 낡으면 꼬리말의
#        명령과 이미지가 어긋난다.
#
#   ── 포털 도구(dss-auth-tools:4) — ㄴ·ㄷ 이 굽는다 ───────────────────
#     ㄱ **안 걸린다.** package.json diff **0줄** · scripts 항목 **25 → 25**.
#     ㄴ **걸린다.** 등록된 명령이 가리키는 scripts/*.ts **13개**를 시작점으로
#        닫힘을 재어 **65개**(못 푼 상대경로 0). 바뀐 13 과 겹치는 것이 **4개**:
#              src/lib/approvals/kinds.ts      ← send-approval-mails 가 부른다
#              src/lib/approvals/plan.ts       ← 같은 길
#              src/lib/approvals/sources.ts    ← 같은 길
#              src/lib/notifications/merge.ts  ← check-notifications 가 부른다
#        🔵 **밤마다 도는 purge-expired.ts 의 닫힘은 0개**가 바뀐다 — 즉 안 구워도
#           야간 정리는 멀쩡하다. 그럼에도 굽는 까닭은 **check:notify 가 옛 잣대로
#           배지를 세어 사람에게 틀린 수를 말하게 되기 때문**이다. 「종 배지는
#           보이는 줄 수다」가 바로 이번 판에서 고친 그 셈이다.
#     ㄷ **걸린다.** tools 스테이지가 담는 것(package.json · tsconfig.json ·
#        drizzle.config.ts · src/ · drizzle/ · scripts/) 중 바뀐 파일 **11개**.
#        🔵 바뀐 13 중 **둘은 docs/ 라 .dockerignore 가 막는다** — 이미지에 안 간다.
#     🔵 **39번이 굽던 까닭(비상구 둘)은 이번 판의 까닭이 아니다.** 그 둘
#        (admin:promote · admin:emergency)은 **이미 :3 에 들어 있고** 이번에 한 글자도
#        안 바뀌었다. 🔴 그래도 **있는지는 계속 센다** — 한 번 빼면 다시 넣는 사람이 없다.
#     🔴 52-deploy.sh 꼬리말에 남아 있던 'npm run admin:promote' 를 51번이
#        **A/S 쪽에 없는 명령**이라고 걷어냈는데, **포털에는 있다**(25개 중 하나).
#        같은 글자라도 집이 다르면 답이 다르다 — 이 파일은 **포털 것만** 센다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 알고도 안 고친 것 — **PO 가 새 거절 코드를 모른다**
# ══════════════════════════════════════════════════════════════════════
#   이번 판부터 A/S 의 「POST /api/v1/domestic-orders/{id}/completion」 이
#   **409 APPROVAL_REQUIRED** 를 돌려줄 수 있다(API_FOR_INTERNAL_SYSTEMS.md 158줄).
#   그런데 운영에 도는 **dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 그 코드가
#   없다**(dss-po/src/lib/server/as-gateway.ts 71~79줄 · 2026-11-07 실측).
#   🔴 그래서 PO 에서 기타건을 [완료 처리] 하면 A/S 가 **왜 막혔는지 적어 보낸
#      문장이 PO 화면에 안 뜨고**, 「모르는 응답」으로 떨어져 **「바뀌었는지 알 수
#      없다」**가 된다. 🔵 자료가 깨지지는 않는다 — A/S 는 한 글자도 안 쓴 채
#      거절했고, PO 도 「완료되었습니다」라고 말하지 않는다.
#   🔴 **이 파일은 그것을 고치지 않는다**(PO 는 이번에 안 굽고, 고치려면 PO 코드
#      변경이 필요하다 — 지시서 범위 밖이다). 대신 **5절-ㅍ 이 그 목록을 글자로
#      세어 ⚠️ 로 알린다.** 53-deploy.sh 꼬리말에도 적어 둔다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 배포 뒤 **사람이 해야 하는 일 둘** — 꼬리말에 다시 찍는다
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 [사용자 관리] › [승인 절차] 에서 **「기타건 최종 출하 승인」 결재선을
#      한 판 세운다.** 안 세우면 **기타건을 아무도 [완료] 처리할 수 없다** —
#      새 갈래는 판이 0개이고, 이번 판부터 완료에 승인이 필요하다.
#      (RF_Service_System/src/lib/domain/domestic-order-approval-rules.ts 의
#       resolveMiscCaseCompletionGate — 판이 없으면 ROUTE_MISSING 으로 막는다)
#   ② 포털 관리자 화면 › 결재 알림 메일 에서 **「기타건 최종 출하 결재」 스위치를
#      켠다.** 🔵 안 켜도 **종과 통합 승인함은 뜬다.** 메일만 안 간다.
#      기본값이 끔인 것은 2026-10-23 결정이다.
#
# ── 🔴 모드 둘 ────────────────────────────────────────────────────────
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다.
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면
#            굽지 않고 멈춘다. 전부 ✓ 일 때만 넷을 굽고 tar 로 뽑는다.
#            그리고 **이미지 안을 센다**(겉이 아니라 결과). 묶음도 만든다.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 tar 크기를 **두 번** 견준다 — 그런데 **엄함이 집마다 다르다** ──
#   ① **지난 판 tar 와** 견준다. 적어 둔 값의 출처:
#        dss-as-4.5.tar       133874688  [실측] 2026-11-07 _images-49 에서 stat
#        dss-as-tools-12.tar  224836096  [실측] 2026-11-07 _images-49 에서 stat
#        dss-auth-2.0.tar     113688576  [배포본] 39-deploy.sh 의 TARS (**14판 전**)
#        dss-auth-tools-3.tar 212256768  [배포본] 39-deploy.sh 의 TARS (**14판 전**)
#      🔴 **A/S 둘은 한 판 전이라 25% 를 넘으면 ✗ 다.**
#      🔴 **포털 둘은 14판 전이라 같은 잣대를 대면 가짜 ✗ 가 난다.** 베이스
#         이미지(node:22-bookworm-slim)가 떠 있는 태그라 그 사이에 바뀌었을 수
#         있다. 그래서 포털은 **25% 넘으면 ⚠️ · 60% 넘으면 ✗** 로 갈랐다.
#         🔵 「스테이지를 잘못 구웠다」는 크기가 아니라 **이미지 안**이 잡는다
#            (runner 면 /app/server.js · tools 면 /app/package.json). 그쪽이 훨씬 세다.
#   ② **그 이미지 자신과** 견준다. 🔴 여기가 함정이라 가지를 둘로 나눴다:
#      · containerd 저장소면 'docker image inspect {{.Size}}' 가 **압축된 내용
#        크기**를 주어 tar 와 거의 같다(90~110%).
#      · 고전 저장소면 그 값이 **펼친 크기**라 tar 는 그 **1/4쯤**이다(10~45%).
#      🔴 **둘 중 어느 쪽인지 미리 못 정한다.** 한 잣대로 재면 **가짜 ✗** 가 난다.
#   🔴 **tar 지문은 'docker image inspect' 의 .Id 와 맞대지 않는다.** 그것은
#      애초에 다른 값이다. 맞댈 상대는 **빌드 로그의 'exporting config sha256:'** 이다.
#
# ── 🔴 이 환경의 함정 (36~52-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싸고, 저장소 자리를
#      이 파일의 자리에서 계산한다(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:/… 를 /c/… 로
#      바꾸고, docker save 는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#      🔴 이 파일의 tar/docker save 어디에도 드라이브 문자가 들어가지 않는다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를
#      막는다 — 아래 5절이 그것도 잰다). 다만 메모리는 다르다.
#   ④ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다.** 한글을 argv 로 넘기면
#      깨지는 길이 열린다 — 아래 검사의 이름은 전부 ASCII 다.
#   ⑤ 🔵 **이번 판의 파일 목록에는 대괄호가 있다**(src/app/api/… 의 [id]).
#      그래서 목록은 **따옴표로 감싼 여러 줄 변수**로만 다루고, 글롭으로 펴지
#      않는다. 🔴 「대괄호 폴더의 시험은 조용히 안 돈다」와 같은 뿌리다.
#   ⑥ 🔵 **양식 경로는 .env.local 에서 꼴이 두 가지다** — 앞 다섯은 빗금,
#      뒤 여섯은 **역빗금**이다(2026-11-07 실측으로 52번의 글이 여전히 맞았다).
#      그래서 8절은 이름을 끊기 전에 **반드시 to_unix() 를 거친다.**
#   ⑦ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」
#      같은 안전망을 달면 **하필 바라던 0 에서만** 그것이 터져 값이 "0 ?" 가 된다
#      (2026-11-06 52-build.sh 에서 실제로 났다). 이 파일은 그 꼴을 **한 군데도
#      쓰지 않는다** — 셈을 받을 때는 「$( … || true )」 로 **종료 코드만** 가린다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안의 백틱은 명령 치환으로 읽힌다 → 이 파일에는 백틱이
#      **한 개도 없다**(주석에도 안 썼다). 쓴 뒤 grep 으로 세었다.
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
#    🔵 역빗금을 빗금으로 먼저 바꾸므로 **양식 경로 두 꼴을 다 받는다**(함정 ⑥).
to_unix() { # 1 경로
  local p=${1//\\//}
  case "$p" in
    [A-Za-z]:/*) p=/$(printf '%s' "${p%%:*}" | tr 'A-Z' 'a-z')${p#?:} ;;
  esac
  printf '%s' "$p"
}

tar_name() { printf '%s.tar' "$(printf '%s' "$1" | tr ':' '-')"; }

# tar 안 manifest.json 의 Config 지문 (39~52-build.sh 의 것을 글자 그대로)
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
# 🔴 '네 칸 들여쓴 따옴표 줄'을 통째로 세면 dependencies 까지 섞인다.
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
#      🔴 **A/S 는 3 이다** — 0124.sql · meta/0124_snapshot.json · meta/_journal.json.
#         0 이 아니다. 52번의 「0 이어야 한다」를 베껴 오면 가짜 ✗ 가 난다.
#      🔵 포털은 **0** 이다(마이그레이션 없음).
#      🔴 「0 이면 통과」가 아니라 **적어 둔 수와 똑같아야** 한다.
#   🔵 일곱째 칸(커밋 수)은 ✗ 로 세지 않고 ⚠️ 로만 센다 — 어긋나면 표가 낡았다는
#      뜻이라 사람이 봐야 한다. A/S 열 · 포털 하나다.
#   🔴 'astools'·'authtools' 는 **같은 저장소**를 --target tools 로 한 번 더 굽는
#      줄이다. 저장소를 세는 자리에서는 건너뛴다 — 두 번 세면 ✗ 도 두 번 센다.
#   🔵 열째 칸: strict = 25% 넘으면 ✗ · loose = 25% ⚠️ · 60% 넘으면 ✗ (머리말).
#   🔴 **PO 줄이 없다.** 이번 판은 PO 를 안 굽는다.
SITES='
as|RF_Service_System|dss-as:4.6|c6b2b271|-|3|10|133874688|dss-as-4.5.tar|strict
astools|RF_Service_System|dss-as-tools:13|c6b2b271|tools|3|10|224836096|dss-as-tools-12.tar|strict
auth|dss-auth|dss-auth:2.1|52cbb19|-|0|1|113688576|dss-auth-2.0.tar|loose
authtools|dss-auth|dss-auth-tools:4|52cbb19|tools|0|1|212256768|dss-auth-tools-3.tar|loose
'
HOWMANY=4
AS_TOOLS_TAG=dss-as-tools:13
AUTH_TOOLS_TAG=dss-auth-tools:4
AS_APP_TAG=dss-as:4.6
AUTH_APP_TAG=dss-auth:2.1
# 🔵 되돌릴 판 — 53-deploy.sh --rollback 이 쓰는 그것이다.
AS_OLD_TAG=dss-as:4.5
AUTH_OLD_TAG=dss-auth:2.0
AS_TOOLS_OLD_TAG=dss-as-tools:12
AUTH_TOOLS_OLD_TAG=dss-auth-tools:3

# ── 🔴 기대값과 그 출처 — 전부 [실측] 2026-11-07 개발 PC ───────────────
AS_BASE=c6b2b271
AUTH_BASE=52cbb19
PO_BASE=9c1b2ef

# 🔴 A/S drizzle — **125 로 늘었다.** 마지막이 0124 이고 0125 는 없어야 한다.
AS_SQL_WANT=125
AS_PREV_MIG=0123      # 48번이 올린 마지막
AS_NEW_MIG=0124       # 🔴 이번 판이 올리는 것
AS_NEXT_MIG=0125      # 🔴 이것이 생겼으면 전제가 깨진 것이다
# 🔴 **다음 번호를 셈으로 만들지 않는다.** bash 의 $(( )) 는 0 으로 시작하는 수를
#    **8진수**로 읽어 0124+1 이 85 가 된다 — 오류 없이 엉뚱한 파일을 찾는다.
#    그래서 글자로 적어 두고, 아래에서 이어지는 번호인지 한 번 맞대어 본다.
AS_NEW_MIG_FILE=0124_deep_masked_marvel.sql
# 🔵 포털 drizzle — **그대로여야** 한다(이번 판에 마이그레이션 0건).
AUTH_SQL_WANT=10

# 🔴 0124 안의 문장 세기 — 앱의 migration-safety.ts 와 **같은 잣대**(19번 452줄).
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
MIG_DESTRUCT_WANT=0
# 🔴 「자료는 그대로지만 살펴볼 문장」 — 앱의 findRiskyOperations 가 잡는 갈래다.
#    DROP CONSTRAINT · DROP INDEX · DROP TYPE · RENAME · SET NOT NULL.
#    🔵 이 판은 DROP CONSTRAINT **둘**이고 둘 다 같은 파일에서 다시 세워진다.
RISKY_RE='DROP[[:space:]]+(CONSTRAINT|INDEX|TYPE)|RENAME[[:space:]]+(TO|COLUMN)|SET[[:space:]]+NOT[[:space:]]+NULL'
MIG_RISKY_WANT=2
# 🔴 0124 가 **정말 그 파일인지** 보는 글자들. 전부 ASCII 다.
MIG_MARK_ENUM1='ALTER TYPE "public"."repair_case_approval_type" ADD VALUE'
MIG_MARK_ENUM2='ALTER TYPE "public"."shipment_approval_route_scope" ADD VALUE'
MIG_MARK_COL='ADD COLUMN "domestic_order_id" uuid'
MIG_MARK_UNIQ='repair_case_approvals_one_active_domestic_request'
MIG_MARK_IDX='repair_case_approvals_domestic_order_id_idx'
# 🔴 **뗐다가 다시 세우는 둘** — 「뗀 것」만 세고 「다시 세운 것」을 안 세면
#    제약이 사라진 판과 넓혀 다시 선 판이 구별되지 않는다.
MIG_REDO1='ADD CONSTRAINT "repair_case_approvals_delegation_only_for_final_shipment"'
MIG_REDO2='ADD CONSTRAINT "repair_case_approvals_route_only_for_final_shipment"'

# 서브모듈 포인터 셋. 🔴 **A/S 의 dss-core 가 이번에 움직인다** — 20bb394 → 460458a.
#    🔵 PO 의 8730c94 는 460458a 의 **조상**이고 여덟 커밋 뒤다(2026-11-07 실측).
#       🔴 **이 배포에서 맞추지 않는다** — PO 를 안 굽는다.
AS_CORE_PIN=460458ad3ae1cd8703930cb7208d0c12391cee64
AS_CORE_PIN_OLD=20bb394f5a8e33d8357a93c3c5c28b5145a9b1d4
PO_CORE_PIN=8730c9433b4388a038349ab9a11ec633659da782
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425        # 🔵 안 움직인다
# 🔵 460458a 가 고치는 둘 — 도구 닫힘 안에 있다(머리말).
CORE_CHANGED='src/schema/repair-case-approvals.ts src/schema/shipment-approval-routes.ts'
CORE_CHANGED_WANT=2

# 🔵 A/S — 저장소 전체 163 · tools 스테이지가 담는 것 158 · 바깥 다섯.
AS_ALL_CHANGED_WANT=163
AS_TOOLS_CHANGED_WANT=158
# 🔵 포털 — 저장소 전체 13 · 이미지에 가는 것 11(docs/ 둘은 .dockerignore 가 막는다).
AUTH_ALL_CHANGED_WANT=13
AUTH_IMG_CHANGED_WANT=11
# 🔴 PO 는 0 이어야 한다.
PO_CHANGED_WANT=0

# 🔵 npm 명령 수 — **둘 다 안 늘었다.** 41번 잣대는 이번 판에 **안 걸린다.**
AS_NPM_WAS=37;   AS_NPM_NOW=37
AUTH_NPM_WAS=25; AUTH_NPM_NOW=25
AS_PKG_LINES_WANT=0
AUTH_PKG_LINES_WANT=0
# 🔴 사라지면 안 되는 A/S 명령 — 48·52번이 올린 것과 운영에서 불리는 것.
AS_KEEP_NPM="check:target-shipment-missing check:due-date-inverted check:requested-due-date-sync procedures:export procedures:import db:preflight db:migrate"
AS_KEEP_NPM_WANT=7
# 🔴 사라지면 안 되는 포털 명령 — 39번이 연 비상구 둘 + 야간 정리 + 진단 둘.
AUTH_KEEP_NPM="admin:promote admin:emergency db:purge check:notify check:notify:site db:migrate"
AUTH_KEEP_NPM_WANT=6

# ══ 🔴 A/S 도구 닫힘 — 시작점 24 · 닫힘 233 · 겹침 10 ═════════════════
#   🔵 재는 법은 48·52번과 **같은 잣대**다(주석을 걷고, 상대경로 · '@/' ·
#      '@dss/core/schema' · '@dss/core/ui/*' · '@dss/ui' 를 따라가고, export … from
#      과 타입 전용 import 까지 따라간다). 2026-11-07 에 다시 재어 233 · 못 푼
#      상대경로 0 이었다(52번은 같은 잣대로 231 이었다 — 둘 늘었다).
#   🔴 **그 파일이 아직 저장소에 있나** 가드를 그대로 둔다 — 이름이 바뀌었는데
#      0 이 나와 「안 바뀌었다」로 조용히 지나가는 길을 막는다.
AS_TOOLS_CALLED='
scripts/export-procedure-bundle.ts
src/lib/auth/permission-areas.ts
src/lib/auth/permission-baseline.ts
src/lib/domain/domestic-order-approval-rules.ts
src/lib/domain/domestic-order-detail-link.ts
src/lib/domain/domestic-order-detail-tabs.ts
src/lib/domain/domestic-order-display.ts
src/lib/domain/notifications.ts
src/lib/domain/shipment-approval-route.ts
src/lib/validation/quote-input.ts
'
AS_TOOLS_CALLED_WANT=10
# 🔴 그중 **기준판에 아예 없던 파일 넷** — 이미지 안에서 존재만 봐도 새 판이다.
AS_BORN='
src/lib/domain/domestic-order-approval-rules.ts
src/lib/domain/domestic-order-detail-link.ts
src/lib/domain/domestic-order-detail-tabs.ts
src/lib/domain/domestic-order-display.ts
'
AS_BORN_WANT=4

# ══ 🔵 포털 도구 닫힘 — 시작점 13 · 닫힘 65 · 겹침 4 ══════════════════
AUTH_TOOLS_CALLED='
src/lib/approvals/kinds.ts
src/lib/approvals/plan.ts
src/lib/approvals/sources.ts
src/lib/notifications/merge.ts
'
AUTH_TOOLS_CALLED_WANT=4

# ══ 🔴 「이번 판인가」를 글자로 가르는 표식 ════════════════════════════
#   🔴 전부 **기준판에 0번 · 지금 판에 1번 이상**이다(2026-11-07 git show 로 확인).
#      이름은 모두 ASCII 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
#   형식: 글자|파일
AS_MARKS='
DOMESTIC_ORDER_FINAL_SHIPMENT|src/lib/domain/shipment-approval-route.ts
resolveMiscCaseCompletionGate|src/lib/domain/domestic-order-approval-rules.ts
DOMESTIC_ORDER_APPROVAL_ROUTE_SCOPE|src/lib/domain/domestic-order-approval-rules.ts
APPROVAL_REQUIRED|src/lib/db/mutations/domestic-orders.ts
resolveDomesticOrderModelLink|src/lib/domain/domestic-order-detail-link.ts
domesticOrderDetailHrefs|src/lib/domain/domestic-order-detail-tabs.ts
'
AS_MARKS_WANT=6
AUTH_MARKS='
DOMESTIC_ORDER_FINAL_SHIPMENT|src/lib/approvals/kinds.ts
'
AUTH_MARKS_WANT=1
# 🔵 서브모듈 쪽 표식 — git show 로 재는 길이 다르다(별도 저장소다).
CORE_MARK=domesticOrderId
CORE_MARK_FILE=src/schema/repair-case-approvals.ts

# 🔴 **구운 이미지 안에서 쓸 공통 표식.** 두 저장소 모두 기준판에 **0건**이고
#    지금 판에 있다(A/S src/ 30파일 · 포털 src/ 3파일 · 2026-11-07 실측).
#    🔵 runner 이미지는 소스가 없고 .next/standalone 만 있다 — 거기서도 이 글자가
#       **묶음 안에 박혀** 나온다. 그래서 앱 이미지도 「새 판인가」를 잴 수 있다.
BUILD_MARK=DOMESTIC_ORDER_FINAL_SHIPMENT

# 🔴 PO 쪽에서 **모르는 거절 코드** — 고치지 않고 세어서 알린다(머리말).
PO_GATEWAY=src/lib/server/as-gateway.ts
PO_MISSING_CODE=APPROVAL_REQUIRED
PO_MUT=src/lib/db/mutations/domestic-orders.ts

# ══ 🔴 양식 파일 — 이름|바이트|md5 ════════════════════════════════════
#   🔴 **이번 판에는 올릴 양식이 없다.** 열하나가 전부 52번이 적어 둔 값 그대로다
#      (2026-11-07 개발 PC 실측 — 바이트와 md5 가 글자 그대로 같았다).
#      이 절은 **「안 바뀌었다」를 확인하는 자리**이고 복사하는 절은 없다.
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
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-50"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

ASDIR="$DEV/RF_Service_System"
AUTHDIR="$DEV/dss-auth"
PODIR="$DEV/dss-po"
COREDIR="$ASDIR/vendor/dss-core"

printf '%s\n' "쉰째 배포 · 이미지 굽기   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  저장소 뿌리: $DEV"
printf '%s\n' "  tar 넷을 둘 자리: $OUT"
printf '%s\n' "  굽는 것: $AS_APP_TAG · $AS_TOOLS_TAG · $AUTH_APP_TAG · $AUTH_TOOLS_TAG  (저장소 둘 · 이미지 넷)"
printf '%s\n' "  올릴 HEAD: A/S 62a42be8 (기준 $AS_BASE 이후 커밋 10 · 파일 163)"
printf '%s\n' "             포털 f87bf7d  (기준 $AUTH_BASE 이후 커밋 1 · 파일 13)"
printf '%s\n' "             공용 스키마 vendor/dss-core ${AS_CORE_PIN_OLD:0:7} → ${AS_CORE_PIN:0:7}"
printf '%s\n' "  🔴 **포털을 구운 마지막은 39번이고 14판 전이다** — 값은 전부 다시 쟀다"
printf '%s\n' "  🔴 마이그레이션 **1건(0124)** — 묶음 as-migrations.tar.gz 를 **반드시 보낸다**"
printf '%s\n' "  🔵 PO 는 **안 굽는다** — HEAD 가 기준 SHA 그대로다(2절이 다시 잰다)"
printf '%s\n' "  🔵 양식은 **0장** — 열하나가 52번 값 그대로다(8절이 센다)"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 1. 도커가 도는가 ──────────────────────────────────────────────────
printf '\n== 1. 도커\n'
if docker version --format '{{.Server.Version}}' >/dev/null 2>&1; then
  ok "도커가 돈다 (서버 $(docker version --format '{{.Server.Version}}' 2>/dev/null))"
else
  bad "도커가 안 돈다 — Docker Desktop 을 켜세요"
fi

# ── 2. 저장소 둘 (이미지 넷) ─────────────────────────────────────────
printf '\n== 2. 저장소 둘 (이미지 넷)\n'
printf '%s\n' "🔴 미커밋·미푸시가 있으면 구운 이미지를 나중에 재현하지 못한다."
printf '%s\n' "🔴 **안 받은 것도 센다** — 낡은 코드를 굽고도 모른다."
printf '%s\n' "$SITES" | while IFS='|' read -r KEY REPO TAG BASE TGT WANTMIG WANTN PREVSZ PREVTAR STRICT; do
  [ -n "${KEY:-}" ] || continue
  case "$KEY" in (astools|authtools) continue ;; esac   # 🔵 같은 저장소다. 위에서 이미 쟀다.
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
      printf '%s\n' "         53-deploy.sh 꼬리말의 「볼 곳」과 5절의 파일 목록이다 — 사람이 보세요."
      git -C "$DIR" log --oneline "$BASE..HEAD" 2>/dev/null | head -12 | sed 's/^/      /'
    fi
    # 🔴 「0 이면 통과」가 아니다. 적어 둔 수와 **똑같아야** 한다.
    if [ "${m:-x}" = "$WANTMIG" ]; then
      printf '  ✓ %s drizzle/ 에서 달라진 파일 %s개 — 적어 둔 그대로\n' "$REPO" "$m"
    else
      printf '  ✗ %s drizzle/ 에서 달라진 파일 %s개 — **%s개를 기대했다**. 멈추고 알릴 것\n' "$REPO" "${m:-?}" "$WANTMIG"
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
  case "$KEY" in (astools|authtools) continue ;; esac   # 🔵 이미 셌다.
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
# 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다 — 저장소 **둘**을 봤는가.
if [ "$REPO_SEEN" = "2" ]; then ok "저장소 둘을 다 봤다 (표본이 비지 않았다)"
else bad "저장소를 ${REPO_SEEN}개만 봤다 — 둘을 기대했다. SITES 표가 깨졌다"; fi
if [ "$REPO_BAD" = "0" ]; then ok "저장소 둘이 깨끗하고 drizzle 변경 수가 적어 둔 그대로(A/S 3 · 포털 0)"
else bad "저장소 검사에서 어긋난 것 ${REPO_BAD}가지 — 위 ✗ 를 보세요"; doubt; fi

# 🔴 **안 굽는 여덟도 재 둔다** — 「이번 범위에 커밋이 없다」를 짐작으로 적지
#    않는다. HEAD 가 기준 SHA 와 글자 그대로 같아야 한다.
#    🔴 **52번은 아홉이었다.** 거기에 dss-auth 가 들어 있었는데 **이번엔 굽는다** —
#       그래서 이 목록에서 뺐고, 수도 9 에서 **8** 로 고쳤다.
#    🔵 ✗ 가 나도 **이 배포를 막지 않는다**(⚠️ 로만 센다) — 다음 판의 범위가
#       늘었다는 뜻이다.
printf '\n  ── 안 굽는 여덟 (HEAD 가 기준 SHA 그대로여야 한다)\n'
IDLE='
dss-inventory|e0d84e8
dss-board|7d4f390
dss-leave|f568fc0
njlee|a234878
dss-improvements|38fc0ef
dss-trouble|c3da85d
dss-approvals|8ab36fd
dss-po|9c1b2ef
'
IDLE_WANT=8
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
if [ "$IDLE_SEEN" = "$IDLE_WANT" ]; then ok "안 굽는 여덟을 다 봤다 (표본이 비지 않았다)"
else bad "안 굽는 저장소를 ${IDLE_SEEN}개만 봤다 — ${IDLE_WANT}을 기대했다. IDLE 표가 깨졌다"; fi
# 🔴 **dss-auth 가 이 목록에 남아 있지 않은가** — 52번에서 베껴 올 때 빠뜨리기 쉽다.
if printf '%s\n' "$IDLE" | grep -q '^dss-auth|'; then
  bad "🔴 IDLE 표에 dss-auth 가 남아 있다 — **이번 판은 포털을 굽는다.** 52번에서 그대로 베꼈다"
else
  ok "IDLE 표에 dss-auth 가 없다 (이번 판은 포털을 굽는다 — 52번에서 뺀 자리다)"
fi

# ── 3. 🔴 서브모듈 — 이번엔 A/S 의 dss-core 가 **움직인다** ───────────
printf '\n== 3. 서브모듈 (A/S 둘 — 🔴 dss-core 가 이번에 한 칸 움직인다)\n'
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
# 🔴 **정말 움직였는가** — 기준판의 포인터가 옛 값이어야 「이번에 움직였다」가 선다.
#    🔵 안 움직였는데 「움직였다」고 적어 두면, 다음 사람이 스키마 변경을 범위에
#       넣고도 못 찾는다.
WASPIN=$(git -C "$ASDIR" ls-tree "$AS_BASE" vendor/dss-core 2>/dev/null | awk '{print $3}')
say "기준판 $AS_BASE 의 vendor/dss-core = ${WASPIN:0:7}  (지금 ${AS_CORE_PIN:0:7})"
if [ "${WASPIN:-}" = "$AS_CORE_PIN_OLD" ]; then
  ok "서브모듈이 ${AS_CORE_PIN_OLD:0:7} → ${AS_CORE_PIN:0:7} 로 **이번에 움직였다** (적어 둔 그대로)"
elif [ -z "${WASPIN:-}" ]; then
  unk "기준판의 서브모듈 포인터" "git ls-tree 가 아무것도 안 돌려줬다 — 기준 SHA 를 보세요"
else
  note "기준판의 포인터가 ${WASPIN:0:7} 다 — ${AS_CORE_PIN_OLD:0:7} 을 적어 두었다. 사람이 보세요"
fi
# 🔴 **그 커밋이 고친 둘이 정말 그 둘인가** — 서브모듈은 별도 저장소라 바깥
#    저장소의 git diff 로는 파일 이름이 안 나온다. 안에서 따로 잰다.
if [ -d "$COREDIR/.git" ] || [ -f "$COREDIR/.git" ]; then
  CORE_N=$(git -C "$COREDIR" diff --name-only "$AS_CORE_PIN_OLD..$AS_CORE_PIN" 2>/dev/null | wc -l | tr -d ' ')
  say "vendor/dss-core 에서 달라진 파일 ${CORE_N:-못 쟀다}개 (적어 둔 수 $CORE_CHANGED_WANT)"
  git -C "$COREDIR" diff --name-only "$AS_CORE_PIN_OLD..$AS_CORE_PIN" 2>/dev/null | sed 's/^/      /'
  if [ "${CORE_N:-x}" = "$CORE_CHANGED_WANT" ]; then
    ok "공용 스키마에서 달라진 파일이 ${CORE_CHANGED_WANT}개다 — 적어 둔 그대로"
  else
    note "공용 스키마에서 달라진 파일이 ${CORE_N:-?}개다 — ${CORE_CHANGED_WANT}개를 적어 두었다. 사람이 보세요"
  fi
  CORE_SEEN=0; CORE_HIT=0
  for f in $CORE_CHANGED; do
    CORE_SEEN=$((CORE_SEEN+1))
    if [ -s "$COREDIR/$f" ]; then
      if git -C "$COREDIR" diff --name-only "$AS_CORE_PIN_OLD..$AS_CORE_PIN" -- "$f" 2>/dev/null | grep -q .; then
        CORE_HIT=$((CORE_HIT+1)); say "🔴 바뀌었다 · 도구 닫힘 안이다 — vendor/dss-core/$f"
      else
        say "🔵 안 바뀌었다 — vendor/dss-core/$f"
      fi
    else
      bad "🔴 vendor/dss-core/$f 가 없다 — 목록이 낡았다"
    fi
  done
  if [ "$CORE_SEEN" = "$CORE_CHANGED_WANT" ] && [ "$CORE_HIT" = "$CORE_CHANGED_WANT" ]; then
    ok "공용 스키마 둘이 **둘 다 이번에 바뀌었다** (A/S 도구가 이 스키마로 DB 를 읽는다)"
  else
    note "본 것 ${CORE_SEEN} · 바뀐 것 ${CORE_HIT} 다 — ${CORE_CHANGED_WANT}/${CORE_CHANGED_WANT} 을 기대했다. 사람이 보세요"
  fi
  # 🔵 글자 표식 — 이름만 맞고 속이 다를 수 있다.
  cw=$(git -C "$COREDIR" show "$AS_CORE_PIN_OLD:$CORE_MARK_FILE" 2>/dev/null | grep -c "$CORE_MARK" || true)
  cn=$(grep -c "$CORE_MARK" "$COREDIR/$CORE_MARK_FILE" 2>/dev/null || true)
  say "$CORE_MARK_FILE 의 $CORE_MARK — 기준 ${cw:-0} → 지금 ${cn:-0}  (기대 0 → 1 이상)"
  if [ "${cw:-1}" = "0" ] && [ "${cn:-0}" -ge 1 ] 2>/dev/null; then
    ok "공용 스키마에 $CORE_MARK 칸이 **이번에 생겼다** (0124 가 DB 에 더하는 그 칸이다)"
  else
    bad "🔴 $CORE_MARK 가 기준 ${cw:-?} → 지금 ${cn:-?} 다 — 0 → 1 이상을 기대했다"
    doubt
  fi
else
  unk "vendor/dss-core 안" "그 폴더가 git 저장소가 아니다 — git submodule update --init 을 먼저"
fi
# 🔵 PO 는 **이번에 안 굽는다.** 핀이 어긋나도 이 배포를 막을 일이 아니다 — ⚠️ 로만 센다.
for pair in "vendor/dss-core $PO_CORE_PIN" "vendor/dss-ui $UI_PIN"; do
  set -- $pair
  got=$(pin_of "$PODIR" "$1")
  if [ "${got:-}" = "$2" ]; then say "🔵 PO $1 포인터 ${2:0:7} — 적어 둔 그대로 (이번에 안 굽는다)"
  else note "PO $1 포인터가 ${got:0:7} 다 — ${2:0:7} 을 적어 두었다. **이번 배포는 안 막는다**(PO 를 안 굽는다)"; fi
done
say "🔵 A/S dss-core ${AS_CORE_PIN:0:7} · PO dss-core ${PO_CORE_PIN:0:7} — **서로 다른 것이 맞다.**"
say "   PO 쪽이 커밋 여덟만큼 뒤에 있고(조상 관계), PO 는 repair_case_approvals 를 아예 안 쓴다"
say "   (2026-11-07 실측: dss-po 소스에 repairCaseApprovals 가 0건). 🔴 여기서 맞추지 마세요."
# 🔴 빈 폴더가 아닌가 — 포인터는 맞는데 안이 비어 있는 경우가 실제로 있다.
check_not_empty() { # 1 서브모듈 폴더 2 사람이 부르는 이름
  if [ -s "$1/package.json" ]; then ok "$2 에 파일이 있다 (빈 폴더가 아니다)"
  else bad "$2 가 **빈 폴더**다 — git submodule update --init 을 먼저"; fi
}
check_not_empty "$COREDIR"            "A/S-core"
check_not_empty "$ASDIR/vendor/dss-ui" "A/S-ui"
# 🔴 **포털에는 서브모듈이 없는 것이 맞다**(2026-11-07 실측). 짐작으로 적지 않는다 —
#    생기면 굽기 전에 받아 두어야 하고, 빈 폴더면 빌드가 조용히 옛것을 굽는다.
if [ -e "$AUTHDIR/.gitmodules" ] || [ -d "$AUTHDIR/vendor" ]; then
  note "포털에 서브모듈이 **생겼다** — 지금까지 없던 것이다. 받아 두었는지 사람이 보세요"
  git -C "$AUTHDIR" submodule status 2>/dev/null | sed 's/^/      /'
else
  ok "포털에 서브모듈이 없다 (없는 것이 맞다 — @dss/ui 도 vendor/ 도 안 쓴다)"
fi

# ── 4. 🔴 drizzle/ — A/S 는 125 로 **늘었다** · 포털은 10 **그대로** ──
printf '\n== 4. drizzle/ — A/S %s (마이그레이션 1건) · 포털 %s (0건)\n' "$AS_SQL_WANT" "$AUTH_SQL_WANT"
AS_COUNTS=$(count_drizzle "$ASDIR"); AS_SQL=${AS_COUNTS%% *}; AS_JRN=${AS_COUNTS##* }
say "RF_Service_System/drizzle — .sql ${AS_SQL}장 · meta/_journal.json 의 idx ${AS_JRN}개"
if [ "${AS_SQL:-0}" = "$AS_SQL_WANT" ] && [ "${AS_JRN:-0}" = "$AS_SQL_WANT" ]; then
  ok "${AS_SQL_WANT}장이다 — 🔴 48번의 124 에서 **하나 늘었다**(0124). 묶음을 **반드시 보낸다**"
else
  bad "drizzle 이 .sql ${AS_SQL:-?} · idx ${AS_JRN:-?} 다 — **${AS_SQL_WANT} 여야 한다.** 멈추고 알릴 것"
  doubt
fi
# 🔵 두 상수가 이어지는 번호인가 — 한쪽만 고치면 아래 검사가 조용히 빗나간다.
#    🔴 10# 을 붙여 **10진수로 강제**한다. 안 붙이면 0124 가 8진수 84 로 읽힌다.
if [ "$(printf '%04d' "$((10#$AS_PREV_MIG + 1))")" = "$AS_NEW_MIG" ] \
   && [ "$(printf '%04d' "$((10#$AS_NEW_MIG + 1))")" = "$AS_NEXT_MIG" ]; then
  ok "번호 셋이 이어진다 ($AS_PREV_MIG → $AS_NEW_MIG → $AS_NEXT_MIG)"
else
  bad "🔴 $AS_PREV_MIG · $AS_NEW_MIG · $AS_NEXT_MIG 가 안 이어진다 — 한쪽만 고쳤다"
fi
# 🔴 **0124 가 정말 있는가.** 수만 세면 하나 빠지고 하나 생긴 경우를 못 본다.
MIGSQL="$ASDIR/drizzle/$AS_NEW_MIG_FILE"
if [ -s "$MIGSQL" ]; then
  ok "drizzle/$AS_NEW_MIG_FILE 이 있다"
else
  bad "🔴 drizzle/$AS_NEW_MIG_FILE 이 **없다** — 이 배포는 그 파일을 전제로 쓰였다"
  ls -1 "$ASDIR/drizzle/${AS_NEW_MIG}_"*.sql 2>/dev/null | sed 's/^/      /'
  doubt
fi
if [ -s "$ASDIR/drizzle/meta/${AS_NEW_MIG}_snapshot.json" ]; then
  ok "meta/${AS_NEW_MIG}_snapshot.json 이 있다 (목록에 없는 .sql 은 drizzle 이 아예 모른다)"
else
  bad "🔴 meta/${AS_NEW_MIG}_snapshot.json 이 없다 — 적용이 **0건으로 조용히 끝난다**"
fi
if ls -1 "$ASDIR/drizzle/${AS_NEXT_MIG}_"*.sql >/dev/null 2>&1; then
  bad "🔴 drizzle 에 $AS_NEXT_MIG 번이 **생겼다** — 이 배포는 1건을 전제로 쓰였다. 멈추고 알릴 것"
  doubt
else
  ok "$AS_NEXT_MIG 번이 없다 (마지막이 $AS_NEW_MIG — 이번 판은 1건이 맞다)"
fi
# 🔵 48번이 올린 셋도 그대로 있어야 한다 — 묶음을 통째로 갈아 끼우기 때문이다.
KEEPMIG_SEEN=0; KEEPMIG_OK=0
for t in 0121 0122 0123; do
  KEEPMIG_SEEN=$((KEEPMIG_SEEN+1))
  if ls -1 "$ASDIR/drizzle/${t}_"*.sql >/dev/null 2>&1 && [ -s "$ASDIR/drizzle/meta/${t}_snapshot.json" ]; then
    KEEPMIG_OK=$((KEEPMIG_OK+1))
  else
    bad "$t 의 .sql 또는 스냅샷이 없다 — 묶음이 온전하지 않게 된다"
  fi
done
if [ "$KEEPMIG_SEEN" = "3" ] && [ "$KEEPMIG_OK" = "3" ]; then
  ok "48번이 올린 셋(0121·0122·0123)이 .sql 과 스냅샷까지 그대로 있다"
else
  bad "본 것 ${KEEPMIG_SEEN} · 온전한 것 ${KEEPMIG_OK} 다 — 3/3 을 기대했다"
fi

# ── 4-ㄴ. 🔴 0124 안을 센다 — 지우는 문장 0 · 살펴볼 문장 2 ───────────
printf '\n  ── 0124 안의 문장 (앱의 migration-safety 와 **같은 잣대**)\n'
if [ -s "$MIGSQL" ]; then
  # 🔴 먼저 **잣대가 살아 있는지** 표본 둘로 본다 — 안 그러면 아래 0 이 공짜 통과다.
  PROBE_DROP=$(printf '%s\n' "DROP TABLE foo;" | grep -ciE "$DESTRUCTIVE_RE" || true)
  PROBE_OND=$(printf '%s\n' 'REFERENCES "b"("id") ON DELETE set null;' | grep -ciE "$DESTRUCTIVE_RE" || true)
  PROBE_DC=$(printf '%s\n' 'ALTER TABLE a DROP CONSTRAINT c;' | grep -ciE "$DESTRUCTIVE_RE" || true)
  PROBE_RISKY=$(printf '%s\n' 'ALTER TABLE a DROP CONSTRAINT c;' | grep -ciE "$RISKY_RE" || true)
  say "표본 — 가짜 DROP TABLE ${PROBE_DROP:-?}(기대 1) · ON DELETE set null ${PROBE_OND:-?}(기대 0) · DROP CONSTRAINT ${PROBE_DC:-?}(기대 0)"
  say "표본 — 살펴볼 잣대로 본 DROP CONSTRAINT ${PROBE_RISKY:-?}(기대 1)"
  if [ "${PROBE_DROP:-0}" = "1" ]; then ok "지우는 잣대가 살아 있다 (가짜 DROP 하나를 제대로 잡았다)"
  else bad "🔴 지우는 잣대가 죽었다 — 아래 「0건」이 공짜 통과다. 멈추세요"; fi
  if [ "${PROBE_OND:-1}" = "0" ]; then ok "ON DELETE set null 은 지우는 문장으로 **안 센다** (0124 가 가짜 ✗ 를 안 받는다)"
  else bad "🔴 ON DELETE 를 지우는 문장으로 센다 — **더하기만 하는 판이 ✗ 가 된다**"; fi
  if [ "${PROBE_DC:-1}" = "0" ]; then ok "DROP CONSTRAINT 도 지우는 문장으로 **안 센다** (앱의 잣대와 같다)"
  else bad "🔴 DROP CONSTRAINT 를 지우는 문장으로 센다 — 앱의 잣대와 다르다"; fi
  if [ "${PROBE_RISKY:-0}" = "1" ]; then ok "살펴볼 잣대가 살아 있다 (DROP CONSTRAINT 를 제대로 잡았다)"
  else bad "🔴 살펴볼 잣대가 죽었다 — 아래 2건이 공짜 통과다"; fi

  DN=$(grep -ciE "$DESTRUCTIVE_RE" "$MIGSQL" || true)
  RN=$(grep -ciE "$RISKY_RE" "$MIGSQL" || true)
  say "$AS_NEW_MIG — 지우는 문장 ${DN:-?}줄(기대 $MIG_DESTRUCT_WANT) · 살펴볼 문장 ${RN:-?}줄(기대 $MIG_RISKY_WANT)"
  if [ "${DN:-x}" = "$MIG_DESTRUCT_WANT" ]; then
    ok "$AS_NEW_MIG 에 지우는 문장이 ${MIG_DESTRUCT_WANT}줄이다 (DROP TABLE/COLUMN/SCHEMA · TRUNCATE · DELETE FROM 없음)"
  else
    bad "🔴 $AS_NEW_MIG 에 지우는 문장이 ${DN:-?}줄이다 — ${MIG_DESTRUCT_WANT}줄을 기대했다. **고치지 말고 먼저 알리세요**"
    grep -niE "$DESTRUCTIVE_RE" "$MIGSQL" | head -5 | sed 's/^/      /'
    doubt
  fi
  if [ "${RN:-x}" = "$MIG_RISKY_WANT" ]; then
    ok "$AS_NEW_MIG 에 살펴볼 문장이 ${MIG_RISKY_WANT}줄이다 — 🔵 **제약 삭제 둘이고, 같은 파일에서 넓혀 다시 세운다**"
    grep -niE "$RISKY_RE" "$MIGSQL" | cut -c1-110 | sed 's/^/      /'
  else
    bad "🔴 $AS_NEW_MIG 에 살펴볼 문장이 ${RN:-?}줄이다 — ${MIG_RISKY_WANT}줄을 기대했다"
    grep -niE "$RISKY_RE" "$MIGSQL" | cut -c1-110 | sed 's/^/      /'
    doubt
  fi
  # 🔴 **뗀 둘이 다시 서는가** — 「뗐다」만 세면 사라진 판과 구별되지 않는다.
  REDO=0
  for s in "$MIG_REDO1" "$MIG_REDO2"; do
    if grep -qF "$s" "$MIGSQL"; then REDO=$((REDO+1)); fi
  done
  if [ "$REDO" = "2" ]; then
    ok "뗀 제약 둘이 **같은 파일에서 다시 세워진다** (넓힌 CHECK 로 — 자료가 안 사라진다)"
  else
    bad "🔴 다시 세우는 ADD CONSTRAINT 가 ${REDO}/2 개다 — **제약이 사라진 채 끝나는 판이다.** 멈추고 알릴 것"
    doubt
  fi
  # 🔴 **그 파일이 맞는가** — 이름만 맞고 속이 다를 수 있다. 다섯을 글자로 본다.
  MK_SEEN=0; MK_OK=0
  for s in "$MIG_MARK_ENUM1" "$MIG_MARK_ENUM2" "$MIG_MARK_COL" "$MIG_MARK_UNIQ" "$MIG_MARK_IDX"; do
    MK_SEEN=$((MK_SEEN+1))
    if grep -qF "$s" "$MIGSQL"; then MK_OK=$((MK_OK+1)); else say "없다 — $s"; fi
  done
  say "0124 안의 표식 ${MK_OK}/${MK_SEEN} 개"
  if [ "$MK_SEEN" = "5" ] && [ "$MK_OK" = "5" ]; then
    ok "0124 가 enum 둘 · 칸 하나 · 유니크 하나 · 인덱스 하나를 더하는 그 파일이 맞다"
  else
    bad "🔴 0124 의 표식이 ${MK_OK}/5 개다 — **다른 파일이다.** 멈추고 알릴 것"
    doubt
  fi
  # 🔴 **enum 리터럴을 CHECK 에 쓰지 않았는가** — 썼으면 한 트랜잭션에서 죽는다.
  #    🔵 approval_type::text 로 적은 덕에 통과한다(머리말 ③).
  CASTN=$(grep -c 'approval_type::text' "$MIGSQL" || true)
  say "CHECK 이 approval_type::text 로 적힌 줄 ${CASTN:-?}개 (기대 4 — enum 리터럴이면 같은 트랜잭션에서 죽는다)"
  if [ "${CASTN:-0}" -ge 4 ] 2>/dev/null; then
    ok "CHECK 넷이 전부 ::text 비교다 — 같은 트랜잭션에서 새 enum 값을 **안 쓴다**"
  else
    bad "🔴 ::text 비교가 ${CASTN:-?}개다 — 넷을 기대했다. **적용이 그 자리에서 죽을 수 있다**"
    doubt
  fi
else
  unk "0124 안의 문장" "그 .sql 을 못 읽었다"
fi

# ── 4-ㄷ. 포털 drizzle 은 **그대로여야** 한다 ────────────────────────
printf '\n  ── 포털 drizzle (이번 판에 돌릴 마이그레이션이 없다)\n'
AU_COUNTS=$(count_drizzle "$AUTHDIR"); AU_SQL=${AU_COUNTS%% *}; AU_JRN=${AU_COUNTS##* }
say "dss-auth/drizzle — .sql ${AU_SQL}장 · idx ${AU_JRN}개 (기대 $AUTH_SQL_WANT · $AUTH_SQL_WANT)"
if [ "${AU_SQL:-0}" = "$AUTH_SQL_WANT" ] && [ "${AU_JRN:-0}" = "$AUTH_SQL_WANT" ]; then
  ok "포털이 $AUTH_SQL_WANT 그대로다 — 🔴 **53-deploy.sh 에 포털 DB 를 건드리는 단계가 없다**"
else
  bad "포털이 .sql ${AU_SQL:-?} · idx ${AU_JRN:-?} 다 — **$AUTH_SQL_WANT 그대로여야 한다.** 늘었다면 이 배포의 설계가 틀렸다"
  doubt
fi
# 🔴 「삼켜진 0」을 여기서 가른다 — PO 에 drizzle/ 이 없는 것이 맞다.
if [ -d "$PODIR/drizzle" ]; then
  bad "🔴 dss-po 에 drizzle/ 폴더가 **생겼다** — 2026-09-28 부터 없던 것이다. 스키마의 주인이 바뀌었는지 사람이 보세요"
  doubt
else
  ok "dss-po 에 drizzle/ 폴더가 없다 (없는 것이 맞다 — 스키마의 주인은 A/S 하나뿐이다)"
fi

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 담는 길 · 도구 판정 · 소스가 새 코드를 담고 있나 ────────────
# ══════════════════════════════════════════════════════════════════════
#  🔴 .dockerignore 나 Dockerfile 이 어긋나면 이미지는 멀쩡히 구워지고 **바뀐
#     코드만 조용히 빠진다.** 그래서 담는 길부터 센다.
printf '\n== 5. 담는 길 · 도구 판정 · 소스가 새 코드를 담고 있나\n'
# 🔴 기준 SHA 가 표와 이 절에 **두 벌로** 적혀 있다. 한쪽만 고치면 조용히 어긋난다.
row_f() { printf '%s\n' "$SITES" | tr -d ' ' | grep "^$1|" | head -1 | cut -d'|' -f"$2"; }
AS_ROW_BASE=$(row_f as 4)
AUTH_ROW_BASE=$(row_f auth 4)
if [ "${AS_ROW_BASE:-}" = "$AS_BASE" ]; then ok "A/S 기준 SHA 가 SITES 표와 이 절에서 같다 ($AS_BASE)"
else bad "A/S 기준 SHA 가 어긋난다 — 표는 ${AS_ROW_BASE:-못 읽음} · 이 절은 $AS_BASE"; fi
if [ "${AUTH_ROW_BASE:-}" = "$AUTH_BASE" ]; then ok "포털 기준 SHA 가 SITES 표와 이 절에서 같다 ($AUTH_BASE)"
else bad "포털 기준 SHA 가 어긋난다 — 표는 ${AUTH_ROW_BASE:-못 읽음} · 이 절은 $AUTH_BASE"; fi
# 🔴 PO 기준 SHA 는 SITES 에 없다(안 굽는다). IDLE 표의 PO 줄과 맞댄다.
PO_IDLE_BASE=$(printf '%s\n' "$IDLE" | tr -d ' ' | grep '^dss-po|' | head -1 | cut -d'|' -f2)
if [ "${PO_IDLE_BASE:-}" = "$PO_BASE" ]; then ok "PO 기준 SHA 가 IDLE 표와 이 절에서 같다 ($PO_BASE)"
else bad "PO 기준 SHA 가 어긋난다 — IDLE 표는 ${PO_IDLE_BASE:-못 읽음} · 이 절은 $PO_BASE"; fi
# 🔵 도구 줄이 정말 --target tools 인지. 여기가 '-' 면 runner 가 구워지고,
#    그 이미지는 **오류 없이** 쓸모가 없다.
for pair in "astools $AS_TOOLS_TAG" "authtools $AUTH_TOOLS_TAG"; do
  set -- $pair
  t=$(row_f "$1" 5); g=$(row_f "$1" 3)
  if [ "${t:-}" = "tools" ] && [ "${g:-}" = "$2" ]; then
    ok "SITES 표의 $1 줄이 $2 · --target tools 다"
  else
    bad "SITES 표의 $1 줄이 어긋난다 — 태그 ${g:-없음} · target ${t:-없음} (기대 $2 · tools)"
  fi
done

# ── ㄱ) 두 저장소의 Dockerfile 이 담는 길 ────────────────────────────
#   🔴 **집마다 담는 것이 다르다.** A/S 의 tools 는 drizzle/ 을 **안 담고**(볼륨),
#      포털의 tools 는 **담는다**(292KB 라 이미지 안에서 돈다). 39번이 그 차이를
#      적어 두었고 2026-11-07 에 두 Dockerfile 을 다시 읽어 확인했다.
check_copy() { # 1 Dockerfile 2 정규식 3 있어야 하나(yes/no) 4 사람이 읽을 말
  if grep -qE "$2" "$1" 2>/dev/null; then
    if [ "$3" = yes ]; then ok "$4"; else bad "🔴 $4"; fi
  else
    if [ "$3" = yes ]; then bad "🔴 $4"; else ok "$4"; fi
  fi
}
printf '\n  ── A/S Dockerfile\n'
if grep -q '^FROM .* AS tools' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "A/S 에 tools 스테이지가 있다 (--target tools 가 선다)"
else
  bad "A/S 에 tools 스테이지가 없다 — --target tools 가 실패한다"
fi
check_copy "$ASDIR/Dockerfile" '^COPY .*scripts \./scripts'   yes "A/S tools 가 scripts/ 를 담는다"
check_copy "$ASDIR/Dockerfile" '^COPY .*package\.json'        yes "A/S tools 가 package.json·tsconfig.json 을 담는다 (npm 명령이 들어가는 길)"
check_copy "$ASDIR/Dockerfile" '^COPY .*src \./src'           yes "A/S tools 가 src/ 를 담는다 (닫힘 안에서 바뀐 열 중 아홉이 여기다)"
check_copy "$ASDIR/Dockerfile" '^COPY .*vendor \./vendor'     yes "A/S tools 가 vendor/ 를 담는다 (🔴 이번에 움직인 공용 스키마가 들어가는 유일한 길)"
check_copy "$ASDIR/Dockerfile" '^COPY .*drizzle \./drizzle'   no  "A/S tools 는 drizzle/ 을 **안 담는다** (28MB — 볼륨으로 붙인다)"
printf '\n  ── 포털 Dockerfile\n'
if grep -q '^FROM .* AS tools' "$AUTHDIR/Dockerfile" 2>/dev/null; then
  ok "포털에 tools 스테이지가 있다 (--target tools 가 선다)"
else
  bad "포털에 tools 스테이지가 없다 — --target tools 가 실패한다"
fi
check_copy "$AUTHDIR/Dockerfile" '^COPY .*scripts \./scripts' yes "포털 tools 가 scripts/ 를 담는다 (39번이 연 비상구 둘이 사는 자리)"
check_copy "$AUTHDIR/Dockerfile" '^COPY .*package\.json'      yes "포털 tools 가 package.json 을 담는다 (npm run 으로 부르는 길)"
check_copy "$AUTHDIR/Dockerfile" '^COPY .*src \./src'         yes "포털 tools 가 src/ 를 담는다 (🔴 이번에 바뀐 넷이 들어가는 길)"
check_copy "$AUTHDIR/Dockerfile" '^COPY .*drizzle \./drizzle' yes "포털 tools 가 drizzle/ 을 담는다 (🔵 A/S 와 **반대다** — 이미지 안에서 돈다)"
# 🔴 두 집 다 tools 가 runner **앞**이어야 한다 — 마지막 스테이지가 docker build 의
#    기본 대상이다. 뒤에 두면 --target 없이 구운 이미지가 앱이 아니라 도구가 된다.
for pair in "A/S $ASDIR" "포털 $AUTHDIR"; do
  set -- $pair
  lt=$(grep -n '^FROM .* AS tools'  "$2/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
  lr=$(grep -n '^FROM .* AS runner' "$2/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
  if isnum "${lt:-}" && isnum "${lr:-}" && [ "$lt" -lt "$lr" ]; then
    ok "$1 Dockerfile 이 tools(${lt}줄) 를 runner(${lr}줄) **앞**에 둔다 (--target 없이 구우면 runner 가 나온다)"
  else
    bad "🔴 $1 Dockerfile 의 차례가 tools ${lt:-?} · runner ${lr:-?} 다 — **--target 없이 구운 것이 도구가 된다**"
    doubt
  fi
done

# ── ㄴ) .dockerignore — 두 집 다 ─────────────────────────────────────
check_dockerignore() { # 1 저장소 폴더 2 이름 3 drizzle 도 가야 하나(yes/no)
  local DIG
  DIG="$1/.dockerignore"
  if [ ! -s "$DIG" ]; then
    bad "$2 에 .dockerignore 가 없거나 비었다 — .env 와 .git 이 이미지로 따라 들어간다"
    return
  fi
  if grep -qE '^scripts/?$' "$DIG" 2>/dev/null; then
    bad "$2 의 .dockerignore 가 scripts/ 를 막는다 — 빈 폴더가 구워진다"
  else
    ok "$2 의 .dockerignore 가 scripts/ 를 막지 않는다"
  fi
  if grep -qE '^src/?$' "$DIG" 2>/dev/null; then
    bad "$2 의 .dockerignore 가 src/ 를 막는다 — 이번에 고친 코드가 통째로 빠진다"
  else
    ok "$2 의 .dockerignore 가 src/ 를 막지 않는다"
  fi
  if grep -qE '^\.next/?$' "$DIG" 2>/dev/null; then
    ok "$2 의 .dockerignore 가 .next 를 막는다 (개발 서버를 띄워 둔 채로 구워도 된다)"
  else
    bad "$2 의 .dockerignore 가 .next 를 안 막는다 — 호스트의 .next 가 빌드 문맥에 들어간다"
  fi
  if [ "$3" = yes ]; then
    if grep -qE '^drizzle/?$' "$DIG" 2>/dev/null; then
      bad "$2 의 .dockerignore 가 drizzle/ 을 막는다 — 빈 폴더가 구워진다"
    else
      ok "$2 의 .dockerignore 가 drizzle/ 을 막지 않는다"
    fi
  fi
}
printf '\n'
check_dockerignore "$ASDIR"   "A/S"  no
check_dockerignore "$AUTHDIR" "포털" yes
# 🔵 포털은 docs/ 를 막는다 — 바뀐 13 중 둘이 거기라 **이미지에 안 간다.**
#    🔴 짐작으로 적지 않는다. 막는지 재서 11 이라는 수의 근거로 쓴다.
if grep -qE '^docs/?$' "$AUTHDIR/.dockerignore" 2>/dev/null; then
  ok "포털의 .dockerignore 가 docs/ 를 막는다 (바뀐 13 중 둘이 이미지에 안 간다 → $AUTH_IMG_CHANGED_WANT)"
else
  note "포털의 .dockerignore 가 docs/ 를 안 막는다 — 바뀐 13 이 전부 이미지에 간다. 수만 달라진다"
fi

# ── ㄷ) 🔴 npm 명령 — **이번 판은 안 늘었다.** 「줄지 않았는가」를 센다 ─
printf '\n  ── npm 명령 (🔴 이번 판은 **안 늘었다** — 41번 잣대는 안 걸린다)\n'
npm_block() { # 1 저장소 2 기준SHA 3 이름 4 기대 was 5 기대 now 6 pkg diff 기대 7 지킬 명령들 8 그 수
  local DIR base label ww nn pl now was seen oknow okwas s
  DIR=$1; base=$2; label=$3
  pl=$(git -C "$DIR" diff "$base..HEAD" -- package.json 2>/dev/null | wc -l | tr -d ' ')
  say "$label package.json 의 diff ${pl:-못 쟀다}줄 (적어 둔 값 $6)"
  if [ "${pl:-x}" = "$6" ]; then
    ok "$label package.json 이 $6 줄 바뀌었다 — 🔵 **명령이 안 늘었다**(41번 잣대는 이번 판에 안 걸린다)"
  else
    note "$label package.json 이 ${pl}줄 바뀌었다 — $6 줄을 적어 두었다. 아래 diff 를 사람이 보세요"
    git -C "$DIR" diff "$base..HEAD" -- package.json 2>/dev/null | head -24 | sed 's/^/      /'
  fi
  nn=$(count_scripts < "$DIR/package.json" 2>/dev/null | tr -d ' ')
  ww=$(git -C "$DIR" show "$base:package.json" 2>/dev/null | count_scripts | tr -d ' ')
  say "$label scripts 항목 — 기준 ${ww:-?} → 지금 ${nn:-?} (적어 둔 값 $4 → $5)"
  if [ "${ww:-x}" = "$4" ] && [ "${nn:-x}" = "$5" ]; then
    ok "$label 명령 수가 적어 둔 그대로다 ($4 → $5)"
  elif isnum "${nn:-}" && isnum "${ww:-}" && [ "${nn:-0}" -lt "${ww:-0}" ]; then
    bad "🔴 $label 명령이 ${ww} 에서 ${nn} 로 **줄었다** — 사라진 명령을 그날 부르면 Missing script 다"
    doubt
  else
    note "$label 명령 수가 기준 ${ww:-?} → 지금 ${nn:-?} 다 — $4 → $5 를 적어 두었다. 사람이 보세요"
  fi
  seen=0; oknow=0; okwas=0
  for s in $7; do
    seen=$((seen+1))
    now=$(grep -c "\"$s\"" "$DIR/package.json" 2>/dev/null || true)
    was=$(git -C "$DIR" show "$base:package.json" 2>/dev/null | grep -c "\"$s\"" || true)
    printf '      %-34s 기준 %s → 지금 %s\n' "$s" "${was:-0}" "${now:-0}"
    if [ "${now:-0}" -ge 1 ] 2>/dev/null; then oknow=$((oknow+1)); fi
    if [ "${was:-0}" -ge 1 ] 2>/dev/null; then okwas=$((okwas+1)); fi
  done
  if [ "$seen" = "$8" ]; then ok "$label 지킬 명령 $8 개를 다 봤다 (표본이 비지 않았다)"
  else bad "$label 명령을 ${seen}개만 봤다 — $8 개를 기대했다. 목록이 깨졌다"; fi
  if [ "$oknow" = "$8" ]; then ok "$label 지킬 명령 $8 개가 **지금 판에 다 있다** (부르는 날 Missing script 가 안 난다)"
  else bad "🔴 $label 지금 판에 있는 명령이 ${oknow}/$8 개다 — **사라진 것이 있다.** 그 명령은 올려도 못 부른다"; doubt; fi
  if [ "$okwas" = "$8" ]; then ok "$label 지킬 명령 $8 개가 기준판에도 있었다 (이번에 생긴 것이 아니다)"
  else note "$label 기준판에 있던 명령이 ${okwas}/$8 개다 — $8 개를 기대했다. 사람이 보세요"; fi
}
npm_block "$ASDIR"   "$AS_BASE"   "A/S "  "$AS_NPM_WAS"   "$AS_NPM_NOW"   "$AS_PKG_LINES_WANT"   "$AS_KEEP_NPM"   "$AS_KEEP_NPM_WANT"
printf '\n'
npm_block "$AUTHDIR" "$AUTH_BASE" "포털" "$AUTH_NPM_WAS" "$AUTH_NPM_NOW" "$AUTH_PKG_LINES_WANT" "$AUTH_KEEP_NPM" "$AUTH_KEEP_NPM_WANT"
# 🔵 포털의 비상구 둘이 **컨테이너에서 사는 꼴**인가 — 39번이 연 그 자리다.
#    🔴 옛 --env-file= 이면 .env.local 이 없는 컨테이너에서 **그 자리에 죽는다.**
for k in admin:promote admin:emergency; do
  if grep -q "\"$k\": \"node --env-file-if-exists=" "$AUTHDIR/package.json" 2>/dev/null; then
    ok "포털 package.json 의 $k 가 --env-file-if-exists 다 (컨테이너에서 산다)"
  else
    bad "🔴 포털 package.json 의 $k 가 --env-file-if-exists 가 아니다 — **컨테이너에서 그 자리에 죽는다**"
    doubt
  fi
done

# ── ㄹ) 🔴 도구 닫힘 안에서 바뀐 파일 — 집마다 따로 센다 ─────────────
closure_block() { # 1 저장소 2 기준 3 이름 4 목록 5 기대 수
  local DIR base label seen hit f
  DIR=$1; base=$2; label=$3
  seen=0; hit=0
  printf '\n  ── %s 도구 닫힘 안에서 바뀐 파일 (기대 %s개)\n' "$label" "$5"
  for f in $4; do
    seen=$((seen+1))
    if [ ! -s "$DIR/$f" ]; then
      bad "🔴 $label $f 가 저장소에 없다 — **닫힘 목록이 낡았다.** 닫힘을 다시 재세요"
      continue
    fi
    if git -C "$DIR" diff --name-only "$base..HEAD" -- "$f" 2>/dev/null | grep -q .; then
      hit=$((hit+1)); say "🔴 바뀌었다 · 도구가 부른다 — $f"
    else
      say "🔵 안 바뀌었다 — $f"
    fi
  done
  say "$label 닫힘 목록 ${seen}개를 봤고, 그중 바뀐 것 ${hit}개 (적어 둔 수 $5)"
  if [ "$seen" = "$5" ]; then ok "$label 닫힘 목록 $5 개를 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
  else bad "$label 닫힘 목록을 ${seen}개만 봤다 — $5 개를 기대했다. 목록이 깨졌다"; fi
  if [ "${hit:-0}" -ge 1 ] 2>/dev/null; then
    ok "$label 도구가 부르는 파일이 ${hit}개 바뀌었다 — **부르니까 굽는다**"
  else
    bad "🔴 $label 도구가 부르는 길에서 바뀐 파일이 0개다 — $5 개를 적어 두었다. **머리말의 실측이 낡았다.** 멈추고 알릴 것"
    doubt
  fi
  if [ "${hit:-x}" != "$5" ]; then
    note "$label 바뀐 것이 ${hit:-?}개다 — 적어 둔 것은 $5 개다. 커밋이 더 쌓였는지 사람이 보세요"
  fi
}
closure_block "$ASDIR"   "$AS_BASE"   "A/S "  "$AS_TOOLS_CALLED"   "$AS_TOOLS_CALLED_WANT"
closure_block "$AUTHDIR" "$AUTH_BASE" "포털" "$AUTH_TOOLS_CALLED" "$AUTH_TOOLS_CALLED_WANT"
# 🔵 **닫힘 안에 이번에 생긴 파일 넷** — 48번에는 하나도 없던 신호다. 이것이
#    있으면 이미지 안에서 「그 파일이 있나」만 봐도 **새 판이 담겼다**가 선다.
printf '\n  ── A/S 닫힘 안에 **이번에 생긴** 파일 넷 (기준판에는 없어야 한다)\n'
BORN_SEEN=0; BORN_OK=0
for f in $AS_BORN; do
  BORN_SEEN=$((BORN_SEEN+1))
  if git -C "$ASDIR" cat-file -e "$AS_BASE:$f" 2>/dev/null; then
    note "$f 가 **기준판에도 있다** — 이번에 생긴 파일로 적어 두었다. 사람이 보세요"
  else
    BORN_OK=$((BORN_OK+1)); say "🔵 기준판에 없던 파일 — $f"
  fi
done
if [ "$BORN_SEEN" = "$AS_BORN_WANT" ] && [ "$BORN_OK" = "$AS_BORN_WANT" ]; then
  ok "넷 다 기준판에 **없던 파일**이다 (이미지 안에서 존재만 봐도 새 판이다)"
else
  note "본 것 ${BORN_SEEN} · 기준판에 없던 것 ${BORN_OK} 다 — ${AS_BORN_WANT}/${AS_BORN_WANT} 을 기대했다. 사람이 보세요"
fi

# ── ㅁ) 🔴 **「담기는 것」으로도 센다** (39번에 넓혀 둔 잣대) ──────────
printf '\n  ── 담기는 것으로 세기\n'
AS_TOOLS_PATHS="scripts/ src/ package.json drizzle.config.ts tsconfig.json vendor/"
AS_TOOLS_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $AS_TOOLS_PATHS 2>/dev/null | wc -l | tr -d ' ')
AS_ALL_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
say "A/S  tools 가 담는 것 중 달라진 파일 ${AS_TOOLS_CHANGED:-못 쟀다}개 (적어 둔 수 $AS_TOOLS_CHANGED_WANT)"
say "A/S  저장소 전체에서 달라진 파일 ${AS_ALL_CHANGED:-못 쟀다}개 (적어 둔 수 $AS_ALL_CHANGED_WANT)"
if isnum "${AS_TOOLS_CHANGED:-}" && [ "${AS_TOOLS_CHANGED:-0}" -ge 1 ]; then
  ok "A/S 도구를 구울 둘째 까닭이 있다 — 달라진 파일 ${AS_TOOLS_CHANGED}개"
else
  bad "A/S 달라진 파일이 ${AS_TOOLS_CHANGED:-못 쟀다}개다 — 전제가 깨졌으니 멈추고 알릴 것"
  doubt
fi
if [ "${AS_TOOLS_CHANGED:-x}" = "$AS_TOOLS_CHANGED_WANT" ] && [ "${AS_ALL_CHANGED:-x}" = "$AS_ALL_CHANGED_WANT" ]; then
  ok "A/S 바깥이 $((AS_ALL_CHANGED_WANT - AS_TOOLS_CHANGED_WANT))개다 — 적어 둔 그대로 (문서 둘 + drizzle 셋)"
else
  note "A/S 바깥이 $((${AS_ALL_CHANGED:-0} - ${AS_TOOLS_CHANGED:-0}))개다 — 다섯을 적어 두었다. 굽는 판정은 안 흔들린다"
fi
printf '%s\n' "      ── A/S tools 바깥에서 바뀐 것"
git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" 2>/dev/null \
  | grep -vE '^(scripts/|src/|package\.json$|drizzle\.config\.ts$|tsconfig\.json$|vendor/)' | head -10 | sed 's/^/      /'
# 🔵 포털 — 담기는 것은 src/ · scripts/ · drizzle/ · 설정 셋. docs/ 는 막힌다.
AUTH_IMG_PATHS="src/ scripts/ drizzle/ package.json drizzle.config.ts tsconfig.json"
AUTH_IMG_CHANGED=$(git -C "$AUTHDIR" diff --name-only "$AUTH_BASE..HEAD" -- $AUTH_IMG_PATHS 2>/dev/null | wc -l | tr -d ' ')
AUTH_ALL_CHANGED=$(git -C "$AUTHDIR" diff --name-only "$AUTH_BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
say "포털 이미지에 가는 것 중 달라진 파일 ${AUTH_IMG_CHANGED:-못 쟀다}개 (적어 둔 수 $AUTH_IMG_CHANGED_WANT)"
say "포털 저장소 전체에서 달라진 파일 ${AUTH_ALL_CHANGED:-못 쟀다}개 (적어 둔 수 $AUTH_ALL_CHANGED_WANT)"
if isnum "${AUTH_IMG_CHANGED:-}" && [ "${AUTH_IMG_CHANGED:-0}" -ge 1 ]; then
  ok "포털 도구를 구울 둘째 까닭이 있다 — 달라진 파일 ${AUTH_IMG_CHANGED}개"
else
  bad "포털 달라진 파일이 ${AUTH_IMG_CHANGED:-못 쟀다}개다 — 전제가 깨졌으니 멈추고 알릴 것"
  doubt
fi
if [ "${AUTH_IMG_CHANGED:-x}" = "$AUTH_IMG_CHANGED_WANT" ] && [ "${AUTH_ALL_CHANGED:-x}" = "$AUTH_ALL_CHANGED_WANT" ]; then
  ok "포털 바깥이 $((AUTH_ALL_CHANGED_WANT - AUTH_IMG_CHANGED_WANT))개다 — 적어 둔 그대로 (docs/ 둘)"
else
  note "포털 바깥이 $((${AUTH_ALL_CHANGED:-0} - ${AUTH_IMG_CHANGED:-0}))개다 — 둘을 적어 두었다. 굽는 판정은 안 흔들린다"
fi
printf '%s\n' "      ── 포털에서 바뀐 것 (전부)"
git -C "$AUTHDIR" diff --name-only "$AUTH_BASE..HEAD" 2>/dev/null | head -16 | sed 's/^/      /'

# ── ㅂ) 🔴 PO 쪽에서 달라진 파일 — **0 이어야 한다** ─────────────────
PO_CHANGED=$(git -C "$PODIR" diff --name-only "$PO_BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
say "PO 에서 달라진 파일 ${PO_CHANGED:-못 쟀다}개 (적어 둔 수 $PO_CHANGED_WANT — 안 굽는다)"
if [ "${PO_CHANGED:-x}" = "$PO_CHANGED_WANT" ]; then
  ok "PO 에서 달라진 파일이 0개다 — **안 굽는 것이 맞다**"
else
  bad "🔴 PO 에서 달라진 파일이 ${PO_CHANGED:-못 쟀다}개다 — 0개를 기대했다. **PO 도 구워야 할 수 있다.** 멈추고 알릴 것"
  git -C "$PODIR" diff --name-only "$PO_BASE..HEAD" 2>/dev/null | head -20 | sed 's/^/      /'
  doubt
fi

# ── ㅅ) 🔴 **이번 판인가를 글자로 가른다** ───────────────────────────
#   🔴 「파일이 바뀌었다」와 「그 안에 새 코드가 있다」는 다른 말이다.
mark_block() { # 1 저장소 2 기준 3 이름 4 표 5 기대 수
  local DIR base label seen okn row s f was now
  DIR=$1; base=$2; label=$3
  seen=0; okn=0
  printf '\n  ── %s 이번 판의 표식 (기준판에 0 · 지금 판에 1 이상)\n' "$label"
  for row in $(printf '%s\n' "$4" | tr -d ' ' | grep -v '^$'); do
    s=${row%%|*}; f=${row#*|}
    seen=$((seen+1))
    was=$(git -C "$DIR" show "$base:$f" 2>/dev/null | grep -c "$s" || true)
    now=$(grep -c "$s" "$DIR/$f" 2>/dev/null || true)
    printf '      %-36s %-52s 기준 %s → 지금 %s\n' "$s" "$f" "${was:-0}" "${now:-0}"
    if [ "${was:-1}" = "0" ] && [ "${now:-0}" -ge 1 ] 2>/dev/null; then okn=$((okn+1)); fi
  done
  if [ "$seen" = "$5" ] && [ "$okn" = "$5" ]; then
    ok "$label 표식 $5 개가 전부 **이번에 생겼다** (옛 판이 아니다)"
  else
    bad "🔴 $label 표식이 ${okn}/${seen} 개다 — $5/$5 를 기대했다. 목록이 낡았거나 범위가 틀렸다"
    doubt
  fi
}
mark_block "$ASDIR"   "$AS_BASE"   "A/S "  "$AS_MARKS"   "$AS_MARKS_WANT"
mark_block "$AUTHDIR" "$AUTH_BASE" "포털" "$AUTH_MARKS" "$AUTH_MARKS_WANT"
# 🔴 구운 이미지 안에서 쓸 **공통 표식**이 두 저장소 모두에서 기준판에 0 인가.
#    🔵 이 값이 0 이 아니면 아래 「새 판이 담겼다」 검사가 통째로 공짜 통과가 된다.
ASMW=$(git -C "$ASDIR"   grep -l "$BUILD_MARK" "$AS_BASE"   -- src/ 2>/dev/null | wc -l | tr -d ' ')
ASMN=$(git -C "$ASDIR"   grep -l "$BUILD_MARK" HEAD         -- src/ 2>/dev/null | wc -l | tr -d ' ')
AUMW=$(git -C "$AUTHDIR" grep -l "$BUILD_MARK" "$AUTH_BASE" -- src/ 2>/dev/null | wc -l | tr -d ' ')
AUMN=$(git -C "$AUTHDIR" grep -l "$BUILD_MARK" HEAD         -- src/ 2>/dev/null | wc -l | tr -d ' ')
say "$BUILD_MARK 가 든 src/ 파일 — A/S 기준 ${ASMW:-?} → 지금 ${ASMN:-?} · 포털 기준 ${AUMW:-?} → 지금 ${AUMN:-?}"
if [ "${ASMW:-1}" = "0" ] && [ "${ASMN:-0}" -ge 1 ] 2>/dev/null \
   && [ "${AUMW:-1}" = "0" ] && [ "${AUMN:-0}" -ge 1 ] 2>/dev/null; then
  ok "공통 표식 $BUILD_MARK 이 **두 집 모두 이번에 생겼다** — 구운 앱·도구 넷을 이 한 글자로 가를 수 있다"
else
  bad "🔴 공통 표식이 A/S ${ASMW:-?}→${ASMN:-?} · 포털 ${AUMW:-?}→${AUMN:-?} 다 — 0→1 이상을 기대했다"
  doubt
fi

# ── ㅇ) 🔴 **알고도 안 고친 것** — PO 가 새 거절 코드를 모른다 ───────
#   🔴 고치지 않는다(PO 를 안 굽고, 고치려면 PO 코드 변경이 필요하다).
#      **세어서 알리는 것**이 이 절의 일이다. ⚠️ 라 배포를 막지 않는다.
printf '\n  ── 🔴 PO 가 A/S 의 새 거절 코드를 아는가 (이번 판의 이음새 · 거꾸로 방향)\n'
if [ -s "$PODIR/$PO_GATEWAY" ]; then
  PCODE=$(grep -c "$PO_MISSING_CODE" "$PODIR/$PO_GATEWAY" || true)
  ASCODE=$(grep -c "$PO_MISSING_CODE" "$ASDIR/$PO_MUT" || true)
  say "A/S $PO_MUT 의 $PO_MISSING_CODE ${ASCODE:-0}번 (이번에 생겼다)"
  say "PO  $PO_GATEWAY 의 $PO_MISSING_CODE ${PCODE:-0}번 (기대 0 — **아직 모른다**)"
  if [ "${ASCODE:-0}" -ge 1 ] 2>/dev/null && [ "${PCODE:-1}" = "0" ]; then
    note "🔴 **PO 는 $PO_MISSING_CODE 를 모른다.** PO 에서 기타건을 [완료 처리] 하면 A/S 가"
    say "   적어 보낸 안내 문장이 **화면에 안 뜨고** 「모르는 응답」으로 떨어집니다."
    say "   🔵 자료는 안 깨집니다 — A/S 는 한 글자도 안 쓴 채 거절하고, PO 도"
    say "      「완료되었습니다」라고 말하지 않습니다(「바뀌었는지 알 수 없다」로 끝납니다)."
    say "   🔴 **이 배포는 그것을 안 고칩니다**(PO 를 안 굽습니다). 다음 PO 판에서"
    say "      AS_COMPLETION_REJECT_CODES 에 그 코드를 더하면 문장이 뜹니다."
  elif [ "${PCODE:-0}" -ge 1 ] 2>/dev/null; then
    ok "PO 가 $PO_MISSING_CODE 를 안다 — 🔵 그 사이에 PO 가 고쳐졌다. 위 ⚠️ 는 이제 거짓이다"
  else
    note "A/S 쪽 $PO_MISSING_CODE 가 ${ASCODE:-0}번이다 — 1 이상을 기대했다. 범위를 사람이 보세요"
  fi
else
  unk "PO 의 as-gateway" "$PODIR/$PO_GATEWAY 를 못 읽었다"
fi
# 🔵 PO 가 수리 건 표에 **쓴다** — 안 굽어도 잰다(52번의 그 줄 그대로).
PO_UPD=$(grep -c 'update(repairCases)' "$PODIR/$PO_MUT" 2>/dev/null || true)
say "PO $PO_MUT 의 update(repairCases) ${PO_UPD:-0}번 (기대 1 이상)"
if [ "${PO_UPD:-0}" -ge 1 ] 2>/dev/null; then
  ok "PO 가 repair_cases 에 **쓴다** — 🔴 53-deploy.sh --check 가 NAS 에서 그 권한을 값으로 묻는다"
else
  bad "🔴 PO 가 repair_cases 를 안 쓴다 — 49번이 올린 기능이 사라졌다. 멈추고 알릴 것"
  doubt
fi
# 🔵 PO 가 repair_case_approvals 를 **안 쓰는 것이 맞다** — 0124 가 그 표를 고치는데
#    PO 의 dss-core 가 여덟 커밋 뒤라, 만약 쓰고 있으면 핀을 맞춰야 하는 판이 된다.
PO_APPR=$(grep -rc 'repairCaseApprovals' "$PODIR/src" 2>/dev/null | grep -v ':0$' | wc -l | tr -d ' ')
say "PO 소스에서 repairCaseApprovals 를 쓰는 파일 ${PO_APPR:-0}개 (기대 0)"
if [ "${PO_APPR:-1}" = "0" ]; then
  ok "PO 는 repair_case_approvals 를 **안 쓴다** — 0124 가 그 표를 고쳐도 PO 는 영향이 없다"
else
  note "PO 가 repair_case_approvals 를 ${PO_APPR}개 파일에서 쓴다 — 0 을 기대했다. **PO 의 dss-core 핀이 여덟 뒤다.** 사람이 보세요"
fi

# ── 6. 태그가 이미 있나 ───────────────────────────────────────────────
printf '\n== 6. 새 태그가 이미 있나\n'
printf '%s\n' "🔵 있으면 **덮어쓴다** — 같은 커밋이면 같은 것이 나오므로 해롭지 않다."
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  rest=${row#*|}; rest=${rest#*|}; TAG=${rest%%|*}
  if docker image inspect "$TAG" >/dev/null 2>&1; then note "$TAG — 이미 있다 (덮어쓴다)"
  else ok "$TAG — 아직 없다"; fi
done
# 🔵 **되돌릴 판이 개발 PC 에 남아 있는가** — NAS 쪽은 53-deploy.sh 가 따로 센다.
#    🔴 **이번 판이 되돌릴 상대는 넷이다.** 52번은 둘이었다.
for t in "$AS_OLD_TAG" "$AUTH_OLD_TAG" "$AS_TOOLS_OLD_TAG" "$AUTH_TOOLS_OLD_TAG"; do
  if docker image inspect "$t" >/dev/null 2>&1; then say "🔵 옛 판 $t 가 개발 PC 에 있다"
  else say "🔵 옛 판 $t 가 개발 PC 에 없다 — NAS 쪽에 있으면 되돌리기는 된다(거기서 센다)"; fi
done
say "🔵 PO 는 dss-po:0.9 그대로 둔다 — 이번에 안 굽고 안 갈아 끼운다."

# ── 7. tar 넷을 둘 자리 ──────────────────────────────────────────────
printf '\n== 7. tar 넷을 둘 자리\n'
if [ "$MODE" = "--go" ]; then
  mkdir -p "$OUT" 2>/dev/null
fi
if [ -d "$OUT" ]; then ok "$OUT 가 있다"
elif [ "$MODE" = "--check" ]; then note "$OUT 가 아직 없다 (--go 가 만든다)"
else bad "$OUT 를 못 만들었다"; fi
# 🔵 tar 넷이면 690MB 쯤이고 묶음이 2.4MB 다. 두 배를 여유로 본다.
FREEKB=$(df -Pk "$(dirname "$OUT")" 2>/dev/null | awk 'NR==2 {print $4}')
if isnum "${FREEKB:-}"; then
  say "남은 자리 $((FREEKB / 1024))MB (tar 넷이 약 690MB · 묶음이 약 2.4MB 다)"
  if [ "$FREEKB" -ge 2000000 ]; then ok "자리가 넉넉하다"
  else bad "자리가 모자란다 — 2GB 이상을 권한다 (이번 판은 tar 가 **넷**이다)"; fi
else
  unk "남은 자리" "df 가 수를 안 돌려줬다"
fi

# ══════════════════════════════════════════════════════════════════════
# ── 8. 🔴 양식 파일 — **이번 판에는 올릴 것이 없다. 그래도 잰다** ─────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **경로를 찍지 않는다.** 이름 · 바이트 · md5 · 수정 시각만 찍는다.
#   🔴 **md5 가 적어 둔 것과 다르면 ✗ 가 아니라 ⚠️ 다** — 사용자가 양식을 고쳤다는
#      뜻이고, 그러면 **올릴 것이 생긴다.** 굽기를 막을 일은 아니다.
#   🔴 **파일이 아예 없으면 ✗ 다** — 운영이 못 읽는 양식을 그대로 두는 셈이다.
printf '\n== 8. 양식 파일 — 열하나가 52번 값 그대로인가 (경로는 안 찍는다)\n'
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
# 🔴 양식 이름에는 **공백과 한글**이 둘 다 있다. 그래서 while/IFS 로 한 줄씩 읽는다
#    — for 고리에 날것으로 넣으면 공백에서 쪼개진다.
#    🔵 while 이 파이프라인 안이면 셈이 안 넘어오므로 **여기 문자열**로 먹인다.
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
  # 🔴 to_unix() 를 이미 거쳤으므로 빗금으로 끊으면 **파일 이름만** 남는다(함정 ⑥).
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
  ok "양식 $TPL_COUNT_WANT 개가 **전부 52번이 적어 둔 md5 그대로**다 — 🔵 **올릴 양식이 0장이다**"
else
  note "양식 ${TPL_DIFF}개가 적어 둔 것과 다르다 — 위를 보세요. **굽기는 막지 않는다**"
fi
# 🔵 그리고 **이번 범위에 .xlsx 변경이 0줄인가** — 저장소 쪽에서도 따로 본다.
XLSX=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" 2>/dev/null | grep -ci '\.xlsx$' || true)
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
printf '\n%s\n' "════════ 굽는다 (넷) ════════"
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
  #    scripts/ 도 package.json 도 없어 오류 없이 쓸모없는 이미지가 된다
  #    (두 Dockerfile 모두 tools 를 runner **앞에** 둔다 — 5절-ㄱ 이 그것을 쟀다).
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

  # ── 🔴 크기 견주기 ① — **지난 판 tar 와** (🔴 엄함이 집마다 다르다) ─
  p=$(pct_diff "$sz" "$PREVSZ")
  if [ -n "${p:-}" ]; then
    printf '    지난 판 %s %s바이트 → 이번 %s바이트 (차이 %s%%)\n' "$PREVTAR" "$PREVSZ" "$sz" "$p"
    if [ "$p" -le 25 ]; then
      printf '  ✓ 지난 판 tar 와 크기가 비슷하다 (차이 %s%% · 25%% 이내)\n' "$p"
    elif [ "$STRICT" = "loose" ] && [ "$p" -le 60 ]; then
      # 🔴 포털의 기준값은 **14판 전(39번)** 것이다. 그 사이에 떠 있는 베이스 태그
      #    (node:22-bookworm-slim)가 바뀌었을 수 있다 — 여기서 ✗ 를 내면 거의
      #    확실히 **가짜 ✗** 다. 「스테이지를 잘못 구웠다」는 아래 이미지 안 검사가 잡는다.
      printf '  ⚠️ 지난 판 tar 와 %s%% 다르다 — 🔵 **포털의 기준값은 14판 전(39번) 것**이라\n' "$p"
      printf '%s\n' "     이만큼 벌어질 수 있습니다. 25~60%% 는 사람이 보라는 뜻이고 **막지 않습니다.**"
      printf '%s\n' "     🔴 「다른 스테이지를 구웠다」는 크기가 아니라 **이미지 안**이 잡습니다(아래)."
    else
      printf '  ✗ 지난 판 tar 와 크기가 %s%% 다르다 — %s 에서는 그만큼이면 멈춘다\n' "$p" "$STRICT"
      printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 라이브러리가 늘거나 베이스 이미지가"
      printf '%s\n' "         바뀌면 정상적으로도 이만큼 뜁니다. 까닭을 알면 SITES 표의 여덟째 칸을"
      printf '%s\n' "         고쳐 적으면 됩니다. 모르겠으면 **멈추고 알리세요.**"
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
  #   🔴 갈래가 넷이라 **갈래마다 다른 것을 잰다.** 한 잣대로 재면 가짜 ✗ 가 난다:
  #      앱(runner) 둘 → server.js 가 있고 **.next 묶음 안에 새 글자**가 있나
  #      도구(tools) 둘 → package.json 이 있고 **소스와 명령**이 새 판인가
  IMGFAIL=0
  case "$KEY" in
    as|auth)
      # ① runner 가 맞는가 — tools 에는 /app/server.js 가 없다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/server.js && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '    /app/server.js: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ runner 스테이지가 맞다 (node server.js 를 안다)\n'
      else printf '  ✗ /app/server.js 가 없다 — **runner 가 아닌 것을 구웠다.** 올리지 마세요\n'; IMGFAIL=1; fi
      # ② 🔴 **묶음 안에 이번 판의 글자가 있는가.** runner 에는 소스가 없고
      #    .next/standalone 만 있다 — 그래도 서버 묶음에 그 글자가 박혀 나온다.
      #    🔵 기준판에는 두 저장소 모두 **0건**이었다(5절-ㅅ 이 그것을 쟀다).
      #    🔴 이것이 없으면 「옛 판을 구웠다」이고, 그때 증상은 **아무 일도 안
      #       일어나는 것**이다 — 배포는 성공하고 기능만 없다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "grep -rlF $BUILD_MARK /app/.next/server 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '    /app/.next/server 안에서 %s 가 든 파일: %s개 (기대 1 이상)\n' "$BUILD_MARK" "${v:-?}"
      if isnum "${v:-}" && [ "${v:-0}" -ge 1 ]; then
        printf '  ✓ 묶음에 이번 판의 글자가 있다 (옛 판이 아니다)\n'
      else
        printf '  ✗ 묶음에 %s 가 없다 — **옛 판을 구웠다.** 캐시를 의심하세요\n' "$BUILD_MARK"; IMGFAIL=1
      fi
      # ③ 🔵 public/ 이 담겼는가 — 없으면 아이콘·정적 파일이 404 가 된다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/public && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '    /app/public: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ public/ 이 담겼다\n'
      else printf '  ✗ public/ 이 없다 — 정적 파일이 404 가 된다\n'; IMGFAIL=1; fi
      ;;
    astools)
      printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TAG"
      # ① runner 가 아니라 tools 인가
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '      /app/package.json: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ tools 스테이지가 맞다\n'
      else printf '  ✗ /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다\n'; IMGFAIL=1; fi
      # ② 🔴 운영에서 불릴 npm 명령이 이미지 안 package.json 에 있는가(41번의 자리).
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync procedures:export procedures:import db:preflight db:migrate; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "7" ]; then printf '  ✓ npm 명령 일곱이 이미지 안에 있다 (Missing script 가 안 난다)\n'
      else printf '  ✗ 명령이 %s/7 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다**\n' "${got:-0}"; IMGFAIL=1; fi
      # ③ 🔴 닫힘 안에서 바뀐 열이 담겼는가. 🔵 그중 넷은 기준판에 **없던 파일**이다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/export-procedure-bundle.ts /app/src/lib/auth/permission-areas.ts /app/src/lib/auth/permission-baseline.ts /app/src/lib/domain/domestic-order-approval-rules.ts /app/src/lib/domain/domestic-order-detail-link.ts /app/src/lib/domain/domestic-order-detail-tabs.ts /app/src/lib/domain/domestic-order-display.ts /app/src/lib/domain/notifications.ts /app/src/lib/domain/shipment-approval-route.ts /app/src/lib/validation/quote-input.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "10" ]; then printf '  ✓ 닫힘에서 바뀐 열이 다 들어갔다 (그중 넷은 이번에 생긴 파일이다)\n'
      else printf '  ✗ 열 중 %s개만 들어갔다 — src/ 나 scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
      # ④ 🔴 **공용 스키마가 새 판인가** — vendor/ 가 담기는 유일한 길을 값으로 본다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'f=/app/vendor/dss-core/src/schema/repair-case-approvals.ts; if [ -f "$f" ]; then echo "miss=0"; echo "n=$(grep -c domesticOrderId "$f")"; else echo "miss=1"; fi' 2>/dev/null | tr -d ' \r')
      printf '%s\n' "$v" | sed 's/^/      /'
      cm=$(printf '%s\n' "$v" | sed -n 's/^miss=//p'); cn=$(printf '%s\n' "$v" | sed -n 's/^n=//p')
      if [ "${cm:-1}" != "0" ]; then
        printf '  ✗ 이미지에 vendor/dss-core 의 그 스키마가 **없다** — Cannot find module 이 난다\n'; IMGFAIL=1
      elif [ "${cn:-0}" -ge 1 ] 2>/dev/null; then
        printf '  ✓ 공용 스키마가 **새 판이다** (domesticOrderId 가 %s번 — 0124 가 더하는 그 칸)\n' "$cn"
      else
        printf '  ✗ 공용 스키마에 domesticOrderId 가 0번이다 — **옛 서브모듈이 담겼다.** 올리지 마세요\n'; IMGFAIL=1
      fi
      # ⑤ 🔴 소스가 이번 판인가 — 글자로 센다. 전부 기준판에 **0번**이다(5절-ㅅ).
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for pair in "DOMESTIC_ORDER_FINAL_SHIPMENT /app/src/lib/domain/shipment-approval-route.ts" "resolveMiscCaseCompletionGate /app/src/lib/domain/domestic-order-approval-rules.ts" "APPROVAL_REQUIRED /app/src/lib/db/mutations/domestic-orders.ts" "resolveDomesticOrderModelLink /app/src/lib/domain/domestic-order-detail-link.ts" "domesticOrderDetailHrefs /app/src/lib/domain/domestic-order-detail-tabs.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "5" ]; then printf '  ✓ 이번 판의 이름 다섯이 이미지 안에 있다 (옛 판이 아니다)\n'
      else printf '  ✗ 이번 판의 이름이 %s/5 개다 — **옛 판이 담겼다.** 캐시를 의심하세요\n' "${got:-0}"; IMGFAIL=1; fi
      # ⑥ 🔵 지난 판들이 올린 도구가 **아직 있는가** — 한 번 빼면 다시 넣는 사람이 없다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts /app/scripts/import-procedure-bundle.ts /app/scripts/lib/procedure-template-bundle.ts /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts /app/scripts/lib/kyosan-used-parts-backfill-plan.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "9" ]; then printf '  ✓ 48~52번이 올린 도구 아홉이 다 들어갔다\n'
      else printf '  ✗ 도구 파일이 %s/9 개다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
      # ⑦ 🔴 **갈래 셋을 갈래마다 다르게 센다**(52번의 그 절 그대로).
      #    🔴 한 잣대로 재면 import-procedure-bundle 이 **가짜 ✗** 가 된다 —
      #       그 파일은 운영에서 도는 것이 목적이라 자물쇠를 **일부러 안 단다.**
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/import-technical-task-procedures.ts /app/scripts/link-technical-task-next-procedures.ts; do if grep -q checkDevelopmentWriteTarget "$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "2" ]; then printf '  ✓ 갈래 ㄱ — 엑셀 읽개 둘이 개발 DB 자물쇠를 부른다 (NAS 에서 부르면 막힌다)\n'
      else printf '  ✗ 갈래 ㄱ — 자물쇠를 부르는 것이 %s/2 개다. **운영 DB 에 쓸 수 있는 판이다.** 올리지 마세요\n' "${got:-0}"; IMGFAIL=1; fi
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'f=/app/scripts/import-procedure-bundle.ts; for pair in "guard:checkDevelopmentWriteTarget" "apply:process.env.APPLY" "tx:db.transaction" "target:formatDatabaseTarget"; do k=${pair%%:*}; s=${pair#*:}; n=$(grep -cF "$s" "$f" 2>/dev/null); echo "$k=$n"; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      pg=$(printf '%s\n' "$v" | sed -n 's/^guard=//p'); pa=$(printf '%s\n' "$v" | sed -n 's/^apply=//p')
      pt=$(printf '%s\n' "$v" | sed -n 's/^tx=//p');    pd=$(printf '%s\n' "$v" | sed -n 's/^target=//p')
      if [ "${pg:-x}" = "0" ] && [ "${pa:-0}" -ge 1 ] 2>/dev/null && [ "${pt:-0}" -ge 1 ] 2>/dev/null && [ "${pd:-0}" -ge 1 ] 2>/dev/null; then
        printf '  ✓ 갈래 ㄴ — import-procedure-bundle 가 운영용 모양 그대로다 (자물쇠 0 · APPLY · 트랜잭션 · 대상 DB 찍기)\n'
      else
        printf '  ✗ 갈래 ㄴ — 자물쇠 %s(기대 0) · APPLY %s · 트랜잭션 %s · 대상DB %s (셋은 1 이상)\n' "${pg:-?}" "${pa:-?}" "${pt:-?}" "${pd:-?}"; IMGFAIL=1
      fi
      # 🔴 「grep -c」 는 0 일 때 종료 코드 1 을 낸다. 「|| echo ?」 를 달면 **하필 바라던
      #    0 에서만** 터진다(2026-11-06 실제로 났다). 파일 없음과 0번을 **갈래로** 가른다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'f=/app/scripts/export-procedure-bundle.ts; if [ -f "$f" ]; then echo "miss=0"; echo "w=$(grep -cE "\.insert\(|\.update\(|\.delete\(" "$f")"; echo "t=$(grep -c "transaction" "$f")"; else echo "miss=1"; fi' 2>/dev/null | tr -d ' \r')
      printf '%s\n' "$v" | sed 's/^/      /'
      rm_=$(printf '%s\n' "$v" | sed -n 's/^miss=//p'); rw=$(printf '%s\n' "$v" | sed -n 's/^w=//p'); rt=$(printf '%s\n' "$v" | sed -n 's/^t=//p')
      if [ "${rm_:-1}" != "0" ]; then
        printf '  ✗ 갈래 ㄷ — export-procedure-bundle.ts 가 **이미지 안에 없다**\n'; IMGFAIL=1
      elif [ "${rw:-x}" = "0" ] && [ "${rt:-x}" = "0" ]; then
        printf '  ✓ 갈래 ㄷ — export-procedure-bundle 는 읽기만 한다 (쓰는 문장 0 · 트랜잭션 0)\n'
      else
        printf '  ✗ 갈래 ㄷ — 쓰는 문장 %s번 · 트랜잭션 %s번이다. **읽기 전용이 아니다**\n' "${rw:-?}" "${rt:-?}"; IMGFAIL=1
      fi
      # ⑧ 🔵 그 도구가 **--prefix 를 아는가** — 541287aa 가 더한 것이고 꼬리말이 쓴다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'f=/app/scripts/export-procedure-bundle.ts; n=$(grep -cF -- "--prefix" "$f" 2>/dev/null); echo "p=$n"' 2>/dev/null | tr -d ' \r')
      pn=$(printf '%s\n' "$v" | sed -n 's/^p=//p')
      printf '      export-procedure-bundle 의 --prefix: %s번 (기대 1 이상)\n' "${pn:-?}"
      if [ "${pn:-0}" -ge 1 ] 2>/dev/null; then printf '  ✓ --prefix 를 아는 판이 담겼다 (꼬리말의 명령과 이미지가 맞는다)\n'
      else printf '  ✗ --prefix 가 0번이다 — **541287aa 이전 판이 담겼다.** 꼬리말의 명령이 안 먹는다\n'; IMGFAIL=1; fi
      # ⑨ tsx 가 있는가 — 이 도구는 tsx 로만 돈다(운영 이미지에는 없는 devDependency 다).
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '      /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ tsx 가 있다\n'
      else printf '  ✗ tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
      # ⑩ 🔴 **값을 받아 본다** — npm 으로 실제로 부른다. DATABASE_URL 을 안 준다.
      #    세 파일이 맨 위에서 connection.ts 를 정적 import 하고 그것이 동기적으로
      #    던진다 — **DB 에는 한 글자도 안 닿는다.**
      #    🔴 'node …' 가 아니라 **'npm run …'** 이어야 Missing script 가 드러난다.
      for cmdname in check:due-date-inverted procedures:import; do
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
      # ⑪ 🔵 이미지 안의 drizzle/ 은 **비어 있어야** 한다 — 볼륨으로 붙는 자리다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '      /app/drizzle 안 .sql: %s개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)\n' "${v:-?}"
      if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ drizzle/ 이 비어 있다 (이미지에 안 굽는다)\n'
      else printf '  ✗ drizzle/ 에 .sql 이 들었다 — 이미지가 28MB 를 더 메고 다닌다\n'; IMGFAIL=1; fi
      # ⑫ 🔵 **양식은 이미지에 안 들어간다** — 들어갔으면 도장과 계좌번호가 구워진 것이다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "ls /templates 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '      /templates 안 파일: %s개 (기대 0 — 양식은 볼륨으로 붙는다)\n' "${v:-?}"
      if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ 양식이 이미지에 안 들어갔다\n'
      else printf '  ✗ 이미지 안에 /templates 가 %s개 있다 — 도장·계좌번호가 구워졌다. 사람이 보세요\n' "${v:-?}"; IMGFAIL=1; fi
      ;;
    authtools)
      printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TAG"
      # ① runner 가 아니라 tools 인가
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '      /app/package.json: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ tools 스테이지가 맞다\n'
      else printf '  ✗ /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다\n'; IMGFAIL=1; fi
      # ② 🔴 **포털 drizzle 은 이미지 안에서 돈다** — A/S 와 반대다. 비면 다음 판이
      #    조용히 0건이 된다.
      # 🔴 **상자를 둘 띄운다.** 한 줄에 몰아넣으면 sh -c 안에서 따옴표가 세 겹이
      #    되어 조용히 빈 값이 나온다. 🔵 idx 는 _journal.json 에서 entry 당 한 번만
      #    나온다(2026-11-07 실측: 따옴표를 붙여 세도 10 으로 같았다).
      ds=$(docker run --rm --entrypoint sh "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      dj=$(docker run --rm --entrypoint sh "$TAG" -c "grep -o idx /app/drizzle/meta/_journal.json 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '      /app/drizzle — .sql %s장 · idx %s개 (기대 %s · %s)\n' "${ds:-?}" "${dj:-?}" "$AUTH_SQL_WANT" "$AUTH_SQL_WANT"
      if [ "${ds:-0}" = "$AUTH_SQL_WANT" ] && [ "${dj:-0}" = "$AUTH_SQL_WANT" ]; then
        printf '  ✓ 포털 drizzle 이 개발 PC 와 같다 (%s · %s)\n' "$AUTH_SQL_WANT" "$AUTH_SQL_WANT"
      else
        printf '  ✗ 이미지 안이 .sql %s · idx %s 다 — 둘 다 %s 여야 한다\n' "${ds:-?}" "${dj:-?}" "$AUTH_SQL_WANT"; IMGFAIL=1
      fi
      # ③ 🔴 39번이 연 **비상구 둘** — 이번 판의 까닭은 아니지만 **빼지 않는다.**
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/promote-admin.ts /app/scripts/create-emergency-admin.ts /app/scripts/purge-expired.ts /app/scripts/send-approval-mails.ts /app/scripts/check-notifications.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "5" ]; then printf '  ✓ 비상구 둘 · 야간 정리 하나 · 메일 하나 · 진단 하나가 다 들어갔다\n'
      else printf '  ✗ 다섯 중 %s개만 들어갔다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
      # ④ 🔴 **닫힘 안에서 바뀐 넷이 담겼는가.**
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/src/lib/approvals/kinds.ts /app/src/lib/approvals/plan.ts /app/src/lib/approvals/sources.ts /app/src/lib/notifications/merge.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "4" ]; then printf '  ✓ 닫힘에서 바뀐 넷이 다 들어갔다\n'
      else printf '  ✗ 넷 중 %s개만 들어갔다 — src/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
      # ⑤ 🔴 **이번 판인가 — 글자로 센다.** 기준판에 0번이었다(5절-ㅅ).
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'f=/app/src/lib/approvals/kinds.ts; n=$(grep -c DOMESTIC_ORDER_FINAL_SHIPMENT "$f" 2>/dev/null); echo "k=$n"' 2>/dev/null | tr -d ' \r')
      kn=$(printf '%s\n' "$v" | sed -n 's/^k=//p')
      printf '      kinds.ts 의 %s: %s번 (기대 1 이상 · 기준판은 0)\n' "$BUILD_MARK" "${kn:-?}"
      if [ "${kn:-0}" -ge 1 ] 2>/dev/null; then
        printf '  ✓ 포털 도구가 **새 갈래를 아는 판**이다 (결재 메일 표에 기타건이 올라가 있다)\n'
      else
        printf '  ✗ kinds.ts 에 %s 가 0번이다 — **옛 판이 담겼다.** 올리지 마세요\n' "$BUILD_MARK"; IMGFAIL=1
      fi
      # ⑥ 🔵 「종 배지는 보이는 줄 수다」가 담겼는가 — merge.ts 의 그 한 줄이다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'f=/app/src/lib/notifications/merge.ts; n=$(grep -cF "count: items.length" "$f" 2>/dev/null); echo "m=$n"' 2>/dev/null | tr -d ' \r')
      mn=$(printf '%s\n' "$v" | sed -n 's/^m=//p')
      printf '      merge.ts 의 줄 수 세기: %s번 (기대 1 이상 · 기준판은 0)\n' "${mn:-?}"
      if [ "${mn:-0}" -ge 1 ] 2>/dev/null; then printf '  ✓ 배지를 줄 수로 세는 판이 담겼다\n'
      else printf '  ✗ merge.ts 가 옛 판이다 — check:notify 가 옛 잣대로 센다\n'; IMGFAIL=1; fi
      # ⑦ tsx 가 있는가
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '      /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ tsx 가 있다\n'
      else printf '  ✗ tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
      # ⑧ 🔴 **이미지 안 node 가 --env-file-if-exists 를 아는가** — 39번이 재던 그 줄.
      #    모르면 비상구 둘이 **쓸 일이 생긴 날** 그 자리에서 죽는다.
      v=$(docker run --rm --entrypoint node "$TAG" --env-file-if-exists=/nonexistent.env -e "console.log('FLAG_OK')" 2>&1 | tr -d '\r' | tail -1)
      printf '      node --env-file-if-exists=<없는 파일> → %s (기대 FLAG_OK)\n' "${v:-없음}"
      if [ "${v:-}" = "FLAG_OK" ]; then printf '  ✓ 이미지 안 node 가 그 깃발을 안다 (비상구 둘이 산다)\n'
      else printf '  ✗ FLAG_OK 가 아니다 — node 가 그 깃발을 모른다. 비상구가 또 죽는다\n'; IMGFAIL=1; fi
      # ⑨ 🔴 **값을 받아 본다** — 비상구를 npm 으로 부른다. DB 에는 안 닿는다.
      #    🔵 인자를 안 주면 쓰는 법만 찍고 끝나는 도구다(39번 기록).
      v=$(docker run --rm --entrypoint sh "$TAG" -c "cd /app && npm run admin:promote 2>&1 | head -40" 2>&1 | tr -d '\r')
      if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
        printf '  ✗ npm run admin:promote — **Missing script**. 비상구를 올려도 못 부른다\n'
        printf '%s\n' "$v" | head -20 | sed 's/^/      /'; IMGFAIL=1
      elif printf '%s' "$v" | grep -qE 'Cannot find module|ERR_MODULE_NOT_FOUND'; then
        printf '  ✗ npm run admin:promote 가 모듈을 못 찾는다 — 담긴 것이 모자란다\n'
        printf '%s\n' "$v" | head -20 | sed 's/^/      /'; IMGFAIL=1
      else
        printf '  ✓ npm run admin:promote 가 Missing script 없이 섰다 (아래 끝 6줄)\n'
        printf '%s\n' "$v" | tail -6 | sed 's/^/      /'
      fi
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

# ══ 🔴 다섯째 산출물 — A/S 마이그레이션 묶음 ══════════════════════════
#  🔴 **이번 판에는 보험이 아니라 필수다.** 운영 볼륨이 124 이고 저장소가 125 다 —
#     이 묶음을 안 보내면 이미지 넷을 다 올려도 **적용이 0건으로 조용히 끝나고**,
#     그 다음에 뜬 dss-as:4.6 이 **없는 칸을 읽다 죽는다.**
#     🔵 52번은 0건이라 「안 보내도 된다」였다. **그 글을 베껴 오면 안 된다.**
#  🔴 git archive 로 뽑지 않는다 — 서브모듈이 빈 폴더로 나온다.
#  🔴 묶은 뒤 **안을 센다.** 「파일이 생겼다」와 「담겼다」는 다르다.
printf '\n%s\n' "════════ A/S 마이그레이션 묶음 (🔴 이번 판에는 **반드시 보낸다**) ════════"
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

SQLPAT='^drizzle/[0-9][0-9][0-9][0-9]_.*[.]sql'
INSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "$SQLPAT" || true)
INJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
printf '    묶음 안 .sql %s장 · _journal.json 의 idx %s개 (기대 %s · %s)\n' "${INSQL:-?}" "${INJRN:-?}" "$AS_SQL_WANT" "$AS_SQL_WANT"
MFAIL=0
if [ "${INSQL:-0}" != "$AS_SQL_WANT" ]; then
  printf '  ✗ 묶음 안 .sql 이 %s장이다 — %s장이어야 한다\n' "${INSQL:-?}" "$AS_SQL_WANT"; MFAIL=1
fi
if [ "${INJRN:-0}" != "$AS_SQL_WANT" ]; then
  printf '  ✗ 묶음 안 idx 가 %s개다 — %s개여야 한다. 🔴 목록에 없는 .sql 은 **안 돈다**\n' "${INJRN:-?}" "$AS_SQL_WANT"; MFAIL=1
fi
# 🔴 **0124 가 묶음 안에 있어야 한다** — 이번 판의 핵심이다. 52번과 반대다.
if tar -tzf "$MIGTAR" 2>/dev/null | grep -qE "^drizzle/${AS_NEW_MIG}_.*[.]sql"; then
  printf '  ✓ 묶음에 %s 번이 **있다** (이번 판이 적용할 그 한 건)\n' "$AS_NEW_MIG"
else
  printf '  ✗ 묶음에 %s 번이 **없다** — 보내도 적용이 0건으로 끝난다\n' "$AS_NEW_MIG"; MFAIL=1
fi
if tar -tzf "$MIGTAR" 2>/dev/null | grep -qE "^drizzle/meta/${AS_NEW_MIG}_snapshot[.]json"; then
  printf '  ✓ 묶음에 meta/%s_snapshot.json 이 있다\n' "$AS_NEW_MIG"
else
  printf '  ✗ 묶음에 meta/%s_snapshot.json 이 없다\n' "$AS_NEW_MIG"; MFAIL=1
fi
# 🔴 **0125 는 없어야 한다** — 있으면 이 배포의 전제(1건)가 깨진 것이다.
if tar -tzf "$MIGTAR" 2>/dev/null | grep -qE "^drizzle/${AS_NEXT_MIG}_.*[.]sql"; then
  printf '  ✗ 묶음에 %s 번이 있다 — 이 배포는 **1건**을 전제로 쓰였다\n' "$AS_NEXT_MIG"; MFAIL=1
else
  printf '  ✓ 묶음에 %s 번이 없다 (마지막이 %s — 1건이 맞다)\n' "$AS_NEXT_MIG" "$AS_NEW_MIG"
fi
# 🔵 48번이 올린 셋도 온전해야 한다 — 폴더를 통째로 갈아 끼우기 때문이다.
for n in 0121 0122 0123; do
  hitsql=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${n}_.*[.]sql" || true)
  hitsnap=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/meta/${n}_snapshot[.]json" || true)
  if [ "${hitsql:-0}" = "1" ] && [ "${hitsnap:-0}" = "1" ]; then
    printf '  ✓ %s — .sql 과 스냅샷이 둘 다 묶음 안에 있다 (48번이 올린 셋)\n' "$n"
  else
    printf '  ✗ %s 가 온전하지 않다 — .sql %s · 스냅샷 %s\n' "$n" "${hitsql:-?}" "${hitsnap:-?}"; MFAIL=1
  fi
done

# 🔴 **묶음 안의 0124 를 다시 센다** — 저장소에서 이미 쟀지만, 「묶인 것」과
#    「저장소에 있는 것」은 다른 물건이다(겉이 아니라 결과).
MIGNAME=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -E "^drizzle/${AS_NEW_MIG}_.*[.]sql" | head -1)
if [ -n "${MIGNAME:-}" ]; then
  dn=$(tar -xzOf "$MIGTAR" "$MIGNAME" 2>/dev/null | grep -ciE "$DESTRUCTIVE_RE" || true)
  rn=$(tar -xzOf "$MIGTAR" "$MIGNAME" 2>/dev/null | grep -ciE "$RISKY_RE" || true)
  printf '    묶음 안 %s — 지우는 문장 %s줄(기대 %s) · 살펴볼 문장 %s줄(기대 %s)\n' \
    "$AS_NEW_MIG" "${dn:-?}" "$MIG_DESTRUCT_WANT" "${rn:-?}" "$MIG_RISKY_WANT"
  if [ "${dn:-x}" = "$MIG_DESTRUCT_WANT" ]; then
    printf '  ✓ 묶음 안 %s 에 지우는 문장이 %s줄이다 (더하기만 한다 — ON DELETE 는 안 센다)\n' "$AS_NEW_MIG" "$MIG_DESTRUCT_WANT"
  else
    printf '  ✗ 묶음 안 %s 에 지우는 문장이 %s줄이다 — %s줄을 기대했다\n' "$AS_NEW_MIG" "${dn:-?}" "$MIG_DESTRUCT_WANT"; MFAIL=1
  fi
  if [ "${rn:-x}" = "$MIG_RISKY_WANT" ]; then
    printf '  ✓ 묶음 안 %s 에 살펴볼 문장이 %s줄이다 (제약 삭제 둘 — 같은 파일에서 다시 선다)\n' "$AS_NEW_MIG" "$MIG_RISKY_WANT"
  else
    printf '  ✗ 묶음 안 %s 에 살펴볼 문장이 %s줄이다 — %s줄을 기대했다\n' "$AS_NEW_MIG" "${rn:-?}" "$MIG_RISKY_WANT"; MFAIL=1
  fi
else
  printf '  ✗ 묶음에서 %s 의 .sql 이름을 못 찾았다\n' "$AS_NEW_MIG"; MFAIL=1
fi
# 🔵 표본 둘 — 잣대가 살아 있고, ON DELETE 는 **안 걸려야** 한다.
PROBE1=$(printf '%s\n' "DROP TABLE foo;" | grep -ciE "$DESTRUCTIVE_RE" || true)
PROBE2=$(printf '%s\n' 'REFERENCES "b"("id") ON DELETE set null;' | grep -ciE "$DESTRUCTIVE_RE" || true)
if [ "${PROBE1:-0}" = "1" ]; then printf '  ✓ 잣대가 살아 있다 (가짜 DROP 하나를 제대로 잡았다)\n'
else printf '  ✗ 잣대가 죽었다 — 위 「0줄」이 공짜 통과다. 멈추세요\n'; MFAIL=1; fi
if [ "${PROBE2:-1}" = "0" ]; then printf '  ✓ ON DELETE set null 은 지우는 문장으로 안 센다 (0124 가 가짜 ✗ 를 안 받는다)\n'
else printf '  ✗ ON DELETE 를 지우는 문장으로 센다 — 0124 가 가짜 ✗ 를 받는다\n'; MFAIL=1; fi

if [ "$MFAIL" = "0" ]; then
  printf '  ✓ 묶음 안이 저장소와 같다 (.sql %s · idx %s · %s 있음 · %s 없음)\n' "$AS_SQL_WANT" "$AS_SQL_WANT" "$AS_NEW_MIG" "$AS_NEXT_MIG"
else
  printf '%s\n' "🔴 묶음이 온전하지 않다. 올리지 마세요."; exit 1
fi
MIGLINE="as-migrations.tar.gz|${msz}|${mm5}|-"

# ══ 🔴 53-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 53-deploy.sh 의 TARS 는 **이름만 적힌 채로** 올라간다. 지문 칸이 비어 있으면
#     --check 에서 ? 로 세고 **--preload·--go 에서는 ✗ 다** — 아래 **네 줄**로
#     그 네 줄을 통째로 갈아 끼운다.
printf '\n%s\n' "════════ 53-deploy.sh 의 TARS 에 붙여 넣을 것 (네 줄) ════════"
printf '%s' "$TARTABLE"
echo "  🔴 위 네 줄로 TARS 의 네 줄을 통째로 갈아 끼운다."
echo "$MIGLINE"
echo "  🔴 마지막 줄(묶음)은 53-deploy.sh 의 MIGTAR_SIZE · MIGTAR_MD5 에 넣는다."
echo "  🔴 **묶음은 이번 판에 반드시 보낸다** — 볼륨이 124 이고 저장소가 125 다."
printf '\n%s\n' "✅ 넷 다 구웠다. tar · 묶음 · 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'

printf '\n%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **올리는 차례 — 이번 판은 tar 가 넷 · 묶음 하나다**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  🔵 양식은 **한 장도 안 올립니다** — 열하나가 52번 값 그대로입니다(8절)."
printf '%s\n' "  🔴 마이그레이션은 **1건(0124)** 입니다 — 묶음을 **반드시** 보내세요."
printf '%s\n' ""
printf '%s\n' "  🔴 PowerShell 경로는 **슬래시**로 적습니다. 역슬래시는 bash·scp 가 먹습니다."
printf '%s\n' ""
printf '%s\n' "  ① (개발 PC · PowerShell) **스크립트부터 올린다**"
printf '%s\n' "       cd \"C:/Users/희만/Desktop/Development/dss-deploy/nas/setup\""
printf '%s\n' "       scp -O 53-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "       Get-FileHash -Algorithm MD5 53-deploy.sh"
printf '%s\n' "     🔵 NAS 에서 md5sum 을 쳐 **눈으로 맞댑니다**(DSM 터미널이 긴 것을 잘라 먹습니다)."
printf '%s\n' ""
printf '%s\n' "  ② (NAS) 지금 상태를 잰다 — 아직 아무것도 안 바뀐다"
printf '%s\n' "       sudo -i"
printf '%s\n' "       bash /volume1/dss/setup/53-deploy.sh            ← --check"
printf '%s\n' "       bash /volume1/dss/setup/53-deploy.sh --count    ← 올리기 전 수"
printf '%s\n' "     🔵 2절의 마이그레이션 수가 **124** 로 나와야 합니다 (아직 적용 전)."
printf '%s\n' ""
printf '%s\n' "  ③ (개발 PC · PowerShell) **tar 넷과 묶음을 보낸다 — 한 줄에 하나씩**"
printf '%s\n' "       cd \"$(printf '%s' "$OUT" | sed 's|^/c/|C:/|')\""
printf '%s\n' "       scp -O dss-as-4.6.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "       scp -O dss-as-tools-13.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "       scp -O dss-auth-2.1.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "       scp -O dss-auth-tools-4.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "       scp -O as-migrations.tar.gz dss-nas:/volume1/dss/setup/incoming/"
printf '%s\n' "     🔴 **-O 를 빼지 마세요** — DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' "     🔴 **as-migrations.tar.gz 를 빠뜨리면 적용이 0건으로 조용히 끝납니다.**"
printf '%s\n' ""
printf '%s\n' "  ④ (NAS) **들여놓고 → 적용하고 → 갈아 끼운다**"
printf '%s\n' "       bash /volume1/dss/setup/53-deploy.sh --preload"
printf '%s\n' "       bash /volume1/dss/setup/53-deploy.sh            ← 다시 --check"
printf '%s\n' "       bash /volume1/dss/setup/53-deploy.sh --migrate  🔴 **DB 가 바뀝니다**(124 → 125)"
printf '%s\n' "       bash /volume1/dss/setup/53-deploy.sh --go       ⏱ 정지 창 (앱 **둘**)"
printf '%s\n' "       bash /volume1/dss/setup/53-deploy.sh --count    ← 올린 뒤 수"
printf '%s\n' "     🔴 **--migrate 를 건너뛰지 마세요.** 52번과 다릅니다 — 이번 판은"
printf '%s\n' "        새 앱이 **없는 칸을 읽습니다.** --go 가 그것을 막지만, 차례대로 가세요."
printf '%s\n' ""
printf '%s\n' "🔴 **되돌리기**: --rollback 은 app-as 를 $AS_OLD_TAG · app-auth 를 $AUTH_OLD_TAG 로"
printf '%s\n' "   되돌립니다. 🔵 도구 둘은 $AS_TOOLS_TAG · $AUTH_TOOLS_TAG 그대로 둡니다"
printf '%s\n' "   (39·41~52번과 같은 판단 — 평소에 뜨지 않는 상자입니다)."
printf '%s\n' "   🔵 **0124 는 되돌리지 않아도 됩니다** — 칸과 제약을 **더하기만** 하고,"
printf '%s\n' "      옛 판 $AS_OLD_TAG 는 그 칸을 모르는 채로 멀쩡히 돕니다."
printf '%s\n' ""
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **배포 뒤 사람이 해야 하는 일 둘** — 53-deploy.sh 꼬리말에 다시 찍힙니다"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  ① 🔴 **[사용자 관리] › [승인 절차] 에서 「기타건 최종 출하 승인」 결재선을 한 판 세웁니다.**"
printf '%s\n' "     🔴 **안 세우면 기타건을 아무도 [완료] 처리할 수 없습니다** — 새 갈래는 판이"
printf '%s\n' "        0개이고, 이번 판부터 완료에 승인이 필요합니다. **가장 중요한 후속 작업입니다.**"
printf '%s\n' "  ② 포털 관리자 화면 › 결재 알림 메일 에서 **「기타건 최종 출하 결재」 스위치를 켭니다.**"
printf '%s\n' "     🔵 안 켜도 **종과 통합 승인함은 뜹니다.** 메일만 안 갑니다(기본값 끔 — 2026-10-23 결정)."
printf '%s\n' ""
printf '%s\n' "🔵 **개발에서 만든 절차를 운영에 넣는 일은 52번 꼬리말에서 넘어온 할 일입니다.**"
printf '%s\n' "   🔴 **이미 하셨으면 건너뛰세요** — 53-deploy.sh --count 가 운영의 절차 수를 찍습니다."
printf '%s\n' "   🔵 541287aa 가 **--prefix 를 더했습니다** — 이제 갈래별로 나눠 뜰 수 있습니다:"
printf '%s\n' "        npm run procedures:export -- --prefix \"[RFG]\" --out \"\$env:TEMP/rfg.json\""
printf '%s\n' "        npm run procedures:export -- --prefix \"[MB]\"  --out \"\$env:TEMP/mb.json\""
printf '%s\n' "     넣는 쪽 차례는 **53-deploy.sh --go 꼬리말**에 있습니다."
printf '%s\n' ""
printf '%s\n' "🔴 **알고도 안 고친 것 — PO 가 새 거절 코드를 모릅니다**"
printf '%s\n' "   dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 APPROVAL_REQUIRED 가 없습니다."
printf '%s\n' "   PO 에서 기타건을 [완료 처리] 하면 A/S 가 적어 보낸 안내 문장이 안 뜨고"
printf '%s\n' "   「모르는 응답」으로 떨어집니다. 🔵 자료는 안 깨집니다(A/S 는 한 글자도 안 썼고"
printf '%s\n' "   PO 도 「완료되었습니다」라고 말하지 않습니다). 🔴 **이 배포는 그것을 안 고칩니다.**"
printf '%s\n' "────────────────────────────────────────────────────────────"
