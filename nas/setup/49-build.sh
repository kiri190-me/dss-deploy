#!/bin/bash
# dss-deploy/nas/setup/49-build.sh — 마흔여섯째 배포 · 이미지 굽기 (2026-10-30)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · Git Bash) ────────────────────────────────────
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/49-build.sh" --check
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/49-build.sh" --go
#
#   🔵 PowerShell 에서도 돈다 — 2026-10-30 에 48번으로 확인했다:
#     & bash.exe "C:\Users\희만\Desktop\Development\dss-deploy\nas\setup\49-build.sh" --check
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-46):
#     bash .../49-build.sh --go "/d/배포본/_images-46"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다. 47·48번과
#      같은 방식이다 — 지시서를 쓴 쪽은 이 파일을 쓰기만 하고 돌리지 않았다.
#
# ── 이번에 굽는 것 — **저장소 둘, 이미지 셋** ─────────────────────────
#     ① A/S 앱   dss-as:4.1        → **dss-as:4.2**        커밋 3  스테이지 기본(runner)
#     ② A/S 도구 dss-as-tools:8    → **dss-as-tools:9**    커밋 3  🔴 --target tools
#     ③ PO 앱    dss-po:0.8        → **dss-po:0.9**        커밋 3  스테이지 기본(runner)
#
#   🔵 **48번(지난 판)과 같은 모양이다** — 저장소 둘, 이미지 셋. 다만 PO 쪽 커밋이
#      하나에서 **셋**으로 늘었다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 기준 SHA — **두 출처를 맞대어 확인했다** (2026-10-30)
# ══════════════════════════════════════════════════════════════════════
#   48번은 지난 판 스크립트에서 역산해야 했다(40번대에 dss-po 가 한 줄도 없었다).
#   이번엔 그럴 필요가 없다 — 48번이 **제 머리말에 무엇을 구웠는지 글자로** 남겼고,
#   그 값이 README 의 기준 SHA 표와 같다. 두 출처를 **둘 다 읽어** 맞대었다:
#
#   ㄱ) **A/S — 3851693.**
#        · dss-deploy/README.md 의 「🔴 기준 SHA … (2026-10-30 갱신)」 표 73줄:
#            | A/S 관리 | RF_Service_System | **4.1** | **3851693** |
#        · 48-build.sh 머리말 「이번 범위의 커밋」의 A/S 마지막 줄이
#            3851693 머리말이 세는 수를 항목 수에 맞춘다
#          — 즉 48번이 실제로 구운 HEAD 가 3851693 이다.
#        · 🔵 지시서의 값과도 **맞았다.**
#
#   ㄴ) **PO — c32358f.**
#        · 같은 README 표 74줄: | PO | dss-po | **0.8** | **c32358f** |
#        · 48-build.sh 머리말의 PO 범위 마지막 줄이
#            c32358f 내자정리에서도 납기 역전을 붉은 날짜와 메모로 알린다
#        · 🔵 지시서의 값과도 **맞았다.**
#
#   🔴 아래 2절이 **merge-base --is-ancestor** 로 둘 다 다시 잰다. 표가 낡았거나
#      가지가 갈렸으면 거기서 ✗ 가 난다 — 머리말의 글이 아니라 저장소가 답한다.
#
# ── 이번 범위의 커밋 — A/S 셋 · PO 셋 ────────────────────────────────
#   A/S  3851693..ac3f713
#     8ae38e3 납기요청일과 고객 요청 납기일을 양방향으로 묶는다
#     05e9806 출하 판정을 제 파일로 옮겨 고리 import 를 끊는다
#     ac3f713 PO 사본도 함께 옮겼다는 사실을 적는다
#   PO   c32358f..9c1b2ef
#     bfb2e95 뒤처진 사본을 A/S 판에 맞춘다 — 빌려 온 곳을 알리는 글자 셋
#     f9349d0 내자정리에서 고친 납기요청일이 수리 건까지 간다
#     9c1b2ef 출하 판정 사본도 shipment-finished 로 옮긴다
#
#   🔵 **두 저장소 사이에 API 계약이 바뀐 자리가 없다**(2026-10-30 실측):
#        git -C RF_Service_System diff --name-only 3851693..ac3f713 -- src/app/api  → 0줄
#        git -C dss-po          diff --name-only c32358f..9c1b2ef  -- src/app/api  → 0줄
#      두 diff 를 'fetch(' · '/api/v1/' · '/api/integration/' 로 훑어도 더하거나
#      지운 줄이 **0줄**이다(양쪽 다). 🔴 **한 방향만 세지 않았다** — PO→A/S 도
#      A/S→PO 도 부르는 자리가 안 바뀌었다.
#   🔴 **이번 판의 이음새는 HTTP 가 아니라 같은 DB 다.** PO 가 repair_cases 를
#      **직접 UPDATE** 한다(dss-po/src/lib/db/mutations/domestic-orders.ts 365줄 —
#      기준판에는 그 줄이 **0번** 나오고 지금 판에 **1번** 나온다. 아래 5절-ㅊ 이
#      그것을 센다). 🔴 **그 권한이 운영에 있는지는 이 스크립트가 못 잰다** —
#      49-deploy.sh --check 가 NAS 에서 값으로 묻는다. 거기서 막히면 PO 에서
#      납기요청일을 저장할 때 오류로 끝난다.
#
# ── 🔴 마이그레이션 — **둘 다 0건이다. 내가 다시 쟀다** ───────────────
#   2026-10-30 실측:
#     git -C RF_Service_System diff --name-only 3851693..ac3f713 -- drizzle/  → **0줄**
#     git -C dss-po          diff --name-only c32358f..9c1b2ef  -- drizzle/  → **0줄**
#   🔴 PO 쪽 0 은 **삼켜진 0 이 아니다** — dss-po 에는 drizzle/ 폴더가 **애초에
#      없다**(2026-09-28 부터. 스키마의 주인은 A/S 하나뿐이다). 아래 4절이
#      「없는 것이 맞다」를 따로 센다.
#   🔴 그래서 **as-migrations.tar.gz 를 만들지도 보내지도 않는다.** NAS 의
#      /volume1/dss/as-migrations 는 39번이 올려 둔 **121 그대로**다.
#   🔵 **이 판에 새 표도 새 칸도 없다.** 이번 일은 **이미 있는 칸 둘을 서로 묶는
#      것**이다(repair_cases.customer_requested_due_date 와
#      domestic_order_due_dates.due_date). 칸을 더하는 일이 아니라 DDL 이 없다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 A/S 도구(dss-as-tools)를 **왜 굽는가** — 잣대 셋 중 **둘**이 굽는다
# ══════════════════════════════════════════════════════════════════════
#   🔵 이 판정이 넉 달 사이 여러 번 어긋났고, 어긋난 자리마다 잣대가 한 칸씩
#      넓어졌다. 이력은 46~48-build.sh 머리말에 길게 적혀 있다. 여기에는
#      **이번 판에서 달라진 것**만 적는다.
#
#   🔴 **이번 판은 48번과 모양이 다르다 — 잣대 ㄱ 이 「굽는다」를 안 준다.**
#      48번은 npm 명령이 셋 늘어서 그것 하나만으로 구울 까닭이 섰다. 이번 판은
#      **package.json 이 0줄 바뀌었다**(2026-10-30 실측). 명령이 안 늘었다.
#      🔴 그래도 **굽는다** — 아래 ㄴ·ㄷ 이 둘 다 「굽는다」다.
#
#   ㄱ) 🔵 **늘어난 npm 명령 — 없다. 그래도 잰다.**
#      git diff 3851693..ac3f713 -- package.json  → **0줄**
#      🔴 재는 까닭은 「안 늘었다」를 확인하려는 것이 아니라 **「사라지지
#         않았는가」**를 보려는 것이다. 48번이 올린 셋
#         (check:target-shipment-missing · check:due-date-inverted ·
#          check:requested-due-date-sync)이 이 판에서 빠지면 그날 tools-as 를
#         부르는 사람이 **npm error Missing script** 를 받는다 — 41번과 같은
#         모양인데 까닭만 반대다(늘어서가 아니라 사라져서).
#      2026-10-30 실측: 셋 다 기준판 **1번** · 지금 판 **1번**. 그대로다.
#
#   ㄴ) 🔴 **도구의 import 닫힘 안에 바뀐 파일이 일곱이다.**
#      🔵 48번이 쓴 펼치개를 **글자 그대로** 다시 썼다(상대경로 · '@/' ·
#         '@dss/core/schema' · '@dss/core/ui/*' · '@dss/ui' 를 따라가고,
#         'export … from' 과 타입 전용 import 까지 따라간다. 주석은 걷어내고 센다).
#      · 🔴 **시작점을 하나로 두지 않았다** — 48번이 남긴 교훈 그대로다.
#        package.json 의 scripts 가 가리키는 scripts/*.ts **전부**(21개)에 백필
#        하나를 더해 **스물둘**에서 폈다.
#            닫힘 **223개** · 못 푼 상대경로 **0개**
#        🔵 48번의 222 에서 하나 늘었다 — 이번에 **새로 생긴**
#           src/lib/domain/shipment-finished.ts 가 닫힘에 들어왔기 때문이다
#           (due-date-inversion.ts 가 그것을 들여온다).
#      · 이번에 바뀐 32개와 맞대면 **일곱이 겹친다**:
#              src/lib/db/queries/repair-case-due-date-inverted-notifications.ts
#              src/lib/db/queries/repair-case-target-shipment-notifications.ts
#              src/lib/domain/due-date-inversion.ts
#              src/lib/domain/notifications.ts
#              src/lib/domain/requested-due-date-link.ts
#              src/lib/domain/shipment-finished.ts        ← 이번에 새로 생긴 파일
#              src/lib/validation/repair-case-update-input.ts
#      · 🔵 **시작점을 백필 하나로 좁혀도 이번엔 0 이 아니다** — 좁은 닫힘 164개에
#        둘이 겹친다(requested-due-date-link.ts · repair-case-update-input.ts).
#        그래도 **좁혀서 재지 않는다**: 좁은 수로는 다섯을 놓치고, 그 다섯에
#        새 파일이 들어 있다. 「시작점을 하나로 두지 마라」는 48번의 교훈이
#        이번 판에서도 **더 많은 참을 준다.**
#      🔴 **used-part-display.ts 는 여전히 닫힘 밖이다**(223개로 재도 안 나온다).
#         45번이 바로잡은 그대로 — 아래 목록에 넣지 마라. 넣으면 셈이 부풀려진다.
#
#   ㄷ) 🔵 **39번에 넓혀 둔 잣대(「tools 스테이지가 담는 것 전부」)로도 굽는다.**
#      Dockerfile 의 tools 스테이지가 담는 것은
#      package.json · tsconfig.json · drizzle.config.ts · scripts/ · src/ · vendor/
#      이고, 이번에 바뀐 **32개가 전부 그 안**이다(scripts/ 3 · src/ 29).
#      **32 > 0** 이라 굽는다.
#
#   🔵 **치르는 값**: tar 하나(224MB)를 더 굽고 올리는 것뿐이다. tools-as 는
#      profiles: [tools] 라 **다시 뜨지도 않는다.**
#
#   🔵 **다음 사람이 같은 판단을 다시 하는 법** — 명령 네 줄이다:
#        ① git -C RF_Service_System diff --name-only <기준SHA>..HEAD
#        ② git -C RF_Service_System diff <기준SHA>..HEAD -- package.json
#           → scripts 에 **줄이 늘었으면 그것만으로 굽는다**(41번).
#           → 🔴 **줄이 0 이어도 「안 굽는다」가 아니다**(이번 판). ③ 으로 간다.
#        ③ package.json 의 scripts 가 가리키는 scripts/*.ts **전부**(+백필)에서
#           import 를 끝까지 펼쳐 닫힘을 만든다. (지금 판에서 223개 · 못 푼 0.)
#        ④ ①과 ③을 맞댄다. **겹치는 것이 하나라도 있으면 굽는다.**
#      🔴 ④ 에서 「겹치긴 하는데 주석만이다」가 나와도 **굽는 쪽**이다(47번 머리말 ㄹ).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 PO 에는 도구 이미지가 **없다** — 짐작이 아니라 쟀다 (2026-10-30 재측정)
# ══════════════════════════════════════════════════════════════════════
#   · dss-po/Dockerfile 의 FROM 은 **셋**이다: deps · builder · runner.
#     'AS tools' 가 한 줄도 없다.
#   · 운영 compose 의 PO 블록 주석도 같은 말을 한다 — 「🔴 **도구 서비스(tools-po)를
#     만들지 않는다.** 이 저장소에는 마이그레이션도 야간 작업도 없다」.
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
#      아니라는 증거다. 🔴 48번의 표를 베끼기만 하지 않고 **여덟을 다시 쟀다.**
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
# ── 🔴 tar 크기를 **두 번** 견준다 (48번 것을 그대로) ─────────────────
#   ① **지난 판 tar 와** 견준다. 적어 둔 값의 출처:
#        dss-as-4.1.tar      132592640  [배포본] 48-deploy.sh 의 TARS
#        dss-as-tools-8.tar  223804416  [배포본] 48-deploy.sh 의 TARS
#        dss-po-0.8.tar       95437824  [배포본] 48-deploy.sh 의 TARS
#      차이가 **25%** 를 넘으면 ✗ 다. 🔵 넘었다고 반드시 잘못된 것은 아니다 —
#      그때는 **사람이 보라는 뜻**이고, 까닭을 알면 그 숫자를 여기 고쳐 적으면 된다.
#   ② **그 이미지 자신과** 견준다. 🔴 여기가 함정이라 가지를 둘로 나눴다:
#      · 이 개발 PC 의 docker 는 **containerd 저장소**를 쓴다. 그래서
#        'docker image inspect --format {{.Size}}' 가 **압축된 내용 크기**를 준다 —
#        2026-10-30 실측으로 dss-as:4.0 은 inspect 132482475 · tar 132502528 이라
#        **거의 같다**(0.02% 차이).
#      · 반면 'docker image ls' 가 보여 주는 601MB 는 **펼친 크기**이고, tar 는
#        그 **1/4쯤**이다. 「584MB 이미지 → 130MB tar」는 그쪽 비다.
#      🔴 **둘 중 어느 저장소인지는 미리 못 정한다.** 그래서 비가 90~110% 면
#         ✓(containerd), 10~45% 면 ✓(고전), 그 밖이면 ✗ 로 센다.
#         한 잣대로 재면 **가짜 ✗** 가 난다 — 「단계마다 기대값이 다르다」.
#   🔴 **tar 지문은 'docker image inspect' 의 .Id 와 맞대지 않는다.** 그것은
#      애초에 다른 값이다. 맞댈 상대는 **빌드 로그의 'exporting config sha256:'** 이다.
#      그걸로 재서 구운 아홉이 전부 ✗ 가 난 적이 있다.
#
# ── 🔴 이 환경의 함정 (36~48-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싸고, 저장소 자리를
#      이 파일의 자리에서 계산한다(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:\… 를 /c/… 로
#      바꾸고, docker save 는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#      🔴 이 파일의 tar/docker save 어디에도 드라이브 문자가 들어가지 않는다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(두 저장소의 .dockerignore 가
#      .next 를 막는다 — 아래 5절이 그것도 잰다). 다만 메모리는 다르다.
#   ④ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다.** 한글을 argv 로 넘기면
#      깨지는 길이 열린다 — 아래 '새 판인가' 검사의 이름 넷은 전부 ASCII 다.
#   ⑤ 🔵 **이번 판의 파일 목록에는 대괄호도 괄호도 없다.** 그래도 목록은
#      **따옴표로 감싼 여러 줄 변수**로만 다룬다 — 다음 판에 다시 생길 자리라
#      48번의 처방을 걷지 않는다.
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

