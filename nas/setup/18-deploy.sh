#!/bin/bash
# /volume1/dss/setup/18-deploy.sh — 2026-10-05 열넷째 배포
#
# ── 무엇이 올라가는가 ───────────────────────────────────────────────────
#   사내 사이트 여섯 중 **하나**만 올린다.
#
#     A/S  dss-as:2.0  →  **dss-as:2.1**
#
#   나머지 다섯(포털 1.5 · 계측기 1.3 · 개선요청 0.3 · PO 0.3 · 휴가 0.1)은
#   **건드리지 않는다. 멈추지도 않는다.**
#
#   17번과 다른 것 셋 — 이번 판의 성격이 여기 다 있다:
#     · 🔴 **마이그레이션이 0건이다.** 운영 DB 는 112 그대로다(아래 ①).
#     · 🔴 **새 볼륨이 하나 는다** — 연락서 공유폴더(아래 ②). 16번에서 가져왔다.
#     · 🔴 **as.env 에 설정 셋을 덧붙인다**(아래 ③). 이것도 16번에서 가져왔다.
#   그리고 17번과 같은 것 하나: **도구 이미지를 다시 굽지 않았다**(dss-as-tools:1).
#
# ── 이 판에 무엇이 담겼나 (사람에게 설명할 말로) ────────────────────────
#
#   10/5 새벽부터 밤까지 쌓인 **커밋 12개**(b2dfde8 ~ 9a6ba31)다. 줄기는 둘이다.
#
#   ① **연락서 공유폴더 연동** — 커밋 11개. 이 판의 거의 전부다.
#      직원이 수년째 탐색기로 쓰던 서류함을 화면에서 그대로 쓰게 했다.
#        · 수리 건 상세에 [폴더 열기] — 🔴 **찾는 열쇠는 인수번호 하나뿐**이다.
#          (모델·S/N 으로 짝지으면 같은 장비의 **지난번 수리 건**에 들어간다.)
#        · 폴더가 없으면 **사람이 한 번 더 눌러** 만든다. 비슷한 폴더가 이미
#          있으면 만들지 않고 목록을 보여 준다 — 앱이 고르지 않는다.
#        · 🔴 **접수하면 폴더가 저절로 생긴다.** 막는 것은 인수번호 하나뿐이고,
#          만들기가 실패해도 **접수는 그대로 된다**(곁다리다).
#        · 파일 관리 화면에 「공유폴더」 구역 — 폴더 안을 보여 주고 **하위 폴더로
#          들어간다.** 파일을 **눌러서 연다**(허용 목록에 든 것만 · 검사 일곱).
#        · 올린 첨부의 **사본**을 그 폴더의 분류 폴더에 꽂는다(사람이 읽는 이름으로,
#          덮어쓰지 않고 ` (2)` 로 비켜 간다).
#        · 폴더 안에 `DATA` 폴더를 두고 [DATA에 저장]으로 꽂는다 — 여러 개도 낱개로.
#      🔵 **DB 스키마가 0 이다.** 남기는 기록은 `audit_logs` 한 줄
#         (`CREATE` · `repair_case_contact_folder`)뿐이고, 그 표도 칸도 이미 있다.
#
#   ② **주간보고 「현 상태」를 블록 단위로 고친다** — 커밋 1개.
#      머리줄의 [수정] 하나가 그 블록을 연다. 17번이 올린 「현 상태 바로 바꾸기」의
#      잔손질이다. 🔴 단계·권한·이력이 타는 길은 **그대로**다 — 새 길을 내지 않았다.
#
# ══ 🔴 ① 마이그레이션이 **0건**이다 ════════════════════════════════════
#
#   개발 PC 에서 확인했다:
#     git diff --name-only b2dfde8..9a6ba31 -- drizzle/   → **빈 출력**
#
#   🔴 그러므로 이 스크립트에는 **마이그레이션 코드가 한 줄도 없다.**
#      걷어낸 것 넷(17번에서 들어냈다):
#        · as-migrations 폴더 세기 · 묶음(tar.gz) 받기 · 통째로 갈아 끼우기
#        · db:preflight · db:migrate
#        · drizzle.__drizzle_migrations 줄 수 대조 · enum 자리 확인
#        · 적용 직전 덤프(pg_dump) — 「마이그레이션이 DB 를 깨뜨렸을 때」의 수단이다
#      돌 일이 없는 코드를 운영 절차에 남기지 않는다. 운영 DB 는 **112 그대로**다.
#
#   ⚠️ **배포 전 백업 검사는 그대로 둔다.** 17번에서 그것이 실제로 배포를 막아
#      사고를 피했다(01:00 에 돌렸더니 야간 백업이 02:30 이라 아직 없었다).
#      이번 판은 DB 를 바꾸지 않지만 **직원의 서류함에 폴더와 파일을 만든다** —
#      백업 없이 시작하지 않는다는 문은 그대로 둔다. 🔴 **--go 는 오늘 뜬
#      dss_as 백업이 없으면 시작조차 않는다**(3-ㄱ).
#
# ══ 🔴 ② compose 에 **새 볼륨**이 하나 는다 (16번에서 가져옴) ═══════════
#
#   app-as 에 이것이 더해진다 — 🔴 **긴 문법**이다:
#
#       - type: bind
#         source: "/volume1/2_AS센터/1. 수리 관련/3. 연락서(활용)/2. 연락서"
#         target: /contact-folder-archive
#
#   🔴 짧은 문법(`원본:대상`)으로 적으면 깨진다 — 경로에 **공백과 괄호**가 있다.
#      한 줄을 콜론으로 가르는데, 따옴표를 씌우면 이번엔 전체가 원본 하나로 읽힌다
#      (compose 의 견적서 볼륨 주석에 그 까닭이 적혀 있다).
#
#   🔴 **`2_AS센터` 의 AS 는 대문자다.** Windows 탐색기가 보여 주는 `2_as센터` 를
#      그대로 적으면 리눅스에서 **조용히 빈 폴더**가 된다. 그러면 앱은 「폴더가
#      없다」가 아니라 **「폴더는 있는데 0개」**를 보고 전부 짝 없음으로 판정해
#      **새 폴더를 수백 개 만든다.** 16번이 같은 자리에서 그것을 적어 뒀다.
#
#   🔴 **쓰기 가능으로 붙인다**(read_only 를 쓰지 않는다). 앱이 폴더를 만들고
#      파일을 꽂기 때문이다. 🔵 **2026-10-05 에 NAS 에서 실측해 WRITE-OK 를
#      받았다** — 앱 이미지(dss-as:2.0) + `--group-add 100` 으로 파일·폴더를
#      만들었다 지웠다. 이 스크립트도 --go 에서 **같은 조건으로 다시 해 본다**
#      (3-ㄴ). 그때 안 되면 앱을 멈추기 전에 거기서 멈춘다.
#
#   🔴 **ACL 을 걷지 않는다.** compose 가 이 자리에서 두 번 경고한다 —
#      chmod · chown 으로 걷으면 **직원의 탐색기 접근이 끊긴다.** 컨테이너가
#      쓸 수 있는 근거는 app-as 의 `group_add: ["100"]` 하나이고, 그 줄은
#      **이미 있다**(더하지 않는다).
#
#   🔴 **tools-as 의 `read_only: true` 는 그대로 둔다.** 교산 이식용 도구이고
#      이 폴더를 쓰는 스크립트가 없다 — 쓸 이유가 없다.
#   🔴 **app-po 에도 붙이지 않는다.** PO 저장소에 연락서 화면이 없다.
#
# ══ 🔴 ③ as.env 에 설정 **셋**을 덧붙인다 (16번의 그 코드를 본뜸) ═══════
#
#   | 이름                              | 무엇                                  |
#   | CONTACT_FOLDER_ARCHIVE_DIR        | 컨테이너 안 경로 = /contact-folder-archive |
#   | CONTACT_FOLDER_ARCHIVE_UNC_ROOT   | 🔴 **도우미 설치본에만** 들어간다       |
#   | CONTACT_FOLDER_ARCHIVE_UNC_PATH   | 🔴 **이 값만 화면으로 나간다**([위치 복사]) |
#
#   🔴 16번의 규율을 한 글자도 바꾸지 않고 그대로 가져왔다:
#     · **이 PC(dss-deploy)의 nas/env/as.env 를 NAS 로 올리지 않는다. 절대로.**
#       그 사본은 낡아서 NAS 에만 있는 줄들(견적서 셋 · 현황표 다섯)이 없다 —
#       올리면 그 기능들이 운영에서 통째로 사라진다. **NAS 의 파일에 덧붙인다.**
#     · 덧붙이기 전에 **사본**을 남긴다(backups/as.env.<도장>, root 600).
#     · **이미 그 줄이 있으면 건드리지 않는다**(두 번 돌려도 안전하다).
#     · 적기 **전에** 견적서 셋 · 현황표 다섯이 살아 있는지 본다. 하나라도 없으면
#       덧붙이지 않고 멈춘다 — 그건 배포보다 먼저 알아야 할 일이다.
#
#   🔴 **UNC 의 호스트 부분은 NAS 의 as.env 에서 뽑는다. 코드에 박지 않는다.**
#      견적서 쪽(QUOTE_ARCHIVE_UNC_ROOT · _ALT)이 이미 이름(\\DSS-NAS)과
#      IP(\\192.168.0.222)를 나눠 쓰고 있다. 거기서 **호스트 토막만** 읽는다.
#
#   🔴 그런데 **연락서에는 _ALT 가 없다 — 루트 한 자리뿐이다.**
#      (RF_Service_System/src/lib/server/quote-folder-helper.ts 의
#       resolveQuoteFolderHelperInstallRoots 가 읽는 연락서 키는 하나다.)
#      그래서 **IP 쪽을 고른다.** 까닭은 이 판의 커밋 bebc1e7 이 적어 둔 그대로다:
#        「이름으로 바꾸는 길은 막혀 있다 — 사내 DNS 가 없고 대역이 달라
#          이름 조회가 안 된다」
#      이름을 골랐다가 이름 풀이가 안 되는 PC 에서는 [폴더 열기]가 통째로 먹통이
#      되는데, 비켜 갈 두 번째 주소가 없다. 🔵 IP 를 고른 쪽의 부작용(윈도우가
#      「인터넷 영역」으로 보아 파일 열 때 확인창이 뜨던 것)은 **이 판이 함께
#      고쳤다** — 도우미가 설치할 때 그 IP 를 「로컬 인트라넷」에 등록한다.
#      🔵 둘 다 IP 가 아니면 이름 쪽을 쓰고 **그렇게 말한다.**
#
#   ⚠️ **값에 따옴표를 두르지 않는다.** env_file 의 큰따옴표 안에서는 역슬래시가
#      이스케이프로 읽혀 `\2` · `\3` 이 조용히 사라진다. 따옴표 없이 적으면 줄
#      끝까지가 그대로 값이다(빈칸·괄호가 들어 있어도 된다).
#   🔴 **역슬래시가 먹혔는지 교체 뒤에 센다** — 컨테이너 안에서 printenv 로 읽어
#      역슬래시가 **넷 이상**인지 본다(5-ㄷ). 16번이 그 검사로 잡았다.
#
# ══ 🔴 ④ 배포 뒤 **사람이 할 일**이 있다 — 도우미 다시 설치 ════════════
#
#   🔴 **쓰는 분들이 PC 에서 도우미를 다시 설치해야 한다.** 이번 판은 도우미에
#      둘을 더했다:
#        ㄱ) **연락서 루트** — 그 폴더를 열 수 있게
#        ㄴ) **파일 열기 동작**과 **IP 를 「로컬 인트라넷」에 등록**
#            (파일을 열 때 뜨던 「신뢰할 수 있는 출처인가요」 확인창을 없앤다)
#      옛 도우미는 새 주소를 받으면 **조용히 아무 일도 하지 않는다.**
#      (도우미는 PC 당 **한 벌**이다 — 레지스트리 `dss-folder`.)
#
#   🔴 **설치 명령은 반드시 A/S 화면에서 받는다.**
#      PO 화면에서 받으면 그 PC 의 **고객사 현황표 [폴더 열기]가 먹통이 된다** —
#      도우미가 한 벌뿐이라 PO 가 내준 설치본이 A/S 것을 덮어쓴다(README 의 함정).
#      받는 길: A/S → 수리 건 상세 → [폴더 열기] → [설치 명령 복사] →
#               PowerShell 창에 붙여넣기 (관리자 권한 필요 없음).
#   8단계가 이 안내를 **마지막에 한 번 더** 찍는다.
#
# ══ 🔴 돌리기 전에 — **값 셋을 채워야 한다** ═══════════════════════════
#
#   🔴 이 스크립트가 쓰일 때 dss-as:2.1 은 **아직 구워지지 않았다.**
#      그래서 아래 세 상수가 **비어 있다**:
#        SZ_AS · MD5_AS · WANT_CFG_AS
#      비어 있는 동안 --check 는 그 자리를 ⚠️ 로만 말하고, 🔴 **--go 는 시작조차
#      하지 않는다.** 잰 적 없는 이미지를 운영에 올리지 않기 위해서다.
#
#   개발 PC(PowerShell)에서 굽고 재는 차례 — 폴더는
#   C:\Users\희만\Desktop\Development 다:
#
#     cd C:\Users\희만\Desktop\Development\RF_Service_System
#     git status --short                      ← **비어 있어야 한다**(작업 폴더에서 굽는다)
#     docker build -t dss-as:2.1 .
#     cd ..
#     docker save dss-as:2.1 -o dss-as-2.1.tar
#     (Get-Item dss-as-2.1.tar).Length        ← SZ_AS
#     Get-FileHash -Algorithm MD5 dss-as-2.1.tar   ← MD5_AS (소문자로 적는다)
#     tar -xOf dss-as-2.1.tar manifest.json        ← "Config" 의 sha256 → WANT_CFG_AS
#
#   🔴 **`git archive` 로 뽑지 마라** — 서브모듈 vendor/dss-ui 가 빈 폴더로 나와
#      빌드가 깨진다(README 「다음 배포 때」 1번 · runbook/02 10절).
#   🔴 **tar 안 Config 지문이 개발 PC 의 `{{.Id}}` 와 다르다.** 17번이 두 번 겪었다
#      (그 판의 실제 값: 개발 PC 554e8528… ↔ tar 안 cdd1534e…). NAS 는 tar 안의
#      config 지문을 image ID 로 낸다 — **맞춰 볼 값은 tar 쪽**이다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/18-deploy.sh            ← 읽기만 한다
#
#   🔴 NAS 의 docker 는 **sudo(root)** 가 필요하다. 이 스크립트는 root 가
#      아니면 첫 줄에서 멈춘다.
#
# ══ 🔴 개발 PC → NAS 로 올릴 것 **둘** ═════════════════════════════════
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#      아래는 **개발 PC 의 PowerShell** 에서 친다(NAS 가 아니다).
#
#     scp -O dss-as-2.1.tar dss-nas:/volume1/dss/images/
#     scp -O docker-compose.nas.yml dss-nas:/volume1/dss/setup/incoming/
#
#   🔵 17번은 셋이었다 — **마이그레이션 묶음이 빠졌다.** 이번엔 0건이라 올릴
#      것이 없다. 그 파일을 올리려 들면 그것부터 잘못된 것이다.
#   🔴 두 번째 줄의 compose 는 **dss-deploy 저장소의 nas/docker-compose.nas.yml**
#      이다(A/S 태그를 2.1 로 올리고 **연락서 볼륨을 더한** 그 파일).
#   🔵 scp 가 바로 안 되면 사용자 계정(swhur)의 홈으로 올린 뒤 NAS 에서
#      `sudo mv` 로 옮긴다. /volume1/dss 아래는 root 만 쓸 수 있다.
#
# ══ 🔴 DSM 터미널은 긴 명령을 잘라 먹는다 ══════════════════════════════
#
#   하루에 네 번 깨진 적이 있다. **NAS 에서 돌릴 것은 스크립트 파일로 올리고
#   md5 를 맞춘 뒤** 실행한다. 이 파일 자체가 그렇다:
#
#     (PowerShell)  scp -O nas\setup\18-deploy.sh dss-nas:/volume1/dss/setup/
#     (PowerShell)  Get-FileHash -Algorithm MD5 nas\setup\18-deploy.sh
#     (NAS)         md5sum /volume1/dss/setup/18-deploy.sh
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
#      **새 볼륨을 읽어 보려고** 임시 컨테이너를 하나 더 띄웠다 지운다.
#      디스크에도 DB 에도 아무것도 남기지 않고 도는 사이트를 건드리지도 않지만,
#      「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확한 말이다.
#      13·15·16·17번 머리말의 그 문장을 그대로 잇는다.
#
# ── 모드 다섯 ───────────────────────────────────────────────────────────
#   (없음) · --check     읽기만 한다. 아무것도 안 바꾸고 안 멈춘다      ← 기본값
#   --preload            새 이미지 하나를 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --go                 🔴 **A/S 하나만** 교체 + 새 볼륨 + as.env 세 줄
#   --rollback           되돌리기 안내
#
#   `--force-load` 는 `--go` 와 같이 써도 된다:  bash 18-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 18-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 18-deploy.sh --preload       (새 이미지를 미리 실어 둔다)
#   3) bash 18-deploy.sh                 (다시 읽기만 — 이번엔 지문까지 다 본다)
#   4) bash 18-deploy.sh --go            (볼륨 + as.env + A/S 교체)
#
# ══ 🔴 ⑤ 「아직 안 온 것」을 ✗ 로 세지 않는다 (17번의 규칙 그대로) ═════
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
#     · 이미지 **안에 이번 판의 표시가 없다**         → ✗ (옛 판을 올린 것)
#
#   🔴 **「아직 안 실린 이미지」는 어느 모드에서도 ✗ 가 아니다**(notloaded).
#      --preload 와 --go 는 2단계에서 **스스로 싣기** 때문이다. 여기서 ✗ 를
#      세면 --go 가 싣기도 전에 자기 검사에 막혀 배포가 아예 불가능해진다.
#   🔴 같은 까닭으로 **새 볼륨을 「도는 컨테이너」에서 찾지 않는다**(16번 ⑩ ·
#      README 「ㄴ」). 지금 도는 2.0 에는 /contact-folder-archive 가 **없는 것이
#      맞다** — 그 자리는 새 compose 를 적용해야 생긴다. 그래서 **임시 컨테이너를
#      띄워** 호스트 경로를 붙여 보는 probe_new_volume() 을 16번에서 되가져왔다.
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
#   시작 시각(.State.StartedAt)을 적어 두고 **그대로인지** 본다(5-ㅅ).
#
# ══ 15 · 16 · 17번에서 그대로 이어받는 것 ══════════════════════════════
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
#      🔵 17번은 「이 기능은 그 표를 안 읽는다」가 결론이었다. **이번은 반대다** —
#         연락서 통로 셋이 전부 `repairCases.files` 를 묻는다(READ 로 찾고
#         WRITE 로 만든다). 그래서 이번엔 **저장된 값이 기능을 막을 수 있다.**
#   ⑩ 🔴 **새로 붙는 볼륨은 임시 컨테이너로 본다**(위 ⑤ 절의 그 까닭)
#   ⑪ 🔴 앱이 저장한 파일을 **직원이 열 수 있는가** — 새 파일에 ACL 이
#      물려오는지 본다(acl_inherit_check · 07-deploy.sh 2단계의 그 검사)
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
TAG_AS=dss-as:2.1
OLD_AS=dss-as:2.0

