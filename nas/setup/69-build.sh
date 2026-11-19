#!/bin/bash
# dss-deploy/nas/setup/69-build.sh — 예순다섯째 배포 · 이미지 굽기 (2026-11-20)
#
# 🔵 **배포 회차(예순다섯째)와 파일 번호(69)가 어긋나는 것은 이 저장소에서 원래
#    그렇다** — 63번이 쉰아홉째, 64번이 예순째, 65번이 예순한째, 66번이
#    예순두째, 67번이 예순세째, 68번이 예순네째였다. (56번은 2026-11-11 의
#    **양식 전용**이라 회차를 안 먹었다.)
#
# ══════════════════════════════════════════════════════════════════════
# 🔴🔴 **이 파일은 바탕이 둘이다 — 68번의 뼈대 + 62번의 재고 값** (2026-11-19 결정)
# ══════════════════════════════════════════════════════════════════════
#   🔴 **이번은 A/S 가 아니라 재고관리다.** 지난 다섯 판(64~68)이 전부 A/S 였다 —
#      그 전제를 그대로 베끼면 **아래 일곱 자리가 조용히 틀린다**(머리말 ②).
#   · **뼈대 · 절 번호 · 모드 셋 · 표식 재는 법 · 관문** → **68-build.sh** 에서
#     글자 그대로 가져왔다. 모양이 68번과 같다: 집 **하나** + 도구 **하나** +
#     마이그레이션 **0건** + 묶음 **없음**.
#   · **재고관리 고유의 값과 검사** → **62-build.sh**(쉰여덟째 — 재고를 0.6 → 0.7
#     로 올린 **가장 최근 판**)에서 가져왔다: Dockerfile 의 COPY 규칙 · public 이
#     **비어 있다**는 것 · 마이그레이션이 **이미지 안에서** 돈다는 것 · 시험이
#     **글롭 등록**이라는 것 · 지난 판 tar 바이트.
#   🔴 **62번을 통째로 복사하지 않았다** — 그 판은 **집이 여섯**이다. 그 구조를
#      업고 오면 이번 판에 **뜻 없는 분기**가 잔뜩 남고, 다음 판이 그것을 베낀다.
#   🔴 **줄이는 것은 만드는 방법뿐이고 검사는 하나도 안 뺐다**(2026-11-19 결정).
#
#   🔴 **이 파일에 「왜 없는가」를 적어 두는 절 넷** (68·67·65·64·63 이 그렇게 했다 —
#      그 글이 없으면 다음 판이 「원래 없는 절」로 읽는다):
#      · **묶음(as-migrations.tar.gz)을 만드는 절이 없다.** 까닭이 **둘**이다:
#        ㉠ 이번 범위의 drizzle/ 변경이 **0장**이고(4절이 값으로 잰다),
#        ㉡ 🔴 **재고관리는 애초에 묶음을 안 쓴다** — .sql 이 **도구 이미지 안**에
#           구워져 간다(5-ㄱ 의 COPY drizzle 줄이 그 증거다). 볼륨에서 도는 것은
#           **A/S 하나뿐**이다. 🔴 A/S 판을 베낄 때 이 자리를 안 뒤집으면
#           「이미지 안 .sql 은 0장이어야 한다」가 되어 **멀쩡한 재고 도구가 ✗** 가 된다.
#      · **지우는 문장 잣대와 그 표본이 없다**(62번 4-ㄱ). 까닭: 잴 .sql 이 이번
#        범위에 **0장**이다. 🔴 .sql 이 한 장이라도 생기면 **62번에서 그 절부터** 넣어라.
#      · **vendor/dss-core 를 보는 절이 없다.** 까닭: 🔴 **재고관리에는 그 서브모듈이
#        아예 없다**[실측 2026-11-20 — .gitmodules 에 vendor/dss-ui 한 줄뿐이다].
#        A/S 판에는 dss-core 를 보는 절이 **다섯 군데** 있었다 — 그대로 베꼈으면
#        전부 「서브모듈이 없다」로 ✗ 가 났을 자리다.
#      · **도구 이미지 안에서 공용 스키마를 보는 절이 없다.** 까닭: 🔴 **재고 tools
#        스테이지는 vendor/ 를 COPY 하지 않는다**(5-ㄱ 이 값으로 잰다). 대신
#        **없어야 한다**를 값으로 센다(62번이 포털 도구에 쓰던 꼴 그대로).
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · PowerShell 에서 Git Bash 를 부른다) ──────────
#     cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#     & "C:\Program Files\Git\bin\bash.exe" ./69-build.sh --check
#     & "C:\Program Files\Git\bin\bash.exe" ./69-build.sh --go
#
#   🔴 **bash.exe 만 치면 WSL 이 잡힌다**(2026-11-04 에 걸렸다). WSL 에서 돌면
#      도커가 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 내어 ✗ 가 흩어져
#      난다. 단서는 로그의 뿌리 경로가 **/mnt/c/…** 인 것이다 — 0절이 값으로 잰다.
#   🔴 **스크립트에 건네는 경로에는 역슬래시를 쓰지 않는다.** 역슬래시를 주면
#      bash 가 그것을 먹어 "C:Users희만Desktop…" 이 되어 No such file 이 난다.
#
#   둘째 인자로 산출물을 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-65):
#     & "C:\Program Files\Git\bin\bash.exe" ./69-build.sh --go "/d/배포본/_images-65"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다.
#      이 파일을 쓴 쪽은 **한 번도 굽지 않았다** — 재기만 했다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 올리는 것 — 한 줄 요약**
# ══════════════════════════════════════════════════════════════════════
#   [재고관리] **부품의 도번이 맨 아랫줄에 제 줄로 서고, 그 모양을 설정에서 고른다.**
#   ① 🔵 **보이는 자리가 셋이다** — [부품 요청 관리] · [승인 요청건] · **불출 신청
#      팝업**. 셋이 같은 조각(components/stock/RequestItemDetails.tsx)을 쓴다.
#   ② 🔴 **도번이 없는 부품에서는 그 줄이 통째로 안 선다** — 「빈 칸은 안 그린다」가
#      이 화면의 오래된 규칙이다(lib/stock/request-item-detail.ts 머리말).
#   ③ 🔵 **모양은 [설정] → [도번 표시] 에서 고른다**(관리자만). 고르는 것 넷:
#      알약 켬/끔 · 글자 크기 · 글자색 · 알약색. 미는 칸과 색 고르개를 움직이면
#      **저장 없이** 미리보기가 따라 바뀐다.
#   ④ 🔴 **알약을 꺼도 도번은 안 사라진다** — 글자만 커지고 색이 든다. 알약색 칸은
#      흐려지되 **값은 남는다**(다시 켜면 그대로 돌아온다).
#   🔵 **DB 는 한 글자도 안 바뀐다** — 마이그레이션 **0건**. 🔴 까닭: 고른 모양은
#      **이미 있는 app_settings 표**에 열쇠 하나(drawing_no_style)로 들어간다.
#      칸도 표도 더하지 않는다 — 그 표는 「열쇠 하나에 글자 하나」 꼴이다.
#      🔵 69-deploy.sh --count 가 **그 열쇠가 저장돼 있는지**를 배포 전후로 센다.
#         🔴 **배포 직후에는 0줄이 정상이다** — 사람이 저장해야 줄이 생긴다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **68번의 전제 중 이번에 깨지는 것 일곱 — 하나씩 재서 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴🔴 **저장소가 다르다.** RF_Service_System 이 아니라 **dss-inventory** 다.
#      [실측 2026-11-20 · 기준 a160fd9] 가지 main · main == origin/main ·
#      커밋 **1** · 미커밋 0줄.
#
#   ② 🔴 **바뀐 파일이 15장이고, 그중 3장은 두 이미지 어디에도 안 담긴다.**
#      [실측 2026-11-20] src/ **12** · tests/ **3** · scripts/ **0** · drizzle/ **0** ·
#      vendor+.gitmodules **0** · 새 파일 **8** · 지운 파일 **0**.
#      🔴 **tests/ 가 .dockerignore 에 적혀 있다**[실측 — .dockerignore 의 ^tests 1줄].
#         그래서 **빌드 맥락에 아예 안 들어간다** — 「15 중 15」가 아니라 **12** 다
#         (5-ㄹ 의 ㄴ 잣대가 그 수를 쓴다). A/S 는 시험이 src/ 아래에 있어 **담겼다** —
#         그 전제를 베꼈으면 「본 것 12 · 기대 15」로 ✗ 가 나고, 그 ✗ 는 **src/ 가
#         안 담긴 것처럼** 보인다.
#
#   ③ 🔴 **괄호는 둘이고 대괄호는 0이다.**
#        src/app/(app)/layout.tsx
#        src/app/(app)/settings/drawing-no/page.tsx
#      🔴 68번은 **괄호 1 · 대괄호 1**(같은 한 파일)이었다. 🔴 **대괄호가 0이라고
#         세는 줄을 빼지 않았다** — 66번이 더하고 67번이 0인 채로 지켜서 68번에
#         실물이 나온 자리다. 🔵 **다만 68번처럼 「대괄호 때문에 이 길이 중요하다」고
#         적지는 않았다** — 이번 판은 0이다. 그래도 **set -f · grep -Fx 로 목록을
#         넘기는 수법 자체는 그대로** 둔다(괄호가 둘 있고, 글롭 함정은 괄호에도 산다).
#
#   ④ 🔴🔴 **표식을 통째로 갈았다 — 지시받은 글자를 하나하나 다시 셌다.**
#      🔴 **기능 표식은 이번 판에 태어난 DOM id 다:**
#           APPMARK = drawing-no-text-color
#           [실측 2026-11-20] src 안에서 기준 **0파일** → 지금 **1파일**
#             src/components/settings/DrawingNoStyleForm.tsx:61
#               const TEXT_COLOR_ID = "drawing-no-text-color";
#        🔵 이 꼴을 고른 까닭 — **minify 가 못 지운다.** 이것은 **문자열 리터럴**이라
#           이름 바꾸기의 대상이 아니다(변수 이름이었으면 지워진다 — ⑤ 를 보라).
#        🔴 **「주석이 아니다」를 값으로도 보인다**(5-ㅂ-2). [실측] 날것 1파일 →
#           주석을 걷은 뒤 **1파일** · 그중 시험이 아닌 것 **1파일**.
#        🔵 **곁들이 값은 따옴표째다** — 번들이 따옴표를 지키는지 로그에 함께 찍는다.
#           🔴 곁들이는 맨 글자의 **부분집합**이라 맨 글자보다 클 수 없다.
#        🔴 **drawing_no_style(스네이크)은 표식으로 안 쓴다** — DB 열쇠라 소스에서
#           한 자리뿐이고 번들에서 0 이 나와 **진짜 결함처럼 보이는 ✗** 가 난다.
#        🔵 **보조로 함께 잰다**(판정은 하되 번들에는 안 쓴다): settings/drawing-no
#           [실측] 기준 **0파일** → 지금 **4파일**(라우트 경로).
#
#   ⑤ 🔴🔴 **뒷걸음 표식 셋 중 하나는 번들에서 못 센다 — 재는 곳을 갈랐다.**
#      [실측 2026-11-20 · 기준 a160fd9 와 지금을 둘 다 dss-inventory 에서]
#        portal_approval_delegations   쉰여덟째 · 기준 14파일 → 지금 14파일  → **앱 번들**
#        stock_issue_approval_steps    그 앞 판 · 기준 10파일 → 지금 10파일  → **앱 번들**
#        TOOLBAR_BTN_PRIMARY           지난 판  · 기준  1파일 → 지금  1파일  → 🔴 **도구 소스**
#      🔴 **TOOLBAR_BTN_PRIMARY 를 번들 표식으로 쓰지 않는다.** 그것은
#         **모듈 안의 const 이름**이라 minify 가 **이름을 바꾼다** — 번들에서 0 이
#         나오고 그 ✗ 는 진짜 결함처럼 보인다. 🔵 62번이 그것을 **도구 이미지의
#         마지막 커밋 표식**(소스 글자 그대로)으로 썼다 — **그 자리로 되돌렸다.**
#         [실측] src/components/parts/PartsList.tsx 안에서 기준 **2줄** → 지금 **2줄**.
#      🔴 **하나도 빼지 않았다.** 뺀 자리는 다시 넣는 사람이 없다.
#      🔴 **마지막 커밋 표식**(도구 이미지용)도 갈았다:
#           TOOLMARK = DrawingNoLine
#                      in src/components/stock/RequestItemDetails.tsx
#           [실측] 그 **파일 안에서는** 기준 **0줄** → 지금 **4줄**
#         🔵 **새로 생긴 파일을 과녁으로 삼지 않았다**(66·67·68번과 같은 판단) —
#            새 파일이면 「기준 0줄」이 **파일이 없어서 0** 인 것이라 아무것도 안 가른다.
#            🔴 **그 파일이 기준판에도 있었는지도 git 에 직접 묻는다**(5-ㅅ).
#         🔵 4줄 중 **둘이 코드**(import 한 줄 · 그리는 한 줄)이고 **둘이 주석**이다.
#            🔴 도구 이미지는 **소스가 글자 그대로** 들어가므로 주석도 같이 센다 —
#            앱 번들과 달리 여기서는 그것이 맞다.
#
#   ⑥ 🔴 **마이그레이션은 0건인데, 재고는 그 .sql 이 「이미지 안」에 있다.**
#      [실측] 저장소 drizzle/ 에 .sql **28장** · meta/_journal.json 의 idx **28개** ·
#      이번 범위의 drizzle/ 변경 **0줄** · **0028 이 안 생겼다.**
#      🔴 **A/S 판을 베낄 때 가장 위험한 자리다.** A/S 도구 이미지는 drizzle/ 이
#         **비어 있어야** 하고(볼륨이 정본), 재고 도구 이미지는 **28장이 들어 있어야**
#         한다. 기대값이 **정반대**다 — 그대로 베끼면 멀쩡한 이미지가 ✗ 가 된다.
#
#   ⑦ 🔴 **굽는 까닭이 둘이다 — ㄴ 과 ㄷ.** (68번은 ㄴ 하나였다)
#      ㄴ) tools 가 담는 것 중 바뀐 파일 **12 / 15**.
#      ㄷ) 🔴 **도구의 import 닫힘이 이번 판에 실제로 걸린다.**
#         [실측 2026-11-20] scripts/ 의 **두 파일**이 그 모듈을 import 한다:
#           scripts/import-workbook.ts:28   import { appSettings, SETTING_TRANSITION_DATE } from "../src/db/schema/app-settings";
#           scripts/seed-demo-legacy.ts:18  (같은 모듈)
#         🔴 그 **과녁(src/db/schema/app-settings.ts)이 이번 범위에 들어 있다** —
#            67·68번은 **두 판 연속** 안 걸렸다. 이번 판이 **그 잣대의 실물**이다.
#            도구를 안 구우면 그 둘이 **옛 몸통**으로 돌게 된다.
#      ㄱ) npm 명령 **17 → 17** — 안 걸린다(「안 걸린다」도 값으로 잰다).
#      ㄹ) vendor/ 변경 **0줄** — 안 걸린다.
#      ㅁ) 마이그레이션 **0건** — 묶음을 만들 까닭이 없다(재고는 애초에 묶음을 안 쓴다).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **68번에서 그대로 살린 것 — 한 번 빼면 다시 넣는 사람이 없다**
# ══════════════════════════════════════════════════════════════════════
#   · 0절 Git Bash 판정(/mnt/ 로 시작하면 ✗)        → 참. 그대로.
#   · 🔴 **1-ㄴ 경로 번역 검사**(MSYS_NO_PATHCONV)   → 참. **맨 앞에 둔다.**
#     이것이 없어서 쉰여덟째에 **가짜 ✗ 일곱**을 헤맸다.
#   · 2절 「미푸시 0 과 **안 받은 것도 센다**」 → 참. [실측] main == origin/main.
#   · 「굽기 전에 서브모듈 작업본이 체크아웃돼 있는가」 → 🔴 **참이고 이번에도
#     중요하다.** 핀이 안 움직이니 **핀만 보면 빈 서브모듈도 통과한다**(3-ㄷ).
#   · tar 크기를 **두 번** 견주기(지난 판 tar 와 · 그 이미지 자신과) → 참.
#   · 「grep -c 는 0 일 때 종료 코드 1」·「tar | grep -q 는 SIGPIPE」·
#     「bash -n 이 못 잡는 둘」·「0 으로 시작하는 수는 8진수」 → 전부 참. 같은 규율로 썼다.
#   · 함수 정의에 붙인 **</dev/null** · 고리마다 **「몇 개를 봤는가」 관문** → 참.
#   · 「✗ 가 나도 지문 줄만은 찍는다」 → 참. **세 자리**에서 찍는다.
#   · --verify 모드(이미 구운 둘을 **다시 굽지 않고** 안만 잰다) → 참.
#   · 「docker build 는 dev 서버를 안 내려도 된다(.dockerignore 가 .next 를 막는다)」
#     → 참. [실측] .dockerignore 의 ^\.next 가 **1줄**. 🔵 **3800·3100 과 DB 상자
#     셋이 떠 있는 것이 정상이다** — 7-ㄴ 이 값으로 찍기만 하고 판정에 안 쓴다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **65번에서 와서 68번이 지켜 온 결함 고침 둘 — 빠뜨리면 같은 일이 또 난다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 **stdin 을 빨아들이는 명령을 고리 안에서 부르면 고리가 한 바퀴만 돈다.**
#      🔴 처방 둘을 **함께**: **-i 를 떼고**, **함수 정의에 </dev/null 을 붙인다.**
#      🔴 그리고 **「몇 개를 봤는가」를 고리마다 세어 끝에서 단언한다.**
#   ② 🔴 **Git Bash 가 docker.exe 에 넘기는 「/ 로 시작하고 빈칸 없는」 인자를
#      윈도우 경로로 번역한다.** [실측 2026-11-18] 그것 하나로 **가짜 ✗ 일곱**이 났다.
#      🔴 처방 셋을 **다 쓴다**: dockr() 로 **docker 를 부를 때만** 끄고 ·
#         **그것이 정말 꺼졌는지 값으로 재고**(1-ㄴ) · 파일 경로는 **상대로 넘긴다.**
#      🔴 **전역 export 로 끄면 git 이 깨진다 — 실제로 깨뜨려 봤다**(✗ 스물한 개).
#
# ── 이번에 굽는 것 — **이미지 둘** ───────────────────────────────────
#     ① 재고 앱   dss-inventory:0.7        → dss-inventory:0.8        커밋 1
#     ② 재고 도구 dss-inventory-tools:4    → dss-inventory-tools:5    🔴 --target tools
#   🔴 **묶음은 없다**(재고는 .sql 을 이미지에 굽는다 — 머리말 ⑥).
#   🔴 **나머지 아홉 집은 안 굽는다** — 이번 범위에 한 줄도 없다.
#
# ── 🔴 모드 셋 ────────────────────────────────────────────────────────
#   --verify 🔴 **이미 구운 둘을 다시 재기만 한다.** docker build 도 docker save 도
#            한 줄 안 돌린다. 🔴 6절의 기대값이 **뒤집힌다** — 태그가 **있어야** 한다.
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다(폴더도).
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면 멈춘다.
#            전부 ✓ 일 때만 **둘을 굽고** tar 로 뽑고 **이미지 안을 센다.**
#   🔵 세 모드가 **같은 함수**로 잰다(check_all · inside_check). 두 벌로 적으면 어긋난다.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 tar 크기를 **두 번** 견준다 ────────────────────────────────────
#   ① **지난 판 tar 와** 견준다(둘 다 값이 있다 — 62-deploy.sh 의 TARS).
#   ② **그 이미지 자신과** 견준다. 가지가 둘이다:
#      · containerd 저장소면 inspect .Size 가 **압축된 내용 크기**라 90~110%.
#      · 고전 저장소면 **펼친 크기**라 tar 는 그 **1/4쯤**(10~45%).
#   🔴 **tar 지문은 'docker image inspect' 의 .Id 와 맞대지 않는다.** 맞댈 상대는
#      **빌드 로그의 'exporting config sha256:'** 이다.
#
# ── 🔴 이 환경의 함정 (36~68-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싼다. 저장소 자리를 적어
#      넣지 않고 **이 파일의 자리에서 계산한다**(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:/… 를 /c/… 로 바꾸고,
#      docker save 는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를 막는다).
#   ④ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다.** 이 파일의 표식은 **전부
#      ASCII** 다 — 8진 이스케이프가 한 군데도 없다.
#   ⑤ 🔴 **이번 범위에는 괄호가 든 경로가 둘 있다**(대괄호는 0이다):
#        src/app/(app)/layout.tsx · src/app/(app)/settings/drawing-no/page.tsx
#      🔴 목록을 넘기는 길은 **here 문서 + while read** 와 **grep -Fx** 로만 썼고,
#         컨테이너 안에서도 set -f 로 글롭을 끈다. 「이번엔 대괄호가 없으니 괜찮다」로
#         길을 바꾸면 다음 판이 그 함정을 밟는다.
#   ⑥ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」 같은
#      안전망을 달면 **하필 바라던 0 에서만** 그것이 터져 값이 "0 ?" 가 된다.
#      이 파일은 그 꼴을 **한 군데도 쓰지 않는다** — 「$( … || true )」 로 받는다.
#   ⑦ 🔴 **tar | grep -q 를 if 에 바로 물리지 않는다.** set -uo pipefail 아래서
#      grep -q 가 먼저 끝나면 앞의 tar 가 SIGPIPE 로 죽어 **파일이 있을 때 오히려
#      ✗** 가 난다. 🔵 이 파일이 tar 를 읽는 자리는 **manifest.json 하나**뿐이고,
#      그 자리는 **세어서 담는 꼴**(grep -o)이다.
#   ⑧ 🔴 **CRLF.** 이 저장소들의 작업본은 전부 CRLF 다. Git Bash 의 grep 만 \r 를
#      걷어내고 리눅스 컨테이너의 GNU grep 은 안 걷어낸다. 줄 전체로 맞대는
#      검사(-Fx)는 **읽자마자 tr -d 로 \r 를 걷어낸 뒤** 맞댄다.
#   ⑨ 🔴 **빈 결과는 삼켜진 오류일 수 있다.** 목록을 읽는 자리는 **읽은 줄 수를
#      함께 받아** 너무 적으면 ✗ 로 세고, **없는 경로 하나를 일부러 함께 묻는다.**
#   ⑩ 🔴 **bash 의 $(( )) 는 0 으로 시작하는 수를 8진수로 읽는다** — 0028 을 셈에
#      넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안의 백틱은 명령 치환으로 읽힌다 → 이 파일에는 백틱이 **한 개도 없다.**
#   ② 읽기 전용 자리의 콜론과 꺾쇠로 빈 파일을 만드는 꼴은 ash 를 죽인다 →
#      이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   🔴 19·20·21번에는 그 둘이 아직 남아 있다. **거기서 베껴 오지 마라.**
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail

