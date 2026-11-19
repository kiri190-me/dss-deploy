#!/bin/bash
# dss-deploy/nas/setup/64-build.sh — 예순째 배포 · 이미지 굽기 (2026-11-19)
#
# 🔵 **배포 회차(예순째)와 파일 번호(64)가 어긋나는 것은 이 저장소에서 원래
#    그렇다** — 61번이 쉰일곱째, 62번이 쉰여덟째, 63번이 쉰아홉째였다.
#    (56번은 2026-11-11 의 **양식 전용**이라 회차를 안 먹었다.)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · PowerShell 에서 Git Bash 를 부른다) ──────────
#     cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#     & "C:\Program Files\Git\bin\bash.exe" ./64-build.sh --check
#     & "C:\Program Files\Git\bin\bash.exe" ./64-build.sh --go
#
#   🔴 **bash.exe 만 치면 WSL 이 잡힌다**(2026-11-04 에 걸렸다). WSL 에서 돌면
#      도커가 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 내어 ✗ 가 흩어져
#      난다. 단서는 로그의 뿌리 경로가 **/mnt/c/…** 인 것이다 — 0절이 값으로 잰다.
#   🔴 **스크립트에 건네는 경로에는 역슬래시를 쓰지 않는다.** 역슬래시를 주면
#      bash 가 그것을 먹어 "C:Users희만Desktop…" 이 되어 No such file 이 난다.
#
#   둘째 인자로 산출물을 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-60):
#     & "C:\Program Files\Git\bin\bash.exe" ./64-build.sh --go "/d/배포본/_images-60"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다.
#      이 파일을 쓴 쪽은 **한 번도 굽지 않았다** — 재기만 했다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 올리는 것 — 한 줄 요약**
# ══════════════════════════════════════════════════════════════════════
#   [내자 정리]의 **상태 거르개가 셋에서 넷**이 된다. NO_ORDER_DATE 의 이름표가
#   「발주일 미정」 → **「발주 대기」**로 바뀌고, 새 값 **ORDER_ISSUED**(=
#   「발주 완료」 · orderIssuedDate !== null)가 생긴다.
#   🔵 **판정은 한 줄도 안 바뀌었고 DB 는 한 글자도 안 건드린다** — 읽는 쪽 기능이다.
#   🔴 **필터 이름만 바꿨다.** NO_ORDER_DATE_LABEL(= "발주일 미정")은 배지 ·
#      주황 안내 · 기타건 칸 · 내자 상세 **넷이 그대로** 쓴다. **같은 줄을 화면이
#      두 말로 부르는 것이 2026-11-19 사용자 결정이다** — 고장이 아니다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **63번의 전제 중 이번에 깨지는 것 여섯 — 하나씩 재서 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 **scripts/ 가 한 장도 안 바뀌었다.**
#      63번은 바뀐 10장 중 **scripts/ 가 둘**이었고 그 둘이 시험 등록 목록
#      (scripts/test-lists/*.txt)이었다. [실측 2026-11-19] 이번 범위의
#      scripts/ 변경은 **0줄**이다 — CH_SCRIPTS 기대값을 **0** 으로 내렸다.
#      🔵 그래도 **도구는 굽는다**(③). 까닭이 scripts/ 가 바뀐 것이 아니었다.
#
#   ② 🔴 **새 파일이 0장이다 — 63번 5-ㅇ 을 그대로 두면 ✗ 가 난다.**
#      63번의 5-ㅇ 은 **「새 시험 3개가 목록에 등록돼 있다」**를 쟀다.
#      [실측] 이번 범위의 새 파일은 **0장**이라 그 잣대는 **표본이 비어서
#      공짜로 ✗** 가 된다.
#      🔴 **빼지 않고 뜻을 뒤집었다**(5-ㅇ):
#        · 새 시험 파일이 **0개**인가(*.test.ts(x) 중 추가된 것)
#        · 🔴 **목록 줄 수가 줄지 않았는가** — 기준판 합계를 git 에서 **그 자리에서
#          다시 세어** 지금과 맞댄다(적어 둔 값 4050). 줄었으면 **누가 등록을
#          지운 것**이고, 그것은 오류 없이 조용히 산다.
#        · 🔴 **이번에 바뀐 시험 둘이 아직 목록에 적혀 있는가** — 이것이 이 절의
#          **빈 표본 방지**다. 「0개가 등록돼 있다」만 재면 아무것도 안 재는 ✓ 다.
#        · 목록 파일 **넷**이 다 있는가(63번 그대로)
#
#   ③ 🔴 **굽는 까닭 ㄷ(도구의 import 닫힘)은 이번에도 걸린다 — 수치만 갈았다.**
#      [실측 2026-11-19] scripts/lib/ 의 **두 파일**이 바뀐 모듈을 진짜 import 로
#      부른다:
#        scripts/lib/delivered-date-sync-survey.ts:1
#        scripts/lib/requested-due-date-sync-survey.ts:1
#          import { foldBlankToNull } from "../../src/lib/domain/domestic-order-list";
#      그 domestic-order-list.ts 가 이번에 **+54/−22** 바뀌었다(63번은 +301 이었다).
#      🔴 63번 5-ㄹ 의 ㄴ 잣대는 **「바뀐 10장 중 10장」**이었다 — 이번엔 **4장 중
#         4장**이다. 적어 둔 값을 **전부 다시 셌다.**
#      🔴 안 구우면 야간 조사 도구 둘이 **옛 몸통**으로 계속 돈다. 오류 없이 조용히.
#
#   ④ 🔴🔴 **표식을 갈아야 한다 — 그리고 지시받은 표식이 실제로는 안 갈랐다.**
#      63번의 기능 표식 domestic-order-status-filter 는 **쉰아홉째가 이미 올린
#      글자**라 이번 판에서는 「있다」가 **아무것도 안 가른다**(기준 3 → 지금 3).
#      그래서 그것을 **뒷걸음 표식**으로 내리고 기능 표식을 새로 골랐다.
#
#      🔴 **처음 고른 ORDER_ISSUED(맨 글자)는 틀렸다 — 재 보고 알았다.**
#        [실측 2026-11-19] git grep -lF ORDER_ISSUED 48011ab4 -- src → **2파일**.
#        쉰아홉째가 올린 상수 **ORDER_ISSUED_SORT_HINT**(발주발행일 세모의 설명
#        글)의 **앞부분**에 걸린다. 그대로 썼으면 「기능 표식이 기준판에도 있다」로
#        **✗** 가 났고, 그 ✗ 는 **진짜 결함처럼** 보였을 것이다.
#      🔴 그래서 **따옴표를 포함한 리터럴**로 좁혔다:
#           APPMARK = "ORDER_ISSUED"   (따옴표가 글자의 일부다)
#           [실측] 기준 **0파일** → 지금 **2파일**
#        🔵 이 꼴을 고른 까닭이 하나 더 있다 — **번들에 실제로 들어가는 꼴이
#           이것**이다. 값 배열(DOMESTIC_ORDER_STATUS_FILTER_VALUES)과 switch 의
#           case 가 둘 다 **따옴표째** 번들에 남는다. 상수 이름은 minify 가 지운다.
#        🔴 다만 **번들이 홑따옴표로 적을 가능성**은 남는다(SWC 는 쌍따옴표를 쓴다).
#           그래서 bundle_mark 가 **맨 글자 ORDER_ISSUED 를 곁들여 찍는다** —
#           판정에는 안 쓰고, ✗ 가 났을 때 「따옴표만 안 맞는 것」을 바로 가르려고.
#      🔴 **뒷걸음 표식은 셋이다**(63번은 둘이었다):
#           domestic-order-status-filter  쉰아홉째 · 기준 3 → 지금 3
#           portal_approval_delegations   쉰여덟째 · 기준 26 → 지금 26
#           domesticOrders.view           쉰여섯째 · 기준 17 → 지금 17
#      🔴 **마지막 커밋 표식**(도구 이미지용)도 갈았다. 63번의
#         DOMESTIC_ORDER_UNASSIGNED_CUSTOMER_VALUE 는 **이번에 안 바뀐 글자**라
#         이 판을 안 가른다. 대신 **파일을 좁혀** 맨 글자를 쓴다:
#           TOOLMARK = ORDER_ISSUED  in src/lib/domain/domestic-order-list.ts
#           [실측] 그 **파일 안에서는** 기준 **0줄** → 지금 **4줄**
#         🔵 ORDER_ISSUED_SORT_HINT 는 **그 파일에 없다**(DomesticOrderListScreen.tsx
#            와 그 화면 시험에만 있다) — 파일을 좁히는 것만으로 충돌이 사라진다.
#            🔴 **0줄이었는지도 이 파일이 git 에서 직접 센다**(5-ㅅ) — 적어 둔 값을
#            믿지 않는다. 바로 그 믿음이 ④ 의 첫 표식을 틀리게 했다.
#
#   ⑤ 🔴 **tar 크기 견주기 기준값이 바뀐다 — 둘 다 strict.**
#      지난 판: dss-as-5.5.tar **136025088** · dss-as-tools-22.tar **226528768**
#      [실측] 이번 범위의 package.json · package-lock.json · tsconfig.json ·
#      drizzle.config.ts 변경이 **0장**이다 — 라이브러리가 한 개도 안 늘었다.
#      그래서 **둘 다 strict**(25% 넘으면 ✗)로 둔다.
#
#   ⑥ 🔴 **「안 걸린다」도 값으로 잰다.** npm 명령 수 **39 → 39**.
#      [실측] package.json diff 0줄. 🔵 63번이 그렇게 했고, 그 규율이 없으면
#      다음 판이 「안 늘었다」는 **거짓**을 근거로 「안 구워도 된다」를 꺼낸다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **63번에서 그대로 살린 것 — 한 번 빼면 다시 넣는 사람이 없다**
# ══════════════════════════════════════════════════════════════════════
#   · 0절 Git Bash 판정(/mnt/ 로 시작하면 ✗)        → 참. 그대로.
#   · 🔴 **1-ㄴ 경로 번역 검사**(MSYS_NO_PATHCONV)   → 참. **맨 앞에 둔다.**
#     이것이 없어서 쉰여덟째에 **가짜 ✗ 일곱**을 헤맸다.
#   · 2절 「미푸시 0 과 **안 받은 것도 센다**」 → 참. [실측] main == origin/main ·
#     기준 48011ab4..main 커밋 **1** · 미커밋 0줄.
#   · 「굽기 전에 서브모듈 작업본이 체크아웃돼 있는가」 → 🔴 **참이고 이번에도
#     중요하다.** 핀이 안 움직이니 **핀만 보면 빈 서브모듈도 통과한다**(3-ㄷ).
#   · 4절 「마이그레이션 0건 — 바뀌지 않아야 한다」 → 참. **어제와 같다.**
#   · tar 크기를 **두 번** 견주기(지난 판 tar 와 · 그 이미지 자신과) → 참.
#   · 「grep -c 는 0 일 때 종료 코드 1」·「tar | grep -q 는 SIGPIPE」·
#     「bash -n 이 못 잡는 둘」·「8진수로 읽히는 0131」 → 전부 참. 같은 규율로 썼다.
#   · 함수 정의에 붙인 **</dev/null** · 고리마다 **「몇 개를 봤는가」 관문** → 참.
#   · 「✗ 가 나도 지문 줄만은 찍는다」 → 참. **세 자리**에서 찍는다.
#   · 「docker build 는 dev 서버를 안 내려도 된다(.dockerignore 가 .next 를 막는다)」
#     → 참. [실측] .dockerignore 의 ^\.next 가 **1줄**. 🔵 **3000번과 5442번이
#     떠 있는 것이 정상이다** — 7-ㄴ 이 값으로 찍기만 하고 판정에 안 쓴다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **63번에서 가져온 결함 고침 둘 — 빠뜨리면 같은 일이 또 난다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 **stdin 을 빨아들이는 명령을 고리 안에서 부르면 고리가 한 바퀴만 돈다.**
#      [실측 2026-11-18 · NAS] while read … done <<END 안에서 docker exec **-i** 를
#      부르면 그 명령이 here 문서의 남은 줄을 **남김없이** 빨아들여 다음 read 가
#      EOF 를 받는다 — 네 집 중 **한 집만** 재고 끝났다.
#      🔴 처방 둘을 **함께**: **-i 를 떼고**, **함수 정의에 </dev/null 을 붙인다.**
#      🔴 그리고 **「몇 개를 봤는가」를 고리마다 세어 끝에서 단언한다.** 이 파일의
#         고리는 **전부** SEEN 변수를 들고 있다.
#   ② 🔴 **Git Bash 가 docker.exe 에 넘기는 「/ 로 시작하고 빈칸 없는」 인자를
#      윈도우 경로로 번역한다.** [실측 2026-11-18] 그것 하나로 **가짜 ✗ 일곱**이 났다.
#      🔴 처방 셋을 **다 쓴다**: dockr() 로 **docker 를 부를 때만** 끄고 ·
#         **그것이 정말 꺼졌는지 값으로 재고**(1-ㄴ) · 파일 경로는 **상대로 넘긴다.**
#      🔴 **전역 export 로 끄면 git 이 깨진다 — 실제로 깨뜨려 봤다**(✗ 스물한 개).
#
# ── 🔴 **--verify 모드** — 63번이 만든 것을 그대로 가져왔다 ───────────
#   이미 구운 둘을 **다시 굽지 않고 안만 잰다.** 가짜 ✗ 를 고칠 때 **구운 지문이
#   바뀌면 안 되기** 때문에 필요하다 — 다시 구우면 받아 둔 TARS 값이 못 쓰게 된다.
#
# ── 이번에 굽는 것 — **이미지 둘** ───────────────────────────────────
#     ① A/S 앱   dss-as:5.5       → dss-as:5.6         커밋 1
#     ② A/S 도구 dss-as-tools:22  → dss-as-tools:23    🔴 --target tools
#   🔴 **묶음은 없다**(마이그레이션 0건). 🔴 **나머지 아홉 집은 안 굽는다** —
#      이번 범위에 한 줄도 없고, 쉰아홉째가 올린 그대로다.
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
# ── 🔴 이 환경의 함정 (36~63-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싼다. 저장소 자리를 적어
#      넣지 않고 **이 파일의 자리에서 계산한다**(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:/… 를 /c/… 로 바꾸고,
#      docker save 는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를 막는다).
#   ④ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다.** 이 파일의 표식은 **전부
#      ASCII** 다 — 8진 이스케이프가 한 군데도 없다.
#   ⑤ 🔵 **이번 범위에는 괄호가 든 경로가 0개다**[실측 — 바뀐 4장 중 0장].
#      🔴 그래도 목록을 넘기는 길은 **here 문서 + while read** 와 **grep -Fx** 로만
#         썼고, 컨테이너 안에서도 set -f 로 글롭을 끈다. 「이번엔 0이니 괜찮다」로
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
#   ⑩ 🔴 **bash 의 $(( )) 는 0 으로 시작하는 수를 8진수로 읽는다** — 0131 을 셈에
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
#   🔴 **전역 export 로 끄지 않는다** — git 이 깨진다(머리말 ②). docker 를 부르는
#      자리에만 붙인다. 같은 셸에서 git 은 그대로다.
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
#    🔴 **이번 판이 그 실물이다** — 지시받은 기능 표식이 실제로는 안 갈랐다(머리말 ④).
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

