#!/bin/bash
# /volume1/dss/setup/17-deploy.sh — 2026-10-05 열세째 배포
#
# ── 무엇이 올라가는가 ───────────────────────────────────────────────────
#   사내 사이트 여섯 중 **하나**만 올린다.
#
#     A/S  dss-as:1.9  →  **dss-as:2.0**
#
#   나머지 다섯(포털 1.5 · 계측기 1.3 · 개선요청 0.3 · PO 0.3 · 휴가 0.1)은
#   **건드리지 않는다. 멈추지도 않는다.**
#
#   16번과 같은 것 하나: **마이그레이션이 있다.** 다만 **하나**다(0111).
#   16번과 다른 것 셋:
#     · **새 볼륨이 없다.** compose 에서 바뀌는 것은 **태그 한 줄**뿐이다.
#     · 🔴 **as.env 를 한 글자도 고치지 않는다.** 새 환경변수가 없다.
#     · **도구 이미지를 다시 굽지 않았다**(dss-as-tools:1 그대로).
#
# ══ 🔴 as.env 의 함정 — 이번엔 「아예 건드리지 않는 것」으로 피한다 ══════
#
#   16번 머리말이 이렇게 적어 뒀다:
#     「이 PC(dss-deploy)의 nas/env/as.env 를 NAS 로 올리지 않는다. 절대로.
#      그 파일은 낡아서 NAS 에 있는 QUOTE_ARCHIVE_* 세 줄이 없다 — 올리면
#      그 셋이 운영에서 사라지고 견적서 [폴더 열기]가 죽는다.」
#
#   🔴 **이번 판에는 새 환경변수가 하나도 없다.** 그래서 이 스크립트는 as.env 를
#      **읽기만** 한다. 덧붙이지도, 고치지도, 올리지도 않는다. 함정 자체를
#      밟지 않는 것이 이번의 방식이다.
#      1-ㅁ 이 「있어야 할 여덟 줄이 그대로 있는가」만 본다(값은 안 찍는다).
#
#   ⚠️ 2.0 에서 **쓰이지 않게 된 줄이 하나** 생겼다 — CUSTOMER_LINK_TOKEN_KEY.
#      고객 전용 주소를 걷어내면서 그 키를 읽는 코드가 사라졌다.
#      🔴 **지우지 마라.** 앱이 안 읽을 뿐이고, 지우려고 as.env 를 건드리는 쪽이
#         훨씬 위험하다(위 함정). 그대로 두면 아무 일도 일어나지 않는다.
#
# ── 이 판에 무엇이 담겼나 (사람에게 설명할 말로) ────────────────────────
#
#   10/2 저녁부터 10/4 밤까지 쌓인 **커밋 9개**(c497085 ~ b2dfde8)다.
#   줄기는 넷이다.
#
#   ① **고객 전용 주소를 걷어냈다.**
#      고객사에 주소를 발급해 바깥 사이트에서 현황을 보게 하던 길이다.
#      🔵 **운영에서 한 번도 돈 적이 없다** — NAS 의 DSS_HOME_URL 이 주석 처리돼
#         있고 공개 사이트는 아직 배포되지 않았다. 그래서 직원이 잃는 기능이 없다.
#      「고객 안내 현황」은 이제 **고객사 양식 표 하나만** 보여 주고, 그 표가
#      **반출일 오름차순**으로 정렬된다.
#      🔴 곁들여 **「새 수리 의뢰」 알림을 누르면 404 가 되던 것**을 고쳤다 —
#         알림 종류째 없앴다(의뢰가 들어올 길이 없으니 그 알림도 없다).
#      🔵 그대로 남은 것: 줄마다 [저장] · 상태 목록 설정 · 권한 영역 customerPortal ·
#         **DB 의 표·칸·행 전부**. 그리고 **엑셀 내보내기 · 공유폴더 저장 ·
#         폴더 열기**(16번이 붙인 그 기능)도 그대로다 — 그래서 as.env 의
#         CUSTOMER_PORTAL_ARCHIVE_* 다섯 줄은 **계속 쓰인다.**
#
#   ② **엔지니어 누구나 「현재 단계 직접 변경」을 쓴다.**
#      전에는 「엔지니어일 뿐이면 자기가 담당인 건만」이었다. 그 조건을 풀었고
#      **변경 사유도 선택**이 됐다(화면 단추 · 서버 액션 · DB 쓰기 세 겹 전부).
#      🔴 그대로인 안전장치 넷 — 승인 안 된 계정 거부 · **역할 허용 목록**
#         (SUPER_ADMIN · ADMIN · AS_ENGINEER 셋 그대로. 영업·재고 담당자는
#          전과 같이 막힌다) · 보류 중 금지 · 출하 완료 잠금.
#      🔴 **이력은 사유가 비어도 남는다** — 누가 · 언제 · 어디서 어디로.
#
#   ③ **수리 진행 상태에 「수리 완료」가 생겼다**(「수리 중」 다음, 「출하 승인
#      대기」 앞). 이것이 마이그레이션 0111 이다.
#      그리고 **주간보고 상세표의 「현 상태」를 그 자리에서 바꿀 수 있다** —
#      고르면 그 칸에 해당하는 단계 중 **지금 단계에서 가장 가까운** 단계로
#      옮겨 간다. 저장은 기존 「단계 직접 변경」 길을 그대로 탄다
#      (권한도 이력도 그대로다 — 새 길을 내지 않았다).
#      🔴 **주간보고 집계는 6칸 그대로**이고 「수리 완료」는 **「수리 중」 숫자에
#         합산**된다. 숫자는 묶어 보고 줄은 사실대로 적는다(사용자 결정).
#
#   ④ **주간보고 잔손질** — 종류 고르개가 「RFG 만」→「RFG」로, 가로폭 슬라이더가
#      **1% 단위**로 움직이고 조절 바가 **오른쪽 위에 고정**된다
#      (전에는 끌면 트랙이 달아나 값이 튀었다).
#
#   🔴 **워크플로 편집은 이미 끝났다.** 주간보고가 「점검 대기 / 점검 중」을
#      **단계로** 가르게 바뀌었는데(전에는 「점검 기록이 있나」로 갈랐다),
#      사용자가 **운영 워크플로의 2번 단계 「인수점검」을 `인수점검 중` 으로 바꿔
#      발행해 두었다**(2026-10-04). 그래서 배포 전후로 주간보고 숫자가 흔들리지
#      않는다. 🔴 **이 스크립트는 워크플로를 건드리지 않는다.** 읽지도 않는다.
#
# ══ 🔴 마이그레이션 **하나** — 한 줄이고 더하기만 한다 ═════════════════
#
#   운영 DB(dss_as)는 지금 **111**, 적용하면 **112** 가 된다.
#
#     0111_eager_zaran.sql  (전문이 이 한 줄이다)
#       ALTER TYPE "public"."repair_status"
#         ADD VALUE 'REPAIR_COMPLETED' BEFORE 'WAITING_SHIPMENT_APPROVAL';
#
#   🔴 **표도 칸도 자료도 건드리지 않는다.** DROP · DELETE · TRUNCATE 가 없고
#      ALTER TABLE 도 없다. enum 에 값 하나를 끼워 넣을 뿐이다.
#      그래서 db:preflight 가 「사라질 자료」로 걸리지 않고 종료 코드 0 이다.
#
#   🔵 `repair_status` 를 쓰는 표는 **workflow_steps 하나뿐**이다
#      (vendor/dss-core/src/schema/workflow.ts:191). 그 칸에 새 값을 쓰는 행은
#      **아직 하나도 없다** — 쓰려면 사람이 워크플로 편집에서 그 단계를 골라
#      발행해야 하고, 그것은 2.0 이 뜬 뒤의 일이다.
#
#   🔵 PostgreSQL 12 부터 `ALTER TYPE … ADD VALUE` 는 트랜잭션 안에서 돈다
#      (같은 트랜잭션에서 **그 값을 쓰지만** 않으면 된다. 이 한 줄은 안 쓴다).
#      운영은 17.11 이고, 16번의 0106·0109 가 같은 꼴이었으며 그대로 통과했다.
#
#   🔴 A/S 의 drizzle/ 은 이미지 안이 아니라 **볼륨**이다
#      (compose 의 tools-as: /volume1/dss/as-migrations:/app/drizzle:ro).
#      그러니 .sql 하나만 넣어서는 안 되고 **meta/_journal.json 과
#      meta/0111_snapshot.json 까지 함께** 가야 한다. _journal.json 이 옛것이면
#      drizzle 은 새 .sql 을 **아예 모른다** — 조용히 0건 적용으로 끝나고, 그
#      다음에 뜬 2.0 이 없는 값을 쓰다 죽는다.
#      → 그래서 폴더를 통째로 갈아 끼운다(3-ㄷ · as-migrations.tar.gz).
#
# ══ 🔴 앱을 멈추지 않고 **먼저** 적용한다 (16번이 배운 것) ═════════════
#
#   README 「ㄷ」 — 16번은 1.8 이 살아 있는 채로 마이그레이션을 돌리고, 정지 창을
#   **이미지 교체 하나**로 뒀다. 정지가 18초에서 14초로 줄었다.
#
#   이번 판은 그 근거가 **더 세다.** 0111 은 enum 에 값 하나를 더할 뿐이고,
#   1.9 는 그 값을 **쓰지도 읽지도 않는다**(그 값을 가진 행이 없다).
#   그래서:
#     4~5) 마이그레이션을 **앱이 살아 있는 채로** 적용한다 (직원은 못 느낀다)
#       6) 그 다음에 이미지를 바꿔 끼운다 ⏱ 이것 하나가 정지 창이다 (약 20초)
#   얻는 것 둘:
#     · 정지 창이 짧다.
#     · 🔴 마이그레이션이 깨져도 **직원은 1.9 를 그대로 쓰고 있다.**
#
#   🔴 **차례(마이그레이션 → 코드)는 뒤집지 마라.** 먼저 띄우면 2.0 이 아직 없는
#      enum 값('REPAIR_COMPLETED')을 쓰려다 그 자리에서 죽는다. 그리고 둘 사이에
#      사람이 쉬어 가는 자리를 두지 않는다 — 한 흐름 안에 둔다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/17-deploy.sh            ← 읽기만 한다
#
#   🔴 NAS 의 docker 는 **sudo(root)** 가 필요하다. 이 스크립트는 root 가
#      아니면 첫 줄에서 멈춘다.
#
# ══ 🔴 개발 PC → NAS 로 올릴 것 **셋** ═════════════════════════════════
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#      아래는 **개발 PC 의 PowerShell** 에서 친다(NAS 가 아니다).
#      파일이 있는 자리는 C:\Users\희만\Desktop\Development 다.
#
#     scp -O dss-as-2.0.tar dss-nas:/volume1/dss/images/
#     scp -O as-migrations-2.0.tar.gz dss-nas:/volume1/dss/setup/incoming/as-migrations.tar.gz
#     scp -O docker-compose.nas.yml dss-nas:/volume1/dss/setup/incoming/
#
#   🔴 **두 번째 줄에서 이름이 바뀐다** — as-migrations-2.0.tar.gz 를
#      **as-migrations.tar.gz** 로 올린다. 이 스크립트가 그 이름으로 찾는다.
#   🔴 세 번째 줄의 compose 는 **dss-deploy 저장소의 nas/docker-compose.nas.yml**
#      이다(A/S 태그만 2.0 으로 올린 그 파일).
#   🔵 scp 가 바로 안 되면 사용자 계정(swhur)의 홈으로 올린 뒤 NAS 에서
#      `sudo mv` 로 옮긴다. /volume1/dss 아래는 root 만 쓸 수 있다.
#
# ══ 🔴 DSM 터미널은 긴 명령을 잘라 먹는다 ══════════════════════════════
#
#   하루에 네 번 깨진 적이 있다. **NAS 에서 돌릴 것은 스크립트 파일로 올리고
#   md5 를 맞춘 뒤** 실행한다. 이 파일 자체가 그렇다:
#
#     (PowerShell)  scp -O nas\setup\17-deploy.sh dss-nas:/volume1/dss/setup/
#     (PowerShell)  Get-FileHash -Algorithm MD5 nas\setup\17-deploy.sh
#     (NAS)         md5sum /volume1/dss/setup/17-deploy.sh
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
#      `db:preflight` 를 한 번 돌린다(tools-as 로 떴다 사라진다. DB 에는
#      select 만 간다). 디스크에도 DB 에도 아무것도 남기지 않고 도는 사이트를
#      건드리지도 않지만, 「아무것도 안 한다」가 아니라 「아무것도 **바꾸지**
#      않는다」가 정확한 말이다. 13·15·16번 머리말의 그 문장을 그대로 잇는다.
#
# ── 모드 다섯 ───────────────────────────────────────────────────────────
#   (없음) · --check     읽기만 한다. 아무것도 안 바꾸고 안 멈춘다      ← 기본값
#   --preload            새 이미지 하나를 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --go                 🔴 **A/S 하나만** 교체 + 마이그레이션 0111 적용
#   --rollback           태그 되돌리기 안내
#
#   `--force-load` 는 `--go` 와 같이 써도 된다:  bash 17-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 17-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 17-deploy.sh --preload       (새 이미지를 미리 실어 둔다)
#   3) bash 17-deploy.sh                 (다시 읽기만 — 이번엔 지문까지 다 본다)
#   4) bash 17-deploy.sh --go            (마이그레이션 + A/S 교체)
#
# ══ 🔴 ⑤ README 가 남긴 숙제 — 「아직 안 온 것」을 ✗ 로 세지 않는다 ════
#
#   README 「ㄷ」(2026-09-30): 15-deploy.sh 는 이미지를 싣기 **전에** 첫 --check 를
#   돌리면 **실패 1** 로 끝났다. 같은 상황을 한 자리(1-ㅊ)는 `✗` 로, 다른
#   자리(1-ㄴ)는 「아직 없다 — --preload 가 싣는다」로 안내만 해서 **판정이
#   엇갈렸다.** 배포를 막지는 않았지만 사람을 놀라게 한다.
#
#   🔴 17번의 규칙은 한 줄이다:
#
#       **--check 가 ✗ 로 세는 것은 「있는데 어긋난 것」뿐이다.**
#       「아직 안 온 것 · 아직 안 실린 것」은 ⚠️ 로 안내만 한다.
#
#   구체적으로 --check 에서 ⚠️(안내)로 끝나는 자리 셋:
#     · $TAR_AS 가 아직 NAS 에 없다            → ⚠️ 「먼저 scp -O 로 올리세요」
#     · $TAG_AS 가 아직 docker load 안 됐다    → ⚠️ 「--preload 가 싣는다」
#     · 그래서 이미지 **안**을 못 봤다(1-ㅋ)   → ⚠️ 「--preload 뒤에 다시」
#   그리고 ✗ 로 세는 자리:
#     · tar 는 있는데 **바이트·md5·지문이 어긋난다**  → ✗ (옮기다 깨졌다)
#     · 이미지가 **실려 있는데 지문이 tar 와 다르다** → ✗ (--force-load 가 필요)
#     · 이미지 **안에 이번 판의 표시가 없다**         → ✗ (옛 판을 올린 것)
#
#   🔴 모드에 따라 갈리는 것은 **tar · 묶음**뿐이다(notyet). --preload · --go 는
#      그것이 **있어야** 도는 모드라 없으면 ✗ 고, --go 는 거기서 멈춘다
#      (앱은 살아 있다).
#   🔴 **「아직 안 실린 이미지」는 어느 모드에서도 ✗ 가 아니다**(notloaded).
#      --preload 와 --go 는 2단계에서 **스스로 싣기** 때문이다. 여기서 ✗ 를
#      세면 --go 가 싣기도 전에 자기 검사에 막혀 배포가 아예 불가능해진다 —
#      16번의 첫 판이 새 볼륨 검사에서 똑같이 당했다(머리말 ⑩).
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
# ══ 15 · 16번에서 그대로 이어받는 것 ═══════════════════════════════════
#
#   ① 같은 태그로 다시 구운 이미지는 조용히 안 실린다 → --force-load
#   ② 폴더 권한은 **컨테이너 안에서 실제로 열어 본다**(ls -ld 로는 모른다)
#   ③ 이미지는 태그가 아니라 **안을 본다**(1-ㅋ)
#   ④ 사람이 칠 명령은 **한 줄 76자 안쪽**(DSM 의 ash 가 긴 줄을 자른다)
#   ⑤ 공유폴더는 **chmod 로 ACL 을 걷으면 안 된다** — 직원의 탐색기가 끊긴다
#   ⑥ `docker ps` 에 보이는 것과 앱이 **대답하는** 것은 다르다 → wait_http
#   ⑦ compose 는 바꾸기 **전에** 시험하고, 바꾼 것은 backups/ 에 남긴다
#   ⑧ 알림 링크가 **밖에서 닿는 주소**로 나오는가(1-ㅊ · 7-ㄹ)
#   ⑨ 🔴 **권한은 코드가 아니라 운영 DB 가 정한다** — role_permissions 를
#      읽어 보고 말한다(1-ㄷ). 🔴 **select 만 쓴다.**
#
#   ⑩ 🔴 **「새로 붙는 볼륨」을 도는 컨테이너에서 찾으면 안 된다**
#      (README 「ㄴ」 · 2026-10-02). 16번의 첫 판이 --check 에서
#      /customer-portal-archive 를 **도는 컨테이너**(옛 compose 의 1.8)에서
#      찾아 EACCES 로 ✗ 를 냈다. 그 자리는 새 compose 를 적용해야 생기니
#      **있을 수가 없었다.** --go 도 검사를 먼저 다 돌리고 ✗ 가 있으면 멈추므로
#      **배포 자체가 불가능했다.** 더 나빴던 것은 그때 뜬 안내다 —
#      「ACL 을 걷어라(chown·chmod)」. 직원이 쓰는 공유폴더에 그러면 탐색기
#      접근이 끊긴다. 고친 방법은 **임시 컨테이너를 띄워** 호스트 경로를
#      :ro 로 붙여 보는 것이었다.
#      🔵 **이번 판에는 새로 붙는 볼륨이 없어 그 검사가 돌 자리가 없다.**
#         그래도 이 교훈은 지운다고 사라지지 않는다 — 다음에 볼륨이 하나라도
#         늘면 **반드시** 16-deploy.sh 의 probe_new_volume() 을 다시 가져올 것.
#
# ── 참고 · 개발 PC 에서 잰 값 (2026-10-05 실측) ────────────────────────
#
#   이미지 dss-as:2.0   — 582MB (`docker images` 기준. 1.9 는 581MB)
#   tar  dss-as-2.0.tar — 129,669,120 바이트 (약 124MB)
#                          md5 9ff848af82be9df78073bb043828e0f5
#                          tar 안 Config 지문
#                            sha256:cdd1534e3bd8825ef34291cd8757fa0e7ac2da00…
#   🔴 **이미지 크기(582MB)와 tar 크기(124MB)는 다른 수치다. 섞지 마라.**
#
#   묶음 as-migrations-2.0.tar.gz — 2,042,289 바이트
#                          md5 b56ab4f2df21bbe8666894f8316830a4
#                          안에 .sql **112개**(0111_eager_zaran.sql 포함) ·
#                          meta/*_snapshot.json 112개
#
#   🔴 **Config 지문이 가장 중요한 값이다.** NAS 는 tar 안의 config 지문을
#      이미지 ID 로 낸다. 개발 PC 의
#        docker image inspect --format '{{.Id}}'
#      값이 **아니다** — 그쪽은 manifest list 지문이라 다르다
#      (이 판의 실제 값: 개발 PC 554e8528… ↔ tar 안 cdd1534e…).
#      그래서 tar_config_id() 가 **tar 에서 직접 읽고**, 그 값이 아래
#      WANT_CFG_AS 와 같은지까지 본다. 어긋나면 옮기다 깨진 것이다.
#      🔵 빌드 로그의 `exporting config sha256:cdd1534e…` 와도 일치를 확인했다.
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
TAG_AS=dss-as:2.0
OLD_AS=dss-as:1.9

