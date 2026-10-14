#!/bin/sh
# 재고 관리 설치 파일 셋을 제자리로 옮기고, 데이터 폴더를 만들어 권한을 맞춘다.
# 🔴 사람이 sudo -i 로 돌린다.
#   실행:  sh /volume1/dss/setup/27-inventory-place.sh
#
# 본은 25-board-place.sh 다. 다른 것이 셋 있고, 셋 다 아래에 까닭을 적었다:
#   ① 폴더 주인이 uid **1001** 이다 (게시판은 1000)
#   ② compose 의 주석을 **이 스크립트가 벗긴다** (게시판은 올리기 전에 벗겼다)
#   ③ 데이터 폴더가 「첨부가 쌓이는 곳」이 아니라 **앱이 1분마다 쓰는 곳**이다
#
# 🔴 순서가 있다 — inventory.env 가 **먼저**다.
#    그것 없이 compose 의 app-inventory 를 켠 판을 놓으면 docker compose 명령이
#    **통째로** 안 먹는다. 앱을 멈춘 뒤에 그걸 알면 다시 띄우지도 못한다
#    (개선요청 첫 설치 때의 교훈 · PO · 휴가 · 게시판도 같은 까닭으로 주석이었다).
#
# 🔴 옛 파일은 지우지 않고 사본을 남긴다. 되돌릴 자리가 필요하다.
#    compose 의 옛 판은 backups/docker-compose.nas.yml.<시각> 으로 간다 —
#    27-deploy.sh --rollback 이 그 자리를 안내한다.
#
# ── 🔴 ① uid 1001 — 앞의 일곱과 다르다 ────────────────────────────────
#    컨테이너는 nextjs(uid 1001)로 돈다. 그 저장소 Dockerfile 의 runner 가
#      groupadd --system --gid 1001 nodejs
#      useradd  --system --uid 1001 --gid nodejs nextjs   →   USER nextjs
#    로 굽기 때문이다. A/S · 계측기 · 개선요청 · 게시판은 node(uid 1000)였다.
#
#    🔴 **Dockerfile 을 고치지 않는다.** 고칠 이유가 없다 —
#       /volume1/dss/inventory-data 는 이 스크립트가 **새로 만드는 폴더**라
#       chown 1001 로 풀 수 있다. 게시판이 uid 를 1000 으로 바꿔야 했던 것은
#       **이미 있던 폴더가 1000 에게만 열려 있었기** 때문이지, 1000 이
#       규칙이어서가 아니다. 새 폴더에 그 제약을 옮겨 올 이유가 없고,
#       남의 저장소 이미지를 고치면 그쪽을 다시 구워야 한다.
#
#    dss 공유폴더에는 시놀로지 ACL(administrators 만 허용)이 걸려 있는데,
#    uid 1001 은 DSM 계정이 아니라 ACL 로는 권한을 줄 수 없다. 그래서
#    **이 폴더만** ACL 을 걷고 리눅스 권한으로 준다 — 01-prepare.sh 가
#    as-attachments · meters-files 에 한 것과 같은 방식이다.
#    🔵 여기서 ACL 을 걷어도 끊기는 사람이 없다. 직원이 탐색기로 쓰는
#       서류함(견적서 · 연락서 …)이 아니라 이번에 새로 만드는 폴더다.
#
# ── 🔴 ③ 「만들었나」가 아니라 **「쓸 수 있나」** ──────────────────────
#    임시 컨테이너를 -u 1001:1001 로 띄워 **실제로 파일을 만들었다 지우고,
#    폴더도 만들었다 지운다.** 앱이 둘 다 하기 때문이다(workbook-sync.ts 가
#    mkdir 로 workbook · baseline · backup · OLD 를 스스로 만든다).
#    🔴 이 확인이 게시판보다 더 중요하다. 게시판은 사람이 사진을 붙일 때
#       드러나지만, 재고 관리는 **1분마다** 쓴다 — 그런데 화면에는 아무
#       오류도 안 뜬다. 로그에만 남고 엑셀만 조용히 안 만들어진다.

set -u
D=/volume1/dss
IN=$D/setup/incoming
DOCKER=/usr/local/bin/docker
ACLT=/usr/syno/bin/synoacltool
DATA=$D/inventory-data
# 🔴 직원이 윈도우 탐색기로 여는 자리. compose 가 이 폴더를 /data/workbook 에
#    붙인다. $DATA 아래에 두지 않는 까닭: /volume1/dss 에는 시놀로지 ACL 이
#    걸려 있어 직원이 탐색기로 못 연다. 거꾸로 /data 통째를 여기로 돌리지도
#    않는다 — templates/ 의 양식 두 벌은 프로그램이 다시 못 만드는 입력물이라
#    사람이 드나드는 자리에 두지 않는다 (야간 백업이 받는 것도 그 양식이다).
SHARE_WB="/volume1/2_AS센터/2. 부품 관리/1. 재고 및 부품 입출고 관리/4. 재고관리 시스템"
UID_APP=1001
GID_APP=1001
# 🔴 **공유폴더에 쓸 때만** 쓰는 그룹 번호. $GID_APP(1001)과 다르다 —
#    까닭은 6-2 절에 적었다. 데이터 폴더(5번)는 1001:1001 그대로다.
GID_SHARE=100
STAMP=$(date +%Y%m%d-%H%M%S)
FAIL=0

