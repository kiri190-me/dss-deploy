#!/bin/bash
# /volume1/dss/setup/26-deploy.sh — 2026-10-13 스물한째 배포
#
# ── 🔴 이번에 갈아 끼우는 것 **둘** ────────────────────────────────────
#
#     포털     dss-auth:1.6   →  **dss-auth:1.7**    (커밋 3개)
#     게시판   dss-board:0.1  →  **dss-board:0.2**   (커밋 **7개**)
#
#   나머지 다섯(A/S 2.5 · 계측기 1.3 · 개선요청 0.3 · PO 0.5 · 휴가 0.2)은
#   **건드리지 않는다. 멈추지도 않는다.**
#
# ══ 이 일곱(아니 열) 커밋은 **한 가지 일**이다 ═════════════════════════
#
#   「어느 시스템에서 종을 열어도 **모든 사내 시스템의 알림**이 보인다」를
#   사내 게시판까지 넓히는 것이다. 게시판은 오늘 15:09 에 처음 섰고 알림은
#   **그 뒤에** 붙었다 — 그래서 **지금 운영 게시판에는 알림이 통째로 없다.**
#
#   · 게시판 쪽(0.2) — 종을 달고, 포털에 내줄 통로 둘을 열고, 남의 알림을
#     제 종에 합친다.
#   · 포털 쪽(1.7)   — 알림 출처 목록에 **게시판**과 **재고 관리**를 더한다.
#     🔴 그 목록은 **코드에 박힌 상수**다(sources.ts). 그래서 .env 에 더할
#        줄이 **하나도 없다** — 아래 「직접 확인한 것 ②」.
#
# ══ 🔴 지시서와 **다른 것 하나** — 게시판은 커밋이 **일곱**이다 ════════
#
#   받은 지시서는 게시판을 네 커밋(5f78f93 · 144c60a · 85b391d · e4fd9c9)
#   이라 적었다. 🔴 **실측은 일곱이다.** 까닭:
#
#     dss-board:0.1 은 **8980a60**(10-13 13:34)으로 구워졌다. 그 뒤 15:09 에
#     운영에 섰고, 그 다음 커밋은 16:11 이다 — 그 사이에 커밋이 없다.
#     그러므로 0.1 과 HEAD 사이에는 일곱이 있다:
#
#       7c2059a 16:11  탭 아이콘을 회사 로고로
#       30c3e8b 16:11  머리말에 [통합 로그인으로]
#       745b756 16:40  머리말에 **알림 종** — 안 읽은 공지를 띄운다
#       5f78f93 17:04  공지 알림을 포털에 내준다
#       144c60a 17:10  알림 설정 통로
#       85b391d 17:26  종에 **다른 시스템 알림**을 합친다
#       e4fd9c9 17:45  필독도 알림이 된다 (종류가 하나에서 둘로)
#
#   🔵 README(10-13 저녁)가 그것을 뒷받침한다 — 「알림 종 … 이번에 메뉴바만
#      붙였다. **종까지 붙이면** 다른 사이트와 한 벌이 된다」. 0.1 에는 종이
#      없었다는 뜻이다.
#   🔴 그래서 **눈으로 볼 것이 셋 더 있다**(맨 아래 안내): 탭 아이콘 ·
#      머리말의 [통합 로그인으로] · 머리말의 **종 자체**.
#
# ══ 🔴 포털은 **로그인 문**이다 — 게시판보다 조심한다 ══════════════════
#
#   일곱 사이트 전부가 이 문을 지나 들어온다. 포털이 안 뜨면 **아무도 아무
#   데도 못 들어간다.** 그래서 24번이 포털에만 두었던 넷을 그대로 가져왔다:
#     ① 🔴 되돌리는 길을 맨 위에 적어 둔다 — 급할 때 그대로 칠 줄.
#     ② 🔴 로그인 길을 스모크로 본다 — /signin · / · discovery · jwks.
#        🔵 **실제 계정으로 로그인하지는 않는다**(사람이 한다).
#     ③ 🔴 서명 키 볼륨(/keys)을 새 컨테이너 안에서 실제로 읽어 본다.
#     ④ 🔴 세션이 끊기는지를 **숫자로** 센다(바꾸기 전과 뒤).
#
#   🔵 **다시 로그인하지 않아도 된다.** 세션은 DB(dss_auth · sso_sessions)에
#      있고 이 배포는 dss-pg-auth 를 멈추지 않는다. 서명 키도 이미지가 아니라
#      호스트 폴더(/volume1/dss/auth-keys)에 있다. 게시판 쪽 세션도 같다 —
#      web_sessions 는 dss_board 안이고 dss-pg-app 은 멈추지 않는다.
#      🔴 다만 바꿔 끼우는 **그 몇 초** 동안 들어온 요청은 실패한다.
#
# ══ 🔴 내가 직접 확인한 것 셋 (지시서를 믿지 않고 열어 봤다) ═══════════
#
#   ① **마이그레이션 — 양쪽 다 0건이다.**
#      · 포털:   git log --oneline c51ff52..HEAD -- drizzle/   → **빈 출력**
#      · 게시판: git log --oneline 8980a60..HEAD -- drizzle/   → **빈 출력**
#      게시판의 drizzle/ 에는 0000_blue_taskmaster.sql 하나뿐이고 그것은
#      오늘 낮 첫 설치에서 이미 운영에 적용됐다(표 7개).
#      🔴 그래서 이 판에는 **묶음도 db:migrate 도 db:preflight 도 적용 직전
#         덤프도 「지우는 문장」 잣대도 한 줄도 없다**(22 · 24번과 같다).
#      🔵 그래도 **배포 전 백업 검사는 그대로 뒀다** — 17번에서 그것이 실제로
#         배포를 막아 사고를 피했다. 🔴 이번에 볼 것은 **둘**이다:
#         dss_auth 와 dss_board.
#
#   ② **새 볼륨도 새 환경변수도 없다.**
#      · 포털: 바뀐 파일이 **둘뿐**이다 — sources.ts · sources.test.ts.
#        알림 출처 목록이 **코드에 박힌 상수**다(그 파일 머리말이 「상수로
#        두기로 정했다」고 못 박았다). process.env 를 **한 줄도 더 읽지 않는다**
#        (git diff 에서 새로 생긴 process.env 줄 **0개**).
#      · 게시판: src/lib/env.ts 가 늘었지만 **새 이름이 아니다** — ownBaseUrl
#        이라는 getter 가 생겼고, 그 값은 **이미 있는 OIDC_REDIRECT_URI** 에서
#        콜백 경로를 떼어 만든다. 🔴 **그래서 새 설정이 늘지 않는 대신, 그
#        값이 /api/auth/callback 으로 끝나지 않으면 던진다** — 아래 1-ㄹ 이
#        그것을 본다.
#      · 볼륨: 게시판은 첨부 하나(/volume1/dss/board-uploads → /data/uploads),
#        포털은 서명 키 하나(/keys:ro). **둘 다 이미 붙어 있던 그대로**다.
#
#   ③ **이미지 지문 자리는 비워 뒀다.**
#      🔴 이 스크립트를 쓸 때 1.7 도 0.2 도 **아직 안 구워졌다.** 그래서
#         여섯 상수가 **비어 있다** — SZ/MD5/WANT_CFG 가 둘씩.
#         비어 있는 동안 --check 는 그 자리를 ⚠️ 로만 말하고,
#         🔴 **--go 는 시작조차 하지 않는다.** 잰 적 없는 이미지를 운영에
#         올리지 않기 위해서다. **사람이 구운 뒤 채운다.**
#
# ══ 🔴 돌리기 전에 — **값 여섯을 채워야 한다** ═════════════════════════
#
#   개발 PC(PowerShell)에서 굽고 재는 차례 — 폴더는
#   C:\Users\희만\Desktop\Development 다:
#
#     cd C:\Users\희만\Desktop\Development\dss-auth
#     git status --short                      ← **비어 있어야 한다**
#     docker build -t dss-auth:1.7 .
#     cd ..\dss-board
#     git status --short                      ← **비어 있어야 한다**
#     docker build -t dss-board:0.2 .
#     cd ..
#     docker save dss-auth:1.7  -o dss-auth-1.7.tar
#     docker save dss-board:0.2 -o dss-board-0.2.tar
#     (Get-Item dss-auth-1.7.tar).Length              ← SZ_AUTH
#     Get-FileHash -Algorithm MD5 dss-auth-1.7.tar    ← MD5_AUTH (소문자로)
#     tar -xOf dss-auth-1.7.tar manifest.json         ← Config → WANT_CFG_AUTH
#     (Get-Item dss-board-0.2.tar).Length             ← SZ_BOARD
#     Get-FileHash -Algorithm MD5 dss-board-0.2.tar   ← MD5_BOARD (소문자로)
#     tar -xOf dss-board-0.2.tar manifest.json        ← Config → WANT_CFG_BOARD
#
#   🔴 **게시판은 --target 을 적지 않는다.** 그 저장소 Dockerfile 은 runner 가
#      맨 뒤라 --target 없이 구우면 앱이 나온다(그 파일 주석이 그 까닭을
#      적어 두었다). 도구 이미지는 이번에 **안 굽는다** — 아래 「도구」절.
#   🔴 **tar 가 이미지의 1/4 쯤인 것은 정상이다.** 지난 판과 견준다 —
#      dss-board-0.1.tar 가 96,508,416 바이트였다. 🔵 이번 판은 코드만 늘었다
#      (favicon 1.6KB 하나 빼고 전부 .ts/.tsx) — 비슷한 크기가 정상이다.
#   🔴 **tar 안 Config 지문은 개발 PC 의 {{.Id}} 와 다르다.** NAS 는 tar 안의
#      config 지문을 image ID 로 낸다 — **맞춰 볼 값은 tar 쪽**이다.
#   🔴 **git archive 로 뽑지 마라** — 작업 폴더에서 굽되 git status 가 비어야 한다.
#
# ══ 🔵 도구 이미지 — **이번엔 안 굽는다** ══════════════════════════════
#
#   dss-board-tools:1 을 그대로 둔다. 까닭은 짐작이 아니라 실측이다:
#   0.1 이후 바뀐 파일 **열넷**이 전부 src/ 와 tsconfig.json 이고,
#   **scripts/ 도 drizzle/ 도 package.json 도 한 글자도 안 바뀌었다.**
#   도구가 하는 일(db:migrate · make:admin · cleanup:orphans)이 그대로다.
#   🔵 포털에는 도구 서비스가 **아예 없다**(tools-auth 가 compose 에 없다).
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/26-deploy.sh           ← 읽기만 한다
#
#   🔴 NAS 의 docker 는 **sudo(root)** 가 필요하다. root 가 아니면 멈춘다.
#
# ══ 🔴 개발 PC → NAS 로 올릴 것 **셋** ═════════════════════════════════
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#      아래는 **개발 PC 의 PowerShell** 에서 친다(NAS 가 아니다).
#
#     scp -O dss-auth-1.7.tar dss-nas:/volume1/dss/images/
#     scp -O dss-board-0.2.tar dss-nas:/volume1/dss/images/
#     scp -O docker-compose.nas.yml dss-nas:/volume1/dss/setup/incoming/
#
#   🔴 세 번째 줄의 compose 는 **dss-deploy 저장소의 nas/docker-compose.nas.yml**
#      이고, 거기서 고칠 줄은 **딱 둘**이다:
#        app-auth  의  image: dss-auth:1.6   →  dss-auth:1.7
#        app-board 의  image: dss-board:0.1  →  dss-board:0.2
#   🔴 **마이그레이션 묶음도 도구 이미지도 올릴 것이 없다.**
#   🔵 scp 가 바로 안 되면 사용자 계정(swhur)의 홈으로 올린 뒤 NAS 에서
#      sudo mv 로 옮긴다. /volume1/dss 아래는 root 만 쓸 수 있다.
#
# ══ 🔴 같은 날 다른 에이전트가 **재고관리 첫 설치**를 쓰고 있다 ════════
#
#   27-*.sh 와 compose 의 app-inventory 가 그것이다. 🔴 **이 배포는 그것을
#   건드리지 않는다.** 다만 compose 는 **한 파일**이라 섞일 수 있다:
#     · 재고관리 배포가 **이미 끝났다면** compose 에 app-inventory 가 있는
#       것이 정상이다.
#     · **아직이라면** 그 블록이 섞여 들어온 것이다 — 🔴 **올리지 말고
#       먼저 알리세요.** 이 스크립트는 1-ㅁ 에서 ⚠️ 로 알려 준다(✗ 는 아니다).
#   🔵 포털 1.7 의 상수에는 dss-inventory 가 **이미 들어 있다.** 재고관리가
#      포털에 등록되기 전에는 그 줄이 **아무 일도 하지 않는다** — 포털은
#      그 사람이 볼 수 있는 타일만 훑기 때문이다(sources.ts 의 그 판정).
#
# ══ 🔴 DSM 터미널은 긴 명령을 잘라 먹는다 ══════════════════════════════
#
#   하루에 네 번 깨진 적이 있다. **NAS 에서 돌릴 것은 스크립트 파일로 올리고
#   md5 를 맞춘 뒤** 실행한다. 이 파일 자체가 그렇다:
#
#     (PowerShell)  scp -O nas\setup\26-deploy.sh dss-nas:/volume1/dss/setup/
#     (PowerShell)  Get-FileHash -Algorithm MD5 nas\setup\26-deploy.sh
#     (NAS)         md5sum /volume1/dss/setup/26-deploy.sh
#                   → 두 값이 **같아야** 실행한다. 다르면 다시 올린다.
#
#   그래서 이 스크립트는 사람이 칠 명령을 **한 줄 76자 안쪽**으로만 찍는다.
#
# ══ 🔴 야간 백업 시각을 지킨다 — **02:30** ═════════════════════════════
#
#   🔴 **자정을 넘겨 돌리면 백업 검사에 걸린다.** 17번이 01:00 에 돌렸다가
#      실제로 배포가 막혔다 — 그것이 사고를 막았다.
#      늦은 시각에 돌려야 한다면 **먼저 손으로 한 번 뜬다**(종료 코드 0):
#
#        bash /volume1/dss/jobs/backup-nightly.sh
#
#      🔴 **dss_auth 와 dss_board 두 줄이 찍혀야 한다.** 여섯이 다 떠야
#         1-ㅅ 이 통과한다(게시판이 선 뒤로 다섯이 아니라 여섯이다).
#
# ══ 🔴 22 · 24 · 25번에서 고쳐진 것 둘을 그대로 가져왔다 ═══════════════
#
#   ① 🔴 **큰따옴표 안에 백틱을 쓰지 않는다.** 명령 치환으로 읽혀 운영에서
#      syntax error 가 났다. bash -n 은 치환 **안쪽**을 안 봐서 **못 잡는다.**
#      코드를 인용할 때는 작은따옴표나 「」 를 쓴다.
#      🔵 이 파일에는 백틱이 **하나도 없다**(짠 뒤 세어 확인했다).
#   ② 🔴 **읽기 전용 자리에 리다이렉션으로 빈 파일을 만들지 않는다.**
#      ash 는 리다이렉션 실패를 **치명적으로** 보고 셸을 그 자리에서 끝낸다 —
#      뒤의 echo 가 안 돌아 판정이 **빈 채로** 나왔다(2026-10-12 실제 사고).
#      🔴 **touch 를 쓴다** — 외부 명령이라 실패해도 셸이 산다.
#      🔵 이 판에서 그 자리는 둘이다 — /keys(읽기 전용)와 /data/uploads(쓰기).
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#
#   11번부터 이어온 약속 그대로 — **인자 없이 돌리면 --check**.
#   실수로 그냥 돌려도 아무것도 바뀌지 않는다(🔵 로그 파일 **둘**만 남는다).
#   코드로는 아래 두 줄이 그 약속이다:
#     · MODE=check        (모드 절의 첫 줄)
#     · FORCE_LOAD=0      (같은 태그를 덮어쓰지 않는다)
#
#   🔴 정직하게 적어 둔다 — --check 도 이미지 **안을 보려고** 컨테이너를 잠깐
#      띄웠다 지우고(docker run --rm), 운영 DB 에 **select** 를 몇 번 보낸다.
#      「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#   🔴 **--check 가 DB 에 보내는 문장은 전부 select 다.** 믿으라고 하지 않고
#      **세어서 찍는다**(23번이 쓴 그 길) — 마지막에 「보낸 문장 N · select N ·
#      그 밖 0」이 나온다(sql_report).
#   🔵 --check 는 /keys 에도 /data/uploads 에도 **쓰기 시험을 하지 않는다.**
#      쓰기 시험은 --go 뒤 스모크에서만 한다.
#
# ── 모드 다섯 ───────────────────────────────────────────────────────────
#   (없음) · --check     읽기만 한다. 아무것도 안 바꾸고 안 멈춘다      ← 기본값
#   --preload            새 이미지 **둘**을 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --go                 🔴 포털과 게시판을 교체한다 (DB 는 안 바꾼다)
#   --rollback           되돌리기 안내
#
#   --force-load 는 --go 와 같이 써도 된다:  bash 26-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 26-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 26-deploy.sh --preload       (새 이미지 둘을 미리 실어 둔다)
#   3) bash 26-deploy.sh                 (다시 읽기만 — 이번엔 안까지 다 본다)
#   4) bash 26-deploy.sh --go            (포털 · 게시판 교체)
#
# ══ 🔴 「아직 안 온 것」을 ✗ 로 세지 않는다 (17 ~ 25번의 규칙) ═════════
#
#       **--check 가 ✗ 로 세는 것은 「있는데 어긋난 것」뿐이다.**
#       「아직 안 온 것 · 아직 안 실린 것」은 ⚠️ 로 안내만 한다.
#
# ══ 🔴 건드리지 않는 열 ════════════════════════════════════════════════
#
#     dss-as:2.5                dss-as-tools:1
#     dss-meters:1.3            dss-meters-tools:1
#     dss-improvements:0.3      dss-improvements-tools:2
#     dss-po:0.5                dss-leave:0.2
#     dss-leave-tools:2         dss-board-tools:1
#
#   🔴 **열이다**(24번은 아홉이었다 — 그 뒤 25번이 게시판 도구를 더했다).
#   전부 지금 운영에 실려 있다(도구 다섯은 실려만 있다 — profiles: [tools]).
#   compose 에서 이 태그가 흔들렸으면 **남의 변경이 섞인 것**이다 — 두 세션이
#   같은 저장소를 쓴다. 고치지 말고 **먼저 알린다.**
#
#   그리고 「안 멈췄다」를 말로 하지 않는다 — 교체 **전후로** 각 컨테이너의
#   시작 시각(.State.StartedAt)을 적어 두고 **그대로인지** 본다(5-ㅅ).
#   🔴 **이번에 세는 상자는 일곱이다** — dss-as · dss-meters ·
#      dss-improvements · dss-po · dss-leave · dss-pg-app · dss-pg-auth.
#
# ══ 🔴 포털 화면의 「v1.5」는 **또 안 바뀐다** — 실측이다 ══════════════
#
#   업데이트 소식 머리말의 v 표기는 RELEASES 의 가장 최근 글 번호다. 이번
#   커밋 셋은 **소식 글을 하나도 더하지 않았다**(바뀐 파일이 sources.ts 와
#   그 시험 둘뿐이다). package.json 의 version 도 그대로다.
#   🔴 그러므로 **1.7 은 배포본 번호**다 — 화면에서 v1.7 을 찾지 마세요.
#      「새 판인가」는 **게시판 알림이 포털 종에 뜨는가**로 본다.
#
# ══ 15 ~ 25번에서 그대로 이어받는 것 ═══════════════════════════════════
#
#   ① 같은 태그로 다시 구운 이미지는 조용히 안 실린다 → --force-load
#   ② 이미지는 태그가 아니라 **안을 본다**(1-ㅋ)
#   ③ 사람이 칠 명령은 **한 줄 76자 안쪽**(DSM 의 ash 가 긴 줄을 자른다)
#   ④ 'docker ps' 에 보이는 것과 앱이 **대답하는** 것은 다르다 → wait_http
#   ⑤ compose 는 바꾸기 **전에** 시험하고, 바꾼 것은 backups/ 에 남긴다
#   ⑥ 🔴 **auto 는 컨테이너 안에서 172.x 가 된다** — OIDC_ISSUER ·
#      OIDC_REDIRECT_URI 를 읽어 판정한다(1-ㅈ)
#   ⑦ 🔴 **겉이 아니라 결과를 봐라** — 통로가 200 이냐가 아니라 **무엇이
#      나오느냐**를 본다. 🔴 이 판의 핵심이 그것이다 — **포털 컨테이너 안에서
#      게시판의 새 통로를 실제로 불러 본다**(1-ㅍ · 5-ㄹ). 옛 판이면 404,
#      새 판이면 **401** 이 온다. 토큰 없이도 **판이 갈린다.**
#   ⑧ 🔴 **만든 것과 도는 것은 다르다** — 이미지 안에서 한 번(1-ㅋ),
#      **도는 컨테이너** 안에서 또 한 번(5-ㄷ) 본다
#   ⑨ 🔴 **DB 에 보내는 문장은 전부 select 다** — 파일에 적어 센다(sql_report)
#   ⑩ 🔴 **첨부는 호스트 폴더에 있다** — 바꾸기 전후로 **파일 수를 센다**(5-ㅁ)
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
TODAY=$(date +%F)
CF=$D/deploy/docker-compose.nas.yml
INC=$D/setup/incoming
INCOMING=$INC/docker-compose.nas.yml
ENV_NAS=$D/deploy/.env.nas
ENVD=$D/deploy/env
AUTH_ENV=$ENVD/auth.env
BOARD_ENV=$ENVD/board.env
IMAGES=$D/images
BKD=$D/backups

