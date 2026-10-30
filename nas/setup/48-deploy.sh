#!/bin/bash
# dss-deploy/nas/setup/48-deploy.sh — 마흔다섯째 배포 (2026-10-30)
#
# 🔴 NAS 에서 돈다. **DSM 터미널은 긴 명령을 잘라 먹는다**(2026-10-12 하루에 네
#    번 깨졌다). 그래서 손으로 치지 않고 **파일로 올려** 돌린다. 절차는 이렇다:
#      ① (개발 PC · PowerShell)
#           cd C:\Users\희만\Desktop\Development
#           scp -O dss-deploy\nas\setup\48-deploy.sh dss-nas:/volume1/dss/setup/
#           Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\48-deploy.sh
#      ② (NAS) md5sum /volume1/dss/setup/48-deploy.sh
#      ③ 🔴 **두 md5 가 같은지 눈으로 맞댄다.** 다르면 옮기다 잘린 것이다 —
#         그대로 돌리면 중간에서 끊긴 스크립트가 compose 를 고치다 만다.
#      🔵 이 파일은 돌 때 맨 위에서 **제 md5 를 스스로 찍는다.** ②를 따로 안
#         쳐도 로그에 남는다.
#    🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#    🔴 tar · scp 에 드라이브 문자(C:)를 주지 마라 — 원격 호스트로 읽는다.
#
# ── 사람이 실행한다 ───────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/48-deploy.sh            ← 읽기만 한다
#   (NAS)         bash /volume1/dss/setup/48-deploy.sh --preload
#   (NAS)         bash /volume1/dss/setup/48-deploy.sh            ← 다시 --check
#   (NAS)         bash /volume1/dss/setup/48-deploy.sh --go       ⏱ 정지 창
#   (NAS)         bash /volume1/dss/setup/48-deploy.sh --count    ← 종에 몇 줄이 뜨나
#
# ── 갈아 끼우는 것 — **저장소 둘, 태그 셋** ───────────────────────────
#     ① A/S 앱   dss-as:4.0        → **dss-as:4.1**        커밋 6
#     ② A/S 도구 dss-as-tools:7    → **dss-as-tools:8**    커밋 6
#     ③ PO 앱    dss-po:0.7        → **dss-po:0.8**        커밋 1
#
#   🔴 **지난 판(47번)은 A/S 하나뿐이었다.** 이 판은 **둘**이다.
#   🔵 PO 는 40번대 스크립트에 한 번도 안 나온다 — 마지막으로 올린 것은
#      **31-deploy.sh**(2026-10-22)이고 그때 0.6 → 0.7 이었다.
#   🔴 **마이그레이션이 없다.** 두 저장소의 drizzle/ 이 각자의 기준 SHA 이후
#      **0건**이다(2026-10-30 재측정). 그래서 이 파일에는 **--migrate 모드가
#      없다** — DB 를 바꾸는 단계가 한 군데도 없다.
#   🔵 **나머지 여덟은 안 건드린다** — 통합 로그인 · 재고 · 게시판 · 계측기 ·
#      개선요청 · RF 이슈관리 · 휴가 · 통합 승인함. 여덟 모두 HEAD 가 기준 SHA
#      그대로다(2026-10-30 실측 — 48-build.sh 머리말에 SHA 를 하나씩 적었다).
#
# ── 🔴 기준 SHA — 추정하지 않고 역산해서 확인했다 ────────────────────
#   · **A/S 3bde67e** : 47-build.sh 머리말이 제 기준을 081439b · 커밋 1 이라고
#     적었고, 'git log 081439b..HEAD' 의 첫 줄이 3bde67e 하나다. 47-deploy.sh
#     머리말의 「이 배포가 하는 일 — 커밋 하나」에도 3bde67e 가 글자 그대로 있다.
#   · **PO 394e048** : 40번대에 'dss-po:' 가 한 줄도 없고, PO 를 마지막으로 구운
#     것은 31-build.sh 의 'po|dss-po|dss-po:0.7|' 이다. README.md 의 기준 SHA 표
#     네 자리가 모두 'PO · 0.7 · 394e048' 이라고 적는다.
#   🔵 둘 다 지시서의 추정과 맞았다.
#
# ── 이 배포가 하는 일 — **「납기 역전」을 화면과 종이 함께 알린다** ───
#   A/S  3bde67e..3851693 (여섯)
#     dca7909 사내 목표 출하일이 고객 요청 납기일보다 늦으면 알린다
#     be21fa5 PO발행일이 적혔는데 사내 목표 출하일이 비면 엔지니어에게 알린다
#     7c4f31b 납기일을 묶기 전에 운영 자료를 세는 도구
#     4516021 내자정리에서도 납기 역전을 붉은 날짜와 메모로 알린다
#     3d20358 납기 역전이면 엔지니어·영업·관리자에게 알린다
#     3851693 머리말이 세는 수를 항목 수에 맞춘다
#   PO   394e048..c32358f (하나)
#     c32358f 내자정리에서도 납기 역전을 붉은 날짜와 메모로 알린다
#
#   🔵 **PO 쪽은 A/S 4516021 의 사본이다** — 판정과 화면 코드가 머리말 아래로
#      바이트 동일이다(그 커밋 본문이 그렇게 적는다). 그래서 **두 화면이 같은
#      줄에 같은 색을 내야** 맞다. 그것이 이번 판의 핵심 눈 확인이다.
#   🔴 **저장된 글자는 한 자도 안 바뀐다.** DB 를 건드리는 단계가 없다.
#   🔵 **설정 이름도 안 는다.** 이 범위에 새 환경변수가 한 개도 없다.
# ── 🔴 **왜 둘을 한 번에 띄우는가** — 30번은 일부러 갈라 띄웠다 ───────
#   30번(서른셋째)은 A/S 를 먼저 올리고 **대답을 받은 뒤에** PO 를 올렸다.
#   까닭이 분명했다 — PO 0.6 의 「내자 정리 완료 처리/해제」가 A/S 의 **새 쓰기
#   통로**(POST /api/v1/domestic-orders/{id}/completion)를 불렀고, A/S 가 아직
#   옛 판이면 그 통로가 **없어서 404** 였다.
#   🔴 **이번 판은 그 조건이 성립하지 않는다. 한 방향만 보고 정하지 않았다 —
#      양쪽을 따로 쟀다**(2026-10-30):
#     · A/S 의 35개 파일 가운데 **src/app/api/ 밑이 하나도 없다.**
#       (git diff --name-only 3bde67e..3851693 -- src/app/api  → 0줄)
#     · 두 diff 전체를 'fetch(' · '/api/v1/' · '/api/integration/' 로 훑어도
#       **더하거나 지운 줄이 0줄**이다. 즉 **PO → A/S 도, A/S → PO 도** 부르는
#       자리가 안 바뀌었다.
#     · PO 가 새로 **읽는** 것은 repair_cases.internal_target_shipment_date 와
#       workflow_steps 의 상태인데, 둘 다 **이미 있는 칸**이다(마이그레이션 0건).
#       그래서 PO 0.8 은 A/S 4.0 옆에서도, A/S 4.1 은 PO 0.7 옆에서도 선다.
#   🔵 그래서 6절이 둘을 **한 번에** 띄운다 — 정지 창이 그만큼 짧다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 A/S 도구를 **왜 올리는가** — 다툴 것이 없는 판이다
# ══════════════════════════════════════════════════════════════════════
#   잣대 셋이 전부 「올린다」다. 실측과 까닭은 48-build.sh 머리말에 길게 적었고,
#   여기에는 결론만 셋으로 줄여 둔다:
#     ㄱ) 🔴 **npm 명령이 셋 늘었다** — check:target-shipment-missing ·
#        check:due-date-inverted · check:requested-due-date-sync.
#        셋 다 **NAS 의 tools-as 에서 부를 물건**이다(셋의 머리말이 「운영 DB 에
#        직접 붙는 것은 금지라 코드 안에 세는 길이 있어야 한다」고 적는다).
#        🔴 안 올리면 그날 **npm error Missing script** 다 — 38·41번이 데인 자리다.
#     ㄴ) 🔴 **도구의 import 닫힘 안에 바뀐 파일이 아홉이다.**
#        🔵 닫힘을 잴 때 **시작점을 백필 하나로 두면 0 이 나온다** — 그러면
#           46번처럼 「안 굽는다」로 갈 뻔했다. 이번에 늘어난 명령 셋은 백필이
#           아니라서, 백필에서 출발하면 **새 도구 자신이 닫힘 밖**에 선다.
#           package.json 의 scripts 가 가리키는 scripts/*.ts **전부**(스물둘)에서
#           출발하면 닫힘이 **222개**가 되고 거기서 아홉이 겹친다.
#     ㄷ) 🔵 39번에 넓혀 둔 잣대(「tools 스테이지가 담는 것」)로도 **35 > 0** 이다.
#   🔵 **치르는 값**은 tar 하나(223MB)를 더 올리고 compose 의 image: 줄이 하나 더
#      달라지는 것뿐이다. tools-as 는 profiles: [tools] 라 **다시 뜨지도 않는다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 종에 **새 알림 둘**이 뜬다 — 켜진 채로 태어난다
# ══════════════════════════════════════════════════════════════════════
#   · REPAIR_CASE_TARGET_SHIPMENT_MISSING  「사내 목표 출하일 미등록」 주황
#       PO발행일이 적혔는데 사내 목표 출하일이 비어 있고 출하 완료가 아닌 건.
#       받는 사람: **A/S 엔지니어**(+ 최고관리자는 잠금으로 언제나).
#   · REPAIR_CASE_DUE_DATE_INVERTED        「납기 요청일 협의가 필요합니다」 호박
#       사내 목표 출하일이 고객 요청 납기일보다 늦고 출하 완료가 아닌 건.
#       받는 사람: **A/S 엔지니어·영업·관리자**(+ 최고관리자).
#
#   🔴 **둘 다 기본값이 「켜짐」이다**(defaultNotificationKindEnabled 가 true 를
#      돌려준다 — 저장소에서 읽어 확인). 저장된 값이 없으면 기본값이 이기고,
#      이 종류들은 **새 이름이라 저장된 행이 아예 없다.** 즉 앱이 뜨는 순간부터
#      계산이 돌고 종에 줄이 선다.
#   🔴 **지난 건도 함께 뜬다.** 「보냈다/안 보냈다」를 기록하지 않고 **매 요청마다
#      다시 계산**하는 구조라서다. 날짜를 고치면 저절로 빠지고 지우면 돌아온다.
#   🔴 **확인 단추가 없다 — 눌러도 안 사라진다.** 일부러 그렇게 두었다(두 커밋
#      본문이 「ACKNOWLEDGEABLE_NOTIFICATION_KINDS 에 넣으면 깨지는 시험을 넷/다섯
#      두었다」고 적는다). 사라지는 길은 **날짜를 고치는 것** 하나뿐이다.
#   🔴 **그래서 몇 줄이 설지를 먼저 보는 것이 안전하다.** 그 도구가 이번에
#      들어간다 — 이 파일의 **--count** 모드가 둘을 불러 준다(읽기 전용).
#      🔴 **--count 는 --go 뒤에 쓴다.** 그 전에는 compose 의 tools-as 가 아직
#         :7 을 가리켜 **Missing script** 가 난다. 🔵 그 답 자체가 ㄱ 의 증거라
#         --count 는 그 경우를 **✗ 가 아니라 ? 로 갈라서** 설명한다.
#      🔵 개발 DB 에서는 납기 역전이 2건이었다. **운영은 규모가 다르다** —
#         개발 DB 엔 과거 건이 거의 없다.
#   🔵 **너무 많으면 끄는 길이 있다**: 포털의 알림 설정 화면에서 그 종류를 끄면
#      된다. 그 표의 줄이 **다섯에서 일곱으로** 는다.
#      🔵 **포털을 다시 띄울 필요가 없다** — 그 목록은 A/S 가 내준다
#      (/api/integration/notification-settings · 설계서 D-5·F-4). 포털은 안에
#      무엇이 들었는지 모른다.
#
# ── 🔵 새 표도 새 칸도 없다 — 왜 마이그레이션이 0건인가 ──────────────
#   알림 종류 이름은 notification_kind_settings 의 **text 칸**(kind_key)에 들어간다.
#   그 표 머리말이 「kind_key 에 왜 enum 을 쓰지 않았나」를 적어 두었다. enum
#   이었다면 이 판에 마이그레이션이 **있어야** 했다. text 라 종류를 늘리는 데
#   DDL 이 필요 없다.
#
# ── 🔴 47번(지난 판)과 다른 것 ────────────────────────────────────────
#   ① 🔴 **시스템이 하나에서 둘로 늘었다.** SITES 에 app-po 줄이 생겼고,
#      「안 건드린 아홉」이 **여덟**이 됐다(dss-po 가 거기서 빠져 여기로 왔다).
#   ② 🔴 **5절의 「image: 줄이 꼭 몇 개 달라졌나」 기대값이 바뀐다** —
#      --go **3** (app-as · app-po · tools-as) · --rollback **2** (앱 둘).
#      47번은 2 와 1 이었다.
#   ③ 🔴 **1절이 「운영이 지금 쓰는 태그」를 통째로 찍는다.** 이 저장소의 compose
#      사본은 운영보다 **아홉 판까지** 뒤처진 적이 있다(배포가 NAS 위 파일을 한
#      줄씩 고치고 돌아오지 않는다 — 실제로 이 저장소의 사본은 아직
#      'image: dss-po:0.5' 라고 적는다). 그래서 **「사본에 있으니 운영에도」가
#      안 통한다.** 1절은 운영 파일과 **도는 컨테이너**에서 직접 읽는다.
#      🔴 compose 의 태그와 **실제로 도는 이미지**가 다를 수 있다 — 누가 줄만
#         고치고 다시 안 띄운 경우다. 그 둘을 **따로** 찍고 어긋나면 ? 로 센다.
#   ④ 🔴 **설정 파일 검사를 새로 넣었다**(아래 절).
#   ⑤ 🔵 tools_inside_check 는 47번 것을 이어받되 **단계 하나를 더했다** —
#      'npm run check:due-date-inverted' 를 **실제로 불러** Missing script 가
#      안 나는지 본다. 🔴 node 로 직접 부르면 그 실패가 **영영 안 드러난다.**
#   ⑥ 🔵 연락서 폴더 검사 · 재고 관리 통로 검사는 **42~47번 것 그대로다.**
#      🔴 **빼지 않는다** — 한 번 빼면 다시 넣는 사람이 없다.
#   ⑦ 🔵 **--rollback 은 앱 둘만 되돌린다.** 도구는 :8 그대로 둔다 —
#      39·41~47번과 같은 판단이다(새 도구가 있는 편이 낫다. 그 도구들은 전부
#      읽기 전용이고, 백필은 '--apply' 없이는 DB 에 한 글자도 안 쓴다).
#   ⑧ 🔵 **다시 띄우는 것은 app-as · app-po 둘뿐이다.** tools-as 는
#      'profiles: [tools]' 라 평소에 뜨지 않는다 — compose 의 태그만 새 것으로
#      고쳐 두면 다음에 'run --rm tools-as' 로 부를 때 새 이미지를 쓴다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 설정 파일 — **.env 와 env/*.env 를 둘 다 본다** (이 판에서 새로 넣었다)
# ══════════════════════════════════════════════════════════════════════
#   ㄱ) 🔴 **같은 이름이 두 줄 있으면 아래가 이긴다.** 하루에 네 번 난 적이
#      있고, 원인은 늘 「위를 고치고 아래에 또 적었다」였다. 그러면 고친 줄이
#      **아무 일도 안 한다.** 그래서 세 파일의 **중복 키를 센다.**
#      🔴 **값은 한 글자도 안 찍는다. 이름만 찍는다.**
#      🔵 여기서 ? 가 나도 **배포를 막지 않는다** — 이 판은 설정을 안 바꾼다.
#         다만 다음에 그 파일을 고치는 사람이 틀린 줄을 고칠 자리다.
#   ㄴ) 🔴 **컨테이너 안에서 'auto' 는 172.x 가 된다.** A/S 는 SSO_ISSUER 와
#      SSO_REDIRECT_URI 를 읽고, 값이 'auto' 또는 'auto:포트' 면 **그 기계의
#      랜 주소**로 풀어 쓴다(src/lib/config/lan-address.ts · sso.ts). 컨테이너
#      안에서 그 주소는 도커 사설망의 172.x 라 **밖에서 못 닿는다.** 그러면
#      로그인이 돌아오지 못한다.
#      🔴 그래서 둘이 **있고, 'auto' 가 아닌지**를 잰다. 값은 안 찍고
#         「fixed」/「auto」 두 글자만 찍는다.
#      🔵 지금 운영은 이미 로그인이 되고 있으니 fixed 일 것이다. **그래도
#         짐작하지 않는다** — ✓ 쪽 오판은 영영 안 드러난다.
#   🔵 **세 파일을 보는 까닭**: compose 가 .env.nas 를 --env-file 로 읽어
#      ${AS_APP_PASSWORD} 같은 치환을 하고, 앱마다 env/as.env · env/po.env 를
#      env_file 로 읽는다. 「.env 와 docker.env 를 둘 다 본다」는 규칙의
#      이 NAS 에서의 모습이 이 셋이다.
#
# ── 🔴 개발 PC → NAS 로 올릴 것 — **둘** ───────────────────────────────
#   ㄱ) 이미지 tar **셋** → /volume1/dss/images/
#        dss-as-4.1.tar · dss-as-tools-8.tar · dss-po-0.8.tar
#   ㄴ) 이 파일 → /volume1/dss/setup/
#
#   (개발 PC · PowerShell)
#     cd C:\Users\희만\Desktop\Development\_images-45
#     scp -O dss-as-4.1.tar dss-as-tools-8.tar dss-po-0.8.tar dss-nas:/volume1/dss/images/
#     cd C:\Users\희만\Desktop\Development
#     scp -O dss-deploy\nas\setup\48-deploy.sh dss-nas:/volume1/dss/setup/
#     Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\48-deploy.sh
#
# ── 모드 다섯 ─────────────────────────────────────────────────────────
#   (기본)   --check      아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --preload             tar 셋을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --go                  compose 의 image: 줄 **셋**을 바꾸고 앱 둘을 다시 띄운다
#   --rollback            앱 둘만 옛 판으로 되돌린다 (도구는 :8 그대로)
#   --count               🔵 종에 몇 줄이 뜨나를 **읽기만** 해서 센다 (--go 뒤)
#
#   🔴 차례:  --check → --preload → --check → --go → --count
#
# ── 🔴 --check 도 「아무것도 안 한다」는 아니다 ───────────────────────
#   A/S DB 에 **select** 를 한 번 보낸다(마이그레이션 수가 그대로인지 — 바꾸는
#   문장은 없다). 앱 둘의 주소에 GET 을 한 번씩 보낸다. 재고 관리 통로에도
#   **GET 을 한 번** 보낸다(읽기만 한다). 도구 이미지가 이미 실려 있으면
#   **안을 보려고 컨테이너를 잠깐 띄웠다 지운다**(docker run --rm, DB 에는 안
#   닿는다 — DATABASE_URL 을 안 주고 부른다).
#   「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 쓴 뒤 grep 으로 세었다.
#   ② 읽기 전용 자리에 콜론 하나와 꺾쇠로 빈 파일을 만들면 NAS 의 ash 가 셸을
#      그 자리에서 끝낸다(2026-10-12 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   🔴 19·20·21번에는 그 둘이 아직 남아 있다. **거기서 베껴 오지 마라.**
#
# ── 🔴 비밀값을 찍지 않는다 ───────────────────────────────────────────
#   설정 파일은 **이름이 있는가/없는가**와 **auto 인가**만 본다. 값도, 값의
#   길이도 찍지 않는다. 재고 관리 검사도 토큰을 **쓰기만** 하고 찍지 않는다 —
#   찍는 것은 HTTP 상태와 받은 줄 수뿐이다.
#   🔴 그리고 **한글을 HTTP 머리말에 넣지 않는다** — 넣으면 요청이 아예 안
#      나가고, 그 ✗ 가 진짜 결함처럼 보인다(하필 보안 검사에서 그랬다).
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v45-$STAMP