# ── compose 주석 벗기기 — 🔴 줄 수를 먼저 세어 확인한다 ────────────────
# 게시판 때 바로 뒤 블록의 주석까지 함께 벗겨진 일이 있다. 그래서 표시 사이만
# 벗기고, **바뀐 줄 수가 기대값과 다르면 아무것도 놓지 않는다.**
# 기대값은 개발 PC 에서 실측했다 (2026-10-13, js-yaml 로 앞뒤 둘 다 파싱 확인).
# 2026-10-14: app-inventory 에 공유폴더 볼륨 한 줄이 늘어 69 → 70.
# 2026-10-14: tools-inventory 에도 **글자까지 같은** 한 줄을 더해 70 → 71.
#             두 자리가 같아야 하는 까닭은 compose 의 그 블록 머리말에 있다 —
#             전환일 명령(build-workbook-template · workbook-selftest)이
#             **앱이 보는 바로 그 파일**을 만들어야 하기 때문이다.
# 2026-10-14: 두 블록에 user: "1001:100" 한 줄과 그 까닭 주석을 더해 71 → 87
#             (app 쪽 9줄 · tools 쪽 7줄). 벗겨지는 주석도 바뀐 줄로 세어진다.
#             까닭: 공유폴더의 시놀로지 ACL 이 **이름 기반**이라 NAS 에 아예
#             없는 번호인 gid 1001 은 그 ACL 어디에도 안 걸린다. users 가
#             gid 100 이다 — **uid 는 1001 그대로.** 아래 6-2 절을 보라.
N_UNCOMMENT_WANT=87

# ── 개발 PC 에서 잰 값 — 이것과 다르면 옮기지 않는다 ───────────────────
# 🔴 셋 다 비어 있다. 까닭을 그대로 적어 둔다:
#    · inventory.env 는 비밀값이 들어가는 파일이라 저장소에 없다.
#    · compose 는 올린 뒤 **이 스크립트가 주석을 벗기므로** 제자리에 놓이는
#      파일은 올라온 것과 바이트가 다르다.
#    · backup-nightly.sh 는 저장소에서 고쳤지만, 올리는 시점의 판이 무엇인지는
#      올리는 사람이 안다.
# 🔴 그래서 **대조하지 않는다.** 대신 받은 값을 찍고 「대조하지 않았다」고 크게
#    말한다 — 조용히 지나가지 않게. 올리면서 잰 값과 눈으로 맞춰 주세요.
MD5_ENV=
MD5_COMPOSE=
MD5_BACKUP=

say()  { echo "$@"; }
ok()   { echo "  ✓ $*"; }
bad()  { echo "  ✗ $*"; FAIL=1; }

check_in() { # 1 파일이름 2 기대md5(비어 있으면 대조하지 않는다)
  got=""
  if [ ! -s "$IN/$1" ]; then
    bad "$IN/$1 이 없다 — 올렸는지 확인하세요 (scp 에는 -O 를 붙입니다)"
    return 1
  fi
  got=$(md5sum "$IN/$1" | awk '{print $1}')
  if [ -z "$2" ]; then
    say "  ⚠️ $1 · md5 $got — 🔴 **기대값이 없어 대조하지 않았다.**"
    say "     올리면서 잰 값과 같은지 눈으로 맞춰 주세요. 다르면 멈추세요."
    return 0
  fi
  if [ "$got" != "$2" ]; then
    bad "$1 의 md5 가 다르다 (받은 값 $got · 기대 $2)"
    say "     전송이 깨졌거나 다른 판입니다. 옮기지 않습니다."
    return 1
  fi
  ok "$1 · md5 맞음"
}

say "══ 1. 올라온 것이 맞는지 본다 (아직 안 옮긴다) ══"
check_in inventory.env          "$MD5_ENV"
check_in docker-compose.nas.yml "$MD5_COMPOSE"
check_in backup-nightly.sh      "$MD5_BACKUP"
[ "$FAIL" = 0 ] || { say; say "🔴 위를 먼저 해결하세요. 아무것도 안 옮겼습니다."; exit 1; }

say
say "══ 2. inventory.env 를 먼저 놓는다 (compose 보다 먼저) ══"
# 🔴 새 파일이라 덮어쓸 것이 없지만, 혹시 있으면 사본을 남긴다.
[ -f "$D/deploy/env/inventory.env" ] && cp -a "$D/deploy/env/inventory.env" "$D/deploy/env/inventory.env.bak-$STAMP"
cp "$IN/inventory.env" "$D/deploy/env/inventory.env" || exit 1
chown root:root "$D/deploy/env/inventory.env" && chmod 600 "$D/deploy/env/inventory.env" || exit 1
ok "env/inventory.env · $(stat -c '%U:%G %a' "$D/deploy/env/inventory.env")"
# 🔴 값은 안 찍는다. 있어야 하는 이름과 **있으면 안 되는 이름**만 센다.
say "     키 $(grep -cE '^[A-Z_]+=' "$D/deploy/env/inventory.env") 개 (여덟 이상이어야 합니다)"
for k in SSO_ISSUER SSO_CLIENT_ID SSO_CLIENT_SECRET SSO_REDIRECT_URI \
         AUTH_SESSION_SECRET SSO_TX_SECRET SESSION_COOKIE_SECURE SESSION_HOURS; do
  n=$(grep -cE "^[[:space:]]*(export[[:space:]]+)?$k=" "$D/deploy/env/inventory.env" 2>/dev/null || true)
  if [ "${n:-0}" = 1 ]; then
    ok "inventory.env 에 $k 가 한 줄 있다"
  elif [ "${n:-0}" = 0 ]; then
    bad "inventory.env 에 $k 가 **없다**"
  else
    bad "inventory.env 에 $k 가 ${n}줄이다 — 나중 것이 이긴다. 하나만 남기세요"
  fi
