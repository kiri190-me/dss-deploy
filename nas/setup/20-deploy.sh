#!/bin/bash
# /volume1/dss/setup/20-deploy.sh — 2026-10-08 열여섯째 배포
#
# ── 무엇이 올라가는가 ───────────────────────────────────────────────────
#   사내 사이트 여섯 중 **하나**만 올린다.
#
#     A/S  dss-as:2.2  →  **dss-as:2.3**
#
#   나머지 다섯(포털 1.5 · 계측기 1.3 · 개선요청 0.3 · PO 0.3 · 휴가 0.1)은
#   **건드리지 않는다. 멈추지도 않는다.**
#
#   🔵 **지금까지 중 가장 단순한 배포다.** 19번(열다섯째)을 본으로 베끼고
#      **마이그레이션 일체**와 **새 볼륨 · as.env 덧붙이기**를 걷어냈다.
#      걷어내는 방식은 18번(열넷째, 마이그레이션 0건)을 그대로 따랐다.
#      🔴 17번을 베끼지 않았다 — 그쪽의 「지우는 문장」 잣대
#         (grep -iE 'DROP|DELETE|TRUNCATE')가 외래키의 `ON DELETE restrict` 를
#         오탐해 멀쩡한 판을 거부한다. 이번 판은 그 검사 **자체가 없다**(①).
#
#     | | 값 |
#     | A/S           | 2.2 → **2.3** (커밋 2개 · 전부 A/S)            |
#     | 마이그레이션  | 🔵 **0건** — 운영 DB 는 **115 그대로**        |
#     | 새 볼륨       | **없다**                                      |
#     | as.env        | **변화 없다** — 더할 줄이 하나도 없다         |
#     | 다른 사이트   | **손대지 않는다**                             |
#
# ── 이 판에 무엇이 담겼나 (사람에게 설명할 말로) ────────────────────────
#
#   10/8 아침에 쌓인 커밋 **둘**(1f56947 ~ e8359e8)이고, 담긴 것은 **셋**이다.
#   ⚠️ 커밋은 둘인데 바뀐 일은 셋이다 — 가운데 커밋(c06bc6e)이 ①과 ②를 함께
#      담았다. 지시서의 「커밋 3개」는 **일이 셋**이라는 뜻으로 읽으면 맞다
#      (git rev-list --count 1f56947..e8359e8 → 2 · 2026-10-08 실측).
#
#   ① **[제품 모델 관리] 표의 정렬에 「고객사 오름차순」이 늘었다.**
#      🔵 고르개의 글자는 화면이 아니라 도메인 모듈 한 벌이 정한다
#         (src/lib/domain/product-model-sort.ts).
#      🔴 **고객사 상세의 고르개에는 그 값이 없다** — 거기 모델은 전부 같은
#         고객사의 것이라 고르는 순간 아무것도 안 달라지는 조작이 되기 때문이다.
#         화면이 손으로 거르지 않고 도메인이 내준 제 몫의 목록을 쓴다
#         (CUSTOMER_DETAIL_PRODUCT_MODEL_SORT_KEYS).
#
#   ② **[고객사 관리] 상세의 「연결된 제품 모델」이 접수 기록의 모델까지 보인다.**
#      전에는 사람이 손으로 걸어 둔 연결만 보여 줬다 — 개발 DB 실측으로 수기
#      연결은 6건(고객사 5곳)뿐인데 접수 건으로 이어지는 짝이 132쌍이라,
#      **접수 건이 있는 고객사 32곳 중 27곳이 「없습니다」를 보고 있었다.**
#      줄마다 출처 딱지가 붙는다 — 「직접 연결」 · 「접수 기록」.
#      🔵 조회 한 번으로 두 갈래를 `exists` 로 묻는다(표 구조는 그대로다).
#      🔵 🔴 **DB 스키마가 0 이다.** 읽는 방식만 바뀌었다.
#
#   ③ 🔴 **`.xlsm`(매크로 엑셀)을 점검표 · 파라미터 · 통전검사 분류에서 받는다.**
#      실행 파일 거절 목록(EXECUTABLE_EXTENSIONS)에서 `xlsm` **한 줄만** 뺐다.
#      · 열린 곳은 **형식을 안 가리는 분류 셋**뿐이다(2026-09-30 결정으로
#        `.hwp` · `.dwg` · `.bin` 이 이미 들어가는 자리다).
#      · `xlsm` 을 전체 허용목록 14종에는 **넣지 않았다** — 사진 · 고객 서류 ·
#        견적서처럼 목록이 좁은 분류는 **하나도 안 열렸다.**
#      · 🔴 **매크로 오피스 나머지 아홉은 그대로 거절이다**
#        (xlsb · xlam · xla · docm · dotm · pptm · potm · ppam · sldm).
#      · 🔴 **그때 알고 있던 위험** — 악성코드 검사기가 **아직 없다.** 첨부의
#        malware_scan_status 는 전부 NOT_SCANNED 이고 내려받기를 막지 않는다.
#        앞머리 바이트 대조는 「형식을 속인 파일」까지만 막지 매크로 **안쪽**은
#        보지 않는다. 🔴 **사용자가 그것을 듣고 나서 열기로 정했다**(2026-10-08).
#
#   🔴 **DB 스키마 0 · 설정 0 · 새 권한 0 · 새 볼륨 0.** 순수 코드 교체다.
#
# ══ 🔴 ① 마이그레이션이 **0건**이다 ════════════════════════════════════
#
#   개발 PC 에서 확인했다:
#     git diff --name-only 1f56947..e8359e8 -- drizzle/   → **빈 출력**
#
#   🔴 그러므로 이 스크립트에는 **마이그레이션 코드가 한 줄도 없다.**
#      19번에서 걷어낸 것(18번이 같은 일을 한 그대로다):
#        · N_MIG_HAVE / N_MIG_WANT · MIGDIR · MIGTAR · see_migtar()
#        · as-migrations 폴더 세기 · 묶음(tar.gz) 받아 통째로 갈아 끼우기
#        · drizzle.__drizzle_migrations 줄 수 대조 · 새 표 · 새 칸 · enum 확인
#        · db:preflight (적용 전후) · db:migrate
#        · **적용 직전 pg_dump** · 「마이그레이션 먼저, 코드 나중」 차례
#        · tools-as 의 /app/drizzle 볼륨 검사
#        · 「지우는 문장」 잣대(DESTRUCTIVE_RE) — 17번이 오탐으로 막혔던 그것
#      돌 일이 없는 코드를 운영 절차에 남기지 않는다. 운영 DB 는 **115 그대로**다.
#
#   ⚠️ **배포 전 백업 검사는 그대로 둔다.** 17번에서 그것이 실제로 배포를 막아
#      사고를 피했다(01:00 에 돌렸더니 야간 백업이 02:30 이라 아직 없었다).
#      🔴 **--go 는 오늘 뜬 dss_as 백업이 없으면 시작조차 않는다**(3-ㄱ).
#      DB 를 안 바꾸더라도 그 문은 닫아 두지 않는다.
#
#   🔵 도구 이미지도 **다시 굽지 않았다**(dss-as-tools:1). 17 · 18 · 19번과 같다.
#      이번엔 그 이미지가 할 일 자체가 없다(마이그레이션이 없다).
#
# ══ 🔵 ② 새 볼륨이 **없다** · as.env 에 더할 줄이 **없다** ══════════════
#
#   19번에서 함께 걷어냈다:
#     · probe_new_volume() — 임시 컨테이너로 새 볼륨을 열어 보던 함수
#     · 「자리가 맞는가」 검사(하위 폴더가 보이는가 · 맨 위 칸이 0개인가)
#     · as.env 에 **줄 덧붙이기**(build_env_values · env_line_for · ADDED …)
#
#   🔴 **다만 기존 as.env 줄이 그대로 있는지 보는 부분은 남겼다.**
#      이번 판이 도는 데 필요한 줄이 **열세 줄**이고, 하나라도 사라졌으면
#      배포보다 그것이 먼저다(누가 as.env 를 덮어썼다는 뜻이다):
#        · 견적서 **셋**   QUOTE_ARCHIVE_DIR · _UNC_ROOT · _UNC_ROOT_ALT
#        · 현황표 **다섯** CUSTOMER_PORTAL_ARCHIVE_DIR · _UNC_ROOT ·
#                          _UNC_ROOT_ALT · _FOLDER_PATH · _UNC_PATH
#        · 연락서 **셋**   CONTACT_FOLDER_ARCHIVE_DIR · _UNC_ROOT · _UNC_PATH
#        · 수리관련 **둘** REPAIR_DOCS_ARCHIVE_DIR · _UNC_ROOT
#      ⚠️ 지시서는 「열다섯 줄」이라 적었지만 19번에서 세어 보면 **열셋**이다
#         (3 + 5 + 3 + 2). 이름은 19번의 QUOTE_KEYS · PORTAL_KEYS ·
#         CONTACT_KEYS · ENV_KEYS 를 **글자 그대로** 가져왔다.
#
#   🔴 그리고 19번과 똑같이 지킨다 — **이 PC(dss-deploy)의 nas/env/as.env 를
#      NAS 로 올리지 않는다. 절대로.** 그 사본은 낡아서 위 열세 줄이 없다.
#      이번 판은 as.env 를 **한 글자도 고치지 않는다**(사본만 남긴다 · 3-ㄴ).
#
# ══ 🔴 ③ 야간 백업 시각을 지킨다 — **02:30** ═══════════════════════════
#
#   🔴 **자정을 넘겨 돌리면 백업 검사에 걸린다.** 17번이 01:00 에 돌렸다가
#      실제로 배포가 막혔다 — 그것이 사고를 막았다.
#      늦은 시각에 돌려야 한다면 **먼저 손으로 한 번 뜬다**(종료 코드 0):
#
#        bash /volume1/dss/jobs/backup-nightly.sh
#
#      ✓ dss_as 줄이 찍혀야 한다. 다섯 개가 다 떠야 1-ㅅ 이 통과한다.
#
# ══ ✅ 돌리기 전에 — **값 셋은 이미 쟀다** ═════════════════════════════
#
#   🔵 19번과 다른 점이다 — dss-as:2.3 은 **이미 구워져 있다**
#      (C:\Users\희만\Desktop\Development\dss-as-2.3.tar · 2026-10-08 07:31).
#      아래 세 상수는 그 파일에서 **실제로 재어** 적은 값이다(2026-10-08 실측).
#
#   🔴 **그래도 「비어 있으면 --go 가 시작조차 않는다」는 가드는 그대로 둔다.**
#      값을 적었다고 그 코드를 들어내지 않는다 — 다음 판이 이 파일을 베낄 때
#      빈 값으로 운영에 올라가는 길이 열린다.
#
#   🔵 **다시 구울 일이 생기면** 개발 PC(PowerShell)에서 이 차례다:
#
#     cd C:\Users\희만\Desktop\Development\RF_Service_System
#     git status --short                      ← **비어 있어야 한다**(작업 폴더에서 굽는다)
#     docker build -t dss-as:2.3 .
#     cd ..
#     docker save dss-as:2.3 -o dss-as-2.3.tar
#     (Get-Item dss-as-2.3.tar).Length        ← SZ_AS
#     Get-FileHash -Algorithm MD5 dss-as-2.3.tar   ← MD5_AS (소문자로 적는다)
#     tar -xOf dss-as-2.3.tar manifest.json        ← "Config" 의 sha256 → WANT_CFG_AS
#
#   🔴 **`git archive` 로 뽑지 마라** — 서브모듈 vendor/dss-ui · vendor/dss-core 가
#      **빈 폴더**로 나와 빌드가 깨진다(README 「다음 배포 때」 1번 · runbook/02 10절).
#   🔴 **tar 가 이미지의 1/4 쯤인 것은 정상이다.** 2.2 는 590MB 이미지에 tar 가
#      130,827,264 바이트였다. 크기 차이로 「빌드가 잘못됐나」를 의심할 일이 아니다.
#   🔴 **tar 안 Config 지문은 개발 PC 의 `{{.Id}}` 와 다르다.** 17번이 두 번 겪었다.
#      NAS 는 tar 안의 config 지문을 image ID 로 낸다 — **맞춰 볼 값은 tar 쪽**이다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/20-deploy.sh            ← 읽기만 한다
#
#   🔴 NAS 의 docker 는 **sudo(root)** 가 필요하다. 이 스크립트는 root 가
#      아니면 첫 줄에서 멈춘다.
#
# ══ 🔴 개발 PC → NAS 로 올릴 것 **둘** ═════════════════════════════════
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#      아래는 **개발 PC 의 PowerShell** 에서 친다(NAS 가 아니다).
#
#     scp -O dss-as-2.3.tar dss-nas:/volume1/dss/images/
#     scp -O docker-compose.nas.yml dss-nas:/volume1/dss/setup/incoming/
#
#   🔴 **마이그레이션 묶음은 올릴 것이 없다.** 19번은 셋이었고(이미지 · 묶음 ·
#      compose) 이번은 **둘**이다. as-migrations.tar.gz 를 올리지 마라 —
#      이 스크립트는 그 파일을 쳐다보지도 않는다.
#   🔴 두 번째 줄의 compose 는 **dss-deploy 저장소의 nas/docker-compose.nas.yml**
#      이다(app-as 태그 한 줄만 2.3 으로 올린 그 파일).
#   🔵 scp 가 바로 안 되면 사용자 계정(swhur)의 홈으로 올린 뒤 NAS 에서
#      `sudo mv` 로 옮긴다. /volume1/dss 아래는 root 만 쓸 수 있다.
#
# ══ 🔴 DSM 터미널은 긴 명령을 잘라 먹는다 ══════════════════════════════
#
#   하루에 네 번 깨진 적이 있다. **NAS 에서 돌릴 것은 스크립트 파일로 올리고
#   md5 를 맞춘 뒤** 실행한다. 이 파일 자체가 그렇다:
#
#     (PowerShell)  scp -O nas\setup\20-deploy.sh dss-nas:/volume1/dss/setup/
#     (PowerShell)  Get-FileHash -Algorithm MD5 nas\setup\20-deploy.sh
#     (NAS)         md5sum /volume1/dss/setup/20-deploy.sh
#                   → 두 값이 **같아야** 실행한다. 다르면 다시 올린다.
#
#   그래서 이 스크립트는 사람이 칠 명령을 **한 줄 76자 안쪽**으로만 찍는다.
#   넘으면 그 자리에서 「파일로 만드세요」를 함께 찍는다(cmd 함수).
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
#      컨테이너를 잠깐 띄웠다 지우고(docker run --rm … sh -c 'grep …'),
#      운영 DB 에 **select** 를 몇 번 보낸다(권한 표를 읽는다).
#      디스크에도 DB 에도 아무것도 남기지 않고 도는 사이트를 건드리지도 않지만,
#      「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확한
#      말이다. 13 · 15 · 16 · 17 · 18 · 19번 머리말의 그 문장을 그대로 잇는다.
#   🔵 19번과 달리 **db:preflight 도 안 돌린다** — 돌 일이 없다.
#
# ── 모드 다섯 ───────────────────────────────────────────────────────────
#   (없음) · --check     읽기만 한다. 아무것도 안 바꾸고 안 멈춘다      ← 기본값
#   --preload            새 이미지 하나를 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --go                 🔴 A/S 하나만 교체한다 (DB 도 as.env 도 안 바꾼다)
#   --rollback           되돌리기 안내
#
#   `--force-load` 는 `--go` 와 같이 써도 된다:  bash 20-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 20-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 20-deploy.sh --preload       (새 이미지를 미리 실어 둔다)
#   3) bash 20-deploy.sh                 (다시 읽기만 — 이번엔 지문까지 다 본다)
#   4) bash 20-deploy.sh --go            (A/S 교체 하나뿐이다)
#
# ══ 🔴 ④ 「아직 안 온 것」을 ✗ 로 세지 않는다 (17 · 18 · 19번의 규칙) ══
#
#       **--check 가 ✗ 로 세는 것은 「있는데 어긋난 것」뿐이다.**
#       「아직 안 온 것 · 아직 안 실린 것」은 ⚠️ 로 안내만 한다.
#
#   --check 에서 ⚠️(안내)로 끝나는 자리 셋:
#     · $TAR_AS 가 아직 NAS 에 없다            → ⚠️ 「먼저 scp -O 로 올리세요」
#     · $TAG_AS 가 아직 docker load 안 됐다    → ⚠️ 「--preload 가 싣는다」
#     · 그래서 이미지 **안**을 못 봤다(1-ㅋ)   → ⚠️ 「--preload 뒤에 다시」
#   그리고 ✗ 로 세는 자리:
#     · tar 는 있는데 **바이트·md5·지문이 어긋난다**  → ✗ (옮기다 깨졌다)
#     · 이미지가 **실려 있는데 지문이 tar 와 다르다** → ✗ (--force-load 가 필요)
#     · 이미지 **안이 2.2 의 모습이다**               → ✗ (옛 판을 올린 것)
#
#   🔴 **「아직 안 실린 이미지」는 어느 모드에서도 ✗ 가 아니다**(notloaded).
#      --preload 와 --go 는 2단계에서 **스스로 싣기** 때문이다. 여기서 ✗ 를
#      세면 --go 가 싣기도 전에 자기 검사에 막혀 배포가 아예 불가능해진다.
#
# ══ 🔴 건드리지 않는 아홉 ══════════════════════════════════════════════
#
#     dss-auth:1.5              dss-as-tools:1
#     dss-meters:1.3            dss-meters-tools:1
#     dss-improvements:0.3      dss-improvements-tools:2
#     dss-po:0.3                dss-leave:0.1
#     dss-leave-tools:1
#
#   전부 지금 운영에서 돌고 있다. compose 에서 이 태그가 흔들렸으면 **남의
#   변경이 섞인 것**이다 — 두 세션이 같은 저장소를 쓴다(HANDOFF A절). 실제로
#   일어나는 일이다. 고치지 말고 **먼저 알린다.**
#
#   그리고 「안 멈췄다」를 말로 하지 않는다 — 교체 **전후로** 각 컨테이너의
#   시작 시각(.State.StartedAt)을 적어 두고 **그대로인지** 본다(5-ㅂ).
#
# ══ 15 · 16 · 17 · 18 · 19번에서 그대로 이어받는 것 ════════════════════
#
#   ① 같은 태그로 다시 구운 이미지는 조용히 안 실린다 → --force-load
#   ② 폴더 권한은 **컨테이너 안에서 실제로 열어 본다**(ls -ld 로는 모른다)
#   ③ 이미지는 태그가 아니라 **안을 본다**(1-ㅋ)
#   ④ 사람이 칠 명령은 **한 줄 76자 안쪽**(DSM 의 ash 가 긴 줄을 자른다)
#   ⑤ 공유폴더는 **chmod 로 ACL 을 걷으면 안 된다** — 직원의 탐색기가 끊긴다
#   ⑥ `docker ps` 에 보이는 것과 앱이 **대답하는** 것은 다르다 → wait_http
#   ⑦ compose 는 바꾸기 **전에** 시험하고, 바꾼 것은 backups/ 에 남긴다
#   ⑧ 알림 링크가 **밖에서 닿는 주소**로 나오는가(1-ㅈ · 5-ㄹ)
#   ⑨ 🔴 **권한은 코드가 아니라 운영 DB 가 정한다** — role_permissions 를
#      읽어 보고 말한다(1-ㄷ). 🔴 **select 만 쓴다.**
#      🔵 이번 판은 **새 권한을 하나도 만들지 않았다.** 그래도 세 화면이 기대는
#         칸을 읽어 둔다 — customers.view · productModels.view · repairCases.files.
#   ⑩ 🔴 **공유폴더 넷은 「사라지지 않았는가」만 본다.** 이번 판은 거기에
#      새로 붙이는 것도, 뜻을 바꾸는 것도 없다.
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
AS_ENV=$ENVD/as.env
IMAGES=$D/images
BKD=$D/backups