# tar 안 manifest.json 의 Config 지문 (39~48-build.sh 의 것을 글자 그대로)
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
#      표가 낡았다는 뜻이라 사람이 봐야 한다. A/S 셋 · PO 셋이다.
#   🔴 'astools' 는 **같은 저장소**(RF_Service_System)를 --target tools 로 한 번
#      더 굽는 줄이다. 저장소를 세는 자리에서는 이 줄을 건너뛴다(41~48번과 같은
#      처리) — 두 번 세면 ✗ 도 두 번 센다.
#   🔵 여덟째·아홉째 칸은 **지난 판 tar** 다. 출처는 머리말에 적었다.
SITES='
as|RF_Service_System|dss-as:4.2|3851693|-|0|3|132592640|dss-as-4.1.tar
astools|RF_Service_System|dss-as-tools:9|3851693|tools|0|3|223804416|dss-as-tools-8.tar
po|dss-po|dss-po:0.9|c32358f|-|0|3|95437824|dss-po-0.8.tar
'
HOWMANY=3
TOOLS_TAG=dss-as-tools:9

# ── 🔴 기대값과 그 출처 ───────────────────────────────────────────────
#   [저장소] 2026-10-30 개발 PC 의 저장소에서 센 값
AS_SQL_WANT=121       # [저장소] RF_Service_System/drizzle/*.sql — 안 늘어야 한다(0120 까지 그대로)
# 서브모듈 포인터 셋. 🔴 **A/S 와 PO 의 dss-core 가 서로 다르다 — 그것이 지금
#    상태다.** PO 의 8730c94 는 A/S 의 05018b0 의 **조상**이다. 🔴 **이 배포에서
#    맞추지 않는다.** 이번 범위에 vendor/ 변경이 한 줄도 없고(두 diff 모두 0줄),
#    여기서 올리면 재어 보지도 않은 코드가 운영에 따라 들어간다.
#    🔵 세 값 모두 48번과 **같다**(2026-10-30 git submodule status 로 다시 쟀다).
AS_CORE_PIN=05018b077a780922b484a7a539665f35d5207c82
PO_CORE_PIN=8730c9433b4388a038349ab9a11ec633659da782
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425        # 두 저장소가 같은 값이다
# 🔴 5절이 쓰는 기준 SHA. **SITES 표의 넷째 칸과 같은 값이어야 한다** — 41번에서는
#    이 값이 표와 따로 적혀 있어 한쪽만 고치면 조용히 어긋날 자리였다.
AS_BASE=3851693
PO_BASE=c32358f
# 🔵 tools 스테이지가 담는 것 중 달라진 파일 수 — 적어 둔 값(2026-10-30 실측 32).
TOOLS_CHANGED_WANT=32
# 🔵 도구 닫힘(223개) 안에서 바뀐 파일 수 — 적어 둔 값(2026-10-30 실측 7).
TOOLS_CALLED_WANT=7
# 🔵 PO 에서 달라진 파일 수 — 적어 둔 값(2026-10-30 실측 18).
PO_CHANGED_WANT=18
# 🔴 48번이 올린 npm 명령 셋. **이번 판에 안 늘었다** — 재는 까닭은 「사라지지
#    않았는가」다(머리말 ㄱ). 기준판에도 1번, 지금 판에도 1번 나와야 한다.
KEEP_NPM_SCRIPTS="check:target-shipment-missing check:due-date-inverted check:requested-due-date-sync"

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-46"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