done
# 🔴 이 아홉은 compose 와 이미지가 넘긴다. 같은 값이 두 곳에 있으면 언젠가
#    한쪽만 바뀌는데, 그때 앱은 **오류 없이** 다른 DB 를 보거나 엉뚱한 자리에
#    엑셀을 쓴다. DEV_ROLE_OVERRIDE · WORKBOOK_SYNC_DISABLED 는 성격이 다르다 —
#    앞엣것은 역할을 낮춰 보는 개발용 울타리, 뒤엣것은 **엑셀 자동 갱신을
#    통째로 끄는** 값이다. 운영에 남아 있으면 현황판이 영영 안 만들어진다.
for k in DATABASE_URL PORT TZ INVENTORY_DATA_DIR \
         STOCK_WORKBOOK_PATH STOCK_WORKBOOK_TEMPLATE_PATH STOCK_DOWNLOAD_TEMPLATE_PATH \
         DEV_ROLE_OVERRIDE WORKBOOK_SYNC_DISABLED DEV_POSTGRES_PASSWORD; do
  n=$(grep -cE "^[[:space:]]*(export[[:space:]]+)?$k=" "$D/deploy/env/inventory.env" 2>/dev/null || true)
  if [ "${n:-0}" = 0 ]; then
    ok "inventory.env 에 $k 가 없다 (맞다 — compose·이미지가 넘긴다)"
  else
    bad "inventory.env 에 $k 가 **있다** (${n}줄) — 지우세요"
  fi
done

say
say "══ 3. 야간 백업 스크립트 ══"
cp -a "$D/jobs/backup-nightly.sh" "$D/jobs/backup-nightly.sh.bak-$STAMP" 2>/dev/null \
  && say "  · 옛것 사본: jobs/backup-nightly.sh.bak-$STAMP"
cp "$IN/backup-nightly.sh" "$D/jobs/backup-nightly.sh" || exit 1
chown root:root "$D/jobs/backup-nightly.sh" && chmod 700 "$D/jobs/backup-nightly.sh" || exit 1
# 🔴 전환 절차서가 전제 1번으로 못 박은 것이 이 두 줄이다 —
#    「야간 백업에 운영 DB 와 데이터 폴더가 들어 있다. 없으면 실자료를 넣지 않는다.」
#    개선요청은 이 한 줄이 빠져 11일간 아무 오류 없이 백업되지 않았다.
N=$(grep -c 'dss_inventory' "$D/jobs/backup-nightly.sh")
[ "${N:-0}" -ge 1 ] && ok "jobs/backup-nightly.sh · dss_inventory 줄 ${N}개" \
  || bad "🔴 backup-nightly.sh 에 dss_inventory 가 없다 — DB 가 한 번도 백업되지 않는다"
N=$(grep -c 'inventory-data' "$D/jobs/backup-nightly.sh")
[ "${N:-0}" -ge 1 ] && ok "jobs/backup-nightly.sh · inventory-data 줄 ${N}개" \
  || bad "🔴 backup-nightly.sh 에 inventory-data 가 없다 — 엑셀 양식 두 벌이 백업되지 않는다"
# 🔴 옮겨 놓은 것이 **돌 수 있는 파일인지**까지 본다. 문법이 깨진 백업
#    스크립트는 밤에 조용히 아무 일도 하지 않는다.
if bash -n "$D/jobs/backup-nightly.sh" 2>/dev/null; then
  ok "야간 백업 문법 통과"
else
  bad "야간 백업에 문법 오류가 있다 — 옛 사본으로 되돌리세요"
  bash -n "$D/jobs/backup-nightly.sh" 2>&1 | sed 's/^/     /' | head -5
fi

say
say "══ 4. 🔴 compose — 주석을 벗긴다 (줄 수를 세어 확인한 뒤) ══"
say "  표시 사이만 벗긴다. 게시판 때 바로 뒤 블록까지 벗겨진 일이 있다."
NEW=$IN/docker-compose.nas.yml.uncommented
# 🔴 awk 로 **표시 사이에서만** 맨 앞 두 칸 뒤의 '# ' 두 글자를 뗀다.
awk '
  /DSS-INVENTORY-UNCOMMENT-BEGIN-APP/   { inb = 1; print; next }
  /DSS-INVENTORY-UNCOMMENT-END-APP/     { inb = 0; print; next }
  /DSS-INVENTORY-UNCOMMENT-BEGIN-TOOLS/ { inb = 1; print; next }
  /DSS-INVENTORY-UNCOMMENT-END-TOOLS/   { inb = 0; print; next }
  inb && substr($0, 1, 4) == "  # " { print "  " substr($0, 5); next }
  { print }
