#!/bin/bash
# /volume1/dss/setup/22-deploy.sh — 2026-10-12 열여덟째 배포
#
# ── 🔴 오늘 **두 번째** 배포다 ─────────────────────────────────────────
#
#   몇 시간 전 열일곱째 배포(21-deploy.sh)로 2.4 · 0.4 가 나갔다. 그 판에
#   **운영에서 드러난 결함 하나**가 있어 그것만 고쳐 다시 올린다.
#
#     A/S  dss-as:2.4  →  **dss-as:2.5**   (커밋 1개 · 74f3f0e)
#     PO   dss-po:0.4  →  **dss-po:0.5**   (커밋 1개 · 3119df1)
#
#   나머지 넷(포털 1.5 · 계측기 1.3 · 개선요청 0.3 · 휴가 0.1)은
#   **건드리지 않는다. 멈추지도 않는다.**
#
# ══ 🔴 무엇이 틀렸나 — 정규식 한 줄 ════════════════════════════════════
#
#   견적서 번호를 파일 이름에서 뽑는 정규식이 **가지(-1) 와 개정(R1) 중
#   하나만** 받고 있었다. 그래서 둘 다 붙은 번호를 **통째로 못 읽었다**:
#
#       DSS 2026-095-1R1 … .xls   →  (null)      ← 번호 없는 파일로 떨어졌다
#
#   고친 자리는 src/lib/domain/quote-archive-file-number.ts 의 한 줄이다
#   (A/S 와 PO 가 **글자까지 같은 모듈**을 들고 있어 양쪽을 같이 고쳤다):
#
#       (?:-\d+|R\d+)?        ← 옛 규칙. 하나만 받는다
#       (?:-\d+)?(?:R\d+)?    ← 새 규칙. 가지 뒤에 개정이 올 수 있다
#
#   지금 운영에서 나는 증상 — 🔴 **그 번호를 쓰는 건에서만** 난다:
#     · [고객 안내 현황] · [주간보고] 에 **옛 번호**가 뜬다(-1R1 이 안 뜬다)
#     · 🔴 [Excel 보기] 가 「저장된 파일이 없습니다」 — 분명히 있는데 못 연다
#     · 🔴 결재 탭 공유폴더에 그 장의 파일이 **하나도 안 보인다**
#
#   🔵 **데이터는 멀쩡하다.** 읽는 쪽만 틀렸다. 공유폴더의 파일도, DB 의 줄도
#      하나도 안 건드렸고 이 배포도 안 건드린다.
#
# ══ 🔴 이 판은 21번에서 **덜어낸** 판이다 ══════════════════════════════
#
#   21번을 본으로 베끼되 **이번에 없는 것들을 걷어냈다.** 걷어낸 자리마다
#   「이번엔 없다」를 적어 둔다 — 다음 사람이 「왜 빠졌지」 하지 않게.
#   (21번이 20번에서 마이그레이션을 걷어낼 때 그렇게 했다.)
#
#     |              | 21번(열일곱째)      | **22번(이번)**            |
#     | 마이그레이션 | 0건                 | **0건** (그대로 없음)     |
#     | 새 볼륨      | 발주서 하나         | 🔴 **없다**               |
#     | .env 줄      | 일곱                | 🔴 **없다** (있는가만 본다)|
#     | 양식 교체    | 매쳐 두 벌          | 🔴 **없다**               |
#     | compose 변경 | 태그 둘 + 볼륨 넷   | **태그 둘뿐**             |
#     | 올릴 파일    | 다섯                | **셋** (tar 둘 + compose) |
#
#   ── 🔴 ① 마이그레이션 — **이번에도 없다** ──────────────────────────
#     두 커밋 다 drizzle/ 을 한 글자도 안 건드렸다. PO 에는 그 장치 자체가
#     없다(drizzle 폴더가 없다). 운영 DB 는 **115 그대로**다.
#     그래서 이 스크립트에는 묶음 · db:migrate · db:preflight · 적용 직전
#     덤프 · 「지우는 문장」 잣대가 **한 줄도 없다**(20 · 21번과 같다).
#     ⚠️ **배포 전 백업 검사만은 그대로 뒀다.** 17번에서 그것이 실제로
#        배포를 막아 사고를 피했다. DB 를 안 바꾸더라도 그 문은 안 닫는다.
#
#   ── 🔴 ② 새 볼륨 — **이번엔 없다. 다만 검사는 남겼다** ─────────────
#     21번이 app-as 에 붙인 발주서 볼륨(/purchase-order-archive)을 **더하지는
#     않는다.** 그런데 이 배포는 compose 를 다시 올려 컨테이너를 다시 만든다 —
#     그 볼륨이 **사라질 수 있다.** 그래서 검사를 「새로 붙는다」가 아니라
#     🔴 **「그대로 있다」** 쪽으로 바꿨다(21번이 /repair-docs-archive 를
#     그렇게 다룬 그 모양이다).
#       · compose 에 target · source · read_only: true · type: bind 가 그대로인가
#       · 🔴 **도는 컨테이너 안에서** 실제로 읽히는가 · 맨 위 칸이 0 이 아닌가
#       · 🔴 **쓰기가 막혀 있는가** — /proc/mounts 의 ro 를 읽어서 본다
#     🔵 그래서 21번의 probe_new_volume() 은 **없다.** 임시 컨테이너에 :ro 로
#        붙여 볼 까닭이 없다 — 그 자리는 지금 **진짜로 붙어 돌고 있다.**
#
#   ── 🔴 ③ .env — **이번엔 한 줄도 적지 않는다. 「있는가」만 본다** ───
#     21번이 as.env 에 둘 · po.env 에 다섯, 모두 일곱 줄을 넣었다. 이번 판은
#     **새 설정이 하나도 없다.** 그래서 덧붙이는 코드를 전부 걷어냈다
#     (build_env_values · want_env_value · env_verdict · append_env_keys).
#     🔴 대신 **그 일곱 줄이 아직 거기 있는지만** 본다 — 없으면 ✗ 다
#        (21번이 제대로 안 돈 것이다. 그때는 배포보다 그것이 먼저다).
#
#   ── 🔴 ④ 양식 — **이번엔 없다** ───────────────────────────────────
#     21번이 매쳐 내자 · 매쳐 OH 견적서 두 벌을 바꿨다(직인 좌표). 이번 판은
#     **양식을 올리지도 바꾸지도 않는다.** see_tpl · swap_tpl · 백업 폴더 ·
#     컨테이너 안 md5 대조가 전부 빠졌다.
#     🔵 양식은 호스트 폴더(/volume1/dss/as-templates)에 있고 :ro 로 붙는다 —
#        컨테이너를 다시 띄워도 **한 글자도 안 바뀐다.** 걱정할 자리가 아니다.
#
#   ── 🔴 ⑤ compose — **태그 두 줄만** 다르다 ─────────────────────────
#     app-as 의 image 와 app-po 의 image. 볼륨도 포트도 환경변수도 그대로다.
#     그래서 되돌릴 때 사본을 쓰지 않아도 되지만, **사본을 쓰는 규율은 그대로
#     둔다**(--go 가 backups/ 에 남긴다).
#
# ══ 🔴 21번에서 고친 것 둘을 **그대로 가져왔다** ═══════════════════════
#
#   오늘 운영 --check 에서 찾아 고친 것이다. 베끼면서 되살리지 않았다:
#
#   ① 🔴 **큰따옴표 안에 백틱을 쓰지 않는다.** 명령 치환으로 읽혀
#      syntax error 가 난다. bash -n 은 치환 **안쪽**을 안 봐서 **못 잡는다.**
#      코드를 인용할 때는 작은따옴표나 「」 를 쓴다.
#      🔵 이 파일에는 백틱이 **하나도 없다**(짠 뒤 grep 으로 세어 확인했다).
#
#   ② 🔴 **읽기 전용 자리에 리다이렉션으로 빈 파일을 만들지 않는다.**
#      Alpine 의 ash 는 리다이렉션 실패를 **치명적으로** 보고 셸을 그 자리에서
#      끝낸다 — 그래서 뒤의 echo 가 안 돌아 판정이 **빈 채로** 나왔다
#      (2026-10-12 --check 에서 실제로 났다: 「쓰기 막힘 여부를 못 봤다」).
#      🔴 **touch 를 쓴다** — 외부 명령이라 실패해도 셸이 산다.
#      🔵 21번에 한 군데 남아 있던 자리(PROBE_SH)도 **함께 touch 로 바꿨다.**
#         그쪽은 쓸 수 있는 /data 라 안 죽었을 뿐 같은 함정이다.
#
# ══ 🔴 돌리기 전에 — **값 여섯을 채워야 한다** ═════════════════════════
#
#   🔴 이 스크립트를 쓸 때 dss-as:2.5 · dss-po:0.5 는 **아직 안 구워졌다.**
#      그래서 아래 여섯 상수가 **비어 있다**:
#        SZ_AS · MD5_AS · WANT_CFG_AS · SZ_PO · MD5_PO · WANT_CFG_PO
#      비어 있는 동안 --check 는 그 자리를 ⚠️ 로만 말하고, 🔴 **--go 는 시작조차
#      하지 않는다.** 잰 적 없는 이미지를 운영에 올리지 않기 위해서다.
#
#   개발 PC(PowerShell)에서 굽고 재는 차례 — 폴더는
#   C:\Users\희만\Desktop\Development 다:
#
#     cd C:\Users\희만\Desktop\Development\RF_Service_System
#     git status --short                      ← **비어 있어야 한다**
#     docker build -t dss-as:2.5 .
#     cd ..\dss-po
#     git status --short
#     docker build -t dss-po:0.5 .
#     cd ..
#     docker save dss-as:2.5 -o dss-as-2.5.tar
#     docker save dss-po:0.5 -o dss-po-0.5.tar
#     (Get-Item dss-as-2.5.tar).Length             ← SZ_AS
#     Get-FileHash -Algorithm MD5 dss-as-2.5.tar   ← MD5_AS (소문자로 적는다)
#     tar -xOf dss-as-2.5.tar manifest.json        ← "Config" 의 sha256 → WANT_CFG_AS
#     (PO 도 같은 세 줄)
#
#   🔴 **git archive 로 뽑지 마라** — 서브모듈 vendor/dss-ui · vendor/dss-core 가
#      **빈 폴더**로 나와 빌드가 깨진다. 작업 폴더에서 굽되 git status 가 비어야 한다.
#   🔴 **tar 가 이미지의 1/4 쯤인 것은 정상이다.** 2.4 는 tar 131,237,888 바이트였고
#      이미지는 590MB 였다. 0.4 는 tar 95,424,000 이었다.
#      🔵 이번 판은 **정규식 한 줄**만 바뀌었다 — tar 크기가 2.4 · 0.4 와
#         **거의 같은 것이 정상**이다. 크게 달라졌으면 그쪽을 먼저 의심한다.
#   🔴 **tar 안 Config 지문은 개발 PC 의 {{.Id}} 와 다르다.** 17번이 두 번 겪었다.
#      NAS 는 tar 안의 config 지문을 image ID 로 낸다 — **맞춰 볼 값은 tar 쪽**이다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/22-deploy.sh            ← 읽기만 한다
#
#   🔴 NAS 의 docker 는 **sudo(root)** 가 필요하다. 이 스크립트는 root 가
#      아니면 첫 줄에서 멈춘다.
#
# ══ 🔴 개발 PC → NAS 로 올릴 것 **셋** ═════════════════════════════════
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#      아래는 **개발 PC 의 PowerShell** 에서 친다(NAS 가 아니다).
#
#     scp -O dss-as-2.5.tar dss-nas:/volume1/dss/images/
#     scp -O dss-po-0.5.tar dss-nas:/volume1/dss/images/
#     scp -O docker-compose.nas.yml dss-nas:/volume1/dss/setup/incoming/
#
#   🔵 21번은 **다섯**이었다 — 거기서 **양식 두 벌이 빠졌다**(이번엔 없다).
#   🔴 **마이그레이션 묶음은 올릴 것이 없다.** 이 스크립트는 그 파일을
#      쳐다보지도 않는다.
#   🔴 세 번째 줄의 compose 는 **dss-deploy 저장소의 nas/docker-compose.nas.yml**
#      이다(A/S · PO 태그 **두 줄만** 올라간 그 파일).
#   🔵 scp 가 바로 안 되면 사용자 계정(swhur)의 홈으로 올린 뒤 NAS 에서
#      sudo mv 로 옮긴다. /volume1/dss 아래는 root 만 쓸 수 있다.
#
# ══ 🔴 DSM 터미널은 긴 명령을 잘라 먹는다 ══════════════════════════════
#
#   하루에 네 번 깨진 적이 있다. **NAS 에서 돌릴 것은 스크립트 파일로 올리고
#   md5 를 맞춘 뒤** 실행한다. 이 파일 자체가 그렇다:
#
#     (PowerShell)  scp -O nas\setup\22-deploy.sh dss-nas:/volume1/dss/setup/
#     (PowerShell)  Get-FileHash -Algorithm MD5 nas\setup\22-deploy.sh
#     (NAS)         md5sum /volume1/dss/setup/22-deploy.sh
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
#      ✓ dss_as 줄이 찍혀야 한다. 다섯 개가 다 떠야 1-ㅅ 이 통과한다.
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#
#   11번부터 이어온 약속을 그대로 잇는다 — **인자 없이 돌리면 --check**.
#   실수로 그냥 돌려도 아무것도 바뀌지 않는다(로그 파일 하나만 남는다).
#   코드로는 아래 세 줄이 그 약속이다:
#     · MODE=check        (모드 절의 첫 줄)
#     · FORCE_LOAD=0      (같은 태그를 덮어쓰지 않는다)
#     · PROBE_WRITE=0     (--check 는 /data 에 시험 파일도 만들지 않는다)
#
#   🔴 정직하게 적어 둔다 — --check 도 이미지 **안을 보려고** 컨테이너를 잠깐
#      띄웠다 지우고(docker run --rm), 운영 DB 에 **select** 를 몇 번 보낸다.
#      디스크에도 DB 에도 아무것도 남기지 않는다. 「아무것도 안 한다」가 아니라
#      「아무것도 **바꾸지** 않는다」가 정확한 말이다.
#      🔵 21번과 달리 **공유폴더에 시험 파일을 놓아 보지 않는다.** 발주서 볼륨의
#         쓰기 막힘은 /proc/mounts 의 ro 를 **읽어서** 본다(쓰지 않는다).
#
# ── 모드 다섯 ───────────────────────────────────────────────────────────
#   (없음) · --check     읽기만 한다. 아무것도 안 바꾸고 안 멈춘다      ← 기본값
#   --preload            새 이미지 둘을 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --go                 🔴 A/S · PO 를 교체한다 (DB 는 안 바꾼다)
#   --rollback           되돌리기 안내
#
#   --force-load 는 --go 와 같이 써도 된다:  bash 22-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 22-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 22-deploy.sh --preload       (새 이미지 둘을 미리 실어 둔다)
#   3) bash 22-deploy.sh                 (다시 읽기만 — 이번엔 지문까지 다 본다)
#   4) bash 22-deploy.sh --go            (A/S · PO 교체. 그것뿐이다)
#
# ══ 🔴 「아직 안 온 것」을 ✗ 로 세지 않는다 (17 ~ 21번의 규칙) ═════════
#
#       **--check 가 ✗ 로 세는 것은 「있는데 어긋난 것」뿐이다.**
#       「아직 안 온 것 · 아직 안 실린 것」은 ⚠️ 로 안내만 한다.
#
# ══ 🔴 건드리지 않는 여덟 ══════════════════════════════════════════════
#
#     dss-auth:1.5              dss-as-tools:1
#     dss-meters:1.3            dss-meters-tools:1
#     dss-improvements:0.3      dss-improvements-tools:2
#     dss-leave:0.1             dss-leave-tools:1
#
#   전부 지금 운영에서 돌고 있다. compose 에서 이 태그가 흔들렸으면 **남의
#   변경이 섞인 것**이다 — 두 세션이 같은 저장소를 쓴다. 고치지 말고 **먼저 알린다.**
#
#   그리고 「안 멈췄다」를 말로 하지 않는다 — 교체 **전후로** 각 컨테이너의
#   시작 시각(.State.StartedAt)을 적어 두고 **그대로인지** 본다(5-ㅅ).
#
# ══ 15 ~ 21번에서 그대로 이어받는 것 ═══════════════════════════════════
#
#   ① 같은 태그로 다시 구운 이미지는 조용히 안 실린다 → --force-load
#   ② 폴더 권한은 **컨테이너 안에서 실제로 열어 본다**(ls -ld 로는 모른다)
#   ③ 이미지는 태그가 아니라 **안을 본다**(1-ㅋ)
#   ④ 사람이 칠 명령은 **한 줄 76자 안쪽**(DSM 의 ash 가 긴 줄을 자른다)
#   ⑤ 공유폴더는 **chmod 로 ACL 을 걷으면 안 된다** — 직원의 탐색기가 끊긴다
#   ⑥ 'docker ps' 에 보이는 것과 앱이 **대답하는** 것은 다르다 → wait_http
#   ⑦ compose 는 바꾸기 **전에** 시험하고, 바꾼 것은 backups/ 에 남긴다
#   ⑧ 알림 링크가 **밖에서 닿는 주소**로 나오는가(1-ㅈ · 5-ㅁ)
#   ⑨ 🔴 **권한은 코드가 아니라 운영 DB 가 정한다** — role_permissions 를
#      읽어 보고 말한다(1-ㄷ). 🔴 **select 만 쓴다.**
#   ⑩ 🔴 **만든 것과 도는 것은 다르다** — 볼륨도 설정도 **컨테이너 안에서**
#      다시 본다(5-ㄴ · 5-ㄹ).
#   ⑪ 🔴 **겉이 아니라 결과를 봐라** — 이번 판은 거기서 한 걸음 더 간다.
#      정규식이 바뀌었는지를 **글자로** 보고(1-ㅋ 짝 판정), 그 다음 **값으로**
#      본다 — 이미지 안의 그 정규식을 꺼내 실제 파일 이름에 돌려
#      2026-095-1R1 이 나오는지 센다(1-ㅋ · 5-ㄷ).
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
AS_ENV=$ENVD/as.env
PO_ENV=$ENVD/po.env
IMAGES=$D/images
BKD=$D/backups