# ── 🔴 이번에 올라가는 것 **둘** ───────────────────────────────────────
TAG_AUTH=dss-auth:1.7
OLD_AUTH=dss-auth:1.6
TAG_BOARD=dss-board:0.2
OLD_BOARD=dss-board:0.1

# ── 🔴 **건드리지 않는 열** ────────────────────────────────────────────
KEEP_AS=dss-as:2.5
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_METERSTOOLS=dss-meters-tools:1
KEEP_IMP=dss-improvements:0.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_PO=dss-po:0.5
KEEP_LEAVE=dss-leave:0.2
KEEP_LEAVETOOLS=dss-leave-tools:2
KEEP_BOARDTOOLS=dss-board-tools:1

# ── tar 둘 ─────────────────────────────────────────────────────────────
TAR_AUTH=$IMAGES/dss-auth-1.7.tar
TAR_BOARD=$IMAGES/dss-board-0.2.tar
# ╔════════════════════════════════════════════════════════════════════╗
# ║ 🔴 **여기 여섯 칸은 비어 있다. 사람이 이미지를 구운 뒤 채운다.**      ║
# ║    Claude 는 이미지를 굽지 않는다 — 재 본 적 없는 값을 적을 수 없다. ║
# ║    채우는 차례는 이 파일 머리말 「값 여섯을 채워야 한다」 절.         ║
# ║    🔴 비어 있는 동안 --go 는 **시작조차 하지 않는다.**                ║
# ╚════════════════════════════════════════════════════════════════════╝
SZ_AUTH=
MD5_AUTH=
WANT_CFG_AUTH=
SZ_BOARD=
MD5_BOARD=
WANT_CFG_BOARD=
# ⚠️ manifest.json 은 Config 를 'blobs/sha256/4256829e…' 로 적는다 — 앞의
#    'blobs/' 를 떼고 'sha256:' 를 붙인 모양으로 적는다(17 ~ 25번과 같다).
#    보기:  WANT_CFG_AUTH=sha256:f229e9cc…

# ── 포트 (compose 의 ports: 에서 읽어 확인했다 — 짐작이 아니다) ────────
#   포털 13100 · A/S 13000 · 계측기 13300 · 게시판 13400 ·
#   개선요청 13500 · PO 13600 · 휴가 13700
AUTH_PORT=13100
AUTH_INNER=3100
BOARD_PORT=13400
BOARD_INNER=3400

# ── DB — 🔴 **이번에 볼 것은 둘이다** ──────────────────────────────────
# 🔴 두 DB 는 **다른 상자**에 있다. 포털은 dss-pg-auth, 게시판은 dss-pg-app.
#    인증 DB 는 등급이 달라 인스턴스를 나눠 둔 것이다(CLAUDE.md 의 그 결정).
# 🔵 이번 판은 DB 를 **바꾸지 않는다.** 마이그레이션도 덤프도 없다.
AUTH_DB=dss_auth
PG_AUTH=dss-pg-auth
BOARD_DB=dss_board
PG_APP=dss-pg-app

# ── 컨테이너 · 서비스 이름 ─────────────────────────────────────────────
AUTH_CNAME=dss-auth
BOARD_CNAME=dss-board
AUTH_SVC=app-auth
BOARD_SVC=app-board

# ── 🔴 포털에 붙은 볼륨은 **서명 키 하나뿐이다** ───────────────────────
KEYS_HOST=/volume1/dss/auth-keys
KEYS_MNT=/keys

# ── 🔴 게시판에 붙은 볼륨은 **첨부 하나뿐이다** ────────────────────────
# 🔴 빠지면 올린 사진이 컨테이너 안에 쌓이고 **다음 교체에서 통째로 사라진다.**
#    화면에는 첨부가 있는데 바이트만 없는 상태가 되어 한참 뒤에 드러난다.
BOARD_UPLOADS=$D/board-uploads
BOARD_MNT=/data/uploads

# ── 바깥 주소 ──────────────────────────────────────────────────────────
WANT_ISSUER=https://login.dss21.co.kr
BOARD_BASE=https://board.dss21.co.kr
CB_PATH=/api/auth/callback
CLIENT_ID=dss-board
# 🔴 포털 1.7 이 더한 두 줄 중 하나. 아직 운영에 없는 시스템이다.
INV_CLIENT_ID=dss-inventory
# 게시판이 포털에 내주는 통로 둘 (sources.ts 의 상수와 **글자가 같아야 한다**)
NOTI_PATH=/api/integration/notifications
NOTI_SET_PATH=/api/integration/notification-settings

# ══════════════════════════════════════════════════════════════════════
#  🔴 설정 파일 — **이름만 본다. 값은 한 글자도 찍지 않는다.**
#
#  🔴 「*_URL 같은 넓은 패턴이 DATABASE_URL 을 끌고 와 비밀번호가 찍힌 적이
#     있다(2026-09-14)」 — 이름만 보고, 값은 꼴로만 말한다.
#  🔴 이 PC(dss-deploy)의 nas/env/*.env 를 NAS 로 **올리지 않는다. 절대로.**
#     그 사본은 낡아서 NAS 에만 있는 줄들이 없다.
# ══════════════════════════════════════════════════════════════════════
# 🔴 없으면 포털이 **아예 못 뜬다**(src/lib/config/env.ts 의 required 가 던진다).
AUTH_REQUIRED_KEYS="OIDC_ISSUER AUTH_TX_SECRET AUTH_ACTIVE_KID KAKAO_CLIENT_ID KAKAO_CLIENT_SECRET"
AUTH_FORBIDDEN_KEYS="DATABASE_URL AUTH_KEYS_DIR PORT"
# 🔴 게시판 일곱 (dss-board/.env.example · src/lib/env.ts). 25번과 같다.
#    🔴 OIDC_CLIENT_SECRET 이 이 판에서 **새 일**을 한다 — 게시판이 포털에
#       남의 알림을 물으러 갈 때 Basic 자격이 그것이다(oidc.ts 의 그 함수).
BOARD_REQUIRED_KEYS="OIDC_ISSUER OIDC_CLIENT_ID OIDC_CLIENT_SECRET OIDC_REDIRECT_URI"
BOARD_REQUIRED_KEYS="$BOARD_REQUIRED_KEYS AUTH_STATE_SECRET SESSION_COOKIE_SECURE SESSION_HOURS"
BOARD_FORBIDDEN_KEYS="DATABASE_URL PORT STORAGE_ROOT TZ SEED_DEV_ENABLED"

# ══════════════════════════════════════════════════════════════════════
#  이미지 **안에** 이번 판이 들어 있는가 — 🔴 글자로 본다
#
#  🔴 포털 쪽은 **가르기가 아주 깨끗하다.** 아래 두 글자는 1.6 에 **하나도
#     없다**(실측: git grep 'dss-board' · 'dss-inventory' 를 c51ff52 의 src/
#     에서 돌렸더니 **빈 출력**이었다). 그래서 **보이면 1.7 이다.**
#     🔵 24번처럼 「틀린 글자」와 짝지어 가릴 필요가 없다.
#  🔴 게시판 쪽은 **통로의 용도 글자**로 본다. 0.1 에는 그 통로 자체가 없다.
#  🔴 대조 표시(CTRL)가 안 나오면 **판정하지 않는다** — 글자를 못 읽은 것과
#     옛 판인 것을 가를 수 없기 때문이다.
# ══════════════════════════════════════════════════════════════════════
# 포털 — 1.7 에서 처음 생기는 두 글자(sources.ts 의 상수 열쇠)
AUTH_M1='dss-board'
AUTH_M2='dss-inventory'
# 포털 — 1.6 에도 1.7 에도 있다. 안 나오면 **안을 못 읽은 것**이다.
AUTH_CTRL='/api/integration/notification-settings'

# 게시판 — 0.2 에서 처음 생기는 글자 셋
#   🔴 앞 둘은 **토큰의 용도** 값이다(portal-service-token.ts). 압축기가
#      이름은 지워도 **문자열 값은 남긴다.**
BOARD_M1='dss.notifications.read'
BOARD_M2='dss.notification-settings.read'
#   🔴 셋째는 게시판이 **포털에 물으러 갈 때** 남기는 로그 글자다(oidc.ts).
#      이것이 있으면 「남의 알림을 합치는 쪽」까지 들어온 것이다.
BOARD_M3='포털 알림 통로 거절'
# 게시판 — 0.1 에도 0.2 에도 있다(layout.tsx 의 title).
BOARD_CTRL='DSS 사내 게시판'

# ══════════════════════════════════════════════════════════════════════
#  🔴 글자 찾기 — 이미지/컨테이너 안의 .next 를 훑는다
#
#  🔴 글자는 **-e 로 넘긴다.** 본문에 끼워 넣으면 공백·대시·한글이 든 글자에서
#     깨진다(22번이 깨졌던 바로 그 모양이다).
#  🔴 node 로 재는 까닭: sh 로 하려면 대괄호와 따옴표가 든 패턴을 넘겨야 한다.
#     node 는 두 이미지에 반드시 있다(둘 다 CMD 가 node server.js 다).
# ══════════════════════════════════════════════════════════════════════
MARK_PROBE_JS='
const fs = require("fs");
const path = require("path");
const marks = [process.env.M1, process.env.M2, process.env.M3, process.env.C1];
const hits = [0, 0, 0, 0];
let seen = 0;
const stack = ["/app/.next"];
while (stack.length > 0) {
  const dir = stack.pop();
  let entries = [];
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch (err) { continue; }
  for (const entry of entries) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name !== "cache" && entry.name !== "dev") stack.push(p);
      continue;
    }
    if (!/[.](js|html|rsc|json|txt)$/.test(entry.name)) continue;
    let text = "";
    try { text = fs.readFileSync(p, "utf8"); } catch (err) { continue; }
    seen += 1;
    for (let i = 0; i < marks.length; i += 1) {
      const m = marks[i];
      if (typeof m === "string" && m.length > 0 && text.indexOf(m) >= 0) hits[i] = 1;
    }
  }
}
console.log("MARKS " + hits.join(" "));
console.log("SEEN " + seen);
'

# ══════════════════════════════════════════════════════════════════════
#  🔴 **앱이 쓰는 길로 불러 본다** — 이 판에서 가장 센 검사다
#
#  포털이 게시판에게 묻는 길은 **컨테이너에서 나갔다 DSM 프록시를 거쳐**
#  들어온다. 호스트에서 curl 로 재면 그 길을 안 지난다 — 「검사는 앱이 쓰는
#  길로」. 그래서 **컨테이너 안에서 node 의 fetch 로** 부른다.
#
#  🔴 토큰 없이 불러도 **판이 갈린다**:
#     · 0.1(옛 판) → **404** (그 통로가 아예 없다)
#     · 0.2(새 판) → **401** (통로는 있고 자격이 없다고 거절한다)
#  🔵 그래서 바꾸기 **전에 404**, 바꾼 **뒤에 401** 이 나오면 이 배포가 한
#     일이 숫자 하나로 증명된다.
# ══════════════════════════════════════════════════════════════════════
REACH_PROBE_JS='
const u = process.env.U;
const t = setTimeout(function () { console.log("REACHFAIL timeout"); process.exit(0); }, 12000);
fetch(u, { redirect: "manual" })
  .then(function (r) { clearTimeout(t); console.log("REACH " + r.status); })
  .catch(function (e) {
    clearTimeout(t);
    console.log("REACHFAIL " + (e && e.name ? e.name : "unknown"));
  });
'
# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 둘. 인자가 없으면 이대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 26-deploy.sh                  읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 26-deploy.sh --check          위와 같습니다
  bash 26-deploy.sh --preload        새 이미지 **둘**을 싣고 지문만 맞춥니다
  bash 26-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 26-deploy.sh --go             🔴 포털 · 게시판 교체 — 그것뿐입니다
  bash 26-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 26-deploy.sh --rollback       되돌리기 안내

  🔴 --go 가 멈추는 것은 **dss-auth 와 dss-board 둘**입니다.
     A/S · 계측기 · 개선요청 · PO · 휴가 · DB 둘은 그대로 돕니다.
  🔴 그러나 포털은 **로그인 문**입니다 — 멈춰 있는 동안은 아무도 **새로**
     로그인하지 못합니다(이미 들어가 있는 사람은 그대로 일합니다).
  🔵 --go 는 **DB 도 .env 도 볼륨도 안 바꿉니다** — 이번 판은 이미지 둘뿐입니다.
  🔵 **다시 로그인하지 않아도 됩니다** — 세션은 DB 에 있고 이 배포는 DB 를
     멈추지 않습니다(포털은 dss_auth, 게시판은 dss_board).
  🔴 그래도 **그날 백업이 없으면 시작하지 않습니다.** 야간 백업은 02:30 입니다.
     🔴 이번에 볼 것은 **dss_auth 와 dss_board 둘**입니다.
USAGE
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)      MODE=check ;;
    --preload)    MODE=preload ;;
    --force-load) FORCE_LOAD=1; [ "$MODE" = check ] && MODE=force-load ;;
    --go)         MODE=go ;;
    --rollback)   MODE=rollback ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "모르는 인자: $1"; usage; exit 2 ;;
  esac
  shift
done

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/26-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11 ~ 25-deploy.sh 의 것 그대로 ────────────────────────────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""; DOWN=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# 🔴 「아직 안 온 것」은 --check 에서 ✗ 가 아니다.
#    --preload · --go 는 그것이 **있어야** 도는 모드라 ✗ 로 센다.
missing_is_fatal() { [ "$MODE" != check ]; }
notyet() { # 1 할 말   — 아직 안 **온** 것(사람이 올려야 하는 파일)
  if missing_is_fatal; then bad "$1"; else echo "    ⚠️ $1"; fi
}
notloaded() { # 1 할 말 — 아직 안 **실린** 것. 🔴 어느 모드에서도 ✗ 가 아니다.
  echo "    ⚠️ $1"
}

