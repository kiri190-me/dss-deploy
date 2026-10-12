#!/bin/bash
# /volume1/dss/setup/24-deploy.sh — 2026-10-12 스무째 배포
#
# ── 🔴 오늘 **네 번째** 배포다 ─────────────────────────────────────────
#
#   20:50 열일곱째(A/S 2.4 · PO 0.4) · 22:22 열여덟째(A/S 2.5 · PO 0.5) ·
#   23:07 열아홉째(휴가 0.2 + 표 하나). 이번이 **넷째**다.
#
#     포털  dss-auth:1.5  →  **dss-auth:1.6**   (커밋 1개 · c51ff52)
#
#   나머지 다섯(A/S 2.5 · 계측기 1.3 · 개선요청 0.3 · PO 0.5 · 휴가 0.2)은
#   **건드리지 않는다. 멈추지도 않는다.**
#
# ══ 🔴 포털은 **로그인 문**이다 — 앞의 셋보다 조심한다 ═════════════════
#
#   앞의 넷(A/S · PO · 휴가)은 **업무 사이트**였다. 하나가 죽어도 나머지는
#   돌았다. 🔴 **포털은 다르다.** 여섯 사이트 전부가 이 문을 지나 들어온다.
#   포털이 안 뜨면 **아무도 아무 데도 못 들어간다.**
#
#   그래서 이 판에만 있는 것이 넷이다:
#     ① 🔴 **되돌리는 길을 맨 위에 적어 둔다** — 급할 때 다섯 줄(각 76자 안쪽).
#     ② 🔴 **로그인 길이 사는지를 스모크로 본다** — 바깥 주소 여섯 ·
#        /signin · /.well-known/openid-configuration · /.well-known/jwks.json.
#        🔵 **실제 계정으로 로그인하지는 않는다**(사람이 한다).
#     ③ 🔴 **서명 키 볼륨**(/keys)을 새 컨테이너 안에서 실제로 읽어 본다.
#        키를 못 읽으면 화면은 뜨는데 **여섯 사이트 전부가 토큰을 거절한다.**
#     ④ 🔴 **세션이 끊기는지를 숫자로 센다** — 바꾸기 전과 뒤에 각각 센다.
#
# ══ 🔵 세션은 **안 끊긴다** — 코드를 보고 내린 판단이다 ════════════════
#
#   🔴 **다시 로그인하지 않아도 된다.** 근거는 셋이다:
#
#   ① **세션이 DB 에 있다.** dss-auth/src/lib/db/schema/sso-sessions.ts 머리말 —
#      「A/S 의 dss_session 쿠키(서명만으로 성립하는 stateless 토큰)와 달리
#       **서버 저장형**이다」. 표는 sso_sessions, DB 는 dss_auth, 그 DB 는
#      **dss-pg-auth** 컨테이너 안이다. 브라우저 쿠키(dss_sso)에는 난수 32바이트만
#      들어 있고 DB 에는 그 sha256 만 있다(src/lib/session/sso-session.ts).
#      🔴 **이 배포는 dss-pg-auth 를 멈추지 않는다** — up 을 --no-deps 로 부르고
#      이름을 적는 것은 app-auth 하나뿐이다. 그래서 그 표가 그대로 있고,
#      포털이 다시 뜨면 **같은 쿠키가 그대로 통한다.**
#
#   ② **서명 키가 이미지 안이 아니다.** compose 가 호스트 폴더
#      /volume1/dss/auth-keys 를 /keys 에 읽기 전용으로 붙인다. 컨테이너를
#      새로 만들어도 키가 그대로라 **이미 나간 ID 토큰도 계속 검증된다.**
#
#   ③ **로그인 왕복 쿠키의 서명 키도 그대로다.** AUTH_TX_SECRET 은 auth.env 에서
#      온다(src/lib/config/env.ts 의 required). 프로세스가 만들어 내는 값이
#      아니라서 다시 띄워도 안 바뀐다 — 카카오 화면에 가 있던 사람도 돌아오면
#      그대로 이어진다(그 쿠키의 수명은 10분이다).
#
#   🔴 **다만 바꿔 끼우는 그 몇 초 동안**은 포털로 들어온 요청이 실패한다.
#      그때 마침 로그인 단추를 누른 사람은 **한 번 더 누르면 된다.**
#      이 스크립트가 5-ㄹ 에서 **살아 있는 세션 수를 전후로 세어** 보여 준다.
#
# ══ 🔴 이 판은 22번에서 **더 덜어낸** 판이다 ═══════════════════════════
#
#   본은 22-deploy.sh(2,138줄) — **가장 가벼운 판**이었다(이미지 둘 ·
#   compose 두 줄). 이번은 그보다도 가볍다(**이미지 하나 · compose 한 줄**).
#   걷어낸 자리마다 「이번엔 없다」를 적어 둔다 — 다음 사람이 「왜 빠졌지」
#   하지 않게.
#
#     |                | 22번(열여덟째)        | **24번(이번)**             |
#     | 멈추는 것     | A/S · PO **둘**       | 🔴 **포털 하나**           |
#     | 이미지        | 둘                    | 🔴 **하나**                |
#     | compose 변경  | 태그 **둘**           | 🔴 **태그 한 줄**          |
#     | 올릴 파일     | 셋                    | 🔴 **둘** (tar + compose)  |
#     | 마이그레이션  | 0건                   | **0건** (그대로 없음)      |
#     | 새 볼륨       | 없음                  | **없음**                   |
#     | .env 줄       | 없음(있는가만 봄)     | **없음**(있는가만 봄)      |
#     | 양식 교체     | 없음                  | **없음**                   |
#     | 도구 이미지   | 안 건드림             | 🔴 **포털엔 아예 없다**    |
#     | 공유폴더 볼륨 | 다섯(그대로 있는가)   | 🔴 **포털엔 하나도 없다**  |
#     | 백업 DB       | dss_as                | 🔴 **dss_auth**            |
#
#   ── 🔴 ① 공유폴더 볼륨 — **포털에는 하나도 없다** (실측) ────────────
#     docker-compose.nas.yml 의 app-auth 블록에 붙은 볼륨은 **딱 하나**다:
#         - /volume1/dss/auth-keys:/keys:ro
#     /quote-archive · /customer-portal-archive · /contact-folder-archive ·
#     /repair-docs-archive · /purchase-order-archive 는 **한 줄도 없다.**
#     group_add 도 없고 /data 도 없다 — 포털은 사내 서류함을 쳐다보지 않는다.
#     🔴 그래서 22번의 공유폴더 검사 **열몇 줄을 통째로 걷어냈다**(probe_svc ·
#        ro_mount_check · mnt_count_check · perm_fix_hint · PO_SRC · 대소문자
#        함정 안내 · ACL 경고). 🔵 22번이 양식 검사를 걷어낸 그 모양이다.
#     🔴 **대신 /keys 하나를 그 자리만큼 깐깐히 본다** — 그것이 로그인의 심장이다.
#
#   ── 🔴 ② 도구 이미지 — **포털에는 아예 없다** (실측) ────────────────
#     compose 에 tools-auth 라는 서비스가 **없다**(grep 으로 확인했다. 도구는
#     tools-as · tools-meters · tools-improvements · tools-leave 넷뿐이다).
#     포털은 마이그레이션도 야간 작업도 compose 를 통해 돌리지 않는다 —
#     백업은 BACKUP_MODE=direct 로 앱 컨테이너 안에서 돈다.
#     🔵 그래서 「도구 이미지를 다시 굽는다」가 이번엔 **할 일 자체가 없다.**
#
#   ── 🔴 ③ 마이그레이션 — **없다** ──────────────────────────────────
#     커밋 c51ff52 는 drizzle/ 을 한 글자도 안 건드렸다(파일 셋 — page.tsx ·
#     release-notes.ts · release-notes.test.ts). 그래서 묶음 · db:migrate ·
#     db:preflight · 적용 직전 덤프 · 「지우는 문장」 잣대가 **한 줄도 없다**
#     (20 · 21 · 22번과 같다).
#     ⚠️ **배포 전 백업 검사만은 그대로 뒀다.** 17번에서 그것이 실제로 배포를
#        막아 사고를 피했다. DB 를 안 바꾸더라도 그 문은 안 닫는다.
#        🔴 **이번에 볼 것은 dss_auth 다**(21·22 는 dss_as, 23 은 dss_leave 였다).
#
#   ── 🔴 ④ compose — **한 줄만** 다르다 ─────────────────────────────
#     app-auth 의 image 한 줄. 볼륨도 포트도 환경변수도 그대로다. 그래서
#     되돌릴 때 사본을 쓰지 않아도 되지만, **사본을 쓰는 규율은 그대로 둔다**
#     (--go 가 backups/ 에 남긴다). 🔴 급할 때를 위해 sed 한 줄짜리 길도
#     --rollback 에 함께 찍는다 — 포털은 **빨리 되돌아가는 것**이 먼저다.
#
# ══ 🔴 22번에서 고친 것 둘을 **그대로 가져왔다** ═══════════════════════
#
#   ① 🔴 **큰따옴표 안에 백틱을 쓰지 않는다.** 명령 치환으로 읽혀
#      syntax error 가 난다. bash -n 은 치환 **안쪽**을 안 봐서 **못 잡는다.**
#      코드를 인용할 때는 작은따옴표나 「」 를 쓴다.
#      🔵 이 파일에는 백틱이 **하나도 없다**(짠 뒤 세어 확인했다).
#
#   ② 🔴 **읽기 전용 자리에 리다이렉션으로 빈 파일을 만들지 않는다.**
#      ash 는 리다이렉션 실패를 **치명적으로** 보고 셸을 그 자리에서 끝낸다 —
#      뒤의 echo 가 안 돌아 판정이 **빈 채로** 나왔다(2026-10-12 실제 사고).
#      🔴 **touch 를 쓴다** — 외부 명령이라 실패해도 셸이 산다.
#      🔵 이 판에서 그 자리는 /keys 하나다(읽기 전용이라 정확히 그 함정이다).
#
# ══ 🔴 돌리기 전에 — **값 셋을 채워야 한다** ═══════════════════════════
#
#   🔴 이 스크립트를 쓸 때 dss-auth:1.6 은 **아직 안 구워졌다.**
#      그래서 아래 세 상수가 **비어 있다**:
#        SZ_AUTH · MD5_AUTH · WANT_CFG_AUTH
#      비어 있는 동안 --check 는 그 자리를 ⚠️ 로만 말하고, 🔴 **--go 는 시작조차
#      하지 않는다.** 잰 적 없는 이미지를 운영에 올리지 않기 위해서다.
#
#   개발 PC(PowerShell)에서 굽고 재는 차례 — 폴더는
#   C:\Users\희만\Desktop\Development 다:
#
#     cd C:\Users\희만\Desktop\Development\dss-auth
#     git status --short                      ← **비어 있어야 한다**
#     docker build -t dss-auth:1.6 .
#     cd ..
#     docker save dss-auth:1.6 -o dss-auth-1.6.tar
#     (Get-Item dss-auth-1.6.tar).Length             ← SZ_AUTH
#     Get-FileHash -Algorithm MD5 dss-auth-1.6.tar   ← MD5_AUTH (소문자로 적는다)
#     tar -xOf dss-auth-1.6.tar manifest.json        ← "Config" 의 sha256 → WANT_CFG_AUTH
#
#   🔴 **tar 가 이미지의 1/4 쯤인 것은 정상이다**(2026-10-12 기억). 지난 판
#      tar 와 견준다 — dss-auth-1.4.tar.gz 가 개발 PC 에 남아 있다.
#      🔵 이번 판은 **화면 한 칸**만 늘었다 — 크기가 1.5 와 **거의 같은 것이
#         정상**이다. 크게 달라졌으면 그쪽을 먼저 의심한다.
#   🔴 **tar 안 Config 지문은 개발 PC 의 {{.Id}} 와 다르다.** 17번이 두 번 겪었다.
#      NAS 는 tar 안의 config 지문을 image ID 로 낸다 — **맞춰 볼 값은 tar 쪽**이다.
#   🔴 **git archive 로 뽑지 마라** — 작업 폴더에서 굽되 git status 가 비어야 한다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/24-deploy.sh            ← 읽기만 한다
#
#   🔴 NAS 의 docker 는 **sudo(root)** 가 필요하다. 이 스크립트는 root 가
#      아니면 첫 줄에서 멈춘다.
#
# ══ 🔴 개발 PC → NAS 로 올릴 것 **둘** ═════════════════════════════════
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#      아래는 **개발 PC 의 PowerShell** 에서 친다(NAS 가 아니다).
#
#     scp -O dss-auth-1.6.tar dss-nas:/volume1/dss/images/
#     scp -O docker-compose.nas.yml dss-nas:/volume1/dss/setup/incoming/
#
#   🔵 22번은 **셋**이었다 — 거기서 **tar 하나가 빠졌다**(이번엔 이미지가 하나다).
#   🔴 **마이그레이션 묶음도 도구 이미지도 올릴 것이 없다.**
#   🔴 두 번째 줄의 compose 는 **dss-deploy 저장소의 nas/docker-compose.nas.yml**
#      이다(app-auth 태그 **한 줄만** 올라간 그 파일).
#   🔵 scp 가 바로 안 되면 사용자 계정(swhur)의 홈으로 올린 뒤 NAS 에서
#      sudo mv 로 옮긴다. /volume1/dss 아래는 root 만 쓸 수 있다.
#
# ══ 🔴 DSM 터미널은 긴 명령을 잘라 먹는다 ══════════════════════════════
#
#   하루에 네 번 깨진 적이 있다. **NAS 에서 돌릴 것은 스크립트 파일로 올리고
#   md5 를 맞춘 뒤** 실행한다. 이 파일 자체가 그렇다:
#
#     (PowerShell)  scp -O nas\setup\24-deploy.sh dss-nas:/volume1/dss/setup/
#     (PowerShell)  Get-FileHash -Algorithm MD5 nas\setup\24-deploy.sh
#     (NAS)         md5sum /volume1/dss/setup/24-deploy.sh
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
#      🔴 **dss_auth 줄이 찍혀야 한다.** 다섯 개가 다 떠야 1-ㅅ 이 통과한다.
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#
#   11번부터 이어온 약속을 그대로 잇는다 — **인자 없이 돌리면 --check**.
#   실수로 그냥 돌려도 아무것도 바뀌지 않는다(🔵 로그 파일 **둘**만 남는다 —
#   돌아간 기록 하나와, DB 에 보낸 문장을 한 줄씩 적은 것 하나).
#   코드로는 아래 두 줄이 그 약속이다:
#     · MODE=check        (모드 절의 첫 줄)
#     · FORCE_LOAD=0      (같은 태그를 덮어쓰지 않는다)
#
#   🔴 정직하게 적어 둔다 — --check 도 이미지 **안을 보려고** 컨테이너를 잠깐
#      띄웠다 지우고(docker run --rm), 운영 DB 에 **select** 를 몇 번 보낸다.
#      디스크에도 DB 에도 아무것도 남기지 않는다. 「아무것도 안 한다」가 아니라
#      「아무것도 **바꾸지** 않는다」가 정확한 말이다.
#   🔴 **--check 가 DB 에 보내는 문장은 전부 select 다.** 믿으라고 하지 않고
#      **세어서 찍는다**(23번이 쓴 그 길) — 마지막에 「보낸 문장 N · select N ·
#      그 밖 0」이 나온다(sql_report). 🔵 이 판에는 db:migrate 도 pg_dump 도
#      **어느 모드에도 없다** — 마이그레이션이 0건이라서다.
#   🔵 --check 는 /keys 에 **쓰기 시험을 하지 않는다**. 읽기만 해 본다.
#
# ── 모드 다섯 ───────────────────────────────────────────────────────────
#   (없음) · --check     읽기만 한다. 아무것도 안 바꾸고 안 멈춘다      ← 기본값
#   --preload            새 이미지 하나를 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --go                 🔴 포털을 교체한다 (DB 는 안 바꾼다)
#   --rollback           되돌리기 안내
#
#   --force-load 는 --go 와 같이 써도 된다:  bash 24-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 24-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 24-deploy.sh --preload       (새 이미지를 미리 실어 둔다)
#   3) bash 24-deploy.sh                 (다시 읽기만 — 이번엔 안까지 다 본다)
#   4) bash 24-deploy.sh --go            (포털 교체. 그것뿐이다)
#
# ══ 🔴 「아직 안 온 것」을 ✗ 로 세지 않는다 (17 ~ 23번의 규칙) ═════════
#
#       **--check 가 ✗ 로 세는 것은 「있는데 어긋난 것」뿐이다.**
#       「아직 안 온 것 · 아직 안 실린 것」은 ⚠️ 로 안내만 한다.
#
# ══ 🔴 건드리지 않는 아홉 ══════════════════════════════════════════════
#
#     dss-as:2.5                dss-as-tools:1
#     dss-meters:1.3            dss-meters-tools:1
#     dss-improvements:0.3      dss-improvements-tools:2
#     dss-po:0.5                dss-leave:0.2
#     dss-leave-tools:2
#
#   🔴 **아홉이다**(22번은 여덟이었다 — 그때는 A/S 와 PO 가 「건드리는 쪽」
#      이었고 휴가는 아직 0.1 이었다. 23번이 휴가를 0.2 · 도구를 2 로 올렸다).
#   전부 지금 운영에 실려 있다(도구 넷은 실려만 있다 — profiles: [tools]).
#   compose 에서 이 태그가 흔들렸으면 **남의 변경이 섞인 것**이다 — 두 세션이
#   같은 저장소를 쓴다. 고치지 말고 **먼저 알린다.**
#
#   그리고 「안 멈췄다」를 말로 하지 않는다 — 교체 **전후로** 각 컨테이너의
#   시작 시각(.State.StartedAt)을 적어 두고 **그대로인지** 본다(5-ㅁ).
#   🔴 **이번에 세는 상자는 일곱이다**(22번은 여섯이었다 — 그때 멈춘 것이
#      둘이었기 때문이다. 이번엔 하나만 멈추므로 하나가 더 남는다):
#      dss-as · dss-meters · dss-improvements · dss-po · dss-leave ·
#      dss-pg-app · dss-pg-auth.
#
# ══ 🔴 화면의 「v1.5」는 **안 바뀐다** — 실측이다, 결함이 아니다 ═══════
#
#   업데이트 소식 머리말이 「지금 보고 계신 로그인 화면은 v1.5 입니다」라고
#   적는데, 이 판에서도 **그대로 v1.5 다.** 까닭:
#     · 그 글자는 APP_VERSION 이고, APP_VERSION 은 RELEASES 에서 「통합 로그인」
#       가장 최근 글의 version 을 집는다(src/lib/release-notes.ts 끝).
#     · 🔴 이번 커밋은 **소식 글을 하나도 더하지 않았다** — 도우미 칸을 일부러
#       RELEASES 밖에 뒀다(소식은 쌓이면서 밀려 내려가는데 이 칸은 상시여야
#       한다는 것이 그 커밋의 요지다). 시험이 그것을 못 박고 있다.
#     · package.json 의 version 도 1.5 그대로이고, 시험이 둘이 같아야 한다고
#       막고 있다.
#   🔴 그러므로 **1.6 은 「배포본 번호」**다 — 화면에서 v1.6 을 찾지 마세요.
#      「새 판인가」는 **도우미 칸이 있는가**로 본다(아래 1-ㅋ · 5-ㄷ).
#
# ══ 15 ~ 23번에서 그대로 이어받는 것 ═══════════════════════════════════
#
#   ① 같은 태그로 다시 구운 이미지는 조용히 안 실린다 → --force-load
#   ② 이미지는 태그가 아니라 **안을 본다**(1-ㅋ)
#   ③ 사람이 칠 명령은 **한 줄 76자 안쪽**(DSM 의 ash 가 긴 줄을 자른다)
#   ④ 'docker ps' 에 보이는 것과 앱이 **대답하는** 것은 다르다 → wait_http
#   ⑤ compose 는 바꾸기 **전에** 시험하고, 바꾼 것은 backups/ 에 남긴다
#   ⑥ 🔴 **auto 는 컨테이너 안에서 172.x 가 된다** — OIDC_ISSUER 를 읽어
#      판정한다(1-ㅈ). 틀리면 **여섯 사이트 전부 로그인이 깨진다.**
#   ⑦ 🔴 **겉이 아니라 결과를 봐라** — 통로가 200 이냐가 아니라 **무엇이
#      나오느냐**를 본다(jwks 에 키가 실려 있는가 · discovery 의 issuer 가
#      사내 도메인인가).
#   ⑧ 🔴 **만든 것과 도는 것은 다르다** — 새 칸이 들어 있는지를 이미지 안에서
#      한 번(1-ㅋ), **도는 컨테이너** 안에서 또 한 번(5-ㄷ) 본다.
#   ⑨ 🔴 **DB 에 보내는 문장은 전부 select 다** — 파일에 적어 센다(sql_report).
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
IMAGES=$D/images
BKD=$D/backups

