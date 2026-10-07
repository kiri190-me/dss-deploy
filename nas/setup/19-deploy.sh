#!/bin/bash
# /volume1/dss/setup/19-deploy.sh — 2026-10-08 열다섯째 배포
#
# ── 무엇이 올라가는가 ───────────────────────────────────────────────────
#   사내 사이트 여섯 중 **하나**만 올린다.
#
#     A/S  dss-as:2.1  →  **dss-as:2.2**
#
#   나머지 다섯(포털 1.5 · 계측기 1.3 · 개선요청 0.3 · PO 0.3 · 휴가 0.1)은
#   **건드리지 않는다. 멈추지도 않는다.**
#
#   🔴 이 스크립트는 **17번과 18번을 합친 것**이다:
#     · 17번에서 **마이그레이션 코드 전부**를 되가져왔다(이번은 **3건**이다).
#       18번은 0건이라 그 코드를 걷어냈었다.
#     · 18번에서 **새 볼륨 검사**(probe_new_volume)와 **as.env 줄 덧붙이기**를
#       가져왔다. 🔴 다만 새 볼륨이 **읽기 전용**이라 검사의 뜻이 뒤집힌다 —
#       아래 ②를 보라.
#   그리고 17 · 18번과 같은 것 하나: **도구 이미지를 다시 굽지 않았다**
#   (dss-as-tools:1). 마이그레이션은 이미지가 아니라 **볼륨**으로 갈아 끼운다.
#
# ── 이 판에 무엇이 담겼나 (사람에게 설명할 말로) ────────────────────────
#
#   10/6 아침부터 10/8 새벽까지 쌓인 **커밋 51개**(9a6ba31 ~ 1f56947)다.
#   줄기는 넷이다.
#
#   ① 🔴 **제품 모델·종류가 「공유폴더의 자리」를 가리킨다** — 이 판의 중심이고
#      새 표 둘이 여기서 나온다(0113 · 0114).
#      제품 종류마다 같은 서류를 돌려 쓴다(인수시 체크시트 · 작업 수순과 자료 ·
#      통전 체크시트 …). 그것을 앱에 **올리지 않고 자리만 적어 둔다**
#      (사용자 결정 2026-10-07) — 올리면 같은 파일이 모델 수만큼 복사되고,
#      사내에서 원본을 고쳐도 앱 안의 사본은 그대로 남는다.
#      · 제품 종류 상세 · 제품 모델 상세에 「공유폴더에서 가리킨 서류」 구역
#      · 고르는 창이 폴더를 **한 칸씩** 읽어 보여 주고, 이름으로 **거른다**
#      · 수리 건 상세 **파일 관리**에도 그 서류가 **보기·열기만** 으로 나온다
#      🔴 **앱은 이 폴더를 읽기만 한다** — 만들지도 쓰지도 지우지도 않는다
#         (src/lib/storage/repair-docs-archive.ts · repair-docs-entries.ts 의
#          머리말이 그 사실을 못 박았고, 원본을 글자로 읽는 시험이 지킨다).
#
#   ② **첨부파일 영구 삭제** — 휴지통에서 **디스크 파일까지** 지운다.
#      이 시스템에 영구 삭제가 **아예 없었다**(지우기는 전부 휴지통행이었다).
#      🔴 권한은 휴지통과 **같은 문**이다(resolveWriteActor) — 새 권한을 만들지
#         않았다. 차례는 **DB 먼저, 파일은 커밋 뒤**다.
#
#   ③ **도우미 재설치 안내를 세대로 관리한다** — `dss.helper.gen1.openfile`.
#      파일 열기가 되는 도우미가 이미 있으면 안내와 [설치 명령 복사]를 그만 낸다.
#      🔴 그런데 **이번 판은 도우미에 루트를 하나 더한다**(아래 ③절) — 그래서
#         이번만은 **모든 PC 가 다시 설치해야 한다.**
#
#   ④ **견적서 쪽 잔손질 여럿** — 견적서 목록을 공용 묶음 화면으로 · 발행번호
#      미리 채우기 · 공유폴더에서 번호 읽기 · [Excel 보기] · 머리 카드 한 줄 ·
#      내 작업기록 달별 모아 보기 · 전체 현황을 인수번호 내림차순으로.
#      🔵 이 줄기에는 DB 스키마가 없다.
#
# ══ 🔴 ① 마이그레이션 **셋** — 전부 더하기만 한다 ══════════════════════
#
#   운영 DB(dss_as)는 지금 **112**, 적용하면 **115** 가 된다.
#
#     0112_gray_hex.sql
#       ALTER TABLE attachments ADD COLUMN product_model_kind …   ← 칸 하나
#       CREATE INDEX attachments_product_model_kind_not_deleted_idx
#       ALTER TABLE attachments ADD CONSTRAINT attachments_kind_owner_alone CHECK(…)
#     0113_dizzy_zuras.sql
#       CREATE TYPE public.share_doc_entry_kind AS ENUM('FILE','FOLDER')
#       CREATE TABLE product_model_kind_share_docs (…)             ← 표 하나
#     0114_clean_whistler.sql
#       CREATE TABLE product_model_share_docs (…)                  ← 표 하나
#
#   🔴 **DROP · TRUNCATE · DELETE FROM 이 한 줄도 없다.** 표도 칸도 자료도
#      지우지 않는다 — 칸 하나와 표 둘을 **더할** 뿐이다. 그래서 db:preflight 가
#      「사라질 자료」로 걸리지 않고 종료 코드 0 이다.
#
#   ⚠️ 🔴 **「DELETE」 라는 글자만 보고 세면 안 된다.** 0113 · 0114 의 외래키에
#      `ON DELETE restrict` · `ON DELETE cascade` 가 **세 번** 나온다. 17번은
#      `grep -iE 'DROP|DELETE|TRUNCATE'` 로 셌는데 그 잣대를 이번 판에 그대로
#      대면 **멀쩡한 마이그레이션이 ✗ 가 된다.** 그래서 이 스크립트는
#      `DROP` · `TRUNCATE` · **`DELETE FROM`** 으로 센다 — 앱의 판정기
#      (src/lib/db/migration-safety.ts:94)가 쓰는 정규식과 **같은 잣대**다.
#
#   🔵 0112 의 enum 타입 `product_model_kind` 는 **이미 운영에 있다**
#      (0030 이 만들고 0033 이 TOTAL_CONTROLLER 를 더했다 — 둘 다 112 안쪽).
#      이번에 새로 생기는 타입은 `share_doc_entry_kind` 하나뿐이다.
#
#   🔵 0112 가 손대는 `attachments` 는 **PO 도 같은 DB 에서 보는 표**다.
#      🔴 그래도 PO 를 멈추지 않아도 된다 — 더해지는 칸은 NULL 을 받고, CHECK 는
#      그 칸이 NULL 이 아닐 때만 조건을 건다. PO(0.3)는 그 칸을 모르므로 늘
#      NULL 로 넣는다. 되돌아간 2.1 도 마찬가지다.
#
#   🔴 A/S 의 drizzle/ 은 이미지 안이 아니라 **볼륨**이다
#      (compose 의 tools-as: /volume1/dss/as-migrations:/app/drizzle:ro).
#      그러니 .sql 셋만 넣어서는 안 되고 **meta/_journal.json 과
#      meta/0112·0113·0114_snapshot.json 까지 함께** 가야 한다. _journal.json 이
#      옛것이면 drizzle 은 새 .sql 을 **아예 모른다** — 조용히 0건 적용으로 끝나고,
#      그 다음에 뜬 2.2 가 없는 표를 읽다 죽는다.
#      → 그래서 폴더를 통째로 갈아 끼운다(3-ㄹ · as-migrations.tar.gz).
#
#   🔵 적용 전후로 db:preflight 가 보는 값(17번과 같은 길):
#        갈기 전   .sql 112 · 대기 **0건**
#        갈고 나서 .sql 115 · 대기 **3건**
#        적용 뒤   .sql 115 · 대기 **0건**
#      ⚠️ preflight 의 「살펴봐야 할 것」 칸에 유니크 인덱스·제약이 뜰 수 있는데
#         그것은 **종료 코드를 건드리지 않는다**(migration-safety 의 risky 갈래).
#         이번 셋에는 risky 로 잡히는 문장(DROP INDEX · RENAME · SET NOT NULL ·
#         타입 바꾸기)이 **하나도 없다.**
#
# ══ 🔴 ② compose 에 **새 볼륨**이 하나 는다 — 🔴 **읽기 전용**이다 ══════
#
#   app-as 에 이것이 더해진다 — 🔴 **긴 문법**이다:
#
#       - type: bind
#         source: "/volume1/2_AS센터/1. 수리 관련"
#         target: /repair-docs-archive
#         read_only: true
#
#   🔴 짧은 문법(`원본:대상`)으로 적으면 깨진다 — 경로에 **공백**이 있다.
#      한 줄을 콜론으로 가르는데, 따옴표를 씌우면 이번엔 전체가 원본 하나로 읽힌다
#      (compose 의 견적서 볼륨 주석에 그 까닭이 적혀 있다).
#
#   🔴 **`2_AS센터` 의 AS 는 대문자다.** Windows 탐색기가 보여 주는 `2_as센터` 를
#      그대로 적으면 리눅스에서 **조용히 빈 폴더**가 된다. 그러면 고르는 창이
#      「서류가 하나도 없다」로 보이고, 사람은 앱이 고장 난 줄 안다.
#      🔵 compose 의 기존 줄 둘이 같은 공유폴더를 쓴다 — 거기 적힌 글자와
#         **똑같이** 적었다(현황표 · 연락서 볼륨).
#
#   🔴 **읽기 전용으로 붙인다**(read_only: true · 사용자 결정 2026-10-08).
#      18번의 연락서 볼륨과 **반대**다. 이 기능은 공유폴더를 **훑어 경로를 DB 에
#      적을 뿐** 쓰지 않는다 — 파일을 여는 일은 사람 PC 의 도우미가 한다.
#      🔴 그래서 검사의 뜻도 뒤집힌다. 18번의 probe_new_volume() 은 **쓰기까지**
#         시험했지만, 이번엔 **「읽히는가」와 「쓰기가 막혀 있는가」** 둘을 본다.
#         🔴 **쓰기가 되면 오히려 ✗ 다** — :ro 가 안 먹었다는 뜻이고, 그대로 두면
#         앱이 직원의 서류함을 고칠 수 있는 자리가 열린 채로 돈다.
#      🔵 그래서 18번에 있던 acl_inherit_check(새 파일이 ACL 을 물려받는가)는
#         **이번에 없다.** 우리가 파일을 만들지 않으니 물려받을 것도 없다.
#
#   🔴 **ACL 을 걷지 않는다.** compose 가 이 자리에서 세 번 경고한다 —
#      chmod · chown 으로 걷으면 **직원의 탐색기 접근이 끊긴다.** 컨테이너가
#      읽을 수 있는 근거는 app-as 의 `group_add: ["100"]` 하나이고, 그 줄은
#      **이미 있다**(더하지 않는다).
#
#   🔴 **이 볼륨은 연락서 볼륨의 윗 폴더다.** 같은 나무를 두 번 붙이는 셈인데
#      (`…/1. 수리 관련` 과 `…/1. 수리 관련/3. 연락서(활용)/2. 연락서`), 도커의
#      바인드는 서로 독립이라 **한쪽이 읽기 전용이어도 다른 쪽은 그대로 쓴다.**
#      연락서 쪽 쓰기가 죽지 않는다 — 5-ㄴ 이 교체 뒤에 실제로 확인한다.
#
#   🔴 **tools-as 에는 붙이지 않는다.** 그쪽은 교산 이식용이고 이 폴더를 쓰는
#      스크립트가 없다. 🔴 **app-po 에도 붙이지 않는다.** PO 에는 이 화면이 없다.
#
# ══ 🔴 ③ as.env 에 설정 **둘**을 덧붙인다 (18번의 그 코드를 본뜸) ═══════
#
#   | 이름                          | 무엇                                     |
#   | REPAIR_DOCS_ARCHIVE_DIR       | 컨테이너 안 경로 = /repair-docs-archive   |
#   | REPAIR_DOCS_ARCHIVE_UNC_ROOT  | 🔴 **도우미 설치본에만** 들어간다          |
#
#   🔵 18번과 다른 것 하나 — **_UNC_PATH 가 없다.** 연락서에는 [위치 복사]로
#      화면에 나가는 값이 따로 있었지만, 이쪽은 그 단추가 없다. 그래서 둘뿐이다.
#      (RF_Service_System/.env.example 에 그 둘만 들어왔다 — 실측.)
#
#   🔴 18번의 규율을 한 글자도 바꾸지 않고 그대로 가져왔다:
#     · **이 PC(dss-deploy)의 nas/env/as.env 를 NAS 로 올리지 않는다. 절대로.**
#       그 사본은 낡아서 NAS 에만 있는 줄들(견적서 셋 · 현황표 다섯 · 연락서 셋)이
#       없다 — 올리면 그 기능들이 운영에서 통째로 사라진다.
#       **NAS 의 파일에 덧붙인다.**
#     · 덧붙이기 전에 **사본**을 남긴다(backups/as.env.<도장>, root 600).
#     · **이미 그 줄이 있으면 건드리지 않는다**(두 번 돌려도 안전하다).
#     · 적기 **전에** 견적서 셋 · 현황표 다섯 · **연락서 셋**이 살아 있는지 본다.
#       하나라도 없으면 덧붙이지 않고 멈춘다 — 배포보다 먼저 알아야 할 일이다.
#
#   🔴 **UNC 의 호스트 부분은 NAS 의 as.env 에서 뽑는다. 코드에 박지 않는다.**
#      견적서 쪽(QUOTE_ARCHIVE_UNC_ROOT · _ALT)이 이미 이름(\\DSS-NAS)과
#      IP(\\192.168.0.222)를 나눠 쓰고 있다. 거기서 **호스트 토막만** 읽는다.
#      🔴 **IP 쪽을 고른다** — 까닭은 18번과 같다(사내 DNS 가 없어 이름 풀이가
#      안 되는 PC 가 있고, 이 루트에도 비켜 갈 _ALT 가 없다). 뽑지 못하면
#      기본값 \\192.168.0.222 를 쓰고 **그렇게 말한다.**
#
#   🔴 **이 루트 아래 전부가 도우미에게 열린다.** 그래서 공유 뿌리가 아니라
#      「1. 수리 관련」 까지만 적는다(소스 머리말의 그 당부).
#
#   ⚠️ **값에 따옴표를 두르지 않는다.** env_file 의 큰따옴표 안에서는 역슬래시가
#      이스케이프로 읽혀 `\2` 가 조용히 사라진다. 따옴표 없이 적으면 줄 끝까지가
#      그대로 값이다(빈칸이 들어 있어도 된다).
#   🔴 **역슬래시가 먹혔는지 교체 뒤에 센다** — 컨테이너 안에서 printenv 로 읽어
#      역슬래시가 **넷 이상**인지 본다(7-ㄷ). 16 · 18번이 그 검사로 잡았다.
#
# ══ 🔴 ④ 배포 뒤 **사람이 할 일**이 있다 — 도우미 다시 설치 ════════════
#
#   🔴 **쓰는 분들이 PC 에서 도우미를 다시 설치해야 한다.** 이번 판은 도우미에
#      **루트를 하나 더했다** — 「1. 수리 관련」 아래를 열 수 있게(커밋 7463752).
#      옛 도우미는 새 루트의 주소를 받으면 **조용히 아무 일도 하지 않는다.**
#      (도우미는 PC 당 **한 벌**이다 — 레지스트리 `dss-folder`.)
#
#   🔵 이번 판이 **재설치 안내를 세대로 관리**하기 시작했다(`dss.helper.gen1.openfile`).
#      그래서 다음 판부터는 「이미 새 도우미가 있는 PC」에 안내가 안 뜬다.
#      🔴 하지만 **이번 한 번은 모두가 다시 설치해야 한다** — 루트가 늘었기 때문이다.
#
#   🔴 **설치 명령은 반드시 A/S 화면에서 받는다.**
#      PO 화면에서 받으면 그 PC 의 **고객사 현황표 [폴더 열기]가 먹통이 된다** —
#      도우미가 한 벌뿐이라 PO 가 내준 설치본이 A/S 것을 덮어쓴다(README 의 함정).
#      받는 길: A/S → 수리 건 상세 → [폴더 열기] → [설치 명령 복사] →
#               PowerShell 창에 붙여넣기 (관리자 권한 필요 없음).
#   8단계가 이 안내를 **마지막에 한 번 더** 찍는다.
#
# ══ 🔴 ⑤ 야간 백업 시각을 지킨다 — **02:30** ═══════════════════════════
#
#   🔴 **자정을 넘겨 돌리면 백업 검사에 걸린다.** 야간 백업은 02:30 이다.
#      17번이 01:00 에 돌렸다가 실제로 배포가 막혔다 — 그것이 사고를 막았다.
#      🔴 --go 는 **오늘 뜬 dss_as 백업이 없으면 시작조차 않는다**(3-ㄱ).
#      이번 판은 **DB 를 바꾼다**(마이그레이션 3건). 더 단단히 지킨다.
#
#      늦은 시각에 돌려야 한다면 **먼저 손으로 한 번 뜬다**(종료 코드 0):
#
#        bash /volume1/dss/jobs/backup-nightly.sh
#
#      ✓ dss_as 줄이 찍혀야 한다. 다섯 개가 다 떠야 1-ㅅ 이 통과한다.
#
# ══ 🔴 돌리기 전에 — **값 셋을 채워야 한다** ═══════════════════════════
#
#   🔴 이 스크립트가 쓰일 때 dss-as:2.2 는 **아직 구워지지 않았다.**
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
#     docker build -t dss-as:2.2 .
#     cd ..
#     docker save dss-as:2.2 -o dss-as-2.2.tar
#     (Get-Item dss-as-2.2.tar).Length        ← SZ_AS
#     Get-FileHash -Algorithm MD5 dss-as-2.2.tar   ← MD5_AS (소문자로 적는다)
#     tar -xOf dss-as-2.2.tar manifest.json        ← "Config" 의 sha256 → WANT_CFG_AS
#
#   🔴 **`git archive` 로 뽑지 마라** — 서브모듈 vendor/dss-ui · vendor/dss-core 가
#      **빈 폴더**로 나와 빌드가 깨진다(README 「다음 배포 때」 1번 · runbook/02 10절).
#      작업 폴더에서 굽되 `git status --short` 가 비어 있어야 한다.
#   🔴 **tar 가 이미지의 1/4 쯤인 것은 정상이다.** 2.1 은 584MB 이미지에 tar 가
#      130,042,880 바이트(약 124MB)였다. 크기 차이로 「빌드가 잘못됐나」를
#      의심할 일이 아니다 — 2.0 도 582MB 이미지에 tar 129,669,120 이었다.
#   🔴 **tar 안 Config 지문이 개발 PC 의 `{{.Id}}` 와 다르다.** 17번이 두 번 겪었다.
#      NAS 는 tar 안의 config 지문을 image ID 로 낸다 — **맞춰 볼 값은 tar 쪽**이다.
#
#   🔵 마이그레이션 묶음의 바이트·md5(SZ_MIG · MD5_MIG)도 비워 두었다.
#      🔴 그 둘은 **--go 를 막지 않는다** — 다시 묶으면 gzip 도장 때문에 값이
#      달라질 수 있어서다(17번의 그 판단). 🔴 진짜 판정은 **푼 뒤의 개수**다
#      (.sql 115 · _journal tag 115 · 0112·0113·0114 의 .sql 과 snapshot).
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/19-deploy.sh            ← 읽기만 한다
#
#   🔴 NAS 의 docker 는 **sudo(root)** 가 필요하다. 이 스크립트는 root 가
#      아니면 첫 줄에서 멈춘다.
#
# ══ 🔴 개발 PC → NAS 로 올릴 것 **셋** ═════════════════════════════════
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#      아래는 **개발 PC 의 PowerShell** 에서 친다(NAS 가 아니다).
#
#     scp -O dss-as-2.2.tar dss-nas:/volume1/dss/images/
#     scp -O as-migrations-2.2.tar.gz dss-nas:/volume1/dss/setup/incoming/as-migrations.tar.gz
#     scp -O docker-compose.nas.yml dss-nas:/volume1/dss/setup/incoming/
#
#   🔵 18번은 둘이었다 — **마이그레이션 묶음이 돌아왔다.** 17번처럼 셋이다.
#   🔴 **두 번째 줄에서 이름이 바뀐다** — as-migrations-2.2.tar.gz 를
#      **as-migrations.tar.gz** 로 올린다. 이 스크립트가 그 이름으로 찾는다.
#   🔴 세 번째 줄의 compose 는 **dss-deploy 저장소의 nas/docker-compose.nas.yml**
#      이다(A/S 태그를 2.2 로 올리고 **「수리 관련」 볼륨을 더한** 그 파일).
#   🔵 scp 가 바로 안 되면 사용자 계정(swhur)의 홈으로 올린 뒤 NAS 에서
#      `sudo mv` 로 옮긴다. /volume1/dss 아래는 root 만 쓸 수 있다.
#
# ══ 🔴 DSM 터미널은 긴 명령을 잘라 먹는다 ══════════════════════════════
#
#   하루에 네 번 깨진 적이 있다. **NAS 에서 돌릴 것은 스크립트 파일로 올리고
#   md5 를 맞춘 뒤** 실행한다. 이 파일 자체가 그렇다:
#
#     (PowerShell)  scp -O nas\setup\19-deploy.sh dss-nas:/volume1/dss/setup/
#     (PowerShell)  Get-FileHash -Algorithm MD5 nas\setup\19-deploy.sh
#     (NAS)         md5sum /volume1/dss/setup/19-deploy.sh
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
#      **새 볼륨을 읽어 보려고** 임시 컨테이너를 하나 더 띄웠다 지우며,
#      `db:preflight` 를 한 번 돌린다(tools-as 로 떴다 사라진다. DB 에는 select
#      만 간다). 디스크에도 DB 에도 아무것도 남기지 않고 도는 사이트를 건드리지도
#      않지만, 「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가
#      정확한 말이다. 13·15·16·17·18번 머리말의 그 문장을 그대로 잇는다.
#   🔵 새 볼륨은 **:ro 로** 붙여 본다 — 쓰기 시도는 파일을 만들 수 없다.
#      (만들어지면 그 자체가 ✗ 이고, 그때는 그 자리에서 곧바로 지운다.)
#
# ── 모드 다섯 ───────────────────────────────────────────────────────────
#   (없음) · --check     읽기만 한다. 아무것도 안 바꾸고 안 멈춘다      ← 기본값
#   --preload            새 이미지 하나를 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --go                 🔴 마이그레이션 셋 + 볼륨 + as.env 두 줄 + A/S 교체
#   --rollback           되돌리기 안내
#
#   `--force-load` 는 `--go` 와 같이 써도 된다:  bash 19-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 19-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 19-deploy.sh --preload       (새 이미지를 미리 실어 둔다)
#   3) bash 19-deploy.sh                 (다시 읽기만 — 이번엔 지문까지 다 본다)
#   4) bash 19-deploy.sh --go            (마이그레이션 + 볼륨 + as.env + 교체)
#
# ══ 🔴 ⑥ 「아직 안 온 것」을 ✗ 로 세지 않는다 (17 · 18번의 규칙 그대로) ═
#
#       **--check 가 ✗ 로 세는 것은 「있는데 어긋난 것」뿐이다.**
#       「아직 안 온 것 · 아직 안 실린 것」은 ⚠️ 로 안내만 한다.
#
#   --check 에서 ⚠️(안내)로 끝나는 자리 넷:
#     · $TAR_AS 가 아직 NAS 에 없다            → ⚠️ 「먼저 scp -O 로 올리세요」
#     · 마이그레이션 묶음이 아직 없다          → ⚠️ 「폴더가 이미 115 면 필요 없다」
#     · $TAG_AS 가 아직 docker load 안 됐다    → ⚠️ 「--preload 가 싣는다」
#     · 그래서 이미지 **안**을 못 봤다(1-ㅋ)   → ⚠️ 「--preload 뒤에 다시」
#   그리고 ✗ 로 세는 자리:
#     · tar 는 있는데 **바이트·md5·지문이 어긋난다**  → ✗ (옮기다 깨졌다)
#     · 이미지가 **실려 있는데 지문이 tar 와 다르다** → ✗ (--force-load 가 필요)
#     · 이미지 **안에 이번 판의 표시가 없다**         → ✗ (옛 판을 올린 것)
#     · 마이그레이션 폴더가 112 도 115 도 아니다      → ✗ (남의 손이 닿았다)
#
#   🔴 **「아직 안 실린 이미지」는 어느 모드에서도 ✗ 가 아니다**(notloaded).
#      --preload 와 --go 는 2단계에서 **스스로 싣기** 때문이다. 여기서 ✗ 를
#      세면 --go 가 싣기도 전에 자기 검사에 막혀 배포가 아예 불가능해진다.
#   🔴 같은 까닭으로 **새 볼륨을 「도는 컨테이너」에서 찾지 않는다**(16번 ⑩ ·
#      README 「ㄴ」). 지금 도는 2.1 에는 /repair-docs-archive 가 **없는 것이
#      맞다** — 그 자리는 새 compose 를 적용해야 생긴다. 그래서 **임시 컨테이너를
#      띄워** 호스트 경로를 붙여 보는 probe_new_volume() 을 18번에서 가져왔다.
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
#   시작 시각(.State.StartedAt)을 적어 두고 **그대로인지** 본다(7-ㅂ).
#
# ══ 15 · 16 · 17 · 18번에서 그대로 이어받는 것 ═════════════════════════
#
#   ① 같은 태그로 다시 구운 이미지는 조용히 안 실린다 → --force-load
#   ② 폴더 권한은 **컨테이너 안에서 실제로 열어 본다**(ls -ld 로는 모른다)
#   ③ 이미지는 태그가 아니라 **안을 본다**(1-ㅋ)
#   ④ 사람이 칠 명령은 **한 줄 76자 안쪽**(DSM 의 ash 가 긴 줄을 자른다)
#   ⑤ 공유폴더는 **chmod 로 ACL 을 걷으면 안 된다** — 직원의 탐색기가 끊긴다
#   ⑥ `docker ps` 에 보이는 것과 앱이 **대답하는** 것은 다르다 → wait_http
#   ⑦ compose 는 바꾸기 **전에** 시험하고, 바꾼 것은 backups/ 에 남긴다
#   ⑧ 알림 링크가 **밖에서 닿는 주소**로 나오는가(1-ㅈ · 7-ㄹ)
#   ⑨ 🔴 **권한은 코드가 아니라 운영 DB 가 정한다** — role_permissions 를
#      읽어 보고 말한다(1-ㄷ). 🔴 **select 만 쓴다.**
#      🔵 이번 판이 묻는 칸은 **셋**이다 — productModels.view(보기) ·
#         productModels.files(가리킨 자리를 더하고 지우기) · repairCases.files
#         (수리 건 파일 관리 화면 자체). 저장된 값이 기본 정책을 이긴다.
#   ⑩ 🔴 **새로 붙는 볼륨은 임시 컨테이너로 본다**(위 ⑥절의 그 까닭)
#   ⑪ 🔴 마이그레이션은 **앱을 멈추기 전에** 적용한다(16번이 배운 것) —
#      정지 창은 **이미지 교체 하나**다. 🔴 **차례를 뒤집지 마라**: 먼저 띄우면
#      2.2 가 아직 없는 표(product_model_share_docs …)를 읽다 그 자리에서 죽는다.
#      🔵 이번 판은 그 근거가 더 세다 — 더하기만 하는 셋이라 2.1 은 새 칸도 새 표도
#         **읽지도 쓰지도 않는다.** 적용해 두고 교체해도 2.1 이 그대로 돈다.
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
TAG_AS=dss-as:2.2
OLD_AS=dss-as:2.1