# ══════════════════════════════════════════════════════════════════════
# 🔴 **Git Bash 가 /app/… 을 C:/Program Files/Git/app/… 으로 바꾼다** (결함 ②)
# ══════════════════════════════════════════════════════════════════════
#   docker.exe 는 **윈도우 프로그램**이라 MSYS 런타임이 인자를 넘기기 전에
#   「유닉스 절대경로처럼 생긴 것」을 윈도우 경로로 **조용히 번역한다.** 값에
#   빈칸이 없고 / 로 시작하면 걸린다:
#
#       docker run -e F="/app/src/x.ts" …  →  컨테이너 안에서 $F 가
#       C:/Program Files/Git/app/src/x.ts  가 되어 [ -f "$F" ] 가 거짓이 된다
#
#   🔴 **전역 export 로 끄지 않는다** — git 이 깨진다. docker 를 부르는 자리에만
#      붙인다. 같은 셸에서 git 은 그대로다.
dockr() { MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker "$@" </dev/null; }
# 🔵 </dev/null 은 결함 ① 의 처방이다. docker run 은 -i 가 없으면 stdin 을 안 읽지만,
#    나중에 누가 -i 를 되살려도 **고리가 살아남게** 함수 정의에 붙여 둔다.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEV=${DSS_DEV:-$(cd "$SCRIPT_DIR/../../.." && pwd)}

PASS=0; FAIL=0; UNK=0
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
unk()  { UNK=$((UNK+1));   printf '  ? %s — 못 쟀다 (%s)\n' "$1" "$2"; }
note() { printf '  ⚠️ %s\n' "$1"; }
say()  { printf '    %s\n' "$1"; }
step() { printf '\n%s\n' "── $1"; }
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

# tar 안 manifest.json 의 Config 지문 (39~68-build.sh 의 것을 글자 그대로)
tar_config_id() { # 1 tar
  tar -xOf "$1" manifest.json 2>/dev/null \
    | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 \
    | sed 's|blobs/sha256/|sha256:|'
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

# package.json 의 scripts 블록 **안**만 센다.
count_scripts() { # stdin = package.json
  awk '
    /^  "scripts": \{/ { inb = 1; next }
    inb && /^  \}/      { inb = 0 }
    inb && /^    "/     { n++ }
    END { print n + 0 }
  '
}

# ══════════════════════════════════════════════════════════════════════
# ══ 이번 판의 값 — 한자리에 모아 둔다 ═════════════════════════════════
# ══════════════════════════════════════════════════════════════════════
#
# ── 저장소 **하나** — 🔴 **재고관리다** ──────────────────────────────
#   🔴 기준 SHA 의 출처: 쉰여덟째(62번)가 올린 뒤로 재고관리는 **한 판도 안 구워졌다**
#      [실측 2026-11-20 — 63~68번 어디에도 dss-inventory 태그가 없다].
#      그래서 기준은 **그 뒤 재고 저장소가 쌓아 온 것의 바로 앞**이다.
#      [실측] 그 SHA 에서 세어 커밋 **1** 이었다.
INV_REPO=dss-inventory
INV_NAME=재고관리
INV_BASE=a160fd9
INV_COMMITS_WANT=1
INV_PORT=3800
# 🔵 재고 개발 DB 는 **dss-inventory-db(호스트 5450)** 다 — A/S 의 5442 가 아니다
#    [실측 2026-11-20 · docker-compose.yml 의 127.0.0.1:5450:5432].
#    🔴 **끄지 않는다** — 이 파일은 DB 에 한 번도 안 붙는다.
INV_DB_PORT=5450
PORTAL_PORT=3100
AS_DB_PORT=5442
AUTH_DB_PORT=5444

# ── 굽는 **둘** ───────────────────────────────────────────────────────
#   열쇠|새 태그|타깃(-=기본 runner)|지난판 tar 이름|지난판 tar 바이트|엄함
#   🔴 지난판 바이트의 출처 — **62-deploy.sh 의 TARS 에 박힌 값 그대로다**:
#      dss-inventory-0.7.tar        95449600
#      dss-inventory-tools-4.tar   213334528
#   🔵 엄함: strict = 25% 넘으면 ✗ · loose = 25% ⚠️ · 60% 넘으면 ✗
#   🔴 **둘 다 strict 다** — [실측] 의존성 파일이 **한 장도 안 바뀌었다**.
IMAGES='
inv|dss-inventory:0.8|-|dss-inventory-0.7.tar|95449600|strict
invtools|dss-inventory-tools:5|tools|dss-inventory-tools-4.tar|213334528|strict
'
HOWMANY=2

# ── 🔴 마이그레이션 — **0건이다** ────────────────────────────────────
#   저장소가 들고 있어야 하는 수 · 목록 수 · 이번 범위의 drizzle 변경 · 그 다음 번호
#   🔴 **재고는 그 .sql 이 도구 이미지 안에 구워져 간다**(머리말 ⑥) — A/S 처럼
#      볼륨에 보내는 묶음이 **애초에 없다.**
INV_SQL_WANT=28
INV_DRIZZLE_DIFF_WANT=0
INV_NEXT_MIG=0028
# 🔵 **운영이 지금 들고 있어야 하는 수** — 개발 PC 에서는 못 잰다. 69-deploy.sh 가
#    DB 에 물어 확인하고, **바뀌었으면 거기서 멈춘다.** 여기서는 찍어 두기만 한다.
PROD_MIGS_NOTE='A/S 132 · 재고 28 · 휴가 5 · 포털 11 · 계측기 3'

# ══ 🔴 서브모듈 — **하나뿐이고 안 움직인다** ══════════════════════════
#   🔴 **재고관리에는 vendor/dss-core 가 없다**[실측 2026-11-20 · .gitmodules].
#      A/S 판을 베끼면 여기서 「없다」로 ✗ 가 줄줄이 난다. 🔵 **없는 것이 맞다** —
#      재고는 공용 스키마를 안 쓴다(제 src/db/schema 를 쓴다).
#   🔵 dss-ui 는 이것으로 **열넷째 판 연속** 안 움직인다.
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425
# 🔴 **핀만 보면 빈 서브모듈도 통과한다** — 안의 파일과 내보내기를 함께 본다.
INV_UI_KEEP_FILE=src/index.ts
INV_UI_EXPORT1=ServiceMenuBar
INV_UI_EXPORT2=NotificationBell

# ══ 🔴 바뀐 파일 수 — [실측 2026-11-20] ═══════════════════════════════
#   전체|src/|tests/|scripts/|drizzle/|vendor+.gitmodules|새 파일|지운 파일|괄호|대괄호
#   🔴 **68번과 같은 자리가 거의 없다**(머리말 ②). 68번은 전체가 **8**(src 7 ·
#      scripts 1)이었다 — 이번엔 **15** 이고 그중 **3장이 tests/** 다.
CH_ALL=15
CH_SRC=12
CH_TESTSDIR=3
CH_SCRIPTS=0
CH_DRIZZLE=0
CH_VENDOR=0
CH_NEW=8
CH_DEL=0
CH_PAREN=2
# 🔴 **대괄호 셈은 66번이 더한 것이다.** 67번이 0 이었는데도 안 뺐고 68번에 실물이
#    나왔다. 🔴 **이번 판은 다시 0 이다** — 그래도 안 뺀다. 「0이니 뺀다」를 한 번
#    하면 다음에 1 이 되는 날 아무도 못 본다.
CH_BRACKET=0
#   🔵 바뀐 15장 중 **셋이 시험 파일**이다 — 5-ㅇ 의 표본이 거기서 나온다.
#      🔴 68번은 **넷**이었고, 그 넷은 **src/ 아래**라 이미지에 담겼다.
#         🔴 재고의 시험은 **tests/ 아래**이고 .dockerignore 에 걸려 **안 담긴다.**
CH_TESTS=3

# ══ 🔴 npm 명령 수 — [실측 2026-11-20] ════════════════════════════════
NPM_WAS=17
NPM_NOW=17

# ══ 🔴 **도구를 굽는 까닭** — 값으로 가린다(머리말 ⑦) ═════════════════
#   ㄴ) tools 스테이지가 담는 것 중 바뀐 파일 수. 🔴 **15 중 12**.
#      🔵 빠지는 셋은 **전부 tests/** 다 — .dockerignore 가 막는다(5-ㄴ 이 잰다).
#      🔴 재고의 tools 는 **drizzle/ 도 담는다**(A/S 는 안 담는다) — 그래서 이
#         정규식에 drizzle/ 이 들어 있다. 이번 범위에 그 폴더는 0장이지만,
#         **잣대를 좁혀 두면** .sql 이 생기는 날 그 수가 조용히 빠진다.
TOOLS_PAYLOAD_RE='^(src/|scripts/|drizzle/|package\.json|tsconfig\.json|drizzle\.config\.ts)'
TOOLS_PAYLOAD_WANT=12
#   ㄷ) 🔴 **도구의 import 닫힘 — 이번 판에 실제로 걸린다**(67·68번은 안 걸렸다).
#      파일|그 파일이 import 하는 모듈
TOOL_IMPORTERS='
scripts/import-workbook.ts|../src/db/schema/app-settings
scripts/seed-demo-legacy.ts|../src/db/schema/app-settings
'
TOOL_IMPORTERS_WANT=2
TOOL_IMPORT_TARGET=src/db/schema/app-settings.ts
# 🔴 **1 이다.** 그 과녁이 이번 범위에 들어 있다 — 도구를 안 구우면 그 둘이
#    **옛 몸통**으로 돈다. 🔵 67·68번은 0 이었다(잣대만 재 두던 판).
TOOL_IMPORT_TARGET_WANT=1

# ══ 🔴 Dockerfile 이 담는 길 — **재고 넷** ════════════════════════════
#   정규식|있어야 하나(yes/no)|사람이 읽을 말
#   🔴 **A/S 와 뜻이 반대인 줄이 둘이다**(drizzle 과 vendor). 그대로 베끼면
#      멀쩡한 재고 Dockerfile 이 ✗ 가 된다.
COPYRULES='
^COPY drizzle \./drizzle|yes|🔴 재고 tools 가 drizzle/ 을 **담는다** — 재고 마이그레이션은 **이미지 안에서** 돈다 (A/S 와 반대다)
^COPY scripts \./scripts|yes|재고 tools 가 scripts/ 를 담는다 (migrate.ts 와 ㄷ 잣대의 둘이 여기다 — 이번 범위에는 0장)
^COPY src \./src|yes|🔴 재고 tools 가 src/ 를 담는다 — 바뀐 12장이 전부 여기다
^COPY .*vendor|no|🔵 재고 tools 는 vendor/ 를 **안 담는다** — @dss/ui 는 화면 조각이라 도구가 안 쓴다 (62번이 포털에서 쓰던 잣대 그대로)
'
COPYRULES_WANT=4

# ══ 🔴 앱 번들에서 쓸 표식 — **전부 리터럴 · 전부 ASCII** ═════════════
#   🔴 **이번 판에 태어난 DOM id 다**(머리말 ④) — 색 고르개의 이름표가 가리키는
#      입력 칸의 id 이고, **문자열 리터럴**이라 minify 가 **이름을 못 바꾼다.**
APPMARK=drawing-no-text-color
APPMARK_NOTE='기준 0 → 지금 1파일 (색 고르개의 DOM id — 문자열 리터럴이다)'
# 🔵 판정에 **안 쓰는** 곁들이 값 — 번들이 **따옴표를 지키는지** 로그에 같이 찍는다.
#    🔴 곁들이 꼴은 맨 글자의 **부분집합**이라 맨 글자보다 클 수 없다 — 곁들이가
#       더 크게 나오면 **세는 쪽이 깨진 것**이다.
APPMARK_DIAG='"drawing-no-text-color"'
# 🔵 **보조 표식** — 판정은 하되 **번들에는 안 쓴다**(라우트 경로라 담기는 자리가
#    판마다 다르다). [실측] 기준 0 → 지금 4파일.
AUXMARK=settings/drawing-no
AUXMARK_WAS=0
AUXMARK_NOW=4
KEEPMARK1=portal_approval_delegations
KEEPMARK1_NOTE='쉰여덟째가 올린 글자 — 기준 14 → 지금 14파일'
KEEPMARK2=stock_issue_approval_steps
KEEPMARK2_NOTE='그 앞 판이 올린 표 이름 — 기준 10 → 지금 10파일'
# 🔴 **셋째 뒷걸음 표식은 번들에서 안 센다**(머리말 ⑤) — const 이름이라 minify 가
#    이름을 바꾼다. 소스에서만 세고, 도구 이미지에서 **소스 글자 그대로** 다시 센다.
KEEPMARK3=TOOLBAR_BTN_PRIMARY
KEEPMARK3_NOTE='지난 판의 도구 표식 — 기준 1 → 지금 1파일 (🔴 번들에선 안 센다)'
MARKS_WANT=4
# 🔴 **번들에서 세는 뒷걸음은 둘뿐이다.** 셋으로 적으면 KEEPMARK3 가 번들에서
#    0 으로 나와 **진짜 결함처럼 보이는 ✗** 가 난다.
BUNDLE_KEEPS_WANT=2

# ══ 🔴 도구 이미지에서 쓸 **마지막 커밋 표식** ════════════════════════
#   🔴 **이번 판에 태어난 조각 이름**이다 — 도번 줄을 그리는 공용 조각이고,
#      과녁 파일은 **기준판에도 있던 신청 항목 칸**이다.
TOOLMARK=DrawingNoLine
TOOLMARK_FILE=src/components/stock/RequestItemDetails.tsx
TOOLMARK_LINES_WANT=4
TOOLMARK_LINES_WAS=0
# 🔴 그 표식이 가리키는 **새 모듈** — 그 파일이 import 하는 쪽이다. 없으면 화면이
#    import 에서 죽는다.
TOOLMARK_MODULE=src/components/stock/DrawingNoLine.tsx
# ══ 🔴 도구 이미지에서 세는 **뒷걸음 표식**(소스 글자 그대로) ═════════
#   🔵 62번이 이것을 **마지막 커밋 표식**으로 썼다 — 이제 뒷걸음을 보는 자리다.
TOOLKEEP=TOOLBAR_BTN_PRIMARY
TOOLKEEP_FILE=src/components/parts/PartsList.tsx
TOOLKEEP_LINES_WANT=2

# ══ 🔴 public/ 기대값 ═════════════════════════════════════════════════
#   🔴 **재고의 public/ 은 있는데 비어 있다**(ls -1 로 0개) — .gitkeep 한 장뿐이고
#      그것은 숨은 파일이라 안 세어진다. [실측 2026-11-18 · 62번이 구운 것을 열어 셌다]
#   🔴 **A/S 판(9개 이상이어야 한다)을 그대로 베끼면 멀쩡한 재고 앱이 ✗** 가 된다.
#      62번이 그 자리에서 **가짜 ✗** 를 냈고, 그래서 ⚠️ 가지를 따로 두었다.
INV_PUBLIC_WANT=yes
INV_PUBLIC_N=0

# ══ 🔴 **이번 판의 바뀐 파일 중 도구 이미지가 담는 열둘** ═════════════
#   🔴 **바뀐 목록 15장에서 tests/ 셋을 뺀 것**이다. 뺀 까닭은 .dockerignore 이고,
#      5-ㄴ 이 그것을 값으로 잰다 — 「왜 12인가」를 추측으로 두지 않는다.
#   🔴 **괄호가 든 경로가 둘 있다**(src/app/(app)/…) — here 문서로 넘기고 컨테이너
#      안에서 set -f 로 글롭을 끄는 길이 **여기서 실제로 쓰인다.**
#   🔴 **없는 경로 하나를 함께 묻는다** — 「무조건 yes」인 검사인지 가른다.
PROBE_MISS=src/__dss_probe_no_such_file__.ts
INV_CHANGED_FILES='
src/app/(app)/layout.tsx
src/app/(app)/settings/drawing-no/page.tsx
src/app/actions/drawing-no-style.ts
src/components/settings/DrawingNoStyleForm.tsx
src/components/settings/SettingsNav.tsx
src/components/stock/DrawingNoLine.tsx
src/components/stock/DrawingNoStyleContext.tsx
src/components/stock/RequestItemDetails.tsx
src/db/schema/app-settings.ts
src/lib/stock/drawing-no-style-queries.ts
src/lib/stock/drawing-no-style.ts
src/lib/stock/request-item-detail.ts
'
INV_CHANGED_FILES_WANT=12

# ══ 🔴 시험 등록 — 재고는 **글롭** 방식이다 ═══════════════════════════
#   🔴 **A/S 와 다르다.** A/S 는 scripts/test-lists/*.txt 에 **적어야 돌고**,
#      재고는 package.json 의 test 줄이 **글롭 둘**을 들고 있어 **파일을 두면 돈다**:
#        tests/**/*.test.ts  ·  src/lib/xlsx/*.test.ts
#      🔴 A/S 판의 「목록에 적혀 있나」를 그대로 베끼면 **적을 파일이 없어** ✗ 가
#         줄줄이 난다. 여기서 재는 것은 **글롭이 아직 살아 있는가**와
#         **새 시험이 그 글롭에 걸리는 자리에 있는가** 둘이다.
#   🔵 **「줄 수가 안 줄었다」의 뜻은 살린다** — 글롭 방식에서는 **걸리는 파일 수**가
#      그 자리다. [실측 2026-11-20] tests/ **95 → 96** · src/lib/xlsx/ **4 → 4**.
#      🔴 줄어든 것은 언제나 누가 시험을 지운 것이다.
INV_TEST_GLOB1='tests/**/*.test.ts'
INV_TEST_GLOB2='src/lib/xlsx/*.test.ts'
INV_TESTS_TESTSDIR_WAS=95
INV_TESTS_TESTSDIR_NOW=96
INV_TESTS_XLSX_WAS=4
INV_TESTS_XLSX_NOW=4
INV_NEW_TESTS_WANT=1
INV_NEW_TESTS='
tests/drawing-no-style.test.ts
'
INV_TOUCHED_TESTS='
tests/drawing-no-style.test.ts
tests/request-item-detail.test.ts
tests/settings-access.test.ts
'
INV_TOUCHED_TESTS_WANT=3

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-65"; fi

case "$MODE" in
  --check|--go|--verify) ;;
  *) printf '쓰는 법: %s [--check|--go|--verify] [산출물폴더]\n' "$0"; exit 2 ;;