' "$IN/docker-compose.nas.yml" > "$NEW" || exit 1

L_OLD=$(wc -l < "$IN/docker-compose.nas.yml")
L_NEW=$(wc -l < "$NEW")
if [ "$L_OLD" = "$L_NEW" ]; then
  ok "줄 수가 그대로다 (${L_NEW}줄) — 지워지거나 늘어난 줄이 없다"
else
  bad "🔴 줄 수가 달라졌다 (전 $L_OLD · 후 $L_NEW) — 옮기지 않는다"
fi
CHANGED=$(awk 'NR==FNR { a[FNR] = $0; next } a[FNR] != $0 { n++ } END { print n + 0 }' \
          "$IN/docker-compose.nas.yml" "$NEW")
say "  · 바뀐 줄: $CHANGED 개 (기대 $N_UNCOMMENT_WANT)"
if [ "$CHANGED" = "$N_UNCOMMENT_WANT" ]; then
  ok "🔴 벗긴 줄 수가 기대와 **같다** — 범위가 넘치지 않았다"
else
  bad "🔴 벗긴 줄 수가 기대($N_UNCOMMENT_WANT)와 다르다 ($CHANGED) — **옮기지 않는다**"
  say "     올린 compose 가 이 스크립트가 아는 판이 아닙니다. 고치지 말고 알리세요."
fi
# 서비스 두 줄이 실제로 섰는지 — 표시가 아니라 결과를 본다.
grep -qx '  app-inventory:' "$NEW"   && ok "app-inventory: 줄이 주석에서 벗겨졌다" \
  || bad "app-inventory: 가 아직 주석이다"
grep -qx '  tools-inventory:' "$NEW" && ok "tools-inventory: 줄이 주석에서 벗겨졌다" \
  || bad "tools-inventory: 가 아직 주석이다"
# 🔴 남의 블록이 함께 벗겨지지 않았는지 — 바로 뒤가 도구 절이라 특히 본다.
for s in app-auth app-as app-meters app-improvements app-po app-leave app-board; do
  grep -qx "  $s:" "$NEW" || bad "🔴 $s: 가 사라졌다 — 범위가 넘쳤다"
done
[ "$FAIL" = 0 ] || { say; say "🔴 위를 먼저 해결하세요. **아무것도 제자리로 옮기지 않았습니다.**"; exit 1; }

say
say "  이제 바꾸기 **전에** 새 파일이 말이 되는지 본다."
# 🔴 --project-directory 가 반드시 있어야 한다. compose 안의 env_file 은
#    ./env/inventory.env 처럼 **상대 경로**인데, 그 기준은 기본적으로 -f 로 준
#    파일이 있는 폴더다. incoming 에 둔 채로 검사하면 incoming/env/auth.env 를
#    찾다가 「no such file」로 죽는다 — 파일이 멀쩡해도 그렇다
#    (2026-09-29 휴가 설치에서 실제로 걸렸다). 놓일 자리(deploy/)를 기준으로
#    봐야 진짜 검사가 된다. **2번이 inventory.env 를 이미 놓았으므로** 여기서
#    새 compose 가 그 파일을 제대로 찾는지까지 한 번에 드러난다.
CFG="$DOCKER compose -f $NEW \
  --project-directory $D/deploy --env-file $D/deploy/.env.nas --profile tools"
if $CFG config --quiet >/dev/null 2>&1; then
  ok "새 compose 문법 통과 (놓일 자리 기준으로 봤다)"
else
  bad "새 compose 가 문법에서 걸린다 — 옮기지 않는다"
  $CFG config --quiet 2>&1 | sed 's/^/     /' | head -8
  say "  🔴 inventory.env 가 2번에서 제대로 놓였는지부터 보세요."
  exit 1
fi
cp -a "$D/deploy/docker-compose.nas.yml" "$D/backups/docker-compose.nas.yml.$STAMP" 2>/dev/null \
  && say "  · 옛것 사본: backups/docker-compose.nas.yml.$STAMP"
cp "$NEW" "$D/deploy/docker-compose.nas.yml" || exit 1
chown root:root "$D/deploy/docker-compose.nas.yml" && chmod 644 "$D/deploy/docker-compose.nas.yml" || exit 1
ok "deploy/docker-compose.nas.yml"

