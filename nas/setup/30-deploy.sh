#!/bin/bash
# /volume1/dss/setup/30-deploy.sh — 2026-10-19 서른째 배포
#
# ══ 무엇이 올라가는가 — **둘** ════════════════════════════════════════
#
#     A/S   dss-as:2.7  →  **dss-as:2.8**   (RF_Service_System  2812d40)
#     PO    dss-po:0.5  →  **dss-po:0.6**   (dss-po             696c6a0)
#
#   두 저장소 다 2026-10-19 기준 **미커밋 0줄**이다(굽기 전에 확인했다).
#   🔴 멈추는 것은 **dss-as 와 dss-po 둘**이다. 🔵 안 멈추는 여섯 —
#      포털 · 계측기 · 개선요청 · 휴가 · 게시판 · 재고 관리(DB 둘도 안 멈춘다).
#
# ══ 🔴 이 배포가 하는 일 — **여섯** ═══════════════════════════════════
#
#   ① 이미지 교체 둘                     dss-as:2.8 · dss-po:0.6
#   ② 마이그레이션 **둘**                0116 · 0117  (116 → **118**)
#   ③ 양식 **네 장** 넣기                $TEMPLATES 에 7장 → **11장**
#   ④ compose 에 **네 줄** 더하기        app-as 의 environment: 절
#   ⑤ 설정 **넷** 적기                   as.env 한 줄 · po.env 세 줄
#   ⑥ 🔴 올리는 순서 — **A/S 먼저**, 대답을 확인한 뒤에 PO
#
#   🔵 22번(열여덟째)을 틀로 삼았다 — 절 구성 · 말투 · ok/bad/say/step ·
#      기본값이 점검 모드 · 백업 · 되돌리기 안내 · 마지막 요약표가 전부 그 파일의
#      방식이다. 경로 상수와 qas() 는 29번에서 가져왔다. 마이그레이션 절은
#      28번(스물두째)의 방식 그대로다 — 그 판이 A/S 0115 를 그렇게 올렸다.
#
# ══ 🔴 ⑥ 왜 A/S 가 먼저인가 — 한 방향으로만 부른다 ═══════════════════
#
#   PO 0.6 의 「내자 정리 완료 처리/해제」가 A/S 의 **새 쓰기 통로**를 부른다:
#       POST /api/v1/domestic-orders/{id}/completion
#   A/S 가 아직 2.7 이면 그 통로가 **없어서 404** 다. 거꾸로 A/S 가 PO 를
#   부르는 길은 **없다**(확인했다).
#   → 그래서 up -d 를 **한 번에 둘** 부르지 않는다. app-as 를 올리고 대답을
#     받은 **뒤에** app-po 를 올린다. 22번은 둘을 한 번에 불렀다 — 이번 판은
#     거기서 일부러 갈라졌다. 정지 창이 그만큼 길어지는 것은 **받아들인다.**
#
# ══ 🔴 ② 마이그레이션 둘 — 116 → 118 ═════════════════════════════════
#
#   0116_customer_portal_form_id.sql
#     · customers 에 널 허용 text 칸 portal_form_id 를 더한다
#     · 지금 아는 이름 열하나로 기존 줄을 채운다(UPDATE 셋)
#     · 🔴 **지우는 문장 0줄.** 칸을 더하는 쪽이라 옛 판(2.7 · 0.5)이 깨지지
#        않는다 — drizzle 의 select() 는 칸 이름을 적어서 묻는다.
#   0117_shipment_completed_allow_engineer_sales.sql
#     · workflow_transitions.allowed_roles 에 AS_ENGINEER · SALES 를
#       **더하기만** 한다(DISTINCT 로 합친다. 기존 역할은 하나도 안 뺀다)
#     · 🔴 **지우는 문장 0줄.** 그러나 **인가 경계를 넓히는 변경**이다.
#
#   🔴 운영의 역할 분포는 개발과 다르다 (2026-10-19 02:48 실측):
#        {SUPER_ADMIN,ADMIN,AS_ENGINEER}        19줄
#        {SUPER_ADMIN,ADMIN,INVENTORY_MANAGER}   9줄
#        {SUPER_ADMIN,ADMIN}                     4줄
#        ─────────────────────────────────────  합 **32줄** (개발은 22줄)
#      셋 중 **SALES 가 든 줄이 하나도 없다** — 32줄 전부가 UPDATE 를 맞는다.
#      적용 뒤 **32줄 모두**가 두 역할을 갖는지 세어 확인한다(0 → 32).
#
#   🔴 되돌리기는 **이미지만** 되돌린다. 이 둘은 되감지 않는다 —
#      0117 을 거꾸로 돌리려면 「원래 AS_ENGINEER 가 있던 19줄」과 「이번에
#      생긴 줄」을 갈라야 하는데, 그 구분은 적용 뒤에는 DB 에 남지 않는다.
#      --migrate 가 **적용 전 분포를 로그에 적어 둔다.** 되돌릴 일이 생기면
#      그 로그를 보고 사람이 SQL 을 짠다. 🔴 스크립트는 짜 주지 않는다.
#
#   🔴 **적용은 --go 가 아니라 --migrate 가 한다.** 명령을 나눈 까닭은 28번과
#      같다 — 마이그레이션이 덜 된 DB 에 2.8 이 뜨면 없는 칸을 읽다 죽는다.
#
# ══ 🔴 ③ 양식 네 장 — 기존 두 장은 **손대지 않는다** ═════════════════
#
#   매쳐 건과 제너레이터 건은 **담당 엔지니어가 다르고 양식에 그 사람의 도장이
#   박혀 있다.** 둘이 같은 파일을 읽는 동안 매쳐 건 보고서에 제너레이터
#   담당자의 도장이 찍혀 나갔다. 2.8 이 그것을 가른다.
#     검사보고서_매쳐.xlsx · 검사보고서_제너레이터.xlsx
#     수리보고서_매쳐.xlsx · 수리보고서_제너레이터.xlsx
#   🔴 **기존 검사보고서.xlsx · 수리보고서.xlsx 두 장은 그대로 둔다**
#      (2026-10-19 사용자 결정). 코드가 제품 종류를 모를 때 물러서는 자리다 —
#      그 둘을 지우면 물러설 자리가 사라진다.
#   🔵 넣는 방식은 21번 1313~1324줄 그대로다 — 기존 파일의 주인·모드를 읽어
#      .new 로 복사 → chown/chmod → mv -f → md5 재확인. 이번엔 새 파일이라
#      **치워 둘 원본이 없다.** 주인·모드는 같은 폴더의 짝 파일에서 읽는다.
#   🔵 폴더가 dr-x------ 1000:1000 이라 평소엔 못 쓰지만 이 스크립트는 root 로
#      도니 쓴다. 🔴 폴더의 모드를 고치지 않는다.
#
# ══ 🔴 ④ compose 네 줄 — **저장소 사본을 올리지 않는다** ═════════════
#
#   🔴 이 저장소의 nas/docker-compose.nas.yml 은 **낡았다** — dss-as:2.5 라고
#      적혀 있고(운영은 2.7) app-inventory 블록이 아직 주석이다(27번이 NAS 에서
#      벗겼다). 올리면 **재고 관리가 compose 에서 통째로 사라진다.**
#   → 그래서 이 스크립트가 **NAS 의 파일($CF)을 제자리에서** 고친다:
#        ㄱ) image: dss-as:2.7 → 2.8   (한 줄)
#        ㄴ) image: dss-po:0.5 → 0.6   (한 줄)
#        ㄷ) app-as 의 environment: 절에 **일곱 줄**(주석 셋 + 설정 넷)을
#            INSPECTION_REPORT_TEMPLATE_PATH **바로 앞**에 넣는다
#      · 고치기 **전에** 사본을 뜬다(backups/docker-compose.nas.yml.<도장>)
#      · 줄 수가 **정확히 7줄 늘어야** 한다
#      · image: 줄 **전체 목록**을 고치기 전후로 견준다 — 달라진 것이 위 둘뿐
#        이어야 한다(건드리지 않는 쪽의 태그를 **박아 두지 않는다.** 박아 두면
#        기준이 낡는 날 멀쩡한 배포가 막힌다)
#      · 고친 뒤 compose config -q. 깨졌으면 **사본으로 되돌리고 멈춘다**
#   🔴 PO(app-po)에는 그 네 줄을 넣지 않는다 — 검사·수리 보고서는 A/S 의 것이다.
#   🔴 들여쓰기는 **공백 6칸**이다(같은 절의 다른 줄과 맞춘다).
#
# ══ 🔴 ⑤ 설정 넷 — 토큰은 **화면에 찍지 않는다** ═════════════════════
#
#   as.env 한 줄
#     AS_WRITE_TOKEN       🔴 **스크립트가 새로 만든다** (openssl rand -base64 36
#                          · 48자 · 기존 AS_API_TOKEN 과 같은 형식).
#                          🔴 값을 한 글자도 안 찍는다 — 「만들었습니다(48자)」까지.
#   po.env 세 줄
#     AS_WRITE_TOKEN       🔴 **as.env 와 같은 값**이어야 한다. 다르면 401 이다
#     INVENTORY_API_BASE_URL   🔴 **as.env 에서 그대로 복사**한다
#     INVENTORY_API_TOKEN      🔴 **as.env 에서 그대로 복사**한다
#
#   🔵 재고 쪽 읽기 토큰은 여러 시스템이 나눠 쓴다(그쪽 src/lib/api/auth.ts 의
#      주석). 새로 발급할 까닭이 없다. 🔴 PO 는 **읽기만** 한다 —
#      INVENTORY_WRITE_TOKEN 은 **넣지 않는다**(PO 저장소의 시험이 그것을 지킨다).
#   🔵 as.env 에 그 두 줄이 있는 것은 2026-10-19 03:0x 에 실측으로 확인했다
#      (둘 다 1줄). 🔴 그래도 preflight 의 「없으면 멈춘다」 문은 **안 닫는다** —
#      지금 있다는 것이 배포 시점에도 참이라는 보장은 아니고, 문은 공짜다.
#   🔴 .env 는 같은 이름이 둘이면 **나중 것이 이긴다** — 조용히 어긋난다.
#      그래서 이미 줄이 있으면 **덧붙이지 않는다.** 값이 같으면 통과, 다르면
#      멈춘다(덮어쓰지 않는다). 고치기 전에 두 파일의 사본을 뜬다.
#
# ══ 🔴 돌리기 전에 — **값 여섯은 채워져 있다** ════════════════════════
#
#   🔵 2026-10-19 에 개발 PC 에서 굽고 재어 채웠고, **NAS 에서 다시 쟀다**:
#        SZ_AS  132020224  MD5_AS  353c41296381c313c6a1e7ae55534026
#        SZ_PO   95434240  MD5_PO  37f39ae2dea773173362644fbd0d631a
#      WANT_CFG_AS 는 docker build 로그의 「exporting config sha256:」 과
#      글자까지 같다(교차 확인). 🔴 tar_config_id() 가 내는 꼴에 맞추려고
#      **sha256: 를 붙인 모양**으로 적는다.
#   🔴 하나라도 비면 --check 는 ⚠️ 로만 말하고 **--migrate 도 --go 도 시작하지
#      않는다.** 잰 적 없는 이미지를 운영에 올리지 않는다. 지금은 여섯 다 찼다.
#   🔴 tar 가 이미지의 1/4 쯤인 것은 **정상**이다 — dss-as:2.8 은 이미지 599MB
#      에 tar 132,020,224 바이트다. 지난 판과 견주세요:
#        dss-as  2.4 → 131,237,888 · 2.6 → 131,566,592 · 2.7 → 131,561,472
#        dss-po  0.4 →  95,424,000 · 0.5 → (잰 값 없음) · **0.6 → 95,434,240**
#      크게 달라졌으면 **그쪽을 먼저 의심한다.**
#   🔴 tar 안 Config 지문은 개발 PC 의 {{.Id}} 와 **다르다.** NAS 는 tar 안의
#      config 지문을 image ID 로 낸다 — 맞춰 볼 값은 **tar 쪽**이다.
#
#   다시 구워야 한다면 (개발 PC · PowerShell · 폴더는 Development):
#
#     cd C:\Users\희만\Desktop\Development\RF_Service_System
#     git status --short                      ← **비어 있어야 한다**
#     docker build -t dss-as:2.8 .
#     cd ..\dss-po
#     git status --short
#     docker build -t dss-po:0.6 .
#     cd ..
#     docker save dss-as:2.8 -o dss-as-2.8.tar
#     docker save dss-po:0.6 -o dss-po-0.6.tar
#     (Get-Item dss-as-2.8.tar).Length             ← SZ_AS
#     Get-FileHash -Algorithm MD5 dss-as-2.8.tar   ← MD5_AS (소문자로 적는다)
#     tar -xOf dss-as-2.8.tar manifest.json        ← Config 의 sha256 → WANT_CFG_AS
#     (PO 도 같은 세 줄)
#
#   🔴 **git archive 로 뽑지 마라** — 서브모듈 vendor/dss-ui · vendor/dss-core 가
#      빈 폴더로 나와 빌드가 깨진다. 작업 폴더에서 굽되 git status 가 비어야 한다.
#   🔴 docker save 는 분류기가 막는 일이 있다 — **사람이 직접 친다.**
#
# ══ 🔴 개발 PC → NAS 로 올릴 것 ═══════════════════════════════════════
#
#   🔵 2026-10-19 기준 **이미 올라가 있는 것 여섯** (크기·md5 대조 완료):
#        /volume1/dss/images/dss-as-2.8.tar
#        /volume1/dss/images/dss-po-0.6.tar
#        /volume1/dss/setup/incoming/검사보고서_매쳐.xlsx
#        /volume1/dss/setup/incoming/검사보고서_제너레이터.xlsx
#        /volume1/dss/setup/incoming/수리보고서_매쳐.xlsx
#        /volume1/dss/setup/incoming/수리보고서_제너레이터.xlsx
#
#   🔴 **아직 확인되지 않은 것 하나 — 마이그레이션 묶음.**
#      A/S 의 drizzle/ 은 이미지 안이 아니라 **볼륨**에서 돈다:
#          /volume1/dss/as-migrations → tools-as 의 /app/drizzle (읽기 전용)
#      그 폴더가 아직 116 이면 0116 · 0117 을 **적용할 수가 없다**(drizzle 은
#      meta/_journal.json 에 없는 .sql 을 아예 모른다). 이 스크립트가 먼저
#      세어 보고, 116 이면 아래 묶음을 찾는다:
#          /volume1/dss/setup/incoming/as-migrations.tar.gz
#      없으면 **멈춘다.** 만들어 올리는 차례 (개발 PC · PowerShell):
#
#        cd C:\Users\희만\Desktop\Development\RF_Service_System
#        tar -czf ..\as-migrations.tar.gz drizzle
#        cd ..
#        scp -O as-migrations.tar.gz dss-nas:/volume1/dss/setup/incoming/
#
#      🔴 tar 에 C:\… 같은 **드라이브 문자를 주지 마라** — 원격 호스트로 읽는다.
#         위처럼 **상대경로**로 친다.
#      🔵 폴더가 이미 118 이면 올릴 것이 없다. 스크립트가 그렇게 말해 준다.
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#   🔵 scp 가 바로 안 되면 사용자 계정(swhur)의 홈으로 올린 뒤 NAS 에서
#      sudo mv 로 옮긴다. /volume1/dss 아래는 root 만 쓸 수 있다.
#
# ══ DSM 터미널은 긴 명령을 잘라 먹는다 ════════════════════════════════
#   NAS 에서 돌릴 것은 **파일로 올리고 md5 를 맞춘 뒤** 실행한다. 이 파일도 그렇다:
#     (PowerShell)  scp -O nas\setup\30-deploy.sh dss-nas:/volume1/dss/setup/
#     (PowerShell)  Get-FileHash -Algorithm MD5 nas\setup\30-deploy.sh
#     (NAS)         md5sum /volume1/dss/setup/30-deploy.sh
#                   → 두 값이 **같아야** 실행한다. 다르면 다시 올린다.
#   🔵 이 스크립트는 시작할 때 **자기 md5 를 찍는다.**
#   이 스크립트가 찍는 명령은 전부 cmd() 를 지나 **76자 안쪽**이다.
#
# ══ 🔴 야간 백업 시각을 지킨다 — **02:30** ════════════════════════════
#   🔴 자정을 넘겨 돌리면 백업 검사에 걸린다. 17번이 01:00 에 돌렸다가 실제로
#      배포가 막혔다 — 그것이 사고를 막았다. 늦은 시각이면 먼저 손으로 뜬다:
#        bash /volume1/dss/jobs/backup-nightly.sh
#      ✓ dss_as 줄이 찍혀야 한다.
#
# ── 사람이 실행한다 ───────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/30-deploy.sh        ← 읽기만 한다
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ───────────────────────────────────
#   11번부터 이어온 약속 그대로 — **인자 없이 돌리면 --check**.
#   코드로는 아래 세 줄이 그 약속이다:
#     · MODE=check        (모드 절의 첫 줄)
#     · FORCE_LOAD=0      (같은 태그를 덮어쓰지 않는다)
#     · PROBE_WRITE=0     (--check 는 폴더에 시험 파일도 만들지 않는다)
#   🔴 정직하게 적어 둔다 — --check 도 이렇게 한다:
#      · 이미지 **안을 보려고** 컨테이너를 잠깐 띄웠다 지운다(docker run --rm)
#      · 운영 DB 에 **select** 를 몇 번 보낸다(바꾸는 문장은 하나도 없다)
#      · 🔴 A/S 의 쓰기 통로에 **POST 를 한 번** 보낸다(1-ㅋ). 라우트의 맨 첫
#        줄이 토큰 문지기라 **DB 를 두드리기 전에 돌아선다** — 지금은 404,
#        배포 뒤에는 401 이 온다. id 도 없는 0 UUID 다.
#      「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#
# ── 모드 여섯 ─────────────────────────────────────────────────────────
#   (없음) · --check   읽기만. 아무것도 안 바꾸고 안 멈춘다        ← 기본값
#   --preload          새 이미지 둘을 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load       🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --migrate          🔴 마이그레이션 0116 · 0117. **DB 가 바뀐다.** 안 멈춘다
#   --go               ⏱ 양식 · compose · 설정 · 컨테이너 둘 (A/S → PO)
#   --rollback         되돌리는 명령을 찍는다 (아무것도 안 바꾼다)
#
#   --force-load 는 --preload · --go 와 같이 써도 된다.
#
# ── 차례 ──────────────────────────────────────────────────────────────
#   1) bash 30-deploy.sh             읽기만 — 어긋난 곳을 먼저 고친다
#   2) bash 30-deploy.sh --preload   새 이미지 둘을 미리 싣는다
#   3) bash 30-deploy.sh             다시 읽기만 (이번엔 지문·이미지 안까지)
#   4) bash 30-deploy.sh --migrate   🔴 DB 가 바뀐다 (앱은 아직 옛 판이다)
#   5) bash 30-deploy.sh --go        ⏱ 정지 창 — A/S 먼저, 그 다음 PO
#   6) 눈으로 확인 (--go 끝의 안내)
#
# ══ 🔴 「아직 안 온 것」을 ✗ 로 세지 않는다 (17 ~ 29번의 규칙) ════════
#       **--check 가 ✗ 로 세는 것은 「있는데 어긋난 것」뿐이다.**
#       「아직 안 온 것 · 아직 안 실린 것」은 ⚠️ 로 안내만 한다.
#   🔵 그리고 이번 판은 한 걸음 더 간다 — **이미 해 둔 것도 ✗ 가 아니다.**
#      양식 · compose 네 줄 · 설정 넷 · 마이그레이션은 전부 「아직(PENDING)」과
#      「이미 했다(DONE)」를 갈라 본다. 그래야 --go 를 두 번 불러도 막히지 않는다.
#
# ══ 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ═══════════════════════
#   ① 큰따옴표 안의 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 주석에도 안 썼다. 쓴 뒤 세었다.
#   ② 읽기 전용 자리에 리다이렉션으로 빈 파일을 만들면(콜론 하나 뒤에 꺾쇠)
#      NAS 의 ash 가 셸을 그 자리에서 끝낸다 — 뒤의 echo 가 안 돌아 판정이
#      **빈 채로** 나온다(2026-10-12 실제 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   🔴 19 · 20 · 21번에는 아직 남아 있다 — 베낄 때 함께 베끼지 않았다.
#
# ══ 🔴 건드리지 않는 쪽 ═══════════════════════════════════════════════
#   포털 · 계측기 · 개선요청 · 휴가 · 게시판 · 재고 관리 · DB 둘.
#   🔴 **태그를 박아 두지 않는다.** compose 의 image 줄 목록을 고치기 **전후로**
#      견주어, 달라진 것이 dss-as 와 dss-po 둘뿐인지 본다. 박아 둔 기준은
#      다른 배포가 지나가면 낡고, 낡은 기준은 멀쩡한 배포를 막는다.
#   그리고 「안 멈췄다」를 말로 하지 않는다 — 교체 **전후로** 각 컨테이너의
#   시작 시각(.State.StartedAt)을 적어 두고 **그대로인지** 본다.
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
PO_ENV=$ENVD/po.env
IMAGES=$D/images
BKD=$D/backups
TEMPLATES=$D/as-templates
INCOMING=$D/setup/incoming
ATT=$D/as-attachments

