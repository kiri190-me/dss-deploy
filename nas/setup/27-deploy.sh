#!/bin/bash
# /volume1/dss/setup/27-deploy.sh — 2026-10-13 재고 관리 **첫 설치**
#
# ── 이것은 「갈아 끼우기」가 아니라 「없던 것을 세우는 일」이다 ─────────
#   본은 25-deploy.sh(게시판 첫 설치)다. 검사가 보는 것이 「도는 것이
#   흔들리지 않았나」가 아니라 **「띄울 자리가 다 됐나」**다.
#
#   재고 관리 : dss-inventory:0.1 · dss-inventory-tools:1
#               DB dss_inventory · 롤 dss_inventory_app
#               컨테이너 안 3800 → 127.0.0.1:13800 → https://inventory.dss21.co.kr
#               데이터 /volume1/dss/inventory-data → 컨테이너 /data
#               🔴 다만 그중 workbook 만은 **사내 공유폴더가 덧씌운다** (2026-10-14):
#                  /volume1/2_AS센터/2. 부품 관리/1. 재고 및 부품 입출고 관리/4. 재고관리 시스템
#                  → 컨테이너 /data/workbook. /volume1/dss 에는 시놀로지 ACL 이 걸려
#                  직원이 탐색기로 못 열기 때문이다. 그래서 야간 백업도 그 자리를
#                  **따로** 받는다 — 백업 이름 files/inventory-workbook (검사 9 가 센다).
#
# ══ 🔴 오늘 하는 것은 **그릇까지**다 ═══════════════════════════════════
#
#   이 스크립트는 **표를 만들고 앱을 띄우는 데까지**만 한다.
#   🔴 실자료(엑셀의 과거 기록 수천 줄)를 넣지 **않는다.** 항목 19종
#      (seed-items)도 넣지 않는다. 그 둘은 **전환일 작업**이고 전용 절차서가
#      따로 있다 — dss-inventory/docs/전환일_절차서_2026-10-12.md.
#      · 실자료 가져오기는 **한 번만** 돌릴 수 있고(빈 DB 가 아니면 스스로
#        거절한다), 되돌리려면 DB 를 비워야 한다.
#      · 사람이 숫자를 대조하며 하는 별도의 날 작업이다.
#   🔴 전환 절차서는 전제 1번으로 「야간 백업에 운영 DB 와 데이터 폴더가 들어
#      있다. **없으면 실자료를 넣지 않는다**」를 못 박고 있다. 그래서 이
#      스크립트의 검사 9 가 그 둘을 센다.
#
# ── 🔴 첫 설치 순서. 이 차례로 부른다 ──────────────────────────────────
#
#   1) bash 27-deploy.sh                읽기만. 어긋난 곳을 먼저 고친다
#   2) bash 27-deploy.sh --preload      이미지 둘을 싣는다 (아무것도 안 멈춤)
#   3) bash 27-deploy.sh                다시 읽기만 — 이번엔 지문까지 다 본다
#   4) bash 27-deploy.sh --init         🔴 표 열셋을 만든다 (DB 가 바뀐다)
#   5) bash 27-deploy.sh --go           앱을 띄운다
#   6) 눈으로 확인 (아래 --go 끝의 안내)
#
#   🔴 4 와 5 는 **합치지 않았다.** 표가 없는 DB 에 앱이 먼저 뜨면 첫 화면이
#      42P01 (relation does not exist) 로 죽는다. 그래서 **순서를 강제한다** —
#      5(--go)는 시작하기 전에 「마이그레이션 아홉 줄 · 표 열셋」을 DB 에서
#      다시 세고, 아니면 **앱을 띄우지 않고 멈춘다.**
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/27-deploy.sh          ← 읽기만 한다
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#   · MODE=check       (모드 절의 첫 줄)
#   · FORCE_LOAD=0     (같은 태그를 덮어쓰지 않는다)
#   DB 를 바꾸는 곳은 --init 한 군데뿐이고, 컨테이너를 띄우는 곳은 --go
#   한 군데뿐이다. --check 는 그 둘을 **부르지 않는다.**
#
#   🔴 두 가지는 정직하게 적어 둔다 — --check 도
#      ① 이미지 **안을 보려고** 컨테이너를 잠깐 띄웠다 지운다
#      ② 데이터 폴더에 **쓸 수 있는지** 보려고 파일·폴더를 만들었다 지운다
#      「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#
# ── 모드 여섯 ───────────────────────────────────────────────────────────
#   (없음) · --check   읽기만. 아무것도 안 바꾸고 안 멈춘다        ← 기본값
#   --preload          이미지 둘을 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load       🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --init             🔴 마이그레이션 — 표 열셋을 만든다. DB 가 바뀐다
#   --go               app-inventory 를 띄운다 (다른 일곱은 안 멈춘다)
#   --rollback         내리는 명령과 compose 되돌리는 명령을 찍는다
#
# ── 🔴 이미 끝나 있어야 하는 것 (이 스크립트는 **검사만** 한다) ────────
#   · 이미지 둘을 /volume1/dss/images/ 에 올렸다
#   · DB dss_inventory · 롤 dss_inventory_app 과 비밀번호 (27-inventory-db.sh
#     · 27-inventory-pw.sh)
#   · .env.nas 에 INVENTORY_APP_PASSWORD 한 줄
#   · 포털 clients 에 dss-inventory 등록 (27-inventory-client.sh ·
#     🔴 requires_grant=true) **그리고 사람·역할 명단**
#   · Cloudflare A 레코드 inventory · DSM 리버스 프록시 · 인증서(dss21.co.kr)
#   · inventory.env · compose · 야간 백업을 NAS 로 올려 제자리에 놓고,
#     데이터 폴더를 만들어 uid 1001 로 권한을 맞췄다 (27-inventory-place.sh)
#   · 27-inventory-check.sh 가 전부 ✓
#
# ══ 🔴 이 스크립트가 **왜 이렇게 의심이 많은가** ═══════════════════════
#
#   이 저장소가 같은 함정에 여러 번 걸렸다. 다섯 다 **오류가 안 났다.**
#
#   ① 「만든 것」과 「도는 것」은 다르다
#      개선요청 DB 가 11일간 한 번도 백업되지 않았다. 백업 스크립트의 저장소
#      사본에는 그 줄이 있었는데 **NAS 에 올리지 않았다.**
#      → 검사 9 가 「오늘 백업이 **일곱**인가」와 「데이터 폴더가 들어갔나」를 본다.
#
#   ② 태그가 같아도 **속이 다를 수 있다**
#      A/S 도구 이미지가 vendor 를 안 담은 채 여드레 돌았다. 휴가 도구 이미지는
#      scripts 가 빠져 있었다. 재고 관리는 2026-10-12 에 tools 스테이지가
#      **src 전체와 tsconfig.json** 을 담도록 고쳐졌다 — 그 전 이미지는 migrate
#      만 돌고 가져오기·자체 점검은 모듈을 못 찾는다.
#      → 검사 2 가 도구 이미지 **안을 센다.**
#
#   ③ 유닉스 소켓으로 한 DB 확인은 **거짓 통과**를 낸다 (소켓은 보통 trust)
#      → 검사 3 은 앱이 붙는 길과 같게 **-h 127.0.0.1**(TCP)로 붙어 본다.
#
#   ④ 폴더는 「있는가」로 보면 안 된다 — 🔴 **이 설치의 핵심이다**
#      컨테이너는 nextjs(uid **1001**)로 도는데 dss 공유폴더에는 시놀로지 ACL 이
#      걸려 있다. 주인이 맞아도 ACL 이 막으면 못 쓴다.
#      🔴 게시판보다 더 중요하다. 게시판은 사람이 사진을 붙일 때 드러나지만
#         재고 관리는 **1분마다** 쓰고, 못 써도 화면에는 아무 오류가 안 뜬다.
#      → 검사 6 이 임시 컨테이너를 -u 1001:1001 로 띄워 **실제로 쓰고 폴더를
#        만든다.** --go 뒤에는 **도는 컨테이너 안에서** 한 번 더 본다.
#
#   ⑤ 사람이 칠 명령은 **한 줄 76자 안쪽** (DSM 의 ash 가 긴 줄을 자른다)
#      → 이 스크립트가 찍는 명령은 전부 cmd() 를 지난다.
#
#   ⑥ bash -n 이 못 잡는 둘 — 이 저장소에서 실제로 두 번 깨졌다
#      · 큰따옴표 안의 백틱은 명령 치환으로 읽힌다.
#        → 이 파일에는 백틱이 한 개도 없다.
#      · 읽기 전용 자리의 리다이렉션은 ash 가 셸을 그 자리에서 끝낸다.
#        → touch 와 mkdir 을 쓴다.
#
# ── 🔴 되돌리기 ────────────────────────────────────────────────────────
#   첫 설치라 「옛 태그로 내린다」가 없다. 되돌리기는 **없던 것으로** 돌린다:
#     · app-inventory 를 멈추고 지운다
#     · compose 를 backups/ 의 사본으로 되돌린다
#     · 🔴 **DB 와 포털 등록은 남긴다.** 해가 없고, 다시 띄울 때 그대로 쓴다.
#     · 🔴 **마이그레이션은 되돌리지 않는다.** 표를 만들기만 했고, 이 DB 는
#       재고 관리 혼자 쓴다.
#     · 🔴 **데이터 폴더는 건드리지 않는다.** 사람이 넣은 **엑셀 양식 두 벌**은
#       프로그램이 다시 만들 수 없는 입력물이다. 지우면 돌아오지 않는다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
ACLT=/usr/syno/bin/synoacltool
STAMP=$(date +%Y%m%d-%H%M%S)
TODAY=$(date +%F)
CF=$D/deploy/docker-compose.nas.yml
INCOMING=$D/setup/incoming/docker-compose.nas.yml
ENV_NAS=$D/deploy/.env.nas
ENVD=$D/deploy/env
IMAGES=$D/images
BKD=$D/backups
JOBS=$D/jobs

# ── 🔴 이번에 새로 서는 것 **둘** ──────────────────────────────────────
TAG_APP=dss-inventory:0.1
TAG_TOOLS=dss-inventory-tools:1

# ── tar 둘 ─────────────────────────────────────────────────────────────
# ✅ 2026-10-14 개발 PC 에서 굽고 docker save 로 떠 실측해 아래를 채웠다(아래 안내는 그 전 이야기).
# 🔴 크기와 md5 가 **비어 있었다.** 이 스크립트를 쓴 세션은 docker build 를
#    돌리지 않았으므로 잴 값이 없었다. 비어 있으면 **대조하지 않고**, 대신
#    받은 값을 찍고 「대조하지 않았다」고 크게 말한다.
#    🔵 그래도 **지문 확인은 그대로 산다** — tar_config_id() 가 tar 안의
#       manifest.json 에서 읽어 내 NAS 의 image ID 와 맞춘다. 그쪽이 더 강한
#       검사다(전송이 온전한지가 아니라 **같은 이미지인지**를 본다).
#    🔴 이미지를 구운 사람은 아래 두 줄을 채워 다시 올려 주세요:
#         SZ_APP=<바이트>   MD5_APP=<md5>
#         SZ_TOOLS=<바이트> MD5_TOOLS=<md5>
#    ⚠️ tar 가 이미지의 1/4 쯤인 것은 정상이다. 「빌드가 잘못됐나」로 의심할
#       일이 아니다(2026-10-12 기억).
#    🔴 docker save 를 다시 돌리면 이 값이 달라질 수 있다 — 이미 뽑아 둔
#       파일을 그대로 올리세요.
TAR_APP=$IMAGES/dss-inventory-0.1.tar
SZ_APP=95283712;     MD5_APP=385fa27a2e4a7bc83007d37f4c6c1ad0
TAR_TOOLS=$IMAGES/dss-inventory-tools-1.tar
SZ_TOOLS=212687872;   MD5_TOOLS=0b1c7604feac0d423f5e4b53f392ea30

# ── 🔴 **건드리지 않는 열둘.** ─────────────────────────────────────────
# 전부 지금 운영에서 돌고 있다. compose 에서 이 태그가 흔들렸으면 남의 것이
# 섞인 것이다(두 세션이 같은 저장소를 쓴다). 고치지 말고 알린다.
# 🔴 이 목록은 **2026-10-14 26번 배포 직후** 기준이다(2026-10-14 갱신).
#    그날 아침 26번으로 포털 dss-auth 1.6 → **1.7**, 게시판 dss-board
#    0.1 → **0.2** 가 올라갔고 둘 다 지금 운영에서 돌고 있다. 나머지 열은
#    2026-10-13 게시판 설치 때 그대로다.
#    그 뒤에 또 다른 배포가 들어갔다면 목록이 모자랄 수 있다 — 고치지 말고
#    먼저 알리세요.
KEEP_AUTH=dss-auth:1.7
KEEP_AS=dss-as:2.5
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_METERSTOOLS=dss-meters-tools:1
KEEP_IMP=dss-improvements:0.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_PO=dss-po:0.5
KEEP_LEAVE=dss-leave:0.2
KEEP_LEAVETOOLS=dss-leave-tools:2
KEEP_BOARD=dss-board:0.2
KEEP_BOARDTOOLS=dss-board-tools:1

# ── 재고 관리의 값들 ───────────────────────────────────────────────────
INV_DB=dss_inventory
INV_ROLE=dss_inventory_app
INV_ENV=$ENVD/inventory.env
INV_SVC=app-inventory
INV_TOOLS_SVC=tools-inventory
INV_CNAME=dss-inventory
INV_PORT=13800
INV_INNER=3800
INV_HOST=inventory.dss21.co.kr
INV_BASE=https://inventory.dss21.co.kr
INV_DATA=$D/inventory-data
INV_MNT=/data
# 🔴 그중 workbook 한 칸만은 **사내 공유폴더가 덧씌운다** (2026-10-14).
#    /volume1/dss 에는 시놀로지 ACL 이 걸려 직원이 탐색기로 못 열기 때문이다.
#    27-inventory-place.sh 의 SHARE_WB 와 **같은 값**이어야 한다.
INV_SHARE_WB="/volume1/2_AS센터/2. 부품 관리/1. 재고 및 부품 입출고 관리/4. 재고관리 시스템"
UID_APP=1001
GID_APP=1001
CLIENT_ID=dss-inventory
# 🔴 게시판(/api/auth/callback)과 **다르다** — sso 가 한 칸 더 있다.
CB_PATH=/api/auth/sso/callback
BC_PATH=/api/auth/sso/backchannel-logout
START_PATH=/api/auth/sso/start

# 🔴 실측이다 (dss-inventory/drizzle/meta/_journal.json · 2026-10-13).
MIG_TAGS="0000_serious_amazoness 0001_lazy_ezekiel 0002_workable_quasar"
MIG_TAGS="$MIG_TAGS 0003_stock_ledger_comments 0004_harsh_outlaw_kid 0005_slippery_loa"
MIG_TAGS="$MIG_TAGS 0006_tan_fabian_cortez 0007_milky_talisman 0008_crazy_firelord"
N_MIG_WANT=9
N_TABLE_WANT=13
# 🔴 표 이름도 실측이다 (dss-inventory/drizzle/*.sql 의 CREATE TABLE 열셋).
INV_TABLES="app_settings audit_logs legacy_records part_favorites part_items parts"
INV_TABLES="$INV_TABLES stock_balances stock_entries stock_requests stock_transactions"
INV_TABLES="$INV_TABLES users workbook_apply_logs workbook_states"

