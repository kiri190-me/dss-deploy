#!/bin/bash
# /volume1/dss/setup/21-deploy.sh — 2026-10-12 열일곱째 배포
#
# ── 무엇이 올라가는가 ───────────────────────────────────────────────────
#   사내 사이트 여섯 중 **둘**을 올린다.
#
#     A/S  dss-as:2.3  →  **dss-as:2.4**   (커밋 17개 · 082b6a6 ~ 1a3185d)
#     PO   dss-po:0.3  →  **dss-po:0.4**   (커밋 14개 · 2026-09-30 이후)
#
#   나머지 넷(포털 1.5 · 계측기 1.3 · 개선요청 0.3 · 휴가 0.1)은
#   **건드리지 않는다. 멈추지도 않는다.**
#
#   🔴 **휴가(dss-leave)는 이 판에 넣지 않는다**(사용자 결정 2026-10-12).
#      그쪽은 마이그레이션 0002 가 운영에 안 올라가 있어 따로 간다.
#
#     | | 값 |
#     | A/S           | 2.3 → **2.4** (커밋 17개)                       |
#     | PO            | 0.3 → **0.4** (커밋 14개)                       |
#     | 마이그레이션  | 🔵 **0건** — 운영 DB 는 **115 그대로**          |
#     | 새 볼륨       | **하나 — 🔴 읽기 전용** (app-as 에만)           |
#     | as.env        | **두 줄** 덧붙임                                |
#     | po.env        | **다섯 줄** 덧붙임 (볼륨 없이 값만)             |
#     | 양식          | **두 벌 교체** (매쳐 내자 · 매쳐 OH 견적서)     |
#     | 다른 넷       | **손대지 않는다**                               |
#
#   🔵 20번(열여섯째)의 뼈대를 쓰고, **볼륨 하나 + .env 덧붙이기**는 19번
#      (열다섯째)의 코드를 그대로 가져왔다. 19번이 REPAIR_DOCS_ARCHIVE_* 에서
#      한 일과 **같은 모양**이다.
#   🔴 20번에서 그대로 이어받은 것: 마이그레이션 코드가 **한 줄도 없다**
#      (묶음 · db:migrate · db:preflight · 적용 직전 덤프 · 「지우는 문장」 잣대).
#      돌 일이 없는 코드를 운영 절차에 남기지 않는다.
#
# ── 이 판에 무엇이 담겼나 (사람에게 설명할 말로) ────────────────────────
#
#   ① **수리 건 상세에 「발주서」 탭이 생겼다.** 그 장비의 **가장 최근 발주서
#      폴더 하나**를 찾아 안을 보여 준다. 짝짓기는 폴더 이름의 **L/N · S/N**
#      으로만 한다 — 고객사 이름을 우리 DB 와 맞추지 않는다(수리 중에 고객사가
#      바뀐 건도 찾히고, `㈜` 유무 같은 규칙을 만들 일이 없다).
#      🔴 **날짜가 같은 폴더가 둘이면 아무것도 안 보여 준다**(multiple) —
#         하나를 임의로 고르면 **남의 발주서**가 화면에 뜨기 때문이다.
#
#   ② **[저장]을 누르면 엑셀이 진짜 PDF 로 바뀐다.** 쓰는 분 PC 의 Excel 이
#      바꾸고, 서버가 폴더를 다시 읽어 확인한다. 도는 동안 팝업이 떠 있다.
#      🔴 **내자 견적서는 내자 탭만, OH 는 OH 탭만** 나간다(서버가 그 시트를
#      활성으로 두고 도우미는 활성 시트만 내보낸다).
#
#   ③ **견적서 결재창 · 보고서 탭에 공유폴더 구역**이 생겼다. 승인하기 전에
#      그 장의 폴더를 본다. 승인된 견적서는 목록에 **체크 표시**가 붙는다
#      (🔴 APPROVED 에만. 승인 뒤 고친 장 APPROVED_OUTDATED 에는 안 붙는다).
#
#   ④ **공유폴더 창이 표가 됐다** — 이름 · **수정날짜** · 크기 · 동작.
#      네 창이 한 벌을 쓴다.
#
#   ⑤ **공유폴더 서류를 그 건의 연락서 폴더 「공통」에 가져오기.**
#
#   ⑥ PO 도 같은 흐름을 받는다 — 견적서 저장 PDF · 결재 탭 공유폴더 구역 ·
#      목록의 승인 체크 · [Excel 보기] · 새 견적서의 발행번호 미리 채우기.
#      🔴 **PO 의 공용 묶음 포인터가 5ecbaee 로 올라간다**(이미지에 포함된다).
#
#   🔴 **DB 스키마 0 · 새 권한 0.** 바뀌는 것은 코드 · 볼륨 하나 · 설정 일곱 줄 ·
#      양식 두 벌이다.
#
# ══ 🔴 ① 마이그레이션이 **0건**이다 ════════════════════════════════════
#
#   개발 PC 에서 확인했다:
#     git diff --name-only e8359e8..1a3185d -- drizzle/   → **빈 출력**
#     npm run db:preflight                                → 115건 · 대기 0
#   🔴 **PO 에는 마이그레이션 장치가 아예 없다**(drizzle 폴더가 없다).
#
#   ⚠️ **배포 전 백업 검사는 그대로 둔다.** 17번에서 그것이 실제로 배포를 막아
#      사고를 피했다(01:00 에 돌렸더니 야간 백업이 02:30 이라 아직 없었다).
#      🔴 **--go 는 오늘 뜬 dss_as 백업이 없으면 시작조차 않는다**(3-ㄱ).
#      DB 를 안 바꾸더라도 그 문은 닫아 두지 않는다.
#
#   🔵 도구 이미지도 **다시 굽지 않았다**(dss-as-tools:1). 이번엔 그 이미지가
#      할 일 자체가 없다.
#
# ══ 🔴 ② compose 에 **새 볼륨**이 하나 는다 — 🔴 **읽기 전용**이다 ══════
#
#   app-as 에 이것이 더해진다 — 🔴 **긴 문법**이다:
#
#       - type: bind
#         source: "/volume1/5_ 외자 PO/1. 발주서(고객-디에스에스) 관련 최종자료(활용)/열람가능 외부 송부시 대표 허락요망/발주서 및 해당 정보 파일 모음"
#         target: /purchase-order-archive
#         read_only: true
#
#   🔴 짧은 문법(`원본:대상`)으로 적으면 깨진다 — 경로에 **공백**이 있다.
#
#   🔴 **`5_ 외자 PO` 의 PO 는 대문자다.** Windows 탐색기에는 `5_ 외자 po` 로
#      보이지만 NAS 의 실제 이름은 대문자다(2026-10-12 `ls -d /volume1/*/` 로
#      사용자가 확인). 소문자로 적으면 리눅스에서 **조용히 빈 폴더**가 되고
#      화면은 「발주서가 하나도 없다」로 보인다 — `2_AS센터` 에서 겪은 그 일이다.
#      🔵 이 스크립트는 그래서 **맨 위 칸이 0개면 ✗** 로 센다.
#
#   🔴 **읽기 전용으로 붙인다**(read_only: true). 19번의 「수리 관련」 볼륨과
#      같은 까닭이다 — 발주서 코드에 만들기 · 쓰기 · 지우기가 **한 글자도 없다**
#      (purchase-order-archive.ts 는 node:fs/promises 를 아예 안 가져온다.
#       purchase-order-archive-source.test.ts 가 원본을 글자로 읽어 못 박는다).
#      🔴 그래서 **쓰기가 되면 오히려 ✗ 다** — :ro 가 안 먹었다는 뜻이고,
#         그대로 두면 앱이 직원의 서류함을 고칠 수 있는 자리가 열린 채로 돈다.
#
#   🔴 **ACL 을 걷지 않는다.** chmod · chown 으로 걷으면 **직원의 탐색기 접근이
#      끊긴다.** 컨테이너가 읽을 수 있는 근거는 app-as 의 `group_add: ["100"]`
#      하나이고, 그 줄은 **이미 있다**(더하지 않는다).
#
#   🔴 **app-po 에는 붙이지 않는다** — PO 저장소에 그 화면이 없다.
#      🔴 **tools-as 에도 붙이지 않는다** — 쓰는 스크립트가 없다.
#
# ══ 🔴 ③ .env 에 **일곱 줄**을 덧붙인다 (19번의 그 코드를 본뜸) ════════
#
#   | 파일   | 이름                                 | 무엇                      |
#   | as.env | PURCHASE_ORDER_ARCHIVE_DIR           | 컨테이너 안 경로          |
#   | as.env | PURCHASE_ORDER_ARCHIVE_UNC_ROOT      | 🔴 도우미 설치본에만      |
#   | po.env | CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT     | 🔴 A/S 와 **같은 값**     |
#   | po.env | CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT | 🔴 A/S 와 **같은 값**     |
#   | po.env | CONTACT_FOLDER_ARCHIVE_UNC_ROOT      | 🔴 A/S 와 **같은 값**     |
#   | po.env | REPAIR_DOCS_ARCHIVE_UNC_ROOT         | 🔴 A/S 와 **같은 값**     |
#   | po.env | PURCHASE_ORDER_ARCHIVE_UNC_ROOT      | 🔴 A/S 와 **같은 값**     |
#
#   🔴 **A/S 의 두 줄은 반드시 함께** 들어가야 한다. _DIR 만 넣으면 목록은
#      보이는데 [폴더 열기]가 **조용히** 안 되고, _UNC_ROOT 만 넣으면 구역이
#      통째로 안 그려진다(2026-10-12 개발 PC 에서 실제로 겪었다).
#
# ── 🔴 **PO 는 다섯이다** (2026-10-12 사용자 결정 — 「세 줄을 더 넣고」) ──
#
#   🔴 **PO 의 다섯 줄은 볼륨 없이 값만** 들어간다. 그 값은 **도우미 설치본에만**
#      심기고 PO 서버는 그 폴더들을 읽지 않는다(볼륨도 안 붙인다).
#
#   🔵 **왜 다섯인가.** 2026-10-07 결정은 「도우미는 두 사이트가 똑같이 — 어느
#      화면에서 설치해도 **같은 스크립트**가 깔린다」였다. 오늘 **코드**는 글자까지
#      같아졌는데(지문 76f85922…) **설정값이 달라 설치본은 여전히 달랐다.**
#      도우미가 루트를 모으는 자리는 **다섯을 본다**
#      (quote-folder-helper.ts · resolveQuoteFolderHelperInstallRoots 의 배열 —
#       A/S 저장소와 PO 저장소가 그 배열까지 **글자가 같다**. 2026-10-12 실측):
#        CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT · 그 _ALT ·
#        CONTACT_FOLDER_ARCHIVE_UNC_ROOT · REPAIR_DOCS_ARCHIVE_UNC_ROOT ·
#        PURCHASE_ORDER_ARCHIVE_UNC_ROOT
#      po.env 에 그 다섯이 다 있어야 비로소 두 설치본이 같아진다.
#   🔴 **그래도 「설치 명령은 A/S 화면에서만 받는다」 안내는 이번에 없애지 않는다.**
#      (쓰는 분들이 이미 그 길에 익었다. 안내 문구는 그대로 둔다.)
#
#   🔴 **값은 지어내지 않는다. as.env 에서 읽어 그대로 쓴다.** 지어내 넣으면
#      PO 에서 설치한 PC 가 **엉뚱한 폴더**를 연다. _ALT 를 뺀 넷 가운데 하나라도
#      as.env 쪽 값이 **비어 있으면 거기서 멈추고 사람에게 알린다.**
#
#   🔵 **_ALT 는 선택값이다 — 비어 있어도 된다.** 확인한 사실(2026-10-12):
#      도우미는 `if (!configured || configured.trim().length === 0) continue;` 로
#      **빈 값을 건너뛴다.** 그러므로 **빈 값으로 넣는 것과 아예 안 넣는 것이
#      결과가 같다.** 고른 쪽은 「**as.env 를 그대로 비춘다**」이다 —
#        · as.env 에 그 줄이 있으면(값이 비었어도) po.env 에도 **같은 줄**을 적는다
#          → 두 파일을 나란히 놓고 보면 눈으로도 같다.
#        · as.env 에 그 줄이 **아예 없으면** po.env 에도 **안 적는다**(SKIP).
#          그때도 설치본은 같다 — 양쪽 다 그 루트가 없는 것이다.
#
#   🔴 19번의 규율을 한 글자도 바꾸지 않고 그대로 가져왔다:
#     · **이 PC(dss-deploy)의 nas/env/*.env 를 NAS 로 올리지 않는다. 절대로.**
#       그 사본은 낡아서 NAS 에만 있는 줄들이 없다 — 올리면 그 기능들이 운영에서
#       통째로 사라진다. **NAS 의 파일에 덧붙인다.**
#     · 덧붙이기 전에 **사본**을 남긴다(backups/as.env.<도장> · po.env.<도장>).
#     · 🔴 **같은 이름이 두 줄이 되게 하지 않는다** — 이미 있으면 **값이 같은지
#       보고**, 다르면 **덧붙이지 않고 멈춘다.** 두 번 돌려도 안전하다.
#     · 적기 **전에** 견적서 셋 · 현황표 다섯 · 연락서 셋 · 수리관련 둘이
#       살아 있는지 본다. 하나라도 없으면 멈춘다.
#
#   🔴 **UNC 의 호스트 부분은 NAS 의 as.env 에서 뽑는다. 코드에 박지 않는다.**
#      견적서 쪽(QUOTE_ARCHIVE_UNC_ROOT · _ALT)에서 **호스트 토막만** 읽고,
#      🔴 **IP 쪽을 고른다**(사내 DNS 가 없어 이름 풀이가 안 되는 PC 가 있다).
#      뽑지 못하면 기본값 \\192.168.0.222 를 쓰고 **그렇게 말한다.**
#
#   ⚠️ **값에 따옴표를 두르지 않는다.** env_file 의 큰따옴표 안에서는 역슬래시가
#      이스케이프로 읽혀 조용히 사라진다.
#   🔴 **역슬래시가 먹혔는지 센다** — 짤 때 한 번, 교체 뒤 컨테이너 안에서
#      printenv 로 한 번. **넷 이상**이어야 맞다(16 · 18 · 19 · 20번의 그 검사).
#
#   🔵 UNC 쪽 공유 이름은 **`5_ 외자 po`(소문자)** 로 적는다 — Windows 탐색기가
#      보여 주는 이름이고, SMB 는 공유 이름의 대소문자를 가리지 않는다.
#      🔴 **리눅스 쪽(볼륨 source)만 대문자 `PO`** 다. 둘이 다른 것이 맞다.
#
# ══ 🔴 ④ 매쳐 견적서 **양식 두 벌**을 바꾼다 ═══════════════════════════
#
#   운영 양식은 /volume1/dss/as-templates/ 에 있고 **A/S 와 PO 가 같은 폴더를
#   읽는다**(둘 다 :ro 로 /templates). 바꿀 둘:
#
#     매쳐 내자 견적서.xlsx    40,079 바이트
#     매쳐 OH 견적서.xlsx      40,664 바이트
#
#   🔴 2026-10-12 에 **직인 좌표를 고쳤다.** 매쳐 O/H 는 직인 폭이 **0** 이라
#      **아예 안 찍히고 있었다** — 위치 문제가 아니라 **직인 빠진 견적서가
#      나가고 있었다.** 그래서 이 교체는 「보기 좋게」가 아니라 **사고 수습**이다.
#
#   🔴 **스크립트가 파일을 만들어 내지는 못한다.** 사람이 먼저 올려야 한다:
#
#     (PowerShell · 개발 PC 에서 · 🔴 ASCII 이름으로 올린다)
#       scp -O '매쳐 내자 견적서.xlsx' dss-nas:/volume1/dss/setup/incoming/matcher-quote.xlsx
#       scp -O '매쳐 OH 견적서.xlsx'  dss-nas:/volume1/dss/setup/incoming/matcher-oh-quote.xlsx
#
#   🔴 **md5 로 맞는 파일인지 확인한다**(DSM 터미널이 긴 명령을 잘라 먹어 파일이
#      깨진 적이 있다). 아래 두 상수는 개발 PC 의 원본에서 **실제로 재어** 적었다
#      (2026-10-12 · 직인 좌표를 고친 뒤의 파일).
#   🔴 **--go 는 옛 양식을 지우지 않는다. 옆에 치워 둔다**
#      (backups/as-templates-<도장>/).
#   🔵 양식은 **코드와 무관한 자료**라 되돌릴 때 함께 되돌릴 필요가 없다 —
#      직인 좌표는 xlsx 파일 안에 들어 있다.
#
# ══ 🔴 ⑤ 야간 백업 시각을 지킨다 — **02:30** ═══════════════════════════
#
#   🔴 **자정을 넘겨 돌리면 백업 검사에 걸린다.** 17번이 01:00 에 돌렸다가
#      실제로 배포가 막혔다 — 그것이 사고를 막았다.
#      늦은 시각에 돌려야 한다면 **먼저 손으로 한 번 뜬다**(종료 코드 0):
#
#        bash /volume1/dss/jobs/backup-nightly.sh
#
#      ✓ dss_as 줄이 찍혀야 한다. 다섯 개가 다 떠야 1-ㅅ 이 통과한다.
#
# ══ 🔴 돌리기 전에 — **값 여섯을 채워야 한다** ═════════════════════════
#
#   🔴 이 스크립트를 쓸 때 dss-as:2.4 · dss-po:0.4 는 **아직 안 구워졌다.**
#      그래서 아래 여섯 상수가 **비어 있다**:
#        SZ_AS · MD5_AS · WANT_CFG_AS · SZ_PO · MD5_PO · WANT_CFG_PO
#      비어 있는 동안 --check 는 그 자리를 ⚠️ 로만 말하고, 🔴 **--go 는 시작조차
#      하지 않는다.** 잰 적 없는 이미지를 운영에 올리지 않기 위해서다.
#
#   개발 PC(PowerShell)에서 굽고 재는 차례 — 폴더는
#   C:\Users\희만\Desktop\Development 다:
#
#     cd C:\Users\희만\Desktop\Development\RF_Service_System
#     git status --short                      ← **비어 있어야 한다**
#     docker build -t dss-as:2.4 .
#     cd ..\dss-po
#     git status --short
#     docker build -t dss-po:0.4 .
#     cd ..
#     docker save dss-as:2.4 -o dss-as-2.4.tar
#     docker save dss-po:0.4 -o dss-po-0.4.tar
#     (Get-Item dss-as-2.4.tar).Length             ← SZ_AS
#     Get-FileHash -Algorithm MD5 dss-as-2.4.tar   ← MD5_AS (소문자로 적는다)
#     tar -xOf dss-as-2.4.tar manifest.json        ← "Config" 의 sha256 → WANT_CFG_AS
#     (PO 도 같은 세 줄)
#
#   🔴 **`git archive` 로 뽑지 마라** — 서브모듈 vendor/dss-ui · vendor/dss-core 가
#      **빈 폴더**로 나와 빌드가 깨진다. 작업 폴더에서 굽되 git status 가 비어야 한다.
#   🔴 **tar 가 이미지의 1/4 쯤인 것은 정상이다.** 2.3 은 tar 130,845,696 바이트
#      (약 125MB)였고 이미지는 590MB 였다. 0.3 은 tar 95,373,824 였다.
#   🔴 **tar 안 Config 지문은 개발 PC 의 `{{.Id}}` 와 다르다.** 17번이 두 번 겪었다.
#      NAS 는 tar 안의 config 지문을 image ID 로 낸다 — **맞춰 볼 값은 tar 쪽**이다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/21-deploy.sh            ← 읽기만 한다
#
#   🔴 NAS 의 docker 는 **sudo(root)** 가 필요하다. 이 스크립트는 root 가
#      아니면 첫 줄에서 멈춘다.
#
# ══ 🔴 개발 PC → NAS 로 올릴 것 **다섯** ═══════════════════════════════
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#      아래는 **개발 PC 의 PowerShell** 에서 친다(NAS 가 아니다).
#
#     scp -O dss-as-2.4.tar dss-nas:/volume1/dss/images/
#     scp -O dss-po-0.4.tar dss-nas:/volume1/dss/images/
#     scp -O docker-compose.nas.yml dss-nas:/volume1/dss/setup/incoming/
#     scp -O '매쳐 내자 견적서.xlsx' dss-nas:/volume1/dss/setup/incoming/matcher-quote.xlsx
#     scp -O '매쳐 OH 견적서.xlsx' dss-nas:/volume1/dss/setup/incoming/matcher-oh-quote.xlsx
#
#   🔴 **마이그레이션 묶음은 올릴 것이 없다.** 이 스크립트는 그 파일을 쳐다보지
#      도 않는다.
#   🔴 세 번째 줄의 compose 는 **dss-deploy 저장소의 nas/docker-compose.nas.yml**
#      이다(A/S · PO 태그 두 줄과 발주서 볼륨 네 줄이 올라간 그 파일).
#   🔵 scp 가 바로 안 되면 사용자 계정(swhur)의 홈으로 올린 뒤 NAS 에서
#      `sudo mv` 로 옮긴다. /volume1/dss 아래는 root 만 쓸 수 있다.
#
# ══ 🔴 DSM 터미널은 긴 명령을 잘라 먹는다 ══════════════════════════════
#
#   하루에 네 번 깨진 적이 있다. **NAS 에서 돌릴 것은 스크립트 파일로 올리고
#   md5 를 맞춘 뒤** 실행한다. 이 파일 자체가 그렇다:
#
#     (PowerShell)  scp -O nas\setup\21-deploy.sh dss-nas:/volume1/dss/setup/
#     (PowerShell)  Get-FileHash -Algorithm MD5 nas\setup\21-deploy.sh
#     (NAS)         md5sum /volume1/dss/setup/21-deploy.sh
#                   → 두 값이 **같아야** 실행한다. 다르면 다시 올린다.
#
#   그래서 이 스크립트는 사람이 칠 명령을 **한 줄 76자 안쪽**으로만 찍는다.
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#
#   11번부터 이어온 약속을 그대로 잇는다 — **인자 없이 돌리면 --check**.
#   실수로 그냥 돌려도 아무것도 바뀌지 않는다(로그 파일 하나만 남는다).
#   코드로는 아래 세 줄이 그 약속이다:
#     · MODE=check        (모드 절의 첫 줄)
#     · FORCE_LOAD=0      (같은 태그를 덮어쓰지 않는다)
#     · PROBE_WRITE=0     (--check 는 /data 에 시험 파일도 만들지 않는다)
#
#   🔴 정직하게 적어 둔다 — --check 도 이미지 **안을 보려고** 컨테이너를 잠깐
#      띄웠다 지우고(docker run --rm), 운영 DB 에 **select** 를 몇 번 보낸다.
#      그리고 새 볼륨을 **임시 컨테이너에 `:ro` 로 붙여** 「쓰기가 막혀 있는가」를
#      한 번 시험한다 — 🔴 **그 마운트를 우리가 `:ro` 로 만들기 때문에 커널이
#      거절하는 것이 정상이고, 쓰이는 일은 일어나지 않는다.** 19번이 --check 에서
#      하던 그대로다. 디스크에도 DB 에도 아무것도 남기지 않는다.
#      「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확한 말이다.
#
# ── 모드 다섯 ───────────────────────────────────────────────────────────
#   (없음) · --check     읽기만 한다. 아무것도 안 바꾸고 안 멈춘다      ← 기본값
#   --preload            새 이미지 둘을 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --go                 🔴 A/S · PO 를 교체한다 (DB 는 안 바꾼다)
#   --rollback           되돌리기 안내
#
#   `--force-load` 는 `--go` 와 같이 써도 된다:  bash 21-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 21-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 21-deploy.sh --preload       (새 이미지 둘을 미리 실어 둔다)
#   3) bash 21-deploy.sh                 (다시 읽기만 — 이번엔 지문까지 다 본다)
#   4) bash 21-deploy.sh --go            (A/S · PO 교체 · 설정 일곱 줄 · 양식 둘)
#
# ══ 🔴 「아직 안 온 것」을 ✗ 로 세지 않는다 (17 ~ 20번의 규칙) ═════════
#
#       **--check 가 ✗ 로 세는 것은 「있는데 어긋난 것」뿐이다.**
#       「아직 안 온 것 · 아직 안 실린 것」은 ⚠️ 로 안내만 한다.
#
# ══ 🔴 건드리지 않는 여덟 ══════════════════════════════════════════════
#
#     dss-auth:1.5              dss-as-tools:1
#     dss-meters:1.3            dss-meters-tools:1
#     dss-improvements:0.3      dss-improvements-tools:2
#     dss-leave:0.1             dss-leave-tools:1
#
#   전부 지금 운영에서 돌고 있다. compose 에서 이 태그가 흔들렸으면 **남의
#   변경이 섞인 것**이다 — 두 세션이 같은 저장소를 쓴다. 고치지 말고 **먼저 알린다.**
#
#   그리고 「안 멈췄다」를 말로 하지 않는다 — 교체 **전후로** 각 컨테이너의
#   시작 시각(.State.StartedAt)을 적어 두고 **그대로인지** 본다(5-ㅅ).
#
# ══ 15 ~ 20번에서 그대로 이어받는 것 ═══════════════════════════════════
#
#   ① 같은 태그로 다시 구운 이미지는 조용히 안 실린다 → --force-load
#   ② 폴더 권한은 **컨테이너 안에서 실제로 열어 본다**(ls -ld 로는 모른다)
#   ③ 이미지는 태그가 아니라 **안을 본다**(1-ㅋ)
#   ④ 사람이 칠 명령은 **한 줄 76자 안쪽**(DSM 의 ash 가 긴 줄을 자른다)
#   ⑤ 공유폴더는 **chmod 로 ACL 을 걷으면 안 된다** — 직원의 탐색기가 끊긴다
#   ⑥ `docker ps` 에 보이는 것과 앱이 **대답하는** 것은 다르다 → wait_http
#   ⑦ compose 는 바꾸기 **전에** 시험하고, 바꾼 것은 backups/ 에 남긴다
#   ⑧ 알림 링크가 **밖에서 닿는 주소**로 나오는가(1-ㅈ · 5-ㅁ)
#   ⑨ 🔴 **권한은 코드가 아니라 운영 DB 가 정한다** — role_permissions 를
#      읽어 보고 말한다(1-ㄷ). 🔴 **select 만 쓴다.**
#   ⑩ 🔴 **만든 것과 도는 것은 다르다** — 양식도 볼륨도 **컨테이너 안에서**
#      다시 본다(5-ㄴ · 5-ㄹ).
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
TODAY=$(date +%F)
CF=$D/deploy/docker-compose.nas.yml
INC=$D/setup/incoming
INCOMING=$INC/docker-compose.nas.yml
ENV_NAS=$D/deploy/.env.nas
ENVD=$D/deploy/env
AS_ENV=$ENVD/as.env
PO_ENV=$ENVD/po.env
IMAGES=$D/images
BKD=$D/backups

