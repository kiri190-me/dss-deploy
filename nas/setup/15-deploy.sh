#!/bin/bash
# /volume1/dss/setup/15-deploy.sh — 2026-09-30 열째 배포
#
# ── 무엇이 올라가는가 ───────────────────────────────────────────────────
#   사내 사이트 여섯 중 **둘**을 올린다.
#
#     A/S      dss-as:1.7  →  **dss-as:1.8**
#     PO/내자  dss-po:0.2  →  **dss-po:0.3**
#
#   나머지 넷(포털 · 계측기 · 개선요청 · 휴가)은 **건드리지 않는다.**
#
# ── 이 판에 무엇이 담겼나 (사람에게 설명할 말로) ────────────────────────
#
#   ① 🔴 **엔지니어에게 내자 정리와 견적서를 열었다** — 이번 판의 핵심이다.
#      2026-09-29 사용자 결정, 원문 「엔지니어도 PO/내자에 모두 읽기/쓰기 할 수
#      있어야 해」. A/S 와 PO 가 **같은 DB 를 보고 권한 열쇠도 같아서** 한쪽만
#      올리면 같은 사람이 A/S 에서는 되고 PO 에서는 안 되는 상태가 된다.
#      그래서 **둘을 함께 올린다.** 열린 것은 셋이다:
#        내자 정리(domesticOrders) 쓰기 · 견적서(quotes) 쓰기 ·
#        작업 비용(repairLabor) 보기
#      🔴 삭제 · 휴지통 · 복원 · 완전 삭제는 관리자 이상 그대로다.
#         재고 담당자는 한 글자도 안 바뀌었다.
#
#   ② 사진 손보기 — 크게 보기에 확대 · 회전 · 뒤집기, 아래 썸네일 줄,
#      돌린 것을 원본에 저장, 여러 장 한 번에 돌리기, Shift 연속 고르기,
#      미리보기가 잘리지 않게(맞춰 넣기).
#
#   ③ 수리 건 상세에 **「내자 정리 발행일」 구역** — 견적서 발행일 · PO 발행일.
#      연결된 내자 줄에서 가져와 보여 주고 고칠 수 있다. 🔴 **내자 줄이 하나도
#      없으면 저장이 줄을 하나 만든다.**
#
#   ④ 「PO 발행 일시」 → **「PO 발행일」** 로 이름 통일. 칼럼이 date 라 시각이
#      없어서다(2026-09-29 사용자 결정). 주간보고 상세표의 머리말과 인쇄물에도
#      새 이름으로 찍힌다.
#      ⚠️ 이 이름 통일은 **A/S 쪽 일이다.** PO 저장소에는 「PO 발행 일시」라는
#         글자가 처음부터 없었다(2026-09-30 실측). PO 쪽 0.3 에 담긴 것은
#         위 ① 의 권한 변경과 사내 공용 메뉴바 묶음(vendor/dss-ui) 포인터
#         갱신 둘이다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/15-deploy.sh            ← 읽기만 한다
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#
#   11번부터 이어온 약속을 그대로 잇는다 — **인자 없이 돌리면 --check**.
#   실수로 그냥 돌려도 아무것도 바뀌지 않는다(로그 파일 하나만 남는다).
#   코드로는 아래 세 줄이 그 약속이다:
#     · MODE=check        (모드 절의 첫 줄)
#     · FORCE_LOAD=0      (같은 태그를 덮어쓰지 않는다)
#     · PROBE_WRITE=0     (--check 는 폴더에 시험 파일도 만들지 않는다)
#
#   🔴 한 가지는 정직하게 적어 둔다 — --check 도 이미지 **안을 보려고**
#      컨테이너를 잠깐 띄웠다 지운다(docker run --rm … sh -c 'grep …').
#      디스크에도 DB 에도 아무것도 남기지 않고 도는 사이트를 건드리지도
#      않지만, 「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가
#      정확한 말이다. 13-deploy.sh 머리말의 그 문장을 그대로 잇는다.
#
# ── 모드 다섯 ───────────────────────────────────────────────────────────
#   (없음) · --check     읽기만 한다. 아무것도 안 바꾸고 안 멈춘다      ← 기본값
#   --preload            새 이미지 둘을 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --go                 🔴 **A/S 와 PO 둘만** 교체한다 (나머지 넷은 안 멈춘다)
#   --rollback           태그 되돌리기 안내
#
#   `--force-load` 는 `--go` 와 같이 써도 된다 — 그때는 --go 가 싣는 자리에서
#   have_img 검사를 건너뛴다:  bash 15-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 15-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 15-deploy.sh --preload       (새 이미지 둘을 미리 실어 둔다)
#   3) bash 15-deploy.sh                 (다시 읽기만 — 이번엔 지문까지 다 본다)
#   4) bash 15-deploy.sh --go            (A/S 와 PO 를 함께 교체)
#
# ══ 🔴 마이그레이션은 **0개**다 ════════════════════════════════════════
#
#   스키마를 한 글자도 안 건드렸다. 개발 PC 에서 `npm run db:preflight` 실측
#   결과가 **전체 106건 · 적용 대기 0건**이다. 교차 확인도 했다 —
#   `git diff --stat 733f8ed..HEAD -- drizzle/` 가 **빈 줄**이다(66개 파일이
#   바뀌었는데 drizzle/ 은 하나도 없다).
#
#   · **새 SQL 을 적용하지 않는다.** 이 스크립트에는 마이그레이션 적용 단계가
#     아예 없다. `db:migrate` 를 부르는 줄이 한 줄도 없다.
#   · 대신 「코드의 마이그레이션 수(106) = 운영 DB 의 적용 수」가 맞는지
#     **확인만** 한다(1-ㄹ). 어긋나면 그것이 곧 신호다 — 멈추고 사람에게
#     알린다. 세는 자리는 셋이다:
#       ㄱ) /volume1/dss/as-migrations/*.sql 의 개수
#       ㄴ) 그 폴더의 meta/_journal.json 안의 tag 줄 수
#       ㄷ) dss_as 의 drizzle.__drizzle_migrations 줄 수
#     🔴 A/S 의 drizzle/ 은 **이미지 안이 아니라 볼륨**이다(compose 의
#        tools-as: /volume1/dss/as-migrations:/app/drizzle:ro). 그래서 ㄱㄴ 은
#        NAS 의 폴더를 그대로 읽으면 된다.
#   · **도구 이미지 dss-as-tools:1 도 다시 굽지 않았다.** 대기 커밋이
#     drizzle/ 을 전혀 안 건드렸고, 애초에 drizzle/ 은 그 이미지에 없다.
#   · PO 저장소에는 **마이그레이션이 아예 없다**(drizzle/ 도 drizzle.config.ts
#     도 db:migrate 도 없다 — dss-po/src/lib/db/index.ts 가 그렇게 못 박았다).
#     그래서 compose 에 tools-po 라는 서비스도 없는 것이 맞다.
#
#   🔴 그러니 --rollback 에도 **DB 를 되돌리는 일이 없다.** 이 스크립트에는
#      자료를 바꾸는 SQL 이 한 줄도 없다 — 전부 select 다.
#
# ══ 🔴 건드리지 않는 여덟 ══════════════════════════════════════════════
#
#     dss-auth:1.5              dss-as-tools:1
#     dss-meters:1.3            dss-meters-tools:1
#     dss-improvements:0.3      dss-improvements-tools:2
#     dss-leave:0.1             dss-leave-tools:1
#
#   전부 지금 운영에서 돌고 있다. compose 에서 이 태그가 흔들렸으면 **남의
#   변경이 섞인 것**이다 — 두 세션이 같은 저장소를 쓴다(HANDOFF A절). 실제로
#   일어나는 일이다. 고치지 말고 **먼저 알린다.**
#
# ══ 🔴 이번 배포에만 있는 검사 셋 ══════════════════════════════════════
#
# ── 【검사 ①】 엔지니어 권한이 **진짜로** 열리는가 (1-ㄷ · --check 에서 본다)
#
#   이번 판의 핵심은 엔지니어에게 내자 정리·견적서를 연 것이다. 그런데
#   **코드를 배포해도 안 열릴 수 있다.** A/S 의 판단이 이렇기 때문이다
#   (src/lib/auth/permission-resolver.ts):
#
#     level = higherPermissionLevel(level,
#               configured[leafKey] ?? baselineLeafLevel(leafKey, role));
#
#   칸(leafKey) 하나하나마다, **DB 에 저장된 값이 있으면 그 값이 이기고**
#   없을 때만 코드의 기본 정책을 본다. 관리자가 화면 [사용자 관리 → 역할별
#   접근 권한]에서 그 칸을 저장해 둔 적이 있으면 DB 에 줄이 남아 있고,
#   그러면 **배포해도 엔지니어에게 안 열린다.**
#
#   → 1-ㄷ 이 운영 DB(dss_as · 컨테이너 dss-pg-app)의 role_permissions 표를
#     **select 만으로** 읽어, AS_ENGINEER 의 그 칸들에 저장된 값이 있는지
#     찍는다. 표·칸 이름은 짐작하지 않았다 — 아래 자리에서 직접 읽었다:
#
#       표·칸   RF_Service_System/vendor/dss-core/src/schema/role-permissions.ts
#               (32~45행. 표 role_permissions, 칸 role · area_key · level ·
#                updated_by · updated_at. 🔴 칸 이름은 leaf_key 가 아니라
#                **area_key** 다 — 이름이 낡았다)
#               RF_Service_System/drizzle/0042_role_permissions.sql 로 교차 확인
#       역할    RF_Service_System/vendor/dss-core/src/schema/users.ts 17~22행
#               pgEnum("role_code", [...]) → **AS_ENGINEER** (대문자)
#       레벨    RF_Service_System/src/lib/auth/permission-areas.ts 32행
#               NONE < READ < WRITE < MANAGE
#       칸 값   RF_Service_System/src/lib/auth/permission-areas.ts 224 · 236 ·
#               245행 → **domesticOrders · quotes · repairLabor** (camelCase)
#               dss-po/src/lib/auth/permission-areas.ts 87 · 102 · 114행도 같다
#       기본값  RF_Service_System/src/lib/auth/permission-baseline.ts 266~301행
#               + domestic-order-authorization.ts 55~62행(이번에 AS_ENGINEER 가
#               더해진 그 줄) → AS_ENGINEER 는 WRITE · WRITE · READ
#
#   🔴 **select 만 쓴다.** 어떤 모드에서도 이 표를 고치지 않는다. 고치는 곳은
#      A/S 의 화면 하나뿐이고, 그것은 사람이 브라우저에서 할 일이다.
#
#   ⚠️ 지시서에 「한 번이라도 저장했으면 줄이 남아 있다」고 적혀 있었는데
#      **정확하지 않다.** 저장하는 쪽(RF_Service_System/src/lib/db/mutations/
#      role-permissions.ts 188~204행)은 값이 기본값과 **같으면 줄을 없앤다.**
#      그러니 옛 기본값(NONE)으로 저장한 것은 줄이 안 남고, 배포하면 그대로
#      열린다. 줄이 남는 것은 옛 기본값과 **다르게** 저장했을 때뿐이다.
#      검사가 필요 없다는 뜻이 아니다 — 줄이 있으면 그 값이 이기는 것은
#      그대로다. 다만 「줄이 있을 것」이라고 미리 겁먹지 않는다.
#
#   ⚠️ 그리고 셋을 본다. 지시서는 내자 정리·견적서 둘만 말했지만, **작업
#      비용(repairLabor)도 함께 따라 열렸다**(READ). 견적서 판정을 그대로
#      불러 쓰기 때문이다(permission-baseline.ts 288~301행). 같이 봐야 한다.
#
# ── 【검사 ②】 알림 링크의 주소 — A/S 만 (1-ㅊ · 5-ㄹ)
#
#   🔴 PO 에는 알림 통로가 **없다.** 12-deploy.sh 가 이미 실측해 적어 두었다:
#      api/integration 폴더가 계측기와 PO 두 저장소에 아예 없다. 2026-09-30 에
#      다시 확인했다 — dss-po/src/app/api 아래에 integration 이 없다. PO 의
#      알림은 포털이 모아 준 것을 **받아서 그리기만** 한다. 그러니 **없는 것을
#      찾지 않는다.** 통로가 있는 곳은 A/S 와 개선요청 둘뿐이다.
#
#   🔴 이 검사가 있는 까닭: 2026-09-29 에 「통로가 열려 있는가」만 보고
#      통과시켰는데, 그 통로가 내준 주소가 http://172.20.0.7:3500/ (도커 내부
#      주소)라 **밖에서 닿지 않았다.** 「있는가」가 아니라 「제 일을 하는가」를
#      본다. A/S 는 SSO_REDIRECT_URI 에서 자기 주소를 뽑는다
#      (src/lib/config/sso.ts 83~111행의 getAppBaseUrl).
#
# ── 【검사 ③】 야간 작업이 실제로 돌고 있는가 (1-ㅇ · 앞 세션이 남긴 숙제)
#
#   · **야간 백업** — backups/db/ 에 **DB 다섯**(dss_auth · dss_meters ·
#     dss_as · dss_improvements · dss_leave)이 **02:30 도장**으로 있는지 본다.
#     🔴 개선요청이 9/18~9/29 **11일간 백업에서 빠져 있으면서 매일 「성공」으로
#        끝난** 일이 있었다. 없는 줄은 실패하지 않기 때문이다. 도장 시각과
#        DB 다섯이 유일한 증거다.
#   · **야간 완전삭제(DSM 작업 「DSS Purge」)** — setup/logs/purge-*.log 가
#     있는지 본다. 지울 것이 0건이라 「영구 삭제 0 건 · 성공」이면 맞다.
#     🔴 **로그가 아예 없으면 스케줄러에 등록이 안 된 것**이고, 그러면 휴지통이
#        한 번도 안 비워지고 있다는 뜻이다. 화면은 「15일 뒤 자동 삭제」라고
#        말하는데 실제로는 안 지워지고 있는 상태다. 그렇게 알린다.
#   · 🔴 이 셋은 **읽기만** 한다. 등록하거나 고치려 들지 않는다 — 그건 사람이
#     DSM 작업 스케줄러 화면에서 할 일이다.
#
# ══ 12번에서 그대로 이어받는 것 ════════════════════════════════════════
#
#   ① 같은 태그로 다시 구운 이미지는 조용히 안 실린다 → --force-load
#   ② 폴더 권한은 **컨테이너 안에서 실제로 열어 본다**(주인·모드만 보면
#      Synology ACL 을 놓친다). 이번에 교체되는 둘은 쓰기까지 보고(--go),
#      교체 안 되는 곳은 「아직 읽히는가」만 본다.
#   ③ 이미지는 태그가 아니라 **안을 본다**(1-ㅋ).
#   ④ 사람이 칠 명령은 **한 줄 76자 안쪽**. DSM 의 ash 에 긴 줄을 붙여넣으면
#      터미널 폭에서 줄바꿈되며 개행이 끼어들어 **줄이 잘린다.** cmd() 가
#      그것을 검사하고, 길 수밖에 없는 것은 script_file_hint() 로 넘긴다.
#   ⑤ 견적서 공유폴더는 **chmod 로 ACL 을 걷으면 안 된다** — 직원의 탐색기
#      접근이 끊긴다. 못 쓰면 compose 의 group_add: ["100"] 부터 본다.
#   ⑥ 컨테이너가 docker ps 에 보이는 것과 앱이 대답하는 것은 다르다.
#      wait_http 로 대답할 때까지 기다리고, 그 시각으로 멈춘 시간을 잰다.
#
# ── 참고 · 개발 PC 에서 잰 값 (2026-09-30) ─────────────────────────────
#   아래 지문은 **아무 검사에도 쓰지 않는다.** 사람이 손으로 맞춰 볼 일이
#   생겼을 때를 위한 메모다. 기대 지문은 tar_config_id() 가 tar 안에서 직접
#   읽는다 — 12번이 하는 그대로다.
#     dss-as:1.8 →
#       sha256:143402e6423d6704d942f34d3c96ad1d72f9b6288c0a5fb93c39e380f3230146
#     dss-po:0.3 →
#       sha256:21dd1749af94a75e21c942d9268fe4ed935ed0d0366dc77b09b7260750927b4b
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
TODAY=$(date +%F)
CF=$D/deploy/docker-compose.nas.yml
INCOMING=$D/setup/incoming/docker-compose.nas.yml
ENV_NAS=$D/deploy/.env.nas
ENVD=$D/deploy/env
IMAGES=$D/images
BKD=$D/backups