# tar 안 manifest.json 의 Config 지문 (39~63-build.sh 의 것을 글자 그대로)
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
#   🔴 기준 SHA 의 출처: 쉰아홉째(63번)가 올린 커밋이다.
#      [실측 2026-11-19] 그 SHA 에서 세어 커밋 **1** 이었다.
AS_REPO=RF_Service_System
AS_NAME=A/S관리
AS_BASE=48011ab4
AS_COMMITS_WANT=1
AS_PORT=3000
# 🔵 DB 는 dss-pg-app(호스트 5442)이 개발 PC 에 떠 있다. 🔴 **끄지 않는다** —
#    이 파일은 DB 에 한 번도 안 붙는다(개발 PC 에서는 운영 DB 를 못 본다).
AS_DB_PORT=5442

# ── 굽는 **둘** ───────────────────────────────────────────────────────
#   열쇠|새 태그|타깃(-=기본 runner)|지난판 tar 이름|지난판 tar 바이트|엄함
#   🔴 지난판 바이트의 출처 — **63-deploy.sh 의 TARS 에 박힌 값 그대로다**:
#      dss-as-5.5.tar        136025088
#      dss-as-tools-22.tar   226528768
#   🔵 엄함: strict = 25% 넘으면 ✗ · loose = 25% ⚠️ · 60% 넘으면 ✗
#   🔴 **둘 다 strict 다** — [실측] 의존성 파일이 **한 장도 안 바뀌었다**(머리말 ⑤).
IMAGES='
as|dss-as:5.6|-|dss-as-5.5.tar|136025088|strict
astools|dss-as-tools:23|tools|dss-as-tools-22.tar|226528768|strict
'
HOWMANY=2