# ── 🔴 이번에 올라가는 것 **둘** ───────────────────────────────────────
TAG_AS=dss-as:2.4
OLD_AS=dss-as:2.3
TAG_PO=dss-po:0.4
OLD_PO=dss-po:0.3

# ── 🔴 **건드리지 않는 여덟** (20번의 아홉에서 PO 가 빠졌다) ───────────
KEEP_AUTH=dss-auth:1.5
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_METERSTOOLS=dss-meters-tools:1
KEEP_IMP=dss-improvements:0.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_LEAVE=dss-leave:0.1
KEEP_LEAVETOOLS=dss-leave-tools:1

# ── tar 둘 ─────────────────────────────────────────────────────────────
TAR_AS=$IMAGES/dss-as-2.4.tar
TAR_PO=$IMAGES/dss-po-0.4.tar
# 🔴 **2026-10-12 20:16 에 구워 잰 값이다.** 개발 PC 의
#    Development\dss-as-2.4.tar · dss-po-0.4.tar 에서 바로 쟀다.
#    tar 가 다시 구워지면 **지문이 달라진다** — 그때는 여섯을 다시 잰다.
SZ_AS=131237888
MD5_AS=2673bdecfc47cddc9d2a76ddfa47042b
WANT_CFG_AS=sha256:4256829e89aa5ac2fdd594b97a65da3b96ac59b9a1ed2b0d057880be7a7699ee
SZ_PO=95424000
MD5_PO=d0d6ce877db88976e9af31d48d791621
WANT_CFG_PO=sha256:c74e49a684e7ef8c52aa6685252464f61d1b43de590a52231e32441bcc07eeb3
# ⚠️ manifest.json 은 그 값을 `blobs/sha256/973ce1c0…` 로 적는다 — 앞의 `blobs/` 를
#    떼고 `sha256:` 를 붙인 모양으로 적는다(17 ~ 20번도 같은 모양이었다).

# ── 포트 (compose 의 ports: 에서 읽어 확인했다 — 짐작이 아니다) ────────
#   포털 13100 · A/S 13000 · 계측기 13300 · 개선요청 13500 ·
#   PO 13600 · 휴가 13700
AS_PORT=13000
PO_PORT=13600

# ── DB 이름 — 🔴 **백업 검사와 권한 읽기에만 쓴다** ────────────────────
# 🔵 이번 판은 DB 를 **바꾸지 않는다.** 마이그레이션도 덤프도 없다.
AS_DB=dss_as

# ── 권한 — 🔴 읽기만 한다. 출처는 전부 소스다 (1-ㄷ) ──────────────────
#   표·칸   vendor/dss-core/src/schema/role-permissions.ts
#           (표 role_permissions · 칸 role · area_key · level · updated_at.
#            🔴 칸 이름은 leaf_key 가 아니라 **area_key** 다 — 이름이 낡았다)
#   기본값  src/lib/auth/permission-baseline.ts
#             repairCases.view   → 수리 건을 볼 수 있는 역할만 READ
#             repairCases.files  → 로그인한 사람이면 WRITE
#             quotes.view        → 견적서를 볼 수 있는 역할만 READ
#   🔴 표에 줄이 **없으면 위 기본값대로**다. 줄이 있으면 그 값이 이긴다.
#   🔵 이번 판은 **새 권한을 하나도 만들지 않았다.** 그래도 읽어 두는 것은,
#      어느 칸이 NONE 이면 그 사람 눈에는 「바뀐 것이 없다」로 보이기 때문이다.
PERM_TABLE=role_permissions
PERM_AREA_CASE=repairCases.view
PERM_AREA_FILES=repairCases.files
PERM_AREA_QUOTE=quotes.view

# ── 컨테이너 안에서 실제로 열어 볼 폴더 ────────────────────────────────
ATT=$D/as-attachments
TEMPLATES=$D/as-templates
UP_IMP=$D/improvements-uploads
MF_METERS=$D/meters-files
# 🔵 **이미 붙어 있는 공유폴더 넷.** 여기서는 「사라지지 않았는가」만 본다.
PORTAL_MNT=/customer-portal-archive          # 16번이 붙였다 (현황표)
CONTACT_MNT=/contact-folder-archive          # 18번이 붙였다 (연락서 · 쓰기 가능)
REPAIR_MNT=/repair-docs-archive              # 19번이 붙였다 (수리 관련 · 읽기 전용)
REPAIR_SRC="/volume1/2_AS센터/1. 수리 관련"  # 🔴 `2_AS센터` 의 AS 는 **대문자**다

# ── 🔴 이번에 **새로 붙는** 공유폴더 — 읽기 전용이다 ──────────────────
# 🔴 `5_ 외자 PO` 의 **PO 는 대문자**다(머리말 ②).
PO_SRC="/volume1/5_ 외자 PO/1. 발주서(고객-디에스에스) 관련 최종자료(활용)/열람가능 외부 송부시 대표 허락요망/발주서 및 해당 정보 파일 모음"
PO_MNT=/purchase-order-archive

# ── as.env · po.env 에 덧붙일 **일곱 줄**의 재료 ───────────────────────
# 호스트 부분은 build_env_values() 가 NAS 의 as.env 에서 뽑는다. 뽑지 못했을
# 때 쓸 기본값은 아래 하나다 — 🔴 **IP 다**(머리말 ③ 의 그 까닭).
DEF_HOST='\\192.168.0.222'
# 🔵 UNC 쪽 공유 이름은 **소문자**다 — 탐색기가 보여 주는 이름이고 SMB 는
#    공유 이름의 대소문자를 가리지 않는다. 리눅스 쪽(PO_SRC)만 대문자다.
P_SHARE='5_ 외자 po'
P_T1='1. 발주서(고객-디에스에스) 관련 최종자료(활용)'
P_T2='열람가능 외부 송부시 대표 허락요망'
P_T3='발주서 및 해당 정보 파일 모음'
# build_env_values() 가 채운다. 🔴 PO 쪽 값은 **전부 as.env 에서 읽는다 —
#    지어내지 않는다.** 지어내면 PO 에서 설치한 PC 가 엉뚱한 폴더를 연다.
V_PO_DIR=$PO_MNT
V_PO_ROOT=""
V_REPAIR_ROOT=""
V_PORTAL_ROOT=""
V_PORTAL_ALT=""
V_CONTACT_ROOT=""
ALT_IN_AS=0        # as.env 에 _ALT **줄 자체**가 있는가 (값이 비어도 1)
PO_KEYS_EFF=""     # 실제로 다룰 po.env 키 목록 (build_env_values 가 정한다)
AS_NEW_KEYS="PURCHASE_ORDER_ARCHIVE_DIR PURCHASE_ORDER_ARCHIVE_UNC_ROOT"
# 🔴 **다섯이다**(2026-10-12 사용자 결정 — 「세 줄을 더 넣고」).
#    차례는 도우미가 루트를 모으는 차례 그대로다
#    (quote-folder-helper.ts 의 resolveQuoteFolderHelperInstallRoots 배열).
PO_NEW_KEYS="CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT CONTACT_FOLDER_ARCHIVE_UNC_ROOT REPAIR_DOCS_ARCHIVE_UNC_ROOT PURCHASE_ORDER_ARCHIVE_UNC_ROOT"
# 🔴 _ALT 를 뺀 넷은 **값이 비어 있으면 안 된다** — 비면 그 루트가 통째로 빠진다.
PO_REQUIRED_KEYS="CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT CONTACT_FOLDER_ARCHIVE_UNC_ROOT REPAIR_DOCS_ARCHIVE_UNC_ROOT PURCHASE_ORDER_ARCHIVE_UNC_ROOT"
PO_ALT_KEY=CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT
# 🔴 NAS 에만 있고 이 PC 의 사본에는 없는 열세 줄. **사라지면 안 된다.**
QUOTE_KEYS="QUOTE_ARCHIVE_DIR QUOTE_ARCHIVE_UNC_ROOT QUOTE_ARCHIVE_UNC_ROOT_ALT"
PORTAL_KEYS="CUSTOMER_PORTAL_ARCHIVE_DIR CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT CUSTOMER_PORTAL_ARCHIVE_FOLDER_PATH CUSTOMER_PORTAL_ARCHIVE_UNC_PATH"
CONTACT_KEYS="CONTACT_FOLDER_ARCHIVE_DIR CONTACT_FOLDER_ARCHIVE_UNC_ROOT CONTACT_FOLDER_ARCHIVE_UNC_PATH"
REPAIR_KEYS="REPAIR_DOCS_ARCHIVE_DIR REPAIR_DOCS_ARCHIVE_UNC_ROOT"