printf '%s\n' "마흔여섯째 배포 · 이미지 굽기   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  저장소 뿌리: $DEV"
printf '%s\n' "  tar 셋을 둘 자리: $OUT"
printf '%s\n' "  굽는 것: dss-as:4.2 · dss-as-tools:9 · dss-po:0.9  (저장소 둘 · 이미지 셋)"
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
      printf '%s\n' "         49-deploy.sh 꼬리말의 「볼 곳」과 5절의 파일 목록이다 — 사람이 보세요."
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
  ok "tools 스테이지가 scripts/ 를 담는다 (48번이 올린 도구 셋이 들어가는 유일한 길)"
else
  bad "A/S Dockerfile 이 scripts/ 를 안 담는다 — 도구 셋이 통째로 빠진다"
fi
if grep -qE '^COPY .*package\.json' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 package.json·tsconfig.json 을 담는다 (npm 명령이 들어가는 길)"
else
  bad "A/S Dockerfile 이 package.json 을 안 담는다 — npm run 이 Missing script 로 죽는다"
fi
if grep -qE '^COPY .*src \./src' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 src/ 를 담는다 (닫힘 안에서 바뀐 일곱이 들어가는 길)"
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

# ── ㄹ) 🔴 **npm 명령 셋 — 이번 판에는 「사라지지 않았는가」를 센다** ──
#   🔴 48번은 이 자리에서 「늘었는가」를 쟀고 그것만으로 구울 까닭이 섰다.
#      이번 판은 package.json 이 **0줄** 바뀌었다 — 그 잣대가 「굽는다」를
#      안 준다(머리말 ㄱ). 🔴 **그래도 재기는 잰다.** 재는 뜻이 뒤집혔을 뿐이다:
#      셋 중 하나라도 **사라지면** 그날 tools-as 를 부르는 사람이 Missing script
#      를 받는다 — 41번과 같은 고장인데 까닭만 반대다.
printf '\n  ── 48번이 올린 npm 명령 셋이 **그대로 있는가**\n'
PKG_LINES=$(git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | wc -l | tr -d ' ')
say "package.json 의 diff ${PKG_LINES:-못 쟀다}줄 (적어 둔 값은 0 — 이번 판은 명령이 안 늘었다)"
if [ "${PKG_LINES:-x}" = "0" ]; then
  ok "package.json 이 한 줄도 안 바뀌었다 (잣대 ㄱ 은 이번 판에 「굽는다」를 안 준다 — ㄴ·ㄷ 이 준다)"
