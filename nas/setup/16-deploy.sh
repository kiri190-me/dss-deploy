#!/bin/bash
# /volume1/dss/setup/16-deploy.sh — 2026-10-02 열두째 배포
#
# ── 무엇이 올라가는가 ───────────────────────────────────────────────────
#   사내 사이트 여섯 중 **하나**만 올린다.
#
#     A/S  dss-as:1.8  →  **dss-as:1.9**
#
#   나머지 다섯(포털 1.5 · 계측기 1.3 · 개선요청 0.3 · PO 0.3 · 휴가 0.1)은
#   **건드리지 않는다. 멈추지도 않는다.**
#
#   🔴 15번과 다른 것 하나: **마이그레이션이 다섯 있다**(0106~0110).
#      15번에는 `db:migrate` 를 부르는 줄이 한 줄도 없었다. 이 스크립트에는
#      있다 — 6·7단계가 그 자리다. 그래서 백업 규칙도 세졌다(아래 ③).
#
# ── 이 판에 무엇이 담겼나 (사람에게 설명할 말로) ────────────────────────
#
#   9/30 아침부터 10/2 저녁까지 쌓인 **커밋 28개**(e7c3db9 ~ c497085)다.
#   큰 줄기는 셋이고, 나머지는 그 셋에 딸린 것이거나 작은 손질이다.
#
#   ① 🔴 **고객사 현황표** — 이번 배포 준비의 절반이 이것이다.
#      「고객 안내 현황」에 고객사 양식 표가 생겼고(엑셀 열 구성 그대로),
#      그 표를 **엑셀로 내보내** ㉠ 미리보기 ㉡ 공유폴더에 저장 ㉢ 폴더 열기
#      까지 한다. 저장할 자리가 **새 공유폴더**다:
#
#        /volume1/2_AS센터/1. 수리 관련/7. 수리품 목록/3. 업체별 수리품현황
#
#      🔴 그래서 이 배포에는 **compose 에 볼륨 하나**(/customer-portal-archive)와
#         **as.env 에 설정 다섯 줄**이 함께 간다. 둘 중 하나라도 빠지면 화면은
#         멀쩡히 뜨는데 [공유폴더에 저장]만 실패로 끝난다 — 앱이 루트를 만들지
#         않기 때문이다(그렇게 일부러 짰다. 없는 루트를 만들면 컨테이너 안
#         임시 디스크에 쓰게 되고, 그건 사라지는 저장이다).
#      · 같은 이름이면 **덮어쓴다**(2026-09-30 사용자 결정). 견적서 쪽은 지금도
#        ` (2)` 로 비켜 간다 — 이쪽만 다르다.
#      · 저장한 **뒤에** 날짜가 지난 옛 파일을 `OLD` 하위 폴더로 옮긴다.
#        `OLD` 가 없으면 앱이 만든다 → 이 폴더에는 **파일 쓰기 + 폴더 만들기**가
#        둘 다 돼야 한다(3-ㄴ 이 --go 에서 실제로 해 본다).
#      · 앱은 **맨 위 칸의 파일만** 본다. `OLD` 안으로는 내려가지 않는다.
#      · 「하루에 한 탭」 — 같은 날 다시 저장하면 그 날 탭을 갈아 끼운다.
#
#   ② **접수할 때 명판 사진으로 Model · L/N · S/N 을 채운다.**
#      QR 이 있으면 QR 로 읽고(`@zxing/library` — 새 의존성), 없으면 **글자
#      인식**으로 읽는다(네모를 치면 그 안만 읽는다).
#      🔴 글자 인식기와 언어 자료가 이미지 안에 **6.8MB** 들어간다
#         (`/app/public/ocr` — tesseract.min.js · worker.min.js ·
#          tessdata/eng.traineddata.gz). 그래서 1.9 는 1.8 보다 눈에 띄게 크다.
#         🔴 이것은 **밖으로 아무것도 보내지 않는다** — 브라우저 안에서 돈다.
#            통문증·명판에 고객사 이름이 들어 있어 외부 서비스에 못 보낸다는
#            그 판단의 결과다.
#      · 같은 줄기로 통문증(PASS_SLIP) 분류가 생겼고, 통문증 사진에서 통문번호 ·
#        PRV No. · Q코드를 읽어 주성 양식 표를 채운다.
#
#   ③ **엔지니어가 자기 작업 기록을 고칠 수 있게 한다.**
#      지금까지 작업 기록은 일부러 못 고치게 돼 있었다. 이제 **자기가 쓴 기록 ·
#      자기 담당 건**이면 고칠 수 있고, 고친 이력이 한 줄씩 쌓인다
#      (마이그레이션 `0110` 의 그 표).
#      🔴 `isAuthor` 가 거짓이면 **관리자도 최고관리자도 못 고친다.**
#      🔴 무효 처리(manage)는 엔지니어에게 **열지 않았다.**
#      → 이것이 아래 【검사 ⑤】가 있는 까닭이다.
#
#   그 밖에: 제품 모델에 파라미터·통전검사·점검표 올리기 · 파일 목록의 「원본
#   수정일」(0107) · 수리 건 상세의 모델명 눌러 가기 · 신고 증상 인수점검 결과를
#   비율로 · 워크플로 발행이 진행 중인 건을 새 판으로 옮기기 · 저장 팝업 손질.
#
# ══ 🔴 마이그레이션 다섯 — **전부 더하기만 한다** ══════════════════════
#
#   운영 DB(dss_as)는 지금 **106**, 적용하면 **111** 이 된다.
#
#     0106  attachment_category 에 PARAMETER · POWER_TEST · CHECKLIST 를 더한다
#           (ALTER TYPE … ADD VALUE … BEFORE 'OTHER' 셋)
#     0107  attachments 에 original_modified_at 칸 하나 (timestamptz, NULL 허용)
#     0108  repair_case_customer_status 에 form_values 칸 하나
#           (jsonb NOT NULL DEFAULT '{}') — 🔴 고객사 양식 표가 사는 자리다
#     0109  attachment_category 에 PASS_SLIP 을 더한다 (통문증)
#     0110  표 하나를 새로 만든다 — repair_case_work_record_edits
#           (작업 기록을 고친 이력. work_record_id · previous_memo ·
#            previous_record_kind · edited_by · edited_at + 외래키 둘 + 인덱스)
#
#   🔴 **지우는 문장이 하나도 없다.** DROP · DELETE · TRUNCATE 가 없다.
#      그래서 `db:preflight` 가 「사라질 자료」로 걸리지 않고 종료 코드 0 이다.
#
#   🔴 A/S 의 drizzle/ 은 이미지 안이 아니라 **볼륨**이다
#      (compose 의 tools-as: /volume1/dss/as-migrations:/app/drizzle:ro).
#      그러니 .sql 다섯만 넣어서는 안 되고 **meta/_journal.json 과
#      meta/0106~0110_snapshot.json 까지 함께** 가야 한다. _journal.json 이
#      옛것이면 drizzle 은 새 .sql 을 **아예 모른다** — 조용히 0건 적용으로
#      끝나고, 그 다음에 뜬 1.9 가 없는 칸을 찾다 죽는다.
#      → 그래서 폴더를 통째로 갈아 끼운다(5단계 · as-migrations.tar.gz).
#
#   🔴 **도구 이미지 dss-as-tools:1 은 다시 굽지 않았다.** 대기 커밋이
#      scripts/ 의 마이그레이션 도구를 건드리지 않았고(테스트 목록만 바뀌었다),
#      drizzle/ 은 애초에 그 이미지에 없다(볼륨이다).
#
# ══ 🔴 ④ 코드와 마이그레이션 사이에 간격을 두지 않는다 ════════════════
#
#   `0108`(고객사 양식 칸)이 적용되기 전까지 **고객에게 내보내는 동기화가
#   멈춘다**(5분마다 도는 그것). 고객 화면이 깨지지는 않고 옛 내용이 그대로
#   보이지만 갱신이 안 된다. 그래서 이미지 교체와 마이그레이션 적용이
#   **--go 안의 한 흐름**이다 — 사람이 두 번에 나눠 밟을 자리가 없다.
#
#   차례는 **마이그레이션이 먼저, 이미지가 나중**이다. 10-deploy.sh 가
#   그렇게 했고(멈춤 → 덤프 → migrate → up -d), 13-deploy.sh 도 같다
#   (--init 으로 db:migrate 를 끝낸 **뒤에** --go 로 앱을 띄운다).
#   까닭은 뒤집으면 바로 드러난다:
#     · 먼저 적용하면 — 1.8 은 새 칸을 **모른 채** 그냥 돈다. drizzle 의
#       select 는 코드가 아는 칸만 이름으로 적어 묻기 때문이다. 안전하다.
#     · 먼저 띄우면 — 1.9 가 아직 없는 칸(form_values · original_modified_at)을
#       이름으로 묻는다. 그 화면이 그 자리에서 죽는다.
#   같은 까닭으로 **PO(0.3)는 멈추지 않아도 된다.** PO 는 같은 DB(dss_as)를
#   보지만 코드가 그대로라 새 칸을 묻지 않는다. 더하기만 한 변경이라 PO 쪽에서
#   보이는 것도 달라지지 않는다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/16-deploy.sh            ← 읽기만 한다
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
#      않는다」가 정확한 말이다. 13·15번 머리말의 그 문장을 그대로 잇는다.
#
# ── 모드 다섯 ───────────────────────────────────────────────────────────
#   (없음) · --check     읽기만 한다. 아무것도 안 바꾸고 안 멈춘다      ← 기본값
#   --preload            새 이미지 하나를 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --go                 🔴 **A/S 하나만** 교체 + 마이그레이션 다섯 적용
#   --rollback           태그 되돌리기 안내
#
#   `--force-load` 는 `--go` 와 같이 써도 된다:  bash 16-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 16-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 16-deploy.sh --preload       (새 이미지를 미리 실어 둔다)
#   3) bash 16-deploy.sh                 (다시 읽기만 — 이번엔 지문까지 다 본다)
#   4) bash 16-deploy.sh --go            (마이그레이션 + A/S 교체)
#
# ══ 🔴 이번 배포에만 있는 것 다섯 ══════════════════════════════════════
#
# ── 【검사 ①】 as.env 에 설정 다섯 줄을 **덧붙인다** (2-ㄱ · 4단계)
#
#   🔴 **이 PC(dss-deploy)의 nas/env/as.env 를 NAS 로 올리지 않는다. 절대로.**
#      그 파일은 2026-09-15 것이라 낡았고, NAS 에 있는 세 줄
#        QUOTE_ARCHIVE_DIR · QUOTE_ARCHIVE_UNC_ROOT · QUOTE_ARCHIVE_UNC_ROOT_ALT
#      이 거기에 **없다.** 올리면 그 셋이 운영에서 사라지고 **견적서 [폴더 열기]가
#      죽는다.** (근거: runbook/07-2026-09-18-배포-점검표.html 의 그 경고 상자.)
#
#   그래서 이 스크립트는 **NAS 의 파일을 읽고, 없는 줄만 덧붙인다.**
#   덧붙이기 전에 env/as.env.$STAMP 로 사본을 남기고, 이미 그 줄이 있으면
#   **건드리지 않는다**(두 번 돌려도 안전하다).
#
#   넣을 다섯 줄과 그 뜻 (RF_Service_System/.env.example 에서 읽었다):
#     CUSTOMER_PORTAL_ARCHIVE_DIR        앱이 실제로 엑셀을 쓰는 **컨테이너 안**
#                                        경로. compose 의 target 과 같아야 한다
#     CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT   [폴더 열기] 도우미가 **열 수 있는 범위**.
#                                        🔴 될 수 있는 대로 **좁게** — 현황표
#                                        폴더의 **바로 위 폴더**까지
#     ..._UNC_ROOT_ALT                   같은 곳의 **다른 주소**(이름 ↔ IP).
#                                        이름 풀이가 안 되는 PC 를 위한 것
#     ..._FOLDER_PATH                    위 루트에서 **얼마나 더 들어가나**.
#                                        🔴 **비우면 [폴더 열기]가 꺼진다**
#     ..._UNC_PATH                       탐색기에 붙여넣을 **전체 주소**.
#                                        [위치 복사] 단추가 이것으로 생긴다
#
#   🔴 _UNC_ROOT 와 _ALT 에 **IP 를 쓸지 이름을 쓸지**는 NAS 의 as.env 가 정한다.
#      견적서 쪽(QUOTE_ARCHIVE_UNC_ROOT · _ALT)이 이미 그 둘을 나눠 쓰고 있고,
#      도우미는 **한 PC 에 한 벌**이라 두 쪽 루트가 한 파일에 함께 심긴다.
#      그래서 2-ㄱ 이 NAS 의 그 두 줄에서 **호스트 부분만** 뽑아 보여 주고,
#      **같은 차례로** 새 다섯 줄을 짜 준다. 뽑지 못하면 기본값
#      (ROOT=\\DSS-NAS · ALT=\\192.168.0.222)으로 짜고 **그렇게 말한다.**
#
#   ⚠️ 값에 **따옴표를 두르지 않는다.** env_file 의 큰따옴표 안에서는 역슬래시가
#      이스케이프로 읽혀 `\2` · `\7` 이 조용히 사라진다. 따옴표 없이 적으면
#      줄 끝까지가 그대로 값이다(빈칸이 들어 있어도 된다).
#
# ── 【검사 ②】 마이그레이션 — 파일을 옮기고 적용한다 (1-ㄹ · 5~7단계)
#
#   위 「마이그레이션 다섯」 절을 보라. 보는 자리는 넷이다:
#     ㄱ) /volume1/dss/as-migrations/*.sql 의 개수          (111)
#     ㄴ) 그 폴더의 meta/_journal.json 안의 tag 줄 수       (111)
#     ㄷ) 0106~0110 의 .sql 과 meta/*_snapshot.json 이 실제로 있는가
#     ㄹ) dss_as 의 drizzle.__drizzle_migrations 줄 수      (적용 전 106 → 뒤 111)
#   적용은 `tools-as` 로 한다 — 13·10번이 쓰는 그 길이다:
#     docker compose … --profile tools run --rm tools-as npm run db:migrate
#
# ── 【검사 ③】 🔴 백업이 없으면 **멈춘다** (3-ㄱ)
#
#   15번까지는 「백업이 오래됐다」고 **안내만** 했다. 이번엔 마이그레이션이
#   다섯이다. 그래서 --go 에서 **그날 백업이 없으면 거기서 멈춘다.**
#   보는 자리는 /volume1/dss/backups/db/dss_as_<오늘>_*.dump 다.
#   없으면 이것부터 돌리라고 말하고 끝낸다:
#     bash /volume1/dss/jobs/backup-nightly.sh
#   🔴 스크립트가 **대신 뜨지 않는다.** 백업은 사람이 확인하고 넘어가는 문이다.
#
# ── 【검사 ④】 새 공유폴더가 **컨테이너 안에서** 열리는가 (1-ㅅ · 3-ㄴ)
#
#   주인(uid)과 모드(755)만 보면 통과하는데 실제로는 EACCES 인 일이 있다 —
#   Synology ACL 이 상위에서 내려오면 `ls -ld` 에는 끝의 `+` 하나로만 보인다.
#   그래서 판정을 커널에게 맡긴다. 07-deploy.sh 2단계가 견적서 폴더에 한
#   그대로 한다. 다만 이쪽은 **폴더 만들기까지** 본다(`OLD` 때문이다).
#   🔴 쓰기 시험은 --go 에서만 한다(PROBE_WRITE). --check 는 읽기만 본다.
#   🔴 여기서 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기 접근이 끊긴다.
#      못 쓰면 compose 의 group_add: ["100"] 부터 본다.
#   🔴 그리고 앱이 만든 파일을 **직원이 열 수 있어야** 뜻이 있다. 새 파일에
#      allow 가 물려오는지 synoacltool 로 본다(07-deploy.sh 가 하던 그 검사).
#
# ── 【검사 ⑤】 🔴 운영 role_permissions 를 읽어 **판정한다** (1-ㄷ · 7-ㅂ)
#
#   작업 기록 수정은 **코드로만** 권한을 정한다 — `repairCases.workRecords` 에
#   WRITE 이상(src/lib/auth/repair-case-work-record-authorization.ts 의
#   canEditWorkRecord 주석). 그런데 운영 DB 에 저장된 값이 있으면 **그게 코드를
#   이긴다**(permission-resolver.ts 의 `configured[leafKey] ?? baseline…`).
#
#   🔴 2026-09-30 에 이것 때문에 「셋이 열린다」가 「하나만 열렸다」로 밝혀졌다.
#      그때 운영 DB 에는 AS_ENGINEER 의 quotes=WRITE · repairLabor=WRITE 가
#      2026-09-11 자로 저장돼 있었다 — 코드와 무관하게 진작 열려 있었던 것이다.
#      **권한은 코드가 아니라 운영 DB 가 정한다.**
#
#   그래서 --check 가 아래를 읽어 보여 주고 판정한다 (🔴 전부 select 다):
#     select role, area_key, level, updated_at::date
#       from role_permissions
#      where area_key like 'repairCases%'
#      order by area_key, role;
#   (지시서의 `or area_key = 'repairCases.workRecords'` 는 위 like 에 이미
#    들어 있어 빼도 같은 결과다 — 한 줄로 적었다.)
#
#   판정:
#     · AS_ENGINEER · repairCases.workRecords 에 **저장된 줄이 없으면**
#       → 코드 기본값 WRITE 가 적용돼 **열린다**
#         (permission-baseline.ts 373행의 ladder 가 AS_ENGINEER 에게 write 를 준다)
#     · 저장된 값이 WRITE · MANAGE 면 → 막지 않는다. 열린다
#     · 저장된 값이 NONE · READ 면 → 🔴 **배포해도 안 열린다.** 고치는 자리는
#       NAS 가 아니라 화면이다(A/S → 사용자 관리 → 역할별 접근 권한)
#   🔴 **select 만 쓴다.** 어떤 모드에서도 이 표를 고치지 않는다.
#   🔴 이 검사는 ✗ 로 세지 **않는다** — 배포의 흠이 아니라 설정이다. 여기서
#      ✗ 를 세면 아무 잘못 없는 배포가 멈춘다. 대신 눈에 띄게 찍고 마지막에
#      한 번 더 말한다. 15번이 쓴 그 방식 그대로다.
#
# ══ 🔴 건드리지 않는 아홉 ══════════════════════════════════════════════
#
#     dss-auth:1.5              dss-as-tools:1
#     dss-meters:1.3            dss-meters-tools:1
#     dss-improvements:0.3      dss-improvements-tools:2
#     dss-po:0.3                dss-leave:0.1
#     dss-leave-tools:1
#
#   🔴 **PO 가 이 목록에 새로 들어왔다.** 15번에서는 PO 가 올라가는 쪽이었다.
#   전부 지금 운영에서 돌고 있다. compose 에서 이 태그가 흔들렸으면 **남의
#   변경이 섞인 것**이다 — 두 세션이 같은 저장소를 쓴다(HANDOFF A절). 실제로
#   일어나는 일이다. 고치지 말고 **먼저 알린다.**
#
#   그리고 「안 멈췄다」를 말로 하지 않는다 — 교체 **전후로** 각 컨테이너의
#   시작 시각(.State.StartedAt)을 적어 두고 **그대로인지** 본다(7-ㅅ).
#
# ══ 15번에서 그대로 이어받는 것 ════════════════════════════════════════
#
#   ① 같은 태그로 다시 구운 이미지는 조용히 안 실린다 → --force-load
#   ② 폴더 권한은 **컨테이너 안에서 실제로 열어 본다**
#   ③ 이미지는 태그가 아니라 **안을 본다**(1-ㅋ)
#   ④ 사람이 칠 명령은 **한 줄 76자 안쪽**(DSM 의 ash 가 긴 줄을 자른다)
#   ⑤ 공유폴더는 **chmod 로 ACL 을 걷으면 안 된다**
#   ⑥ `docker ps` 에 보이는 것과 앱이 **대답하는** 것은 다르다 → wait_http
#   ⑦ compose 는 바꾸기 **전에** 시험하고, 바꾼 것은 backups/ 에 남긴다
#   ⑧ 알림 링크가 **밖에서 닿는 주소**로 나오는가(1-ㅊ · 7-ㅁ)
#
# ── 참고 · 개발 PC 에서 잰 값 ──────────────────────────────────────────
#   🔴 **아직 비어 있다.** dss-as:1.9 를 아직 굽지 않았기 때문이다(2026-10-02
#      현재 이 PC 에 dss-as:1.8 까지만 있다). 비어 있으면 이 스크립트는 바이트 ·
#      md5 대조를 **건너뛰고 잰 값을 찍어 준다** — 그 값을 아래 두 줄에 옮겨
#      적고 다시 돌리면 그때부터 대조한다.
#      🔵 비어 있어도 **무방비는 아니다.** tar 안의 Config(sha256)와 NAS 에
#         실린 뒤의 image ID 를 맞추는 검사(verify_img)는 그대로 돈다 —
#         그쪽이 「이 tar 가 그 이미지냐」를 보는 진짜 검사다.
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
TAG_AS=dss-as:1.9
OLD_AS=dss-as:1.8