# 🔴 값 **여섯**이 채워졌는가 — 안 채워졌으면 --go 가 시작하지 않는다.
pinned() {
  [ -n "$SZ_AUTH" ] && [ -n "$MD5_AUTH" ] && [ -n "$WANT_CFG_AUTH" ] &&
  [ -n "$SZ_BOARD" ] && [ -n "$MD5_BOARD" ] && [ -n "$WANT_CFG_BOARD" ]
}

# ── 사람이 칠 명령은 76자 안쪽으로만 찍는다 ────────────────────────────
CMDW=76
cmd() { # 1 사람이 그대로 칠 명령 한 줄
  printf '    %s\n' "$1"
  if [ "${#1}" -gt "$CMDW" ]; then
    printf '    ⚠️ 위 줄이 %s자다(%s자 넘음) — 붙여넣으면 잘릴 수 있다.\n' "${#1}" "$CMDW"
    printf '       아래 「스크립트 파일로 만들기」를 쓰세요.\n'
  fi
}
script_file_hint() { # 1 파일이름(확장자 없이)
  say "    ── 길면 붙여넣지 말고 파일로 만드세요 ──"
  cmd "cat > /volume1/dss/setup/$1.sh"
  say "      (여기에 위 줄들을 붙여넣고 Ctrl+D)"
  cmd "bash /volume1/dss/setup/$1.sh"
}

COMPOSE=("$DOCKER" compose -f "$CF" --env-file "$ENV_NAS" --profile tools)
compose_at() { # 1 compose파일  나머지: compose 에 넘길 인자
  local f="$1"; shift
  "$DOCKER" compose --project-directory "$D/deploy" -f "$f" --env-file "$ENV_NAS" --profile tools "$@"
}

running() { "$DOCKER" ps --format '{{.Names}}' | grep -qx "$1"; }
pg_auth_up() { running "$PG_AUTH"; }
pg_app_up()  { running "$PG_APP"; }

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미 — 🔴 **보낸 문장을 한 줄씩 적어 둔다** (23 ~ 25번의 길)
#
#  🔴 「--check 는 select 만 보낸다」를 말로 하지 않는다. 이 넷을 지나는
#     문장을 **파일에 적고**, 끝에서 세어 찍는다. select 로 시작하지 않는
#     것이 하나라도 있으면 **그 문장을 그대로** 찍는다(sql_report).
#  🔴 **파일에 적는 까닭** — 이 함수들은 거의 언제나 $( ) 안에서 불린다.
#     거기는 아래 껍데기(subshell)라 변수로 세면 **그 수가 밖으로 안 나온다.**
#  🔴 **상자가 둘이다** — 포털은 dss-pg-auth, 게시판은 dss-pg-app.
#  🔵 이 판에는 db:migrate 도 pg_dump 도 **어느 모드에도 없다**(0건).
# ══════════════════════════════════════════════════════════════════════
SQLLOG="$D/setup/logs/26-sql-$MODE-$STAMP.txt"
touch "$SQLLOG" 2>/dev/null || true
SQL_N=0
SQL_SELECT_N=0
sql_note() { printf '%s\n' "$1" >> "$SQLLOG" 2>/dev/null || true; }
qauth()  { # 포털 DB · 한 칸만 받는다
  sql_note "$1"
  "$DOCKER" exec "$PG_AUTH" sh -c "psql -U \"\$POSTGRES_USER\" -d $AUTH_DB -Atc \"$1\"" 2>/dev/null
}
qqauth() { # 포털 DB · 표 꼴로 받는다
  sql_note "$1"
  "$DOCKER" exec "$PG_AUTH" sh -c "psql -U \"\$POSTGRES_USER\" -d $AUTH_DB -c   \"$1\"" 2>/dev/null
}
qboard()  { # 게시판 DB · 한 칸만 받는다
  sql_note "$1"
  "$DOCKER" exec "$PG_APP" sh -c "psql -U \"\$POSTGRES_USER\" -d $BOARD_DB -Atc \"$1\"" 2>/dev/null
}
sql_report() {
  local n_other
  SQL_N=$(wc -l < "$SQLLOG" 2>/dev/null | tr -d ' ')
  SQL_N=${SQL_N:-0}
  SQL_SELECT_N=$(grep -c '^select' "$SQLLOG" 2>/dev/null | tr -d ' ')
  SQL_SELECT_N=${SQL_SELECT_N:-0}
  n_other=$((SQL_N - SQL_SELECT_N))
  say
  say "  ── 🔴 이 실행이 운영 DB 에 보낸 문장 ──"
  say "     모두 $SQL_N 개 · 그중 select $SQL_SELECT_N 개"
  if [ "$n_other" -gt 0 ] 2>/dev/null; then
    say "     🔴 select 로 시작하지 않는 문장이 ${n_other}개 있다:"
    grep -v '^select' "$SQLLOG" 2>/dev/null | sed 's/^/        /'
  else
    say "     ✓ select 가 아닌 문장: **0개**"
  fi
  say "     (그대로의 목록: $SQLLOG)"
  say "     🔵 이 판에는 db:migrate 도 pg_dump 도 **어느 모드에도 없다** —"
  say "        마이그레이션이 **양쪽 다 0건**이라서다."
}

# ── 설정 파일에서 값 하나를 꺼낸다 ─────────────────────────────────────
# 🔴 부르는 쪽은 이 값을 **절대 화면에 찍지 않는다.** 판정에만 쓴다.
# 🔴 같은 이름이 두 줄 있으면 **나중 것**을 읽는다(tail). docker compose 가
#    그렇게 읽기 때문이다 — 앞 줄을 읽고 판정하면 「내가 본 값」과 「앱이 받는
#    값」이 달라진다. 그것이 이 스크립트가 가장 피하려는 거짓 통과다.
env_val() { # 1 파일 2 키
  local v
  [ -r "$1" ] || { printf ''; return 1; }
  v=$(sed -n "s/^[[:space:]]*\(export[[:space:]][[:space:]]*\)\?$2=//p" "$1" 2>/dev/null | tail -1 | tr -d '\r')
  v=${v#\"}; v=${v%\"}
  v=${v#\'}; v=${v%\'}
  printf '%s' "$v"
}
env_count_of() { # 1 파일 2 키 → 그 이름으로 시작하는 줄 수
  [ -f "$1" ] || { echo 0; return 0; }
  grep -c "^$2=" "$1" 2>/dev/null | tr -d ' '
}
env_keys_present() { # 1 파일 2 라벨 3 "키 …" 4 없을때할말
  local f="$1" label="$2" keys="$3" why="$4" k n
  for k in $keys; do
    n=$(env_count_of "$f" "$k")
    if [ "${n:-0}" = 0 ]; then
      bad "$label · $k 가 **없다** — 🔴 $why"
    elif [ "${n:-0}" -gt 1 ] 2>/dev/null; then
      bad "🔴 $label · $k 가 **두 줄 이상** 있다 — 먼저 그것부터 고쳐야 한다"
      say "      보기:  grep -c '^$k=' $f"
    else
      ok "$label · $k 있다"
    fi
  done
}
env_keys_absent() { # 1 파일 2 라벨 3 "키 …"
  local f="$1" label="$2" keys="$3" k
  for k in $keys; do
    if [ "$(env_count_of "$f" "$k")" = 0 ]; then
      ok "$label 에 $k 가 없다 (맞다 — compose·이미지가 넘긴다)"
    else
      bad "$label 에 $k 가 **있다** — 지우세요(두 곳에 있으면 언젠가 갈린다)"
    fi
  done
}
env_file_mode() { # 1 파일 2 라벨
  local s
  if [ ! -f "$1" ]; then
    bad "$2 가 없다: $1"
    say "    → 없는 env_file 하나면 docker compose 명령이 **통째로** 안 먹는다."
    return 1
  fi
  s=$(stat -c '%a' "$1" 2>/dev/null)
  [ "$s" = 600 ] && ok "$2 있다 · 모드 600" \
    || bad "$2 의 모드가 ${s:-?} 다 (600 이어야 한다 — 남이 읽는다)"
  s=$(stat -c '%U:%G' "$1" 2>/dev/null)
  [ "$s" = "root:root" ] || bad "$2 의 주인이 ${s:-?} 다 (root:root 이어야 한다)"
  return 0
}

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
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
  cmd "bash $0 --force-load"
  say "       (교체까지 한 번에 하려면:)"
  cmd "bash $0 --go --force-load"
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

# ── compose 파일에서 서비스 한 덩어리만 잘라 낸다 ──────────────────────
# 🔴 파일 전체를 grep 하면 안 된다 — 주석 줄이 그대로 걸려서 꺼져 있는 서비스를
#    「가리킨다」고 세게 된다(11-deploy.sh 의 그 함정).
svc_block() { # 1 compose파일 2 서비스이름
  awk -v s="  $2:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$1" | sed '/^[[:space:]]*#/d'
}
svc_image() { # 1 compose파일 2 서비스이름
  svc_block "$1" "$2" | sed -n 's/^[[:space:]]*image:[[:space:]]*//p' | head -1
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 볼륨이 **제 모양으로 붙어 있는가** — 쓰지 않고 **읽어서** 본다
#
#  🔵 /proc/mounts 는 커널이 적어 둔 것이라 거짓말하지 않고, --check 가
#     「아무것도 안 바꾼다」는 약속도 그대로 지켜진다.
#  🔵 --go 의 스모크에서는 교체 뒤에 **touch 로 한 번 더** 확인한다.
#     🔴 리다이렉션이 아니라 **touch** 다 — 읽기 전용 자리에서 ash 가 죽는다.
# ══════════════════════════════════════════════════════════════════════
mount_opts() { # 1 컨테이너 2 컨테이너안경로 → 마운트 옵션 (못 찾으면 빈 문자열)
  "$DOCKER" exec -e M="$2" "$1" sh -c '
    while read -r dev mp fs opts rest; do
      if [ "$mp" = "$M" ]; then echo "MNTOPT $opts"; fi
    done < /proc/mounts' 2>/dev/null | sed -n 's/^MNTOPT //p' | head -1
}
ro_mount_check() { # 1 컨테이너 2 경로 3 사람이읽을이름
  local o
  o=$(mount_opts "$1" "$2")
  if [ -z "$o" ]; then
    bad "🔴 $3 · $2 가 $1 안에 **마운트돼 있지 않다** — 볼륨이 사라졌다"
    say "    → compose 의 $AUTH_SVC 쪽 volumes: 한 줄이 지워졌는지 보세요."
    return 1
  fi
  say "    · $3 마운트 옵션: $o"
  case ",$o," in
    *,ro,*) ok "🔴 $3 · **읽기 전용 그대로다**(ro)" ; return 0 ;;
  esac
  bad "🔴 $3 · 마운트가 **쓸 수 있는 상태**다 — :ro 가 안 먹었다"
  say "    🔴 앱은 서명만 하고 키를 고치지 않는다. 쓸 수 있는 자리가 열린 채로"
  say "       돌면 뚫렸을 때 **키를 바꿔치기당한다.**"
  return 1
}
rw_mount_check() { # 1 컨테이너 2 경로 3 사람이읽을이름
  local o
  o=$(mount_opts "$1" "$2")
  if [ -z "$o" ]; then
    bad "🔴 $3 · $2 가 $1 안에 **마운트돼 있지 않다**"
    say "    🔴 이러면 올린 사진이 컨테이너 안에 쌓이고 **다음 교체에서 사라진다.**"
    say "       화면에는 첨부가 있는데 바이트만 없는 상태가 된다."
    return 1
  fi
  say "    · $3 마운트 옵션: $o"
  case ",$o," in
    *,ro,*) bad "🔴 $3 · **읽기 전용**으로 붙었다 — 사진을 올리는 순간 깨진다"
            return 1 ;;
  esac
  ok "$3 · 쓸 수 있게 붙어 있다 (rw)"
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 /keys 를 **컨테이너 안에서 실제로 열어 본다**
#
#  🔴 주인(uid)과 모드만 보면 통과하는데 실제로는 EACCES 인 일이 있다
#     (Synology ACL). → 판정은 커널에게 맡긴다.
#  🔴 **무엇이 들어 있어야 하나** (dss-auth/src/lib/crypto/keys.ts 실측):
#     · <무엇>.public.json 이 **하나 이상** — 없으면 앱이 던지며 죽는다
#     · <AUTH_ACTIVE_KID>.private.json 하나 — 없으면 역시 죽는다
#     🔵 이름을 찍지 않는다. 개수만 센다.
#  🔴 쓰기 시험(touch)은 **--go 뒤 스모크에서만** 한다. --check 는 읽기만 한다.
# ══════════════════════════════════════════════════════════════════════
KEYS_PROBE_SH='id
if ls -1 /keys >/dev/null 2>&1; then r=READ_OK; else r=READ_FAIL; fi
npub=$(ls -1 /keys 2>/dev/null | grep -c "[.]public[.]json$")
npri=$(ls -1 /keys 2>/dev/null | grep -c "[.]private[.]json$")
echo "KEYS $r ${npub:-0} ${npri:-0}"'
keys_probe() { # 1 컨테이너
  local what="$1" out r npub npri
  if ! running "$what"; then
    bad "/keys · $what 가 안 돌고 있어 **열어 보지 못했다**"
    return 1
  fi
  out=$("$DOCKER" exec "$what" sh -c "$KEYS_PROBE_SH" 2>&1)
  printf '%s\n' "$out" | grep -E '^(uid=|KEYS )' | sed 's/^/      /'
  if ! printf '%s\n' "$out" | grep -q '^KEYS '; then
    bad "/keys 를 열어 보지 못했다 — 아래가 그대로의 출력이다"
    printf '%s\n' "$out" | sed 's/^/      /' | head -8
    return 1
  fi
  r=$(printf   '%s\n' "$out" | sed -n 's/^KEYS //p' | head -1 | awk '{print $1}')
  npub=$(printf '%s\n' "$out" | sed -n 's/^KEYS //p' | head -1 | awk '{print $2}')
  npri=$(printf '%s\n' "$out" | sed -n 's/^KEYS //p' | head -1 | awk '{print $3}')
  [ "$r" = READ_OK ] && ok "/keys 를 읽는다" \
    || { bad "🔴 /keys 를 **못 읽는다**(EACCES) — 포털이 뜨다가 죽는다"
         say "      먼저 눈으로 보세요:"
         cmd "ls -ld $KEYS_HOST"
         cmd "synoacltool -get $KEYS_HOST"; }
  if [ "${npub:-0}" -ge 1 ] 2>/dev/null; then
    ok "/keys 에 공개키(*.public.json)가 ${npub}개 있다"
  else
    bad "🔴 /keys 에 공개키가 **하나도 없다** — 앱이 뜨면서 던지고 죽는다"
  fi
  if [ "${npri:-0}" -ge 1 ] 2>/dev/null; then
    ok "/keys 에 개인키(*.private.json)가 ${npri}개 있다"
  else
    bad "🔴 /keys 에 개인키가 **하나도 없다** — 서명을 못 해 로그인이 통째로 깨진다"
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 주소 — **auto 는 컨테이너 안에서 172.x 가 된다**
#
#  🔴 2026-09-29 에 「통로가 있다(401 이 온다)」로 통과했는데 그 통로가 내준
#     링크가 http://172.20.0.7:3500/ 이었다. 문이 있는지가 아니라 **무엇이
#     나오는지**를 봐야 잡힌다.
#  🔴 이 판에서는 그 자리가 **하나 더 늘었다** — 게시판 0.2 는 자기 알림의
#     링크를 **OIDC_REDIRECT_URI 에서 뽑아** 절대 주소로 만든다(env.ts 의
#     ownBaseUrl). 그 값이 틀리면 **포털 종에 뜬 게시판 알림을 눌러도 아무
#     데도 안 간다.** 그래서 이번엔 redirect_uri 까지 본다.
#  🔴 값을 그대로 찍지 않는다 — 숫자를 N 으로 가려 꼴만 보여 준다.
# ══════════════════════════════════════════════════════════════════════
href_shape() { # 1 주소
  printf '%s' "$1" | cut -c1-48 | sed 's/[0-9]/N/g'
}
judge_issuer() { # 1 라벨 2 원본값
  local label="$1" raw="$2" base host
  case "$raw" in
    auto|auto:*|AUTO|"")
      bad "$label · OIDC_ISSUER 가 auto(또는 빈 값)다 — 운영에서는 도메인을 적는다"
      say "      auto 는 이 기계의 랜 주소를 집는다. **컨테이너 안에서는 172.x 다.**"
      return 1 ;;
  esac
  base=$(printf '%s' "$raw" | sed 's:/*$::')
  host=${base#*://}; host=${host%%/*}; host=${host%%:*}
  case "$host" in
    172.*|10.*|192.168.*)
      bad "$label · issuer 가 **밖에서 닿지 않는 사설 주소**다 — $(href_shape "$base") 꼴"
      return 1 ;;
    *[!0-9.]*) : ;;   # 글자가 섞여 있다 = 이름(도메인)이다
    *)
      bad "$label · issuer 가 이름이 아니라 **IP** 다 — $(href_shape "$base") 꼴"
      return 1 ;;
  esac
  if [ "$base" = "$WANT_ISSUER" ]; then
    if [ "$raw" = "$WANT_ISSUER" ]; then
      ok "$label · issuer 가 $WANT_ISSUER 다"
      return 0
    fi
    bad "$label · issuer 끝에 슬래시가 붙었다 — 포털은 **글자 단위로** 대조한다"
    return 1
  fi
  bad "$label · issuer 가 $WANT_ISSUER 가 아니다 — $(href_shape "$base") 꼴"
  return 1
}
issuer_check() { # 1 라벨 2 컨테이너 3 env파일
  local label="$1" cname="$2" envf="$3" raw="" src=""
  say "  $label — OIDC_ISSUER 가 무엇인지 본다 (🔴 값은 찍지 않는다)"
  if running "$cname"; then
    raw=$("$DOCKER" exec "$cname" printenv OIDC_ISSUER 2>/dev/null | tr -d '\r')
    [ -n "$raw" ] && src="지금 도는 $cname 안"
  fi
  if [ -z "$raw" ] && [ -f "$envf" ]; then
    raw=$(env_val "$envf" OIDC_ISSUER)
    [ -n "$raw" ] && src="$(basename "$envf")"
  fi
  if [ -z "$raw" ]; then
    bad "$label · OIDC_ISSUER 를 찾지 못했다 — 앱이 뜨면서 던지고 죽는다"
    return 1
  fi
  say "    · $src 에서 읽었다"
  judge_issuer "$label" "$raw"
}
# 🔴 게시판 전용. 이 값 하나가 **로그인**과 **알림 링크** 둘을 함께 정한다.
judge_redirect_uri() { # 1 라벨 2 원본값
  local label="$1" raw="$2" base host
  case "$raw" in
    auto|auto:*|AUTO|"")
      bad "$label · OIDC_REDIRECT_URI 가 auto(또는 빈 값)다 — 운영에는 도메인을 적는다"
      say "      🔴 0.2 부터는 이 값에서 **알림 링크의 앞머리**도 뽑는다."
      return 1 ;;
  esac
  case "$raw" in
    *"$CB_PATH") base=${raw%"$CB_PATH"} ;;
    *)
      bad "🔴 $label · OIDC_REDIRECT_URI 가 $CB_PATH 로 끝나지 않는다"
      say "      꼴: $(href_shape "$raw")"
      say "      🔴 0.2 는 이때 **던진다**(env.ts 의 ownBaseUrlFrom). 알림을"
      say "         만드는 쪽이 그것을 삼켜 **종이 조용히 빈다.**"
      return 1 ;;
  esac
  host=${base#*://}; host=${host%%/*}; host=${host%%:*}
  case "$host" in
    172.*|10.*|192.168.*)
      bad "$label · **밖에서 닿지 않는 사설 주소**다 — $(href_shape "$base") 꼴"
      return 1 ;;
  esac
  if [ "$raw" = "$BOARD_BASE$CB_PATH" ]; then
    ok "$label · OIDC_REDIRECT_URI 가 $BOARD_BASE$CB_PATH 다"
    say "    🔵 그래서 알림 링크의 앞머리는 $BOARD_BASE 가 된다."
    return 0
  fi
  bad "$label · OIDC_REDIRECT_URI 가 기대값과 다르다 — $(href_shape "$raw") 꼴"
  say "      기대: $BOARD_BASE$CB_PATH"
  return 1
}
redirect_check() { # 1 라벨 2 컨테이너 3 env파일
  local label="$1" cname="$2" envf="$3" raw="" src=""
  say "  $label — OIDC_REDIRECT_URI 를 본다 (🔴 값은 꼴로만 말한다)"
  if running "$cname"; then
    raw=$("$DOCKER" exec "$cname" printenv OIDC_REDIRECT_URI 2>/dev/null | tr -d '\r')
    [ -n "$raw" ] && src="지금 도는 $cname 안"
  fi
  if [ -z "$raw" ] && [ -f "$envf" ]; then
    raw=$(env_val "$envf" OIDC_REDIRECT_URI)
    [ -n "$raw" ] && src="$(basename "$envf")"
  fi
  if [ -z "$raw" ]; then
    bad "$label · OIDC_REDIRECT_URI 를 찾지 못했다 — 로그인도 알림 링크도 깨진다"
    return 1
  fi
  say "    · $src 에서 읽었다"
  judge_redirect_uri "$label" "$raw"
}
# ══════════════════════════════════════════════════════════════════════
#  🔴 **로그인 길이 사는가** — 통로가 아니라 **나오는 것**을 본다
#
#  넷을 본다. 앞의 둘은 사람이 지나는 길, 뒤의 둘은 **다른 여섯 사이트가**
#  지나는 길이다. 🔴 **실제 계정으로 로그인하지 않는다**(사람이 한다).
#
#    /signin                               로그인 화면이 뜨는가
#    /                                     들어오면 /signin 으로 보내는가
#    /.well-known/openid-configuration     issuer 가 사내 도메인인가
#    /.well-known/jwks.json                🔴 **공개키가 실려 있는가**
#
#  🔴 jwks 는 「200 이냐」로는 모자라다 — 키가 0개라도 200 이 나온다. 그러면
#     로그인은 되는데 **각 시스템이 전부 토큰을 거절한다.**
#  🔴 덤으로 **개인키가 새지 않았는지**도 본다 — 공개 JWK 에 "d" 가 있으면
#     서명 키가 밖으로 나간 것이다.
# ══════════════════════════════════════════════════════════════════════
login_path_check() { # 1 라벨 2 경로 3 기대코드꼴(2|23)
  local label="$1" p="$2" want="$3" code
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "http://127.0.0.1:$AUTH_PORT$p" 2>/dev/null)
  case "$want:$code" in
    2:2??)    ok "$label · $p → $code" ;;
    23:2??|23:3??) ok "$label · $p → $code" ;;
    *:404)    bad "🔴 $label · $p 가 **404** 다 — 길이 없다" ;;
    *:000|*:) bad "🔴 $label · $p 가 **대답하지 않는다** (${code:-없음})" ;;
    *)        bad "🔴 $label · $p → $code (기대와 다르다)" ;;
  esac
}
login_door_check() {
  local body n
  login_path_check "로그인 화면" /signin 2
  login_path_check "들머리"      /        23
  body=$(curl -s -m 10 "http://127.0.0.1:$AUTH_PORT/.well-known/openid-configuration" 2>/dev/null)
  if [ -z "$body" ]; then
    bad "🔴 /.well-known/openid-configuration 이 **빈 대답**이다 — 여섯 사이트가 길을 잃는다"
  elif printf '%s' "$body" | grep -q "$WANT_ISSUER"; then
    ok "🔴 discovery 가 $WANT_ISSUER 를 내준다 (여섯 사이트가 보는 그 값이다)"
  else
    bad "🔴 discovery 의 issuer 가 $WANT_ISSUER 가 아니다"
    say "      꼴: $(href_shape "$body")"
    say "      🔴 auth.env 의 OIDC_ISSUER 가 auto 거나 옛 주소다."
  fi
  body=$(curl -s -m 10 "http://127.0.0.1:$AUTH_PORT/.well-known/jwks.json" 2>/dev/null)
  if [ -z "$body" ]; then
    bad "🔴 /.well-known/jwks.json 이 **빈 대답**이다 — 아무도 토큰을 못 검증한다"
  else
    printf '%s' "$body" | grep -q '"kid"' \
      && ok "🔴 jwks 에 kid 가 실려 있다" \
      || bad "🔴 jwks 에 kid 가 **없다** — 로그인은 되는데 각 시스템이 전부 거절한다"
    printf '%s' "$body" | grep -q '"kty"' \
      && ok "jwks 에 kty 가 실려 있다 (키 꼴이 담겼다)" \
      || bad "🔴 jwks 가 키를 담고 있지 않다"
    n=$(printf '%s' "$body" | grep -o '"kid"' | wc -l | tr -d ' ')
    say "    · 공개키 ${n:-0}개가 실려 있다 (키 교체 중이면 둘 이상이 맞다)"
    if printf '%s' "$body" | grep -q '"d"'; then
      bad "🔴🔴 jwks 에 **개인키 필드(d)가 섞여 있다** — 서명 키가 밖으로 나갔다"
      say "      🔴 즉시 알리세요. 이 판을 올리지 마세요."
    else
      ok "jwks 에 개인키 필드(d)가 없다 (공개키만 나간다)"
    fi
  fi
  # 🔴 게시판이 **이 통로로** 남의 알림을 물으러 온다(POST · Basic).
  #    자격 없이 부르면 401 이어야 한다. 404 면 포털 쪽 통로가 사라진 것이다.
  n=$(curl -s -o /dev/null -w '%{http_code}' -m 10 -X POST \
        "http://127.0.0.1:$AUTH_PORT$NOTI_PATH" 2>/dev/null)
  case "$n" in
    401|400) ok "포털의 통합 알림 통로가 산다 ($NOTI_PATH → $n · 자격 없이 거절)" ;;
    404)     bad "🔴 포털의 $NOTI_PATH 가 **404** 다 — 게시판이 남의 알림을 못 묻는다" ;;
    *)       bad "🔴 포털의 $NOTI_PATH → ${n:-없음} (401 이나 400 이어야 한다)" ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════