# ── 🔴 이번에 올라가는 것 **둘** ───────────────────────────────────────
TAG_AS=dss-as:1.8
TAG_PO=dss-po:0.3
# 되돌릴 자리 (지금 도는 것)
OLD_AS=dss-as:1.7
OLD_PO=dss-po:0.2

# ── 🔴 **건드리지 않는 여덟.** ─────────────────────────────────────────
# 전부 지금 운영에서 돌고 있다. compose 에서 이 태그가 흔들렸으면 남의 것이
# 섞인 것이다(두 세션이 같은 저장소를 쓴다 — HANDOFF A절). 고치지 말고 알린다.
KEEP_AUTH=dss-auth:1.5
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_METERSTOOLS=dss-meters-tools:1
KEEP_IMP=dss-improvements:0.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_LEAVE=dss-leave:0.1
KEEP_LEAVETOOLS=dss-leave-tools:1

# ── tar 둘 ─────────────────────────────────────────────────────────────
# 🔴 둘 다 **비압축 .tar** 다(.tar.gz 가 아니다). tar_config_id() 는 둘 다
#    읽지만 이번 것은 비압축이다.
# 🔴 건드리지 않는 여덟의 tar 는 **요구하지 않는다** — 이미 실려서 돌고 있으므로
#    tar 가 지워졌어도 이 배포에는 아무 상관이 없다. 대신 「NAS 에 그 이미지가
#    실려 있는가」를 1-ㄴ 에서 본다.
TAR_AS=$IMAGES/dss-as-1.8.tar
TAR_PO=$IMAGES/dss-po-0.3.tar
# 개발 PC 실측 (2026-09-30). **파일 전송이 온전한지** 보는 값이다 —
# 이미지의 지문(sha256)은 tar_config_id() 가 tar 안에서 따로 읽어 낸다.
SZ_AS=113512960;  MD5_AS=2a073760cad6dc0ed12dd3876c5384c4
SZ_PO=95373824;   MD5_PO=8a1af7c7f1f69a38259b76942d3ea5b4

# ── 포트 (compose 의 ports: 에서 읽어 확인했다 — 짐작이 아니다) ────────
#   포털 13100 · A/S 13000 · 계측기 13300 · 개선요청 13500 ·
#   PO 13600 · 휴가 13700
AS_PORT=13000
PO_PORT=13600

# ── 마이그레이션 — 🔴 **적용하지 않는다. 수만 센다** ───────────────────
AS_DB=dss_as
N_MIG_WANT=106                 # 개발 PC preflight 실측: 전체 106 · 대기 0
MIGDIR=$D/as-migrations        # compose 가 tools-as 의 /app/drizzle 로 붙인다

# ── 【검사 ①】 권한 — 표·칸·역할·값은 전부 소스에서 읽었다 (머리말 참조) ─
PERM_TABLE=role_permissions
PERM_ROLE=AS_ENGINEER
PERM_KEYS="domesticOrders quotes repairLabor"

# ── 컨테이너 안에서 실제로 열어 볼 폴더 ────────────────────────────────
ATT=$D/as-attachments
TEMPLATES=$D/as-templates
UP_IMP=$D/improvements-uploads
MF_METERS=$D/meters-files

# ── 이미지 **안에서** 찾을 글자 (1-ㅋ) ─────────────────────────────────
# 🔴 태그와 지문이 맞아도 「무엇이 든 판인지」는 안을 봐야 안다. 9/21~9/29 에
#    A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다.
#
#  A/S 1.8 : 「내자 정리 발행일」은 이번 판에서 처음 생긴 구역 제목이다
#            (RF_Service_System/src/lib/domain/repair-case-domestic-order-dates.ts
#             의 DOMESTIC_ORDER_DATES_SECTION_TITLE). 1.7 에는 없다.
#            대조 표시는 두 판에 다 있는 SSO_REDIRECT_URI 를 쓴다.
AS_MARK="내자 정리 발행일"
AS_CTRL="SSO_REDIRECT_URI"
#  PO 0.3 : 권한 변경은 글자로 드러나지 않는다(AS_ENGINEER 는 0.2 의 역할
#           목록에도 있는 글자다). 대신 같은 판에 함께 실린 **사내 공용
#           메뉴바 묶음 갱신**을 본다 — vendor/dss-ui 를 8a17da8 에서
#           8a64d2a 로 올렸고, 그 커밋이 새로 만든 글자가 dss:bell-opened 다
#           (dss-ui/src/notification-bell/events.ts). 0.2 에는 없다.
#           🔴 이 표시는 「0.3 이다」를 말해 줄 뿐 「권한이 열렸다」를 말해
#              주지 않는다. 권한은 1-ㄷ 이 DB 로 보고, 마지막에 사람이
#              엔지니어 계정으로 눈으로 본다.
PO_MARK="dss:bell-opened"
PO_CTRL="domesticOrders"

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 셋. 인자가 없으면 이 셋 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
PROBE_WRITE=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 15-deploy.sh                  읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 15-deploy.sh --check          위와 같습니다
  bash 15-deploy.sh --preload        새 이미지 둘을 싣고 지문만 맞춥니다
  bash 15-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 15-deploy.sh --go             🔴 A/S 와 PO 둘만 교체합니다
  bash 15-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 15-deploy.sh --rollback       되돌리기 안내

  🔴 --go 가 멈추는 것은 **dss-as 와 dss-po 둘**입니다.
     포털 · 계측기 · 개선요청 · 휴가 · DB 는 그대로 돕니다.
  🔴 마이그레이션은 0 개입니다 — 이 스크립트에는 DB 를 바꾸는 자리가
     한 군데도 없습니다. SQL 은 전부 select 입니다.
USAGE
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)      MODE=check ;;
    --preload)    MODE=preload ;;
    --force-load) FORCE_LOAD=1; [ "$MODE" = check ] && MODE=force-load ;;
    --go)         MODE=go ;;
    --rollback)   MODE=rollback ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "모르는 인자: $1"; usage; exit 2 ;;
  esac
  shift
done
# 🔴 쓰기 시험(폴더에 빈 파일을 놓았다 지운다)은 --go 에서만 한다.
#    --check 가 「아무것도 안 바꾼다」고 말해 놓고 파일을 만들면 그 약속이 거짓이 된다.
[ "$MODE" = go ] && PROBE_WRITE=1

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/15-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11 · 12 · 13-deploy.sh 의 것을 그대로 쓴다 ────────────────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""
PERM_PINNED=0     # 🔴 저장된 권한 값이 기본값을 막고 있는 칸의 수 (1-ㄷ)
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# ── ④ 사람이 칠 명령은 76자 안쪽으로만 찍는다 ──────────────────────────
# DSM 의 ash 에 긴 줄을 붙여넣으면 터미널 폭에서 자동 줄바꿈되며 개행이 끼어들어
# **줄이 잘린다.** 줄 이어붙임(`\`)도 한 줄짜리 긴 명령도 둘 다 깨졌다(9/29 실측).
CMDW=76
cmd() { # 1 사람이 그대로 칠 명령 한 줄
  printf '    %s\n' "$1"
  if [ "${#1}" -gt "$CMDW" ]; then
    printf '    ⚠️ 위 줄이 %s자다(%s자 넘음) — 붙여넣으면 잘릴 수 있다.\n' "${#1}" "$CMDW"
    printf '       아래 「스크립트 파일로 만들기」를 쓰세요.\n'
  fi
}
# 길 수밖에 없는 명령은 붙여넣지 말고 파일로 만들어 돌린다.
script_file_hint() { # 1 파일이름(확장자 없이)
  say "    ── 길면 붙여넣지 말고 파일로 만드세요 ──"
  cmd "cat > /volume1/dss/setup/$1.sh"
  say "      (여기에 위 줄들을 붙여넣고 Ctrl+D)"
  cmd "bash /volume1/dss/setup/$1.sh"
}

