#!/bin/bash
# /volume1/dss/setup/32-rf-trouble-deploy.sh
#   서른두째 — 아홉째 사이트 **RF 이슈관리**(dss-trouble · client_id
#   dss-rf-trouble) **첫 설치**.
#
# ── 이것은 「갈아 끼우기」가 아니라 「없던 것을 세우는 일」이다 ─────────
#   본은 27-deploy.sh(재고 관리 첫 설치)와 31-deploy.sh(compose 고치기)다.
#   검사가 보는 것은 「도는 것이 흔들리지 않았나」가 아니라
#   **「띄울 자리가 다 됐나」**다.
#
#     RF 이슈관리 : dss-rf-trouble:0.1
#                   🔴 **DB 가 없다** — 자료가 data/ 폴더의 파일이다
#                   컨테이너 안 7331 → 127.0.0.1:13900 → https://issues.dss21.co.kr
#                   자료 /volume1/dss/rf-trouble-data → 컨테이너 /app/data
#                   사본 /volume1/dss/rf-trouble-backup → 컨테이너 /backup
#                   공유폴더 둘은 **읽기 전용** — 자리는 사람이 정한다
#
# ══ 🔴 이 집이 앞의 여덟과 다른 것 다섯 ═══════════════════════════════
#   ① **DB 가 없다.** 마이그레이션 · 롤 · 비밀번호 절차가 **통째로 없다.**
#      그래서 27번의 --init 이 하던 일(표 만들기)이 여기서는
#      **자리 만들기**(폴더 · 설정 · compose)로 바뀐다.
#   ② **Next.js 가 아니다.** server.js 한 장 + 정적 HTML. package.json 이
#      없어 도구 이미지(tools-*)도 없다 — 빠뜨린 것이 아니다.
#   ③ 🔴 **팀 비밀번호 로그인이 이미 걷혔다**([저장소] 2026-10-21 커밋
#      9a52287). 들어오는 길은 통합 로그인 하나뿐이라
#      🔴 **포털이 멈추면 아무도 못 들어온다.** 비상구가 없다.
#   ④ 🔴 **콜백 경로에 auth 한 겹이 없다** — /api/sso/callback.
#      [저장소] dss-trouble/server.js 가 그 글자로 길을 연다.
#   ⑤ 🔴 저장소의 compose.yaml 은 **우리 규칙을 어긴다** — 그래서 그 파일을
#      쓰지 않고 통합 compose 에 블록을 **새로 쓴다**:
#        · ports: "7331:7331"  → 호스트 **모든 주소**에 연다
#          (우리는 127.0.0.1:13900 만 연다)
#
# ══ 🔴 공유폴더 둘은 **이번에 안 붙인다** (2026-10-22 쓰는 분 결정) ═══
#   저장소 compose.yaml 의 /volume1/공유폴더A · B 는 자리표시자였고, 실제
#   자리는 **배포판 이후에 시스템에서 고르기로** 했다. 그래서 이번 블록에는
#   볼륨 둘이 **없다.**
#
#   🔴 없어도 앱이 **뜬다** — 코드를 읽어 확인했다(2026-10-22):
#     · server.listen 까지 오는 길에 공유폴더를 보는 자리가 **하나도 없다.**
#       시작할 때 읽는 것은 data/ 뿐이다(kb.json · issues.json · trips.json ·
#       synonyms.json · customers.json).
#     · 공유폴더를 보는 곳은 셋인데 전부 **막혀 있다**:
#         ㄱ) 자동 재색인(autoCheck) — 60초 뒤부터 돈다. excelSignature 가
#             없는 파일을 「없음」으로 적어 지문이 달라지므로 build-kb.js 를
#             한 번 부르고, 그것이 엑셀을 못 읽어 **0 아닌 코드로 죽는다.**
#             그러면 FAILED_SIG 에 적어 두고 **다시 시도하지 않는다.**
#             🔵 kb.json 은 **덮어써지지 않는다** — build-kb.js 가 파일을
#                쓰기 전에 죽기 때문이다(읽기가 맨 앞에 있다). 색인을 잃지 않는다.
#         ㄴ) 파일 열기·내려받기 — 요청이 올 때만. 못 찾으면 그 요청만 오류다.
#         ㄷ) 작업 일지 백업 — config.json 의 backup.dir 을 **/backup**(절대
#             경로)으로 두면 공유폴더와 무관하다. 우리 블록이 그 자리를 붙인다.
#
#   🔴 그래서 **비는 것**은 이 둘뿐이다(쓰는 분이 알아야 한다):
#     · 자료 파일을 **열거나 내려받는** 길 — 검색 결과에 파일 이름은 그대로
#       나오는데(색인은 data/kb.json 에서 온다) 누르면 못 찾는다.
#     · **엑셀 자동 재색인** — 업무정리 엑셀을 고쳐도 반영되지 않는다.
#       설정·정보 화면의 「자동 갱신」 칸에 실패가 적힌다.
#     🔵 이슈 등록 · 검색 · 주간보고 · 출장일정 · 첨부는 **전부 그대로** 된다
#        (자료가 data/ 에 있다).
#     🔵 config.json 의 autoRefreshSec 를 **0** 으로 두면 그 헛걸음과 경고가
#        아예 없어진다. 공유폴더를 붙이는 날 60 으로 되돌리면 된다.
#
#   🔴 **나중에 붙이는 날** 무엇을 하는지는 compose 블록 안 주석에 적어 두었다
#      (볼륨 두 줄의 모양과, 붙인 뒤 재야 하는 것).
#
# ── 🔴 첫 설치 순서. 이 차례로 부른다 ──────────────────────────────────
#   0) sh  32-rf-trouble-check.sh        세우기 전 상태 (다른 파일)
#   1) bash 32-rf-trouble-deploy.sh      읽기만. 어긋난 곳을 먼저 고친다
#   2) bash 32-rf-trouble-deploy.sh --preload   이미지를 싣는다 (안 멈춤)
#   3) bash 32-rf-trouble-deploy.sh --init      🔴 **자리를 만든다**
#        폴더 · 권한 · 설정 틀 · 야간 백업 · compose 블록
#   4) sh  32-rf-trouble-client.sh --make-secret   포털에 등록 + 비밀값
#   5) bash 32-rf-trouble-deploy.sh      다시 읽기만 — 이번엔 다 찬다
#   6) bash 32-rf-trouble-deploy.sh --go        앱을 띄운다
#   7) 눈으로 확인 (--go 끝의 안내)
#
#   🔴 3 과 6 을 **합치지 않았다.** 자리가 덜 된 채 앱이 뜨면
#      · 설정이 비어 로그인이 꺼지고 → 컨테이너가 제 안 127.0.0.1 에만 열어
#        **바깥에서 아예 못 닿는다**(증상이 502 라 프록시 탓으로 보인다)
#      · config.json 이 없으면 도커가 그 자리에 **빈 폴더를 만들어** 붙인다
#        (한 번 생기면 사람이 지워야 한다)
#      그래서 --go 는 시작 전에 그 둘을 **값으로** 다시 센다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/32-rf-trouble-deploy.sh   ← 읽기만
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#   MODE=check 가 기본값이다. 정직하게 적어 둔다 — --check 도 이렇게 한다:
#     · 이미지 **안을 보려고** 컨테이너를 잠깐 띄웠다 지운다(docker run --rm)
#     · 데이터 폴더에 **쓸 수 있는지** 보려고 파일을 만들었다 지운다
#     · 포털 DB 에 **select** 를 보낸다(바꾸는 문장은 하나도 없다)
#     · 바깥 주소 아홉에 GET 을 한 번씩 보낸다
#   「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#
# ══ 🔴 이 파일을 NAS 로 옮기는 법 ═════════════════════════════════════
#   DSM 터미널은 **긴 명령을 잘라 먹는다**(2026-10-13 하루 네 번). 파일로
#   올리고 **md5 를 맞춘다.** scp 에는 **-O** 를 붙인다(없으면 sftp 가 없어 실패).
#     (PowerShell) scp -O 32-rf-trouble-deploy.sh dss-nas:/volume1/dss/setup/
#     (PowerShell) Get-FileHash -Algorithm MD5 .\32-rf-trouble-deploy.sh
#     (NAS)        md5sum /volume1/dss/setup/32-rf-trouble-deploy.sh
#
# ══ 🔴 ✓ / ✗ / ? 로 센다 ═════════════════════════════════════════════
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다 · 아직 안 왔다**
#   🔴 ? 를 통과로 세지 않는다. ✗ 든 ? 든 하나라도 있으면 종료 코드 1 이다.
#   🔴 그러나 **「아직 안 온 것」을 ✗ 로 세지도 않는다** — --check 에서는 ? 다.
#      --preload · --init · --go 는 그것이 **있어야** 도는 모드라 ✗ 로 센다.
#   🔴 기대값의 출처를 그 줄 옆에 적는다 — [설문] · [저장소] · [결정] · [사람].
#      🔴 추측이면 박지 않는다.
#   🔵 2026-10-22 에 **검사 자신이 틀린 경우가 일곱 번** 있었다(전부 거짓
#      실패였다). ✗ 가 나면 **검사를 먼저 의심하세요.**
#
# ══ 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ═══════════════════════
#   ① 큰따옴표 안의 백틱은 명령 치환으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 주석에도 안 썼다.
#   ② 읽기 전용 자리에 리다이렉션으로 빈 파일을 만들면(콜론 하나 뒤에 꺾쇠)
#      NAS 의 ash 가 셸을 그 자리에서 끝낸다(2026-10-12 실제 사고).
#      → 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir 로 만든다.
#
# ══ 🔴 비밀값을 찍지 않는다 ═══════════════════════════════════════════
#   .env 는 **이름이 있는가 · 값이 비었는가**만 본다. 값도 길이도 안 찍는다.
#   공개 주소(SSO_ISSUER · SSO_REDIRECT_URI · SSO_CLIENT_ID)만 글자 대조한다.
#
# ══ 🔴 건드리지 않는 쪽 ═══════════════════════════════════════════════
#   도는 컨테이너 **전부**다. 이 설치는 아무것도 멈추지 않는다 — 없던 것을
#   하나 세울 뿐이다. 그래도 바꾸기 전후로 시작 시각(.State.StartedAt)을
#   적어 두고 **그대로인지** 본다. 말로 하지 않는다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
ACLT=/usr/syno/bin/synoacltool
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
ENV_NAS=$D/deploy/.env.nas
ENVD=$D/deploy/env
IMAGES=$D/images
BKD=$D/backups
BKDB=$D/backups/db
IN=$D/setup/incoming
JOB=$D/jobs/backup-nightly.sh

