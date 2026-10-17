#!/bin/bash
# /volume1/dss/setup/29-deploy.sh — 2026-10-17 스물셋째 배포
#
# ── 무엇이 올라가는가 — 🔵 **아주 단순하다** ──────────────────────────
#
#   사내 사이트 여덟 중 **하나**만 올라간다. 순서도 없고 짝도 없다.
#
#     A/S        dss-as:2.6   →  **dss-as:2.7**   (커밋 646796f 하나)
#
#   🔴 멈추는 것은 **dss-as 하나뿐**이다.
#   🔵 안 멈추는 일곱 — 재고 관리 · 포털 · 계측기 · 개선요청 · PO · 휴가 ·
#      게시판. (DB 둘도 안 멈춘다.)
#
#   🔵 마이그레이션 **0건.** 코드 116 = 개발 116 = 운영 116 — **DB 를 한 줄도
#      안 바꾼다.** 그래서 이 스크립트에는 DB 를 바꾸는 문장이 **하나도 없다**
#      (전부 select 다).
#   🔵 설정(.env) 변경 **없음.** 볼륨 · 공유폴더 변경 **없음.**
#   🔵 A/S 도구(dss-as-tools:1)도 **다시 굽지 않는다** — 적용할 것이 없다.
#   🔵 서브모듈 vendor/dss-core 는 2.6 과 같은 2ecdf01 이다(바뀐 것이 없다).
#
# ══ 🔴 무엇이 고쳐지나 — **운영 장애 복구다** ═════════════════════════
#
#   운영에서 쓰는 분이 고객사 세 곳의 이름을 정식 상호로 고쳤다:
#       ICD      → (주)아이씨디
#       INVENIA  → 인베니아(주)
#       JUSUNG   → 주성엔지니어링(주)
#
#   A/S 의 「고객 안내 현황」(https://as.dss21.co.kr/customer-portal)은 고객사
#   이름을 **코드에 박아 둔 글자 목록**과 정확히 맞춰 양식을 가린다
#   (src/lib/domain/customer-portal-forms.ts 의 customerNames. 부분 일치를
#    일부러 안 쓴다). 그 순간 **코드가 알던 여덟 이름 중 운영에 남은 것이
#   0개**가 되어, 표 셋이 통째로 사라지고 화면은
#       「양식이 정해진 고객사가 없습니다.」
#   만 띄웠다. 🔴 **오류도 빈 표도 아니라 원인이 안 보인다.**
#
#   2.7 은 그 목록에 새 상호 셋을 **더한** 판이다(옛 이름은 안 지운다).
#
# ══ 🔴 그래서 이 배포의 확인은 「돈다」가 아니다 ══════════════════════
#
#   🔴 **2.6 도 돌고 있었다.** 돌면서 표를 못 세운 것이 이번 장애다.
#      그래서 --go 의 스모크는 **고쳐졌다는 것을 값으로** 본다. 셋이다:
#
#     ㄱ. 운영 DB 에 그 세 이름이 각각 **1줄씩** 있는가 (읽기 전용 select)
#     ㄴ. 도는 컨테이너 **안**의 빌드 산출물이 그 세 이름을 **아는가**
#         (🔴 셋 다 나와야 한다. 하나라도 0이면 옛 이미지가 도는 것이다.)
#     ㄷ. 건드리지 않은 일곱이 정말 **안 멈췄는가** (시작 시각 대조)
#
#   🔵 ㄴ 을 어떻게 재는가 — Next.js 빌드 산출물은 번들이지만 **문자열
#      리터럴은 그대로 남는다.** 다만 작은 도구가 한글을 \uXXXX 로 바꿔
#      적을 수 있어 **두 꼴을 다 찾아본다.** 그리고 **대조 표시 셋**을 먼저
#      찾는다 — 2.6 에도 2.7 에도 있는 글자다:
#        QUOTE_ARCHIVE_UNC_ROOT  (영문 · 28번이 실제로 찾아낸 자리)
#        ICD Co.,Ltd.            (영문 · 🔴 **고치는 바로 그 목록 안**에 있다)
#        주성 엔지니어링          (한글 · 한글이 어느 꼴로 들어 있는지 가른다)
#      🔴 대조 표시가 안 나오면 **판정하지 않는다.** 「글자를 못 읽은 것」과
#         「옛 판인 것」을 가를 수 없기 때문이다(19번 이래의 규율).
#         지어내지 않고 **못 읽었다고 출력한다.**
#
# ══ 🔴 되돌리는 길 — **이미지만 되돌리면 완전히 돌아간다** ════════════
#
#   🔵 이번 판은 **DB 를 한 줄도 안 바꾼다.** 설정도 볼륨도 안 바꾼다.
#      그래서 되돌릴 것이 **compose 한 줄과 컨테이너 하나**뿐이고,
#      되돌리면 **배포 전과 글자 하나까지 같은 상태**가 된다.
#      덤프를 되감을 일도, 「DB 는 두고 앱만 내린다」 같은 단서도 없다.
#
#   되돌리는 차례 (명령은 --rollback 이 찍어 준다):
#     1) compose 를 사본으로 되돌린다  backups/docker-compose.nas.yml.<도장>
#        (--go 가 image 줄을 고치기 **전에** 뜬 사본이다)
#     2) /usr/local/bin/docker compose … up -d --no-deps app-as
#     3) 끝이다. DB 도 설정도 손대지 않았으므로 **되돌릴 것이 없다.**
#
#   🔴 dss-as:2.6 이 NAS 에 그대로 있어야 한다. 검사가 그것을 센다.
#      **이미지는 지우지 않는다.**
#
# ══ 🔴 compose — **저장소 사본을 올리지 않는다** ══════════════════════
#
#   🔴 이 저장소의 nas/docker-compose.nas.yml 은 운영 파일과 다르다
#      (27번이 NAS 에서 재고 관리 블록의 주석을 벗겼고, 저장소 사본은 아직
#       그대로다. 올리면 **재고 관리가 compose 에서 통째로 사라진다**).
#   → 그래서 이 스크립트가 **NAS 의 파일에서 image 줄 하나만** 고친다:
#        image: dss-as:2.6   →   image: dss-as:2.7
#      · 고치기 **전에** 사본을 뜬다(backups/docker-compose.nas.yml.<도장>)
#      · 글자 비교다 — 정규식이 아니다(태그의 점이 아무 글자나 맞는 일이 없게)
#      · 바꾸기 전 「옛 태그 1줄 · 새 태그 0줄」, 바꾼 뒤 「0줄 · 1줄」을 센다
#      · 줄 수가 한 줄이라도 달라지면 **사본으로 되돌리고 멈춘다**
#      · 건드리지 않는 열세 태그가 그대로인지 세고, compose config 를 다시 돈다
#   🔴 태그를 고쳐도 **아무것도 안 뜨고 안 멈춘다.** compose 는 글자일 뿐이다.
#      다만 그 뒤로 누가 **인자 없는 up -d** 를 부르면 새 판이 올라온다 —
#      부르지 마세요(19번이 적어 둔 그 당부).
#
# ══ 🔵 돌리기 전에 — **값 셋은 채워져 있다** ══════════════════════════
#
#   🔵 **2026-10-17 에 개발 PC 에서 재어 채웠다**:
#        SZ_AS        131561472
#        MD5_AS       dcb922d4107c2613c076a76adf3f1d9e
#        WANT_CFG_AS  sha256:19e8545f…0443f0
#      (하나라도 비면 --check 는 경고로만 말하고 🔴 **--go 는 시작하지 않는다** —
#       잰 적 없는 이미지를 운영에 올리지 않는다. 지금은 셋 다 차 있다.)
#   🔴 그래도 NAS 에서 다시 잰다 — tar 를 옮기다 끊기거나 다른 판을 올렸을 수
#      있다. 1-ㄱ 이 바이트 · md5 · tar 안 Config 지문을 **셋 다** 맞춰 본다.
#   굽고 재는 차례는 이 파일 맨 아래 「사람이 칠 명령」 절에 있다.
#   🔴 tar 가 이미지의 1/4 쯤인 것은 **정상**이다. 지난 판과 견주세요 —
#      dss-as-2.6.tar 는 131,566,592 바이트였다.
#   🔴 tar 안 Config 지문은 개발 PC 의 {{.Id}} 와 **다르다.** NAS 는 tar 안의
#      config 지문을 image ID 로 낸다 — 맞춰 볼 값은 **tar 쪽**이다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/29-deploy.sh        ← 읽기만 한다
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#   · MODE=check   · FORCE_LOAD=0
#   컨테이너를 바꿔 끼우는 곳은 --go 한 군데뿐이고, --check 는 그것을
#   **부르지 않는다.**
#   🔴 정직하게 적어 둔다 — --check 도 이미지 **안을 보려고** 컨테이너를
#      잠깐 띄웠다 지운다(docker run --rm). 「아무것도 안 한다」가 아니라
#      「아무것도 **바꾸지** 않는다」가 정확하다. DB 쪽은 전부 select 다.
#
# ── 모드 넷 ─────────────────────────────────────────────────────────────
#   (없음) · --check   읽기만. 아무것도 안 바꾸고 안 멈춘다        ← 기본값
#   --preload          이미지 하나를 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load       🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --go               ⏱ compose 한 줄 + dss-as 바꿔 끼우기
#   --rollback         되돌리는 명령을 찍는다 (아무것도 안 바꾼다)
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 29-deploy.sh                 읽기만
#   2) bash 29-deploy.sh --preload       이미지를 싣는다
#   3) bash 29-deploy.sh                 다시 읽기만 (지문까지)
#   4) bash 29-deploy.sh --go            ⏱ 정지 창 (dss-as 하나)
#   5) 눈으로 확인 (--go 끝의 안내)
#
# ══ 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ═══════════════════════
#   ① 큰따옴표 안의 백틱은 **명령 치환**으로 읽힌다.
#      → 이 파일에는 백틱이 **한 개도 없다**. 주석에도 안 썼다(28번에는
#        주석에 둘 남아 있다). 쓴 뒤 세어서 0 인 것을 확인했다.
#   ② 읽기 전용 자리에 리다이렉션을 쓰면(콜론 하나 뒤에 꺾쇠) NAS 의 ash 가
#      셸을 그 자리에서 끝낸다.
#      → 이 파일에는 그 꼴이 **한 군데도 없다**. 빈 파일은 touch, 폴더는
#        mkdir 로 만든다. 쓴 뒤 세어서 0 인 것을 확인했다.
#   🔴 19 · 20 · 21번에는 아직 남아 있다 — 베낄 때 함께 베끼지 않았다.
#
# ══ DSM 터미널은 긴 명령을 잘라 먹는다 ════════════════════════════════
#   그래서 NAS 에서 돌릴 것은 **파일로 올리고 md5 를 맞춘 뒤** 실행한다.
#   🔵 이 스크립트는 **시작할 때 자기 md5 를 찍는다.** 개발 PC 의
#      Get-FileHash 값과 다르면 올리다 잘린 것이다 — 돌리지 말고 다시 올린다.
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
IMAGES=$D/images
BKD=$D/backups