# ── 🔴 **건드리지 않는 아홉.** PO 가 이번에 이 목록으로 넘어왔다 ───────
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
TAR_AS=$IMAGES/dss-as-1.9.tar
# 2026-10-02 17:18 개발 PC 에서 구워 **실측한 값**이다(docker build → docker save).
#    1.8 은 113512960 바이트였고 1.9 는 129642496 — public/ocr 6.8MB 와 QR 해독기가
#    들어가 **16MB 더 크다.** 비슷하면 오히려 의심하라(옛 tar 를 올린 것이다).
#    펼친 크기는 494MB → 581MB.
SZ_AS="129642496"
MD5_AS="613c10ed7c7595977d601580fd3b48cb"

# ── 포트 (compose 의 ports: 에서 읽어 확인했다 — 짐작이 아니다) ────────
#   포털 13100 · A/S 13000 · 계측기 13300 · 개선요청 13500 ·
#   PO 13600 · 휴가 13700
AS_PORT=13000

# ── 마이그레이션 — 🔴 **이번에는 적용한다** ────────────────────────────
AS_DB=dss_as
N_MIG_HAVE=106                 # 지금 운영에 적용돼 있는 수
N_MIG_WANT=111                 # 적용 뒤 수 (15번의 N_MIG_WANT=106 자리)
MIGDIR=$D/as-migrations        # compose 가 tools-as 의 /app/drizzle 로 붙인다
MIGTAR=$D/setup/incoming/as-migrations.tar.gz
NEW_MIGS="0106 0107 0108 0109 0110"
AS_TOOLS_SVC=tools-as

# ── 【검사 ⑤】 권한 — 표·칸·역할·값은 전부 소스에서 읽었다 (머리말 참조) ─
#   표·칸   vendor/dss-core/src/schema/role-permissions.ts
#           (표 role_permissions · 칸 role · area_key · level · updated_at.
#            🔴 칸 이름은 leaf_key 가 아니라 **area_key** 다 — 이름이 낡았다)
#   역할    vendor/dss-core/src/schema/users.ts → AS_ENGINEER (대문자)
#   레벨    src/lib/auth/permission-areas.ts → NONE < READ < WRITE < MANAGE
#   칸 값   src/lib/auth/permission-features.ts 463행 → repairCases.workRecords
#   기본값  src/lib/auth/permission-baseline.ts 373행 → AS_ENGINEER 는 WRITE
PERM_TABLE=role_permissions
PERM_ROLE=AS_ENGINEER
PERM_LEAF=repairCases.workRecords
PERM_NEED=WRITE

# ── 컨테이너 안에서 실제로 열어 볼 폴더 ────────────────────────────────
ATT=$D/as-attachments
TEMPLATES=$D/as-templates
UP_IMP=$D/improvements-uploads
MF_METERS=$D/meters-files

# ── 🔴 이번에 새로 붙는 공유폴더 ───────────────────────────────────────
# 🔴 `2_AS센터` 의 AS 는 **대문자**다. Windows 에서 본 이름(`2_as센터`)을 그대로
#    쓰면 리눅스에서 조용히 빈 폴더가 된다 — 전에 당한 자리다.
PORTAL_SRC="/volume1/2_AS센터/1. 수리 관련/7. 수리품 목록/3. 업체별 수리품현황"
PORTAL_MNT=/customer-portal-archive

