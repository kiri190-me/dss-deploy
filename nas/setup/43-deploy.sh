#!/bin/bash
# dss-deploy/nas/setup/43-deploy.sh — 마흔째 배포 (2026-10-29)
#
# 🔴 NAS 에서 돈다. DSM 터미널은 긴 명령을 잘라 먹으므로 **파일로 올려** 돌린다.
#    md5 를 맞춘다:  md5sum /volume1/dss/setup/43-deploy.sh
#
# ── 사람이 실행한다 ───────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/43-deploy.sh            ← 읽기만 한다
#   (NAS)         bash /volume1/dss/setup/43-deploy.sh --preload
#   (NAS)         bash /volume1/dss/setup/43-deploy.sh --go       ⏱ 정지 창
#
# ── 갈아 끼우는 것 — **저장소 하나, 태그 둘** ──────────────────────────
#     ① A/S 앱   dss-as:3.5        → **dss-as:3.6**        커밋 1
#     ② A/S 도구 dss-as-tools:3    → **dss-as-tools:4**    커밋 1
#
#   🔴 **마이그레이션이 없다.** A/S 의 drizzle/ 이 기준 SHA(a728418) 이후 0건이다.
#      그래서 이 파일에는 **--migrate 모드가 없다** — DB 를 건드리는 단계가 한
#      군데도 없다.
#   🔵 **나머지 아홉은 안 건드린다** — 통합 로그인 · PO · 재고 · 게시판 · 계측기 ·
#      개선요청 · RF 이슈관리 · 휴가 · 통합 승인함 아홉은 마지막 커밋이 전부
#      2026-10-27 이전이다. 서른아홉째 배포(10-29) 뒤로 한 줄도 안 쌓였다
#      (2026-10-29 실측).
#
# ── 이 배포가 하는 일 — **연락서를 읽는 규칙 둘** (커밋 341be31 하나) ──
#   어제(서른아홉째)까지 연락서의 사용 부품은 **품번**으로 들어가게 바뀌었다.
#   이번 판은 그 품번을 **어느 칸에서 집는가**를 고치고, 겹친 줄에서 수량이
#   사라지던 것을 막는다:
#     ① **판본 C 는 오른쪽 칸(D열)이 품번이다.** 머리글이 '部品名 / 型式'(B열)과
#        '仕様書番号 / 型式'(D열)로 둘 다 型式 을 품은 겹뜻이라 2026-10-28 에는
#        「가를 근거가 없다」며 왼쪽을 먼저 두었다. 2026-10-29 운영 실측으로
#        뒤집었다 — 왼쪽은 언제나 사람이 읽는 설명이고 오른쪽이 품번이다.
#        🔴 그래서 **품번이 다른 별개 부품 둘이 설명이 같다는 이유로 한 줄로
#        뭉개지고** 있었다. 사용자가 연 운영 연락서 한 장은 시트에 10줄·수량 합
#        12 인데 사용 부품 칸에 6줄·수량 합 11 이 들어가 있었다.
#     ② **같은 갈래에 같은 이름이 두 줄이면 수량을 더한다.** 2026-09-22 부터 그
#        자리는 **첫 줄 수량만** 쓰고 나머지를 버렸고, 버리는 쪽에는 근거가 한
#        줄도 적혀 있지 않았다. 형제 경로(추정수리내용 쪽)는 그때부터 더하고
#        있었다. **판본을 가리지 않는 변경이다.**
#   🔵 42번이 올린 화면 쪽 변경(사용 부품을 「고객사 품명 (품번)」으로 보여 주는
#      것)은 **그대로다** — 이번 판은 그 파일을 건드리지 않는다.
#
# ── 🔴 A/S 도구를 왜 올리는가 — 이번엔 **도구 파일이 안 바뀌었는데도** 올린다 ──
#   🔵 **서른여섯째**: 「마이그레이션 0건이니 도구는 안 굽는다」 → **틀렸다**
#      (비상구 둘이 못 쓰는 채였다).
#   🔵 **서른일곱째**: 「그 도구가 실제로 부르는 명령이 바뀌었는가」로 판정해
#      안 구웠다 → **맞았다**(db:migrate·db:preflight 둘 다 볼륨만 읽는다).
#   🔵 **서른여덟째**: 그 잣대로는 「**늘어난** 명령」이 안 걸렸다. 안 올렸으면
#      'npm error Missing script' 가 날 자리였다.
#   🔵 **서른아홉째**: package.json 이 0줄인데 'scripts/' 에 백필 도구가 새로
#      생겼다. 그래서 잣대를 「tools 스테이지가 담는 것 전부」로 넓혀 적었다.
#   🔴 **마흔째(이번)에는 그 'scripts/' 의 도구 파일조차 한 글자도 안 바뀌었다.**
#      그런데도 올린다 — 바뀐 것이 **그 도구가 부르는 코드**이기 때문이다:
#        src/lib/kyosan/parts-detail-sheet.ts   연락서에서 품번을 읽는 칸 차례
#        src/lib/kyosan/report-preview.ts       겹친 줄의 수량을 더한다
#      백필 도구는 이 둘을 정적 import 로 끌어 쓴다
#      (backfill-kyosan-used-parts.ts → scripts/lib/kyosan-used-parts-backfill.ts
#       92줄 import · 376줄에서 buildKyosanPreviewParts 호출 → readKyosanReport
#       를 거쳐 parts-detail-sheet.ts).
#      🔴 **도구를 안 올리면 백필이 옛 규칙으로 돌아 같은 결함을 또 만든다.**
#         이것이 이번에 도구를 올리는 유일하고 충분한 까닭이다.
#   🔵 **이번 판의 잣대** — 서른아홉째에 넓혀 둔 그것을 그대로 쓴다:
#        git diff a728418..HEAD -- scripts/ src/ package.json drizzle.config.ts tsconfig.json vendor/
#      (43-build.sh 5절이 그 셈을 하고, 이 파일 3절이 결과물의 **안**을 다시 센다.)
#
# ── 🔴 백필 돌리는 법 — **배포가 끝난 뒤, 사람이 손으로** ──────────────
#   🔴 이 스크립트는 백필을 **부르지 않는다.** 아래는 쓰는 분이 칠 명령이다.
#   🔴 **이번 판에서는 반드시 다시 돌려야 한다.** 어제 올린 도구는 옛 차례로
#      돌았다 — 그때 바꾼 줄에도 **판본 C 의 설명 글자**가 들어갔고, 겹친 줄의
#      수량은 버려진 채다. 새 도구로 **계획부터 다시** 밟는다.
#
#   ① 계획만 본다 — 🔴 '--apply' 가 없으면 DB 에 한 글자도 안 쓴다
#     cd /volume1/dss/deploy
#     /usr/local/bin/docker compose -f docker-compose.nas.yml --env-file .env.nas \
#       --profile tools run --rm tools-as \
#       node --conditions=react-server --import tsx \
#       scripts/backfill-kyosan-used-parts.ts --dir /kyosan-src --dir /kyosan-converted
#
#   ② 화면에 나온 「N줄 → M줄」을 **사람이 읽고 승인한 뒤에만**
#     cd /volume1/dss/deploy
#     /usr/local/bin/docker compose -f docker-compose.nas.yml --env-file .env.nas \
#       --profile tools run --rm tools-as \
#       node --conditions=react-server --import tsx \
#       scripts/backfill-kyosan-used-parts.ts --dir /kyosan-src --dir /kyosan-converted --apply
#
#   🔴 **어제 잰 수는 낡았다.** 2026-10-29 서른아홉째 배포 뒤에 잰
#      「바꿀 수 있음 253건 · 813줄 → 922줄」은 **옛 차례·옛 수량 규칙으로 센 수**다.
#      이번 도구로 다시 계획을 돌리면 그 수가 달라진다 — 판본 C 의 줄이 설명에서
#      품번으로 바뀌고, 겹쳐 뭉개지던 줄이 갈라지고, 버려지던 수량이 살아나기
#      때문이다. 🔵 **그 수가 달라지는 것이, 새 차례가 실제로 돈다는 유일한
#      증거다** — 이미지 안에서는 못 잰다(DB 도 연락서 파일도 있어야 한다).
#      🔴 그러니 어제 수와 같게 나오면 **새 이미지로 안 돌고 있는 것**을 먼저
#      의심하세요(compose 의 tools-as 태그가 dss-as-tools:4 인지).
#   🔴 **폴더를 둘 다 줘야 한다.** 한쪽만 주면 나머지 연락서가 조용히 「못 바꿈」으로
#      떨어진다 — '/kyosan-converted' 는 개발 PC 에서 .xls 를 .xlsm 로 바꾼 143장이다.
#   🔵 '--out' 은 **적지 않는다.** 기록 JSON 에는 연락서 **파일 이름**(모델·S/N 이
#      섞일 수 있다)이 들어가고, 그 도구는 저장소 안을 가리키면 거부한다. 쓰려면
#      /volume1/dss 밑에 폴더를 먼저 만들어 'run -v' 로 붙여야 하는데 **이번 배포
#      범위 밖**이다. 자세한 사유가 필요하면 그때 폴더를 만든다.
#   🔵 '--conditions=react-server' 를 빼지 마세요 — 재고관리 통로·조회 쪽의
#      'server-only' 가 안 풀려 그 자리에서 죽는다.
#
# ── 🔴 연락서 폴더 검사 — 42번에서 넣었고 **그대로 둔다** ──────────────
#   41번이 compose 에서 재던 볼륨은 'as-migrations' 한 줄뿐이었다. 그런데 백필은
#   **연락서 원본 폴더를 읽어야** 돈다. 개발 PC 쪽 compose 사본은 운영보다 여러
#   판 낡아서 「사본에 있으니 운영에도 있겠지」가 성립하지 않는다 — 그래서 운영
#   파일에서 직접 센다. 이번 판은 백필을 **반드시 다시 돌려야 하므로** 이 검사가
#   지난 판보다 더 쓸모가 있다.
#     · 1절 : tools-as 블록에 '/kyosan-src' · '/kyosan-converted' 줄이 있나
#     · 7절 : --go 끝에 **폴더가 실제로 열리는지** 결과를 센다(줄이 아니라 결과)
#   🔴 **없어도 배포를 막지 않는다.** 앱·도구 교체는 그 폴더와 무관하다. 그래서
#      1절에서는 ✗(FAIL) 가 아니라 **?** 로 센다 — ✗ 는 4·5절의 문을 닫아
#      멀쩡한 교체까지 막는다. 대신 「이대로면 백필이 못 돈다」를 크게 찍는다.
#
# ── 🔴 이번 배포에서 **동작이 바뀌는 자리** — 쓰는 분이 눈으로 볼 곳 ────
#   ① **연락서를 새로 이식할 때** 판본 C('仕様書番号 / 型式' 머리글이 있는 장)의
#      사용 부품 이름이 **D열의 품번**으로 들어간다. 전에는 B열(설명)을 먼저 집었다.
#   ② **같은 갈래에 같은 이름이 여러 줄이면 수량을 더한다** — 판본을 가리지 않는다.
#      전에는 첫 줄 수량만 쓰고 나머지를 버렸다.
#   ③ 🔵 **판본 A·B 는 닿지 않는다.** 그 둘은 홑뜻 '型式'·'仕様書番号' 를 쓰고
#      예전부터 1·2 순위라 자리가 그대로다.
#   ④ 🔵 **'部品名' 이 비고 규격만 있는 줄(실측 11줄)은 손해를 안 본다** — 고친
#      차례가 D열을 **먼저** 보기 때문이다. 바뀌는 것은 둘 다 찬 줄에서 어느 쪽이
#      이기는가 하나뿐이다.
#   ⑤ 🔴 **이미 들어간 줄은 이 배포만으로 안 바뀐다.** 위 「백필 돌리는 법」을
#      계획부터 다시 밟아야 바뀐다.
#
# ── 🔴 ①-보조: 재고 관리가 꺼져 있으면 품명이 안 붙는다 ────────────────
#   42번이 올린 화면 쪽 변경(「고객사 품명 (품번)」)은 재고 관리의 부품 통로에서
#   품명을 얻는다. 그 상자가 멈춰 있으면 화면이 깨지지 않고 **품번 그대로**
#   보인다 — 조용한 쪽으로 떨어지므로 신고가 안 들어온다. 🔵 아래 7절이 재고관리
#   컨테이너가 계속 도는지(KEEP_BOXES) 재지만, **배포 직후에는 쓰는 분이 재고관리
#   화면이 떠 있는지 직접 한 번 더 보는 것이 안전하다.**
#
# ── 🔴 42번(지난 판)과 다른 것 ─────────────────────────────────────────
#   ① 모양은 같다 — 저장소 하나(A/S)에 **태그는 둘**(앱 하나 + 도구 하나).
#   ② 🔴 **도구 이미지 안을 재는 단계가 하나 늘었다.** 42번은 넷으로 셌다
#      (① /app/package.json ② 백필 도구 파일 셋 ③ tsx ④ 값으로 받아 본다).
#      🔵 **그 넷을 하나도 빼지 않았다** — 백필 도구 파일 셋은 이번에도 이미지에
#      있어야 하고 그 검사는 그대로 ✓ 가 난다. 🔴 거기에 **이번 판 전용으로
#      ③ 을 끼워 넣었다**: 이번에 고친 파일 둘이 이미지 안에 들어갔는가
#      (/app/src/lib/kyosan/parts-detail-sheet.ts · report-preview.ts). 하나라도
#      없으면 src/ 가 안 담긴 것이고, 그러면 **백필이 옛 규칙으로 돈다** — 오류
#      없이, 같은 결함을 다시 만들면서. 42번의 ③④ 는 ④⑤ 로 밀렸다.
#   ③ 🔵 **연락서 폴더 검사는 42번 것 그대로다.** 이번 판은 백필을 반드시 다시
#      돌려야 하므로 그 검사가 더 쓸모가 있다.
#   ④ 🔴 **다시 띄우는 것은 app-as 하나뿐이다.** tools-as 는 'profiles: [tools]'
#      라 평소에 뜨지 않는 서비스다 — compose 의 태그만 새 것으로 고쳐 두면
#      다음에 'run --rm tools-as' 로 부를 때 새 이미지를 쓴다. **up -d 로
#      띄우지 않는다** — 띄우려 하면 프로필이 안 걸려 있어 compose 가 그 서비스를
#      모르는 것으로 다룬다.
#   ⑤ 🔵 **--rollback 은 앱만 되돌린다.** 도구는 :4 그대로 둔다 — 39·41·42번과
#      같은 판단이다(판에 매이지 않고, 새 도구가 있는 편이 낫다. 되돌릴 일이
#      생겨도 이 도구는 '--apply' 를 주지 않으면 DB 에 한 글자도 안 쓴다).
#   ⑥ 🔵 RF_Service_System 의 Dockerfile 은 tools 스테이지를 runner **앞에**
#      둔다 — --target 없이 구우면 마지막 스테이지(runner)가 기본값이 된다.
#      이 함정은 43-build.sh 쪽 이야기지만, 그 결과(올바른 tools 이미지)가
#      맞게 왔는지는 이 파일의 3절이 다시 센다.
#
# ── 🔴 개발 PC → NAS 로 올릴 것 — **셋** (마이그레이션 묶음이 없다) ─────
#   ㄱ) 이미지 tar **둘** → /volume1/dss/images/
#        dss-as-3.6.tar · dss-as-tools-4.tar
#   ㄴ) 이 파일 → /volume1/dss/setup/
#
#   (개발 PC · PowerShell)
#     cd C:\Users\희만\Desktop\Development\_images-40
#     scp -O dss-as-3.6.tar dss-as-tools-4.tar dss-nas:/volume1/dss/images/
#     cd C:\Users\희만\Desktop\Development
#     scp -O dss-deploy\nas\setup\43-deploy.sh dss-nas:/volume1/dss/setup/
#     Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\43-deploy.sh
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#   🔴 tar 에 드라이브 문자(C:)를 주지 마세요 — 원격 호스트로 읽습니다.
#
# ── 모드 넷 ───────────────────────────────────────────────────────────
#   (기본)   --check      아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --preload             tar 둘을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --go                  compose 의 image: 줄 둘(app-as·tools-as)을 바꾸고
#                         app-as 만 다시 띄운다
#   --rollback            app-as 만 옛 판으로 되돌린다 (도구는 :4 그대로)
#
#   🔴 차례:  --check → --preload → --check → --go
#
# ── 🔴 --check 도 「아무것도 안 한다」는 아니다 ───────────────────────
#   A/S DB 에 **select** 를 한 번 보낸다(마이그레이션 수가 그대로인지 — 바꾸는
#   문장은 없다). 앱의 바깥 주소에 GET 을 한 번 보낸다. 도구 이미지가 이미
#   실려 있으면 **안을 보려고 컨테이너를 잠깐 띄웠다 지운다**(docker run --rm,
#   DB 에는 안 닿는다 — DATABASE_URL 을 안 주고 부른다).
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
#   이번 판에는 새로 필요한 설정 이름이 없다.
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v40-$STAMP