# ── 🔴 이번에 올라가는 것 **둘** ───────────────────────────────────────
TAG_AS=dss-as:2.5
OLD_AS=dss-as:2.4
TAG_PO=dss-po:0.5
OLD_PO=dss-po:0.4

# ── 🔴 **건드리지 않는 여덟** (21번과 같다) ────────────────────────────
KEEP_AUTH=dss-auth:1.5
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_METERSTOOLS=dss-meters-tools:1
KEEP_IMP=dss-improvements:0.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_LEAVE=dss-leave:0.1
KEEP_LEAVETOOLS=dss-leave-tools:1

# ── tar 둘 ─────────────────────────────────────────────────────────────
TAR_AS=$IMAGES/dss-as-2.5.tar
TAR_PO=$IMAGES/dss-po-0.5.tar
# 🔴 **2026-10-12 21:45 에 구워 잰 값이다.** 개발 PC 의
#    Development\dss-as-2.5.tar · dss-po-0.5.tar 에서 바로 쟀다.
#    🔵 크기가 2.4(131,237,888) · 0.4(95,424,000)와 거의 같은 것이 정상이다 —
#       바뀐 것이 정규식 한 줄뿐이다.
#    🔴 tar 를 다시 구우면 지문이 달라진다 — 그때는 여섯을 다시 잰다.
SZ_AS=131239936
MD5_AS=556fac2b0e48f1355fc58f2884eb8bfc
WANT_CFG_AS=sha256:cc8a4cc4f21e94e7ff5191e5d144b642ececf59ccfe9b33a35ef5d6405e3c792
SZ_PO=95418368
MD5_PO=5830e8ec818e4a26f2ebd993943bb80e
WANT_CFG_PO=sha256:89b038728bc2112efbe5865331ad75a5dbff2a7cb75bcc89940f880330f262ea
# ⚠️ manifest.json 은 그 값을 'blobs/sha256/4256829e…' 로 적는다 — 앞의 'blobs/' 를
#    떼고 'sha256:' 를 붙인 모양으로 적는다(17 ~ 21번도 같은 모양이었다).

# ── 포트 (compose 의 ports: 에서 읽어 확인했다 — 짐작이 아니다) ────────
#   포털 13100 · A/S 13000 · 계측기 13300 · 개선요청 13500 ·
#   PO 13600 · 휴가 13700
AS_PORT=13000
PO_PORT=13600

# ── DB 이름 — 🔴 **백업 검사와 권한 읽기에만 쓴다** ────────────────────
# 🔵 이번 판은 DB 를 **바꾸지 않는다.** 마이그레이션도 덤프도 없다.
AS_DB=dss_as

# ── 권한 — 🔴 읽기만 한다. 출처는 전부 소스다 (1-ㄷ) ──────────────────
#   표·칸   vendor/dss-core/src/schema/role-permissions.ts
#           (표 role_permissions · 칸 role · area_key · level · updated_at.
#            🔴 칸 이름은 leaf_key 가 아니라 **area_key** 다 — 이름이 낡았다)
#   기본값  src/lib/auth/permission-baseline.ts
#   🔴 표에 줄이 **없으면** 코드의 기본값대로다. 줄이 있으면 그 값이 이긴다.
#   🔵 이번 판은 **새 권한을 하나도 만들지 않았다.** 그래도 읽어 두는 것은,
#      어느 칸이 NONE 이면 그 사람 눈에는 「고쳐진 것이 없다」로 보이기 때문이다.
PERM_TABLE=role_permissions
PERM_AREA_CASE=repairCases.view
PERM_AREA_FILES=repairCases.files
PERM_AREA_QUOTE=quotes.view

# ── 컨테이너 안에서 실제로 열어 볼 폴더 ────────────────────────────────
ATT=$D/as-attachments
TEMPLATES=$D/as-templates
UP_IMP=$D/improvements-uploads
MF_METERS=$D/meters-files
# 🔵 **이미 붙어 있는 공유폴더 다섯.** 🔴 이번 판은 **하나도 더하지 않는다** —
#    여기서는 전부 「사라지지 않았는가」만 본다.
PORTAL_MNT=/customer-portal-archive          # 16번이 붙였다 (현황표)
CONTACT_MNT=/contact-folder-archive          # 18번이 붙였다 (연락서 · 쓰기 가능)
REPAIR_MNT=/repair-docs-archive              # 19번이 붙였다 (수리 관련 · 읽기 전용)
PO_MNT=/purchase-order-archive               # 🔴 **21번이 붙였다** (발주서 · 읽기 전용)
# 🔴 「5_ 외자 PO」 의 **PO 는 대문자**다. Windows 탐색기에는 소문자로 보이지만
#    NAS 의 실제 이름은 대문자다(2026-10-12 사용자가 'ls -d /volume1/*/' 로 확인).
#    소문자로 적으면 리눅스에서 **조용히 빈 폴더**가 되고 화면은
#    「발주서가 하나도 없다」로 보인다 — 「2_AS센터」 에서 겪은 그 일이다.
PO_SRC="/volume1/5_ 외자 PO/1. 발주서(고객-디에스에스) 관련 최종자료(활용)/열람가능 외부 송부시 대표 허락요망/발주서 및 해당 정보 파일 모음"

# ══════════════════════════════════════════════════════════════════════
#  🔴 .env — **이번엔 한 줄도 적지 않는다. 「있는가」만 본다.**
#
#  🔵 21번이 넣은 일곱 줄이 **그대로 있는지**만 센다. 없으면 ✗ 다 — 21번이
#     제대로 안 돈 것이고, 그때는 배포보다 그것이 먼저다.
#  🔴 이 PC(dss-deploy)의 nas/env/*.env 를 NAS 로 **올리지 않는다. 절대로.**
#     그 사본은 낡아서 NAS 에만 있는 줄들이 없다 — 올리면 그 기능들이 운영에서
#     통째로 사라진다. (이번 판은 아예 **쓰지 않는다.**)
# ══════════════════════════════════════════════════════════════════════
QUOTE_KEYS="QUOTE_ARCHIVE_DIR QUOTE_ARCHIVE_UNC_ROOT QUOTE_ARCHIVE_UNC_ROOT_ALT"
PORTAL_KEYS="CUSTOMER_PORTAL_ARCHIVE_DIR CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT CUSTOMER_PORTAL_ARCHIVE_FOLDER_PATH CUSTOMER_PORTAL_ARCHIVE_UNC_PATH"
CONTACT_KEYS="CONTACT_FOLDER_ARCHIVE_DIR CONTACT_FOLDER_ARCHIVE_UNC_ROOT CONTACT_FOLDER_ARCHIVE_UNC_PATH"
REPAIR_KEYS="REPAIR_DOCS_ARCHIVE_DIR REPAIR_DOCS_ARCHIVE_UNC_ROOT"
# 🔴 21번이 as.env 에 넣은 **두 줄**. 없으면 발주서 탭이 죽는다.
PO_ARCHIVE_KEYS="PURCHASE_ORDER_ARCHIVE_DIR PURCHASE_ORDER_ARCHIVE_UNC_ROOT"
# 🔴 21번이 po.env 에 넣은 **다섯 줄**. 도우미가 루트를 모으는 그 차례다
#    (quote-folder-helper.ts 의 resolveQuoteFolderHelperInstallRoots 배열).
PO_HELPER_KEYS="CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT CONTACT_FOLDER_ARCHIVE_UNC_ROOT REPAIR_DOCS_ARCHIVE_UNC_ROOT PURCHASE_ORDER_ARCHIVE_UNC_ROOT"
# 🔴 _ALT 를 뺀 넷은 **값이 비어 있으면 안 된다** — 비면 그 루트가 통째로 빠진다.
#    🔵 _ALT 는 선택값이다 — 도우미가 빈 값을 건너뛴다(2026-10-12 실측).
PO_REQUIRED_KEYS="CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT CONTACT_FOLDER_ARCHIVE_UNC_ROOT REPAIR_DOCS_ARCHIVE_UNC_ROOT PURCHASE_ORDER_ARCHIVE_UNC_ROOT"
PO_ALT_KEY=CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT_ALT

# ══════════════════════════════════════════════════════════════════════
#  이미지 **안에서** 찾을 글자 (1-ㅋ) — 🔴 **짝으로** 본다
#
#  🔴 이번 판은 **새 파일이 0개**다. 커밋 둘이 고친 것은 모듈 하나의 정규식
#     한 줄뿐이고, 함께 든 세 파일은 전부 **시험 파일**이라 이미지에 안 담긴다.
#     그래서 19 · 21번처럼 「새 모듈 경로가 있나」로는 두 판을 **못 가른다** —
#     20번이 쓴 **내용 짝**(새 글자가 있고 옛 글자가 없다)으로 가린다.
#
#  🔵 정규식 리터럴은 압축기가 **글자를 바꾸지 않는다**(토큰 하나로 다룬다).
#     그래서 아래 두 줄은 번들 안에 **그대로** 들어 있다.
#  🔴 A/S 와 PO 가 **글자까지 같은 모듈**을 들고 있다 — 두 이미지에 같은 짝을 쓴다.
NEW_RE='^DSS[ -](\d{4}-\d+(?:-\d+)?(?:R\d+)?)(?=\s)'
OLD_RE='^DSS[ -](\d{4}-\d+(?:-\d+|R\d+)?)(?=\s)'
# 🔵 회귀 — 2.4 · 0.4 에서 들어온 것이 2.5 · 0.5 에도 그대로 있는가.
AS_KEEP1='src/lib/storage/purchase-order-archive.ts'          # 2.4 가 더한 발주서 탭
AS_KEEP2='src/lib/storage/repair-docs-archive.ts'             # 2.2 의 「수리 관련」
PO_KEEP1='src/components/quotes/QuoteArchiveFolderSection.tsx' # 0.4 가 더한 공유폴더 구역
PO_KEEP2='src/lib/server/quote-folder-helper.ts'              # 도우미 설치본
# 대조 표시 — 두 판에 다 있다. 이것이 안 나오면 **글자를 못 읽은 것**이다.
CTRL='SSO_REDIRECT_URI'