# ── 🔴 **건드리지 않는 아홉.** 16 · 17번과 같은 아홉이다 ───────────────
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
TAR_AS=$IMAGES/dss-as-2.1.tar
# 🔴 개발 PC 에서 2026-10-05 에 구워 실측한 값이다(docker build → docker save).
#    이미지 584MB · tar 130MB — 이미지와 tar 의 크기가 네 배 넘게 다른 것이 정상이다
#    (2.0 도 582MB 이미지에 tar 129,669,120 이었다). tar 크기로 놀라지 말 것.
#    2.0 과 견주면 tar 가 373,760 바이트 늘었다 — 이 판에 더한 코드 양과 맞는다.
SZ_AS="130042880"        # (Get-Item dss-as-2.1.tar).Length
MD5_AS="ef6d9206e17d8b9d01b6fce105eddbd9"   # Get-FileHash -Algorithm MD5 (소문자로 적는다)
WANT_CFG_AS="sha256:ba9fc00889df321f157a98dc6fcbb76f278e880bfe88cc90e791c43bfebbc07a"
# ⚠️ manifest.json 은 이 값을 `blobs/sha256/ba9fc008…` 로 적는다 — 앞의 `blobs/` 를
#    떼고 `sha256:` 를 붙인 모양이 위 값이다(17번도 같은 모양으로 적었다).
# ⚠️ tar 안의 이 지문은 개발 PC 의 `docker images --format {{.Id}}`(e630d0793c3d…)와
#    **다르다.** 17번이 두 번 겪고 적어 둔 그대로다 — 다르다고 놀라지 말 것.

# ── 포트 (compose 의 ports: 에서 읽어 확인했다 — 짐작이 아니다) ────────
#   포털 13100 · A/S 13000 · 계측기 13300 · 개선요청 13500 ·
#   PO 13600 · 휴가 13700
AS_PORT=13000

# ── DB — 🔴 **이 스크립트는 DB 를 바꾸지 않는다. select 만 한다** ──────
# 마이그레이션 0건이다. 운영은 112 그대로고, 여기서 적는 SQL 은 전부 select 다.
AS_DB=dss_as

