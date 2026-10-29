#!/bin/bash
# dss-deploy/nas/setup/45-deploy.sh — 마흔두째 배포 (2026-10-29)
#
# 🔴 NAS 에서 돈다. DSM 터미널은 긴 명령을 잘라 먹으므로 **파일로 올려** 돌린다.
#    md5 를 맞춘다:  md5sum /volume1/dss/setup/45-deploy.sh
#
# ── 사람이 실행한다 ───────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/45-deploy.sh            ← 읽기만 한다
#   (NAS)         bash /volume1/dss/setup/45-deploy.sh --preload
#   (NAS)         bash /volume1/dss/setup/45-deploy.sh --go       ⏱ 정지 창
#
# ── 갈아 끼우는 것 — **저장소 하나, 태그 둘** ──────────────────────────
#     ① A/S 앱   dss-as:3.7        → **dss-as:3.8**        커밋 5
#     ② A/S 도구 dss-as-tools:5    → **dss-as-tools:6**    커밋 5
#
#   🔴 **마이그레이션이 없다.** A/S 의 drizzle/ 이 기준 SHA(3206ca2) 이후 0건이다.
#      그래서 이 파일에는 **--migrate 모드가 없다** — DB 를 건드리는 단계가 한
#      군데도 없다.
#   🔵 **나머지 아홉은 안 건드린다** — 통합 로그인 · PO · 재고 · 게시판 · 계측기 ·
#      개선요청 · RF 이슈관리 · 휴가 · 통합 승인함 아홉은 이번 범위에 커밋이
#      한 줄도 없다.
#
# ── 이 배포가 하는 일 — **커밋 다섯. 화면 둘이 바뀐다** ────────────────
#   4e918c7 고장 부품 조각을 누르면 그 부품의 재고를 펼친다
#   32df613 A/S 이력을 년/월로 거른다
#   8917871 사용 부품 문지기가 재고관리에서 실제로 나간 것을 본다
#   b0d67bc 고장 부품 그래프가 반출 확인된 부품도 센다
#   37de223 고장 부품 그래프가 사용 부품도 센다
#
#   ㄱ) **제품 모델 상세 → [A/S 이력]** 이 네 가지로 달라진다 —
#       기간 드롭다운 둘(년·월) · [고장 부품] 그래프가 **사용 부품과 반출 부품까지**
#       셈 · 그래프 조각을 누르면 **그 부품의 재고가 소유구분별로** 펼쳐짐.
#   ㄴ) 🔴 **수리 건 상세 → [사용부품] 의 문지기가 바뀐다.** 지금까지는 A/S 의 옛
#       표만 보고 있었는데 그 표는 2026-10-16 부터 한 줄도 안 는다. 그래서
#       **재고 관리로 반출이 끝난 건에도 칸이 열려 있었고**, 같은 부품을 손으로 또
#       적으면 그래프가 두 번 셌다. 이제 재고 관리에 묻는다.
#       🔵 잣대는 「신청 흔적이 있나」가 아니라 **「실제로 나간 줄(issued >= 1)이
#          있나」**다 — 반려·취소만 되고 한 개도 안 나간 건은 **그대로 적을 수 있다.**
#   🔴 **저장된 글자는 한 자도 안 바뀐다.** DB 를 건드리는 단계가 없다(위).
#
# ── 🔴 A/S 도구를 왜 올리는가 — 🔴 **이번엔 도구가 실제로 부른다** ─────
#   🔵 **서른여섯째**: 「마이그레이션 0건이니 도구는 안 굽는다」 → **틀렸다**
#      (비상구 둘이 못 쓰는 채였다).
#   🔵 **서른일곱째**: 「그 도구가 실제로 부르는 명령이 바뀌었는가」로 판정해
#      안 구웠다 → **맞았다**(db:migrate·db:preflight 둘 다 볼륨만 읽는다).
#   🔵 **서른여덟째**: 그 잣대로는 「**늘어난** 명령」이 안 걸렸다. 안 올렸으면
#      'npm error Missing script' 가 날 자리였다.
#   🔵 **서른아홉째**: package.json 이 0줄인데 'scripts/' 에 백필 도구가 새로
#      생겼다. 그래서 잣대를 「tools 스테이지가 담는 것 전부」로 넓혀 적었다.
#   🔵 **마흔째**: 도구가 **부르는 코드**(src/lib/kyosan/ 둘)가 바뀌어 올렸다.
#   🔵 **마흔한째**: 도구가 **안 부르는** used-part-display.ts 가 바뀌었는데도
#      「잣대를 판마다 손으로 뒤집지 않는다」로 올렸다.
#
#   🔴 **마흔두째(이번)는 까닭이 분명하다 — 부르니까 올린다.** 실측부터 적는다:
#     · scripts/backfill-kyosan-used-parts.ts 에서 import 를 끝까지 펼치면 파일
#       **99개**가 나온다(2026-10-29 실측).
#     · 그 99개와 이번에 달라진 38개를 맞대면 **넷이 겹친다**:
#         src/lib/auth/repair-case-used-parts-authorization.ts   (+145줄)
#         src/lib/db/queries/repair-case-used-parts.ts           (+66줄)
#         src/lib/domain/inventory-gateway.ts                    (+66줄 · 형)
#         src/lib/server/inventory-gateway.ts                    (+20줄)
#     · 백필은 85줄에서 resolveUsedPartsWriteGate 를, 90줄에서
#       probeInventoryPartRequestTrace 를 **이름으로 끌어 쓴다.**
#   🔴 **used-part-display.ts 는 이번에도 도구가 안 부른다.** 그 파일을 거쳐
#      닿는다는 앞선 메모는 **틀렸다** — toFaultPartRows 는
#      src/lib/domain/product-model-fault-parts.ts 에 있고 그것을 부르는 것은
#      제품 모델 상세 화면 하나다. 🔵 그래도 그 파일은 아래 3절 검사에 **그대로
#      남긴다**(도구와 앱의 src/ 가 같은 판이어야 한다 — 44번 머리말 ㉡).
#   🔵 **잣대** — 39번에 넓혀 둔 그것을 글자 그대로 쓴다:
#        git diff 3206ca2..HEAD -- scripts/ src/ package.json drizzle.config.ts tsconfig.json vendor/
#      (45-build.sh 5절이 그 셈을 하고, 이 파일 3절이 결과물의 **안**을 다시 센다.)
#
# ── 🔵 백필 — **이번 판에서도 다시 돌리지 않는다** ────────────────────
#   🔴 44-deploy.sh 와 같다. 까닭:
#     · 백필은 **2026-10-29 새벽에 283건이 끝났다**
#       (회차 e8c3c890-b1ba-42ec-a555-737609ad2e38). 사용 부품 **978줄**이 품번으로
#       들어가 있다.
#     · 이번 판이 바꾸는 것은 **화면 둘과 문지기 하나**다. **DB 에 들어간 값과
#       무관하다** — 돌려도 바뀔 줄이 없고, 괜히 운영 자료를 건드릴 일만 만든다.
#   🔵 백필이 다시 필요해지는 때는 **연락서를 읽는 규칙**(src/lib/kyosan/ 쪽)이
#      바뀌는 판이다. 그때 칠 명령은 43-deploy.sh 꼬리말에 그대로 있다
#      (/volume1/dss/setup/43-deploy.sh). 🔴 **--apply 가 없으면 DB 에 한 글자도 안
#      쓴다**는 것도 거기 적혀 있다.
#   🔵 이번 판이 백필의 **동작**을 바꾸지는 않는다. 바뀐 넷 중 백필이 부르는
#      resolveUsedPartsWriteGate 는 **한 글자도 안 바뀌었고**(새로 생긴 것은 그것을
#      감싸는 …WithInventory 쪽이다), 백필은 지금도 옛 함수를 그대로 부른다.
#   🔴 **대신 눈으로 볼 곳이 있다.** 아래 「동작이 바뀌는 자리」 절과 꼬리말을 보세요.
#
# ── 🔴 연락서 폴더 검사 — 42번에서 넣었고 **그대로 둔다** ──────────────
#   41번이 compose 에서 재던 볼륨은 'as-migrations' 한 줄뿐이었다. 그런데 백필은
#   **연락서 원본 폴더를 읽어야** 돈다. 개발 PC 쪽 compose 사본은 운영보다 여러
#   판 낡아서 「사본에 있으니 운영에도 있겠지」가 성립하지 않는다 — 그래서 운영
#   파일에서 직접 센다.
#   🔵 **이번 판도 백필을 안 돌리므로 이 검사가 당장 쓰일 일은 없다.** 그래도
#      빼지 않는다 — 이 볼륨은 **연락서를 새로 이식할 때마다** 쓰이고, 조용히
#      빠져 있으면 다음에 이식하는 날 그 자리에서 막힌다. 한 번 빼면 다시 넣는
#      사람이 없다.
#     · 1절 : tools-as 블록에 '/kyosan-src' · '/kyosan-converted' 줄이 있나
#     · 7절 : --go 끝에 **폴더가 실제로 열리는지** 결과를 센다(줄이 아니라 결과)
#   🔴 **없어도 배포를 막지 않는다.** 앱·도구 교체는 그 폴더와 무관하다. 그래서
#      1절에서는 ✗(FAIL) 가 아니라 **?** 로 센다 — ✗ 는 4·5절의 문을 닫아
#      멀쩡한 교체까지 막는다.
#
# ── 🔴 이번 배포에서 **동작이 바뀌는 자리** — 쓰는 분이 눈으로 볼 곳 ────
#   ① 🔴 **수리 건 상세 → [사용부품].** **반출이 실제로 나간 건은 칸이 잠긴다**
#      (새 동작). 재고 관리에 이 건으로 나간 줄이 있으면 적을 수 없고, 화면에
#      「이 건의 부품은 부품 요청(반출) 이력에서 잡힙니다…」가 뜬다.
#      🔵 **반려·취소만 된 건은 그대로 열린다** — 한 개도 안 나갔으면 적을 자리가
#         여기뿐이기 때문이다. 이 둘을 꼭 갈라서 보세요.
#   ② **제품 모델 상세 → [A/S 이력].** 년·월 드롭다운 둘이 생긴다. **네 그래프와
#      접수 건 목록이 함께** 걸린다(인수일 기준). [고장 부품] 그래프는 이제
#      **사용 부품과 반출 확인된 부품까지** 센다.
#   ③ **[고장 부품] 조각을 누르면** 그 아래에 **그 부품의 재고 관리 줄**이
#      펼쳐진다 — 🔵 **소유구분을 나눠서** 줄마다 보인다(KYOSAN · DSS 가 따로다).
#      같은 품번에 줄이 여럿인 것은 고장이 아니라 저쪽 시스템의 모양이다.
#   ④ 🔵 **기대치 — 이름이 안 붙고 품번만 보이는 줄이 많다. 결함이 아니다.**
#      이름이 붙으려면 맞은 재고 관리 줄에 **고객사 품명이 적혀 있어야** 하는데,
#      재고 관리 부품 **319줄 중 고객사 품명이 적힌 줄은 27개뿐**이다(2026-10-29 실측).
#      🔵 **재고 관리에서 고객사 품명을 채우면 A/S 는 아무것도 안 고쳐도 저절로
#         붙는다** — 그러라고 이름을 재고 관리에서 가져오는 설계를 골랐다.
#   ⑤ 🔵 **저장된 글자는 안 바뀐다.** 백필을 다시 돌릴 까닭이 없는 것도 그래서다.
#   ⑥ 🔵 **연락서 이식 규칙은 안 건드린다** — 43번이 올린 판본 C 의 칸 차례와
#      겹친 줄 수량 더하기는 **그대로다.**
#
# ── 🔴 ①-보조: 재고 관리가 꺼져 있으면 **사람이 막힌다** ───────────────
#   🔴 **이번 판에서 이 함정의 성격이 달라졌다.** 지난 판까지는 재고 관리가 멈추면
#      이름이 안 붙을 뿐이었다(조용한 쪽). 이번 판은 **[사용부품] 칸이 모든 건에서
#      막힌다** — 문지기가 「못 물어봤다」를 「없다」로 눕히지 않기 때문이다.
#      화면에는 「재고 관리에 물어볼 수 없어 지금은 사용 부품을 적을 수 없습니다.
#      재고 관리가 열리면 다시 해 주세요.」가 뜬다.
#   🔵 그 설계 자체는 맞다 — 「모른다」를 「없다」로 눕히면 중복이 조용히 쌓인다.
#      🔴 다만 **운영 설정이 빠져 있어도 똑같이 막힌다.** 이름이 둘이다:
#        INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN  (NAS 의 env/as.env)
#      운영은 이미 재고 관리를 쓰고 있어 둘 다 있을 것이다. 🔴 **그래도 짐작하지
#      않는다** — 아래 7절이 **「설정이 적혀 있나」가 아니라 「물어보니 답하나」**를
#      앱 컨테이너 안에서 실제로 잰다(inventory_gateway_check).
#   🔵 7절은 재고관리 컨테이너가 계속 도는지(KEEP_BOXES)도 그대로 센다.
#
# ── 🔴 44번(지난 판)과 다른 것 ─────────────────────────────────────────
#   ① 모양은 같다 — 저장소 하나(A/S)에 **태그는 둘**(앱 하나 + 도구 하나).
#   ② 🔵 **도구 이미지 안을 재는 단계가 다섯에서 여섯이 된다.** 44번의 ③ 이
#      **ㄱ·ㄴ 둘로 갈린다**:
#        ㄱ) 파일이 있나 — **셋에서 다섯으로.** 44번의 셋
#            (kyosan/parts-detail-sheet.ts · kyosan/report-preview.ts ·
#             domain/used-part-display.ts)은 **그대로 두고**, 이번에 바뀌었고
#            **도구가 실제로 부르는** 둘을 더한다
#            (auth/repair-case-used-parts-authorization.ts ·
#             server/inventory-gateway.ts). 🔴 **다섯이 다 있어야 ✓.**
#        ㄴ) 🔴 **그 파일이 '새 판' 인가 — 글자로 센다.** ㄱ 은 「있나」만 보므로
#            낡은 src/ 가 담겨도 통과한다. 그래서 **이번 판에만 있는 이름 셋**을
#            이미지 안에서 찾는다(기준 3206ca2 판에는 0번 나온다 — 실측).
#   ③ 🔴 **7절에 재고 관리 통로 검사를 더했다**(이번 판에서 새로 생긴 줄).
#      까닭은 위 ①-보조. 🔵 **읽기만 한다** — GET /api/v1/parts 한 번이고 저쪽
#      DB 에도 A/S DB 에도 한 글자 안 쓴다.
#   ④ 🔵 **연락서 폴더 검사는 42~44번 것 그대로다.**
#   ⑤ 🔵 **꼬리말의 백필 안내는 44번과 같다** — 「돌리지 않는다」.
#   ⑥ 🔴 **다시 띄우는 것은 app-as 하나뿐이다.** tools-as 는 'profiles: [tools]'
#      라 평소에 뜨지 않는 서비스다 — compose 의 태그만 새 것으로 고쳐 두면
#      다음에 'run --rm tools-as' 로 부를 때 새 이미지를 쓴다. **up -d 로
#      띄우지 않는다** — 띄우려 하면 프로필이 안 걸려 있어 compose 가 그 서비스를
#      모르는 것으로 다룬다.
#   ⑦ 🔵 **--rollback 은 앱만 되돌린다.** 도구는 :6 그대로 둔다 — 39·41~44번과
#      같은 판단이다(판에 매이지 않고, 새 도구가 있는 편이 낫다. 되돌릴 일이
#      생겨도 이 도구는 '--apply' 를 주지 않으면 DB 에 한 글자도 안 쓴다).
#   ⑧ 🔵 RF_Service_System 의 Dockerfile 은 tools 스테이지를 runner **앞에**
#      둔다 — --target 없이 구우면 마지막 스테이지(runner)가 기본값이 된다.
#      이 함정은 45-build.sh 쪽 이야기지만, 그 결과(올바른 tools 이미지)가
#      맞게 왔는지는 이 파일의 3절이 다시 센다.
#
# ── 🔴 개발 PC → NAS 로 올릴 것 — **셋** (마이그레이션 묶음이 없다) ─────
#   ㄱ) 이미지 tar **둘** → /volume1/dss/images/
#        dss-as-3.8.tar · dss-as-tools-6.tar
#   ㄴ) 이 파일 → /volume1/dss/setup/
#
#   (개발 PC · PowerShell)
#     cd C:\Users\희만\Desktop\Development\_images-42
#     scp -O dss-as-3.8.tar dss-as-tools-6.tar dss-nas:/volume1/dss/images/
#     cd C:\Users\희만\Desktop\Development
#     scp -O dss-deploy\nas\setup\45-deploy.sh dss-nas:/volume1/dss/setup/
#     Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\45-deploy.sh
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#   🔴 tar 에 드라이브 문자(C:)를 주지 마세요 — 원격 호스트로 읽습니다.
#
# ── 모드 넷 ───────────────────────────────────────────────────────────
#   (기본)   --check      아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --preload             tar 둘을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --go                  compose 의 image: 줄 둘(app-as·tools-as)을 바꾸고
#                         app-as 만 다시 띄운다
#   --rollback            app-as 만 옛 판으로 되돌린다 (도구는 :6 그대로)
#
#   🔴 차례:  --check → --preload → --check → --go
#
# ── 🔴 --check 도 「아무것도 안 한다」는 아니다 ───────────────────────
#   A/S DB 에 **select** 를 한 번 보낸다(마이그레이션 수가 그대로인지 — 바꾸는
#   문장은 없다). 앱의 바깥 주소에 GET 을 한 번 보낸다. 재고 관리 통로에도
#   **GET 을 한 번** 보낸다(읽기만 한다). 도구 이미지가 이미 실려 있으면
#   **안을 보려고 컨테이너를 잠깐 띄웠다 지운다**(docker run --rm, DB 에는 안
#   닿는다 — DATABASE_URL 을 안 주고 부른다).
#   「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 쓴 뒤 세었다.
#   ② 읽기 전용 자리에 콜론 하나와 꺾쇠로 빈 파일을 만들면 NAS 의 ash 가 셸을
#      그 자리에서 끝낸다(2026-10-12 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#
# ── 🔴 비밀값을 찍지 않는다 ───────────────────────────────────────────
#   .env 는 **이름이 있는가/없는가**만 본다. 값도, 값의 길이도 찍지 않는다.
#   🔴 7절의 재고 관리 검사도 마찬가지다 — 토큰을 **쓰기만** 하고 찍지 않는다.
#      찍는 것은 HTTP 상태와 받은 줄 수뿐이다.
#   이번 판에 새로 필요한 설정 이름은 없다(INVENTORY_API_* 둘은 2026-10-15 부터
#   이미 쓰고 있다 — 부품 요청 칸이 그것으로 돈다).
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v42-$STAMP

