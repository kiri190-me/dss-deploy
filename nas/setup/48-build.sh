#!/bin/bash
# dss-deploy/nas/setup/48-build.sh — 마흔다섯째 배포 · 이미지 굽기 (2026-10-30)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · Git Bash) ────────────────────────────────────
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/48-build.sh" --check
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/48-build.sh" --go
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-45):
#     bash .../48-build.sh --go "/d/배포본/_images-45"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다. 47번과
#      같은 방식이다 — 지시서를 쓴 쪽은 이 파일을 쓰기만 하고 돌리지 않았다.
#
# ── 이번에 굽는 것 — **저장소 둘, 이미지 셋** ─────────────────────────
#     ① A/S 앱   dss-as:4.0        → **dss-as:4.1**        커밋 6  스테이지 기본(runner)
#     ② A/S 도구 dss-as-tools:7    → **dss-as-tools:8**    커밋 6  🔴 --target tools
#     ③ PO 앱    dss-po:0.7        → **dss-po:0.8**        커밋 1  스테이지 기본(runner)
#
#   🔴 **지난 판(47번)은 저장소 하나뿐이었다.** 이 판은 **둘**이다 — 같은 날 A/S 와
#      PO 가 같은 일(납기 역전)을 했고 PO 쪽은 A/S 의 4516021 을 옮긴 사본이다.
#   🔵 PO 는 **40번대 스크립트에 한 번도 안 나온다.** 마지막으로 구운 것은
#      **31-build.sh**(2026-10-22)이고 그때 태그가 dss-po:0.7 이었다.
#   🔴 **PO 에는 도구 이미지가 없다** — 아래 5절에서 그것을 **재서** 확인한다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 기준 SHA — **추정하지 않고 역산해서 확인했다** (2026-10-30)
# ══════════════════════════════════════════════════════════════════════
#   「최근 N개」로 세다 가운데 셋을 놓친 적이 있고 그중 하나가 알림 종 자체였다.
#   그래서 두 저장소 모두 **지난 판 스크립트에서 역산**했다.
#
#   ㄱ) **A/S — 3bde67e.** 역산한 길:
#        · 47-build.sh 머리말이 제 기준 SHA 를 **081439b**, 그 이후 **커밋 1** 이라
#          적어 두었다(SITES 표 넷째 칸 · 일곱째 칸도 같은 값이다).
#        · 'git log --oneline 081439b..HEAD' 를 돌리면 081439b 바로 뒤가
#          **3bde67e 고장 부품을 줄 수가 아니라 실제 수량으로 센다** 하나다.
#        · 즉 47번이 실제로 구운 것은 **3bde67e** 이고, 48번의 기준은 거기다.
#        · 🔵 47-deploy.sh 머리말의 「이 배포가 하는 일 — 커밋 하나」에도
#          **3bde67e** 가 글자 그대로 적혀 있다. 두 길이 같은 답을 냈다.
#        · 🔵 지시서의 추정(3bde67e)과 **맞았다.**
#
#   ㄴ) **PO — 394e048.** 역산한 길:
#        · 40번대 스크립트에는 'dss-po:' 가 **한 줄도 없다**(42~47번 전수 grep).
#          PO 가 마지막으로 들어간 것은 **31-build.sh** 의 JOBS 표
#          'po|dss-po|dss-po:0.7|' 이고, 31-deploy.sh 의 IMGS 표가 그 tar 를
#          'dss-po:0.7 ← dss-po:0.6' 으로 갈아 끼웠다.
#        · dss-deploy/README.md 의 기준 SHA 표가 네 자리에서 모두
#          **| PO | dss-po | 0.7 | 394e048 |** 이라고 적는다.
#        · 'git log' 로 보면 394e048 은 2026-10-22 13:38 이고 31-build.sh 파일
#          시각은 같은 날 16:56 이다 — 그때 PO 의 HEAD 가 394e048 이었다는 뜻이고,
#          그 뒤 오늘까지 PO 에 쌓인 커밋은 **c32358f 하나뿐**이다.
#        · 🔵 지시서의 추정(394e048)과 **맞았다.**
#
# ── 이번 범위의 커밋 — A/S 여섯 · PO 하나 ────────────────────────────
#   A/S  3bde67e..3851693
#     dca7909 사내 목표 출하일이 고객 요청 납기일보다 늦으면 알린다
#     be21fa5 PO발행일이 적혔는데 사내 목표 출하일이 비면 엔지니어에게 알린다
#     7c4f31b 납기일을 묶기 전에 운영 자료를 세는 도구
#     4516021 내자정리에서도 납기 역전을 붉은 날짜와 메모로 알린다
#     3d20358 납기 역전이면 엔지니어·영업·관리자에게 알린다
#     3851693 머리말이 세는 수를 항목 수에 맞춘다
#   PO   394e048..c32358f
#     c32358f 내자정리에서도 납기 역전을 붉은 날짜와 메모로 알린다
#
#   🔵 **두 저장소 사이에 API 계약이 바뀐 자리가 없다**(2026-10-30 실측 — 두
#      diff 어디에도 src/app/api/ 밑의 파일이 **한 개도 없다**). 그래서 **배포
#      차례가 어느 쪽이 먼저든 상관없다.** 48-deploy.sh 는 둘을 한 번에 띄운다.
#
# ── 🔴 마이그레이션 — **둘 다 0건이다. 내가 다시 쟀다** ───────────────
#   2026-10-30 실측:
#     git -C RF_Service_System diff --name-only 3bde67e..3851693 -- drizzle/  → **0줄**
#     git -C dss-po          diff --name-only 394e048..c32358f  -- drizzle/  → **0줄**
#   🔴 PO 쪽 0 은 **삼켜진 0 이 아니다** — dss-po 에는 drizzle/ 폴더가 **애초에
#      없다**(2026-09-28 부터 그렇고 .dockerignore 머리말이 그것을 적어 두었다.
#      스키마의 주인은 A/S 하나뿐이다). 아래 4절이 「없는 것이 맞다」를 따로 센다.
#   🔴 그래서 **as-migrations.tar.gz 를 만들지도 보내지도 않는다.** NAS 의
#      /volume1/dss/as-migrations 는 39번이 올려 둔 **121 그대로**다.
#   🔵 **이 판에 새 표도 새 칸도 없다.** 알림 종류가 둘 늘었지만 종류 이름은
#      notification_kind_settings 의 **text 칸**(kind_key)에 들어간다 — 그 표의
#      머리말이 「kind_key 에 왜 enum 을 쓰지 않았나」를 적어 두었다. enum 이었다면
#      이 판에 마이그레이션이 **있어야** 했다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 A/S 도구(dss-as-tools)를 **왜 굽는가** — 세 잣대가 모두 같은 답이다
# ══════════════════════════════════════════════════════════════════════
#   🔵 이 판정이 넉 달 사이 여러 번 어긋났고, 어긋난 자리마다 잣대가 한 칸씩
#      넓어졌다. 이력부터 한 줄씩 적는다(46·47-build.sh 의 글을 이어받는다):
#        · **서른여섯째(39번)**: 「마이그레이션 0건이니 도구는 안 굽는다」로 쟀다
#          → **틀렸다**(도구에 비상구 둘이 못 쓰는 채로 들어 있었다).
#        · **서른일곱째(40번)**: 「그 도구가 **부르는 명령**이 바뀌었는가」로 쟀고
#          안 구웠다 → **맞았다**(db:migrate · db:preflight 둘 다 볼륨만 읽는다).
#        · **서른여덟째(41번)**: 그 잣대로는 「**늘어난** 명령」이 안 걸렸다.
#          안 올렸으면 'npm error Missing script' 가 날 자리였다 → 구웠다.
#        · **서른아홉째(42번)**: package.json 이 0줄인데 scripts/ 에 백필 도구가
#          새로 생겼다. 잣대를 「tools 스테이지가 **담는 것 전부**」로 넓혔다 → 구웠다.
#        · **마흔째(43번)**: 도구가 **부르는 코드**(src/lib/kyosan/ 둘)가 바뀌어 구웠다.
#        · **마흔한째(44번)**: 도구가 **안 부르는** used-part-display.ts 가 바뀌었는데도
#          「잣대를 사람이 그때그때 뒤집지 않는다」로 구웠다.
#        · **마흔두째(45번)**: 도구의 import 닫힘 안에 바뀐 파일이 **넷** 있었다 —
#          까닭이 「**부르니까**」였다.
#        · **마흔세째(46번)**: 닫힘 안에 **하나도 없었다**(닫힘 161 · 바뀐 아홉 ·
#          겹침 0). 다섯 판을 내리 구운 뒤 처음으로 **안 구웠다.**
#        · **마흔네째(47번)**: 닫힘 안에 **하나**(inventory-gateway.ts, 주석만) →
#          「주석만이니 안 굽는다」는 셋째 잣대를 세우지 않기로 하고 구웠다.
#
#   🔴 **마흔다섯째(이번)는 다툴 것이 아예 없다 — 잣대 셋이 전부 「굽는다」다.**
#
#   ㄱ) 🔴 **늘어난 npm 명령 — 41번이 데인 바로 그 자리다.**
#      package.json 의 scripts 에 **세 줄이 늘었다**(2026-10-30 git diff 실측):
#          check:target-shipment-missing
#          check:due-date-inverted
#          check:requested-due-date-sync
#      셋 다 기준 3bde67e 판의 package.json 에는 **0번** 나오고 지금 판에는
#      **1번씩** 나온다(git show 로 파일마다 세어 확인).
#      🔴 **그리고 이 셋은 「개발 PC 전용 검사」가 아니다.** 셋의 머리말이
#         「운영 DB 에 직접 붙는 것은 금지라 코드 안에 세는 길이 있어야 한다」고
#         적는다 — 즉 **NAS 의 tools-as 에서 부를 물건**이다. 41-deploy.sh 가
#         'compose … --profile tools run --rm tools-as npm run check:part-name-overlap'
#         을 실제로 부른 전례가 있다. 안 구우면 그날 **npm error Missing script**다.
#
#   ㄴ) 🔴 **도구의 import 닫힘 안에 바뀐 파일이 아홉이다.**
#      🔵 46·47번이 쓴 펼치개를 **글자 그대로** 다시 썼다(상대경로 · '@/' ·
#         '@dss/core/schema' · '@dss/core/ui/*' · '@dss/ui' 를 따라가고,
#         'export … from' 과 타입 전용 import 까지 따라간다. 주석은 걷어내고 센다).
#      · **먼저 펼치개를 맞대어 봤다.** 46·47번이 쓴 시작점
#        (scripts/backfill-kyosan-used-parts.ts) 하나로 돌리면 **161개**가 나오고
#        못 푼 상대경로가 **0개**다 — 46·47번이 적은 수와 **같다.** 45번이
#        「닫힘 밖」이라 바로잡은 used-part-display.ts 는 여기서도 **안 나온다.**
#      · 🔴 **그런데 이번 판은 시작점을 하나로 두면 틀린 답이 나온다.** 그
#        161개와 이번에 바뀐 35개를 맞대면 **겹침이 0** 이다. 46번과 똑같은
#        모양이라 「안 굽는다」로 갈 뻔했다.
#        **까닭은 간단하다 — 이번에 늘어난 명령 셋은 백필이 아니다.** 백필 하나만
#        시작점으로 두면 **새로 생긴 도구 자신이 닫힘 밖에 선다.**
#      · 🔴 그래서 시작점을 **package.json 의 scripts 가 가리키는 scripts/ 파일
#        전부**(스물둘 — 백필 포함)로 넓혀 다시 폈다. 그것이 「**이 도구 이미지로
#        부를 수 있는 것 전부**」의 닫힘이다.
#            닫힘 **222개** · 못 푼 상대경로 **0개**
#            이번에 바뀐 35개와 맞대면 **아홉이 겹친다**:
#              scripts/check-due-date-inverted.ts
#              scripts/check-requested-due-date-sync.ts
#              scripts/check-target-shipment-missing.ts
#              scripts/lib/requested-due-date-sync-survey.ts
#              src/lib/db/queries/repair-case-due-date-inverted-notifications.ts
#              src/lib/db/queries/repair-case-target-shipment-notifications.ts
#              src/lib/domain/due-date-inversion.ts
#              src/lib/domain/notifications.ts
#              src/lib/domain/requested-due-date-link.ts
#      · 🔵 **47번이 이름 붙인 닫힘 열 개도 이 222개에 전부 들어 있다**(열 다 확인).
#        즉 넓힌 닫힘은 좁은 닫힘을 **덮는다** — 덜어낸 것이 아니라 더한 것이다.
#      🔴 **다음 사람에게 남기는 교훈 한 줄**: 「닫힘」을 잴 때 **시작점을 하나로
#         두지 마라.** 도구 이미지가 부를 수 있는 **명령 전부**에서 시작해야 한다.
#         46·47번의 161 은 틀린 수가 아니라 **그 판에서는 시작점이 하나로 충분했던
#         수**다 — 그 판들은 scripts/ 에 새 파일이 안 생겼다.
#
#   ㄷ) 🔵 **39번에 넓혀 둔 잣대(「tools 스테이지가 담는 것 전부」)로도 굽는다.**
#      Dockerfile 의 tools 스테이지가 담는 것은
#      package.json · tsconfig.json · drizzle.config.ts · scripts/ · src/ · vendor/
#      이고, 이번에 바뀐 **35개가 전부 그 안**이다(package.json 1 · scripts/ 6 ·
#      src/ 28). **35 > 0** 이라 굽는다.
#
#   🔵 **치르는 값**: tar 하나(223MB)를 더 굽고 올리는 것뿐이다. tools-as 는
#      profiles: [tools] 라 **다시 뜨지도 않는다.**
#
#   🔵 **다음 사람이 같은 판단을 다시 하는 법** — 명령 네 줄이다:
#        ① git -C RF_Service_System diff --name-only <기준SHA>..HEAD
#        ② git -C RF_Service_System diff <기준SHA>..HEAD -- package.json
#           → scripts 에 **줄이 늘었으면 그것만으로 굽는다**(41번).
#        ③ package.json 의 scripts 가 가리키는 scripts/*.ts **전부**에서 import 를
#           끝까지 펼쳐 닫힘을 만든다. (지금 판에서 222개 · 못 푼 상대경로 0.)
#        ④ ①과 ③을 맞댄다. **겹치는 것이 하나라도 있으면 굽는다.**
#      🔴 ④ 에서 「겹치긴 하는데 주석만이다」가 나와도 **굽는 쪽**이다(47번 머리말 ㄹ).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 PO 에는 도구 이미지가 **없다** — 짐작이 아니라 쟀다
# ══════════════════════════════════════════════════════════════════════
#   · dss-po/Dockerfile 의 FROM 은 **셋**이다: deps · builder · **runner**.
#     'AS tools' 가 한 줄도 없다. 그 자리에 주석이 대신 적혀 있다 —
#     「이웃 저장소(A/S · 개선요청)에는 여기에 --target tools 로 굽는 스테이지가
#      있다 … 🔴 이 사이트에는 NAS 에서 돌릴 스크립트가 없다. 스키마의 주인은
#      A/S 하나뿐이다」.
#   · 운영 compose 의 PO 블록 주석도 같은 말을 한다 — 「🔴 **도구 서비스(tools-po)를
#     만들지 않는다.** 이 저장소에는 마이그레이션도 야간 작업도 없다. 야간
#     완전삭제는 tools-as 가 계속 맡고, 같은 표라 그것이 PO 의 휴지통도 함께 비운다」.
#   · dss-po/package.json 의 scripts 는 열이고 전부 개발 PC 것이다
#     (dev · build · start · lint · typecheck · test · test:db:safety · pretest:db ·
#      test:db · test:components). NAS 에서 부를 명령이 하나도 없다.
#   🔵 그래서 PO 쪽은 「같은 잣대로 재서 안 굽는다」가 아니라 **잴 대상이 없다**.
#      5절이 「tools 스테이지가 **없는 것이 맞다**」를 ✗ 가 나게 재 둔다 —
#      나중에 누가 PO 에 tools 를 더하면 이 줄이 그것을 알려 준다.
#
# ── 🔴 안 굽는 저장소 **여덟** (2026-10-30 실측 — 전부 HEAD 가 기준 SHA 그대로) ─
#     dss-auth        기준 52cbb19 · HEAD 52cbb19 · 이후 커밋 0
#     dss-inventory   기준 e0d84e8 · HEAD e0d84e8 · 이후 커밋 0
#     dss-board       기준 7d4f390 · HEAD 7d4f390 · 이후 커밋 0
#     dss-leave       기준 f568fc0 · HEAD f568fc0 · 이후 커밋 0
#     njlee(계측기)   기준 a234878 · HEAD a234878 · 이후 커밋 0
#     dss-improvements 기준 38fc0ef · HEAD 38fc0ef · 이후 커밋 0
#     dss-trouble     기준 c3da85d · HEAD c3da85d · 이후 커밋 0
#     dss-approvals   기준 8ab36fd · HEAD 8ab36fd · 이후 커밋 0
#   🔵 기준 SHA 의 출처는 dss-deploy/README.md 의 기준 SHA 표다. 여덟 모두
#      **HEAD 가 그 SHA 와 글자 그대로 같다** — 「이후 커밋 0」이 삼켜진 0 이
#      아니라는 증거다.
#
# ── 🔴 모드 둘 ────────────────────────────────────────────────────────
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다.
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면
#            굽지 않고 멈춘다. 전부 ✓ 일 때만 셋을 굽고 tar 로 뽑는다.
#            그리고 **이미지 안을 센다**(겉이 아니라 결과).
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 tar 크기를 **두 번** 견준다 (이 판에서 새로 넣었다) ────────────
#   ① **지난 판 tar 와** 견준다. 적어 둔 값의 출처:
#        dss-as-4.0.tar      132502528  [배포본] 47-deploy.sh 의 TARS
#        dss-as-tools-7.tar  223720960  [배포본] 47-deploy.sh 의 TARS
#        dss-po-0.7.tar       95437312  [배포본] 31-deploy.sh 의 IMGS
#      차이가 **25%** 를 넘으면 ✗ 다. 🔵 넘었다고 반드시 잘못된 것은 아니다 —
#      그때는 **사람이 보라는 뜻**이고, 까닭을 알면 그 숫자를 여기 고쳐 적으면 된다.
#   ② **그 이미지 자신과** 견준다. 🔴 여기가 함정이라 가지를 둘로 나눴다:
#      · 이 개발 PC 의 docker 는 **containerd 저장소**를 쓴다. 그래서
#        'docker image inspect --format {{.Size}}' 가 **압축된 내용 크기**를 준다 —
#        2026-10-30 실측으로 dss-as:4.0 은 inspect 132482475 · tar 132502528 이라
#        **거의 같다**(0.02% 차이). dss-as-tools:7 도 223698073 vs 223720960 이다.
#      · 반면 'docker image ls' 가 보여 주는 601MB 는 **펼친 크기**이고, tar 는
#        그 **1/4쯤**이다(601MB → 126MiB ≈ 22%). 「584MB 이미지 → 130MB tar」는
#        그쪽 비다.
#      🔴 **둘 중 어느 저장소인지는 미리 못 정한다.** 그래서 비가 90~110% 면
#         ✓(containerd), 10~45% 면 ✓(고전), 그 밖이면 ✗ 로 센다.
#         한 잣대로 재면 **가짜 ✗** 가 난다 — 「단계마다 기대값이 다르다」.
#   🔴 **tar 지문은 'docker image inspect' 의 .Id 와 맞대지 않는다.** 그것은
#      애초에 다른 값이다. 맞댈 상대는 **빌드 로그의 'exporting config sha256:'** 이다.
#      그걸로 재서 구운 아홉이 전부 ✗ 가 난 적이 있다.
#
# ── 🔴 이 환경의 함정 (36~47-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싸고, 저장소 자리를
#      이 파일의 자리에서 계산한다(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:\… 를 /c/… 로
#      바꾸고, docker save 는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#      🔴 이 파일의 tar/docker save 어디에도 드라이브 문자가 들어가지 않는다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(두 저장소의 .dockerignore 가
#      .next 를 막는다 — 아래 5절이 그것도 잰다). 다만 메모리는 다르다.
#   ④ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다.** 한글을 argv 로 넘기면
#      깨지는 길이 열린다 — 아래 '새 판인가' 검사의 이름 셋은 전부 ASCII 다.
#   ⑤ 🔴 **이번 판의 파일 목록에는 대괄호와 괄호가 있다**
#      (src/app/(app)/repair-cases/[id]/page.tsx). 그래서 목록은 **따옴표로 감싼
#      여러 줄 변수**로만 다룬다 — 따옴표 없이 펼치면 셸이 글자 묶음 패턴으로 읽는다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안의 백틱은 명령 치환으로 읽힌다 → 이 파일에는 백틱이
#      **한 개도 없다**(주석에도 안 썼다). 쓴 뒤 grep 으로 세었다.
#   ② 읽기 전용 자리의 콜론과 꺾쇠로 빈 파일을 만드는 꼴은 ash 를 죽인다 →
#      이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   🔴 19·20·21번에는 그 둘이 아직 남아 있다. **거기서 베껴 오지 마라.**
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEV=${DSS_DEV:-$(cd "$SCRIPT_DIR/../../.." && pwd)}

