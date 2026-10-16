#!/bin/bash
# /volume1/dss/setup/28-deploy.sh — 2026-10-16 스물두째 배포
#
# ── 무엇이 올라가는가 ───────────────────────────────────────────────────
#
#   사내 사이트 여덟 중 **둘**이 올라간다. 🔴 **순서가 있다.**
#
#     재고 관리  dss-inventory:0.1        →  **dss-inventory:0.2**   (커밋 42)
#                dss-inventory-tools:1    →  **dss-inventory-tools:2**
#     A/S        dss-as:2.5               →  **dss-as:2.6**          (커밋 11)
#
#   나머지 여섯(포털 1.7 · 계측기 1.3 · 개선요청 0.3 · PO 0.5 · 휴가 0.2 ·
#   게시판 0.2)은 **건드리지 않는다. 멈추지도 않는다.**
#
#   🔵 A/S 는 서브모듈 vendor/dss-core 도 2ecdf01 로 함께 간다(이미지 안이다).
#   🔵 A/S 도구(dss-as-tools:1)는 **다시 굽지 않는다** — A/S 의 drizzle 은
#      이미지가 아니라 볼륨(/volume1/dss/as-migrations)이다.
#   🔴 재고 관리 도구는 **반드시 다시 굽는다** — 그쪽 Dockerfile 의 tools
#      스테이지가 「COPY drizzle ./drizzle」 로 마이그레이션을 **이미지 안에**
#      담는다. 옛 도구(:1)로는 새 11건을 아예 모른다(조용히 0건으로 끝난다).
#
# ══ 🔴 ① 순서 — 재고 관리를 **먼저**, A/S 를 나중에 ════════════════════
#
#   운영의 재고 관리 0.1 에는 A/S 2.6 이 부르는 통로가 **없다**:
#     · /api/v1/oh-templates            ← 0.2 에서 새로 생긴다
#     · /api/v1/stock-requests          ← 0.2 에서 새로 생긴다
#     · /api/v1/stock-requests/cancel   ← 0.2 에서 새로 생긴다
#     · /api/v1/parts/{no}/customer-name ← 0.2 에서 새로 생긴다
#   ⚠️ 🔴 /api/v1/parts 와 /api/v1/parts/{no} 는 **0.1 에도 이미 있다**
#      (2026-10-16 저장소 실측 · 8bf96ad 에 그 두 파일이 있다). 그래서
#      「통로가 전부 없다」가 아니라 **「넷이 새로 생긴다」**가 정확하다.
#      A/S 를 먼저 띄우면 부품 **목록**은 보이는데 O/H 템플릿 · 부품 요청 ·
#      고객사 품명이 전부 「확인하지 못했습니다」가 된다 — 반쪽만 도는 모양이
#      가장 나쁘다. 그래서 순서를 지킨다.
#
#   🔵 거꾸로도 하나 있다 — **A/S 의 읽기 통로 셋은 2.6 에서 처음 생긴다**
#      (/api/v1/users · /api/v1/intakes/{number} · /api/v1/product-models.
#       74f3f0e 에는 src/app/api/v1 폴더 자체가 없다 — 실측).
#      그래서 재고 0.2 를 먼저 띄운 **그 사이**에는 재고 쪽의 인수번호 조회와
#      결재자 명부가 못 닿는다. 🔵 **그것이 정상이고 조용히 망가지지 않는다** —
#      그 저장소 env.ts 가 「비어 있으면 응답 없음으로 다룬다 · 저장된 결재선은
#      그대로 보인다」로 설계했다. 5-ㄹ 가 그 창에서 404 를 보고, 5-ㅅ 가
#      A/S 교체 뒤에 401/200 으로 바뀌는 것을 본다.
#
#   🔴 **한 정지 창**에서 한다(열일곱째 21번이 사이트 둘을 한 창에서 올린
#      그 선례). 다만 **차례는 기계가 지킨다** — 재고를 띄워 통로가 값으로
#      대답하는 것을 본 **뒤에야** A/S 를 띄운다.
#
# ══ 🔴 ② 이번 판의 가장 큰 위험 — **새 설정값 여덟** ═══════════════════
#
#   두 시스템을 잇는 줄이 **여덟**이고 이번이 **처음**이다. 하나만 틀려도
#   조용히 반쪽만 돈다.
#
#     | 쓰임                         | A/S (as.env)            | 재고 (inventory.env)     |
#     | 재고가 A/S 를 읽는 토큰      | AS_API_TOKEN            | AS_LOOKUP_TOKEN  (같은 값)|
#     | A/S 가 재고를 **읽는** 토큰  | INVENTORY_API_TOKEN     | INVENTORY_API_TOKEN (같은)|
#     | A/S 가 재고에 **쓰는** 토큰  | INVENTORY_WRITE_TOKEN   | INVENTORY_WRITE_TOKEN(같은)|
#     | 주소                         | INVENTORY_API_BASE_URL  | AS_LOOKUP_URL · AS_API_BASE_URL |
#
#   🔵 **여덟이 맞다** — inventory.env 에는 INVENTORY_API_TOKEN 줄이 이미
#      있다(27번이 놓은 파일). 그래서 새로 적는 줄은 as.env 에 넷,
#      inventory.env 에 넷이다. (값이 비어 있을 수 있으니 길이도 본다.)
#
#   🔴 **읽기 토큰과 쓰기 토큰은 서로 다른 값이어야 한다.** 섞어 적으면
#      화면은 읽히는데 **올리기만 조용히 막힌다**(401). 그 저장소
#      src/lib/env.ts 의 inventoryWriteToken 머리말이 「프로그램은 막지 못한다」
#      고 적어 두었다 — 그래서 **이 스크립트가 막는다.**
#   🔴 **토큰이 비면 통로가 503 으로 닫힌다**(열어 두지 않는다). 둘 다 32자 이상.
#   🔴 **INVENTORY_API_BASE_URL 은 사내 도메인**이어야 한다
#      (https://inventory.dss21.co.kr). 그 값 하나가 **두 가지로** 쓰인다 —
#      A/S 서버가 재고를 부르는 주소이고, **A/S 재고 화면 안내 띠의 링크**
#      이기도 하다(inventory-gateway.ts 의 inventorySiteUrl). 컨테이너 안에서만
#      닿는 주소(http://app-inventory:3800 · 172.x)를 적으면 서버 호출은 되는데
#      **사람이 누르는 링크가 안 열린다** — 그런데 아무 오류도 안 난다.
#
#   🔴 **이 스크립트는 값을 만들지도 적지도 않는다.** 값은 사람이 NAS 의
#      env 파일에 적는다(아래 「사람이 할 일 ②」). 여기서 하는 일은
#      **비었거나 짝이 안 맞으면 멈추는 것**이다.
#   🔴 **값을 한 글자도 찍지 않는다.** 길이와 지문 앞 12자로만 견준다.
#   🔴 「있는가」로 재지 않는다 — **「맞는가」로** 잰다:
#        · 셋이 서로 다른 값인가(읽기 ≠ 쓰기)
#        · 양쪽 짝이 같은 값인가(지문 대조)
#        · 주소가 http:// · 172. · 서비스 이름이면 경고
#        · 🔴 **통로를 실제로 두드려 값을 받는다** — 토큰 넣고 200,
#          안 넣고 401. **둘 다** 본다. 「맞으면 되나」만 보면 자격이 아예
#          안 걸린 상태를 통과시킨다.
#        · 🔴 **앱이 쓰는 길로** 잰다 — 호스트의 curl 이 아니라 **A/S 컨테이너
#          안에서 node 의 fetch** 로 https://inventory.dss21.co.kr 를 부른다.
#          루프백(127.0.0.1:13800)으로 재면 DSM 프록시도 도커 망도 안 지난다.
#
# ══ 🔴 ③ 두 번째 위험 — 마이그레이션 **12건** ═════════════════════════
#
#   재고 관리 **11건**(0009 ~ 0019) + A/S **1건**(0115). 운영 기준:
#
#     재고 관리 dss_inventory :  9줄 → **20줄**  ·  표 13개 → **22개**
#     A/S       dss_as        : 115줄 → **116줄** ·  표 수는 안 변한다
#
#   ── 🔴 「지우는 문장」 — **있다. 셋이다.** 숨기지 않는다 ──────────────
#
#     잣대는 앱의 판정기(RF_Service_System/src/lib/db/migration-safety.ts)와
#     **같다**: DROP TABLE · DROP COLUMN · TRUNCATE · DELETE FROM.
#     🔴 「DELETE」 만으로 세지 않는다 — 외래키의 「ON DELETE cascade」 ·
#        「ON DELETE restrict」 가 이번 판에도 여러 번 나온다. 그 잣대를 쓰면
#        표만 더하는 판이 ✗ 가 된다(19번이 적어 둔 그 함정).
#
#     2026-10-16 저장소 실측 — DROP COLUMN 이 **셋**이다:
#       0012_bored_earthquake  : oh_part_template_items DROP COLUMN oh_price
#       0012_bored_earthquake  : oh_part_templates      DROP COLUMN sort_order
#       0014_goofy_miracleman  : oh_part_templates      DROP COLUMN code
#     그리고 DROP INDEX 둘(0012 · 0014, 전부 oh_part_templates). DROP INDEX 는
#     자료를 지우지 않는다 — migration-safety 의 「살펴볼 것」 쪽이다.
#
#     🔵 **셋 다 운영 자료를 지우지 않는다.** 그 두 표가 **같은 묶음 안의
#        0011 에서 태어나기** 때문이다. 운영 DB 는 지금 0008 까지라 그 표가
#        **아예 없다** — 0011 이 만들고, 0012 · 0014 가 그 자리에서 칸을
#        다듬는다. 지울 자료가 생길 틈이 없다.
#     🔴 그래도 **되돌릴 수 없는 문장**인 것은 맞다. 그래서 --migrate 는
#        이 사실을 먼저 크게 알리고, **--drop-column-ok 를 같이 주지 않으면
#        시작하지 않는다.** 그리고 적용 **전에** 운영 DB 에 그 두 표가 정말
#        없는지 센다 — 있으면 전제가 깨진 것이라 **멈춘다.**
#     🔵 A/S 0115 에는 지우는 문장이 **하나도 없다**(칸 하나 + CHECK 하나).
#
#   ── 🔵 적용해 놓고 옛 판을 그대로 띄워도 안 깨진다 ────────────────────
#     재고 0.1 이 쓰던 표에 더해지는 칸은 전부 DEFAULT 가 있거나 NULL 을 받는다
#     (parts.customer_name DEFAULT '' · parts.limit_quantity NULL ·
#      stock_requests.source DEFAULT 'INVENTORY' · hold_reason DEFAULT '' …).
#     requested_by 는 **NOT NULL 을 푸는** 쪽이라 더 느슨해진다.
#     A/S 0115 의 CHECK 는 새 칸이 NULL 이면 늘 참이라 2.5 의 저장이 안 막힌다.
#     🔴 그래서 되돌리기는 **이미지만 내리고 DB 는 그대로 두는 것**이다.
#
# ══ 🔴 ④ 되돌리는 길 — 잘못되면 어디로 가나 ═══════════════════════════
#
#   되돌릴 것은 **셋**이고 전부 이 스크립트가 남긴다:
#
#     ① compose      backups/docker-compose.nas.yml.<도장>
#                    (--migrate 가 태그 세 줄을 고치기 **전에** 뜬 사본)
#     ② A/S 마이그레이션 폴더   /volume1/dss/as-migrations.old
#                    (--migrate 가 115 짜리 폴더를 그 이름으로 치워 둔다)
#     ③ DB 덤프      backups/predeploy-<도장>/dss_inventory.dump · dss_as.dump
#                    🔴 **마지막 수단이다.** 되돌리기의 기본이 아니다.
#
#   되돌리는 차례(명령은 --rollback 이 찍어 준다):
#     1) compose 를 ① 로 되돌린다  → 태그가 0.1 · tools:1 · 2.5 로 돌아간다
#     2) up -d --no-deps app-inventory app-as  → 옛 판 둘이 다시 뜬다
#     3) 🔴 **DB 는 되돌리지 않는다**(위 ③절의 까닭). 표와 칸이 더 있는 채로
#        옛 판이 그대로 돈다.
#     4) env 의 여덟 줄도 **그대로 둔다** — 옛 판은 그 이름을 읽지 않는다.
#   🔴 DB 자체가 깨졌을 때만 ③ 의 덤프를 쓴다. 그때는 **먼저 알리고** 사람이
#      판단한다 — PO 가 같은 dss_as 를 보고 있어 덤프 뒤의 PO 저장분이 사라진다.
#
#   🔴 **이미지는 지우지 않는다.** dss-inventory:0.1 · dss-inventory-tools:1 ·
#      dss-as:2.5 가 NAS 에 그대로 있어야 되돌릴 수 있다. 검사가 그것을 센다.
#
# ══ 🔴 ⑤ compose — **저장소 사본을 올리지 않는다** ════════════════════
#
#   🔴 이번 판은 compose 파일을 **올리지 않는다.** 이 저장소의
#      nas/docker-compose.nas.yml 은 재고 관리 두 블록이 **아직 주석**이다
#      (27-inventory-place.sh 가 NAS 에서 87줄을 벗겼고, 저장소 사본은 그대로다).
#      그것을 올리면 **재고 관리가 compose 에서 통째로 사라진다.**
#
#   → 그래서 이 스크립트가 **NAS 의 파일에서 image 줄 셋만** 고친다:
#        image: dss-inventory:0.1       →  image: dss-inventory:0.2
#        image: dss-inventory-tools:1   →  image: dss-inventory-tools:2
#        image: dss-as:2.5              →  image: dss-as:2.6
#      · 고치기 **전에** 사본을 뜬다(backups/docker-compose.nas.yml.<도장>)
#      · 글자 비교다 — 정규식이 아니다(태그의 점이 아무 글자나 맞는 일이 없게)
#      · 바꾸기 전 「옛 태그 1줄 · 새 태그 0줄」, 바꾼 뒤 「0줄 · 1줄」을 센다
#      · 줄 수가 한 줄이라도 달라지면 **사본으로 되돌리고 멈춘다**
#      · 바꾼 뒤 compose config 를 다시 돌리고, 건드리지 않는 열한 태그가
#        그대로인지 센다
#   🔴 태그를 고쳐도 **아무것도 안 뜨고 안 멈춘다.** compose 는 글자일 뿐이다.
#      다만 그 뒤로 누가 **인자 없는 up -d** 를 부르면 새 판이 올라온다 —
#      부르지 마세요(19번이 적어 둔 그 당부).
#
# ══ 🔴 ⑥ 사람이 할 일 — 스크립트가 못 하는 것 ═════════════════════════
#
#   ① 🔴 **배포 전에** 운영 DB 의 권한 칸을 본다 (--check 가 보여 준다):
#        select area_key, role, level from role_permissions
#         where area_key like 'inventory%'
#      inventory.requests 가 A/S 새 통로의 **문**이다. 저장된 값이 코드의
#      기본값을 이긴다 — 거기가 NONE 이면 부품 요청이 통째로 안 된다.
#   ② 🔴 env 여덟 줄을 NAS 의 as.env · inventory.env 에 적는다
#      (--check 가 틀을 찍어 준다. 🔴 값은 사람만 안다).
#   ③ 🔴 **재고 관리에서 승인 절차(결재선)를 저장한다.** 운영 DB 의
#      approval_routes 가 비어 있으면 부품 불출 결재가 안 돈다. 이 스크립트는
#      표가 섰는지와 줄이 몇인지만 세고 **넣지 않는다**(사람이 화면에서 고른다).
#   ④ 야간 백업이 새 표까지 담는지 본다 — 배포 **다음 날 아침**에
#      덤프 일곱과 files 둘을 센다(마무리 안내에 그 명령이 있다).
#
# ══ 🔴 ⑦ 야간 백업 시각을 지킨다 — **02:30** ═══════════════════════════
#
#   🔴 자정을 넘겨 돌리면 백업 검사에 걸린다. --migrate 는 **오늘 뜬
#      dss_inventory · dss_as 백업이 둘 다 없으면 시작조차 않는다.**
#      17번이 01:00 에 돌렸다가 실제로 막혔고, 그것이 사고를 막았다.
#      늦은 시각이면 먼저 손으로 한 번 (종료 코드 0 이어야 한다):
#        bash /volume1/dss/jobs/backup-nightly.sh
#
# ══ 🔴 돌리기 전에 — **값 아홉을 채워야 한다** ═════════════════════════
#
#   🔴 이 스크립트를 쓴 세션은 docker build 를 돌리지 않았다. 그래서 아래
#      아홉이 **비어 있다**:
#        SZ_INV · MD5_INV · WANT_CFG_INV
#        SZ_INVTOOLS · MD5_INVTOOLS · WANT_CFG_INVTOOLS
#        SZ_AS · MD5_AS · WANT_CFG_AS
#      비어 있는 동안 --check 는 ⚠️ 로만 말하고, 🔴 **--migrate 도 --go 도
#      시작하지 않는다.** 잰 적 없는 이미지를 운영에 올리지 않는다.
#
#   굽고 재는 차례는 이 파일 맨 아래 「사람이 칠 명령」 절에 있다.
#   🔴 tar 가 이미지의 1/4 쯤인 것은 **정상**이다(584MB 이미지 → 130MB tar).
#      지난 판 tar 와 견주세요: dss-as-2.5.tar · dss-inventory-0.1.tar.
#   🔴 tar 안 Config 지문은 개발 PC 의 {{.Id}} 와 **다르다.** NAS 는 tar 안의
#      config 지문을 image ID 로 낸다 — 맞춰 볼 값은 **tar 쪽**이다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/28-deploy.sh        ← 읽기만 한다
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#   · MODE=check        (모드 절의 첫 줄)
#   · FORCE_LOAD=0      (같은 태그를 덮어쓰지 않는다)
#   · DROP_OK=0         (지우는 문장을 받아들인 적이 없다)
#   DB 를 바꾸는 곳은 --migrate 한 군데뿐이고, 컨테이너를 바꿔 끼우는 곳은
#   --go 한 군데뿐이다. --check 는 그 둘을 **부르지 않는다.**
#
#   🔴 정직하게 적어 둔다 — --check 도
#      ① 이미지 **안을 보려고** 컨테이너를 잠깐 띄웠다 지운다
#      ② 도는 컨테이너 안에서 **node 로 통로를 두드린다**(읽기 요청뿐이다)
#      「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#      🔴 두드리는 것은 **GET 과, 자격이 막힐 POST 하나**뿐이다. 그 POST 는
#         **읽기 토큰으로** 보내므로 문지기가 먼저 401 로 돌려보낸다 —
#         본문을 읽기도 전이라 DB 에 한 줄도 안 쓴다(그 라우트의 첫 두 줄).
#
# ── 모드 여섯 ───────────────────────────────────────────────────────────
#   (없음) · --check   읽기만. 아무것도 안 바꾸고 안 멈춘다        ← 기본값
#   --preload          이미지 **셋**을 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load       🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --migrate          🔴 compose 태그 셋 + 마이그레이션 12건. **DB 가 바뀐다**
#                      🔴 --drop-column-ok 를 함께 주어야 시작한다
#   --go               ⏱ 재고 → (통로 확인) → A/S 를 바꿔 끼운다
#   --rollback         되돌리는 명령을 찍는다 (아무것도 안 바꾼다)
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 28-deploy.sh                          읽기만
#   2) bash 28-deploy.sh --preload                이미지 셋을 싣는다
#   3) bash 28-deploy.sh                          다시 읽기만 (지문까지)
#   4) bash 28-deploy.sh --migrate --drop-column-ok   🔴 DB 가 바뀐다
#   5) bash 28-deploy.sh --go                     ⏱ 정지 창
#   6) 눈으로 확인 (--go 끝의 안내)
#
# ══ 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ════════════════════════
#   ① 큰따옴표 안의 백틱은 **명령 치환**으로 읽힌다.
#      → 이 파일에는 백틱이 **한 개도 없다**(쓴 뒤 세어 확인했다).
#   ② 읽기 전용 자리의 리다이렉션은 ash 가 셸을 그 자리에서 끝낸다.
#      → 빈 파일은 **touch**, 폴더는 **mkdir** 로 만든다. 「: > 파일」 꼴이
#        이 파일에 **한 군데도 없다**.
#   🔴 19 · 20 · 21번에는 아직 남아 있다 — 베낄 때 함께 베끼지 않았다.
#
# ══ DSM 터미널은 긴 명령을 잘라 먹는다 ═════════════════════════════════
#   그래서 NAS 에서 돌릴 것은 **파일로 올리고 md5 를 맞춘 뒤** 실행한다.
#   이 스크립트가 찍는 명령은 전부 cmd() 를 지나 **76자 안쪽**이다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
TODAY=$(date +%F)
CF=$D/deploy/docker-compose.nas.yml
ENV_NAS=$D/deploy/.env.nas
ENVD=$D/deploy/env
AS_ENV=$ENVD/as.env
INV_ENV=$ENVD/inventory.env
IMAGES=$D/images
BKD=$D/backups
JOBS=$D/jobs

# ── 🔴 이번에 올라가는 것 **셋** ───────────────────────────────────────
TAG_INV=dss-inventory:0.2;        OLD_INV=dss-inventory:0.1
TAG_INVTOOLS=dss-inventory-tools:2; OLD_INVTOOLS=dss-inventory-tools:1
TAG_AS=dss-as:2.6;                OLD_AS=dss-as:2.5

# ── tar 셋 ─────────────────────────────────────────────────────────────
# 🔴 아홉이 **비어 있다.** 개발 PC 에서 굽고 재어 채운다(맨 아래 안내).
#    🔵 지난 판 참고 — dss-inventory:0.1 의 tar 는 95,283,712 바이트,
#       dss-inventory-tools:1 은 212,687,872, dss-as:2.5 는 약 131MB 였다.
#       tar 가 이미지의 1/4 쯤인 것은 정상이다.
TAR_INV=$IMAGES/dss-inventory-0.2.tar
SZ_INV="95390720";       MD5_INV="197f2df976d754224075c86ceaac78f0";       WANT_CFG_INV="sha256:72abaa01b66d0b64abd84c59a1c8acf4b7d110acfa7e0e74184c98b2da2b9adf"
TAR_INVTOOLS=$IMAGES/dss-inventory-tools-2.tar
SZ_INVTOOLS="212990976";  MD5_INVTOOLS="408d8c2bd15cf56a9263dc17522569fe";  WANT_CFG_INVTOOLS="sha256:e8ae8c9cf5d9acf8eaf40d5f5167abd74a3509bdc5dcc32d7bbcba050a8ffe45"
TAR_AS=$IMAGES/dss-as-2.6.tar
SZ_AS="131566592";        MD5_AS="cf0cc6b50f2f48b7c26dfbaa30291489";        WANT_CFG_AS="sha256:2f96d9498d2dc7c5bbbd9e127ae46dbcfdfc13d3d00d0f9aead1486da7fcabab"

# ── 🔴 **건드리지 않는 열하나.** ───────────────────────────────────────
# 전부 지금 운영에서 돌고 있다. compose 에서 이 태그가 흔들렸으면 남의 것이
# 섞인 것이다(두 세션이 같은 저장소를 쓴다). 고치지 말고 **먼저 알린다.**
# 🔴 이 목록은 **2026-10-14 27번(재고 관리 첫 설치) 직후** 기준이다.
KEEP_AUTH=dss-auth:1.7
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_METERSTOOLS=dss-meters-tools:1
KEEP_IMP=dss-improvements:0.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_PO=dss-po:0.5
KEEP_LEAVE=dss-leave:0.2
KEEP_LEAVETOOLS=dss-leave-tools:2
KEEP_BOARD=dss-board:0.2
KEEP_BOARDTOOLS=dss-board-tools:1
KEEP_TAGS="$KEEP_AUTH $KEEP_ASTOOLS $KEEP_METERS $KEEP_METERSTOOLS"
KEEP_TAGS="$KEEP_TAGS $KEEP_IMP $KEEP_IMPTOOLS $KEEP_PO $KEEP_LEAVE"
KEEP_TAGS="$KEEP_TAGS $KEEP_LEAVETOOLS $KEEP_BOARD $KEEP_BOARDTOOLS"
# 건드리지 않는 **여섯 사이트**의 컨테이너와 바깥 이름
KEEP_BOXES="dss-auth dss-meters dss-improvements dss-po dss-leave dss-board"
KEEP_HOSTS="login meters improvements po leave board"