#  이미지/컨테이너 **안에** 이번 판이 들어 있는가
#
#  🔴 「아직 안 실린 것」은 ✗ 가 아니다. 못 봤다고 말하고 넘어간다.
#  🔴 대조 표시(CTRL)가 안 나오면 **판정하지 않는다.**
# ══════════════════════════════════════════════════════════════════════
mark_check() { # 1 how(image|run) 2 태그또는컨테이너 3 라벨 4 M1 5 M2 6 M3 7 CTRL 8 옛판
  local how="$1" what="$2" label="$3" m1="$4" m2="$5" m3="$6" c1="$7" old="$8"
  local out marks h1 h2 h3 hc seen
  if [ "$how" = image ]; then
    if ! have_img "$what"; then
      notloaded "$what 가 아직 NAS 에 없어 **안을 못 봤다** — 먼저 실으세요"
      cmd "bash $0 --preload"
      return 0
    fi
    out=$("$DOCKER" run --rm \
          -e M1="$m1" -e M2="$m2" -e M3="$m3" -e C1="$c1" \
          --entrypoint node "$what" -e "$MARK_PROBE_JS" 2>&1)
  else
    if ! running "$what"; then
      bad "$label · $what 가 안 돌고 있어 **안을 못 봤다**"
      return 1
    fi
    out=$("$DOCKER" exec \
          -e M1="$m1" -e M2="$m2" -e M3="$m3" -e C1="$c1" \
          "$what" node -e "$MARK_PROBE_JS" 2>&1)
  fi
  marks=$(printf '%s\n' "$out" | sed -n 's/^MARKS //p' | head -1)
  seen=$(printf  '%s\n' "$out" | sed -n 's/^SEEN //p'  | head -1)
  if [ -z "$marks" ]; then
    say "    ⚠️ $label · node 가 대답하지 않았다. **판정하지 않는다** —"
    say "       아래가 그대로의 출력이다. 🔴 이때는 사람이 화면에서 봐야 한다."
    printf '%s\n' "$out" | sed 's/^/      /' | head -6
    return 0
  fi
  h1=$(printf '%s' "$marks" | awk '{print $1}')
  h2=$(printf '%s' "$marks" | awk '{print $2}')
  h3=$(printf '%s' "$marks" | awk '{print $3}')
  hc=$(printf '%s' "$marks" | awk '{print $4}')
  say "    · /app/.next 안 글자 파일 ${seen:-?}개를 읽었다"
  if [ "${hc:-0}" != 1 ]; then
    say "    ⚠️ $label · 대조 표시(「$c1」)가 안 나왔다. **판정하지 않는다** —"
    say "       안을 아예 못 읽은 것이다. 🔴 사람이 화면에서 봐야 한다."
    return 0
  fi
  ok "$label · 대조 표시를 찾았다 — 안을 실제로 읽었다는 뜻이다"
  [ "${h1:-0}" = 1 ] && ok "$label · 「$m1」이 들어 있다" \
    || bad "🔴 $label · 「$m1」이 **없다** — 이것은 $old 다"
  [ "${h2:-0}" = 1 ] && ok "$label · 「$m2」가 들어 있다" \
    || bad "🔴 $label · 「$m2」가 **없다** — 이것은 $old 다"
  if [ -n "$m3" ]; then
    [ "${h3:-0}" = 1 ] && ok "$label · 「$m3」가 들어 있다" \
      || bad "🔴 $label · 「$m3」가 **없다** — 판이 반만 들어갔다"
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 **앱이 쓰는 길로 불러 본다** — 컨테이너 안에서 node 의 fetch
#
#  🔴 호스트에서 curl 로 재면 DSM 프록시와 도커 망을 안 지난다. 포털이
#     게시판에게 묻는 길은 **정확히 이 길**이다 — 그래서 여기서 잰다.
# ══════════════════════════════════════════════════════════════════════
reach_code() { # 1 컨테이너 2 주소  → 숫자 또는 FAIL:<까닭>
  local out
  if ! running "$1"; then printf 'FAIL:not_running'; return 0; fi
  out=$("$DOCKER" exec -e U="$2" "$1" node -e "$REACH_PROBE_JS" 2>&1)
  if printf '%s\n' "$out" | grep -q '^REACH '; then
    printf '%s' "$(printf '%s\n' "$out" | sed -n 's/^REACH //p' | head -1)"
    return 0
  fi
  if printf '%s\n' "$out" | grep -q '^REACHFAIL '; then
    printf 'FAIL:%s' "$(printf '%s\n' "$out" | sed -n 's/^REACHFAIL //p' | head -1)"
    return 0
  fi
  printf 'FAIL:no_answer'
}
# 🔴 이 판의 핵심. 포털 컨테이너에서 게시판의 새 통로 둘을 불러 본다.
#    want=old 면 404 를(아직 안 바꿨다), want=new 면 401 을 기대한다.
board_route_from_portal() { # 1 want(old|new)
  local want="$1" code p label
  for p in "$NOTI_PATH" "$NOTI_SET_PATH"; do
    code=$(reach_code "$AUTH_CNAME" "$BOARD_BASE$p")
    label="포털 → 게시판 $p"
    case "$code" in
      FAIL:*)
        bad "🔴 $label · **부르지 못했다** (${code#FAIL:})"
        say "      🔴 포털이 게시판에 닿지 못하면 **통합 종에 게시판 줄이 안 뜬다.**"
        say "         dss-edge 망 · DSM 리버스 프록시 · 인증서를 보세요." ;;
      401)
        if [ "$want" = new ]; then
          ok "🔴 $label → **401** — 통로가 있고 자격을 제대로 따진다 (새 판이다)"
        else
          ok "$label → 401 (이미 새 판이 돌고 있다 — 다시 올리는 중인가)"
        fi ;;
      404)
        if [ "$want" = old ]; then
          ok "$label → 404 (아직 $OLD_BOARD 다 — **이 배포가 고칠 바로 그것**)"
        else
          bad "🔴 $label → **404** — 새 통로가 없다. 옛 판이 돌고 있다"
          say "      🔴 $TAG_BOARD 가 제대로 안 실렸거나 옛 커밋으로 구운 것이다."
        fi ;;
      *)
        bad "🔴 $label → ${code:-없음} (기대: 새 판 401 · 옛 판 404)" ;;
    esac
  done
}
# 🔴 반대 방향도 본다 — 게시판이 포털에 물으러 갈 수 있는가.
portal_from_board() {
  local code
  code=$(reach_code "$BOARD_CNAME" "$WANT_ISSUER/.well-known/openid-configuration")
  case "$code" in
    FAIL:*)
      bad "🔴 게시판 → 포털 · **닿지 못했다** (${code#FAIL:})"
      say "      🔴 이러면 게시판 종에 **남의 시스템 알림이 안 합쳐진다.**"
      say "         (로그인도 같은 길을 쓴다 — 로그인이 되는데 이것만 막히지는"
      say "          않는다. 그래서 이 ✗ 는 망 자체를 의심하라는 뜻이다.)" ;;
    200)
      ok "🔴 게시판 → 포털 discovery → 200 (남의 알림을 물으러 갈 길이 열려 있다)" ;;
    *)
      bad "🔴 게시판 → 포털 discovery → ${code:-없음} (200 이어야 한다)" ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════
#  운영 DB 를 읽는다 — 🔴 **읽기만 한다. 전부 select 다.**
#
#  🔵 이번 판은 DB 를 한 글자도 안 바꾼다. 그래도 읽는 까닭은 셋이다:
#    ① 🔴 **세션이 끊기는지**를 숫자로 말하려고(교체 전후로 센다).
#    ② 🔴 **포털이 게시판에게 물으러 가는 조건**이 DB 에 있다 — 상수에 줄을
#       더해도 그 사람의 **타일에 게시판이 없으면** 포털은 묻지 않는다
#       (sources.ts 의 판정 1번). 그래서 clients 를 본다.
#       「권한은 코드가 아니라 운영 DB 가 정한다」와 같은 자다.
#    ③ 🔵 게시판 표 일곱이 그대로인지(마이그레이션 0건을 숫자로 확인).
#  🔴 **주소는 찍지 않는다.** 있는가(true/false)만 본다.
# ══════════════════════════════════════════════════════════════════════
SESS_SQL="select count(*) from sso_sessions where revoked_at is null and expires_at > now()"
live_sessions() { qauth "$SESS_SQL"; }

