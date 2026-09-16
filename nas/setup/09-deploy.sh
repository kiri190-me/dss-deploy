#!/bin/bash
# /volume1/dss/setup/09-deploy.sh — 2026-09-16 (dss-as 1.4 · [폴더 열기] 를 실제로 고친다)
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i
#   (NAS)         bash /volume1/dss/setup/09-deploy.sh
#
# **A/S 만 잠깐 멈춘다.** 통합 로그인 · 계측기 · DB 는 건드리지 않는다.
#
# ── 무엇이 바뀌나 ───────────────────────────────────────────────────────
# 1.3 에서 [폴더 열기] 가 여전히 안 열렸다. 도우미가 주소를 둘 가지고 있었지만,
# 첫째가 **풀리지 않는 서버 이름**이면 Test-Path 가 $false 를 주는 대신 **던져서**
# 둘째를 시도조차 못 했다($ErrorActionPreference = 'Stop'). 1.4 가 그 자리를 삼켜
# 다음 주소로 넘긴다.
#
# 함께 as.env 의 주소 **차례를 바꾼다** — IP 를 먼저, 이름을 나중에.
# 풀리지 않는 이름을 기다리는 데 약 3초가 걸려서(실측), 그 PC 에서는 누를 때마다
# 3초를 기다린 뒤에야 열리게 된다. NAS 주소는 DSM 에서 손으로 고정해 두었다.
#
# ⚠️ **PC 마다 도우미를 새로 설치해야 한다.** 주소와 스크립트는 설치할 때 그 PC 에
#    박힌다 — 서버만 고쳐서는 이미 깔린 도우미가 바뀌지 않는다.
#
# ── 되돌리기 ────────────────────────────────────────────────────────────
#   sed -i 's/dss-as:1.4/dss-as:1.3/' /volume1/dss/deploy/docker-compose.nas.yml
#   /usr/local/bin/docker compose -f /volume1/dss/deploy/docker-compose.nas.yml \
#     --env-file /volume1/dss/deploy/.env.nas up -d app-as
# as.env 옛 사본은 backups/as.env.<시각>. 스키마는 건드리지 않는다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE_SRC="/volume1/3_견적-세금계산서-국내발주/4. DSS 내자견적서 (활용)"

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/09-deploy-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

PASS=0; FAIL=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

COMPOSE=("$DOCKER" compose -f "$D/deploy/docker-compose.nas.yml" --env-file "$D/deploy/.env.nas" --profile tools)

echo "DSS 배포 · $(date '+%F %T')"
echo "  dss-as 1.3 → 1.4 · [폴더 열기] 고침 · 공유폴더 주소 차례 바꿈"

# ══ 1. 먼저 볼 것 ══════════════════════════════════════════════════════
step "1. 먼저 볼 것"

if "$DOCKER" image inspect dss-as:1.4 >/dev/null 2>&1; then
  ok "dss-as:1.4 ($("$DOCKER" image inspect dss-as:1.4 --format '{{.Id}}' | cut -c1-19)…)"
else
  bad "dss-as:1.4 가 없다"
  stop "먼저 images/dss-as-1.4.tar.gz 를 docker load 하세요."
fi

INCOMING=$D/setup/incoming/docker-compose.nas.yml
if [ -s "$INCOMING" ] && ! cmp -s "$INCOMING" "$D/deploy/docker-compose.nas.yml"; then
  mkdir -p "$D/backups"
  cp -p "$D/deploy/docker-compose.nas.yml" "$D/backups/docker-compose.nas.yml.$STAMP"
  cp "$INCOMING" "$D/deploy/docker-compose.nas.yml"
  chown root:root "$D/deploy/docker-compose.nas.yml"; chmod 644 "$D/deploy/docker-compose.nas.yml"
  rm -f "$INCOMING"
  ok "compose 새것으로 (옛것: backups/docker-compose.nas.yml.$STAMP)"
fi

INCOMING_ENV=$D/setup/incoming/as.env
if [ -s "$INCOMING_ENV" ] && ! cmp -s "$INCOMING_ENV" "$D/deploy/env/as.env"; then
  cp -p "$D/deploy/env/as.env" "$D/backups/as.env.$STAMP"
  cp "$INCOMING_ENV" "$D/deploy/env/as.env"
  chown root:root "$D/deploy/env/as.env"; chmod 600 "$D/deploy/env/as.env"
  chmod 600 "$D/backups/as.env.$STAMP"
  rm -f "$INCOMING_ENV"
  ok "as.env 새것으로 (옛것: backups/as.env.$STAMP, root 600)"
fi

grep -q "image: dss-as:1.4" "$D/deploy/docker-compose.nas.yml" && ok "compose 가 dss-as:1.4 를 가리킨다" || bad "compose 의 as 태그가 1.4 가 아니다"
grep -q "^QUOTE_ARCHIVE_UNC_ROOT=.*192\.168\.0\.222" "$D/deploy/env/as.env" \
  && ok "첫째 주소가 IP 다 (이름을 기다리지 않는다)" || bad "첫째 주소가 IP 가 아니다"