# ── 🔴 이번에 올라가는 것 **둘** ───────────────────────────────────────
TAG_AS=dss-as:2.8;  OLD_AS=dss-as:2.7
TAG_PO=dss-po:0.6;  OLD_PO=dss-po:0.5

# ── 서비스 · 컨테이너 · 포트 (compose 의 ports: 에서 읽어 확인했다) ────
AS_SVC=app-as;    AS_CNAME=dss-as;  AS_PORT=13000;  AS_BASE=https://as.dss21.co.kr
PO_SVC=app-po;    PO_CNAME=dss-po;  PO_PORT=13600;  PO_BASE=https://po.dss21.co.kr
AS_TOOLS_SVC=tools-as
# compose 에 반드시 있어야 하는 서비스 열넷 (29번의 목록 그대로)
SVC_ALL="app-auth app-as tools-as app-meters tools-meters app-improvements"
SVC_ALL="$SVC_ALL tools-improvements app-po app-leave tools-leave app-board"
SVC_ALL="$SVC_ALL tools-board app-inventory tools-inventory"
# 🔴 건드리지 않는 컨테이너 여덟 — 시작 시각을 적어 두고 뒤에서 대조한다
KEEP_BOXES="dss-auth dss-meters dss-improvements dss-leave dss-board"
KEEP_BOXES="$KEEP_BOXES dss-inventory dss-pg-app dss-pg-auth"
# 건드리지 않는 바깥 이름 여섯 / 바뀌는 둘
KEEP_HOSTS="login meters improvements leave board inventory"
MOVE_HOSTS="as po"

# ── tar 둘 — 🔴 2026-10-19 에 재어 채웠고 NAS 에서 다시 쟀다 ───────────
TAR_AS=$IMAGES/dss-as-2.8.tar
TAR_PO=$IMAGES/dss-po-0.6.tar
SZ_AS="132020224"
MD5_AS="353c41296381c313c6a1e7ae55534026"
WANT_CFG_AS="sha256:0cce865eeea494e0dedc0da22cd8ca2a4e131f6244ef4a124c41d6ae8af8922e"
SZ_PO="95434240"
MD5_PO="37f39ae2dea773173362644fbd0d631a"
WANT_CFG_PO="sha256:188c15b0a38ceeba559c154e4a66d65739bb544cfcabcafe9ecf0c1e11a708ff"
# ⚠️ manifest.json 은 그 값을 'blobs/sha256/0cce865e…' 로 적는다 — 앞의 'blobs/'
#    를 떼고 'sha256:' 를 붙인 모양으로 적는다(17 ~ 29번도 같은 모양이었다).

# ══ 🔴 마이그레이션 — 값 **넷**으로 센다 ══════════════════════════════
#
#   ① 운영 DB 에 적용된 줄 수   (dss_as 의 drizzle.__drizzle_migrations)
#   ② NAS 볼륨의 .sql 수        (/volume1/dss/as-migrations — tools-as 가 읽는다)
#   ③ 그 볼륨 meta/_journal.json 의 tag 줄 수
#   ④ 🔴 $TAG_AS **이미지 안** /app/drizzle 의 .sql 수
#
#   🔵 2026-10-19 실측: ① 116 · ④ 2.7 은 116 · **2.8 은 118**(0116 · 0117 둘 다
#      들어 있다). ②③ 은 아직 재지 않았다 — 이 스크립트가 센다.
#   🔴 적용을 **돌리는** 쪽은 볼륨이다. 이미지 안의 118 은 「코드가 그 둘을 알고
#      있다」는 증언일 뿐 적용에 쓰이지 않는다. 둘 다 센다.
AS_DB=dss_as
AS_MIG_HAVE=116
AS_MIG_WANT=118
AS_NEW_MIGS="0116 0117"
MIGDIR=$D/as-migrations
MIGTAR=$INCOMING/as-migrations.tar.gz
IMG_MIGDIR=/app/drizzle
# 🔴 새 .sql 안에 **반드시 있어야 하는 글자** (다른 파일을 올린 것을 가린다)
MIG_MARK_0116='ADD COLUMN "portal_form_id"'
MIG_MARK_0117="'SHIPMENT_COMPLETED'"
# 🔴 「지우는 문장」 잣대 — 앱의 migration-safety.ts 와 **같은 것**을 쓴다.
#    DELETE 만으로 세지 않는다. 외래키의 ON DELETE 가 걸려서 표만 더하는 판이
#    ✗ 가 된다(19번이 그 자리에서 넘어졌다).
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
RISKY_RE='DROP[[:space:]]+INDEX|RENAME|SET[[:space:]]+NOT[[:space:]]+NULL'
# 🔴 이번 판에 **있는 것이 맞는** 지우는 문장의 수 — 0116 도 0117 도 **0줄**이다
MIG_DROP_WANT=0
# 🔴 출하 완료 줄 — 적용 전 32 · 적용 뒤에도 32(줄 수는 안 변한다)
WF_ACTION=SHIPMENT_COMPLETED
WF_ROWS_WANT=32
# 줄 수가 그대로여야 하는 표
AS_COUNT_TABLES="customers workflow_transitions repair_cases"

# ══ 🔴 양식 네 장 — md5 는 2026-10-19 에 대조한 값이다 ════════════════
#
# 🔴 **기존 두 장은 손대지 않는다.** TPLx_BASE 는 「주인·모드를 베껴 올 짝」일
#    뿐, 바꾸거나 지우는 대상이 아니다.
TPL_NAMES="검사보고서_매쳐.xlsx 검사보고서_제너레이터.xlsx 수리보고서_매쳐.xlsx 수리보고서_제너레이터.xlsx"
TPL_KEEP="검사보고서.xlsx 수리보고서.xlsx"
TPL1_NAME='검사보고서_매쳐.xlsx';       TPL1_MD5=400e4be36058a9dd02fb1b2aed00352b; TPL1_BASE='검사보고서.xlsx'
TPL2_NAME='검사보고서_제너레이터.xlsx'; TPL2_MD5=4d8d86698abbae529ad0ccfbf2bf1df2; TPL2_BASE='검사보고서.xlsx'
TPL3_NAME='수리보고서_매쳐.xlsx';       TPL3_MD5=0d213401b35e25901afac0f5fac9635b; TPL3_BASE='수리보고서.xlsx'
TPL4_NAME='수리보고서_제너레이터.xlsx'; TPL4_MD5=b2f45c8782d7438cf60d6ff1a74553b2; TPL4_BASE='수리보고서.xlsx'
# 🔵 지금 7장. 넉 장을 넣으면 **11장**이다 (2026-10-19 02:48 실측).
TPL_COUNT_HAVE=7
TPL_COUNT_WANT=11

# ══ 🔴 compose 에 더할 네 줄 ══════════════════════════════════════════
# 🔴 INSPECTION_REPORT_TEMPLATE_PATH **바로 앞**에 넣는다. 그 줄과
#    REPAIR_REPORT_TEMPLATE_PATH 는 **지우지 않는다**(물러설 자리다).
CF_ANCHOR=INSPECTION_REPORT_TEMPLATE_PATH
CF_KEEP_KEYS="INSPECTION_REPORT_TEMPLATE_PATH REPAIR_REPORT_TEMPLATE_PATH"
CF_NEW_KEYS="MATCHER_INSPECTION_REPORT_TEMPLATE_PATH GENERATOR_INSPECTION_REPORT_TEMPLATE_PATH"
CF_NEW_KEYS="$CF_NEW_KEYS MATCHER_REPAIR_REPORT_TEMPLATE_PATH GENERATOR_REPAIR_REPORT_TEMPLATE_PATH"
# 넣는 줄 수 (주석 셋 + 설정 넷)
CF_ADD_LINES=7

# ══ 🔴 설정 넷 ════════════════════════════════════════════════════════
AS_NEW_KEYS="AS_WRITE_TOKEN"
PO_NEW_KEYS="AS_WRITE_TOKEN INVENTORY_API_BASE_URL INVENTORY_API_TOKEN"
# 🔴 po.env 로 **복사해 갈 원본** — as.env 에 없으면 멈춘다(지어내지 않는다)
AS_SRC_KEYS="INVENTORY_API_BASE_URL INVENTORY_API_TOKEN"
# 🔴 PO 가 **알 필요가 없는** 값 — po.env 에 있으면 ✗ 다
PO_FORBIDDEN="INVENTORY_WRITE_TOKEN"
# as.env 에 있으면 안 되는 것 (compose 가 넘긴다)
AS_FORBIDDEN="DATABASE_URL UPLOADS_DIR PORT"
# 🔴 as.env 에 **그대로 있어야 하는** 줄들 (22 · 28번의 목록 그대로).
#    사라졌으면 누가 덮어쓴 것이고, 그때는 배포보다 그것이 먼저다.
AS_QUOTE_KEYS="QUOTE_ARCHIVE_DIR QUOTE_ARCHIVE_UNC_ROOT"
AS_PORTAL_KEYS="CUSTOMER_PORTAL_ARCHIVE_DIR CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT"
AS_PORTAL_KEYS="$AS_PORTAL_KEYS CUSTOMER_PORTAL_ARCHIVE_FOLDER_PATH"
AS_OTHER_KEYS="CONTACT_FOLDER_ARCHIVE_DIR REPAIR_DOCS_ARCHIVE_DIR PURCHASE_ORDER_ARCHIVE_DIR"
AS_OTHER_KEYS="$AS_OTHER_KEYS AS_API_TOKEN"
# 토큰 길이 — openssl rand -base64 36 은 **정확히 48자**다
TOKEN_LEN=48

# ── 쓰기 통로 (이번 판의 알맹이) ───────────────────────────────────────
# 🔴 아무것도 안 바꾸는 확인용 주소다. id 는 **존재하지 않는 0 UUID** 이고,
#    라우트의 **맨 첫 줄이 토큰 문지기**라 그 앞에서 돌아선다(DB 를 안 두드린다).
WRITE_PATH=/api/v1/domestic-orders/00000000-0000-0000-0000-000000000000/completion

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 셋. 인자가 없으면 이 셋 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
PROBE_WRITE=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 30-deploy.sh                 읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 30-deploy.sh --check         위와 같습니다
  bash 30-deploy.sh --preload       새 이미지 둘을 싣고 지문을 맞춥니다
  bash 30-deploy.sh --force-load    🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 30-deploy.sh --migrate       🔴 마이그레이션 0116 · 0117 — DB 가 바뀝니다
  bash 30-deploy.sh --go            ⏱ 양식 · compose · 설정 · 컨테이너 둘
  bash 30-deploy.sh --rollback      되돌리기 안내 (아무것도 안 바꿉니다)

  🔴 차례:  (없음) → --preload → (없음) → --migrate → --go
  🔴 --migrate 와 --go 는 **따로** 부릅니다. 마이그레이션이 덜 된 DB 에
     2.8 이 뜨면 없는 칸을 읽다 그 자리에서 죽습니다.
  🔴 --go 가 바꿔 끼우는 것은 **app-as 와 app-po 둘**입니다. 그리고
     **A/S 를 먼저** 올려 대답을 받은 뒤에 PO 를 올립니다.
  🔴 --migrate 도 --go 도 **그날 백업이 없으면 시작하지 않습니다.**
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
# 🔴 쓰기 시험(폴더에 빈 파일을 놓았다 지운다)은 --go 에서만 한다.
#    --check 가 「아무것도 안 바꾼다」고 말해 놓고 파일을 만들면 그 약속이 거짓이 된다.
[ "$MODE" = go ] && PROBE_WRITE=1

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/30-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 22 · 29번의 것 그대로 ─────────────────────────────────────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""; DOWN=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# 🔴 「아직 안 온 것」은 --check 에서 ✗ 가 아니다.
#    --preload · --migrate · --go 는 그것이 **있어야** 도는 모드라 ✗ 로 센다.
missing_is_fatal() { [ "$MODE" != check ]; }
notyet() { # 아직 안 **온** 것 (사람이 올려야 하는 파일)
  if missing_is_fatal; then bad "$1"; else echo "    ⚠️ $1"; fi
}
notloaded() { # 아직 안 **실린** 것. 🔴 어느 모드에서도 ✗ 가 아니다.
  echo "    ⚠️ $1"
}

# 🔴 값 여섯이 채워졌는가 — 안 채워졌으면 --migrate 도 --go 도 시작하지 않는다.
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
  fi
}

# 🔵 29번처럼 함수 하나로 쓴다 — 배열을 안 쓰므로 더 단순하다.
compose_cmd() { "$DOCKER" compose --project-directory "$D/deploy" -f "$CF" --env-file "$ENV_NAS" --profile tools "$@"; }

running() { "$DOCKER" ps --format '{{.Names}}' | grep -qx "$1"; }
pg_up()   { running dss-pg-app; }

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미 — 🔴 바꾸는 문장은 **--migrate 의 db:migrate 하나뿐**이다.
#     이 스크립트가 직접 보내는 SQL 은 전부 select 다.
#  🔴 29번 353줄의 것을 글자 그대로 가져왔다.
# ══════════════════════════════════════════════════════════════════════
qas()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -Atc \"$1\"" 2>/dev/null; }
qqas() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -c   \"$1\"" 2>/dev/null; }
# 🔴 qas 가 받은 글자를 psql 의 -Atc 뒤에 **큰따옴표로 감싸** 넘긴다.
#    그래서 SQL 안에는 **큰따옴표를 쓰지 않는다.** 식별자는 전부 소문자로 적는다.
as_mig_count() { qas "select count(*) from drizzle.__drizzle_migrations"; }
wf_rows()      { qas "select count(*) from workflow_transitions where action_code = '$WF_ACTION'"; }
wf_rows_both() { qas "select count(*) from workflow_transitions where action_code = '$WF_ACTION' and allowed_roles @> array['AS_ENGINEER','SALES']::role_code[]"; }
col_exists()   { qas "select count(*) from information_schema.columns where table_name = '$1' and column_name = '$2'"; }

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

# ── compose 파일에서 서비스 한 덩어리만 잘라 낸다 (27 ~ 29번) ──────────
# 🔴 파일 전체를 grep 하면 안 된다 — 주석 줄이 그대로 걸려서 꺼져 있는
#    서비스를 「가리킨다」고 세게 된다(11-deploy.sh 의 그 함정).
svc_block() { # 1 compose파일 2 서비스이름
  awk -v s="  $2:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$1" | sed '/^[[:space:]]*#/d'
}
svc_image() { svc_block "$1" "$2" | sed -n 's/^[[:space:]]*image:[[:space:]]*//p' | head -1; }

# ══════════════════════════════════════════════════════════════════════
#  🔴 compose 의 줄을 **글자로** 센다 — 정규식이 아니다
#
#  태그에는 점이 들어 있다(2.7 · 2.8). 정규식으로 보면 그 점이 아무 글자나
#  맞아 엉뚱한 줄을 센다. 들여쓰기만 떼고 **통째로 같은지** 본다.
#  🔴 주석 줄은 자동으로 안 걸린다 — 「image: …」 로 시작하지 않는다.
# ══════════════════════════════════════════════════════════════════════
img_line_count() { # 1 파일 2 태그 → 「image: <태그>」 줄 수
  awk -v want="image: $2" '
    { t = $0; gsub(/^[ \t]+/, "", t); gsub(/[ \t\r]+$/, "", t)
      if (t == want) n++ }
    END { print n + 0 }
  ' "$1"
}
# 🔴 「<키>:」 **로 시작하는** 줄 수. MATCHER_… 는 안 걸린다(머리가 다르다).
cf_key_count() { # 1 파일 2 키
  awk -v k="$2:" '
    { t = $0; gsub(/^[ \t]+/, "", t); gsub(/[ \t\r]+$/, "", t)
      if (index(t, k) == 1) n++ }
    END { print n + 0 }
  ' "$1"
}
# 같은 것을 서비스 한 덩어리 안에서만 센다
svc_key_count() { # 1 파일 2 서비스 3 키
  svc_block "$1" "$2" | awk -v k="$3:" '
    { t = $0; gsub(/^[ \t]+/, "", t); gsub(/[ \t\r]+$/, "", t)
      if (index(t, k) == 1) n++ }
    END { print n + 0 }
  '
}
# 🔴 image: 줄 **전체 목록** (들여쓰기를 떼고 정렬). 고치기 전후로 견준다.
cf_img_list() { # 1 파일
  awk '
    { t = $0; gsub(/^[ \t]+/, "", t); gsub(/[ \t\r]+$/, "", t)
      if (index(t, "image: ") == 1) print t }
  ' "$1" | sort
}

