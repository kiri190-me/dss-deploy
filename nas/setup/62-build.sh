#!/bin/bash
# dss-deploy/nas/setup/62-build.sh — 쉰여덟째 배포 · 이미지 굽기 (2026-11-18)
#
# 🔵 **배포 회차(쉰여덟째)와 파일 번호(62)가 어긋나는 것은 이 저장소에서 원래
#    그렇다** — 59번이 쉰다섯째, 60번이 쉰여섯째, 61번이 쉰일곱째였다.
#    (56번은 2026-11-11 의 **양식 전용**이라 회차를 안 먹었다.)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · PowerShell 에서 Git Bash 를 부른다) ──────────
#     cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#     & "C:\Program Files\Git\bin\bash.exe" ./62-build.sh --check
#     & "C:\Program Files\Git\bin\bash.exe" ./62-build.sh --go
#
#   🔴 **bash.exe 만 치면 WSL 이 잡힌다**(2026-11-04 에 걸렸다). WSL 에서 돌면
#      도커가 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 내어 ✗ 가 흩어져
#      난다. 단서는 로그의 뿌리 경로가 **/mnt/c/…** 인 것이다 — 0절이 값으로 잰다.
#   🔴 **스크립트에 건네는 경로에는 역슬래시를 쓰지 않는다.** 역슬래시를 주면
#      bash 가 그것을 먹어 "C:Users희만Desktop…" 이 되어 No such file 이 난다.
#
#   둘째 인자로 산출물을 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-58):
#     & "C:\Program Files\Git\bin\bash.exe" ./62-build.sh --go "/d/배포본/_images-58"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다.
#      이 파일을 쓴 쪽은 **한 번도 굽지 않았다** — 재기만 했다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 지난 판과 근본부터 다른 점 — 집이 여섯이다**
# ══════════════════════════════════════════════════════════════════════
#   55~61번(쉰두째~쉰일곱째)은 **A/S 한 집**만 올렸다. 이번은 **여섯 집**이고
#   **마이그레이션이 네 집에 일곱 건** 걸린다. 그래서 61-build.sh 의 틀은
#   가져왔지만 **표를 돌며 재는 꼴**로 다시 썼다(39·31번이 쓰던 모양이다).
#
#   🔴 **그 대가로 생기는 함정이 둘 있다.**
#     ① 61번의 절들은 「A/S 하나」를 전제로 변수 이름을 박아 두었다(AS_*).
#        그대로 베끼면 **다섯 집은 아무것도 안 재는 ✓** 가 된다.
#     ② 집마다 **담는 길이 다르다.** 특히 **마이그레이션이 어디서 도는가**가
#        다르다 — 아래 표를 보라. 한 잣대로 재면 네 집에서 가짜 ✗ 가 난다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **마이그레이션이 어디서 도는가 — 집마다 다르다** [실측 2026-11-18]
# ══════════════════════════════════════════════════════════════════════
#   저장소의 Dockerfile 에서 tools 스테이지의 COPY 줄을 직접 읽어 가른 것이다.
#
#     A/S        tools 에 **drizzle/ 이 없다**  → **볼륨**에서 돈다
#                (/volume1/dss/as-migrations 가 /app/drizzle 로 붙는다)
#                🔴 그래서 **묶음 as-migrations.tar.gz 를 따로 만들어 보낸다.**
#     포털       tools 에 COPY drizzle ./drizzle 있다 → **이미지 안**에서 돈다
#     재고관리   tools 에 COPY drizzle ./drizzle 있다 → **이미지 안**에서 돈다
#     휴가       tools 에 COPY drizzle ./drizzle 있다 → **이미지 안**에서 돈다
#     계측기     이번 판에 마이그레이션 **0건**(저장소가 3장 그대로다)
#     통합승인함 🔴 **DB 가 아예 없다** — drizzle/ 폴더도 tools 스테이지도 없다
#
#   🔴 **「이미지 안에서 돈다」는 집은 도구 이미지를 안 구우면 새 .sql 이 세상에
#      존재하지 않는다.** 적용이 0건으로 조용히 끝나고 겉으로는 성공으로 보인다
#      (31·39번이 겪었다). 그래서 이번에 도구 이미지를 **다섯** 굽는다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **61-build.sh(쉰일곱째)에서 베낀 절과 버린 절**
# ══════════════════════════════════════════════════════════════════════
#   🔵 아래 「61번은 ~였다」는 **61-build.sh 를 직접 열어 확인한 것만**이다.
#
#   ── 베낀 것 (그리고 **이번 판에서도 참인지 값으로 다시 쟀다**)
#     · 0절 Git Bash 판정(/mnt/ 로 시작하면 ✗)        → 참. 그대로.
#     · 지우는 문장 잣대(**주석을 먼저 걷고 UPDATE 를 안 센다**)
#       → 🔴 참이고 **이번 판에 더 중요해졌다.** 일곱 건 중 **셋**에
#         ON DELETE restrict 가, **하나**에 ON DELETE no action 이 들어 있다.
#         그 글자를 세는 잣대였으면 **표만 더하는 판이 ✗** 가 된다.
#     · 「3-ㄴ 공용 스키마 안에서 무엇이 바뀌었나」(55번 것을 61번이 되살렸다)
#       → 🔴 **이번에도 넣는다.** dss-core 가 **또** 움직였다(아래 ②).
#     · 「굽기 전에 서브모듈 작업본이 새 커밋으로 체크아웃돼 있는가」
#       → 🔴 **이번에도 넣는다.** 포인터만 맞고 파일이 옛것이면 구운 이미지가
#         옛 스키마다. 🔴 그리고 이번에는 **포털에도** 같은 잣대를 쓴다(①).
#     · tar 크기를 **두 번** 견주기(지난 판 tar 와 · 그 이미지 자신과)
#       → 참. 다만 **지난 판 tar 바이트를 못 찾은 것이 둘** 있다(아래 ⑦).
#     · 「grep -c 는 0 일 때 종료 코드 1」· 「tar | grep -q 는 SIGPIPE」
#       · 「bash -n 이 못 잡는 둘」 · 「8진수로 읽히는 0128」
#       → 전부 참. 이 파일도 같은 규율로 썼다.
#     · 「docker build 는 dev 서버를 안 내려도 된다(.dockerignore 가 .next 를
#       막는다)」 → 참. 그래도 **여섯 포트를 재서 찍는다**(7-ㄴ).
#
#   ── 버린 것 (까닭과 함께)
#     · 61번의 **앱 번들 표식 셋 · 뒷걸음 방지 넷**은 전부 A/S 전용이고
#       「배지 표시」 판을 가르는 글자였다. 🔴 **이번 판이 하나도 안 건드린다** —
#       그대로 두면 **옛 판에서도 ✓** 인 죽은 검사다. 여섯 집 것으로 **전부 갈았다**
#       (아래 「표식을 어떻게 골랐나」). 🔵 다만 A/S 의 뒷걸음 방지 하나
#       (domesticOrders.view)는 **살려서 가져왔다** — 쉰여섯째가 올린 글자다.
#     · 61번의 **FRESH_MARK(날짜 글자로 새 내용인지 덮는 절)** 는 버렸다.
#       🔴 까닭: 이번 범위는 **열흘에 걸친 커밋 84개**라 한 날짜로 못 덮는다.
#       그 자리를 **새 파일이 이미지에 있는가**(집마다 여섯~아홉 장)로 바꿨다.
#     · 61번의 **양식(.xlsx) 절 여덟**은 버렸다 — 이번 범위에 .xlsx 변경이
#       **0줄**이고, 양식은 볼륨으로 붙어 이미지와 무관하다. 🔵 대신 A/S 도구
#       이미지 안에 /templates 가 **0개**인지는 그대로 잰다(도장이 구워졌는지).
#     · 61번의 **AS_KEEP_MIGS(0122~0128 일곱 장을 묶음에서 확인)** 는
#       **창을 밀어** 0124~0130 으로 다시 적었다. 통째로 갈아 끼우는 폴더라
#       마지막 둘만 보면 안 된다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **지난 판의 전제가 깨지는 자리 여섯 — 하나씩 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 **포털(dss-auth)에 서브모듈이 처음 생겼다.**
#      [실측] 「git diff f87bf7d..main --name-status -- .gitmodules vendor/」 가
#      **A .gitmodules · A vendor/dss-ui** 다 — 둘 다 **새 파일**이다.
#      🔴 지금까지 포털을 굽는 절에는 서브모듈 이야기가 **한 줄도 없었다.**
#      🔴 포털의 Dockerfile 은 builder 에서 「COPY . .」 를 하고 tsconfig 의
#         paths 가 「@dss/ui」 를 **./vendor/dss-ui/src/index.ts** 로 푼다
#         [실측 dss-auth/tsconfig.json 31줄]. 그 폴더가 비어 있으면
#         **npm run build 가 Module not found 로 죽는다** — 조용히 안 죽는 것이
#         그나마 다행이지만, 굽기가 30분 지나 죽는다.
#      🔴 그래서 **A/S 가 vendor/dss-core 를 다루는 그 잣대 그대로** 포털에
#         붙였다(3-ㄷ): 포인터 값 · 작업본이 비지 않았나 · 미커밋 0 ·
#         **index.ts 가 NotificationBell 을 내보내는가**.
#      🔵 포털의 **tools 스테이지는 vendor 를 안 담는다**[실측 Dockerfile] —
#         그래서 8절의 포털 도구 검사에서 vendor 를 찾지 않는다. 대신
#         **npm run 으로 값을 받아** 모듈을 못 찾는지 가른다.
#
#   ② 🔴 **A/S 의 vendor/dss-core 가 또 움직였다** — 5da0382 → b79e5ab8.
#      61번 기록에 「지난 다섯 판이 전부 안 움직였다 → 60번의 절 다섯이 그
#      전제로 쓰여 있었다 → 전부 뒤집었다」가 적혀 있다. 🔴 **두 판 연속이다.**
#      [실측] 그 사이 커밋 **2개** · 바뀐 파일 **4장**:
#        A src/schema/portal-approval-delegations.ts   ← **새 표**
#        M src/schema/index.ts                         ← 내보내기 한 줄
#        M src/schema/quote-approvals.ts               ← 색인
#        M src/schema/repair-case-approvals.ts         ← 색인
#      🔴 **A/S 쪽 git diff 에는 포인터 한 줄로만 보인다.** 서브모듈 안으로
#         들어가 세지 않으면 「104장 바뀌었다」 안에 이 변경이 안 들어 있다.
#      🔴 옛 스키마가 담긴 도구로 db:migrate 를 돌리면 **새 표를 모르는 채** 돈다.
#
#   ③ 🔴 **마이그레이션이 네 집에 동시에 일곱 건.** 순서는 62-deploy.sh 가
#      정하고 거기 까닭을 적었다. 이 파일이 지키는 것은 **묶음과 이미지가
#      그 일곱을 정말 담고 있는가** 하나다.
#
#   ④ 🔴 **통합 승인함은 DB 가 없다 — 「0건」이 아니라 「해당 없음」이다.**
#      [실측] dss-approvals 에 **drizzle/ 폴더가 없고** Dockerfile 의 스테이지가
#      deps · build · runner **셋뿐**이다(tools 가 없다).
#      🔴 다른 다섯과 같은 점검을 돌리면 .sql 세기도 _journal.json 도 전부
#         ✗ 가 난다. 그래서 이 파일은 **DBLESS 깃발**로 가지를 나눈다.
#      🔴 그리고 「--target tools」 를 주면 **그 자리에서 굽기가 실패한다** —
#         5-ㅇ 절이 「tools 스테이지가 없는 것이 정상」임을 값으로 잰다.
#
#   ⑤ 🔴 **계측기는 도구 이미지를 반드시 다시 구워야 한다.**
#      [실측] 이번 범위가 바꾼 파일에 **scripts/send-notify.ts** 가 있고
#      **src/lib/notify-send.ts** 가 **새로 생겼다**(보내는 몸통을 공용으로 뺐다).
#      njlee 의 tools 스테이지는 **scripts 와 src 를 담는다**[실측 Dockerfile
#      71·72줄] — 둘 다 바뀌었다.
#      🔴 **그런데 계측기는 상시 컨테이너가 아니다.** nas/jobs/notify-daily.sh 가
#         매일 09:00 에 **run --rm tools-meters npm run send-notify** 로 부른다
#         (그때만 떴다 사라진다). 🔴 그 작업이 새 코드를 쓰게 하려면 갈아야 하는
#         것은 **compose 의 tools-meters 줄 하나**다 — jobs/notify-daily.sh 는
#         태그를 모르고 compose 를 그때그때 읽으므로 **한 글자도 안 고친다.**
#         🔵 06-notify-install.sh 에 IMAGE=dss-meters-tools:1 이 적혀 있지만
#            그것은 **첫 설치 때 한 번 쓰는 값**이고 매일 도는 길이 아니다.
#            🔴 그래도 **다음에 그 파일을 돌리는 사람이 옛 태그를 싣는다** —
#            62-deploy.sh 의 꼬리말에 그 사실을 적었다.
#
#   ⑥ 🔴 **A/S 에 npm 의존성이 하나 늘었다** — heic2any ^0.0.4.
#      [실측] package.json diff **12줄** · **dependencies 한 줄만 늘었다** ·
#      **npm 명령은 39 → 39 로 그대로**다.
#      🔴 **이미지가 커진다.** 지난 판 tar 와 견주는 ①번 검사의 기대값이
#         그만큼 틀린다 — 그래서 A/S 두 줄만 **strict 에서 loose 로** 풀었다
#         (loose = 25% 넘으면 ⚠️ · 60% 넘어야 ✗). 🔵 wasm 디코더라 번들에서는
#         1.35MB 지만 node_modules 는 그보다 크게 늘 수 있고, **도구 이미지는
#         node_modules 를 통째로 담는다**[실측 Dockerfile 66줄].
#
#   ⑦ 🔵 **지난 판 tar 바이트를 못 찾은 것이 둘이다** — dss-leave-tools-2.tar 와
#      dss-meters-tools-1.tar. 이 저장소의 배포본·README 를 다 뒤졌지만 그 둘의
#      바이트가 **적힌 곳이 없다**(23번과 06번이 그 둘을 올렸는데 둘 다 크기를
#      안 남겼다). 🔴 **0 을 적어 두고 ①번 견주기를 ⚠️ 로 건너뛴다** —
#      0 을 기대값으로 쓰면 「차이 무한%」로 **가짜 ✗** 가 난다.
#      🔵 ②번 견주기(이미지 자신과)는 그 둘에도 그대로 듣는다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 운영에서 바꾸는 것 — 한 줄 요약**
# ══════════════════════════════════════════════════════════════════════
#   결재권 위임을 **포털 한 곳에서** 관리하고 A/S·재고관리·휴가 **세 집에
#   전파**하는 기능 전체(네 집에 표가 새로 생긴다) + 통합 승인함이 **처음 갖는
#   자체 화면** + 포털 **종 알림** + A/S 의 **파일 올리기 개선**(heic→jpg ·
#   연락서 폴더 분류 선택 · 파일 이름) + **모바일 폭 손질 넷** + 계측기의
#   **수동 발송 단추**.
#
#   🔴 **전파가 한 곳이라도 실패하면 지정 자체가 거절된다**
#      [실측 dss-auth/src/lib/approvals/delegation-push.ts 머리말 — 설계 B-13].
#      이 한 문장이 **집 올리는 순서를 정한다**. 까닭은 62-deploy.sh 에 적었다.
#
# ── 이번에 굽는 것 — **이미지 열하나 + 묶음 하나** ────────────────────
#     ①  A/S 앱        dss-as:5.3         → dss-as:5.4            커밋 18
#     ②  A/S 도구      dss-as-tools:20    → dss-as-tools:21       🔴 --target tools
#     ③  포털 앱       dss-auth:2.1       → dss-auth:2.2          커밋 13
#     ④  포털 도구     dss-auth-tools:4   → dss-auth-tools:5      🔴 --target tools
#     ⑤  승인함 앱     dss-approvals:0.1  → dss-approvals:0.2     커밋 24
#     ⑥  재고 앱       dss-inventory:0.6  → dss-inventory:0.7     커밋 16
#     ⑦  재고 도구     dss-inventory-tools:3 → :4                 🔴 --target tools
#     ⑧  휴가 앱       dss-leave:0.4      → dss-leave:0.5         커밋 11
#     ⑨  휴가 도구     dss-leave-tools:2  → dss-leave-tools:3     🔴 --target tools
#     ⑩  계측기 앱     dss-meters:1.4     → dss-meters:1.5        커밋 2
#     ⑪  계측기 도구   dss-meters-tools:1 → dss-meters-tools:2    🔴 --target tools
#     ⑫  🔴 **마이그레이션 묶음 as-migrations.tar.gz** — 131장 (A/S 전용)
#
#   🔴 **PO(dss-po)·게시판·개선요청·RF이슈관리는 안 굽는다** — 이번 범위에
#      한 줄도 없다. 🔵 PO 는 운영에서 직원 접근이 **닫혀 있다**(2026-11-08).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **도구 이미지를 굽는 까닭 — 마이그레이션 수로 정하지 않는다**
# ══════════════════════════════════════════════════════════════════════
#   41·48·52~61번이 쓰던 잣대 넷을 그대로 쓴다. **집마다 걸리는 까닭이 다르다.**
#     ㄱ) npm 명령이 늘었나
#     ㄴ) tools 스테이지가 담는 것 중 바뀐 파일이 있나
#     ㄷ) tools 가 drizzle/ 을 담는데 마이그레이션이 늘었나
#     ㄹ) 공용 스키마(vendor/*)가 움직였나
#
#   [실측 2026-11-18 · npm 명령 수는 scripts 블록 안만 센 값]
#     A/S        ㄱ **39 → 39 안 걸린다** · ㄴ **걸린다**(src 92 · scripts 3) ·
#                ㄷ 해당 없음(drizzle 을 안 담는다) · ㄹ **걸린다**(dss-core)
#     포털       ㄱ **25 → 26 걸린다**(check:delegations 가 생겼다) ·
#                ㄴ **걸린다**(src 44 · scripts 2) · ㄷ **걸린다**(0010) ·
#                ㄹ 해당 없음(tools 가 vendor 를 안 담는다)
#     재고관리   ㄱ **17 → 17 안 걸린다** · ㄴ **걸린다**(src 43) ·
#                ㄷ **걸린다**(0026·0027) · ㄹ 해당 없음
#     휴가       ㄱ **23 → 32 걸린다**(시험 명령 아홉) · ㄴ **걸린다**(src 29 ·
#                scripts 14) · ㄷ **걸린다**(0003·0004) · ㄹ 해당 없음
#     계측기     ㄱ **20 → 20 안 걸린다** · ㄴ **걸린다**(scripts 1 · src 8 —
#                🔴 **이것 하나로 굽는다**) · ㄷ 해당 없음 · ㄹ 해당 없음
#     승인함     🔴 **tools 스테이지 자체가 없다.**
#   🔴 「안 걸린다」도 **값으로 잰다.** 바뀌었는데 0 으로 적어 두면 다음 판이
#      그 거짓을 근거로 「안 구워도 된다」를 꺼낸다(61번이 적어 둔 말이다).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **표식을 어떻게 골랐나 — 먼저 재 보고 골랐다** [실측 2026-11-18]
# ══════════════════════════════════════════════════════════════════════
#   집이 여섯이라 표식도 여섯 벌이다. 🔴 **고르는 규칙을 둘로 나눴다.**
#
#   ── 앱 이미지(.next/standalone · **minify 를 거친다**)
#      🔴 **상수·함수 이름으로 재지 않는다** — minify 가 지운다. 60번의 실측으로
#         「코드가 그 글자로 묻는 **리터럴**」은 견딘다는 것이 확인됐다.
#         그래서 여섯 다 **표 이름 · 통로 경로 · 열쇠 문자열 · 클래스 문자열**로 골랐다.
#      🔴 전부 **기준판 src/ 에 0파일**(뒷걸음 표식은 반대로 **1 이상**)이다.
#
#        집        기능 표식(기준→지금)                        뒷걸음 표식(기준→지금)
#        A/S       portal_approval_delegations      0→26      domesticOrders.view   17→17
#        포털      dss.delegations.write            0→4       approval_mail_kinds    3→3
#        승인함    /api/integration/delegations     0→1       rf-service-system      2→2
#        재고      portal_approval_delegations      0→14      stock_issue_approval_steps 10→10
#        휴가      web_portal_approval_delegations  0→5       web_approval_steps     3→4
#        계측기    /settings/notify                 0→3       web_notifications      1→6
#
#      🔴 **번들에서 세어 본 수는 아직 없다**(개발 PC 에 standalone 이 없다).
#         그래서 이미지 안 검사는 **「합이 1 이상」으로만** 잰다 —
#         **✗ 가 나면 검사부터 의심한다.**
#      🔴 **뒷걸음 표식을 하나도 빼지 마라** — 뺀 자리는 다시 넣는 사람이 없다.
#
#   ── 도구 이미지(**소스가 글자 그대로 있다**)
#      🔴 여기서는 **마지막 커밋이 담겼는가**를 가른다. 앱 번들에서 그것까지
#         가르려면 커밋마다 리터럴을 찾아야 하는데, 여섯 집의 마지막 커밋 중
#         **넷이 화면 폭 손질**이라 새 리터럴이 클래스 문자열뿐이다.
#      🔵 **두 이미지는 같은 작업본에서 같은 실행으로 굽는다** — 2절이 그
#         작업본의 HEAD 와 미커밋 0 을 이미 확인했으므로, 도구에 마지막 커밋이
#         있으면 앱에도 있다. 🔴 **그 전제를 출력에도 적는다.**
#
#        집        마지막 커밋 표식                            | 파일
#        A/S       UPLOAD_FILE_NAME_MAX_LENGTH       0→3      | src/components/repair-cases/files/upload-file-name.ts
#        포털      h-7 shrink-0 items-center whitespace-nowrap 0→1 | src/app/apps/page.tsx
#        재고      TOOLBAR_BTN_PRIMARY               0→1      | src/components/parts/PartsList.tsx
#        휴가      loadDelegationFoldActingFor       0→2      | src/lib/auth/portal-delegations.ts
#        계측기    onConflictDoNothing               0→1      | scripts/send-notify.ts
#
#      🔴 **승인함은 도구 이미지가 없다.** 그래서 승인함만 **앱 번들에서**
#         마지막 커밋을 가른다 — 「grid grid-cols-2 gap-3 sm:col-span-2」
#         (클래스 문자열 · 기준 0 → 지금 1).
#      🔴 **계측기의 마지막 커밋은 앱에 안 담긴다** — 그 커밋이 고친 것이
#         scripts/ · 시험 · 문서뿐이다[실측 4장]. 계측기 앱 이미지에서는
#         **앞 커밋(e0207f1)까지만** 가려진다. 그 사실을 출력에 적는다.
#
# ── 🔴 모드 셋 ────────────────────────────────────────────────────────
#   --verify 🔴 **이미 구운 열하나를 다시 재기만 한다.** docker build 도
#            docker save 도 한 줄 안 돌린다 — **구운 지문(md5)이 바뀌면 안 되기**
#            때문이다. 2026-11-18 에 이 모드를 더했다: 첫 굽기에서 **검사 쪽이
#            틀려** 가짜 ✗ 가 일곱 났는데, 검사를 고친 뒤 「고친 검사가 정말
#            통과하는가」를 재야 했고 다시 구우면 **이미 받아 둔 TARS 값이
#            못 쓰게 된다.**
#            🔵 **쓰는 것**: 없다. 꼬리말에 TARS 열한 줄을 **다시 찍어 준다**
#               (tar 를 열어 다시 재므로 굽지 않고도 그 값을 받을 수 있다).
#            🔴 6절의 기대값이 **뒤집힌다** — 이 모드에서는 태그가 **있어야** 한다.
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다.
#            🔵 **쓰는 것**: 없다(폴더도 --go 때만 만든다).
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면
#            굽지 않고 멈춘다. 전부 ✓ 일 때만 **열하나를 굽고** tar 로 뽑고
#            **묶음을 만든다.** 그리고 **이미지 안을 센다**(겉이 아니라 결과).
#            🔵 **쓰는 것**: $OUT 폴더 · tar 열하나 · 묶음 하나 · 빌드 로그
#               열하나 · 도커 이미지 열하나.
#            🔵 **안 쓰는 것**: 저장소 안의 파일 · NAS · DB.
#   🔵 두 모드가 **같은 함수(check_all)** 로 잰다. 두 벌로 적으면 어긋난다.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 tar 크기를 **두 번** 견준다 ────────────────────────────────────
#   ① **지난 판 tar 와** 견준다 — 적어 둔 값의 출처는 아래 IMAGES 표 주석.
#      🔴 **둘은 값을 못 찾아 0 으로 두었다**(⑦) — 그 둘은 ⚠️ 로 건너뛴다.
#   ② **그 이미지 자신과** 견준다. 가지가 둘이다:
#      · containerd 저장소면 inspect .Size 가 **압축된 내용 크기**라 90~110%.
#      · 고전 저장소면 **펼친 크기**라 tar 는 그 **1/4쯤**(10~45%).
#   🔴 **tar 지문은 'docker image inspect' 의 .Id 와 맞대지 않는다.** 그것은
#      애초에 다른 값이다. 맞댈 상대는 **빌드 로그의 'exporting config sha256:'** 이다.
#
# ── 🔴 이 환경의 함정 (36~61-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싼다. 저장소 자리를
#      적어 넣지 않고 **이 파일의 자리에서 계산한다**(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:/… 를 /c/… 로
#      바꾸고, docker save 와 묶음 만들기는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를
#      막는다 — 5-ㄴ 이 여섯 집에서 그것을 잰다). 🔴 그래도 7-ㄴ 이 **여섯 포트**를
#      재서 찍는다.
#   ④ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다.** 이 파일의 표식은
#      **전부 ASCII** 다 — 8진 이스케이프가 한 군데도 없다(61번은 셋 있었다).
#      🔵 그만큼 「못 만들었다」로 샐 자리가 없어졌다.
#   ⑤ 🔴 **대괄호·괄호가 든 경로를 글롭에 넘기지 않는다.**
#      🔴 [실측] 괄호가 든 바뀐 경로 — A/S **6** · 승인함 **2** · 재고 **2** ·
#         휴가 **2** · 계측기 **1**. **다섯 집에 살아 있다.**
#      🔴 git 의 **pathspec 은 글롭**이라 「-- "…/(app)/…"」 로 물으면 조용히
#         0줄이 돌아온다. 그래서 바뀐 목록은 **한 번만 뽑아 두고 grep -Fx 로** 맞댄다.
#      🔴 셸 쪽도 같다 — 목록은 **here 문서 + while read** 로만 돌린다.
#      🔴 컨테이너 안에서도 경로를 **큰따옴표**로 감싸고 set -f 로 글롭을 끈다.
#   ⑥ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」
#      같은 안전망을 달면 **하필 바라던 0 에서만** 그것이 터져 값이 "0 ?" 가 된다.
#      이 파일은 그 꼴을 **한 군데도 쓰지 않는다** — 「$( … || true )」 로 받는다.
#   ⑦ 🔴 **tar | grep -q 를 if 에 바로 물리지 않는다.** set -uo pipefail 때문에
#      grep -q 가 먼저 끝나면 앞의 tar 가 SIGPIPE 로 죽고 **파일이 있을 때 오히려
#      ✗** 가 난다(2026-11-07 쉰째에서 실제로 났다). 묶음을 읽는 자리는 전부
#      **세어서 담고 비교하는 꼴**(grep -c · grep -o)이다.
#   ⑧ 🔴 **지우는 문장을 셀 때 주석을 먼저 걷어낸다.** 그리고 **UPDATE 를 잣대에
#      넣지 마라** — 'updated_by'·'updated_at' **칸 이름**이 걸린다.
#      🔴 **ON DELETE 도 안 센다** — 이번 일곱 중 넷에 그 글자가 있다.
#   ⑨ 🔴 **CRLF.** 이 저장소들의 작업본은 전부 CRLF 다. Git Bash 의 grep 만
#      \r 를 걷어내고 리눅스 컨테이너의 GNU grep 은 안 걷어낸다. 줄 전체로
#      맞대는 검사(-Fx)는 **읽자마자 tr -d 로 \r 를 걷어낸 뒤** 맞댄다.
#   ⑩ 🔴 **빈 결과는 삼켜진 오류일 수 있다.** 목록을 읽는 자리는 **읽은 줄 수를
#      함께 받아** 너무 적으면 ✗ 로 세고, **없는 경로 하나를 일부러 함께 묻는다**.
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
#   [실측 2026-11-18 · 굽기 뒤에 걸렸다] docker.exe 는 **윈도우 프로그램**이라
#   MSYS 런타임이 인자를 넘기기 전에 「유닉스 절대경로처럼 생긴 것」을 윈도우
#   경로로 **조용히 번역한다.** 값에 빈칸이 없고 / 로 시작하면 걸린다:
#
#       docker run -e F="/app/src/x.ts" …  →  컨테이너 안에서 $F 가
#       C:/Program Files/Git/app/src/x.ts  가 되어 [ -f "$F" ] 가 거짓이 된다
#
#   🔴 **이것이 첫 굽기에서 난 가짜 ✗ 일곱 중 일곱의 까닭이었다.**
#      · 도구 다섯의 「마지막 커밋 표식 missing」 — -e F="/app/…" 가 번역됐다
#      · 계측기 「/settings/notify 가 번들에 없다」 — 표식 자체가 번역됐다
#      · 승인함 「/api/integration/delegations 가 없다」 — 같은 까닭
#      🔵 **표식도 파일도 멀쩡했다.** 컨테이너를 열어 세어 보니 각각
#         6·1 개였고 파일도 12317바이트로 있었다.
#   🔴 **왜 다른 검사는 멀쩡했나**: -c '…' 로 넘기는 셸 토막은 빈칸이 들어 있어
#      경로로 안 읽히고, ask_files 는 **상대경로**를 넘겨 /app/ 를 컨테이너
#      안에서 붙인다. 걸린 것은 **값이 / 로 시작하고 빈칸이 없는 것들**뿐이다.
#
#   처방 셋을 **다 쓴다**(하나만으로는 또 걸린다):
#     ① 아래 dockr() — **docker 를 부를 때만** 번역을 끈다.
#     ② 🔴 **그것이 실제로 꺼졌는지 값으로 잰다**(1-ㄴ 절). 변수 이름이 바뀌거나
#        다른 셸에서 돌면 ①이 조용히 안 듣는데, 그때 나는 ✗ 는 **진짜 결함처럼
#        보인다.** 「빈 결과는 삼켜진 오류일 수 있다」의 실물이다.
#     ③ 파일 경로는 **상대로 넘기고 /app/ 를 컨테이너 안에서 붙인다** —
#        ①이 안 들어도 그 검사만은 산다.
#
#   🔴 **전역 export 로 끄면 git 이 깨진다 — 실제로 깨뜨려 봤다.**
#      [실측 2026-11-18] 맨 위에서 export 했더니 **git 쪽 ✗ 가 스물한 개** 났다:
#      「가지가 못 읽음」·「기준 SHA 가 이 저장소에 없다」·「서브모듈 포인터를
#      못 읽었다」. 까닭은 이 파일이 git 에 넘기는 경로가 **/c/Users/… 꼴**이라,
#      번역을 끄면 git.exe 가 그 글자를 그대로 받아 못 찾기 때문이다.
#      ([ -d ] 같은 **셸 내장**은 멀쩡해서 「저장소는 있는데 git 이 다 틀린」
#       모양이 되고, 그것이 또 진짜 결함처럼 보인다.)
#      🔵 그래서 **docker 를 부르는 자리에만** 붙인다. 같은 셸에서 git 은 그대로다.
dockr() { MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker "$@"; }

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