# ── 🔴 이번에 올라가는 것 **하나** ─────────────────────────────────────
TAG_AS=dss-as:2.7;  OLD_AS=dss-as:2.6

# ── tar 하나 ───────────────────────────────────────────────────────────
# 🔵 **2026-10-17 에 개발 PC 에서 재어 채웠다** (dss-as-2.7.tar).
#    지난 판 dss-as:2.6 의 tar 는 131,566,592 바이트였다 — 이번이 **5,120 바이트
#    작다.** 고친 것이 상수 배열 셋과 주석·시험뿐이라 맞는 크기다.
# 🔴 WANT_CFG_AS 는 tar 의 manifest.json 이 「blobs/sha256/…」 로 내는 값에서
#    앞의 「blobs/」 를 떼고 **「sha256:」 을 붙인 꼴**이다. tar_config_id() 가
#    내는 꼴이고 NAS 의 image .Id 와 같은 꼴이다 — 꼴이 다르면 ✓ 가 안 난다.
TAR_AS=$IMAGES/dss-as-2.7.tar
SZ_AS="131561472"
MD5_AS="dcb922d4107c2613c076a76adf3f1d9e"
WANT_CFG_AS="sha256:19e8545f2eada208cbda4d8e7d203d65fb38ad62b1a858bc988c4847880443f0"

# ── 🔴 **건드리지 않는 열셋.** ─────────────────────────────────────────
# 전부 지금 운영에서 돌고 있다. compose 에서 이 태그가 흔들렸으면 남의 것이
# 섞인 것이다(두 세션이 같은 저장소를 쓴다). 고치지 말고 **먼저 알린다.**
# 🔴 이 목록은 **2026-10-17 00:15 스물두째 배포 직후** 기준이다.
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
KEEP_INV=dss-inventory:0.2
KEEP_INVTOOLS=dss-inventory-tools:2
KEEP_TAGS="$KEEP_AUTH $KEEP_ASTOOLS $KEEP_METERS $KEEP_METERSTOOLS"
KEEP_TAGS="$KEEP_TAGS $KEEP_IMP $KEEP_IMPTOOLS $KEEP_PO $KEEP_LEAVE"
KEEP_TAGS="$KEEP_TAGS $KEEP_LEAVETOOLS $KEEP_BOARD $KEEP_BOARDTOOLS"
KEEP_TAGS="$KEEP_TAGS $KEEP_INV $KEEP_INVTOOLS"
# 건드리지 않는 **일곱 사이트**의 컨테이너와 바깥 이름
KEEP_BOXES="dss-auth dss-meters dss-improvements dss-po dss-leave dss-board"
KEEP_BOXES="$KEEP_BOXES dss-inventory"
KEEP_HOSTS="login meters improvements po leave board inventory"
# compose 에 반드시 있어야 하는 서비스 열넷
SVC_ALL="app-auth app-as tools-as app-meters tools-meters app-improvements"
SVC_ALL="$SVC_ALL tools-improvements app-po app-leave tools-leave app-board"
SVC_ALL="$SVC_ALL tools-board app-inventory tools-inventory"

# ── 서비스 · 포트 · 컨테이너 ───────────────────────────────────────────
AS_SVC=app-as
AS_CNAME=dss-as
AS_PORT=13000
AS_BASE=https://as.dss21.co.kr

# ══ 🔴 마이그레이션 **0건** — 값 **넷**으로 센다 ══════════════════════
#
# 🔴 「0건이다」를 말로 하지 않는다. **넷이 모두 116** 이어야 ✓ 다:
#      ① 운영 DB 에 적용된 줄 수          (dss_as 의 drizzle.__drizzle_migrations)
#      ② NAS 볼륨의 .sql 수               (/volume1/dss/as-migrations)
#      ③ 그 볼륨 meta/_journal.json 의 tag 줄 수
#      ④ 🔴 **$TAG_AS 이미지 안 /app/drizzle 의 .sql 수**
#    하나라도 어긋나면 **멈추고 아무것도 바꾸지 않는다** — 「DB 를 안 바꾼다」가
#    이번 배포의 전제이기 때문이다.
#
# 🔴 ④ 가 왜 셋보다 나은가 — **볼륨은 사람이 올리는 것이고, 이미지는 코드와
#    함께 굳는다.** 볼륨만 보면 「올리는 것을 깜빡했다」와 「원래 올릴 것이
#    없다」를 가르지 못한다. 이번엔 올릴 것이 없는 쪽이 맞고, 그것을
#    **이미지가 증언**하게 한다.
#
# 🔵 2026-10-17 실측 — dss-as:2.7 이미지 안에 **/app/drizzle 이 있다**:
#      .sql 116개 · meta/_journal.json 의 tag 116개.
#    (Dockerfile 에 「COPY drizzle」 줄은 없지만 Next 의 standalone 파일 추적이
#     담는다. 🔴 「runner 이미지에는 drizzle 이 안 들어간다」고 적었던 앞 판단은
#     **틀렸다** — 실제로 구워서 안을 센 값이 위와 같다.)
# 🔵 적용을 **돌리는** 쪽은 여전히 볼륨이다(tools-as 의 /app/drizzle:ro).
#    그래서 ②③ 과 ④ 를 **둘 다** 센다 — 같은 값이어야 한다.
# 🔴 이미지 안을 못 읽었을 때는 **판정하지 않는다.** 0 을 「0건이니 통과」로
#    읽지 않는다 — 이름 세기에서 한 것과 같은 규율이다.
AS_DB=dss_as
AS_MIG=116
MIGDIR=$D/as-migrations
# 이미지 안에서 셀 자리 (실측으로 확인된 경로)
IMG_MIGDIR=/app/drizzle
TAG_PAT='"tag"'

# ══ 🔴 이번 판정의 알맹이 — 이름 셋 ═══════════════════════════════════
#
# 🔴 운영에서 바뀐 정식 상호 셋. 코드(2.7)의 customerNames 에 이 셋이 더해졌다.
N_ICD='(주)아이씨디'
N_INV='인베니아(주)'
N_JUS='주성엔지니어링(주)'
# 🔵 같은 글자를 \uXXXX 로 적은 꼴. 작은 도구가 한글을 이렇게 바꿔 적어도
#    찾아내려고 둘 다 본다. (값은 개발 PC 에서 코드포인트로 뽑았다.)
N_ICD_ESC='(\uc8fc)\uc544\uc774\uc528\ub514'
N_INV_ESC='\uc778\ubca0\ub2c8\uc544(\uc8fc)'
N_JUS_ESC='\uc8fc\uc131\uc5d4\uc9c0\ub2c8\uc5b4\ub9c1(\uc8fc)'
# 🔴 대조 표시 셋 — 2.6 에도 2.7 에도 **있어야 하는** 글자다.
#    이것이 안 나오면 글자를 못 읽은 것이므로 **판정하지 않는다.**
CTRL_A='QUOTE_ARCHIVE_UNC_ROOT'
CTRL_B='ICD Co.,Ltd.'
CTRL_K='주성 엔지니어링'
CTRL_K_ESC='\uc8fc\uc131 \uc5d4\uc9c0\ub2c8\uc5b4\ub9c1'
# 🔵 참고용 — 코드가 알던 옛 이름들. 운영에 몇 줄 남았는지 **보여만 준다.**
OLD_ICD1='ICD'
OLD_INV1='INVENIA'
OLD_INV2='INVENIA Co.,Ltd'
OLD_INV3='INVENIA Co.,Ltd.'
OLD_JUS1='JUSUNG'
OLD_JUS2='주성 엔지니어링'
OLD_JUS3='주성엔지니어링'
# 고친 화면
PORTAL_PATH=/customer-portal

# ── as.env — 🔴 **이름만 센다. 값은 한 글자도 안 찍는다.** ─────────────
# 이번 판은 설정을 **안 바꾼다.** 그런데 컨테이너를 다시 띄우는 자리라,
# 누가 덮어써서 줄이 사라졌으면 **지금 드러난다.** 그래서 이름만 센다.
AS_LINK_KEYS="AS_API_TOKEN INVENTORY_API_BASE_URL INVENTORY_API_TOKEN INVENTORY_WRITE_TOKEN"
# 🔴 고치는 화면이 바로 이 줄들을 쓴다 (고객 안내 현황의 보관 폴더)
AS_PORTAL_KEYS="CUSTOMER_PORTAL_ARCHIVE_DIR CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT"
AS_PORTAL_KEYS="$AS_PORTAL_KEYS CUSTOMER_PORTAL_ARCHIVE_FOLDER_PATH"
AS_OTHER_KEYS="QUOTE_ARCHIVE_DIR QUOTE_ARCHIVE_UNC_ROOT CONTACT_FOLDER_ARCHIVE_DIR"
AS_OTHER_KEYS="$AS_OTHER_KEYS REPAIR_DOCS_ARCHIVE_DIR PURCHASE_ORDER_ARCHIVE_DIR"
# as.env 에 있으면 안 되는 것 (compose 가 넘긴다)
AS_FORBIDDEN="DATABASE_URL UPLOADS_DIR PORT"

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 둘. 인자가 없으면 이대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 29-deploy.sh                 읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 29-deploy.sh --check         위와 같습니다
  bash 29-deploy.sh --preload       이미지 하나를 싣고 지문을 맞춥니다
  bash 29-deploy.sh --force-load    🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 29-deploy.sh --go            ⏱ compose 한 줄 + dss-as 바꿔 끼우기
  bash 29-deploy.sh --rollback      되돌리기 안내 (아무것도 안 바꿉니다)

  🔴 차례:  (없음) → --preload → (없음) → --go
  🔴 --go 가 바꿔 끼우는 것은 **app-as 하나**입니다. 재고 관리 · 포털 ·
     계측기 · 개선요청 · PO · 휴가 · 게시판 · DB 둘은 그대로 돕니다.
  🔵 마이그레이션이 **0건**이라 --migrate 가 없습니다. 이 스크립트는 운영
     DB 를 **한 줄도 바꾸지 않습니다**(전부 select 입니다).
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

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/29-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 28번의 것을 그대로 쓴다 ───────────────────────────────────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""; DOWN=0
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
  fi
}