# ── 서비스 · 포트 · 컨테이너 ───────────────────────────────────────────
INV_SVC=app-inventory;   INV_TOOLS_SVC=tools-inventory
INV_CNAME=dss-inventory; INV_PORT=13800
INV_BASE=https://inventory.dss21.co.kr
INV_DATA=$D/inventory-data
# 🔴 27번이 정한 자리. 현황판 엑셀이 여기 쌓인다 — gid 100 이어야 쓸 수 있다.
INV_SHARE_WB="/volume1/2_AS센터/2. 부품 관리/1. 재고 및 부품 입출고 관리/4. 재고관리 시스템"
UID_APP=1001; GID_APP=100
AS_SVC=app-as;  AS_TOOLS_SVC=tools-as
AS_CNAME=dss-as; AS_PORT=13000
AS_BASE=https://as.dss21.co.kr

# ══ 마이그레이션 — 🔴 재고 11 + A/S 1 ═════════════════════════════════
INV_DB=dss_inventory
INV_MIG_HAVE=9;   INV_MIG_WANT=20
INV_TBL_HAVE=13;  INV_TBL_WANT=22
INV_NEW_MIGS="0009 0010 0011 0012 0013 0014 0015 0016 0017 0018 0019"
# 🔴 실측이다 (dss-inventory/drizzle/meta/_journal.json · 2026-10-16).
INV_MIG_TAGS="0009_volatile_sue_storm 0010_concerned_lucky_pierre"
INV_MIG_TAGS="$INV_MIG_TAGS 0011_nice_daimon_hellstrom 0012_bored_earthquake"
INV_MIG_TAGS="$INV_MIG_TAGS 0013_hesitant_rhino 0014_goofy_miracleman"
INV_MIG_TAGS="$INV_MIG_TAGS 0015_whole_ares 0016_swift_pride 0017_warm_namora"
INV_MIG_TAGS="$INV_MIG_TAGS 0018_noisy_puff_adder 0019_high_calypso"
# 🔴 새로 서는 표 **아홉** (0009~0019 의 CREATE TABLE 전수 · 실측)
INV_NEW_TABLES="stock_request_issues oh_part_template_items oh_part_templates"
INV_NEW_TABLES="$INV_NEW_TABLES oh_part_template_models part_overhaul_unit_prices"
INV_NEW_TABLES="$INV_NEW_TABLES approval_route_steps approval_routes"
INV_NEW_TABLES="$INV_NEW_TABLES stock_issue_approval_steps stock_issue_approvals"
# 🔴 새로 서는 타입 넷
INV_NEW_TYPES="approval_route_scope stock_issue_approval_status"
INV_NEW_TYPES="$INV_NEW_TYPES stock_issue_approval_step_status stock_request_source"
# 🔴 **있던 표에 더해지는 칸** — 전부 DEFAULT 가 있거나 NULL 을 받는다
INV_NEW_COLS="parts:customer_name parts:limit_quantity stock_requests:hold_reason"
INV_NEW_COLS="$INV_NEW_COLS stock_requests:held_by stock_requests:held_by_name"
INV_NEW_COLS="$INV_NEW_COLS stock_requests:held_at stock_requests:source"
INV_NEW_COLS="$INV_NEW_COLS stock_requests:external_key stock_requests:requester_sub"
# 🔴 **지우는 문장이 손대는 두 표.** 적용 전에 운영 DB 에 **없어야** 한다 —
#    0011 이 만들고 0012 · 0014 가 그 자리에서 칸을 다듬기 때문이다.
INV_DROP_TABLES="oh_part_templates oh_part_template_items"
# 🔴 줄 수가 그대로여야 하는 표 — 마이그레이션 전후로 센다
INV_COUNT_TABLES="parts stock_entries stock_transactions legacy_records stock_balances"

AS_DB=dss_as
AS_MIG_HAVE=115;  AS_MIG_WANT=116
AS_NEW_MIGS="0115"
AS_MIG_TAG=0115_massive_omega_red
MIGDIR=$D/as-migrations          # compose 가 tools-as 의 /app/drizzle 로 붙인다
MIGTAR=$D/setup/incoming/as-migrations.tar.gz
SZ_MIG="2152901"; MD5_MIG="c01d8647c5cc596712fb11f7e00f8c21"
# 🔴 0115 가 **진짜 그 파일인지** 보는 글자 (실측)
AS_MIG_MARK='ADD COLUMN "inventory_part_no"'
AS_NEW_COL_TBL=quote_items
AS_NEW_COL=inventory_part_no
AS_NEW_CHECK=quote_items_inventory_part_no_item_line_only
AS_COUNT_TABLES="quote_items quotes repair_cases attachments"

# 🔴 지우는 문장을 세는 잣대 — 앱의 판정기와 **같은 잣대**다
#    (RF_Service_System/src/lib/db/migration-safety.ts).
# 🔵 \b 를 쓰지 않는다 — DSM 의 grep 이 GNU 가 아닐 수 있다. POSIX ERE 로만.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
# 🔴 「살펴볼 것」 — 자료를 지우지는 않지만 되돌리기 어려운 것들
RISKY_RE='DROP[[:space:]]+INDEX|RENAME|SET[[:space:]]+NOT[[:space:]]+NULL'
# 🔴 이번 판에 **있는 것이 맞는** 지우는 문장의 수 (재고 3 · A/S 0)
INV_DROP_WANT=3
AS_DROP_WANT=0

# ══ 🔴 새 설정값 여덟 ══════════════════════════════════════════════════
# as.env 에 **새로 적을 넷**
AS_NEW_KEYS="AS_API_TOKEN INVENTORY_API_BASE_URL INVENTORY_API_TOKEN INVENTORY_WRITE_TOKEN"
# inventory.env 에 **새로 적을 넷** (INVENTORY_API_TOKEN 은 이미 줄이 있다)
INV_NEW_KEYS="AS_LOOKUP_URL AS_LOOKUP_TOKEN AS_API_BASE_URL INVENTORY_WRITE_TOKEN"
# inventory.env 에 **있어야 하는** 전부 (27번의 여덟 + 이음새 다섯)
INV_LINK_KEYS="AS_LOOKUP_URL AS_LOOKUP_TOKEN AS_API_BASE_URL INVENTORY_API_TOKEN INVENTORY_WRITE_TOKEN"
# 27번이 정한 여덟 — 하나라도 사라지면 앱이 시작할 때 던진다
INV_BASE_KEYS="SSO_ISSUER SSO_CLIENT_ID SSO_CLIENT_SECRET SSO_REDIRECT_URI"
INV_BASE_KEYS="$INV_BASE_KEYS AUTH_SESSION_SECRET SSO_TX_SECRET SESSION_COOKIE_SECURE SESSION_HOURS"
# inventory.env 에 **있으면 안 되는** 것들 (27번의 목록 그대로)
INV_FORBIDDEN="DATABASE_URL PORT TZ INVENTORY_DATA_DIR STOCK_WORKBOOK_PATH"
INV_FORBIDDEN="$INV_FORBIDDEN STOCK_WORKBOOK_TEMPLATE_PATH STOCK_DOWNLOAD_TEMPLATE_PATH"
INV_FORBIDDEN="$INV_FORBIDDEN DEV_ROLE_OVERRIDE WORKBOOK_SYNC_DISABLED DEV_POSTGRES_PASSWORD"
# 🔴 as.env 에 **그대로 있어야 하는** 줄들. 사라졌으면 누가 덮어쓴 것이고,
#    그때는 배포보다 그것이 먼저다 (22번의 목록 그대로).
AS_QUOTE_KEYS="QUOTE_ARCHIVE_DIR QUOTE_ARCHIVE_UNC_ROOT QUOTE_ARCHIVE_UNC_ROOT_ALT"
AS_PORTAL_KEYS="CUSTOMER_PORTAL_ARCHIVE_DIR CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT CUSTOMER_PORTAL_ARCHIVE_FOLDER_PATH CUSTOMER_PORTAL_ARCHIVE_UNC_PATH"
AS_CONTACT_KEYS="CONTACT_FOLDER_ARCHIVE_DIR CONTACT_FOLDER_ARCHIVE_UNC_ROOT CONTACT_FOLDER_ARCHIVE_UNC_PATH"
AS_REPAIR_KEYS="REPAIR_DOCS_ARCHIVE_DIR REPAIR_DOCS_ARCHIVE_UNC_ROOT"
AS_PO_KEYS="PURCHASE_ORDER_ARCHIVE_DIR PURCHASE_ORDER_ARCHIVE_UNC_ROOT"
# as.env 에 있으면 안 되는 것 (compose 가 넘긴다)
AS_FORBIDDEN="DATABASE_URL UPLOADS_DIR PORT"

# ── 권한 — 🔴 **읽기만 한다** ──────────────────────────────────────────
PERM_TABLE=role_permissions
PERM_SQL_COUNT="select count(*) from role_permissions where area_key like 'inventory%'"
PERM_SQL_AREA="select area_key, role, level from role_permissions where area_key like 'inventory%' order by 1, 2"
PERM_GATE=inventory.requests

# ── 통로 — 🔴 값으로 확인할 자리들 ─────────────────────────────────────
# 0.1 에 **이미 있던** 통로 (바꾸기 전에도 401 이 나온다)
P_PARTS=/api/v1/parts
# 0.2 에서 **새로 생기는** 통로 셋 (바꾸기 전에는 404 가 나와야 한다)
P_OHT='/api/v1/oh-templates?modelId=00000000-0000-0000-0000-000000000000'
P_SREQ='/api/v1/stock-requests?intake=DSS-PROBE-0000'
P_SREQ_POST=/api/v1/stock-requests
# A/S 가 2.6 에서 **처음** 내는 통로 셋
P_AS_USERS=/api/v1/users
P_AS_MODELS=/api/v1/product-models
P_AS_INTAKE=/api/v1/intakes/DSS-PROBE-0000

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 셋. 인자가 없으면 이 셋 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
DROP_OK=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 28-deploy.sh                 읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 28-deploy.sh --check         위와 같습니다
  bash 28-deploy.sh --preload       이미지 셋을 싣고 지문을 맞춥니다
  bash 28-deploy.sh --force-load    🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 28-deploy.sh --migrate --drop-column-ok
                                    🔴 compose 태그 셋 + 마이그레이션 12건
                                       **DB 가 바뀝니다**
  bash 28-deploy.sh --go            ⏱ 재고 → (통로 확인) → A/S 교체
  bash 28-deploy.sh --rollback      되돌리기 안내 (아무것도 안 바꿉니다)

  🔴 차례:  (없음) → --preload → (없음) → --migrate --drop-column-ok → --go
  🔴 --migrate 와 --go 는 **따로** 부릅니다. 마이그레이션이 덜 된 DB 에
     새 판이 뜨면 없는 표를 읽다 그 자리에서 죽습니다.
  🔴 --go 가 바꿔 끼우는 것은 app-inventory 와 app-as 둘입니다. 포털 ·
     계측기 · 개선요청 · PO · 휴가 · 게시판 · DB 는 그대로 돕니다.
  🔴 --drop-column-ok 가 없으면 --migrate 는 시작하지 않습니다. 이번 판에는
     DROP COLUMN 이 셋 있습니다 (까닭은 이 파일 머리말 ③절).
USAGE
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)          MODE=check ;;
    --preload)        MODE=preload ;;
    --force-load)     FORCE_LOAD=1; [ "$MODE" = check ] && MODE=force-load ;;
    --migrate)        MODE=migrate ;;
    --drop-column-ok) DROP_OK=1 ;;
    --go)             MODE=go ;;
    --rollback)       MODE=rollback ;;
    -h|--help)        usage; exit 0 ;;
    *) echo "모르는 인자: $1"; usage; exit 2 ;;
  esac
  shift
done

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/28-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 27 · 22번의 것을 그대로 쓴다 ──────────────────────────────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }
# 🔴 「아직 안 온 것」은 ✗ 가 아니다 (17~19번의 그 규칙)
notyet() { echo "  ⚠️ $*"; }

# ── 사람이 칠 명령은 76자 안쪽으로만 찍는다 ────────────────────────────
CMDW=76
cmd() { # 1 사람이 그대로 칠 명령 한 줄
  printf '    %s\n' "$1"
  if [ "${#1}" -gt "$CMDW" ]; then
    printf '    ⚠️ 위 줄이 %s자다(%s자 넘음) — 붙여넣으면 잘릴 수 있다.\n' "${#1}" "$CMDW"
    printf '       아래 「스크립트 파일로 만들기」를 쓰세요.\n'
  fi
}
script_file_hint() { # 1 파일이름(확장자 없이)
  say "    ── 길면 붙여넣지 말고 파일로 만드세요 ──"
  cmd "cat > /volume1/dss/setup/$1.sh"
  say "      (여기에 위 줄들을 붙여넣고 Ctrl+D)"
  cmd "bash /volume1/dss/setup/$1.sh"
}

COMPOSE=("$DOCKER" compose -f "$CF" --env-file "$ENV_NAS" --profile tools)
compose_at() { # 1 compose파일  나머지: compose 에 넘길 인자
  local f="$1"; shift
  "$DOCKER" compose --project-directory "$D/deploy" -f "$f" --env-file "$ENV_NAS" --profile tools "$@"
}

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미 — 🔴 --migrate 말고는 전부 select 다
#
#  🔴 아래 셋은 컨테이너 안에서 **유닉스 소켓**으로 붙는다(superuser).
#     읽기에는 그것으로 충분하다. 「비밀번호가 맞는가」는 이것으로 알 수 없다 —
#     소켓은 보통 trust 라 거짓 통과를 낸다. 이번 판은 롤도 비밀번호도
#     건드리지 않으므로(둘 다 이미 운영에서 돌고 있다) 그 확인은 하지 않는다.
# ══════════════════════════════════════════════════════════════════════
qi()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $INV_DB -Atc \"$1\"" 2>/dev/null; }
qas() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB  -Atc \"$1\"" 2>/dev/null; }
qqas(){ "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB  -c   \"$1\"" 2>/dev/null; }