COMPOSE=("$DOCKER" compose -f "$CF" --env-file "$ENV_NAS" --profile tools)
# 아직 갈아 끼우지 않은 compose 를 **시험만** 해 볼 때 쓴다.
compose_at() { # 1 compose파일  나머지: compose 에 넘길 인자
  local f="$1"; shift
  "$DOCKER" compose --project-directory "$D/deploy" -f "$f" --env-file "$ENV_NAS" --profile tools "$@"
}

running() { "$DOCKER" ps --format '{{.Names}}' | grep -qx "$1"; }
pg_up()   { running dss-pg-app; }

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미 — 🔴 **전부 select 다.**
#
#  이 스크립트에는 자료를 바꾸는 SQL 이 한 줄도 없다. 마이그레이션이 0개라
#  적용할 것이 없고, role_permissions 는 읽기만 한다(고치는 곳은 A/S 의 화면
#  하나뿐이고 그것은 사람이 브라우저에서 하는 일이다).
# ══════════════════════════════════════════════════════════════════════
qas()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -Atc \"$1\"" 2>/dev/null; }
qqas() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -c   \"$1\"" 2>/dev/null; }

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 개발 PC 의 `docker image inspect --format {{.Id}}` 가 아니라 **이 값**이
#    NAS 에 실렸을 때의 image ID 가 된다(11-deploy.sh 머리말의 그 까닭).
#    비압축을 먼저 읽고 안 되면 gzip 으로 다시 읽는다 — 둘 다 된다.
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

# ── ① 같은 태그를 덮어쓰는 길 ──────────────────────────────────────────
# 태그를 그대로 두고 다시 구운 이미지는 have_img 갈래에서 영영 안 실린다.
# FORCE_LOAD=1 이면 그 검사를 건너뛰고, 지문이 어긋나면 그 자리에서 고칠
# 명령을 찍는다 — 사람이 스스로 다음 수를 알 수 있어야 한다.
force_load_hint() { # 1 태그
  say "    🔴 같은 태그로 **다시 구운** 이미지일 수 있다. 덮어쓰려면:"
  cmd "bash $0 --force-load"
  say "       (교체까지 한 번에 하려면:)"
  cmd "bash $0 --go --force-load"
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
  verify_img "$1" "$3" || { force_load_hint "$1"; return 1; }
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

# ── compose 파일에서 서비스 한 덩어리만 잘라 낸다 ──────────────────────
# 🔴 파일 전체를 grep 하면 안 된다 — 주석 줄(`# image: dss-po:0.1`)이 그대로
#    걸려서 꺼져 있는 서비스를 「가리킨다」고 세게 된다(11-deploy.sh 의 그 함정).
svc_block() { # 1 compose파일 2 서비스이름
  awk -v s="  $2:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$1" | sed '/^[[:space:]]*#/d'
}
svc_image() { # 1 compose파일 2 서비스이름
  svc_block "$1" "$2" | sed -n 's/^[[:space:]]*image:[[:space:]]*//p' | head -1
}

# ══════════════════════════════════════════════════════════════════════
#  ② 폴더를 **컨테이너 안에서 실제로 열어 본다**
#
#  🔴 주인(uid)과 모드(755)만 보면 통과하는데 실제로는 EACCES 인 일이 있다.
#     Synology ACL 이 상위에서 내려오면 `ls -ld` 에는 끝의 `+` 하나로만 보이고,
#     `stat -c %u:%g` 는 그것을 아예 안 보여 준다. 9/29 오전에 kyosan-converted
#     가 그래서 통과했다가 러너가 EACCES 로 끝났다.
#     → 판정은 커널에게 맡긴다. 컨테이너 안에서 `ls` 를 돌려 본다.
#
#  PATHS 는 "경로:모드" 를 빈칸으로 나열한 것이다 (모드: ro | rw).
#  🔴 쓰기 시험은 PROBE_WRITE=1 (즉 --go) 일 때만 한다.
# ══════════════════════════════════════════════════════════════════════
PROBE_SH='id
for p in $PATHS; do
  d=${p%%:*}; m=${p##*:}
  if ls -1 "$d" >/dev/null 2>&1; then r=READ_OK; else r=READ_FAIL; fi
  w=WRITE_SKIP
  if [ "$m" = rw ]; then
    t="$d/.dss-write-test"
    if : > "$t" 2>/dev/null; then w=WRITE_OK; rm -f "$t"; else w=WRITE_FAIL; fi
  fi
  echo "PROBE $d $r $w"
done'

perm_fix_hint() { # 나머지: 호스트 폴더들
  local h
  say "    ╔══════════════════════════════════════════════════════════════╗"
  say "    ║ 🔴 주인·모드로는 통과하는데 **컨테이너가 실제로는 못 연다.**   ║"
  say "    ╚══════════════════════════════════════════════════════════════╝"
  say "    상위 공유폴더의 Synology ACL(d---------+ · administrators 만)을"
  say "    물려받은 것이다. scp 나 mkdir 로 새로 생긴 폴더에서 일어난다."
  say "    먼저 눈으로 본다:"
  for h in "$@"; do
    cmd "ls -ld $h"
    cmd "synoacltool -get $h"
  done
  say "    고친다 — 🔴 Synology 는 chmod 하면 ACL 을 벗고 Linux mode 가 된다:"
  for h in "$@"; do
    cmd "chown -R 1000:1000 $h"
    cmd "find $h -type d -exec chmod 750 {} +"
    cmd "find $h -type f -exec chmod 640 {} +"
  done
  say "    🔴 /volume1/3_견적… 같은 **직원이 쓰는 공유폴더에는 하지 마라** —"
  say "       거기서 ACL 을 걷으면 탐색기 접근이 끊긴다(app-as 주석의 그 까닭)."
}

probe_svc() { # 1 서비스 2 컨테이너이름 3 사람이읽을이름 4 "경로:모드 …" 5 "호스트폴더 …"
  local svc="$1" cname="$2" label="$3" paths="$4" hosts="$5"
  local img out how anybad=0 d r w
  if running "$cname"; then
    how="지금 도는 컨테이너 $cname 안에서"
    out=$("$DOCKER" exec -e PATHS="$paths" "$cname" sh -c "$PROBE_SH" 2>&1)
  else
    img=$(svc_image "$CF_EFF" "$svc")
    if [ -n "$img" ] && have_img "$img"; then
      how="새 컨테이너($svc · $img)를 잠깐 띄워"
      out=$(compose_at "$CF_EFF" run --rm --no-deps -e PATHS="$paths" \
            --entrypoint sh "$svc" -c "$PROBE_SH" 2>&1)
    else
      say "  · $label — $cname 도 안 돌고 ${img:-이미지}도 아직 없다. **못 열어 봤다**"
      say "    → 먼저 이미지를 실으세요:"
      cmd "bash $0 --preload"
      return 0
    fi
  fi
  say "  $label — $how 본 것:"
  printf '%s\n' "$out" | grep -E '^(uid=|PROBE )' | sed 's/^/      /'
  if ! printf '%s\n' "$out" | grep -q '^PROBE '; then
    bad "$label 의 폴더를 열어 보지 못했다 — 아래가 그대로의 출력이다"
    printf '%s\n' "$out" | sed 's/^/      /' | head -8
    return 1
  fi
  while read -r _ d r w; do
    [ -n "${d:-}" ] || continue
    case "$r" in
      READ_OK) ok "$label · $d 를 읽는다" ;;
      *)       bad "$label · $d 를 **못 읽는다**(EACCES)"; anybad=1 ;;
    esac
    case "$w" in
      WRITE_OK)   ok "$label · $d 에 쓸 수 있다" ;;
      WRITE_SKIP) : ;;
      *)          bad "$label · $d 에 **못 쓴다**"; anybad=1 ;;
    esac
  done <<EOF
$(printf '%s\n' "$out" | grep '^PROBE ')
EOF
  [ "$anybad" = 0 ] || perm_fix_hint $hosts
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  【검사 ②】 알림 링크의 **주소를 실제로 뽑아 본다**
#
#  🔴 왜 이것이 있는가는 머리말에 적었다. 요약: 2026-09-29 에 「통로가 있다
#     (401 이 온다)」로 통과했는데, 그 통로가 내준 링크가 http://172.20.0.7:3500/
#     이었다. 문이 있는지가 아니라 **무엇이 나오는지**를 봐야 잡힌다.
#
#  🔴 이번 배포에서 이 검사를 도는 곳은 **A/S 하나뿐**이다. PO 에는 통로가
#     아예 없다(api/integration 폴더가 없다). 없는 것을 찾지 않는다.
# ══════════════════════════════════════════════════════════════════════
NOTIFY_CB=/api/auth/sso/callback

# 값을 그대로 찍지 않는다 — 숫자를 N 으로 가린 앞머리만 남긴다.
# (172.20.0.7 → NNN.NN.N.N · as.dss21.co.kr → as.dssNN.co.kr)
href_shape() { # 1 주소
  printf '%s' "$1" | cut -c1-48 | sed 's/[0-9]/N/g'
}

judge_base_url() { # 1 라벨 2 SSO_REDIRECT_URI 원본 3 기대 앞머리
  local label="$1" raw="$2" want="$3" base host
  # `auto` 와 `auto:<포트>` 둘 다 auto 다.
  case "$raw" in
    auto|auto:*|AUTO|"")
      bad "$label · SSO_REDIRECT_URI 가 auto(또는 빈 값)다 — 운영에서는 도메인을 적는다"
      say "      auto 는 이 기계의 랜 주소를 집는다. **컨테이너 안에서는 172.x 가 잡힌다.**"
      return 1 ;;
  esac
  case "$raw" in
    *"$NOTIFY_CB") base=${raw%"$NOTIFY_CB"} ;;
    *)
      bad "$label · SSO_REDIRECT_URI 가 $NOTIFY_CB 로 끝나지 않는다"
      say "      앱은 여기서 던지고 **알림이 통째로 빈 목록**이 된다. 꼴: $(href_shape "$raw")"
      return 1 ;;
  esac
  base=$(printf '%s' "$base" | sed 's:/*$::')
  host=${base#*://}; host=${host%%/*}; host=${host%%:*}
  case "$host" in
    172.*|10.*|192.168.*)
      bad "$label · 알림 주소가 **밖에서 닿지 않는 사설 주소**다 — $(href_shape "$base") 꼴"
      say "      2026-09-29 에 실제로 나간 그 주소다. 눌러도 아무 데도 못 간다."
      return 1 ;;
    *[!0-9.]*) : ;;   # 글자가 섞여 있다 = 이름(도메인)이다
    *)
      bad "$label · 알림 주소가 이름이 아니라 **IP** 다 — $(href_shape "$base") 꼴"
      return 1 ;;
  esac
  if [ "$base" = "$want" ]; then
    ok "$label · 알림 링크가 $want 로 시작한다"
    return 0
  fi
  bad "$label · 알림 주소가 $want 가 아니다 — $(href_shape "$base") 꼴"
  say "      포털은 「절대 주소이고 http 니까」 그대로 통과시킨다 — **조용히 틀린다.**"
  return 1
}