else
  note "package.json 이 ${PKG_LINES}줄 바뀌었다 — 0줄을 적어 두었다. **명령이 늘었으면 굽는 까닭이 하나 더 선다**(41번). 아래 diff 를 사람이 보세요"
  git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | head -20 | sed 's/^/      /'
fi
NPM_SEEN=0; NPM_NOW=0; NPM_WAS=0
for s in $KEEP_NPM_SCRIPTS; do
  NPM_SEEN=$((NPM_SEEN+1))
  now=$(grep -c "\"$s\"" "$ASDIR/package.json" 2>/dev/null | tr -d ' ')
  was=$(git -C "$ASDIR" show "$AS_BASE:package.json" 2>/dev/null | grep -c "\"$s\"" | tr -d ' ')
  printf '      %-34s 기준 %s → 지금 %s\n' "$s" "${was:-?}" "${now:-?}"
  if [ "${now:-0}" -ge 1 ] 2>/dev/null; then NPM_NOW=$((NPM_NOW+1)); fi
  if [ "${was:-0}" -ge 1 ] 2>/dev/null; then NPM_WAS=$((NPM_WAS+1)); fi
done
if [ "$NPM_SEEN" = "3" ]; then ok "명령 셋을 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
else bad "명령을 ${NPM_SEEN}개만 봤다 — 셋을 기대했다. 목록이 깨졌다"; fi
if [ "$NPM_NOW" = "3" ]; then
  ok "셋 다 **지금 판 package.json 에 있다** — 도구를 부르는 날 Missing script 가 안 난다"
else
  bad "지금 판에 있는 명령이 ${NPM_NOW}/3 개다 — **사라진 것이 있다.** 그 명령은 올려도 못 부른다"
  doubt
fi
if [ "$NPM_WAS" = "3" ]; then
  ok "셋 다 기준판에도 있었다 (48번이 올린 그대로 — 이번 판에 안 늘었다)"
else
  note "기준판에 있던 명령이 ${NPM_WAS}/3 개다 — 셋을 기대했다. **늘어난 명령이 있으면 41번의 잣대가 되살아난다.** 사람이 보세요"
fi
# 🔵 그리고 그 셋이 가리키는 **파일**이 저장소에 있어야 담긴다.
for f in scripts/check-target-shipment-missing.ts \
         scripts/check-due-date-inverted.ts \
         scripts/check-requested-due-date-sync.ts \
         scripts/lib/requested-due-date-sync-survey.ts; do
  if [ -s "$ASDIR/$f" ]; then ok "$f 가 저장소에 있다"
  else bad "$f 가 없다 — 명령은 있는데 담을 파일이 없다"; fi
done

