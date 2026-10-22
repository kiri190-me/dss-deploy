#!/bin/bash
# /volume1/dss/setup/31-deploy.sh — 2026-10-22 서른한째 배포
#
# ══ 무엇이 올라가는가 — **여덟** (+ 도구 둘) ══════════════════════════
#
#     ① 포털   dss-auth:1.7         →  **dss-auth:1.8**
#     ② 재고   dss-inventory:0.2    →  **dss-inventory:0.3**
#        도구  dss-inventory-tools:2 → **dss-inventory-tools:3**
#     ③ A/S    dss-as:2.8           →  **dss-as:2.9**
#     ④ PO     dss-po:0.6           →  **dss-po:0.7**
#        게시판 dss-board:0.2        →  **dss-board:0.3**
#        휴가   dss-leave:0.2        →  **dss-leave:0.3**
#        계측기 dss-meters:1.3       →  **dss-meters:1.4**
#        개선   dss-improvements:0.3 →  **dss-improvements:0.4**
#     🔴 그리고 **처음 생기는 것 하나** — dss-auth-tools:1 (포털 도구)
#
#   🔴 멈추는 것은 **여덟 다**. 안 멈추는 것은 DB 둘(dss-pg-app · dss-pg-auth)뿐이다.
#   🔵 아홉째 사이트(RF 이슈관리) 신설은 **32번**이다 — 이 파일의 일이 아니다.
#
#   🔵 30번(서른째)을 틀로 삼았다. 모드 넷 · ok/bad/say/step · tar_config_id() ·
#      see_tar() · have_img() · bring_img() · svc_block() · img_line_count() ·
#      destructive_scan() · place_migs() · wait_http() 는 그 파일에서 **글자
#      그대로** 가져왔다. 발명한 곳은 세 군데뿐이고 아래에 적어 둔다.
#      ✓ / ✗ / ? 세 칸으로 세는 방식은 31-survey.sh · 31-build.sh 의 것이다.
#
# ══ 🔴 배포 순서와 그 까닭 — 한쪽으로만 손해가 난다 ═══════════════════
#
#   ① **포털이 먼저다.** 일곱 집이 포털의 새 통로 둘을 부른다:
#        POST /api/integration/notification-acknowledgements
#        POST /api/integration/notification-dismissals
#      포털이 옛 판(1.7)이면 그 둘이 **전부 404** 다. 거꾸로 포털만 새것이면
#      **아무 일도 안 난다** — 부르러 오는 집이 아직 없을 뿐이다.
#
#   ② **그 다음이 재고다.** A/S → 재고로 가는 값(fromOhTemplate · workflowKind)은
#      신청이 서는 **그 순간** payload 에 눕고 **나중에 안 돌아온다.** A/S 가 먼저
#      올라가면 그 사이에 선 신청은 영영 O/H 딱지를 못 갖는다. 거꾸로는 잃는 것이
#      없다 — 재고가 새것이어도 옛 A/S 는 그 값을 안 보낼 뿐이다.
#
#   ③ **그 짝의 보내는 쪽이 A/S 다.** 재고 바로 뒤에 붙여 중간 창을 짧게 한다.
#
#   ④ 나머지 다섯(PO · 게시판 · 휴가 · 계측기 · 개선요청)은 서로 의존이 없다.
#      그래도 **하나씩** 올리고 대답을 받은 뒤 다음으로 간다 — 한 번에 부르면
#      어느 것이 안 떴는지 로그에서 가려내기가 어렵다.
#
# ══ 🔴 마이그레이션 — 세 DB 가 바뀐다 ════════════════════════════════
#
#   포털 dss_auth        5 → **8**    (0005 · 0006 · 0007)   🔴 처음이다
#   재고 dss_inventory  20 → **26**   (0020 ~ 0025 여섯)
#   A/S  dss_as        118 → **119**  (0118 하나)
#   🔵 계측기 3 · 개선요청 4 · 휴가 3 · 게시판 1 — **배포 뒤에도 같아야 한다.**
#
#   🔴 **돌리는 쪽이 시스템마다 다르다** (30번의 교훈 ①):
#        포털 → **이번에 처음 생긴 도구 이미지** dss-auth-tools:1
#        재고 → **도구 이미지 안**(dss-inventory-tools:**3**)에 구워져 있다
#        A/S  → **볼륨** /volume1/dss/as-migrations 를 tools-as 가 :ro 로 읽는다
#      🔴 A/S 는 볼륨이 118 인 채로 돌리면 **0건으로 조용히 끝난다**(drizzle 은
#         meta/_journal.json 에 없는 .sql 을 아예 모른다). 30번이 당한 그것이다.
#      🔴 재고는 도구가 :2 인 채로 돌리면 역시 **0건으로 조용히 끝난다** —
#         새 여섯은 :3 안에만 있다.
#
#   🔴 ALTER TYPE … ADD VALUE 가 **넷** 있다 (A/S 0118 · 재고 0020 · 0022 · 0023).
#      PostgreSQL 은 **같은 트랜잭션에서 새 enum 값을 쓰지 못한다.** drizzle 은
#      대기 중인 마이그레이션 전부를 **한 트랜잭션**에 넣는다(drizzle-orm 의
#      migrate()). 네 파일을 2026-10-22 에 글자로 읽어 확인한 결과:
#        · 0020 · 0023 — ADD VALUE 뿐. 쓰는 문장이 없다.
#        · 0022 — ADD VALUE 뒤에 CHECK 를 더하는데 그 식이 status::text 와
#                 **글자 비교**다. enum 값을 쓰지 않는다 → 안전하다.
#        · A/S 0118 — ADD VALUE 한 줄뿐이다.
#      → 설계상 안전하다. 🔴 그래도 **한 장씩 끊어 돌릴 길**을 아래 8절에 적어
#         두었다. 55P04(unsafe use of new value)가 나면 그 길로 간다.
#
#   🔴 **마이그레이션은 되돌아가지 않는다.** 그래서 --migrate 는 시작 전에
#      ① 오늘 백업 일곱을 다시 찾고 ② 바뀌는 DB 셋을 그 자리에서 덤프한다.
#
# ══ 🔴 compose 를 두 번 고친다 — 지시서에서 갈라진 한 곳 ══════════════
#
#   🔴 **--migrate 도 compose 를 고친다.** 지시서는 compose 고치기를 전부 --go 에
#      두었는데, 그러면 --migrate 가 **돌 수가 없다**:
#        · tools-auth 서비스 블록이 compose 에 없으면 compose run tools-auth 가
#          「그런 서비스 없음」으로 끝난다. 포털 마이그레이션을 돌릴 길이 없다.
#        · tools-inventory 가 :2 를 가리키는 동안은 새 여섯이 **존재하지 않는다.**
#      → 그래서 이 파일은 compose 고치기를 **둘로 나눈다**:
#          --migrate : tools-auth 블록을 넣고 tools-inventory 를 :2 → :3
#          --go      : 앱 image 줄 **여덟**
#        🔵 앞의 둘은 profiles: [tools] 라 **평소에 뜨지 않는 서비스**다.
#           도는 컨테이너는 compose 를 읽지 않으므로 그 두 줄을 고쳐도
#           **직원이 느끼는 것이 하나도 없다.** up -d 를 부르지 않는다.
#        🔴 두 번 다 사본을 먼저 뜨고, 줄 수와 image: 목록을 세고, config -q 를
#           통과하지 못하면 **사본으로 되돌리고 멈춘다.**
#
# ══ 🔴 저장소 사본을 올리지 않는다 ════════════════════════════════════
#   이 저장소의 nas/docker-compose.nas.yml 은 **낡았다** — dss-as:2.5 라고 적혀
#   있고 app-inventory · tools-inventory 가 아직 주석이다(27번이 NAS 에서 벗겼다).
#   올리면 **재고 관리가 compose 에서 통째로 사라진다.** 그래서 이 스크립트가
#   NAS 의 파일($CF)을 **제자리에서** 고친다.
#
# ══ 🔴 돌리기 전에 — 값은 어디서 왔는가 ══════════════════════════════
#
#   이 파일이 박아 둔 기대값에는 **출처를 적어 두었다.** 오늘 이 묶음에서
#   **검사 자신이 틀린 경우가 여섯** 있었다. ✗ 가 나면 **검사를 먼저 의심한다.**
#     [설문]   31-survey.sh 가 2026-10-22 에 NAS 에서 실제로 잰 값
#     [배포본] 31-build.sh 가 굽고 바로 잰 값 (tar 바이트 · md5 · Config 지문)
#     [저장소] 개발 PC 의 저장소에서 센 값 (.sql 장수 등)
#     [없음]   잰 적이 없다 — 기대값을 박지 않고 **지금 수를 적어만 둔다**
#
# ══ 🔴 개발 PC → NAS 로 올릴 것 — **열하나** ═════════════════════════
#
#   ㄱ) 이미지 tar **아홉** → /volume1/dss/images/
#        dss-auth-1.8.tar · dss-as-2.9.tar · dss-po-0.7.tar
#        dss-inventory-0.3.tar · dss-inventory-tools-3.tar
#        dss-board-0.3.tar · dss-leave-0.3.tar · dss-meters-1.4.tar
#        dss-improvements-0.4.tar
#      🔵 아홉은 2026-10-22 에 _images-31 폴더에 구워져 있다.
#
#   ㄴ) 🔴 **포털 도구 tar — 열째다.** 🔵 **이것이 가장 먼저 필요하다** —
#      없으면 포털 마이그레이션(0005 · 0006 · 0007)을 **돌릴 길이 아예 없다.**
#        /volume1/dss/images/dss-auth-tools-1.tar   211,960,832 바이트
#      🔵 2026-10-22 17:10 에 개발 PC 의 _images-31 에 **이미 뽑혀 있다**(실측).
#         그 전까지는 없었다 — 지시서가 쓰인 뒤에 생겼다. 아직 안 뽑았다면:
#        (개발 PC · PowerShell)
#          cd C:\Users\희만\Desktop\Development\_images-31
#          docker save dss-auth-tools:1 -o dss-auth-tools-1.tar
#          scp -O dss-auth-tools-1.tar dss-nas:/volume1/dss/images/
#      🔴 docker save 는 분류기가 막는 일이 있다 — **사람이 직접 친다.**
#
#   ㄷ) 🔴 **A/S 마이그레이션 묶음** → /volume1/dss/setup/incoming/
#        (개발 PC · PowerShell)
#          cd C:\Users\희만\Desktop\Development\RF_Service_System
#          tar -czf ..\as-migrations.tar.gz drizzle
#          cd ..
#          scp -O as-migrations.tar.gz dss-nas:/volume1/dss/setup/incoming/
#      🔴 tar 에 드라이브 문자(C:)를 주지 마세요 — **원격 호스트로 읽습니다.**
#      🔴 git archive 로 뽑지 마세요 — 서브모듈이 빈 폴더로 나옵니다.
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#
# ══ DSM 터미널은 긴 명령을 잘라 먹는다 ════════════════════════════════
#   하루에 네 번 깨진 적이 있다. NAS 에서 돌릴 것은 **파일로 올리고 md5 를 맞춘
#   뒤** 실행한다. 이 파일도 그렇다:
#     (PowerShell)  cd C:\Users\희만\Desktop\Development
#     (PowerShell)  scp -O dss-deploy\nas\setup\31-deploy.sh dss-nas:/volume1/dss/setup/
#     (PowerShell)  Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\31-deploy.sh
#     (NAS)         md5sum /volume1/dss/setup/31-deploy.sh
#                   → 두 값이 **같아야** 실행한다. 다르면 다시 올린다.
#   🔵 이 스크립트는 시작할 때 **자기 md5 를 찍는다.**
#   이 스크립트가 찍는 명령은 전부 cmd() 를 지나 **76자 안쪽**이다.
#
# ══ 🔴 야간 백업 시각을 지킨다 — **02:30** ════════════════════════════
#   🔴 자정을 넘겨 돌리면 백업 검사에 걸린다. 17번이 01:00 에 돌렸다가 실제로
#      배포가 막혔다 — 그것이 사고를 막았다. 늦은 시각이면 먼저 손으로 뜬다:
#        bash /volume1/dss/jobs/backup-nightly.sh
#      ✓ 줄이 **일곱** 찍혀야 한다.
#
# ── 사람이 실행한다 ───────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/31-deploy.sh        ← 읽기만 한다
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ──────────────────────────────────
#   11번부터 이어온 약속 그대로 — **인자 없이 돌리면 --check**.
#   🔴 정직하게 적어 둔다 — --check 도 이렇게 한다:
#      · 이미지 **안을 보려고** 컨테이너를 잠깐 띄웠다 지운다(docker run --rm).
#        도구 둘과 A/S 2.9 의 /app/drizzle 을 세는 자리다.
#      · 운영 DB 에 **select** 를 여러 번 보낸다(바꾸는 문장은 하나도 없다).
#      · 포털의 새 통로 둘에 **POST 를 한 번씩** 보낸다. 자격증명이 없으므로
#        맨 첫 문에서 돌아선다 — 본문도 안 읽고 DB 도 안 두드린다.
#      · 바깥 주소 여덟에 GET 을 한 번씩 보낸다.
#      「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#
# ── 모드 여섯 ─────────────────────────────────────────────────────────
#   (없음) · --check   읽기만. 아무것도 안 바꾸고 안 멈춘다        ← 기본값
#   --preload          tar 열을 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load       🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --migrate          🔴 **DB 셋이 바뀐다.** compose 의 도구 둘도 고친다. 안 멈춘다
#   --go               ⏱ **정지 창.** compose 여덟 줄 + 컨테이너 여덟 교체
#   --rollback         되돌리는 명령을 찍는다 (아무것도 안 바꾼다)
#
#   --force-load 는 --preload · --go 와 같이 써도 된다.
#
# ── 차례 ──────────────────────────────────────────────────────────────
#   1) bash 31-deploy.sh             읽기만 — 어긋난 곳을 먼저 고친다
#   2) bash 31-deploy.sh --preload   tar 열을 미리 싣는다
#   3) bash 31-deploy.sh             다시 읽기만 (이번엔 지문·이미지 안까지)
#   4) bash 31-deploy.sh --migrate   🔴 DB 셋이 바뀐다 (앱은 아직 옛 판이다)
#   5) bash 31-deploy.sh --go        ⏱ 정지 창 — 포털 → 재고 → A/S → 다섯
#   6) 눈으로 확인 (--go 끝의 안내)
#
# ══ 🔴 ✓ / ✗ / ? 로 센다 ═════════════════════════════════════════════
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다 · 아직 안 왔다**
#   🔴 ? 를 통과로 세지 않는다. ✗ 든 ? 든 하나라도 있으면 **종료 코드 1** 이다.
#   🔴 그러나 **「아직 안 온 것」을 ✗ 로 세지도 않는다**(17 ~ 30번의 규칙).
#      올리기 전에 --check 를 돌리면 ? 가 여럿 나오는 것이 **정상**이다.
#      --preload · --migrate · --go 는 그것이 **있어야** 도는 모드라 ✗ 로 센다.
#   🔴 psql 이 숫자가 아닌 것을 돌려주면 ? 다. **0 을 「0건이니 통과」로 읽지 않는다.**
#
# ══ 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ═══════════════════════
#   ① 큰따옴표 안의 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 주석에도 안 썼다. 쓴 뒤 세었다.
#   ② 읽기 전용 자리에 리다이렉션으로 빈 파일을 만들면(콜론 하나 뒤에 꺾쇠)
#      NAS 의 ash 가 셸을 그 자리에서 끝낸다(2026-10-12 실제 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#
# ══ 🔴 비밀값을 찍지 않는다 ═══════════════════════════════════════════
#   .env 는 **이름이 있는가/없는가**만 본다. 값도, 값의 길이도 찍지 않는다.
#
# ══ 🔴 건드리지 않는 쪽 ═══════════════════════════════════════════════
#   DB 둘(dss-pg-app · dss-pg-auth)뿐이다. 교체 **전후로** 시작 시각
#   (.State.StartedAt)을 적어 두고 **그대로인지** 본다 — 말로 하지 않는다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
TODAY=$(date +%F)
CF=$D/deploy/docker-compose.nas.yml
ENV_NAS=$D/deploy/.env.nas
ENVD=$D/deploy/env
IMAGES=$D/images
BKD=$D/backups
BKDB=$D/backups/db
INCOMING=$D/setup/incoming
MIGDIR=$D/as-migrations
MIGTAR=$INCOMING/as-migrations.tar.gz
IMG_MIGDIR=/app/drizzle