# ══ 🔴 매쳐 견적서 양식 두 벌 ══════════════════════════════════════════
#
#  🔴 아래 md5 · 바이트는 **개발 PC 의 원본에서 실제로 재어** 적었다
#     (2026-10-12 · 직인 좌표를 고친 뒤). 짐작한 값이 아니다.
TPL1_NAME='매쳐 내자 견적서.xlsx'
TPL1_INC=matcher-quote.xlsx
TPL1_SZ=40079
TPL1_MD5=a9f1f7e75e2ac718d86c288efec41d43
TPL2_NAME='매쳐 OH 견적서.xlsx'
TPL2_INC=matcher-oh-quote.xlsx
TPL2_SZ=40664
TPL2_MD5=fc4ee94678b99e5c7b60ca7d1fd94c57
# --check 가 채운다: DONE(이미 새것) · READY(올라와 있다) · 빈 값(아직 없다)
TPL1_STATE=""
TPL2_STATE=""
TPL1_SRC=""
TPL2_SRC=""

# ══ 이미지 **안에서** 찾을 글자 (1-ㅋ) ═════════════════════════════════
#
#  🔴 태그와 지문이 맞아도 「무엇이 든 판인지」는 안을 봐야 안다. 9/21~9/29 에
#     A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다.
#
#  🔵 이번 판은 **새 파일이 많다** — 그래서 19번처럼 **모듈 경로**로 가린다
#     (20번은 새 파일이 0개라 내용으로 갈라야 했다). Next 의 번들은 webpack
#     모듈 이름으로 소스 경로를 그대로 품는다.
#  🔴 아래 경로는 개발 PC 의 git 에서 **실제로 A(새로 생김)로 확인한 것**이다
#     (git diff --name-status e8359e8..1a3185d · a7987a0..cb654be).
AS_MARK1="src/lib/storage/purchase-order-archive.ts"
AS_MARK2="src/components/repair-cases/purchase-orders/PurchaseOrderFolderSection.tsx"
AS_MARK3="src/lib/domain/purchase-order-folder-name.ts"
AS_MARK4="src/components/repair-cases/report/ServiceReportFolderSection.tsx"
AS_MARK5="PURCHASE_ORDER_ARCHIVE_DIR"     # 설정 이름 — 2.3 에는 없다
# 🔵 2.2 · 2.3 에서 들어온 것이 2.4 에도 그대로 있는가 — **회귀** 표시다.
AS_KEEP="src/lib/storage/repair-docs-archive.ts"
AS_CTRL="SSO_REDIRECT_URI"                # 두 판에 다 있는 대조 표시
PO_MARK1="src/components/quotes/QuoteArchiveFolderSection.tsx"
PO_MARK2="src/components/quotes/quote-save-pdf-convert.ts"
PO_MARK3="src/components/quotes/quote-next-number.ts"
PO_MARK4="PURCHASE_ORDER_ARCHIVE_UNC_ROOT" # 설정 이름 — 0.3 에는 없다
PO_KEEP="src/lib/server/quote-folder-helper.ts"
PO_CTRL="SSO_REDIRECT_URI"

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 셋. 인자가 없으면 이 셋 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
PROBE_WRITE=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 21-deploy.sh                  읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 21-deploy.sh --check          위와 같습니다
  bash 21-deploy.sh --preload        새 이미지 둘을 싣고 지문만 맞춥니다
  bash 21-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 21-deploy.sh --go             🔴 A/S · PO 교체 + 설정 일곱 줄 + 양식 둘
  bash 21-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 21-deploy.sh --rollback       되돌리기 안내

  🔴 --go 가 멈추는 것은 **dss-as 와 dss-po 둘**입니다.
     포털 · 계측기 · 개선요청 · 휴가 · DB 는 그대로 돕니다.
  🔵 --go 는 **DB 를 바꾸지 않습니다** — 이번 판은 마이그레이션이 0건입니다.
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
LOG="$D/setup/logs/21-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11 ~ 20-deploy.sh 의 것 그대로 ────────────────────────────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""; DOWN=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# 🔴 「아직 안 온 것」은 --check 에서 ✗ 가 아니다.
#    --preload · --go 는 그것이 **있어야** 도는 모드라 ✗ 로 센다.
missing_is_fatal() { [ "$MODE" != check ]; }
notyet() { # 1 할 말   — 아직 안 **온** 것(사람이 올려야 하는 파일)
  if missing_is_fatal; then bad "$1"; else echo "    ⚠️ $1"; fi
}
notloaded() { # 1 할 말 — 아직 안 **실린** 것. 🔴 어느 모드에서도 ✗ 가 아니다.
  echo "    ⚠️ $1"
}

# 🔴 값 여섯이 채워졌는가 — 안 채워졌으면 --go 가 시작하지 않는다.
pinned() {
  [ -n "$SZ_AS" ] && [ -n "$MD5_AS" ] && [ -n "$WANT_CFG_AS" ] \
    && [ -n "$SZ_PO" ] && [ -n "$MD5_PO" ] && [ -n "$WANT_CFG_PO" ]
}

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

running() { "$DOCKER" ps --format '{{.Names}}' | grep -qx "$1"; }
pg_up()   { running dss-pg-app; }

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미 — 🔴 **이 스크립트가 DB 에 보내는 SQL 은 전부 select 다.**
#     db:migrate 도, pg_dump 도, db:preflight 도 없다.
# ══════════════════════════════════════════════════════════════════════
qas()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -Atc \"$1\"" 2>/dev/null; }
qqas() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -c   \"$1\"" 2>/dev/null; }

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
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
# ── 🔴 역슬래시가 삼켜졌는가 — UNC 값에 역슬래시가 넷 이상 있어야 맞다 ──
backslash_count() { # 1 값 → 개수
  printf '%s' "$1" | tr -cd '\\' | wc -c | tr -d ' '
}
# ══════════════════════════════════════════════════════════════════════
#  ② 폴더를 **컨테이너 안에서 실제로 열어 본다**
#
#  🔴 주인(uid)과 모드(755)만 보면 통과하는데 실제로는 EACCES 인 일이 있다.
#     Synology ACL 이 상위에서 내려오면 `ls -ld` 에는 끝의 `+` 하나로만 보인다.
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
  say "    🔴 /volume1/3_견적… · /volume1/2_AS센터 · /volume1/5_ 외자 PO 같은"
  say "       **직원이 쓰는 공유폴더에는 하지 마라** — 탐색기 접근이 끊긴다."
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
#  🔴 **이번 배포로 새로 붙는 볼륨**을 임시 컨테이너로 열어 본다 (19번의 것)
#
#  도는 2.3 에는 아직 이 자리가 없다. 그래서 호스트 경로를 **우리가 :ro 로**
#  붙여 본다. ⚠️ -u 1000:1000 --group-add 100 은 compose 의 app-as 와 **같은
#  조건**이다 — 그것 없이 재면 ACL 의 group:users:allow 에 안 걸려 「못 읽는다」
#  가 나오고, 멀쩡한 폴더를 또 의심하게 된다.
#
#  🔴 **쓰기가 되면 ✗ 다** — 19번의 「수리 관련」에서와 같은 뜻이다.
#     🔵 마운트를 **우리가 :ro 로 만든다.** 그래서 이 시험은 --check 에서도
#        아무것도 쓰지 못한다(커널이 거절한다).
# ══════════════════════════════════════════════════════════════════════
probe_image() { # → 임시로 띄울 이미지 태그 (없으면 빈 문자열)
  local img
  img=$("$DOCKER" inspect -f '{{.Config.Image}}' dss-as 2>/dev/null)
  if [ -n "$img" ] && have_img "$img"; then echo "$img"; return 0; fi
  if have_img "$TAG_AS"; then echo "$TAG_AS"; return 0; fi
  if have_img "$OLD_AS"; then echo "$OLD_AS"; return 0; fi
  return 1
}
probe_new_volume() { # 1 호스트경로 2 컨테이너안경로 3 사람이읽을이름
  local src="$1" mnt="$2" label="$3" img out r w y n rc=0
  if [ ! -d "$src" ]; then
    say "  · $label — 호스트 폴더가 없어 못 열어 봤다(위에서 이미 ✗ 로 셌다)"
    return 0
  fi
  img=$(probe_image) || {
    say "  · $label — 띄울 이미지가 NAS 에 하나도 없다. **못 열어 봤다**"
    say "    → 먼저 이미지를 실으세요:"
    cmd "bash $0 --preload"
    return 0
  }
  say "  $label — 🔴 **새로 붙는 볼륨이라** 임시 컨테이너($img)를 띄워 본 것:"
  say "    (도는 2.3 에는 아직 이 자리가 없다)"
  say "    🔵 :ro 로 붙인다 — compose 의 read_only: true 와 **같은 조건**이다."
  # 🔴 경로는 -e 로 넘겨 **컨테이너 안에서** 푼다. sh -c 본문에 끼워 넣으면
  #    빈칸 · 괄호 · 한글이 든 경로에서 조용히 깨진다.
  out=$("$DOCKER" run --rm -u 1000:1000 --group-add 100 \
        -e M="$mnt" \
        -v "$src:$mnt:ro" --entrypoint sh "$img" -c '
          id
          if ls -1 "$M" >/dev/null 2>&1; then
            echo "PROBE_NEW READ_OK"
            echo "TOPN $(ls -1 "$M" 2>/dev/null | wc -l)"
            echo "YEARN $(ls -1 "$M" 2>/dev/null | grep -c "^[12][0-9][0-9][0-9]$")"
            ls -1 "$M" 2>/dev/null | head -8 | sed "s/^/TOP /"
          else
            echo "PROBE_NEW READ_FAIL"
          fi
          t="$M/.dss-ro-test"
          # 🔴 **`: > "$t"` 를 쓰지 마라.** 읽기 전용 자리에서 리다이렉션이 실패하면
          #    Alpine 의 ash 는 **셸을 그 자리에서 끝낸다** — 아래 echo 가 아예 안
          #    돌아 판정이 빈 채로 나온다(2026-10-12 --check 에서 실제로 났다:
          #    「쓰기 막힘 여부를 못 봤다(출력이 비었다)」). touch 는 외부 명령이라
          #    실패해도 셸이 살아 있다.
          if touch "$t" 2>/dev/null; then
            echo "PROBE_RO WRITE_OK"
            rm -f "$t" 2>/dev/null
          else
            echo "PROBE_RO WRITE_BLOCKED"
          fi' 2>&1)
  printf '%s\n' "$out" | grep -E '^(uid=|PROBE_NEW |PROBE_RO |TOPN |YEARN |TOP )' \
    | sed 's/^/      /'
  r=$(printf '%s\n' "$out" | sed -n 's/^PROBE_NEW //p' | head -1)
  w=$(printf '%s\n' "$out" | sed -n 's/^PROBE_RO //p'  | head -1)
  n=$(printf '%s\n' "$out" | sed -n 's/^TOPN //p'  | head -1 | tr -d ' ')
  y=$(printf '%s\n' "$out" | sed -n 's/^YEARN //p' | head -1 | tr -d ' ')
  case "$r" in
    READ_OK)
      ok "$label · $mnt 를 읽는다 (uid 1000 + gid 100)" ;;
    READ_FAIL)
      bad "$label · $mnt 를 **못 읽는다**(EACCES) — 🔴 진짜 권한 문제다"
      say "    (자리가 없어서 나는 ✗ 가 아니다. 여기서는 자리를 **우리가 붙여** 봤다.)"
      say "    🔴 **chmod · chown 을 하지 마라** — 직원의 탐색기 접근이 끊긴다."
      say "    되는 폴더(견적서 · 현황표 · 연락서 · 수리 관련)와 ACL 을 견주세요:"
      cmd "synoacltool -get \"$src\" | head -30"
      say "    (보는 것: group:users:allow:…r…x… 가 있는가)"
      say "    compose 의 app-as 에 group_add: [\"100\"] 이 있는지도 보세요."
      rc=1 ;;
    *)
      bad "$label · 열어 보지 못했다 — 아래가 그대로의 출력이다"
      printf '%s\n' "$out" | sed 's/^/      /' | head -8
      rc=1 ;;
  esac
  if [ "$r" = READ_OK ]; then
    if [ "${n:-0}" -ge 1 ] 2>/dev/null; then
      ok "$label · 맨 위 칸에 ${n}개가 보인다"
    else
      bad "🔴 $label · 맨 위 칸이 **0개다** — 경로가 틀렸다"
      say "    → 🔴 「5_ 외자 PO」 의 **PO 가 대문자**인지 보세요(머리말 ②)."
      cmd "ls -d /volume1/5_*"
      rc=1
    fi
    if [ "${y:-0}" -ge 1 ] 2>/dev/null; then
      ok "$label · 맨 위 칸에 **연도 폴더**(2026 꼴)가 ${y}개 있다 — 자리가 맞다"
    else
      bad "🔴 $label · 연도 폴더(2026 꼴)가 **하나도 없다** — 한 칸 위나 아래다"
      say "    (발주서는 <루트>/2026/<고객사>/<발주 건> 꼴로 쌓여 있다.)"
      rc=1
    fi
  fi
  case "$w" in
    WRITE_BLOCKED)
      ok "$label · **쓰기가 막혀 있다** — 읽기 전용으로 붙었다는 뜻이다" ;;
    WRITE_OK)
      bad "🔴 $label · **쓰기가 됐다** — :ro 가 안 먹었다"
      say "    🔴 이 기능은 이 폴더를 **읽기만** 한다. 쓸 수 있는 자리가 열린 채로"
      say "       돌면 앱이 직원의 서류함을 고칠 수 있다."
      say "    → compose 의 app-as 쪽 이 볼륨에 read_only: true 가 있는지 보세요."
      say "    🔵 시험 파일은 만들자마자 지웠다 — 남아 있으면 알려 주세요."
      rc=1 ;;
    *)
      say "    ⚠️ $label · 쓰기 막힘 여부를 못 봤다(출력이 비었다)" ;;
  esac
  return "$rc"
}