# ── 🔴 이번에 올라가는 것 **하나** ─────────────────────────────────────
TAG_AS=dss-as:2.3
OLD_AS=dss-as:2.2

# ── 🔴 **건드리지 않는 아홉.** 16 · 17 · 18 · 19번과 같은 아홉이다 ─────
KEEP_AUTH=dss-auth:1.5
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_METERSTOOLS=dss-meters-tools:1
KEEP_IMP=dss-improvements:0.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_PO=dss-po:0.3
KEEP_LEAVE=dss-leave:0.1
KEEP_LEAVETOOLS=dss-leave-tools:1

# ── tar 하나 ───────────────────────────────────────────────────────────
TAR_AS=$IMAGES/dss-as-2.3.tar
# ✅ **이미 구워 재어 둔 값이다**(2026-10-08 07:31 · dss-as-2.3.tar 에서 실측).
#    🔵 2.2 는 tar 130,827,264 였다 — **18,432 바이트** 늘었고 그것이 이 판의
#       코드 양이다. 🔴 이미지(약 590MB)와 tar 가 네 배 넘게 다른 것은 정상이다.
SZ_AS="130845696"
MD5_AS="cff9982d2b64492454708d0b14c98bb6"
WANT_CFG_AS="sha256:973ce1c0de0dfcefc399100e86cda6d0167c00f81062103305303943b48806eb"
# ⚠️ manifest.json 은 그 값을 `blobs/sha256/973ce1c0…` 로 적는다 — 앞의 `blobs/` 를
#    떼고 `sha256:` 를 붙인 모양으로 적는다(17 · 18 · 19번도 같은 모양이었다).
# ⚠️ tar 안의 이 지문은 개발 PC 의 `docker images --format {{.Id}}` 와 **다르다.**
#    17번이 두 번 겪고 적어 둔 그대로다 — 다르다고 놀라지 말 것.

# ── 포트 (compose 의 ports: 에서 읽어 확인했다 — 짐작이 아니다) ────────
#   포털 13100 · A/S 13000 · 계측기 13300 · 개선요청 13500 ·
#   PO 13600 · 휴가 13700
AS_PORT=13000

# ── DB 이름 — 🔴 **백업 검사와 권한 읽기에만 쓴다** ────────────────────
# 🔵 이번 판은 DB 를 **바꾸지 않는다.** 마이그레이션도 덤프도 없다.
AS_DB=dss_as

# ── 권한 — 🔴 읽기만 한다. 출처는 전부 소스다 (1-ㄷ) ──────────────────
#   표·칸   vendor/dss-core/src/schema/role-permissions.ts
#           (표 role_permissions · 칸 role · area_key · level · updated_at.
#            🔴 칸 이름은 leaf_key 가 아니라 **area_key** 다 — 이름이 낡았다)
#   기본값  src/lib/auth/permission-baseline.ts
#             :444 customers.view      → 고객사를 볼 수 있는 역할만 READ
#             :477 productModels.view  → 제품 모델을 볼 수 있는 역할만 READ
#             :482 productModels.files → 모델 파일을 다루는 역할만 WRITE
#             :394 repairCases.files   → 로그인한 사람이면 WRITE
#   🔴 그러므로 표에 줄이 **없으면 위 기본값대로**다. 줄이 있으면 그 값이 이긴다.
#   🔵 이번 판은 **새 권한을 하나도 만들지 않았다** — 바뀐 세 가지가 전부 기존
#      화면 안에서 일어난다. 그래도 읽어 두는 것은, 어느 칸이 NONE 이면 그 사람
#      눈에는 「바뀐 것이 없다」로 보이기 때문이다.
PERM_TABLE=role_permissions
PERM_AREA_CUST=customers.view
PERM_AREA_VIEW=productModels.view
PERM_AREA_FILES=productModels.files
PERM_AREA_CASE=repairCases.files

# ── 컨테이너 안에서 실제로 열어 볼 폴더 ────────────────────────────────
ATT=$D/as-attachments
TEMPLATES=$D/as-templates
UP_IMP=$D/improvements-uploads
MF_METERS=$D/meters-files
# 🔵 **이미 붙어 있는 공유폴더 넷.** 이번에 새로 붙는 것은 **하나도 없다** —
#    도는 2.2 에 넷 다 있다. 여기서는 「사라지지 않았는가」만 본다.
PORTAL_MNT=/customer-portal-archive          # 16번이 붙였다 (현황표)
CONTACT_MNT=/contact-folder-archive          # 18번이 붙였다 (연락서 · 쓰기 가능)
REPAIR_MNT=/repair-docs-archive              # 19번이 붙였다 (수리 관련 · 읽기 전용)
REPAIR_SRC="/volume1/2_AS센터/1. 수리 관련"  # 🔴 `2_AS센터` 의 AS 는 **대문자**다

# ── as.env — 🔴 **읽기만 한다. 한 글자도 안 고친다** ───────────────────
# 🔴 아래 **열세 줄**은 NAS 의 as.env 에만 있고 이 PC 의 사본에는 없다.
#    하나라도 사라졌으면 **배포보다 그것이 먼저다.**
QUOTE_KEYS="QUOTE_ARCHIVE_DIR QUOTE_ARCHIVE_UNC_ROOT QUOTE_ARCHIVE_UNC_ROOT_ALT"
PORTAL_KEYS="CUSTOMER_PORTAL_ARCHIVE_DIR CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT CUSTOMER_PORTAL_ARCHIVE_FOLDER_PATH CUSTOMER_PORTAL_ARCHIVE_UNC_PATH"
CONTACT_KEYS="CONTACT_FOLDER_ARCHIVE_DIR CONTACT_FOLDER_ARCHIVE_UNC_ROOT CONTACT_FOLDER_ARCHIVE_UNC_PATH"
REPAIR_KEYS="REPAIR_DOCS_ARCHIVE_DIR REPAIR_DOCS_ARCHIVE_UNC_ROOT"