db_check_auth() {
  local reg n_all n_live n_cli v
  if ! pg_auth_up; then
    say "  · $PG_AUTH 이 떠 있지 않다 — 포털 DB 를 못 봤다(✗ 는 아니다)"
    return 0
  fi
  reg=$(qauth "select to_regclass('public.sso_sessions')")
  if [ -z "$reg" ]; then
    say "  · $AUTH_DB 에 sso_sessions 표가 없다 — 🔴 첫 설치가 덜 된 DB 다"
    return 0
  fi
  ok "$AUTH_DB 에 sso_sessions 표가 있다"
  n_all=$(qauth "select count(*) from sso_sessions")
  n_live=$(live_sessions)
  say "  · sso_sessions 전체 줄: ${n_all:-?}"
  say "  · 🔴 **지금 살아 있는 세션**(안 끊겼고 안 만료): ${n_live:-?}"
  say "     🔵 이 숫자가 교체 뒤에도 **그대로면 아무도 로그아웃되지 않은 것**이다."
  reg=$(qauth "select to_regclass('public.clients')")
  if [ -z "$reg" ]; then
    say "  · clients 표가 없다 — 🔴 첫 설치가 덜 된 DB 다"
    return 0
  fi
  n_cli=$(qauth "select count(*) from clients where is_active = true")
  say "  · 켜져 있는 시스템(clients): ${n_cli:-?}"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 **이 배포가 실제로 무언가를 하려면** 게시판이 등록돼 있어야 ║"
  say "  ║    한다. 상수에 줄을 더해도 타일에 없으면 포털은 안 묻는다.    ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  v=$(qauth "select count(*) from clients where client_id = '$CLIENT_ID' and is_active = true")
  if [ "${v:-0}" = 1 ]; then
    ok "🔴 clients 에 $CLIENT_ID 가 **켜져 있다** — 포털이 물으러 간다"
  else
    bad "🔴 clients 에 켜진 $CLIENT_ID 가 없다 (${v:-?}) — 올려도 종에 아무것도 안 뜬다"
  fi
  v=$(qauth "select count(*) from clients where client_id = '$CLIENT_ID' and launcher_url is not null and launcher_url <> ''")
  if [ "${v:-0}" = 1 ]; then
    ok "🔴 $CLIENT_ID 의 타일 주소가 **적혀 있다** (🔴 주소 자체는 안 찍는다)"
    say "     🔵 포털은 이 주소의 **origin** 에 통로 경로를 붙여 묻는다."
  else
    bad "🔴 $CLIENT_ID 의 launcher_url 이 비어 있다 — 포털이 물을 주소를 못 만든다"
  fi
  v=$(qauth "select count(*) from clients where client_id = '$CLIENT_ID' and requires_grant = false")
  [ "${v:-0}" = 1 ] && say "  · $CLIENT_ID 는 전 직원 공개다(requires_grant=false)" \
    || say "  · $CLIENT_ID 는 권한을 받은 사람만 본다(requires_grant=true)"
  say
  say "  🔵 1.7 이 함께 더한 **재고 관리**는 아직 운영에 없다 — 있으면 그때부터"
  say "     묻기 시작한다. 지금 상태를 적어 둔다(✗ 가 아니다):"
  v=$(qauth "select count(*) from clients where client_id = '$INV_CLIENT_ID'")
  if [ "${v:-0}" = 0 ]; then
    say "    · clients 에 $INV_CLIENT_ID 가 **없다** — 상수의 그 줄은 아직 쉰다"
  else
    say "    · clients 에 $INV_CLIENT_ID 가 **있다**(${v}) — 재고관리 설치가 끝났다는 뜻이다"
    say "      🔴 그렇다면 그쪽 앱이 통로 둘을 내주고 있어야 한다. 아니면 종의"
    say "         그 줄만 조용히 빈다(포털은 못 받은 줄을 버린다)."
  fi
  say
  say "  켜져 있는 시스템 — 이름과 「주소가 적혀 있나」만 (🔴 주소는 안 찍는다):"
  qqauth "select client_id, (launcher_url is not null and launcher_url <> '') as has_tile from clients where is_active = true order by client_id" \
    | sed 's/^/      /'
  return 0
}

db_check_board() {
  local reg n_tab n_mig n_user
  if ! pg_app_up; then
    say "  · $PG_APP 이 떠 있지 않다 — 게시판 DB 를 못 봤다(✗ 는 아니다)"
    return 0
  fi
  reg=$(qboard "select to_regclass('public.web_posts')")
  if [ -z "$reg" ]; then
    bad "🔴 $BOARD_DB 에 web_posts 표가 없다 — 첫 설치가 덜 된 DB 다"
    return 0
  fi
  n_tab=$(qboard "select count(*) from information_schema.tables where table_schema = 'public'")
  if [ "${n_tab:-0}" = 7 ]; then
    ok "$BOARD_DB 의 표가 **일곱 그대로**다 (이 배포는 표를 안 건드린다)"
  else
    bad "🔴 $BOARD_DB 의 표가 ${n_tab:-?}개다 (일곱이어야 한다) — 누가 바꿨다"
  fi
  n_mig=$(qboard "select count(*) from drizzle.__drizzle_migrations")
  if [ "${n_mig:-0}" = 1 ]; then
    ok "🔴 마이그레이션이 **1건 그대로**다 — 이번 판은 0건을 더한다"
  else
    bad "🔴 마이그레이션이 ${n_mig:-?}건이다 (1 이어야 한다) — 누가 돌렸다"
  fi
  n_user=$(qboard "select count(*) from web_users")
  say "  · 게시판에 들어와 본 사람(web_users): ${n_user:-?}"
  say "    🔵 🔴 **포털 종에 게시판 알림이 뜨려면 그 사람이 게시판에 한 번은**"
  say "       **들어와 본 적이 있어야 한다** — 통로가 auth_sub 로 사람을 찾고,"
  say "       못 찾으면 **빈 목록**을 돌려준다(오류가 아니다, 그 route 의 규칙)."
  say "       그래서 처음에는 **대부분의 사람에게 아무것도 안 뜬다.** 정상이다."
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)
EXP_AUTH=""
EXP_BOARD=""
SVCS=""

see_tar() { # 1 태그 2 tar 3 tar지문 4 기대바이트 5 기대md5 6 기대지문 7 올릴파일이름
  local tag="$1" f="$2" got="$3" wsz="$4" wmd5="$5" wcfg="$6" up="$7" n m
  if [ ! -s "$f" ]; then
    notyet "$tag 의 tar 가 아직 NAS 에 없다: $f"
    say "    → 개발 PC(PowerShell)에서 올리세요. 🔴 scp 에 -O 를 붙입니다:"
    say "      scp -O $up dss-nas:/volume1/dss/images/"
    return 1
  fi
  n=$(stat -c '%s' "$f" 2>/dev/null)
  m=$(md5_of "$f")
  say "    · 지금 이 tar: 바이트 ${n:-?} · md5 ${m:-?}"
  if [ -z "$wsz" ] || [ -z "$wmd5" ] || [ -z "$wcfg" ]; then
    say "    ⚠️ 🔴 **$tag 의 기대값이 비어 있다.** 개발 PC 에서 구운 뒤 이 스크립트"
    say "       머리말의 차례대로 재어 채우세요. 채우기 전에는 --go 가 시작하지 않습니다."
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
  local tag s f db n_bk nlog h code FREE_KB FREE_H n

  # ── 1-ㄱ. 올릴 파일 — 이미지 tar **둘** · compose 하나 ───────────────
  step "1-ㄱ. 올린 파일 (이미지 tar **둘** · compose 하나. 그것이 전부다)"
  say "  🔵 24번은 **둘**이었다(tar 하나 · compose). 🔴 이번엔 **셋**이다."
  say "     🔴 **마이그레이션 묶음도 도구 이미지도 없다** — 양쪽 다 0건이고,"
  say "        게시판 도구는 바뀐 것이 없어 다시 굽지 않는다(머리말의 그 절)."
  EXP_AUTH=$(tar_config_id "$TAR_AUTH" 2>/dev/null) || EXP_AUTH=""
  see_tar "$TAG_AUTH" "$TAR_AUTH" "$EXP_AUTH" "$SZ_AUTH" "$MD5_AUTH" "$WANT_CFG_AUTH" dss-auth-1.7.tar
  EXP_BOARD=$(tar_config_id "$TAR_BOARD" 2>/dev/null) || EXP_BOARD=""
  see_tar "$TAG_BOARD" "$TAR_BOARD" "$EXP_BOARD" "$SZ_BOARD" "$MD5_BOARD" "$WANT_CFG_BOARD" dss-board-0.2.tar
  say "  🔵 포털은 **파일 둘**만 달라졌다(sources.ts · 그 시험) — tar 크기가"
  say "     1.6 과 거의 같은 것이 정상이다."
  say "  🔵 게시판은 코드가 늘었지만 사진·글꼴이 아니다 — 0.1 의 96,508,416"
  say "     바이트와 크게 다르면 그쪽을 먼저 의심한다."

  # ── 1-ㄴ. NAS 에 실린 이미지 ─────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (올라가는 **둘** · 🔴 건드리지 않는 **열**)"
  if have_img "$TAG_AUTH"; then
    [ -n "$EXP_AUTH" ] && { verify_img "$TAG_AUTH" "$EXP_AUTH" || force_load_hint "$TAG_AUTH"; }
  else
    notloaded "$TAG_AUTH 는 아직 NAS 에 실리지 않았다 — --preload 나 --go 가 싣는다"
  fi
  if have_img "$TAG_BOARD"; then
    [ -n "$EXP_BOARD" ] && { verify_img "$TAG_BOARD" "$EXP_BOARD" || force_load_hint "$TAG_BOARD"; }
  else
    notloaded "$TAG_BOARD 는 아직 NAS 에 실리지 않았다 — --preload 나 --go 가 싣는다"
  fi
  say "  🔴 지문이 어긋나면 **혼자 고쳐지지 않는다.** 태그가 같으면 docker load 를"
  say "     그냥 부르는 것으로는 안 바뀐다 — 위에 찍힌 --force-load 를 쓰세요."
  say "  🔴 건드리지 않는 열 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for tag in "$KEEP_AS" "$KEEP_ASTOOLS" "$KEEP_METERS" "$KEEP_METERSTOOLS" \
             "$KEEP_IMP" "$KEEP_IMPTOOLS" "$KEEP_PO" "$KEEP_LEAVE" \
             "$KEEP_LEAVETOOLS" "$KEEP_BOARDTOOLS"; do
    have_img "$tag" && ok "$tag 실려 있다 ($(img_id "$tag" | cut -c1-19)…)" \
      || bad "$tag 가 NAS 에 없다 — 🔴 앞 배포가 되돌아갔거나 누가 지웠다"
  done
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 **되돌아갈 옛 이미지 둘**이 있는가 — 포털은 특히 중요하다   ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  if have_img "$OLD_AUTH"; then
    ok "🔴 $OLD_AUTH 가 아직 NAS 에 있다 — **되돌릴 길이 열려 있다**"
  else
    bad "🔴 $OLD_AUTH 가 NAS 에 **없다** — 되돌릴 이미지가 없다"
    say "     🔴 포털은 로그인 문이다. 되돌릴 길이 없는 채로 올리지 마세요."
    cmd "$DOCKER ps --format '{{.Names}} {{.Image}}' | grep dss-auth"
  fi
  if have_img "$OLD_BOARD"; then
    ok "$OLD_BOARD 가 아직 NAS 에 있다 — 되돌릴 길이 열려 있다"
  else
    bad "🔴 $OLD_BOARD 가 NAS 에 **없다** — 게시판을 되돌릴 이미지가 없다"
  fi

  # ── 1-ㄷ. 🔴 운영 DB 둘 — 읽기만 한다 ────────────────────────────────
  step "1-ㄷ. 운영 DB **둘**을 읽는다 — 세션 · 등록 · 표 (🔴 전부 select)"
  say "  🔴 상자가 다르다 — 포털은 $PG_AUTH 안의 $AUTH_DB,"
  say "     게시판은 $PG_APP 안의 $BOARD_DB 다."
  db_check_auth
  say
  say "  게시판 DB:"
  db_check_board

  # ── 1-ㄹ. 🔴 설정 둘 — **있는가와 꼴만 본다** ────────────────────────
  step "1-ㄹ. auth.env · board.env — 🔴 **값은 한 글자도 안 찍는다**"
  say "  🔴 이번 판은 **.env 에 더할 줄이 하나도 없다**(머리말의 확인 ②)."
  say "     그래서 아래는 전부 「있는가 · 꼴이 맞는가」뿐이다."
  if env_file_mode "$AUTH_ENV" "auth.env"; then
    say "  🔴 없으면 **포털이 아예 못 뜬다**(env.ts 의 required 가 던진다):"
    env_keys_present "$AUTH_ENV" "auth.env" "$AUTH_REQUIRED_KEYS" "포털이 시작하자마자 죽는다"
    say "  🔴 compose 가 넘기는 것들 — auth.env 에 또 있으면 안 된다:"
    env_keys_absent "$AUTH_ENV" "auth.env" "$AUTH_FORBIDDEN_KEYS"
  fi
  if env_file_mode "$BOARD_ENV" "board.env"; then
    say "  🔴 없으면 **게시판이 아예 못 뜬다**(그 저장소 env.ts 의 getter 가 던진다):"
    env_keys_present "$BOARD_ENV" "board.env" "$BOARD_REQUIRED_KEYS" "게시판이 시작하자마자 죽는다"
    say "  🔴 compose·이미지가 넘기는 것들 — board.env 에 또 있으면 안 된다:"
    env_keys_absent "$BOARD_ENV" "board.env" "$BOARD_FORBIDDEN_KEYS"
    say "  🔴 OIDC_CLIENT_SECRET 이 이 판에서 **새 일**을 한다 — 게시판이 포털에"
    say "     남의 알림을 물으러 갈 때의 자격(Basic)이다. 없으면 **게시판 종에**"
    say "     **다른 시스템 알림이 안 합쳐진다**(로그인은 그대로 된다)."
  fi
  for f in as.env po.env meters.env improvements.env leave.env; do
    [ -f "$ENVD/$f" ] || bad "$f 가 없다: $ENVD/$f (compose 가 통째로 실패한다)"
  done

  # ── 1-ㅁ. compose ───────────────────────────────────────────────────
  step "1-ㅁ. compose ($CF_EFF)"
  say "  🔴 이번 판에서 compose 가 바뀌는 자리는 **둘뿐**이다:"
  say "     $AUTH_SVC 의 image ($OLD_AUTH → $TAG_AUTH)"
  say "     $BOARD_SVC 의 image ($OLD_BOARD → $TAG_BOARD)"
  say "     다른 것이 흔들렸으면 남의 것이 섞인 것이다 — 고치지 말고 알리세요."
  if compose_at "$CF_EFF" config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_at "$CF_EFF" config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  SVCS=$(compose_at "$CF_EFF" config --services 2>/dev/null)
  for s in app-auth app-as tools-as app-meters tools-meters \
           app-improvements tools-improvements app-po app-leave tools-leave \
           app-board tools-board; do
    echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
      || bad "서비스 목록에 $s 가 없다 — 주석으로 꺼져 있다"
  done
  if echo "$SVCS" | grep -qx tools-auth; then
    bad "🔴 tools-auth 서비스가 **생겼다** — 포털에는 도구가 없었다. 고치지 말고 알리세요"
  else
    ok "🔴 tools-auth 가 없다 (맞다 — 포털에는 도구 이미지가 아예 없다)"
  fi
  # 🔴 재고관리 — 같은 날 다른 에이전트가 쓰고 있다. ✗ 가 아니라 ⚠️ 다.
  if echo "$SVCS" | grep -qx app-inventory; then
    say "  ⚠️ 🔴 compose 에 **app-inventory 가 있다.**"
    say "     · 재고관리 첫 설치가 **이미 끝났다면** 정상이다."
    say "     · **아직이라면 남의 변경이 섞인 것**이다 — 🔴 올리지 말고 알리세요."
    say "       (이 스크립트는 그 서비스를 **부르지도 멈추지도 않는다.**)"
  else
    say "  🔵 compose 에 app-inventory 가 없다 — 재고관리는 아직 서지 않았다."
  fi
  see_tag() { # 1 서비스 2 태그 3 사람이 읽을 이름
    svc_block "$CF_EFF" "$1" | grep -q "image: $2$" \
      && ok "$1 가 $2 를 가리킨다 ($3)" \
      || bad "$1 의 태그가 $2 가 아니다 ($3) — 지금 값: $(svc_image "$CF_EFF" "$1")"
  }
  say "  올라가는 둘:"
  see_tag "$AUTH_SVC"  "$TAG_AUTH"  "포털"
  see_tag "$BOARD_SVC" "$TAG_BOARD" "게시판"
  if [ "$(svc_image "$CF_EFF" "$AUTH_SVC")" = "$OLD_AUTH" ] ||
     [ "$(svc_image "$CF_EFF" "$BOARD_SVC")" = "$OLD_BOARD" ]; then
    say "    🔴 compose 가 아직 **옛 태그**를 가리킵니다. 개발 PC 에서 고친 파일을"
    say "       아래에 올리면 --go 가 시험하고 제자리로 옮깁니다:"
    say "         $INCOMING"
  fi
  say "  🔴 건드리지 않는 열 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-as              "$KEEP_AS"          "A/S · 그대로"
  see_tag tools-as            "$KEEP_ASTOOLS"     "A/S 도구 · 그대로"
  see_tag app-meters          "$KEEP_METERS"      "계측기 · 그대로"
  see_tag tools-meters        "$KEEP_METERSTOOLS" "계측기 도구 · 그대로"
  see_tag app-improvements    "$KEEP_IMP"         "개선요청 · 그대로"
  see_tag tools-improvements  "$KEEP_IMPTOOLS"    "개선요청 도구 · 그대로"
  see_tag app-po              "$KEEP_PO"          "PO/내자 · 그대로"
  see_tag app-leave           "$KEEP_LEAVE"       "휴가 · 그대로"
  see_tag tools-leave         "$KEEP_LEAVETOOLS"  "휴가 도구 · 그대로"
  see_tag tools-board         "$KEEP_BOARDTOOLS"  "게시판 도구 · 🔴 **이번에 안 바꾼다**"
  # 🔴 포털에 붙은 볼륨은 서명 키 하나뿐이다. 사라지면 안 되고 늘어도 안 된다.
  say "  🔴 포털에 붙은 볼륨 — **하나뿐이어야 한다**(서명 키):"
  svc_block "$CF_EFF" "$AUTH_SVC" | grep -q "$KEYS_HOST:$KEYS_MNT:ro" \
    && ok "$AUTH_SVC 가 $KEYS_HOST 를 $KEYS_MNT 에 **읽기 전용**으로 붙인다" \
    || bad "🔴 $AUTH_SVC 의 서명 키 볼륨이 어긋났다 — 포털이 뜨다가 죽거나 키가 바뀐다"
  for s in /quote-archive /contact-folder-archive /repair-docs-archive \
           /purchase-order-archive /customer-portal-archive; do
    svc_block "$CF_EFF" "$AUTH_SVC" | grep -q "$s" \
      && bad "🔴 $AUTH_SVC 에 $s 가 **생겼다** — 포털에는 없던 것이다. 고치지 말고 알리세요" \
      || ok "$AUTH_SVC 에 $s 가 없다 (맞다)"
  done
  svc_block "$CF_EFF" "$AUTH_SVC" | grep -q "$AUTH_PORT:$AUTH_INNER" \
    && ok "$AUTH_SVC 가 127.0.0.1:$AUTH_PORT 으로 열린다" \
    || bad "$AUTH_SVC 의 포트가 $AUTH_PORT:$AUTH_INNER 이 아니다"
  svc_block "$CF_EFF" "$AUTH_SVC" | grep -q 'db-auth' \
    && ok "$AUTH_SVC 가 db-auth 를 본다 (DATABASE_URL · depends_on)" \
    || bad "🔴 $AUTH_SVC 가 db-auth 를 안 본다 — 세션 표를 못 찾는다"
  # 🔴 게시판에 붙은 볼륨은 첨부 하나뿐이다.
  say "  🔴 게시판에 붙은 볼륨 — **첨부 하나**(빠지면 사진이 다음 교체에서 사라진다):"
  svc_block "$CF_EFF" "$BOARD_SVC" | grep -q "$BOARD_UPLOADS:$BOARD_MNT" \
    && ok "$BOARD_SVC 가 $BOARD_UPLOADS 를 $BOARD_MNT 에 붙인다" \
    || bad "🔴 $BOARD_SVC 의 첨부 볼륨이 어긋났다 — **올린 사진이 사라진다**"
  svc_block "$CF_EFF" "$BOARD_SVC" | grep -q "$BOARD_PORT:$BOARD_INNER" \
    && ok "$BOARD_SVC 가 127.0.0.1:$BOARD_PORT 으로 열린다" \
    || bad "$BOARD_SVC 의 포트가 $BOARD_PORT:$BOARD_INNER 이 아니다"
  svc_block "$CF_EFF" "$BOARD_SVC" | grep -q 'dss-edge' \
    && ok "🔴 $BOARD_SVC 가 dss-edge 망에 있다 — 포털에 물으러 나갈 수 있다" \
    || bad "🔴 $BOARD_SVC 에 dss-edge 가 없다 — 화면은 뜨는데 **로그인도 알림도** 안 된다"
  svc_block "$CF_EFF" "$AUTH_SVC" | grep -q 'dss-edge' \
    && ok "🔴 $AUTH_SVC 가 dss-edge 망에 있다 — 게시판에 물으러 나갈 수 있다" \
    || bad "🔴 $AUTH_SVC 에 dss-edge 가 없다 — 통합 종이 남의 알림을 못 모은다"
  # 🔴 사내 전용 원칙 — DB 에 ports: 를 더하지 않는다.
  svc_block "$CF_EFF" db-app | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-app 에 ports: 가 생겼다 — 사내 전용 원칙을 깬다. 고치지 말고 알리세요" \
    || ok "db-app 에 ports: 가 없다 (DB 는 호스트 포트를 하나도 안 연다)"
  svc_block "$CF_EFF" db-auth | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-auth 에 ports: 가 생겼다 — 고치지 말고 알리세요" \
    || ok "db-auth 에 ports: 가 없다"

  # ── 1-ㅂ. 🔴 볼륨 둘을 컨테이너 안에서 실제로 열어 본다 ──────────────
  step "1-ㅂ. 🔴 서명 키(/keys) · 첨부($BOARD_MNT) — 컨테이너 안에서 연다"
  say "  🔵 --check 는 **쓰기 시험을 하지 않는다.** 읽기만 해 본다."
  if [ -d "$KEYS_HOST" ]; then
    ok "호스트에 $KEYS_HOST 가 있다"
  else
    bad "🔴 호스트에 $KEYS_HOST 가 **없다** — 포털이 뜨다가 죽는다"
  fi
  if running "$AUTH_CNAME"; then
    say "  지금 도는 $AUTH_CNAME 안에서 본 것:"
    keys_probe "$AUTH_CNAME"
    ro_mount_check "$AUTH_CNAME" "$KEYS_MNT" "서명 키"
  else
    bad "$AUTH_CNAME 가 안 돌고 있어 /keys 를 못 열어 봤다"
  fi
  if [ -d "$BOARD_UPLOADS" ]; then
    n=$(find "$BOARD_UPLOADS" -type f 2>/dev/null | wc -l | tr -d ' ')
    ok "호스트에 $BOARD_UPLOADS 가 있다 · 지금 파일 ${n:-?}개"
    say "    🔴 이 숫자를 교체 **뒤에 다시 센다**(5-ㅁ). 줄면 큰일이다."
  else
    bad "🔴 호스트에 $BOARD_UPLOADS 가 **없다** — 첨부가 갈 곳이 없다"
  fi
  if running "$BOARD_CNAME"; then
    say "  지금 도는 $BOARD_CNAME 안에서 본 것:"
    rw_mount_check "$BOARD_CNAME" "$BOARD_MNT" "첨부"
  else
    bad "$BOARD_CNAME 가 안 돌고 있어 $BOARD_MNT 를 못 열어 봤다"
  fi

  # ── 1-ㅅ. 🔴 야간 백업 **여섯** · 야간 완전삭제 (읽기만 한다) ────────
  step "1-ㅅ. 야간 백업 **여섯** · 야간 완전삭제 (읽기만 한다)"
  say "  🔵 이번 판은 **DB 를 바꾸지 않는다**(마이그레이션 양쪽 0건)."
  say "     🔴 그래도 --go 는 오늘 뜬 **$AUTH_DB 와 $BOARD_DB** 백업이 없으면"
  say "        **시작조차 않는다**(3-ㄱ). 24번은 하나였고 이번엔 **둘**이다."
  say "  🔵 야간 백업은 **02:30** 이다 — 자정 넘어 배포하면 여기 걸린다."
  say "  최근 백업 여덟:"
  ls -lt "$BKD/db/" 2>/dev/null | head -8 | sed 's/^/      /'
  n_bk=0
  for db in dss_auth dss_meters dss_as dss_improvements dss_leave dss_board; do
    f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
      n_bk=$((n_bk + 1))
    else
      bad "오늘($TODAY) 뜬 $db 백업이 없다"
    fi
  done
  if [ "$n_bk" = 6 ]; then
    ok "🔴 오늘 백업이 **여섯**이다 — 야간 백업이 실제로 돌았다"
  else
    bad "🔴 오늘 백업이 ${n_bk}개뿐이다 (여섯이어야 한다)"
    say "    → 손으로 한 번 (종료 코드 0 이어야 한다):"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    say "    🔴 그중 **$AUTH_DB 나 $BOARD_DB 가 없으면 --go 는 시작조차 않는다.**"
  fi
  say
  say "  야간 완전삭제 — DSM 작업 「DSS Purge」의 로그:"
  nlog=$(ls -1t "$D/setup/logs"/purge-*.log 2>/dev/null | wc -l | tr -d ' ')
  if [ "${nlog:-0}" -gt 0 ]; then
    ok "완전삭제 로그가 ${nlog}개 있다 — 스케줄러에 등록돼 돌고 있다"
    ls -lt "$D/setup/logs"/purge-*.log 2>/dev/null | head -3 | sed 's/^/      /'
  else
    bad "🔴 완전삭제 로그가 **하나도 없다** — 스케줄러에 등록이 안 된 것이다"
    say "    → 🔴 이 스크립트는 등록하지 않는다. 사람이 DSM 화면에서 합니다."
  fi

  # ── 1-ㅇ. 디스크 · DB · 지금 도는 것 ────────────────────────────────
  step "1-ㅇ. 디스크 · DB · 지금 도는 것"
  if running "$PG_APP" && pg_auth_up; then
    ok "DB 둘 다 떠 있다 (이 배포에서 DB 컨테이너는 멈추지 않는다)"
  else
    bad "DB 가 떠 있지 않다"
  fi
  for s in dss-auth dss-as dss-meters dss-improvements dss-po dss-leave dss-board; do
    running "$s" && ok "$s 가 돌고 있다" || bad "$s 가 안 돌고 있다"
  done
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  # tar 둘 + 실은 이미지 둘. 22번이 둘이라 3GB 를 봤다 — 같은 잣대다.
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (tar 둘 + 실은 이미지 둘이 들어가야 한다)"
  fi

  # ── 1-ㅈ. 🔴 주소 — issuer 둘 · redirect_uri 하나 ────────────────────
  step "1-ㅈ. 🔴 주소 — auto 면 컨테이너 안에서 172.x 가 된다"
  say "  🔴 포털에서 틀어지면 **일곱 사이트 전원이 못 들어온다.**"
  issuer_check "포털"   "$AUTH_CNAME"  "$AUTH_ENV"
  issuer_check "게시판" "$BOARD_CNAME" "$BOARD_ENV"
  say "  🔴 게시판은 이번 판에서 이 값 하나가 **일을 하나 더 한다**:"
  redirect_check "게시판" "$BOARD_CNAME" "$BOARD_ENV"

  # ── 1-ㅋ. 새 이미지 **안에** 이번 판이 들어 있는가 ───────────────────
  step "1-ㅋ. 새 이미지 **둘**의 안을 본다 — 🔴 글자로 본다"
  say "  🔴 9/21~9/29 에 A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다."
  say "  🔵 포털 쪽은 가르기가 깨끗하다 — 아래 두 글자는 1.6 에 **하나도 없다**"
  say "     (실측). 보이면 1.7 이다."
  if have_img "$TAG_AUTH"; then
    say "  $TAG_AUTH 구운 때: $("$DOCKER" images "$TAG_AUTH" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_AUTH" --format '{{.Size}}' 2>/dev/null)"
    mark_check image "$TAG_AUTH" "포털" "$AUTH_M1" "$AUTH_M2" "" "$AUTH_CTRL" "$OLD_AUTH"
  else
    notloaded "$TAG_AUTH 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
  fi
  if have_img "$TAG_BOARD"; then
    say "  $TAG_BOARD 구운 때: $("$DOCKER" images "$TAG_BOARD" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_BOARD" --format '{{.Size}}' 2>/dev/null)"
    mark_check image "$TAG_BOARD" "게시판" "$BOARD_M1" "$BOARD_M2" "$BOARD_M3" "$BOARD_CTRL" "$OLD_BOARD"
  else
    notloaded "$TAG_BOARD 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
  fi

  # ── 1-ㅌ. 바깥 주소 일곱 · 🔴 로그인 길 ──────────────────────────────
  step "1-ㅌ. 바깥 주소 **일곱** · 🔴 로그인 길 (지금 상태를 적어 둔다)"
  say "  🔴 **포털이 죽으면 나머지 여섯도 못 들어간다.** 그래서 일곱을 다 본다."
  for h in login as meters improvements po leave board; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$h.dss21.co.kr → $code" ;;
      *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
    esac
  done
  say "  🔴 로그인 길 — **실제 계정으로 로그인하지는 않는다**(사람이 한다):"
  login_door_check

  # ── 1-ㅍ. 🔴 **이 배포가 고칠 바로 그것** — 지금은 404 여야 한다 ─────
  step "1-ㅍ. 🔴 포털이 게시판에 **지금** 물어 본다 (앱이 쓰는 그 길로)"
  say "  🔵 지금은 게시판이 $OLD_BOARD 라 그 통로가 **없다** — **404 가 정상**이다."
  say "     🔴 교체 뒤 5-ㄹ 에서 다시 물으면 **401** 이 와야 한다. 그 숫자 하나가"
  say "        「이 배포가 무엇을 했는가」의 답이다."
  board_route_from_portal old
  say "  🔴 반대 방향 — 게시판이 포털에 물으러 갈 수 있는가:"
  portal_from_board
}