esac

IVD="$DEV/$INV_REPO"
UIDIR="$IVD/vendor/dss-ui"

printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' " 69-build.sh — 예순다섯째 배포 · 이미지 굽기 ($MODE)"
printf '%s\n' "   저장소 뿌리 : $DEV"
printf '%s\n' "   산출물 자리 : $OUT"
printf '%s\n' "   굽는 것     : 이미지 $HOWMANY (재고 앱 · 재고 도구) · 🔴 **묶음 없음**"
printf '%s\n' "   판          : 🔴 **dss-inventory:0.7 → 0.8** · dss-inventory-tools:4 → 5"
printf '%s\n' "   마이그레이션: 🔴 **0건** — 「바뀌지 않아야 한다」를 잰다 (28장 그대로)"
printf '%s\n' "   서브모듈    : 🔵 **vendor/dss-ui 하나뿐이고 안 움직인다** (dss-core 는 없다)"
printf '%s\n' "   🔵 [재고관리] 도번을 **제 줄에 크게** — 모양은 [설정] → [도번 표시] 에서 고릅니다"
printf '%s\n' "══════════════════════════════════════════════════════════════"

# ══ 표를 읽는 길 ══════════════════════════════════════════════════════
#   🔴 **공백이 든 표(COPYRULES)는 tr -d ' ' 로 읽지 않는다** — 말이 뭉개진다.
#      그 표는 while IFS='|' read 로만 읽는다.
rows_of() { printf '%s\n' "$1" | grep -v '^[[:space:]]*$'; }
field() { printf '%s' "$1" | cut -d'|' -f"$2"; }

# 「기준 SHA 때 그 글자가 든 src/ 파일 수」 — 🔴 pathspec 에 글롭이 든 경로를
# 넘기지 않는다(src 하나만 넘긴다).
mark_was() { git -C "$IVD" grep -lF -- "$2" "$1" -- src 2>/dev/null </dev/null | wc -l | tr -d ' '; }
mark_now() { grep -rlF -- "$1" "$IVD/src" 2>/dev/null | wc -l | tr -d ' '; }

# 🔴 표식 한 쌍을 재는 길 — 기능(0 → N) · 뒷걸음(N → N) 둘 다 이 함수로 센다.
MARK_SEEN=0
check_mark() { # 1 글자 2 갈래(feature|keep) 3 사람이 읽을 말
  local a b
  MARK_SEEN=$((MARK_SEEN+1))
  a=$(mark_was "$INV_BASE" "$1"); b=$(mark_now "$1")
  printf '      %-32s 기준 %-4s → 지금 %-4s  (%s)\n' "[$1]" "${a:-?}" "${b:-?}" "$3"
  case "$2" in
    feature)
      if [ "${a:-x}" = "0" ] && [ "${b:-0}" -ge 1 ] 2>/dev/null; then
        ok "기능 표식 [$1] 이 **이번 판에만 있다**"
      else
        bad "기능 표식 [$1] 이 기준 ${a:-?} → 지금 ${b:-?} 다 — 0 → 1 이상을 기대했다"
        say "      🔴 기준판에도 있으면 그 표식은 **아무것도 안 가릅니다.**"
        say "      🔵 **네 판 연속으로 그 실물이 나왔습니다** — 예순째는 맨 글자"
        say "         ORDER_ISSUED 가 기준판의 ORDER_ISSUED_SORT_HINT 에 걸려 2파일,"
        say "         예순한째는 selectionMode 가 RepairCaseTable 에 걸려 5파일,"
        say "         예순두째는 지시받은 fault_tags 가 **주석 한 줄**뿐이었고,"
        say "         예순세째 것은 **어제 올린 글자**라 아무것도 안 갈랐습니다."
        doubt
      fi
      ;;
    keep)
      if [ "${a:-0}" -ge 1 ] 2>/dev/null && [ "${b:-0}" -ge 1 ] 2>/dev/null; then
        ok "뒷걸음 표식 [$1] 이 기준에도 지금에도 있다 (뒷걸음을 잴 수 있다)"
      else
        bad "뒷걸음 표식 [$1] 이 기준 ${a:-?} · 지금 ${b:-?} 다 — 둘 다 1 이상이어야 한다"
        doubt
      fi
      ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════