# ══ 이번에 다시 띄우는 것 — 앱 **둘** ═════════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
SITES='
as|app-as|dss-as|dss-as:4.1|dss-as:4.0|dss-as-4.1.tar|13000
po|app-po|dss-po|dss-po:0.8|dss-po:0.7|dss-po-0.8.tar|13600
'
# 🔵 7절의 재고 관리 검사가 명령을 넣을 상자. 위 표 셋째 칸과 같은 이름이다.
AS_APP_CN=dss-as
# ══ 🔴 A/S 도구 — **이번에 갈아 끼운다.** up -d 로 다시 띄우지 않는다 ═══
AS_TOOLS_SVC=tools-as
TOOLS_OLD=dss-as-tools:7
TOOLS_NEW=dss-as-tools:8
IMG_MIGDIR=/app/drizzle
MIGDIR=$D/as-migrations

# ══ 🔴 연락서 원본 폴더 — 연락서를 이식할 때 읽는 자리 ════════════════
#   🔵 기대값의 출처: 2026-10-28 실측 673장 · 143장. 늘기만 하는 폴더라 아래
#      바닥값으로 잰다. 🔴 **0 이면 볼륨 줄은 있는데 안 열리는 것**이고, 그것이
#      제일 조용한 실패다.
KYO_SRC=/kyosan-src;        KYO_SRC_MIN=600
KYO_CONV=/kyosan-converted; KYO_CONV_MIN=100