# ══ 이번에 다시 띄우는 것 — 앱 하나뿐이다 ═════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
SITES='
as|app-as|dss-as|dss-as:3.6|dss-as:3.5|dss-as-3.6.tar|13000
'
# ══ 🔴 A/S 도구 — **이번에 갈아 끼운다.** up -d 로 다시 띄우지 않는다 ═══
#   (profiles: [tools] 라 평소에 뜨지 않는다. compose 의 태그만 고치면
#    다음에 run --rm tools-as 로 부를 때 새 이미지를 쓴다.)
AS_TOOLS_SVC=tools-as
TOOLS_OLD=dss-as-tools:3
TOOLS_NEW=dss-as-tools:4
IMG_MIGDIR=/app/drizzle
MIGDIR=$D/as-migrations

# ══ 🔴 연락서 원본 폴더 — 백필이 읽어야 하는 자리 ════════════════════
#   🔵 기대값의 출처: 2026-10-28 실측 673장 · 143장. 늘기만 하는 폴더라 아래
#      바닥값으로 잰다. 🔴 **0 이면 볼륨 줄은 있는데 안 열리는 것**이고, 그것이
#      제일 조용한 실패다.
KYO_SRC=/kyosan-src;        KYO_SRC_MIN=600
KYO_CONV=/kyosan-converted; KYO_CONV_MIN=100