# ── .env 읽기 ──────────────────────────────────────────────────────────
env_val_of() { # 1 파일 2 키  → 값 (없으면 빈 문자열)
  local v
  [ -f "$1" ] || return 0
  v=$(sed -n "s/^$2=//p" "$1" | head -1 | tr -d '\r')
  v=${v#\"}; v=${v%\"}
  v=${v#\'}; v=${v%\'}
  printf '%s' "$v"
}
env_count_of() { # 1 파일 2 키 → 그 이름으로 시작하는 줄 수
  # 🔴 「|| echo 0」을 붙이지 않는다. grep -c 는 0건일 때도 0 을 찍고 종료코드만
  #    1 이라, 붙이면 값이 두 줄이 되어 비교가 전부 어긋난다(27번의 그 자리).
  [ -f "$1" ] || { echo 0; return 0; }
  grep -c "^$2=" "$1" 2>/dev/null | tr -d ' '
}
# 🔴 「있는가」만 본다. 없으면 ✗ — 앞 배포가 제대로 안 돈 것이다.
env_keys_present() { # 1 파일 2 라벨 3 "키 …" 4 없을때할말
  local f="$1" label="$2" keys="$3" why="$4" k n
  for k in $keys; do
    n=$(env_count_of "$f" "$k")
    if [ "${n:-0}" = 0 ]; then
      bad "$label · $k 가 **없다** — 🔴 $why"
    elif [ "${n:-0}" -gt 1 ] 2>/dev/null; then
      bad "🔴 $label · $k 가 **두 줄 이상** 있다 — 먼저 그것부터 고쳐야 한다"
      say "      보기:  grep -n '^$k=' $f"
    else
      ok "$label · $k 있다"
    fi
  done
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 설정 넷의 **값**을 정한다 — 토큰은 화면에 한 글자도 안 찍는다
#
#  🔴 지어내지 않는다:
#     · INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN 은 **as.env 에서 읽는다.**
#       없으면 멈춘다(사람이 값을 가져와야 한다).
#     · AS_WRITE_TOKEN 은 as.env 에 **이미 있으면 그 값**을 쓴다. 없을 때만
#       새로 만든다 — 그래야 --go 를 두 번 불러도 두 파일이 같은 값을 갖는다.
# ══════════════════════════════════════════════════════════════════════
V_WRITE=""; V_INV_BASE=""; V_INV_TOKEN=""; WRITE_TOKEN_SRC=""
# 🔴 만드는 자리는 여기 하나뿐이다. openssl 이 없으면 /dev/urandom 으로 간다
#    (27-inventory-pw.sh 가 쓰는 그 길). 둘 다 안 되면 멈춘다.
make_write_token() { # → 48자 base64
  local t=""
  if command -v openssl >/dev/null 2>&1; then
    t=$(openssl rand -base64 36 2>/dev/null | tr -d '\r\n')
  fi
  if [ "${#t}" != "$TOKEN_LEN" ]; then
    t=$(head -c 36 /dev/urandom 2>/dev/null | base64 2>/dev/null | tr -d '\r\n')
  fi
  [ "${#t}" = "$TOKEN_LEN" ] || return 1
  printf '%s' "$t"
}
# 🔴 --go 에서만 부른다. make=1 이면 없을 때 새로 만든다.
build_env_values() { # 1 make(0|1)
  local make="$1" k n
  for k in $AS_SRC_KEYS; do
    n=$(env_count_of "$AS_ENV" "$k")
    if [ "${n:-0}" != 1 ]; then
      bad "🔴 as.env 의 $k 가 ${n:-0}줄이다 (**딱 한 줄**이어야 한다)"
      say "      🔴 지어내지 않는다. 사람이 값을 가져와야 합니다:"
      say "         grep -c '^$k=' $AS_ENV"
      return 1
    fi
  done
  V_INV_BASE=$(env_val_of "$AS_ENV" INVENTORY_API_BASE_URL)
  V_INV_TOKEN=$(env_val_of "$AS_ENV" INVENTORY_API_TOKEN)
  if [ -z "$V_INV_BASE" ] || [ -z "$V_INV_TOKEN" ]; then
    bad "🔴 as.env 의 INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN 중 **값이 빈 것**이 있다"
    say "      (줄 길이 — BASE ${#V_INV_BASE}자 · TOKEN ${#V_INV_TOKEN}자. 🔴 값은 안 찍는다)"
    return 1
  fi
  V_WRITE=$(env_val_of "$AS_ENV" AS_WRITE_TOKEN)
  if [ -n "$V_WRITE" ]; then
    WRITE_TOKEN_SRC="as.env 에 이미 있던 값"
    return 0
  fi
  if [ "$make" != 1 ]; then
    WRITE_TOKEN_SRC="아직 없다 — --go 가 만든다"
    return 0
  fi
  V_WRITE=$(make_write_token) || {
    bad "🔴 AS_WRITE_TOKEN 을 만들지 못했다 (openssl 도 /dev/urandom 도 안 됐다)"
    return 1
  }
  WRITE_TOKEN_SRC="이번에 새로 만든 값"
  return 0
}
want_env_value() { # 1 키 → 그 키에 들어가야 할 값
  case "$1" in
    AS_WRITE_TOKEN)          printf '%s' "$V_WRITE" ;;
    INVENTORY_API_BASE_URL)  printf '%s' "$V_INV_BASE" ;;
    INVENTORY_API_TOKEN)     printf '%s' "$V_INV_TOKEN" ;;
  esac
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
# --check 에서 **보기만** 한다. ADD 도 SAME 도 ✗ 가 아니다.
report_env_keys() { # 1 파일 2 라벨 3 "키 …"
  local f="$1" label="$2" keys="$3" k v
  for k in $keys; do
    v=$(env_verdict "$f" "$k")
    case "$v" in
      SAME) ok "$label · $k 가 **이미 있고 값도 같다** — 건드리지 않는다" ;;
      ADD)  say "    · $label · $k 가 없다 — **--go 가 덧붙인다**" ;;
      DIFF) bad "🔴 $label · $k 가 **이미 있는데 값이 다르다** — 덮어쓰지 않는다"
            say "      (길이만 적는다 — 지금 $(printf '%s' "$(env_val_of "$f" "$k")" | wc -c | tr -d ' ')자"
            say "       · 넣을 것 $(printf '%s' "$(want_env_value "$k")" | wc -c | tr -d ' ')자)"
            say "      🔴 어느 쪽이 맞는지 **사람이 정해야 합니다.**" ;;
      DUP)  bad "🔴 $label · $k 가 **두 줄 이상** 있다 — 나중 것이 이긴다. 먼저 고치세요"
            say "      보기:  grep -n '^$k=' $f" ;;
    esac
  done
}
# 🔴 덧붙이는 쪽. **--go 에서만 불린다.**
append_env_keys() { # 1 파일 2 라벨 3 "키 …" 4 머리주석
  local f="$1" label="$2" keys="$3" note="$4" k v added=0
  for k in $keys; do
    v=$(env_verdict "$f" "$k")
    case "$v" in
      DIFF) bad "🔴 $label · $k 가 **이미 있는데 값이 다르다** — 덮어쓰지 않는다"; return 1 ;;
      DUP)  bad "🔴 $label · $k 가 **두 줄 이상** 있다"; return 1 ;;
    esac
  done
  # 파일이 줄바꿈으로 끝나지 않으면 한 줄 띄운다 (앞 줄과 붙어 버리지 않게)
  [ -n "$(tail -c 1 "$f")" ] && printf '\n' >> "$f"
  for k in $keys; do
    if [ "$(env_verdict "$f" "$k")" != ADD ]; then
      say "  · $label · $k 는 **이미 있고 값도 같다** — 건드리지 않는다"
      continue
    fi
    if [ "$added" = 0 ]; then
      printf '\n# ── %s — %s 30-deploy.sh 가 덧붙임 ──\n' "$note" "$TODAY" >> "$f"
    fi
    printf '%s=%s\n' "$k" "$(want_env_value "$k")" >> "$f"
    added=$((added + 1))
    ok "$label · $k 덧붙였다 (🔴 값은 안 찍는다)"
  done
  chown root:root "$f"; chmod 600 "$f"
  if [ "$added" = 0 ]; then
    ok "$label · 더할 줄이 없었다 — 한 글자도 안 바꿨다"
  else
    ok "$label · ${added}줄을 덧붙였다 (모드 600 · root:root 로 되돌렸다)"
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 양식 네 장 — **읽기만 한다. 놓는 것은 --go 가 한다.**
#
#  상태 셋으로 가른다:
#    DONE  운영 폴더에 이미 있고 md5 가 맞다 — 할 일이 없다
#    READY incoming 에 있고 md5 가 맞다 — --go 가 놓는다
#    (빈값) 아직 안 왔다(⚠️) 또는 어긋났다(✗)
# ══════════════════════════════════════════════════════════════════════
TPL1_STATE=""; TPL2_STATE=""; TPL3_STATE=""; TPL4_STATE=""
see_tpl() { # 1 번호 2 운영이름 3 기대md5
  local n="$1" name="$2" wmd5="$3" cur src smd5 ssz
  say "  · 「$name」"
  if [ -f "$TEMPLATES/$name" ]; then
    cur=$(md5_of "$TEMPLATES/$name")
    if [ "$cur" = "$wmd5" ]; then
      ok "운영 폴더에 **이미 있고 md5 가 맞다** — 놓을 것이 없다"
      eval "TPL${n}_STATE=DONE"
      return 0
    fi
    bad "🔴 운영 폴더에 **같은 이름의 다른 파일**이 있다 (md5 ${cur:-못 읽음})"
    say "      기대 md5 $wmd5"
    say "      🔴 덮어쓰지 않습니다. 고치지 말고 **먼저 알리세요.**"
    eval "TPL${n}_STATE="
    return 1
  fi
  src=$INCOMING/$name
  if [ ! -f "$src" ]; then
    notyet "새 양식이 아직 NAS 에 없다 — $src"
    say "      → 개발 PC(PowerShell)에서 올리세요:"
    cmd "scp -O '$name' dss-nas:/volume1/dss/setup/incoming/"
    eval "TPL${n}_STATE="
    return 1
  fi
  ssz=$(stat -c '%s' "$src" 2>/dev/null)
  smd5=$(md5_of "$src")
  say "      올라온 것: 바이트 ${ssz:-?} · md5 ${smd5:-?}"
  if [ "$smd5" != "$wmd5" ]; then
    bad "🔴 올라온 파일의 md5 가 기대값과 다르다 — 옮기다 깨졌거나 다른 파일이다"
    say "      기대 $wmd5"
    say "      → 다시 올리세요(scp -O). DSM 터미널로 붙여넣지 마세요."
    eval "TPL${n}_STATE="
    return 1
  fi
  ok "incoming 에 있고 md5 가 맞다 — **--go 가 놓는다**"
  eval "TPL${n}_STATE=READY"
  return 0
}
# 🔴 놓는 쪽. **--go 에서만 불린다.** 21번 1313~1324줄의 방식 그대로다.
#    🔵 이번엔 새 파일이라 **치워 둘 원본이 없다.** 주인·모드는 짝 파일에서 읽는다.
place_tpl() { # 1 운영이름 2 기대md5 3 주인·모드를 베껴 올 짝 파일
  local name="$1" wmd5="$2" base="$3" src own mode got
  src=$INCOMING/$name
  [ -f "$src" ] || { bad "놓을 파일이 없다: $src"; return 1; }
  if [ ! -f "$TEMPLATES/$base" ]; then
    bad "🔴 주인·모드를 베껴 올 짝 파일이 없다: $TEMPLATES/$base"
    say "      🔴 지어내지 않습니다. 그 폴더가 기대한 모습이 아닙니다."
    return 1
  fi
  own=$(stat -c '%u:%g' "$TEMPLATES/$base" 2>/dev/null)
  mode=$(stat -c '%a' "$TEMPLATES/$base" 2>/dev/null)
  if [ -z "$own" ] || [ -z "$mode" ]; then
    bad "🔴 $base 의 주인·모드를 읽지 못했다 — 놓지 않는다"
    return 1
  fi
  cp "$src" "$TEMPLATES/$name.new" 2>/dev/null \
    || { bad "새 양식을 복사하지 못했다 ($name)"; return 1; }
  chown "$own" "$TEMPLATES/$name.new" 2>/dev/null
  chmod "$mode" "$TEMPLATES/$name.new" 2>/dev/null
  mv -f "$TEMPLATES/$name.new" "$TEMPLATES/$name" \
    || { bad "새 양식을 제자리에 놓지 못했다 ($name)"; rm -f "$TEMPLATES/$name.new"; return 1; }
  got=$(md5_of "$TEMPLATES/$name")
  if [ "$got" = "$wmd5" ]; then
    ok "「$name」 놓았다 (주인 $own · 모드 $mode — $base 에서 베꼈다)"
    say "    🔵 incoming 의 사본은 **지우지 않는다** — 다시 돌릴 때 쓴다."
    return 0
  fi
  bad "🔴 놓은 뒤 md5 가 다르다 ($got) — 기대 $wmd5"
  return 1
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 compose 고치기 — **제자리에서 세 군데**
#
#    ㄱ) image: dss-as:2.7 → 2.8          ㄴ) image: dss-po:0.5 → 0.6
#    ㄷ) app-as 의 environment: 절에 **일곱 줄**
#
#  🔴 바꾸기 전에 사본을 뜨고, 바꾼 뒤 아래를 **전부** 센다. 하나라도 어긋나면
#     **사본으로 되돌리고 멈춘다.**
#       · 줄 수가 정확히 7줄 늘었는가
#       · 새 태그 1줄씩 · 옛 태그 0줄씩
#       · 새 키 넷이 app-as 에 1줄씩 · app-po 에 0줄
#       · 물러설 자리 두 줄이 **그대로 1줄씩** 있는가
#       · image: 줄 **전체 목록**이 위 둘 말고는 그대로인가
#       · compose config -q 가 통과하는가
# ══════════════════════════════════════════════════════════════════════
TMPD=$D/setup/tmp-30-$STAMP
CF_BK=""
compose_tags_done() {
  [ "$(img_line_count "$CF" "$TAG_AS")" = 1 ] && [ "$(img_line_count "$CF" "$TAG_PO")" = 1 ]
}
compose_env_done() {
  local k
  for k in $CF_NEW_KEYS; do
    [ "$(cf_key_count "$CF" "$k")" = 1 ] || return 1
  done
  return 0
}
compose_done() { compose_tags_done && compose_env_done; }

write_block_file() { # 1 쓸 파일
  cat > "$1" <<'BLOCK'
      # 제품 종류별 양식 (2026-10-19 더함 · 서른째 배포).
      # 매쳐와 제너레이터는 담당자 도장이 다르다. T/C 는 제너레이터 것을 쓴다.
      # 아래 두 줄(종류를 모를 때 쓰는 예비 경로)은 그대로 둔다.
      MATCHER_INSPECTION_REPORT_TEMPLATE_PATH: "/templates/검사보고서_매쳐.xlsx"
      GENERATOR_INSPECTION_REPORT_TEMPLATE_PATH: "/templates/검사보고서_제너레이터.xlsx"
      MATCHER_REPAIR_REPORT_TEMPLATE_PATH: "/templates/수리보고서_매쳐.xlsx"
      GENERATOR_REPAIR_REPORT_TEMPLATE_PATH: "/templates/수리보고서_제너레이터.xlsx"
BLOCK
}

edit_compose() {
  local bk tmp blk before after nb na k n n2 rc
  mkdir -p "$TMPD"; chown root:root "$TMPD"; chmod 700 "$TMPD"
  bk="$BKD/docker-compose.nas.yml.$STAMP"
  tmp="$TMPD/compose.new"
  blk="$TMPD/compose-block.txt"
  before="$TMPD/img-before.txt"
  after="$TMPD/img-after.txt"
  mkdir -p "$BKD"
  cp -p "$CF" "$bk" || { bad "compose 사본을 못 떴다"; return 1; }
  chmod 644 "$bk"
  CF_BK=$bk
  ok "compose 사본 — backups/docker-compose.nas.yml.$STAMP"

  # ── ① 바꾸기 **전**의 모습이 기대한 그대로인가 ──────────────────────
  if [ "$(img_line_count "$CF" "$OLD_AS")" != 1 ]; then
    bad "🔴 compose 에 「image: $OLD_AS」 줄이 하나가 아니다"
    say "    → 남의 변경이 섞였거나 이미 바뀐 뒤다. 고치지 말고 알리세요."
    return 1
  fi
  if [ "$(img_line_count "$CF" "$OLD_PO")" != 1 ]; then
    bad "🔴 compose 에 「image: $OLD_PO」 줄이 하나가 아니다"
    return 1
  fi
  if [ "$(img_line_count "$CF" "$TAG_AS")" != 0 ] || [ "$(img_line_count "$CF" "$TAG_PO")" != 0 ]; then
    bad "🔴 compose 에 새 태그 줄이 **이미 있다**"
    return 1
  fi
  if [ "$(cf_key_count "$CF" "$CF_ANCHOR")" != 1 ]; then
    bad "🔴 compose 에 「$CF_ANCHOR:」 줄이 하나가 아니다 — 넣을 자리를 못 고른다"
    return 1
  fi
  if [ "$(svc_key_count "$CF" "$AS_SVC" "$CF_ANCHOR")" != 1 ]; then
    bad "🔴 그 한 줄이 **app-as 안에 있지 않다** — 넣을 자리가 틀렸다"
    return 1
  fi
  for k in $CF_NEW_KEYS; do
    if [ "$(cf_key_count "$CF" "$k")" != 0 ]; then
      bad "🔴 compose 에 $k 줄이 **이미 있다**"
      return 1
    fi
  done
  nb=$(wc -l < "$CF")
  cf_img_list "$CF" > "$before"

  # ── ② 글자로 바꾸고, 글자로 넣는다 (awk 한 번) ──────────────────────
  write_block_file "$blk" || { bad "넣을 일곱 줄을 만들지 못했다"; return 1; }
  n=$(wc -l < "$blk")
  if [ "$n" != "$CF_ADD_LINES" ]; then
    bad "🔴 넣을 줄이 ${n}줄이다 (${CF_ADD_LINES}줄이어야 한다)"
    return 1
  fi
  awk -v blk="$blk" -v key="$CF_ANCHOR:" \
      -v oa="image: $OLD_AS" -v na="image: $TAG_AS" \
      -v op="image: $OLD_PO" -v np="image: $TAG_PO" '
    {
      line = $0
      lead = line
      sub(/^[ \t]*/, "", lead)
      ind = substr(line, 1, length(line) - length(lead))
      t = lead
      sub(/[ \t\r]+$/, "", t)
      if (t == oa) { print ind na; next }
      if (t == op) { print ind np; next }
      if (done == 0 && index(t, key) == 1) {
        while ((getline b < blk) > 0) print b
        close(blk)
        done = 1
      }
      print line
    }' "$CF" > "$tmp" || { bad "compose 를 못 썼다"; rm -f "$tmp"; return 1; }

  # ── ③ 줄 수가 정확히 일곱 늘었는가 ──────────────────────────────────
  na=$(wc -l < "$tmp")
  if [ "$na" != "$((nb + CF_ADD_LINES))" ]; then
    bad "🔴 줄 수가 ${nb} → ${na} 다 ($((nb + CF_ADD_LINES)) 이어야 한다) — **바꾸지 않는다**"
    rm -f "$tmp"
    return 1
  fi
  ok "줄 수 ${nb} → ${na} (+${CF_ADD_LINES}줄 — 기대한 그대로)"
  cp -p "$tmp" "$CF" && rm -f "$tmp"
  chown root:root "$CF"; chmod 644 "$CF"

  # ── ④ 바꾼 뒤 — 태그 · 새 키 넷 · 물러설 자리 두 줄 ─────────────────
  rc=0
  [ "$(img_line_count "$CF" "$TAG_AS")" = 1 ] && [ "$(img_line_count "$CF" "$OLD_AS")" = 0 ] \
    && ok "$OLD_AS → $TAG_AS" || { bad "🔴 A/S 태그가 안 바뀌었다"; rc=1; }
  [ "$(img_line_count "$CF" "$TAG_PO")" = 1 ] && [ "$(img_line_count "$CF" "$OLD_PO")" = 0 ] \
    && ok "$OLD_PO → $TAG_PO" || { bad "🔴 PO 태그가 안 바뀌었다"; rc=1; }
  for k in $CF_NEW_KEYS; do
    n=$(svc_key_count "$CF" "$AS_SVC" "$k")
    n2=$(svc_key_count "$CF" "$PO_SVC" "$k")
    if [ "$n" = 1 ] && [ "$n2" = 0 ]; then
      ok "app-as 에 $k 한 줄 (app-po 에는 없다 — 맞다)"
    else
      bad "🔴 $k — app-as ${n}줄 · app-po ${n2}줄 (1줄 · 0줄이어야 한다)"
      rc=1
    fi
  done
  for k in $CF_KEEP_KEYS; do
    [ "$(svc_key_count "$CF" "$AS_SVC" "$k")" = 1 ] \
      && ok "물러설 자리 $k 가 **그대로 있다**" \
      || { bad "🔴 $k 가 사라졌다 — 종류를 모를 때 읽을 양식이 없어진다"; rc=1; }
  done

  # ── ⑤ image: 줄 **전체 목록**이 위 둘 말고는 그대로인가 ─────────────
  #    🔴 건드리지 않는 쪽의 태그를 **박아 두지 않는다.** 바꾸기 전 목록에
  #       우리가 바꾼 둘만 손으로 고쳐 넣고, 바꾼 뒤 목록과 **글자로** 견준다.
  cf_img_list "$CF" > "$after"
  awk -v oa="image: $OLD_AS" -v na="image: $TAG_AS" \
      -v op="image: $OLD_PO" -v np="image: $TAG_PO" \
      '{ if ($0 == oa) print na; else if ($0 == op) print np; else print }' "$before" \
      | sort > "$TMPD/img-expect.txt"
  if cmp -s "$TMPD/img-expect.txt" "$after"; then
    ok "🔴 image: 줄 전체 목록이 **그 둘 말고는 글자까지 그대로**다"
  else
    bad "🔴 image: 줄이 그 둘 말고 **또 달라졌다** — 남의 변경이 섞였다"
    diff "$TMPD/img-expect.txt" "$after" 2>/dev/null | sed 's/^/      /' | head -10
    rc=1
  fi

  # ── ⑥ 서비스 열넷이 그대로인가 · 문법 ───────────────────────────────
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
    say "  🔴 **사본으로 되돌립니다.**"
    cp -p "$bk" "$CF"; chown root:root "$CF"; chmod 644 "$CF"
    ok "compose 를 사본으로 되돌렸다 — 바꾸기 전과 글자까지 같다"
    return 1
  fi
  say "  🔴 compose 를 고쳤다 — **아직 아무것도 안 뜨고 안 멈췄다.** 글자일 뿐이다."
  say "     🔴 다만 지금부터 **인자 없는 up -d 를 부르지 마세요.** 새 판이 올라온다."
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 「지우는 문장」을 센다 — 앱의 migration-safety.ts 와 **같은 잣대**로
#
#  🔴 「DELETE」 만으로 세지 않는다. 외래키의 ON DELETE 가 걸려서 **표만 더하는
#     판이 ✗ 가 된다**(19번이 그 자리에서 넘어졌다).
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

# ══════════════════════════════════════════════════════════════════════
#  🔴 A/S 의 drizzle 은 **이미지 안이 아니라 볼륨**이다
#      /volume1/dss/as-migrations → tools-as 의 /app/drizzle (읽기 전용)
#  🔴 .sql 만 가는 것으로는 부족하다 — **meta/_journal.json 과 snapshot 까지**
#     가야 한다. _journal.json 이 옛것이면 drizzle 은 새 .sql 을 **아예 모르고**
#     적용이 0건으로 조용히 끝난다.
# ══════════════════════════════════════════════════════════════════════
MIG_N_SQL=0; MIG_N_J=0; MIG_STATE=""
read_migdir() { # MIG_N_SQL · MIG_N_J · MIG_STATE 를 채운다
  MIG_N_SQL=0; MIG_N_J=0; MIG_STATE=""
  [ -d "$MIGDIR" ] || { MIG_STATE=NODIR; return 0; }
  MIG_N_SQL=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  [ -f "$MIGDIR/meta/_journal.json" ] \
    && MIG_N_J=$(grep -c '"tag"' "$MIGDIR/meta/_journal.json" 2>/dev/null | tr -d ' ')
  MIG_N_SQL=${MIG_N_SQL:-0}; MIG_N_J=${MIG_N_J:-0}
  if [ "$MIG_N_SQL" = "$AS_MIG_WANT" ] && [ "$MIG_N_J" = "$AS_MIG_WANT" ]; then
    MIG_STATE=DONE
  elif [ "$MIG_N_SQL" = "$AS_MIG_HAVE" ] && [ "$MIG_N_J" = "$AS_MIG_HAVE" ]; then
    MIG_STATE=OLD
  else
    MIG_STATE=ODD
  fi
  return 0
}
# 새 .sql 둘이 실제로 그 폴더에 있고 **그 글자**를 들고 있는가
check_new_migs() {
  # 🔴 local 을 빠뜨리면 부르는 쪽(run_checks)의 같은 이름 변수를 덮어쓴다.
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
  f=$(ls -1 "$MIGDIR/0116_"*.sql 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    grep -qF "$MIG_MARK_0116" "$f" \
      && ok "0116 안에 그 글자가 있다 ($(basename "$f"))" \
      || { bad "🔴 0116 안에 $MIG_MARK_0116 가 **없다** — 다른 파일이다"; rc=1; }
    destructive_scan "$f" "A/S 0116" "$MIG_DROP_WANT"
  fi
  f=$(ls -1 "$MIGDIR/0117_"*.sql 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    grep -qF "$MIG_MARK_0117" "$f" \
      && ok "0117 안에 그 글자가 있다 ($(basename "$f"))" \
      || { bad "🔴 0117 안에 $MIG_MARK_0117 가 **없다** — 다른 파일이다"; rc=1; }
    destructive_scan "$f" "A/S 0117" "$MIG_DROP_WANT"
  fi
  return "$rc"
}
# 🔴 묶음을 푸는 쪽. **--migrate 에서만 불린다.** 28번 2197~2213줄의 방식이다.
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
#  🔴 이미지 **안에** 이번 판이 들어 있는가 — 글자로 본다
#
#  🔴 「아직 안 실린 것」은 ✗ 가 아니다. 못 봤다고 말하고 넘어간다.
#  🔴 대조 표시(CTRL)가 안 나오면 **판정하지 않는다** — 「글자를 못 읽은 것」과
#     「옛 판인 것」을 가를 수 없기 때문이다(19번 이래의 규율).
# ══════════════════════════════════════════════════════════════════════
CTRL='SSO_REDIRECT_URI'
# A/S 2.8 에만 있는 글자 둘 (2.7 에는 없다)
AS_NEW1='MATCHER_INSPECTION_REPORT_TEMPLATE_PATH'
AS_NEW2='GENERATOR_REPAIR_REPORT_TEMPLATE_PATH'
# A/S 2.7 에서 들어온 것이 2.8 에도 그대로 있는가 (회귀)
AS_KEEP1='QUOTE_ARCHIVE_UNC_ROOT'
AS_KEEP2='PURCHASE_ORDER_ARCHIVE_UNC_ROOT'
# PO 0.6 에만 있는 글자 둘 (0.5 에는 없다)
PO_NEW1='INVENTORY_API_BASE_URL'
PO_NEW2='AS_WRITE_TOKEN'
PO_KEEP1='QUOTE_ARCHIVE_UNC_ROOT'
PO_KEEP2='AS_APP_BASE_URL'

inside_check() { # 1 태그 2 라벨 3 옛태그 4 새글자1 5 새글자2 6 회귀1 7 회귀2
  local tag="$1" label="$2" old="$3" w1="$4" w2="$5" k1="$6" k2="$7"
  local out c a b d e
  if ! have_img "$tag"; then
    notloaded "$tag 가 아직 NAS 에 없어 **안을 못 봤다** — 먼저 실으세요"
    cmd "bash $0 --preload"
    return 0
  fi
  # 🔴 글자는 **-e 로 넘긴다.** sh -c 본문에 끼워 넣으면 괄호·물음표가 든
  #    글자에서 조용히 깨진다. 결과는 한 줄에 0/1 다섯 개로 받는다.
  out=$("$DOCKER" run --rm \
        -e C="$CTRL" -e W1="$w1" -e W2="$w2" -e K1="$k1" -e K2="$k2" \
        --entrypoint sh "$tag" -c '
    r=""
    for w in "$C" "$W1" "$W2" "$K1" "$K2"; do
      if grep -rlF -- "$w" /app/.next >/dev/null 2>&1; then r="$r 1"; else r="$r 0"; fi
    done
    echo "INSIDE$r"' 2>/dev/null \
    | grep '^INSIDE ' | head -1)
  c=$(printf '%s' "$out" | awk '{print $2}')
  a=$(printf '%s' "$out" | awk '{print $3}')
  b=$(printf '%s' "$out" | awk '{print $4}')
  d=$(printf '%s' "$out" | awk '{print $5}')
  e=$(printf '%s' "$out" | awk '{print $6}')
  if [ "${c:-0}" != 1 ]; then
    say "    ⚠️ $tag 안을 글자로 뒤지지 못했다 — 대조 표시($CTRL)도 안 나왔다."
    say "       🔴 **판정하지 않는다.** 지어내지 않고 못 읽었다고 적는다."
    return 0
  fi
  ok "$label · 대조 표시($CTRL)를 찾았다 — 안을 실제로 읽었다는 뜻이다"
  [ "${a:-0}" = 1 ] && ok "$label · 새 글자 $w1 가 있다 — **$tag 의 모습이다**" \
    || bad "🔴 $label · $w1 가 **없다** — $old 를 올린 것이다"
  [ "${b:-0}" = 1 ] && ok "$label · 새 글자 $w2 가 있다" \
    || bad "🔴 $label · $w2 가 **없다** — $old 를 올린 것이다"
  [ "${d:-0}" = 1 ] && ok "$label · 회귀 — $k1 가 그대로 있다" \
    || bad "🔴 $label · $k1 가 **사라졌다** — $old 보다 **옛 판**을 올린 것이다"
  [ "${e:-0}" = 1 ] && ok "$label · 회귀 — $k2 가 그대로 있다" \
    || bad "🔴 $label · $k2 가 **사라졌다** — $old 보다 **옛 판**을 올린 것이다"
}

# 🔴 이미지 안 /app/drizzle 의 .sql 을 센다 — **118 이어야 한다**
img_mig_count() { # 1 태그 → 개수 (못 읽으면 빈 문자열)
  "$DOCKER" run --rm --entrypoint sh "$1" \
    -c "ls -1 $IMG_MIGDIR/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' ' | head -1
}
img_mig_check() { # 1 태그 2 라벨 3 기대값
  # 🔴 local 을 빠뜨리면 부르는 쪽의 같은 이름 변수를 덮어쓴다.
  local tag="$1" label="$2" want="$3" n out t
  if ! have_img "$tag"; then
    notloaded "$label · $tag 가 아직 NAS 에 없어 이미지 안 .sql 을 못 셌다"
    return 0
  fi
  n=$(img_mig_count "$tag")
  if [ -z "$n" ]; then
    say "    ⚠️ $label · 이미지 안을 못 읽었다. 🔴 **판정하지 않는다** —"
    say "       0 을 「0건이니 통과」로 읽지 않는다."
    return 0
  fi
  if [ "$n" = "$want" ]; then
    ok "$label · 이미지 안 $IMG_MIGDIR 의 .sql 이 ${n}장이다"
  else
    bad "🔴 $label · 이미지 안 .sql 이 ${n}장이다 (${want}장이어야 한다)"
    say "    → ${AS_MIG_HAVE}장이면 **옛 이미지를 구운 것**이다. 다시 구우세요."
    return 1
  fi
  # 🔴 개수만으로는 부족하다 — **이름을 하나씩** 본다
  out=$("$DOCKER" run --rm -e M="$AS_NEW_MIGS" --entrypoint sh "$tag" -c '
    for t in $M; do
      if ls -1 /app/drizzle/${t}_*.sql >/dev/null 2>&1; then
        echo "MIGHAS $t 1"
      else
        echo "MIGHAS $t 0"
      fi
    done' 2>/dev/null)
  for t in $AS_NEW_MIGS; do
    if printf '%s\n' "$out" | grep -qx "MIGHAS $t 1"; then
      ok "$label · 이미지 안에 ${t} 의 .sql 이 있다"
    else
      bad "🔴 $label · 이미지 안에 ${t} 의 .sql 이 **없다**"
    fi
  done
  return 0
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
#  🔴 【이번 배포의 알맹이】 **쓰기 통로를 값으로 재어 본다**
#
#  🔴 아무것도 안 바꾼다 — 라우트의 **맨 첫 줄이 토큰 문지기**라 그 앞에서
#     돌아선다(DB 를 두드리지 않는다). id 도 없는 0 UUID 다.
#     · 404 → 통로가 없다 = **옛 이미지(2.7)** 가 돌고 있다
#     · 503 → 통로는 있는데 **AS_WRITE_TOKEN 이 컨테이너 안에 없다**
#     · 401 → 통로가 있고 토큰 검사가 돈다 = **맞다**
# ══════════════════════════════════════════════════════════════════════
write_gate_probe() { # 1 라벨 2 기대(401|404)
  local label="$1" want="$2" code
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 -X POST \
         "http://127.0.0.1:$AS_PORT$WRITE_PATH" 2>/dev/null)
  say "    · POST $WRITE_PATH → ${code:-없음}"
  case "${code:-}" in
    401) if [ "$want" = 401 ]; then
           ok "$label · 쓰기 통로가 **있고 토큰 검사가 돈다** (401 — 맞다)"
         else
           bad "🔴 $label · 벌써 401 이다 — 새 이미지가 이미 돌고 있다 (기대 $want)"
         fi ;;
    404) if [ "$want" = 404 ]; then
           ok "$label · 아직 통로가 없다 (404 — **배포 전이라 맞다**)"
         else
           bad "🔴 $label · 쓰기 통로가 **404** 다 — 🔴 옛 이미지가 돌고 있다"
           say "      PO 의 [완료 처리]·[완료 해제]가 그 자리에서 실패한다."
         fi ;;
    503) bad "🔴 $label · **503** — 통로는 있는데 AS_WRITE_TOKEN 이 컨테이너 안에 없다"
         say "      → as.env 에 그 줄이 갔는지, 컨테이너를 다시 띄웠는지 보세요." ;;
    000|"") bad "🔴 $label · 대답이 없다 (${code:-없음}) — 앱이 안 떠 있다" ;;
    *)   say "    ⚠️ $label · ${code} 가 왔다. 🔴 **판정하지 않는다** — 기대는 $want 였다" ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 PO 가 **실제로** 재고 관리와 A/S 를 부를 수 있는가 — 컨테이너 안에서
#
#  🔴 「설정이 있다」는 조용히 통과한다. 그래서 **값을 받아 본다.**
#  🔴 토큰도 본문도 한 글자도 안 찍는다 — HTTP 번호만 찍는다.
#  🔴 A/S 쪽은 **GET** 으로 두드린다. 쓰기 통로라 GET 은 405 가 맞고,
#     405 가 오면 「통로가 있고 PO 가 거기까지 닿는다」가 증명된다.
#     🔵 백틱을 쓰지 않으려고 문자열은 전부 더하기로 잇는다.
# ══════════════════════════════════════════════════════════════════════
PO_PROBE_JS='
function tag(name, value) { console.log("POPROBE " + name + " " + value); }
function call(name, url, token, method) {
  if (url === "") { tag(name, "NOURL"); return Promise.resolve(); }
  if (token === null) { token = ""; }
  var ac = new AbortController();
  var timer = setTimeout(function () { ac.abort(); }, 8000);
  var opt = { method: method, signal: ac.signal, headers: {} };
  if (token !== "") { opt.headers.authorization = "Bearer " + token; }
  return fetch(url, opt)
    .then(function (res) { tag(name, String(res.status)); })
    .catch(function (err) { tag(name, "ERR " + ((err && err.name) || "unknown")); })
    .then(function () { clearTimeout(timer); });
}
var invBase = (process.env.INVENTORY_API_BASE_URL || "").trim().replace(/\/+$/, "");
var invTok = (process.env.INVENTORY_API_TOKEN || "").trim();
var asBase = (process.env.AS_APP_BASE_URL || "").trim().replace(/\/+$/, "");
tag("INVTOKLEN", String(invTok.length));
tag("WRTOKLEN", String((process.env.AS_WRITE_TOKEN || "").trim().length));
call("INV", invBase === "" ? "" : invBase + "/api/v1/parts", invTok, "GET")
  .then(function () {
    return call("AS", asBase === "" ? "" : asBase + "/api/v1/domestic-orders/00000000-0000-0000-0000-000000000000/completion", "", "GET");
  });
'
po_probe() {
  local out v
  if ! running "$PO_CNAME"; then
    bad "$PO_CNAME 가 안 돌고 있어 **값으로 못 재 봤다**"
    return 1
  fi
  out=$("$DOCKER" exec "$PO_CNAME" node -e "$PO_PROBE_JS" 2>&1)
  if ! printf '%s\n' "$out" | grep -q '^POPROBE '; then
    say "    ⚠️ PO 안에서 node 가 대답하지 않았다. 🔴 **판정하지 않는다** —"
    printf '%s\n' "$out" | sed 's/^/      /' | head -6
    return 0
  fi
  v=$(printf '%s\n' "$out" | sed -n 's/^POPROBE INVTOKLEN //p' | head -1)
  [ "${v:-0}" -ge 1 ] 2>/dev/null \
    && ok "PO · INVENTORY_API_TOKEN 이 컨테이너 안에 있다 (${v}자 · 🔴 값은 안 찍는다)" \
    || bad "🔴 PO · INVENTORY_API_TOKEN 이 컨테이너 안에 **없다**"
  v=$(printf '%s\n' "$out" | sed -n 's/^POPROBE WRTOKLEN //p' | head -1)
  [ "${v:-0}" = "$TOKEN_LEN" ] \
    && ok "PO · AS_WRITE_TOKEN 이 ${v}자로 들어 있다" \
    || bad "🔴 PO · AS_WRITE_TOKEN 이 ${v:-0}자다 (${TOKEN_LEN}자여야 한다)"
  v=$(printf '%s\n' "$out" | sed -n 's/^POPROBE INV //p' | head -1)
  say "    · PO → 재고 관리 GET /api/v1/parts → ${v:-못 읽음}"
  case "${v:-}" in
    200) ok "🔴 PO 가 재고 관리를 **실제로 읽는다** (200)" ;;
    401|403) bad "🔴 PO 의 재고 토큰이 **안 맞는다** ($v) — as.env 에서 복사한 값이 틀렸다" ;;
    NOURL)   bad "🔴 PO 에 INVENTORY_API_BASE_URL 이 **없다**" ;;
    ERR*)    bad "🔴 PO 가 재고 관리에 **닿지 못했다** ($v) — 주소나 네트워크다" ;;
    "")      say "    ⚠️ 못 읽었다 — 판정하지 않는다" ;;
    *)       say "    ⚠️ $v 가 왔다. 🔴 판정하지 않는다 — 사람이 화면에서 보세요" ;;
  esac
  v=$(printf '%s\n' "$out" | sed -n 's/^POPROBE AS //p' | head -1)
  say "    · PO → A/S  GET …/completion → ${v:-못 읽음}  (🔵 GET 이라 405 가 맞다)"
  case "${v:-}" in
    405) ok "🔴 PO 가 A/S 의 **쓰기 통로까지 닿는다** (405 — 통로가 있다는 뜻)" ;;
    404) bad "🔴 PO 가 A/S 의 쓰기 통로를 **못 찾는다**(404) — A/S 가 아직 옛 판이다" ;;
    401) ok "PO 가 A/S 의 쓰기 통로에 닿는다 (401 — 통로가 있다)" ;;
    NOURL) bad "🔴 PO 에 AS_APP_BASE_URL 이 **없다**" ;;
    ERR*)  bad "🔴 PO 가 A/S 에 **닿지 못했다** ($v)" ;;
    "")    say "    ⚠️ 못 읽었다 — 판정하지 않는다" ;;
    *)     say "    ⚠️ $v 가 왔다. 🔴 판정하지 않는다" ;;
  esac
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 양식을 **컨테이너 안에서** 본다 — 호스트에서 보는 것으로는 부족하다
#     볼륨이 :ro 로 제대로 붙었는지가 핵심이다.
# ══════════════════════════════════════════════════════════════════════
tpl_in_box() { # 1 컨테이너 2 라벨 3 기대 장수
  local cname="$1" label="$2" want="$3" n f
  if ! running "$cname"; then
    say "  · $cname 가 안 돌고 있어 /templates 를 못 봤다"
    return 0
  fi
  n=$("$DOCKER" exec "$cname" sh -c 'ls -1 /templates 2>/dev/null | wc -l' 2>/dev/null | tr -d ' ')
  if [ "${n:-0}" = "$want" ]; then
    ok "$label · 컨테이너 안 /templates 에 **${n}장**이 보인다"
  else
    bad "🔴 $label · 컨테이너 안 /templates 가 ${n:-0}장이다 (${want}장이어야 한다)"
  fi
  for f in $TPL_NAMES; do
    "$DOCKER" exec "$cname" sh -c "[ -f '/templates/$f' ]" >/dev/null 2>&1 \
      && ok "$label · /templates/$f 를 읽는다" \
      || bad "🔴 $label · /templates/$f 가 **안 보인다**"
  done
  for f in $TPL_KEEP; do
    "$DOCKER" exec "$cname" sh -c "[ -f '/templates/$f' ]" >/dev/null 2>&1 \
      && ok "$label · 물러설 자리 /templates/$f 도 그대로 있다" \
      || bad "🔴 $label · /templates/$f 가 **사라졌다** — 손대지 않기로 한 파일이다"
  done
  return 0
}