grep -q "^QUOTE_ARCHIVE_UNC_ROOT_ALT=.*DSS-NAS" "$D/deploy/env/as.env" \
  && ok "둘째 주소가 이름이다" || bad "둘째 주소가 이름이 아니다"
"${COMPOSE[@]}" config --quiet 2>/dev/null && ok "compose 문법 통과" || bad "compose 문법 오류"

[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. 아직 아무것도 바꾸지 않았습니다."

# ══ 2. 새 이미지의 도우미가 정말로 고쳐졌나 — 앱을 멈추기 전에 ═════════
#
# 🔴 1.3 을 그냥 믿고 올렸다가 「고쳤다」는 것이 사실이 아니었다. 이번에는 **NAS 에서**
#    직접 확인한다. 도우미 스크립트를 만들어(설치하지는 않는다) 그 안에 고친 자리가
#    들어 있는지 글자로 본다. 실제 동작은 Windows PC 에서만 볼 수 있다.
step "2. 새 이미지의 도우미가 고쳐졌는지 (설치하지 않는다)"
# 운영 이미지에는 tsx 가 없어 모듈을 직접 부를 수 없다. 도우미 본문은 앱이 요청마다
# 만들어 주므로, 여기서는 **고친 소스가 이미지에 구워졌는지**만 글자로 본다.
# 1.3 에는 없고 1.4 에만 있는 이름이라 둘을 실제로 가른다 (2026-09-16 개발 PC 확인).
if "$DOCKER" run --rm --entrypoint sh dss-as:1.4 -c 'grep -rq "Test-NoReparsePoint" /app/.next 2>/dev/null'; then
  ok "이미지 안에 고친 도우미가 들어 있다"
else
  bad "이미지 안에서 고친 자리를 찾지 못했다"
  stop "1.4 가 맞는 이미지인지 확인하세요. 앱은 아직 살아 있습니다."
fi

# ══ 3. A/S 만 다시 띄운다 ══════════════════════════════════════════════
step "3. A/S 만 다시 띄운다  ⏱ 여기부터 A/S 가 잠깐 멈춘다"
T0=$SECONDS
"${COMPOSE[@]}" up -d app-as 2>&1 | sed 's/^/  /'

wait_http() { # 이름 포트 경로
  local i code
  for i in $(seq 1 60); do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://127.0.0.1:$2$3" 2>/dev/null)
    case "$code" in 200|302|307) ok "$1 응답 $code ($((SECONDS - T0))초)"; return 0;; esac
    sleep 2
  done
  bad "$1 이 120초 안에 대답하지 않았다 (마지막 $code)"
  return 1
}
wait_http "A/S" 13000 /dashboard
wait_http "통합 로그인" 13100 /signin   # 건드리지 않았지만 같이 본다

# ══ 4. 공유폴더는 그대로 쓸 수 있나 ════════════════════════════════════
step "4. 견적서 공유폴더 쓰기 (새 이미지로)"
if "$DOCKER" run --rm --group-add 100 -v "$ARCHIVE_SRC:/quote-archive" dss-as:1.4 \
     sh -c 'set -e; t=/quote-archive/.dss-write-test; : > "$t"; rm -f "$t"' >/dev/null 2>&1; then
  ok "공유폴더에 쓸 수 있다"
else
  bad "공유폴더에 쓸 수 없다"
fi

# ══ 끝 ═════════════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL · A/S 가 멈춘 시간 약 $((SECONDS - T0))초"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" = 0 ]; then
  cat <<'ANNOUNCE'

🔴 이제 PC 에서 도우미를 **새로 설치**해야 합니다 — 주소와 스크립트는 설치할 때
   그 PC 에 박히므로, 서버만 고쳐서는 이미 깔린 도우미가 바뀌지 않습니다.

  1. https://as.dss21.co.kr 에서 견적서 하나를 열고 [폴더 열기] 를 누릅니다.
  2. 도우미가 없다고 나오면 안내대로 설치 파일(또는 붙여넣는 설치 명령)을
     **새로** 받아 실행합니다. 이미 깔려 있어도 다시 실행하면 덮어써서 고쳐집니다.
  3. 다시 [폴더 열기] — 이번에는 탐색기가 떠야 합니다.

  안 되면 그 PC 에서 이렇게 하면 무엇이 걸리는지 보입니다(창에 결과만 찍힙니다):
     $env:DSS_FOLDER_DRY_RUN = "1"
     & "$env:LOCALAPPDATA\DSS\open-dss-folder.ps1" "<[폴더 열기] 가 여는 dss-folder:// 주소>"
  OPEN <경로> 면 정상, NOT-FOUND 면 그 경로가 실제로 없는 것,
  REJECT <까닭> 이면 규칙에 걸린 것입니다. 그 한 줄을 Claude 에게 알려 주세요.
ANNOUNCE
else
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
fi
exit "$FAIL"