# ══════════════════════════════════════════════════════════════════════
#  compose 갈아 끼우기
#
#  🔴 --check 는 **갈아 끼우지 않는다.** 읽기만 한다는 약속이 먼저다.
#  🔴 바꾸기 **전에** 새 파일을 먼저 시험한다. 없는 env_file 하나면 docker
#     compose 명령이 **통째로** 실패해서, 앱을 멈춘 뒤에 그걸 알게 되면 다시
#     띄우지도 못한다. 🔴 포털에서는 그것이 「전원 못 들어옴」이 된다.
# ══════════════════════════════════════════════════════════════════════
compose_incoming() {
  local e MISS nimg
  [ -s "$INCOMING" ] || return 0
  if cmp -s "$INCOMING" "$CF"; then
    say "  · incoming 의 compose 가 지금 것과 같다 — 할 일이 없다"
    return 0
  fi
  step "새 compose 를 먼저 시험한다 (바꾸기 전에)"
  MISS=""
  for e in $(sed '/^[[:space:]]*#/d' "$INCOMING" | grep -oE '\./env/[A-Za-z0-9_.-]+\.env' | sort -u); do
    [ -f "$D/deploy/${e#./}" ] || MISS="$MISS ${e#./}"
  done
  if [ -n "$MISS" ]; then
    bad "새 compose 가 **없는 설정 파일**을 가리킨다:$MISS"
    say "    → 하나만 없어도 docker compose 가 통째로 실패한다."
    return 1
  fi
  if compose_at "$INCOMING" config --quiet >/dev/null 2>&1; then
    ok "새 compose 문법 통과"
  else
    bad "새 compose 에 문법 오류가 있다"
    compose_at "$INCOMING" config --quiet 2>&1 | sed 's/^/    /' | head -10
    return 1
  fi
  say "  🔵 지금 것과 달라진 줄 — 🔴 **image 두 줄이어야 한다**:"
  say "     (볼륨 줄이나 다른 서비스가 보이면 남의 변경이 섞인 것이다 —"
  say "      고치지 말고 알리세요. 재고관리 블록이면 머리말의 그 절을 보세요.)"
  diff "$CF" "$INCOMING" 2>/dev/null | sed 's/^/      /' | head -60
  nimg=$(diff "$CF" "$INCOMING" 2>/dev/null | grep -c '^[<>][[:space:]]*image:')
  say "  · 달라진 image 줄: ${nimg:-?}개 (🔵 앞뒤를 함께 세므로 **4** 가 맞다)"
  if [ "$MODE" = go ]; then
    mkdir -p "$BKD"
    cp -p "$CF" "$BKD/docker-compose.nas.yml.$STAMP"
    cp "$INCOMING" "$CF"
    chown root:root "$CF"; chmod 644 "$CF"
    rm -f "$INCOMING"
    ok "compose 새것으로 (옛것: backups/docker-compose.nas.yml.$STAMP)"
    CF_EFF=$CF
  else
    CF_EFF=$INCOMING
    say "  🔵 --check 라서 **갈아 끼우지 않았다.** 아래 검사는 incoming 의 파일을 본 것이다:"
    say "     $INCOMING"
    say "     갈아 끼우는 것은 --go 가 한다."
  fi
  return 0
}
# ══ 되돌리기 ═══════════════════════════════════════════════════════════
#
# 🔴 포털이 섞여 있으므로 24번처럼 **또렷하게** 적는다. 로그인 문이 닫히면
#    1분이 길다 — 읽고 고민하는 자리가 아니라 **그대로 칠 줄**이 있어야 한다.
if [ "$MODE" = rollback ]; then
  echo "DSS 스물한째 배포 되돌리기 (포털 · 게시판) · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     되돌리는 것은 **이미지 둘**이다:"
  say "       $TAG_AUTH  → $OLD_AUTH"
  say "       $TAG_BOARD → $OLD_BOARD"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 **급할 때 — 이 여섯 줄이면 돌아간다** (각 줄 76자 안쪽)      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  cmd "cd /volume1/dss/deploy"
  cmd "sed -i 's/$TAG_AUTH/$OLD_AUTH/' docker-compose.nas.yml"
  cmd "sed -i 's/$TAG_BOARD/$OLD_BOARD/' docker-compose.nas.yml"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps $AUTH_SVC $BOARD_SVC"
  say "     🔵 바뀐 자리가 **그 두 줄뿐**이라 sed 로 내려도 안전하다."
  say "     🔴 다만 **먼저 아래 1번**으로 옛 이미지 둘이 있는지 보세요 —"
  say "        없으면 위 여섯 줄은 「이미지를 못 찾는다」로 끝난다."
  say "     🔵 확인:"
  cmd "grep -n 'image: dss-auth\\|image: dss-board' docker-compose.nas.yml"
  say "  🔵 **포털만** 되돌리고 싶으면 위에서 board 줄과 sed 하나를 빼세요."
  say "     (둘은 서로를 필요로 하지 않는다 — 포털 1.7 은 게시판이 옛 판이면"
  say "      그 줄만 조용히 못 받고, 게시판 0.2 는 포털이 옛 판이어도 제 종은"
  say "      그대로 뜬다. **반쪽만 되돌려도 아무것도 깨지지 않는다.**)"
  script_file_hint "26-rollback"
  say
  say "  🔵 되돌릴 것이 **이미지 둘뿐**입니다."
  say "     · DB — 바꾼 적이 없다(마이그레이션 양쪽 0건)"
  say "     · .env — 🔵 **이번엔 한 글자도 안 적었다**"
  say "     · 볼륨 — 🔵 **이번엔 안 더했다**(서명 키 · 첨부는 그대로다)"
  say "     · 첨부 바이트 — 🔵 호스트 폴더에 있다. 되돌려도 **그대로 있다**"
  say
  say "  🔴 되돌리면 **통합 알림에서 게시판이 사라진다.**"
  say "     · 포털 종에 게시판 줄이 안 뜬다(포털만 되돌려도 그렇다)"
  say "     · 게시판 머리말의 **종이 통째로 사라진다**(게시판을 되돌렸을 때)"
  say "     · 게시판 탭 아이콘과 [통합 로그인으로] 도 함께 사라진다"
  say "     🔵 그뿐이다 — 로그인도 글도 첨부도 **아무것도 안 달라진다.**"
  say "     🔵 **세션도 안 끊긴다** — 되돌릴 때도 DB 둘은 멈추지 않는다."

  step "1. 🔴 옛 이미지 둘이 아직 NAS 에 있는지 **먼저** 본다"
  if have_img "$OLD_AUTH"; then
    ok "$OLD_AUTH 있다 ($(img_id "$OLD_AUTH" | cut -c1-19)…) — 되돌릴 수 있다"
  else
    bad "🔴 $OLD_AUTH 가 **없다** — 위 줄로는 포털을 못 돌린다"
    say "    → 개발 PC(PowerShell)에서 다시 굽고 올리세요:"
    cmd "docker build -t dss-auth:1.6 ."
    cmd "docker save dss-auth:1.6 -o dss-auth-1.6.tar"
    cmd "scp -O dss-auth-1.6.tar dss-nas:/volume1/dss/images/"
    say "    🔴 그 1.6 은 커밋 c51ff52 에서 구워야 같다."
  fi
  if have_img "$OLD_BOARD"; then
    ok "$OLD_BOARD 있다 ($(img_id "$OLD_BOARD" | cut -c1-19)…) — 되돌릴 수 있다"
  else
    bad "🔴 $OLD_BOARD 가 **없다** — 위 줄로는 게시판을 못 돌린다"
    say "    🔴 그 0.1 은 커밋 **8980a60** 에서 구워야 같다(실측으로 찾은 값이다)."
  fi

  step "2. 🔵 사본으로 되돌리는 길 (급하지 않을 때는 이쪽이 정석이다)"
  say "  --go 가 옛 compose 를 아래에 남겼다 (가장 최근 것):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -3 | sed 's/^/      /'
  cmd "cd /volume1/dss/deploy"
  cmd "cp \$(ls -1t ../backups/docker-compose.nas.yml.* | head -1) ."
  say "      (파일 이름이 길면 위 한 줄 대신 두 줄로 나눠 치세요)"
  say "  그다음 위 「급할 때」의 뒤 세 줄(D1 · F · up)을 그대로 칩니다."
  say "  🔴 **인자 없는 up -d 를 부르지 않는다** — DB 컨테이너까지 다시 만든다."

  step "3. 🔴 되돌린 뒤 바로 볼 것"
  say "  (아래는 되돌린 **뒤에** 이 스크립트를 --check 로 한 번 더 돌리면 다 본다.)"
  cmd "bash $0"
  say "  급하면 이 넷만 (🔴 첫 줄이 나머지를 짧게 만든다):"
  cmd "U=http://127.0.0.1:$AUTH_PORT"
  cmd "curl -s -o /dev/null -w '%{http_code}\\n' -m 10 \$U/signin"
  cmd "curl -s -o /dev/null -w '%{http_code}\\n' -m 10 https://login.dss21.co.kr/"
  cmd "curl -s -o /dev/null -w '%{http_code}\\n' -m 10 https://board.dss21.co.kr/"

  step "4. 지금 상태"
  say "  dss-auth  : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep '^dss-auth ' || echo '안 돌고 있다')"
  say "  dss-board : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep '^dss-board ' || echo '안 돌고 있다')"
  say "  (A/S · 계측기 · 개선요청 · PO · 휴가 · DB 둘은 이번에 건드리지 않았다.)"
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터 check · preload · force-load · go ═════════════════════════
echo "DSS 스물한째 배포 · 2026-10-13 · $(date '+%F %T')"
echo "  🔴 올라가는 것은 **둘**:"
echo "       $OLD_AUTH  → $TAG_AUTH   (커밋 3개)"
echo "       $OLD_BOARD → $TAG_BOARD  (커밋 **7개** — 머리말의 그 절)"
echo "  🔴 멈추는 것도 **둘**:  dss-auth · dss-board"
echo "     🔴 그중 하나가 **로그인 문**이다 — 포털이 안 뜨면 일곱 사이트"
echo "        어디에도 새로 못 들어간다."
echo "     🔵 이미 들어가 있는 사람은 그대로 일한다(세션이 DB 에 있다)."
echo "  🔴 이 판이 하는 일은 **하나**다 — 「어느 시스템에서 종을 열어도 모든"
echo "     사내 시스템의 알림이 보인다」에 **사내 게시판**을 들인다."
echo "  🔵 **마이그레이션 양쪽 0건** · **새 볼륨 없음** · **.env 0줄**"
echo "     · **도구 이미지 안 바꿈** · **양식 없음**"
echo "  🔴 포털 화면의 **v 표기는 1.5 그대로**다 — 소식 글을 더하지 않았다."
echo "     1.7 은 **배포본 번호**다. 화면에서 v1.7 을 찾지 마세요."
echo "  🔵 야간 백업은 **02:30** — 🔴 이번에 볼 것은 **$AUTH_DB · $BOARD_DB 둘**"
echo "  · 건드리지 않는 열 — $KEEP_AS · $KEEP_ASTOOLS · $KEEP_METERS"
echo "    · $KEEP_METERSTOOLS · $KEEP_IMP · $KEEP_IMPTOOLS"
echo "    · $KEEP_PO · $KEEP_LEAVE · $KEEP_LEAVETOOLS · $KEEP_BOARDTOOLS"
echo
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║ 🔴 **되돌리는 길** — 먼저 읽어 두세요. 포털은 빠른 것이 먼저다. ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo "      bash $0 --rollback        ← 여섯 줄을 찍어 줍니다"
echo "      🔵 되돌릴 것은 **이미지 둘**뿐입니다(DB 0 · .env 0 · 볼륨 0)."
if ! pinned; then
  echo "  ⚠️ 🔴 **이미지 기대값 여섯이 비어 있습니다.**"
  echo "     1.7 과 0.2 를 굽고 재어 채우기 전에는 --go 가 시작하지 않습니다."
  echo "     재는 차례는 이 파일 머리말 「값 여섯을 채워야 한다」."
