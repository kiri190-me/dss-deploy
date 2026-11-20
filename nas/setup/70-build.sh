#!/bin/bash
# dss-deploy/nas/setup/70-build.sh — 예순여섯째 배포 · 이미지 굽기 (2026-11-20)
#
# 🔵 **배포 회차(예순여섯째)와 파일 번호(70)가 어긋나는 것은 이 저장소에서 원래
#    그렇다** — 63번이 쉰아홉째, 64번이 예순째, 65번이 예순한째, 66번이
#    예순두째, 67번이 예순세째, 68번이 예순네째, 69번이 예순다섯째였다.
#    (56번은 2026-11-11 의 **양식 전용**이라 회차를 안 먹었다.)
#
# ══════════════════════════════════════════════════════════════════════
# 🔴🔴 **이 파일은 68-build.sh 를 복사해 값만 고친 것이다** (2026-11-19 결정)
# ══════════════════════════════════════════════════════════════════════
#   🔴 **68번(예순네째)을 베꼈다.** 까닭은 **모양이 68번과 같기** 때문이다:
#      집 하나(**A/S**) · 도구 하나 · 마이그레이션 **0건** · 묶음 **없음** ·
#      서브모듈 **안 움직임**.
#   🔴 **직전 판(69번)에서 베끼면 틀린다.** 69번은 **재고관리**였다 —
#      저장소가 다르고(dss-inventory) · 시험 등록이 **글롭 방식**이며 ·
#      마이그레이션이 **이미지 안에** 들어가는 집이다. A/S 는 **셋 다 반대**다:
#        · 시험 등록은 **목록 파일**(scripts/test-lists/*.txt) — 적어야 돈다.
#        · .sql 은 **볼륨**(/volume1/dss/as-migrations)에 살고 **도구 이미지 안은
#          0장이어야 ✓** 다. 🔴 69번은 정반대 기대값을 들고 있다. 베끼지 마라.
#   🔴 **그래도 69번의 좋은 절 둘은 가져왔다**(68번에 없고 69번이 더한 것):
#      ㉠ **5-ㅁ 의 덮기 관문** — 폴더별 셈의 합이 전체와 맞는가.
#         🔵 69번은 src + tests == 전체 였다. **A/S 에는 tests/ 폴더가 없다**
#            (시험이 src/ 안에 산다) — 그래서 이 판은
#            src + scripts + drizzle + vendor == 전체 로 적었고,
#            이번 값으로는 **src 만으로 전체를 덮는다**(3 = 3).
#      ㉡ **5-ㅂ-2 의 mark_net()** — **번들에 쓰는 글자를 전부** 「주석을 걷은 뒤」로
#         거른다. 🔴 68번은 **기능 표식 하나만** 걸렀다. 이 판은 **열 글자**를 다
#         거른다(기능 1 + 곁들이 1 + 뒷걸음 8).
#         🔵 그 절이 없었으면 domesticOrders.completedEdit 이 날것 11파일인데
#            **주석을 걷으면 7파일**이라는 것을 아무도 몰랐을 것이다[실측].
#
#   🔴 **이 파일에 「왜 없는가」를 적어 두는 절 셋** (68·67·65·64·63 이 그렇게 했다 —
#      그 글이 없으면 다음 판이 「원래 없는 절」로 읽는다):
#      · **묶음을 만드는 절이 없다**(66번의 「셋째 산출물」). 까닭: 이번 범위의
#        drizzle/ 변경이 **0줄**이라 볼륨에 더할 .sql 이 없다 — 4절이 값으로 잰다.
#        🔴 마이그레이션이 생기는 판에서는 **66번에서 그 절을 통째로 되살려라.**
#      · **지우는 문장 잣대와 그 표본 여섯이 없다**(66번 4-ㄱ). 까닭: 잴 .sql 이
#        이번 범위에 없다. 🔴 .sql 이 한 장이라도 생기면 **먼저 그 절부터** 넣어라.
#      · **공용 스키마에 더한 칸을 보는 절이 없다**(66번 3-ㄹ). 까닭: 서브모듈이
#        안 움직인다(3-ㄴ 이 0줄로 잰다). 🔵 **다만 지난 판들이 더한 칸 넷은 도구
#        이미지 안에서 그대로 본다**(inside_check) — 뒷걸음을 막는 자리다.
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · PowerShell 에서 Git Bash 를 부른다) ──────────
#     cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#     & "C:\Program Files\Git\bin\bash.exe" ./70-build.sh --check
#     & "C:\Program Files\Git\bin\bash.exe" ./70-build.sh --go
#
#   🔴 **bash.exe 만 치면 WSL 이 잡힌다**(2026-11-04 에 걸렸다). WSL 에서 돌면
#      도커가 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 내어 ✗ 가 흩어져
#      난다. 단서는 로그의 뿌리 경로가 **/mnt/c/…** 인 것이다 — 0절이 값으로 잰다.
#   🔴 **스크립트에 건네는 경로에는 역슬래시를 쓰지 않는다.** 역슬래시를 주면
#      bash 가 그것을 먹어 "C:Users희만Desktop…" 이 되어 No such file 이 난다.
#
#   둘째 인자로 산출물을 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-66):
#     & "C:\Program Files\Git\bin\bash.exe" ./70-build.sh --go "/d/배포본/_images-66"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다.
#      이 파일을 쓴 쪽은 **한 번도 굽지 않았다** — 재기만 했다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 올리는 것 — 한 줄 요약**
# ══════════════════════════════════════════════════════════════════════
#   [부품요청] **재고의 「비고」로도 부품을 찾는다.**
#   ① 🔵 찾는 칸이 보던 칸이 **다섯에서 여섯**으로 는다 —
#      품명 · 품명2 · 고객사 품명 · 교산 품번 · 도번 **+ 비고**.
#      안내 문구도 그만큼 길어진다(끝에 **「/ 비고」**가 붙는다).
#   ② 🔴 **전에 되던 것은 그대로 된다.** 더하기만 했다 — 다섯 칸 중 어느 것으로도
#      여전히 찾아진다(낱말이 **모두** 들어 있는 줄을 뽑는 규칙도 그대로다).
#   ③ 🔵 **화면은 비고의 첫 줄만 그리지만 검색은 적힌 전부를 본다.** 비고는
#      줄바꿈이 든 글자라 둘째 줄의 낱말로도 찾아진다 — 눈 확인에 그 자리가 있다.
#   ④ 🔴 **저쪽(재고관리)의 서버 검색은 아직 다섯 칸이다**[실측 — dss-inventory 의
#      lib/api/parts.ts 의 matchesQuery 가 name·name2·customerName·kyosanPartNo·
#      drawingNo 다섯만 본다]. 🔴 그래서 **「언젠가 q 를 서버에 넘기면 된다」가
#      이제 거짓**이고, 그 말이 소스 주석에 그대로 적혀 있다. 서버로 옮기려면
#      **저쪽 q 에 비고를 먼저 넣어야** 한다.
#   ⑤ 🔵 **견적서와 [사용 부품] 고르개는 그대로 다섯 칸**이다(2026-11-20 결정 —
#      [부품요청] 한 곳만 넓힌다). 그쪽 거르개는 vendor/dss-core 의
#      filterPartOptions 가 쥐고 있고 **이번 범위는 vendor/ 를 0줄 건드렸다**(3-ㄴ).
#   🔵 **DB 는 한 글자도 안 건드린다** — 마이그레이션 **0건**. 🔴 까닭: 이 기능은
#      **읽는 쪽**이고, 부품은 애초에 **재고관리의 자료**다(A/S 는 API 로 받아 온다).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **68번의 전제 중 이번에 깨지는 것 여덟 — 하나씩 재서 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 **바뀐 파일이 3장이다**(68번은 8장). [실측 2026-11-20 · 기준 40d01c0a]
#      src/ **3** · scripts/ **0** · drizzle/ **0** · vendor+.gitmodules **0** ·
#      새 파일 **0** · 지운 파일 **0** · 괄호 **0** · 대괄호 **0**.
#      🔵 셋은 이렇다:
#        src/components/repair-cases/detail/PartRequestSection.tsx
#        src/lib/domain/inventory-gateway.test.ts
#        src/lib/domain/inventory-gateway.ts
#      🔴 **괄호도 대괄호도 0장이다**(68번은 둘 다 1장). 🔴 **그래도 그 셈을 빼지
#         않는다** — 66번이 더했고 67번이 0 이었는데 안 빼서 68번의 [id] 를 잡았다.
#      🔴 **시험 파일이 src/ 안에 있다**(A/S 는 그렇다). 그래서 도구 이미지가
#         담는 것 중 바뀐 파일이 **3 중 3** 이다 — 빠지는 것이 하나도 없다.
#
#   ② 🔴 **새 시험이 0장이다**(68번은 1장). 그래서 5-ㅇ 의 뜻을 **64·65번 꼴로
#      뒤집는다**: 「새 시험 N개가 등록돼 있다」가 아니라 **「목록 줄 수가 안
#      줄었다」 + 「바뀐 시험이 아직 적혀 있다」**.
#      [실측] 목록 줄 수 **4200 → 4200**(안 늘고 안 줄었다). 바뀐 시험은 **1장**:
#        src/lib/domain/inventory-gateway.test.ts   ← scripts/test-lists/unit.txt 1406줄
#      🔴 **68번의 「넷」을 그대로 두면 「본 것 1 · 기대 4」로 ✗** 가 나고, 그 ✗ 는
#         **등록이 빠진 것처럼** 보인다.
#
#   ③ 🔴 **굽는 까닭 ㄷ(도구의 import 닫힘)은 이번에도 안 걸린다 — 잣대만 재 둔다.**
#      [실측 2026-11-20] scripts/lib/ 의 **두 파일**이 아직 그 모듈을 import 한다:
#        scripts/lib/delivered-date-sync-survey.ts:1
#        scripts/lib/requested-due-date-sync-survey.ts:1
#          import { foldBlankToNull } from "../../src/lib/domain/domestic-order-list";
#      🔴 그 **과녁(src/lib/domain/domestic-order-list.ts)이 이번 범위에 0줄**이다
#         — 67·68번과 같다(**세 판 연속**으로 안 걸린다).
#      🔴 **그래도 절을 빼지 않는다**(66·67·68번이 같은 판단을 했다).
#      🔴 **굽는 까닭은 ㄴ 하나다** — tools 가 담는 것 중 바뀐 파일 **3 중 3**.
#
#   ④ 🔴🔴🔴 **이번 판에만 있는 함정 — 기능 표식이 한글이다.**
#      지금까지의 앱 표식은 전부 영문·숫자였다(hasLiveApproval · radiogroup ·
#      "ORDER_ISSUED" …). 🔴 **이번 커밋이 번들에 남기는 글자는 한글 문자열
#      하나뿐**이다 — 바뀐 셋 중 번들에 들어가는 것은 PartRequestSection.tsx 이고,
#      그 파일의 **달라진 줄이 placeholder 한 줄**이기 때문이다[실측 · diff 전문]:
#          - placeholder="재고 관리에서 찾기: 품명 / 품명2 / 고객사 품명 / 교산 품번 / 도번"
#          + placeholder="재고 관리에서 찾기: 품명 / 품명2 / 고객사 품명 / 교산 품번 / 도번 / 비고"
#      🔵 **문자열 리터럴이고 주석이 아니다.** minify 는 문자열 **내용**을 안 바꾼다.
#      🔴 inventory-gateway.ts 쪽에서 바뀐 코드는 part.note 하나인데, part 는
#         **지역 이름이라 minify 가 갈아 치운다** — 번들 표식으로 못 쓴다.
#
#      🔴 **그래서 「0 이 나왔을 때 그것이 결함인지 검사 탓인지」를 가르는 길이
#         없다.** 컨테이너 안으로 한글을 넘기는 길이 어디서든 깨지면(인코딩 ·
#         로케일 · 인자 전달) **멀쩡한 이미지가 ✗** 가 되고 그 ✗ 는 진짜 결함처럼
#         보인다. 이 저장소에는 그 꼴의 사고가 여럿 적혀 있다 — 한글을 HTTP
#         머리말에 넣어 요청이 통째로 안 나간 적 · Git Bash 의 경로 번역으로
#         검사 일곱이 가짜 ✗ 가 된 적.
#
#      🔵 **처방 셋을 함께 깐다:**
#        ㄱ) **1-ㄷ 절 — 한글이 컨테이너 경계를 글자 그대로 건너가는가.**
#            1-ㄴ(경로 번역)과 같은 길이다: 보내고 **되돌려 받아** 바이트까지 맞댄다.
#            [실측 2026-11-20 · dss-as:6.0 에 넣어 봤다]
#              보낸 값 [도번 / 비고] 15바이트 → 받은 값 [도번 / 비고] 15바이트 ✓
#              보낸 값 [재고 관리에서 찾기] 26바이트 → 받은 값 26바이트 ✓
#        ㄴ) **곁들이 표식** — 같은 placeholder 의 **앞부분**이다:
#              APPMARK_SIDE = 재고 관리에서 찾기      기준 1파일 → 지금 1파일
#            [실측 · 옛 판 dss-as:6.0 의 번들에서] server **1** · static **1**.
#            🔴 **이 수가 이 설계의 핵심 증거다** — 한글이 번들에서 **실제로
#               걸린다**는 것을 옛 이미지로 확인해 두었다.
#        ㄷ) **ASCII 대조** — 같은 실행에서 ASCII 글자 하나를 함께 센다.
#            [실측 · 옛 판에서] hasLiveApproval server **2** · static **1**.
#      🔴 **가름을 로그 글자로 적어 둔다**(bundle_mark_ko 의 네 가지):
#        · 기능 ≥1                       → ✓
#        · 기능 0 · 곁들이 ≥1            → 🔴 **진짜 결함**(옛 이미지를 구웠다)
#        · 기능 0 · 곁들이 0 · ASCII ≥1  → 🔴 **한글 grep 이 안 되는 것**(검사 탓)
#        · 셋 다 0                       → 🔴 **번들을 아예 못 읽었다**(.next·경로)
#      🔴 적어 두지 않으면 한밤중에 ✗ 를 본 사람이 **멀쩡한 이미지를 되돌린다.**
#
#      🔵 **도구 쪽은 덜 위험하다** — 소스가 글자 그대로 들어 있다. 🔴 그래도 같은
#         꼴의 곁들이를 뒀다. 도구 표식은 **둘**이고 하나는 ASCII 다:
#           TOOLMARK       = 여섯 칸                      (한글 · 주석 줄)
#           TOOLMARK_ASCII = part.drawingNo, part.note    (ASCII · **코드 줄**)
#         둘 다 과녁 src/lib/domain/inventory-gateway.ts 안에서 **기준 0줄 → 지금 1줄**
#         이다[실측]. [옛 판 dss-as-tools:27 안에서 실측] ko=0 · ascii=0 — **둘 다
#         옛 판을 가른다.**
#         🔴 part.note 를 **홀로 쓰지 않은 까닭**: 그 글자는 기준판에도 **1줄**
#            있었다(332줄 — 비고 첫 줄을 그리는 자리). 그래서 쉼표까지 붙여
#            part.drawingNo, part.note 로 잡아야 0 → 1 이 된다.
#
#   ⑤ 🔴 **뒷걸음 표식이 일곱에서 여덟로 는다.** 68번이 기능 표식으로 쓴
#      hasLiveApproval 은 **예순네째가 어제 올린 글자**라 오늘은 「있다」가
#      **아무것도 안 가른다**(기준 4 → 지금 4)[실측]. **뒷걸음으로 내렸다.**
#      🔵 faultTags · radiogroup · domesticOrders.completedEdit 이 앞서 그랬던 것과
#         같은 내림이다. 🔴 **하나도 빼지 마라** — 뺀 자리는 다시 넣는 사람이 없다
#         (65번 넷 → 66번 다섯 → 67번 여섯 → 68번 일곱 → **여덟**).
#
#   ⑥ 🔴🔴 **68번의 AS_NEXT_MIG 이 한 칸 빗나가 있었다 — 고쳤다.**
#      [실측 2026-11-20] drizzle/ 의 .sql 은 **132장**이고 번호는 **0000~0131** 이다
#      (meta/_journal.json 의 마지막 idx 도 **131**). 그러면 **다음 번호는 0132** 다.
#      🔴 그런데 67·68번은 AS_NEXT_MIG=0133 을 들고 「마지막이 0132 그대로」라고
#         적고 있었다. 66번이 0131 을 만들면서 올려 둔 0132 를 67번이 **한 번 더**
#         올린 것이다(66번은 0132 로 맞았다).
#      🔴 그 탓에 **두 판 연속으로 이 검사가 아무것도 안 막았다** — 누가 0132 를
#         새로 뽑아도 「0133 이 없다」로 조용히 ✓ 였다. **0132 로 되돌렸다.**
#      🔵 70-deploy.sh 의 AS_VOL_NEXT 도 같이 0132 로 고쳤다(짝이다).
#
#   ⑦ 🔴 **tar 크기 견주기 기준값이 바뀐다 — 둘 다 strict.**
#      지난 판: dss-as-6.0.tar **136190464** · dss-as-tools-27.tar **226645504**
#      [실측] 이번 범위의 package.json · package-lock.json · tsconfig.json ·
#      drizzle.config.ts 변경이 **0장**이다 — 라이브러리가 한 개도 안 늘었다.
#      그래서 **둘 다 strict**(25% 넘으면 ✗)로 둔다.
#
#   ⑧ 🔴 **판 번호 — dss-as:6.0 → 6.1 · dss-as-tools:27 → 28.**
#      tar 이름(dss-as-6.1.tar) · 태그 · 70-deploy.sh 의 tar2tag · 크기 견주기의
#      지난 판 이름이 **전부 6.1 로** 바뀌어야 한다. 🔴 한 자리만 6.0 으로 남으면
#      --preload 가 「tar 안의 태그가 다르다」로 멈추거나, 더 나쁘게는 **옛 판을
#      실어 놓고 성공으로 보인다.**
#      🔵 **「안 걸린다」도 값으로 잰다** — npm 명령 수 **39 → 39**[실측].
#         63~69번이 그렇게 했고, 그 규율이 없으면 다음 판이 「안 늘었다」는
#         **거짓**을 근거로 「안 구워도 된다」를 꺼낸다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **68번에서 와서 한 줄도 안 뺀 것**
# ══════════════════════════════════════════════════════════════════════
#   · 0절 Git Bash 판정(/mnt/ 로 시작하면 ✗)        → 참. 그대로.
#   · 🔴 **1-ㄴ 경로 번역 검사**(MSYS_NO_PATHCONV)   → 참. **맨 앞에 둔다.**
#     이것이 없어서 쉰여덟째에 **가짜 ✗ 일곱**을 헤맸다.
#   · 2절 「미푸시 0 과 **안 받은 것도 센다**」 → 참. [실측] main == origin/main ·
#     기준 40d01c0a..main 커밋 **1** · 미커밋 0줄.
#   · 「굽기 전에 서브모듈 작업본이 체크아웃돼 있는가」 → 🔴 **참이고 이번에도
#     중요하다.** 핀이 안 움직이니 **핀만 보면 빈 서브모듈도 통과한다**(3-ㄷ).
#   · 4절 「마이그레이션 0건 — 바뀌지 않아야 한다」 → 참. 🔵 66번이 1건이었으니
#     **67·68·이번 판으로 세 판 연속** 0건이다.
#   · tar 크기를 **두 번** 견주기(지난 판 tar 와 · 그 이미지 자신과) → 참.
#   · 「grep -c 는 0 일 때 종료 코드 1」·「tar | grep -q 는 SIGPIPE」·
#     「bash -n 이 못 잡는 둘」·「8진수로 읽히는 0132」 → 전부 참. 같은 규율로 썼다.
#   · 함수 정의에 붙인 **</dev/null** · 고리마다 **「몇 개를 봤는가」 관문** → 참.
#   · 「✗ 가 나도 지문 줄만은 찍는다」 → 참. **세 자리**에서 찍는다.
#   · 「docker build 는 dev 서버를 안 내려도 된다(.dockerignore 가 .next 를 막는다)」
#     → 참. [실측] .dockerignore 의 ^\.next 가 **1줄**. 🔵 **3000번과 5442번이
#     떠 있는 것이 정상이다** — 7-ㄴ 이 값으로 찍기만 하고 판정에 안 쓴다.
#   · 5-ㅂ-2(주석 걷기) · 5-ㅅ 의 「과녁 파일이 기준판에도 있었나」 · 5-ㅁ 의
#     대괄호 셈 · 도구 이미지 안 공용 스키마 **넷** → 전부 참.
#
# ── 🔴 **--verify 모드** — 63번이 만든 것을 그대로 가져왔다 ───────────
#   이미 구운 둘을 **다시 굽지 않고 안만 잰다.** 가짜 ✗ 를 고칠 때 **구운 지문이
#   바뀌면 안 되기** 때문에 필요하다 — 다시 구우면 받아 둔 TARS 값이 못 쓰게 된다.
#
# ── 이번에 굽는 것 — **이미지 둘** ───────────────────────────────────
#     ① A/S 앱   dss-as:6.0       → dss-as:6.1         커밋 1
#     ② A/S 도구 dss-as-tools:27  → dss-as-tools:28    🔴 --target tools
#   🔴 **묶음은 없다**(마이그레이션 0건 — 4절이 값으로 잰다).
#   🔴 **나머지 아홉 집은 안 굽는다** — 이번 범위에 한 줄도 없다.
#      🔵 재고관리(dss-inventory)는 **예순다섯째가 어제 올린 그대로**다. 이번 기능이
#         재고의 자료를 읽지만 **저쪽 코드는 한 줄도 안 바뀌었다**(찾는 일을
#         A/S 가 제 쪽에서 한다 — 머리말 ④).
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
#   ① **지난 판 tar 와** 견준다(둘 다 값이 있다 — 아래 IMAGES 표 주석).
#   ② **그 이미지 자신과** 견준다. 가지가 둘이다:
#      · containerd 저장소면 inspect .Size 가 **압축된 내용 크기**라 90~110%.
#      · 고전 저장소면 **펼친 크기**라 tar 는 그 **1/4쯤**(10~45%).
#   🔴 **tar 지문은 'docker image inspect' 의 .Id 와 맞대지 않는다.** 그것은 애초에
#      다른 값이다. 맞댈 상대는 **빌드 로그의 'exporting config sha256:'** 이다.
#
# ── 🔴 이 환경의 함정 (36~68-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싼다. 저장소 자리를 적어
#      넣지 않고 **이 파일의 자리에서 계산한다**(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:/… 를 /c/… 로 바꾸고,
#      docker save 는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를 막는다).
#   ④ 🔴🔴 **이미지 안을 재는 명령에 한글이 들어간다 — 이 판이 처음이다.**
#      36~69번은 「표식은 전부 ASCII」를 규칙으로 지켰다. 🔴 **이번 판은 지킬 수가
#      없다**(머리말 ④). 그래서 **대신 1-ㄷ 절과 곁들이·ASCII 대조를 깔았다.**
#      🔴 8진 이스케이프로 우회하지 않았다 — 백슬래시 한 겹이 조용히 삼켜지는
#         함정이 이 PC 에 적혀 있어 **그 길이 더 위험**하다. 되돌려 받아 맞대는
#         길이 1-ㄴ 에서 이미 검증된 길이다.
#   ⑤ 🔵 **이번 범위에는 괄호도 대괄호도 0장이다**[실측]. 🔴 **그래도 목록을
#      넘기는 길은 here 문서 + grep -Fx 로만 썼고, 컨테이너 안에서도 set -f 로
#      글롭을 끈다.** 68번이 [id] 한 장을 그 길로 받아 냈다 — 「이번엔 괜찮다」로
#      길을 바꾸면 다음 판이 그 함정을 밟는다.
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
#   ⑩ 🔴 **bash 의 $(( )) 는 0 으로 시작하는 수를 8진수로 읽는다** — 0132 를 셈에
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
# 🔴 **Git Bash 가 /app/… 을 C:/Program Files/Git/app/… 으로 바꾼다**
# ══════════════════════════════════════════════════════════════════════
#   docker.exe 는 **윈도우 프로그램**이라 MSYS 런타임이 인자를 넘기기 전에
#   「유닉스 절대경로처럼 생긴 것」을 윈도우 경로로 **조용히 번역한다.** 값에
#   빈칸이 없고 / 로 시작하면 걸린다:
#
#       docker run -e F="/app/src/x.ts" …  →  컨테이너 안에서 $F 가
#       C:/Program Files/Git/app/src/x.ts  가 되어 [ -f "$F" ] 가 거짓이 된다
#
#   🔴 **전역 export 로 끄지 않는다** — git 이 깨진다(✗ 스물한 개를 실제로 봤다).
#      docker 를 부르는 자리에만 붙인다. 같은 셸에서 git 은 그대로다.
dockr() { MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker "$@" </dev/null; }
# 🔵 </dev/null 은 「고리 안의 docker exec 가 here 문서를 먹는다」의 처방이다.
#    docker run 은 -i 가 없으면 stdin 을 안 읽지만, 나중에 누가 -i 를 되살려도
#    **고리가 살아남게** 함수 정의에 붙여 둔다.

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
# ── 저장소 **하나** ───────────────────────────────────────────────────
#   🔴 기준 SHA 의 출처: 예순네째(68번)가 올린 커밋이다.
#      [실측 2026-11-20] 그 SHA 에서 세어 커밋 **1** 이었다.
AS_REPO=RF_Service_System
AS_NAME=A/S관리
AS_BASE=40d01c0a
AS_COMMITS_WANT=1
AS_PORT=3000
# 🔵 DB 는 dss-pg-app(호스트 5442)이 개발 PC 에 떠 있다. 🔴 **끄지 않는다** —
#    이 파일은 DB 에 한 번도 안 붙는다(개발 PC 에서는 운영 DB 를 못 본다).
AS_DB_PORT=5442