# ══════════════════════════════════════════════════════════════════════
#  🔴 이번에 올라가는 것 — 표 하나로 둔다
#
#  칸: 키|새태그|옛태그|tar이름|바이트|md5|Config지문
#  🔴 바이트 · md5 · 지문의 출처는 [배포본] — 31-build.sh 가 굽고 바로 잰 값이다.
#  🔴 세 칸이 비면 see_tar() 가 **? 로 센다**(통과로 세지 않는다). 지금은 열 줄이
#     다 차 있다. 🔴 --migrate 는 도구 이미지가 없으면 시작하지 않는다.
#  🔴 줄의 차례가 곧 **배포 차례**다 (포털 → 재고 → A/S → 나머지 다섯).
# ══════════════════════════════════════════════════════════════════════
IMGS='
auth|dss-auth:1.8|dss-auth:1.7|dss-auth-1.8.tar|113598464|d880baa7360dfcd4d047ed8e0ef152ae|sha256:98fbc4d366c86aba7991fcc90c615cb5a9cb404b9750e415c631a7877bdb81ce
inventory|dss-inventory:0.3|dss-inventory:0.2|dss-inventory-0.3.tar|95431168|71ab6ce2cd1acdfdbcacbe1d00a1a95e|sha256:40bb861581737f7859a889cd44d5e87ebb6df80fc8a34b037110ffe71e9ec4aa
as|dss-as:2.9|dss-as:2.8|dss-as-2.9.tar|132405248|02b52d16647a671c08a4d008799458c2|sha256:4010f472ca60981fba9f6c15bb6f30979d1fb2453852b55d5d72e829a0ecec2a
po|dss-po:0.7|dss-po:0.6|dss-po-0.7.tar|95437312|b97df7d10f5ba90afcaa30d3d4a8a957|sha256:425ad1d07aec24f3a1aba8c0adf9508a561790c4954762c1fba320251b38d9eb
board|dss-board:0.3|dss-board:0.2|dss-board-0.3.tar|96269312|f0cdf5d2d40ef0be525adf4204125fe9|sha256:b658d4b79a0f03a5b3eaf098838382a88aa8c9f5830a850b0f34db5a9e9f9a3f
leave|dss-leave:0.3|dss-leave:0.2|dss-leave-0.3.tar|75081728|d8ec8c5ff22a5ab49739a1deb68d8eee|sha256:6d7350f9c5b0d96a00c7b6f81138d9e06b0d91471ac56235dcd12d75e97ad7e0
meters|dss-meters:1.4|dss-meters:1.3|dss-meters-1.4.tar|114052096|58d1cf094673283896da3112994c4fcc|sha256:f1afdf453b33ede29d4c7543c1c1eb6e908fa92df3c219e69975c9edab19c51a
improvements|dss-improvements:0.4|dss-improvements:0.3|dss-improvements-0.4.tar|94991872|609e427b6af47fe1780cf2be7764da6b|sha256:65ff7c557f421c449af37f5d3e7a538ef6b554d0d672945f8ee480222b093ea8
invtools|dss-inventory-tools:3|dss-inventory-tools:2|dss-inventory-tools-3.tar|213200896|fad46f3c1e5a07537f3b7132f64b8a60|sha256:13a42952a5d0d2728952ec4f6a3a49da8c5d3d91fc65feef29f4096c092422e1
authtools|dss-auth-tools:1||dss-auth-tools-1.tar|211960832|4d82b40e564245c59ef4afa4ffbaed2a|sha256:e44be51f6831c65096f0a4e0a79b3f5b2ea2929054998eef0131729e512193f5
'
# 🔴 authtools 의 세 값은 **31-build.sh 가 아니라 이 조각이 쟀다**(2026-10-22 17:10,
#    개발 PC 의 _images-31 폴더). 지시서를 쓸 때는 tar 가 없었는데 그 뒤에 생겼다.
#    tar 안 RepoTags 가 "dss-auth-tools:1" 인 것까지 확인했다.
# 🔵 나머지 아홉은 2026-10-22 에 같은 폴더에서 **셋 다 다시 재어 대조했다** —
#    바이트 · md5 · Config 지문이 전부 31-build.sh 가 찍은 값과 같았다.
# 🔴 tar 안 Config 지문은 개발 PC 의 {{.Id}} 와 **다르다.** NAS 는 tar 안의 config
#    지문을 image ID 로 낸다 — 맞춰 볼 값은 **tar 쪽**이다(30번 137줄).
#    실제로 dss-auth-tools:1 은 개발 PC {{.Id}} 가 sha256:9f092f4b… 인데
#    tar 쪽은 sha256:e44be51f… 다. 어긋난 것이 아니라 **원래 그렇다.**
# 앱 여덟 — 키|서비스|컨테이너|호스트포트|바깥 이름
# 🔴 포트와 컨테이너 이름은 compose 의 ports: · container_name: 에서 읽어 확인했다.
APPS='
auth|app-auth|dss-auth|13100|login
inventory|app-inventory|dss-inventory|13800|inventory
as|app-as|dss-as|13000|as
po|app-po|dss-po|13600|po
board|app-board|dss-board|13400|board
leave|app-leave|dss-leave|13700|leave
meters|app-meters|dss-meters|13300|meters
improvements|app-improvements|dss-improvements|13500|improvements
'
# compose 에 반드시 있어야 하는 서비스 열여섯 ([설문] 2절이 image 줄로 확인했다)
SVC_ALL="db-app db-auth app-auth app-as tools-as app-meters tools-meters"
SVC_ALL="$SVC_ALL app-improvements tools-improvements app-po app-leave tools-leave"
SVC_ALL="$SVC_ALL app-board tools-board app-inventory tools-inventory"
# 🔴 건드리지 않는 컨테이너 둘 — 시작 시각을 적어 두고 뒤에서 대조한다
KEEP_BOXES="dss-pg-app dss-pg-auth"

# ══ 🔴 마이그레이션 — 바뀌는 셋 · 그대로인 넷 ═════════════════════════
# 칸: 상자|DB|지금|목표|도구서비스|도구이미지키|이미지안.sql
# 🔴 [설문] 2026-10-22 실측: 118 · 20 · 5
AUTH_BOX=dss-pg-auth;  AUTH_DB=dss_auth;      AUTH_HAVE=5;   AUTH_WANT=8
INV_BOX=dss-pg-app;    INV_DB=dss_inventory;  INV_HAVE=20;   INV_WANT=26
AS_BOX=dss-pg-app;     AS_DB=dss_as;          AS_HAVE=118;   AS_WANT=119
AUTH_TOOLS_SVC=tools-auth
INV_TOOLS_SVC=tools-inventory
AS_TOOLS_SVC=tools-as
# 🔵 그대로여야 하는 넷 — [설문] 실측값. 배포 **뒤에도 같아야** 한다.
KEEP_MIGS="dss_meters|3 dss_improvements|4 dss_leave|3 dss_board|1"
# 🔴 포털에 **이번에 생기는** 표 셋. [설문]이 「아직 없다」를 확인했다.
AUTH_NEW_TABLES="notification_dismissals notification_kind_purposes notification_acknowledgements"
# A/S 볼륨 — 새 .sql 하나
AS_NEW_MIGS="0118"
MIG_MARK_0118="ADD VALUE 'REPAIR_REQUEST'"
# 🔴 이미지 **안** .sql 장수 — 🔴 이 셋이 틀리면 적용이 **0건으로 조용히 끝난다.**
#    가장 조용한 실패다. 오류가 안 나고 겉으로는 성공으로 보인다.
IMG_SQL_AS=119        # dss-as:2.9  [저장소] drizzle/*.sql 119장
# 🔵 아래 둘은 [배포본] — 2026-10-22 에 **구운 이미지 안을 실제로 열어 세었다.**
#    .sql 장수와 meta/_journal.json 의 tag 줄 수가 **둘 다** 같았다.
IMG_SQL_INVTOOLS=26   # dss-inventory-tools:3  실측 26 · journal 26
IMG_SQL_AUTHTOOLS=8   # dss-auth-tools:1       실측 8 · journal 8
# 🔴 「지우는 문장」 잣대 — 앱의 migration-safety.ts 와 **같은 것**을 쓴다.
#    DELETE 만으로 세지 않는다. 외래키의 ON DELETE 가 걸려서 표만 더하는 판이
#    ✗ 가 된다(19번이 그 자리에서 넘어졌다).
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
RISKY_RE='DROP[[:space:]]+INDEX|RENAME|SET[[:space:]]+NOT[[:space:]]+NULL'
MIG_DROP_WANT=0
# 줄 수가 그대로여야 하는 표 — 배포 전후로 센다 (출처 [없음]: 지금 수를 적어 둔다)
AS_COUNT_TABLES="repair_cases customers attachments workflow_transitions"
INV_COUNT_TABLES="parts legacy_records stock_requests approval_routes"
AUTH_COUNT_TABLES="users clients user_client_grants"

# ══ 🔴 포털의 새 통로 둘 — 값으로 재어 본다 ═══════════════════════════
# 🔴 아무것도 안 바꾼다. 자격증명이 없으면 **맨 첫 문(authorizeSiteRequest)** 에서
#    돌아선다 — 본문도 안 읽고 DB 도 안 두드린다(site-dismissals.ts 의 주석).
#    · 404 → 통로가 없다 = **옛 포털(1.7)** 이 돌고 있다
#    · 401 → 통로가 있고 문이 돈다 = **맞다**
AUTH_PATH1=/api/integration/notification-dismissals
AUTH_PATH2=/api/integration/notification-acknowledgements

# ══ 🔴 compose 에 넣을 tools-auth 블록 — 줄 수를 박아 둔다 ════════════
CF_TOOLS_ADD_LINES=27
CF_TOOLS_ANCHOR='  app-as:'

# ── 설정 파일 — 🔴 **이름만** 본다 ([설문] 7절과 같은 목록) ────────────
ENV_CHECK='
as.env|AS_API_TOKEN AS_WRITE_TOKEN INVENTORY_API_BASE_URL INVENTORY_API_TOKEN INVENTORY_WRITE_TOKEN
po.env|AS_WRITE_TOKEN AS_APP_BASE_URL INVENTORY_API_BASE_URL INVENTORY_API_TOKEN
inventory.env|SSO_ISSUER SSO_CLIENT_ID SSO_REDIRECT_URI AS_LOOKUP_URL AS_LOOKUP_TOKEN AS_API_BASE_URL INVENTORY_WRITE_TOKEN
auth.env|AUTH_TX_SECRET AUTH_ACTIVE_KID
'
# compose 가 통째로 안 먹지 않으려면 **있어야 하는** env 파일들
ENV_FILES="auth.env as.env po.env meters.env improvements.env leave.env board.env inventory.env"
# 야간 백업이 뜨는 DB 일곱 (jobs/backup-nightly.sh 의 목록 그대로)
BK_DBS="dss_auth dss_meters dss_as dss_improvements dss_leave dss_board dss_inventory"

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 둘. 인자가 없으면 이대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 31-deploy.sh                 읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 31-deploy.sh --check         위와 같습니다
  bash 31-deploy.sh --preload       tar 열을 싣고 지문을 맞춥니다
  bash 31-deploy.sh --force-load    🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 31-deploy.sh --migrate       🔴 DB 셋이 바뀝니다 (5→8 · 20→26 · 118→119)
  bash 31-deploy.sh --go            ⏱ compose 여덟 줄 + 컨테이너 여덟 교체
  bash 31-deploy.sh --rollback      되돌리기 안내 (아무것도 안 바꿉니다)

  🔴 차례:  (없음) → --preload → (없음) → --migrate → --go
  🔴 --migrate 와 --go 는 **따로** 부릅니다. 마이그레이션이 덜 된 DB 에 새 판이
     뜨면 없는 표·없는 칸을 읽다 그 자리에서 죽습니다.
  🔴 --migrate 는 compose 의 **도구 둘**(tools-auth 블록 · tools-inventory 태그)도
     고칩니다. 🔵 도구는 평소에 뜨지 않아 직원이 느끼는 것이 없습니다.
  🔴 --migrate 도 --go 도 **오늘 백업이 없으면 시작하지 않습니다.**
     야간 백업은 02:30 입니다.
USAGE
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)      MODE=check ;;
    --preload)    MODE=preload ;;
    --force-load) FORCE_LOAD=1; [ "$MODE" = check ] && MODE=force-load ;;
    --migrate)    MODE=migrate ;;
    --go)         MODE=go ;;
    --rollback)   MODE=rollback ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "모르는 인자: $1"; usage; exit 2 ;;
  esac
  shift