# ══ 이번에 세우는 것 — 한자리에 모아 둔다 ═════════════════════════════
TAG=dss-rf-trouble:0.1            # [결정] 다른 여덟과 같은 이름 규칙
OLDTAG=                           # 🔴 첫 설치라 **옛 태그가 없다**
TARF=dss-rf-trouble-0.1.tar
SVC=app-rf-trouble
CNAME=dss-rf-trouble
HPORT=13900                       # [설문] 31-survey.sh 8절이 비어 있음을 확인
CPORT=7331                        # [저장소] dss-trouble/Dockerfile 의 ENV PORT
BASE=https://issues.dss21.co.kr   # [결정] 2026-10-22
CLIENT_ID=dss-rf-trouble          # [저장소] dss-auth sources.ts 에 박힌 글자
ISSUER=https://login.dss21.co.kr  # [결정] 끝 빗금 없이
REDIR=$BASE/api/sso/callback      # 🔴 auth 한 겹이 없다
BACKCH=$BASE/api/sso/backchannel-logout
DATA=$D/rf-trouble-data
BKDIR=$D/rf-trouble-backup
ENVF=$ENVD/rf-trouble.env
HEALTH=/api/health                # [저장소] Dockerfile 의 HEALTHCHECK 가 쓰는 길
# ══ 🔴 컨테이너가 도는 번호 — [실측] 2026-10-22 NAS 에서 id 1026 ═══════
#   uid=1026(swhur) gid=100(users)
#   groups=100(users),101(administrators),65537,65536
#   🔵 **다른 집들(1001)과 다르다.** 바꾸지 마라 — 이 저장소의 compose.yaml 이
#      1026 을 적고 있었고, NAS 에 **실재하는 번호**다(그 계정이 /volume1/dss/
#      images 의 tar 들 주인이기도 하다).
#   🔵 gid 가 100(users)인 까닭: 공유폴더의 시놀로지 ACL 은 **이름 기반**이라
#      그 그룹이어야 직원 폴더를 읽는다. 공유폴더를 **나중에 붙이는 날** 그
#      번호가 필요하다 — 지금 맞춰 두면 그날 고칠 것이 없다.
#   🔴 이미지가 들고 있는 번호(Dockerfile 의 USER node)와 다르다. 그래서
#      compose 의 user: 줄로 덮어쓰고, 데이터 폴더 주인을 이 번호로 맞춘다.
APP_UID=1026
APP_GID=100
NOTIF=/api/integration/notifications
# ══ 🔴 tar 의 기대값 — **비워 둔다. 추측으로 박지 않는다** ═════════════
#   이미지를 아직 굽지 않았으므로 바이트·md5·Config 지문을 알 길이 없다.
#   🔴 그렇다고 ? 를 영영 두면 --go 가 **영원히 막힌다.** 그래서 27번의
#      클라이언트 해시와 **같은 방식**으로 사람이 채우는 길을 둔다:
#
#     개발 PC(PowerShell)에서 구운 뒤 재서 →
#       Get-FileHash -Algorithm MD5 .\dss-rf-trouble-0.1.tar
#       (Get-Item .\dss-rf-trouble-0.1.tar).Length
#     NAS 에 이 파일을 만들어 적는다 (값 하나만 적어도 된다):
#       /volume1/dss/setup/incoming/rf-trouble-image.txt
#         MD5=<소문자 32자>
#         SIZE=<바이트>
#         CFG=sha256:<64자>      ← 모르면 적지 않아도 된다
#
#   🔴 **이 값을 Claude 가 지어내지 않는다.** 재는 쪽은 사람이고, 그래야
#      「옮기다 깨졌나」가 아니라 「개발 PC 에서 구운 그것이 맞나」를 본다.
#   🔵 그 파일이 없으면 ? 로 센다 — 그 상태로 --go 가 막히는 것이 **맞다.**
TAR_EXP=$IN/rf-trouble-image.txt
TAR_SIZE=
TAR_MD5=
TAR_CFG=
if [ -r "$TAR_EXP" ]; then
  TAR_MD5=$(sed -n 's/^[[:space:]]*MD5=//p'  "$TAR_EXP" | head -1 | tr -d ' \r' | tr 'A-F' 'a-f')
  TAR_SIZE=$(sed -n 's/^[[:space:]]*SIZE=//p' "$TAR_EXP" | head -1 | tr -d ' \r')
  TAR_CFG=$(sed -n 's/^[[:space:]]*CFG=//p'  "$TAR_EXP" | head -1 | tr -d ' \r')
fi

# compose 에 블록을 넣을 자리 표시. [저장소] 27-inventory-place.sh 의 awk 는
# 표시 줄 자체를 **그대로 두고** 지나가므로 NAS 의 compose 에도 남아 있다.
ANCHOR=DSS-INVENTORY-UNCOMMENT-END-TOOLS
# 🔴 넣을 블록의 줄 수. [저장소] 2026-10-22 개발 PC 의 compose 사본(1298줄)에
#    **실제로 넣어 보고 세었다** — 1298 → 1419 (+121). js-yaml 로 넣기 전후를
#    둘 다 파싱했고 서비스가 14 → 15 로 하나만 늘었다.
#    🔵 공유폴더 볼륨 둘을 **안 넣는 쪽**으로 정해진 뒤의 값이다(2026-10-22).
#       붙이는 날 두 줄이 늘면 이 수도 함께 고쳐야 한다.
#    🔴 이 값이 틀리면 edit_compose 가 **넣지 않고 멈춘다**(틀린 채 넣지 않는다).
CF_BLOCK_BASE=121
# compose 에 그대로 있어야 하는 서비스 열여섯 [설문] 31-deploy.sh 의 목록
SVC_ALL="db-app db-auth app-auth app-as tools-as app-meters tools-meters"
SVC_ALL="$SVC_ALL app-improvements tools-improvements app-po app-leave tools-leave"
SVC_ALL="$SVC_ALL app-board tools-board app-inventory tools-inventory"
# compose 가 통째로 안 먹지 않으려면 있어야 하는 env 파일들 [설문]
ENV_FILES="auth.env as.env po.env meters.env improvements.env leave.env board.env inventory.env"
# 건드리지 않는 바깥 주소 여덟 [설문]
HOSTS8="login as meters improvements po leave board inventory"
# 건드리지 않는 컨테이너 — 시작 시각을 적어 두고 뒤에서 대조한다
KEEP_BOXES="dss-pg-app dss-pg-auth dss-auth dss-as dss-meters dss-improvements dss-po dss-leave dss-board dss-inventory"

# ── 모드 ───────────────────────────────────────────────────────────────
MODE=check
FORCE_LOAD=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 32-rf-trouble-deploy.sh              읽기만 (기본값) · 아무것도 안 바꿈
  bash 32-rf-trouble-deploy.sh --check      위와 같습니다
  bash 32-rf-trouble-deploy.sh --preload    이미지를 싣고 지문을 맞춥니다
  bash 32-rf-trouble-deploy.sh --force-load 🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 32-rf-trouble-deploy.sh --init       🔴 **자리를 만듭니다**
                                            폴더 · 권한 · 설정 틀 · 야간 백업 ·
                                            compose 블록. 아직 안 띄웁니다
  bash 32-rf-trouble-deploy.sh --go         앱을 띄웁니다 (멈추는 것은 없습니다)
  bash 32-rf-trouble-deploy.sh --rollback   되돌리기 안내 (아무것도 안 바꿈)

  🔴 차례: (없음) → --preload → --init → 포털 등록 → (없음) → --go
  🔴 --init 과 --go 는 **따로** 부릅니다. 자리가 덜 된 채 앱이 뜨면 설정이
     비어 로그인이 꺼지고, 그러면 바깥에서 아예 못 닿습니다.
  🔴 --init 도 --go 도 **오늘 백업이 없으면 시작하지 않습니다.** 야간 02:30.
USAGE
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)      MODE=check ;;
    --preload)    MODE=preload ;;
    --force-load) FORCE_LOAD=1; [ "$MODE" = check ] && MODE=preload ;;
    --init)       MODE=init ;;
    --go)         MODE=go ;;
    --rollback)   MODE=rollback ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "모르는 인자: $1"; usage; exit 2 ;;
  esac
  shift
done

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/32-rf-trouble-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 (30 · 31번의 것) ───────────────────────────────────────────
PASS=0; FAIL=0; UNK=0; T0=0; UP_AT=""; STOP_AT=""; DOWN=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
unk()  { echo "  ? $*"; UNK=$((UNK + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }
doubt() { say "    🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 이 줄의 기대값이"
          say "       어디서 왔는지는 바로 옆에 적혀 있습니다([설문]·[저장소]·[결정])."; }
missing_is_fatal() { [ "$MODE" != check ]; }
notyet() { if missing_is_fatal; then bad "$1"; else unk "$1"; fi; }
isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }
CMDW=76
cmd() {
  printf '    %s\n' "$1"
  if [ "${#1}" -gt "$CMDW" ]; then
    printf '    ⚠️ 위 줄이 %s자다(%s자 넘음) — 붙여넣으면 잘릴 수 있다.\n' "${#1}" "$CMDW"
  fi
}
compose_cmd() { "$DOCKER" compose --project-directory "$D/deploy" -f "$CF" --env-file "$ENV_NAS" --profile tools "$@"; }
running() { "$DOCKER" ps --format '{{.Names}}' | grep -qx "$1"; }

# ── 이미지 (30 · 31번 글자 그대로) ────────────────────────────────────
tar_config_id() {
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
  verify_img "$1" "$3" || { say "    🔴 같은 태그로 **다시 구운** 이미지일 수 있다. 덮어쓰려면:"
                            cmd "bash $0 --preload --force-load"; return 1; }
}
see_tar() { # 1 태그 2 tar경로 3 tar지문 4 기대바이트 5 기대md5 6 기대지문
  local tag="$1" f="$2" got="$3" wsz="$4" wmd5="$5" wcfg="$6" n m
  if [ ! -s "$f" ]; then
    notyet "$tag 의 tar 가 아직 NAS 에 없다: $(basename "$f")"
    say "    → 🔴 이미지는 **사람이 개발 PC 에서 굽는다.** Claude 는 굽지 않는다:"
    cmd "docker build -t $tag ."
    cmd "docker save $tag -o $(basename "$f")"
    cmd "scp -O $(basename "$f") dss-nas:/volume1/dss/images/"
    return 1
  fi
  n=$(stat -c '%s' "$f" 2>/dev/null)
  m=$(md5_of "$f")
  say "    · 지금 이 tar: 바이트 ${n:-?} · md5 ${m:-?}"
  [ -n "$got" ] && say "    · 이 tar 안 Config 지문: $got"
  # 🔴 **칸마다 따로 센다.** 셋 중 하나만 받아도 그 하나는 진짜로 맞춰 보고,
  #    못 받은 칸만 ? 로 둔다. 「하나라도 비면 전부 ?」로 두면 사람이 md5 를
  #    줘도 쓰이지 않는다.
  if [ -z "$wsz" ] && [ -z "$wmd5" ] && [ -z "$wcfg" ]; then
    unk "$tag · **사람이 잰 값이 하나도 없다** — 「개발 PC 에서 구운 그것이 맞나」를 못 본다"
    say "       🔴 첫 설치라 기대값이 **없는 것이 정상**이지만, 이대로는 --go 가"
    say "          막힙니다(막히는 것이 맞습니다). 개발 PC 에서 재어 적어 주세요:"
    cmd "Get-FileHash -Algorithm MD5 .\\$(basename "$f")"
    cmd "(Get-Item .\\$(basename "$f")).Length"
    say "       NAS 에 그 값을 적습니다 (MD5 한 줄만 적어도 됩니다):"
    cmd "vi $TAR_EXP"
    say "         MD5=<소문자 32자>"
    say "         SIZE=<바이트>"
    return 0
  fi
  if [ -n "$wsz" ]; then
    [ "$n" = "$wsz" ] && ok "$tag · 바이트 $n  [사람이 잼]" \
      || { bad "$tag 의 바이트가 $wsz 가 아니다 ($n) — 옮기다 끊겼다  [사람이 잼]"; doubt; }
  else
    say "    · 바이트 기대값은 안 받았다 (md5 가 있으면 그것으로 충분하다)"
  fi
  if [ -n "$wmd5" ]; then
    [ "$m" = "$wmd5" ] && ok "$tag · md5 맞음  [사람이 잼]" \
      || { bad "$tag 의 md5 가 다르다 (${m:-못 읽음}) — 다른 판이거나 상했다  [사람이 잼]"; doubt; }
  else
    unk "$tag · md5 기대값을 안 받았다 — $TAR_EXP 에 MD5= 를 적어 주세요"
  fi
  if [ -n "$wcfg" ]; then
    [ "$got" = "$wcfg" ] && ok "$tag · tar 안 Config 지문이 기대값과 같다" \
      || { bad "$tag · tar 안 Config 지문이 기대값과 다르다  [사람이 잼]"; doubt; }
  else
    say "    · Config 지문 기대값은 안 받았다 — 대신 **실린 이미지의 .Id 와** 맞춰 본다"
  fi
  return 0
}
wait_http() { # 1 이름 2 포트 3 경로 4 컨테이너
  local i code
  for i in $(seq 1 90); do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://127.0.0.1:$2$3" 2>/dev/null)
    case "$code" in 2??|3??) ok "$1 응답 $code ($((SECONDS - T0))초)"; return 0 ;; esac
    sleep 2
  done
  bad "$1 이 180초 안에 대답하지 않았다 (마지막 ${code:-없음})"
  say "    🔴 설정 넷(SSO_*)이 하나라도 비면 앱이 **제 안 127.0.0.1 에만** 연다."
  say "       그러면 포트는 멀쩡한데 바깥에서 아예 못 닿는다. 로그를 보세요:"
  cmd "$DOCKER logs --tail 50 $4"
  return 1
}