say
say "══ 5. 🔴 데이터 폴더를 만들고 권한을 맞춘다 (uid $UID_APP) ══"
say "  $DATA — 컨테이너가 nextjs(uid $UID_APP)로 돈다. ACL 을 걷고 리눅스 권한으로 준다."
say "  🔴 앞의 일곱(uid 1000)과 **다른 번호**입니다. 1000 으로 고치지 마세요."
mkdir -p "$DATA" || exit 1
# 🔴 사람이 넣는 입력물 둘. 프로그램이 만들지 못하는 것이라 자리를 미리 둔다.
#      templates/  양식 두 벌 (전환일에 사람이 넣는다 — 🔴 프로그램이 다시 못 만든다)
#      import/     현황판 최신 사본 · 묶음 판정표 (전환일 입력)
#    workbook/ 는 사람이 **보는** 자리라 미리 만들어 공유 폴더로 잡을 수 있게 한다.
#    baseline/ · backup/ · workbook/OLD/ 는 프로그램이 스스로 만든다 —
#    여기서 만들지 않는다(workbook-sync.ts 가 mkdir 한다).
mkdir -p "$DATA/templates" "$DATA/import" "$DATA/workbook" || exit 1
# find … -exec 로 폴더와 그 아래 전부에서 ACL 을 뗀다 (01-prepare.sh 의 unacl).
find "$DATA" -exec "$ACLT" -del {} \; >/dev/null 2>&1
# 🔴 -R 이다. 사람이 scp 로 넣은 양식 파일은 root 가 주인이라 그대로 두면
#    앱이 못 읽을 수 있다(모드가 600 이면 확실히 못 읽는다).
chown -R "$UID_APP:$GID_APP" "$DATA" || exit 1
chmod 750 "$DATA" "$DATA/templates" "$DATA/import" "$DATA/workbook" || exit 1
# 🔴 판정은 **숫자**(%u:%g)로 한다. DSM 에 그 번호짜리 계정이 있으면 %U 가
#    그 이름으로 보여 「1001 이 아니다」로 잘못 읽는다. 이름은 보여 주기만 한다.
MODE=$(stat -c '%u:%g %a' "$DATA" 2>/dev/null)
say "  · $DATA · $MODE (숫자) · $(stat -c '%U:%G' "$DATA" 2>/dev/null) (이름)"
case "$MODE" in
  *" 750") ok "모드 750" ;;
  *)       bad "모드가 750 이 아니다 ($MODE)" ;;
esac
case "$MODE" in
  "$UID_APP:$GID_APP "*) ok "주인이 uid $UID_APP (nextjs)이다" ;;
  *)                     bad "주인이 uid $UID_APP 이 아니다 ($MODE) — 컨테이너가 못 쓴다" ;;
esac
# 🔴 아래 것들까지 센다. 하나라도 남이 주인이면 그 파일에서만 조용히 막힌다.
OTHERS=$(find "$DATA" ! -uid "$UID_APP" 2>/dev/null | wc -l)
[ "${OTHERS:-1}" = 0 ] && ok "폴더 아래 전부가 uid $UID_APP 것이다" \
  || { bad "주인이 다른 것이 ${OTHERS}개 있다 — chown -R $UID_APP:$GID_APP $DATA"
       find "$DATA" ! -uid "$UID_APP" 2>/dev/null | head -5 | sed 's/^/       /'; }
ACLN=$("$ACLT" -get "$DATA" 2>&1 | grep -cE ':(allow|deny):')
[ "${ACLN:-1}" = 0 ] && ok "ACL 항목 0개 (걷혔다)" \
  || bad "ACL 항목이 ${ACLN}개 남아 있다 — 컨테이너가 막힌다"
say "  · 지금 들어 있는 것:"
ls -la "$DATA" 2>/dev/null | sed 's/^/      /'
say "  · templates/ 의 양식 (전환일 전에는 비어 있는 것이 정상입니다):"
ls -la "$DATA/templates" 2>/dev/null | sed 's/^/      /'

say
say "══ 5-2. 🔴 직원이 탐색기로 여는 현황판 자리를 만든다 ══"
say "  $SHARE_WB"
say "  compose 가 이 폴더를 /data/workbook 에 붙인다. 1분마다 다시 쓰이는"
say "  현황판 엑셀이 여기 생겨야 직원이 윈도우 탐색기로 엽니다."
say "  🔴 폴더가 **미리 없으면** 도커가 마운트할 때 root 것으로 만들어 버립니다."
say "     그러면 앱(uid $UID_APP)이 못 써서 엑셀이 영영 안 생기는데 화면은 멀쩡합니다."
say "  🔴 **맨 끝 폴더 하나만** 만지고 그 위 셋(2_AS센터 · 2. 부품 관리 ·"
say "     1. 재고 및 부품 입출고 관리)은 건드리지 않습니다 — 직원들이 쓰는"
say "     사내 공유폴더라 chown 을 위로 돌리면 권한이 망가집니다."
# 🔴 chown 에 -R 을 쓰지 않는다. 새로 만드는 빈 폴더라 아래에 아무것도 없고,
#    -R 은 경로가 어긋났을 때 피해가 폴더 하나로 끝나지 않는다.
# 🔴 ACL 은 걷지 않는다 — $DATA 와 **반대다.** 직원이 탐색기로 들어오는 길이
#    그 ACL 이다. 걷으면 엑셀은 생기는데 아무도 못 보게 된다.
SHARE_PARENT=$(dirname "$SHARE_WB")
if [ ! -d "$SHARE_PARENT" ]; then
  # 🔴 위 폴더가 없으면 경로가 틀린 것이다. mkdir -p 는 틀린 이름으로도 조용히
  #    만들어, 사내 공유폴더 안에 엉뚱한 폴더를 남긴다. 그래서 멈춘다.
  bad "위 폴더가 없다: $SHARE_PARENT"
  say "     경로의 대소문자 · 공백이 맞는지 보세요. **아무것도 만들지 않았습니다.**"