# ── ㅁ) 🔵 백필 도구 파일 셋 — 43~48번이 넣은 줄, **그대로 둔다** ─────
#   이번 판에서 한 글자도 안 바뀌었지만, 여전히 이미지에 있어야 백필을 부를 수 있다.
for f in scripts/backfill-kyosan-used-parts.ts \
         scripts/lib/kyosan-used-parts-backfill.ts \
         scripts/lib/kyosan-used-parts-backfill-plan.ts; do
  if [ -s "$ASDIR/$f" ]; then ok "$f 가 저장소에 있다"
  else bad "$f 가 없다 — 담을 것이 없다"; fi
done

# ── ㅂ) 🔴 **도구 닫힘 안의 이름난 파일 스물하나 중 몇이 바뀌었나** ───
#   🔴 이것이 **이번 판의 첫째 까닭**이다 — 1개 이상이면 「부르니까 굽는다」다.
#   🔵 앞의 열아홉은 **48번이 적어 둔 그 열아홉**이고 한 줄도 안 뺐다.
#      2026-10-30 에 넓힌 닫힘(223개)으로 다시 재어 **열아홉 다 들어 있음**을
#      확인했다.
#   🔵 뒤의 둘은 **이번 판에 닫힘 안으로 새로 들어온 둘**이다:
#      shipment-finished.ts(이번에 생긴 파일) · repair-case-update-input.ts.
#   🔴 **used-part-display.ts 는 여기 없다.** 45번이 바로잡은 그대로 — 그 파일은
#      닫힘 **밖**이다(223개로 넓혀 재도 안 나온다). 넣으면 셈이 부풀려진다.
#   🔵 「그 파일이 아직 저장소에 있나」 가드를 **그대로 둔다** — 이름이 바뀌었는데
#      0 이 나와 「안 바뀌었다」로 조용히 지나가는 길을 막는다.
printf '\n  ── 도구 닫힘(223개) 안의 이름난 파일 스물하나\n'
TOOLS_CALLED="scripts/backfill-kyosan-used-parts.ts scripts/lib/kyosan-used-parts-backfill.ts scripts/lib/kyosan-used-parts-backfill-plan.ts src/lib/db/connection.ts src/lib/auth/repair-case-used-parts-authorization.ts src/lib/db/queries/repair-case-used-parts.ts src/lib/domain/inventory-gateway.ts src/lib/server/inventory-gateway.ts src/lib/kyosan/parts-detail-sheet.ts src/lib/kyosan/report-preview.ts scripts/check-due-date-inverted.ts scripts/check-requested-due-date-sync.ts scripts/check-target-shipment-missing.ts scripts/lib/requested-due-date-sync-survey.ts src/lib/db/queries/repair-case-due-date-inverted-notifications.ts src/lib/db/queries/repair-case-target-shipment-notifications.ts src/lib/domain/due-date-inversion.ts src/lib/domain/notifications.ts src/lib/domain/requested-due-date-link.ts src/lib/domain/shipment-finished.ts src/lib/validation/repair-case-update-input.ts"
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
if [ "$CALLED_SEEN" = "21" ]; then
  ok "닫힘 목록 스물하나를 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
else
  bad "닫힘 목록을 ${CALLED_SEEN}개만 봤다 — 스물하나를 기대했다. 목록이 깨졌다"
fi
if isnum "${CALLED_HIT:-}" && [ "${CALLED_HIT:-0}" -ge 1 ]; then
  ok "도구가 부르는 파일이 ${CALLED_HIT}개 바뀌었다 — **부르니까 굽는다**(머리말 ㄴ)"
else
  # 🔴 이번 판은 48번과 다르다 — 늘어난 npm 명령이 **없어서** 여기가 0 이면
  #    「굽는다」를 주는 잣대가 ㄷ 하나만 남는다. 그래서 ⚠️ 가 아니라 ✗ 다.
  bad "🔴 도구가 부르는 길에서 바뀐 파일이 0개다 — ${TOOLS_CALLED_WANT}개를 적어 두었다. **머리말 ㄴ 의 실측이 낡았다.** 멈추고 알릴 것"
  doubt
fi
if [ "${CALLED_HIT:-x}" != "$TOOLS_CALLED_WANT" ]; then
  note "바뀐 것이 ${CALLED_HIT:-?}개다 — 적어 둔 것은 ${TOOLS_CALLED_WANT}개다. 커밋이 더 쌓였는지 사람이 보세요"
fi

# ── ㅅ) 🔴 **「담기는 것」으로도 센다** (39번에 넓혀 둔 잣대) ──────────
TOOLS_PATHS="scripts/ src/ package.json drizzle.config.ts tsconfig.json vendor/"
TOOLS_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | wc -l | tr -d ' ')
printf '\n  ── 담기는 것으로 세기\n'
say "tools 스테이지가 담는 것 중 달라진 파일 ${TOOLS_CHANGED:-못 쟀다}개"
if isnum "${TOOLS_CHANGED:-}" && [ "${TOOLS_CHANGED:-0}" -ge 1 ]; then
  ok "도구를 구울 둘째 까닭이 있다 — 기준 $AS_BASE 이후 달라진 파일 ${TOOLS_CHANGED}개 (적어 둔 수는 $TOOLS_CHANGED_WANT)"
else
  bad "달라진 파일이 ${TOOLS_CHANGED:-못 쟀다}개다 — 전제가 깨졌으니 멈추고 알릴 것"
  doubt
fi
if [ "${TOOLS_CHANGED:-x}" != "$TOOLS_CHANGED_WANT" ]; then
  note "달라진 파일이 ${TOOLS_CHANGED:-?}개다 — 적어 둔 것은 ${TOOLS_CHANGED_WANT}개다. 커밋이 더 쌓였는지 사람이 보세요"
fi