# ══ 이미지 **안에서** 찾을 글자 (1-ㅋ) ═════════════════════════════════
#
#  🔴 태그와 지문이 맞아도 「무엇이 든 판인지」는 안을 봐야 안다. 9/21~9/29 에
#     A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다.
#
#  🔴 **19번과 가장 크게 달라진 자리가 여기다.** 19번은 **새로 생긴 파일의
#     모듈 경로**로 가렸다(repair-docs-archive.ts 처럼). 이번 판은 **새 파일이
#     하나도 없다** — 바뀐 다섯 파일이 전부 2.2 에도 있던 파일이다. 그러니
#     경로로는 2.2 와 2.3 을 **못 가린다.** 대신 바뀐 **내용**을 본다.
#
#  🔵 아래 짝은 개발 PC 의 **실제 빌드 산출물**에서 재어 골랐다(2026-10-08 ·
#     .next/standalone/.next 와 .next/static 양쪽). 2.3 쪽 개수와 2.2 쪽 0 을
#     둘 다 확인했다 — 짐작이 아니다.
#
#  🔴 **짝으로 본다**(새 글자 · 옛 글자). 그래서 판정이 셋이다:
#     · 옛 글자가 보이면            → ✗ (이것은 2.2 다)
#     · 새 글자만 보이면            → ✓
#     · 둘 다 안 보이면             → ⚠️ **판정하지 않는다**
#       (압축기가 글자 모양을 바꿨을 수 있다. 그 자리에서 ✗ 를 세면 멀쩡한
#        배포가 막힌다 — 16 · 17번이 그 꼴을 겪었다.)
#
# ① 정렬에 「고객사」가 들어왔다 — 값 목록의 모양이 달라진다
AS_NEW1='MODEL_NAME","KIND","CUSTOMER'   # 2.3: ["MODEL_NAME","KIND","CUSTOMER"]
AS_OLD1='MODEL_NAME","KIND"]'            # 2.2: ["MODEL_NAME","KIND"]
# ② 고객사 상세가 접수 기록까지 본다 — 새 이름 하나와 새 안내 문구 하나
AS_NEW2='CUSTOMER_DETAIL_PRODUCT_MODEL_SORT_KEYS'   # 2.3 에만 있는 이름
AS_NEW2B='A/S 접수 건이 생기면'                     # 2.3 의 「비어 있을 때」 안내
AS_OLD2='연결은 제품 모델 상세의 모델 기본정보에서' # 2.2 의 그 자리 문구
# ③ 🔴 .xlsm 이 거절 목록에서 빠졌다 — 목록의 **이웃 글자**로 가린다
AS_NEW3='dex","xlsb'   # 2.3: … "class","dex","xlsb","xlam", …
AS_OLD3='dex","xlsm'   # 2.2: … "class","dex","xlsm","xlsb", …
# 🔵 2.2 에서 들어온 것이 2.3 에도 그대로 있는가 — **회귀** 표시 둘.
AS_KEEP1='src/lib/storage/repair-docs-archive.ts'
AS_KEEP2='src/components/product-models/KindShareDocsSection.tsx'
AS_CTRL='SSO_REDIRECT_URI'    # 두 판에 다 있는 대조 표시

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 셋. 인자가 없으면 이 셋 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
PROBE_WRITE=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 20-deploy.sh                  읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 20-deploy.sh --check          위와 같습니다
  bash 20-deploy.sh --preload        새 이미지를 싣고 지문만 맞춥니다
  bash 20-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 20-deploy.sh --go             🔴 A/S 하나만 교체합니다
  bash 20-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 20-deploy.sh --rollback       되돌리기 안내

  🔴 --go 가 멈추는 것은 **dss-as 하나**입니다.
     포털 · 계측기 · 개선요청 · PO · 휴가 · DB 는 그대로 돕니다.
  🔵 --go 는 **DB 를 바꾸지 않습니다** — 이번 판은 마이그레이션이 0건입니다.
     🔵 as.env 도 한 글자도 안 고칩니다(사본만 남깁니다).
  🔴 그래도 **그날 백업이 없으면 시작하지 않습니다.** 야간 백업은 02:30 입니다.
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
LOG="$D/setup/logs/20-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11 · 12 · 13 · 15 · 16 · 17 · 18 · 19-deploy.sh 의 것 그대로 ──
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""; DOWN=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# 🔴 머리말 ④ — 「아직 안 온 것」은 --check 에서 ✗ 가 아니다.
#    --preload · --go 는 그것이 **있어야** 도는 모드라 ✗ 로 센다.
missing_is_fatal() { [ "$MODE" != check ]; }
notyet() { # 1 할 말   — 아직 안 **온** 것(사람이 올려야 하는 파일)
  if missing_is_fatal; then bad "$1"; else echo "    ⚠️ $1"; fi
}
notloaded() { # 1 할 말 — 아직 안 **실린** 것. 🔴 어느 모드에서도 ✗ 가 아니다.
  echo "    ⚠️ $1"
}

# 🔴 값 셋이 채워졌는가 — 안 채워졌으면 --go 가 시작하지 않는다.
#    🔵 이번 판은 이미 채워져 있다. 그래도 이 가드를 들어내지 않는다(머리말).
pinned() { [ -n "$SZ_AS" ] && [ -n "$MD5_AS" ] && [ -n "$WANT_CFG_AS" ]; }

# ── ④ 사람이 칠 명령은 76자 안쪽으로만 찍는다 ──────────────────────────
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

running() { "$DOCKER" ps --format '{{.Names}}' | grep -qx "$1"; }
pg_up()   { running dss-pg-app; }

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미 — 🔴 **이 스크립트가 DB 에 보내는 SQL 은 전부 select 다.**
#
#  🔵 19번과 달리 **DB 를 바꾸는 자리가 하나도 없다** — db:migrate 도,
#     pg_dump 도, db:preflight 도 없다. role_permissions 와 attachments 를
#     **읽기만** 한다.
# ══════════════════════════════════════════════════════════════════════
qas()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -Atc \"$1\"" 2>/dev/null; }
qqas() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -c   \"$1\"" 2>/dev/null; }

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 개발 PC 의 `docker image inspect {{.Id}}` 가 아니라 **이 값**이 NAS 에
#    실렸을 때의 image ID 가 된다. 16 · 17 · 18 · 19번의 함수를 그대로 가져왔다.
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
# 🔴 파일 전체를 grep 하면 안 된다 — 주석 줄이 그대로 걸려서 꺼져 있는 서비스를
#    「가리킨다」고 세게 된다(11-deploy.sh 의 그 함정).
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
# 🔴 어떤 줄 **바로 다음 줄**만 뽑는다 (볼륨의 read_only 를 보려고).
#    grep -A1 를 쓰지 않는다 — DSM 의 grep 이 GNU 가 아닐 수 있다. awk 로 한다.
line_after() { # 1 찾을 글자 (본문은 표준입력)
  awk -v pat="$1" 'f { print; f = 0 } index($0, pat) { f = 1 }'
}

# ══════════════════════════════════════════════════════════════════════
#  ② 폴더를 **컨테이너 안에서 실제로 열어 본다**
#
#  🔴 주인(uid)과 모드(755)만 보면 통과하는데 실제로는 EACCES 인 일이 있다.
#     Synology ACL 이 상위에서 내려오면 `ls -ld` 에는 끝의 `+` 하나로만 보이고,
#     `stat -c %u:%g` 는 그것을 아예 안 보여 준다.
#     → 판정은 커널에게 맡긴다. 컨테이너 안에서 `ls` 를 돌려 본다.
#
#  PATHS 는 "경로:모드" 를 빈칸으로 나열한 것이다.
#    ro   읽기만 / rw  읽기+파일 쓰기 / rwd  읽기+파일 쓰기+**폴더 만들기**
#  🔴 쓰기 시험은 PROBE_WRITE=1 (즉 --go) 일 때만 한다.
# ══════════════════════════════════════════════════════════════════════
PROBE_SH='id
for p in $PATHS; do
  d=${p%%:*}; m=${p##*:}
  if ls -1 "$d" >/dev/null 2>&1; then r=READ_OK; else r=READ_FAIL; fi
  w=WRITE_SKIP; k=MKDIR_SKIP
  if [ "$m" = rw ] || [ "$m" = rwd ]; then
    t="$d/.dss-write-test"
    if : > "$t" 2>/dev/null; then w=WRITE_OK; rm -f "$t"; else w=WRITE_FAIL; fi
  fi
  if [ "$m" = rwd ]; then
    g="$d/.dss-dir-test"
    if mkdir "$g" 2>/dev/null; then k=MKDIR_OK; rmdir "$g"; else k=MKDIR_FAIL; fi
  fi
  echo "PROBE $d $r $w $k"
done'

perm_fix_hint() { # 나머지: 호스트 폴더들
  local h
  say "    ╔══════════════════════════════════════════════════════════════╗"
  say "    ║ 🔴 주인·모드로는 통과하는데 **컨테이너가 실제로는 못 연다.**   ║"
  say "    ╚══════════════════════════════════════════════════════════════╝"
  say "    상위 공유폴더의 Synology ACL 을 물려받은 것이다."
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
  say "    🔴 /volume1/3_견적… · /volume1/2_AS센터 같은 **직원이 쓰는 공유폴더에는"
  say "       하지 마라** — 거기서 ACL 을 걷으면 탐색기 접근이 끊긴다."
}

probe_svc() { # 1 서비스 2 컨테이너이름 3 사람이읽을이름 4 "경로:모드 …" 5 "호스트폴더 …"
  local svc="$1" cname="$2" label="$3" paths="$4" hosts="$5"
  local img out how anybad=0 d r w k
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
  while read -r _ d r w k; do
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
    case "$k" in
      MKDIR_OK)   ok "$label · $d 에 폴더를 만들 수 있다" ;;
      MKDIR_SKIP) : ;;
      *)          bad "$label · $d 에 **폴더를 못 만든다**"; anybad=1 ;;
    esac
  done <<EOF