# ══ 🔴 설정 파일 — .env 쪽과 env/*.env 쪽을 **둘 다** 본다 ════════════
ENV_NAS=$D/deploy/.env.nas
ENV_AS=$D/deploy/env/as.env
ENV_PO=$D/deploy/env/po.env

# ══ 🔴 tar 셋의 지문 — [배포본] 48-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 안 채웠다.** 48-build.sh --go 가 끝에 찍어 주는 **세 줄**로 아래
#      세 줄을 통째로 갈아 끼우세요.
#      (비어 있으면 3절이 **? 로 센다** — 「옮기다 깨진 것」은 잡지만 「개발 PC 에서
#      구운 그것이 맞나」는 못 본다. ? 는 통과로 안 세므로 --preload 가 막힌다.)
#   🔵 이름만이라도 적어 두는 까닭: 줄이 아예 없으면 4절(--preload)이 **아무것도
#      안 싣고 조용히 끝난다.** 이름이 있으면 싣기는 제대로 된다.
TARS='
dss-as-4.1.tar|132592640|05432afe924a8a08d31998ad18477f93|sha256:919e7c0ebeb0a49ec0a5e53953034fa35034c18f75a8e84d6ee84f07de7faf97
dss-as-tools-8.tar|223804416|e1e21674823b1b465e6c117701ca10fd|sha256:74fad6e9fa6f91e409ff317f4d3013fea235ec93825e16361c4c2cb0cd13c41a
dss-po-0.8.tar|95437824|83cae856ac382ec114f48a03797378a8|sha256:efeb01ee7e9f8a4cd00b0c09460f86da2de95e7dd9ad8a525cb6749c6a3c6f6c
'
tar2tag() {
  case "$1" in
    dss-as-4.1.tar)      printf 'dss-as:4.1' ;;
    dss-as-tools-8.tar)  printf 'dss-as-tools:8' ;;
    dss-po-0.8.tar)      printf 'dss-po:0.8' ;;
  esac
}

# ══ 🔴 DB 는 **그대로여야** 한다(마이그레이션 0건) ════════════════════
#   🔵 A/S 와 PO 는 **같은 dss_as** 를 본다(PO 는 제 DB 가 없다 — compose 의 PO
#      블록 머리말이 그렇게 적는다). 그래서 재는 자리도 하나다.
AS_BOX=dss-pg-app; AS_DB=dss_as; AS_KEEP=121   # [저장소] 48-build.sh 4절과 같다
# 🔵 안 건드리는 **여덟** — 「옆으로 안 샜다」는 증거로 센다.
#    🔴 47번의 아홉에서 **dss-po 가 빠졌다** — 이번엔 우리가 갈아 끼운다.
KEEP_BOXES="dss-auth dss-inventory dss-meters dss-board dss-improvements dss-leave dss-approvals dss-rf-trouble"
# 🔵 DB 둘은 멈추지 않는다 (애초에 up -d --no-deps 가 앱 둘만 건드린다)
KEEP_DB="dss-pg-app dss-pg-auth"