# ── as.env 에 덧붙일 다섯 줄의 **재료** ────────────────────────────────
# 호스트 부분(\\DSS-NAS · \\192.168.0.222)은 2-ㄱ 이 NAS 의 as.env 에서 뽑는다.
# 뽑지 못했을 때 쓸 기본값은 아래 둘이다. NAS 이름은 DSS-NAS 다.
DEF_HOST_ROOT='\\DSS-NAS'
DEF_HOST_ALT='\\192.168.0.222'
P_SHARE='2_AS센터'                      # 공유 이름 (/volume1 바로 아래 폴더)
P_MID='1. 수리 관련\7. 수리품 목록'      # 공유 아래 ~ 현황표 폴더의 **바로 위**
P_LEAF='3. 업체별 수리품현황'            # 현황표 폴더 그 자체
# 2-ㄱ 이 채운다.
V_DIR=$PORTAL_MNT
V_ROOT=""
V_ALT=""
V_FOLDER=$P_LEAF
V_UNCPATH=""
ENV_KEYS="CUSTOMER_PORTAL_ARCHIVE_DIR CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT CUSTOMER_PORTAL_ARCHIVE_FOLDER_PATH CUSTOMER_PORTAL_ARCHIVE_UNC_PATH"
# 🔴 NAS 에만 있고 이 PC 의 사본에는 없는 세 줄. **사라지면 안 된다.**
QUOTE_KEYS="QUOTE_ARCHIVE_DIR QUOTE_ARCHIVE_UNC_ROOT QUOTE_ARCHIVE_UNC_ROOT_ALT"

# ── 이미지 **안에서** 찾을 글자 (1-ㅋ) ─────────────────────────────────
# 🔴 태그와 지문이 맞아도 「무엇이 든 판인지」는 안을 봐야 안다. 9/21~9/29 에
#    A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다.
#  표시 둘 다 1.8 에는 **한 글자도 없다**(개발 PC 에서 git grep 으로 실측:
#  e7c3db9~1 에서 0건 · c497085 에서 각각 1건 · 5건).
AS_MARK1="작업 기록 수정"     # 작업 기록 수정 창의 제목 (EditWorkRecordDialog)
AS_MARK2="명판 사진"          # 접수 화면의 명판 사진 칸 (NameplateQrPicker)
AS_CTRL="SSO_REDIRECT_URI"    # 두 판에 다 있는 대조 표시

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 셋. 인자가 없으면 이 셋 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
PROBE_WRITE=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 16-deploy.sh                  읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 16-deploy.sh --check          위와 같습니다
  bash 16-deploy.sh --preload        새 이미지를 싣고 지문만 맞춥니다
  bash 16-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 16-deploy.sh --go             🔴 마이그레이션 다섯 + A/S 교체
  bash 16-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 16-deploy.sh --rollback       되돌리기 안내

  🔴 --go 가 멈추는 것은 **dss-as 하나**입니다.
     포털 · 계측기 · 개선요청 · PO · 휴가 · DB 는 그대로 돕니다.
  🔴 --go 는 **DB 를 바꿉니다** — 마이그레이션 0106~0110 다섯.
     전부 더하기만 하지만, 그날 백업이 없으면 거기서 멈춥니다.
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
LOG="$D/setup/logs/16-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11 · 12 · 13 · 15-deploy.sh 의 것을 그대로 쓴다 ───────────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""; DOWN=0
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
#  거기서 도는 SQL 은 drizzle 이 0106~0110 파일에서 읽는 것이고, 이 스크립트가
#  직접 적는 SQL 은 **전부 select** 다. role_permissions 는 읽기만 한다.
# ══════════════════════════════════════════════════════════════════════
qas()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -Atc \"$1\"" 2>/dev/null; }
qqas() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -c   \"$1\"" 2>/dev/null; }

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 개발 PC 의 `docker image inspect --format {{.Id}}` 가 아니라 **이 값**이
#    NAS 에 실렸을 때의 image ID 가 된다(11-deploy.sh 머리말의 그 까닭).
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
#    rwd  읽기 + 파일 쓰기 + **폴더 만들기**  ← 현황표 폴더(OLD)가 이것이다
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
      MKDIR_OK)   ok "$label · $d 에 폴더를 만들 수 있다 (OLD 를 만드는 그 권한)" ;;
      MKDIR_SKIP) : ;;
      *)          bad "$label · $d 에 **폴더를 못 만든다** — OLD 로 치우기가 실패한다"; anybad=1 ;;
    esac
  done <<EOF
$(printf '%s\n' "$out" | grep '^PROBE ')
EOF
  [ "$anybad" = 0 ] || perm_fix_hint $hosts
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 **이번 배포로 새로 붙는 볼륨**은 임시 컨테이너로 본다
#
#  ╔══════════════════════════════════════════════════════════════════╗
#  ║ 🔴 왜 도는 컨테이너에서 보지 않는가 — 되돌리지 마라.               ║
#  ╚══════════════════════════════════════════════════════════════════╝
#  **새로 붙는 볼륨은 배포 전에는 도는 컨테이너 안에 없다.** 그 자리는 새
#  compose 를 적용해야 생기는데, --check 시점에 도는 것은 아직 옛 compose 의
#  dss-as:1.8 이다. 거기에 /customer-portal-archive 가 있을 수가 없다.
#
#  🔴 2026-10-02 에 이 검사가 바로 그 이유로 ✗ 를 냈다(통과 88 · 실패 1).
#     **폴더는 멀쩡했다.** NAS 에서 따로 확인한 것이 이렇다:
#       · 도는 컨테이너에 붙은 자리는 /templates · /data · /quote-archive 셋뿐
#       · 호스트 경로를 임시로 붙여 띄우니 **읽혔다**(맨 위 칸 5개)
#       · synoacltool -get 을 견적서 폴더와 끝까지 견주니 **둘 다 22줄**이고
#         group:users:allow:rwxpdDaARWc-- 가 양쪽에 있다. 모드도 양쪽
#         drwxrwxrwx+ 로 같다
#     즉 EACCES 는 권한 문제가 아니라 **그 자리가 없어서** 난 것이었다.
#
#  그래서 호스트 경로를 **임시로 붙여** 읽어 본다. --check 이므로 **읽기만**
#  한다(:ro). 쓰기·폴더 만들기는 지금처럼 --go 의 3-ㄴ 에서만 본다.
#
#  ── 어느 이미지로 띄우는가 ────────────────────────────────────────────
#  🔴 **지금 도는 dss-as 의 이미지**를 먼저 쓴다. 이 검사가 보는 것은 폴더와
#     ACL 이지 이미지가 아니라서 sh 가 든 것이면 아무거나 된다. 그런데
#     --preload 전에는 dss-as:1.9 가 **아직 NAS 에 없을 수 있다** — 그걸
#     골랐다가는 「이미지가 없어서」 또 못 보게 된다. 도는 이미지는 지금 돌고
#     있으니 반드시 있다. 없으면 1.9 → 1.8 차례로 내려간다.
#
#  ⚠️ -u 1000:1000 --group-add 100 은 compose 의 app-as 와 **같은 조건**이다
#     (group_add: ["100"]). 그것 없이 재면 ACL 의 group:users:allow 에 안 걸려
#     「못 읽는다」가 나온다 — 그러면 멀쩡한 폴더를 또 의심하게 된다.
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
  say "    (도는 컨테이너에는 아직 이 자리가 없다 — 함수 머리말 참조)"
  # 🔴 경로는 -e M= 로 넘겨 **컨테이너 안에서** 푼다. sh -c 본문에 끼워 넣으면
  #    빈칸 · 한글이 든 경로에서 조용히 깨진다.
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
      say "    🔵 쓰기 · 폴더 만들기는 --go 의 3-ㄴ 에서 본다(--check 는 안 만든다)."
      return 0 ;;
    READ_FAIL)
      bad "$label · $mnt 를 **못 읽는다**(EACCES) — 🔴 이번엔 진짜 권한 문제다"
      say "    (자리가 없어서 나는 ✗ 가 아니다. 여기서는 자리를 **우리가 붙여** 봤다.)"
      # 🔴 여기서는 perm_fix_hint 를 부르지 않는다 — 그 안내는 chown·chmod 로
      #    ACL 을 걷는 길이고, **직원이 쓰는 공유폴더에 그러면 탐색기 접근이
      #    끊긴다.** 대신 견적서 폴더와 견주게 한다(그쪽은 되는 것이 확인됐다).
      say "    🔴 **chmod · chown 을 하지 마라** — 직원의 탐색기 접근이 끊긴다."
      say "    되는 폴더(견적서)와 ACL 을 끝까지 견주세요 — 줄 수와 users 줄을 봅니다:"
      cmd "synoacltool -get \"$src\" | head -30"
      say "    (견적서 쪽과 견줄 때 보는 것: 줄 수가 같은가 ·"
      say "     group:users:allow:rwxpdDaARWc-- 가 있는가 · 모드가 drwxrwxrwx+ 인가)"
      say "    compose 의 app-as 에 group_add: [\"100\"] 이 있는지도 보세요."
      return 1 ;;
    *)
      bad "$label · 열어 보지 못했다 — 아래가 그대로의 출력이다"
      printf '%s\n' "$out" | sed 's/^/      /' | head -8
      return 1 ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 앱이 저장한 파일을 **직원이 열 수 있는가** (07-deploy.sh 2단계의 그 검사)
#
#  만든 파일의 POSIX 모드는 000 이고(주인이 DSM 사용자가 아니다) 접근은 물려받은
#  ACL 이 정한다. allow 가 하나도 안 물려오면 직원 눈에 「열리지 않는 파일」만
#  쌓인다 — 없느니만 못하다. 🔴 파일을 하나 만들었다 지우므로 --go 에서만 한다.
# ══════════════════════════════════════════════════════════════════════
acl_inherit_check() { # 1 호스트폴더 2 사람이읽을이름 3 이미지태그 4 컨테이너안경로
  local src="$1" label="$2" tag="$3" mnt="$4" t allow users_ok
  t="$src/.dss-inherit-test"
  "$DOCKER" run --rm --group-add 100 -v "$src:$mnt" --entrypoint sh "$tag" \
    -c ": > $mnt/.dss-inherit-test" >/dev/null 2>&1
  if [ ! -e "$t" ]; then
    bad "$label · 시험 파일을 만들지 못했다 — 앱도 저장하지 못한다"
    say "    🔴 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기 접근이 끊긴다."
    say "       compose 의 app-as 에 group_add: [\"100\"] 이 있는지부터 보세요."
    return 1
  fi
  allow=$(synoacltool -get "$t" 2>/dev/null | grep -c ":allow:")
  users_ok=$(synoacltool -get "$t" 2>/dev/null \
             | grep -c "group:users:allow\|group:administrators:allow")
  rm -f "$t"
  if [ "${allow:-0}" -gt 0 ] && [ "${users_ok:-0}" -gt 0 ]; then
    ok "$label · 새 파일이 ACL 을 물려받는다 (allow ${allow}줄) — 직원이 연다"
    return 0
  fi
  bad "$label · 새 파일에 allow 가 안 물려온다 (allow ${allow:-0}줄)"
  say "    → 앱이 저장해도 **직원이 못 여는 파일**이 쌓인다."
  say "    → 그럴 바에는 이 기능을 끄는 편이 낫다 — as.env 의"
  say "      CUSTOMER_PORTAL_ARCHIVE_DIR 한 줄을 비우면 [공유폴더에 저장]만"
  say "      꺼지고 화면의 표 · 고객 안내 · 견적서는 그대로 동작한다."
  return 1
}

# ══════════════════════════════════════════════════════════════════════
#  【이어받은 검사】 알림 링크의 **주소를 실제로 뽑아 본다**
#
#  🔴 2026-09-29 에 「통로가 있다(401 이 온다)」로 통과했는데, 그 통로가 내준
#     링크가 http://172.20.0.7:3500/ 이었다. 문이 있는지가 아니라 **무엇이
#     나오는지**를 봐야 잡힌다. A/S 는 SSO_REDIRECT_URI 에서 자기 주소를 뽑는다
#     (src/lib/config/sso.ts 의 getAppBaseUrl).
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

# ── 이미지 **안에** 그 판의 표시가 들어 있는가 ─────────────────────────
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
    ok "$label · $tag 안에 「$marker」가 있다 (1.8 에는 없는 글자다)"
    return 0
  fi
  if [ "${c:-0}" = 1 ]; then
    bad "$label · $tag 는 **옛 판**이다 — 「$marker」가 없다"
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

# ── 🔴 이미지 안에 글자 인식기(public/ocr)가 들어 있는가 ───────────────
# 🔴 Next 의 standalone 은 public 을 **자동으로 담지 않는다.** Dockerfile 이
#    따로 COPY 하는데(117행), 그 줄이 어긋나면 화면은 뜨고 명판 읽기만 죽는다 —
#    그것도 오류 없이 「인식기를 불러오지 못했습니다」 하나로.
ocr_check() { # 1 이미지태그
  local tag="$1" out a b c s
  have_img "$tag" || { bad "OCR · $tag 가 NAS 에 없다"; return 1; }
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
  say "    · /app/public/ocr 크기: ${s:-?} KB (개발 PC 실측 약 6.8MB = 약 6900KB)"
  if [ "${s:-0}" -lt 5000 ]; then
    bad "OCR 폴더가 ${s:-0}KB 뿐이다 — 자료가 덜 담겼다"
  fi
}