# ══════════════════════════════════════════════════════════════════════
#  【이어받은 검사】 알림 링크의 **주소를 실제로 뽑아 본다**
#
#  🔴 2026-09-29 에 「통로가 있다(401 이 온다)」로 통과했는데, 그 통로가 내준
#     링크가 http://172.20.0.7:3500/ 이었다. 문이 있는지가 아니라 **무엇이
#     나오는지**를 봐야 잡힌다.
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
#  이미지 **안에** 이번 판이 들어 있는가
#
#  🔴 「아직 안 실린 것」은 ✗ 가 아니다. 못 봤다고 말하고 넘어간다.
#  🔴 대조 표시(…_CTRL)가 안 나오면 **판정하지 않는다** — 글자를 못 읽은 것과
#     옛 판인 것을 가를 수 없기 때문이다.
# ══════════════════════════════════════════════════════════════════════
inside_check() { # 1 태그 2 라벨 3 옛태그 4..9 글자 여섯(새 넷 · 회귀 하나 · 대조 하나)
  local tag="$1" label="$2" old="$3" m1="$4" m2="$5" m3="$6" m4="$7" keep="$8" ctrl="$9"
  local out a b c d k x
  if ! have_img "$tag"; then
    notloaded "$tag 가 아직 NAS 에 없어 **안을 못 봤다** — 먼저 실으세요"
    cmd "bash $0 --preload"
    return 0
  fi
  # 🔴 글자는 **-e 로 넘긴다.** sh -c 본문에 끼워 넣으면 따옴표가 든 글자에서
  #    조용히 깨진다. 결과는 한 줄에 0/1 여섯 개로 받는다.
  out=$("$DOCKER" run --rm \
        -e M1="$m1" -e M2="$m2" -e M3="$m3" -e M4="$m4" \
        -e K="$keep" -e C="$ctrl" \
        --entrypoint sh "$tag" -c '
    r=""
    for w in "$M1" "$M2" "$M3" "$M4" "$K" "$C"; do
      if grep -rlF -- "$w" /app/.next >/dev/null 2>&1; then r="$r 1"; else r="$r 0"; fi
    done
    echo "INSIDE$r"' 2>/dev/null \
    | grep '^INSIDE ' | head -1)
  a=$(printf '%s' "$out" | awk '{print $2}')
  b=$(printf '%s' "$out" | awk '{print $3}')
  c=$(printf '%s' "$out" | awk '{print $4}')
  d=$(printf '%s' "$out" | awk '{print $5}')
  k=$(printf '%s' "$out" | awk '{print $6}')
  x=$(printf '%s' "$out" | awk '{print $7}')
  if [ "${x:-0}" != 1 ]; then
    say "    ⚠️ $tag 안을 글자로 뒤지지 못했다 — 대조 표시($ctrl)도 안 나왔다."
    say "       **판정하지 않는다.** 🔴 이때는 사람이 직접 화면에서 봐야 한다."
    return 0
  fi
  ok "$label · 대조 표시($ctrl)를 찾았다 — 안을 실제로 읽었다는 뜻이다"
  [ "${a:-0}" = 1 ] && ok "$label · $m1 가 들어 있다" \
    || bad "🔴 $label · $m1 가 **없다** — 이것은 $old 다"
  [ "${b:-0}" = 1 ] && ok "$label · $m2 가 들어 있다" \
    || bad "🔴 $label · $m2 가 **없다** — 이것은 $old 다"
  [ "${c:-0}" = 1 ] && ok "$label · $m3 가 들어 있다" \
    || bad "🔴 $label · $m3 가 **없다** — 이것은 $old 다"
  [ "${d:-0}" = 1 ] && ok "$label · $m4 가 들어 있다" \
    || bad "🔴 $label · $m4 가 **없다** — 이것은 $old 다"
  [ "${k:-0}" = 1 ] && ok "$label · 회귀 — $keep 가 그대로 있다" \
    || bad "🔴 $label · $keep 가 **사라졌다** — $old 보다 **옛 판**을 올린 것이다"
}

# ── 🔴 이미지 안에 글자 인식기(public/ocr)가 들어 있는가 (A/S 만) ──────
# 🔴 Next 의 standalone 은 public 을 **자동으로 담지 않는다.** Dockerfile 이
#    따로 COPY 하는데, 그 줄이 어긋나면 화면은 뜨고 명판 읽기만 죽는다.
# 🔵 이번 판이 더한 기능이 아니다 — 회귀 검사다(2026-10-05 실측 6912KB).
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
# ══════════════════════════════════════════════════════════════════════
PERM_SQL_COUNT="select count(*) from $PERM_TABLE"
PERM_SQL_AREA="select role, area_key, level, updated_at::date from $PERM_TABLE where area_key in ('$PERM_AREA_CASE', '$PERM_AREA_FILES', '$PERM_AREA_QUOTE') order by area_key, role"

perm_check() {
  local reg n_all n_case n_files n_quote
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
  n_case=$(qas  "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_CASE'")
  n_files=$(qas "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_FILES'")
  n_quote=$(qas "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_QUOTE'")
  say "  · $PERM_AREA_CASE 에 저장된 줄: ${n_case:-?}"
  say "  · $PERM_AREA_FILES 에 저장된 줄: ${n_files:-?}"
  say "  · $PERM_AREA_QUOTE 에 저장된 줄: ${n_quote:-?}"
  say
  say "  저장된 값 — 역할 전부:"
  qqas "$PERM_SQL_AREA" | sed 's/^/      /'
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔵 이번 판은 **새 권한을 만들지 않았습니다.**                   ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  if [ "${n_case:-0}" = 0 ] && [ "${n_files:-0}" = 0 ] && [ "${n_quote:-0}" = 0 ]; then
    say "     🔵 세 칸에 **저장된 줄이 하나도 없습니다.** 그러면 코드의 기본값이"
    say "        그대로 삽니다 — 지금 보이던 사람에게 그대로 보입니다."
  else
    say "     🔴 저장된 줄이 있습니다. 위 표를 보세요 — **저장된 값이 코드의"
    say "        기본값을 이깁니다.** 그 칸이 NONE 인 역할에게는"
    say "        · $PERM_AREA_CASE  — 수리 건 상세가 안 열립니다(발주서 탭도)"
    say "        · $PERM_AREA_QUOTE — 견적서 화면이 안 열립니다(저장 PDF 도)"
    say "        · $PERM_AREA_FILES — 파일 관리가 막힙니다"
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  .env — 🔴 **NAS 의 파일을 읽고 없는 줄만 덧붙인다** (19번에서 가져옴)
#
#  🔴 이 PC 의 nas/env/*.env 를 올리지 않는다(머리말 ③).
#  🔴 값은 로그에 찍지 않는다 — 다만 QUOTE_ARCHIVE_UNC_ROOT · _ALT 의
#     **호스트 부분**(\\이름 또는 \\IP)만 뽑아 보여 준다. 새 줄을 같은 꼴로
#     짜려면 그 한 토막이 필요하고, 그 토막은 비밀이 아니라 NAS 이름이다.
#  🔴 그리고 **새로 넣는 일곱 줄의 값은 그대로 찍는다** — 폴더 경로라 비밀이
#     아니고, 사람이 눈으로 맞춰 봐야 하는 값이다.
# ══════════════════════════════════════════════════════════════════════
env_val_of() { # 1 파일 2 키  → 값 (없으면 빈 문자열)
  local v
  [ -f "$1" ] || return 0
  v=$(sed -n "s/^$2=//p" "$1" | head -1 | tr -d '\r')
  v=${v#\"}; v=${v%\"}
  v=${v#\'}; v=${v%\'}
  printf '%s' "$v"
}
env_count_of() { # 1 파일 2 키 → 그 이름으로 시작하는 줄 수
  [ -f "$1" ] || { echo 0; return 0; }
  grep -c "^$2=" "$1" 2>/dev/null | tr -d ' '
}
unc_host() { # 1 UNC 값  → \\호스트  (못 뽑으면 빈 문자열)
  printf '%s' "$1" | sed -n 's/^\(\\\\[^\\]*\).*/\1/p'
}
is_ip_host() { # 1 \\호스트  → IP 면 0
  local b
  b=$(printf '%s' "$1" | tr -d '\\')
  [ -n "$b" ] || return 1
  case "$b" in *[!0-9.]*) return 1 ;; esac
  return 0
}
ENV_SRC_NOTE=""; ENV_HOST=""; ENV_HOST_WHY=""
# 일곱 줄의 값을 짠다. 🔴 printf 로 짓는다 — 역슬래시가 한 겹 삼켜지지 않게.
build_env_values() {
  local qroot qalt hr ha already
  qroot=$(env_val_of "$AS_ENV" QUOTE_ARCHIVE_UNC_ROOT)
  qalt=$(env_val_of "$AS_ENV" QUOTE_ARCHIVE_UNC_ROOT_ALT)
  hr=$(unc_host "$qroot")
  ha=$(unc_host "$qalt")
  ENV_SRC_NOTE="NAS 의 as.env"
  # 🔴 IP 쪽을 고른다 — 사내 DNS 가 없어 이름 풀이가 안 되는 PC 가 있다.
  if is_ip_host "$hr"; then
    ENV_HOST=$hr; ENV_HOST_WHY="QUOTE_ARCHIVE_UNC_ROOT 가 IP 라 그것을 골랐다"
  elif is_ip_host "$ha"; then
    ENV_HOST=$ha; ENV_HOST_WHY="QUOTE_ARCHIVE_UNC_ROOT_ALT 가 IP 라 그것을 골랐다"
  elif [ -n "$hr" ]; then
    ENV_HOST=$hr
    ENV_HOST_WHY="🔴 둘 다 IP 가 아니라 **이름**을 골랐다 — 이름 풀이가 안 되는 PC 에서는 [폴더 열기]가 안 된다"
  elif [ -n "$ha" ]; then
    ENV_HOST=$ha
    ENV_HOST_WHY="🔴 ROOT 를 못 읽어 _ALT 를 골랐다"
  else
    ENV_HOST=$DEF_HOST
    ENV_SRC_NOTE="기본값(as.env 에서 뽑지 못했다)"
    ENV_HOST_WHY="🔴 견적서 두 줄에서 호스트를 못 뽑았다 — 기본값 IP 를 썼다"
  fi
  V_PO_DIR=$PO_MNT
  # 🔴 as.env 에 이미 적혀 있으면 **그 값이 기준**이다(두 번 돌려도 같아야 한다).
  already=$(env_val_of "$AS_ENV" PURCHASE_ORDER_ARCHIVE_UNC_ROOT)
  if [ -n "$already" ]; then
    V_PO_ROOT=$already
  else
    V_PO_ROOT=$(printf '%s\\%s\\%s\\%s\\%s' "$ENV_HOST" "$P_SHARE" "$P_T1" "$P_T2" "$P_T3")
  fi
  # 🔴 PO 쪽에 넣을 네 루트는 **A/S 의 값을 글자까지 그대로** 쓴다 — 지어내지 않는다.
  V_REPAIR_ROOT=$(env_val_of  "$AS_ENV" REPAIR_DOCS_ARCHIVE_UNC_ROOT)
  V_PORTAL_ROOT=$(env_val_of  "$AS_ENV" CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT)
  V_PORTAL_ALT=$(env_val_of   "$AS_ENV" "$PO_ALT_KEY")
  V_CONTACT_ROOT=$(env_val_of "$AS_ENV" CONTACT_FOLDER_ARCHIVE_UNC_ROOT)
  # ── 🔴 _ALT 를 다룰지 말지 — **as.env 에 줄이 있으면 그대로 따라 적는다** ──
  #
  #  🔵 확인한 사실(2026-10-12 · 두 저장소의 소스를 읽어서):
  #     도우미 루트를 모으는 자리가 양쪽 저장소에서 **글자까지 같다** —
  #       quote-folder-helper.ts : resolveQuoteFolderHelperInstallRoots()
  #         `if (!configured || configured.trim().length === 0) continue;`
  #     즉 **빈 값으로 넣는 것과 아예 안 넣는 것이 결과가 같다**(둘 다 건너뛴다).
  #     그래서 어느 쪽을 골라도 도우미 설치본은 똑같이 나온다.
  #  🔴 고른 쪽: **as.env 를 그대로 비춘다.**
  #     · as.env 에 그 줄이 있으면(값이 비었어도) po.env 에도 같은 줄을 적는다
  #       → 두 파일을 나란히 놓고 보면 **눈으로 같다**. 이것이 이번 결정의 뜻이다.
  #     · as.env 에 그 줄이 **아예 없으면** po.env 에도 적지 않는다(지어내지 않는다).
  #       🔵 그때도 설치본은 같다 — 양쪽 다 그 루트가 없는 것이다.
  if [ "$(env_count_of "$AS_ENV" "$PO_ALT_KEY")" -ge 1 ] 2>/dev/null; then
    ALT_IN_AS=1
    PO_KEYS_EFF=$PO_NEW_KEYS
  else
    ALT_IN_AS=0
    PO_KEYS_EFF=$(printf '%s' "$PO_NEW_KEYS" | tr ' ' '\n' | grep -v "^$PO_ALT_KEY$" | tr '\n' ' ')
  fi
}
want_env_value() { # 1 키 → 그 키에 들어가야 할 값
  case "$1" in
    PURCHASE_ORDER_ARCHIVE_DIR)            printf '%s' "$V_PO_DIR" ;;
    PURCHASE_ORDER_ARCHIVE_UNC_ROOT)       printf '%s' "$V_PO_ROOT" ;;
    REPAIR_DOCS_ARCHIVE_UNC_ROOT)          printf '%s' "$V_REPAIR_ROOT" ;;
    CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT)      printf '%s' "$V_PORTAL_ROOT" ;;
    CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT)  printf '%s' "$V_PORTAL_ALT" ;;
    CONTACT_FOLDER_ARCHIVE_UNC_ROOT)       printf '%s' "$V_CONTACT_ROOT" ;;
  esac
}
# 🔴 네 루트는 **값이 비면 안 된다.** 비었으면 거기서 멈추고 사람에게 알린다
#    (지어내서 넣으면 PO 에서 설치한 PC 가 엉뚱한 폴더를 연다).
po_required_values_ok() { # → 0 이면 다 찼다
  local k v anybad=0
  for k in $PO_REQUIRED_KEYS; do
    v=$(want_env_value "$k")
    if [ -z "$v" ]; then
      bad "🔴 as.env 의 $k 값이 **비어 있다** — po.env 에 옮길 값이 없다"
      say "      🔴 지어내지 않는다. as.env 쪽을 먼저 보세요:"
      say "         grep -n '^$k=' $AS_ENV"
      anybad=1
    fi
  done
  [ "$anybad" = 0 ]
}
# 🔴 같은 이름이 두 줄이 되게 하지 않는다. 이미 있으면 **값이 같은지** 본다.
env_verdict() { # 1 파일 2 키 → ADD | SAME | DIFF | DUP
  local n cur want
  n=$(env_count_of "$1" "$2")
  if [ "${n:-0}" -gt 1 ]; then echo DUP; return 0; fi
  if [ "${n:-0}" = 0 ];    then echo ADD; return 0; fi
  cur=$(env_val_of "$1" "$2")
  want=$(want_env_value "$2")
  if [ "$cur" = "$want" ]; then echo SAME; else echo DIFF; fi
}
report_env_keys() { # 1 파일 2 사람이읽을이름 3 "키 …"
  local f="$1" label="$2" keys="$3" k v
  for k in $keys; do
    # 🔴 _ALT 가 as.env 에 **아예 없으면** 손대지 않는다(지어내지 않는다).
    if [ "$k" = "$PO_ALT_KEY" ] && [ "$f" = "$PO_ENV" ] && [ "$ALT_IN_AS" = 0 ]; then
      say "    · $label · $k — **SKIP** (as.env 에 그 줄이 없다. 적지 않는다)"
      continue
    fi
    v=$(env_verdict "$f" "$k")
    case "$v" in
      SAME) ok "$label · $k 가 **이미 있고 값도 같다** — 건드리지 않는다" ;;
      ADD)  say "    · $label · $k 가 없다 — --go 가 덧붙인다" ;;
      DIFF) bad "🔴 $label · $k 가 **이미 있는데 값이 다르다** — 멈추고 사람에게 알린다"
            say "      지금 값:  $(env_val_of "$f" "$k")"
            say "      넣을 값:  $(want_env_value "$k")"
            say "      🔴 덮어쓰지 않습니다. 어느 쪽이 맞는지 사람이 정해야 합니다." ;;
      DUP)  bad "🔴 $label · $k 가 **두 줄 이상** 있다 — 먼저 그것부터 고쳐야 한다"
            say "      보기:  grep -n '^$k=' $f" ;;
    esac
  done
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 매쳐 견적서 양식 두 벌 — **읽기만 한다. 바꾸는 것은 --go 가 한다.**
# ══════════════════════════════════════════════════════════════════════
see_tpl() { # 1 번호(1|2) 2 운영이름 3 incoming이름 4 기대바이트 5 기대md5
  local n="$1" name="$2" inc="$3" wsz="$4" wmd5="$5"
  local cur cursz src ssz smd5
  say "  · 「$name」"
  if [ ! -f "$TEMPLATES/$name" ]; then
    bad "운영 양식 폴더에 그 파일이 없다: $TEMPLATES/$name"
    say "    🔴 이름이 한 글자라도 다르면 그 종류의 견적서 출력이 통째로 죽는다."
    return 1
  fi
  cursz=$(stat -c '%s' "$TEMPLATES/$name" 2>/dev/null)
  cur=$(md5_of "$TEMPLATES/$name")
  say "      지금 운영: 바이트 ${cursz:-?} · md5 ${cur:-?}"
  say "      바꿀 것 : 바이트 $wsz · md5 $wmd5"
  if [ "$cur" = "$wmd5" ]; then
    ok "「$name」 은 **이미 새 양식이다** — 바꿀 것이 없다"
    eval "TPL${n}_STATE=DONE"
    return 0
  fi
  src=""
  if   [ -f "$INC/$inc" ];  then src=$INC/$inc
  elif [ -f "$INC/$name" ]; then src=$INC/$name
  fi
  if [ -z "$src" ]; then
    notyet "새 양식이 아직 NAS 에 없다 — $INC/$inc"
    say "      → 개발 PC(PowerShell)에서 올리세요. 🔴 **ASCII 이름으로** 올립니다:"
    say "        scp -O '$name' dss-nas:$INC/$inc"
    say "      (그 파일은 개발 PC 의 .env.local 이 가리키는 양식 원본입니다 —"
    say "       2026-10-12 에 직인 좌표를 고친 그 파일.)"
    eval "TPL${n}_STATE="
    return 1
  fi
  ssz=$(stat -c '%s' "$src" 2>/dev/null)
  smd5=$(md5_of "$src")
  say "      올라온 것: 바이트 ${ssz:-?} · md5 ${smd5:-?}"
  if [ "$smd5" != "$wmd5" ]; then
    bad "🔴 올라온 파일의 md5 가 기대값과 다르다 — 옮기다 깨졌거나 다른 파일이다"
    say "      → 다시 올리세요(scp -O). DSM 터미널로 붙여넣지 마세요."
    eval "TPL${n}_STATE="
    return 1
  fi
  if [ "${ssz:-0}" != "$wsz" ]; then
    bad "🔴 올라온 파일의 바이트가 $wsz 가 아니다 (${ssz:-?})"
    eval "TPL${n}_STATE="
    return 1
  fi
  ok "새 양식이 올라와 있고 md5 · 바이트가 맞다 — --go 가 바꾼다"
  eval "TPL${n}_STATE=READY"
  eval "TPL${n}_SRC=\$src"
  return 0
}
# 🔴 바꾸는 쪽. **--go 에서만 불린다.**
swap_tpl() { # 1 운영이름 2 올라온파일 3 기대md5 4 백업폴더
  local name="$1" src="$2" wmd5="$3" bkt="$4" own mode got
  own=$(stat -c '%u:%g' "$TEMPLATES/$name" 2>/dev/null)
  mode=$(stat -c '%a' "$TEMPLATES/$name" 2>/dev/null)
  cp -p "$TEMPLATES/$name" "$bkt/" 2>/dev/null \
    && ok "옛 양식을 치워 뒀다 → $bkt/$name" \
    || { bad "옛 양식을 치우지 못했다 — 바꾸지 않는다"; return 1; }
  cp "$src" "$TEMPLATES/$name.new" 2>/dev/null \
    || { bad "새 양식을 복사하지 못했다"; return 1; }
  [ -n "$own" ]  && chown "$own" "$TEMPLATES/$name.new" 2>/dev/null
  [ -n "$mode" ] && chmod "$mode" "$TEMPLATES/$name.new" 2>/dev/null
  mv -f "$TEMPLATES/$name.new" "$TEMPLATES/$name" \
    || { bad "새 양식을 제자리에 놓지 못했다"; return 1; }
  got=$(md5_of "$TEMPLATES/$name")
  if [ "$got" = "$wmd5" ]; then
    ok "「$name」 바꿨다 (주인 ${own:-?} · 모드 ${mode:-?} 그대로)"
    rm -f "$src"
    return 0
  fi
  bad "🔴 바꾼 뒤 md5 가 다르다 ($got) — 🔴 백업이 $bkt 에 있다"
  return 1
}
# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)
EXP_AS=""
EXP_PO=""
SVCS=""
AS_DBURL=""; PO_DBURL=""