# 🔴 출하 완료 줄의 역할 분포를 **보여 준다** (select 만)
wf_show() { # 1 라벨
  say "  $1 — 출하 완료($WF_ACTION) 줄의 역할 분포:"
  qqas "select array_to_string(allowed_roles, ',') as roles, count(*) from workflow_transitions where action_code = '$WF_ACTION' group by 1 order by 2 desc" \
    | sed 's/^/      /'
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
# ══════════════════════════════════════════════════════════════════════
EXP_AS=""; EXP_PO=""; SVCS=""; MIG_DB_NOW=""

see_tar() { # 1 태그 2 tar 3 tar에서읽은지문 4 기대바이트 5 기대md5 6 기대지문 7 올릴이름
  local tag="$1" f="$2" got="$3" wsz="$4" wmd5="$5" wcfg="$6" up="$7" n m
  if [ ! -s "$f" ]; then
    notyet "$tag 의 tar 가 아직 NAS 에 없다: $f"
    say "    → 개발 PC(PowerShell)에서 올리세요. 🔴 scp 에 -O 를 붙입니다:"
    cmd "scp -O $up dss-nas:/volume1/dss/images/"
    return 1
  fi
  n=$(stat -c '%s' "$f" 2>/dev/null)
  m=$(md5_of "$f")
  say "    · 지금 이 tar: 바이트 ${n:-?} · md5 ${m:-?}"
  if [ -z "$wsz" ] || [ -z "$wmd5" ] || [ -z "$wcfg" ]; then
    say "    ⚠️ 🔴 **$tag 의 기대값이 비어 있다.** 개발 PC 에서 구운 뒤 이 파일"
    say "       머리말의 차례대로 재어 채우세요. 채우기 전에는 --migrate 도"
    say "       --go 도 시작하지 않습니다."
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
  local s t f db n_bk nlog k n n2 code h v FREE_KB FREE_H

  # ── 1-ㄱ. 올린 파일 ─────────────────────────────────────────────────
  step "1-ㄱ. 올린 파일 — 이미지 tar **둘** · 양식 **넷** · 마이그레이션 묶음"
  say "  🔵 2026-10-19 기준 tar 둘과 양식 넷은 **이미 올라가 있다**(대조 완료)."
  say "     🔴 마이그레이션 묶음은 아래 1-ㄷ 에서 폴더를 세어 보고 정한다."
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  EXP_PO=$(tar_config_id "$TAR_PO" 2>/dev/null) || EXP_PO=""
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS" "$SZ_AS" "$MD5_AS" "$WANT_CFG_AS" dss-as-2.8.tar
  see_tar "$TAG_PO" "$TAR_PO" "$EXP_PO" "$SZ_PO" "$MD5_PO" "$WANT_CFG_PO" dss-po-0.6.tar
  say "  🔴 tar 가 이미지의 1/4 쯤인 것은 **정상**이다 — 2.8 은 이미지 599MB 에"
  say "     tar 132,020,224 바이트다. 지난 판: 2.7 → 131,561,472 · 0.4 → 95,424,000."

  # ── 1-ㄴ. NAS 에 실린 이미지 ─────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (올라가는 둘 · 되돌릴 옛것 둘)"
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
  say "     그냥 부르는 것으로는 안 바뀐다 — --force-load 를 쓰세요."
  say "  🔴 되돌아갈 옛 이미지 둘 — 되돌리기가 그것을 쓴다. **지우지 마세요.**"
  have_img "$OLD_AS" && ok "$OLD_AS 가 아직 있다 (되돌릴 길이 열려 있다)" \
    || bad "🔴 $OLD_AS 가 NAS 에 없다 — 되돌리려면 tar 를 다시 올려야 한다"
  have_img "$OLD_PO" && ok "$OLD_PO 가 아직 있다 (되돌릴 길이 열려 있다)" \
    || bad "🔴 $OLD_PO 가 NAS 에 없다 — 되돌리려면 tar 를 다시 올려야 한다"

  # ── 1-ㄷ. 🔴 마이그레이션 — 값 넷으로 센다 ───────────────────────────
  step "1-ㄷ. 🔴 마이그레이션 둘 (0116 · 0117) — 값 **넷**으로 센다"
  say "  🔴 ① 운영 DB · ② 볼륨의 .sql · ③ 볼륨의 _journal.json · ④ 이미지 안 .sql"
  say "     🔵 적용을 **돌리는** 쪽은 ②③ 이다. ④ 는 「코드가 그 둘을 안다」는 증언이다."
  if pg_up; then
    MIG_DB_NOW=$(as_mig_count); MIG_DB_NOW=${MIG_DB_NOW:-0}
    say "  ① 운영 DB 에 적용된 줄: ${MIG_DB_NOW}"
    if [ "$MIG_DB_NOW" = "$AS_MIG_HAVE" ]; then
      ok "① 아직 $AS_MIG_HAVE 이다 — **--migrate 가 둘을 올린다**"
    elif [ "$MIG_DB_NOW" = "$AS_MIG_WANT" ]; then
      ok "① **이미 $AS_MIG_WANT 이다** — 마이그레이션은 끝났다"
    else
      bad "🔴 ① 운영 DB 가 $AS_MIG_HAVE 도 $AS_MIG_WANT 도 아니다 (${MIG_DB_NOW})"
      say "    → 고치지 말고 **먼저 알리세요.**"
    fi
    say "  마지막 다섯:"
    qas "select id || ' · ' || to_timestamp(created_at/1000)::date from drizzle.__drizzle_migrations order by id desc limit 5" \
      | head -5 | sed 's/^/      /'
  else
    bad "dss-pg-app 이 안 떠 있다 — 마이그레이션 줄을 못 셌다"
    MIG_DB_NOW=""
  fi
  read_migdir
  say "  ②③ 볼륨 $MIGDIR — .sql ${MIG_N_SQL}장 · _journal.json 의 tag ${MIG_N_J}줄"
  case "$MIG_STATE" in
    DONE)
      ok "②③ **이미 $AS_MIG_WANT 이다** — 올릴 묶음이 없다"
      check_new_migs || true ;;
    OLD)
      say "    🔴 아직 $AS_MIG_HAVE 이다 — **0116 · 0117 이 그 폴더에 없다.**"
      say "       그대로 두면 적용이 **0건으로 조용히 끝난다**(drizzle 은"
      say "       _journal.json 에 없는 .sql 을 아예 모른다)."
      if [ -s "$MIGTAR" ]; then
        ok "묶음이 올라와 있다 — **--migrate 가 갈아 끼운다** ($MIGTAR)"
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
    NODIR)
      bad "🔴 $MIGDIR 폴더가 **없다** — compose 가 tools-as 에 붙이는 그 폴더다" ;;
    *)
      bad "🔴 볼륨이 $AS_MIG_HAVE 도 $AS_MIG_WANT 도 아니다 (.sql ${MIG_N_SQL} · tag ${MIG_N_J})"
      say "    → 고치지 말고 **먼저 알리세요.**" ;;
  esac
  say "  ④ 이미지 안 $IMG_MIGDIR:"
  img_mig_check "$TAG_AS" "$TAG_AS" "$AS_MIG_WANT" || true
  if have_img "$OLD_AS"; then
    n=$(img_mig_count "$OLD_AS")
    say "    · 견줌 — $OLD_AS 안에는 ${n:-?}장 (이것이 $AS_MIG_HAVE 이면 자연스럽다)"
  fi

  # ── 1-ㄹ. 🔴 0117 이 건드릴 줄 — 적용 **전** 분포를 적어 둔다 ────────
  step "1-ㄹ. 🔴 0117 이 건드릴 줄 — 적용 전 분포 (🔴 select 만 한다)"
  say "  🔴 **인가 경계를 넓히는 변경**이다. 출하 완료를 담당 엔지니어와 영업도"
  say "     누를 수 있게 된다 — 내자 정리의 완료 처리뿐 아니라 **수리건 화면의"
  say "     [출하 완료] 단추도 함께 열린다.** 2026-10-18 사용자 결정이다."
  if pg_up; then
    n=$(wf_rows); n=${n:-0}
    n2=$(wf_rows_both); n2=${n2:-0}
    say "  · $WF_ACTION 줄: ${n} (2026-10-19 실측 $WF_ROWS_WANT · 개발은 22)"
    if [ "$n" = "$WF_ROWS_WANT" ]; then
      ok "줄 수가 실측값 $WF_ROWS_WANT 과 같다"
    else
      say "    ⚠️ 줄 수가 실측값($WF_ROWS_WANT)과 다르다 (${n}). 🔴 **✗ 로 세지 않는다** —"
      say "       그 사이 워크플로 판이 늘었을 수 있다. 🔴 적용 뒤에는 **지금 이 수**"
      say "       전부가 두 역할을 가져야 한다. 아래 수를 적어 두세요."
    fi
    say "  · 그중 이미 두 역할을 다 가진 줄: ${n2} (적용 뒤 **${n}** 이어야 한다)"
    wf_show "  "
  else
    bad "dss-pg-app 이 안 떠 있다 — 분포를 못 봤다"
  fi

  # ── 1-ㅁ. 🔴 양식 네 장 ──────────────────────────────────────────────
  step "1-ㅁ. 🔴 양식 네 장 (지금 ${TPL_COUNT_HAVE}장 → **${TPL_COUNT_WANT}장**)"
  say "  🔴 기존 「검사보고서.xlsx」·「수리보고서.xlsx」 두 장은 **손대지 않는다**"
  say "     — 코드가 제품 종류를 모를 때 물러서는 자리다(2026-10-19 사용자 결정)."
  if [ -d "$TEMPLATES" ]; then
    n=$(ls -1 "$TEMPLATES" 2>/dev/null | wc -l | tr -d ' ')
    say "  · 지금 호스트 폴더: ${n}장  ($(stat -c '%A %u:%g' "$TEMPLATES" 2>/dev/null))"
    for f in $TPL_KEEP; do
      [ -f "$TEMPLATES/$f" ] && ok "물러설 자리 「$f」 가 있다" \
        || bad "🔴 「$f」 가 **없다** — 주인·모드를 베껴 올 짝이기도 하다"
    done
  else
    bad "🔴 양식 폴더가 없다: $TEMPLATES"
  fi
  see_tpl 1 "$TPL1_NAME" "$TPL1_MD5" || true
  see_tpl 2 "$TPL2_NAME" "$TPL2_MD5" || true
  see_tpl 3 "$TPL3_NAME" "$TPL3_MD5" || true
  see_tpl 4 "$TPL4_NAME" "$TPL4_MD5" || true
  say "  🔴 호스트에서 보는 것으로는 부족하다 — **컨테이너 안**에서도 본다:"
  if [ "$TPL1_STATE" = DONE ] && [ "$TPL2_STATE" = DONE ] \
     && [ "$TPL3_STATE" = DONE ] && [ "$TPL4_STATE" = DONE ]; then
    tpl_in_box "$AS_CNAME" "A/S" "$TPL_COUNT_WANT"
  else
    say "    🔵 아직 네 장을 안 놓았다 — 지금은 $TPL_COUNT_HAVE 장이 맞다."
    n=$("$DOCKER" exec "$AS_CNAME" sh -c 'ls -1 /templates 2>/dev/null | wc -l' 2>/dev/null | tr -d ' ')
    say "    · 컨테이너 안 /templates: ${n:-못 봤다}장"
  fi

  # ── 1-ㅂ. compose ───────────────────────────────────────────────────
  step "1-ㅂ. compose ($CF)"
  say "  🔴 이번 판에서 compose 가 바뀌는 자리는 **셋**이다:"
  say "     ㄱ) app-as 의 image ($OLD_AS → $TAG_AS)"
  say "     ㄴ) app-po 의 image ($OLD_PO → $TAG_PO)"
  say "     ㄷ) app-as 의 environment: 절에 **일곱 줄** (주석 셋 + 설정 넷)"
  say "     🔴 저장소 사본을 올리지 않는다 — 이 스크립트가 **제자리에서** 고친다."
  if compose_cmd config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_cmd config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  SVCS=$(compose_cmd config --services 2>/dev/null)
  for s in $SVC_ALL; do
    echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
      || bad "서비스 목록에 $s 가 없다 — 주석으로 꺼져 있다"
  done
  say "  태그 — 🔵 「아직(PENDING)」도 「이미 했다(DONE)」도 ✗ 가 아니다:"
  if compose_tags_done; then
    ok "compose 가 **이미 새 태그 둘**을 가리킨다 (DONE)"
  elif [ "$(img_line_count "$CF" "$OLD_AS")" = 1 ] && [ "$(img_line_count "$CF" "$OLD_PO")" = 1 ]; then
    say "    · 아직 옛 태그 둘이다 — **--go 가 고친다** (PENDING)"
  else
    bad "🔴 compose 의 태그가 기대한 모습이 아니다"
    say "      app-as: $(svc_image "$CF" "$AS_SVC")  /  app-po: $(svc_image "$CF" "$PO_SVC")"
    say "      → 남의 변경이 섞였을 수 있다. 고치지 말고 알리세요."
  fi
  say "  새 네 줄:"
  if compose_env_done; then
    ok "네 줄이 **이미 들어 있다** (DONE)"
    for k in $CF_NEW_KEYS; do
      n=$(svc_key_count "$CF" "$AS_SVC" "$k"); n2=$(svc_key_count "$CF" "$PO_SVC" "$k")
      [ "$n" = 1 ] && [ "$n2" = 0 ] && ok "$k — app-as 1줄 · app-po 0줄" \
        || bad "🔴 $k — app-as ${n}줄 · app-po ${n2}줄"
    done
  else
    n=0
    for k in $CF_NEW_KEYS; do n=$((n + $(cf_key_count "$CF" "$k"))); done
    if [ "$n" = 0 ]; then
      say "    · 아직 0줄이다 — **--go 가 넣는다** (PENDING)"
    else
      bad "🔴 네 줄 중 ${n}줄만 있다 — 반만 들어간 상태다. 고치지 말고 알리세요"
    fi
  fi
  say "  🔴 물러설 자리 두 줄 (**지우지 않는다**):"
  for k in $CF_KEEP_KEYS; do
    [ "$(svc_key_count "$CF" "$AS_SVC" "$k")" = 1 ] && ok "app-as 에 $k 한 줄" \
      || bad "🔴 app-as 의 $k 가 1줄이 아니다"
  done
  say "  🔴 볼륨 — 이번 판은 **하나도 더하지 않는다.** 사라지지 않았는지만 본다:"
  for s in "$AS_SVC" "$PO_SVC"; do
    svc_block "$CF" "$s" | grep -q "$TEMPLATES:/templates" \
      && ok "$s 가 양식 폴더($TEMPLATES)를 읽기 전용으로 붙인다" \
      || bad "🔴 $s 의 양식 볼륨이 $TEMPLATES 가 아니다 — 보고서 출력이 죽는다"
    svc_block "$CF" "$s" | grep -q "$ATT:/data" \
      && ok "$s 가 첨부 폴더($ATT)를 붙인다" \
      || bad "🔴 $s 의 첨부 볼륨이 $ATT 가 아니다"
    svc_block "$CF" "$s" | grep -q 'group_add' \
      && ok "$s 에 group_add 가 있다 (공유폴더의 ACL 때문이다)" \
      || bad "🔴 $s 에 group_add 가 없다 — 공유폴더에 Permission denied 가 난다"
  done
  svc_block "$CF" tools-as | grep -q "$MIGDIR:$IMG_MIGDIR" \
    && ok "tools-as 가 $MIGDIR 를 $IMG_MIGDIR 로 붙인다 (적용이 그 폴더를 읽는다)" \
    || bad "🔴 tools-as 의 drizzle 볼륨이 $MIGDIR 가 아니다 — **적용이 엉뚱한 것을 읽는다**"
  svc_block "$CF" "$AS_SVC" | grep -q "$AS_PORT:3000" \
    && ok "app-as 가 127.0.0.1:$AS_PORT 으로 열린다" \
    || bad "app-as 의 포트가 $AS_PORT:3000 이 아니다"
  svc_block "$CF" "$PO_SVC" | grep -q "$PO_PORT:3600" \
    && ok "app-po 가 127.0.0.1:$PO_PORT 으로 열린다" \
    || bad "app-po 의 포트가 $PO_PORT:3600 이 아니다"
  svc_block "$CF" db-app | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-app 에 ports: 가 생겼다 — 사내 전용 원칙을 깬다. 고치지 말고 알리세요" \
    || ok "db-app 에 ports: 가 없다 (DB 는 호스트 포트를 하나도 안 연다)"
  v=$(svc_block "$CF" "$AS_SVC" | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  n=$(svc_block "$CF" "$PO_SVC" | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  if [ -n "$n" ] && [ "$v" = "$n" ]; then
    ok "app-po 의 DATABASE_URL 이 app-as 와 **글자까지 같다** (둘이 같은 DB 를 쓴다)"
  else
    bad "🔴 app-po 의 DATABASE_URL 이 app-as 와 다르다 — PO 가 엉뚱한 DB 를 본다"
  fi

  # ── 1-ㅅ. 🔴 설정 넷 ────────────────────────────────────────────────
  step "1-ㅅ. 🔴 설정 넷 — as.env 한 줄 · po.env 세 줄 (🔴 값은 안 찍는다)"
  say "  🔴 이 PC(dss-deploy)의 nas/env/*.env 를 NAS 로 **올리지 마세요.**"
  say "     그 사본에는 NAS 에만 있는 줄들이 빠져 있습니다."
  if [ -f "$AS_ENV" ]; then
    s=$(stat -c '%a' "$AS_ENV" 2>/dev/null)
    [ "$s" = 600 ] && ok "as.env 있다 · 모드 600" \
      || bad "as.env 의 모드가 ${s:-?} 다 (600 이어야 한다 — 남이 읽는다)"
    s=$(stat -c '%U:%G' "$AS_ENV" 2>/dev/null)
    [ "$s" = "root:root" ] || bad "as.env 의 주인이 ${s:-?} 다 (root:root 이어야 한다)"
    for t in $AS_FORBIDDEN; do
      grep -q "^$t=" "$AS_ENV" && bad "as.env 에 $t 가 **있다** — 지우세요(compose 가 넘긴다)"
    done
    say "  🔴 그대로 있어야 하는 줄들 (사라졌으면 누가 덮어쓴 것이다):"
    env_keys_present "$AS_ENV" "as.env" "$AS_QUOTE_KEYS" "견적서 [폴더 열기]가 죽는다"
    env_keys_present "$AS_ENV" "as.env" "$AS_PORTAL_KEYS" "[공유폴더에 저장]이 실패로 끝난다"
    env_keys_present "$AS_ENV" "as.env" "$AS_OTHER_KEYS" "그쪽 기능이 통째로 죽는다"
    say "  🔴 **PO 로 복사해 갈 원본 둘** — 없으면 --go 가 시작하지 않는다:"
    env_keys_present "$AS_ENV" "as.env" "$AS_SRC_KEYS" "PO 가 재고 관리를 못 읽는다 — 사람이 값을 가져와야 한다"
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
    env_keys_present "$PO_ENV" "po.env" "AS_APP_BASE_URL" "PO 가 A/S 주소를 모른다"
    for t in $PO_FORBIDDEN; do
      if [ "$(env_count_of "$PO_ENV" "$t")" != 0 ]; then
        bad "🔴 po.env 에 $t 가 **있다** — PO 는 읽기만 한다. 알 필요가 없는 값이다"
      else
        ok "po.env 에 $t 가 없다 (맞다 — PO 는 읽기만 한다)"
      fi
    done
  fi
  say "  🔴 이번에 적을 넷 — 🔵 ADD 도 SAME 도 ✗ 가 아니다:"
  if build_env_values 0; then
    say "    · AS_WRITE_TOKEN 의 출처: $WRITE_TOKEN_SRC"
    report_env_keys "$AS_ENV" "as.env" "$AS_NEW_KEYS"
    report_env_keys "$PO_ENV" "po.env" "$PO_NEW_KEYS"
  else
    say "    🔴 as.env 에서 값을 못 읽어 더 보지 않는다. **--go 는 여기서 멈춘다.**"
  fi
  if command -v openssl >/dev/null 2>&1; then
    ok "openssl 이 있다 (AS_WRITE_TOKEN 을 그것으로 만든다)"
  else
    say "    ⚠️ openssl 이 없다 — /dev/urandom 으로 만든다(27-inventory-pw.sh 와 같은 길)"
  fi

  # ── 1-ㅇ. 🔴 야간 백업 다섯 ─────────────────────────────────────────
  step "1-ㅇ. 야간 백업 다섯 · 야간 완전삭제 (읽기만 한다)"
  say "  🔴 이번 판은 **DB 를 바꾼다**(0116 · 0117). --migrate 는 오늘 뜬 $AS_DB"
  say "     백업이 없으면 **시작조차 않는다.** 야간 백업은 **02:30** 이다."
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
  fi
  say
  say "  야간 완전삭제 — DSM 작업 「DSS Purge」의 로그:"
  nlog=$(ls -1t "$D/setup/logs"/purge-*.log 2>/dev/null | wc -l | tr -d ' ')
  if [ "${nlog:-0}" -gt 0 ]; then
    ok "완전삭제 로그가 ${nlog}개 있다 — 스케줄러에 등록돼 돌고 있다"
  else
    bad "🔴 완전삭제 로그가 **하나도 없다** — 스케줄러에 등록이 안 된 것이다"
  fi

  # ── 1-ㅈ. 디스크 · DB · 지금 도는 것 ────────────────────────────────
  step "1-ㅈ. 디스크 · DB · 지금 도는 것"
  if pg_up && running dss-pg-auth; then
    ok "DB 둘 다 떠 있다 (이 배포에서 DB 컨테이너는 멈추지 않는다)"
  else
    bad "DB 가 떠 있지 않다"
  fi
  for t in dss-auth dss-as dss-meters dss-improvements dss-po dss-leave dss-board dss-inventory; do
    running "$t" && ok "$t 가 돌고 있다" || bad "$t 가 안 돌고 있다"
  done
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (tar 둘 + 실은 이미지 둘이 들어가야 한다)"
  fi

  # ── 1-ㅊ. 새 이미지 **안**을 본다 ───────────────────────────────────
  step "1-ㅊ. 새 이미지 안을 본다 — 🔴 글자로 본다 (태그는 거짓말을 한다)"
  say "  🔴 9/21~9/29 에 A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다."
  if have_img "$TAG_AS"; then
    say "  $TAG_AS 구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_AS" --format '{{.Size}}' 2>/dev/null) ($OLD_AS 는 590MB 대였다)"
    inside_check "$TAG_AS" "A/S" "$OLD_AS" "$AS_NEW1" "$AS_NEW2" "$AS_KEEP1" "$AS_KEEP2"
    say "  🔵 글자 인식기(public/ocr) 회귀 검사:"
    ocr_check "$TAG_AS"
  else
    notloaded "$TAG_AS 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
  fi
  if have_img "$TAG_PO"; then
    say "  $TAG_PO 구운 때: $("$DOCKER" images "$TAG_PO" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_PO" --format '{{.Size}}' 2>/dev/null)"
    inside_check "$TAG_PO" "PO" "$OLD_PO" "$PO_NEW1" "$PO_NEW2" "$PO_KEEP1" "$PO_KEEP2"
    say "  🔵 PO 에는 public/ 이 없다 — OCR 검사를 하지 않는다(그것이 맞다)."
  else
    notloaded "$TAG_PO 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
  fi

  # ── 1-ㅋ. 🔴 쓰기 통로의 **지금** 모습을 적어 둔다 ──────────────────
  step "1-ㅋ. 🔴 A/S 의 쓰기 통로 — **지금** 무엇이 오는가"
  say "  🔵 배포 전에는 **404 가 맞다**(2.7 에는 그 통로가 없다). 배포 뒤에는"
  say "     401 이어야 한다. 🔴 아무것도 안 바꾼다 — 문지기가 맨 첫 줄이라"
  say "     DB 를 두드리지 않고 돌아선다."
  if compose_tags_done; then
    write_gate_probe "A/S" 401
  else
    write_gate_probe "A/S" 404
  fi

  # ── 1-ㅌ. 바깥 주소 여덟 ────────────────────────────────────────────
  step "1-ㅌ. 바깥 주소 여덟 (지금 상태를 적어 둔다)"
  for h in $MOVE_HOSTS $KEEP_HOSTS; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$h.dss21.co.kr → $code" ;;
      *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
    esac
  done
}