pg_up()   { "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-app; }
running() { "$DOCKER" ps --format '{{.Names}}' | grep -qx "$1"; }

inv_mig_table() { qi  "select to_regclass('drizzle.__drizzle_migrations')"; }
inv_mig_count() { qi  "select count(*) from drizzle.__drizzle_migrations"; }
inv_tbl_count() { qi  "select count(*) from information_schema.tables where table_schema='public'"; }
inv_tbl_has()   { qi  "select count(*) from information_schema.tables where table_schema='public' and table_name='$1'"; }
as_mig_count()  { qas "select count(*) from drizzle.__drizzle_migrations"; }

# ── 설정 파일에서 값 하나를 꺼낸다 ─────────────────────────────────────
# 🔴 부르는 쪽은 이 값을 **절대 화면에 찍지 않는다.** 판정에만 쓴다.
# 🔴 같은 이름이 두 줄이면 **나중 것**을 읽는다(docker compose 가 그렇게 읽는다).
env_val() { # 1 파일 2 키
  local v
  [ -r "$1" ] || { printf ''; return 1; }
  v=$(sed -n "s/^[[:space:]]*\(export[[:space:]][[:space:]]*\)\?$2=//p" "$1" 2>/dev/null | tail -1 | tr -d '\r')
  v=${v#\"}; v=${v%\"}
  v=${v#\'}; v=${v%\'}
  printf '%s' "$v"
}
env_has()  { grep -qE "^[[:space:]]*(export[[:space:]]+)?$2=" "$1" 2>/dev/null; }
env_dups() {
  # 🔴 「|| echo 0」을 붙이지 않는다. grep -c 는 0건일 때도 0 을 찍고 종료코드만
  #    1 이라, 붙이면 값이 두 줄이 되어 비교가 전부 어긋난다(27번의 그 자리).
  grep -cE "^[[:space:]]*(export[[:space:]]+)?$2=" "$1" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 비밀값을 **견주되 찍지 않는다**
#
#  값 자체는 한 글자도 안 나간다. 나가는 것은 **길이**와 **지문 앞 12자**뿐이다.
#  그 둘이면 「양쪽이 같은 값인가」와 「읽기와 쓰기가 다른 값인가」를 다 가른다.
#  🔴 sha256 이 없는 DSM 도 있어 셋 중 되는 것을 쓰고, **무엇으로 쟀는지 말한다.**
# ══════════════════════════════════════════════════════════════════════
# 🔴 **되돌려 주지 않고 전역에 담는다.** $( ) 로 부르면 그 안에서 센 ✓/✗ 가
#    부분 셸과 함께 사라지고(PASS·FAIL 이 안 는다), 화면에 찍힌 글까지 값에
#    섞여 들어온다. 이 파일에서 ✓/✗ 를 세는 함수는 **전부** 이 꼴로 쓴다.
DIGEST_ALG=""
DIGEST_OUT=""
digest() { # 1 값 → DIGEST_OUT 에 지문 앞 12자 (빈 값이면 빈 글자)
  local v="$1" h=""
  DIGEST_OUT=""
  [ -n "$v" ] || return 0
  if command -v sha256sum >/dev/null 2>&1; then
    DIGEST_ALG=sha256; h=$(printf '%s' "$v" | sha256sum 2>/dev/null | awk '{print $1}')
  elif command -v openssl >/dev/null 2>&1; then
    DIGEST_ALG=sha256; h=$(printf '%s' "$v" | openssl dgst -sha256 2>/dev/null | awk '{print $NF}')
  else
    DIGEST_ALG=md5;    h=$(printf '%s' "$v" | md5sum 2>/dev/null | awk '{print $1}')
  fi
  DIGEST_OUT=$(printf '%s' "$h" | cut -c1-12)
  return 0
}
# 값을 그대로 찍지 않는다 — 숫자를 N 으로 가린 앞머리만 남긴다(27번).
href_shape() { printf '%s' "$1" | cut -c1-56 | sed 's/[0-9]/N/g'; }

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 개발 PC 의 docker image inspect 가 아니라 **이 값**이 NAS 에 실렸을 때의
#    image ID 가 된다.
tar_config_id() { # 1 tar 경로  → sha256:<지문>
  local raw v
  raw=$(tar -xOf  "$1" manifest.json 2>/dev/null) || raw=""
  [ -n "$raw" ] || raw=$(tar -xzOf "$1" manifest.json 2>/dev/null) || raw=""
  v=$(printf '%s' "$raw" \
      | sed -n 's/.*"Config"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  v=${v##*/}; v=${v%.json}
  [ -n "$v" ] || return 1
  echo "sha256:$v"
}
have_img() { "$DOCKER" image inspect "$1" >/dev/null 2>&1; }
img_id()   { "$DOCKER" image inspect "$1" --format '{{.Id}}' 2>/dev/null; }

verify_img() { # 1 태그 2 기대지문
  local got
  got=$(img_id "$1")
  if [ "$got" != "$2" ]; then
    bad "$1 지문이 tar 와 다르다 (NAS ${got:-없음} / tar $2)"
    return 1
  fi
  ok "$1 지문 맞음 ($(echo "$2" | cut -c1-19)…)"
}
force_load_hint() {
  say "    🔴 같은 태그로 **다시 구운** 이미지일 수 있다. 덮어쓰려면:"
  cmd "bash $0 --preload --force-load"
}
bring_img() { # 1 태그 2 tar 3 지문
  if [ "$FORCE_LOAD" = 1 ]; then
    say "  · --force-load — $1 가 이미 있어도 **다시 싣는다**"
    "$DOCKER" load -i "$2" >/dev/null 2>&1 && ok "$1 다시 실었다" \
      || { bad "$1 싣기 실패 ($2)"; return 1; }
  elif have_img "$1"; then
    say "  · $1 는 이미 실려 있다 — 다시 싣지 않는다 (덮어쓰려면 --force-load)"
  else
    "$DOCKER" load -i "$2" >/dev/null 2>&1 && ok "$1 실었다" \
      || { bad "$1 싣기 실패 ($2)"; return 1; }
  fi
  verify_img "$1" "$3" || { force_load_hint; return 1; }
}

# 🔴 기대값 아홉이 다 찼는가. 비어 있으면 --migrate 도 --go 도 시작하지 않는다.
pinned() {
  [ -n "$SZ_INV" ] && [ -n "$MD5_INV" ] && [ -n "$WANT_CFG_INV" ] \
  && [ -n "$SZ_INVTOOLS" ] && [ -n "$MD5_INVTOOLS" ] && [ -n "$WANT_CFG_INVTOOLS" ] \
  && [ -n "$SZ_AS" ] && [ -n "$MD5_AS" ] && [ -n "$WANT_CFG_AS" ]
}

wait_http() { # 1 이름 2 포트 3 경로 4 컨테이너
  local i code
  for i in $(seq 1 90); do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://127.0.0.1:$2$3" 2>/dev/null)
    case "$code" in 2??|3??) ok "$1 응답 $code ($((SECONDS - T0))초)"; return 0 ;; esac
    sleep 2
  done
  bad "$1 이 180초 안에 대답하지 않았다 (마지막 ${code:-없음})"
  say "    로그:"
  cmd "$DOCKER logs --tail 50 $4"
  return 1
}

# ── compose 파일에서 서비스 한 덩어리만 잘라 낸다 (27번) ───────────────
# 🔴 파일 전체를 grep 하면 안 된다 — 주석 줄이 그대로 걸려서 꺼져 있는
#    서비스를 「가리킨다」고 세게 된다.
svc_block() { # 1 compose파일 2 서비스이름
  awk -v s="  $2:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$1" | sed '/^[[:space:]]*#/d'
}
svc_image() { svc_block "$1" "$2" | sed -n 's/^[[:space:]]*image:[[:space:]]*//p' | head -1; }
svc_env() { # 1 compose파일 2 서비스 3 키
  local v
  v=$(svc_block "$1" "$2" | sed -n "s/^[[:space:]]*$3:[[:space:]]*//p" | head -1)
  v=${v#\"}; v=${v%\"}
  v=${v#\'}; v=${v%\'}
  printf '%s' "$v"
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 compose 의 image 줄을 **글자로** 센다 — 정규식이 아니다
#
#  태그에는 점이 들어 있다(0.1 · 2.5). 정규식으로 보면 그 점이 아무 글자나
#  맞아 엉뚱한 줄을 센다. 들여쓰기만 떼고 **통째로 같은지** 본다.
#  🔴 주석 줄(# 으로 시작)은 자동으로 안 걸린다 — 「image: …」 로 시작하지 않는다.
# ══════════════════════════════════════════════════════════════════════
img_line_count() { # 1 파일 2 태그 → 「image: <태그>」 줄 수
  awk -v want="image: $2" '
    { t = $0; gsub(/^[ \t]+/, "", t); gsub(/[ \t\r]+$/, "", t)
      if (t == want) n++ }
    END { print n + 0 }
  ' "$1"
}
# ══════════════════════════════════════════════════════════════════════
#  🔴 **앱이 쓰는 길로 통로를 두드린다** — 컨테이너 안에서 node 의 fetch
#
#  🔴 호스트에서 curl 로 재면 DSM 프록시도 도커 망(dss-edge)도 안 지난다.
#     A/S 가 재고를 부르는 길은 **정확히 이 길**이다 — 컨테이너에서 나가
#     NAS 의 443 을 거쳐 돌아온다. 그래서 여기서 잰다(26번의 reach_code 를
#     토큰과 본문까지 보도록 늘린 것이다).
#
#  🔴 dss-as 의 runner 에는 **curl 이 없다**(그 Dockerfile 이 빌드 뒤 지운다).
#     node 는 있다. node 22 의 fetch 는 전역이라 따로 깔 것이 없다.
#
#  🔴 값은 **-e 로만** 넘긴다. 명령줄에 적으면 ps 와 로그에 남는다.
#  🔵 돌려주는 것: 「PROBE <상태코드> <count>」 또는 「PROBEFAIL <까닭>」.
#     count 는 본문이 JSON 이고 count 칸이 있을 때만 숫자이고, 아니면 -1 이다.
# ══════════════════════════════════════════════════════════════════════
API_PROBE_JS='
var u = process.env.U;
var t = process.env.T || "";
var m = process.env.M || "GET";
var h = { Accept: "application/json" };
if (t !== "") h.Authorization = "Bearer " + t;
var opt = { method: m, headers: h, redirect: "manual" };
if (m === "POST") { h["Content-Type"] = "application/json"; opt.body = "{}"; }
var timer = setTimeout(function () {
  console.log("PROBEFAIL timeout");
  process.exit(0);
}, 20000);
fetch(u, opt)
  .then(function (r) {
    return r.text().then(function (b) {
      clearTimeout(timer);
      var n = -1;
      try {
        var j = JSON.parse(b);
        if (j && typeof j.count === "number") n = j.count;
        else if (j && Array.isArray(j.requests)) n = j.requests.length;
        else if (j && Array.isArray(j.users)) n = j.users.length;
      } catch (e) { n = -1; }
      console.log("PROBE " + r.status + " " + n);
    });
  })
  .catch(function (e) {
    clearTimeout(timer);
    console.log("PROBEFAIL " + (e && e.name ? e.name : "unknown"));
  });
'
probe() { # 1 컨테이너 2 주소 3 토큰(빈값 가능) 4 메서드(빈값이면 GET)
          # → 「<코드> <count>」 또는 「FAIL:<까닭>」
  local out
  if ! running "$1"; then printf 'FAIL:not_running'; return 0; fi
  out=$("$DOCKER" exec -e U="$2" -e T="$3" -e M="${4:-GET}" \
        "$1" node -e "$API_PROBE_JS" 2>&1)
  if printf '%s\n' "$out" | grep -q '^PROBE '; then
    printf '%s' "$(printf '%s\n' "$out" | sed -n 's/^PROBE //p' | head -1)"
    return 0
  fi
  if printf '%s\n' "$out" | grep -q '^PROBEFAIL '; then
    printf 'FAIL:%s' "$(printf '%s\n' "$out" | sed -n 's/^PROBEFAIL //p' | head -1)"
    return 0
  fi
  printf 'FAIL:no_answer'
}
probe_code() { printf '%s' "${1%% *}"; }   # 「401 -1」 → 401
probe_n()    { printf '%s' "${1##* }"; }   # 「200 319」 → 319

# 🔴 「맞으면 되나」와 「틀리면 안 되나」를 **둘 다** 본다.
#    한 쪽만 보면 자격이 아예 안 걸린 상태를 통과시킨다.
judge_probe() { # 1 라벨 2 받은것 3 기대코드들(빈칸으로 나눔) 4 틀렸을때할말
  local label="$1" got="$2" wants="$3" why="$4" code w
  case "$got" in
    FAIL:*)
      bad "$label — 대답이 없다 (${got#FAIL:})"
      say "      🔴 컨테이너가 바깥으로 못 나가거나(dss-edge) 주소가 틀렸다."
      return 1 ;;
  esac
  code=$(probe_code "$got")
  for w in $wants; do
    if [ "$code" = "$w" ]; then
      ok "$label → $code"
      return 0
    fi
  done
  bad "$label → $code (기대 $wants)"
  say "      🔴 $why"
  case "$code" in
    503) say "      503 은 **토큰이 비었다**는 뜻이다 — 통로가 닫혀 있다." ;;
    404) say "      404 는 **그 통로가 없는 판**이라는 뜻이다(옛 이미지다)." ;;
    401) say "      401 은 **토큰이 틀렸다**는 뜻이다 — 양쪽 값이 다르다." ;;
  esac
  return 1
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 설정값 — **맞는가**로 잰다 (있는가가 아니다)
# ══════════════════════════════════════════════════════════════════════
V_AS_API_TOKEN=""; V_AS_LOOKUP_TOKEN=""
V_INV_RD_AS=""; V_INV_RD_INV=""
V_INV_WR_AS=""; V_INV_WR_INV=""
D_AS_API=""; D_AS_LOOKUP=""; D_RD_AS=""; D_RD_INV=""; D_WR_AS=""; D_WR_INV=""

env_one() { # 1 파일 2 라벨 3 키 → 줄이 하나고 값이 차 있으면 0
  local n v
  if ! env_has "$1" "$3"; then
    bad "$2 · $3 가 **없다**"
    return 1
  fi
  n=$(env_dups "$1" "$3")
  if [ "${n:-0}" != 1 ]; then
    bad "$2 · $3 줄이 ${n}개다 — 나중 것이 이긴다. 하나만 남기세요"
    return 1
  fi
  v=$(env_val "$1" "$3")
  if [ -z "$v" ]; then
    bad "$2 · $3 줄은 있는데 **값이 비었다**"
    return 1
  fi
  return 0
}
env_keys_present() { # 1 파일 2 라벨 3 "키 …" 4 없을때할말
  local f="$1" label="$2" keys="$3" why="$4" k n
  for k in $keys; do
    n=$(env_dups "$f" "$k")
    if [ "${n:-0}" = 0 ]; then
      bad "$label · $k 가 **없다** — 🔴 $why"
    elif [ "${n:-0}" -gt 1 ] 2>/dev/null; then
      bad "🔴 $label · $k 가 **두 줄 이상** 있다 — 먼저 그것부터 고쳐야 한다"
    else
      ok "$label · $k 있다"
    fi
  done
}

# 🔴 토큰 하나를 본다 — 길이와 지문만 남긴다. 값은 한 글자도 안 찍는다.
# 🔴 $( ) 로 부르지 않는다(바로 위 digest 의 그 까닭). 지문은 TOKEN_DG 에 담는다.
TOKEN_DG=""
token_look() { # 1 파일 2 라벨 3 키 → TOKEN_DG
  local v
  TOKEN_DG=""
  v=$(env_val "$1" "$3")
  if [ -z "$v" ]; then return 1; fi
  digest "$v"
  if [ "${#v}" -ge 32 ]; then
    ok "$2 · $3 — ${#v}자 · 지문 $DIGEST_OUT"
  else
    bad "$2 · $3 이 **32자보다 짧다**(${#v}자) — 앱이 시작할 때 던진다"
  fi
  v=
  TOKEN_DG=$DIGEST_OUT
  return 0
}

# 🔴 주소 하나를 본다. 값은 찍는다 — 비밀이 아니고 **사람이 눈으로 맞춰야**
#    하는 값이다(27번이 엑셀 경로를 그렇게 다뤘다).
judge_link_url() { # 1 라벨 2 키 3 값 4 반드시 시작해야 할 것 5 쓰임
  local label="$1" key="$2" raw="$3" want="$4" why="$5" host
  if [ -z "$raw" ]; then
    bad "$label · $key 가 **비었다** — $why"
    return 1
  fi
  host=${raw#*://}; host=${host%%/*}; host=${host%%:*}
  case "$raw" in
    http://*)
      bad "🔴 $label · $key 가 **http://** 다 — $raw"
      say "      사내 주소는 https 다. http 로 적으면 프록시가 안 받는다."
      return 1 ;;
  esac
  case "$host" in
    172.*|10.*|192.168.*)
      bad "🔴 $label · $key 가 **사설 IP** 다 ($host) — $why"
      say "      컨테이너 안에서 auto 로 잡은 주소가 들어간 것이다."
      return 1 ;;
    app-*|dss-*|localhost|127.0.0.1)
      bad "🔴 $label · $key 가 **컨테이너 안에서만 닿는 이름**이다 ($host)"
      say "      $why"
      return 1 ;;
  esac
  case "$raw" in
    "$want"*)
      ok "$label · $key = $raw" ;;
    *)
      bad "$label · $key 가 $want 로 시작하지 않는다 — $raw"
      return 1 ;;
  esac
  return 0
}

link_env_check() {
  local v n
  step "【검사 4-ㄱ】 as.env — 🔴 **새 넷** (값은 안 찍는다 · 지문만)"
  if [ ! -f "$AS_ENV" ]; then
    bad "as.env 가 없다: $AS_ENV"
    say "    → 🔴 **없는 env_file 하나면 docker compose 가 통째로 안 먹는다.**"
    return 1
  fi
  v=$(stat -c '%a' "$AS_ENV" 2>/dev/null)
  [ "$v" = 600 ] && ok "as.env · 모드 600" \
    || bad "as.env 의 모드가 ${v:-?} 다 (600 이어야 한다 — 남이 읽는다)"
  v=$(stat -c '%U:%G' "$AS_ENV" 2>/dev/null)
  [ "$v" = "root:root" ] && ok "as.env · 주인 root:root" \
    || bad "as.env 의 주인이 ${v:-?} 다"
  for v in $AS_FORBIDDEN; do
    env_has "$AS_ENV" "$v" \
      && bad "as.env 에 $v 가 **있다** — 지우세요(compose 가 넘긴다)"
  done
  say "  🔴 앞 배포들이 넣은 줄이 **그대로 있는가** (없으면 배포보다 그게 먼저다):"
  env_keys_present "$AS_ENV" as.env "$AS_QUOTE_KEYS"  "견적서 [폴더 열기]가 죽는다"
  env_keys_present "$AS_ENV" as.env "$AS_PORTAL_KEYS" "[공유폴더에 저장]이 실패로 끝난다"
  env_keys_present "$AS_ENV" as.env "$AS_CONTACT_KEYS" "연락서 [폴더 열기]가 죽는다"
  env_keys_present "$AS_ENV" as.env "$AS_REPAIR_KEYS"  "가리킨 서류 고르는 창이 죽는다"
  env_keys_present "$AS_ENV" as.env "$AS_PO_KEYS"      "발주서 탭이 죽는다"
  say
  say "  🔴 **이번 판에 새로 적어야 하는 넷** — 사람이 적는다(이 스크립트는 안 적는다):"
  for v in $AS_NEW_KEYS; do
    env_one "$AS_ENV" as.env "$v" || true
  done
  token_look "$AS_ENV" as.env AS_API_TOKEN;          D_AS_API=$TOKEN_DG
  token_look "$AS_ENV" as.env INVENTORY_API_TOKEN;   D_RD_AS=$TOKEN_DG
  token_look "$AS_ENV" as.env INVENTORY_WRITE_TOKEN; D_WR_AS=$TOKEN_DG
  judge_link_url as.env INVENTORY_API_BASE_URL \
    "$(env_val "$AS_ENV" INVENTORY_API_BASE_URL)" "$INV_BASE" \
    "이 값 하나가 **서버 호출**과 **A/S 재고 화면 안내 띠의 링크** 둘 다에 쓰인다" || true

  step "【검사 4-ㄴ】 inventory.env — 🔴 **새 넷** + 27번의 여덟이 그대로인가"
  if [ ! -f "$INV_ENV" ]; then
    bad "inventory.env 가 없다: $INV_ENV"
    return 1
  fi
  v=$(stat -c '%a' "$INV_ENV" 2>/dev/null)
  [ "$v" = 600 ] && ok "inventory.env · 모드 600" \
    || bad "inventory.env 의 모드가 ${v:-?} 다 (600 이어야 한다)"
  v=$(stat -c '%U:%G' "$INV_ENV" 2>/dev/null)
  [ "$v" = "root:root" ] && ok "inventory.env · 주인 root:root" \
    || bad "inventory.env 의 주인이 ${v:-?} 다"
  say "  🔴 27번이 넣은 여덟 — 하나라도 사라지면 앱이 **시작할 때 던진다**:"
  env_keys_present "$INV_ENV" inventory.env "$INV_BASE_KEYS" "앱이 시작할 때 던진다"
  for v in $INV_FORBIDDEN; do
    env_has "$INV_ENV" "$v" \
      && bad "inventory.env 에 $v 가 **있다** — 지우세요" \
      || ok "inventory.env 에 $v 가 없다 (맞다)"
  done
  say "  🔵 WORKBOOK_SYNC_DISABLED 가 위에 없는 것이 특히 중요하다 — 남아 있으면"
  say "     현황판 엑셀이 영영 안 만들어지는데 **화면은 멀쩡하다.**"
  say
  say "  🔴 **이번 판에 새로 적어야 하는 넷** + 이미 있던 읽기 토큰:"
  for v in $INV_LINK_KEYS; do
    env_one "$INV_ENV" inventory.env "$v" || true
  done
  token_look "$INV_ENV" inventory.env AS_LOOKUP_TOKEN;       D_AS_LOOKUP=$TOKEN_DG
  token_look "$INV_ENV" inventory.env INVENTORY_API_TOKEN;   D_RD_INV=$TOKEN_DG
  token_look "$INV_ENV" inventory.env INVENTORY_WRITE_TOKEN; D_WR_INV=$TOKEN_DG
  judge_link_url inventory.env AS_LOOKUP_URL \
    "$(env_val "$INV_ENV" AS_LOOKUP_URL)" "$AS_BASE" \
    "재고 쪽 인수번호 조회가 여기로 간다" || true
  judge_link_url inventory.env AS_API_BASE_URL \
    "$(env_val "$INV_ENV" AS_API_BASE_URL)" "$AS_BASE" \
    "결재자 명부와 제품 모델을 여기서 받아 온다" || true
  v=$(env_val "$INV_ENV" AS_API_BASE_URL)
  case "${v%/}" in
    */api/v1) ok "AS_API_BASE_URL 이 /api/v1 로 끝난다 (여기에 /users 를 붙인다)" ;;
    "")       : ;;
    *) bad "AS_API_BASE_URL 이 /api/v1 로 끝나지 않는다 — ${v}"
       say "      그 저장소가 이 값 뒤에 /users · /product-models 를 그대로 붙인다." ;;
  esac
  v=$(env_val "$INV_ENV" AS_LOOKUP_URL)
  case "$v" in
    *"{number}"*) ok "AS_LOOKUP_URL 에 {number} 자리표시자가 있다" ;;
    "")           : ;;
    *) say "    ⚠️ AS_LOOKUP_URL 에 {number} 가 없다 — 그러면 **끝에 붙인다.**"
       say "       끝이 /api/v1/intakes 로 끝나는지 눈으로 보세요: $v" ;;
  esac

  # ── 🔴 여기가 이 절의 핵심이다 — **짝과 다름** ──────────────────────
  step "【검사 4-ㄷ】 🔴 짝이 맞는가 · 읽기와 쓰기가 다른가 (지문으로만 본다)"
  say "  🔵 잰 방법: $DIGEST_ALG · 지문 앞 12자. **값은 한 글자도 안 나간다.**"
  pair_same() { # 1 라벨 2 지문A 3 지문B 4 틀렸을때할말
    if [ -z "$2" ] || [ -z "$3" ]; then
      bad "$1 — 한쪽이 비어 **견주지 못했다**"
      return 1
    fi
    if [ "$2" = "$3" ]; then
      ok "$1 — 양쪽이 **같은 값**이다 ($2)"
      return 0
    fi
    bad "🔴 $1 — 양쪽이 **다른 값**이다 (as $2 / inv $3)"
    say "      $4"
    return 1
  }
  pair_same "AS_API_TOKEN ↔ AS_LOOKUP_TOKEN" "$D_AS_API" "$D_AS_LOOKUP" \
    "재고가 A/S 의 명부·인수번호를 못 읽는다(401). 화면에는 「응답 없음」만 뜬다."
  pair_same "INVENTORY_API_TOKEN (읽기)" "$D_RD_AS" "$D_RD_INV" \
    "A/S 가 부품 목록·O/H 템플릿을 못 읽는다(401)."
  pair_same "INVENTORY_WRITE_TOKEN (쓰기)" "$D_WR_AS" "$D_WR_INV" \
    "🔴 화면은 읽히는데 **올리기만** 조용히 막힌다. 가장 늦게 들키는 고장이다."
  say
  if [ -n "$D_RD_AS" ] && [ -n "$D_WR_AS" ]; then
    if [ "$D_RD_AS" != "$D_WR_AS" ]; then
      ok "🔴 as.env 의 **읽기 ≠ 쓰기** ($D_RD_AS / $D_WR_AS)"
    else
      bad "🔴 as.env 의 읽기 토큰과 쓰기 토큰이 **같은 값**이다"
      say "      읽기 토큰은 여러 시스템이 나눠 쓰는 값이다. 그것 하나로 재고를"
      say "      **움직이는** 신청까지 만들 수 있으면 안 된다(env.ts 의 그 당부)."
      say "      🔴 프로그램은 이것을 막지 못한다 — 그래서 여기서 막는다."
    fi
  fi
  if [ -n "$D_RD_INV" ] && [ -n "$D_WR_INV" ]; then
    [ "$D_RD_INV" != "$D_WR_INV" ] \
      && ok "🔴 inventory.env 의 **읽기 ≠ 쓰기** ($D_RD_INV / $D_WR_INV)" \
      || bad "🔴 inventory.env 의 읽기 토큰과 쓰기 토큰이 **같은 값**이다"
  fi
  if [ -n "$D_AS_API" ] && [ -n "$D_RD_AS" ] && [ "$D_AS_API" = "$D_RD_AS" ]; then
    say "    ⚠️ A/S 를 읽는 토큰과 재고를 읽는 토큰이 **같은 값**이다."
    say "       막히지는 않지만 방향 둘의 자격이 하나가 된다 — 따로 만드는 편이 낫다."
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 설정 여덟을 **어떻게 적는가** — 틀만 찍는다. 값은 사람만 안다.
# ══════════════════════════════════════════════════════════════════════
env_template() {
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 설정 여덟은 **사람이** 적습니다. 이 스크립트는 안 적습니다.  ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "  🔴 이 PC(dss-deploy)의 nas/env/*.env 를 NAS 로 **올리지 마세요.**"
  say "     그 사본에는 NAS 에만 있는 줄들이 빠져 있습니다 — 올리면 그 기능이"
  say "     운영에서 통째로 사라집니다. **NAS 의 파일에 덧붙입니다.**"
  say
  say "  차례 — 긴 명령은 DSM 터미널이 잘라 먹으므로 **파일로** 만듭니다:"
  say "   1) 개발 PC 에서 메모장으로 28-env-add.sh 를 만들고 아래 틀을 붙여넣어"
  say "      <여기에값> 자리를 채웁니다. 🔴 **저장소 안에 두지 마세요.**"
  say "   2) (PowerShell) scp -O 로 올립니다:"
  cmd "scp -O 28-env-add.sh dss-nas:/volume1/dss/setup/incoming/"
  say "   3) (NAS · sudo -i 상태) 돌리고 **바로 지웁니다**:"
  cmd "sh /volume1/dss/setup/incoming/28-env-add.sh"
  cmd "rm -f /volume1/dss/setup/incoming/28-env-add.sh"
  say
  say "  ── 28-env-add.sh 의 틀 (여기부터) ─────────────────────────────"
  cat <<'TEMPLATE'
      #!/bin/sh
      # 🔴 값이 든 파일입니다. 돌린 뒤 바로 지우세요. 저장소에 두지 마세요.
      set -e
      A=/volume1/dss/deploy/env/as.env
      I=/volume1/dss/deploy/env/inventory.env
      cp -p "$A" /volume1/dss/backups/as.env.before28
      cp -p "$I" /volume1/dss/backups/inventory.env.before28
      chmod 600 /volume1/dss/backups/as.env.before28
      chmod 600 /volume1/dss/backups/inventory.env.before28

      # ── A/S (as.env) 넷 ──────────────────────────────────────────────
      # 🔴 값에 따옴표를 두르지 않습니다. 줄 끝까지가 그대로 값입니다.
      printf '\n# ── 재고 관리 이음새 (28-deploy) ──\n' >> "$A"
      printf 'AS_API_TOKEN=%s\n'           '<여기에값 재고가 A/S 를 읽는 토큰>' >> "$A"
      printf 'INVENTORY_API_BASE_URL=%s\n' 'https://inventory.dss21.co.kr'       >> "$A"
      printf 'INVENTORY_API_TOKEN=%s\n'    '<여기에값 읽기 토큰 32자 이상>'      >> "$A"
      printf 'INVENTORY_WRITE_TOKEN=%s\n'  '<여기에값 쓰기 토큰 32자 이상·읽기와 다른 값>' >> "$A"

      # ── 재고 관리 (inventory.env) **다섯** ────────────────────────────
      # 🔴 2026-10-16 --check 로 실측: INVENTORY_API_TOKEN 은 **줄 자체가 없다.**
      #    (앞 판이 넣었을 거라 짐작했었다 — 아니었다.) 그래서 **다섯 줄**이고,
      #    그 줄이 비어 있던 것이 지금 /api/v1/parts 가 **503** 인 까닭이다
      #    (env.ts: 「비어 있으면 API 가 503 으로 닫힌다」).
      printf '\n# ── A/S 이음새 (28-deploy) ──\n' >> "$I"
      printf 'AS_LOOKUP_URL=%s\n'   'https://as.dss21.co.kr/api/v1/intakes/{number}' >> "$I"
      printf 'AS_LOOKUP_TOKEN=%s\n' '<여기에값 as.env 의 AS_API_TOKEN 과 같은 값>'  >> "$I"
      printf 'AS_API_BASE_URL=%s\n' 'https://as.dss21.co.kr/api/v1'                 >> "$I"
      printf 'INVENTORY_API_TOKEN=%s\n'   '<여기에값 as.env 의 읽기 토큰과 같은 값>' >> "$I"
      printf 'INVENTORY_WRITE_TOKEN=%s\n' '<여기에값 as.env 의 쓰기 토큰과 같은 값>' >> "$I"

      chown root:root "$A" "$I"
      chmod 600 "$A" "$I"
      echo "끝났습니다. 이어서:  bash /volume1/dss/setup/28-deploy.sh"
TEMPLATE
  say "  ── 틀 끝 ───────────────────────────────────────────────────────"
  say "  🔴 토큰을 만드는 법(개발 PC · PowerShell 한 줄):"
  cmd "-join ((48..57)+(65..90)+(97..122)|Get-Random -Count 48|%{[char]\$_})"
  say "     🔴 **셋을 따로** 만드세요 — A/S 읽기용 · A/S 쓰기용 · 재고→A/S 용."
  say "  🔴 적은 뒤 반드시 다시 읽기만 돌려 짝이 맞는지 보세요:"
  cmd "bash $0"
}
# ══════════════════════════════════════════════════════════════════════
#  【검사 1】 이미지 **안**을 본다 — 태그만으로는 안심 못 한다
#
#  🔴 9/21~9/29 에 A/S 도구 이미지가 태그는 같은데 속이 빈 채로 여드레 돌았다.
#     휴가 도구 이미지는 scripts 가 빠져 있었다. **안을 세야 보인다.**
#
#  🔵 이번 판은 가르는 글자를 **파일 자리**로 잡았다 — 통로가 넷 새로 생기고
#     Next 의 standalone 이 그것을 폴더로 만들기 때문이다. 압축기가 글자를
#     바꿔도 **폴더 이름은 안 바뀐다.**
# ══════════════════════════════════════════════════════════════════════
inv_app_inside() {
  local out
  if ! have_img "$TAG_INV"; then
    notyet "$TAG_INV 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
    return 0
  fi
  say "  구운 때: $("$DOCKER" images "$TAG_INV" --format '{{.CreatedAt}}' 2>/dev/null)"
  say "  크기: $("$DOCKER" images "$TAG_INV" --format '{{.Size}}' 2>/dev/null)"
  out=$("$DOCKER" run --rm --entrypoint sh "$TAG_INV" -c '
    R=/app/.next/server/app/api/v1
    [ -f /app/server.js ]              && echo "SERVER 1"   || echo "SERVER 0"
    [ -d /app/.next/static ]           && echo "STATIC 1"   || echo "STATIC 0"
    [ -d "$R/parts" ]                  && echo "PARTS 1"    || echo "PARTS 0"
    [ -d "$R/oh-templates" ]           && echo "OHT 1"      || echo "OHT 0"
    [ -d "$R/stock-requests" ]         && echo "SREQ 1"     || echo "SREQ 0"
    [ -d "$R/stock-requests/cancel" ]  && echo "SCAN 1"     || echo "SCAN 0"
    grep -rlF -- INVENTORY_WRITE_TOKEN /app/.next/server >/dev/null 2>&1 \
      && echo "WRTOK 1" || echo "WRTOK 0"
    grep -rlF -- AS_API_BASE_URL /app/.next/server >/dev/null 2>&1 \
      && echo "ASBASE 1" || echo "ASBASE 0"
    echo "PORT $(printenv PORT)"
    echo "WHO $(id -u):$(id -g)"' 2>&1)
  printf '%s\n' "$out" | grep -E '^[A-Z]+ ' | sed 's/^/      /'
  see1() { # 1 표시 2 읽을 말 3 없을 때 할 말
    printf '%s\n' "$out" | grep -qx "$1 1" && ok "$2" \
      || { bad "$2 — **없다**"; say "    → $3"; }
  }
  see1 SERVER "server.js 가 있다 (standalone 빌드)" \
    "도구를 앱으로 구웠다. 다시 구우세요."
  see1 STATIC ".next/static 이 있다" "화면이 글자만 나온다."
  see1 PARTS  "🔵 /api/v1/parts 가 있다 (0.1 에도 있던 것 — 회귀 확인)" \
    "🔴 0.1 보다 **옛 판**을 올린 것이다."
  see1 OHT    "🔴 /api/v1/oh-templates 가 있다 (0.2 에서 새로 생긴 통로)" \
    "🔴 이것은 $OLD_INV 다. A/S 의 O/H 템플릿 불러오기가 안 된다."
  see1 SREQ   "🔴 /api/v1/stock-requests 가 있다 (부품 요청의 문)" \
    "🔴 이것은 $OLD_INV 다. A/S 의 부품 요청 칸이 통째로 안 된다."
  see1 SCAN   "🔴 /api/v1/stock-requests/cancel 이 있다 (거두기)" \
    "🔴 이것은 $OLD_INV 다."
  see1 WRTOK  "🔴 INVENTORY_WRITE_TOKEN 을 읽는 코드가 들어 있다" \
    "🔴 쓰기 토큰을 모르는 판이다 — $OLD_INV 다."
  see1 ASBASE "AS_API_BASE_URL 을 읽는 코드가 들어 있다 (결재자 명부)" \
    "🔴 A/S 명부를 못 읽는 판이다."
  printf '%s\n' "$out" | grep -qx "PORT 3800" \
    && ok "이미지가 PORT=3800 을 들고 있다" \
    || bad "이미지의 PORT 가 3800 이 아니다"
  # 🔴 compose 가 user: 1001:100 으로 덮어쓰지만, 이미지 자체의 번호도 본다.
  printf '%s\n' "$out" | grep -q '^WHO 1001:' \
    && ok "이미지가 uid 1001 로 돈다 (데이터 폴더 주인과 같다)" \
    || { bad "🔴 이미지의 uid 가 1001 이 아니다 — 데이터 폴더를 못 쓴다"
         printf '%s\n' "$out" | grep '^WHO ' | sed 's/^/      /'; }
}

inv_tools_inside() {
  local out n_sql n_j t
  if ! have_img "$TAG_INVTOOLS"; then
    notyet "$TAG_INVTOOLS 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
    return 0
  fi
  say "  구운 때: $("$DOCKER" images "$TAG_INVTOOLS" --format '{{.CreatedAt}}' 2>/dev/null)"
  say "  🔴 재고 관리의 마이그레이션은 **이미지 안**이다(A/S 와 다르다)."
  say "     그래서 도구 이미지를 다시 굽지 않으면 11건이 아예 안 들어간다."
  out=$("$DOCKER" run --rm --entrypoint sh "$TAG_INVTOOLS" \
        -c 'ls -1 /app/drizzle/*.sql 2>/dev/null' 2>&1)
  n_sql=$(printf '%s\n' "$out" | grep -c '\.sql$')
  if [ "$n_sql" = "$INV_MIG_WANT" ]; then
    ok "도구 이미지 안의 마이그레이션 .sql 이 ${n_sql}개다"
  else
    bad "도구 이미지 안의 .sql 이 ${INV_MIG_WANT}개가 아니다 (${n_sql}개)"
    say "    → ${INV_MIG_HAVE}개면 **옛 도구(:1)**를 올린 것이다. 다시 구우세요."
    say "    → 더 많으면 이 스크립트가 모르는 판이다. 고치지 말고 알리세요."
  fi
  for t in $INV_MIG_TAGS; do
    printf '%s\n' "$out" | grep -q "/$t\.sql$" \
      && ok "$t.sql 있다" || bad "$t.sql 이 **없다** — 다른 판이다"
  done
  out=$("$DOCKER" run --rm --entrypoint sh "$TAG_INVTOOLS" \
        -c 'cat /app/drizzle/meta/_journal.json 2>/dev/null' 2>&1)
  n_j=$(printf '%s\n' "$out" | grep -c '"tag"')
  [ "$n_j" = "$INV_MIG_WANT" ] && ok "_journal.json 의 tag 가 ${n_j}줄이다" \
    || bad "_journal.json 의 tag 가 ${INV_MIG_WANT}줄이 아니다 (${n_j}줄)"
  say "  🔴 _journal.json 이 옛것이면 drizzle 은 새 .sql 을 **아예 모른다** —"
  say "     적용이 조용히 0건으로 끝나고, 그 다음에 뜬 0.2 가 없는 표를 읽다 죽는다."
  # 🔴 도구가 **제 일을 할 수 있는가** — 27번의 그 목록 그대로
  out=$("$DOCKER" run --rm --entrypoint sh "$TAG_INVTOOLS" -c '
    [ -f /app/scripts/migrate.ts ]   && echo "MIGRATE 1"   || echo "MIGRATE 0"
    [ -f /app/tsconfig.json ]        && echo "TSCONFIG 1"  || echo "TSCONFIG 0"
    [ -f /app/drizzle.config.ts ]    && echo "DRIZZLECFG 1"|| echo "DRIZZLECFG 0"
    [ -f /app/src/lib/env.ts ]       && echo "ENVTS 1"     || echo "ENVTS 0"
    [ -d /app/src/lib/excel ]        && echo "EXCELDIR 1"  || echo "EXCELDIR 0"
    [ -d /app/src/lib/legacy ]       && echo "LEGACYDIR 1" || echo "LEGACYDIR 0"
    [ -x /app/node_modules/.bin/tsx ]&& echo "TSX 1"       || echo "TSX 0"' 2>&1)
  printf '%s\n' "$out" | grep -E '^[A-Z]+ [01]$' | sed 's/^/      /'
  see2() {
    printf '%s\n' "$out" | grep -qx "$1 1" && ok "$2" \
      || { bad "$2 — **없다**"; say "    → $3"; }
  }
  see2 MIGRATE    "scripts/migrate.ts 가 있다" "🔴 --migrate 가 「없는 파일」로 끝난다."
  see2 TSX        "node_modules/.bin/tsx 가 있다" "운영 이미지를 도구로 구웠나."
  see2 TSCONFIG   "tsconfig.json 이 있다 (@/… 경로를 푸는 곳)" "migrate 만 돌고 나머지가 죽는다."
  see2 DRIZZLECFG "drizzle.config.ts 가 있다" "drizzle-kit 이 스키마 자리를 못 찾는다."
  see2 ENVTS      "src/lib/env.ts 가 있다" "도구가 돌다 죽는다."
  see2 EXCELDIR   "src/lib/excel 가 있다" "전환일 도구가 모듈을 못 찾는다."
  see2 LEGACYDIR  "src/lib/legacy 가 있다" "전환일 도구가 모듈을 못 찾는다."
}

as_app_inside() {
  local out
  if ! have_img "$TAG_AS"; then
    notyet "$TAG_AS 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
    return 0
  fi
  say "  구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
  say "  크기: $("$DOCKER" images "$TAG_AS" --format '{{.Size}}' 2>/dev/null)"
  say "        ($OLD_AS 는 약 590MB 였다 — 🔴 **크기로는 못 가른다.**)"
  out=$("$DOCKER" run --rm --entrypoint sh "$TAG_AS" -c '
    R=/app/.next/server/app/api/v1
    [ -f /app/server.js ]       && echo "SERVER 1" || echo "SERVER 0"
    [ -d /app/.next/static ]    && echo "STATIC 1" || echo "STATIC 0"
    [ -d "$R/users" ]           && echo "USERS 1"  || echo "USERS 0"
    [ -d "$R/intakes" ]         && echo "INTAKE 1" || echo "INTAKE 0"
    [ -d "$R/product-models" ]  && echo "MODELS 1" || echo "MODELS 0"
    [ -d /app/public/ocr ]      && echo "OCR 1"    || echo "OCR 0"
    grep -rlF -- INVENTORY_WRITE_TOKEN /app/.next/server >/dev/null 2>&1 \
      && echo "WRTOK 1" || echo "WRTOK 0"
    grep -rlF -- INVENTORY_API_BASE_URL /app/.next/server >/dev/null 2>&1 \
      && echo "INVBASE 1" || echo "INVBASE 0"
    grep -rlF -- QUOTE_ARCHIVE_UNC_ROOT /app/.next/server >/dev/null 2>&1 \
      && echo "CTRL 1" || echo "CTRL 0"
    echo "PORT $(printenv PORT)"
    echo "WHO $(id -u):$(id -g)"' 2>&1)
  printf '%s\n' "$out" | grep -E '^[A-Z]+ ' | sed 's/^/      /'
  # 🔴 대조 표시가 안 나오면 **판정하지 않는다** — 글자를 못 읽은 것과 옛 판인
  #    것을 가를 수 없기 때문이다(19번의 그 규율).
  if ! printf '%s\n' "$out" | grep -qx "CTRL 1"; then
    say "    ⚠️ 이미지 안을 글자로 뒤지지 못했다 — 대조 표시도 안 나왔다."
    say "       **판정하지 않는다.** 이때는 사람이 직접 화면에서 봐야 한다."
    return 0
  fi
  ok "대조 표시(QUOTE_ARCHIVE_UNC_ROOT)를 찾았다 — 안을 실제로 읽었다"
  see3() {
    printf '%s\n' "$out" | grep -qx "$1 1" && ok "$2" \
      || { bad "$2 — **없다**"; say "    → $3"; }
  }
  see3 SERVER  "server.js 가 있다 (standalone 빌드)" "도구를 앱으로 구웠다."
  see3 STATIC  ".next/static 이 있다" "화면이 글자만 나온다."
  see3 USERS   "🔴 /api/v1/users 가 있다 (2.6 에서 **처음** 생기는 통로)" \
    "🔴 이것은 $OLD_AS 다. 재고의 결재자 고르개가 빈 채로 돈다."
  see3 INTAKE  "🔴 /api/v1/intakes/{number} 가 있다 (인수번호 조회)" \
    "🔴 이것은 $OLD_AS 다."
  see3 MODELS  "🔴 /api/v1/product-models 가 있다" "🔴 이것은 $OLD_AS 다."
  see3 WRTOK   "🔴 INVENTORY_WRITE_TOKEN 을 읽는 코드가 들어 있다" \
    "🔴 쓰기 토큰을 모르는 판이다 — 부품 요청을 못 올린다."
  see3 INVBASE "🔴 INVENTORY_API_BASE_URL 을 읽는 코드가 들어 있다" \
    "🔴 재고를 부를 주소를 모르는 판이다."
  see3 OCR     "🔵 회귀 — public/ocr 이 그대로 있다 (2.5 에서 오던 것)" \
    "🔴 명판 읽기가 죽는다. Next 의 standalone 은 public 을 자동으로 안 담는다."
  printf '%s\n' "$out" | grep -qx "PORT 3000" \
    && ok "이미지가 PORT=3000 을 들고 있다" \
    || say "    ⚠️ 이미지의 PORT 가 3000 이 아니다 — compose 가 넘기는지 보세요."
}

# ══════════════════════════════════════════════════════════════════════
#  【검사 2】 A/S 마이그레이션 **파일** (115 → 116)
#
#  🔴 A/S 의 drizzle/ 은 이미지 안이 아니라 **볼륨**이다:
#       /volume1/dss/as-migrations → tools-as 의 /app/drizzle (읽기 전용)
#     그래서 .sql 한 장만이 아니라 **meta/_journal.json 과 0115_snapshot.json
#     까지** 함께 가야 한다. _journal.json 이 옛것이면 drizzle 은 새 .sql 을
#     아예 모른다 — 조용히 0건 적용으로 끝나고, 그 뒤에 뜬 2.6 이 없는 칸을
#     읽다 죽는다. 그래서 폴더를 **통째로** 갈아 끼운다.
# ══════════════════════════════════════════════════════════════════════
MIG_PLACED=0
as_mig_files() {
  local n_sql n_j f miss t n m
  if [ -s "$MIGTAR" ]; then
    n=$(stat -c '%s' "$MIGTAR" 2>/dev/null)
    m=$(md5sum "$MIGTAR" 2>/dev/null | awk '{print $1}')
    say "  · incoming 의 묶음: 바이트 ${n:-?} · md5 ${m:-?}"
    say "    🔵 기대값(SZ_MIG · MD5_MIG)은 비워 두었다 — 다시 묶으면 gzip 도장"
    say "       때문에 달라진다. 🔴 **진짜 판정은 푼 뒤의 개수**다."
  else
    say "  · incoming 에 묶음이 없다: $MIGTAR"
    say "    (폴더가 **이미 $AS_MIG_WANT** 이면 올릴 필요가 없다 — 아래에서 센다)"
  fi
  if [ ! -d "$MIGDIR" ]; then
    bad "$MIGDIR 폴더가 없다 — compose 가 tools-as 에 붙이는 그 폴더다"
    return 1
  fi
  n_sql=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  n_j=0
  [ -f "$MIGDIR/meta/_journal.json" ] \
    && n_j=$(grep -c '"tag"' "$MIGDIR/meta/_journal.json" 2>/dev/null | tr -d ' ')
  say "  · 지금 폴더: .sql ${n_sql}개 · _journal.json 의 tag ${n_j}줄"
  if [ "$n_sql" = "$AS_MIG_WANT" ] && [ "$n_j" = "$AS_MIG_WANT" ]; then
    MIG_PLACED=1
    ok "새 마이그레이션 파일이 **이미 놓여 있다** ($AS_MIG_WANT)"
  elif [ "$n_sql" = "$AS_MIG_HAVE" ] && [ "$n_j" = "$AS_MIG_HAVE" ]; then
    if [ -s "$MIGTAR" ]; then
      ok "아직 $AS_MIG_HAVE 이다 — **--migrate 가 묶음으로 갈아 끼운다**"
    else
      notyet "아직 $AS_MIG_HAVE 인데 **갈아 끼울 묶음이 없다**: $MIGTAR"
      say "    → 개발 PC(PowerShell)에서 올리세요 — 🔴 **이름이 바뀝니다**:"
      say "      scp -O as-migrations-2.6.tar.gz \\"
      say "        dss-nas:/volume1/dss/setup/incoming/as-migrations.tar.gz"
      say "    🔴 .sql 한 장만 넣지 마세요 — meta/_journal.json 이 빠지면"
      say "       적용이 **조용히 0건**으로 끝납니다."
    fi
  else
    bad "폴더가 $AS_MIG_HAVE 도 $AS_MIG_WANT 도 아니다 (.sql ${n_sql} · tag ${n_j})"
    say "    → 🔴 **남의 손이 닿았거나 반쯤 올라간 것**이다. 고치지 말고 알리세요."
  fi
  if [ "$MIG_PLACED" = 1 ]; then
    miss=""
    for t in $AS_NEW_MIGS; do
      ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || miss="$miss $t(sql)"
      [ -f "$MIGDIR/meta/${t}_snapshot.json" ] || miss="$miss $t(snapshot)"
    done
    [ -z "$miss" ] && ok "$AS_NEW_MIGS 의 .sql 과 meta/*_snapshot.json 이 다 있다" \
      || bad "빠진 것이 있다:$miss"
    f=$(ls -1 "$MIGDIR/0115_"*.sql 2>/dev/null | head -1)
    if [ -n "$f" ]; then
      grep -qF "$AS_MIG_MARK" "$f" \
        && ok "0115 안에 $AS_MIG_MARK 가 있다 ($(basename "$f"))" \
        || bad "0115 안에 그 글자가 **없다** — 🔴 다른 파일이다"
      destructive_scan "$f" "A/S 0115" "$AS_DROP_WANT"
    fi
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 「지우는 문장」을 센다 — 앱의 판정기와 **같은 잣대**로
#
#  🔴 「DELETE」 만으로 세지 않는다. 외래키의 ON DELETE cascade · restrict 가
#     이번 판에도 여러 번 나온다 — 그 잣대를 쓰면 표만 더하는 판이 ✗ 가 된다.
#     그래서 DROP TABLE · DROP COLUMN · TRUNCATE · DELETE FROM 으로만 센다
#     (migration-safety.ts 가 쓰는 것과 같다).
# ══════════════════════════════════════════════════════════════════════
destructive_scan() { # 1 파일 2 라벨 3 기대 개수
  local f="$1" label="$2" want="$3" n r
  n=$(grep -ciE "$DESTRUCTIVE_RE" "$f" 2>/dev/null)
  n=${n:-0}
  r=$(grep -ciE "$RISKY_RE" "$f" 2>/dev/null)
  r=${r:-0}
  if [ "$n" = "$want" ]; then
    if [ "$n" = 0 ]; then
      ok "$label — 지우는 문장이 **없다** (DROP · TRUNCATE · DELETE FROM 0줄)"
    else
      ok "$label — 지우는 문장이 **${n}줄**이다 (기대한 그대로)"
      grep -niE "$DESTRUCTIVE_RE" "$f" | sed 's/^/        /' | head -6
    fi
  else
    bad "🔴 $label — 지우는 문장이 ${n}줄이다 (기대 ${want}줄)"
    grep -niE "$DESTRUCTIVE_RE" "$f" | sed 's/^/        /' | head -10
    say "    → 🔴 이 스크립트가 모르는 문장이다. 고치지 말고 **먼저 알리세요.**"
  fi
  if [ "${r:-0}" -gt 0 ] 2>/dev/null; then
    say "    ⚠️ $label — 「살펴볼 것」이 ${r}줄 있다(DROP INDEX · RENAME ·"
    say "       SET NOT NULL). **자료를 지우지는 않는다** — 종료 코드도 안 건드린다."
    grep -niE "$RISKY_RE" "$f" | sed 's/^/        /' | head -4
  fi
  return 0
}

# 🔴 재고 쪽은 .sql 이 **이미지 안**에 있다 — 꺼내서 센다.
inv_destructive_scan() {
  local out n r
  if ! have_img "$TAG_INVTOOLS"; then
    notyet "$TAG_INVTOOLS 가 없어 **지우는 문장을 못 셌다**"
    return 0
  fi
  say "  🔴 재고 쪽 .sql 은 **도구 이미지 안**이다. 거기서 꺼내 센다."
  say "     잣대: DROP TABLE · DROP COLUMN · TRUNCATE · DELETE FROM"
  say "     (앱의 migration-safety.ts 와 **같은 잣대**. ON DELETE 는 안 센다.)"
  out=$("$DOCKER" run --rm -e RE="$DESTRUCTIVE_RE" -e MIGS="$INV_NEW_MIGS" \
        --entrypoint sh "$TAG_INVTOOLS" -c '
    for t in $MIGS; do
      for f in /app/drizzle/${t}_*.sql; do
        [ -f "$f" ] || continue
        grep -niE "$RE" "$f" | sed "s#^#$(basename "$f"):#"
      done
    done' 2>&1 | grep -v '^$')
  n=$(printf '%s\n' "$out" | grep -c ':' )
  [ -n "$out" ] || n=0
  if [ "$n" = "$INV_DROP_WANT" ]; then
    ok "재고 0009~0019 — 지우는 문장이 **${n}줄**이다 (기대한 그대로)"
  else
    bad "🔴 재고 0009~0019 — 지우는 문장이 ${n}줄이다 (기대 ${INV_DROP_WANT}줄)"
    say "    → 🔴 이 스크립트가 모르는 문장이다. 고치지 말고 **먼저 알리세요.**"
  fi
  printf '%s\n' "$out" | sed 's/^/        /' | head -8
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 **되돌릴 수 없는 문장이 셋 있습니다.** 숨기지 않습니다.      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     0012 : oh_part_template_items DROP COLUMN oh_price"
  say "     0012 : oh_part_templates      DROP COLUMN sort_order"
  say "     0014 : oh_part_templates      DROP COLUMN code"
  say
  say "  🔵 **그래도 운영 자료는 한 줄도 안 사라집니다.** 그 두 표가 같은"
  say "     묶음 안의 **0011 에서 태어나기** 때문입니다 — 운영 DB 는 지금"
  say "     0008 까지라 그 표가 아예 없습니다. 0011 이 만들고, 0012 · 0014 가"
  say "     그 자리에서 칸을 다듬습니다. 지울 자료가 생길 틈이 없습니다."
  say "  🔴 --migrate 는 적용 **전에** 그 두 표가 운영 DB 에 정말 없는지"
  say "     셉니다. 있으면 전제가 깨진 것이라 **멈춥니다.**"
  say "  🔴 그래도 되돌릴 수 없는 문장인 것은 맞으므로, --migrate 는"
  say "     **--drop-column-ok 를 함께 주지 않으면 시작하지 않습니다.**"
}

# ══════════════════════════════════════════════════════════════════════
#  【검사 3】 권한 — 🔴 **코드가 아니라 운영 DB 가 정한다**
#
#  🔴 inventory.requests 가 A/S 새 통로의 **문**이다. 저장된 값이 코드의
#     기본값을 이긴다 — 거기가 NONE 이면 부품 요청이 통째로 안 된다.
#  🔴 **select 만 쓴다.** 이 스크립트는 권한을 고치지 않는다.
# ══════════════════════════════════════════════════════════════════════
perm_check() {
  local reg n_all n_gate
  if ! pg_up; then
    say "  · dss-pg-app 이 떠 있지 않다 — 권한을 못 봤다(✗ 는 아니다)"
    return 0
  fi
  reg=$(qas "select to_regclass('public.$PERM_TABLE')")
  if [ -z "$reg" ]; then
    say "  · $AS_DB 에 $PERM_TABLE 표가 없다 — 🔴 첫 설치가 덜 된 DB 다"
    return 0
  fi
  ok "$AS_DB 에 $PERM_TABLE 표가 있다"
  say "  🔴 이 검사가 돌리는 SQL 은 아래 둘이 전부다. 둘 다 select 다:"
  say "      $PERM_SQL_COUNT"
  say "      $PERM_SQL_AREA"
  n_all=$(qas "$PERM_SQL_COUNT")
  n_gate=$(qas "select count(*) from $PERM_TABLE where area_key = '$PERM_GATE'")
  say
  say "  · inventory% 로 저장된 줄: ${n_all:-?}"
  say "  · $PERM_GATE 에 저장된 줄: ${n_gate:-?}"
  say
  say "  저장된 값 — 역할 전부:"
  qqas "$PERM_SQL_AREA" | sed 's/^/      /'
  say
  if [ "${n_all:-0}" = 0 ]; then
    say "  🔵 **저장된 줄이 하나도 없습니다.** 그러면 코드의 기본값이 그대로"
    say "     삽니다 — $PERM_GATE 는 엔지니어까지 WRITE 입니다"
    say "     (permission-baseline.ts 의 canCreatePartRequest)."
  else
    say "  ╔══════════════════════════════════════════════════════════════╗"
    say "  ║ 🔴 저장된 줄이 있습니다. **저장된 값이 기본값을 이깁니다.**     ║"
    say "  ╚══════════════════════════════════════════════════════════════╝"
    say "     · $PERM_GATE 가 NONE 인 역할은 **부품 요청 칸 자체가 막힙니다.**"
    say "       그 사람에게는 A/S 가 재고를 부르지도 않습니다 — 통로가 멀쩡해도"
    say "       화면에서 길이 없습니다."
    say "     · inventory.view 가 NONE 이면 재고 화면 자체가 안 열립니다."
    say "  🔴 위 표를 **배포 전에 사람이 보고** 「실제로 달라지는 칸」을 정하세요."
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  【검사 5】 재고 관리가 **공유폴더에 쓸 수 있는가** — gid 100 이 그대로인가
#
#  🔴 27번이 데인 자리다. 그 공유폴더의 시놀로지 ACL 은 **이름 기반**이라
#     NAS 에 없는 번호인 gid 1001 은 어디에도 안 걸린다. users 그룹이 100 이다.
#  🔴 이번 판은 compose 의 user: 줄을 **건드리지 않는다.** 그래도 컨테이너를
#     다시 만들기 때문에 「그대로 유지되는가」를 본다 — 빠지면 현황판 엑셀이
#     공유폴더에 안 생기는데 **화면은 멀쩡하다.**
# ══════════════════════════════════════════════════════════════════════
share_check() { # 1 compose파일
  local v own mode
  v=$(svc_env "$1" "$INV_SVC" user)
  [ "$v" = "$UID_APP:$GID_APP" ] \
    && ok "🔴 compose 의 $INV_SVC 가 user: \"$UID_APP:$GID_APP\" 그대로다" \
    || bad "🔴 $INV_SVC 의 user 가 $UID_APP:$GID_APP 이 아니다 (${v:-없음}) — 공유폴더에 못 쓴다"
  v=$(svc_env "$1" "$INV_TOOLS_SVC" user)
  [ "$v" = "$UID_APP:$GID_APP" ] \
    && ok "compose 의 $INV_TOOLS_SVC 도 user: \"$UID_APP:$GID_APP\" 그대로다" \
    || say "    ⚠️ $INV_TOOLS_SVC 의 user 가 ${v:-없음} 이다 — /data 에 쓰는 명령에서만 문제가 된다"
  # 🔴 grep -qF 다 — 이 경로에는 점이 넷 들어 있어 정규식으로 읽으면 아무 글자나 맞는다.
  svc_block "$1" "$INV_SVC" | grep -qF "$INV_SHARE_WB:/data/workbook" \
    && ok "$INV_SVC 에 공유폴더 → /data/workbook 볼륨이 그대로 있다" \
    || bad "🔴 $INV_SVC 에 공유폴더 볼륨이 없다 — 현황판이 직원에게 안 보이는데 화면은 멀쩡하다"
  svc_block "$1" "$INV_SVC" | grep -qF "$INV_DATA:/data" \
    && ok "$INV_SVC 에 $INV_DATA:/data 볼륨이 그대로 있다" \
    || bad "🔴 $INV_SVC 에 데이터 볼륨이 없다 — 만든 엑셀이 컨테이너와 함께 사라진다"
  if [ -d "$INV_SHARE_WB" ]; then
    own=$(stat -c '%u:%g' "$INV_SHARE_WB" 2>/dev/null)
    mode=$(stat -c '%a' "$INV_SHARE_WB" 2>/dev/null)
    # 🔴 주인만 보고 모드를 안 봐서 000 인 파일을 못 읽은 적이 있다 — **둘 다** 본다.
    say "  · 공유폴더 주인 ${own:-?} · 모드 ${mode:-?} (🔴 둘 다 본다)"
    # 🔴 2026-10-16 실측: `stat -c %a` 는 000 을 **`0`** 으로 돌려준다. `000)` 만
    #    보던 앞 판은 **모드 000 을 통과로 읽었다**(✓ 가 뜬다 — 가장 나쁜 방향).
    #    🔵 다만 이 폴더는 시놀로지 **ACL 자리**라 0 으로 보이는 것이 정상이고,
    #    실제로 엑셀이 만들어져 백업에도 담긴다. 그래서 막지 않고 **보이게만** 한다 —
    #    진짜 판정은 --go 의 **쓰기 시험**이다(ACL 은 모드로 안 보인다).
    case "${mode:-000}" in
      0|000) notyet "모드가 ${mode} 다 — ACL 자리라면 정상이다. 🔴 진짜 판정은 --go 의 쓰기 시험" ;;
      *)     ok "모드가 000 이 아니다 (${mode})" ;;
    esac
  else
    bad "공유폴더가 없다: $INV_SHARE_WB"
  fi
}
# ══════════════════════════════════════════════════════════════════════
#  🔴 compose 의 태그 **세 줄**을 고친다 — 사본을 뜨고, 세어 보고, 틀리면 되돌린다
#
#  🔴 저장소의 compose 를 올리지 않는 까닭은 머리말 ⑤절에 있다.
#     (저장소 사본은 재고 관리 두 블록이 아직 주석이다 — 올리면 사라진다.)
# ══════════════════════════════════════════════════════════════════════
compose_swapped() {   # 이미 새 태그로 바뀌어 있는가
  [ "$(img_line_count "$CF" "$TAG_INV")" = 1 ] \
    && [ "$(img_line_count "$CF" "$TAG_INVTOOLS")" = 1 ] \
    && [ "$(img_line_count "$CF" "$TAG_AS")" = 1 ]
}

swap_tags() {
  local nb na tmp bk rec oldt newt
  bk="$BKD/docker-compose.nas.yml.$STAMP"
  tmp="$CF.28new"
  mkdir -p "$BKD"
  cp -p "$CF" "$bk" || { bad "compose 사본을 못 떴다"; return 1; }
  chmod 644 "$bk"
  ok "compose 사본 — backups/docker-compose.nas.yml.$STAMP"
  nb=$(wc -l < "$CF")
  # ① 바꾸기 전 — 옛 태그가 **정확히 한 줄씩** 있어야 한다
  for rec in "$OLD_INV|$TAG_INV" "$OLD_INVTOOLS|$TAG_INVTOOLS" "$OLD_AS|$TAG_AS"; do
    oldt=${rec%%|*}; newt=${rec##*|}
    if [ "$(img_line_count "$CF" "$oldt")" != 1 ]; then
      bad "🔴 compose 에 「image: $oldt」 줄이 하나가 아니다"
      say "    → 남의 변경이 섞였거나 이미 바뀐 뒤다. 고치지 말고 알리세요."
      rm -f "$tmp"
      return 1
    fi
    if [ "$(img_line_count "$CF" "$newt")" != 0 ]; then
      bad "🔴 compose 에 「image: $newt」 줄이 **이미 있다**"
      rm -f "$tmp"
      return 1
    fi
  done
  # ② 글자로 바꾼다 — 정규식이 아니다. 들여쓰기는 그대로 둔다.
  awk -v oi="image: $OLD_INV"       -v ni="image: $TAG_INV" \
      -v ot="image: $OLD_INVTOOLS"  -v nt="image: $TAG_INVTOOLS" \
      -v oa="image: $OLD_AS"        -v na="image: $TAG_AS" '
    { line = $0
      t = line; gsub(/^[ \t]+/, "", t); gsub(/[ \t\r]+$/, "", t)
      ind = substr(line, 1, length(line) - length(t))
      if (t == oi)      { print ind ni; next }
      if (t == ot)      { print ind nt; next }
      if (t == oa)      { print ind na; next }
      print line
    }' "$CF" > "$tmp" || { bad "compose 를 못 썼다"; rm -f "$tmp"; return 1; }
  # ③ 줄 수가 그대로인가 — 한 줄이라도 달라지면 되돌린다
  na=$(wc -l < "$tmp")
  if [ "$nb" != "$na" ]; then
    bad "🔴 줄 수가 달라졌다 (전 $nb · 후 $na) — **바꾸지 않고 되돌린다**"
    rm -f "$tmp"
    return 1
  fi
  ok "줄 수가 그대로다 ($nb줄)"
  cp -p "$tmp" "$CF" && rm -f "$tmp"
  chown root:root "$CF"; chmod 644 "$CF"
  # ④ 바꾼 뒤 — 새 태그 1줄 · 옛 태그 0줄
  for rec in "$OLD_INV|$TAG_INV" "$OLD_INVTOOLS|$TAG_INVTOOLS" "$OLD_AS|$TAG_AS"; do
    oldt=${rec%%|*}; newt=${rec##*|}
    if [ "$(img_line_count "$CF" "$newt")" = 1 ] \
       && [ "$(img_line_count "$CF" "$oldt")" = 0 ]; then
      ok "$oldt → $newt"
    else
      bad "🔴 $newt 로 안 바뀌었다 — **사본으로 되돌린다**"
      cp -p "$bk" "$CF"; chown root:root "$CF"; chmod 644 "$CF"
      return 1
    fi
  done
  # ⑤ 건드리지 않는 열하나가 그대로인가
  for oldt in $KEEP_TAGS; do
    [ "$(img_line_count "$CF" "$oldt")" -ge 1 ] 2>/dev/null \
      || { bad "🔴 $oldt 가 compose 에서 사라졌다 — **되돌린다**"
           cp -p "$bk" "$CF"; chown root:root "$CF"; chmod 644 "$CF"
           return 1; }
  done
  ok "건드리지 않는 열하나가 compose 에 그대로다"
  # ⑥ 문법
  if compose_at "$CF" config --quiet >/dev/null 2>&1; then
    ok "바꾼 compose 의 문법이 통과했다"
  else
    bad "🔴 바꾼 compose 에 문법 오류가 있다 — **사본으로 되돌린다**"
    compose_at "$CF" config --quiet 2>&1 | sed 's/^/      /' | head -8
    cp -p "$bk" "$CF"; chown root:root "$CF"; chmod 644 "$CF"
    return 1
  fi
  say "  🔴 태그만 고쳤다 — **아무것도 안 뜨고 안 멈췄다.** compose 는 글자일 뿐이다."
  say "     다만 지금부터 누가 **인자 없는 up -d** 를 부르면 새 판이 올라온다."
  say "     부르지 마세요. 띄우는 것은 --go 가 한다."
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --migrate · --go 가 **같은 것**을 본다
#
#  🔴 --migrate 와 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면
#     **아무것도 바꾸지 않고 멈춘다.**
#  🔴 「아직 안 온 것 · 아직 안 실린 것」은 ⚠️ 로 안내만 한다(17~19번의 규칙).
# ══════════════════════════════════════════════════════════════════════
SWAPPED=0
run_checks() {
  local tag rec t n v code f db n_bk FREE_KB FREE_H ex

  # ── 1-ㄱ. 올릴 파일 넷 ──────────────────────────────────────────────
  step "1-ㄱ. 올린 파일 **넷** (이미지 tar 셋 · A/S 마이그레이션 묶음)"
  EXP_INV=$(tar_config_id      "$TAR_INV"      2>/dev/null) || EXP_INV=""
  EXP_INVTOOLS=$(tar_config_id "$TAR_INVTOOLS" 2>/dev/null) || EXP_INVTOOLS=""
  EXP_AS=$(tar_config_id       "$TAR_AS"       2>/dev/null) || EXP_AS=""
  see_tar() { # 1 태그 2 tar 3 tar에서읽은지문 4 기대바이트 5 기대md5 6 기대지문
    local n m
    if [ ! -s "$2" ]; then
      notyet "$1 의 tar 가 아직 NAS 에 없다: $2"
      say "    → 개발 PC(PowerShell)에서 올리세요. 🔴 scp 에 **-O** 를 붙입니다."
      return 1
    fi
    n=$(stat -c '%s' "$2" 2>/dev/null)
    m=$(md5sum "$2" 2>/dev/null | awk '{print $1}')
    say "    · 지금 이 tar: 바이트 ${n:-?} · md5 ${m:-?}"
    if [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ]; then
      say "    ⚠️ 🔴 **기대값이 아직 비어 있다.** 개발 PC 에서 재어 채우세요."
      say "       채우기 전에는 --migrate 도 --go 도 시작하지 않습니다."
      [ -n "$3" ] && say "    · 이 tar 안 Config 지문: $3"
      return 0
    fi
    [ "$n" = "$4" ] && ok "$1 · 바이트 $n" \
      || bad "$1 의 바이트가 $4 가 아니다 ($n) — 옮기다 끊겼다"
    [ "$m" = "$5" ] && ok "$1 · md5 $m" \
      || bad "$1 의 md5 가 $5 가 아니다 (${m:-못 읽음}) — 파일이 상했다"
    if [ -z "$3" ]; then
      bad "$1 의 tar 에서 manifest.json 을 읽지 못했다: $2"
      return 1
    fi
    [ "$3" = "$6" ] && ok "$1 · tar 안 Config 지문이 기대값과 같다 ($(echo "$3" | cut -c1-19)…)" \
      || { bad "$1 · tar 안 Config 지문이 기대값과 다르다"
           say "      tar   $3"
           say "      기대  $6"
           say "      🔴 **다른 판을 올린 것**이거나 옮기다 깨진 것이다."; }
  }
  see_tar "$TAG_INV"      "$TAR_INV"      "$EXP_INV"      "$SZ_INV"      "$MD5_INV"      "$WANT_CFG_INV"
  see_tar "$TAG_INVTOOLS" "$TAR_INVTOOLS" "$EXP_INVTOOLS" "$SZ_INVTOOLS" "$MD5_INVTOOLS" "$WANT_CFG_INVTOOLS"
  see_tar "$TAG_AS"       "$TAR_AS"       "$EXP_AS"       "$SZ_AS"       "$MD5_AS"       "$WANT_CFG_AS"
  say "  🔴 tar 가 이미지의 1/4 쯤인 것은 **정상**이다. 지난 판과 견주세요:"
  for f in "$IMAGES/dss-inventory-0.1.tar" "$IMAGES/dss-inventory-tools-1.tar" \
           "$IMAGES/dss-as-2.5.tar"; do
    [ -s "$f" ] && say "      $(basename "$f") $(stat -c '%s' "$f") 바이트"
  done

  # ── 1-ㄴ. NAS 에 실린 이미지 ────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (올라가는 셋 · 되돌릴 셋 · 건드리지 않는 열하나)"
  for rec in "$TAG_INV|$EXP_INV" "$TAG_INVTOOLS|$EXP_INVTOOLS" "$TAG_AS|$EXP_AS"; do
    tag=${rec%%|*}; t=${rec##*|}
    if have_img "$tag"; then
      [ -n "$t" ] && { verify_img "$tag" "$t" || force_load_hint; }
    else
      notyet "$tag 는 아직 NAS 에 안 실렸다 — --preload 나 --migrate 가 싣는다"
    fi
  done
  say "  🔴 **되돌릴 길** — 옛 태그 셋이 NAS 에 그대로 있어야 한다:"
  for tag in "$OLD_INV" "$OLD_INVTOOLS" "$OLD_AS"; do
    have_img "$tag" && ok "$tag 가 아직 있다 (되돌릴 길이 열려 있다)" \
      || bad "🔴 $tag 가 NAS 에 **없다** — 되돌리려면 tar 를 다시 올려야 한다"
  done
  say "  🔴 건드리지 않는 열하나 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for tag in $KEEP_TAGS; do
    have_img "$tag" && ok "$tag 실려 있다 ($(img_id "$tag" | cut -c1-19)…)" \
      || bad "$tag 가 NAS 에 없다 — 🔴 앞 배포가 되돌아갔거나 누가 지웠다"
  done
  say "  ⚠️ $KEEP_ASTOOLS 는 **다시 굽지 않았다.** A/S 의 drizzle 은 이미지가"
  say "     아니라 볼륨이라 새 .sql 은 폴더로 들어간다(1-ㅁ)."

  # ── 1-ㄷ. 이미지 안 ─────────────────────────────────────────────────
  step "1-ㄷ. 【검사 1-ㄱ】 $TAG_INV 안 — 새 통로 넷이 들어 있는가"
  inv_app_inside
  step "1-ㄹ. 【검사 1-ㄴ】 $TAG_INVTOOLS 안 — 마이그레이션 **스무 장**"
  inv_tools_inside
  step "1-ㅁ. 【검사 1-ㄷ】 $TAG_AS 안 — A/S 읽기 통로 셋이 **처음** 생겼는가"
  as_app_inside

  # ── 1-ㅂ. 마이그레이션 ──────────────────────────────────────────────
  step "1-ㅂ. 【검사 2-ㄱ】 A/S 마이그레이션 파일 ($AS_MIG_HAVE → $AS_MIG_WANT)"
  as_mig_files
  step "1-ㅅ. 【검사 2-ㄴ】 🔴 재고 11건의 **지우는 문장**을 센다"
  inv_destructive_scan
  step "1-ㅇ. 【검사 2-ㄷ】 운영 DB 가 지금 어디까지 와 있나"
  if pg_up; then
    ok "dss-pg-app 이 떠 있다"
    if [ -z "$(inv_mig_table)" ]; then
      bad "$INV_DB 에 drizzle.__drizzle_migrations 가 없다 — 27번이 덜 끝난 DB 다"
    else
      n=$(inv_mig_count); v=$(inv_tbl_count)
      say "  · 재고 $INV_DB : 마이그레이션 ${n:-?}줄 · 표 ${v:-?}개"
      case "${n:-x}" in
        "$INV_MIG_HAVE") ok "적용 전 상태가 맞다 (${INV_MIG_HAVE}줄) — --migrate 가 11건을 적용한다" ;;
        "$INV_MIG_WANT") ok "**이미 ${INV_MIG_WANT}줄이다** — 적용이 끝난 DB 다(두 번 돌려도 안전)" ;;
        *) bad "적용된 줄이 $INV_MIG_HAVE 도 $INV_MIG_WANT 도 아니다 (${n:-?})"
           say "    → 🔴 **이것이 신호다.** 고치지 말고 **먼저 알리세요.**" ;;
      esac
      [ "${v:-0}" = "$INV_TBL_HAVE" ] || [ "${v:-0}" = "$INV_TBL_WANT" ] \
        && ok "표가 ${v}개다 ($INV_TBL_HAVE 또는 $INV_TBL_WANT 이 맞다)" \
        || bad "표가 ${v:-?}개다 ($INV_TBL_HAVE 도 $INV_TBL_WANT 도 아니다)"
      # 🔴 지우는 문장이 손대는 두 표 — 적용 전에는 **없어야** 한다
      for t in $INV_DROP_TABLES; do
        if [ "$(inv_tbl_has "$t")" = 1 ]; then
          if [ "${n:-0}" = "$INV_MIG_WANT" ]; then
            ok "표 $t 가 있다 (적용이 끝난 뒤라 맞다)"
          else
            bad "🔴 표 $t 가 **적용 전인데 이미 있다** — 전제가 깨졌다"
            say "      DROP COLUMN 셋이 안전한 까닭이 「0011 이 지금 만든다」인데,"
            say "      이미 있다면 그 안에 자료가 있을 수 있다. **멈추고 알리세요.**"
          fi
        else
          ok "표 $t 가 아직 없다 (맞다 — 0011 이 만든다)"
        fi
      done
      say "  · 줄 수 (적용 뒤에 **그대로여야** 한다):"
      for t in $INV_COUNT_TABLES; do
        say "      $t $(qi "select count(*) from $t" 2>/dev/null)줄"
      done
    fi
    n=$(as_mig_count)
    say "  · A/S $AS_DB : 마이그레이션 ${n:-?}줄"
    case "${n:-x}" in
      "$AS_MIG_HAVE") ok "적용 전 상태가 맞다 (${AS_MIG_HAVE}줄) — --migrate 가 1건을 적용한다" ;;
      "$AS_MIG_WANT") ok "**이미 ${AS_MIG_WANT}줄이다** — 적용이 끝난 DB 다" ;;
      *) bad "적용된 줄이 $AS_MIG_HAVE 도 $AS_MIG_WANT 도 아니다 (${n:-?})"
         say "    → 🔴 고치지 말고 **먼저 알리세요.**" ;;
    esac
    v=$(qas "select count(*) from information_schema.columns where table_name='$AS_NEW_COL_TBL' and column_name='$AS_NEW_COL'")
    say "  · $AS_NEW_COL_TBL.$AS_NEW_COL 칸: ${v:-?}개 (적용 전 0 · 적용 뒤 1)"
    for t in $AS_COUNT_TABLES; do
      say "      $t $(qas "select count(*) from $t" 2>/dev/null)줄"
    done
  else
    bad "dss-pg-app 이 떠 있지 않다 — DB 를 하나도 볼 수 없다"
  fi

  # ── 1-ㅈ. 권한 ──────────────────────────────────────────────────────
  step "1-ㅈ. 【검사 3】 🔴 **배포 전에 사람이 봐야 하는 것** — 운영 DB 의 권한"
  perm_check

  # ── 1-ㅊ. 설정 여덟 ─────────────────────────────────────────────────
  link_env_check

  # ── 1-ㅋ. compose ───────────────────────────────────────────────────
  step "1-ㅋ. 【검사 6】 compose ($CF)"
  if compose_at "$CF" config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_at "$CF" config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  SVCS=$(compose_at "$CF" config --services 2>/dev/null)
  for t in app-auth app-as tools-as app-meters tools-meters app-improvements \
           tools-improvements app-po app-leave tools-leave app-board tools-board \
           app-inventory tools-inventory; do
    echo "$SVCS" | grep -qx "$t" && ok "서비스 목록에 $t 가 있다" \
      || bad "🔴 서비스 목록에 $t 가 **없다** — 주석이 덮였거나 파일이 옛것이다"
  done
  if compose_swapped; then
    SWAPPED=1
    ok "🔵 compose 가 **이미 새 태그 셋**으로 바뀌어 있다 (--migrate 를 돌린 뒤다)"
  else
    SWAPPED=0
    say "  🔵 compose 는 아직 **옛 태그**다 — 바꾸는 것은 --migrate 가 한다."
  fi
  say "  지금 compose 가 가리키는 태그:"
  for t in "$INV_SVC|재고 관리" "$INV_TOOLS_SVC|재고 도구" "$AS_SVC|A/S" \
           "$AS_TOOLS_SVC|A/S 도구"; do
    say "      ${t##*|} : $(svc_image "$CF" "${t%%|*}")"
  done
  for rec in "$INV_SVC|$TAG_INV|$OLD_INV" "$INV_TOOLS_SVC|$TAG_INVTOOLS|$OLD_INVTOOLS" \
             "$AS_SVC|$TAG_AS|$OLD_AS"; do
    t=${rec%%|*}; v=${rec#*|}; ex=${v##*|}; v=${v%%|*}
    case "$(svc_image "$CF" "$t")" in
      "$v") ok "$t → $v (바뀐 뒤다)" ;;
      "$ex") say "      · $t 는 아직 $ex 다 (바꾸기 전이면 맞다)" ;;
      *) bad "🔴 $t 가 $v 도 $ex 도 아니다 — 남의 것이 섞였다. 고치지 말고 알리세요" ;;
    esac
  done
  say "  🔴 건드리지 않는 열하나의 태그 (흔들렸으면 남의 것이 섞인 것이다):"
  for tag in $KEEP_TAGS; do
    [ "$(img_line_count "$CF" "$tag")" -ge 1 ] 2>/dev/null \
      && ok "compose 에 $tag 가 그대로다" \
      || bad "🔴 compose 에 $tag 가 없다"
  done
  # 포트 — 한 글자가 틀리면 리버스 프록시가 502 를 계속 낸다
  svc_block "$CF" "$INV_SVC" | grep -q "127.0.0.1:$INV_PORT:3800" \
    && ok "$INV_SVC 가 127.0.0.1:$INV_PORT 으로만 열린다" \
    || bad "$INV_SVC 의 포트가 127.0.0.1:$INV_PORT:3800 이 아니다"
  svc_block "$CF" "$AS_SVC" | grep -q "127.0.0.1:$AS_PORT:" \
    && ok "$AS_SVC 가 127.0.0.1:$AS_PORT 으로만 열린다" \
    || bad "$AS_SVC 의 포트가 127.0.0.1:$AS_PORT 이 아니다"

  # ── 1-ㅌ. 공유폴더 · gid 100 ────────────────────────────────────────
  step "1-ㅌ. 【검사 5】 🔴 재고 관리의 gid 100 과 공유폴더가 **그대로인가**"
  share_check "$CF"

  # ── 1-ㅍ. 백업 · 디스크 · 도는 것 ───────────────────────────────────
  step "1-ㅍ. 【검사 7】 오늘($TODAY) 백업 **일곱** · 디스크 · 도는 것"
  n=0
  for db in dss_auth dss_meters dss_as dss_improvements dss_leave dss_board dss_inventory; do
    f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
      n=$((n + 1))
    else
      bad "오늘($TODAY) 뜬 $db 백업이 없다"
    fi
  done
  if [ "$n" = 7 ]; then
    ok "🔴 오늘 백업이 일곱이다"
  else
    bad "🔴 오늘 백업이 ${n}개뿐이다 (일곱이어야 한다)"
    say "    🔵 야간 백업은 **02:30** 이다 — 자정을 넘겨 돌리면 여기 걸린다."
    say "    → 먼저 손으로 한 번 (종료 코드 0 이어야 한다):"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    say "    🔴 --migrate 는 dss_inventory · dss_as 백업이 **둘 다** 없으면"
    say "       시작하지 않는다."
  fi
  for t in inventory-data inventory-workbook; do
    [ -d "$BKD/files/$t" ] \
      && ok "백업에 files/$t 가 있다 ($(find "$BKD/files/$t" -type f 2>/dev/null | wc -l)개)" \
      || say "    ⚠️ 백업에 files/$t 가 없다 — 야간 백업을 한 번 돌리면 생긴다"
  done
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (tar 셋 + 실은 이미지 + 덤프)"
  fi
  pg_up && running dss-pg-auth && ok "DB 둘 다 떠 있다 (이 배포는 DB 컨테이너를 안 멈춘다)" \
    || bad "DB 컨테이너가 떠 있지 않다"
  for t in $INV_CNAME $AS_CNAME $KEEP_BOXES; do
    running "$t" && ok "$t 가 돌고 있다" || bad "🔴 $t 가 안 돌고 있다"
  done
  say "  🔴 메모리 — 바꾸기 **전** 값이다. --go 뒤와 견주세요:"
  free -m 2>/dev/null | sed 's/^/      /'

  # ── 1-ㅎ. 통로 — 🔴 **값으로** 본다 ─────────────────────────────────
  step "1-ㅎ. 【검사 8】 🔴 통로를 **앱이 쓰는 길로** 두드린다 (바꾸기 전 상태)"
  say "  🔴 호스트의 curl 이 아니라 **A/S 컨테이너 안에서 node 의 fetch** 로"
  say "     $INV_BASE 를 부른다. 루프백으로 재면 DSM 프록시도 도커 망도 안 지난다."
  say "  🔵 지금은 재고가 **0.1** 이라 아래가 기대값이다:"
  say "      /api/v1/parts          → 401 (0.1 에도 있던 통로 · 토큰 없이 부른다)"
  say "      /api/v1/oh-templates   → 404 (0.2 에서 생긴다)"
  say "      /api/v1/stock-requests → 404 (0.2 에서 생긴다)"
  v=$(probe "$AS_CNAME" "$INV_BASE$P_PARTS" "" GET)
  judge_probe "A/S → 재고 $P_PARTS (토큰 없이)" "$v" "401 503" \
    "401 이 아니면 자격이 안 걸려 있거나(503=토큰 빔) 통로가 없다" || true
  v=$(probe "$AS_CNAME" "$INV_BASE$P_OHT" "" GET)
  case "$(probe_code "$v")" in
    404) ok "A/S → 재고 /api/v1/oh-templates → 404 (아직 0.1 이다 — **맞다**)" ;;
    401|503) ok "→ $(probe_code "$v") · 이미 0.2 가 떠 있다 (--go 를 돌린 뒤다)" ;;
    *) bad "A/S → 재고 /api/v1/oh-templates → $(probe_code "$v") — 뜻을 모르겠다" ;;
  esac
  v=$(probe "$AS_CNAME" "$INV_BASE$P_SREQ" "" GET)
  case "$(probe_code "$v")" in
    404) ok "A/S → 재고 /api/v1/stock-requests → 404 (아직 0.1 이다 — **맞다**)" ;;
    401|503) ok "→ $(probe_code "$v") · 이미 0.2 가 떠 있다" ;;
    *) bad "A/S → 재고 /api/v1/stock-requests → $(probe_code "$v") — 뜻을 모르겠다" ;;
  esac
  say "  🔵 거꾸로 — 재고가 A/S 를 부르는 길. 지금은 A/S 가 **2.5** 라"
  say "     **404 가 맞다**(그 통로가 2.6 에서 처음 생긴다):"
  v=$(probe "$INV_CNAME" "$AS_BASE$P_AS_USERS" "" GET)
  case "$(probe_code "$v")" in
    404) ok "재고 → A/S /api/v1/users → 404 (아직 2.5 다 — **맞다**)" ;;
    401|503) ok "→ $(probe_code "$v") · 이미 2.6 이 떠 있다" ;;
    *) bad "재고 → A/S /api/v1/users → $(probe_code "$v") — 뜻을 모르겠다" ;;
  esac

  # ── 1-ㄲ. 바깥 주소 여덟 ────────────────────────────────────────────
  step "1-ㄲ. 바깥 주소 여덟 (지금 상태를 적어 둔다)"
  for t in inventory as $KEEP_HOSTS; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$t.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$t.dss21.co.kr → $code" ;;
      *)       bad "🔴 https://$t.dss21.co.kr → ${code:-없음}" ;;
    esac
  done
}
# ══ 되돌리기 ═══════════════════════════════════════════════════════════
if [ "$MODE" = rollback ]; then
  echo "DSS 스물두째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say
  say "  ── 되돌릴 것 셋 ──────────────────────────────────────────────"
  say "   ① compose      backups/docker-compose.nas.yml.<도장>"
  say "   ② A/S 마이그레이션 폴더  $MIGDIR.old"
  say "   ③ DB 덤프      backups/predeploy-<도장>/  🔴 **마지막 수단**"
  say
  say "  🔵 **DB 는 되돌리지 않는 것이 기본이다.** 이번 12건은 옛 판이 그대로"
  say "     돌 수 있는 모양이다 — 있던 표에 더해지는 칸은 전부 DEFAULT 가 있거나"
  say "     NULL 을 받고, requested_by 는 NOT NULL 을 **푸는** 쪽이다."
  say "     DROP COLUMN 셋은 **0011 이 이번에 만든 표**를 다듬은 것이라"
  say "     0.1 이 아예 모르는 자리다. A/S 0115 의 CHECK 도 새 칸이 NULL 이면"
  say "     늘 참이라 2.5 의 저장을 막지 않는다."
  say "  🔵 env 의 여덟 줄도 **그대로 둔다** — 옛 판은 그 이름을 읽지 않는다."

  step "1. 지금 상태"
  for t in "$INV_CNAME" "$AS_CNAME"; do
    running "$t" \
      && say "  $t : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$t " || echo '?')" \
      || say "  $t 은 돌고 있지 않다"
  done
  if pg_up; then
    say "  재고 마이그레이션: $(inv_mig_count)줄 · 표 $(inv_tbl_count)개"
    say "  A/S  마이그레이션: $(as_mig_count)줄"
  fi
  say "  compose 가 가리키는 것:"
  for t in "$INV_SVC" "$INV_TOOLS_SVC" "$AS_SVC"; do
    say "      $t : $(svc_image "$CF" "$t")"
  done

  step "2. 옛 이미지가 아직 있는지 먼저 본다"
  for t in "$OLD_INV" "$OLD_INVTOOLS" "$OLD_AS"; do
    have_img "$t" && ok "$t 가 있다" \
      || { bad "🔴 $t 가 **없다** — 되돌리려면 tar 를 다시 올려야 한다"
           say "      (PowerShell) scp -O dss-...tar dss-nas:/volume1/dss/images/"
           say "      (NAS) /usr/local/bin/docker load -i /volume1/dss/images/..."; }
  done

  step "3. compose 를 사본으로 되돌린다 — 🔴 **통째로** 되돌린다"
  say "  🔴 태그 세 줄만 손으로 고치지 마라. 들여쓰기 한 칸에 여덟 사이트가"
  say "     함께 넘어간다. 있는 사본 (최근 다섯):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -5 | sed 's/^/      /' \
    || say "      (없다)"
  say "  위에서 **되돌릴 것 하나를 고른 뒤** 한 줄씩:"
  cmd "cd /volume1/dss/deploy"
  cmd "B=/volume1/dss/backups"
  cmd "F=docker-compose.nas.yml"
  cmd "cp -p \$B/docker-compose.nas.yml.<고른것> \$F"
  cmd "chown root:root \$F && chmod 644 \$F"
  cmd "D1=/usr/local/bin/docker"
  cmd "C=\"compose -f \$F --env-file .env.nas\""
  cmd "\$D1 \$C config --quiet"
  script_file_hint "28-rollback"

  step "4. 옛 판 둘을 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "\$D1 \$C up -d --no-deps $INV_SVC"
  cmd "\$D1 \$C up -d --no-deps $AS_SVC"
  say "  🔵 둘을 **반쪽만** 되돌려도 안 깨진다. 재고만 0.1 로 내리면 A/S 2.6 의"
  say "     부품 요청이 「확인하지 못했습니다」가 되고, A/S 만 2.5 로 내리면"
  say "     재고의 인수번호 조회가 「응답 없음」이 된다 — 둘 다 **설계된 꼴**이다."

  step "5. A/S 마이그레이션 폴더 (🔴 보통은 되돌리지 않는다)"
  if [ -d "$MIGDIR.old" ]; then
    say "  $MIGDIR.old 가 있다 ($(ls -1 "$MIGDIR.old"/*.sql 2>/dev/null | wc -l)장)."
    say "  🔴 되돌릴 까닭은 거의 없다 — 폴더가 116 이어도 2.5 는 그것을 읽지"
    say "     않는다(읽는 것은 tools-as 뿐이고 그때만 돈다). 그래도 굳이 한다면:"
    cmd "M=/volume1/dss/as-migrations"
    cmd "mv \$M \$M.116 && mv \$M.old \$M"
  else
    say "  $MIGDIR.old 가 없다 — 아직 갈아 끼우지 않았다."
  fi

  step "6. 🔴 DB 덤프 — **마지막 수단이다**"
  ls -1dt "$BKD"/predeploy-* 2>/dev/null | head -3 | sed 's/^/      /' \
    || say "      (없다)"
  say "  🔴 **되돌리기 전에 반드시 알리세요.** PO 가 같은 dss_as 를 보고 있어,"
  say "     덤프를 뜬 뒤 PO 에서 저장한 것이 전부 사라진다."
  say "  🔴 재고 쪽도 마찬가지다 — 전환일 자료(부품 319 · 과거 2,288)가 든 DB 다."

  step "7. 이미지는 지우지 않는다"
  say "  $TAG_INV · $TAG_INVTOOLS · $TAG_AS 를 남겨 둔다 — 다시 올릴 때 쓴다."
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit 0
fi