# ── compose 읽기 (27 ~ 31번) ──────────────────────────────────────────
svc_block() {
  awk -v s="  $2:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$1" | sed '/^[[:space:]]*#/d'
}
img_line_count() {
  awk -v want="image: $2" '
    { t = $0; gsub(/^[ \t]+/, "", t); gsub(/[ \t\r]+$/, "", t)
      if (t == want) n++ }
    END { print n + 0 }
  ' "$1"
}
exact_line_count() {
  awk -v want="$2" '
    { t = $0; gsub(/[ \t\r]+$/, "", t)
      if (t == want) n++ }
    END { print n + 0 }
  ' "$1"
}
cf_img_list() {
  awk '
    { t = $0; gsub(/^[ \t]+/, "", t); gsub(/[ \t\r]+$/, "", t)
      if (index(t, "image: ") == 1) print t }
  ' "$1" | sort
}
env_has() { # 1 파일 2 이름 → 그 이름 줄 수
  [ -f "$1" ] || { echo 0; return 0; }
  grep -cE "^[[:space:]]*(export[[:space:]]+)?$2=" "$1" 2>/dev/null | tr -d ' '
}
env_val() { # 1 파일 2 이름 → 값 (🔴 부르는 쪽이 찍지 않도록 조심한다)
  sed -n "s/^[[:space:]]*\(export[[:space:]]*\)\?$2=//p" "$1" 2>/dev/null | head -1
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 공유폴더가 **아직 안 붙었다**는 사실을 적어 두는 줄
#
#  ✓ 로 세지 않는다 — 「맞게 됐다」가 아니라 「지금은 이렇다」이기 때문이다.
#  🔴 붙이는 날 **여기와 견준다.** 그날 이 수가 0 에서 2 로 바뀌어야 한다.
#  🔴 경로는 한 글자도 찍지 않는다 — dss-trouble 은 공개 저장소이고 이 로그는
#     채팅으로 돌아간다.
# ══════════════════════════════════════════════════════════════════════
note_shares() {
  local n=0
  # 🔴 svc_block 은 **주석 줄을 지우고** 돌려준다 — 이 블록에 들어 있는
  #    「붙이는 날 이렇게 더한다」 예시 두 줄이 세어지지 않는 까닭이다.
  #    그래도 한 겹 더 좁혀 둔다(줄머리가 「- 」인 것만).
  [ -f "$CF" ] && n=$(svc_block "$CF" "$SVC" 2>/dev/null | grep -E '^[[:space:]]*-[[:space:]]' | grep -c ':/mnt/nas')
  say "  🔵 **적어 두는 줄** — 공유폴더 볼륨: 지금 ${n:-0}개 (2026-10-22 결정으로 0 이 맞다)"
  say "     파일 위치는 배포판 이후에 시스템에서 고르기로 했다. 그때까지 비는 것 둘:"
  say "       · 자료 파일 **열기·내려받기** — 검색에 이름은 나오는데 누르면 못 찾는다"
  say "       · 엑셀 **자동 재색인** — 설정·정보 화면의 「자동 갱신」에 실패가 적힌다"
  say "     🔵 그 밖(이슈 등록·검색·주간보고·출장일정·첨부)은 **전부 그대로** 된다."
  say "     🔵 config.json 의 autoRefreshSec 를 0 으로 두면 헛걸음과 경고가 없어진다."
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 「있는가」가 아니라 **「쓸 수 있는가 · 읽을 수 있는가」**
#     임시 컨테이너를 **앱이 쓸 바로 그 번호로** 띄워 실제로 해 본다.
#  🔴 콜론과 리다이렉션으로 빈 파일을 만들지 않는다 — 쓰기가 막히면 ash 가
#     셸을 그 자리에서 끝내 뒤 줄이 아예 안 돌고 판정이 **빈 채로** 지나간다
#     (2026-10-12 실측). touch · mkdir 은 외부 명령이라 실패해도 셸이 산다.
# ══════════════════════════════════════════════════════════════════════
probe_write() { # 데이터 폴더에 실제로 써 본다
  local out
  if ! have_img "$TAG"; then
    notyet "쓰기 시험에 쓸 이미지가 아직 없다 ($TAG)"
    return 1
  fi
  out=$("$DOCKER" run --rm --network none -u "$APP_UID:$APP_GID" \
        -v "$DATA:/app/data" --entrypoint sh "$TAG" -c '
          id
          if touch /app/data/.dss-write-test 2>/dev/null; then
            echo "PROBE WRITE_OK"
            rm -f /app/data/.dss-write-test 2>/dev/null
          else
            echo "PROBE WRITE_FAIL"
          fi
          if mkdir -p /app/data/.dss-mkdir-test 2>/dev/null; then
            echo "PROBE MKDIR_OK"
            rmdir /app/data/.dss-mkdir-test 2>/dev/null
          else
            echo "PROBE MKDIR_FAIL"
          fi' 2>&1)
  printf '%s\n' "$out" | grep -E '^(uid=|PROBE )' | sed 's/^/     /'
  case "$out" in
    *"PROBE WRITE_OK"*)
      ok "🔴 uid $APP_UID 이 데이터 폴더에 **실제로 썼다** (바로 지웠다)" ;;
    *"PROBE WRITE_FAIL"*)
      bad "🔴 uid $APP_UID 이 못 쓴다 — 세션 서명 열쇠(.session-secret)조차 못 만든다"
      say "       그러면 로그인이 **될 때마다 풀린다.** ACL 이 남았거나 주인이 다르다." ;;
    *)
      bad "쓰기 시험을 판정하지 못했다 — 아래가 그대로의 출력이다"
      printf '%s\n' "$out" | sed 's/^/     /' | head -8 ;;
  esac
  case "$out" in
    *"PROBE MKDIR_OK"*)   ok "폴더도 만들 수 있다 (uploads 가 이렇게 생긴다)" ;;
    *"PROBE MKDIR_FAIL"*) bad "🔴 폴더를 못 만든다 — 첨부 폴더가 영영 안 생긴다" ;;
  esac
  local left
  left=$(find "$DATA" -maxdepth 2 -name '.dss-*-test' 2>/dev/null | wc -l)
  [ "${left:-0}" = 0 ] && ok "시험 흔적이 남지 않았다" \
    || bad "시험 흔적이 남아 있다 — $DATA 아래 .dss-*-test 를 손으로 지우세요"
}
# ══════════════════════════════════════════════════════════════════════
#  🔴 compose 에 블록을 넣는다 — 31번이 한 방식 그대로
#     사본을 먼저 뜨고, 넣은 뒤 아래를 **전부** 센다. 하나라도 어긋나면
#     **사본으로 되돌리고 멈춘다.**
#       · 줄 수가 기대한 그대로 늘었는가
#       · image: 줄 **전체 목록**이 우리 것 한 줄 말고는 글자까지 그대로인가
#       · compose config -q 가 통과하는가 · 서비스 목록이 그대로인가
# ══════════════════════════════════════════════════════════════════════
TMPD=$D/setup/tmp-32-$STAMP
CF_BK=""
backup_compose() {
  local bk="$BKD/docker-compose.nas.yml.$STAMP"
  mkdir -p "$BKD"
  cp -p "$CF" "$bk" || { bad "compose 사본을 못 떴다"; return 1; }
  chmod 644 "$bk"
  CF_BK=$bk
  ok "compose 사본 — backups/docker-compose.nas.yml.$STAMP"
}
restore_compose() {
  [ -n "$CF_BK" ] || return 1
  say "  🔴 **사본으로 되돌립니다.**"
  cp -p "$CF_BK" "$CF"; chown root:root "$CF"; chmod 644 "$CF"
  ok "compose 를 사본으로 되돌렸다 — 넣기 전과 글자까지 같다"
}
write_app_block() { # 1 쓸 파일
  cat > "$1" <<BLOCK

  # ══ RF 이슈관리 (7331) ═══════════════════════════════════════════════
  #
  # 아홉째 사이트다 (2026-10-22 더함). 🔴 앞의 여덟과 **근본이 다른 것 셋**:
  #
  #  ① **DB 가 없다.** 자료가 data/ 폴더의 파일이다 — 이슈 · 색인 · 첨부,
  #     그리고 세션 서명 열쇠 .session-secret. 그래서 이 블록에는
  #     DATABASE_URL 도 depends_on 도 없고, 도구 서비스(tools-*)도 없다.
  #     🔴 대신 **백업 대상이 폴더**다. jobs/backup-nightly.sh 의
  #        rf-trouble-data 절이 그것이다 — 그 줄이 빠지면 이 시스템은
  #        아무 오류 없이 **한 번도 백업되지 않는다**(개선요청이 11일).
  #
  #  ② **Next.js 가 아니다.** server.js 한 장과 정적 HTML 이고 의존성이 0 이라
  #     package.json 자체가 없다. 부를 npm script 가 없어 도구 이미지도 없다 —
  #     빠뜨린 것이 아니다.
  #
  #  ③ **networks 에 dss-data 가 없다.** DB 를 보지 않으므로 붙일 까닭이 없다.
  #     dss-edge 만 있으면 된다 — 통합 로그인의 토큰 교환과 공개 열쇠(jwks)
  #     받기가 https://login.dss21.co.kr 로 **나갔다 들어온다**(NAS 자신의
  #     443 이지만 컨테이너에서는 바깥이다). dss-data 는 internal: true 라
  #     바깥으로 못 나간다. 🔴 dss-edge 가 빠지면 화면은 뜨는데 로그인만 안 된다.
  #
  # 🔴 **들어오는 길이 통합 로그인 하나뿐이다.** 그 저장소 2026-10-21 커밋
  #    9a52287 이 팀 공용 비밀번호 길을 코드에서 걷어냈다 — 비상구가 없다.
  #    **포털이 멈추면 아무도 못 들어온다.**
  #
  # 🔴 SSO_ 넷 중 하나라도 비면 이 앱은 제 안 127.0.0.1 에만 연다(그 저장소
  #    server.js 의 HOST 내림). 그러면 아래 ports: 가 멀쩡해도 바깥에서
  #    **아예 못 닿는다** — 증상이 502 라 프록시 탓으로 보인다.
  #
  # 주소는 https 뿐이다 — https://issues.dss21.co.kr (DSM 프록시 443 →
  # 127.0.0.1:13900). 인증서는 이미 있는 와일드카드(*.dss21.co.kr)가 덮는다.
  # ⚠️ Cloudflare 에 A 레코드 issues 가 하나 늘어야 한다 (사람이 한다).
  #
  # 🔴 콜백 경로가 다른 여덟과 **다르다** — /api/sso/callback 이다(auth 한 겹이
  #    없다). 포털 clients 의 redirect_uris 와 글자 단위로 같아야 한다.
  # 🔴 클라이언트 열쇠는 dss-rf-trouble 이다 — 저장소 이름(dss-trouble)과 다르다.
  #
  # 🔴 컨테이너 안 포트는 7331 그대로다. 앞의 여덟이 쓰던 「앞에 1 을 붙인
  #    번호」 규칙을 쓸 수 없어 호스트 쪽만 13900 을 쓴다(31-survey.sh 8절이
  #    13900 이 비어 있음을 확인했다).
  app-rf-trouble:
    image: $TAG
    # 🔴 **번호가 앞의 여덟과 다르다.** [실측] 2026-10-22 NAS 에서 id 1026 —
    #    uid=1026(swhur) gid=100(users). 이 저장소의 compose.yaml 이 적고 있던
    #    번호이고 NAS 에 실재한다. 다른 집들의 1001 로 바꾸지 마라.
    #    🔵 gid 가 100(users)인 까닭: 공유폴더의 시놀로지 ACL 은 **이름 기반**
    #       이라 그 그룹이어야 직원 폴더를 읽는다. 공유폴더를 나중에 붙이는 날
    #       그 번호가 필요해서 지금 맞춰 둔다(그날 고칠 것이 없게).
    #    🔴 이미지가 들고 있는 번호(Dockerfile 의 USER node)와 다르다 — 이
    #       줄이 그것을 덮어쓴다. 데이터 폴더 주인도 같은 번호로 맞춰 두었다.
    user: "$APP_UID:$APP_GID"
    container_name: $CNAME
    restart: unless-stopped
    logging: *logging
    networks: [dss-edge]
    ports: ["127.0.0.1:$HPORT:$CPORT"]
    env_file:
      - ./env/rf-trouble.env
    environment:
      TZ: Asia/Seoul
      # PORT · HOST · WORKLOG 는 적지 않는다 — 이미지가 들고 있다(그 저장소
      # Dockerfile 의 ENV). 여기 또 적으면 같은 값이 두 곳에 생긴다.
    volumes:
      # 🔴 이 한 줄이 이 서비스에서 가장 중요하다. 빠지면 이슈와 첨부가
      #    컨테이너 안 임시 디스크에 쌓이고 **다음 배포에서 전부 사라진다.**
      #    그 안에는 세션 서명 열쇠(.session-secret)도 있어, 사라지면
      #    로그인해 있던 사람이 한꺼번에 풀린다.
      - $DATA:/app/data
      # 설정. 🔴 공유폴더 경로와 pathMap 이 들어 있어 **사람이 만든다.**
      #    🔴 호스트에 이 파일이 없으면 도커가 그 자리에 **빈 폴더를 만들어**
      #       붙인다 — 앱이 설정을 못 읽는데 오류가 안 난다. --go 가 먼저 센다.
      - $DATA/config.json:/app/config.json:ro
      # 작업 일지(issues.json)의 날짜별 사본. data/ 에서 다시 만들 수 있는
      # 것이라 야간 백업에 넣지 않는다 — 백업의 백업을 받지 않는다.
      - $BKDIR:/backup
      #
      # ══ 🔴 **공유폴더 둘은 아직 안 붙였다** (2026-10-22 쓰는 분 결정) ══
      #
      #   저장소 compose.yaml 에는 /volume1/공유폴더A · B 라는 **자리표시자**가
      #   있었다. 실제 자리는 **배포판 이후에 시스템에서 고르기로** 해서, 이
      #   설치에서는 **일부러 넣지 않았다.** 🔴 빠뜨린 것이 아니다.
      #
      #   🔴 없어도 앱은 뜬다 — 시작하는 길에 공유폴더를 보는 자리가 하나도
      #      없다(그 저장소 server.js 는 data/ 만 읽고 listen 한다).
      #      비는 것은 둘뿐이다:
      #        · 자료 파일 **열기·내려받기** — 검색에 이름은 나오는데(색인이
      #          data/kb.json 에서 온다) 누르면 못 찾는다
      #        · 엑셀 **자동 재색인** — 60초 뒤 한 번 해 보고 실패하면 그
      #          지문을 기억해 **다시 시도하지 않는다.** kb.json 은 덮어써지지
      #          않는다(build-kb.js 가 쓰기 전에 죽는다 — 색인을 잃지 않는다).
      #      🔵 config.json 의 autoRefreshSec 를 0 으로 두면 그 헛걸음과
      #         경고가 아예 없어진다. 붙이는 날 60 으로 되돌린다.
      #
      #   🔴 **붙이는 날**에는 여기에 두 줄을 더한다. 꼴은 이렇다
      #      (경로에 공백·한글이 들어가므로 **큰따옴표로 묶는다**):
      #
      #        - "/volume1/<공유폴더A 의 실제 위치>:/mnt/nas7:ro"
      #        - "/volume1/<공유폴더B 의 실제 위치>:/mnt/nas1:ro"
      #
      #      · 오른쪽 이름(/mnt/nas7 · /mnt/nas1)은 **config.json 의 pathMap
      #        오른쪽과 글자까지 같아야 한다.** 어긋나면 오류 없이 못 찾는다.
      #      · 🔴 **:ro 를 빠뜨리지 마라.** 이 앱이 직원 서류함에 쓸 일은 없다.
      #      · 붙인 뒤 **읽히는지 값으로 재라** — 「붙였다」가 아니라 「읽나」다.
      #        시놀로지 ACL 은 **이름 기반**이라 chown 만으로는 안 열린다
      #        (2026-10-14 재고 관리 실측: 1001:1001 ✗ · 1001:100 ✓).
      #        위 user: 가 gid 100(users)인 까닭이 그것이다. 재는 법:
      #          docker exec dss-rf-trouble sh -c 'ls -1 /mnt/nas7 | wc -l'
      #      · config.json 의 autoRefreshSec 를 60 으로 되돌린다.
      #
BLOCK
  cat >> "$1" <<'BLOCK2'
    deploy:
      resources:
        limits:
          # 🔴 512M. 근거: 이 앱은 업무정리 엑셀을 파싱해 색인을 메모리에 들고
          #    있다(그 저장소 tools/parse-xlsx.js · build-kb.js). A/S · PO 의
          #    640M 은 21MB 업로드 파싱의 봉우리 때문이라 성격이 다르고,
          #    384M 쪽(포털 · 휴가 · 게시판)은 파일을 아예 안 다룬다. 성격이
          #    가장 가까운 것은 계측기(app-meters, 512M)다.
          #    🔴 **상한이지 예약이 아니다.** 세운 직후 docker stats --no-stream
          #       으로 실측해서 이 파일 맨 아래 예산표를 다시 적는다.
          memory: 512M
BLOCK2
}
compose_done() { [ "$(exact_line_count "$CF" "  $SVC:")" = 1 ]; }
edit_compose() {
  local tmp blk before after nb na n n2 want rc=0
  mkdir -p "$TMPD"; chown root:root "$TMPD"; chmod 700 "$TMPD"
  tmp="$TMPD/compose.new"; blk="$TMPD/app-block.txt"
  before="$TMPD/img-before.txt"; after="$TMPD/img-after.txt"

  # ── ① 넣기 **전**의 모습이 기대한 그대로인가 ────────────────────────
  if [ "$(exact_line_count "$CF" "  $SVC:")" != 0 ]; then
    bad "🔴 compose 에 $SVC 가 **이미 있다** — 누가 먼저 넣었다"
    say "    → 고치지 말고 알리세요."
    return 1
  fi
  if [ "$(img_line_count "$CF" "$TAG")" != 0 ]; then
    bad "🔴 compose 에 「image: $TAG」 줄이 **이미 있다**"
    return 1
  fi
  n=$(grep -c "$ANCHOR" "$CF" 2>/dev/null)
  if [ "${n:-0}" != 1 ]; then
    bad "🔴 넣을 자리 표시가 ${n:-0}줄이다 (하나여야 한다) — 자리를 못 고른다"
    say "    → 고치지 말고 알리세요. $ANCHOR"
    return 1
  fi
  if grep -q "127\.0\.0\.1:$HPORT:" "$CF"; then
    bad "🔴 compose 에 $HPORT 이 이미 쓰이고 있다 — 다른 번호를 골라야 한다"
    return 1
  fi
  backup_compose || return 1
  nb=$(wc -l < "$CF")
  cf_img_list "$CF" > "$before"

  # ── ② 블록을 만들고 **줄 수를 먼저 센다** ───────────────────────────
  write_app_block "$blk" || { bad "넣을 블록을 만들지 못했다"; return 1; }
  n=$(wc -l < "$blk")
  want=$CF_BLOCK_BASE
  if [ "$n" != "$want" ]; then
    bad "🔴 넣을 블록이 ${n}줄이다 (${want}줄이어야 한다)"
    say "    → 이 스크립트가 아는 모양이 아니다. 고치지 말고 알리세요."
    return 1
  fi
  ok "넣을 블록 ${n}줄  [저장소] 개발 PC 사본에서 실제로 넣어 보고 세었다"
  # 🔴 공유폴더 줄이 **없어야** 한다(2026-10-22 결정). 베끼다 되살아나면 잡는다.
  # 🔴 **주석 속 예시를 세지 않는다.** 이 블록에는 「붙이는 날 이렇게 더한다」는
  #    예시 두 줄이 주석으로 들어 있다 — 그것까지 세면 **늘 ✗ 가 난다**(검사
  #    자신이 틀리는 그 자리다). 그래서 줄머리가 「- 」인 것만 센다.
  n2=$(grep -E '^[[:space:]]*-[[:space:]]' "$blk" | grep -c ':/mnt/nas')
  [ "${n2:-0}" = 0 ] && ok "블록에 공유폴더 볼륨이 **없다** (결정대로다 — 붙이는 날 더한다)" \
    || { bad "🔴 블록에 공유폴더 볼륨이 ${n2}줄 있다 — 이번 설치에서는 안 붙인다"; return 1; }

  # ── ③ 표시 줄 **바로 뒤**에 넣는다 (awk 한 번) ──────────────────────
  awk -v blk="$blk" -v anchor="$ANCHOR" '
    {
      print
      if (done == 0 && index($0, anchor) > 0) {
        while ((getline b < blk) > 0) print b
        close(blk)
        done = 1
      }
    }' "$CF" > "$tmp" || { bad "compose 를 못 썼다"; rm -f "$tmp"; return 1; }
  na=$(wc -l < "$tmp")
  if [ "$na" != "$((nb + n))" ]; then
    bad "🔴 줄 수가 ${nb} → ${na} 다 ($((nb + n)) 이어야 한다) — **바꾸지 않는다**"
    rm -f "$tmp"
    return 1
  fi
  ok "줄 수 ${nb} → ${na} (+${n}줄 — 기대한 그대로)"
  cp -p "$tmp" "$CF" && rm -f "$tmp"
  chown root:root "$CF"; chmod 644 "$CF"

  # ── ④ 넣은 뒤 ───────────────────────────────────────────────────────
  [ "$(exact_line_count "$CF" "  $SVC:")" = 1 ] \
    && ok "$SVC 서비스가 한 줄로 들어갔다" \
    || { bad "🔴 $SVC 가 안 들어갔다"; rc=1; }
  [ "$(img_line_count "$CF" "$TAG")" = 1 ] \
    && ok "image: $TAG 가 한 줄이다" || { bad "🔴 image 줄이 하나가 아니다"; rc=1; }
  cf_img_list "$CF" > "$after"
  { cat "$before"; printf 'image: %s\n' "$TAG"; } | sort > "$TMPD/img-expect.txt"
  if cmp -s "$TMPD/img-expect.txt" "$after"; then
    ok "🔴 image: 줄 전체 목록이 **우리 한 줄 말고는 글자까지 그대로**다"
    say "    🔵 건드리지 않는 쪽의 태그를 박아 두지 않았다 — 넣기 전 목록과 견준다."
  else
    bad "🔴 image: 줄이 우리 것 말고 **또 달라졌다** — 남의 변경이 섞였다"
    diff "$TMPD/img-expect.txt" "$after" 2>/dev/null | sed 's/^/      /' | head -10
    rc=1
  fi
  if [ "$rc" = 0 ]; then
    if compose_cmd config --quiet >/dev/null 2>&1; then
      ok "바꾼 compose 의 문법이 통과했다"
    else
      bad "🔴 바꾼 compose 에 문법 오류가 있다"
      compose_cmd config --quiet 2>&1 | sed 's/^/      /' | head -8
      rc=1
    fi
  fi
  if [ "$rc" = 0 ]; then
    compose_cmd config --services 2>/dev/null | grep -qx "$SVC" \
      && ok "서비스 목록에 $SVC 가 보인다 — **부를 수 있다**" \
      || { bad "🔴 서비스 목록에 $SVC 가 안 보인다"; rc=1; }
  fi
  if [ "$rc" = 0 ]; then
    for s in $SVC_ALL; do
      compose_cmd config --services 2>/dev/null | grep -qx "$s" \
        || { bad "🔴 $s 가 사라졌다 — 범위가 넘쳤다"; rc=1; }
    done
    [ "$rc" = 0 ] && ok "건드리지 않는 서비스 열여섯이 그대로다"
  fi
  if [ "$rc" != 0 ]; then
    restore_compose
    return 1
  fi
  say "  🔴 compose 를 고쳤다 — **아직 아무것도 안 뜨고 안 멈췄다.** 글자일 뿐이다."
  say "     🔴 다만 지금부터 **인자 없는 up -d 를 부르지 마세요.**"
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
# ══════════════════════════════════════════════════════════════════════
run_checks() {
  local v n code

  step "1-ㄱ. 이미지와 tar"
  v=$(tar_config_id "$IMAGES/$TARF" 2>/dev/null) || v=""
  see_tar "$TAG" "$IMAGES/$TARF" "$v" "$TAR_SIZE" "$TAR_MD5" "$TAR_CFG" || true
  if have_img "$TAG"; then
    ok "$TAG 가 실려 있다"
    if [ -n "$v" ]; then
      [ "$(img_id "$TAG")" = "$v" ] \
        && ok "🔴 실린 이미지 지문이 **tar 안 Config 와 같다**" \
        || { bad "🔴 실린 이미지가 그 tar 에서 온 것이 아니다"; doubt; }
    fi
    # 🔴 이미지 **안을 센다.** 「있는가」가 아니라 「무엇이 들었나」.
    n=$("$DOCKER" run --rm --network none --entrypoint sh "$TAG" -c \
        'ls /app/server.js >/dev/null 2>&1 && echo HAS_SERVER; ls -1 /app/tools 2>/dev/null | wc -l; ls -1 /app/public 2>/dev/null | wc -l; id -u' 2>&1)
    printf '%s\n' "$n" | sed 's/^/     /' | head -5
    case "$n" in
      *HAS_SERVER*) ok "이미지 안에 server.js 가 있다" ;;
      *)            bad "🔴 이미지 안에 server.js 가 없다 — 다른 이미지다" ;;
    esac
  else
    notyet "$TAG 가 아직 안 실렸다 — --preload 가 싣는다"
  fi

  step "1-ㄴ. 컨테이너가 돌 번호 · 공유폴더"
  say "  🔵 번호는 박아 두었다 — uid $APP_UID · gid $APP_GID  [실측] 2026-10-22 id 1026"
  say "     uid=1026(swhur) gid=100(users). 다른 집들의 1001 과 다르다 — 바꾸지 마라."
  # 🔴 이미지가 들고 있는 번호도 **읽어 둔다.** 같을 필요는 없다(compose 의
  #    user: 가 덮어쓴다). 다르다는 사실을 눈으로 보게 하려고 찍는다.
  if have_img "$TAG"; then
    v=$("$DOCKER" run --rm --network none --entrypoint sh "$TAG" -c 'id' 2>&1 | head -1)
    say "     · 이미지가 들고 있는 번호: $v (compose 의 user: 가 덮어쓴다)"
  fi
  note_shares

  step "1-ㄷ. 설정 파일 — 🔴 **이름과 빈칸만** 본다 (값도 길이도 안 찍는다)"
  if [ ! -f "$ENVF" ]; then
    notyet "rf-trouble.env 가 아직 없다 — --init 이 **이름만** 적은 틀을 만든다"
  else
    ok "rf-trouble.env 가 있다 ($(stat -c '%U:%G %a' "$ENVF"))"
    [ "$(stat -c '%a' "$ENVF")" = 600 ] && ok "모드 600" || bad "🔴 모드가 600 이 아니다 — 비밀값이 든 파일이다"
    for k in SSO_ISSUER SSO_CLIENT_ID SSO_CLIENT_SECRET SSO_REDIRECT_URI; do
      n=$(env_has "$ENVF" "$k")
      if [ "${n:-0}" = 1 ]; then ok "$k 가 한 줄 있다"
      elif [ "${n:-0}" = 0 ]; then bad "$k 가 **없다**  [저장소] docker.env.example"
      else bad "$k 가 ${n}줄이다 — 🔴 나중 것이 이긴다. 하나만 남기세요"
      fi
    done
    # 🔴 **값이 비었는지**까지 본다. 넷 중 하나라도 비면 앱이 로그인을 끈 채
    #    뜨고, 그러면 제 안 127.0.0.1 에만 열어 바깥에서 아예 못 닿는다.
    for k in SSO_ISSUER SSO_CLIENT_ID SSO_CLIENT_SECRET SSO_REDIRECT_URI; do
      v=$(env_val "$ENVF" "$k")
      [ -n "$v" ] && ok "$k 에 값이 들어 있다" \
        || notyet "🔴 $k 가 **비어 있다** — 로그인이 꺼진 채 뜨고 바깥에서 못 닿는다"
    done
    # 🔴 공개 주소 셋은 **글자 단위로** 맞춘다. 포털이 그렇게 대조한다.
    v=$(env_val "$ENVF" SSO_ISSUER)
    [ "$v" = "$ISSUER" ] && ok "SSO_ISSUER 가 $ISSUER 다 (끝 빗금 없이)  [결정]" \
      || { [ -n "$v" ] && bad "🔴 SSO_ISSUER 가 다르다 — 받은 값: $v  [결정] $ISSUER"; }
    v=$(env_val "$ENVF" SSO_CLIENT_ID)
    [ "$v" = "$CLIENT_ID" ] && ok "SSO_CLIENT_ID 가 $CLIENT_ID 다  [저장소] sources.ts" \
      || { [ -n "$v" ] && bad "🔴 SSO_CLIENT_ID 가 다르다 — 받은 값: $v"; }
    v=$(env_val "$ENVF" SSO_REDIRECT_URI)
    if [ "$v" = "$REDIR" ]; then
      ok "🔴 SSO_REDIRECT_URI 가 $REDIR 다 — **auth 한 겹이 없는** 그 길이다"
    elif [ -n "$v" ]; then
      bad "🔴 SSO_REDIRECT_URI 가 다르다 — 받은 값: $v"
      say "       기대: $REDIR  [저장소] server.js 가 그 글자로 길을 연다"
    fi
    for k in NAS_USER NAS_PASS TEAM_PASSWORD PORT HOST TZ WORKLOG; do
      n=$(env_has "$ENVF" "$k")
      [ "${n:-0}" = 0 ] && ok "$k 가 없다 (맞다 — 이미지·compose 가 넘긴다)" \
        || bad "$k 가 **있다** (${n}줄) — 지우세요"
    done
    n=$(grep -ciE '^[[:space:]]*SSO=off' "$ENVF" 2>/dev/null)
    [ "${n:-0}" = 0 ] && ok "SSO=off 줄이 없다" \
      || bad "🔴 SSO=off 가 있다 — 로그인이 꺼지고 바깥에서 아예 못 닿는다"
  fi
  say "    🔵 compose 가 통째로 안 먹지 않도록 **남의 env 파일 여덟**도 센다:"
  for f in $ENV_FILES; do
    [ -s "$ENVD/$f" ] && ok "env/$f 가 있다" || bad "🔴 env/$f 가 없다 — compose 가 통째로 막힌다"
  done

  step "1-ㄹ. 자리 — 데이터 폴더 · 사본 폴더 · config.json"
  if [ -d "$DATA" ]; then
    v=$(stat -c '%u:%g %a' "$DATA" 2>/dev/null)
    say "    · $DATA · $v (숫자) · $(stat -c '%U:%G' "$DATA" 2>/dev/null) (이름)"
    # 🔴 판정은 **숫자**로 한다. DSM 에 그 번호짜리 계정이 있으면 %U 가 그
    #    이름으로 보여 「번호가 아니다」로 잘못 읽는다.
    if isnum "${APP_UID:-}"; then
      case "$v" in
        "$APP_UID:$APP_GID "*) ok "주인이 $APP_UID:$APP_GID 다" ;;
        *) bad "🔴 주인이 $APP_UID:$APP_GID 이 아니다 ($v) — 컨테이너가 못 쓴다" ;;
      esac
      case "$v" in
        *" 700") ok "모드 700 (🔴 그 안에 세션 서명 열쇠가 있다)" ;;
        *)       bad "🔴 모드가 700 이 아니다 ($v) — .session-secret 이 남에게 열린다" ;;
      esac
      n=$(find "$DATA" ! -uid "$APP_UID" 2>/dev/null | wc -l)
      [ "${n:-1}" = 0 ] && ok "폴더 아래 전부가 uid $APP_UID 것이다" \
        || { bad "주인이 다른 것이 ${n}개 있다 — chown -R $APP_UID:$APP_GID $DATA"
             find "$DATA" ! -uid "$APP_UID" 2>/dev/null | head -5 | sed 's/^/       /'; }
      n=$("$ACLT" -get "$DATA" 2>&1 | grep -cE ':(allow|deny):')
      [ "${n:-1}" = 0 ] && ok "ACL 항목 0개 (걷혔다)" \
        || bad "ACL 항목이 ${n}개 남아 있다 — 컨테이너가 막힌다"
      probe_write
    else
      unk "번호를 모르니 주인을 판정하지 않는다"
    fi
  else
    notyet "$DATA 가 아직 없다 — --init 이 만든다"
  fi
  if [ -d "$BKDIR" ]; then
    ok "사본 폴더가 있다 ($(stat -c '%u:%g %a' "$BKDIR"))"
  else
    notyet "$BKDIR 이 아직 없다 — --init 이 만든다"
  fi
  if [ -f "$DATA/config.json" ]; then
    ok "🔴 config.json 이 **파일**이다 ($(stat -c '%u:%g %a' "$DATA/config.json"))"
    say "       🔴 안은 안 찍는다 — 공유폴더 경로가 들어 있다."
    # 열 수 있는가. 못 읽으면 앱이 설정 없이 뜬다(오류가 안 난다).
    if have_img "$TAG" && isnum "${APP_UID:-}"; then
      v=$("$DOCKER" run --rm --network none -u "$APP_UID:$APP_GID" \
          -v "$DATA/config.json:/app/config.json:ro" --entrypoint sh "$TAG" -c \
          'head -c 1 /app/config.json >/dev/null 2>&1 && echo CFG_READ_OK || echo CFG_READ_FAIL' 2>&1)
      case "$v" in
        *CFG_READ_OK*)   ok "🔴 uid $APP_UID 이 config.json 을 **실제로 읽었다**" ;;
        *CFG_READ_FAIL*) bad "🔴 uid $APP_UID 이 config.json 을 못 읽는다 — 설정 없이 뜬다" ;;
        *)               unk "config.json 읽기를 판정하지 못했다" ;;
      esac
    fi
  elif [ -e "$DATA/config.json" ]; then
    bad "🔴 config.json 자리에 파일이 아닌 것이 있다 — 도커가 만든 빈 폴더다"
    say "       손으로 지우고 사람이 만든 파일을 놓으세요:  rmdir $DATA/config.json"
  else
    notyet "config.json 이 아직 없다 — **사람이 만든다**(--init 이 자리를 안내한다)"
  fi

  step "1-ㅂ. compose"
  if compose_cmd config --quiet >/dev/null 2>&1; then
    ok "지금 compose 의 문법이 통과한다"
  else
    bad "🔴 지금 compose 가 문법에서 걸린다 — 세우기 전에 사람이 봐야 한다"
    compose_cmd config --quiet 2>&1 | sed 's/^/     /' | head -8
  fi
  n=$(grep -c "$ANCHOR" "$CF" 2>/dev/null)
  [ "${n:-0}" = 1 ] && ok "넣을 자리 표시가 한 줄이다" \
    || bad "🔴 넣을 자리 표시가 ${n:-0}줄이다 — --init 이 멈춘다"
  if compose_done; then
    ok "compose 에 $SVC 가 **이미 들어 있다** (DONE)"
    svc_block "$CF" "$SVC" | sed 's/^/     /' | head -20
  else
    notyet "compose 에 $SVC 가 아직 없다 — **--init 이 넣는다** (PENDING)"
  fi
  if netstat -tln 2>/dev/null | grep -q ":$HPORT "; then
    if running "$CNAME"; then
      ok "$HPORT 을 듣는 것이 있다 — 우리 컨테이너다"
    else
      bad "🔴 $HPORT 을 **남이** 듣고 있다"
      netstat -tln 2>/dev/null | grep ":$HPORT " | sed 's/^/       /'
    fi
  else
    ok "$HPORT 을 듣는 것이 아직 없다 (안 띄웠으면 맞다)"
  fi

  step "1-ㅅ. 포털 등록 — 🔴 주소 넷을 **글자 단위로** 맞춘다"
  if running dss-pg-auth; then
    v=$("$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth -X -tAq' <<'SQL' 2>/dev/null | head -1 | tr -d ' \r'
select count(*) from clients where client_id = 'dss-rf-trouble';
SQL
)
    if isnum "${v:-}" && [ "$v" = 1 ]; then
      ok "포털에 $CLIENT_ID 이 등록돼 있다"
      "$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth -X -tAq' <<'SQL' > "$TMPD.client" 2>/dev/null