done

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/31-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 30번의 것 + 31-survey 의 ? 칸 ────────────────────────────
PASS=0; FAIL=0; UNK=0; T0=0; STOP_AT=""; UP_AT=""; DOWN=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
unk()  { echo "  ? $*"; UNK=$((UNK + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }
# 🔴 ✗ 가 났을 때 그 자리에서 찍는다 — 오늘 이 묶음에서 검사가 틀린 적이 여섯 있다.
doubt() { say "    🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 이 줄의 기대값이"
          say "       어디서 왔는지는 바로 옆에 적혀 있습니다([설문]·[배포본]·[저장소])."; }

# 🔴 「아직 안 온 것」은 --check 에서 ✗ 가 아니라 ? 다.
#    --preload · --migrate · --go 는 그것이 **있어야** 도는 모드라 ✗ 로 센다.
missing_is_fatal() { [ "$MODE" != check ]; }
notyet() { if missing_is_fatal; then bad "$1"; else unk "$1"; fi; }
notloaded() { unk "$1"; }

isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }

# ── 사람이 칠 명령은 76자 안쪽으로만 찍는다 ────────────────────────────
CMDW=76
cmd() {
  printf '    %s\n' "$1"
  if [ "${#1}" -gt "$CMDW" ]; then
    printf '    ⚠️ 위 줄이 %s자다(%s자 넘음) — 붙여넣으면 잘릴 수 있다.\n' "${#1}" "$CMDW"
  fi
}

compose_cmd() { "$DOCKER" compose --project-directory "$D/deploy" -f "$CF" --env-file "$ENV_NAS" --profile tools "$@"; }
running() { "$DOCKER" ps --format '{{.Names}}' | grep -qx "$1"; }

# ── 표 읽기 ───────────────────────────────────────────────────────────
# 🔴 파이프를 쓰지 않는다 — 파이프는 하위 셸을 만들어 PASS/FAIL 이 사라진다.
#    도는 쪽은 전부 while … done <<EOF 꼴이다.
img_f() { printf '%s\n' "$IMGS" | awk -F'|' -v k="$1" -v n="$2" '$1==k{print $n; exit}'; }
app_f() { printf '%s\n' "$APPS" | awk -F'|' -v k="$1" -v n="$2" '$1==k{print $n; exit}'; }

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미 — 🔴 이 스크립트가 보내는 SQL 은 **전부 select** 다.
#     바꾸는 것은 --migrate 의 db:migrate 셋뿐이다.
#  🔴 psql 의 -Atc 뒤에 큰따옴표로 감싸 넘긴다. SQL 안에 큰따옴표를 쓰지 않는다.
# ══════════════════════════════════════════════════════════════════════
q()  { "$DOCKER" exec "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -Atc \"$3\"" 2>/dev/null; }
qq() { "$DOCKER" exec "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -c   \"$3\"" 2>/dev/null; }
# 🔴 수가 아니면 **빈 글자**를 돌려준다. 0 을 「0건이니 통과」로 읽지 않는다.
qnum() {
  local v
  v=$(q "$1" "$2" "$3" | head -1 | tr -d ' \r')
  isnum "$v" && printf '%s' "$v"
}
mig_count()    { qnum "$1" "$2" 'select count(*) from drizzle.__drizzle_migrations'; }
table_state()  { q "$1" "$2" "select coalesce(to_regclass('public.$3')::text,'none')" | head -1 | tr -d ' \r'; }

# ── tar 가 들고 있는 지문 (30번 501줄 글자 그대로) ────────────────────
tar_config_id() {
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
md5_of()   { md5sum "$1" 2>/dev/null | awk '{print $1}'; }

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

see_tar() { # 1 태그 2 tar경로 3 tar에서읽은지문 4 기대바이트 5 기대md5 6 기대지문
  local tag="$1" f="$2" got="$3" wsz="$4" wmd5="$5" wcfg="$6" n m
  if [ ! -s "$f" ]; then
    notyet "$tag 의 tar 가 아직 NAS 에 없다: $(basename "$f")"
    say "    → 개발 PC(PowerShell)에서 올리세요. 🔴 scp 에 -O 를 붙입니다:"
    cmd "scp -O $(basename "$f") dss-nas:/volume1/dss/images/"
    return 1
  fi
  n=$(stat -c '%s' "$f" 2>/dev/null)
  m=$(md5_of "$f")
  say "    · 지금 이 tar: 바이트 ${n:-?} · md5 ${m:-?}"
  if [ -z "$wsz" ] || [ -z "$wmd5" ] || [ -z "$wcfg" ]; then
    unk "$tag · **잰 값이 없다** — tar 가 들고 있는 지문으로만 맞춘다"
    say "       (옮기다 깨진 것은 잡지만 「개발 PC 에서 구운 그것이 맞나」는 못 본다.)"
    say "       🔴 사람이 개발 PC 에서 재어 대조해 주세요:"
    cmd "Get-FileHash -Algorithm MD5 $(basename "$f")"
    [ -n "$got" ] && say "    · 이 tar 안 Config 지문: $got"
    return 0
  fi
  [ "$n" = "$wsz" ] && ok "$tag · 바이트 $n  [배포본]" \
    || { bad "$tag 의 바이트가 $wsz 가 아니다 ($n) — 옮기다 끊겼다  [배포본]"; doubt; }
  [ "$m" = "$wmd5" ] && ok "$tag · md5 맞음  [배포본]" \
    || { bad "$tag 의 md5 가 다르다 (${m:-못 읽음}) — 파일이 상했다  [배포본]"; doubt; }
  if [ -z "$got" ]; then
    bad "$tag 의 tar 에서 manifest.json 을 읽지 못했다: $f"
    return 1
  fi
  if [ "$got" = "$wcfg" ]; then
    ok "$tag · tar 안 Config 지문이 기대값과 같다 ($(echo "$got" | cut -c1-19)…)"
  else
    bad "$tag · tar 안 Config 지문이 기대값과 다르다  [배포본]"
    say "      tar   $got"
    say "      기대  $wcfg"
    say "      🔴 **다른 판을 올린 것**이거나 옮기다 깨진 것이다."
  fi
  return 0
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

# ── compose 파일에서 서비스 한 덩어리만 잘라 낸다 (27 ~ 30번) ──────────
# 🔴 파일 전체를 grep 하면 안 된다 — 주석 줄이 그대로 걸려서 꺼져 있는 서비스를
#    「가리킨다」고 세게 된다(11-deploy.sh 의 그 함정).
svc_block() {
  awk -v s="  $2:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$1" | sed '/^[[:space:]]*#/d'
}
svc_image() { svc_block "$1" "$2" | sed -n 's/^[[:space:]]*image:[[:space:]]*//p' | head -1; }
# 🔴 글자로 센다 — 정규식이 아니다. 태그에는 점이 들어 있어(2.8 · 2.9) 정규식으로
#    보면 그 점이 아무 글자나 맞아 엉뚱한 줄을 센다.
img_line_count() {
  awk -v want="image: $2" '
    { t = $0; gsub(/^[ \t]+/, "", t); gsub(/[ \t\r]+$/, "", t)
      if (t == want) n++ }
    END { print n + 0 }
  ' "$1"
}
# 들여쓰기를 뗀 줄이 **통째로 같은** 줄 수 (주석은 저절로 안 걸린다)
exact_line_count() {
  awk -v want="$2" '
    { t = $0; gsub(/[ \t\r]+$/, "", t)
      if (t == want) n++ }
    END { print n + 0 }
  ' "$1"
}
cf_img_list() {
  awk '
    { t = $0; gsub(/^[ \t]+/, "", t); gsub(/[ \t\r]+$/, "", t)
      if (index(t, "image: ") == 1) print t }
  ' "$1" | sort
}
env_count_of() { # 1 파일 2 키 → 그 이름으로 시작하는 줄 수
  # 🔴 「|| echo 0」을 붙이지 않는다. grep -c 는 0건일 때도 0 을 찍고 종료코드만
  #    1 이라, 붙이면 값이 두 줄이 되어 비교가 전부 어긋난다(27번의 그 자리).
  [ -f "$1" ] || { echo 0; return 0; }
  grep -c "^$2=" "$1" 2>/dev/null | tr -d ' '
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 「지우는 문장」을 센다 — 앱의 migration-safety.ts 와 **같은 잣대**로
# ══════════════════════════════════════════════════════════════════════
destructive_scan() { # 1 파일 2 라벨 3 기대 개수
  local f="$1" label="$2" want="$3" n r
  n=$(grep -ciE "$DESTRUCTIVE_RE" "$f" 2>/dev/null); n=${n:-0}
  r=$(grep -ciE "$RISKY_RE" "$f" 2>/dev/null); r=${r:-0}
  if [ "$n" = "$want" ]; then
    if [ "$n" = 0 ]; then
      ok "$label — 지우는 문장이 **없다** (DROP · TRUNCATE · DELETE FROM 0줄)"
    else
      ok "$label — 지우는 문장이 **${n}줄**이다 (기대한 그대로)"
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

# ══════════════════════════════════════════════════════════════════════
#  🔴 A/S 의 drizzle 은 **이미지 안이 아니라 볼륨**이다
#      /volume1/dss/as-migrations → tools-as 의 /app/drizzle (읽기 전용)
#  🔴 .sql 만으로는 부족하다 — **meta/_journal.json 과 snapshot 까지** 가야 한다.
#     _journal.json 이 옛것이면 drizzle 은 새 .sql 을 **아예 모르고** 적용이
#     0건으로 조용히 끝난다(30번이 당한 그것이다).
# ══════════════════════════════════════════════════════════════════════
MIG_N_SQL=0; MIG_N_J=0; MIG_STATE=""
read_migdir() {
  MIG_N_SQL=0; MIG_N_J=0; MIG_STATE=""
  [ -d "$MIGDIR" ] || { MIG_STATE=NODIR; return 0; }
  MIG_N_SQL=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  [ -f "$MIGDIR/meta/_journal.json" ] \
    && MIG_N_J=$(grep -c '"tag"' "$MIGDIR/meta/_journal.json" 2>/dev/null | tr -d ' ')
  MIG_N_SQL=${MIG_N_SQL:-0}; MIG_N_J=${MIG_N_J:-0}
  if [ "$MIG_N_SQL" = "$AS_WANT" ] && [ "$MIG_N_J" = "$AS_WANT" ]; then
    MIG_STATE=DONE
  elif [ "$MIG_N_SQL" = "$AS_HAVE" ] && [ "$MIG_N_J" = "$AS_HAVE" ]; then
    MIG_STATE=OLD
  else
    MIG_STATE=ODD
  fi
  return 0
}
check_new_migs() {
  local t miss="" f rc=0
  for t in $AS_NEW_MIGS; do
    ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || miss="$miss $t(sql)"
    [ -f "$MIGDIR/meta/${t}_snapshot.json" ] || miss="$miss $t(snapshot)"
  done
  if [ -z "$miss" ]; then
    ok "$AS_NEW_MIGS 의 .sql 과 meta/*_snapshot.json 이 다 있다"
  else
    bad "🔴 빠진 것:$miss"
    rc=1
  fi
  f=$(ls -1 "$MIGDIR/0118_"*.sql 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    grep -qF "$MIG_MARK_0118" "$f" \
      && ok "0118 안에 그 글자가 있다 ($(basename "$f"))  [저장소]" \
      || { bad "🔴 0118 안에 $MIG_MARK_0118 가 **없다** — 다른 파일이다"; rc=1; }
    destructive_scan "$f" "A/S 0118" "$MIG_DROP_WANT"
  fi
  return "$rc"
}
place_migs() {
  if [ ! -s "$MIGTAR" ]; then
    say "  · incoming 에 묶음이 없다 — 폴더가 이미 새것인지 아래에서 본다"
    return 0
  fi
  rm -rf "$MIGDIR.new"; mkdir -p "$MIGDIR.new"
  if tar -xzf "$MIGTAR" -C "$MIGDIR.new" --strip-components=1; then
    rm -rf "$MIGDIR.old"
    [ -d "$MIGDIR" ] && mv "$MIGDIR" "$MIGDIR.old"
    mv "$MIGDIR.new" "$MIGDIR"
    chown -R root:root "$MIGDIR"; chmod -R a+rX "$MIGDIR"
    ok "as-migrations 새것으로 (옛것: as-migrations.old — 되돌릴 길이다)"
    say "    🔵 묶음은 **지우지 않는다** — 다시 돌릴 때 쓴다."
    return 0
  fi
  rm -rf "$MIGDIR.new"
  bad "as-migrations 풀기 실패"
  return 1
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 이미지 **안**의 .sql 을 센다 — 가장 조용한 실패를 여기서 잡는다
#  🔴 못 읽으면 **판정하지 않는다**(?). 0 을 「0건이니 통과」로 읽지 않는다.
# ══════════════════════════════════════════════════════════════════════
img_sql_count() { # 1 태그 → 개수 (못 읽으면 빈 글자)
  local v
  v=$("$DOCKER" run --rm --entrypoint sh "$1" \
      -c "ls -1 $IMG_MIGDIR/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r' | head -1)
  isnum "$v" && printf '%s' "$v"
}
img_sql_check() { # 1 태그 2 라벨 3 기대값
  local tag="$1" label="$2" want="$3" n
  if ! have_img "$tag"; then
    notloaded "$label · $tag 가 아직 NAS 에 없어 이미지 안 .sql 을 못 셌다"
    return 0
  fi
  n=$(img_sql_count "$tag")
  if [ -z "$n" ]; then
    unk "$label · 이미지 안을 못 읽었다 — **판정하지 않는다**"
    return 0
  fi
  if [ "$n" = "$want" ]; then
    ok "$label · 이미지 안 $IMG_MIGDIR 의 .sql 이 ${n}장이다  [저장소]"
  else
    bad "🔴 $label · 이미지 안 .sql 이 ${n}장이다 (${want}장이어야 한다)  [저장소]"
    say "    → 🔴 이 수가 틀리면 적용이 **0건으로 조용히 끝난다.** 다시 구우세요."
    doubt
    return 1
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 포털의 새 통로 둘 — 값으로 재어 본다 (아무것도 안 바꾼다)
# ══════════════════════════════════════════════════════════════════════
auth_gate_probe() { # 1 경로 2 기대(401|404)
  local path="$1" want="$2" port code
  port=$(app_f auth 4)
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 -X POST \
         "http://127.0.0.1:$port$path" 2>/dev/null)
  say "    · POST $path → ${code:-없음}"
  case "${code:-}" in
    401|403)
      if [ "$want" = 401 ]; then
        ok "통로가 **있고 문이 돈다** ($code — 맞다)"
      else
        bad "🔴 벌써 $code 다 — 새 포털이 이미 돌고 있다 (기대 $want)"
      fi ;;
    404)
      if [ "$want" = 404 ]; then
        ok "아직 통로가 없다 (404 — **배포 전이라 맞다**)"
      else
        bad "🔴 통로가 **404** 다 — 🔴 옛 포털(1.7)이 돌고 있다"
        say "      일곱 집의 ✕ 지움과 ✓ 확인이 그 자리에서 실패한다."
      fi ;;
    000|"") bad "🔴 대답이 없다 (${code:-없음}) — 포털이 안 떠 있다" ;;
    *)      unk "${code} 가 왔다 — **판정하지 않는다** (기대는 $want 였다)" ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 compose 고치기 — **두 번 나눠서** 한다
#
#   ㄱ) --migrate : tools-auth 블록 ${CF_TOOLS_ADD_LINES}줄 + tools-inventory :2 → :3
#   ㄴ) --go      : 앱 image 줄 **여덟**
#
#  🔴 두 번 다 사본을 먼저 뜨고, 바꾼 뒤 아래를 **전부** 센다. 하나라도 어긋나면
#     **사본으로 되돌리고 멈춘다.**
#       · 줄 수가 기대한 그대로 늘었는가 (ㄴ 는 **하나도 안 늘어야** 한다)
#       · image: 줄 **전체 목록**이 우리가 바꾼 것 말고는 글자까지 그대로인가
#       · compose config -q 가 통과하는가 · 서비스 목록이 그대로인가
# ══════════════════════════════════════════════════════════════════════
TMPD=$D/setup/tmp-31-$STAMP
CF_BK=""
backup_compose() { # → CF_BK 를 채운다
  local bk="$BKD/docker-compose.nas.yml.$STAMP"
  mkdir -p "$BKD"
  cp -p "$CF" "$bk" || { bad "compose 사본을 못 떴다"; return 1; }
  chmod 644 "$bk"
  CF_BK=$bk
  ok "compose 사본 — backups/docker-compose.nas.yml.$STAMP"
}
restore_compose() {
  [ -n "$CF_BK" ] || return 1
  say "  🔴 **사본으로 되돌립니다.**"
  cp -p "$CF_BK" "$CF"; chown root:root "$CF"; chmod 644 "$CF"
  ok "compose 를 사본으로 되돌렸다 — 바꾸기 전과 글자까지 같다"
}

# 🔴 넣을 블록. 🔵 DB 상자가 dss-pg-app 이 **아니라 dss-pg-auth** 다 —
#    포털만 DB 를 따로 쓴다. 이 줄은 app-auth 블록의 같은 줄에서 베꼈다.
# 🔴 서명 개인키 볼륨(/volume1/dss/auth-keys)은 **붙이지 않는다.**
write_tools_block() { # 1 쓸 파일
  cat > "$1" <<'BLOCK'
  # ══ 도구 — 포털. 평소에는 뜨지 않는다 ════════════════════════════════
  #
  # 🔴 2026-10-22 서른한째 배포가 더했다. 포털에 마이그레이션이 처음 생겨
  #    (0005 · 0006 · 0007) 그것을 돌릴 길이 없었다.
  #
  # 🔴 DB 상자가 dss-pg-app 이 **아니라 dss-pg-auth** 다 — 포털만 DB 를 따로 쓴다.
  #    베끼다 틀리면 호스트를 못 찾는 것이 아니라 **엉뚱한 서버에 붙어** 끝난다.
  # 🔴 서명 개인키 볼륨(/volume1/dss/auth-keys)을 **붙이지 않는다** — db:migrate 는
  #    키를 보지 않고, 그 파일 하나면 누구든 통행증을 위조할 수 있다.
  #
  #   docker compose -f docker-compose.nas.yml --env-file .env.nas --profile tools \
  #     run --rm tools-auth npm run db:migrate
  #
  tools-auth:
    image: dss-auth-tools:1
    profiles: [tools]
    networks: [dss-data, dss-edge]
    env_file:
      - ./env/auth.env
    environment:
      TZ: Asia/Seoul
      DATABASE_URL: postgresql://dss_auth_app:${AUTH_APP_PASSWORD}@dss-pg-auth:5432/dss_auth
    deploy:
      resources:
        limits:
          memory: 512M

BLOCK
}

compose_tools_done() {
  [ "$(exact_line_count "$CF" '  tools-auth:')" = 1 ] \
    && [ "$(img_line_count "$CF" "$(img_f invtools 2)")" = 1 ]
}
compose_apps_done() {
  local k new
  while IFS='|' read -r k new _rest; do
    [ -n "${k:-}" ] || continue
    [ "$k" = invtools ] && continue
    [ "$k" = authtools ] && continue
    [ "$(img_line_count "$CF" "$new")" = 1 ] || return 1
  done <<EOF
$IMGS
EOF
  return 0
}

edit_compose_tools() {
  local tmp blk before after nb na n old new
  old=$(img_f invtools 3); new=$(img_f invtools 2)
  mkdir -p "$TMPD"; chown root:root "$TMPD"; chmod 700 "$TMPD"
  tmp="$TMPD/compose.new"; blk="$TMPD/tools-block.txt"
  before="$TMPD/img-before.txt"; after="$TMPD/img-after.txt"
  backup_compose || return 1

  # ── ① 바꾸기 **전**의 모습이 기대한 그대로인가 ──────────────────────
  if [ "$(exact_line_count "$CF" '  tools-auth:')" != 0 ]; then
    bad "🔴 compose 에 tools-auth 가 **이미 있다** — 누가 먼저 넣었다"
    say "    → 고치지 말고 알리세요."
    return 1
  fi
  if [ "$(img_line_count "$CF" "$old")" != 1 ]; then
    bad "🔴 compose 에 「image: $old」 줄이 하나가 아니다"
    say "    → 남의 변경이 섞였거나 이미 바뀐 뒤다. 고치지 말고 알리세요."
    return 1
  fi
  if [ "$(img_line_count "$CF" "$new")" != 0 ]; then
    bad "🔴 compose 에 「image: $new」 줄이 **이미 있다**"
    return 1
  fi
  if [ "$(exact_line_count "$CF" "$CF_TOOLS_ANCHOR")" != 1 ]; then
    bad "🔴 compose 에 「$CF_TOOLS_ANCHOR」 줄이 하나가 아니다 — 넣을 자리를 못 고른다"
    return 1
  fi
  nb=$(wc -l < "$CF")
  cf_img_list "$CF" > "$before"

  # ── ② 글자로 넣고, 글자로 바꾼다 (awk 한 번) ────────────────────────
  write_tools_block "$blk" || { bad "넣을 블록을 만들지 못했다"; return 1; }
  n=$(wc -l < "$blk")
  if [ "$n" != "$CF_TOOLS_ADD_LINES" ]; then
    bad "🔴 넣을 블록이 ${n}줄이다 (${CF_TOOLS_ADD_LINES}줄이어야 한다)"
    return 1
  fi
  awk -v blk="$blk" -v anchor="$CF_TOOLS_ANCHOR" \
      -v oi="image: $old" -v ni="image: $new" '
    {
      line = $0
      lead = line
      sub(/^[ \t]*/, "", lead)
      ind = substr(line, 1, length(line) - length(lead))
      t = lead
      sub(/[ \t\r]+$/, "", t)
      a = line
      sub(/[ \t\r]+$/, "", a)
      if (t == oi) { print ind ni; next }
      if (done == 0 && a == anchor) {
        while ((getline b < blk) > 0) print b
        close(blk)
        done = 1
      }
      print line
    }' "$CF" > "$tmp" || { bad "compose 를 못 썼다"; rm -f "$tmp"; return 1; }

  # ── ③ 줄 수가 정확히 늘었는가 ───────────────────────────────────────
  na=$(wc -l < "$tmp")
  if [ "$na" != "$((nb + CF_TOOLS_ADD_LINES))" ]; then
    bad "🔴 줄 수가 ${nb} → ${na} 다 ($((nb + CF_TOOLS_ADD_LINES)) 이어야 한다) — **바꾸지 않는다**"
    rm -f "$tmp"
    return 1
  fi
  ok "줄 수 ${nb} → ${na} (+${CF_TOOLS_ADD_LINES}줄 — 기대한 그대로)"
  cp -p "$tmp" "$CF" && rm -f "$tmp"
  chown root:root "$CF"; chmod 644 "$CF"

  # ── ④ 바꾼 뒤 ───────────────────────────────────────────────────────
  local rc=0
  [ "$(exact_line_count "$CF" '  tools-auth:')" = 1 ] \
    && ok "tools-auth 서비스가 한 줄로 들어갔다" \
    || { bad "🔴 tools-auth 가 안 들어갔다"; rc=1; }
  [ "$(img_line_count "$CF" "$new")" = 1 ] && [ "$(img_line_count "$CF" "$old")" = 0 ] \
    && ok "$old → $new" || { bad "🔴 재고 도구 태그가 안 바뀌었다"; rc=1; }
  cf_img_list "$CF" > "$after"
  { awk -v oi="image: $old" -v ni="image: $new" \
        '{ if ($0 == oi) print ni; else print }' "$before"
    printf 'image: %s\n' "$(img_f authtools 2)"; } | sort > "$TMPD/img-expect.txt"
  if cmp -s "$TMPD/img-expect.txt" "$after"; then
    ok "🔴 image: 줄 전체 목록이 **그 둘 말고는 글자까지 그대로**다"
  else
    bad "🔴 image: 줄이 그 둘 말고 **또 달라졌다** — 남의 변경이 섞였다"
    diff "$TMPD/img-expect.txt" "$after" 2>/dev/null | sed 's/^/      /' | head -10
    rc=1
  fi
  if [ "$rc" = 0 ]; then
    if compose_cmd config --quiet >/dev/null 2>&1; then
      ok "바꾼 compose 의 문법이 통과했다"
    else
      bad "🔴 바꾼 compose 에 문법 오류가 있다"
      compose_cmd config --quiet 2>&1 | sed 's/^/      /' | head -8
      rc=1
    fi
  fi
  if [ "$rc" = 0 ]; then
    compose_cmd config --services 2>/dev/null | grep -qx tools-auth \
      && ok "서비스 목록에 tools-auth 가 보인다 — **부를 수 있다**" \
      || { bad "🔴 서비스 목록에 tools-auth 가 안 보인다"; rc=1; }
  fi
  if [ "$rc" != 0 ]; then
    restore_compose
    return 1
  fi
  say "  🔴 compose 를 고쳤다 — **아직 아무것도 안 뜨고 안 멈췄다.** 글자일 뿐이다."
  say "     🔵 고친 둘은 profiles: [tools] 라 up -d 로 뜨지 않는다."
  return 0
}

edit_compose_apps() {
  local tmp before after nb na k new old rc=0 sedf
  mkdir -p "$TMPD"; chown root:root "$TMPD"; chmod 700 "$TMPD"
  tmp="$TMPD/compose-apps.new"
  before="$TMPD/img-before-apps.txt"; after="$TMPD/img-after-apps.txt"
  sedf="$TMPD/img-swap.txt"
  backup_compose || return 1

  # ── ① 바꾸기 전 — 옛 태그 여덟이 한 줄씩 · 새 태그는 0줄 ────────────
  while IFS='|' read -r k new old _rest; do
    [ -n "${k:-}" ] || continue
    [ "$k" = invtools ] && continue
    [ "$k" = authtools ] && continue
    if [ "$(img_line_count "$CF" "$old")" != 1 ]; then
      bad "🔴 compose 에 「image: $old」 줄이 하나가 아니다"
      rc=1
    fi
    if [ "$(img_line_count "$CF" "$new")" != 0 ]; then
      bad "🔴 compose 에 「image: $new」 줄이 **이미 있다**"
      rc=1
    fi
  done <<EOF
$IMGS
EOF
  [ "$rc" = 0 ] || { say "    → 남의 변경이 섞였거나 이미 바뀐 뒤다. 고치지 말고 알리세요."; return 1; }
  nb=$(wc -l < "$CF")
  cf_img_list "$CF" > "$before"

  # ── ② 글자로 바꾼다 — 바꿀 짝 여덟을 파일로 적어 awk 에 넘긴다 ──────
  rm -f "$sedf"; touch "$sedf"
  while IFS='|' read -r k new old _rest; do
    [ -n "${k:-}" ] || continue
    [ "$k" = invtools ] && continue
    [ "$k" = authtools ] && continue
    printf 'image: %s|image: %s\n' "$old" "$new" >> "$sedf"
  done <<EOF
$IMGS
EOF
  [ "$(wc -l < "$sedf")" = 8 ] || { bad "🔴 바꿀 짝이 여덟이 아니다 ($(wc -l < "$sedf"))"; return 1; }
  awk -v swap="$sedf" '
    BEGIN {
      while ((getline s < swap) > 0) {
        p = index(s, "|")
        from[substr(s, 1, p - 1)] = substr(s, p + 1)
      }
      close(swap)
    }
    {
      line = $0
      lead = line
      sub(/^[ \t]*/, "", lead)
      ind = substr(line, 1, length(line) - length(lead))
      t = lead
      sub(/[ \t\r]+$/, "", t)
      if (t in from) { print ind from[t]; next }
      print line
    }' "$CF" > "$tmp" || { bad "compose 를 못 썼다"; rm -f "$tmp"; return 1; }

  # ── ③ 줄 수가 **하나도 안 늘어야** 한다 ─────────────────────────────
  na=$(wc -l < "$tmp")
  if [ "$na" != "$nb" ]; then
    bad "🔴 줄 수가 ${nb} → ${na} 다 (**그대로여야** 한다) — 바꾸지 않는다"
    rm -f "$tmp"
    return 1
  fi
  ok "줄 수 ${nb} → ${na} (안 늘었다 — 태그만 갈았다)"
  cp -p "$tmp" "$CF" && rm -f "$tmp"
  chown root:root "$CF"; chmod 644 "$CF"

  # ── ④ 바꾼 뒤 ───────────────────────────────────────────────────────
  while IFS='|' read -r k new old _rest; do
    [ -n "${k:-}" ] || continue
    [ "$k" = invtools ] && continue
    [ "$k" = authtools ] && continue
    [ "$(img_line_count "$CF" "$new")" = 1 ] && [ "$(img_line_count "$CF" "$old")" = 0 ] \
      && ok "$old → $new" || { bad "🔴 $k 태그가 안 바뀌었다"; rc=1; }
  done <<EOF
$IMGS
EOF
  cf_img_list "$CF" > "$after"
  awk -v swap="$sedf" '
    BEGIN { while ((getline s < swap) > 0) { p = index(s, "|"); from[substr(s, 1, p - 1)] = substr(s, p + 1) } close(swap) }
    { if ($0 in from) print from[$0]; else print }' "$before" | sort > "$TMPD/img-expect-apps.txt"
  if cmp -s "$TMPD/img-expect-apps.txt" "$after"; then
    ok "🔴 image: 줄 전체 목록이 **그 여덟 말고는 글자까지 그대로**다"
    say "    🔵 건드리지 않는 쪽의 태그를 박아 두지 않았다 — 바꾸기 전 목록과 견준다."
  else
    bad "🔴 image: 줄이 그 여덟 말고 **또 달라졌다** — 남의 변경이 섞였다"
    diff "$TMPD/img-expect-apps.txt" "$after" 2>/dev/null | sed 's/^/      /' | head -12
    rc=1
  fi
  if [ "$rc" = 0 ]; then
    if compose_cmd config --quiet >/dev/null 2>&1; then
      ok "바꾼 compose 의 문법이 통과했다"
    else
      bad "🔴 바꾼 compose 에 문법 오류가 있다"
      compose_cmd config --quiet 2>&1 | sed 's/^/      /' | head -8
      rc=1
    fi
  fi
  if [ "$rc" != 0 ]; then
    restore_compose
    return 1
  fi
  say "  🔴 compose 를 고쳤다 — **아직 아무것도 안 뜨고 안 멈췄다.** 글자일 뿐이다."
  say "     🔴 다만 지금부터 **인자 없는 up -d 를 부르지 마세요.** 여덟이 한꺼번에 올라온다."
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
# ══════════════════════════════════════════════════════════════════════
MIG_AUTH_NOW=""; MIG_INV_NOW=""; MIG_AS_NOW=""

run_checks() {
  local k new old tarf sz md5 cfg v n b svc cname port host f db want line rest
  local FREE_KB FREE_H MEM code

  # ── 1-ㄱ. 올린 파일 ─────────────────────────────────────────────────
  step "1-ㄱ. 올린 파일 — 이미지 tar **열** (아홉 + 포털 도구)"
  say "  🔴 기대값의 출처는 [배포본] — 굽고 바로 잰 값이다. 2026-10-22 에 개발 PC"
  say "     에서 **열 개 다 다시 재어 대조했다**(바이트 · md5 · Config 지문 셋)."
  while IFS='|' read -r k new old tarf sz md5 cfg; do
    [ -n "${k:-}" ] || continue
    say "  · $new"
    v=$(tar_config_id "$IMAGES/$tarf" 2>/dev/null) || v=""
    eval "EXP_$k=\$v"
    see_tar "$new" "$IMAGES/$tarf" "$v" "$sz" "$md5" "$cfg" || true
  done <<EOF
$IMGS
EOF
  say "  🔴 tar 가 이미지의 1/4 쯤인 것은 **정상**이다. 지난 판과 견주세요:"
  say "     dss-as 2.7 → 131,561,472 · 2.8 → 132,020,224 · **2.9 → 132,405,248**"
  say "     dss-auth 1.7 → 113,596,928 · **1.8 → 113,598,464**"
  say "     크게 달라졌으면 **그쪽을 먼저 의심한다.**"

  # ── 1-ㄴ. NAS 에 실린 이미지 ────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (올라가는 열 · 되돌릴 옛것 아홉)"
  while IFS='|' read -r k new old tarf sz md5 cfg; do
    [ -n "${k:-}" ] || continue
    eval "v=\${EXP_$k:-}"
    if have_img "$new"; then
      if [ -n "$v" ]; then
        verify_img "$new" "$v" || force_load_hint
      else
        ok "$new 가 실려 있다 (tar 가 없어 지문은 못 맞췄다)"
      fi
    else
      notloaded "$new 는 아직 NAS 에 실리지 않았다 — --preload 나 --go 가 싣는다"
    fi
  done <<EOF
$IMGS
EOF
  say "  🔴 지문이 어긋나면 **혼자 고쳐지지 않는다.** 태그가 같으면 docker load 를"
  say "     그냥 부르는 것으로는 안 바뀐다 — --force-load 를 쓰세요."
  say "  🔴 되돌아갈 옛 이미지 아홉 — 되돌리기가 그것을 쓴다. **지우지 마세요.**"
  while IFS='|' read -r k new old rest; do
    [ -n "${k:-}" ] || continue
    [ -n "${old:-}" ] || continue
    have_img "$old" && ok "$old 가 아직 있다 (되돌릴 길이 열려 있다)" \
      || bad "🔴 $old 가 NAS 에 없다 — 되돌리려면 tar 를 다시 올려야 한다"
  done <<EOF
$IMGS
EOF

  # ── 1-ㄷ. 지금 선 판 여덟 ───────────────────────────────────────────
  step "1-ㄷ. 🔴 지금 선 판 여덟이 [설문] 실측 그대로인가"
  say "  🔴 하나라도 다르면 그 사이 **다른 세션이 올린 것**이다 — 기준이 틀렸다는"
  say "     뜻이고 배포 범위를 다시 세야 한다. 지어내지 말고 멈추세요."
  while IFS='|' read -r k svc cname port host; do
    [ -n "${k:-}" ] || continue
    old=$(img_f "$k" 3)
    v=$("$DOCKER" ps --filter "name=^${cname}$" --format '{{.Image}}' 2>/dev/null | head -1)
    if [ -z "$v" ]; then
      bad "$cname 가 안 돌고 있다 — 멈춘 것이 있다. 배포 전에 까닭을 보세요"
    elif [ "$v" = "$old" ]; then
      ok "$cname 가 $v 로 돈다  [설문]"
    elif [ "$v" = "$(img_f "$k" 2)" ]; then
      ok "$cname 가 **이미 새 판** $v 로 돈다 (DONE)"
    else
      bad "🔴 $cname 가 $v 로 돈다 (기대 $old)  [설문]"
      doubt
    fi
  done <<EOF
$APPS
EOF

  # ── 1-ㄹ. 🔴 마이그레이션 ───────────────────────────────────────────
  step "1-ㄹ. 🔴 마이그레이션 — 바뀌는 셋 · 그대로여야 하는 넷"
  say "  🔴 **돌리는 쪽이 시스템마다 다르다.** 포털은 새 도구 이미지, 재고는 도구"
  say "     이미지 안, A/S 는 볼륨이다. 하나만 보면 0건으로 조용히 끝난다."

  say "  ── ① 포털 dss_auth — $AUTH_HAVE → **$AUTH_WANT**  [설문]"
  MIG_AUTH_NOW=$(mig_count "$AUTH_BOX" "$AUTH_DB")
  if [ -z "$MIG_AUTH_NOW" ]; then
    unk "포털 적용 수를 못 읽었다 (psql 이 수를 안 돌려줬다)"
  elif [ "$MIG_AUTH_NOW" = "$AUTH_HAVE" ]; then
    ok "지금 ${MIG_AUTH_NOW} — **--migrate 가 셋을 올린다**"
    say "    🔵 마지막 적용이 2026-08-27 이다. 그 뒤 포털 배포는 전부 0건이었다."
  elif [ "$MIG_AUTH_NOW" = "$AUTH_WANT" ]; then
    ok "**이미 ${MIG_AUTH_NOW}** — 포털 마이그레이션은 끝났다 (DONE)"
  else
    bad "🔴 포털이 $AUTH_HAVE 도 $AUTH_WANT 도 아니다 (${MIG_AUTH_NOW})  [설문]"
    doubt
  fi
  img_sql_check "$(img_f authtools 2)" "포털 도구" "$IMG_SQL_AUTHTOOLS"

  say "  ── ② 재고 dss_inventory — $INV_HAVE → **$INV_WANT**  [설문]"
  MIG_INV_NOW=$(mig_count "$INV_BOX" "$INV_DB")
  if [ -z "$MIG_INV_NOW" ]; then
    unk "재고 적용 수를 못 읽었다"
  elif [ "$MIG_INV_NOW" = "$INV_HAVE" ]; then
    ok "지금 ${MIG_INV_NOW} — **--migrate 가 여섯을 올린다**"
  elif [ "$MIG_INV_NOW" = "$INV_WANT" ]; then
    ok "**이미 ${MIG_INV_NOW}** (DONE)"
  else
    bad "🔴 재고가 $INV_HAVE 도 $INV_WANT 도 아니다 (${MIG_INV_NOW})  [설문]"
    doubt
  fi
  img_sql_check "$(img_f invtools 2)" "재고 도구" "$IMG_SQL_INVTOOLS"
  say "    🔴 도구가 :2 인 채로 돌리면 새 여섯이 **아예 존재하지 않는다** — 0건으로"
  say "       조용히 끝나고 겉으로는 성공으로 보인다. --migrate 가 compose 를 고친다."

  say "  ── ③ A/S dss_as — 🔴 **값 넷**을 다 센다 ($AS_HAVE → **$AS_WANT**)"
  MIG_AS_NOW=$(mig_count "$AS_BOX" "$AS_DB")
  if [ -z "$MIG_AS_NOW" ]; then
    unk "① 운영 DB 적용 수를 못 읽었다"
  elif [ "$MIG_AS_NOW" = "$AS_HAVE" ]; then
    ok "① 운영 DB ${MIG_AS_NOW} — **--migrate 가 하나를 올린다**  [설문]"
  elif [ "$MIG_AS_NOW" = "$AS_WANT" ]; then
    ok "① 운영 DB **이미 ${MIG_AS_NOW}** (DONE)"
  else
    bad "🔴 ① 운영 DB 가 $AS_HAVE 도 $AS_WANT 도 아니다 (${MIG_AS_NOW})  [설문]"
    doubt
  fi
  read_migdir
  say "  ②③ 볼륨 $MIGDIR — .sql ${MIG_N_SQL}장 · _journal.json 의 tag ${MIG_N_J}줄"
  case "$MIG_STATE" in
    DONE) ok "②③ **이미 $AS_WANT 이다** — 올릴 묶음이 없다"
          check_new_migs || true ;;
    OLD)  say "    🔴 아직 $AS_HAVE 이다 — **0118 이 그 폴더에 없다.**"
          say "       그대로 두면 적용이 **0건으로 조용히 끝난다**(drizzle 은"
          say "       _journal.json 에 없는 .sql 을 아예 모른다)."
          if [ -s "$MIGTAR" ]; then
            ok "묶음이 올라와 있다 — **--migrate 가 갈아 끼운다**"
            say "    · 바이트 $(stat -c '%s' "$MIGTAR" 2>/dev/null) · md5 $(md5_of "$MIGTAR")"
          else
            notyet "🔴 갈아 끼울 묶음이 **없다**: $MIGTAR"
            say "      → 개발 PC(PowerShell)에서 만들어 올리세요:"
            cmd "cd C:\\Users\\희만\\Desktop\\Development\\RF_Service_System"
            cmd "tar -czf ..\\as-migrations.tar.gz drizzle"
            cmd "cd .."
            cmd "scp -O as-migrations.tar.gz dss-nas:$INCOMING/"
            say "      🔴 tar 에 드라이브 문자(C:)를 주지 마세요 — 원격 호스트로 읽습니다."
          fi ;;
    NODIR) bad "🔴 $MIGDIR 폴더가 **없다** — compose 가 tools-as 에 붙이는 그 폴더다" ;;
    *)    bad "🔴 볼륨이 $AS_HAVE 도 $AS_WANT 도 아니다 (.sql ${MIG_N_SQL} · tag ${MIG_N_J})"
          say "    → 고치지 말고 **먼저 알리세요.**" ;;
  esac
  say "  ④ 새 A/S 이미지 안:"
  img_sql_check "$(img_f as 2)" "A/S 2.9" "$IMG_SQL_AS"
  v=$("$DOCKER" exec dss-as sh -c "ls -1 $IMG_MIGDIR/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  if isnum "$v"; then
    say "    · 견줌 — **지금 도는** dss-as 안에는 ${v}장 (이것이 $AS_HAVE 이면 자연스럽다)"
  else
    unk "지금 도는 dss-as 안을 못 읽었다 — 0 을 통과로 읽지 않는다"
  fi

  say "  ── ④ 🔵 그대로여야 하는 넷 — **배포 뒤에도 같아야 한다**  [설문]"
  for line in $KEEP_MIGS; do
    db=${line%%|*}; want=${line#*|}
    v=$(mig_count dss-pg-app "$db")
    if [ -z "$v" ]; then
      unk "$db 적용 수를 못 읽었다"
    elif [ "$v" = "$want" ]; then
      ok "$db ${v} — 그대로  [설문]"
    else
      bad "🔴 $db 가 ${v} 다 (${want} 를 기대했다)  [설문]"
      doubt
    fi
  done
  say "  🔵 PO 는 제 DB 가 없다 — A/S 와 **같은 dss_as** 를 본다."

  # ── 1-ㅁ. 포털의 새 표 셋 ───────────────────────────────────────────
  step "1-ㅁ. 🔴 포털에 **이번에 생기는** 표 셋 — 아직 없어야 정상이다  [설문]"
  for f in $AUTH_NEW_TABLES; do
    v=$(table_state "$AUTH_BOX" "$AUTH_DB" "$f")
    case "$v" in
      none) ok "$f 가 아직 없다 (배포 전이라 맞다)" ;;
      "$f") if [ "${MIG_AUTH_NOW:-}" = "$AUTH_WANT" ]; then
              ok "$f 가 있다 — 마이그레이션이 끝난 뒤라 맞다 (DONE)"
            else
              bad "🔴 $f 가 **이미 있다** — 누가 손으로 만들었다. 사람이 보세요"
            fi ;;
      *)    unk "$f 의 유무를 못 읽었다 (psql 이 none 도 이름도 아닌 것을 돌려줬다)" ;;
    esac
  done

  # ── 1-ㅂ. compose ───────────────────────────────────────────────────
  step "1-ㅂ. compose ($CF)"
  say "  🔴 이번 판에서 compose 가 바뀌는 자리는 **둘로 나뉜다**:"
  say "     ㄱ) --migrate — tools-auth 블록 ${CF_TOOLS_ADD_LINES}줄 + tools-inventory :2 → :3"
  say "     ㄴ) --go      — 앱 image 줄 **여덟**"
  say "     🔴 저장소 사본을 올리지 않는다 — 이 스크립트가 **제자리에서** 고친다."
  if compose_cmd config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_cmd config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  v=$(compose_cmd config --services 2>/dev/null)
  for f in $SVC_ALL; do
    printf '%s\n' "$v" | grep -qx "$f" && ok "서비스 목록에 $f 가 있다" \
      || bad "서비스 목록에 $f 가 없다 — 주석으로 꺼져 있다"
  done
  say "  🔴 도구 둘 — 🔵 「아직(PENDING)」도 「이미 했다(DONE)」도 ✗ 가 아니다:"
  if compose_tools_done; then
    ok "tools-auth 가 있고 tools-inventory 가 $(img_f invtools 2) 다 (DONE)"
    printf '%s\n' "$v" | grep -qx tools-auth \
      && ok "tools-auth 를 **부를 수 있다**" \
      || bad "🔴 tools-auth 줄은 있는데 서비스 목록에 안 뜬다"
  elif [ "$(exact_line_count "$CF" '  tools-auth:')" = 0 ] \
       && [ "$(img_line_count "$CF" "$(img_f invtools 3)")" = 1 ]; then
    say "    · 아직 옛 모습이다 — **--migrate 가 고친다** (PENDING)"
    say "      🔴 그 전에는 포털 · 재고 마이그레이션을 **돌릴 길이 없다.**"
  else
    bad "🔴 도구 둘이 기대한 모습이 아니다 — 반만 들어간 상태다"
    say "      tools-auth 줄 $(exact_line_count "$CF" '  tools-auth:') ·"
    say "      tools-inventory image $(svc_image "$CF" tools-inventory)"
    say "      → 고치지 말고 알리세요."
  fi
  say "  🔴 앱 태그 여덟:"
  if compose_apps_done; then
    ok "compose 가 **이미 새 태그 여덟**을 가리킨다 (DONE)"
  else
    n=0
    while IFS='|' read -r k new old rest; do
      [ -n "${k:-}" ] || continue
      [ "$k" = invtools ] && continue
      [ "$k" = authtools ] && continue
      [ "$(img_line_count "$CF" "$old")" = 1 ] && n=$((n + 1))
    done <<EOF
$IMGS
EOF
    if [ "$n" = 8 ]; then
      say "    · 아직 옛 태그 여덟이다 — **--go 가 고친다** (PENDING)"
    else
      bad "🔴 옛 태그가 여덟 중 ${n}줄만 보인다 — 반만 바뀐 상태다. 고치지 말고 알리세요"
      cf_img_list "$CF" | sed 's/^/      /'
    fi
  fi
  say "  🔴 볼륨 — 이번 판은 **하나도 더하지 않는다.** 사라지지 않았는지만 본다:"
  svc_block "$CF" tools-as | grep -q "$MIGDIR:$IMG_MIGDIR" \
    && ok "tools-as 가 $MIGDIR 를 $IMG_MIGDIR 로 붙인다 (적용이 그 폴더를 읽는다)" \
    || bad "🔴 tools-as 의 drizzle 볼륨이 $MIGDIR 가 아니다 — **적용이 엉뚱한 것을 읽는다**"
  svc_block "$CF" db-app | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-app 에 ports: 가 생겼다 — 사내 전용 원칙을 깬다. 고치지 말고 알리세요" \
    || ok "db-app 에 ports: 가 없다 (DB 는 호스트 포트를 하나도 안 연다)"
  svc_block "$CF" db-auth | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-auth 에 ports: 가 생겼다 — 고치지 말고 알리세요" \
    || ok "db-auth 에 ports: 가 없다"
  while IFS='|' read -r k svc cname port host; do
    [ -n "${k:-}" ] || continue
    svc_block "$CF" "$svc" | grep -q "127.0.0.1:$port:" \
      && ok "$svc 가 127.0.0.1:$port 으로만 열린다" \
      || bad "🔴 $svc 의 포트가 127.0.0.1:$port 이 아니다"
  done <<EOF
$APPS
EOF

  # ── 1-ㅅ. 설정 파일 ─────────────────────────────────────────────────
  step "1-ㅅ. 설정 파일 — 🔴 **이름만** 본다 (값도 길이도 안 찍는다)"
  say "  🔵 이번 범위에 **새로 필요해진 .env 이름은 없다**([설문] 7절)."
  say "     있어야 할 것이 그대로 있는지만 센다 — 누가 덮어썼으면 지금 드러난다."
  say "  🔴 이 PC(dss-deploy)의 nas/env/*.env 를 NAS 로 **올리지 마세요.**"
  for f in $ENV_FILES; do
    [ -f "$ENVD/$f" ] && ok "$f 가 있다" \
      || bad "$f 가 없다: $ENVD/$f — 🔴 없는 env_file 하나면 compose 가 통째로 안 먹는다"
  done
  while IFS='|' read -r f rest; do
    [ -n "${f:-}" ] || continue
    [ -f "$ENVD/$f" ] || { unk "$f 의 이름들을 못 봤다 (파일이 없다)"; continue; }
    v=$(stat -c '%a' "$ENVD/$f" 2>/dev/null)
    [ "$v" = 600 ] || bad "🔴 $f 의 모드가 ${v:-?} 다 (600 이어야 한다 — 남이 읽는다)"
    for k in $rest; do
      n=$(env_count_of "$ENVD/$f" "$k")
      if [ "${n:-0}" = 1 ]; then
        ok "$f · $k 가 1줄 있다"
      elif [ "${n:-0}" = 0 ]; then
        bad "🔴 $f · $k 가 **없다**"
      else
        bad "🔴 $f · $k 가 ${n}줄이다 — .env 는 **나중 것이 이긴다.** 조용히 어긋난다"
      fi
    done
  done <<EOF
$ENV_CHECK
EOF

  # ── 1-ㅇ. 백업 · 디스크 · 메모리 ────────────────────────────────────
  step "1-ㅇ. 야간 백업 **일곱** · 디스크 · 메모리"
  say "  🔴 이번 판은 **DB 셋을 바꾼다.** --migrate 는 오늘 뜬 백업이 없으면"
  say "     **시작조차 않는다.** 야간 백업은 **02:30** 이다."
  say "  최근 백업 열:"
  ls -lt "$BKDB/" 2>/dev/null | head -10 | sed 's/^/      /'
  n=0
  for db in $BK_DBS; do
    f=$(ls -1t "$BKDB/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      ok "오늘 백업 $db ($(du -h "$f" | cut -f1))"
      n=$((n + 1))
    else
      bad "오늘($TODAY) 뜬 $db 백업이 없다"
    fi
  done
  if [ "$n" = 7 ]; then
    ok "🔴 오늘 백업이 **일곱**이다 — 야간 백업이 실제로 돌았다"
  else
    bad "🔴 오늘 백업이 ${n}개뿐이다 (일곱이어야 한다)"
    say "    → 손으로 한 번 (종료 코드 0 이어야 한다):"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  fi
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  if [ "${FREE_KB:-0}" -ge 5000000 ] 2>/dev/null; then
    ok "디스크 여유 $FREE_H  (tar 열 + 실은 이미지 열이 들어가야 한다)"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 — 올리기 전에 옛 tar 를 치우세요"
  fi
  MEM=$(free -m 2>/dev/null | awk '/^Mem:/ {print $NF}')
  if isnum "${MEM:-}" && [ "$MEM" -ge 1500 ]; then
    ok "쓸 수 있는 메모리 ${MEM}MB"
  elif isnum "${MEM:-}"; then
    bad "쓸 수 있는 메모리 ${MEM}MB — 여덟을 한 번에 갈기엔 빠듯하다"
  else
    unk "쓸 수 있는 메모리를 못 쟀다"
  fi

  # ── 1-ㅈ. 지금 도는 것 ──────────────────────────────────────────────
  step "1-ㅈ. 지금 도는 것 — 🔴 안 멈추는 것은 DB 둘뿐이다"
  for f in $KEEP_BOXES; do
    running "$f" && ok "$f 가 돌고 있다 (이 배포에서 **안 멈춘다**)" \
      || bad "$f 가 안 돌고 있다"
  done
  "$DOCKER" ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null | sort | sed 's/^/      /'

  # ── 1-ㅊ. 포털의 새 통로 둘 ─────────────────────────────────────────
  step "1-ㅊ. 🔴 포털의 새 통로 둘 — **지금** 무엇이 오는가"
  say "  🔵 배포 전에는 **404 가 맞다**(1.7 에는 그 통로가 없다 — 2026-10-20 이후"
  say "     커밋이다). 배포 뒤에는 401 이어야 한다. 🔴 아무것도 안 바꾼다 —"
  say "     자격증명이 없으면 맨 첫 문에서 돌아선다(본문도 DB 도 안 건드린다)."
  if compose_apps_done; then
    auth_gate_probe "$AUTH_PATH1" 401
    auth_gate_probe "$AUTH_PATH2" 401
  else
    auth_gate_probe "$AUTH_PATH1" 404
    auth_gate_probe "$AUTH_PATH2" 404
  fi

  # ── 1-ㅋ. 바깥 주소 여덟 ────────────────────────────────────────────
  step "1-ㅋ. 바깥 주소 여덟 (지금 상태를 적어 둔다)"
  while IFS='|' read -r k svc cname port host; do
    [ -n "${k:-}" ] || continue
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$host.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$host.dss21.co.kr → $code" ;;
      *)       bad "https://$host.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
    esac
  done <<EOF
$APPS
EOF

  # ── 1-ㅌ. 표 줄 수 ──────────────────────────────────────────────────
  step "1-ㅌ. 표 줄 수 — 🔵 출처 [없음]. **지금 수를 적어 두고 배포 뒤 견준다**"
  say "  🔴 기대값을 박지 않는다. 줄어들면 안 된다는 것만 안다."
  for f in $AS_COUNT_TABLES; do
    v=$(qnum "$AS_BOX" "$AS_DB" "select count(*) from $f")
    [ -n "$v" ] && say "    dss_as.$f  ${v}줄" || unk "dss_as.$f 줄 수를 못 읽었다"
  done
  for f in $INV_COUNT_TABLES; do
    v=$(qnum "$INV_BOX" "$INV_DB" "select count(*) from $f")
    [ -n "$v" ] && say "    dss_inventory.$f  ${v}줄" || unk "dss_inventory.$f 줄 수를 못 읽었다"
  done
  for f in $AUTH_COUNT_TABLES; do
    v=$(qnum "$AUTH_BOX" "$AUTH_DB" "select count(*) from $f")
    [ -n "$v" ] && say "    dss_auth.$f  ${v}줄" || unk "dss_auth.$f 줄 수를 못 읽었다"
  done
}

# ══ 되돌리기 ═══════════════════════════════════════════════════════════
if [ "$MODE" = rollback ]; then
  echo "DSS 서른한째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     되돌리는 것은 **compose 한 파일과 컨테이너 여덟**이다."
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 **DB 는 되돌리지 않습니다.** 아래 까닭을 먼저 읽으세요.      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     · 포털 0005 · 0006 · 0007 — **표 셋을 더하기만** 했습니다. 옛 포털"
  say "       (1.7)은 그 표를 **모르고도 멀쩡히 돕니다.** 그대로 두는 것이 맞습니다."
  say "     · 재고 0020 ~ 0025 — enum 값과 칸을 **더하기만** 했습니다. 더해진 칸은"
  say "       전부 기본값이 있거나 널을 받습니다. 옛 판(0.2)은 그 칸을 안 적습니다."
  say "       🔴 **ALTER TYPE 으로 더한 enum 값은 PostgreSQL 이 빼 주지 않습니다.**"
  say "          그대로 남습니다 — 해로운 것이 아니라 되돌릴 수 없는 것입니다."
  say "     · A/S 0118 — attachment_category 에 값 하나를 더했습니다. 위와 같습니다."
  say
  step "1. 옛 이미지 아홉이 아직 NAS 에 있는지 먼저 본다"
  while IFS='|' read -r k new old rest; do
    [ -n "${k:-}" ] || continue
    [ -n "${old:-}" ] || continue
    have_img "$old" && ok "$old 있다 ($(img_id "$old" | cut -c1-19)…)" \
      || bad "$old 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"
  done <<EOF
$IMGS
EOF
  step "2. compose 를 사본으로 되돌린다"
  say "  --migrate · --go 가 고치기 **전에** 뜬 사본들이다 (가장 최근 것부터):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -5 | sed 's/^/      /'
  say "  🔴 어느 것으로 돌릴지 고르세요:"
  say "     · --go 만 되돌린다  → --go 가 뜬 사본(가장 최근 것)"
  say "     · 도구 둘까지 되돌린다 → --migrate 가 뜬 사본(그 앞의 것)"
  say "       🔵 도구 둘은 되돌리지 않아도 됩니다 — 평소에 뜨지 않습니다."
  cmd "cd /volume1/dss/deploy"
  cmd "ls -1t ../backups/docker-compose.nas.yml.* | head -3"
  cmd "cp ../backups/docker-compose.nas.yml.<도장> docker-compose.nas.yml"
  cmd "grep -n 'image: dss-' docker-compose.nas.yml"
  say "      → 옛 태그 여덟으로 보여야 합니다."
  step "3. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  say "  🔴 되돌리는 길에서도 **포털이 먼저**다 — 거꾸로 가면 일곱 집이 404 를 본다."
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  while IFS='|' read -r k svc cname port host; do
    [ -n "${k:-}" ] || continue
    cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps $svc"
  done <<EOF
$APPS
EOF
  step "4. 🔴 사람에게 알릴 것"
  say "  · 🔴 포털의 **✕ 지움과 ✓ 확인**이 다시 안 됩니다(통로가 404)."
  say "  · 🔴 A/S → 재고로 가던 **O/H 딱지와 수리 종류**가 다시 안 실립니다."
  say "  · 🔵 그 밖에는 달라지지 않습니다."
  step "5. 지금 상태"
  "$DOCKER" ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null | sort | sed 's/^/      /'
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  ✓ $PASS · ✗ $FAIL · ? $UNK · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  [ "$FAIL" = 0 ] && [ "$UNK" = 0 ] && exit 0
  exit 1
fi

# ══ 여기부터 check · preload · force-load · migrate · go ═══════════════
echo "DSS 서른한째 배포 · $(date '+%F %T')"
echo "  이 파일의 md5: $(md5_of "$0")  ← 개발 PC 의 Get-FileHash 와 같아야 합니다"
echo "  🔴 올라가는 것 **여덟** — 포털 · 재고 · A/S · PO · 게시판 · 휴가 ·"
echo "     계측기 · 개선요청. 도구 둘(포털 도구는 **처음 생긴다**)도 함께."
echo "  🔴 멈추는 것도 **여덟 다.** 안 멈추는 것은 DB 둘뿐입니다."
echo "  🔴 순서: ① 포털 → ② 재고 → ③ A/S → ④ 나머지 다섯"
echo "     ① 포털이 먼저인 까닭 — 일곱 집이 포털의 새 통로 둘을 부릅니다."
echo "        포털이 옛 판이면 전부 404 이고, 거꾸로는 아무 일도 안 납니다."
echo "     ② 재고가 A/S 보다 먼저인 까닭 — A/S 가 보내는 O/H 딱지는 신청이"
echo "        서는 그 순간 눕고 **나중에 안 돌아옵니다.**"
echo "  🔴 DB 셋이 바뀝니다 — 포털 5→8 · 재고 20→26 · A/S 118→119"
echo "  🔵 야간 백업은 **02:30** — 자정 넘어 돌리면 백업 검사에 걸립니다"
echo "  🔵 아홉째 사이트(RF 이슈관리) 신설은 **32번**입니다 — 여기 없습니다"
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**"
              echo "     🔵 아직 안 온 것 · 안 실린 것은 ? 다 (✗ 가 아니다)." ;;
  preload)    echo "  🔵 --preload — tar 열을 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  migrate)    echo "  🔴 --migrate — 마이그레이션 **열**(3+6+1). **DB 셋이 바뀐다.**"
              echo "     🔴 compose 의 도구 둘도 고친다(tools-auth 블록 · tools-inventory :3)."
              echo "     🔵 앱은 안 멈춘다 — 직원은 옛 판 여덟을 그대로 쓴다." ;;
  go)         echo "  🔴 --go — compose 여덟 줄을 고치고 컨테이너 여덟을 바꿔 끼운다."
              echo "     🔵 **DB 는 안 바꾼다** — 그것은 --migrate 가 이미 했다."
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(백업 · 마이그레이션)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "tar 열 · 지문"
  while IFS='|' read -r K NEW OLD TARF SZ MD5 CFG; do
    [ -n "${K:-}" ] || continue
    say "  · $NEW"
    V=$(tar_config_id "$IMAGES/$TARF" 2>/dev/null) || V=""
    see_tar "$NEW" "$IMAGES/$TARF" "$V" "$SZ" "$MD5" "$CFG" || true
    if [ -s "$IMAGES/$TARF" ] && [ -n "$V" ]; then
      bring_img "$NEW" "$IMAGES/$TARF" "$V" || true
    else
      bad "$NEW 를 싣지 않았다 — tar 가 없거나 manifest.json 을 못 읽었다"
    fi
  done <<EOF