# ══════════════════════════════════════════════════════════════════════
#  【검사 ⑤】 작업 기록 수정이 **진짜로** 열리는가 — 🔴 select 만 쓴다
#
#  까닭과 출처는 머리말에 있다. 🔴 ✗ 로 세지 **않는다** — 배포의 흠이 아니라
#  설정이고, 고치는 자리도 NAS 가 아니라 A/S 의 화면이다.
# ══════════════════════════════════════════════════════════════════════
lvl_rank() { # 1 레벨  → 0..3 (모르는 값이면 -1)
  case "$1" in
    NONE) echo 0 ;; READ) echo 1 ;; WRITE) echo 2 ;; MANAGE) echo 3 ;; *) echo -1 ;;
  esac
}
# 🔴 실제로 돌리는 SQL 전문. 화면에도 그대로 찍어 사람이 무엇을 물었는지
#    눈으로 확인할 수 있게 한다. select 뿐이다.
PERM_SQL_COUNT="select count(*) from $PERM_TABLE"
PERM_SQL_ALL="select role, area_key, level, updated_at::date from $PERM_TABLE where area_key like 'repairCases%' order by area_key, role"
PERM_SQL_ROWS="select role || '|' || level from $PERM_TABLE where area_key = '$PERM_LEAF' order by role"
PERM_SQL_MINE="select level from $PERM_TABLE where role = '$PERM_ROLE' and area_key = '$PERM_LEAF'"

perm_check() {
  local reg n_all rows got r_got r_want line rl lv
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
  say "      $PERM_SQL_ALL"
  say "      $PERM_SQL_ROWS"
  say "      $PERM_SQL_MINE"
  say
  n_all=$(qas "$PERM_SQL_COUNT")
  say "  · $PERM_TABLE 전체 줄: ${n_all:-?}  (0 이면 전부 코드의 기본 정책대로다)"
  say
  say "  전체 A/S 현황(repairCases*)에 저장된 값 — 역할 전부:"
  qqas "$PERM_SQL_ALL" | sed 's/^/      /'
  say

  # ── 판정 ①  AS_ENGINEER · repairCases.workRecords ────────────────────
  got=$(qas "$PERM_SQL_MINE" | head -1)
  r_want=$(lvl_rank "$PERM_NEED")
  if [ -z "$got" ]; then
    ok "$PERM_ROLE · $PERM_LEAF 에 **저장된 값이 없다**"
    say "     ╔══════════════════════════════════════════════════════════════╗"
    say "     ║ ✅ 이 배포로 엔지니어에게 작업 기록 수정이 **열립니다.**       ║"
    say "     ╚══════════════════════════════════════════════════════════════╝"
    say "       저장된 값이 없으므로 코드의 기본 정책($PERM_NEED)이 그대로 적용된다"
    say "       (permission-baseline.ts 373행의 ladder)."
    say "       🔴 다만 **자기가 쓴 기록 · 자기 담당 건**일 때만이다. 남의 글은"
    say "          관리자도 최고관리자도 못 고친다. 무효 처리는 그대로 관리자 몫."
  else
    r_got=$(lvl_rank "$got")
    if [ "$r_got" -ge "$r_want" ] 2>/dev/null; then
      ok "$PERM_ROLE · $PERM_LEAF 에 저장된 값이 $got 다 — $PERM_NEED 보다 낮지 않다"
      say "     ╔══════════════════════════════════════════════════════════════╗"
      say "     ║ ✅ 이 배포로 엔지니어에게 작업 기록 수정이 **열립니다.**       ║"
      say "     ╚══════════════════════════════════════════════════════════════╝"
      say "       🔴 다만 그 값은 **DB 에 저장된 것**이다. 누군가 화면에서 그 칸을"
      say "          낮추면 코드와 무관하게 그 순간 막힌다."
    else
      PERM_PINNED=$((PERM_PINNED + 1))
      say "     ╔══════════════════════════════════════════════════════════════╗"
      say "     ║ 🔴 **배포해도 작업 기록 수정은 안 열립니다.**                  ║"
      say "     ╚══════════════════════════════════════════════════════════════╝"
      say "       DB 에 저장된 값: $got   (코드의 기본값: $PERM_NEED)"
      say "       칸 하나하나마다 **저장된 값이 코드의 기본 정책을 이깁니다**"
      say "       (permission-resolver.ts 168행)."
      say "       고치는 자리는 NAS 가 아니라 화면입니다:"
      say "         A/S → [사용자 관리] → [역할별 접근 권한] → $PERM_ROLE 줄의"
      say "         「전체 A/S 현황」 쪽 작업 기록 칸을 $PERM_NEED 이상으로 올리고 저장."
      say "       (이 줄은 ✗ 로 세지 않습니다. 배포의 흠이 아니라 설정입니다.)"
    fi
  fi

  # ── 판정 ②  다른 역할도 본다 — 관리자가 막혀 있으면 그것도 알려야 한다 ─
  rows=$(qas "$PERM_SQL_ROWS")
  if [ -n "$rows" ]; then
    say
    say "  🔵 $PERM_LEAF 에 저장된 줄 전부 (역할별):"
    while IFS='|' read -r rl lv; do
      [ -n "${rl:-}" ] || continue
      r_got=$(lvl_rank "$lv")
      if [ "$r_got" -ge "$r_want" ] 2>/dev/null; then
        say "      · $rl = $lv  (막지 않는다)"
      else
        say "      · $rl = $lv  🔴 이 역할은 작업 기록 수정이 **막혀 있다**"
      fi
    done <<EOF
$rows
EOF
  else
    say "  🔵 $PERM_LEAF 에 저장된 줄이 **한 역할에도 없다** — 전부 코드 기본값대로다."
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  as.env — 🔴 **NAS 의 파일을 읽고 없는 줄만 덧붙인다**
#
#  🔴 이 PC 의 nas/env/as.env 를 올리지 않는다(머리말 【검사 ①】).
#  🔴 값은 로그에 찍지 않는다 — 다만 QUOTE_ARCHIVE_UNC_ROOT · _ALT 의
#     **호스트 부분**(\\이름 또는 \\IP)만 뽑아 보여 준다. 새 다섯 줄을 같은
#     꼴로 짜려면 그 한 토막이 필요하고, 그 토막은 비밀이 아니라 NAS 이름이다.
#     나머지(공유 이름 아래의 폴더 구조)는 찍지 않는다.
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
# 다섯 줄의 값을 짠다. 🔴 printf 로 짓는다 — 역슬래시가 한 겹 삼켜지지 않게.
build_env_values() {
  local qroot qalt hr ha src_note
  qroot=$(env_val QUOTE_ARCHIVE_UNC_ROOT)
  qalt=$(env_val QUOTE_ARCHIVE_UNC_ROOT_ALT)
  hr=$(unc_host "$qroot")
  ha=$(unc_host "$qalt")
  src_note="NAS 의 as.env"
  if [ -z "$hr" ]; then hr=$DEF_HOST_ROOT; src_note="기본값(뽑지 못했다)"; fi
  if [ -z "$ha" ]; then ha=$DEF_HOST_ALT;  src_note="$src_note · ALT 는 기본값"; fi
  V_DIR=$PORTAL_MNT
  V_ROOT=$(printf '%s\\%s\\%s' "$hr" "$P_SHARE" "$P_MID")
  V_ALT=$(printf  '%s\\%s\\%s' "$ha" "$P_SHARE" "$P_MID")
  V_FOLDER=$P_LEAF
  V_UNCPATH=$(printf '%s\\%s' "$V_ROOT" "$P_LEAF")
  ENV_SRC_NOTE=$src_note
  ENV_HOST_ROOT=$hr
  ENV_HOST_ALT=$ha
}
ENV_SRC_NOTE=""; ENV_HOST_ROOT=""; ENV_HOST_ALT=""
env_line_for() { # 1 키  → "키=값" 한 줄
  case "$1" in
    CUSTOMER_PORTAL_ARCHIVE_DIR)          printf '%s=%s' "$1" "$V_DIR" ;;
    CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT)     printf '%s=%s' "$1" "$V_ROOT" ;;
    CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT) printf '%s=%s' "$1" "$V_ALT" ;;
    CUSTOMER_PORTAL_ARCHIVE_FOLDER_PATH)  printf '%s=%s' "$1" "$V_FOLDER" ;;
    CUSTOMER_PORTAL_ARCHIVE_UNC_PATH)     printf '%s=%s' "$1" "$V_UNCPATH" ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)
EXP_AS=""
MIG_PLACED=0   # as-migrations 폴더가 이미 111 이면 1
SVCS=""
AS_DBURL=""; PO_DBURL=""

see_tar() { # 1 태그 2 tar 3 지문 4 바이트(비어도 됨) 5 md5(비어도 됨)
  local n m
  if [ ! -s "$2" ]; then
    bad "$1 의 tar 가 없다: $2"
    say "    → 개발 PC 에서 올리세요. 🔴 scp 에는 -O 를 붙입니다(DSM 에 sftp 가 없다)."
    return 1
  fi
  n=$(stat -c '%s' "$2" 2>/dev/null)
  m=$(md5sum "$2" 2>/dev/null | awk '{print $1}')
  if [ -n "$4" ]; then
    [ "$n" = "$4" ] && ok "$1 · 바이트 $n" \
      || bad "$1 의 바이트가 $4 가 아니다 ($n) — 올리다 끊겼다"
  else
    say "    ⚠️ $1 · 기대 바이트가 비어 있다 — 잰 값: $n"
    say "       (이 값을 16-deploy.sh 의 SZ_AS 에 적어 넣으세요)"
  fi
  if [ -n "$5" ]; then
    [ "$m" = "$5" ] && ok "$1 · md5 $m" \
      || bad "$1 의 md5 가 $5 가 아니다 (${m:-못 읽음}) — 파일이 상했다"
  else
    say "    ⚠️ $1 · 기대 md5 가 비어 있다 — 잰 값: ${m:-못 읽음}"
    say "       (이 값을 16-deploy.sh 의 MD5_AS 에 적어 넣으세요)"
  fi
  [ -n "$3" ] && ok "$1 · tar 안의 기대 지문 $(echo "$3" | cut -c1-19)…" \
    || bad "$1 의 tar 에서 manifest.json 을 읽지 못했다: $2"
}