# ── ㅇ) 🔵 **달라진 파일 목록이 적어 둔 서른둘과 글자 그대로 같은가** ──
#   🔵 ⚠️ 로만 센다. 굽기로 했으므로 목록이 달라져도 굽는 판정은 안 흔들린다.
#      흔들리는 것은 **머리말의 실측과 49-deploy.sh 꼬리말의 「볼 곳」**이다.
#      🔴 **재기는 그대로 잰다 — 뺀 검사가 아니다.**
#   🔵 이번 목록에는 대괄호도 괄호도 없지만 **따옴표로 감싼 여러 줄 변수**를
#      그대로 쓴다 — 48번의 처방을 걷지 않는다(다음 판에 다시 생길 자리다).
TOOLS_CHANGED_LIST='
scripts/test-lists/components.txt
scripts/test-lists/db.txt
scripts/test-lists/unit.txt
src/components/common/save-popup-screens.test.ts
src/components/domestic-orders/DomesticOrderDueDatesCell.tsx
src/components/domestic-orders/DomesticOrderEditForm.tsx
src/components/domestic-orders/DomesticOrderListScreen.tsx
src/components/domestic-orders/domestic-order-inline-cells.test.ts
src/components/domestic-orders/requested-due-date-link-notice.test.ts
src/components/repair-cases/detail/IntakeInfoSection.tsx
src/components/repair-cases/detail/RepairCaseDetailView.tsx
src/components/repair-cases/detail/edit/IntakeInfoEditForm.tsx
src/components/repair-cases/detail/edit/useSectionEditSubmit.ts
src/components/repair-cases/detail/requested-due-date-link-notice.test.ts
src/lib/db/mutations/domestic-orders.ts
src/lib/db/mutations/repair-cases.ts
src/lib/db/mutations/requested-due-date-link.integration.test.ts
src/lib/db/queries/domestic-orders.ts
src/lib/db/queries/repair-case-due-date-inverted-notifications.ts
src/lib/db/queries/repair-case-due-date-notifications.ts
src/lib/db/queries/repair-case-target-shipment-notifications.ts
src/lib/domain/due-date-inversion.test.ts
src/lib/domain/due-date-inversion.ts
src/lib/domain/due-date-inverted-notification.test.ts
src/lib/domain/notifications.test.ts
src/lib/domain/notifications.ts
src/lib/domain/requested-due-date-link.test.ts
src/lib/domain/requested-due-date-link.ts
src/lib/domain/shipment-finished.test.ts
src/lib/domain/shipment-finished.ts
src/lib/server/actions/domestic-orders.ts
src/lib/validation/repair-case-update-input.ts
'
WANT_LIST=$(printf '%s\n' "$TOOLS_CHANGED_LIST" | grep -v '^[[:space:]]*$' | sort)
GOT_LIST=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | sort)
if [ -z "${GOT_LIST:-}" ]; then
  unk "A/S 에서 달라진 파일 목록" "git diff 가 아무것도 안 돌려줬다 — 기준 SHA 를 보세요"
elif [ "$GOT_LIST" = "$WANT_LIST" ]; then
  ok "A/S 에서 달라진 파일이 **적어 둔 서른둘 그대로**다 — 2026-10-30 의 닫힘 실측이 이 커밋들을 덮는다"
else
  note "달라진 파일이 적어 둔 서른둘과 **다르다** — 굽는 것은 그대로 굽되, 머리말의 닫힘 실측과 49-deploy.sh 꼬리말을 사람이 다시 보세요"
  say "🔵 닫힘을 다시 재는 법은 이 파일 머리말에 명령 네 줄로 적어 두었다."
  say "── 적어 둔 것에 없는데 바뀐 것"
  printf '%s\n' "$GOT_LIST" | grep -vxF -f <(printf '%s\n' "$WANT_LIST") | head -12 | sed 's/^/      /'
  say "── 적어 두었는데 안 바뀐 것"
  printf '%s\n' "$WANT_LIST" | grep -vxF -f <(printf '%s\n' "$GOT_LIST") | head -12 | sed 's/^/      /'
fi