# ══════════════════════════════════════════════════════════════════════
#  🔴 **이 배포의 핵심 — 정규식을 「값」으로 재어 본다**
#
#  글자로 보는 것(위 짝 판정)은 「새 모양이 들어 있다」까지만 말한다. 이번 판은
#  그 정규식이 **실제로 그 번호를 읽어 내는가**가 전부라, 한 걸음 더 간다:
#
#    ① 이미지(또는 도는 컨테이너) 안의 /app/.next 를 뒤져 **그 정규식 리터럴을
#       꺼낸다** — 머리 「/^DSS[ -](」 부터 꼬리 「/i」 까지.
#    ② 꺼낸 그것으로 RegExp 를 만들어 **파일 이름 여섯에 돌린다.**
#    ③ 뽑힌 번호를 기대값과 **글자로 견준다.**
#
#  🔴 **실제 고객 정보를 쓰지 않는다** — 이 저장소는 공개다. 번호 모양만 실물로
#     두고 고객사명 · 모델 · L/N · S/N 은 A/S · PO 두 저장소의 시험 파일이 쓰는
#     **그 가짜 이름**을 그대로 쓴다(quote-archive-file-number.test.ts).
#
#  🔵 앱의 진짜 함수는 번호를 뽑기 전에 이름을 다듬고(NFC · 연속 공백 하나 ·
#     앞뒤 공백 걷기) 뒤에 대문자로 맞춘다. 아래 여섯은 다듬을 것이 없는 이름이라
#     결과가 같고, 이 스크립트도 끝에 대문자로 맞춘다.
#
#  🔴 **왜 node 로 재는가.** 모듈 하나만 꺼내 부를 길이 번들에는 없다(webpack
#     묶음이다). 그래서 **그 정규식 자체**를 꺼내 돌린다 — 앱이 쓰는 바로 그
#     글자이므로, 통과하면 그 화면도 통과한다. node 는 이미지에 반드시 있다
#     (Dockerfile 의 CMD 가 node server.js 다).
# ══════════════════════════════════════════════════════════════════════
# 🔴 ① 이번 결함 그 번호다. 2.4 · 0.4 는 여기서 (null) 을 낸다.
NP1='DSS 2026-095-1R1 가나상사 MODEL-X1 AB1234 1234567 수리 견적서.xls'
NW1='2026-095-1R1'
NL1='🔴 가지+개정 — **이번 결함 그 번호**'
# ② ~ ④ 회귀 — 옛 판에서도 되던 것이 그대로 되는가.
NP2='DSS 2026-095 가나상사 MODEL-X1 AB1234 1234567 수리 견적서.xls'
NW2='2026-095'
NL2='가지도 개정도 없는 번호'
NP3='DSS 2026-095-1 가나상사 MODEL-X1 AB1234 1234567 수리 견적서(OH포함).xls'
NW3='2026-095-1'
NL3='가지만 붙은 번호'
NP4='DSS 2026-004R1 가나상사 MODEL-X1 AB1234 1234567 수리 견적서.pdf'
NW4='2026-004R1'
NL4='개정만 붙은 번호'
# ⑤ ⑥ 🔴 **안 받아야 맞는 것들.** 넓히다 지나치면 여기서 잡힌다.
NP5='DSS 2026-095R1-1 가나상사 MODEL-X1 AB1234 1234567 수리 견적서.xls'
NW5='(null)'
NL5='🔴 개정이 가지보다 앞 — **일부러 안 받는다**'
NP6='DSS 2026-046- ICD MODEL-X1 AB1234 1234567 수리 견적서.xls'
NW6='(null)'
NL6='🔴 번호 뒤가 공백이 아니다(오타) — **안 받는다**'
# 🔴 node 에 넘길 글. 작은따옴표로 감싼다 — 안에 백틱도 $ 도 없다.
NUMBER_PROBE_JS='
const fs = require("fs");
const path = require("path");
const ANCHOR = "/^DSS[ -](";
const TAIL = "/i";
let src = null;
let where = "";
const stack = ["/app/.next"];
while (stack.length > 0 && src === null) {
  const dir = stack.pop();
  let entries = [];
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch (err) { continue; }
  for (const entry of entries) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) { stack.push(p); continue; }
    if (!entry.name.endsWith(".js")) continue;
    let text = "";
    try { text = fs.readFileSync(p, "utf8"); } catch (err) { continue; }
    const i = text.indexOf(ANCHOR);
    if (i < 0) continue;
    const j = text.indexOf(TAIL, i);
    if (j < 0) continue;
    src = text.slice(i + 1, j);
    where = p;
    break;
  }
}
if (src === null) { console.log("NUMSRC NOTFOUND"); process.exit(0); }
console.log("NUMSRC " + src);
console.log("NUMWHERE " + where);
let re = null;
try { re = new RegExp(src, "i"); } catch (err) { console.log("NUMSRC BADRE"); process.exit(0); }
for (let k = 1; k <= 6; k += 1) {
  const name = process.env["P" + k];
  if (typeof name !== "string" || name.length === 0) continue;
  const m = re.exec(name);
  console.log("NUMPROBE " + k + " " + (m === null ? "(null)" : m[1].toUpperCase()));
}
'

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 셋. 인자가 없으면 이 셋 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
PROBE_WRITE=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 22-deploy.sh                  읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 22-deploy.sh --check          위와 같습니다
  bash 22-deploy.sh --preload        새 이미지 둘을 싣고 지문만 맞춥니다
  bash 22-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 22-deploy.sh --go             🔴 A/S · PO 교체 — 그것뿐입니다
  bash 22-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 22-deploy.sh --rollback       되돌리기 안내

  🔴 --go 가 멈추는 것은 **dss-as 와 dss-po 둘**입니다.
     포털 · 계측기 · 개선요청 · 휴가 · DB 는 그대로 돕니다.
  🔵 --go 는 **DB 도 .env 도 양식도 안 바꿉니다** — 이번 판은 이미지 둘뿐입니다.
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
# 🔴 쓰기 시험(폴더에 빈 파일을 놓았다 지운다)은 --go 에서만 한다.
#    --check 가 「아무것도 안 바꾼다」고 말해 놓고 파일을 만들면 그 약속이 거짓이 된다.
[ "$MODE" = go ] && PROBE_WRITE=1

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/22-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11 ~ 21-deploy.sh 의 것 그대로 ────────────────────────────
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

# 🔴 값 여섯이 채워졌는가 — 안 채워졌으면 --go 가 시작하지 않는다.
pinned() {
  [ -n "$SZ_AS" ] && [ -n "$MD5_AS" ] && [ -n "$WANT_CFG_AS" ] \
    && [ -n "$SZ_PO" ] && [ -n "$MD5_PO" ] && [ -n "$WANT_CFG_PO" ]
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
pg_up()   { running dss-pg-app; }

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미 — 🔴 **이 스크립트가 DB 에 보내는 SQL 은 전부 select 다.**
#     db:migrate 도, pg_dump 도, db:preflight 도 없다.
# ══════════════════════════════════════════════════════════════════════
qas()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -Atc \"$1\"" 2>/dev/null; }
qqas() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -c   \"$1\"" 2>/dev/null; }

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
# 🔴 어떤 줄 **바로 다음 줄**만 뽑는다 (볼륨의 read_only 를 보려고).
#    grep -A1 를 쓰지 않는다 — DSM 의 grep 이 GNU 가 아닐 수 있다. awk 로 한다.
line_after() { # 1 찾을 글자 (본문은 표준입력)
  awk -v pat="$1" 'f { print; f = 0 } index($0, pat) { f = 1 }'
}
# ── 🔴 역슬래시가 삼켜졌는가 — UNC 값에 역슬래시가 넷 이상 있어야 맞다 ──
backslash_count() { # 1 값 → 개수
  printf '%s' "$1" | tr -cd '\\' | wc -c | tr -d ' '
}
# ══════════════════════════════════════════════════════════════════════
#  ② 폴더를 **컨테이너 안에서 실제로 열어 본다**
#
#  🔴 주인(uid)과 모드(755)만 보면 통과하는데 실제로는 EACCES 인 일이 있다.
#     Synology ACL 이 상위에서 내려오면 'ls -ld' 에는 끝의 더하기 하나로만 보인다.
#     → 판정은 커널에게 맡긴다. 컨테이너 안에서 'ls' 를 돌려 본다.
#
#  PATHS 는 "경로:모드" 를 빈칸으로 나열한 것이다.
#    ro   읽기만 / rw  읽기+파일 쓰기 / rwd  읽기+파일 쓰기+**폴더 만들기**
#  🔴 쓰기 시험은 PROBE_WRITE=1 (즉 --go) 일 때만 한다.
#
#  🔴 **빈 파일을 리다이렉션으로 만들지 않는다 — touch 를 쓴다.**
#     21번에는 이 자리에 리다이렉션이 남아 있었다. 쓸 수 있는 /data 라 안 죽었을
#     뿐, 읽기 전용 자리에서는 Alpine 의 ash 가 **셸을 그 자리에서 끝낸다** —
#     뒤의 echo 가 안 돌아 판정이 **빈 채로** 나온다(2026-10-12 실제 사고).
#     touch 는 외부 명령이라 실패해도 셸이 산다.
# ══════════════════════════════════════════════════════════════════════
PROBE_SH='id
for p in $PATHS; do
  d=${p%%:*}; m=${p##*:}
  if ls -1 "$d" >/dev/null 2>&1; then r=READ_OK; else r=READ_FAIL; fi
  w=WRITE_SKIP; k=MKDIR_SKIP
  if [ "$m" = rw ] || [ "$m" = rwd ]; then
    t="$d/.dss-write-test"
    if touch "$t" 2>/dev/null; then w=WRITE_OK; rm -f "$t"; else w=WRITE_FAIL; fi
  fi
  if [ "$m" = rwd ]; then
    g="$d/.dss-dir-test"
    if mkdir "$g" 2>/dev/null; then k=MKDIR_OK; rmdir "$g"; else k=MKDIR_FAIL; fi
  fi
  echo "PROBE $d $r $w $k"
done'

perm_fix_hint() { # 나머지: 호스트 폴더들
  local h
  say "    ╔══════════════════════════════════════════════════════════════╗"
  say "    ║ 🔴 주인·모드로는 통과하는데 **컨테이너가 실제로는 못 연다.**   ║"
  say "    ╚══════════════════════════════════════════════════════════════╝"
  say "    상위 공유폴더의 Synology ACL 을 물려받은 것이다."
  say "    먼저 눈으로 본다:"
  for h in "$@"; do
    cmd "ls -ld $h"
    cmd "synoacltool -get $h"
  done
  say "    고친다 — 🔴 Synology 는 chmod 하면 ACL 을 벗고 Linux mode 가 된다:"
  for h in "$@"; do
    cmd "chown -R 1000:1000 $h"
    cmd "find $h -type d -exec chmod 750 {} +"
    cmd "find $h -type f -exec chmod 640 {} +"
  done
  say "    🔴 /volume1/3_견적… · /volume1/2_AS센터 · /volume1/5_ 외자 PO 같은"
  say "       **직원이 쓰는 공유폴더에는 하지 마라** — 탐색기 접근이 끊긴다."
}

probe_svc() { # 1 서비스 2 컨테이너이름 3 사람이읽을이름 4 "경로:모드 …" 5 "호스트폴더 …"
  local svc="$1" cname="$2" label="$3" paths="$4" hosts="$5"
  local img out how anybad=0 d r w k
  if running "$cname"; then
    how="지금 도는 컨테이너 $cname 안에서"
    out=$("$DOCKER" exec -e PATHS="$paths" "$cname" sh -c "$PROBE_SH" 2>&1)
  else
    img=$(svc_image "$CF_EFF" "$svc")
    if [ -n "$img" ] && have_img "$img"; then
      how="새 컨테이너($svc · $img)를 잠깐 띄워"
      out=$(compose_at "$CF_EFF" run --rm --no-deps -e PATHS="$paths" \
            --entrypoint sh "$svc" -c "$PROBE_SH" 2>&1)
    else
      say "  · $label — $cname 도 안 돌고 ${img:-이미지}도 아직 없다. **못 열어 봤다**"
      say "    → 먼저 이미지를 실으세요:"
      cmd "bash $0 --preload"
      return 0
    fi
  fi
  say "  $label — $how 본 것:"
  printf '%s\n' "$out" | grep -E '^(uid=|PROBE )' | sed 's/^/      /'
  if ! printf '%s\n' "$out" | grep -q '^PROBE '; then
    bad "$label 의 폴더를 열어 보지 못했다 — 아래가 그대로의 출력이다"
    printf '%s\n' "$out" | sed 's/^/      /' | head -8
    return 1
  fi
  while read -r _ d r w k; do
    [ -n "${d:-}" ] || continue
    case "$r" in
      READ_OK) ok "$label · $d 를 읽는다" ;;
      *)       bad "$label · $d 를 **못 읽는다**(EACCES)"; anybad=1 ;;
    esac
    case "$w" in
      WRITE_OK)   ok "$label · $d 에 쓸 수 있다" ;;
      WRITE_SKIP) : ;;
      *)          bad "$label · $d 에 **못 쓴다**"; anybad=1 ;;
    esac
    case "$k" in
      MKDIR_OK)   ok "$label · $d 에 폴더를 만들 수 있다" ;;
      MKDIR_SKIP) : ;;
      *)          bad "$label · $d 에 **폴더를 못 만든다**"; anybad=1 ;;
    esac
  done <<EOF
$(printf '%s\n' "$out" | grep '^PROBE ')
EOF
  [ "$anybad" = 0 ] || perm_fix_hint $hosts
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 **읽기 전용 볼륨이 아직 읽기 전용인가** — 쓰지 않고 **읽어서** 본다
#
#  🔵 21번은 임시 컨테이너에 호스트 경로를 :ro 로 붙여 touch 를 해 봤다.
#     거기는 **아직 안 붙은 자리**라 그래야 했다. 이번 판은 그 자리가 **진짜로
#     붙어 돌고 있다** — 거기에 파일을 놓아 보는 것은 직원의 서류함에 쓰는 일이다.
#  🔴 그래서 /proc/mounts 를 **읽는다.** 커널이 적어 둔 것이라 거짓말하지 않고,
#     --check 가 「아무것도 안 바꾼다」는 약속도 그대로 지켜진다.
#  🔵 --go 의 스모크에서는 교체 뒤에 touch 로 **한 번 더** 확인한다(5-ㄴ).
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
    say "    → compose 의 app-as 쪽 그 볼륨 네 줄이 지워졌는지 보세요."
    return 1
  fi
  say "    · $3 마운트 옵션: $o"
  case ",$o," in
    *,ro,*) ok "🔴 $3 · **읽기 전용 그대로다**(ro)" ; return 0 ;;
  esac
  bad "🔴 $3 · 마운트가 **쓸 수 있는 상태**다 — read_only: true 가 안 먹었다"
  say "    🔴 이 기능은 이 폴더를 **읽기만** 한다. 쓸 수 있는 자리가 열린 채로"
  say "       돌면 앱이 직원의 서류함을 고칠 수 있다."
  return 1
}
# 🔴 폴더 안이 **비어 보이지 않는가** — 경로 대소문자가 틀리면 빈 폴더가 붙는다.
mnt_count_check() { # 1 컨테이너 2 경로 3 이름 4 연도폴더도보나(1/0)
  local n y rc=0
  n=$("$DOCKER" exec "$1" sh -c "ls -1 '$2' 2>/dev/null | wc -l" 2>/dev/null | tr -d ' ')
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then
    ok "$3 · 맨 위 칸에 ${n}개가 보인다"
  else
    bad "🔴 $3 · 맨 위 칸이 **0개다** — 빈 폴더가 붙었다(경로 대소문자)"
    say "    → 🔴 「5_ 외자 PO」 의 **PO 가 대문자**인지 보세요."
    cmd "ls -d /volume1/5_*"
    rc=1
  fi
  if [ "$4" = 1 ]; then
    y=$("$DOCKER" exec "$1" sh -c "ls -1 '$2' 2>/dev/null | grep -c '^[12][0-9][0-9][0-9]\$'" 2>/dev/null | tr -d ' ')
    if [ "${y:-0}" -ge 1 ] 2>/dev/null; then
      ok "$3 · 맨 위 칸에 **연도 폴더**(2026 꼴)가 ${y}개 있다 — 자리가 맞다"
    else
      bad "🔴 $3 · 연도 폴더(2026 꼴)가 **하나도 없다** — 한 칸 위나 아래다"
      say "    (발주서는 <루트>/2026/<고객사>/<발주 건> 꼴로 쌓여 있다.)"
      rc=1
    fi
  fi
  return "$rc"
}