# ══ 여기부터 check · preload · force-load · migrate · go ═══════════════
echo "DSS 스물두째 배포 · $(date '+%F %T')"
echo "  🔴 올라가는 것 셋:"
echo "     $OLD_INV → **$TAG_INV**          (커밋 42)"
echo "     $OLD_INVTOOLS → **$TAG_INVTOOLS**"
echo "     $OLD_AS → **$TAG_AS**            (커밋 11 · vendor/dss-core 2ecdf01)"
echo "  🔴 마이그레이션 **12건** — 재고 11(0009~0019) · A/S 1(0115)"
echo "     재고 $INV_MIG_HAVE줄 → $INV_MIG_WANT줄 · 표 $INV_TBL_HAVE개 → $INV_TBL_WANT개"
echo "     A/S  $AS_MIG_HAVE줄 → $AS_MIG_WANT줄"
echo "  🔴 멈추는 것은 **둘뿐** — dss-inventory · dss-as."
echo "     그대로 도는 여섯: 포털 · 계측기 · 개선요청 · PO · 휴가 · 게시판 (+ DB 둘)"
echo "  🔴 순서: **재고 먼저**, 통로를 값으로 확인한 뒤 A/S."
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**" ;;
  preload)    echo "  🔵 --preload — 이미지 셋을 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  migrate)    echo "  🔴 --migrate — compose 태그 셋 + 마이그레이션 12건. **DB 가 바뀐다.**"
              [ "$DROP_OK" = 1 ] && echo "  🔴 --drop-column-ok 를 받았다 — DROP COLUMN 셋을 알고 가는 것이다." ;;
  go)         echo "  🔴 --go — 재고 → (통로 확인) → A/S 를 바꿔 끼운다. ⏱ 정지 창."
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 미리 실어 두려는 시점에는 뒤 항목(백업 · 설정)이 아직
#    안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "이미지 tar 셋 · 지문"
  EXP_INV=$(tar_config_id      "$TAR_INV"      2>/dev/null) || EXP_INV=""
  EXP_INVTOOLS=$(tar_config_id "$TAR_INVTOOLS" 2>/dev/null) || EXP_INVTOOLS=""
  EXP_AS=$(tar_config_id       "$TAR_AS"       2>/dev/null) || EXP_AS=""
  for rec in "$TAG_INV|$TAR_INV|$EXP_INV|$SZ_INV|$MD5_INV|$WANT_CFG_INV" \
             "$TAG_INVTOOLS|$TAR_INVTOOLS|$EXP_INVTOOLS|$SZ_INVTOOLS|$MD5_INVTOOLS|$WANT_CFG_INVTOOLS" \
             "$TAG_AS|$TAR_AS|$EXP_AS|$SZ_AS|$MD5_AS|$WANT_CFG_AS"; do
    IFS='|' read -r tag tarf exp sz md5 wcfg <<EOF