# ── 이미지 **안에** 그 판의 표시가 들어 있는가 ─────────────────────────
# 🔴 12번의 fix_marker_check 를 그대로 가져왔다. 한 군데만 넓혔다 — 12번은
#    /app/.next/server 만 뒤졌는데 여기서는 **/app/.next 전체**를 뒤진다.
#    PO 의 표시(dss:bell-opened)는 알림 종 안에 있어 client 조각으로도 갈리고,
#    그쪽은 /app/.next/static 에 담기기 때문이다. 두 이미지 모두 Next 의
#    standalone 이라 /app/.next 아래에 server 와 static 이 함께 있다.
mark_check() { # 1 라벨 2 이미지태그 3 그 판의표시 4 두 판에 다 있는 대조표시
  local label="$1" tag="$2" marker="$3" control="$4" mark m c
  if ! have_img "$tag"; then
    bad "$label · $tag 가 NAS 에 없다 — 안을 볼 수 없다"
    cmd "bash $0 --preload"
    return 1
  fi
  mark=$("$DOCKER" run --rm -e M="$marker" -e C="$control" --entrypoint sh "$tag" -c '
    m=0; c=0
    grep -rlF -- "$M" /app/.next >/dev/null 2>&1 && m=1
    grep -rlF -- "$C" /app/.next >/dev/null 2>&1 && c=1
    echo "MARK $m $c"' 2>/dev/null | grep '^MARK ' | head -1)
  m=$(printf '%s' "$mark" | awk '{print $2}')
  c=$(printf '%s' "$mark" | awk '{print $3}')
  if [ "${m:-0}" = 1 ]; then
    ok "$label · $tag 안에 **이번 판의 표시**가 있다"
    return 0
  fi
  if [ "${c:-0}" = 1 ]; then
    bad "$label · $tag 는 **옛 판**이다 — 이번 판의 표시가 없다"
    say "      대조 표시는 찾았는데 이번 판의 표시가 없다 → 글자를 못 읽은 것이 아니다."
    say "      🔴 개발 PC 에서 다시 굽고 tar 를 다시 올리세요."
    return 1
  fi
  say "    ⚠️ $tag 안을 글자로 뒤지지 못했다 — 대조 표시도 안 나왔다."
  say "       까닭 둘 중 하나다: 굽는 도구가 글자를 유니코드 이스케이프로 바꿔"
  say "       넣었거나, 대조 표시로 고른 글자가 코드에서 없어졌다."
  say "       **판정하지 않는다.** 🔴 이때는 사람이 직접 화면에서 봐야 한다."
  return 0
}

notify_href_check() { # 1 라벨 2 컨테이너 3 env파일 4 기대앞머리 5 이미지태그 6 표시 7 대조표시
  local label="$1" cname="$2" envf="$3" want="$4" tag="$5" marker="$6" control="$7"
  local raw="" src=""
  say "  $label — 알림 링크가 무엇으로 시작하는지 본다"

  # ㄱ. SSO_REDIRECT_URI — 🔴 값은 찍지 않는다
  if running "$cname"; then
    raw=$("$DOCKER" exec "$cname" printenv SSO_REDIRECT_URI 2>/dev/null | tr -d '\r')
    [ -n "$raw" ] && src="지금 도는 $cname 안"
  fi
  if [ -z "$raw" ] && [ -f "$envf" ]; then
    raw=$(sed -n 's/^SSO_REDIRECT_URI=//p' "$envf" | head -1 | tr -d '\r')
    raw=${raw#\"}; raw=${raw%\"}
    raw=${raw#\'}; raw=${raw%\'}
    [ -n "$raw" ] && src="$(basename "$envf")"
  fi
  if [ -z "$raw" ]; then
    bad "$label · SSO_REDIRECT_URI 를 찾지 못했다 — 알림 주소를 계산할 수 없다"
    return 1
  fi
  say "    · $src 에서 읽었다 (🔴 값은 찍지 않는다)"

  # ㄴ. 앱과 같은 계산 → 판정 (src/lib/config/sso.ts 의 getAppBaseUrl 과 같다)
  judge_base_url "$label" "$raw" "$want"

  # ㄷ. 이미지 안에 **그 계산이 들어 있는가**
  mark_check "$label" "$tag" "$marker" "$control"
}

# ══════════════════════════════════════════════════════════════════════
#  【검사 ①】 엔지니어 권한이 **진짜로** 열리는가 — 🔴 select 만 쓴다
#
#  까닭과 출처(표·칸·역할·값을 어느 파일에서 읽었는지)는 머리말에 있다.
#
#  🔴 이 검사는 ✗ 로 세지 **않는다.** 배포 자체의 흠이 아니라 「배포해도 안
#     열릴 수 있다」는 경고이고, 고치는 자리도 NAS 가 아니라 A/S 의 화면이다.
#     여기서 ✗ 를 세면 아무 잘못 없는 배포가 멈춘다. 대신 아주 눈에 띄게
#     찍고, 마지막 안내에서 한 번 더 말한다.
# ══════════════════════════════════════════════════════════════════════
lvl_rank() { # 1 레벨  → 0..3 (모르는 값이면 -1)
  case "$1" in
    NONE) echo 0 ;; READ) echo 1 ;; WRITE) echo 2 ;; MANAGE) echo 3 ;; *) echo -1 ;;
  esac
}
perm_want() { # 1 칸  → 배포 뒤 기대하는 기본값
  case "$1" in
    domesticOrders) echo WRITE ;;
    quotes)         echo WRITE ;;
    repairLabor)    echo READ ;;
    *)              echo "" ;;
  esac
}
perm_label() { # 1 칸  → 화면에 보이는 이름
  case "$1" in
    domesticOrders) echo "내자 정리" ;;
    quotes)         echo "견적서" ;;
    repairLabor)    echo "작업 비용" ;;
    *)              echo "$1" ;;
  esac
}

# 🔴 실제로 돌리는 SQL 전문. 화면에도 그대로 찍어 사람이 무엇을 물었는지
#    눈으로 확인할 수 있게 한다. select 뿐이다.
PERM_SQL_COUNT="select count(*) from $PERM_TABLE"
PERM_SQL_ROLE="select count(*) from $PERM_TABLE where role = '$PERM_ROLE'"
PERM_SQL_ROWS="select area_key || '|' || level from $PERM_TABLE where role = '$PERM_ROLE' and area_key in ('domesticOrders', 'quotes', 'repairLabor') order by area_key"
PERM_SQL_ALL="select role, area_key, level, updated_at from $PERM_TABLE where area_key in ('domesticOrders', 'quotes', 'repairLabor') order by role, area_key"

perm_check() {
  local reg n_all n_role rows k want got r_got r_want
  if ! pg_up; then
    bad "dss-pg-app 이 떠 있지 않다 — 권한을 하나도 볼 수 없다"
    return 1
  fi
  reg=$(qas "select to_regclass('public.$PERM_TABLE')")
  if [ -z "$reg" ]; then
    bad "$AS_DB 에 $PERM_TABLE 표가 없다 — 🔴 첫 설치가 덜 된 DB 다"
    return 1
  fi
  ok "$AS_DB 에 $PERM_TABLE 표가 있다"

  say "  🔴 이 검사가 돌리는 SQL 은 아래 넷이 전부다. 전부 select 다:"
  say "      $PERM_SQL_COUNT"
  say "      $PERM_SQL_ROLE"
  say "      $PERM_SQL_ROWS"
  say "      $PERM_SQL_ALL"
  say

  n_all=$(qas "$PERM_SQL_COUNT")
  n_role=$(qas "$PERM_SQL_ROLE")
  say "  · $PERM_TABLE 전체 줄: ${n_all:-?}  (0 이면 전부 코드의 기본 정책대로다)"
  say "  · 그중 $PERM_ROLE 의 줄: ${n_role:-?}"
  say
  say "  이번에 열린 칸 셋에 저장된 값 (역할 전부):"
  qqas "$PERM_SQL_ALL" | sed 's/^/      /'
  say

  rows=$(qas "$PERM_SQL_ROWS")
  for k in $PERM_KEYS; do
    want=$(perm_want "$k")
    got=$(printf '%s\n' "$rows" | sed -n "s/^$k|//p" | head -1)
    if [ -z "$got" ]; then
      ok "$(perm_label "$k") ($k) · 저장된 값이 **없다** → 코드의 기본 정책을 따른다"
      say "      → 배포하면 엔지니어에게 **$want 로 열린다.**"
      continue
    fi
    r_got=$(lvl_rank "$got")
    r_want=$(lvl_rank "$want")
    if [ "$r_got" -ge "$r_want" ] 2>/dev/null; then
      ok "$(perm_label "$k") ($k) · 저장된 값이 $got 다 — 기본값 $want 보다 낮지 않다"
      say "      → 막히지 않는다. 그래도 **저장된 값이 이긴다**는 것은 알고 계세요."
      continue
    fi
    PERM_PINNED=$((PERM_PINNED + 1))
    say "  ╔══════════════════════════════════════════════════════════════╗"
    say "  ║ 🔴 $(perm_label "$k") — **배포해도 이 칸은 안 열립니다.**"
    say "  ╚══════════════════════════════════════════════════════════════╝"
    say "     DB 에 저장된 값: $got   (이번 판의 기본값: $want)"
    say "     칸 하나하나마다 **저장된 값이 코드의 기본 정책을 이깁니다.**"
    say "     고치는 자리는 NAS 가 아니라 화면입니다:"
    say "       A/S → [사용자 관리] → [역할별 접근 권한] → $PERM_ROLE 줄의"
    say "       「$(perm_label "$k")」 칸을 $want 이상으로 올리고 저장."
    say "     🔴 이번 변경으로 **드롭다운의 상한은 열렸습니다** — 예전에는"
    say "        그 칸을 올리려 해도 고를 수 있는 값이 없었습니다."
    say "     (이 줄은 ✗ 로 세지 않습니다. 배포의 흠이 아니라 설정입니다.)"
  done
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)
EXP_AS=""; EXP_PO=""

see_tar() { # 1 태그 2 tar 3 지문 4 바이트 5 md5
  local n m
  if [ ! -s "$2" ]; then
    bad "$1 의 tar 가 없다: $2"
    say "    → 개발 PC 에서 올리세요. 🔴 scp 에는 -O 를 붙입니다(DSM 에 sftp 가 없다)."
    return 1
  fi
  n=$(stat -c '%s' "$2" 2>/dev/null)
  [ "$n" = "$4" ] && ok "$1 · 바이트 $n" \
    || bad "$1 의 바이트가 $4 가 아니다 ($n) — 올리다 끊겼다"
  m=$(md5sum "$2" 2>/dev/null | awk '{print $1}')
  [ "$m" = "$5" ] && ok "$1 · md5 $m" \
    || bad "$1 의 md5 가 $5 가 아니다 (${m:-못 읽음}) — 파일이 상했다"
  [ -n "$3" ] && ok "$1 · 기대 지문 $(echo "$3" | cut -c1-19)…" \
    || bad "$1 의 tar 에서 manifest.json 을 읽지 못했다: $2"
}