$IMGS
EOF

  step "🔴 도구 이미지 안의 .sql — 가장 조용한 실패를 여기서 잡는다"
  img_sql_check "$(img_f authtools 2)" "포털 도구" "$IMG_SQL_AUTHTOOLS"
  img_sql_check "$(img_f invtools 2)" "재고 도구" "$IMG_SQL_INVTOOLS"
  img_sql_check "$(img_f as 2)" "A/S 2.9" "$IMG_SQL_AS"
  say "  🔵 재고 앱 이미지 안의 .sql (출처 [없음] — 적어만 둔다):"
  V=$(img_sql_count "$(img_f inventory 2)")
  [ -n "$V" ] && say "    · $(img_f inventory 2) 안 ${V}장" \
    || say "    · 못 읽었다 (이 저장소는 앱 이미지에 drizzle 이 없을 수 있다)"

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  ✓ $PASS · ✗ $FAIL · ? $UNK · **아무것도 멈추지 않았다**"
  if [ "$FAIL" != 0 ] && [ "$FORCE_LOAD" != 1 ]; then
    echo "  🔴 지문이 어긋난 것이 있으면 **같은 태그로 다시 구운 것**이다:"
    echo "       bash $0 --preload --force-load"
  fi
  echo "  🔵 나머지 항목은 안 봤다. 이어서: bash $0        (읽기만)"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  [ "$FAIL" = 0 ] && [ "$UNK" = 0 ] && exit 0
  exit 1