MODE=check
case "${1:-}" in
  --check|"")  MODE=check ;;
  --preload)   MODE=preload ;;
  --go)        MODE=go ;;
  --rollback)  MODE=rollback ;;
  --count)     MODE=count ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --preload · --go · --rollback · --count\n' "$1"; exit 2 ;;
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
LOG="$D/setup/logs/48-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "마흔다섯째 배포 — A/S 앱·도구 + PO 앱   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  🔴 개발 PC 의 Get-FileHash 값과 **같은지 눈으로 맞대세요** (DSM 터미널이 긴 것을 잘라 먹습니다)"
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
# 🔴 그 줄의 낱말 수. **2 가 아니면 치환하지 마라.**
#    5절의 치환은 'sub(/[^ ]+$/, to)' 로 **줄의 마지막 낱말**을 갈아 끼운다.
#    줄 끝에 주석이 붙어 있으면(예: 'image: dss-x:1.0   # 2026-10-22 에 올림')
#    **주석의 마지막 낱말**이 태그로 바뀌고 image: 값은 그대로 남는다 —
#    2026-10-30 에 가짜 compose 로 직접 재어 확인했다. 그러면 compose 가 옛
#    이미지로 뜨면서 파일만 망가진다. 그 자리를 치환 **전에** 막는다.
nf_at() { awk -v n="$1" 'NR==n {print NF}' "$CF"; }
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

# ══ 🔴 설정 파일 — 중복 키와 auto (값은 한 글자도 안 찍는다) ══════════
#   🔴 **「비면 OK」 자리를 만들지 않는다.** 파일이 없거나 키가 0개면 그것은
#      「중복이 없다」가 아니라 **「못 쟀다」**다 — ? 로 센다.
env_file_check() { # 1 파일 2 사람이 부르는 이름
  local f n dup
  f=$1
  if [ ! -f "$f" ]; then
    hm "$2 — 파일이 없다: $f (못 쟀다)"
    return
  fi
  n=$(grep -cE '^[A-Za-z_][A-Za-z0-9_]*=' "$f" 2>/dev/null | tr -d ' ')
  if ! isnum "${n:-}" || [ "${n:-0}" -eq 0 ]; then
    hm "$2 — 이름=값 꼴의 줄이 ${n:-못 쟀다}개다. **빈 결과는 삼켜진 오류일 수 있다** — 사람이 보세요"
    return
  fi
  say "$2 — 이름=값 줄 ${n}개 (값은 안 찍는다)"
  dup=$(grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' "$f" 2>/dev/null | sed 's/=$//' | sort | uniq -d)
  if [ -z "${dup:-}" ]; then
    ok "$2 에 같은 이름이 두 번 적힌 줄이 없다"
  else
    hm "$2 에 **같은 이름이 두 번** 적혀 있다 — 🔴 **아래 줄이 이긴다.** 이름만 찍는다:"
    printf '%s\n' "$dup" | head -10 | sed 's/^/      /'
    say "🔵 이 판은 설정을 안 바꾼다 — **배포를 막지 않는다.** 다음에 그 파일을 고칠 때의 함정이다."
  fi
}
# 🔴 컨테이너 안에서 auto 는 172.x 가 된다 — 이름 둘이 있고 auto 가 아니어야 한다.
env_auto_check() { # 1 파일 2 사람이 부르는 이름 3 환경변수 이름
  local f v q
  f=$1
  if [ ! -f "$f" ]; then hm "$2 의 $3 — 파일이 없어 못 쟀다"; return; fi
  # 🔴 값은 **안 찍는다.** auto 인지 아닌지만 본다.
  # 🔴 같은 이름이 두 줄이면 **아래가 이긴다** — 그래서 tail -1 이다.
  v=$(grep -E "^$3=" "$f" 2>/dev/null | tail -1 | cut -d= -f2-)
  v=$(printf '%s' "$v" | tr -d '\r')
  q=$(printf '%s' "'")                    # 작은따옴표 한 글자 — 인용이 꼬이지 않게 따로 만든다
  v=${v#\"}; v=${v%\"}
  v=${v#"$q"}; v=${v%"$q"}
  v=${v# }; v=${v% }
  if [ -z "${v:-}" ]; then
    bad "$2 에 $3 가 없거나 비었다 — 앱이 뜨면서 던진다"
    return
  fi
  case "$v" in
    auto|auto:*)
      bad "🔴 $2 의 $3 가 **auto** 다 — 컨테이너 안에서 172.x 로 풀려 **로그인이 돌아오지 못한다.** 고정 주소를 적으세요"
      doubt ;;
    *)
      ok "$2 의 $3 가 고정값이다 (auto 가 아니다 — 값은 안 찍는다)" ;;
  esac
}

# ══ 🔴 재고 관리 통로가 **값을 돌려주는가** (45~47번 것을 글자 그대로) ══
#   🔴 **빼지 않는다.** 이것은 **앱**이 쓰는 길이다. 45번이 운영에서
#      'HTTP 200 rows 319' 를 받은 바로 그 검사다.
#   🔴 「설정이 적혀 있다」가 아니라 **「물어보니 답한다」**로 잰다.
#   🔵 **읽기만 한다.** GET /api/v1/parts 한 번이고, 저쪽 DB 에도 A/S DB 에도
#      한 글자 안 쓴다. 토큰은 쓰기만 하고 **찍지 않는다.**
#   🔵 **이번 판은 재고 관리와 무관하다** — 그래도 뺄 자리가 아니다. 이 통로가
#      막히면 [사용부품] 칸과 [고장 부품] 그래프의 반출 몫이 통째로 빠진다.
#   🔴 **머리말에 한글을 안 넣는다.** 받는 답도 일부러 ASCII 로만 찍게 했다 —
#      한글을 argv 로 넘기면 깨지는 길이 열린다.
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
#    문이 닫혀 멀쩡한 교체까지 막는다. --go 에서는 ✗ 다 — 그때는 **사람이 실제로
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
        ok "재고 관리가 답한다 — 200 · 부품 ${rows}줄"
      else
        hm "200 인데 부품 줄이 ${rows:-?} 이다 — 응답 모양이 기대와 다르다. 사람이 보세요"
        doubt
      fi ;;
    NOCONF*)
      say "🔴 **설정이 비어 있다.** 값은 안 찍는다 — 0 은 비었다는 뜻이다."
      say "   고칠 자리: $ENV_AS (root 600)"
      say "   이름 둘: INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN"
      if [ "$strict" = 1 ]; then
        bad "🔴 재고 관리 설정이 비어 **[사용부품] 칸이 막히고 [고장 부품]의 반출 몫이 빠진다**"
      else
        hm "재고 관리 설정이 비어 있다 — **이대로 --go 해도 반출 몫이 안 보인다**"
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
        bad "🔴 재고 관리가 안 답한다 — **[사용부품] 칸이 막히고 반출 몫이 빠진다.** 위 줄을 보세요"
      else
        hm "재고 관리가 안 답한다 — **이대로 --go 해도 반출 몫이 안 보인다**"
      fi
      printf '%s\n' "$out" | tail -8 | sed 's/^/      /'
      doubt ;;
  esac
}