select array_to_string(redirect_uris, ','), coalesce(backchannel_logout_uri,''), requires_grant, is_active, length(client_secret_hash)
from clients where client_id = 'dss-rf-trouble';
SQL
      v=$(head -1 "$TMPD.client" 2>/dev/null)
      rm -f "$TMPD.client"
      say "    · 받은 값: $v"
      case "$v" in
        "$REDIR|$BACKCH|t|t|64")
          ok "🔴 주소 둘 · requires_grant · is_active · 해시길이가 **전부 맞다**" ;;
        *)
          bad "🔴 포털에 적힌 값이 기대와 다르다"
          say "       기대: $REDIR|$BACKCH|t|t|64"
          say "       🔴 콜백은 /api/sso/callback 이다 — auth 한 겹이 없다."
          say "       고치는 길:  sh /volume1/dss/setup/32-rf-trouble-client.sh"
          doubt ;;
      esac
    elif isnum "${v:-}"; then
      notyet "포털에 $CLIENT_ID 이 아직 없다 — 32-rf-trouble-client.sh 가 넣는다"
      say "    🔴 등록 전에는 포털이 그 집을 **부르러 가지도 않는다.**"
    else
      unk "포털 clients 를 못 쟀다 — psql 이 수를 안 돌려줬다"
    fi
  else
    unk "dss-pg-auth 가 안 돌고 있어 포털 쪽을 못 쟀다"
  fi

  step "1-ㅇ. 야간 백업 — 🔴 이 시스템은 **폴더 하나가 전부**다"
  if [ -f "$JOB" ]; then
    n=$(grep -c 'rf-trouble-data' "$JOB" 2>/dev/null)
    if [ "${n:-0}" -ge 1 ]; then
      ok "🔴 NAS 의 backup-nightly.sh 에 rf-trouble-data 줄이 ${n}개 **있다**"
    else
      notyet "🔴 NAS 의 backup-nightly.sh 에 rf-trouble-data 가 **없다** — --init 이 올린다"
      say "       🔴 「고쳤다」와 「올렸다」는 다른 일이다. 2026-09-29 에 개선요청이"
      say "          그 차이로 11일간 아무 오류 없이 백업되지 않았다."
    fi
    bash -n "$JOB" 2>/dev/null && ok "야간 백업 문법 통과" || bad "🔴 야간 백업에 문법 오류가 있다"
  else
    bad "🔴 야간 백업 스크립트가 없다: $JOB"
  fi
  n=$(find "$BKDB" -name '*.dump' -mtime -2 2>/dev/null | wc -l | tr -d ' ')
  if isnum "${n:-}" && [ "$n" -ge 7 ]; then
    ok "이틀 안에 뜬 덤프가 ${n}개 (DB 일곱 이상)"
  else
    bad "🔴 이틀 안에 뜬 덤프가 ${n:-?}개다 — 일곱을 기대했다. **세우기 전에 백업부터**"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  fi

  step "1-ㅈ. 바깥 주소 — 건드리지 않는 여덟"
  for h in $HOSTS8; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$h.dss21.co.kr → $code" ;;
      *)       bad "🔴 https://$h.dss21.co.kr → ${code:-없음} — 건드리지 않는 쪽이 흔들렸다" ;;
    esac
  done
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$BASE/" 2>/dev/null)
  say "    · $BASE → ${code:-없음}"
  case "$code" in
    2??|3??) ok "$BASE 가 **이미 받고 있다** (프록시가 섰다)" ;;
    502)     notyet "$BASE → 502 — 프록시는 섰는데 앱이 아직 없다(안 띄웠으면 맞다)" ;;
    *)       notyet "$BASE → ${code:-없음} — DNS · DSM 리버스 프록시가 아직 없다" ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════