# ── 🔴 이번에 올라가는 것 **하나** ─────────────────────────────────────
TAG_AUTH=dss-auth:1.6
OLD_AUTH=dss-auth:1.5

# ── 🔴 **건드리지 않는 아홉** (23번이 휴가 둘을 올린 뒤의 모습이다) ────
KEEP_AS=dss-as:2.5
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_METERSTOOLS=dss-meters-tools:1
KEEP_IMP=dss-improvements:0.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_PO=dss-po:0.5
KEEP_LEAVE=dss-leave:0.2
KEEP_LEAVETOOLS=dss-leave-tools:2

# ── tar 하나 ───────────────────────────────────────────────────────────
TAR_AUTH=$IMAGES/dss-auth-1.6.tar
# 🔴 **2026-10-12 밤에 구워 잰 값이다.** 개발 PC 의 Development\dss-auth-1.6.tar
#    에서 바로 쟀다(tar 안 manifest.json 의 Config — 개발 PC 의 image ID 가 아니다).
#    🔴 tar 를 다시 구우면 지문이 달라진다 — 그때는 셋을 다시 잰다.
SZ_AUTH=113596928
MD5_AUTH=dcd97afe52af343142465f37219256ca
WANT_CFG_AUTH=sha256:f229e9ccaa047ab12ba0089ab8af96f7234f2ffc8c5db4a9e6b0857aa650be1e
# ⚠️ manifest.json 은 그 값을 'blobs/sha256/4256829e…' 로 적는다 — 앞의 'blobs/' 를
#    떼고 'sha256:' 를 붙인 모양으로 적는다(17 ~ 23번도 같은 모양이었다).

# ── 포트 (compose 의 ports: 에서 읽어 확인했다 — 짐작이 아니다) ────────
#   포털 13100 · A/S 13000 · 계측기 13300 · 개선요청 13500 ·
#   PO 13600 · 휴가 13700
AUTH_PORT=13100

# ── DB — 🔴 **이번에 볼 것은 dss_auth 다** ─────────────────────────────
# 🔴 21·22 는 dss_as, 23 은 dss_leave 였다. **베낄 때 놓치기 쉬운 자리다.**
# 🔴 포털의 DB 는 다른 다섯과 **다른 상자**에 있다 — dss-pg-app 이 아니라
#    **dss-pg-auth** 다(compose 의 app-auth 블록 DATABASE_URL 이 그렇다).
#    인증 DB 는 등급이 달라 인스턴스를 나눠 둔 것이다(CLAUDE.md 의 그 결정).
# 🔵 이번 판은 DB 를 **바꾸지 않는다.** 마이그레이션도 덤프도 없다.
AUTH_DB=dss_auth
PG_AUTH=dss-pg-auth

# ── 🔴 서명 키 — **포털에 붙은 볼륨은 이것 하나뿐이다** ────────────────
# 🔴 이미지에 키를 넣지 않는다. 이미지는 파일로 복사되어 돌아다녀서, 한 번
#    들어가면 회수할 수 없다(compose 의 그 주석 · Dockerfile 의 그 주석).
# 🔴 키를 못 읽으면 앱이 뜨다가 죽거나, 떠도 **여섯 사이트 전부가 토큰을
#    거절한다.** 그래서 이 판에서 가장 깐깐히 보는 자리다.
KEYS_HOST=/volume1/dss/auth-keys
KEYS_MNT=/keys