# ── 권한 — 🔴 읽기만 한다. 출처는 전부 소스다 (1-ㄷ) ──────────────────
#   표·칸   vendor/dss-core/src/schema/role-permissions.ts
#           (표 role_permissions · 칸 role · area_key · level · updated_at.
#            🔴 칸 이름은 leaf_key 가 아니라 **area_key** 다 — 이름이 낡았다)
#   이번 판 src/app/api/repair-cases/[id]/contact-folder/route.ts:169 · :257
#           hasPermission(actingUser, "repairCases.files", "READ" | "WRITE")
#   기본값  src/lib/auth/permission-baseline.ts:394 → repairCases.files 는
#           ladder({ write: true, read: true }) — **로그인한 사람이면 WRITE** 다.
#   🔴 그러므로 표에 줄이 **없으면 전부 열린다.** 줄이 있으면 그 값이 이긴다.
PERM_TABLE=role_permissions
PERM_AREA=repairCases.files

# ── 컨테이너 안에서 실제로 열어 볼 폴더 ────────────────────────────────
ATT=$D/as-attachments
TEMPLATES=$D/as-templates
UP_IMP=$D/improvements-uploads
MF_METERS=$D/meters-files
# 🔵 16번이 붙인 현황표 공유폴더. **이번에 새로 붙는 것이 아니다** — 이미
#    도는 2.0 에 붙어 있다. 여기서는 「사라지지 않았는가」만 본다.
PORTAL_MNT=/customer-portal-archive

# ── 🔴 이번에 **새로 붙는** 공유폴더 ───────────────────────────────────
# 🔴 `2_AS센터` 의 AS 는 **대문자**다(머리말 ②).
CONTACT_SRC="/volume1/2_AS센터/1. 수리 관련/3. 연락서(활용)/2. 연락서"
CONTACT_MNT=/contact-folder-archive

# ── as.env 에 덧붙일 세 줄의 **재료** ──────────────────────────────────
# 호스트 부분은 2-ㄱ(build_env_values)이 NAS 의 as.env 에서 뽑는다. 뽑지 못했을
# 때 쓸 기본값은 아래 하나다 — 🔴 **IP 다**(머리말 ③ 의 그 까닭).
DEF_HOST='\\192.168.0.222'
P_SHARE='2_AS센터'                                   # 공유 이름(/volume1 바로 아래)
P_TAIL='1. 수리 관련\3. 연락서(활용)\2. 연락서'       # 공유 아래 ~ 연락서 폴더들이 모인 곳
# 2-ㄱ 이 채운다.
V_DIR=$CONTACT_MNT
V_ROOT=""
V_UNCPATH=""
ENV_KEYS="CONTACT_FOLDER_ARCHIVE_DIR CONTACT_FOLDER_ARCHIVE_UNC_ROOT CONTACT_FOLDER_ARCHIVE_UNC_PATH"
# 🔴 NAS 에만 있고 이 PC 의 사본에는 없는 여덟 줄. **사라지면 안 된다.**
QUOTE_KEYS="QUOTE_ARCHIVE_DIR QUOTE_ARCHIVE_UNC_ROOT QUOTE_ARCHIVE_UNC_ROOT_ALT"
PORTAL_KEYS="CUSTOMER_PORTAL_ARCHIVE_DIR CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT CUSTOMER_PORTAL_ARCHIVE_FOLDER_PATH CUSTOMER_PORTAL_ARCHIVE_UNC_PATH"

# ── 이미지 **안에서** 찾을 글자 (1-ㅋ) ─────────────────────────────────
# 🔴 태그와 지문이 맞아도 「무엇이 든 판인지」는 안을 봐야 안다. 9/21~9/29 에
#    A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다.
#
# 🔵 17번처럼 **모듈 경로**로 본다. Next 의 번들은 webpack 모듈 이름으로 소스
#    경로를 그대로 품는다 — 한글 문구보다 또렷하다(한글은 유니코드 이스케이프로
#    바뀌어 있을 때가 있다. 16번이 그 함정을 적어 뒀다).
#
# 🔴 **네 값은 개발 PC 의 git 에서 가린 것이고, 이미지 안에서는 아직 안 쟀다**
#    (2.1 이 아직 안 구워졌다). git 으로 확인한 것은 이렇다:
#      b2dfde8(=2.0) 의 src 에 "CONTACT_FOLDER_ARCHIVE" 가 **0 파일**
#      9a6ba31(=2.1) 의 src 에 **19 파일**
#      WeeklyReportBlockStatusEdit.tsx 는 2.0 에 **없고** 2.1 에 **있다**
#    🔵 17번이 같은 꼴의 모듈 경로 표시를 실제 이미지에서 재어 통과시켰다.
AS_MARK1="src/lib/storage/contact-folder-archive.ts"
AS_MARK2="src/components/repair-cases/files/ContactFolderSection.tsx"
AS_MARK3="src/components/dashboard/WeeklyReportBlockStatusEdit.tsx"
AS_MARK4="CONTACT_FOLDER_ARCHIVE_UNC_PATH"
# 🔵 2.0 에서 들어온 것이 2.1 에도 그대로 있는가 — **회귀** 표시다.
AS_KEEP="src/lib/domain/weekly-report-row-status.ts"
AS_CTRL="SSO_REDIRECT_URI"    # 두 판에 다 있는 대조 표시
# 🔵 이번 판에는 **없어져야 할 파일이 하나도 없다**(git diff 에 D 가 0건이다).
#    그래서 17번의 AS_GONE 자리가 비어 있다 — 일부러 비워 둔 것이다.

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 셋. 인자가 없으면 이 셋 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
PROBE_WRITE=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 18-deploy.sh                  읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 18-deploy.sh --check          위와 같습니다
  bash 18-deploy.sh --preload        새 이미지를 싣고 지문만 맞춥니다
  bash 18-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 18-deploy.sh --go             🔴 볼륨 + as.env 세 줄 + A/S 교체
  bash 18-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 18-deploy.sh --rollback       되돌리기 안내

  🔴 --go 가 멈추는 것은 **dss-as 하나**입니다.
     포털 · 계측기 · 개선요청 · PO · 휴가 · DB 는 그대로 돕니다.
  🔵 --go 는 **DB 를 바꾸지 않습니다** — 이번 판은 마이그레이션이 0건입니다.
     그래도 그날 백업이 없으면 거기서 멈춥니다(직원의 서류함에 씁니다).
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
LOG="$D/setup/logs/18-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11 · 12 · 13 · 15 · 16 · 17-deploy.sh 의 것을 그대로 쓴다 ──
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""; DOWN=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# 🔴 머리말 ⑤ — 「아직 안 온 것」은 --check 에서 ✗ 가 아니다.
missing_is_fatal() { [ "$MODE" != check ]; }
notyet() { # 1 할 말   — 아직 안 **온** 것(사람이 올려야 하는 파일)
  if missing_is_fatal; then bad "$1"; else echo "    ⚠️ $1"; fi
}
notloaded() { # 1 할 말 — 아직 안 **실린** 것. 🔴 어느 모드에서도 ✗ 가 아니다.
  echo "    ⚠️ $1"
}

# 🔴 값 셋이 채워졌는가 — 안 채워졌으면 --go 가 시작하지 않는다.
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
#  DB 도우미 — 🔴 **전부 select 다.**
#
#  이 스크립트에는 DB 를 바꾸는 자리가 **하나도 없다.** 이번 판은 마이그레이션이
#  0건이고, 여기서 적는 SQL 은 role_permissions 를 읽는 select 뿐이다.
# ══════════════════════════════════════════════════════════════════════
qas()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -Atc \"$1\"" 2>/dev/null; }
qqas() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -c   \"$1\"" 2>/dev/null; }

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 개발 PC 의 `docker image inspect --format {{.Id}}` 가 아니라 **이 값**이
#    NAS 에 실렸을 때의 image ID 가 된다. 16 · 17번의 함수를 그대로 가져왔다.
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
#  🔴 **새로 붙는 볼륨**은 도는 컨테이너에서 찾으면 안 된다 (16번 ⑩ 에서 되가져옴)
#
#  지금 도는 dss-as 는 **2.0** 이고 그 컨테이너에는 /contact-folder-archive 가
#  **없는 것이 맞다.** 그 자리는 새 compose 를 적용해야 생긴다. 16번의 첫 판이
#  바로 그 자리에서 EACCES 로 ✗ 를 내 **배포 자체를 불가능하게 만들었다** —
#  --go 도 검사를 다 돌리고 ✗ 가 있으면 멈추기 때문이다.
#  고친 방법이 이것이다: **임시 컨테이너를 띄워** 호스트 경로를 :ro 로 붙여 본다.
#
#  ⚠️ -u 1000:1000 --group-add 100 은 compose 의 app-as 와 **같은 조건**이다.
#     그것 없이 재면 ACL 의 group:users:allow 에 안 걸려 「못 읽는다」가 나온다 —
#     그러면 멀쩡한 폴더를 또 의심하게 된다.
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
  local src="$1" mnt="$2" label="$3" img out r
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
  say "    (도는 2.0 에는 아직 이 자리가 없다 — 함수 머리말 참조)"
  # 🔴 경로는 -e M= 로 넘겨 **컨테이너 안에서** 푼다. sh -c 본문에 끼워 넣으면
  #    빈칸 · 괄호 · 한글이 든 경로에서 조용히 깨진다.
  out=$("$DOCKER" run --rm -u 1000:1000 --group-add 100 -e M="$mnt" \
        -v "$src:$mnt:ro" --entrypoint sh "$img" -c '
          id
          if ls -1 "$M" >/dev/null 2>&1; then
            echo "PROBE_NEW READ_OK"
            echo "TOPN $(ls -1 "$M" 2>/dev/null | wc -l)"
            ls -1 "$M" 2>/dev/null | head -3 | sed "s/^/TOP /"
          else
            echo "PROBE_NEW READ_FAIL"
          fi' 2>&1)
  printf '%s\n' "$out" | grep -E '^(uid=|PROBE_NEW |TOPN |TOP )' | sed 's/^/      /'
  r=$(printf '%s\n' "$out" | sed -n 's/^PROBE_NEW //p' | head -1)
  case "$r" in
    READ_OK)
      ok "$label · $mnt 를 읽는다 (uid 1000 + gid 100)"
      say "    🔴 위 TOPN 이 **0 이면 경로가 틀린 것**이다 — 연락서 폴더가 수백 개"
      say "       있어야 한다. 0 이면 「2_AS센터」 의 대소문자부터 보세요(머리말 ②)."
      say "    🔵 쓰기 · 폴더 만들기는 --go 의 3-ㄴ 에서 본다(--check 는 안 만든다)."
      return 0 ;;
    READ_FAIL)
      bad "$label · $mnt 를 **못 읽는다**(EACCES) — 🔴 이번엔 진짜 권한 문제다"
      say "    (자리가 없어서 나는 ✗ 가 아니다. 여기서는 자리를 **우리가 붙여** 봤다.)"
      # 🔴 여기서는 perm_fix_hint 를 부르지 않는다 — 그 안내는 ACL 을 걷는 길이고,
      #    직원이 쓰는 공유폴더에 그러면 탐색기 접근이 끊긴다.
      say "    🔴 **chmod · chown 을 하지 마라** — 직원의 탐색기 접근이 끊긴다."
      say "    되는 폴더(견적서 · 현황표)와 ACL 을 끝까지 견주세요:"
      cmd "synoacltool -get \"$src\" | head -30"
      say "    (보는 것: 줄 수가 같은가 · group:users:allow:rwxpdDaARWc-- 가 있는가)"
      say "    compose 의 app-as 에 group_add: [\"100\"] 이 있는지도 보세요."
      return 1 ;;
    *)
      bad "$label · 열어 보지 못했다 — 아래가 그대로의 출력이다"
      printf '%s\n' "$out" | sed 's/^/      /' | head -8
      return 1 ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 앱이 만든 파일을 **직원이 열 수 있는가** (07-deploy.sh 2단계의 그 검사)