# inventory.env 에 **있어야 하는** 여덟 (dss-inventory/.env.example · src/lib/env.ts)
ENV_KEYS="SSO_ISSUER SSO_CLIENT_ID SSO_CLIENT_SECRET SSO_REDIRECT_URI"
ENV_KEYS="$ENV_KEYS AUTH_SESSION_SECRET SSO_TX_SECRET SESSION_COOKIE_SECURE SESSION_HOURS"
# inventory.env 에 **있으면 안 되는** 열. 앞 일곱은 compose 와 이미지가 넘긴다 —
# 같은 값이 두 곳에 있으면 언젠가 한쪽만 바뀌는데, 그때 앱은 **오류 없이**
# 다른 DB 를 보거나 엉뚱한 자리에 엑셀을 쓴다.
# 🔴 뒤 셋은 성격이 다르다:
#    DEV_ROLE_OVERRIDE      개발용 「역할 낮춰 보기」 울타리
#    WORKBOOK_SYNC_DISABLED 🔴 **엑셀 자동 갱신을 통째로 끈다.** 남아 있으면
#                           현황판이 영영 안 만들어지는데 화면은 멀쩡하다
#    DEV_POSTGRES_PASSWORD  개발 DB 컨테이너용
ENV_FORBIDDEN="DATABASE_URL PORT TZ INVENTORY_DATA_DIR STOCK_WORKBOOK_PATH"
ENV_FORBIDDEN="$ENV_FORBIDDEN STOCK_WORKBOOK_TEMPLATE_PATH STOCK_DOWNLOAD_TEMPLATE_PATH"
ENV_FORBIDDEN="$ENV_FORBIDDEN DEV_ROLE_OVERRIDE WORKBOOK_SYNC_DISABLED DEV_POSTGRES_PASSWORD"

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 둘. 인자가 없으면 이 둘 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 27-deploy.sh                 읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 27-deploy.sh --check         위와 같습니다
  bash 27-deploy.sh --preload       이미지 둘을 싣고 지문을 맞춥니다
  bash 27-deploy.sh --force-load    🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 27-deploy.sh --init          🔴 표 열셋을 만듭니다 (DB 가 바뀜)
  bash 27-deploy.sh --go            app-inventory 를 띄웁니다
  bash 27-deploy.sh --rollback      되돌리기 안내 (아무것도 안 바꿉니다)

  🔴 첫 설치 차례:  (없음) → --preload → (없음) → --init → --go
  🔴 --init 과 --go 는 **따로** 부릅니다. 표가 없는 DB 에 앱이 먼저 뜨면
     첫 화면이 42P01 로 죽습니다.
  🔴 --go 가 띄우는 것은 app-inventory 하나입니다. 포털 · A/S · 계측기 ·
     개선요청 · PO · 휴가 · 게시판 · DB 는 그대로 돕니다.
  🔴 **실자료(import-workbook --real)와 항목 19종(seed-items)은 여기에
     없습니다.** 전환일 작업이고 전용 절차서가 따로 있습니다.
USAGE
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)      MODE=check ;;
    --preload)    MODE=preload ;;
    --force-load) FORCE_LOAD=1; [ "$MODE" = check ] && MODE=force-load ;;
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
LOG="$D/setup/logs/27-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 25-deploy.sh 의 것을 그대로 쓴다 ──────────────────────────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# ── ⑤ 사람이 칠 명령은 76자 안쪽으로만 찍는다 ──────────────────────────
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

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미
#
#  🔴 이 스크립트가 DB 를 바꾸는 곳은 **--init 한 군데뿐**이다. 아래 것들은
#     전부 SELECT 다.
#  🔴 아래 넷은 컨테이너 안에서 **유닉스 소켓**으로 붙는다(superuser). 읽기에는
#     그것으로 충분하지만, **비밀번호가 맞는지는 이것으로 알 수 없다** —
#     소켓은 보통 trust 라 거짓 통과를 낸다. 그 확인은 tcp_db_check() 가
#     -h 127.0.0.1 로 따로 한다(머리말 ③).
# ══════════════════════════════════════════════════════════════════════
qpg() { "$DOCKER" exec dss-pg-app  sh -c "psql -U \"\$POSTGRES_USER\" -d postgres -Atc \"$1\"" 2>/dev/null; }
qi()  { "$DOCKER" exec dss-pg-app  sh -c "psql -U \"\$POSTGRES_USER\" -d $INV_DB  -Atc \"$1\"" 2>/dev/null; }
qa()  { "$DOCKER" exec dss-pg-auth sh -c "psql -U \"\$POSTGRES_USER\" -d dss_auth -Atc \"$1\"" 2>/dev/null; }

pg_up() { "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-app; }
running() { "$DOCKER" ps --format '{{.Names}}' | grep -qx "$1"; }

# ── 설정 파일에서 값 하나를 꺼낸다 ─────────────────────────────────────
# 🔴 부르는 쪽은 이 값을 **절대 화면에 찍지 않는다.** 판정에만 쓴다.
# 🔴 같은 이름이 두 줄 있으면 **나중 것**을 읽는다(head 가 아니라 tail).
#    docker compose 가 그렇게 읽기 때문이다. 앞 줄을 읽고 판정하면 「내가 본 값」과
#    「앱이 받는 값」이 달라진다 — 이 스크립트가 가장 피하려는 거짓 통과다.
env_val() { # 1 파일 2 키
  local v
  [ -r "$1" ] || { printf ''; return 1; }
  v=$(sed -n "s/^[[:space:]]*\(export[[:space:]][[:space:]]*\)\?$2=//p" "$1" 2>/dev/null | tail -1 | tr -d '\r')
  v=${v#\"}; v=${v%\"}
  v=${v#\'}; v=${v%\'}
  printf '%s' "$v"
}
env_has() { grep -qE "^[[:space:]]*(export[[:space:]]+)?$2=" "$1" 2>/dev/null; }
env_dups() {
  # 🔴 「|| echo 0」을 붙이지 않는다. grep -c 는 0건일 때도 0 을 찍고 종료코드만
  #    1 이라, 붙이면 값이 두 줄("0" 다음에 또 "0")이 되어 비교가 전부 어긋난다.
  grep -cE "^[[:space:]]*(export[[:space:]]+)?$2=" "$1" 2>/dev/null
}

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 개발 PC 의 docker image inspect 가 아니라 **이 값**이 NAS 에 실렸을 때의
#    image ID 가 된다.
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

verify_img() { # 1 태그 2 기대지문
  local got
  got=$(img_id "$1")
  if [ "$got" != "$2" ]; then
    bad "$1 지문이 tar 와 다르다 (NAS ${got:-없음} / tar $2)"
    return 1
  fi
  ok "$1 지문 맞음 ($(echo "$2" | cut -c1-19)…)"
}

# ── 같은 태그를 덮어쓰는 길 ────────────────────────────────────────────
# 태그를 그대로 두고 다시 구운 이미지는 have_img 갈래에서 영영 안 실린다.
force_load_hint() {
  say "    🔴 같은 태그로 **다시 구운** 이미지일 수 있다. 덮어쓰려면:"
  cmd "bash $0 --preload --force-load"
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
  verify_img "$1" "$3" || { force_load_hint; return 1; }
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
# 🔴 파일 전체를 grep 하면 안 된다 — 주석 줄이 그대로 걸려서 꺼져 있는
#    서비스를 「가리킨다」고 세게 된다.
#    🔴 이번 설치에서는 특히 중요하다. app-inventory 와 tools-inventory 는
#       **주석으로 들어가 있다가** 27-inventory-place.sh 가 벗긴다. 안 벗긴
#       판에서도 파일 전체 grep 은 전부 ✓ 를 낸다.
svc_block() { # 1 compose파일 2 서비스이름
  awk -v s="  $2:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$1" | sed '/^[[:space:]]*#/d'
}
svc_image() { svc_block "$1" "$2" | sed -n 's/^[[:space:]]*image:[[:space:]]*//p' | head -1; }
# 🔴 값에 한글과 공백이 들어 있어 grep 패턴에 직접 적지 않는다 — 꺼내서 본다.
svc_env() { # 1 compose파일 2 서비스 3 키
  local v
  v=$(svc_block "$1" "$2" | sed -n "s/^[[:space:]]*$3:[[:space:]]*//p" | head -1)
  v=${v#\"}; v=${v%\"}
  v=${v#\'}; v=${v%\'}
  printf '%s' "$v"
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 검사 3 의 핵심 — DB 에 **TCP 로** 붙어 본다
#
#  docker exec dss-pg-app psql -U dss_inventory_app … 은 **유닉스 소켓**으로
#  붙는데, 소켓은 pg_hba 에서 보통 trust 다 — **비밀번호가 틀려도, 아예 없어도
#  통과한다.** 앱은 compose 가 넘긴 DATABASE_URL 로 dss-pg-app:5432(TCP)에
#  붙으므로, 확인도 TCP 로 한다.
#
#  🔴 비밀번호는 **표준입력으로만** 흐른다. 화면에는 한 글자도 안 찍는다.
# ══════════════════════════════════════════════════════════════════════
tcp_db_check() {
  local pw out out2 n
  if ! pg_up; then
    bad "dss-pg-app 이 떠 있지 않다 — DB 를 볼 수 없다"
    return 1
  fi
  if [ ! -r "$ENV_NAS" ]; then
    bad "$ENV_NAS 를 읽을 수 없다 — sudo -i 로 돌리고 계십니까"
    return 1
  fi
  if ! env_has "$ENV_NAS" INVENTORY_APP_PASSWORD; then
    bad ".env.nas 에 INVENTORY_APP_PASSWORD 줄이 없다 — 27-inventory-pw.sh 를 돌리세요"
    return 1
  fi
  n=$(env_dups "$ENV_NAS" INVENTORY_APP_PASSWORD)
  if [ "${n:-0}" != 1 ]; then
    bad ".env.nas 에 INVENTORY_APP_PASSWORD 가 ${n}줄이다 — 하나만 남기세요"
    say "      나중 것이 이긴다. 아래 시험은 **나중 것**으로 해 본다."
  fi
  pw=$(env_val "$ENV_NAS" INVENTORY_APP_PASSWORD)
  if [ -z "$pw" ]; then
    bad ".env.nas 의 INVENTORY_APP_PASSWORD 는 줄만 있고 값이 비었다"
    return 1
  fi
  ok ".env.nas 에 INVENTORY_APP_PASSWORD 가 있다 (🔴 값은 안 찍는다)"

  out=$(printf '%s\n' "$pw" | "$DOCKER" exec -i \
        -e R="$INV_ROLE" -e DBN="$INV_DB" dss-pg-app sh -c '
    read -r PW
    PGPASSWORD="$PW" psql -X -tAq -h 127.0.0.1 -U "$R" -d "$DBN" \
      -c "select current_user" 2>&1')
  pw=
  # 🔴 갈래 차례가 중요하다. 실패 문장이 롤 이름을 품고 있어서,
  #    성공 갈래를 먼저 두면 실패가 ✓ 로 둔갑한다.
  case "$out" in
    *"authentication failed"*)
      bad "🔴 TCP 로 붙지 못했다 — .env.nas 의 값과 롤의 비밀번호가 다르다"
      say "      앱이 뜨는 순간 password authentication failed 로 죽는다."
      cmd "sh /volume1/dss/setup/27-inventory-pw.sh"
      return 1 ;;
    *"no password supplied"*)
      bad "🔴 비밀번호가 안 넘어갔다 — .env.nas 의 값이 비어 있는 듯하다"
      return 1 ;;
    *"could not connect"*|*"Connection refused"*|*"could not translate"*)
      bad "🔴 TCP 로 서버에 닿지 못했다 (127.0.0.1:5432)"
      printf '%s\n' "$out" | sed 's/^/      /' | head -4
      return 1 ;;
    "$INV_ROLE")
      ok "🔴 TCP(-h 127.0.0.1)로 $INV_ROLE 이 $INV_DB 에 붙었다 — 진짜 확인" ;;
    *"$INV_ROLE"*)
      ok "TCP 로 붙었다 (출력에 다른 줄이 섞였지만 $INV_ROLE 로 붙었다)" ;;
    *)
      bad "TCP 접속을 판정하지 못했다 — psql 이 말한 것:"
      printf '%s\n' "$out" | sed 's/^/      /' | head -4
      return 1 ;;
  esac

  # 곁들여 — 그 통과가 **진짜 인증을 지난 것인지**까지 본다.
  out2=$("$DOCKER" exec -e R="$INV_ROLE" -e DBN="$INV_DB" dss-pg-app sh -c '
    PGPASSWORD="" psql -X -tAq -h 127.0.0.1 -U "$R" -d "$DBN" -c "select 1" 2>&1')
  case "$out2" in
    *"authentication failed"*|*"no password supplied"*)
      ok "빈 비밀번호로는 거절당한다 — TCP 인증이 실제로 걸려 있다" ;;
    1)
      say "  ⚠️ 빈 비밀번호로도 붙는다 — host 규칙이 trust 다. 위 ✓ 는 증거가"
      say "     약하다. 지금 설치에는 지장이 없지만 알아 두세요." ;;
    *)
      say "  · 빈 비밀번호 시험은 판정하지 않는다" ;;
  esac
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 검사 6 — 데이터 폴더에 **uid 1001 이 실제로 쓰는가**
#
#  이 설치에서 가장 조용한 결함이 여기 있다. 폴더가 있고 주인이 맞아도
#  시놀로지 ACL 이 남아 있으면 컨테이너가 못 쓴다. 그런데 앱은 **1분마다**
#  여기에 쓰고, 못 써도 화면에는 아무 오류가 안 뜬다 — 로그에만 남는다.
#
#  🔴 리다이렉션으로 시험하지 않는다. 쓰기가 막히면 ash 가 셸을 그 자리에서
#     끝내 뒤 줄이 아예 안 돌고 판정이 **빈 채로** 지나간다(2026-10-12 실측).
#     touch 와 mkdir 은 외부 명령이라 실패해도 셸이 산다.
# ══════════════════════════════════════════════════════════════════════
probe_image() {
  local t
  for t in "$TAG_APP" "$KEEP_BOARD" "$KEEP_LEAVE" "$KEEP_IMP" "$KEEP_AS" "$KEEP_AUTH"; do
    if have_img "$t"; then printf '%s' "$t"; return 0; fi
  done
  printf ''
  return 1
}

data_check() {
  local mode acln img out left others sub ntpl
  if [ ! -d "$INV_DATA" ]; then
    bad "$INV_DATA 가 없다 — 27-inventory-place.sh 를 돌리세요"
    cmd "sh /volume1/dss/setup/27-inventory-place.sh"
    return 1
  fi
  # 🔴 판정은 **숫자**(%u:%g)로 한다. DSM 에 그 번호짜리 계정이 있으면 %U 가
  #    그 이름으로 보여 「1001 이 아니다」로 잘못 읽는다.
  mode=$(stat -c '%u:%g %a' "$INV_DATA" 2>/dev/null)
  say "  · $INV_DATA · $mode (숫자) · $(stat -c '%U:%G' "$INV_DATA" 2>/dev/null) (이름)"
  case "$mode" in
    *" 750") ok "모드 750" ;;
    *) bad "모드가 750 이 아니다 ($mode)" ;;
  esac
  case "$mode" in
    "$UID_APP:$GID_APP "*) ok "주인이 uid $UID_APP (nextjs)이다" ;;
    *) bad "주인이 uid $UID_APP 이 아니다 ($mode) — 컨테이너가 못 쓴다" ;;
  esac
  others=$(find "$INV_DATA" ! -uid "$UID_APP" 2>/dev/null | wc -l)
  if [ "${others:-1}" = 0 ]; then
    ok "폴더 아래 전부가 uid $UID_APP 것이다"
  else
    bad "주인이 다른 것이 ${others}개 있다 — 그 파일에서만 조용히 막힌다"
    say "      🔴 도구 컨테이너는 root 로 돈다. /data 에 쓰는 명령을 돌렸다면"
    say "         그 뒤에 주인을 되돌려야 한다:"
    cmd "chown -R $UID_APP:$GID_APP $INV_DATA"
    find "$INV_DATA" ! -uid "$UID_APP" 2>/dev/null | head -5 | sed 's/^/      /'
  fi
  acln=$("$ACLT" -get "$INV_DATA" 2>&1 | grep -cE ':(allow|deny):')
  [ "${acln:-1}" = 0 ] && ok "ACL 항목 0개 (걷혔다)" \
    || bad "ACL 항목이 ${acln}개 남아 있다 — 주인이 맞아도 못 쓴다"
  for sub in templates import workbook; do
    [ -d "$INV_DATA/$sub" ] && ok "$sub/ 가 있다" || bad "$sub/ 가 없다"
  done
  # 🔵 양식 두 벌은 전환일에 사람이 넣는다. 지금 없는 것이 **정상**이다.
  ntpl=$(find "$INV_DATA/templates" -maxdepth 1 -name '*.xlsx' 2>/dev/null | wc -l)
  if [ "${ntpl:-0}" -ge 2 ]; then
    ok "templates/ 에 xlsx 가 ${ntpl}개 있다"
  else
    say "  ⚠️ templates/ 에 xlsx 가 ${ntpl:-0}개다 — 설치하는 날에는 **정상**이다."
    say "     🔴 전환일 전에 양식 두 벌을 넣어야 현황판 엑셀이 만들어진다."
    say "     이름이 compose 의 STOCK_*_PATH 와 **글자 하나까지** 같아야 한다."
  fi

  img=$(probe_image)
  if [ -z "$img" ]; then
    bad "쓰기 시험에 쓸 이미지를 하나도 찾지 못했다 — **시험을 못 했다**"
    return 1
  fi
  say "  · 쓰기 시험에 쓴 이미지: $img"
  out=$("$DOCKER" run --rm --network none -u "$UID_APP:$GID_APP" \
        -v "$INV_DATA:$INV_MNT" --entrypoint sh "$img" -c '
          id
          if touch /data/.dss-write-test 2>/dev/null; then
            echo "PROBE WRITE_OK"
            rm -f /data/.dss-write-test 2>/dev/null
          else
            echo "PROBE WRITE_FAIL"
          fi
          if mkdir -p /data/.dss-mkdir-test 2>/dev/null; then
            echo "PROBE MKDIR_OK"
            rmdir /data/.dss-mkdir-test 2>/dev/null
          else
            echo "PROBE MKDIR_FAIL"
          fi' 2>&1)
  printf '%s\n' "$out" | grep -E '^(uid=|PROBE )' | sed 's/^/      /'
  case "$out" in
    *"PROBE WRITE_OK"*)
      ok "🔴 uid $UID_APP 이 $INV_DATA 에 **실제로 썼다** (바로 지웠다)" ;;
    *"PROBE WRITE_FAIL"*)
      bad "🔴 uid $UID_APP 이 못 쓴다 — 앱이 첫 1분부터 조용히 멈춘다"
      cmd "sh /volume1/dss/setup/27-inventory-place.sh" ;;
    *)
      bad "쓰기 시험을 판정하지 못했다 — 아래가 그대로의 출력이다"
      printf '%s\n' "$out" | sed 's/^/      /' | head -8 ;;
  esac
  case "$out" in
    *"PROBE MKDIR_OK"*)   ok "🔴 폴더도 만들 수 있다 (baseline · backup · OLD 가 이렇게 생긴다)" ;;
    *"PROBE MKDIR_FAIL"*) bad "🔴 폴더를 못 만든다 — 백업 폴더가 영영 안 생긴다" ;;
  esac
  left=$(find "$INV_DATA" -maxdepth 1 -name '.dss-*-test' 2>/dev/null | wc -l)
  [ "${left:-0}" = 0 ] && ok "시험 흔적이 남지 않았다" \
    || bad "시험 흔적이 남아 있다 — rm -rf $INV_DATA/.dss-write-test $INV_DATA/.dss-mkdir-test"
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 주소 넷이 글자 단위로 같은가 — 가장 자주 나는 고장
#
#  증상은 「로그인이 안 된다」 하나로 뭉뚱그려진다. 포털은 redirect_uri 를
#  **글자 단위로** 대조한다 — 와일드카드도 정규화도 없다.
#
#  🔴 이 시스템은 SSO_REDIRECT_URI 에서 **자기 주소도 뽑는다**
#     (dss-inventory/src/lib/env.ts 의 ownBaseUrlFrom). 그래서 이 값 하나가
#     틀리면 로그인뿐 아니라 다른 시스템 종에 실리는 알림 링크까지 어긋난다.
#     컨테이너 안에서 자기 주소를 auto 로 알아내면 172.x 가 나온다 — 그래서도
#     이 값이다.
# ══════════════════════════════════════════════════════════════════════
# 값을 그대로 찍지 않는다 — 숫자를 N 으로 가린 앞머리만 남긴다.
href_shape() { printf '%s' "$1" | cut -c1-56 | sed 's/[0-9]/N/g'; }