fi

# ══ --migrate — 🔴 **DB 셋이 바뀐다. 앱은 안 멈춘다.** ═════════════════
if [ "$MODE" = migrate ]; then
  running dss-pg-app  || stop "dss-pg-app 이 떠 있지 않습니다. **아무것도 바꾸지 않았습니다.**"
  running dss-pg-auth || stop "dss-pg-auth 가 떠 있지 않습니다. **아무것도 바꾸지 않았습니다.**"

  # ── 1. 🔴 도구 이미지 **셋**이 다 있는가 ────────────────────────────
  step "1. 🔴 적용에 쓸 도구가 다 있는가 (없으면 여기서 멈춘다)"
  MISS=0
  for T in "$(img_f authtools 2)" "$(img_f invtools 2)"; do
    if have_img "$T"; then ok "$T 가 NAS 에 실려 있다"; else bad "🔴 $T 가 **없다**"; MISS=1; fi
  done
  have_img dss-as-tools:1 && ok "dss-as-tools:1 이 있다 (A/S 는 도구를 안 바꾼다)" \
    || { bad "🔴 dss-as-tools:1 이 없다"; MISS=1; }
  if [ "$MISS" != 0 ]; then
    say "  🔴 포털 도구가 없으면 **포털 마이그레이션을 돌릴 길이 없습니다.**"
    say "     🔵 tar 는 개발 PC 의 _images-31 에 있습니다(2026-10-22 17:10 실측)."
    cmd "cd C:\\Users\\희만\\Desktop\\Development\\_images-31"
    cmd "docker save dss-auth-tools:1 -o dss-auth-tools-1.tar"
    cmd "scp -O dss-auth-tools-1.tar dss-nas:/volume1/dss/images/"
    say "  그 뒤 NAS 에서:"
    cmd "bash $0 --preload"
    stop "**DB 도 compose 도 앱도 그대로입니다.**"
  fi
  img_sql_check "$(img_f authtools 2)" "포털 도구" "$IMG_SQL_AUTHTOOLS" || MISS=1
  img_sql_check "$(img_f invtools 2)" "재고 도구" "$IMG_SQL_INVTOOLS" || MISS=1
  [ "$MISS" = 0 ] || stop "도구 이미지 안이 기대한 모습이 아닙니다. **DB 도 앱도 그대로입니다.**"

  # ── 2. 🔴 오늘 백업을 지금 다시 찾는다 ──────────────────────────────
  #
  # 🔴 --check 에서 봤다는 것으로는 부족하다 — 그 뒤에 지워졌을 수 있고, 무엇보다
  #    --check 를 안 돌리고 바로 여기로 올 수 있다. 🔴 스크립트가 대신 뜨지 않는다.
  step "2. 🔴 오늘 백업을 **지금 다시** 찾는다 (바뀌는 DB 셋은 꼭 있어야 한다)"
  NBK=0
  for DB in $BK_DBS; do
    F=$(ls -1t "$BKDB/${DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$F" ] && [ -s "$F" ]; then
      ok "오늘 백업 $DB ($(du -h "$F" | cut -f1))"; NBK=$((NBK + 1))
    else
      bad "오늘($TODAY) 뜬 $DB 백업이 없다"
    fi
  done
  if [ "$NBK" != 7 ]; then
    say "  ╔══════════════════════════════════════════════════════════════╗"
    say "  ║ 🔴 오늘 백업이 ${NBK}개뿐입니다. 일곱이어야 합니다.                 ║"
    say "  ╚══════════════════════════════════════════════════════════════╝"
    say "     🔵 야간 백업은 **02:30** 입니다 — 자정을 넘겨 돌리면 여기 걸립니다."
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    say "     ✓ 줄이 일곱 찍혀야 합니다. 그 뒤에 다시:"
    cmd "bash $0 --migrate"
    stop "백업 없이 DB 를 바꾸지 않습니다. **DB 도 앱도 그대로입니다.**"
  fi

  # ── 3. 적용 직전 덤프 셋 ────────────────────────────────────────────
  #
  # 🔴 되돌리기의 **기본 수단이 아니다.** 되돌리기는 이미지만 내리고 DB 를 그대로
  #    두는 것이다(--rollback). 이것은 「마이그레이션이 DB 를 깨뜨렸을 때」의
  #    마지막 수단이다.
  step "3. 적용 직전 덤프 **셋** ($AUTH_DB · $INV_DB · $AS_DB)"
  BK=$BKD/predeploy-31-$STAMP
  mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
  for PAIR in "$AUTH_BOX|$AUTH_DB" "$INV_BOX|$INV_DB" "$AS_BOX|$AS_DB"; do
    BOX=${PAIR%%|*}; DB=${PAIR#*|}
    if "$DOCKER" exec "$BOX" sh -c "pg_dump -U \"\$POSTGRES_USER\" -d $DB -Fc" \
         > "$BK/$DB.dump.part" 2>/dev/null \
       && "$DOCKER" exec -i "$BOX" pg_restore -l < "$BK/$DB.dump.part" >/dev/null 2>&1; then
      mv "$BK/$DB.dump.part" "$BK/$DB.dump"
      ok "$DB 덤프 $(du -h "$BK/$DB.dump" | cut -f1)"
    else
      rm -f "$BK/$DB.dump.part"
      bad "$DB 덤프 실패"
      stop "DB 를 바꾸지 않았습니다. **앱도 그대로입니다.**"
    fi
  done
  say "  · 자리: $BK"
  say "  ⚠️ PO 가 **같은 $AS_DB 를 보고 있다** — 덤프 중에 PO 에서 저장한 것은 이"
  say "     덤프에 안 들어갈 수 있다. 그래서 이것은 마지막 수단이고, 되돌리기의"
  say "     기본은 **이미지만 내리고 DB 는 그대로 두는 것**이다."

  # ── 4. 🔴 적용 전 상태를 지금 다시 센다 (로그에 남는다) ─────────────
  step "4. 🔴 적용 **전** 상태를 지금 다시 센다 — 이 출력이 뒤에서 견줄 자리다"
  B_AUTH=$(mig_count "$AUTH_BOX" "$AUTH_DB")
  B_INV=$(mig_count "$INV_BOX" "$INV_DB")
  B_AS=$(mig_count "$AS_BOX" "$AS_DB")
  say "  · 포털 ${B_AUTH:-?} · 재고 ${B_INV:-?} · A/S ${B_AS:-?}"
  [ -n "$B_AUTH" ] && [ -n "$B_INV" ] && [ -n "$B_AS" ] \
    || stop "적용 수를 못 읽었습니다(psql). **DB 는 그대로입니다.**"
  [ "$B_AUTH" = "$AUTH_HAVE" ] || [ "$B_AUTH" = "$AUTH_WANT" ] \
    || stop "포털이 $AUTH_HAVE 도 $AUTH_WANT 도 아닙니다 (${B_AUTH}). **DB 는 그대로입니다.**"
  [ "$B_INV" = "$INV_HAVE" ] || [ "$B_INV" = "$INV_WANT" ] \
    || stop "재고가 $INV_HAVE 도 $INV_WANT 도 아닙니다 (${B_INV}). **DB 는 그대로입니다.**"
  [ "$B_AS" = "$AS_HAVE" ] || [ "$B_AS" = "$AS_WANT" ] \
    || stop "A/S 가 $AS_HAVE 도 $AS_WANT 도 아닙니다 (${B_AS}). **DB 는 그대로입니다.**"
  say "  🔴 줄 수 — 적용 뒤에 **그대로여야** 한다:"
  CNT_BEFORE=""
  for F in $AS_COUNT_TABLES; do
    V=$(qnum "$AS_BOX" "$AS_DB" "select count(*) from $F")
    CNT_BEFORE="$CNT_BEFORE as.$F=${V:-?}"; say "      dss_as.$F ${V:-?}줄"
  done
  for F in $INV_COUNT_TABLES; do
    V=$(qnum "$INV_BOX" "$INV_DB" "select count(*) from $F")
    CNT_BEFORE="$CNT_BEFORE inv.$F=${V:-?}"; say "      dss_inventory.$F ${V:-?}줄"
  done
  for F in $AUTH_COUNT_TABLES; do
    V=$(qnum "$AUTH_BOX" "$AUTH_DB" "select count(*) from $F")
    CNT_BEFORE="$CNT_BEFORE auth.$F=${V:-?}"; say "      dss_auth.$F ${V:-?}줄"
  done
  say "  🔵 그대로여야 하는 넷:"
  for LINE in $KEEP_MIGS; do
    DB=${LINE%%|*}
    V=$(mig_count dss-pg-app "$DB"); say "      $DB ${V:-?}"
  done

  # ── 5. 🔴 A/S 볼륨을 119 로 갈아 끼운다 ─────────────────────────────
  step "5. 🔴 A/S 마이그레이션 볼륨 ($MIGDIR → tools-as 의 $IMG_MIGDIR)"
  say "  🔴 .sql 만으로는 부족하다 — **meta/_journal.json 과 snapshot 까지** 가야"
  say "     한다. _journal.json 이 옛것이면 적용이 **0건으로 조용히 끝난다.**"
  read_migdir
  if [ "$MIG_STATE" = OLD ]; then
    if [ ! -s "$MIGTAR" ]; then
      say "  ╔══════════════════════════════════════════════════════════════╗"
      say "  ║ 🔴 볼륨이 아직 $AS_HAVE 인데 갈아 끼울 묶음이 없습니다.            ║"
      say "  ╚══════════════════════════════════════════════════════════════╝"
      cmd "cd C:\\Users\\희만\\Desktop\\Development\\RF_Service_System"
      cmd "tar -czf ..\\as-migrations.tar.gz drizzle"
      cmd "cd .."
      cmd "scp -O as-migrations.tar.gz dss-nas:$INCOMING/"
      stop "DB 를 바꾸지 않았습니다. **앱도 DB 도 그대로입니다.**"
    fi
    place_migs || stop "DB 를 바꾸지 않았습니다. **앱도 그대로입니다.**"
    read_migdir
  fi
  say "  · 지금 $MIGDIR — .sql ${MIG_N_SQL}장 · tag ${MIG_N_J}줄"
  [ "$MIG_N_SQL" = "$AS_WANT" ] && ok ".sql ${MIG_N_SQL}장" \
    || bad ".sql 이 ${AS_WANT}장이 아니다 (${MIG_N_SQL}장)"
  [ "$MIG_N_J" = "$AS_WANT" ] && ok "_journal.json 의 tag ${MIG_N_J}줄" \
    || bad "_journal.json 의 tag 가 ${AS_WANT}줄이 아니다 — 🔴 적용이 0건으로 끝난다"
  check_new_migs || true
  [ "$FAIL" = 0 ] || stop "마이그레이션 파일이 온전하지 않습니다. **DB 도 앱도 그대로입니다.**"

  # ── 6. 🔴 compose 의 도구 둘 ────────────────────────────────────────
  step "6. 🔴 compose 의 **도구 둘** — tools-auth 블록 · tools-inventory :2 → :3"
  say "  🔵 둘 다 profiles: [tools] 다. 도는 컨테이너는 compose 를 읽지 않으므로"
  say "     **직원이 느끼는 것이 하나도 없다.** up -d 를 부르지 않는다."
  if compose_tools_done; then
    ok "compose 가 **이미 다 고쳐져 있다** — 할 일이 없다"
  else
    edit_compose_tools || stop "compose 를 바꾸지 못했습니다(되돌려 두었습니다). **DB 도 앱도 그대로입니다.**"
  fi

  say
  say "  🔴 이제 DB 를 바꿉니다. 그만두려면 **20초 안에 Ctrl+C**."
  say "     지금 Ctrl+C 하면 DB 는 손대지 않은 채로 남습니다."
  say "     (마이그레이션 파일과 compose 의 도구 둘은 이미 바뀌었지만 그것만으로는"
  say "      아무 일도 일어나지 않습니다 — 읽는 것은 도구뿐이고 그때만 돕니다.)"
  sleep 20

  # ── 7. 🔴 ① 포털 ───────────────────────────────────────────────────
  step "7. 🔴 ① 포털 dss_auth — $AUTH_HAVE → $AUTH_WANT  (0005 · 0006 · 0007)"
  say "  🔵 포털에 마이그레이션이 **처음** 도는 자리다. 지금까지는 돌릴 길이 없었다."
  if [ "$B_AUTH" = "$AUTH_WANT" ]; then
    ok "이미 $AUTH_WANT 이다 — 건너뛴다 (drizzle 은 다시 돌려도 안전하다)"
  else
    compose_cmd run --rm "$AUTH_TOOLS_SVC" npm run db:migrate 2>&1 | sed 's/^/    /'
    RC=${PIPESTATUS[0]}
    if [ "$RC" = 0 ]; then ok "포털 db:migrate 끝 (종료 코드 0)"
    else
      bad "포털 db:migrate 실패 (종료 코드 $RC)"
      say "    ╔══════════════════════════════════════════════════════════════╗"
      say "    ║ 🔵 직원은 아직 옛 판 여덟을 쓰고 있습니다. 안 멈췄습니다.        ║"
      say "    ╚══════════════════════════════════════════════════════════════╝"
      say "    🔴 **새 판을 띄우지 않습니다.** 덤프: $BK"
      stop "재고 · A/S 는 손도 대지 않았습니다."
    fi
  fi
  V=$(mig_count "$AUTH_BOX" "$AUTH_DB")
  [ "${V:-x}" = "$AUTH_WANT" ] && ok "포털 ${V}줄 (전 ${B_AUTH}줄)" \
    || bad "🔴 포털이 ${V:-?}줄이다 (${AUTH_WANT}줄이어야 한다)"
  for F in $AUTH_NEW_TABLES; do
    V=$(table_state "$AUTH_BOX" "$AUTH_DB" "$F")
    [ "$V" = "$F" ] && ok "표 $F 가 **생겼다**" \
      || bad "🔴 표 $F 가 **안 생겼다** (${V:-못 읽음})"
  done

  # ── 8. 🔴 ② 재고 ───────────────────────────────────────────────────
  step "8. 🔴 ② 재고 dss_inventory — $INV_HAVE → $INV_WANT  (0020 ~ 0025)"
  say "  🔴 **ALTER TYPE … ADD VALUE 가 셋**이다(0020 · 0022 · 0023). drizzle 은"
  say "     대기 중인 여섯을 **한 트랜잭션**에 넣는다. 세 파일 다 새 값을 쓰지"
  say "     않으므로(0022 의 CHECK 는 status::text 와 **글자 비교**다) 안전하다."
  if [ "$B_INV" = "$INV_WANT" ]; then
    ok "이미 $INV_WANT 이다 — 건너뛴다"
  else
    compose_cmd run --rm "$INV_TOOLS_SVC" npx tsx scripts/migrate.ts 2>&1 | sed 's/^/    /'
    RC=${PIPESTATUS[0]}
    if [ "$RC" = 0 ]; then ok "재고 마이그레이션 끝 (종료 코드 0)"
    else
      bad "재고 마이그레이션 실패 (종료 코드 $RC)"
      say "    🔴 위 글에 **unsafe use of new value**(55P04)가 있습니까?"
      say "       그렇다면 **한 장씩 끊어 돌릴 길**로 갑니다 — 아래 차례입니다:"
      say "       ㄱ) 도구 이미지에서 목록을 꺼낸다:"
      cmd "cd /volume1/dss/setup/incoming"
      cmd "M=/app/drizzle/meta/_journal.json"
      cmd "/usr/local/bin/docker run --rm dss-inventory-tools:3 \\"
      cmd "  cat \$M > inv-journal.json"
      say "       ㄴ) 그 파일에서 **뒤쪽 entries 를 지워** 0020 까지만 남긴 사본을"
      say "          만들고(inv-journal-20.json), 그것을 덮어씌워 한 번 돌린다:"
      cmd "cd /volume1/dss/deploy"
      cmd "D1=/usr/local/bin/docker; F=docker-compose.nas.yml"
      cmd "J=/volume1/dss/setup/incoming/inv-journal-20.json"
      cmd "\$D1 compose -f \$F --env-file .env.nas --profile tools \\"
      cmd "  run --rm -v \$J:\$M:ro tools-inventory \\"
      cmd "  npx tsx scripts/migrate.ts"
      say "       ㄷ) 0021 · 0022 … 로 늘려 가며 같은 줄을 되풀이한다."
      say "       🔴 **사람이 판단해서 합니다.** 스크립트가 journal 을 깎지 않습니다 —"
      say "          한 글자 어긋나면 drizzle 이 그 뒤를 통째로 건너뜁니다."
      say "    🔵 포털은 이미 $AUTH_WANT 로 올라갔습니다. 되돌릴 필요 없습니다."
      stop "A/S 는 손도 대지 않았습니다. **앱 여덟은 그대로 돕니다.** 덤프: $BK"
    fi
  fi
  V=$(mig_count "$INV_BOX" "$INV_DB")
  [ "${V:-x}" = "$INV_WANT" ] && ok "재고 ${V}줄 (전 ${B_INV}줄)" \
    || bad "🔴 재고가 ${V:-?}줄이다 (${INV_WANT}줄이어야 한다)"

  # ── 9. 🔴 ③ A/S ────────────────────────────────────────────────────
  step "9. 🔴 ③ A/S dss_as — $AS_HAVE → $AS_WANT  (0118)"
  say "  🔴 적용 전 확인 — db:preflight (앱은 아직 옛 판으로 살아 있다)"
  compose_cmd run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | sed 's/^/    /'
  PRC=${PIPESTATUS[0]}
  say "  (종료 코드 $PRC — 기대 0 · 대기 **1건**)"
  if [ "$PRC" != 0 ]; then
    bad "db:preflight 가 0 이 아니다 ($PRC) — 사라질 자료가 있다는 뜻이다"
    say "    → 🔴 0118 에는 그럴 문장이 없다. **다른 것이 섞였다.**"
    stop "A/S 마이그레이션을 시작하지 않았습니다. 앱 여덟은 그대로 돕니다."
  fi
  if [ "$B_AS" = "$AS_WANT" ]; then
    ok "이미 $AS_WANT 이다 — 건너뛴다"
  else
    compose_cmd run --rm "$AS_TOOLS_SVC" npm run db:migrate 2>&1 | sed 's/^/    /'
    RC=${PIPESTATUS[0]}
    if [ "$RC" = 0 ]; then ok "A/S db:migrate 끝 (종료 코드 0)"
    else
      bad "A/S db:migrate 실패 (종료 코드 $RC)"
      say "    🔵 포털과 재고는 이미 올라갔습니다. 앱 여덟은 그대로 돕니다."
      stop "덤프: $BK"
    fi
  fi
  V=$(mig_count "$AS_BOX" "$AS_DB")
  [ "${V:-x}" = "$AS_WANT" ] && ok "A/S ${V}줄 (전 ${B_AS}줄)" \
    || bad "🔴 A/S 가 ${V:-?}줄이다 (${AS_WANT}줄이어야 한다)"
  say "  🔴 적용 뒤 preflight — **대기 0건**이어야 한다:"
  compose_cmd run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | sed 's/^/    /'
  say "  (종료 코드 ${PIPESTATUS[0]})"

  # ── 10. 🔴 흔들리지 않았는가 ────────────────────────────────────────
  step "10. 🔴 건드리지 않기로 한 것이 흔들리지 않았는가 (select 만)"
  for LINE in $KEEP_MIGS; do
    DB=${LINE%%|*}; WANT=${LINE#*|}
    V=$(mig_count dss-pg-app "$DB")
    [ "${V:-x}" = "$WANT" ] && ok "$DB ${V} — 그대로  [설문]" \
      || bad "🔴 $DB 가 ${V:-?} 다 (${WANT} 이어야 한다) — 이 배포가 건드렸다"
  done
  say "  🔴 줄 수가 그대로인가 (하나라도 줄었으면 자료가 사라진 것이다):"
  for F in $AS_COUNT_TABLES; do
    V=$(qnum "$AS_BOX" "$AS_DB" "select count(*) from $F")
    B=$(printf '%s' "$CNT_BEFORE" | tr ' ' '\n' | sed -n "s/^as\\.$F=//p")
    [ "${V:-x}" = "${B:-y}" ] && ok "dss_as.$F ${V}줄 — 그대로" \
      || bad "🔴 dss_as.$F 가 ${B:-?} → ${V:-?} 로 **달라졌다**"
  done
  for F in $INV_COUNT_TABLES; do
    V=$(qnum "$INV_BOX" "$INV_DB" "select count(*) from $F")
    B=$(printf '%s' "$CNT_BEFORE" | tr ' ' '\n' | sed -n "s/^inv\\.$F=//p")
    [ "${V:-x}" = "${B:-y}" ] && ok "dss_inventory.$F ${V}줄 — 그대로" \
      || bad "🔴 dss_inventory.$F 가 ${B:-?} → ${V:-?} 로 **달라졌다**"
  done
  for F in $AUTH_COUNT_TABLES; do
    V=$(qnum "$AUTH_BOX" "$AUTH_DB" "select count(*) from $F")
    B=$(printf '%s' "$CNT_BEFORE" | tr ' ' '\n' | sed -n "s/^auth\\.$F=//p")
    [ "${V:-x}" = "${B:-y}" ] && ok "dss_auth.$F ${V}줄 — 그대로" \
      || bad "🔴 dss_auth.$F 가 ${B:-?} → ${V:-?} 로 **달라졌다**"
  done
  say "  🔴 앱 여덟이 **여전히 옛 판으로 돌고 있는가** (--go 가 아직 안 돌았다):"
  "$DOCKER" ps --format '{{.Names}}\t{{.Image}}' 2>/dev/null | sort | sed 's/^/      /'

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  ✓ $PASS · ✗ $FAIL · ? $UNK"
  echo "  🔴 DB 셋을 바꿨습니다. 여덟 사이트는 **아직 옛 판으로 돌고 있습니다.**"
  echo "     포털 ${B_AUTH} → $(mig_count "$AUTH_BOX" "$AUTH_DB")"
  echo "     재고 ${B_INV} → $(mig_count "$INV_BOX" "$INV_DB")"
  echo "     A/S  ${B_AS} → $(mig_count "$AS_BOX" "$AS_DB")"
  echo "  🔴 compose 의 도구 둘도 고쳤습니다 (사본: ${CF_BK:-없음})"
  echo "  덤프: $BK"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  if [ "$FAIL" != 0 ]; then
    echo
    echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
    echo "🔵 마이그레이션은 **다시 돌려도 안전합니다**:  bash $0 --migrate"
    exit "$FAIL"
  fi
  echo
  echo "✅ 이어서 (⏱ 여기부터가 정지 창입니다):"
  echo "     bash $0 --go"
  [ "$UNK" = 0 ] && exit 0
  exit 1
fi

# ══ 1. 먼저 볼 것 ══════════════════════════════════════════════════════
#
# 🔴 규칙 하나: **앱을 멈추기 전에 볼 것을 다 보고, 어긋나면 앱이 살아 있는 채로
#    멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
step "1. 점검표를 기계로 옮긴 것 (앱은 살아 있다 · DB 는 손도 안 댄다)"
run_checks

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  ✓ $PASS · ✗ $FAIL · ? $UNK · **아무것도 바꾸지 않았습니다**"
  if [ "$FAIL" = 0 ]; then
    if [ "$UNK" != 0 ]; then
      echo "  🔵 ? 가 ${UNK}개 있습니다 — **아직 안 온 것 · 안 실린 것**입니다."
      echo "     올리기 전에는 이것이 정상입니다. 올리고 --preload 한 뒤 다시 보세요."
    fi
    if [ "${MIG_AS_NOW:-}" = "$AS_WANT" ] && [ "${MIG_AUTH_NOW:-}" = "$AUTH_WANT" ] \
       && [ "${MIG_INV_NOW:-}" = "$INV_WANT" ]; then
      echo "  ✅ 마이그레이션은 이미 끝났습니다. 이어서:"
      echo "       bash $0 --go"
    else
      echo "  ✅ 이어서 — 🔴 **--migrate 가 먼저입니다** (DB 셋이 바뀝니다):"
      echo "       bash $0 --preload     ← 아직 안 실었으면"
      echo "       bash $0 --migrate"
      echo "       bash $0 --go"
    fi
    echo "     🔴 --migrate 도 --go 도 오늘 백업 일곱이 없으면 멈춥니다."
    echo "     🔵 야간 백업은 02:30 입니다 — 먼저 손으로 뜨려면:"
    echo "          bash /volume1/dss/jobs/backup-nightly.sh"
  else
    echo "  ✗ 위 ✗ 를 먼저 해결하세요. Claude 에게 알려 주세요."
    echo "    🔵 「아직 안 온 것 · 안 실린 것」은 ? 지 ✗ 가 아닙니다."
    echo "    🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 오늘 이 묶음에서"
    echo "       검사가 틀린 경우가 여섯 있었습니다."
  fi
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  [ "$FAIL" = 0 ] && [ "$UNK" = 0 ] && exit 0
  exit 1
fi

# ══ --go ═══════════════════════════════════════════════════════════════
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 바꾸지 않았고 앱 여덟은 살아 있습니다.**"

# ── 2. 🔴 --migrate 가 끝났는지 **여기서 막는다** ─────────────────────
#
# 🔴 왜 막는가: 마이그레이션이 덜 된 DB 에 새 판이 뜨면 **없는 표·없는 칸**을
#    읽다 그 자리에서 죽는다. --migrate 는 따로 부르는 명령이라 **빠뜨릴 수 있다.**
#    명령은 나눠 두고 순서만 기계가 지킨다(27 · 28 · 30번의 그 규율).
step "2. 🔴 --migrate 가 끝났는지 **다시 센다** (바꿔 끼우기 전에)"
G_AUTH=$(mig_count "$AUTH_BOX" "$AUTH_DB")
G_INV=$(mig_count "$INV_BOX" "$INV_DB")
G_AS=$(mig_count "$AS_BOX" "$AS_DB")
say "  · 포털 ${G_AUTH:-?} · 재고 ${G_INV:-?} · A/S ${G_AS:-?}"
GOK=1
[ "${G_AUTH:-x}" = "$AUTH_WANT" ] || GOK=0
[ "${G_INV:-x}" = "$INV_WANT" ] || GOK=0
[ "${G_AS:-x}" = "$AS_WANT" ] || GOK=0
for F in $AUTH_NEW_TABLES; do
  V=$(table_state "$AUTH_BOX" "$AUTH_DB" "$F")
  [ "$V" = "$F" ] && ok "포털 표 $F 가 있다" || { bad "🔴 포털 표 $F 가 **없다**"; GOK=0; }
done
if [ "$GOK" != 1 ]; then
  say "  ✗ 마이그레이션이 아직 끝나지 않았습니다 (기대 $AUTH_WANT · $INV_WANT · $AS_WANT)"
  say "    🔴 새 판은 **없는 표·없는 칸을 읽습니다.** 띄우지 않습니다."
  cmd "bash $0 --migrate"
  stop "**아무것도 바꾸지 않았고 앱 여덟은 살아 있습니다.**"
fi
ok "마이그레이션이 끝나 있다 (포털 $G_AUTH · 재고 $G_INV · A/S $G_AS)"

# ── 3. 이미지 열을 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ────────
step "3. 이미지 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
while IFS='|' read -r K NEW OLD TARF SZ MD5 CFG; do
  [ -n "${K:-}" ] || continue
  eval "V=\${EXP_$K:-}"
  if [ -z "$V" ]; then
    V=$(tar_config_id "$IMAGES/$TARF" 2>/dev/null) || V=""
  fi
  if [ -z "$V" ]; then
    if have_img "$NEW"; then
      ok "$NEW 가 이미 실려 있다 (tar 가 없어 지문은 못 맞췄다)"
      continue
    fi
    stop "$NEW 의 tar 에서 지문을 못 읽었습니다. **아무것도 바꾸지 않았습니다.**"
  fi
  bring_img "$NEW" "$IMAGES/$TARF" "$V" || {
    say "  🔴 $NEW 가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
    stop "교체를 시작하지 않았습니다."
  }
done <<EOF
$IMGS
EOF

# ══ 4. 🔴 멈추기 전에 — 백업 · 설정 사본 · compose ════════════════════
#
# 🔴 여기까지가 「돌이킬 수 있는 자리」다. 앱 여덟은 아직 옛 판으로 **살아 있다.**
step "4-ㄱ. 🔴 오늘 백업을 **지금 다시** 찾는다 (없으면 멈춘다)"
NBK=0
for DB in $BK_DBS; do
  F=$(ls -1t "$BKDB/${DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
  [ -n "$F" ] && [ -s "$F" ] && NBK=$((NBK + 1))
done
if [ "$NBK" = 7 ]; then
  ok "오늘 백업 일곱이 다 있다"
else
  say "  🔴 오늘($TODAY) 뜬 백업이 ${NBK}개뿐입니다."
  say "     🔵 --go 는 DB 를 안 바꿉니다. 그래도 **백업 없이 운영 이미지를 갈아"
  say "        끼우지 않습니다** — 17번에서 이 문이 사고를 막았습니다."
  cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  stop "백업 없이 교체하지 않습니다. **앱도 DB 도 그대로입니다.**"
fi

step "4-ㄴ. 설정 파일 사본 (DB 덤프는 --migrate 가 떴다)"
BK=$BKD/predeploy-go-31-$STAMP
mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
for F in $ENV_FILES; do
  if [ -f "$ENVD/$F" ]; then
    cp -p "$ENVD/$F" "$BK/$F"; chmod 600 "$BK/$F"
  else
    bad "$F 가 없다: $ENVD/$F"
    stop "설정 파일이 없습니다. **앱도 DB 도 그대로입니다.**"
  fi
done
chmod 700 "$BK"
ok "env 여덟의 사본 → $BK (root 700 · 파일 600)"
say "  🔵 이번 판은 설정을 **한 줄도 안 고친다** — 사본은 보험이다."

step "4-ㄷ. 🔴 compose 의 앱 image 줄 **여덟** 고치기 (아무것도 안 뜨고 안 멈춘다)"
if compose_apps_done; then
  ok "compose 가 **이미 다 고쳐져 있다** — 할 일이 없다"
else
  edit_compose_apps || stop "compose 를 바꾸지 못했습니다(되돌려 두었습니다). **앱도 DB 도 그대로입니다.**"
fi

step "4-ㄹ. 건드리지 않는 쪽(DB 둘)의 시작 시각을 적어 둔다"
STARTED_BEFORE=""
for T in $KEEP_BOXES; do
  S=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$T" 2>/dev/null)
  STARTED_BEFORE="$STARTED_BEFORE$T=$S
"
  say "  · $T  시작 ${S:-?}"
done
say
say "  🔴 이제 여덟을 바꿔 끼웁니다. 그만두려면 **20초 안에 Ctrl+C**."
say "     지금 Ctrl+C 하면 직원은 옛 판 여덟을 그대로 쓰고 있습니다."
say "     (compose 는 이미 바뀌었지만 그것만으로는 아무 일도 일어나지 않습니다 —"
say "      옛 컨테이너가 그대로 돌고 있습니다.)"
sleep 20

# ══ 5. 🔴 여기부터 정지 창 — ① 포털 → ② 재고 → ③ A/S → ④ 다섯 ═══════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고 compose 에
#    있는 것을 전부 띄우려 든다. --no-deps 로 **이름을 적은 하나만** 부른다.
# 🔴 한 번에 여럿을 부르지 않는다. 하나씩 올리고 **대답을 받은 뒤** 다음으로 간다.
step "5. 🔴 여덟을 차례로 바꿔 끼운다  ⏱ 여기부터 정지 창"
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"
NTH=0
while IFS='|' read -r K SVC CNAME PORT HOST; do
  [ -n "${K:-}" ] || continue
  NTH=$((NTH + 1))
  say
  say "  ── ${NTH}/8  $SVC ($(img_f "$K" 3) → $(img_f "$K" 2))"
  case "$K" in
    auth)      say "     🔴 포털이 **가장 먼저**다 — 일곱 집이 부를 통로 둘이 여기 있다." ;;
    inventory) say "     🔴 재고가 A/S 보다 먼저다 — O/H 딱지는 신청이 서는 그 순간 눕고"
               say "        나중에 안 돌아온다." ;;
    as)        say "     🔵 그 짝의 보내는 쪽이다. 재고 바로 뒤에 붙여 중간 창을 짧게 한다." ;;
  esac
  compose_cmd up -d --no-deps "$SVC" 2>&1 | sed 's/^/    /'
  wait_http "$SVC" "$PORT" / "$CNAME" || {
    say "    ╔══════════════════════════════════════════════════════════════╗"
    say "    ║ 🔴 $SVC 가 대답하지 않습니다. **뒤의 것을 올리지 않습니다.**      ║"
    say "    ╚══════════════════════════════════════════════════════════════╝"
    say "       되돌리기 안내:  bash $0 --rollback"
    stop "여기까지 ${NTH}개를 갈았습니다. 나머지는 옛 판 그대로입니다."
  }
  V=$("$DOCKER" ps --filter "name=^${CNAME}$" --format '{{.Image}}' 2>/dev/null | head -1)
  [ "$V" = "$(img_f "$K" 2)" ] && ok "$CNAME 가 $V 로 돈다" \
    || bad "🔴 $CNAME 가 $V 로 돈다 (기대 $(img_f "$K" 2))"
  if [ "$K" = auth ]; then
    say "     🔴 뒤의 일곱을 올리기 **전에** 새 통로 둘이 열렸는지 본다:"
    auth_gate_probe "$AUTH_PATH1" 401
    auth_gate_probe "$AUTH_PATH2" 401
    if [ "$FAIL" != 0 ]; then
      say "    ╔══════════════════════════════════════════════════════════════╗"
      say "    ║ 🔴 포털의 새 통로가 기대한 모습이 아닙니다.                     ║"
      say "    ╚══════════════════════════════════════════════════════════════╝"
      say "       🔴 **뒤의 일곱을 올리지 않습니다.** 지금 일곱은 옛 판이라 그"
      say "          통로를 부르지 않습니다 — 직원이 느끼는 것이 없습니다."
      say "       되돌리기 안내:  bash $0 --rollback"
      stop "포털 하나만 갈린 상태입니다."
    fi
  fi