# tar 안 manifest.json 의 Config 지문 (39~61-build.sh 의 것을 글자 그대로)
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

# 한 저장소의 drizzle/ 을 센다 → ".sql수 journal수"
# 🔴 _journal.json 은 drizzle/ 바로 아래가 아니라 **meta/ 안**이다.
count_drizzle() { # 1 저장소 폴더
  local s j
  s=$(ls -1 "$1/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  j=$(grep -o '"idx"' "$1/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  printf '%s %s' "${s:-0}" "${j:-0}"
}

# ══════════════════════════════════════════════════════════════════════
# ══ 이번 판의 값 — 한자리에 모아 둔다 ═════════════════════════════════
# ══════════════════════════════════════════════════════════════════════
#
# ── 저장소 여섯 ───────────────────────────────────────────────────────
#   열쇠|폴더|사람이 부르는 이름|기준 SHA|기대 커밋 수|dev 포트|DB 있나
#   🔴 기준 SHA 의 출처: README.md 113~126행의 「기준 SHA — 쉰일곱째까지」 표.
#      [실측 2026-11-18] 여섯 다 그 SHA 에서 세어 아래 수와 맞았다.
#   🔴 **커밋 수는 ⚠️ 로만 센다** — 사람이 그 사이에 하나 더 밀 수 있다.
#      🔵 계측기는 메인이 잰 뒤 **하나 더 늘었다**(ab238fe). 아래가 지금 값이다.
REPOS='
as|RF_Service_System|A/S관리|70ec2173|18|3000|yes
auth|dss-auth|통합로그인포털|f87bf7d|13|3100|yes
approvals|dss-approvals|통합승인함|8ab36fd|24|3900|no
inventory|dss-inventory|재고관리|e0d84e8|16|3800|yes
leave|dss-leave|휴가관리|f568fc0|11|3700|yes
meters|njlee|계측기관리|a234878|2|3300|yes
'
REPOS_WANT=6

# ── 굽는 열하나 ───────────────────────────────────────────────────────
#   열쇠|저장소폴더|새 태그|타깃(-=기본 runner)|지난판 tar 이름|지난판 tar 바이트|엄함
#   🔴 지난판 바이트의 출처(전부 이 저장소의 배포본에 적힌 값을 눈으로 맞댄 것):
#      dss-as-5.3.tar            134987776  61-deploy.sh 의 TARS
#      dss-as-tools-20.tar       225588736  61-deploy.sh 의 TARS
#      dss-auth-2.1.tar          113688064  55-deploy.sh 의 TARS
#      dss-auth-tools-4.tar      212260864  55-deploy.sh 의 TARS
#      dss-approvals-0.1.tar      94882816  38-approvals.sh 의 TAR_SIZE
#      dss-inventory-0.6.tar      95444992  39-deploy.sh 의 TARS
#      dss-inventory-tools-3.tar 213200896  31-deploy.sh 의 TARS
#      dss-leave-0.4.tar          75085824  37-deploy.sh 의 TARS
#      dss-meters-1.4.tar        114052096  31-deploy.sh 의 TARS
#      dss-leave-tools-2.tar             0  🔴 **적힌 곳이 없다**(⑦)
#      dss-meters-tools-1.tar            0  🔴 **적힌 곳이 없다**(⑦)
#   🔵 엄함: strict = 25% 넘으면 ✗ · loose = 25% ⚠️ · 60% 넘으면 ✗ ·
#            none = ①번 견주기를 **아예 건너뛴다**(기준값이 없다).
#   🔴 A/S 둘만 loose 다 — heic2any 가 늘었다(⑥).
IMAGES='
as|RF_Service_System|dss-as:5.4|-|dss-as-5.3.tar|134987776|loose
astools|RF_Service_System|dss-as-tools:21|tools|dss-as-tools-20.tar|225588736|loose
auth|dss-auth|dss-auth:2.2|-|dss-auth-2.1.tar|113688064|strict
authtools|dss-auth|dss-auth-tools:5|tools|dss-auth-tools-4.tar|212260864|strict
approvals|dss-approvals|dss-approvals:0.2|-|dss-approvals-0.1.tar|94882816|strict
inventory|dss-inventory|dss-inventory:0.7|-|dss-inventory-0.6.tar|95444992|strict
inventorytools|dss-inventory|dss-inventory-tools:4|tools|dss-inventory-tools-3.tar|213200896|strict
leave|dss-leave|dss-leave:0.5|-|dss-leave-0.4.tar|75085824|strict
leavetools|dss-leave|dss-leave-tools:3|tools|dss-leave-tools-2.tar|0|none
meters|njlee|dss-meters:1.5|-|dss-meters-1.4.tar|114052096|strict
meterstools|njlee|dss-meters-tools:2|tools|dss-meters-tools-1.tar|0|none
'
HOWMANY=11

# ── 마이그레이션 ─────────────────────────────────────────────────────
#   열쇠|저장소가 들고 있어야 하는 .sql 수|운영이 지금 들고 있는 수|새 것 수|
#   마지막 번호|그 다음 번호(있으면 전제가 깨진 것)|도는 자리(volume|image|none)
#   🔴 운영 수의 출처:
#      A/S  129  61-deploy.sh 의 AS_SQL_WANT (쉰일곱째가 올린 값)
#      포털  10  39-deploy.sh 의 AUTH_KEEP
#      재고  26  39-deploy.sh 의 INV_KEEP
#      휴가   3  저장소가 0000~0002 였고 그 뒤 휴가 마이그레이션 배포가 없었다
#      계측기 3  이번 범위에 drizzle 변경 0줄
#   🔴 **운영 수는 개발 PC 에서 못 잰다.** 62-deploy.sh --check 가 DB 에 물어
#      확인한다 — 어긋나면 **거기서 멈춘다.**
MIGS='
as|131|129|2|0130|0131|volume
auth|11|10|1|0010|0011|image
approvals|0|0|0|-|-|none
inventory|28|26|2|0027|0028|image
leave|5|3|2|0004|0005|image
meters|3|3|0|0002|0003|image
'

# 🔴 이번에 새로 생긴 마이그레이션 파일 — **이름까지 못 박는다.**
#    열쇠|파일이름(여러 개면 빈칸으로 나눈다)
NEW_MIG_FILES='
as|0129_portal_approval_delegations.sql 0130_long_the_liberteens.sql
auth|0010_giant_victor_mancha.sql
inventory|0026_safe_wallflower.sql 0027_broad_secret_warriors.sql
leave|0003_portal_approval_delegations.sql 0004_approval_history_indexes.sql
'
NEW_MIG_FILES_WANT=7

# 🔵 A/S 묶음을 통째로 갈아 끼우므로 **창 안의 일곱**을 다 본다(창이 두 칸 밀렸다).
AS_KEEP_MIGS='0124 0125 0126 0127 0128 0129 0130'
AS_KEEP_MIGS_WANT=7

# ══ 🔴 지우는 문장 잣대 — **주석을 먼저 걷어낸다** ════════════════════
#   🔴 55·60·61-build.sh 의 잣대를 글자 그대로 가져왔다. **UPDATE 를 넣지 않는다** —
#      넣으면 'updated_by'·'updated_at' **칸 이름**이 걸린다.
#   🔵 ON DELETE · DROP CONSTRAINT · DROP INDEX 는 **안 센다** — 앱의
#      migration-safety 와 같은 잣대다. 🔴 이번 일곱 중 **넷**에 ON DELETE 가 있다
#      (A/S 0129 에 restrict 둘 · 포털 0010 에 restrict 넷 · 휴가 0003 에 no action
#      둘). 그 글자를 세는 잣대였으면 **표만 더하는 판이 전부 ✗** 다.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
MIG_DROP_WANT=0
SQL_COMMENT_RE='^[[:space:]]*--'

# ══ 🔴 서브모듈 ═══════════════════════════════════════════════════════
#   🔴 A/S 의 dss-core 가 **두 판 연속** 움직인다(②).
AS_CORE_WAS=5da03825baa1a6a89a47a069d73ecaca4d69bb9c
AS_CORE_PIN=b79e5ab894389a6fe433d7214d9c4496294dabee
AS_CORE_COMMITS_WANT=2
AS_CORE_FILES_WANT=4
AS_CORE_NEW_SCHEMA=src/schema/portal-approval-delegations.ts
AS_CORE_TABLE=portal_approval_delegations
# 🔵 dss-ui 는 **일곱째 판 연속 안 움직인다**(1210d11). 🔴 그래도 값으로 잰다.
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425
# 🔴 포털에 **처음** 생긴 서브모듈(①). dss-ui 를 쓰는 집이 하나 늘었다.
AUTH_UI_IS_NEW=yes
AUTH_UI_EXPORT=NotificationBell
AUTH_TSCONFIG_PATH='./vendor/dss-ui/src/index.ts'

# ══ 🔴 바뀐 파일 수 — [실측 2026-11-18] ═══════════════════════════════
#   열쇠|전체|src/|scripts/|drizzle/|vendor+.gitmodules|새 파일|지운 파일|괄호 든 경로
#   🔴 **지운 파일은 여섯 집 다 0 이다.** 하나라도 늘면 멈추고 사람이 본다.
CHANGED='
as|104|92|3|5|1|41|0|6
auth|55|44|2|3|2|34|0|0
approvals|31|16|0|0|0|26|0|2
inventory|75|43|0|5|0|27|0|2
leave|50|29|14|5|0|25|0|2
meters|11|8|1|0|0|3|0|1
'

# ══ 🔴 npm 명령 수 — [실측 2026-11-18] ════════════════════════════════
#   열쇠|기준판|지금
NPMCMDS='
as|39|39
auth|25|26
approvals|6|6
inventory|17|17
leave|23|32
meters|20|20
'

# ══ 🔴 앱 번들에서 쓸 표식 — **전부 리터럴 · 전부 ASCII** ═════════════
#   열쇠|기능 표식|뒷걸음 표식|기능 표식의 기준→지금(사람이 읽을 말)
#   🔴 **공백이 든 표식이 있다**(포털·승인함). 그래서 이 표는 tr -d ' ' 로
#      읽지 않고 **here 문서 + IFS='|' read** 로만 읽는다.
APPMARKS='
as|portal_approval_delegations|domesticOrders.view|기준 0 → 지금 26파일
auth|dss.delegations.write|approval_mail_kinds|기준 0 → 지금 4파일
approvals|/api/integration/delegations|rf-service-system|기준 0 → 지금 1파일
inventory|portal_approval_delegations|stock_issue_approval_steps|기준 0 → 지금 14파일
leave|web_portal_approval_delegations|web_approval_steps|기준 0 → 지금 5파일
meters|/settings/notify|web_notifications|기준 0 → 지금 3파일
'

# ══ 🔴 도구 이미지에서 쓸 **마지막 커밋 표식** ════════════════════════
#   열쇠|표식|그 표식이 있어야 하는 파일(이미지 안 경로는 /app/ + 이것)
TOOLMARKS='
astools|UPLOAD_FILE_NAME_MAX_LENGTH|src/components/repair-cases/files/upload-file-name.ts
authtools|h-7 shrink-0 items-center whitespace-nowrap|src/app/apps/page.tsx
inventorytools|TOOLBAR_BTN_PRIMARY|src/components/parts/PartsList.tsx
leavetools|loadDelegationFoldActingFor|src/lib/auth/portal-delegations.ts
meterstools|onConflictDoNothing|scripts/send-notify.ts
'
TOOLMARKS_WANT=5
# 🔴 승인함만 **앱 번들에서** 마지막 커밋을 가린다(도구 이미지가 없다).
APPROVALS_LAST_MARK='grid grid-cols-2 gap-3 sm:col-span-2'

# ══ 🔴 public/ 기대값 — **집마다 다르다** ═════════════════════════════
#   열쇠|기대(yes|no)|이미지 안 파일 수(참고 · 판정에 안 쓴다)
#   🔴 **승인함만 no 다.** [실측 2026-11-18 · 구운 열하나와 옛 판 다섯을 열어 셌다]
#      dss-approvals:0.1 **no** · dss-approvals:0.2 **no** · 저장소에도 **없다**.
#      그 상태로 운영이 잘 돌고 있다 — 그 집 Dockerfile 88줄이 「이 집에는 그
#      폴더가 없다 · 아홉을 베끼면 /app/public not found 로 멈춘다(2026-10-24)」
#      라고 적어 두었다.
#   🔵 재고·휴가는 폴더는 있는데 **비어 있다**(0개). 그것도 원래 그렇다 —
#      「담겼다 ✓」가 아니라 ⚠️ 로 적어 사람이 속지 않게 한다.
PUBLIC_WANT='
as|yes|9
inventory|yes|0
leave|yes|0
auth|yes|6
approvals|no|0
meters|yes|5
'

# ══ 🔴 **이번 판의 핵심 파일** — 도구 이미지가 담고 있어야 한다 ══════
#   🔴 시험 파일은 뺐다(도구 이미지에도 들어가지만 목록 등록은 따로 잰다).
#   🔴 **없는 경로 하나를 함께 묻는다** — 「무조건 yes」인 검사인지 가른다.
#   🔴 **목록 끝에 괄호가 든 경로를 일부러 넣었다**(A/S 2 · 재고 2 · 휴가 2).
#      글롭 함정이 이 다섯 집에 **살아 있어서** — 목록을 넘기는 길이 끊기면
#      그 줄들이 먼저 사라진다. 🔵 그 둘은 새 파일이 아니라 **이번에 고친** 파일이다.
PROBE_MISS=src/__dss_probe_no_such_file__.ts
AS_NEW_FILES='
src/app/api/integration/approval-history/route.ts
src/app/api/integration/delegations/route.ts
src/components/repair-cases/files/ShareDocFolderPickerDialog.tsx
src/components/repair-cases/files/heic-to-jpeg.ts
src/components/repair-cases/files/heic-upload.ts
src/components/repair-cases/files/upload-file-name.ts
src/lib/db/mutations/portal-approval-delegations.ts
src/lib/db/queries/approval-history.ts
src/lib/db/queries/portal-approval-delegations.ts
src/lib/domain/approval-history.ts
src/lib/domain/contact-folder-save-targets.ts
src/lib/server/integration/portal-approval-history.ts
src/lib/server/integration/portal-delegation-list.ts
src/lib/server/integration/portal-delegation-push.ts
src/app/(app)/users/page.tsx
src/app/(app)/repair-cases/page.tsx
'
AS_NEW_FILES_WANT=16
AUTH_NEW_FILES='
scripts/check-delegation-sync.ts
src/app/api/integration/approval-history/route.ts
src/app/api/integration/delegations/route.ts
src/lib/approvals/delegation-push-service.ts
src/lib/approvals/delegation-push.ts
src/lib/approvals/delegation-request.ts
src/lib/approvals/delegation-sync.ts
src/lib/approvals/delegation.ts
src/lib/approvals/history-gather.ts
src/lib/approvals/history-service.ts
src/lib/db/mutations/approval-delegations.ts
src/lib/db/queries/approval-delegations.ts
src/lib/db/schema/approval-delegations.ts
src/lib/notifications/bell-key.ts
src/lib/server/actions/notification-bell.ts
'
AUTH_NEW_FILES_WANT=15
INV_NEW_FILES='
src/app/api/integration/approval-history/route.ts
src/app/api/integration/delegations/route.ts
src/db/schema/portal-approval-delegations.ts
src/lib/approval/delegated-role.ts
src/lib/approval/part-issue-history.ts
src/lib/approval/portal-delegation-list.ts
src/lib/approval/portal-delegation-store.ts
src/lib/approval/portal-delegation-sync.ts
src/lib/notifications/portal-approval-history.ts
src/app/(app)/settings/delegations/page.tsx
src/app/(app)/layout.tsx
'
INV_NEW_FILES_WANT=11
LEAVE_NEW_FILES='
src/app/api/integration/approval-history/route.ts
src/app/api/integration/delegations/route.ts
src/components/DelegationNotice.tsx
src/lib/auth/delegated-role.ts
src/lib/auth/portal-delegation-store.ts
src/lib/auth/portal-delegations.ts
src/lib/leave/approval-history.ts
src/lib/leave/delegation-view.ts
src/lib/leave/portal-approval-history.ts
src/lib/leave/portal-delegation-list.ts
src/lib/leave/portal-delegation-sync.ts
src/lib/leave/settings-tabs.ts
src/app/(internal)/admin/settings/page.tsx
src/app/(internal)/approvals/page.tsx
'
LEAVE_NEW_FILES_WANT=14
METERS_NEW_FILES='
src/components/ResendNotifyForm.tsx
src/lib/notify-send.ts
'
METERS_NEW_FILES_WANT=2

# ══ 🔴 시험 등록 — **저장소마다 방식이 다르다** ═══════════════════════
#   🔴 목록 방식에서 등록을 빠뜨리면 **오류 없이 조용히 안 돈다.**
#   A/S   : scripts/test-lists/*.txt  (🔴 **CRLF** 라 \r 를 걷고 -Fx 로 맞댄다)
#   포털  : package.json 의 test 줄에 경로를 하나씩 나열
#   휴가  : scripts/test-*.ts 와 package.json 의 test:* 명령이 짝
#   재고  : 글롭 둘 — tests/**/*.test.ts · src/lib/xlsx/*.test.ts (등록 불필요)
#   승인함: tests/ 글롭 (등록 불필요)
#   계측기: 글롭 — src/**/*.test.ts (등록 불필요)
AS_TESTLIST_DIR=scripts/test-lists
AS_TESTLIST_MIN_LINES=3800
AS_NEW_TESTS='
src/app/api/integration/delegations/route-list-branch.integration.test.ts
src/components/repair-cases/files/heic-upload.test.ts
src/components/repair-cases/files/share-doc-contact-folder-reload.test.tsx
src/components/repair-cases/files/share-doc-folder-picker-dialog.test.tsx
src/components/repair-cases/files/upload-file-name.test.ts
src/components/repair-cases/files/upload-panel-width.test.ts
src/components/users/approval-route-delegation-finished-fold.test.ts
src/components/users/portal-approval-delegation-section.test.ts
src/lib/config/approvals-delegation-url.test.ts
src/lib/db/mutations/portal-approval-delegations.integration.test.ts
src/lib/db/queries/approval-history.integration.test.ts
src/lib/db/queries/approval-route-delegations-acting.integration.test.ts
src/lib/db/queries/portal-approval-delegations-audit.integration.test.ts
src/lib/db/queries/portal-approval-delegations.integration.test.ts
src/lib/db/schema/portal-approval-delegations-safety.test.ts
src/lib/domain/approval-history.test.ts
src/lib/domain/approval-route-delegation-period.test.ts
src/lib/domain/contact-folder-save-targets.test.ts
src/lib/server/actions/portal-delegation-wiring.test.ts
src/lib/server/integration/portal-approval-history.test.ts
src/lib/server/integration/portal-delegation-list.test.ts
src/lib/server/integration/portal-delegation-push.test.ts
src/lib/server/portal-delegation-read-wiring.test.ts
'
AS_NEW_TESTS_WANT=23
AS_TESTLIST_FILES='
scripts/test-lists/unit.txt
scripts/test-lists/components.txt
scripts/test-lists/db.txt
scripts/test-lists/db-safety.txt
'
AS_TESTLIST_FILES_WANT=4
# 🔴 포털이 test 줄에 새로 적은 경로 열둘.
AUTH_NEW_TESTS='
src/lib/auth/role-change-session-cut.test.ts
src/lib/approvals/delegation.test.ts
src/lib/approvals/delegation-admin-role.test.ts
src/lib/approvals/delegation-request.test.ts
src/lib/approvals/delegation-push.test.ts
src/lib/approvals/delegation-sync.test.ts
src/lib/approvals/history-period.test.ts
src/lib/approvals/history-entry.test.ts
src/lib/approvals/history-gather.test.ts
src/lib/approvals/history-request.test.ts
src/lib/notifications/bell-key.test.ts
src/lib/notifications/bell-wiring.test.ts
'
AUTH_NEW_TESTS_WANT=12
# 🔴 휴가가 새로 적은 npm 명령 아홉 — 짝이 되는 scripts/*.ts 도 함께 본다.
LEAVE_NEW_TESTS='
test:nudge-delegation|scripts/test-approval-nudge-delegation.ts
test:delegation|scripts/test-approval-delegation.ts
test:delegation-sync|scripts/test-delegation-sync.ts
test:delegation-list|scripts/test-delegation-list.ts
test:delegation-screen|scripts/test-delegation-screen.ts
test:delegation-fold|scripts/test-delegation-fold.ts
test:delegated-role|scripts/test-delegated-role.ts
test:approval-history|scripts/test-approval-history.ts
test:approval-history-api|scripts/test-approval-history-api.ts
'
LEAVE_NEW_TESTS_WANT=9

# ══ 🔴 Dockerfile 이 담는 길 — 집마다 다르다 ══════════════════════════
#   열쇠|정규식|있어야 하나(yes/no)|사람이 읽을 말
#   🔴 **no 줄이 뜻하는 것이 집마다 반대다.** A/S 의 「drizzle 을 안 담는다」는
#      **묶음을 보내야 한다**는 뜻이고, 포털의 「drizzle 을 담는다」는
#      **도구를 안 구우면 새 .sql 이 존재하지 않는다**는 뜻이다.
COPYRULES='
as|^COPY .*scripts \./scripts|yes|A/S tools 가 scripts/ 를 담는다 (바뀐 3장이 여기다)
as|^COPY .*src \./src|yes|A/S tools 가 src/ 를 담는다 (바뀐 92장이 여기다)
as|^COPY .*vendor \./vendor|yes|🔴 A/S tools 가 vendor/ 를 담는다 — 이번에 dss-core 가 바뀌었다
as|^COPY .*drizzle \./drizzle|no|🔴 A/S tools 는 drizzle/ 을 **안 담는다** — 그래서 묶음으로 보낸다
auth|^COPY .*src \./src|yes|포털 tools 가 src/ 를 담는다
auth|^COPY .*drizzle \./drizzle|yes|🔴 포털 tools 가 drizzle/ 을 **담는다** — 0010 이 이미지 안에 구워진다
auth|^COPY .*scripts \./scripts|yes|포털 tools 가 scripts/ 를 담는다 (check-delegation-sync.ts 가 새로 생겼다)
auth|^COPY .*vendor \./vendor|no|🔵 포털 tools 는 vendor/ 를 **안 담는다** — builder 만 @dss/ui 를 쓴다
inventory|^COPY drizzle \./drizzle|yes|🔴 재고 tools 가 drizzle/ 을 **담는다** — 0026·0027 이 이미지 안에 구워진다
inventory|^COPY scripts \./scripts|yes|재고 tools 가 scripts/ 를 담는다 (migrate.ts 가 여기다)
inventory|^COPY src \./src|yes|재고 tools 가 src/ 를 담는다
leave|^COPY .*src \./src|yes|휴가 tools 가 src/ 를 담는다
leave|^COPY .*drizzle \./drizzle|yes|🔴 휴가 tools 가 drizzle/ 을 **담는다** — 0003·0004 가 이미지 안에 구워진다
leave|^COPY .*scripts \./scripts|yes|휴가 tools 가 scripts/ 를 담는다 (새 시험 아홉이 여기다)
meters|^COPY .*scripts \./scripts|yes|🔴 계측기 tools 가 scripts/ 를 담는다 — **send-notify.ts 가 여기다**
meters|^COPY .*src \./src|yes|🔴 계측기 tools 가 src/ 를 담는다 — **새 notify-send.ts 가 여기다**
'
COPYRULES_WANT=16

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-58"; fi
MIGTAR="$OUT/as-migrations.tar.gz"

case "$MODE" in
  --check|--go|--verify) ;;
  *) printf '쓰는 법: %s [--check|--go|--verify] [산출물폴더]\n' "$0"; exit 2 ;;