check_all() {
PASS=0; FAIL=0; UNK=0

# ── 0. 🔴 Git Bash 인가 (WSL 이면 ✗ 가 흩어져 난다) ──────────────────
step "0. 🔴 Git Bash 에서 도는가 — WSL 이면 여기서 멈춘다"
say "뿌리 경로: $DEV"
case "$DEV" in
  /mnt/*)
    bad "🔴 **WSL 에서 돌고 있다**(뿌리가 /mnt/ 로 시작한다) — 여기서 구우면 유령 diff 가 난다"
    say "    → PowerShell 에서 이렇게 부르세요:"
    say "       & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./69-build.sh $MODE"
    ;;
  /[a-z]/*)
    ok "Git Bash 다 (뿌리가 /c/ 꼴이다)"
    ;;
  *)
    unk "셸 갈래" "뿌리가 /mnt/ 도 /c/ 도 아니다 — $DEV"
    ;;
esac
u=$(uname -s 2>/dev/null)
say "uname -s: ${u:-못 읽음}"
case "${u:-}" in
  MINGW*|MSYS*) ok "uname 도 Git Bash 를 가리킨다 ($u)" ;;
  Linux)        bad "uname 이 Linux 다 — **WSL 이다**" ;;
  *)            note "uname 이 ${u:-못 읽음} 다 — 사람이 보세요" ;;
esac

# ── 1. 도커가 도는가 ──────────────────────────────────────────────────
step "1. 도커가 도는가"
if docker version --format '{{.Server.Version}}' >/dev/null 2>&1; then
  v=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
  ok "도커가 돈다 (서버 ${v:-판 못 읽음})"
else
  bad "도커가 안 돈다 — Docker Desktop 을 켜세요"
fi

# ── 1-ㄴ. 🔴 **경로 번역이 정말 꺼졌는가** — 값으로 잰다 (결함 ②) ────
#   🔴 이 절이 없어서 쉰여덟째의 첫 굽기에 **가짜 ✗ 일곱**이 났다. 번역이 켜져
#      있으면 아래 절들의 ✗ 가 **진짜 결함처럼 보인다.**
#   🔵 컨테이너가 하나 필요하다 — 옛 판이든 새 판이든 **있는 것**을 쓴다.
say ""
say "── 1-ㄴ. 🔴 Git Bash 의 경로 번역이 꺼졌는가 (MSYS_NO_PATHCONV)"
PROBE_IMG=""
PROBEIMG_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  PROBEIMG_SEEN=$((PROBEIMG_SEEN+1))
  t=$(field "$r" 2)
  if [ -z "${PROBE_IMG:-}" ] && docker image inspect "$t" >/dev/null 2>&1; then PROBE_IMG=$t; fi
  t2=$(field "$r" 4); t2=$(printf '%s' "${t2%.tar}" | sed 's/-\([0-9][0-9.]*\)$/:\1/')
  if [ -z "${PROBE_IMG:-}" ] && docker image inspect "$t2" >/dev/null 2>&1; then PROBE_IMG=$t2; fi
done <<ENDPROBEIMG
$(rows_of "$IMAGES")
ENDPROBEIMG
say "잴 후보로 본 줄 ${PROBEIMG_SEEN}개 (기대 $HOWMANY)"
if [ "$PROBEIMG_SEEN" != "$HOWMANY" ]; then
  bad "IMAGES 표를 ${PROBEIMG_SEEN}줄만 읽었다 — ${HOWMANY}줄을 기대했다. 표가 깨졌다"
fi
if [ -z "${PROBE_IMG:-}" ]; then
  unk "경로 번역" "잴 이미지가 하나도 없다 — 옛 판도 새 판도 이 PC 에 없다"
  say "      🔴 **이 줄이 ? 면 아래 이미지 안 검사를 믿지 마세요.**"
else
  say "재는 데 쓴 이미지: $PROBE_IMG"
  v=$(dockr run --rm -e DSSPROBE="/app/dss-pathconv-probe" --entrypoint sh "$PROBE_IMG" -c 'printf "%s" "$DSSPROBE"' 2>/dev/null | tr -d '\r')
  say "넘긴 값 [/app/dss-pathconv-probe] → 컨테이너가 받은 값 [${v:-못 읽음}]"
  if [ "${v:-}" = "/app/dss-pathconv-probe" ]; then
    ok "경로 번역이 **꺼져 있다** (아래 이미지 안 검사를 믿을 수 있다)"
  elif [ -z "${v:-}" ]; then
    unk "경로 번역" "컨테이너에서 값을 못 받았다"
  else
    bad "🔴 경로 번역이 **살아 있다** — 받은 값이 [${v}] 다"
    say "      🔴 이대로 두면 아래의 표식·파일 검사가 **가짜 ✗** 를 냅니다."
    say "      → PowerShell 에서 이렇게 부르세요(Git Bash 로):"
    say "         & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./69-build.sh $MODE"
    say "      → 그래도 안 꺼지면 이 파일 맨 위의 dockr() 줄을 보세요."
  fi
fi

# ── 2. 저장소 **하나** ────────────────────────────────────────────────
step "2. 저장소 하나 — 깨끗한가 · 올라가 있나 · 범위가 맞나"
say "🔴 구운 이미지는 **그때 그 작업 폴더의 사진**입니다. 커밋 안 된 줄이 섞이면"
say "   나중에 같은 이미지를 다시 못 만듭니다."
say "🔴 **이번 저장소는 dss-inventory 입니다** — 지난 다섯 판은 RF_Service_System 이었습니다."
if [ ! -d "$IVD/.git" ]; then
  bad "$INV_NAME — 저장소가 없다 ($IVD)"
else
  br=$(git -C "$IVD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ "$br" = "main" ] && ok "$INV_NAME 가지가 main 이다" || bad "$INV_NAME 가지가 ${br:-못 읽음} 다 — main 이어야 한다"
  dirty=$(git -C "$IVD" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${dirty:-1}" = "0" ]; then ok "$INV_NAME 미커밋 0줄"
  else
    bad "$INV_NAME 에 미커밋이 ${dirty}줄 있다 — 굽기 전에 정리하세요"
    git -C "$IVD" status --porcelain=v1 2>/dev/null | head -8 | sed 's/^/        /'
  fi
  h=$(git -C "$IVD" rev-parse --short HEAD 2>/dev/null)
  o=$(git -C "$IVD" rev-parse --short origin/main 2>/dev/null)
  say "HEAD $h · origin/main ${o:-없음}"
  if [ -n "${o:-}" ] && [ "$h" = "$o" ]; then
    ok "$INV_NAME main == origin/main (올라가 있다)"
  else
    ab=$(git -C "$IVD" rev-list --left-right --count main...origin/main 2>/dev/null)
    bad "$INV_NAME main 과 origin/main 이 다르다 (왼쪽=안 올린 것 오른쪽=안 받은 것: ${ab:-못 읽음})"
    say "      🔴 **「미푸시 0」은 받았다는 뜻이 아닙니다** — 오른쪽 수도 보세요."
  fi
  if git -C "$IVD" cat-file -e "$INV_BASE^{commit}" 2>/dev/null; then
    n=$(git -C "$IVD" rev-list --count "$INV_BASE..main" 2>/dev/null)
    say "기준 $INV_BASE..main 커밋 ${n:-못 읽음}개 (적어 둔 값 $INV_COMMITS_WANT)"
    git -C "$IVD" log --oneline "$INV_BASE..main" 2>/dev/null | sed 's/^/        /'
    if [ "${n:-x}" = "$INV_COMMITS_WANT" ]; then
      ok "$INV_NAME 범위가 적어 둔 것과 같다 ($INV_COMMITS_WANT 커밋)"
    else
      note "$INV_NAME 커밋이 ${n:-?}개다 — $INV_COMMITS_WANT 을 적어 두었다. **사람이 보세요**"
      say "      🔵 ⚠️ 로만 셉니다 — 그 사이에 하나 더 밀었을 수 있습니다."
      say "      🔴 그래도 **표식·파일 수 기대값이 전부 그 범위에서 나온 값**입니다."
    fi
  else
    bad "$INV_NAME 기준 SHA $INV_BASE 가 이 저장소에 없다 — 표가 틀렸다"
  fi
fi

# ── 3. 🔴 서브모듈 — **하나뿐이다.** 「안 움직였다」를 값으로 잰다 ────
step "3. 🔴 서브모듈 — **재고관리에는 vendor/dss-ui 하나뿐이다**"
say "🔴 **A/S 판을 그대로 베끼면 여기가 통째로 ✗ 입니다** — A/S 에는 vendor/dss-core"
say "   가 있고 그것을 보는 절이 다섯 군데였습니다. 🔵 **재고에는 그 서브모듈이"
say "   아예 없습니다**(.gitmodules 에 dss-ui 한 줄뿐) — 재고는 공용 스키마를 안"
say "   쓰고 제 src/db/schema 를 씁니다. **없는 것이 맞습니다.**"
say "🔵 vendor/dss-ui 는 이것으로 **열넷째 판 연속** 안 움직입니다."
say "🔴 핀이 안 움직이면 3-ㄱ 은 **아무것도 안 가르는 ✓** 가 될 수 있습니다 —"
say "   그래서 3-ㄷ 이 **안의 파일을 값으로** 셉니다."
pin_of() { git -C "$IVD" submodule status "$1" 2>/dev/null </dev/null | awk '{print $1}' | tr -d '+-'; }
SUB_SEEN=0
check_pin() { # 1 서브모듈경로 2 기대 핀 3 사람이 읽을 말
  local p
  SUB_SEEN=$((SUB_SEEN+1))
  p=$(pin_of "$1")
  if [ -z "${p:-}" ]; then
    bad "$1 포인터를 못 읽었다 — 서브모듈이 없거나 init 이 안 됐다"
    return
  fi
  if [ "$p" = "$2" ]; then ok "$1 = ${2:0:8} — **지난 판 핀 그대로다** ($3)"
  else
    bad "$1 이 ${p:0:8} 다 — ${2:0:8} 을 기대했다 (🔴 **움직였다 — 이 배포본의 전제가 깨졌다**)"
    say "      🔴 멈추고 알리세요. 이 배포본에는 **공용 묶음이 바뀌는 절이 없습니다.**"
    doubt
  fi
}
say ""
say "── 3-ㄱ. 핀 값 — 지난 판 그대로인가"
check_pin vendor/dss-ui "$UI_PIN" "🔵 **열넷째 판 연속** 안 움직였다"
[ "$SUB_SEEN" = "1" ] && ok "서브모듈 핀 하나를 다 봤다 (표본이 비지 않았다)" \
  || bad "서브모듈 핀을 ${SUB_SEEN}개 봤다 — 1개를 기대했다"
# 🔴 **「하나뿐」인 것도 값으로 센다** — dss-core 가 조용히 생기면(또는 누가
#    베껴 넣으면) 이 배포본의 전제가 바뀐 것이다.
gm=$(grep -c '^\[submodule' "$IVD/.gitmodules" 2>/dev/null || true)
say ".gitmodules 의 서브모듈 줄 ${gm:-?}개 (기대 1 — dss-ui 하나)"
if [ "${gm:-x}" = "1" ]; then ok ".gitmodules 에 서브모듈이 **하나뿐이다** (dss-core 가 없는 것이 맞다)"
else
  note ".gitmodules 에 서브모듈이 ${gm:-?}개다 — 1 을 기대했다. **사람이 보세요**"
  say "      🔵 늘었으면 이 파일에 **그것을 보는 절을 더해야** 합니다(68번 3-ㄷ 을 베끼세요)."
fi

say ""
say "── 3-ㄴ. 🔴 **이번 범위가 vendor/ 를 건드렸는가** — 0줄이어야 한다"
VLIST=$(git -C "$IVD" diff --name-only "$INV_BASE..main" 2>/dev/null | tr -d '\r' | grep -E '^(vendor/|\.gitmodules)' || true)
vn=$(printf '%s\n' "$VLIST" | grep -c . || true)
say "vendor/ · .gitmodules 변경 ${vn:-?}줄 (기대 $CH_VENDOR)"
[ -n "${VLIST:-}" ] && printf '%s\n' "$VLIST" | sed 's/^/        /'
if [ "${vn:-x}" = "$CH_VENDOR" ]; then
  ok "이번 범위가 vendor/ 를 **한 줄도 안 건드렸다**"
else
  bad "vendor/ 변경이 ${vn:-?}줄 있다 — $CH_VENDOR 을 기대했다. **서브모듈이 움직였다**"
  doubt
fi

say ""
say "── 3-ㄷ. 🔴 **핀만 보면 빈 서브모듈도 통과한다** — 안의 파일을 값으로 센다"
SUBFILE_SEEN=0
check_sub() { # 1 폴더 2 이름
  SUBFILE_SEEN=$((SUBFILE_SEEN+1))
  local n d
  n=$(ls -1 "$1" 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -ge 3 ] 2>/dev/null; then ok "$2 작업본에 파일이 ${n}개 있다"
  else bad "$2 작업본이 비었다(${n:-?}개) — submodule update --init 이 필요하다"; fi
  d=$(git -C "$1" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${d:-1}" = "0" ]; then ok "$2 미커밋 0줄"
  else bad "$2 에 미커밋이 ${d}줄 있다 — 🔴 서브모듈 안을 고치지 마세요"; fi
}
check_sub "$UIDIR" "재고-ui"
[ "$SUBFILE_SEEN" = "1" ] && ok "서브모듈 작업본 하나를 다 봤다 (표본이 비지 않았다)" \
  || bad "서브모듈 작업본을 ${SUBFILE_SEEN}개 봤다 — 1개를 기대했다"
# 🔴 **빈 것이 아니라 「쓰는 것이 들어 있는가」를 센다** — 재고의 머리말이
#    ServiceMenuBar 와 NotificationBell 둘을 부른다. 안 내보내면 next build 가
#    그 자리에서 죽는다(2026-09-21 에 운영에서 도구가 전부 죽은 그 자리와 같은 꼴).
if [ -f "$UIDIR/$INV_UI_KEEP_FILE" ]; then
  ok "공용 묶음의 내보내기 파일이 **작업본에 있다** ($INV_UI_KEEP_FILE)"
  UIEXP_SEEN=0; UIEXP_OK=0
  for e in "$INV_UI_EXPORT1" "$INV_UI_EXPORT2"; do
    UIEXP_SEEN=$((UIEXP_SEEN+1))
    n=$(grep -cF "$e" "$UIDIR/$INV_UI_KEEP_FILE" 2>/dev/null || true)
    printf '      [%s] %s줄\n' "$e" "${n:-?}"
    if isnum "${n:-}" && [ "${n:-0}" -ge 1 ]; then UIEXP_OK=$((UIEXP_OK+1)); fi
  done
  say "본 것 ${UIEXP_SEEN} · 내보내는 것 ${UIEXP_OK} (기대 2 · 2)"
  if [ "$UIEXP_SEEN" = "2" ] && [ "$UIEXP_OK" = "2" ]; then
    ok "index.ts 가 **재고가 쓰는 둘을 내보낸다** (메뉴바 · 알림 종)"
  else
    bad "본 것 ${UIEXP_SEEN} · 내보내는 것 ${UIEXP_OK} 다 — 2 를 기대했다"
    say "      🔵 안 내보내면 next build 가 Cannot find export 로 죽습니다."
  fi
else
  bad "공용 묶음의 $INV_UI_KEEP_FILE 이 **작업본에 없다** — 🔴 핀만 맞고 **파일이 비었다**"
  say "      → git -C \"$IVD\" submodule update --init --recursive"
fi

# ── 4. 🔴 마이그레이션 — **0건.** 「바뀌지 않아야 한다」를 잰다 ───────
step "4. 🔴 마이그레이션 — **0건이다.** 「안 바뀌었는가」를 잰다"
say "🔴 **재고관리의 .sql 은 도구 이미지 안에 구워져 갑니다**(5-ㄱ 의 COPY drizzle)."
say "   🔴 **A/S 와 정반대입니다** — A/S 는 볼륨이 정본이라 이미지 안이 비어 있어야"
say "   하고, 재고는 **28장이 들어 있어야** 합니다. 그대로 베끼면 멀쩡한 이미지가 ✗ 입니다."
say "🔴 **묶음(as-migrations.tar.gz)을 만드는 절이 없습니다.** 까닭이 둘입니다 —"
say "   ㉠ 이번 범위의 drizzle/ 변경이 **0장**이고, ㉡ **재고는 애초에 묶음을 안 씁니다.**"
say "   🔴 .sql 이 한 장이라도 생기면 **62번의 「지우는 문장 잣대」부터 되살리세요** —"
say "      묶음이 아니라 **이미지를 다시 굽는 것**이 재고의 올리는 길입니다."
MIGCK_SEEN=0
s=$(ls -1 "$IVD/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
j=$(grep -o '"idx"' "$IVD/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
MIGCK_SEEN=$((MIGCK_SEEN+1))
say ".sql ${s:-?}장 · meta/_journal.json 의 idx ${j:-?}개 (기대 $INV_SQL_WANT · $INV_SQL_WANT)"
if [ "${s:-x}" = "$INV_SQL_WANT" ] && [ "${j:-x}" = "$INV_SQL_WANT" ]; then
  ok "저장소 drizzle/ 이 ${INV_SQL_WANT}장이고 목록도 ${INV_SQL_WANT}개다 (쉰여덟째가 올린 수 그대로)"
else
  bad "저장소가 .sql ${s:-?} · idx ${j:-?} 다 — ${INV_SQL_WANT}·${INV_SQL_WANT} 를 기대했다"
  say "      🔴 **.sql 과 idx 가 다르면** 목록에 없는 파일이 있다는 뜻이고,"
  say "         drizzle 이 그것을 **아예 모릅니다**(적용이 0건으로 조용히 끝납니다)."
  doubt
fi
MIGCK_SEEN=$((MIGCK_SEEN+1))
dn=$(git -C "$IVD" diff --name-only "$INV_BASE..main" -- drizzle 2>/dev/null | tr -d '\r' | grep -c . || true)
say "이번 범위의 drizzle/ 변경 ${dn:-?}줄 (기대 $INV_DRIZZLE_DIFF_WANT)"
if [ "${dn:-x}" = "$INV_DRIZZLE_DIFF_WANT" ]; then
  ok "이번 범위가 drizzle/ 을 **한 줄도 안 건드렸다** — 🔴 **올릴 마이그레이션이 없다**"
  say "      🔵 그래서 69-deploy.sh 에는 **--migrate 모드가 없습니다.**"
else
  bad "drizzle/ 변경이 ${dn:-?}줄 있다 — 0 을 기대했다"
  say "      🔴 **이 배포본에는 마이그레이션을 올리는 절이 없습니다.** 멈추고 알리세요."
  git -C "$IVD" diff --name-only "$INV_BASE..main" -- drizzle 2>/dev/null | sed 's/^/        /'
fi
MIGCK_SEEN=$((MIGCK_SEEN+1))
nx=$(ls -1 "$IVD/drizzle/${INV_NEXT_MIG}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
say "$INV_NEXT_MIG 이 생겼는가: ${nx:-?}개 (기대 0)"
if [ "${nx:-1}" = "0" ]; then
  ok "$INV_NEXT_MIG 이 없다 (마지막이 0027 그대로 — 적용 대기 **0건**)"
else
  bad "$INV_NEXT_MIG 이 **생겼다** — 이 배포본은 0027 까지를 전제로 쓰였다. 멈추고 알릴 것"
fi
[ "$MIGCK_SEEN" = "3" ] && ok "마이그레이션 검사 셋을 다 돌았다 (표본이 비지 않았다)" \
  || bad "마이그레이션 검사를 ${MIGCK_SEEN}개만 돌았다 — 3개를 기대했다"
say ""
say "🔵 **운영이 지금 들고 있어야 하는 수** — $PROD_MIGS_NOTE"
say "   🔴 **개발 PC 에서는 못 잽니다.** 69-deploy.sh --check 가 DB 에 물어 확인하고,"
say "      어긋나면 **거기서 멈춥니다.** 어긋나면 그것은 **이 배포와 무관한 다른 사고**입니다."

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 담는 길 · 굽는 까닭 · 소스가 새 코드를 담고 있나 ────────────
# ══════════════════════════════════════════════════════════════════════
step "5. 🔴 담는 길 · 굽는 까닭 · 소스가 새 코드를 담고 있나"

# 5-ㄱ. Dockerfile 이 담는 길
say "── 5-ㄱ. Dockerfile 의 COPY 줄 — 🔴 **굽는 까닭이 여기 있다**"
say "🔴 **A/S 와 뜻이 반대인 줄이 둘입니다**(drizzle 과 vendor). 그대로 베끼면"
say "   멀쩡한 재고 Dockerfile 이 ✗ 가 납니다."
COPY_SEEN=0
DF="$IVD/Dockerfile"
while IFS='|' read -r RE WANT MSG; do
  [ -n "${RE:-}" ] || continue
  COPY_SEEN=$((COPY_SEEN+1))
  if [ ! -f "$DF" ]; then bad "재고의 Dockerfile 이 없다 ($DF)"; continue; fi
  n=$(grep -cE "$RE" "$DF" 2>/dev/null || true)
  ln=$(grep -nE "$RE" "$DF" 2>/dev/null | head -1 | cut -d: -f1)
  if [ "$WANT" = "yes" ]; then
    if [ "${n:-0}" -ge 1 ] 2>/dev/null; then ok "$MSG (${ln:-?}줄)"
    else bad "Dockerfile 에 그 COPY 가 **없다** — $MSG"; doubt; fi
  else
    if [ "${n:-1}" = "0" ]; then ok "$MSG"
    else bad "Dockerfile 에 그 COPY 가 **있다**(${ln}줄) — $MSG"; doubt; fi
  fi
done <<ENDCOPY
$(rows_of "$COPYRULES")
ENDCOPY
[ "$COPY_SEEN" = "$COPYRULES_WANT" ] && ok "COPY 규칙 ${COPYRULES_WANT}줄을 다 봤다 (표본이 비지 않았다)" \
  || bad "COPY 규칙을 ${COPY_SEEN}줄만 봤다 — ${COPYRULES_WANT}줄을 기대했다. 표가 깨졌다"
# 🔴 **tools 스테이지가 runner 보다 앞에 있는가** — 뒤에 있으면 docker build 의
#    기본 대상이 되어 **앱 자리에 도구 이미지가 구워진다**(그 집 Dockerfile 21~22줄).
tl=$(grep -n '^FROM .* AS tools' "$DF" 2>/dev/null | head -1 | cut -d: -f1)
rl=$(grep -n '^FROM .* AS runner' "$DF" 2>/dev/null | head -1 | cut -d: -f1)
say "FROM … AS tools ${tl:-?}줄 · FROM … AS runner ${rl:-?}줄 (🔴 tools 가 **앞**이어야 한다)"
if isnum "${tl:-}" && isnum "${rl:-}" && [ "${tl}" -lt "${rl}" ]; then
  ok "tools 가 runner 보다 앞에 있다 (기본 대상이 runner 다 — 앱이 제대로 구워진다)"
else
  bad "스테이지 차례가 tools ${tl:-?} · runner ${rl:-?} 다 — tools 가 앞이어야 한다"
  say "      🔴 마지막 스테이지가 기본 대상입니다. 뒤집히면 **앱 태그에 도구가 구워집니다.**"
  doubt
fi

# 5-ㄴ. .dockerignore — .next 를 막는가 · 🔴 **tests 를 막는가**
say ""
say "── 5-ㄴ. .dockerignore — .next 를 막는가 · 🔴 **tests 를 막는가**"
say "🔴 **tests 줄이 「15 중 12」의 까닭입니다.** 추측으로 두지 않고 값으로 셉니다 —"
say "   이 줄이 사라지면 ㄴ 잣대의 기대값이 12 가 아니라 15 가 되어야 합니다."
DI="$IVD/.dockerignore"
if [ ! -f "$DI" ]; then bad "재고에 .dockerignore 가 없다 — 🔴 호스트의 .next 가 섞여 들어간다"
else
  n=$(grep -c '^\.next' "$DI" 2>/dev/null || true)
  say ".dockerignore 의 ^.next 줄 ${n:-?}개 (기대 1 이상)"
  [ "${n:-0}" -ge 1 ] 2>/dev/null && ok ".dockerignore 가 .next 를 막는다 (dev 서버를 안 내려도 된다)" \
    || bad ".dockerignore 가 .next 를 **안 막는다** — dev 서버를 내리고 구워야 한다"
  n=$(grep -c '^tests$' "$DI" 2>/dev/null || true)
  say ".dockerignore 의 ^tests$ 줄 ${n:-?}개 (기대 1)"
  if [ "${n:-x}" = "1" ]; then
    ok "🔴 **tests/ 가 빌드 맥락에서 빠진다** — 그래서 바뀐 15장 중 ${TOOLS_PAYLOAD_WANT}장만 담긴다"
  else
    bad "tests 를 막는 줄이 ${n:-?}개다 — 1 을 기대했다"
    say "      🔴 막지 않으면 바뀐 **15장이 다 담깁니다** — 그러면 ㄴ 잣대의 기대값"
    say "         ${TOOLS_PAYLOAD_WANT} 가 틀린 것이고, 아래 ✗ 는 **검사 쪽 탓**입니다."
    doubt
  fi
fi

# 5-ㄷ. 🔴 **굽는 까닭 ㄱ** — npm 명령 수
say ""
say "── 5-ㄷ. 🔴 굽는 까닭 **ㄱ** — npm 명령이 늘었나 (scripts 블록 안만 센다)"
say "🔴 「안 걸린다」도 **값으로 잽니다.** 바뀌었는데 0 으로 적어 두면 다음 판이"
say "   그 거짓을 근거로 「안 구워도 된다」를 꺼냅니다."
a=$(git -C "$IVD" show "$INV_BASE:package.json" 2>/dev/null </dev/null | count_scripts)
b=$(count_scripts < "$IVD/package.json")
say "npm 명령 — 기준 ${a:-?} → 지금 ${b:-?} (적어 둔 값 $NPM_WAS → $NPM_NOW)"
if [ "${a:-x}" = "$NPM_WAS" ] && [ "${b:-x}" = "$NPM_NOW" ]; then
  if [ "$NPM_WAS" = "$NPM_NOW" ]; then ok "npm 명령이 안 늘었다 — **ㄱ 잣대가 안 걸린다**"
  else ok "npm 명령이 $NPM_WAS → $NPM_NOW 로 늘었다 — 🔴 **ㄱ 잣대가 걸린다**"; fi
else
  bad "npm 명령이 ${a:-?} → ${b:-?} 다 — $NPM_WAS → $NPM_NOW 를 기대했다"
  say "      🔴 늘었으면 **도구를 안 구우면 Missing script** 가 납니다(41번이 겪었다)."
  doubt
fi
pk=$(git -C "$IVD" diff --numstat "$INV_BASE..main" -- package.json package-lock.json tsconfig.json drizzle.config.ts 2>/dev/null | wc -l | tr -d ' ')
say "package.json · package-lock.json · tsconfig.json · drizzle.config.ts 의 바뀐 파일 ${pk:-?}장 (기대 0)"
if [ "${pk:-1}" = "0" ]; then
  ok "의존성·설정 파일이 **한 장도 안 바뀌었다**"
  say "      🔴 그래서 tar 크기 견주기를 **둘 다 strict** 로 두었습니다."
else
  note "그 넷 중 ${pk}장이 바뀌었다 — 0을 기대했다. **이미지 크기가 뛸 수 있습니다.** 사람이 보세요"
fi

# 5-ㄹ. 🔴 **굽는 까닭 ㄴ·ㄷ·ㄹ·ㅁ**
say ""
say "── 5-ㄹ. 🔴 굽는 까닭 **ㄴ·ㄷ·ㄹ·ㅁ** — 도구 이미지를 굽는 까닭을 값으로 댄다"
LIST=$(git -C "$IVD" diff --name-only "$INV_BASE..main" 2>/dev/null | tr -d '\r')
all=$(printf '%s\n' "$LIST" | grep -c . || true)
pay=$(printf '%s\n' "$LIST" | grep -cE "$TOOLS_PAYLOAD_RE" || true)
say "ㄴ) tools 스테이지가 담는 것 중 바뀐 파일 — ${pay:-?} / ${all:-?} 장 (적어 둔 값 $TOOLS_PAYLOAD_WANT / $CH_ALL)"
say "🔴 68번은 이 자리가 **8 / 8** 이었습니다 — 베껴 쓰면 틀렸을 자리라 다시 셌습니다."
say "🔵 **빠지는 셋은 전부 tests/** 입니다 — .dockerignore 가 막습니다(5-ㄴ 이 쟀습니다)."
printf '%s\n' "$LIST" | sed 's/^/        /'
if [ "${pay:-x}" = "$TOOLS_PAYLOAD_WANT" ] && [ "${all:-x}" = "$CH_ALL" ]; then
  if [ "${pay:-0}" -ge 1 ] 2>/dev/null; then
    ok "🔴 **ㄴ 잣대가 걸린다** — 바뀐 ${all}장 중 ${pay}장이 도구 이미지 안으로 들어간다"
  else
    ok "ㄴ 잣대가 안 걸린다 (도구가 담는 것 중 바뀐 것이 0장이다)"
  fi
else
  note "ㄴ 의 수가 ${pay:-?} / ${all:-?} 다 — $TOOLS_PAYLOAD_WANT / $CH_ALL 을 기대했다. **사람이 보세요**"
  say "      🔵 커밋이 하나 더 밀렸으면 여기가 먼저 어긋납니다(2절의 ⚠️ 와 짝입니다)."
fi
say ""
say "ㄷ) 🔴 **도구의 import 닫힘 — 이번 판에 실제로 걸린다**"
say "🔴 67·68번은 **두 판 연속** 이 잣대가 안 걸렸습니다(과녁이 0줄이었습니다)."
say "   🔴 **이번 판이 그 잣대의 실물입니다** — scripts/ 의 둘이 부르는 모듈"
say "   (src/db/schema/app-settings.ts)이 **이번 범위에 들어 있습니다.** 도구를"
say "   안 구우면 그 둘이 **옛 몸통**으로 돕니다."
say "🔵 그래서 65번과 **같은 까닭**으로 도구를 굽습니다 — 68번은 ㄴ 하나였습니다."
IMP_SEEN=0; IMP_OK=0
tn=$(printf '%s\n' "$LIST" | grep -cFx "$TOOL_IMPORT_TARGET" || true)
say "바뀐 목록에 $TOOL_IMPORT_TARGET 이 ${tn:-?}줄 (기대 $TOOL_IMPORT_TARGET_WANT)"
if [ "${tn:-x}" = "$TOOL_IMPORT_TARGET_WANT" ]; then
  if [ "$TOOL_IMPORT_TARGET_WANT" = "0" ]; then
    ok "그 모듈이 **이번 범위에 0줄이다** — ㄷ 잣대는 안 걸린다 (잣대만 재 둔다)"
  else
    ok "🔴 **ㄷ 잣대가 걸린다** — 그 모듈이 이번 범위에 ${tn}줄이다"
  fi
else
  note "그 모듈이 바뀐 목록에 ${tn:-?}줄이다 — $TOOL_IMPORT_TARGET_WANT 을 기대했다. **사람이 보세요**"
  say "      🔵 0 이면 ㄷ 가 안 걸리는 것이라 **굽는 까닭이 하나 주는 것**입니다 —"
  say "         그래도 ㄴ 하나로 굽는 까닭이 섭니다(막을 일이 아닙니다)."
fi
while IFS='|' read -r F IMP; do
  [ -n "${F:-}" ] || continue
  IMP_SEEN=$((IMP_SEEN+1))
  if [ ! -f "$IVD/$F" ]; then bad "$F 가 없다 — 표가 틀렸다"; continue; fi
  n=$(grep -cF -- "$IMP" "$IVD/$F" 2>/dev/null || true)
  printf '      %-40s [%s] %s줄\n' "$F" "$IMP" "${n:-?}"
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then IMP_OK=$((IMP_OK+1))
  else bad "$F 가 그 모듈을 안 부른다 — 표가 틀렸다"; fi
done <<ENDIMP
$(rows_of "$TOOL_IMPORTERS")
ENDIMP
say "본 것 ${IMP_SEEN} · 부르는 것 ${IMP_OK} (기대 $TOOL_IMPORTERS_WANT · $TOOL_IMPORTERS_WANT)"
if [ "$IMP_SEEN" = "$TOOL_IMPORTERS_WANT" ] && [ "$IMP_OK" = "$TOOL_IMPORTERS_WANT" ]; then
  ok "ㄷ 잣대가 **살아 있다** — 도구 스크립트 ${IMP_OK}장이 그 모듈을 부른다"
  say "      🔴 그 둘은 **가져오기**(import-workbook)와 **옛 자료 심기**(seed-demo-legacy)입니다 —"
  say "         전환일 열쇠를 그 모듈에서 꺼내 씁니다. 옛 몸통으로 돌면 조용히 어긋납니다."
else
  bad "본 것 ${IMP_SEEN} · 부르는 것 ${IMP_OK} 다 — ${TOOL_IMPORTERS_WANT} 을 기대했다"
  doubt
fi
say ""
say "ㄹ) 공용 묶음(vendor/*)이 움직였나 — 3-ㄴ 에서 **0줄**로 쟀다 → **안 걸린다**"
say "   🔵 재고의 tools 는 **vendor 를 담지도 않습니다**(5-ㄱ) — 움직여도 도구는"
say "      안 바뀝니다. 🔴 다만 **앱**은 바뀝니다(builder 가 통째로 담습니다)."
say ""
say "ㅁ) 🔵 **마이그레이션은 0건이다** — 묶음을 만들 까닭이 없다(4절이 값으로 쟀다)."
say "   🔴 **재고는 애초에 묶음을 안 씁니다** — .sql 이 도구 이미지 안에 구워집니다."
say "      1건이라도 생기는 판에서는 **62번의 지우는 문장 잣대와 그 표본**을 넣고,"
say "      올리는 길은 **묶음이 아니라 도구 이미지를 다시 굽는 것**입니다."
say ""
say "🔴 **결론: 도구 이미지를 굽는다.** ㄴ 과 ㄷ **둘**이 걸렸다(ㄱ·ㄹ·ㅁ 은 안 걸렸다)."
say "   🔵 반대 방향의 사고도 이 저장소에 적혀 있습니다 — 「마이그레이션 0건이니"
say "      도구는 안 굽는다」가 틀려 비상구 둘을 못 올린 적이 있고, 이튿날에는"
say "      거꾸로 「명령이 늘어난 것」을 놓쳐 Missing script 가 났습니다."

# 5-ㅁ. 바뀐 파일 수
say ""
say "── 5-ㅁ. 바뀐 파일 수 — 🔴 **68번과 같은 자리가 거의 없다**"
say "🔴 **대괄호 셈은 66번이 더한 것입니다.** 67번은 0 · 68번은 1 이었고 **이번 판은"
say "   다시 0 입니다** — 그래도 안 뺍니다. 「0이니 뺀다」를 한 번 하면 다음에 1 이"
say "   되는 날 아무도 못 봅니다."
src=$(printf '%s\n' "$LIST" | grep -c '^src/' || true)
tst=$(printf '%s\n' "$LIST" | grep -c '^tests/' || true)
scr=$(printf '%s\n' "$LIST" | grep -c '^scripts/' || true)
drz=$(printf '%s\n' "$LIST" | grep -c '^drizzle/' || true)
ven=$(printf '%s\n' "$LIST" | grep -cE '^(vendor/|\.gitmodules)' || true)
par=$(printf '%s\n' "$LIST" | grep -cF '(' || true)
brk=$(printf '%s\n' "$LIST" | grep -cF '[' || true)
new=$(git -C "$IVD" diff --diff-filter=A --name-only "$INV_BASE..main" 2>/dev/null | grep -c . || true)
del=$(git -C "$IVD" diff --diff-filter=D --name-only "$INV_BASE..main" 2>/dev/null | grep -c . || true)
printf '      전체 %-4s src %-4s tests %-3s scripts %-3s drizzle %-2s vendor %-2s 새 %-3s 지움 %-2s 괄호 %-2s 대괄호 %s\n' \
  "${all:-?}" "${src:-?}" "${tst:-?}" "${scr:-?}" "${drz:-?}" "${ven:-?}" "${new:-?}" "${del:-?}" "${par:-?}" "${brk:-?}"
printf '      (적어 둔 값) %-4s     %-4s       %-3s         %-3s         %-2s        %-2s    %-3s      %-2s      %-2s       %s\n' \
  "$CH_ALL" "$CH_SRC" "$CH_TESTSDIR" "$CH_SCRIPTS" "$CH_DRIZZLE" "$CH_VENDOR" "$CH_NEW" "$CH_DEL" "$CH_PAREN" "$CH_BRACKET"
if [ "${all:-x}" = "$CH_ALL" ] && [ "${src:-x}" = "$CH_SRC" ] && [ "${tst:-x}" = "$CH_TESTSDIR" ] \
   && [ "${scr:-x}" = "$CH_SCRIPTS" ] && [ "${drz:-x}" = "$CH_DRIZZLE" ] && [ "${ven:-x}" = "$CH_VENDOR" ] \
   && [ "${new:-x}" = "$CH_NEW" ] && [ "${par:-x}" = "$CH_PAREN" ] && [ "${brk:-x}" = "$CH_BRACKET" ]; then
  ok "바뀐 파일 수가 적어 둔 것과 전부 같다"
else
  note "바뀐 파일 수가 적어 둔 것과 다르다 — **사람이 보세요**"
  say "      🔵 커밋이 하나 더 밀렸으면 여기가 먼저 어긋납니다(2절의 ⚠️ 와 짝입니다)."
fi
if [ "${del:-1}" = "$CH_DEL" ]; then ok "지운 파일 ${CH_DEL}장"
else bad "🔴 파일을 ${del}장 **지웠다** — 0 을 기대했다. 멈추고 알릴 것"; fi
# 🔴 **src + tests 가 전체와 맞는가** — 「12 와 3」이 서로 다른 수를 말하지 않게.
if isnum "${src:-}" && isnum "${tst:-}" && isnum "${all:-}"; then
  printf '      src %s + tests %s = %s (전체 %s)\n' "$src" "$tst" "$((src + tst))" "$all"
  [ "$((src + tst))" = "$all" ] && ok "src 와 tests 가 전체를 덮는다 (다른 폴더는 0장이다)" \
    || bad "src + tests 가 $((src + tst)) 다 — 전체 ${all} 를 기대했다. 다른 폴더가 섞였다"
else
  unk "src+tests 관문" "앞의 수 중 못 잰 것이 있다"
fi
say "🔴 **이번 범위에는 괄호가 든 경로가 ${CH_PAREN}장 있습니다**(68번은 1장이었습니다):"
printf '%s\n' "$LIST" | grep -F '(' | sed 's/^/        /'
say "   🔵 **대괄호는 ${CH_BRACKET}장입니다**(68번은 1장이었습니다) — 이번 판에는 없습니다."
say "   🔵 그래도 목록을 넘기는 길은 here 문서 + grep -Fx 로만 썼고 컨테이너 안에서는"
say "      set -f 로 글롭을 끕니다. 괄호도 글롭이 켜져 있으면 조용히 어긋날 수 있고,"
say "      **대괄호가 다시 생기는 날** 그 길이 그대로 받아 냅니다."

# 5-ㅂ. 🔴 표식 — 소스에서 먼저 센다
say ""
say "── 5-ㅂ. 🔴 표식 — **소스에서 먼저 센다** (기능 0→N · 뒷걸음 N→N)"
say "🔴 기능 표식은 **이번 판에 태어난 DOM id** 입니다 — 색 고르개의 이름표가"
say "   가리키는 입력 칸의 id 이고, **문자열 리터럴**이라 minify 가 이름을 못 바꿉니다."
say "🔴 **지시서의 수를 그대로 믿지 않고 다시 셌습니다**(src 안)."
MARK_SEEN=0
check_mark "$APPMARK"   feature "$APPMARK_NOTE"
check_mark "$KEEPMARK1" keep    "$KEEPMARK1_NOTE"
check_mark "$KEEPMARK2" keep    "$KEEPMARK2_NOTE"
check_mark "$KEEPMARK3" keep    "$KEEPMARK3_NOTE"
[ "$MARK_SEEN" = "$MARKS_WANT" ] && ok "표식 ${MARKS_WANT}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "표식을 ${MARK_SEEN}개만 봤다 — ${MARKS_WANT}개를 기대했다"
say "🔵 뒷걸음 표식이 **셋**인 까닭: 쉰여덟째 · 그 앞 판 · 지난 판이 올린 글자를"
say "   하나씩 잡고 있습니다 — **하나도 빼지 마세요.** 뺀 자리는 다시 넣는 사람이 없습니다."
say "🔴 그중 **TOOLBAR_BTN_PRIMARY 만은 앱 번들에서 안 셉니다** — 모듈 안의 const"
say "   이름이라 minify 가 **이름을 바꿉니다.** 번들에서 0 이 나오고 그 ✗ 는 진짜"
say "   결함처럼 보입니다. 🔵 62번이 그것을 **도구 이미지의 소스 글자**로 쟀습니다 —"
say "   **그 자리로 되돌렸습니다**(inside_check 의 도구 쪽에서 2줄을 셉니다)."
say "🔵 번들에서 세는 뒷걸음은 **${BUNDLE_KEEPS_WANT}개**입니다(둘 다 DB 표 이름이라 문자열로 남습니다)."

# 5-ㅂ-2. 🔴 **그 글자가 주석만이 아닌가** — 66번에서 가져온 절
say ""
say "── 5-ㅂ-2. 🔴 **번들에 쓸 글자가 주석만이 아닌가** — 값으로 보인다"
say "🔴 「소스 글자로 재는 검사는 주석을 먼저 센다」가 이 저장소에 적혀 있습니다."
say "   🔴 **주석은 minify 가 지웁니다** — 주석에만 있는 글자를 표식으로 쓰면 번들에서"
say "      0 이 나오고, 그 ✗ 는 **진짜 결함처럼** 보입니다(66번이 거기서 글자를 갈았습니다)."
say "🔴 **68번은 기능 표식 하나만 걸렀습니다. 여기서는 번들에 쓰는 셋을 다 거릅니다** —"
say "   뒷걸음 표식 둘은 날것이 14파일·10파일이라 **눈으로는 넉넉해 보이지만**,"
say "   그 대부분이 **주석**입니다(아래 수가 그것을 보여 줍니다)."
NET_SEEN=0
mark_net() { # 1 글자 2 사람이 읽을 말
  local raw net code seen f n
  NET_SEEN=$((NET_SEEN+1))
  raw=$(grep -rlF -- "$1" "$IVD/src" 2>/dev/null | wc -l | tr -d ' ')
  net=0; code=0; seen=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    seen=$((seen+1))
    n=$(grep -vE '^[[:space:]]*(//|\*|/\*)' "$f" 2>/dev/null | grep -cF -- "$1" || true)
    isnum "${n:-}" || n=0
    if [ "${n:-0}" -ge 1 ]; then
      net=$((net + 1))
      # 🔵 **시험 파일은 이미지에 안 담긴다** — 재고의 시험은 tests/ 아래라 여기
      #    src/ 안에는 거의 없지만, src/lib/xlsx/*.test.ts 가 있어 잣대를 그대로 둔다.
      case "$f" in (*.test.ts|*.test.tsx) ;; (*) code=$((code + 1)) ;; esac
    fi
  done <<ENDNET
$(grep -rlF -- "$1" "$IVD/src" 2>/dev/null)
ENDNET
  say "[$1] in src — 날것 ${raw:-?}파일 · **주석을 걷은 뒤 ${net}파일** · 그중 시험이 아닌 것 ${code}파일 (본 파일 ${seen}장) — $2"
  if [ "${seen:-0}" != "${raw:-x}" ]; then
    bad "본 파일이 ${seen}장인데 날것은 ${raw:-?}파일이다 — **목록을 넘기는 길이 끊겼다.** 위 수를 못 믿는다"
  elif [ "${raw:-0}" = "0" ]; then
    bad "src/ 에 [$1] 이 **한 파일도 없다** — 주석 문제가 아니라 **글자가 틀렸다**"
    doubt
  elif [ "${net:-0}" -ge 1 ] 2>/dev/null && [ "${code:-0}" -ge 1 ] 2>/dev/null; then
    ok "[$1] 이 주석을 걷고도 ${net}파일에 남고, 그중 ${code}장이 **시험이 아닌 코드**다 (번들 표식으로 쓸 수 있다)"
  elif [ "${net:-0}" -ge 1 ] 2>/dev/null; then
    bad "[$1] 이 주석을 걷으면 ${net}파일이 남지만 **전부 시험 파일**이다 — 시험은 이미지에 안 담긴다"
    doubt
  else
    bad "[$1] 이 주석을 걷으면 **0파일**이다 — 🔴 이 글자는 src/ 에서 **주석에만** 있습니다"
    say "      🔴 minify 가 주석을 지우므로 번들 표식으로 못 씁니다. 다른 글자를 고르세요."
    doubt
  fi
}
mark_net "$APPMARK"   "기능 표식"
mark_net "$KEEPMARK1" "뒷걸음 ①"
mark_net "$KEEPMARK2" "뒷걸음 ②"
say "본 글자 ${NET_SEEN}개 (기대 3 — 기능 하나 + 번들에서 세는 뒷걸음 ${BUNDLE_KEEPS_WANT}개)"
[ "$NET_SEEN" = "3" ] && ok "번들에 쓰는 글자 셋을 다 걸렀다 (표본이 비지 않았다)" \
  || bad "걸른 글자가 ${NET_SEEN}개다 — 3개를 기대했다"
say "🔴 **TOOLBAR_BTN_PRIMARY 는 여기에 없습니다** — 번들에 안 쓰기 때문입니다(5-ㅂ)."

# 5-ㅂ-3. 🔵 **보조 표식** — 판정은 하되 번들에는 안 쓴다
say ""
say "── 5-ㅂ-3. 🔵 보조 표식 — 라우트 경로 (번들에는 **안 씁니다**)"
say "🔵 [설정] → [도번 표시] 가 서는 길입니다. 🔴 번들 표식으로 안 쓰는 까닭은"
say "   **담기는 자리가 판마다 다르기** 때문입니다(라우트 매니페스트·서버 청크)."
say "   소스에서 0 → N 인 것만 값으로 보여 둡니다."
a=$(mark_was "$INV_BASE" "$AUXMARK"); b=$(mark_now "$AUXMARK")
say "[$AUXMARK] — 기준 ${a:-?} → 지금 ${b:-?} (적어 둔 값 $AUXMARK_WAS → $AUXMARK_NOW)"
if [ "${a:-x}" = "0" ] && [ "${b:-0}" -ge 1 ] 2>/dev/null; then
  ok "보조 표식이 **이번 판에만 있다** (설정 화면이 그 길로 섭니다)"
  [ "${b:-x}" = "$AUXMARK_NOW" ] || note "지금이 ${b}파일이다 — $AUXMARK_NOW 을 기대했다. 사람이 보세요"
else
  note "보조 표식이 기준 ${a:-?} → 지금 ${b:-?} 다 — 0 → 1 이상을 기대했다. **사람이 보세요**"
fi

# 5-ㅅ. 🔴 도구 이미지가 쓸 **마지막 커밋 표식** — 소스에서 먼저 센다
say ""
say "── 5-ㅅ. 🔴 **마지막 커밋 표식**(도구 이미지용) — 소스에서 먼저 센다"
say "🔴 이것은 **이번 판에 태어난 조각 이름**입니다 — 도번 줄을 그리는 공용 조각이고,"
say "   어제까지는 그 과녁 파일에 한 줄도 없었습니다."
say "🔵 **새로 생긴 파일을 과녁으로 삼지 않았습니다**(66·67·68번과 같은 판단) — 새 파일을"
say "   과녁으로 쓰면 「기준 0줄」이 **파일이 없어서 0** 인 것이라 아무것도 안 가릅니다."
say "🔴 **그 사실도 git 에서 직접 셉니다**(적어 둔 값을 안 믿습니다) — 바로 그 믿음이"
say "   기능 표식을 **네 판 연속** 틀리게 했습니다."
if [ ! -f "$IVD/$TOOLMARK_FILE" ]; then
  bad "$TOOLMARK_FILE 이 없다 (표식을 둘 자리가 없다)"
else
  if git -C "$IVD" cat-file -e "$INV_BASE:$TOOLMARK_FILE" 2>/dev/null; then
    ok "과녁 파일이 **기준판에도 있었다** (「기준 0줄」이 공짜 ✓ 가 아니다)"
  else
    bad "과녁 파일이 기준판에 **없었다** — 그러면 기준 0줄은 아무것도 안 가른다"
    say "      🔴 기준판에도 있던 파일을 과녁으로 고르세요."
    doubt
  fi
  was=$(git -C "$IVD" show "$INV_BASE:$TOOLMARK_FILE" 2>/dev/null </dev/null | grep -cF -- "$TOOLMARK" || true)
  n=$(grep -cF -- "$TOOLMARK" "$IVD/$TOOLMARK_FILE" 2>/dev/null || true)
  say "[$TOOLMARK] in $TOOLMARK_FILE — 기준 ${was:-?}줄 → 지금 ${n:-?}줄 (기대 $TOOLMARK_LINES_WAS → $TOOLMARK_LINES_WANT)"
  if [ "${was:-x}" = "$TOOLMARK_LINES_WAS" ]; then
    ok "그 파일 안에서는 기준판에 **0줄**이었다 (이 표식이 판을 **가른다**)"
  else
    bad "기준판의 그 파일에 그 글자가 ${was:-?}줄 있다 — $TOOLMARK_LINES_WAS 을 기대했다"
    say "      🔴 0 이 아니면 그 표식은 **이 판을 안 가릅니다.** 다른 글자를 고르세요."
    say "      🔵 **68번은 이 줄에 0 을 글자로 박아 두었습니다** — 적어 둔 값이 0 이"
    say "         아닌 판에서는 「0줄 있다 — 0 을 기대했다」라는 **말이 안 되는 ✗** 가"
    say "         납니다. 변수로 바꿔 두었습니다."
    doubt
  fi
  if [ "${n:-x}" = "$TOOLMARK_LINES_WANT" ]; then ok "마지막 커밋 표식이 그 파일에 ${n}줄 있다"
  elif [ "${n:-0}" -ge 1 ] 2>/dev/null; then note "그 글자가 ${n}줄이다 — $TOOLMARK_LINES_WANT 을 기대했다. 사람이 보세요"
  else bad "마지막 커밋 표식이 그 파일에 **없다** — 표가 틀렸다"; fi
  say "      🔵 4줄 중 **둘이 코드**(import 한 줄 · 그리는 한 줄)이고 **둘이 주석**입니다."
  say "         🔴 도구 이미지는 **소스가 글자 그대로** 들어가므로 주석도 같이 셉니다 —"
  say "         앱 번들과 달리 여기서는 그것이 맞습니다."
fi
# 🔴 그 표식이 가리키는 **새 모듈**이 작업본에 있는가.
if [ -f "$IVD/$TOOLMARK_MODULE" ]; then
  ok "그 표식이 가리키는 **새 모듈이 작업본에 있다** ($TOOLMARK_MODULE)"
else
  bad "$TOOLMARK_MODULE 이 작업본에 **없다** — 화면이 import 에서 죽는다"
fi
# 🔴 **도구 이미지에서 셀 뒷걸음 표식**도 소스에서 먼저 센다 (62번의 표식을 내린 것)
say ""
say "🔵 **도구 이미지의 뒷걸음 표식**(62번이 쓰던 글자) — 소스에서 먼저 센다"
if [ ! -f "$IVD/$TOOLKEEP_FILE" ]; then
  bad "$TOOLKEEP_FILE 이 없다 — 지난 판의 표식을 둘 자리가 없다"
else
  was=$(git -C "$IVD" show "$INV_BASE:$TOOLKEEP_FILE" 2>/dev/null </dev/null | grep -cF -- "$TOOLKEEP" || true)
  n=$(grep -cF -- "$TOOLKEEP" "$IVD/$TOOLKEEP_FILE" 2>/dev/null || true)
  say "[$TOOLKEEP] in $TOOLKEEP_FILE — 기준 ${was:-?}줄 → 지금 ${n:-?}줄 (기대 $TOOLKEEP_LINES_WANT → $TOOLKEEP_LINES_WANT)"
  if [ "${was:-x}" = "$TOOLKEEP_LINES_WANT" ] && [ "${n:-x}" = "$TOOLKEEP_LINES_WANT" ]; then
    ok "지난 판의 도구 표식이 기준에도 지금에도 ${TOOLKEEP_LINES_WANT}줄 있다 (뒷걸음을 잴 수 있다)"
  else
    bad "지난 판의 도구 표식이 기준 ${was:-?} · 지금 ${n:-?} 줄이다 — 둘 다 $TOOLKEEP_LINES_WANT 을 기대했다"
    doubt
  fi
fi

# 5-ㅇ. 🔴 시험 등록 — 재고는 **글롭**이다
say ""
say "── 5-ㅇ. 🔴 시험 등록 — **재고는 글롭 방식이다** (A/S 와 다르다)"
say "🔴 **A/S 는 scripts/test-lists/*.txt 에 적어야 돕니다.** 재고는 package.json 의"
say "   test 줄이 **글롭 둘**을 들고 있어 **파일을 두면 돕니다** — 적을 곳이 없습니다."
say "   🔴 A/S 판의 「목록에 적혀 있나」를 그대로 베끼면 **적을 파일이 없어** ✗ 가"
say "      줄줄이 나고, 그 ✗ 는 **등록을 빠뜨린 것처럼** 보입니다."
say "🔵 여기서 재는 것은 둘입니다 — **글롭이 아직 살아 있는가**와"
say "   **새 시험이 그 글롭에 걸리는 자리에 있는가.**"
PKG="$IVD/package.json"
GLOB_SEEN=0; GLOB_OK=0
for g in "$INV_TEST_GLOB1" "$INV_TEST_GLOB2"; do
  GLOB_SEEN=$((GLOB_SEEN+1))
  n=$(grep -cF -- "$g" "$PKG" 2>/dev/null || true)
  printf '      test 줄의 글롭 [%s] %s줄\n' "$g" "${n:-?}"
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then GLOB_OK=$((GLOB_OK+1)); fi
done
say "본 글롭 ${GLOB_SEEN} · 살아 있는 것 ${GLOB_OK} (기대 2 · 2)"
if [ "$GLOB_SEEN" = "2" ] && [ "$GLOB_OK" = "2" ]; then
  ok "package.json 의 test 줄이 **글롭 둘을 그대로 들고 있다**"
else
  bad "글롭이 ${GLOB_OK}/2 개다 — 🔴 **빠진 글롭에 걸리던 시험은 조용히 안 돕니다**"
  doubt
fi
# 🔴 **걸리는 파일 수가 줄지 않았는가** — 글롭 방식에서의 「줄 수가 안 줄었다」다.
tb=$(git -C "$IVD" ls-tree -r --name-only "$INV_BASE" -- tests 2>/dev/null </dev/null | grep -cE '\.test\.ts$' || true)
tnow=$(git -C "$IVD" ls-tree -r --name-only main -- tests 2>/dev/null </dev/null | grep -cE '\.test\.ts$' || true)
xb=$(git -C "$IVD" ls-tree -r --name-only "$INV_BASE" -- src/lib/xlsx 2>/dev/null </dev/null | grep -cE '\.test\.ts$' || true)
xnow=$(git -C "$IVD" ls-tree -r --name-only main -- src/lib/xlsx 2>/dev/null </dev/null | grep -cE '\.test\.ts$' || true)
say "글롭에 걸리는 시험 — tests/ ${tb:-?} → ${tnow:-?} (적어 둔 값 $INV_TESTS_TESTSDIR_WAS → $INV_TESTS_TESTSDIR_NOW) · src/lib/xlsx/ ${xb:-?} → ${xnow:-?} (적어 둔 값 $INV_TESTS_XLSX_WAS → $INV_TESTS_XLSX_NOW)"
if ! isnum "${tb:-}" || ! isnum "${tnow:-}" || [ "${tb:-0}" -lt 50 ]; then
  bad "기준판 tests/ 를 ${tb:-못 읽음}개밖에 못 읽었다 — 🔴 **빈 결과는 삼켜진 오류일 수 있다.** 아래를 못 믿는다"
elif [ "${tnow}" -lt "${tb}" ]; then
  bad "tests/ 가 ${tb} → ${tnow} 로 **줄었다** — 🔴 누가 시험을 **지웠다.** 멈추고 알리세요"
elif [ "${tnow}" = "${tb}" ]; then
  bad "tests/ 가 ${tnow} **그대로다** — 새 시험이 ${INV_NEW_TESTS_WANT}장인데 한 장도 안 늘었다"
  doubt
else
  ok "tests/ 가 ${tb} → ${tnow} 로 **늘었다** (새 시험 ${INV_NEW_TESTS_WANT}장이 글롭에 걸리는 꼴이다)"
  [ "${tnow}" = "$INV_TESTS_TESTSDIR_NOW" ] && ok "적어 둔 값 $INV_TESTS_TESTSDIR_NOW 과도 같다" \
    || note "적어 둔 값은 $INV_TESTS_TESTSDIR_NOW 인데 ${tnow} 다 — 사람이 보세요"
  # 🔴 **기준판 쪽도 맞댄다** — 안 맞대면 이 값은 say 로 찍히기만 하고 **아무것도
  #    안 재는 글자**가 된다(일부러 90 으로 바꿔 돌려 보니 아무 말도 안 나왔다).
  [ "${tb}" = "$INV_TESTS_TESTSDIR_WAS" ] && ok "기준판 수도 적어 둔 값 $INV_TESTS_TESTSDIR_WAS 과 같다" \
    || note "기준판이 ${tb}개다 — $INV_TESTS_TESTSDIR_WAS 을 기대했다. 사람이 보세요"
fi
if [ "${xnow:-x}" = "${xb:-y}" ] && [ "${xnow:-x}" = "$INV_TESTS_XLSX_NOW" ]; then
  ok "src/lib/xlsx/ 가 ${xnow}개 그대로다 (둘째 글롭도 살아 있다)"
else
  note "src/lib/xlsx/ 가 ${xb:-?} → ${xnow:-?} 다 — $INV_TESTS_XLSX_WAS → $INV_TESTS_XLSX_NOW 를 기대했다. 사람이 보세요"
fi
# 🔴 새 시험 파일이 몇 개인가 — 이번 범위에서 추가된 *.test.ts(x) 를 센다.
nt=$(git -C "$IVD" diff --diff-filter=A --name-only "$INV_BASE..main" 2>/dev/null | tr -d '\r' | grep -cE '\.test\.tsx?$' || true)
say "이번 범위에서 **새로 생긴** 시험 파일 ${nt:-?}개 (기대 $INV_NEW_TESTS_WANT)"
git -C "$IVD" diff --diff-filter=A --name-only "$INV_BASE..main" 2>/dev/null | tr -d '\r' | grep -E '\.test\.tsx?$' | sed 's/^/        /'
if [ "${nt:-x}" = "$INV_NEW_TESTS_WANT" ]; then
  ok "새 시험 파일이 ${INV_NEW_TESTS_WANT}개다"
else
  bad "새 시험 파일이 ${nt:-?}개다 — $INV_NEW_TESTS_WANT 을 기대했다"
  doubt
fi
ct=$(printf '%s\n' "$LIST" | grep -cE '\.test\.tsx?$' || true)
say "이번에 **바뀐** 시험 파일 ${ct:-?}개 (적어 둔 값 $CH_TESTS · 그중 새것 $INV_NEW_TESTS_WANT)"
[ "${ct:-x}" = "$CH_TESTS" ] && ok "바뀐 시험이 ${CH_TESTS}개다 (표본을 바뀐 목록에서 뽑았다)" \
  || note "바뀐 시험이 ${ct:-?}개다 — $CH_TESTS 를 기대했다. 사람이 보세요"
# 🔴 **빈 표본 방지** — 바뀐 시험 셋이 글롭에 걸리는 자리에 **실제로 있는가.**
#    🔵 그리고 **없는 경로 하나를 함께 묻는다** — 「무조건 yes」인 검사인지 가른다.
got=0; seen=0
while IFS= read -r t; do
  [ -n "$t" ] || continue
  seen=$((seen+1))
  if [ -f "$IVD/$t" ]; then
    case "$t" in
      tests/*.test.ts|src/lib/xlsx/*.test.ts) got=$((got+1)) ;;
      *) printf '        🔴 글롭에 안 걸리는 자리 %s\n' "$t" ;;
    esac
  else
    printf '        🔴 없음 %s\n' "$t"
  fi
done <<ENDTCH
$(rows_of "$INV_TOUCHED_TESTS")
ENDTCH
probe=0
[ -f "$IVD/tests/__dss_probe_no_such_test__.test.ts" ] && probe=1
say "바뀐 시험 — 본 것 ${seen} · 글롭에 걸리는 것 ${got} (기대 $INV_TOUCHED_TESTS_WANT · $INV_TOUCHED_TESTS_WANT) · 없는 경로가 있다고 나왔나 ${probe}(기대 0)"
if [ "$probe" != "0" ]; then
  bad "**없는 시험 경로가 있다고 나왔다** — 검사가 깨졌다. 위 수도 못 믿는다"
elif [ "$seen" = "$INV_TOUCHED_TESTS_WANT" ] && [ "$got" = "$INV_TOUCHED_TESTS_WANT" ]; then
  ok "🔴 **바뀐 시험 ${INV_TOUCHED_TESTS_WANT}개가 전부 글롭에 걸리는 자리에 있다** (조용히 안 도는 시험이 없다)"
else
  bad "걸리는 것이 ${got}/${INV_TOUCHED_TESTS_WANT} 개다 — 🔴 **빠진 것은 오류 없이 조용히 안 돈다**"
  doubt
fi
say "🔴 **이 셋은 어느 이미지에도 안 담깁니다**(.dockerignore 의 tests 줄) — 그래서"
say "   시험 등록은 **저장소에서만** 잽니다. 이미지 안에서 세려 하면 영영 0 입니다."

# ── 6. 태그 ───────────────────────────────────────────────────────────
#   🔴 **기대값이 모드마다 뒤집힌다.**
#      --check·--go : 아직 **없어야** 한다(같은 태그를 덮으면 되돌릴 판이 사라진다)
#      --verify     : **있어야** 한다(이미 구운 것을 다시 재는 모드다)
if [ "$MODE" = "--verify" ]; then
  step "6. 태그가 **있나** — --verify 는 이미 구운 것을 다시 재는 모드다"
else
  step "6. 태그가 이미 있나 — 같은 태그를 다시 구우면 **되돌릴 판이 사라진다**"
fi
IMG_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  TAG=$(field "$r" 2)
  IMG_SEEN=$((IMG_SEEN+1))
  if docker image inspect "$TAG" >/dev/null 2>&1; then
    if [ "$MODE" = "--verify" ]; then ok "$TAG 가 있다 (이것을 다시 잰다)"
    else
      bad "$TAG 가 **이미 있다** — 다른 판을 그 태그로 덮으면 되돌릴 것이 없어진다"
      say "      🔵 이미 구우셨다면 **다시 굽지 말고** --verify 로 그것을 재세요:"
      say "         & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./69-build.sh --verify"
      say "      → 정말 지우려면: docker image rm $TAG"
    fi
  else
    if [ "$MODE" = "--verify" ]; then bad "$TAG 가 **없다** — --verify 는 구운 뒤에 쓰는 모드다"
    else ok "$TAG 가 아직 없다 (새로 굽는다)"; fi
  fi
done <<ENDIMG1
$(rows_of "$IMAGES")
ENDIMG1
[ "$IMG_SEEN" = "$HOWMANY" ] && ok "태그 ${HOWMANY}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "태그를 ${IMG_SEEN}개만 봤다 — ${HOWMANY}개를 기대했다. IMAGES 표가 깨졌다"
say ""
say "🔵 되돌릴 옛 판이 개발 PC 에 있는지도 찍습니다(없어도 막지 않습니다 — NAS 에 있으면 됩니다)."
OLD_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  OLD_SEEN=$((OLD_SEEN+1))
  PT=$(field "$r" 4)
  OLDTAG=$(printf '%s' "${PT%.tar}" | sed 's/-\([0-9][0-9.]*\)$/:\1/')
  if docker image inspect "$OLDTAG" >/dev/null 2>&1; then say "옛 판 있음 $OLDTAG"
  else say "옛 판 없음 $OLDTAG (개발 PC 에만 없는 것일 수 있습니다)"; fi
done <<ENDIMG2
$(rows_of "$IMAGES")
ENDIMG2
[ "$OLD_SEEN" = "$HOWMANY" ] && ok "옛 판 ${HOWMANY}개를 다 찍었다" \
  || bad "옛 판을 ${OLD_SEEN}개만 찍었다"

# ── 7. 산출물을 둘 자리 + 🔴 dev 서버 ────────────────────────────────
step "7. 산출물을 둘 자리"
if [ -d "$OUT" ]; then
  n=$(ls -1 "$OUT" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$MODE" = "--verify" ]; then
    say "$OUT 안 ${n}개 (--verify 는 **이미 구운 뒤**라 차 있는 것이 정상입니다)"
    ls -1 "$OUT" 2>/dev/null | head -15 | sed 's/^/        /'
    if [ "${n:-0}" -ge 1 ] 2>/dev/null; then ok "산출물 폴더에 파일이 ${n}개 있다"
    else bad "산출물 폴더가 비었다 — --verify 는 구운 뒤에 쓰는 모드다"; fi
  elif [ "${n:-0}" = "0" ]; then ok "$OUT 가 있고 비어 있다"
  else
    note "$OUT 에 이미 파일이 ${n}개 있다 — 아래를 보세요"
    ls -1 "$OUT" | head -15 | sed 's/^/        /'
    say "      🔴 **옛 tar 가 섞여 있으면 보낼 때 헷갈립니다.** 보내기 전에 이 폴더에서"
    say "         옛 tar 를 먼저 지우세요(쉰여섯째·쉰일곱째가 **두 판 연속** 그 자리를 밟았습니다)."
    say "      🔵 이번 판도 **묶음이 없습니다** — 옛 묶음(as-migrations.tar.gz)이 여기 보이면"
    say "         **보내지 마세요.** 그것은 A/S 것이고 재고와 아무 상관이 없습니다."
  fi
else
  say "$OUT 가 아직 없다 — --go 때 만든다 (--check 는 아무것도 안 만든다)"
  ok "산출물 자리를 쓸 수 있다"
fi
# 🔴 7-ㄴ. dev 서버 — 🔵 **떠 있는 것이 정상이다**
say ""
say "── 7-ㄴ. dev 서버 — **막지는 않는다. 값으로 찍는다**"
say "🔵 docker build 는 dev 서버를 안 내려도 됩니다(.dockerignore 가 .next 를 막습니다 — 5-ㄴ)."
say "🔵 **재고 dev 서버(3800)·포털(3100)과 DB 상자 셋이 떠 있는 것이 정상입니다** —"
say "   🔴 **끄지 마세요.** 이 파일은 DB 에 한 번도 안 붙습니다."
say "🔴 그래도 찍는 까닭: 3800번이 떠 있으면 **호스트의 npm run build** 가 .next 를"
say "   두고 다투고, 그 탓에 난 tsc 오류를 코드 탓으로 오해한 적이 있습니다."
say "   🔵 이 파일은 **호스트의 npm run build 를 한 번도 안 부릅니다** — docker build 만 합니다."
PORT_SEEN=0
for p in "$INV_PORT:재고 dev 서버" "$PORTAL_PORT:포털 dev 서버" "$INV_DB_PORT:재고 개발 DB(dss-inventory-db)" "$AS_DB_PORT:A/S 개발 DB(dss-pg-app)" "$AUTH_DB_PORT:포털 개발 DB(dss-pg-auth)"; do
  PORT_SEEN=$((PORT_SEEN+1))
  pn=${p%%:*}; nm=${p#*:}
  if netstat -an 2>/dev/null | grep -q "[:.]$pn[^0-9].*LISTEN"; then
    say "$nm ($pn) — **떠 있다** (🔵 정상입니다)"
  else
    say "$nm ($pn) — 안 떠 있다"
  fi
done
[ "$PORT_SEEN" = "5" ] && ok "포트 다섯을 다 봤다" || bad "포트를 ${PORT_SEEN}개만 봤다"
say "🔴 **next dev 는 포트가 차면 조용히 옆으로 비켜섭니다** — 위 수만으로 「안 떠 있다」를"
say "   단정하지 마세요. 이 줄은 판정에 쓰이지 않습니다."

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
}

# ══════════════════════════════════════════════════════════════════════
# ══ 이미지 안을 재는 길 — 🔴 **갈래마다 다른 것을 잰다** ══════════════
# ══════════════════════════════════════════════════════════════════════
#   🔴 앱과 도구는 담긴 것이 다르다 — 앱은 **번들**, 도구는 **소스 그대로**다.
#   🔴 한 잣대로 재면 가짜 ✗ 가 난다.
IMGFAIL=0
INSIDE_RAN=0
dock() { dockr run --rm --entrypoint sh "$@" 2>/dev/null | tr -d '\r'; }

# 🔴 목록 하나를 이미지 안에서 한 장씩 묻는다 — **없는 경로 하나를 함께** 묻는다.
#    🔵 set -f 로 글롭을 끈다 — 🔴 **이번 범위엔 괄호가 든 경로가 둘 있다**
#       (대괄호는 0이다). 괄호도 글롭이 켜져 있으면 조용히 어긋날 수 있다.
ask_files() { # 1 태그 2 목록(줄바꿈) 3 기대 수 4 사람이 부르는 말
  local v got seen probe
  v=$(dockr run --rm -e DSS_FILES="$2" -e DSS_MISS="$PROBE_MISS" --entrypoint sh "$1" -c \
    'set -f; printf "%s\n%s\n" "$DSS_FILES" "$DSS_MISS" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/        /'
  seen=$(printf '%s\n' "$v" | grep -c '^\(yes\|no \)' || true)
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  probe=$(printf '%s\n' "$v" | grep -c "^no  $PROBE_MISS" || true)
  printf '      %s — 본 것 %s · 있는 것 %s (기대 %s · %s) · 없는 경로가 no 로 나왔나 %s(기대 1)\n' \
    "$4" "${seen:-0}" "${got:-0}" "$(( $3 + 1 ))" "$3" "${probe:-0}"
  if [ "${probe:-0}" != "1" ]; then
    printf '  ✗ **없는 경로가 no 로 안 나왔다** — 「무조건 yes」인 검사다. 위 yes 도 못 믿는다\n'; IMGFAIL=1
  elif [ "${seen:-0}" = "$(( $3 + 1 ))" ] && [ "${got:-0}" = "$3" ]; then
    printf '  ✓ %s %s장이 다 담겼다 (표본이 비지 않았다)\n' "$4" "$3"
  else
    printf '  ✗ 본 것 %s · 있는 것 %s 다 — %s 를 기대했다\n' "${seen:-0}" "${got:-0}" "$3"; IMGFAIL=1
    printf '%s\n' "      🔴 본 것이 모자라면 **목록을 넘기는 길이 끊긴 것**(글롭 함정)이고,"
    printf '%s\n' "         있는 것만 모자라면 **옛 소스가 담긴 이미지**입니다."
  fi
}

# 🔴 번들 안에서 글자 하나를 센다 — **.next/server 와 .next/static 을 둘 다** 본다.
#    🔵 넷째 인자는 **판정에 안 쓰는 곁들이 값**이다. 이 판은 판정 글자가 **맨 글자**
#       라 「따옴표째 써도 되나」를 곁들여 찍어 다음 판이 로그에서 바로 읽게 한다.
#    🔴 곁들이 꼴은 맨 글자의 **부분집합**이라 맨 글자보다 클 수 없다.
bundle_mark() { # 1 태그 2 글자 3 사람이 부르는 말 4 (선택) 곁들여 찍을 글자
  local v s t d ds dt
  v=$(dockr run --rm -e M="$2" --entrypoint sh "$1" -c \
    'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  s=$(printf '%s' "$v" | awk '{print $1}'); t=$(printf '%s' "$v" | awk '{print $2}')
  printf '      [%s] — .next/server %s개 · .next/static %s개 (🔴 합이 1 이상이어야 한다)\n' "$2" "${s:-?}" "${t:-?}"
  if [ -n "${4:-}" ]; then
    d=$(dockr run --rm -e M="$4" --entrypoint sh "$1" -c \
      'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
    ds=$(printf '%s' "$d" | awk '{print $1}'); dt=$(printf '%s' "$d" | awk '{print $2}')
    printf '      [%s] — server %s개 · static %s개 (🔵 **판정에 안 쓰는 곁들이 값**)\n' "$4" "${ds:-?}" "${dt:-?}"
  fi
  if isnum "${s:-}" && isnum "${t:-}" && [ "$((s + t))" -ge 1 ]; then
    printf '  ✓ %s\n' "$3"
  else
    printf '  ✗ %s — **없다.** 올리지 마세요\n' "$3"; IMGFAIL=1
    printf '%s\n' "      🔵 **검사 자신도 의심하세요** — 이 글자는 소스에서만 세어 보았고"
    printf '%s\n' "         **번들에서 세어 본 적이 없습니다**(개발 PC 에 standalone 이 없습니다)."
    if [ -n "${4:-}" ] && isnum "${ds:-}" && isnum "${dt:-}" && [ "$((ds + dt))" -ge 1 ]; then
      printf '%s\n' "      🔴🔴 **세는 쪽이 깨졌습니다** — 맨 글자가 0 인데 곁들이 꼴이 1 이상입니다."
      printf '%s\n' "         곁들이 꼴은 맨 글자의 **부분집합**이라 그럴 수 없습니다. 이미지가"
      printf '%s\n' "         아니라 **이 검사를 먼저 보세요**(1-ㄴ 경로 번역 · grep 에 넘긴 글자)."
    fi
  fi
}

# 🔴 npm 명령을 **값으로 받아 본다** — Missing script 와 Cannot find module 을 가른다.
npm_probe() { # 1 태그 2 명령
  local v
  v=$(dockr run --rm --entrypoint sh "$1" -c "cd /app && npm run $2 2>&1 | head -40" 2>&1 | tr -d '\r')
  if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
    printf '  ✗ npm run %s — **Missing script** (41번과 같은 실패다)\n' "$2"; IMGFAIL=1
    printf '%s\n' "$v" | head -15 | sed 's/^/        /'
  elif printf '%s' "$v" | grep -qE 'Cannot find module|ERR_MODULE_NOT_FOUND|Cannot find package'; then
    printf '  ✗ npm run %s 가 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다\n' "$2"; IMGFAIL=1
    printf '%s\n' "$v" | head -15 | sed 's/^/        /'
  elif printf '%s' "$v" | grep -qiE 'DATABASE_URL|환경변수|connection string|ECONNREFUSED|getaddrinfo'; then
    printf '  ✓ npm run %s 가 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)\n' "$2"
  else
    printf '  ⚠️ npm run %s 의 답이 기대와 다르다 — 아래 15줄을 사람이 보세요\n' "$2"
    printf '%s\n' "$v" | head -15 | sed 's/^/        /'
  fi
}

# ══════════════════════════════════════════════════════════════════════
# ══ 🔴 이미지 **안**을 세는 함수 — 굽기와 --verify 가 **함께 쓴다** ══
# ══════════════════════════════════════════════════════════════════════
#   🔴 **두 벌로 적지 않는다.** 두 벌이면 한쪽만 고쳐져 어긋난다.
#   🔵 바깥에 IMGFAIL 을 남긴다(local 로 가리지 않는다).
inside_check() { # 1 열쇠 2 태그 3 타깃(-=앱)
  # 🔴 **몇 번 실제로 돌았는지 센다.** [실측 2026-11-18] 이 함수를 쓰는 자리보다
  #    **뒤에** 정의해 두었더니 「command not found」만 한 줄 찍히고 --verify 가
  #    **✗ 0 으로 통과**했다. 아무것도 안 재는 ✓ 의 실물이다.
  INSIDE_RAN=$((INSIDE_RAN + 1))
  KEY=$1; TAG=$2; TGT=$3
  IMGFAIL=0
  if [ "$TGT" = "-" ]; then
    # ── 앱 이미지 (번들이다 — 소스가 없다)
    printf '\n    ── %s 안을 센다 (**번들**이다 — 소스가 없다)\n' "$TAG"
    v=$(dock "$TAG" -c "test -f /app/server.js && echo yes || echo no")
    printf '      /app/server.js: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ runner 스테이지가 맞다 (node server.js 를 안다)\n'
    else printf '  ✗ /app/server.js 가 없다 — **runner 가 아닌 것을 구웠다.** 올리지 마세요\n'; IMGFAIL=1; fi
    # 🔴 **재고의 public/ 은 있는데 비어 있다**(ls -1 로 0개 — .gitkeep 은 숨은 파일).
    #    🔴 A/S 판(9개 이상)을 그대로 베끼면 **멀쩡한 재고 앱이 ✗** 가 된다.
    #       62번이 그 자리에서 가짜 ✗ 를 냈고, 그래서 ⚠️ 가지를 따로 둔다.
    v=$(dock "$TAG" -c 'if [ -d /app/public ]; then printf "yes %s\n" "$(ls -1 /app/public 2>/dev/null | wc -l)"; else printf "no 0\n"; fi')
    pst=$(printf '%s' "$v" | awk '{print $1}'); pn=$(printf '%s' "$v" | awk '{print $2}')
    printf '      /app/public: %s (파일 %s개 · 기대 %s · 재고는 참고 %s개)\n' "${pst:-못 읽음}" "${pn:-?}" "$INV_PUBLIC_WANT" "$INV_PUBLIC_N"
    if [ "${pst:-}" != "$INV_PUBLIC_WANT" ]; then
      printf '  ✗ /app/public 이 %s 다 — %s 를 기대했다\n' "${pst:-못 읽음}" "$INV_PUBLIC_WANT"; IMGFAIL=1
      printf '%s\n' "      🔵 없으면 COPY 가 /app/public not found 로 멈췄다는 뜻입니다."
    elif [ "${pn:-0}" = "0" ]; then
      printf '  ⚠️ public/ 은 있는데 **비어 있다** — 🔵 **재고는 원래 그렇습니다**(.gitkeep 한 장뿐)\n'
      printf '%s\n' "         🔴 A/S 는 9개를 기대합니다 — 그 수를 여기 들이대면 가짜 ✗ 가 납니다."
    else
      printf '  ✓ public/ 이 담겼다 (%s개 — 참고 %s개보다 늘었습니다. 사람이 보세요)\n' "$pn" "$INV_PUBLIC_N"
    fi
    bundle_mark "$TAG" "$APPMARK"   "번들에 **이번 판의 글자**가 있다 (소스에서는 $APPMARK_NOTE)" "$APPMARK_DIAG"
    bundle_mark "$TAG" "$KEEPMARK1" "쉰여덟째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$TAG" "$KEEPMARK2" "그 앞 판이 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
    printf '%s\n' "      🔴 **셋째 뒷걸음 표식(TOOLBAR_BTN_PRIMARY)은 여기서 안 셉니다** — 모듈 안의"
    printf '%s\n' "         const 이름이라 minify 가 **이름을 바꿉니다.** 도구 이미지에서 **소스"
    printf '%s\n' "         글자 그대로** 셉니다(62번이 쓰던 자리). 여기서 세면 0 이 나오고 그 ✗ 는"
    printf '%s\n' "         진짜 결함처럼 보입니다."
  else
    # ── 도구 이미지 (소스가 글자 그대로 있다)
    printf '\n    ── %s 안을 센다 (**소스가 글자 그대로** 있다)\n' "$TAG"
    v=$(dock "$TAG" -c "test -f /app/package.json && echo yes || echo no")
    printf '      /app/package.json: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tools 스테이지가 맞다\n'
    else printf '  ✗ /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다\n'; IMGFAIL=1; fi
    v=$(dock "$TAG" -c "test -d /app/node_modules/tsx && echo yes || echo no")
    printf '      /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tsx 가 있다\n'
    else printf '  ✗ tsx 가 없다 — tsx 로 도는 도구가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
    # 🔴 **경로를 상대로 넘기고 /app/ 를 컨테이너 안에서 붙인다** (결함 ②).
    #    그리고 yes/no 가 아니라 **센 줄 수**를 받는다 — 0 과 「못 읽음」을 가른다.
    v=$(dockr run --rm -e M="$TOOLMARK" -e F="$TOOLMARK_FILE" --entrypoint sh "$TAG" -c \
      'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s\n" "$(grep -cF -- "$M" "$p")"; else printf "missing 0\n"; fi' 2>/dev/null | tr -d '\r')
    tst=$(printf '%s' "$v" | awk '{print $1}'); tn=$(printf '%s' "$v" | awk '{print $2}')
    printf '      마지막 커밋 표식 [%s] in %s — 파일 %s · 그 글자 %s줄 (기대 hit · %s)\n' \
      "$TOOLMARK" "$TOOLMARK_FILE" "${tst:-못 읽음}" "${tn:-?}" "$TOOLMARK_LINES_WANT"
    if [ "${tst:-}" = "hit" ] && [ "${tn:-0}" -ge 1 ] 2>/dev/null; then
      printf '  ✓ **마지막 커밋이 담겼다** (%s줄)\n' "$tn"
      printf '%s\n' "      🔵 앱 이미지는 **같은 작업본에서 같은 실행으로** 굽습니다 — 2절이 그"
      printf '%s\n' "         작업본의 HEAD 와 미커밋 0 을 확인했으므로 앱에도 들어 있습니다."
    elif [ "${tst:-}" = "hit" ]; then
      printf '  ✗ 그 파일은 있는데 마지막 커밋의 글자가 **0줄**이다 — 커밋 하나가 빠진 판이다\n'; IMGFAIL=1
    elif [ "${tst:-}" = "missing" ]; then
      printf '  ✗ 그 파일 자체가 이미지에 없다 — src/ 가 온전히 안 담겼다\n'; IMGFAIL=1
      printf '%s\n' "      🔵 **경로 번역부터 의심하세요** — 1-ㄴ 절이 ✓ 였는지 보세요."
    else
      printf '  ✗ 못 읽었다 (받은 값 [%s])\n' "${v:-}"; IMGFAIL=1
    fi
    # 🔴 **셋째 뒷걸음 표식** — 번들에서 못 세는 것을 **여기서 소스 글자로** 센다.
    #    🔵 62번이 이것을 마지막 커밋 표식으로 쓰던 자리다. 내려 왔을 뿐 안 뺐다.
    v=$(dockr run --rm -e M="$TOOLKEEP" -e F="$TOOLKEEP_FILE" --entrypoint sh "$TAG" -c \
      'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s\n" "$(grep -cF -- "$M" "$p")"; else printf "missing 0\n"; fi' 2>/dev/null | tr -d '\r')
    kst=$(printf '%s' "$v" | awk '{print $1}'); kn=$(printf '%s' "$v" | awk '{print $2}')
    printf '      뒷걸음 표식 [%s] in %s — 파일 %s · 그 글자 %s줄 (기대 hit · %s)\n' \
      "$TOOLKEEP" "$TOOLKEEP_FILE" "${kst:-못 읽음}" "${kn:-?}" "$TOOLKEEP_LINES_WANT"
    if [ "${kst:-}" = "hit" ] && [ "${kn:-x}" = "$TOOLKEEP_LINES_WANT" ]; then
      printf '  ✓ **지난 판이 올린 도구 모음이 그대로 있다** (뒷걸음친 나무가 아니다)\n'
    elif [ "${kst:-}" = "hit" ] && [ "${kn:-0}" -ge 1 ] 2>/dev/null; then
      printf '  ⚠️ 그 글자가 %s줄이다 — %s 를 기대했다. 사람이 보세요\n' "$kn" "$TOOLKEEP_LINES_WANT"
    else
      printf '  ✗ 지난 판의 도구 모음이 %s / %s줄이다 — **뒷걸음쳤거나 옛 소스다**\n' "${kst:-못 읽음}" "${kn:-?}"; IMGFAIL=1
    fi
    # 🔴 **이번에 바뀐 열둘이 다 담겼는가** — 도구가 굽는 까닭(ㄴ)의 결과물이다.
    #    🔵 그 목록에 **괄호가 든 경로 둘**이 섞여 있다 — set -f 로 글롭을 끈다.
    ask_files "$TAG" "$INV_CHANGED_FILES" "$INV_CHANGED_FILES_WANT" "이번에 바뀐 파일(tests/ 셋은 뺀 것)"
    # 🔴 **시험 셋은 「없어야」 맞다** — .dockerignore 가 막는다(5-ㄴ). 「12 중 12」가
    #    **왜 15가 아닌지**를 값으로 보이는 자리다. 🔵 있으면 .dockerignore 가 바뀐 것이다.
    v=$(dock "$TAG" -c 'if [ -d /app/tests ]; then printf "yes %s\n" "$(ls -1 /app/tests 2>/dev/null | wc -l)"; else printf "no 0\n"; fi')
    tsd=$(printf '%s' "$v" | awk '{print $1}'); tsn=$(printf '%s' "$v" | awk '{print $2}')
    printf '      /app/tests: %s (파일 %s개 · 기대 no — .dockerignore 가 막는다)\n' "${tsd:-못 읽음}" "${tsn:-?}"
    if [ "${tsd:-}" = "no" ]; then
      printf '  ✓ tests/ 가 이미지에 **안 담겼다** (그래서 바뀐 %s장 중 %s장만 담긴다)\n' "$CH_ALL" "$INV_CHANGED_FILES_WANT"
    else
      printf '  ⚠️ tests/ 가 이미지에 담겼다(%s개) — .dockerignore 가 바뀐 것 같습니다. 사람이 보세요\n' "${tsn:-?}"
      printf '%s\n' "         🔵 ✗ 는 아닙니다(해로운 것이 아닙니다) — 다만 ㄴ 잣대의 기대값이"
      printf '%s\n' "            ${INV_CHANGED_FILES_WANT} 가 아니라 ${CH_ALL} 가 되어야 합니다."
    fi
    # 🔴 **ㄷ 잣대의 실물** — 그 모듈을 import 하는 scripts/ 둘이 이미지 안에도 있는가.
    #    🔵 **이번 판은 그 과녁이 실제로 바뀌었다**(5-ㄹ 의 ㄷ) — 그래서 이 줄이
    #       「scripts/ 가 담겼나」를 넘어 **굽는 까닭 자체**를 확인한다.
    v=$(dockr run --rm --entrypoint sh "$TAG" -c \
      'set -f; n=0; for f in scripts/import-workbook.ts scripts/seed-demo-legacy.ts scripts/migrate.ts; do [ -f "/app/$f" ] && n=$((n+1)); done; printf "n=%s\n" "$n"' 2>/dev/null | tr -d '\r')
    g=$(printf '%s' "$v" | sed -n 's/^n=//p')
    printf '      ㄷ 잣대의 scripts/ 둘 + migrate.ts: %s개 (기대 3)\n' "${g:-?}"
    if [ "${g:-x}" = "3" ]; then printf '  ✓ 그 셋이 이미지에 담겼다 (scripts/ 가 온전히 담겼다)\n'
    else printf '  ✗ 그 셋이 %s/3 개다 — scripts/ 가 온전히 안 담겼다\n' "${g:-?}"; IMGFAIL=1; fi
    # 🔴 **그 둘이 부르는 과녁이 새 몸통인가** — 이번 판에 바뀐 모듈이다.
    v=$(dockr run --rm -e M="SETTING_DRAWING_NO_STYLE" -e F="$TOOL_IMPORT_TARGET" --entrypoint sh "$TAG" -c \
      'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s\n" "$(grep -cF -- "$M" "$p")"; else printf "missing 0\n"; fi' 2>/dev/null | tr -d '\r')
    ist=$(printf '%s' "$v" | awk '{print $1}'); inn=$(printf '%s' "$v" | awk '{print $2}')
    printf '      ㄷ 잣대의 과녁 [SETTING_DRAWING_NO_STYLE] in %s — 파일 %s · %s줄 (기대 hit · 1 이상)\n' \
      "$TOOL_IMPORT_TARGET" "${ist:-못 읽음}" "${inn:-?}"
    if [ "${ist:-}" = "hit" ] && [ "${inn:-0}" -ge 1 ] 2>/dev/null; then
      printf '  ✓ **도구가 부르는 모듈이 새 몸통이다** (옛 몸통으로 돌지 않는다)\n'
    else
      printf '  ✗ 과녁이 %s / %s줄이다 — **옛 소스가 담긴 이미지다.** 올리지 마세요\n' "${ist:-못 읽음}" "${inn:-?}"; IMGFAIL=1
    fi
    # 🔴 **재고는 drizzle 을 담아야 한다** — 🔴 **A/S 와 정반대다.**
    v=$(dock "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
    printf '      /app/drizzle 안 .sql: %s개 (기대 %s — 🔴 **이미지 안에서 돈다**)\n' "${v:-?}" "$INV_SQL_WANT"
    if [ "${v:-x}" = "$INV_SQL_WANT" ]; then printf '  ✓ 재고 마이그레이션 %s장이 이미지에 구워졌다\n' "$INV_SQL_WANT"
    else
      printf '  ✗ .sql 이 %s장이다 — %s 를 기대했다\n' "${v:-?}" "$INV_SQL_WANT"; IMGFAIL=1
      printf '%s\n' "      🔴 **A/S 판을 베껴 0 을 기대하지 마세요** — A/S 는 볼륨이 정본이고"
      printf '%s\n' "         재고는 이미지가 정본입니다. 줄었으면 **운영이 올릴 .sql 을 잃습니다.**"
    fi
    v=$(dock "$TAG" -c "ls /app/drizzle/0027_*.sql 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
    printf '      마지막 번호 0027: %s개 (기대 1)\n' "${v:-?}"
    [ "${v:-x}" = "1" ] && printf '  ✓ 지난 판이 올린 0027 이 이미지 안에 그대로 있다\n' \
      || { printf '  ✗ 0027 이 이미지에 없다 — 옛 판이 담겼다\n'; IMGFAIL=1; }
    v=$(dock "$TAG" -c "ls /app/drizzle/0028_*.sql 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
    printf '      그 다음 번호 0028: %s개 (기대 0 — 이번 판은 **0건**이다)\n' "${v:-?}"
    [ "${v:-x}" = "0" ] && printf '  ✓ 0028 이 없다 (이 배포는 DB 를 한 글자도 안 바꾼다)\n' \
      || { printf '  ✗ 0028 이 이미지에 있다 — 이 배포본은 0027 까지를 전제로 쓰였다\n'; IMGFAIL=1; }
    v=$(dock "$TAG" -c "grep -c 'idx' /app/drizzle/meta/_journal.json 2>/dev/null")
    v=$(printf '%s' "$v" | tr -d ' ')
    printf '      meta/_journal.json 의 idx: %s개 (기대 %s — 0 이면 목록이 안 담긴 것)\n' "${v:-?}" "$INV_SQL_WANT"
    if [ "${v:-x}" = "$INV_SQL_WANT" ]; then printf '  ✓ 목록 파일도 담겼다 (목록에 없는 .sql 은 drizzle 이 모른다)\n'
    else printf '  ✗ idx 가 %s개다 — %s 를 기대했다. **적용이 조용히 어긋난다**\n' "${v:-?}" "$INV_SQL_WANT"; IMGFAIL=1; fi
    # 🔴 **재고 tools 는 vendor 를 안 담는다** — 62번이 포털에 쓰던 잣대 그대로.
    #    🔵 ✗ 가 아니라 ⚠️ 다: 담겨도 해롭지 않고, Dockerfile 이 바뀐 신호일 뿐이다.
    v=$(dock "$TAG" -c "test -d /app/vendor && echo yes || echo no")
    printf '      /app/vendor: %s (기대 no — 재고 tools 는 vendor 를 안 담는다)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "no" ]; then printf '  ✓ 재고 도구에 vendor 가 없다 (Dockerfile 과 같다)\n'
    else printf '  ⚠️ 재고 도구에 vendor 가 있다 — Dockerfile 이 바뀐 것 같습니다. 사람이 보세요\n'; fi
    npm_probe "$TAG" db:migrate
    printf '%s\n' "      🔵 db:migrate 는 **이번 판에 올릴 것이 0건**입니다 — 그래도 이 줄은"
    printf '%s\n' "         「그 명령이 import 까지 가는가」를 재는 자리라 그대로 둡니다."
    printf '%s\n' "      🔴 **/templates 를 보는 절이 없습니다** — 그 볼륨은 **A/S 양식**이고"
    printf '%s\n' "         재고와 아무 상관이 없습니다(A/S 판에서 그대로 베끼면 뜻 없는 ✓ 가 됩니다)."
  fi
}
# ══ 재기 ══════════════════════════════════════════════════════════════
check_all
if [ "$MODE" = "--check" ]; then
  if [ "$FAIL" = "0" ] && [ "$UNK" = "0" ]; then
    printf '\n%s\n' "✅ 전부 ✓ 입니다. 구우려면 --go 로 다시 부르세요."
    exit 0
  fi
  printf '\n%s\n' "🔴 ✗ 나 ? 가 있습니다. 위를 보세요 — 고친 뒤 --go 로 가세요."
  printf '%s\n' "   🔵 **검사 자신을 먼저 의심하세요** — 처음 도는 코드라 기대값이 틀릴 확률이"
  printf '%s\n' "      굽기만큼 높습니다. 기대값의 출처는 이 파일 머리말에 적혀 있습니다."
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════
# ── 🔴 --verify : **이미 구운 둘을 다시 재기만 한다** ────────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **아무것도 굽지 않고 아무 파일도 만들지 않는다.** docker build 도
#      docker save 도 한 줄 없다 — 구운 지문(md5)이 바뀌면 안 되기 때문이다.
if [ "$MODE" = "--verify" ]; then
  printf '\n%s\n' "════════ --verify — 이미 구운 $HOWMANY 을 **다시 잰다** (굽지 않는다) ════════"
  printf '%s\n' "🔴 docker build 도 docker save 도 돌리지 않습니다 — 지문이 바뀌면 안 됩니다."
  VFAIL=0; VSEEN=0; TARTABLE=""; INSIDE_RAN=0
  # 🔴 **함수가 정말 있는가** — 없으면 「command not found」 한 줄만 찍히고
  #    나머지가 통째로 건너뛰어진다(2026-11-18 에 실제로 그렇게 통과했다).
  if ! command -v inside_check >/dev/null 2>&1; then
    printf '  ✗ inside_check 함수가 **없다** — 이 파일의 차례가 깨졌다. 아무것도 안 쟀다\n'
    exit 1
  fi
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    KEY=$(field "$row" 1); TAG=$(field "$row" 2); TGT=$(field "$row" 3)
    VSEEN=$((VSEEN+1))
    printf '\n── %s\n' "$TAG"
    if ! docker image inspect "$TAG" >/dev/null 2>&1; then
      printf '  ✗ %s 가 없다 — 굽지 않았거나 지웠다\n' "$TAG"; VFAIL=$((VFAIL+1)); continue
    fi
    IMGFAIL=0
    inside_check "$KEY" "$TAG" "$TGT"
    if [ "$IMGFAIL" != 0 ]; then
      printf '%s\n' "🔴 $TAG 의 안이 온전하지 않다."
      VFAIL=$((VFAIL+1))
    fi
    # 🔵 tar 가 아직 있으면 지문 줄을 **다시 찍어 준다** — 굽지 않고도 TARS 를 채울 수 있다.
    FILE=$(tar_name "$TAG")
    if [ -f "$OUT/$FILE" ]; then
      sz=$(stat -c %s "$OUT/$FILE" 2>/dev/null || wc -c < "$OUT/$FILE")
      m5=$(md5sum "$OUT/$FILE" | awk '{print $1}')
      cfg=$(tar_config_id "$OUT/$FILE")
      TARTABLE="$TARTABLE$FILE|$sz|$m5|${cfg:-없음}