judge_redirect_uri() { # 1 라벨 2 원본값
  local label="$1" raw="$2" host base
  case "$raw" in
    auto|auto:*|AUTO|"")
      bad "$label · SSO_REDIRECT_URI 가 auto(또는 빈 값)다 — 운영에는 도메인을 적는다"
      say "      auto 는 이 기계의 랜 주소를 집는다. **컨테이너 안에서는 172.x 다.**"
      return 1 ;;
  esac
  case "$raw" in
    *"$CB_PATH") base=${raw%"$CB_PATH"} ;;
    *)
      bad "$label · SSO_REDIRECT_URI 가 $CB_PATH 로 끝나지 않는다"
      say "      꼴: $(href_shape "$raw")"
      say "      🔴 이 값이 $CB_PATH 로 끝나지 않으면 앱이 **시작할 때 던진다**"
      say "         (env.ts 의 ownBaseUrlFrom 이 거기서 자기 주소를 뽑는다)."
      return 1 ;;
  esac
  host=${base#*://}; host=${host%%/*}; host=${host%%:*}
  case "$host" in
    172.*|10.*|192.168.*)
      bad "$label · **밖에서 닿지 않는 사설 주소**다 — $(href_shape "$base") 꼴"
      return 1 ;;
  esac
  if [ "$raw" = "$INV_BASE$CB_PATH" ]; then
    ok "$label · SSO_REDIRECT_URI 가 $INV_BASE$CB_PATH 다"
    return 0
  fi
  bad "$label · SSO_REDIRECT_URI 가 기대값과 다르다 — $(href_shape "$raw") 꼴"
  say "      기대: $INV_BASE$CB_PATH"
  return 1
}

judge_issuer() { # 1 라벨 2 원본값
  local label="$1" raw="$2"
  case "$raw" in
    auto|auto:*|AUTO|"")
      bad "$label · SSO_ISSUER 가 auto(또는 빈 값)다 — 운영에는 도메인을 적는다"
      return 1 ;;
    https://login.dss21.co.kr)
      ok "$label · SSO_ISSUER 가 https://login.dss21.co.kr 다"
      return 0 ;;
    https://login.dss21.co.kr/*|https://login.dss21.co.kr/)
      bad "$label · SSO_ISSUER 끝에 슬래시나 경로가 붙었다 — 글자 단위로 대조한다"
      say "      (앱이 한 번 벗겨 주지만, 포털 등록값과 맞추려면 안 붙이는 것이 맞다.)"
      return 1 ;;
    *)
      bad "$label · SSO_ISSUER 가 https://login.dss21.co.kr 가 아니다 — $(href_shape "$raw") 꼴"
      return 1 ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════