done <<EOF
$APPS
EOF
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → 여덟이 다 대답한 시각 $UP_AT · 약 ${DOWN}초"

# ══ 6. 스모크 ══════════════════════════════════════════════════════════
step "6. 스모크 — 통로 · DB · 안 멈췄는가 · 주소 · 포트"

say "  6-ㄱ. 🔴 포털의 새 통로 둘 (401 이어야 한다)"
auth_gate_probe "$AUTH_PATH1" 401
auth_gate_probe "$AUTH_PATH2" 401

say "  6-ㄴ. 🔴 DB 가 --migrate 뒤로 흔들리지 않았는가 (select 만)"
V=$(mig_count "$AUTH_BOX" "$AUTH_DB")
[ "${V:-x}" = "$AUTH_WANT" ] && ok "포털 ${V}줄 그대로" || bad "🔴 포털이 ${V:-?}줄이다"
V=$(mig_count "$INV_BOX" "$INV_DB")
[ "${V:-x}" = "$INV_WANT" ] && ok "재고 ${V}줄 그대로" || bad "🔴 재고가 ${V:-?}줄이다"
V=$(mig_count "$AS_BOX" "$AS_DB")
[ "${V:-x}" = "$AS_WANT" ] && ok "A/S ${V}줄 그대로" || bad "🔴 A/S 가 ${V:-?}줄이다"
for LINE in $KEEP_MIGS; do
  DB=${LINE%%|*}; WANT=${LINE#*|}
  V=$(mig_count dss-pg-app "$DB")
  [ "${V:-x}" = "$WANT" ] && ok "$DB ${V} — 그대로" \
    || bad "🔴 $DB 가 ${V:-?} 다 (${WANT} 이어야 한다)"
done

say "  6-ㄷ. 🔴 건드리지 않는 DB 둘이 **정말 안 멈췄는가** (시작 시각을 대조한다)"
for T in $KEEP_BOXES; do
  B=$(printf '%s\n' "$STARTED_BEFORE" | sed -n "s/^$T=//p" | head -1)
  A=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$T" 2>/dev/null)
  if [ -n "$B" ] && [ "$B" = "$A" ]; then
    ok "$T · 시작 시각 그대로 — **한 번도 안 멈췄다**"
  else
    bad "🔴 $T 의 시작 시각이 바뀌었다 ($B → $A) — 이 배포가 건드렸다"
  fi
done

say "  6-ㄹ. 바깥 주소 여덟"
while IFS='|' read -r K SVC CNAME PORT HOST; do
  [ -n "${K:-}" ] || continue
  CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$HOST.dss21.co.kr/" 2>/dev/null)
  case "$CODE" in
    2??|3??) ok "https://$HOST.dss21.co.kr → $CODE" ;;
    *)       bad "https://$HOST.dss21.co.kr → ${CODE:-없음} — DNS · DSM 리버스 프록시" ;;
  esac