see_tar() { # 1 태그 2 tar 3 tar에서읽은지문 4 기대바이트 5 기대md5 6 기대지문 7 올릴파일이름
  local tag="$1" f="$2" got="$3" wsz="$4" wmd5="$5" wcfg="$6" up="$7" n m
  if [ ! -s "$f" ]; then
    notyet "$tag 의 tar 가 아직 NAS 에 없다: $f"
    say "    → 개발 PC(PowerShell)에서 올리세요. 🔴 scp 에 -O 를 붙입니다:"
    say "      scp -O $up dss-nas:/volume1/dss/images/"
    return 1
  fi
  n=$(stat -c '%s' "$f" 2>/dev/null)
  m=$(md5_of "$f")
  say "    · 지금 이 tar: 바이트 ${n:-?} · md5 ${m:-?}"
  if [ -z "$wsz" ] || [ -z "$wmd5" ] || [ -z "$wcfg" ]; then
    say "    ⚠️ 🔴 **$tag 의 기대값이 비어 있다.** 개발 PC 에서 구운 뒤 이 스크립트"
    say "       머리말의 차례대로 재어 채우세요. 채우기 전에는 --go 가 시작하지 않습니다."
    [ -n "$got" ] && say "    · 이 tar 안 Config 지문: $got"
    return 0
  fi
  [ "$n" = "$wsz" ] && ok "$tag · 바이트 $n" \
    || bad "$tag 의 바이트가 $wsz 가 아니다 ($n) — 옮기다 끊겼다"
  [ "$m" = "$wmd5" ] && ok "$tag · md5 $m" \
    || bad "$tag 의 md5 가 $wmd5 가 아니다 (${m:-못 읽음}) — 파일이 상했다"
  if [ -z "$got" ]; then
    bad "$tag 의 tar 에서 manifest.json 을 읽지 못했다: $f"
    return 1
  fi
  if [ "$got" = "$wcfg" ]; then
    ok "$tag · tar 안 Config 지문이 기대값과 같다 ($(echo "$got" | cut -c1-19)…)"
  else
    bad "$tag · tar 안 Config 지문이 기대값과 다르다"
    say "      tar   $got"
    say "      기대  $wcfg"
    say "      🔴 **다른 판을 올린 것**이거나 옮기다 깨진 것이다."
  fi
}