# ── 굽는 **둘** ───────────────────────────────────────────────────────
#   열쇠|새 태그|타깃(-=기본 runner)|지난판 tar 이름|지난판 tar 바이트|엄함
#   🔴 지난판 바이트의 출처 — **68-deploy.sh 의 TARS 에 박힌 값 그대로다**:
#      dss-as-6.0.tar        136190464
#      dss-as-tools-27.tar   226645504
#   🔵 엄함: strict = 25% 넘으면 ✗ · loose = 25% ⚠️ · 60% 넘으면 ✗
#   🔴 **둘 다 strict 다** — [실측] 의존성 파일이 **한 장도 안 바뀌었다**(머리말 ⑦).
IMAGES='
as|dss-as:6.1|-|dss-as-6.0.tar|136190464|strict
astools|dss-as-tools:28|tools|dss-as-tools-27.tar|226645504|strict
'
HOWMANY=2

# ── 🔴 마이그레이션 — **0건이다** ────────────────────────────────────
#   🔵 66번이 1건이었고 67·68·이번 판이 0건이라 **세 판 연속**이다.
#   저장소가 들고 있어야 하는 수 · 목록 수 · 이번 범위의 drizzle 변경 · 그 다음 번호
AS_SQL_WANT=132
AS_DRIZZLE_DIFF_WANT=0
# 🔴🔴 **0133 이 아니라 0132 다**(머리말 ⑥). [실측 2026-11-20]
#    drizzle/ 의 .sql 132장은 **0000~0131** 이고 journal 의 마지막 idx 도 **131** 이다.
#    67·68번은 0133 을 보고 있었다 — **두 판 연속 아무것도 안 막았다.**
AS_NEXT_MIG=0132
AS_LAST_MIG=0131
# 🔵 **운영이 지금 들고 있어야 하는 수** — 개발 PC 에서는 못 잰다. 70-deploy.sh 가
#    DB 에 물어 확인하고, **바뀌었으면 거기서 멈춘다.** 여기서는 찍어 두기만 한다.
PROD_MIGS_NOTE='A/S 132 · 재고 28 · 휴가 5 · 포털 11 · 계측기 3'

# ══ 🔴 서브모듈 — **안 움직인다** ═════════════════════════════════════
#   🔵 dss-core 는 66번이 b79e5ab8 → 1e9ec85 로 올렸다. **이번 판도 그 자리다.**
#   🔵 dss-ui 는 이것으로 **열다섯 판 연속** 안 움직인다.
AS_CORE_PIN=1e9ec85535a2718901879639dd4dd3557d8af357
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425
AS_CORE_COMMITS_WANT=0
# 🔴 **핀만 보면 빈 서브모듈도 통과한다** — 쉰여덟째가 올린 것이 거기 있는지 함께 본다.
AS_CORE_KEEP_FILE=src/schema/portal-approval-delegations.ts
AS_CORE_KEEP_TABLE=portal_approval_delegations
AS_CORE_KEEP_EXPORT=portal-approval-delegations

# ══ 🔴 바뀐 파일 수 — [실측 2026-11-20] ═══════════════════════════════
#   전체|src/|scripts/|drizzle/|vendor+.gitmodules|새 파일|지운 파일|괄호|대괄호
#   🔴 **68번과 같은 자리가 거의 없다**(머리말 ①). 68번은 전체가 **8**(src 7 ·
#      scripts 1)이었다 — 이번엔 **3** 이고 **전부 src/** 다.
CH_ALL=3
CH_SRC=3
CH_SCRIPTS=0
CH_DRIZZLE=0
CH_VENDOR=0
CH_NEW=0
CH_DEL=0
CH_PAREN=0
# 🔴 **대괄호 셈은 66번이 더한 것이다.** 67번은 0 · 68번은 1 이었고 이번 판은
#    다시 **0** 이다. 🔴 그래도 안 뺀다 — 68번이 그 셈으로 [id] 한 장을 잡았다.
CH_BRACKET=0
#   🔵 바뀐 3장 중 **하나가 시험 파일**이다 — 5-ㅇ 의 표본이 거기서 나온다.
#      🔴 68번은 **넷**이었다(머리말 ②).
CH_TESTS=1

# ══ 🔴 npm 명령 수 — [실측 2026-11-20] ════════════════════════════════
NPM_WAS=39
NPM_NOW=39

# ══ 🔴 **도구를 굽는 까닭** — 값으로 가린다(머리말 ③) ═════════════════
#   ㄴ) tools 스테이지가 담는 것 중 바뀐 파일 수. 🔴 **3 중 3**(68번은 8 중 8).
#      🔵 빠지는 것이 **하나도 없다** — drizzle/ 과 vendor/ 가 0장이고
#         **시험 파일도 src/ 안에 있기** 때문이다(A/S 는 그렇다).
TOOLS_PAYLOAD_RE='^(src/|scripts/|vendor/|package\.json|tsconfig\.json|drizzle\.config\.ts)'
TOOLS_PAYLOAD_WANT=3
#   ㄷ) 🔴 **도구의 import 닫힘** — scripts/ 가 그 모듈을 import 로 부르는 자리.
#      파일|그 파일이 import 하는 모듈
TOOL_IMPORTERS='
scripts/lib/delivered-date-sync-survey.ts|../../src/lib/domain/domestic-order-list
scripts/lib/requested-due-date-sync-survey.ts|../../src/lib/domain/domestic-order-list
'
TOOL_IMPORTERS_WANT=2
TOOL_IMPORT_TARGET=src/lib/domain/domestic-order-list.ts
# 🔴 **이번 범위에도 그 과녁이 0줄이다** — 65번은 1 이었다(그래서 걸렸다).
#    67·68·이번 판이 0 이라 **세 판 연속**으로 안 걸린다.
TOOL_IMPORT_TARGET_WANT=0

# ══ 🔴 Dockerfile 이 담는 길 — **A/S 넷** ═════════════════════════════
#   정규식|있어야 하나(yes/no)|사람이 읽을 말
#   🔴 **no 줄이 뜻하는 것이 반대다.** A/S 의 「drizzle 을 안 담는다」는 **볼륨이
#      정본**이라는 뜻이다 — 이번 판은 거기에 더할 것이 없다(0건).
#   🔴 **69번(재고)은 정반대였다** — 거기는 마이그레이션이 이미지 안에 들어간다.
COPYRULES='
^COPY .*scripts \./scripts|yes|🔴 A/S tools 가 scripts/ 를 담는다 — 이번 범위엔 바뀐 것이 0장이지만 ㄷ 잣대의 둘이 거기 있다
^COPY .*src \./src|yes|🔴 A/S tools 가 src/ 를 담는다 — 바뀐 3장이 **전부** 여기다 (시험 파일도 src/ 안이다)
^COPY .*vendor \./vendor|yes|A/S tools 가 vendor/ 를 담는다 (이번 판은 vendor 가 안 바뀐다 — 지난 판의 칸은 그대로 담긴다)
^COPY .*drizzle \./drizzle|no|🔵 A/S tools 는 drizzle/ 을 **안 담는다** — 볼륨이 정본이고 이번엔 더할 것이 0건이다
'
COPYRULES_WANT=4

# ══ 🔴🔴 앱 번들에서 쓸 표식 — **기능 표식이 한글이다**(머리말 ④) ════
#   🔴 이번 커밋이 번들에 남기는 글자는 **이 한글 문자열 하나뿐**이다.
#      [실측 2026-11-20] src 에서 기준 **0파일** → 지금 **1파일**.
#      주석을 걷은 뒤에도 **1파일**이고 그 하나가 **시험이 아닌 코드**다.
#        src/components/repair-cases/detail/PartRequestSection.tsx:610
#   🔵 **문자열 리터럴이다** — minify 는 문자열 내용을 안 바꾼다.
APPMARK='도번 / 비고'
APPMARK_NOTE='기준 0 → 지금 1파일 (찾는 칸 안내 문구의 끝 — 리터럴이라 minify 를 견딘다)'
# 🔴🔴 **곁들이가 이 판에서는 판정에 쓰인다**(68번까지는 찍기만 했다).
#    같은 placeholder 의 **앞부분**이라 **옛 판에도 새 판에도 있다.**
#    [실측 2026-11-20 · 옛 판 dss-as:6.0 의 번들] server **1** · static **1**.
#    🔴 이 값이 1 이상인데 APPMARK 가 0 이면 → **진짜 결함**(옛 이미지).
#    🔴 둘 다 0 이면 → **한글 grep 자체가 안 되는 것**(검사 탓).
APPMARK_SIDE='재고 관리에서 찾기'
# 🔵 **ASCII 대조** — 같은 실행에서 함께 센다. 한글 둘이 0 인데 이것이 1 이상이면
#    「한글만 안 걸린다」가 값으로 드러난다. [실측 · 옛 판] server 2 · static 1.
APPMARK_ASCII=hasLiveApproval
KEEPMARK1=hasLiveApproval
KEEPMARK1_NOTE='예순네째가 올린 프롭 이름 — 기준 4 → 지금 4파일'
KEEPMARK2=domesticOrders.completedEdit
KEEPMARK2_NOTE='예순세째가 올린 권한 열쇠 — 기준 11 → 지금 11파일'
KEEPMARK3=faultTags
KEEPMARK3_NOTE='예순두째가 올린 칸 이름 — 기준 13 → 지금 13파일'
KEEPMARK4=radiogroup
KEEPMARK4_NOTE='예순한째가 올린 DOM 속성 값 — 기준 2 → 지금 2파일'
KEEPMARK5='"ORDER_ISSUED"'
KEEPMARK5_NOTE='예순째가 올린 상태 값 — 기준 2 → 지금 2파일'
KEEPMARK6=domestic-order-status-filter
KEEPMARK6_NOTE='쉰아홉째가 올린 DOM id — 기준 3 → 지금 3파일'
KEEPMARK7=portal_approval_delegations
KEEPMARK7_NOTE='쉰여덟째가 올린 글자 — 기준 26 → 지금 26파일'
KEEPMARK8=domesticOrders.view
KEEPMARK8_NOTE='쉰여섯째가 올린 권한 열쇠 — 기준 17 → 지금 17파일'
# 🔴 기능 1 + 뒷걸음 8 = **아홉**. 68번은 여덟이었다(하나씩 늘려 왔다 — 빼지 마라).
MARKS_WANT=9
# 🔴 5-ㅂ-2(mark_net)가 거르는 글자 수 — 위 아홉 + 곁들이 하나 = **열**.
#    🔵 69번에서 가져온 절이다. 68번은 기능 표식 하나만 걸렀다.
BUNDLE_NET_WANT=10