run_checks() {
  local tag s p rec t n_sql n_j n_db f db n_bk n_pg nlog

  # ── 1-ㄱ. 이미지 tar 둘 — 크기 · md5 · tar 안의 지문 ─────────────────
  # 🔴 크기와 md5 는 **파일 전송이 온전한지**를 본다. 지문(sha256)은 그 tar 가
  #    NAS 에 실렸을 때 갖게 될 image ID 다 — 둘은 다른 것을 본다.
  step "1-ㄱ. 새 이미지 tar 둘 (크기 · md5 · tar 안의 지문)"
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  EXP_PO=$(tar_config_id "$TAR_PO" 2>/dev/null) || EXP_PO=""
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS" "$SZ_AS" "$MD5_AS"
  see_tar "$TAG_PO" "$TAR_PO" "$EXP_PO" "$SZ_PO" "$MD5_PO"

  # ── 1-ㄴ. NAS 에 실린 이미지 ─────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (올라가는 둘 · 건드리지 않는 여덟)"
  say "  올라가는 둘 — 지문까지 맞춘다:"
  if have_img "$TAG_AS"; then
    [ -n "$EXP_AS" ] && { verify_img "$TAG_AS" "$EXP_AS" || force_load_hint "$TAG_AS"; }
  else
    say "  · $TAG_AS 는 아직 NAS 에 없다 — --preload 나 --go 가 싣는다"
  fi
  if have_img "$TAG_PO"; then
    [ -n "$EXP_PO" ] && { verify_img "$TAG_PO" "$EXP_PO" || force_load_hint "$TAG_PO"; }
  else
    say "  · $TAG_PO 는 아직 NAS 에 없다 — --preload 나 --go 가 싣는다"
  fi
  say "  🔴 지문이 어긋나면 **혼자 고쳐지지 않는다.** 태그가 같으면 docker load 를"
  say "     그냥 부르는 것으로는 안 바뀐다 — 위에 찍힌 --force-load 를 쓰세요."
  # 🔴 건드리지 않는 여덟 — **다시 싣지 않는다.** 여기서는 「있는가」만 본다.
  say "  🔴 건드리지 않는 여덟 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for tag in "$KEEP_AUTH" "$KEEP_ASTOOLS" "$KEEP_METERS" "$KEEP_METERSTOOLS" \
             "$KEEP_IMP" "$KEEP_IMPTOOLS" "$KEEP_LEAVE" "$KEEP_LEAVETOOLS"; do
    have_img "$tag" && ok "$tag 실려 있다 ($(img_id "$tag" | cut -c1-19)…)" \
      || bad "$tag 가 NAS 에 없다 — 🔴 앞 배포가 되돌아갔거나 누가 지웠다"
  done

  # ── 1-ㄷ. 🔴 【검사 ①】 엔지니어 권한 ────────────────────────────────
  step "1-ㄷ. 【검사 ①】 엔지니어에게 내자 정리·견적서가 **진짜로** 열리는가"
  say "  이번 판의 핵심이다. 🔴 **코드를 배포해도 안 열릴 수 있다** — 칸마다"
  say "  DB 에 저장된 값이 있으면 그 값이 코드의 기본 정책을 이기기 때문이다."
  say "  (RF_Service_System/src/lib/auth/permission-resolver.ts 의 그 한 줄)"
  perm_check

  # ── 1-ㄹ. 마이그레이션 — 🔴 **적용하지 않는다. 수만 센다** ───────────
  step "1-ㄹ. 마이그레이션 — 🔴 적용하지 않는다. $N_MIG_WANT 이 맞는지만 본다"
  say "  스키마를 한 글자도 안 건드린 판이다(개발 PC preflight: 전체 $N_MIG_WANT · 대기 0)."
  say "  그러니 여기서 볼 것은 **셋이 다 $N_MIG_WANT 인가** 하나뿐이다."
  if [ -d "$MIGDIR" ]; then
    n_sql=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
    [ "$n_sql" = "$N_MIG_WANT" ] && ok "ㄱ) $MIGDIR 의 .sql 이 ${n_sql}개다" \
      || bad "ㄱ) $MIGDIR 의 .sql 이 ${N_MIG_WANT}개가 아니다 (${n_sql}개)"
    if [ -f "$MIGDIR/meta/_journal.json" ]; then
      n_j=$(grep -c '"tag"' "$MIGDIR/meta/_journal.json" 2>/dev/null | tr -d ' ')
      [ "$n_j" = "$N_MIG_WANT" ] && ok "ㄴ) _journal.json 의 tag 가 ${n_j}줄이다" \
        || bad "ㄴ) _journal.json 의 tag 가 ${N_MIG_WANT}줄이 아니다 (${n_j}줄)"
    else
      bad "ㄴ) $MIGDIR/meta/_journal.json 이 없다"
    fi
  else
    bad "ㄱㄴ) $MIGDIR 폴더가 없다 — compose 가 tools-as 에 붙이는 그 폴더다"
  fi
  if pg_up; then
    if [ -n "$(qas "select to_regclass('drizzle.__drizzle_migrations')")" ]; then
      n_db=$(qas "select count(*) from drizzle.__drizzle_migrations")
      say "  ㄷ) 운영 DB($AS_DB)에 적용된 줄: ${n_db:-?}"
      if [ "${n_db:-x}" = "$N_MIG_WANT" ]; then
        ok "🔴 코드의 마이그레이션 수($N_MIG_WANT) = 운영 DB 의 적용 수. 할 일이 없다"
      else
        bad "🔴 적용된 줄이 ${N_MIG_WANT}이 아니다 (${n_db:-?}) — **이것이 신호다**"
        say "    → 이 배포는 마이그레이션을 하나도 들고 오지 않았다. 그런데 수가"
        say "      어긋났다면 **남의 변경이 섞였거나 누가 손으로 적용한 것**이다."
        say "      고치지 말고 **먼저 알리세요.** 더 깊이 보려면 preflight 를:"
        say "        (아래 두 줄을 파일로 만들어 돌린다 — 한 줄로는 길어서 잘린다)"
        say "          cd /volume1/dss/deploy"
        say "          docker compose -f docker-compose.nas.yml \\"
        say "            --env-file .env.nas --profile tools \\"
        say "            run --rm tools-as npm run db:preflight"
        script_file_hint "15-preflight"
      fi
    else
      bad "ㄷ) $AS_DB 에 drizzle.__drizzle_migrations 가 없다 — 첫 설치가 안 된 DB 다"
    fi
  else
    bad "ㄷ) dss-pg-app 이 떠 있지 않다 — 적용 수를 못 봤다"
  fi
  say "  🔴 PO 저장소에는 마이그레이션이 **아예 없다**(drizzle/ 도 db:migrate 도)."
  say "     그래서 compose 에 tools-po 가 없는 것이 맞다 — 1-ㅂ 이 그것도 본다."

  # ── 1-ㅁ. env 파일 둘 — 🔴 **값은 절대 찍지 않는다** ────────────────
  # 둘 다 이미 NAS 에 있다. 이번 판은 새로 요구하는 이름이 없다 — 두 저장소의
  # .env.example 이 그대로다. 그래서 있는가 · 모드가 600 인가 · 금지 이름이
  # 안 들어왔는가만 본다.
  step "1-ㅁ. env 파일 둘 (이름·모드만 본다. 값은 안 찍는다)"
  for f in as.env po.env; do
    p="$ENVD/$f"
    if [ -f "$p" ]; then
      s=$(stat -c '%a' "$p" 2>/dev/null)
      [ "$s" = 600 ] && ok "$f 있다 · 모드 600" \
        || bad "$f 의 모드가 ${s:-?} 다 (600 이어야 한다 — 남이 읽는다)"
      s=$(stat -c '%U:%G' "$p" 2>/dev/null)
      [ "$s" = "root:root" ] || bad "$f 의 주인이 ${s:-?} 다 (root:root 이어야 한다)"
      # compose 와 이미지가 넘기는 값이 여기에도 있으면 언젠가 한쪽만 바뀌는데,
      # 그때 앱은 **오류 없이** 다른 DB·다른 폴더를 본다.
      for t in DATABASE_URL UPLOADS_DIR PORT; do
        grep -q "^$t=" "$p" && bad "$f 에 $t 가 **있다** — 지우세요(compose 가 넘긴다)"
      done
    else
      bad "$f 가 없다: $p"
      say "    → 없는 env_file 하나면 docker compose 명령이 **통째로** 안 먹는다."
    fi
  done

  # ── 1-ㅂ. compose — 태그 둘 · 🔴 건드리지 않는 여덟 ─────────────────
  step "1-ㅂ. compose ($CF_EFF)"
  if compose_at "$CF_EFF" config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_at "$CF_EFF" config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  SVCS=$(compose_at "$CF_EFF" config --services 2>/dev/null)
  for s in app-auth app-as tools-as app-meters tools-meters \
           app-improvements tools-improvements app-po app-leave tools-leave; do
    echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
      || bad "서비스 목록에 $s 가 없다 — 주석으로 꺼져 있다"
  done
  see_tag() { # 1 서비스 2 태그 3 사람이 읽을 이름
    svc_block "$CF_EFF" "$1" | grep -q "image: $2$" \
      && ok "$1 가 $2 를 가리킨다 ($3)" \
      || bad "$1 의 태그가 $2 가 아니다 ($3) — 지금 값: $(svc_image "$CF_EFF" "$1")"
  }
  say "  올라가는 둘:"
  see_tag app-as "$TAG_AS" "A/S"
  see_tag app-po "$TAG_PO" "PO/내자"
  if [ "$(svc_image "$CF_EFF" app-as)" = "$OLD_AS" ] \
     || [ "$(svc_image "$CF_EFF" app-po)" = "$OLD_PO" ]; then
    say "    🔴 compose 가 아직 **옛 태그**를 가리킵니다. 고치는 길 둘:"
    say "      ㄱ) 개발 PC 에서 새 compose 를 만들어 아래에 올린다(권장):"
    say "           /volume1/dss/setup/incoming/docker-compose.nas.yml"
    say "         --go 가 그 파일을 시험하고 제자리로 옮깁니다."
    say "      ㄴ) 손으로 고친다 — 🔴 아래를 **한 줄씩** 치세요:"
    cmd "cd /volume1/dss/deploy"
    cmd "F=docker-compose.nas.yml"
    cmd "sed -i 's|$OLD_AS|$TAG_AS|' \$F"
    cmd "sed -i 's|$OLD_PO|$TAG_PO|' \$F"
    say "         (dss-as-tools:1 은 글자가 겹치지만 위 sed 는 태그까지"
    say "          붙여 갈아 끼우므로 흔들리지 않습니다 — 확인:)"
    cmd "grep -n 'image: dss-as' \$F"
    cmd "grep -n 'image: dss-po' \$F"
  fi
  # 🔴 건드리지 않기로 한 여덟. 여기가 흔들렸으면 **남의 커밋이 섞인 것**이다 —
  #    두 세션이 같은 저장소를 쓴다(HANDOFF A절). 고치지 말고 먼저 알린다.
  say "  🔴 건드리지 않는 여덟 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-auth            "$KEEP_AUTH"        "포털 · 그대로"
  see_tag tools-as            "$KEEP_ASTOOLS"     "A/S 도구 · 그대로"
  see_tag app-meters          "$KEEP_METERS"      "계측기 · 그대로"
  see_tag tools-meters        "$KEEP_METERSTOOLS" "계측기 도구 · 그대로"
  see_tag app-improvements    "$KEEP_IMP"         "개선요청 · 그대로"
  see_tag tools-improvements  "$KEEP_IMPTOOLS"    "개선요청 도구 · 그대로"
  see_tag app-leave           "$KEEP_LEAVE"       "휴가 · 그대로"
  see_tag tools-leave         "$KEEP_LEAVETOOLS"  "휴가 도구 · 그대로"
  # 볼륨과 포트 — 한 글자가 틀리면 앱은 **오류 없이** 뜨고 자료가 갈라진다.
  svc_block "$CF_EFF" app-as | grep -q "$ATT:/data" \
    && ok "app-as 가 $ATT 를 붙인다" \
    || bad "app-as 의 첨부 볼륨이 $ATT 가 아니다 — 🔴 첨부가 사라진다"
  svc_block "$CF_EFF" app-po | grep -q "$ATT:/data" \
    && ok "app-po 가 A/S 와 **같은 첨부 폴더**($ATT)를 붙인다" \
    || bad "app-po 의 첨부 볼륨이 $ATT 가 아니다 — 🔴 서로의 파일을 못 찾는다"
  for s in app-as app-po; do
    svc_block "$CF_EFF" "$s" | grep -q "$TEMPLATES:/templates" \
      && ok "$s 가 양식 폴더($TEMPLATES)를 읽기 전용으로 붙인다" \
      || bad "$s 의 양식 볼륨이 $TEMPLATES 가 아니다 — 🔴 견적서 출력이 죽는다"
    svc_block "$CF_EFF" "$s" | grep -q '/quote-archive' \
      && ok "$s 가 견적서 공유폴더(/quote-archive)를 붙인다" \
      || bad "$s 에 견적서 공유폴더가 안 붙어 있다 — 🔴 발행이 실패한다"
    svc_block "$CF_EFF" "$s" | grep -q 'group_add' \
      && ok "$s 에 group_add 가 있다 (견적서 공유폴더의 ACL 때문이다)" \
      || bad "$s 에 group_add 가 없다 — 🔴 공유폴더에 Permission denied 가 난다"
  done
  svc_block "$CF_EFF" app-as | grep -q "$MIGDIR" \
    && say "    ⚠️ app-as 가 $MIGDIR 를 붙인다 — 원래는 tools-as 의 자리다" \
    || :
  svc_block "$CF_EFF" tools-as | grep -q "$MIGDIR:/app/drizzle" \
    && ok "tools-as 가 $MIGDIR 를 /app/drizzle 로 붙인다 (1-ㄹ 이 세는 그 폴더)" \
    || bad "tools-as 의 drizzle 볼륨이 $MIGDIR 가 아니다"
  for rec in "app-as|$AS_PORT:3000" "app-po|$PO_PORT:3600"; do
    s=${rec%%|*}; p=${rec##*|}
    svc_block "$CF_EFF" "$s" | grep -q "$p" && ok "$s 가 127.0.0.1:${p%%:*} 으로 열린다" \
      || bad "$s 의 포트가 $p 가 아니다"
  done
  AS_DBURL=$(svc_block "$CF_EFF" app-as | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  PO_DBURL=$(svc_block "$CF_EFF" app-po | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  if [ -n "$PO_DBURL" ] && [ "$AS_DBURL" = "$PO_DBURL" ]; then
    ok "app-po 의 DATABASE_URL 이 app-as 와 **글자까지 같다**"
    say "    (이번 판의 권한이 두 사이트에서 같이 도는 까닭이 이것이다 —"
    say "     role_permissions 표를 둘이 같이 본다.)"
  else
    bad "app-po 의 DATABASE_URL 이 app-as 와 다르다 — 🔴 PO 가 엉뚱한 DB 를 본다"
  fi
  echo "$SVCS" | grep -qx tools-po \
    && bad "tools-po 라는 서비스가 있다 — PO 에는 마이그레이션이 없다" \
    || ok "tools-po 가 없다 (맞다 — PO 저장소에 drizzle/ 자체가 없다)"

  # ── 1-ㅅ. ② 폴더를 컨테이너 안에서 **실제로 열어 본다** ─────────────
  step "1-ㅅ. 폴더 — 주인·모드가 아니라 컨테이너 안에서 실제로 연다"
  if [ "$PROBE_WRITE" = 1 ]; then
    say "  (교체되는 둘은 읽기+쓰기를 본다. 시험 파일은 만들었다가 바로 지운다.)"
  else
    say "  🔵 --check 라서 **읽기만** 해 본다 — 아무 파일도 만들지 않는다."
    say "     쓰기는 --go 의 스모크에서 본다. 지금 손으로 보려면:"
    cmd "D1=/usr/local/bin/docker"
    cmd "\$D1 exec dss-as sh -c \"touch /data/.t && rm /data/.t\""
    cmd "\$D1 exec dss-po sh -c \"touch /data/.t && rm /data/.t\""
  fi
  M=ro; [ "$PROBE_WRITE" = 1 ] && M=rw
  # 🔴 이번에 교체되는 둘 — 쓰기까지 본다(--go 에서만).
  probe_svc app-as dss-as "A/S" "/data:$M /templates:ro" "$ATT $TEMPLATES"
  probe_svc app-po dss-po PO    "/data:$M /templates:ro" "$ATT $TEMPLATES"
  # 🔴 교체 안 되는 곳 — 「아직 읽히는가」만 본다. 쓰기 시험을 하지 않는다.
  probe_svc app-meters       dss-meters       계측기   "/data:ro"         "$MF_METERS"
  probe_svc app-improvements dss-improvements 개선요청 "/data/uploads:ro" "$UP_IMP"
  # 🔴 견적서 공유폴더는 위 틀에 안 넣는다 — 경로에 빈칸과 괄호가 있고, 무엇보다
  #    여기서는 ACL 을 **걷으면 안 된다**(직원의 탐색기 접근이 끊긴다). 읽기만
  #    여기서 보고, 쓰기 시험은 --go 의 스모크에서 따로 한다(5-ㄴ).
  say "  견적서 공유폴더(/quote-archive) — 🔴 읽기만 본다. ACL 을 걷지 않는다:"
  for rec in "dss-as|A/S" "dss-po|PO"; do
    s=${rec%%|*}; p=${rec##*|}
    if running "$s"; then
      "$DOCKER" exec "$s" sh -c 'ls -1 /quote-archive >/dev/null 2>&1' \
        && ok "$p 가 견적서 공유폴더를 읽는다" \
        || { bad "$p 가 견적서 공유폴더를 **못 읽는다**"
             say "      🔴 여기는 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기가 끊긴다."
             say "         compose 의 $s 쪽에 group_add: [\"100\"] 이 있는지부터 보세요."; }
    else
      say "  · $s 가 안 돌고 있어 못 봤다"
    fi
  done

  # ── 1-ㅇ. 🔴 【검사 ③】 야간 작업이 실제로 돌고 있는가 ──────────────
  # 🔴 읽기만 한다. 등록하거나 고치려 들지 않는다 — 그건 사람이 DSM 작업
  #    스케줄러 화면에서 할 일이다.
  step "1-ㅇ. 【검사 ③】 야간 백업 다섯 · 야간 완전삭제 (읽기만 한다)"
  say "  🔴 개선요청이 11일간 백업에서 빠져 있으면서 매일 「성공」으로 끝난 일이"
  say "     있었다. **도장 시각과 DB 다섯**이 유일한 증거다."
  say "  최근 백업 일곱 (사람이 눈으로도 보는 그 명령):"
  cmd "ls -lt /volume1/dss/backups/db/ | head -7"
  ls -lt "$BKD/db/" 2>/dev/null | head -7 | sed 's/^/      /'
  n_bk=0
  for db in dss_auth dss_meters dss_as dss_improvements dss_leave; do
    f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
      n_bk=$((n_bk + 1))
    else
      bad "오늘($TODAY) 뜬 $db 백업이 없다"
    fi
  done
  if [ "$n_bk" = 5 ]; then
    ok "🔴 오늘 백업이 **다섯**이다 — 야간 백업이 실제로 돌았다"
  else
    bad "🔴 오늘 백업이 ${n_bk}개뿐이다 (다섯이어야 한다)"
    say "    → DSM 작업 스케줄러 「DSS Backup」 02:30 · root 가 도는지 보세요."
    say "      손으로 한 번 (종료 코드 0 이어야 한다):"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    say "    🔴 백업이 없으면 야간 완전삭제도 스스로 멈춘다(문지기가 그렇게 짜여 있다)."
  fi
  say
  say "  야간 완전삭제 — DSM 작업 「DSS Purge」의 로그:"
  cmd "ls -lt /volume1/dss/setup/logs/purge-*.log | head -3"
  nlog=$(ls -1t "$D/setup/logs"/purge-*.log 2>/dev/null | wc -l | tr -d ' ')
  if [ "${nlog:-0}" -gt 0 ]; then
    ok "완전삭제 로그가 ${nlog}개 있다 — 스케줄러에 등록돼 돌고 있다"
    ls -lt "$D/setup/logs"/purge-*.log 2>/dev/null | head -3 | sed 's/^/      /'
    say "    가장 최근 로그의 끝 여섯 줄:"
    tail -6 "$(ls -1t "$D/setup/logs"/purge-*.log 2>/dev/null | head -1)" 2>/dev/null \
      | sed 's/^/      /'
    say "    🔵 「영구 삭제 0 건 · 성공」이면 맞다 — 지울 것이 없다는 뜻이다."
  else
    bad "🔴 완전삭제 로그가 **하나도 없다** — 스케줄러에 등록이 안 된 것이다"
    say "    → 그러면 휴지통이 **한 번도 안 비워지고 있다.** 화면은 「15일 뒤"
    say "      자동 삭제」라고 말하는데 실제로는 안 지워지는 상태다."
    say "    → 🔴 이 스크립트는 등록하지 않는다. 사람이 DSM 화면에서 합니다:"
    say "      [제어판] → [작업 스케줄러] → 예약된 작업 → 사용자 정의 스크립트"
    say "      이름 「DSS Purge」 · 사용자 root · 매일 03:00 (백업 02:30 뒤)"
    say "      명령:"
    cmd "bash /volume1/dss/jobs/purge-nightly.sh"
    say "    (지금 무엇이 얼마나 쌓였는지만 보려면 — 읽기만 합니다:)"
    cmd "sh /volume1/dss/setup/trash-status.sh"
  fi

  # ── 1-ㅈ. 디스크 · DB · 지금 도는 것 ────────────────────────────────
  step "1-ㅈ. 디스크 · DB · 지금 도는 것"
  if pg_up && running dss-pg-auth; then
    ok "DB 둘 다 떠 있다 (이 배포에서 DB 는 멈추지 않는다)"
  else
    bad "DB 가 떠 있지 않다"
  fi
  for t in dss-auth dss-as dss-meters dss-improvements dss-po dss-leave; do
    running "$t" && ok "$t 가 돌고 있다" || bad "$t 가 안 돌고 있다"
  done
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  # 새 tar 둘이 약 200MB, 실은 이미지가 또 그만큼, 덤프가 더 든다.
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (새 tar 둘 약 200MB + 실은 이미지 + 덤프)"
  fi

  # ── 1-ㅊ. 🔴 【검사 ②】 알림 링크의 주소 — A/S 만 ───────────────────
  step "1-ㅊ. 【검사 ②】 알림 링크의 주소 (통로가 아니라 **나오는 주소**를 본다)"
  say "  🔴 **A/S 하나만 본다.** PO 에는 알림 통로가 아예 없다 — api/integration"
  say "     폴더가 그 저장소에 없다(2026-09-29 · 09-30 두 번 실측). PO 의 알림은"
  say "     포털이 모아 준 것을 받아서 그리기만 한다. **없는 것을 찾지 않는다.**"
  notify_href_check "A/S" dss-as "$ENVD/as.env" \
    "https://as.dss21.co.kr" "$TAG_AS" \
    "is also read as this app" \
    "SSO_REDIRECT_URI"

  # ── 1-ㅋ. 새 이미지 **안에** 이번 판의 표시가 있는가 ─────────────────
  step "1-ㅋ. 새 이미지 안에 이번 판의 표시가 있는가 (태그만으로는 안심 못 한다)"
  say "  🔴 9/21~9/29 에 A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다."
  if have_img "$TAG_AS"; then
    say "  $TAG_AS 구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
    mark_check "A/S" "$TAG_AS" "$AS_MARK" "$AS_CTRL"
    say "      (찾는 글자: 수리 건 상세의 새 구역 제목 「$AS_MARK」 — 1.7 에는 없다)"
  fi
  if have_img "$TAG_PO"; then
    say "  $TAG_PO 구운 때: $("$DOCKER" images "$TAG_PO" --format '{{.CreatedAt}}' 2>/dev/null)"
    mark_check "PO" "$TAG_PO" "$PO_MARK" "$PO_CTRL"
    say "      (찾는 글자: 새 메뉴바 묶음이 만든 $PO_MARK — 0.2 에는 없다)"
    say "      🔴 이 표시는 「0.3 이다」를 말해 줄 뿐 「권한이 열렸다」를 말해"
    say "         주지 않는다. 권한은 1-ㄷ 이 DB 로 보고, 마지막에 사람이"
    say "         엔지니어 계정으로 눈으로 본다."
  fi
}

# ══════════════════════════════════════════════════════════════════════
#  compose 갈아 끼우기
#
#  🔴 --check 는 **갈아 끼우지 않는다.** 읽기만 한다는 약속이 먼저다. 대신
#     incoming 에 새 파일이 있으면 **그 파일을** 들여다보고, 갈아 끼우는 것은
#     --go 가 한다고 알려 준다.
#  🔴 바꾸기 **전에** 새 파일을 먼저 시험한다. 없는 env_file 하나면
#     docker compose 명령이 **통째로** 실패해서, 앱을 멈춘 뒤에 그걸 알게 되면
#     다시 띄우지도 못한다.
# ══════════════════════════════════════════════════════════════════════
compose_incoming() {
  local e MISS
  [ -s "$INCOMING" ] || return 0
  if cmp -s "$INCOMING" "$CF"; then
    say "  · incoming 의 compose 가 지금 것과 같다 — 할 일이 없다"
    return 0
  fi
  step "새 compose 를 먼저 시험한다 (바꾸기 전에)"
  MISS=""
  for e in $(sed '/^[[:space:]]*#/d' "$INCOMING" | grep -oE '\./env/[A-Za-z0-9_.-]+\.env' | sort -u); do
    [ -f "$D/deploy/${e#./}" ] || MISS="$MISS ${e#./}"
  done
  if [ -n "$MISS" ]; then
    bad "새 compose 가 **없는 설정 파일**을 가리킨다:$MISS"
    say "    → 하나만 없어도 docker compose 가 통째로 실패한다."
    return 1
  fi
  if compose_at "$INCOMING" config --quiet >/dev/null 2>&1; then
    ok "새 compose 문법 통과"
  else
    bad "새 compose 에 문법 오류가 있다"
    compose_at "$INCOMING" config --quiet 2>&1 | sed 's/^/    /' | head -10
    return 1
  fi
  if [ "$MODE" = go ]; then
    mkdir -p "$BKD"
    cp -p "$CF" "$BKD/docker-compose.nas.yml.$STAMP"
    cp "$INCOMING" "$CF"
    chown root:root "$CF"; chmod 644 "$CF"
    rm -f "$INCOMING"
    ok "compose 새것으로 (옛것: backups/docker-compose.nas.yml.$STAMP)"
    CF_EFF=$CF
  else
    CF_EFF=$INCOMING
    say "  🔵 --check 라서 **갈아 끼우지 않았다.** 아래 검사는 incoming 의 파일을 본 것이다:"
    say "     $INCOMING"
    say "     갈아 끼우는 것은 --go 가 한다."
  fi
  return 0
}

# ══ 되돌리기 ═══════════════════════════════════════════════════════════
if [ "$MODE" = rollback ]; then
  echo "DSS 열째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     둘을 함께 옛 태그로 내리는 일이다:"
  say "       $TAG_AS → $OLD_AS"
  say "       $TAG_PO → $OLD_PO"
  say "  🔴 **둘을 함께 내리세요.** 한쪽만 내리면 같은 사람이 A/S 에서는 되고"
  say "     PO 에서는 안 되는(또는 그 반대의) 상태가 된다 — 이번 판이 두 사이트를"
  say "     함께 올린 바로 그 까닭이다."
  say "  🔴 되돌리면 엔지니어의 내자 정리·견적서가 **다시 막힌다.** 그리고 수리 건"
  say "     상세의 「내자 정리 발행일」 구역과 사진 손보기도 함께 사라진다."

  step "1. 옛 이미지가 아직 NAS 에 있는지 먼저 본다"
  for t in "$OLD_AS" "$OLD_PO"; do
    if have_img "$t"; then
      ok "$t 있다 ($(img_id "$t" | cut -c1-19)…)"
    else
      bad "$t 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"
    fi
  done

  step "2. 태그를 내린다 — 🔴 아래를 **한 줄씩** 친다"
  say "  (DSM 의 ash 는 긴 줄을 자른다. 줄 이어붙임 \\ 도 깨졌다 — 한 줄씩.)"
  cmd "cd /volume1/dss/deploy"
  cmd "F=docker-compose.nas.yml"
  cmd "sed -i 's|$TAG_AS|$OLD_AS|' \$F"
  cmd "sed -i 's|$TAG_PO|$OLD_PO|' \$F"
  say
  say "  ⚠️ 🔴 dss-as-tools:1 은 글자가 겹치지만 위 sed 는 태그까지 붙여"
  say "     갈아 끼우므로 흔들리지 않는다 — 확인:"
  cmd "grep -n 'image: dss-as' \$F"
  cmd "grep -n 'image: dss-po' \$F"

  step "3. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "D1=/usr/local/bin/docker"
  say "  (2단계에서 F 를 이미 정했으면 아래 한 줄은 건너뜁니다.)"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-as app-po"
  script_file_hint "15-rollback"

  step "4. DB — 🔴 **되돌릴 것이 없다**"
  say "  이 배포는 마이그레이션을 **0개** 들고 왔다. 스키마를 한 글자도 건드리지"
  say "  않았으므로 DB 에는 되돌릴 것이 아무것도 없다."
  say "  🔴 그러니 이 되돌리기에는 **DB 를 바꾸는 명령이 한 줄도 없다.**"
  say "     (이 스크립트 전체에 자료를 바꾸는 SQL 이 한 줄도 없다 — 전부 select 다.)"
  say "  ⚠️ role_permissions 표도 건드리지 않는다. 그 표는 배포가 아니라 사람이"
  say "     화면에서 고치는 자리다."

  step "5. 지금 상태"
  for t in dss-as dss-po; do
    say "  $t : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$t " || echo '안 돌고 있다')"
  done
  say "  (포털 · 계측기 · 개선요청 · 휴가 · DB 둘은 이번에 건드리지 않았으므로 그대로다.)"
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터 check · preload · force-load · go ═════════════════════════
echo "DSS 열째 배포 · 2026-09-30 · $(date '+%F %T')"
echo "  🔴 올라가는 것은 **둘**:  $OLD_AS → $TAG_AS · $OLD_PO → $TAG_PO"
echo "  🔴 멈추는 것도 **둘**:  dss-as · dss-po"
echo "  🔴 이번 판의 핵심: **엔지니어에게 내자 정리·견적서를 열었다.**"
echo "     A/S 와 PO 는 같은 DB·같은 권한 열쇠를 쓴다 — 그래서 함께 올린다."
echo "  · 마이그레이션은 **0 개**입니다 — 적용하지 않고 수만 셉니다(106)"
echo "  · 건드리지 않는 여덟 — $KEEP_AUTH · $KEEP_ASTOOLS · $KEEP_METERS"
echo "    · $KEEP_METERSTOOLS · $KEEP_IMP · $KEEP_IMPTOOLS"
echo "    · $KEEP_LEAVE · $KEEP_LEAVETOOLS"
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**" ;;
  preload)    echo "  🔵 --preload — 새 이미지 둘을 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — A/S 와 PO 둘만 교체한다. 나머지 넷은 안 멈춘다."
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(폴더 권한 · 백업)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
#    이미지를 싣는 것은 **아무것도 안 멈춘다.**
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "새 이미지 tar 둘 · 지문"
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  EXP_PO=$(tar_config_id "$TAR_PO" 2>/dev/null) || EXP_PO=""
  for rec in "$TAG_AS|$TAR_AS|$EXP_AS|$SZ_AS|$MD5_AS" \
             "$TAG_PO|$TAR_PO|$EXP_PO|$SZ_PO|$MD5_PO"; do
    IFS='|' read -r tag tarf exp sz md5 <<EOF
$rec
EOF
    if [ ! -s "$tarf" ]; then bad "$tag 의 tar 가 없다: $tarf"; continue; fi
    n=$(stat -c '%s' "$tarf" 2>/dev/null)
    if [ "$n" != "$sz" ]; then
      bad "$tag 의 바이트가 $sz 가 아니다 ($n) — 올리다 끊겼다. 싣지 않는다"
      continue
    fi
    m=$(md5sum "$tarf" 2>/dev/null | awk '{print $1}')
    if [ "$m" != "$md5" ]; then
      bad "$tag 의 md5 가 $md5 가 아니다 (${m:-못 읽음}) — 파일이 상했다. 싣지 않는다"
      continue
    fi
    ok "$tag · 바이트 $n · md5 맞음"
    if [ -z "$exp" ]; then bad "$tag 의 tar 에서 manifest.json 을 읽지 못했다"; continue; fi
    bring_img "$tag" "$tarf" "$exp"
  done

  # 🔴 실어 놓고 **안을 본다.** 태그와 지문이 맞아도 「무엇이 든 판인지」는
  #    사람이 읽을 수 있는 증거로 한 번 더 남긴다.
  step "새 이미지 안에 이번 판의 표시가 있는가"
  if have_img "$TAG_AS"; then
    say "  $TAG_AS 구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
    mark_check "A/S" "$TAG_AS" "$AS_MARK" "$AS_CTRL"
  fi
  if have_img "$TAG_PO"; then
    say "  $TAG_PO 구운 때: $("$DOCKER" images "$TAG_PO" --format '{{.CreatedAt}}' 2>/dev/null)"
    mark_check "PO" "$TAG_PO" "$PO_MARK" "$PO_CTRL"
  fi

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 멈추지 않았다**"
  if [ "$FAIL" != 0 ] && [ "$FORCE_LOAD" != 1 ]; then
    echo "  🔴 지문이 어긋난 것이 있으면 **같은 태그로 다시 구운 것**이다:"
    echo "       bash $0 --force-load"
  fi
  echo "  🔵 나머지 항목은 안 봤다. 이어서: bash $0        (읽기만)"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 1. 먼저 볼 것 ══════════════════════════════════════════════════════
#
# 🔴 규칙 하나: **앱을 멈추기 전에 볼 것을 다 보고, 어긋나면 앱이 살아 있는
#    채로 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
step "1. 점검표를 기계로 옮긴 것 (앱은 살아 있다)"
compose_incoming || stop "compose 를 바꾸지 않았습니다. 앱은 그대로 돕니다."
run_checks

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  if [ "$PERM_PINNED" != 0 ]; then
    echo "  🔴 저장된 권한 값이 기본값을 막고 있는 칸이 ${PERM_PINNED}개 있습니다."
    echo "     배포해도 그 칸은 안 열립니다 — 1-ㄷ 을 읽어 보세요."
    echo "     (✗ 가 아닙니다. 배포는 그대로 진행해도 됩니다.)"
  fi
  if [ "$FAIL" = 0 ]; then
    echo "  ✅ 이어서 (A/S 와 PO 가 잠깐 멈춥니다):  bash $0 --go"
  else
    echo "  ✗ 위 ✗ 를 먼저 해결하세요. Claude 에게 알려 주세요."
  fi
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ --go ═══════════════════════════════════════════════════════════════
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 바꾸지 않았고 앱은 살아 있습니다.**"

# ── 2. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ───────────
# 🔴 **둘만 싣는다.** 건드리지 않는 여덟은 이미 실려서 돌고 있다 — 다시 싣지
#    않는다. (1-ㄴ 이 그 여덟이 NAS 에 있는지 이미 확인했다.)
step "2. 새 이미지 둘 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
FAIL2=0
bring_img "$TAG_AS" "$TAR_AS" "$EXP_AS" || FAIL2=1
bring_img "$TAG_PO" "$TAR_PO" "$EXP_PO" || FAIL2=1
if [ "$FAIL2" = 1 ]; then
  say
  say "  🔴 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
fi

# ══ 3. 마이그레이션 — 🔴 **이번에는 없다. 수만 다시 센다** ════════════
#
# 🔴 이 자리에 `db:migrate` 를 부르는 줄이 **없다.** 스키마를 한 글자도 안
#    건드린 판이라 적용할 것이 없기 때문이다. 대신 앱을 멈추기 직전에 수를
#    한 번 더 세어, 1-ㄹ 과 지금 사이에 누가 무엇을 하지 않았는지 본다.
step "3. 마이그레이션 — 🔴 적용하지 않는다. 앱을 멈추기 직전에 수만 다시 센다"
if pg_up; then
  N_NOW=$(qas "select count(*) from drizzle.__drizzle_migrations")
  say "  지금 적용된 줄: ${N_NOW:-?}  (기대 $N_MIG_WANT)"
  if [ "${N_NOW:-x}" = "$N_MIG_WANT" ]; then
    ok "$N_MIG_WANT 그대로다 — 적용할 것이 없다. 그냥 넘어간다"
  else
    bad "적용된 줄이 $N_MIG_WANT 이 아니다 (${N_NOW:-?})"
    stop "DB 가 기대한 상태가 아닙니다. **앱은 아직 옛 판 그대로 돕니다.**"
  fi
else
  bad "dss-pg-app 이 떠 있지 않다"
  stop "DB 를 볼 수 없습니다. **앱은 아직 옛 판 그대로 돕니다.**"
fi

# ══ 4. A/S 와 PO **둘만** 교체 — 🔴 여기부터 정지 창 ═══════════════════
#
# 🔴 인자 없이 `up -d` 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다(포털·계측기까지 흔들린다).
#    `--no-deps` 로 **이름을 적은 둘만** 부른다.
# 🔴 둘을 **한 번에** 부른다. 권한 열쇠가 같아서, 한쪽만 새 판이 되는 시간이
#    길수록 「A/S 에서는 되는데 PO 에서는 안 된다」는 문의가 들어온다.
step "4. A/S 와 PO 를 함께 교체  ⏱ 여기부터 정지 창"
say "  🔴 **멈추는 것은 dss-as 와 dss-po 둘뿐이다.**"
say "     그대로 도는 것: 포털 · 계측기 · 개선요청 · 휴가 · DB 둘."
say "     즉 https://as.dss21.co.kr 와 https://po.dss21.co.kr 만"
say "     몇십 초 대답하지 않는다."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"

say "  4-ㄱ. A/S ($OLD_AS → $TAG_AS) · PO ($OLD_PO → $TAG_PO)"
"${COMPOSE[@]}" up -d --no-deps app-as app-po 2>&1 | sed 's/^/    /'
wait_http "A/S" "$AS_PORT" / dss-as
wait_http "PO"  "$PO_PORT" / dss-po

UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 5. 스모크 ══════════════════════════════════════════════════════════
step "5. 스모크 — 폴더 · 견적서 공유폴더 · 알림 · 🔴 권한 · 바깥 주소"

# ② 새 컨테이너로 폴더를 **실제로 열어 본다.**
# 🔴 쓰기까지 보는 것은 **이번에 새로 뜬 둘**뿐이다. 계측기·개선요청은 이번에
#    교체하지 않았으니(컨테이너가 그대로다) 「아직 읽히는가」만 본다.
say "  5-ㄱ. 폴더를 컨테이너 안에서 실제로 연다"
probe_svc app-as dss-as "A/S" "/data:rw /templates:ro" "$ATT $TEMPLATES"
probe_svc app-po dss-po PO    "/data:rw /templates:ro" "$ATT $TEMPLATES"
probe_svc app-meters       dss-meters       계측기   "/data:ro"         "$MF_METERS"
probe_svc app-improvements dss-improvements 개선요청 "/data/uploads:ro" "$UP_IMP"

# 견적서 공유폴더 — 🔴 여기서는 ACL 을 걷으면 안 된다(직원의 탐색기가 끊긴다).
say "  5-ㄴ. 견적서 공유폴더 (A/S 와 PO 가 발행할 자리)"
for rec in "dss-as|A/S" "dss-po|PO"; do
  s=${rec%%|*}; p=${rec##*|}
  if running "$s"; then
    "$DOCKER" exec "$s" sh -c 'set -e; t=/quote-archive/.dss-write-test; : > "$t"; rm -f "$t"' >/dev/null 2>&1 \
      && ok "$p 가 견적서 공유폴더에 쓸 수 있다" \
      || { bad "$p 가 견적서 공유폴더에 못 쓴다 — 발행이 Permission denied 로 끝난다"
           say "    🔴 여기는 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기 접근이 끊긴다."
           say "       compose 의 $s 쪽에 group_add: [\"100\"] 이 있는지부터 보세요."; }
  else
    bad "$s 컨테이너가 떠 있지 않다"
  fi
done

# 통로가 **있는가** — A/S 만. PO 에는 이 통로가 없다.
say "  5-ㄷ. 알림 통로 — 포털 $KEEP_AUTH 가 묻는 자리 (A/S 만)"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 \
       "http://127.0.0.1:$AS_PORT/api/integration/notifications" 2>/dev/null)
case "$code" in
  404) bad "A/S 의 /api/integration/notifications 가 404 다 — **옛 이미지다**" ;;
  000|"") bad "A/S 의 알림 통로가 대답하지 않는다 (${code:-없음})" ;;
  *)   ok "A/S 의 알림 통로가 있다 (토큰 없이 부르면 401 이 맞다 — 지금 $code)" ;;