fi
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**"
              echo "     🔵 아직 안 온 것 · 안 실린 것은 ⚠️ 로만 말한다(✗ 가 아니다)."
              echo "     🔵 DB 에 보내는 문장은 **전부 select** 다 — 끝에 세어서 찍는다." ;;
  preload)    echo "  🔵 --preload — 새 이미지 **둘**을 싣고 지문만 맞춘다. **안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — 포털과 게시판을 교체한다. **DB 도 .env 도 볼륨도 안 바꾼다.**"
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(백업 · 키)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "새 이미지 tar 둘 · 지문"
  EXP_AUTH=$(tar_config_id "$TAR_AUTH" 2>/dev/null) || EXP_AUTH=""
  see_tar "$TAG_AUTH" "$TAR_AUTH" "$EXP_AUTH" "$SZ_AUTH" "$MD5_AUTH" "$WANT_CFG_AUTH" dss-auth-1.7.tar
  if [ -s "$TAR_AUTH" ] && [ -n "$EXP_AUTH" ]; then
    bring_img "$TAG_AUTH" "$TAR_AUTH" "$EXP_AUTH"
  else
    bad "$TAG_AUTH 를 싣지 않았다 — tar 가 없거나 manifest.json 을 못 읽었다"
  fi
  EXP_BOARD=$(tar_config_id "$TAR_BOARD" 2>/dev/null) || EXP_BOARD=""
  see_tar "$TAG_BOARD" "$TAR_BOARD" "$EXP_BOARD" "$SZ_BOARD" "$MD5_BOARD" "$WANT_CFG_BOARD" dss-board-0.2.tar
  if [ -s "$TAR_BOARD" ] && [ -n "$EXP_BOARD" ]; then
    bring_img "$TAG_BOARD" "$TAR_BOARD" "$EXP_BOARD"
  else
    bad "$TAG_BOARD 를 싣지 않았다 — tar 가 없거나 manifest.json 을 못 읽었다"
  fi

  # 🔴 실어 놓고 **안을 본다.**
  step "새 이미지 안에 이번 판이 들어 있는가 (글자)"
  if have_img "$TAG_AUTH"; then
    mark_check image "$TAG_AUTH" "포털" "$AUTH_M1" "$AUTH_M2" "" "$AUTH_CTRL" "$OLD_AUTH"
  fi
  if have_img "$TAG_BOARD"; then
    mark_check image "$TAG_BOARD" "게시판" "$BOARD_M1" "$BOARD_M2" "$BOARD_M3" "$BOARD_CTRL" "$OLD_BOARD"
  fi

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 멈추지 않았다**"
  if [ "$FAIL" != 0 ] && [ "$FORCE_LOAD" != 1 ]; then
    echo "  🔴 지문이 어긋난 것이 있으면 **같은 태그로 다시 구운 것**이다:"
    echo "       bash $0 --force-load"
  fi
  echo "  🔵 나머지 항목은 안 봤다. 이어서: bash $0        (읽기만)"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 1. 먼저 볼 것 ══════════════════════════════════════════════════════
#
# 🔴 규칙 하나: **앱을 멈추기 전에 볼 것을 다 보고, 어긋나면 앱이 살아 있는
#    채로 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
step "1. 점검표를 기계로 옮긴 것 (앱 둘은 살아 있다 · DB 는 손도 안 댄다)"
compose_incoming || stop "compose 를 바꾸지 않았습니다. 포털도 게시판도 그대로 돕니다."
run_checks
sql_report

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  🔵 DB 에 보낸 문장 $SQL_N 개 · select $SQL_SELECT_N 개 · 그 밖 $((SQL_N - SQL_SELECT_N))개"
  if [ "$FAIL" = 0 ]; then
    if pinned; then
      echo "  ✅ 이어서 (🔴 포털과 게시판이 잠깐 멈춥니다):"
      echo "       bash $0 --go"
      echo "     🔴 --go 는 오늘 백업($AUTH_DB · $BOARD_DB)이 없으면 바로 멈춥니다."
      echo "     🔵 야간 백업은 02:30 입니다 — 먼저 손으로 뜨려면:"
      echo "          bash /volume1/dss/jobs/backup-nightly.sh"
      echo "     🔵 **이미 로그인한 사람은 다시 로그인하지 않아도 됩니다.**"
    else
      echo "  🔴 아직 --go 를 부를 수 없습니다 — 이미지 기대값 여섯이 비어 있습니다."
      echo "     개발 PC 에서 굽고 재어 이 파일에 채운 뒤 다시 올리세요."
    fi
    echo "     🔵 ⚠️ 가 있었다면 아직 안 온 파일이 있다는 뜻입니다 — 올리고"
    echo "        --preload 한 뒤 이 명령을 한 번 더 돌리세요."
  else
    echo "  ✗ 위 ✗ 를 먼저 해결하세요. Claude 에게 알려 주세요."
    echo "    🔵 「아직 안 온 것 · 안 실린 것」은 ✗ 가 아닙니다 — ⚠️ 로 찍혔습니다."
  fi
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi
# ══ --go ═══════════════════════════════════════════════════════════════
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 바꾸지 않았고 두 앱은 살아 있습니다.**"
pinned || {
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 이미지 기대값 여섯이 **비어 있습니다.** 재지 않은 이미지를   ║"
  say "  ║    운영에 올리지 않습니다. 🔴 더구나 하나는 로그인 문입니다.    ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  stop "아무것도 바꾸지 않았습니다. 앱도 DB 도 그대로입니다."
}

# ── 2. 이미지 둘을 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ────────
step "2. 새 이미지 **둘** 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
[ -n "$EXP_AUTH" ]  || stop "포털 tar 에서 지문을 못 읽었습니다. **아무것도 바꾸지 않았습니다.**"
[ -n "$EXP_BOARD" ] || stop "게시판 tar 에서 지문을 못 읽었습니다. **아무것도 바꾸지 않았습니다.**"
bring_img "$TAG_AUTH" "$TAR_AUTH" "$EXP_AUTH" || {
  say "  🔴 포털 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
}
bring_img "$TAG_BOARD" "$TAR_BOARD" "$EXP_BOARD" || {
  say "  🔴 게시판 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
}

# ══ 3. 🔴 멈추기 전에 — 백업 · 사본 · 세션 수 · 첨부 수 · 시작 시각 ════
#
# 🔴 여기까지가 「돌이킬 수 있는 자리」다. 두 앱은 아직 옛 판으로 **살아 있다.**
# 🔵 DB 덤프는 뜨지 않는다 — 이 판은 DB 를 바꾸지 않는다(양쪽 0건).
# 🔴 **서명 키의 사본도 만들지 않는다.** 그것은 개인키다 — 사본이 늘수록
#    회수할 자리가 는다. 키는 우리가 **건드리지 않으므로** 사본이 필요 없다.
# 🔵 **첨부 스냅숏도 만들지 않는다** — 첨부는 호스트 폴더에 있고 이 배포는
#    그 폴더를 건드리지 않는다. 대신 **파일 수를 전후로 센다**(5-ㅁ).

# ── 3-ㄱ. 🔴 오늘 백업 **둘**을 지금 다시 찾는다. 없으면 멈춘다 ────────
step "3-ㄱ. 🔴 오늘 $AUTH_DB · $BOARD_DB 백업을 **지금 다시** 찾는다"
say "  🔴 **둘이다** — 24번은 dss_auth 하나였다. 게시판이 선 뒤로 하나 늘었다."
BK_MISS=""
for db in "$AUTH_DB" "$BOARD_DB"; do
  f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
  if [ -n "$f" ] && [ -s "$f" ]; then
    ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
  else
    BK_MISS="$BK_MISS $db"
  fi
done
if [ -n "$BK_MISS" ]; then
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 오늘($TODAY) 뜬 백업을 못 찾았습니다:$BK_MISS"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     🔵 이번 판은 DB 를 바꾸지 않습니다. 그래도 **백업 없이 운영 이미지를"
  say "        갈아 끼우지 않습니다** — 17번에서 이 문이 사고를 막았습니다."
  say "     🔴 더구나 $AUTH_DB 에는 **세션과 사용자**가, $BOARD_DB 에는"
  say "        **직원이 쓴 글**이 들어 있습니다."
  cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  say "     ✓ 두 줄이 다 찍혀야 합니다. 그 뒤에 다시:"
  cmd "bash $0 --go"
  stop "백업 없이 교체하지 않습니다. **앱도 DB 도 그대로입니다.**"
fi