"
    fi
  done <<ENDVERIFY
$(rows_of "$IMAGES")
ENDVERIFY
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  본 이미지 %s / %s · **안을 실제로 센 횟수 %s** · 안이 온전하지 않은 것 %s\n' \
    "$VSEEN" "$HOWMANY" "$INSIDE_RAN" "$VFAIL"
  if [ "$VSEEN" != "$HOWMANY" ]; then
    printf '  ✗ 이미지를 %s개만 봤다 — %s개를 기대했다. IMAGES 표가 깨졌다\n' "$VSEEN" "$HOWMANY"
    VFAIL=$((VFAIL+1))
  fi
  # 🔴 **표본이 비어서 공짜로 통과하지 않게** 한다.
  if [ "$INSIDE_RAN" != "$HOWMANY" ]; then
    printf '  ✗ 이미지 안을 %s번만 쟀다 — %s번을 기대했다. **아무것도 안 잰 통과다**\n' "$INSIDE_RAN" "$HOWMANY"
    VFAIL=$((VFAIL+1))
  else
    printf '  ✓ 이미지 안을 %s번 다 쟀다 (표본이 비지 않았다)\n' "$INSIDE_RAN"
  fi
  if [ -n "${TARTABLE:-}" ]; then
    printf '\n%s\n' "════════ 69-deploy.sh 의 TARS 에 넣을 줄 (tar 에서 다시 쟀습니다) ════════"
    printf '%s' "$TARTABLE"
  fi
  printf '\n'
  if [ "$FAIL" = "0" ] && [ "$UNK" = "0" ] && [ "$VFAIL" = "0" ]; then
    printf '%s\n' "✅ --verify 전부 통과입니다. **아무것도 안 굽고 안 바꿨습니다.**"
    exit 0
  fi
  printf '%s\n' "🔴 ✗ 가 남아 있습니다 (앞 절 ✗ $FAIL · ? $UNK · 이미지 $VFAIL)"
  printf '%s\n' "   🔵 **검사 자신을 먼저 의심하세요** — 1-ㄴ 절(경로 번역)이 ✓ 였는지 보세요."
  exit 1