esac
say "      ⚠️ PO 에는 이 통로가 없다(그 저장소에 api/integration 폴더가 없다)."
say "         🔴 **찾지 않는다.** 없는 것을 찾으면 없는 결함이 생긴다."
say "      🔴 이 줄 하나로는 9/29 의 결함을 못 잡았다. 아래 5-ㄹ 를 보세요."

# 🔴 그 통로가 **내주는 주소**가 밖에서 닿는가.
say "  5-ㄹ. 🔴 알림 링크의 주소 — 새로 뜬 컨테이너로 다시 본다"
say "      (1-ㅊ 와 같은 검사다. 교체 **뒤에** 한 번 더 보는 것이 이 자리의 일이다.)"
notify_href_check "A/S" dss-as "$ENVD/as.env" \
  "https://as.dss21.co.kr" "$TAG_AS" \
  "is also read as this app" \
  "SSO_REDIRECT_URI"

# 🔴 이번 판의 핵심 — 교체 뒤에 권한을 한 번 더 본다.
say "  5-ㅁ. 🔴 엔지니어 권한 — 교체 뒤에 다시 본다 (select 만)"
perm_check

say "  5-ㅂ. 바깥 주소 — 바뀌는 쪽"
for h in as po; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code" ;;
    *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
  esac
done
# 🔴 건드리지 않기로 한 넷이 그대로인지 본다. 흔들렸으면 이 배포가 건드린 것이다.
say "  🔴 안 바뀌는 쪽 — 흔들렸으면 **이 배포가 건드린 것**이다:"
for h in login meters improvements leave; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code (건드리지 않은 쪽 · 그대로다)" ;;
    *)       bad "🔴 https://$h.dss21.co.kr → ${code:-없음} — 건드리지 않기로 한 쪽이 흔들렸다" ;;
  esac