done <<EOF
$APPS
EOF
say "  열린 포트 (127.0.0.1 만이어야 한다):"
netstat -tln 2>/dev/null | grep ':13[0-9]\{3\}' | sed 's/^/      /'
say "  지금 도는 이미지:"
"$DOCKER" ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null | sort | sed 's/^/      /'

# ══ 7. 마무리 ══════════════════════════════════════════════════════════
rm -rf "$TMPD"
echo
echo "════════════════════════════════════════════════════════════"
echo "  ✓ $PASS · ✗ $FAIL · ? $UNK"
echo "  멈춘 시각 $STOP_AT → $UP_AT · 약 ${DOWN}초"
echo "  바꾼 것 — 이미지 여덟 · compose 여덟 줄"
echo "  🔵 DB 는 --go 가 안 바꿨습니다 (그것은 --migrate 가 이미 했습니다)"
echo "  compose 사본: ${CF_BK:-backups/ 에 있습니다}"
echo "  env 사본: $BK"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" != 0 ]; then
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
  echo "되돌리기 안내:  bash $0 --rollback"
  exit "$FAIL"
fi
cat <<ANNOUNCE

╔════════════════════════════════════════════════════════════════════╗
║ 🔵 **도우미는 다시 깔지 않아도 됩니다.** 이번 판은 도우미를 안 바꿨습니다 ║
╚════════════════════════════════════════════════════════════════════╝

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. 🔴 **포털의 종** — 알림을 ✕ 로 지우고, ✓ 로 확인해 보세요.
      · ✕ 지움은 **로그아웃하면 돌아오고**, ✓ 확인은 **안 돌아옵니다.**
        둘의 수명이 다른 것이 맞습니다.
      · 다른 시스템(A/S · 재고 등)의 종에서도 같은 일이 되는지 보세요.
      🔵 스크립트가 통로 둘이 열린 것은 이미 확인했습니다. 여기서는
         **실제로 업무가 되는지**만 보시면 됩니다.

   2. 🔴 **A/S → 재고** — O/H 템플릿으로 부품을 요청해 보세요.
      재고 쪽 신청에 **O/H 딱지**와 **수리 종류**가 함께 들어와야 합니다.

   3. 🔴 **재고의 승인 절차** — 승인 대리(위임)와 **집행 반려**가 보입니까.
      (0021 · 0022 가 연 것입니다.)

   4. 🔵 PO · 게시판 · 휴가 · 계측기 · 개선요청이 평소처럼 열립니까.

   5. 🔵 **머리말의 ☰ 서랍**(폰 화면) 과 메뉴바가 그대로입니까.

🔴 사람이 이어서 할 일:
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.
  · 내일 아침 백업을 한 번 더 보세요 — **일곱**이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -10
  · 🔵 as-migrations.old 는 **그대로 두세요** — 되돌릴 길입니다.
  · 🔵 아홉째(RF 이슈관리) 신설은 **32번**입니다. 이 배포에 없습니다.

되돌리기 안내:  bash $0 --rollback
  🔴 되돌리면 포털의 ✕ 지움·✓ 확인이 다시 404 가 되고, A/S → 재고의 O/H
     딱지가 다시 안 실립니다. 🔴 **DB 는 되돌리지 않습니다** — 까닭은
     --rollback 이 찍어 줍니다.
ANNOUNCE
[ "$UNK" = 0 ] && exit 0
exit 1