# ══ 🔴 도구 이미지에서 쓸 **마지막 커밋 표식 — 둘이다** ═══════════════
#   🔴 과녁 파일은 **기준판에도 있던 모듈**이다(새 파일을 과녁으로 쓰면 「기준
#      0줄」이 파일이 없어서 0 인 것이라 아무것도 안 가른다).
#      🔵 이번 판은 **새 파일이 아예 0장**이라 고를 여지도 없었다.
TOOLMARK_FILE=src/lib/domain/inventory-gateway.ts
# ㄱ) 한글 쪽 — 주석 줄이다. [실측] 그 파일 안에서 기준 **0줄** → 지금 **1줄**.
#     src/lib/domain/inventory-gateway.ts:440 ( * 화면에서 거르기 — … **여섯 칸**에)
TOOLMARK='여섯 칸'
TOOLMARK_LINES_WANT=1
TOOLMARK_LINES_WAS=0
# ㄴ) 🔴 **ASCII 쪽 — 코드 줄이다.** [실측] 같은 파일에서 기준 **0줄** → 지금 **1줄**.
#     src/lib/domain/inventory-gateway.ts:466 (haystack 배열에 part.note 가 붙은 줄)
#     🔴 part.note 만으로는 안 된다 — 그 글자는 **기준판에도 1줄** 있었다(332줄).
#        쉼표까지 붙여야 0 → 1 이 된다.
#     🔵 [실측 · 옛 판 dss-as-tools:27 안] ko=0 · ascii=0 — **둘 다 옛 판을 가른다.**
TOOLMARK_ASCII='part.drawingNo, part.note'
TOOLMARK_ASCII_WANT=1
TOOLMARK_ASCII_WAS=0
# 🔴 **「그 표식이 가리키는 짝 파일」** — 68번은 여기가 **새 모듈**이었다(그 판에
#    새 파일이 있었다). 🔴 이번 판은 새 파일이 0장이라 **쓰는 쪽 화면**을 둔다.
#    까닭: 이 기능은 **모듈과 화면 둘이 한 몸**이다 — 한쪽만 담기면 안내 문구는
#    늘었는데 검색은 다섯 칸이거나, 그 반대가 된다.
TOOLMARK_PAIR=src/components/repair-cases/detail/PartRequestSection.tsx

# ══ 🔴 public/ 기대값 ═════════════════════════════════════════════════
#   🔵 A/S 는 yes 이고 안에 파일이 **9개**다[실측 — 작업본의 public/ 도 9개다].
AS_PUBLIC_WANT=yes
AS_PUBLIC_N=9

# ══ 🔴 **이번 판의 바뀐 파일 셋** — 도구 이미지가 담고 있어야 한다 ════
#   🔴 **바뀐 목록과 글자 그대로 같다**(3장). 시험 파일도 뺀 것이 없다 —
#      도구 이미지는 src/ 를 통째로 담는다.
#   🔴🔴 **이 검사만으로는 판을 못 가른다** — 셋 다 **기준판에도 있던 파일**이다
#      (새 파일 0장). [실측 · 옛 판 dss-as-tools:27 안에서 셋 다 yes 였다.]
#      🔵 가르는 것은 **TOOLMARK 둘**이다. 이 절은 「src/ 가 온전히 담겼는가」를
#         재는 자리로 남는다 — 빼지 않는다.
#   🔴 **없는 경로 하나를 함께 묻는다** — 「무조건 yes」인 검사인지 가른다.
PROBE_MISS=src/__dss_probe_no_such_file__.ts
AS_CHANGED_FILES='
src/components/repair-cases/detail/PartRequestSection.tsx
src/lib/domain/inventory-gateway.test.ts
src/lib/domain/inventory-gateway.ts
'
AS_CHANGED_FILES_WANT=3

# ══ 🔴 시험 등록 — A/S 는 **목록 파일** 방식이다 ══════════════════════
#   🔴 적어야 돈다. 빠뜨리면 **오류 없이 조용히 안 돈다.**
#      🔵 69번(재고)은 **글롭 방식**이었다 — 거기서 베끼면 이 절이 통째로 없어진다.
#   🔴 그 파일들은 **CRLF** 라 \r 를 걷고 -Fx 로 줄 전체를 맞댄다.
#   🔴 **이번 판은 새 시험이 0개다**(머리말 ②) — 64·65번 꼴로 **뜻을 뒤집는다**:
#      「줄 수가 안 줄었다」 + 「바뀐 시험이 아직 적혀 있다」.
#      [실측] 기준 4200(unit 2067 + components 1528 + db 591 + db-safety 14) → 지금 4200.
AS_TESTLIST_MIN_LINES=3900
AS_TESTLIST_LINES_WANT=4200
AS_TESTLIST_LINES_WAS=4200
AS_NEW_TESTS_WANT=0
# 🔵 바뀐 시험 **한 장** — scripts/test-lists/unit.txt 1406줄에 적혀 있다[실측].
AS_TOUCHED_TESTS='
src/lib/domain/inventory-gateway.test.ts
'
AS_TOUCHED_TESTS_WANT=1
AS_TESTLIST_FILES='
scripts/test-lists/unit.txt
scripts/test-lists/components.txt
scripts/test-lists/db.txt
scripts/test-lists/db-safety.txt
'
AS_TESTLIST_FILES_WANT=4

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-66"; fi

case "$MODE" in
  --check|--go|--verify) ;;
  *) printf '쓰는 법: %s [--check|--go|--verify] [산출물폴더]\n' "$0"; exit 2 ;;
esac

ASD="$DEV/$AS_REPO"
COREDIR="$ASD/vendor/dss-core"
UIDIR="$ASD/vendor/dss-ui"

printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' " 70-build.sh — 예순여섯째 배포 · 이미지 굽기 ($MODE)"
printf '%s\n' "   저장소 뿌리 : $DEV"
printf '%s\n' "   산출물 자리 : $OUT"
printf '%s\n' "   굽는 것     : 이미지 $HOWMANY (A/S 앱 · A/S 도구) · 🔴 **묶음 없음**"
printf '%s\n' "   판          : dss-as:6.0 → **6.1** · dss-as-tools:27 → **28**"
printf '%s\n' "   마이그레이션: 🔴 **0건** — 「바뀌지 않아야 한다」를 잰다"
printf '%s\n' "   서브모듈    : 🔵 **둘 다 안 움직인다**"
printf '%s\n' "   🔴 **기능 표식이 한글이다** — 1-ㄷ 절이 경계를 값으로 잽니다"
printf '%s\n' "══════════════════════════════════════════════════════════════"

# ══ 표를 읽는 길 ══════════════════════════════════════════════════════
#   🔴 **공백이 든 표(COPYRULES)는 tr -d ' ' 로 읽지 않는다** — 말이 뭉개진다.
#      그 표는 while IFS='|' read 로만 읽는다.
rows_of() { printf '%s\n' "$1" | grep -v '^[[:space:]]*$'; }
field() { printf '%s' "$1" | cut -d'|' -f"$2"; }

# 「기준 SHA 때 그 글자가 든 src/ 파일 수」 — 🔴 pathspec 에 글롭이 든 경로를
# 넘기지 않는다(src 하나만 넘긴다).
mark_was() { git -C "$ASD" grep -lF -- "$2" "$1" -- src 2>/dev/null </dev/null | wc -l | tr -d ' '; }
mark_now() { grep -rlF -- "$1" "$ASD/src" 2>/dev/null | wc -l | tr -d ' '; }

# 🔴 표식 한 쌍을 재는 길 — 기능(0 → N) · 뒷걸음(N → N) 둘 다 이 함수로 센다.
MARK_SEEN=0
check_mark() { # 1 글자 2 갈래(feature|keep|side) 3 사람이 읽을 말
  local a b
  MARK_SEEN=$((MARK_SEEN+1))
  a=$(mark_was "$AS_BASE" "$1"); b=$(mark_now "$1")
  printf '      %-32s 기준 %-4s → 지금 %-4s  (%s)\n' "[$1]" "${a:-?}" "${b:-?}" "$3"
  case "$2" in
    feature)
      if [ "${a:-x}" = "0" ] && [ "${b:-0}" -ge 1 ] 2>/dev/null; then
        ok "기능 표식 [$1] 이 **이번 판에만 있다**"
      else
        bad "기능 표식 [$1] 이 기준 ${a:-?} → 지금 ${b:-?} 다 — 0 → 1 이상을 기대했다"
        say "      🔴 기준판에도 있으면 그 표식은 **아무것도 안 가릅니다.**"
        say "      🔵 **네 판 연속으로 그 실물이 나왔습니다** — 예순째는 ORDER_ISSUED 가"
        say "         기준판의 ORDER_ISSUED_SORT_HINT 에 걸렸고, 예순한째는 selectionMode"
        say "         가, 예순두째는 지시받은 fault_tags 가 **주석 한 줄**뿐이었습니다."
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
    side)
      # 🔴 곁들이는 **옛 판에도 있어야** 뜻이 선다 — 「한글이 걸린다」를 보이는 자다.
      if [ "${a:-0}" -ge 1 ] 2>/dev/null && [ "${b:-0}" -ge 1 ] 2>/dev/null; then
        ok "곁들이 표식 [$1] 이 기준에도 지금에도 있다 (🔴 **한글 grep 이 되는지 가르는 자다**)"
      else
        bad "곁들이 표식 [$1] 이 기준 ${a:-?} · 지금 ${b:-?} 다 — 둘 다 1 이상이어야 한다"
        say "      🔴 곁들이가 **옛 판에 없으면** 번들에서 0 이 나왔을 때 「결함인지"
        say "         검사 탓인지」를 **못 가릅니다.** 다른 글자를 고르세요."
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
    say "       & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./70-build.sh $MODE"
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

# ── 1-ㄴ. 🔴 **경로 번역이 정말 꺼졌는가** — 값으로 잰다 ─────────────
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
    say "         & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./70-build.sh $MODE"
    say "      → 그래도 안 꺼지면 이 파일 맨 위의 dockr() 줄을 보세요."
  fi
fi

# ── 1-ㄷ. 🔴🔴 **한글이 컨테이너 경계를 글자 그대로 건너가는가** ─────
#   🔴 **이 판에 처음 생긴 절이다**(머리말 ④). 36~69번의 표식은 전부 ASCII 였다.
#      이번 판은 번들에서 셀 수 있는 글자가 **한글 문자열 하나뿐**이라, 경계가
#      깨지면 **멀쩡한 이미지가 ✗** 가 되고 그 ✗ 가 진짜 결함처럼 보인다.
#   🔵 길은 1-ㄴ 과 **같다** — 보내고 **되돌려 받아** 글자와 **바이트 수**를 맞댄다.
#      🔴 8진 이스케이프로 우회하지 않았다. 백슬래시 한 겹이 조용히 삼켜지는
#         함정이 이 PC 에 적혀 있어 **그 길이 더 위험**하다.
say ""
say "── 1-ㄷ. 🔴🔴 **한글이 컨테이너 안까지 글자 그대로 가는가** (이 판의 표식이 한글이다)"
say "🔴 이 줄이 ✗ 면 **이미지가 아니라 검사가 깨진 것**입니다 — 아래 번들 표식의"
say "   0 을 결함으로 읽지 마세요."
if [ -z "${PROBE_IMG:-}" ]; then
  unk "한글 경계" "잴 이미지가 없다 (1-ㄴ 과 같은 까닭)"
else
  KO_SEEN=0; KO_OK=0
  ko_probe() { # 1 글자 2 사람이 읽을 말
    local hb v got cb
    KO_SEEN=$((KO_SEEN+1))
    hb=$(printf '%s' "$1" | wc -c | tr -d ' ')
    v=$(dockr run --rm -e DSSKO="$1" --entrypoint sh "$PROBE_IMG" -c \
      'printf "%s|%s\n" "$DSSKO" "$(printf "%s" "$DSSKO" | wc -c | tr -d " ")"' 2>/dev/null | tr -d '\r')
    got=$(printf '%s' "$v" | cut -d'|' -f1)
    cb=$(printf '%s' "$v" | cut -d'|' -f2)
    printf '      %-14s 보낸 [%s] %s바이트 → 받은 [%s] %s바이트\n' "$2" "$1" "$hb" "${got:-못 읽음}" "${cb:-?}"
    if [ "${got:-}" = "$1" ] && [ "${cb:-x}" = "$hb" ]; then
      KO_OK=$((KO_OK+1))
    else
      bad "$2 의 한글이 경계에서 **달라졌다** — 받은 [${got:-못 읽음}] ${cb:-?}바이트 (보낸 ${hb}바이트)"
      say "      🔴 **이미지를 의심하지 마세요.** 로케일이나 인자 전달이 깨진 것입니다."
      doubt
    fi
  }
  ko_probe "$APPMARK"      "기능 표식"
  ko_probe "$APPMARK_SIDE" "곁들이 표식"
  ko_probe "$TOOLMARK"     "도구 표식"
  say "본 한글 ${KO_SEEN}개 · 그대로 건너간 것 ${KO_OK}개 (기대 3 · 3)"
  if [ "$KO_SEEN" = "3" ] && [ "$KO_OK" = "3" ]; then
    ok "한글 셋이 **컨테이너까지 글자 그대로 간다** (번들·소스의 0 을 결함으로 읽어도 된다)"
    say "      🔵 [실측 2026-11-20] 보낸 바이트는 [도번 / 비고] 15 · [재고 관리에서 찾기] 26 ·"
    say "         [여섯 칸] 10 입니다. 받은 쪽이 그와 같으면 경계가 멀쩡합니다."
  else
    bad "본 것 ${KO_SEEN} · 그대로인 것 ${KO_OK} 다 — 3 · 3 을 기대했다"
    say "      🔴 **아래 한글 표식의 ✗ 는 전부 이 줄의 결과입니다.** 이미지를 되돌리지 마세요."
  fi
fi

# ── 2. 저장소 **하나** ────────────────────────────────────────────────
step "2. 저장소 하나 — 깨끗한가 · 올라가 있나 · 범위가 맞나"
say "🔴 구운 이미지는 **그때 그 작업 폴더의 사진**입니다. 커밋 안 된 줄이 섞이면"
say "   나중에 같은 이미지를 다시 못 만듭니다."
if [ ! -d "$ASD/.git" ]; then
  bad "$AS_NAME — 저장소가 없다 ($ASD)"