# ══ 되돌리기 ═══════════════════════════════════════════════════════════
if [ "$MODE" = rollback ]; then
  echo "DSS 서른째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     되돌리는 것은 **compose 한 파일과 컨테이너 둘**이다:"
  say "       $TAG_AS → $OLD_AS"
  say "       $TAG_PO → $OLD_PO"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 **DB 는 되돌리지 않습니다.** 아래 까닭을 먼저 읽으세요.      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     · 0116 — customers 에 칸 하나를 더했습니다. 옛 판(2.7 · 0.5)은 그"
  say "       칸을 **모르고도 멀쩡히 돕니다**(drizzle 은 칸 이름을 적어서 묻습니다)."
  say "       그대로 두는 것이 맞습니다."
  say "     · 0117 — 🔴 **인가 경계를 넓혔습니다.** 거꾸로 돌리려면 「원래"
  say "       AS_ENGINEER 가 있던 줄」과 「이번에 생긴 줄」을 갈라야 하는데, 그"
  say "       구분은 적용 뒤 DB 에 **남지 않습니다.** 적용 전 분포는 --migrate 의"
  say "       로그에 적혀 있습니다. 🔴 스크립트는 되돌리는 SQL 을 짜 주지 않습니다 —"
  say "       사람이 그 로그를 보고 정해야 합니다."
  say "     · 양식 네 장 · 설정 넷 — **그대로 둡니다.** 옛 판은 그 넷을 읽지"
  say "       않고(compose 를 되돌리면 그 네 줄이 사라집니다), 양식 네 장은"
  say "       폴더에 있어도 아무도 안 읽습니다. 지울 까닭이 없습니다."
  say

  step "1. 옛 이미지가 아직 NAS 에 있는지 먼저 본다"
  have_img "$OLD_AS" && ok "$OLD_AS 있다 ($(img_id "$OLD_AS" | cut -c1-19)…)" \
    || bad "$OLD_AS 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"
  have_img "$OLD_PO" && ok "$OLD_PO 있다 ($(img_id "$OLD_PO" | cut -c1-19)…)" \
    || bad "$OLD_PO 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"

  step "2. compose 를 사본으로 되돌린다"
  say "  --go 가 고치기 **전에** 뜬 사본이다 (가장 최근 것):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -3 | sed 's/^/      /'
  cmd "cd /volume1/dss/deploy"
  cmd "ls -1t ../backups/docker-compose.nas.yml.* | head -1"
  say "      (그 이름을 보고 아래 한 줄을 치세요)"
  cmd "cp ../backups/docker-compose.nas.yml.<도장> docker-compose.nas.yml"
  cmd "grep -n 'image: dss-as\\|image: dss-po' docker-compose.nas.yml"
  say "      → dss-as:2.7 · dss-po:0.5 로 보여야 합니다."

  step "3. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  say "  🔴 올릴 때도 **A/S 가 먼저**다 — 되돌리는 길에서도 같다."
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-as"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-po"

  step "4. 🔴 사람에게 알릴 것"
  say "  · 🔴 PO 의 **[완료 처리]·[완료 해제]** 가 다시 안 됩니다(통로가 404)."
  say "  · 🔴 PO 의 견적서 **부품 고르개**가 다시 옛 목록으로 돌아갑니다."
  say "  · 🔴 검사·수리 보고서가 다시 **한 벌 양식**으로 나갑니다 — 매쳐 건에"
  say "    제너레이터 담당자의 도장이 찍히던 그 상태입니다."
  say "  · 🔵 그 밖에는 달라지지 않습니다."

  step "5. 지금 상태"
  say "  dss-as : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep '^dss-as ' || echo '안 돌고 있다')"
  say "  dss-po : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep '^dss-po ' || echo '안 돌고 있다')"
  say "  (포털 · 계측기 · 개선요청 · 휴가 · 게시판 · 재고 관리 · DB 둘은 이번에"
  say "   건드리지 않았습니다.)"
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터 check · preload · force-load · migrate · go ═══════════════
echo "DSS 서른째 배포 · $(date '+%F %T')"
echo "  이 파일의 md5: $(md5_of "$0")  ← 개발 PC 의 Get-FileHash 와 같아야 합니다"
echo "  🔴 올라가는 것 **둘**:  $OLD_AS → $TAG_AS · $OLD_PO → $TAG_PO"
echo "     (RF_Service_System 2812d40 · dss-po 696c6a0 — 둘 다 미커밋 0줄)"
echo "  🔴 멈추는 것도 **둘**:  $AS_CNAME · $PO_CNAME"
echo "  🔴 이 배포가 하는 일 여섯 — 이미지 둘 · 마이그레이션 둘(116→118) ·"
echo "     양식 네 장 · compose 네 줄 · 설정 넷 · **A/S 를 먼저 올린다**"
echo "  🔴 PO 의 완료 처리가 A/S 의 **새 쓰기 통로**를 부른다. A/S 가 구판이면"
echo "     404 다 — 그래서 app-as 를 올리고 **대답을 받은 뒤에** app-po 를 올린다."
echo "  🔵 야간 백업은 **02:30** — 자정 넘어 돌리면 백업 검사에 걸립니다"
echo "  🔵 안 멈추는 여섯 — 포털 · 계측기 · 개선요청 · 휴가 · 게시판 · 재고 관리"
echo "     (DB 둘도 안 멈춥니다. 시작 시각으로 대조합니다.)"
if ! pinned; then
  echo "  ⚠️ 🔴 **이미지 기대값 여섯이 비어 있습니다.**"
  echo "     개발 PC 에서 2.8 · 0.6 을 굽고 재어 채우기 전에는 --migrate 도 --go 도"
  echo "     시작하지 않습니다. 재는 차례는 이 파일 머리말에 있습니다."