run_checks() {
  local tag s p rec t f db n_bk nlog k n_top
  local FREE_KB FREE_H code h nb

  # ── 1-ㄱ. 올릴 파일 — 이미지 tar **둘** · 양식 **둘** ────────────────
  step "1-ㄱ. 올린 파일 (이미지 tar 둘 · 양식 둘. 🔵 마이그레이션 묶음은 없다)"
  say "  🔵 19번은 셋이었고 20번은 둘이었다 — 이번은 **다섯**이다"
  say "     (tar 둘 · compose · 양식 둘). as-migrations.tar.gz 는 올리지 마세요."
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  EXP_PO=$(tar_config_id "$TAR_PO" 2>/dev/null) || EXP_PO=""
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS" "$SZ_AS" "$MD5_AS" "$WANT_CFG_AS" dss-as-2.4.tar
  see_tar "$TAG_PO" "$TAR_PO" "$EXP_PO" "$SZ_PO" "$MD5_PO" "$WANT_CFG_PO" dss-po-0.4.tar
  say
  say "  🔴 매쳐 견적서 양식 둘 — **직인이 빠진 견적서가 나가고 있었다.**"
  say "     (매쳐 O/H 는 직인 폭이 0 이라 아예 안 찍혔다 · 2026-10-12 에 고쳤다)"
  see_tpl 1 "$TPL1_NAME" "$TPL1_INC" "$TPL1_SZ" "$TPL1_MD5"
  see_tpl 2 "$TPL2_NAME" "$TPL2_INC" "$TPL2_SZ" "$TPL2_MD5"
  say "  🔵 양식은 **A/S 와 PO 가 같은 폴더를 읽는다**(둘 다 :ro 로 /templates)."
  say "     그래서 한 번 바꾸면 두 사이트가 함께 새 양식을 쓴다."

  # ── 1-ㄴ. NAS 에 실린 이미지 ─────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (올라가는 둘 · 건드리지 않는 여덟)"
  if have_img "$TAG_AS"; then
    [ -n "$EXP_AS" ] && { verify_img "$TAG_AS" "$EXP_AS" || force_load_hint "$TAG_AS"; }
  else
    notloaded "$TAG_AS 는 아직 NAS 에 실리지 않았다 — --preload 나 --go 가 싣는다"
  fi
  if have_img "$TAG_PO"; then
    [ -n "$EXP_PO" ] && { verify_img "$TAG_PO" "$EXP_PO" || force_load_hint "$TAG_PO"; }
  else
    notloaded "$TAG_PO 는 아직 NAS 에 실리지 않았다 — --preload 나 --go 가 싣는다"
  fi
  say "  🔴 지문이 어긋나면 **혼자 고쳐지지 않는다.** 태그가 같으면 docker load 를"
  say "     그냥 부르는 것으로는 안 바뀐다 — 위에 찍힌 --force-load 를 쓰세요."
  say "  🔴 건드리지 않는 여덟 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for tag in "$KEEP_AUTH" "$KEEP_ASTOOLS" "$KEEP_METERS" "$KEEP_METERSTOOLS" \
             "$KEEP_IMP" "$KEEP_IMPTOOLS" "$KEEP_LEAVE" "$KEEP_LEAVETOOLS"; do
    have_img "$tag" && ok "$tag 실려 있다 ($(img_id "$tag" | cut -c1-19)…)" \
      || bad "$tag 가 NAS 에 없다 — 🔴 앞 배포가 되돌아갔거나 누가 지웠다"
  done
  say "  🔴 되돌아간 옛 이미지 둘도 그대로 둔다 — 되돌리기가 그것을 쓴다."
  have_img "$OLD_AS" && ok "$OLD_AS 도 아직 있다 (되돌릴 길이 열려 있다)" \
    || say "    ⚠️ $OLD_AS 가 NAS 에 없다 — 되돌리려면 tar 를 다시 올려야 한다"
  have_img "$OLD_PO" && ok "$OLD_PO 도 아직 있다 (되돌릴 길이 열려 있다)" \
    || say "    ⚠️ $OLD_PO 가 NAS 에 없다 — 되돌리려면 tar 를 다시 올려야 한다"

  # ── 1-ㄷ. 권한 — 🔴 읽기만 한다 ──────────────────────────────────────
  step "1-ㄷ. 새 화면이 **누구 눈에** 보이는가 (운영 DB 를 읽는다)"
  say "  🔴 「권한은 코드가 아니라 운영 DB 가 정한다」 — 그래서 읽어 보고 말한다."
  say "     🔵 이번 판은 **새 권한을 하나도 만들지 않았다.**"
  perm_check

  # ── 1-ㄹ. 🔴 as.env · po.env ─────────────────────────────────────────
  step "1-ㄹ. as.env · po.env (이름만 본다. 🔵 **적는 것은 --go 가 한다**)"
  say "  🔴 이 PC(dss-deploy)의 nas/env/*.env 를 NAS 로 **올리지 마세요.**"
  say "     그 사본에는 NAS 에만 있는 줄들이 빠져 있습니다 — 올리면 견적서 ·"
  say "     현황표 · 연락서 · 수리 관련 기능이 운영에서 통째로 사라집니다."
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
    say "  🔴 현황표 다섯 줄 — 16번이 넣은 것이고 **2.4 도 그대로 쓴다**:"
    for k in $PORTAL_KEYS; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 [공유폴더에 저장]이 실패로 끝난다"
    done
    say "  🔴 연락서 세 줄 — 18번이 넣은 것이고 **2.4 도 그대로 쓴다**:"
    for k in $CONTACT_KEYS; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 연락서 [폴더 열기]가 죽는다"
    done
    say "  🔴 수리 관련 두 줄 — 19번이 넣은 것이고 **2.4 도 그대로 쓴다**:"
    for k in $REPAIR_KEYS; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 「가리킨 서류」 고르는 창이 죽는다"
    done
  else
    bad "as.env 가 없다: $AS_ENV"
    say "    → 없는 env_file 하나면 docker compose 명령이 **통째로** 안 먹는다."
  fi
  for f in po.env auth.env meters.env improvements.env leave.env; do
    [ -f "$ENVD/$f" ] || bad "$f 가 없다: $ENVD/$f (compose 가 통째로 실패한다)"
  done
  if [ -f "$PO_ENV" ]; then
    s=$(stat -c '%a' "$PO_ENV" 2>/dev/null)
    [ "$s" = 600 ] && ok "po.env 있다 · 모드 600" \
      || bad "po.env 의 모드가 ${s:-?} 다 (600 이어야 한다)"
    s=$(stat -c '%U:%G' "$PO_ENV" 2>/dev/null)
    [ "$s" = "root:root" ] || bad "po.env 의 주인이 ${s:-?} 다 (root:root 이어야 한다)"
  fi
  # ── 🔴 이번에 덧붙일 **일곱 줄** ────────────────────────────────────
  build_env_values
  say
  say "  🔴 이번에 덧붙일 **일곱 줄** (as.env 둘 · po.env **다섯**):"
  say "     🔵 po.env 의 다섯은 **도우미 설치본이 심는 루트 다섯**과 같은 목록이다"
  say "        (2026-10-12 사용자 결정 — 「세 줄을 더 넣고」). 이 다섯이 맞아야"
  say "        **어느 화면에서 설치해도 같은 도우미**가 깔린다."
  say "     🔴 po.env 값은 **전부 as.env 에서 읽어 그대로** 쓴다 — 지어내지 않는다."
  po_required_values_ok \
    || say "      → 위 값이 비어 있으면 --go 는 **덧붙이지 않고 멈춥니다.**"
  if [ "$ALT_IN_AS" = 1 ]; then
    say "     🔵 $PO_ALT_KEY — as.env 에 **줄이 있다.** 값까지 그대로 비춘다"
    say "        (값이 비어 있어도 같은 줄을 적는다 — 아래 까닭)."
  else
    say "     ⚠️ $PO_ALT_KEY — as.env 에 **줄이 아예 없다.** po.env 에도 **적지 않는다**"
    say "        (지어내지 않는다. 양쪽 다 그 루트가 없는 것이라 설치본은 여전히 같다)."
  fi
  # 🔴 아래 줄에 **백틱을 쓰지 마라.** 큰따옴표 안의 백틱은 bash 가 명령 치환으로
  #    읽어 `syntax error near unexpected token` 을 뱉는다(2026-10-12 --check 에서
  #    실제로 났다). `bash -n` 은 치환 **안쪽**을 보지 않아 못 잡는다 — 코드를
  #    인용할 때는 작은따옴표나 「」를 쓴다.
  say "     🔵 **빈 값으로 넣는 것과 안 넣는 것은 도우미에서 결과가 같다** — 실측:"
  say "        quote-folder-helper.ts 의 resolveQuoteFolderHelperInstallRoots() 가"
  say "        'if (!configured || configured.trim().length === 0) continue;' 로"
  say "        **빈 값을 건너뛴다.** A/S 와 PO 두 저장소가 그 줄까지 같다(2026-10-12)."
  # 🔴 다섯을 **각각** 찍는다(SKIP 도 한 줄로 찍는다).
  report_env_keys "$AS_ENV" "as.env" "$AS_NEW_KEYS"
  report_env_keys "$PO_ENV" "po.env" "$PO_NEW_KEYS"
  say
  say "  🔵 호스트 토막은 $ENV_SRC_NOTE 에서 왔다 → $ENV_HOST"
  say "     까닭: $ENV_HOST_WHY"
  say "     (견적서 두 줄의 **나머지 부분은 찍지 않는다.** 쓸 것은 호스트뿐이다.)"
  say "  🔵 --go 가 적어 넣을 값 — 눈으로 보고 틀렸으면 멈추세요:"
  for k in $AS_NEW_KEYS; do
    printf '      as.env  %s=%s\n' "$k" "$(want_env_value "$k")"
  done
  for k in $PO_KEYS_EFF; do
    printf '      po.env  %s=%s\n' "$k" "$(want_env_value "$k")"
  done
  nb=$(backslash_count "$V_PO_ROOT")
  [ "${nb:-0}" -ge 4 ] && ok "짠 발주서 UNC 의 역슬래시가 ${nb}개 — 삼켜지지 않았다" \
    || bad "짠 발주서 UNC 의 역슬래시가 ${nb:-0}개뿐이다 — 🔴 따옴표가 먹은 것이다"
  nb=$(backslash_count "$V_REPAIR_ROOT")
  [ "${nb:-0}" -ge 4 ] && ok "A/S 에서 가져온 수리관련 UNC 의 역슬래시가 ${nb}개" \
    || bad "수리관련 UNC 의 역슬래시가 ${nb:-0}개뿐이다 — 🔴 as.env 쪽이 이미 깨져 있다"
  say "  🔴 _UNC_ROOT 는 **도우미 설치본에만** 들어간다(화면으로 안 나간다)."
  say "     🔵 _UNC_PATH 는 없다 — 이 화면에는 [위치 복사]가 없다."
  say "  🔴 이 루트 **아래 전부**가 도우미에게 열린다 — 그래서 공유 뿌리가 아니라"
  say "     「$P_T3」 까지만 적는다."
  say "  ⚠️ 값에 따옴표를 두르지 않는다 — 큰따옴표 안에서는 역슬래시가 먹힌다."
  say
  say "  🔵 **왜 po.env 에 다섯을 넣는가** (2026-10-12 사용자 결정):"
  say "     2026-10-07 결정은 「도우미는 두 사이트가 똑같이 — 어느 화면에서 설치해도"
  say "     같은 스크립트가 깔린다」였다. 오늘 **코드**는 글자까지 같아졌는데"
  say "     (지문 76f85922…) **설정값이 달라 설치본은 여전히 달랐다.** 이 다섯 줄로"
  say "     그 결정이 비로소 완성된다."
  say "     🔴 그래도 「설치 명령은 **A/S 화면에서만** 받는다」 안내는 **그대로 둔다** —"
  say "        이번에 없애지 않는다(쓰는 분들이 이미 그 길에 익었다)."

  # ── 1-ㅁ. compose ───────────────────────────────────────────────────
  step "1-ㅁ. compose ($CF_EFF)"
  say "  🔴 이번 판에서 compose 가 바뀌는 자리는 **셋**이다:"
  say "     ㄱ) app-as 의 image 한 줄 ($OLD_AS → $TAG_AS)"
  say "     ㄴ) app-po 의 image 한 줄 ($OLD_PO → $TAG_PO)"
  say "     ㄷ) app-as 에 **발주서 볼륨 하나**(긴 문법 · 네 줄 · 🔴 읽기 전용)"
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
  say "  올라가는 둘:"
  see_tag app-as "$TAG_AS" "A/S"
  see_tag app-po "$TAG_PO" "PO/내자"
  if [ "$(svc_image "$CF_EFF" app-as)" = "$OLD_AS" ]; then
    say "    🔴 compose 가 아직 **옛 태그**를 가리킵니다. 개발 PC 에서 고친 파일을"
    say "       아래에 올리면 --go 가 시험하고 제자리로 옮깁니다:"
    say "         $INCOMING"
  fi
  say "  🔴 건드리지 않는 여덟 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-auth            "$KEEP_AUTH"        "포털 · 그대로"
  see_tag tools-as            "$KEEP_ASTOOLS"     "A/S 도구 · 그대로"
  see_tag app-meters          "$KEEP_METERS"      "계측기 · 그대로"
  see_tag tools-meters        "$KEEP_METERSTOOLS" "계측기 도구 · 그대로"
  see_tag app-improvements    "$KEEP_IMP"         "개선요청 · 그대로"
  see_tag tools-improvements  "$KEEP_IMPTOOLS"    "개선요청 도구 · 그대로"
  see_tag app-leave           "$KEEP_LEAVE"       "휴가 · 그대로"
  see_tag tools-leave         "$KEEP_LEAVETOOLS"  "휴가 도구 · 그대로"
  # 이미 붙어 있던 볼륨 — 「사라지지 않았는가」만 본다.
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
  svc_block "$CF_EFF" app-as | line_after "target: $REPAIR_MNT" | grep -q 'read_only: true' \
    && ok "🔴 $REPAIR_MNT 에 read_only: true 가 그대로 있다" \
    || bad "🔴 $REPAIR_MNT 의 read_only: true 가 **없어졌다** — 쓰기가 열린 채로 돈다"
  # ── 🔴 이번 배포의 **새 볼륨** — 읽기 전용 ──────────────────────────
  say "  🔴 이번에 새로 붙는 **발주서** 공유폴더 (🔴 **읽기 전용**):"
  svc_block "$CF_EFF" app-as | grep -q "target: $PO_MNT" \
    && ok "app-as 가 $PO_MNT 를 붙인다" \
    || bad "app-as 에 $PO_MNT 가 **없다** — 🔴 발주서 탭이 통째로 꺼진다"
  svc_block "$CF_EFF" app-as | grep -qF "source: \"$PO_SRC\"" \
    && ok "원본 경로가 글자까지 맞다 (🔴 5_ 외자 **PO** — 대문자)" \
    || bad "원본 경로가 기대와 다르다 — 🔴 「5_ 외자 PO」 의 **대소문자**부터 보세요"
  svc_block "$CF_EFF" app-as | line_after "target: $PO_MNT" | grep -q 'read_only: true' \
    && ok "🔴 read_only: true 가 붙어 있다 — 앱이 이 서류함을 못 고친다" \
    || bad "🔴 $PO_MNT 에 read_only: true 가 **없다** — 쓰기가 열린 채로 돈다"
  svc_block "$CF_EFF" app-as | grep -q "type: bind" \
    && ok "긴 문법(type: bind)으로 적혀 있다 (경로에 공백이 있다)" \
    || bad "긴 문법이 아니다 — 🔴 짧은 문법은 이 경로에서 깨진다"
  # 🔴 일부러 안 붙이는 둘
  svc_block "$CF_EFF" app-po | grep -q "$PO_MNT" \
    && say "    ⚠️ app-po 에도 $PO_MNT 가 붙어 있다 — PO 에는 이 화면이 없다(없어도 된다)" \
    || ok "app-po 에는 안 붙였다 (맞다 — PO 저장소에 이 화면이 없다)"
  svc_block "$CF_EFF" tools-as | grep -q "$PO_MNT" \
    && say "    ⚠️ tools-as 에도 붙어 있다 — 쓰는 스크립트가 없다(없어도 된다)" \
    || ok "tools-as 에는 안 붙였다 (맞다 — 쓸 이유가 없다)"
  svc_block "$CF_EFF" app-as | grep -q "$AS_PORT:3000" \
    && ok "app-as 가 127.0.0.1:$AS_PORT 으로 열린다" \
    || bad "app-as 의 포트가 $AS_PORT:3000 이 아니다"
  svc_block "$CF_EFF" app-po | grep -q "$PO_PORT:3600" \
    && ok "app-po 가 127.0.0.1:$PO_PORT 으로 열린다" \
    || bad "app-po 의 포트가 $PO_PORT:3600 이 아니다"
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
    say "       표도 칸도 그대로다 — 둘을 함께 올리는 것이 오히려 단순하다."
  else
    bad "app-po 의 DATABASE_URL 이 app-as 와 다르다 — 🔴 PO 가 엉뚱한 DB 를 본다"
  fi

  # ── 1-ㅂ. 폴더를 컨테이너 안에서 **실제로 열어 본다** ────────────────
  step "1-ㅂ. 폴더 — 주인·모드가 아니라 컨테이너 안에서 실제로 연다"
  say "  🔴 보는 자리가 둘로 갈린다:"
  say "     ㄱ) **이미 붙어 있는 자리**는 지금 도는 컨테이너 안에서 본다."
  say "     ㄴ) **이번 배포로 새로 붙는 자리**($PO_MNT)는 도는 2.3 에 아직 없다 —"
  say "        호스트 경로를 **임시로 :ro 로 붙여** 따로 본다."
  if [ "$PROBE_WRITE" = 1 ]; then
    say "  (교체되는 A/S 의 /data 는 읽기+쓰기를 본다. 시험 파일은 만들었다 지운다.)"
  else
    say "  🔵 --check 라서 /data 는 **읽기만** 해 본다 — 아무 파일도 만들지 않는다."
  fi
  if [ -d "$PO_SRC" ]; then
    ok "호스트에 발주서 폴더가 있다"
    n_top=$(ls -1 "$PO_SRC" 2>/dev/null | wc -l | tr -d ' ')
    say "    · 맨 위 칸의 항목 ${n_top:-?}개"
    if [ "${n_top:-0}" = 0 ]; then
      bad "🔴 **0개다.** 경로가 틀렸다 — 「5_ 외자 PO」 의 PO 가 대문자인지 보세요"
      cmd "ls -d /volume1/5_*"
    fi
  else
    bad "호스트에 발주서 폴더가 **없다**"
    say "    → 🔴 「5_ 외자 PO」 의 **PO 가 대문자**인지 보세요. 소문자로 적으면"
    say "       docker 가 **빈 폴더를 만들어 붙입니다** — 그러면 화면이"
    say "       「발주서가 하나도 없다」로 보입니다."
    cmd "ls -d /volume1/5_*"
  fi
  if [ "$PROBE_WRITE" = 1 ]; then M_DATA=rw; else M_DATA=ro; fi
  probe_svc app-as dss-as "A/S" "/data:$M_DATA /templates:ro" "$ATT $TEMPLATES"
  # 🔴 이번 배포로 **새로 붙는** 볼륨. 도는 컨테이너에는 아직 없다.
  probe_new_volume "$PO_SRC" "$PO_MNT" "발주서 공유폴더"
  # 🔴 교체되는 PO 와, 교체 안 되는 둘.
  probe_svc app-po           dss-po           PO       "/data:ro"         "$ATT"
  probe_svc app-meters       dss-meters       계측기   "/data:ro"         "$MF_METERS"
  probe_svc app-improvements dss-improvements 개선요청 "/data/uploads:ro" "$UP_IMP"
  # 🔴 공유폴더들은 위 틀에 안 넣는다 — 경로에 빈칸과 한글이 있고, 무엇보다
  #    여기서는 ACL 을 **걷으면 안 된다**(직원의 탐색기 접근이 끊긴다).
  say "  이미 붙어 있는 공유폴더 — 🔴 읽기만 본다. ACL 을 걷지 않는다:"
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

  # ── 1-ㅅ. 🔴 야간 백업 · 야간 완전삭제 (읽기만 한다) ─────────────────
  step "1-ㅅ. 야간 백업 다섯 · 야간 완전삭제 (읽기만 한다)"
  say "  🔵 이번 판은 **DB 를 바꾸지 않는다**(마이그레이션 0건)."
  say "     🔴 그래도 --go 는 오늘 뜬 $AS_DB 백업이 없으면 **시작조차 않는다**(3-ㄱ)."
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
  # 새 tar 둘(약 125MB + 95MB) + 실은 이미지 둘(약 590MB + 450MB).
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (tar 둘 + 실은 이미지 둘이 들어가야 한다)"
  fi

  # ── 1-ㅈ. 알림 링크의 주소 — A/S 만 ─────────────────────────────────
  step "1-ㅈ. 알림 링크의 주소 (통로가 아니라 **나오는 주소**를 본다)"
  say "  🔴 **A/S 하나만 본다.** PO 에는 알림 통로가 아예 없다."
  notify_href_check "A/S" dss-as "$AS_ENV" "https://as.dss21.co.kr"

  # ── 1-ㅋ. 새 이미지 **안에** 이번 판이 들어 있는가 ───────────────────
  step "1-ㅋ. 새 이미지 안을 본다 (태그만으로는 안심 못 한다)"
  say "  🔴 9/21~9/29 에 A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다."
  say "  🔵 이번 판은 **새 파일이 많다** — 그래서 모듈 경로로 가린다(19번의 길)."
  if have_img "$TAG_AS"; then
    say "  $TAG_AS 구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_AS" --format '{{.Size}}' 2>/dev/null) ($OLD_AS 는 590MB 였다)"
    inside_check "$TAG_AS" "A/S" "$OLD_AS" \
      "$AS_MARK1" "$AS_MARK2" "$AS_MARK3" "$AS_MARK4" "$AS_KEEP" "$AS_CTRL"
    [ "$(
        "$DOCKER" run --rm -e W="$AS_MARK5" --entrypoint sh "$TAG_AS" -c \
          'if grep -rlF -- "$W" /app/.next >/dev/null 2>&1; then echo 1; else echo 0; fi' 2>/dev/null
      )" = 1 ] \
      && ok "A/S · 설정 이름 $AS_MARK5 가 이미지 안에 있다" \
      || say "    ⚠️ $AS_MARK5 를 못 찾았다 — 압축되며 바뀌었을 수 있다(판정 안 함)"
    say "  🔵 글자 인식기(public/ocr) 회귀 검사 — 2.3 의 것이 그대로 있는가:"
    ocr_check "$TAG_AS"
  else
    notloaded "$TAG_AS 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
  fi
  if have_img "$TAG_PO"; then
    say "  $TAG_PO 구운 때: $("$DOCKER" images "$TAG_PO" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_PO" --format '{{.Size}}' 2>/dev/null)"
    inside_check "$TAG_PO" "PO" "$OLD_PO" \
      "$PO_MARK1" "$PO_MARK2" "$PO_MARK3" "$PO_MARK4" "$PO_KEEP" "$PO_CTRL"
    say "  🔵 PO 에는 public/ 이 없다 — OCR 검사를 하지 않는다(그것이 맞다)."
  else
    notloaded "$TAG_PO 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
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
  # 🔴 이번 판은 **image 두 줄 + 볼륨 네 줄(주석 빼고)** 만 달라야 한다.
  say "  🔵 지금 것과 달라진 줄 (🔴 image 둘 · 발주서 볼륨 넷 + 주석):"
  diff "$CF" "$INCOMING" 2>/dev/null | sed 's/^/      /' | head -60
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
  echo "DSS 열일곱째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     되돌리는 것은 **이미지 둘**이다:"
  say "       $TAG_AS → $OLD_AS"
  say "       $TAG_PO → $OLD_PO"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔵 DB 는 **되돌릴 것이 없다.** 이번 판은 DB 를 안 바꿨다.       ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     마이그레이션 0건 · 새 표 0 · 새 칸 0. 운영 DB 는 **115 그대로**다."
  say
  say "  🔴 **compose 는 사본으로 되돌린다.** sed 로 태그만 내리면 **발주서 볼륨이"
  say "     남는다** — 볼륨이 남아도 2.3 은 그 자리를 안 쓰므로 당장 깨지지는 않지만,"
  say "     「되돌렸다」와 실제가 어긋난 채로 남는다. 사본을 쓰세요(19번의 그 판단)."
  say
  say "  🔵 **.env 일곱 줄은 지우지 않아도 된다.** 2.3 · 0.3 은 그 이름을 읽지 않는다"
  say "     (모르는 환경변수는 그냥 무시된다). 사본은 backups/ 에 있다."
  say "  🔵 **양식 두 벌도 되돌릴 필요가 없다** — 직인 좌표는 xlsx 파일 안에 있고"
  say "     코드와 무관하다. 🔴 되돌리면 **직인 빠진 견적서로 되돌아간다.**"
  say "     그래도 꼭 돌려야 하면 아래 백업 폴더에서 꺼내 쓰세요:"
  ls -1dt "$BKD"/as-templates-* 2>/dev/null | head -3 | sed 's/^/      /'
  say

  step "1. 옛 이미지가 아직 NAS 에 있는지 먼저 본다"
  have_img "$OLD_AS" && ok "$OLD_AS 있다 ($(img_id "$OLD_AS" | cut -c1-19)…)" \
    || bad "$OLD_AS 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"
  have_img "$OLD_PO" && ok "$OLD_PO 있다 ($(img_id "$OLD_PO" | cut -c1-19)…)" \
    || bad "$OLD_PO 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"

  step "2. compose 를 사본으로 되돌린다"
  say "  --go 가 옛 compose 를 아래에 남겼다 (가장 최근 것):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -3 | sed 's/^/      /'
  cmd "cd /volume1/dss/deploy"
  cmd "cp \$(ls -1t ../backups/docker-compose.nas.yml.* | head -1) ."
  say "      (파일 이름이 길면 위 한 줄 대신 두 줄로 나눠 치세요)"
  cmd "grep -n 'image: dss-as\\|image: dss-po' docker-compose.nas.yml"

  step "3. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-as app-po"
  script_file_hint "21-rollback"

  step "4. 🔴 사람에게 알릴 것"
  say "  · 수리 건 상세의 **「발주서」 탭이 없어진다.**"
  say "  · 견적서 [저장]을 눌러도 **PDF 로 안 바뀐다**(엑셀만 들어간다)."
  say "  · 결재 탭 · 보고서 탭의 **공유폴더 구역이 없어진다.**"
  say "  · 🔴 **도우미는 그대로 두세요.** 세대 3 도우미는 2.3 에서도 해를 끼치지"
  say "    않는다 — 다만 발주서 루트를 안 쓰게 될 뿐이다."
  say "  · 🔴 되돌려도 **공유폴더의 파일은 하나도 안 바뀐다** — 이 판이 거기에"
  say "    쓴 것이 없다(발주서는 읽기 전용이었다)."

  step "5. 지금 상태"
  say "  dss-as : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep '^dss-as ' || echo '안 돌고 있다')"
  say "  dss-po : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep '^dss-po ' || echo '안 돌고 있다')"
  say "  (포털 · 계측기 · 개선요청 · 휴가 · DB 둘은 이번에 건드리지 않았다.)"
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터 check · preload · force-load · go ═════════════════════════
echo "DSS 열일곱째 배포 · 2026-10-12 · $(date '+%F %T')"
echo "  🔴 올라가는 것은 **둘**:  $OLD_AS → $TAG_AS · $OLD_PO → $TAG_PO"
echo "  🔴 멈추는 것도 **둘**:  dss-as · dss-po"
echo "  🔴 이번 판의 중심: 수리 건 상세의 **발주서 탭** · 견적서 [저장] **PDF 변환**"
echo "     · 결재/보고서 탭의 **공유폴더 구역** · 공유폴더 창이 **표**로"
echo "  🔵 **마이그레이션 0건** — 운영 DB 는 115 그대로 (DB 를 안 건드린다)"
echo "  🔴 **새 볼륨 하나**(발주서 · 읽기 전용) · **.env 일곱 줄**(as.env 둘 · po.env 다섯) · **양식 두 벌**"
echo "  🔵 도구 이미지 그대로 ($KEEP_ASTOOLS — 이번엔 할 일 자체가 없다)"
echo "  🔵 야간 백업은 **02:30** — 자정 넘어 돌리면 백업 검사에 걸립니다"
echo "  · 건드리지 않는 여덟 — $KEEP_AUTH · $KEEP_ASTOOLS · $KEEP_METERS"
echo "    · $KEEP_METERSTOOLS · $KEEP_IMP · $KEEP_IMPTOOLS"
echo "    · $KEEP_LEAVE · $KEEP_LEAVETOOLS"
if ! pinned; then
  echo "  ⚠️ 🔴 **이미지 기대값 여섯이 비어 있습니다.**"
  echo "     개발 PC 에서 2.4 · 0.4 를 굽고 재어 채우기 전에는 --go 가 시작하지 않습니다."
  echo "     재는 차례는 이 파일 머리말 「돌리기 전에 — 값 여섯을 채워야 한다」."