# ══ 이번에 다시 띄우는 것 — 앱 하나뿐이다 ═════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
SITES='
as|app-as|dss-as|dss-as:3.8|dss-as:3.7|dss-as-3.8.tar|13000
'
# 🔵 7절의 재고 관리 검사가 명령을 넣을 상자. 위 표 셋째 칸과 같은 이름이다.
AS_APP_CN=dss-as
# ══ 🔴 A/S 도구 — **이번에 갈아 끼운다.** up -d 로 다시 띄우지 않는다 ═══
#   (profiles: [tools] 라 평소에 뜨지 않는다. compose 의 태그만 고치면
#    다음에 run --rm tools-as 로 부를 때 새 이미지를 쓴다.)
AS_TOOLS_SVC=tools-as
TOOLS_OLD=dss-as-tools:5
TOOLS_NEW=dss-as-tools:6
IMG_MIGDIR=/app/drizzle
MIGDIR=$D/as-migrations

# ══ 🔴 연락서 원본 폴더 — 연락서를 이식할 때 읽는 자리 ════════════════
#   🔵 기대값의 출처: 2026-10-28 실측 673장 · 143장. 늘기만 하는 폴더라 아래
#      바닥값으로 잰다. 🔴 **0 이면 볼륨 줄은 있는데 안 열리는 것**이고, 그것이
#      제일 조용한 실패다.
KYO_SRC=/kyosan-src;        KYO_SRC_MIN=600
KYO_CONV=/kyosan-converted; KYO_CONV_MIN=100