# ══════════════════════════════════════════════════════════════════════
#  【이어받은 검사】 알림 링크의 **주소를 실제로 뽑아 본다**
#
#  🔴 2026-09-29 에 「통로가 있다(401 이 온다)」로 통과했는데, 그 통로가 내준
#     링크가 http://172.20.0.7:3500/ 이었다. 문이 있는지가 아니라 **무엇이
#     나오는지**를 봐야 잡힌다.
# ══════════════════════════════════════════════════════════════════════
NOTIFY_CB=/api/auth/sso/callback
href_shape() { # 1 주소  (값을 그대로 찍지 않는다 — 숫자를 N 으로 가린다)
  printf '%s' "$1" | cut -c1-48 | sed 's/[0-9]/N/g'
}
judge_base_url() { # 1 라벨 2 SSO_REDIRECT_URI 원본 3 기대 앞머리
  local label="$1" raw="$2" want="$3" base host
  case "$raw" in
    auto|auto:*|AUTO|"")
      bad "$label · SSO_REDIRECT_URI 가 auto(또는 빈 값)다 — 운영에서는 도메인을 적는다"
      say "      auto 는 이 기계의 랜 주소를 집는다. **컨테이너 안에서는 172.x 가 잡힌다.**"
      return 1 ;;
  esac
  case "$raw" in
    *"$NOTIFY_CB") base=${raw%"$NOTIFY_CB"} ;;
    *)
      bad "$label · SSO_REDIRECT_URI 가 $NOTIFY_CB 로 끝나지 않는다"
      say "      앱은 여기서 던지고 **알림이 통째로 빈 목록**이 된다. 꼴: $(href_shape "$raw")"
      return 1 ;;
  esac
  base=$(printf '%s' "$base" | sed 's:/*$::')
  host=${base#*://}; host=${host%%/*}; host=${host%%:*}
  case "$host" in
    172.*|10.*|192.168.*)
      bad "$label · 알림 주소가 **밖에서 닿지 않는 사설 주소**다 — $(href_shape "$base") 꼴"
      return 1 ;;
    *[!0-9.]*) : ;;   # 글자가 섞여 있다 = 이름(도메인)이다
    *)
      bad "$label · 알림 주소가 이름이 아니라 **IP** 다 — $(href_shape "$base") 꼴"
      return 1 ;;
  esac
  if [ "$base" = "$want" ]; then
    ok "$label · 알림 링크가 $want 로 시작한다"
    return 0
  fi
  bad "$label · 알림 주소가 $want 가 아니다 — $(href_shape "$base") 꼴"
  return 1
}
notify_href_check() { # 1 라벨 2 컨테이너 3 env파일 4 기대앞머리
  local label="$1" cname="$2" envf="$3" want="$4"
  local raw="" src=""
  say "  $label — 알림 링크가 무엇으로 시작하는지 본다"
  if running "$cname"; then
    raw=$("$DOCKER" exec "$cname" printenv SSO_REDIRECT_URI 2>/dev/null | tr -d '\r')
    [ -n "$raw" ] && src="지금 도는 $cname 안"
  fi
  if [ -z "$raw" ] && [ -f "$envf" ]; then
    raw=$(sed -n 's/^SSO_REDIRECT_URI=//p' "$envf" | head -1 | tr -d '\r')
    raw=${raw#\"}; raw=${raw%\"}
    raw=${raw#\'}; raw=${raw%\'}
    [ -n "$raw" ] && src="$(basename "$envf")"
  fi
  if [ -z "$raw" ]; then
    bad "$label · SSO_REDIRECT_URI 를 찾지 못했다 — 알림 주소를 계산할 수 없다"
    return 1
  fi
  say "    · $src 에서 읽었다 (🔴 값은 찍지 않는다)"
  judge_base_url "$label" "$raw" "$want"
}

# ══════════════════════════════════════════════════════════════════════
#  이미지 **안에** 이번 판이 들어 있는가 — 🔴 **짝으로** 본다 (20번의 길)
#
#  🔴 「아직 안 실린 것」은 ✗ 가 아니다. 못 봤다고 말하고 넘어간다.
#  🔴 대조 표시(CTRL)가 안 나오면 **판정하지 않는다** — 글자를 못 읽은 것과
#     옛 판인 것을 가를 수 없기 때문이다.
#  🔵 19 · 21번은 **새 모듈 경로**로 갈랐지만 이번 판은 새 파일이 0개라
#     그 방법이 통하지 않는다(2.4 에도 전부 있다).
# ══════════════════════════════════════════════════════════════════════
pair_judge() { # 1 이름 2 새글자있나(0/1) 3 옛글자있나(0/1) 4 새판이름 5 옛판이름
  local label="$1" n="${2:-0}" o="${3:-0}" nw="$4" od="$5"
  if [ "$o" = 1 ]; then
    bad "🔴 $label — **$od 의 모습이다**(옛 정규식이 아직 보인다). 옛 판을 올린 것이다"
    return 1
  fi
  if [ "$n" = 1 ]; then
    ok "$label — $nw 의 모습이다 (새 정규식이 들어 있다)"
    return 0
  fi
  say "    ⚠️ $label — 새 글자도 옛 글자도 **못 찾았다.** 압축기가 글자 모양을"
  say "       바꿨을 수 있다. 🔴 **판정하지 않는다** — 아래 「값으로 재기」가"
  say "       그 자리를 대신 본다(그쪽이 더 센 검사다)."
  return 0
}
inside_check() { # 1 태그 2 라벨 3 옛태그 4 회귀글자1 5 회귀글자2
  local tag="$1" label="$2" old="$3" keep1="$4" keep2="$5"
  local out n o k1 k2 c
  if ! have_img "$tag"; then
    notloaded "$tag 가 아직 NAS 에 없어 **안을 못 봤다** — 먼저 실으세요"
    cmd "bash $0 --preload"
    return 0
  fi
  # 🔴 글자는 **-e 로 넘긴다.** sh -c 본문에 끼워 넣으면 괄호 · 물음표가 든
  #    글자에서 조용히 깨진다. 결과는 한 줄에 0/1 다섯 개로 받는다.
  out=$("$DOCKER" run --rm \
        -e N="$NEW_RE" -e O="$OLD_RE" \
        -e K1="$keep1" -e K2="$keep2" -e C="$CTRL" \
        --entrypoint sh "$tag" -c '
    r=""
    for w in "$N" "$O" "$K1" "$K2" "$C"; do
      if grep -rlF -- "$w" /app/.next >/dev/null 2>&1; then r="$r 1"; else r="$r 0"; fi
    done
    echo "INSIDE$r"' 2>/dev/null \
    | grep '^INSIDE ' | head -1)
  n=$(printf  '%s' "$out" | awk '{print $2}')
  o=$(printf  '%s' "$out" | awk '{print $3}')
  k1=$(printf '%s' "$out" | awk '{print $4}')
  k2=$(printf '%s' "$out" | awk '{print $5}')
  c=$(printf  '%s' "$out" | awk '{print $6}')
  if [ "${c:-0}" != 1 ]; then
    say "    ⚠️ $tag 안을 글자로 뒤지지 못했다 — 대조 표시($CTRL)도 안 나왔다."
    say "       **판정하지 않는다.** 🔴 이때는 아래 「값으로 재기」를 보세요."
    return 0
  fi
  ok "$label · 대조 표시($CTRL)를 찾았다 — 안을 실제로 읽었다는 뜻이다"
  pair_judge "$label · 견적서 번호 정규식" "$n" "$o" "$tag" "$old"
  [ "${k1:-0}" = 1 ] && ok "$label · 회귀 — $keep1 가 그대로 있다" \
    || bad "🔴 $label · $keep1 가 **사라졌다** — $old 보다 **옛 판**을 올린 것이다"
  [ "${k2:-0}" = 1 ] && ok "$label · 회귀 — $keep2 가 그대로 있다" \
    || bad "🔴 $label · $keep2 가 **사라졌다** — $old 보다 **옛 판**을 올린 것이다"
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 **정규식을 값으로 재어 본다** — 이 배포의 핵심 (머리말 ⑪)
#
#  how=image : 아직 안 띄운 이미지 안에서 (docker run --rm)
#  how=run   : 🔴 **지금 도는 컨테이너** 안에서 (docker exec)
#              — 「만든 것과 도는 것은 다르다」. 교체 뒤에는 이쪽을 본다.
# ══════════════════════════════════════════════════════════════════════
number_probe() { # 1 how(image|run) 2 태그또는컨테이너 3 라벨 4 옛판이름
  local how="$1" what="$2" label="$3" old="$4"
  local out src where v want plabel k rc=0 rec
  if [ "$how" = image ]; then
    if ! have_img "$what"; then
      notloaded "$label · $what 가 아직 NAS 에 없어 **값으로 못 재 봤다**"
      return 0
    fi
    out=$("$DOCKER" run --rm \
          -e P1="$NP1" -e P2="$NP2" -e P3="$NP3" \
          -e P4="$NP4" -e P5="$NP5" -e P6="$NP6" \
          --entrypoint node "$what" -e "$NUMBER_PROBE_JS" 2>&1)
  else
    if ! running "$what"; then
      bad "$label · $what 가 안 돌고 있어 **값으로 못 재 봤다**"
      return 1
    fi
    out=$("$DOCKER" exec \
          -e P1="$NP1" -e P2="$NP2" -e P3="$NP3" \
          -e P4="$NP4" -e P5="$NP5" -e P6="$NP6" \
          "$what" node -e "$NUMBER_PROBE_JS" 2>&1)
  fi
  src=$(printf '%s\n' "$out" | sed -n 's/^NUMSRC //p' | head -1)
  where=$(printf '%s\n' "$out" | sed -n 's/^NUMWHERE //p' | head -1)
  if [ -z "$src" ]; then
    say "    ⚠️ $label · node 가 대답하지 않았다. **판정하지 않는다** —"
    say "       아래가 그대로의 출력이다. 🔴 이때는 사람이 화면에서 봐야 한다."
    printf '%s\n' "$out" | sed 's/^/      /' | head -6
    return 0
  fi
  if [ "$src" = NOTFOUND ]; then
    say "    ⚠️ $label · 이미지 안에서 그 정규식을 못 찾았다. **판정하지 않는다** —"
    say "       압축기가 글자 모양을 바꿨을 수 있다. 🔴 사람이 화면에서 봐야 한다."
    return 0
  fi
  if [ "$src" = BADRE ]; then
    bad "🔴 $label · 꺼낸 글자가 정규식이 아니었다 — 꺼내는 자리가 틀렸다"
    return 1
  fi
  say "  $label — 이미지 안에 **실제로 들어 있는** 정규식:"
  printf '      %s\n' "$src"
  [ -n "$where" ] && printf '      (찾은 자리: %s)\n' "$where"
  say "    🔵 아래는 그 정규식을 **그대로 돌려 본 결과**다(가짜 이름을 쓴다):"
  for rec in "1|$NW1|$NL1" "2|$NW2|$NL2" "3|$NW3|$NL3" \
             "4|$NW4|$NL4" "5|$NW5|$NL5" "6|$NW6|$NL6"; do
    k=$(printf '%s' "$rec" | cut -d'|' -f1)
    want=$(printf '%s' "$rec" | cut -d'|' -f2)
    plabel=$(printf '%s' "$rec" | cut -d'|' -f3)
    v=$(printf '%s\n' "$out" | sed -n "s/^NUMPROBE $k //p" | head -1)
    if [ "$v" = "$want" ]; then
      ok "$label · $plabel → $v"
    elif [ "$k" = 1 ] && [ "$v" = "(null)" ]; then
      bad "🔴 $label · $plabel 가 **(null)** 이다 — 이것은 $old 다"
      say "      🔴 **이번 결함이 그대로 있는 판**이다. 올리면 아무것도 안 고쳐진다."
      rc=1
    else
      bad "🔴 $label · $plabel → ${v:-못 읽음}  (기대 $want)"
      rc=1
    fi
  done
  return "$rc"
}

# ── 🔴 이미지 안에 글자 인식기(public/ocr)가 들어 있는가 (A/S 만) ──────
# 🔴 Next 의 standalone 은 public 을 **자동으로 담지 않는다.** Dockerfile 이
#    따로 COPY 하는데, 그 줄이 어긋나면 화면은 뜨고 명판 읽기만 죽는다.
# 🔵 이번 판이 더한 기능이 아니다 — 회귀 검사다(2026-10-05 실측 6912KB).
ocr_check() { # 1 이미지태그
  local tag="$1" out a b c s
  if ! have_img "$tag"; then
    notloaded "OCR · $tag 가 아직 NAS 에 없어 못 봤다"
    return 0
  fi
  out=$("$DOCKER" run --rm --entrypoint sh "$tag" -c '
    a=0; b=0; c=0
    [ -f /app/public/ocr/tesseract.min.js ] && a=1
    [ -f /app/public/ocr/worker.min.js ] && b=1
    ls /app/public/ocr/tessdata/*.traineddata.gz >/dev/null 2>&1 && c=1
    s=$(du -sk /app/public/ocr 2>/dev/null | cut -f1)
    echo "OCR $a $b $c ${s:-0}"' 2>/dev/null | grep '^OCR ' | head -1)
  a=$(printf '%s' "$out" | awk '{print $2}')
  b=$(printf '%s' "$out" | awk '{print $3}')
  c=$(printf '%s' "$out" | awk '{print $4}')
  s=$(printf '%s' "$out" | awk '{print $5}')
  [ "${a:-0}" = 1 ] && ok "이미지 안에 tesseract.min.js 가 있다" \
    || bad "이미지 안에 /app/public/ocr/tesseract.min.js 가 **없다**"
  [ "${b:-0}" = 1 ] && ok "이미지 안에 worker.min.js 가 있다" \
    || bad "이미지 안에 /app/public/ocr/worker.min.js 가 **없다**"
  [ "${c:-0}" = 1 ] && ok "이미지 안에 tessdata/*.traineddata.gz 가 있다" \
    || bad "이미지 안에 tessdata 언어 자료가 **없다** — 글자 인식이 안 돈다"
  say "    · /app/public/ocr 크기: ${s:-?} KB (개발 PC 실측 6912KB)"
  if [ "${s:-0}" -lt 5000 ] 2>/dev/null; then
    bad "OCR 폴더가 ${s:-0}KB 뿐이다 — 자료가 덜 담겼다"
  fi
}

# ══════════════════════════════════════════════════════════════════════
#  권한 — 🔴 **읽기만 한다. 어떤 모드에서도 이 표를 고치지 않는다.**
# ══════════════════════════════════════════════════════════════════════
PERM_SQL_COUNT="select count(*) from $PERM_TABLE"
PERM_SQL_AREA="select role, area_key, level, updated_at::date from $PERM_TABLE where area_key in ('$PERM_AREA_CASE', '$PERM_AREA_FILES', '$PERM_AREA_QUOTE') order by area_key, role"

perm_check() {
  local reg n_all n_case n_files n_quote
  if ! pg_up; then
    say "  · dss-pg-app 이 떠 있지 않다 — 권한을 못 봤다(✗ 는 아니다)"
    return 0
  fi
  reg=$(qas "select to_regclass('public.$PERM_TABLE')")
  if [ -z "$reg" ]; then
    say "  · $AS_DB 에 $PERM_TABLE 표가 없다 — 🔴 첫 설치가 덜 된 DB 다"
    return 0
  fi
  ok "$AS_DB 에 $PERM_TABLE 표가 있다"
  say "  🔴 이 검사가 돌리는 SQL 은 아래 둘이 전부다. 둘 다 select 다:"
  say "      $PERM_SQL_COUNT"
  say "      $PERM_SQL_AREA"
  say
  n_all=$(qas "$PERM_SQL_COUNT")
  say "  · $PERM_TABLE 전체 줄: ${n_all:-?}  (0 이면 전부 코드의 기본 정책대로다)"
  n_case=$(qas  "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_CASE'")
  n_files=$(qas "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_FILES'")
  n_quote=$(qas "select count(*) from $PERM_TABLE where area_key = '$PERM_AREA_QUOTE'")
  say "  · $PERM_AREA_CASE 에 저장된 줄: ${n_case:-?}"
  say "  · $PERM_AREA_FILES 에 저장된 줄: ${n_files:-?}"
  say "  · $PERM_AREA_QUOTE 에 저장된 줄: ${n_quote:-?}"
  say
  say "  저장된 값 — 역할 전부:"
  qqas "$PERM_SQL_AREA" | sed 's/^/      /'
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔵 이번 판은 **새 권한을 만들지 않았습니다.**                   ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  if [ "${n_case:-0}" = 0 ] && [ "${n_files:-0}" = 0 ] && [ "${n_quote:-0}" = 0 ]; then
    say "     🔵 세 칸에 **저장된 줄이 하나도 없습니다.** 그러면 코드의 기본값이"
    say "        그대로 삽니다 — 지금 보이던 사람에게 그대로 보입니다."
  else
    say "     🔴 저장된 줄이 있습니다. 위 표를 보세요 — **저장된 값이 코드의"
    say "        기본값을 이깁니다.** 그 칸이 NONE 인 역할에게는 이번에 고친 것이"
    say "        **보이지 않습니다**(그 화면 자체가 안 열립니다):"
    say "        · $PERM_AREA_QUOTE — 견적서 화면([Excel 보기] · 결재 탭)"
    say "        · $PERM_AREA_CASE  — 수리 건 상세(고객 안내 현황 · 보고서 탭)"
    say "        · $PERM_AREA_FILES — 파일 관리"
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  .env 읽기 — 🔴 **읽기만 한다. 이 스크립트는 .env 를 한 글자도 안 고친다.**
# ══════════════════════════════════════════════════════════════════════
env_val_of() { # 1 파일 2 키  → 값 (없으면 빈 문자열)
  local v
  [ -f "$1" ] || return 0
  v=$(sed -n "s/^$2=//p" "$1" | head -1 | tr -d '\r')
  v=${v#\"}; v=${v%\"}
  v=${v#\'}; v=${v%\'}
  printf '%s' "$v"
}
env_count_of() { # 1 파일 2 키 → 그 이름으로 시작하는 줄 수
  [ -f "$1" ] || { echo 0; return 0; }
  grep -c "^$2=" "$1" 2>/dev/null | tr -d ' '
}
# 🔴 「있는가」만 본다. 없으면 ✗ — 앞 배포가 제대로 안 돈 것이다.
env_keys_present() { # 1 파일 2 라벨 3 "키 …" 4 없을때할말
  local f="$1" label="$2" keys="$3" why="$4" k n
  for k in $keys; do
    n=$(env_count_of "$f" "$k")
    if [ "${n:-0}" = 0 ]; then
      bad "$label · $k 가 **없다** — 🔴 $why"
    elif [ "${n:-0}" -gt 1 ] 2>/dev/null; then
      bad "🔴 $label · $k 가 **두 줄 이상** 있다 — 먼저 그것부터 고쳐야 한다"
      say "      보기:  grep -n '^$k=' $f"
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
EXP_AS=""
EXP_PO=""
SVCS=""
AS_DBURL=""; PO_DBURL=""

see_tar() { # 1 태그 2 tar 3 tar에서읽은지문 4 기대바이트 5 기대md5 6 기대지문 7 올릴파일이름
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
  local tag s p rec t f db n_bk nlog k
  local FREE_KB FREE_H code h nb v1 v2

  # ── 1-ㄱ. 올릴 파일 — 이미지 tar **둘**뿐 ───────────────────────────
  step "1-ㄱ. 올린 파일 (이미지 tar **둘** · compose 하나. 그것이 전부다)"
  say "  🔵 21번은 **다섯**이었다 — tar 둘 · compose · **양식 두 벌**."
  say "     🔴 이번엔 **셋**이다. **양식은 이번엔 없다**(21번이 이미 바꿨고,"
  say "        그 폴더는 호스트에 있어 컨테이너를 다시 띄워도 안 바뀐다)."
  say "     🔴 **마이그레이션 묶음도 이번엔 없다**(20 · 21번과 같다)."
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  EXP_PO=$(tar_config_id "$TAR_PO" 2>/dev/null) || EXP_PO=""
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS" "$SZ_AS" "$MD5_AS" "$WANT_CFG_AS" dss-as-2.5.tar
  see_tar "$TAG_PO" "$TAR_PO" "$EXP_PO" "$SZ_PO" "$MD5_PO" "$WANT_CFG_PO" dss-po-0.5.tar
  say "  🔵 이번 판은 **정규식 한 줄**만 바뀌었다 — tar 크기가 2.4(131,237,888) ·"
  say "     0.4(95,424,000)와 **거의 같은 것이 정상**이다."

  # ── 1-ㄴ. NAS 에 실린 이미지 ─────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (올라가는 둘 · 건드리지 않는 여덟)"
  if have_img "$TAG_AS"; then
    [ -n "$EXP_AS" ] && { verify_img "$TAG_AS" "$EXP_AS" || force_load_hint "$TAG_AS"; }
  else
    notloaded "$TAG_AS 는 아직 NAS 에 실리지 않았다 — --preload 나 --go 가 싣는다"
  fi
  if have_img "$TAG_PO"; then
    [ -n "$EXP_PO" ] && { verify_img "$TAG_PO" "$EXP_PO" || force_load_hint "$TAG_PO"; }
  else
    notloaded "$TAG_PO 는 아직 NAS 에 실리지 않았다 — --preload 나 --go 가 싣는다"
  fi
  say "  🔴 지문이 어긋나면 **혼자 고쳐지지 않는다.** 태그가 같으면 docker load 를"
  say "     그냥 부르는 것으로는 안 바뀐다 — 위에 찍힌 --force-load 를 쓰세요."
  say "  🔴 건드리지 않는 여덟 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for tag in "$KEEP_AUTH" "$KEEP_ASTOOLS" "$KEEP_METERS" "$KEEP_METERSTOOLS" \
             "$KEEP_IMP" "$KEEP_IMPTOOLS" "$KEEP_LEAVE" "$KEEP_LEAVETOOLS"; do
    have_img "$tag" && ok "$tag 실려 있다 ($(img_id "$tag" | cut -c1-19)…)" \
      || bad "$tag 가 NAS 에 없다 — 🔴 앞 배포가 되돌아갔거나 누가 지웠다"
  done
  say "  🔴 되돌아갈 옛 이미지 둘도 그대로 둔다 — 되돌리기가 그것을 쓴다."
  have_img "$OLD_AS" && ok "$OLD_AS 도 아직 있다 (되돌릴 길이 열려 있다)" \
    || say "    ⚠️ $OLD_AS 가 NAS 에 없다 — 되돌리려면 tar 를 다시 올려야 한다"
  have_img "$OLD_PO" && ok "$OLD_PO 도 아직 있다 (되돌릴 길이 열려 있다)" \
    || say "    ⚠️ $OLD_PO 가 NAS 에 없다 — 되돌리려면 tar 를 다시 올려야 한다"

  # ── 1-ㄷ. 권한 — 🔴 읽기만 한다 ──────────────────────────────────────
  step "1-ㄷ. 고친 화면이 **누구 눈에** 보이는가 (운영 DB 를 읽는다)"
  say "  🔴 「권한은 코드가 아니라 운영 DB 가 정한다」 — 그래서 읽어 보고 말한다."
  say "     🔵 이번 판은 **새 권한을 하나도 만들지 않았다.**"
  perm_check

  # ── 1-ㄹ. 🔴 as.env · po.env — **있는가만 본다** ─────────────────────
  step "1-ㄹ. as.env · po.env — 🔴 **있는가만 본다. 이번엔 한 줄도 안 적는다**"
  say "  🔵 21번은 여기서 **일곱 줄을 덧붙였다**(as.env 둘 · po.env 다섯)."
  say "     🔴 **이번엔 없다** — 새 설정이 하나도 없다. 덧붙이는 코드를 전부"
  say "        걷어냈고, 그 일곱 줄이 **아직 거기 있는지만** 센다."
  say "     🔴 없으면 ✗ 다 — **21번이 제대로 안 돈 것**이고, 그때는 배포보다"
  say "        그것이 먼저다."
  say "  🔴 이 PC(dss-deploy)의 nas/env/*.env 를 NAS 로 **올리지 마세요.**"
  say "     그 사본에는 NAS 에만 있는 줄들이 빠져 있습니다."
  if [ -f "$AS_ENV" ]; then
    s=$(stat -c '%a' "$AS_ENV" 2>/dev/null)
    [ "$s" = 600 ] && ok "as.env 있다 · 모드 600" \
      || bad "as.env 의 모드가 ${s:-?} 다 (600 이어야 한다 — 남이 읽는다)"
    s=$(stat -c '%U:%G' "$AS_ENV" 2>/dev/null)
    [ "$s" = "root:root" ] || bad "as.env 의 주인이 ${s:-?} 다 (root:root 이어야 한다)"
    for t in DATABASE_URL UPLOADS_DIR PORT; do
      grep -q "^$t=" "$AS_ENV" && bad "as.env 에 $t 가 **있다** — 지우세요(compose 가 넘긴다)"
    done
    say "  🔴 견적서 세 줄 — 사라지면 [폴더 열기]가 죽는다:"
    env_keys_present "$AS_ENV" "as.env" "$QUOTE_KEYS" "누가 as.env 를 덮어썼다"
    say "  🔴 현황표 다섯 줄 (16번이 넣었다):"
    env_keys_present "$AS_ENV" "as.env" "$PORTAL_KEYS" "[공유폴더에 저장]이 실패로 끝난다"
    say "  🔴 연락서 세 줄 (18번이 넣었다):"
    env_keys_present "$AS_ENV" "as.env" "$CONTACT_KEYS" "연락서 [폴더 열기]가 죽는다"
    say "  🔴 수리 관련 두 줄 (19번이 넣었다):"
    env_keys_present "$AS_ENV" "as.env" "$REPAIR_KEYS" "「가리킨 서류」 고르는 창이 죽는다"
    say "  🔴 발주서 두 줄 — **21번이 몇 시간 전에 넣은 것**이다:"
    env_keys_present "$AS_ENV" "as.env" "$PO_ARCHIVE_KEYS" "발주서 탭이 죽는다 — 21번이 제대로 안 돌았다"
    say "  🔵 발주서 두 줄의 값(폴더 경로라 비밀이 아니다 — 눈으로 보세요):"
    for k in $PO_ARCHIVE_KEYS; do
      printf '      as.env  %s\n' "$(grep "^$k=" "$AS_ENV" | head -1)"
    done
  else
    bad "as.env 가 없다: $AS_ENV"
    say "    → 없는 env_file 하나면 docker compose 명령이 **통째로** 안 먹는다."
  fi
  for f in po.env auth.env meters.env improvements.env leave.env; do
    [ -f "$ENVD/$f" ] || bad "$f 가 없다: $ENVD/$f (compose 가 통째로 실패한다)"
  done
  if [ -f "$PO_ENV" ]; then
    s=$(stat -c '%a' "$PO_ENV" 2>/dev/null)
    [ "$s" = 600 ] && ok "po.env 있다 · 모드 600" \
      || bad "po.env 의 모드가 ${s:-?} 다 (600 이어야 한다)"
    s=$(stat -c '%U:%G' "$PO_ENV" 2>/dev/null)
    [ "$s" = "root:root" ] || bad "po.env 의 주인이 ${s:-?} 다 (root:root 이어야 한다)"
    say "  🔴 도우미 설치본의 루트 넷 — **21번이 po.env 에 넣은 것**이다:"
    env_keys_present "$PO_ENV" "po.env" "$PO_REQUIRED_KEYS" \
      "PO 에서 설치한 도우미가 그 폴더를 못 연다 — 21번이 제대로 안 돌았다"
    say "  🔵 다섯째 줄($PO_ALT_KEY)은 **선택값**이다 — 도우미가 빈 값을 건너뛴다."
    say "     규칙은 21번 그대로: **as.env 를 비춘다**(줄이 있으면 po.env 에도 있어야)."
    v1=$(env_count_of "$AS_ENV" "$PO_ALT_KEY")
    v2=$(env_count_of "$PO_ENV" "$PO_ALT_KEY")
    if [ "${v1:-0}" = 0 ] && [ "${v2:-0}" = 0 ]; then
      ok "$PO_ALT_KEY — 양쪽 다 줄이 없다 (설치본은 여전히 같다)"
    elif [ "${v1:-0}" -ge 1 ] && [ "${v2:-0}" -ge 1 ] 2>/dev/null; then
      ok "$PO_ALT_KEY — 양쪽 다 줄이 있다"
    else
      bad "🔴 $PO_ALT_KEY 가 **한쪽에만** 있다 (as.env ${v1:-0}줄 · po.env ${v2:-0}줄)"
    fi
    say "  🔴 다섯이 as.env 와 **글자까지 같은가** (파일로 본다):"
    for k in $PO_HELPER_KEYS; do
      if [ "$(env_count_of "$AS_ENV" "$k")" = 0 ] && [ "$(env_count_of "$PO_ENV" "$k")" = 0 ]; then
        continue
      fi
      if [ "$(env_val_of "$AS_ENV" "$k")" = "$(env_val_of "$PO_ENV" "$k")" ]; then
        ok "$k 가 as.env 와 po.env 에서 **글자까지 같다**"
      else
        bad "🔴 $k 가 as.env 와 po.env 에서 **다르다** — 설치 화면에 따라 갈린다"
      fi
    done
    say "  🔴 역슬래시가 삼켜지지 않았는가 (UNC 는 넷 이상이어야 맞다):"
    for k in $PO_REQUIRED_KEYS; do
      nb=$(backslash_count "$(env_val_of "$PO_ENV" "$k")")
      [ "${nb:-0}" -ge 4 ] && ok "po.env · $k 의 역슬래시 ${nb}개" \
        || bad "po.env · $k 의 역슬래시가 ${nb:-0}개뿐이다 — 🔴 따옴표가 먹었다"
    done
  fi

  # ── 1-ㅁ. compose ───────────────────────────────────────────────────
  step "1-ㅁ. compose ($CF_EFF)"
  say "  🔴 이번 판에서 compose 가 바뀌는 자리는 **둘뿐**이다:"
  say "     ㄱ) app-as 의 image 한 줄 ($OLD_AS → $TAG_AS)"
  say "     ㄴ) app-po 의 image 한 줄 ($OLD_PO → $TAG_PO)"
  say "     🔵 21번에는 셋째가 있었다 — 발주서 볼륨 네 줄. **이번엔 없다**"
  say "        (그 볼륨은 이미 들어가 있다. 아래에서 **그대로 있는지**만 본다)."
  say "     다른 것이 흔들렸으면 남의 것이 섞인 것이다."
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
  see_tag() { # 1 서비스 2 태그 3 사람이 읽을 이름
    svc_block "$CF_EFF" "$1" | grep -q "image: $2$" \
      && ok "$1 가 $2 를 가리킨다 ($3)" \
      || bad "$1 의 태그가 $2 가 아니다 ($3) — 지금 값: $(svc_image "$CF_EFF" "$1")"
  }
  say "  올라가는 둘:"
  see_tag app-as "$TAG_AS" "A/S"
  see_tag app-po "$TAG_PO" "PO/내자"
  if [ "$(svc_image "$CF_EFF" app-as)" = "$OLD_AS" ]; then
    say "    🔴 compose 가 아직 **옛 태그**를 가리킵니다. 개발 PC 에서 고친 파일을"
    say "       아래에 올리면 --go 가 시험하고 제자리로 옮깁니다:"
    say "         $INCOMING"
  fi
  say "  🔴 건드리지 않는 여덟 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-auth            "$KEEP_AUTH"        "포털 · 그대로"
  see_tag tools-as            "$KEEP_ASTOOLS"     "A/S 도구 · 그대로"
  see_tag app-meters          "$KEEP_METERS"      "계측기 · 그대로"
  see_tag tools-meters        "$KEEP_METERSTOOLS" "계측기 도구 · 그대로"
  see_tag app-improvements    "$KEEP_IMP"         "개선요청 · 그대로"
  see_tag tools-improvements  "$KEEP_IMPTOOLS"    "개선요청 도구 · 그대로"
  see_tag app-leave           "$KEEP_LEAVE"       "휴가 · 그대로"
  see_tag tools-leave         "$KEEP_LEAVETOOLS"  "휴가 도구 · 그대로"
  # 🔴 볼륨은 **하나도 더하지 않는다.** 전부 「사라지지 않았는가」만 본다.
  svc_block "$CF_EFF" app-as | grep -q "$ATT:/data" \
    && ok "app-as 가 $ATT 를 붙인다" \
    || bad "app-as 의 첨부 볼륨이 $ATT 가 아니다 — 🔴 첨부가 사라진다"
  svc_block "$CF_EFF" app-po | grep -q "$ATT:/data" \
    && ok "app-po 가 A/S 와 **같은 첨부 폴더**($ATT)를 붙인다" \
    || bad "app-po 의 첨부 볼륨이 $ATT 가 아니다 — 🔴 서로의 파일을 못 찾는다"
  for s in app-as app-po; do
    svc_block "$CF_EFF" "$s" | grep -q "$TEMPLATES:/templates" \
      && ok "$s 가 양식 폴더($TEMPLATES)를 읽기 전용으로 붙인다" \
      || bad "$s 의 양식 볼륨이 $TEMPLATES 가 아니다 — 🔴 견적서 출력이 죽는다"
    svc_block "$CF_EFF" "$s" | grep -q '/quote-archive' \
      && ok "$s 가 견적서 공유폴더(/quote-archive)를 붙인다" \
      || bad "$s 에 견적서 공유폴더가 안 붙어 있다 — 🔴 발행이 실패한다"
    svc_block "$CF_EFF" "$s" | grep -q 'group_add' \
      && ok "$s 에 group_add 가 있다 (공유폴더의 ACL 때문이다)" \
      || bad "$s 에 group_add 가 없다 — 🔴 공유폴더에 Permission denied 가 난다"
  done
  svc_block "$CF_EFF" app-as | grep -q "target: $PORTAL_MNT" \
    && ok "app-as 가 현황표 공유폴더($PORTAL_MNT)를 그대로 붙인다 (16번이 붙인 것)" \
    || bad "app-as 에서 $PORTAL_MNT 가 **사라졌다** — 🔴 [공유폴더에 저장]이 죽는다"
  svc_block "$CF_EFF" app-as | grep -q "target: $CONTACT_MNT" \
    && ok "app-as 가 연락서 공유폴더($CONTACT_MNT)를 그대로 붙인다 (18번이 붙인 것)" \
    || bad "app-as 에서 $CONTACT_MNT 가 **사라졌다** — 🔴 연락서 연동이 죽는다"
  # 🔴 연락서는 **쓸 수 있어야** 한다 — 거기에 read_only 가 붙으면 안 된다.
  svc_block "$CF_EFF" app-as | line_after "target: $CONTACT_MNT" | grep -q 'read_only' \
    && bad "🔴 연락서 볼륨에 read_only 가 붙었다 — 폴더 만들기·사본 꽂기가 죽는다" \
    || ok "연락서 볼륨은 그대로 **쓸 수 있다** (read_only 가 없다)"
  svc_block "$CF_EFF" app-as | grep -q "target: $REPAIR_MNT" \
    && ok "app-as 가 「수리 관련」 공유폴더($REPAIR_MNT)를 그대로 붙인다 (19번이 붙인 것)" \
    || bad "app-as 에서 $REPAIR_MNT 가 **사라졌다** — 🔴 가리킨 서류가 통째로 꺼진다"
  svc_block "$CF_EFF" app-as | line_after "target: $REPAIR_MNT" | grep -q 'read_only: true' \
    && ok "🔴 $REPAIR_MNT 에 read_only: true 가 그대로 있다" \
    || bad "🔴 $REPAIR_MNT 의 read_only: true 가 **없어졌다** — 쓰기가 열린 채로 돈다"
  # ── 🔴 발주서 볼륨 — **21번이 붙인 것이 그대로 있는가** ─────────────
  say "  🔴 발주서 공유폴더 — 🔵 **이번에 더하는 것이 아니다.** 21번이 붙였고,"
  say "     compose 를 다시 올리므로 **사라지지 않았는지**를 본다:"
  svc_block "$CF_EFF" app-as | grep -q "target: $PO_MNT" \
    && ok "app-as 가 $PO_MNT 를 그대로 붙인다 (21번이 붙인 것)" \
    || bad "app-as 에서 $PO_MNT 가 **사라졌다** — 🔴 발주서 탭이 통째로 꺼진다"
  svc_block "$CF_EFF" app-as | grep -qF "source: \"$PO_SRC\"" \
    && ok "원본 경로가 글자까지 그대로다 (🔴 5_ 외자 **PO** — 대문자)" \
    || bad "원본 경로가 기대와 다르다 — 🔴 「5_ 외자 PO」 의 **대소문자**부터 보세요"
  svc_block "$CF_EFF" app-as | line_after "target: $PO_MNT" | grep -q 'read_only: true' \
    && ok "🔴 $PO_MNT 에 read_only: true 가 그대로 있다" \
    || bad "🔴 $PO_MNT 의 read_only: true 가 **없어졌다** — 쓰기가 열린 채로 돈다"
  svc_block "$CF_EFF" app-as | grep -q "type: bind" \
    && ok "긴 문법(type: bind)으로 적혀 있다 (경로에 공백이 있다)" \
    || bad "긴 문법이 아니다 — 🔴 짧은 문법은 이 경로에서 깨진다"
  svc_block "$CF_EFF" app-po | grep -q "$PO_MNT" \
    && say "    ⚠️ app-po 에도 $PO_MNT 가 붙어 있다 — PO 에는 이 화면이 없다(없어도 된다)" \
    || ok "app-po 에는 안 붙었다 (맞다 — PO 저장소에 이 화면이 없다)"
  svc_block "$CF_EFF" app-as | grep -q "$AS_PORT:3000" \
    && ok "app-as 가 127.0.0.1:$AS_PORT 으로 열린다" \
    || bad "app-as 의 포트가 $AS_PORT:3000 이 아니다"
  svc_block "$CF_EFF" app-po | grep -q "$PO_PORT:3600" \
    && ok "app-po 가 127.0.0.1:$PO_PORT 으로 열린다" \
    || bad "app-po 의 포트가 $PO_PORT:3600 이 아니다"
  # 🔴 사내 전용 원칙 — DB 에 ports: 를 더하지 않는다. 더해졌으면 남의 것이다.
  svc_block "$CF_EFF" db-app | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-app 에 ports: 가 생겼다 — 사내 전용 원칙을 깬다. 고치지 말고 알리세요" \
    || ok "db-app 에 ports: 가 없다 (DB 는 호스트 포트를 하나도 안 연다)"
  svc_block "$CF_EFF" db-auth | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-auth 에 ports: 가 생겼다 — 고치지 말고 알리세요" \
    || ok "db-auth 에 ports: 가 없다"
  AS_DBURL=$(svc_block "$CF_EFF" app-as | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  PO_DBURL=$(svc_block "$CF_EFF" app-po | sed -n 's/^[[:space:]]*DATABASE_URL:[[:space:]]*//p' | head -1)
  if [ -n "$PO_DBURL" ] && [ "$AS_DBURL" = "$PO_DBURL" ]; then
    ok "app-po 의 DATABASE_URL 이 app-as 와 **글자까지 같다**"
    say "    🔵 둘은 같은 DB 와 같은 첨부 폴더를 쓴다. 이번 판은 **DB 를 안 바꾸므로**"
    say "       표도 칸도 그대로다 — 둘을 함께 올리는 것이 오히려 단순하다."
  else
    bad "app-po 의 DATABASE_URL 이 app-as 와 다르다 — 🔴 PO 가 엉뚱한 DB 를 본다"
  fi

  # ── 1-ㅂ. 폴더를 컨테이너 안에서 **실제로 열어 본다** ────────────────
  step "1-ㅂ. 폴더 — 주인·모드가 아니라 컨테이너 안에서 실제로 연다"
  say "  🔵 21번에는 「새로 붙는 자리」가 있어 임시 컨테이너를 띄워야 했다."
  say "     🔴 **이번엔 없다** — 다섯 자리가 전부 **지금 붙어 돌고 있다.**"
  say "        그래서 전부 **도는 컨테이너 안에서** 본다."
  if [ "$PROBE_WRITE" = 1 ]; then
    say "  (교체되는 A/S 의 /data 는 읽기+쓰기를 본다. 시험 파일은 만들었다 지운다.)"
  else
    say "  🔵 --check 라서 /data 는 **읽기만** 해 본다 — 아무 파일도 만들지 않는다."
  fi
  if [ -d "$PO_SRC" ]; then
    ok "호스트에 발주서 폴더가 있다"
  else
    bad "호스트에 발주서 폴더가 **없다**"
    say "    → 🔴 「5_ 외자 PO」 의 **PO 가 대문자**인지 보세요."
    cmd "ls -d /volume1/5_*"
  fi
  if [ "$PROBE_WRITE" = 1 ]; then M_DATA=rw; else M_DATA=ro; fi
  probe_svc app-as dss-as "A/S" "/data:$M_DATA /templates:ro" "$ATT $TEMPLATES"
  probe_svc app-po           dss-po           PO       "/data:ro"         "$ATT"
  probe_svc app-meters       dss-meters       계측기   "/data:ro"         "$MF_METERS"
  probe_svc app-improvements dss-improvements 개선요청 "/data/uploads:ro" "$UP_IMP"
  # 🔴 공유폴더들은 위 틀에 안 넣는다 — 경로에 빈칸과 한글이 있고, 무엇보다
  #    여기서는 ACL 을 **걷으면 안 된다**(직원의 탐색기 접근이 끊긴다).
  say "  공유폴더 다섯 — 🔴 읽기만 본다. ACL 을 걷지 않는다:"
  for rec in "dss-as|A/S|/quote-archive" "dss-po|PO|/quote-archive" \
             "dss-as|A/S|$PORTAL_MNT" "dss-as|A/S|$CONTACT_MNT" \
             "dss-as|A/S|$REPAIR_MNT" "dss-as|A/S|$PO_MNT"; do
    s=$(printf '%s' "$rec" | cut -d'|' -f1)
    p=$(printf '%s' "$rec" | cut -d'|' -f2)
    t=$(printf '%s' "$rec" | cut -d'|' -f3)
    if running "$s"; then
      "$DOCKER" exec "$s" sh -c "ls -1 '$t' >/dev/null 2>&1" \
        && ok "$p 가 $t 를 읽는다" \
        || { bad "$p 가 $t 를 **못 읽는다**"
             say "      🔴 여기는 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기가 끊긴다."
             say "         compose 의 $s 쪽에 group_add 가 있는지부터 보세요."; }
    else
      say "  · $s 가 안 돌고 있어 $t 를 못 봤다"
    fi
  done
  # 🔴 발주서 · 수리 관련은 **읽기 전용이 아직 살아 있는가** — 쓰지 않고 읽어서 본다.
  say "  🔴 읽기 전용 둘이 **아직 읽기 전용인가** (/proc/mounts 를 읽는다. 안 쓴다):"
  if running dss-as; then
    ro_mount_check dss-as "$REPAIR_MNT" "수리 관련"
    ro_mount_check dss-as "$PO_MNT" "발주서"
    mnt_count_check dss-as "$PO_MNT" "발주서" 1
  else
    say "  · dss-as 가 안 돌고 있어 마운트 옵션을 못 봤다"
  fi

  # ── 1-ㅅ. 🔴 야간 백업 · 야간 완전삭제 (읽기만 한다) ─────────────────
  step "1-ㅅ. 야간 백업 다섯 · 야간 완전삭제 (읽기만 한다)"
  say "  🔵 이번 판은 **DB 를 바꾸지 않는다**(마이그레이션 0건)."
  say "     🔴 그래도 --go 는 오늘 뜬 $AS_DB 백업이 없으면 **시작조차 않는다**(3-ㄱ)."
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
    say "    🔴 그중 **$AS_DB 가 없으면 --go 는 시작조차 하지 않는다.**"
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
  if pg_up && running dss-pg-auth; then
    ok "DB 둘 다 떠 있다 (이 배포에서 DB 컨테이너는 멈추지 않는다)"
  else
    bad "DB 가 떠 있지 않다"
  fi
  for t in dss-auth dss-as dss-meters dss-improvements dss-po dss-leave; do
    running "$t" && ok "$t 가 돌고 있다" || bad "$t 가 안 돌고 있다"
  done
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  # 새 tar 둘(약 125MB + 95MB) + 실은 이미지 둘(약 590MB + 450MB).
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (tar 둘 + 실은 이미지 둘이 들어가야 한다)"
  fi

  # ── 1-ㅈ. 알림 링크의 주소 — A/S 만 ─────────────────────────────────
  step "1-ㅈ. 알림 링크의 주소 (통로가 아니라 **나오는 주소**를 본다)"
  say "  🔴 **A/S 하나만 본다.** PO 에는 알림 통로가 아예 없다."
  notify_href_check "A/S" dss-as "$AS_ENV" "https://as.dss21.co.kr"

  # ── 1-ㅋ. 새 이미지 **안에** 이번 판이 들어 있는가 ───────────────────
  step "1-ㅋ. 새 이미지 안을 본다 — 🔴 글자로 보고, 그 다음 **값으로** 본다"
  say "  🔴 9/21~9/29 에 A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다."
  say "  🔵 이번 판은 **새 파일이 0개**라 모듈 경로로는 못 가린다(2.4 에도 다 있다)."
  say "     그래서 20번처럼 **내용 짝**으로 가리고, 🔴 그 위에 **값으로 재기**를 더한다."
  if have_img "$TAG_AS"; then
    say "  $TAG_AS 구운 때: $("$DOCKER" images "$TAG_AS" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_AS" --format '{{.Size}}' 2>/dev/null) ($OLD_AS 는 590MB 였다)"
    inside_check "$TAG_AS" "A/S" "$OLD_AS" "$AS_KEEP1" "$AS_KEEP2"
    number_probe image "$TAG_AS" "A/S" "$OLD_AS"
    say "  🔵 글자 인식기(public/ocr) 회귀 검사 — 2.4 의 것이 그대로 있는가:"
    ocr_check "$TAG_AS"
  else
    notloaded "$TAG_AS 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
  fi
  if have_img "$TAG_PO"; then
    say "  $TAG_PO 구운 때: $("$DOCKER" images "$TAG_PO" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_PO" --format '{{.Size}}' 2>/dev/null)"
    inside_check "$TAG_PO" "PO" "$OLD_PO" "$PO_KEEP1" "$PO_KEEP2"
    number_probe image "$TAG_PO" "PO" "$OLD_PO"
    say "  🔵 PO 에는 public/ 이 없다 — OCR 검사를 하지 않는다(그것이 맞다)."
  else
    notloaded "$TAG_PO 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
  fi

  # ── 1-ㅌ. 바깥 주소 여섯 ────────────────────────────────────────────
  step "1-ㅌ. 바깥 주소 여섯 (지금 상태를 적어 둔다)"
  for h in login as meters improvements po leave; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$h.dss21.co.kr → $code" ;;
      *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
    esac
  done
}

# ══════════════════════════════════════════════════════════════════════
#  compose 갈아 끼우기
#
#  🔴 --check 는 **갈아 끼우지 않는다.** 읽기만 한다는 약속이 먼저다.
#  🔴 바꾸기 **전에** 새 파일을 먼저 시험한다. 없는 env_file 하나면 docker
#     compose 명령이 **통째로** 실패해서, 앱을 멈춘 뒤에 그걸 알게 되면 다시
#     띄우지도 못한다.
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
  # 🔴 이번 판은 **image 두 줄**만 달라야 한다.
  say "  🔵 지금 것과 달라진 줄 — 🔴 **image 둘뿐이어야 한다**:"
  say "     (21번은 여기에 발주서 볼륨 네 줄이 더 있었다. **이번엔 없다.**"
  say "      볼륨 줄이 보이면 남의 변경이 섞인 것이다 — 고치지 말고 알리세요.)"
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
if [ "$MODE" = rollback ]; then
  echo "DSS 열여덟째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     되돌리는 것은 **이미지 둘**이다:"
  say "       $TAG_AS → $OLD_AS"
  say "       $TAG_PO → $OLD_PO"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔵 되돌릴 것이 **이미지 둘뿐**입니다. 이번 판은 가장 가벼웠다.  ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     · DB — 바꾼 적이 없다(마이그레이션 0건. 운영 DB 는 **115 그대로**)"
  say "     · .env — 🔵 **이번엔 한 줄도 안 적었다**(21번이 적은 일곱 줄은 그대로 둔다)"
  say "     · 양식 — 🔵 **이번엔 안 바꿨다**(21번이 바꾼 그대로 둔다)"
  say "     · 볼륨 — 🔵 **이번엔 안 더했다**(21번이 붙인 발주서 볼륨은 그대로 둔다)"
  say
  say "  🔴 **compose 는 사본으로 되돌린다.** 이번 판은 compose 가 **태그 둘만**"
  say "     다르므로 사실 sed 로 내려도 같지만, 사본을 쓰는 규율은 그대로 지킨다"
  say "     (손으로 고치다 **다른 줄을 건드린** 일이 실제로 있었다)."
  say
  say "  🔴 되돌리면 **이번에 고친 결함이 되살아난다** — 2026-095-1R1 처럼 가지와"
  say "     개정이 함께 붙은 번호에서 [Excel 보기]가 「저장된 파일이 없습니다」로,"
  say "     결재 탭 공유폴더가 **빈 채로** 돌아간다. 🔵 자료는 그대로다."
  say

  step "1. 옛 이미지가 아직 NAS 에 있는지 먼저 본다"
  have_img "$OLD_AS" && ok "$OLD_AS 있다 ($(img_id "$OLD_AS" | cut -c1-19)…)" \
    || bad "$OLD_AS 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"
  have_img "$OLD_PO" && ok "$OLD_PO 있다 ($(img_id "$OLD_PO" | cut -c1-19)…)" \
    || bad "$OLD_PO 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"

  step "2. compose 를 사본으로 되돌린다"
  say "  --go 가 옛 compose 를 아래에 남겼다 (가장 최근 것):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -3 | sed 's/^/      /'
  cmd "cd /volume1/dss/deploy"
  cmd "cp \$(ls -1t ../backups/docker-compose.nas.yml.* | head -1) ."
  say "      (파일 이름이 길면 위 한 줄 대신 두 줄로 나눠 치세요)"
  cmd "grep -n 'image: dss-as\\|image: dss-po' docker-compose.nas.yml"

  step "3. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-as app-po"
  script_file_hint "22-rollback"

  step "4. 🔴 사람에게 알릴 것"
  say "  · 🔴 가지+개정 번호(2026-095-1R1 꼴)에서 [Excel 보기]가 다시 **안 열린다.**"
  say "  · 🔴 그 번호의 결재 탭 공유폴더가 다시 **빈 채로** 보인다."
  say "  · [고객 안내 현황]·[주간보고]의 그 칸이 다시 **옛 번호**로 돌아간다."
  say "  · 🔵 **그 밖에는 아무것도 안 달라진다** — 21번이 넣은 발주서 탭 · 저장 PDF ·"
  say "    공유폴더 구역 · 승인 체크 · 새 양식은 **그대로 남는다.**"
  say "  · 🔵 **도우미는 그대로 두세요.** 이번 판은 도우미를 한 글자도 안 바꿨다."

  step "5. 지금 상태"
  say "  dss-as : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep '^dss-as ' || echo '안 돌고 있다')"
  say "  dss-po : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep '^dss-po ' || echo '안 돌고 있다')"
  say "  (포털 · 계측기 · 개선요청 · 휴가 · DB 둘은 이번에 건드리지 않았다.)"
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터 check · preload · force-load · go ═════════════════════════
echo "DSS 열여덟째 배포 · 2026-10-12 (오늘 **두 번째**) · $(date '+%F %T')"
echo "  🔴 올라가는 것은 **둘**:  $OLD_AS → $TAG_AS · $OLD_PO → $TAG_PO"
echo "  🔴 멈추는 것도 **둘**:  dss-as · dss-po"
echo "  🔴 이번 판은 **결함 하나를 고친 판**이다 — 견적서 번호를 읽는 정규식 한 줄."
echo "     가지(-1)와 개정(R1)이 **함께 붙은 번호**(2026-095-1R1)를 통째로 못 읽었다."
echo "     그 번호의 건에서 [Excel 보기]가 「저장된 파일이 없습니다」였고,"
echo "     결재 탭 공유폴더가 **빈 채로** 보였다. 🔵 자료는 멀쩡하다 — 읽는 쪽만 틀렸다."
echo "  🔵 **마이그레이션 0건** · **새 볼륨 없음** · **.env 0줄** · **양식 교체 없음**"
echo "     — 21번에서 그 넷을 전부 걷어낸 **가장 가벼운 판**이다."
echo "  🔵 도구 이미지 그대로 ($KEEP_ASTOOLS — 이번엔 할 일 자체가 없다)"
echo "  🔵 야간 백업은 **02:30** — 자정 넘어 돌리면 백업 검사에 걸립니다"
echo "  · 건드리지 않는 여덟 — $KEEP_AUTH · $KEEP_ASTOOLS · $KEEP_METERS"
echo "    · $KEEP_METERSTOOLS · $KEEP_IMP · $KEEP_IMPTOOLS"
echo "    · $KEEP_LEAVE · $KEEP_LEAVETOOLS"
if ! pinned; then
  echo "  ⚠️ 🔴 **이미지 기대값 여섯이 비어 있습니다.**"
  echo "     개발 PC 에서 2.5 · 0.5 를 굽고 재어 채우기 전에는 --go 가 시작하지 않습니다."
  echo "     재는 차례는 이 파일 머리말 「돌리기 전에 — 값 여섯을 채워야 한다」."
fi
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**"
              echo "     🔵 아직 안 온 것 · 안 실린 것은 ⚠️ 로만 말한다(✗ 가 아니다)." ;;
  preload)    echo "  🔵 --preload — 새 이미지 둘을 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — A/S · PO 를 교체한다. **DB 도 .env 도 양식도 안 바꾼다.**"
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(폴더 권한 · 백업)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "새 이미지 tar 둘 · 지문"
  EXP_AS=$(tar_config_id "$TAR_AS" 2>/dev/null) || EXP_AS=""
  EXP_PO=$(tar_config_id "$TAR_PO" 2>/dev/null) || EXP_PO=""
  see_tar "$TAG_AS" "$TAR_AS" "$EXP_AS" "$SZ_AS" "$MD5_AS" "$WANT_CFG_AS" dss-as-2.5.tar
  see_tar "$TAG_PO" "$TAR_PO" "$EXP_PO" "$SZ_PO" "$MD5_PO" "$WANT_CFG_PO" dss-po-0.5.tar
  if [ -s "$TAR_AS" ] && [ -n "$EXP_AS" ]; then
    bring_img "$TAG_AS" "$TAR_AS" "$EXP_AS"
  else
    bad "$TAG_AS 를 싣지 않았다 — tar 가 없거나 manifest.json 을 못 읽었다"
  fi
  if [ -s "$TAR_PO" ] && [ -n "$EXP_PO" ]; then
    bring_img "$TAG_PO" "$TAR_PO" "$EXP_PO"
  else
    bad "$TAG_PO 를 싣지 않았다 — tar 가 없거나 manifest.json 을 못 읽었다"
  fi

  # 🔴 실어 놓고 **안을 본다.** 글자로 한 번, **값으로** 한 번.
  step "새 이미지 안에 이번 판이 들어 있는가 (글자 · 그리고 **값**)"
  if have_img "$TAG_AS"; then
    inside_check "$TAG_AS" "A/S" "$OLD_AS" "$AS_KEEP1" "$AS_KEEP2"
    number_probe image "$TAG_AS" "A/S" "$OLD_AS"
    ocr_check "$TAG_AS"
  fi
  if have_img "$TAG_PO"; then
    inside_check "$TAG_PO" "PO" "$OLD_PO" "$PO_KEEP1" "$PO_KEEP2"
    number_probe image "$TAG_PO" "PO" "$OLD_PO"
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
compose_incoming || stop "compose 를 바꾸지 않았습니다. 앱은 그대로 돕니다."
run_checks

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  if [ "$FAIL" = 0 ]; then
    if pinned; then
      echo "  ✅ 이어서 (A/S · PO 가 잠깐 멈춥니다. 그 밖엔 아무것도 안 바뀝니다):"
      echo "       bash $0 --go"
      echo "     🔴 --go 는 오늘 백업($AS_DB)이 없으면 **시작하자마자 멈춥니다.**"
      echo "     🔵 야간 백업은 02:30 입니다 — 먼저 손으로 뜨려면:"
      echo "          bash /volume1/dss/jobs/backup-nightly.sh"
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
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 바꾸지 않았고 앱은 살아 있습니다.**"
pinned || {
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 이미지 기대값 여섯이 **비어 있습니다.** 재지 않은 이미지를    ║"
  say "  ║    운영에 올리지 않습니다.                                     ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  stop "아무것도 바꾸지 않았습니다. 앱도 DB 도 그대로입니다."
}

# ── 2. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ───────────
step "2. 새 이미지 둘 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
[ -n "$EXP_AS" ] || stop "A/S tar 에서 지문을 못 읽었습니다. **아무것도 바꾸지 않았습니다.**"
[ -n "$EXP_PO" ] || stop "PO tar 에서 지문을 못 읽었습니다. **아무것도 바꾸지 않았습니다.**"
bring_img "$TAG_AS" "$TAR_AS" "$EXP_AS" || {
  say "  🔴 A/S 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
}
bring_img "$TAG_PO" "$TAR_PO" "$EXP_PO" || {
  say "  🔴 PO 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
}

# ══ 3. 🔴 멈추기 전에 — 백업 · 스냅숏 · 시작 시각 ══════════════════════
#
# 🔴 여기까지가 「돌이킬 수 있는 자리」다. 앱은 아직 옛 판으로 **살아 있다.**
# 🔵 21번에는 여기에 둘이 더 있었다 — **.env 일곱 줄 적기**(3-ㄹ)와
#    **양식 두 벌 바꾸기**(3-ㅁ). 🔴 **이번엔 둘 다 없다.**

# ── 3-ㄱ. 🔴 오늘 백업을 **지금 다시** 찾는다. 없으면 멈춘다 ───────────
step "3-ㄱ. 🔴 오늘 백업을 **지금 다시** 찾는다 (없으면 여기서 멈춘다)"
BK_TODAY=$(ls -1t "$BKD/db/${AS_DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
if [ -n "$BK_TODAY" ] && [ -s "$BK_TODAY" ]; then
  ok "오늘 백업 — $(basename "$BK_TODAY") ($(du -h "$BK_TODAY" | cut -f1))"
else
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 오늘($TODAY) 뜬 $AS_DB 백업을 **지금 찾지 못했습니다.**      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     🔵 이번 판은 DB 를 바꾸지 않습니다. 그래도 **백업 없이 운영 이미지를"
  say "        갈아 끼우지 않습니다** — 17번에서 이 문이 사고를 막았습니다."
  cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  say "     ✓ $AS_DB 줄이 찍혀야 합니다. 그 뒤에 다시:"
  cmd "bash $0 --go"
  stop "백업 없이 교체하지 않습니다. **앱도 DB 도 그대로입니다.**"
fi

# ── 3-ㄴ. 첨부 하드링크 스냅숏 · .env 사본 둘 ──────────────────────────
#
# 🔵 **DB 덤프는 뜨지 않는다** — 이번 판은 DB 를 바꾸지 않는다(18 · 20 · 21번과 같다).
# 🔵 **.env 는 안 고치지만 사본은 그대로 남긴다** — 공짜이고, 뒷날 「그때 어땠나」를
#    묻는 자리가 실제로 있었다.
step "3-ㄴ. 첨부 하드링크 스냅숏 · .env 사본 둘 (DB 덤프는 뜨지 않는다)"
BK=$BKD/predeploy-$STAMP
mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
if [ -d "$ATT" ]; then
  cp -al "$ATT" "$BK/as-attachments" 2>/dev/null \
    && ok "첨부 스냅숏 (cp -al 하드링크 — 즉시 · 공간 0) → $BK" \
    || bad "첨부 스냅숏 실패"
else
  bad "첨부 폴더가 없다: $ATT"
fi
if [ -f "$AS_ENV" ]; then
  cp -p "$AS_ENV" "$BKD/as.env.$STAMP"; chmod 600 "$BKD/as.env.$STAMP"
  ok "as.env 사본 — backups/as.env.$STAMP (root 600 · 🔵 **고치지는 않는다**)"
else
  bad "as.env 가 없다: $AS_ENV"
  stop "설정 파일이 없습니다. **앱도 DB 도 그대로입니다.**"
fi
if [ -f "$PO_ENV" ]; then
  cp -p "$PO_ENV" "$BKD/po.env.$STAMP"; chmod 600 "$BKD/po.env.$STAMP"
  ok "po.env 사본 — backups/po.env.$STAMP (root 600 · 🔵 **고치지는 않는다**)"
else
  bad "po.env 가 없다: $PO_ENV"
  stop "설정 파일이 없습니다. **앱도 DB 도 그대로입니다.**"
fi
say "  🔵 공유폴더 다섯(견적서 · 현황표 · 연락서 · 수리 관련 · 발주서)은 **스냅숏을"
say "     뜨지 않는다** — 직원의 서류함이라 우리가 사본을 만들 자리가 아니다."
say "     NAS 의 야간 백업이 본다."
say "  🔵 양식 폴더도 건드리지 않는다 — **이번 판은 양식을 안 바꾼다.**"

# ── 3-ㄷ. 건드리지 않는 쪽의 **시작 시각**을 적어 둔다 ─────────────────
step "3-ㄷ. 건드리지 않는 쪽의 시작 시각을 적어 둔다 (뒤에서 대조한다)"
KEEP_BOXES="dss-auth dss-meters dss-improvements dss-leave dss-pg-app dss-pg-auth"
STARTED_BEFORE=""
for t in $KEEP_BOXES; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  STARTED_BEFORE="$STARTED_BEFORE$t=$s
"
  say "  · $t  시작 ${s:-?}"
done
say
say "  🔴 이제 A/S 와 PO 를 바꿔 끼웁니다. 그만두려면 **20초 안에 Ctrl+C**."
say "     지금 Ctrl+C 하면 직원은 $OLD_AS · $OLD_PO 를 그대로 쓰고 있습니다."
say "     (compose 는 이미 바뀌었지만 그것만으로는 아무 일도 일어나지 않습니다 —"
say "      옛 컨테이너가 그대로 돌고 있습니다.)"
sleep 20

# ══ 4. 둘을 새 판으로 바꿔 끼운다 — 🔴 여기 하나가 정지 창이다 ═════════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다. --no-deps 로 **이름을 적은 둘만** 부른다.
step "4. 새 이미지로 바꿔 끼운다 (A/S · PO)  ⏱ 여기부터 정지 창"
say "  🔴 **멈추는 것은 dss-as 와 dss-po 둘뿐이다.**"
say "     그대로 도는 것: 포털 · 계측기 · 개선요청 · 휴가 · DB 둘."
say "  🔵 둘을 **한 번에** 부른다 — 나눠 부르면 정지 창이 그만큼 길어진다."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"
"${COMPOSE[@]}" up -d --no-deps app-as app-po 2>&1 | sed 's/^/    /'
wait_http "A/S" "$AS_PORT" / dss-as
wait_http "PO"  "$PO_PORT" / dss-po
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 5. 스모크 ══════════════════════════════════════════════════════════
step "5. 스모크 — 폴더 · 🔴 **정규식** · 설정 · 알림 · 권한 · 안 멈췄는가 · 주소"

# 5-ㄱ. 새 컨테이너로 폴더를 **실제로 열어 본다**
say "  5-ㄱ. 폴더를 새 컨테이너 안에서 실제로 연다"
probe_svc app-as dss-as "A/S" "/data:rw /templates:ro" "$ATT $TEMPLATES"
probe_svc app-po dss-po "PO"  "/data:rw /templates:ro" "$ATT $TEMPLATES"

say "  5-ㄴ. 공유폴더 다섯 — 🔴 **그대로 붙어 있는가**(이번엔 더한 것이 없다)"
if running dss-as; then
  "$DOCKER" exec dss-as sh -c 'ls -1 /quote-archive >/dev/null 2>&1' \
    && ok "A/S 가 견적서 공유폴더를 읽는다" \
    || { bad "A/S 가 견적서 공유폴더를 **못 읽는다** — 발행이 실패한다"
         say "    🔴 여기는 **chmod 로 ACL 을 걷지 마라** — 직원의 탐색기가 끊긴다."; }
  "$DOCKER" exec dss-as sh -c "ls -1 '$PORTAL_MNT' >/dev/null 2>&1" \
    && ok "A/S 가 현황표 공유폴더를 읽는다" \
    || bad "A/S 가 $PORTAL_MNT 를 **못 읽는다** — 🔴 [공유폴더에 저장]이 죽는다"
  "$DOCKER" exec dss-as sh -c "ls -1 '$CONTACT_MNT' >/dev/null 2>&1" \
    && ok "A/S 가 연락서 공유폴더를 읽는다" \
    || bad "A/S 가 $CONTACT_MNT 를 **못 읽는다** — 🔴 연락서 [폴더 열기]가 죽는다"
  # 🔴 연락서는 **여전히 쓸 수 있어야** 한다 (18번이 연 자리).
  #    🔴 리다이렉션이 아니라 **touch** 다 — 머리말 ②.
  if "$DOCKER" exec dss-as sh -c "t='$CONTACT_MNT/.dss-write-test'; touch \"\$t\" && rm -f \"\$t\"" >/dev/null 2>&1; then
    ok "🔴 연락서 공유폴더는 **아직 쓸 수 있다**"
  else
    bad "🔴 연락서 공유폴더에 **못 쓴다** — 폴더 자동 생성 · 사본 꽂기가 죽는다"
  fi
  # 🔴 「수리 관련」과 발주서는 **쓰기가 막혀 있어야** 맞다.
  for rec in "$REPAIR_MNT|수리 관련" "$PO_MNT|발주서"; do
    t=$(printf '%s' "$rec" | cut -d'|' -f1)
    p=$(printf '%s' "$rec" | cut -d'|' -f2)
    n_in=$("$DOCKER" exec dss-as sh -c "ls -1 '$t' 2>/dev/null | wc -l" 2>/dev/null | tr -d ' ')
    if [ "${n_in:-0}" -ge 1 ] 2>/dev/null; then
      ok "A/S 가 「$p」 공유폴더를 읽는다 (맨 위 칸 ${n_in}개)"
    else
      bad "🔴 A/S 가 $t 에서 **0개**를 본다 — 빈 폴더가 붙었다"
      say "    → 경로의 **대소문자**를 보세요(2_AS센터 · 5_ 외자 PO)."
    fi
    # 🔴 **touch 를 쓴다.** 리다이렉션은 읽기 전용 자리에서 ash 를 죽인다.
    if "$DOCKER" exec dss-as sh -c "t='$t/.dss-ro-test'; touch \"\$t\"" >/dev/null 2>&1; then
      bad "🔴 $t 에 **쓸 수 있다** — read_only 가 안 먹었다"
      "$DOCKER" exec dss-as sh -c "rm -f '$t/.dss-ro-test'" >/dev/null 2>&1
      say "    🔵 시험 파일은 곧바로 지웠다 — 남아 있으면 알려 주세요."
    else
      ok "🔴 $t 는 **쓰기가 막혀 있다** (읽기 전용 그대로다)"
    fi
    ro_mount_check dss-as "$t" "$p"
  done
  mnt_count_check dss-as "$PO_MNT" "발주서" 1
else
  bad "dss-as 컨테이너가 떠 있지 않다"
fi
if running dss-po; then
  "$DOCKER" exec dss-po sh -c 'ls -1 /quote-archive >/dev/null 2>&1' \
    && ok "PO 가 견적서 공유폴더를 읽는다" \
    || bad "PO 가 견적서 공유폴더를 **못 읽는다** — 발행이 실패한다"
else
  bad "dss-po 컨테이너가 떠 있지 않다"
fi

# 5-ㄷ. 🔴 **이 배포의 핵심** — 도는 컨테이너 안에서 정규식을 값으로 잰다
say "  5-ㄷ. 🔴 **고쳐졌는가를 값으로 잰다** — 도는 컨테이너 안에서"
say "     (「만든 것과 도는 것은 다르다」. 위 1-ㅋ 는 이미지를 봤고 여기는 **도는 것**이다.)"
number_probe run dss-as "A/S" "$OLD_AS"
number_probe run dss-po "PO"  "$OLD_PO"

# 5-ㄹ. 🔴 설정이 컨테이너 안까지 그대로 왔는가
say "  5-ㄹ. 🔴 설정이 컨테이너 안까지 그대로 왔는가 (역슬래시까지 센다)"
say "     🔵 이번 판은 .env 를 한 글자도 안 고쳤다 — 여기서 보는 것은 **회귀**다."
if running dss-as; then
  for k in QUOTE_ARCHIVE_UNC_ROOT CUSTOMER_PORTAL_ARCHIVE_UNC_ROOT \
           CONTACT_FOLDER_ARCHIVE_UNC_ROOT REPAIR_DOCS_ARCHIVE_UNC_ROOT \
           PURCHASE_ORDER_ARCHIVE_UNC_ROOT; do
    v=$("$DOCKER" exec dss-as printenv "$k" 2>/dev/null)
    if [ -n "$v" ]; then
      ok "A/S · $k 가 컨테이너 안에 그대로 있다"
      n=$(backslash_count "$v")
      [ "${n:-0}" -ge 4 ] && ok "A/S · $k 의 역슬래시 ${n}개 — 삼켜지지 않았다" \
        || bad "A/S · $k 의 역슬래시가 ${n:-0}개뿐이다 — 🔴 따옴표가 먹은 것이다"
    else
      bad "A/S · $k 가 컨테이너 안에 **없다** — 🔴 그쪽 [폴더 열기]가 죽는다"
    fi
  done
  "$DOCKER" exec dss-as sh -c "[ -d \"\$PURCHASE_ORDER_ARCHIVE_DIR\" ]" >/dev/null 2>&1 \
    && ok "PURCHASE_ORDER_ARCHIVE_DIR 이 **실제로 있는 폴더**를 가리킨다" \
    || bad "🔴 PURCHASE_ORDER_ARCHIVE_DIR 이 가리키는 폴더가 컨테이너 안에 없다"
  "$DOCKER" exec dss-as sh -c "[ -d \"\$REPAIR_DOCS_ARCHIVE_DIR\" ]" >/dev/null 2>&1 \
    && ok "REPAIR_DOCS_ARCHIVE_DIR 이 **실제로 있는 폴더**를 가리킨다" \
    || bad "REPAIR_DOCS_ARCHIVE_DIR 이 가리키는 폴더가 컨테이너 안에 없다"
  "$DOCKER" exec dss-as sh -c "[ -d \"\$CONTACT_FOLDER_ARCHIVE_DIR\" ]" >/dev/null 2>&1 \
    && ok "CONTACT_FOLDER_ARCHIVE_DIR 이 **실제로 있는 폴더**를 가리킨다" \
    || bad "CONTACT_FOLDER_ARCHIVE_DIR 이 가리키는 폴더가 컨테이너 안에 없다"
else
  bad "dss-as 컨테이너가 떠 있지 않다 — 설정을 못 봤다"
fi
if running dss-po; then
  for k in $PO_REQUIRED_KEYS; do
    v=$("$DOCKER" exec dss-po printenv "$k" 2>/dev/null)
    if [ -n "$v" ]; then
      n=$(backslash_count "$v")
      [ "${n:-0}" -ge 4 ] && ok "PO · $k 가 있고 역슬래시 ${n}개 — 삼켜지지 않았다" \
        || bad "PO · $k 의 역슬래시가 ${n:-0}개뿐이다 — 🔴 따옴표가 먹은 것이다"
    else
      bad "PO · $k 가 컨테이너 안에 **없다** — 🔴 PO 에서 설치한 도우미가 그 폴더를 못 연다"
    fi
  done
  # 🔴 **다섯이 A/S 와 글자까지 같은가** — 다르면 설치 화면에 따라 갈린다.
  for k in $PO_HELPER_KEYS; do
    if [ "$("$DOCKER" exec dss-as printenv "$k" 2>/dev/null)" \
       = "$("$DOCKER" exec dss-po printenv "$k" 2>/dev/null)" ]; then
      ok "🔴 $k 가 A/S 와 PO 에서 **글자까지 같다**"
    else
      bad "🔴 $k 가 A/S 와 PO 에서 **다르다** — 어느 화면에서 설치했는가로 갈린다"
    fi
  done
fi

say "  5-ㅁ. 알림 통로 · 알림 링크의 주소 (A/S 만)"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 \
       "http://127.0.0.1:$AS_PORT/api/integration/notifications" 2>/dev/null)
case "$code" in
  404) bad "A/S 의 /api/integration/notifications 가 404 다 — **옛 이미지다**" ;;
  000|"") bad "A/S 의 알림 통로가 대답하지 않는다 (${code:-없음})" ;;
  *)   ok "A/S 의 알림 통로가 있다 (토큰 없이 부르면 401 이 맞다 — 지금 $code)" ;;