# ── 🔴 **건드리지 않는 아홉.** 16 · 17 · 18번과 같은 아홉이다 ──────────
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
TAR_AS=$IMAGES/dss-as-2.2.tar
# 🔴 **아직 비어 있다.** 개발 PC 에서 2.2 를 굽고 재어 채운다(머리말의 그 차례).
#    비어 있는 동안 --check 는 ⚠️ 로만 말하고 --go 는 시작조차 하지 않는다.
#    🔵 참고 — 2.1 은 이미지 584MB 에 tar 130,042,880 바이트였다.
#       tar 가 이미지의 1/4 쯤인 것은 **정상**이다.
SZ_AS="130827264"                                                                   # 2026-10-08 02:0x 잼
MD5_AS="2a89d5ba1ac27ac0a46761abfff20a91"                                           # 소문자
WANT_CFG_AS="sha256:8ed1626f8b663c3debfd1866de6651d06d510627d257547ba0e74eaf42950894"
# 🔵 잰 값 — 이미지 590MB · tar 130,827,264 바이트(2.1 보다 784,384 늘었다).
#    docker build 가 찍은 "exporting config sha256:8ed1626f…" 와 tar 쪽 Config 가 같았다.
# ⚠️ manifest.json 은 그 값을 `blobs/sha256/ba9fc008…` 로 적는다 — 앞의 `blobs/` 를
#    떼고 `sha256:` 를 붙인 모양으로 적는다(17 · 18번도 같은 모양이었다).
# ⚠️ tar 안의 이 지문은 개발 PC 의 `docker images --format {{.Id}}` 와 **다르다.**
#    17번이 두 번 겪고 적어 둔 그대로다 — 다르다고 놀라지 말 것.

# ── 포트 (compose 의 ports: 에서 읽어 확인했다 — 짐작이 아니다) ────────
#   포털 13100 · A/S 13000 · 계측기 13300 · 개선요청 13500 ·
#   PO 13600 · 휴가 13700
AS_PORT=13000

# ══ 마이그레이션 — 🔴 **셋이다**(0112 · 0113 · 0114) ═══════════════════
AS_DB=dss_as
N_MIG_HAVE=112                 # 지금 운영에 적용돼 있는 수
N_MIG_WANT=115                 # 적용 뒤 수
MIGDIR=$D/as-migrations        # compose 가 tools-as 의 /app/drizzle 로 붙인다
MIGTAR=$D/setup/incoming/as-migrations.tar.gz
# 🔵 아래 둘은 **비워 두어도 된다.** 다시 묶으면 gzip 도장 때문에 값이 달라질 수
#    있어 ⚠️ 로만 말하고 ✗ 로 세지 않는다 — 진짜 판정은 **푼 뒤의 개수**다.
SZ_MIG=""
MD5_MIG=""
NEW_MIGS="0112 0113 0114"
AS_TOOLS_SVC=tools-as