run_checks() {
  local tag s p rec t n_sql n_j n_db f db n_bk nlog k line miss n_snap rc
  local FREE_KB FREE_H code h

  # ── 1-ㄱ. 이미지 tar — 크기 · md5 · tar 안의 지문 ────────────────────
  step "1-ㄱ. 새 이미지 tar (크기 · md5 · tar 안의 지문)"
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS" "$SZ_AS" "$MD5_AS"

  # ── 1-ㄴ. NAS 에 실린 이미지 ─────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (올라가는 하나 · 건드리지 않는 아홉)"
  if have_img "$TAG_AS"; then
    [ -n "$EXP_AS" ] && { verify_img "$TAG_AS" "$EXP_AS" || force_load_hint "$TAG_AS"; }
  else
    say "  · $TAG_AS 는 아직 NAS 에 없다 — --preload 나 --go 가 싣는다"
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

  # ── 1-ㄷ. 🔴 【검사 ⑤】 작업 기록 수정 권한 ──────────────────────────
  step "1-ㄷ. 【검사 ⑤】 엔지니어의 작업 기록 수정이 **진짜로** 열리는가"
  say "  🔴 **권한은 코드가 아니라 운영 DB 가 정한다.** 칸마다 DB 에 저장된 값이"
  say "     있으면 그 값이 코드의 기본 정책을 이긴다. 2026-09-30 에 이것 때문에"
  say "     「셋이 열린다」가 「하나만 열렸다」로 밝혀졌다."
  perm_check

  # ── 1-ㄹ. 🔴 마이그레이션 — 이번에는 **적용한다** ────────────────────
  step "1-ㄹ. 【검사 ②】 마이그레이션 다섯 ($N_MIG_HAVE → $N_MIG_WANT)"
  say "  🔴 A/S 의 drizzle/ 은 이미지가 아니라 **볼륨**이다:"
  say "     $MIGDIR → tools-as 의 /app/drizzle (읽기 전용)"
  say "  그래서 .sql 다섯만이 아니라 **meta/_journal.json 과 snapshot 다섯까지**"
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
        ok "아직 $N_MIG_HAVE 이다 — **--go 가 incoming 의 tar 로 갈아 끼운다**"
        say "    $MIGTAR ($(du -h "$MIGTAR" | cut -f1))"
      else
        bad "아직 $N_MIG_HAVE 인데 **갈아 끼울 tar 가 없다**: $MIGTAR"
        say "    → 개발 PC 에서 drizzle/ 을 통째로 묶어 올리세요(🔴 scp -O):"
        say "        tar czf as-migrations.tar.gz drizzle"
        say "      올릴 자리: /volume1/dss/setup/incoming/as-migrations.tar.gz"
        say "    🔴 .sql 다섯만 넣지 마세요 — meta/_journal.json 이 빠지면"
        say "       적용이 **조용히 0건**으로 끝납니다."
      fi
    else
      bad "폴더가 $N_MIG_HAVE 도 $N_MIG_WANT 도 아니다 (.sql ${n_sql} · tag ${n_j})"
      say "    → 🔴 **남의 손이 닿았거나 반쯤 올라간 것**이다. 고치지 말고 알리세요."
    fi
    # 새 다섯이 실제로 있는가 — 놓인 뒤에만 뜻이 있다
    if [ "$MIG_PLACED" = 1 ]; then
      miss=""
      for t in $NEW_MIGS; do
        ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || miss="$miss $t(sql)"
        [ -f "$MIGDIR/meta/${t}_snapshot.json" ] || miss="$miss $t(snapshot)"
      done
      if [ -z "$miss" ]; then
        ok "0106~0110 의 .sql 다섯과 meta/*_snapshot.json 다섯이 다 있다"
      else
        bad "빠진 것이 있다:$miss"
      fi
      n_snap=$(ls -1 "$MIGDIR"/meta/*_snapshot.json 2>/dev/null | wc -l | tr -d ' ')
      say "  · meta/*_snapshot.json: ${n_snap}개"
    fi
  else
    bad "$MIGDIR 폴더가 없다 — compose 가 tools-as 에 붙이는 그 폴더다"
  fi
  if pg_up; then
    if [ -n "$(qas "select to_regclass('drizzle.__drizzle_migrations')")" ]; then
      n_db=$(qas "select count(*) from drizzle.__drizzle_migrations")
      say "  · 운영 DB($AS_DB)에 적용된 줄: ${n_db:-?}"
      case "${n_db:-x}" in
        "$N_MIG_HAVE") ok "적용 전 상태가 맞다 ($N_MIG_HAVE) — --go 가 다섯을 적용한다" ;;
        "$N_MIG_WANT") ok "**이미 $N_MIG_WANT 다** — 적용이 끝난 DB 다(두 번 돌려도 안전하다)" ;;
        *) bad "적용된 줄이 $N_MIG_HAVE 도 $N_MIG_WANT 도 아니다 (${n_db:-?})"
           say "    → 🔴 **이것이 신호다.** 남의 변경이 섞였거나 누가 손으로 적용한 것이다."
           say "      고치지 말고 **먼저 알리세요.**" ;;
      esac
    else
      bad "$AS_DB 에 drizzle.__drizzle_migrations 가 없다 — 첫 설치가 안 된 DB 다"
    fi
  else
    bad "dss-pg-app 이 떠 있지 않다 — 적용 수를 못 봤다"
  fi
  # 적용 전 **대기 수** — db:preflight 가 그것을 말해 준다
  say
  say "  🔵 적용 대기 수를 봅니다 — db:preflight (DB 에는 select 만 갑니다):"
  if [ -n "$SVCS" ] || SVCS=$(compose_at "$CF_EFF" config --services 2>/dev/null); then :; fi
  if echo "$SVCS" | grep -qx "$AS_TOOLS_SVC"; then
    compose_at "$CF_EFF" run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | sed 's/^/      /'
    rc=${PIPESTATUS[0]}
    say "      (종료 코드 $rc — 🔴 이번 다섯은 **지우는 문장이 없어** 0 이 맞다)"
    say "      🔵 기대: 폴더가 아직 $N_MIG_HAVE 이면 「대기 0건」, 갈아 끼운 뒤면 「대기 5건」."
  else
    bad "compose 에 $AS_TOOLS_SVC 가 없다 — 마이그레이션을 돌릴 수 없다"
  fi

  # ── 1-ㅁ. 🔴 as.env — 다섯 줄 · 🔴 견적서 세 줄이 살아 있는가 ────────
  step "1-ㅁ. 【검사 ①】 as.env (이름만 본다. 값은 호스트 토막만 찍는다)"
  if [ -f "$AS_ENV" ]; then
    s=$(stat -c '%a' "$AS_ENV" 2>/dev/null)
    [ "$s" = 600 ] && ok "as.env 있다 · 모드 600" \
      || bad "as.env 의 모드가 ${s:-?} 다 (600 이어야 한다 — 남이 읽는다)"
    s=$(stat -c '%U:%G' "$AS_ENV" 2>/dev/null)
    [ "$s" = "root:root" ] || bad "as.env 의 주인이 ${s:-?} 다 (root:root 이어야 한다)"
    for t in DATABASE_URL UPLOADS_DIR PORT; do
      grep -q "^$t=" "$AS_ENV" && bad "as.env 에 $t 가 **있다** — 지우세요(compose 가 넘긴다)"
    done
    # 🔴 견적서 세 줄 — 이 PC 의 사본에는 없고 NAS 에만 있는 그 셋이다.
    say "  🔴 NAS 에만 있는 견적서 세 줄 — 사라지면 [폴더 열기]가 죽는다:"
    for k in $QUOTE_KEYS; do
      grep -q "^$k=" "$AS_ENV" && ok "$k 있다" \
        || bad "$k 가 **없다** — 🔴 누가 as.env 를 덮어썼다. 배포보다 이것이 먼저다"
    done
    # 새 다섯 줄
    build_env_values
    say
    say "  이번에 덧붙일 다섯 줄:"
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
    say "  🔵 호스트 토막은 $ENV_SRC_NOTE 에서 왔다:"
    say "      QUOTE_ARCHIVE_UNC_ROOT     의 호스트 → $ENV_HOST_ROOT"
    say "      QUOTE_ARCHIVE_UNC_ROOT_ALT 의 호스트 → $ENV_HOST_ALT"
    say "      (그 두 줄의 **나머지 부분은 찍지 않는다.** 쓸 것은 호스트뿐이다.)"
    say "  🔵 --go 가 적어 넣을 값 — 눈으로 보고 틀렸으면 멈추세요:"
    for k in $ENV_KEYS; do
      printf '      %s\n' "$(env_line_for "$k")"
    done
    say "  🔴 _UNC_ROOT 는 현황표 폴더의 **바로 위**까지다(.env.example 이 그렇게"
    say "     시킨다 — 도우미가 열 수 있는 범위가 곧 그 루트 아래 전부다)."
    say "  🔴 _FOLDER_PATH 를 **비우면 [폴더 열기]가 꺼진다.** 그래서 「$P_LEAF」가"
    say "     거기 들어간다 — 루트 + FOLDER_PATH = UNC_PATH 가 되게 짰다."
    say "  ⚠️ 값에 따옴표를 두르지 않는다 — 큰따옴표 안에서는 역슬래시가 먹힌다."
    if [ -n "$miss" ] && [ "$MODE" != go ]; then
      say "  🔵 지금은 **아무것도 안 적었다.** 적는 것은 --go 가 한다(4단계)."
    fi
  else
    bad "as.env 가 없다: $AS_ENV"
    say "    → 없는 env_file 하나면 docker compose 명령이 **통째로** 안 먹는다."
  fi
  for f in po.env auth.env meters.env improvements.env leave.env; do
    [ -f "$ENVD/$f" ] || bad "$f 가 없다: $ENVD/$f (compose 가 통째로 실패한다)"
  done

  # ── 1-ㅂ. compose — 태그 하나 · 🔴 건드리지 않는 아홉 · 🔴 새 볼륨 ───
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
  say "  올라가는 하나:"
  see_tag app-as "$TAG_AS" "A/S"
  if [ "$(svc_image "$CF_EFF" app-as)" = "$OLD_AS" ]; then
    say "    🔴 compose 가 아직 **옛 태그**를 가리킵니다. 고치는 길 둘:"
    say "      ㄱ) 개발 PC 에서 새 compose 를 만들어 아래에 올린다(권장):"
    say "           /volume1/dss/setup/incoming/docker-compose.nas.yml"
    say "         --go 가 그 파일을 시험하고 제자리로 옮깁니다."
    say "         🔴 이번엔 **볼륨 한 줄도 함께** 들어갑니다 — sed 로는 못 합니다."
    say "      ㄴ) 손으로 고친다 — 태그만 바꾸는 길입니다. 🔴 그러면 새 공유폴더가"
    say "         안 붙어 [공유폴더에 저장]이 실패로 끝납니다. ㄱ 을 쓰세요."
  fi
  say "  🔴 건드리지 않는 아홉 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-auth            "$KEEP_AUTH"        "포털 · 그대로"
  see_tag tools-as            "$KEEP_ASTOOLS"     "A/S 도구 · 그대로"
  see_tag app-meters          "$KEEP_METERS"      "계측기 · 그대로"
  see_tag tools-meters        "$KEEP_METERSTOOLS" "계측기 도구 · 그대로"
  see_tag app-improvements    "$KEEP_IMP"         "개선요청 · 그대로"
  see_tag tools-improvements  "$KEEP_IMPTOOLS"    "개선요청 도구 · 그대로"
  see_tag app-po              "$KEEP_PO"          "PO/내자 · 🔴 이번엔 그대로"
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
      && ok "$s 에 group_add 가 있다 (공유폴더의 ACL 때문이다)" \
      || bad "$s 에 group_add 가 없다 — 🔴 공유폴더에 Permission denied 가 난다"
  done
  # 🔴 이번 배포의 새 볼륨
  say "  🔴 이번에 새로 붙는 고객사 현황표 공유폴더:"
  svc_block "$CF_EFF" app-as | grep -q "target: $PORTAL_MNT" \
    && ok "app-as 가 $PORTAL_MNT 를 붙인다" \
    || bad "app-as 에 $PORTAL_MNT 가 **없다** — 🔴 [공유폴더에 저장]이 실패로 끝난다"
  svc_block "$CF_EFF" app-as | grep -q "2_AS센터" \
    && ok "원본 경로에 2_AS센터(**대문자 AS**)가 들어 있다" \
    || bad "원본 경로에 2_AS센터 가 없다 — 🔴 소문자(2_as센터)면 빈 폴더가 된다"
  svc_block "$CF_EFF" app-as | grep -q "3. 업체별 수리품현황" \
    && ok "원본 경로가 「3. 업체별 수리품현황」까지 들어간다" \
    || bad "원본 경로가 현황표 폴더까지 들어가지 않는다"
  # PO · tools-as 에는 **일부러 안 붙인다**
  svc_block "$CF_EFF" app-po | grep -q "$PORTAL_MNT" \
    && say "    ⚠️ app-po 에도 $PORTAL_MNT 가 붙어 있다 — PO 에는 이 기능이 없다(없어도 된다)" \
    || ok "app-po 에는 안 붙였다 (맞다 — PO 저장소에 고객 안내 현황이 없다)"
  svc_block "$CF_EFF" tools-as | grep -q "$PORTAL_MNT" \
    && say "    ⚠️ tools-as 에도 붙어 있다 — 쓰는 스크립트가 없다(없어도 된다)" \
    || ok "tools-as 에는 안 붙였다 (맞다 — scripts/ 에 이 폴더를 쓰는 것이 없다)"
  svc_block "$CF_EFF" tools-as | grep -q "$MIGDIR:/app/drizzle" \
    && ok "tools-as 가 $MIGDIR 를 /app/drizzle 로 붙인다 (1-ㄹ 이 세는 그 폴더)" \
    || bad "tools-as 의 drizzle 볼륨이 $MIGDIR 가 아니다"
  svc_block "$CF_EFF" app-as | grep -q "$AS_PORT:3000" \
    && ok "app-as 가 127.0.0.1:$AS_PORT 으로 열린다" \
    || bad "app-as 의 포트가 $AS_PORT:3000 이 아니다"
  AS_DBURL=$(svc_block "$CF_EFF" app-as | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  PO_DBURL=$(svc_block "$CF_EFF" app-po | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  if [ -n "$PO_DBURL" ] && [ "$AS_DBURL" = "$PO_DBURL" ]; then
    ok "app-po 의 DATABASE_URL 이 app-as 와 **글자까지 같다**"
    say "    🔴 그래서 이번 마이그레이션 다섯은 **PO 가 보는 DB 도 바꾼다.**"
    say "       전부 더하기만 하고 PO 의 코드는 그대로라 PO 는 새 칸을 묻지 않는다 —"
    say "       그래서 PO 를 멈추지 않아도 된다."
  else
    bad "app-po 의 DATABASE_URL 이 app-as 와 다르다 — 🔴 PO 가 엉뚱한 DB 를 본다"
  fi

  # ── 1-ㅅ. ② 폴더를 컨테이너 안에서 **실제로 열어 본다** ─────────────
  step "1-ㅅ. 【검사 ④】 폴더 — 주인·모드가 아니라 컨테이너 안에서 실제로 연다"
  say "  🔴 보는 자리가 둘로 갈린다:"
  say "     ㄱ) **이미 붙어 있는 자리**(/data · /templates · /quote-archive)는"
  say "        지금 도는 컨테이너 안에서 본다."
  say "     ㄴ) **이번 배포로 새로 붙는 자리**($PORTAL_MNT)는 도는 컨테이너에"
  say "        아직 없다 — 호스트 경로를 **임시로 붙여** 따로 본다."
  if [ "$PROBE_WRITE" = 1 ]; then
    say "  (교체되는 A/S 의 /data 는 읽기+쓰기를 본다. 시험 파일은 만들었다 지운다.)"
  else
    say "  🔵 --check 라서 **읽기만** 해 본다 — 아무 파일도 만들지 않는다."
    say "     쓰기는 --go 의 3-ㄴ 과 스모크에서 본다."
  fi
  # 호스트 쪽에 그 폴더가 **있는지**부터. 없으면 볼륨이 빈 폴더로 붙는다.
  if [ -d "$PORTAL_SRC" ]; then
    ok "호스트에 현황표 폴더가 있다"
    say "    $PORTAL_SRC"
    n_top=$(ls -1p "$PORTAL_SRC" 2>/dev/null | grep -v '/$' | wc -l | tr -d ' ')
    if [ -d "$PORTAL_SRC/OLD" ]; then s_old="있다"; else s_old="아직 없다 — 앱이 만든다"; fi
    say "    · 맨 위 칸의 파일 ${n_top:-?}개 (앱이 보는 것은 이것뿐이다)"
    say "    · OLD 폴더: $s_old"
  else
    bad "호스트에 현황표 폴더가 **없다**: $PORTAL_SRC"
    say "    → 🔴 「2_AS센터」 의 AS 가 **대문자**인지 보세요. 소문자로 적으면"
    say "       docker 가 **빈 폴더를 만들어 붙입니다** — 저장은 되는데 아무도 못 봅니다."
    say "    눈으로 보는 명령:"
    cmd "ls -d /volume1/2_AS*"
  fi
  # 🔴 **이미 붙어 있는 자리만** 도는 컨테이너에서 본다. 새로 붙는 볼륨은
  #    아래 probe_new_volume 이 임시 컨테이너로 따로 본다 — 까닭은 그 함수 머리말.
  if [ "$PROBE_WRITE" = 1 ]; then M_DATA=rw; else M_DATA=ro; fi
  probe_svc app-as dss-as "A/S" "/data:$M_DATA /templates:ro" "$ATT $TEMPLATES"
  # 🔴 이번 배포로 **새로 붙는** 볼륨. 도는 컨테이너에는 아직 없다.
  probe_new_volume "$PORTAL_SRC" "$PORTAL_MNT" "현황표 공유폴더"
  # 🔴 교체 안 되는 곳 — 「아직 읽히는가」만 본다. 쓰기 시험을 하지 않는다.
  probe_svc app-po           dss-po           PO       "/data:ro"         "$ATT"
  probe_svc app-meters       dss-meters       계측기   "/data:ro"         "$MF_METERS"
  probe_svc app-improvements dss-improvements 개선요청 "/data/uploads:ro" "$UP_IMP"
  # 🔴 견적서 공유폴더는 위 틀에 안 넣는다 — 경로에 빈칸과 괄호가 있고, 무엇보다
  #    여기서는 ACL 을 **걷으면 안 된다**(직원의 탐색기 접근이 끊긴다).
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

  # ── 1-ㅇ. 🔴 야간 백업 · 야간 완전삭제 (읽기만 한다) ─────────────────
  step "1-ㅇ. 야간 백업 다섯 · 야간 완전삭제 (읽기만 한다)"
  say "  🔴 이번엔 마이그레이션이 다섯이다 — **--go 는 오늘 백업이 없으면 멈춘다**(3-ㄱ)."
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
  # 새 tar 약 120MB + 실은 이미지 + dss_as 덤프 + 첨부 하드링크(공간 0).
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (새 tar + 실은 이미지 + 덤프가 들어가야 한다)"
  fi

  # ── 1-ㅊ. 알림 링크의 주소 — A/S 만 ─────────────────────────────────
  step "1-ㅊ. 알림 링크의 주소 (통로가 아니라 **나오는 주소**를 본다)"
  say "  🔴 **A/S 하나만 본다.** PO 에는 알림 통로가 아예 없다(api/integration 폴더가"
  say "     그 저장소에 없다 — 09-29 · 09-30 두 번 실측). 없는 것을 찾지 않는다."
  notify_href_check "A/S" dss-as "$AS_ENV" "https://as.dss21.co.kr"

  # ── 1-ㅋ. 새 이미지 **안에** 이번 판의 표시가 있는가 + public/ocr ────
  step "1-ㅋ. 새 이미지 안을 본다 (태그만으로는 안심 못 한다)"
  say "  🔴 9/21~9/29 에 A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다."
  if have_img "$TAG_AS"; then
    say "  $TAG_AS 구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_AS" --format '{{.Size}}' 2>/dev/null)"
    say "        (1.8 은 $("$DOCKER" images "$OLD_AS" --format '{{.Size}}' 2>/dev/null) — 1.9 가 더 커야 맞다)"
    mark_check "A/S" "$TAG_AS" "$AS_MARK1" "$AS_CTRL"
    mark_check "A/S" "$TAG_AS" "$AS_MARK2" "$AS_CTRL"
    say "  🔴 글자 인식기(public/ocr)가 이미지 안에 들어 있는가:"
    ocr_check "$TAG_AS"
  else
    say "  · $TAG_AS 가 아직 없어 안을 못 봤다 — 먼저:"
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
  echo "DSS 열두째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     되돌리는 것은 **이미지 하나**다:  $TAG_AS → $OLD_AS"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 DB 는 **되돌리지 않는다.** 그대로 둔다.                      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     0106~0110 은 **전부 더하기만** 했다 — 칸 둘 · enum 값 넷 · 표 하나."
  say "     1.8 의 drizzle 은 **자기가 아는 칸만 이름으로 적어 묻는다.** 그래서"
  say "     새 칸이 DB 에 남아 있어도 1.8 은 그것을 보지도 않고 그냥 돈다."
  say "     🔴 되돌리려고 덤프를 되붓는 것이 **오히려 자료를 잃는 길**이다 —"
  say "        덤프 시각 이후에 들어온 접수·작업 기록이 통째로 사라진다."
  say "     (3-ㄷ 에서 뜬 덤프는 「마이그레이션이 DB 를 깨뜨렸을 때」만 쓰는"
  say "      마지막 수단이다. 그때는 Claude 에게 알리고 함께 한다.)"
  say
  say "  ⚠️ 되돌린 뒤에 한 가지가 눈에 띌 수 있다 — 1.9 에서 올린 「통문증」 ·"
  say "     「파라미터」 · 「통전검사」 · 「점검표」 분류의 파일이 1.8 목록에서"
  say "     **분류 이름 없이** 보인다. 그 분류 이름을 1.8 이 모르기 때문이다."
  say "     파일 자체는 멀쩡하다. 1.9 로 다시 올리면 제 이름을 되찾는다."

  step "1. 옛 이미지가 아직 NAS 에 있는지 먼저 본다"
  if have_img "$OLD_AS"; then
    ok "$OLD_AS 있다 ($(img_id "$OLD_AS" | cut -c1-19)…)"
  else
    bad "$OLD_AS 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"
  fi

  step "2. compose 를 되돌린다 — 🔴 사본이 있으면 그것을 쓴다"
  say "  --go 가 옛 compose 를 아래에 남겼다 (가장 최근 것):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -3 | sed 's/^/      /'
  say "  🔴 **사본으로 되돌리는 쪽이 낫다.** sed 로 태그만 내리면 새 볼륨"
  say "     ($PORTAL_MNT)이 그대로 남는데, 1.8 은 그 볼륨을 쓰지 않을 뿐이라"
  say "     당장 문제는 없지만 되돌림이 반쪽이 된다."
  say "  사본으로 되돌리기 — 🔴 아래를 **한 줄씩** 치세요:"
  cmd "cd /volume1/dss/deploy"
  cmd "ls -1t ../backups/docker-compose.nas.yml.* | head -1"
  cmd "cp \$(ls -1t ../backups/docker-compose.nas.yml.* | head -1) ."
  say "      (파일 이름이 길면 위 한 줄 대신 두 줄로 나눠 치세요)"
  say "  태그만 내리는 길 (사본이 없을 때):"
  cmd "F=docker-compose.nas.yml"
  cmd "sed -i 's|$TAG_AS|$OLD_AS|' \$F"
  cmd "grep -n 'image: dss-as' \$F"
  say "      (dss-as-tools:1 은 글자가 겹치지만 위 sed 는 태그까지 붙여"
  say "       갈아 끼우므로 흔들리지 않습니다.)"

  step "3. as.env — 🔴 **되돌릴 필요가 없다**"
  say "  덧붙인 다섯 줄은 1.8 이 **읽지 않는다**(그 코드가 없다). 그대로 두세요."
  say "  그래도 되돌리고 싶다면 사본이 여기 있습니다:"
  ls -1t "$BKD"/as.env.* 2>/dev/null | head -3 | sed 's/^/      /'

  step "4. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-as"
  script_file_hint "16-rollback"

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
echo "DSS 열두째 배포 · 2026-10-02 · $(date '+%F %T')"
echo "  🔴 올라가는 것은 **하나**:  $OLD_AS → $TAG_AS"
echo "  🔴 멈추는 것도 **하나**:  dss-as"
echo "  🔴 이번 판의 핵심 셋: 고객사 현황표(새 공유폴더 + 설정 다섯 줄) ·"
echo "     명판 사진으로 채우기(이미지에 글자 인식기 6.8MB) ·"
echo "     엔지니어가 자기 작업 기록 고치기(마이그레이션 0110)"
echo "  🔴 마이그레이션 **다섯**(0106~0110) — 운영 $N_MIG_HAVE → $N_MIG_WANT. 전부 더하기만 한다"
echo "  · 건드리지 않는 아홉 — $KEEP_AUTH · $KEEP_ASTOOLS · $KEEP_METERS"
echo "    · $KEEP_METERSTOOLS · $KEEP_IMP · $KEEP_IMPTOOLS"
echo "    · $KEEP_PO · $KEEP_LEAVE · $KEEP_LEAVETOOLS"
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**" ;;
  preload)    echo "  🔵 --preload — 새 이미지를 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — 마이그레이션 다섯을 적용하고 A/S 하나만 교체한다."
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
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS" "$SZ_AS" "$MD5_AS"
  if [ -s "$TAR_AS" ] && [ -n "$EXP_AS" ]; then
    bring_img "$TAG_AS" "$TAR_AS" "$EXP_AS"
  else
    bad "$TAG_AS 를 싣지 않았다 — tar 가 없거나 manifest.json 을 못 읽었다"
  fi

  # 🔴 실어 놓고 **안을 본다.** 태그와 지문이 맞아도 「무엇이 든 판인지」는
  #    사람이 읽을 수 있는 증거로 한 번 더 남긴다.
  step "새 이미지 안에 이번 판의 표시가 있는가 · public/ocr 이 들어 있는가"
  if have_img "$TAG_AS"; then
    say "  $TAG_AS 구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
    mark_check "A/S" "$TAG_AS" "$AS_MARK1" "$AS_CTRL"
    mark_check "A/S" "$TAG_AS" "$AS_MARK2" "$AS_CTRL"
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
  if [ "$PERM_PINNED" != 0 ]; then
    echo "  🔴 저장된 권한 값이 작업 기록 수정을 막고 있습니다 — 1-ㄷ 을 읽어 보세요."
    echo "     (✗ 가 아닙니다. 배포는 그대로 진행해도 됩니다.)"
  fi
  if [ "$FAIL" = 0 ]; then
    echo "  ✅ 이어서 (A/S 가 잠깐 멈추고 DB 가 바뀝니다):  bash $0 --go"
    echo "     🔴 --go 는 오늘 백업(dss_as)이 없으면 **시작하자마자 멈춥니다.**"
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
step "2. 새 이미지 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
bring_img "$TAG_AS" "$TAR_AS" "$EXP_AS" || {
  say
  say "  🔴 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
}

# ══ 3. 🔴 멈추기 전에 — 백업 · 공유폴더 쓰기 · 덤프 ════════════════════
#
# 🔴 여기까지가 「돌이킬 수 있는 자리」다. 3-ㄱ 이 백업의 문이고, 3-ㄴ 이
#    「새 폴더에 정말 쓸 수 있나」의 문이다. 둘 다 앱이 **살아 있는 채로** 본다.

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
  say "     이번 배포는 마이그레이션이 **다섯**입니다. 백업 없이 DB 를 바꾸지"
  say "     않습니다. 먼저 이것부터 (종료 코드 0 이어야 합니다):"
  cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  say "     ✓ dss_as 줄이 찍혀야 합니다. 그 뒤에 다시:"
  cmd "bash $0 --go"
  stop "백업 없이 DB 를 바꾸지 않습니다. **DB 도 앱도 그대로입니다.**"
fi

# ── 3-ㄴ. 🔴 새 공유폴더에 **정말 쓸 수 있는가** (07-deploy.sh 2단계) ──
step "3-ㄴ. 【검사 ④】 현황표 공유폴더 쓰기·폴더만들기 시험 (uid 1000 · gid 100)"
say "  🔴 여기는 /volume1/dss 가 아니라 **직원이 탐색기로 쓰는 서류함**이다."
say "     ACL 을 걷지 않는다 — 걷으면 직원의 접근이 끊긴다. 컨테이너가 쓸 수"
say "     있는지만 실제로 해 보고, 안 되면 배포를 멈춘다(앱은 아직 살아 있다)."
if [ ! -d "$PORTAL_SRC" ]; then
  bad "폴더가 없다: $PORTAL_SRC"
  say "    → 🔴 2_AS센터 의 AS 가 **대문자**인지 보세요."
  cmd "ls -d /volume1/2_AS*"
  stop "경로를 확인하세요. **DB 도 앱도 그대로입니다.**"
fi
ok "폴더가 있다"
# compose 의 app-as 와 **같은 조건**으로 시험해야 뜻이 있다 — gid 100(users).
if "$DOCKER" run --rm --group-add 100 -v "$PORTAL_SRC:$PORTAL_MNT" \
     --entrypoint sh "$TAG_AS" -c \
     'set -e; t='"$PORTAL_MNT"'/.dss-write-test; : > "$t"; rm -f "$t";
      d='"$PORTAL_MNT"'/.dss-dir-test; mkdir "$d"; rmdir "$d"' >/dev/null 2>&1; then
  ok "파일을 만들고 지울 수 있다 · 폴더(OLD)를 만들고 지울 수 있다"
else
  bad "현황표 공유폴더에 쓸 수 없다"
  say "    🔴 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기 접근이 끊긴다."
  say "       compose 의 app-as 에 group_add: [\"100\"] 이 있는지부터 보세요."
  say "    → 이 기능만 빼고 배포하려면 as.env 에 다섯 줄을 **안 넣으면** 된다:"
  say "      [공유폴더에 저장] · [미리보기] · [폴더 열기]만 꺼지고 나머지는 그대로."
  stop "앱은 아직 살아 있습니다. **DB 도 그대로입니다.**"
fi
acl_inherit_check "$PORTAL_SRC" "현황표 공유폴더" "$TAG_AS" "$PORTAL_MNT" \
  || stop "앱이 저장해도 직원이 못 여는 파일이 쌓입니다. **아무것도 안 바꿨습니다.**"

# ── 3-ㄷ. 덤프 — 🔴 「마이그레이션이 DB 를 깨뜨렸을 때」의 마지막 수단 ──
#
# 🔴 되돌리기의 **기본 수단이 아니다.** 되돌리기는 이미지만 1.8 로 내리고 DB 는
#    그대로 두는 것이다(--rollback 참조). 이 덤프는 그보다 나쁜 일 —
#    마이그레이션이 중간에 깨져 DB 가 어중간해진 경우 — 을 위한 것이다.
step "3-ㄷ. 적용 직전 덤프 ($AS_DB) · 첨부 하드링크 스냅숏"
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

# ── 3-ㄹ. 🔴 as.env 에 다섯 줄을 덧붙인다 (아직 아무것도 안 멈췄다) ────
#
# 🔴 이 PC 의 as.env 를 올리는 것이 아니다. **NAS 의 파일을 읽고 없는 줄만**
#    덧붙인다. 이미 있으면 건드리지 않는다(두 번 돌려도 안전하다).
step "3-ㄹ. 【검사 ①】 as.env 에 설정 다섯 줄 덧붙이기"
build_env_values
cp -p "$AS_ENV" "$BKD/as.env.$STAMP"; chmod 600 "$BKD/as.env.$STAMP"
ok "as.env 사본 — backups/as.env.$STAMP (root 600)"
# 🔴 견적서 세 줄이 그대로 있는지 **적기 전에** 한 번 더 본다.
for k in $QUOTE_KEYS; do
  grep -q "^$k=" "$AS_ENV" || {
    bad "$k 가 as.env 에 없다 — 🔴 누가 덮어썼다"
    stop "as.env 가 온전하지 않습니다. 덧붙이지 않았습니다. **DB 도 앱도 그대로입니다.**"
  }
done
ok "견적서 세 줄이 그대로 있다 — 덧붙여도 안전하다"
# 파일이 개행으로 끝나지 않으면 먼저 한 줄 띄운다(마지막 줄에 붙어 버린다).
[ -n "$(tail -c 1 "$AS_ENV")" ] && printf '\n' >> "$AS_ENV"
ADDED=0
for k in $ENV_KEYS; do
  if grep -q "^$k=" "$AS_ENV"; then
    say "  · $k 는 **이미 있다** — 건드리지 않는다"
    continue
  fi
  [ "$ADDED" = 0 ] && {
    printf '\n# ── 고객사 현황표(업체별 수리품현황) 공유폴더 — %s 16-deploy.sh 가 덧붙임 ──\n' \
      "$TODAY" >> "$AS_ENV"
  }
  printf '%s\n' "$(env_line_for "$k")" >> "$AS_ENV"
  ADDED=$((ADDED + 1))
  ok "$k 덧붙였다"
done
chown root:root "$AS_ENV"; chmod 600 "$AS_ENV"
if [ "$ADDED" = 0 ]; then
  ok "다섯 줄이 모두 이미 있었다 — as.env 를 한 글자도 안 바꿨다"
else
  ok "$ADDED 줄을 덧붙였다 (모드 600 · root:root 로 되돌렸다)"
fi
# 🔴 다섯 줄은 **폴더 경로**다 — 비밀이 아니고, 사람이 눈으로 맞춰 봐야 하는
#    값이라 그대로 찍는다. as.env 의 다른 줄은 한 글자도 찍지 않는다.
say "  지금 as.env 에 들어 있는 다섯 줄 (값까지 그대로):"
for k in $ENV_KEYS; do
  printf '      %s\n' "$(grep "^$k=" "$AS_ENV" | head -1)"
done
say "  🔴 호스트 토막의 출처: $ENV_SRC_NOTE"

# ── 3-ㅁ. 🔴 마이그레이션 파일을 제자리에 놓는다 ───────────────────────
#
# 🔴 .sql 다섯만이 아니라 meta/_journal.json 과 snapshot 다섯까지 함께 간다.
#    그래서 폴더를 **통째로** 갈아 끼운다(10-deploy.sh 1-ㅂ 과 같은 길).
step "3-ㅁ. 【검사 ②】 마이그레이션 파일 놓기 ($MIGDIR)"
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
  say "  · incoming 에 tar 가 없다 — 폴더가 이미 새것인지 아래에서 본다"
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
[ -z "$MISS" ] && ok "0106~0110 의 .sql 과 snapshot 이 다 있다" || bad "빠진 것:$MISS"
[ "$FAIL" = 0 ] || stop "마이그레이션 파일이 온전하지 않습니다. **DB 도 앱도 그대로입니다.**"

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

# ══ 4. 적용 전 확인 (db:preflight) — 🔴 앱은 **아직 1.8 로 살아 있다** ═══
#
# ── 🔴 왜 앱을 먼저 멈추지 않는가 (10-deploy.sh 와 다른 자리다) ───────────
#
#   10-deploy.sh 는 **멈추고 → 덤프 → migrate → up** 이었다. 그래야 했던
#   까닭은 그 판의 0103·0104 가 **자료를 지우는** 마이그레이션이었기 때문이다
#   (DELETE 로 합치기 · DROP TABLE). 지우는 동안 앱이 쓰고 있으면 지운 자리에
#   새 줄이 끼어든다.
#
#   🔴 이번 다섯은 **전부 더하기만** 한다. 그리고 1.8 의 drizzle 은 **자기가
#      아는 칸만 이름으로 적어 묻는다** — 새로 생긴 칸을 보지도 않는다.
#      0108 의 form_values 는 NOT NULL 이지만 DEFAULT 가 있어 1.8 의 INSERT 도
#      그대로 통과한다. 그래서 적용하는 동안 1.8 이 돌아도 안전하다.
#
#   그래서 차례를 이렇게 둔다:
#      4~5) 마이그레이션을 **앱이 살아 있는 채로** 적용한다 (직원은 못 느낀다)
#        6) 그 다음에 이미지를 바꿔 끼운다 ⏱ 이것 하나가 정지 창이다 (약 20초)
#   얻는 것 둘:
#     · 정지 창이 **1~2분에서 20초로** 줄어든다(15번이 18초였다).
#     · 🔴 마이그레이션이 깨져도 **직원은 1.8 을 그대로 쓰고 있다.** 멈춰
#       놓고 깨지면 다시 띄울 이미지를 고르는 일이 사람 손에 떨어진다.
#   🔴 **차례(마이그레이션 → 코드)는 13·10번과 같다.** 거꾸로 하면 1.9 가 아직
#      없는 칸(form_values · original_modified_at)을 묻다 그 화면에서 죽는다.
#      그리고 둘 사이에 사람이 쉬어 가는 자리를 두지 않는다 — 머리말 ④.
step "4. 적용 전 확인 — db:preflight  (🔴 앱은 아직 1.8 로 살아 있다)"
say "  🔴 이번 다섯은 **지우는 문장이 하나도 없다**(DROP · DELETE · TRUNCATE 없음)."
say "     그러니 「사라질 자료가 있는 항목」이 나오면 그것이 신호다 — 멈춘다."
"${COMPOSE[@]}" run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | sed 's/^/    /'
PRC=${PIPESTATUS[0]}
say "  (종료 코드 $PRC — 기대 0)"
if [ "$PRC" != 0 ]; then
  bad "db:preflight 가 0 이 아니다 ($PRC) — 사라질 자료가 있다는 뜻이다"
  say "    → 🔴 이번 다섯에는 그럴 문장이 없다. **다른 것이 섞였다.**"
  stop "마이그레이션을 시작하지 않았습니다. **DB 도 앱도 그대로이고 직원은 1.8 을 쓰고 있습니다.**"
fi
N_BEFORE=$(qas "select count(*) from drizzle.__drizzle_migrations")
say "  · 적용 전 DB 의 마이그레이션 줄: ${N_BEFORE:-?}  (기대 $N_MIG_HAVE)"
say
say "  🔴 이제 DB 를 바꿉니다. 그만두려면 **20초 안에 Ctrl+C**."
say "     지금 Ctrl+C 하면 DB 도 앱도 손대지 않은 채로 남습니다."
say "     (as.env 와 compose · 마이그레이션 파일은 이미 바뀌었지만, 그 셋만으로는"
say "      아무 일도 일어나지 않습니다 — 1.8 은 그것을 읽지 않습니다.)"
sleep 20

# ══ 5. 🔴 마이그레이션 적용 — 앱은 아직 1.8 로 살아 있다 ═══════════════
step "5. 마이그레이션 적용 (0106 ~ 0110)  🔴 여기서 DB 가 바뀐다"
say "  전부 더하기만 한다 — enum 값 넷 · 칸 둘 · 표 하나."
say "  🔴 다시 돌려도 안전하다. drizzle 은 이미 적용된 것을 건너뛴다."
say "  🔵 도는 동안 직원은 **1.8 을 그대로 쓰고 있다.** 아직 안 멈췄다."
"${COMPOSE[@]}" run --rm "$AS_TOOLS_SVC" npm run db:migrate 2>&1 | sed 's/^/    /'
rc=${PIPESTATUS[0]}
if [ "$rc" = 0 ]; then
  ok "db:migrate 끝 (종료 코드 0)"
else
  bad "db:migrate 실패 (종료 코드 $rc)"
  say "    ╔══════════════════════════════════════════════════════════════╗"
  say "    ║ 🔵 **직원은 아직 1.8 을 그대로 쓰고 있습니다.** 안 멈췄습니다.  ║"
  say "    ╚══════════════════════════════════════════════════════════════╝"
  say "    🔴 **새 이미지를 띄우지 않습니다.** 1.9 는 없는 칸을 묻다 죽습니다."
  say "    🔴 compose 는 이미 $TAG_AS 를 가리키고 있으니, 누가 up -d 를 부르면"
  say "       1.9 가 올라옵니다 — 부르지 마세요."
  say "    → 고친 뒤 **다시 돌리면 됩니다**(이미 적용된 것은 건너뜁니다):"
  cmd "bash $0 --go"
  say "    → 오늘은 그만두려면 compose 를 1.8 로 되돌려 두세요. 아래가 그"
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
# 🔴 「했다」가 아니라 「들어 있다」를 본다 — 0110 의 표와 0108 의 칸을 직접 센다.
say "  🔴 SQL 로 직접 센다 (「했다」가 아니라 「들어 있다」를 본다):"
T0110=$(qas "select to_regclass('public.repair_case_work_record_edits')")
[ -n "$T0110" ] && ok "0110 · repair_case_work_record_edits 표가 생겼다" \
  || bad "0110 의 표가 **없다**"
C0108=$(qas "select count(*) from information_schema.columns where table_name='repair_case_customer_status' and column_name='form_values'")
[ "${C0108:-0}" = 1 ] && ok "0108 · repair_case_customer_status.form_values 칸이 생겼다" \
  || bad "0108 의 칸이 **없다** — 🔴 고객 안내 동기화가 계속 멈춰 있다"
C0107=$(qas "select count(*) from information_schema.columns where table_name='attachments' and column_name='original_modified_at'")
[ "${C0107:-0}" = 1 ] && ok "0107 · attachments.original_modified_at 칸이 생겼다" \
  || bad "0107 의 칸이 **없다**"
E_NEW=$(qas "select count(*) from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = 'attachment_category' and e.enumlabel in ('PARAMETER','POWER_TEST','CHECKLIST','PASS_SLIP')")
[ "${E_NEW:-0}" = 4 ] && ok "0106·0109 · attachment_category 에 새 값 넷이 들어갔다" \
  || bad "attachment_category 의 새 값이 넷이 아니다 (${E_NEW:-?})"
[ "$FAIL" = 0 ] || stop "DB 가 기대한 상태가 아닙니다. 직원은 **아직 1.8 을 쓰고 있습니다.** 적용 직전 덤프: $BK/$AS_DB.dump"

# ══ 6. A/S 를 새 판으로 바꿔 끼운다 — 🔴 여기 하나가 정지 창이다 ═══════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다(포털·계측기까지 흔들린다).
#    --no-deps 로 **이름을 적은 하나만** 부른다.
# 🔴 따로 stop 하지 않는다. up -d 가 옛 컨테이너를 지우고 새것을 올리는 한
#    걸음이라, 나눠 부르면 그 사이만큼 정지 창이 길어진다(15번이 18초였다).
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
step "7. 스모크 — 폴더 · 설정 · 알림 · 🔴 권한 · 안 멈췄는가 · 바깥 주소"

# 7-ㄱ. 새 컨테이너로 폴더를 **실제로 열어 본다** (쓰기 · 폴더 만들기까지)
say "  7-ㄱ. 폴더를 새 컨테이너 안에서 실제로 연다"
probe_svc app-as dss-as "A/S" "/data:rw /templates:ro $PORTAL_MNT:rwd" \
          "$ATT $TEMPLATES"
say "  7-ㄴ. 견적서 공유폴더 (A/S 가 발행할 자리)"
if running dss-as; then
  "$DOCKER" exec dss-as sh -c 'set -e; t=/quote-archive/.dss-write-test; : > "$t"; rm -f "$t"' >/dev/null 2>&1 \
    && ok "A/S 가 견적서 공유폴더에 쓸 수 있다" \
    || { bad "A/S 가 견적서 공유폴더에 못 쓴다 — 발행이 Permission denied 로 끝난다"
         say "    🔴 여기는 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기가 끊긴다."; }
else
  bad "dss-as 컨테이너가 떠 있지 않다"
fi

# 7-ㄷ. 🔴 새 컨테이너가 설정 다섯을 **실제로 들고 있는가**
say "  7-ㄷ. 🔴 새 컨테이너 안에서 설정 다섯이 보이는가 (값은 안 찍는다)"
for k in $ENV_KEYS; do
  v=$("$DOCKER" exec dss-as printenv "$k" 2>/dev/null | tr -d '\r')
  if [ -n "$v" ]; then
    ok "$k 가 컨테이너 안에 있다 (${#v}자)"
  else
    bad "$k 가 컨테이너 안에 **없다** — env_file 이 안 읽혔다"
  fi
done
# 🔴 역슬래시가 삼켜졌는지 — UNC 값에 역슬래시가 넷 이상 있어야 맞다.
v=$("$DOCKER" exec dss-as printenv CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT 2>/dev/null)
n=$(printf '%s' "$v" | tr -cd '\\' | wc -c | tr -d ' ')
[ "${n:-0}" -ge 4 ] && ok "UNC_ROOT 의 역슬래시가 ${n}개 — 삼켜지지 않았다" \
  || bad "UNC_ROOT 의 역슬래시가 ${n:-0}개뿐이다 — 🔴 따옴표가 먹은 것이다"
# 🔴 컨테이너 안 경로가 실제로 그 폴더인가
"$DOCKER" exec dss-as sh -c "[ -d \"\$CUSTOMER_PORTAL_ARCHIVE_DIR\" ]" >/dev/null 2>&1 \
  && ok "CUSTOMER_PORTAL_ARCHIVE_DIR 이 **실제로 있는 폴더**를 가리킨다" \
  || bad "CUSTOMER_PORTAL_ARCHIVE_DIR 이 가리키는 폴더가 컨테이너 안에 없다"

say "  7-ㄹ. 알림 통로 — 포털이 묻는 자리 (A/S 만)"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 \
       "http://127.0.0.1:$AS_PORT/api/integration/notifications" 2>/dev/null)
case "$code" in
  404) bad "A/S 의 /api/integration/notifications 가 404 다 — **옛 이미지다**" ;;
  000|"") bad "A/S 의 알림 통로가 대답하지 않는다 (${code:-없음})" ;;
  *)   ok "A/S 의 알림 통로가 있다 (토큰 없이 부르면 401 이 맞다 — 지금 $code)" ;;
esac
say "  7-ㅁ. 🔴 알림 링크의 주소 — 새로 뜬 컨테이너로 다시 본다"
notify_href_check "A/S" dss-as "$AS_ENV" "https://as.dss21.co.kr"

say "  7-ㅂ. 🔴 작업 기록 수정 권한 — 교체 뒤에 다시 본다 (select 만)"
perm_check

# 7-ㅅ. 🔴 건드리지 않는 쪽이 **정말 안 멈췄는가** — 시작 시각으로 본다
say "  7-ㅅ. 🔴 건드리지 않는 쪽이 안 멈췄는가 (시작 시각을 대조한다)"
for t in $KEEP_BOXES; do
  before=$(printf '%s\n' "$STARTED_BEFORE" | sed -n "s/^$t=//p" | head -1)
  after=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  if [ -n "$before" ] && [ "$before" = "$after" ]; then
    ok "$t · 시작 시각 그대로 — **한 번도 안 멈췄다**"
  else
    bad "🔴 $t 의 시작 시각이 바뀌었다 ($before → $after) — 이 배포가 건드렸다"
  fi
done

say "  7-ㅇ. 바깥 주소 여섯"
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
if [ "$PERM_PINNED" != 0 ]; then
  echo
  echo "🔴 저장된 권한 값이 작업 기록 수정을 막고 있습니다."
  echo "   **배포는 잘 끝났지만 엔지니어에게는 아직 안 열립니다.**"
  echo "   A/S → [사용자 관리] → [역할별 접근 권한] → AS_ENGINEER 줄에서"
  echo "   「전체 A/S 현황」의 작업 기록 칸을 쓰기 이상으로 올리고 저장하세요."
fi
cat <<ANNOUNCE

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. 🔴 **고객사 현황표** — 이번 판의 절반이 이것입니다.
      · [고객 안내 현황]에 **고객사 양식 표**가 보입니까.
      · [엑셀 미리보기]를 눌러 보세요 — 표가 그대로 뜹니까.
      · [공유폴더에 저장]을 누르고 **그 엑셀을 실제로 열어 보세요.**
        🔴 「저장했습니다」만 보고 넘어가지 마세요. 파일이 열려야 끝입니다.
      · 같은 날 **두 번** 저장해 보세요 — 「덮어썼습니다」라고 말해야 맞습니다
        (파일이 하나만 남습니다. 「 (2)」 가 붙으면 옛 코드입니다).
      · 어제 날짜 파일이 있었다면 **OLD 폴더로 옮겨졌는지** 보세요.
      · [폴더 열기]를 누르세요. 🔴 도우미를 **다시 설치**해야 합니다
        (화면이 그렇게 안내합니다). 설치 뒤 탐색기가 「3. 업체별 수리품현황」
        에서 열려야 맞습니다.
      · 🔴 **PO 사이트에서는 도우미를 다시 설치하지 마세요.** PO 는 이번에
        안 올라가서 현황표 루트를 모릅니다 — 거기서 설치하면 그 PC 의
        현황표 [폴더 열기]만 다시 먹통이 됩니다(견적서는 그대로 됩니다).
   2. **명판 사진으로 채우기** (A/S 접수 화면):
      · 명판 사진을 올리면 Model · L/N · S/N 이 채워집니까.
      · QR 이 없는 명판으로도 해 보세요 — 네모를 치면 그 안만 읽습니다.
      · 🔴 처음 한 번은 **글자 인식기를 받느라 몇 초 걸립니다.** 멈춘 것이
        아닙니다. 사진은 밖으로 나가지 않습니다 — 브라우저 안에서 읽습니다.
   3. 🔴 **엔지니어 계정으로** 로그인해 작업 기록을 고쳐 보세요:
      · 수리 건 상세 → [작업 이력] 탭 → **자기가 쓴** 기록에 수정이 됩니까.
      · 고친 뒤 「수정됨」과 마지막 수정 사람·시각이 붙습니까.
      · 이전 글을 펼쳐 볼 수 있습니까.
      · 🔴 **남이 쓴 기록은 고칠 수 없어야 맞습니다** — 관리자도 마찬가지입니다.
      · 🔴 무효 처리는 여전히 관리자 이상이어야 맞습니다.
      · [작업내용] 탭은 **안 바뀐 것이 맞습니다**(새로 남기는 자리입니다).
   4. **통문증** — 수리 건 파일에 「통문증」 분류가 보입니까.
      사진을 올리면 통문번호 · PRV No. · Q코드를 읽어 주성 양식 표를 채웁니까.
      🔴 서류가 어긋나면 **불러오지 않는 것이 맞습니다.**
   5. 제품 모델 — 파라미터 · 통전검사 · 점검표를 올릴 수 있습니까.
      파일 목록에 「원본 수정일」이 올린 날짜 옆에 보입니까.
   6. 🔴 **포털 · 계측기 · 개선요청 · PO · 휴가가 그대로입니까** — 이번 판은
      그 다섯을 건드리지 않았습니다. 이상하면 남의 변경이 섞인 것입니다.
      (스크립트가 7-ㅅ 에서 시작 시각으로 이미 확인했습니다.)

🔴 사람이 이어서 할 일:
  · 직원에게 알립니다 — 「고객사 현황표를 엑셀로 내보낼 수 있다」 ·
    「엔지니어가 자기 작업 기록을 고칠 수 있다」.
  · [폴더 열기]를 쓰는 PC 는 **도우미를 다시 설치**해야 합니다.
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.
  · 내일 아침 백업을 한 번 더 보세요 — 다섯이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -7
  · 적용 직전 덤프는 $BK 에 있습니다. 한 주쯤 두었다 지우세요.

되돌리기 안내:  bash $0 --rollback
  🔴 되돌려도 **DB 는 그대로 둡니다** — 더하기만 한 변경이라 1.8 이 새 칸을
     모른 채 그냥 돕니다. 덤프를 되붓지 마세요(그 뒤의 일이 사라집니다).
ANNOUNCE
exit "$FAIL"