# ── 🔴 마이그레이션 — **0건이다** (어제와 같다) ──────────────────────
#   저장소가 들고 있어야 하는 수 · 목록 수 · 이번 범위의 drizzle 변경 · 그 다음 번호
AS_SQL_WANT=131
AS_DRIZZLE_DIFF_WANT=0
AS_NEXT_MIG=0131
# 🔵 **운영이 지금 들고 있어야 하는 수** — 개발 PC 에서는 못 잰다. 64-deploy.sh 가
#    DB 에 물어 확인하고, **바뀌었으면 거기서 멈춘다.** 여기서는 찍어 두기만 한다.
PROD_MIGS_NOTE='A/S 131 · 재고 28 · 휴가 5 · 포털 11 · 계측기 3'

# ══ 🔴 서브모듈 — **안 움직인다** ═════════════════════════════════════
#   🔴 쉰아홉째가 올린 핀 그대로여야 한다. 움직였으면 이 배포본의 전제가 깨진 것이다.
AS_CORE_PIN=b79e5ab894389a6fe433d7214d9c4496294dabee
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425
AS_CORE_COMMITS_WANT=0
# 🔴 **핀만 보면 빈 서브모듈도 통과한다** — 쉰여덟째가 올린 것이 거기 있는지 함께 본다.
AS_CORE_KEEP_FILE=src/schema/portal-approval-delegations.ts
AS_CORE_KEEP_TABLE=portal_approval_delegations
AS_CORE_KEEP_EXPORT=portal-approval-delegations

# ══ 🔴 바뀐 파일 수 — [실측 2026-11-19] ═══════════════════════════════
#   전체|src/|scripts/|drizzle/|vendor+.gitmodules|새 파일|지운 파일|괄호 든 경로
#   🔴 **scripts·drizzle·vendor·새 파일·지운 파일·괄호가 전부 0 이다**(머리말 ①②).
#      63번은 scripts 2 · 새 파일 3 이었다 — 그 둘이 이번에 뒤집힌 자리다.
CH_ALL=4
CH_SRC=4
CH_SCRIPTS=0
CH_DRIZZLE=0
CH_VENDOR=0
CH_NEW=0
CH_DEL=0
CH_PAREN=0
#   🔵 바뀐 넷 중 **둘이 시험 파일**이다 — 5-ㅇ 의 표본이 거기서 나온다.
CH_TESTS=2

# ══ 🔴 npm 명령 수 — [실측 2026-11-19] ════════════════════════════════
NPM_WAS=39
NPM_NOW=39