$rec
EOF
    if [ ! -s "$tarf" ]; then bad "$tag 의 tar 가 없다: $tarf"; continue; fi
    n=$(stat -c '%s' "$tarf" 2>/dev/null)
    m=$(md5sum "$tarf" 2>/dev/null | awk '{print $1}')
    if [ -z "$sz" ] || [ -z "$md5" ]; then
      say "  ⚠️ $tag · 바이트 $n · md5 $m — 🔴 **기대값이 없어 대조하지 않았다.**"
      say "     이미지를 구운 PC 에서 잰 값과 눈으로 맞춰 주세요."
    else
      if [ "$n" != "$sz" ]; then
        bad "$tag 의 바이트가 $sz 가 아니다 ($n) — 올리다 끊겼다. 싣지 않는다"
        continue
      fi
      if [ "$m" != "$md5" ]; then
        bad "$tag 의 md5 가 $md5 가 아니다 (${m:-못 읽음}) — 파일이 상했다. 싣지 않는다"
        continue
      fi
      ok "$tag · 바이트 $n · md5 맞음"
    fi
    if [ -z "$exp" ]; then bad "$tag 의 tar 에서 manifest.json 을 읽지 못했다"; continue; fi
    if [ -n "$wcfg" ] && [ "$exp" != "$wcfg" ]; then
      bad "$tag · tar 안 Config 지문이 기대값과 다르다 — **다른 판이다.** 싣지 않는다"
      say "      tar   $exp"
      say "      기대  $wcfg"
      continue
    fi
    bring_img "$tag" "$tarf" "$exp"
  done

  # 🔴 실어 놓고 **안을 본다.** 태그와 지문이 맞아도 「무엇이 든 판인지」는
  #    사람이 읽을 수 있는 증거로 한 번 더 남긴다.
  step "$TAG_INV 안"
  inv_app_inside
  step "$TAG_INVTOOLS 안 — 🔴 마이그레이션 **스무 장**이어야 한다"
  inv_tools_inside
  step "$TAG_AS 안"
  as_app_inside

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 멈추지 않았다**"
  if [ "$FAIL" != 0 ] && [ "$FORCE_LOAD" != 1 ]; then
    echo "  🔴 지문이 어긋난 것이 있으면 **같은 태그로 다시 구운 것**이다:"
    echo "       bash $0 --preload --force-load"
  fi
  echo "  🔵 나머지 항목은 안 봤다. 이어서: bash $0        (읽기만)"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 1. 먼저 볼 것 (check · migrate · go 가 같이 지난다) ════════════════