fi
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**"
              echo "     🔵 아직 안 온 것 · 안 실린 것 · **이미 해 둔 것**은 ✗ 가 아니다." ;;
  preload)    echo "  🔵 --preload — 새 이미지 둘을 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  migrate)    echo "  🔴 --migrate — 마이그레이션 0116 · 0117. **DB 가 바뀐다.**"
              echo "     🔵 앱은 안 멈춘다 — 직원은 $OLD_AS · $OLD_PO 를 그대로 쓴다." ;;
  go)         echo "  🔴 --go — 양식 · compose · 설정을 고치고 컨테이너 둘을 바꿔 끼운다."
              echo "     🔵 **DB 는 안 바꾼다** — 그것은 --migrate 가 이미 했다."
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(양식 · 백업)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "새 이미지 tar 둘 · 지문"
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  EXP_PO=$(tar_config_id "$TAR_PO" 2>/dev/null) || EXP_PO=""
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS" "$SZ_AS" "$MD5_AS" "$WANT_CFG_AS" dss-as-2.8.tar
  see_tar "$TAG_PO" "$TAR_PO" "$EXP_PO" "$SZ_PO" "$MD5_PO" "$WANT_CFG_PO" dss-po-0.6.tar
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

  step "새 이미지 안에 이번 판이 들어 있는가 (글자 · 그리고 .sql 개수)"
  if have_img "$TAG_AS"; then
    inside_check "$TAG_AS" "A/S" "$OLD_AS" "$AS_NEW1" "$AS_NEW2" "$AS_KEEP1" "$AS_KEEP2"
    img_mig_check "$TAG_AS" "A/S" "$AS_MIG_WANT" || true
    ocr_check "$TAG_AS"
  fi
  if have_img "$TAG_PO"; then
    inside_check "$TAG_PO" "PO" "$OLD_PO" "$PO_NEW1" "$PO_NEW2" "$PO_KEEP1" "$PO_KEEP2"
  fi

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