case "$MODE" in
rollback)
  echo "════════ 되돌리기 안내 (아무것도 바꾸지 않습니다) ════════"
  cat <<ROLL
  이 설치는 **아무것도 멈추지 않는다** — 없던 것을 하나 세울 뿐이다.
  그래서 되돌리기도 「세운 것을 치우는」 일이다.

  1) 앱만 내린다 (다른 아홉은 그대로)
       $DOCKER compose --project-directory $D/deploy \\
         -f $CF --env-file $ENV_NAS stop $SVC
       $DOCKER compose --project-directory $D/deploy \\
         -f $CF --env-file $ENV_NAS rm -f $SVC

  2) compose 를 사본으로 되돌린다 (가장 최근 것)
       ls -lt $BKD/docker-compose.nas.yml.* | head -3
       cp -p $BKD/docker-compose.nas.yml.<시각> $CF

  3) 포털 등록만 끄고 싶으면 (지우지 않는다 — 끈다)
       $DOCKER exec -i dss-pg-auth sh -c 'psql -U "\$POSTGRES_USER" -d dss_auth'
         update clients set is_active = false where client_id = '$CLIENT_ID';

  🔴 **자료 폴더($DATA)는 지우지 않는다.** 그 안에 이슈와 첨부가 있다.
  🔴 야간 백업 스크립트도 되돌릴 수 있다:
       ls -lt $JOB.bak-* | head -3