#
# 🔴 규칙 하나: **바꾸기 전에 볼 것을 다 보고, 어긋나면 아무것도 하지 않은
#    채로 멈춘다.** 여기서 끝나면 아무 일도 일어나지 않는다.
step "1. 준비가 됐는지 기계로 본다 (아직 아무것도 안 바꿨다)"
run_checks

if [ "$MODE" = check ]; then
  env_template
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo
  echo "  🔴 --check 가 보여 준 것 — 사람이 보고 판단할 자리 다섯:"
  echo "     ① 운영 DB 의 inventory% 권한 표 (1-ㅈ)"
  echo "        🔴 $PERM_GATE 가 A/S 새 통로의 문입니다."
  echo "     ② 설정 여덟의 길이와 지문 · 짝이 맞는가 · 읽기 ≠ 쓰기 (1-ㅊ)"
  echo "     ③ 지우는 문장 셋과 그것이 안전한 까닭 (1-ㅅ)"
  echo "     ④ 적용 전 줄 수 — parts · stock_entries · legacy_records … (1-ㅇ)"
  echo "     ⑤ 설정 여덟을 적는 틀 (바로 위)"
  if [ "$FAIL" = 0 ]; then
    if ! pinned; then
      echo "  ⚠️ 이미지 기대값 아홉이 아직 비어 있습니다 — 재어 채운 뒤에 갑니다."
    elif ! have_img "$TAG_INV" || ! have_img "$TAG_INVTOOLS" || ! have_img "$TAG_AS"; then
      echo "  ✅ 이어서 (아무것도 안 멈춥니다):  bash $0 --preload"
    elif [ "$SWAPPED" = 0 ]; then
      echo "  ✅ 이어서 (🔴 DB 가 바뀝니다):"
      echo "       bash $0 --migrate --drop-column-ok"
    elif ! running "$INV_CNAME"; then
      echo "  ✅ 이어서 (⏱ 정지 창):           bash $0 --go"
    else
      echo "  ✅ 이어서 (⏱ 정지 창):           bash $0 --go"
    fi
  else
    echo "  ✗ 위 ✗ 를 먼저 해결하세요. Claude 에게 알려 주세요."
  fi
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터는 --migrate 와 --go 뿐이다 ════════════════════════════════
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 바꾸지 않았고 두 사이트는 살아 있습니다.**"
pinned || {
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 이미지 기대값 아홉이 **비어 있습니다.** 재지 않은 이미지를    ║"
  say "  ║    운영에 올리지 않습니다.                                     ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     이 파일 머리말 「돌리기 전에」의 차례대로 개발 PC 에서 재어"
  say "     아홉을 채우고, 이 파일을 다시 올린 뒤(md5 대조) 돌리세요."
  stop "아무것도 바꾸지 않았습니다. 앱도 DB 도 그대로입니다."
}
# ══ --migrate — 🔴 여기서만 DB 가 바뀐다 ══════════════════════════════
#
# 🔴 차례가 중요하다. compose 태그를 **먼저** 고치는 까닭은, 재고 쪽
#    마이그레이션이 **도구 이미지 안**에 있어서 tools-inventory 가 :2 를
#    가리켜야 새 11건을 보기 때문이다. 태그를 고쳐도 아무것도 안 뜨고 안 멈춘다.
# 🔴 적용하는 동안 직원은 **0.1 과 2.5 를 그대로 쓰고 있다.**
if [ "$MODE" = migrate ]; then
  if [ "$DROP_OK" != 1 ]; then
    say
    say "  ╔══════════════════════════════════════════════════════════════╗"
    say "  ║ 🔴 이번 판에는 **되돌릴 수 없는 문장이 셋** 있습니다.          ║"
    say "  ╚══════════════════════════════════════════════════════════════╝"
    say "     0012 : oh_part_template_items DROP COLUMN oh_price"
    say "     0012 : oh_part_templates      DROP COLUMN sort_order"
    say "     0014 : oh_part_templates      DROP COLUMN code"
    say
    say "  🔵 그래도 운영 자료는 한 줄도 안 사라집니다 — 그 두 표가 같은 묶음"
    say "     안의 **0011 에서 태어나기** 때문입니다. 위 1-ㅇ 이 운영 DB 에 그"
    say "     표가 정말 없는지 이미 세었고, 아래에서 **한 번 더** 셉니다."
    say "  🔴 그래도 되돌릴 수 없는 문장인 것은 맞습니다. 알고 간다는 뜻으로"
    say "     깃발을 하나 더 주세요:"
    cmd "bash $0 --migrate --drop-column-ok"
    stop "DB 를 바꾸지 않았습니다. **앱도 DB 도 그대로입니다.**"
  fi

  # ── 1. 🔴 오늘 백업 **둘**을 지금 다시 찾는다 ───────────────────────
  #
  # 🔴 --check 에서 봤다는 것으로는 부족하다 — 그 뒤에 지워졌을 수 있고,
  #    무엇보다 --check 를 안 돌리고 바로 여기로 올 수 있다.
  #    🔴 스크립트가 **대신 뜨지 않는다.**
  step "1. 🔴 오늘 백업 **둘**을 지금 다시 찾는다 (없으면 여기서 멈춘다)"
  BK_OK=1
  for db in "$INV_DB" "$AS_DB"; do
    f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
    else
      bad "오늘($TODAY) 뜬 $db 백업을 **지금 찾지 못했다**"
      BK_OK=0
    fi
  done
  if [ "$BK_OK" != 1 ]; then
    say "  🔵 야간 백업은 **02:30** 입니다 — 자정을 넘겨 돌리면 여기 걸립니다."
    say "     먼저 이것부터 (종료 코드 0 이어야 합니다):"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    say "     ✓ $INV_DB · ✓ $AS_DB 줄이 둘 다 찍혀야 합니다. 그 뒤에 다시:"
    cmd "bash $0 --migrate --drop-column-ok"
    stop "백업 없이 DB 를 바꾸지 않습니다. **DB 도 앱도 그대로입니다.**"
  fi

  # ── 2. 적용 직전 덤프 둘 ────────────────────────────────────────────
  #
  # 🔴 되돌리기의 **기본 수단이 아니다.** 되돌리기는 이미지만 내리고 DB 를
  #    그대로 두는 것이다(--rollback 참조). 이것은 「마이그레이션이 DB 를
  #    깨뜨렸을 때」의 마지막 수단이다.
  step "2. 적용 직전 덤프 둘 ($INV_DB · $AS_DB)"
  BK=$BKD/predeploy-$STAMP
  mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
  for db in "$INV_DB" "$AS_DB"; do
    if "$DOCKER" exec dss-pg-app sh -c "pg_dump -U \"\$POSTGRES_USER\" -d $db -Fc" \
         > "$BK/$db.dump.part" 2>/dev/null \
       && "$DOCKER" exec -i dss-pg-app pg_restore -l < "$BK/$db.dump.part" >/dev/null 2>&1; then
      mv "$BK/$db.dump.part" "$BK/$db.dump"
      ok "$db 덤프 $(du -h "$BK/$db.dump" | cut -f1) → $BK"
    else
      rm -f "$BK/$db.dump.part"
      bad "$db 덤프 실패"
      stop "DB 를 바꾸지 않았습니다. **앱도 그대로입니다.**"
    fi
  done
  say "  ⚠️ PO 가 같은 $AS_DB 를 보고 있다 — 덤프 중에 PO 에서 저장한 것은 이"
  say "     덤프에 안 들어갈 수 있다. 그래서 이것은 마지막 수단이고, 되돌리기의"
  say "     기본은 **이미지만 내리고 DB 는 그대로 두는 것**이다."

  # ── 3. 🔴 적용 전 상태를 한 번 더 센다 ──────────────────────────────
  step "3. 🔴 적용 전 상태를 **지금 다시** 센다"
  MIG_I_BEFORE=$(inv_mig_count); MIG_I_BEFORE=${MIG_I_BEFORE:-0}
  TBL_I_BEFORE=$(inv_tbl_count); TBL_I_BEFORE=${TBL_I_BEFORE:-0}
  MIG_A_BEFORE=$(as_mig_count);  MIG_A_BEFORE=${MIG_A_BEFORE:-0}
  say "  · 재고 : 마이그레이션 ${MIG_I_BEFORE}줄 · 표 ${TBL_I_BEFORE}개"
  say "  · A/S  : 마이그레이션 ${MIG_A_BEFORE}줄"
  [ "$MIG_I_BEFORE" = "$INV_MIG_HAVE" ] || [ "$MIG_I_BEFORE" = "$INV_MIG_WANT" ] \
    || stop "재고의 마이그레이션 줄이 $INV_MIG_HAVE 도 $INV_MIG_WANT 도 아닙니다. **DB 는 그대로입니다.**"
  [ "$MIG_A_BEFORE" = "$AS_MIG_HAVE" ] || [ "$MIG_A_BEFORE" = "$AS_MIG_WANT" ] \
    || stop "A/S 의 마이그레이션 줄이 $AS_MIG_HAVE 도 $AS_MIG_WANT 도 아닙니다. **DB 는 그대로입니다.**"
  # 🔴 DROP COLUMN 이 안전한 **전제**를 여기서 한 번 더 못 박는다
  if [ "$MIG_I_BEFORE" = "$INV_MIG_HAVE" ]; then
    for t in $INV_DROP_TABLES; do
      if [ "$(inv_tbl_has "$t")" = 1 ]; then
        bad "🔴 표 $t 가 **적용 전인데 이미 있다**"
        say "      DROP COLUMN 셋이 안전한 까닭이 「0011 이 지금 만든다」인데"
        say "      그 전제가 깨졌습니다. 그 안에 자료가 있으면 사라집니다."
        stop "**DB 를 바꾸지 않았습니다.** 고치지 말고 알리세요."
      fi
      ok "표 $t 가 아직 없다 — DROP COLUMN 이 지울 자료가 없다"
    done
  fi
  say "  · 줄 수 (적용 뒤에 **그대로여야** 한다):"
  CNT_BEFORE=""
  for t in $INV_COUNT_TABLES; do
    v=$(qi "select count(*) from $t" 2>/dev/null)
    CNT_BEFORE="$CNT_BEFORE inv:$t=${v:-?}"
    say "      재고 $t ${v:-?}줄"
  done
  for t in $AS_COUNT_TABLES; do
    v=$(qas "select count(*) from $t" 2>/dev/null)
    CNT_BEFORE="$CNT_BEFORE as:$t=${v:-?}"
    say "      A/S  $t ${v:-?}줄"
  done

  # ── 4. compose 태그 셋 ──────────────────────────────────────────────
  step "4. compose 의 태그 **세 줄**을 고친다 (🔴 아무것도 안 뜨고 안 멈춘다)"
  if compose_swapped; then
    ok "compose 가 **이미** 새 태그 셋이다 — 할 일이 없다"
  else
    swap_tags || stop "compose 를 바꾸지 못했습니다(되돌려 두었습니다). **DB 도 앱도 그대로입니다.**"
  fi

  # ── 5. A/S 마이그레이션 파일 놓기 ───────────────────────────────────
  step "5. A/S 마이그레이션 파일 놓기 ($MIGDIR)"
  if [ -s "$MIGTAR" ]; then
    rm -rf "$MIGDIR.new"; mkdir -p "$MIGDIR.new"
    if tar -xzf "$MIGTAR" -C "$MIGDIR.new" --strip-components=1; then
      rm -rf "$MIGDIR.old"
      [ -d "$MIGDIR" ] && mv "$MIGDIR" "$MIGDIR.old"
      mv "$MIGDIR.new" "$MIGDIR"
      rm -f "$MIGTAR"
      chown -R root:root "$MIGDIR"; chmod -R a+rX "$MIGDIR"
      ok "as-migrations 새것으로 (옛것: as-migrations.old — 되돌릴 길이다)"
    else
      rm -rf "$MIGDIR.new"
      bad "as-migrations 풀기 실패"
      stop "DB 를 바꾸지 않았습니다. **앱도 그대로입니다.**"
    fi
  else
    say "  · incoming 에 묶음이 없다 — 폴더가 이미 새것인지 아래에서 본다"
  fi
  N_SQL=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  N_J=0
  [ -f "$MIGDIR/meta/_journal.json" ] \
    && N_J=$(grep -c '"tag"' "$MIGDIR/meta/_journal.json" 2>/dev/null | tr -d ' ')
  [ "$N_SQL" = "$AS_MIG_WANT" ] && ok ".sql ${N_SQL}장" \
    || bad ".sql 이 ${AS_MIG_WANT}장이 아니다 (${N_SQL}장)"
  [ "$N_J" = "$AS_MIG_WANT" ] && ok "_journal.json 의 tag ${N_J}줄" \
    || bad "_journal.json 의 tag 가 ${AS_MIG_WANT}줄이 아니다 (${N_J}줄) — 🔴 적용이 0건으로 끝난다"
  MISS=""
  for t in $AS_NEW_MIGS; do
    ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || MISS="$MISS $t(sql)"
    [ -f "$MIGDIR/meta/${t}_snapshot.json" ] || MISS="$MISS $t(snapshot)"
  done
  [ -z "$MISS" ] && ok "$AS_NEW_MIGS 의 .sql 과 snapshot 이 다 있다" || bad "빠진 것:$MISS"
  F=$(ls -1 "$MIGDIR/0115_"*.sql 2>/dev/null | head -1)
  if [ -n "$F" ]; then
    grep -qF "$AS_MIG_MARK" "$F" && ok "0115 안에 $AS_MIG_MARK 가 있다" \
      || bad "0115 안에 그 글자가 **없다** — 🔴 다른 파일이다"
    destructive_scan "$F" "A/S 0115" "$AS_DROP_WANT"
  fi
  [ "$FAIL" = 0 ] || stop "마이그레이션 파일이 온전하지 않습니다. **DB 도 앱도 그대로입니다.**"

  say
  say "  🔴 이제 DB 를 바꿉니다. 그만두려면 **20초 안에 Ctrl+C**."
  say "     지금 Ctrl+C 하면 DB 는 손대지 않은 채로 남습니다."
  say "     (compose 와 마이그레이션 파일은 이미 바뀌었지만, 그것만으로는"
  say "      아무 일도 일어나지 않습니다 — 지금 도는 0.1 과 2.5 는 그것을"
  say "      읽지 않습니다. 🔴 다만 **인자 없는 up -d 를 부르지 마세요.**)"
  sleep 20

  # ── 6. 🔴 재고 11건 ─────────────────────────────────────────────────
  step "6. 🔴 재고 마이그레이션 11건 ($INV_MIG_HAVE → $INV_MIG_WANT)  — 여기서 DB 가 바뀐다"
  say "  🔵 도는 동안 직원은 **$OLD_INV 과 $OLD_AS 를 그대로 쓰고 있다.**"
  say "  🔴 다시 돌려도 안전하다 — drizzle 은 이미 적용된 것을 건너뛴다."
  "${COMPOSE[@]}" run --rm "$INV_TOOLS_SVC" npx tsx scripts/migrate.ts 2>&1 | sed 's/^/  /'
  rc=${PIPESTATUS[0]}
  if [ "$rc" = 0 ]; then
    ok "재고 마이그레이션 끝 (종료 코드 0)"
  else
    bad "재고 마이그레이션 실패 (종료 코드 $rc)"
    say "    ╔══════════════════════════════════════════════════════════════╗"
    say "    ║ 🔵 직원은 아직 $OLD_INV · $OLD_AS 를 쓰고 있습니다. 안 멈췄습니다. ║"
    say "    ╚══════════════════════════════════════════════════════════════╝"
    say "    🔴 **새 판을 띄우지 않습니다.** 고친 뒤 다시 돌리면 됩니다:"
    cmd "bash $0 --migrate --drop-column-ok"
    stop "적용 직전 덤프: $BK/$INV_DB.dump"
  fi

  step "7. 🔴 SQL 로 직접 센다 (「돌았다」가 아니라 「섰다」를 본다)"
  MIG_I_AFTER=$(inv_mig_count); TBL_I_AFTER=$(inv_tbl_count)
  [ "${MIG_I_AFTER:-0}" = "$INV_MIG_WANT" ] \
    && ok "재고 마이그레이션 ${MIG_I_AFTER}줄 (전 ${MIG_I_BEFORE}줄)" \
    || bad "재고 마이그레이션이 ${INV_MIG_WANT}줄이 아니다 (${MIG_I_AFTER:-?})"
  [ "${TBL_I_AFTER:-0}" = "$INV_TBL_WANT" ] \
    && ok "재고 표 ${TBL_I_AFTER}개 (전 ${TBL_I_BEFORE}개)" \
    || bad "재고 표가 ${INV_TBL_WANT}개가 아니다 (${TBL_I_AFTER:-?})"
  say "  🔴 개수만으로는 부족하다 — **이름을 하나씩** 센다 (새 표 아홉):"
  for t in $INV_NEW_TABLES; do
    [ "$(inv_tbl_has "$t")" = 1 ] && ok "표 $t 가 섰다" || bad "표 $t 가 **없다**"
  done
  say "  새 타입 넷:"
  for t in $INV_NEW_TYPES; do
    v=$(qi "select count(*) from pg_type where typname='$t'")
    [ "${v:-0}" = 1 ] && ok "타입 $t 가 생겼다" || bad "타입 $t 가 **없다** (${v:-?})"
  done
  say "  있던 표에 더해진 칸 아홉:"
  for t in $INV_NEW_COLS; do
    v=$(qi "select count(*) from information_schema.columns where table_name='${t%%:*}' and column_name='${t##*:}'")
    [ "${v:-0}" = 1 ] && ok "${t%%:*}.${t##*:} 칸이 생겼다" \
      || bad "${t%%:*}.${t##*:} 칸이 **없다** (${v:-?})"
  done
  say "  🔴 **지우는 문장이 지운 자리** — 그 두 표에 그 칸이 없어야 맞다:"
  for t in "oh_part_template_items:oh_price" "oh_part_templates:sort_order" \
           "oh_part_templates:code"; do
    v=$(qi "select count(*) from information_schema.columns where table_name='${t%%:*}' and column_name='${t##*:}'")
    [ "${v:-1}" = 0 ] && ok "${t%%:*}.${t##*:} 칸이 없다 (0012·0014 가 지웠다 — 맞다)" \
      || bad "${t%%:*}.${t##*:} 칸이 아직 있다 (${v}) — 적용이 덜 됐다"
  done
  say "  🔴 **줄 수가 그대로인가** (하나라도 줄었으면 자료가 사라진 것이다):"
  for t in $INV_COUNT_TABLES; do
    v=$(qi "select count(*) from $t" 2>/dev/null)
    b=$(printf '%s' "$CNT_BEFORE" | tr ' ' '\n' | sed -n "s/^inv:$t=//p")
    [ "${v:-x}" = "${b:-y}" ] && ok "재고 $t ${v}줄 — 그대로다" \
      || bad "🔴 재고 $t 가 ${b:-?} → ${v:-?} 로 **달라졌다**"
  done

  # ── 8. 🔴 A/S 1건 ───────────────────────────────────────────────────
  step "8. 🔴 A/S 적용 전 확인 — db:preflight (앱은 아직 $OLD_AS 로 살아 있다)"
  say "  🔴 0115 에는 **지우는 문장이 하나도 없다.** 그러니 「사라질 자료가"
  say "     있는 항목」이 나오면 그것이 신호다 — 멈춘다."
  "${COMPOSE[@]}" run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | sed 's/^/    /'
  PRC=${PIPESTATUS[0]}
  say "  (종료 코드 $PRC — 기대 0 · 대기 **1건**이어야 한다)"
  if [ "$PRC" != 0 ]; then
    bad "db:preflight 가 0 이 아니다 ($PRC) — 사라질 자료가 있다는 뜻이다"
    say "    → 🔴 0115 에는 그럴 문장이 없다. **다른 것이 섞였다.**"
    stop "A/S 마이그레이션을 시작하지 않았습니다. 직원은 $OLD_AS 를 쓰고 있습니다."
  fi
  step "9. 🔴 A/S 마이그레이션 적용 (0115)"
  "${COMPOSE[@]}" run --rm "$AS_TOOLS_SVC" npm run db:migrate 2>&1 | sed 's/^/    /'
  rc=${PIPESTATUS[0]}
  if [ "$rc" = 0 ]; then
    ok "db:migrate 끝 (종료 코드 0)"
  else
    bad "db:migrate 실패 (종료 코드 $rc)"
    say "    🔵 직원은 아직 $OLD_AS 를 쓰고 있습니다. 안 멈췄습니다."
    say "    🔴 **새 이미지를 띄우지 않습니다.** $TAG_AS 는 없는 칸을 읽습니다."
    cmd "bash $0 --migrate --drop-column-ok"
    stop "적용 직전 덤프: $BK/$AS_DB.dump"
  fi
  MIG_A_AFTER=$(as_mig_count)
  [ "${MIG_A_AFTER:-0}" = "$AS_MIG_WANT" ] \
    && ok "A/S 마이그레이션 ${MIG_A_AFTER}줄 (전 ${MIG_A_BEFORE}줄)" \
    || bad "A/S 마이그레이션이 ${AS_MIG_WANT}줄이 아니다 (${MIG_A_AFTER:-?})"
  v=$(qas "select count(*) from information_schema.columns where table_name='$AS_NEW_COL_TBL' and column_name='$AS_NEW_COL'")
  [ "${v:-0}" = 1 ] && ok "$AS_NEW_COL_TBL 에 $AS_NEW_COL 칸이 생겼다" \
    || bad "$AS_NEW_COL_TBL.$AS_NEW_COL 칸이 **없다** (${v:-?})"
  v=$(qas "select count(*) from pg_constraint where conname='$AS_NEW_CHECK'")
  [ "${v:-0}" = 1 ] && ok "CHECK 제약 $AS_NEW_CHECK 이 걸렸다" \
    || bad "CHECK 제약 $AS_NEW_CHECK 이 **없다** (${v:-?})"
  say "  🔵 새 칸이 든 줄은 아직 0건이 맞다:"
  say "      $(qas "select count(*) from $AS_NEW_COL_TBL where $AS_NEW_COL is not null")건"
  say "  🔴 **줄 수가 그대로인가**:"
  for t in $AS_COUNT_TABLES; do
    v=$(qas "select count(*) from $t" 2>/dev/null)
    b=$(printf '%s' "$CNT_BEFORE" | tr ' ' '\n' | sed -n "s/^as:$t=//p")
    [ "${v:-x}" = "${b:-y}" ] && ok "A/S $t ${v}줄 — 그대로다" \
      || bad "🔴 A/S $t 가 ${b:-?} → ${v:-?} 로 **달라졌다**"
  done
  say "  🔴 적용 뒤 preflight — **대기 0건**이어야 한다:"
  "${COMPOSE[@]}" run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | sed 's/^/    /'
  say "  (종료 코드 ${PIPESTATUS[0]})"

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL"
  echo "  🔴 DB 를 바꿨습니다. 두 사이트는 **아직 옛 판으로 돌고 있습니다.**"
  echo "     재고 ${MIG_I_BEFORE}줄 → ${MIG_I_AFTER:-?}줄 · 표 ${TBL_I_BEFORE}개 → ${TBL_I_AFTER:-?}개"
  echo "     A/S  ${MIG_A_BEFORE}줄 → ${MIG_A_AFTER:-?}줄"
  echo "  덤프: $BK"
  echo "  compose 사본: backups/docker-compose.nas.yml.$STAMP"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  if [ "$FAIL" != 0 ]; then
    echo
    echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
    echo "🔵 마이그레이션은 **다시 돌려도 안전합니다**:"
    echo "     bash $0 --migrate --drop-column-ok"
    exit "$FAIL"
  fi
  echo
  echo "✅ 이어서 바꿔 끼웁니다 (⏱ 여기부터가 정지 창입니다):"
  echo "     bash $0 --go"
  exit 0