# ── 셋이 **진짜 그 파일인지** 보는 글자 (3-ㄹ · 1-ㄹ) ──────────────────
MIG_0112_MARK='ADD COLUMN "product_model_kind"'
MIG_0113_MARK='CREATE TABLE "product_model_kind_share_docs"'
MIG_0113_TYPE='CREATE TYPE "public"."share_doc_entry_kind"'
MIG_0114_MARK='CREATE TABLE "product_model_share_docs"'
# 🔴 지우는 문장을 세는 잣대. **`DELETE` 만으로 세지 않는다** — 0113 · 0114 의
#    외래키에 `ON DELETE restrict` · `ON DELETE cascade` 가 세 번 나온다.
#    앱의 판정기(src/lib/db/migration-safety.ts)가 쓰는 것과 같은 잣대다.
# 🔵 `\b` 를 쓰지 않는다 — DSM 의 grep 이 GNU 가 아닐 수 있다. POSIX ERE 로만 적었다.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'

# ── 적용 뒤 DB 에서 **직접 세어** 볼 것 (5단계) ───────────────────────
NEW_TYPE=share_doc_entry_kind
NEW_TBL1=product_model_kind_share_docs
NEW_TBL2=product_model_share_docs
NEW_COL_TBL=attachments
NEW_COL=product_model_kind
NEW_CHECK=attachments_kind_owner_alone

# ── 권한 — 🔴 읽기만 한다. 출처는 전부 소스다 (1-ㄷ) ──────────────────
#   표·칸   vendor/dss-core/src/schema/role-permissions.ts
#           (표 role_permissions · 칸 role · area_key · level · updated_at.
#            🔴 칸 이름은 leaf_key 가 아니라 **area_key** 다 — 이름이 낡았다)
#   이번 판 src/app/api/product-models/[id]/share-folder/entries/route.ts:160
#           src/app/api/product-model-kinds/[kind]/share-folder/entries/route.ts:154
#             → hasPermission(actingUser, "productModels.view", "READ")
#           src/lib/server/actions/product-model-share-docs.ts:162
#           src/lib/server/actions/product-model-kind-share-docs.ts:140
#             → hasPermission(actingUser, "productModels.files", "WRITE")
#   기본값  src/lib/auth/permission-baseline.ts:477 · :482
#             productModels.view  → SUPER_ADMIN · ADMIN · AS_ENGINEER · SALES 만 READ
#             productModels.files → SUPER_ADMIN · ADMIN · AS_ENGINEER 만 WRITE
#           :394 repairCases.files → 로그인한 사람이면 WRITE
#   🔴 그러므로 표에 줄이 **없으면 위 기본값대로**다. 줄이 있으면 그 값이 이긴다.
PERM_TABLE=role_permissions
PERM_AREA_VIEW=productModels.view
PERM_AREA_FILES=productModels.files
PERM_AREA_CASE=repairCases.files

# ── 컨테이너 안에서 실제로 열어 볼 폴더 ────────────────────────────────
ATT=$D/as-attachments
TEMPLATES=$D/as-templates
UP_IMP=$D/improvements-uploads
MF_METERS=$D/meters-files
# 🔵 이미 붙어 있는 공유폴더 둘. **이번에 새로 붙는 것이 아니다** — 도는 2.1 에
#    이미 있다. 여기서는 「사라지지 않았는가」만 본다.
PORTAL_MNT=/customer-portal-archive
CONTACT_MNT=/contact-folder-archive

# ── 🔴 이번에 **새로 붙는** 공유폴더 — 읽기 전용이다 ──────────────────
# 🔴 `2_AS센터` 의 AS 는 **대문자**다(머리말 ②).
REPAIR_SRC="/volume1/2_AS센터/1. 수리 관련"
REPAIR_MNT=/repair-docs-archive
# 🔵 이 폴더가 **맞는 자리인지** 가려 줄 하위 폴더. 연락서 볼륨이 그 아래에 있다.
REPAIR_SUB='3. 연락서(활용)'

# ── as.env 에 덧붙일 **두 줄**의 재료 ──────────────────────────────────
# 호스트 부분은 2-ㄱ(build_env_values)이 NAS 의 as.env 에서 뽑는다. 뽑지 못했을
# 때 쓸 기본값은 아래 하나다 — 🔴 **IP 다**(머리말 ③ 의 그 까닭).
DEF_HOST='\\192.168.0.222'
P_SHARE='2_AS센터'        # 공유 이름(/volume1 바로 아래)
P_TAIL='1. 수리 관련'     # 공유 아래 ~ 수리 관련 서류가 모인 곳
# 2-ㄱ 이 채운다.
V_DIR=$REPAIR_MNT
V_ROOT=""
ENV_KEYS="REPAIR_DOCS_ARCHIVE_DIR REPAIR_DOCS_ARCHIVE_UNC_ROOT"
# 🔴 NAS 에만 있고 이 PC 의 사본에는 없는 열한 줄. **사라지면 안 된다.**
QUOTE_KEYS="QUOTE_ARCHIVE_DIR QUOTE_ARCHIVE_UNC_ROOT QUOTE_ARCHIVE_UNC_ROOT_ALT"
PORTAL_KEYS="CUSTOMER_PORTAL_ARCHIVE_DIR CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT CUSTOMER_PORTAL_ARCHIVE_FOLDER_PATH CUSTOMER_PORTAL_ARCHIVE_UNC_PATH"
CONTACT_KEYS="CONTACT_FOLDER_ARCHIVE_DIR CONTACT_FOLDER_ARCHIVE_UNC_ROOT CONTACT_FOLDER_ARCHIVE_UNC_PATH"