# ══ 🔴 도구 이미지 안을 센다 — 겉이 아니라 결과 ═══════════════════════
#   🔴 이 도구는 평소에 안 뜬다. 안이 모자라도 **그날 아무 일이 안 일어나고**,
#      드러나는 것은 **쓸 일이 생긴 날**의 한 줄뿐이다.
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
  # ② 🔴 **늘어난 npm 명령 셋이 이미지 안 package.json 에 있는가.** 41번의 자리다.
  #    🔴 이름은 전부 ASCII 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "3" ] && ok "늘어난 npm 명령 셋이 이미지 안에 있다" \
    || { bad "🔴 명령이 ${got:-0}/3 개다 — **옛 package.json 이 담겼다.** 부르는 날 Missing script 가 난다"; doubt; }
  # ③ 🔴 **닫힘 안에서 바뀐 아홉이 다 담겼는가.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts /app/src/lib/db/queries/repair-case-due-date-inverted-notifications.ts /app/src/lib/db/queries/repair-case-target-shipment-notifications.ts /app/src/lib/domain/due-date-inversion.ts /app/src/lib/domain/notifications.ts /app/src/lib/domain/requested-due-date-link.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "9" ] && ok "닫힘 안에서 바뀐 아홉이 다 들어 있다" \
    || { bad "🔴 아홉 중 ${got:-0}개만 들어 있다 — scripts/ 나 src/ 가 온전히 안 담겼다"; doubt; }
  # ④ 백필 도구 파일 셋 — 43~47번 것 그대로. **빼지 않는다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts /app/scripts/lib/kyosan-used-parts-backfill-plan.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "3" ] && ok "백필 도구 파일 셋이 다 들어 있다" \
    || bad "🔴 백필 도구 파일이 ${got:-0}/3 개다 — scripts/ 가 온전히 안 담겼다"
  # ⑤ 🔴 **그 src/ 가 '이번 판' 인가 — 글자로 센다.** ③ 은 「있나」만 본다.
  #    🔵 앞의 둘은 이번 판에 **새로 생긴 파일**이라 ③ 이 이미 갈라 주지만,
  #       셋째(notifications.ts)는 **옛날부터 있던 파일**이라 ③ 이 통과해도 낡은
  #       판이 담길 수 있다. 그 자리를 막는 것이 이 단계다.
  #    🔵 셋 다 기준 3bde67e 판에는 **0번** 나오고 지금 판에는 나온다
  #       (2026-10-30 git show 로 파일마다 세어 확인: 0 → 38 · 0 → 5 · 0 → 3).
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for pair in "isRepairCaseDueDateInverted /app/src/lib/domain/due-date-inversion.ts" "countDueDateInversionStages /app/src/lib/db/queries/repair-case-due-date-inverted-notifications.ts" "REPAIR_CASE_TARGET_SHIPMENT_MISSING /app/src/lib/domain/notifications.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "3" ] && ok "이번 판의 이름 셋이 이미지 안에 있다 (옛 src/ 가 아니다)" \
    || { bad "🔴 이번 판의 이름이 ${got:-0}/3 개다 — **옛 src/ 가 담긴 이미지다.** 올리지 마세요"; doubt; }
  # ⑥ tsx 가 있는가 — 이 도구는 tsx 로만 돈다(운영 이미지에는 없는 devDependency다).
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/node_modules/tsx: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "tsx 가 있다" \
    || bad "🔴 tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다"
  # ⑦ 🔴 **값으로 받아 본다 — 새 명령을 npm 으로 실제로 부른다.**
  #    DATABASE_URL 을 안 준다. 그 파일이 1줄에서 './load-env' 를, 3줄에서
  #    '../src/lib/db/connection' 을 정적 import 하고 connection.ts 가 모듈 맨
  #    위에서 동기적으로 던진다. **DB 에는 한 글자도 안 닿는다.**
  #    🔴 'node …' 가 아니라 **'npm run …'** 으로 부르는 것이 중요하다 —
  #       41번의 실패 모양이 'npm error Missing script' 였고, node 로 직접
  #       부르면 그 실패가 **영영 안 드러난다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'cd /app && npm run check:due-date-inverted 2>&1 | head -40' 2>&1 | tr -d '\r')
  if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
    bad "🔴 **npm error Missing script** — 41번과 같은 실패다. 이 이미지의 package.json 이 옛 판이다"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
  elif printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
    ok "npm run check:due-date-inverted 가 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)"
  elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
    bad "🔴 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
  else
    hm "기대한 답이 아니다 — 아래 20줄을 사람이 보세요"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
  fi
  # ⑧ 🔵 백필도 여전히 서는가 — 43~47번이 재던 그 줄이다. **빼지 않는다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'cd /app && node --conditions=react-server --import tsx scripts/backfill-kyosan-used-parts.ts 2>&1 | head -40' 2>&1 | tr -d '\r')
  if printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
    ok "백필도 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)"
  elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
    bad "🔴 백필이 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
  else
    hm "백필의 답이 기대와 다르다 — 아래 20줄을 사람이 보세요"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
  fi
}

# ══ 🔴 연락서 폴더가 **실제로 열리는가** — 줄이 아니라 결과 ══════════
#   🔵 1절은 compose 에 줄이 있는지만 본다. 줄은 있는데 안 열리는 것이 제일
#      조용한 실패라 여기서 **수를 받아** 본다. 보내는 명령은 ls 뿐이다.
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
    say "🔵 이 줄은 **앱 교체와 무관하다 — 되돌리지 마세요.**"
    say "   연락서를 이식할 때만 필요한 폴더다. compose 의 $AS_TOOLS_SVC 볼륨을"
    say "   고치고 이 절만 다시 재면 된다."
  fi
}

# ══════════════════════════════════════════════════════════════════════
# ── --count : 종에 몇 줄이 뜨나 (읽기만 한다) ─────────────────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **--go 뒤에 쓴다.** compose 의 tools-as 가 --go 전까지 :7 을 가리키고 그
#      이미지에는 이 명령이 **없다**. 그때 나오는 'Missing script' 는 결함이
#      아니라 **ㄱ 의 증거**라, 아래는 그 경우를 ✗ 가 아니라 **?** 로 가른다.
#   🔴 이 둘은 **읽기 전용이다** — INSERT·UPDATE·DELETE 가 한 줄도 없고
#      '--apply' 같은 깃발도 일부러 두지 않았다(두 도구의 머리말).
#   🔵 찍히는 것은 인수번호와 날짜까지다. 고객사·L/N·S/N 은 조회가 애초에 안 읽는다.
#   🔴 **'--silent' 를 안 붙인다.** 붙이면 npm 의 로그 수위가 내려가 'Missing
#      script' 가 **안 찍힐 수 있고**, 그러면 아래 가지가 「못 쟀다」가 아니라
#      조용히 「건수가 안 보인다」로 흘러간다.
count_one() { # 1 npm 명령 2 사람이 부르는 이름
  local out rc
  printf '\n  ── %s  (npm run %s)\n' "$2" "$1"
  out=$(dct run --rm -T "$AS_TOOLS_SVC" npm run "$1" 2>&1)
  rc=$?
  out=$(printf '%s' "$out" | tr -d '\r')
  if printf '%s' "$out" | grep -qE 'Missing script|missing script'; then
    hm "$2 — **아직 옛 도구 이미지다**(Missing script). --go 를 먼저 하세요"
    say "🔵 이것은 결함이 아니라 **도구를 올려야 하는 까닭 그 자체**다 — 머리말 ㄱ."
    return
  fi
  if [ -z "${out:-}" ]; then
    hm "$2 — 아무것도 안 돌아왔다. **빈 결과는 삼켜진 오류일 수 있다** — 사람이 보세요"
    return
  fi
  printf '%s\n' "$out" | sed 's/^/      /'
  # 🔴 「글자가 보이나」가 아니라 **종료 코드**로 가른다. 두 도구는 세는 길과
  #    뜨는 길이 갈라지면 **찍지 않고 0 이 아닌 값으로 멈춘다**(그 머리말).
  if [ "${rc:-1}" = "0" ]; then
    ok "$2 — 셌다 (위 수를 보고 켜 둘지 판단하세요)"
  else
    bad "🔴 $2 — 도구가 종료 코드 ${rc} 로 멈췄다. **세는 길과 뜨는 길이 갈라졌다는 뜻**이다"
    doubt
  fi
}