# ── 🔴 **건드리지 않는 아홉.** 16번과 같은 아홉이다 ────────────────────
KEEP_AUTH=dss-auth:1.5
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_METERSTOOLS=dss-meters-tools:1
KEEP_IMP=dss-improvements:0.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_PO=dss-po:0.3
KEEP_LEAVE=dss-leave:0.1
KEEP_LEAVETOOLS=dss-leave-tools:1

# ── tar 하나 — 🔴 2026-10-05 개발 PC 에서 **실측한 값**이다 ────────────
TAR_AS=$IMAGES/dss-as-2.0.tar
SZ_AS="129669120"
MD5_AS="9ff848af82be9df78073bb043828e0f5"
# 🔴 tar 안 manifest.json 의 "Config" 에서 뽑은 지문. NAS 에 실리면 이 값이
#    그대로 image ID 가 된다. 개발 PC 의 {{.Id}}(554e8528…)가 아니다.
WANT_CFG_AS="sha256:cdd1534e3bd8825ef34291cd8757fa0e7ac2da00fdacf848ae63bfa9e1ff3c78"

# ── 포트 (compose 의 ports: 에서 읽어 확인했다 — 짐작이 아니다) ────────
#   포털 13100 · A/S 13000 · 계측기 13300 · 개선요청 13500 ·
#   PO 13600 · 휴가 13700
AS_PORT=13000