ROLL
  exit 0 ;;
esac

echo "════════════════════════════════════════════════════════════"
echo "  RF 이슈관리(아홉째) 첫 설치 · 모드 **$MODE** · $(date '+%F %T')"
echo "  로그: $LOG"
case "$MODE" in
  check)   echo "  🔵 읽기만 합니다. 아무것도 바꾸지 않습니다." ;;
  preload) echo "  🔵 이미지를 싣습니다. 아무것도 안 멈춥니다." ;;
  init)    echo "  🔴 **자리를 만듭니다** — 폴더 · 권한 · 설정 틀 · 야간 백업 · compose." ;;
  go)      echo "  🔴 **앱을 띄웁니다.** 멈추는 것은 없습니다 — 하나를 새로 세웁니다." ;;
esac
echo "════════════════════════════════════════════════════════════"

# 건드리지 않는 쪽의 시작 시각을 적어 둔다 — 말로 하지 않는다
mkdir -p "$TMPD"; chown root:root "$TMPD"; chmod 700 "$TMPD"
for b in $KEEP_BOXES; do
  printf '%s %s\n' "$b" "$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$b" 2>/dev/null)" >> "$TMPD/started-before.txt"
done

case "$MODE" in

# ══ --preload ═════════════════════════════════════════════════════════
preload)
  step "이미지를 싣는다"
  EXP=$(tar_config_id "$IMAGES/$TARF" 2>/dev/null) || EXP=""
  if [ -z "$EXP" ]; then
    bad "$IMAGES/$TARF 에서 manifest.json 을 읽지 못했다"
    stop "이미지를 확인하지 못했습니다. **아무것도 안 실었습니다.**"
  fi
  see_tar "$TAG" "$IMAGES/$TARF" "$EXP" "$TAR_SIZE" "$TAR_MD5" "$TAR_CFG" || true
  bring_img "$TAG" "$IMAGES/$TARF" "$EXP" || stop "싣기에서 멈췄습니다."
  say
  say "  🔴 이미지 **안을 센다** — 「실었다」가 아니라 「무엇이 들었나」."
  "$DOCKER" run --rm --network none --entrypoint sh "$TAG" -c \
    'echo "uid=$(id -u) gid=$(id -g)"; ls /app/server.js; echo "tools: $(ls -1 /app/tools | wc -l)"; echo "public: $(ls -1 /app/public | wc -l)"; node --version' 2>&1 | sed 's/^/     /'
  ok "이미지 안을 열어 보았다 (위 값을 Claude 에게 알려 주세요)"
  say
  say "  다음:  bash $0 --init"
  ;;

# ══ --init ════════════════════════════════════════════════════════════
init)
  step "0. 시작해도 되는지 먼저 본다"
  N=$(find "$BKDB" -name '*.dump' -mtime -2 2>/dev/null | wc -l | tr -d ' ')
  if isnum "${N:-}" && [ "$N" -ge 7 ]; then
    ok "이틀 안에 뜬 덤프가 ${N}개 — 되돌릴 자리가 있다"
  else
    bad "🔴 오늘(어제) 백업이 없다 — **시작하지 않는다**"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    stop "백업부터 떠 주세요."
  fi
  isnum "${APP_UID:-}" || stop "번호가 수가 아닙니다. **아무것도 안 만들었습니다.**"
  isnum "${APP_GID:-}" || stop "번호가 수가 아닙니다. **아무것도 안 만들었습니다.**"

  step "1. 데이터 폴더와 사본 폴더를 만든다 (uid $APP_UID · gid $APP_GID)"
  say "  🔵 [실측] 2026-10-22 NAS 에서 id 1026 → uid=1026(swhur) gid=100(users)."
  say "     다른 집들의 1001 과 다르다 — 이 저장소의 compose 가 적고 있던 번호다."
  say "  🔴 모드는 **700** 이다. 이 안에 세션 서명 열쇠(.session-secret)가 있다 —"
  say "     그 파일 하나면 누구든 남의 세션 쿠키를 구울 수 있다."
  mkdir -p "$DATA" "$BKDIR" || stop "폴더를 만들지 못했습니다."
  # dss 공유폴더에는 시놀로지 ACL(administrators 만)이 걸려 있는데 uid 는 DSM
  # 계정이 아니라 ACL 로 권한을 줄 수 없다. 그래서 **이 폴더만** ACL 을 걷고
  # 리눅스 권한으로 준다 — 01-prepare.sh 가 as-attachments 에 한 것과 같다.
  # 🔵 여기서 ACL 을 걷어도 끊기는 사람이 없다. 새로 만드는 폴더다.
  find "$DATA" -exec "$ACLT" -del {} \; >/dev/null 2>&1
  find "$BKDIR" -exec "$ACLT" -del {} \; >/dev/null 2>&1
  chown -R "$APP_UID:$APP_GID" "$DATA" "$BKDIR" || stop "주인을 바꾸지 못했습니다."
  chmod 700 "$DATA" "$BKDIR" || stop "모드를 바꾸지 못했습니다."
  # 🔴 「만들었다」가 아니라 **되읽은 값**으로 판정한다. 숫자(%u:%g)로 본다 —
  #    DSM 에 그 번호짜리 계정이 있으면 %U 가 그 이름으로 보인다.
  V=$(stat -c '%u:%g %a' "$DATA" 2>/dev/null)
  say "  · $DATA · $V (숫자) · $(stat -c '%U:%G' "$DATA" 2>/dev/null) (이름)"
  case "$V" in
    "$APP_UID:$APP_GID 700") ok "주인과 모드를 되읽어 확인했다" ;;
    *) bad "🔴 되읽은 값이 다르다 ($V)" ;;
  esac
  V=$(stat -c '%u:%g %a' "$BKDIR" 2>/dev/null)
  say "  · $BKDIR · $V"
  case "$V" in
    "$APP_UID:$APP_GID 700") ok "사본 폴더도 되읽어 확인했다" ;;
    *) bad "🔴 사본 폴더의 되읽은 값이 다르다 ($V)" ;;
  esac
  N=$("$ACLT" -get "$DATA" 2>&1 | grep -cE ':(allow|deny):')
  [ "${N:-1}" = 0 ] && ok "ACL 항목 0개 (걷혔다)" || bad "ACL 항목이 ${N}개 남아 있다"
  probe_write

  step "2. 공유폴더 — 🔴 **이번에는 안 붙인다** (2026-10-22 쓰는 분 결정)"
  note_shares
  say "     🔴 붙이는 날 할 일은 compose 의 app-rf-trouble 블록 안 주석에 적어 두었다"
  say "        (볼륨 두 줄의 꼴 · :ro · pathMap 과 맞추기 · 읽히는지 값으로 재기)."

  step "3. 설정 틀을 만든다 — 🔴 **이름만 적는다. 값은 사람이 넣는다**"
  if [ -f "$ENVF" ]; then
    ok "rf-trouble.env 가 이미 있다 — **덮어쓰지 않는다**(비밀값이 들어 있을 수 있다)"
  else
    # 🔴 공개로 정해진 셋은 값까지 적는다. 비밀값 한 줄만 비워 둔다.
    #    [결정] 2026-10-22 · [저장소] dss-trouble/docker.env.example 의 이름들
    cat > "$ENVF" <<ENVEOF