esac
notify_href_check "A/S" dss-as "$AS_ENV" "https://as.dss21.co.kr"

say "  5-ㅂ. 권한 — 교체 뒤에 다시 읽는다 (🔴 select 만)"
perm_check

# 5-ㅅ. 🔴 건드리지 않는 쪽이 **정말 안 멈췄는가** — 시작 시각으로 본다
say "  5-ㅅ. 🔴 건드리지 않는 쪽이 안 멈췄는가 (시작 시각을 대조한다)"
for t in $KEEP_BOXES; do
  before=$(printf '%s\n' "$STARTED_BEFORE" | sed -n "s/^$t=//p" | head -1)
  after=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  if [ -n "$before" ] && [ "$before" = "$after" ]; then
    ok "$t · 시작 시각 그대로 — **한 번도 안 멈췄다**"
  else
    bad "🔴 $t 의 시작 시각이 바뀌었다 ($before → $after) — 이 배포가 건드렸다"
  fi
done

say "  5-ㅇ. 바깥 주소 여섯"
for h in as po; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code (바뀐 쪽)" ;;
    *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
  esac
done
say "  🔴 안 바뀌는 쪽 — 흔들렸으면 **이 배포가 건드린 것**이다:"
for h in login meters improvements leave; do
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

# ══ 6. 마무리 ══════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · 약 ${DOWN}초"
echo "  🔵 바꾼 것은 **이미지 둘뿐**입니다 — DB 0 · .env 0줄 · 양식 0벌 · 볼륨 0"
echo "  첨부 스냅숏: $BK"
echo "  .env 사본: $BKD/as.env.$STAMP · $BKD/po.env.$STAMP (고치지는 않았습니다)"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" != 0 ]; then
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
  echo "되돌리기 안내:  bash $0 --rollback"
  exit "$FAIL"