fi
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**"
              echo "     🔵 아직 안 온 것 · 안 실린 것은 ⚠️ 로만 말한다(✗ 가 아니다)." ;;
  preload)    echo "  🔵 --preload — 새 이미지 둘을 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — A/S · PO 를 교체한다. **DB 는 안 바꾼다.**"
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(폴더 권한 · 백업)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "새 이미지 tar 둘 · 지문"
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  EXP_PO=$(tar_config_id "$TAR_PO" 2>/dev/null) || EXP_PO=""
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS" "$SZ_AS" "$MD5_AS" "$WANT_CFG_AS" dss-as-2.4.tar
  see_tar "$TAG_PO" "$TAR_PO" "$EXP_PO" "$SZ_PO" "$MD5_PO" "$WANT_CFG_PO" dss-po-0.4.tar
  if [ -s "$TAR_AS" ] && [ -n "$EXP_AS" ]; then
    bring_img "$TAG_AS" "$TAR_AS" "$EXP_AS"
  else
    bad "$TAG_AS 를 싣지 않았다 — tar 가 없거나 manifest.json 을 못 읽었다"
  fi
  if [ -s "$TAR_PO" ] && [ -n "$EXP_PO" ]; then
    bring_img "$TAG_PO" "$TAR_PO" "$EXP_PO"
  else
    bad "$TAG_PO 를 싣지 않았다 — tar 가 없거나 manifest.json 을 못 읽었다"
  fi

  # 🔴 실어 놓고 **안을 본다.**
  step "새 이미지 안에 이번 판이 들어 있는가"
  if have_img "$TAG_AS"; then
    inside_check "$TAG_AS" "A/S" "$OLD_AS" \
      "$AS_MARK1" "$AS_MARK2" "$AS_MARK3" "$AS_MARK4" "$AS_KEEP" "$AS_CTRL"
    ocr_check "$TAG_AS"
  fi
  if have_img "$TAG_PO"; then
    inside_check "$TAG_PO" "PO" "$OLD_PO" \
      "$PO_MARK1" "$PO_MARK2" "$PO_MARK3" "$PO_MARK4" "$PO_KEEP" "$PO_CTRL"
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
      echo "  ✅ 이어서 (A/S · PO 가 잠깐 멈춥니다. DB 는 안 바뀝니다):  bash $0 --go"
      echo "     🔴 --go 는 오늘 백업($AS_DB)이 없으면 **시작하자마자 멈춥니다.**"
      echo "     🔵 야간 백업은 02:30 입니다 — 먼저 손으로 뜨려면:"
      echo "          bash /volume1/dss/jobs/backup-nightly.sh"
    else
      echo "  🔴 아직 --go 를 부를 수 없습니다 — 이미지 기대값 여섯이 비어 있습니다."
      echo "     개발 PC 에서 굽고 재어 이 파일에 채운 뒤 다시 올리세요."
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
  say "  ║ 🔴 이미지 기대값 여섯이 **비어 있습니다.** 재지 않은 이미지를    ║"
  say "  ║    운영에 올리지 않습니다.                                     ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  stop "아무것도 바꾸지 않았습니다. 앱도 DB 도 그대로입니다."
}

# ── 2. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ───────────
step "2. 새 이미지 둘 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
[ -n "$EXP_AS" ] || stop "A/S tar 에서 지문을 못 읽었습니다. **아무것도 바꾸지 않았습니다.**"
[ -n "$EXP_PO" ] || stop "PO tar 에서 지문을 못 읽었습니다. **아무것도 바꾸지 않았습니다.**"
bring_img "$TAG_AS" "$TAR_AS" "$EXP_AS" || {
  say "  🔴 A/S 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
}
bring_img "$TAG_PO" "$TAR_PO" "$EXP_PO" || {
  say "  🔴 PO 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
}

# ══ 3. 🔴 멈추기 전에 — 백업 · 스냅숏 · 설정 · 양식 · 시작 시각 ════════
#
# 🔴 여기까지가 「돌이킬 수 있는 자리」다. 앱은 아직 옛 판으로 **살아 있다.**

# ── 3-ㄱ. 🔴 오늘 백업을 **지금 다시** 찾는다. 없으면 멈춘다 ───────────
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
  cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  say "     ✓ $AS_DB 줄이 찍혀야 합니다. 그 뒤에 다시:"
  cmd "bash $0 --go"
  stop "백업 없이 교체하지 않습니다. **앱도 DB 도 그대로입니다.**"
fi

# ── 3-ㄴ. 첨부 하드링크 스냅숏 · .env 사본 둘 ──────────────────────────
#
# 🔵 **DB 덤프는 뜨지 않는다** — 이번 판은 DB 를 바꾸지 않는다(18 · 20번과 같다).
step "3-ㄴ. 첨부 하드링크 스냅숏 · .env 사본 둘 (DB 덤프는 뜨지 않는다)"
BK=$BKD/predeploy-$STAMP
mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
if [ -d "$ATT" ]; then
  cp -al "$ATT" "$BK/as-attachments" 2>/dev/null \
    && ok "첨부 스냅숏 (cp -al 하드링크 — 즉시 · 공간 0) → $BK" \
    || bad "첨부 스냅숏 실패"
else
  bad "첨부 폴더가 없다: $ATT"
fi
if [ -f "$AS_ENV" ]; then
  cp -p "$AS_ENV" "$BKD/as.env.$STAMP"; chmod 600 "$BKD/as.env.$STAMP"
  ok "as.env 사본 — backups/as.env.$STAMP (root 600)"
else
  bad "as.env 가 없다: $AS_ENV"
  stop "설정 파일이 없습니다. **앱도 DB 도 그대로입니다.**"
fi
if [ -f "$PO_ENV" ]; then
  cp -p "$PO_ENV" "$BKD/po.env.$STAMP"; chmod 600 "$BKD/po.env.$STAMP"
  ok "po.env 사본 — backups/po.env.$STAMP (root 600)"
else
  bad "po.env 가 없다: $PO_ENV"
  stop "설정 파일이 없습니다. **앱도 DB 도 그대로입니다.**"
fi
say "  🔵 공유폴더 다섯(견적서 · 현황표 · 연락서 · 수리 관련 · 발주서)은 **스냅숏을"
say "     뜨지 않는다** — 직원의 서류함이라 우리가 사본을 만들 자리가 아니다."
say "     NAS 의 야간 백업이 본다."

# ── 3-ㄷ. 🔴 새 공유폴더가 **읽히고, 쓰기가 막혀 있는가** ──────────────
step "3-ㄷ. 발주서 공유폴더 — 읽기 · 쓰기 막힘 시험 (uid 1000 · gid 100)"
say "  🔴 여기는 /volume1/dss 가 아니라 **직원이 탐색기로 쓰는 서류함**이다."
say "     ACL 을 걷지 않는다 — 걷으면 직원의 접근이 끊긴다."
say "  🔴 이 기능은 **읽기만** 한다 — 쓰기가 되면 오히려 ✗ 다."
if [ ! -d "$PO_SRC" ]; then
  bad "발주서 폴더가 없다"
  say "    → 🔴 「5_ 외자 PO」 의 PO 가 **대문자**인지 보세요."
  cmd "ls -d /volume1/5_*"
  stop "경로를 확인하세요. **앱도 DB 도 그대로입니다.**"
fi
ok "폴더가 있다"
probe_new_volume "$PO_SRC" "$PO_MNT" "발주서 공유폴더" \
  || stop "새 볼륨이 기대한 모습이 아닙니다. **앱도 DB 도 그대로입니다.**"

# ── 3-ㄹ. 🔴 as.env 둘 · po.env 다섯을 덧붙인다 ───────────────────────
#
# 🔴 이 PC 의 .env 를 올리는 것이 아니다. **NAS 의 파일을 읽고 없는 줄만**
#    덧붙인다. 이미 있으면 **값이 같은지 보고** 다르면 멈춘다.
# 🔴 po.env 의 다섯은 **전부 as.env 에서 읽은 값**이다 — 지어내지 않는다.
#    🔴 as.env 는 **읽기만** 한다(발주서 두 줄을 더하는 것 말고는 안 고친다).
step "3-ㄹ. as.env 에 **두 줄** · po.env 에 **다섯 줄** 덧붙이기"
build_env_values
po_required_values_ok \
  || stop "as.env 에서 PO 로 옮길 값을 못 읽었습니다. **아무것도 안 바꿨습니다.**"
# 🔴 견적서 셋 · 현황표 다섯 · 연락서 셋 · 수리관련 둘이 **적기 전에** 그대로인가.
for k in $QUOTE_KEYS $PORTAL_KEYS $CONTACT_KEYS $REPAIR_KEYS; do
  grep -q "^$k=" "$AS_ENV" || {
    bad "$k 가 as.env 에 없다 — 🔴 누가 덮어썼다"
    stop "as.env 가 온전하지 않습니다. 덧붙이지 않았습니다. **앱도 DB 도 그대로입니다.**"
  }
done
ok "as.env 의 열세 줄이 그대로 있다 — 덧붙여도 안전하다"
append_env_keys() { # 1 파일 2 라벨 3 "키 …" 4 머리주석
  local f="$1" label="$2" keys="$3" note="$4" k v added=0
  for k in $keys; do
    v=$(env_verdict "$f" "$k")
    case "$v" in
      DIFF)
        bad "🔴 $label · $k 가 **이미 있는데 값이 다르다**"
        say "      지금 값:  $(env_val_of "$f" "$k")"
        say "      넣을 값:  $(want_env_value "$k")"
        return 1 ;;
      DUP)
        bad "🔴 $label · $k 가 **두 줄 이상** 있다"
        return 1 ;;
    esac
  done
  [ -n "$(tail -c 1 "$f")" ] && printf '\n' >> "$f"
  for k in $keys; do
    if [ "$(env_verdict "$f" "$k")" != ADD ]; then
      say "  · $label · $k 는 **이미 있고 값도 같다** — 건드리지 않는다"
      continue
    fi
    if [ "$added" = 0 ]; then
      printf '\n# ── %s — %s 21-deploy.sh 가 덧붙임 ──\n' "$note" "$TODAY" >> "$f"
    fi
    printf '%s=%s\n' "$k" "$(want_env_value "$k")" >> "$f"
    added=$((added + 1))
    ok "$label · $k 덧붙였다"
  done
  chown root:root "$f"; chmod 600 "$f"
  if [ "$added" = 0 ]; then
    ok "$label · 더할 줄이 없었다 — 한 글자도 안 바꿨다"
  else
    ok "$label · ${added}줄을 덧붙였다 (모드 600 · root:root 로 되돌렸다)"
  fi
  return 0
}
append_env_keys "$AS_ENV" "as.env" "$AS_NEW_KEYS" "발주서 서류 공유폴더" \
  || stop "as.env 가 기대한 모습이 아닙니다. **덧붙이지 않았고 앱도 DB 도 그대로입니다.**"
[ "$ALT_IN_AS" = 1 ] \
  || say "  ⚠️ $PO_ALT_KEY 는 as.env 에 줄이 없어 po.env 에도 **안 적는다**(지어내지 않는다)"
append_env_keys "$PO_ENV" "po.env" "$PO_KEYS_EFF" "도우미 설치본에 심을 공유폴더 루트 다섯" \
  || stop "po.env 가 기대한 모습이 아닙니다. **앱도 DB 도 그대로입니다.**"
# 🔴 이 줄들은 **폴더 경로**다 — 비밀이 아니고, 사람이 눈으로 맞춰 봐야 하는
#    값이라 그대로 찍는다. 다른 줄은 한 글자도 찍지 않는다.
say "  지금 들어 있는 줄 (값까지 그대로):"
for k in $AS_NEW_KEYS; do
  printf '      as.env  %s\n' "$(grep "^$k=" "$AS_ENV" | head -1)"
done
for k in $PO_KEYS_EFF; do
  printf '      po.env  %s\n' "$(grep "^$k=" "$PO_ENV" | head -1)"
done
# 🔴 다섯이 **as.env 와 글자까지 같은가** — 여기서 한 번 더 본다(파일로).
for k in $PO_KEYS_EFF; do
  if [ "$(env_val_of "$AS_ENV" "$k")" = "$(env_val_of "$PO_ENV" "$k")" ]; then
    ok "$k 가 as.env 와 po.env 에서 **글자까지 같다**"
  else
    bad "🔴 $k 가 as.env 와 po.env 에서 **다르다** — 설치 화면에 따라 갈린다"
  fi
done
say "  🔴 호스트 토막의 출처: $ENV_SRC_NOTE → $ENV_HOST ($ENV_HOST_WHY)"

# ── 3-ㅁ. 🔴 매쳐 견적서 양식 두 벌을 바꾼다 ───────────────────────────
#
# 🔴 **지우지 않는다. 옆에 치워 둔다.**
step "3-ㅁ. 매쳐 견적서 양식 두 벌 바꾸기 (옛 양식은 치워 둔다)"
BKT=$BKD/as-templates-$STAMP
mkdir -p "$BKT"; chown root:root "$BKT"; chmod 700 "$BKT"
TPL_CHANGED=0
case "$TPL1_STATE" in
  DONE)  ok "「$TPL1_NAME」 은 이미 새 양식이다 — 바꿀 것이 없다" ;;
  READY) swap_tpl "$TPL1_NAME" "$TPL1_SRC" "$TPL1_MD5" "$BKT" \
           && TPL_CHANGED=$((TPL_CHANGED + 1)) \
           || stop "양식을 바꾸다 어긋났습니다. 백업은 $BKT 입니다. **앱은 그대로 돕니다.**" ;;
  *)     bad "🔴 「$TPL1_NAME」 의 새 파일이 준비되지 않았다"
         stop "양식이 준비되지 않았습니다. **아무것도 안 바꿨습니다.**" ;;
esac
case "$TPL2_STATE" in
  DONE)  ok "「$TPL2_NAME」 은 이미 새 양식이다 — 바꿀 것이 없다" ;;
  READY) swap_tpl "$TPL2_NAME" "$TPL2_SRC" "$TPL2_MD5" "$BKT" \
           && TPL_CHANGED=$((TPL_CHANGED + 1)) \
           || stop "양식을 바꾸다 어긋났습니다. 백업은 $BKT 입니다. **앱은 그대로 돕니다.**" ;;
  *)     bad "🔴 「$TPL2_NAME」 의 새 파일이 준비되지 않았다"
         stop "양식이 준비되지 않았습니다. **아무것도 안 바꿨습니다.**" ;;
esac
say "  🔵 바꾼 양식 ${TPL_CHANGED}벌. 옛 양식: $BKT"
say "  🔴 **A/S 와 PO 가 같은 폴더를 읽는다** — 두 사이트가 함께 새 양식을 쓴다."

# ── 3-ㅂ. 건드리지 않는 쪽의 **시작 시각**을 적어 둔다 ─────────────────
step "3-ㅂ. 건드리지 않는 쪽의 시작 시각을 적어 둔다 (뒤에서 대조한다)"
KEEP_BOXES="dss-auth dss-meters dss-improvements dss-leave dss-pg-app dss-pg-auth"
STARTED_BEFORE=""
for t in $KEEP_BOXES; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  STARTED_BEFORE="$STARTED_BEFORE$t=$s
"
  say "  · $t  시작 ${s:-?}"
done
say
say "  🔴 이제 A/S 와 PO 를 바꿔 끼웁니다. 그만두려면 **20초 안에 Ctrl+C**."
say "     지금 Ctrl+C 하면 직원은 $OLD_AS · $OLD_PO 를 그대로 쓰고 있습니다."
say "     (compose · .env · 양식은 이미 바뀌었지만 그것만으로는 아무 일도"
say "      일어나지 않습니다 — 옛 컨테이너가 그대로 돌고 있습니다.)"
sleep 20

# ══ 4. 둘을 새 판으로 바꿔 끼운다 — 🔴 여기 하나가 정지 창이다 ═════════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다. --no-deps 로 **이름을 적은 둘만** 부른다.
step "4. 새 이미지로 바꿔 끼운다 (A/S · PO)  ⏱ 여기부터 정지 창"
say "  🔴 **멈추는 것은 dss-as 와 dss-po 둘뿐이다.**"
say "     그대로 도는 것: 포털 · 계측기 · 개선요청 · 휴가 · DB 둘."
say "  🔵 둘을 **한 번에** 부른다 — 나눠 부르면 정지 창이 그만큼 길어진다."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"
"${COMPOSE[@]}" up -d --no-deps app-as app-po 2>&1 | sed 's/^/    /'
wait_http "A/S" "$AS_PORT" / dss-as
wait_http "PO"  "$PO_PORT" / dss-po
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 5. 스모크 ══════════════════════════════════════════════════════════
step "5. 스모크 — 폴더 · 양식 · 설정 · 알림 · 권한 · 안 멈췄는가 · 바깥 주소"