# ══ 🔴 tar 둘의 지문 — [배포본] 43-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   ✅ **채웠다** — 2026-10-29 02:00 에 43-build.sh --go 가 굽고 **바로 잰 값**이다.
#      (비어 있으면 3절이 **? 로 센다** — 「옮기다 깨진 것」은 잡지만 「개발 PC 에서
#      구운 그것이 맞나」는 못 본다.)
#   🔵 이름만이라도 적어 두는 까닭: 줄이 아예 없으면 4절(--preload)이 **아무것도
#      안 싣고 조용히 끝난다.** 이름이 있으면 싣기는 제대로 된다.
TARS='
dss-as-3.6.tar|132373504|fe1214f5b18a733da0b8f4a8bb6916a9|sha256:b35ada8a18257c9c6d29850bc2cc02824f70ce9cc258474ffc72b5f9af4c7233
dss-as-tools-4.tar|223610368|6c602d9e82e2133785a7f4ab03ad686c|sha256:b20f5a849e64998b603af173024946e7997fe1e4eee6c309545ddaf4f0657185
'
tar2tag() {
  case "$1" in
    dss-as-3.6.tar)      printf 'dss-as:3.6' ;;
    dss-as-tools-4.tar)  printf 'dss-as-tools:4' ;;
  esac
}