# ── 3-ㄴ. 설정 사본 둘 (🔴 고치지는 않는다) ────────────────────────────
step "3-ㄴ. auth.env · board.env 사본 (🔵 DB 덤프도 첨부 스냅숏도 없다)"
for pair in "$AUTH_ENV:auth.env" "$BOARD_ENV:board.env"; do
  f=${pair%%:*}; s=${pair##*:}
  if [ -f "$f" ]; then
    cp -p "$f" "$BKD/$s.$STAMP"; chmod 600 "$BKD/$s.$STAMP"
    ok "$s 사본 — backups/$s.$STAMP (root 600 · 🔵 **고치지는 않는다**)"
  else
    bad "$s 가 없다: $f"
    stop "설정 파일이 없습니다. **앱도 DB 도 그대로입니다.**"
  fi
done
say "  🔵 **DB 덤프는 뜨지 않는다** — 이 판은 DB 를 바꾸지 않는다(양쪽 0건)."
say "     오늘 야간 백업이 이미 둘을 떠 두었다(3-ㄱ 에서 확인했다)."
say "  🔴 **서명 키 사본도 만들지 않는다** — 개인키다. 우리가 건드리지 않으므로"
say "     사본이 필요 없고, 사본이 늘수록 회수할 자리만 는다."

# ── 3-ㄷ. 🔴 살아 있는 세션 수 · 첨부 파일 수를 적어 둔다 ──────────────
step "3-ㄷ. 🔴 세션 수와 첨부 파일 수를 적어 둔다 (뒤에서 대조한다)"
SESS_BEFORE=$(live_sessions)
say "  · 🔴 살아 있는 세션: ${SESS_BEFORE:-?}  (안 끊겼고 안 만료된 것)"
say "    🔵 이것이 「세션이 끊기는가」에 대한 **숫자로 된 답**이다."
FILES_BEFORE=$(find "$BOARD_UPLOADS" -type f 2>/dev/null | wc -l | tr -d ' ')
say "  · 🔴 게시판 첨부 파일: ${FILES_BEFORE:-?}개  ($BOARD_UPLOADS)"
say "    🔵 컨테이너를 새로 만들어도 이 폴더는 호스트에 있어 **안 지워진다.**"
say "       그래도 센다 — 볼륨 줄이 빠진 채로 올라가면 **이 수가 0 으로 보인다.**"
say "  🔴 교체 뒤 5-ㅂ 에서 **둘 다 다시 센다.**"

# ── 3-ㄹ. 건드리지 않는 쪽의 **시작 시각**을 적어 둔다 ─────────────────
step "3-ㄹ. 건드리지 않는 **일곱**의 시작 시각을 적어 둔다 (뒤에서 대조한다)"
KEEP_BOXES="dss-as dss-meters dss-improvements dss-po dss-leave $PG_APP $PG_AUTH"
STARTED_BEFORE=""
for t in $KEEP_BOXES; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  STARTED_BEFORE="$STARTED_BEFORE$t=$s
"
  say "  · $t  시작 ${s:-?}"
done
say
say "  🔴 이제 **포털과 게시판**을 바꿔 끼웁니다. 그만두려면 **20초 안에 Ctrl+C**."
say "     지금 Ctrl+C 하면 직원은 $OLD_AUTH 와 $OLD_BOARD 를 그대로 쓰고 있습니다."
say "     (compose 는 이미 바뀌었지만 그것만으로는 아무 일도 일어나지 않습니다 —"
say "      옛 컨테이너가 그대로 돌고 있습니다.)"
say "  🔴 되돌리는 길:  bash $0 --rollback"
sleep 20

# ══ 4. 둘을 새 판으로 바꿔 끼운다 — 🔴 여기 하나가 정지 창이다 ═════════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다(재고관리 블록이 섞여 있으면 그것까지
#    띄운다). --no-deps 로 **이름을 적은 둘만** 부른다.
# 🔴 --no-deps 가 depends_on 을 건너뛴다 — 🔵 그래서 **DB 둘이 멈추지 않는다**
#    (세션도 글도 그대로 있는 까닭).
step "4. 새 이미지로 바꿔 끼운다 (포털 · 게시판)  ⏱ 여기부터 정지 창"
say "  🔴 **멈추는 것은 $AUTH_CNAME 과 $BOARD_CNAME 둘뿐이다.**"
say "     그대로 도는 것: A/S · 계측기 · 개선요청 · PO · 휴가 · DB 둘."
say "  🔵 둘을 **한 번에** 부른다 — 나눠 부르면 정지 창이 그만큼 길어진다."
say "  🔴 그중 포털은 **로그인 문**이다 — 이 몇 초 동안 아무도 **새로** 못 들어온다."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"
"${COMPOSE[@]}" up -d --no-deps "$AUTH_SVC" "$BOARD_SVC" 2>&1 | sed 's/^/    /'
wait_http "포털"   "$AUTH_PORT"  /signin "$AUTH_CNAME"
wait_http "게시판" "$BOARD_PORT" /       "$BOARD_CNAME"
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 5. 스모크 ══════════════════════════════════════════════════════════
step "5. 스모크 — 키 · 로그인 길 · 🔴 **통합 알림** · 첨부 · 세션 · 안 멈췄는가"

# 5-ㄱ. 🔴 서명 키를 새 컨테이너 안에서 실제로 열어 본다
say "  5-ㄱ. 🔴 서명 키(/keys)를 **새 컨테이너** 안에서 연다"
say "     (「만든 것과 도는 것은 다르다」. 1-ㅂ 은 옛 컨테이너였다.)"
if running "$AUTH_CNAME"; then
  keys_probe "$AUTH_CNAME"
  ro_mount_check "$AUTH_CNAME" "$KEYS_MNT" "서명 키"
  # 🔴 **touch 를 쓴다.** 리다이렉션은 읽기 전용 자리에서 셸을 죽인다(머리말 ②).
  if "$DOCKER" exec "$AUTH_CNAME" sh -c "t=$KEYS_MNT/.dss-ro-test; touch \"\$t\"" >/dev/null 2>&1; then
    bad "🔴 $KEYS_MNT 에 **쓸 수 있다** — :ro 가 안 먹었다"
    "$DOCKER" exec "$AUTH_CNAME" sh -c "rm -f $KEYS_MNT/.dss-ro-test" >/dev/null 2>&1
    say "    🔵 시험 파일은 곧바로 지웠다 — 남아 있으면 알려 주세요."
  else
    ok "🔴 $KEYS_MNT 는 **쓰기가 막혀 있다** (읽기 전용 그대로다)"
  fi
else
  bad "$AUTH_CNAME 컨테이너가 떠 있지 않다"
fi

# 5-ㄴ. 🔴 로그인 길이 사는가
say "  5-ㄴ. 🔴 **로그인 길이 사는가** — 통로가 아니라 **나오는 것**을 본다"
say "     🔵 실제 계정으로 로그인하지는 않는다. **그것은 사람이 한다.**"
login_door_check
issuer_check "포털"   "$AUTH_CNAME"  "$AUTH_ENV"
issuer_check "게시판" "$BOARD_CNAME" "$BOARD_ENV"
redirect_check "게시판" "$BOARD_CNAME" "$BOARD_ENV"

# 5-ㄷ. 🔴 새 판이 **도는 컨테이너** 안에 있는가
say "  5-ㄷ. 🔴 새 판이 **도는 컨테이너** 안에 있는가 (글자)"
say "     (위 1-ㅋ 는 이미지를 봤고 여기는 **도는 것**이다.)"
mark_check run "$AUTH_CNAME"  "포털"   "$AUTH_M1" "$AUTH_M2" "" "$AUTH_CTRL" "$OLD_AUTH"
mark_check run "$BOARD_CNAME" "게시판" "$BOARD_M1" "$BOARD_M2" "$BOARD_M3" "$BOARD_CTRL" "$OLD_BOARD"

# 5-ㄹ. 🔴🔴 **이 배포의 핵심** — 아까 404 였던 자리가 401 이 되는가
say "  5-ㄹ. 🔴🔴 **이 배포가 한 일을 숫자 하나로 본다**"
say "     1-ㅍ 에서 포털이 게시판에 물었을 때 **404** 였다(통로가 없었다)."
say "     🔴 지금 다시 묻는다 — **401** 이어야 한다(통로가 있고 자격을 따진다)."
board_route_from_portal new
say "     🔴 반대 방향 — 게시판이 포털에 물으러 갈 수 있는가:"
portal_from_board
say "     🔵 통로 둘이 바깥(프록시)에서도 열려 있는지 한 번 더:"
for p in "$NOTI_PATH" "$NOTI_SET_PATH"; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "http://127.0.0.1:$BOARD_PORT$p" 2>/dev/null)
  case "$code" in
    401) ok "게시판 $p → 401 (자격 없이 거절 — 맞다)" ;;
    404) bad "🔴 게시판 $p → **404** — 옛 판이 돌고 있다" ;;
    *)   bad "🔴 게시판 $p → ${code:-없음} (401 이어야 한다)" ;;
  esac
done

# 5-ㅁ. 🔴 첨부가 그대로 붙어 있는가 — **쓸 수 있는지**까지 본다
say "  5-ㅁ. 🔴 첨부($BOARD_MNT) — 붙어 있고 **쓸 수 있는가**"
if running "$BOARD_CNAME"; then
  rw_mount_check "$BOARD_CNAME" "$BOARD_MNT" "첨부"
  # 🔴 **touch 를 쓴다.** 리다이렉션으로 빈 파일을 만들면 ash 가 죽는다.
  if "$DOCKER" exec "$BOARD_CNAME" sh -c "t=$BOARD_MNT/.dss-write-test; touch \"\$t\"" >/dev/null 2>&1; then
    ok "🔴 $BOARD_MNT 에 **실제로 썼다** — 직원이 사진을 붙일 수 있다"
    "$DOCKER" exec "$BOARD_CNAME" sh -c "rm -f $BOARD_MNT/.dss-write-test" >/dev/null 2>&1
    n=$(find "$BOARD_UPLOADS" -maxdepth 1 -name '.dss-write-test' 2>/dev/null | wc -l | tr -d ' ')
    [ "${n:-0}" = 0 ] && ok "시험 파일이 남지 않았다" \
      || bad "시험 파일이 남아 있다 — rm -f $BOARD_UPLOADS/.dss-write-test"
  else
    bad "🔴 $BOARD_MNT 에 **못 쓴다** — 사람이 사진을 붙이는 순간 깨진다"
    say "      🔴 그 자리는 uid 1000(node)에게 열려 있어야 한다. 고치는 길:"
    cmd "sh /volume1/dss/setup/25-board-place.sh"
  fi
else
  bad "$BOARD_CNAME 가 떠 있지 않아 첨부를 못 봤다"
fi

# 5-ㅂ. 🔴 세션과 첨부가 줄지 않았는가 — 숫자로 다시 센다
say "  5-ㅂ. 🔴 **세션 · 첨부** — 바꾸기 전 숫자와 견준다"
SESS_AFTER=$(live_sessions)
FILES_AFTER=$(find "$BOARD_UPLOADS" -type f 2>/dev/null | wc -l | tr -d ' ')
say "     · 세션  바꾸기 전 ${SESS_BEFORE:-?} → 바꾼 뒤 ${SESS_AFTER:-?}"
say "     · 첨부  바꾸기 전 ${FILES_BEFORE:-?} → 바꾼 뒤 ${FILES_AFTER:-?}"
# 🔴 숫자인지를 **먼저** 가린다. psql 이 숫자가 아닌 것을 돌려줬을 때
#    $(( )) 에 그대로 넣으면 set -u 아래서 셸이 그 자리에서 죽는다.
if [ -z "${SESS_BEFORE:-}" ] || [ -z "${SESS_AFTER:-}" ]; then
  bad "세션 수를 못 셌다 — DB 를 못 읽었다"
elif [ "$SESS_AFTER" = "$SESS_BEFORE" ]; then
  ok "🔴 살아 있는 세션이 **그대로다** — 아무도 로그아웃되지 않았다"
else
  case "$SESS_BEFORE$SESS_AFTER" in
    *[!0-9]*)
      bad "세션 수가 숫자가 아니다 (${SESS_BEFORE} → ${SESS_AFTER}) — DB 를 제대로 못 읽었다" ;;
    *)
      if [ "$SESS_AFTER" -gt "$SESS_BEFORE" ]; then
        ok "🔴 세션이 오히려 늘었다(${SESS_BEFORE} → ${SESS_AFTER}) — 그 사이 누가 들어왔다"
      elif [ $((SESS_BEFORE - SESS_AFTER)) -le 2 ]; then
        ok "세션이 ${SESS_BEFORE} → ${SESS_AFTER} (12시간이 지나 저절로 빠진 것이다)"
      else
        bad "🔴 세션이 ${SESS_BEFORE} → ${SESS_AFTER} 로 **많이 줄었다** — 끊긴 사람이 있다"
        say "      🔴 이것은 예상 밖이다. 세션은 DB(sso_sessions)에 있고 이 배포는"
        say "         $PG_AUTH 를 멈추지 않는다. Claude 에게 알려 주세요."
      fi ;;
  esac
fi
if [ "${FILES_AFTER:-x}" = "${FILES_BEFORE:-y}" ]; then
  ok "🔴 첨부 파일 수가 **그대로다** — 볼륨이 제자리에 붙었다"
else
  bad "🔴 첨부 파일 수가 ${FILES_BEFORE:-?} → ${FILES_AFTER:-?} 로 달라졌다"
  say "      🔴 줄었다면 **볼륨 줄이 빠진 채로 올라간 것**일 수 있다. 즉시 알리세요."
fi

# 5-ㅅ. 🔴 건드리지 않는 쪽이 **정말 안 멈췄는가**
say "  5-ㅅ. 🔴 건드리지 않는 **일곱**이 안 멈췄는가 (시작 시각을 대조한다)"
for t in $KEEP_BOXES; do
  before=$(printf '%s\n' "$STARTED_BEFORE" | sed -n "s/^$t=//p" | head -1)
  after=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  if [ -n "$before" ] && [ "$before" = "$after" ]; then
    ok "$t · 시작 시각 그대로 — **한 번도 안 멈췄다**"
  else
    bad "🔴 $t 의 시작 시각이 바뀌었다 ($before → $after) — 이 배포가 건드렸다"
  fi
done

# 5-ㅇ. 🔴 바깥 주소 일곱
say "  5-ㅇ. 🔴 바깥 주소 **일곱이 전부 사는가**"
for h in login board; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code (바뀐 쪽 · 열려 있다)" ;;
    *)       bad "🔴🔴 https://$h.dss21.co.kr → ${code:-없음} — **닫혔다**"
             say "      🔴 바로 되돌리세요:"
             cmd "bash $0 --rollback" ;;
  esac
done
say "  🔴 안 바뀌는 다섯 — 흔들렸으면 **이 배포가 건드린 것**이다:"
for h in as meters improvements po leave; do
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

sql_report

# ══ 6. 마무리 ══════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · 약 ${DOWN}초"
echo "  🔵 바꾼 것은 **이미지 둘뿐**입니다 — DB 0 · .env 0줄 · 볼륨 0 · 양식 0벌"
echo "  🔵 DB 에 보낸 문장 $SQL_N 개 · select $SQL_SELECT_N 개 · 그 밖 $((SQL_N - SQL_SELECT_N))개"
echo "  🔵 살아 있는 세션 ${SESS_BEFORE:-?} → ${SESS_AFTER:-?}"
echo "  🔵 게시판 첨부 ${FILES_BEFORE:-?} → ${FILES_AFTER:-?}"
echo "  .env 사본: $BKD/auth.env.$STAMP · $BKD/board.env.$STAMP"
echo "  로그: $LOG · SQL 목록: $SQLLOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" != 0 ]; then
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
  echo "되돌리기 안내:  bash $0 --rollback"
  exit "$FAIL"
fi
cat <<ANNOUNCE

╔════════════════════════════════════════════════════════════════════╗
║ 🔵 **다시 로그인하지 않으셔도 됩니다.**                                ║
╚════════════════════════════════════════════════════════════════════╝

  포털의 세션은 DB(sso_sessions · $AUTH_DB · $PG_AUTH)에, 게시판의 세션은
  DB(web_sessions · $BOARD_DB · $PG_APP)에 있습니다. 🔴 **이 배포는 그 DB
  둘을 멈추지 않습니다** — up 을 --no-deps 로 부르고 이름을 적은 것은
  $AUTH_SVC 와 $BOARD_SVC 뿐입니다.
  🔵 서명 키도 그대로입니다 — 이미지가 아니라 호스트 폴더($KEYS_HOST)에
  있습니다. 이미 나간 로그인 토큰도 계속 검증됩니다.
  🔵 위 5-ㅂ 이 **숫자로** 확인했습니다: ${SESS_BEFORE:-?} → ${SESS_AFTER:-?}.
  🔴 다만 바꿔 끼우던 **약 ${DOWN}초** 동안 마침 로그인 단추를 누른 분은
  한 번 더 누르시면 됩니다.

╔════════════════════════════════════════════════════════════════════╗
║ 🔴 **포털 화면의 「v1.5」는 그대로입니다. 결함이 아닙니다.**             ║
╚════════════════════════════════════════════════════════════════════╝

  이번 커밋 셋은 소식 글을 하나도 더하지 않았습니다(바뀐 파일이 알림 출처
  목록과 그 시험 **둘뿐**입니다). 🔴 **1.7 은 배포본 번호**입니다.

╔════════════════════════════════════════════════════════════════════╗
║ 🔴 **처음에는 종이 비어 보이는 것이 정상입니다.**                       ║
╚════════════════════════════════════════════════════════════════════╝

  게시판 알림은 **그 사람이 게시판에 한 번이라도 들어와 본 뒤에만** 뜹니다
  (통로가 포털 쪽 id 로 게시판 계정을 찾고, 못 찾으면 **빈 목록**을 돌려
  줍니다 — 오류가 아닙니다). 그리고 **안 읽은 필독·공지가 있어야** 뜨고,
  **자기가 쓴 글은 오지 않으며**, 글을 열면 사라집니다.
  🔵 그래서 「아무것도 안 뜬다」는 대개 **정상**입니다. 아래 2번처럼
  일부러 하나 만들어 보셔야 눈으로 확인됩니다.

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. 🔴 **로그인이 되는지 먼저.** https://login.dss21.co.kr 에서 평소대로
      들어가 보세요. 🔵 이미 열려 있던 창은 그대로일 것입니다 — 그래도
      한 번은 **새로** 들어가 보셔야 합니다(스크립트는 길이 열렸는지만 봤고
      실제 계정으로는 들어가 보지 않았습니다).

   2. 🔴 **이 배포의 핵심.** 게시판(https://board.dss21.co.kr)에 들어가
      **필독이나 공지를 하나 올리고**(관리자 계정으로), **다른 사람 계정**
      으로 포털이나 A/S 의 **종**을 열어 보세요. 거기에 그 글이 보여야
      합니다. 🔴 **누르면 게시판의 그 글로 가야 합니다** — 엉뚱한 주소로
      가면 알려 주세요(알림 링크의 앞머리를 게시판이 스스로 만듭니다).
      🔵 쓴 사람 자신에게는 안 보이는 것이 맞습니다.

   3. 🔴 **게시판 머리말의 종.** 게시판에서도 종이 보이고, 그 종에
      **다른 시스템(A/S · 휴가 · 개선요청)의 알림이 함께** 보여야 합니다.
      🔵 이 종은 0.1 에는 아예 없었습니다 — 처음 생기는 것입니다.

   4. 🔵 게시판 탭 아이콘이 **회사 로고**인지, 머리말에
      **[통합 로그인으로]** 가 있는지. (0.1 뒤에 들어온 커밋 둘입니다.)

   5. 🔵 나머지 다섯이 그대로입니까 — A/S · 계측기 · 개선요청 · PO · 휴가.
      (스크립트가 5-ㅅ 에서 시작 시각으로, 5-ㅇ 에서 주소로 이미 확인했습니다.)

🔴 사람이 이어서 할 일:
  · 내일 아침 백업을 한 번 더 보세요 — **여섯**이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -8
  · .env 사본 둘($BKD/auth.env.$STAMP · $BKD/board.env.$STAMP)은
    한 주쯤 두었다 지우세요.
    🔴 그 안에 비밀값이 있습니다 — 다른 데로 옮기지 마세요.
  · 🔵 **재고 관리**는 포털 상수에 이미 들어 있습니다. 그 사이트가 서고
    포털에 등록되는 날부터 **포털을 다시 배포하지 않아도** 종에 붙습니다.

되돌리기 안내:  bash $0 --rollback
  🔵 되돌릴 것은 **이미지 둘뿐**입니다 — DB 도 .env 도 볼륨도 안 바꿨습니다.
  🔵 **반쪽만 되돌려도 아무것도 깨지지 않습니다**(그 모드가 설명합니다).
ANNOUNCE
exit "$FAIL"