elif [ -d "$SHARE_WB" ]; then
  say "  · 이미 있다 — 새로 만들지 않는다"
elif mkdir -p "$SHARE_WB"; then
  say "  · 새로 만들었다"
else
  bad "폴더를 만들지 못했다: $SHARE_WB"
fi
if [ -d "$SHARE_WB" ]; then
  chown "$UID_APP:$GID_APP" "$SHARE_WB" || bad "주인을 바꾸지 못했다 — sudo 로 돌리고 있나요?"
  # 🔴 「만들었다」가 아니라 **다시 읽은 값**으로 판정한다. 판정은 숫자(%u:%g)로 —
  #    DSM 에 그 번호짜리 계정이 있으면 %U 가 그 이름으로 보인다.
  SMODE=$(stat -c '%u:%g %a' "$SHARE_WB" 2>/dev/null)
  say "  · $SMODE (숫자) · $(stat -c '%U:%G' "$SHARE_WB" 2>/dev/null) (이름)"
  case "$SMODE" in
    "$UID_APP:$GID_APP "*) ok "주인이 uid $UID_APP (nextjs)이다 — 앱이 여기에 쓴다" ;;
    *) bad "주인이 uid $UID_APP 이 아니다 ($SMODE) — 현황판 엑셀이 안 만들어진다" ;;
  esac
  # 모드는 바꾸지 않고 **본 값을 적어 둔다.** 직원이 탐색기로 보는 길은 리눅스
  #    모드가 아니라 이 공유폴더의 ACL 이 정한다 — 전환일에 눈으로 확인한다.
  say "  · 모드는 손대지 않았습니다 (위 값 그대로). 직원이 탐색기로 보이는지는"
  say "    전환일에 실제로 열어서 확인합니다 — 그 길은 공유폴더 ACL 이 정합니다."
fi

say
say "══ 6. 🔴 진짜 확인 — uid $UID_APP 이 **실제로 쓸 수 있나** ══"
say "  「있는가」가 아니라 「쓸 수 있는가」를 봅니다. 임시 컨테이너를 띄워"
say "  파일을 하나 만들었다 지우고, **폴더도 만들었다 지웁니다** —"
say "  앱이 workbook · baseline · backup · OLD 를 스스로 mkdir 하기 때문입니다."
PROBE_IMG=""
for t in dss-inventory:0.1 dss-board:0.2 dss-leave:0.2 dss-improvements:0.3 dss-as:2.5 dss-auth:1.7; do
  if "$DOCKER" image inspect "$t" >/dev/null 2>&1; then PROBE_IMG=$t; break; fi
done
if [ -z "$PROBE_IMG" ]; then
  bad "시험에 쓸 이미지를 하나도 찾지 못했다 — 쓰기 시험을 **못 했다**"
  say "     (재고 관리 이미지를 실은 뒤 27-deploy.sh 가 같은 시험을 다시 합니다.)"
else
  say "  · 시험에 쓴 이미지: $PROBE_IMG"
  # 🔴 콜론과 리다이렉션으로 빈 파일을 만드는 방식을 쓰지 마라 — 쓰기가 막히면
  #    ash 가 셸을 그 자리에서 끝내, 뒤 줄이 아예 안 돌고 판정이 **빈 채로**
  #    지나간다(2026-10-12 실측). touch 와 mkdir 은 외부 명령이라 실패해도 셸이 산다.
  OUT=$("$DOCKER" run --rm --network none -u "$UID_APP:$GID_APP" \
        -v "$DATA:/data" --entrypoint sh "$PROBE_IMG" -c '
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
          fi
          if touch /data/templates/.dss-write-test 2>/dev/null; then
            echo "PROBE TPL_OK"
            rm -f /data/templates/.dss-write-test 2>/dev/null
          else
            echo "PROBE TPL_FAIL"
          fi' 2>&1)
  printf '%s\n' "$OUT" | grep -E '^(uid=|PROBE )' | sed 's/^/     /'
  case "$OUT" in
    *"PROBE WRITE_OK"*)
      ok "🔴 uid $UID_APP 이 $DATA 에 **실제로 썼다** (바로 지웠다)" ;;
    *"PROBE WRITE_FAIL"*)
      bad "🔴 uid $UID_APP 이 못 쓴다 — 앱이 첫 1분부터 조용히 멈춘다"
      say "     ACL 이 남았거나 주인이 다릅니다. 위 5번 값을 보세요." ;;
    *)
      bad "쓰기 시험을 판정하지 못했다 — 아래가 그대로의 출력이다"
      printf '%s\n' "$OUT" | sed 's/^/     /' | head -8 ;;
  esac
  case "$OUT" in
    *"PROBE MKDIR_OK"*)   ok "🔴 폴더도 만들 수 있다 (workbook · backup · OLD 가 이렇게 생긴다)" ;;
    *"PROBE MKDIR_FAIL"*) bad "🔴 폴더를 못 만든다 — 백업 폴더가 영영 안 생긴다" ;;
  esac
  case "$OUT" in
    *"PROBE TPL_OK"*)   ok "templates/ 에도 쓸 수 있다" ;;
    *"PROBE TPL_FAIL"*) bad "templates/ 에 못 쓴다 — 양식을 못 읽을 수도 있다" ;;
  esac
  # 시험 흔적이 남지 않았는지까지 본다.
  LEFT=$(find "$DATA" -maxdepth 2 -name '.dss-*-test' 2>/dev/null | wc -l)
  [ "${LEFT:-0}" = 0 ] && ok "시험 흔적이 남지 않았다" \
    || { bad "시험 흔적이 남아 있다 — 아래를 손으로 지우세요"
         find "$DATA" -maxdepth 2 -name '.dss-*-test' 2>/dev/null | sed 's/^/       /'; }