fi
# ══ --go ═══════════════════════════════════════════════════════════════

# ── 2. 🔴 --migrate 가 끝났는지 **여기서 막는다** ─────────────────────
#
# 🔴 왜 막는가: 마이그레이션이 덜 된 DB 에 새 판이 뜨면 없는 표·칸을 읽다
#    그 자리에서 죽는다. --migrate 는 따로 부르는 명령이라 **빠뜨릴 수 있다.**
#    그래서 명령은 나눠 두고 순서만 기계가 지킨다(27번의 그 규율).
step "2. 🔴 --migrate 가 끝났는지 다시 센다 (바꿔 끼우기 전에)"
MIG_I_NOW=$(inv_mig_count); MIG_I_NOW=${MIG_I_NOW:-0}
TBL_I_NOW=$(inv_tbl_count); TBL_I_NOW=${TBL_I_NOW:-0}
MIG_A_NOW=$(as_mig_count);  MIG_A_NOW=${MIG_A_NOW:-0}
if [ "$MIG_I_NOW" != "$INV_MIG_WANT" ] || [ "$TBL_I_NOW" != "$INV_TBL_WANT" ] \
   || [ "$MIG_A_NOW" != "$AS_MIG_WANT" ]; then
  say "  ✗ 재고 ${MIG_I_NOW}줄 · 표 ${TBL_I_NOW}개 · A/S ${MIG_A_NOW}줄"
  say "    기대: 재고 ${INV_MIG_WANT}줄 · 표 ${INV_TBL_WANT}개 · A/S ${AS_MIG_WANT}줄"
  if [ "$MIG_I_NOW" -lt "$INV_MIG_WANT" ] 2>/dev/null \
     || [ "$MIG_A_NOW" -lt "$AS_MIG_WANT" ] 2>/dev/null; then
    say "    덜 들어갔다. 다시 돌려도 안전하다:"
    cmd "bash $0 --migrate --drop-column-ok"
  else
    say "    🔴 기대보다 **많다.** 이 배포가 모르는 마이그레이션이 들어갔다 —"
    say "       남의 변경이 섞였을 수 있다. 고치지 말고 **먼저 알리세요.**"
  fi
  stop "새 판을 띄우지 않았습니다. **아무것도 안 바꿨습니다.**"
fi
ok "재고 ${MIG_I_NOW}줄 · 표 ${TBL_I_NOW}개 · A/S ${MIG_A_NOW}줄 — --migrate 가 끝났다"
for t in $INV_NEW_TABLES; do
  if [ "$(inv_tbl_has "$t")" != 1 ]; then
    say "  ✗ 표 $t 가 없다 — 이대로 띄우면 그 화면이 42P01 로 죽는다"
    cmd "bash $0 --migrate --drop-column-ok"
    stop "새 판을 띄우지 않았습니다. **아무것도 안 바꿨습니다.**"
  fi
done
ok "새 표 아홉이 다 서 있다"
compose_swapped \
  || stop "compose 가 아직 옛 태그입니다. 먼저 --migrate 를 돌리세요. **아무것도 안 바꿨습니다.**"
ok "compose 가 새 태그 셋을 가리킨다"

# ── 3. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ───────────
step "3. 이미지 확인 · 필요하면 싣기 (tar 의 Config ↔ NAS 의 .Id)"
for rec in "$TAG_INV|$TAR_INV" "$TAG_INVTOOLS|$TAR_INVTOOLS" "$TAG_AS|$TAR_AS"; do
  tag=${rec%%|*}; tarf=${rec##*|}
  exp=$(tar_config_id "$tarf" 2>/dev/null) || exp=""
  if [ -z "$exp" ]; then
    bad "$tarf 에서 manifest.json 을 읽지 못했다"
    stop "이미지를 확인하지 못했습니다. **아무것도 안 띄웠습니다.**"
  fi
  bring_img "$tag" "$tarf" "$exp" || {
    say
    say "  🔴 이미지가 기대한 것과 다릅니다. **아직 아무것도 안 멈췄습니다.**"
    stop "바꿔 끼우기를 시작하지 않았습니다."
  }
done

# ── 4. 건드리지 않는 쪽의 시작 시각을 적어 둔다 ────────────────────────
#
# 🔴 「안 멈췄다」를 말로 하지 않는다. 바꾼 뒤에 이 값과 그대로인지 본다.
step "4. 건드리지 않는 여섯의 시작 시각을 적어 둔다 (뒤에서 대조한다)"
STARTED_BEFORE=""
for t in $KEEP_BOXES dss-pg-app dss-pg-auth; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  STARTED_BEFORE="$STARTED_BEFORE$t=$s
"
  say "  · $t  시작 ${s:-?}"
done

# 🔴 토큰은 **변수에만** 담는다. 화면에도 명령줄에도 안 나간다.
TK_RD=$(env_val "$AS_ENV" INVENTORY_API_TOKEN)
TK_WR=$(env_val "$AS_ENV" INVENTORY_WRITE_TOKEN)
TK_AS=$(env_val "$INV_ENV" AS_LOOKUP_TOKEN)

# ══ 5. ⏱ 정지 창 — 🔴 **재고 먼저** ═══════════════════════════════════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — compose 에 있는 것을 전부 띄우려 들고
#    DB 컨테이너까지 다시 만든다. --no-deps 로 **이름을 적은 하나만**.
# 🔴 따로 stop 하지 않는다. up -d 가 옛 컨테이너를 지우고 새것을 올리는 한
#    걸음이라, 나눠 부르면 그 사이만큼 정지 창이 길어진다.
step "5. ⏱ 정지 창 시작 — 먼저 **재고 관리**를 바꿔 끼운다 ($OLD_INV → $TAG_INV)"
say "  🔴 멈추는 것은 지금 **dss-inventory 하나**다. A/S 는 아직 $OLD_AS 로 돈다."
say "     그대로 도는 것: 포털 · 계측기 · 개선요청 · PO · 휴가 · 게시판 · DB 둘."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"
"${COMPOSE[@]}" up -d --no-deps "$INV_SVC" 2>&1 | sed 's/^/    /'
wait_http "재고 관리" "$INV_PORT" / "$INV_CNAME" \
  || stop "재고가 안 떴습니다. 🔴 **A/S 는 아직 $OLD_AS 로 멀쩡히 돌고 있습니다.**"
INV_UP_AT=$(date '+%F %T')
say "  ⏱ $STOP_AT → $INV_UP_AT · 재고 정지 약 $((SECONDS - T0))초"

# ══ 6. 🔴 여기가 이 배포의 핵심 — **A/S 를 띄우기 전에 통로를 값으로 본다** ══
#
#  🔴 「섰는가」가 아니라 「되는가」다. A/S 2.6 의 부품 요청 칸이 실제로
#     목록을 받아 오는 그 길을 **지금** 지나 본다 — A/S 컨테이너 안에서.
#  🔴 「맞으면 되나」만 보지 않는다. 토큰 없이도 눌러 **401 이 나오는지**를
#     함께 본다. 한 쪽만 보면 자격이 아예 안 걸린 상태를 통과시킨다.
#  🔴 여기서 ✗ 가 나면 **A/S 를 띄우지 않고 멈춘다.** 그래야 직원이 보는
#     A/S 는 여전히 멀쩡한 2.5 다.
step "6. 🔴 통로를 **값으로** 확인한다 (A/S 컨테이너 안에서 · 아직 $OLD_AS 다)"
say "  부르는 곳: $INV_BASE  ← 🔴 앱이 쓰는 바로 그 주소"
GATE=0

v=$(probe "$AS_CNAME" "$INV_BASE$P_PARTS" "$TK_RD" GET)
if judge_probe "읽기 토큰으로 $P_PARTS" "$v" "200" \
     "A/S 가 부품 목록을 못 받아 온다. 읽기 토큰 짝이 틀렸거나 비었다."; then
  n=$(probe_n "$v")
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then
    ok "🔴 부품이 **${n}줄** 왔다 — 목록이 실제로 넘어온다"
  else
    bad "🔴 200 인데 **줄이 ${n} 이다** — 빈 목록이 넘어왔다"
    say "      운영 재고에는 부품이 수백 줄 있어야 한다(전환일에 319줄 넣었다)."
    say "      DB 를 잘못 보고 있거나 전부 숨김 처리된 것이다."
    GATE=1
  fi
else
  GATE=1
fi
v=$(probe "$AS_CNAME" "$INV_BASE$P_PARTS" "" GET)
judge_probe "🔴 토큰 **없이** $P_PARTS (거절돼야 한다)" "$v" "401" \
  "자격이 안 걸려 있다 — 토큰 없이 부품 목록이 나간다" || GATE=1
v=$(probe "$AS_CNAME" "$INV_BASE$P_PARTS" "$TK_WR" GET)
judge_probe "🔴 **쓰기** 토큰으로 읽기 통로 (거절돼야 한다)" "$v" "401" \
  "읽기 토큰과 쓰기 토큰이 **같은 값**이다 — 둘을 가른 뜻이 사라진다" || GATE=1

v=$(probe "$AS_CNAME" "$INV_BASE$P_OHT" "$TK_RD" GET)
judge_probe "읽기 토큰으로 /api/v1/oh-templates" "$v" "200" \
  "O/H 템플릿 불러오기가 안 된다. 404 면 아직 $OLD_INV 가 떠 있는 것이다." || GATE=1
v=$(probe "$AS_CNAME" "$INV_BASE$P_OHT" "" GET)
judge_probe "🔴 토큰 없이 /api/v1/oh-templates (거절돼야 한다)" "$v" "401" \
  "자격이 안 걸려 있다" || GATE=1

v=$(probe "$AS_CNAME" "$INV_BASE$P_SREQ" "$TK_RD" GET)
judge_probe "읽기 토큰으로 /api/v1/stock-requests (되읽기)" "$v" "200 400" \
  "부품 요청 되읽기가 안 된다. 404 면 아직 $OLD_INV 다." || GATE=1
v=$(probe "$AS_CNAME" "$INV_BASE$P_SREQ" "" GET)
judge_probe "🔴 토큰 없이 /api/v1/stock-requests (거절돼야 한다)" "$v" "401" \
  "자격이 안 걸려 있다" || GATE=1

# 🔴 **쓰기 문**을 본다 — 그런데 DB 에는 한 줄도 안 쓴다.
#    읽기 토큰으로 POST 하면 문지기가 **본문을 읽기도 전에** 401 로 돌려보낸다
#    (그 라우트의 첫 두 줄이 checkApiWriteToken 이다). 503 이면 쓰기 토큰이
#    비어 통로가 닫힌 것이고, 200/201 이 나오면 두 토큰이 같은 값인 것이다.
say "  🔴 쓰기 문 — **DB 에는 한 줄도 안 쓴다**(자격에서 먼저 막히는 요청이다):"
v=$(probe "$AS_CNAME" "$INV_BASE$P_SREQ_POST" "$TK_RD" POST)
case "$(probe_code "$v")" in
  401) ok "🔴 읽기 토큰으로 POST → 401 — 쓰기 토큰이 **설정됐고 값이 다르다**" ;;
  503) bad "🔴 POST → 503 — 재고 쪽 INVENTORY_WRITE_TOKEN 이 **비었다**"
       say "      쓰기 통로가 닫혀 있다. 부품 요청을 **올릴 수 없다.**"; GATE=1 ;;
  400) bad "🔴 POST → 400 — 자격을 **통과했다**. 읽기와 쓰기가 같은 값이다"
       say "      🔴 본문이 비어 400 이 난 것이라 DB 에는 안 썼다. 그래도 문이 샌다."; GATE=1 ;;
  404) bad "🔴 POST → 404 — 아직 $OLD_INV 가 떠 있다"; GATE=1 ;;
  *)   bad "🔴 POST → $(probe_code "$v") — 뜻을 모르겠다"; GATE=1 ;;