# ── 마이그레이션 — 🔴 **하나다**(0111) ────────────────────────────────
AS_DB=dss_as
N_MIG_HAVE=111                 # 지금 운영에 적용돼 있는 수
N_MIG_WANT=112                 # 적용 뒤 수
MIGDIR=$D/as-migrations        # compose 가 tools-as 의 /app/drizzle 로 붙인다
MIGTAR=$D/setup/incoming/as-migrations.tar.gz
SZ_MIG="2042289"
MD5_MIG="b56ab4f2df21bbe8666894f8316830a4"
NEW_MIGS="0111"
AS_TOOLS_SVC=tools-as

# ── 0111 이 실제로 들어갔는지 보는 값 (5단계) ──────────────────────────
ENUM_TYPE=repair_status
ENUM_NEW=REPAIR_COMPLETED
ENUM_AFTER=WAITING_SHIPMENT_APPROVAL   # 새 값은 **이것 바로 앞**에 들어간다

# ── 권한 — 🔴 읽기만 한다. 출처는 전부 소스다 (1-ㄷ) ──────────────────
#   표·칸   vendor/dss-core/src/schema/role-permissions.ts
#           (표 role_permissions · 칸 role · area_key · level · updated_at.
#            🔴 칸 이름은 leaf_key 가 아니라 **area_key** 다 — 이름이 낡았다)
#   이번 판 src/lib/domain/local/workflow/permissions.ts:207
#           checkManualStepSetEligibility — 승인 계정 → **역할 허용 목록** →
#           보류. 🔴 role_permissions 를 **한 번도 읽지 않는다.**
PERM_TABLE=role_permissions
PERM_ROLES="SUPER_ADMIN ADMIN AS_ENGINEER"

# ── 컨테이너 안에서 실제로 열어 볼 폴더 ────────────────────────────────
ATT=$D/as-attachments
TEMPLATES=$D/as-templates
UP_IMP=$D/improvements-uploads
MF_METERS=$D/meters-files
# 🔵 16번이 붙인 현황표 공유폴더. **이번에 새로 붙는 것이 아니다** — 이미
#    도는 1.9 에 붙어 있다. 여기서는 「사라지지 않았는가」만 본다.
PORTAL_MNT=/customer-portal-archive