fi

say
say "══ 6-2. 🔴 진짜 확인 — $UID_APP:$GID_SHARE 이 **공유폴더에** 쓸 수 있나 ══"
say "  $SHARE_WB"
say "  🔴 6번과 **다른 그룹 번호**로 잽니다 — 6번(데이터 폴더)은 $UID_APP:$GID_APP 이고"
say "     여기는 $UID_APP:$GID_SHARE(users) 입니다. 공유폴더의 시놀로지 ACL 은 이름"
say "     기반이라 NAS 에 아예 없는 번호인 gid $GID_APP 은 그 ACL 어디에도 안 걸립니다"
say "     (2026-10-14 NAS 실측: 공유폴더 $UID_APP:$GID_APP ✗ · $UID_APP:$GID_SHARE ✓)."
say "     compose 의 app-inventory · tools-inventory 도 같은 번호로 돕니다 —"
say "     **앱이 쓰는 그 번호로** 재야 이 시험이 뜻이 있습니다."
say "  🔴 5-2 의 「주인이 $UID_APP 이다」로는 **모자랍니다.** 여기는 직원들이 쓰는"
say "     사내 공유폴더라 시놀로지 ACL 이 켜져 있고, ACL 이 켜진 자리에서는 chown"
say "     만으로 쓰기가 열린다는 보장이 없습니다. 그래서 **앱이 쓰는 길로** 잽니다 —"
say "     6번과 같은 방식으로 임시 컨테이너를 띄워 /data/workbook 에 써 봅니다."
say "  🔴 여기서는 ACL 을 **걷지 않습니다.** 직원이 탐색기로 들어오는 길이 그"
say "     ACL 입니다. 걷으면 엑셀은 생기는데 아무도 못 보게 되어 이 폴더를 쓰는"
say "     까닭 자체가 사라집니다. 아래가 ✗ 면 고치지 말고 **알리세요.**"
if [ -z "$PROBE_IMG" ]; then
  bad "시험에 쓸 이미지를 하나도 찾지 못했다 — 공유폴더 쓰기 시험을 **못 했다**"
  say "     (재고 관리 이미지를 실은 뒤 27-deploy.sh 가 같은 시험을 다시 합니다.)"
elif [ ! -d "$SHARE_WB" ]; then
  bad "공유폴더가 없어 쓰기 시험을 **못 했다** — 위 5-2 의 ✗ 를 먼저 보세요"