# ══════════════════════════════════════════════════════════════════════
#  🔴 auth.env — **이번엔 한 글자도 적지 않는다. 「있는가」만 본다.**
#
#  🔴 값은 **절대 찍지 않는다.** 이 파일에는 카카오 비밀키와 쿠키 서명 키가
#     들어 있다. 「*_URL 같은 넓은 패턴이 DATABASE_URL 을 끌고 와 비밀번호가
#     찍힌 적이 있다(2026-09-14)」 — 이름만 보고, 값은 길이로만 말한다.
#  🔴 이 PC(dss-deploy)의 nas/env/*.env 를 NAS 로 **올리지 않는다. 절대로.**
#     그 사본은 낡아서 NAS 에만 있는 줄들이 없다.
# ══════════════════════════════════════════════════════════════════════
# 🔴 없으면 포털이 **아예 못 뜬다**(src/lib/config/env.ts 의 required 가 던진다).
AUTH_REQUIRED_KEYS="OIDC_ISSUER AUTH_TX_SECRET AUTH_ACTIVE_KID KAKAO_CLIENT_ID KAKAO_CLIENT_SECRET"
# 🔴 compose 가 넘기는 것들이다 — auth.env 에 또 있으면 어느 쪽이 이기는지
#    사람이 헷갈린다(22번이 as.env 에 같은 검사를 두었다).
AUTH_FORBIDDEN_KEYS="DATABASE_URL AUTH_KEYS_DIR PORT"

# ══════════════════════════════════════════════════════════════════════
#  이미지 **안에** 이번 판이 들어 있는가 — 🔴 **짝으로** 본다 (20·22번의 길)
#
#  🔴 이번 판은 바뀐 파일이 셋인데 그중 하나(release-notes.test.ts)는 시험
#     파일이라 이미지에 안 담긴다. 남는 둘은 **글자**가 전부다 — 새 모듈
#     경로가 생기지도 않았다. 그래서 22번처럼 **내용 짝**으로 가른다.
#  🔴 글자는 src/lib/release-notes.ts 의 FOLDER_HELPER_NOTICE 에서 **그대로**
#     가져왔다(짐작이 아니라 그 파일을 읽었다).
#  🔵 Next 는 이 화면을 빌드 때 미리 그려 둔다 — /app/.next 안에 번들 JS 와
#     **미리 그린 HTML** 양쪽에 같은 글자가 들어 있다. 둘 중 하나만 찾아도 된다.
# ══════════════════════════════════════════════════════════════════════
# 🔴 ① 접힌 채로도 보이는 한 줄(summary). 1.5 에는 **없다**.
NEW1='공유폴더를 탐색기로 바로 여는 설치 안내 — PC 마다 한 번'
# 🔴 ② 쓰는 분이 바로잡아 준 그 문장. 「건마다 다시 깔 일이 없다」는 말이다.
NEW2='건마다 다시 설치할 일은 없습니다'
# 🔴 ③ 단추 글자. 이 단추는 포털 제 화면(/apps)으로 간다.
NEW3='사내 시스템 열기'
# 🔴 ④ **있으면 안 되는 글자** — 고치기 **전** 커밋으로 구우면 이것이 들어간다.
#    (「새 폴더가 늘면 한 번 더 받아 주세요」가 사실이 아니어서 고쳤다.
#     도우미가 아는 것은 루트이고 그 아래는 전부 열린다.)
BAD1='새 폴더가 늘면'
# 대조 표시 — 1.5 에도 1.6 에도 있다. 이것이 안 나오면 **글자를 못 읽은 것**이다.
CTRL='업데이트 소식 | DSS 통합 로그인'

# ══════════════════════════════════════════════════════════════════════
#  🔴 **접힌 채로 뜨는가**를 글자로 본다
#
#  🔴 화면 코드는 <details> 에 open 을 주지 않았다(사용자 결정 2026-10-12:
#     「기본적으로는 접혀져 있도록」). 그 저장소의 시험이 open 이 다시 들어오는
#     것을 막고 있지만, **구워진 것**에서도 한 번 본다 — 「만든 것과 도는 것은
#     다르다」.
#  🔵 미리 그려 둔 HTML 에서 <details …> 태그를 통째로 꺼내 open 이 있나 본다.
#     🔴 **그 HTML 이 맞는 화면인지**를 먼저 가린다 — 위 NEW1 이 들어 있는
#        .html 파일에서만 꺼낸다(admin 화면들도 <details> 를 쓴다).
#  🔴 node 로 재는 까닭: sh 로 하려면 대괄호와 작은따옴표가 든 패턴을 넘겨야
#     하는데, 그 자리가 22번이 깨졌던 바로 그 모양이다. node 는 이미지에 반드시
#     있다(Dockerfile 의 CMD 가 node server.js 다).
#  🔴 글자는 **-e 로 넘긴다.** 본문에 끼워 넣으면 공백·대시가 든 글자에서 깨진다.
# ══════════════════════════════════════════════════════════════════════
NOTICE_PROBE_JS='
const fs = require("fs");
const path = require("path");
const marks = [process.env.N1, process.env.N2, process.env.N3, process.env.B1, process.env.C1];
const hits = [0, 0, 0, 0, 0];
let det = "";
let detWhere = "";
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
    if (det === "" && entry.name.slice(-5) === ".html" &&
        typeof marks[0] === "string" && text.indexOf(marks[0]) >= 0) {
      const j = text.indexOf("<details");
      if (j >= 0) {
        const k = text.indexOf(">", j);
        if (k > j) { det = text.slice(j, k + 1); detWhere = p; }
      }
    }
  }
}
console.log("MARKS " + hits.join(" "));
console.log("SEEN " + seen);
if (det === "") { console.log("DETAILS NONE"); }
else { console.log("DETAILS " + det); console.log("DETWHERE " + detWhere); }
'

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 둘. 인자가 없으면 이대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 24-deploy.sh                  읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 24-deploy.sh --check          위와 같습니다
  bash 24-deploy.sh --preload        새 이미지 하나를 싣고 지문만 맞춥니다
  bash 24-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 24-deploy.sh --go             🔴 포털 교체 — 그것뿐입니다
  bash 24-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 24-deploy.sh --rollback       되돌리기 안내

  🔴 --go 가 멈추는 것은 **dss-auth 하나**입니다.
     A/S · PO · 계측기 · 개선요청 · 휴가 · DB 둘은 그대로 돕니다.
  🔴 그러나 포털은 **로그인 문**입니다 — 멈춰 있는 동안은 아무도 **새로**
     로그인하지 못합니다(이미 들어가 있는 사람은 그대로 일합니다).
  🔵 --go 는 **DB 도 .env 도 볼륨도 안 바꿉니다** — 이번 판은 이미지 하나뿐입니다.
  🔵 **다시 로그인하지 않아도 됩니다** — 세션은 DB(dss_auth)에 있고 이 배포는
     그 DB 를 멈추지 않습니다. 까닭은 이 파일 머리말에 적어 두었습니다.
  🔴 그래도 **그날 백업이 없으면 시작하지 않습니다.** 야간 백업은 02:30 입니다.
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
LOG="$D/setup/logs/24-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11 ~ 23-deploy.sh 의 것 그대로 ────────────────────────────
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