# ── 이미지 **안에서** 찾을 글자 (1-ㅋ) ─────────────────────────────────
# 🔴 태그와 지문이 맞아도 「무엇이 든 판인지」는 안을 봐야 안다. 9/21~9/29 에
#    A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다.
#
# 🔵 이번에는 **글자가 아니라 모듈 경로**로 본다. Next 의 서버 번들은 webpack
#    모듈 이름으로 소스 경로를 그대로 품고 있어, 파일이 **생겼는지 없어졌는지**를
#    한글 문구보다 또렷하게 가른다(한글은 유니코드 이스케이프로 바뀌어 있을 때가
#    있다 — 16번이 그 함정을 적어 뒀다).
#
# 🔴 네 값 모두 2026-10-05 에 **두 이미지 안에서 실측**했다:
#                                     dss-as:2.0   dss-as:1.9
#      weekly-report-row-status.ts        있다        없다
#      WeeklyReportStatusCell.tsx         있다        없다
#      customer-portal-sync.ts            없다        있다     ← 걷어낸 파일
#      .next/server 안 REPAIR_COMPLETED   20개        0개
#    즉 **네 자리가 전부 뒤집힌다.** 1.9 를 잘못 올리면 네 줄이 모두 어긋난다.
AS_MARK1="src/lib/domain/weekly-report-row-status.ts"
AS_MARK2="src/components/dashboard/WeeklyReportStatusCell.tsx"
AS_GONE="src/lib/server/services/customer-portal-sync.ts"
AS_CTRL="SSO_REDIRECT_URI"    # 두 판에 다 있는 대조 표시 (2.0 에서 6개 파일)
AS_ENUM_FILES=20              # .next/server 안 REPAIR_COMPLETED 가 든 파일 수

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 셋. 인자가 없으면 이 셋 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
PROBE_WRITE=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 17-deploy.sh                  읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 17-deploy.sh --check          위와 같습니다
  bash 17-deploy.sh --preload        새 이미지를 싣고 지문만 맞춥니다
  bash 17-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 17-deploy.sh --go             🔴 마이그레이션 0111 + A/S 교체
  bash 17-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 17-deploy.sh --rollback       되돌리기 안내

  🔴 --go 가 멈추는 것은 **dss-as 하나**입니다.
     포털 · 계측기 · 개선요청 · PO · 휴가 · DB 는 그대로 돕니다.
  🔴 --go 는 **DB 를 바꿉니다** — 마이그레이션 0111 하나.
     표도 칸도 자료도 안 건드리지만, 그날 백업이 없으면 거기서 멈춥니다.
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
LOG="$D/setup/logs/17-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11 · 12 · 13 · 15 · 16-deploy.sh 의 것을 그대로 쓴다 ──────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""; DOWN=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# 🔴 머리말 ⑤ — 「아직 안 온 것」은 --check 에서 ✗ 가 아니다.
#    --preload · --go 는 그 셋이 **있어야** 도는 모드라 ✗ 로 센다.
missing_is_fatal() { [ "$MODE" != check ]; }
# 「아직 안 **온** 것」 — tar · 묶음처럼 사람이 올려야 하는 것.
#   --check 에서는 ⚠️ , --preload · --go 에서는 ✗ (그 모드는 그것이 있어야 돈다).
notyet() { # 1 할 말
  if missing_is_fatal; then bad "$1"; else echo "    ⚠️ $1"; fi
}
# 「아직 안 **실린** 것」 — docker load 가 안 된 이미지.
#   🔴 **어느 모드에서도 ✗ 가 아니다.** --preload 와 --go 는 2단계에서 **스스로
#      싣는다** — 여기서 ✗ 를 세면 --go 가 싣기도 전에 자기 검사에 막힌다.
#      (16번이 1-ㅋ 에서 say 로만 적은 것이 바로 이 까닭이다.)
notloaded() { # 1 할 말
  echo "    ⚠️ $1"
}

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
#  이 스크립트가 DB 를 바꾸는 자리는 **5단계의 `npm run db:migrate` 한 줄**뿐이다.
#  거기서 도는 SQL 은 drizzle 이 0111 파일에서 읽는 그 한 줄이고, 이 스크립트가
#  직접 적는 SQL 은 **전부 select** 다. role_permissions 는 읽기만 한다.
#  🔴 workflow_templates · workflow_steps 는 **읽지도 않는다** — 워크플로는
#     사용자가 이미 화면에서 발행해 뒀고, 스크립트가 손댈 자리가 없다.
# ══════════════════════════════════════════════════════════════════════
qas()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -Atc \"$1\"" 2>/dev/null; }
qqas() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -c   \"$1\"" 2>/dev/null; }

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 개발 PC 의 `docker image inspect --format {{.Id}}` 가 아니라 **이 값**이
#    NAS 에 실렸을 때의 image ID 가 된다(11-deploy.sh 머리말의 그 까닭).
#    16번의 함수를 **한 글자도 안 고치고** 가져왔다.
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
#  PATHS 는 "경로:모드" 를 빈칸으로 나열한 것이다.
#    ro   읽기만
#    rw   읽기 + 파일 쓰기
#    rwd  읽기 + 파일 쓰기 + **폴더 만들기**
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
#
#  🔵 이번 판이 **알림 종류 하나**(「새 수리 의뢰」)를 없앴다. 통로 자체와 주소
#     계산은 그대로다 — 그러니 이 검사의 기대값도 그대로다.
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
#  이미지 **안에** 이번 판이 들어 있는가 — 네 자리를 한 번에 본다
#
#  🔴 「아직 안 실린 것」은 ✗ 가 아니다(머리말 ⑤). 못 봤다고 말하고 넘어간다.
#  🔴 대조 표시(AS_CTRL)가 안 나오면 **판정하지 않는다** — 글자를 못 읽은 것과
#     옛 판인 것을 가를 수 없기 때문이다.
# ══════════════════════════════════════════════════════════════════════
inside_check() { # 1 이미지태그
  local tag="$1" out m1 m2 g c n
  if ! have_img "$tag"; then
    notloaded "$tag 가 아직 NAS 에 없어 **안을 못 봤다** — 먼저 실으세요"
    cmd "bash $0 --preload"
    return 0
  fi
  out=$("$DOCKER" run --rm -e M1="$AS_MARK1" -e M2="$AS_MARK2" \
        -e G="$AS_GONE" -e C="$AS_CTRL" --entrypoint sh "$tag" -c '
    m1=0; m2=0; g=0; c=0
    grep -rlF -- "$M1" /app/.next >/dev/null 2>&1 && m1=1
    grep -rlF -- "$M2" /app/.next >/dev/null 2>&1 && m2=1
    grep -rlF -- "$G"  /app/.next >/dev/null 2>&1 && g=1
    grep -rlF -- "$C"  /app/.next >/dev/null 2>&1 && c=1
    n=$(grep -rlF -- REPAIR_COMPLETED /app/.next/server 2>/dev/null | wc -l)
    echo "INSIDE $m1 $m2 $g $c $n"' 2>/dev/null | grep '^INSIDE ' | head -1)
  m1=$(printf '%s' "$out" | awk '{print $2}')
  m2=$(printf '%s' "$out" | awk '{print $3}')
  g=$(printf  '%s' "$out" | awk '{print $4}')
  c=$(printf  '%s' "$out" | awk '{print $5}')
  n=$(printf  '%s' "$out" | awk '{print $6}')
  if [ "${c:-0}" != 1 ]; then
    say "    ⚠️ $tag 안을 글자로 뒤지지 못했다 — 대조 표시($AS_CTRL)도 안 나왔다."
    say "       **판정하지 않는다.** 🔴 이때는 사람이 직접 화면에서 봐야 한다."
    return 0
  fi
  ok "대조 표시($AS_CTRL)를 찾았다 — 안을 실제로 읽었다는 뜻이다"
  [ "${m1:-0}" = 1 ] && ok "주간보고 상세표 상태 함수가 들어 있다 ($AS_MARK1)" \
    || bad "🔴 $AS_MARK1 가 **없다** — 이것은 1.9 다. 다시 구워 올리세요"
  [ "${m2:-0}" = 1 ] && ok "주간보고 「현 상태」 고르개가 들어 있다 ($AS_MARK2)" \
    || bad "🔴 $AS_MARK2 가 **없다** — 이것은 1.9 다. 다시 구워 올리세요"
  [ "${g:-0}" = 0 ] && ok "고객 전용 주소 동기화가 **걷혔다** ($AS_GONE 없음)" \
    || bad "🔴 $AS_GONE 가 아직 **있다** — 이것은 1.9 다"
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then
    ok ".next/server 안에 $ENUM_NEW 가 든 파일 ${n}개"
    [ "${n:-0}" = "$AS_ENUM_FILES" ] \
      || say "    ⚠️ 개발 PC 에서는 ${AS_ENUM_FILES}개였다 — 빌드가 조금 다를 수 있다(✗ 아님)"
  else
    bad "🔴 .next/server 안에 $ENUM_NEW 가 **한 파일도 없다** — 이것은 1.9 다"
  fi
}

# ── 🔴 이미지 안에 글자 인식기(public/ocr)가 들어 있는가 ───────────────
# 🔴 Next 의 standalone 은 public 을 **자동으로 담지 않는다.** Dockerfile 이
#    따로 COPY 하는데, 그 줄이 어긋나면 화면은 뜨고 명판 읽기만 죽는다 —
#    그것도 오류 없이 「인식기를 불러오지 못했습니다」 하나로.
# 🔵 이번 판이 더한 기능은 아니다. **1.9 에서 들어온 것이 2.0 에도 그대로
#    있는지** 보는 회귀 검사다(2026-10-05 실측 6912KB).
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
#  【왜 이 자리가 있는가】
#  「권한은 코드가 아니라 운영 DB 가 정한다」 — 2026-09-30 에 role_permissions 에
#  저장된 값이 코드의 기본 정책을 이겨서 「셋이 열린다」가 「하나만 열렸다」로
#  밝혀졌다. 그래서 권한이 걸린 배포에서는 **운영 DB 를 읽어 보고 말한다.**
#
#  【그런데 이번 판은 다르다 — 그것이 이 검사의 결론이다】
#  🔴 「현재 단계 직접 변경」은 role_permissions 를 **한 번도 읽지 않는다.**
#     판정은 코드 세 걸음뿐이다
#     (src/lib/domain/local/workflow/permissions.ts:207 checkManualStepSetEligibility):
#       ㄱ) 승인된 계정인가
#       ㄴ) 역할이 SUPER_ADMIN · ADMIN · AS_ENGINEER 셋 중 하나인가
#       ㄷ) 보류 중이 아닌가
#     그래서 **DB 에 저장된 값이 이 기능을 막을 자리가 없다.** 16번처럼
#     「저장된 값이 기본 정책을 이겨 안 열린다」가 **이번엔 일어나지 않는다.**
#
#  그래도 운영 DB 를 읽어 **보여는 준다.** 두 가지 때문이다:
#    · 읽어 보지 않고 「막을 자리가 없다」고 말하면 그것은 또 코드만 읽은 말이다.
#    · repairCases* 에 예상 못 한 줄이 생겼으면 그 자체가 신호다.
#  🔴 이 검사는 ✗ 를 세지 않는다. 배포의 흠이 아니라 설정이다.
# ══════════════════════════════════════════════════════════════════════
PERM_SQL_COUNT="select count(*) from $PERM_TABLE"
PERM_SQL_ALL="select role, area_key, level, updated_at::date from $PERM_TABLE where area_key like 'repairCases%' order by area_key, role"

perm_check() {
  local reg n_all
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
  say "      $PERM_SQL_ALL"
  say
  n_all=$(qas "$PERM_SQL_COUNT")
  say "  · $PERM_TABLE 전체 줄: ${n_all:-?}  (0 이면 전부 코드의 기본 정책대로다)"
  say
  say "  전체 A/S 현황(repairCases*)에 저장된 값 — 역할 전부:"
  qqas "$PERM_SQL_ALL" | sed 's/^/      /'
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ ✅ 이 배포로 **엔지니어 누구나** 현재 단계를 직접 바꿉니다.     ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     🔴 위 표에 무엇이 저장돼 있든 **이 기능은 막히지 않습니다.**"
  say "        판정이 role_permissions 를 읽지 않기 때문입니다 — 보는 것은"
  say "        승인 계정 · 역할($PERM_ROLES) · 보류 셋뿐입니다."
  say "     🔴 그래서 **영업 담당자 · 재고 담당자는 전과 같이 막힙니다.**"
  say "        그 둘이 열렸다면 그건 이 배포가 아니라 다른 변경입니다."
  say "     🔵 변경 사유는 선택이 됐지만 **이력은 사유가 비어도 남습니다** —"
  say "        누가 · 언제 · 어디서 어디로."
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)
EXP_AS=""
MIG_PLACED=0   # as-migrations 폴더가 이미 112 이면 1
SVCS=""
AS_DBURL=""; PO_DBURL=""

see_tar() { # 1 태그 2 tar 3 tar에서읽은지문 4 기대바이트 5 기대md5 6 기대지문
  local n m
  if [ ! -s "$2" ]; then
    notyet "$1 의 tar 가 아직 NAS 에 없다: $2"
    say "    → 개발 PC(PowerShell)에서 올리세요. 🔴 scp 에 -O 를 붙입니다:"
    say "      (NAS 가 아니라 **개발 PC 의 PowerShell** 에서 칩니다)"
    say "      scp -O dss-as-2.0.tar dss-nas:/volume1/dss/images/"
    return 1
  fi
  n=$(stat -c '%s' "$2" 2>/dev/null)
  m=$(md5sum "$2" 2>/dev/null | awk '{print $1}')
  [ "$n" = "$4" ] && ok "$1 · 바이트 $n" \
    || bad "$1 의 바이트가 $4 가 아니다 ($n) — 옮기다 끊겼다"
  [ "$m" = "$5" ] && ok "$1 · md5 $m" \
    || bad "$1 의 md5 가 $5 가 아니다 (${m:-못 읽음}) — 파일이 상했다"
  if [ -z "$3" ]; then
    bad "$1 의 tar 에서 manifest.json 을 읽지 못했다: $2"
    return 1
  fi
  if [ "$3" = "$6" ]; then
    ok "$1 · tar 안 Config 지문이 기대값과 같다 ($(echo "$3" | cut -c1-19)…)"
  else
    bad "$1 · tar 안 Config 지문이 기대값과 다르다"
    say "      tar   $3"
    say "      기대  $6"
    say "      🔴 **다른 판을 올린 것**이거나 옮기다 깨진 것이다."
  fi
}

# ── 마이그레이션 묶음 tar — 바이트·md5 를 대조한다 ─────────────────────
# 🔵 사람이 다시 묶으면 gzip 의 도장 때문에 md5 가 달라질 수 있다. 그래서
#    여기서 어긋나는 것은 ⚠️ 로만 말하고, **진짜 판정은 푼 뒤의 개수**로 한다
#    (3-ㄷ 가 .sql 112개 · _journal tag 112줄 · 0111 을 직접 센다).
see_migtar() {
  local n m
  [ -s "$MIGTAR" ] || return 0
  n=$(stat -c '%s' "$MIGTAR" 2>/dev/null)
  m=$(md5sum "$MIGTAR" 2>/dev/null | awk '{print $1}')
  if [ "$n" = "$SZ_MIG" ] && [ "$m" = "$MD5_MIG" ]; then
    ok "마이그레이션 묶음 · 바이트 $n · md5 $m (개발 PC 와 같다)"
  else
    say "    ⚠️ 마이그레이션 묶음이 개발 PC 에서 잰 값과 다르다 (✗ 는 아니다)"
    say "       지금  바이트 ${n:-?} · md5 ${m:-?}"
    say "       기대  바이트 $SZ_MIG · md5 $MD5_MIG"
    say "       다시 묶으면 달라질 수 있다. 🔴 진짜 판정은 **푼 뒤의 개수**다."
  fi
}

run_checks() {
  local tag s p rec t n_sql n_j n_db f db n_bk nlog k miss n_snap rc
  local FREE_KB FREE_H code h

  # ── 1-ㄱ. 올릴 파일 둘 — 크기 · md5 · tar 안의 지문 ──────────────────
  step "1-ㄱ. 올린 파일 둘 (이미지 tar · 마이그레이션 묶음)"
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS" "$SZ_AS" "$MD5_AS" "$WANT_CFG_AS"
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
  step "1-ㄷ. 「현재 단계 직접 변경」이 **진짜로** 열리는가 (운영 DB 를 읽는다)"
  say "  🔴 「권한은 코드가 아니라 운영 DB 가 정한다」 — 그래서 읽어 보고 말한다."
  say "     🔵 다만 이번 기능은 role_permissions 를 **읽지 않는 판정**이다."
  perm_check

  # ── 1-ㄹ. 🔴 마이그레이션 하나 (111 → 112) ───────────────────────────
  step "1-ㄹ. 마이그레이션 0111 ($N_MIG_HAVE → $N_MIG_WANT)"
  say "  🔴 A/S 의 drizzle/ 은 이미지가 아니라 **볼륨**이다:"
  say "     $MIGDIR → tools-as 의 /app/drizzle (읽기 전용)"
  say "  그래서 .sql 하나만이 아니라 **meta/_journal.json 과 0111_snapshot.json 까지**"
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
        say "      scp -O as-migrations-2.0.tar.gz \\"
        say "        dss-nas:/volume1/dss/setup/incoming/as-migrations.tar.gz"
        say "    🔴 .sql 하나만 넣지 마세요 — meta/_journal.json 이 빠지면"
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
        ok "0111 의 .sql 과 meta/0111_snapshot.json 이 있다"
      else
        bad "빠진 것이 있다:$miss"
      fi
      n_snap=$(ls -1 "$MIGDIR"/meta/*_snapshot.json 2>/dev/null | wc -l | tr -d ' ')
      say "  · meta/*_snapshot.json: ${n_snap}개"
      # 🔴 0111 이 **진짜 그 한 줄인지** 본다 — 이름만 맞고 속이 다를 수 있다.
      f=$(ls -1 "$MIGDIR/0111_"*.sql 2>/dev/null | head -1)
      if [ -n "$f" ]; then
        grep -q "ADD VALUE '$ENUM_NEW'" "$f" \
          && ok "0111 안에 ADD VALUE '$ENUM_NEW' 가 있다" \
          || bad "0111 안에 ADD VALUE '$ENUM_NEW' 가 **없다** — 🔴 다른 파일이다"
        grep -qiE 'DROP|DELETE|TRUNCATE' "$f" \
          && bad "🔴 0111 에 **지우는 문장**이 있다 — 이번 판에는 없어야 한다" \
          || ok "0111 에 DROP · DELETE · TRUNCATE 가 없다 (더하기만 한다)"
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
        "$N_MIG_HAVE") ok "적용 전 상태가 맞다 ($N_MIG_HAVE) — --go 가 0111 을 적용한다" ;;
        "$N_MIG_WANT") ok "**이미 $N_MIG_WANT 다** — 적용이 끝난 DB 다(두 번 돌려도 안전하다)" ;;
        *) bad "적용된 줄이 $N_MIG_HAVE 도 $N_MIG_WANT 도 아니다 (${n_db:-?})"
           say "    → 🔴 **이것이 신호다.** 남의 변경이 섞였거나 누가 손으로 적용한 것이다."
           say "      고치지 말고 **먼저 알리세요.**" ;;
      esac
      # 🔴 지금 enum 이 어떤 꼴인지 적어 둔다 — 적용 뒤에 이것과 견준다.
      say "  · 지금 $ENUM_TYPE 의 값 차례 (적용 전):"
      qas "select e.enumlabel from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = '$ENUM_TYPE' order by e.enumsortorder" \
        | tr '\n' ' ' | sed 's/^/      /'
      echo
      if [ -n "$(qas "select 1 from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = '$ENUM_TYPE' and e.enumlabel = '$ENUM_NEW'")" ]; then
        ok "$ENUM_NEW 가 **이미 들어 있다** — 적용이 끝난 DB 다"
      else
        say "    🔵 $ENUM_NEW 는 아직 없다 — --go 가 넣는다(맞는 상태다)"
      fi
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
    say "      (종료 코드 $rc — 🔴 0111 은 **지우는 문장이 없어** 0 이 맞다)"
    say "      🔵 기대: 폴더가 아직 $N_MIG_HAVE 이면 「대기 0건」, 갈아 끼운 뒤면 「대기 1건」."
  else
    bad "compose 에 $AS_TOOLS_SVC 가 없다 — 마이그레이션을 돌릴 수 없다"
  fi

  # ── 1-ㅁ. 🔴 as.env — **읽기만 한다. 이번엔 고치지 않는다** ──────────
  step "1-ㅁ. as.env (🔴 이번 배포는 **한 글자도 고치지 않는다**. 읽기만 한다)"
  say "  🔴 이 PC(dss-deploy)의 nas/env/as.env 를 NAS 로 **올리지 마세요.**"
  say "     그 사본에는 NAS 에만 있는 줄들이 빠져 있습니다 — 올리면 그 기능이"
  say "     운영에서 사라집니다(16번 머리말의 그 함정). 이번엔 **안 건드립니다.**"
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
    for k in QUOTE_ARCHIVE_DIR QUOTE_ARCHIVE_UNC_ROOT QUOTE_ARCHIVE_UNC_ROOT_ALT; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 누가 as.env 를 덮어썼다. 배포보다 이것이 먼저다"
    done
    say "  🔴 현황표 다섯 줄 — 16번이 넣은 것이고 **2.0 도 그대로 쓴다**:"
    for k in CUSTOMER_PORTAL_ARCHIVE_DIR CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT \
             CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT CUSTOMER_PORTAL_ARCHIVE_FOLDER_PATH \
             CUSTOMER_PORTAL_ARCHIVE_UNC_PATH; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 [공유폴더에 저장]이 실패로 끝난다"
    done
    if grep -q "^CUSTOMER_LINK_TOKEN_KEY=" "$AS_ENV"; then
      say "  ⚠️ CUSTOMER_LINK_TOKEN_KEY 가 아직 있다 — 2.0 은 이 줄을 **안 읽는다.**"
      say "     🔴 **지우지 마세요.** 그대로 둬도 아무 일도 일어나지 않습니다."
    fi
    say "  🔵 이번 배포가 as.env 에 더하는 줄: **없음.** 새 환경변수가 없습니다."
  else
    bad "as.env 가 없다: $AS_ENV"
    say "    → 없는 env_file 하나면 docker compose 명령이 **통째로** 안 먹는다."
  fi
  for f in po.env auth.env meters.env improvements.env leave.env; do
    [ -f "$ENVD/$f" ] || bad "$f 가 없다: $ENVD/$f (compose 가 통째로 실패한다)"
  done

  # ── 1-ㅂ. compose — 🔴 바뀌는 것은 **태그 한 줄**뿐이다 ──────────────
  step "1-ㅂ. compose ($CF_EFF)"
  say "  🔴 이번 판에서 compose 가 바뀌는 자리는 **app-as 의 image 한 줄**뿐이다."
  say "     볼륨도 환경 파일도 포트도 그대로다. 다른 것이 흔들렸으면 남의 것이다."
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
    say "    🔴 compose 가 아직 **옛 태그**($OLD_AS)를 가리킵니다. 고치는 길 둘:"
    say "      ㄱ) 개발 PC 에서 고친 compose 를 아래에 올린다(권장):"
    say "           /volume1/dss/setup/incoming/docker-compose.nas.yml"
    say "         --go 가 그 파일을 시험하고 제자리로 옮깁니다."
    say "      ㄴ) 손으로 고친다 — 🔴 이번엔 **태그 한 줄뿐**이라 이 길도 안전합니다:"
    cmd "cd /volume1/dss/deploy"
    cmd "sed -i 's|image: $OLD_AS|image: $TAG_AS|' docker-compose.nas.yml"
    cmd "grep -n 'image: dss-as' docker-compose.nas.yml"
    say "         (dss-as-tools:1 은 글자가 겹치지만 위 sed 는 태그까지 붙여"
    say "          갈아 끼우므로 흔들리지 않습니다.)"
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
  # 볼륨과 포트 — 한 글자가 틀리면 앱은 **오류 없이** 뜨고 자료가 갈라진다.
  # 🔴 여기 있는 것은 전부 **이미 붙어 있던 자리**다. 이번에 새로 붙는 볼륨은
  #    하나도 없다 — 「사라지지 않았는가」만 본다.
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
  svc_block "$CF_EFF" tools-as | grep -q "$MIGDIR:/app/drizzle" \
    && ok "tools-as 가 $MIGDIR 를 /app/drizzle 로 붙인다 (1-ㄹ 이 세는 그 폴더)" \
    || bad "tools-as 의 drizzle 볼륨이 $MIGDIR 가 아니다"
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
    say "    🔴 그래서 0111 은 **PO 가 보는 DB 도 바꾼다.**"
    say "       enum 에 값 하나를 더할 뿐이고 PO 의 코드는 그대로라, PO 는 그 값을"
    say "       쓰지도 묻지도 않는다 — 그래서 PO 를 멈추지 않아도 된다."
  else
    bad "app-po 의 DATABASE_URL 이 app-as 와 다르다 — 🔴 PO 가 엉뚱한 DB 를 본다"
  fi

  # ── 1-ㅅ. ② 폴더를 컨테이너 안에서 **실제로 열어 본다** ─────────────
  step "1-ㅅ. 폴더 — 주인·모드가 아니라 컨테이너 안에서 실제로 연다"
  say "  🔵 이번 판에는 **새로 붙는 볼륨이 없다.** 전부 이미 붙어 있는 자리라"
  say "     지금 도는 컨테이너 안에서 그대로 본다(16번의 임시 컨테이너 검사는"
  say "     돌 자리가 없다 — 다음에 볼륨이 늘면 그때 다시 가져온다)."
  if [ "$PROBE_WRITE" = 1 ]; then
    say "  (교체되는 A/S 의 /data 는 읽기+쓰기를 본다. 시험 파일은 만들었다 지운다.)"
  else
    say "  🔵 --check 라서 **읽기만** 해 본다 — 아무 파일도 만들지 않는다."
  fi
  if [ "$PROBE_WRITE" = 1 ]; then M_DATA=rw; else M_DATA=ro; fi
  probe_svc app-as dss-as "A/S" "/data:$M_DATA /templates:ro" "$ATT $TEMPLATES"
  # 🔴 교체 안 되는 곳 — 「아직 읽히는가」만 본다. 쓰기 시험을 하지 않는다.
  probe_svc app-po           dss-po           PO       "/data:ro"         "$ATT"
  probe_svc app-meters       dss-meters       계측기   "/data:ro"         "$MF_METERS"
  probe_svc app-improvements dss-improvements 개선요청 "/data/uploads:ro" "$UP_IMP"
  # 🔴 공유폴더 둘은 위 틀에 안 넣는다 — 경로에 빈칸과 한글이 있고, 무엇보다
  #    여기서는 ACL 을 **걷으면 안 된다**(직원의 탐색기 접근이 끊긴다).
  say "  직원이 쓰는 공유폴더 둘 — 🔴 읽기만 본다. ACL 을 걷지 않는다:"
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

  # ── 1-ㅇ. 🔴 야간 백업 · 야간 완전삭제 (읽기만 한다) ─────────────────
  step "1-ㅇ. 야간 백업 다섯 · 야간 완전삭제 (읽기만 한다)"
  say "  🔴 이번에도 DB 를 바꾼다 — **--go 는 오늘 백업이 없으면 멈춘다**(3-ㄱ)."
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
    say "    🔴 그중 **dss_as 가 없으면 --go 는 시작조차 하지 않는다.**"
  fi
  say
  say "  야간 완전삭제 — DSM 작업 「DSS Purge」의 로그:"
  nlog=$(ls -1t "$D/setup/logs"/purge-*.log 2>/dev/null | wc -l | tr -d ' ')
  if [ "${nlog:-0}" -gt 0 ]; then
    ok "완전삭제 로그가 ${nlog}개 있다 — 스케줄러에 등록돼 돌고 있다"
    ls -lt "$D/setup/logs"/purge-*.log 2>/dev/null | head -3 | sed 's/^/      /'
    say "    🔵 「영구 삭제 0 건 · 성공」이면 맞다 — 지울 것이 없다는 뜻이다."
  else
    bad "🔴 완전삭제 로그가 **하나도 없다** — 스케줄러에 등록이 안 된 것이다"
    say "    → 그러면 휴지통이 **한 번도 안 비워지고 있다.**"
    say "    → 🔴 이 스크립트는 등록하지 않는다. 사람이 DSM 화면에서 합니다:"
    say "      [제어판] → [작업 스케줄러] · 이름 「DSS Purge」 · root · 매일 03:00"
    cmd "bash /volume1/dss/jobs/purge-nightly.sh"
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
  # 새 tar 124MB + 실은 이미지 582MB + dss_as 덤프 + 첨부 하드링크(공간 0).
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (새 tar + 실은 이미지 + 덤프가 들어가야 한다)"
  fi

  # ── 1-ㅊ. 알림 링크의 주소 — A/S 만 ─────────────────────────────────
  step "1-ㅊ. 알림 링크의 주소 (통로가 아니라 **나오는 주소**를 본다)"
  say "  🔴 **A/S 하나만 본다.** PO 에는 알림 통로가 아예 없다(api/integration 폴더가"
  say "     그 저장소에 없다 — 09-29 · 09-30 두 번 실측). 없는 것을 찾지 않는다."
  say "  🔵 이번 판이 알림 **종류 하나**(「새 수리 의뢰」)를 없앴다. 통로와 주소"
  say "     계산은 그대로라 기대값도 그대로다."
  notify_href_check "A/S" dss-as "$AS_ENV" "https://as.dss21.co.kr"

  # ── 1-ㅋ. 새 이미지 **안에** 이번 판이 들어 있는가 ───────────────────
  step "1-ㅋ. 새 이미지 안을 본다 (태그만으로는 안심 못 한다)"
  say "  🔴 9/21~9/29 에 A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다."
  if have_img "$TAG_AS"; then
    say "  $TAG_AS 구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_AS" --format '{{.Size}}' 2>/dev/null)"
    say "        (개발 PC 에서 582MB. $OLD_AS 는 581MB 였다 — 크기로는 못 가른다)"
    say "  🔴 그래서 **안의 파일 네 자리**로 가른다. 네 자리가 1.9 와 전부 뒤집힌다:"
    inside_check "$TAG_AS"
    say "  🔵 글자 인식기(public/ocr) 회귀 검사 — 1.9 에서 들어온 것이 그대로 있는가:"
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
  # 🔴 이번 판은 **태그 한 줄**만 달라야 한다. 더 달라졌으면 눈으로 보게 한다.
  say "  🔵 지금 것과 달라진 줄 (이번 판은 image 한 줄이어야 맞다):"
  diff "$CF" "$INCOMING" 2>/dev/null | sed 's/^/      /' | head -20
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
  echo "DSS 열세째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     되돌리는 것은 **이미지 하나**다:  $TAG_AS → $OLD_AS"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 DB 는 **되돌리지 않는다.** 그대로 둔다.                      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     0111 은 enum 에 값 하나를 **더하기만** 했다. 표도 칸도 자료도"
  say "     건드리지 않았다. PostgreSQL 에는 애초에 enum 값을 빼는 명령이 없다."
  say "     🔴 되돌리려고 덤프를 되붓는 것이 **오히려 자료를 잃는 길**이다 —"
  say "        덤프 시각 이후에 들어온 접수·작업 기록이 통째로 사라진다."
  say "     (3-ㄴ 에서 뜬 덤프는 「마이그레이션이 DB 를 깨뜨렸을 때」만 쓰는"
  say "      마지막 수단이다. 그때는 Claude 에게 알리고 함께 한다.)"
  say
  say "  ⚠️ 🔴 되돌리기 전에 **한 가지를 꼭 보라.**"
  say "     $OLD_AS 는 '$ENUM_NEW' 라는 값을 **모른다.** 2.0 이 도는 동안"
  say "     누군가 워크플로에 「수리 완료」 단계를 발행했다면 그 단계에 있는"
  say "     건의 상태 표시가 1.9 에서 어떻게 보일지 보장할 수 없다."
  say "     → 그런 단계가 있는지 먼저 센다 (🔴 select 다):"
  if pg_up; then
    s=$(qas "select count(*) from workflow_steps where repair_status = '$ENUM_NEW'")
    if [ "${s:-0}" = 0 ]; then
      ok "'$ENUM_NEW' 을 쓰는 단계가 **하나도 없다** — 그냥 되돌려도 된다"
    else
      bad "'$ENUM_NEW' 을 쓰는 단계가 ${s}개 있다"
      say "      → 🔴 되돌리기 전에 **워크플로를 옛 판으로 되돌려 발행**하세요."
      say "         (A/S → 워크플로 편집 → 그 단계를 「수리 중」 쪽으로 돌린 뒤 발행)"
    fi
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
  say "  🔵 이번 판은 **태그 한 줄**만 바뀌었다 — sed 로 되돌려도 반쪽이 되지 않는다."
  say "  태그만 내리기 — 🔴 아래를 **한 줄씩** 치세요:"
  cmd "cd /volume1/dss/deploy"
  cmd "sed -i 's|image: $TAG_AS|image: $OLD_AS|' docker-compose.nas.yml"
  cmd "grep -n 'image: dss-as' docker-compose.nas.yml"
  say "  사본으로 되돌리는 길 (그쪽이 더 확실하다):"
  cmd "cp \$(ls -1t ../backups/docker-compose.nas.yml.* | head -1) ."
  say "      (파일 이름이 길면 위 한 줄 대신 두 줄로 나눠 치세요)"

  step "3. as.env — 🔴 **되돌릴 것이 없다**"
  say "  이번 배포는 as.env 를 **한 글자도 고치지 않았다.** 그대로 두세요."

  step "4. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-as"
  script_file_hint "17-rollback"

  step "5. 지금 상태"
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
echo "DSS 열세째 배포 · 2026-10-05 · $(date '+%F %T')"
echo "  🔴 올라가는 것은 **하나**:  $OLD_AS → $TAG_AS"
echo "  🔴 멈추는 것도 **하나**:  dss-as"
echo "  🔴 이번 판의 줄기 넷: 고객 전용 주소 걷어내기(알림 404 도 함께) ·"
echo "     엔지니어 누구나 단계 직접 변경 · 수리 진행 상태에 「수리 완료」 ·"
echo "     주간보고에서 현 상태 바로 바꾸기"
echo "  🔴 마이그레이션 **하나**(0111) — 운영 $N_MIG_HAVE → $N_MIG_WANT. 더하기만 한다"
echo "  🔵 새 볼륨 없음 · 새 환경변수 없음 · as.env 안 고침 · 도구 이미지 그대로"
echo "  · 건드리지 않는 아홉 — $KEEP_AUTH · $KEEP_ASTOOLS · $KEEP_METERS"
echo "    · $KEEP_METERSTOOLS · $KEEP_IMP · $KEEP_IMPTOOLS"
echo "    · $KEEP_PO · $KEEP_LEAVE · $KEEP_LEAVETOOLS"
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**"
              echo "     🔵 아직 안 온 것 · 안 실린 것은 ⚠️ 로만 말한다(✗ 가 아니다)." ;;
  preload)    echo "  🔵 --preload — 새 이미지를 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — 마이그레이션 0111 을 적용하고 A/S 하나만 교체한다."
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
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS" "$SZ_AS" "$MD5_AS" "$WANT_CFG_AS"
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
step "1. 점검표를 기계로 옮긴 것 (앱은 살아 있다 · DB 도 그대로다)"
compose_incoming || stop "compose 를 바꾸지 않았습니다. 앱은 그대로 돕니다."
run_checks

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  if [ "$FAIL" = 0 ]; then
    echo "  ✅ 이어서 (A/S 가 잠깐 멈추고 DB 가 바뀝니다):  bash $0 --go"
    echo "     🔴 --go 는 오늘 백업(dss_as)이 없으면 **시작하자마자 멈춥니다.**"
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

# ── 2. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ───────────
step "2. 새 이미지 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
[ -n "$EXP_AS" ] || stop "tar 에서 지문을 못 읽었습니다. **아무것도 바꾸지 않았습니다.**"
bring_img "$TAG_AS" "$TAR_AS" "$EXP_AS" || {
  say
  say "  🔴 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
}

# ══ 3. 🔴 멈추기 전에 — 백업 · 덤프 · 마이그레이션 파일 ════════════════
#
# 🔴 여기까지가 「돌이킬 수 있는 자리」다. 3-ㄱ 이 백업의 문이다. 앱은 아직
#    $OLD_AS 로 **살아 있다.**

# ── 3-ㄱ. 🔴 오늘 백업을 **지금 다시** 찾는다. 없으면 멈춘다 ───────────
#
# 🔴 --check 에서 봤다는 것으로는 부족하다 — 그 뒤에 지워졌을 수 있고, 무엇보다
#    --check 를 안 돌리고 바로 여기로 올 수 있다. 13-deploy.sh 2단계가 하는
#    그대로다. 🔴 스크립트가 **대신 뜨지 않는다.**
step "3-ㄱ. 🔴 오늘 백업을 **지금 다시** 찾는다 (없으면 여기서 멈춘다)"
BK_TODAY=$(ls -1t "$BKD/db/${AS_DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
if [ -n "$BK_TODAY" ] && [ -s "$BK_TODAY" ]; then
  ok "오늘 백업 — $(basename "$BK_TODAY") ($(du -h "$BK_TODAY" | cut -f1))"
else
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 오늘($TODAY) 뜬 $AS_DB 백업을 **지금 찾지 못했습니다.**      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     마이그레이션이 하나뿐이고 더하기만 하지만, 백업 없이 DB 를 바꾸지"
  say "     않습니다. 먼저 이것부터 (종료 코드 0 이어야 합니다):"
  cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  say "     ✓ dss_as 줄이 찍혀야 합니다. 그 뒤에 다시:"
  cmd "bash $0 --go"
  stop "백업 없이 DB 를 바꾸지 않습니다. **DB 도 앱도 그대로입니다.**"
fi

# ── 3-ㄴ. 덤프 — 🔴 「마이그레이션이 DB 를 깨뜨렸을 때」의 마지막 수단 ──
#
# 🔴 되돌리기의 **기본 수단이 아니다.** 되돌리기는 이미지만 1.9 로 내리고 DB 는
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
fi
say "  ⚠️ PO 가 같은 DB 를 보고 있다 — 덤프 중에 PO 에서 저장한 것은 이 덤프에"
say "     안 들어갈 수 있다. 그래서 이 덤프는 마지막 수단이고, 되돌리기의"
say "     기본은 **이미지만 내리고 DB 는 그대로 두는 것**이다."

# ── 3-ㄷ. 🔴 마이그레이션 파일을 제자리에 놓는다 ───────────────────────
#
# 🔴 .sql 하나만이 아니라 meta/_journal.json 과 0111_snapshot.json 까지 함께
#    간다. 그래서 폴더를 **통째로** 갈아 끼운다(10 · 16-deploy.sh 와 같은 길).
step "3-ㄷ. 마이그레이션 파일 놓기 ($MIGDIR)"
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
[ -z "$MISS" ] && ok "0111 의 .sql 과 snapshot 이 있다" || bad "빠진 것:$MISS"
F0111=$(ls -1 "$MIGDIR/0111_"*.sql 2>/dev/null | head -1)
if [ -n "$F0111" ]; then
  grep -q "ADD VALUE '$ENUM_NEW'" "$F0111" \
    && ok "0111 안에 ADD VALUE '$ENUM_NEW' 가 있다 ($(basename "$F0111"))" \
    || bad "0111 안에 ADD VALUE '$ENUM_NEW' 가 **없다** — 🔴 다른 파일이다"
fi
[ "$FAIL" = 0 ] || stop "마이그레이션 파일이 온전하지 않습니다. **DB 도 앱도 그대로입니다.**"

# ── 3-ㄹ. 건드리지 않는 쪽의 **시작 시각**을 적어 둔다 ─────────────────
#
# 🔴 「안 멈췄다」를 말로 하지 않는다. 교체 뒤에 이 값과 그대로인지 본다.
step "3-ㄹ. 건드리지 않는 쪽의 시작 시각을 적어 둔다 (뒤에서 대조한다)"
KEEP_BOXES="dss-auth dss-meters dss-improvements dss-po dss-leave dss-pg-app dss-pg-auth"
STARTED_BEFORE=""
for t in $KEEP_BOXES; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  STARTED_BEFORE="$STARTED_BEFORE$t=$s
"
  say "  · $t  시작 ${s:-?}"
done

# ══ 4. 적용 전 확인 (db:preflight) — 🔴 앱은 **아직 1.9 로 살아 있다** ══
step "4. 적용 전 확인 — db:preflight  (🔴 앱은 아직 $OLD_AS 로 살아 있다)"
say "  🔴 0111 은 **지우는 문장이 하나도 없다**(DROP · DELETE · TRUNCATE 없음)."
say "     그러니 「사라질 자료가 있는 항목」이 나오면 그것이 신호다 — 멈춘다."
"${COMPOSE[@]}" run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | sed 's/^/    /'
PRC=${PIPESTATUS[0]}
say "  (종료 코드 $PRC — 기대 0)"
if [ "$PRC" != 0 ]; then
  bad "db:preflight 가 0 이 아니다 ($PRC) — 사라질 자료가 있다는 뜻이다"
  say "    → 🔴 0111 에는 그럴 문장이 없다. **다른 것이 섞였다.**"
  stop "마이그레이션을 시작하지 않았습니다. **DB 도 앱도 그대로이고 직원은 $OLD_AS 를 쓰고 있습니다.**"
fi
N_BEFORE=$(qas "select count(*) from drizzle.__drizzle_migrations")
say "  · 적용 전 DB 의 마이그레이션 줄: ${N_BEFORE:-?}  (기대 $N_MIG_HAVE)"
say
say "  🔴 이제 DB 를 바꿉니다. 그만두려면 **20초 안에 Ctrl+C**."
say "     지금 Ctrl+C 하면 DB 도 앱도 손대지 않은 채로 남습니다."
say "     (compose 와 마이그레이션 파일은 이미 바뀌었지만, 그 둘만으로는"
say "      아무 일도 일어나지 않습니다 — $OLD_AS 는 그것을 읽지 않습니다.)"
sleep 20

# ══ 5. 🔴 마이그레이션 적용 — 앱은 아직 $OLD_AS 로 살아 있다 ═══════════
step "5. 마이그레이션 적용 (0111)  🔴 여기서 DB 가 바뀐다"
say "  더하기만 한다 — $ENUM_TYPE 에 '$ENUM_NEW' 하나."
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
  say "    🔴 **새 이미지를 띄우지 않습니다.** $TAG_AS 는 없는 enum 값을 씁니다."
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

# 🔴 「했다」가 아니라 「들어 있다」를 본다 — enum 을 직접 센다.
say "  🔴 SQL 로 직접 센다 (「했다」가 아니라 「들어 있다」를 본다):"
E_NEW=$(qas "select count(*) from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = '$ENUM_TYPE' and e.enumlabel = '$ENUM_NEW'")
[ "${E_NEW:-0}" = 1 ] && ok "0111 · $ENUM_TYPE 에 '$ENUM_NEW' 이 들어갔다" \
  || bad "0111 의 enum 값이 **없다** (${E_NEW:-?}) — 🔴 $TAG_AS 를 띄우면 죽는다"
# 🔴 **자리까지** 본다. BEFORE 'WAITING_SHIPMENT_APPROVAL' 이 그 뜻이다.
E_PREV=$(qas "select (select e2.enumlabel from pg_enum e2 where e2.enumtypid = t.oid and e2.enumsortorder < e.enumsortorder order by e2.enumsortorder desc limit 1) from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = '$ENUM_TYPE' and e.enumlabel = '$ENUM_AFTER'")
[ "${E_PREV:-}" = "$ENUM_NEW" ] \
  && ok "'$ENUM_NEW' 이 '$ENUM_AFTER' 바로 **앞**에 있다 (차례까지 맞다)" \
  || bad "'$ENUM_AFTER' 앞에 있는 값이 '${E_PREV:-없음}' 이다 — 🔴 자리가 틀렸다"
say "  · 적용 뒤 $ENUM_TYPE 의 값 차례:"
qas "select e.enumlabel from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = '$ENUM_TYPE' order by e.enumsortorder" \
  | tr '\n' ' ' | sed 's/^/      /'
echo
say "  🔵 이 값을 쓰는 단계는 **아직 없는 것이 맞다** — 사람이 워크플로에서"
say "     고를 때 생긴다. 지금 세어 본다 (select):"
W_NEW=$(qas "select count(*) from workflow_steps where repair_status = '$ENUM_NEW'")
say "      workflow_steps 중 '$ENUM_NEW' 인 단계: ${W_NEW:-?}개"
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
step "7. 스모크 — 폴더 · 알림 · 권한 · 안 멈췄는가 · 바깥 주소"

# 7-ㄱ. 새 컨테이너로 폴더를 **실제로 열어 본다**
say "  7-ㄱ. 폴더를 새 컨테이너 안에서 실제로 연다"
probe_svc app-as dss-as "A/S" "/data:rw /templates:ro" "$ATT $TEMPLATES"

say "  7-ㄴ. 직원이 쓰는 공유폴더 둘 — 🔴 읽기만 본다 (이번 판은 안 건드렸다)"
if running dss-as; then
  "$DOCKER" exec dss-as sh -c 'ls -1 /quote-archive >/dev/null 2>&1' \
    && ok "A/S 가 견적서 공유폴더를 읽는다" \
    || { bad "A/S 가 견적서 공유폴더를 **못 읽는다** — 발행이 실패한다"
         say "    🔴 여기는 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기가 끊긴다."
         say "       compose 의 app-as 에 group_add: [\"100\"] 이 있는지부터 보세요."; }
  "$DOCKER" exec dss-as sh -c "ls -1 '$PORTAL_MNT' >/dev/null 2>&1" \
    && ok "A/S 가 현황표 공유폴더($PORTAL_MNT)를 읽는다" \
    || bad "A/S 가 $PORTAL_MNT 를 **못 읽는다** — 🔴 [공유폴더에 저장]이 죽는다"
  "$DOCKER" exec dss-as sh -c "[ -d \"\$CUSTOMER_PORTAL_ARCHIVE_DIR\" ]" >/dev/null 2>&1 \
    && ok "CUSTOMER_PORTAL_ARCHIVE_DIR 이 **실제로 있는 폴더**를 가리킨다" \
    || bad "CUSTOMER_PORTAL_ARCHIVE_DIR 이 가리키는 폴더가 컨테이너 안에 없다"
else
  bad "dss-as 컨테이너가 떠 있지 않다"
fi

say "  7-ㄷ. 알림 통로 — 포털이 묻는 자리 (A/S 만)"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 \
       "http://127.0.0.1:$AS_PORT/api/integration/notifications" 2>/dev/null)
case "$code" in
  404) bad "A/S 의 /api/integration/notifications 가 404 다 — **옛 이미지다**" ;;
  000|"") bad "A/S 의 알림 통로가 대답하지 않는다 (${code:-없음})" ;;
  *)   ok "A/S 의 알림 통로가 있다 (토큰 없이 부르면 401 이 맞다 — 지금 $code)" ;;
esac
say "  7-ㄹ. 🔴 알림 링크의 주소 — 새로 뜬 컨테이너로 다시 본다"
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
echo "  마이그레이션 ${N_BEFORE:-?} → ${N_AFTER:-?}"
echo "  적용 직전 덤프: $BK"
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

   1. 🔴 **주간보고** — 이번 판에서 가장 많이 바뀐 자리입니다.
      · 상세표의 「현 상태」 칸을 눌러 **그 자리에서 바꿔** 보세요.
        고른 값으로 단계가 옮겨 가고 저장돼야 맞습니다.
      · 🔴 **두 번 눌러 보세요** — 같은 값을 다시 골라도 깨지지 않아야 합니다.
      · 고르개에 「수리 완료」가 보입니까 (「수리 중」 바로 다음 자리).
      · 🔴 **위의 집계는 6칸 그대로**여야 맞습니다. 「수리 완료」인 건은
        집계에서 **「수리 중」 숫자에 들어갑니다.** 칸의 합과 총 대수가
        어긋나지 않는지 보세요.
      · 종류 고르개가 「RFG」 · 「MB」로 보입니까(「RFG 만」이 아니라).
      · 가로폭 슬라이더를 끌어 보세요 — **1%씩** 움직이고 조절 바가
        **오른쪽 위에 그대로 있어야** 맞습니다(전에는 트랙이 달아났습니다).
      · 🔴 **배포 전후로 숫자가 흔들리면 안 됩니다.** 워크플로의 2번 단계를
        미리 「인수점검 중」으로 발행해 두었기 때문입니다.
   2. 🔴 **엔지니어 계정으로** 로그인해 「현재 단계 직접 변경」을 써 보세요:
      · **자기 담당이 아닌 건**에서도 단계를 바꿀 수 있습니까.
      · **변경 사유를 비운 채로** 저장이 됩니까.
      · 🔴 사유를 비워도 **이력에는 남아야** 맞습니다 — 누가 · 언제 ·
        어디서 어디로.
      · 🔴 **영업 담당자 · 재고 담당자는 여전히 막혀야 맞습니다.**
      · 🔴 **보류 중인 건**과 **출하 완료로 잠긴 건**은 여전히 막혀야 맞습니다.
   3. **수리 진행 상태** — 「수리 완료」가 「수리 중」 다음, 「출하 승인 대기」
      앞에 보입니까.
   4. 🔴 **고객 안내 현황** — 전용 주소가 **사라진 것이 맞습니다.**
      · 고객사 양식 표 **하나만** 보이고, 표가 **반출일 오름차순**입니까.
      · 줄마다 [저장]은 그대로 됩니까.
      · [엑셀 미리보기] · [공유폴더에 저장] · [폴더 열기]는 **그대로**
        돼야 맞습니다(16번에서 들어온 그 기능입니다).
      · 🔴 **「새 수리 의뢰」 알림이 더는 안 떠야 맞습니다.** 전에는 누르면
        404 였습니다.
   5. 🔴 **포털 · 계측기 · 개선요청 · PO · 휴가가 그대로입니까** — 이번 판은
      그 다섯을 건드리지 않았습니다. 이상하면 남의 변경이 섞인 것입니다.
      (스크립트가 7-ㅂ 에서 시작 시각으로 이미 확인했습니다.)

🔴 사람이 이어서 할 일:
  · 직원에게 알립니다 — 「주간보고에서 현 상태를 바로 바꿀 수 있다」 ·
    「엔지니어 누구나 단계를 직접 바꿀 수 있다」 · 「수리 완료 상태가 생겼다」.
  · 🔴 「수리 완료」를 실제로 쓰려면 **워크플로에 그 단계를 두고 발행**해야
    합니다. 지금은 enum 값만 생긴 상태입니다(스크립트가 5단계에서 그 단계가
    몇 개인지 세어 찍었습니다).
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.
  · 내일 아침 백업을 한 번 더 보세요 — 다섯이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -7
  · 적용 직전 덤프는 $BK 에 있습니다. 한 주쯤 두었다 지우세요.

되돌리기 안내:  bash $0 --rollback
  🔴 되돌려도 **DB 는 그대로 둡니다** — enum 에 값 하나를 더했을 뿐이고,
     PostgreSQL 에는 그것을 빼는 명령이 애초에 없습니다.
  🔴 되돌리기 전에 「수리 완료」 단계를 발행했는지 보세요 — --rollback 이
     그것을 세어 줍니다.
ANNOUNCE
exit "$FAIL"
