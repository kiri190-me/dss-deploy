#!/bin/bash
# /volume1/dss/setup/07-deploy.sh — 2026-09-16 배포 (dss-auth 1.2 · dss-as 1.2 · 마이그레이션 셋)
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지 먼저!
#   (NAS)         bash /volume1/dss/setup/07-deploy.sh
#
# **앱이 멈춘다.** DB 는 내내 떠 있고 계측기도 건드리지 않는다. 멈추는 것은
# 통합 로그인과 A/S 둘, 약 5~10분이다(결정 E — 무중단으로 가지 않는다).
#
# ── 무엇이 바뀌나 ───────────────────────────────────────────────────────
#   통합 로그인  dss-auth:1.1 → 1.2   커밋 2   마이그레이션 없음
#   A/S          dss-as:1.1   → 1.2   커밋 41  마이그레이션 셋 (0098 · 0099 · 0100)
#   계측기       그대로 — 운영 이미지 내용물이 바뀌지 않았다
#
# ── 🔴 0100 은 더하기만이 아니다 ────────────────────────────────────────
# repair_labor_settings 의 기존 값을 계산해 investigation_hours 를 채운다 —
# **청구 금액에 닿는 값**이다. 조사작업 몫이 지금까지 「기본 작업비 − 통전 몫」이라는
# 나머지였던 것을 제 칸으로 옮기는 것이고, 마이그레이션이 숫자를 박지 않고 계산식으로
# 쓴다(NAS 값이 개발 PC 와 다를 수 있어서). 이 스크립트는 그 표를 **바꾸기 전과 뒤에
# 각각 찍어** 로그에 남긴다.
#
# 또 power_test_tasks.scope 가 NOT NULL·기본값 없음이라 **되돌리기가 「이미지 태그만」이
# 아니다** — 1.1 로 되돌리면 통전 건명 추가가 실패한다. 그래서 4단계의 덤프가
# 유일한 되돌리기 수단이다. 그 덤프를 뜨기 전에는 아무것도 바꾸지 않는다.
#
# ── 되돌리기 ────────────────────────────────────────────────────────────
#   bash /volume1/dss/setup/07-deploy.sh --rollback
# 4단계 덤프로 dss_as·dss_auth 를 되돌리고 이미지 태그를 1.1 로 내린다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
BK=$D/backups/pre-deploy-$STAMP
ARCHIVE_SRC="/volume1/3_견적-세금계산서-국내발주/4. DSS 내자견적서 (활용)"
MODE=${1:-}

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/07-deploy-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

PASS=0; FAIL=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

COMPOSE=("$DOCKER" compose -f "$D/deploy/docker-compose.nas.yml" --env-file "$D/deploy/.env.nas" --profile tools)
q()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d dss_as -Atc \"$1\"" 2>/dev/null; }
qq() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d dss_as -c \"$1\"" 2>/dev/null; }