fi

if [ "$FAIL" != "0" ] || [ "$UNK" != "0" ]; then
  printf '\n%s\n' "🔴 ✗ 나 ? 가 있어 **굽지 않습니다.** (✗ $FAIL · ? $UNK)"
  printf '%s\n' "   구운 이미지는 그때 그 작업 폴더의 사진입니다 — 어긋난 채로 구우면"
  printf '%s\n' "   나중에 같은 이미지를 다시 못 만듭니다."
  exit 1
fi

mkdir -p "$OUT" || { printf '%s\n' "🔴 $OUT 를 못 만들었다"; exit 1; }

# ══ 굽기 ══════════════════════════════════════════════════════════════
printf '\n%s\n' "════════ 굽는다 ($HOWMANY) ════════"
printf '%s\n' "🔵 **둘입니다.** 오래 걸리지 않습니다."
printf '%s\n' "🔵 재고 dev 서버(3800)와 DB 상자 셋은 **켜 둔 채로 둬도 됩니다** — .dockerignore 가"
printf '%s\n' "   .next 를 막고(5-ㄴ), 이 파일은 호스트의 npm run build 를 한 번도 안 부릅니다."
BUILT=0; BFAIL=0; TARTABLE=""; BUILD_SEEN=0
while IFS= read -r row; do
  [ -n "$row" ] || continue
  KEY=$(field "$row" 1); TAG=$(field "$row" 2); TGT=$(field "$row" 3)
  PREVTAR=$(field "$row" 4); PREVSZ=$(field "$row" 5); STRICT=$(field "$row" 6)
  BUILD_SEEN=$((BUILD_SEEN+1))
  FILE=$(tar_name "$TAG")
  LOG="$OUT/build-$(printf '%s' "$TAG" | tr ':' '-').log"
  printf '\n── %s/%s  %s  (%s)\n' "$BUILD_SEEN" "$HOWMANY" "$TAG" "$INV_REPO"

  # 🔴 도구 이미지만 --target tools 다. 안 주면 **runner 가 구워지고** 그 안에는
  #    scripts/ 도 package.json 도 없어 오류 없이 쓸모없는 이미지가 된다.
  if [ "$TGT" = "-" ]; then
    printf '    스테이지: 기본(runner)\n'
    ( cd "$IVD" && docker build -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG" | tail -3
    RC=${PIPESTATUS[0]}
  else
    printf '    스테이지: --target %s\n' "$TGT"
    ( cd "$IVD" && docker build --target "$TGT" -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG" | tail -3
    RC=${PIPESTATUS[0]}
  fi
  if [ "${RC:-1}" = "0" ]; then
    printf '  ✓ 구웠다\n'
  else
    printf '  ✗ 굽기 실패 — %s 를 보세요\n' "$LOG"; BFAIL=$((BFAIL+1))
    printf '%s\n' "      🔵 **vendor 를 먼저 의심하세요** — vendor/dss-ui 가 비어 있으면"
    printf '%s\n' "         @dss/ui 를 못 찾아 next build 가 죽습니다(3-ㄷ 이 그것을 쟀습니다)."
    printf '%s\n' "         → git -C \"$IVD\" submodule update --init --recursive"
    continue
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

  # ── 🔴 크기 견주기 ① — **지난 판 tar 와** ────────────────────────────
  p=$(pct_diff "$sz" "$PREVSZ")
  if [ -n "${p:-}" ]; then
    printf '    지난 판 %s %s바이트 → 이번 %s바이트 (차이 %s%%)\n' "$PREVTAR" "$PREVSZ" "$sz" "$p"
    if [ "$p" -le 25 ]; then
      printf '  ✓ 지난 판 tar 와 크기가 비슷하다 (차이 %s%% · 25%% 이내)\n' "$p"
    elif [ "$STRICT" = "loose" ] && [ "$p" -le 60 ]; then
      printf '  ⚠️ 지난 판 tar 와 %s%% 다르다 — 이 줄은 loose 라 막지 않습니다\n' "$p"
    else
      printf '  ✗ 지난 판 tar 와 크기가 %s%% 다르다 — %s 에서는 그만큼이면 멈춘다\n' "$p" "$STRICT"
      printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 라이브러리가 늘거나 베이스 이미지가"
      printf '%s\n' "         바뀌면 정상적으로도 이만큼 뜁니다. 🔴 다만 이번 판은 package.json 이"
      printf '%s\n' "         **0줄** 바뀌었습니다(5-ㄷ) — 그래서 strict 로 두었습니다. 까닭을 모르면"
      printf '%s\n' "         **멈추고 알리세요.**"
      printf '%s\n' "      🔵 지난 판 값의 출처는 **62-deploy.sh 의 TARS** 입니다(쉰여덟째)."
      BFAIL=$((BFAIL+1)); continue
    fi
  else
    printf '  ✗ 크기를 못 쟀다 (이번 %s · 지난 판 %s)\n' "${sz:-없음}" "${PREVSZ:-없음}"
    BFAIL=$((BFAIL+1)); continue
  fi

  # ── 🔴 크기 견주기 ② — **그 이미지 자신과** (가지를 둘로 나눈다) ───
  isz=$(docker image inspect "$TAG" --format '{{.Size}}' 2>/dev/null)
  if isnum "${isz:-}" && [ "${isz:-0}" -gt 0 ]; then
    rr=$((sz * 100 / isz))
    printf '    이미지 inspect .Size %s바이트 · tar 는 그 %s%%\n' "$isz" "$rr"
    if [ "$rr" -ge 90 ] && [ "$rr" -le 110 ]; then
      printf '  ✓ tar 가 이미지 내용 크기와 거의 같다 (%s%% — containerd 저장소다)\n' "$rr"
    elif [ "$rr" -ge 10 ] && [ "$rr" -le 45 ]; then
      printf '  ✓ tar 가 이미지의 1/4 쯤이다 (%s%% — 고전 저장소다)\n' "$rr"
    else
      printf '  ✗ tar 가 이미지의 %s%% 다 — 90~110%% 나 10~45%% 를 기대했다\n' "$rr"
      printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 이 비는 docker 의 저장소 방식이 정합니다."
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

  # ══ 🔴 이미지 **안**을 센다 — 겉이 아니라 결과 ═══════════════════════
  inside_check "$KEY" "$TAG" "$TGT"
  if [ "$IMGFAIL" != 0 ]; then
    printf '%s\n' "🔴 $TAG 의 안이 온전하지 않다. 올리지 마세요."
    BFAIL=$((BFAIL+1))
  fi
done <<ENDBUILD
$(rows_of "$IMAGES")
ENDBUILD

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  본 줄 %s / %s · 구운 것 %s / %s · **안을 실제로 센 횟수 %s** · 실패 %s\n' \
  "$BUILD_SEEN" "$HOWMANY" "$BUILT" "$HOWMANY" "$INSIDE_RAN" "$BFAIL"
# 🔴 **표본이 비어서 공짜로 통과하지 않게** 한다 — 고리가 한 바퀴만 돌아도 잡힌다.
if [ "$BUILD_SEEN" != "$HOWMANY" ]; then
  printf '  ✗ IMAGES 표를 %s줄만 돌았다 — %s줄을 기대했다. **고리가 끊겼다**\n' "$BUILD_SEEN" "$HOWMANY"
  BFAIL=$((BFAIL+1))
fi

# ══ 🔴 **✗ 가 나도 지문 줄만은 찍는다** ═══════════════════════════════
#   🔴 쉰세째·쉰네째에 **두 번 연속으로 지문을 못 받았다.** 그래서 **세 자리**에서 찍는다.
if [ "$BFAIL" != "0" ]; then
  printf '\n%s\n' "🔴🔴🔴 **실패가 있지만 지금까지 만든 산출물의 지문은 아래가 전부입니다**"
  printf '%s\n' "       (이름|바이트|md5|Config 지문 — 69-deploy.sh 의 TARS 에 넣을 꼴입니다)"
  if [ -n "${TARTABLE:-}" ]; then printf '%s' "$TARTABLE"
  else printf '%s\n' "       (tar 가 한 줄도 없습니다 — 하나도 안 구워졌다는 뜻입니다.)"; fi
  printf '%s\n' "🔴🔴🔴 **실패를 고친 뒤 다시 구우면 지문이 바뀝니다** — 위 값을 그대로 쓰지"
  printf '%s\n' "       마시고, 다시 구운 뒤의 값을 쓰세요."
  printf '%s\n' "       🔵 **검사 쪽이 틀린 것이면 다시 굽지 말고 --verify 를 쓰세요** —"
  printf '%s\n' "          지문이 바뀌지 않습니다."
  printf '\n%s\n' "🔴 실패가 있다. 위를 보세요."
  exit 1
fi

# 🔴 **굽고 나서 저장소가 더러워졌는가** — next build 가 tsconfig.json 을 다시 접는다.
printf '\n%s\n' "════════ 구운 뒤 저장소가 그대로인가 ════════"
printf '%s\n' "🔴 next build 가 tsconfig.json 을 다시 접은 적이 있습니다(눈에 안 띕니다)."
d=$(git -C "$IVD" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
if [ "${d:-1}" = "0" ]; then printf '  ✓ %s 미커밋 0줄\n' "$INV_NAME"
else
  printf '  ⚠️ %s 에 미커밋이 %s줄 생겼다 — **사람에게 알리세요**\n' "$INV_NAME" "$d"
  git -C "$IVD" status --porcelain=v1 2>/dev/null | head -6 | sed 's/^/        /'
fi
d=$(git -C "$UIDIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
if [ "${d:-1}" = "0" ]; then printf '  ✓ vendor/dss-ui 미커밋 0줄\n'
else printf '  ⚠️ vendor/dss-ui 에 미커밋이 %s줄 생겼다 — 사람에게 알리세요\n' "$d"; fi
printf '%s\n' "  🔵 **tar 는 이미 구워졌습니다** — 되돌릴지 그대로 둘지는 사람이 정하세요."
printf '%s\n' "  🔵 재고에는 **tsconfig.tsbuildinfo** 가 .gitignore 에 있습니다 — 그것은 안 뜹니다."

# ══ 🔴 69-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
printf '\n%s\n' "════════ 69-deploy.sh 에 붙여 넣을 것 (TARS **두 줄**) ════════"
printf '%s' "$TARTABLE"
printf '%s\n' "  🔴 위 **두 줄**로 TARS 를 통째로 갈아 끼웁니다 — 지금은 **이름만 적혀 있고**"
printf '%s\n' "     **지문 자리가 비어 있습니다**(dss-inventory-0.8.tar||| 꼴)."
printf '%s\n' "  🔵 **묶음 값은 없습니다** — 재고는 .sql 을 **이미지에 굽습니다.**"
printf '%s\n' "  🔴 **NAS 에서 재서 채우지 마세요** — 자기가 잰 값으로 자기를 재면 영영 통과합니다."
printf '%s\n' "  🔵 그리고 위 **두 줄의 바이트를 README 에 적어 두세요** — 다음 판이 ①번"
printf '%s\n' "     크기 견주기에 그 값을 씁니다(이번 판은 62-deploy.sh 에서 꺼내 왔습니다)."
printf '\n%s\n' "✅ 둘을 다 구웠습니다. 산출물이 여기 있습니다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'

printf '\n%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **올리는 차례 — tar 둘뿐이다 (묶음 없음)**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  🔴 PowerShell 경로는 **슬래시**로 적습니다. 역슬래시는 bash·scp 가 먹습니다."
printf '%s\n' "  🔴 **Tee-Object 로 로그를 받지 마세요** — PowerShell 이 UTF-16 으로 써서"
printf '%s\n' "     나중에 grep 이 한 줄도 못 찾습니다. NAS 쪽 로그 파일을 보세요."
printf '%s\n' "  🔴 **-O 를 빼지 마세요** — DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' ""
printf '%s\n' "  ① (개발 PC · PowerShell) **스크립트부터 올린다**"
printf '%s\n' "       cd \"C:/Users/희만/Desktop/Development/dss-deploy/nas/setup\""
printf '%s\n' "       scp -O 69-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "       Get-FileHash -Algorithm MD5 69-deploy.sh"
printf '%s\n' "     🔴 **TARS 두 줄을 먼저 채운 뒤에 올리세요.**"
printf '%s\n' ""
printf '%s\n' "  ② (NAS) 지금 상태를 잰다 — 아직 아무것도 안 바뀐다"
printf '%s\n' "       sudo -i"
printf '%s\n' "       bash /volume1/dss/setup/69-deploy.sh            ← --check"
printf '%s\n' "       bash /volume1/dss/setup/69-deploy.sh --count    ← 올리기 전 수"
printf '%s\n' ""
printf '%s\n' "  ③ (개발 PC · PowerShell) **tar 둘을 보낸다 — 한 줄에 하나씩**"
printf '%s\n' "       cd \"$(printf '%s' "$OUT" | sed 's|^/c/|C:/|')\""
SCP_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  SCP_SEEN=$((SCP_SEEN+1))
  printf '%s\n' "       scp -O $(tar_name "$(field "$r" 2)") dss-nas:/volume1/dss/images/"
done <<ENDSCP
$(rows_of "$IMAGES")
ENDSCP
printf '%s\n' "     (보낼 줄 $SCP_SEEN / $HOWMANY)"
printf '%s\n' "     🔴 **묶음(as-migrations.tar.gz)은 보내지 마세요** — 그것은 **A/S 것**이고"
printf '%s\n' "        재고와 아무 상관이 없습니다. 재고의 .sql 은 **도구 tar 안에** 들어 있습니다."
printf '%s\n' ""
printf '%s\n' "  ④ (NAS) **들여놓고 → 다시 재고 → 도구를 갈고 → 앱을 갈아 끼운다**"
printf '%s\n' "       bash /volume1/dss/setup/69-deploy.sh --preload"
printf '%s\n' "       bash /volume1/dss/setup/69-deploy.sh            ← 다시 --check"
printf '%s\n' "       bash /volume1/dss/setup/69-deploy.sh --tools    ← 도구 태그만 (🔵 DB 는 안 바뀐다)"
printf '%s\n' "       bash /volume1/dss/setup/69-deploy.sh --go       ⏱ 정지 창 (앱 **하나**)"
printf '%s\n' "       bash /volume1/dss/setup/69-deploy.sh --count    ← 올린 뒤 수"
printf '%s\n' "     🔴 **--migrate 모드는 없습니다** — 이번 판은 마이그레이션이 0건입니다."
printf '%s\n' "        그 자리에 **--tools** 가 들어갔습니다: 도구 태그를 갈고, 새 도구로"
printf '%s\n' "        db:migrate 를 **--dry 없이 돌리지 않고** 이미지 안을 세어 확인하고,"
printf '%s\n' "        DB 수가 **132·28·5·11·3 그대로인지**를 잽니다."
printf '%s\n' ""
printf '%s\n' "🔴 **배포 뒤에 눈으로 볼 곳 — 69-deploy.sh --go 의 꼬리말에 일곱 가지가 있습니다.**"
printf '%s\n' "   🔵 가장 먼저 볼 것: [설정] → **[도번 표시]** 가 메뉴에 서는가(항목 관리 바로 뒤)."
printf '%s\n' ""
printf '%s\n' "🔴 **되돌리기**: --rollback 은 앱 하나를 옛 태그로 되돌립니다."
printf '%s\n' "   🔵 도구는 새 판 그대로 둡니다(39·41~68번과 같은 판단)."
printf '%s\n' "   🔵 **DB 는 되돌릴 것이 없습니다** — 이번 판은 한 글자도 안 바꿉니다."
printf '%s\n' "   🔴 **되돌리면 도번 줄이 사라지고 [도번 표시] 메뉴도 없어집니다** — 둘 다"
printf '%s\n' "      **코드에만** 있습니다. 🔵 사람이 저장해 둔 모양(app_settings 의 한 줄)은"
printf '%s\n' "      **DB 에 남습니다** — 다시 올리면 그대로 돌아옵니다."
printf '%s\n' "────────────────────────────────────────────────────────────"
printf '\n%s\n' "🔴🔴🔴 **69-deploy.sh 에 넣을 값 (다시 찍습니다 — 여기만 복사해도 됩니다)**"
printf '%s\n' "── TARS 두 줄"
printf '%s' "$TARTABLE"
printf '%s\n' "🔴🔴🔴 위를 69-deploy.sh 에 **그대로** 적은 뒤 scp 하세요."