if [ "$MODE" = count ]; then
  printf '\n== 종에 몇 줄이 뜨나 — 읽기만 한다\n'
  [ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
  printf '%s\n' "🔴 이 둘은 **쓰는 모드가 없다.** DB 에 한 글자도 안 쓴다."
  printf '%s\n' "🔵 수가 너무 크면 포털의 알림 설정에서 그 종류를 끄면 됩니다."
  count_one check:target-shipment-missing "사내 목표 출하일 미등록"
  count_one check:due-date-inverted       "납기 역전"
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 1. 지금 상태 ──────────────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
[ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
say "compose 줄 수 $(wc -l < "$CF") · image: 줄 $(grep -c '^ *image:' "$CF")개"

# ── ㄱ) 🔴 **운영이 지금 쓰는 태그 전부** — 저장소 사본을 믿지 않는다 ──
#   이 저장소의 compose 사본은 운영보다 뒤처진다(아홉 판 차이가 난 적이 있고,
#   지금도 사본에는 'image: dss-po:0.5' 라고 적혀 있다). 배포는 NAS 위 파일을
#   한 줄씩 고치고 돌아오지 않는다. 그래서 **여기서 직접 읽어 로그에 남긴다.**
printf '\n    ── 운영 compose 의 image: 줄 전부 (이 파일이 진짜다)\n'
grep -n '^ *image:' "$CF" | sed 's/^/      /'
printf '\n    ── 지금 **도는** 컨테이너와 그 이미지 (compose 와 다를 수 있다)\n'
"$DOCKER" ps -a --format '{{.Names}} {{.Image}} {{.Status}}' 2>/dev/null | sort | sed 's/^/      /'

for r in $(rows); do
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  printf '\n    ── %s\n' "$SVC"
  L=$(img_line "$SVC") || { bad "$SVC — compose 에서 image: 줄을 못 찾았다"; continue; }
  CUR=$(tag_at "$L")
  ST=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  say "$SVC — ${L}줄 · compose ${CUR} · 도는 것 ${RUN:-없음} (${ST:-?})"
  case "$MODE" in
    rollback)
      # 🔵 되돌릴 때는 새 판이 서 있어야 정상이다. 기대값이 모드마다 다르다.
      if [ "$CUR" = "$NEW" ]; then ok "$SVC 가 $NEW 다 (되돌릴 준비)"
      elif [ "$CUR" = "$OLD" ]; then hm "$SVC 가 이미 $OLD 다 (벌써 되돌렸나)"
      else bad "$SVC 의 태그가 $CUR 다 — 옛 판도 새 판도 아니다. 멈추고 알릴 것"; doubt; fi ;;
    *)
      if [ "$CUR" = "$OLD" ]; then ok "$SVC 가 옛 판 $OLD 다 (갈아 끼울 준비)"
      elif [ "$CUR" = "$NEW" ]; then hm "$SVC 가 이미 $NEW 다 (다시 돌리는 중인가)"
      else
        bad "$SVC 의 태그가 $CUR 다 — $OLD 도 $NEW 도 아니다. 멈추고 알릴 것"
        say "🔴 **이 저장소의 compose 사본을 믿고 적은 값이 아니다** — 48-build.sh 머리말이"
        say "   31-build.sh 와 README 의 기준 SHA 표에서 역산한 값이다. 그래도 어긋났다면"
        say "   운영이 그 사이 따로 움직였다는 뜻이다. **고치지 말고 알리세요.**"
        doubt
      fi ;;
  esac
  # 🔴 **compose 의 태그와 실제로 도는 이미지가 같은가** — 줄만 고치고 다시 안
  #    띄운 경우가 있다. 그때는 교체가 「아무 일도 안 한 것처럼」 보인다.
  if [ -z "${RUN:-}" ]; then
    hm "$CN 가 안 뜬 것 같다 — Config.Image 를 못 읽었다"
  elif [ "$RUN" = "$CUR" ]; then
    ok "$CN 가 compose 에 적힌 그 태그로 돈다 ($RUN)"
  else
    hm "$CN 는 $RUN 로 도는데 compose 는 $CUR 라고 적는다 — 줄만 고치고 안 띄운 상태다"
    say "🔵 **교체를 막지 않는다** — --go 가 어차피 다시 띄운다. 다만 되돌릴 때 기준이 흔들린다."
  fi
done

# ══ 🔴 A/S 도구 — **이번엔 이 배포가 고치는 줄이다** ═════════════════
printf '\n    ── %s\n' "$AS_TOOLS_SVC"
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  say "$AS_TOOLS_SVC — ${TL}줄 · $TCUR"
  case "$MODE" in
    rollback)
      # 🔵 되돌려도 도구는 :8 그대로 둔다(머리말 ⑦). 그래서 기대값이 새 판이다.
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
  # 🔴 42번에서 넣은 검사다. **없어도 교체를 막지 않는다** — 그래서 ✗ 가 아니라
  #    ? 로 센다(✗ 는 4·5절의 문을 닫아 멀쩡한 교체까지 막는다).
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

# ══ 🔴 PO 쪽 — **도구 서비스가 없는 것이 맞다** ═══════════════════════
#   짐작으로 「없다」고 적지 않는다. 생겼으면 이 줄이 알려 준다.
if img_line tools-po >/dev/null 2>&1; then
  hm "compose 에 tools-po 가 **생겼다** — 지금까지 없던 것이다. 이 배포의 범위 밖이니 사람이 보세요"
else
  ok "compose 에 tools-po 가 없다 (없는 것이 맞다 — PO 에는 NAS 에서 돌릴 스크립트가 없다)"
fi

# ── 1-ㄴ. 🔴 설정 파일 — 중복 키와 auto (값은 안 찍는다) ──────────────
printf '\n    ── 설정 파일 (이름만 본다. 값도, 값의 길이도 안 찍는다)\n'
env_file_check "$ENV_NAS" ".env.nas"
env_file_check "$ENV_AS"  "env/as.env"
env_file_check "$ENV_PO"  "env/po.env"
env_auto_check "$ENV_AS" "env/as.env" SSO_ISSUER
env_auto_check "$ENV_AS" "env/as.env" SSO_REDIRECT_URI
env_auto_check "$ENV_PO" "env/po.env" SSO_ISSUER
env_auto_check "$ENV_PO" "env/po.env" SSO_REDIRECT_URI
say "🔵 **이 판은 설정을 하나도 안 바꾼다** — 새 환경변수가 한 개도 없다."

# ── 2. 🔴 DB — 마이그레이션 수가 **그대로여야** 한다 ──────────────────
#   🔵 A/S 와 PO 가 같은 dss_as 를 본다. 그래서 재는 자리가 하나다.
printf '\n== 2. DB (dss_as · A/S 와 PO 가 함께 쓴다) — 마이그레이션 %s 그대로여야 한다\n' "$AS_KEEP"
MIG_AS0=$(mig_count "$AS_BOX" "$AS_DB")
say "기록 ${MIG_AS0:-?} (기대 $AS_KEEP 그대로)"
if [ -z "${MIG_AS0:-}" ]; then
  bad "DB 를 못 쟀다 — $AS_BOX 가 도는지 보세요"
elif [ "$MIG_AS0" = "$AS_KEEP" ]; then
  ok "$AS_KEEP 그대로다 (이 배포는 DB 를 건드리지 않는다)"
else
  bad "🔴 ${MIG_AS0} 이다 ($AS_KEEP 이어야 한다) — 다른 배포가 먼저 돌았거나 전제가 깨졌다"
  doubt
fi

# ── 3. 들여올 이미지 셋 ───────────────────────────────────────────────
printf '\n== 3. 들여올 이미지 셋 (앱 둘 · 도구 하나)\n'
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
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 48-build.sh --go 가 끝에 찍어 주는"
  printf '%s\n' "     **세 줄**로 이 파일의 TARS 세 줄을 통째로 갈아 끼우세요."
fi
# 🔵 되돌릴 길 — 옛 태그가 남아 있는가(앱 둘만. 도구는 되돌리지 않는다)
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
if [ "$MODE" = check ]; then inventory_gateway_check soft; fi