PASS=0; FAIL=0; UNK=0
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
unk()  { UNK=$((UNK+1));   printf '  ? %s — 못 쟀다 (%s)\n' "$1" "$2"; }
note() { printf '  ⚠️ %s\n' "$1"; }
say()  { printf '    %s\n' "$1"; }
# 🔴 ✗ 가 났을 때 그 자리에서 찍는다 — 처음 도는 코드라 기대값이 틀릴 확률이
#    굽기만큼 높다. ✓ 쪽 오판은 영영 안 드러나므로 ✗ 쪽을 크게 적는다.
doubt() { say "🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 이 줄의 기대값이"
          say "   어디서 왔는지는 이 파일 머리말에 적혀 있습니다."; }

isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }

# 🔴 C:\… 또는 C:/… 를 /c/… 로. tar 는 드라이브 문자를 원격 호스트로 읽는다.
to_unix() { # 1 경로
  local p=${1//\\//}
  case "$p" in
    [A-Za-z]:/*) p=/$(printf '%s' "${p%%:*}" | tr 'A-Z' 'a-z')${p#?:} ;;
  esac
  printf '%s' "$p"
}

tar_name() { printf '%s.tar' "$(printf '%s' "$1" | tr ':' '-')"; }

# 🔴 /c/… 를 C:\… 로. **사람이 칠 명령은 PowerShell 이다** — 이 PC 는
#    PowerShell 5.1 이고 /c/… 꼴 경로를 모른다. 꼬리말의 안내가 그대로
#    붙여 넣어지는 글이라, 여기서 한 번 되돌려 준다.
#    🔵 이 함수가 만든 글은 **찍기만 한다** — tar 나 docker save 에 넘기지
#       않는다(tar 는 드라이브 문자를 원격 호스트로 읽는다).
to_win() { # 1 경로
  local p=$1
  case "$p" in
    /[A-Za-z]/*)
      p=$(printf '%s' "${p:1:1}" | tr 'a-z' 'A-Z'):${p:2}
      ;;
  esac
  printf '%s' "${p//\//\\}"
}

# tar 안 manifest.json 의 Config 지문 (39~47-build.sh 의 것을 글자 그대로)
tar_config_id() { # 1 tar
  tar -xOf "$1" manifest.json 2>/dev/null \
    | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 \
    | sed 's|blobs/sha256/|sha256:|'
}

# 한 저장소의 drizzle/ 을 센다 → ".sql수 journal수"
count_drizzle() { # 1 저장소 폴더
  local s j
  s=$(ls -1 "$1/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  j=$(grep -o '"idx"' "$1/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  printf '%s %s' "${s:-0}" "${j:-0}"
}

# 두 수의 차이가 몇 퍼센트인가 (정수). 0 으로 나누지 않는다.
pct_diff() { # 1 새값 2 옛값 → 퍼센트(정수). 못 재면 아무것도 안 찍는다.
  local a b d
  a=$1; b=$2
  isnum "$a" || return 1
  isnum "$b" || return 1
  [ "$b" -gt 0 ] || return 1
  if [ "$a" -ge "$b" ]; then d=$((a - b)); else d=$((b - a)); fi
  printf '%s' $((d * 100 / b))
}

# ══ 이번에 굽는 것 — 한자리에 모아 둔다 ═══════════════════════════════
#   열쇠|저장소 폴더|새 태그|기준 SHA|--target(없으면 -)|기대 drizzle 변경 수|기대 커밋 수|지난판 tar 바이트|지난판 tar 이름
#
#   🔴 여섯째 칸은 「기준 SHA 이후 drizzle/ 에서 **달라진 파일 수**」다.
#      셋 다 **0 이어야** 맞다.
#   🔵 일곱째 칸(커밋 수)은 ✗ 로 세지 않고 ⚠️ 로만 센다 — 적어 둔 수와 어긋나면
#      표가 낡았다는 뜻이라 사람이 봐야 한다. A/S 여섯 · PO 하나다.
#   🔴 'astools' 는 **같은 저장소**(RF_Service_System)를 --target tools 로 한 번
#      더 굽는 줄이다. 저장소를 세는 자리에서는 이 줄을 건너뛴다(41~47번과 같은
#      처리) — 두 번 세면 ✗ 도 두 번 센다.
#   🔵 여덟째·아홉째 칸은 **지난 판 tar** 다. 출처는 머리말에 적었다.
SITES='
as|RF_Service_System|dss-as:4.1|3bde67e|-|0|6|132502528|dss-as-4.0.tar
astools|RF_Service_System|dss-as-tools:8|3bde67e|tools|0|6|223720960|dss-as-tools-7.tar
po|dss-po|dss-po:0.8|394e048|-|0|1|95437312|dss-po-0.7.tar
'
HOWMANY=3
TOOLS_TAG=dss-as-tools:8

# ── 🔴 기대값과 그 출처 ───────────────────────────────────────────────
#   [저장소] 2026-10-30 개발 PC 의 저장소에서 센 값
AS_SQL_WANT=121       # [저장소] RF_Service_System/drizzle/*.sql — 안 늘어야 한다(0120 까지 그대로)
# 서브모듈 포인터 셋. 🔴 **A/S 와 PO 의 dss-core 가 서로 다르다 — 그것이 지금
#    상태다.** PO 의 8730c94 는 A/S 의 05018b0 의 **조상**이다(2026-10-30
#    merge-base 로 확인 — PO 가 커밋 셋만큼 뒤에 있다). 🔴 **이 배포에서 맞추지
#    않는다.** 이번 범위에 vendor/ 변경이 한 줄도 없고(두 diff 모두 0줄), 여기서
#    올리면 재어 보지도 않은 코드가 운영에 따라 들어간다.
AS_CORE_PIN=05018b077a780922b484a7a539665f35d5207c82
PO_CORE_PIN=8730c9433b4388a038349ab9a11ec633659da782
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425        # 두 저장소가 같은 값이다
# 🔴 5절이 쓰는 기준 SHA. **SITES 표의 넷째 칸과 같은 값이어야 한다** — 41번에서는
#    이 값이 표와 따로 적혀 있어 한쪽만 고치면 조용히 어긋날 자리였다.
AS_BASE=3bde67e
PO_BASE=394e048
# 🔵 tools 스테이지가 담는 것 중 달라진 파일 수 — 적어 둔 값(2026-10-30 실측 35).
TOOLS_CHANGED_WANT=35
# 🔵 도구 닫힘(222개) 안에서 바뀐 파일 수 — 적어 둔 값(2026-10-30 실측 9).
TOOLS_CALLED_WANT=9
# 🔵 늘어난 npm 명령 셋 — 41번이 데인 자리다.
NEW_NPM_SCRIPTS="check:target-shipment-missing check:due-date-inverted check:requested-due-date-sync"

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-45"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

printf '%s\n' "마흔다섯째 배포 · 이미지 굽기   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  저장소 뿌리: $DEV"
printf '%s\n' "  tar 셋을 둘 자리: $OUT"
printf '%s\n' "  굽는 것: dss-as:4.1 · dss-as-tools:8 · dss-po:0.8  (저장소 둘 · 이미지 셋)"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 1. 도커가 도는가 ──────────────────────────────────────────────────
printf '\n== 1. 도커\n'
if docker version --format '{{.Server.Version}}' >/dev/null 2>&1; then
  ok "도커가 돈다 (서버 $(docker version --format '{{.Server.Version}}' 2>/dev/null))"
else
  bad "도커가 안 돈다 — Docker Desktop 을 켜세요"
fi

# ── 2. 저장소 둘 (이미지 셋) ──────────────────────────────────────────
printf '\n== 2. 저장소 둘 (이미지 셋)\n'
printf '%s\n' "🔴 미커밋·미푸시가 있으면 구운 이미지를 나중에 재현하지 못한다."
printf '%s\n' "🔴 **안 받은 것도 센다** — 낡은 코드를 굽고도 모른다."
printf '%s\n' "$SITES" | while IFS='|' read -r KEY REPO TAG BASE TGT WANTMIG WANTN PREVSZ PREVTAR; do
  [ -n "${KEY:-}" ] || continue
  [ "$KEY" = astools ] && continue   # 🔵 A/S 앱에서 이미 쟀다. 같은 저장소다.
  DIR="$DEV/$REPO"
  printf '  ── %s (%s → %s)\n' "$KEY" "$REPO" "$TAG"
  if [ ! -d "$DIR/.git" ] && [ ! -f "$DIR/.git" ]; then
    printf '  ✗ %s — git 저장소가 아니다 (%s)\n' "$REPO" "$DIR"; continue
  fi
  dirty=$(git -C "$DIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if isnum "${dirty:-}" && [ "$dirty" -eq 0 ]; then printf '  ✓ %s 미커밋 0\n' "$REPO"
  else printf '  ✗ %s 미커밋 %s 줄\n' "$REPO" "${dirty:-?}"; git -C "$DIR" status --porcelain=v1 2>/dev/null | head -5 | sed 's/^/      /'; fi
  if git -C "$DIR" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    up=$(git -C "$DIR" log --oneline '@{u}..HEAD' 2>/dev/null | wc -l | tr -d ' ')
    dn=$(git -C "$DIR" log --oneline 'HEAD..@{u}' 2>/dev/null | wc -l | tr -d ' ')
    if [ "${up:-1}" = "0" ] && [ "${dn:-1}" = "0" ]; then printf '  ✓ %s 미푸시 0 · 안받음 0\n' "$REPO"
    else printf '  ✗ %s 미푸시 %s · 안받음 %s\n' "$REPO" "${up:-?}" "${dn:-?}"; fi
  else
    printf '  ? %s 미푸시 — 올려다볼 가지가 없다\n' "$REPO"
  fi
  # 🔵 기준 SHA 가 조상인지 — 아니면 표가 낡았거나 가지가 갈렸다.
  if git -C "$DIR" merge-base --is-ancestor "$BASE" HEAD 2>/dev/null; then
    n=$(git -C "$DIR" log --oneline "$BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
    m=$(git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | wc -l | tr -d ' ')
    if [ "${n:-x}" = "$WANTN" ]; then
      printf '  ✓ %s 기준 %s 이후 커밋 %s개 — 적어 둔 그대로\n' "$REPO" "$BASE" "$n"
    else
      printf '  ⚠️ %s 기준 %s 이후 커밋 %s개 — **%s개를 적어 두었다**. 아래를 보고 사람이 판단할 것\n' "$REPO" "$BASE" "${n:-?}" "$WANTN"
      printf '%s\n' "      🔵 커밋이 늘어도 **굽는 판정은 안 흔들린다**(이미 굽는다). 흔들리는 것은"
      printf '%s\n' "         48-deploy.sh 꼬리말의 「볼 곳」과 5절의 파일 목록이다 — 사람이 보세요."
      git -C "$DIR" log --oneline "$BASE..HEAD" 2>/dev/null | head -12 | sed 's/^/      /'
    fi
    # 🔴 「0 이면 통과」가 아니다. 적어 둔 수와 **똑같아야** 한다.
    if [ "${m:-x}" = "$WANTMIG" ]; then
      printf '  ✓ %s drizzle/ 에서 달라진 파일 %s개 — 적어 둔 그대로\n' "$REPO" "$m"
    else
      printf '  ✗ %s drizzle/ 에서 달라진 파일 %s개 — **%s개를 기대했다**. 전제가 깨졌으니 멈추고 알릴 것\n' "$REPO" "${m:-?}" "$WANTMIG"
      git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | head -8 | sed 's/^/      /'
    fi
  else
    printf '  ✗ %s — 기준 SHA %s 가 조상이 아니다 (표가 낡았거나 가지가 갈렸다)\n' "$REPO" "$BASE"
  fi
  printf '    지금 HEAD: %s\n' "$(git -C "$DIR" log -1 --format='%h %s' 2>/dev/null)"
done

# 🔴 위 while 이 파이프라인 안이라 **셈이 안 넘어온다.** 다시 세어 FAIL 에 싣는다.
REPO_BAD=0
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}
  rest=${rest#*|}; BASE=${rest%%|*}; rest=${rest#*|}; TGT=${rest%%|*}
  rest=${rest#*|}; WANTMIG=${rest%%|*}
  [ "$KEY" = astools ] && continue   # 🔵 이미 셌다. 두 번 세면 ✗ 도 두 번이다.
  DIR="$DEV/$REPO"
  d=$(git -C "$DIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  u=$(git -C "$DIR" log --oneline '@{u}..HEAD' 2>/dev/null | wc -l | tr -d ' ')
  n=$(git -C "$DIR" log --oneline 'HEAD..@{u}' 2>/dev/null | wc -l | tr -d ' ')
  m=$(git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | wc -l | tr -d ' ')
  git -C "$DIR" merge-base --is-ancestor "$BASE" HEAD 2>/dev/null || REPO_BAD=$((REPO_BAD+1))
  [ "${d:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
  [ "${u:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
  [ "${n:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
  [ "${m:-x}" = "$WANTMIG" ] || REPO_BAD=$((REPO_BAD+1))
done
if [ "$REPO_BAD" = "0" ]; then ok "저장소 둘이 깨끗하고 drizzle 변경 수가 적어 둔 그대로(0)"
else bad "저장소 검사에서 어긋난 것 ${REPO_BAD}가지 — 위 ✗ 를 보세요"; doubt; fi

# 🔴 **안 굽는 여덟도 재 둔다** — 「이번 범위에 커밋이 없다」를 짐작으로 적지
#    않는다. HEAD 가 기준 SHA 와 글자 그대로 같아야 ✓ 다.
#    🔵 ✗ 가 나도 **이 배포를 막지 않는다**(⚠️ 로만 센다) — 그 저장소를 굽는 것은
#       이 판의 일이 아니고, 다음 판의 범위가 늘었다는 뜻이다.
printf '\n  ── 안 굽는 여덟 (HEAD 가 기준 SHA 그대로여야 한다)\n'
IDLE='
dss-auth|52cbb19
dss-inventory|e0d84e8
dss-board|7d4f390
dss-leave|f568fc0
njlee|a234878
dss-improvements|38fc0ef
dss-trouble|c3da85d
dss-approvals|8ab36fd
'
IDLE_SEEN=0
for row in $(printf '%s\n' "$IDLE" | tr -d ' ' | grep -v '^$'); do
  R=${row%%|*}; B=${row#*|}
  IDLE_SEEN=$((IDLE_SEEN+1))
  DIR="$DEV/$R"
  if [ ! -d "$DIR/.git" ] && [ ! -f "$DIR/.git" ]; then
    note "$R — 저장소가 여기 없다 ($DIR). 못 쟀으니 사람이 보세요"; continue
  fi
  h=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
  c=$(git -C "$DIR" rev-list --count "$B..HEAD" 2>/dev/null)
  if [ "${c:-x}" = "0" ]; then
    printf '      %-18s 기준 %s · HEAD %s · 이후 커밋 0\n' "$R" "$B" "${h:-?}"
  else
    note "$R — 기준 $B 이후 커밋 ${c:-못 쟀다}개다. **다음 판의 범위가 늘었다.** 사람이 보세요"
    git -C "$DIR" log --oneline "$B..HEAD" 2>/dev/null | head -5 | sed 's/^/      /'
  fi
done
# 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다 — 여덟을 다 봤는가.
if [ "$IDLE_SEEN" = "8" ]; then ok "안 굽는 여덟을 다 봤다 (표본이 비지 않았다)"
else bad "안 굽는 저장소를 ${IDLE_SEEN}개만 봤다 — 여덟을 기대했다. IDLE 표가 깨졌다"; fi

# ── 3. 🔴 서브모듈 — 빈 폴더면 빌드가 크게 실패한다 ───────────────────
printf '\n== 3. 서브모듈 (A/S 둘 · PO 둘)\n'
ASDIR="$DEV/RF_Service_System"
PODIR="$DEV/dss-po"
# 🔴 tr 의 지우기 집합에서 빼기표는 **맨 끝**에 둔다(ASCII 역순이면 죽는다).
pin_of() { git -C "$1" submodule status "$2" 2>/dev/null | awk '{print $1}' | tr -d '+-'; }

check_pin() { # 1 저장소 2 서브모듈경로 3 기대 4 사람이 부르는 이름
  local got
  got=$(pin_of "$1" "$2")
  if [ "${got:-}" = "$3" ]; then
    ok "$4 $2 포인터가 ${3:0:7} 다 (적어 둔 그대로)"
  elif [ -n "${got:-}" ]; then
    bad "$4 $2 포인터가 ${got:0:7} 다 — **${3:0:7} 을 기대했다.** 멈추고 알릴 것"
    doubt
  else
    bad "$4 $2 포인터를 못 읽었다 — 서브모듈이 아예 없다"
  fi
}
check_pin "$ASDIR" vendor/dss-core "$AS_CORE_PIN" "A/S"
check_pin "$ASDIR" vendor/dss-ui   "$UI_PIN"      "A/S"
check_pin "$PODIR" vendor/dss-core "$PO_CORE_PIN" "PO"
check_pin "$PODIR" vendor/dss-ui   "$UI_PIN"      "PO"
# 🔵 **A/S 와 PO 의 dss-core 가 서로 다른 것은 지금 상태이고 이 배포가 고칠 일이
#    아니다.** 그 사실을 한 줄로 남겨 둔다 — 다음 사람이 「어긋났다」고 읽고
#    고치려 들지 않게.
say "🔵 A/S dss-core ${AS_CORE_PIN:0:7} · PO dss-core ${PO_CORE_PIN:0:7} — **서로 다른 것이 맞다.**"
say "   PO 쪽이 커밋 셋만큼 뒤에 있고(조상 관계), 이번 범위에 vendor/ 변경이 한 줄도 없다."
say "   🔴 여기서 맞추지 마세요 — 재어 보지도 않은 코드가 운영에 따라 들어간다."
# 🔴 빈 폴더가 아닌가 — 포인터는 맞는데 안이 비어 있는 경우가 실제로 있다.
#    🔵 경로에 한글이 있어 **한 줄짜리 함수**로 받는다. "경로 이름" 꼴로 묶어
#       넘기면 셸이 공백에서 쪼개므로 그 꼴을 쓰지 않는다(머리말 함정 ①).
check_not_empty() { # 1 서브모듈 폴더 2 사람이 부르는 이름
  if [ -s "$1/package.json" ]; then ok "$2 에 파일이 있다 (빈 폴더가 아니다)"
  else bad "$2 가 **빈 폴더**다 — git submodule update --init 을 먼저"; fi
}
check_not_empty "$ASDIR/vendor/dss-core" "A/S-core"
check_not_empty "$ASDIR/vendor/dss-ui"   "A/S-ui"
check_not_empty "$PODIR/vendor/dss-core" "PO-core"
check_not_empty "$PODIR/vendor/dss-ui"   "PO-ui"

# ── 4. 🔴 drizzle/ — A/S 는 121 그대로 · PO 는 **없는 것이 맞다** ─────
printf '\n== 4. drizzle/ — A/S 는 %s 그대로 · PO 는 폴더가 없는 것이 맞다\n' "$AS_SQL_WANT"
AS_COUNTS=$(count_drizzle "$ASDIR"); AS_SQL=${AS_COUNTS%% *}; AS_JRN=${AS_COUNTS##* }
say "RF_Service_System/drizzle — .sql ${AS_SQL}장 · meta/_journal.json 의 idx ${AS_JRN}개"
if [ "${AS_SQL:-0}" = "$AS_SQL_WANT" ] && [ "${AS_JRN:-0}" = "$AS_SQL_WANT" ]; then
  ok "${AS_SQL_WANT} 그대로다 (이번 판은 마이그레이션이 없다 — 볼륨은 39번 것을 그대로 쓴다)"
else
  bad "drizzle 이 .sql ${AS_SQL:-?} · idx ${AS_JRN:-?} 다 — **${AS_SQL_WANT} 그대로여야 한다.** 전제가 깨졌으니 멈추고 알릴 것"
  doubt
fi
# 🔴 **PO 쪽 0 이 「삼켜진 0」이 아님을 여기서 가른다.** 2절은 git diff 로 0줄을
#    받았는데, 그 0 은 「안 바뀌었다」와 「그런 경로가 없다」를 구별하지 못한다.
if [ -d "$PODIR/drizzle" ]; then
  bad "🔴 dss-po 에 drizzle/ 폴더가 **생겼다** — 2026-09-28 부터 없던 것이다. 스키마의 주인이 바뀌었는지 사람이 보세요"
  ls -1 "$PODIR/drizzle" 2>/dev/null | head -8 | sed 's/^/      /'
  doubt
else
  ok "dss-po 에 drizzle/ 폴더가 없다 (없는 것이 맞다 — 스키마의 주인은 A/S 하나뿐이다)"
fi

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 도구 판정 · 담는 길 · 소스가 새 코드를 담고 있나 ────────────
# ══════════════════════════════════════════════════════════════════════
#  🔴 .dockerignore 나 Dockerfile 이 어긋나면 이미지는 멀쩡히 구워지고 **바뀐
#     코드만 조용히 빠진다.** 그래서 담는 길부터 센다.
printf '\n== 5. 도구 판정 · 담는 길 · 소스가 새 코드를 담고 있나\n'
# 🔴 기준 SHA 가 표와 이 절에 **두 벌로** 적혀 있다. 한쪽만 고치면 조용히 어긋나므로
#    먼저 맞대어 본다(41번에서 실제로 어긋날 뻔한 자리다).
AS_ROW_BASE=$(printf '%s\n' "$SITES" | tr -d ' ' | grep '^as|' | head -1 | cut -d'|' -f4)
PO_ROW_BASE=$(printf '%s\n' "$SITES" | tr -d ' ' | grep '^po|' | head -1 | cut -d'|' -f4)
if [ "${AS_ROW_BASE:-}" = "$AS_BASE" ]; then ok "A/S 기준 SHA 가 SITES 표와 이 절에서 같다 ($AS_BASE)"
else bad "A/S 기준 SHA 가 어긋난다 — 표는 ${AS_ROW_BASE:-못 읽음} · 이 절은 $AS_BASE"; fi
if [ "${PO_ROW_BASE:-}" = "$PO_BASE" ]; then ok "PO 기준 SHA 가 SITES 표와 이 절에서 같다 ($PO_BASE)"
else bad "PO 기준 SHA 가 어긋난다 — 표는 ${PO_ROW_BASE:-못 읽음} · 이 절은 $PO_BASE"; fi
# 🔵 표의 'astools' 줄이 정말 --target tools 인지. 여기가 '-' 면 runner 가 구워지고,
#    그 이미지는 **오류 없이** 쓸모가 없다.
AS_TOOLS_ROW_TGT=$(printf '%s\n' "$SITES" | tr -d ' ' | grep '^astools|' | head -1 | cut -d'|' -f5)
AS_TOOLS_ROW_TAG=$(printf '%s\n' "$SITES" | tr -d ' ' | grep '^astools|' | head -1 | cut -d'|' -f3)
if [ "${AS_TOOLS_ROW_TGT:-}" = "tools" ] && [ "${AS_TOOLS_ROW_TAG:-}" = "$TOOLS_TAG" ]; then
  ok "SITES 표의 astools 줄이 $TOOLS_TAG · --target tools 다"
else
  bad "SITES 표의 astools 줄이 어긋난다 — 태그 ${AS_TOOLS_ROW_TAG:-없음} · target ${AS_TOOLS_ROW_TGT:-없음} (기대 $TOOLS_TAG · tools)"
fi

# ── ㄱ) A/S Dockerfile 의 tools 스테이지가 담는 길 ────────────────────
if grep -q '^FROM .* AS tools' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "A/S Dockerfile 에 tools 스테이지가 있다 (--target tools 가 선다)"
else
  bad "A/S Dockerfile 에 tools 스테이지가 없다 — --target tools 가 실패한다"
fi
if grep -qE '^COPY .*scripts \./scripts' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 scripts/ 를 담는다 (**이번에 생긴 도구 셋이 들어가는 유일한 길**)"
else
  bad "A/S Dockerfile 이 scripts/ 를 안 담는다 — 새 도구 셋이 통째로 빠진다"
fi
if grep -qE '^COPY .*package\.json' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 package.json·tsconfig.json 을 담는다 (**늘어난 npm 명령 셋이 들어가는 길**)"
else
  bad "A/S Dockerfile 이 package.json 을 안 담는다 — npm run 이 Missing script 로 죽는다"
fi
if grep -qE '^COPY .*src \./src' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 src/ 를 담는다 (닫힘 안에서 바뀐 다섯이 들어가는 길)"
else
  bad "A/S Dockerfile 이 src/ 를 안 담는다 — 이번에 고친 코드가 통째로 빠진다"
fi
if grep -qE '^COPY .*vendor \./vendor' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 vendor/ 를 담는다 (@dss/core 스키마를 찾는 길)"
else
  bad "A/S Dockerfile 이 vendor/ 를 안 담는다 — Cannot find module @dss/core/schema 가 난다"
fi

# ── ㄴ) 🔴 PO 에 tools 스테이지가 **없는 것이 맞다** ──────────────────
#   짐작으로 「없다」고 적지 않는다. 생기면 이 줄이 알려 준다.
if grep -q '^FROM .* AS tools' "$PODIR/Dockerfile" 2>/dev/null; then
  bad "🔴 dss-po/Dockerfile 에 tools 스테이지가 **생겼다** — 지금까지 없던 것이다. 도구를 굽고 올릴지 사람이 정해야 한다"
  doubt
else
  ok "dss-po 에 tools 스테이지가 없다 (없는 것이 맞다 — NAS 에서 돌릴 스크립트가 없다)"
fi
PO_STAGES=$(grep -c '^FROM ' "$PODIR/Dockerfile" 2>/dev/null | tr -d ' ')
say "dss-po/Dockerfile 의 FROM 줄 ${PO_STAGES:-못 쟀다}개 (기대 3 — deps · builder · runner)"
if [ "${PO_STAGES:-x}" = "3" ]; then ok "PO 의 스테이지가 셋이다 (deps · builder · runner)"
else note "PO 의 스테이지가 ${PO_STAGES:-?}개다 — 셋을 기대했다. 사람이 보세요"; fi

# ── ㄷ) .dockerignore — 두 저장소 모두 ────────────────────────────────
#   🔴 **.next 를 막는가**도 함께 센다. 막아야 개발 서버를 띄워 둔 채로 구울 수 있다.
#   🔵 여기도 "경로 이름" 꼴로 묶지 않는다 — 경로에 한글이 있다(머리말 함정 ①).
check_dockerignore() { # 1 저장소 폴더 2 사람이 부르는 이름
  local DIG
  DIG="$1/.dockerignore"
  if [ ! -s "$DIG" ]; then
    bad "$2 에 .dockerignore 가 없거나 비었다 — .env 와 .git 이 이미지로 따라 들어간다"
    return
  fi
  if grep -qE '^scripts/?$' "$DIG" 2>/dev/null; then
    bad "$2 의 .dockerignore 가 scripts/ 를 막는다 — 빈 폴더가 구워진다"
  else
    ok "$2 의 .dockerignore 가 scripts/ 를 막지 않는다"
  fi
  if grep -qE '^\.next/?$' "$DIG" 2>/dev/null; then
    ok "$2 의 .dockerignore 가 .next 를 막는다 (개발 서버를 띄워 둔 채로 구워도 된다)"
  else
    bad "$2 의 .dockerignore 가 .next 를 안 막는다 — 호스트의 .next 가 빌드 문맥에 들어간다"
  fi
}
check_dockerignore "$ASDIR" "A/S"
check_dockerignore "$PODIR" "PO"

# ── ㄹ) 🔴 **늘어난 npm 명령 셋** — 41번이 데인 바로 그 자리 ──────────
#   🔴 「package.json 이 바뀌었나」가 아니라 **「이 이름이 지금 거기 있나」**를
#      센다. 바뀐 줄 수만 세면 **지워진 명령**도 같은 수를 낸다.
printf '\n  ── 늘어난 npm 명령 셋 (안 구우면 그날 Missing script 다)\n'
NPM_SEEN=0; NPM_HIT=0
for s in $NEW_NPM_SCRIPTS; do
  NPM_SEEN=$((NPM_SEEN+1))
  now=$(grep -c "\"$s\"" "$ASDIR/package.json" 2>/dev/null | tr -d ' ')
  was=$(git -C "$ASDIR" show "$AS_BASE:package.json" 2>/dev/null | grep -c "\"$s\"" | tr -d ' ')
  printf '      %-34s 기준 %s → 지금 %s\n' "$s" "${was:-?}" "${now:-?}"
  if [ "${now:-0}" -ge 1 ] 2>/dev/null && [ "${was:-1}" = "0" ]; then NPM_HIT=$((NPM_HIT+1)); fi
done
if [ "$NPM_SEEN" = "3" ]; then ok "명령 셋을 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
else bad "명령을 ${NPM_SEEN}개만 봤다 — 셋을 기대했다. 목록이 깨졌다"; fi
if [ "$NPM_HIT" = "3" ]; then
  ok "셋 다 **기준판에 없고 지금 판에 있다** — 도구를 구울 첫째 까닭이다(41번 전례)"
else
  bad "기준에 없고 지금 있는 명령이 ${NPM_HIT}/3 개다 — 적어 둔 전제가 깨졌다. 머리말 ㄱ 을 다시 재세요"
  doubt
fi
# 🔵 그리고 그 셋이 가리키는 **파일**이 저장소에 있어야 담긴다.
for f in scripts/check-target-shipment-missing.ts \
         scripts/check-due-date-inverted.ts \
         scripts/check-requested-due-date-sync.ts \
         scripts/lib/requested-due-date-sync-survey.ts; do
  if [ -s "$ASDIR/$f" ]; then ok "$f 가 저장소에 있다"
  else bad "$f 가 없다 — 명령은 늘었는데 담을 파일이 없다"; fi
done

# ── ㅁ) 🔵 백필 도구 파일 셋 — 43~47번이 넣은 줄, **그대로 둔다** ─────
#   이번 판에서 한 글자도 안 바뀌었지만, 여전히 이미지에 있어야 백필을 부를 수 있다.
for f in scripts/backfill-kyosan-used-parts.ts \
         scripts/lib/kyosan-used-parts-backfill.ts \
         scripts/lib/kyosan-used-parts-backfill-plan.ts; do
  if [ -s "$ASDIR/$f" ]; then ok "$f 가 저장소에 있다"
  else bad "$f 가 없다 — 담을 것이 없다"; fi
done

# ── ㅂ) 🔴 **도구 닫힘 안의 이름난 파일 열아홉 중 몇이 바뀌었나** ─────
#   🔴 이것이 둘째 까닭이다 — 1개 이상이면 「부르니까 굽는다」다.
#   🔵 앞의 열은 **47번이 적어 둔 그 열**이고 한 줄도 안 뺐다. 2026-10-30 에
#      넓힌 닫힘(222개)으로 다시 재어 **열 다 들어 있음**을 확인했다.
#   🔵 뒤의 아홉은 **이번 판에 닫힘 안에서 바뀐 바로 그 아홉**이다.
#   🔴 **used-part-display.ts 는 여기 없다.** 45번이 바로잡은 그대로 — 그 파일은
#      닫힘 **밖**이다(222개로 넓혀 재도 안 나온다). 넣으면 셈이 부풀려진다.
#   🔵 「그 파일이 아직 저장소에 있나」 가드를 **그대로 둔다** — 이름이 바뀌었는데
#      0 이 나와 「안 바뀌었다」로 조용히 지나가는 길을 막는다.
printf '\n  ── 도구 닫힘(222개) 안의 이름난 파일 열아홉\n'
TOOLS_CALLED="scripts/backfill-kyosan-used-parts.ts scripts/lib/kyosan-used-parts-backfill.ts scripts/lib/kyosan-used-parts-backfill-plan.ts src/lib/db/connection.ts src/lib/auth/repair-case-used-parts-authorization.ts src/lib/db/queries/repair-case-used-parts.ts src/lib/domain/inventory-gateway.ts src/lib/server/inventory-gateway.ts src/lib/kyosan/parts-detail-sheet.ts src/lib/kyosan/report-preview.ts scripts/check-due-date-inverted.ts scripts/check-requested-due-date-sync.ts scripts/check-target-shipment-missing.ts scripts/lib/requested-due-date-sync-survey.ts src/lib/db/queries/repair-case-due-date-inverted-notifications.ts src/lib/db/queries/repair-case-target-shipment-notifications.ts src/lib/domain/due-date-inversion.ts src/lib/domain/notifications.ts src/lib/domain/requested-due-date-link.ts"
CALLED_HIT=0
CALLED_SEEN=0
for f in $TOOLS_CALLED; do
  CALLED_SEEN=$((CALLED_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 저장소에 없다 — **도구 닫힘 목록이 낡았다.** 닫힘을 다시 재세요"
    continue
  fi
  if git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- "$f" 2>/dev/null | grep -q .; then
    CALLED_HIT=$((CALLED_HIT+1)); say "🔴 바뀌었다 · 도구가 부른다 — $f"
  fi
done
say "닫힘의 이름난 파일 ${CALLED_SEEN}개를 봤고, 그중 바뀐 것 ${CALLED_HIT}개 (적어 둔 수는 $TOOLS_CALLED_WANT)"
if [ "$CALLED_SEEN" = "19" ]; then
  ok "닫힘 목록 열아홉을 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
else
  bad "닫힘 목록을 ${CALLED_SEEN}개만 봤다 — 열아홉을 기대했다. 목록이 깨졌다"
fi
if isnum "${CALLED_HIT:-}" && [ "${CALLED_HIT:-0}" -ge 1 ]; then
  ok "도구가 부르는 파일이 ${CALLED_HIT}개 바뀌었다 — **부르니까 굽는다**(머리말 ㄴ)"
else
  # 🔵 ⚠️ 다. 0 이 나와도 「굽지 마라」는 뜻은 아니다 — 늘어난 명령 셋(위 ㄹ)만으로도
  #    굽는 까닭이 선다. 다만 적어 둔 실측이 낡았다는 뜻이라 사람이 봐야 한다.
  note "도구가 부르는 길에서 바뀐 파일이 0개다 — ${TOOLS_CALLED_WANT}개를 적어 두었다. 머리말 ㄴ 의 실측이 낡았다. 사람이 보세요"
fi
if [ "${CALLED_HIT:-x}" != "$TOOLS_CALLED_WANT" ]; then
  note "바뀐 것이 ${CALLED_HIT:-?}개다 — 적어 둔 것은 ${TOOLS_CALLED_WANT}개다. 커밋이 더 쌓였는지 사람이 보세요"
fi

# ── ㅅ) 🔴 **「담기는 것」으로도 센다** (39번에 넓혀 둔 잣대) ──────────
TOOLS_PATHS="scripts/ src/ package.json drizzle.config.ts tsconfig.json vendor/"
TOOLS_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | wc -l | tr -d ' ')
PKG_LINES=$(git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | wc -l | tr -d ' ')
printf '\n  ── 담기는 것으로 세기\n'
say "tools 스테이지가 담는 것 중 달라진 파일 ${TOOLS_CHANGED:-못 쟀다}개 · 그중 package.json 의 diff 는 ${PKG_LINES:-못 쟀다}줄"
if isnum "${TOOLS_CHANGED:-}" && [ "${TOOLS_CHANGED:-0}" -ge 1 ]; then
  ok "도구를 구울 셋째 까닭이 있다 — 기준 $AS_BASE 이후 달라진 파일 ${TOOLS_CHANGED}개 (적어 둔 수는 $TOOLS_CHANGED_WANT)"
else
  bad "달라진 파일이 ${TOOLS_CHANGED:-못 쟀다}개다 — 전제가 깨졌으니 멈추고 알릴 것"
  doubt
fi
if [ "${TOOLS_CHANGED:-x}" != "$TOOLS_CHANGED_WANT" ]; then
  note "달라진 파일이 ${TOOLS_CHANGED:-?}개다 — 적어 둔 것은 ${TOOLS_CHANGED_WANT}개다. 커밋이 더 쌓였는지 사람이 보세요"
fi

# ── ㅇ) 🔵 **달라진 파일 목록이 적어 둔 서른다섯과 글자 그대로 같은가** ─
#   🔵 ⚠️ 로만 센다. 굽기로 했으므로 목록이 달라져도 굽는 판정은 안 흔들린다.
#      흔들리는 것은 **머리말의 실측과 48-deploy.sh 꼬리말의 「볼 곳」**이다.
#      🔴 **재기는 그대로 잰다 — 뺀 검사가 아니다.**
#   🔴 **따옴표로 감싼 여러 줄 변수**로 둔다 — 이번 목록에는 대괄호와 괄호가 있다
#      (src/app/(app)/repair-cases/[id]/page.tsx). 따옴표 없이 펼치면 셸이 글자
#      묶음 패턴으로 읽는다.
TOOLS_CHANGED_LIST='
package.json
scripts/check-due-date-inverted.ts
scripts/check-requested-due-date-sync.ts
scripts/check-target-shipment-missing.ts
scripts/lib/requested-due-date-sync-survey.test.ts
scripts/lib/requested-due-date-sync-survey.ts
scripts/test-lists/components.txt
scripts/test-lists/unit.txt
src/app/(app)/repair-cases/[id]/page.tsx
src/components/domestic-orders/DomesticOrderListScreen.tsx
src/components/domestic-orders/domestic-order-due-date-inversion.test.ts
src/components/domestic-orders/domestic-order-inline-cells.test.ts
src/components/layout/NotificationBell.test.tsx
src/components/repair-cases/detail/IntakeInfoSection.tsx
src/components/repair-cases/detail/RepairCaseDetailView.tsx
src/components/repair-cases/detail/due-date-inversion-note.test.ts
src/components/repair-cases/due-date-near.ts
src/lib/db/queries/domestic-orders.integration.test.ts
src/lib/db/queries/domestic-orders.ts
src/lib/db/queries/notification-settings.integration.test.ts
src/lib/db/queries/notifications.ts
src/lib/db/queries/repair-case-due-date-inverted-notifications.ts
src/lib/db/queries/repair-case-target-shipment-notifications.ts
src/lib/domain/due-date-inversion.test.ts
src/lib/domain/due-date-inversion.ts
src/lib/domain/due-date-inverted-notification.test.ts
src/lib/domain/notification-acknowledgement.test.ts
src/lib/domain/notification-bell-items.test.ts
src/lib/domain/notification-settings.test.ts
src/lib/domain/notification-settings.ts
src/lib/domain/notifications.test.ts
src/lib/domain/notifications.ts
src/lib/domain/requested-due-date-link.test.ts
src/lib/domain/requested-due-date-link.ts
src/lib/domain/target-shipment-notification.test.ts
'
WANT_LIST=$(printf '%s\n' "$TOOLS_CHANGED_LIST" | grep -v '^[[:space:]]*$' | sort)
GOT_LIST=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | sort)
if [ -z "${GOT_LIST:-}" ]; then
  unk "A/S 에서 달라진 파일 목록" "git diff 가 아무것도 안 돌려줬다 — 기준 SHA 를 보세요"
elif [ "$GOT_LIST" = "$WANT_LIST" ]; then
  ok "A/S 에서 달라진 파일이 **적어 둔 서른다섯 그대로**다 — 2026-10-30 의 닫힘 실측이 이 커밋들을 덮는다"
else
  note "달라진 파일이 적어 둔 서른다섯과 **다르다** — 굽는 것은 그대로 굽되, 머리말의 닫힘 실측과 48-deploy.sh 꼬리말을 사람이 다시 보세요"
  say "🔵 닫힘을 다시 재는 법은 이 파일 머리말에 명령 네 줄로 적어 두었다."
  say "── 적어 둔 것에 없는데 바뀐 것"
  printf '%s\n' "$GOT_LIST" | grep -vxF -f <(printf '%s\n' "$WANT_LIST") | head -12 | sed 's/^/      /'
  say "── 적어 두었는데 안 바뀐 것"
  printf '%s\n' "$WANT_LIST" | grep -vxF -f <(printf '%s\n' "$GOT_LIST") | head -12 | sed 's/^/      /'
fi

# ── ㅈ) 🔵 PO 쪽에서 달라진 파일 — 열넷이어야 한다 ───────────────────
#   🔵 ⚠️ 로만 센다. PO 는 도구가 없으므로 이 수가 굽는 판정을 흔들지 않는다 —
#      흔들리는 것은 꼬리말의 「볼 곳」이다.
PO_CHANGED=$(git -C "$PODIR" diff --name-only "$PO_BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
say "PO 에서 달라진 파일 ${PO_CHANGED:-못 쟀다}개 (적어 둔 수는 14)"
if [ "${PO_CHANGED:-x}" = "14" ]; then
  ok "PO 에서 달라진 파일이 적어 둔 열넷 그대로다"
elif isnum "${PO_CHANGED:-}" && [ "${PO_CHANGED:-0}" -ge 1 ]; then
  note "PO 에서 달라진 파일이 ${PO_CHANGED}개다 — 열넷을 적어 두었다. 커밋이 더 쌓였는지 사람이 보세요"
  git -C "$PODIR" diff --name-only "$PO_BASE..HEAD" 2>/dev/null | head -16 | sed 's/^/      /'
else
  bad "PO 에서 달라진 파일이 ${PO_CHANGED:-못 쟀다}개다 — 구울 까닭이 없다. 기준 SHA 를 보세요"
  doubt
fi

# ── 6. 태그가 이미 있나 ───────────────────────────────────────────────
printf '\n== 6. 새 태그가 이미 있나\n'
printf '%s\n' "🔵 있으면 **덮어쓴다** — 같은 커밋이면 같은 것이 나오므로 해롭지 않다."
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  rest=${row#*|}; rest=${rest#*|}; TAG=${rest%%|*}
  if docker image inspect "$TAG" >/dev/null 2>&1; then note "$TAG — 이미 있다 (덮어쓴다)"
  else ok "$TAG — 아직 없다"; fi
done
# 🔵 **되돌릴 판이 개발 PC 에 남아 있는가** — NAS 쪽은 48-deploy.sh 가 따로 센다.
for t in dss-as:4.0 dss-as-tools:7 dss-po:0.7; do
  if docker image inspect "$t" >/dev/null 2>&1; then say "🔵 옛 판 $t 가 개발 PC 에 있다"
  else say "🔵 옛 판 $t 가 개발 PC 에 없다 — NAS 쪽에 있으면 되돌리기는 된다"; fi
done

# ── 7. tar 셋을 둘 자리 ──────────────────────────────────────────────
printf '\n== 7. tar 셋을 둘 자리\n'
if [ "$MODE" = "--go" ]; then
  mkdir -p "$OUT" 2>/dev/null
fi
if [ -d "$OUT" ]; then ok "$OUT 가 있다"
elif [ "$MODE" = "--check" ]; then note "$OUT 가 아직 없다 (--go 가 만든다)"
else bad "$OUT 를 못 만들었다"; fi
# 🔵 tar 셋이면 450MB 쯤이다. 두 배를 여유로 본다.
FREEKB=$(df -Pk "$(dirname "$OUT")" 2>/dev/null | awk 'NR==2 {print $4}')
if isnum "${FREEKB:-}"; then
  say "남은 자리 $((FREEKB / 1024))MB (tar 셋이 약 450MB 다)"
  if [ "$FREEKB" -ge 1000000 ]; then ok "자리가 넉넉하다"
  else bad "자리가 모자란다 — 1GB 이상을 권한다"; fi
else
  unk "남은 자리" "df 가 수를 안 돌려줬다"
fi

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
if [ "$FAIL" != "0" ] || [ "$UNK" != "0" ]; then
  printf '%s\n' "🔴 멈춘다 — 위 ✗ / ? 를 먼저 보세요. **아무것도 안 구웠다.**"
  exit 1
fi
if [ "$MODE" = "--check" ]; then
  printf '%s\n' "🔵 **아무것도 안 구웠다.** 전부 통과했으니 이어서: --go"
  exit 0
fi

# ══ 굽기 ══════════════════════════════════════════════════════════════
printf '\n%s\n' "════════ 굽는다 (셋) ════════"
BUILT=0; BFAIL=0; TARTABLE=""
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}
  rest=${rest#*|}; BASE=${rest%%|*}; rest=${rest#*|}; TGT=${rest%%|*}
  rest=${rest#*|}; WANTMIG=${rest%%|*}; rest=${rest#*|}; WANTN=${rest%%|*}
  rest=${rest#*|}; PREVSZ=${rest%%|*}; rest=${rest#*|}; PREVTAR=${rest%%|*}
  DIR="$DEV/$REPO"
  FILE=$(tar_name "$TAG")
  LOG="$OUT/build-$(printf '%s' "$TAG" | tr ':' '-').log"
  printf '\n── %s  (%s)\n' "$TAG" "$REPO"

  # 🔴 도구 이미지만 --target tools 다. 안 주면 **runner 가 구워지고** 그 안에는
  #    scripts/ 도 package.json 도 없어 오류 없이 쓸모없는 이미지가 된다
  #    (RF_Service_System/Dockerfile 은 tools 스테이지를 runner **앞에** 둔다 —
  #    --target 없이 구우면 마지막 스테이지인 runner 가 기본값이 된다).
  if [ "$TGT" = "-" ]; then
    printf '    스테이지: 기본(runner)\n'
    ( cd "$DIR" && docker build -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG" | tail -3
    RC=${PIPESTATUS[0]}
  else
    printf '    스테이지: --target %s\n' "$TGT"
    ( cd "$DIR" && docker build --target "$TGT" -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG" | tail -3
    RC=${PIPESTATUS[0]}
  fi
  if [ "${RC:-1}" = "0" ]; then
    printf '  ✓ 구웠다\n'
  else
    printf '  ✗ 굽기 실패 — %s 를 보세요\n' "$LOG"; BFAIL=$((BFAIL+1)); continue
  fi

  # 🔴 docker save 는 작업 폴더로 들어가 **상대경로**로 쓴다(tar 의 드라이브 문자 함정).
  if ( cd "$OUT" && docker save "$TAG" -o "$FILE" ) </dev/null; then
    sz=$(stat -c %s "$OUT/$FILE" 2>/dev/null || wc -c < "$OUT/$FILE")
    printf '  ✓ tar %s (%s바이트)\n' "$FILE" "$sz"
  else
    printf '  ✗ tar 내보내기 실패\n'; BFAIL=$((BFAIL+1)); continue
  fi

  # 🔴 tar 의 Config 를 **빌드 로그의 exporting config** 와 맞댄다.
  #    'docker image inspect' 의 .Id 와는 **애초에 다른 값**이다.
  cfg=$(tar_config_id "$OUT/$FILE")
  exp=$(tr -d '\000' < "$LOG" | grep -oE "exporting config sha256:[0-9a-f]+" | tail -1 | grep -oE "sha256:[0-9a-f]+")
  printf '    tar  %s\n' "${cfg:-못 읽음}"
  printf '    로그 %s\n' "${exp:-없음}"
  if [ -n "$cfg" ] && [ -n "$exp" ] && [ "$cfg" = "$exp" ]; then printf '  ✓ 지문이 빌드 로그와 같다\n'
  elif [ -z "$exp" ]; then printf '  ⚠️ 빌드 로그에 exporting config 가 없다 (buildx 판에 따라 안 찍힌다)\n'
  else printf '  ✗ 지문이 다르다\n'; BFAIL=$((BFAIL+1)); continue; fi

  # ── 🔴 크기 견주기 ① — **지난 판 tar 와** ──────────────────────────
  p=$(pct_diff "$sz" "$PREVSZ")
  if [ -n "${p:-}" ]; then
    printf '    지난 판 %s %s바이트 → 이번 %s바이트 (차이 %s%%)\n' "$PREVTAR" "$PREVSZ" "$sz" "$p"
    if [ "$p" -le 25 ]; then printf '  ✓ 지난 판 tar 와 크기가 비슷하다 (차이 %s%% · 25%% 이내)\n' "$p"
    else
      printf '  ✗ 지난 판 tar 와 크기가 %s%% 다르다 — 25%% 이내를 기대했다\n' "$p"
      printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 라이브러리가 늘거나 베이스 이미지가"
      printf '%s\n' "         바뀌면 정상적으로도 이만큼 뜁니다. 까닭을 알면 SITES 표의 여덟째 칸을"
      printf '%s\n' "         고쳐 적으면 됩니다. 모르겠으면 **멈추고 알리세요.**"
      BFAIL=$((BFAIL+1)); continue
    fi
  else
    printf '  ✗ 크기를 못 쟀다 (이번 %s · 지난 판 %s)\n' "${sz:-없음}" "${PREVSZ:-없음}"
    BFAIL=$((BFAIL+1)); continue
  fi

  # ── 🔴 크기 견주기 ② — **그 이미지 자신과** (가지를 둘로 나눈다) ───
  #   🔴 저장소 방식에 따라 기대값이 **다르다.** 한 잣대로 재면 가짜 ✗ 가 난다.
  isz=$(docker image inspect "$TAG" --format '{{.Size}}' 2>/dev/null)
  if isnum "${isz:-}" && [ "${isz:-0}" -gt 0 ]; then
    r=$((sz * 100 / isz))
    printf '    이미지 inspect .Size %s바이트 · tar 는 그 %s%%\n' "$isz" "$r"
    if [ "$r" -ge 90 ] && [ "$r" -le 110 ]; then
      printf '  ✓ tar 가 이미지 내용 크기와 거의 같다 (%s%% — containerd 저장소다)\n' "$r"
    elif [ "$r" -ge 10 ] && [ "$r" -le 45 ]; then
      printf '  ✓ tar 가 이미지의 1/4 쯤이다 (%s%% — 고전 저장소다)\n' "$r"
    else
      printf '  ✗ tar 가 이미지의 %s%% 다 — 90~110%% 나 10~45%% 를 기대했다\n' "$r"
      printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 이 비는 docker 의 저장소 방식이"
      printf '%s\n' "         정합니다(머리말의 크기 견주기 ②)."
      BFAIL=$((BFAIL+1)); continue
    fi
  else
    printf '  ? 이미지 크기를 못 쟀다 — docker image inspect 가 수를 안 돌려줬다\n'
    BFAIL=$((BFAIL+1)); continue
  fi

  m5=$(md5sum "$OUT/$FILE" | awk '{print $1}')
  printf '    md5  %s\n' "$m5"
  TARTABLE="$TARTABLE$FILE|$sz|$m5|${cfg:-없음}
"
  BUILT=$((BUILT+1))

  # ── 🔴 앱 이미지 둘 — **runner 가 맞는가**를 한 줄로 센다 ──────────
  #   🔵 47번은 앱 이미지 안을 아예 안 쟀다(「NAS 에서 실제로 떠서 응답하는지가
  #      더 센 신호다」). 그 말은 지금도 맞다 — 그래서 **한 가지만** 본다:
  #      standalone 의 /app/server.js 가 있는가. 없으면 그 이미지는
  #      'node server.js' 를 모르고 **뜨는 순간 죽는다.**
  #   🔴 A/S 는 Dockerfile 이 tools 를 runner **앞에** 두어 기본값이 runner 지만,
  #      누가 스테이지를 뒤에 하나 더 붙이면 조용히 바뀐다. 그 자리를 막는 줄이다.
  if [ "$KEY" = as ] || [ "$KEY" = po ]; then
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/server.js && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '    /app/server.js: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ runner 스테이지가 맞다 (node server.js 를 안다)\n'
    else printf '  ✗ /app/server.js 가 없다 — **runner 가 아닌 것을 구웠다.** 올리지 마세요\n'; BFAIL=$((BFAIL+1)); fi
  fi

  # 🔴 A/S 도구는 구운 뒤 **이미지 안**을 다시 센다 — 겉이 아니라 결과.
  if [ "$KEY" = "astools" ]; then
    printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TAG"
    IMGFAIL=0
    # ① runner 가 아니라 tools 인가 — runner 에는 /app/package.json 이 없다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '      /app/package.json: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tools 스테이지가 맞다\n'
    else printf '  ✗ /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다\n'; IMGFAIL=1; fi
    # ② 🔴 **늘어난 npm 명령 셋이 이미지 안 package.json 에 있는가.**
    #    🔴 41번이 데인 자리를 이미지 안에서 직접 센다. 이름은 전부 ASCII 다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "3" ]; then printf '  ✓ 늘어난 npm 명령 셋이 이미지 안에 있다 (Missing script 가 안 난다)\n'
    else printf '  ✗ 명령이 %s/3 개다 — **옛 package.json 이 담겼다.** 그날 npm error Missing script 가 난다\n' "${got:-0}"; IMGFAIL=1; fi
    # ③ 🔴 **닫힘 안에서 바뀐 아홉이 다 담겼는가.** 하나라도 없으면 ✗.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts /app/src/lib/db/queries/repair-case-due-date-inverted-notifications.ts /app/src/lib/db/queries/repair-case-target-shipment-notifications.ts /app/src/lib/domain/due-date-inversion.ts /app/src/lib/domain/notifications.ts /app/src/lib/domain/requested-due-date-link.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "9" ]; then printf '  ✓ 닫힘 안에서 바뀐 아홉이 다 들어갔다\n'
    else printf '  ✗ 아홉 중 %s개만 들어갔다 — scripts/ 나 src/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
    # ④ 백필 도구 파일 셋 — 43~47번 것 그대로. 이번 판에 안 바뀌었지만 있어야 부른다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts /app/scripts/lib/kyosan-used-parts-backfill-plan.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "3" ]; then printf '  ✓ 백필 도구 파일 셋이 다 들어갔다\n'
    else printf '  ✗ 백필 도구 파일이 %s/3 개다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
    # ⑤ 🔴 **그 src/ 가 '이번 판' 인가 — 글자로 센다.** ③ 은 「있나」만 본다.
    #    🔵 셋 중 앞의 둘은 **이번 판에 새로 생긴 파일**이라 ③ 이 이미 갈라 주지만,
    #       셋째(notifications.ts)는 **옛날부터 있던 파일**이라 ③ 이 통과해도 낡은
    #       판이 담길 수 있다. 그 자리를 막는 것이 이 단계다.
    #    🔵 셋 다 기준 3bde67e 판에는 **0번** 나오고 지금 판에는 나온다
    #       (2026-10-30 git show 로 파일마다 세어 확인: 0 → 38 · 0 → 5 · 0 → 3).
    #    🔴 이름은 전부 **ASCII** 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for pair in "isRepairCaseDueDateInverted /app/src/lib/domain/due-date-inversion.ts" "countDueDateInversionStages /app/src/lib/db/queries/repair-case-due-date-inverted-notifications.ts" "REPAIR_CASE_TARGET_SHIPMENT_MISSING /app/src/lib/domain/notifications.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "3" ]; then printf '  ✓ 이번 판의 이름 셋이 이미지 안에 있다 (옛 src/ 가 아니다)\n'
    else printf '  ✗ 이번 판의 이름이 %s/3 개다 — **옛 src/ 가 담겼다.** 캐시를 의심하세요\n' "${got:-0}"; IMGFAIL=1; fi
    # ⑥ tsx 가 있는가 — 이 도구는 tsx 로만 돈다(운영 이미지에는 없는 devDependency다).
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '      /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tsx 가 있다\n'
    else printf '  ✗ tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
    # ⑦ 🔴 **값을 받아 본다 — 새 명령을 npm 으로 실제로 부른다.**
    #    DATABASE_URL 을 안 준다. 그 파일이 1줄에서 './load-env' 를, 3줄에서
    #    '../src/lib/db/connection' 을 정적 import 하고 connection.ts 가 모듈 맨
    #    위에서 동기적으로 던진다. **DB 에는 한 글자도 안 닿는다.**
    #    🔴 'node …' 가 아니라 **'npm run …'** 으로 부르는 것이 중요하다 —
    #       41번의 실패 모양이 'npm error Missing script' 였고, 그것은 node 로
    #       직접 부르면 **영영 안 드러난다.**
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'cd /app && npm run check:due-date-inverted 2>&1 | head -40' 2>&1 | tr -d '\r')
    if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
      printf '  ✗ **npm error Missing script** — 41번과 같은 실패다. package.json 이 옛 판이다\n'
      printf '%s\n' "$v" | head -20 | sed 's/^/      /'
      IMGFAIL=1
    elif printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
      printf '  ✓ npm run check:due-date-inverted 가 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)\n'
    elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
      printf '  ✗ 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다\n'
      printf '%s\n' "$v" | head -20 | sed 's/^/      /'
      IMGFAIL=1
    else
      printf '  ? 기대한 답이 아니다 — 아래 20줄을 사람이 보세요\n'
      printf '%s\n' "$v" | head -20 | sed 's/^/      /'
      IMGFAIL=1
    fi
    # ⑧ 🔵 백필도 여전히 서는가 — 43~47번이 재던 그 줄이다. **빼지 않는다.**
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'cd /app && node --conditions=react-server --import tsx scripts/backfill-kyosan-used-parts.ts 2>&1 | head -40' 2>&1 | tr -d '\r')
    if printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
      printf '  ✓ 백필도 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)\n'
    elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
      printf '  ✗ 백필이 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다\n'
      printf '%s\n' "$v" | head -20 | sed 's/^/      /'
      IMGFAIL=1
    else
      printf '  ? 기대한 답이 아니다 — 아래 20줄을 사람이 보세요\n'
      printf '%s\n' "$v" | head -20 | sed 's/^/      /'
      IMGFAIL=1
    fi
    # ⑨ 🔵 이미지 안의 drizzle/ 은 **비어 있어야** 한다 — 볼륨으로 붙는 자리다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d '\r')
    printf '      /app/drizzle 안 .sql: %s개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)\n' "${v:-?}"
    if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ drizzle/ 이 비어 있다 (이미지에 안 굽는다)\n'
    else printf '  ✗ drizzle/ 에 .sql 이 들었다 — 이미지가 28MB 를 더 메고 다닌다\n'; IMGFAIL=1; fi
    if [ "$IMGFAIL" != 0 ]; then
      printf '%s\n' "🔴 이미지 안이 온전하지 않다. 올리지 마세요."
      BFAIL=$((BFAIL+1))
    fi
  fi
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  구운 것 %s / %s · 실패 %s\n' "$BUILT" "$HOWMANY" "$BFAIL"
if [ "$BFAIL" != "0" ]; then printf '%s\n' "🔴 실패가 있다. 위를 보세요."; exit 1; fi

# ══ 🔴 48-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 48-deploy.sh 의 TARS 는 **이름만 적힌 채로** 올라간다. 지문 칸이 비어 있으면
#     그 파일이 ? 로 세고 「옮기다 깨진 것」만 잡는다 — 아래 **세 줄**로 그 세 줄을
#     통째로 갈아 끼운다. 🔵 마이그레이션 묶음은 이번에도 없다.
printf '\n%s\n' "════════ 48-deploy.sh 의 TARS 에 붙여 넣을 것 ════════"
printf '%s' "$TARTABLE"
printf '%s\n' "  🔴 위 세 줄로 TARS 의 세 줄을 통째로 갈아 끼운다. 🔵 as-migrations.tar.gz 는 이번에도 없다."

printf '\n%s\n' "✅ 셋 다 구웠다. tar · 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'
printf '\n%s\n' "🔵 다음 — 올릴 곳이 **둘**이다:"
printf '%s\n' "    · 이미지 tar 셋 → NAS 의 /volume1/dss/images/"
printf '%s\n' "      (dss-as-4.1.tar · dss-as-tools-8.tar · dss-po-0.8.tar)"
printf '%s\n' "    · 48-deploy.sh 자신 → NAS 의 /volume1/dss/setup/  (md5 를 맞춘다)"
printf '%s\n' ""
printf '%s\n' "  (개발 PC · PowerShell — 🔴 tar 에 C: 를 주지 마세요. 폴더로 **들어가서** 보냅니다)"
printf '%s\n' "    cd $(to_win "$OUT")"
printf '%s\n' "    scp -O dss-as-4.1.tar dss-as-tools-8.tar dss-po-0.8.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "    cd C:\\Users\\희만\\Desktop\\Development"
printf '%s\n' "    scp -O dss-deploy\\nas\\setup\\48-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "    Get-FileHash -Algorithm MD5 dss-deploy\\nas\\setup\\48-deploy.sh"
printf '%s\n' "  🔴 **scp 에는 -O 를 붙입니다.** DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' "🔵 **마이그레이션 묶음은 없다** — 이번 판도 두 저장소 모두 drizzle/ 이 0건이다."
printf '%s\n' "────────────────────────────────────────────────────────────"