# /volume1/dss/deploy/env/rf-trouble.env
# 🔴 RF 이슈관리(dss-trouble). 32-rf-trouble-deploy.sh --init 이 만들었다.
#
# 🔴 들어오는 길은 **이것 하나**다. 팀 공용 비밀번호 길은 2026-10-21 에
#    코드에서 걷혔다 — 포털이 멈추면 아무도 못 들어온다.
# 🔴 네 값이 **모두** 차야 로그인이 켜진다. 하나라도 비면 앱이 제 안
#    127.0.0.1 에만 열어 **바깥에서 아예 못 닿는다**(증상은 502 다).
#
# 아래 셋은 정해진 공개 주소다(2026-10-22 결정). 고치지 마세요.
SSO_ISSUER=$ISSUER
SSO_CLIENT_ID=$CLIENT_ID
SSO_REDIRECT_URI=$REDIR
# 🔴 비밀값. 이 줄만 비어 있다. 채우는 가장 쉬운 길 —
#      sh /volume1/dss/setup/32-rf-trouble-client.sh --make-secret
#    그 스크립트가 값을 만들어 이 줄에 넣고, 포털에는 sha256 만 넣는다.
#    🔴 평문은 이 파일(root 600) 한 곳에만 둔다. 채팅·로그에 적지 않는다.
SSO_CLIENT_SECRET=
# 🔵 선택 — AI 검색을 쓸 때만. config.json 의 ai.enabled 도 true 로.
#OPENAI_API_KEY=
#
# 🔴 여기 적으면 안 되는 것:
#    PORT · HOST · TZ · WORKLOG  — 이미지와 compose 가 넘긴다
#    NAS_USER · NAS_PASS         — 개발 PC 의 Docker Desktop 전용이다
#    SSO=off                     — 로그인이 꺼진다
ENVEOF
    chown root:root "$ENVF" && chmod 600 "$ENVF" || stop "설정 파일 권한을 못 맞췄습니다."
    ok "rf-trouble.env 를 만들었다 ($(stat -c '%U:%G %a' "$ENVF"))"
    say "     키 $(grep -cE '^[A-Z_]+=' "$ENVF") 개 (🔴 값은 안 찍는다)"
  fi
  if [ -f "$DATA/config.json" ]; then
    ok "config.json 이 이미 있다 (파일)"
  else
    bad "🔴 config.json 이 아직 없다 — **사람이 만들어 놓아야 한다**"
    say "     저장소의 config.docker.example.json 을 복사해 아래에 두세요:"
    cmd "$DATA/config.json"
    say "     🔵 공유폴더를 아직 안 붙였으므로 이번에는 이렇게 두기를 권합니다:"
    say "       · backup.dir 은 **\"/backup\"**(절대 경로) — 우리 블록이 붙인 자리다"
    say "       · autoRefreshSec 는 **0** — 공유폴더가 없어 헛걸음할 것이 없다"
    say "         (붙이는 날 60 으로 되돌린다)"
    say "       · sourceExcel · baseDir · pathMap 은 비워 두거나 그대로 둬도 된다 —"
    say "         붙이는 날 pathMap 오른쪽을 /mnt/nas7 · /mnt/nas1 로 맞춘다"
    say "     🔴 놓은 뒤 주인을 맞추세요:"
    cmd "chown $APP_UID:$APP_GID $DATA/config.json"
    say "     🔴 이 파일 없이 --go 를 부르면 도커가 그 자리에 **빈 폴더를**"
    say "        만들어 붙인다 — 앱이 설정을 못 읽는데 오류가 안 난다."
  fi

  step "4. 야간 백업 — 🔴 이 시스템은 **폴더 하나가 전부**다"
  if [ -s "$IN/backup-nightly.sh" ]; then
    say "  · 올라온 것: md5 $(md5_of "$IN/backup-nightly.sh")"
    say "    🔴 개발 PC 에서 잰 값과 눈으로 맞추세요. 다르면 멈추세요."
    if ! grep -q 'rf-trouble-data' "$IN/backup-nightly.sh"; then
      bad "🔴 올라온 backup-nightly.sh 에 rf-trouble-data 가 **없다** — 놓지 않는다"
    elif ! bash -n "$IN/backup-nightly.sh" 2>/dev/null; then
      bad "🔴 올라온 backup-nightly.sh 에 문법 오류가 있다 — 놓지 않는다"
      bash -n "$IN/backup-nightly.sh" 2>&1 | sed 's/^/     /' | head -5
    else
      cp -a "$JOB" "$JOB.bak-$STAMP" 2>/dev/null && say "  · 옛것 사본: $(basename "$JOB").bak-$STAMP"
      cp "$IN/backup-nightly.sh" "$JOB" || stop "야간 백업을 놓지 못했습니다."
      chown root:root "$JOB" && chmod 700 "$JOB" || stop "야간 백업 권한을 못 맞췄습니다."
      ok "jobs/backup-nightly.sh 를 새 판으로 놓았다"
    fi
  else
    say "  · incoming 에 새 backup-nightly.sh 가 없다 — 제자리 것을 그대로 센다"
  fi
  # 🔴 「고쳤다」가 아니라 **「제자리 것이 그것을 아는가」**를 센다.
  #    2026-09-29 에 개선요청이 저장소에는 들어가 있었는데 NAS 에 안 올라가
  #    11일간 아무 오류 없이 백업되지 않았다. 그 자리가 여기다.
  N=$(grep -c 'rf-trouble-data' "$JOB" 2>/dev/null)
  if [ "${N:-0}" -ge 1 ]; then
    ok "🔴 **NAS 의** backup-nightly.sh 에 rf-trouble-data 줄이 ${N}개 있다"
    say "     md5 $(md5_of "$JOB")"
  else
    bad "🔴 **NAS 의** backup-nightly.sh 에 rf-trouble-data 가 없다"
    say "     개발 PC 에서 고친 판을 올리세요:"
    cmd "scp -O nas/jobs/backup-nightly.sh dss-nas:/volume1/dss/setup/incoming/"
    say "     그 뒤 이 모드를 다시 부르면 놓고 다시 셉니다."
  fi
  bash -n "$JOB" 2>/dev/null && ok "야간 백업 문법 통과" || bad "🔴 야간 백업에 문법 오류가 있다"

  step "5. 🔴 compose 에 $SVC 블록을 넣는다"
  if compose_done; then
    ok "이미 들어 있다 — 다시 넣지 않는다 (DONE)"
  else
    edit_compose || stop "compose 를 고치지 못했습니다. **사본으로 되돌렸습니다.**"
  fi

  step "6. 건드리지 않은 것이 정말 그대로인가"
  for b in $KEEP_BOXES; do
    A=$(grep "^$b " "$TMPD/started-before.txt" 2>/dev/null | awk '{print $2}')
    B=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$b" 2>/dev/null)
    if [ -z "$A" ] || [ -z "$B" ]; then
      unk "$b 의 시작 시각을 못 쟀다"
    elif [ "$A" = "$B" ]; then
      ok "$b 시작 시각 그대로"
    else
      bad "🔴 $b 가 다시 떴다 ($A → $B)"
    fi
  done

  say
  say "  🔴 **아직 아무것도 안 떴습니다.** 다음 차례:"
  say "     ① 포털 등록과 비밀값:"
  cmd "sh /volume1/dss/setup/32-rf-trouble-client.sh --make-secret"
  say "     ② config.json 을 $DATA 에 놓는다 (사람이 만든다)"
  say "     ③ DSM 리버스 프록시 · Cloudflare A 레코드 (아래 안내)"
  say "     ④ 다시 읽기만:  bash $0"
  say "     ⑤ 띄우기:       bash $0 --go"
  ;;

# ══ --go ══════════════════════════════════════════════════════════════
go)
  step "1. 준비가 됐는지 기계로 본다 (아직 아무것도 안 띄웠다)"
  run_checks
  if [ "$FAIL" != 0 ] || [ "$UNK" != 0 ]; then
    say
    say "  ✗ $FAIL 개 · ? $UNK 개 — **아무것도 띄우지 않았습니다.**"
    say "  🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요.** 기대값의 출처는"
    say "     그 줄 바로 옆 주석에 있습니다([설문]·[저장소]·[결정]·[사람])."
    stop "준비가 덜 됐습니다."
  fi
  ok "준비 검사 $PASS 개 전부 통과"

  step "2. 🔴 띄우기 **직전에** 다시 센다 (바뀐 사이 누가 손댔을 수 있다)"
  compose_done || stop "compose 에 $SVC 가 없습니다. --init 을 먼저 부르세요."
  have_img "$TAG" || stop "$TAG 가 없습니다. --preload 를 먼저 부르세요."
  [ -f "$DATA/config.json" ] || stop "config.json 이 없습니다. 사람이 먼저 놓아야 합니다."
  for k in SSO_ISSUER SSO_CLIENT_ID SSO_CLIENT_SECRET SSO_REDIRECT_URI; do
    [ -n "$(env_val "$ENVF" "$k")" ] || stop "$k 가 비어 있습니다. 로그인이 꺼진 채 뜹니다."
  done
  ok "설정 넷이 전부 차 있다 (값은 안 찍는다)"

  step "3. $SVC 를 띄운다  (🔴 멈추는 것은 없다 — 새로 하나 세운다)"
  say "  그대로 도는 것: 포털 · A/S · 계측기 · 개선요청 · PO · 휴가 · 게시판 ·"
  say "                  재고 관리 · DB 둘."
  say "  🔴 인자 없는 up -d 를 부르지 않는다 — --no-deps 로 **이름을 적은 하나만.**"
  T0=$SECONDS
  STOP_AT=$(date '+%F %T')
  say "  띄운 시각: $STOP_AT"
  compose_cmd up -d --no-deps "$SVC" 2>&1 | sed 's/^/    /'
  wait_http "RF 이슈관리" "$HPORT" "$HEALTH" "$CNAME"
  UP_AT=$(date '+%F %T')
  DOWN=$((SECONDS - T0))
  say
  say "  ⏱ 띄운 시각 $STOP_AT → 대답한 시각 $UP_AT · **약 ${DOWN}초**"

  step "4. 스모크 — 🔴 「도는가」가 아니라 **「값이 돌아오는가」**"

  say "  4-ㄱ. 컨테이너가 살아 있는가"
  if running "$CNAME"; then
    ok "$CNAME 이 돌고 있다"
    "$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$CNAME " | sed 's/^/      /'
  else
    bad "$CNAME 이 안 돌고 있다 — 떴다가 죽었다"
    cmd "$DOCKER logs --tail 50 $CNAME"
  fi

  say "  4-ㄴ. 🔴 건강 통로가 **값을 돌려주는가** (Dockerfile 의 HEALTHCHECK 가 쓰는 길)"
  BODY=$(curl -s -m 10 "http://127.0.0.1:$HPORT$HEALTH" 2>/dev/null)
  say "      받은 것: ${BODY:-없음}"
  case "$BODY" in
    *'"ok"'*|*'ok'*true*) ok "🔴 $HEALTH 가 ok 를 돌려줬다" ;;
    "")                   bad "🔴 아무것도 안 돌아왔다 — 설정 넷이 비면 제 안에만 연다" ;;
    *)                    bad "🔴 뜻밖의 답이다 — 위 값을 보세요" ;;
  esac

  say "  4-ㄷ. 🔴 로그인 통로가 **어디로 보내는가** (통로가 아니라 나오는 것을 본다)"
  say "      🔴 정직하게 적어 둔다 — 이 집의 /api/sso/start 는 **포털에 묻지 않는다.**"
  say "         설정으로 주소를 조립할 뿐이다(그 저장소 tools/sso.js 의 authorizeUrl)."
  say "         그러니 이 줄은 **주소 둘**만 증명한다. 나가는 길은 4-ㄹ 이 본다."
  LOC=$(curl -s -o /dev/null -w '%{redirect_url}' -m 20 "http://127.0.0.1:$HPORT/api/sso/start" 2>/dev/null)
  say "      보내는 곳(물음표 앞까지): ${LOC%%[?]*}"
  case "$LOC" in
    "")  bad "🔴 아무 데로도 안 보낸다 — 302 가 안 왔다(로그인이 꺼져 있으면 404 다)"
         cmd "$DOCKER logs --tail 50 $CNAME" ;;
    "$ISSUER"/api/oidc/authorize*)
      ok "🔴 포털의 /api/oidc/authorize 로 보낸다 — SSO_ISSUER 가 맞다"
      case "$LOC" in
        *issues.dss21.co.kr%2Fapi%2Fsso%2Fcallback*|*issues.dss21.co.kr/api/sso/callback*)
          ok "🔴 redirect_uri 가 **auth 한 겹 없는** 그 주소다" ;;
        *) bad "🔴 redirect_uri 가 기대와 다르다 — 끝에서 거절된다"
           say "         기대: $REDIR" ;;
      esac
      case "$LOC" in
        *client_id=dss-rf-trouble*) ok "client_id 가 dss-rf-trouble 이다" ;;
        *) bad "🔴 client_id 가 dss-rf-trouble 이 아니다 — 포털이 모른다" ;;
      esac
      case "$LOC" in
        *172.*|*192.168.*) bad "🔴 주소에 사설 IP 가 섞였다 — 설정에 auto 가 남았다" ;;
      esac ;;
    *) bad "🔴 뜻밖의 곳으로 보낸다 — ${LOC%%[?]*}"
       say "         rf-trouble.env 의 SSO_ISSUER 를 보세요." ;;
  esac

  say "  4-ㄹ. 🔴 컨테이너가 **바깥으로 나갈 수 있는가** (dss-edge)"
  say "      포털의 공개 열쇠를 **실제로 받아 본다.** 못 받으면 로그인이 끝에서 깨진다."
  OUT=$("$DOCKER" exec "$CNAME" node -e '
    fetch("'"$ISSUER"'/.well-known/jwks.json").then(function (r) {
      return r.text();
    }).then(function (t) {
      console.log("EGRESS_OK " + (t.indexOf("keys") >= 0 ? "HASKEYS" : "NOKEYS"));
    }).catch(function (e) {
      console.log("EGRESS_FAIL " + e.message);
    });' 2>&1)
  printf '%s\n' "$OUT" | sed 's/^/      /' | head -3
  case "$OUT" in
    *"EGRESS_OK HASKEYS"*) ok "🔴 포털의 공개 열쇠를 **받아 왔다** — 나가는 길이 열려 있다" ;;
    *"EGRESS_OK NOKEYS"*)  bad "🔴 닿기는 하는데 열쇠가 안 들어 있다 — 포털 쪽을 보세요" ;;
    *"EGRESS_FAIL"*)       bad "🔴 못 나간다 — compose 의 networks 에 dss-edge 가 있는지 보세요" ;;
    *)                     unk "나가는 길을 판정하지 못했다 — 위가 그대로의 출력이다" ;;
  esac

  say "  4-ㅁ. 🔴 포털이 **우리에게** 말 거는 통로 둘이 서 있는가"
  say "      자격증명 없이 한 번 두드린다. 🔴 **401 이 맞는 답이다.**"
  say "        404 → 통로가 없다(옛 이미지) 또는 로그인이 꺼져 있다"
  say "        200 → 🔴 아무나 남의 알림을 볼 수 있다는 뜻이다"
  CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "http://127.0.0.1:$HPORT$NOTIF" 2>/dev/null)
  case "$CODE" in
    401) ok "🔴 $NOTIF → 401 (통로가 있고 문이 돈다)" ;;
    404) bad "🔴 → 404 — 통로가 없거나 로그인이 꺼져 있다" ;;
    200) bad "🔴 → 200 — **문이 안 돌고 있다.** 바로 알리세요" ;;
    *)   bad "🔴 → ${CODE:-없음} — 뜻밖의 답이다" ;;
  esac
  CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "http://127.0.0.1:$HPORT/api/integration/notification-settings" 2>/dev/null)
  case "$CODE" in
    401) ok "🔴 알림 설정 통로 → 401" ;;
    *)   bad "🔴 알림 설정 통로 → ${CODE:-없음} (401 을 기대했다)"
         say "         🔵 이 통로가 404 면 포털의 [알림 설정] 화면에 경고가 뜬다 —"
         say "            멀쩡한 시스템이 고장으로 보인다." ;;
  esac
  say "      🔵 알림 자체는 지금 **빈 목록**이다 — 이 시스템에는 제 알림이 아직"
  say "         없다. 고장이 아니다([저장소] 포털 sources.ts 의 그 주석)."

  say "  4-ㅂ. 🔴 도는 컨테이너가 자료 폴더에 **실제로 쓰나**"
  say "      (임시 컨테이너가 아니라 **지금 사람을 받는 그 컨테이너**로 본다.)"
  OUT=$("$DOCKER" exec "$CNAME" sh -c '
    echo "WHO $(id -u):$(id -g)"
    if touch /app/data/.dss-write-test 2>/dev/null; then
      echo "LIVE WRITE_OK"
    else
      echo "LIVE WRITE_FAIL"
    fi' 2>&1)
  printf '%s\n' "$OUT" | grep -E '^(WHO|LIVE) ' | sed 's/^/      /'
  case "$OUT" in
    *"LIVE WRITE_OK"*) ok "도는 컨테이너가 썼다" ;;
    *"LIVE WRITE_FAIL"*) bad "🔴 도는 컨테이너가 못 쓴다 — 이슈 저장이 통째로 안 된다" ;;
    *) bad "판정하지 못했다"; printf '%s\n' "$OUT" | sed 's/^/      /' | head -6 ;;
  esac
  # 🔴 볼륨이 **진짜로 밖을 가리키는가.** 안에만 쌓이면 다음 배포에서 전부 사라진다.
  if [ -f "$DATA/.dss-write-test" ]; then
    ok "🔴 컨테이너가 쓴 것이 NAS 폴더에 **보인다** — 볼륨이 제대로 붙었다"
    rm -f "$DATA/.dss-write-test"
  else
    bad "🔴 컨테이너가 쓴 것이 NAS 폴더에 **안 보인다** — 볼륨이 안 붙었다"
    say "         그 바이트는 컨테이너 안에 있고 **다음 배포에서 전부 사라진다.**"
    "$DOCKER" exec "$CNAME" sh -c 'rm -f /app/data/.dss-write-test' >/dev/null 2>&1
  fi
  # 🔴 세션 서명 열쇠가 **생겼는가.** 못 만들면 로그인이 될 때마다 풀린다.
  if [ -f "$DATA/.session-secret" ]; then
    ok "🔴 세션 서명 열쇠가 자리에 있다 ($(stat -c '%u:%g %a' "$DATA/.session-secret") · 🔴 내용은 안 찍는다)"
  else
    unk "세션 서명 열쇠가 아직 없다 — 첫 로그인 때 만들어진다"
  fi

  say "  4-ㅅ. 공유폴더 — 🔴 **안 붙인 것이 맞다** (2026-10-22 결정)"
  note_shares
  # 🔴 「안 붙였다」를 말로 하지 않고 **컨테이너 안에서 값으로** 본다.
  #    붙이는 날 이 수가 0 에서 둘로 바뀌는 것이 그날의 확인이 된다.
  OUT=$("$DOCKER" exec "$CNAME" sh -c '
    n=0
    for m in /mnt/nas7 /mnt/nas1; do
      if [ -d "$m" ]; then n=$((n + 1)); fi
    done
    echo "MNT $n"' 2>&1)
  printf '%s\n' "$OUT" | sed 's/^/      /' | head -2
  case "$OUT" in
    *"MNT 0"*) ok "컨테이너 안에 /mnt/nas7 · /mnt/nas1 이 **없다** — 결정대로다" ;;
    *"MNT "*)  bad "🔴 컨테이너 안에 붙은 자리가 있다 — 이번 설치에서는 없어야 한다"
               say "         compose 의 app-rf-trouble 볼륨을 보세요." ;;
    *)         unk "붙은 자리를 판정하지 못했다" ;;
  esac
  # 🔵 자동 재색인이 공유폴더를 못 찾아 한 번 실패하는 것은 **고장이 아니다.**
  #    로그에 그 줄이 보이면 「예상한 그것」임을 여기서 말해 둔다.
  LOGS=$("$DOCKER" logs --tail 60 "$CNAME" 2>&1)
  case "$LOGS" in
    *"[자동갱신] 실패"*)
      say "      🔵 로그에 「[자동갱신] 실패」가 있다 — **공유폴더가 없어서다.**"
      say "         한 번만 해 보고 그 지문을 기억해 다시 시도하지 않는다."
      say "         🔵 kb.json 은 덮어써지지 않는다(쓰기 전에 죽는다)." ;;
    *) say "      🔵 자동갱신 실패 줄이 아직 없다 (60초 전이면 정상이다)" ;;
  esac

  say "  4-ㅇ. 바깥 주소"
  CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$BASE/" 2>/dev/null)
  case "$CODE" in
    302|303) ok "$BASE → $CODE (포털로 넘긴다 — 이것이 기대한 값이다)" ;;
    2??|3??) ok "$BASE → $CODE" ;;
    502)     bad "$BASE → 502 — 앱은 떴는데 프록시가 못 닿는다"
             say "         DSM 프록시의 대상이 localhost:$HPORT 인지 보세요." ;;
    *)       bad "$BASE → ${CODE:-없음} — DNS · DSM 리버스 프록시 · 인증서" ;;
  esac
  say "  🔴 건드리지 않은 여덟이 그대로인가:"
  for h in $HOSTS8; do
    CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
    case "$CODE" in
      2??|3??) ok "https://$h.dss21.co.kr → $CODE (그대로다)" ;;
      *)       bad "🔴 https://$h.dss21.co.kr → ${CODE:-없음} — 건드리지 않은 쪽이 흔들렸다" ;;
    esac
  done
  say "  열린 포트 (127.0.0.1 만이어야 한다):"
  netstat -tln 2>/dev/null | grep ':1[0-9]\{4\} ' | sed 's/^/      /'
  N=$(netstat -tln 2>/dev/null | grep ":$HPORT " | grep -vc '127\.0\.0\.1')
  [ "${N:-1}" = 0 ] && ok "🔴 $HPORT 이 **127.0.0.1 에만** 열려 있다" \
    || bad "🔴 $HPORT 이 다른 주소에도 열렸다 — 저장소 compose.yaml 의 모양이 섞였다"

  say "  4-ㅈ. 건드리지 않은 열이 정말 그대로인가"
  for b in $KEEP_BOXES; do
    A=$(grep "^$b " "$TMPD/started-before.txt" 2>/dev/null | awk '{print $2}')
    B=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$b" 2>/dev/null)
    if [ -z "$A" ] || [ -z "$B" ]; then unk "$b 의 시작 시각을 못 쟀다"
    elif [ "$A" = "$B" ]; then ok "$b 시작 시각 그대로"
    else bad "🔴 $b 가 다시 떴다 ($A → $B)"; fi
  done
  say "  지금 도는 이미지:"
  "$DOCKER" ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | sed 's/^/      /'
  say "  🔴 메모리 — **아홉째입니다. 이 값을 compose 맨 아래 예산표에 옮겨 적습니다:**"
  "$DOCKER" stats --no-stream --format '{{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}' 2>/dev/null | sed 's/^/      /'
  free -m 2>/dev/null | sed 's/^/      /'
  ;;