# ══ 🔴 tar 둘의 지문 — [배포본] 45-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   ✅ **채웠다** — 2026-10-29 15:17 에 45-build.sh --go 가 굽고 **바로 잰 값**이다.
#      (비어 있으면 3절이 **? 로 센다** — 「옮기다 깨진 것」은 잡지만 「개발 PC 에서
#      구운 그것이 맞나」는 못 본다.)
#   🔵 이름만이라도 적어 두는 까닭: 줄이 아예 없으면 4절(--preload)이 **아무것도
#      안 싣고 조용히 끝난다.** 이름이 있으면 싣기는 제대로 된다.
TARS='
dss-as-3.8.tar|132478976|0be98f286f65c4c10b467cd90b655919|sha256:2fa83fcbacb8e096434f853d2b6cd39ea29bc82efdcfc1541c3fa392691d62c6
dss-as-tools-6.tar|223703552|c5248a7e9870b70873ad2311b1da9c3b|sha256:869a03cb59d80dfea02a08733a2cb5ccec89f3fdd5c3fe1408c318b72bb2ed28
'
tar2tag() {
  case "$1" in
    dss-as-3.8.tar)      printf 'dss-as:3.8' ;;
    dss-as-tools-6.tar)  printf 'dss-as-tools:6' ;;
  esac
}

# ══ 🔴 A/S — DB 는 **그대로여야** 한다(마이그레이션 0건) ═════════════
AS_BOX=dss-pg-app; AS_DB=dss_as; AS_KEEP=121   # [저장소] 45-build.sh 4절과 같다
# 🔵 안 건드리는 아홉 — 「옆으로 안 샜다」는 증거로 센다
KEEP_BOXES="dss-auth dss-inventory dss-meters dss-po dss-board dss-improvements dss-leave dss-approvals dss-rf-trouble"
# 🔵 DB 둘은 멈추지 않는다 (애초에 up -d --no-deps 가 app-as 하나만 건드린다)
KEEP_DB="dss-pg-app dss-pg-auth"

MODE=check
case "${1:-}" in
  --check|"")  MODE=check ;;
  --preload)   MODE=preload ;;
  --go)        MODE=go ;;
  --rollback)  MODE=rollback ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --preload · --go · --rollback\n' "$1"; exit 2 ;;
esac

PASS=0; FAIL=0; WARN=0
ok()  { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
hm()  { WARN=$((WARN+1)); printf '  ? %s\n' "$1"; }
say() { printf '    %s\n' "$1"; }
cmd() { printf '      %s\n' "$1"; }
# 🔴 ✗ 가 났을 때 그 자리에서 찍는다 — 처음 도는 코드라 기대값이 틀릴 확률이
#    배포만큼 높다. ✓ 쪽 오판은 영영 안 드러나므로 ✗ 쪽을 크게 적는다.
doubt() { say "🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 이 줄의 기대값이"
          say "   어디서 왔는지는 파일 머리의 기대값 표에 적혀 있습니다."; }

isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }
rows()  { printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'; }
trows() { printf '%s\n' "$TARS"  | tr -d ' ' | grep -v '^$'; }
fld()   { printf '%s' "$1" | cut -d'|' -f"$2"; }

dc()  { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas "$@" ); }
dct() { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas --profile tools "$@" ); }