# 5-ㄱ. 새 컨테이너로 폴더를 **실제로 열어 본다**
say "  5-ㄱ. 폴더를 새 컨테이너 안에서 실제로 연다"
probe_svc app-as dss-as "A/S" "/data:rw /templates:ro" "$ATT $TEMPLATES"
probe_svc app-po dss-po "PO"  "/data:rw /templates:ro" "$ATT $TEMPLATES"

say "  5-ㄴ. 공유폴더 다섯 — 🔴 **새로 붙은 발주서**가 진짜로 보이는가"
if running dss-as; then
  "$DOCKER" exec dss-as sh -c 'ls -1 /quote-archive >/dev/null 2>&1' \
    && ok "A/S 가 견적서 공유폴더를 읽는다" \
    || { bad "A/S 가 견적서 공유폴더를 **못 읽는다** — 발행이 실패한다"
         say "    🔴 여기는 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기가 끊긴다."; }
  "$DOCKER" exec dss-as sh -c "ls -1 '$PORTAL_MNT' >/dev/null 2>&1" \
    && ok "A/S 가 현황표 공유폴더를 읽는다" \
    || bad "A/S 가 $PORTAL_MNT 를 **못 읽는다** — 🔴 [공유폴더에 저장]이 죽는다"
  "$DOCKER" exec dss-as sh -c "ls -1 '$CONTACT_MNT' >/dev/null 2>&1" \
    && ok "A/S 가 연락서 공유폴더를 읽는다" \
    || bad "A/S 가 $CONTACT_MNT 를 **못 읽는다** — 🔴 연락서 [폴더 열기]가 죽는다"
  # 🔴 연락서는 **여전히 쓸 수 있어야** 한다 (18번이 연 자리).
  if "$DOCKER" exec dss-as sh -c "t='$CONTACT_MNT/.dss-write-test'; : > \"\$t\" && rm -f \"\$t\"" >/dev/null 2>&1; then
    ok "🔴 연락서 공유폴더는 **아직 쓸 수 있다**"
  else
    bad "🔴 연락서 공유폴더에 **못 쓴다** — 폴더 자동 생성 · 사본 꽂기가 죽는다"
  fi
  # 🔴 「수리 관련」과 발주서는 **쓰기가 막혀 있어야** 맞다.
  for rec in "$REPAIR_MNT|수리 관련" "$PO_MNT|발주서"; do
    t=$(printf '%s' "$rec" | cut -d'|' -f1)
    p=$(printf '%s' "$rec" | cut -d'|' -f2)
    n_in=$("$DOCKER" exec dss-as sh -c "ls -1 '$t' 2>/dev/null | wc -l" 2>/dev/null | tr -d ' ')
    if [ "${n_in:-0}" -ge 1 ] 2>/dev/null; then
      ok "A/S 가 「$p」 공유폴더를 읽는다 (맨 위 칸 ${n_in}개)"
    else
      bad "🔴 A/S 가 $t 에서 **0개**를 본다 — 빈 폴더가 붙었다"
      say "    → 경로의 **대소문자**를 보세요(2_AS센터 · 5_ 외자 PO)."
    fi
    if "$DOCKER" exec dss-as sh -c "t='$t/.dss-ro-test'; : > \"\$t\"" >/dev/null 2>&1; then
      bad "🔴 $t 에 **쓸 수 있다** — read_only 가 안 먹었다"
      "$DOCKER" exec dss-as sh -c "rm -f '$t/.dss-ro-test'" >/dev/null 2>&1
      say "    🔵 시험 파일은 곧바로 지웠다 — 남아 있으면 알려 주세요."
    else
      ok "🔴 $t 는 **쓰기가 막혀 있다** (읽기 전용 그대로다)"
    fi
  done
  # 🔴 발주서 폴더 안에 연도 폴더가 보이는가 — 자리가 맞는지의 증거.
  n_in=$("$DOCKER" exec dss-as sh -c "ls -1 '$PO_MNT' 2>/dev/null | grep -c '^[12][0-9][0-9][0-9]\$'" 2>/dev/null | tr -d ' ')
  [ "${n_in:-0}" -ge 1 ] 2>/dev/null \
    && ok "발주서 폴더 안에 연도 폴더가 ${n_in}개 보인다 — 자리가 맞다" \
    || bad "🔴 발주서 폴더에 연도 폴더(2026 꼴)가 **없다** — 한 칸 위나 아래다"
else
  bad "dss-as 컨테이너가 떠 있지 않다"
fi
if running dss-po; then
  "$DOCKER" exec dss-po sh -c 'ls -1 /quote-archive >/dev/null 2>&1' \
    && ok "PO 가 견적서 공유폴더를 읽는다" \
    || bad "PO 가 견적서 공유폴더를 **못 읽는다** — 발행이 실패한다"
  "$DOCKER" exec dss-po sh -c "ls -1 '$PO_MNT' >/dev/null 2>&1" \
    && say "    ⚠️ PO 에도 $PO_MNT 가 붙어 있다 (없어도 되는 자리다)" \
    || ok "PO 에는 발주서 볼륨이 **안 붙었다** (맞다 — 그 화면이 없다)"
else
  bad "dss-po 컨테이너가 떠 있지 않다"
fi

# 5-ㄷ. 🔴 양식이 **컨테이너 안에서** 새것인가 (만든 것과 도는 것은 다르다)
say "  5-ㄷ. 🔴 매쳐 양식 두 벌이 **컨테이너 안에서** 새것인가"
for c in dss-as dss-po; do
  running "$c" || { bad "$c 가 안 돌고 있어 양식을 못 봤다"; continue; }
  for rec in "$TPL1_NAME|$TPL1_MD5" "$TPL2_NAME|$TPL2_MD5"; do
    t=$(printf '%s' "$rec" | cut -d'|' -f1)
    p=$(printf '%s' "$rec" | cut -d'|' -f2)
    s=$("$DOCKER" exec "$c" sh -c "md5sum '/templates/$t' 2>/dev/null | cut -d' ' -f1" 2>/dev/null | tr -d ' \r')
    if [ "$s" = "$p" ]; then
      ok "$c · 「$t」 가 새 양식이다 (md5 맞음)"
    else
      bad "🔴 $c · 「$t」 의 md5 가 ${s:-못 읽음} 다 — 기대 $p"
      say "    🔴 직인이 안 찍히는 옛 양식일 수 있습니다. 백업: $BKT"
    fi
  done
done

# 5-ㄹ. 🔴 설정이 컨테이너 안까지 그대로 왔는가
say "  5-ㄹ. 🔴 설정이 컨테이너 안까지 그대로 왔는가 (역슬래시까지 센다)"
if running dss-as; then
  for k in QUOTE_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT \
           CONTACT_FOLDER_ARCHIVE_UNC_ROOT REPAIR_DOCS_ARCHIVE_UNC_ROOT \
           PURCHASE_ORDER_ARCHIVE_UNC_ROOT; do
    v=$("$DOCKER" exec dss-as printenv "$k" 2>/dev/null)
    if [ -n "$v" ]; then
      ok "A/S · $k 가 컨테이너 안에 그대로 있다"
      n=$(backslash_count "$v")
      [ "${n:-0}" -ge 4 ] && ok "A/S · $k 의 역슬래시 ${n}개 — 삼켜지지 않았다" \
        || bad "A/S · $k 의 역슬래시가 ${n:-0}개뿐이다 — 🔴 따옴표가 먹은 것이다"
    else
      bad "A/S · $k 가 컨테이너 안에 **없다** — 🔴 그쪽 [폴더 열기]가 죽는다"
    fi
  done
  "$DOCKER" exec dss-as sh -c "[ -d \"\$PURCHASE_ORDER_ARCHIVE_DIR\" ]" >/dev/null 2>&1 \
    && ok "🔴 PURCHASE_ORDER_ARCHIVE_DIR 이 **실제로 있는 폴더**를 가리킨다" \
    || bad "🔴 PURCHASE_ORDER_ARCHIVE_DIR 이 가리키는 폴더가 컨테이너 안에 없다"
  "$DOCKER" exec dss-as sh -c "[ -d \"\$REPAIR_DOCS_ARCHIVE_DIR\" ]" >/dev/null 2>&1 \
    && ok "REPAIR_DOCS_ARCHIVE_DIR 이 **실제로 있는 폴더**를 가리킨다" \
    || bad "REPAIR_DOCS_ARCHIVE_DIR 이 가리키는 폴더가 컨테이너 안에 없다"
  "$DOCKER" exec dss-as sh -c "[ -d \"\$CONTACT_FOLDER_ARCHIVE_DIR\" ]" >/dev/null 2>&1 \
    && ok "CONTACT_FOLDER_ARCHIVE_DIR 이 **실제로 있는 폴더**를 가리킨다" \
    || bad "CONTACT_FOLDER_ARCHIVE_DIR 이 가리키는 폴더가 컨테이너 안에 없다"
else
  bad "dss-as 컨테이너가 떠 있지 않다 — 설정을 못 봤다"
fi
if running dss-po; then
  # 🔴 도우미 설치본이 심는 **루트 다섯**이 PO 컨테이너 안에 다 왔는가.
  for k in $PO_REQUIRED_KEYS; do
    v=$("$DOCKER" exec dss-po printenv "$k" 2>/dev/null)
    if [ -n "$v" ]; then
      n=$(backslash_count "$v")
      [ "${n:-0}" -ge 4 ] && ok "PO · $k 가 있고 역슬래시 ${n}개 — 삼켜지지 않았다" \
        || bad "PO · $k 의 역슬래시가 ${n:-0}개뿐이다 — 🔴 따옴표가 먹은 것이다"
    else
      bad "PO · $k 가 컨테이너 안에 **없다** — 🔴 PO 에서 설치한 도우미가 그 폴더를 못 연다"
    fi
  done
  if [ "$ALT_IN_AS" = 1 ]; then
    v=$("$DOCKER" exec dss-po printenv "$PO_ALT_KEY" 2>/dev/null)
    if [ -n "$v" ]; then
      n=$(backslash_count "$v")
      [ "${n:-0}" -ge 4 ] && ok "PO · $PO_ALT_KEY 가 있고 역슬래시 ${n}개" \
        || bad "PO · $PO_ALT_KEY 의 역슬래시가 ${n:-0}개뿐이다"
    else
      say "    🔵 PO · $PO_ALT_KEY 가 **비어 있다** — as.env 쪽도 그렇다. 도우미는"
      say "       빈 값을 건너뛰므로(resolveQuoteFolderHelperInstallRoots) 양쪽이 같다."
    fi
  fi
  # 🔴 **다섯이 A/S 와 글자까지 같은가** — 다르면 설치 화면에 따라 갈린다.
  #    🔵 2026-10-07 결정(「도우미는 두 사이트가 똑같이」)이 여기서 완성된다.
  for k in $PO_NEW_KEYS; do
    if [ "$("$DOCKER" exec dss-as printenv "$k" 2>/dev/null)" \
       = "$("$DOCKER" exec dss-po printenv "$k" 2>/dev/null)" ]; then
      ok "🔴 $k 가 A/S 와 PO 에서 **글자까지 같다**"
    else
      bad "🔴 $k 가 A/S 와 PO 에서 **다르다** — 어느 화면에서 설치했는가로 갈린다"
    fi
  done
fi

say "  5-ㅁ. 알림 통로 · 알림 링크의 주소 (A/S 만)"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 \
       "http://127.0.0.1:$AS_PORT/api/integration/notifications" 2>/dev/null)
case "$code" in
  404) bad "A/S 의 /api/integration/notifications 가 404 다 — **옛 이미지다**" ;;
  000|"") bad "A/S 의 알림 통로가 대답하지 않는다 (${code:-없음})" ;;
  *)   ok "A/S 의 알림 통로가 있다 (토큰 없이 부르면 401 이 맞다 — 지금 $code)" ;;
esac
notify_href_check "A/S" dss-as "$AS_ENV" "https://as.dss21.co.kr"

say "  5-ㅂ. 권한 — 교체 뒤에 다시 읽는다 (🔴 select 만)"
perm_check

# 5-ㅅ. 🔴 건드리지 않는 쪽이 **정말 안 멈췄는가** — 시작 시각으로 본다
say "  5-ㅅ. 🔴 건드리지 않는 쪽이 안 멈췄는가 (시작 시각을 대조한다)"
for t in $KEEP_BOXES; do
  before=$(printf '%s\n' "$STARTED_BEFORE" | sed -n "s/^$t=//p" | head -1)
  after=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  if [ -n "$before" ] && [ "$before" = "$after" ]; then
    ok "$t · 시작 시각 그대로 — **한 번도 안 멈췄다**"
  else
    bad "🔴 $t 의 시작 시각이 바뀌었다 ($before → $after) — 이 배포가 건드렸다"
  fi
done

say "  5-ㅇ. 바깥 주소 여섯"
for h in as po; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code (바뀐 쪽)" ;;
    *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
  esac
done
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
echo "  🔵 마이그레이션 **0건** — 운영 DB 는 115 그대로입니다"
echo "  🔴 .env **일곱 줄**(as.env 둘 · po.env 다섯) · 양식 **${TPL_CHANGED}벌** 바꿨습니다"
echo "  첨부 스냅숏: $BK"
echo "  .env 사본: $BKD/as.env.$STAMP · $BKD/po.env.$STAMP"
echo "  옛 양식:   $BKT"
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
║ 🔴 **사람이 바로 할 일 — 도우미를 전원이 다시 깔아야 합니다(세대 3)** ║
╚════════════════════════════════════════════════════════════════════╝

  🔴 이번 세대 올림은 성질이 다릅니다. 세대 1→2 때 옛 도우미는 **조용히
     아무것도 안 했지만**, **세대 2 도우미는 「탭이 섞인 틀린 PDF」를 만들어
     냅니다** — 조용한 실패가 아니라 **잘못된 결과물**입니다.
  🔴 **설치 명령은 A/S 화면에서만** 받으세요. PO 화면에서 받으면 그 PC 의
     현황표 · 연락서 [폴더 열기]가 죽습니다(도우미는 PC 당 한 벌입니다).
     받는 길: A/S → 수리 건 상세 → [폴더 열기] → [설치 명령 복사] →
              PowerShell 창에 붙여넣기 (관리자 권한 필요 없음).

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. 🔴 **수리 건 상세의 「발주서」 탭** — 그 장비의 발주서 폴더가 보입니까.
      · 「발주서가 하나도 없다」만 뜬다면 **볼륨 경로의 대소문자**가 먼저입니다
        (5_ 외자 **PO** — 스크립트가 5-ㄴ 에서 이미 세어 보긴 했습니다).
      · [폴더 열기]가 실제로 탐색기를 엽니까 — **도우미를 다시 깐 PC 에서**.

   2. 🔴 **매쳐 견적서를 한 장씩 뽑아 직인을 보세요** — 내자 · O/H **둘 다**.
      🔴 O/H 는 그동안 **직인이 아예 안 찍히고 있었습니다.** 이번 교체의
         중심입니다. A/S 와 PO **양쪽에서** 한 장씩 뽑아 보세요(같은 양식입니다).

   3. **견적서 [저장]** — 팝업이 뜨고 「완료되었습니다」로 끝납니까.
      · 🔴 내자 견적서는 **내자 탭만**, OH 는 **OH 탭만** PDF 에 들어갑니까.

   4. **견적서 결재 탭 · 보고서 탭의 공유폴더 구역** · 목록의 **승인 체크**.
      · 🔴 승인 뒤 고친 장(APPROVED_OUTDATED)에는 체크가 **없어야** 맞습니다.

   5. **공유폴더 창이 표로** 보입니까 — 이름 · 수정날짜 · 크기 · 동작.

   6. 🔵 그대로여야 하는 것 — 견적서 · 현황표 · 연락서 · 「수리 관련」
      [폴더 열기] 넷. (스크립트가 5-ㄴ 에서 읽기·쓰기를 이미 확인했습니다.)

   7. 🔵 **포털 · 계측기 · 개선요청 · 휴가가 그대로입니까** — 이번 판은
      그 넷을 건드리지 않았습니다. (스크립트가 5-ㅅ 에서 시작 시각으로 이미
      확인했습니다.)

🔴 사람이 이어서 할 일:
  · **도우미 재설치를 전원에게 알립니다**(위 상자 · 세대 3).
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.
  · 내일 아침 백업을 한 번 더 보세요 — 다섯이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -7
  · 첨부 스냅숏은 $BK 에 있습니다. 한 주쯤 두었다 지우세요.
  · 옛 양식 두 벌은 $BKT 에 있습니다. **지우지 마세요** — 한 달쯤 둡니다.

되돌리기 안내:  bash $0 --rollback
  🔵 **DB 는 되돌릴 것이 없습니다** — 이번 판은 안 바꿨습니다.
  🔴 compose 는 **사본으로** 되돌립니다(발주서 볼륨이 들어갔습니다).
  🔴 양식은 되돌리지 마세요 — 되돌리면 **직인 빠진 견적서**로 돌아갑니다.
ANNOUNCE
exit "$FAIL"