esac

printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' " 62-build.sh — 쉰여덟째 배포 · 이미지 굽기 ($MODE)"
printf '%s\n' "   저장소 뿌리 : $DEV"
printf '%s\n' "   산출물 자리 : $OUT"
printf '%s\n' "   굽는 것     : 이미지 $HOWMANY · 묶음 1 (A/S 전용)"
printf '%s\n' "══════════════════════════════════════════════════════════════"

# ══ 표를 읽는 길 ══════════════════════════════════════════════════════
#   🔴 **공백이 든 표(APPMARKS · TOOLMARKS · COPYRULES)는 tr -d ' ' 로 읽지
#      않는다** — 표식이 통째로 뭉개진다. 그 셋은 while IFS='|' read 로만 읽는다.
#   🔵 공백이 없는 표(REPOS · IMAGES · MIGS · CHANGED · NPMCMDS)는 61번처럼
#      tr -d ' ' 로 씻어서 읽어도 된다 — 그래도 같은 길로 읽어 둘을 안 섞는다.
rows_of() { printf '%s\n' "$1" | grep -v '^[[:space:]]*$'; }
field() { # 1 줄 2 칸번호
  printf '%s' "$1" | cut -d'|' -f"$2"
}
row_by_key() { # 1 표 2 열쇠 → 그 줄(없으면 빈 줄)
  rows_of "$1" | while IFS= read -r r; do
    [ "$(field "$r" 1)" = "$2" ] && printf '%s' "$r"
  done
}
# 한 저장소에서 「기준 SHA 때 그 글자가 든 src/ 파일 수」
# 🔴 pathspec 에 글롭이 든 경로를 넘기지 않는다 — src 하나만 넘긴다.
mark_was() { # 1 저장소 2 기준SHA 3 글자
  git -C "$1" grep -lF -- "$3" "$2" -- src 2>/dev/null | wc -l | tr -d ' '
}
mark_now() { # 1 저장소 2 글자
  grep -rlF -- "$2" "$1/src" 2>/dev/null | wc -l | tr -d ' '
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
    say "       & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./62-build.sh $MODE"
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

# ── 1-ㄴ. 🔴 **경로 번역이 정말 꺼졌는가** — 값으로 잰다 ──────────────
#   🔴 이 절이 없어서 첫 굽기에 **가짜 ✗ 일곱**이 났다. 번역이 켜져 있으면
#      아래 절들의 ✗ 가 **진짜 결함처럼 보인다.**
#   🔵 컨테이너가 하나 필요하다 — 아무 이미지나 쓴다(alpine 을 새로 받지 않는다).
say ""
say "── 1-ㄴ. 🔴 Git Bash 의 경로 번역이 꺼졌는가 (MSYS_NO_PATHCONV)"
PROBE_IMG=""
while IFS= read -r r; do
  [ -n "$r" ] || continue
  t=$(field "$r" 3)
  if docker image inspect "$t" >/dev/null 2>&1; then PROBE_IMG=$t; break; fi
  t2=$(field "$r" 5); t2=$(printf '%s' "${t2%.tar}" | sed 's/-\([0-9][0-9.]*\)$/:\1/')
  if docker image inspect "$t2" >/dev/null 2>&1; then PROBE_IMG=$t2; break; fi
done <<ENDPROBEIMG
$(rows_of "$IMAGES")
ENDPROBEIMG
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
    say "         & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./62-build.sh $MODE"
    say "      → 그래도 안 꺼지면 이 파일 맨 위의 MSYS_NO_PATHCONV 줄을 보세요."
  fi
fi

# ── 2. 저장소 여섯 ────────────────────────────────────────────────────
step "2. 저장소 여섯 — 깨끗한가 · 올라가 있나 · 범위가 맞나"
say "🔴 구운 이미지는 **그때 그 작업 폴더의 사진**입니다. 커밋 안 된 줄이 섞이면"
say "   나중에 같은 이미지를 다시 못 만듭니다."
REPO_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  K=$(field "$r" 1); F=$(field "$r" 2); N=$(field "$r" 3)
  B=$(field "$r" 4); WANTN=$(field "$r" 5); HASDB=$(field "$r" 7)
  D="$DEV/$F"
  REPO_SEEN=$((REPO_SEEN+1))
  printf '\n  ── %s (%s)\n' "$N" "$F"
  if [ ! -d "$D/.git" ]; then
    bad "$N — 저장소가 없다 ($D)"
    continue
  fi
  br=$(git -C "$D" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ "$br" = "main" ] && ok "$N 가지가 main 이다" || bad "$N 가지가 ${br:-못 읽음} 다 — main 이어야 한다"
  dirty=$(git -C "$D" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${dirty:-1}" = "0" ]; then ok "$N 미커밋 0줄"
  else
    bad "$N 에 미커밋이 ${dirty}줄 있다 — 굽기 전에 정리하세요"
    git -C "$D" status --porcelain=v1 2>/dev/null | head -8 | sed 's/^/        /'
  fi
  h=$(git -C "$D" rev-parse --short HEAD 2>/dev/null)
  o=$(git -C "$D" rev-parse --short origin/main 2>/dev/null)
  say "HEAD $h · origin/main ${o:-없음}"
  if [ -n "${o:-}" ] && [ "$h" = "$o" ]; then
    ok "$N main == origin/main (올라가 있다)"
  else
    ab=$(git -C "$D" rev-list --left-right --count main...origin/main 2>/dev/null)
    bad "$N main 과 origin/main 이 다르다 (왼쪽=안 올린 것 오른쪽=안 받은 것: ${ab:-못 읽음})"
    say "      🔴 **「미푸시 0」은 받았다는 뜻이 아닙니다** — 오른쪽 수도 보세요."
  fi
  if git -C "$D" cat-file -e "$B^{commit}" 2>/dev/null; then
    n=$(git -C "$D" rev-list --count "$B..main" 2>/dev/null)
    say "기준 $B..main 커밋 ${n:-못 읽음}개 (적어 둔 값 $WANTN)"
    if [ "${n:-x}" = "$WANTN" ]; then
      ok "$N 범위가 적어 둔 것과 같다 ($WANTN 커밋)"
    else
      note "$N 커밋이 ${n:-?}개다 — $WANTN 을 적어 두었다. **사람이 보세요**"
      say "      🔵 ⚠️ 로만 셉니다 — 그 사이에 하나 더 밀었을 수 있습니다."
      say "      🔴 그래도 **표식·파일 수 기대값이 전부 그 범위에서 나온 값**입니다."
    fi
  else
    bad "$N 기준 SHA $B 가 이 저장소에 없다 — 표가 틀렸다"
  fi
  say "DB: $(if [ "$HASDB" = yes ]; then printf '있다'; else printf '🔴 **없다 — 마이그레이션 검사는 해당 없음**'; fi)"
done <<ENDREPOS
$(rows_of "$REPOS")
ENDREPOS
if [ "$REPO_SEEN" = "$REPOS_WANT" ]; then
  ok "저장소 ${REPOS_WANT}곳을 다 봤다 (표본이 비지 않았다)"
else
  bad "저장소를 ${REPO_SEEN}곳만 봤다 — ${REPOS_WANT}곳을 기대했다. REPOS 표가 깨졌다"
fi

# ── 3. 🔴 서브모듈 ────────────────────────────────────────────────────
step "3. 🔴 서브모듈 — **포털에 처음 생겼고 A/S 의 dss-core 가 또 움직인다**"
pin_of() { git -C "$1" submodule status "$2" 2>/dev/null | awk '{print $1}' | tr -d '+-'; }
check_pin() { # 1 저장소폴더 2 서브모듈경로 3 기대 4 사람이 부르는 이름
  local p
  p=$(pin_of "$DEV/$1" "$2")
  if [ -z "${p:-}" ]; then
    bad "$4 의 $2 포인터를 못 읽었다 — 서브모듈이 없거나 init 이 안 됐다"
    return
  fi
  if [ "$p" = "$3" ]; then ok "$4 $2 = ${3:0:7} (맞다)"
  else
    bad "$4 $2 가 ${p:0:7} 다 — ${3:0:7} 을 기대했다"
    say "      🔴 포인터가 다르면 **구운 이미지의 스키마가 다른 판**입니다."
    doubt
  fi
}
# 3-ㄱ. 포인터 값
say "── 3-ㄱ. 포인터 값"
check_pin RF_Service_System vendor/dss-core "$AS_CORE_PIN" "A/S"
check_pin RF_Service_System vendor/dss-ui   "$UI_PIN"      "A/S"
check_pin dss-auth          vendor/dss-ui   "$UI_PIN"      "포털"
check_pin dss-approvals     vendor/dss-ui   "$UI_PIN"      "승인함"
check_pin dss-inventory     vendor/dss-ui   "$UI_PIN"      "재고관리"
check_pin dss-leave         vendor/dss-ui   "$UI_PIN"      "휴가"
check_pin njlee             vendor/dss-ui   "$UI_PIN"      "계측기"
say "🔵 dss-ui 는 **일곱째 판 연속 안 움직였습니다**(1210d11). 그래도 값으로 쟀습니다."

# 3-ㄴ. 🔴 공용 스키마 안에서 무엇이 바뀌었나 (55번 것을 61번이 되살렸고 또 쓴다)
say ""
say "── 3-ㄴ. 🔴 A/S 의 vendor/dss-core 안에서 **무엇이 바뀌었나**"
say "🔴 A/S 쪽 git diff 에는 **포인터 한 줄**로만 보입니다 — 안으로 들어가 셉니다."
COREDIR="$DEV/RF_Service_System/vendor/dss-core"
if [ -d "$COREDIR/.git" ] || [ -f "$COREDIR/.git" ]; then
  if git -C "$COREDIR" cat-file -e "$AS_CORE_WAS^{commit}" 2>/dev/null; then
    n=$(git -C "$COREDIR" rev-list --count "$AS_CORE_WAS..$AS_CORE_PIN" 2>/dev/null)
    say "커밋 ${n:-못 읽음}개 (기대 $AS_CORE_COMMITS_WANT)"
    git -C "$COREDIR" log --oneline "$AS_CORE_WAS..$AS_CORE_PIN" 2>/dev/null | sed 's/^/        /'
    [ "${n:-x}" = "$AS_CORE_COMMITS_WANT" ] && ok "dss-core 가 $AS_CORE_COMMITS_WANT 커밋 움직였다" \
      || bad "dss-core 커밋이 ${n:-?}개다 — $AS_CORE_COMMITS_WANT 을 기대했다"
    f=$(git -C "$COREDIR" diff --name-only "$AS_CORE_WAS..$AS_CORE_PIN" 2>/dev/null | wc -l | tr -d ' ')
    git -C "$COREDIR" diff --name-status "$AS_CORE_WAS..$AS_CORE_PIN" 2>/dev/null | sed 's/^/        /'
    [ "${f:-x}" = "$AS_CORE_FILES_WANT" ] && ok "바뀐 파일 $AS_CORE_FILES_WANT 장" \
      || bad "바뀐 파일이 ${f:-?}장이다 — $AS_CORE_FILES_WANT 을 기대했다"
  else
    unk "dss-core 범위" "옛 포인터 ${AS_CORE_WAS:0:7} 가 그 저장소에 없다"
  fi
  # 🔴 **새 스키마가 표 이름을 적는가 · index.ts 가 내보내는가** (55번의 그 절)
  if [ -f "$COREDIR/$AS_CORE_NEW_SCHEMA" ]; then
    ok "새 스키마 파일이 작업본에 있다 ($AS_CORE_NEW_SCHEMA)"
    n=$(grep -cF "$AS_CORE_TABLE" "$COREDIR/$AS_CORE_NEW_SCHEMA" 2>/dev/null || true)
    if isnum "${n:-}" && [ "${n:-0}" -ge 1 ]; then
      ok "그 파일이 표 이름 $AS_CORE_TABLE 을 적는다 (${n}줄)"
    else
      bad "그 파일에 표 이름 $AS_CORE_TABLE 이 없다 — 다른 것을 보고 있다"
    fi
  else
    bad "새 스키마 파일이 **작업본에 없다** — 🔴 포인터만 맞고 **파일이 옛것**이다"
    say "      🔴 그대로 구우면 **옛 스키마가 담긴 도구 이미지**가 됩니다."
    say "      → git -C \"$DEV/RF_Service_System\" submodule update --init --recursive"
  fi
  n=$(grep -c 'portal-approval-delegations' "$COREDIR/src/schema/index.ts" 2>/dev/null || true)
  if isnum "${n:-}" && [ "${n:-0}" -ge 1 ]; then
    ok "index.ts 가 새 스키마를 **내보낸다**"
    say "      🔵 안 내보내면 도구가 @dss/core/schema 에서 그 표를 **못 찾습니다**"
    say "         — 2026-09-21 에 운영에서 도구가 전부 죽은 그 자리입니다."
  else
    bad "index.ts 가 새 스키마를 안 내보낸다 — Cannot find export 가 난다"
  fi
else
  bad "vendor/dss-core 가 **비어 있다**(.git 이 없다) — submodule update --init 이 필요하다"
fi

# 3-ㄷ. 🔴 포털에 처음 생긴 서브모듈 (①)
say ""
say "── 3-ㄷ. 🔴 **포털에 서브모듈이 처음 생겼다** — 지금까지 없던 절이다"
AUTHDIR="$DEV/dss-auth"
AUTHUI="$AUTHDIR/vendor/dss-ui"
if [ -f "$AUTHDIR/.gitmodules" ]; then
  ok ".gitmodules 가 있다 (이번 판이 만든 **새 파일**이다)"
  n=$(grep -c 'vendor/dss-ui' "$AUTHDIR/.gitmodules" 2>/dev/null || true)
  [ "${n:-0}" -ge 1 ] 2>/dev/null && ok ".gitmodules 가 vendor/dss-ui 를 적는다" \
    || bad ".gitmodules 에 vendor/dss-ui 가 없다"
else
  bad "포털에 .gitmodules 가 없다 — 🔴 이번 판은 그 파일이 **새로 생긴 판**이다"
fi
if [ -d "$AUTHUI/src" ]; then
  n=$(ls -1 "$AUTHUI/src" 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then
    ok "포털의 vendor/dss-ui 작업본이 체크아웃돼 있다 (src 안 ${n}개)"
  else
    bad "포털의 vendor/dss-ui/src 가 비었다 — **빈 서브모듈**이다"
  fi
  n=$(grep -c "$AUTH_UI_EXPORT" "$AUTHUI/src/index.ts" 2>/dev/null || true)
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then
    ok "dss-ui 의 index.ts 가 $AUTH_UI_EXPORT 을 내보낸다 (${n}줄)"
  else
    bad "dss-ui 의 index.ts 가 $AUTH_UI_EXPORT 을 안 내보낸다 — 포털의 종이 안 선다"
  fi
else
  bad "포털의 vendor/dss-ui 가 **비어 있다** — 🔴 그대로 구우면 **npm run build 가 죽는다**"
  say "      🔴 포털의 tsconfig 가 @dss/ui 를 $AUTH_TSCONFIG_PATH 로 풉니다."
  say "      → git -C \"$AUTHDIR\" submodule update --init --recursive"
fi
n=$(grep -cF "$AUTH_TSCONFIG_PATH" "$AUTHDIR/tsconfig.json" 2>/dev/null || true)
if [ "${n:-0}" -ge 1 ] 2>/dev/null; then
  ok "포털 tsconfig 의 paths 가 vendor/dss-ui 를 가리킨다"
else
  bad "포털 tsconfig 에 그 paths 가 없다 — 검사의 전제가 틀렸다. 사람이 보세요"
  doubt
fi
# 🔴 .dockerignore 가 vendor 를 막고 있지 않은가 — 막으면 builder 가 못 본다.
n=$(grep -c '^vendor' "$AUTHDIR/.dockerignore" 2>/dev/null || true)
if [ "${n:-0}" = "0" ]; then
  ok "포털 .dockerignore 가 vendor/ 를 **안 막는다** (COPY . . 가 담는다)"
else
  bad "포털 .dockerignore 가 vendor 를 막는다 — 🔴 @dss/ui 가 이미지에 안 들어간다"
fi

# 3-ㄹ. 모든 서브모듈 작업본이 비지 않았고 깨끗한가
say ""
say "── 3-ㄹ. 서브모듈 작업본 일곱 — 비지 않았나 · 미커밋 0 인가"
SUB_SEEN=0
check_sub() { # 1 폴더 2 이름
  SUB_SEEN=$((SUB_SEEN+1))
  local n d
  n=$(ls -1 "$1" 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -ge 3 ] 2>/dev/null; then ok "$2 작업본에 파일이 ${n}개 있다"
  else bad "$2 작업본이 비었다(${n:-?}개) — submodule update --init 이 필요하다"; fi
  d=$(git -C "$1" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${d:-1}" = "0" ]; then ok "$2 미커밋 0줄"
  else bad "$2 에 미커밋이 ${d}줄 있다 — 🔴 서브모듈 안을 고치지 마세요"; fi
}
check_sub "$COREDIR"                          "A/S-core"
check_sub "$DEV/RF_Service_System/vendor/dss-ui" "A/S-ui"
check_sub "$AUTHUI"                           "포털-ui"
check_sub "$DEV/dss-approvals/vendor/dss-ui"  "승인함-ui"
check_sub "$DEV/dss-inventory/vendor/dss-ui"  "재고-ui"
check_sub "$DEV/dss-leave/vendor/dss-ui"      "휴가-ui"
check_sub "$DEV/njlee/vendor/dss-ui"          "계측기-ui"
[ "$SUB_SEEN" = "7" ] && ok "서브모듈 작업본 일곱을 다 봤다 (표본이 비지 않았다)" \
  || bad "서브모듈을 ${SUB_SEEN}개만 봤다 — 7개를 기대했다"

# ── 4. 🔴 마이그레이션 — **네 집에 일곱 건 · 한 집은 해당 없음** ─────
step "4. 🔴 마이그레이션 — 네 집에 일곱 건 (승인함은 **해당 없음**)"

# 4-ㄱ. 🔴 **잣대가 살아 있는가를 먼저 잰다** — 표본 다섯
say "── 4-ㄱ. 🔴 지우는 문장 잣대가 **살아 있는가** (표본 다섯으로 먼저 잰다)"
say "🔴 표본이 비어서 공짜로 통과하는 일을 막는 절입니다. 잣대가 죽어 있으면"
say "   아래 「지우는 문장 0줄」이 **아무것도 안 재는 ✓** 가 됩니다."
probe_destructive() { # 1 글 2 기대(hit|miss) 3 이름
  local n
  n=$(printf '%s\n' "$1" | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
  case "$2" in
    hit)  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then ok "잣대가 $3 를 **잡는다**"; else bad "잣대가 $3 를 **못 잡는다** — 잣대가 죽었다"; fi ;;
    miss) if [ "${n:-1}" = "0" ]; then ok "잣대가 $3 를 **안 센다** (맞다)"; else bad "잣대가 $3 를 **센다** — 멀쩡한 판이 ✗ 가 된다"; fi ;;
  esac
}
probe_destructive 'DROP TABLE "x";'                          hit  "DROP TABLE"
probe_destructive 'TRUNCATE "x";'                            hit  "TRUNCATE"
probe_destructive 'DELETE FROM "x" WHERE id = 1;'            hit  "DELETE FROM"
probe_destructive '-- DELETE FROM "x" 는 안 한다'            miss "주석 속 DELETE FROM"
probe_destructive 'FOREIGN KEY ("a") REFERENCES "b"("id") ON DELETE restrict;' miss "FK 의 ON DELETE restrict"
probe_destructive 'UPDATE "x" SET updated_by = NULL;'        miss "UPDATE (칸 이름 updated_by)"
say "🔵 마지막 둘이 **이번 판의 실물**입니다 — 일곱 중 넷에 ON DELETE 가 있고"
say "   표 넷 전부에 updated_at/synced_at 류 칸이 있습니다."

# 4-ㄴ. 집마다 .sql 수 · journal 수
say ""
say "── 4-ㄴ. 집마다 drizzle/ 을 센다 (.sql 수 == meta/_journal.json 의 idx 수)"
MIG_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  K=$(field "$r" 1); WANT=$(field "$r" 2); PROD=$(field "$r" 3)
  NEWN=$(field "$r" 4); LAST=$(field "$r" 5); NEXT=$(field "$r" 6); WHERE=$(field "$r" 7)
  rr=$(row_by_key "$REPOS" "$K"); F=$(field "$rr" 2); N=$(field "$rr" 3)
  D="$DEV/$F"
  MIG_SEEN=$((MIG_SEEN+1))
  printf '\n  ── %s (%s · 도는 자리 %s)\n' "$N" "$F" "$WHERE"
  if [ "$WHERE" = "none" ]; then
    # 🔴 ④ — DB 가 아예 없는 집. 다른 다섯과 **같은 점검을 돌리면 안 된다.**
    if [ -d "$D/drizzle" ]; then
      bad "🔴 $N 에 drizzle/ 폴더가 **생겼다** — 이 집은 DB 가 없다는 전제가 깨졌다"
      say "      🔴 멈추고 알리세요. 이 배포본은 승인함에 **마이그레이션 절이 없습니다.**"
    else
      ok "$N 은 drizzle/ 폴더가 **없다** — 🔴 「0건」이 아니라 **해당 없음**이다"
      say "      🔵 그래서 이 집에는 .sql 세기도 _journal.json 검사도 **안 돌립니다.**"
      say "      🔵 62-deploy.sh 도 이 집에서는 DB 절을 통째로 건너뜁니다."
    fi
    continue
  fi
  v=$(count_drizzle "$D"); s=$(printf '%s' "$v" | awk '{print $1}'); j=$(printf '%s' "$v" | awk '{print $2}')
  say ".sql ${s}장 · journal idx ${j}개 (기대 $WANT · $WANT) · 운영은 지금 $PROD · 새것 $NEWN"
  if [ "${s:-x}" = "$WANT" ] && [ "${j:-x}" = "$WANT" ]; then
    ok "$N drizzle/ 이 ${WANT}장이고 목록도 ${WANT}개다"
  else
    bad "$N 이 .sql ${s:-?} · idx ${j:-?} 다 — ${WANT}·${WANT} 를 기대했다"
    say "      🔴 목록에 없는 .sql 은 drizzle 이 **아예 모르고** 적용이 0건으로 끝납니다."
  fi
  if [ "$NEWN" = "0" ]; then
    n=$(git -C "$D" diff --name-only "$(field "$rr" 4)..main" -- drizzle 2>/dev/null | wc -l | tr -d ' ')
    if [ "${n:-1}" = "0" ]; then ok "$N 은 이번 범위에 drizzle 변경이 **0줄**이다 (올릴 것이 없다)"
    else bad "$N 에 drizzle 변경이 ${n}줄 있다 — 0 을 기대했다. 표가 틀렸다"; fi
    continue
  fi
  # 🔴 그 다음 번호가 생겼으면 전제가 깨진 것이다
  nx=$(ls -1 "$D/drizzle/${NEXT}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  if [ "${nx:-1}" = "0" ]; then ok "$N 의 마지막이 $LAST 다 ($NEXT 이 없다 — 적용 대기 ${NEWN}건)"
  else bad "$N 에 $NEXT 이 **생겼다** — 이 배포본은 $LAST 까지를 전제로 쓰였다. 멈추고 알릴 것"; fi
done <<ENDMIGS
$(rows_of "$MIGS")
ENDMIGS
[ "$MIG_SEEN" = "$REPOS_WANT" ] && ok "집 ${REPOS_WANT}곳의 마이그레이션 자리를 다 봤다" \
  || bad "마이그레이션을 ${MIG_SEEN}곳만 봤다 — ${REPOS_WANT}곳을 기대했다"

# 4-ㄷ. 🔴 새로 생긴 일곱 — 이름까지 맞고 · 지우는 문장이 0 인가
say ""
say "── 4-ㄷ. 🔴 **새로 생긴 일곱** — 이름이 그 이름인가 · 지우는 문장이 0 인가"
NEWMIG_SEEN=0; NEWMIG_OK=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  K=$(field "$r" 1); FILES=$(field "$r" 2)
  rr=$(row_by_key "$REPOS" "$K"); F=$(field "$rr" 2); N=$(field "$rr" 3); B=$(field "$rr" 4)
  D="$DEV/$F"
  for m in $FILES; do
    NEWMIG_SEEN=$((NEWMIG_SEEN+1))
    P="$D/drizzle/$m"
    if [ ! -f "$P" ]; then
      bad "$N — $m 이 **없다**(이름이 다르거나 안 생겼다)"
      continue
    fi
    # 🔴 그 파일이 정말 **이번 범위에서 새로 생긴 것**인가
    added=$(git -C "$D" diff --diff-filter=A --name-only "$B..main" -- drizzle 2>/dev/null | tr -d '\r' | grep -cFx "drizzle/$m" || true)
    raw=$(grep -ciE "$DESTRUCTIVE_RE" "$P" 2>/dev/null || true)
    net=$(grep -v "$SQL_COMMENT_RE" "$P" 2>/dev/null | grep -ciE "$DESTRUCTIVE_RE" || true)
    ct=$(grep -v "$SQL_COMMENT_RE" "$P" 2>/dev/null | grep -c 'CREATE TABLE' || true)
    ix=$(grep -v "$SQL_COMMENT_RE" "$P" 2>/dev/null | grep -c 'CREATE INDEX' || true)
    ins=$(grep -v "$SQL_COMMENT_RE" "$P" 2>/dev/null | grep -c 'INSERT INTO' || true)
    alt=$(grep -v "$SQL_COMMENT_RE" "$P" 2>/dev/null | grep -c 'ALTER TYPE' || true)
    ond=$(grep -cF 'ON DELETE' "$P" 2>/dev/null || true)
    printf '      %-44s 새파일 %s · 지우는문장 날것 %s/걷은뒤 %s · CREATE TABLE %s · CREATE INDEX %s · INSERT %s · ALTER TYPE %s · (참고)ON DELETE %s줄\n' \
      "$m" "${added:-0}" "${raw:-?}" "${net:-?}" "${ct:-?}" "${ix:-?}" "${ins:-?}" "${alt:-?}" "${ond:-?}"
    if [ "${added:-0}" != "1" ]; then
      bad "$N — $m 이 이번 범위의 **새 파일이 아니다**(git 이 A 로 안 센다)"
      continue
    fi
    if [ "${net:-x}" != "$MIG_DROP_WANT" ]; then
      bad "$N — $m 에 지우는 문장이 ${net}줄 있다 — 0 을 기대했다. **사람이 보세요**"
      continue
    fi
    if [ "${ins:-1}" != "0" ]; then
      note "$N — $m 에 INSERT 가 ${ins}줄 있다 (자료를 넣는 판이다 — 사람이 보세요)"
    fi
    NEWMIG_OK=$((NEWMIG_OK+1))
  done
done <<ENDNEWMIG
$(rows_of "$NEW_MIG_FILES")
ENDNEWMIG
say "본 것 ${NEWMIG_SEEN}장 · 통과 ${NEWMIG_OK}장 (기대 $NEW_MIG_FILES_WANT · $NEW_MIG_FILES_WANT)"
if [ "$NEWMIG_SEEN" = "$NEW_MIG_FILES_WANT" ] && [ "$NEWMIG_OK" = "$NEW_MIG_FILES_WANT" ]; then
  ok "새 마이그레이션 ${NEW_MIG_FILES_WANT}장이 전부 **더하기만 한다** (지우는 문장 0)"
  say "      🔵 넷에 ON DELETE 가 있지만 **FK 구절**이라 안 셉니다 — 앱의 migration-safety 와 같은 잣대입니다."
else
  bad "본 것 ${NEWMIG_SEEN} · 통과 ${NEWMIG_OK} 다 — ${NEW_MIG_FILES_WANT}/${NEW_MIG_FILES_WANT} 를 기대했다"
fi

# 4-ㄹ. 🔴 포털 0010 의 ALTER TYPE ADD VALUE 둘 — **같은 판에서 그 값을 쓰지 않는가**
say ""
say "── 4-ㄹ. 🔴 포털 0010 의 **ALTER TYPE … ADD VALUE** — 한 트랜잭션 함정"
say "🔴 drizzle 은 밀린 마이그레이션을 **한 트랜잭션**에 넣습니다. 새 enum 값을"
say "   **같은 트랜잭션에서 쓰면** PostgreSQL 이 55P04(unsafe use of new value)로"
say "   거절합니다 — 그러면 그 판은 쪼개도 안 넘어갑니다."
AUTH0010="$DEV/dss-auth/drizzle/0010_giant_victor_mancha.sql"
if [ -f "$AUTH0010" ]; then
  add=$(grep -c 'ALTER TYPE' "$AUTH0010" 2>/dev/null || true)
  use1=$(grep -c "DELEGATION_CREATED" "$AUTH0010" 2>/dev/null || true)
  use2=$(grep -c "DELEGATION_REVOKED" "$AUTH0010" 2>/dev/null || true)
  ins=$(grep -c 'INSERT INTO' "$AUTH0010" 2>/dev/null || true)
  say "ALTER TYPE ${add:-?}줄 · DELEGATION_CREATED ${use1:-?}줄 · DELEGATION_REVOKED ${use2:-?}줄 · INSERT ${ins:-?}줄"
  if [ "${add:-0}" = "2" ] && [ "${use1:-0}" = "1" ] && [ "${use2:-0}" = "1" ] && [ "${ins:-1}" = "0" ]; then
    ok "새 enum 값 둘은 **ALTER TYPE 줄에서만** 나온다 (같은 판에서 안 쓴다 — 안전하다)"
    say "      🔵 포털은 **밀린 것이 0010 하나**라 트랜잭션 안에 다른 판이 섞이지도 않습니다."
  else
    bad "0010 의 모양이 기대와 다르다 — ALTER 2 · 각 값 1줄 · INSERT 0 을 기대했다"
    say "      🔴 새 값을 같은 판에서 쓰면 **적용이 그 자리에서 멈춥니다.** 사람이 보세요."
    doubt
  fi
  # 🔴 그 뒤에 또 마이그레이션이 생겼으면 한 트랜잭션에 둘이 들어간다
  nx=$(ls -1 "$DEV/dss-auth/drizzle/0011"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  [ "${nx:-1}" = "0" ] && ok "포털에 0011 이 없다 (트랜잭션에 0010 하나만 들어간다)" \
    || bad "포털에 0011 이 생겼다 — 🔴 **새 enum 값을 그 판이 쓰면 멈춘다.** 사람이 보세요"
else
  bad "포털 0010 을 못 읽었다 ($AUTH0010)"
fi

# 4-ㅁ. 🔴 A/S 창 일곱 — 묶음을 통째로 갈아 끼우므로 창 안을 다 본다
say ""
say "── 4-ㅁ. 🔵 A/S 창 일곱($AS_KEEP_MIGS) — .sql 과 스냅샷이 짝으로 있는가"
KEEP_MISS=""
KEEP_SEEN=0
for t in $AS_KEEP_MIGS; do
  KEEP_SEEN=$((KEEP_SEEN+1))
  a=$(ls -1 "$DEV/RF_Service_System/drizzle/${t}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  b=$(ls -1 "$DEV/RF_Service_System/drizzle/meta/${t}"_snapshot.json 2>/dev/null | wc -l | tr -d ' ')
  printf '      %-6s .sql %s · 스냅샷 %s\n' "$t" "${a:-0}" "${b:-0}"
  [ "${a:-0}" -ge 1 ] 2>/dev/null || KEEP_MISS="$KEEP_MISS $t(sql)"
  [ "${b:-0}" -ge 1 ] 2>/dev/null || KEEP_MISS="$KEEP_MISS $t(snapshot)"
done
if [ "$KEEP_SEEN" = "$AS_KEEP_MIGS_WANT" ] && [ -z "${KEEP_MISS:-}" ]; then
  ok "창 안 ${AS_KEEP_MIGS_WANT}장이 .sql 과 스냅샷을 다 갖췄다"
else
  bad "본 것 ${KEEP_SEEN}장 · 빠진 것:${KEEP_MISS:- 없음} (${AS_KEEP_MIGS_WANT}장을 기대했다)"
fi

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 담는 길 · 굽는 까닭 · 소스가 새 코드를 담고 있나 ────────────
# ══════════════════════════════════════════════════════════════════════
step "5. 🔴 담는 길 · 굽는 까닭 · 소스가 새 코드를 담고 있나"

# 5-ㄱ. Dockerfile 이 담는 길 — **굽는 까닭이 여기 있다**
say "── 5-ㄱ. Dockerfile 의 COPY 줄 — 🔴 **같은 글자가 집마다 반대 뜻이다**"
COPY_SEEN=0
while IFS='|' read -r K RE WANT MSG; do
  [ -n "${K:-}" ] || continue
  rr=$(row_by_key "$REPOS" "$K"); F=$(field "$rr" 2)
  DF="$DEV/$F/Dockerfile"
  COPY_SEEN=$((COPY_SEEN+1))
  if [ ! -f "$DF" ]; then bad "$F 의 Dockerfile 이 없다"; continue; fi
  n=$(grep -cE "$RE" "$DF" 2>/dev/null || true)
  ln=$(grep -nE "$RE" "$DF" 2>/dev/null | head -1 | cut -d: -f1)
  if [ "$WANT" = "yes" ]; then
    if [ "${n:-0}" -ge 1 ] 2>/dev/null; then ok "$MSG (${ln:-?}줄)"
    else bad "$F 의 Dockerfile 에 그 COPY 가 **없다** — $MSG"; doubt; fi
  else
    if [ "${n:-1}" = "0" ]; then ok "$MSG"
    else bad "$F 의 Dockerfile 에 그 COPY 가 **있다**(${ln}줄) — $MSG"; doubt; fi
  fi
done <<ENDCOPY
$(rows_of "$COPYRULES")
ENDCOPY
[ "$COPY_SEEN" = "$COPYRULES_WANT" ] && ok "COPY 규칙 ${COPYRULES_WANT}줄을 다 봤다 (표본이 비지 않았다)" \
  || bad "COPY 규칙을 ${COPY_SEEN}줄만 봤다 — ${COPYRULES_WANT}줄을 기대했다. 표가 깨졌다"

# 5-ㄴ. 🔴 승인함에는 tools 스테이지가 **없다** (④)
say ""
say "── 5-ㄴ. 🔴 승인함의 Dockerfile — **tools 스테이지가 없는 것이 정상**"
APDF="$DEV/dss-approvals/Dockerfile"
if [ -f "$APDF" ]; then
  n=$(grep -cE '^FROM .* AS tools' "$APDF" 2>/dev/null || true)
  st=$(grep -cE '^FROM ' "$APDF" 2>/dev/null || true)
  say "FROM 줄 ${st:-?}개 (기대 3 — deps · build · runner) · AS tools ${n:-?}개 (기대 0)"
  if [ "${n:-1}" = "0" ] && [ "${st:-0}" = "3" ]; then
    ok "승인함에 tools 스테이지가 **없다** — 🔴 --target tools 를 주면 그 자리에서 굽기가 실패한다"
    say "      🔵 그래서 IMAGES 표의 승인함 줄은 타깃이 **-** 입니다."
  else
    bad "승인함 Dockerfile 의 스테이지 모양이 다르다 (FROM ${st:-?} · tools ${n:-?})"
    say "      🔴 tools 가 생겼으면 이 배포본의 전제가 깨진 것입니다. 멈추고 알리세요."
  fi
else
  bad "승인함 Dockerfile 을 못 읽었다"
fi

# 5-ㄷ. .dockerignore 가 .next 를 막는가 (여섯 집)
say ""
say "── 5-ㄷ. .dockerignore 가 .next 를 막는가 — 막아야 dev 서버를 안 내려도 된다"
DI_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  F=$(field "$r" 2); N=$(field "$r" 3)
  DI="$DEV/$F/.dockerignore"
  DI_SEEN=$((DI_SEEN+1))
  if [ ! -f "$DI" ]; then bad "$N 에 .dockerignore 가 없다 — 🔴 호스트의 .next 가 섞여 들어간다"; continue; fi
  n=$(grep -c '^\.next' "$DI" 2>/dev/null || true)
  [ "${n:-0}" -ge 1 ] 2>/dev/null && ok "$N .dockerignore 가 .next 를 막는다" \
    || bad "$N .dockerignore 가 .next 를 **안 막는다** — dev 서버를 내리고 구워야 한다"
done <<ENDDI
$(rows_of "$REPOS")
ENDDI
[ "$DI_SEEN" = "$REPOS_WANT" ] && ok ".dockerignore 를 여섯 집에서 다 봤다" \
  || bad ".dockerignore 를 ${DI_SEEN}집만 봤다"

# 5-ㄹ. npm 명령 수 — 굽는 까닭 ㄱ
say ""
say "── 5-ㄹ. npm 명령 수 (scripts 블록 안만) — 굽는 까닭 ㄱ 이 걸리는가"
NPM_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  K=$(field "$r" 1); WAS=$(field "$r" 2); NOW=$(field "$r" 3)
  rr=$(row_by_key "$REPOS" "$K"); F=$(field "$rr" 2); N=$(field "$rr" 3); B=$(field "$rr" 4)
  D="$DEV/$F"
  NPM_SEEN=$((NPM_SEEN+1))
  a=$(git -C "$D" show "$B:package.json" 2>/dev/null | count_scripts)
  b=$(count_scripts < "$D/package.json")
  printf '      %-10s 기준 %-3s → 지금 %-3s (적어 둔 값 %s → %s)\n' "$N" "${a:-?}" "${b:-?}" "$WAS" "$NOW"
  if [ "${a:-x}" = "$WAS" ] && [ "${b:-x}" = "$NOW" ]; then
    if [ "$WAS" = "$NOW" ]; then ok "$N npm 명령이 안 늘었다 (ㄱ 잣대가 안 걸린다)"
    else ok "$N npm 명령이 $WAS → $NOW 로 늘었다 (🔴 **ㄱ 잣대가 걸린다 — 도구를 굽는다**)"; fi
  else
    bad "$N npm 명령이 ${a:-?} → ${b:-?} 다 — $WAS → $NOW 를 기대했다"
    doubt
  fi
done <<ENDNPM
$(rows_of "$NPMCMDS")
ENDNPM
[ "$NPM_SEEN" = "$REPOS_WANT" ] && ok "npm 명령 수를 여섯 집에서 다 봤다" \
  || bad "npm 명령 수를 ${NPM_SEEN}집만 봤다"

# 5-ㅁ. 🔴 heic2any — ⑥. 의존성이 늘었다
say ""
say "── 5-ㅁ. 🔴 A/S 에 npm 의존성이 하나 늘었다 (⑥) — **이미지가 커진다**"
ASPKG="$DEV/RF_Service_System/package.json"
n=$(grep -c '"heic2any"' "$ASPKG" 2>/dev/null || true)
w=$(git -C "$DEV/RF_Service_System" show 70ec2173:package.json 2>/dev/null | grep -c '"heic2any"' || true)
say "package.json 의 heic2any — 기준 ${w:-?}줄 → 지금 ${n:-?}줄 (기대 0 → 1)"
if [ "${w:-x}" = "0" ] && [ "${n:-x}" = "1" ]; then
  ok "heic2any 가 **이번 판에 더해졌다** (dependencies 한 줄)"
  say "      🔴 그래서 A/S 두 줄만 tar 크기 견주기를 **loose** 로 풀었습니다."
  say "      🔵 번들에서는 1.35MB 지만 **도구 이미지는 node_modules 를 통째로 담습니다.**"
else
  note "heic2any 가 기준 ${w:-?} → 지금 ${n:-?} 다 — 0 → 1 을 기대했다. 사람이 보세요"
fi
# 🔴 **늦게 받는가** — src 어디에도 정적 import 가 없어야 한다(저장소 쪽 시험이 지키는 규율).
st=$(grep -rn 'from "heic2any"' "$DEV/RF_Service_System/src" 2>/dev/null | wc -l | tr -d ' ')
dy=$(grep -rn 'import("heic2any")' "$DEV/RF_Service_System/src" 2>/dev/null | wc -l | tr -d ' ')
say "src/ 의 heic2any — 정적 import ${st:-?}줄(기대 0) · await import ${dy:-?}줄(기대 1 이상)"
if [ "${st:-1}" = "0" ] && [ "${dy:-0}" -ge 1 ] 2>/dev/null; then
  ok "heic2any 를 **늦게 받는다** (첫 화면 번들이 1.35MB 안 늘어난다)"
else
  note "heic2any 를 정적으로 받는 줄이 ${st:-?}개다 — 사람이 보세요 (판정은 안 막습니다)"
fi

# 5-ㅂ. 바뀐 파일 수 — 집마다
say ""
say "── 5-ㅂ. 바뀐 파일 수 — 집마다 (🔴 **지운 파일은 여섯 다 0 이어야 한다**)"
CH_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  K=$(field "$r" 1); WALL=$(field "$r" 2); WSRC=$(field "$r" 3); WSCR=$(field "$r" 4)
  WDRZ=$(field "$r" 5); WVEN=$(field "$r" 6); WNEW=$(field "$r" 7); WDEL=$(field "$r" 8)
  WPAR=$(field "$r" 9)
  rr=$(row_by_key "$REPOS" "$K"); F=$(field "$rr" 2); N=$(field "$rr" 3); B=$(field "$rr" 4)
  D="$DEV/$F"
  CH_SEEN=$((CH_SEEN+1))
  # 🔴 pathspec 에 글롭이 든 경로를 넘기지 않는다 — 목록을 한 번 뽑아 두고 센다.
  LIST=$(git -C "$D" diff --name-only "$B..main" 2>/dev/null | tr -d '\r')
  all=$(printf '%s\n' "$LIST" | grep -c . || true)
  src=$(printf '%s\n' "$LIST" | grep -c '^src/' || true)
  scr=$(printf '%s\n' "$LIST" | grep -c '^scripts/' || true)
  drz=$(printf '%s\n' "$LIST" | grep -c '^drizzle/' || true)
  ven=$(printf '%s\n' "$LIST" | grep -cE '^(vendor/|\.gitmodules)' || true)
  par=$(printf '%s\n' "$LIST" | grep -cF '(' || true)
  new=$(git -C "$D" diff --diff-filter=A --name-only "$B..main" 2>/dev/null | grep -c . || true)
  del=$(git -C "$D" diff --diff-filter=D --name-only "$B..main" 2>/dev/null | grep -c . || true)
  printf '      %-10s 전체 %-4s src %-4s scripts %-3s drizzle %-2s vendor %-2s 새 %-3s 지움 %-2s 괄호 %s\n' \
    "$N" "${all:-?}" "${src:-?}" "${scr:-?}" "${drz:-?}" "${ven:-?}" "${new:-?}" "${del:-?}" "${par:-?}"
  printf '      %-10s (적어 둔 값) %-4s     %-4s         %-3s         %-2s        %-2s    %-3s      %-2s      %s\n' \
    "" "$WALL" "$WSRC" "$WSCR" "$WDRZ" "$WVEN" "$WNEW" "$WDEL" "$WPAR"
  if [ "${all:-x}" = "$WALL" ] && [ "${src:-x}" = "$WSRC" ] && [ "${scr:-x}" = "$WSCR" ] \
     && [ "${drz:-x}" = "$WDRZ" ] && [ "${ven:-x}" = "$WVEN" ] && [ "${new:-x}" = "$WNEW" ] \
     && [ "${par:-x}" = "$WPAR" ]; then
    ok "$N 바뀐 파일 수가 적어 둔 것과 전부 같다"
  else
    note "$N 바뀐 파일 수가 적어 둔 것과 다르다 — **사람이 보세요**"
    say "      🔵 커밋이 하나 더 밀렸으면 여기가 먼저 어긋납니다(2절의 ⚠️ 와 짝입니다)."
  fi
  if [ "${del:-1}" = "$WDEL" ]; then ok "$N 지운 파일 ${WDEL}장"
  else bad "🔴 $N 이 파일을 ${del}장 **지웠다** — 0 을 기대했다. 멈추고 알릴 것"; fi
done <<ENDCH
$(rows_of "$CHANGED")
ENDCH
[ "$CH_SEEN" = "$REPOS_WANT" ] && ok "바뀐 파일 수를 여섯 집에서 다 봤다" \
  || bad "바뀐 파일 수를 ${CH_SEEN}집만 봤다"
say "🔴 **괄호가 든 경로가 다섯 집에 살아 있습니다**(A/S 6 · 승인함 2 · 재고 2 · 휴가 2 · 계측기 1)."
say "   git 의 pathspec 은 글롭이라 그 경로로 물으면 **조용히 0줄**이 돌아옵니다 —"
say "   이 파일은 목록을 **한 번만 뽑아 두고** grep 으로 셉니다."

# 5-ㅅ. 🔴 표식이 소스에서 기대한 수인가 (앱 번들 검사가 설 바탕)
say ""
say "── 5-ㅅ. 🔴 표식 — **소스에서 먼저 센다** (기능 0→N · 뒷걸음 N→N)"
MK_SEEN=0
while IFS='|' read -r K MK KEEPMK NOTE1; do
  [ -n "${K:-}" ] || continue
  rr=$(row_by_key "$REPOS" "$K"); F=$(field "$rr" 2); N=$(field "$rr" 3); B=$(field "$rr" 4)
  D="$DEV/$F"
  MK_SEEN=$((MK_SEEN+1))
  a=$(mark_was "$D" "$B" "$MK"); b=$(mark_now "$D" "$MK")
  c=$(mark_was "$D" "$B" "$KEEPMK"); d=$(mark_now "$D" "$KEEPMK")
  printf '      %-10s 기능 [%s] 기준 %-3s → 지금 %-3s   | 뒷걸음 [%s] 기준 %-3s → 지금 %s\n' \
    "$N" "$MK" "${a:-?}" "${b:-?}" "$KEEPMK" "${c:-?}" "${d:-?}"
  if [ "${a:-x}" = "0" ] && [ "${b:-0}" -ge 1 ] 2>/dev/null; then
    ok "$N 기능 표식이 **이번 판에만 있다** ($NOTE1)"
  else
    bad "$N 기능 표식이 기준 ${a:-?} → 지금 ${b:-?} 다 — 0 → 1 이상을 기대했다"
    say "      🔴 기준판에도 있으면 그 표식은 **아무것도 안 가릅니다.**"
    doubt
  fi
  if [ "${c:-0}" -ge 1 ] 2>/dev/null && [ "${d:-0}" -ge 1 ] 2>/dev/null; then
    ok "$N 뒷걸음 표식이 기준에도 지금에도 있다 (뒷걸음을 잴 수 있다)"
  else
    bad "$N 뒷걸음 표식이 기준 ${c:-?} · 지금 ${d:-?} 다 — 둘 다 1 이상이어야 한다"
    doubt
  fi
done <<ENDMK
$(rows_of "$APPMARKS")
ENDMK
[ "$MK_SEEN" = "$REPOS_WANT" ] && ok "표식을 여섯 집에서 다 봤다 (표본이 비지 않았다)" \
  || bad "표식을 ${MK_SEEN}집만 봤다"

# 5-ㅇ. 🔴 도구 이미지가 쓸 **마지막 커밋 표식** — 소스에서 먼저 센다
say ""
say "── 5-ㅇ. 🔴 **마지막 커밋 표식** — 소스에서 먼저 센다"
TM_SEEN=0
while IFS='|' read -r K MK FILE; do
  [ -n "${K:-}" ] || continue
  RK=${K%tools}
  rr=$(row_by_key "$REPOS" "$RK"); F=$(field "$rr" 2); N=$(field "$rr" 3)
  D="$DEV/$F"
  TM_SEEN=$((TM_SEEN+1))
  if [ ! -f "$D/$FILE" ]; then bad "$N — $FILE 이 없다 (표식을 둘 자리가 없다)"; continue; fi
  n=$(grep -cF -- "$MK" "$D/$FILE" 2>/dev/null || true)
  printf '      %-10s [%s] 가 %s 에 %s줄\n' "$N" "$MK" "$FILE" "${n:-?}"
  [ "${n:-0}" -ge 1 ] 2>/dev/null && ok "$N 마지막 커밋 표식이 그 파일에 있다" \
    || bad "$N 마지막 커밋 표식이 그 파일에 **없다** — 표가 틀렸다"
done <<ENDTM
$(rows_of "$TOOLMARKS")
ENDTM
[ "$TM_SEEN" = "$TOOLMARKS_WANT" ] && ok "마지막 커밋 표식 ${TOOLMARKS_WANT}개를 다 봤다" \
  || bad "마지막 커밋 표식을 ${TM_SEEN}개만 봤다 — ${TOOLMARKS_WANT}개를 기대했다"
n=$(mark_now "$DEV/dss-approvals" "$APPROVALS_LAST_MARK")
w=$(mark_was "$DEV/dss-approvals" 8ab36fd "$APPROVALS_LAST_MARK")
say "승인함(도구 이미지가 없다)의 마지막 커밋 표식 — 기준 ${w:-?} → 지금 ${n:-?} (기대 0 → 1 이상)"
if [ "${w:-x}" = "0" ] && [ "${n:-0}" -ge 1 ] 2>/dev/null; then
  ok "승인함은 **앱 번들에서** 마지막 커밋을 가린다 (클래스 문자열이라 minify 를 견딘다)"
else
  bad "승인함 마지막 커밋 표식이 기준 ${w:-?} → 지금 ${n:-?} 다"
fi
say "🔴 **계측기의 마지막 커밋은 앱에 안 담깁니다** — 그 커밋이 고친 것이 scripts/ ·"
say "   시험 · 문서뿐입니다. 계측기 앱 이미지는 **앞 커밋(e0207f1)까지만** 가려집니다."

# 5-ㅈ. 🔴 계측기 — 스케줄러가 부르는 그 파일이 정말 바뀌었나 (⑤)
say ""
say "── 5-ㅈ. 🔴 계측기 (⑤) — **매일 09:00 배치가 부르는 파일이 바뀌었다**"
MD="$DEV/njlee"
n=$(git -C "$MD" diff --name-only a234878..main 2>/dev/null | tr -d '\r' | grep -cFx 'scripts/send-notify.ts' || true)
a=$(git -C "$MD" diff --diff-filter=A --name-only a234878..main 2>/dev/null | tr -d '\r' | grep -cFx 'src/lib/notify-send.ts' || true)
say "scripts/send-notify.ts 가 바뀐 목록에 ${n:-?}줄 (기대 1) · src/lib/notify-send.ts 가 새 파일 목록에 ${a:-?}줄 (기대 1)"
if [ "${n:-0}" = "1" ] && [ "${a:-0}" = "1" ]; then
  ok "스케줄러가 부르는 몸통이 바뀌었다 — 🔴 **도구 이미지를 안 구우면 옛 코드로 계속 돈다**"
  say "      🔵 nas/jobs/notify-daily.sh 는 **태그를 모릅니다** — compose 를 그때그때"
  say "         읽으므로 갈 것은 **compose 의 tools-meters image: 줄 하나**입니다."
  say "      🔴 06-notify-install.sh 에는 IMAGE=dss-meters-tools:1 이 박혀 있습니다 —"
  say "         **그 파일을 다시 돌리는 사람이 옛 태그를 싣습니다.** 62-deploy 꼬리말에 적었습니다."
else
  bad "계측기의 그 두 파일이 기대와 다르다 (send-notify ${n:-?} · notify-send ${a:-?})"
  doubt
fi
n=$(grep -c 'send-notify' "$MD/package.json" 2>/dev/null || true)
[ "${n:-0}" -ge 1 ] 2>/dev/null && ok "계측기 package.json 에 send-notify 명령이 있다" \
  || bad "계측기 package.json 에 send-notify 가 없다 — 배치가 Missing script 로 죽는다"

# 5-ㅊ. 🔴 시험 등록 — **저장소마다 방식이 다르다**
say ""
say "── 5-ㅊ. 🔴 시험 등록 — 빠뜨리면 **오류 없이 조용히 안 돈다**"
# A/S : 목록 파일 넷. 🔴 CRLF 라 \r 를 걷고 -Fx 로 맞댄다.
ASD="$DEV/RF_Service_System"
LIST=$(cat "$ASD"/scripts/test-lists/*.txt 2>/dev/null | tr -d '\r')
lines=$(printf '%s\n' "$LIST" | grep -c . || true)
say "A/S 목록 줄 수 ${lines:-?} (기대 $AS_TESTLIST_MIN_LINES 이상 — 빈 결과는 삼켜진 오류일 수 있다)"
if ! isnum "${lines:-}" || [ "${lines:-0}" -lt "$AS_TESTLIST_MIN_LINES" ]; then
  bad "A/S 목록을 ${lines:-못 읽음}줄밖에 못 읽었다 — 아래 등록 검사를 못 믿는다"
else
  got=0; seen=0
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    seen=$((seen+1))
    n=$(printf '%s\n' "$LIST" | grep -cFx -- "$t" || true)
    if [ "${n:-0}" -ge 1 ] 2>/dev/null; then got=$((got+1)); else printf '        안 적힘 %s\n' "$t"; fi
  done <<ENDAST
$(rows_of "$AS_NEW_TESTS")
ENDAST
  probe=$(printf '%s\n' "$LIST" | grep -cFx -- "$PROBE_MISS" || true)
  say "A/S 새 시험 — 본 것 ${seen} · 등록된 것 ${got} (기대 $AS_NEW_TESTS_WANT · $AS_NEW_TESTS_WANT) · 없는 경로 ${probe:-?}줄(기대 0)"
  if [ "${probe:-1}" != "0" ]; then
    bad "**없는 경로가 목록에 있다고 나왔다** — 줄 전체 일치가 깨졌다. 위 수도 못 믿는다"
  elif [ "$seen" = "$AS_NEW_TESTS_WANT" ] && [ "$got" = "$AS_NEW_TESTS_WANT" ]; then
    ok "A/S 새 시험 ${AS_NEW_TESTS_WANT}개가 목록에 등록돼 있다"
  else
    bad "A/S 등록된 것이 ${got}/${AS_NEW_TESTS_WANT} 개다 — 등록을 빠뜨리면 조용히 안 돈다"
  fi
fi
n=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ -f "$ASD/$f" ] && n=$((n+1)) || printf '        없음 %s\n' "$f"
done <<ENDASL
$(rows_of "$AS_TESTLIST_FILES")
ENDASL
[ "$n" = "$AS_TESTLIST_FILES_WANT" ] && ok "A/S 시험 목록 파일 ${AS_TESTLIST_FILES_WANT}장이 다 있다" \
  || bad "A/S 목록 파일이 ${n}/${AS_TESTLIST_FILES_WANT} 장이다"
# 포털 : package.json 의 test 줄에 경로가 하나씩 적혀 있다.
AUTHTEST=$(grep -F '"test":' "$AUTHDIR/package.json" 2>/dev/null | head -1)
if [ -z "${AUTHTEST:-}" ]; then
  bad "포털 package.json 에서 test 줄을 못 읽었다"
else
  got=0; seen=0
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    seen=$((seen+1))
    n=$(printf '%s' "$AUTHTEST" | grep -cF -- "$t" || true)
    if [ "${n:-0}" -ge 1 ] 2>/dev/null; then got=$((got+1)); else printf '        안 적힘 %s\n' "$t"; fi
  done <<ENDAUT
$(rows_of "$AUTH_NEW_TESTS")
ENDAUT
  probe=$(printf '%s' "$AUTHTEST" | grep -cF -- "$PROBE_MISS" || true)
  say "포털 새 시험 — 본 것 ${seen} · 적힌 것 ${got} (기대 $AUTH_NEW_TESTS_WANT) · 없는 경로 ${probe:-?}(기대 0)"
  if [ "${probe:-1}" != "0" ]; then bad "**없는 경로가 적혀 있다고 나왔다** — 검사가 깨졌다"
  elif [ "$seen" = "$AUTH_NEW_TESTS_WANT" ] && [ "$got" = "$AUTH_NEW_TESTS_WANT" ]; then
    ok "포털 새 시험 ${AUTH_NEW_TESTS_WANT}개가 test 줄에 적혀 있다"
  else bad "포털에 적힌 것이 ${got}/${AUTH_NEW_TESTS_WANT} 개다"; fi
fi
# 휴가 : package.json 의 test:* 명령과 scripts/*.ts 가 **짝**이어야 한다.
LVD="$DEV/dss-leave"
got=0; seen=0; miss=""
while IFS='|' read -r CMD FILE; do
  [ -n "${CMD:-}" ] || continue
  seen=$((seen+1))
  a=$(grep -cF "\"$CMD\":" "$LVD/package.json" 2>/dev/null || true)
  if [ "${a:-0}" -ge 1 ] 2>/dev/null && [ -f "$LVD/$FILE" ]; then got=$((got+1))
  else miss="$miss $CMD"; fi
done <<ENDLVT
$(rows_of "$LEAVE_NEW_TESTS")
ENDLVT
say "휴가 새 시험 — 본 것 ${seen} · 명령과 파일이 짝인 것 ${got} (기대 $LEAVE_NEW_TESTS_WANT)"
if [ "$seen" = "$LEAVE_NEW_TESTS_WANT" ] && [ "$got" = "$LEAVE_NEW_TESTS_WANT" ]; then
  ok "휴가 새 시험 ${LEAVE_NEW_TESTS_WANT}개가 **명령과 파일 둘 다** 있다"
  say "      🔵 휴가는 test 라는 명령이 없고 test:* 가 여섯에서 **열다섯**이 됐습니다."
else
  bad "휴가에서 짝이 안 맞는 것:${miss:- 없음} (${got}/${LEAVE_NEW_TESTS_WANT})"
fi
say "🔵 재고·승인함·계측기는 **글롭 등록**이라 적을 곳이 없습니다 — 파일을 두면 돕니다."

# ── 6. 태그 ───────────────────────────────────────────────────────────
#   🔴 **기대값이 모드마다 뒤집힌다.**
#      --check·--go : 아직 **없어야** 한다(같은 태그를 덮으면 되돌릴 판이 사라진다)
#      --verify     : **있어야** 한다(이미 구운 것을 다시 재는 모드다)
#   🔴 한 잣대로 재면 둘 중 하나가 가짜 ✗ 다 — 「단계마다 기대값이 다르다」.
if [ "$MODE" = "--verify" ]; then
  step "6. 태그가 **있나** — --verify 는 이미 구운 것을 다시 재는 모드다"
else
  step "6. 태그가 이미 있나 — 같은 태그를 다시 구우면 **되돌릴 판이 사라진다**"
fi
IMG_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  TAG=$(field "$r" 3)
  IMG_SEEN=$((IMG_SEEN+1))
  if docker image inspect "$TAG" >/dev/null 2>&1; then
    if [ "$MODE" = "--verify" ]; then ok "$TAG 가 있다 (이것을 다시 잰다)"
    else
      bad "$TAG 가 **이미 있다** — 다른 판을 그 태그로 덮으면 되돌릴 것이 없어진다"
      say "      🔵 이미 구우셨다면 **다시 굽지 말고** --verify 로 그것을 재세요:"
      say "         & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./62-build.sh --verify"
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
# 🔵 **되돌릴 옛 판이 아직 있는가** — --rollback 이 그것을 쓴다.
say ""
say "🔵 되돌릴 옛 판이 개발 PC 에 있는지도 찍습니다(없어도 막지 않습니다 — NAS 에 있으면 됩니다)."
while IFS= read -r r; do
  [ -n "$r" ] || continue
  PT=$(field "$r" 5)
  OLDTAG=$(printf '%s' "${PT%.tar}" | sed 's/-\([0-9][0-9.]*\)$/:\1/')
  if docker image inspect "$OLDTAG" >/dev/null 2>&1; then say "옛 판 있음 $OLDTAG"
  else say "옛 판 없음 $OLDTAG (개발 PC 에만 없는 것일 수 있습니다)"; fi
done <<ENDIMG2
$(rows_of "$IMAGES")
ENDIMG2

# ── 7. 산출물을 둘 자리 + 🔴 dev 서버 여섯 ───────────────────────────
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
    say "      🔴 **옛 묶음이 섞여 있으면 --preload 가 ✗ 를 냅니다** — 쉰여섯째·쉰일곱째가"
    say "         **두 판 연속** 그 자리를 밟았습니다(_images-56 의 옛 묶음 128장)."
    say "      🔴 보내기 전에 **이 폴더에서 옛 tar 와 옛 묶음을 먼저 지우세요.**"
  fi
else
  say "$OUT 가 아직 없다 — --go 때 만든다 (--check 는 아무것도 안 만든다)"
  ok "산출물 자리를 쓸 수 있다"
fi
# 🔴 7-ㄴ. dev 서버 여섯 포트
say ""
say "── 7-ㄴ. dev 서버 — **막지는 않는다. 값으로 찍는다**"
say "🔵 docker build 는 dev 서버를 안 내려도 됩니다(.dockerignore 가 .next 를 막습니다 — 5-ㄷ)."
say "🔴 그래도 찍는 까닭: 3000번이 떠 있으면 **호스트의 npm run build** 가 .next 를 두고"
say "   다투고, 그 탓에 난 tsc 오류를 코드 탓으로 오해한 적이 있습니다."
PORT_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  N=$(field "$r" 3); P=$(field "$r" 6)
  PORT_SEEN=$((PORT_SEEN+1))
  if netstat -an 2>/dev/null | grep -q "[:.]$P[^0-9].*LISTEN"; then
    say "$N ($P) — **떠 있다**"
  else
    say "$N ($P) — 안 떠 있다"
  fi
done <<ENDPORT
$(rows_of "$REPOS")
ENDPORT
[ "$PORT_SEEN" = "$REPOS_WANT" ] && ok "dev 포트 여섯을 다 봤다" || bad "dev 포트를 ${PORT_SEEN}개만 봤다"
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
#    🔵 set -f 로 글롭을 끄고 경로를 큰따옴표로 감싼다(괄호 경로가 다섯 집에 있다).
ask_files() { # 1 태그 2 목록(줄바꿈) 3 기대 수 4 사람이 부르는 말
  local v got seen probe
  v=$(dockr run --rm -e DSS_FILES="$2" -e DSS_MISS="$PROBE_MISS" --entrypoint sh "$1" -c \
    'set -f; printf "%s\n%s\n" "$DSS_FILES" "$DSS_MISS" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | grep '^no  ' | sed 's/^/        /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  seen=$(printf '%s\n' "$v" | grep -cE '^(yes|no ) ' || true)
  probe=$(printf '%s\n' "$v" | grep -c "^no  $PROBE_MISS" || true)
  printf '      %s — 본 것 %s · 있는 것 %s (기대 %s · %s) · 없는 경로가 no %s줄(기대 1)\n' \
    "$4" "${seen:-0}" "${got:-0}" "$(( $3 + 1 ))" "$3" "${probe:-0}"
  if [ "${probe:-0}" != "1" ]; then
    printf '  ✗ **없는 경로가 no 로 안 나왔다** — 「무조건 yes」인 검사다. 위 yes 도 못 믿는다\n'; IMGFAIL=1
  elif [ "${seen:-0}" = "$(( $3 + 1 ))" ] && [ "${got:-0}" = "$3" ]; then
    printf '  ✓ %s %s장이 다 담겼다 (표본이 비지 않았다 · 괄호 경로도 그대로 읽혔다)\n' "$4" "$3"
  else
    printf '  ✗ 본 것 %s · 있는 것 %s 다 — %s 를 기대했다\n' "${seen:-0}" "${got:-0}" "$3"; IMGFAIL=1
    printf '%s\n' "      🔴 본 것이 모자라면 **목록을 넘기는 길이 끊긴 것**(글롭 함정)이고,"
    printf '%s\n' "         있는 것만 모자라면 **옛 소스가 담긴 이미지**입니다."
  fi
}

# 🔴 번들 안에서 글자 하나를 센다 — **.next/server 와 .next/static 을 둘 다** 본다.
bundle_mark() { # 1 태그 2 글자 3 사람이 부르는 말 4 hard|soft
  local v s t
  v=$(dockr run --rm -e M="$2" --entrypoint sh "$1" -c \
    'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  s=$(printf '%s' "$v" | awk '{print $1}'); t=$(printf '%s' "$v" | awk '{print $2}')
  printf '      [%s] — .next/server %s개 · .next/static %s개 (🔴 합이 1 이상이어야 한다)\n' "$2" "${s:-?}" "${t:-?}"
  if isnum "${s:-}" && isnum "${t:-}" && [ "$((s + t))" -ge 1 ]; then
    printf '  ✓ %s\n' "$3"
  else
    if [ "${4:-hard}" = "soft" ]; then printf '  ⚠️ %s — 못 찾았다. 사람이 보세요\n' "$3"
    else printf '  ✗ %s — **없다.** 올리지 마세요\n' "$3"; IMGFAIL=1; fi
    printf '%s\n' "      🔵 **검사 자신도 의심하세요** — 이 글자는 소스에서만 세어 보았고"
    printf '%s\n' "         **번들에서 세어 본 적이 없습니다**(개발 PC 에 standalone 이 없습니다)."
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
#   🔴 **두 벌로 적지 않는다.** 61번이 --check 와 --go 를 같은 함수로 잰 까닭과
#      같다 — 두 벌이면 한쪽만 고쳐져 어긋난다.
#   🔵 바깥에 IMGFAIL 을 남긴다(local 로 가리지 않는다) — 부르는 쪽이 그것으로
#      「이 이미지를 올려도 되나」를 정한다.
inside_check() { # 1 열쇠 2 태그 3 타깃(-=앱)
  # 🔴 **몇 번 실제로 돌았는지 센다.** 부르는 쪽이 그 수를 맞대어 본다 —
  #    [실측 2026-11-18] 이 함수를 쓰는 자리보다 **뒤에** 정의해 두었더니
  #    「command not found」만 한 줄 찍히고 --verify 가 **✗ 0 으로 통과**했다.
  #    아무것도 안 재는 ✓ 의 실물이다. 그래서 세는 줄을 함수 **안**에 둔다.
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
    # 🔴 **public/ 기대값은 집마다 다르다.** 승인함에는 그 폴더가 **아예 없다** —
    #    [실측 2026-11-18] 저장소에도 없고 옛 판(dss-approvals:0.1)에도 없는데
    #    운영이 그 상태로 잘 돌고 있다. 그 집 Dockerfile 88줄이 까닭을 적어 두었다:
    #    「public/ 을 안 담는다 — 이 집에는 그 폴더가 없다. 아홉을 베끼면 여기서
    #     "/app/public": not found 로 멈춘다(2026-10-24 실제로 겪었다)」.
    #    🔴 「yes 가 맞다」를 여섯에 똑같이 들이대 **가짜 ✗** 가 났던 자리다.
    prow=$(row_by_key "$PUBLIC_WANT" "$KEY"); pw=$(field "$prow" 2)
    v=$(dock "$TAG" -c 'if [ -d /app/public ]; then printf "yes %s\n" "$(ls -1 /app/public 2>/dev/null | wc -l)"; else printf "no 0\n"; fi')
    pst=$(printf '%s' "$v" | awk '{print $1}'); pn=$(printf '%s' "$v" | awk '{print $2}')
    printf '      /app/public: %s (파일 %s개 · 이 집의 기대값 %s)\n' "${pst:-못 읽음}" "${pn:-?}" "${pw:-yes}"
    if [ -z "${pw:-}" ]; then
      printf '  ✗ %s 의 public 기대값이 PUBLIC_WANT 표에 없다 — 표가 깨졌다\n' "$KEY"; IMGFAIL=1
    elif [ "${pst:-}" = "$pw" ]; then
      if [ "$pw" = "no" ]; then
        printf '  ✓ 승인함에는 public/ 이 **없는 것이 정상**이다 (옛 판에도 없고 저장소에도 없다)\n'
      elif [ "${pn:-0}" = "0" ]; then
        printf '  ⚠️ public/ 은 있는데 **비어 있다** — 이 집은 원래 그렇습니다(빈 폴더를 담습니다)\n'
      else
        printf '  ✓ public/ 이 담겼다 (%s개)\n' "$pn"
      fi
    else
      printf '  ✗ /app/public 이 %s 다 — 이 집은 %s 를 기대했다\n' "${pst:-못 읽음}" "$pw"; IMGFAIL=1
      printf '%s\n' "      🔵 yes 를 기대한 집이면 정적 파일이 404 가 됩니다(새 사이트에서 걸리는 셋 중 하나)."
    fi
    mrow=$(row_by_key "$APPMARKS" "$KEY")
    MK=$(field "$mrow" 2); KEEPMK=$(field "$mrow" 3); NOTE1=$(field "$mrow" 4)
    bundle_mark "$TAG" "$MK" "번들에 **이번 판의 글자**가 있다 (소스에서는 $NOTE1)" hard
    bundle_mark "$TAG" "$KEEPMK" "지난 판이 올린 글자가 그대로 있다 (뒷걸음친 나무가 아니다)" hard
    if [ "$KEY" = "approvals" ]; then
      # 🔴 승인함만 **앱 번들에서** 마지막 커밋을 가린다 (도구 이미지가 없다).
      bundle_mark "$TAG" "$APPROVALS_LAST_MARK" "**마지막 커밋이 담겼다** (위임 폼의 날짜 둘이 가로로 서는 판이다)" hard
      # 🔴 DB 가 없는 집이다 — drizzle 이 섞여 들어가지 않았는가.
      v=$(dock "$TAG" -c "ls /app/drizzle 2>/dev/null | wc -l")
      v=$(printf '%s' "$v" | tr -d ' ')
      printf '      /app/drizzle 안: %s개 (기대 0 — **이 집은 DB 가 없다**)\n' "${v:-?}"
      if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ 승인함 이미지에 drizzle 이 없다 (해당 없음이 맞다)\n'
      else printf '  ✗ 승인함 이미지에 drizzle 이 들었다 — 전제가 깨졌다. 사람이 보세요\n'; IMGFAIL=1; fi
    fi
    if [ "$KEY" = "meters" ]; then
      printf '%s\n' "      🔴 **계측기 앱은 마지막 커밋을 가리지 못합니다** — 그 커밋이 고친 것이"
      printf '%s\n' "         scripts/ · 시험 · 문서뿐입니다. 위 표식은 **앞 커밋(e0207f1)**의 증거입니다."
      printf '%s\n' "         마지막 커밋은 **도구 이미지**에서 가립니다(dss-meters-tools:2)."
    fi
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
    tmrow=$(row_by_key "$TOOLMARKS" "$KEY")
    TMK=$(field "$tmrow" 2); TMF=$(field "$tmrow" 3)
    # 🔴 **경로를 상대로 넘기고 /app/ 를 컨테이너 안에서 붙인다.**
    #    [실측 2026-11-18] -e F="/app/…" 로 넘기면 Git Bash 가 그 값을
    #    C:/Program Files/Git/app/… 으로 바꿔 **멀쩡한 파일이 missing** 이 된다.
    #    첫 굽기의 가짜 ✗ 다섯이 전부 이것이었다. ask_files 가 처음부터 쓰던 꼴이다.
    # 🔴 그리고 yes/no 가 아니라 **센 줄 수**를 받는다 — 0 과 「못 읽음」을 가른다.
    if [ -z "${TMF:-}" ]; then
      printf '  ✗ %s 의 마지막 커밋 표식이 TOOLMARKS 표에 **없다** — 표가 깨졌다\n' "$KEY"; IMGFAIL=1
    else
    v=$(dockr run --rm -e M="$TMK" -e F="$TMF" --entrypoint sh "$TAG" -c \
      'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s\n" "$(grep -cF -- "$M" "$p")"; else printf "missing 0\n"; fi' 2>/dev/null | tr -d '\r')
    tst=$(printf '%s' "$v" | awk '{print $1}'); tn=$(printf '%s' "$v" | awk '{print $2}')
    printf '      마지막 커밋 표식 [%s] in %s — 파일 %s · 그 글자 %s줄 (기대 hit · 1 이상)\n' \
      "$TMK" "$TMF" "${tst:-못 읽음}" "${tn:-?}"
    if [ "${tst:-}" = "hit" ] && [ "${tn:-0}" -ge 1 ] 2>/dev/null; then
      printf '  ✓ **마지막 커밋이 담겼다** (%s줄)\n' "$tn"
      printf '%s\n' "      🔵 앱 이미지는 **같은 작업본에서 같은 실행으로** 굽습니다 — 2절이 그"
      printf '%s\n' "         작업본의 HEAD 와 미커밋 0 을 확인했으므로 앱에도 들어 있습니다."
    elif [ "${tst:-}" = "hit" ]; then
      printf '  ✗ 그 파일은 있는데 마지막 커밋의 글자가 **0줄**이다 — 커밋 하나가 빠진 판이다\n'; IMGFAIL=1
    elif [ "${tst:-}" = "missing" ]; then
      printf '  ✗ 그 파일 자체가 이미지에 없다 — src/ 나 scripts/ 가 온전히 안 담겼다\n'; IMGFAIL=1
      printf '%s\n' "      🔵 **경로 번역부터 의심하세요** — 1-ㄴ 절이 ✓ 였는지 보세요."
    else
      printf '  ✗ 못 읽었다 (받은 값 [%s])\n' "${v:-}"; IMGFAIL=1
    fi
    fi
    case "$KEY" in
      astools)
        ask_files "$TAG" "$AS_NEW_FILES" "$AS_NEW_FILES_WANT" "A/S 의 핵심 파일"
        # 🔴 A/S 는 drizzle 을 **안 담아야** 한다 — 볼륨이 붙는 자리다.
        v=$(dock "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
        printf '      /app/drizzle 안 .sql: %s개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)\n' "${v:-?}"
        if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ drizzle/ 이 비어 있다 (🔴 그래서 0129·0130 은 **묶음으로** 가야 한다)\n'
        else printf '  ✗ drizzle/ 에 .sql 이 들었다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다\n'; IMGFAIL=1; fi
        # 🔴 **이번 판에서 가장 중요한 줄** — 공용 스키마가 움직였다(②).
        v=$(dock "$TAG" -c 'd=/app/vendor/dss-core/src/schema; if [ -d "$d" ]; then echo "miss=0"; echo "n=$(ls -1 "$d" | wc -l)"; else echo "miss=1"; fi')
        v=$(printf '%s\n' "$v" | tr -d ' ')
        printf '%s\n' "$v" | sed 's/^/        /'
        c=$(printf '%s\n' "$v" | sed -n 's/^miss=//p'); g=$(printf '%s\n' "$v" | sed -n 's/^n=//p')
        if [ "${c:-1}" != "0" ]; then printf '  ✗ 이미지에 vendor/dss-core 의 스키마 폴더가 **없다** — Cannot find module 이 난다\n'; IMGFAIL=1
        elif [ "${g:-0}" -ge 1 ] 2>/dev/null; then printf '  ✓ 공용 스키마가 담겼다 (파일 %s개)\n' "$g"
        else printf '  ✗ 공용 스키마 폴더가 비었다 — **빈 서브모듈이 담겼다.** 올리지 마세요\n'; IMGFAIL=1; fi
        v=$(dock "$TAG" -c 'for pair in "portal_approval_delegations /app/vendor/dss-core/src/schema/portal-approval-delegations.ts" "portal-approval-delegations /app/vendor/dss-core/src/schema/index.ts" "delegated_from_user_id /app/vendor/dss-core/src/schema/repair-case-approvals.ts" "delegated_from_user_id /app/vendor/dss-core/src/schema/quote-approvals.ts" "due_date_row_order /app/vendor/dss-core/src/schema/repair-case-approvals.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1 $2"; fi; done')
        printf '%s\n' "$v" | sed 's/^/        /'
        g=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
        if [ "${g:-0}" = "5" ]; then
          printf '  ✓ **이번 판의 새 공용 스키마**가 담겼고(표 + index 내보내기) 지난 판의 칸들도 그대로다\n'
          printf '%s\n' "      🔵 index.ts 가 안 내보내면 도구가 @dss/core/schema 에서 그 표를 **못 찾습니다**"
          printf '%s\n' "         — 2026-09-21 에 운영에서 도구가 전부 죽은 그 자리입니다."
        else
          printf '  ✗ 다섯 중 %s개만 있다 — **옛 공용 스키마가 담겼다.** 올리지 마세요\n' "${g:-0}"; IMGFAIL=1
        fi
        # 🔵 양식이 이미지에 안 들어갔는가 — 들어갔으면 도장과 계좌번호가 구워진 것이다.
        v=$(dock "$TAG" -c "ls /templates 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
        printf '      /templates 안 파일: %s개 (기대 0 — 양식은 볼륨으로 붙는다)\n' "${v:-?}"
        if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ 양식이 이미지에 안 들어갔다\n'
        else printf '  ✗ 이미지 안에 /templates 가 %s개 있다 — 도장·계좌번호가 구워졌다. 사람이 보세요\n' "${v:-?}"; IMGFAIL=1; fi
        v=$(dock "$TAG" -c "test -d /app/node_modules/drizzle-kit && echo yes || echo no")
        printf '      /app/node_modules/drizzle-kit: %s (기대 yes)\n' "${v:-못 읽음}"
        if [ "${v:-}" = "yes" ]; then printf '  ✓ drizzle-kit 이 있다 (--migrate 가 이것으로 돈다)\n'
        else printf '  ✗ drizzle-kit 이 없다 — **--migrate 가 그 자리에서 죽는다.** 올리지 마세요\n'; IMGFAIL=1; fi
        npm_probe "$TAG" db:preflight
        npm_probe "$TAG" db:migrate
        ;;
      authtools)
        ask_files "$TAG" "$AUTH_NEW_FILES" "$AUTH_NEW_FILES_WANT" "포털의 핵심 파일"
        # 🔴 포털은 drizzle 을 **담아야** 한다 — 0010 이 이미지 안에 있어야 돈다.
        v=$(dock "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
        printf '      /app/drizzle 안 .sql: %s개 (기대 11 — 🔴 **이미지 안에서 돈다**)\n' "${v:-?}"
        if [ "${v:-x}" = "11" ]; then printf '  ✓ 포털 마이그레이션 11장이 이미지에 구워졌다\n'
        else printf '  ✗ .sql 이 %s장이다 — 11 을 기대했다. **안 구우면 0010 이 세상에 없다**\n' "${v:-?}"; IMGFAIL=1; fi
        v=$(dock "$TAG" -c "ls /app/drizzle/0010_*.sql 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
        printf '      0010: %s개 (기대 1)\n' "${v:-?}"
        [ "${v:-x}" = "1" ] && printf '  ✓ **이번 판이 올릴 0010 이 이미지 안에 있다**\n' \
          || { printf '  ✗ 0010 이 이미지에 없다 — 이 배포의 목적물이 안 담겼다\n'; IMGFAIL=1; }
        v=$(dock "$TAG" -c "grep -c 'idx' /app/drizzle/meta/_journal.json 2>/dev/null")
        v=$(printf '%s' "$v" | tr -d ' ')
        printf '      meta/_journal.json 을 읽을 수 있나: %s (0 이면 목록이 안 담긴 것)\n' "${v:-?}"
        if isnum "${v:-}" && [ "${v:-0}" -ge 1 ] 2>/dev/null; then printf '  ✓ 목록 파일도 담겼다 (목록에 없는 .sql 은 drizzle 이 모른다)\n'
        else printf '  ✗ meta/_journal.json 을 못 읽었다 — 적용이 0건으로 조용히 끝난다\n'; IMGFAIL=1; fi
        v=$(dock "$TAG" -c "test -d /app/node_modules/drizzle-kit && echo yes || echo no")
        printf '      /app/node_modules/drizzle-kit: %s (기대 yes)\n' "${v:-못 읽음}"
        if [ "${v:-}" = "yes" ]; then printf '  ✓ drizzle-kit 이 있다\n'
        else printf '  ✗ drizzle-kit 이 없다 — db:migrate 가 죽는다\n'; IMGFAIL=1; fi
        # 🔵 포털 tools 는 vendor 를 **안 담는다** — 그래도 도구가 도는지 값으로 본다.
        v=$(dock "$TAG" -c "test -d /app/vendor && echo yes || echo no")
        printf '      /app/vendor: %s (기대 no — 포털 tools 는 vendor 를 안 담는다)\n' "${v:-못 읽음}"
        if [ "${v:-}" = "no" ]; then printf '  ✓ 포털 도구에 vendor 가 없다 (Dockerfile 과 같다)\n'
        else printf '  ⚠️ 포털 도구에 vendor 가 있다 — Dockerfile 이 바뀐 것 같습니다. 사람이 보세요\n'; fi
        npm_probe "$TAG" db:migrate
        npm_probe "$TAG" check:delegations
        ;;
      inventorytools)
        ask_files "$TAG" "$INV_NEW_FILES" "$INV_NEW_FILES_WANT" "재고관리의 핵심 파일"
        v=$(dock "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
        printf '      /app/drizzle 안 .sql: %s개 (기대 28 — 🔴 **이미지 안에서 돈다**)\n' "${v:-?}"
        if [ "${v:-x}" = "28" ]; then printf '  ✓ 재고 마이그레이션 28장이 이미지에 구워졌다\n'
        else printf '  ✗ .sql 이 %s장이다 — 28 을 기대했다. **안 구우면 0026·0027 이 세상에 없다**\n' "${v:-?}"; IMGFAIL=1; fi
        v=$(dock "$TAG" -c "printf '%s %s\n' \"\$(ls /app/drizzle/0026_*.sql 2>/dev/null | wc -l)\" \"\$(ls /app/drizzle/0027_*.sql 2>/dev/null | wc -l)\"")
        a=$(printf '%s' "$v" | awk '{print $1}'); b=$(printf '%s' "$v" | awk '{print $2}')
        printf '      0026 %s개 · 0027 %s개 (기대 1 · 1)\n' "${a:-?}" "${b:-?}"
        if [ "${a:-x}" = "1" ] && [ "${b:-x}" = "1" ]; then printf '  ✓ **이번 판이 올릴 둘이 이미지 안에 있다**\n'
        else printf '  ✗ 0026·0027 이 이미지에 없다 — 이 배포의 목적물이 안 담겼다\n'; IMGFAIL=1; fi
        v=$(dock "$TAG" -c "test -f /app/scripts/migrate.ts && echo yes || echo no")
        printf '      /app/scripts/migrate.ts: %s (기대 yes — db:migrate 가 이것을 tsx 로 돌린다)\n' "${v:-못 읽음}"
        if [ "${v:-}" = "yes" ]; then printf '  ✓ migrate.ts 가 있다\n'
        else printf '  ✗ migrate.ts 가 없다 — npm run db:migrate 가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
        npm_probe "$TAG" db:migrate
        ;;
      leavetools)
        ask_files "$TAG" "$LEAVE_NEW_FILES" "$LEAVE_NEW_FILES_WANT" "휴가의 핵심 파일"
        v=$(dock "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l"); v=$(printf '%s' "$v" | tr -d ' ')
        printf '      /app/drizzle 안 .sql: %s개 (기대 5 — 🔴 **이미지 안에서 돈다**)\n' "${v:-?}"
        if [ "${v:-x}" = "5" ]; then printf '  ✓ 휴가 마이그레이션 5장이 이미지에 구워졌다\n'
        else printf '  ✗ .sql 이 %s장이다 — 5 를 기대했다. **안 구우면 0003·0004 가 세상에 없다**\n' "${v:-?}"; IMGFAIL=1; fi
        v=$(dock "$TAG" -c "printf '%s %s\n' \"\$(ls /app/drizzle/0003_*.sql 2>/dev/null | wc -l)\" \"\$(ls /app/drizzle/0004_*.sql 2>/dev/null | wc -l)\"")
        a=$(printf '%s' "$v" | awk '{print $1}'); b=$(printf '%s' "$v" | awk '{print $2}')
        printf '      0003 %s개 · 0004 %s개 (기대 1 · 1)\n' "${a:-?}" "${b:-?}"
        if [ "${a:-x}" = "1" ] && [ "${b:-x}" = "1" ]; then printf '  ✓ **이번 판이 올릴 둘이 이미지 안에 있다**\n'
        else printf '  ✗ 0003·0004 가 이미지에 없다 — 이 배포의 목적물이 안 담겼다\n'; IMGFAIL=1; fi
        v=$(dock "$TAG" -c "test -d /app/node_modules/drizzle-kit && echo yes || echo no")
        printf '      /app/node_modules/drizzle-kit: %s (기대 yes)\n' "${v:-못 읽음}"
        if [ "${v:-}" = "yes" ]; then printf '  ✓ drizzle-kit 이 있다\n'
        else printf '  ✗ drizzle-kit 이 없다 — db:migrate 가 죽는다\n'; IMGFAIL=1; fi
        # 🔵 휴가는 시험 명령이 아홉 늘었다 — 그 파일들이 이미지에도 있는가.
        v=$(dock "$TAG" -c 'n=0; for f in /app/scripts/test-approval-delegation.ts /app/scripts/test-delegation-fold.ts /app/scripts/test-approval-history.ts; do [ -f "$f" ] && n=$((n+1)); done; echo "n=$n"')
        g=$(printf '%s' "$v" | sed -n 's/^n=//p')
        printf '      새 시험 셋(표본): %s개 (기대 3)\n' "${g:-?}"
        [ "${g:-x}" = "3" ] && printf '  ✓ 새 시험 파일이 도구 이미지에도 담겼다\n' \
          || { printf '  ✗ 새 시험 파일이 %s/3 개다 — scripts/ 가 온전히 안 담겼다\n' "${g:-?}"; IMGFAIL=1; }
        npm_probe "$TAG" db:migrate
        ;;
      meterstools)
        ask_files "$TAG" "$METERS_NEW_FILES" "$METERS_NEW_FILES_WANT" "계측기의 핵심 파일"
        # 🔴 ⑤ — 매일 09:00 배치가 부르는 그 파일이 **새 코드**인가.
        v=$(dock "$TAG" -c "test -f /app/scripts/send-notify.ts && echo yes || echo no")
        printf '      /app/scripts/send-notify.ts: %s (기대 yes — **매일 09:00 배치가 이것을 부른다**)\n' "${v:-못 읽음}"
        if [ "${v:-}" = "yes" ]; then printf '  ✓ 배치가 부르는 파일이 이미지에 있다\n'
        else printf '  ✗ send-notify.ts 가 없다 — **배치가 Missing script 로 죽는다**\n'; IMGFAIL=1; fi
        v=$(dock "$TAG" -c 'if grep -q "notify-send" /app/scripts/send-notify.ts 2>/dev/null; then echo yes; else echo no; fi')
        printf '      send-notify.ts 가 공용 몸통(notify-send)을 부르는가: %s (기대 yes)\n' "${v:-못 읽음}"
        if [ "${v:-}" = "yes" ]; then printf '  ✓ **보내는 몸통이 공용 파일로 빠진 판이다** (수동 발송과 같은 길을 쓴다)\n'
        else printf '  ✗ 옛 send-notify.ts 다 — 도구를 안 구운 것이거나 캐시다\n'; IMGFAIL=1; fi
        npm_probe "$TAG" send-notify
        ;;
    esac
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
# ── 🔴 --verify : **이미 구운 열하나를 다시 재기만 한다** ────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **아무것도 굽지 않고 아무 파일도 만들지 않는다.** docker build 도
#      docker save 도 한 줄 없다 — 구운 지문(md5)이 바뀌면 안 되기 때문이다.
#   🔵 왜 필요한가: 첫 굽기에서 **검사 쪽이 틀려** 가짜 ✗ 가 났다. 검사를 고친
#      뒤 「고친 검사가 실제로 통과하는가」를 재야 하는데, 다시 구우면 지문이
#      바뀌어 **이미 받아 둔 TARS 값이 못 쓰게 된다.**
#   🔵 쓰는 것: **없다.** (컨테이너를 run --rm 으로 잠깐 띄웠다 지울 뿐이다)
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
    KEY=$(field "$row" 1); TAG=$(field "$row" 3); TGT=$(field "$row" 4)
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
  # 🔴 **표본이 비어서 공짜로 통과하지 않게** 한다 — 함수가 한 번도 안 돌았는데
  #    ✗ 0 이 나오는 일이 실제로 있었다.
  if [ "$INSIDE_RAN" != "$HOWMANY" ]; then
    printf '  ✗ 이미지 안을 %s번만 쟀다 — %s번을 기대했다. **아무것도 안 잰 통과다**\n' "$INSIDE_RAN" "$HOWMANY"
    VFAIL=$((VFAIL+1))
  else
    printf '  ✓ 이미지 안을 %s번 다 쟀다 (표본이 비지 않았다)\n' "$INSIDE_RAN"
  fi
  if [ -n "${TARTABLE:-}" ]; then
    printf '\n%s\n' "════════ 62-deploy.sh 의 TARS 에 넣을 줄 (tar 에서 다시 쟀습니다) ════════"
    printf '%s' "$TARTABLE"
  fi
  if [ -f "$MIGTAR" ]; then
    msz=$(stat -c %s "$MIGTAR" 2>/dev/null); mm5=$(md5sum "$MIGTAR" | awk '{print $1}')
    printf '%s\n' "MIGTAR_SIZE=${msz}"
    printf '%s\n' "MIGTAR_MD5=${mm5}"
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
printf '%s\n' "🔴 **열하나입니다.** 한 시간 가까이 걸릴 수 있습니다 — 중간에 끊지 마세요."
BUILT=0; BFAIL=0; TARTABLE=""; MIGLINE=""
while IFS= read -r row; do
  [ -n "$row" ] || continue
  KEY=$(field "$row" 1); REPO=$(field "$row" 2); TAG=$(field "$row" 3)
  TGT=$(field "$row" 4); PREVTAR=$(field "$row" 5); PREVSZ=$(field "$row" 6)
  STRICT=$(field "$row" 7)
  DIR="$DEV/$REPO"
  FILE=$(tar_name "$TAG")
  LOG="$OUT/build-$(printf '%s' "$TAG" | tr ':' '-').log"
  printf '\n── %s  (%s)\n' "$TAG" "$REPO"

  # 🔴 도구 이미지만 --target tools 다. 안 주면 **runner 가 구워지고** 그 안에는
  #    scripts/ 도 package.json 도 없어 오류 없이 쓸모없는 이미지가 된다.
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
    printf '  ✗ 굽기 실패 — %s 를 보세요\n' "$LOG"; BFAIL=$((BFAIL+1))
    if [ "$REPO" = "dss-auth" ]; then
      printf '%s\n' "      🔴 포털이면 **@dss/ui 를 먼저 의심하세요**(①). 이번 판에 서브모듈이"
      printf '%s\n' "         처음 생겼습니다 — vendor/dss-ui 가 비면 Module not found 로 죽습니다."
      printf '%s\n' "         → git -C \"$DEV/dss-auth\" submodule update --init --recursive"
    fi
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
  if [ "$STRICT" = "none" ]; then
    printf '  ⚠️ 지난 판 %s 의 바이트가 **이 저장소에 적힌 곳이 없다** — ①번 견주기를 건너뛴다\n' "$PREVTAR"
    printf '%s\n' "      🔵 0 을 기대값으로 쓰면 「차이 무한%」로 **가짜 ✗** 가 납니다(⑦)."
    printf '%s\n' "      🔴 이번에 나온 바이트를 **README 에 적어 두세요** — 다음 판이 그것을 씁니다."
  else
    p=$(pct_diff "$sz" "$PREVSZ")
    if [ -n "${p:-}" ]; then
      printf '    지난 판 %s %s바이트 → 이번 %s바이트 (차이 %s%%)\n' "$PREVTAR" "$PREVSZ" "$sz" "$p"
      if [ "$p" -le 25 ]; then
        printf '  ✓ 지난 판 tar 와 크기가 비슷하다 (차이 %s%% · 25%% 이내)\n' "$p"
      elif [ "$STRICT" = "loose" ] && [ "$p" -le 60 ]; then
        printf '  ⚠️ 지난 판 tar 와 %s%% 다르다 — 이 줄은 loose 라 막지 않습니다\n' "$p"
        printf '%s\n' "      🔵 A/S 는 이번 판에 **heic2any 가 늘었습니다**(⑥)."
      else
        printf '  ✗ 지난 판 tar 와 크기가 %s%% 다르다 — %s 에서는 그만큼이면 멈춘다\n' "$p" "$STRICT"
        printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 라이브러리가 늘거나 베이스 이미지가"
        printf '%s\n' "         바뀌면 정상적으로도 이만큼 뜁니다. 까닭을 알면 IMAGES 표의 여섯째 칸을"
        printf '%s\n' "         고쳐 적으면 됩니다. 모르겠으면 **멈추고 알리세요.**"
        BFAIL=$((BFAIL+1)); continue
      fi
    else
      printf '  ✗ 크기를 못 쟀다 (이번 %s · 지난 판 %s)\n' "${sz:-없음}" "${PREVSZ:-없음}"
      BFAIL=$((BFAIL+1)); continue
    fi
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
  #   🔴 **--verify 모드가 같은 함수를 부른다** — 두 벌로 적으면 어긋난다.
  inside_check "$KEY" "$TAG" "$TGT"
  if [ "$IMGFAIL" != 0 ]; then
    printf '%s\n' "🔴 $TAG 의 안이 온전하지 않다. 올리지 마세요."
    BFAIL=$((BFAIL+1))
  fi
done <<ENDBUILD
$(rows_of "$IMAGES")
ENDBUILD

# ══════════════════════════════════════════════════════════════════════
# ── 🔴 **열두째 산출물 — A/S 마이그레이션 묶음** ──────────────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **A/S 만 그렇다.** 포털·재고·휴가의 마이그레이션은 **도구 이미지 안**에
#      구워져 가므로 묶음이 없다(머리말의 「어디서 도는가」 표).
#   🔴 A/S 도구의 /app/drizzle 은 비어 있고(위 ⑫ 가 그것을 쟀다) 운영에서는
#      거기에 /volume1/dss/as-migrations 가 붙는다. 그래서 0129·0130 은
#      **이 묶음으로만** 간다. 🔴 안 보내면 적용이 0건으로 조용히 끝난다.
ASDIR="$DEV/RF_Service_System"
AS_SQL_WANT=131
AS_PROD_SQL_NOW=129
printf '\n%s\n' "════════ 열두째 산출물 — A/S 마이그레이션 묶음 ($AS_SQL_WANT 장) ════════"
MIGOK=1; msz=""; mm5=""
rm -f "$MIGTAR" 2>/dev/null
if ( cd "$ASDIR" && tar -czf "$MIGTAR" drizzle ) </dev/null; then
  msz=$(stat -c %s "$MIGTAR" 2>/dev/null || wc -c < "$MIGTAR")
  mm5=$(md5sum "$MIGTAR" | awk '{print $1}')
  printf '  ✓ as-migrations.tar.gz (%s바이트)\n' "$msz"
  printf '    md5  %s\n' "$mm5"
  printf '%s\n' "    🔵 61번(129장)의 묶음은 2,532,210바이트였습니다 — 그보다 조금 큰 것이 정상입니다."
else
  printf '  ✗ 묶음을 못 만들었다 — 🔴 **A/S 는 묶음이 필수다**\n'
  BFAIL=$((BFAIL+1)); MIGOK=0
fi
if [ "$MIGOK" = "1" ]; then
  # 🔴 **안을 센다 — 겉이 아니라 결과.** tar 를 grep -q 에 물리지 않는다.
  INSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE '^drizzle/[0-9]{4}_.*[.]sql$' || true)
  INJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
  printf '    묶음 안 — .sql %s장 · meta/_journal.json 의 idx %s개 (기대 %s · %s)\n' "${INSQL:-?}" "${INJRN:-?}" "$AS_SQL_WANT" "$AS_SQL_WANT"
  if [ "${INSQL:-x}" = "$AS_SQL_WANT" ] && [ "${INJRN:-x}" = "$AS_SQL_WANT" ]; then
    printf '  ✓ 묶음 안이 %s장이고 목록도 %s개다 (목록에서 빠진 .sql 이 없다)\n' "$AS_SQL_WANT" "$AS_SQL_WANT"
  else
    printf '  ✗ 묶음 안이 .sql %s · idx %s 다 — %s·%s 를 기대했다\n' "${INSQL:-?}" "${INJRN:-?}" "$AS_SQL_WANT" "$AS_SQL_WANT"
    printf '%s\n' "      🔴 목록에 없는 .sql 은 drizzle 이 **아예 모르고**, 적용이 0건으로 조용히 끝납니다."
    BFAIL=$((BFAIL+1))
  fi
  # 🔴 이번 판이 올릴 둘이 정말 들어 있는가 — 수만 맞고 다른 것이 들었을 수 있다.
  for t in 0129 0130; do
    a=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${t}_.*[.]sql" || true)
    b=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/meta/${t}_snapshot[.]json" || true)
    printf '    묶음 안의 %s — .sql %s개 · 스냅샷 %s개 (기대 1 · 1)\n' "$t" "${a:-?}" "${b:-?}"
    if [ "${a:-0}" = "1" ] && [ "${b:-0}" = "1" ]; then
      printf '  ✓ **이번 판이 올릴 %s 이 묶음 안에 있다**\n' "$t"
    else
      printf '  ✗ 묶음 안에 %s 이 없다 — **이 배포의 목적물이 안 담겼다.** 보내지 마세요\n' "$t"
      BFAIL=$((BFAIL+1))
    fi
  done
  HASNEXT=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/0131_.*[.]sql" || true)
  printf '    묶음 안의 0131: %s개 (기대 0)\n' "${HASNEXT:-?}"
  if [ "${HASNEXT:-1}" = "0" ]; then
    printf '  ✓ 묶음에 0131 이 없다 (마지막이 0130 — 적용 대기가 2건이 된다)\n'
  else
    printf '  ✗ 묶음에 0131 이 **있다** — 이 배포는 0130 까지를 전제로 쓰였다. 멈추고 알릴 것\n'
    BFAIL=$((BFAIL+1))
  fi
  KEEPIN_MISS=""
  for t in $AS_KEEP_MIGS; do
    a=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${t}_.*[.]sql" || true)
    b=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/meta/${t}_snapshot[.]json" || true)
    printf '      %-6s .sql %s · 스냅샷 %s\n' "$t" "${a:-0}" "${b:-0}"
    [ "${a:-0}" -ge 1 ] 2>/dev/null || KEEPIN_MISS="$KEEPIN_MISS $t(sql)"
    [ "${b:-0}" -ge 1 ] 2>/dev/null || KEEPIN_MISS="$KEEPIN_MISS $t(snapshot)"
  done
  if [ -z "${KEEPIN_MISS:-}" ]; then
    printf '  ✓ 묶음에 창 안 일곱의 .sql 과 스냅샷이 다 있다 (폴더를 통째로 갈아 끼워도 안전하다)\n'
  else
    printf '  ✗ 묶음에서 빠진 것:%s\n' "$KEEPIN_MISS"
    BFAIL=$((BFAIL+1))
  fi
  # 🔴 묶음 안의 0129·0130 이 기대한 생김새인가 — 보내는 것은 저장소가 아니라 이 묶음이다.
  for t in 0129 0130; do
    NM=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -E "^drizzle/${t}_.*[.]sql" | head -1)
    if [ -z "${NM:-}" ]; then printf '  ⚠️ 묶음 안의 %s 을 못 읽었다\n' "$t"; continue; fi
    TB=$(tar -xzOf "$MIGTAR" "$NM" 2>/dev/null)
    traw=$(printf '%s\n' "$TB" | grep -ciE "$DESTRUCTIVE_RE" || true)
    tnet=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
    tct=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'CREATE TABLE' || true)
    tix=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'CREATE INDEX' || true)
    tins=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'INSERT INTO' || true)
    tond=$(printf '%s\n' "$TB" | grep -cF 'ON DELETE' || true)
    printf '    묶음 안 %s — 지우는 문장 날것 %s줄 · 주석 걷은 뒤 %s줄 (기대 0) · CREATE TABLE %s · CREATE INDEX %s · INSERT %s · (참고) ON DELETE %s줄\n' \
      "$t" "${traw:-?}" "${tnet:-?}" "${tct:-?}" "${tix:-?}" "${tins:-?}" "${tond:-?}"
    if [ "${tnet:-x}" = "0" ] && [ "${tins:-1}" = "0" ]; then
      printf '  ✓ 묶음 안의 %s 이 **더하기만 하고 자료는 안 건드린다**\n' "$t"
    else
      printf '  ✗ 묶음 안의 %s 이 기대와 다르다 — 지우는 문장 %s줄 · INSERT %s\n' "$t" "${tnet:-?}" "${tins:-?}"
      BFAIL=$((BFAIL+1))
    fi
  done
  printf '%s\n' "    🔵 0129 의 ON DELETE restrict 두 줄은 **FK 구절**이라 안 셉니다 — 앱의"
  printf '%s\n' "       migration-safety 와 같은 잣대입니다(4-ㄱ 이 표본으로 그 잣대를 먼저 쟀습니다)."
  MIGLINE="as-migrations.tar.gz|${msz}|${mm5}|-"
fi

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  구운 것 %s / %s · 실패 %s\n' "$BUILT" "$HOWMANY" "$BFAIL"

# ══ 🔴 **✗ 가 나도 지문 줄만은 찍는다** ═══════════════════════════════
#   🔴 쉰세째·쉰네째에 **두 번 연속으로 지문을 못 받았다.** 그래서 **세 자리**에서 찍는다.
if [ "$BFAIL" != "0" ]; then
  printf '\n%s\n' "🔴🔴🔴 **실패가 있지만 지금까지 만든 산출물의 지문은 아래가 전부입니다**"
  printf '%s\n' "       (이름|바이트|md5|Config 지문 — 62-deploy.sh 의 TARS 에 넣을 꼴입니다)"
  if [ -n "${TARTABLE:-}" ]; then printf '%s' "$TARTABLE"
  else printf '%s\n' "       (tar 가 한 줄도 없습니다 — 하나도 안 구워졌다는 뜻입니다.)"; fi
  if [ -n "${MIGLINE:-}" ]; then
    printf '%s\n' "       MIGTAR_SIZE=${msz}"
    printf '%s\n' "       MIGTAR_MD5=${mm5}"
  else
    printf '%s\n' "       (묶음 줄이 없습니다 — 묶음이 안 만들어졌다는 뜻입니다.)"
  fi
  printf '%s\n' "🔴🔴🔴 **실패를 고친 뒤 다시 구우면 지문이 바뀝니다** — 위 값을 그대로 쓰지"
  printf '%s\n' "       마시고, 다시 구운 뒤의 값을 쓰세요."
  printf '\n%s\n' "🔴 실패가 있다. 위를 보세요."
  exit 1
fi

# 🔴 **굽고 나서 저장소가 더러워졌는가** — next build 가 tsconfig.json 을 다시 접는다.
printf '\n%s\n' "════════ 구운 뒤 저장소 여섯이 그대로인가 ════════"
printf '%s\n' "🔴 next build 가 tsconfig.json 을 다시 접은 적이 있습니다(눈에 안 띕니다)."
while IFS= read -r r; do
  [ -n "$r" ] || continue
  F=$(field "$r" 2); N=$(field "$r" 3)
  d=$(git -C "$DEV/$F" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${d:-1}" = "0" ]; then printf '  ✓ %s 미커밋 0줄\n' "$N"
  else
    printf '  ⚠️ %s 에 미커밋이 %s줄 생겼다 — **사람에게 알리세요**\n' "$N" "$d"
    git -C "$DEV/$F" status --porcelain=v1 2>/dev/null | head -6 | sed 's/^/        /'
  fi
done <<ENDDIRTY
$(rows_of "$REPOS")
ENDDIRTY
d=$(git -C "$COREDIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
if [ "${d:-1}" = "0" ]; then printf '  ✓ vendor/dss-core 미커밋 0줄\n'
else printf '  ⚠️ vendor/dss-core 에 미커밋이 %s줄 생겼다 — 사람에게 알리세요\n' "$d"; fi
printf '%s\n' "  🔵 **tar 는 이미 구워졌습니다** — 되돌릴지 그대로 둘지는 사람이 정하세요."

# ══ 🔴 62-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
printf '\n%s\n' "════════ 62-deploy.sh 에 붙여 넣을 것 (TARS 열한 줄 + 묶음 값 둘) ════════"
printf '%s' "$TARTABLE"
printf '%s\n' "  🔴 위 **열한 줄**로 TARS 를 통째로 갈아 끼웁니다."
printf '%s\n' "  🔴 그리고 **묶음 값 둘**을 아래 그대로 적습니다 (TARS 가 아니라 따로 있는 변수입니다):"
printf '%s\n' "       MIGTAR_SIZE=${msz}"
printf '%s\n' "       MIGTAR_MD5=${mm5}"
printf '%s\n' "  🔴 **NAS 에서 재서 채우지 마세요** — 자기가 잰 값으로 자기를 재면 영영 통과합니다."
printf '%s\n' "  🔵 그리고 **dss-leave-tools-3.tar 와 dss-meters-tools-2.tar 의 바이트를 README 에"
printf '%s\n' "     적어 두세요** — 이 저장소에 그 둘의 지난 판 값이 없어 이번에 ①번 견주기를"
printf '%s\n' "     건너뛰었습니다(⑦). 다음 판은 그 값을 쓸 수 있습니다."
printf '\n%s\n' "✅ 열하나를 다 굽고 묶음도 만들었습니다. 산출물이 여기 있습니다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'

printf '\n%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **올리는 차례 — tar 열하나 + 묶음 하나**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  🔴 PowerShell 경로는 **슬래시**로 적습니다. 역슬래시는 bash·scp 가 먹습니다."
printf '%s\n' "  🔴 **Tee-Object 로 로그를 받지 마세요** — PowerShell 이 UTF-16 으로 써서"
printf '%s\n' "     나중에 grep 이 한 줄도 못 찾습니다. NAS 쪽 로그 파일을 보세요."
printf '%s\n' "  🔴 **-O 를 빼지 마세요** — DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' ""
printf '%s\n' "  ① (개발 PC · PowerShell) **스크립트부터 올린다**"
printf '%s\n' "       cd \"C:/Users/희만/Desktop/Development/dss-deploy/nas/setup\""
printf '%s\n' "       scp -O 62-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "       Get-FileHash -Algorithm MD5 62-deploy.sh"
printf '%s\n' "     🔴 **TARS 열한 줄과 MIGTAR_SIZE·MIGTAR_MD5 를 먼저 채운 뒤에 올리세요.**"
printf '%s\n' ""
printf '%s\n' "  ② (NAS) 지금 상태를 잰다 — 아직 아무것도 안 바뀐다"
printf '%s\n' "       sudo -i"
printf '%s\n' "       bash /volume1/dss/setup/62-deploy.sh            ← --check"
printf '%s\n' "       bash /volume1/dss/setup/62-deploy.sh --count    ← 올리기 전 수"
printf '%s\n' ""
printf '%s\n' "  ③ (개발 PC · PowerShell) **tar 열하나와 묶음 하나를 보낸다 — 한 줄에 하나씩**"
printf '%s\n' "       cd \"$(printf '%s' "$OUT" | sed 's|^/c/|C:/|')\""
while IFS= read -r r; do
  [ -n "$r" ] || continue
  printf '%s\n' "       scp -O $(tar_name "$(field "$r" 3)") dss-nas:/volume1/dss/images/"
done <<ENDSCP
$(rows_of "$IMAGES")
ENDSCP
printf '%s\n' "       scp -O as-migrations.tar.gz dss-nas:/volume1/dss/setup/incoming/"
printf '%s\n' "     🔴 **묶음은 images/ 가 아니라 setup/incoming/ 으로 갑니다** — 자리가 다릅니다."
printf '%s\n' "     🔴 **옛 판의 묶음을 보내지 마세요** — _images-57 에는 129장짜리가 있습니다."
printf '%s\n' ""
printf '%s\n' "  ④ (NAS) **들여놓고 → 다시 재고 → DB 를 올리고 → 갈아 끼운다**"
printf '%s\n' "       bash /volume1/dss/setup/62-deploy.sh --preload"
printf '%s\n' "       bash /volume1/dss/setup/62-deploy.sh            ← 다시 --check"
printf '%s\n' "       bash /volume1/dss/setup/62-deploy.sh --migrate  🔴 **여기서 DB 가 바뀐다** (네 집 · 일곱 건)"
printf '%s\n' "       bash /volume1/dss/setup/62-deploy.sh --go       ⏱ 정지 창 (앱 **여섯**)"
printf '%s\n' "       bash /volume1/dss/setup/62-deploy.sh --count    ← 올린 뒤 수"
printf '%s\n' "     🔴 **--migrate 를 건너뛰고 --go 로 가지 마세요** — 네 집의 위임 화면이"
printf '%s\n' "        표가 없으면 42P01 로 터집니다."
printf '%s\n' ""
printf '%s\n' "🔴 **되돌리기**: --rollback 은 앱 여섯을 옛 태그로 되돌립니다."
printf '%s\n' "   🔵 도구 다섯은 새 판 그대로 둡니다(39·41~61번과 같은 판단)."
printf '%s\n' "   🔴 **DB 는 자동으로 안 되돌립니다** — 일곱 건이 **더하기만** 하므로 옛 앱은"
printf '%s\n' "      그 표와 색인을 쳐다보지도 않습니다."
printf '%s\n' "────────────────────────────────────────────────────────────"
printf '\n%s\n' "🔴🔴🔴 **62-deploy.sh 에 넣을 값 (다시 찍습니다 — 여기만 복사해도 됩니다)**"
printf '%s\n' "── TARS 열한 줄"
printf '%s' "$TARTABLE"
printf '%s\n' "── 묶음 값 둘 (TARS 가 아니라 따로 있는 변수다)"
printf '%s\n' "MIGTAR_SIZE=${msz}"
printf '%s\n' "MIGTAR_MD5=${mm5}"
printf '%s\n' "🔴🔴🔴 위를 62-deploy.sh 에 **그대로** 적은 뒤 scp 하세요."