[ "$(id -u)" = 0 ] || { printf '먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요.\n'; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/45-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "마흔두째 배포 — A/S 앱 · A/S 도구   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  로그: $LOG"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 공통: compose 에서 그 서비스의 image: 줄을 찾는다 ─────────────────
# 🔴 그 블록 안의 것 하나만 고쳐야 한다. 서비스 머리부터 다음 서비스 머리 전까지.
img_line() { # 1 서비스
  local s start next
  s=$1
  start=$(grep -n "^  ${s}:" "$CF" | head -1 | cut -d: -f1)
  [ -n "$start" ] || return 1
  next=$(awk -v s="$start" 'NR>s && /^  [a-z]/ {print NR; exit}' "$CF")
  awk -v s="$start" -v e="${next:-999999}" 'NR>s && NR<e && /^[[:space:]]*image:/ {print NR; exit}' "$CF"
}
tag_at() { awk -v n="$1" 'NR==n {print $2}' "$CF"; }
svc_block() { # 1 서비스 — 주석 줄은 뗀다
  awk -v s="  $1:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$CF" | sed '/^[[:space:]]*#/d'
}

# 🔴 운영 DB 를 **앱이 쓰는 길**(컨테이너 안 psql)로 잰다. 소켓·루프백으로 재면
#    trust 라 그냥 통과한다. 보내는 SQL 은 select 뿐이다.
pgq() { # 1 상자 2 DB 3 SQL
  "$DOCKER" exec -i "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -X -tAq -c \"$3\"" 2>/dev/null | head -1 | tr -d ' \r'
}
pgn() { local v; v=$(pgq "$1" "$2" "$3"); isnum "$v" && printf '%s' "$v"; }
mig_count() { pgn "$1" "$2" 'select count(*) from drizzle.__drizzle_migrations'; }

# ══ 🔴 재고 관리 통로가 **값을 돌려주는가** (이번 판에서 새로 넣은 절) ══
#   🔴 「설정이 적혀 있다」가 아니라 **「물어보니 답한다」**로 잰다. 설정은 있는데
#      주소가 안 닿거나 토큰이 안 맞는 경우가 **이번 판에서 제일 아픈 실패**다 —
#      [사용부품] 칸이 모든 건에서 막히기 때문이다(머리말 ①-보조).
#   🔴 **앱이 쓰는 길로 잰다** — 막히는 자리가 app-as 안이므로 그 컨테이너 안에서
#      묻는다. 바깥에서 재면 그 컨테이너의 설정이 아니라 NAS 의 망을 재게 된다.
#   🔵 **읽기만 한다.** GET /api/v1/parts 한 번이고(앱이 부품 이름을 얻을 때 쓰는
#      바로 그 통로다 — server/inventory-gateway.ts 216줄), 저쪽 DB 에도 A/S DB 에도
#      한 글자 안 쓴다. 토큰은 쓰기만 하고 **찍지 않는다.**
#   🔵 쓰기 토큰(INVENTORY_WRITE_TOKEN)은 안 본다 — 이번 판이 막히고 풀리는 자리는
#      **읽기 쪽** 하나다. 쓰기 토큰은 부품 요청을 올릴 때만 쓰고, 그 길은 이번에
#      안 바뀌었다.
#   🔴 **도구 쪽(tools-as)은 안 잰다.** 까닭을 적어 둔다 — 백필도 같은 설정을 쓰지만
#      못 물어보면 **아무것도 안 쓰고 멈춘다**(outcome 'inventory-unknown' —
#      scripts/lib/kyosan-used-parts-backfill.ts 408-416줄). 즉 설정이 빠져도 자료가
#      상하지 않고, 이번 판은 백필을 아예 안 돌린다. 재야 할 날은 **연락서를 다시
#      이식하는 날**이고, 그날 이 절을 베껴 'dct run --rm -T tools-as' 로 바꾸면 된다.
#
#   받는 답은 셋 중 하나다(일부러 ASCII 로만 찍게 했다 — 한글을 argv 로 넘겨
#   깨지는 길을 아예 두지 않는다):
#     NOCONF base=0 token=1   설정이 비었다
#     HTTP 200 rows 319       물어봤고 답이 왔다
#     FAIL timeout            못 닿았다
INV_PROBE='const b=(process.env.INVENTORY_API_BASE_URL||"").trim().replace(/\/+$/,"");
const t=(process.env.INVENTORY_API_TOKEN||"").trim();
if(b===""||t===""){console.log("NOCONF base="+(b===""?0:1)+" token="+(t===""?0:1));}
else{
const c=new AbortController();
const timer=setTimeout(function(){c.abort();},8000);
fetch(b+"/api/v1/parts",{method:"GET",headers:{Accept:"application/json",Authorization:"Bearer "+t},cache:"no-store",signal:c.signal})
.then(function(r){return r.json().catch(function(){return null;}).then(function(j){
var n=-1;
if(j&&typeof j==="object"&&Array.isArray(j.parts)){n=j.parts.length;}
console.log("HTTP "+r.status+" rows "+n);});})
.catch(function(e){var m=(e&&e.message)?String(e.message).split("\n")[0]:"error";console.log("FAIL "+((e&&e.name==="AbortError")?"timeout":m));})
.then(function(){clearTimeout(timer);});}'

# 🔴 **단계마다 기대값이 아니라 '엄함'이 다르다.** --check 에서는 ? 로만 센다 —
#    아직 안 갈아 끼웠으니 그 자리에서 배포를 막을 일이 아니고, ✗ 로 세면 4·5절의
#    문이 닫혀 멀쩡한 교체까지 막힌다. --go 에서는 ✗ 다 — 그때는 **사람이 실제로
#    막혀 있는 상태**이기 때문이다.
inventory_gateway_check() { # 1 strict|soft
  local strict out line rows
  strict=0; [ "${1:-soft}" = strict ] && strict=1
  printf '\n    ── 재고 관리 통로가 값을 돌려주는가 (설정이 아니라 **답**으로 센다)\n'
  out=$("$DOCKER" exec "$AS_APP_CN" node -e "$INV_PROBE" 2>&1 | tr -d '\r')
  line=$(printf '%s\n' "$out" | grep -E '^(HTTP|NOCONF|FAIL)' | tail -1)
  say "받은 것: ${line:-못 쟀다}"
  case "${line:-}" in
    "HTTP 200 rows "*)
      rows=${line##* }
      if isnum "${rows:-}" && [ "${rows:-0}" -ge 1 ]; then
        ok "재고 관리가 답한다 — 200 · 부품 ${rows}줄 ([사용부품] 칸이 막히지 않는다)"
        say "🔵 고객사 품명이 적힌 줄은 그중 일부뿐이다(2026-10-29 실측 319줄 중 27줄)."
        say "   이름이 안 붙고 품번만 보이는 줄이 많은 것은 **결함이 아니다.**"
      else
        hm "200 인데 부품 줄이 ${rows:-?} 이다 — 응답 모양이 기대와 다르다. 사람이 보세요"
        doubt
      fi ;;
    NOCONF*)
      say "🔴 **설정이 비어 있다.** 값은 안 찍는다 — 0 은 비었다는 뜻이다."
      say "   고칠 자리: NAS 의 /volume1/dss/deploy/env/as.env (root 600)"
      say "   이름 둘: INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN"
      if [ "$strict" = 1 ]; then
        bad "🔴 재고 관리 설정이 비어 **[사용부품] 칸이 모든 건에서 막힌다** — 설정을 넣고 app-as 를 다시 띄우세요"
      else
        hm "재고 관리 설정이 비어 있다 — **이대로 --go 하면 [사용부품] 칸이 모든 건에서 막힌다**"
      fi ;;
    "")
      if [ "$strict" = 1 ]; then
        bad "🔴 재고 관리 통로를 **못 쟀다** — $AS_APP_CN 안에서 node 가 안 돌았다"
      else
        hm "재고 관리 통로를 못 쟀다 — $AS_APP_CN 가 도는지 보세요"
      fi
      printf '%s\n' "$out" | tail -8 | sed 's/^/      /' ;;
    *)
      say "🔴 답이 200 이 아니거나 아예 못 닿았다 — 401 이면 토큰, 404 면 주소,"
      say "   FAIL 이나 timeout 이면 망이거나 저쪽 상자다."
      if [ "$strict" = 1 ]; then
        bad "🔴 재고 관리가 안 답한다 — **[사용부품] 칸이 모든 건에서 막힌다.** 위 줄을 보세요"
      else
        hm "재고 관리가 안 답한다 — **이대로 --go 하면 [사용부품] 칸이 모든 건에서 막힌다**"
      fi
      printf '%s\n' "$out" | tail -8 | sed 's/^/      /'
      doubt ;;
  esac
}

