#!/bin/bash
# /volume1/dss/setup/08-deploy.sh — 2026-09-16 두 번째 배포 (dss-auth 1.3 · dss-as 1.3)
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지 먼저!
#   (NAS)         bash /volume1/dss/setup/08-deploy.sh
#
# **앱이 잠깐 멈춘다.** DB 도 계측기도 건드리지 않는다. 멈추는 것은 통합 로그인과
# A/S 둘이고, 07 때는 대답할 때까지 1분이 채 안 걸렸다.
#
# ── 무엇이 바뀌나 ───────────────────────────────────────────────────────
#   통합 로그인  dss-auth:1.2 → 1.3
#     업데이트 소식 화면이 **세 시스템 소식을 함께** 싣는다. 항목마다 어느 시스템인지
#     붙는다. 마이그레이션 없음.
#
#   A/S          dss-as:1.2 → 1.3
#     [폴더 열기] 도우미가 공유폴더 주소를 **둘 차례로** 열어 본다 — 이름(\\DSS-NAS\…)이
#     안 풀리는 PC 에서도 IP(\\192.168.0.222\…)로 열린다. 마이그레이션 없음.
#     as.env 에 QUOTE_ARCHIVE_UNC_ROOT_ALT 한 줄이 는다.
#
#   계측기       그대로. 업데이트 소식에 글만 실린다(앱은 1.1 그대로).
#
# ── 되돌리기 ────────────────────────────────────────────────────────────
# 이번엔 스키마가 바뀌지 않아 **이미지 태그만 내리면 된다**:
#   sed -i 's/dss-auth:1.3/dss-auth:1.2/; s/dss-as:1.3/dss-as:1.2/' /volume1/dss/deploy/docker-compose.nas.yml
#   /usr/local/bin/docker compose -f /volume1/dss/deploy/docker-compose.nas.yml \
#     --env-file /volume1/dss/deploy/.env.nas up -d app-auth app-as
# as.env 옛 사본은 backups/as.env.<시각> 에 남는다. 덤프도 뜨지만(4단계) 이번엔
# 되돌리기에 쓸 일이 없다 — 그래도 뜬다. 2초면 되고, 없을 때 후회하는 쪽이 크다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
BK=$D/backups/pre-deploy-$STAMP
ARCHIVE_SRC="/volume1/3_견적-세금계산서-국내발주/4. DSS 내자견적서 (활용)"

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/08-deploy-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

PASS=0; FAIL=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

COMPOSE=("$DOCKER" compose -f "$D/deploy/docker-compose.nas.yml" --env-file "$D/deploy/.env.nas" --profile tools)

echo "DSS 배포 · $(date '+%F %T')"
echo "  dss-auth 1.2 → 1.3 · dss-as 1.2 → 1.3 · 마이그레이션 없음"

# ══ 1. 먼저 볼 것 — 여기서는 아무것도 바꾸지 않는다 ════════════════════
step "1. 먼저 볼 것"

for img in dss-auth:1.3 dss-as:1.3; do
  if "$DOCKER" image inspect "$img" >/dev/null 2>&1; then
    ok "$img ($("$DOCKER" image inspect "$img" --format '{{.Id}}' | cut -c1-19)…)"
  else
    bad "$img 가 없다"
  fi
done
[ "$FAIL" = 0 ] || stop "먼저 images/ 의 tar 를 docker load 하세요."

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

grep -q "image: dss-auth:1.3" "$D/deploy/docker-compose.nas.yml" && ok "compose 가 dss-auth:1.3 을 가리킨다" || bad "compose 의 auth 태그가 1.3 이 아니다"
grep -q "image: dss-as:1.3" "$D/deploy/docker-compose.nas.yml" && ok "compose 가 dss-as:1.3 을 가리킨다" || bad "compose 의 as 태그가 1.3 이 아니다"
grep -q "^QUOTE_ARCHIVE_UNC_ROOT_ALT=" "$D/deploy/env/as.env" && ok "as.env 에 둘째 공유폴더 주소가 있다" || bad "as.env 에 QUOTE_ARCHIVE_UNC_ROOT_ALT 가 없다"
"${COMPOSE[@]}" config --quiet 2>/dev/null && ok "compose 문법 통과" || bad "compose 문법 오류"