# 🔵 28번은 bash 배열(COMPOSE=(…))을 썼다. 여기서는 함수 하나로 쓴다 —
#    하는 일은 같고, 배열을 안 쓰므로 더 단순하다.
compose_cmd() { "$DOCKER" compose --project-directory "$D/deploy" -f "$CF" --env-file "$ENV_NAS" --profile tools "$@"; }

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미 — 🔴 **전부 select 다. 바꾸는 문장이 하나도 없다.**
#
#  🔴 컨테이너 안에서 유닉스 소켓으로 붙는다(superuser). 읽기에는 그것으로
#     충분하다. 이번 판은 롤도 비밀번호도 건드리지 않는다.
# ══════════════════════════════════════════════════════════════════════
qas() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -Atc \"$1\"" 2>/dev/null; }

pg_up()   { "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-app; }
running() { "$DOCKER" ps --format '{{.Names}}' | grep -qx "$1"; }

as_mig_count() { qas "select count(*) from drizzle.__drizzle_migrations"; }
as_tbl_count() { qas "select count(*) from information_schema.tables where table_schema='public'"; }
cust_count()   { qas "select count(*) from customers where is_deleted = false"; }
# 🔴 이름 하나가 **살아 있는 고객사**로 몇 줄인가 (읽기 전용)
name_rows()    { qas "select count(*) from customers where is_deleted = false and name = '$1'"; }
name_rows_del(){ qas "select count(*) from customers where is_deleted = true  and name = '$1'"; }

# ── 설정 파일 — 🔴 이름만 본다 ─────────────────────────────────────────
env_has() { grep -qE "^[[:space:]]*(export[[:space:]]+)?$2=" "$1" 2>/dev/null; }
env_dups() {
  # 🔴 「|| echo 0」을 붙이지 않는다. grep -c 는 0건일 때도 0 을 찍고 종료코드만
  #    1 이라, 붙이면 값이 두 줄이 되어 비교가 전부 어긋난다(27번의 그 자리).
  grep -cE "^[[:space:]]*(export[[:space:]]+)?$2=" "$1" 2>/dev/null
}

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

# 🔴 기대값 셋이 다 찼는가. 비어 있으면 --go 는 시작하지 않는다.
pinned() { [ -n "$SZ_AS" ] && [ -n "$MD5_AS" ] && [ -n "$WANT_CFG_AS" ]; }

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

# ── compose 파일에서 서비스 한 덩어리만 잘라 낸다 (27 · 28번) ──────────
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

# ══════════════════════════════════════════════════════════════════════
#  🔴 compose 의 image 줄을 **글자로** 센다 — 정규식이 아니다
#
#  태그에는 점이 들어 있다(2.6 · 2.7). 정규식으로 보면 그 점이 아무 글자나
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
compose_swapped() { [ "$(img_line_count "$CF" "$TAG_AS")" = 1 ]; }

swap_tag() {
  local nb na tmp bk oldt
  bk="$BKD/docker-compose.nas.yml.$STAMP"
  tmp="$CF.29new"
  mkdir -p "$BKD"
  cp -p "$CF" "$bk" || { bad "compose 사본을 못 떴다"; return 1; }
  chmod 644 "$bk"
  ok "compose 사본 — backups/docker-compose.nas.yml.$STAMP"
  nb=$(wc -l < "$CF")
  # ① 바꾸기 전 — 옛 태그가 **정확히 한 줄**, 새 태그는 **없어야** 한다
  if [ "$(img_line_count "$CF" "$OLD_AS")" != 1 ]; then
    bad "🔴 compose 에 「image: $OLD_AS」 줄이 하나가 아니다"
    say "    → 남의 변경이 섞였거나 이미 바뀐 뒤다. 고치지 말고 알리세요."
    return 1
  fi
  if [ "$(img_line_count "$CF" "$TAG_AS")" != 0 ]; then
    bad "🔴 compose 에 「image: $TAG_AS」 줄이 **이미 있다**"
    return 1
  fi
  # ② 글자로 바꾼다 — 정규식이 아니다. 들여쓰기는 그대로 둔다.
  awk -v oa="image: $OLD_AS" -v na="image: $TAG_AS" '
    { line = $0
      t = line; gsub(/^[ \t]+/, "", t); gsub(/[ \t\r]+$/, "", t)
      ind = substr(line, 1, length(line) - length(t))
      if (t == oa) { print ind na; next }
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
  if [ "$(img_line_count "$CF" "$TAG_AS")" = 1 ] \
     && [ "$(img_line_count "$CF" "$OLD_AS")" = 0 ]; then
    ok "$OLD_AS → $TAG_AS"
  else
    bad "🔴 $TAG_AS 로 안 바뀌었다 — **사본으로 되돌린다**"
    cp -p "$bk" "$CF"; chown root:root "$CF"; chmod 644 "$CF"
    return 1
  fi
  # ⑤ 건드리지 않는 열셋이 그대로인가
  for oldt in $KEEP_TAGS; do
    [ "$(img_line_count "$CF" "$oldt")" -ge 1 ] 2>/dev/null \
      || { bad "🔴 $oldt 가 compose 에서 사라졌다 — **되돌린다**"
           cp -p "$bk" "$CF"; chown root:root "$CF"; chmod 644 "$CF"
           return 1; }
  done
  ok "건드리지 않는 열셋이 compose 에 그대로다"
  # ⑥ 문법
  if compose_cmd config --quiet >/dev/null 2>&1; then
    ok "바꾼 compose 의 문법이 통과했다"
  else
    bad "🔴 바꾼 compose 에 문법 오류가 있다 — **사본으로 되돌린다**"
    compose_cmd config --quiet 2>&1 | sed 's/^/      /' | head -8
    cp -p "$bk" "$CF"; chown root:root "$CF"; chmod 644 "$CF"
    return 1
  fi
  say "  🔴 태그만 고쳤다 — **아무것도 안 뜨고 안 멈췄다.** compose 는 글자일 뿐이다."
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 【이번 배포의 핵심】 빌드 산출물이 **세 이름을 아는가**
#
#  🔴 「돈다」로는 못 가른다 — 2.6 도 돌면서 표를 못 세웠다. 그래서 이미지
#     **안의 글자**를 센다. Next.js 의 standalone 빌드는 번들이지만 문자열
#     리터럴은 그대로 남는다.
#  🔵 한글이 \uXXXX 로 적혀 있을 수 있어 **두 꼴을 다** 찾는다.
#  🔴 값은 **-e 로만** 넘긴다. 명령줄에 적으면 ps 와 로그에 남는다.
#  🔴 대조 표시가 안 나오면 **판정하지 않는다** — 못 읽은 것과 옛 판인 것을
#     가를 수 없기 때문이다. 지어내지 않고 「못 읽었다」고 출력한다.
# ══════════════════════════════════════════════════════════════════════
NAME_SCAN_SH='
R=/app/.next
[ -d "$R/server" ] && echo "DIR server 1" || echo "DIR server 0"
[ -d "$R/static" ] && echo "DIR static 1" || echo "DIR static 0"
hit() {
  r=0
  e=0
  if [ -n "$2" ]; then
    grep -rlF -- "$2" "$R" >/dev/null 2>&1 && r=1
  fi
  if [ -n "$3" ]; then
    grep -rlF -- "$3" "$R" >/dev/null 2>&1 && e=1
  fi
  echo "HIT $1 $r $e"
}
hit CTRLA "$CA" ""
hit CTRLB "$CB" ""
hit CTRLK "$CK" "$CKE"
hit ICD "$N1" "$N1E"
hit INVENIA "$N2" "$N2E"
hit JUSUNG "$N3" "$N3E"
'
SCAN_OUT=""
scan_names() { # 1 run|exec  2 태그 또는 컨테이너 이름
  if [ "$1" = run ]; then
    SCAN_OUT=$("$DOCKER" run --rm \
      -e CA="$CTRL_A" -e CB="$CTRL_B" -e CK="$CTRL_K" -e CKE="$CTRL_K_ESC" \
      -e N1="$N_ICD" -e N1E="$N_ICD_ESC" -e N2="$N_INV" -e N2E="$N_INV_ESC" \
      -e N3="$N_JUS" -e N3E="$N_JUS_ESC" \
      --entrypoint sh "$2" -c "$NAME_SCAN_SH" 2>&1)
  else
    SCAN_OUT=$("$DOCKER" exec \
      -e CA="$CTRL_A" -e CB="$CTRL_B" -e CK="$CTRL_K" -e CKE="$CTRL_K_ESC" \
      -e N1="$N_ICD" -e N1E="$N_ICD_ESC" -e N2="$N_INV" -e N2E="$N_INV_ESC" \
      -e N3="$N_JUS" -e N3E="$N_JUS_ESC" \
      "$2" sh -c "$NAME_SCAN_SH" 2>&1)
  fi
}
scan_field() { printf '%s\n' "$SCAN_OUT" | sed -n "s/^HIT $1 //p" | head -1; }
see_name() { # 1 키 2 사람이 읽을 이름
  local f r e
  f=$(scan_field "$1"); r=${f%% *}; e=${f##* }
  if [ "${r:-0}" = 1 ] || [ "${e:-0}" = 1 ]; then
    ok "🔴 $2 를 **안다** (날글자 ${r:-0} · 이스케이프 ${e:-0})"
  else
    bad "🔴 $2 를 **모른다** — 이것은 $OLD_AS 다"
    say "      이 판을 띄워도 「고객 안내 현황」은 그대로"
    say "      「양식이 정해진 고객사가 없습니다.」 다."
  fi
}
judge_names() {
  local f ra rb rk ek
  printf '%s\n' "$SCAN_OUT" | grep -E '^(DIR|HIT) ' | sed 's/^/      /'
  f=$(scan_field CTRLA); ra=${f%% *}
  f=$(scan_field CTRLB); rb=${f%% *}
  f=$(scan_field CTRLK); rk=${f%% *}; ek=${f##* }
  if [ "${ra:-0}" != 1 ] && [ "${rb:-0}" != 1 ]; then
    say "    ⚠️ 빌드 산출물을 글자로 뒤지지 못했다 — 대조 표시 둘 다 안 나왔다."
    say "       **판정하지 않는다.** 지어내지 않는다. 사람이 직접 보세요:"
    cmd "$DOCKER exec $AS_CNAME ls /app/.next/server"
    printf '%s\n' "$SCAN_OUT" | head -6 | sed 's/^/      /'
    return 0
  fi
  ok "대조 표시를 찾았다 — 안을 실제로 읽었다 (영문A ${ra:-0} · 영문B ${rb:-0})"
  if [ "${rb:-0}" != 1 ]; then
    say "    ⚠️ 고치는 그 목록 안의 영문 이름(ICD Co.,Ltd.)이 안 나왔다."
    say "       화면 코드가 다른 자리로 옮겨 갔을 수 있다 — 아래 판정은"
    say "       **참고로만** 보세요."
  fi
  if [ "${rk:-0}" != 1 ] && [ "${ek:-0}" != 1 ]; then
    say "    ⚠️ 한글 대조 표시(옛 이름 「주성 엔지니어링」)를 **날글자로도**"
    say "       **이스케이프로도** 못 찾았다. 이 판으로는 한글을 셀 수 없다 —"
    say "       🔴 **판정하지 않는다.** 사람이 화면에서 봐야 한다."
    return 0
  fi
  ok "한글 대조 표시를 찾았다 (날글자 ${rk:-0} · 이스케이프 ${ek:-0})"
  see_name ICD     "$N_ICD"
  see_name INVENIA "$N_INV"
  see_name JUSUNG  "$N_JUS"
}
as_img_inside() {
  if ! have_img "$TAG_AS"; then
    notyet "$TAG_AS 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
    return 0
  fi
  say "  구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
  say "  크기: $("$DOCKER" images "$TAG_AS" --format '{{.Size}}' 2>/dev/null)"
  say "        ($OLD_AS 는 약 590MB 였다 — 🔴 **크기로는 못 가른다.**)"
  say "  🔵 이미지를 잠깐 띄웠다 지운다(docker run --rm). 안 멈추고 안 바꾼다."
  scan_names run "$TAG_AS"
  judge_names
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 【검사】 마이그레이션이 **0건인지 값으로** 센다 — 값 **넷**
#
#  🔴 어긋나면 ✗ 다 — 그러면 --go 가 **아무것도 바꾸지 않고 멈춘다.**
#     「DB 를 안 바꾼다」가 이번 배포의 전제이기 때문이다.
#
#  🔴 넷째 값은 **이미지 안**이다. 볼륨은 사람이 올리는 것이고 이미지는 코드와
#     함께 굳는다 — 볼륨만 보면 「깜빡했다」와 「올릴 것이 없다」를 못 가른다.
#  🔵 1-ㄷ 의 이름 세기와 **같은 방식**이다(docker run --rm · 앱을 안 멈춘다).
#  🔴 못 읽었으면 **판정하지 않는다.** 0 을 「0건이니 통과」로 읽지 않는다.
#     MIGMARK 가 그것을 가른다 — 조각이 끝까지 돌았다는 표시다.
# ══════════════════════════════════════════════════════════════════════
MIG_SCAN_SH='
R=${R:-/app/drizzle}
P=${TAGPAT:-tag}
if [ -d "$R" ]; then
  echo "MIGDIR 1"
else
  echo "MIGDIR 0"
fi
n=$(ls -1 "$R"/*.sql 2>/dev/null | wc -l | tr -d " ")
echo "MIGSQL ${n:-0}"
j=0
if [ -f "$R/meta/_journal.json" ]; then
  j=$(grep -c -- "$P" "$R/meta/_journal.json" 2>/dev/null | tr -d " ")
fi
echo "MIGJ ${j:-0}"
echo "MIGMARK 1"
'
IMG_MIG_RAW=""; IMG_MIG_DIR=""; IMG_MIG_SQL=""; IMG_MIG_J=""
img_mig_scan() { # 1 태그 — 이미지 안의 /app/drizzle 을 센다 (안 멈춘다)
  IMG_MIG_RAW=$("$DOCKER" run --rm -e R="$IMG_MIGDIR" -e TAGPAT="$TAG_PAT" \
    --entrypoint sh "$1" -c "$MIG_SCAN_SH" 2>&1)
  IMG_MIG_DIR=$(printf '%s\n' "$IMG_MIG_RAW" | sed -n 's/^MIGDIR //p' | head -1)
  IMG_MIG_SQL=$(printf '%s\n' "$IMG_MIG_RAW" | sed -n 's/^MIGSQL //p' | head -1)
  IMG_MIG_J=$(printf '%s\n'   "$IMG_MIG_RAW" | sed -n 's/^MIGJ //p'   | head -1)
}
# 되돌리는 값: 0 맞다 · 1 어긋났다 · 2 **판정하지 않았다**
judge_img_mig() {
  printf '%s\n' "$IMG_MIG_RAW" | grep -E '^MIG' | sed 's/^/      /'
  if ! printf '%s\n' "$IMG_MIG_RAW" | grep -qx "MIGMARK 1"; then
    say "    ⚠️ 이미지 안을 **못 읽었다** — 조각이 끝까지 돌지 않았다."
    say "       🔴 **판정하지 않는다.** 0 을 「0건이니 통과」로 읽지 않는다."
    printf '%s\n' "$IMG_MIG_RAW" | head -5 | sed 's/^/      /'
    return 2
  fi
  if [ "${IMG_MIG_DIR:-0}" != 1 ] || [ "${IMG_MIG_SQL:-0}" = 0 ]; then
    say "    ⚠️ 이미지 안 $IMG_MIGDIR 에서 .sql 을 **세지 못했다**"
    say "       (폴더 ${IMG_MIG_DIR:-?} · .sql ${IMG_MIG_SQL:-?}개)."
    say "       🔴 **판정하지 않는다.** 2026-10-17 에는 116개가 들어 있었다 —"
    say "          달라졌으면 Claude 에게 알리세요."
    return 2
  fi
  if [ "$IMG_MIG_SQL" = "$AS_MIG" ]; then
    ok "🔴 이미지 안 $IMG_MIGDIR 의 .sql 이 ${AS_MIG}개다 — 코드와 같다"
  else
    bad "🔴 이미지 안 .sql 이 ${IMG_MIG_SQL}개다 ($AS_MIG 이 아니다)"
    say "    → 🔴 이 이미지는 운영 DB 와 **다른 마이그레이션**을 들고 있다."
    say "       「0건」이 아니다. 고치지 말고 **먼저 알리세요.**"
    return 1
  fi
  if [ "${IMG_MIG_J:-0}" = "$AS_MIG" ]; then
    ok "이미지 안 _journal.json 의 tag 도 ${AS_MIG}줄이다"
  elif [ "${IMG_MIG_J:-0}" = 0 ]; then
    say "    ⚠️ 이미지 안 _journal.json 을 못 읽었다 — 그 한 줄은 판정하지 않는다."
  else
    bad "🔴 이미지 안 _journal.json 의 tag 가 ${IMG_MIG_J}줄이다 ($AS_MIG 이 아니다)"
    return 1
  fi
  return 0
}
mig_zero_check() {
  local n n_sql n_j
  if pg_up; then
    n=$(as_mig_count)
    say "  · 운영 DB $AS_DB 에 적용된 줄: ${n:-?}"
    if [ "${n:-x}" = "$AS_MIG" ]; then
      ok "🔵 운영이 ${AS_MIG}줄이다 — 코드와 같다. **적용할 것이 0건이다**"
    else
      bad "🔴 운영이 ${n:-?}줄이다 ($AS_MIG 이 아니다)"
      say "    → 🔴 **이것이 신호다.** 「DB 를 안 바꾼다」는 전제가 깨졌다."
      say "       고치지 말고 **먼저 알리세요.**"
    fi
  else
    bad "dss-pg-app 이 떠 있지 않다 — 마이그레이션을 셀 수 없다"
  fi
  if [ ! -d "$MIGDIR" ]; then
    bad "$MIGDIR 폴더가 없다 — compose 가 tools-as 에 붙이는 그 폴더다"
  else
    n_sql=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
    n_j=0
    [ -f "$MIGDIR/meta/_journal.json" ] \
      && n_j=$(grep -c '"tag"' "$MIGDIR/meta/_journal.json" 2>/dev/null | tr -d ' ')
    say "  · NAS 볼륨($MIGDIR): .sql ${n_sql}개 · _journal.json 의 tag ${n_j}줄"
    if [ "$n_sql" = "$AS_MIG" ] && [ "$n_j" = "$AS_MIG" ]; then
      ok "🔵 볼륨도 ${AS_MIG} 이다 — 올릴 .sql 이 **없다**(이번 판은 안 올린다)"
    else
      bad "🔴 볼륨이 $AS_MIG 이 아니다 (.sql ${n_sql} · tag ${n_j})"
      say "    → 남의 손이 닿았거나 반쯤 올라간 것이다. 고치지 말고 알리세요."
    fi
  fi
  # ── ④ 🔴 **이미지가 증언하게 한다** ─────────────────────────────────
  # 볼륨은 사람이 올리는 것이고, 이미지는 코드와 함께 굳는다.
  say "  🔴 넷째 값 — $TAG_AS **이미지 안**의 $IMG_MIGDIR (앱을 안 멈춘다):"
  if have_img "$TAG_AS"; then
    img_mig_scan "$TAG_AS"
    judge_img_mig
  else
    notyet "$TAG_AS 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 【검사】 운영 DB 에 **그 세 이름이 있는가** (읽기 전용 select)
# ══════════════════════════════════════════════════════════════════════
show_name() { # 1 이름 2 앞에 붙일 말
  say "      $2 $1 → $(name_rows "$1")줄"
}
judge_name() { # 1 이름
  local n d
  n=$(name_rows "$1")
  case "${n:-x}" in
    1) ok "🔴 운영에 「$1」 가 **1줄** 있다" ;;
    0) bad "🔴 운영에 「$1」 가 **없다**"
       d=$(name_rows_del "$1")
       say "      (지워진 줄로는 ${d:-?}줄)"
       say "      🔴 이름이 **또 바뀐 것**이다. 2.7 을 올려도 그 표는 안 돌아온다 —"
       say "         코드의 customerNames 를 고쳐 2.8 을 구워야 한다."
       say "         🔴 그래도 올려야 하면 **먼저 Claude 에게 알리세요.**" ;;
    x) bad "「$1」 를 세지 못했다 — DB 를 못 읽었다" ;;
    *) notyet "「$1」 가 ${n}줄이다 (하나인 줄 알았다)"
       say "      양식은 두 줄 다에 붙는다 — 표가 둘로 갈려 보일 수 있다." ;;
  esac
}
name_check() {
  if ! pg_up; then
    bad "dss-pg-app 이 떠 있지 않다 — 이름을 셀 수 없다"
    return 1
  fi
  say "  · 지워지지 않은 고객사: $(cust_count)줄"
  say "  🔴 2.7 이 새로 아는 이름 셋 — **각각 1줄**이어야 한다:"
  judge_name "$N_ICD"
  judge_name "$N_INV"
  judge_name "$N_JUS"
  say "  🔵 코드가 알던 옛 이름들 (참고로만 — 0줄이 **맞다**):"
  show_name "$OLD_ICD1" "ICD 양식  "
  show_name "$CTRL_B"   "ICD 양식  "
  show_name "$OLD_INV1" "INVENIA   "
  show_name "$OLD_INV2" "INVENIA   "
  show_name "$OLD_INV3" "INVENIA   "
  show_name "$OLD_JUS1" "JUSUNG    "
  show_name "$OLD_JUS2" "JUSUNG    "
  show_name "$OLD_JUS3" "JUSUNG    "
  say "  🔵 옛 이름은 **지우지 않았다** — 개발 DB 와 과거 기록에 그대로 있고,"
  say "     한 회사가 여러 이름으로 등록될 수 있다는 전제는 여전히 참이다."
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면
#     **아무것도 바꾸지 않고 멈춘다.**
#  🔴 「아직 안 온 것 · 아직 안 실린 것」은 ⚠️ 로 안내만 한다(17~19번의 규칙).
# ══════════════════════════════════════════════════════════════════════
SWAPPED=0
run_checks() {
  local t n m f db n_bk FREE_KB FREE_H code

  # ── 1-ㄱ. 올린 파일 하나 ────────────────────────────────────────────
  step "1-ㄱ. 올린 파일 **하나** (이미지 tar)"
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  if [ ! -s "$TAR_AS" ]; then
    notyet "$TAG_AS 의 tar 가 아직 NAS 에 없다: $TAR_AS"
    say "    → 개발 PC(PowerShell)에서 올리세요. 🔴 scp 에 **-O** 를 붙입니다."
  else
    n=$(stat -c '%s' "$TAR_AS" 2>/dev/null)
    m=$(md5sum "$TAR_AS" 2>/dev/null | awk '{print $1}')
    say "    · 지금 이 tar: 바이트 ${n:-?} · md5 ${m:-?}"
    if [ -z "$SZ_AS" ] || [ -z "$MD5_AS" ] || [ -z "$WANT_CFG_AS" ]; then
      say "    ⚠️ 🔴 **기대값 셋이 아직 비어 있다.** 개발 PC 에서 재어 채우세요."
      say "       채우기 전에는 --go 가 시작하지 않습니다."
      [ -n "$EXP_AS" ] && say "    · 이 tar 안 Config 지문: $EXP_AS"
    else
      [ "$n" = "$SZ_AS" ] && ok "$TAG_AS · 바이트 $n" \
        || bad "$TAG_AS 의 바이트가 $SZ_AS 가 아니다 ($n) — 옮기다 끊겼다"
      [ "$m" = "$MD5_AS" ] && ok "$TAG_AS · md5 $m" \
        || bad "$TAG_AS 의 md5 가 $MD5_AS 가 아니다 (${m:-못 읽음}) — 파일이 상했다"
      if [ -z "$EXP_AS" ]; then
        bad "$TAG_AS 의 tar 에서 manifest.json 을 읽지 못했다"
      elif [ "$EXP_AS" = "$WANT_CFG_AS" ]; then
        ok "$TAG_AS · tar 안 Config 지문이 기대값과 같다 ($(echo "$EXP_AS" | cut -c1-19)…)"
      else
        bad "$TAG_AS · tar 안 Config 지문이 기대값과 다르다"
        say "      tar   $EXP_AS"
        say "      기대  $WANT_CFG_AS"
        say "      🔴 **다른 판을 올린 것**이거나 옮기다 깨진 것이다."
      fi
    fi
  fi
  say "  🔴 tar 가 이미지의 1/4 쯤인 것은 **정상**이다. 지난 판과 견주세요:"
  for f in "$IMAGES/dss-as-2.6.tar" "$IMAGES/dss-as-2.5.tar"; do
    [ -s "$f" ] && say "      $(basename "$f") $(stat -c '%s' "$f") 바이트"
  done

  # ── 1-ㄴ. NAS 에 실린 이미지 ────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (올라가는 하나 · 되돌릴 하나 · 그대로 둘 열셋)"
  if have_img "$TAG_AS"; then
    [ -n "$EXP_AS" ] && { verify_img "$TAG_AS" "$EXP_AS" || force_load_hint; }
    [ -n "$EXP_AS" ] || say "  · $TAG_AS 는 실려 있다 (tar 가 없어 지문은 못 맞췄다)"
  else
    notyet "$TAG_AS 는 아직 NAS 에 안 실렸다 — --preload 나 --go 가 싣는다"
  fi
  say "  🔴 **되돌릴 길** — 옛 태그가 NAS 에 그대로 있어야 한다:"
  have_img "$OLD_AS" && ok "$OLD_AS 가 아직 있다 (되돌릴 길이 열려 있다)" \
    || bad "🔴 $OLD_AS 가 NAS 에 **없다** — 되돌리려면 tar 를 다시 올려야 한다"
  say "  🔴 건드리지 않는 열셋 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for t in $KEEP_TAGS; do
    have_img "$t" && ok "$t 실려 있다 ($(img_id "$t" | cut -c1-19)…)" \
      || bad "$t 가 NAS 에 없다 — 🔴 앞 배포가 되돌아갔거나 누가 지웠다"
  done

  # ── 1-ㄷ. 이미지 안 ─────────────────────────────────────────────────
  step "1-ㄷ. 【검사 1】 🔴 $TAG_AS 안 — **세 이름을 아는가**"
  as_img_inside

  # ── 1-ㄹ. 마이그레이션 0건 ──────────────────────────────────────────
  step "1-ㄹ. 【검사 2】 🔴 마이그레이션이 **0건**인지 값으로 센다 ($AS_MIG)"
  mig_zero_check

  # ── 1-ㅁ. 운영 DB 의 이름 셋 ────────────────────────────────────────
  step "1-ㅁ. 【검사 3】 🔴 운영 DB 에 **그 세 이름이 있는가** (select 만 한다)"
  name_check

  # ── 1-ㅂ. as.env — 이름만 센다 ──────────────────────────────────────
  step "1-ㅂ. 【검사 4】 as.env 가 **그대로인가** (🔴 값은 한 글자도 안 찍는다)"
  say "  🔵 이번 판은 설정을 **안 바꾼다.** 그런데 컨테이너를 다시 띄우는"
  say "     자리라, 누가 덮어써서 줄이 사라졌으면 지금 드러난다."
  if [ ! -r "$AS_ENV" ]; then
    bad "$AS_ENV 를 읽을 수 없다"
  else
    say "  · $AS_ENV ($(wc -l < "$AS_ENV")줄)"
    for t in $AS_LINK_KEYS $AS_PORTAL_KEYS $AS_OTHER_KEYS; do
      if env_has "$AS_ENV" "$t"; then
        n=$(env_dups "$AS_ENV" "$t")
        if [ "${n:-0}" = 1 ]; then
          ok "$t 줄이 하나 있다"
        else
          bad "🔴 $t 줄이 ${n:-?}개다 — docker compose 는 **나중 것**을 읽는다"
        fi
      else
        bad "🔴 $t 줄이 **사라졌다** — 누가 as.env 를 덮어썼다"
        say "      배포보다 이것이 먼저다. 고치지 말고 알리세요."
      fi
    done
    for t in $AS_FORBIDDEN; do
      env_has "$AS_ENV" "$t" \
        && bad "🔴 as.env 에 $t 가 있다 — compose 가 넘기는 값이라 겹친다" \
        || ok "as.env 에 $t 가 없다 (맞다)"
    done
  fi

  # ── 1-ㅅ. compose ───────────────────────────────────────────────────
  step "1-ㅅ. 【검사 5】 compose ($CF)"
  if compose_cmd config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_cmd config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  SVCS=$(compose_cmd config --services 2>/dev/null)
  for t in $SVC_ALL; do
    echo "$SVCS" | grep -qx "$t" && ok "서비스 목록에 $t 가 있다" \
      || bad "🔴 서비스 목록에 $t 가 **없다** — 주석이 덮였거나 파일이 옛것이다"
  done
  if compose_swapped; then
    SWAPPED=1
    ok "🔵 compose 가 **이미 $TAG_AS** 를 가리킨다 (--go 를 돌린 뒤다)"
  else
    SWAPPED=0
    say "  🔵 compose 는 아직 **$OLD_AS** 다 — 바꾸는 것은 --go 가 한다."
  fi
  say "  지금 compose 가 가리키는 태그:"
  say "      A/S      : $(svc_image "$CF" "$AS_SVC")"
  say "      A/S 도구 : $(svc_image "$CF" tools-as)"
  case "$(svc_image "$CF" "$AS_SVC")" in
    "$TAG_AS") ok "$AS_SVC → $TAG_AS (바뀐 뒤다)" ;;
    "$OLD_AS") say "      · $AS_SVC 는 아직 $OLD_AS 다 (바꾸기 전이면 맞다)" ;;
    *) bad "🔴 $AS_SVC 가 $TAG_AS 도 $OLD_AS 도 아니다 — 남의 것이 섞였다"
       say "      고치지 말고 알리세요." ;;
  esac
  say "  🔴 건드리지 않는 열셋의 태그 (흔들렸으면 남의 것이 섞인 것이다):"
  for t in $KEEP_TAGS; do
    [ "$(img_line_count "$CF" "$t")" -ge 1 ] 2>/dev/null \
      && ok "compose 에 $t 가 그대로다" \
      || bad "🔴 compose 에 $t 가 없다"
  done
  svc_block "$CF" "$AS_SVC" | grep -q "127.0.0.1:$AS_PORT:" \
    && ok "$AS_SVC 가 127.0.0.1:$AS_PORT 으로만 열린다" \
    || bad "$AS_SVC 의 포트가 127.0.0.1:$AS_PORT 이 아니다"

  # ── 1-ㅇ. 디스크 · 백업 · 도는 것 ───────────────────────────────────
  step "1-ㅇ. 【검사 6】 디스크 · 오늘($TODAY) 백업 · 도는 것 아홉"
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  if [ "${FREE_KB:-0}" -ge 2000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (tar 하나 + 실은 이미지)"
  fi
  say "  🔵 백업은 **막지 않는다** — 이번 판은 DB 를 한 줄도 안 바꾸고,"
  say "     되돌리기도 이미지만 내리면 끝이라 덤프를 쓸 일이 없다. 그래도 적어 둔다:"
  n_bk=0
  for db in dss_auth dss_meters dss_as dss_improvements dss_leave dss_board dss_inventory; do
    f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      say "      ✓ $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
      n_bk=$((n_bk + 1))
    else
      say "      · $db — 오늘 뜬 덤프가 없다"
    fi
  done
  if [ "$n_bk" = 7 ]; then
    ok "오늘 백업이 일곱이다"
  else
    notyet "오늘 백업이 ${n_bk}개다 (야간 백업은 **02:30** 이다)"
    say "      🔵 이번 판은 이것 때문에 멈추지 않는다. 손으로 뜨고 싶으면:"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  fi
  pg_up && running dss-pg-auth && ok "DB 둘 다 떠 있다 (이 배포는 DB 컨테이너를 안 멈춘다)" \
    || bad "DB 컨테이너가 떠 있지 않다"
  for t in $AS_CNAME $KEEP_BOXES; do
    running "$t" && ok "$t 가 돌고 있다" || bad "🔴 $t 가 안 돌고 있다"
  done
  say "  지금 도는 이미지:"
  "$DOCKER" ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | sed 's/^/      /'
  say "  🔴 메모리 — 바꾸기 **전** 값이다. --go 뒤와 견주세요:"
  free -m 2>/dev/null | sed 's/^/      /'

  # ── 1-ㅈ. 바깥 주소 여덟 ────────────────────────────────────────────
  step "1-ㅈ. 바깥 주소 여덟 (지금 상태를 적어 둔다)"
  for t in as $KEEP_HOSTS; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$t.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$t.dss21.co.kr → $code" ;;
      *)       bad "🔴 https://$t.dss21.co.kr → ${code:-없음}" ;;
    esac
  done
  say "  🔵 고치는 화면은 $AS_BASE$PORTAL_PATH 다. 로그인이 필요해 스크립트가"
  say "     열어 볼 수는 없다 — **눈으로 보는 것은 사람이 한다**(--go 끝의 안내)."
}

# ══ 되돌리기 ═══════════════════════════════════════════════════════════
if [ "$MODE" = rollback ]; then
  echo "DSS 스물셋째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say
  say "  ── 🔵 되돌릴 것이 **하나뿐이다** ─────────────────────────────"
  say "   ① compose      backups/docker-compose.nas.yml.<도장>"
  say
  say "  🔵 **DB 는 되돌릴 것이 없다.** 이번 판은 운영 DB 를 한 줄도 바꾸지"
  say "     않았다(마이그레이션 0건 · select 만 했다). 설정도 볼륨도 공유폴더도"
  say "     안 바꿨다. 그래서 **이미지만 되돌리면 배포 전과 똑같아진다.**"
  say "     덤프를 되감을 일이 없다."

  step "1. 지금 상태"
  running "$AS_CNAME" \
    && say "  $AS_CNAME : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$AS_CNAME " || echo '?')" \
    || say "  $AS_CNAME 은 돌고 있지 않다"
  pg_up && say "  A/S 마이그레이션: $(as_mig_count)줄 (바뀌지 않았어야 한다)"
  say "  compose 가 가리키는 것: $(svc_image "$CF" "$AS_SVC")"

  step "2. 옛 이미지가 아직 있는지 먼저 본다"
  have_img "$OLD_AS" && ok "$OLD_AS 가 있다" \
    || { bad "🔴 $OLD_AS 가 **없다** — 되돌리려면 tar 를 다시 올려야 한다"
         say "      (PowerShell) scp -O dss-as-2.6.tar dss-nas:/volume1/dss/images/"
         say "      (NAS) /usr/local/bin/docker load -i /volume1/dss/images/dss-as-2.6.tar"; }

  step "3. compose 를 사본으로 되돌린다 — 🔴 **통째로** 되돌린다"
  say "  🔴 태그 한 줄만 손으로 고치지 마라. 들여쓰기 한 칸에 여덟 사이트가"
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

  step "4. 옛 판을 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "\$D1 \$C up -d --no-deps $AS_SVC"
  say "  🔵 여기까지가 끝이다. DB 도 설정도 손대지 않았으므로 더 되돌릴 것이 없다."
  say "  🔵 되돌리면 「고객 안내 현황」은 다시 「양식이 정해진 고객사가"
  say "     없습니다.」 가 된다 — 그것이 2.6 의 상태다."

  step "5. 이미지는 지우지 않는다"
  say "  $TAG_AS 를 남겨 둔다 — 다시 올릴 때 쓴다."
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit 0
fi

# ══ 여기부터 check · preload · force-load · go ═════════════════════════
echo "DSS 스물셋째 배포 · $(date '+%F %T')"
echo "  이 파일 md5: $(md5sum "$0" 2>/dev/null | awk '{print $1}')"
echo "    🔵 개발 PC 의 Get-FileHash 값과 다르면 올리다 잘린 것입니다."
echo "  🔴 올라가는 것 **하나**:"
echo "     $OLD_AS → **$TAG_AS**   (커밋 646796f · vendor/dss-core 2ecdf01 그대로)"
echo "  🔵 마이그레이션 **0건** — 코드 $AS_MIG = 개발 $AS_MIG = 운영 $AS_MIG."
echo "     🔴 이 스크립트는 운영 DB 를 **한 줄도 바꾸지 않습니다**(select 만)."
echo "  🔵 설정 변경 없음 · 볼륨 변경 없음 · 공유폴더 변경 없음."
echo "  🔴 멈추는 것은 **dss-as 하나뿐**."
echo "     그대로 도는 일곱: 재고 관리 · 포털 · 계측기 · 개선요청 · PO ·"
echo "                      휴가 · 게시판 (+ DB 둘)"
echo "  🔴 고치는 것: 고객 안내 현황의 **고객사 이름 셋**"
echo "     $N_ICD · $N_INV · $N_JUS"
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**" ;;
  preload)    echo "  🔵 --preload — 이미지 하나를 싣고 지문만 맞춘다. **안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — compose 한 줄을 고치고 dss-as 를 바꿔 끼운다. ⏱ 정지 창."
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 미리 실어 두려는 시점에는 뒤 항목이 아직 안 맞는 것이
#    정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "이미지 tar · 지문"
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  if [ ! -s "$TAR_AS" ]; then
    bad "$TAG_AS 의 tar 가 없다: $TAR_AS"
  else
    N=$(stat -c '%s' "$TAR_AS" 2>/dev/null)
    M=$(md5sum "$TAR_AS" 2>/dev/null | awk '{print $1}')
    GO_LOAD=1
    if [ -z "$SZ_AS" ] || [ -z "$MD5_AS" ]; then
      say "  ⚠️ $TAG_AS · 바이트 $N · md5 $M — 🔴 **기대값이 없어 대조하지 않았다.**"
      say "     이미지를 구운 PC 에서 잰 값과 눈으로 맞춰 주세요."
    else
      if [ "$N" != "$SZ_AS" ]; then
        bad "$TAG_AS 의 바이트가 $SZ_AS 가 아니다 ($N) — 올리다 끊겼다. 싣지 않는다"
        GO_LOAD=0
      elif [ "$M" != "$MD5_AS" ]; then
        bad "$TAG_AS 의 md5 가 $MD5_AS 가 아니다 (${M:-못 읽음}) — 상했다. 싣지 않는다"
        GO_LOAD=0
      else
        ok "$TAG_AS · 바이트 $N · md5 맞음"
      fi
    fi
    if [ -z "$EXP_AS" ]; then
      bad "$TAG_AS 의 tar 에서 manifest.json 을 읽지 못했다"
      GO_LOAD=0
    elif [ -n "$WANT_CFG_AS" ] && [ "$EXP_AS" != "$WANT_CFG_AS" ]; then
      bad "$TAG_AS · tar 안 Config 지문이 기대값과 다르다 — **다른 판이다.** 싣지 않는다"
      say "      tar   $EXP_AS"
      say "      기대  $WANT_CFG_AS"
      GO_LOAD=0
    fi
    [ "$GO_LOAD" = 1 ] && bring_img "$TAG_AS" "$TAR_AS" "$EXP_AS"
  fi

  # 🔴 실어 놓고 **안을 본다.** 태그와 지문이 맞아도 「무엇이 든 판인지」는
  #    사람이 읽을 수 있는 증거로 한 번 더 남긴다.
  step "$TAG_AS 안 — 🔴 **세 이름을 아는가**"
  as_img_inside

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 멈추지 않았다**"
  if [ "$FAIL" != 0 ] && [ "$FORCE_LOAD" != 1 ]; then
    echo "  🔴 지문이 어긋났으면 **같은 태그로 다시 구운 것**이다:"
    echo "       bash $0 --preload --force-load"
  fi
  echo "  🔵 나머지 항목은 안 봤다. 이어서: bash $0        (읽기만)"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 1. 먼저 볼 것 (check · go 가 같이 지난다) ══════════════════════════
#
# 🔴 규칙 하나: **바꾸기 전에 볼 것을 다 보고, 어긋나면 아무것도 하지 않은
#    채로 멈춘다.** 여기서 끝나면 아무 일도 일어나지 않는다.
step "1. 준비가 됐는지 기계로 본다 (아직 아무것도 안 바꿨다)"
run_checks

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo
  echo "  🔴 --check 가 보여 준 것 — 사람이 보고 판단할 자리 셋:"
  echo "     ① $TAG_AS 가 세 이름을 아는가 (1-ㄷ)"
  echo "     ② 운영 DB 에 그 세 이름이 1줄씩 있는가 (1-ㅁ)"
  echo "     ③ 마이그레이션이 정말 0건인가 — 운영 $AS_MIG · 폴더 $AS_MIG (1-ㄹ)"
  if [ "$FAIL" = 0 ]; then
    if ! pinned; then
      echo "  ⚠️ 이미지 기대값 셋이 아직 비어 있습니다 — 재어 채운 뒤에 갑니다."
    elif ! have_img "$TAG_AS"; then
      echo "  ✅ 이어서 (아무것도 안 멈춥니다):  bash $0 --preload"
    else
      echo "  ✅ 이어서 (⏱ 정지 창 · dss-as 하나):  bash $0 --go"
    fi
  else
    echo "  ✗ 위 ✗ 를 먼저 해결하세요. Claude 에게 알려 주세요."
  fi
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터는 --go 뿐이다 ═════════════════════════════════════════════
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 바꾸지 않았고 A/S 는 살아 있습니다.**"
pinned || {
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 이미지 기대값 셋이 **비어 있습니다.** 재지 않은 이미지를      ║"
  say "  ║    운영에 올리지 않습니다.                                     ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     이 파일 머리말 「돌리기 전에」의 차례대로 개발 PC 에서 재어"
  say "     셋을 채우고, 이 파일을 다시 올린 뒤(md5 대조) 돌리세요."
  stop "아무것도 바꾸지 않았습니다. 앱도 DB 도 그대로입니다."
}

# ── 2. 🔴 바꾸기 **직전에** 다시 센다 ─────────────────────────────────
#
# 🔴 --check 에서 봤다는 것으로는 부족하다 — 그 뒤에 달라졌을 수 있고,
#    무엇보다 --check 를 안 돌리고 바로 여기로 올 수 있다.
step "2. 🔴 마이그레이션 0건과 이름 셋을 **지금 다시** 센다 (바꾸기 전이다)"
MIG_BEFORE=$(as_mig_count)
TBL_BEFORE=$(as_tbl_count)
CUST_BEFORE=$(cust_count)
say "  · 적용된 마이그레이션 ${MIG_BEFORE:-?}줄 · 표 ${TBL_BEFORE:-?}개 · 고객사 ${CUST_BEFORE:-?}줄"
[ "${MIG_BEFORE:-x}" = "$AS_MIG" ] \
  || stop "운영 DB 가 ${MIG_BEFORE:-?}줄입니다($AS_MIG 이 아닙니다). **아무것도 안 바꿨습니다.**"
ok "운영이 ${AS_MIG}줄이다 — 적용할 것이 0건이다"
# 🔵 막는 것은 **0줄일 때뿐**이다. 둘 이상이면 1-ㅁ 가 ⚠️ 로 알리고 지나간다 —
#    같은 이름이 두 줄이어도 양식은 양쪽에 붙어서, 고치는 일 자체는 된다.
for Q in "$N_ICD" "$N_INV" "$N_JUS"; do
  NQ=$(name_rows "$Q")
  [ "${NQ:-0}" -ge 1 ] 2>/dev/null \
    || stop "운영에 「$Q」 가 없습니다(${NQ:-?}줄). 이름이 또 바뀐 것입니다. **아무것도 안 바꿨습니다.**"
done
ok "운영에 세 이름이 다 있다 — 고칠 자리가 맞다"
# ── 🔴 넷째 값 — **이미지가 증언하게 한다** ───────────────────────────
# 볼륨은 사람이 올리는 것이고 이미지는 코드와 함께 굳는다. 볼륨만 보면
# 「올리는 것을 깜빡했다」와 「원래 올릴 것이 없다」를 가르지 못한다.
IMG_MIG_DONE=0
if have_img "$TAG_AS"; then
  say "  · $TAG_AS 이미지 안 $IMG_MIGDIR (앱을 안 멈춘다):"
  img_mig_scan "$TAG_AS"
  judge_img_mig
  RC=$?
  [ "$RC" = 1 ] && stop "이미지가 운영 DB 와 다른 마이그레이션을 들고 있습니다. **아무것도 안 바꿨습니다.**"
  IMG_MIG_DONE=1
else
  say "  · $TAG_AS 가 아직 안 실렸다 — **3단계에서 실은 뒤에** 센다"
fi

# ── 3. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ───────────
step "3. 이미지 확인 · 필요하면 싣기 (tar 의 Config ↔ NAS 의 .Id)"
EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
if [ -z "$EXP_AS" ]; then
  bad "$TAR_AS 에서 manifest.json 을 읽지 못했다"
  stop "이미지를 확인하지 못했습니다. **아무것도 안 띄웠습니다.**"
fi
[ "$EXP_AS" = "$WANT_CFG_AS" ] \
  || stop "tar 안 Config 지문이 기대값과 다릅니다(다른 판입니다). **아무것도 안 띄웠습니다.**"
bring_img "$TAG_AS" "$TAR_AS" "$EXP_AS" || {
  say
  say "  🔴 이미지가 기대한 것과 다릅니다. **아직 아무것도 안 멈췄습니다.**"
  stop "바꿔 끼우기를 시작하지 않았습니다."
}
# 🔴 2단계에서 아직 안 실려 못 센 경우, **지금 센다**(여전히 바꾸기 전이다)
if [ "$IMG_MIG_DONE" = 0 ]; then
  say "  · 방금 실은 이미지 안 $IMG_MIGDIR 을 센다:"
  img_mig_scan "$TAG_AS"
  judge_img_mig
  RC=$?
  [ "$RC" = 1 ] && stop "이미지가 운영 DB 와 다른 마이그레이션을 들고 있습니다. **아무것도 안 바꿨습니다.**"
fi

# ── 4. 건드리지 않는 쪽의 시작 시각을 적어 둔다 ────────────────────────
#
# 🔴 「안 멈췄다」를 말로 하지 않는다. 바꾼 뒤에 이 값과 그대로인지 본다.
step "4. 건드리지 않는 일곱 + DB 둘의 시작 시각을 적어 둔다 (뒤에서 대조한다)"
STARTED_BEFORE=""
for T in $KEEP_BOXES dss-pg-app dss-pg-auth; do
  S=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$T" 2>/dev/null)
  STARTED_BEFORE="$STARTED_BEFORE$T=$S
"
  say "  · $T  시작 ${S:-?}"
done

# ── 5. compose 의 image 줄 하나를 바꾼다 (아직 아무것도 안 멈췄다) ─────
step "5. compose 의 image 줄 **하나**를 바꾼다 ($OLD_AS → $TAG_AS)"
if compose_swapped; then
  ok "🔵 compose 가 **이미 $TAG_AS** 다 — 다시 고치지 않는다"
else
  swap_tag || stop "compose 를 바꾸지 못했습니다. **사본으로 되돌렸고 아무것도 안 멈췄습니다.**"
fi

# ══ 6. ⏱ 정지 창 — dss-as 하나 ════════════════════════════════════════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — compose 에 있는 것을 전부 띄우려 들고
#    DB 컨테이너까지 다시 만든다. --no-deps 로 **이름을 적은 하나만**.
# 🔴 따로 stop 하지 않는다. up -d 가 옛 컨테이너를 지우고 새것을 올리는 한
#    걸음이라, 나눠 부르면 그 사이만큼 정지 창이 길어진다.
step "6. ⏱ 정지 창 시작 — dss-as 하나를 바꿔 끼운다"
say "  🔴 멈추는 것은 **dss-as 하나**다. 재고 관리 · 포털 · 계측기 · 개선요청 ·"
say "     PO · 휴가 · 게시판 · DB 둘은 그대로 돈다."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"
compose_cmd up -d --no-deps "$AS_SVC" 2>&1 | sed 's/^/    /'
wait_http "A/S" "$AS_PORT" / "$AS_CNAME" \
  || stop "A/S 가 안 떴습니다. 되돌리기: bash $0 --rollback"
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say "  ⏱ $STOP_AT → $UP_AT · A/S 정지 약 ${DOWN}초"

# ══ 7. 스모크 — 🔴 「돈다」로 끝내지 않는다 ════════════════════════════
#
# 🔴 2.6 도 돌고 있었다. 돌면서 표를 못 세운 것이 이번 장애다.
#    그래서 **고쳐졌다는 것을 값으로** 본다.
step "7. 스모크 — 🔴 「돈다」가 아니라 「고쳐졌는가」"

say "  7-ㄱ. 컨테이너가 살아 있는가 · 🔴 **도는 것이 정말 $TAG_AS 인가**"
if running "$AS_CNAME"; then
  ok "$AS_CNAME 가 돌고 있다"
  say "      $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$AS_CNAME " || true)"
else
  bad "$AS_CNAME 이 안 돌고 있다 — 떴다가 죽었다"
  say "    로그:"
  cmd "$DOCKER logs --tail 50 $AS_CNAME"
fi
RUN_ID=$("$DOCKER" inspect -f '{{.Image}}' "$AS_CNAME" 2>/dev/null)
WANT_ID=$(img_id "$TAG_AS")
if [ -n "$RUN_ID" ] && [ "$RUN_ID" = "$WANT_ID" ]; then
  ok "🔴 도는 컨테이너의 이미지 지문이 $TAG_AS 와 **같다** ($(echo "$RUN_ID" | cut -c1-19)…)"
else
  bad "🔴 도는 컨테이너의 이미지 지문이 $TAG_AS 가 아니다"
  say "      도는 것 ${RUN_ID:-없음}"
  say "      $TAG_AS  ${WANT_ID:-없음}"
fi

say "  7-ㄴ. 🔴 운영 DB 에 **그 세 이름이 있는가** (select 만 한다)"
name_check

say "  7-ㄷ. 🔴 **도는 컨테이너 안**의 빌드 산출물이 세 이름을 아는가"
say "      (🔴 셋 다 나와야 한다. 하나라도 0이면 옛 이미지가 도는 것이다.)"
if running "$AS_CNAME"; then
  scan_names exec "$AS_CNAME"
  judge_names
else
  bad "컨테이너가 안 돌아 안을 못 봤다"
fi

say "  7-ㄹ. 🔴 **건드리지 않은 일곱이 정말 안 멈췄는가** (시작 시각으로 본다)"
for T in $KEEP_BOXES dss-pg-app dss-pg-auth; do
  S=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$T" 2>/dev/null)
  B=$(printf '%s\n' "$STARTED_BEFORE" | sed -n "s/^$T=//p")
  [ -n "$S" ] && [ "$S" = "$B" ] && ok "$T 시작 시각 그대로 ($S)" \
    || bad "🔴 $T 의 시작 시각이 달라졌다 (전 ${B:-?} / 후 ${S:-?}) — 함께 멈췄다"
done

say "  7-ㅁ. 🔵 **DB 가 정말 그대로인가** — 바꾸기 전 값과 견준다"
MIG_AFTER=$(as_mig_count)
TBL_AFTER=$(as_tbl_count)
CUST_AFTER=$(cust_count)
[ "${MIG_AFTER:-x}" = "${MIG_BEFORE:-y}" ] \
  && ok "마이그레이션 ${MIG_AFTER}줄 — 그대로다 (한 건도 안 돌았다)" \
  || bad "🔴 마이그레이션이 ${MIG_BEFORE:-?} → ${MIG_AFTER:-?} 로 달라졌다"
[ "${TBL_AFTER:-x}" = "${TBL_BEFORE:-y}" ] \
  && ok "표 ${TBL_AFTER}개 — 그대로다" \
  || bad "🔴 표가 ${TBL_BEFORE:-?} → ${TBL_AFTER:-?} 로 달라졌다"
[ "${CUST_AFTER:-x}" = "${CUST_BEFORE:-y}" ] \
  && ok "고객사 ${CUST_AFTER}줄 — 그대로다" \
  || notyet "고객사가 ${CUST_BEFORE:-?} → ${CUST_AFTER:-?} 로 달라졌다 (쓰는 분이 고쳤을 수 있다)"

say "  7-ㅂ. 바깥 주소 여덟"
for T in as $KEEP_HOSTS; do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$T.dss21.co.kr/" 2>/dev/null)
  case "$CODE" in
    2??|3??) ok "https://$T.dss21.co.kr → $CODE" ;;
    *)       bad "🔴 https://$T.dss21.co.kr → ${CODE:-없음}" ;;
  esac
done
say "  열린 포트 (🔴 127.0.0.1 만이어야 한다):"
netstat -tln 2>/dev/null | grep ':13[0-9]\{3\}' | sed 's/^/      /'
say "  지금 도는 이미지:"
"$DOCKER" ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | sed 's/^/      /'
say "  🔴 메모리 — 이 값을 Claude 에게 알려 주세요:"
"$DOCKER" stats --no-stream --format '{{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}' 2>/dev/null \
  | sed 's/^/      /'
free -m 2>/dev/null | sed 's/^/      /'

# ══ 8. 마무리 ══════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  ⏱ $STOP_AT → $UP_AT (약 ${DOWN}초) · 멈춘 것은 dss-as 하나"
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

   1. 🔴 https://as.dss21.co.kr/customer-portal — **고객 안내 현황**
      · 🔴 「양식이 정해진 고객사가 없습니다.」 가 **사라졌습니까**
      · 🔴 표 **셋**이 보입니까 — ICD 양식 · INVENIA 양식 · JUSUNG 양식
      · 그 표 안에 접수 건이 실려 있습니까(빈 표가 아니라)
      🔵 여기가 이번 배포의 전부입니다. 이것만 보면 됩니다.
   2. A/S 의 다른 화면이 그대로입니까 — 수리 건 목록 · 견적서 ·
      부품 요청(재고 관리와 잇는 그 칸). 🔵 2.6 에서 바뀐 것이 없습니다.
   3. 🔴 **재고 관리 · 포털 · 계측기 · 개선요청 · PO · 휴가 · 게시판이
      그대로입니까** — 이 배포는 그 일곱을 건드리지 않았습니다.

🔴 사람이 이어서 할 일:
  · 위 메모리 값을 Claude 에게 알려 주세요.
  · 🔵 쓰는 분이 고객사 이름을 **또 바꾸면 같은 일이 다시 일어납니다.**
    그때는 코드의 customerNames 에 이름을 한 줄 더해 새 판을 구워야 합니다
    (src/lib/domain/customer-portal-forms.ts). 오류가 안 나므로
    **화면에서 표가 사라지는 것**이 유일한 신호입니다.

🔴 되돌리기:  bash $0 --rollback
   · 🔵 되돌릴 것이 **compose 한 줄과 컨테이너 하나**뿐입니다.
     DB 도 설정도 안 바꿨으므로 **이미지만 되돌리면 배포 전과 똑같아집니다.**
ANNOUNCE
exit "$FAIL"
# ══════════════════════════════════════════════════════════════════════
#  사람이 칠 명령 — 🔴 **딱지를 보고 치세요**
#
#  🔴 이 PC 는 PowerShell 5.1 입니다. 그리고 NAS 에서 칠 것은 bash 입니다.
#  🔴 docker build · docker save · tar 는 **사용자가 직접** 칩니다
#     (분류기가 막고, tar 가 C: 를 원격 호스트로 읽습니다 — 그래서 아래는
#      전부 **상대경로**입니다. 먼저 Development 폴더로 들어가세요).
# ══════════════════════════════════════════════════════════════════════
#
# ── 【Windows · PowerShell】 ① 굽는다 ─────────────────────────────────
#
#   cd C:\Users\희만\Desktop\Development\RF_Service_System
#   git status --short
#   git log --oneline -1
#   git submodule status
#     🔴 git status 가 **비어 있어야** 하고, 맨 위가 646796f 여야 합니다.
#     🔴 vendor/dss-core 가 2ecdf01 · vendor/dss-ui 가 8a64d2a 여야 합니다.
#     🔴 「git archive」 로 뽑지 마세요 — 서브모듈이 **빈 폴더**로 나와
#        빌드가 깨집니다. 작업 폴더에서 굽되 git status 가 비어 있어야 합니다.
#   docker build -t dss-as:2.7 .
#     🔵 도구 이미지(dss-as-tools:1)는 **다시 굽지 않습니다** — 이번 판에는
#        적용할 마이그레이션이 0건입니다.
#
# ── 【Windows · PowerShell】 ② tar 로 뜨고 **잰다** ───────────────────
#
#   cd C:\Users\희만\Desktop\Development
#   docker save dss-as:2.7 -o dss-as-2.7.tar
#
#   (Get-Item dss-as-2.7.tar).Length             ← SZ_AS
#   Get-FileHash -Algorithm MD5 dss-as-2.7.tar   ← MD5_AS (소문자로 적습니다)
#   tar -xOf dss-as-2.7.tar manifest.json        ← "Config" → WANT_CFG_AS
#     🔴 「blobs/sha256/abc…」 꼴로 나옵니다. 앞의 「blobs/」 를 떼고
#        「sha256:abc…」 모양으로 적습니다(28번이 여기서 세 줄을 틀렸습니다).
#
#   🔴 **tar 는 상대경로로만** 칩니다. C:\… 로 적으면 tar 가 그 앞을
#      원격 호스트 이름으로 읽어 실패합니다.
#   🔴 tar 가 이미지의 1/4 쯤인 것은 **정상**입니다. 지난 판과 견주세요:
#      dss-as-2.6.tar 는 131,566,592 바이트였습니다.
#
# ── 【Windows · PowerShell】 ③ 셋을 채우고 올린다 ────────────────────
#
#   🔵 **이번 판은 이미 채워져 있습니다**(2026-10-17 실측). 아래 ①② 는 다시
#      구워야 할 때의 차례입니다 — 다시 구우면 셋을 **다시 재어** 채웁니다.
#      비어 있으면 --go 가 시작하지 않습니다.
#   🔴 PowerShell 에는 gzip 이 없습니다. 「docker save … | gzip -1」 로 적힌
#      옛 안내를 쓰지 마세요 — 위 ② 처럼 **-o 로 .tar** 를 만듭니다
#      (2026-10-17 에 실제로 걸렸습니다). 압축은 **안 해도 됩니다** —
#      docker save 가 이미 압축된 레이어를 담고, 이 스크립트는 .tar 를 봅니다.
#
#   cd C:\Users\희만\Desktop\Development
#   scp -O dss-as-2.7.tar dss-nas:/volume1/dss/images/
#   scp -O dss-deploy\nas\setup\29-deploy.sh dss-nas:/volume1/dss/setup/
#   Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\29-deploy.sh
#
#   🔴 **scp 에 -O 를 붙입니다** — DSM 에 sftp 서버가 없어 없으면 실패합니다.
#   🔴 **compose 는 올리지 않습니다.** 저장소 사본은 재고 관리 두 블록이
#      아직 주석이라, 올리면 재고 관리가 통째로 사라집니다(머리말 참조).
#   🔵 마이그레이션 묶음도 **안 올립니다** — 0건입니다.
#   🔴 Git Bash 의 ssh/scp 로는 NAS 에 못 붙습니다(한글 사용자 폴더).
#      PowerShell 의 것(C:\WINDOWS\System32\OpenSSH\scp.exe)을 쓰세요.
#   🔵 scp 가 바로 안 되면 swhur 홈으로 올린 뒤 NAS 에서 sudo mv 로 옮깁니다.
#
# ── 【NAS · bash】 ④ md5 를 맞추고 돌린다 ────────────────────────────
#
#   md5sum /volume1/dss/setup/29-deploy.sh
#     🔴 위 Get-FileHash 값과 **같아야** 돌립니다. 다르면 다시 올립니다.
#        (DSM 터미널이 긴 명령을 잘라 먹어 하루에 네 번 깨진 적이 있습니다.)
#        🔵 스크립트도 시작할 때 자기 md5 를 찍습니다.
#
#   sudo -i
#   bash /volume1/dss/setup/29-deploy.sh             ← 읽기만
#   bash /volume1/dss/setup/29-deploy.sh --preload   ← 이미지를 싣는다
#   bash /volume1/dss/setup/29-deploy.sh             ← 다시 읽기만 (지문까지)
#   bash /volume1/dss/setup/29-deploy.sh --go        ← ⏱ 정지 창
#
#   🔵 야간 백업(02:30)을 기다릴 필요가 **없습니다** — 이번 판은 DB 를 한 줄도
#      바꾸지 않습니다. 아무 때나 돌려도 --go 가 백업 때문에 막히지 않습니다.
#
# ── 【NAS · bash】 되돌리기 ──────────────────────────────────────────
#
#   bash /volume1/dss/setup/29-deploy.sh --rollback
#     (아무것도 바꾸지 않고 명령만 찍습니다. 치는 것은 사람입니다.)
#
# ══════════════════════════════════════════════════════════════════════