# ══ 🔴 A/S 도구 이미지 **안**을 센다 — 겉이 아니라 결과 ══════════════
#   🔴 --target tools 를 빠뜨렸으면 runner 가 구워지고, 그 안에는 scripts/ 도
#      package.json 도 없다. 이미지는 멀쩡히 실리고 오류가 안 난다. 증상은
#      **쓸 일이 생긴 날**의 「모듈을 못 찾는다」 한 줄뿐이다. 그래서 여기서 센다.
#   🔵 **단계가 다섯에서 여섯이 된다.** 44번의 ③ 이 ㄱ·ㄴ 둘로 갈린다(머리말).
#   🔴 이번 판은 도구가 바뀐 코드를 **실제로 부른다** — 그래서 ㄴ(새 판인가)이
#      44번보다 훨씬 중요하다. 낡은 src/ 가 담기면 다음 연락서 이식이 옛 규칙으로
#      돈다. 🔵 **오류는 한 줄도 안 난다.**
#   🔵 ⑤ 는 42~44번 그대로다. 백필을 **직접** 부르되 **DATABASE_URL 을 안 준다** —
#      그 파일이 1줄에서 './load-env' 를, 9줄에서 '../src/lib/db/connection' 을
#      정적 import 하고, connection.ts 가 모듈 맨 위에서 동기적으로 던진다.
#      인자를 안 줘도 파싱까지 안 가고 import 에서 막힌다.
#      **DB 에는 한 글자도 안 닿는다.**
#   🔴 ⑤ 가 말해 주는 것은 **import 가 선다**까지다. 🔵 이번 판도 백필을 다시
#      돌리지 않으므로, 도구가 선다는 것을 확인할 자리가 **여기 말고 없다.**
#   🔴 **「✗ 가 아니면 ✓」로 세지 않는다.** ✓ 조건만 정확히 적고 나머지는 ? 다 —
#      ✓ 쪽 오판은 영영 안 드러난다.
tools_inside_check() {
  local v got
  printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TOOLS_NEW"
  # ① runner 가 아니라 tools 인가 — runner 에는 /app/package.json 이 없다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/package.json: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "tools 스테이지가 맞다" \
    || { bad "🔴 /app/package.json 이 없다 — **runner 를 구웠다.**"; doubt; }
  # ② 백필 도구 파일 셋이 다 담겼는가 — 하나라도 없으면 ✗.
  #    🔵 이번 판에서 이 셋은 한 글자도 안 바뀌었지만, 있어야 부를 수 있다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts /app/scripts/lib/kyosan-used-parts-backfill-plan.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "3" ] && ok "백필 도구 파일 셋이 다 들어 있다" \
    || bad "🔴 백필 도구 파일이 ${got:-0}/3 개다 — scripts/ 가 온전히 안 담겼다"
  # ③-ㄱ 🔴 **src/ 가 온전히 담겼는가 — 파일 다섯으로 센다.** 앞의 셋은 43·44번
  #    것 그대로, 뒤의 둘이 이번에 더한 것이고 **도구가 이름으로 끌어 쓰는** 파일이다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/src/lib/kyosan/parts-detail-sheet.ts /app/src/lib/kyosan/report-preview.ts /app/src/lib/domain/used-part-display.ts /app/src/lib/auth/repair-case-used-parts-authorization.ts /app/src/lib/server/inventory-gateway.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "5" ] && ok "src/ 의 파일 다섯이 다 들어 있다 (도구와 앱이 같은 판이다)" \
    || { bad "🔴 src/ 의 파일이 ${got:-0}/5 개다 — src/ 가 온전히 안 담겼다"; doubt; }
  # ③-ㄴ 🔴 **그 파일이 '새 판' 인가 — 글자로 센다.** ㄱ 은 「있나」만 보므로 낡은
  #    src/ 가 담겨도 통과한다. 아래 셋은 기준 3206ca2 판에 **0번** 나오고 지금
  #    판에만 있다(2026-10-29 git show 로 확인).
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for pair in "probeInventoryIssuedPartsTrace /app/src/lib/server/inventory-gateway.ts" "resolveUsedPartsWriteGateWithInventory /app/src/lib/auth/repair-case-used-parts-authorization.ts" "resolveInventoryIssuedPartsTrace /app/src/lib/domain/inventory-gateway.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "3" ] && ok "새 판의 이름 셋이 이미지 안에 있다 (옛 src/ 가 아니다)" \
    || { bad "🔴 새 판의 이름이 ${got:-0}/3 개다 — **옛 src/ 가 담긴 이미지다.** 올리지 마세요"; doubt; }
  # ④ tsx 가 있는가 — 이 도구는 tsx 로만 돈다(운영 이미지에는 없는 devDependency다).
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/node_modules/tsx: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "tsx 가 있다" \
    || bad "🔴 tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다"
  # ⑤ 🔴 값으로 받아 본다. DATABASE_URL 을 안 준다 — DB 에 안 닿는다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'cd /app && node --conditions=react-server --import tsx scripts/backfill-kyosan-used-parts.ts 2>&1 | head -40' 2>&1 | tr -d '\r')
  if printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
    ok "import 까지 갔고 DB 에는 안 닿았다 (DATABASE_URL is not set — 기대한 답)"
  elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
    bad "🔴 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
  else
    hm "기대한 답이 아니다 — 아래 20줄을 사람이 보세요"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
  fi
}

# ══ 🔴 연락서 폴더가 **실제로 열리는가** — 줄이 아니라 결과 ══════════
#   🔵 1절은 compose 에 줄이 있는지만 본다. 줄은 있는데 안 열리는 것이 제일
#      조용한 실패라 여기서 **수를 받아** 본다. 보내는 명령은 ls 뿐이다 —
#      이 서비스에는 DATABASE_URL 이 들어 있지만 ls 는 DB 를 안 건드린다.
#   🔵 -T 는 가짜 터미널을 안 만들려고 준다. 없으면 줄 끝에 캐리지리턴이 붙어
#      수를 파싱하는 쪽이 어긋날 수 있다.
#   🔵 **이번 판도 백필을 안 돌리므로 여기서 ✗ 가 나도 이 배포의 일은 끝난 것이다.**
#      다음에 연락서를 이식할 때 막히지 않게 지금 재 두는 것이다.
kyosan_folder_check() {
  local out src conv good
  good=1
  printf '\n    ── 연락서 폴더가 실제로 열리는가 (줄이 아니라 결과)\n'
  out=$(dct run --rm -T "$AS_TOOLS_SVC" sh -c 'ls /kyosan-src 2>/dev/null | wc -l; ls /kyosan-converted 2>/dev/null | wc -l' 2>&1 | tr -d ' \r')
  src=$(printf '%s\n' "$out"  | grep -E '^[0-9]+$' | sed -n 1p)
  conv=$(printf '%s\n' "$out" | grep -E '^[0-9]+$' | sed -n 2p)
  say "$KYO_SRC ${src:-못 쟀다}장 (기대 $KYO_SRC_MIN 이상 · 2026-10-28 실측 673)"
  if isnum "${src:-}" && [ "${src:-0}" -ge "$KYO_SRC_MIN" ]; then
    ok "$KYO_SRC 가 열린다 (${src}장)"
  elif [ "${src:-}" = "0" ]; then
    bad "🔴 $KYO_SRC 가 **비었다** — 볼륨 줄은 있는데 안 열린다"; good=0
  else
    hm "$KYO_SRC 가 ${src:-못 쟀다} 다 — $KYO_SRC_MIN 이상을 기대했다. 사람이 보세요"; good=0
  fi
  say "$KYO_CONV ${conv:-못 쟀다}장 (기대 $KYO_CONV_MIN 이상 · 2026-10-28 실측 143)"
  if isnum "${conv:-}" && [ "${conv:-0}" -ge "$KYO_CONV_MIN" ]; then
    ok "$KYO_CONV 가 열린다 (${conv}장)"
  elif [ "${conv:-}" = "0" ]; then
    bad "🔴 $KYO_CONV 가 **비었다** — 볼륨 줄은 있는데 안 열린다"; good=0
  else
    hm "$KYO_CONV 가 ${conv:-못 쟀다} 다 — $KYO_CONV_MIN 이상을 기대했다. 사람이 보세요"; good=0
  fi
  if [ "$good" != 1 ]; then
    say "── 받은 것 그대로 (끝 12줄)"
    printf '%s\n' "$out" | tail -12 | sed 's/^/      /'
    say "🔵 이 줄은 **앱·도구 교체와 무관하다 — 되돌리지 마세요.**"
    say "   연락서를 이식할 때만 필요한 폴더다. compose 의 $AS_TOOLS_SVC 볼륨을"
    say "   고치고 이 절만 다시 재면 된다."
  fi
}