#  【검사 2】 도구 이미지 **안**을 센다
#
#  🔴 태그도 지문도 「무엇이 든 판인지」를 말해 주지 않는다. Dockerfile 의
#     tools 스테이지는 COPY . . 가 아니라 **폴더를 골라 담는다** — 휴가에서
#     scripts 가 빠진 채로 구워졌던 자리다. **안을 세야 보인다.**
#
#  🔴 재고 관리에는 특별한 것이 하나 더 있다. 2026-10-12 에 tools 스테이지가
#     **src 전체와 tsconfig.json** 을 담도록 고쳐졌다. 그 전 판은 migrate 만
#     돌고 가져오기(import-workbook)와 자체 점검(workbook-selftest)은
#     "@/..." 를 못 풀어 모듈을 못 찾는다. tsconfig.json 이 **없으면**
#     전환일에 가서야 드러난다.
# ══════════════════════════════════════════════════════════════════════
tools_image_check() {
  local out_sql n_sql out_j n_j out t
  if ! have_img "$TAG_TOOLS"; then
    bad "$TAG_TOOLS 가 NAS 에 없다 — 안을 셀 수 없다"
    cmd "bash $0 --preload"
    return 1
  fi
  say "  구운 때: $("$DOCKER" images "$TAG_TOOLS" --format '{{.CreatedAt}}' 2>/dev/null)"

  out_sql=$("$DOCKER" run --rm --entrypoint sh "$TAG_TOOLS" \
            -c 'ls -1 /app/drizzle/*.sql 2>/dev/null' 2>&1)
  n_sql=$(printf '%s\n' "$out_sql" | grep -c '\.sql$')
  printf '%s\n' "$out_sql" | sed 's/^/      /' | head -12
  if [ "$n_sql" = "$N_MIG_WANT" ]; then
    ok "마이그레이션 .sql 이 ${n_sql}개다"
  else
    bad "마이그레이션 .sql 이 ${N_MIG_WANT}개가 아니다 (${n_sql}개)"
    say "    → 늘었으면 이 스크립트가 모르는 판이다. 고치지 말고 알리세요."
  fi
  for t in $MIG_TAGS; do
    printf '%s\n' "$out_sql" | grep -q "/$t\.sql$" \
      && ok "$t.sql 있다" || bad "$t.sql 이 없다 — 다른 판이다"
  done

  out_j=$("$DOCKER" run --rm --entrypoint sh "$TAG_TOOLS" \
          -c 'cat /app/drizzle/meta/_journal.json 2>/dev/null' 2>&1)
  n_j=$(printf '%s\n' "$out_j" | grep -c '"tag"')
  [ "$n_j" = "$N_MIG_WANT" ] && ok "_journal.json 의 tag 가 ${n_j}줄이다" \
    || bad "_journal.json 의 tag 가 ${N_MIG_WANT}줄이 아니다 (${n_j}줄)"
  for t in $MIG_TAGS; do
    printf '%s\n' "$out_j" | grep -q "$t" \
      && ok "_journal 에 $t 가 있다" || bad "_journal 에 $t 가 없다"
  done

  # 🔴 한 번의 docker run 으로 아홉을 본다.
  out=$("$DOCKER" run --rm --entrypoint sh "$TAG_TOOLS" -c '
    [ -f /app/scripts/migrate.ts ]                 && echo "MIGRATE 1"  || echo "MIGRATE 0"
    [ -f /app/scripts/import-workbook.ts ]         && echo "IMPORT 1"   || echo "IMPORT 0"
    [ -f /app/scripts/build-workbook-template.ts ] && echo "BUILDTPL 1" || echo "BUILDTPL 0"
    [ -f /app/scripts/workbook-selftest.ts ]       && echo "SELFTEST 1" || echo "SELFTEST 0"
    [ -f /app/scripts/seed-items.ts ]              && echo "SEEDITEMS 1" || echo "SEEDITEMS 0"
    [ -f /app/tsconfig.json ]                      && echo "TSCONFIG 1" || echo "TSCONFIG 0"
    [ -f /app/drizzle.config.ts ]                  && echo "DRIZZLECFG 1" || echo "DRIZZLECFG 0"
    [ -f /app/src/lib/env.ts ]                     && echo "ENVTS 1"    || echo "ENVTS 0"
    [ -d /app/src/lib/excel ]                      && echo "EXCELDIR 1" || echo "EXCELDIR 0"
    [ -d /app/src/lib/legacy ]                     && echo "LEGACYDIR 1" || echo "LEGACYDIR 0"
    [ -x /app/node_modules/.bin/tsx ]              && echo "TSX 1"      || echo "TSX 0"
    ' 2>&1)
  printf '%s\n' "$out" | grep -E '^[A-Z]+ [01]$' | sed 's/^/      /'
  see_one() { # 1 표시 2 사람이 읽을 것 3 없을 때 할 말
    if printf '%s\n' "$out" | grep -qx "$1 1"; then
      ok "$2"
    else
      bad "$2 — **없다**"
      say "    → $3"
    fi
  }
  see_one MIGRATE    "scripts/migrate.ts 가 있다" \
    "🔴 표를 만들 수 없다. --init 이 「없는 파일」로 끝난다."
  see_one TSX        "node_modules/.bin/tsx 가 있다" \
    "🔴 tsx 가 없으면 scripts 를 하나도 못 돌린다. 운영 이미지를 도구로 구웠나."
  see_one TSCONFIG   "🔴 tsconfig.json 이 있다 (@/… 경로를 푸는 곳)" \
    "🔴 2026-10-12 **이전 판**이다. migrate 는 돌지만 전환일 명령이 모듈을 못 찾는다."
  see_one DRIZZLECFG "drizzle.config.ts 가 있다" \
    "drizzle-kit 이 스키마 자리를 못 찾는다."
  see_one ENVTS      "src/lib/env.ts 가 있다 (DATABASE_URL 을 읽는 곳)" \
    "src 가 빠졌다 — 도구가 돌다 죽는다."
  see_one EXCELDIR   "src/lib/excel 가 있다 (자체 점검이 쓴다)" \
    "🔴 2026-10-12 이전 판이다. workbook-selftest 가 모듈을 못 찾는다."
  see_one LEGACYDIR  "src/lib/legacy 가 있다 (실자료 가져오기가 쓴다)" \
    "🔴 전환일에 import-workbook 이 모듈을 못 찾는다."
  see_one IMPORT     "scripts/import-workbook.ts 가 있다 (전환일용)" \
    "전환일에 실자료를 못 넣는다. 오늘 쓰지는 않는다."
  see_one BUILDTPL   "scripts/build-workbook-template.ts 가 있다 (전환일용)" \
    "전환일 전날 양식을 다시 못 만든다."
  see_one SELFTEST   "scripts/workbook-selftest.ts 가 있다 (전환일용)" \
    "전환일에 첫 엑셀이 제대로 났는지 스스로 못 본다."
  see_one SEEDITEMS  "scripts/seed-items.ts 가 있다 (🔵 전환일용 · 오늘 안 돌린다)" \
    "전환일에 항목 19종을 못 넣는다."
  return 0
}

# ── 표를 센다 — 「돌았다」가 아니라 「섰다」를 본다 ─────────────────────
mig_table()  { qi "select to_regclass('drizzle.__drizzle_migrations')"; }
mig_count()  { qi "select count(*) from drizzle.__drizzle_migrations"; }
tbl_count()  { qi "select count(*) from information_schema.tables where table_schema='public'"; }
tbl_has()    { qi "select count(*) from information_schema.tables where table_schema='public' and table_name='$1'"; }

# 지금 DB 가 어디까지 와 있는지 — 여러 곳에서 부른다.
show_db_state() { # [hint]
  if ! pg_up; then
    say "  · dss-pg-app 이 떠 있지 않아 못 봤다"
    return 0
  fi
  if [ -z "$(mig_table)" ]; then
    say "  · drizzle.__drizzle_migrations 가 아직 없다 → **--init 을 아직 안 돌렸다**"
    say "    🔴 이대로 앱을 띄우면 첫 화면이 42P01 로 죽는다. DB 가 먼저다."
    if [ "${1:-}" = hint ]; then
      say "    다음:"
      cmd "bash $0 --init"
    fi
    return 0
  fi
  say "  · 적용된 마이그레이션: $(mig_count)줄 (기대 $N_MIG_WANT)"
  say "  · public 스키마의 표: $(tbl_count)개 (기대 $N_TABLE_WANT)"
  # 🔵 실자료가 들어갔는지도 보여 준다. 오늘은 **0 이 정상**이다.
  say "  · parts $(qi "select count(*) from parts" 2>/dev/null)줄 ·" \
      "legacy_records $(qi "select count(*) from legacy_records" 2>/dev/null)줄" \
      "(🔵 그릇만 세우는 오늘은 둘 다 0 이 정상 — 실자료는 전환일에 넣는다)"
  return 0
}

CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.**
#  🔴 마이그레이션의 **지금 상태는 ✗ 로 세지 않는다.** --check 는 --init 보다
#     먼저 도는 것이 정상 차례라, 「표가 아직 없다」는 흠이 아니다.
# ══════════════════════════════════════════════════════════════════════
run_checks() {
  local tag s rec f db code t
  local perm own v n miss

  # ── 1-ㄱ. 【검사 1】 이미지 tar 둘 ───────────────────────────────────
  step "1-ㄱ. 【검사 1】 이미지 tar 둘 (크기 · md5 · tar 안의 지문)"
  EXP_APP=$(tar_config_id   "$TAR_APP"   2>/dev/null) || EXP_APP=""
  EXP_TOOLS=$(tar_config_id "$TAR_TOOLS" 2>/dev/null) || EXP_TOOLS=""
  see_tar() { # 1 태그 2 tar 3 지문 4 바이트(빈 값이면 대조 안 함) 5 md5(빈 값이면 대조 안 함)
    local n m
    if [ ! -s "$2" ]; then
      bad "$1 의 tar 가 없다: $2"
      say "    → 개발 PC 에서 올리세요. 🔴 scp 에는 -O 를 붙입니다(DSM 에 sftp 가 없다)."
      return 1
    fi
    n=$(stat -c '%s' "$2" 2>/dev/null)
    m=$(md5sum "$2" 2>/dev/null | awk '{print $1}')
    if [ -z "$4" ] || [ -z "$5" ]; then
      say "  ⚠️ $1 · 바이트 $n · md5 $m"
      say "     🔴 **기대값이 없어 대조하지 않았다.** 이미지를 구운 PC 에서 잰 값과"
      say "     눈으로 맞춰 주세요. 다르면 멈추세요. (아래 지문 확인은 그대로 돕니다.)"
    else
      [ "$n" = "$4" ] && ok "$1 · 바이트 $n" \
        || bad "$1 의 바이트가 $4 가 아니다 ($n) — 올리다 끊겼다"
      [ "$m" = "$5" ] && ok "$1 · md5 $m" \
        || bad "$1 의 md5 가 $5 가 아니다 (${m:-못 읽음}) — 파일이 상했다"
    fi
    [ -n "$3" ] && ok "$1 · 기대 지문 $(echo "$3" | cut -c1-19)…" \
      || bad "$1 의 tar 에서 manifest.json 을 읽지 못했다: $2"
  }
  see_tar "$TAG_APP"   "$TAR_APP"   "$EXP_APP"   "$SZ_APP"   "$MD5_APP"
  see_tar "$TAG_TOOLS" "$TAR_TOOLS" "$EXP_TOOLS" "$SZ_TOOLS" "$MD5_TOOLS"

  # ── 1-ㄴ. NAS 에 실린 이미지 ────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (재고 관리 둘 + 건드리지 않는 열둘)"
  say "  새로 서는 둘 — 지문까지 맞춘다:"
  for rec in "$TAG_APP|$EXP_APP" "$TAG_TOOLS|$EXP_TOOLS"; do
    tag=${rec%%|*}; t=${rec##*|}
    if have_img "$tag"; then
      if [ -n "$t" ] && ! verify_img "$tag" "$t"; then
        force_load_hint
      fi
    else
      say "  · $tag 는 아직 NAS 에 없다 — --preload 가 싣는다"
    fi
  done
  say "  🔴 지문이 어긋나면 **혼자 고쳐지지 않는다.** 태그가 같으면 docker load 를"
  say "     그냥 부르는 것으로는 안 바뀐다 — 위에 찍힌 --force-load 를 쓰세요."
  say "  건드리지 않는 열둘 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for tag in "$KEEP_AUTH" "$KEEP_AS" "$KEEP_ASTOOLS" "$KEEP_METERS" \
             "$KEEP_METERSTOOLS" "$KEEP_IMP" "$KEEP_IMPTOOLS" "$KEEP_PO" \
             "$KEEP_LEAVE" "$KEEP_LEAVETOOLS" "$KEEP_BOARD" "$KEEP_BOARDTOOLS"; do
    have_img "$tag" && ok "$tag 실려 있다 ($(img_id "$tag" | cut -c1-19)…)" \
      || bad "$tag 가 NAS 에 없다 — 🔴 앞선 배포가 되돌아갔거나 누가 지웠다"
  done

  # ── 1-ㄷ. 【검사 2】 도구 이미지 안 ──────────────────────────────────
  step "1-ㄷ. 【검사 2】 $TAG_TOOLS 안 — 마이그레이션 아홉 · tsconfig · src"
  tools_image_check

  # ── 1-ㄹ. 【검사 3】 DB 와 롤 — 🔴 TCP 로 붙어 본다 ──────────────────
  step "1-ㄹ. 【검사 3】 DB $INV_DB · 롤 $INV_ROLE (🔴 TCP 로 실제로 붙는다)"
  if pg_up; then
    ok "dss-pg-app 이 떠 있다"
    [ "$(qpg "select 1 from pg_database where datname='$INV_DB'")" = 1 ] \
      && ok "DB $INV_DB 가 있다" \
      || bad "DB $INV_DB 가 없다 — 27-inventory-db.sh 를 먼저 돌리세요"
    [ "$(qpg "select 1 from pg_roles where rolname='$INV_ROLE'")" = 1 ] \
      && ok "롤 $INV_ROLE 이 있다" \
      || bad "롤 $INV_ROLE 이 없다 — 27-inventory-db.sh 를 먼저 돌리세요"
    v=$(qpg "select pg_get_userbyid(datdba) from pg_database where datname='$INV_DB'")
    [ "$v" = "$INV_ROLE" ] && ok "DB 의 주인이 $INV_ROLE 이다 (표를 만들 수 있다)" \
      || bad "DB 의 주인이 ${v:-?} 다 — $INV_ROLE 이 표를 못 만든다"
    v=$(qpg "select 1 from pg_authid where rolname='$INV_ROLE' and rolpassword is not null")
    [ "$v" = 1 ] && ok "롤에 비밀번호가 붙어 있다" \
      || bad "롤에 비밀번호가 없다 — 27-inventory-pw.sh 를 돌리세요"
    # 🔴 정렬이 다른 DB 와 같아야 목록 차례가 사이트마다 안 달라진다.
    v=$(qpg "select datcollate from pg_database where datname='$INV_DB'")
    n=$(qpg "select datcollate from pg_database where datname='dss_board'")
    [ -n "$v" ] && [ "$v" = "$n" ] && ok "정렬이 dss_board 와 같다 ($v)" \
      || say "    ⚠️ 정렬이 dss_board 와 다르다 (재고 ${v:-?} / 게시판 ${n:-?})"
  else
    bad "dss-pg-app 이 떠 있지 않다 — DB 를 하나도 볼 수 없다"
  fi
  tcp_db_check

  # ── 1-ㅁ. 【검사 4】 inventory.env ───────────────────────────────────
  # 🔴 **값은 화면에 찍지 않는다.** 있나/없나와 판정만 남긴다.
  step "1-ㅁ. 【검사 4】 $INV_ENV (이름·모드·판정만. 값은 안 찍는다)"
  if [ -f "$INV_ENV" ]; then
    ok "inventory.env 가 제자리에 있다"
    perm=$(stat -c '%a' "$INV_ENV" 2>/dev/null)
    own=$(stat -c '%U:%G' "$INV_ENV" 2>/dev/null)
    [ "$perm" = 600 ] && ok "모드 600" \
      || bad "모드가 ${perm:-?} 다 (600 이어야 한다 — 남이 읽는다)"
    [ "$own" = "root:root" ] && ok "주인이 root:root 다" \
      || bad "주인이 ${own:-?} 다 (root:root 이어야 한다)"
    miss=""
    for t in $ENV_KEYS; do
      if env_has "$INV_ENV" "$t"; then
        # 🔴 같은 이름이 두 줄이면 **나중 것이 이긴다**(compose 가 그렇게 읽는다).
        n=$(env_dups "$INV_ENV" "$t")
        if [ "${n:-0}" != 1 ]; then
          bad "$t 줄이 ${n}개다 — 나중 것이 이긴다. 하나만 남기세요"
          continue
        fi
        v=$(env_val "$INV_ENV" "$t")
        if [ -n "$v" ]; then ok "$t 줄이 하나고 값이 차 있다"
        else bad "$t 줄은 있는데 **값이 비었다**"; fi
      else
        bad "$t 가 없다"; miss="$miss $t"
      fi
    done
    [ -z "$miss" ] && ok "여덟 개가 다 있다" \
      || say "    → 없는 것:$miss"
    for t in $ENV_FORBIDDEN; do
      env_has "$INV_ENV" "$t" \
        && bad "inventory.env 에 $t 가 **있다** — 지우세요" \
        || ok "inventory.env 에 $t 가 없다 (맞다)"
    done
    # 🔴 주소 넷 중 둘이 여기 있다. 나머지 둘은 포털에 있고 검사 7 이 본다.
    judge_issuer       inventory.env "$(env_val "$INV_ENV" SSO_ISSUER)"
    judge_redirect_uri inventory.env "$(env_val "$INV_ENV" SSO_REDIRECT_URI)"
    v=$(env_val "$INV_ENV" SSO_CLIENT_ID)
    [ "$v" = "$CLIENT_ID" ] && ok "SSO_CLIENT_ID 가 $CLIENT_ID 다" \
      || bad "SSO_CLIENT_ID 가 $CLIENT_ID 가 아니다 (${v:-빔})"
    # 🔴 두 비밀키가 **달라야** 한다. 같으면 앱이 시작할 때 던진다(env.ts).
    #    값은 안 찍는다 — 길이와 같은지 여부만 본다.
    v=$(env_val "$INV_ENV" AUTH_SESSION_SECRET)
    n=$(env_val "$INV_ENV" SSO_TX_SECRET)
    [ "${#v}" -ge 32 ] && ok "AUTH_SESSION_SECRET 이 32자 이상이다 (${#v}자)" \
      || bad "AUTH_SESSION_SECRET 이 32자보다 짧다 (${#v}자) — 앱이 시작할 때 던진다"
    [ "${#n}" -ge 32 ] && ok "SSO_TX_SECRET 이 32자 이상이다 (${#n}자)" \
      || bad "SSO_TX_SECRET 이 32자보다 짧다 (${#n}자) — 앱이 시작할 때 던진다"
    [ "$v" != "$n" ] && ok "🔴 두 비밀키가 서로 다르다 (같으면 앱이 시작할 때 던진다)" \
      || bad "🔴 AUTH_SESSION_SECRET 과 SSO_TX_SECRET 이 **같다** — 앱이 안 뜬다"
    v=; n=
    # 사내 주소가 https 다. 쿠키에 secure 가 안 붙으면 세션 쿠키가 평문으로 흐른다.
    v=$(env_val "$INV_ENV" SESSION_COOKIE_SECURE)
    [ "$v" = true ] && ok "SESSION_COOKIE_SECURE 가 켜져 있다 (https 라 맞다)" \
      || bad "SESSION_COOKIE_SECURE 가 true 가 아니다 (${v:-빔}) — https 사이트에서는 켠다"
    # 포털 SSO 세션의 절대 만료 12시간을 넘기지 않는다 — 넘기면 앱이 **던진다**
    # (게시판은 깎았지만 이 저장소는 1~12 밖이면 오류다 — env.ts).
    v=$(env_val "$INV_ENV" SESSION_HOURS)
    case "$v" in
      12) ok "SESSION_HOURS 가 12 다" ;;
      1|2|3|4|5|6|7|8|9|10|11) say "    ⚠️ SESSION_HOURS 가 $v 다 — 12 가 기본이다." ;;
      *)  bad "SESSION_HOURS 가 ${v:-빔} 이다 — 1~12 밖이면 앱이 시작할 때 던진다" ;;
    esac
    # 🔵 있어도 되는 것들 — 없으면 그 기능만 꺼진다. 흠이 아니다.
    for t in STOCK_WORKBOOK_SHARE_PATH AS_LOOKUP_URL AS_LOOKUP_TOKEN INVENTORY_API_TOKEN; do
      env_has "$INV_ENV" "$t" && say "    · $t 가 있다 (값은 안 본다)" \
        || say "    · $t 가 없다 — 그 기능만 꺼진다(흠이 아니다)"
    done
    say "    🔵 STOCK_WORKBOOK_SHARE_PATH 는 **사람이 탐색기로 가는 경로**다."
    say "       비어 있으면 화면이 컨테이너 안 경로(/data/workbook/…)를 보여 준다 —"
    say "       직원이 그 글자를 복사해도 아무 데도 못 간다. 정해지면 넣으세요."
  else
    bad "inventory.env 가 없다: $INV_ENV"
    say "    → 🔴 **없는 env_file 하나면 docker compose 명령이 통째로 안 먹는다.**"
    say "      compose 의 app-inventory·tools-inventory 가 이 파일을 가리킨다."
    cmd "sh /volume1/dss/setup/27-inventory-place.sh"
  fi

  # ── 1-ㅂ. 【검사 5】 compose ─────────────────────────────────────────
  step "1-ㅂ. 【검사 5】 compose ($CF_EFF)"
  if compose_at "$CF_EFF" config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_at "$CF_EFF" config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  SVCS=$(compose_at "$CF_EFF" config --services 2>/dev/null)
  say "  새로 생기는 둘 (🔴 주석을 벗겼어야 보인다):"
  for s in "$INV_SVC" "$INV_TOOLS_SVC"; do
    echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
      || bad "서비스 목록에 $s 가 없다 — 주석으로 꺼져 있거나 파일이 옛것이다"
  done
  say "  🔴 건드리지 않는 열둘 (하나라도 없으면 남의 것이 섞인 것이다):"
  for s in app-auth app-as tools-as app-meters tools-meters \
           app-improvements tools-improvements app-po app-leave tools-leave \
           app-board tools-board; do
    echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
      || bad "서비스 목록에 $s 가 없다"
  done
  see_tag() { # 1 서비스 2 태그 3 사람이 읽을 이름
    svc_block "$CF_EFF" "$1" | grep -q "image: $2$" \
      && ok "$1 가 $2 를 가리킨다 ($3)" \
      || bad "$1 의 태그가 $2 가 아니다 ($3) — 지금 값: $(svc_image "$CF_EFF" "$1")"
  }
  say "  새로 생기는 둘의 태그:"
  see_tag "$INV_SVC"       "$TAG_APP"   "재고 관리"
  see_tag "$INV_TOOLS_SVC" "$TAG_TOOLS" "재고 관리 도구"
  say "  🔴 건드리지 않는 열둘의 태그 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-auth           "$KEEP_AUTH"        "포털 · 그대로"
  see_tag app-as             "$KEEP_AS"          "A/S · 그대로"
  see_tag tools-as           "$KEEP_ASTOOLS"     "A/S 도구 · 그대로"
  see_tag app-meters         "$KEEP_METERS"      "계측기 · 그대로"
  see_tag tools-meters       "$KEEP_METERSTOOLS" "계측기 도구 · 그대로"
  see_tag app-improvements   "$KEEP_IMP"         "개선요청 · 그대로"
  see_tag tools-improvements "$KEEP_IMPTOOLS"    "개선요청 도구 · 그대로"
  see_tag app-po             "$KEEP_PO"          "PO · 그대로"
  see_tag app-leave          "$KEEP_LEAVE"       "휴가 · 그대로"
  see_tag tools-leave        "$KEEP_LEAVETOOLS"  "휴가 도구 · 그대로"
  see_tag app-board          "$KEEP_BOARD"       "게시판 · 그대로"
  see_tag tools-board        "$KEEP_BOARDTOOLS"  "게시판 도구 · 그대로"
  # 포트 — 한 글자가 틀리면 리버스 프록시가 502 를 계속 낸다.
  svc_block "$CF_EFF" "$INV_SVC" | grep -q "127.0.0.1:$INV_PORT:$INV_INNER" \
    && ok "$INV_SVC 가 127.0.0.1:$INV_PORT 으로만 열린다" \
    || bad "$INV_SVC 의 포트가 127.0.0.1:$INV_PORT:$INV_INNER 가 아니다"
  # 설정 파일을 가리키는가
  for s in "$INV_SVC" "$INV_TOOLS_SVC"; do
    svc_block "$CF_EFF" "$s" | grep -q './env/inventory.env' \
      && ok "$s 가 ./env/inventory.env 를 읽는다" \
      || bad "$s 가 ./env/inventory.env 를 안 읽는다"
    svc_block "$CF_EFF" "$s" | grep -q 'DATABASE_URL:' \
      && ok "$s 에 DATABASE_URL 이 있다" \
      || bad "🔴 $s 에 DATABASE_URL 이 없다 — 뜨자마자 죽는다"
    # 🔴 볼륨 — 빠지면 1분마다 만들어지는 엑셀이 컨테이너 안에 쌓이고,
    #    **다음 배포에서 컨테이너를 새로 만드는 순간 전부 사라진다.**
    svc_block "$CF_EFF" "$s" | grep -q "$INV_DATA:$INV_MNT" \
      && ok "$s 에 $INV_DATA:$INV_MNT 볼륨이 있다" \
      || bad "🔴 $s 에 데이터 볼륨이 없다 — 만든 엑셀이 컨테이너와 함께 사라진다"
    # 🔴 그 위에 덧씌우는 **공유폴더 볼륨**. 빠져도 화면은 멀쩡하고 파일도
    #    남는다 — 다만 $INV_DATA/workbook 안쪽에만 쌓인다. 그 자리는 시놀로지
    #    ACL 때문에 직원이 탐색기로 못 연다. 이 시스템의 핵심 요구가
    #    「직원이 공유 폴더에서 현황판 엑셀을 읽는다」라서, 이것이 조용히
    #    무너지면 목적 자체가 사라진다.
    # 🔴 grep -qF 다(-q 가 아니다) — 이 경로에는 점이 넷(2. · 1. · 4.) 들어
    #    있어 정규식으로 읽으면 아무 글자나 맞는다. 고정 문자열로 본다.
    svc_block "$CF_EFF" "$s" | grep -qF "$INV_SHARE_WB:$INV_MNT/workbook" \
      && ok "$s 에 공유폴더 → $INV_MNT/workbook 볼륨이 있다" \
      || bad "🔴 $s 에 공유폴더 볼륨이 없다 — 현황판이 /volume1/dss 안쪽에 쌓여 **직원이 탐색기로 못 여는데 화면은 멀쩡하다**"
    v=$(svc_env "$CF_EFF" "$s" INVENTORY_DATA_DIR)
    [ "$v" = "$INV_MNT" ] && ok "$s 의 INVENTORY_DATA_DIR 가 $INV_MNT 다" \
      || bad "$s 의 INVENTORY_DATA_DIR 가 $INV_MNT 가 아니다 (${v:-빔}) — 볼륨과 짝이 안 맞는다"
  done
  # 도구는 평소에 뜨지 않아야 한다
  svc_block "$CF_EFF" "$INV_TOOLS_SVC" | grep -q 'profiles:.*tools' \
    && ok "$INV_TOOLS_SVC 에 profiles: [tools] 가 있다 (up -d 로 안 뜬다)" \
    || bad "$INV_TOOLS_SVC 에 profiles 가 없다 — 🔴 상시 서비스가 하나 늘어난다"
  # 🔴 엑셀 경로 셋 — 한글과 공백이 들어 있어 **꺼내서** 본다.
  #    값 자체는 비밀이 아니라 찍어도 된다. 오히려 눈으로 봐야 한다.
  for s in "$INV_SVC" "$INV_TOOLS_SVC"; do
    v=$(svc_env "$CF_EFF" "$s" STOCK_WORKBOOK_TEMPLATE_PATH)
    case "$v" in
      "$INV_MNT"/templates/*) ok "$s · STOCK_WORKBOOK_TEMPLATE_PATH = $v" ;;
      *) bad "$s · STOCK_WORKBOOK_TEMPLATE_PATH 가 $INV_MNT/templates/ 아래가 아니다 (${v:-빔})" ;;
    esac
    v=$(svc_env "$CF_EFF" "$s" STOCK_DOWNLOAD_TEMPLATE_PATH)
    case "$v" in
      "$INV_MNT"/templates/*) ok "$s · STOCK_DOWNLOAD_TEMPLATE_PATH = $v" ;;
      *) bad "$s · STOCK_DOWNLOAD_TEMPLATE_PATH 가 $INV_MNT/templates/ 아래가 아니다 (${v:-빔})" ;;
    esac
    v=$(svc_env "$CF_EFF" "$s" STOCK_WORKBOOK_PATH)
    case "$v" in
      "$INV_MNT"/workbook/*) ok "$s · STOCK_WORKBOOK_PATH = $v" ;;
      *) bad "$s · STOCK_WORKBOOK_PATH 가 $INV_MNT/workbook/ 아래가 아니다 (${v:-빔})" ;;
    esac
  done
  # 🔴 db-app 은 건드리지 않았어야 한다. 거기에 줄을 더하면 설정 지문이 바뀌어
  #    인자 없는 up -d 가 **DB 컨테이너를 다시 만든다.**
  svc_block "$CF_EFF" db-app | grep -q 'INVENTORY_APP_PASSWORD' \
    && bad "🔴 db-app 에 INVENTORY_APP_PASSWORD 가 들어갔다 — DB 가 다시 만들어진다" \
    || ok "db-app 에 더해진 줄이 없다 (맞다 — 롤과 DB 는 손으로 만들었다)"

  # ── 1-ㅅ. 【검사 6】 🔴 데이터 폴더 — 쓸 수 있는가 ───────────────────
  step "1-ㅅ. 【검사 6】 🔴 데이터 폴더 $INV_DATA — **쓸 수 있는가** (uid $UID_APP)"
  say "  「있는가」가 아니라 「제 일을 하는가」를 본다. 앱은 **1분마다** 여기에 쓴다 —"
  say "  못 써도 화면에는 아무 오류가 안 뜬다. 그래서 여기서 잡아야 한다."
  data_check

  # ── 1-ㅇ. 【검사 7】 포털 등록 · 명단 ────────────────────────────────
  step "1-ㅇ. 【검사 7】 포털(clients)에 $CLIENT_ID 가 등록돼 있는가 · 명단"
  if running dss-pg-auth; then
    # 🔴 boolean 을 || 로 이으면 PostgreSQL 이 'true'/'false' 로 바꾼다. psql 이
    #    칸으로 찍을 때의 't'/'f' 와 다르다 — 2026-10-13 게시판 설치에서 멀쩡한
    #    등록이 ✗ 둘로 보였다. case when 으로 't'/'f' 를 직접 만든다.
    ROW=$(qa "select case when is_active then 't' else 'f' end || '|' || case when requires_grant then 't' else 'f' end || '|' || launcher_url || '|' || length(client_secret_hash) || '|' || length(launcher_icon) || '|' || upper(to_hex(ascii(launcher_icon))) from clients where client_id='$CLIENT_ID'")
    if [ -z "$ROW" ]; then
      bad "clients 에 $CLIENT_ID 가 **없다** — 로그인이 아예 안 된다"
      cmd "sh /volume1/dss/setup/27-inventory-client.sh"
    else
      ok "clients 에 $CLIENT_ID 가 있다"
      IFS='|' read -r C_ACT C_GRANT C_URL C_HLEN C_ILEN C_ICODE <<EOF
$ROW
EOF
      [ "$C_ACT" = t ] && ok "is_active 가 참이다" \
        || bad "is_active 가 참이 아니다 (${C_ACT:-?}) — 포털이 거절한다"
      # 🔴 게시판·휴가·개선요청과 **반대**다. 까닭은 27-inventory-client.sh 머리말.
      if [ "$C_GRANT" = t ]; then
        ok "🔴 requires_grant 가 참이다 — 명단에 있는 사람만 (맞다 · PO 와 같다)"
      else
        bad "🔴 requires_grant 가 거짓이다 (${C_GRANT:-?})"
        say "      전 직원이 포털은 통과하고 **앱에서 거절당한다**(no_role)."
        say "      재고 관리에는 기본 역할이 없다 — 명단이 곧 자격이다."
      fi
      [ "$C_URL" = "$INV_BASE/" ] && ok "launcher_url 이 $INV_BASE/ 다" \
        || bad "launcher_url 이 $INV_BASE/ 가 아니다 (${C_URL:-?})"
      [ "$C_HLEN" = 64 ] && ok "client_secret_hash 가 64글자다 (sha256 hex)" \
        || bad "client_secret_hash 가 64글자가 아니다 (${C_HLEN:-?}글자)"
      if [ "$C_ILEN" = 1 ] && [ "$C_ICODE" = 1F4E6 ]; then
        ok "launcher_icon 이 U+1F4E6 한 글자다 (코드로 되읽었다)"
      else
        bad "launcher_icon 이 U+1F4E6 이 아니다 (글자수 ${C_ILEN:-?} · 코드 ${C_ICODE:-?})"
        cmd "sh /volume1/dss/setup/27-inventory-client.sh"
      fi
      # redirect_uri 는 포털이 **글자 단위로** 대조한다.
      v=$(qa "select 1 from clients where client_id='$CLIENT_ID' and '$INV_BASE$CB_PATH' = any(redirect_uris)")
      [ "$v" = 1 ] && ok "redirect_uris 에 $INV_BASE$CB_PATH 가 있다" \
        || bad "redirect_uris 에 그 주소가 없다 — 로그인이 끝에서 거절된다"
      v=$(qa "select 1 from clients where client_id='$CLIENT_ID' and backchannel_logout_uri = '$INV_BASE$BC_PATH'")
      [ "$v" = 1 ] && ok "backchannel_logout_uri 가 맞다" \
        || bad "backchannel_logout_uri 가 다르다 — 포털에서 로그아웃해도 안 끊긴다"
      for t in VIEWER STAFF ADMIN; do
        v=$(qa "select 1 from clients where client_id='$CLIENT_ID' and '$t' = any(available_roles::text[])")
        [ "$v" = 1 ] && ok "available_roles 에 $t 가 있다" \
          || bad "available_roles 에 $t 가 없다 — 그 역할로는 로그인이 거절된다"
      done
      # 🔴 명단 — user_client_grants.client_id 는 **clients.id(uuid)** 다.
      #    글자로 비교하면 조용히 0건이 나온다.
      v=$(qa "select count(*) from user_client_grants g join clients c on c.id=g.client_id where c.client_id='$CLIENT_ID' and g.role is not null")
      if [ "${v:-0}" -ge 1 ]; then
        ok "🔴 역할을 받은 사람이 ${v}명 — 적어도 한 사람은 들어올 수 있다"
      else
        bad "🔴 역할을 받은 사람이 **하나도 없다** — 아무도 못 들어간다"
        say "      재고 관리에는 비상구(make:admin 류)가 **없다.** 포털이 유일한 길이다."
        say "      포털 관리 화면에서 **정영빈 님을 ADMIN** 으로 먼저 넣으세요."
      fi
      v=$(qa "select count(*) from user_client_grants g join clients c on c.id=g.client_id where c.client_id='$CLIENT_ID' and g.role is null")
      [ "${v:-0}" = 0 ] && ok "역할이 비어 있는 명단 줄이 없다" \
        || say "    ⚠️ 역할이 빈 줄이 ${v}개 있다 — 그 사람들은 no_role 로 거절된다"
    fi
  else
    bad "dss-pg-auth 가 떠 있지 않다 — 포털 등록을 볼 수 없다"
  fi

  # ── 1-ㅈ. 【검사 8】 바깥 주소 ───────────────────────────────────────
  # 🔴 502 는 흠이 아니다. 「프록시와 인증서는 제대로 걸렸는데 갈 곳(앱)이 아직
  #    없다」는 뜻이다 — 첫 설치 전에는 그것이 **정상**이다.
  step "1-ㅈ. 【검사 8】 바깥 주소 $INV_BASE (앱 전에는 502 가 정상)"
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$INV_BASE/" 2>/dev/null)
  case "$code" in
    502)
      ok "→ 502 · **앱이 뜨기 전이면 이것이 정상이다**"
      say "      뜻: DNS 도 DSM 리버스 프록시도 인증서도 제대로 걸렸다. 다만"
      say "      localhost:$INV_PORT 에 아직 아무도 없다. --go 뒤에는 307 이 된다." ;;
    2??|3??)
      ok "→ $code · 앱이 이미 대답하고 있다 (--go 를 이미 돌린 뒤다)" ;;
    000|"")
      bad "→ 대답이 없다 — DNS 나 DSM 리버스 프록시가 아직 없다"
      say "      Cloudflare 에 A 레코드 inventory · DSM 역방향 프록시(443 →"
      say "      localhost:$INV_PORT)를 사람이 먼저 넣어야 한다." ;;
    404|503)
      bad "→ $code — 프록시 규칙이 다른 곳을 가리킨다(대상이 localhost:$INV_PORT 인가)" ;;
    *)
      bad "→ $code — 뜻을 모르겠다. 프록시 규칙과 인증서를 보세요" ;;
  esac
  say "  🔴 건드리지 않는 일곱 — 지금도 그대로여야 한다:"
  for t in login as meters improvements po leave board; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$t.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$t.dss21.co.kr → $code" ;;
      *)       bad "🔴 https://$t.dss21.co.kr → ${code:-없음} — 건드리지 않은 쪽이 흔들렸다" ;;
    esac
  done

  # ── 1-ㅊ. 【검사 9】 🔴 백업 일곱 + 데이터 폴더 · 디스크 · 도는 것 ───
  # 🔴 전환 절차서 전제 1번이 이것이다 — 「야간 백업에 운영 DB 와 데이터 폴더가
  #    들어 있다. **없으면 실자료를 넣지 않는다.**」
  step "1-ㅊ. 【검사 9】 오늘($TODAY) 백업이 **일곱**인가 · 데이터 폴더 · 디스크"
  n=0
  for db in dss_auth dss_meters dss_as dss_improvements dss_leave dss_board dss_inventory; do
    f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
      n=$((n + 1))
    else
      bad "오늘($TODAY) 뜬 $db 백업이 없다"
    fi
  done
  if [ "$n" = 7 ]; then
    ok "🔴 오늘 백업이 일곱이다 — 고친 야간 백업이 NAS 에서 **실제로 돌았다**"
  else
    bad "🔴 오늘 백업이 ${n}개뿐이다 (일곱이어야 한다)"
    say "    → dss_inventory 가 빠졌다면 고친 backup-nightly.sh 를 **NAS 에 올리지**"
    say "      않았거나, 올리고 한 번도 안 돌린 것이다. 올린 뒤 손으로 한 번:"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    say "      종료 코드 0 이고 ✓ dss_inventory 줄이 찍혀야 한다."
    say "    🔴 이 백업이 --init 의 되돌릴 자리다. 없으면 --init 이 멈춘다."
  fi
  # 🔴 데이터 폴더도 백업에 들어가야 한다 — DB 와 **따로**다.
  #    엑셀 양식 두 벌은 프로그램이 다시 만들 수 없는 **입력물**이다.
  if [ -r "$JOBS/backup-nightly.sh" ]; then
    v=$(grep -c 'inventory-data' "$JOBS/backup-nightly.sh")
    [ "${v:-0}" -ge 1 ] && ok "backup-nightly.sh 에 inventory-data 줄이 ${v}개 있다" \
      || bad "🔴 backup-nightly.sh 에 inventory-data 가 없다 — **양식 두 벌이 백업되지 않는다**"
    # 🔴 현황판 공유폴더는 위 inventory-data 의 **밖**이라 따로 세야 한다
    #    (2026-10-14 에 compose 가 /data/workbook 을 공유폴더로 덧씌웠다).
    #    그쪽이 받는 것은 프로그램이 다시 못 만드는 둘이다 —
    #    현황판_사람수정_*.xlsx (사람이 적은 것) 와 OLD/ (월별 영구 백업).
    v=$(grep -c 'inventory-workbook' "$JOBS/backup-nightly.sh")
    [ "${v:-0}" -ge 1 ] && ok "backup-nightly.sh 에 inventory-workbook 줄이 ${v}개 있다" \
      || bad "🔴 backup-nightly.sh 에 inventory-workbook 이 없다 — **현황판 공유폴더가 백업되지 않는다**"
  else
    bad "$JOBS/backup-nightly.sh 를 읽을 수 없다"
  fi
  if [ -d "$BKD/files/inventory-data" ]; then
    ok "백업에 files/inventory-data 가 있다 ($(find "$BKD/files/inventory-data" -type f | wc -l)개)"
  else
    say "    ⚠️ 백업에 files/inventory-data 가 아직 없다 — 폴더가 비어 있으면"
    say "       rsync 가 빈 폴더만 만든다. 야간 백업을 한 번 돌리면 생긴다."
  fi
  if [ -d "$BKD/files/inventory-workbook" ]; then
    ok "백업에 files/inventory-workbook 이 있다 ($(find "$BKD/files/inventory-workbook" -type f | wc -l)개)"
  else
    say "    ⚠️ 백업에 files/inventory-workbook 이 아직 없다 — 첫 설치 전이면"
    say "       공유폴더 자체가 없어 **정상**이다(흠으로 세지 않는다). 공유폴더가"
    say "       선 뒤 야간 백업을 한 번 돌리면 생긴다."
  fi
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (tar 둘 + 실은 이미지 + 덤프)"
  fi
  if pg_up && running dss-pg-auth; then
    ok "DB 둘 다 떠 있다 (이 설치에서 DB 컨테이너는 멈추지 않는다)"
  else
    bad "DB 컨테이너가 떠 있지 않다"
  fi
  for t in dss-auth dss-as dss-meters dss-improvements dss-po dss-leave dss-board; do
    running "$t" && ok "$t 가 돌고 있다" \
      || bad "$t 가 안 돌고 있다 — 이 설치는 그것을 건드리지 않는다"
  done
  if running "$INV_CNAME"; then
    say "  · $INV_CNAME 이 이미 돌고 있다 — --go 를 이미 돌린 뒤다"
  else
    say "  · $INV_CNAME 은 아직 없다 (맞다 — --go 가 띄운다)"
  fi
  say "  🔴 메모리 — 여덟째를 세우기 **전** 값이다. --go 뒤와 견주세요:"
  free -m 2>/dev/null | sed 's/^/      /'

  # ── 1-ㅋ. 표의 지금 상태 (🔴 ✗ 로 세지 않는다) ──────────────────────
  step "1-ㅋ. 표의 지금 상태 (읽기만 · ✗ 로 세지 않는다)"
  say "  🔴 --check 는 --init 보다 **먼저** 도는 것이 정상 차례다. 그래서 여기서"
  say "     「아직 없다」가 나오는 것은 흠이 아니다 — 무엇을 할 차례인지만 알린다."
  show_db_state hint
}

# ══════════════════════════════════════════════════════════════════════
#  compose 갈아 끼우기
#
#  🔴 보통은 할 일이 없다. 재고 관리의 compose 는 27-inventory-place.sh 가
#     주석을 벗겨 이미 제자리에 놓았다. 그래도 남겨 둔 것은, incoming 에 새
#     파일이 남아 있는 채로 여기까지 오는 일이 실제로 있기 때문이다.
#  🔴 --check 는 **갈아 끼우지 않는다.** 대신 incoming 의 그 파일을 들여다본다.
# ══════════════════════════════════════════════════════════════════════
compose_incoming() {
  local e MISS
  [ -s "$INCOMING" ] || return 0
  if cmp -s "$INCOMING" "$CF"; then
    say "  · incoming 의 compose 가 지금 것과 같다 — 할 일이 없다"
    return 0
  fi
  step "새 compose 를 먼저 시험한다 (바꾸기 전에)"
  # 🔴 주석을 **안 벗긴** 판이 incoming 에 남아 있을 수 있다. 그 판으로
  #    갈아 끼우면 app-inventory 가 통째로 사라진다 — 먼저 그것부터 본다.
  if ! grep -qx '  app-inventory:' "$INCOMING"; then
    bad "incoming 의 compose 는 app-inventory 가 **아직 주석**이다"
    say "    → 이것으로 갈아 끼우면 재고 관리가 사라진다. 벗기는 것은 이쪽이 한다:"
    cmd "sh /volume1/dss/setup/27-inventory-place.sh"
    return 1
  fi
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
  echo "DSS 재고 관리 첫 설치 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "  🔴 첫 설치라 「옛 태그로 내린다」가 없다. 되돌리기는 **없던 것으로**"
  say "     돌리는 일이다. 다른 일곱 사이트는 아무 상관이 없다."
  say
  say "  남기는 것 (지우지 않는다):"
  say "    · DB $INV_DB 와 롤 $INV_ROLE — 해가 없고, 다시 띄울 때 그대로 쓴다"
  say "    · 포털 clients 의 $CLIENT_ID — 지우지 말고 급하면 is_active 만 끈다"
  say "    · 마이그레이션 — 🔴 **되돌리지 않는다.** 표를 만들기만 했고"
  say "      이 DB 는 재고 관리 혼자 쓴다"
  say "    · 🔴 **데이터 폴더 $INV_DATA — 건드리지 않는다.**"
  say "      사람이 넣은 **엑셀 양식 두 벌**은 프로그램이 다시 만들 수 없는"
  say "      입력물이다. 지우면 현황판 엑셀을 아예 못 만든다."

  step "1. 지금 상태"
  if running "$INV_CNAME"; then
    say "  $INV_CNAME : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$INV_CNAME " || echo '?')"
  else
    say "  $INV_CNAME 은 돌고 있지 않다 — 이미 내려간 뒤다"
  fi
  show_db_state
  if [ -d "$INV_DATA" ]; then
    say "  데이터 폴더: 파일 $(find "$INV_DATA" -type f 2>/dev/null | wc -l)개 · $(du -sh "$INV_DATA" 2>/dev/null | cut -f1)"
    say "  그중 양식: $(find "$INV_DATA/templates" -maxdepth 1 -name '*.xlsx' 2>/dev/null | wc -l)개"
  fi

  step "2. 앱을 내린다 — 🔴 아래를 **한 줄씩** 친다"
  say "  (DSM 의 ash 는 긴 줄을 자른다. 줄 이어붙임도 깨졌다 — 한 줄씩.)"
  say "  🔴 인자 없는 down 을 부르지 않는다 — DB 까지 내려간다."
  cmd "cd /volume1/dss/deploy"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "C=\"compose -f \$F --env-file .env.nas\""
  cmd "\$D1 \$C stop $INV_SVC"
  cmd "\$D1 \$C rm -f $INV_SVC"
  script_file_hint "27-rollback"

  step "3. compose 를 백업본으로 되돌린다"
  say "  🔴 compose 에서 재고 관리 둘만 지우는 것이 아니라 **통째로 옛 파일로** 되돌린다."
  say "     손으로 지우면 들여쓰기 한 칸에 여덟 사이트가 함께 넘어간다."
  say "  있는 사본 (최근 다섯):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -5 | sed 's/^/      /' \
    || say "      (없다)"
  if [ -z "$(ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -1)" ]; then
    say "  ⚠️ 사본이 하나도 없다. 27-inventory-place.sh 도 이 스크립트도 옛 compose 를"
    say "     $BKD/docker-compose.nas.yml.<시각> 으로 남기므로,"
    say "     그것이 없다는 것은 갈아 끼운 적이 없다는 뜻이다 — 되돌릴 것도 없다."
  else
    say "  위에서 **되돌릴 것 하나를 고른 뒤**:"
    cmd "B=/volume1/dss/backups"
    cmd "ls -1t \$B/docker-compose.nas.yml.* | head -5"
    cmd "cp -p \$B/docker-compose.nas.yml.<고른것> \$F"
    cmd "chown root:root \$F && chmod 644 \$F"
    cmd "\$D1 \$C config --quiet"
  fi

  step "4. 이미지는 지우지 않는다"
  say "  $TAG_APP · $TAG_TOOLS 를 남겨 둔다 — 다시 띄울 때 그대로 쓴다."
  say "  디스크가 급할 때만:"
  cmd "\$D1 image rm $TAG_APP $TAG_TOOLS"

  step "5. 주소"
  say "  $INV_BASE 는 다시 **502** 가 된다 — 그것이 맞다."
  say "  Cloudflare 레코드와 DSM 프록시 규칙은 남겨 두세요. 다시 띄울 때 씁니다."
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit 0
fi

# ══ 여기부터 check · preload · force-load · init · go ══════════════════
echo "DSS 재고 관리 **첫 설치** · $(date '+%F %T')"
echo "  🔴 새로 서는 것 둘:  $TAG_APP · $TAG_TOOLS"
echo "  🔴 멈추는 것은 **없다** — 여덟째 사이트를 하나 더 띄우는 일이다."
echo "  · 주소 $INV_BASE → 127.0.0.1:$INV_PORT"
echo "  · 데이터 $INV_DATA → 컨테이너 $INV_MNT (🔴 주인 uid $UID_APP)"
echo "  🔵 오늘 하는 것은 **그릇까지**다 — 실자료와 항목 19종은 전환일 작업."
echo "  · 건드리지 않는 열둘 — $KEEP_AUTH · $KEEP_AS · $KEEP_ASTOOLS"
echo "    · $KEEP_METERS · $KEEP_METERSTOOLS · $KEEP_IMP"
echo "    · $KEEP_IMPTOOLS · $KEEP_PO · $KEEP_LEAVE · $KEEP_LEAVETOOLS"
echo "    · $KEEP_BOARD · $KEEP_BOARDTOOLS"
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**" ;;
  preload)    echo "  🔵 --preload — 이미지 둘을 싣고 지문만 맞춘다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  init)       echo "  🔴 --init — 표 열셋을 만든다. **DB 가 바뀐다.**" ;;
  go)         echo "  🔴 --go — app-inventory 를 띄운다. 다른 일곱은 안 멈춘다."
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(백업 · 주소)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "이미지 tar 둘 · 지문"
  EXP_APP=$(tar_config_id   "$TAR_APP"   2>/dev/null) || EXP_APP=""
  EXP_TOOLS=$(tar_config_id "$TAR_TOOLS" 2>/dev/null) || EXP_TOOLS=""
  for rec in "$TAG_APP|$TAR_APP|$EXP_APP|$SZ_APP|$MD5_APP" \
             "$TAG_TOOLS|$TAR_TOOLS|$EXP_TOOLS|$SZ_TOOLS|$MD5_TOOLS"; do
    IFS='|' read -r tag tarf exp sz md5 <<EOF
$rec
EOF
    if [ ! -s "$tarf" ]; then bad "$tag 의 tar 가 없다: $tarf"; continue; fi
    n=$(stat -c '%s' "$tarf" 2>/dev/null)
    m=$(md5sum "$tarf" 2>/dev/null | awk '{print $1}')
    if [ -z "$sz" ] || [ -z "$md5" ]; then
      say "  ⚠️ $tag · 바이트 $n · md5 $m — 🔴 **기대값이 없어 대조하지 않았다.**"
      say "     이미지를 구운 PC 에서 잰 값과 눈으로 맞춰 주세요."
    else
      if [ "$n" != "$sz" ]; then
        bad "$tag 의 바이트가 $sz 가 아니다 ($n) — 올리다 끊겼다. 싣지 않는다"
        continue
      fi
      if [ "$m" != "$md5" ]; then
        bad "$tag 의 md5 가 $md5 가 아니다 (${m:-못 읽음}) — 파일이 상했다. 싣지 않는다"
        continue
      fi
      ok "$tag · 바이트 $n · md5 맞음"
    fi
    if [ -z "$exp" ]; then bad "$tag 의 tar 에서 manifest.json 을 읽지 못했다"; continue; fi
    bring_img "$tag" "$tarf" "$exp"
  done

  # 🔴 실어 놓고 **안을 본다.** 태그와 지문이 맞아도 「무엇이 든 판인지」는
  #    사람이 읽을 수 있는 증거로 한 번 더 남긴다.
  step "【검사 2】 $TAG_TOOLS 안 — 마이그레이션 아홉 · tsconfig · src"
  tools_image_check
  if have_img "$TAG_APP"; then
    step "$TAG_APP — 구운 때와 안의 모양"
    say "  구운 때: $("$DOCKER" images "$TAG_APP" --format '{{.CreatedAt}}' 2>/dev/null)"
    OUTA=$("$DOCKER" run --rm --entrypoint sh "$TAG_APP" -c '
      [ -f /app/server.js ] && echo "SERVER 1" || echo "SERVER 0"
      [ -d /app/.next/static ] && echo "STATIC 1" || echo "STATIC 0"
      echo "PORT $(printenv PORT)"
      echo "HOSTNAME $(printenv HOSTNAME)"
      echo "WHO $(id -u):$(id -g)"' 2>&1)
    printf '%s\n' "$OUTA" | grep -E '^[A-Z]+ ' | sed 's/^/      /'
    printf '%s\n' "$OUTA" | grep -qx "SERVER 1" && ok "server.js 가 있다 (standalone 빌드)" \
      || bad "server.js 가 없다 — 앱 이미지가 아니다(도구를 앱으로 구웠나)"
    printf '%s\n' "$OUTA" | grep -qx "STATIC 1" && ok ".next/static 이 있다" \
      || bad ".next/static 이 없다 — 화면이 글자만 나온다"
    printf '%s\n' "$OUTA" | grep -qx "PORT $INV_INNER" && ok "이미지가 PORT=$INV_INNER 를 들고 있다" \
      || bad "이미지의 PORT 가 $INV_INNER 가 아니다"
    printf '%s\n' "$OUTA" | grep -qx "HOSTNAME 0.0.0.0" && ok "HOSTNAME 이 0.0.0.0 이다 (밖에서 닿는다)" \
      || bad "HOSTNAME 이 0.0.0.0 이 아니다 — 컨테이너 밖에서 못 닿는다"
    # 🔴 이 설치의 uid 결정이 맞는지 **이미지에서 되읽는다.** 폴더 권한을
    #    1001 로 맞춰 놓았는데 이미지가 다른 번호로 돌면 그 자리에서 어긋난다.
    printf '%s\n' "$OUTA" | grep -qx "WHO $UID_APP:$GID_APP" \
      && ok "🔴 이미지가 uid $UID_APP:$GID_APP 으로 돈다 — 폴더 주인과 같다" \
      || { bad "🔴 이미지의 uid 가 $UID_APP:$GID_APP 이 아니다 — 데이터 폴더를 못 쓴다"
           printf '%s\n' "$OUTA" | grep '^WHO ' | sed 's/^/      /'
           say "      폴더를 그 번호로 맞추거나(27-inventory-place.sh 의 UID_APP)"
           say "      이미지를 다시 구워야 합니다. 고치지 말고 알리세요." ; }
  fi

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 멈추지 않았다**"
  if [ "$FAIL" != 0 ] && [ "$FORCE_LOAD" != 1 ]; then
    echo "  🔴 지문이 어긋난 것이 있으면 **같은 태그로 다시 구운 것**이다:"
    echo "       bash $0 --preload --force-load"
  fi
  echo "  🔵 나머지 항목은 안 봤다. 이어서: bash $0        (읽기만)"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ --init — 🔴 첫 설치의 핵심. 여기서만 DB 가 바뀐다 ═════════════════
#
# 🔴 표 열셋이 서야 첫 화면이 뜬다. 없으면 42P01 로 죽는다.
# 🔴 다시 돌려도 안전하다 — migrate 는 이미 적용된 것을 건너뛴다
#    (drizzle 기록을 본다). 중간에 막혔을 때 그냥 다시 부르면 된다.
# 🔴 **seed-items 도 import-workbook 도 부르지 않는다.** 그것은 전환일
#    작업이고 전용 절차서가 따로 있다. 특히 import-workbook --real 은
#    **한 번만** 돌릴 수 있고 되돌리려면 DB 를 비워야 한다.
if [ "$MODE" = init ]; then
  step "--init · 여기서만 DB 가 바뀐다"
  say "  하는 일: 마이그레이션 아홉. 표 열셋이 선다."
  say "  🔴 다시 돌려도 안전하다. 이미 있는 것은 건너뛴다."
  say "  🔵 **자료는 한 줄도 안 넣는다.** 항목 19종(seed-items)도, 실자료"
  say "     (import-workbook --real)도 **전환일 작업**이다 — 그쪽은 사람이"
  say "     숫자를 대조하며 하는 별도의 날 작업이고 절차서가 따로 있다."

  # ── 적용 전 — 꼭 필요한 것만 본다 (전체 검사는 --check 가 한다) ──────
  step "1. 적용 전 확인"
  if ! pg_up; then
    bad "dss-pg-app 이 떠 있지 않다"
    stop "DB 가 없습니다. **아무것도 바꾸지 않았습니다.**"
  fi
  ok "dss-pg-app 이 떠 있다"
  [ "$(qpg "select 1 from pg_database where datname='$INV_DB'")" = 1 ] \
    && ok "DB $INV_DB 가 있다" || bad "DB $INV_DB 가 없다"
  tcp_db_check
  if ! have_img "$TAG_TOOLS"; then
    bad "$TAG_TOOLS 가 NAS 에 없다"
    say "    → 먼저:"
    cmd "bash $0 --preload"
  fi
  tools_image_check
  if ! compose_at "$CF" config --services 2>/dev/null | grep -qx "$INV_TOOLS_SVC"; then
    bad "지금 쓰는 compose 에 $INV_TOOLS_SVC 가 없다"
    say "    → compose 의 주석을 안 벗겼거나 제자리에 없다. 먼저 놓으세요:"
    cmd "sh /volume1/dss/setup/27-inventory-place.sh"
    stop "도구를 부를 수 없습니다. **아무것도 바꾸지 않았습니다.**"
  fi
  ok "compose 에 $INV_TOOLS_SVC 가 있다"

  # 🔴 백업을 **작업 직전에 다시** 찾는다. --check 에서 봤다는 것으로는
  #    부족하다 — 그 뒤에 지워졌을 수 있고, 무엇보다 --check 를 안 돌리고
  #    바로 여기로 올 수 있다.
  step "2. 🔴 오늘 백업을 **지금 다시** 찾는다"
  BK=$(ls -1t "$BKD/db/${INV_DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
  if [ -n "$BK" ] && [ -s "$BK" ]; then
    ok "오늘 백업 — $(basename "$BK") ($(du -h "$BK" | cut -f1))"
  else
    say "  🔴 오늘($TODAY) 뜬 $INV_DB 백업을 **지금 찾지 못했습니다.**"
    say "     먼저 이것부터 (종료 코드 0 이어야 합니다):"
    cmd "bash $D/jobs/backup-nightly.sh"
    say "     ✓ dss_inventory 줄이 찍혀야 합니다. 안 찍히면 고친"
    say "     backup-nightly.sh 를 NAS 에 아직 안 올린 것입니다."
    stop "백업 없이 DB 를 바꾸지 않습니다. **DB 는 그대로입니다.**"
  fi

  step "3. 지금 DB 상태"
  show_db_state
  if [ "$FAIL" != 0 ]; then
    stop "위 ✗ 를 먼저 해결해야 합니다. **DB 는 그대로입니다.**"
  fi

  MIG_BEFORE=$(mig_count); MIG_BEFORE=${MIG_BEFORE:-0}
  TBL_BEFORE=$(tbl_count); TBL_BEFORE=${TBL_BEFORE:-0}
  say
  say "  🔴 이제 DB 를 바꿉니다. 그만두려면 **20초 안에 Ctrl+C**."
  say "     지금 Ctrl+C 하면 DB 도 앱도 손대지 않은 채로 남습니다."
  sleep 20

  # ── 4. 표를 만든다 ──────────────────────────────────────────────────
  step "4. 마이그레이션 — 표 열셋을 만든다"
  "${COMPOSE[@]}" run --rm "$INV_TOOLS_SVC" npx tsx scripts/migrate.ts 2>&1 | sed 's/^/  /'
  rc=${PIPESTATUS[0]}
  if [ "$rc" = 0 ]; then
    ok "마이그레이션 끝 (종료 코드 0)"
  else
    bad "마이그레이션 실패 (종료 코드 $rc)"
    say "    🔴 「.env.local 을 확인하십시오」가 보이면 그 파일이 아니라"
    say "       compose 의 $INV_TOOLS_SVC 에 DATABASE_URL 이 없는 것입니다."
    stop "표가 다 만들어지지 않았습니다. 위 오류를 보세요."
  fi

  # ── 5. SQL 로 직접 센다 ─────────────────────────────────────────────
  # 🔴 스크립트가 「했다」고 말하는 것과 DB 에 「섰다」는 다른 일이다.
  step "5. 🔴 SQL 로 직접 센다 (「돌았다」가 아니라 「섰다」를 본다)"
  MIG_AFTER=$(mig_count)
  TBL_AFTER=$(tbl_count)
  [ "${MIG_AFTER:-0}" = "$N_MIG_WANT" ] \
    && ok "마이그레이션 기록 ${MIG_AFTER}줄 (전 ${MIG_BEFORE}줄)" \
    || bad "마이그레이션이 ${N_MIG_WANT}줄이 아니다 (${MIG_AFTER:-?})"
  [ "${TBL_AFTER:-0}" -ge "$N_TABLE_WANT" ] \
    && ok "public 스키마의 표 ${TBL_AFTER}개 (전 ${TBL_BEFORE}개 · 기대 $N_TABLE_WANT 이상)" \
    || bad "표가 ${TBL_AFTER:-?}개뿐이다 (기대 $N_TABLE_WANT)"
  # 🔴 개수만으로는 부족하다. **이름을 하나씩** 센다.
  for t in $INV_TABLES; do
    [ "$(tbl_has "$t")" = 1 ] && ok "표 $t 가 섰다" || bad "표 $t 가 없다"
  done
  say "  만들어진 표:"
  qi "select table_name from information_schema.tables where table_schema='public' order by 1" \
    | sed 's/^/    /'
  # 🔵 표만 섰고 자료는 **없어야** 한다. 있으면 누가 전환을 먼저 돌린 것이다.
  say "  🔵 자료는 비어 있어야 합니다 (전환일에 넣습니다):"
  say "     parts $(qi "select count(*) from parts")줄 ·" \
      "stock_entries $(qi "select count(*) from stock_entries")줄 ·" \
      "legacy_records $(qi "select count(*) from legacy_records")줄"
  v=$(qi "select count(*) from parts")
  [ "${v:-0}" = 0 ] && ok "parts 가 0줄이다 (맞다 — 전환일 전이다)" \
    || { bad "🔴 parts 에 ${v}줄이 **이미 있다** — 누가 가져오기를 먼저 돌렸다"
         say "      실자료 가져오기는 빈 DB 가 아니면 거절한다. 멈추고 알리세요." ; }

  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL"
  echo "  🔴 DB 를 바꿨습니다(표만). 앱은 **아직 안 떴습니다.**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  if [ "$FAIL" != 0 ]; then
    echo
    echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
    echo "🔵 마이그레이션은 **다시 돌려도 안전합니다**:"
    echo "     bash $0 --init"
    exit "$FAIL"
  fi
  echo
  echo "✅ 이어서 앱을 띄웁니다 (다른 일곱은 안 멈춥니다):"
  echo "     bash $0 --go"
  exit 0
fi

# ══ 1. 먼저 볼 것 (check · go 가 같이 지난다) ══════════════════════════
#
# 🔴 규칙 하나: **앱을 띄우기 전에 볼 것을 다 보고, 어긋나면 아무것도 하지
#    않은 채로 멈춘다.** 여기서 끝나면 아무 일도 일어나지 않는다.
step "1. 준비가 됐는지 기계로 본다 (아직 아무것도 안 바꿨다)"
compose_incoming || stop "compose 를 바꾸지 않았습니다. 아무것도 안 띄웠습니다."
run_checks

if [ "$MODE" = check ]; then
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  if [ "$FAIL" = 0 ]; then
    if ! have_img "$TAG_APP" || ! have_img "$TAG_TOOLS"; then
      echo "  ✅ 이어서 (아무것도 안 멈춥니다):  bash $0 --preload"
    elif [ -z "$(mig_table)" ]; then
      echo "  ✅ 이어서 (🔴 DB 가 바뀝니다):     bash $0 --init"
    elif ! running "$INV_CNAME"; then
      echo "  ✅ 이어서 (앱을 띄웁니다):         bash $0 --go"
    else
      echo "  ✅ 다 됐습니다. 눈으로 확인할 차례입니다."
    fi
  else
    echo "  ✗ 위 ✗ 를 먼저 해결하세요. Claude 에게 알려 주세요."
  fi
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ --go ═══════════════════════════════════════════════════════════════
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 띄우지 않았습니다.**"

# ── 2. 🔴 --init 이 끝났는지 **여기서 막는다** ─────────────────────────
#
# 🔴 왜 막는가: 표가 없는 DB 에 앱이 뜨면 첫 화면이 42P01 로 죽는다.
#    --init 은 따로 부르는 명령이라 **빠뜨릴 수 있다.** 그래서 명령은
#    나눠 두고 순서만 기계가 지킨다.
step "2. 🔴 --init 이 끝났는지 다시 센다 (앱을 띄우기 전에)"
if [ -z "$(mig_table)" ]; then
  say "  ✗ drizzle.__drizzle_migrations 가 없다 — **--init 을 아직 안 돌렸다**"
  say "    먼저:"
  cmd "bash $0 --init"
  stop "표가 없는 DB 에 앱을 띄우지 않습니다. **아무것도 안 바꿨습니다.**"
fi
MIG_NOW=$(mig_count);  MIG_NOW=${MIG_NOW:-0}
if [ "$MIG_NOW" != "$N_MIG_WANT" ]; then
  say "  ✗ 마이그레이션이 ${MIG_NOW}줄이다 ($N_MIG_WANT 이어야 한다)"
  if [ "$MIG_NOW" -lt "$N_MIG_WANT" ]; then
    say "    덜 들어갔다. 다시 돌려도 안전하다:"
    cmd "bash $0 --init"
  else
    say "    🔴 기대보다 **많다.** 이 설치가 모르는 마이그레이션이 들어갔다 —"
    say "    남의 변경이 섞였을 수 있다. 고치지 말고 먼저 알리세요."
  fi
  stop "앱을 띄우지 않았습니다. **아무것도 안 바꿨습니다.**"
fi
ok "마이그레이션 ${MIG_NOW}줄 — --init 이 끝났다"
for t in $INV_TABLES; do
  if [ "$(tbl_has "$t")" != 1 ]; then
    say "  ✗ 표 $t 가 없다 — 이대로 띄우면 첫 화면이 42P01 로 죽는다"
    cmd "bash $0 --init"
    stop "앱을 띄우지 않았습니다. **아무것도 안 바꿨습니다.**"
  fi
done
ok "표 열셋이 다 서 있다"

# ── 3. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 띄웠다) ───────────
step "3. 이미지 확인 · 필요하면 싣기 (tar 의 Config ↔ NAS 의 .Id)"
EXP_APP=$(tar_config_id "$TAR_APP" 2>/dev/null) || EXP_APP=""
if [ -z "$EXP_APP" ]; then
  bad "$TAR_APP 에서 manifest.json 을 읽지 못했다"
  stop "이미지를 확인하지 못했습니다. **아무것도 안 띄웠습니다.**"
fi
bring_img "$TAG_APP" "$TAR_APP" "$EXP_APP" || FAIL2=1
if [ "${FAIL2:-0}" = 1 ]; then
  say
  say "  🔴 이미지가 기대한 것과 다릅니다. **아직 아무것도 띄우지 않았습니다.**"
  stop "띄우기를 시작하지 않았습니다."
fi

# ══ 4. app-inventory 를 띄운다 ═════════════════════════════════════════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — compose 에 있는 것을 전부 띄우려
#    들고 DB 컨테이너까지 다시 만든다. --no-deps 로 **이름을 적은 하나만**.
# 🔴 이번에는 **멈추는 것이 없다.** 없던 서비스를 하나 더 세우는 일이다.
step "4. $INV_SVC 를 띄운다  (🔴 멈추는 것은 없다 — 새로 하나 세운다)"
say "  그대로 도는 것: 포털 · A/S · 계측기 · 개선요청 · PO · 휴가 · 게시판 · DB 둘."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  띄운 시각: $STOP_AT"
"${COMPOSE[@]}" up -d --no-deps "$INV_SVC" 2>&1 | sed 's/^/    /'
wait_http "재고 관리" "$INV_PORT" / "$INV_CNAME"
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 띄운 시각 $STOP_AT → 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 5. 스모크 ══════════════════════════════════════════════════════════
step "5. 스모크 — 통로 · 🔴 로그인이 어디로 보내는가 · 표 · 🔴 데이터 폴더 · 엑셀 · 주소"

say "  5-ㄱ. 컨테이너가 살아 있는가"
if running "$INV_CNAME"; then
  ok "$INV_CNAME 이 돌고 있다"
  say "      $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$INV_CNAME " || true)"
else
  bad "$INV_CNAME 이 안 돌고 있다 — 떴다가 죽었다"
  say "      🔴 환경 설정이 빠지면 **시작할 때 한꺼번에** 알려 준다"
  say "         (그 저장소 src/lib/env.ts 의 assertEnvOnStartup). 로그를 보세요:"
  cmd "$DOCKER logs --tail 50 $INV_CNAME"
fi

# ══════════════════════════════════════════════════════════════════════
#  🔴 5-ㄴ 이 이 설치에서 가장 값진 한 줄이다
#
#  /api/auth/sso/start 는 그냥 열리는 통로가 아니다. 앱이
#    ① SSO_ISSUER 로 **실제로 나가서** 설정(discovery)을 받아 오고
#    ② 거기서 받은 /authorize 주소에 ③ SSO_REDIRECT_URI 를 붙여
#    ④ 307 로 되돌려 준다.
#  그러니 그 **Location 값 하나**가 주소 둘과 컨테이너가 바깥으로 나갈 수
#  있는지(dss-edge 망)를 한꺼번에 증명한다.
#
#  🔴 설정이 덜 되면 오류가 아니라 /login?error=… 로 **조용히** 샌다.
#     그래서 「200 이 왔다」로는 못 잡는다. **나오는 주소**를 본다.
# ══════════════════════════════════════════════════════════════════════
say "  5-ㄴ. 🔴 로그인 통로가 **어디로 보내는가** (통로가 아니라 나오는 것을 본다)"
LOGIN_LOC=$(curl -s -o /dev/null -w '%{redirect_url}' -m 20 \
            "http://127.0.0.1:$INV_PORT$START_PATH" 2>/dev/null)
LOGIN_HEAD=${LOGIN_LOC%%[?]*}
say "      보내는 곳(물음표 앞까지): ${LOGIN_HEAD:-없음}"
case "$LOGIN_LOC" in
  "")
    bad "🔴 아무 데로도 안 보낸다 — 307 이 안 왔다"
    cmd "$DOCKER logs --tail 50 $INV_CNAME" ;;
  *"/login?error="*)
    bad "🔴 /login?error= 로 샜다 — OIDC 설정이 덜 됐거나 포털에 못 닿는다"
    say "      보는 곳 둘: inventory.env 의 SSO_ 넷 · compose 의 networks 에"
    say "      dss-edge 가 있는가(없으면 화면은 뜨는데 **로그인만** 안 된다)." ;;
  https://login.dss21.co.kr/*)
    ok "🔴 포털 https://login.dss21.co.kr 로 보낸다 — issuer 가 살아 있다"
    case "$LOGIN_LOC" in
      *172.*|*192.168.*)
        bad "🔴 주소에 사설 IP 가 섞였다 — inventory.env 에 auto 가 남은 것이다" ;;
    esac
    case "$LOGIN_LOC" in
      *"inventory.dss21.co.kr"*)
        ok "🔴 redirect_uri 가 inventory.dss21.co.kr 다 — 주소 넷이 맞는다" ;;
      *)
        bad "🔴 redirect_uri 에 inventory.dss21.co.kr 가 없다 — 끝에서 거절된다" ;;
    esac ;;
  *)
    bad "🔴 뜻밖의 곳으로 보낸다 — ${LOGIN_HEAD:-?}"
    say "      inventory.env 의 SSO_ISSUER 를 보세요." ;;
esac

say "  5-ㄷ. 표 열셋이 서 있는가 (SQL 로 센다)"
for t in $INV_TABLES; do
  [ "$(tbl_has "$t")" = 1 ] && ok "표 $t" || bad "표 $t 가 없다"
done

# 🔴 도는 컨테이너 **안에서** 쓴다. --check 의 임시 컨테이너와 다른 것을 본다 —
#    compose 가 실제로 붙인 볼륨이 맞는지까지 드러난다.
say "  5-ㄹ. 🔴 도는 컨테이너가 $INV_MNT 에 **실제로 쓰나**"
say "      (임시 컨테이너가 아니라 **지금 사람을 받는 그 컨테이너**로 본다.)"
OUTW=$("$DOCKER" exec "$INV_CNAME" sh -c '
  echo "WHO $(id -u):$(id -g)"
  if touch /data/.dss-write-test 2>/dev/null; then
    echo "LIVE WRITE_OK"
    rm -f /data/.dss-write-test 2>/dev/null
  else
    echo "LIVE WRITE_FAIL"
  fi
  if mkdir -p /data/.dss-mkdir-test 2>/dev/null; then
    echo "LIVE MKDIR_OK"
    rmdir /data/.dss-mkdir-test 2>/dev/null
  else
    echo "LIVE MKDIR_FAIL"
  fi' 2>&1)
printf '%s\n' "$OUTW" | grep -E '^(WHO|LIVE) ' | sed 's/^/      /'
case "$OUTW" in
  *"LIVE WRITE_OK"*)
    ok "🔴 도는 컨테이너가 썼다 (바로 지웠다) — 1분마다 도는 엑셀 갱신이 열려 있다" ;;
  *"LIVE WRITE_FAIL"*)
    bad "🔴 도는 컨테이너가 못 쓴다 — **엑셀이 영영 안 만들어진다**"
    say "      화면은 멀쩡하게 뜹니다. 오류도 안 납니다. 그래서 여기서 잡아야 합니다." ;;
  *)
    bad "판정하지 못했다 — 아래가 그대로의 출력이다"
    printf '%s\n' "$OUTW" | sed 's/^/      /' | head -8 ;;
esac
case "$OUTW" in
  *"LIVE MKDIR_OK"*)   ok "🔴 폴더도 만든다 (baseline · backup · OLD 가 이렇게 생긴다)" ;;
  *"LIVE MKDIR_FAIL"*) bad "🔴 폴더를 못 만든다 — 백업 폴더가 영영 안 생긴다" ;;
esac
# 🔴 볼륨이 **진짜로 밖을 가리키는가.** 컨테이너 안에만 쓰이고 있으면 다음
#    배포에서 만든 엑셀이 통째로 사라진다 — 그런데 화면은 멀쩡하다.
"$DOCKER" exec "$INV_CNAME" sh -c 'touch /data/.dss-mount-test 2>/dev/null' >/dev/null 2>&1
if [ -f "$INV_DATA/.dss-mount-test" ]; then
  ok "🔴 컨테이너가 쓴 것이 NAS 폴더에 **보인다** — 볼륨이 제대로 붙었다"
  rm -f "$INV_DATA/.dss-mount-test"
else
  bad "🔴 컨테이너가 쓴 것이 NAS 폴더에 **안 보인다** — 볼륨이 안 붙었다"
  say "      그 바이트는 컨테이너 안에 있고 **다음 배포에서 전부 사라진다.**"
  say "      compose 의 app-inventory 볼륨 한 줄을 보세요."
  "$DOCKER" exec "$INV_CNAME" sh -c 'rm -f /data/.dss-mount-test' >/dev/null 2>&1
fi

say "  5-ㅁ. 🔴 엑셀 자동 갱신이 **켜져 있는가** (로그에서 읽는다)"
say "      빈 DB 라 쓸 것이 없어 파일은 아직 안 생긴다 — 켜졌는지만 본다."
LOGS=$("$DOCKER" logs --tail 120 "$INV_CNAME" 2>&1)
case "$LOGS" in
  *"엑셀 한 벌 자동 갱신 켜짐"*)
    ok "🔴 1분 주기 자동 갱신이 켜졌다" ;;
  *"자동 갱신 꺼짐"*)
    bad "🔴 자동 갱신이 **꺼져 있다** — inventory.env 에 WORKBOOK_SYNC_DISABLED=1 이 남았다"
    say "      그 줄을 지우고 다시 띄우세요. 현황판 엑셀이 영영 안 만들어집니다." ;;
  *)
    say "    ⚠️ 로그에서 판정하지 못했다. 직접 보세요:"
    cmd "$DOCKER logs --tail 50 $INV_CNAME" ;;
esac
case "$LOGS" in
  *"환경 확인 완료"*) ok "시작할 때 환경 확인을 통과했다" ;;
  *"환경 설정이 빠졌습니다"*)
    bad "🔴 환경 설정이 빠졌다 — 로그에 빠진 이름이 한꺼번에 찍혀 있다"
    printf '%s\n' "$LOGS" | grep -A 12 '환경 설정이 빠졌습니다' | sed 's/^/      /' | head -14 ;;
esac

say "  5-ㅂ. 바깥 주소"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$INV_BASE/" 2>/dev/null)
case "$code" in
  307) ok "$INV_BASE → $code (로그인으로 넘긴다 — 이것이 기대한 값이다)" ;;
  2??|3??) ok "$INV_BASE → $code" ;;
  502) bad "$INV_BASE → 502 — 앱은 떴는데 프록시가 못 닿는다"
       say "      DSM 프록시의 대상이 localhost:$INV_PORT 인지 보세요." ;;
  *)   bad "$INV_BASE → ${code:-없음} — DNS · DSM 리버스 프록시 · 인증서" ;;
esac
say "  🔴 건드리지 않은 일곱이 그대로인가:"
for h in login as meters improvements po leave board; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code (그대로다)" ;;
    *)       bad "🔴 https://$h.dss21.co.kr → ${code:-없음} — 건드리지 않은 쪽이 흔들렸다" ;;
  esac
done
say "  열린 포트 (127.0.0.1 만이어야 한다):"
netstat -tln 2>/dev/null | grep ':13[0-9]\{3\}' | sed 's/^/      /'
say "  지금 도는 이미지:"
"$DOCKER" ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | sed 's/^/      /'
say "  🔴 메모리 — **여덟째입니다. 이 값을 compose 맨 아래 예산표에 옮겨 적습니다:**"
"$DOCKER" stats --no-stream --format '{{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}' 2>/dev/null \
  | sed 's/^/      /'
free -m 2>/dev/null | sed 's/^/      /'

# ══ 6. 마무리 ══════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  띄운 시각 $STOP_AT → 대답한 시각 $UP_AT · 약 ${DOWN}초"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" != 0 ]; then
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
  echo "되돌리기 안내:  bash $0 --rollback"
  exit "$FAIL"
fi
cat <<ANNOUNCE

브라우저로 확인해 주세요 (사내망 · 이 순서로):

   1. https://inventory.dss21.co.kr — 포털을 거쳐 로그인이 됩니까
      · 🔴 **역할을 받은 사람으로** 들어가야 합니다. 명단에 없으면
        「역할 없음」으로 거절됩니다 — 고장이 아니라 설계입니다.
      · 🔴 인증서 경고가 뜨면 DSM 프록시에 dss21.co.kr 인증서를
        지정하지 않은 것입니다(기본값이 synology.com 입니다).
   2. 머리말에 자기 이름과 **역할(관리자/기록/보기)** 이 맞게 나옵니까
   3. 재고 관리에서 로그아웃 → 포털 세션도 함께 끝납니까
   4. 🔴 포털에서 로그아웃한 뒤 재고 관리 탭을 새로고침 → 로그인 화면이 뜹니까
      · 백채널 로그아웃이 도는지를 보는 **유일한 길**입니다.
   5. https://login.dss21.co.kr 의 타일에 재고 관리가 보입니까
      · 🔴 requires_grant 가 켜져 있어 **명단에 있는 사람에게만** 보입니다.
   6. 🔴 목록이 **비어 있는 것이 맞습니다.** 부품도 기록도 아직 없습니다 —
      실자료는 전환일에 넣습니다. 「고장 났다」로 보지 마세요.
   7. 🔴 **포털 · A/S · 계측기 · 개선요청 · PO · 휴가 · 게시판이 그대로입니까** —
      이 설치는 그 일곱을 건드리지 않았습니다.

🔴 사람이 이어서 할 일:
  · 내일 아침 백업을 한 번 더 보세요 — 스케줄러가 실제로 돌려서
    dss_inventory 덤프와 files/inventory-data · files/inventory-workbook
    **셋이 다** 생기는지가 진짜 확인입니다(현황판 공유폴더가 셋째입니다):
      ls -lt /volume1/dss/backups/db/ | head -9
      ls -l  /volume1/dss/backups/files/
  · 위 메모리 값을 Claude 에게 알려 주세요 — compose 의 예산표를 다시 적습니다.
  · 포털에 **쓸 사람과 역할**을 넣으세요 (VIEWER/STAFF/ADMIN).

🔴 전환일(실자료를 넣는 날)은 **별도 작업**입니다:
  · 절차서: dss-inventory/docs/전환일_절차서_2026-10-12.md
  · 전제 1번이 「야간 백업에 운영 DB 와 데이터 폴더가 들어 있다」입니다 —
    위 백업 확인이 그것입니다. 확인 전에는 실자료를 넣지 않습니다.
  · 데이터 폴더에 **엑셀 양식 두 벌**을 먼저 넣어야 합니다
    (/volume1/dss/inventory-data/templates/). 넣은 뒤 주인을 되돌리세요:
      chown -R 1001:1001 /volume1/dss/inventory-data
  · 🔴 현황판은 그 폴더가 아니라 **사내 공유폴더**에 쌓입니다 (2026-10-14 부터
    compose 가 /data/workbook 을 이리로 덧씌웁니다):
      /volume1/2_AS센터/2. 부품 관리/1. 재고 및 부품 입출고 관리/4. 재고관리 시스템
    주인이 어긋났을 때만 **그 폴더 하나**를 되돌리세요:
      chown 1001:1001 '/volume1/2_AS센터/2. 부품 관리/1. 재고 및 부품 입출고 관리/4. 재고관리 시스템'
    🔴 여기에는 **-R 을 쓰지 마세요.** 그 아래에는 직원이 탐색기로 넣은 파일이
    섞일 수 있고, 경로가 한 글자만 어긋나도 -R 은 피해가 폴더 하나로 끝나지
    않습니다. 아래 파일의 주인까지 바꿔야 한다면 무엇을 바꾸는지 먼저 세어
    보세요: find '…/4. 재고관리 시스템' ! -uid 1001
  · 🔴 도구 컨테이너는 root 로 돕니다. /data 에 쓰는 전환일 명령은
    --user 1001:1001 로 돌리거나, 돌린 뒤 위 chown 을 하세요.

되돌리기 안내:  bash $0 --rollback
ANNOUNCE
exit "$FAIL"