# ══ 🔴 **도구를 굽는 까닭** — 값으로 가린다(머리말 ③) ═════════════════
#   ㄴ) tools 스테이지가 담는 것 중 바뀐 파일 수. 🔴 4 중 **4**.
TOOLS_PAYLOAD_RE='^(src/|scripts/|vendor/|package\.json|tsconfig\.json|drizzle\.config\.ts)'
TOOLS_PAYLOAD_WANT=4
#   ㄷ) 🔴 **도구의 import 닫힘** — scripts/ 가 바뀐 모듈을 import 로 부르는 자리.
#      파일|그 파일이 import 하는 바뀐 모듈
TOOL_IMPORTERS='
scripts/lib/delivered-date-sync-survey.ts|../../src/lib/domain/domestic-order-list
scripts/lib/requested-due-date-sync-survey.ts|../../src/lib/domain/domestic-order-list
'
TOOL_IMPORTERS_WANT=2
TOOL_IMPORT_TARGET=src/lib/domain/domestic-order-list.ts

# ══ 🔴 Dockerfile 이 담는 길 — **A/S 넷** ═════════════════════════════
#   정규식|있어야 하나(yes/no)|사람이 읽을 말
#   🔴 **no 줄이 뜻하는 것이 반대다.** A/S 의 「drizzle 을 안 담는다」는 **볼륨이
#      정본**이라는 뜻이다 — 이번 판은 거기에 더할 것이 없다(0건).
COPYRULES='
^COPY .*scripts \./scripts|yes|🔴 A/S tools 가 scripts/ 를 담는다 — **굽는 까닭 ㄷ 가 여기 있다**
^COPY .*src \./src|yes|🔴 A/S tools 가 src/ 를 담는다 — 바뀐 4장이 전부 여기다
^COPY .*vendor \./vendor|yes|A/S tools 가 vendor/ 를 담는다 (이번 판은 vendor 가 안 바뀐다)
^COPY .*drizzle \./drizzle|no|🔵 A/S tools 는 drizzle/ 을 **안 담는다** — 볼륨이 정본이고 이번엔 더할 것이 0건이다
'
COPYRULES_WANT=4

# ══ 🔴 앱 번들에서 쓸 표식 — **전부 리터럴 · 전부 ASCII** ═════════════
#   🔴 **따옴표가 글자의 일부다**(머리말 ④). 맨 글자로 재면 기준판의
#      ORDER_ISSUED_SORT_HINT 에 걸려 **아무것도 안 가른다.**
APPMARK='"ORDER_ISSUED"'
APPMARK_NOTE='기준 0 → 지금 2파일 (상태 값 배열과 switch 의 case 에 든 리터럴)'
# 🔵 판정에 **안 쓰는** 곁들이 값 — ✗ 가 났을 때 「따옴표만 안 맞는 것」을 가른다.
APPMARK_DIAG=ORDER_ISSUED
KEEPMARK1=domestic-order-status-filter
KEEPMARK1_NOTE='쉰아홉째가 올린 DOM id — 기준 3 → 지금 3파일'
KEEPMARK2=portal_approval_delegations
KEEPMARK2_NOTE='쉰여덟째가 올린 글자 — 기준 26 → 지금 26파일'
KEEPMARK3=domesticOrders.view
KEEPMARK3_NOTE='쉰여섯째가 올린 권한 열쇠 — 기준 17 → 지금 17파일'
MARKS_WANT=4

# ══ 🔴 도구 이미지에서 쓸 **마지막 커밋 표식** ════════════════════════
#   🔴 **파일을 좁혀서** 맨 글자를 쓴다 — 그 파일에 SORT_HINT 가 없다(머리말 ④).
TOOLMARK=ORDER_ISSUED
TOOLMARK_FILE=src/lib/domain/domestic-order-list.ts
TOOLMARK_LINES_WANT=4
TOOLMARK_LINES_WAS=0

# ══ 🔴 public/ 기대값 ═════════════════════════════════════════════════
#   🔵 A/S 는 yes 이고 안에 파일이 **9개**다[실측 2026-11-18 · 구운 것을 열어 셌다].
AS_PUBLIC_WANT=yes
AS_PUBLIC_N=9

# ══ 🔴 **이번 판의 바뀐 파일 넷** — 도구 이미지가 담고 있어야 한다 ════
#   🔴 **바뀐 목록과 글자 그대로 같다**(4장). 시험 파일도 뺀 것이 없다 —
#      도구 이미지는 src/ 를 통째로 담으므로 넷이 다 들어간다.
#   🔴 **없는 경로 하나를 함께 묻는다** — 「무조건 yes」인 검사인지 가른다.
PROBE_MISS=src/__dss_probe_no_such_file__.ts
AS_CHANGED_FILES='
src/components/domestic-orders/DomesticOrderListScreen.tsx
src/components/domestic-orders/domestic-order-list-filters-screen.test.ts
src/lib/domain/domestic-order-list-filters.test.ts
src/lib/domain/domestic-order-list.ts
'
AS_CHANGED_FILES_WANT=4

# ══ 🔴 시험 등록 — A/S 는 **목록 파일** 방식이다 ══════════════════════
#   🔴 적어야 돈다. 빠뜨리면 **오류 없이 조용히 안 돈다.**
#   🔴 그 파일들은 **CRLF** 라 \r 를 걷고 -Fx 로 줄 전체를 맞댄다.
#   🔴 **이번 판은 새 시험이 0개다**(머리말 ②) — 63번의 「새 시험 3개가 등록돼
#      있다」를 그대로 두면 ✗ 다. 뜻을 뒤집어 **「줄 수가 안 줄었다」**와
#      **「바뀐 시험 둘이 아직 적혀 있다」**를 잰다.
AS_TESTLIST_MIN_LINES=3900
AS_TESTLIST_LINES_WANT=4050
AS_NEW_TESTS_WANT=0
AS_TOUCHED_TESTS='
src/components/domestic-orders/domestic-order-list-filters-screen.test.ts
src/lib/domain/domestic-order-list-filters.test.ts
'
AS_TOUCHED_TESTS_WANT=2
AS_TESTLIST_FILES='
scripts/test-lists/unit.txt
scripts/test-lists/components.txt
scripts/test-lists/db.txt
scripts/test-lists/db-safety.txt
'
AS_TESTLIST_FILES_WANT=4

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-60"; fi

case "$MODE" in
  --check|--go|--verify) ;;
  *) printf '쓰는 법: %s [--check|--go|--verify] [산출물폴더]\n' "$0"; exit 2 ;;
esac