if [ "$MODE" = check ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.** 다음: --preload → (다시 --check) → --go → --count"
  printf '%s\n' "🔴 올리기 전에 돌리면 ? 가 여럿 나오는 것이 **정상**이다 (tar 셋)."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 4. --preload : tar 셋을 들여놓는다 ───────────────────────────────
if [ "$MODE" = preload ] || [ "$MODE" = go ]; then
  printf '\n== 4. tar 셋을 들여놓는다\n'
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 하고 멈춘다.**\n'; exit 1; fi
  LOADED=0
  for t in $(trows); do
    TAR=$(fld "$t" 1); NEW=$(tar2tag "$TAR")
    if [ -z "$NEW" ]; then bad "$TAR 의 태그를 모른다 — tar2tag() 에 줄을 더하세요"; continue; fi
    T=$IMGD/$TAR
    if [ ! -s "$T" ]; then bad "$TAR 가 없다: $T"; continue; fi
    WCFG=$(tar -xOf "$T" manifest.json 2>/dev/null | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 | sed 's|blobs/sha256/|sha256:|')
    if "$DOCKER" image inspect "$NEW" --format '{{.Id}}' 2>/dev/null | grep -q "$WCFG"; then
      ok "$NEW 는 이미 있고 지문이 tar 와 같다 (건너뜀)"; LOADED=$((LOADED+1)); continue
    fi
    "$DOCKER" load -i "$T" 2>&1 | sed 's/^/    /'
    FULL=$("$DOCKER" image inspect "$NEW" --format '{{.Id}}' 2>/dev/null)
    if [ "$FULL" = "$WCFG" ]; then ok "$NEW 가 올라왔고 지문이 tar 와 같다"; LOADED=$((LOADED+1))
    elif [ -n "$FULL" ]; then bad "$NEW 지문이 다르다 — tar $WCFG / NAS $FULL"
    else bad "$NEW 가 안 올라왔다"; fi
  done
  # 🔴 **「몇 개 실었나」를 센다.** 줄이 비어 있으면 위 고리가 **아무것도 안 하고
  #    조용히 끝난다** — 그 자리를 막는다.
  say "실린 이미지 ${LOADED}개 (기대 3)"
  if [ "$LOADED" = "3" ]; then ok "셋이 다 실렸다"
  else bad "🔴 ${LOADED}/3 개만 실렸다 — TARS 가 비었거나 tar 가 모자란다"; fi
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
#  🔴 --go 는 **셋**(app-as·app-po·tools-as)을 고친다. --rollback 은 **앱 둘**만
#     되돌린다 — 도구는 :8 그대로 둔다(39·41~47번과 같은 판단).
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
  # 🔴 치환 **전에** 줄 모양을 본다 — 주석이 붙어 있으면 엉뚱한 낱말이 바뀐다.
  NF=$(nf_at "$L")
  if [ "${NF:-0}" != "2" ]; then
    bad "🔴 $SVC 의 ${L}줄이 낱말 ${NF:-?}개다 — 'image: 태그' 두 낱말만 있어야 한다. 줄 끝에 주석이 붙었는지 보세요"
    awk -v n="$L" 'NR==n' "$CF" | sed 's/^/      /'
    doubt
    continue
  fi
  TMP=$(mktemp) || exit 1
  awk -v n="$L" -v to="$TO" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
  cp "$TMP" "$CF"; rm -f "$TMP"
  NOW=$(tag_at "$L")
  if [ "$NOW" = "$TO" ]; then ok "$SVC → $TO (${L}줄)"; else bad "$SVC 의 태그가 $NOW 다"; fi
done

# 🔴 도구는 --go 일 때만 고친다. --rollback 은 **손대지 않는다.**
if [ "$MODE" = go ]; then
  TL=$(img_line "$AS_TOOLS_SVC") || { bad "$AS_TOOLS_SVC — image: 줄을 못 찾았다"; }
  TNF=$(nf_at "${TL:-0}")
  if [ -n "${TL:-}" ] && [ "${TNF:-0}" != "2" ]; then
    bad "🔴 $AS_TOOLS_SVC 의 ${TL}줄이 낱말 ${TNF:-?}개다 — 'image: 태그' 두 낱말만 있어야 한다"
    awk -v n="$TL" 'NR==n' "$CF" | sed 's/^/      /'
    doubt
    TL=""
  fi
  if [ -n "${TL:-}" ]; then
    TMP=$(mktemp) || exit 1
    awk -v n="$TL" -v to="$TOOLS_NEW" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
    cp "$TMP" "$CF"; rm -f "$TMP"
    TNOW=$(tag_at "$TL")
    if [ "$TNOW" = "$TOOLS_NEW" ]; then ok "$AS_TOOLS_SVC → $TOOLS_NEW (${TL}줄)"; else bad "$AS_TOOLS_SVC 의 태그가 $TNOW 다"; fi
  fi
else
  say "🔵 $AS_TOOLS_SVC 는 이번 모드($MODE)에서 **안 건드린다** — $TOOLS_NEW 그대로 둔다"
fi

L1=$(wc -l < "$CF"); IMGS1=$(grep -c '^ *image:' "$CF")
grep -n '^ *image:' "$CF" > "$AFT"
DIFFN=$(diff "$BEF" "$AFT" | grep -c '^[<>]')
rm -f "$BEF" "$AFT"
say "줄 수 $L0 → $L1 · image: 줄 $IMGS0 → $IMGS1 · 달라진 image: 줄 $((DIFFN / 2))개"
[ "$L1" = "$L0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
[ "$IMGS1" = "$IMGS0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
# 🔴 **남의 image: 줄을 건드리면 안 된다.** --go 는 셋(app-as·app-po·tools-as),
#    --rollback 은 둘(앱 둘)만 달라져야 한다.
if [ "$MODE" = go ]; then WANT_DIFF=3; else WANT_DIFF=2; fi
[ "$((DIFFN / 2))" = "$WANT_DIFF" ] && ok "image: 줄이 꼭 ${WANT_DIFF}개만 달라졌다 (우리 것)" \
  || { bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — ${WANT_DIFF}개를 기대했다. 남의 것을 건드렸을 수 있다"; doubt; }
dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 6. 앱 둘을 다시 띄운다 ────────────────────────────────────────────
#  🔴 tools-as 는 profiles: [tools] 라 up -d 로 띄우지 않는다. 태그만 고쳐 두면
#     다음에 run --rm tools-as 로 부를 때 새 이미지를 쓴다.
printf '\n== 6. 앱 둘(app-as · app-po)을 다시 띄운다\n'
printf '%s\n' "🔴 --no-deps 다 — 앱 둘만 갈아 끼운다. 나머지 여덟과 DB 둘은 안 건드린다."
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
  # 🔴 303(See Other)을 빠뜨리면 **멀쩡한 사이트가 ✗ 로 나온다**(2026-10-30 실측).
  #    A/S 는 307 로 로그인에 보내는데 PO 는 303 으로 보낸다 —
  #    `curl -w '%{redirect_url}'` 로 재니 둘 다 /api/auth/sso/start 였다.
  #    로그인으로 넘기는 방식이 사이트마다 다르므로 3xx 리다이렉트는 넷을 다 받는다.
  printf '%s' "$CODE" | grep -qE '200|30[1237]' && ok "$CN 가 응답한다 ($CODE)" || bad "$CN 응답이 ${CODE:-없음}"
done

# 🔴 DB — 마이그레이션 수가 **여전히** 그대로인가 (이 배포는 DB 를 안 건드린다)
MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
say "마이그레이션 ${MIG_AS0:-?} -> ${MIG_AS1:-?} (그대로여야 한다)"
[ "${MIG_AS1:-x}" = "$AS_KEEP" ] && ok "$AS_KEEP 그대로다 (DB 를 안 건드렸다)" \
  || bad "🔴 ${MIG_AS1:-?} 다 — $AS_KEEP 그대로여야 한다. 이 배포가 DB 를 건드렸다면 전제가 틀렸다"

# 🔴 도구 태그가 제대로 섰는지 + 이미지 안이 온전한지 다시 센다
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  # 🔵 --go 도 --rollback 도 도구 기대값은 **$TOOLS_NEW 로 같다** — 되돌려도
  #    도구는 :8 그대로 둔다(머리말 ⑦).
  [ "$TCUR" = "$TOOLS_NEW" ] && ok "$AS_TOOLS_SVC 가 $TOOLS_NEW 다" \
    || bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $TOOLS_NEW 를 기대했다"
  "$DOCKER" image inspect "$TCUR" >/dev/null 2>&1 && ok "$TCUR 이미지가 NAS 에 있다" \
    || bad "$TCUR 이미지가 NAS 에 없다 — 다음에 부를 때 못 쓴다"
fi
if [ "$MODE" = go ]; then tools_inside_check; fi
# 🔴 42번에서 넣은 검사는 **그대로 둔다** — 연락서 폴더가 줄만 있는 게 아니라
#    실제로 열리는지 센다.
if [ "$MODE" = go ]; then kyosan_folder_check; fi

# 🔴 **안 건드린 여덟이 그대로 도는지** 센다 — 「옆으로 안 샜다」는 증거다.
printf '\n    ── 안 건드린 여덟 (그대로여야 한다)\n'
KEEP_SEEN=0
for c in $KEEP_BOXES; do
  KEEP_SEEN=$((KEEP_SEEN+1))
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
  [ "$s" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
done
# 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다.
[ "$KEEP_SEEN" = "8" ] && ok "안 건드린 여덟을 다 봤다 (표본이 비지 않았다)" \
  || bad "안 건드린 상자를 ${KEEP_SEEN}개만 봤다 — 여덟을 기대했다. KEEP_BOXES 가 깨졌다"

# 🔴 **「상자가 돈다」와 「물어보니 답한다」는 다른 말이다.**
if [ "$MODE" = go ]; then inventory_gateway_check strict; fi

printf '\n    ── DB 둘이 안 멈췄는가 (시작 시각이 그대로여야 한다)\n'
for c in $KEEP_DB; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
  b=$(printf '%s' "$DBSTART" | tr ' ' '\n' | sed -n "s/^$c=//p")
  printf '      %-14s %s\n' "$c" "${s:-없음}"
  [ "${s:-x}" = "${b:-y}" ] && ok "$c 가 안 멈췄다" || bad "🔴 $c 가 다시 떴다 (${b:-?} -> ${s:-?})"
done

printf '\n    ── 최근 로그 (12줄씩)\n'
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
  printf '%s\n' "🔵 **백필은 다시 돌리지 않는다.** 44~47번과 같다 — 까닭:"
  printf '%s\n' "   · 백필은 2026-10-29 새벽에 283건이 끝났다(사용 부품 978줄이 품번으로 들어가 있다)."
  printf '%s\n' "   · 이번 판은 **날짜 둘을 견주는 화면·알림**이다. 연락서를 읽는 규칙과 무관하다."
  printf '%s\n' "   🔵 도구는 올렸지만 돌릴 까닭은 없다 — 올리는 것과 돌리는 것은 다른 일이다."
  printf '%s\n' ""
  if [ "$MODE" = go ]; then
    printf '%s\n' "🔴 **먼저 이것부터 — 종에 몇 줄이 뜨나 세어 보세요 (읽기만 합니다):**"
    printf '%s\n' "      bash $0 --count"
    printf '%s\n' "   🔵 새 알림 둘은 **켜진 채로 태어나고 지난 건도 함께 뜹니다.**"
    printf '%s\n' "      수가 너무 크면 포털의 알림 설정에서 그 종류를 끄면 됩니다."
    printf '%s\n' ""
  fi
  printf '%s\n' "🔴 **마지막은 눈입니다** — 이번 판은 볼 곳이 **넷**입니다."
  printf '%s\n' ""
  printf '%s\n' "  ① **A/S → 수리 건 상세 → 접수 정보**"
  printf '%s\n' "     사내 목표 출하일이 고객 요청 납기일보다 **늦으면** 그 날짜가 **굵은 붉은색**이"
  printf '%s\n' "     되고 「협의 필요」 메모가 붙습니다."
  printf '%s\n' "     🔵 **출하가 끝난 건에는 안 뜹니다** — 지난 건에 붉은 글이 남으면 알려 주세요."
  printf '%s\n' "     🔵 메모와 **출처 표시**가 테두리 상자 안에 한 줄로 들어갑니다. 색이 갈립니다 —"
  printf '%s\n' "        **출처는 회색, 경보는 붉은색**. 출처 문구가 「내자 정리에서 작성됨」으로 바뀝니다."
  printf '%s\n' ""
  printf '%s\n' "  ② **A/S → 내자 정리** 의 「납기요청일」 칸"
  printf '%s\n' "     같은 규칙으로 날짜가 붉어지고 「협의 필요」 넉 자가 붙습니다(긴 문장은 마우스를"
  printf '%s\n' "     올리면 나옵니다). **카드(좁은 화면)도 표와 같은 부품**을 씁니다."
  printf '%s\n' "     🔵 날짜가 여럿인 줄은 **가장 이른 하루**로 잽니다."
  printf '%s\n' "     🔵 줄에 날짜가 없을 때만 수리 건에서 빌려 옵니다 — 그때는 출처 표시가 남습니다."
  printf '%s\n' "     🔵 **납기일 추가 편집은 한 글자도 안 건드렸습니다**(분할 납품 건이 쓰는 기능)."
  printf '%s\n' ""
  printf '%s\n' "  ③ 🔴 **PO → 내자 정리** 의 같은 칸 — **이번 판의 핵심 확인입니다**"
  printf '%s\n' "     PO 쪽은 A/S 의 같은 조각을 **바이트 그대로 옮긴 사본**입니다. 그래서"
  printf '%s\n' "     **두 화면을 나란히 열어 같은 줄이 같은 색·같은 말인지** 보세요."
  printf '%s\n' "     🔴 한쪽만 붉으면 그것이 결함입니다 — 알려 주세요."
  printf '%s\n' "     🔵 PO 에는 종 알림이 없습니다 — 화면만 바뀝니다."
  printf '%s\n' ""
  printf '%s\n' "  ④ **알림 종** — 새 종류가 **둘** 늘었습니다"
  printf '%s\n' "     · 「사내 목표 출하일 미등록」 **주황** — PO발행일이 적혔는데 사내 목표 출하일이"
  printf '%s\n' "       비어 있는 건. 받는 사람: **A/S 엔지니어**(최고관리자도)."
  printf '%s\n' "     · 「납기 요청일 협의가 필요합니다」 **호박** — 납기 역전. 받는 사람:"
  printf '%s\n' "       **A/S 엔지니어·영업·관리자**(최고관리자도)."
  printf '%s\n' "     🔴 **둘 다 눌러도 안 사라집니다 — 확인 단추가 없습니다.** 일부러 그렇게"
  printf '%s\n' "        두었습니다. 사라지는 길은 **날짜를 고치는 것** 하나뿐입니다."
  printf '%s\n' "     🔴 **지난 건도 함께 뜹니다** — 매 요청마다 다시 계산하는 구조입니다."
  printf '%s\n' "     🔵 두 색이 **다른 것이 중요합니다**. 같은 건에서 차례로 뜨는 짝이라 같은 색이면"
  printf '%s\n' "        종에서 구별이 안 됩니다."
  printf '%s\n' "     🔵 **포털의 알림 설정 표가 다섯 줄에서 일곱 줄로** 늡니다. 포털을 다시 띄울"
  printf '%s\n' "        필요는 없습니다 — 그 목록은 A/S 가 내줍니다."
  printf '%s\n' ""
  printf '%s\n' "  🔵 **아무것도 안 바뀐 것처럼 보이면** 앱 둘이 정말 새 태그로 도는지(위 7절) 먼저"
  printf '%s\n' "     보시고, 맞다면 알려 주세요."
  printf '%s\n' ""
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (앱 둘만 되돌립니다. DB 를 안 건드렸으니"
  printf '%s\n' "               자료 손실이 없습니다. 🔵 도구는 $TOOLS_NEW 그대로 둡니다)"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
  printf '%s\n' "  🔵 ✗ 가 **재고 관리 통로** 하나뿐이라면 되돌리기 전에 설정을 먼저 보세요 —"
  printf '%s\n' "     INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN (env/as.env). 🔴 되돌려도 같은"
  printf '%s\n' "     설정 문제는 남습니다 — 옛 판도 같은 통로를 씁니다."
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