else
  br=$(git -C "$ASD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ "$br" = "main" ] && ok "$AS_NAME 가지가 main 이다" || bad "$AS_NAME 가지가 ${br:-못 읽음} 다 — main 이어야 한다"
  dirty=$(git -C "$ASD" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${dirty:-1}" = "0" ]; then ok "$AS_NAME 미커밋 0줄"
  else
    bad "$AS_NAME 에 미커밋이 ${dirty}줄 있다 — 굽기 전에 정리하세요"
    git -C "$ASD" status --porcelain=v1 2>/dev/null | head -8 | sed 's/^/        /'
  fi
  h=$(git -C "$ASD" rev-parse --short HEAD 2>/dev/null)
  o=$(git -C "$ASD" rev-parse --short origin/main 2>/dev/null)
  say "HEAD $h · origin/main ${o:-없음}"
  if [ -n "${o:-}" ] && [ "$h" = "$o" ]; then
    ok "$AS_NAME main == origin/main (올라가 있다)"
  else
    ab=$(git -C "$ASD" rev-list --left-right --count main...origin/main 2>/dev/null)
    bad "$AS_NAME main 과 origin/main 이 다르다 (왼쪽=안 올린 것 오른쪽=안 받은 것: ${ab:-못 읽음})"
    say "      🔴 **「미푸시 0」은 받았다는 뜻이 아닙니다** — 오른쪽 수도 보세요."
  fi
  if git -C "$ASD" cat-file -e "$AS_BASE^{commit}" 2>/dev/null; then
    n=$(git -C "$ASD" rev-list --count "$AS_BASE..main" 2>/dev/null)
    say "기준 $AS_BASE..main 커밋 ${n:-못 읽음}개 (적어 둔 값 $AS_COMMITS_WANT)"
    git -C "$ASD" log --oneline "$AS_BASE..main" 2>/dev/null | sed 's/^/        /'
    if [ "${n:-x}" = "$AS_COMMITS_WANT" ]; then
      ok "$AS_NAME 범위가 적어 둔 것과 같다 ($AS_COMMITS_WANT 커밋)"
    else
      note "$AS_NAME 커밋이 ${n:-?}개다 — $AS_COMMITS_WANT 을 적어 두었다. **사람이 보세요**"
      say "      🔵 ⚠️ 로만 셉니다 — 그 사이에 하나 더 밀었을 수 있습니다."
      say "      🔴 그래도 **표식·파일 수 기대값이 전부 그 범위에서 나온 값**입니다."
    fi
  else
    bad "$AS_NAME 기준 SHA $AS_BASE 가 이 저장소에 없다 — 표가 틀렸다"
  fi
fi

# ── 3. 🔴 서브모듈 — **「안 움직였다」를 값으로 잰다** ────────────────
step "3. 🔴 서브모듈 — **이번 판은 둘 다 안 움직인다.** 그것을 값으로 잰다"
say "🔴 **66번은 dss-core 가 움직였습니다** — 거기서는 「옛 핀이면 ✗」와 「origin 에"
say "   올라갔나」를 함께 쟀습니다. **이번 판은 그 둘이 없습니다**(움직이지 않으니"
say "   잴 것이 없습니다). 🔴 움직이는 판이 오면 **66번 3-ㄴ 에서 되살리세요.**"
say "🔵 vendor/dss-ui 는 이것으로 **열다섯 판 연속** 안 움직입니다."
say "🔴 **이번 판에서 이 절이 특히 중요합니다** — 견적서·[사용 부품] 고르개의"
say "   다섯 칸 거르개가 **vendor/dss-core 의 filterPartOptions** 에 있습니다."
say "   거기가 움직였으면 「[부품요청] 한 곳만 넓힌다」는 2026-11-20 결정이 깨진 것입니다."
say "🔴 핀이 안 움직이면 3-ㄱ 은 **아무것도 안 가르는 ✓** 가 될 수 있습니다 —"
say "   그래서 3-ㄷ 이 **안의 파일을 값으로** 셉니다."
pin_of() { git -C "$ASD" submodule status "$1" 2>/dev/null </dev/null | awk '{print $1}' | tr -d '+-'; }
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
    say "      🔴 멈추고 알리세요. 이 배포본에는 **공용 스키마가 바뀌는 절이 없습니다.**"
    doubt
  fi
}
say ""
say "── 3-ㄱ. 핀 값 — 지난 판 그대로인가"
check_pin vendor/dss-core "$AS_CORE_PIN" "66번이 올린 핀 (filterPartOptions 의 다섯 칸이 거기 있다)"
check_pin vendor/dss-ui   "$UI_PIN"      "🔵 **열다섯 판 연속** 안 움직였다"
[ "$SUB_SEEN" = "2" ] && ok "서브모듈 핀 둘을 다 봤다 (표본이 비지 않았다)" \
  || bad "서브모듈 핀을 ${SUB_SEEN}개만 봤다 — 2개를 기대했다"

say ""
say "── 3-ㄴ. 🔴 **이번 범위가 vendor/ 를 건드렸는가** — 0줄이어야 한다"
VLIST=$(git -C "$ASD" diff --name-only "$AS_BASE..main" 2>/dev/null | tr -d '\r' | grep -E '^(vendor/|\.gitmodules)' || true)
vn=$(printf '%s\n' "$VLIST" | grep -c . || true)
say "vendor/ · .gitmodules 변경 ${vn:-?}줄 (기대 $CH_VENDOR)"
[ -n "${VLIST:-}" ] && printf '%s\n' "$VLIST" | sed 's/^/        /'
if [ "${vn:-x}" = "$CH_VENDOR" ]; then
  ok "이번 범위가 vendor/ 를 **한 줄도 안 건드렸다**"
  say "      🔵 그래서 **견적서와 [사용 부품] 고르개는 그대로 다섯 칸**입니다 —"
  say "         배포 뒤 눈 확인에서 **거기서 비고로 안 찾아지는 것이 맞습니다.**"
else
  bad "vendor/ 변경이 ${vn:-?}줄 있다 — $CH_VENDOR 을 기대했다. **서브모듈이 움직였다**"
  say "      🔴 누가 filterPartOptions 도 함께 넓혔을 수 있습니다 — 그러면 2026-11-20"
  say "         결정(「[부품요청] 한 곳만」)이 깨진 것입니다. **멈추고 알리세요.**"
  doubt
fi
# 🔴 서브모듈 **안으로 들어가** 커밋이 0개인지 센다 — 포인터 글자만 맞대면
#    「같은 핀을 다른 저장소가 들고 있는」 꼴을 못 가른다.
if [ -d "$COREDIR/.git" ] || [ -f "$COREDIR/.git" ]; then
  if git -C "$COREDIR" cat-file -e "$AS_CORE_PIN^{commit}" 2>/dev/null; then
    n=$(git -C "$COREDIR" rev-list --count "$AS_CORE_PIN..HEAD" 2>/dev/null)
    say "dss-core 안: 적어 둔 핀 → 지금 HEAD 커밋 ${n:-못 읽음}개 (기대 $AS_CORE_COMMITS_WANT)"
    if [ "${n:-x}" = "$AS_CORE_COMMITS_WANT" ]; then
      ok "dss-core 가 **0커밋 움직였다** (작업본도 그 핀에 서 있다)"
    else
      bad "dss-core 작업본이 핀보다 ${n:-?}커밋 앞서 있다 — $AS_CORE_COMMITS_WANT 을 기대했다"
      git -C "$COREDIR" log --oneline "$AS_CORE_PIN..HEAD" 2>/dev/null | head -5 | sed 's/^/        /'
    fi
  else
    unk "dss-core 커밋 수" "적어 둔 핀 ${AS_CORE_PIN:0:8} 가 그 저장소에 없다"
  fi
else
  bad "vendor/dss-core 가 **비어 있다**(.git 이 없다) — submodule update --init 이 필요하다"
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
check_sub "$COREDIR" "A/S-core"
check_sub "$UIDIR"   "A/S-ui"
[ "$SUBFILE_SEEN" = "2" ] && ok "서브모듈 작업본 둘을 다 봤다 (표본이 비지 않았다)" \
  || bad "서브모듈 작업본을 ${SUBFILE_SEEN}개만 봤다 — 2개를 기대했다"
if [ -f "$COREDIR/$AS_CORE_KEEP_FILE" ]; then
  ok "쉰여덟째가 올린 공용 스키마가 **작업본에 있다** ($AS_CORE_KEEP_FILE)"
  n=$(grep -cF "$AS_CORE_KEEP_TABLE" "$COREDIR/$AS_CORE_KEEP_FILE" 2>/dev/null || true)
  if isnum "${n:-}" && [ "${n:-0}" -ge 1 ]; then
    ok "그 파일이 표 이름 $AS_CORE_KEEP_TABLE 을 적는다 (${n}줄)"
  else
    bad "그 파일에 표 이름 $AS_CORE_KEEP_TABLE 이 없다 — 다른 것을 보고 있다"
  fi
else
  bad "공용 스키마 파일이 **작업본에 없다** — 🔴 핀만 맞고 **파일이 비었다**"
  say "      🔴 그대로 구우면 도구가 @dss/core/schema 에서 그 표를 **못 찾습니다.**"
  say "      → git -C \"$ASD\" submodule update --init --recursive"
fi
n=$(grep -c "$AS_CORE_KEEP_EXPORT" "$COREDIR/src/schema/index.ts" 2>/dev/null || true)
if isnum "${n:-}" && [ "${n:-0}" -ge 1 ]; then
  ok "index.ts 가 그 스키마를 **내보낸다** (${n}줄)"
  say "      🔵 안 내보내면 도구가 Cannot find export 로 죽습니다 — 2026-09-21 에"
  say "         운영에서 도구가 전부 죽은 그 자리입니다."
else
  bad "index.ts 가 그 스키마를 안 내보낸다 — Cannot find export 가 난다"
fi

# ── 4. 🔴 마이그레이션 — **0건.** 「바뀌지 않아야 한다」를 잰다 ───────
step "4. 🔴 마이그레이션 — **0건이다.** 「안 바뀌었는가」를 잰다"
say "🔴 **66번은 여기가 「1건이다」였습니다** — 거기에는 **지우는 문장 잣대와 그"
say "   표본 여섯**(4-ㄱ) · **0131 의 생김새**(4-ㄷ) · **창 안 일곱의 스냅샷 짝**"
say "   (4-ㄹ)이 있었습니다. 🔴 **이번 판에는 그 셋이 없습니다** — 잴 .sql 이"
say "   이번 범위에 **한 장도 없기** 때문입니다(아래가 그것을 값으로 잽니다)."
say "   🔴 .sql 이 한 장이라도 생기는 판에서는 **66번에서 그 셋부터 되살리세요.**"
say "🔴🔴 **67·68번의 「다음 번호」가 한 칸 빗나가 있었습니다 — 고쳤습니다**(머리말 ⑥)."
say "   [실측] .sql 132장의 번호는 **0000~0131** 이고 journal 의 마지막 idx 도 **131**"
say "   입니다. 그러면 다음 번호는 **$AS_NEXT_MIG** 입니다. 67·68번은 0133 을 보고"
say "   있었고, 그래서 누가 ${AS_NEXT_MIG} 를 새로 뽑아도 **조용히 ✓** 였습니다."
MIGCK_SEEN=0
s=$(ls -1 "$ASD/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
j=$(grep -o '"idx"' "$ASD/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
MIGCK_SEEN=$((MIGCK_SEEN+1))
say ".sql ${s:-?}장 · meta/_journal.json 의 idx ${j:-?}개 (기대 $AS_SQL_WANT · $AS_SQL_WANT)"
if [ "${s:-x}" = "$AS_SQL_WANT" ] && [ "${j:-x}" = "$AS_SQL_WANT" ]; then
  ok "저장소 drizzle/ 이 ${AS_SQL_WANT}장이고 목록도 ${AS_SQL_WANT}개다 (예순두째가 올린 수 그대로)"
else
  bad "저장소가 .sql ${s:-?} · idx ${j:-?} 다 — ${AS_SQL_WANT}·${AS_SQL_WANT} 를 기대했다"
  say "      🔴 **.sql 과 idx 가 다르면** 목록에 없는 파일이 있다는 뜻이고,"
  say "         drizzle 이 그것을 **아예 모릅니다**(적용이 0건으로 조용히 끝납니다)."
  doubt
fi
MIGCK_SEEN=$((MIGCK_SEEN+1))
dn=$(git -C "$ASD" diff --name-only "$AS_BASE..main" -- drizzle 2>/dev/null | tr -d '\r' | grep -c . || true)
say "이번 범위의 drizzle/ 변경 ${dn:-?}줄 (기대 $AS_DRIZZLE_DIFF_WANT)"
if [ "${dn:-x}" = "$AS_DRIZZLE_DIFF_WANT" ]; then
  ok "이번 범위가 drizzle/ 을 **한 줄도 안 건드렸다** — 🔴 **올릴 마이그레이션이 없다**"
  say "      🔵 그래서 70-deploy.sh 에는 **--migrate 모드가 없습니다.**"
else
  bad "drizzle/ 변경이 ${dn:-?}줄 있다 — 0 을 기대했다"
  say "      🔴 **이 배포본에는 마이그레이션을 올리는 절이 없습니다.** 멈추고 알리세요."
  git -C "$ASD" diff --name-only "$AS_BASE..main" -- drizzle 2>/dev/null | sed 's/^/        /'
fi
MIGCK_SEEN=$((MIGCK_SEEN+1))
nx=$(ls -1 "$ASD/drizzle/${AS_NEXT_MIG}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
lm=$(ls -1 "$ASD/drizzle/${AS_LAST_MIG}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
say "$AS_NEXT_MIG 이 생겼는가: ${nx:-?}개 (기대 0) · $AS_LAST_MIG 이 있는가: ${lm:-?}개 (기대 1)"
if [ "${nx:-1}" = "0" ] && [ "${lm:-0}" = "1" ]; then
  ok "$AS_NEXT_MIG 이 없고 $AS_LAST_MIG 이 있다 (마지막이 $AS_LAST_MIG 그대로 — 적용 대기 **0건**)"
  say "      🔴 **$AS_LAST_MIG 쪽을 함께 세는 까닭**: 「없는가」만 보면 번호가 한 칸"
  say "         빗나가도 영영 통과합니다. 67·68번이 실제로 그랬습니다(머리말 ⑥)."
elif [ "${nx:-1}" != "0" ]; then
  bad "$AS_NEXT_MIG 이 **생겼다** — 이 배포본은 $AS_LAST_MIG 까지를 전제로 쓰였다. 멈추고 알릴 것"
else
  bad "$AS_LAST_MIG 이 ${lm:-?}개다 — 1 을 기대했다. 🔴 **번호 잣대가 빗나가 있다**"
  doubt
fi
[ "$MIGCK_SEEN" = "3" ] && ok "마이그레이션 검사 셋을 다 돌았다 (표본이 비지 않았다)" \
  || bad "마이그레이션 검사를 ${MIGCK_SEEN}개만 돌았다 — 3개를 기대했다"
say ""
say "🔵 **운영이 지금 들고 있어야 하는 수** — $PROD_MIGS_NOTE"
say "   🔴 **개발 PC 에서는 못 잽니다.** 70-deploy.sh --check 가 DB 에 물어 확인하고,"
say "      어긋나면 **거기서 멈춥니다.** 어긋나면 그것은 **이 배포와 무관한 다른 사고**입니다."
say "   🔵 A/S 는 마이그레이션이 **볼륨**에서 돕니다(/volume1/dss/as-migrations) —"
say "      이번에는 보낼 묶음이 없지만 **볼륨이 132장 그대로인지**는 거기서 잽니다."
say "      🔴 66번이 131 → 132 로 올려 둔 수입니다. 줄었으면 다른 사고입니다."

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 담는 길 · 굽는 까닭 · 소스가 새 코드를 담고 있나 ────────────
# ══════════════════════════════════════════════════════════════════════
step "5. 🔴 담는 길 · 굽는 까닭 · 소스가 새 코드를 담고 있나"

# 5-ㄱ. Dockerfile 이 담는 길
say "── 5-ㄱ. Dockerfile 의 COPY 줄 — 🔴 **굽는 까닭이 여기 있다**"
COPY_SEEN=0
DF="$ASD/Dockerfile"
while IFS='|' read -r RE WANT MSG; do
  [ -n "${RE:-}" ] || continue
  COPY_SEEN=$((COPY_SEEN+1))
  if [ ! -f "$DF" ]; then bad "A/S 의 Dockerfile 이 없다 ($DF)"; continue; fi
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

# 5-ㄴ. .dockerignore 가 .next 를 막는가
say ""
say "── 5-ㄴ. .dockerignore 가 .next 를 막는가 — 막아야 dev 서버를 안 내려도 된다"
DI="$ASD/.dockerignore"
if [ ! -f "$DI" ]; then bad "A/S 에 .dockerignore 가 없다 — 🔴 호스트의 .next 가 섞여 들어간다"
else
  n=$(grep -c '^\.next' "$DI" 2>/dev/null || true)
  say ".dockerignore 의 ^.next 줄 ${n:-?}개 (기대 1 이상)"
  [ "${n:-0}" -ge 1 ] 2>/dev/null && ok ".dockerignore 가 .next 를 막는다" \
    || bad ".dockerignore 가 .next 를 **안 막는다** — dev 서버를 내리고 구워야 한다"
fi

# 5-ㄷ. 🔴 **굽는 까닭 ㄱ** — npm 명령 수
say ""
say "── 5-ㄷ. 🔴 굽는 까닭 **ㄱ** — npm 명령이 늘었나 (scripts 블록 안만 센다)"
say "🔴 「안 걸린다」도 **값으로 잽니다.** 바뀌었는데 0 으로 적어 두면 다음 판이"
say "   그 거짓을 근거로 「안 구워도 된다」를 꺼냅니다."
a=$(git -C "$ASD" show "$AS_BASE:package.json" 2>/dev/null </dev/null | count_scripts)
b=$(count_scripts < "$ASD/package.json")
say "npm 명령 — 기준 ${a:-?} → 지금 ${b:-?} (적어 둔 값 $NPM_WAS → $NPM_NOW)"
if [ "${a:-x}" = "$NPM_WAS" ] && [ "${b:-x}" = "$NPM_NOW" ]; then
  if [ "$NPM_WAS" = "$NPM_NOW" ]; then ok "npm 명령이 안 늘었다 — **ㄱ 잣대가 안 걸린다**"
  else ok "npm 명령이 $NPM_WAS → $NPM_NOW 로 늘었다 — 🔴 **ㄱ 잣대가 걸린다**"; fi
else
  bad "npm 명령이 ${a:-?} → ${b:-?} 다 — $NPM_WAS → $NPM_NOW 를 기대했다"
  say "      🔴 늘었으면 **도구를 안 구우면 Missing script** 가 납니다(41번이 겪었다)."
  doubt
fi
pk=$(git -C "$ASD" diff --numstat "$AS_BASE..main" -- package.json package-lock.json tsconfig.json drizzle.config.ts 2>/dev/null | wc -l | tr -d ' ')
say "package.json · package-lock.json · tsconfig.json · drizzle.config.ts 의 바뀐 파일 ${pk:-?}장 (기대 0)"
if [ "${pk:-1}" = "0" ]; then
  ok "의존성·설정 파일이 **한 장도 안 바뀌었다**"
  say "      🔴 그래서 tar 크기 견주기를 **둘 다 strict** 로 두었습니다."
else
  note "그 넷 중 ${pk}장이 바뀌었다 — 0을 기대했다. **이미지 크기가 뛸 수 있습니다.** 사람이 보세요"
fi
# 🔵 뒷걸음 — 쉰여덟째가 더한 heic2any 가 그대로 있는가(빠지면 아이폰 사진이 다시 막힌다)
n=$(grep -c '"heic2any"' "$ASD/package.json" 2>/dev/null || true)
say "heic2any (쉰여덟째가 더한 것) — ${n:-?}줄 (기대 1)"
[ "${n:-x}" = "1" ] && ok "heic2any 가 그대로 있다 (뒷걸음친 나무가 아니다)" \
  || bad "heic2any 가 ${n:-?}줄이다 — 1 을 기대했다"

# 5-ㄹ. 🔴 **굽는 까닭 ㄴ·ㄷ·ㄹ** — 도구를 굽는 결정적인 자리
say ""
say "── 5-ㄹ. 🔴 굽는 까닭 **ㄴ·ㄷ·ㄹ** — 도구 이미지를 굽는 까닭을 값으로 댄다"
LIST=$(git -C "$ASD" diff --name-only "$AS_BASE..main" 2>/dev/null | tr -d '\r')
all=$(printf '%s\n' "$LIST" | grep -c . || true)
pay=$(printf '%s\n' "$LIST" | grep -cE "$TOOLS_PAYLOAD_RE" || true)
say "ㄴ) tools 스테이지가 담는 것 중 바뀐 파일 — ${pay:-?} / ${all:-?} 장 (적어 둔 값 $TOOLS_PAYLOAD_WANT / $CH_ALL)"
say "🔴 68번은 이 자리가 **8 / 8** 이었습니다 — 베껴 쓰면 틀렸을 자리라 다시 셌습니다."
say "🔵 **빠지는 것이 하나도 없습니다** — drizzle/ 과 vendor/ 가 0장이고,"
say "   **A/S 는 시험 파일도 src/ 안에** 있기 때문입니다(69번의 재고는 tests/ 였습니다)."
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
say "ㄷ) 🔵 **도구의 import 닫힘** — 🔴 **이번 판에도 안 걸린다.** 잣대만 재 둔다"
say "🔴 65번은 **여기가 도구를 굽는 결정적인 까닭**이었습니다. 67·68번과 이번 판은"
say "   그 과녁(src/lib/domain/domestic-order-list.ts)이 **한 줄도 안 바뀌었습니다.**"
say "🔴 **그래도 절을 빼지 않습니다**(66·67·68번과 같은 판단) — 빼면 다음 판이 「ㄷ 는"
say "   원래 없는 절」로 읽고, 그 둘이 옛 몸통으로 도는 사고를 아무도 못 잡습니다."
say "   여기서는 **잣대가 살아 있는지**(그 둘이 아직 그 모듈을 부르는가)와 **과녁이"
say "   0줄인지**를 잽니다."
IMP_SEEN=0; IMP_OK=0
tn=$(printf '%s\n' "$LIST" | grep -cFx "$TOOL_IMPORT_TARGET" || true)
say "바뀐 목록에 $TOOL_IMPORT_TARGET 이 ${tn:-?}줄 (기대 $TOOL_IMPORT_TARGET_WANT)"
if [ "${tn:-x}" = "$TOOL_IMPORT_TARGET_WANT" ]; then
  ok "그 모듈이 **이번 범위에 ${TOOL_IMPORT_TARGET_WANT}줄이다** — ㄷ 잣대는 안 걸린다"
else
  note "그 모듈이 바뀐 목록에 ${tn:-?}줄이다 — $TOOL_IMPORT_TARGET_WANT 을 기대했다. **사람이 보세요**"
  say "      🔵 1 이면 ㄷ 가 되살아난 것이라 **굽는 까닭이 하나 더 는 것**입니다 —"
  say "         그래서 ⚠️ 로만 셉니다(막을 일이 아닙니다)."
fi
while IFS='|' read -r F IMP; do
  [ -n "${F:-}" ] || continue
  IMP_SEEN=$((IMP_SEEN+1))
  if [ ! -f "$ASD/$F" ]; then bad "$F 가 없다 — 표가 틀렸다"; continue; fi
  n=$(grep -cF -- "$IMP" "$ASD/$F" 2>/dev/null || true)
  printf '      %-48s [%s] %s줄\n' "$F" "$IMP" "${n:-?}"
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then IMP_OK=$((IMP_OK+1))
  else bad "$F 가 그 모듈을 안 부른다 — 표가 틀렸다"; fi
done <<ENDIMP
$(rows_of "$TOOL_IMPORTERS")
ENDIMP
say "본 것 ${IMP_SEEN} · 부르는 것 ${IMP_OK} (기대 $TOOL_IMPORTERS_WANT · $TOOL_IMPORTERS_WANT)"
if [ "$IMP_SEEN" = "$TOOL_IMPORTERS_WANT" ] && [ "$IMP_OK" = "$TOOL_IMPORTERS_WANT" ]; then
  ok "ㄷ 잣대가 **살아 있다** — 도구 스크립트 ${IMP_OK}장이 아직 그 모듈을 부른다"
  say "      🔵 과녁이 바뀌는 판이 오면 이 절이 그때 ✗ 가 아니라 **까닭**이 됩니다."
else
  bad "본 것 ${IMP_SEEN} · 부르는 것 ${IMP_OK} 다 — ${TOOL_IMPORTERS_WANT} 을 기대했다"
  doubt
fi
say ""
say "ㄹ) 공용 스키마(vendor/*)가 움직였나 — 3-ㄴ 에서 **0줄**로 쟀다 → **안 걸린다**"
say "   🔴 66번은 여기가 **걸렸습니다**(dss-core 에 fault_tags 칸이 생겼습니다)."
say "      🔵 그 칸은 지금 핀 안에 **그대로** 있고, 도구 이미지 안에서 값으로 봅니다."
say ""
say "ㅁ) 🔵 **마이그레이션은 0건이다** — 묶음을 만들 까닭이 없다(4절이 값으로 쟀다)."
say "   🔴 66번은 여기가 **1건**이라 묶음을 만들었습니다. 1건이라도 생기는 판에서는"
say "      **66번의 「셋째 산출물」 절을 통째로 되살리세요** — A/S 는 .sql 이 이미지가"
say "      아니라 **볼륨**에 있어서, 묶음을 안 보내면 적용이 0건으로 조용히 끝납니다."
say ""
say "🔴 **결론: 도구 이미지를 굽는다.** ㄴ 하나가 걸렸다(ㄱ·ㄷ·ㄹ·ㅁ 은 안 걸렸다)."
say "   🔵 반대 방향의 사고도 이 저장소에 적혀 있습니다 — 「마이그레이션 0건이니"
say "      도구는 안 굽는다」가 틀려 비상구 둘을 못 올린 적이 있고, 이튿날에는"
say "      거꾸로 「명령이 늘어난 것」을 놓쳐 Missing script 가 났습니다."

# 5-ㅁ. 바뀐 파일 수 + 🔴 **덮기 관문**(69번에서 가져왔다)
say ""
say "── 5-ㅁ. 바뀐 파일 수 — 🔴 **68번과 같은 자리가 거의 없다**"
say "🔴 **대괄호 셈은 66번이 더한 것입니다.** 67번은 0 · 68번은 1 이었고 이번 판은"
say "   다시 **0** 입니다 — 그래도 안 뺍니다. 「0이니 뺀다」를 한 번 하면 다음에 1 이"
say "   되는 날 아무도 못 봅니다(68번이 그 실물이었습니다)."
src=$(printf '%s\n' "$LIST" | grep -c '^src/' || true)
scr=$(printf '%s\n' "$LIST" | grep -c '^scripts/' || true)
drz=$(printf '%s\n' "$LIST" | grep -c '^drizzle/' || true)
ven=$(printf '%s\n' "$LIST" | grep -cE '^(vendor/|\.gitmodules)' || true)
par=$(printf '%s\n' "$LIST" | grep -cF '(' || true)
brk=$(printf '%s\n' "$LIST" | grep -cF '[' || true)
new=$(git -C "$ASD" diff --diff-filter=A --name-only "$AS_BASE..main" 2>/dev/null | grep -c . || true)
del=$(git -C "$ASD" diff --diff-filter=D --name-only "$AS_BASE..main" 2>/dev/null | grep -c . || true)
printf '      전체 %-4s src %-4s scripts %-3s drizzle %-2s vendor %-2s 새 %-3s 지움 %-2s 괄호 %-2s 대괄호 %s\n' \
  "${all:-?}" "${src:-?}" "${scr:-?}" "${drz:-?}" "${ven:-?}" "${new:-?}" "${del:-?}" "${par:-?}" "${brk:-?}"
printf '      (적어 둔 값) %-4s     %-4s         %-3s         %-2s        %-2s    %-3s      %-2s      %-2s       %s\n' \
  "$CH_ALL" "$CH_SRC" "$CH_SCRIPTS" "$CH_DRIZZLE" "$CH_VENDOR" "$CH_NEW" "$CH_DEL" "$CH_PAREN" "$CH_BRACKET"
if [ "${all:-x}" = "$CH_ALL" ] && [ "${src:-x}" = "$CH_SRC" ] && [ "${scr:-x}" = "$CH_SCRIPTS" ] \
   && [ "${drz:-x}" = "$CH_DRIZZLE" ] && [ "${ven:-x}" = "$CH_VENDOR" ] && [ "${new:-x}" = "$CH_NEW" ] \
   && [ "${par:-x}" = "$CH_PAREN" ] && [ "${brk:-x}" = "$CH_BRACKET" ]; then
  ok "바뀐 파일 수가 적어 둔 것과 전부 같다"
else
  note "바뀐 파일 수가 적어 둔 것과 다르다 — **사람이 보세요**"
  say "      🔵 커밋이 하나 더 밀렸으면 여기가 먼저 어긋납니다(2절의 ⚠️ 와 짝입니다)."
fi
if [ "${del:-1}" = "$CH_DEL" ]; then ok "지운 파일 ${CH_DEL}장"
else bad "🔴 파일을 ${del}장 **지웠다** — 0 을 기대했다. 멈추고 알릴 것"; fi
# 🔴🔴 **덮기 관문 — 69번에서 가져왔다.** 폴더별 셈의 합이 전체와 맞는가.
#    🔵 69번은 src + tests == 전체 였다. **A/S 에는 tests/ 폴더가 없다**(시험이
#       src/ 안에 산다) — 그래서 네 폴더로 적었고, 이번 값으로는 **src 만으로
#       전체를 덮는다**(3 = 3).
#    🔴 이 관문이 잡는 것: 어느 폴더에도 안 걸리는 파일이 **조용히 섞이는 것**.
#       예를 들어 Dockerfile · .env.example · docs/ 가 바뀌면 여기서 먼저 울린다.
say ""
say "🔴 **덮기 관문**(69번에서 가져왔다) — 폴더별 셈의 합이 전체와 맞는가"
if isnum "${src:-}" && isnum "${scr:-}" && isnum "${drz:-}" && isnum "${ven:-}" && isnum "${all:-}"; then
  printf '      src %s + scripts %s + drizzle %s + vendor %s = %s (전체 %s)\n' \
    "$src" "$scr" "$drz" "$ven" "$((src + scr + drz + ven))" "$all"
  if [ "$((src + scr + drz + ven))" = "$all" ]; then
    ok "네 폴더가 전체를 덮는다 (다른 자리에 샌 파일이 없다)"
    if [ "${src:-0}" = "${all:-x}" ]; then
      ok "🔵 **이번 판은 src/ 하나가 전체를 덮는다** (${src} = ${all})"
    else
      say "      🔵 이번 판의 적어 둔 값은 src 만으로 전체를 덮는 꼴입니다 — 지금은 아닙니다."
    fi
  else
    bad "네 폴더의 합이 $((src + scr + drz + ven)) 다 — 전체 ${all} 를 기대했다. **다른 자리가 섞였다**"
    say "      🔴 어느 폴더에도 안 걸린 파일이 있습니다. 위 목록을 사람이 보세요."
    doubt
  fi
else
  unk "덮기 관문" "앞의 수 중 못 잰 것이 있다"
fi
say "🔵 **이번 범위에는 괄호가 ${CH_PAREN}장 · 대괄호가 ${CH_BRACKET}장입니다**(68번은 둘 다 1장)."
printf '%s\n' "$LIST" | grep -F '(' | sed 's/^/        /'
printf '%s\n' "$LIST" | grep -F '[' | sed 's/^/        /'
say "   🔴 **그래도 목록을 넘기는 길은 그대로입니다** — here 문서 + grep -Fx 로만 쓰고"
say "      컨테이너 안에서는 set -f 로 글롭을 끕니다. 68번이 [id] 한 장을 그 길로"
say "      받아 냈습니다. 「이번엔 괜찮다」로 길을 바꾸면 다음 판이 그 함정을 밟습니다."

# 5-ㅂ. 🔴 표식 — 소스에서 먼저 센다
say ""
say "── 5-ㅂ. 🔴 표식 — **소스에서 먼저 센다** (기능 0→N · 곁들이 N→N · 뒷걸음 N→N)"
say "🔴🔴 **기능 표식이 한글입니다**(머리말 ④) — 이번 커밋이 번들에 남기는 글자가"
say "   **찾는 칸 안내 문구 한 줄뿐**이기 때문입니다. 문자열 리터럴이라 minify 를"
say "   견디지만, **한글이라 검사 쪽이 깨질 위험**이 있습니다(1-ㄷ 가 그것을 쟀습니다)."
say "🔴 **곁들이도 여기서 함께 잽니다** — 그것은 같은 문구의 **앞부분**이라 옛 판에도"
say "   있습니다. 번들에서 **기능 0 · 곁들이 1 이상**이면 진짜 결함이고, **둘 다 0**"
say "   이면 한글 grep 이 안 되는 것입니다. 그 가름이 이 판의 핵심입니다."
say "🔴 **지시받은 수를 그대로 믿지 않고 다시 셌습니다**(src 안). 네 판 연속으로"
say "   적어 준 표식이 틀렸고 매번 구현한 쪽이 바로잡았습니다."
MARK_SEEN=0
check_mark "$APPMARK"      feature "$APPMARK_NOTE"
check_mark "$APPMARK_SIDE" side    '같은 문구의 앞부분 — 기준 1 → 지금 1파일 (옛 판에도 있다)'
check_mark "$KEEPMARK1" keep    "$KEEPMARK1_NOTE"
check_mark "$KEEPMARK2" keep    "$KEEPMARK2_NOTE"
check_mark "$KEEPMARK3" keep    "$KEEPMARK3_NOTE"
check_mark "$KEEPMARK4" keep    "$KEEPMARK4_NOTE"
check_mark "$KEEPMARK5" keep    "$KEEPMARK5_NOTE"
check_mark "$KEEPMARK6" keep    "$KEEPMARK6_NOTE"
check_mark "$KEEPMARK7" keep    "$KEEPMARK7_NOTE"
check_mark "$KEEPMARK8" keep    "$KEEPMARK8_NOTE"
say "본 표식 ${MARK_SEEN}개 (기대 $((MARKS_WANT + 1)) — 기능 1 + 곁들이 1 + 뒷걸음 8)"
[ "$MARK_SEEN" = "$((MARKS_WANT + 1))" ] && ok "표식 $((MARKS_WANT + 1))개를 다 봤다 (표본이 비지 않았다)" \
  || bad "표식을 ${MARK_SEEN}개만 봤다 — $((MARKS_WANT + 1))개를 기대했다"
say "🔵 뒷걸음 표식이 **여덟**인 까닭: 예순네째·예순세째·예순두째·예순한째·예순째·"
say "   쉰아홉째·쉰여덟째·쉰여섯째가 올린 글자를 하나씩 잡고 있습니다 —"
say "   **하나도 빼지 마세요.** 뺀 자리는 다시 넣는 사람이 없습니다"
say "   (65번 넷 → 66번 다섯 → 67번 여섯 → 68번 일곱 → **여덟**)."
say "🔴 그중 hasLiveApproval 은 **68번에서는 기능 표식**이었습니다. 어제 올린 것이라"
say "   오늘은 「있다」가 아무것도 안 가릅니다 — **뒷걸음으로 내렸습니다.**"

# 5-ㅂ-2. 🔴 **번들에 쓰는 글자를 전부 「주석을 걷은 뒤」로 거른다** (69번에서 가져왔다)
say ""
say "── 5-ㅂ-2. 🔴 **번들에 쓰는 글자가 주석만이 아닌가** — 열 글자를 다 거른다"
say "🔴 「소스 글자로 재는 검사는 주석을 먼저 센다」가 이 저장소에 적혀 있습니다."
say "   🔴 **주석은 minify 가 지웁니다** — 주석에만 있는 글자를 표식으로 쓰면 번들에서"
say "      0 이 나오고, 그 ✗ 는 **진짜 결함처럼** 보입니다(66번이 거기서 글자를 갈았습니다)."
say "🔴 **68번은 기능 표식 하나만 걸렀습니다.** 69번이 「번들에 쓰는 것을 다 거른다」로"
say "   넓혔고, **그 절을 가져왔습니다.** [실측 2026-11-20] 그 덕에 이런 것이 보입니다:"
say "   domesticOrders.completedEdit 은 날것 11파일인데 **주석을 걷으면 7파일**이고"
say "   그중 시험이 아닌 것은 **3파일**뿐입니다 — 눈으로는 넉넉해 보이던 수입니다."
NET_SEEN=0
mark_net() { # 1 글자 2 사람이 읽을 말
  local raw net code seen f n
  NET_SEEN=$((NET_SEEN+1))
  raw=$(grep -rlF -- "$1" "$ASD/src" 2>/dev/null | wc -l | tr -d ' ')
  net=0; code=0; seen=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    seen=$((seen+1))
    n=$(grep -vE '^[[:space:]]*(//|\*|/\*)' "$f" 2>/dev/null | grep -cF -- "$1" || true)
    isnum "${n:-}" || n=0
    if [ "${n:-0}" -ge 1 ]; then
      net=$((net + 1))
      # 🔵 **시험 파일은 이미지에 안 담긴다** — 번들에 남는 것은 시험이 아닌 쪽이다.
      #    🔴 A/S 는 시험이 src/ 안에 살아서 이 가름이 **실제로 쓰인다**(69번의
      #       재고는 tests/ 폴더라 거의 안 걸렸다).
      case "$f" in (*.test.ts|*.test.tsx) ;; (*) code=$((code + 1)) ;; esac
    fi
  done <<ENDNET
$(grep -rlF -- "$1" "$ASD/src" 2>/dev/null)
ENDNET
  say "[$1] — 날것 ${raw:-?}파일 · **주석을 걷은 뒤 ${net}파일** · 그중 시험이 아닌 것 ${code}파일 (본 파일 ${seen}장) — $2"
  if [ "${seen:-0}" != "${raw:-x}" ]; then
    bad "본 파일이 ${seen}장인데 날것은 ${raw:-?}파일이다 — **목록을 넘기는 길이 끊겼다.** 위 수를 못 믿는다"
  elif [ "${raw:-0}" = "0" ]; then
    # 🔴 「주석에만 있다」와 「아예 없다」는 **다른 말**이다. 한 말로 뭉개면 다음
    #    사람이 엉뚱한 곳을 판다 — 5-ㅂ 이 이미 ✗ 를 냈을 자리이기도 하다.
    bad "src/ 에 [$1] 이 **한 파일도 없다** — 주석 문제가 아니라 **글자가 틀렸다**"
    doubt
  elif [ "${net:-0}" -ge 1 ] 2>/dev/null && [ "${code:-0}" -ge 1 ] 2>/dev/null; then
    ok "[$1] 이 주석을 걷고도 ${net}파일에 남고, 그중 ${code}장이 **시험이 아닌 코드**다 (번들 표식으로 쓸 수 있다)"
  elif [ "${net:-0}" -ge 1 ] 2>/dev/null; then
    bad "[$1] 이 주석을 걷으면 ${net}파일이 남지만 **전부 시험 파일**이다 — 시험은 이미지에 안 담긴다"
    say "      🔴 다른 글자를 고르세요. 번들에서 0 이 나오고 그 ✗ 는 진짜 결함처럼 보입니다."
    doubt
  else
    bad "[$1] 이 주석을 걷으면 **0파일**이다 — 🔴 이 글자는 src/ 에서 **주석에만** 있습니다"
    say "      🔴 minify 가 주석을 지우므로 번들 표식으로 못 씁니다. 다른 글자를 고르세요."
    doubt
  fi
}
mark_net "$APPMARK"      "🔴 기능 표식 (한글 리터럴)"
mark_net "$APPMARK_SIDE" "🔴 곁들이 (한글 grep 이 되는지 가르는 자)"
mark_net "$KEEPMARK1" "뒷걸음 ① 예순네째"
mark_net "$KEEPMARK2" "뒷걸음 ② 예순세째"
mark_net "$KEEPMARK3" "뒷걸음 ③ 예순두째"
mark_net "$KEEPMARK4" "뒷걸음 ④ 예순한째"
mark_net "$KEEPMARK5" "뒷걸음 ⑤ 예순째"
mark_net "$KEEPMARK6" "뒷걸음 ⑥ 쉰아홉째"
mark_net "$KEEPMARK7" "뒷걸음 ⑦ 쉰여덟째"
mark_net "$KEEPMARK8" "뒷걸음 ⑧ 쉰여섯째"
say "걸른 글자 ${NET_SEEN}개 (기대 $BUNDLE_NET_WANT — 번들에서 세는 것 전부)"
[ "$NET_SEEN" = "$BUNDLE_NET_WANT" ] && ok "번들에 쓰는 글자 ${BUNDLE_NET_WANT}개를 다 걸렀다 (표본이 비지 않았다)" \
  || bad "걸른 글자가 ${NET_SEEN}개다 — ${BUNDLE_NET_WANT}개를 기대했다"
say "🔵 **APPMARK 는 주석을 걷어도 1파일이고 그 하나가 시험이 아닌 코드입니다**"
say "   [실측 — PartRequestSection.tsx:610 의 placeholder 한 줄]. 🔴 그 한 줄이"
say "   **이 배포의 전부**라 번들 표식을 다른 데서 구할 수 없습니다."

# 5-ㅅ. 🔴 도구 이미지가 쓸 **마지막 커밋 표식 — 둘이다**
say ""
say "── 5-ㅅ. 🔴 **마지막 커밋 표식**(도구 이미지용) — **둘**을 소스에서 먼저 센다"
say "🔴 도구 이미지는 **소스가 글자 그대로** 들어 있어 한글이 덜 위험합니다."
say "   🔵 그래도 **ASCII 짝을 함께 둡니다** — 한글 쪽만 0 이 나오면 그것은"
say "      **이미지가 아니라 검사**입니다(1-ㄷ 와 같은 가름)."
say "🔵 **새로 생긴 파일을 과녁으로 삼지 않았습니다** — 새 파일이면 「기준 0줄」이"
say "   파일이 없어서 0 인 것이라 아무것도 안 가릅니다. 🔵 **이번 판은 새 파일이"
say "   아예 0장**이라 고를 여지도 없었습니다."
say "🔴 **그 사실도 git 에서 직접 셉니다**(적어 둔 값을 안 믿습니다)."
if [ ! -f "$ASD/$TOOLMARK_FILE" ]; then
  bad "$TOOLMARK_FILE 이 없다 (표식을 둘 자리가 없다)"
else
  # 🔴 66번에서 가져온 한 줄 — **과녁 파일이 기준판에도 있었나.** 없으면
  #    「기준 0줄」이 파일이 없어서 0 인 것이라 **공짜 ✓** 가 된다.
  if git -C "$ASD" cat-file -e "$AS_BASE:$TOOLMARK_FILE" 2>/dev/null; then
    ok "과녁 파일이 **기준판에도 있었다** (「기준 0줄」이 공짜 ✓ 가 아니다)"
  else
    bad "과녁 파일이 기준판에 **없었다** — 그러면 기준 0줄은 아무것도 안 가른다"
    say "      🔴 기준판에도 있던 파일을 과녁으로 고르세요."
    doubt
  fi
  TM_SEEN=0
  tool_mark_pair() { # 1 글자 2 기준기대 3 지금기대 4 사람이 읽을 말
    local was n
    TM_SEEN=$((TM_SEEN+1))
    was=$(git -C "$ASD" show "$AS_BASE:$TOOLMARK_FILE" 2>/dev/null </dev/null | grep -cF -- "$1" || true)
    n=$(grep -cF -- "$1" "$ASD/$TOOLMARK_FILE" 2>/dev/null || true)
    say "[$1] in $TOOLMARK_FILE — 기준 ${was:-?}줄 → 지금 ${n:-?}줄 (기대 $2 → $3) — $4"
    if [ "${was:-x}" != "$2" ]; then
      bad "기준판의 그 파일에 [$1] 이 ${was:-?}줄 있다 — $2 를 기대했다"
      say "      🔴 기준이 0 이 아니면 그 표식은 **이 판을 안 가릅니다.** 다른 글자를 고르세요."
      doubt
    elif [ "${n:-x}" = "$3" ]; then
      ok "[$1] 이 기준 ${2}줄 → 지금 ${n}줄이다 (**이 표식이 판을 가른다**)"
    elif [ "${n:-0}" -ge 1 ] 2>/dev/null; then
      note "[$1] 이 ${n}줄이다 — $3 을 기대했다. 사람이 보세요"
    else
      bad "[$1] 이 지금 파일에 **없다** — 표가 틀렸다"
      doubt
    fi
  }
  tool_mark_pair "$TOOLMARK"       "$TOOLMARK_LINES_WAS"  "$TOOLMARK_LINES_WANT"  "🔴 한글 쪽 (440줄 주석)"
  tool_mark_pair "$TOOLMARK_ASCII" "$TOOLMARK_ASCII_WAS"  "$TOOLMARK_ASCII_WANT"  "🔵 ASCII 쪽 (466줄 **코드**)"
  say "본 도구 표식 ${TM_SEEN}개 (기대 2 — 한글 하나 + ASCII 하나)"
  [ "$TM_SEEN" = "2" ] && ok "도구 표식 둘을 다 봤다 (표본이 비지 않았다)" \
    || bad "도구 표식을 ${TM_SEEN}개만 봤다 — 2개를 기대했다"
  # 🔴 part.note 를 홀로 쓰면 안 되는 까닭을 **값으로 보인다.**
  pn=$(git -C "$ASD" show "$AS_BASE:$TOOLMARK_FILE" 2>/dev/null </dev/null | grep -cF -- 'part.note' || true)
  say "🔵 참고 — [part.note] 만으로는 기준판에도 ${pn:-?}줄 있습니다(기대 1)."
  say "   🔴 그래서 쉼표까지 붙여 [$TOOLMARK_ASCII] 로 잡아야 **0 → 1** 이 됩니다."
  [ "${pn:-x}" = "1" ] && ok "part.note 가 기준판에 1줄이었다 (쉼표를 붙인 까닭이 값으로 선다)" \
    || note "part.note 가 기준판에 ${pn:-?}줄이다 — 1 을 기대했다. 사람이 보세요"
fi
# 🔴 **짝 파일** — 68번은 여기가 「새 모듈」이었다. 이번 판은 새 파일이 0장이라
#    **쓰는 쪽 화면**을 둔다. 모듈과 화면이 한 몸이라, 한쪽만 담기면 안내 문구는
#    늘었는데 검색은 다섯 칸이거나 그 반대가 된다.
if [ -f "$ASD/$TOOLMARK_PAIR" ]; then
  ok "그 표식의 **짝 파일이 작업본에 있다** ($TOOLMARK_PAIR)"
  say "      🔵 68번은 이 자리가 **새 모듈**이었습니다 — 이번 판은 새 파일이 0장이라"
  say "         **쓰는 쪽 화면**을 뒀습니다. 모듈과 화면이 한 몸입니다."
else
  bad "$TOOLMARK_PAIR 이 작업본에 **없다** — 안내 문구와 검색이 갈린다"
fi
say "🔴 **이번 범위는 커밋이 하나입니다.** 그래서 이 표식은 기능 표식과 **같은 커밋**을"
say "   가리킵니다. 🔵 그래도 따로 두는 까닭은 **재는 곳이 다르기** 때문입니다 —"
say "   앱은 minify 를 거친 **번들**에서, 도구는 **소스 글자 그대로**에서 셉니다."
say "   한쪽만 깨지는 일이 실제로 있었습니다(2026-11-18 · 경로 번역)."
say "🔴 커밋이 둘 이상인 판에서는 **뒤 커밋에서만 바뀐 파일**을 과녁으로 고르세요."

# 5-ㅇ. 🔴 시험 등록 — **뜻을 뒤집었다**(새 시험이 0개다)
say ""
say "── 5-ㅇ. 🔴 시험 등록 — **새 시험이 0개다.** 64·65번 꼴로 뜻을 뒤집어 잰다"
say "🔴 63·66·67·68번은 여기서 **「새 시험 N개가 목록에 등록돼 있다」**를 쟀습니다."
say "   **이번 판은 새 파일이 0장**이라 그대로 두면 **표본이 비어서 ✗** 입니다."
say "   빼지 않고 뜻을 뒤집었습니다 — **「줄 수가 안 줄었다」**와"
say "   **「바뀐 시험이 아직 적혀 있다」**."
say "🔴 **A/S 는 목록 파일 방식입니다** — 적어야 돕니다. 빠뜨리면 그 시험은"
say "   **오류 없이 조용히 안 돕니다.** 🔴 **69번(재고)은 글롭 방식이었습니다** —"
say "   거기서 베꼈으면 이 절이 통째로 없어졌을 자리입니다."
say "🔴 **바뀐 시험이 넷에서 하나로 줄었습니다**(68번은 넷). 수를 안 고치면"
say "   **「본 것 1 · 기대 4」로 ✗** 가 나고, 그 ✗ 는 등록이 빠진 것처럼 보입니다."
TL=$(cat "$ASD"/scripts/test-lists/*.txt 2>/dev/null | tr -d '\r')
lines=$(printf '%s\n' "$TL" | grep -c . || true)
# 🔴 기준판의 줄 수를 **git 에서 그 자리에서 다시 센다** — 적어 둔 값만 믿으면
#    「둘 다 줄어든 꼴」을 못 가른다.
TLBASE=0; TLB_SEEN=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  TLB_SEEN=$((TLB_SEEN+1))
  n=$(git -C "$ASD" show "$AS_BASE:$f" 2>/dev/null </dev/null | tr -d '\r' | grep -c . || true)
  isnum "${n:-}" || n=0
  TLBASE=$((TLBASE + n))
done <<ENDTLB
$(rows_of "$AS_TESTLIST_FILES")
ENDTLB
say "목록 줄 수 — 기준 ${TLBASE} (본 파일 ${TLB_SEEN}장) → 지금 ${lines:-?} (적어 둔 값 $AS_TESTLIST_LINES_WANT)"
if [ "$TLB_SEEN" != "$AS_TESTLIST_FILES_WANT" ]; then
  bad "기준판 목록을 ${TLB_SEEN}장만 봤다 — ${AS_TESTLIST_FILES_WANT}장을 기대했다"
fi
if ! isnum "${lines:-}" || [ "${lines:-0}" -lt "$AS_TESTLIST_MIN_LINES" ]; then
  bad "목록을 ${lines:-못 읽음}줄밖에 못 읽었다 — 🔴 **빈 결과는 삼켜진 오류일 수 있다.** 아래를 못 믿는다"
elif [ "${TLBASE:-0}" -lt "$AS_TESTLIST_MIN_LINES" ]; then
  bad "기준판 목록이 ${TLBASE}줄이다 — git show 가 비었을 수 있다. 아래를 못 믿는다"
elif [ "${lines}" -lt "${TLBASE}" ]; then
  bad "목록이 ${TLBASE} → ${lines} 로 **줄었다** — 🔴 누가 시험 등록을 **지웠다**"
  say "      🔴 등록이 빠지면 그 시험은 **오류 없이 조용히 안 돕니다.** 멈추고 알리세요."
elif [ "${lines}" = "${TLBASE}" ]; then
  ok "목록 줄 수가 ${lines} 그대로다 (이번 범위에 새 시험이 없으니 이것이 맞다)"
  [ "${lines}" = "$AS_TESTLIST_LINES_WANT" ] && ok "적어 둔 값 $AS_TESTLIST_LINES_WANT 과도 같다" \
    || note "적어 둔 값은 $AS_TESTLIST_LINES_WANT 인데 ${lines} 다 — 사람이 보세요"
  [ "${TLBASE}" = "$AS_TESTLIST_LINES_WAS" ] && ok "기준판 줄 수도 적어 둔 값 $AS_TESTLIST_LINES_WAS 과 같다" \
    || note "기준판이 ${TLBASE}줄이다 — $AS_TESTLIST_LINES_WAS 을 기대했다. 사람이 보세요"
else
  note "목록이 ${TLBASE} → ${lines} 로 **늘었다** — 이번 범위엔 새 시험이 없습니다. 사람이 보세요"
  say "      🔵 늘어난 줄이 **까닭을 적은 주석**일 수도 있습니다 — 이 저장소의 목록"
  say "         파일은 경로만 적는 곳이 아닙니다. 막지는 않습니다."
fi
# 🔴 새 시험 파일이 0개인가 — 이번 범위에서 추가된 *.test.ts(x) 를 센다.
nt=$(git -C "$ASD" diff --diff-filter=A --name-only "$AS_BASE..main" 2>/dev/null | tr -d '\r' | grep -cE '\.test\.tsx?$' || true)
say "이번 범위에서 **새로 생긴** 시험 파일 ${nt:-?}개 (기대 $AS_NEW_TESTS_WANT)"
if [ "${nt:-x}" = "$AS_NEW_TESTS_WANT" ]; then
  ok "새 시험 파일이 ${AS_NEW_TESTS_WANT}개다 (등록할 것이 없다 — 그래서 이 절의 뜻을 뒤집었다)"
else
  bad "새 시험 파일이 ${nt:-?}개다 — $AS_NEW_TESTS_WANT 을 기대했다. 🔴 **그러면 등록 여부를 재야 합니다**"
  git -C "$ASD" diff --diff-filter=A --name-only "$AS_BASE..main" 2>/dev/null | sed 's/^/        /'
  say "      🔴 새 시험이 생겼으면 **68번의 「새 시험이 목록에 등록돼 있다」 절을"
  say "         되살리세요** — 등록이 빠지면 오류 없이 조용히 안 돕니다."
  doubt
fi
# 🔴 **빈 표본 방지** — 이번에 바뀐 시험 하나가 아직 목록에 적혀 있는가.
ct=$(printf '%s\n' "$LIST" | grep -cE '\.test\.tsx?$' || true)
say "이번에 **바뀐** 시험 파일 ${ct:-?}개 (적어 둔 값 $CH_TESTS) — 이것이 표본이다"
[ "${ct:-x}" = "$CH_TESTS" ] && ok "바뀐 시험이 ${CH_TESTS}개다 (표본을 바뀐 목록에서 뽑았다)" \
  || note "바뀐 시험이 ${ct:-?}개다 — $CH_TESTS 를 기대했다. 사람이 보세요"
if [ "${lines:-0}" -ge "$AS_TESTLIST_MIN_LINES" ] 2>/dev/null; then
  got=0; seen=0
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    seen=$((seen+1))
    n=$(printf '%s\n' "$TL" | grep -cFx -- "$t" || true)
    if [ "${n:-0}" -ge 1 ] 2>/dev/null; then got=$((got+1)); else printf '        🔴 안 적힘 %s\n' "$t"; fi
  done <<ENDAST
$(rows_of "$AS_TOUCHED_TESTS")
ENDAST
  probe=$(printf '%s\n' "$TL" | grep -cFx -- "$PROBE_MISS" || true)
  say "바뀐 시험 — 본 것 ${seen} · 적혀 있는 것 ${got} (기대 $AS_TOUCHED_TESTS_WANT · $AS_TOUCHED_TESTS_WANT) · 없는 경로 ${probe:-?}줄(기대 0)"
  if [ "${probe:-1}" != "0" ]; then
    bad "**없는 경로가 목록에 있다고 나왔다** — 줄 전체 일치가 깨졌다. 위 수도 못 믿는다"
  elif [ "$seen" = "$AS_TOUCHED_TESTS_WANT" ] && [ "$got" = "$AS_TOUCHED_TESTS_WANT" ]; then
    ok "이번에 바뀐 시험 ${AS_TOUCHED_TESTS_WANT}개가 **아직 목록에 적혀 있다**"
    say "      🔵 지난 판들이 등록해 둔 줄입니다 — [실측] scripts/test-lists/unit.txt 1406줄."
    say "      🔴 지워졌으면 그 시험은 조용히 안 돕니다(오류도 안 납니다)."
  else
    bad "적혀 있는 것이 ${got}/${AS_TOUCHED_TESTS_WANT} 개다 — 등록이 빠지면 조용히 안 돈다"
    doubt
  fi
fi
n=0; tlseen=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  tlseen=$((tlseen+1))
  [ -f "$ASD/$f" ] && n=$((n+1)) || printf '        없음 %s\n' "$f"
done <<ENDASL
$(rows_of "$AS_TESTLIST_FILES")
ENDASL
say "목록 파일 — 본 것 ${tlseen} · 있는 것 ${n} (기대 $AS_TESTLIST_FILES_WANT)"
if [ "$tlseen" = "$AS_TESTLIST_FILES_WANT" ] && [ "$n" = "$AS_TESTLIST_FILES_WANT" ]; then
  ok "시험 목록 파일 ${AS_TESTLIST_FILES_WANT}장이 다 있다"
else
  bad "목록 파일이 ${n}/${AS_TESTLIST_FILES_WANT} 장이다"
fi

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
      say "         & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./70-build.sh --verify"
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
    say "         **보내지 마세요.** 이 배포는 마이그레이션이 0건입니다."
  fi
else
  say "$OUT 가 아직 없다 — --go 때 만든다 (--check 는 아무것도 안 만든다)"
  ok "산출물 자리를 쓸 수 있다"
fi
# 🔴 7-ㄴ. dev 서버 — 🔵 **떠 있는 것이 정상이다**
say ""
say "── 7-ㄴ. dev 서버 — **막지는 않는다. 값으로 찍는다**"
say "🔵 docker build 는 dev 서버를 안 내려도 됩니다(.dockerignore 가 .next 를 막습니다 — 5-ㄴ)."
say "🔵 **A/S dev 서버(3000)와 DB(5442)가 떠 있는 것이 정상입니다** — 🔴 **끄지 마세요.**"
say "   🔵 재고(3800)·포털(3100)도 떠 있을 수 있습니다 — 이 파일은 그 둘을 안 봅니다."
say "🔴 그래도 찍는 까닭: 3000번이 떠 있으면 **호스트의 npm run build** 가 .next 를"
say "   두고 다투고, 그 탓에 난 tsc 오류를 코드 탓으로 오해한 적이 있습니다."
say "   🔵 이 파일은 **호스트의 npm run build 를 한 번도 안 부릅니다** — docker build 만 합니다."
PORT_SEEN=0
for p in "$AS_PORT:A/S dev 서버" "$AS_DB_PORT:A/S 개발 DB(dss-pg-app)"; do
  PORT_SEEN=$((PORT_SEEN+1))
  pn=${p%%:*}; nm=${p#*:}
  if netstat -an 2>/dev/null | grep -q "[:.]$pn[^0-9].*LISTEN"; then
    say "$nm ($pn) — **떠 있다** (🔵 정상입니다)"
  else
    say "$nm ($pn) — 안 떠 있다"
  fi
done
[ "$PORT_SEEN" = "2" ] && ok "포트 둘을 다 봤다" || bad "포트를 ${PORT_SEEN}개만 봤다"
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
#    🔵 set -f 로 글롭을 끈다 — 🔵 **이번 범위엔 괄호도 대괄호도 0장이지만**
#       그 길을 그대로 둔다(68번이 [id] 한 장을 그 길로 받아 냈다).
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
    printf '%s\n' "      🔴 **이 ✓ 는 판을 안 가릅니다** — 셋 다 **기준판에도 있던 파일**입니다"
    printf '%s\n' "         (이번 범위의 새 파일이 0장입니다). [실측 2026-11-20 · 옛 판"
    printf '%s\n' "         dss-as-tools:27 안에서 셋 다 yes 였습니다.] 판을 가르는 것은"
    printf '%s\n' "         **마지막 커밋 표식 둘**입니다. 이 절은 「src/ 가 온전히 담겼는가」입니다."
  else
    printf '  ✗ 본 것 %s · 있는 것 %s 다 — %s 를 기대했다\n' "${seen:-0}" "${got:-0}" "$3"; IMGFAIL=1
    printf '%s\n' "      🔴 본 것이 모자라면 **목록을 넘기는 길이 끊긴 것**(글롭 함정)이고,"
    printf '%s\n' "         있는 것만 모자라면 **옛 소스가 담긴 이미지**입니다."
  fi
}

# 🔴 번들 안에서 **ASCII** 글자 하나를 센다 — .next/server 와 .next/static 을 둘 다.
bundle_mark() { # 1 태그 2 글자 3 사람이 부르는 말
  local v s t
  v=$(dockr run --rm -e M="$2" --entrypoint sh "$1" -c \
    'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  s=$(printf '%s' "$v" | awk '{print $1}'); t=$(printf '%s' "$v" | awk '{print $2}')
  printf '      [%s] — .next/server %s개 · .next/static %s개 (🔴 합이 1 이상이어야 한다)\n' "$2" "${s:-?}" "${t:-?}"
  if isnum "${s:-}" && isnum "${t:-}" && [ "$((s + t))" -ge 1 ]; then
    printf '  ✓ %s\n' "$3"
  else
    printf '  ✗ %s — **없다.** 올리지 마세요\n' "$3"; IMGFAIL=1
    printf '%s\n' "      🔵 **검사 자신도 의심하세요** — 이 글자는 소스에서만 세어 보았습니다."
  fi
}

# ══ 🔴🔴 **한글 표식을 세는 길 — 이 판에만 있는 함수** ════════════════
#   머리말 ④ 의 처방이다. **한 번의 실행에서 셋을 센다**:
#     ㄱ) 기능 표식(한글)   ㄴ) 곁들이(한글 · 옛 판에도 있다)   ㄷ) ASCII 대조
#   🔴 **가름을 로그 글자로 적는다.** 적어 두지 않으면 한밤중에 ✗ 를 본 사람이
#      **멀쩡한 이미지를 되돌린다.**
#     · 기능 ≥1                       → ✓
#     · 기능 0 · 곁들이 ≥1            → 🔴 **진짜 결함**(옛 이미지를 구웠다)
#     · 기능 0 · 곁들이 0 · ASCII ≥1  → 🔴 **한글 grep 이 안 되는 것**(검사 탓)
#     · 셋 다 0                       → 🔴 **번들을 아예 못 읽었다**(.next·경로 번역)
#   🔵 [실측 2026-11-20 · 옛 판 dss-as:6.0 의 번들]
#        [도번 / 비고]        server 0 · static 0   ← 이 판이 올리는 글자다
#        [재고 관리에서 찾기] server 1 · static 1   ← **한글이 실제로 걸린다**
#        [hasLiveApproval]    server 2 · static 1
bundle_mark_ko() { # 1 태그 2 기능글자 3 곁들이글자 4 ASCII대조 5 사람이 부르는 말
  local v ms mt ss st as at
  v=$(dockr run --rm -e M="$2" -e S="$3" -e A="$4" --entrypoint sh "$1" -c \
    'printf "%s %s %s %s %s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)" "$(grep -rlF "$S" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$S" /app/.next/static 2>/dev/null | wc -l)" "$(grep -rlF "$A" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$A" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  ms=$(printf '%s' "$v" | awk '{print $1}'); mt=$(printf '%s' "$v" | awk '{print $2}')
  ss=$(printf '%s' "$v" | awk '{print $3}'); st=$(printf '%s' "$v" | awk '{print $4}')
  as=$(printf '%s' "$v" | awk '{print $5}'); at=$(printf '%s' "$v" | awk '{print $6}')
  printf '      🔴 기능 [%s] — server %s · static %s (합이 1 이상이어야 한다)\n' "$2" "${ms:-?}" "${mt:-?}"
  printf '      🔴 곁들이 [%s] — server %s · static %s (참고 1 · 1 — **옛 판에도 있다**)\n' "$3" "${ss:-?}" "${st:-?}"
  printf '      🔵 ASCII 대조 [%s] — server %s · static %s (참고 2 · 1)\n' "$4" "${as:-?}" "${at:-?}"
  if ! isnum "${ms:-}" || ! isnum "${mt:-}" || ! isnum "${ss:-}" || ! isnum "${st:-}" || ! isnum "${as:-}" || ! isnum "${at:-}"; then
    printf '  ✗ %s — **수를 못 받았다** (받은 값 [%s])\n' "$5" "${v:-}"; IMGFAIL=1
    printf '%s\n' "      🔴 **이미지가 아니라 검사를 먼저 보세요** — 1-ㄴ(경로 번역)과"
    printf '%s\n' "         1-ㄷ(한글 경계)가 ✓ 였는지 보세요."
    return
  fi
  if [ "$((ms + mt))" -ge 1 ]; then
    printf '  ✓ %s\n' "$5"
    if [ "$((ss + st))" -lt 1 ]; then
      printf '%s\n' "      ⚠️ 곁들이가 0 인데 기능이 1 이상입니다 — 곁들이는 기능 글자가 든"
      printf '%s\n' "         **같은 문구의 앞부분**이라 그럴 수 없습니다. 사람이 보세요."
    fi
    return
  fi
  IMGFAIL=1
  if [ "$((ss + st))" -ge 1 ]; then
    printf '  ✗ %s — 🔴🔴 **진짜 결함입니다. 올리지 마세요**\n' "$5"
    printf '%s\n' "      🔴 **가름: 곁들이가 걸렸습니다**(server ${ss} · static ${st}). 한글 grep 은"
    printf '%s\n' "         멀쩡히 돌고 있는데 **이번 판의 글자만 없습니다** — 즉 **옛 소스로"
    printf '%s\n' "         구운 이미지**입니다. 저장소의 HEAD 와 미커밋을 보세요(2절)."
  elif [ "$((as + at))" -ge 1 ]; then
    printf '  ✗ %s — 🔴🔴 **검사 탓일 확률이 높습니다. 배포가 아니라 이 검사를 먼저 보세요**\n' "$5"
    printf '%s\n' "      🔴 **가름: 한글 둘이 모두 0 인데 ASCII 대조는 걸렸습니다**"
    printf '%s\n' "         (server ${as} · static ${at}). 번들은 멀쩡히 읽히는데 **한글만 안"
    printf '%s\n' "         걸립니다** — 인코딩·로케일·인자 전달 중 어디가 깨진 것입니다."
    printf '%s\n' "      🔴 **멀쩡한 이미지를 되돌리지 마세요.** 1-ㄷ 절(한글 경계)을 먼저 보고,"
    printf '%s\n' "         거기가 ✓ 였다면 컨테이너 안 grep 쪽입니다."
    printf '%s\n' "      🔵 고칠 때는 **다시 굽지 말고 --verify 를 쓰세요** — 지문이 안 바뀝니다."
  else
    printf '  ✗ %s — 🔴🔴 **번들을 아예 못 읽었습니다**\n' "$5"
    printf '%s\n' "      🔴 **가름: 셋 다 0 입니다.** 한글도 ASCII 도 안 걸렸습니다 —"
    printf '%s\n' "         /app/.next 가 없거나(runner 가 아닌 것을 구웠다) 경로 번역이"
    printf '%s\n' "         살아 있는 것입니다. 1-ㄴ 과 /app/server.js 줄을 보세요."
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
    # 🔵 A/S 는 public/ 이 yes 이고 안에 9개다.
    v=$(dock "$TAG" -c 'if [ -d /app/public ]; then printf "yes %s\n" "$(ls -1 /app/public 2>/dev/null | wc -l)"; else printf "no 0\n"; fi')
    pst=$(printf '%s' "$v" | awk '{print $1}'); pn=$(printf '%s' "$v" | awk '{print $2}')
    printf '      /app/public: %s (파일 %s개 · 기대 %s · 참고 %s개)\n' "${pst:-못 읽음}" "${pn:-?}" "$AS_PUBLIC_WANT" "$AS_PUBLIC_N"
    if [ "${pst:-}" = "$AS_PUBLIC_WANT" ] && [ "${pn:-0}" -ge 1 ] 2>/dev/null; then
      printf '  ✓ public/ 이 담겼다 (%s개)\n' "$pn"
    elif [ "${pst:-}" = "$AS_PUBLIC_WANT" ]; then
      printf '  ✗ public/ 은 있는데 **비어 있다** — A/S 는 %s개를 기대했다\n' "$AS_PUBLIC_N"; IMGFAIL=1
    else
      printf '  ✗ /app/public 이 %s 다 — %s 를 기대했다\n' "${pst:-못 읽음}" "$AS_PUBLIC_WANT"; IMGFAIL=1
      printf '%s\n' "      🔵 없으면 정적 파일이 404 가 됩니다(새 사이트에서 걸리는 셋 중 하나)."
    fi
    # 🔴🔴 **이 판의 기능 표식은 한글이다** — 세 수를 한 번에 받아 가른다.
    bundle_mark_ko "$TAG" "$APPMARK" "$APPMARK_SIDE" "$APPMARK_ASCII" \
      "번들에 **이번 판의 글자**가 있다 (찾는 칸 안내 문구 끝의 「/ 비고」)"
    bundle_mark "$TAG" "$KEEPMARK1" "예순네째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$TAG" "$KEEPMARK2" "예순세째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$TAG" "$KEEPMARK3" "예순두째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$TAG" "$KEEPMARK4" "예순한째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$TAG" "$KEEPMARK5" "예순째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$TAG" "$KEEPMARK6" "쉰아홉째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$TAG" "$KEEPMARK7" "쉰여덟째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$TAG" "$KEEPMARK8" "쉰여섯째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
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
    # 🔴 **마지막 커밋 표식 둘을 한 번에 받는다** — 한글 하나 · ASCII 하나.
    #    🔴 **경로를 상대로 넘기고 /app/ 를 컨테이너 안에서 붙인다**(경로 번역).
    #    🔴 yes/no 가 아니라 **센 줄 수**를 받는다 — 0 과 「못 읽음」을 가른다.
    v=$(dockr run --rm -e M="$TOOLMARK" -e A="$TOOLMARK_ASCII" -e F="$TOOLMARK_FILE" --entrypoint sh "$TAG" -c \
      'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s %s\n" "$(grep -cF -- "$M" "$p")" "$(grep -cF -- "$A" "$p")"; else printf "missing 0 0\n"; fi' 2>/dev/null | tr -d '\r')
    tst=$(printf '%s' "$v" | awk '{print $1}')
    tko=$(printf '%s' "$v" | awk '{print $2}')
    tas=$(printf '%s' "$v" | awk '{print $3}')
    printf '      마지막 커밋 표식 in %s — 파일 %s\n' "$TOOLMARK_FILE" "${tst:-못 읽음}"
    printf '        🔴 한글  [%s] %s줄 (기대 %s)\n' "$TOOLMARK" "${tko:-?}" "$TOOLMARK_LINES_WANT"
    printf '        🔵 ASCII [%s] %s줄 (기대 %s)\n' "$TOOLMARK_ASCII" "${tas:-?}" "$TOOLMARK_ASCII_WANT"
    if [ "${tst:-}" = "missing" ]; then
      printf '  ✗ 그 파일 자체가 이미지에 없다 — src/ 가 온전히 안 담겼다\n'; IMGFAIL=1
      printf '%s\n' "      🔵 **경로 번역부터 의심하세요** — 1-ㄴ 절이 ✓ 였는지 보세요."
    elif [ "${tst:-}" != "hit" ] || ! isnum "${tko:-}" || ! isnum "${tas:-}"; then
      printf '  ✗ 못 읽었다 (받은 값 [%s])\n' "${v:-}"; IMGFAIL=1
    elif [ "${tko:-0}" -ge 1 ] && [ "${tas:-0}" -ge 1 ]; then
      printf '  ✓ **마지막 커밋이 담겼다** (한글 %s줄 · ASCII %s줄 — 둘 다 걸렸다)\n' "$tko" "$tas"
      printf '%s\n' "      🔵 앱 이미지는 **같은 작업본에서 같은 실행으로** 굽습니다 — 2절이 그"
      printf '%s\n' "         작업본의 HEAD 와 미커밋 0 을 확인했으므로 앱에도 들어 있습니다."
    elif [ "${tas:-0}" -ge 1 ]; then
      printf '  ✗ 🔴🔴 **한글만 0 입니다 — 검사 탓일 확률이 높습니다**\n'; IMGFAIL=1
      printf '%s\n' "      🔴 **가름: ASCII 쪽(${tas}줄)이 걸렸습니다.** 같은 커밋의 같은 파일에서"
      printf '%s\n' "         나온 두 글자인데 **한글만 안 걸립니다** — 새 소스는 담겼다는 뜻입니다."
      printf '%s\n' "      🔴 **이미지를 되돌리지 마세요.** 1-ㄷ 절(한글 경계)을 먼저 보세요."
    elif [ "${tko:-0}" -ge 1 ]; then
      printf '  ✗ ASCII 쪽이 0줄이다 (한글은 %s줄) — 같은 커밋인데 한쪽만이다. 사람이 보세요\n' "$tko"; IMGFAIL=1
    else
      printf '  ✗ 그 파일은 있는데 **둘 다 0줄**이다 — **옛 소스가 담긴 이미지다**\n'; IMGFAIL=1
      printf '%s\n' "      🔵 [실측 2026-11-20 · 옛 판 dss-as-tools:27] 이 둘이 꼭 0 · 0 이었습니다."
    fi
    # 🔴 **짝 파일** — 모듈과 화면이 한 몸이다(5-ㅅ).
    v=$(dockr run --rm -e P="$TOOLMARK_PAIR" --entrypoint sh "$TAG" -c \
      'set -f; if [ -f "/app/$P" ]; then echo "yes"; else echo "no"; fi' 2>/dev/null | tr -d '\r')
    printf '      짝 파일 %s: %s (기대 yes)\n' "$TOOLMARK_PAIR" "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ 쓰는 쪽 화면도 담겼다 (안내 문구와 검색이 안 갈린다)\n'
    else printf '  ✗ 짝 파일이 없다 — 안내 문구와 검색이 갈린다\n'; IMGFAIL=1; fi
    # 🔴 **이번에 바뀐 셋이 다 담겼는가** — 🔵 이 절은 판을 **안 가른다**(ask_files 가 적는다).
    ask_files "$TAG" "$AS_CHANGED_FILES" "$AS_CHANGED_FILES_WANT" "이번에 바뀐 파일"
    # 🔴 **ㄷ 잣대의 실물** — 그 모듈을 import 하는 scripts/ 둘이 이미지 안에도 있는가.
    #    🔵 이번 판은 scripts/ 가 **0장 바뀌었지만** 담겼는지는 여전히 이 줄이 잰다.
    v=$(dockr run --rm --entrypoint sh "$TAG" -c \
      'n=0; for f in /app/scripts/lib/delivered-date-sync-survey.ts /app/scripts/lib/requested-due-date-sync-survey.ts; do [ -f "$f" ] && n=$((n+1)); done; echo "n=$n"' 2>/dev/null | tr -d '\r')
    g=$(printf '%s' "$v" | sed -n 's/^n=//p')
    printf '      ㄷ 잣대의 scripts/ 둘: %s개 (기대 2)\n' "${g:-?}"
    if [ "${g:-x}" = "2" ]; then printf '  ✓ 그 둘이 이미지에 담겼다 (scripts/ 가 온전히 담겼다)\n'
    else printf '  ✗ 그 둘이 %s/2 개다 — scripts/ 가 온전히 안 담겼다\n' "${g:-?}"; IMGFAIL=1; fi
    # 🔴 A/S 는 drizzle 을 **안 담아야** 한다 — 볼륨이 붙는 자리다.
    #    🔴🔴 **69번(재고)은 정반대였다** — 거기는 .sql 이 이미지 안에 들어간다.
    v=$(dock "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
    printf '      /app/drizzle 안 .sql: %s개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)\n' "${v:-?}"
    if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ drizzle/ 이 비어 있다 (볼륨이 정본이다 — 🔵 이번 판은 거기 더할 것이 0건이다)\n'
    else printf '  ✗ drizzle/ 에 .sql 이 들었다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다\n'; IMGFAIL=1; fi
    # 🔴 **공용 스키마가 담겼는가** — 핀이 안 움직여도 **빈 서브모듈이 담길 수 있다**.
    v=$(dock "$TAG" -c 'd=/app/vendor/dss-core/src/schema; if [ -d "$d" ]; then echo "miss=0"; echo "n=$(ls -1 "$d" | wc -l)"; else echo "miss=1"; fi')
    v=$(printf '%s\n' "$v" | tr -d ' ')
    printf '%s\n' "$v" | sed 's/^/        /'
    c=$(printf '%s\n' "$v" | sed -n 's/^miss=//p'); g=$(printf '%s\n' "$v" | sed -n 's/^n=//p')
    if [ "${c:-1}" != "0" ]; then printf '  ✗ 이미지에 vendor/dss-core 의 스키마 폴더가 **없다** — Cannot find module 이 난다\n'; IMGFAIL=1
    elif [ "${g:-0}" -ge 1 ] 2>/dev/null; then printf '  ✓ 공용 스키마가 담겼다 (파일 %s개)\n' "$g"
    else printf '  ✗ 공용 스키마 폴더가 비었다 — **빈 서브모듈이 담겼다.** 올리지 마세요\n'; IMGFAIL=1; fi
    # 🔴 **넷을 묻는다** — 66번이 fault_tags 를 넷째로 더했다. 셋으로 줄이지 마라.
    v=$(dock "$TAG" -c 'for pair in "portal_approval_delegations /app/vendor/dss-core/src/schema/portal-approval-delegations.ts" "portal-approval-delegations /app/vendor/dss-core/src/schema/index.ts" "due_date_row_order /app/vendor/dss-core/src/schema/repair-case-approvals.ts" "fault_tags /app/vendor/dss-core/src/schema/repair-case-flowcharts.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1 $2"; fi; done')
    printf '%s\n' "$v" | sed 's/^/        /'
    g=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
    if [ "${g:-0}" = "4" ]; then
      printf '  ✓ **공용 스키마가 넷 다 담겼다** (표 + index 내보내기 + 지난 판들의 칸 둘)\n'
    else
      printf '  ✗ 넷 중 %s개만 있다 — **옛 공용 스키마가 담겼다.** 올리지 마세요\n' "${g:-0}"; IMGFAIL=1
      printf '%s\n' "      🔴 fault_tags 만 no 면 **서브모듈 핀이 66번 이전으로 돌아갔습니다**(3-ㄱ 을 보세요)."
    fi
    # 🔵 양식이 이미지에 안 들어갔는가 — 들어갔으면 도장과 계좌번호가 구워진 것이다.
    v=$(dock "$TAG" -c "ls /templates 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
    printf '      /templates 안 파일: %s개 (기대 0 — 양식은 볼륨으로 붙는다)\n' "${v:-?}"
    if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ 양식이 이미지에 안 들어갔다\n'
    else printf '  ✗ 이미지 안에 /templates 가 %s개 있다 — 도장·계좌번호가 구워졌다. 사람이 보세요\n' "${v:-?}"; IMGFAIL=1; fi
    v=$(dock "$TAG" -c "test -d /app/node_modules/drizzle-kit && echo yes || echo no")
    printf '      /app/node_modules/drizzle-kit: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ drizzle-kit 이 있다 (db:preflight 가 이것으로 돈다)\n'
    else printf '  ✗ drizzle-kit 이 없다 — **db:preflight 가 그 자리에서 죽는다.** 올리지 마세요\n'; IMGFAIL=1; fi
    npm_probe "$TAG" db:preflight
    npm_probe "$TAG" db:migrate
    printf '%s\n' "      🔵 db:migrate 는 **이번 판에 올릴 것이 0건**입니다 — 그래도 이 줄은"
    printf '%s\n' "         「그 명령이 import 까지 가는가」를 재는 자리라 그대로 둡니다."
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
  printf '%s\n' "   🔴 **이 판은 표식이 한글입니다** — 1-ㄷ 절이 ✗ 였다면 아래의 ✗ 는 전부"
  printf '%s\n' "      그 결과입니다. 이미지가 아니라 **검사를 먼저** 보세요."
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════
# ── 🔴 --verify : **이미 구운 둘을 다시 재기만 한다** ────────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **아무것도 굽지 않고 아무 파일도 만들지 않는다.** docker build 도
#      docker save 도 한 줄 없다 — 구운 지문(md5)이 바뀌면 안 되기 때문이다.
#   🔵 **이 판에서 특히 쓸 일이 많다** — 한글 표식이 ✗ 를 냈을 때 「검사 탓」을
#      고치고 다시 재야 하는데, 다시 구우면 받아 둔 TARS 값이 못 쓰게 된다.
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
    printf '\n%s\n' "════════ 70-deploy.sh 의 TARS 에 넣을 줄 (tar 에서 다시 쟀습니다) ════════"
    printf '%s' "$TARTABLE"
  fi
  printf '\n'
  if [ "$FAIL" = "0" ] && [ "$UNK" = "0" ] && [ "$VFAIL" = "0" ]; then
    printf '%s\n' "✅ --verify 전부 통과입니다. **아무것도 안 굽고 안 바꿨습니다.**"
    exit 0
  fi
  printf '%s\n' "🔴 ✗ 가 남아 있습니다 (앞 절 ✗ $FAIL · ? $UNK · 이미지 $VFAIL)"
  printf '%s\n' "   🔵 **검사 자신을 먼저 의심하세요** — 1-ㄴ(경로 번역)과 1-ㄷ(한글 경계)이"
  printf '%s\n' "      ✓ 였는지 보세요. 이 판의 앱 표식은 **한글 하나뿐**입니다."
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
printf '%s\n' "🔵 A/S dev 서버(3000)와 DB(5442)는 **켜 둔 채로 둬도 됩니다** — .dockerignore 가"
printf '%s\n' "   .next 를 막고(5-ㄴ), 이 파일은 호스트의 npm run build 를 한 번도 안 부릅니다."
BUILT=0; BFAIL=0; TARTABLE=""; BUILD_SEEN=0
while IFS= read -r row; do
  [ -n "$row" ] || continue
  KEY=$(field "$row" 1); TAG=$(field "$row" 2); TGT=$(field "$row" 3)
  PREVTAR=$(field "$row" 4); PREVSZ=$(field "$row" 5); STRICT=$(field "$row" 6)
  BUILD_SEEN=$((BUILD_SEEN+1))
  FILE=$(tar_name "$TAG")
  LOG="$OUT/build-$(printf '%s' "$TAG" | tr ':' '-').log"
  printf '\n── %s/%s  %s  (%s)\n' "$BUILD_SEEN" "$HOWMANY" "$TAG" "$AS_REPO"

  # 🔴 도구 이미지만 --target tools 다. 안 주면 **runner 가 구워지고** 그 안에는
  #    scripts/ 도 package.json 도 없어 오류 없이 쓸모없는 이미지가 된다.
  if [ "$TGT" = "-" ]; then
    printf '    스테이지: 기본(runner)\n'
    ( cd "$ASD" && docker build -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG" | tail -3
    RC=${PIPESTATUS[0]}
  else
    printf '    스테이지: --target %s\n' "$TGT"
    ( cd "$ASD" && docker build --target "$TGT" -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG" | tail -3
    RC=${PIPESTATUS[0]}
  fi
  if [ "${RC:-1}" = "0" ]; then
    printf '  ✓ 구웠다\n'
  else
    printf '  ✗ 굽기 실패 — %s 를 보세요\n' "$LOG"; BFAIL=$((BFAIL+1))
    printf '%s\n' "      🔵 **vendor 를 먼저 의심하세요** — vendor/dss-core 나 vendor/dss-ui 가"
    printf '%s\n' "         비어 있으면 Module not found 로 죽습니다(3-ㄷ 이 그것을 쟀습니다)."
    printf '%s\n' "         → git -C \"$ASD\" submodule update --init --recursive"
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
    printf '%s\n' "   🔵 **다만 이 판의 앱 표식은 한글입니다** — 위의 **가름 글**을 읽고"
    printf '%s\n' "      「검사 탓」이면 다시 굽지 말고 --verify 를 쓰세요(지문이 안 바뀝니다)."
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
  printf '%s\n' "       (이름|바이트|md5|Config 지문 — 70-deploy.sh 의 TARS 에 넣을 꼴입니다)"
  if [ -n "${TARTABLE:-}" ]; then printf '%s' "$TARTABLE"
  else printf '%s\n' "       (tar 가 한 줄도 없습니다 — 하나도 안 구워졌다는 뜻입니다.)"; fi
  printf '%s\n' "🔴🔴🔴 **실패를 고친 뒤 다시 구우면 지문이 바뀝니다** — 위 값을 그대로 쓰지"
  printf '%s\n' "       마시고, 다시 구운 뒤의 값을 쓰세요."
  printf '%s\n' "       🔵 **검사 쪽이 틀린 것이면 다시 굽지 말고 --verify 를 쓰세요** —"
  printf '%s\n' "          지문이 바뀌지 않습니다. 🔴 이 판은 **한글 표식** 때문에 그럴"
  printf '%s\n' "          확률이 지난 판들보다 높습니다."
  printf '\n%s\n' "🔴 실패가 있다. 위를 보세요."
  exit 1
fi

# 🔴 **굽고 나서 저장소가 더러워졌는가** — next build 가 tsconfig.json 을 다시 접는다.
printf '\n%s\n' "════════ 구운 뒤 저장소가 그대로인가 ════════"
printf '%s\n' "🔴 next build 가 tsconfig.json 을 다시 접은 적이 있습니다(눈에 안 띕니다)."
d=$(git -C "$ASD" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
if [ "${d:-1}" = "0" ]; then printf '  ✓ %s 미커밋 0줄\n' "$AS_NAME"
else
  printf '  ⚠️ %s 에 미커밋이 %s줄 생겼다 — **사람에게 알리세요**\n' "$AS_NAME" "$d"
  git -C "$ASD" status --porcelain=v1 2>/dev/null | head -6 | sed 's/^/        /'
fi
d=$(git -C "$COREDIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
if [ "${d:-1}" = "0" ]; then printf '  ✓ vendor/dss-core 미커밋 0줄\n'
else printf '  ⚠️ vendor/dss-core 에 미커밋이 %s줄 생겼다 — 사람에게 알리세요\n' "$d"; fi
d=$(git -C "$UIDIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
if [ "${d:-1}" = "0" ]; then printf '  ✓ vendor/dss-ui 미커밋 0줄\n'
else printf '  ⚠️ vendor/dss-ui 에 미커밋이 %s줄 생겼다 — 사람에게 알리세요\n' "$d"; fi
printf '%s\n' "  🔵 **tar 는 이미 구워졌습니다** — 되돌릴지 그대로 둘지는 사람이 정하세요."

# ══ 🔴 70-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
printf '\n%s\n' "════════ 70-deploy.sh 에 붙여 넣을 것 (TARS **두 줄**) ════════"
printf '%s' "$TARTABLE"
printf '%s\n' "  🔴 위 **두 줄**로 TARS 를 통째로 갈아 끼웁니다 — 지금은 **이름만 적혀 있고**"
printf '%s\n' "     **지문 자리가 비어 있습니다**(dss-as-6.1.tar||| 꼴)."
printf '%s\n' "  🔵 **묶음 값은 없습니다** — 이번 판은 마이그레이션이 0건이라 묶음을 안 만듭니다."
printf '%s\n' "  🔴 **NAS 에서 재서 채우지 마세요** — 자기가 잰 값으로 자기를 재면 영영 통과합니다."
printf '%s\n' "  🔵 그리고 위 **두 줄의 바이트를 README 에 적어 두세요** — 다음 판이 ①번"
printf '%s\n' "     크기 견주기에 그 값을 씁니다."
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
printf '%s\n' "       scp -O 70-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "       Get-FileHash -Algorithm MD5 70-deploy.sh"
printf '%s\n' "     🔴 **TARS 두 줄을 먼저 채운 뒤에 올리세요.**"
printf '%s\n' ""
printf '%s\n' "  ② (NAS) 지금 상태를 잰다 — 아직 아무것도 안 바뀐다"
printf '%s\n' "       sudo -i"
printf '%s\n' "       bash /volume1/dss/setup/70-deploy.sh            ← --check"
printf '%s\n' "       bash /volume1/dss/setup/70-deploy.sh --count    ← 올리기 전 수"
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
printf '%s\n' "     🔴 **묶음(as-migrations.tar.gz)은 보내지 마세요** — 이번 판은 마이그레이션이"
printf '%s\n' "        0건이라 보낼 것이 없습니다. 옛 폴더(_images-58~65)의 묶음을 보내면"
printf '%s\n' "        **엉뚱한 판이 볼륨을 덮습니다** — 특히 _images-62 의 것은 132장짜리라"
printf '%s\n' "        **수가 맞아 보이지만 지문이 다릅니다.**"
printf '%s\n' ""
printf '%s\n' "  ④ (NAS) **들여놓고 → 다시 재고 → 도구를 갈고 → 앱을 갈아 끼운다**"
printf '%s\n' "       bash /volume1/dss/setup/70-deploy.sh --preload"
printf '%s\n' "       bash /volume1/dss/setup/70-deploy.sh            ← 다시 --check"
printf '%s\n' "       bash /volume1/dss/setup/70-deploy.sh --tools    ← 도구 태그만 (🔵 DB 는 안 바뀐다)"
printf '%s\n' "       bash /volume1/dss/setup/70-deploy.sh --go       ⏱ 정지 창 (앱 **하나**)"
printf '%s\n' "       bash /volume1/dss/setup/70-deploy.sh --count    ← 올린 뒤 수"
printf '%s\n' "     🔴 **--migrate 모드는 없습니다** — 이번 판은 마이그레이션이 0건입니다."
printf '%s\n' "        (66번에는 있었습니다. 1건이라도 생기면 **거기서 되살리세요.**)"
printf '%s\n' ""
printf '%s\n' "🔴 **되돌리기**: --rollback 은 앱 하나를 옛 태그로 되돌립니다."
printf '%s\n' "   🔵 도구는 새 판 그대로 둡니다(39·41~68번과 같은 판단)."
printf '%s\n' "   🔵 **DB 는 되돌릴 것이 없습니다** — 이번 판은 한 글자도 안 바꿉니다."
printf '%s\n' "   🔴 **되돌리면 [부품요청]에서 비고로 다시 안 찾아집니다** — 찾는 일을"
printf '%s\n' "      **A/S 가 제 쪽에서** 하기 때문입니다(저쪽 재고관리는 한 줄도 안 바뀝니다)."
printf '%s\n' "────────────────────────────────────────────────────────────"
printf '\n%s\n' "🔴🔴🔴 **70-deploy.sh 에 넣을 값 (다시 찍습니다 — 여기만 복사해도 됩니다)**"
printf '%s\n' "── TARS 두 줄"
printf '%s' "$TARTABLE"
printf '%s\n' "🔴🔴🔴 위를 70-deploy.sh 에 **그대로** 적은 뒤 scp 하세요."