# ══ --migrate — 🔴 **DB 가 바뀐다. 앱은 안 멈춘다.** ═══════════════════
if [ "$MODE" = migrate ]; then
  pinned || {
    say
    say "  ╔══════════════════════════════════════════════════════════════╗"
    say "  ║ 🔴 이미지 기대값 여섯이 **비어 있습니다.** 재지 않은 판으로      ║"
    say "  ║    운영 DB 를 바꾸지 않습니다.                                 ║"
    say "  ╚══════════════════════════════════════════════════════════════╝"
    stop "아무것도 바꾸지 않았습니다. 앱도 DB 도 그대로입니다."
  }
  pg_up || stop "dss-pg-app 이 떠 있지 않습니다. **아무것도 바꾸지 않았습니다.**"

  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 0117 은 **인가 경계를 넓히는** 마이그레이션입니다.           ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     출하 완료를 **담당 엔지니어(AS_ENGINEER)와 영업(SALES)도** 누를 수"
  say "     있게 됩니다. 내자 정리의 완료 처리뿐 아니라 **수리건 화면의"
  say "     [출하 완료] 단추도 함께 열립니다.** 의도한 결과입니다"
  say "     (2026-10-18 사용자 결정)."
  say "     🔴 **되돌리기가 어렵습니다** — 적용 뒤에는 「원래 있던 줄」과"
  say "        「이번에 생긴 줄」을 DB 만 보고 가를 수 없습니다. 그래서 아래"
  say "        3번이 **적용 전 분포를 로그에 적어 둡니다.**"
  say

  # ── 1. 🔴 오늘 백업을 지금 다시 찾는다 ──────────────────────────────
  #
  # 🔴 --check 에서 봤다는 것으로는 부족하다 — 그 뒤에 지워졌을 수 있고,
  #    무엇보다 --check 를 안 돌리고 바로 여기로 올 수 있다.
  #    🔴 스크립트가 **대신 뜨지 않는다.**
  step "1. 🔴 오늘 백업($AS_DB)을 **지금 다시** 찾는다 (없으면 여기서 멈춘다)"
  BK_TODAY=$(ls -1t "$BKD/db/${AS_DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
  if [ -n "$BK_TODAY" ] && [ -s "$BK_TODAY" ]; then
    ok "오늘 백업 — $(basename "$BK_TODAY") ($(du -h "$BK_TODAY" | cut -f1))"
  else
    say "  ╔══════════════════════════════════════════════════════════════╗"
    say "  ║ 🔴 오늘($TODAY) 뜬 $AS_DB 백업을 **지금 찾지 못했습니다.**      ║"
    say "  ╚══════════════════════════════════════════════════════════════╝"
    say "     🔵 야간 백업은 **02:30** 입니다 — 자정을 넘겨 돌리면 여기 걸립니다."
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    say "     ✓ $AS_DB 줄이 찍혀야 합니다. 그 뒤에 다시:"
    cmd "bash $0 --migrate"
    stop "백업 없이 DB 를 바꾸지 않습니다. **DB 도 앱도 그대로입니다.**"
  fi

  # ── 2. 적용 직전 덤프 ───────────────────────────────────────────────
  #
  # 🔴 되돌리기의 **기본 수단이 아니다.** 되돌리기는 이미지만 내리고 DB 를
  #    그대로 두는 것이다(--rollback). 이것은 「마이그레이션이 DB 를 깨뜨렸을
  #    때」의 마지막 수단이다.
  step "2. 적용 직전 덤프 ($AS_DB)"
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
    stop "DB 를 바꾸지 않았습니다. **앱도 그대로입니다.**"
  fi
  say "  ⚠️ PO 가 **같은 $AS_DB 를 보고 있다** — 덤프 중에 PO 에서 저장한 것은"
  say "     이 덤프에 안 들어갈 수 있다. 그래서 이것은 마지막 수단이고, 되돌리기의"
  say "     기본은 **이미지만 내리고 DB 는 그대로 두는 것**이다."

  # ── 3. 🔴 적용 전 상태를 지금 다시 센다 (로그에 남는다) ─────────────
  step "3. 🔴 적용 **전** 상태를 지금 다시 센다 — 🔴 이 출력이 되돌리기의 근거다"
  MIG_BEFORE=$(as_mig_count); MIG_BEFORE=${MIG_BEFORE:-0}
  WF_BEFORE=$(wf_rows); WF_BEFORE=${WF_BEFORE:-0}
  WF_BOTH_BEFORE=$(wf_rows_both); WF_BOTH_BEFORE=${WF_BOTH_BEFORE:-0}
  say "  · 마이그레이션 ${MIG_BEFORE}줄"
  say "  · $WF_ACTION 줄 ${WF_BEFORE}개 · 그중 두 역할을 다 가진 줄 ${WF_BOTH_BEFORE}개"
  [ "$MIG_BEFORE" = "$AS_MIG_HAVE" ] || [ "$MIG_BEFORE" = "$AS_MIG_WANT" ] \
    || stop "마이그레이션 줄이 $AS_MIG_HAVE 도 $AS_MIG_WANT 도 아닙니다 (${MIG_BEFORE}). **DB 는 그대로입니다.**"
  [ "${WF_BEFORE:-0}" -ge 1 ] 2>/dev/null \
    || stop "$WF_ACTION 줄이 하나도 없습니다. 기대한 DB 가 아닙니다. **DB 는 그대로입니다.**"
  say
  say "  🔴 **적용 전 분포** — 되돌릴 일이 생기면 이 표를 보고 사람이 SQL 을 짭니다:"
  wf_show "  "
  say "  🔴 **줄 단위로도 적어 둔다** (판 id · 상태 · 역할):"
  qqas "select t.id, t.allowed_roles, w.status from workflow_transitions t join workflow_versions w on w.id = t.workflow_version_id where t.action_code = '$WF_ACTION' order by w.status, t.id" \
    | sed 's/^/      /' | head -45
  say "  · 줄 수 (적용 뒤에 **그대로여야** 한다):"
  CNT_BEFORE=""
  for t in $AS_COUNT_TABLES; do
    v=$(qas "select count(*) from $t" 2>/dev/null)
    CNT_BEFORE="$CNT_BEFORE $t=${v:-?}"
    say "      $t ${v:-?}줄"
  done

  # ── 4. 마이그레이션 파일 놓기 ───────────────────────────────────────
  step "4. 마이그레이션 파일 놓기 ($MIGDIR → tools-as 의 $IMG_MIGDIR)"
  say "  🔴 .sql 만으로는 부족하다 — **meta/_journal.json 과 snapshot 까지** 가야"
  say "     한다. _journal.json 이 옛것이면 적용이 **0건으로 조용히 끝난다.**"
  read_migdir
  if [ "$MIG_STATE" = OLD ]; then
    if [ ! -s "$MIGTAR" ]; then
      say "  ╔══════════════════════════════════════════════════════════════╗"
      say "  ║ 🔴 볼륨이 아직 $AS_MIG_HAVE 인데 갈아 끼울 묶음이 없습니다.          ║"
      say "  ╚══════════════════════════════════════════════════════════════╝"
      say "     만들어 올리는 차례 (개발 PC · PowerShell):"
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
  [ "$MIG_N_SQL" = "$AS_MIG_WANT" ] && ok ".sql ${MIG_N_SQL}장" \
    || bad ".sql 이 ${AS_MIG_WANT}장이 아니다 (${MIG_N_SQL}장)"
  [ "$MIG_N_J" = "$AS_MIG_WANT" ] && ok "_journal.json 의 tag ${MIG_N_J}줄" \
    || bad "_journal.json 의 tag 가 ${AS_MIG_WANT}줄이 아니다 (${MIG_N_J}줄) — 🔴 적용이 0건으로 끝난다"
  check_new_migs || true
  [ "$FAIL" = 0 ] || stop "마이그레이션 파일이 온전하지 않습니다. **DB 도 앱도 그대로입니다.**"

  say
  say "  🔴 이제 DB 를 바꿉니다. 그만두려면 **20초 안에 Ctrl+C**."
  say "     지금 Ctrl+C 하면 DB 는 손대지 않은 채로 남습니다."
  say "     (마이그레이션 파일은 이미 바뀌었지만 그것만으로는 아무 일도"
  say "      일어나지 않습니다 — 읽는 것은 tools-as 뿐이고 그때만 돕니다.)"
  sleep 20

  # ── 5. 적용 전 preflight ────────────────────────────────────────────
  step "5. 🔴 적용 전 확인 — db:preflight (앱은 아직 $OLD_AS 로 살아 있다)"
  say "  🔴 0116 에도 0117 에도 **지우는 문장이 하나도 없다.** 그러니 「사라질"
  say "     자료가 있는 항목」이 나오면 그것이 신호다 — 멈춘다."
  compose_cmd run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | sed 's/^/    /'
  PRC=${PIPESTATUS[0]}
  say "  (종료 코드 $PRC — 기대 0 · 대기 **2건**이어야 한다)"
  if [ "$PRC" != 0 ]; then
    bad "db:preflight 가 0 이 아니다 ($PRC) — 사라질 자료가 있다는 뜻이다"
    say "    → 🔴 0116 · 0117 에는 그럴 문장이 없다. **다른 것이 섞였다.**"
    stop "마이그레이션을 시작하지 않았습니다. 직원은 $OLD_AS 를 쓰고 있습니다."
  fi

  # ── 6. 🔴 적용 ──────────────────────────────────────────────────────
  step "6. 🔴 마이그레이션 적용 (0116 · 0117)  — 여기서 DB 가 바뀐다"
  say "  🔵 도는 동안 직원은 **$OLD_AS 와 $OLD_PO 를 그대로 쓰고 있다.**"
  say "  🔴 다시 돌려도 안전하다 — drizzle 은 이미 적용된 것을 건너뛴다."
  compose_cmd run --rm "$AS_TOOLS_SVC" npm run db:migrate 2>&1 | sed 's/^/    /'
  rc=${PIPESTATUS[0]}
  if [ "$rc" = 0 ]; then
    ok "db:migrate 끝 (종료 코드 0)"
  else
    bad "db:migrate 실패 (종료 코드 $rc)"
    say "    ╔══════════════════════════════════════════════════════════════╗"
    say "    ║ 🔵 직원은 아직 $OLD_AS · $OLD_PO 를 쓰고 있습니다. 안 멈췄습니다. ║"
    say "    ╚══════════════════════════════════════════════════════════════╝"
    say "    🔴 **새 판을 띄우지 않습니다.** $TAG_AS 는 없는 칸을 읽습니다."
    cmd "bash $0 --migrate"
    stop "적용 직전 덤프: $BK/$AS_DB.dump"
  fi

  # ── 7. 🔴 SQL 로 직접 센다 ──────────────────────────────────────────
  step "7. 🔴 SQL 로 직접 센다 (「돌았다」가 아니라 「섰다」를 본다)"
  MIG_AFTER=$(as_mig_count); MIG_AFTER=${MIG_AFTER:-0}
  [ "$MIG_AFTER" = "$AS_MIG_WANT" ] \
    && ok "마이그레이션 ${MIG_AFTER}줄 (전 ${MIG_BEFORE}줄)" \
    || bad "🔴 마이그레이션이 ${AS_MIG_WANT}줄이 아니다 (${MIG_AFTER})"
  v=$(col_exists customers portal_form_id)
  [ "${v:-0}" = 1 ] && ok "0116 — customers 에 portal_form_id 칸이 생겼다" \
    || bad "🔴 customers.portal_form_id 칸이 **없다** (${v:-?})"
  v=$(qas "select count(*) from customers where portal_form_id is not null")
  say "  · 0116 — 양식이 적힌 고객사 줄: ${v:-?}건 (개발·운영에 따라 다르다)"
  qqas "select portal_form_id, count(*) from customers where portal_form_id is not null group by 1 order by 1" \
    | sed 's/^/      /'
  WF_AFTER=$(wf_rows); WF_AFTER=${WF_AFTER:-0}
  WF_BOTH_AFTER=$(wf_rows_both); WF_BOTH_AFTER=${WF_BOTH_AFTER:-0}
  [ "$WF_AFTER" = "$WF_BEFORE" ] \
    && ok "0117 — $WF_ACTION 줄 수가 ${WF_AFTER}로 **그대로다** (줄이 늘지도 줄지도 않았다)" \
    || bad "🔴 $WF_ACTION 줄 수가 ${WF_BEFORE} → ${WF_AFTER} 로 달라졌다"
  if [ "$WF_BOTH_AFTER" = "$WF_AFTER" ]; then
    ok "🔴 0117 — **${WF_AFTER}줄 전부**가 AS_ENGINEER 와 SALES 를 가졌다 (전 ${WF_BOTH_BEFORE}줄)"
  else
    bad "🔴 0117 — ${WF_AFTER}줄 중 ${WF_BOTH_AFTER}줄만 두 역할을 가졌다"
    say "    → 적용이 덜 됐다. 다시 돌려도 안전합니다:  bash $0 --migrate"
  fi
  say "  적용 **뒤** 분포:"
  wf_show "  "
  say "  🔴 **줄 수가 그대로인가** (하나라도 줄었으면 자료가 사라진 것이다):"
  for t in $AS_COUNT_TABLES; do
    v=$(qas "select count(*) from $t" 2>/dev/null)
    b=$(printf '%s' "$CNT_BEFORE" | tr ' ' '\n' | sed -n "s/^$t=//p")
    [ "${v:-x}" = "${b:-y}" ] && ok "$t ${v}줄 — 그대로다" \
      || bad "🔴 $t 가 ${b:-?} → ${v:-?} 로 **달라졌다**"
  done
  say "  🔴 적용 뒤 preflight — **대기 0건**이어야 한다:"
  compose_cmd run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | sed 's/^/    /'
  say "  (종료 코드 ${PIPESTATUS[0]})"

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL"
  echo "  🔴 DB 를 바꿨습니다. 두 사이트는 **아직 옛 판으로 돌고 있습니다.**"
  echo "     마이그레이션 ${MIG_BEFORE}줄 → ${MIG_AFTER}줄"
  echo "     출하 완료 두 역할 ${WF_BOTH_BEFORE}줄 → ${WF_BOTH_AFTER}줄 (전체 ${WF_AFTER}줄)"
  echo "  덤프: $BK/$AS_DB.dump"
  echo "  🔴 적용 **전** 분포는 이 로그 3번에 있습니다 — 되돌릴 때 그것을 보세요."
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
  exit 0
fi

# ══ 1. 먼저 볼 것 ══════════════════════════════════════════════════════
#
# 🔴 규칙 하나: **앱을 멈추기 전에 볼 것을 다 보고, 어긋나면 앱이 살아 있는
#    채로 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
step "1. 점검표를 기계로 옮긴 것 (앱은 살아 있다 · DB 는 손도 안 댄다)"
run_checks

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  if [ "$FAIL" = 0 ]; then
    if pinned; then
      if [ "${MIG_DB_NOW:-}" = "$AS_MIG_WANT" ]; then
        echo "  ✅ 마이그레이션은 이미 끝났습니다 ($AS_MIG_WANT). 이어서:"
        echo "       bash $0 --go"
      else
        echo "  ✅ 이어서 — 🔴 **--migrate 가 먼저입니다** (DB 가 바뀝니다):"
        echo "       bash $0 --migrate"
        echo "     그 다음에:  bash $0 --go"
      fi
      echo "     🔴 --migrate 도 --go 도 오늘 백업($AS_DB)이 없으면 멈춥니다."
      echo "     🔵 야간 백업은 02:30 입니다 — 먼저 손으로 뜨려면:"
      echo "          bash /volume1/dss/jobs/backup-nightly.sh"
    else
      echo "  🔴 아직 --migrate 도 --go 도 부를 수 없습니다 — 기대값 여섯이 비었습니다."
    fi
    echo "     🔵 ⚠️ 가 있었다면 아직 안 온 파일이 있다는 뜻입니다 — 올리고"
    echo "        --preload 한 뒤 이 명령을 한 번 더 돌리세요."
  else
    echo "  ✗ 위 ✗ 를 먼저 해결하세요. Claude 에게 알려 주세요."
    echo "    🔵 「아직 안 온 것 · 안 실린 것 · 이미 해 둔 것」은 ✗ 가 아닙니다."
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

# ── 2. 🔴 --migrate 가 끝났는지 **여기서 막는다** ─────────────────────
#
# 🔴 왜 막는가: 마이그레이션이 덜 된 DB 에 2.8 이 뜨면 없는 칸(portal_form_id)을
#    읽다 그 자리에서 죽는다. --migrate 는 따로 부르는 명령이라 **빠뜨릴 수 있다.**
#    명령은 나눠 두고 순서만 기계가 지킨다(27 · 28번의 그 규율).
step "2. 🔴 --migrate 가 끝났는지 다시 센다 (바꿔 끼우기 전에)"
MIG_NOW=$(as_mig_count); MIG_NOW=${MIG_NOW:-0}
WF_NOW=$(wf_rows); WF_NOW=${WF_NOW:-0}
WF_BOTH_NOW=$(wf_rows_both); WF_BOTH_NOW=${WF_BOTH_NOW:-0}
COL_NOW=$(col_exists customers portal_form_id); COL_NOW=${COL_NOW:-0}
say "  · 마이그레이션 ${MIG_NOW}줄 · portal_form_id 칸 ${COL_NOW} · 출하 완료 ${WF_BOTH_NOW}/${WF_NOW}"
if [ "$MIG_NOW" != "$AS_MIG_WANT" ] || [ "$COL_NOW" != 1 ] || [ "$WF_BOTH_NOW" != "$WF_NOW" ]; then
  say "  ✗ 마이그레이션이 아직 끝나지 않았습니다 (기대 ${AS_MIG_WANT}줄 · 칸 1 · 두 역할 전부)"
  say "    🔴 $TAG_AS 는 **없는 칸을 읽습니다.** 띄우지 않습니다."
  cmd "bash $0 --migrate"
  stop "**아무것도 바꾸지 않았고 앱은 살아 있습니다.**"
fi
ok "마이그레이션이 끝나 있다 (${MIG_NOW}줄 · portal_form_id 있음 · 출하 완료 ${WF_BOTH_NOW}/${WF_NOW})"

# ── 3. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ───────────
step "3. 새 이미지 둘 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
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

# ══ 4. 🔴 멈추기 전에 — 백업 · 스냅숏 · 양식 · compose · 설정 ══════════
#
# 🔴 여기까지가 「돌이킬 수 있는 자리」다. 앱은 아직 옛 판으로 **살아 있다.**

# ── 4-ㄱ. 🔴 오늘 백업을 지금 다시 찾는다 ──────────────────────────────
step "4-ㄱ. 🔴 오늘 백업($AS_DB)을 **지금 다시** 찾는다 (없으면 멈춘다)"
BK_TODAY=$(ls -1t "$BKD/db/${AS_DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
if [ -n "$BK_TODAY" ] && [ -s "$BK_TODAY" ]; then
  ok "오늘 백업 — $(basename "$BK_TODAY") ($(du -h "$BK_TODAY" | cut -f1))"
else
  say "  🔴 오늘($TODAY) 뜬 $AS_DB 백업을 **지금 찾지 못했습니다.**"
  say "     🔵 --go 는 DB 를 안 바꿉니다. 그래도 **백업 없이 운영 이미지를"
  say "        갈아 끼우지 않습니다** — 17번에서 이 문이 사고를 막았습니다."
  cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  stop "백업 없이 교체하지 않습니다. **앱도 DB 도 그대로입니다.**"
fi

# ── 4-ㄴ. 첨부 하드링크 스냅숏 · .env 사본 둘 ──────────────────────────
step "4-ㄴ. 첨부 하드링크 스냅숏 · .env 사본 둘 (DB 덤프는 --migrate 가 떴다)"
BK=$BKD/predeploy-go-$STAMP
mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
if [ -d "$ATT" ]; then
  cp -al "$ATT" "$BK/as-attachments" 2>/dev/null \
    && ok "첨부 스냅숏 (cp -al 하드링크 — 즉시 · 공간 0) → $BK" \
    || bad "첨부 스냅숏 실패"
else
  bad "첨부 폴더가 없다: $ATT"
fi
for f in "$AS_ENV|as.env" "$PO_ENV|po.env"; do
  p=${f%%|*}; nm=${f#*|}
  if [ -f "$p" ]; then
    cp -p "$p" "$BKD/$nm.$STAMP"; chmod 600 "$BKD/$nm.$STAMP"
    ok "$nm 사본 — backups/$nm.$STAMP (root 600)"
  else
    bad "$nm 이 없다: $p"
    stop "설정 파일이 없습니다. **앱도 DB 도 그대로입니다.**"
  fi
done
say "  🔵 공유폴더들은 스냅숏을 뜨지 않는다 — 직원의 서류함이라 우리가 사본을"
say "     만들 자리가 아니다. NAS 의 야간 백업이 본다."

# ── 4-ㄷ. 🔴 양식 네 장 놓기 ───────────────────────────────────────────
step "4-ㄷ. 🔴 양식 네 장 놓기 (${TPL_COUNT_HAVE}장 → ${TPL_COUNT_WANT}장)"
say "  🔴 기존 두 장(「$TPL_KEEP」)은 **한 글자도 안 건드린다.**"
TPL_PLACED=0
place_one() { # 1 상태 2 이름 3 md5 4 짝
  case "$1" in
    DONE)  ok "「$2」 는 이미 놓여 있다 — 할 일이 없다"; return 0 ;;
    READY) place_tpl "$2" "$3" "$4" && TPL_PLACED=$((TPL_PLACED + 1)) && return 0
           return 1 ;;
    *)     bad "🔴 「$2」 가 준비되지 않았다 (상태 ${1:-없음})"; return 1 ;;
  esac
}
place_one "$TPL1_STATE" "$TPL1_NAME" "$TPL1_MD5" "$TPL1_BASE" \
  || stop "양식을 놓지 못했습니다. **앱도 DB 도 그대로입니다.**"
place_one "$TPL2_STATE" "$TPL2_NAME" "$TPL2_MD5" "$TPL2_BASE" \
  || stop "양식을 놓지 못했습니다. **앱도 DB 도 그대로입니다.**"
place_one "$TPL3_STATE" "$TPL3_NAME" "$TPL3_MD5" "$TPL3_BASE" \
  || stop "양식을 놓지 못했습니다. **앱도 DB 도 그대로입니다.**"
place_one "$TPL4_STATE" "$TPL4_NAME" "$TPL4_MD5" "$TPL4_BASE" \
  || stop "양식을 놓지 못했습니다. **앱도 DB 도 그대로입니다.**"