[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. 아직 아무것도 바꾸지 않았습니다."

# ══ 2. 공유폴더는 여전히 쓸 수 있나 ════════════════════════════════════
#
# 07 에서 한 번 통과했지만 다시 본다 — compose 를 갈아 끼웠으니 group_add 가
# 빠졌을 수도 있다. 앱을 멈추기 전에 본다.
step "2. 견적서 공유폴더 쓰기 시험 (앱을 멈추기 전)"
grep -q 'group_add: \["100"\]' "$D/deploy/docker-compose.nas.yml" \
  && ok "compose 의 app-as 에 group_add 100 이 있다" \
  || { bad "compose 에 group_add 100 이 없다"; stop "새 compose 를 확인하세요."; }

if "$DOCKER" run --rm --group-add 100 -v "$ARCHIVE_SRC:/quote-archive" dss-as:1.3 \
     sh -c 'set -e; t=/quote-archive/.dss-write-test; : > "$t"; rm -f "$t"' >/dev/null 2>&1; then
  ok "새 이미지(1.3)로도 공유폴더에 쓸 수 있다"
else
  bad "공유폴더에 쓸 수 없다"
  stop "앱은 아직 살아 있습니다."
fi

# ══ 3. 앱 정지 → 덤프 ══════════════════════════════════════════════════
step "3. 앱 정지 → 덤프  ⏱ 여기부터 직원이 못 쓴다"
T0=$SECONDS
"${COMPOSE[@]}" stop app-as app-auth && ok "app-as · app-auth 정지" || bad "정지 실패"

mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
dump() {
  "$DOCKER" exec "$2" sh -c "pg_dump -U \"\$POSTGRES_USER\" -d $1 -Fc" > "$3.part" 2>/dev/null \
    && "$DOCKER" exec -i "$2" pg_restore -l < "$3.part" >/dev/null 2>&1 \
    && mv "$3.part" "$3" && ok "$1 덤프 $(du -h "$3" | cut -f1)" \
    || { rm -f "$3.part"; bad "$1 덤프 실패"; }
}
dump dss_as   dss-pg-app  "$BK/dss_as.dump"
dump dss_auth dss-pg-auth "$BK/dss_auth.dump"

# ══ 4. 새 이미지로 기동 ════════════════════════════════════════════════
step "4. 새 이미지로 기동"
"${COMPOSE[@]}" up -d app-auth app-as 2>&1 | sed 's/^/  /'

# 컨테이너가 보이는 것과 앱이 대답하는 것은 다르다 — 대답할 때까지 기다린다(07 에서 걸렸다).
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
wait_http "통합 로그인" 13100 /signin
wait_http "A/S" 13000 /dashboard

# ══ 5. 이번 배포가 실제로 바꾼 것 ══════════════════════════════════════
step "5. 이번에 바뀐 것이 화면에 있나"

# 307 이라 따라가야(-L) 본문이 나오고, React 가 글자를 쪼개므로 주석을 걷는다.
ver=$(curl -sL -m 15 http://127.0.0.1:13100/signin | sed 's/<!--[^>]*-->//g' | grep -oE 'v[0-9]+\.[0-9]+' | head -1)
[ "$ver" = "v1.3" ] && ok "로그인 화면의 번호 $ver" || bad "화면의 번호가 '$ver' (v1.3 이어야 한다)"

notes=$(curl -sL -m 15 http://127.0.0.1:13100/release-notes | sed 's/<!--[^>]*-->//g')
for name in "통합 로그인" "A/S 관리" "계측기 관리"; do
  echo "$notes" | grep -q "$name" && ok "업데이트 소식에 「$name」이 있다" || bad "업데이트 소식에 「$name」이 없다"
done

iss=$(curl -s -m 10 http://127.0.0.1:13100/.well-known/openid-configuration | grep -o '"issuer":"[^"]*"' | cut -d'"' -f4)
[ "$iss" = "https://login.dss21.co.kr" ] && ok "포털 iss $iss" || bad "포털 iss 가 $iss"

# 도우미가 두 주소를 담는지는 로그인한 사람만 받을 수 있어 여기서 못 본다 —
# 사람이 브라우저에서 설치 파일을 새로 받아 확인한다(아래 안내).

# ══ 끝 ═════════════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL · 앱이 멈춘 시간 약 $((SECONDS - T0))초"
echo "  덤프: $BK"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" = 0 ]; then
  cat <<'ANNOUNCE'

브라우저로 확인해 주세요 (사내망):
  1. https://login.dss21.co.kr — 아래가 "v1.3 · 업데이트 소식" 인지, 눌러서
     [통합 로그인] [A/S 관리] [계측기 관리] 세 갈래가 다 보이는지
  2. https://as.dss21.co.kr — 견적서 편집 화면에서 **[폴더 열기] 도우미를 새로 받아
     다시 설치**해 주세요. 옛 도우미에는 주소가 하나만 들어 있습니다.
  3. 설치 뒤 [폴더 열기] 가 열리는지 — 이름이 안 풀리던 PC 에서도 열려야 합니다.

되돌리기(이미지 태그만):
  sed -i 's/dss-auth:1.3/dss-auth:1.2/; s/dss-as:1.3/dss-as:1.2/' /volume1/dss/deploy/docker-compose.nas.yml
  /usr/local/bin/docker compose -f /volume1/dss/deploy/docker-compose.nas.yml --env-file /volume1/dss/deploy/.env.nas up -d app-auth app-as
ANNOUNCE
else
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
fi
exit "$FAIL"