# ══ 되돌리기 ═══════════════════════════════════════════════════════════
if [ "$MODE" = "--rollback" ]; then
  LAST=$(ls -1dt "$D"/backups/pre-deploy-* 2>/dev/null | head -1)
  [ -n "$LAST" ] || stop "되돌릴 덤프가 없습니다."
  echo "되돌립니다 — $LAST"
  echo "⚠️ 그 덤프를 뜬 뒤에 들어온 자료는 사라집니다. 계속하려면 20초 안에 Ctrl+C 를 누르지 마세요."
  sleep 20
  "${COMPOSE[@]}" stop app-as app-auth
  for pair in "dss_as:$LAST/dss_as.dump" "dss_auth:$LAST/dss_auth.dump"; do
    db=${pair%%:*}; f=${pair#*:}
    [ -s "$f" ] || { bad "$f 가 없다"; continue; }
    box=dss-pg-app; [ "$db" = dss_auth ] && box=dss-pg-auth
    "$DOCKER" exec -i "$box" sh -c "pg_restore -U \"\$POSTGRES_USER\" -d $db --clean --if-exists --no-owner" < "$f" \
      && ok "$db 되돌림" || bad "$db 되돌리기 실패"
  done
  echo
  echo "compose 의 이미지 태그를 1.1 로 내린 뒤 up -d 하세요:"
  echo "  sed -i 's/dss-auth:1.2/dss-auth:1.1/; s/dss-as:1.2/dss-as:1.1/' $D/deploy/docker-compose.nas.yml"
  echo "  $DOCKER compose -f $D/deploy/docker-compose.nas.yml --env-file $D/deploy/.env.nas up -d"
  exit "$FAIL"
fi

echo "DSS 배포 · $(date '+%F %T')"
echo "  dss-auth 1.1 → 1.2 · dss-as 1.1 → 1.2 · 마이그레이션 0098·0099·0100"

# ══ 1. 먼저 볼 것 — 여기서는 아무것도 바꾸지 않는다 ════════════════════
step "1. 먼저 볼 것 (아무것도 바꾸지 않는다)"

for img in dss-auth:1.2 dss-as:1.2 dss-as-tools:1; do
  if "$DOCKER" image inspect "$img" >/dev/null 2>&1; then
    ok "$img ($("$DOCKER" image inspect "$img" --format '{{.Id}}' | cut -c1-19)…)"
  else
    bad "$img 가 없다"
  fi
done
[ "$FAIL" = 0 ] || stop "먼저 images/ 의 tar 를 docker load 하세요."

# compose 교체 — 파일만 바뀌고 도는 컨테이너는 그대로다.
INCOMING=$D/setup/incoming/docker-compose.nas.yml
if [ -s "$INCOMING" ] && ! cmp -s "$INCOMING" "$D/deploy/docker-compose.nas.yml"; then
  mkdir -p "$D/backups"
  cp -p "$D/deploy/docker-compose.nas.yml" "$D/backups/docker-compose.nas.yml.$STAMP"
  cp "$INCOMING" "$D/deploy/docker-compose.nas.yml"
  chown root:root "$D/deploy/docker-compose.nas.yml"; chmod 644 "$D/deploy/docker-compose.nas.yml"
  rm -f "$INCOMING"
  ok "compose 새것으로 (옛것: backups/docker-compose.nas.yml.$STAMP)"
fi

# as.env 교체 — 견적서 공유폴더 두 줄이 더해진 것.
INCOMING_ENV=$D/setup/incoming/as.env
if [ -s "$INCOMING_ENV" ] && ! cmp -s "$INCOMING_ENV" "$D/deploy/env/as.env"; then
  cp -p "$D/deploy/env/as.env" "$D/backups/as.env.$STAMP"
  cp "$INCOMING_ENV" "$D/deploy/env/as.env"
  chown root:root "$D/deploy/env/as.env"; chmod 600 "$D/deploy/env/as.env"
  rm -f "$INCOMING_ENV"
  chmod 600 "$D/backups/as.env.$STAMP"
  ok "as.env 새것으로 (옛것: backups/as.env.$STAMP, root 600)"
fi

grep -q "^  tools-as:" "$D/deploy/docker-compose.nas.yml" && ok "compose 에 tools-as 가 있다" || bad "compose 에 tools-as 가 없다"
grep -q "^QUOTE_ARCHIVE_DIR=" "$D/deploy/env/as.env" && ok "as.env 에 QUOTE_ARCHIVE_DIR 이 있다" || bad "as.env 에 QUOTE_ARCHIVE_DIR 이 없다"
"${COMPOSE[@]}" config --quiet 2>/dev/null && ok "compose 문법 통과" || bad "compose 문법 오류"

# 마이그레이션 볼륨 — setup/incoming 의 tar 를 풀어 둔다.
TARBALL=$D/setup/incoming/as-migrations.tar.gz
if [ -s "$TARBALL" ]; then
  rm -rf "$D/as-migrations.new"; mkdir -p "$D/as-migrations.new"
  tar -xzf "$TARBALL" -C "$D/as-migrations.new" --strip-components=1 \
    && { rm -rf "$D/as-migrations.old"; [ -d "$D/as-migrations" ] && mv "$D/as-migrations" "$D/as-migrations.old"; mv "$D/as-migrations.new" "$D/as-migrations"; rm -f "$TARBALL"; ok "as-migrations 새것으로"; } \
    || bad "as-migrations 풀기 실패"
  chown -R root:root "$D/as-migrations"; chmod -R a+rX "$D/as-migrations"
fi
N_SQL=$(ls -1 "$D/as-migrations"/*.sql 2>/dev/null | wc -l)
[ "$N_SQL" = 101 ] && ok "마이그레이션 파일 101건" || bad "마이그레이션 파일이 101건이 아니다 ($N_SQL)"

if "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-app && "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-auth; then
  ok "DB 둘 다 떠 있다"
else
  bad "DB 가 떠 있지 않다"
fi

[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. 아직 아무것도 바꾸지 않았습니다."

# ══ 2. 견적서 공유폴더에 쓸 수 있나 — 앱을 멈추기 전에 본다 ════════════
#
# 🔴 여기는 /volume1/dss 가 아니라 **직원이 20년째 탐색기로 쓰는 서류함**이다.
#    ACL 을 걷지 않는다 — 걷으면 직원의 접근이 끊긴다. 컨테이너(uid 1000)가
#    쓸 수 있는지만 실제로 해 보고, 안 되면 배포를 멈춘다(앱은 아직 살아 있다).
step "2. 견적서 공유폴더 쓰기 시험 (컨테이너 uid 1000)"
[ -d "$ARCHIVE_SRC" ] && ok "폴더가 있다" || { bad "폴더가 없다: $ARCHIVE_SRC"; stop "경로를 확인하세요."; }

YEAR_DIR=$(ls -1d "$ARCHIVE_SRC"/*"$(date +%Y)"* 2>/dev/null | head -1)
[ -n "$YEAR_DIR" ] && ok "올해 연도 폴더: $(basename "$YEAR_DIR")" || bad "올해 연도 폴더를 못 찾았다 (앱이 만들려 시도한다)"

# compose 의 app-as 와 **같은 조건**으로 시험해야 뜻이 있다 — gid 100(users)을 곁들인다.
# 그것 없이는 Permission denied 다(2026-09-16 실측, 07a). 컨테이너의 node 는 DSM
# 사용자가 아니라 이 폴더의 ACL 목록에 없고, 목록의 group:users 에만 걸린다.
GA=(--group-add 100)
grep -q 'group_add: \["100"\]' "$D/deploy/docker-compose.nas.yml" \
  && ok "compose 의 app-as 에 group_add 100 이 있다" \
  || { bad "compose 에 group_add 100 이 없다 — 시험만 통과하고 앱은 못 쓴다"; stop "새 compose 가 올라왔는지 보세요."; }

if "$DOCKER" run --rm "${GA[@]}" -v "$ARCHIVE_SRC:/quote-archive" dss-as:1.2 \
     sh -c 'set -e; t=/quote-archive/.dss-write-test; : > "$t"; rm -f "$t"; d=/quote-archive/.dss-dir-test; mkdir "$d"; rmdir "$d"' >/dev/null 2>&1; then
  ok "루트에 파일·폴더를 만들고 지울 수 있다"
else
  bad "루트에 쓸 수 없다"
  echo "    → as.env 의 QUOTE_ARCHIVE_DIR·QUOTE_ARCHIVE_UNC_ROOT 두 줄을 지우면"
  echo "      공유폴더 저장만 꺼진 채 나머지는 그대로 배포할 수 있습니다."
  stop "앱은 아직 살아 있습니다. 아무것도 멈추지 않았습니다."
fi

if [ -n "$YEAR_DIR" ]; then
  "$DOCKER" run --rm "${GA[@]}" -v "$YEAR_DIR:/y" dss-as:1.2 sh -c 'set -e; t=/y/.dss-write-test; : > "$t"; rm -f "$t"' >/dev/null 2>&1 \
    && ok "올해 폴더 안에도 쓸 수 있다" || bad "올해 폴더 안에 쓸 수 없다"
fi

# 🔴 앱이 저장한 파일을 **직원이 열 수 있어야** 뜻이 있다. 만든 파일의 POSIX 모드는
#    000 이고(주인이 DSM 사용자가 아니다) 접근은 물려받은 ACL 이 정한다. allow 가
#    하나도 안 물려오면 직원 눈에 「열리지 않는 파일」만 쌓인다 — 없느니만 못하다.
T="$ARCHIVE_SRC/.dss-inherit-test"
"$DOCKER" run --rm "${GA[@]}" -v "$ARCHIVE_SRC:/quote-archive" dss-as:1.2 \
  sh -c ': > /quote-archive/.dss-inherit-test' >/dev/null 2>&1
if [ -e "$T" ]; then
  ALLOW=$(synoacltool -get "$T" 2>/dev/null | grep -c ":allow:")
  USERS_OK=$(synoacltool -get "$T" 2>/dev/null | grep -c "group:users:allow\|group:administrators:allow")
  rm -f "$T"
  if [ "${ALLOW:-0}" -gt 0 ] && [ "${USERS_OK:-0}" -gt 0 ]; then
    ok "새 파일이 ACL 을 물려받는다 (allow ${ALLOW}줄 · users/administrators 포함) — 직원이 연다"
  else
    bad "새 파일에 allow 가 물려오지 않는다 (allow ${ALLOW:-0}줄)"
    echo "    → 앱이 저장해도 직원이 못 여는 파일이 쌓인다. 공유폴더 저장은 빼는 것이 낫다:"
    echo "      as.env 의 QUOTE_ARCHIVE_ 두 줄을 지우고 다시 돌리세요."
    stop "앱은 아직 살아 있습니다."
  fi
else
  bad "시험 파일을 만들지 못했다"
fi

[ "$FAIL" = 0 ] || stop "앱은 아직 살아 있습니다."

# ══ 3. 지금 값 — 바꾸기 전에 찍어 둔다 ═════════════════════════════════
step "3. 바꾸기 전 — 0100 이 건드릴 표"
qq "select id, base_cost, hourly_rate, power_test_hours, investigation_hours from repair_labor_settings order by id"
echo "  (investigation_hours 칸이 아직 없다고 나오는 것이 정상 — 0100 이 만든다)"

# ══ 4. 앱을 멈추고 덤프 — 여기부터 중단이다 ════════════════════════════
step "4. 앱 정지 → 최종 덤프  ⏱ 여기부터 직원이 못 쓴다"
T0=$SECONDS
"${COMPOSE[@]}" stop app-as app-auth && ok "app-as · app-auth 정지 (DB·계측기는 그대로)" || bad "정지 실패"

mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
dump() { # DB 컨테이너 파일
  "$DOCKER" exec "$2" sh -c "pg_dump -U \"\$POSTGRES_USER\" -d $1 -Fc" > "$3.part" 2>/dev/null \
    && "$DOCKER" exec -i "$2" pg_restore -l < "$3.part" >/dev/null 2>&1 \
    && mv "$3.part" "$3" && ok "$1 덤프 $(du -h "$3" | cut -f1)" \
    || { rm -f "$3.part"; bad "$1 덤프 실패"; }
}
dump dss_as   dss-pg-app  "$BK/dss_as.dump"
dump dss_auth dss-pg-auth "$BK/dss_auth.dump"
[ "$FAIL" = 0 ] || stop "덤프가 없으면 되돌릴 수 없습니다. 앱을 다시 띄우세요: ${COMPOSE[*]} up -d"

# ══ 5. 마이그레이션 ════════════════════════════════════════════════════
step "5. 마이그레이션 — 적용 전 확인"
"${COMPOSE[@]}" run --rm tools-as npm run db:preflight 2>&1 | sed 's/^/  /'
echo
step "5. 마이그레이션 적용"
"${COMPOSE[@]}" run --rm tools-as npm run db:migrate 2>&1 | sed 's/^/  /'
rc=${PIPESTATUS[0]}
[ "$rc" = 0 ] && ok "적용 끝" || { bad "적용 실패 (종료 코드 $rc)"; stop "되돌리려면: bash $0 --rollback"; }

"${COMPOSE[@]}" run --rm tools-as npm run db:preflight 2>&1 | sed 's/^/  /'
left=$(q "select count(*) from __drizzle_migrations" 2>/dev/null)
echo "  DB 의 마이그레이션 기록: ${left:-?}건"

# ══ 6. 0100 이 옮긴 값 ═════════════════════════════════════════════════
step "6. 바꾼 뒤 — 0100 이 채운 값 (3 의 표와 대조)"
qq "select id, base_cost, hourly_rate, power_test_hours, investigation_hours, document_hours from repair_labor_settings order by id"
echo "  investigation_hours 가 NULL 인 줄은 계산이 서지 않아 사람이 화면에서 채울 자리다."
echo "  document_hours 는 전부 NULL 이 정상이다 — 새 개념이라 옮길 값이 없다."

# ══ 7. 새 이미지로 띄운다 ══════════════════════════════════════════════
step "7. 새 이미지로 기동"
"${COMPOSE[@]}" up -d app-auth app-as 2>&1 | sed 's/^/  /'
for i in $(seq 1 30); do
  up=$("$DOCKER" ps --format '{{.Names}}' | grep -cE '^dss-(auth|as)$')
  [ "$up" = 2 ] && break
  sleep 2
done
[ "${up:-0}" = 2 ] && ok "둘 다 떴다 ($((SECONDS - T0))초)" || bad "뜨지 않았다"

for pair in "통합 로그인:13100:/signin" "A/S:13000:/dashboard"; do
  name=${pair%%:*}; rest=${pair#*:}; port=${rest%%:*}; path=${rest#*:}
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "http://127.0.0.1:$port$path")
  case "$code" in 200|307|302) ok "$name 응답 $code";; *) bad "$name 응답 $code";; esac
done

iss=$(curl -s -m 10 http://127.0.0.1:13100/.well-known/openid-configuration | grep -o '"issuer":"[^"]*"' | cut -d'"' -f4)
[ "$iss" = "https://login.dss21.co.kr" ] && ok "포털 iss $iss" || bad "포털 iss 가 $iss"

ver=$(curl -s -m 10 http://127.0.0.1:13100/signin | grep -o 'v1\.[0-9]*' | head -1)
[ -n "$ver" ] && ok "로그인 화면에 보이는 번호 $ver (1.2 여야 한다)" || bad "화면에서 번호를 못 찾았다"

# ══ 끝 ═════════════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL · 앱이 멈춘 시간 약 $((SECONDS - T0))초"
echo "  덤프: $BK"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" = 0 ]; then
  cat <<'ANNOUNCE'

브라우저로 확인해 주세요 (사내망 · DSSTECH5):
  1. https://login.dss21.co.kr  로그인 → 아래 "v1.2 · 업데이트 소식" 이 보이는지
  2. https://as.dss21.co.kr     A/S 로 넘어가지는지
  3. A/S 견적서 한 건을 열어 [폴더 열기] · [견적서 받기] 가 뜨는지
  4. https://meters.dss21.co.kr 계측기도 그대로인지 (건드리지 않았지만 확인)

되돌리려면:  bash /volume1/dss/setup/07-deploy.sh --rollback
ANNOUNCE
else
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
  echo "되돌리기: bash $0 --rollback"
fi
exit "$FAIL"