# ── 이미지 **안에서** 찾을 글자 (1-ㅋ) ─────────────────────────────────
# 🔴 태그와 지문이 맞아도 「무엇이 든 판인지」는 안을 봐야 안다. 9/21~9/29 에
#    A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다.
#
# 🔵 17 · 18번처럼 **모듈 경로**로 본다. Next 의 번들은 webpack 모듈 이름으로
#    소스 경로를 그대로 품는다 — 한글 문구보다 또렷하다(한글은 유니코드
#    이스케이프로 바뀌어 있을 때가 있다. 16번이 그 함정을 적어 뒀다).
#
# 🔴 아래 값들은 개발 PC 의 git 에서 가린 것이고, 이미지 안에서는 아직 안 쟀다
#    (2.2 가 아직 안 구워졌다). git diff 9a6ba31..1f56947 로 확인한 것:
#      repair-docs-archive.ts · KindShareDocsSection.tsx ·
#      CaseModelShareDocsSection.tsx · attachment-purge.ts  → 전부 **A**(새로 생김)
#      FilesHeaderSummary.tsx                               → **D**(없어짐)
AS_MARK1="src/lib/storage/repair-docs-archive.ts"
AS_MARK2="src/components/product-models/KindShareDocsSection.tsx"
AS_MARK3="src/components/repair-cases/files/CaseModelShareDocsSection.tsx"
AS_MARK4="src/lib/db/mutations/attachment-purge.ts"
AS_MARK5="REPAIR_DOCS_ARCHIVE_DIR"
# 🔴 이번엔 **없어져야 할 파일이 있다**(18번은 그 자리가 비어 있었다).
#    머리 카드를 한 줄로 합치면서 걷어낸 파일이다.
AS_GONE="src/components/repair-cases/files/FilesHeaderSummary.tsx"
# 🔵 2.1 에서 들어온 것이 2.2 에도 그대로 있는가 — **회귀** 표시다.
AS_KEEP="src/lib/storage/contact-folder-archive.ts"
AS_CTRL="SSO_REDIRECT_URI"    # 두 판에 다 있는 대조 표시

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 셋. 인자가 없으면 이 셋 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
PROBE_WRITE=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 19-deploy.sh                  읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 19-deploy.sh --check          위와 같습니다
  bash 19-deploy.sh --preload        새 이미지를 싣고 지문만 맞춥니다
  bash 19-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 19-deploy.sh --go             🔴 마이그레이션 셋 + 볼륨 + as.env 두 줄 + 교체
  bash 19-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 19-deploy.sh --rollback       되돌리기 안내

  🔴 --go 가 멈추는 것은 **dss-as 하나**입니다.
     포털 · 계측기 · 개선요청 · PO · 휴가 · DB 는 그대로 돕니다.
  🔴 --go 는 **DB 를 바꿉니다** — 마이그레이션 0112 · 0113 · 0114.
     표도 칸도 자료도 지우지 않지만, 그날 백업이 없으면 거기서 멈춥니다.
     🔵 야간 백업은 **02:30** 입니다 — 자정 넘어 돌리면 여기 걸립니다.
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
#    🔵 새 볼륨은 예외다 — :ro 로 붙이므로 쓰기 시도가 **파일을 만들 수 없다.**
[ "$MODE" = go ] && PROBE_WRITE=1

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/19-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11 · 12 · 13 · 15 · 16 · 17 · 18-deploy.sh 의 것을 그대로 ──
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""; DOWN=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# 🔴 머리말 ⑥ — 「아직 안 온 것」은 --check 에서 ✗ 가 아니다.
#    --preload · --go 는 그것이 **있어야** 도는 모드라 ✗ 로 센다.
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
#  DB 도우미 — 🔴 **이 스크립트가 직접 적는 SQL 은 전부 select 다.**
#
#  DB 를 바꾸는 자리는 **5단계의 `npm run db:migrate` 한 줄**뿐이고, 거기서 도는
#  SQL 은 drizzle 이 0112 · 0113 · 0114 파일에서 읽는 그것이다.
#  role_permissions · pg_enum · information_schema 는 **읽기만** 한다.
# ══════════════════════════════════════════════════════════════════════
qas()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -Atc \"$1\"" 2>/dev/null; }
qqas() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -c   \"$1\"" 2>/dev/null; }

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 개발 PC 의 `docker image inspect --format {{.Id}}` 가 아니라 **이 값**이
#    NAS 에 실렸을 때의 image ID 가 된다. 16 · 17 · 18번의 함수를 그대로 가져왔다.
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
#  🔴 **새로 붙는 볼륨**은 도는 컨테이너에서 찾으면 안 된다 (18번에서 가져옴)
#
#  지금 도는 dss-as 는 **2.1** 이고 그 컨테이너에는 /repair-docs-archive 가
#  **없는 것이 맞다.** 그 자리는 새 compose 를 적용해야 생긴다. 16번의 첫 판이
#  바로 그 자리에서 EACCES 로 ✗ 를 내 **배포 자체를 불가능하게 만들었다** —
#  --go 도 검사를 다 돌리고 ✗ 가 있으면 멈추기 때문이다.
#  고친 방법이 이것이다: **임시 컨테이너를 띄워** 호스트 경로를 :ro 로 붙여 본다.
#
#  🔴 18번과 **뜻이 뒤집힌 자리**가 여기다. 18번(연락서)은 쓰기가 **되어야**
#     했지만, 이번(수리 관련)은 쓰기가 **막혀 있어야** 맞다. 그래서 세 가지를
#     본다: ㄱ) 읽히는가 ㄴ) 맨 위 칸이 비어 있지 않은가 ㄷ) 쓰기가 막혔는가.
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
probe_new_volume() { # 1 호스트경로 2 컨테이너안경로 3 사람이읽을이름 4 하위폴더이름
  local src="$1" mnt="$2" label="$3" sub="$4" img out r w s n rc=0
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
  say "    (도는 2.1 에는 아직 이 자리가 없다 — 함수 머리말 참조)"
  say "    🔵 :ro 로 붙인다 — compose 의 read_only: true 와 **같은 조건**이다."
  # 🔴 경로는 -e 로 넘겨 **컨테이너 안에서** 푼다. sh -c 본문에 끼워 넣으면
  #    빈칸 · 괄호 · 한글이 든 경로에서 조용히 깨진다.
  out=$("$DOCKER" run --rm -u 1000:1000 --group-add 100 \
        -e M="$mnt" -e SUB="$sub" \
        -v "$src:$mnt:ro" --entrypoint sh "$img" -c '
          id
          if ls -1 "$M" >/dev/null 2>&1; then
            echo "PROBE_NEW READ_OK"
            echo "TOPN $(ls -1 "$M" 2>/dev/null | wc -l)"
            ls -1 "$M" 2>/dev/null | head -8 | sed "s/^/TOP /"
          else
            echo "PROBE_NEW READ_FAIL"
          fi
          if [ -d "$M/$SUB" ]; then echo "PROBE_SUB FOUND"; else echo "PROBE_SUB MISSING"; fi
          t="$M/.dss-ro-test"
          if : > "$t" 2>/dev/null; then
            echo "PROBE_RO WRITE_OK"
            rm -f "$t" 2>/dev/null
          else
            echo "PROBE_RO WRITE_BLOCKED"
          fi' 2>&1)
  printf '%s\n' "$out" | grep -E '^(uid=|PROBE_NEW |PROBE_SUB |PROBE_RO |TOPN |TOP )' \
    | sed 's/^/      /'
  r=$(printf '%s\n' "$out" | sed -n 's/^PROBE_NEW //p' | head -1)
  s=$(printf '%s\n' "$out" | sed -n 's/^PROBE_SUB //p' | head -1)
  w=$(printf '%s\n' "$out" | sed -n 's/^PROBE_RO //p'  | head -1)
  n=$(printf '%s\n' "$out" | sed -n 's/^TOPN //p' | head -1 | tr -d ' ')
  case "$r" in
    READ_OK)
      ok "$label · $mnt 를 읽는다 (uid 1000 + gid 100)" ;;
    READ_FAIL)
      bad "$label · $mnt 를 **못 읽는다**(EACCES) — 🔴 이번엔 진짜 권한 문제다"
      say "    (자리가 없어서 나는 ✗ 가 아니다. 여기서는 자리를 **우리가 붙여** 봤다.)"
      # 🔴 여기서는 perm_fix_hint 를 부르지 않는다 — 그 안내는 ACL 을 걷는 길이고,
      #    직원이 쓰는 공유폴더에 그러면 탐색기 접근이 끊긴다.
      say "    🔴 **chmod · chown 을 하지 마라** — 직원의 탐색기 접근이 끊긴다."
      say "    되는 폴더(견적서 · 현황표 · 연락서)와 ACL 을 끝까지 견주세요:"
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
      say "    → 🔴 「2_AS센터」 의 AS 가 **대문자**인지 보세요(머리말 ②)."
      cmd "ls -d /volume1/2_AS*"
      rc=1
    fi
    case "$s" in
      FOUND) ok "$label · 그 안에 「$sub」 가 있다 — **자리가 맞다**" ;;
      *)     bad "🔴 $label · 「$sub」 가 안 보인다 — 한 칸 위나 아래를 붙인 것이다"
             say "    (연락서 볼륨이 바로 그 아래에 있다. 그것이 안 보이면 자리가 틀렸다.)"
             rc=1 ;;
    esac
  fi
  case "$w" in
    WRITE_BLOCKED)
      ok "$label · **쓰기가 막혀 있다** — 읽기 전용으로 붙었다는 뜻이다" ;;
    WRITE_OK)
      bad "🔴 $label · **쓰기가 됐다** — :ro 가 안 먹었다"
      say "    🔴 이 기능은 이 폴더를 **읽기만** 한다(사용자 결정 2026-10-08)."
      say "       쓸 수 있는 자리가 열린 채로 돌면 앱이 직원의 서류함을 고칠 수 있다."
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
#  이미지 **안에** 이번 판이 들어 있는가 — 여덟 자리를 한 번에 본다
#
#  🔴 「아직 안 실린 것」은 ✗ 가 아니다(머리말 ⑥). 못 봤다고 말하고 넘어간다.
#  🔴 대조 표시(AS_CTRL)가 안 나오면 **판정하지 않는다** — 글자를 못 읽은 것과
#     옛 판인 것을 가를 수 없기 때문이다.
# ══════════════════════════════════════════════════════════════════════
inside_check() { # 1 이미지태그
  local tag="$1" out m1 m2 m3 m4 m5 gn kp c n
  if ! have_img "$tag"; then
    notloaded "$tag 가 아직 NAS 에 없어 **안을 못 봤다** — 먼저 실으세요"
    cmd "bash $0 --preload"
    return 0
  fi
  out=$("$DOCKER" run --rm -e M1="$AS_MARK1" -e M2="$AS_MARK2" -e M3="$AS_MARK3" \
        -e M4="$AS_MARK4" -e M5="$AS_MARK5" -e GN="$AS_GONE" \
        -e KP="$AS_KEEP" -e C="$AS_CTRL" \
        --entrypoint sh "$tag" -c '
    m1=0; m2=0; m3=0; m4=0; m5=0; gn=0; kp=0; c=0
    grep -rlF -- "$M1" /app/.next >/dev/null 2>&1 && m1=1
    grep -rlF -- "$M2" /app/.next >/dev/null 2>&1 && m2=1
    grep -rlF -- "$M3" /app/.next >/dev/null 2>&1 && m3=1
    grep -rlF -- "$M4" /app/.next >/dev/null 2>&1 && m4=1
    grep -rlF -- "$M5" /app/.next >/dev/null 2>&1 && m5=1
    grep -rlF -- "$GN" /app/.next >/dev/null 2>&1 && gn=1
    grep -rlF -- "$KP" /app/.next >/dev/null 2>&1 && kp=1
    grep -rlF -- "$C"  /app/.next >/dev/null 2>&1 && c=1
    n=$(grep -rlF -- repair-docs /app/.next/server 2>/dev/null | wc -l)
    echo "INSIDE $m1 $m2 $m3 $m4 $m5 $gn $kp $c $n"' 2>/dev/null \
    | grep '^INSIDE ' | head -1)
  m1=$(printf '%s' "$out" | awk '{print $2}')
  m2=$(printf '%s' "$out" | awk '{print $3}')
  m3=$(printf '%s' "$out" | awk '{print $4}')
  m4=$(printf '%s' "$out" | awk '{print $5}')
  m5=$(printf '%s' "$out" | awk '{print $6}')
  gn=$(printf '%s' "$out" | awk '{print $7}')
  kp=$(printf '%s' "$out" | awk '{print $8}')
  c=$(printf  '%s' "$out" | awk '{print $9}')
  n=$(printf  '%s' "$out" | awk '{print $10}')
  if [ "${c:-0}" != 1 ]; then
    say "    ⚠️ $tag 안을 글자로 뒤지지 못했다 — 대조 표시($AS_CTRL)도 안 나왔다."
    say "       **판정하지 않는다.** 🔴 이때는 사람이 직접 화면에서 봐야 한다."
    return 0
  fi
  ok "대조 표시($AS_CTRL)를 찾았다 — 안을 실제로 읽었다는 뜻이다"
  [ "${m1:-0}" = 1 ] && ok "「수리 관련」 서류 저장 모듈이 들어 있다 ($AS_MARK1)" \
    || bad "🔴 $AS_MARK1 가 **없다** — 이것은 $OLD_AS 다. 다시 구워 올리세요"
  [ "${m2:-0}" = 1 ] && ok "제품 종류의 「가리킨 서류」 구역이 들어 있다 ($AS_MARK2)" \
    || bad "🔴 $AS_MARK2 가 **없다** — 이것은 $OLD_AS 다. 다시 구워 올리세요"
  [ "${m3:-0}" = 1 ] && ok "수리 건 파일 관리의 모델 서류 구역이 들어 있다 ($AS_MARK3)" \
    || bad "🔴 $AS_MARK3 가 **없다** — 이것은 $OLD_AS 다"
  [ "${m4:-0}" = 1 ] && ok "첨부 **영구 삭제** 모듈이 들어 있다 ($AS_MARK4)" \
    || bad "🔴 $AS_MARK4 가 **없다** — 이것은 $OLD_AS 다"
  [ "${m5:-0}" = 1 ] && ok "설정 이름 $AS_MARK5 가 들어 있다" \
    || bad "🔴 $AS_MARK5 가 **없다** — 이것은 $OLD_AS 다"
  [ "${gn:-0}" = 0 ] && ok "걷어낸 파일이 정말 없다 ($AS_GONE)" \
    || bad "🔴 $AS_GONE 가 **아직 있다** — 이것은 $OLD_AS 다"
  [ "${kp:-0}" = 1 ] && ok "회귀 — $AS_KEEP 가 그대로 있다 (2.1 에서 들어온 것)" \
    || bad "🔴 $AS_KEEP 가 **사라졌다** — 2.1 보다 **옛 판**을 올린 것이다"
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then
    ok ".next/server 안에 repair-docs 가 든 파일 ${n}개"
  else
    bad "🔴 .next/server 안에 repair-docs 가 **한 파일도 없다** — 옛 판이다"
  fi
}

# ── 🔴 이미지 안에 글자 인식기(public/ocr)가 들어 있는가 ───────────────
# 🔴 Next 의 standalone 은 public 을 **자동으로 담지 않는다.** Dockerfile 이
#    따로 COPY 하는데, 그 줄이 어긋나면 화면은 뜨고 명판 읽기만 죽는다 —
#    그것도 오류 없이 「인식기를 불러오지 못했습니다」 하나로.
# 🔵 이번 판이 더한 기능은 아니다. **2.1 에 있던 것이 2.2 에도 그대로 있는지**
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
#  이번 판이 묻는 칸은 **셋**이다:
#    · 가리킨 서류를 **보기**        → productModels.view  **READ**
#    · 자리를 **더하고 지우기**      → productModels.files **WRITE**
#    · 수리 건 **파일 관리 화면**    → repairCases.files
#  기본값(permission-baseline.ts)은
#    productModels.view  : SUPER_ADMIN · ADMIN · AS_ENGINEER · SALES 만 READ
#    productModels.files : SUPER_ADMIN · ADMIN · AS_ENGINEER 만 WRITE
#    repairCases.files   : 로그인한 사람이면 WRITE
#  🔴 표에 줄이 없으면 위 기본값대로이고, 줄이 있으면 **저장된 값이 이긴다.**
#  🔴 그래서 여기서 읽어 보고 「실제로 달라지는 칸」을 말한다. ✗ 는 세지 않는다 —
#     배포의 흠이 아니라 설정이다.
# ══════════════════════════════════════════════════════════════════════
PERM_SQL_COUNT="select count(*) from $PERM_TABLE"
PERM_SQL_AREA="select role, area_key, level, updated_at::date from $PERM_TABLE where area_key in ('$PERM_AREA_VIEW', '$PERM_AREA_FILES', '$PERM_AREA_CASE') order by area_key, role"

perm_check() {
  local reg n_all n_view n_files n_case
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
  n_view=$(qas "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_VIEW'")
  n_files=$(qas "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_FILES'")
  n_case=$(qas "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_CASE'")
  say "  · $PERM_AREA_VIEW 에 저장된 줄: ${n_view:-?}"
  say "  · $PERM_AREA_FILES 에 저장된 줄: ${n_files:-?}"
  say "  · $PERM_AREA_CASE 에 저장된 줄: ${n_case:-?}"
  say
  say "  저장된 값 — 역할 전부:"
  qqas "$PERM_SQL_AREA" | sed 's/^/      /'
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 「가리킨 서류」는 위 세 칸이 함께 정합니다.                  ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  if [ "${n_view:-0}" = 0 ] && [ "${n_files:-0}" = 0 ] && [ "${n_case:-0}" = 0 ]; then
    say "     🔵 세 칸에 **저장된 줄이 하나도 없습니다.** 그러면 코드의 기본값이"
    say "        그대로 삽니다:"
    say "        · 보기(productModels.view)  — 총괄·관리자·엔지니어·영업"
    say "        · 자리 더하기·지우기(files) — 총괄·관리자·엔지니어"
    say "        · 수리 건 파일 관리         — 로그인한 사람이면 누구나"
  else
    say "     🔴 저장된 줄이 있습니다. 위 표를 보세요 — **저장된 값이 코드의"
    say "        기본값을 이깁니다.**"
    say "        · productModels.view 가 NONE 인 역할은 가리킨 서류를 **보지도"
    say "          못합니다**(고르는 창도 안 열립니다)"
    say "        · productModels.files 가 WRITE 가 아닌 역할은 **자리를 더하거나"
    say "          지우지 못합니다**(보기는 됩니다)"
    say "        · repairCases.files 가 NONE 인 역할은 수리 건 **파일 관리 화면"
    say "          자체가 막힙니다** — 거기 붙은 서류 구역도 함께 사라집니다"
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  as.env — 🔴 **NAS 의 파일을 읽고 없는 줄만 덧붙인다** (18번에서 가져옴)
#
#  🔴 이 PC 의 nas/env/as.env 를 올리지 않는다(머리말 ③).
#  🔴 값은 로그에 찍지 않는다 — 다만 QUOTE_ARCHIVE_UNC_ROOT · _ALT 의
#     **호스트 부분**(\\이름 또는 \\IP)만 뽑아 보여 준다. 새 두 줄을 같은 꼴로
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
# 두 줄의 값을 짠다. 🔴 printf 로 짓는다 — 역슬래시가 한 겹 삼켜지지 않게.
build_env_values() {
  local qroot qalt hr ha
  qroot=$(env_val QUOTE_ARCHIVE_UNC_ROOT)
  qalt=$(env_val QUOTE_ARCHIVE_UNC_ROOT_ALT)
  hr=$(unc_host "$qroot")
  ha=$(unc_host "$qalt")
  ENV_SRC_NOTE="NAS 의 as.env"
  # 🔴 IP 쪽을 고른다 — 이 루트에도 비켜 갈 _ALT 가 없고, 사내 DNS 가 없어
  #    이름 풀이가 안 되는 PC 가 있다(머리말 ③ · 18번의 그 판단).
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
  V_DIR=$REPAIR_MNT
  V_ROOT=$(printf '%s\\%s\\%s' "$ENV_HOST" "$P_SHARE" "$P_TAIL")
}
env_line_for() { # 1 키  → "키=값" 한 줄
  case "$1" in
    REPAIR_DOCS_ARCHIVE_DIR)      printf '%s=%s' "$1" "$V_DIR" ;;
    REPAIR_DOCS_ARCHIVE_UNC_ROOT) printf '%s=%s' "$1" "$V_ROOT" ;;
  esac
}
# 🔴 역슬래시가 삼켜졌는지 — UNC 값에 역슬래시가 넷 이상 있어야 맞다(16 · 18번의 검사).
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
MIG_PLACED=0   # as-migrations 폴더가 이미 115 이면 1
SVCS=""
AS_DBURL=""; PO_DBURL=""