esac

if [ "$GATE" != 0 ]; then
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 통로가 제 일을 하지 못합니다. **A/S 를 띄우지 않습니다.**     ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     직원이 보는 A/S 는 지금도 **$OLD_AS 로 멀쩡합니다.**"
  say "     🔴 대부분은 설정 여덟 중 하나입니다 — 아래로 다시 보세요:"
  cmd "bash $0"
  say "     고친 뒤 이어서(재고는 이미 $TAG_INV 입니다):"
  cmd "bash $0 --go"
  say "     되돌리려면:"
  cmd "bash $0 --rollback"
  stop "재고만 바뀌었습니다. **A/S 는 그대로입니다.**"
fi
ok "🔴 통로 전부가 값으로 대답했다 — 이제 A/S 를 띄운다"

# ══ 7. A/S 를 바꿔 끼운다 ══════════════════════════════════════════════
step "7. A/S 를 바꿔 끼운다 ($OLD_AS → $TAG_AS)"
say "  🔴 멈추는 것은 dss-as 하나다. 재고는 방금 떴고 그대로 돈다."
T1=$SECONDS
AS_STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $AS_STOP_AT"
"${COMPOSE[@]}" up -d --no-deps "$AS_SVC" 2>&1 | sed 's/^/    /'
T0=$T1
wait_http "A/S" "$AS_PORT" / "$AS_CNAME"
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T1))
say "  ⏱ $AS_STOP_AT → $UP_AT · A/S 정지 약 ${DOWN}초"

# ══ 8. 스모크 — 「섰는가」가 아니라 「되는가」 ══════════════════════════
step "8. 스모크 — 통로 양방향 · 표 · 엑셀 · 안 멈췄는가 · 바깥 주소"

say "  8-ㄱ. 컨테이너 둘이 살아 있는가"
for t in "$INV_CNAME" "$AS_CNAME"; do
  if running "$t"; then
    ok "$t 가 돌고 있다"
    say "      $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$t " || true)"
  else
    bad "$t 이 안 돌고 있다 — 떴다가 죽었다"
    cmd "$DOCKER logs --tail 50 $t"
  fi
done

say "  8-ㄴ. 🔴 A/S → 재고 — **새 판으로 다시** 두드린다"
v=$(probe "$AS_CNAME" "$INV_BASE$P_PARTS" "$TK_RD" GET)
judge_probe "읽기 토큰으로 $P_PARTS" "$v" "200" "부품 목록이 안 넘어온다" || true
n=$(probe_n "$v")
[ "${n:-0}" -ge 1 ] 2>/dev/null && ok "🔴 부품이 **${n}줄** 왔다" \
  || bad "🔴 부품이 ${n}줄이다 — 빈 목록이다"
v=$(probe "$AS_CNAME" "$INV_BASE$P_OHT" "$TK_RD" GET)
judge_probe "읽기 토큰으로 /api/v1/oh-templates" "$v" "200" "O/H 템플릿이 안 온다" || true

# ══════════════════════════════════════════════════════════════════════
#  🔴 8-ㄷ — **거꾸로 방향**. 여기가 A/S 2.6 에서 처음 열리는 문이다.
#
#  바꾸기 전에는 404 였다(2.5 에는 그 통로가 아예 없다). 이제 401/200 이
#  나오면 **이 배포가 한 일이 숫자 하나로 증명된다**(26번의 그 방식).
# ══════════════════════════════════════════════════════════════════════
say "  8-ㄷ. 🔴 재고 → A/S — 2.6 에서 **처음** 열리는 통로 셋"
say "      (바꾸기 전에는 404 였다. 이제 401/200 이어야 한다.)"
v=$(probe "$INV_CNAME" "$AS_BASE$P_AS_USERS" "" GET)
judge_probe "🔴 토큰 없이 $P_AS_USERS (거절돼야 한다)" "$v" "401" \
  "404 면 아직 $OLD_AS 다. 503 이면 as.env 의 AS_API_TOKEN 이 비었다." || true
v=$(probe "$INV_CNAME" "$AS_BASE$P_AS_USERS" "$TK_AS" GET)
if judge_probe "토큰으로 $P_AS_USERS" "$v" "200" \
     "재고의 결재자 고르개가 빈 채로 돈다 — AS_LOOKUP_TOKEN 짝이 틀렸다."; then
  n=$(probe_n "$v")
  [ "${n:-0}" -ge 1 ] 2>/dev/null && ok "🔴 결재자 후보가 **${n}명** 왔다" \
    || say "    ⚠️ 명부가 ${n}명이다 — 자격 넷(승인·활성·안 잠김·안 지움)을 다 지난 사람만 온다"
fi
v=$(probe "$INV_CNAME" "$AS_BASE$P_AS_MODELS" "$TK_AS" GET)
judge_probe "토큰으로 $P_AS_MODELS" "$v" "200" "제품 모델 목록이 안 온다" || true
v=$(probe "$INV_CNAME" "$AS_BASE$P_AS_INTAKE" "$TK_AS" GET)
# 🔴 2026-10-17 실측으로 고침 — 탐침이 보내는 `DSS-PROBE-0000` 은 **인수번호 모양이
#    아니다**. 그 통로는 모양이 틀리면 **400**("bad_request")을 돌려준다
#    (RF_Service_System 의 api/v1/intakes/[number]/route.ts 머리말: 400 모양 아님 ·
#     401 토큰 · 404 그런 건 없음).
# 🔵 **400 은 건강한 대답이다** — 토큰이 틀렸으면 401 에서 먼저 막혔을 테니,
#    400 이 왔다는 것은 **통로가 살아 있고 자격도 통과했다**는 뜻이다.
#    처음 판은 200|404 만 맞다고 보아 ✗ 를 냈다(배포는 멀쩡했는데 검사가 틀렸다).
case "$(probe_code "$v")" in
  200|404) ok "인수번호 조회 → $(probe_code "$v") (없는 번호라 404 도 맞다)" ;;
  400) ok "인수번호 조회 → 400 (탐침 번호가 모양이 아니다 — 🔵 자격은 통과했다는 뜻)" ;;
  401) bad "🔴 인수번호 조회 → 401 — 토큰 짝이 틀렸다" ;;
  503) bad "🔴 인수번호 조회 → 503 — as.env 의 AS_API_TOKEN 이 비었다" ;;
  *)   bad "🔴 인수번호 조회 → $(probe_code "$v")" ;;
esac
TK_RD=; TK_WR=; TK_AS=

say "  8-ㄹ. 재고 표 스물둘 · A/S 새 칸"
[ "$(inv_tbl_count)" = "$INV_TBL_WANT" ] && ok "재고 표 $INV_TBL_WANT개" \
  || bad "재고 표가 $(inv_tbl_count)개다"
for t in $INV_NEW_TABLES; do
  [ "$(inv_tbl_has "$t")" = 1 ] && ok "표 $t" || bad "표 $t 가 없다"
done
v=$(qas "select count(*) from information_schema.columns where table_name='$AS_NEW_COL_TBL' and column_name='$AS_NEW_COL'")
[ "${v:-0}" = 1 ] && ok "A/S $AS_NEW_COL_TBL.$AS_NEW_COL 칸이 있다" \
  || bad "A/S 의 새 칸이 없다"

# 🔴 **사람이 해야 하는 일 ③** 이 끝났는지 센다 — 넣지는 않는다.
say "  8-ㅁ. 🔴 승인 절차(결재선) — 넣지는 않고 **센다**"
v=$(qi "select count(*) from approval_routes")
if [ "${v:-0}" -ge 1 ] 2>/dev/null; then
  ok "approval_routes 에 ${v}줄이 있다"
  say "      단계: $(qi "select count(*) from approval_route_steps")줄"
else
  say "    ⚠️ approval_routes 가 **0줄이다** — 🔴 부품 불출 결재가 안 돕니다."
  say "       🔴 이것은 **사람이 재고 관리 화면에서** 저장해야 합니다."
  say "       (이 스크립트는 결재선을 만들지 않습니다 — 누가 결재하는지는"
  say "        사람이 정하는 일입니다.)"
fi

# 🔴 27번이 데인 자리 — 못 써도 화면에는 아무 오류가 안 뜬다.
say "  8-ㅂ. 🔴 도는 컨테이너가 공유폴더에 **실제로 쓰는가**"
OUTW=$("$DOCKER" exec "$INV_CNAME" sh -c '
  echo "WHO $(id -u):$(id -g)"
  if touch /data/workbook/.dss-write-test 2>/dev/null; then
    echo "LIVE WRITE_OK"
    rm -f /data/workbook/.dss-write-test 2>/dev/null
  else
    echo "LIVE WRITE_FAIL"
  fi
  if mkdir -p /data/.dss-mkdir-test 2>/dev/null; then
    echo "LIVE MKDIR_OK"
    rmdir /data/.dss-mkdir-test 2>/dev/null
  else
    echo "LIVE MKDIR_FAIL"
  fi' 2>&1)
printf '%s\n' "$OUTW" | grep -E '^(WHO|LIVE) ' | sed 's/^/      /'
printf '%s\n' "$OUTW" | grep -qx "WHO $UID_APP:$GID_APP" \
  && ok "🔴 uid $UID_APP · gid $GID_APP 으로 돈다 (공유폴더 ACL 이 이름으로 받아 준다)" \
  || bad "🔴 uid:gid 가 $UID_APP:$GID_APP 이 아니다 — 공유폴더에 못 쓴다"
case "$OUTW" in
  *"LIVE WRITE_OK"*)
    ok "🔴 **사내 공유폴더에 실제로 썼다**(바로 지웠다) — 현황판이 직원에게 간다" ;;
  *"LIVE WRITE_FAIL"*)
    bad "🔴 공유폴더에 **못 쓴다** — 현황판 엑셀이 영영 안 만들어진다"
    say "      🔴 화면은 멀쩡하게 뜹니다. 오류도 안 납니다. 여기서만 보입니다." ;;
  *) bad "판정하지 못했다"; printf '%s\n' "$OUTW" | sed 's/^/      /' | head -6 ;;
esac
case "$OUTW" in
  *"LIVE MKDIR_OK"*)   ok "폴더도 만든다 (baseline · backup · OLD 가 이렇게 생긴다)" ;;
  *"LIVE MKDIR_FAIL"*) bad "🔴 폴더를 못 만든다 — 백업 폴더가 영영 안 생긴다" ;;
esac
say "  8-ㅅ. 🔴 엑셀 자동 갱신이 켜져 있는가 (로그에서 읽는다)"
LOGS=$("$DOCKER" logs --tail 120 "$INV_CNAME" 2>&1)
case "$LOGS" in
  *"엑셀 한 벌 자동 갱신 켜짐"*) ok "🔴 1분 주기 자동 갱신이 켜졌다" ;;
  *"자동 갱신 꺼짐"*)
    bad "🔴 자동 갱신이 **꺼져 있다** — inventory.env 에 WORKBOOK_SYNC_DISABLED 가 남았다" ;;
  *) say "    ⚠️ 로그에서 판정하지 못했다. 직접 보세요:"; cmd "$DOCKER logs --tail 50 $INV_CNAME" ;;
esac

say "  8-ㅇ. 🔴 **건드리지 않은 여섯이 정말 안 멈췄는가** (시작 시각으로 본다)"
for t in $KEEP_BOXES dss-pg-app dss-pg-auth; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  b=$(printf '%s\n' "$STARTED_BEFORE" | sed -n "s/^$t=//p")
  [ -n "$s" ] && [ "$s" = "$b" ] && ok "$t 시작 시각 그대로 ($s)" \
    || bad "🔴 $t 의 시작 시각이 달라졌다 (전 ${b:-?} / 후 ${s:-?}) — 함께 멈췄다"
done
say "  8-ㅈ. 바깥 주소 여덟"
for t in inventory as $KEEP_HOSTS; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$t.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$t.dss21.co.kr → $code" ;;
    *)       bad "🔴 https://$t.dss21.co.kr → ${code:-없음}" ;;
  esac
done
say "  열린 포트 (🔴 127.0.0.1 만이어야 한다):"
netstat -tln 2>/dev/null | grep ':13[0-9]\{3\}' | sed 's/^/      /'
say "  지금 도는 이미지:"
"$DOCKER" ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | sed 's/^/      /'
say "  🔴 메모리 — 이 값을 Claude 에게 알려 주세요(compose 예산표를 다시 적습니다):"
"$DOCKER" stats --no-stream --format '{{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}' 2>/dev/null \
  | sed 's/^/      /'
free -m 2>/dev/null | sed 's/^/      /'

# ══ 9. 마무리 ══════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  ⏱ 재고 $STOP_AT → $INV_UP_AT · A/S $AS_STOP_AT → $UP_AT (약 ${DOWN}초)"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" != 0 ]; then
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
  echo "되돌리기 안내:  bash $0 --rollback"
  exit "$FAIL"
fi
cat <<ANNOUNCE

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. https://as.dss21.co.kr — 수리 건 상세의 **부품 요청** 칸
      · 🔴 부품 목록이 **뜹니까**(「확인하지 못했습니다」가 아니라)
      · 🔴 한 줄 담아 **올려 봅니다** — 여기가 쓰기 토큰이 걸리는 자리입니다.
        읽기만 되고 올리기가 안 되면 쓰기 토큰 짝이 틀린 것입니다.
      · O/H 템플릿 불러오기 · 견적서의 인수번호 불러오기
   2. 🔴 A/S 메뉴에 **재고가 안 보입니까** (이번 판이 감춥니다)
      · 북마크로 /inventory 에 들어가면 **열리되 안내 띠**가 보여야 합니다
      · 🔴 그 띠의 링크를 **눌러 보세요** — https://inventory.dss21.co.kr 로
        가야 합니다. 안 열리면 as.env 의 INVENTORY_API_BASE_URL 이
        컨테이너 안 주소로 적힌 것입니다(서버 호출은 되는데 링크만 죽습니다).
   3. https://inventory.dss21.co.kr — 승인 절차(결재선) 화면
      · 🔴 **결재자 고르개에 사람이 뜹니까** (A/S 명부를 읽어 옵니다)
      · 🔴 결재선을 **저장해 주세요** — 없으면 부품 불출 결재가 안 돕니다
      · 반출 신청에서 **인수번호를 넣어** 확인이 되는지
   4. 🔴 **포털 · 계측기 · 개선요청 · PO · 휴가 · 게시판이 그대로입니까** —
      이 배포는 그 여섯을 건드리지 않았습니다.
   5. 현황판 엑셀이 사내 공유폴더에서 **열립니까** (1분 뒤 시각이 바뀝니다)

🔴 사람이 이어서 할 일:
  · **내일 아침** 백업을 보세요 — 스케줄러가 실제로 돌려서 덤프 일곱과
    files 둘이 생기는지가 진짜 확인입니다. 🔴 새 표 아홉이 담겼는지는
    덤프 크기가 커진 것으로 가늠하고, 미심쩍으면 알려 주세요:
      ls -lt /volume1/dss/backups/db/ | head -9
      ls -l  /volume1/dss/backups/files/
  · 위 메모리 값을 Claude 에게 알려 주세요.
  · 🔴 role_permissions 의 inventory% 를 다시 보세요(--check 가 보여 줍니다).
    부품 요청이 안 되는 사람이 있으면 거기부터입니다.

🔴 되돌리기:  bash $0 --rollback
   · 되돌릴 것 셋 — compose 사본 · as-migrations.old · predeploy 덤프
   · 🔵 **DB 는 되돌리지 않는 것이 기본입니다.** 옛 판이 그대로 돕니다.
ANNOUNCE
exit "$FAIL"
# ══════════════════════════════════════════════════════════════════════
#  사람이 칠 명령 — 🔴 **딱지를 보고 치세요**
#
#  🔴 이 PC 는 PowerShell 5.1 입니다. && 도 < 도 for…do…done 도 없습니다.
#     여러 줄 붙여넣기와 중첩 따옴표가 두 번 깨졌으니, 길면 .ps1 파일로
#     만들어 돌리세요:  powershell -ExecutionPolicy Bypass -File 파일.ps1
#  🔴 NAS 에서 칠 것은 bash 입니다.
#  🔴 docker build · docker save · tar 는 **사용자가 직접** 칩니다
#     (분류기가 막고, tar 가 C: 를 원격 호스트로 읽습니다 — 그래서 아래는
#      전부 **상대경로**입니다. 먼저 Development 폴더로 들어가세요).
# ══════════════════════════════════════════════════════════════════════
#
# ── 【Windows · PowerShell】 ① 굽는다 ─────────────────────────────────
#
#   cd C:\Users\희만\Desktop\Development\dss-inventory
#   git status --short
#   git log --oneline -1
#     🔴 비어 있어야 하고, 맨 위가 00c92e6 이어야 합니다.
#   docker build -t dss-inventory:0.2 .
#   docker build --target tools -t dss-inventory-tools:2 .
#     🔴 --target tools 를 빠뜨리면 **앱 이미지를 도구로** 굽습니다.
#        그러면 tsx 가 없어 --migrate 가 그 자리에서 죽습니다.
#
#   cd ..\RF_Service_System
#   git status --short
#   git log --oneline -1
#   git submodule status
#     🔴 비어 있어야 하고, bf48033 · vendor/dss-core 가 2ecdf01 이어야 합니다.
#     🔴 「git archive」 로 뽑지 마세요 — 서브모듈이 **빈 폴더**로 나와
#        빌드가 깨집니다. 작업 폴더에서 굽되 git status 가 비어 있어야 합니다.
#   docker build -t dss-as:2.6 .
#
# ── 【Windows · PowerShell】 ② tar 로 뜨고 **잰다** ───────────────────
#
#   cd C:\Users\희만\Desktop\Development
#   docker save dss-inventory:0.2       -o dss-inventory-0.2.tar
#   docker save dss-inventory-tools:2   -o dss-inventory-tools-2.tar
#   docker save dss-as:2.6              -o dss-as-2.6.tar
#
#   (Get-Item dss-inventory-0.2.tar).Length          ← SZ_INV
#   Get-FileHash -Algorithm MD5 dss-inventory-0.2.tar ← MD5_INV (소문자로)
#   tar -xOf dss-inventory-0.2.tar manifest.json      ← "Config" → WANT_CFG_INV
#     🔴 「blobs/sha256/abc…」 꼴로 나옵니다. 앞의 「blobs/」 를 떼고
#        「sha256:abc…」 모양으로 적습니다.
#   (셋을 다 똑같이 — tools 와 as 도)
#
#   🔴 **tar 는 상대경로로만** 칩니다. C:\… 로 적으면 tar 가 그 앞을
#      원격 호스트 이름으로 읽어 실패합니다.
#   🔴 tar 가 이미지의 1/4 쯤인 것은 **정상**입니다. 지난 판과 견주세요:
#      dss-inventory-0.1.tar 95,283,712 · dss-inventory-tools-1.tar 212,687,872
#
# ── 【Windows · PowerShell】 ③ A/S 마이그레이션 묶음 ─────────────────
#
#   cd C:\Users\희만\Desktop\Development\RF_Service_System
#   tar -czf ../as-migrations-2.6.tar.gz drizzle
#   cd ..
#     🔴 묶음의 뿌리가 「drizzle/」 이어야 합니다(스크립트가 --strip-components=1
#        로 풉니다). .sql 116장 + meta/_journal.json + snapshot 116개가
#        함께 들어가야 합니다 — .sql 한 장만 넣으면 적용이 **조용히 0건**으로
#        끝납니다.
#
# ── 【Windows · PowerShell】 ④ 아홉 칸을 채우고 올린다 ───────────────
#
#   🔴 위에서 잰 아홉을 이 파일의 SZ_* · MD5_* · WANT_CFG_* 에 채운 **뒤**
#      올립니다. 비어 있으면 --migrate 도 --go 도 시작하지 않습니다.
#
#   cd C:\Users\희만\Desktop\Development
#   scp -O dss-inventory-0.2.tar     dss-nas:/volume1/dss/images/
#   scp -O dss-inventory-tools-2.tar dss-nas:/volume1/dss/images/
#   scp -O dss-as-2.6.tar            dss-nas:/volume1/dss/images/
#   scp -O as-migrations-2.6.tar.gz dss-nas:/volume1/dss/setup/incoming/as-migrations.tar.gz
#   scp -O dss-deploy\nas\setup\28-deploy.sh dss-nas:/volume1/dss/setup/
#   Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\28-deploy.sh
#
#   🔴 **scp 에 -O 를 붙입니다** — DSM 에 sftp 서버가 없어 없으면 실패합니다.
#   🔴 **마이그레이션 묶음은 이름이 바뀝니다** — as-migrations.tar.gz 로.
#   🔴 **compose 는 올리지 않습니다.** 저장소 사본은 재고 관리 두 블록이
#      아직 주석이라, 올리면 재고 관리가 통째로 사라집니다(머리말 ⑤절).
#   🔴 Git Bash 의 ssh/scp 로는 NAS 에 못 붙습니다(한글 사용자 폴더).
#      PowerShell 의 것(C:\WINDOWS\System32\OpenSSH\scp.exe)을 쓰세요.
#   🔵 scp 가 바로 안 되면 swhur 홈으로 올린 뒤 NAS 에서 sudo mv 로 옮깁니다.
#
# ── 【NAS · bash】 ⑤ md5 를 맞추고 돌린다 ────────────────────────────
#
#   md5sum /volume1/dss/setup/28-deploy.sh
#     🔴 위 Get-FileHash 값과 **같아야** 돌립니다. 다르면 다시 올립니다.
#        (DSM 터미널이 긴 명령을 잘라 먹어 하루에 네 번 깨진 적이 있습니다.)
#
#   sudo -i
#   bash /volume1/dss/setup/28-deploy.sh                    ← 읽기만
#   bash /volume1/dss/setup/28-deploy.sh --preload          ← 이미지 셋
#   bash /volume1/dss/setup/28-deploy.sh                    ← 다시 읽기만
#   bash /volume1/dss/setup/28-deploy.sh --migrate --drop-column-ok
#   bash /volume1/dss/setup/28-deploy.sh --go
#
#   🔴 **첫 --check 와 --migrate 사이에** 설정 여덟을 적어야 합니다.
#      --check 가 그 틀을 찍어 줍니다(28-env-add.sh).
#   🔴 야간 백업은 02:30 입니다. 자정을 넘겨 돌리면 --migrate 가 막힙니다 —
#      그때는 먼저:  bash /volume1/dss/jobs/backup-nightly.sh
#
# ── 【NAS · bash】 되돌리기 ──────────────────────────────────────────
#
#   bash /volume1/dss/setup/28-deploy.sh --rollback
#     (아무것도 바꾸지 않고 명령만 찍습니다. 치는 것은 사람입니다.)
#
# ══════════════════════════════════════════════════════════════════════