# ══ --check (기본값) ══════════════════════════════════════════════════
check)
  run_checks
  say
  say "── 🔴 DSM 리버스 프록시 — **사람이 넣는다** (443 → localhost:$HPORT)"
  cat <<'PROXY'
     DSM → 제어판 → 로그인 포털 → 고급 → 리버스 프록시 → 만들기
       설명      RF 이슈관리
       원본      프로토콜 HTTPS · 호스트 이름 issues.dss21.co.kr · 포트 443
       대상      프로토콜 HTTP  · 호스트 이름 localhost          · 포트 13900
       사용자 지정 머리글 → 만들기 → WebSocket   (다른 여덟과 같게)
     🔴 인증서 탭에서 **dss21.co.kr 와일드카드**를 고릅니다.
        기본값이 synology.com 이라 그대로 두면 브라우저가 경고를 띄웁니다.
     🔴 Cloudflare 에 A 레코드 issues 를 하나 더해야 합니다(사람이 합니다).
PROXY
  ;;
esac

# ══ 마무리 ════════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
printf '  ✓ %s · ✗ %s · ? %s   (모드 %s)\n' "$PASS" "$FAIL" "$UNK" "$MODE"
[ "$MODE" = go ] && echo "  띄운 시각 $STOP_AT → 대답한 시각 $UP_AT · 약 ${DOWN}초"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$UNK" != 0 ]; then
  echo "🔴 **못 쟀거나 아직 안 온 것이 $UNK 개 있다.** 통과로 세지 않는다."
fi
if [ "$FAIL" != 0 ]; then
  echo "🔴 **어긋난 것이 $FAIL 개 있다.**"
  echo "🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 2026-10-22 에 검사가"
  echo "   틀린 경우가 일곱 번 있었고 전부 거짓 실패였습니다."
  echo "되돌리기 안내:  bash $0 --rollback"
fi
if [ "$MODE" = go ] && [ "$FAIL" = 0 ] && [ "$UNK" = 0 ]; then
  cat <<ANNOUNCE

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. $BASE — 포털을 거쳐 로그인이 됩니까
      · 🔴 **명단에 넣은 사람으로** 들어가야 합니다(requires_grant 가 참).
        🔵 재고 관리와 달리 **역할은 없어도 됩니다** — 이 시스템은 역할을
           쓰지 않습니다.
      · 🔴 인증서 경고가 뜨면 DSM 프록시에 dss21.co.kr 인증서를 지정하지
        않은 것입니다(기본값이 synology.com 입니다).
   2. 머리말에 자기 이름과 시스템 목록 · 알림 종이 보입니까
   3. 🔴 종을 눌러 보세요 — 다른 시스템의 알림이 보이고, 이 집 것은
      **빈 목록**인 것이 맞습니다(제 알림이 아직 없습니다).
   4. 이 시스템에서 로그아웃 → 포털 세션도 함께 끝납니까
   5. 🔴 포털에서 로그아웃한 뒤 이 탭을 새로고침 → 로그인으로 갑니까
      · 백채널 로그아웃이 도는지를 보는 **유일한 길**입니다.
   6. https://login.dss21.co.kr 의 타일에 RF 이슈관리가 보입니까
   7. 🔵 **자료 파일을 누르면 안 열리는 것이 맞습니다.** 공유폴더를 이번에
      안 붙였습니다(2026-10-22 결정 — 파일 위치는 배포판 이후에 시스템에서
      고르기로 했습니다). 검색에 **이름은 그대로 나오고**(색인은 data/ 에서
      옵니다) 누를 때만 못 찾습니다.
      · 엑셀 **자동 재색인**도 같은 까닭으로 멈춰 있습니다 — 설정·정보
        화면의 「자동 갱신」 칸에 실패가 적힙니다. 고장이 아닙니다.
      · 🔵 이슈 등록 · 검색 · 주간보고 · 출장일정 · 첨부는 **전부 됩니다.**
        그쪽이 안 되면 그것은 진짜 고장입니다.
   8. 🔴 **포털 · A/S · 계측기 · 개선요청 · PO · 휴가 · 게시판 · 재고 관리가
      그대로입니까** — 이 설치는 그 여덟을 건드리지 않았습니다.

🔴 사람이 이어서 할 일:
  · 내일 아침 백업을 한 번 더 보세요 — 스케줄러가 **실제로 돌려서**
    files/rf-trouble-data 가 생기는지가 진짜 확인입니다:
      ls -l /volume1/dss/backups/files/
    🔴 이 시스템은 DB 가 없어 **그 폴더 하나가 백업의 전부**입니다.
  · 위 메모리 값을 Claude 에게 알려 주세요 — compose 의 예산표를 다시 적습니다.
  · 🔴 쓸 사람을 포털 명단에 넣으세요. 이 시스템에는 **비상구가 없습니다** —
    팀 공용 비밀번호 길이 2026-10-21 에 코드에서 걷혔습니다.

되돌리기 안내:  bash $0 --rollback
ANNOUNCE
fi
if [ "$UNK" != 0 ] || [ "$FAIL" != 0 ]; then exit 1; fi
exit 0