$(printf '%s\n' "$out" | grep '^PROBE ')
EOF
  [ "$anybad" = 0 ] || perm_fix_hint $hosts
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  【이어받은 검사】 알림 링크의 **주소를 실제로 뽑아 본다**
#
#  🔴 2026-09-29 에 「통로가 있다(401 이 온다)」로 통과했는데, 그 통로가 내준
#     링크가 http://172.20.0.7:3500/ 이었다. 문이 있는지가 아니라 **무엇이
#     나오는지**를 봐야 잡힌다. A/S 는 SSO_REDIRECT_URI 에서 자기 주소를 뽑는다
#     (src/lib/config/sso.ts 의 getAppBaseUrl).
#  🔵 이번 판은 알림을 건드리지 않았다 — 기대값도 그대로다.
# ══════════════════════════════════════════════════════════════════════
NOTIFY_CB=/api/auth/sso/callback
href_shape() { # 1 주소  (값을 그대로 찍지 않는다 — 숫자를 N 으로 가린다)
  printf '%s' "$1" | cut -c1-48 | sed 's/[0-9]/N/g'
}
judge_base_url() { # 1 라벨 2 SSO_REDIRECT_URI 원본 3 기대 앞머리
  local label="$1" raw="$2" want="$3" base host
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
notify_href_check() { # 1 라벨 2 컨테이너 3 env파일 4 기대앞머리
  local label="$1" cname="$2" envf="$3" want="$4"
  local raw="" src=""
  say "  $label — 알림 링크가 무엇으로 시작하는지 본다"
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
  judge_base_url "$label" "$raw" "$want"
}

# ══════════════════════════════════════════════════════════════════════
#  이미지 **안에** 이번 판이 들어 있는가 — 🔴 **짝으로** 본다
#
#  🔴 「아직 안 실린 것」은 ✗ 가 아니다(머리말 ④). 못 봤다고 말하고 넘어간다.
#  🔴 대조 표시(AS_CTRL)가 안 나오면 **판정하지 않는다** — 글자를 못 읽은 것과
#     옛 판인 것을 가를 수 없기 때문이다.
# ══════════════════════════════════════════════════════════════════════
pair_judge() { # 1 사람이 읽을 이름 2 새글자있나(0/1) 3 옛글자있나(0/1) 4 새글자 5 옛글자
  local label="$1" n="${2:-0}" o="${3:-0}" pn="$4" po="$5"
  if [ "$o" = 1 ]; then
    bad "🔴 $label — **2.2 의 모습이다**(「$po」 가 아직 보인다). 옛 판을 올린 것이다"
    return 1
  fi
  if [ "$n" = 1 ]; then
    ok "$label — 2.3 의 모습이다 (「$pn」)"
    return 0
  fi
  say "    ⚠️ $label — 새 글자도 옛 글자도 **못 찾았다.** 압축기가 글자 모양을"
  say "       바꿨을 수 있다. 🔴 **판정하지 않는다** — 이 자리는 사람이 화면에서"
  say "       직접 봐야 한다(마무리의 확인 목록)."
  return 0
}

inside_check() { # 1 이미지태그
  local tag="$1" out n1 o1 n2 n2b o2 n3 o3 k1 k2 c
  if ! have_img "$tag"; then
    notloaded "$tag 가 아직 NAS 에 없어 **안을 못 봤다** — 먼저 실으세요"
    cmd "bash $0 --preload"
    return 0
  fi
  # 🔴 글자는 **-e 로 넘긴다.** sh -c 본문에 끼워 넣으면 따옴표가 든 글자
  #    (dex","xlsb)에서 조용히 깨진다. 결과는 한 줄에 0/1 열 개로 받는다.
  out=$("$DOCKER" run --rm \
        -e N1="$AS_NEW1" -e O1="$AS_OLD1" \
        -e N2="$AS_NEW2" -e N2B="$AS_NEW2B" -e O2="$AS_OLD2" \
        -e N3="$AS_NEW3" -e O3="$AS_OLD3" \
        -e K1="$AS_KEEP1" -e K2="$AS_KEEP2" -e C="$AS_CTRL" \
        --entrypoint sh "$tag" -c '
    r=""
    for w in "$N1" "$O1" "$N2" "$N2B" "$O2" "$N3" "$O3" "$K1" "$K2" "$C"; do
      if grep -rlF -- "$w" /app/.next >/dev/null 2>&1; then r="$r 1"; else r="$r 0"; fi
    done
    echo "INSIDE$r"' 2>/dev/null \
    | grep '^INSIDE ' | head -1)
  n1=$(printf  '%s' "$out" | awk '{print $2}')
  o1=$(printf  '%s' "$out" | awk '{print $3}')
  n2=$(printf  '%s' "$out" | awk '{print $4}')
  n2b=$(printf '%s' "$out" | awk '{print $5}')
  o2=$(printf  '%s' "$out" | awk '{print $6}')
  n3=$(printf  '%s' "$out" | awk '{print $7}')
  o3=$(printf  '%s' "$out" | awk '{print $8}')
  k1=$(printf  '%s' "$out" | awk '{print $9}')
  k2=$(printf  '%s' "$out" | awk '{print $10}')
  c=$(printf   '%s' "$out" | awk '{print $11}')
  if [ "${c:-0}" != 1 ]; then
    say "    ⚠️ $tag 안을 글자로 뒤지지 못했다 — 대조 표시($AS_CTRL)도 안 나왔다."
    say "       **판정하지 않는다.** 🔴 이때는 사람이 직접 화면에서 봐야 한다."
    return 0
  fi
  ok "대조 표시($AS_CTRL)를 찾았다 — 안을 실제로 읽었다는 뜻이다"
  pair_judge "① 제품 모델 정렬에 「고객사」" "$n1" "$o1" "$AS_NEW1" "$AS_OLD1"
  pair_judge "② 고객사 상세가 접수 기록까지" "$n2b" "$o2" "$AS_NEW2B" "$AS_OLD2"
  [ "${n2:-0}" = 1 ] \
    && ok "② 고객사 상세 전용 정렬 목록이 들어 있다 ($AS_NEW2)" \
    || say "    ⚠️ $AS_NEW2 를 못 찾았다 — 이름이 압축되며 바뀌었을 수 있다(판정 안 함)"
  pair_judge "③ .xlsm 이 거절 목록에서 빠졌다" "$n3" "$o3" "$AS_NEW3" "$AS_OLD3"
  # 🔵 회귀 — 2.2 에서 들어온 것이 2.3 에도 그대로 있는가
  [ "${k1:-0}" = 1 ] && ok "회귀 — $AS_KEEP1 가 그대로 있다 (2.2 의 「수리 관련」 서류)" \
    || bad "🔴 $AS_KEEP1 가 **사라졌다** — 2.2 보다 **옛 판**을 올린 것이다"
  [ "${k2:-0}" = 1 ] && ok "회귀 — $AS_KEEP2 가 그대로 있다 (2.2 의 가리킨 서류 구역)" \
    || bad "🔴 $AS_KEEP2 가 **사라졌다** — 2.2 보다 **옛 판**을 올린 것이다"
}

# ── 🔴 이미지 안에 글자 인식기(public/ocr)가 들어 있는가 ───────────────
# 🔴 Next 의 standalone 은 public 을 **자동으로 담지 않는다.** Dockerfile 이
#    따로 COPY 하는데, 그 줄이 어긋나면 화면은 뜨고 명판 읽기만 죽는다 —
#    그것도 오류 없이 「인식기를 불러오지 못했습니다」 하나로.
# 🔵 이번 판이 더한 기능은 아니다. **2.2 에 있던 것이 2.3 에도 그대로 있는지**
#    보는 회귀 검사다(2026-10-05 실측 6912KB).
ocr_check() { # 1 이미지태그
  local tag="$1" out a b c s
  if ! have_img "$tag"; then
    notloaded "OCR · $tag 가 아직 NAS 에 없어 못 봤다"
    return 0
  fi
  out=$("$DOCKER" run --rm --entrypoint sh "$tag" -c '
    a=0; b=0; c=0
    [ -f /app/public/ocr/tesseract.min.js ] && a=1
    [ -f /app/public/ocr/worker.min.js ] && b=1
    ls /app/public/ocr/tessdata/*.traineddata.gz >/dev/null 2>&1 && c=1
    s=$(du -sk /app/public/ocr 2>/dev/null | cut -f1)
    echo "OCR $a $b $c ${s:-0}"' 2>/dev/null | grep '^OCR ' | head -1)
  a=$(printf '%s' "$out" | awk '{print $2}')
  b=$(printf '%s' "$out" | awk '{print $3}')
  c=$(printf '%s' "$out" | awk '{print $4}')
  s=$(printf '%s' "$out" | awk '{print $5}')
  [ "${a:-0}" = 1 ] && ok "이미지 안에 tesseract.min.js 가 있다" \
    || bad "이미지 안에 /app/public/ocr/tesseract.min.js 가 **없다**"
  [ "${b:-0}" = 1 ] && ok "이미지 안에 worker.min.js 가 있다" \
    || bad "이미지 안에 /app/public/ocr/worker.min.js 가 **없다**"
  [ "${c:-0}" = 1 ] && ok "이미지 안에 tessdata/*.traineddata.gz 가 있다" \
    || bad "이미지 안에 tessdata 언어 자료가 **없다** — 글자 인식이 안 돈다"
  say "    · /app/public/ocr 크기: ${s:-?} KB (개발 PC 실측 6912KB)"
  if [ "${s:-0}" -lt 5000 ] 2>/dev/null; then
    bad "OCR 폴더가 ${s:-0}KB 뿐이다 — 자료가 덜 담겼다"
  fi
}

# ══════════════════════════════════════════════════════════════════════
#  권한 — 🔴 **읽기만 한다. 어떤 모드에서도 이 표를 고치지 않는다.**
#
#  「권한은 코드가 아니라 운영 DB 가 정한다」(2026-09-30).
#  🔵 이번 판은 **새 권한을 하나도 만들지 않았다.** 그래도 세 가지가 보이려면
#     기존 칸이 열려 있어야 한다:
#    · [제품 모델 관리] 목록의 정렬 → productModels.view
#    · [고객사 관리] 상세의 연결된 제품 모델 → customers.view
#    · 점검표 등에 .xlsm 올리기 → repairCases.files(수리 건) ·
#      productModels.files(모델 · 종류 공통 서류)
#  🔴 표에 줄이 없으면 코드의 기본값대로이고, 줄이 있으면 **저장된 값이 이긴다.**
#  🔴 ✗ 는 세지 않는다 — 배포의 흠이 아니라 설정이다.
# ══════════════════════════════════════════════════════════════════════
PERM_SQL_COUNT="select count(*) from $PERM_TABLE"
PERM_SQL_AREA="select role, area_key, level, updated_at::date from $PERM_TABLE where area_key in ('$PERM_AREA_CUST', '$PERM_AREA_VIEW', '$PERM_AREA_FILES', '$PERM_AREA_CASE') order by area_key, role"

perm_check() {
  local reg n_all n_cust n_view n_files n_case
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
  say
  n_all=$(qas "$PERM_SQL_COUNT")
  say "  · $PERM_TABLE 전체 줄: ${n_all:-?}  (0 이면 전부 코드의 기본 정책대로다)"
  n_cust=$(qas  "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_CUST'")
  n_view=$(qas  "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_VIEW'")
  n_files=$(qas "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_FILES'")
  n_case=$(qas  "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_CASE'")
  say "  · $PERM_AREA_CUST 에 저장된 줄: ${n_cust:-?}"
  say "  · $PERM_AREA_VIEW 에 저장된 줄: ${n_view:-?}"
  say "  · $PERM_AREA_FILES 에 저장된 줄: ${n_files:-?}"
  say "  · $PERM_AREA_CASE 에 저장된 줄: ${n_case:-?}"
  say
  say "  저장된 값 — 역할 전부:"
  qqas "$PERM_SQL_AREA" | sed 's/^/      /'
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔵 이번 판은 **새 권한을 만들지 않았습니다.**                   ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  if [ "${n_cust:-0}" = 0 ] && [ "${n_view:-0}" = 0 ] \
     && [ "${n_files:-0}" = 0 ] && [ "${n_case:-0}" = 0 ]; then
    say "     🔵 네 칸에 **저장된 줄이 하나도 없습니다.** 그러면 코드의 기본값이"
    say "        그대로 삽니다 — 지금 보이던 사람에게 그대로 보입니다."
  else
    say "     🔴 저장된 줄이 있습니다. 위 표를 보세요 — **저장된 값이 코드의"
    say "        기본값을 이깁니다.** 그 칸이 NONE 인 역할에게는"
    say "        · $PERM_AREA_VIEW  — 제품 모델 목록 자체가 안 보입니다(정렬도)"
    say "        · $PERM_AREA_CUST  — 고객사 상세가 안 열립니다(연결된 제품 모델도)"
    say "        · $PERM_AREA_CASE · $PERM_AREA_FILES — 첨부를 못 올립니다"
    say "          (.xlsm 이 열려도 그 사람에게는 달라지는 것이 없습니다)"
  fi
  return 0
}

# ── 🔴 역슬래시가 삼켜졌는가 — UNC 값에 역슬래시가 넷 이상 있어야 맞다 ──
#    16 · 18 · 19번이 이 검사로 잡았다. 🔵 이번 판은 **적지 않고 읽기만** 한다.
backslash_count() { # 1 값 → 개수
  printf '%s' "$1" | tr -cd '\\' | wc -c | tr -d ' '
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)
EXP_AS=""
SVCS=""
AS_DBURL=""; PO_DBURL=""

see_tar() { # 1 태그 2 tar 3 tar에서읽은지문
  local n m
  if [ ! -s "$2" ]; then
    notyet "$1 의 tar 가 아직 NAS 에 없다: $2"
    say "    → 개발 PC(PowerShell)에서 올리세요. 🔴 scp 에 -O 를 붙입니다:"
    say "      (NAS 가 아니라 **개발 PC 의 PowerShell** 에서 칩니다)"
    say "      scp -O dss-as-2.3.tar dss-nas:/volume1/dss/images/"
    return 1
  fi
  n=$(stat -c '%s' "$2" 2>/dev/null)
  m=$(md5sum "$2" 2>/dev/null | awk '{print $1}')
  say "    · 지금 이 tar: 바이트 ${n:-?} · md5 ${m:-?}"
  if ! pinned; then
    say "    ⚠️ 🔴 **기대값 셋이 비어 있다**(SZ_AS · MD5_AS · WANT_CFG_AS)."
    say "       개발 PC 에서 구운 뒤 이 스크립트 머리말의 차례대로 재어 채우세요."
    say "       채우기 전에는 --go 가 시작하지 않습니다."
    [ -n "$3" ] && say "    · 이 tar 안 Config 지문: $3"
    return 0
  fi
  [ "$n" = "$SZ_AS" ] && ok "$1 · 바이트 $n" \
    || bad "$1 의 바이트가 $SZ_AS 가 아니다 ($n) — 옮기다 끊겼다"
  [ "$m" = "$MD5_AS" ] && ok "$1 · md5 $m" \
    || bad "$1 의 md5 가 $MD5_AS 가 아니다 (${m:-못 읽음}) — 파일이 상했다"
  if [ -z "$3" ]; then
    bad "$1 의 tar 에서 manifest.json 을 읽지 못했다: $2"
    return 1
  fi
  if [ "$3" = "$WANT_CFG_AS" ]; then
    ok "$1 · tar 안 Config 지문이 기대값과 같다 ($(echo "$3" | cut -c1-19)…)"
  else
    bad "$1 · tar 안 Config 지문이 기대값과 다르다"
    say "      tar   $3"
    say "      기대  $WANT_CFG_AS"
    say "      🔴 **다른 판을 올린 것**이거나 옮기다 깨진 것이다."
  fi
}

run_checks() {
  local tag s p rec t f db n_bk nlog k n_top
  local FREE_KB FREE_H code h

  # ── 1-ㄱ. 올릴 파일 **하나** — 크기 · md5 · tar 안의 지문 ─────────────
  step "1-ㄱ. 올린 파일 **하나** (이미지 tar. 🔵 마이그레이션 묶음은 없다)"
  say "  🔵 19번은 둘이었다 — 이번 판은 마이그레이션이 **0건**이라 묶음이 없다."
  say "     as-migrations.tar.gz 를 올리지 마세요. 이 스크립트는 안 쳐다봅니다."
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS"

  # ── 1-ㄴ. NAS 에 실린 이미지 ─────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (올라가는 하나 · 건드리지 않는 아홉)"
  if have_img "$TAG_AS"; then
    [ -n "$EXP_AS" ] && { verify_img "$TAG_AS" "$EXP_AS" || force_load_hint "$TAG_AS"; }
  else
    notloaded "$TAG_AS 는 아직 NAS 에 실리지 않았다 — --preload 나 --go 가 싣는다"
  fi
  say "  🔴 지문이 어긋나면 **혼자 고쳐지지 않는다.** 태그가 같으면 docker load 를"
  say "     그냥 부르는 것으로는 안 바뀐다 — 위에 찍힌 --force-load 를 쓰세요."
  say "  🔴 건드리지 않는 아홉 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for tag in "$KEEP_AUTH" "$KEEP_ASTOOLS" "$KEEP_METERS" "$KEEP_METERSTOOLS" \
             "$KEEP_IMP" "$KEEP_IMPTOOLS" "$KEEP_PO" "$KEEP_LEAVE" "$KEEP_LEAVETOOLS"; do
    have_img "$tag" && ok "$tag 실려 있다 ($(img_id "$tag" | cut -c1-19)…)" \
      || bad "$tag 가 NAS 에 없다 — 🔴 앞 배포가 되돌아갔거나 누가 지웠다"
  done
  say "  ⚠️ $KEEP_ASTOOLS 는 **다시 굽지 않았다.** 🔵 이번 판은 그 이미지가 할 일"
  say "     자체가 없다 — 마이그레이션이 0건이다."
  say "  🔴 되돌아간 $OLD_AS 도 그대로 둔다 — 되돌리기가 그것을 쓴다."
  have_img "$OLD_AS" && ok "$OLD_AS 도 아직 있다 (되돌릴 길이 열려 있다)" \
    || say "    ⚠️ $OLD_AS 가 NAS 에 없다 — 되돌리려면 tar 를 다시 올려야 한다"

  # ── 1-ㄷ. 권한 — 🔴 읽기만 한다 ──────────────────────────────────────
  step "1-ㄷ. 바뀐 셋이 **누구 눈에** 보이는가 (운영 DB 를 읽는다)"
  say "  🔴 「권한은 코드가 아니라 운영 DB 가 정한다」 — 그래서 읽어 보고 말한다."
  say "     🔵 이번 판은 **새 권한을 하나도 만들지 않았다.**"
  perm_check

  # ── 1-ㄹ. 🔴 as.env — **읽기만 한다. 더할 줄이 없다** ────────────────
  step "1-ㄹ. as.env (이름만 본다. 🔵 이번 판은 **한 글자도 안 고친다**)"
  say "  🔴 이 PC(dss-deploy)의 nas/env/as.env 를 NAS 로 **올리지 마세요.**"
  say "     그 사본에는 NAS 에만 있는 열세 줄이 빠져 있습니다 — 올리면 견적서 ·"
  say "     현황표 · 연락서 · 수리 관련 기능이 운영에서 통째로 사라집니다."
  say "  🔵 19번은 여기서 두 줄을 **덧붙였다.** 이번 판은 **덧붙일 줄이 없다** —"
  say "     「이미 있는가」만 봅니다."
  if [ -f "$AS_ENV" ]; then
    s=$(stat -c '%a' "$AS_ENV" 2>/dev/null)
    [ "$s" = 600 ] && ok "as.env 있다 · 모드 600" \
      || bad "as.env 의 모드가 ${s:-?} 다 (600 이어야 한다 — 남이 읽는다)"
    s=$(stat -c '%U:%G' "$AS_ENV" 2>/dev/null)
    [ "$s" = "root:root" ] || bad "as.env 의 주인이 ${s:-?} 다 (root:root 이어야 한다)"
    for t in DATABASE_URL UPLOADS_DIR PORT; do
      grep -q "^$t=" "$AS_ENV" && bad "as.env 에 $t 가 **있다** — 지우세요(compose 가 넘긴다)"
    done
    say "  🔴 견적서 세 줄 — 사라지면 [폴더 열기]가 죽는다:"
    for k in $QUOTE_KEYS; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 누가 as.env 를 덮어썼다. 배포보다 이것이 먼저다"
    done
    say "  🔴 현황표 다섯 줄 — 16번이 넣은 것이고 **2.3 도 그대로 쓴다**:"
    for k in $PORTAL_KEYS; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 [공유폴더에 저장]이 실패로 끝난다"
    done
    say "  🔴 연락서 세 줄 — 18번이 넣은 것이고 **2.3 도 그대로 쓴다**:"
    for k in $CONTACT_KEYS; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 연락서 [폴더 열기]가 죽는다"
    done
    say "  🔴 수리 관련 두 줄 — 19번이 넣은 것이고 **2.3 도 그대로 쓴다**:"
    for k in $REPAIR_KEYS; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 「가리킨 서류」 고르는 창이 죽는다"
    done
    if grep -q "^CUSTOMER_LINK_TOKEN_KEY=" "$AS_ENV"; then
      say "  ⚠️ CUSTOMER_LINK_TOKEN_KEY 가 아직 있다 — 2.0 부터 **안 읽는 줄**이다."
      say "     🔴 **지우지 마세요.** 그대로 둬도 아무 일도 일어나지 않습니다."
    fi
    say "  🔵 이번 배포가 as.env 에 적는 줄은 **0 줄**이다. 사본만 남긴다(3-ㄴ)."
  else
    bad "as.env 가 없다: $AS_ENV"
    say "    → 없는 env_file 하나면 docker compose 명령이 **통째로** 안 먹는다."
  fi
  for f in po.env auth.env meters.env improvements.env leave.env; do
    [ -f "$ENVD/$f" ] || bad "$f 가 없다: $ENVD/$f (compose 가 통째로 실패한다)"
  done

  # ── 1-ㅁ. compose — 🔴 **태그 한 줄뿐이다** ─────────────────────────
  step "1-ㅁ. compose ($CF_EFF)"
  say "  🔴 이번 판에서 compose 가 바뀌는 자리는 **하나**다:"
  say "     app-as 의 image 한 줄 ($OLD_AS → $TAG_AS)"
  say "     🔵 19번은 둘이었다(태그 + 새 볼륨 네 줄). 이번엔 **새 볼륨이 없다.**"
  say "     다른 것이 흔들렸으면 남의 것이 섞인 것이다."
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
  say "  올라가는 하나:"
  see_tag app-as "$TAG_AS" "A/S"
  if [ "$(svc_image "$CF_EFF" app-as)" = "$OLD_AS" ]; then
    say "    🔴 compose 가 아직 **옛 태그**($OLD_AS)를 가리킵니다."
    say "       🔵 이번 판은 **태그 한 줄만** 다릅니다. 개발 PC 에서 고친 파일을"
    say "          아래에 올리면 --go 가 시험하고 제자리로 옮깁니다:"
    say "            /volume1/dss/setup/incoming/docker-compose.nas.yml"
  fi
  say "  🔴 건드리지 않는 아홉 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-auth            "$KEEP_AUTH"        "포털 · 그대로"
  see_tag tools-as            "$KEEP_ASTOOLS"     "A/S 도구 · 그대로"
  see_tag app-meters          "$KEEP_METERS"      "계측기 · 그대로"
  see_tag tools-meters        "$KEEP_METERSTOOLS" "계측기 도구 · 그대로"
  see_tag app-improvements    "$KEEP_IMP"         "개선요청 · 그대로"
  see_tag tools-improvements  "$KEEP_IMPTOOLS"    "개선요청 도구 · 그대로"
  see_tag app-po              "$KEEP_PO"          "PO/내자 · 그대로"
  see_tag app-leave           "$KEEP_LEAVE"       "휴가 · 그대로"
  see_tag tools-leave         "$KEEP_LEAVETOOLS"  "휴가 도구 · 그대로"
  # 🔴 볼륨은 **하나도 더하지 않는다.** 「사라지지 않았는가」만 본다.
  say "  🔴 볼륨은 **하나도 더하지 않는다** — 넷이 그대로 있는지만 본다:"
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
      && ok "$s 에 group_add 가 있다 (공유폴더의 ACL 때문이다)" \
      || bad "$s 에 group_add 가 없다 — 🔴 공유폴더에 Permission denied 가 난다"
  done
  svc_block "$CF_EFF" app-as | grep -q "target: $PORTAL_MNT" \
    && ok "app-as 가 현황표 공유폴더($PORTAL_MNT)를 그대로 붙인다 (16번이 붙인 것)" \
    || bad "app-as 에서 $PORTAL_MNT 가 **사라졌다** — 🔴 [공유폴더에 저장]이 죽는다"
  svc_block "$CF_EFF" app-as | grep -q "target: $CONTACT_MNT" \
    && ok "app-as 가 연락서 공유폴더($CONTACT_MNT)를 그대로 붙인다 (18번이 붙인 것)" \
    || bad "app-as 에서 $CONTACT_MNT 가 **사라졌다** — 🔴 연락서 연동이 죽는다"
  # 🔴 연락서는 **쓸 수 있어야** 한다 — 거기에 read_only 가 붙으면 안 된다.
  svc_block "$CF_EFF" app-as | line_after "target: $CONTACT_MNT" | grep -q 'read_only' \
    && bad "🔴 연락서 볼륨에 read_only 가 붙었다 — 폴더 만들기·사본 꽂기가 죽는다" \
    || ok "연락서 볼륨은 그대로 **쓸 수 있다** (read_only 가 없다)"
  svc_block "$CF_EFF" app-as | grep -q "target: $REPAIR_MNT" \
    && ok "app-as 가 「수리 관련」 공유폴더($REPAIR_MNT)를 그대로 붙인다 (19번이 붙인 것)" \
    || bad "app-as 에서 $REPAIR_MNT 가 **사라졌다** — 🔴 가리킨 서류가 통째로 꺼진다"
  # 🔴 「수리 관련」은 **읽기 전용이어야** 맞다 — 19번의 그 결정 그대로다.
  svc_block "$CF_EFF" app-as | line_after "target: $REPAIR_MNT" | grep -q 'read_only: true' \
    && ok "🔴 $REPAIR_MNT 에 read_only: true 가 그대로 있다 (앱이 서류함을 못 고친다)" \
    || bad "🔴 $REPAIR_MNT 의 read_only: true 가 **없어졌다** — 쓰기가 열린 채로 돈다"
  svc_block "$CF_EFF" app-as | grep -qF "source: \"$REPAIR_SRC\"" \
    && ok "「수리 관련」 원본 경로가 글자까지 그대로다 ($REPAIR_SRC)" \
    || bad "원본 경로가 $REPAIR_SRC 가 아니다 — 🔴 대소문자(2_AS센터)부터 보세요"
  svc_block "$CF_EFF" app-as | grep -q "$AS_PORT:3000" \
    && ok "app-as 가 127.0.0.1:$AS_PORT 으로 열린다" \
    || bad "app-as 의 포트가 $AS_PORT:3000 이 아니다"
  # 🔴 사내 전용 원칙 — DB 에 ports: 를 더하지 않는다. 더해졌으면 남의 것이다.
  svc_block "$CF_EFF" db-app | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-app 에 ports: 가 생겼다 — 사내 전용 원칙을 깬다. 고치지 말고 알리세요" \
    || ok "db-app 에 ports: 가 없다 (DB 는 호스트 포트를 하나도 안 연다)"
  svc_block "$CF_EFF" db-auth | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-auth 에 ports: 가 생겼다 — 고치지 말고 알리세요" \
    || ok "db-auth 에 ports: 가 없다"
  AS_DBURL=$(svc_block "$CF_EFF" app-as | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  PO_DBURL=$(svc_block "$CF_EFF" app-po | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  if [ -n "$PO_DBURL" ] && [ "$AS_DBURL" = "$PO_DBURL" ]; then
    ok "app-po 의 DATABASE_URL 이 app-as 와 **글자까지 같다**"
    say "    🔵 둘은 같은 DB 와 같은 첨부 폴더를 쓴다. 이번 판은 **DB 를 안 바꾸므로**"
    say "       PO 에 가는 영향이 없다 — 표도 칸도 그대로다."
    say "    ⚠️ 다만 A/S 에서 올린 .xlsm 첨부가 **PO 화면에도 보인다**(같은 표다)."
    say "       PO(0.3)가 그 파일을 **새로 올릴 수 있는지는 PO 저장소의 목록이**"
    say "       정한다 — 이번 판이 바꾼 것이 아니다."
  else
    bad "app-po 의 DATABASE_URL 이 app-as 와 다르다 — 🔴 PO 가 엉뚱한 DB 를 본다"
  fi

  # ── 1-ㅂ. 폴더를 컨테이너 안에서 **실제로 열어 본다** ────────────────
  step "1-ㅂ. 폴더 — 주인·모드가 아니라 컨테이너 안에서 실제로 연다"
  say "  🔵 이번 배포로 **새로 붙는 자리가 없다** — 넷 다 도는 2.2 에 이미 있다."
  say "     그래서 19번의 probe_new_volume(임시 컨테이너로 새 볼륨 열어 보기)은"
  say "     이 스크립트에 **없다.** 지금 도는 컨테이너 안에서 그대로 본다."
  if [ "$PROBE_WRITE" = 1 ]; then
    say "  (교체되는 A/S 의 /data 는 읽기+쓰기를 본다. 시험 파일은 만들었다 지운다.)"
  else
    say "  🔵 --check 라서 **읽기만** 해 본다 — 아무 파일도 만들지 않는다."
  fi
  if [ -d "$REPAIR_SRC" ]; then
    ok "호스트에 「수리 관련」 폴더가 있다"
    n_top=$(ls -1 "$REPAIR_SRC" 2>/dev/null | wc -l | tr -d ' ')
    say "    · 맨 위 칸의 항목 ${n_top:-?}개"
    if [ "${n_top:-0}" = 0 ]; then
      bad "🔴 **0개다.** 경로가 틀렸다 — 「2_AS센터」 의 AS 가 대문자인지 보세요"
      cmd "ls -d /volume1/2_AS*"
    fi
  else
    bad "호스트에 「수리 관련」 폴더가 **없다**: $REPAIR_SRC"
    cmd "ls -d /volume1/2_AS*"
  fi
  if [ "$PROBE_WRITE" = 1 ]; then M_DATA=rw; else M_DATA=ro; fi
  probe_svc app-as dss-as "A/S" "/data:$M_DATA /templates:ro" "$ATT $TEMPLATES"
  # 🔴 교체 안 되는 곳 — 「아직 읽히는가」만 본다. 쓰기 시험을 하지 않는다.
  probe_svc app-po           dss-po           PO       "/data:ro"         "$ATT"
  probe_svc app-meters       dss-meters       계측기   "/data:ro"         "$MF_METERS"
  probe_svc app-improvements dss-improvements 개선요청 "/data/uploads:ro" "$UP_IMP"
  # 🔴 공유폴더 넷은 위 틀에 안 넣는다 — 경로에 빈칸과 한글이 있고, 무엇보다
  #    여기서는 ACL 을 **걷으면 안 된다**(직원의 탐색기 접근이 끊긴다).
  say "  공유폴더 넷 — 🔴 읽기만 본다. ACL 을 걷지 않는다:"
  for rec in "dss-as|A/S|/quote-archive" "dss-po|PO|/quote-archive" \
             "dss-as|A/S|$PORTAL_MNT" "dss-as|A/S|$CONTACT_MNT" \
             "dss-as|A/S|$REPAIR_MNT"; do
    s=$(printf '%s' "$rec" | cut -d'|' -f1)
    p=$(printf '%s' "$rec" | cut -d'|' -f2)
    t=$(printf '%s' "$rec" | cut -d'|' -f3)
    if running "$s"; then
      "$DOCKER" exec "$s" sh -c "ls -1 '$t' >/dev/null 2>&1" \
        && ok "$p 가 $t 를 읽는다" \
        || { bad "$p 가 $t 를 **못 읽는다**"
             say "      🔴 여기는 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기가 끊긴다."
             say "         compose 의 $s 쪽에 group_add: [\"100\"] 이 있는지부터 보세요."; }
    else
      say "  · $s 가 안 돌고 있어 $t 를 못 봤다"
    fi
  done
  say "  🔵 「수리 관련」에 **쓰기 시험을 하지 않는다** — 읽기 전용으로 붙은 자리라"
  say "     쓰려 들 이유가 없다. 교체 뒤에 **막혀 있는지만** 한 번 본다(5-ㄴ)."

  # ── 1-ㅅ. 🔴 야간 백업 · 야간 완전삭제 (읽기만 한다) ─────────────────
  step "1-ㅅ. 야간 백업 다섯 · 야간 완전삭제 (읽기만 한다)"
  say "  🔵 이번 판은 **DB 를 바꾸지 않는다**(마이그레이션 0건)."
  say "     🔴 그래도 --go 는 오늘 뜬 $AS_DB 백업이 없으면 **시작조차 않는다**(3-ㄱ)."
  say "        17번에서 이 문이 실제로 배포를 막아 사고를 피했다 — 닫아 두지 않는다."
  say "  🔵 야간 백업은 **02:30** 이다 — 자정 넘어 배포하면 여기 걸린다."
  say "  최근 백업 일곱:"
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
    say "    → 손으로 한 번 (종료 코드 0 이어야 한다):"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    say "    🔴 그중 **$AS_DB 가 없으면 --go 는 시작조차 하지 않는다.**"
  fi
  say
  say "  야간 완전삭제 — DSM 작업 「DSS Purge」의 로그:"
  nlog=$(ls -1t "$D/setup/logs"/purge-*.log 2>/dev/null | wc -l | tr -d ' ')
  if [ "${nlog:-0}" -gt 0 ]; then
    ok "완전삭제 로그가 ${nlog}개 있다 — 스케줄러에 등록돼 돌고 있다"
    ls -lt "$D/setup/logs"/purge-*.log 2>/dev/null | head -3 | sed 's/^/      /'
  else
    bad "🔴 완전삭제 로그가 **하나도 없다** — 스케줄러에 등록이 안 된 것이다"
    say "    → 🔴 이 스크립트는 등록하지 않는다. 사람이 DSM 화면에서 합니다:"
    say "      [제어판] → [작업 스케줄러] · 이름 「DSS Purge」 · root · 매일 03:00"
  fi

  # ── 1-ㅇ. 디스크 · DB · 지금 도는 것 ────────────────────────────────
  step "1-ㅇ. 디스크 · DB · 지금 도는 것"
  if pg_up && running dss-pg-auth; then
    ok "DB 둘 다 떠 있다 (이 배포에서 DB 컨테이너는 멈추지 않는다)"
  else
    bad "DB 가 떠 있지 않다"
  fi
  for t in dss-auth dss-as dss-meters dss-improvements dss-po dss-leave; do
    running "$t" && ok "$t 가 돌고 있다" || bad "$t 가 안 돌고 있다"
  done
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  # 새 tar 약 125MB + 실은 이미지 약 590MB + 첨부 하드링크(공간 0).
  # 🔵 19번보다 적게 든다 — 이번엔 **덤프를 뜨지 않는다.**
  if [ "${FREE_KB:-0}" -ge 2000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (새 tar + 실은 이미지가 들어가야 한다)"
  fi

  # ── 1-ㅈ. 알림 링크의 주소 — A/S 만 ─────────────────────────────────
  step "1-ㅈ. 알림 링크의 주소 (통로가 아니라 **나오는 주소**를 본다)"
  say "  🔴 **A/S 하나만 본다.** PO 에는 알림 통로가 아예 없다."
  say "  🔵 이번 판은 알림을 건드리지 않았다 — 기대값도 그대로다."
  notify_href_check "A/S" dss-as "$AS_ENV" "https://as.dss21.co.kr"

  # ── 1-ㅋ. 새 이미지 **안에** 이번 판이 들어 있는가 ───────────────────
  step "1-ㅋ. 새 이미지 안을 본다 (태그만으로는 안심 못 한다)"
  say "  🔴 9/21~9/29 에 A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다."
  say "  🔴 이번 판은 **새 파일이 하나도 없다** — 경로로는 2.2 와 못 가린다."
  say "     그래서 바뀐 **내용**을 짝으로 본다(새 글자 · 옛 글자)."
  if have_img "$TAG_AS"; then
    say "  $TAG_AS 구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_AS" --format '{{.Size}}' 2>/dev/null)"
    say "        ($OLD_AS 는 590MB 였다 — 🔴 **크기로는 못 가른다.** tar 로는 18,432"
    say "         바이트 차이뿐이다.)"
    inside_check "$TAG_AS"
    say "  🔵 글자 인식기(public/ocr) 회귀 검사 — 2.2 의 것이 그대로 있는가:"
    ocr_check "$TAG_AS"
  else
    notloaded "$TAG_AS 가 아직 안 실려 **안을 못 봤다** (머리말 ④ — ✗ 가 아니다)"
    cmd "bash $0 --preload"
  fi

  # ── 1-ㅌ. 바깥 주소 여섯 ────────────────────────────────────────────
  step "1-ㅌ. 바깥 주소 여섯 (지금 상태를 적어 둔다)"
  for h in login as meters improvements po leave; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$h.dss21.co.kr → $code" ;;
      *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
    esac
  done
}

# ══════════════════════════════════════════════════════════════════════
#  compose 갈아 끼우기
#
#  🔴 --check 는 **갈아 끼우지 않는다.** 읽기만 한다는 약속이 먼저다.
#  🔴 바꾸기 **전에** 새 파일을 먼저 시험한다. 없는 env_file 하나면 docker
#     compose 명령이 **통째로** 실패해서, 앱을 멈춘 뒤에 그걸 알게 되면 다시
#     띄우지도 못한다.
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
  # 🔴 이번 판은 **image 한 줄**만 달라야 한다. 더 달라졌으면 남의 것이 섞였다.
  say "  🔵 지금 것과 달라진 줄 (🔴 image 한 줄이어야 한다):"
  diff "$CF" "$INCOMING" 2>/dev/null | sed 's/^/      /' | head -40
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
  echo "DSS 열여섯째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     되돌리는 것은 **이미지 하나**다:  $TAG_AS → $OLD_AS"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔵 DB 는 **되돌릴 것이 없다.** 이번 판은 DB 를 안 바꿨다.       ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     마이그레이션 0건 · 새 표 0 · 새 칸 0. 운영 DB 는 **115 그대로**다."
  say "  🔵 as.env 도 **되돌릴 것이 없다** — 한 줄도 안 더했다."
  say "  🔵 compose 도 **태그 한 줄**만 달라서 sed 로 내려도 안전하다"
  say "     (19번은 볼륨 네 줄이 함께 들어가 사본으로만 되돌려야 했다)."
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 되돌리기 전에 — **`.xlsm` 하나만 알아 두면 된다.**           ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     🔴 2.3 이 도는 동안 점검표 · 파라미터 · 통전검사로 올라간 **.xlsm 은"
  say "        2.2 가 받아들이지 않던 형식**이다."
  say "        · 이미 저장된 파일은 2.2 에서도 **그대로 보이고 내려받힌다**"
  say "          (올리는 통로만 확장자를 보고, 보기·내려받기는 안 본다)."
  say "        · 🔴 다만 **새로 올릴 수는 없다** — 2.2 의 거절 목록에 xlsm 이 있다."
  say "        · 🔴 **지우지 마라.** 다시 2.3 을 올리면 그대로 올릴 수 있게 된다."
  say "     🔵 나머지 둘(제품 모델 정렬 · 고객사 상세의 접수 기록 모델)은 **화면뿐**"
  say "        이다 — 되돌려도 자료가 상하지 않는다. 고르개에서 「고객사 오름차순」이"
  say "        사라지고, 고객사 상세가 다시 **수기 연결만** 보여 줄 뿐이다."
  say
  if pg_up; then
    s=$(qas "select count(*) from attachments where is_deleted = false and lower(original_file_name) like '%.xlsm'")
    say "  · 지금 살아 있는 .xlsm 첨부: ${s:-?}건 (select 다)"
    say "    🔵 0건이면 되돌리기에 걸릴 것이 **아무것도 없다.**"
  else
    say "    · dss-pg-app 이 안 떠 있어 세지 못했다"
  fi

  step "1. 옛 이미지가 아직 NAS 에 있는지 먼저 본다"
  if have_img "$OLD_AS"; then
    ok "$OLD_AS 있다 ($(img_id "$OLD_AS" | cut -c1-19)…)"
  else
    bad "$OLD_AS 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"
  fi

  step "2. compose 를 되돌린다"
  say "  --go 가 옛 compose 를 아래에 남겼다 (가장 최근 것):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -3 | sed 's/^/      /'
  cmd "cd /volume1/dss/deploy"
  cmd "cp \$(ls -1t ../backups/docker-compose.nas.yml.* | head -1) ."
  say "      (파일 이름이 길면 위 한 줄 대신 두 줄로 나눠 치세요)"
  say "  🔵 사본이 없어도 된다 — 이번 판은 **태그 한 줄**뿐이라 이것으로 충분하다:"
  cmd "F=docker-compose.nas.yml"
  cmd "sed -i 's|image: $TAG_AS|image: $OLD_AS|' \$F"
  cmd "grep -n 'image: dss-as' \$F"

  step "3. as.env — 🔵 **되돌릴 것이 없다**"
  say "  이번 판은 as.env 에 **한 줄도 안 더했다.** 그대로 두세요."
  say "  (--go 가 사본은 남겨 둔다 — 기록용이다):"
  ls -1t "$BKD"/as.env.* 2>/dev/null | head -3 | sed 's/^/      /'

  step "4. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-as"
  script_file_hint "20-rollback"

  step "5. 🔴 사람에게 알릴 것"
  say "  · [제품 모델 관리] 정렬에서 **「고객사 오름차순」이 없어진다.**"
  say "  · [고객사 관리] 상세의 「연결된 제품 모델」이 다시 **수기 연결만** 보인다"
  say "    (접수 기록으로 이어진 모델은 안 보일 뿐 **없어지지 않는다** — 그 사실은"
  say "     접수 건 쪽에 그대로 있다. 조회가 계산하던 것이라 지울 자료 자체가 없다)."
  say "  · 🔴 **점검표 · 파라미터 · 통전검사에 .xlsm 을 더는 올릴 수 없다.**"
  say "    이미 올라간 것은 그대로 보이고 내려받힌다 — **지우지 마세요.**"
  say "  · 도우미는 그대로 두세요 — 이번 판은 도우미를 **한 글자도 안 바꿨다.**"

  step "6. 지금 상태"
  say "  dss-as : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep '^dss-as ' || echo '안 돌고 있다')"
  say "  (포털 · 계측기 · 개선요청 · PO · 휴가 · DB 둘은 이번에 건드리지 않았다.)"
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터 check · preload · force-load · go ═════════════════════════
echo "DSS 열여섯째 배포 · 2026-10-08 · $(date '+%F %T')"
echo "  🔴 올라가는 것은 **하나**:  $OLD_AS → $TAG_AS"
echo "  🔴 멈추는 것도 **하나**:  dss-as"
echo "  🔴 이번 판의 셋: 제품 모델 정렬에 **「고객사 오름차순」** ·"
echo "     고객사 상세가 **접수 기록의 모델까지** · 점검표 등에 **.xlsm 허용**"
echo "  🔵 **마이그레이션 0건** — 운영 DB 는 115 그대로 (DB 를 안 건드린다)"
echo "  🔵 **새 볼륨 0** · **as.env 변화 0** · **새 권한 0**"
echo "  🔵 도구 이미지 그대로 ($KEEP_ASTOOLS — 이번엔 할 일 자체가 없다)"
echo "  🔵 야간 백업은 **02:30** — 자정 넘어 돌리면 백업 검사에 걸립니다"
echo "  · 건드리지 않는 아홉 — $KEEP_AUTH · $KEEP_ASTOOLS · $KEEP_METERS"
echo "    · $KEEP_METERSTOOLS · $KEEP_IMP · $KEEP_IMPTOOLS"
echo "    · $KEEP_PO · $KEEP_LEAVE · $KEEP_LEAVETOOLS"
if ! pinned; then
  echo "  ⚠️ 🔴 **이미지 기대값 셋이 비어 있습니다**(SZ_AS · MD5_AS · WANT_CFG_AS)."
  echo "     개발 PC 에서 2.3 을 굽고 재어 채우기 전에는 --go 가 시작하지 않습니다."
  echo "     재는 차례는 이 파일 머리말 「돌리기 전에 — 값 셋은 이미 쟀다」."
fi
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**"
              echo "     🔵 아직 안 온 것 · 안 실린 것은 ⚠️ 로만 말한다(✗ 가 아니다)." ;;
  preload)    echo "  🔵 --preload — 새 이미지를 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — A/S 하나만 교체한다. **DB 도 as.env 도 안 바꾼다.**"
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(폴더 권한 · 백업)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
#    이미지를 싣는 것은 **아무것도 안 멈춘다.**
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "새 이미지 tar · 지문"
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS"
  if [ -s "$TAR_AS" ] && [ -n "$EXP_AS" ]; then
    bring_img "$TAG_AS" "$TAR_AS" "$EXP_AS"
  else
    bad "$TAG_AS 를 싣지 않았다 — tar 가 없거나 manifest.json 을 못 읽었다"
  fi

  # 🔴 실어 놓고 **안을 본다.** 태그와 지문이 맞아도 「무엇이 든 판인지」는
  #    사람이 읽을 수 있는 증거로 한 번 더 남긴다.
  step "새 이미지 안에 이번 판이 들어 있는가 · public/ocr 이 그대로인가"
  if have_img "$TAG_AS"; then
    say "  $TAG_AS 구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
    inside_check "$TAG_AS"
    ocr_check "$TAG_AS"
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
step "1. 점검표를 기계로 옮긴 것 (앱은 살아 있다 · DB 는 손도 안 댄다)"
compose_incoming || stop "compose 를 바꾸지 않았습니다. 앱은 그대로 돕니다."
run_checks

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  if [ "$FAIL" = 0 ]; then
    if pinned; then
      echo "  ✅ 이어서 (A/S 가 잠깐 멈춥니다. DB 는 안 바뀝니다):  bash $0 --go"
      echo "     🔴 --go 는 오늘 백업($AS_DB)이 없으면 **시작하자마자 멈춥니다.**"
      echo "     🔵 야간 백업은 02:30 입니다 — 먼저 손으로 뜨려면:"
      echo "          bash /volume1/dss/jobs/backup-nightly.sh"
    else
      echo "  🔴 아직 --go 를 부를 수 없습니다 — 이미지 기대값 셋이 비어 있습니다."
      echo "     개발 PC 에서 2.3 을 굽고 재어 이 파일에 채운 뒤 다시 올리세요."
    fi
    echo "     🔵 ⚠️ 가 있었다면 아직 안 온 파일이 있다는 뜻입니다 — 올리고"
    echo "        --preload 한 뒤 이 명령을 한 번 더 돌리세요."
  else
    echo "  ✗ 위 ✗ 를 먼저 해결하세요. Claude 에게 알려 주세요."
    echo "    🔵 「아직 안 온 것 · 안 실린 것」은 ✗ 가 아닙니다 — ⚠️ 로 찍혔습니다."
  fi
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ --go ═══════════════════════════════════════════════════════════════
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 바꾸지 않았고 앱은 살아 있습니다.**"
pinned || {
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 이미지 기대값 셋이 **비어 있습니다.** 재지 않은 이미지를      ║"
  say "  ║    운영에 올리지 않습니다.                                     ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     이 파일 머리말 「돌리기 전에」의 차례대로 개발 PC 에서 재어"
  say "     SZ_AS · MD5_AS · WANT_CFG_AS 를 채우고, 이 파일을 다시 올린 뒤"
  say "     (md5 대조) 돌리세요."
  stop "아무것도 바꾸지 않았습니다. 앱도 DB 도 그대로입니다."
}

# ── 2. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ───────────
step "2. 새 이미지 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
[ -n "$EXP_AS" ] || stop "tar 에서 지문을 못 읽었습니다. **아무것도 바꾸지 않았습니다.**"
bring_img "$TAG_AS" "$TAR_AS" "$EXP_AS" || {
  say
  say "  🔴 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
}

# ══ 3. 🔴 멈추기 전에 — 백업 · 스냅숏 · 시작 시각 ══════════════════════
#
# 🔴 여기까지가 「돌이킬 수 있는 자리」다. 앱은 아직 $OLD_AS 로 **살아 있다.**

# ── 3-ㄱ. 🔴 오늘 백업을 **지금 다시** 찾는다. 없으면 멈춘다 ───────────
#
# 🔴 --check 에서 봤다는 것으로는 부족하다 — 그 뒤에 지워졌을 수 있고, 무엇보다
#    --check 를 안 돌리고 바로 여기로 올 수 있다. 🔴 스크립트가 **대신 뜨지 않는다.**
step "3-ㄱ. 🔴 오늘 백업을 **지금 다시** 찾는다 (없으면 여기서 멈춘다)"
BK_TODAY=$(ls -1t "$BKD/db/${AS_DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
if [ -n "$BK_TODAY" ] && [ -s "$BK_TODAY" ]; then
  ok "오늘 백업 — $(basename "$BK_TODAY") ($(du -h "$BK_TODAY" | cut -f1))"
else
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 오늘($TODAY) 뜬 $AS_DB 백업을 **지금 찾지 못했습니다.**      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     🔵 이번 판은 DB 를 바꾸지 않습니다. 그래도 **백업 없이 운영 이미지를"
  say "        갈아 끼우지 않습니다** — 17번에서 이 문이 사고를 막았습니다."
  say "     🔵 야간 백업은 **02:30** 입니다 — 자정을 넘겨 돌리면 여기 걸립니다."
  say "        먼저 이것부터 (종료 코드 0 이어야 합니다):"
  cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  say "     ✓ $AS_DB 줄이 찍혀야 합니다. 그 뒤에 다시:"
  cmd "bash $0 --go"
  stop "백업 없이 교체하지 않습니다. **앱도 DB 도 그대로입니다.**"
fi

# ── 3-ㄴ. 첨부 하드링크 스냅숏 · as.env 사본 ───────────────────────────
#
# 🔵 **DB 덤프는 뜨지 않는다** — 이번 판은 DB 를 바꾸지 않는다(18번과 같다).
#    🔴 19번의 적용 직전 pg_dump 가 여기서 빠진 자리다.
# 🔵 그래도 **첨부 폴더 스냅숏**은 남긴다 — 이번 판이 올리는 파일의 종류를
#    넓혔기 때문이다(.xlsm). cp -al 이라 즉시 끝나고 공간을 쓰지 않는다.
step "3-ㄴ. 첨부 하드링크 스냅숏 · as.env 사본 (DB 덤프는 뜨지 않는다)"
BK=$BKD/predeploy-$STAMP
mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
if [ -d "$ATT" ]; then
  cp -al "$ATT" "$BK/as-attachments" 2>/dev/null \
    && ok "첨부 스냅숏 (cp -al 하드링크 — 즉시 · 공간 0) → $BK" \
    || bad "첨부 스냅숏 실패"
else
  bad "첨부 폴더가 없다: $ATT"
fi
# 🔵 as.env 를 **고치지 않는다.** 사본은 기록으로만 남긴다 — 이 배포 시점의
#    설정이 무엇이었는지 나중에 견줄 수 있어야 한다.
if [ -f "$AS_ENV" ]; then
  cp -p "$AS_ENV" "$BKD/as.env.$STAMP"; chmod 600 "$BKD/as.env.$STAMP"
  ok "as.env 사본 — backups/as.env.$STAMP (root 600) · 🔵 원본은 **안 고친다**"
else
  bad "as.env 가 없다: $AS_ENV"
  stop "설정 파일이 없습니다. **앱도 DB 도 그대로입니다.**"
fi
say "  🔵 공유폴더 넷(견적서 · 현황표 · 연락서 · 수리 관련)은 **스냅숏을 뜨지"
say "     않는다** — 직원의 서류함이라 우리가 사본을 만들 자리가 아니다."
say "     NAS 의 야간 백업이 본다."

# ── 3-ㄷ. 건드리지 않는 쪽의 **시작 시각**을 적어 둔다 ─────────────────
#
# 🔴 「안 멈췄다」를 말로 하지 않는다. 교체 뒤에 이 값과 그대로인지 본다.
step "3-ㄷ. 건드리지 않는 쪽의 시작 시각을 적어 둔다 (뒤에서 대조한다)"
KEEP_BOXES="dss-auth dss-meters dss-improvements dss-po dss-leave dss-pg-app dss-pg-auth"
STARTED_BEFORE=""
for t in $KEEP_BOXES; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  STARTED_BEFORE="$STARTED_BEFORE$t=$s
"
  say "  · $t  시작 ${s:-?}"
done
say
say "  🔴 이제 A/S 를 바꿔 끼웁니다. 그만두려면 **20초 안에 Ctrl+C**."
say "     지금 Ctrl+C 하면 직원은 $OLD_AS 를 그대로 쓰고 있습니다."
say "     (compose 는 이미 바뀌었지만 그것만으로는 아무 일도 일어나지 않습니다 —"
say "      $OLD_AS 가 그대로 돌고 있습니다.)"
sleep 20

# ══ 4. A/S 를 새 판으로 바꿔 끼운다 — 🔴 여기 하나가 정지 창이다 ═══════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다(포털·계측기까지 흔들린다).
#    --no-deps 로 **이름을 적은 하나만** 부른다.
# 🔴 따로 stop 하지 않는다. up -d 가 옛 컨테이너를 지우고 새것을 올리는 한
#    걸음이라, 나눠 부르면 그 사이만큼 정지 창이 길어진다.
step "4. 새 이미지로 바꿔 끼운다 ($OLD_AS → $TAG_AS)  ⏱ 여기부터 정지 창"
say "  🔴 **멈추는 것은 dss-as 하나뿐이다.**"
say "     그대로 도는 것: 포털 · 계측기 · 개선요청 · PO · 휴가 · DB 둘."
say "     즉 https://as.dss21.co.kr 만 몇십 초 대답하지 않는다."
say "  🔵 볼륨은 하나도 안 바뀐다 — 그래도 up -d 로 부른다(이미지가 바뀐다)."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"
"${COMPOSE[@]}" up -d --no-deps app-as 2>&1 | sed 's/^/    /'
wait_http "A/S" "$AS_PORT" / dss-as
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 5. 스모크 ══════════════════════════════════════════════════════════
step "5. 스모크 — 폴더 · 설정 · 알림 · 권한 · 안 멈췄는가 · 바깥 주소"

# 5-ㄱ. 새 컨테이너로 폴더를 **실제로 열어 본다**
say "  5-ㄱ. 폴더를 새 컨테이너 안에서 실제로 연다"
probe_svc app-as dss-as "A/S" "/data:rw /templates:ro" "$ATT $TEMPLATES"

say "  5-ㄴ. 공유폴더 넷 — 🔴 이번 판은 **하나도 안 건드렸다**"
if running dss-as; then
  "$DOCKER" exec dss-as sh -c 'ls -1 /quote-archive >/dev/null 2>&1' \
    && ok "A/S 가 견적서 공유폴더를 읽는다" \
    || { bad "A/S 가 견적서 공유폴더를 **못 읽는다** — 발행이 실패한다"
         say "    🔴 여기는 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기가 끊긴다."; }
  "$DOCKER" exec dss-as sh -c "ls -1 '$PORTAL_MNT' >/dev/null 2>&1" \
    && ok "A/S 가 현황표 공유폴더($PORTAL_MNT)를 읽는다" \
    || bad "A/S 가 $PORTAL_MNT 를 **못 읽는다** — 🔴 [공유폴더에 저장]이 죽는다"
  "$DOCKER" exec dss-as sh -c "ls -1 '$CONTACT_MNT' >/dev/null 2>&1" \
    && ok "A/S 가 연락서 공유폴더($CONTACT_MNT)를 읽는다" \
    || bad "A/S 가 $CONTACT_MNT 를 **못 읽는다** — 🔴 연락서 [폴더 열기]가 죽는다"
  # 🔴 연락서는 **여전히 쓸 수 있어야** 한다 (18번이 연 자리).
  if "$DOCKER" exec dss-as sh -c "t='$CONTACT_MNT/.dss-write-test'; : > \"\$t\" && rm -f \"\$t\"" >/dev/null 2>&1; then
    ok "🔴 연락서 공유폴더는 **아직 쓸 수 있다**"
  else
    bad "🔴 연락서 공유폴더에 **못 쓴다** — 폴더 자동 생성 · 사본 꽂기가 죽는다"
    say "    → compose 의 app-as 에서 $CONTACT_MNT 쪽에 read_only 가 붙었는지 보세요."
  fi
  # 🔴 「수리 관련」은 **쓰기가 막혀 있어야** 맞다 (19번의 그 결정).
  n_in=$("$DOCKER" exec dss-as sh -c "ls -1 '$REPAIR_MNT' 2>/dev/null | wc -l" 2>/dev/null | tr -d ' ')
  if [ "${n_in:-0}" -ge 1 ] 2>/dev/null; then
    ok "A/S 가 「수리 관련」 공유폴더를 읽는다 (맨 위 칸 ${n_in}개)"
  else
    bad "🔴 A/S 가 $REPAIR_MNT 에서 **0개**를 본다 — 빈 폴더가 붙었다"
    say "    → 경로의 대소문자를 보세요(2_AS센터)."
  fi
  if "$DOCKER" exec dss-as sh -c "t='$REPAIR_MNT/.dss-ro-test'; : > \"\$t\"" >/dev/null 2>&1; then
    bad "🔴 $REPAIR_MNT 에 **쓸 수 있다** — read_only 가 안 먹었다"
    "$DOCKER" exec dss-as sh -c "rm -f '$REPAIR_MNT/.dss-ro-test'" >/dev/null 2>&1
    say "    🔵 시험 파일은 곧바로 지웠다 — 남아 있으면 알려 주세요."
  else
    ok "🔴 $REPAIR_MNT 는 **쓰기가 막혀 있다** (읽기 전용 그대로다)"
  fi
else
  bad "dss-as 컨테이너가 떠 있지 않다"
fi

# 5-ㄷ. 🔴 as.env 의 열세 줄이 **컨테이너 안까지** 그대로 왔는가
say "  5-ㄷ. 🔴 설정이 컨테이너 안까지 그대로 왔는가 (🔵 이번에 더한 줄은 없다)"
if running dss-as; then
  for k in QUOTE_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT \
           CONTACT_FOLDER_ARCHIVE_UNC_ROOT REPAIR_DOCS_ARCHIVE_UNC_ROOT; do
    v=$("$DOCKER" exec dss-as printenv "$k" 2>/dev/null)
    if [ -n "$v" ]; then
      ok "$k 가 컨테이너 안에 그대로 있다"
      # 🔴 역슬래시가 삼켜졌는가 — 16 · 18 · 19번이 이 검사로 잡았다.
      n=$(backslash_count "$v")
      [ "${n:-0}" -ge 4 ] && ok "$k 의 역슬래시 ${n}개 — 삼켜지지 않았다" \
        || bad "$k 의 역슬래시가 ${n:-0}개뿐이다 — 🔴 따옴표가 먹은 것이다"
    else
      bad "$k 가 컨테이너 안에 **없다** — 🔴 그쪽 [폴더 열기]가 죽는다"
    fi
  done
  "$DOCKER" exec dss-as sh -c "[ -d \"\$REPAIR_DOCS_ARCHIVE_DIR\" ]" >/dev/null 2>&1 \
    && ok "REPAIR_DOCS_ARCHIVE_DIR 이 **실제로 있는 폴더**를 가리킨다" \
    || bad "REPAIR_DOCS_ARCHIVE_DIR 이 가리키는 폴더가 컨테이너 안에 없다"
  "$DOCKER" exec dss-as sh -c "[ -d \"\$CONTACT_FOLDER_ARCHIVE_DIR\" ]" >/dev/null 2>&1 \
    && ok "CONTACT_FOLDER_ARCHIVE_DIR 이 **실제로 있는 폴더**를 가리킨다" \
    || bad "CONTACT_FOLDER_ARCHIVE_DIR 이 가리키는 폴더가 컨테이너 안에 없다"
else
  bad "dss-as 컨테이너가 떠 있지 않다 — 설정을 못 봤다"
fi

say "  5-ㄹ. 알림 통로 · 알림 링크의 주소 (A/S 만)"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 \
       "http://127.0.0.1:$AS_PORT/api/integration/notifications" 2>/dev/null)
case "$code" in
  404) bad "A/S 의 /api/integration/notifications 가 404 다 — **옛 이미지다**" ;;
  000|"") bad "A/S 의 알림 통로가 대답하지 않는다 (${code:-없음})" ;;
  *)   ok "A/S 의 알림 통로가 있다 (토큰 없이 부르면 401 이 맞다 — 지금 $code)" ;;
esac
notify_href_check "A/S" dss-as "$AS_ENV" "https://as.dss21.co.kr"

say "  5-ㅁ. 권한 — 교체 뒤에 다시 읽는다 (🔴 select 만)"
perm_check

# 5-ㅂ. 🔴 건드리지 않는 쪽이 **정말 안 멈췄는가** — 시작 시각으로 본다
say "  5-ㅂ. 🔴 건드리지 않는 쪽이 안 멈췄는가 (시작 시각을 대조한다)"
for t in $KEEP_BOXES; do
  before=$(printf '%s\n' "$STARTED_BEFORE" | sed -n "s/^$t=//p" | head -1)
  after=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  if [ -n "$before" ] && [ "$before" = "$after" ]; then
    ok "$t · 시작 시각 그대로 — **한 번도 안 멈췄다**"
  else
    bad "🔴 $t 의 시작 시각이 바뀌었다 ($before → $after) — 이 배포가 건드렸다"
  fi
done

say "  5-ㅅ. 바깥 주소 여섯"
for h in as; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code (바뀐 쪽)" ;;
    *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
  esac
done
say "  🔴 안 바뀌는 쪽 — 흔들렸으면 **이 배포가 건드린 것**이다:"
for h in login meters improvements po leave; do
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
echo "  🔵 마이그레이션 **0건** — 운영 DB 는 115 그대로입니다"
echo "  🔵 as.env **0 줄** 고쳤습니다 (사본만 남겼습니다)"
echo "  첨부 스냅숏: $BK"
echo "  as.env 사본: $BKD/as.env.$STAMP"
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
║ 🔵 **이번 판은 사람이 미리 할 일이 없습니다.**                       ║
╚════════════════════════════════════════════════════════════════════╝

  · 도우미(dss-folder)를 **한 글자도 안 바꿨습니다** — 재설치가 필요 없습니다.
  · DB 도, 설정도, 볼륨도 그대로입니다.
  🔵 19번이 넣은 세대 표시(dss.helper.gen1.openfile) 덕분에, 그때 한 번 설치한
     PC 에는 재설치 안내가 더는 뜨지 않습니다.

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. **[제품 모델 관리] 목록의 정렬** — 고르개에 **「고객사 오름차순」**이
      보입니까. 고르면 고객사 이름 차례로 줄이 섭니까.
      🔵 「모델명 오름차순」 · 「종류별」은 그대로 있어야 맞습니다.

   2. **[고객사 관리] → 고객사 하나 → 「연결된 제품 모델」**
      · 🔴 **전에 「없습니다」만 보이던 고객사에 모델이 보입니까** — 이 판의
        중심입니다(접수 건이 있는 고객사 32곳 중 27곳이 비어 있었습니다).
      · 줄마다 **「직접 연결」 · 「접수 기록」** 딱지가 붙습니까.
        양쪽에서 이어진 모델은 **한 줄에 딱지 둘**이 맞습니다.
      · 🔴 **이 화면의 정렬 고르개에는 「고객사 오름차순」이 없어야 맞습니다** —
        여기 모델은 전부 같은 고객사의 것이라 뜻이 없습니다.
      · 모델이 하나도 없는 고객사는 안내 문구가 **「A/S 접수 건이 생기면 …」**
        으로 바뀌어 있습니다.

   3. 🔴 **.xlsm(매크로 엑셀) 올리기** — 되는 자리와 안 되는 자리를 **둘 다**
      보세요.
      · 되어야 하는 곳 **셋** — **점검표 · 파라미터 · 통전검사** 분류.
      · 🔴 안 되어야 하는 곳 — 사진 · 고객 서류 · 견적서처럼 형식을 가리는
        분류. 거기서는 그대로 거절이 맞습니다.
      · 🔴 **.xlsb · .docm · .pptm 같은 나머지 매크로 오피스는 어디서도
        거절**이어야 맞습니다 (하나만 열었습니다).
      · 올린 뒤 **내려받아 엑셀로 열어** 보세요 — 매크로가 든 그 파일이 맞는지.

   4. 🔵 그대로여야 하는 것 — 견적서 · 현황표 · 연락서 · 「수리 관련」
      [폴더 열기] 넷. (스크립트가 5-ㄴ 에서 이미 읽기·쓰기를 확인했습니다.)

   5. 🔵 **포털 · 계측기 · 개선요청 · PO · 휴가가 그대로입니까** — 이번 판은
      그 다섯을 건드리지 않았습니다. (스크립트가 5-ㅂ 에서 시작 시각으로 이미
      확인했습니다.)

🔴 사람이 이어서 할 일:
  · 🔴 **직원에게 .xlsm 을 알립니다** — 점검표 · 파라미터 · 통전검사에
    매크로 엑셀을 올릴 수 있게 됐다는 것, 그리고 🔴 **이 시스템에는 아직
    악성코드 검사기가 없다**는 것. 올리는 사람이 그 파일의 출처를 알아야
    합니다(사용자가 그 사실을 알고 열기로 정했습니다 — 2026-10-08).
  · 「연결된 제품 모델」이 넓어진 것을 영업 쪽에 알립니다.
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.
  · 내일 아침 백업을 한 번 더 보세요 — 다섯이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -7
  · 첨부 스냅숏은 $BK 에 있습니다. 한 주쯤 두었다 지우세요.

되돌리기 안내:  bash $0 --rollback
  🔵 **DB 도 as.env 도 되돌릴 것이 없습니다** — 이번 판은 둘 다 안 바꿨습니다.
  🔴 **2.3 에서 올라간 .xlsm 은 2.2 에서 새로 올릴 수 없습니다.** 이미 올라간
     것은 그대로 보이고 내려받힙니다 — **지우지 마세요.**
ANNOUNCE
exit "$FAIL"