fi
cat <<ANNOUNCE

╔════════════════════════════════════════════════════════════════════╗
║ 🔵 **도우미는 다시 깔지 않아도 됩니다.** 이번 판은 도우미를 안 바꿨습니다 ║
╚════════════════════════════════════════════════════════════════════╝

  🔵 몇 시간 전 열일곱째 배포에서 「전원 재설치(세대 3)」를 안내했습니다.
     **그 안내는 아직 유효합니다** — 아직 안 깐 분은 그대로 깔면 됩니다.
     🔴 이번 판이 **새로 더하는 재설치는 없습니다.**

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. 🔴 **가지 + 개정 번호가 붙은 그 건** — 번호가 2026-095-1R1 꼴인 건입니다.
      · [고객 안내 현황] · [주간보고] 의 견적서 번호 칸에 **-1R1 이 뜹니까.**
        (전에는 옆의 -1 번호가 뜨고 있었습니다.)
      · 🔴 **[Excel 보기]** 가 그 장을 **엽니까.**
        (전에는 「저장된 파일이 없습니다」였습니다.)
      · 🔴 **결재 탭의 공유폴더 구역**에 그 장의 파일이 **보입니까.**
        (전에는 하나도 안 보였습니다.)
      🔵 스크립트가 5-ㄷ 에서 **그 번호를 실제로 돌려** 이미 확인했습니다.
         여기서는 **화면에서도 그런지**만 보시면 됩니다.

   2. 🔵 그대로여야 하는 것 — 가지만(-1) · 개정만(R1) 붙은 번호도 **전처럼**
      보입니까. (스크립트가 5-ㄷ 에서 그 둘도 함께 쟀습니다.)

   3. 🔵 **21번이 올린 것들이 그대로입니까** — 수리 건 상세의 **발주서 탭** ·
      견적서 [저장] PDF · 결재/보고서 탭 공유폴더 · 목록의 승인 체크 ·
      매쳐 견적서의 **직인**. 이번 판은 그 어느 것도 건드리지 않았습니다.

   4. 🔵 **포털 · 계측기 · 개선요청 · 휴가가 그대로입니까** — 이번 판은
      그 넷을 건드리지 않았습니다. (스크립트가 5-ㅅ 에서 시작 시각으로 이미
      확인했습니다.)

🔴 사람이 이어서 할 일:
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.
  · 내일 아침 백업을 한 번 더 보세요 — 다섯이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -7
  · 첨부 스냅숏은 $BK 에 있습니다. 한 주쯤 두었다 지우세요.
  · 🔵 21번이 남긴 **옛 양식 두 벌**(backups/as-templates-*)은 **그대로 두세요.**
    이번 판은 양식을 안 바꿨습니다.

되돌리기 안내:  bash $0 --rollback
  🔵 되돌릴 것은 **이미지 둘뿐**입니다 — DB 도 .env 도 양식도 안 바꿨습니다.
  🔴 되돌리면 **이번에 고친 결함이 되살아납니다**(그 번호에서 [Excel 보기]가
     다시 안 열립니다). 🔵 자료는 그대로입니다.
ANNOUNCE
exit "$FAIL"