# ══ 🔴 A/S — DB 는 **그대로여야** 한다(마이그레이션 0건) ═════════════
AS_BOX=dss-pg-app; AS_DB=dss_as; AS_KEEP=121   # [저장소] 43-build.sh 4절과 같다
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
LOG="$D/setup/logs/43-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "마흔째 배포 — A/S 앱 · A/S 도구   $(date '+%Y-%m-%d %H:%M:%S')"
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

# ══ 🔴 A/S 도구 이미지 **안**을 센다 — 겉이 아니라 결과 ══════════════
#   🔴 --target tools 를 빠뜨렸으면 runner 가 구워지고, 그 안에는 scripts/ 도
#      package.json 도 없다. 이미지는 멀쩡히 실리고 오류가 안 난다. 증상은
#      **쓸 일이 생긴 날**의 「모듈을 못 찾는다」 한 줄뿐이다. 그래서 여기서 센다.
#   🔴 **42번보다 단계가 하나 많다(③).** 이번 판에서 바뀐 것은 도구 파일이 아니라
#      **도구가 부르는 코드**(src/lib/kyosan/ 둘)다. 그 둘이 이미지에 안 담기면
#      도구는 멀쩡히 돌면서 **옛 규칙으로** 백필한다 — 오류가 한 줄도 안 난다.
#   🔵 ④ 는 42번 그대로다. 백필을 **직접** 부르되 **DATABASE_URL 을 안 준다** —
#      그 파일이 1줄에서 './load-env' 를, 9줄에서 '../src/lib/db/connection' 을
#      정적 import 하고, connection.ts 가 모듈 맨 위에서 동기적으로 던진다.
#      인자를 안 줘도 파싱까지 안 가고 import 에서 막힌다.
#      **DB 에는 한 글자도 안 닿는다.**
#   🔴 ④ 가 말해 주는 것은 **import 가 선다**까지다. 「새 차례가 실제로 도는가」는
#      DB 도 연락서 파일도 있어야 해서 여기서는 못 잰다 — 배포 뒤 백필 계획을
#      다시 돌려 수가 달라지는 것으로 확인한다(이 파일 꼬리말).
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
  # ③ 🔴 **이번 판에 끼워 넣은 단계.** 이번에 고친 파일 둘이 이미지 안에 있는가.
  #    없으면 src/ 가 안 담긴 것이고, 그러면 백필이 **옛 규칙으로 돈다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/src/lib/kyosan/parts-detail-sheet.ts /app/src/lib/kyosan/report-preview.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "2" ] && ok "이번에 고친 파일 둘이 다 들어 있다 (백필이 새 규칙으로 돈다)" \
    || { bad "🔴 이번에 고친 파일이 ${got:-0}/2 개다 — src/ 가 온전히 안 담겼다. 백필이 옛 규칙으로 돈다"; doubt; }
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
    say "   백필을 돌릴 때만 필요한 폴더다. compose 의 $AS_TOOLS_SVC 볼륨을"
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
  # 🔴 42번에서 넣은 검사다. 백필은 연락서 원본 폴더를 읽어야 돈다. 개발 PC 쪽
  #    compose 사본은 운영보다 여러 판 낡아서 「사본에 있으니 운영에도 있겠지」가
  #    성립하지 않는다 — 운영 파일에서 센다. 🔴 이번 판은 백필을 **반드시 다시
  #    돌려야 하므로** 이 줄이 지난 판보다 더 쓸모가 있다.
  #    🔵 **없어도 교체를 막지 않는다.** 앱·도구 교체는 이 폴더와 무관하다.
  #       그래서 ✗ 가 아니라 ? 로 센다 — ✗ 는 4·5절의 문을 닫아 멀쩡한 교체까지
  #       막는다. 대신 「이대로면 백필이 못 돈다」를 크게 찍는다.
  for kv in "$KYO_SRC" "$KYO_CONV"; do
    if svc_block "$AS_TOOLS_SVC" | grep -q "$kv"; then
      ok "$AS_TOOLS_SVC 에 $kv 볼륨 줄이 있다 (백필이 읽을 자리)"
    else
      hm "$AS_TOOLS_SVC 에 $kv 볼륨 줄이 **없다** — 🔵 교체는 막지 않는다"
      say "🔴 **이대로면 백필이 못 돈다.** compose 의 $AS_TOOLS_SVC 에 그 줄을 먼저 넣으세요."
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
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 43-build.sh --go 가 끝에 찍어 주는"
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
#     되돌린다 — 도구는 :4 그대로 둔다(39·41·42번과 같은 판단).
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
  say "🔵 $AS_TOOLS_SVC 는 이번 모드($MODE)에서 **안 건드린다** — :4 그대로 둔다"
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
  #    도구는 :4 그대로 둔다(머리말의 판단).
  [ "$TCUR" = "$TOOLS_NEW" ] && ok "$AS_TOOLS_SVC 가 $TOOLS_NEW 다" \
    || bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $TOOLS_NEW 를 기대했다"
  "$DOCKER" image inspect "$TCUR" >/dev/null 2>&1 && ok "$TCUR 이미지가 NAS 에 있다" \
    || bad "$TCUR 이미지가 NAS 에 없다 — 다음에 부를 때 못 쓴다"