# 🔴 값 셋이 채워졌는가 — 안 채워졌으면 --go 가 시작하지 않는다.
pinned() {
  [ -n "$SZ_AUTH" ] && [ -n "$MD5_AUTH" ] && [ -n "$WANT_CFG_AUTH" ]
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

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미 — 🔴 **보낸 문장을 한 줄씩 적어 둔다** (23번의 길)
#
#  🔴 「--check 는 select 만 보낸다」를 말로 하지 않는다. 이 둘을 지나는
#     문장을 **파일에 적고**, 끝에서 세어 찍는다. select 로 시작하지 않는
#     것이 하나라도 있으면 **그 문장을 그대로** 찍는다(sql_report).
#  🔴 **파일에 적는 까닭** — qauth 는 거의 언제나 $( ) 안에서 불린다. 거기는
#     아래 껍데기(subshell)라 변수로 세면 **그 수가 밖으로 안 나온다.**
#     파일은 껍데기를 넘어 남는다.
#  🔴 **상자가 다르다** — 포털 DB 는 dss-pg-app 이 아니라 **dss-pg-auth** 다.
#  🔵 이 판에는 db:migrate 도 pg_dump 도 **어느 모드에도 없다**(마이그레이션 0건).
#     그래서 아래 둘이 이 스크립트가 DB 에 말을 거는 **전부**다.
# ══════════════════════════════════════════════════════════════════════
SQLLOG="$D/setup/logs/24-sql-$MODE-$STAMP.txt"
touch "$SQLLOG" 2>/dev/null || true
SQL_N=0
SQL_SELECT_N=0
sql_note() { printf '%s\n' "$1" >> "$SQLLOG" 2>/dev/null || true; }
qauth()  { # 한 칸만 받는다
  sql_note "$1"
  "$DOCKER" exec "$PG_AUTH" sh -c "psql -U \"\$POSTGRES_USER\" -d $AUTH_DB -Atc \"$1\"" 2>/dev/null
}
qqauth() { # 표 꼴로 받는다
  sql_note "$1"
  "$DOCKER" exec "$PG_AUTH" sh -c "psql -U \"\$POSTGRES_USER\" -d $AUTH_DB -c   \"$1\"" 2>/dev/null
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
  say "        마이그레이션이 0건이라서다. DB 를 바꾸는 자리가 **하나도 없다.**"
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
#  🔴 **서명 키 볼륨이 아직 읽기 전용인가** — 쓰지 않고 **읽어서** 본다
#
#  🔵 /proc/mounts 는 커널이 적어 둔 것이라 거짓말하지 않고, --check 가
#     「아무것도 안 바꾼다」는 약속도 그대로 지켜진다.
#  🔵 --go 의 스모크에서는 교체 뒤에 touch 로 **한 번 더** 확인한다(5-ㄱ).
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
    say "    → compose 의 app-auth 쪽 volumes: 한 줄이 지워졌는지 보세요."
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

# ══════════════════════════════════════════════════════════════════════
#  🔴 /keys 를 **컨테이너 안에서 실제로 열어 본다**
#
#  🔴 주인(uid)과 모드만 보면 통과하는데 실제로는 EACCES 인 일이 있다
#     (Synology ACL). → 판정은 커널에게 맡긴다.
#  🔴 **무엇이 들어 있어야 하나** (dss-auth/src/lib/crypto/keys.ts 실측):
#     · <무엇>.public.json 이 **하나 이상** — 없으면 앱이 던지며 죽는다
#     · <AUTH_ACTIVE_KID>.private.json 하나 — 없으면 역시 죽는다
#     🔵 이름을 찍지 않는다. 개수만 센다(파일 이름이 kid 라 비밀은 아니지만,
#        키 자리 이야기는 좁게 적을수록 낫다).
#  🔴 쓰기 시험(touch)은 **--go 뒤 스모크에서만** 한다. --check 는 읽기만 한다.
# ══════════════════════════════════════════════════════════════════════
KEYS_PROBE_SH='id
if ls -1 /keys >/dev/null 2>&1; then r=READ_OK; else r=READ_FAIL; fi
npub=$(ls -1 /keys 2>/dev/null | grep -c "[.]public[.]json$")
npri=$(ls -1 /keys 2>/dev/null | grep -c "[.]private[.]json$")
echo "KEYS $r ${npub:-0} ${npri:-0}"'
# 🔴 **도는 컨테이너 안에서만** 본다. 임시 컨테이너를 띄워 보지 않는다 —
#    그 자리는 지금 **진짜로 붙어 돌고 있다**(22번이 발주서 볼륨을 그렇게 다뤘다).
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
#  🔴 OIDC_ISSUER 가 무엇인가 — **auto 는 컨테이너 안에서 172.x 가 된다**
#
#  🔴 2026-09-29 에 「통로가 있다(401 이 온다)」로 통과했는데 그 통로가 내준
#     링크가 http://172.20.0.7:3500/ 이었다. 문이 있는지가 아니라 **무엇이
#     나오는지**를 봐야 잡힌다. 포털에서 이것이 틀어지면 **여섯 사이트 전부**
#     로그인이 깨진다 — 다른 사이트의 알림 하나가 아니다.
#  🔴 값을 그대로 찍지 않는다 — 숫자를 N 으로 가려 꼴만 보여 준다.
# ══════════════════════════════════════════════════════════════════════
WANT_ISSUER=https://login.dss21.co.kr
href_shape() { # 1 주소
  printf '%s' "$1" | cut -c1-48 | sed 's/[0-9]/N/g'
}
judge_issuer() { # 1 라벨 2 원본값
  local label="$1" raw="$2" base host
  case "$raw" in
    auto|auto:*|AUTO|"")
      bad "$label · OIDC_ISSUER 가 auto(또는 빈 값)다 — 운영에서는 도메인을 적는다"
      say "      auto 는 이 기계의 랜 주소를 집는다. **컨테이너 안에서는 172.x 가 잡힌다.**"
      say "      🔴 그러면 여섯 사이트가 전부 **로그인 왕복에서 길을 잃는다.**"
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
    ok "$label · issuer 가 $WANT_ISSUER 다"
    return 0
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
    raw=$(sed -n 's/^OIDC_ISSUER=//p' "$envf" | head -1 | tr -d '\r')
    raw=${raw#\"}; raw=${raw%\"}
    raw=${raw#\'}; raw=${raw%\'}
    [ -n "$raw" ] && src="$(basename "$envf")"
  fi
  if [ -z "$raw" ]; then
    bad "$label · OIDC_ISSUER 를 찾지 못했다 — 포털이 뜨면서 던지고 죽는다"
    return 1
  fi
  say "    · $src 에서 읽었다"
  judge_issuer "$label" "$raw"
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 **로그인 길이 사는가** — 통로가 아니라 **나오는 것**을 본다
#
#  넷을 본다. 앞의 둘은 사람이 지나는 길, 뒤의 둘은 **다른 다섯 사이트가**
#  지나는 길이다. 🔴 **실제 계정으로 로그인하지 않는다**(사람이 한다).
#
#    /signin                               로그인 화면이 뜨는가
#    /                                     들어오면 /signin 으로 보내는가
#    /.well-known/openid-configuration     issuer 가 사내 도메인인가
#    /.well-known/jwks.json                🔴 **공개키가 실려 있는가**
#
#  🔴 jwks 는 「200 이냐」로는 모자라다 — 키가 0개라도 200 이 나온다. 그러면
#     로그인은 되는데 **각 시스템이 전부 토큰을 거절한다**(keys.ts 머리말의
#     그 상태다). 그래서 **안에 kid 와 kty 가 있는지**를 글자로 본다.
#  🔴 덤으로 **개인키가 새지 않았는지**도 본다 — 공개 JWK 에 "d" 가 있으면
#     서명 키가 밖으로 나간 것이다(toPublicJwk 가 막게 돼 있다).
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
login_door_check() { # 로그인 길 넷을 본다
  local body n
  login_path_check "로그인 화면" /signin 2
  login_path_check "들머리"      /        23
  # ── discovery — issuer 가 무엇으로 나오는가 (겉이 아니라 **결과**)
  body=$(curl -s -m 10 "http://127.0.0.1:$AUTH_PORT/.well-known/openid-configuration" 2>/dev/null)
  if [ -z "$body" ]; then
    bad "🔴 /.well-known/openid-configuration 이 **빈 대답**이다 — 다섯 사이트가 길을 잃는다"
  elif printf '%s' "$body" | grep -q "$WANT_ISSUER"; then
    ok "🔴 discovery 가 $WANT_ISSUER 를 내준다 (다섯 사이트가 보는 그 값이다)"
  else
    bad "🔴 discovery 의 issuer 가 $WANT_ISSUER 가 아니다"
    say "      꼴: $(href_shape "$body")"
    say "      🔴 auth.env 의 OIDC_ISSUER 가 auto 거나 옛 주소다."
  fi
  # ── jwks — 🔴 키가 **실려 있는가**. 200 만으로는 모자라다
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
}

# ══════════════════════════════════════════════════════════════════════
#  이미지 **안에** 이번 판이 들어 있는가 — 🔴 **짝으로** 본다
#
#  🔴 「아직 안 실린 것」은 ✗ 가 아니다. 못 봤다고 말하고 넘어간다.
#  🔴 대조 표시(CTRL)가 안 나오면 **판정하지 않는다** — 글자를 못 읽은 것과
#     옛 판인 것을 가를 수 없기 때문이다.
# ══════════════════════════════════════════════════════════════════════
# 🔴 **틀린 글자 하나로 ✗ 를 내지 않는다** — 실측에서 배운 것이다(2026-10-12).
#    개발용 빌드(.next/dev)에는 **주석이 그대로 담긴다.** release-notes.ts 의
#    머리말이 「새 폴더가 늘면…」을 **인용하고 있어서**, 주석이 안 걷힌 빌드에서는
#    고쳐진 판인데도 그 글자가 보인다. 그래서 **짝으로** 가린다:
#      · 고친 문구가 **있고** 틀린 글자가 없다  → ✓
#      · 고친 문구가 **없고** 틀린 글자가 있다  → ✗ (고치기 전 판이다)
#      · 둘 다 있다                              → ⚠️ (화면은 맞다. 주석이 남은 것)
#    🔵 더 센 검사는 5-ㄷ 이다 — **화면이 실제로 내보내는 글자**를 본다.
#       주석은 브라우저로 안 나가므로 거기서는 틀린 글자가 보이면 바로 ✗ 다.
pair_judge() { # 1 이름 2 요약줄있나 3 고친문구있나 4 틀린글자있나 5 새판 6 옛판
  local label="$1" n="${2:-0}" n2="${3:-0}" b="${4:-0}" nw="$5" od="$6"
  if [ "$n" != 1 ]; then
    bad "🔴 $label — 도우미 칸의 글자가 **하나도 없다**. 이것은 $od 다"
    say "      🔴 올려도 업데이트 소식 맨 위에 아무것도 안 생긴다."
    return 1
  fi
  if [ "$b" = 1 ] && [ "$n2" != 1 ]; then
    bad "🔴 $label — **고치기 전 글자만 들어 있다**(「$BAD1」). 틀린 커밋으로 구운 것이다"
    say "      🔴 올리면 쓰는 분이 「새 수리건마다 다시 깔아야 하나」로 읽는다."
    say "         dss-auth 를 c51ff52 로 맞추고 다시 구우세요."
    return 1
  fi
  if [ "$b" = 1 ]; then
    ok "$label — $nw 의 모습이다 (도우미 칸이 들어 있다)"
    say "    ⚠️ 🔴 「$BAD1」도 함께 보인다. 🔵 **고친 문구가 같이 있으므로 화면은 맞다** —"
    say "       압축기가 주석을 안 걷었을 때 그렇게 보인다(개발용 빌드가 섞인 경우다)."
    say "       🔴 그래도 5-ㄷ 의 **화면이 내보내는 글자**를 꼭 보세요."
    return 0
  fi
  ok "$label — $nw 의 모습이다 (도우미 칸이 있고 고치기 전 글자가 없다)"
  return 0
}
notice_check() { # 1 how(image|run) 2 태그또는컨테이너 3 라벨 4 옛판
  local how="$1" what="$2" label="$3" old="$4"
  local out marks n1 n2 n3 b1 c1 seen det where
  if [ "$how" = image ]; then
    if ! have_img "$what"; then
      notloaded "$what 가 아직 NAS 에 없어 **안을 못 봤다** — 먼저 실으세요"
      cmd "bash $0 --preload"
      return 0
    fi
    out=$("$DOCKER" run --rm \
          -e N1="$NEW1" -e N2="$NEW2" -e N3="$NEW3" -e B1="$BAD1" -e C1="$CTRL" \
          --entrypoint node "$what" -e "$NOTICE_PROBE_JS" 2>&1)
  else
    if ! running "$what"; then
      bad "$label · $what 가 안 돌고 있어 **안을 못 봤다**"
      return 1
    fi
    out=$("$DOCKER" exec \
          -e N1="$NEW1" -e N2="$NEW2" -e N3="$NEW3" -e B1="$BAD1" -e C1="$CTRL" \
          "$what" node -e "$NOTICE_PROBE_JS" 2>&1)
  fi
  marks=$(printf '%s\n' "$out" | sed -n 's/^MARKS //p' | head -1)
  seen=$(printf  '%s\n' "$out" | sed -n 's/^SEEN //p'  | head -1)
  if [ -z "$marks" ]; then
    say "    ⚠️ $label · node 가 대답하지 않았다. **판정하지 않는다** —"
    say "       아래가 그대로의 출력이다. 🔴 이때는 사람이 화면에서 봐야 한다."
    printf '%s\n' "$out" | sed 's/^/      /' | head -6
    return 0
  fi
  n1=$(printf '%s' "$marks" | awk '{print $1}')
  n2=$(printf '%s' "$marks" | awk '{print $2}')
  n3=$(printf '%s' "$marks" | awk '{print $3}')
  b1=$(printf '%s' "$marks" | awk '{print $4}')
  c1=$(printf '%s' "$marks" | awk '{print $5}')
  say "    · /app/.next 안 글자 파일 ${seen:-?}개를 읽었다"
  if [ "${c1:-0}" != 1 ]; then
    say "    ⚠️ $label · 대조 표시(「$CTRL」)가 안 나왔다. **판정하지 않는다** —"
    say "       안을 아예 못 읽은 것이다. 🔴 사람이 화면에서 봐야 한다."
    return 0
  fi
  ok "$label · 대조 표시를 찾았다 — 안을 실제로 읽었다는 뜻이다"
  pair_judge "$label · 폴더 열기 도우미 칸" "$n1" "$n2" "$b1" "$what" "$old"
  [ "${n2:-0}" = 1 ] && ok "$label · 고쳐진 문구가 들어 있다 (「$NEW2」)" \
    || bad "🔴 $label · 고쳐진 문구가 **없다** — 바로잡기 전 판일 수 있다"
  [ "${n3:-0}" = 1 ] && ok "$label · 단추 글자가 들어 있다 (「$NEW3」)" \
    || bad "🔴 $label · 단추 글자가 **없다** — 칸이 반만 들어갔다"
  # ── 🔵 접힘 — 미리 그린 HTML 에서 <details …> 를 꺼내 본다
  det=$(printf   '%s\n' "$out" | sed -n 's/^DETAILS //p'  | head -1)
  where=$(printf '%s\n' "$out" | sed -n 's/^DETWHERE //p' | head -1)
  if [ -z "$det" ] || [ "$det" = NONE ]; then
    say "    ⚠️ $label · 미리 그린 HTML 에서 접힘 상태를 못 봤다. **판정하지 않는다**"
    say "       (그 화면의 .html 을 못 찾았거나 details 가 거기 없다.)"
    return 0
  fi
  say "    · 미리 그린 HTML 의 그 태그: $det"
  [ -n "$where" ] && say "      (찾은 자리: $where)"
  case "$det" in
    *" open"*) bad "🔴 $label · <details> 에 **open 이 있다** — 처음부터 펴진 채로 뜬다" ;;
    *)         ok "🔴 $label · <details> 에 open 이 없다 — **접힌 채로 뜬다**" ;;
  esac
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  운영 DB 를 읽는다 — 🔴 **읽기만 한다. 전부 select 다.**
#
#  🔵 이번 판은 DB 를 한 글자도 안 바꾼다. 그래도 읽는 까닭은 둘이다:
#    ① 🔴 **세션이 끊기는지**를 숫자로 말하려고(교체 전후로 센다).
#    ② 🔴 도우미 칸의 단추가 /apps 로 가는데, 거기 타일 주소는 **DB 에서**
#       온다(clients.launcher_url). 그 줄이 비어 있으면 단추를 눌러도
#       A/S 로 못 간다 — 「권한은 코드가 아니라 운영 DB 가 정한다」와 같은 자다.
#  🔴 **주소는 찍지 않는다.** 있는가(true/false)만 본다.
# ══════════════════════════════════════════════════════════════════════
SESS_SQL="select count(*) from sso_sessions where revoked_at is null and expires_at > now()"
live_sessions() { qauth "$SESS_SQL"; }

db_check() {
  local reg n_all n_live n_cli n_launch
  if ! pg_auth_up; then
    say "  · $PG_AUTH 이 떠 있지 않다 — DB 를 못 봤다(✗ 는 아니다)"
    return 0
  fi
  reg=$(qauth "select to_regclass('public.sso_sessions')")
  if [ -z "$reg" ]; then
    say "  · $AUTH_DB 에 sso_sessions 표가 없다 — 🔴 첫 설치가 덜 된 DB 다"
    return 0
  fi
  ok "$AUTH_DB 에 sso_sessions 표가 있다"
  say "  🔴 이 검사가 돌리는 SQL 은 전부 select 다. 끝에 세어서 찍는다."
  say
  n_all=$(qauth "select count(*) from sso_sessions")
  n_live=$(live_sessions)
  say "  · sso_sessions 전체 줄: ${n_all:-?}"
  say "  · 🔴 **지금 살아 있는 세션**(안 끊겼고 안 만료): ${n_live:-?}"
  say "     🔵 이 숫자가 교체 뒤에도 **그대로면 아무도 로그아웃되지 않은 것**이다."
  say "        (12시간이 지난 세션은 저절로 빠지므로 1~2 줄어드는 것은 정상이다.)"
  reg=$(qauth "select to_regclass('public.clients')")
  if [ -z "$reg" ]; then
    say "  · clients 표가 없다 — 🔴 첫 설치가 덜 된 DB 다"
    return 0
  fi
  n_cli=$(qauth "select count(*) from clients where is_active = true")
  n_launch=$(qauth "select count(*) from clients where is_active = true and launcher_url is not null and launcher_url <> ''")
  say "  · 켜져 있는 시스템(clients): ${n_cli:-?}"
  say "  · 그중 타일 주소가 **적혀 있는 것**: ${n_launch:-?}  (🔴 주소 자체는 안 찍는다)"
  if [ "${n_launch:-0}" -ge 1 ] 2>/dev/null; then
    ok "🔴 /apps 에 눌러 갈 타일이 있다 — 도우미 칸의 단추가 길을 잃지 않는다"
  else
    bad "🔴 타일 주소가 적힌 시스템이 **하나도 없다** — 도우미 칸 단추를 눌러도 갈 데가 없다"
  fi
  say
  say "  켜져 있는 시스템 — 이름과 「주소가 적혀 있나」만 (🔴 주소는 안 찍는다):"
  qqauth "select name, (launcher_url is not null and launcher_url <> '') as has_tile from clients where is_active = true order by name" \
    | sed 's/^/      /'
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  auth.env 읽기 — 🔴 **읽기만 한다. 값은 절대 찍지 않는다.**
# ══════════════════════════════════════════════════════════════════════
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

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)
EXP_AUTH=""
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
  local tag s f db n_bk nlog h code FREE_KB FREE_H

  # ── 1-ㄱ. 올릴 파일 — 이미지 tar **하나**뿐 ─────────────────────────
  step "1-ㄱ. 올린 파일 (이미지 tar **하나** · compose 하나. 그것이 전부다)"
  say "  🔵 22번은 **셋**이었다 — tar 둘 · compose."
  say "     🔴 이번엔 **둘**이다. 이미지가 하나뿐이다."
  say "     🔴 **마이그레이션 묶음도 도구 이미지도 없다** — 포털에는 도구 서비스"
  say "        자체가 compose 에 **없다**(tools-auth 가 없다. 실측)."
  EXP_AUTH=$(tar_config_id "$TAR_AUTH" 2>/dev/null) || EXP_AUTH=""
  see_tar "$TAG_AUTH" "$TAR_AUTH" "$EXP_AUTH" "$SZ_AUTH" "$MD5_AUTH" "$WANT_CFG_AUTH" dss-auth-1.6.tar
  say "  🔵 이번 판은 **화면 한 칸**만 늘었다 — tar 크기가 1.5 와 거의 같은 것이 정상이다."

  # ── 1-ㄴ. NAS 에 실린 이미지 ─────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (올라가는 하나 · 🔴 건드리지 않는 **아홉**)"
  if have_img "$TAG_AUTH"; then
    [ -n "$EXP_AUTH" ] && { verify_img "$TAG_AUTH" "$EXP_AUTH" || force_load_hint "$TAG_AUTH"; }
  else
    notloaded "$TAG_AUTH 는 아직 NAS 에 실리지 않았다 — --preload 나 --go 가 싣는다"
  fi
  say "  🔴 지문이 어긋나면 **혼자 고쳐지지 않는다.** 태그가 같으면 docker load 를"
  say "     그냥 부르는 것으로는 안 바뀐다 — 위에 찍힌 --force-load 를 쓰세요."
  say "  🔴 건드리지 않는 아홉 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for tag in "$KEEP_AS" "$KEEP_ASTOOLS" "$KEEP_METERS" "$KEEP_METERSTOOLS" \
             "$KEEP_IMP" "$KEEP_IMPTOOLS" "$KEEP_PO" "$KEEP_LEAVE" "$KEEP_LEAVETOOLS"; do
    have_img "$tag" && ok "$tag 실려 있다 ($(img_id "$tag" | cut -c1-19)…)" \
      || bad "$tag 가 NAS 에 없다 — 🔴 앞 배포가 되돌아갔거나 누가 지웠다"
  done
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 **되돌아갈 옛 이미지**가 있는가 — 포털은 이것이 특히 중요하다 ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  if have_img "$OLD_AUTH"; then
    ok "🔴 $OLD_AUTH 가 아직 NAS 에 있다 — **되돌릴 길이 열려 있다**"
    say "     ($(img_id "$OLD_AUTH" | cut -c1-19)…)"
  else
    bad "🔴 $OLD_AUTH 가 NAS 에 **없다** — 되돌릴 이미지가 없다"
    say "     🔴 포털은 로그인 문이다. 되돌릴 길이 없는 채로 올리지 마세요."
    say "     → 개발 PC 에 dss-auth-1.5.tar 를 다시 구워 올리거나, 지금 도는"
    say "       컨테이너에서 이미지를 되찾은 뒤에 배포하세요:"
    cmd "$DOCKER ps --format '{{.Names}} {{.Image}}' | grep dss-auth"
  fi

  # ── 1-ㄷ. 🔴 운영 DB — 읽기만 한다 ───────────────────────────────────
  step "1-ㄷ. 운영 DB 를 읽는다 — 세션 · 타일 주소 (🔴 전부 select)"
  say "  🔴 포털 DB 는 다른 다섯과 **다른 상자**다 — $PG_AUTH 안의 $AUTH_DB."
  db_check

  # ── 1-ㄹ. 🔴 auth.env — **있는가만 본다** ────────────────────────────
  step "1-ㄹ. auth.env — 🔴 **있는가만 본다. 이번엔 한 글자도 안 적는다**"
  say "  🔵 21번은 여기서 일곱 줄을 덧붙였다. 🔴 **이번엔 없다** — 새 설정이"
  say "     하나도 없다. 덧붙이는 코드를 전부 걷어냈다."
  say "  🔴 **값은 절대 찍지 않는다** — 이 파일에는 카카오 비밀키와 쿠키 서명"
  say "     키가 들어 있다. 이름만 보고 지나간다."
  if [ -f "$AUTH_ENV" ]; then
    s=$(stat -c '%a' "$AUTH_ENV" 2>/dev/null)
    [ "$s" = 600 ] && ok "auth.env 있다 · 모드 600" \
      || bad "auth.env 의 모드가 ${s:-?} 다 (600 이어야 한다 — 남이 읽는다)"
    s=$(stat -c '%U:%G' "$AUTH_ENV" 2>/dev/null)
    [ "$s" = "root:root" ] || bad "auth.env 의 주인이 ${s:-?} 다 (root:root 이어야 한다)"
    say "  🔴 없으면 **포털이 아예 못 뜬다**(env.ts 의 required 가 던진다):"
    env_keys_present "$AUTH_ENV" "auth.env" "$AUTH_REQUIRED_KEYS" "포털이 시작하자마자 죽는다"
    say "  🔴 compose 가 넘기는 것들 — auth.env 에 또 있으면 안 된다:"
    for s in $AUTH_FORBIDDEN_KEYS; do
      if [ "$(env_count_of "$AUTH_ENV" "$s")" = 0 ]; then
        ok "auth.env 에 $s 가 없다 (맞다 — compose 가 넘긴다)"
      else
        bad "auth.env 에 $s 가 **있다** — 지우세요(compose 가 넘긴다)"
      fi
    done
  else
    bad "auth.env 가 없다: $AUTH_ENV"
    say "    → 없는 env_file 하나면 docker compose 명령이 **통째로** 안 먹는다."
  fi
  for f in as.env po.env meters.env improvements.env leave.env; do
    [ -f "$ENVD/$f" ] || bad "$f 가 없다: $ENVD/$f (compose 가 통째로 실패한다)"
  done

  # ── 1-ㅁ. compose ───────────────────────────────────────────────────
  step "1-ㅁ. compose ($CF_EFF)"
  say "  🔴 이번 판에서 compose 가 바뀌는 자리는 **하나뿐**이다:"
  say "     app-auth 의 image 한 줄 ($OLD_AUTH → $TAG_AUTH)"
  say "     🔵 22번에는 둘이었다(A/S · PO). 🔴 **이번엔 하나다.**"
  say "     다른 것이 흔들렸으면 남의 것이 섞인 것이다 — 고치지 말고 알리세요."
  if compose_at "$CF_EFF" config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_at "$CF_EFF" config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  SVCS=$(compose_at "$CF_EFF" config --services 2>/dev/null)
  for s in app-auth app-as tools-as app-meters tools-meters \
           app-improvements tools-improvements app-po app-leave tools-leave; do
    echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
      || bad "서비스 목록에 $s 가 없다 — 주석으로 꺼져 있다"
  done
  # 🔴 포털에는 도구 서비스가 **없다.** 생겼으면 남의 변경이다.
  if echo "$SVCS" | grep -qx tools-auth; then
    bad "🔴 tools-auth 서비스가 **생겼다** — 포털에는 도구가 없었다. 고치지 말고 알리세요"
  else
    ok "🔴 tools-auth 가 없다 (맞다 — 포털에는 도구 이미지가 아예 없다)"
  fi
  see_tag() { # 1 서비스 2 태그 3 사람이 읽을 이름
    svc_block "$CF_EFF" "$1" | grep -q "image: $2$" \
      && ok "$1 가 $2 를 가리킨다 ($3)" \
      || bad "$1 의 태그가 $2 가 아니다 ($3) — 지금 값: $(svc_image "$CF_EFF" "$1")"
  }
  say "  올라가는 하나:"
  see_tag app-auth "$TAG_AUTH" "포털"
  if [ "$(svc_image "$CF_EFF" app-auth)" = "$OLD_AUTH" ]; then
    say "    🔴 compose 가 아직 **옛 태그**를 가리킵니다. 개발 PC 에서 고친 파일을"
    say "       아래에 올리면 --go 가 시험하고 제자리로 옮깁니다:"
    say "         $INCOMING"
  fi
  say "  🔴 건드리지 않는 아홉 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-as              "$KEEP_AS"          "A/S · 그대로"
  see_tag tools-as            "$KEEP_ASTOOLS"     "A/S 도구 · 그대로"
  see_tag app-meters          "$KEEP_METERS"      "계측기 · 그대로"
  see_tag tools-meters        "$KEEP_METERSTOOLS" "계측기 도구 · 그대로"
  see_tag app-improvements    "$KEEP_IMP"         "개선요청 · 그대로"
  see_tag tools-improvements  "$KEEP_IMPTOOLS"    "개선요청 도구 · 그대로"
  see_tag app-po              "$KEEP_PO"          "PO/내자 · 그대로"
  see_tag app-leave           "$KEEP_LEAVE"       "휴가 · 그대로 (23번이 올린 것)"
  see_tag tools-leave         "$KEEP_LEAVETOOLS"  "휴가 도구 · 그대로 (23번이 올린 것)"
  # 🔴 포털에 붙은 볼륨은 **서명 키 하나뿐이다.** 사라지면 안 되고 늘어도 안 된다.
  say "  🔴 포털에 붙은 볼륨 — **하나뿐이어야 한다**(서명 키):"
  svc_block "$CF_EFF" app-auth | grep -q "$KEYS_HOST:$KEYS_MNT:ro" \
    && ok "app-auth 가 $KEYS_HOST 를 $KEYS_MNT 에 **읽기 전용**으로 붙인다" \
    || bad "🔴 app-auth 의 서명 키 볼륨이 어긋났다 — 포털이 뜨다가 죽거나 키가 바뀐다"
  say "  🔵 **공유폴더 볼륨은 이번엔 없다** — 포털에는 /quote-archive 도"
  say "     /contact-folder-archive 도 /repair-docs-archive 도 /purchase-order-archive"
  say "     도 /data 도 **한 줄도 없다**(실측). 그래서 22번의 공유폴더 검사와"
  say "     ACL 경고를 통째로 걷어냈다. 포털은 사내 서류함을 쳐다보지 않는다."
  for s in /quote-archive /contact-folder-archive /repair-docs-archive \
           /purchase-order-archive /customer-portal-archive; do
    svc_block "$CF_EFF" app-auth | grep -q "$s" \
      && bad "🔴 app-auth 에 $s 가 **생겼다** — 포털에는 없던 것이다. 고치지 말고 알리세요" \
      || ok "app-auth 에 $s 가 없다 (맞다)"
  done
  svc_block "$CF_EFF" app-auth | grep -q 'group_add' \
    && bad "🔴 app-auth 에 group_add 가 **생겼다** — 포털에는 없던 것이다" \
    || ok "app-auth 에 group_add 가 없다 (맞다 — 공유폴더를 안 쓴다)"
  svc_block "$CF_EFF" app-auth | grep -q "$AUTH_PORT:3100" \
    && ok "app-auth 가 127.0.0.1:$AUTH_PORT 으로 열린다" \
    || bad "app-auth 의 포트가 $AUTH_PORT:3100 이 아니다"
  svc_block "$CF_EFF" app-auth | grep -q 'db-auth' \
    && ok "app-auth 가 db-auth 를 본다 (DATABASE_URL · depends_on)" \
    || bad "🔴 app-auth 가 db-auth 를 안 본다 — 세션 표를 못 찾는다"
  # 🔴 사내 전용 원칙 — DB 에 ports: 를 더하지 않는다. 더해졌으면 남의 것이다.
  svc_block "$CF_EFF" db-app | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-app 에 ports: 가 생겼다 — 사내 전용 원칙을 깬다. 고치지 말고 알리세요" \
    || ok "db-app 에 ports: 가 없다 (DB 는 호스트 포트를 하나도 안 연다)"
  svc_block "$CF_EFF" db-auth | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-auth 에 ports: 가 생겼다 — 고치지 말고 알리세요" \
    || ok "db-auth 에 ports: 가 없다"

  # ── 1-ㅂ. 🔴 서명 키를 컨테이너 안에서 실제로 열어 본다 ──────────────
  step "1-ㅂ. 🔴 서명 키(/keys) — 주인·모드가 아니라 컨테이너 안에서 실제로 연다"
  say "  🔵 22번은 여기서 공유폴더 다섯을 봤다. 🔴 **이번엔 이 자리 하나다** —"
  say "     그 대신 깐깐히 본다. 키를 못 읽으면 화면은 떠도 **여섯 사이트가**"
  say "     **전부 토큰을 거절한다**(keys.ts 머리말의 그 상태다)."
  say "  🔵 --check 는 **쓰기 시험을 하지 않는다.** 읽기만 해 본다."
  if [ -d "$KEYS_HOST" ]; then
    ok "호스트에 $KEYS_HOST 가 있다"
  else
    bad "🔴 호스트에 $KEYS_HOST 가 **없다** — 포털이 뜨다가 죽는다"
  fi
  if running dss-auth; then
    say "  지금 도는 dss-auth 안에서 본 것:"
    keys_probe dss-auth
    ro_mount_check dss-auth "$KEYS_MNT" "서명 키"
  else
    bad "dss-auth 가 안 돌고 있어 /keys 를 못 열어 봤다"
  fi

  # ── 1-ㅅ. 🔴 야간 백업 · 야간 완전삭제 (읽기만 한다) ─────────────────
  step "1-ㅅ. 야간 백업 다섯 · 야간 완전삭제 (읽기만 한다)"
  say "  🔵 이번 판은 **DB 를 바꾸지 않는다**(마이그레이션 0건)."
  say "     🔴 그래도 --go 는 오늘 뜬 **$AUTH_DB** 백업이 없으면 **시작조차 않는다**(3-ㄱ)."
  say "     🔴 **$AUTH_DB 다** — 21·22 는 dss_as, 23 은 dss_leave 였다. 바뀌었다."
  say "  🔵 야간 백업은 **02:30** 이다 — 자정 넘어 배포하면 여기 걸린다."
  say "  최근 백업 일곱:"
  ls -lt "$BKD/db/" 2>/dev/null | head -7 | sed 's/^/      /'
  n_bk=0
  for db in dss_auth dss_meters dss_as dss_improvements dss_leave; do
    f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
      n_bk=$((n_bk + 1))
    else
      bad "오늘($TODAY) 뜬 $db 백업이 없다"
    fi
  done
  if [ "$n_bk" = 5 ]; then
    ok "🔴 오늘 백업이 **다섯**이다 — 야간 백업이 실제로 돌았다"
  else
    bad "🔴 오늘 백업이 ${n_bk}개뿐이다 (다섯이어야 한다)"
    say "    → 손으로 한 번 (종료 코드 0 이어야 한다):"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    say "    🔴 그중 **$AUTH_DB 가 없으면 --go 는 시작조차 하지 않는다.**"
  fi
  say
  say "  야간 완전삭제 — DSM 작업 「DSS Purge」의 로그:"
  nlog=$(ls -1t "$D/setup/logs"/purge-*.log 2>/dev/null | wc -l | tr -d ' ')
  if [ "${nlog:-0}" -gt 0 ]; then
    ok "완전삭제 로그가 ${nlog}개 있다 — 스케줄러에 등록돼 돌고 있다"
    ls -lt "$D/setup/logs"/purge-*.log 2>/dev/null | head -3 | sed 's/^/      /'
  else
    bad "🔴 완전삭제 로그가 **하나도 없다** — 스케줄러에 등록이 안 된 것이다"
    say "    → 🔴 이 스크립트는 등록하지 않는다. 사람이 DSM 화면에서 합니다:"
    say "      [제어판] → [작업 스케줄러] · 이름 「DSS Purge」 · root · 매일 03:00"
  fi

  # ── 1-ㅇ. 디스크 · DB · 지금 도는 것 ────────────────────────────────
  step "1-ㅇ. 디스크 · DB · 지금 도는 것"
  if running dss-pg-app && pg_auth_up; then
    ok "DB 둘 다 떠 있다 (이 배포에서 DB 컨테이너는 멈추지 않는다)"
  else
    bad "DB 가 떠 있지 않다"
  fi
  for s in dss-auth dss-as dss-meters dss-improvements dss-po dss-leave; do
    running "$s" && ok "$s 가 돌고 있다" || bad "$s 가 안 돌고 있다"
  done
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  # 새 tar 하나 + 실은 이미지 하나. 22번은 둘이라 3GB 를 봤다 — 이번은 절반이다.
  if [ "${FREE_KB:-0}" -ge 2000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (tar 하나 + 실은 이미지 하나가 들어가야 한다)"
  fi

  # ── 1-ㅈ. 🔴 issuer — auto 면 172.x 가 된다 ──────────────────────────
  step "1-ㅈ. 🔴 OIDC_ISSUER — 여섯 사이트가 모두 이 값을 따라 돈다"
  say "  🔴 틀어지면 **한 사이트의 알림 하나**가 아니라 **전원이 못 들어온다.**"
  issuer_check "포털" dss-auth "$AUTH_ENV"

  # ── 1-ㅋ. 새 이미지 **안에** 이번 판이 들어 있는가 ───────────────────
  step "1-ㅋ. 새 이미지 안을 본다 — 🔴 글자로 보고, 접힘까지 본다"
  say "  🔴 9/21~9/29 에 A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다."
  say "  🔵 이번 판은 **글자가 전부**다 — 새 모듈 경로도 새 통로도 없다."
  say "     그래서 22번처럼 **내용 짝**으로 가린다(새 글자가 있고 틀린 글자가 없다)."
  say "  🔴 화면의 **v1.5 는 그대로다** — 소식 글을 더하지 않았기 때문이다."
  say "     「새 판인가」는 **도우미 칸이 있는가**로 본다(머리말의 그 절)."
  if have_img "$TAG_AUTH"; then
    say "  $TAG_AUTH 구운 때: $("$DOCKER" images "$TAG_AUTH" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_AUTH" --format '{{.Size}}' 2>/dev/null)"
    notice_check image "$TAG_AUTH" "포털" "$OLD_AUTH"
  else
    notloaded "$TAG_AUTH 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
  fi
  say "  🔵 **OCR 검사는 이번엔 없다** — 포털에 public/ocr 이 없다(A/S 것이다)."

  # ── 1-ㅌ. 바깥 주소 여섯 · 🔴 로그인 길 넷 ──────────────────────────
  step "1-ㅌ. 바깥 주소 여섯 · 🔴 로그인 길 넷 (지금 상태를 적어 둔다)"
  say "  🔴 **포털이 죽으면 나머지 다섯도 못 들어간다.** 그래서 여섯을 다 본다."
  for h in login as meters improvements po leave; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$h.dss21.co.kr → $code" ;;
      *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
    esac
  done
  say "  🔴 로그인 길 넷 — **실제 계정으로 로그인하지는 않는다**(사람이 한다):"
  login_door_check
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
  local e MISS
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
  # 🔴 이번 판은 **image 한 줄**만 달라야 한다.
  say "  🔵 지금 것과 달라진 줄 — 🔴 **image 한 줄뿐이어야 한다**:"
  say "     (22번은 둘이었다. 볼륨 줄이나 다른 서비스가 보이면 남의 변경이"
  say "      섞인 것이다 — 고치지 말고 알리세요.)"
  diff "$CF" "$INCOMING" 2>/dev/null | sed 's/^/      /' | head -40
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
# 🔴 포털이라 이 절을 22번보다 **또렷하게** 적는다. 로그인 문이 닫히면 1분이
#    길다 — 읽고 고민하는 자리가 아니라 **그대로 칠 줄**이 있어야 한다.
if [ "$MODE" = rollback ]; then
  echo "DSS 스무째 배포 되돌리기 (포털) · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     되돌리는 것은 **이미지 하나**다:  $TAG_AUTH → $OLD_AUTH"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 **급할 때 — 이 다섯 줄이면 돌아간다** (각 줄 76자 안쪽)      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  cmd "cd /volume1/dss/deploy"
  cmd "sed -i 's/$TAG_AUTH/$OLD_AUTH/' docker-compose.nas.yml"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-auth"
  say "     🔵 바뀐 자리가 **그 한 줄뿐**이라 sed 로 내려도 안전하다."
  say "     🔴 다만 **먼저 아래 1번**으로 $OLD_AUTH 가 있는지 보세요 —"
  say "        없으면 이 다섯 줄은 「이미지를 못 찾는다」로 끝난다."
  say "     🔵 확인:"
  cmd "grep -n 'image: dss-auth' docker-compose.nas.yml"
  script_file_hint "24-rollback"
  say
  say "  🔵 되돌릴 것이 **이미지 하나뿐**입니다. 이번 판은 가장 가벼웠다."
  say "     · DB — 바꾼 적이 없다(마이그레이션 0건)"
  say "     · .env — 🔵 **이번엔 한 글자도 안 적었다**"
  say "     · 볼륨 — 🔵 **이번엔 안 더했다**(서명 키 하나는 그대로다)"
  say "     · 서명 키 — 🔵 **건드린 적이 없다.** 되돌려도 키는 그대로다"
  say
  say "  🔴 되돌리면 **업데이트 소식 맨 위의 「폴더 열기 도우미」 칸이 사라진다.**"
  say "     🔵 그뿐이다 — 로그인도 /apps 도 알림도 **아무것도 안 달라진다.**"
  say "     🔵 도우미 자체는 A/S 가 내주므로 **설치한 사람은 그대로 쓴다.**"
  say "     🔵 **세션도 안 끊긴다** — 되돌릴 때도 DB 는 멈추지 않는다."

  step "1. 🔴 옛 이미지가 아직 NAS 에 있는지 **먼저** 본다"
  if have_img "$OLD_AUTH"; then
    ok "$OLD_AUTH 있다 ($(img_id "$OLD_AUTH" | cut -c1-19)…) — 되돌릴 수 있다"
  else
    bad "🔴 $OLD_AUTH 가 **없다** — 위 다섯 줄로는 못 돌아간다"
    say "    → 개발 PC(PowerShell)에서 다시 굽고 올리세요:"
    cmd "docker build -t dss-auth:1.5 ."
    cmd "docker save dss-auth:1.5 -o dss-auth-1.5.tar"
    cmd "scp -O dss-auth-1.5.tar dss-nas:/volume1/dss/images/"
    say "    (NAS 에서:)"
    cmd "/usr/local/bin/docker load -i /volume1/dss/images/dss-auth-1.5.tar"
    say "    🔴 그 1.5 는 커밋 39b91b2(c51ff52 **바로 앞**)에서 구워야 같다."
  fi

  step "2. 🔵 사본으로 되돌리는 길 (급하지 않을 때는 이쪽이 정석이다)"
  say "  --go 가 옛 compose 를 아래에 남겼다 (가장 최근 것):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -3 | sed 's/^/      /'
  cmd "cd /volume1/dss/deploy"
  cmd "cp \$(ls -1t ../backups/docker-compose.nas.yml.* | head -1) ."
  say "      (파일 이름이 길면 위 한 줄 대신 두 줄로 나눠 치세요)"
  cmd "grep -n 'image: dss-auth' docker-compose.nas.yml"
  say "  그다음 위 「급할 때」의 뒤 세 줄(D1 · F · up)을 그대로 칩니다."
  say "  🔴 **인자 없는 up -d 를 부르지 않는다** — DB 컨테이너까지 다시 만든다."

  step "3. 🔴 되돌린 뒤 바로 볼 것 — 로그인 길이 사는가"
  say "  (아래는 되돌린 **뒤에** 이 스크립트를 --check 로 한 번 더 돌리면 다 본다.)"
  cmd "bash $0"
  say "  급하면 이 다섯만 (🔴 첫 줄이 나머지를 짧게 만든다):"
  cmd "U=http://127.0.0.1:$AUTH_PORT"
  cmd "curl -s -o /dev/null -w '%{http_code}\\n' -m 10 \$U/signin"
  cmd "curl -s -m 10 \$U/.well-known/jwks.json | head -c 80"
  cmd "curl -s -o /dev/null -w '%{http_code}\\n' -m 10 https://login.dss21.co.kr/"
  cmd "curl -s -o /dev/null -w '%{http_code}\\n' -m 10 https://as.dss21.co.kr/"

  step "4. 지금 상태"
  say "  dss-auth : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep '^dss-auth ' || echo '안 돌고 있다')"
  say "  (A/S · 계측기 · 개선요청 · PO · 휴가 · DB 둘은 이번에 건드리지 않았다.)"
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터 check · preload · force-load · go ═════════════════════════
echo "DSS 스무째 배포 · 2026-10-12 (오늘 **네 번째**) · $(date '+%F %T')"
echo "  🔴 올라가는 것은 **하나**:  $OLD_AUTH → $TAG_AUTH"
echo "  🔴 멈추는 것도 **하나**:  dss-auth  — 🔴 **그러나 그것이 로그인 문이다**"
echo "     포털이 안 뜨면 **여섯 사이트 어디에도 새로 못 들어간다.**"
echo "     🔵 이미 들어가 있는 사람은 그대로 일한다(세션이 DB 에 있다)."
echo "  🔴 이번 판은 **화면에 칸 하나를 더한 판**이다 — 업데이트 소식 맨 위에"
echo "     「폴더 열기 도우미」가 **접힌 채로 상시** 선다(자바스크립트 0줄)."
echo "     🔵 로그인 없이 열리는 공개 화면이라 사내 주소·IP 가 한 글자도 없다."
echo "  🔵 **마이그레이션 0건** · **새 볼륨 없음** · **.env 0줄** · **양식 없음**"
echo "     · **도구 이미지 없음**(포털엔 아예 없다) · **공유폴더 볼륨 없음**"
echo "     — 22번에서 그만큼 더 덜어낸 **가장 가벼운 판**이다."
echo "  🔴 화면의 **v 표기는 1.5 그대로**다 — 소식 글을 더하지 않았기 때문이다."
echo "     1.6 은 **배포본 번호**다. 화면에서 v1.6 을 찾지 마세요."
echo "  🔵 야간 백업은 **02:30** — 🔴 이번에 볼 것은 **$AUTH_DB** 다"
echo "  · 건드리지 않는 아홉 — $KEEP_AS · $KEEP_ASTOOLS · $KEEP_METERS"
echo "    · $KEEP_METERSTOOLS · $KEEP_IMP · $KEEP_IMPTOOLS"
echo "    · $KEEP_PO · $KEEP_LEAVE · $KEEP_LEAVETOOLS"
echo
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║ 🔴 **되돌리는 길** — 먼저 읽어 두세요. 포털은 빠른 것이 먼저다. ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo "      bash $0 --rollback        ← 다섯 줄을 찍어 줍니다"
echo "      🔵 되돌릴 것은 **이미지 하나**뿐입니다(DB 0 · .env 0 · 볼륨 0)."
if ! pinned; then
  echo "  ⚠️ 🔴 **이미지 기대값 셋이 비어 있습니다.**"
  echo "     개발 PC 에서 1.6 을 굽고 재어 채우기 전에는 --go 가 시작하지 않습니다."
  echo "     재는 차례는 이 파일 머리말 「돌리기 전에 — 값 셋을 채워야 한다」."
fi
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**"
              echo "     🔵 아직 안 온 것 · 안 실린 것은 ⚠️ 로만 말한다(✗ 가 아니다)."
              echo "     🔵 DB 에 보내는 문장은 **전부 select** 다 — 끝에 세어서 찍는다." ;;
  preload)    echo "  🔵 --preload — 새 이미지 하나를 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — 포털을 교체한다. **DB 도 .env 도 볼륨도 안 바꾼다.**"
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(백업 · 키)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "새 이미지 tar · 지문"
  EXP_AUTH=$(tar_config_id "$TAR_AUTH" 2>/dev/null) || EXP_AUTH=""
  see_tar "$TAG_AUTH" "$TAR_AUTH" "$EXP_AUTH" "$SZ_AUTH" "$MD5_AUTH" "$WANT_CFG_AUTH" dss-auth-1.6.tar
  if [ -s "$TAR_AUTH" ] && [ -n "$EXP_AUTH" ]; then
    bring_img "$TAG_AUTH" "$TAR_AUTH" "$EXP_AUTH"
  else
    bad "$TAG_AUTH 를 싣지 않았다 — tar 가 없거나 manifest.json 을 못 읽었다"
  fi

  # 🔴 실어 놓고 **안을 본다.**
  step "새 이미지 안에 이번 판이 들어 있는가 (글자 · 접힘)"
  if have_img "$TAG_AUTH"; then
    notice_check image "$TAG_AUTH" "포털" "$OLD_AUTH"
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
step "1. 점검표를 기계로 옮긴 것 (앱은 살아 있다 · DB 는 손도 안 댄다)"
compose_incoming || stop "compose 를 바꾸지 않았습니다. 포털은 그대로 돕니다."
run_checks
sql_report

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  🔵 DB 에 보낸 문장 $SQL_N 개 · select $SQL_SELECT_N 개 · 그 밖 $((SQL_N - SQL_SELECT_N))개"
  if [ "$FAIL" = 0 ]; then
    if pinned; then
      echo "  ✅ 이어서 (🔴 포털이 잠깐 멈춥니다 — 그동안 아무도 **새로** 못 들어옵니다):"
      echo "       bash $0 --go"
      echo "     🔴 --go 는 오늘 백업($AUTH_DB)이 없으면 **시작하자마자 멈춥니다.**"
      echo "     🔵 야간 백업은 02:30 입니다 — 먼저 손으로 뜨려면:"
      echo "          bash /volume1/dss/jobs/backup-nightly.sh"
      echo "     🔵 **이미 로그인한 사람은 다시 로그인하지 않아도 됩니다.**"
    else
      echo "  🔴 아직 --go 를 부를 수 없습니다 — 이미지 기대값 셋이 비어 있습니다."
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
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 바꾸지 않았고 포털은 살아 있습니다.**"
pinned || {
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 이미지 기대값 셋이 **비어 있습니다.** 재지 않은 이미지를      ║"
  say "  ║    운영에 올리지 않습니다. 🔴 더구나 이것은 로그인 문입니다.     ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  stop "아무것도 바꾸지 않았습니다. 포털도 DB 도 그대로입니다."
}

# ── 2. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ───────────
step "2. 새 이미지 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
[ -n "$EXP_AUTH" ] || stop "tar 에서 지문을 못 읽었습니다. **아무것도 바꾸지 않았습니다.**"
bring_img "$TAG_AUTH" "$TAR_AUTH" "$EXP_AUTH" || {
  say "  🔴 포털 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
}

# ══ 3. 🔴 멈추기 전에 — 백업 · 사본 · 세션 수 · 시작 시각 ══════════════
#
# 🔴 여기까지가 「돌이킬 수 있는 자리」다. 포털은 아직 옛 판으로 **살아 있다.**
# 🔵 22번에 있던 **첨부 하드링크 스냅숏**은 **이번엔 없다** — 포털에는 /data 가
#    없다(붙은 볼륨이 서명 키 하나뿐이다).
# 🔴 **서명 키의 사본도 만들지 않는다.** 그것은 개인키다 — 사본이 늘수록
#    회수할 자리가 는다. 키는 우리가 **건드리지 않으므로** 사본이 필요 없다.

# ── 3-ㄱ. 🔴 오늘 백업을 **지금 다시** 찾는다. 없으면 멈춘다 ───────────
step "3-ㄱ. 🔴 오늘 $AUTH_DB 백업을 **지금 다시** 찾는다 (없으면 여기서 멈춘다)"
say "  🔴 **$AUTH_DB 다** — 21·22 는 dss_as, 23 은 dss_leave 였다. 자리가 바뀌었다."
BK_TODAY=$(ls -1t "$BKD/db/${AUTH_DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
if [ -n "$BK_TODAY" ] && [ -s "$BK_TODAY" ]; then
  ok "오늘 백업 — $(basename "$BK_TODAY") ($(du -h "$BK_TODAY" | cut -f1))"
else
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 오늘($TODAY) 뜬 $AUTH_DB 백업을 **지금 찾지 못했습니다.**   ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     🔵 이번 판은 DB 를 바꾸지 않습니다. 그래도 **백업 없이 운영 이미지를"
  say "        갈아 끼우지 않습니다** — 17번에서 이 문이 사고를 막았습니다."
  say "     🔴 더구나 이 DB 에는 **세션과 사용자**가 들어 있습니다."
  cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  say "     ✓ $AUTH_DB 줄이 찍혀야 합니다. 그 뒤에 다시:"
  cmd "bash $0 --go"
  stop "백업 없이 교체하지 않습니다. **포털도 DB 도 그대로입니다.**"
fi

# ── 3-ㄴ. auth.env 사본 (🔴 고치지는 않는다) ───────────────────────────
step "3-ㄴ. auth.env 사본 (🔵 DB 덤프도 첨부 스냅숏도 이번엔 없다)"
BK=$BKD/predeploy-$STAMP
mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
if [ -f "$AUTH_ENV" ]; then
  cp -p "$AUTH_ENV" "$BKD/auth.env.$STAMP"; chmod 600 "$BKD/auth.env.$STAMP"
  ok "auth.env 사본 — backups/auth.env.$STAMP (root 600 · 🔵 **고치지는 않는다**)"
else
  bad "auth.env 가 없다: $AUTH_ENV"
  stop "설정 파일이 없습니다. **포털도 DB 도 그대로입니다.**"
fi
say "  🔵 **DB 덤프는 뜨지 않는다** — 이번 판은 DB 를 바꾸지 않는다(마이그레이션 0건)."
say "     오늘 야간 백업이 이미 $AUTH_DB 를 떠 두었다(3-ㄱ 에서 확인했다)."
say "  🔵 **첨부 스냅숏도 없다** — 포털에는 /data 가 없다."
say "  🔴 **서명 키 사본도 만들지 않는다** — 개인키다. 우리가 건드리지 않으므로"
say "     사본이 필요 없고, 사본이 늘수록 회수할 자리만 는다."

# ── 3-ㄷ. 🔴 살아 있는 세션 수를 적어 둔다 ─────────────────────────────
step "3-ㄷ. 🔴 지금 **로그인해 있는 사람 수**를 적어 둔다 (뒤에서 대조한다)"
say "  🔵 이것이 「세션이 끊기는가」에 대한 **숫자로 된 답**이다."
SESS_BEFORE=$(live_sessions)
say "  · 살아 있는 세션: ${SESS_BEFORE:-?}  (안 끊겼고 안 만료된 것)"
say "  🔴 교체 뒤 5-ㄹ 에서 **다시 센다.** 그대로면 아무도 로그아웃되지 않은 것이다."

# ── 3-ㄹ. 건드리지 않는 쪽의 **시작 시각**을 적어 둔다 ─────────────────
step "3-ㄹ. 건드리지 않는 쪽의 시작 시각을 적어 둔다 (뒤에서 대조한다)"
say "  🔴 **일곱이다**(22번은 여섯이었다 — 그때는 둘을 멈췄다)."
KEEP_BOXES="dss-as dss-meters dss-improvements dss-po dss-leave dss-pg-app dss-pg-auth"
STARTED_BEFORE=""
for t in $KEEP_BOXES; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  STARTED_BEFORE="$STARTED_BEFORE$t=$s
"
  say "  · $t  시작 ${s:-?}"
done
say
say "  🔴 이제 **포털**을 바꿔 끼웁니다. 그만두려면 **20초 안에 Ctrl+C**."
say "     지금 Ctrl+C 하면 직원은 $OLD_AUTH 를 그대로 쓰고 있습니다."
say "     (compose 는 이미 바뀌었지만 그것만으로는 아무 일도 일어나지 않습니다 —"
say "      옛 컨테이너가 그대로 돌고 있습니다.)"
say "  🔴 되돌리는 길:  bash $0 --rollback"
sleep 20

# ══ 4. 포털을 새 판으로 바꿔 끼운다 — 🔴 여기 하나가 정지 창이다 ═══════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다. --no-deps 로 **이름을 적은 하나만** 부른다.
# 🔴 app-auth 에는 depends_on: db-auth(service_healthy) 가 있다. --no-deps 가
#    그것을 건너뛴다 — 🔵 그래서 **세션 DB 가 멈추지 않는다**(세션이 사는 까닭).
step "4. 새 이미지로 바꿔 끼운다 (포털)  ⏱ 여기부터 정지 창"
say "  🔴 **멈추는 것은 dss-auth 하나뿐이다.**"
say "     그대로 도는 것: A/S · 계측기 · 개선요청 · PO · 휴가 · DB 둘."
say "  🔴 그러나 이 하나가 **로그인 문**이다 — 이 몇 초 동안은 아무도 **새로**"
say "     들어오지 못한다. 🔵 이미 들어가 있는 사람은 그대로 일한다."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"
"${COMPOSE[@]}" up -d --no-deps app-auth 2>&1 | sed 's/^/    /'
wait_http "포털" "$AUTH_PORT" /signin dss-auth
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 5. 스모크 ══════════════════════════════════════════════════════════
step "5. 스모크 — 키 · 🔴 **로그인 길** · 새 칸 · 🔴 **세션** · 안 멈췄는가 · 주소"

# 5-ㄱ. 🔴 서명 키를 새 컨테이너 안에서 실제로 열어 본다
say "  5-ㄱ. 🔴 서명 키(/keys)를 **새 컨테이너** 안에서 연다"
say "     (「만든 것과 도는 것은 다르다」. 1-ㅂ 은 옛 컨테이너였다.)"
if running dss-auth; then
  keys_probe dss-auth
  ro_mount_check dss-auth "$KEYS_MNT" "서명 키"
  # 🔴 **touch 를 쓴다.** 리다이렉션은 읽기 전용 자리에서 셸을 죽인다(머리말 ②).
  if "$DOCKER" exec dss-auth sh -c "t=$KEYS_MNT/.dss-ro-test; touch \"\$t\"" >/dev/null 2>&1; then
    bad "🔴 $KEYS_MNT 에 **쓸 수 있다** — :ro 가 안 먹었다"
    "$DOCKER" exec dss-auth sh -c "rm -f $KEYS_MNT/.dss-ro-test" >/dev/null 2>&1
    say "    🔵 시험 파일은 곧바로 지웠다 — 남아 있으면 알려 주세요."
  else
    ok "🔴 $KEYS_MNT 는 **쓰기가 막혀 있다** (읽기 전용 그대로다)"
  fi
else
  bad "dss-auth 컨테이너가 떠 있지 않다"
fi

# 5-ㄴ. 🔴 **이 배포의 핵심 하나** — 로그인 길이 사는가
say "  5-ㄴ. 🔴 **로그인 길이 사는가** — 통로가 아니라 **나오는 것**을 본다"
say "     🔵 실제 계정으로 로그인하지는 않는다. **그것은 사람이 한다.**"
login_door_check
issuer_check "포털" dss-auth "$AUTH_ENV"

# 5-ㄷ. 🔴 새 칸이 **도는 컨테이너** 안에 있는가
say "  5-ㄷ. 🔴 도우미 칸이 **도는 컨테이너** 안에 있는가 (글자 · 접힘)"
say "     (위 1-ㅋ 는 이미지를 봤고 여기는 **도는 것**이다.)"
notice_check run dss-auth "포털" "$OLD_AUTH"
# 🔴 화면이 실제로 그 글자를 내보내는가 — 미리 그린 것이 아니라 **대답**을 본다.
say "     🔴 그리고 화면이 실제로 그 글자를 **내보내는지** 본다:"
NOTICE_BODY=$(curl -s -m 10 "http://127.0.0.1:$AUTH_PORT/release-notes" 2>/dev/null)
if [ -z "$NOTICE_BODY" ]; then
  bad "🔴 /release-notes 가 **빈 대답**이다"
else
  printf '%s' "$NOTICE_BODY" | grep -qF "$NEW1" \
    && ok "🔴 /release-notes 가 접힌 한 줄을 **실제로 내보낸다**" \
    || bad "🔴 /release-notes 에 그 한 줄이 **없다** — 옛 판이 돌고 있다"
  printf '%s' "$NOTICE_BODY" | grep -qF "$NEW3" \
    && ok "/release-notes 가 단추 글자를 내보낸다 (「$NEW3」)" \
    || bad "🔴 /release-notes 에 단추 글자가 없다"
  printf '%s' "$NOTICE_BODY" | grep -qF "$BAD1" \
    && bad "🔴 /release-notes 에 **고치기 전 글자**가 보인다 (「$BAD1」)" \
    || ok "/release-notes 에 고치기 전 글자가 없다 (맞다)"
  # 🔴 이 화면은 **로그인 없이** 열려야 한다 — 그 약속도 함께 본다.
  printf '%s' "$NOTICE_BODY" | grep -qF "업데이트 소식" \
    && ok "🔴 /release-notes 가 **로그인 없이** 열린다 (쿠키 없이 부른 대답이다)" \
    || bad "🔴 /release-notes 가 로그인 없이 안 열린다 — 공개 화면이어야 한다"
fi

# 5-ㄹ. 🔴 **세션이 끊겼는가** — 숫자로 다시 센다
say "  5-ㄹ. 🔴 **세션이 끊겼는가** — 바꾸기 전 숫자와 견준다"
SESS_AFTER=$(live_sessions)
say "     · 바꾸기 전: ${SESS_BEFORE:-?}   바꾼 뒤: ${SESS_AFTER:-?}"
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

# 5-ㅁ. 🔴 건드리지 않는 쪽이 **정말 안 멈췄는가**
say "  5-ㅁ. 🔴 건드리지 않는 **일곱**이 안 멈췄는가 (시작 시각을 대조한다)"
for t in $KEEP_BOXES; do
  before=$(printf '%s\n' "$STARTED_BEFORE" | sed -n "s/^$t=//p" | head -1)
  after=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  if [ -n "$before" ] && [ "$before" = "$after" ]; then
    ok "$t · 시작 시각 그대로 — **한 번도 안 멈췄다**"
  else
    bad "🔴 $t 의 시작 시각이 바뀌었다 ($before → $after) — 이 배포가 건드렸다"
  fi
done

# 5-ㅂ. 🔴 바깥 주소 여섯 — 포털이 죽으면 나머지 다섯도 못 들어간다
say "  5-ㅂ. 🔴 바깥 주소 **여섯이 전부 사는가**"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://login.dss21.co.kr/" 2>/dev/null)
case "$code" in
  2??|3??) ok "https://login.dss21.co.kr → $code (바뀐 쪽 · 🔴 로그인 문이 열려 있다)" ;;
  *)       bad "🔴🔴 https://login.dss21.co.kr → ${code:-없음} — **로그인 문이 닫혔다**"
           say "      🔴 지금 아무도 어느 사이트에도 새로 못 들어옵니다."
           say "      🔴 바로 되돌리세요:"
           cmd "bash $0 --rollback" ;;
esac
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
echo "  🔵 바꾼 것은 **이미지 하나뿐**입니다 — DB 0 · .env 0줄 · 볼륨 0 · 양식 0벌"
echo "  🔵 DB 에 보낸 문장 $SQL_N 개 · select $SQL_SELECT_N 개 · 그 밖 $((SQL_N - SQL_SELECT_N))개"
echo "  🔵 살아 있는 세션 ${SESS_BEFORE:-?} → ${SESS_AFTER:-?}"
echo "  .env 사본: $BKD/auth.env.$STAMP (고치지는 않았습니다)"
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

  포털의 세션은 **DB 에 있습니다**(표 sso_sessions · DB $AUTH_DB ·
  컨테이너 $PG_AUTH). 🔴 **이 배포는 그 DB 를 멈추지 않습니다** — up 을
  --no-deps 로 부르고 이름을 적은 것은 app-auth 하나뿐입니다. 그래서
  브라우저에 있던 쿠키가 그대로 통합니다.
  🔵 서명 키도 그대로입니다 — 이미지가 아니라 호스트 폴더($KEYS_HOST)에
  있습니다. 이미 나간 로그인 토큰도 계속 검증됩니다.
  🔵 위 5-ㄹ 이 **숫자로** 확인했습니다: ${SESS_BEFORE:-?} → ${SESS_AFTER:-?}.
  🔴 다만 바꿔 끼우던 **약 ${DOWN}초** 동안 마침 로그인 단추를 누른 분은
  한 번 더 누르시면 됩니다.

╔════════════════════════════════════════════════════════════════════╗
║ 🔴 **화면의 「v1.5」는 그대로입니다. 결함이 아닙니다.**                  ║
╚════════════════════════════════════════════════════════════════════╝

  이번 커밋은 소식 글을 하나도 더하지 않았습니다(도우미 칸을 일부러 소식
  목록 **밖**에 두었습니다 — 소식은 쌓이면서 밀려 내려가는데 이 칸은 늘
  거기 있어야 하니까요). 화면의 v 표기는 가장 최근 **소식 글**의 번호라
  1.5 그대로입니다. 🔴 **1.6 은 배포본 번호**입니다.
  「새 판인가」는 **도우미 칸이 있는가**로 보세요.

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. 🔴 **로그인이 되는지 먼저.** https://login.dss21.co.kr 에서 평소대로
      들어가 보세요. 🔵 **이미 열려 있던 창은 그대로일 것입니다** — 그래도
      한 번은 **새로** 들어가 보셔야 합니다(스크립트는 길이 열렸는지만 봤고
      실제 계정으로는 들어가 보지 않았습니다).

   2. 🔴 **https://login.dss21.co.kr/release-notes** 맨 위에 「폴더 열기
      도우미」 칸이 보입니까.
      · 🔴 **접힌 채**로 떠야 합니다(제목 옆에 한 줄 설명만 보입니다).
      · 눌러서 펴면 네 문단과 [사내 시스템 열기] 단추가 나옵니다.
      · 🔴 그 단추를 누르면 **시스템 목록(/apps)** 으로 가야 합니다.
      · 🔵 **로그아웃한 채로도** 이 화면이 열려야 합니다(공개 화면입니다).
        그 상태에서 단추를 누르면 로그인 화면으로 갑니다 — 그것이 맞습니다.

   3. 🔵 나머지 다섯이 그대로입니까 — A/S · 계측기 · 개선요청 · PO · 휴가.
      (스크립트가 5-ㅁ 에서 시작 시각으로, 5-ㅂ 에서 주소로 이미 확인했습니다.)

🔴 사람이 이어서 할 일:
  · 🔵 **도우미를 다시 깔 일은 없습니다.** 이번 판은 도우미를 한 글자도
    안 바꿨습니다 — A/S 가 내주는 그 명령 그대로입니다.
  · 내일 아침 백업을 한 번 더 보세요 — 다섯이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -7
  · auth.env 사본($BKD/auth.env.$STAMP)은 한 주쯤 두었다 지우세요.
    🔴 그 안에 비밀값이 있습니다 — 다른 데로 옮기지 마세요.

되돌리기 안내:  bash $0 --rollback
  🔵 되돌릴 것은 **이미지 하나뿐**입니다 — DB 도 .env 도 볼륨도 안 바꿨습니다.
  🔴 되돌리면 **도우미 칸이 사라집니다.** 🔵 그뿐입니다 — 로그인도 /apps 도
     알림도 아무것도 안 달라지고, **세션도 안 끊깁니다.**
ANNOUNCE
exit "$FAIL"