# ── 1. 지금 상태 ──────────────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
[ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
say "compose 줄 수 $(wc -l < "$CF") · image: 줄 $(grep -c '^ *image:' "$CF")개"
for r in $(rows); do
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  L=$(img_line "$SVC") || { bad "$SVC — compose 에서 image: 줄을 못 찾았다"; continue; }
  CUR=$(tag_at "$L")
  ST=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  say "$SVC — ${L}줄 · compose ${CUR} · 도는 것 ${RUN:-없음} (${ST:-?})"
  if [ "$CUR" = "$OLD" ]; then ok "$SVC 가 옛 판 $OLD 다 (갈아 끼울 준비)"
  elif [ "$CUR" = "$NEW" ]; then hm "$SVC 가 이미 $NEW 다 (다시 돌리는 중인가)"
  else bad "$SVC 의 태그가 $CUR 다 — 옛 판도 새 판도 아니다. 멈추고 알릴 것"; doubt; fi
done
# 🔴 A/S 도구 — **--go 가 고친다. --rollback 은 안 건드린다**(머리말의 판단).
#    🔴 단계마다 기대값이 다르다. 한 잣대로 재면 가짜 ✗/? 가 난다.
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  say "$AS_TOOLS_SVC — ${TL}줄 · $TCUR"
  case "$MODE" in
    rollback)
      [ "$TCUR" = "$TOOLS_NEW" ] && ok "$AS_TOOLS_SVC 가 $TOOLS_NEW 다 (🔵 되돌려도 도구는 그대로 둔다)" \
        || hm "$AS_TOOLS_SVC 가 $TCUR 다 — 🔵 되돌리기를 막지 않는다" ;;
    *)
      if [ "$TCUR" = "$TOOLS_OLD" ]; then ok "$AS_TOOLS_SVC 가 $TOOLS_OLD 다 (고칠 준비 — --go 가 $TOOLS_NEW 로 고친다)"
      elif [ "$TCUR" = "$TOOLS_NEW" ]; then hm "$AS_TOOLS_SVC 가 이미 $TOOLS_NEW 다 (다시 돌리는 중인가)"
      else bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $TOOLS_OLD 도 $TOOLS_NEW 도 아니다. 멈추고 알릴 것"; doubt; fi ;;
  esac
  # 🔴 볼륨이 제 자리에 붙는가 — 여기가 어긋나면 **다음 마이그레이션이 엉뚱한 것을 읽는다.**
  if svc_block "$AS_TOOLS_SVC" | grep -q "$MIGDIR:$IMG_MIGDIR"; then
    ok "$AS_TOOLS_SVC 가 $MIGDIR 를 $IMG_MIGDIR 로 붙인다 (안 건드렸다)"
  else
    bad "🔴 $AS_TOOLS_SVC 의 drizzle 볼륨이 $MIGDIR 가 아니다 — 이 배포가 건드릴 자리가 아닌데 어긋났다"
  fi
  # 🔴 42번에서 넣은 검사다. 연락서를 이식하려면 원본 폴더가 열려야 한다. 개발 PC 쪽
  #    compose 사본은 운영보다 여러 판 낡아서 「사본에 있으니 운영에도 있겠지」가
  #    성립하지 않는다 — 운영 파일에서 센다. 🔵 **이번 판도 백필을 안 돌리므로 당장
  #    쓰이지는 않는다.** 그래도 빼지 않는다 — 다음 이식 때 조용히 막히는 자리다.
  #    🔵 **없어도 교체를 막지 않는다.** 앱·도구 교체는 이 폴더와 무관하다.
  #       그래서 ✗ 가 아니라 ? 로 센다 — ✗ 는 4·5절의 문을 닫아 멀쩡한 교체까지
  #       막는다.
  for kv in "$KYO_SRC" "$KYO_CONV"; do
    if svc_block "$AS_TOOLS_SVC" | grep -q "$kv"; then
      ok "$AS_TOOLS_SVC 에 $kv 볼륨 줄이 있다 (연락서를 이식할 때 읽을 자리)"
    else
      hm "$AS_TOOLS_SVC 에 $kv 볼륨 줄이 **없다** — 🔵 교체는 막지 않는다"
      say "🔴 **이대로면 다음 연락서 이식이 못 돈다.** compose 의 $AS_TOOLS_SVC 에 그 줄을 먼저 넣으세요."
    fi
  done
else
  bad "compose 에 $AS_TOOLS_SVC 가 없다 — 올릴 자리가 없다"
fi

# ── 2. 🔴 A/S DB — 마이그레이션 수가 **그대로여야** 한다 ──────────────
printf '\n== 2. A/S DB — 마이그레이션 %s 그대로여야 한다\n' "$AS_KEEP"
MIG_AS0=$(mig_count "$AS_BOX" "$AS_DB")
say "A/S 기록 ${MIG_AS0:-?} (기대 $AS_KEEP 그대로)"
if [ -z "${MIG_AS0:-}" ]; then
  bad "DB 를 못 쟀다 — $AS_BOX 가 도는지 보세요"
elif [ "$MIG_AS0" = "$AS_KEEP" ]; then
  ok "A/S 가 $AS_KEEP 그대로다 (이 배포는 DB 를 건드리지 않는다)"
else
  bad "🔴 A/S 가 ${MIG_AS0} 이다 ($AS_KEEP 이어야 한다) — 다른 배포가 먼저 돌았거나 전제가 깨졌다"
  doubt
fi

# ── 3. 들여올 이미지 둘 ───────────────────────────────────────────────
printf '\n== 3. 들여올 이미지 둘 (앱 하나 + 도구 하나)\n'
BLANK=0
for t in $(trows); do
  TAR=$(fld "$t" 1); WSZ=$(fld "$t" 2); WM5=$(fld "$t" 3); WCFG=$(fld "$t" 4)
  T=$IMGD/$TAR
  if [ ! -s "$T" ]; then
    if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
      hm "$TAR 가 아직 없다: $T — **${MODE} 에서는 괜찮다**"
    else bad "$TAR 가 없다: $T — 먼저 올리세요"; fi
    cmd "scp -O $TAR dss-nas:$IMGD/"
    continue
  fi
  SZ=$(stat -c %s "$T" 2>/dev/null)
  M5=$(md5sum "$T" | awk '{print $1}')
  CFG=$(tar -xOf "$T" manifest.json 2>/dev/null | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 | sed 's|blobs/sha256/|sha256:|')
  say "$TAR — ${SZ}바이트 · md5 $M5"
  say "        tar 안 Config: ${CFG:-못 읽음}"
  if [ -z "$WSZ" ] || [ -z "$WM5" ] || [ -z "$WCFG" ]; then
    BLANK=$((BLANK+1))
    hm "$TAR — **잰 값이 이 파일에 없다.** 옮기다 깨진 것만 잡는다"
    continue
  fi
  [ "$SZ"  = "$WSZ"  ] && ok "$TAR 크기가 구울 때와 같다  [배포본]" || { bad "$TAR 크기가 다르다 (${SZ} != ${WSZ}) — 옮기다 깨졌다"; doubt; }
  [ "$M5"  = "$WM5"  ] && ok "$TAR md5 가 같다  [배포본]"           || { bad "$TAR md5 가 다르다 — 옮기다 깨졌다"; doubt; }
  [ "$CFG" = "$WCFG" ] && ok "$TAR 지문이 같다  [배포본]"           || { bad "$TAR 지문이 다르다 (${CFG:-못 읽음}) — **다른 판을 올렸다**"; doubt; }
done
if [ "$BLANK" != "0" ]; then
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 45-build.sh --go 가 끝에 찍어 주는"
  printf '%s\n' "     두 줄로 이 파일의 TARS 두 줄을 통째로 갈아 끼우세요."
fi
# 🔵 되돌릴 길 — 옛 태그가 남아 있는가(app-as 만. 도구는 되돌리지 않는다)
for r in $(rows); do
  OLD=$(fld "$r" 5)
  if "$DOCKER" image inspect "$OLD" >/dev/null 2>&1; then ok "$OLD 이 남아 있다 (되돌릴 길)"
  else hm "$OLD 이 없다 — 그 시스템은 --rollback 을 못 쓴다"; fi
done
# 🔴 도구 이미지가 **이미 실려 있으면** 그 자리에서 안을 센다.
if "$DOCKER" image inspect "$TOOLS_NEW" >/dev/null 2>&1; then
  tools_inside_check
else
  if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
    hm "$TOOLS_NEW 가 아직 안 실렸다 — **${MODE} 에서는 괜찮다**. 4절이 싣는다"
  else
    say "$TOOLS_NEW 가 아직 안 실렸다 — 4절이 싣는다"
  fi
fi