#
#  만든 파일의 POSIX 모드는 000 이고(주인이 DSM 사용자가 아니다) 접근은 물려받은
#  ACL 이 정한다. allow 가 하나도 안 물려오면 직원 눈에 「열리지 않는 파일」만
#  쌓인다 — 없느니만 못하다. 🔴 파일을 하나 만들었다 지우므로 --go 에서만 한다.
#  🔴 이번 판은 **폴더까지 만든다**(접수하면 저절로 생긴다). 그래서 파일 하나와
#     폴더 하나를 둘 다 만들어 보고 둘 다의 ACL 을 본다.
# ══════════════════════════════════════════════════════════════════════
acl_inherit_check() { # 1 호스트폴더 2 사람이읽을이름 3 이미지태그 4 컨테이너안경로
  local src="$1" label="$2" tag="$3" mnt="$4" t g allow users_ok gallow gusers rc=0
  t="$src/.dss-inherit-test"
  g="$src/.dss-inherit-dir"
  "$DOCKER" run --rm --group-add 100 -v "$src:$mnt" --entrypoint sh "$tag" \
    -c ": > $mnt/.dss-inherit-test; mkdir -p $mnt/.dss-inherit-dir" >/dev/null 2>&1
  if [ ! -e "$t" ]; then
    bad "$label · 시험 파일을 만들지 못했다 — 앱도 저장하지 못한다"
    say "    🔴 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기 접근이 끊긴다."
    say "       compose 의 app-as 에 group_add: [\"100\"] 이 있는지부터 보세요."
    rm -rf "$g"
    return 1
  fi
  allow=$(synoacltool -get "$t" 2>/dev/null | grep -c ":allow:")
  users_ok=$(synoacltool -get "$t" 2>/dev/null \
             | grep -c "group:users:allow\|group:administrators:allow")
  if [ -d "$g" ]; then
    gallow=$(synoacltool -get "$g" 2>/dev/null | grep -c ":allow:")
    gusers=$(synoacltool -get "$g" 2>/dev/null \
             | grep -c "group:users:allow\|group:administrators:allow")
  else
    gallow=0; gusers=0
    bad "$label · 시험 **폴더**를 만들지 못했다 — 접수 때 폴더 자동 생성이 실패한다"
    rc=1
  fi
  rm -f "$t"; rm -rf "$g"
  if [ "${allow:-0}" -gt 0 ] && [ "${users_ok:-0}" -gt 0 ]; then
    ok "$label · 새 **파일**이 ACL 을 물려받는다 (allow ${allow}줄) — 직원이 연다"
  else
    bad "$label · 새 파일에 allow 가 안 물려온다 (allow ${allow:-0}줄)"
    say "    → 앱이 저장해도 **직원이 못 여는 파일**이 쌓인다."
    say "    → 그럴 바에는 이 기능을 끄는 편이 낫다 — as.env 의"
    say "      CONTACT_FOLDER_ARCHIVE_DIR 한 줄을 비우면 연락서 연동만 꺼지고"
    say "      수리 건 조회 · 파일 관리 · 견적서 · 현황표는 그대로 돈다."
    rc=1
  fi
  if [ "${gallow:-0}" -gt 0 ] && [ "${gusers:-0}" -gt 0 ]; then
    ok "$label · 새 **폴더**도 ACL 을 물려받는다 (allow ${gallow}줄)"
  elif [ "${gallow:-0}" = 0 ] && [ "$rc" = 0 ]; then
    bad "$label · 새 폴더에 allow 가 안 물려온다 — 직원이 그 폴더를 못 연다"
    rc=1
  fi
  return "$rc"
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
#  이미지 **안에** 이번 판이 들어 있는가 — 여섯 자리를 한 번에 본다
#
#  🔴 「아직 안 실린 것」은 ✗ 가 아니다(머리말 ⑤). 못 봤다고 말하고 넘어간다.
#  🔴 대조 표시(AS_CTRL)가 안 나오면 **판정하지 않는다** — 글자를 못 읽은 것과
#     옛 판인 것을 가를 수 없기 때문이다.
# ══════════════════════════════════════════════════════════════════════
inside_check() { # 1 이미지태그
  local tag="$1" out m1 m2 m3 m4 kp c n
  if ! have_img "$tag"; then
    notloaded "$tag 가 아직 NAS 에 없어 **안을 못 봤다** — 먼저 실으세요"
    cmd "bash $0 --preload"
    return 0
  fi
  out=$("$DOCKER" run --rm -e M1="$AS_MARK1" -e M2="$AS_MARK2" -e M3="$AS_MARK3" \
        -e M4="$AS_MARK4" -e KP="$AS_KEEP" -e C="$AS_CTRL" \
        --entrypoint sh "$tag" -c '
    m1=0; m2=0; m3=0; m4=0; kp=0; c=0
    grep -rlF -- "$M1" /app/.next >/dev/null 2>&1 && m1=1
    grep -rlF -- "$M2" /app/.next >/dev/null 2>&1 && m2=1
    grep -rlF -- "$M3" /app/.next >/dev/null 2>&1 && m3=1
    grep -rlF -- "$M4" /app/.next >/dev/null 2>&1 && m4=1
    grep -rlF -- "$KP" /app/.next >/dev/null 2>&1 && kp=1
    grep -rlF -- "$C"  /app/.next >/dev/null 2>&1 && c=1
    n=$(grep -rlF -- contact-folder /app/.next/server 2>/dev/null | wc -l)
    echo "INSIDE $m1 $m2 $m3 $m4 $kp $c $n"' 2>/dev/null | grep '^INSIDE ' | head -1)
  m1=$(printf '%s' "$out" | awk '{print $2}')
  m2=$(printf '%s' "$out" | awk '{print $3}')
  m3=$(printf '%s' "$out" | awk '{print $4}')
  m4=$(printf '%s' "$out" | awk '{print $5}')
  kp=$(printf '%s' "$out" | awk '{print $6}')
  c=$(printf  '%s' "$out" | awk '{print $7}')
  n=$(printf  '%s' "$out" | awk '{print $8}')
  if [ "${c:-0}" != 1 ]; then
    say "    ⚠️ $tag 안을 글자로 뒤지지 못했다 — 대조 표시($AS_CTRL)도 안 나왔다."
    say "       **판정하지 않는다.** 🔴 이때는 사람이 직접 화면에서 봐야 한다."
    return 0
  fi
  ok "대조 표시($AS_CTRL)를 찾았다 — 안을 실제로 읽었다는 뜻이다"
  [ "${m1:-0}" = 1 ] && ok "연락서 저장 모듈이 들어 있다 ($AS_MARK1)" \
    || bad "🔴 $AS_MARK1 가 **없다** — 이것은 $OLD_AS 다. 다시 구워 올리세요"
  [ "${m2:-0}" = 1 ] && ok "파일 관리의 「공유폴더」 구역이 들어 있다 ($AS_MARK2)" \
    || bad "🔴 $AS_MARK2 가 **없다** — 이것은 $OLD_AS 다. 다시 구워 올리세요"
  [ "${m3:-0}" = 1 ] && ok "주간보고 블록 단위 수정이 들어 있다 ($AS_MARK3)" \
    || bad "🔴 $AS_MARK3 가 **없다** — 이것은 $OLD_AS 다"
  [ "${m4:-0}" = 1 ] && ok "설정 이름 $AS_MARK4 가 들어 있다" \
    || bad "🔴 $AS_MARK4 가 **없다** — 이것은 $OLD_AS 다"
  [ "${kp:-0}" = 1 ] && ok "회귀 — $AS_KEEP 가 그대로 있다 (2.0 에서 들어온 것)" \
    || bad "🔴 $AS_KEEP 가 **사라졌다** — 2.0 보다 **옛 판**을 올린 것이다"
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then
    ok ".next/server 안에 contact-folder 가 든 파일 ${n}개"
  else
    bad "🔴 .next/server 안에 contact-folder 가 **한 파일도 없다** — 옛 판이다"
  fi
}

# ── 🔴 이미지 안에 글자 인식기(public/ocr)가 들어 있는가 ───────────────
# 🔴 Next 의 standalone 은 public 을 **자동으로 담지 않는다.** Dockerfile 이
#    따로 COPY 하는데, 그 줄이 어긋나면 화면은 뜨고 명판 읽기만 죽는다 —
#    그것도 오류 없이 「인식기를 불러오지 못했습니다」 하나로.
# 🔵 이번 판이 더한 기능은 아니다. **2.0 에 있던 것이 2.1 에도 그대로 있는지**
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
#  「권한은 코드가 아니라 운영 DB 가 정한다」(2026-09-30). 17번은 그 결론이
#  「이 기능은 role_permissions 를 안 읽는다」였다. 🔴 **이번은 반대다.**
#  연락서 통로 셋이 전부 그 표를 읽는 hasPermission 을 거친다:
#    · 폴더 찾기 · 안 보기 · 파일 열기  → repairCases.files **READ**
#    · 폴더 만들기                      → repairCases.files **WRITE**
#  기본값(permission-baseline.ts:394)은 **로그인한 사람이면 WRITE** 다. 그래서
#  표에 줄이 **없으면 전부 열린다.** 줄이 있으면 **저장된 값이 이긴다.**
#  🔴 그래서 여기서 읽어 보고 「실제로 달라지는 칸」을 말한다. ✗ 는 세지 않는다 —
#     배포의 흠이 아니라 설정이다.
# ══════════════════════════════════════════════════════════════════════
PERM_SQL_COUNT="select count(*) from $PERM_TABLE"
PERM_SQL_AREA="select role, area_key, level, updated_at::date from $PERM_TABLE where area_key like 'repairCases%' order by area_key, role"

perm_check() {
  local reg n_all n_files
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
  n_files=$(qas "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA'")
  say "  · 그중 $PERM_AREA 에 저장된 줄: ${n_files:-?}"
  say
  say "  A/S 현황(repairCases*)에 저장된 값 — 역할 전부:"
  qqas "$PERM_SQL_AREA" | sed 's/^/      /'
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 연락서 폴더는 **$PERM_AREA** 가 정합니다.          ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  if [ "${n_files:-0}" = 0 ]; then
    say "     🔵 그 칸에 **저장된 줄이 없습니다.** 그러면 코드의 기본값이 그대로"
    say "        살아 — **로그인한 사람이면 누구나 WRITE** 입니다."
    say "        즉 연락서 [폴더 열기] · [만들기] · 파일 열기가 **전부 열립니다.**"
  else
    say "     🔴 그 칸에 **저장된 줄이 ${n_files}개 있습니다.** 위 표에서 그 줄들을"
    say "        보세요 — **저장된 값이 코드의 기본값을 이깁니다.**"
    say "        · level 이 NONE 인 역할은 폴더를 **찾지도 못합니다**"
    say "        · level 이 READ 인 역할은 찾고 보기만 되고 **만들기가 막힙니다**"
    say "        · 🔴 그 역할로 접수하면 **폴더 자동 생성도 조용히 건너뜁니다**"
    say "          (곁다리라 접수 자체는 그대로 됩니다)"
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  as.env — 🔴 **NAS 의 파일을 읽고 없는 줄만 덧붙인다** (16번에서 가져옴)
#
#  🔴 이 PC 의 nas/env/as.env 를 올리지 않는다(머리말 ③).
#  🔴 값은 로그에 찍지 않는다 — 다만 QUOTE_ARCHIVE_UNC_ROOT · _ALT 의
#     **호스트 부분**(\\이름 또는 \\IP)만 뽑아 보여 준다. 새 세 줄을 같은 꼴로
#     짜려면 그 한 토막이 필요하고, 그 토막은 비밀이 아니라 NAS 이름이다.
# ══════════════════════════════════════════════════════════════════════
env_val() { # 1 키  → NAS as.env 의 값 (없으면 빈 문자열)
  local v
  [ -f "$AS_ENV" ] || return 0
  v=$(sed -n "s/^$1=//p" "$AS_ENV" | head -1 | tr -d '\r')
  # 누가 따옴표를 둘렀을 수 있다 — 벗겨서 본다(우리가 적을 때는 안 두른다).
  v=${v#\"}; v=${v%\"}
  v=${v#\'}; v=${v%\'}
  printf '%s' "$v"
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
# 세 줄의 값을 짠다. 🔴 printf 로 짓는다 — 역슬래시가 한 겹 삼켜지지 않게.
build_env_values() {
  local qroot qalt hr ha
  qroot=$(env_val QUOTE_ARCHIVE_UNC_ROOT)
  qalt=$(env_val QUOTE_ARCHIVE_UNC_ROOT_ALT)
  hr=$(unc_host "$qroot")
  ha=$(unc_host "$qalt")
  ENV_SRC_NOTE="NAS 의 as.env"
  # 🔴 IP 쪽을 고른다 — 연락서에는 _ALT 가 없어 비켜 갈 두 번째 주소가 없고,
  #    사내 DNS 가 없어 이름 풀이가 안 되는 PC 가 있다(머리말 ③).
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
  V_DIR=$CONTACT_MNT
  V_ROOT=$(printf '%s\\%s\\%s' "$ENV_HOST" "$P_SHARE" "$P_TAIL")
  # 🔴 [위치 복사]용 전체 주소는 루트와 **같은 곳**이다 — 서버가 폴더 이름을
  #    이어 붙이지 않는다(server/contact-folder-helper.ts 머리말). 사람은 그
  #    폴더를 열어 제 인수번호 폴더를 눈으로 찾는다.
  V_UNCPATH=$V_ROOT
}
env_line_for() { # 1 키  → "키=값" 한 줄
  case "$1" in
    CONTACT_FOLDER_ARCHIVE_DIR)      printf '%s=%s' "$1" "$V_DIR" ;;
    CONTACT_FOLDER_ARCHIVE_UNC_ROOT) printf '%s=%s' "$1" "$V_ROOT" ;;
    CONTACT_FOLDER_ARCHIVE_UNC_PATH) printf '%s=%s' "$1" "$V_UNCPATH" ;;
  esac
}
# 🔴 역슬래시가 삼켜졌는지 — UNC 값에 역슬래시가 넷 이상 있어야 맞다(16번의 검사).
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
    say "      scp -O dss-as-2.1.tar dss-nas:/volume1/dss/images/"
    return 1
  fi
  n=$(stat -c '%s' "$2" 2>/dev/null)
  m=$(md5sum "$2" 2>/dev/null | awk '{print $1}')
  say "    · 지금 이 tar: 바이트 ${n:-?} · md5 ${m:-?}"
  if ! pinned; then
    say "    ⚠️ 🔴 **기대값 셋이 아직 비어 있다**(SZ_AS · MD5_AS · WANT_CFG_AS)."
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
  local tag s p rec t f db n_bk nlog k miss n_top rc v nb
  local FREE_KB FREE_H code h

  # ── 1-ㄱ. 올릴 파일 하나 — 크기 · md5 · tar 안의 지문 ────────────────
  step "1-ㄱ. 올린 파일 **하나** (이미지 tar. 🔵 마이그레이션 묶음은 없다)"
  say "  🔵 17번은 둘이었다 — 이번 판은 마이그레이션이 **0건**이라 tar 하나뿐이다."
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
  say "  ⚠️ $KEEP_ASTOOLS 는 **다시 굽지 않았다.** 이번 판에 마이그레이션이 없어"
  say "     그 이미지가 할 일이 없다. 🔴 되돌아간 $OLD_AS 도 그대로 둔다 —"
  say "     되돌리기가 그것을 쓴다."
  have_img "$OLD_AS" && ok "$OLD_AS 도 아직 있다 (되돌릴 길이 열려 있다)" \
    || say "    ⚠️ $OLD_AS 가 NAS 에 없다 — 되돌리려면 tar 를 다시 올려야 한다"

  # ── 1-ㄷ. 권한 — 🔴 읽기만 한다 ──────────────────────────────────────
  step "1-ㄷ. 연락서 폴더가 **진짜로** 열리는가 (운영 DB 를 읽는다)"
  say "  🔴 「권한은 코드가 아니라 운영 DB 가 정한다」 — 그래서 읽어 보고 말한다."
  say "     🔴 이번 기능은 17번과 달리 role_permissions 를 **읽는 판정**이다."
  perm_check

  # ── 1-ㄹ. 🔴 as.env — 세 줄을 덧붙일 자리 ────────────────────────────
  step "1-ㄹ. as.env (이름만 본다. 값은 호스트 토막과 **새 세 줄**만 찍는다)"
  say "  🔴 이 PC(dss-deploy)의 nas/env/as.env 를 NAS 로 **올리지 마세요.**"
  say "     그 사본에는 NAS 에만 있는 줄들이 빠져 있습니다 — 올리면 그 기능이"
  say "     운영에서 사라집니다. **NAS 의 파일에 없는 줄만 덧붙입니다.**"
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
    say "  🔴 현황표 다섯 줄 — 16번이 넣은 것이고 **2.1 도 그대로 쓴다**:"
    for k in $PORTAL_KEYS; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 [공유폴더에 저장]이 실패로 끝난다"
    done
    if grep -q "^CUSTOMER_LINK_TOKEN_KEY=" "$AS_ENV"; then
      say "  ⚠️ CUSTOMER_LINK_TOKEN_KEY 가 아직 있다 — 2.0 부터 **안 읽는 줄**이다."
      say "     🔴 **지우지 마세요.** 그대로 둬도 아무 일도 일어나지 않습니다."
    fi
    # 새 세 줄
    build_env_values
    say
    say "  🔴 이번에 덧붙일 **세 줄**:"
    miss=""
    for k in $ENV_KEYS; do
      if grep -q "^$k=" "$AS_ENV"; then
        ok "$k 가 **이미 있다** — 건드리지 않는다"
      else
        say "    · $k 가 없다 — --go 가 덧붙인다"
        miss="$miss $k"
      fi
    done
    say
    say "  🔵 호스트 토막은 $ENV_SRC_NOTE 에서 왔다 → $ENV_HOST"
    say "     까닭: $ENV_HOST_WHY"
    say "     (견적서 두 줄의 **나머지 부분은 찍지 않는다.** 쓸 것은 호스트뿐이다.)"
    say "  🔵 --go 가 적어 넣을 값 — 눈으로 보고 틀렸으면 멈추세요:"
    for k in $ENV_KEYS; do
      printf '      %s\n' "$(env_line_for "$k")"
    done
    nb=$(backslash_count "$V_ROOT")
    [ "${nb:-0}" -ge 4 ] && ok "짠 UNC 값의 역슬래시가 ${nb}개 — 삼켜지지 않았다" \
      || bad "짠 UNC 값의 역슬래시가 ${nb:-0}개뿐이다 — 🔴 따옴표가 먹은 것이다"
    say "  🔴 _UNC_ROOT 와 _UNC_PATH 가 **같은 값인 것이 맞다** — 서버가 폴더 이름을"
    say "     이어 붙이지 않는다. 사람은 그 폴더를 열고 제 인수번호 폴더를 찾는다."
    say "  🔴 _UNC_ROOT 는 **도우미 설치본에만** 들어간다(화면으로 안 나간다)."
    say "     _UNC_PATH 만 화면([위치 복사])으로 나간다."
    say "  ⚠️ 값에 따옴표를 두르지 않는다 — 큰따옴표 안에서는 역슬래시가 먹힌다."
    if [ -n "$miss" ] && [ "$MODE" != go ]; then
      say "  🔵 지금은 **아무것도 안 적었다.** 적는 것은 --go 가 한다(3-ㄷ)."
    fi
  else
    bad "as.env 가 없다: $AS_ENV"
    say "    → 없는 env_file 하나면 docker compose 명령이 **통째로** 안 먹는다."
  fi
  for f in po.env auth.env meters.env improvements.env leave.env; do
    [ -f "$ENVD/$f" ] || bad "$f 가 없다: $ENVD/$f (compose 가 통째로 실패한다)"
  done

  # ── 1-ㅁ. compose — 태그 한 줄 + **새 볼륨 하나** ────────────────────
  step "1-ㅁ. compose ($CF_EFF)"
  say "  🔴 이번 판에서 compose 가 바뀌는 자리는 **둘**이다:"
  say "     ㄱ) app-as 의 image 한 줄 ($OLD_AS → $TAG_AS)"
  say "     ㄴ) app-as 에 **연락서 볼륨 하나**(긴 문법 · 네 줄)"
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
    say "       🔴 이번엔 **손으로 sed 로 고치지 마세요** — 태그만이 아니라"
    say "          **볼륨 네 줄**도 함께 들어가야 합니다. 개발 PC 에서 고친 파일을"
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
  # ── 🔴 이번 배포의 **새 볼륨** ──────────────────────────────────────
  say "  🔴 이번에 새로 붙는 연락서 공유폴더:"
  svc_block "$CF_EFF" app-as | grep -q "target: $CONTACT_MNT" \
    && ok "app-as 가 $CONTACT_MNT 를 붙인다" \
    || bad "app-as 에 $CONTACT_MNT 가 **없다** — 🔴 연락서 연동이 통째로 꺼진다"
  svc_block "$CF_EFF" app-as | grep -q "2_AS센터" \
    && ok "원본 경로에 2_AS센터(**대문자 AS**)가 들어 있다" \
    || bad "원본 경로에 2_AS센터 가 없다 — 🔴 소문자(2_as센터)면 빈 폴더가 된다"
  svc_block "$CF_EFF" app-as | grep -q "3. 연락서(활용)" \
    && ok "원본 경로가 「3. 연락서(활용)」을 지난다" \
    || bad "원본 경로에 「3. 연락서(활용)」이 없다"
  svc_block "$CF_EFF" app-as | grep -q "2. 연락서" \
    && ok "원본 경로가 「2. 연락서」까지 들어간다" \
    || bad "원본 경로가 연락서 폴더까지 들어가지 않는다"
  svc_block "$CF_EFF" app-as | grep -q "type: bind" \
    && ok "긴 문법(type: bind)으로 적혀 있다 (경로에 공백·괄호가 있다)" \
    || bad "긴 문법이 아니다 — 🔴 짧은 문법은 이 경로에서 깨진다"
  # 🔴 일부러 안 붙이는 둘
  svc_block "$CF_EFF" app-po | grep -q "$CONTACT_MNT" \
    && say "    ⚠️ app-po 에도 $CONTACT_MNT 가 붙어 있다 — PO 에는 이 기능이 없다(없어도 된다)" \
    || ok "app-po 에는 안 붙였다 (맞다 — PO 저장소에 연락서 화면이 없다)"
  svc_block "$CF_EFF" tools-as | grep -q "$CONTACT_MNT" \
    && say "    ⚠️ tools-as 에도 붙어 있다 — 쓰는 스크립트가 없다(없어도 된다)" \
    || ok "tools-as 에는 안 붙였다 (맞다 — 교산 이식용이고 쓸 이유가 없다)"
  svc_block "$CF_EFF" tools-as | grep -q 'read_only: true' \
    && ok "tools-as 의 read_only: true 가 그대로다 (걷지 않았다)" \
    || say "    ⚠️ tools-as 에 read_only: true 가 안 보인다 — 원래 그랬는지 보세요"
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
    say "    🔵 이번 판은 **DB 를 바꾸지 않는다** — PO 가 영향을 받을 자리가 없다."
  else
    bad "app-po 의 DATABASE_URL 이 app-as 와 다르다 — 🔴 PO 가 엉뚱한 DB 를 본다"
  fi

  # ── 1-ㅂ. ② 폴더를 컨테이너 안에서 **실제로 열어 본다** ─────────────
  step "1-ㅂ. 폴더 — 주인·모드가 아니라 컨테이너 안에서 실제로 연다"
  say "  🔴 보는 자리가 둘로 갈린다:"
  say "     ㄱ) **이미 붙어 있는 자리**(/data · /templates · /quote-archive ·"
  say "        $PORTAL_MNT)는 지금 도는 컨테이너 안에서 본다."
  say "     ㄴ) **이번 배포로 새로 붙는 자리**($CONTACT_MNT)는 도는 2.0 에"
  say "        아직 없다 — 호스트 경로를 **임시로 붙여** 따로 본다."
  if [ "$PROBE_WRITE" = 1 ]; then
    say "  (교체되는 A/S 의 /data 는 읽기+쓰기를 본다. 시험 파일은 만들었다 지운다.)"
  else
    say "  🔵 --check 라서 **읽기만** 해 본다 — 아무 파일도 만들지 않는다."
    say "     쓰기는 --go 의 3-ㄴ 과 스모크에서 본다."
  fi
  # 호스트 쪽에 그 폴더가 **있는지**부터. 없으면 볼륨이 빈 폴더로 붙는다.
  if [ -d "$CONTACT_SRC" ]; then
    ok "호스트에 연락서 폴더가 있다"
    say "    $CONTACT_SRC"
    n_top=$(ls -1 "$CONTACT_SRC" 2>/dev/null | wc -l | tr -d ' ')
    say "    · 맨 위 칸의 항목 ${n_top:-?}개"
    if [ "${n_top:-0}" = 0 ]; then
      bad "🔴 **0개다.** 연락서 폴더가 수백 개 있어야 한다 — 경로가 틀렸다"
      say "    → 🔴 「2_AS센터」 의 AS 가 **대문자**인지 보세요."
      cmd "ls -d /volume1/2_AS*"
    fi
  else
    bad "호스트에 연락서 폴더가 **없다**: $CONTACT_SRC"
    say "    → 🔴 「2_AS센터」 의 AS 가 **대문자**인지 보세요. 소문자로 적으면"
    say "       docker 가 **빈 폴더를 만들어 붙입니다** — 그러면 앱이 「짝이 없다」고"
    say "       보고 **새 폴더를 수백 개 만듭니다.**"
    cmd "ls -d /volume1/2_AS*"
  fi
  if [ "$PROBE_WRITE" = 1 ]; then M_DATA=rw; else M_DATA=ro; fi
  probe_svc app-as dss-as "A/S" "/data:$M_DATA /templates:ro" "$ATT $TEMPLATES"
  # 🔴 이번 배포로 **새로 붙는** 볼륨. 도는 컨테이너에는 아직 없다.
  probe_new_volume "$CONTACT_SRC" "$CONTACT_MNT" "연락서 공유폴더"
  # 🔴 교체 안 되는 곳 — 「아직 읽히는가」만 본다. 쓰기 시험을 하지 않는다.
  probe_svc app-po           dss-po           PO       "/data:ro"         "$ATT"
  probe_svc app-meters       dss-meters       계측기   "/data:ro"         "$MF_METERS"
  probe_svc app-improvements dss-improvements 개선요청 "/data/uploads:ro" "$UP_IMP"
  # 🔴 공유폴더 둘은 위 틀에 안 넣는다 — 경로에 빈칸과 한글이 있고, 무엇보다
  #    여기서는 ACL 을 **걷으면 안 된다**(직원의 탐색기 접근이 끊긴다).
  say "  이미 붙어 있는 공유폴더 둘 — 🔴 읽기만 본다. ACL 을 걷지 않는다:"
  for rec in "dss-as|A/S|/quote-archive" "dss-po|PO|/quote-archive" \
             "dss-as|A/S|$PORTAL_MNT"; do
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
  say "  🔴 그래도 백업의 문은 그대로 둔다 — 이번 판은 **직원의 서류함에 폴더와"
  say "     파일을 만든다.** --go 는 오늘 뜬 $AS_DB 백업이 없으면 멈춘다(3-ㄱ)."
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
    say "    🔵 야간 백업은 **02:30** 이다 — 자정 넘어 배포하면 여기 걸린다."
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
  # 새 tar 약 124MB + 실은 이미지 약 582MB + 첨부 하드링크(공간 0).
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
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
  if have_img "$TAG_AS"; then
    say "  $TAG_AS 구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_AS" --format '{{.Size}}' 2>/dev/null)"
    say "        ($OLD_AS 는 582MB 였다 — 🔴 **크기로는 못 가른다.**)"
    say "  🔴 그래서 **안의 여섯 자리**로 가른다:"
    inside_check "$TAG_AS"
    say "  🔵 글자 인식기(public/ocr) 회귀 검사 — 2.0 의 것이 그대로 있는가:"
    ocr_check "$TAG_AS"
  else
    notloaded "$TAG_AS 가 아직 안 실려 **안을 못 봤다** (머리말 ⑤ — ✗ 가 아니다)"
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
  # 🔴 이번 판은 **태그 한 줄 + 볼륨 네 줄 + 주석**이 달라야 한다.
  say "  🔵 지금 것과 달라진 줄 (image 한 줄 · type: bind 볼륨 · 그 주석):"
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
  echo "DSS 열넷째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     되돌리는 것은 **이미지 하나**다:  $TAG_AS → $OLD_AS"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔵 DB 는 되돌릴 것이 **없다.** 이번 판은 DB 를 안 바꿨다.       ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     마이그레이션이 0건이고 스키마가 그대로다. 남은 것은 audit_logs 의"
  say "     줄 몇 개(연락서 폴더를 만들었다는 기록)뿐이고, 그 표도 칸도 2.0 이"
  say "     이미 아는 것이다 — **지우지 마라.** 지우면 기록만 사라진다."
  say
  say "  ⚠️ 🔴 **공유폴더에 만들어진 폴더·파일은 그대로 남는다.**"
  say "     2.1 이 도는 동안 접수된 건마다 연락서 폴더가 생겼을 수 있다."
  say "     그 폴더들은 **직원의 서류함에 그대로 둔다** — 사람이 쓰던 그 폴더와"
  say "     같은 꼴이라 지울 이유가 없고, 지우면 그 안의 파일까지 함께 간다."
  say "     🔴 스크립트는 그 폴더를 **세지도 지우지도 않는다.**"

  step "1. 옛 이미지가 아직 NAS 에 있는지 먼저 본다"
  if have_img "$OLD_AS"; then
    ok "$OLD_AS 있다 ($(img_id "$OLD_AS" | cut -c1-19)…)"
  else
    bad "$OLD_AS 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"
  fi

  step "2. compose 를 되돌린다 — 🔴 **사본으로 되돌린다**"
  say "  🔴 이번 판은 태그만 바뀐 것이 아니다 — **볼륨 네 줄**이 함께 들어갔다."
  say "     그래서 sed 로 태그만 내리면 **2.0 에 쓰지 않는 볼륨이 남는다.**"
  say "     (남아도 2.0 은 그 자리를 안 쓰므로 해롭진 않다. 그래도 사본이 깔끔하다.)"
  say "  --go 가 옛 compose 를 아래에 남겼다 (가장 최근 것):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -3 | sed 's/^/      /'
  cmd "cd /volume1/dss/deploy"
  cmd "cp \$(ls -1t ../backups/docker-compose.nas.yml.* | head -1) ."
  say "      (파일 이름이 길면 위 한 줄 대신 두 줄로 나눠 치세요)"
  say "  사본이 없을 때만 — 태그만 내린다:"
  cmd "F=docker-compose.nas.yml"
  cmd "sed -i 's|image: $TAG_AS|image: $OLD_AS|' \$F"
  cmd "grep -n 'image: dss-as' \$F"

  step "3. as.env — 🔴 **되돌릴 필요가 없다**"
  say "  덧붙인 세 줄은 $OLD_AS 가 **읽지 않는다**(그 코드가 없다). 그대로 두세요."
  say "  그래도 되돌리고 싶다면 사본이 여기 있습니다:"
  ls -1t "$BKD"/as.env.* 2>/dev/null | head -3 | sed 's/^/      /'

  step "4. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-as"
  script_file_hint "18-rollback"

  step "5. 🔴 사람에게 알릴 것"
  say "  되돌리면 **연락서 [폴더 열기]가 없어진다.** 도우미는 그대로 두세요 —"
  say "  2.0 의 견적서 · 현황표 [폴더 열기]는 새 도우미로도 그대로 돕니다"
  say "  (설치본에 루트를 여럿 심고 차례로 해 보는 구조다)."

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
echo "DSS 열넷째 배포 · 2026-10-05 · $(date '+%F %T')"
echo "  🔴 올라가는 것은 **하나**:  $OLD_AS → $TAG_AS"
echo "  🔴 멈추는 것도 **하나**:  dss-as"
echo "  🔴 이번 판의 줄기 둘: **연락서 공유폴더 연동**(커밋 11개) ·"
echo "     주간보고 「현 상태」 블록 단위 편집(1개)"
echo "  🔵 **마이그레이션 0건** — 운영 DB 는 112 그대로다. DB 를 안 바꾼다"
echo "  🔴 **새 볼륨 하나** — $CONTACT_MNT (직원의 서류함 · 쓰기 가능)"
echo "  🔴 **as.env 에 세 줄** — CONTACT_FOLDER_ARCHIVE_DIR · _UNC_ROOT · _UNC_PATH"
echo "  🔵 도구 이미지 그대로 ($KEEP_ASTOOLS)"
echo "  · 건드리지 않는 아홉 — $KEEP_AUTH · $KEEP_ASTOOLS · $KEEP_METERS"
echo "    · $KEEP_METERSTOOLS · $KEEP_IMP · $KEEP_IMPTOOLS"
echo "    · $KEEP_PO · $KEEP_LEAVE · $KEEP_LEAVETOOLS"
if ! pinned; then
  echo "  ⚠️ 🔴 **이미지 기대값 셋이 아직 비어 있습니다**(SZ_AS · MD5_AS · WANT_CFG_AS)."
  echo "     개발 PC 에서 2.1 을 굽고 재어 채우기 전에는 --go 가 시작하지 않습니다."
  echo "     재는 차례는 이 파일 머리말 「돌리기 전에 — 값 셋을 채워야 한다」."
fi
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**"
              echo "     🔵 아직 안 온 것 · 안 실린 것은 ⚠️ 로만 말한다(✗ 가 아니다)." ;;
  preload)    echo "  🔵 --preload — 새 이미지를 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — 볼륨을 붙이고 as.env 세 줄을 덧붙이고 A/S 하나만 교체한다."
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
    else
      echo "  🔴 아직 --go 를 부를 수 없습니다 — 이미지 기대값 셋이 비어 있습니다."
      echo "     개발 PC 에서 2.1 을 굽고 재어 이 파일에 채운 뒤 다시 올리세요."
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
  say "     이 파일 머리말 「돌리기 전에 — 값 셋을 채워야 한다」의 차례대로"
  say "     개발 PC 에서 재어 SZ_AS · MD5_AS · WANT_CFG_AS 를 채우고, 이 파일을"
  say "     다시 올린 뒤(md5 대조) 돌리세요."
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

# ══ 3. 🔴 멈추기 전에 — 백업 · 공유폴더 · as.env ═══════════════════════
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
  say "     이번 판은 DB 를 바꾸지 않습니다. 그래도 **직원의 서류함에 폴더와"
  say "     파일을 만드는** 배포라, 백업 없이 시작하지 않습니다."
  say "     먼저 이것부터 (종료 코드 0 이어야 합니다):"
  cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  say "     ✓ $AS_DB 줄이 찍혀야 합니다. 그 뒤에 다시:"
  cmd "bash $0 --go"
  stop "백업 없이 시작하지 않습니다. **앱도 DB 도 그대로입니다.**"
fi

# ── 3-ㄴ. 🔴 새 공유폴더에 **정말 쓸 수 있는가** (16번에서 가져옴) ─────
step "3-ㄴ. 연락서 공유폴더 쓰기 · 폴더 만들기 시험 (uid 1000 · gid 100)"
say "  🔴 여기는 /volume1/dss 가 아니라 **직원이 탐색기로 쓰는 서류함**이다."
say "     ACL 을 걷지 않는다 — 걷으면 직원의 접근이 끊긴다. 컨테이너가 쓸 수"
say "     있는지만 실제로 해 보고, 안 되면 배포를 멈춘다(앱은 아직 살아 있다)."
say "  🔵 2026-10-05 에 손으로 같은 시험을 해 WRITE-OK 를 받았다. 여기서 다시 한다."
if [ ! -d "$CONTACT_SRC" ]; then
  bad "폴더가 없다: $CONTACT_SRC"
  say "    → 🔴 2_AS센터 의 AS 가 **대문자**인지 보세요."
  cmd "ls -d /volume1/2_AS*"
  stop "경로를 확인하세요. **앱도 DB 도 그대로입니다.**"
fi
ok "폴더가 있다"
N_TOP=$(ls -1 "$CONTACT_SRC" 2>/dev/null | wc -l | tr -d ' ')
say "  · 맨 위 칸의 항목 ${N_TOP:-?}개"
if [ "${N_TOP:-0}" = 0 ]; then
  bad "🔴 **0개다.** 연락서 폴더가 수백 개 있어야 한다 — 경로가 틀렸다"
  say "    → 그대로 두면 앱이 **전부 짝 없음으로 보고 새 폴더를 수백 개 만든다.**"
  cmd "ls -d /volume1/2_AS*"
  stop "경로를 확인하세요. **앱도 DB 도 그대로입니다.**"
fi
# compose 의 app-as 와 **같은 조건**으로 시험해야 뜻이 있다 — gid 100(users).
if "$DOCKER" run --rm --group-add 100 -v "$CONTACT_SRC:$CONTACT_MNT" \
     --entrypoint sh "$TAG_AS" -c \
     'set -e; t='"$CONTACT_MNT"'/.dss-write-test; : > "$t"; rm -f "$t";
      d='"$CONTACT_MNT"'/.dss-dir-test; mkdir "$d"; rmdir "$d"' >/dev/null 2>&1; then
  ok "파일을 만들고 지울 수 있다 · 폴더를 만들고 지울 수 있다"
else
  bad "연락서 공유폴더에 쓸 수 없다"
  say "    🔴 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기 접근이 끊긴다."
  say "       compose 의 app-as 에 group_add: [\"100\"] 이 있는지부터 보세요."
  say "    → 이 기능만 빼고 배포하려면 as.env 에 **세 줄을 안 넣으면** 된다:"
  say "      연락서 [폴더 열기] · 폴더 만들기 · 파일 사본만 꺼지고 나머지는 그대로."
  stop "앱은 아직 살아 있습니다. **DB 도 그대로입니다.**"
fi
acl_inherit_check "$CONTACT_SRC" "연락서 공유폴더" "$TAG_AS" "$CONTACT_MNT" \
  || stop "앱이 만들어도 직원이 못 여는 폴더·파일이 쌓입니다. **아무것도 안 바꿨습니다.**"

# ── 3-ㄷ. 🔴 as.env 에 세 줄을 덧붙인다 (아직 아무것도 안 멈췄다) ──────
#
# 🔴 이 PC 의 as.env 를 올리는 것이 아니다. **NAS 의 파일을 읽고 없는 줄만**
#    덧붙인다. 이미 있으면 건드리지 않는다(두 번 돌려도 안전하다).
step "3-ㄷ. as.env 에 설정 **세 줄** 덧붙이기"
build_env_values
cp -p "$AS_ENV" "$BKD/as.env.$STAMP"; chmod 600 "$BKD/as.env.$STAMP"
ok "as.env 사본 — backups/as.env.$STAMP (root 600)"
# 🔴 견적서 셋 · 현황표 다섯이 그대로 있는지 **적기 전에** 한 번 더 본다.
for k in $QUOTE_KEYS $PORTAL_KEYS; do
  grep -q "^$k=" "$AS_ENV" || {
    bad "$k 가 as.env 에 없다 — 🔴 누가 덮어썼다"
    stop "as.env 가 온전하지 않습니다. 덧붙이지 않았습니다. **앱도 DB 도 그대로입니다.**"
  }
done
ok "견적서 세 줄 · 현황표 다섯 줄이 그대로 있다 — 덧붙여도 안전하다"
# 파일이 개행으로 끝나지 않으면 먼저 한 줄 띄운다(마지막 줄에 붙어 버린다).
[ -n "$(tail -c 1 "$AS_ENV")" ] && printf '\n' >> "$AS_ENV"
ADDED=0
for k in $ENV_KEYS; do
  if grep -q "^$k=" "$AS_ENV"; then
    say "  · $k 는 **이미 있다** — 건드리지 않는다"
    continue
  fi
  [ "$ADDED" = 0 ] && {
    printf '\n# ── 연락서 공유폴더 — %s 18-deploy.sh 가 덧붙임 ──\n' \
      "$TODAY" >> "$AS_ENV"
  }
  printf '%s\n' "$(env_line_for "$k")" >> "$AS_ENV"
  ADDED=$((ADDED + 1))
  ok "$k 덧붙였다"
done
chown root:root "$AS_ENV"; chmod 600 "$AS_ENV"
if [ "$ADDED" = 0 ]; then
  ok "세 줄이 모두 이미 있었다 — as.env 를 한 글자도 안 바꿨다"
else
  ok "$ADDED 줄을 덧붙였다 (모드 600 · root:root 로 되돌렸다)"
fi
# 🔴 세 줄은 **폴더 경로**다 — 비밀이 아니고, 사람이 눈으로 맞춰 봐야 하는
#    값이라 그대로 찍는다. as.env 의 다른 줄은 한 글자도 찍지 않는다.
say "  지금 as.env 에 들어 있는 세 줄 (값까지 그대로):"
for k in $ENV_KEYS; do
  printf '      %s\n' "$(grep "^$k=" "$AS_ENV" | head -1)"
done
say "  🔴 호스트 토막의 출처: $ENV_SRC_NOTE → $ENV_HOST ($ENV_HOST_WHY)"

# ── 3-ㄹ. 첨부 하드링크 스냅숏 ─────────────────────────────────────────
#
# 🔵 DB 덤프는 뜨지 않는다 — 이번 판은 DB 를 바꾸지 않는다(마이그레이션 0건).
#    대신 **첨부 폴더**의 스냅숏은 남긴다. 이번 판이 올린 파일을 다루는 길
#    (api/repair-cases/[id]/attachments/route.ts)을 건드렸기 때문이다.
#    cp -al 이라 즉시 끝나고 공간을 쓰지 않는다.
step "3-ㄹ. 첨부 하드링크 스냅숏 (DB 덤프는 뜨지 않는다 — DB 를 안 바꾼다)"
BK=$BKD/predeploy-$STAMP
mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
if [ -d "$ATT" ]; then
  cp -al "$ATT" "$BK/as-attachments" 2>/dev/null \
    && ok "첨부 스냅숏 (cp -al 하드링크 — 즉시 · 공간 0) → $BK" \
    || bad "첨부 스냅숏 실패"
else
  bad "첨부 폴더가 없다: $ATT"
fi
say "  🔵 공유폴더(연락서 · 견적서 · 현황표)는 **스냅숏을 뜨지 않는다** — 직원의"
say "     서류함이라 우리가 사본을 만들 자리가 아니다. NAS 의 야간 백업이 본다."

# ── 3-ㅁ. 건드리지 않는 쪽의 **시작 시각**을 적어 둔다 ─────────────────
#
# 🔴 「안 멈췄다」를 말로 하지 않는다. 교체 뒤에 이 값과 그대로인지 본다.
step "3-ㅁ. 건드리지 않는 쪽의 시작 시각을 적어 둔다 (뒤에서 대조한다)"
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
say "     (compose 와 as.env 는 이미 바뀌었지만, 그 둘만으로는 아무 일도"
say "      일어나지 않습니다 — $OLD_AS 는 그것을 읽지 않습니다.)"
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
say "  🔵 새 컨테이너는 **연락서 볼륨을 달고** 뜬다 — 그래서 up -d 가 필요하다"
say "     (restart 로는 볼륨이 안 붙는다)."
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

# 5-ㄱ. 새 컨테이너로 폴더를 **실제로 열어 본다** — 🔴 연락서가 여기 들어온다
say "  5-ㄱ. 폴더를 새 컨테이너 안에서 실제로 연다 (연락서는 폴더 만들기까지)"
probe_svc app-as dss-as "A/S" \
  "/data:rw /templates:ro $CONTACT_MNT:rwd" "$ATT $TEMPLATES"

say "  5-ㄴ. 이미 있던 공유폴더 둘 — 🔴 읽기만 본다 (이번 판은 안 건드렸다)"
if running dss-as; then
  "$DOCKER" exec dss-as sh -c 'ls -1 /quote-archive >/dev/null 2>&1' \
    && ok "A/S 가 견적서 공유폴더를 읽는다" \
    || { bad "A/S 가 견적서 공유폴더를 **못 읽는다** — 발행이 실패한다"
         say "    🔴 여기는 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기가 끊긴다."; }
  "$DOCKER" exec dss-as sh -c "ls -1 '$PORTAL_MNT' >/dev/null 2>&1" \
    && ok "A/S 가 현황표 공유폴더($PORTAL_MNT)를 읽는다" \
    || bad "A/S 가 $PORTAL_MNT 를 **못 읽는다** — 🔴 [공유폴더에 저장]이 죽는다"
else
  bad "dss-as 컨테이너가 떠 있지 않다"
fi

# 5-ㄷ. 🔴 as.env 의 세 줄이 **컨테이너 안까지** 그대로 왔는가
say "  5-ㄷ. 🔴 연락서 설정 셋이 컨테이너 안까지 그대로 왔는가"
if running dss-as; then
  "$DOCKER" exec dss-as sh -c "[ -d \"\$CONTACT_FOLDER_ARCHIVE_DIR\" ]" >/dev/null 2>&1 \
    && ok "CONTACT_FOLDER_ARCHIVE_DIR 이 **실제로 있는 폴더**를 가리킨다" \
    || bad "CONTACT_FOLDER_ARCHIVE_DIR 이 가리키는 폴더가 컨테이너 안에 없다"
  N_IN=$("$DOCKER" exec dss-as sh -c "ls -1 \"\$CONTACT_FOLDER_ARCHIVE_DIR\" 2>/dev/null | wc -l" 2>/dev/null | tr -d ' ')
  say "    · 컨테이너가 보는 연락서 폴더 수: ${N_IN:-?}"
  if [ "${N_IN:-0}" = 0 ]; then
    bad "🔴 컨테이너 안에서 **0개**다 — 빈 폴더가 붙었다. 경로의 대소문자를 보세요"
  else
    ok "컨테이너가 연락서 폴더 ${N_IN}개를 본다"
  fi
  # 🔴 역슬래시가 삼켜졌는가 — 16번이 이 검사로 잡았다.
  for k in CONTACT_FOLDER_ARCHIVE_UNC_ROOT CONTACT_FOLDER_ARCHIVE_UNC_PATH; do
    v=$("$DOCKER" exec dss-as printenv "$k" 2>/dev/null)
    n=$(backslash_count "$v")
    [ "${n:-0}" -ge 4 ] && ok "$k 의 역슬래시가 ${n}개 — 삼켜지지 않았다" \
      || bad "$k 의 역슬래시가 ${n:-0}개뿐이다 — 🔴 따옴표가 먹은 것이다"
  done
  # 🔵 견적서 · 현황표도 그대로인지 한 번 더
  for k in QUOTE_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT; do
    v=$("$DOCKER" exec dss-as printenv "$k" 2>/dev/null)
    [ -n "$v" ] && ok "$k 가 컨테이너 안에 그대로 있다" \
      || bad "$k 가 컨테이너 안에 **없다** — 🔴 그쪽 [폴더 열기]가 죽는다"
  done
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
echo "  🔵 마이그레이션 0건 — DB 는 손대지 않았습니다"
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
║ 🔴 **먼저 할 일 — 쓰는 분들이 도우미를 다시 설치해야 합니다.**        ║
╚════════════════════════════════════════════════════════════════════╝

  이번 판은 도우미에 둘을 더했습니다:
    ㄱ) **연락서 루트** — 그 폴더를 열 수 있게
    ㄴ) **파일 열기** 동작과 **IP 를 「로컬 인트라넷」에 등록**
        (파일을 열 때 뜨던 「신뢰할 수 있는 출처인가요」 확인창이 없어집니다)
  🔴 **옛 도우미는 새 주소를 받으면 조용히 아무 일도 하지 않습니다.**

  받는 길 — 🔴 **반드시 A/S 화면에서**:
    A/S → 수리 건 상세 → [폴더 열기] → [설치 명령 복사]
      → PowerShell 창에 붙여넣기 (관리자 권한 필요 없음)

  🔴 **PO 화면에서 받으면 안 됩니다.** 도우미는 PC 당 **한 벌**이라
     PO 가 내준 설치본이 A/S 것을 덮어씁니다 — 그 PC 의 **고객사 현황표
     [폴더 열기]가 먹통이 됩니다.**

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. 🔴 **수리 건 상세의 [폴더 열기]** — 이번 판의 중심입니다.
      · 연락서 폴더가 **이미 있는 건**에서 눌러 보세요 — 탐색기가 열려야 합니다.
      · 🔴 **두 번 눌러 보세요** — 두 번째도 똑같이 열려야 맞습니다.
      · 폴더가 **없는 건**에서는 「만들까요」를 묻고, **사람이 한 번 더 눌러야**
        만들어져야 맞습니다. 비슷한 폴더가 여럿이면 **만들지 않고 목록**을
        보여 주어야 맞습니다(앱이 고르지 않습니다).
      · 도우미가 없다는 안내가 뜨면 [설치 명령 복사] → PowerShell 붙여넣기.
      · [위치 복사]를 눌러 탐색기 주소창에 붙여넣어 보세요 — 연락서 폴더들이
        모여 있는 그 폴더가 열려야 맞습니다.
   2. 🔴 **파일 관리 화면의 「공유폴더」 구역**
      · 그 건의 연락서 폴더 안이 보입니까.
      · **하위 폴더로 들어가** 보세요. 위로 올라오는 길도 있습니까.
      · 🔴 **파일을 눌러** 보세요 — 열려야 맞고, 열 때 **확인창이 뜨지 않아야**
        맞습니다(도우미를 다시 설치한 PC 에서).
   3. 🔴 **접수해 보세요** — 접수하면 연락서 폴더가 **저절로 생겨야** 맞습니다.
      · 🔴 폴더 만들기가 실패해도 **접수는 그대로 되어야** 맞습니다(곁다리입니다).
      · 탐색기에서 그 폴더를 열어 **직원 계정으로 보이는지** 꼭 보세요.
   4. 🔴 **파일을 올려** 보세요 — 그 사본이 연락서 폴더의 **분류 폴더**에
      사람이 읽는 이름으로 들어가야 맞습니다. 🔴 **덮어쓰지 않고** 같은 이름이면
      「 (2)」 로 비켜 가야 맞습니다.
   5. **[DATA에 저장]** — 폴더 안의 「DATA」 폴더에 꽂혀야 맞습니다.
      🔴 **여러 개를 고르면 낱개로** 들어가야 맞습니다(묶음 파일이 아닙니다).
   6. **주간보고** — 「현 상태」 머리줄의 [수정] 하나로 그 **블록**이 열립니까.
      🔴 단계가 옮겨 가는 길 · 권한 · 이력은 전과 같아야 맞습니다.
   7. 🔴 **견적서 [폴더 열기] · 고객사 현황표 [폴더 열기]가 그대로입니까** —
      도우미를 다시 설치한 PC 에서 꼭 보세요. 셋이 한 벌에 함께 심깁니다.
   8. 🔴 **포털 · 계측기 · 개선요청 · PO · 휴가가 그대로입니까** — 이번 판은
      그 다섯을 건드리지 않았습니다. (스크립트가 5-ㅂ 에서 시작 시각으로 이미
      확인했습니다.)

🔴 사람이 이어서 할 일:
  · **쓰는 분들에게 도우미 다시 설치를 알립니다**(위 상자).
  · 직원에게 알립니다 — 「수리 건에서 연락서 폴더를 바로 연다」 ·
    「접수하면 폴더가 저절로 생긴다」 · 「올린 파일이 그 폴더에도 꽂힌다」.
  · 🔴 **며칠 뒤 공유폴더를 한 번 보세요** — 폴더가 **쓸데없이 늘지 않았는지.**
    늘었다면 경로나 이름 규칙이 어긋난 신호입니다(그때는 Claude 에게 알리세요).
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.
  · 내일 아침 백업을 한 번 더 보세요 — 다섯이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -7
  · 첨부 스냅숏은 $BK 에 있습니다. 한 주쯤 두었다 지우세요.

되돌리기 안내:  bash $0 --rollback
  🔵 **DB 는 되돌릴 것이 없습니다** — 이번 판은 DB 를 바꾸지 않았습니다.
  🔴 공유폴더에 생긴 폴더·파일은 **그대로 둡니다.** 사람이 쓰던 그 폴더와
     같은 꼴이고, 지우면 그 안의 파일까지 함께 갑니다.
ANNOUNCE
exit "$FAIL"