see_tar() { # 1 태그 2 tar 3 tar에서읽은지문
  local n m
  if [ ! -s "$2" ]; then
    notyet "$1 의 tar 가 아직 NAS 에 없다: $2"
    say "    → 개발 PC(PowerShell)에서 올리세요. 🔴 scp 에 -O 를 붙입니다:"
    say "      (NAS 가 아니라 **개발 PC 의 PowerShell** 에서 칩니다)"
    say "      scp -O dss-as-2.2.tar dss-nas:/volume1/dss/images/"
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

# ── 마이그레이션 묶음 tar — 바이트·md5 를 대조한다 (17번에서 가져옴) ───
# 🔵 사람이 다시 묶으면 gzip 의 도장 때문에 md5 가 달라질 수 있다. 그래서
#    여기서 어긋나는 것은 ⚠️ 로만 말하고, **진짜 판정은 푼 뒤의 개수**로 한다
#    (3-ㄹ 가 .sql 115개 · _journal tag 115줄 · 0112·0113·0114 를 직접 센다).
# 🔵 기대값이 **비어 있어도 된다** — 비면 비교를 건너뛰고 지금 값만 적어 둔다.
see_migtar() {
  local n m
  [ -s "$MIGTAR" ] || return 0
  n=$(stat -c '%s' "$MIGTAR" 2>/dev/null)
  m=$(md5sum "$MIGTAR" 2>/dev/null | awk '{print $1}')
  if [ -z "$SZ_MIG" ] || [ -z "$MD5_MIG" ]; then
    say "    · 마이그레이션 묶음: 바이트 ${n:-?} · md5 ${m:-?}"
    say "      🔵 기대값(SZ_MIG · MD5_MIG)을 비워 두었다 — **판정은 푼 뒤의 개수**로 한다."
    return 0
  fi
  if [ "$n" = "$SZ_MIG" ] && [ "$m" = "$MD5_MIG" ]; then
    ok "마이그레이션 묶음 · 바이트 $n · md5 $m (개발 PC 와 같다)"
  else
    say "    ⚠️ 마이그레이션 묶음이 개발 PC 에서 잰 값과 다르다 (✗ 는 아니다)"
    say "       지금  바이트 ${n:-?} · md5 ${m:-?}"
    say "       기대  바이트 $SZ_MIG · md5 $MD5_MIG"
    say "       다시 묶으면 달라질 수 있다. 🔴 진짜 판정은 **푼 뒤의 개수**다."
  fi
}

# ── 마이그레이션 .sql 하나를 들여다본다 (1-ㄹ · 3-ㄹ 가 함께 쓴다) ─────
check_one_mig() { # 1 태그(0112…) 2 안에 있어야 할 글자
  local t="$1" want="$2" f
  f=$(ls -1 "$MIGDIR/${t}_"*.sql 2>/dev/null | head -1)
  if [ -z "$f" ]; then
    bad "$t 의 .sql 이 없다"
    return 1
  fi
  grep -qF "$want" "$f" \
    && ok "$t 안에 $want 가 있다 ($(basename "$f"))" \
    || bad "$t 안에 $want 가 **없다** — 🔴 다른 파일이다"
  # 🔴 「DELETE」 만으로 세지 않는다 — ON DELETE restrict/cascade 가 정상으로 나온다.
  if grep -qiE "$DESTRUCTIVE_RE" "$f"; then
    bad "🔴 $t 에 **지우는 문장**이 있다 — 이번 판에는 없어야 한다"
    grep -niE "$DESTRUCTIVE_RE" "$f" | sed 's/^/        /' | head -5
  else
    ok "$t 에 DROP · TRUNCATE · DELETE FROM 이 없다 (더하기만 한다)"
  fi
}

run_checks() {
  local tag s p rec t n_sql n_j n_db f db n_bk nlog k miss n_snap rc v nb
  local FREE_KB FREE_H code h

  # ── 1-ㄱ. 올릴 파일 둘 — 크기 · md5 · tar 안의 지문 ──────────────────
  step "1-ㄱ. 올린 파일 **둘** (이미지 tar · 🔴 마이그레이션 묶음)"
  say "  🔵 18번은 하나였다 — 이번 판은 마이그레이션이 **3건**이라 묶음이 돌아왔다."
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS"
  if [ -s "$MIGTAR" ]; then
    see_migtar
  else
    say "  · incoming 에 마이그레이션 묶음이 없다: $MIGTAR"
    say "    (폴더가 **이미 $N_MIG_WANT** 이면 올릴 필요가 없다 — 1-ㄹ 이 센다)"
  fi

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
  say "  ⚠️ $KEEP_ASTOOLS 는 **다시 굽지 않았다.** 마이그레이션을 돌리는 그 이미지인데,"
  say "     drizzle/ 은 이미지 안이 아니라 볼륨이라 새 .sql 은 폴더로 들어간다(1-ㄹ)."
  say "     🔴 되돌아간 $OLD_AS 도 그대로 둔다 — 되돌리기가 그것을 쓴다."
  have_img "$OLD_AS" && ok "$OLD_AS 도 아직 있다 (되돌릴 길이 열려 있다)" \
    || say "    ⚠️ $OLD_AS 가 NAS 에 없다 — 되돌리려면 tar 를 다시 올려야 한다"

  # ── 1-ㄷ. 권한 — 🔴 읽기만 한다 ──────────────────────────────────────
  step "1-ㄷ. 「가리킨 서류」가 **진짜로** 열리는가 (운영 DB 를 읽는다)"
  say "  🔴 「권한은 코드가 아니라 운영 DB 가 정한다」 — 그래서 읽어 보고 말한다."
  say "     🔴 이번 판이 묻는 칸은 **셋**이다(productModels.view · .files ·"
  say "        repairCases.files). 저장된 값이 코드의 기본값을 이긴다."
  perm_check

  # ── 1-ㄹ. 🔴 마이그레이션 셋 (112 → 115) ─────────────────────────────
  step "1-ㄹ. 마이그레이션 셋 $NEW_MIGS ($N_MIG_HAVE → $N_MIG_WANT)"
  say "  🔴 A/S 의 drizzle/ 은 이미지가 아니라 **볼륨**이다:"
  say "     $MIGDIR → tools-as 의 /app/drizzle (읽기 전용)"
  say "  그래서 .sql 셋만이 아니라 **meta/_journal.json 과 snapshot 셋까지**"
  say "  함께 가야 한다. _journal.json 이 옛것이면 새 .sql 을 아예 모른다."
  if [ -d "$MIGDIR" ]; then
    n_sql=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
    n_j=0
    [ -f "$MIGDIR/meta/_journal.json" ] \
      && n_j=$(grep -c '"tag"' "$MIGDIR/meta/_journal.json" 2>/dev/null | tr -d ' ')
    say "  · 지금 폴더: .sql ${n_sql}개 · _journal.json 의 tag ${n_j}줄"
    if [ "$n_sql" = "$N_MIG_WANT" ] && [ "$n_j" = "$N_MIG_WANT" ]; then
      MIG_PLACED=1
      ok "새 마이그레이션 파일이 **이미 놓여 있다** ($N_MIG_WANT)"
    elif [ "$n_sql" = "$N_MIG_HAVE" ] && [ "$n_j" = "$N_MIG_HAVE" ]; then
      if [ -s "$MIGTAR" ]; then
        ok "아직 $N_MIG_HAVE 이다 — **--go 가 incoming 의 묶음으로 갈아 끼운다**"
        say "    $MIGTAR ($(du -h "$MIGTAR" | cut -f1))"
      else
        notyet "아직 $N_MIG_HAVE 인데 **갈아 끼울 묶음이 없다**: $MIGTAR"
        say "    → 개발 PC(PowerShell)에서 올리세요 — 🔴 **이름이 바뀝니다**:"
        say "      (NAS 가 아니라 **개발 PC 의 PowerShell** 에서 칩니다 — 한 줄입니다)"
        say "      scp -O as-migrations-2.2.tar.gz \\"
        say "        dss-nas:/volume1/dss/setup/incoming/as-migrations.tar.gz"
        say "    🔴 .sql 셋만 넣지 마세요 — meta/_journal.json 이 빠지면"
        say "       적용이 **조용히 0건**으로 끝납니다."
      fi
    else
      bad "폴더가 $N_MIG_HAVE 도 $N_MIG_WANT 도 아니다 (.sql ${n_sql} · tag ${n_j})"
      say "    → 🔴 **남의 손이 닿았거나 반쯤 올라간 것**이다. 고치지 말고 알리세요."
    fi
    if [ "$MIG_PLACED" = 1 ]; then
      miss=""
      for t in $NEW_MIGS; do
        ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || miss="$miss $t(sql)"
        [ -f "$MIGDIR/meta/${t}_snapshot.json" ] || miss="$miss $t(snapshot)"
      done
      if [ -z "$miss" ]; then
        ok "$NEW_MIGS 의 .sql 과 meta/*_snapshot.json 이 다 있다"
      else
        bad "빠진 것이 있다:$miss"
      fi
      n_snap=$(ls -1 "$MIGDIR"/meta/*_snapshot.json 2>/dev/null | wc -l | tr -d ' ')
      say "  · meta/*_snapshot.json: ${n_snap}개"
      # 🔴 셋이 **진짜 그 파일인지** 본다 — 이름만 맞고 속이 다를 수 있다.
      check_one_mig 0112 "$MIG_0112_MARK"
      check_one_mig 0113 "$MIG_0113_MARK"
      check_one_mig 0114 "$MIG_0114_MARK"
      f=$(ls -1 "$MIGDIR/0113_"*.sql 2>/dev/null | head -1)
      if [ -n "$f" ]; then
        grep -qF "$MIG_0113_TYPE" "$f" \
          && ok "0113 이 새 타입 $NEW_TYPE 을 만든다" \
          || bad "0113 에 $MIG_0113_TYPE 이 **없다**"
      fi
    fi
  else
    bad "$MIGDIR 폴더가 없다 — compose 가 tools-as 에 붙이는 그 폴더다"
  fi
  if pg_up; then
    if [ -n "$(qas "select to_regclass('drizzle.__drizzle_migrations')")" ]; then
      n_db=$(qas "select count(*) from drizzle.__drizzle_migrations")
      say "  · 운영 DB($AS_DB)에 적용된 줄: ${n_db:-?}"
      case "${n_db:-x}" in
        "$N_MIG_HAVE") ok "적용 전 상태가 맞다 ($N_MIG_HAVE) — --go 가 셋을 적용한다" ;;
        "$N_MIG_WANT") ok "**이미 $N_MIG_WANT 다** — 적용이 끝난 DB 다(두 번 돌려도 안전하다)" ;;
        *) bad "적용된 줄이 $N_MIG_HAVE 도 $N_MIG_WANT 도 아니다 (${n_db:-?})"
           say "    → 🔴 **이것이 신호다.** 남의 변경이 섞였거나 누가 손으로 적용한 것이다."
           say "      고치지 말고 **먼저 알리세요.**" ;;
      esac
      # 🔴 「무엇이 생길 자리인가」를 적용 **전에** 적어 둔다 — 뒤에서 견준다.
      say "  · 지금 DB 에 있는가 (적용 전 · 전부 **없어야** 맞다):"
      for t in "$NEW_TBL1" "$NEW_TBL2"; do
        if [ -n "$(qas "select to_regclass('public.$t')")" ]; then
          say "      ⚠️ 표 $t 가 **이미 있다** — 적용이 끝난 DB 일 수 있다"
        else
          say "      · 표 $t 는 아직 없다 (맞는 상태다)"
        fi
      done
      v=$(qas "select count(*) from pg_type where typname = '$NEW_TYPE'")
      say "      · 타입 $NEW_TYPE: ${v:-?}개 (적용 전 0 · 적용 뒤 1)"
      v=$(qas "select count(*) from information_schema.columns where table_name = '$NEW_COL_TBL' and column_name = '$NEW_COL'")
      say "      · $NEW_COL_TBL.$NEW_COL 칸: ${v:-?}개 (적용 전 0 · 적용 뒤 1)"
    else
      bad "$AS_DB 에 drizzle.__drizzle_migrations 가 없다 — 첫 설치가 안 된 DB 다"
    fi
  else
    bad "dss-pg-app 이 떠 있지 않다 — 적용 수를 못 봤다"
  fi
  say
  say "  🔵 적용 대기 수를 봅니다 — db:preflight (DB 에는 select 만 갑니다):"
  if [ -n "$SVCS" ] || SVCS=$(compose_at "$CF_EFF" config --services 2>/dev/null); then :; fi
  if echo "$SVCS" | grep -qx "$AS_TOOLS_SVC"; then
    compose_at "$CF_EFF" run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | sed 's/^/      /'
    rc=${PIPESTATUS[0]}
    say "      (종료 코드 $rc — 🔴 셋 다 **지우는 문장이 없어** 0 이 맞다)"
    say "      🔵 기대: 폴더가 아직 $N_MIG_HAVE 이면 「대기 0건」, 갈아 끼운 뒤면 「대기 3건」."
    say "      🔵 「살펴봐야 할 것」 칸은 **종료 코드를 건드리지 않는다.** 이번 셋에는"
    say "         거기 잡히는 문장(DROP INDEX · RENAME · SET NOT NULL · 타입 바꾸기)이 없다."
  else
    bad "compose 에 $AS_TOOLS_SVC 가 없다 — 마이그레이션을 돌릴 수 없다"
  fi

  # ── 1-ㅁ. 🔴 as.env — 두 줄을 덧붙일 자리 ────────────────────────────
  step "1-ㅁ. as.env (이름만 본다. 값은 호스트 토막과 **새 두 줄**만 찍는다)"
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
    say "  🔴 현황표 다섯 줄 — 16번이 넣은 것이고 **2.2 도 그대로 쓴다**:"
    for k in $PORTAL_KEYS; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 [공유폴더에 저장]이 실패로 끝난다"
    done
    say "  🔴 연락서 세 줄 — 18번이 넣은 것이고 **2.2 도 그대로 쓴다**:"
    for k in $CONTACT_KEYS; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 연락서 [폴더 열기]가 죽는다"
    done
    if grep -q "^CUSTOMER_LINK_TOKEN_KEY=" "$AS_ENV"; then
      say "  ⚠️ CUSTOMER_LINK_TOKEN_KEY 가 아직 있다 — 2.0 부터 **안 읽는 줄**이다."
      say "     🔴 **지우지 마세요.** 그대로 둬도 아무 일도 일어나지 않습니다."
    fi
    # 새 두 줄
    build_env_values
    say
    say "  🔴 이번에 덧붙일 **두 줄**:"
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
    say "  🔴 _UNC_ROOT 는 **도우미 설치본에만** 들어간다(화면으로 안 나간다)."
    say "     🔵 18번과 달리 **_UNC_PATH 가 없다** — 이 화면에는 [위치 복사]가 없다."
    say "  🔴 이 루트 **아래 전부**가 도우미에게 열린다 — 그래서 공유 뿌리가 아니라"
    say "     「$P_TAIL」 까지만 적는다."
    say "  ⚠️ 값에 따옴표를 두르지 않는다 — 큰따옴표 안에서는 역슬래시가 먹힌다."
    if [ -n "$miss" ] && [ "$MODE" != go ]; then
      say "  🔵 지금은 **아무것도 안 적었다.** 적는 것은 --go 가 한다(3-ㅁ)."
    fi
  else
    bad "as.env 가 없다: $AS_ENV"
    say "    → 없는 env_file 하나면 docker compose 명령이 **통째로** 안 먹는다."
  fi
  for f in po.env auth.env meters.env improvements.env leave.env; do
    [ -f "$ENVD/$f" ] || bad "$f 가 없다: $ENVD/$f (compose 가 통째로 실패한다)"
  done

  # ── 1-ㅂ. compose — 태그 한 줄 + **새 볼륨 하나(읽기 전용)** ─────────
  step "1-ㅂ. compose ($CF_EFF)"
  say "  🔴 이번 판에서 compose 가 바뀌는 자리는 **둘**이다:"
  say "     ㄱ) app-as 의 image 한 줄 ($OLD_AS → $TAG_AS)"
  say "     ㄴ) app-as 에 **「수리 관련」 볼륨 하나**(긴 문법 · 네 줄 · 🔴 읽기 전용)"
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
    say "       🔴 **손으로 sed 로 고치지 마세요** — 태그만이 아니라 **볼륨 네 줄**도"
    say "          함께 들어가야 합니다. 개발 PC 에서 고친 파일을 아래에 올리면"
    say "          --go 가 시험하고 제자리로 옮깁니다:"
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
  svc_block "$CF_EFF" app-as | grep -q "target: $CONTACT_MNT" \
    && ok "app-as 가 연락서 공유폴더($CONTACT_MNT)를 그대로 붙인다 (18번이 붙인 것)" \
    || bad "app-as 에서 $CONTACT_MNT 가 **사라졌다** — 🔴 연락서 연동이 죽는다"
  # 🔴 연락서는 **쓸 수 있어야** 한다 — 거기에 read_only 가 붙으면 안 된다.
  svc_block "$CF_EFF" app-as | line_after "target: $CONTACT_MNT" | grep -q 'read_only' \
    && bad "🔴 연락서 볼륨에 read_only 가 붙었다 — 폴더 만들기·사본 꽂기가 죽는다" \
    || ok "연락서 볼륨은 그대로 **쓸 수 있다** (read_only 가 없다)"
  svc_block "$CF_EFF" tools-as | grep -q "$MIGDIR:/app/drizzle" \
    && ok "tools-as 가 $MIGDIR 를 /app/drizzle 로 붙인다 (1-ㄹ 이 세는 그 폴더)" \
    || bad "tools-as 의 drizzle 볼륨이 $MIGDIR 가 아니다"
  # ── 🔴 이번 배포의 **새 볼륨** — 읽기 전용 ──────────────────────────
  say "  🔴 이번에 새로 붙는 「수리 관련」 공유폴더 (🔴 **읽기 전용**):"
  svc_block "$CF_EFF" app-as | grep -q "target: $REPAIR_MNT" \
    && ok "app-as 가 $REPAIR_MNT 를 붙인다" \
    || bad "app-as 에 $REPAIR_MNT 가 **없다** — 🔴 가리킨 서류가 통째로 꺼진다"
  svc_block "$CF_EFF" app-as | grep -qF "source: \"$REPAIR_SRC\"" \
    && ok "원본 경로가 글자까지 맞다 ($REPAIR_SRC)" \
    || bad "원본 경로가 $REPAIR_SRC 가 아니다 — 🔴 대소문자(2_AS센터)부터 보세요"
  svc_block "$CF_EFF" app-as | line_after "target: $REPAIR_MNT" | grep -q 'read_only: true' \
    && ok "🔴 read_only: true 가 붙어 있다 — 앱이 이 서류함을 못 고친다" \
    || bad "🔴 $REPAIR_MNT 에 read_only: true 가 **없다** — 쓰기가 열린 채로 돈다"
  svc_block "$CF_EFF" app-as | grep -q "type: bind" \
    && ok "긴 문법(type: bind)으로 적혀 있다 (경로에 공백이 있다)" \
    || bad "긴 문법이 아니다 — 🔴 짧은 문법은 이 경로에서 깨진다"
  # 🔴 일부러 안 붙이는 둘
  svc_block "$CF_EFF" app-po | grep -q "$REPAIR_MNT" \
    && say "    ⚠️ app-po 에도 $REPAIR_MNT 가 붙어 있다 — PO 에는 이 화면이 없다(없어도 된다)" \
    || ok "app-po 에는 안 붙였다 (맞다 — PO 저장소에 이 화면이 없다)"
  svc_block "$CF_EFF" tools-as | grep -q "$REPAIR_MNT" \
    && say "    ⚠️ tools-as 에도 붙어 있다 — 쓰는 스크립트가 없다(없어도 된다)" \
    || ok "tools-as 에는 안 붙였다 (맞다 — 교산 이식용이고 쓸 이유가 없다)"
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
    say "    🔴 그래서 0112 는 **PO 가 보는 DB 의 attachments 표**도 바꾼다."
    say "       🔵 그래도 PO 를 멈추지 않아도 된다 — 더해지는 칸은 NULL 을 받고,"
    say "          CHECK 는 그 칸이 NULL 이 아닐 때만 조건을 건다. PO(0.3)는 그 칸을"
    say "          모르므로 늘 NULL 로 넣는다. 0113 · 0114 의 새 표도 PO 는 모른다."
  else
    bad "app-po 의 DATABASE_URL 이 app-as 와 다르다 — 🔴 PO 가 엉뚱한 DB 를 본다"
  fi

  # ── 1-ㅅ. 폴더를 컨테이너 안에서 **실제로 열어 본다** ────────────────
  step "1-ㅅ. 폴더 — 주인·모드가 아니라 컨테이너 안에서 실제로 연다"
  say "  🔴 보는 자리가 둘로 갈린다:"
  say "     ㄱ) **이미 붙어 있는 자리**(/data · /templates · /quote-archive ·"
  say "        $PORTAL_MNT · $CONTACT_MNT)는 지금 도는 컨테이너 안에서 본다."
  say "     ㄴ) **이번 배포로 새로 붙는 자리**($REPAIR_MNT)는 도는 2.1 에"
  say "        아직 없다 — 호스트 경로를 **임시로 붙여** 따로 본다."
  if [ "$PROBE_WRITE" = 1 ]; then
    say "  (교체되는 A/S 의 /data 는 읽기+쓰기를 본다. 시험 파일은 만들었다 지운다.)"
  else
    say "  🔵 --check 라서 **읽기만** 해 본다 — 아무 파일도 만들지 않는다."
  fi
  # 호스트 쪽에 그 폴더가 **있는지**부터. 없으면 볼륨이 빈 폴더로 붙는다.
  if [ -d "$REPAIR_SRC" ]; then
    ok "호스트에 「수리 관련」 폴더가 있다"
    say "    $REPAIR_SRC"
    n_snap=$(ls -1 "$REPAIR_SRC" 2>/dev/null | wc -l | tr -d ' ')
    say "    · 맨 위 칸의 항목 ${n_snap:-?}개"
    if [ "${n_snap:-0}" = 0 ]; then
      bad "🔴 **0개다.** 경로가 틀렸다 — 「2_AS센터」 의 AS 가 대문자인지 보세요"
      cmd "ls -d /volume1/2_AS*"
    fi
    [ -d "$REPAIR_SRC/$REPAIR_SUB" ] \
      && ok "그 안에 「$REPAIR_SUB」 가 있다 — 자리가 맞다 (연락서 볼륨의 윗 폴더다)" \
      || bad "「$REPAIR_SUB」 가 안 보인다 — 🔴 한 칸 위나 아래를 가리킨 것이다"
  else
    bad "호스트에 「수리 관련」 폴더가 **없다**: $REPAIR_SRC"
    say "    → 🔴 「2_AS센터」 의 AS 가 **대문자**인지 보세요. 소문자로 적으면"
    say "       docker 가 **빈 폴더를 만들어 붙입니다** — 그러면 고르는 창이"
    say "       「서류가 하나도 없다」로 보입니다."
    cmd "ls -d /volume1/2_AS*"
  fi
  if [ "$PROBE_WRITE" = 1 ]; then M_DATA=rw; else M_DATA=ro; fi
  probe_svc app-as dss-as "A/S" "/data:$M_DATA /templates:ro" "$ATT $TEMPLATES"
  # 🔴 이번 배포로 **새로 붙는** 볼륨. 도는 컨테이너에는 아직 없다.
  probe_new_volume "$REPAIR_SRC" "$REPAIR_MNT" "「수리 관련」 공유폴더" "$REPAIR_SUB"
  # 🔴 교체 안 되는 곳 — 「아직 읽히는가」만 본다. 쓰기 시험을 하지 않는다.
  probe_svc app-po           dss-po           PO       "/data:ro"         "$ATT"
  probe_svc app-meters       dss-meters       계측기   "/data:ro"         "$MF_METERS"
  probe_svc app-improvements dss-improvements 개선요청 "/data/uploads:ro" "$UP_IMP"
  # 🔴 공유폴더 셋은 위 틀에 안 넣는다 — 경로에 빈칸과 한글이 있고, 무엇보다
  #    여기서는 ACL 을 **걷으면 안 된다**(직원의 탐색기 접근이 끊긴다).
  say "  이미 붙어 있는 공유폴더 셋 — 🔴 읽기만 본다. ACL 을 걷지 않는다:"
  for rec in "dss-as|A/S|/quote-archive" "dss-po|PO|/quote-archive" \
             "dss-as|A/S|$PORTAL_MNT" "dss-as|A/S|$CONTACT_MNT"; do
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

  # ── 1-ㅇ. 🔴 야간 백업 · 야간 완전삭제 (읽기만 한다) ─────────────────
  step "1-ㅇ. 야간 백업 다섯 · 야간 완전삭제 (읽기만 한다)"
  say "  🔴 이번 판은 **DB 를 바꾼다**(마이그레이션 셋). 백업의 문을 더 단단히 본다."
  say "     --go 는 오늘 뜬 $AS_DB 백업이 없으면 **시작조차 않는다**(3-ㄱ)."
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

  # ── 1-ㅈ. 디스크 · DB · 지금 도는 것 ────────────────────────────────
  step "1-ㅈ. 디스크 · DB · 지금 도는 것"
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
  # 새 tar 약 124MB + 실은 이미지 약 584MB + 덤프 + 첨부 하드링크(공간 0).
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (새 tar + 실은 이미지 + 덤프가 들어가야 한다)"
  fi

  # ── 1-ㅊ. 알림 링크의 주소 — A/S 만 ─────────────────────────────────
  step "1-ㅊ. 알림 링크의 주소 (통로가 아니라 **나오는 주소**를 본다)"
  say "  🔴 **A/S 하나만 본다.** PO 에는 알림 통로가 아예 없다."
  say "  🔵 이번 판은 알림을 건드리지 않았다 — 기대값도 그대로다."
  notify_href_check "A/S" dss-as "$AS_ENV" "https://as.dss21.co.kr"

  # ── 1-ㅋ. 새 이미지 **안에** 이번 판이 들어 있는가 ───────────────────
  step "1-ㅋ. 새 이미지 안을 본다 (태그만으로는 안심 못 한다)"
  say "  🔴 9/21~9/29 에 A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다."
  if have_img "$TAG_AS"; then
    say "  $TAG_AS 구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_AS" --format '{{.Size}}' 2>/dev/null)"
    say "        ($OLD_AS 는 584MB 였다 — 🔴 **크기로는 못 가른다.**)"
    say "  🔴 그래서 **안의 여덟 자리**로 가른다:"
    inside_check "$TAG_AS"
    say "  🔵 글자 인식기(public/ocr) 회귀 검사 — 2.1 의 것이 그대로 있는가:"
    ocr_check "$TAG_AS"
  else
    notloaded "$TAG_AS 가 아직 안 실려 **안을 못 봤다** (머리말 ⑥ — ✗ 가 아니다)"
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
  say "  🔵 지금 것과 달라진 줄 (image 한 줄 · type: bind 볼륨 · read_only · 그 주석):"
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
  echo "DSS 열다섯째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     되돌리는 것은 **이미지 하나**다:  $TAG_AS → $OLD_AS"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 DB 는 **되돌리지 않는다.** 그대로 둔다.                      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     0112 · 0113 · 0114 는 칸 하나와 표 둘을 **더하기만** 했다. 자료를"
  say "     지우지 않았다. $OLD_AS 는 그 칸도 그 표도 **읽지도 쓰지도 않는다** —"
  say "     그대로 둬도 아무 일도 일어나지 않는다."
  say "     🔴 되돌리려고 덤프를 되붓는 것이 **오히려 자료를 잃는 길**이다 —"
  say "        덤프 시각 이후에 들어온 접수·작업 기록이 통째로 사라진다."
  say "     (3-ㄴ 에서 뜬 덤프는 「마이그레이션이 DB 를 깨뜨렸을 때」만 쓰는"
  say "      마지막 수단이다. 그때는 Claude 에게 알리고 함께 한다.)"
  say
  say "  ⚠️ 🔴 되돌리기 전에 **두 가지를 알아 두라.**"
  say "     ㄱ) 2.2 가 도는 동안 **제품 종류 공통 서류**로 올린 첨부는 주인 칸이"
  say "        $NEW_COL 이다. $OLD_AS 는 그 칸을 모르므로 그 파일들이 **어느"
  say "        목록에도 안 보인다.** 🔴 **지우지 마라** — 다시 2.2 를 올리면"
  say "        그대로 보인다. (디스크 파일도 그대로 있다.)"
  say "     ㄴ) 2.2 가 도는 동안 **영구 삭제**한 첨부는 **돌아오지 않는다.**"
  say "        DB 행도 디스크 파일도 이미 없다. 되돌리기로 살아나지 않는다."
  say
  if pg_up; then
    s=$(qas "select count(*) from $NEW_COL_TBL where $NEW_COL is not null")
    say "  · 종류 공통 서류로 올라간 첨부: ${s:-?}건 (select 다)"
    s=$(qas "select count(*) from $NEW_TBL1")
    say "  · $NEW_TBL1 에 적힌 자리: ${s:-?}건"
    s=$(qas "select count(*) from $NEW_TBL2")
    say "  · $NEW_TBL2 에 적힌 자리: ${s:-?}건"
    say "    🔵 이 줄들은 2.1 에서 안 보일 뿐 **사라지지 않는다.**"
  else
    say "    · dss-pg-app 이 안 떠 있어 세지 못했다"
  fi

  step "1. 옛 이미지가 아직 NAS 에 있는지 먼저 본다"
  if have_img "$OLD_AS"; then
    ok "$OLD_AS 있다 ($(img_id "$OLD_AS" | cut -c1-19)…)"
  else
    bad "$OLD_AS 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"
  fi

  step "2. compose 를 되돌린다 — 🔴 **사본으로 되돌린다**"
  say "  🔴 이번 판은 태그만 바뀐 것이 아니다 — **볼륨 네 줄**이 함께 들어갔다."
  say "     그래서 sed 로 태그만 내리면 **2.1 에 쓰지 않는 볼륨이 남는다.**"
  say "     (남아도 2.1 은 그 자리를 안 쓰고 읽기 전용이라 해롭진 않다."
  say "      그래도 사본이 깔끔하다.)"
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
  say "  덧붙인 두 줄은 $OLD_AS 가 **읽지 않는다**(그 코드가 없다). 그대로 두세요."
  say "  그래도 되돌리고 싶다면 사본이 여기 있습니다:"
  ls -1t "$BKD"/as.env.* 2>/dev/null | head -3 | sed 's/^/      /'

  step "4. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-as"
  script_file_hint "19-rollback"

  step "5. 🔴 사람에게 알릴 것"
  say "  되돌리면 **「가리킨 서류」 구역이 없어지고 영구 삭제 단추도 사라진다.**"
  say "  도우미는 그대로 두세요 — 2.1 의 견적서 · 현황표 · 연락서 [폴더 열기]는"
  say "  새 도우미로도 그대로 돕니다(설치본에 루트를 여럿 심고 차례로 해 본다)."

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
echo "DSS 열다섯째 배포 · 2026-10-08 · $(date '+%F %T')"
echo "  🔴 올라가는 것은 **하나**:  $OLD_AS → $TAG_AS"
echo "  🔴 멈추는 것도 **하나**:  dss-as"
echo "  🔴 이번 판의 줄기 넷: **제품 모델·종류가 공유폴더 자리를 가리킨다** ·"
echo "     첨부 **영구 삭제** · 도우미 재설치 안내를 **세대로** · 견적서 잔손질"
echo "  🔴 **마이그레이션 셋**($NEW_MIGS) — 운영 $N_MIG_HAVE → $N_MIG_WANT. 더하기만 한다"
echo "  🔴 **새 볼륨 하나** — $REPAIR_MNT (🔴 **읽기 전용**)"
echo "  🔴 **as.env 에 두 줄** — REPAIR_DOCS_ARCHIVE_DIR · _UNC_ROOT"
echo "  🔵 도구 이미지 그대로 ($KEEP_ASTOOLS)"
echo "  🔵 야간 백업은 **02:30** — 자정 넘어 돌리면 백업 검사에 걸립니다"
echo "  · 건드리지 않는 아홉 — $KEEP_AUTH · $KEEP_ASTOOLS · $KEEP_METERS"
echo "    · $KEEP_METERSTOOLS · $KEEP_IMP · $KEEP_IMPTOOLS"
echo "    · $KEEP_PO · $KEEP_LEAVE · $KEEP_LEAVETOOLS"
if ! pinned; then
  echo "  ⚠️ 🔴 **이미지 기대값 셋이 아직 비어 있습니다**(SZ_AS · MD5_AS · WANT_CFG_AS)."
  echo "     개발 PC 에서 2.2 를 굽고 재어 채우기 전에는 --go 가 시작하지 않습니다."
  echo "     재는 차례는 이 파일 머리말 「돌리기 전에 — 값 셋을 채워야 한다」."
fi
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**"
              echo "     🔵 아직 안 온 것 · 안 실린 것은 ⚠️ 로만 말한다(✗ 가 아니다)." ;;
  preload)    echo "  🔵 --preload — 새 이미지를 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — 마이그레이션 셋을 적용하고 볼륨 · as.env 두 줄을 넣고"
              echo "     A/S 하나만 교체한다."
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
step "1. 점검표를 기계로 옮긴 것 (앱은 살아 있다 · DB 는 아직 손도 안 댄다)"
compose_incoming || stop "compose 를 바꾸지 않았습니다. 앱은 그대로 돕니다."
run_checks

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  if [ "$FAIL" = 0 ]; then
    if pinned; then
      echo "  ✅ 이어서 (A/S 가 잠깐 멈추고 DB 가 바뀝니다):  bash $0 --go"
      echo "     🔴 --go 는 오늘 백업($AS_DB)이 없으면 **시작하자마자 멈춥니다.**"
      echo "     🔵 야간 백업은 02:30 입니다 — 먼저 손으로 뜨려면:"
      echo "          bash /volume1/dss/jobs/backup-nightly.sh"
    else
      echo "  🔴 아직 --go 를 부를 수 없습니다 — 이미지 기대값 셋이 비어 있습니다."
      echo "     개발 PC 에서 2.2 를 굽고 재어 이 파일에 채운 뒤 다시 올리세요."
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

# ══ 3. 🔴 멈추기 전에 — 백업 · 덤프 · 볼륨 · 마이그레이션 파일 · as.env ══
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
  say "     마이그레이션이 셋이고 더하기만 하지만, 백업 없이 DB 를 바꾸지"
  say "     않습니다. 🔵 야간 백업은 **02:30** 입니다 — 자정을 넘겨 돌리면"
  say "     여기 걸립니다. 먼저 이것부터 (종료 코드 0 이어야 합니다):"
  cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  say "     ✓ $AS_DB 줄이 찍혀야 합니다. 그 뒤에 다시:"
  cmd "bash $0 --go"
  stop "백업 없이 DB 를 바꾸지 않습니다. **DB 도 앱도 그대로입니다.**"
fi

# ── 3-ㄴ. 덤프 — 🔴 「마이그레이션이 DB 를 깨뜨렸을 때」의 마지막 수단 ──
#
# 🔴 되돌리기의 **기본 수단이 아니다.** 되돌리기는 이미지만 2.1 로 내리고 DB 는
#    그대로 두는 것이다(--rollback 참조).
step "3-ㄴ. 적용 직전 덤프 ($AS_DB) · 첨부 하드링크 스냅숏"
BK=$BKD/predeploy-$STAMP
mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
if "$DOCKER" exec dss-pg-app sh -c "pg_dump -U \"\$POSTGRES_USER\" -d $AS_DB -Fc" \
     > "$BK/$AS_DB.dump.part" 2>/dev/null \
   && "$DOCKER" exec -i dss-pg-app pg_restore -l < "$BK/$AS_DB.dump.part" >/dev/null 2>&1; then
  mv "$BK/$AS_DB.dump.part" "$BK/$AS_DB.dump"
  ok "$AS_DB 덤프 $(du -h "$BK/$AS_DB.dump" | cut -f1) → $BK"
else
  rm -f "$BK/$AS_DB.dump.part"
  bad "$AS_DB 덤프 실패"
  say "    🔴 3-ㄱ 의 야간 백업은 있습니다. 그래도 **적용 직전 덤프 없이는**"
  say "       가지 않습니다 — 야간 백업은 02:30 것이라 그 뒤의 일이 빠집니다."
  stop "DB 를 바꾸지 않았습니다. **앱도 그대로입니다.**"
fi
if [ -d "$ATT" ]; then
  cp -al "$ATT" "$BK/as-attachments" 2>/dev/null \
    && ok "첨부 스냅숏 (cp -al 하드링크 — 즉시 · 공간 0)" || bad "첨부 스냅숏 실패"
else
  bad "첨부 폴더가 없다: $ATT"
fi
say "  🔴 이번 판에는 **영구 삭제**가 들어 있다 — 그래서 첨부 스냅숏이 전보다"
say "     무겁다. 🔵 cp -al 은 하드링크라 **공간을 쓰지 않는다.** 2.2 가 디스크"
say "     파일을 지워도 이 스냅숏의 링크가 남아 **한 주쯤은 되살릴 수 있다.**"
say "  ⚠️ PO 가 같은 DB 를 보고 있다 — 덤프 중에 PO 에서 저장한 것은 이 덤프에"
say "     안 들어갈 수 있다. 그래서 이 덤프는 마지막 수단이고, 되돌리기의"
say "     기본은 **이미지만 내리고 DB 는 그대로 두는 것**이다."
say "  🔵 공유폴더(견적서 · 현황표 · 연락서 · 수리 관련)는 **스냅숏을 뜨지 않는다** —"
say "     직원의 서류함이라 우리가 사본을 만들 자리가 아니다. NAS 의 야간 백업이 본다."

# ── 3-ㄷ. 🔴 새 공유폴더가 **읽히고, 쓰기가 막혀 있는가** ──────────────
step "3-ㄷ. 「수리 관련」 공유폴더 — 읽기 · 쓰기 막힘 시험 (uid 1000 · gid 100)"
say "  🔴 여기는 /volume1/dss 가 아니라 **직원이 탐색기로 쓰는 서류함**이다."
say "     ACL 을 걷지 않는다 — 걷으면 직원의 접근이 끊긴다."
say "  🔴 18번(연락서)과 **반대**다. 이번 기능은 **읽기만** 한다 —"
say "     쓰기가 되면 오히려 ✗ 다(사용자 결정 2026-10-08)."
if [ ! -d "$REPAIR_SRC" ]; then
  bad "폴더가 없다: $REPAIR_SRC"
  say "    → 🔴 2_AS센터 의 AS 가 **대문자**인지 보세요."
  cmd "ls -d /volume1/2_AS*"
  stop "경로를 확인하세요. **앱도 DB 도 그대로입니다.**"
fi
ok "폴더가 있다"
probe_new_volume "$REPAIR_SRC" "$REPAIR_MNT" "「수리 관련」 공유폴더" "$REPAIR_SUB" \
  || stop "새 볼륨이 기대한 모습이 아닙니다. **앱도 DB 도 그대로입니다.**"

# ── 3-ㄹ. 🔴 마이그레이션 파일을 제자리에 놓는다 (17번에서 되가져옴) ───
#
# 🔴 .sql 셋만이 아니라 meta/_journal.json 과 snapshot 셋까지 함께 간다.
#    그래서 폴더를 **통째로** 갈아 끼운다(10 · 16 · 17-deploy.sh 와 같은 길).
step "3-ㄹ. 마이그레이션 파일 놓기 ($MIGDIR)"
if [ -s "$MIGTAR" ]; then
  rm -rf "$MIGDIR.new"; mkdir -p "$MIGDIR.new"
  if tar -xzf "$MIGTAR" -C "$MIGDIR.new" --strip-components=1; then
    rm -rf "$MIGDIR.old"
    [ -d "$MIGDIR" ] && mv "$MIGDIR" "$MIGDIR.old"
    mv "$MIGDIR.new" "$MIGDIR"
    rm -f "$MIGTAR"
    chown -R root:root "$MIGDIR"; chmod -R a+rX "$MIGDIR"
    ok "as-migrations 새것으로 (옛것: as-migrations.old)"
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
[ "$N_SQL" = "$N_MIG_WANT" ] && ok ".sql ${N_SQL}개" \
  || bad ".sql 이 ${N_MIG_WANT}개가 아니다 (${N_SQL}개)"
[ "$N_J" = "$N_MIG_WANT" ] && ok "_journal.json 의 tag ${N_J}줄" \
  || bad "_journal.json 의 tag 가 ${N_MIG_WANT}줄이 아니다 (${N_J}줄) — 🔴 적용이 0건으로 끝난다"
MISS=""
for t in $NEW_MIGS; do
  ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || MISS="$MISS $t(sql)"
  [ -f "$MIGDIR/meta/${t}_snapshot.json" ] || MISS="$MISS $t(snapshot)"
done
[ -z "$MISS" ] && ok "$NEW_MIGS 의 .sql 과 snapshot 이 다 있다" || bad "빠진 것:$MISS"
check_one_mig 0112 "$MIG_0112_MARK"
check_one_mig 0113 "$MIG_0113_MARK"
check_one_mig 0114 "$MIG_0114_MARK"
[ "$FAIL" = 0 ] || stop "마이그레이션 파일이 온전하지 않습니다. **DB 도 앱도 그대로입니다.**"

# ── 3-ㅁ. 🔴 as.env 에 두 줄을 덧붙인다 (아직 아무것도 안 멈췄다) ──────
#
# 🔴 이 PC 의 as.env 를 올리는 것이 아니다. **NAS 의 파일을 읽고 없는 줄만**
#    덧붙인다. 이미 있으면 건드리지 않는다(두 번 돌려도 안전하다).
step "3-ㅁ. as.env 에 설정 **두 줄** 덧붙이기"
build_env_values
cp -p "$AS_ENV" "$BKD/as.env.$STAMP"; chmod 600 "$BKD/as.env.$STAMP"
ok "as.env 사본 — backups/as.env.$STAMP (root 600)"
# 🔴 견적서 셋 · 현황표 다섯 · 연락서 셋이 그대로 있는지 **적기 전에** 한 번 더 본다.
for k in $QUOTE_KEYS $PORTAL_KEYS $CONTACT_KEYS; do
  grep -q "^$k=" "$AS_ENV" || {
    bad "$k 가 as.env 에 없다 — 🔴 누가 덮어썼다"
    stop "as.env 가 온전하지 않습니다. 덧붙이지 않았습니다. **앱도 DB 도 그대로입니다.**"
  }
done
ok "견적서 셋 · 현황표 다섯 · 연락서 셋이 그대로 있다 — 덧붙여도 안전하다"
# 파일이 개행으로 끝나지 않으면 먼저 한 줄 띄운다(마지막 줄에 붙어 버린다).
[ -n "$(tail -c 1 "$AS_ENV")" ] && printf '\n' >> "$AS_ENV"
ADDED=0
for k in $ENV_KEYS; do
  if grep -q "^$k=" "$AS_ENV"; then
    say "  · $k 는 **이미 있다** — 건드리지 않는다"
    continue
  fi
  [ "$ADDED" = 0 ] && {
    printf '\n# ── 「수리 관련」 서류 공유폴더 — %s 19-deploy.sh 가 덧붙임 ──\n' \
      "$TODAY" >> "$AS_ENV"
  }
  printf '%s\n' "$(env_line_for "$k")" >> "$AS_ENV"
  ADDED=$((ADDED + 1))
  ok "$k 덧붙였다"
done
chown root:root "$AS_ENV"; chmod 600 "$AS_ENV"
if [ "$ADDED" = 0 ]; then
  ok "두 줄이 모두 이미 있었다 — as.env 를 한 글자도 안 바꿨다"
else
  ok "$ADDED 줄을 덧붙였다 (모드 600 · root:root 로 되돌렸다)"
fi
# 🔴 두 줄은 **폴더 경로**다 — 비밀이 아니고, 사람이 눈으로 맞춰 봐야 하는
#    값이라 그대로 찍는다. as.env 의 다른 줄은 한 글자도 찍지 않는다.
say "  지금 as.env 에 들어 있는 두 줄 (값까지 그대로):"
for k in $ENV_KEYS; do
  printf '      %s\n' "$(grep "^$k=" "$AS_ENV" | head -1)"
done
say "  🔴 호스트 토막의 출처: $ENV_SRC_NOTE → $ENV_HOST ($ENV_HOST_WHY)"

# ── 3-ㅂ. 건드리지 않는 쪽의 **시작 시각**을 적어 둔다 ─────────────────
#
# 🔴 「안 멈췄다」를 말로 하지 않는다. 교체 뒤에 이 값과 그대로인지 본다.
step "3-ㅂ. 건드리지 않는 쪽의 시작 시각을 적어 둔다 (뒤에서 대조한다)"
KEEP_BOXES="dss-auth dss-meters dss-improvements dss-po dss-leave dss-pg-app dss-pg-auth"
STARTED_BEFORE=""
for t in $KEEP_BOXES; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  STARTED_BEFORE="$STARTED_BEFORE$t=$s
"
  say "  · $t  시작 ${s:-?}"
done

# ══ 4. 적용 전 확인 (db:preflight) — 🔴 앱은 **아직 2.1 로 살아 있다** ══
step "4. 적용 전 확인 — db:preflight  (🔴 앱은 아직 $OLD_AS 로 살아 있다)"
say "  🔴 셋 다 **지우는 문장이 하나도 없다**(DROP · TRUNCATE · DELETE FROM 없음)."
say "     그러니 「사라질 자료가 있는 항목」이 나오면 그것이 신호다 — 멈춘다."
say "  🔵 「살펴봐야 할 것」 칸은 종료 코드를 건드리지 않는다. 이번 셋에는 거기"
say "     잡히는 문장(DROP INDEX · RENAME · SET NOT NULL · 타입 바꾸기)이 없다."
"${COMPOSE[@]}" run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | sed 's/^/    /'
PRC=${PIPESTATUS[0]}
say "  (종료 코드 $PRC — 기대 0 · 대기 **3건**이어야 한다)"
if [ "$PRC" != 0 ]; then
  bad "db:preflight 가 0 이 아니다 ($PRC) — 사라질 자료가 있다는 뜻이다"
  say "    → 🔴 0112 · 0113 · 0114 에는 그럴 문장이 없다. **다른 것이 섞였다.**"
  stop "마이그레이션을 시작하지 않았습니다. **DB 도 앱도 그대로이고 직원은 $OLD_AS 를 쓰고 있습니다.**"
fi
N_BEFORE=$(qas "select count(*) from drizzle.__drizzle_migrations")
say "  · 적용 전 DB 의 마이그레이션 줄: ${N_BEFORE:-?}  (기대 $N_MIG_HAVE)"
say
say "  🔴 이제 DB 를 바꿉니다. 그만두려면 **20초 안에 Ctrl+C**."
say "     지금 Ctrl+C 하면 DB 도 앱도 손대지 않은 채로 남습니다."
say "     (compose · 마이그레이션 파일 · as.env 는 이미 바뀌었지만, 그것만으로는"
say "      아무 일도 일어나지 않습니다 — $OLD_AS 는 그것을 읽지 않습니다.)"
sleep 20

# ══ 5. 🔴 마이그레이션 적용 — 앱은 아직 $OLD_AS 로 살아 있다 ═══════════
step "5. 마이그레이션 적용 ($NEW_MIGS)  🔴 여기서 DB 가 바뀐다"
say "  더하기만 한다 — 칸 하나($NEW_COL_TBL.$NEW_COL) · 타입 하나($NEW_TYPE) ·"
say "  표 둘($NEW_TBL1 · $NEW_TBL2)."
say "  🔴 다시 돌려도 안전하다. drizzle 은 이미 적용된 것을 건너뛴다."
say "  🔵 도는 동안 직원은 **$OLD_AS 를 그대로 쓰고 있다.** 아직 안 멈췄다."
"${COMPOSE[@]}" run --rm "$AS_TOOLS_SVC" npm run db:migrate 2>&1 | sed 's/^/    /'
rc=${PIPESTATUS[0]}
if [ "$rc" = 0 ]; then
  ok "db:migrate 끝 (종료 코드 0)"
else
  bad "db:migrate 실패 (종료 코드 $rc)"
  say "    ╔══════════════════════════════════════════════════════════════╗"
  say "    ║ 🔵 **직원은 아직 $OLD_AS 를 그대로 쓰고 있습니다.** 안 멈췄습니다. ║"
  say "    ╚══════════════════════════════════════════════════════════════╝"
  say "    🔴 **새 이미지를 띄우지 않습니다.** $TAG_AS 는 없는 표를 읽습니다."
  say "    🔴 compose 는 이미 $TAG_AS 를 가리키고 있으니, 누가 up -d 를 부르면"
  say "       $TAG_AS 가 올라옵니다 — 부르지 마세요."
  say "    → 고친 뒤 **다시 돌리면 됩니다**(이미 적용된 것은 건너뜁니다):"
  cmd "bash $0 --go"
  say "    → 오늘은 그만두려면 compose 를 $OLD_AS 로 되돌려 두세요. 아래가 그"
  say "       명령을 **찍어만 줍니다**(스스로 되돌리지 않습니다):"
  cmd "bash $0 --rollback"
  stop "마이그레이션이 중간에 멈췄습니다. 적용 직전 덤프: $BK/$AS_DB.dump"
fi
N_AFTER=$(qas "select count(*) from drizzle.__drizzle_migrations")
[ "${N_AFTER:-0}" = "$N_MIG_WANT" ] \
  && ok "DB 의 마이그레이션 줄 ${N_AFTER} (전 ${N_BEFORE:-?})" \
  || bad "마이그레이션 줄이 ${N_MIG_WANT}이 아니다 (${N_AFTER:-?})"
say "  🔴 적용 뒤 preflight — **대기 0건**이어야 한다:"
"${COMPOSE[@]}" run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | sed 's/^/    /'
say "  (종료 코드 ${PIPESTATUS[0]})"

# 🔴 「했다」가 아니라 「들어 있다」를 본다 — DB 에서 직접 센다.
say "  🔴 SQL 로 직접 센다 (「했다」가 아니라 「들어 있다」를 본다 · 전부 select):"
E_TYPE=$(qas "select count(*) from pg_type where typname = '$NEW_TYPE'")
[ "${E_TYPE:-0}" = 1 ] && ok "0113 · 타입 $NEW_TYPE 이 생겼다" \
  || bad "타입 $NEW_TYPE 이 **없다** (${E_TYPE:-?}) — 🔴 $TAG_AS 를 띄우면 죽는다"
for t in "$NEW_TBL1" "$NEW_TBL2"; do
  if [ -n "$(qas "select to_regclass('public.$t')")" ]; then
    ok "표 $t 가 생겼다"
  else
    bad "표 $t 가 **없다** — 🔴 $TAG_AS 를 띄우면 그 화면이 죽는다"
  fi
done
E_COL=$(qas "select count(*) from information_schema.columns where table_name = '$NEW_COL_TBL' and column_name = '$NEW_COL'")
[ "${E_COL:-0}" = 1 ] && ok "0112 · $NEW_COL_TBL 에 $NEW_COL 칸이 생겼다" \
  || bad "$NEW_COL_TBL.$NEW_COL 칸이 **없다** (${E_COL:-?})"
E_CHK=$(qas "select count(*) from pg_constraint where conname = '$NEW_CHECK'")
[ "${E_CHK:-0}" = 1 ] && ok "0112 · CHECK 제약 $NEW_CHECK 이 걸렸다" \
  || bad "CHECK 제약 $NEW_CHECK 이 **없다** (${E_CHK:-?})"
say "  🔵 새 표 둘은 **비어 있는 것이 맞다** — 사람이 화면에서 자리를 고를 때 찬다:"
say "      $NEW_TBL1: $(qas "select count(*) from $NEW_TBL1")건"
say "      $NEW_TBL2: $(qas "select count(*) from $NEW_TBL2")건"
say "  🔵 $NEW_COL 이 들어간 첨부도 아직 0건이 맞다:"
say "      $(qas "select count(*) from $NEW_COL_TBL where $NEW_COL is not null")건"
[ "$FAIL" = 0 ] || stop "DB 가 기대한 상태가 아닙니다. 직원은 **아직 $OLD_AS 를 쓰고 있습니다.** 적용 직전 덤프: $BK/$AS_DB.dump"

# ══ 6. A/S 를 새 판으로 바꿔 끼운다 — 🔴 여기 하나가 정지 창이다 ═══════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다(포털·계측기까지 흔들린다).
#    --no-deps 로 **이름을 적은 하나만** 부른다.
# 🔴 따로 stop 하지 않는다. up -d 가 옛 컨테이너를 지우고 새것을 올리는 한
#    걸음이라, 나눠 부르면 그 사이만큼 정지 창이 길어진다.
step "6. 새 이미지로 바꿔 끼운다 ($OLD_AS → $TAG_AS)  ⏱ 여기부터 정지 창"
say "  🔴 **멈추는 것은 dss-as 하나뿐이다.**"
say "     그대로 도는 것: 포털 · 계측기 · 개선요청 · PO · 휴가 · DB 둘."
say "     즉 https://as.dss21.co.kr 만 몇십 초 대답하지 않는다."
say "  🔵 새 컨테이너는 **「수리 관련」 볼륨을 달고** 뜬다 — 그래서 up -d 가 필요하다"
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

# ══ 7. 스모크 ══════════════════════════════════════════════════════════
step "7. 스모크 — 폴더 · 설정 · 알림 · 권한 · 안 멈췄는가 · 바깥 주소"

# 7-ㄱ. 새 컨테이너로 폴더를 **실제로 열어 본다**
say "  7-ㄱ. 폴더를 새 컨테이너 안에서 실제로 연다"
say "        🔴 「수리 관련」은 **읽기만** 본다 — 쓰기 시험을 하지 않는다."
probe_svc app-as dss-as "A/S" \
  "/data:rw /templates:ro $REPAIR_MNT:ro" "$ATT $TEMPLATES"

say "  7-ㄴ. 이미 있던 공유폴더 셋 — 🔴 이번 판은 안 건드렸다"
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
  # 🔴 연락서는 **여전히 쓸 수 있어야** 한다. 새 볼륨이 읽기 전용이라고 해서
  #    그 아래 자리까지 잠기면 안 된다 — 둘은 서로 다른 바인드다.
  if "$DOCKER" exec dss-as sh -c "t='$CONTACT_MNT/.dss-write-test'; : > \"\$t\" && rm -f \"\$t\"" >/dev/null 2>&1; then
    ok "🔴 연락서 공유폴더는 **아직 쓸 수 있다** (새 읽기 전용 볼륨에 안 잠겼다)"
  else
    bad "🔴 연락서 공유폴더에 **못 쓴다** — 폴더 자동 생성 · 사본 꽂기가 죽는다"
    say "    → compose 의 app-as 에서 $CONTACT_MNT 쪽에 read_only 가 붙었는지 보세요."
  fi
  # 🔴 새 볼륨은 **쓰기가 막혀 있어야** 맞다.
  if "$DOCKER" exec dss-as sh -c "t='$REPAIR_MNT/.dss-ro-test'; : > \"\$t\"" >/dev/null 2>&1; then
    bad "🔴 $REPAIR_MNT 에 **쓸 수 있다** — read_only 가 안 먹었다"
    "$DOCKER" exec dss-as sh -c "rm -f '$REPAIR_MNT/.dss-ro-test'" >/dev/null 2>&1
    say "    🔵 시험 파일은 곧바로 지웠다 — 남아 있으면 알려 주세요."
  else
    ok "🔴 $REPAIR_MNT 는 **쓰기가 막혀 있다** (읽기 전용으로 붙었다)"
  fi
else
  bad "dss-as 컨테이너가 떠 있지 않다"
fi

# 7-ㄷ. 🔴 as.env 의 두 줄이 **컨테이너 안까지** 그대로 왔는가
say "  7-ㄷ. 🔴 「수리 관련」 설정 둘이 컨테이너 안까지 그대로 왔는가"
if running dss-as; then
  "$DOCKER" exec dss-as sh -c "[ -d \"\$REPAIR_DOCS_ARCHIVE_DIR\" ]" >/dev/null 2>&1 \
    && ok "REPAIR_DOCS_ARCHIVE_DIR 이 **실제로 있는 폴더**를 가리킨다" \
    || bad "REPAIR_DOCS_ARCHIVE_DIR 이 가리키는 폴더가 컨테이너 안에 없다"
  N_IN=$("$DOCKER" exec dss-as sh -c "ls -1 \"\$REPAIR_DOCS_ARCHIVE_DIR\" 2>/dev/null | wc -l" 2>/dev/null | tr -d ' ')
  say "    · 컨테이너가 보는 맨 위 칸: ${N_IN:-?}개"
  if [ "${N_IN:-0}" = 0 ]; then
    bad "🔴 컨테이너 안에서 **0개**다 — 빈 폴더가 붙었다. 경로의 대소문자를 보세요"
  else
    ok "컨테이너가 ${N_IN}개를 본다"
  fi
  # 🔴 역슬래시가 삼켜졌는가 — 16 · 18번이 이 검사로 잡았다.
  v=$("$DOCKER" exec dss-as printenv REPAIR_DOCS_ARCHIVE_UNC_ROOT 2>/dev/null)
  n=$(backslash_count "$v")
  [ "${n:-0}" -ge 4 ] \
    && ok "REPAIR_DOCS_ARCHIVE_UNC_ROOT 의 역슬래시가 ${n}개 — 삼켜지지 않았다" \
    || bad "REPAIR_DOCS_ARCHIVE_UNC_ROOT 의 역슬래시가 ${n:-0}개뿐이다 — 🔴 따옴표가 먹은 것이다"
  # 🔵 견적서 · 현황표 · 연락서도 그대로인지 한 번 더
  for k in QUOTE_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT \
           CONTACT_FOLDER_ARCHIVE_UNC_ROOT; do
    v=$("$DOCKER" exec dss-as printenv "$k" 2>/dev/null)
    [ -n "$v" ] && ok "$k 가 컨테이너 안에 그대로 있다" \
      || bad "$k 가 컨테이너 안에 **없다** — 🔴 그쪽 [폴더 열기]가 죽는다"
  done
else
  bad "dss-as 컨테이너가 떠 있지 않다 — 설정을 못 봤다"
fi

say "  7-ㄹ. 알림 통로 · 알림 링크의 주소 (A/S 만)"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 \
       "http://127.0.0.1:$AS_PORT/api/integration/notifications" 2>/dev/null)
case "$code" in
  404) bad "A/S 의 /api/integration/notifications 가 404 다 — **옛 이미지다**" ;;
  000|"") bad "A/S 의 알림 통로가 대답하지 않는다 (${code:-없음})" ;;
  *)   ok "A/S 의 알림 통로가 있다 (토큰 없이 부르면 401 이 맞다 — 지금 $code)" ;;
esac
notify_href_check "A/S" dss-as "$AS_ENV" "https://as.dss21.co.kr"

say "  7-ㅁ. 권한 — 교체 뒤에 다시 읽는다 (🔴 select 만)"
perm_check

# 7-ㅂ. 🔴 건드리지 않는 쪽이 **정말 안 멈췄는가** — 시작 시각으로 본다
say "  7-ㅂ. 🔴 건드리지 않는 쪽이 안 멈췄는가 (시작 시각을 대조한다)"
for t in $KEEP_BOXES; do
  before=$(printf '%s\n' "$STARTED_BEFORE" | sed -n "s/^$t=//p" | head -1)
  after=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  if [ -n "$before" ] && [ "$before" = "$after" ]; then
    ok "$t · 시작 시각 그대로 — **한 번도 안 멈췄다**"
  else
    bad "🔴 $t 의 시작 시각이 바뀌었다 ($before → $after) — 이 배포가 건드렸다"
  fi
done

say "  7-ㅅ. 바깥 주소 여섯"
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

# ══ 8. 마무리 ══════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · 약 ${DOWN}초"
echo "  🔴 마이그레이션 $N_MIG_HAVE → $N_MIG_WANT (더하기만 했습니다)"
echo "  적용 직전 덤프 · 첨부 스냅숏: $BK"
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

  이번 판은 도우미에 **루트를 하나 더했습니다** — 「1. 수리 관련」 아래를
  열 수 있게. 🔴 **옛 도우미는 새 루트의 주소를 받으면 조용히 아무 일도
  하지 않습니다.**
  🔵 이번 판부터는 **세대로 관리**합니다(dss.helper.gen1.openfile) — 다음
     판부터는 이미 새 도우미가 있는 PC 에 안내가 안 뜹니다. 🔴 **이번 한 번은
     모두 다시 설치해야 합니다.**

  받는 길 — 🔴 **반드시 A/S 화면에서**:
    A/S → 수리 건 상세 → [폴더 열기] → [설치 명령 복사]
      → PowerShell 창에 붙여넣기 (관리자 권한 필요 없음)

  🔴 **PO 화면에서 받으면 안 됩니다.** 도우미는 PC 당 **한 벌**이라
     PO 가 내준 설치본이 A/S 것을 덮어씁니다 — 그 PC 의 **고객사 현황표
     [폴더 열기]가 먹통이 됩니다.**

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. 🔴 **제품 종류 상세의 「공유폴더에서 가리킨 서류」** — 이번 판의 중심입니다.
      · [고르기]를 누르면 「1. 수리 관련」 **안이 한 칸씩** 보입니까.
      · 🔴 **이름으로 걸러** 보세요 — 두 창(종류·모델)이 같게 동작해야 맞습니다.
      · 고른 자리가 목록에 남고, 줄을 눌러 **탐색기로 열립니까.**
      · 🔴 **열 때 확인창이 뜨지 않아야** 맞습니다(도우미를 다시 설치한 PC 에서).
   2. 🔴 **제품 모델 상세**에도 같은 구역이 있습니다 — 같은 식으로 보세요.
   3. 🔴 **수리 건 상세 → 파일 관리** — 그 제품의 **종류 공통 서류**와
      **모델 서류**가 보입니까. 🔴 거기서는 **보고 열기만** 되어야 맞습니다
      (더하기·지우기 단추가 없어야 맞습니다).
   4. 🔴 **휴지통에서 영구 삭제** — 🔴 **되돌릴 수 없습니다.**
      · 시험용 파일을 하나 올려 지우고, 휴지통에서 영구 삭제해 보세요.
      · 🔴 목록에서 사라지고, **다시 되살릴 수 없어야** 맞습니다.
      · 🔵 한 주쯤은 $BK/as-attachments 에 하드링크가 남아 있습니다.
   5. **전체 A/S 현황**이 **인수번호 내림차순**으로 열립니까(접수일이 아니라).
   6. 🔴 **견적서 [폴더 열기] · 현황표 [폴더 열기] · 연락서 [폴더 열기]가
      그대로입니까** — 도우미를 다시 설치한 PC 에서 꼭 보세요. 넷이 한 벌에
      함께 심깁니다.
   7. 🔴 **연락서 폴더가 아직 만들어집니까** — 접수해 보세요. 이번에 붙인
      볼륨이 그 윗 폴더라 혹시 잠기지 않았는지 보는 것입니다
      (스크립트가 7-ㄴ 에서 이미 쓰기를 확인했습니다).
   8. 🔴 **포털 · 계측기 · 개선요청 · PO · 휴가가 그대로입니까** — 이번 판은
      그 다섯을 건드리지 않았습니다. (스크립트가 7-ㅂ 에서 시작 시각으로 이미
      확인했습니다.)

🔴 사람이 이어서 할 일:
  · **쓰는 분들에게 도우미 다시 설치를 알립니다**(위 상자).
  · 직원에게 알립니다 — 「제품 종류·모델이 공유폴더 서류를 가리킨다」 ·
    「휴지통에서 영구 삭제가 된다(되돌릴 수 없다)」.
  · 🔴 **「수리 관련」 폴더는 앱이 고치지 않습니다** — 며칠 뒤 그 폴더가
    그대로인지 한 번 보세요. 무엇이든 늘거나 바뀌었다면 알려 주세요.
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.
  · 내일 아침 백업을 한 번 더 보세요 — 다섯이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -7
  · 적용 직전 덤프와 첨부 스냅숏은 $BK 에 있습니다. 한 주쯤 두었다 지우세요.
  · as-migrations.old 도 한 주쯤 두었다 지웁니다.

되돌리기 안내:  bash $0 --rollback
  🔴 **DB 는 되돌리지 않습니다** — 칸 하나와 표 둘을 더하기만 했고, 2.1 은
     그것을 읽지도 쓰지도 않습니다.
  🔴 **영구 삭제한 첨부는 돌아오지 않습니다.**
ANNOUNCE
exit "$FAIL"