ASD="$DEV/$AS_REPO"
COREDIR="$ASD/vendor/dss-core"
UIDIR="$ASD/vendor/dss-ui"

printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' " 64-build.sh — 예순째 배포 · 이미지 굽기 ($MODE)"
printf '%s\n' "   저장소 뿌리 : $DEV"
printf '%s\n' "   산출물 자리 : $OUT"
printf '%s\n' "   굽는 것     : 이미지 $HOWMANY (A/S 앱 · A/S 도구) · 🔴 **묶음 없음**"
printf '%s\n' "   마이그레이션: 🔴 **0건** — 「바뀌지 않아야 한다」를 잰다"
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
check_mark() { # 1 글자 2 갈래(feature|keep) 3 사람이 읽을 말
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
        say "      🔵 **이번 판이 바로 그 실물입니다** — 맨 글자 ORDER_ISSUED 는"
        say "         기준판의 ORDER_ISSUED_SORT_HINT 에 걸려 2파일이었습니다."
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
    say "       & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./64-build.sh $MODE"
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
    say "         & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./64-build.sh $MODE"
    say "      → 그래도 안 꺼지면 이 파일 맨 위의 dockr() 줄을 보세요."
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
step "3. 🔴 서브모듈 — **이번 판도 안 움직인다.** 그것을 값으로 잰다"
say "🔵 vendor/dss-ui 는 이것으로 **아홉째 판 연속** 안 움직입니다."
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
check_pin vendor/dss-core "$AS_CORE_PIN" "쉰여덟째가 올린 핀 (쉰아홉째도 안 건드렸다)"
check_pin vendor/dss-ui   "$UI_PIN"      "🔵 **아홉째 판 연속** 안 움직였다"
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
else
  bad "vendor/ 변경이 ${vn:-?}줄 있다 — $CH_VENDOR 을 기대했다. **서브모듈이 움직였다**"
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
say "🔵 **어제(63번)와 같습니다** — 이 절은 글자 그대로 가져왔습니다. 뺄 까닭이"
say "   생기지 않았습니다: 빼면 「운영 DB 가 지금 몇 건인지」를 아무도 안 보게 되고,"
say "   그 수가 어긋나면 **이 배포와 무관한 다른 사고**인데 끝까지 모릅니다."
MIGCK_SEEN=0
s=$(ls -1 "$ASD/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
j=$(grep -o '"idx"' "$ASD/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
MIGCK_SEEN=$((MIGCK_SEEN+1))
say ".sql ${s:-?}장 · meta/_journal.json 의 idx ${j:-?}개 (기대 $AS_SQL_WANT · $AS_SQL_WANT)"
if [ "${s:-x}" = "$AS_SQL_WANT" ] && [ "${j:-x}" = "$AS_SQL_WANT" ]; then
  ok "저장소 drizzle/ 이 ${AS_SQL_WANT}장이고 목록도 ${AS_SQL_WANT}개다 (쉰여덟째가 올린 수 그대로)"
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
  say "      🔵 그래서 64-deploy.sh 에는 **--migrate 모드가 없습니다.**"
else
  bad "drizzle/ 변경이 ${dn:-?}줄 있다 — 0 을 기대했다"
  say "      🔴 **이 배포본에는 마이그레이션을 올리는 절이 없습니다.** 멈추고 알리세요."
  git -C "$ASD" diff --name-only "$AS_BASE..main" -- drizzle 2>/dev/null | sed 's/^/        /'
fi
MIGCK_SEEN=$((MIGCK_SEEN+1))
nx=$(ls -1 "$ASD/drizzle/${AS_NEXT_MIG}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
say "$AS_NEXT_MIG 이 생겼는가: ${nx:-?}개 (기대 0)"
if [ "${nx:-1}" = "0" ]; then
  ok "$AS_NEXT_MIG 이 없다 (마지막이 0130 그대로 — 적용 대기 **0건**)"
else
  bad "$AS_NEXT_MIG 이 **생겼다** — 이 배포본은 0130 까지를 전제로 쓰였다. 멈추고 알릴 것"
fi
[ "$MIGCK_SEEN" = "3" ] && ok "마이그레이션 검사 셋을 다 돌았다 (표본이 비지 않았다)" \
  || bad "마이그레이션 검사를 ${MIGCK_SEEN}개만 돌았다 — 3개를 기대했다"
say ""
say "🔵 **운영이 지금 들고 있어야 하는 수** — $PROD_MIGS_NOTE"
say "   🔴 **개발 PC 에서는 못 잽니다.** 64-deploy.sh --check 가 DB 에 물어 확인하고,"
say "      어긋나면 **거기서 멈춥니다.** 어긋나면 그것은 **이 배포와 무관한 다른 사고**입니다."
say "   🔵 A/S 는 마이그레이션이 **볼륨**에서 돕니다(/volume1/dss/as-migrations) —"
say "      이번에도 보낼 묶음이 없지만 **볼륨이 131장 그대로인지**는 거기서 잽니다."

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
say "🔴 63번은 이 자리가 **10 / 10** 이었습니다 — 베껴 쓰면 틀렸을 자리라 다시 셌습니다."
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
say "ㄷ) 🔴 **도구의 import 닫힘** — scripts/ 가 바뀐 모듈을 진짜 import 로 부르는가"
say "🔴 **여기가 이번 판에서 도구를 굽는 결정적인 까닭입니다.** 🔵 이번 범위는"
say "   scripts/ 가 **한 장도 안 바뀌었는데도**(머리말 ①) 걸립니다 — 바뀐 것은"
say "   그 둘이 **import 하는 쪽**입니다. 「scripts 가 0장이니 도구는 그대로다」가"
say "   틀린 자리입니다."
IMP_SEEN=0; IMP_OK=0
tn=$(printf '%s\n' "$LIST" | grep -cFx "$TOOL_IMPORT_TARGET" || true)
say "바뀐 목록에 $TOOL_IMPORT_TARGET 이 ${tn:-?}줄 (기대 1)"
[ "${tn:-x}" = "1" ] && ok "import 로 불리는 그 모듈이 **이번에 바뀌었다** (+54/−22)" \
  || bad "그 모듈이 바뀐 목록에 ${tn:-?}줄이다 — 1 을 기대했다. 이 절의 전제가 틀렸다"
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
  ok "🔴 **ㄷ 잣대가 걸린다** — 도구 스크립트 ${IMP_OK}장의 import 닫힘 안이 바뀌었다"
  say "      🔴 **안 구우면 그 둘이 옛 몸통으로 계속 돕니다.** 오류 없이 조용히 삽니다."
else
  bad "본 것 ${IMP_SEEN} · 부르는 것 ${IMP_OK} 다 — ${TOOL_IMPORTERS_WANT} 을 기대했다"
  doubt
fi
say ""
say "ㄹ) 공용 스키마(vendor/*)가 움직였나 — 3-ㄴ 에서 **0줄**로 쟀다 → **안 걸린다**"
say ""
say "🔴 **결론: 도구 이미지를 굽는다.** ㄴ 과 ㄷ 가 걸렸다(ㄱ·ㄹ 은 안 걸렸다)."
say "   🔵 반대 방향의 사고도 이 저장소에 적혀 있습니다 — 「마이그레이션 0건이니"
say "      도구는 안 굽는다」가 틀려 비상구 둘을 못 올린 적이 있고, 이튿날에는"
say "      거꾸로 「명령이 늘어난 것」을 놓쳐 Missing script 가 났습니다."

# 5-ㅁ. 바뀐 파일 수
say ""
say "── 5-ㅁ. 바뀐 파일 수 — 🔴 **scripts·drizzle·vendor·새·지움·괄호가 다 0 이어야 한다**"
src=$(printf '%s\n' "$LIST" | grep -c '^src/' || true)
scr=$(printf '%s\n' "$LIST" | grep -c '^scripts/' || true)
drz=$(printf '%s\n' "$LIST" | grep -c '^drizzle/' || true)
ven=$(printf '%s\n' "$LIST" | grep -cE '^(vendor/|\.gitmodules)' || true)
par=$(printf '%s\n' "$LIST" | grep -cF '(' || true)
new=$(git -C "$ASD" diff --diff-filter=A --name-only "$AS_BASE..main" 2>/dev/null | grep -c . || true)
del=$(git -C "$ASD" diff --diff-filter=D --name-only "$AS_BASE..main" 2>/dev/null | grep -c . || true)
printf '      전체 %-4s src %-4s scripts %-3s drizzle %-2s vendor %-2s 새 %-3s 지움 %-2s 괄호 %s\n' \
  "${all:-?}" "${src:-?}" "${scr:-?}" "${drz:-?}" "${ven:-?}" "${new:-?}" "${del:-?}" "${par:-?}"
printf '      (적어 둔 값) %-4s     %-4s         %-3s         %-2s        %-2s    %-3s      %-2s      %s\n' \
  "$CH_ALL" "$CH_SRC" "$CH_SCRIPTS" "$CH_DRIZZLE" "$CH_VENDOR" "$CH_NEW" "$CH_DEL" "$CH_PAREN"
if [ "${all:-x}" = "$CH_ALL" ] && [ "${src:-x}" = "$CH_SRC" ] && [ "${scr:-x}" = "$CH_SCRIPTS" ] \
   && [ "${drz:-x}" = "$CH_DRIZZLE" ] && [ "${ven:-x}" = "$CH_VENDOR" ] && [ "${new:-x}" = "$CH_NEW" ] \
   && [ "${par:-x}" = "$CH_PAREN" ]; then
  ok "바뀐 파일 수가 적어 둔 것과 전부 같다"
else
  note "바뀐 파일 수가 적어 둔 것과 다르다 — **사람이 보세요**"
  say "      🔵 커밋이 하나 더 밀렸으면 여기가 먼저 어긋납니다(2절의 ⚠️ 와 짝입니다)."
fi
if [ "${del:-1}" = "$CH_DEL" ]; then ok "지운 파일 ${CH_DEL}장"
else bad "🔴 파일을 ${del}장 **지웠다** — 0 을 기대했다. 멈추고 알릴 것"; fi
say "🔵 **이번 범위에는 괄호가 든 경로가 0개입니다.**"
say "   🔴 그래도 목록을 넘기는 길은 here 문서 + grep -Fx 로만 썼습니다 —"
say "      「이번엔 0이니 괜찮다」로 길을 바꾸면 다음 판이 그 함정을 밟습니다."

# 5-ㅂ. 🔴 표식 — 소스에서 먼저 센다
say ""
say "── 5-ㅂ. 🔴 표식 — **소스에서 먼저 센다** (기능 0→N · 뒷걸음 N→N)"
say "🔴 기능 표식은 **따옴표가 글자의 일부**입니다. 맨 글자 ORDER_ISSUED 로 재면"
say "   기준판의 **ORDER_ISSUED_SORT_HINT**(쉰아홉째가 올린 상수)에 걸려 **2파일**이"
say "   나오고, 그러면 그 표식은 **아무것도 안 가릅니다**(머리말 ④)."
MARK_SEEN=0
check_mark "$APPMARK"   feature "$APPMARK_NOTE"
check_mark "$KEEPMARK1" keep    "$KEEPMARK1_NOTE"
check_mark "$KEEPMARK2" keep    "$KEEPMARK2_NOTE"
check_mark "$KEEPMARK3" keep    "$KEEPMARK3_NOTE"
[ "$MARK_SEEN" = "$MARKS_WANT" ] && ok "표식 ${MARKS_WANT}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "표식을 ${MARK_SEEN}개만 봤다 — ${MARKS_WANT}개를 기대했다"
say "🔵 뒷걸음 표식이 **셋**인 까닭: 쉰아홉째·쉰여덟째·쉰여섯째가 올린 글자를 하나씩"
say "   잡고 있습니다 — **하나도 빼지 마세요.** 뺀 자리는 다시 넣는 사람이 없습니다."
say "🔴 그중 domestic-order-status-filter 는 **63번에서는 기능 표식**이었습니다."
say "   어제 올린 것이라 오늘은 「있다」가 아무것도 안 가릅니다 — **뒷걸음으로 내렸습니다.**"

# 5-ㅅ. 🔴 도구 이미지가 쓸 **마지막 커밋 표식** — 소스에서 먼저 센다
say ""
say "── 5-ㅅ. 🔴 **마지막 커밋 표식**(도구 이미지용) — 소스에서 먼저 센다"
say "🔴 이것은 **파일을 좁혀서** 맨 글자를 씁니다. 그 파일에는 SORT_HINT 가 없어"
say "   충돌이 없습니다 — 🔴 **그 사실도 git 에서 직접 셉니다**(적어 둔 값을 안 믿습니다)."
if [ ! -f "$ASD/$TOOLMARK_FILE" ]; then
  bad "$TOOLMARK_FILE 이 없다 (표식을 둘 자리가 없다)"
else
  was=$(git -C "$ASD" show "$AS_BASE:$TOOLMARK_FILE" 2>/dev/null </dev/null | grep -cF -- "$TOOLMARK" || true)
  n=$(grep -cF -- "$TOOLMARK" "$ASD/$TOOLMARK_FILE" 2>/dev/null || true)
  say "[$TOOLMARK] in $TOOLMARK_FILE — 기준 ${was:-?}줄 → 지금 ${n:-?}줄 (기대 $TOOLMARK_LINES_WAS → $TOOLMARK_LINES_WANT)"
  if [ "${was:-x}" = "$TOOLMARK_LINES_WAS" ]; then
    ok "그 파일 안에서는 기준판에 **0줄**이었다 (이 표식이 판을 **가른다**)"
  else
    bad "기준판의 그 파일에 그 글자가 ${was:-?}줄 있다 — 0 을 기대했다"
    say "      🔴 0 이 아니면 그 표식은 **이 판을 안 가릅니다.** 다른 글자를 고르세요."
    doubt
  fi
  if [ "${n:-x}" = "$TOOLMARK_LINES_WANT" ]; then ok "마지막 커밋 표식이 그 파일에 ${n}줄 있다"
  elif [ "${n:-0}" -ge 1 ] 2>/dev/null; then note "그 글자가 ${n}줄이다 — $TOOLMARK_LINES_WANT 을 기대했다. 사람이 보세요"
  else bad "마지막 커밋 표식이 그 파일에 **없다** — 표가 틀렸다"; fi
fi
say "🔵 이번 범위는 **커밋이 하나**라 기능 표식과 마지막 커밋 표식이 같은 커밋을"
say "   가리킵니다. 그래도 둘을 따로 두는 까닭은 **담긴 꼴이 다르기** 때문입니다 —"
say "   앱은 minify 를 거친 번들, 도구는 소스 글자 그대로입니다."

# 5-ㅇ. 🔴 시험 등록 — **뜻을 뒤집었다**(새 시험이 0개다)
say ""
say "── 5-ㅇ. 🔴 시험 등록 — **새 시험이 0개다.** 뜻을 뒤집어 잰다"
say "🔴 63번은 여기서 **「새 시험 3개가 목록에 등록돼 있다」**를 쟀습니다. 이번엔"
say "   새 파일이 0장이라 그대로 두면 **표본이 비어서 ✗** 입니다. 빼지 않고 뜻을"
say "   뒤집었습니다 — **「줄 수가 안 줄었다」**와 **「바뀐 시험 둘이 아직 적혀 있다」**."
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
else
  note "목록이 ${TLBASE} → ${lines} 로 **늘었다** — 이번 범위엔 새 시험이 없습니다. 사람이 보세요"
fi
# 🔴 새 시험 파일이 0개인가 — 이번 범위에서 추가된 *.test.ts(x) 를 센다.
nt=$(git -C "$ASD" diff --diff-filter=A --name-only "$AS_BASE..main" 2>/dev/null | tr -d '\r' | grep -cE '\.test\.tsx?$' || true)
say "이번 범위에서 **새로 생긴** 시험 파일 ${nt:-?}개 (기대 $AS_NEW_TESTS_WANT)"
if [ "${nt:-x}" = "$AS_NEW_TESTS_WANT" ]; then
  ok "새 시험 파일이 0개다 (등록할 것이 없다 — 그래서 이 절의 뜻을 뒤집었다)"
else
  bad "새 시험 파일이 ${nt:-?}개다 — 0 을 기대했다. 🔴 **그러면 등록 여부를 재야 합니다**"
  git -C "$ASD" diff --diff-filter=A --name-only "$AS_BASE..main" 2>/dev/null | sed 's/^/        /'
  doubt
fi
# 🔴 **빈 표본 방지** — 이번에 바뀐 시험 둘이 아직 목록에 적혀 있는가.
ct=$(printf '%s\n' "$LIST" | grep -cE '\.test\.tsx?$' || true)
say "이번에 **바뀐** 시험 파일 ${ct:-?}개 (적어 둔 값 $CH_TESTS) — 이 둘이 표본이다"
[ "${ct:-x}" = "$CH_TESTS" ] && ok "바뀐 시험이 ${CH_TESTS}개다 (표본을 바뀐 목록에서 뽑았다)" \
  || note "바뀐 시험이 ${ct:-?}개다 — $CH_TESTS 를 기대했다. 사람이 보세요"
if [ "${lines:-0}" -ge "$AS_TESTLIST_MIN_LINES" ] 2>/dev/null; then
  got=0; seen=0
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    seen=$((seen+1))
    n=$(printf '%s\n' "$TL" | grep -cFx -- "$t" || true)
    if [ "${n:-0}" -ge 1 ] 2>/dev/null; then got=$((got+1)); else printf '        안 적힘 %s\n' "$t"; fi
  done <<ENDAST
$(rows_of "$AS_TOUCHED_TESTS")
ENDAST
  probe=$(printf '%s\n' "$TL" | grep -cFx -- "$PROBE_MISS" || true)
  say "바뀐 시험 — 본 것 ${seen} · 적혀 있는 것 ${got} (기대 $AS_TOUCHED_TESTS_WANT · $AS_TOUCHED_TESTS_WANT) · 없는 경로 ${probe:-?}줄(기대 0)"
  if [ "${probe:-1}" != "0" ]; then
    bad "**없는 경로가 목록에 있다고 나왔다** — 줄 전체 일치가 깨졌다. 위 수도 못 믿는다"
  elif [ "$seen" = "$AS_TOUCHED_TESTS_WANT" ] && [ "$got" = "$AS_TOUCHED_TESTS_WANT" ]; then
    ok "이번에 바뀐 시험 ${AS_TOUCHED_TESTS_WANT}개가 **아직 목록에 적혀 있다**"
    say "      🔵 쉰아홉째가 등록한 줄입니다 — 지워졌으면 그 시험이 조용히 안 돕니다."
  else
    bad "적혀 있는 것이 ${got}/${AS_TOUCHED_TESTS_WANT} 개다 — 등록이 빠지면 조용히 안 돈다"
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
      say "         & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./64-build.sh --verify"
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
#    🔵 set -f 로 글롭을 끈다(이번 범위엔 괄호 경로가 0개지만 길을 안 바꾼다).
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
#    🔵 넷째 인자는 **판정에 안 쓰는 곁들이 값**이다(따옴표 꼴을 가르려고 찍는다).
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
      printf '%s\n' "      🔴 **따옴표만 안 맞는 것입니다** — 곁들인 글자는 번들에 있습니다."
      printf '%s\n' "         번들이 홑따옴표로 적었다는 뜻이니 **다시 굽지 말고 검사 쪽을 고치세요**"
      printf '%s\n' "         (APPMARK 를 홑따옴표 꼴로 바꾼 뒤 --verify 로 다시 재면 됩니다)."
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
    # 🔵 A/S 는 public/ 이 yes 이고 안에 9개다[실측 2026-11-18].
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
    bundle_mark "$TAG" "$APPMARK"   "번들에 **이번 판의 글자**가 있다 (소스에서는 $APPMARK_NOTE)" "$APPMARK_DIAG"
    bundle_mark "$TAG" "$KEEPMARK1" "쉰아홉째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$TAG" "$KEEPMARK2" "쉰여덟째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$TAG" "$KEEPMARK3" "쉰여섯째가 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
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
    # 🔴 **이번에 바뀐 네 장이 다 담겼는가** — 도구가 굽는 까닭의 결과물이다.
    ask_files "$TAG" "$AS_CHANGED_FILES" "$AS_CHANGED_FILES_WANT" "이번에 바뀐 파일"
    # 🔴 **ㄷ 잣대의 실물** — import 하는 scripts/ 둘이 이미지 안에도 있는가.
    v=$(dockr run --rm --entrypoint sh "$TAG" -c \
      'n=0; for f in /app/scripts/lib/delivered-date-sync-survey.ts /app/scripts/lib/requested-due-date-sync-survey.ts; do [ -f "$f" ] && n=$((n+1)); done; echo "n=$n"' 2>/dev/null | tr -d '\r')
    g=$(printf '%s' "$v" | sed -n 's/^n=//p')
    printf '      바뀐 모듈을 import 하는 scripts/ 둘: %s개 (기대 2)\n' "${g:-?}"
    if [ "${g:-x}" = "2" ]; then printf '  ✓ 그 둘이 이미지에 담겼다 (**새 몸통으로 돈다**)\n'
    else printf '  ✗ 그 둘이 %s/2 개다 — scripts/ 가 온전히 안 담겼다\n' "${g:-?}"; IMGFAIL=1; fi
    # 🔴 A/S 는 drizzle 을 **안 담아야** 한다 — 볼륨이 붙는 자리다.
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
    v=$(dock "$TAG" -c 'for pair in "portal_approval_delegations /app/vendor/dss-core/src/schema/portal-approval-delegations.ts" "portal-approval-delegations /app/vendor/dss-core/src/schema/index.ts" "due_date_row_order /app/vendor/dss-core/src/schema/repair-case-approvals.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1 $2"; fi; done')
    printf '%s\n' "$v" | sed 's/^/        /'
    g=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
    if [ "${g:-0}" = "3" ]; then
      printf '  ✓ **쉰여덟째가 올린 공용 스키마가 그대로 담겼다** (표 + index 내보내기 + 지난 판의 칸)\n'
    else
      printf '  ✗ 셋 중 %s개만 있다 — **옛 공용 스키마가 담겼다.** 올리지 마세요\n' "${g:-0}"; IMGFAIL=1
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
    printf '\n%s\n' "════════ 64-deploy.sh 의 TARS 에 넣을 줄 (tar 에서 다시 쟀습니다) ════════"
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
  printf '%s\n' "       (이름|바이트|md5|Config 지문 — 64-deploy.sh 의 TARS 에 넣을 꼴입니다)"
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

# ══ 🔴 64-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
printf '\n%s\n' "════════ 64-deploy.sh 에 붙여 넣을 것 (TARS **두 줄**) ════════"
printf '%s' "$TARTABLE"
printf '%s\n' "  🔴 위 **두 줄**로 TARS 를 통째로 갈아 끼웁니다 — 지금은 **비어 있습니다.**"
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
printf '%s\n' "       scp -O 64-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "       Get-FileHash -Algorithm MD5 64-deploy.sh"
printf '%s\n' "     🔴 **TARS 두 줄을 먼저 채운 뒤에 올리세요.**"
printf '%s\n' ""
printf '%s\n' "  ② (NAS) 지금 상태를 잰다 — 아직 아무것도 안 바뀐다"
printf '%s\n' "       sudo -i"
printf '%s\n' "       bash /volume1/dss/setup/64-deploy.sh            ← --check"
printf '%s\n' "       bash /volume1/dss/setup/64-deploy.sh --count    ← 올리기 전 수"
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
printf '%s\n' "        0건이라 보낼 것이 없습니다. 옛 폴더(_images-58·59)의 묶음을 보내면"
printf '%s\n' "        **엉뚱한 판이 볼륨을 덮습니다.**"
printf '%s\n' ""
printf '%s\n' "  ④ (NAS) **들여놓고 → 다시 재고 → 도구를 갈고 → 앱을 갈아 끼운다**"
printf '%s\n' "       bash /volume1/dss/setup/64-deploy.sh --preload"
printf '%s\n' "       bash /volume1/dss/setup/64-deploy.sh            ← 다시 --check"
printf '%s\n' "       bash /volume1/dss/setup/64-deploy.sh --tools    ← 도구 태그만 (🔵 DB 는 안 바뀐다)"
printf '%s\n' "       bash /volume1/dss/setup/64-deploy.sh --go       ⏱ 정지 창 (앱 **하나**)"
printf '%s\n' "       bash /volume1/dss/setup/64-deploy.sh --count    ← 올린 뒤 수"
printf '%s\n' "     🔴 **--migrate 모드는 없습니다** — 이번 판은 마이그레이션이 0건입니다."
printf '%s\n' "        그 자리에 **--tools** 가 들어갔습니다: 도구 태그를 갈고, 새 도구로"
printf '%s\n' "        db:preflight 를 돌려 **「대기 0건」**을 값으로 받고, DB 수가"
printf '%s\n' "        **131·28·5·11·3 그대로인지**를 잽니다."
printf '%s\n' ""
printf '%s\n' "🔴 **되돌리기**: --rollback 은 앱 하나를 옛 태그로 되돌립니다."
printf '%s\n' "   🔵 도구는 새 판 그대로 둡니다(39·41~63번과 같은 판단)."
printf '%s\n' "   🔵 **DB 는 되돌릴 것이 없습니다** — 이번 판은 한 글자도 안 바꿉니다."
printf '%s\n' "────────────────────────────────────────────────────────────"
printf '\n%s\n' "🔴🔴🔴 **64-deploy.sh 에 넣을 값 (다시 찍습니다 — 여기만 복사해도 됩니다)**"
printf '%s\n' "── TARS 두 줄"
printf '%s' "$TARTABLE"
printf '%s\n' "🔴🔴🔴 위를 64-deploy.sh 에 **그대로** 적은 뒤 scp 하세요."