# 🔴 **재고 관리 통로 — --check 에서 미리 재 둔다.** ? 로만 센다(교체를 막지 않는다).
#    여기서 ? 가 나면 **--go 하기 전에 설정부터 고치는 것**이 맞다 — 고치지 않고
#    올리면 [사용부품] 칸이 모든 건에서 막힌다(머리말 ①-보조).
if [ "$MODE" = check ]; then inventory_gateway_check soft; fi

if [ "$MODE" = check ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.** 다음: --preload → (다시 --check) → --go"
  printf '%s\n' "🔴 올리기 전에 돌리면 ? 가 여럿 나오는 것이 **정상**이다 (tar)."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 4. --preload : tar 둘을 들여놓는다 ───────────────────────────────
if [ "$MODE" = preload ] || [ "$MODE" = go ]; then
  printf '\n== 4. tar 둘을 들여놓는다\n'
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 하고 멈춘다.**\n'; exit 1; fi
  for t in $(trows); do
    TAR=$(fld "$t" 1); NEW=$(tar2tag "$TAR")
    if [ -z "$NEW" ]; then bad "$TAR 의 태그를 모른다 — tar2tag() 에 줄을 더하세요"; continue; fi
    T=$IMGD/$TAR
    if [ ! -s "$T" ]; then bad "$TAR 가 없다: $T"; continue; fi
    WCFG=$(tar -xOf "$T" manifest.json 2>/dev/null | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 | sed 's|blobs/sha256/|sha256:|')
    if "$DOCKER" image inspect "$NEW" --format '{{.Id}}' 2>/dev/null | grep -q "$WCFG"; then
      ok "$NEW 는 이미 있고 지문이 tar 와 같다 (건너뜀)"; continue
    fi
    "$DOCKER" load -i "$T" 2>&1 | sed 's/^/    /'
    FULL=$("$DOCKER" image inspect "$NEW" --format '{{.Id}}' 2>/dev/null)
    if [ "$FULL" = "$WCFG" ]; then ok "$NEW 가 올라왔고 지문이 tar 와 같다"
    elif [ -n "$FULL" ]; then bad "$NEW 지문이 다르다 — tar $WCFG / NAS $FULL"
    else bad "$NEW 가 안 올라왔다"; fi
  done
  # 🔴 들여놓자마자 도구 이미지 안을 센다 — 늦게 발견할수록 되돌리기가 비싸다.
  if "$DOCKER" image inspect "$TOOLS_NEW" >/dev/null 2>&1; then
    tools_inside_check
  else
    bad "🔴 $TOOLS_NEW 가 아직 안 실렸다 — 위 load 가 실패했는지 보세요"
  fi
fi

if [ "$MODE" = preload ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **들여놓기만 했다 — 아직 안 갈아 끼웠다.** 다음: --check 를 다시 → --go"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 5. --go / --rollback : compose 의 image: 줄을 바꾼다 ─────────────
#  🔴 --go 는 **둘**(app-as·tools-as)을 고친다. --rollback 은 **app-as 하나만**
#     되돌린다 — 도구는 :6 그대로 둔다(39·41~44번과 같은 판단).
printf '\n== 5. compose 의 image: 줄을 바꾼다\n'
if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi

cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
chmod 644 "$BK"
ok "사본 $BK"
L0=$(wc -l < "$CF"); IMGS0=$(grep -c '^ *image:' "$CF")
BEF=$(mktemp) || exit 1
AFT=$(mktemp) || exit 1
grep -n '^ *image:' "$CF" > "$BEF"

for r in $(rows); do
  SVC=$(fld "$r" 2); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  if [ "$MODE" = rollback ]; then TO=$OLD; else TO=$NEW; fi
  L=$(img_line "$SVC") || { bad "$SVC — image: 줄을 못 찾았다"; continue; }
  TMP=$(mktemp) || exit 1
  awk -v n="$L" -v to="$TO" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
  cp "$TMP" "$CF"; rm -f "$TMP"
  NOW=$(tag_at "$L")
  if [ "$NOW" = "$TO" ]; then ok "$SVC → $TO (${L}줄)"; else bad "$SVC 의 태그가 $NOW 다"; fi
done

# 🔴 도구는 --go 일 때만 고친다. --rollback 은 **손대지 않는다.**
if [ "$MODE" = go ]; then
  TL=$(img_line "$AS_TOOLS_SVC") || { bad "$AS_TOOLS_SVC — image: 줄을 못 찾았다"; }
  if [ -n "${TL:-}" ]; then
    TMP=$(mktemp) || exit 1
    awk -v n="$TL" -v to="$TOOLS_NEW" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
    cp "$TMP" "$CF"; rm -f "$TMP"
    TNOW=$(tag_at "$TL")
    if [ "$TNOW" = "$TOOLS_NEW" ]; then ok "$AS_TOOLS_SVC → $TOOLS_NEW (${TL}줄)"; else bad "$AS_TOOLS_SVC 의 태그가 $TNOW 다"; fi
  fi
else
  say "🔵 $AS_TOOLS_SVC 는 이번 모드($MODE)에서 **안 건드린다** — :6 그대로 둔다"
fi

L1=$(wc -l < "$CF"); IMGS1=$(grep -c '^ *image:' "$CF")
grep -n '^ *image:' "$CF" > "$AFT"
DIFFN=$(diff "$BEF" "$AFT" | grep -c '^[<>]')
rm -f "$BEF" "$AFT"
say "줄 수 $L0 → $L1 · image: 줄 $IMGS0 → $IMGS1 · 달라진 image: 줄 $((DIFFN / 2))개"
[ "$L1" = "$L0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
[ "$IMGS1" = "$IMGS0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
# 🔴 **남의 image: 줄을 건드리면 안 된다.** --go 는 둘(app-as·tools-as),
#    --rollback 은 하나(app-as)만 달라져야 한다.
if [ "$MODE" = go ]; then WANT_DIFF=2; else WANT_DIFF=1; fi
[ "$((DIFFN / 2))" = "$WANT_DIFF" ] && ok "image: 줄이 꼭 ${WANT_DIFF}개만 달라졌다 (우리 것)" \
  || bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — ${WANT_DIFF}개를 기대했다. 남의 것을 건드렸을 수 있다"
dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 6. app-as 만 다시 띄운다 ──────────────────────────────────────────
#  🔴 tools-as 는 profiles: [tools] 라 up -d 로 띄우지 않는다. 태그만 고쳐
#     두면 다음에 run --rm 으로 부를 때 새 이미지를 쓴다.
printf '\n== 6. app-as 를 다시 띄운다\n'
printf '%s\n' "🔴 --no-deps 다 — app-as 하나만 갈아 끼운다. 나머지 아홉과 DB 둘은 안 건드린다."
for r in $(rows); do
  CN=$(fld "$r" 3)
  say "$CN 지금: $("$DOCKER" inspect -f '{{.Id}}' "$CN" 2>/dev/null | cut -c1-12)"
done
# 🔵 DB 둘의 시작 시각을 적어 둔다 — 교체 뒤에 **그대로인지** 본다.
DBSTART=""
for c in $KEEP_DB; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
  DBSTART="$DBSTART $c=$s"; say "$c 시작 $s"
done
TSEC=$SECONDS
SVCS=$(for r in $(rows); do printf '%s ' "$(fld "$r" 2)"; done)
dc up -d --no-deps $SVCS 2>&1 | sed 's/^/    /'
say "뜨는 것을 20초 기다린다…"; sleep 20
say "정지 구간 $((SECONDS - TSEC))초"

# ── 7. 값으로 확인 ───────────────────────────────────────────────────
printf '\n== 7. 값으로 확인\n'
for r in $(rows); do
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5); PORT=$(fld "$r" 7)
  if [ "$MODE" = rollback ]; then TO=$OLD; else TO=$NEW; fi
  ST=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  HL=$("$DOCKER" inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}없음{{end}}' "$CN" 2>/dev/null)
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$PORT/" 2>/dev/null)
  say "$CN — ${ST:-?} · 건강 ${HL:-?} · 이미지 ${RUN:-?} · 127.0.0.1:$PORT → ${CODE:-없음}"
  [ "$ST" = running ] && ok "$CN 가 돈다" || bad "$CN 가 안 돈다 (${ST:-못 찾음})"
  [ "$RUN" = "$TO" ] && ok "$CN 가 $TO 로 돈다" || bad "$CN 가 $RUN 로 돈다"
  printf '%s' "$CODE" | grep -qE '200|30[127]' && ok "$CN 가 응답한다 ($CODE)" || bad "$CN 응답이 ${CODE:-없음}"
done

# 🔴 A/S DB — 마이그레이션 수가 **여전히** 그대로인가 (이 배포는 DB 를 안 건드린다)
MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
say "A/S 마이그레이션 ${MIG_AS0:-?} -> ${MIG_AS1:-?} (그대로여야 한다)"
[ "${MIG_AS1:-x}" = "$AS_KEEP" ] && ok "A/S 가 $AS_KEEP 그대로다 (DB 를 안 건드렸다)" \
  || bad "🔴 A/S 가 ${MIG_AS1:-?} 다 — $AS_KEEP 그대로여야 한다. 이 배포가 DB 를 건드렸다면 전제가 틀렸다"

# 🔴 도구 태그가 제대로 섰는지 + 이미지 안이 온전한지 다시 센다
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  # 🔵 --go 도 --rollback 도 도구 기대값은 **$TOOLS_NEW 로 같다** — 되돌려도
  #    도구는 :6 그대로 둔다(머리말의 판단).
  [ "$TCUR" = "$TOOLS_NEW" ] && ok "$AS_TOOLS_SVC 가 $TOOLS_NEW 다" \
    || bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $TOOLS_NEW 를 기대했다"
  "$DOCKER" image inspect "$TCUR" >/dev/null 2>&1 && ok "$TCUR 이미지가 NAS 에 있다" \
    || bad "$TCUR 이미지가 NAS 에 없다 — 다음에 부를 때 못 쓴다"
fi
if [ "$MODE" = go ]; then tools_inside_check; fi
# 🔴 42번에서 넣은 검사다 — 연락서 폴더가 줄만 있는 게 아니라 실제로 열리는지
#    센다. 🔵 **이번 판도 백필을 안 돌리므로 여기서 ✗ 가 나도 이 배포의 일은
#    끝난 것이다** — 다음 이식 때 막히지 않게 지금 재 두는 것이다.
if [ "$MODE" = go ]; then kyosan_folder_check; fi

# 🔴 **안 건드린 아홉이 그대로 도는지** 센다 — 「옆으로 안 샜다」는 증거다.
#    🔴 dss-inventory 가 이 안에 있다 — 이번 판은 그 상자가 멈추면 **[사용부품]
#       칸이 모든 건에서 막힌다**(머리말 ①-보조). 바로 아래에서 실제로 물어본다.
printf '\n    ── 안 건드린 아홉 (그대로여야 한다 — dss-inventory 도 포함)\n'
for c in $KEEP_BOXES; do
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
  [ "$s" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
done

# 🔴 **「상자가 돈다」와 「물어보니 답한다」는 다른 말이다.** 바로 위는 앞의 것이고
#    이 줄이 뒤의 것이다 — 설정이 빠졌거나 토큰이 안 맞으면 상자는 멀쩡히 돌면서
#    [사용부품] 칸만 막힌다. 🔴 --go 에서는 ✗ 로 센다(사람이 실제로 막혀 있다).
if [ "$MODE" = go ]; then inventory_gateway_check strict; fi

printf '\n    ── DB 둘이 안 멈췄는가 (시작 시각이 그대로여야 한다)\n'
for c in $KEEP_DB; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
  b=$(printf '%s' "$DBSTART" | tr ' ' '\n' | sed -n "s/^$c=//p")
  printf '      %-14s %s\n' "$c" "${s:-없음}"
  [ "${s:-x}" = "${b:-y}" ] && ok "$c 가 안 멈췄다" || bad "🔴 $c 가 다시 떴다 (${b:-?} -> ${s:-?})"
done

printf '\n    ── 최근 로그 (12줄)\n'
for r in $(rows); do
  CN=$(fld "$r" 3)
  printf '      ── %s\n' "$CN"
  "$DOCKER" logs --since 3m "$CN" 2>&1 | tail -12 | sed 's/^/        /'
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
if [ "$FAIL" = 0 ]; then
  printf '%s\n' "✅ 기계로 잴 수 있는 것은 전부 통과했다."
  printf '%s\n' "  compose 사본: $BK"
  printf '%s\n' "  로그: $LOG"
  printf '%s\n' ""
  printf '%s\n' "🔵 **백필은 다시 돌리지 않는다.** 44번과 같다 — 까닭:"
  printf '%s\n' "   · 백필은 2026-10-29 새벽에 283건이 끝났다"
  printf '%s\n' "     (회차 e8c3c890-b1ba-42ec-a555-737609ad2e38 · 사용 부품 978줄이 품번으로 들어가 있다)."
  printf '%s\n' "   · 이번 판은 **화면 둘과 문지기 하나**를 바꾼다. **DB 에 들어간 값과 무관하다.**"
  printf '%s\n' "   🔴 그러니 돌려도 바뀔 줄이 없다. 괜히 운영 자료를 건드릴 일만 만든다."
  printf '%s\n' "   🔵 백필이 다시 필요해지는 때는 **연락서를 읽는 규칙**이 바뀌는 판이다."
  printf '%s\n' "      그때 칠 명령은 /volume1/dss/setup/43-deploy.sh 꼬리말에 그대로 있다."
  printf '%s\n' ""
  printf '%s\n' "🔴 **마지막은 눈이다** — 쓰는 분이 볼 곳 **둘**:"
  printf '%s\n' ""
  printf '%s\n' "  ㄱ) **수리 건 상세 → [사용부품]**  🔴 여기가 이번 판에서 제일 조심할 자리다."
  printf '%s\n' "     · **반출된 부품이 있는 건은 칸이 잠긴다** (새 동작). 「이 건의 부품은 부품"
  printf '%s\n' "       요청(반출) 이력에서 잡힙니다…」가 뜬다."
  printf '%s\n' "     · 🔵 **반려·취소만 된 건은 그대로 열린다.** 두 가지를 꼭 갈라서 보세요 —"
  printf '%s\n' "       둘이 같이 막히면 그것이 결함이다."
  printf '%s\n' "     · 🔴 재고 관리가 멈추면 「재고 관리에 물어볼 수 없어 지금은 사용 부품을 적을"
  printf '%s\n' "       수 없습니다.」가 뜬다. 위 7절이 **물어보니 답하는지**까지 쟀으니 지금은"
  printf '%s\n' "       열려 있어야 한다."
  printf '%s\n' ""
  printf '%s\n' "  ㄴ) **제품 모델 상세 → [A/S 이력]**"
  printf '%s\n' "     · 년·월 드롭다운 둘. **네 그래프와 접수 건 목록이 함께** 걸린다(인수일 기준)."
  printf '%s\n' "     · [고장 부품]이 **사용 부품과 반출 확인된 부품까지** 센다."
  printf '%s\n' "     · **조각을 누르면** 그 부품의 재고가 **소유구분별로** 펼쳐진다"
  printf '%s\n' "       (KYOSAN 과 DSS 가 각각 한 줄 — 합치지 않는다)."
  printf '%s\n' ""
  printf '%s\n' "  🔵 **기대치 — 이름이 안 붙고 품번만 보이는 줄이 많다. 결함이 아니다.**"
  printf '%s\n' "     재고 관리 부품 **319줄 중 고객사 품명이 적힌 줄은 27개뿐**이다(2026-10-29 실측)."
  printf '%s\n' "     🔵 재고 관리에서 고객사 품명을 채우면 A/S 는 아무것도 안 고쳐도 저절로 붙는다."
  printf '%s\n' "  🔵 저장된 글자는 안 바뀐다 — 이 배포는 DB 를 한 줄도 건드리지 않았다."
  printf '%s\n' "  🔵 연락서 이식 규칙(43번이 올린 판본 C 칸 차례 · 겹친 줄 수량)은 그대로다."
  printf '%s\n' ""
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (app-as 만 되돌린다. 도구는 :6 그대로"
  printf '%s\n' "               둔다 — DB 를 안 건드렸으니 자료 손실이 없다)"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
  printf '%s\n' "  🔵 ✗ 가 **재고 관리 통로** 하나뿐이라면 되돌리기 전에 설정을 먼저 보세요 —"
  printf '%s\n' "     INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN (env/as.env). 그 둘을 고치고"
  printf '%s\n' "     app-as 를 다시 띄우면 [사용부품] 칸이 풀린다. 되돌려도 같은 설정 문제는 남는다"
  printf '%s\n' "     (옛 판은 그 설정 없이도 칸이 열려 있었을 뿐이다)."
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