fi
if [ "$MODE" = go ]; then tools_inside_check; fi
# 🔴 42번에서 넣은 검사다 — 연락서 폴더가 줄만 있는 게 아니라 실제로 열리는지
#    센다. 🔴 이번 판은 백필을 **반드시 다시 돌려야** 하므로, 여기서 ✗ 가 나면
#    배포는 끝났어도 **일이 안 끝난 것**이다.
if [ "$MODE" = go ]; then kyosan_folder_check; fi

# 🔴 **안 건드린 아홉이 그대로 도는지** 센다 — 「옆으로 안 샜다」는 증거다.
#    🔵 dss-inventory 가 이 안에 있다 — 사용 부품의 「고객사 품명」이 그 상자에서
#       온다(머리말 ①-보조). 멈춰 있으면 화면이 품번만 보여 준다.
printf '\n    ── 안 건드린 아홉 (그대로여야 한다 — dss-inventory 도 포함)\n'
for c in $KEEP_BOXES; do
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
  [ "$s" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
done
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
  printf '%s\n' "🔴 **마지막은 눈이다** — 쓰는 분이 볼 곳(머리말의 동작 변경):"
  printf '%s\n' "     · 연락서를 **새로 이식**해 보고, 판본 C(머리글이 仕様書番号 / 型式 인 장)의"
  printf '%s\n' "       사용 부품 이름이 **오른쪽 칸의 품번**으로 들어가는가"
  printf '%s\n' "     · 같은 이름이 여러 줄인 장에서 **수량이 더해지는가** (전에는 첫 줄만 썼다)"
  printf '%s\n' "     · 🔵 판본 A·B 는 닿지 않는다 — 그 둘은 홑뜻 型式·仕様書番号 를 쓴다"
  printf '%s\n' "     · 🔵 42번이 올린 화면(「고객사 품명 (품번)」)은 그대로다"
  printf '%s\n' "     · 재고 관리 화면이 떠 있는가 (품명이 거기서 온다)"
  printf '%s\n' "     · 🔴 **이미 들어간 줄은 이 배포만으로 안 바뀐다** — 백필을 다시 돌려야 한다"
  printf '%s\n' ""
  printf '%s\n' "  🔴 **이번 판은 백필을 반드시 다시 돌린다.** 어제 올린 도구는 옛 차례로"
  printf '%s\n' "     돌았다 — 그때 바꾼 줄에도 판본 C 의 설명 글자가 들어갔고, 겹친 줄의"
  printf '%s\n' "     수량은 버려진 채다."
  printf '%s\n' "  🔵 ① 계획부터. **--apply 가 없으면 DB 에 한 글자도 안 쓴다**:"
  printf '%s\n' "    cd /volume1/dss/deploy"
  printf '%s\n' "    $DOCKER compose -f docker-compose.nas.yml --env-file .env.nas \\"
  printf '%s\n' "      --profile tools run --rm tools-as \\"
  printf '%s\n' "      node --conditions=react-server --import tsx \\"
  printf '%s\n' "      scripts/backfill-kyosan-used-parts.ts --dir $KYO_SRC --dir $KYO_CONV"
  printf '%s\n' ""
  printf '%s\n' "  🔵 ② 「N줄 → M줄」을 사람이 읽고 승인한 뒤에만 --apply 를 덧붙인다:"
  printf '%s\n' "      … scripts/backfill-kyosan-used-parts.ts --dir $KYO_SRC --dir $KYO_CONV --apply"
  printf '%s\n' ""
  printf '%s\n' "  🔴 **어제 잰 수는 낡았다** — 2026-10-29 서른아홉째 배포 뒤의"
  printf '%s\n' "     「바꿀 수 있음 253건 · 813줄 → 922줄」은 **옛 차례·옛 수량 규칙**의 수다."
  printf '%s\n' "     이번 도구로 계획을 다시 돌리면 그 수가 달라진다 — 판본 C 의 줄이 설명에서"
  printf '%s\n' "     품번으로 바뀌고, 뭉개지던 줄이 갈라지고, 버려지던 수량이 살아난다."
  printf '%s\n' "  🔵 **그 수가 달라지는 것이, 새 차례가 실제로 돈다는 유일한 증거다** —"
  printf '%s\n' "     이미지 안에서는 못 잰다(DB 도 연락서 파일도 있어야 한다)."
  printf '%s\n' "  🔴 어제 수와 **똑같이** 나오면 새 이미지로 안 돌고 있는 것을 먼저 의심하세요:"
  printf '%s\n' "     grep -n 'image:' 로 compose 의 tools-as 가 $TOOLS_NEW 인지 보세요."
  printf '%s\n' "  🔴 **폴더를 둘 다 줘야 한다** — 한쪽만 주면 나머지가 조용히 「못 바꿈」이 된다."
  printf '%s\n' "  🔵 --out 은 적지 않는다 (기록 JSON 에 연락서 파일 이름이 들어간다)."
  printf '%s\n' "     자세한 사유가 필요하면 그때 /volume1/dss 밑에 폴더를 만든다."
  printf '%s\n' ""
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (app-as 만 되돌린다. 도구는 :4 그대로"
  printf '%s\n' "               둔다 — DB 를 안 건드렸으니 자료 손실이 없다)"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