else
  say "  · 시험에 쓴 이미지: $PROBE_IMG"
  # 🔴 6번과 같은 까닭으로 콜론과 리다이렉션으로 빈 파일을 만들지 않는다 —
  #    쓰기가 막히면 ash 가 셸을 그 자리에서 끝내 뒤 줄이 아예 안 돌고 판정이
  #    빈 채로 지나간다. touch 와 mkdir 은 외부 명령이라 실패해도 셸이 산다.
  # 🔴 여기만 $GID_SHARE(100 · users)로 띄운다. 6번은 $GID_APP(1001)이다. 까닭:
  #     · 공유폴더의 시놀로지 ACL 은 **이름 기반**이고 group:users 와 개별
  #       사용자에게 허용한다. users 가 gid 100 이다. NAS 에 아예 없는 번호인
  #       gid 1001 은 그 ACL 어디에도 안 걸려, 폴더 주인을 1001 로 바꿔도 막힌다
  #       (2026-10-14 NAS 실측: 공유폴더 1001:1001 ✗ · 1001:100 ✓).
  #     · 데이터 폴더는 주인이 1001 이고 모드가 750 이라 앞자리 rwx 로 통한다.
  #       거기까지 gid 100 으로 바꾸면 users(전 직원)에게 읽기가 열리므로
  #       **좁은 쪽을 그대로 둔다** — 5번의 chown 은 1001:1001 이다.
  #     · compose 의 app-inventory · tools-inventory 도 1001:100 으로 돈다.
  #       앱이 쓰는 바로 그 번호로 재는 것이 이 절의 핵심이다.
  WOUT=$("$DOCKER" run --rm --network none -u "$UID_APP:$GID_SHARE" \
        -v "$SHARE_WB:/data/workbook" --entrypoint sh "$PROBE_IMG" -c '
          id
          if touch /data/workbook/.dss-write-test 2>/dev/null; then
            echo "PROBE WB_WRITE_OK"
            rm -f /data/workbook/.dss-write-test 2>/dev/null
          else
            echo "PROBE WB_WRITE_FAIL"
          fi
          if mkdir -p /data/workbook/.dss-mkdir-test 2>/dev/null; then
            echo "PROBE WB_MKDIR_OK"
            rmdir /data/workbook/.dss-mkdir-test 2>/dev/null
          else
            echo "PROBE WB_MKDIR_FAIL"
          fi' 2>&1)
  printf '%s\n' "$WOUT" | grep -E '^(uid=|PROBE )' | sed 's/^/     /'
  case "$WOUT" in
    *"PROBE WB_WRITE_OK"*)
      ok "🔴 $UID_APP:$GID_SHARE 이 공유폴더에 **실제로 썼다** (바로 지웠다)" ;;
    *"PROBE WB_WRITE_FAIL"*)
      bad "🔴 $UID_APP:$GID_SHARE 이 공유폴더에 못 쓴다 — 현황판 엑셀이 영영 안 생긴다"
      say "     화면에는 아무 오류도 안 뜹니다. 로그에만 남습니다."
      say "     공유폴더 ACL 에 group:users 가 아직 있는지, 그리고 그 users 가"
      say "     gid $GID_SHARE 인지(getent group users)부터 보세요."
      say "     🔴 ACL 을 걷어서 풀지 마세요 — 직원이 못 보게 됩니다. 알리세요." ;;
    *)
      bad "공유폴더 쓰기 시험을 판정하지 못했다 — 아래가 그대로의 출력이다"
      printf '%s\n' "$WOUT" | sed 's/^/     /' | head -8 ;;
  esac
  case "$WOUT" in
    *"PROBE WB_MKDIR_OK"*)   ok "🔴 폴더도 만들 수 있다 (workbook/OLD 가 이렇게 생긴다)" ;;
    *"PROBE WB_MKDIR_FAIL"*) bad "🔴 폴더를 못 만든다 — OLD/ 가 안 생겨 월별 보관이 멈춘다" ;;
  esac
  # 시험 흔적이 남지 않았는지까지 본다. 직원이 보는 폴더라 더 그렇다.
  WLEFT=$(find "$SHARE_WB" -maxdepth 2 -name '.dss-*-test' 2>/dev/null | wc -l)
  [ "${WLEFT:-0}" = 0 ] && ok "시험 흔적이 남지 않았다" \
    || { bad "시험 흔적이 남아 있다 — 아래를 손으로 지우세요"
         find "$SHARE_WB" -maxdepth 2 -name '.dss-*-test' 2>/dev/null | sed 's/^/       /'; }
fi

say
say "══ 7. 제자리 것이 맞는지 다시 본다 ══"
# 🔴 「올렸다」가 아니라 「제자리에 맞는 것이 있다」를 본다. 2026-09-29 에
#    새 스크립트를 제자리로 복사하는 것을 빠뜨린 채 --go 를 돌려, 옛 스크립트가
#    새 compose 를 갈아 끼우고 어긋나 멈췄다.
for f in "$D/deploy/env/inventory.env" "$D/deploy/docker-compose.nas.yml" "$D/jobs/backup-nightly.sh"; do
  if [ -s "$f" ]; then
    say "  · $(basename "$f") · $(stat -c '%U:%G %a' "$f") · md5 $(md5sum "$f" | awk '{print $1}')"
  else
    bad "$(basename "$f") 가 제자리에 없다"
  fi
done

say
say "══ 8. 서비스 목록에 재고 관리가 보이나 ══"
SVCS=$("$DOCKER" compose -f "$D/deploy/docker-compose.nas.yml" \
  --project-directory "$D/deploy" --env-file "$D/deploy/.env.nas" --profile tools \
  config --services 2>/dev/null)
for s in app-inventory tools-inventory; do
  echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
    || bad "서비스 목록에 $s 가 없다 — 주석이 안 벗겨졌거나 파일이 옛것이다"
done
say "  🔴 건드리지 않는 열넷도 그대로인가:"
for s in db-app db-auth app-auth app-as app-meters app-improvements app-po app-leave \
         app-board tools-as tools-meters tools-improvements tools-leave tools-board; do
  echo "$SVCS" | grep -qx "$s" && ok "$s" || bad "🔴 $s 가 사라졌다 — 범위가 넘쳤다"
done

say
say "══ 9. 임시 자리를 비운다 ══"
# 🔴 inventory.env 에는 비밀값이 있다. 아무나 읽는 폴더에 두지 않는다.
rm -f "$IN/inventory.env" "$IN/docker-compose.nas.yml" "$NEW" "$IN/backup-nightly.sh"
ok "incoming 을 비웠다"

say
if [ "$FAIL" = 0 ]; then
  say "══ 다 됐습니다 ══"
  say "  다음: 야간 백업을 손으로 한 번 돌려 dss_inventory 가 뜨는지 봅니다."
  say
  say "    bash /volume1/dss/jobs/backup-nightly.sh"
  say
  say "  ✓ dss_inventory 줄과 ✓ inventory-data 줄이 찍혀야 합니다 (DB 일곱)."
  say "  그다음 준비 확인으로 갑니다 —"
  say "    sh /volume1/dss/setup/27-inventory-check.sh"
  exit 0
else
  say "══ 🔴 위 ✗ 를 보세요 ══"
  say "  사본이 남아 있습니다 (.bak-$STAMP · backups/…$STAMP)"
  exit 1
fi