# ── ㅈ) 🔵 PO 쪽에서 달라진 파일 — 열여덟이어야 한다 ─────────────────
#   🔵 ⚠️ 로만 센다. PO 는 도구가 없으므로 이 수가 굽는 판정을 흔들지 않는다 —
#      흔들리는 것은 꼬리말의 「볼 곳」이다.
PO_CHANGED=$(git -C "$PODIR" diff --name-only "$PO_BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
say "PO 에서 달라진 파일 ${PO_CHANGED:-못 쟀다}개 (적어 둔 수는 $PO_CHANGED_WANT)"
if [ "${PO_CHANGED:-x}" = "$PO_CHANGED_WANT" ]; then
  ok "PO 에서 달라진 파일이 적어 둔 열여덟 그대로다"
elif isnum "${PO_CHANGED:-}" && [ "${PO_CHANGED:-0}" -ge 1 ]; then
  note "PO 에서 달라진 파일이 ${PO_CHANGED}개다 — ${PO_CHANGED_WANT}개를 적어 두었다. 커밋이 더 쌓였는지 사람이 보세요"
  git -C "$PODIR" diff --name-only "$PO_BASE..HEAD" 2>/dev/null | head -20 | sed 's/^/      /'
else
  bad "PO 에서 달라진 파일이 ${PO_CHANGED:-못 쟀다}개다 — 구울 까닭이 없다. 기준 SHA 를 보세요"
  doubt
fi

# ── ㅊ) 🔴 **PO 가 수리 건 표에 쓰기 시작했다 — 소스로 못 박는다** ────
#   🔴 이번 판의 핵심 위험이다. PO 는 오늘까지 repair_cases 를 **읽기만** 했다.
#      이제 내자 납기요청일을 고치면 수리 건의 고객 요청 납기일을 **UPDATE** 한다.
#   🔴 **이 스크립트는 운영 권한을 못 잰다**(NAS 에 접속하지 않는다). 여기서 하는
#      일은 「그 위험이 실제로 생겼다」를 **소스에서 못 박아** 49-deploy.sh 의
#      권한 검사가 왜 있는지 다음 사람이 알게 하는 것뿐이다.
#   🔵 기준판 0번 → 지금 판 1번 (2026-10-30 git show 로 세어 확인).
printf '\n  ── PO 가 repair_cases 를 UPDATE 하는가 (이번 판의 핵심 위험)\n'
PO_MUT="src/lib/db/mutations/domestic-orders.ts"
PO_UPD_NOW=$(grep -c 'update(repairCases)' "$PODIR/$PO_MUT" 2>/dev/null | tr -d ' ')
PO_UPD_WAS=$(git -C "$PODIR" show "$PO_BASE:$PO_MUT" 2>/dev/null | grep -c 'update(repairCases)' | tr -d ' ')
say "$PO_MUT — update(repairCases) 기준 ${PO_UPD_WAS:-?}번 → 지금 ${PO_UPD_NOW:-?}번"
if [ "${PO_UPD_NOW:-0}" -ge 1 ] 2>/dev/null; then
  ok "PO 가 repair_cases 에 **쓴다** — 🔴 49-deploy.sh --check 가 NAS 에서 그 권한을 값으로 묻는다"
  say "🔴 운영에서 app-po 의 DB 역할에 repair_cases UPDATE 권한이 없으면, PO 에서"
  say "   납기요청일을 저장할 때 오류로 끝난다. **올리기 전에 --check 로 재세요.**"
else
  bad "🔴 PO 가 repair_cases 를 안 쓴다 — 이번 판의 전제(내자 → 수리 건 한 방향)가 깨졌다. 멈추고 알릴 것"
  doubt
fi
if [ "${PO_UPD_WAS:-x}" = "0" ]; then
  ok "기준판에는 그 줄이 **0번** 나왔다 (오늘 처음 쓰는 것이 맞다)"
else
  note "기준판에도 그 줄이 ${PO_UPD_WAS:-?}번 있었다 — 0번을 적어 두었다. 「오늘 처음」이 아닐 수 있으니 사람이 보세요"
fi

# ── 6. 태그가 이미 있나 ───────────────────────────────────────────────
printf '\n== 6. 새 태그가 이미 있나\n'
printf '%s\n' "🔵 있으면 **덮어쓴다** — 같은 커밋이면 같은 것이 나오므로 해롭지 않다."
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  rest=${row#*|}; rest=${rest#*|}; TAG=${rest%%|*}
  if docker image inspect "$TAG" >/dev/null 2>&1; then note "$TAG — 이미 있다 (덮어쓴다)"
  else ok "$TAG — 아직 없다"; fi
done
# 🔵 **되돌릴 판이 개발 PC 에 남아 있는가** — NAS 쪽은 49-deploy.sh 가 따로 센다.
for t in dss-as:4.1 dss-as-tools:8 dss-po:0.8; do
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
  if [ "$KEY" = as ] || [ "$KEY" = po ]; then
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/server.js && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '    /app/server.js: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ runner 스테이지가 맞다 (node server.js 를 안다)\n'
    else printf '  ✗ /app/server.js 가 없다 — **runner 가 아닌 것을 구웠다.** 올리지 마세요\n'; BFAIL=$((BFAIL+1)); fi
  fi

  # 🔴 **PO 이미지 안에 postgres 모듈이 있는가** — 49-deploy.sh 의 권한 검사가
  #    그 모듈로 묻는다. 없으면 그 검사가 psql 가지로 넘어가는데, 거기서도
  #    못 재면 **이번 판의 핵심 위험을 영영 못 본다.** 그래서 여기서 미리 센다.
  #    🔵 없다고 **굽기를 막지는 않는다**(⚠️). 앱 자신은 standalone 서버로 도는
  #       길이 따로 있고, 못 재는 것은 검사 쪽 사정이다.
  if [ "$KEY" = po ]; then
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/postgres && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '    /app/node_modules/postgres: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ PO 이미지에 postgres 모듈이 있다 (49-deploy.sh 의 권한 검사가 이것으로 묻는다)\n'
    else printf '  ⚠️ PO 이미지에 postgres 모듈이 없다 — 49-deploy.sh 의 권한 검사가 psql 가지로 넘어간다\n'; fi
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
    # ② 🔴 **npm 명령 셋이 이미지 안 package.json 에 있는가.**
    #    🔴 41번이 데인 자리를 이미지 안에서 직접 센다. 이름은 전부 ASCII 다.
    #    🔵 이번 판에는 명령이 안 늘었다 — 그래도 **사라지지 않았는지**는 봐야 한다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "3" ]; then printf '  ✓ npm 명령 셋이 이미지 안에 있다 (Missing script 가 안 난다)\n'
    else printf '  ✗ 명령이 %s/3 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다.** 그날 npm error Missing script 가 난다\n' "${got:-0}"; IMGFAIL=1; fi
    # ③ 🔴 **닫힘 안에서 바뀐 일곱이 다 담겼는가.** 하나라도 없으면 ✗.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/src/lib/db/queries/repair-case-due-date-inverted-notifications.ts /app/src/lib/db/queries/repair-case-target-shipment-notifications.ts /app/src/lib/domain/due-date-inversion.ts /app/src/lib/domain/notifications.ts /app/src/lib/domain/requested-due-date-link.ts /app/src/lib/domain/shipment-finished.ts /app/src/lib/validation/repair-case-update-input.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "7" ]; then printf '  ✓ 닫힘 안에서 바뀐 일곱이 다 들어갔다\n'
    else printf '  ✗ 일곱 중 %s개만 들어갔다 — src/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
    # ④ 🔵 48번이 올린 도구 넷 — **빼지 않는다.** 이번 판에 안 바뀌었지만 있어야 부른다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "4" ]; then printf '  ✓ 48번이 올린 도구 넷이 다 들어갔다\n'
    else printf '  ✗ 도구 파일이 %s/4 개다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
    # ⑤ 백필 도구 파일 셋 — 43~48번 것 그대로. **빼지 않는다.**
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts /app/scripts/lib/kyosan-used-parts-backfill-plan.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "3" ]; then printf '  ✓ 백필 도구 파일 셋이 다 들어갔다\n'
    else printf '  ✗ 백필 도구 파일이 %s/3 개다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
    # ⑥ 🔴 **그 src/ 가 '이번 판' 인가 — 글자로 센다.** ③ 은 「있나」만 본다.
    #    🔵 shipment-finished.ts 는 **이번 판에 새로 생긴 파일**이라 ③ 이 이미
    #       갈라 주지만, 나머지 셋은 **옛날부터 있던 파일**이라 ③ 이 통과해도
    #       낡은 판이 담길 수 있다. 그 자리를 막는 것이 이 단계다.
    #    🔵 넷 다 기준 3851693 판에는 **0번** 나오고 지금 판에는 나온다
    #       (2026-10-30 git show 로 파일마다 세어 확인: 0→2 · 0→7 · 0→1 · 0→1).
    #    🔴 이름은 전부 **ASCII** 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for pair in "shipment-finished /app/src/lib/domain/due-date-inversion.ts" "shipment-finished /app/src/lib/domain/notifications.ts" "requestedDueDateLink /app/src/lib/validation/repair-case-update-input.ts" "resolveRepairCaseDueDateWriteThrough /app/src/lib/domain/requested-due-date-link.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1 $2"; else echo "no  $1 $2"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "4" ]; then printf '  ✓ 이번 판의 이름 넷이 이미지 안에 있다 (옛 src/ 가 아니다)\n'
    else printf '  ✗ 이번 판의 이름이 %s/4 개다 — **옛 src/ 가 담겼다.** 캐시를 의심하세요\n' "${got:-0}"; IMGFAIL=1; fi
    # ⑦ tsx 가 있는가 — 이 도구는 tsx 로만 돈다(운영 이미지에는 없는 devDependency다).
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '      /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tsx 가 있다\n'
    else printf '  ✗ tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
    # ⑧ 🔴 **값을 받아 본다 — 명령 둘을 npm 으로 실제로 부른다.**
    #    DATABASE_URL 을 안 준다. 두 파일이 1줄에서 './load-env' 를, 그 다음 줄에서
    #    '../src/lib/db/connection' 을 정적 import 하고 connection.ts 가 모듈 맨
    #    위에서 동기적으로 던진다. **DB 에는 한 글자도 안 닿는다.**
    #    🔴 'node …' 가 아니라 **'npm run …'** 으로 부르는 것이 중요하다 —
    #       41번의 실패 모양이 'npm error Missing script' 였고, 그것은 node 로
    #       직접 부르면 **영영 안 드러난다.**
    #    🔵 48번은 하나만 불렀다. 이번 판은 **둘**을 부른다 —
    #       check:requested-due-date-sync 가 49-deploy.sh 의 --count 에 새로
    #       들어가므로, 그 명령이 서는지를 여기서 미리 본다.
    for cmdname in check:due-date-inverted check:requested-due-date-sync; do
      v=$(docker run --rm --entrypoint sh "$TAG" -c "cd /app && npm run $cmdname 2>&1 | head -40" 2>&1 | tr -d '\r')
      if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
        printf '  ✗ npm run %s — **Missing script** (41번과 같은 실패다. package.json 이 옛 판이다)\n' "$cmdname"
        printf '%s\n' "$v" | head -20 | sed 's/^/      /'
        IMGFAIL=1
      elif printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
        printf '  ✓ npm run %s 가 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)\n' "$cmdname"
      elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
        printf '  ✗ npm run %s 가 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다\n' "$cmdname"
        printf '%s\n' "$v" | head -20 | sed 's/^/      /'
        IMGFAIL=1
      else
        printf '  ? npm run %s 의 답이 기대와 다르다 — 아래 20줄을 사람이 보세요\n' "$cmdname"
        printf '%s\n' "$v" | head -20 | sed 's/^/      /'
        IMGFAIL=1
      fi
    done
    # ⑨ 🔵 백필도 여전히 서는가 — 43~48번이 재던 그 줄이다. **빼지 않는다.**
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
    # ⑩ 🔵 이미지 안의 drizzle/ 은 **비어 있어야** 한다 — 볼륨으로 붙는 자리다.
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

# ══ 🔴 49-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 49-deploy.sh 의 TARS 는 **이름만 적힌 채로** 올라간다. 지문 칸이 비어 있으면
#     그 파일이 ? 로 세고 「옮기다 깨진 것」만 잡는다 — 아래 **세 줄**로 그 세 줄을
#     통째로 갈아 끼운다. 🔵 마이그레이션 묶음은 이번에도 없다.
printf '\n%s\n' "════════ 49-deploy.sh 의 TARS 에 붙여 넣을 것 ════════"
printf '%s' "$TARTABLE"
printf '%s\n' "  🔴 위 세 줄로 TARS 의 세 줄을 통째로 갈아 끼운다. 🔵 as-migrations.tar.gz 는 이번에도 없다."

printf '\n%s\n' "✅ 셋 다 구웠다. tar · 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'
printf '\n%s\n' "🔵 다음 — 올릴 곳이 **둘**이다:"
printf '%s\n' "    · 이미지 tar 셋 → NAS 의 /volume1/dss/images/"
printf '%s\n' "      (dss-as-4.2.tar · dss-as-tools-9.tar · dss-po-0.9.tar)"
printf '%s\n' "    · 49-deploy.sh 자신 → NAS 의 /volume1/dss/setup/  (md5 를 맞춘다)"
printf '%s\n' ""
printf '%s\n' "  (개발 PC · PowerShell — 🔴 tar 에 C: 를 주지 마세요. 폴더로 **들어가서** 보냅니다)"
printf '%s\n' "    cd $(to_win "$OUT")"
printf '%s\n' "    scp -O dss-as-4.2.tar dss-as-tools-9.tar dss-po-0.9.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "    cd C:\\Users\\희만\\Desktop\\Development"
printf '%s\n' "    scp -O dss-deploy\\nas\\setup\\49-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "    Get-FileHash -Algorithm MD5 dss-deploy\\nas\\setup\\49-deploy.sh"
printf '%s\n' "  🔴 **scp 에는 -O 를 붙입니다.** DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' "🔵 **마이그레이션 묶음은 없다** — 이번 판도 두 저장소 모두 drizzle/ 이 0건이다."
printf '%s\n' "🔴 **올린 뒤 가장 먼저 볼 것**: 49-deploy.sh --check 의 「PO 가 repair_cases 에"
printf '%s\n' "   쓸 수 있는가」 줄입니다. 거기서 ✗ 가 나면 **올리지 마세요** — PO 에서 납기"
printf '%s\n' "   요청일을 저장할 때마다 오류로 끝납니다."
printf '%s\n' "────────────────────────────────────────────────────────────"