say "  🔵 이번에 놓은 양식 ${TPL_PLACED}장."
n=$(ls -1 "$TEMPLATES" 2>/dev/null | wc -l | tr -d ' ')
[ "${n:-0}" = "$TPL_COUNT_WANT" ] && ok "호스트 폴더가 **${n}장**이다" \
  || bad "🔴 호스트 폴더가 ${n:-0}장이다 (${TPL_COUNT_WANT}장이어야 한다)"
say "  🔴 호스트에서 보는 것으로는 부족하다 — **지금 도는 컨테이너 안**에서 본다"
say "     (볼륨이 :ro 로 제대로 붙어 있는지가 핵심이다. 아직 옛 판이지만 볼륨은"
say "      같은 호스트 폴더라 곧바로 보여야 한다):"
tpl_in_box "$AS_CNAME" "A/S(옛 판)" "$TPL_COUNT_WANT"
tpl_in_box "$PO_CNAME" "PO(옛 판)"  "$TPL_COUNT_WANT"
[ "$FAIL" = 0 ] || stop "양식이 컨테이너 안에서 안 보입니다. **compose 도 설정도 아직 안 고쳤습니다.**"

# ── 4-ㄹ. 🔴 compose 고치기 ────────────────────────────────────────────
step "4-ㄹ. 🔴 compose 고치기 — 태그 둘 + 일곱 줄 (아무것도 안 뜨고 안 멈춘다)"
if compose_done; then
  ok "compose 가 **이미 다 고쳐져 있다** — 할 일이 없다"
else
  edit_compose || stop "compose 를 바꾸지 못했습니다(되돌려 두었습니다). **앱도 DB 도 그대로입니다.**"
fi

# ── 4-ㅁ. 🔴 설정 넷 적기 ──────────────────────────────────────────────
step "4-ㅁ. 🔴 설정 넷 적기 — as.env 한 줄 · po.env 세 줄 (🔴 값은 안 찍는다)"
say "  🔴 이 PC 의 .env 를 올리는 것이 아니다. **NAS 의 파일을 읽고 없는 줄만**"
say "     덧붙인다. 이미 있으면 값이 같은지 보고, 다르면 멈춘다(덮어쓰지 않는다)."
build_env_values 1 \
  || stop "as.env 에서 PO 로 옮길 값을 못 읽었습니다. **설정을 한 글자도 안 바꿨습니다.**"
say "  · AS_WRITE_TOKEN 의 출처: $WRITE_TOKEN_SRC"
[ "${#V_WRITE}" = "$TOKEN_LEN" ] \
  && ok "AS_WRITE_TOKEN 을 마련했습니다 (${TOKEN_LEN}자 · 🔴 값은 안 찍습니다)" \
  || { bad "🔴 AS_WRITE_TOKEN 이 ${#V_WRITE}자다 (${TOKEN_LEN}자여야 한다)"
       stop "설정을 한 글자도 안 바꿨습니다."; }
# 🔴 as.env 의 다른 줄들이 적기 **전에** 그대로인가
for k in $AS_QUOTE_KEYS $AS_PORTAL_KEYS $AS_SRC_KEYS; do
  grep -q "^$k=" "$AS_ENV" || {
    bad "$k 가 as.env 에 없다 — 🔴 누가 덮어썼다"
    stop "as.env 가 온전하지 않습니다. 덧붙이지 않았습니다. **앱도 DB 도 그대로입니다.**"
  }
done
ok "as.env 의 있던 줄들이 그대로 있다 — 덧붙여도 안전하다"
append_env_keys "$AS_ENV" "as.env" "$AS_NEW_KEYS" "A/S 쓰기 통로의 토큰" \
  || stop "as.env 가 기대한 모습이 아닙니다. **앱도 DB 도 그대로입니다.**"
append_env_keys "$PO_ENV" "po.env" "$PO_NEW_KEYS" "A/S 쓰기 토큰 · 재고 관리 읽기 통로" \
  || stop "po.env 가 기대한 모습이 아닙니다. **앱도 DB 도 그대로입니다.**"
# 🔴 셋이 as.env 와 **글자까지 같은가** — 파일로 본다. 값은 안 찍는다.
for k in $PO_NEW_KEYS; do
  if [ "$(env_val_of "$AS_ENV" "$k")" = "$(env_val_of "$PO_ENV" "$k")" ]; then
    ok "$k 가 as.env 와 po.env 에서 **글자까지 같다**"
  else
    bad "🔴 $k 가 as.env 와 po.env 에서 **다르다** — PO 가 401 을 받는다"
  fi
done
for k in $PO_FORBIDDEN; do
  [ "$(env_count_of "$PO_ENV" "$k")" = 0 ] \
    && ok "po.env 에 $k 를 **안 넣었다** (맞다 — PO 는 읽기만 한다)" \
    || bad "🔴 po.env 에 $k 가 있다 — PO 가 알 필요가 없는 값이다"
done
[ "$FAIL" = 0 ] || stop "설정을 적다 어긋났습니다. 사본은 backups/ 에 있습니다. **앱은 그대로 돕니다.**"

# ── 4-ㅂ. 건드리지 않는 쪽의 시작 시각을 적어 둔다 ─────────────────────
step "4-ㅂ. 건드리지 않는 쪽의 시작 시각을 적어 둔다 (뒤에서 대조한다)"
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
say "     (양식 · compose · 설정은 이미 바뀌었지만 그것만으로는 아무 일도"
say "      일어나지 않습니다 — 옛 컨테이너가 그대로 돌고 있습니다.)"
sleep 20

# ══ 5. 🔴 **A/S 먼저** — 여기부터 정지 창 ══════════════════════════════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다. --no-deps 로 **이름을 적은 하나만** 부른다.
# 🔴 22번은 둘을 **한 번에** 불렀다. 이번 판은 일부러 갈랐다 — PO 가 A/S 의
#    새 통로를 부르기 때문이다. 정지 창이 그만큼 길어지는 것은 받아들인다.
step "5. 🔴 A/S 를 먼저 바꿔 끼운다 ($AS_SVC)  ⏱ 여기부터 정지 창"
say "  🔵 이 동안 PO 는 **아직 $OLD_PO 로 돌고 있다** — 그쪽은 새 통로를"
say "     부르지 않으므로 A/S 가 잠깐 없어도 평소와 같다."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"
compose_cmd up -d --no-deps "$AS_SVC" 2>&1 | sed 's/^/    /'
wait_http "A/S" "$AS_PORT" / "$AS_CNAME"
AS_UP_AT=$(date '+%F %T')
say "  ⏱ A/S 가 대답한 시각: $AS_UP_AT"

say "  🔴 PO 를 올리기 **전에** 쓰기 통로가 실제로 열렸는지 본다:"
write_gate_probe "A/S" 401
if [ "$FAIL" != 0 ]; then
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 A/S 의 쓰기 통로가 기대한 모습이 아닙니다.                   ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     🔴 **PO 를 올리지 않습니다.** 지금 PO 는 $OLD_PO 라 그 통로를"
  say "        부르지 않습니다 — 직원이 느끼는 것이 없습니다."
  say "     되돌리기 안내:  bash $0 --rollback"
  stop "PO 는 그대로 $OLD_PO 로 돌고 있습니다."
fi
say "  🔴 A/S 안에 설정이 들어갔는가 (🔴 값은 안 찍는다):"
v=$("$DOCKER" exec "$AS_CNAME" printenv AS_WRITE_TOKEN 2>/dev/null)
[ "${#v}" = "$TOKEN_LEN" ] && ok "A/S · AS_WRITE_TOKEN 이 ${#v}자로 들어 있다" \
  || bad "🔴 A/S · AS_WRITE_TOKEN 이 ${#v}자다 (${TOKEN_LEN}자여야 한다)"
for k in $CF_NEW_KEYS; do
  v=$("$DOCKER" exec "$AS_CNAME" printenv "$k" 2>/dev/null)
  if [ -n "$v" ]; then
    ok "A/S · $k = $v"
    "$DOCKER" exec "$AS_CNAME" sh -c "[ -f \"\$$k\" ]" >/dev/null 2>&1 \
      && ok "   그 파일이 컨테이너 안에 **실제로 있다**" \
      || bad "🔴 그 경로에 파일이 **없다** — 보고서가 그 종류에서 죽는다"
  else
    bad "🔴 A/S · $k 가 컨테이너 안에 **없다** — compose 네 줄이 안 먹었다"
  fi
done
for k in $CF_KEEP_KEYS; do
  v=$("$DOCKER" exec "$AS_CNAME" printenv "$k" 2>/dev/null)
  [ -n "$v" ] && ok "A/S · 물러설 자리 $k = $v" \
    || bad "🔴 A/S · $k 가 **사라졌다** — 종류를 모를 때 읽을 양식이 없다"
done
tpl_in_box "$AS_CNAME" "A/S(새 판)" "$TPL_COUNT_WANT"

# ══ 6. 🔴 그 다음에 PO ═════════════════════════════════════════════════
step "6. 🔴 이어서 PO 를 바꿔 끼운다 ($PO_SVC)"
say "  🔵 A/S 가 먼저 대답했으므로 PO 의 [완료 처리]가 404 를 만날 일이 없다."
compose_cmd up -d --no-deps "$PO_SVC" 2>&1 | sed 's/^/    /'
wait_http "PO" "$PO_PORT" / "$PO_CNAME"
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → A/S $AS_UP_AT → PO 다 대답한 시각 $UP_AT"
say "     · 전체 약 ${DOWN}초 (A/S 와 PO 를 **나눠** 올렸다)"

# ══ 7. 스모크 ══════════════════════════════════════════════════════════
step "7. 스모크 — 양식 · 🔴 **통로를 값으로** · 설정 · 폴더 · 안 멈췄는가 · 주소"

say "  7-ㄱ. 양식 — PO 쪽 컨테이너 안에서도 본다"
tpl_in_box "$PO_CNAME" "PO(새 판)" "$TPL_COUNT_WANT"

say "  7-ㄴ. 🔴 **이 배포의 알맹이** — PO 가 재고 관리와 A/S 를 실제로 부르는가"
say "     (🔴 토큰도 본문도 한 글자도 안 찍는다. HTTP 번호만 본다.)"
po_probe

say "  7-ㄷ. 🔴 두 컨테이너의 AS_WRITE_TOKEN 이 **글자까지 같은가**"
if running "$AS_CNAME" && running "$PO_CNAME"; then
  if [ "$("$DOCKER" exec "$AS_CNAME" printenv AS_WRITE_TOKEN 2>/dev/null)" \
     = "$("$DOCKER" exec "$PO_CNAME" printenv AS_WRITE_TOKEN 2>/dev/null)" ]; then
    ok "🔴 AS_WRITE_TOKEN 이 A/S 와 PO 에서 **같다** (🔴 값은 안 찍는다)"
  else
    bad "🔴 AS_WRITE_TOKEN 이 A/S 와 PO 에서 **다르다** — PO 가 401 을 받는다"
  fi
  for k in INVENTORY_API_BASE_URL INVENTORY_API_TOKEN; do
    if [ "$("$DOCKER" exec "$AS_CNAME" printenv "$k" 2>/dev/null)" \
       = "$("$DOCKER" exec "$PO_CNAME" printenv "$k" 2>/dev/null)" ]; then
      ok "$k 가 A/S 와 PO 에서 **같다**"
    else
      bad "🔴 $k 가 A/S 와 PO 에서 **다르다**"
    fi
  done
  # 🔴 PO 가 알면 안 되는 값
  v=$("$DOCKER" exec "$PO_CNAME" printenv INVENTORY_WRITE_TOKEN 2>/dev/null)
  [ -z "$v" ] && ok "PO 안에 INVENTORY_WRITE_TOKEN 이 **없다** (맞다 — 읽기만 한다)" \
    || bad "🔴 PO 안에 INVENTORY_WRITE_TOKEN 이 있다 — 알 필요가 없는 값이다"
else
  bad "컨테이너 둘 중 하나가 안 떠 있다 — 설정을 못 봤다"
fi

say "  7-ㄹ. 폴더 — 공유폴더 다섯이 **그대로 붙어 있는가** (이번엔 더한 것이 없다)"
if running "$AS_CNAME"; then
  for t in /data /templates /quote-archive /customer-portal-archive \
           /contact-folder-archive /repair-docs-archive /purchase-order-archive; do
    "$DOCKER" exec "$AS_CNAME" sh -c "ls -1 '$t' >/dev/null 2>&1" \
      && ok "A/S 가 $t 를 읽는다" \
      || { bad "🔴 A/S 가 $t 를 **못 읽는다**"
           say "      🔴 여기는 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기가 끊긴다."
           say "         compose 의 group_add 가 있는지부터 보세요."; }
  done
  # 🔴 쓰기 시험은 PROBE_WRITE=1 (즉 --go) 일 때만 한다. --check 가 「아무것도
  #    안 바꾼다」고 말해 놓고 파일을 만들면 그 약속이 거짓이 된다.
  # 🔴 **빈 파일은 touch 로 만든다** — 리다이렉션은 읽기 전용 자리에서 ash 를
  #    그 자리에서 끝낸다(2026-10-12 실제 사고).
  if [ "$PROBE_WRITE" = 1 ]; then
    if "$DOCKER" exec "$AS_CNAME" sh -c 't=/data/.dss-write-test; touch "$t" && rm -f "$t"' >/dev/null 2>&1; then
      ok "A/S 가 /data 에 쓸 수 있다 (시험 파일은 곧바로 지웠다)"
    else
      bad "🔴 A/S 가 /data 에 **못 쓴다** — 첨부 올리기가 죽는다"
    fi
    # 🔴 양식은 읽기 전용이어야 맞다
    if "$DOCKER" exec "$AS_CNAME" sh -c 't=/templates/.dss-ro-test; touch "$t"' >/dev/null 2>&1; then
      bad "🔴 /templates 에 **쓸 수 있다** — :ro 가 안 먹었다"
      "$DOCKER" exec "$AS_CNAME" sh -c 'rm -f /templates/.dss-ro-test' >/dev/null 2>&1
      say "    🔵 시험 파일은 곧바로 지웠다 — 남아 있으면 알려 주세요."
    else
      ok "🔴 /templates 는 **쓰기가 막혀 있다** (읽기 전용 그대로다)"
    fi
  fi
else
  bad "$AS_CNAME 가 떠 있지 않다"
fi
if running "$PO_CNAME"; then
  "$DOCKER" exec "$PO_CNAME" sh -c 'ls -1 /quote-archive >/dev/null 2>&1' \
    && ok "PO 가 견적서 공유폴더를 읽는다" \
    || bad "🔴 PO 가 견적서 공유폴더를 **못 읽는다** — 발행이 실패한다"
fi

say "  7-ㅁ. 🔴 DB 가 --migrate 뒤로 **흔들리지 않았는가** (select 만)"
v=$(as_mig_count)
[ "${v:-0}" = "$AS_MIG_WANT" ] && ok "마이그레이션 ${v}줄 그대로" \
  || bad "🔴 마이그레이션이 ${v:-?}줄이다 (${AS_MIG_WANT}줄이어야 한다)"
v=$(wf_rows); n=$(wf_rows_both)
[ "${v:-0}" = "${n:-1}" ] && ok "출하 완료 ${v}줄 전부가 두 역할을 가졌다" \
  || bad "🔴 출하 완료 ${v:-?}줄 중 ${n:-?}줄만 두 역할을 가졌다"

say "  7-ㅂ. 🔴 건드리지 않는 쪽이 **정말 안 멈췄는가** (시작 시각을 대조한다)"
for t in $KEEP_BOXES; do
  before=$(printf '%s\n' "$STARTED_BEFORE" | sed -n "s/^$t=//p" | head -1)
  after=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  if [ -n "$before" ] && [ "$before" = "$after" ]; then
    ok "$t · 시작 시각 그대로 — **한 번도 안 멈췄다**"
  else
    bad "🔴 $t 의 시작 시각이 바뀌었다 ($before → $after) — 이 배포가 건드렸다"
  fi
done

say "  7-ㅅ. 바깥 주소 여덟"
for h in $MOVE_HOSTS; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code (바뀐 쪽)" ;;
    *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
  esac
done
say "  🔴 안 바뀌는 쪽 — 흔들렸으면 **이 배포가 건드린 것**이다:"
for h in $KEEP_HOSTS; do
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
rm -rf "$TMPD"
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  멈춘 시각 $STOP_AT → A/S $AS_UP_AT → PO $UP_AT · 전체 약 ${DOWN}초"
echo "  바꾼 것 — 이미지 둘 · 양식 ${TPL_PLACED}장 · compose 7줄 · 설정 넷"
echo "  🔵 DB 는 --go 가 안 바꿨습니다 (그것은 --migrate 가 이미 했습니다)"
echo "  첨부 스냅숏: $BK"
echo "  compose 사본: ${CF_BK:-backups/ 에 있습니다}"
echo "  .env 사본: $BKD/as.env.$STAMP · $BKD/po.env.$STAMP"
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

   1. 🔴 **PO → 내자 정리 → [완료 처리]** 가 됩니까.
      · 누른 뒤 그 수리건이 **출하 완료**로 바뀌었는지도 보세요.
      · [완료 해제] 도 눌러 보세요 — 확인 창이 먼저 떠야 합니다.
      🔵 스크립트가 7-ㄴ 에서 그 통로까지 닿는 것을 이미 확인했습니다.
         여기서는 **실제로 업무가 되는지**만 보시면 됩니다.

   2. 🔴 **보고서 양식이 제품 종류로 갈리는가** — 매쳐 건과 제너레이터 건에서
      각각 검사보고서·수리보고서를 뽑아 **담당자 도장이 다른지** 보세요.
      (T/C 는 제너레이터 것을 씁니다 — 그것이 맞습니다.)

   3. 🔴 **출하 완료 단추** — 담당 엔지니어와 영업 계정으로 들어가 수리건
      상세에서 [출하 완료] 가 **보이는지** 보세요. 이번 판이 연 권한입니다.

   4. 🔵 **PO 견적서의 부품 고르개**에 새 부품이 뜹니까 (재고 관리에서 받습니다).

   5. 🔵 **고객 안내 현황**(A/S) 의 표 셋이 그대로 보입니까.
      고객사 화면에서 **안내 양식**을 고를 수 있는지도 보세요.

   6. 🔵 포털 · 계측기 · 개선요청 · 휴가 · 게시판 · 재고 관리가 그대로입니까.
      (스크립트가 7-ㅂ 에서 시작 시각으로 이미 확인했습니다.)

🔴 사람이 이어서 할 일:
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.
  · 내일 아침 백업을 한 번 더 보세요 — 다섯이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -7
  · 첨부 스냅숏은 $BK 에 있습니다. 한 주쯤 두었다 지우세요.
  · 🔵 as-migrations.old 는 **그대로 두세요** — 되돌릴 길입니다.

되돌리기 안내:  bash $0 --rollback
  🔴 되돌리면 PO 의 완료 처리가 다시 404 가 되고, 보고서가 다시 한 벌
     양식으로 나갑니다. 🔴 **DB 는 되돌리지 않습니다** — 까닭은 --rollback 이
     찍어 줍니다.
ANNOUNCE
exit "$FAIL"