done
say "  열린 포트 (127.0.0.1 만이어야 한다):"
netstat -tln 2>/dev/null | grep ':13[0-9]\{3\}' | sed 's/^/      /'
say "  지금 도는 이미지:"
"$DOCKER" ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | sed 's/^/      /'

# ══ 6. 마무리 ══════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · 약 ${DOWN}초"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" != 0 ]; then
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
  echo "되돌리기 안내:  bash $0 --rollback"
  exit "$FAIL"
fi
if [ "$PERM_PINNED" != 0 ]; then
  echo
  echo "🔴 저장된 권한 값이 기본값을 막고 있는 칸이 ${PERM_PINNED}개 있습니다."
  echo "   **배포는 잘 끝났지만 그 칸은 아직 엔지니어에게 안 열립니다.**"
  echo "   A/S → [사용자 관리] → [역할별 접근 권한] → AS_ENGINEER 줄에서"
  echo "   그 칸을 올리고 저장하세요. 이번 변경으로 드롭다운의 상한은 열렸습니다."
fi
cat <<ANNOUNCE

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. 🔴 **엔지니어 계정으로 로그인하세요.** 이것이 이 판의 전부입니다.
      · A/S(https://as.dss21.co.kr) 메뉴에 [내자 정리] · [견적서]가
        보입니까. 눌러서 열립니까.
      · PO(https://po.dss21.co.kr) 에서도 같은 둘이 열립니까.
        🔴 **두 사이트가 같아야 합니다.** 한쪽만 되면 한쪽 이미지가
        안 올라간 것입니다.
      · 내자 정리 줄 하나를 열어 **고쳐서 저장**됩니까.
      · 🔴 **삭제 · 휴지통은 여전히 막혀 있어야 합니다** (관리자 이상).
      · [작업 비용]은 **보이기만** 하고 값 수정은 막혀 있어야 합니다.
      · 재고 담당자 계정은 한 글자도 안 바뀌었습니다.
   2. 수리 건 상세 — 「내자 정리 발행일」 구역이 보입니까.
      · 견적서 발행일 · PO 발행일 두 칸이 있습니까.
      · 🔴 **내자 줄이 하나도 없는 수리 건**에서 날짜를 넣고 저장하면
        내자 정리에 줄이 하나 생겨야 맞습니다.
      · 내자 줄이 여럿인 건은 편집이 막혀 있어야 맞습니다.
   3. 이름이 「PO 발행일」로 바뀌었습니까 (「PO 발행 일시」가 아닙니다).
      · 주간보고 상세표의 머리말
      · 🔴 **인쇄물**에도 새 이름으로 찍히는지 한 장 뽑아 보세요.
   4. 사진 손보기 (수리 건의 사진 하나를 크게 열어서):
      · 확대 · 회전 · 뒤집기가 됩니까
      · 아래 썸네일 줄이 보이고, 돌리면 썸네일도 함께 돕니까
      · 돌린 것이 **원본에 저장**됩니까
      · 여러 장을 골라 **한 번에** 돌릴 수 있습니까
      · Shift 로 사이를 **연속으로** 고를 수 있습니까
      · 미리보기가 **잘리지 않고 전체가** 보입니까
   5. A/S 의 알림 종을 열고 아무 알림이나 눌러 보세요.
      · 주소창이 https://as.dss21.co.kr 로 시작해야 맞습니다.
      · 172. 로 시작하면 컨테이너 주소라 밖에서 안 열립니다.
      · 🔴 종이 비어 있으면 밀린 일이 없는 것입니다 — 오류가 아닙니다.
   6. 🔴 **포털 · 계측기 · 개선요청 · 휴가가 그대로입니까** — 이번 판은
      그 넷을 건드리지 않았습니다. 이상하면 남의 변경이 섞인 것입니다.

🔴 사람이 이어서 할 일:
  · 직원에게 알립니다 — 「엔지니어도 내자 정리와 견적서를 쓸 수 있다」.
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.
  · 내일 아침 백업을 한 번 더 보세요 — 다섯이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -7

되돌리기 안내:  bash $0 --rollback
ANNOUNCE
exit "$FAIL"
