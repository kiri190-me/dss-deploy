#!/bin/bash
# /volume1/dss/setup/31-survey.sh — 서른한째 배포 준비: 운영 현황 재기 (2026-10-22)
#
# 🔵 **읽기만 한다.** select 와 ls 와 docker ps/images/exec 뿐이다.
#    docker run · up · restart · rm 이 한 줄도 없고 UPDATE · DELETE 도 없다.
#    컨테이너를 하나도 멈추지 않는다. 몇 번을 돌려도 안전하다.
#
# ── 🔴 올리는 법 — DSM 터미널은 긴 명령을 잘라 먹는다 ──────────────────
#   하루에 네 번 깨진 적이 있다. 그래서 **손으로 치지 않고 파일로 올려** 돌린다.
#
#   (개발 PC · PowerShell)
#     cd C:\Users\희만\Desktop\Development
#     scp -O dss-deploy\nas\setup\31-survey.sh dss-nas:/volume1/dss/setup/
#     Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\31-survey.sh
#
#   (NAS · bash · sudo -i 뒤)
#     md5sum /volume1/dss/setup/31-survey.sh
#     🔴 위 Get-FileHash 와 **같은 글자**일 때만 돌린다. 다르면 다시 올린다.
#        (이 스크립트도 시작할 때 제 md5 를 찍는다 — 눈으로 한 번 더 맞춘다.)
#     bash /volume1/dss/setup/31-survey.sh
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. ✗ 든 ? 든 하나라도 있으면 **종료 코드 1** 이다.
#
#   🔴 **처음 돌리면 ? 가 둘 나오는 것이 정상이다** — 도구 이미지 안의 .sql 수다.
#      그 안을 보려면 docker run --rm 이 필요한데 이 설문은 그것을 쓰지 않는다.
#      끝에 그 명령을 **찍어 준다** — 사람이 따로 치면 그 둘도 메워진다.
#
# ── 🔴 비밀값을 찍지 않는다 ────────────────────────────────────────────
#   .env 는 **이름이 있는가/없는가**만 본다. 값도, 값의 길이도 찍지 않는다
#   (30번은 길이를 찍었다 — 짧은 값은 길이만으로도 범위가 좁아진다).
#
# ══ 🔴 이번 배포가 지난 것들과 다른 점 — 그래서 무엇을 재는가 ═══════════
#
#   ① **덩어리가 역대 최대다.** 지금까지 한 번에 올린 것이 많아야 둘인데
#      이번은 **여덟**(포털 · A/S · PO · 재고 · 게시판 · 휴가 · 계측기 ·
#      개선요청)이고, 그 위에 **아홉째 사이트(RF 이슈관리)를 새로 세우는 일**이
#      따로 있다. → 1절(도는 판) · 6절(자리) 을 먼저 본다.
#
#   ② 🔴 **포털(dss_auth)에 마이그레이션이 처음으로 생겼다** — 0005·0006·0007.
#      그런데 **포털에는 도구 이미지도 도구 서비스도 없다**(compose 에 tools-auth
#      가 없다. 24-deploy.sh 86~91줄이 실측으로 적어 둔 것이다). 지금까지 포털
#      배포는 **전부 마이그레이션 0건**이었다. → **돌릴 길이 아예 없다.**
#      4절이 그것을 값으로 확인한다. 길을 정하는 것은 사람이다.
#
#   ③ 🔴 **적용을 돌리는 쪽은 시스템마다 다르다** (30번의 교훈 ①).
#        A/S      → **볼륨** /volume1/dss/as-migrations 를 tools-as 가 :ro 로 읽는다
#        재고     → **도구 이미지 안**(dss-inventory-tools)에 구워져 있다
#        포털     → **없다**(위 ②)
#      볼륨만 보고 끝내면 「올리는 것을 깜빡했다」와 「원래 올릴 것이 없다」를
#      가르지 못한다. 그래서 3절이 **값 넷**을 다 센다.
#
# ── 이번에 알아야 하는 것 아홉 ─────────────────────────────────────────
#   1 지금 도는 컨테이너와 이미지 태그 (= 지금 선 판)
#   2 운영 compose 가 말하는 태그 (1 과 어긋나면 누가 손으로 바꾼 것이다)
#   3 🔴 마이그레이션 **값 넷** — 운영 DB · 볼륨 .sql · 볼륨 _journal · 이미지 안
#   4 🔴 포털 마이그레이션을 **돌릴 길이 있는가**
#   5 DB 의 핵심 표 행 수 (배포 뒤 비교용)
#   6 디스크 여유 · 메모리 (이미지 여덟을 올리면 자리가 모자랄 수 있다)
#   7 설정 파일에 이번에 필요한 **이름**이 있는가 (🔴 값은 안 찍는다)
#   8 포털 clients — 아홉째(RF 이슈관리) 자리가 비어 있는가
#   9 되돌릴 이미지가 남아 있는가 · 야간 백업이 돌았는가
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail

DOCKER=/usr/local/bin/docker
D=/volume1/dss
CF=$D/deploy/docker-compose.nas.yml
ENVD=$D/deploy/env
IMAGES=$D/images
BKDB=$D/backups/db
MIGDIR_AS=$D/as-migrations

PASS=0; FAIL=0; UNK=0

line() { printf '%s\n' "────────────────────────────────────────────────────────────"; }
sec()  { printf '\n== %s\n' "$1"; }
say()  { printf '%s\n' "    $1"; }
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
unk()  { UNK=$((UNK+1));  printf '  ? %s — 못 쟀다 (%s)\n' "$1" "$2"; }

# 숫자인가. 🔴 psql 이 오류 글자를 돌려줬는데 0 으로 읽으면 가장 나쁜 쪽으로 틀린다.
isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }

# psql — 🔴 읽기 전용 select 만 넘긴다. SQL 안에 큰따옴표를 쓰지 않는다.
qdb() { "$DOCKER" exec "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -Atc \"$3\"" 2>&1; }

# 한 줄짜리 수를 받아 온다. 못 받으면 빈 글자.
qnum() {
  local v
  v=$(qdb "$1" "$2" "$3" | head -1 | tr -d ' \r')
  isnum "$v" && printf '%s' "$v"
}

printf '31-survey — 서른한째 배포 준비 · 운영 현황   %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
printf '이 파일의 md5: %s\n' "$(md5sum "$0" 2>/dev/null | cut -d' ' -f1)"
say '🔴 개발 PC 의 Get-FileHash 와 같은 글자인지 먼저 맞춰 보세요.'
line

# ── 1 ─────────────────────────────────────────────────────────────────
sec "1. 지금 도는 컨테이너와 이미지 태그 (= 지금 선 판)"
printf '%s\n' "🔵 여덟 사이트 + DB 둘 + (도구는 평소에 안 돈다)."
if "$DOCKER" ps --format '{{.Names}}|{{.Image}}|{{.Status}}' >/dev/null 2>&1; then
  "$DOCKER" ps --format '{{.Names}}|{{.Image}}|{{.Status}}' 2>/dev/null \
    | sort | awk -F'|' '{printf "    %-18s %-28s %s\n", $1, $2, $3}'
  N_RUN=$("$DOCKER" ps -q 2>/dev/null | wc -l | tr -d ' ')
  if isnum "$N_RUN" && [ "$N_RUN" -ge 10 ]; then
    ok "도는 컨테이너 $N_RUN 개 (사이트 여덟 + DB 둘 이상)"
  else
    bad "도는 컨테이너가 $N_RUN 개뿐이다 — 멈춘 것이 있다. 배포 전에 까닭을 보세요"
  fi
else
  unk "도는 컨테이너 목록" "docker ps 가 안 된다 (sudo -i 로 돌렸습니까)"
fi
printf '%s\n' "  ── 🔴 지금 선 판이 지난 배포(30번)가 남긴 그대로인가"
say '기대: dss-auth 1.7 · dss-as 2.8 · dss-po 0.6 · dss-meters 1.3'
say '      dss-improvements 0.3 · dss-leave 0.2 · dss-board 0.2 · dss-inventory 0.2'
say '🔴 하나라도 다르면 그 사이 다른 세션이 올린 것이다 — 기준 SHA 가 틀렸다는 뜻이고'
say '   배포 범위를 다시 세야 한다. 지어내지 말고 멈추세요.'

# ── 2 ─────────────────────────────────────────────────────────────────
sec "2. 운영 compose 가 말하는 태그"
printf '%s\n' "🔵 1절과 어긋나면 누가 compose 를 고치고 아직 안 올렸거나, 손으로 띄운 것이다."
if [ -f "$CF" ]; then
  grep -nE '^[[:space:]]*image:[[:space:]]*dss-' "$CF" | sed 's/^/    /'
  N_IMGLINE=$(grep -cE '^[[:space:]]*image:[[:space:]]*dss-' "$CF")
  if isnum "$N_IMGLINE" && [ "$N_IMGLINE" -ge 8 ]; then
    ok "compose 에 dss-* image 줄이 $N_IMGLINE 개 있다"
  else
    bad "compose 의 dss-* image 줄이 $N_IMGLINE 개다 — 블록이 주석에 묻혀 있는지 보세요"
  fi
else
  unk "운영 compose" "$CF 가 없다"
fi

# ── 3 🔴 가장 중요 ────────────────────────────────────────────────────
sec "3. 🔴 마이그레이션 — 값 **넷**을 다 센다 (30번의 교훈 ①)"
printf '%s\n' "🔴 적용을 **돌리는** 쪽이 시스템마다 다르다. 하나만 보면 조용히 0건으로 끝난다."

# 3-ㄱ ── A/S : 볼륨에서 돈다
printf '\n%s\n' "  ── 3-ㄱ. A/S (dss_as) — 🔴 **볼륨**에서 돈다"
say '기대: 지금 118 · 0118 하나를 올리면 119'
V=$(qnum dss-pg-app dss_as 'select count(*) from drizzle.__drizzle_migrations;')
if [ -n "$V" ]; then
  if [ "$V" = "118" ]; then ok "① 운영 DB 적용 수 = $V"
  else bad "① 운영 DB 적용 수 = $V (118 을 기대했다 — 범위를 다시 세세요)"; fi
else
  unk "① 운영 DB(dss_as) 적용 수" "psql 이 수를 안 돌려줬다"
fi
if [ -d "$MIGDIR_AS" ]; then
  N_SQL=$(ls -1 "$MIGDIR_AS"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  if isnum "$N_SQL" && [ "$N_SQL" = "118" ]; then ok "② 볼륨 $MIGDIR_AS 의 .sql = $N_SQL"
  else bad "② 볼륨의 .sql = ${N_SQL:-?} (118 을 기대했다)"; fi
  if [ -f "$MIGDIR_AS/meta/_journal.json" ]; then
    N_J=$(grep -c '"tag"' "$MIGDIR_AS/meta/_journal.json" 2>/dev/null | tr -d ' ')
    if isnum "$N_J" && [ "$N_J" = "118" ]; then ok "③ 볼륨 _journal.json 의 tag = $N_J"
    else bad "③ 볼륨 _journal.json 의 tag = ${N_J:-?} (118 을 기대했다)"; fi
    say '🔴 _journal 이 옛것이면 drizzle 은 새 .sql 을 **아예 모른다** — 0건으로 조용히 끝난다.'
  else
    unk "③ 볼륨 _journal.json" "$MIGDIR_AS/meta/_journal.json 이 없다"
  fi
else
  unk "② ③ 볼륨 $MIGDIR_AS" "폴더가 없다"
fi
V=$("$DOCKER" exec dss-as sh -c 'ls /app/drizzle/*.sql 2>/dev/null | wc -l' 2>/dev/null | tr -d ' \r')
if isnum "$V" && [ "$V" -gt 0 ]; then
  if [ "$V" = "118" ]; then ok "④ 도는 dss-as 이미지 안 /app/drizzle 의 .sql = $V"
  else bad "④ 도는 dss-as 이미지 안의 .sql = $V (118 을 기대했다)"; fi
else
  unk "④ 도는 dss-as 이미지 안의 .sql" "컨테이너 안을 못 읽었다 — 0 을 통과로 읽지 않는다"
fi

# 3-ㄴ ── 재고 관리 : 도구 이미지 안에서 돈다
printf '\n%s\n' "  ── 3-ㄴ. 재고 관리 (dss_inventory) — 🔴 **도구 이미지 안**에서 돈다"
say '기대: 지금 20 · 0020~0025 여섯을 올리면 26'
say '🔴 이 저장소는 볼륨이 없다. drizzle 이 dss-inventory-tools 이미지에 구워져 있다.'
V=$(qnum dss-pg-app dss_inventory 'select count(*) from drizzle.__drizzle_migrations;')
if [ -n "$V" ]; then
  if [ "$V" = "20" ]; then ok "① 운영 DB 적용 수 = $V"
  else bad "① 운영 DB 적용 수 = $V (20 을 기대했다)"; fi
else
  unk "① 운영 DB(dss_inventory) 적용 수" "psql 이 수를 안 돌려줬다"
fi
say '② ③ 볼륨 — **해당 없음**(이 시스템에는 마이그레이션 볼륨이 없다)'
V=$("$DOCKER" exec dss-inventory sh -c 'ls /app/drizzle/*.sql 2>/dev/null | wc -l' 2>/dev/null | tr -d ' \r')
if isnum "$V" && [ "$V" -gt 0 ]; then
  if [ "$V" = "20" ]; then ok "④ 도는 dss-inventory 앱 이미지 안의 .sql = $V"
  else bad "④ 도는 dss-inventory 앱 이미지 안의 .sql = $V (20 을 기대했다)"; fi
else
  say '④ 앱 이미지 안에 /app/drizzle 이 없다 — 이 저장소는 그럴 수 있다(아래 ?로 센다)'
fi
unk "④' 도구 이미지 dss-inventory-tools:2 안의 .sql" "docker run 이 필요하다 — 끝의 명령을 보세요"

# 3-ㄷ ── 포털 : 돌릴 길이 없다
printf '\n%s\n' "  ── 3-ㄷ. 포털 (dss_auth) — 🔴 **처음으로 마이그레이션이 생겼다**"
say '기대: 지금 5 · 0005·0006·0007 셋을 올리면 8'
V=$(qnum dss-pg-auth dss_auth 'select count(*) from drizzle.__drizzle_migrations;')
if [ -n "$V" ]; then
  if [ "$V" = "5" ]; then ok "① 운영 DB 적용 수 = $V"
  else bad "① 운영 DB 적용 수 = $V (5 를 기대했다)"; fi
else
  unk "① 운영 DB(dss_auth) 적용 수" "psql 이 수를 안 돌려줬다 — drizzle 스키마가 없을 수도 있다"
fi
printf '%s\n' "    ── 마지막 셋 (언제 적용됐나)"
qdb dss-pg-auth dss_auth "select id || ' · ' || to_timestamp(created_at/1000)::date from drizzle.__drizzle_migrations order by id desc limit 3;" | head -3 | sed 's/^/      /'
say '② ③ 볼륨 — **해당 없음**'
V=$("$DOCKER" exec dss-auth sh -c 'ls /app/drizzle/*.sql 2>/dev/null | wc -l' 2>/dev/null | tr -d ' \r')
if isnum "$V" && [ "$V" -gt 0 ]; then
  say "④ 도는 dss-auth 이미지 안의 .sql = $V"
else
  say '④ 도는 dss-auth 이미지 안에 /app/drizzle 이 없다'
fi
say '🔴 어느 쪽이든 **그것으로 적용할 수는 없다** — drizzle-kit 이 devDependency 라'
say '   운영(runner) 이미지에 없다. 4절을 보세요.'
printf '%s\n' "    ── 🔴 새 표 셋이 **아직 없어야** 정상이다 (있으면 누가 손으로 만든 것이다)"
for t in notification_dismissals notification_kind_purposes notification_acknowledgements; do
  V=$(qdb dss-pg-auth dss_auth "select coalesce(to_regclass('public.$t')::text,'none');" | head -1 | tr -d ' \r')
  case "$V" in
    none) ok "$t 가 아직 없다 (기대한 상태)" ;;
    "$t") bad "🔴 $t 가 **이미 있다** — 누가 손으로 만들었다. 적용 전에 사람이 보세요" ;;
    *)    unk "$t 의 유무" "psql 이 none 도 이름도 아닌 것을 돌려줬다" ;;
  esac
done

# 3-ㄹ ── 나머지 넷 : 이번에 변화 없음
printf '\n%s\n' "  ── 3-ㄹ. 나머지 넷 — 이번 범위에 마이그레이션 **0건**이다"
say '🔵 기대값을 박지 않는다. 지금 수를 적어 두고, 배포 **뒤에 같아야** 한다.'
for pair in "dss_meters|계측기" "dss_improvements|개선요청" "dss_leave|휴가" "dss_board|게시판"; do
  db="${pair%%|*}"; nm="${pair#*|}"
  V=$(qnum dss-pg-app "$db" 'select count(*) from drizzle.__drizzle_migrations;')
  if [ -n "$V" ]; then
    ok "$nm ($db) 적용 수 = $V  ← 배포 뒤에도 이 수여야 한다"
  else
    unk "$nm ($db) 적용 수" "psql 이 수를 안 돌려줬다"
  fi
done
say '🔵 PO 는 제 DB 가 없다 — A/S 와 **같은 dss_as** 를 본다(3-ㄱ 이 그것이다).'

# ── 4 🔴 ───────────────────────────────────────────────────────────────
sec "4. 🔴 포털 마이그레이션을 **돌릴 길이 있는가**"
printf '%s\n' "🔴 지금까지 포털 배포는 전부 마이그레이션 0건이었다. 이번이 처음이다."
if [ -f "$CF" ]; then
  if grep -qE '^[[:space:]]*tools-auth:' "$CF"; then
    ok "compose 에 tools-auth 서비스가 있다 — 길이 있다"
  else
    bad "🔴 compose 에 tools-auth 서비스가 **없다** — 0005·0006·0007 을 돌릴 길이 없다"
    say '사람이 길을 정해야 한다. 고르는 것은 셋이다:'
    say '  ㄱ) dss-auth 의 Dockerfile 에 tools 스테이지를 더해 도구 이미지를 굽는다'
    say '      (다른 여섯이 쓰는 방식. 🔴 저장소를 고치는 일이라 별도 조각이다)'
    say '  ㄴ) 세 .sql 을 psql 로 직접 적용하고 drizzle.__drizzle_migrations 에'
    say '      줄 셋을 손으로 넣는다 (🔴 hash 가 틀리면 다음에 또 돈다)'
    say '  ㄷ) 포털 배포를 이번 묶음에서 빼고 따로 다룬다'
    say '🔴 정하지 않은 채 포털 이미지만 올리면 **없는 표를 찾다 깨진다.**'
  fi
  printf '%s\n' "    ── compose 에 있는 도구 서비스 전부"
  grep -nE '^[[:space:]]*tools-[a-z]+:' "$CF" | sed 's/^/      /'
else
  unk "tools-auth 서비스의 유무" "$CF 가 없다"
fi

# ── 5 ─────────────────────────────────────────────────────────────────
sec "5. DB 핵심 표 행 수 (🔵 배포 뒤 비교용 — 줄어들면 안 된다)"
for spec in \
  "dss-pg-app|dss_as|repair_cases" \
  "dss-pg-app|dss_as|customers" \
  "dss-pg-app|dss_as|attachments" \
  "dss-pg-app|dss_as|workflow_transitions" \
  "dss-pg-app|dss_inventory|parts" \
  "dss-pg-app|dss_inventory|legacy_records" \
  "dss-pg-app|dss_inventory|stock_requests" \
  "dss-pg-app|dss_inventory|approval_routes" \
  "dss-pg-auth|dss_auth|users" \
  "dss-pg-auth|dss_auth|clients" \
  "dss-pg-auth|dss_auth|user_client_grants" ; do
  box="${spec%%|*}"; rest="${spec#*|}"; db="${rest%%|*}"; tb="${rest#*|}"
  V=$(qnum "$box" "$db" "select count(*) from $tb;")
  if [ -n "$V" ]; then
    printf '  ✓ %-18s %-22s %s줄\n' "$db" "$tb" "$V"; PASS=$((PASS+1))
  else
    unk "$db.$tb 행 수" "표가 없거나 psql 이 수를 안 돌려줬다"
  fi
done
printf '%s\n' "    ── 표 개수 (나머지 넷)"
for db in dss_meters dss_improvements dss_leave dss_board; do
  V=$(qnum dss-pg-app "$db" "select count(*) from pg_tables where schemaname='public';")
  if [ -n "$V" ]; then
    printf '  ✓ %-18s public 표 %s개\n' "$db" "$V"; PASS=$((PASS+1))
  else
    unk "$db 의 표 개수" "psql 이 수를 안 돌려줬다"
  fi
done

# ── 6 ─────────────────────────────────────────────────────────────────
sec "6. 디스크 여유와 메모리 — 🔴 이미지 **여덟**을 올린다"
printf '%s\n' "🔵 지난 판들의 tar 크기: A/S 약 132MB · PO 약 95MB · 재고 도구 약 213MB."
printf '%s\n' "   여덟 + 도구 둘이면 **1.2GB 쯤**을 /volume1/dss/images 에 둔다."
FREE_KB=$(df -P "$D" 2>/dev/null | awk 'NR==2 {print $4}')
if isnum "${FREE_KB:-}"; then
  FREE_GB=$((FREE_KB / 1024 / 1024))
  if [ "$FREE_KB" -ge 5000000 ]; then
    ok "$D 여유 ${FREE_GB}GB (5GB 이상 — 넉넉하다)"
  elif [ "$FREE_KB" -ge 3000000 ]; then
    bad "$D 여유 ${FREE_GB}GB — 3~5GB 다. 올리기 전에 옛 tar 를 치우세요"
  else
    bad "🔴 $D 여유 ${FREE_GB}GB — **모자란다.** 먼저 자리를 만드세요"
  fi
else
  unk "$D 의 디스크 여유" "df 가 수를 안 돌려줬다"
fi
printf '%s\n' "    ── /volume1/dss/images 에 지금 쌓인 tar"
if [ -d "$IMAGES" ]; then
  ls -lt "$IMAGES" 2>/dev/null | head -14 | sed 's/^/      /'
  N_TAR=$(ls -1 "$IMAGES"/*.tar 2>/dev/null | wc -l | tr -d ' ')
  say "tar $N_TAR 개. 🔵 옛 판은 되돌리기용이라 아무거나 지우지 않는다."
else
  unk "$IMAGES 폴더" "폴더가 없다"
fi
printf '%s\n' "    ── 메모리"
if free -m >/dev/null 2>&1; then
  free -m 2>/dev/null | sed 's/^/      /'
  MEM_AVAIL=$(free -m 2>/dev/null | awk '/^Mem:/ {print $NF}')
  if isnum "${MEM_AVAIL:-}" && [ "$MEM_AVAIL" -ge 1500 ]; then
    ok "쓸 수 있는 메모리 ${MEM_AVAIL}MB"
  elif isnum "${MEM_AVAIL:-}"; then
    bad "쓸 수 있는 메모리 ${MEM_AVAIL}MB — 여덟을 한 번에 올리기엔 빠듯하다. 나눠 올리세요"
  else
    unk "쓸 수 있는 메모리" "free 가 수를 안 돌려줬다"
  fi
else
  unk "메모리" "free 명령이 없다"
fi

# ── 7 ─────────────────────────────────────────────────────────────────
sec "7. 설정 파일 — 🔴 **이름만** 본다 (값도 길이도 안 찍는다)"
printf '%s\n' "🔵 실측상 이번 범위에 **새로 필요해진 .env 이름은 없다.** 있어야 할 것이"
printf '%s\n' "   그대로 있는지만 센다 — 누가 줄을 덮어썼으면 지금 드러난다."
for spec in \
  "as.env|AS_API_TOKEN AS_WRITE_TOKEN INVENTORY_API_BASE_URL INVENTORY_API_TOKEN INVENTORY_WRITE_TOKEN" \
  "po.env|AS_WRITE_TOKEN AS_APP_BASE_URL INVENTORY_API_BASE_URL INVENTORY_API_TOKEN" \
  "inventory.env|SSO_ISSUER SSO_CLIENT_ID SSO_REDIRECT_URI AS_LOOKUP_URL AS_LOOKUP_TOKEN AS_API_BASE_URL INVENTORY_WRITE_TOKEN" \
  "auth.env|AUTH_TX_SECRET AUTH_KEYS_DIR AUTH_ACTIVE_KID" ; do
  f="$ENVD/${spec%%|*}"; keys="${spec#*|}"
  printf '%s\n' "    ── ${spec%%|*}"
  if [ ! -f "$f" ]; then unk "${spec%%|*} 의 이름들" "파일이 없다"; continue; fi
  for k in $keys; do
    N=$(grep -cE "^${k}=" "$f" 2>/dev/null | tr -d ' ')
    if [ "${N:-0}" = "1" ]; then
      ok "$k 가 1줄 있다"
    elif [ "${N:-0}" = "0" ]; then
      bad "🔴 $k 가 **없다**"
    else
      bad "🔴 $k 가 ${N}줄이다 — 🔴 .env 는 **나중 것이 이긴다.** 조용히 어긋난다"
    fi
  done
done
printf '%s\n' "    ── 🔴 아홉째(RF 이슈관리)의 설정은 **아직 없어야** 정상이다"
if [ -f "$ENVD/rf-trouble.env" ]; then
  say '🔵 rf-trouble.env 가 이미 있다 — 누가 먼저 올려 두었다. 사람이 확인하세요.'
else
  ok "rf-trouble.env 가 아직 없다 (기대한 상태)"
fi

# ── 8 ─────────────────────────────────────────────────────────────────
sec "8. 포털 clients — 아홉째 자리"
printf '%s\n' "🔵 포털 1.8 의 알림 출처 목록에 dss-rf-trouble 이 들어 있다. 그 열쇠는"
printf '%s\n' "   저장소 이름(dss-trouble)과 **다르다** — clients.client_id 가 기준이다."
printf '%s\n' "    ── 등록된 시스템 (🔴 비밀값 칸은 안 뽑는다)"
qdb dss-pg-auth dss_auth "select client_id || ' · grant=' || requires_grant || ' · sort=' || sort_order from clients order by sort_order, client_id;" | sed 's/^/      /'
V=$(qnum dss-pg-auth dss_auth "select count(*) from clients where client_id='dss-rf-trouble';")
if [ -n "$V" ]; then
  if [ "$V" = "0" ]; then
    ok "dss-rf-trouble 이 아직 없다 (기대한 상태 — 세우는 날 넣는다)"
    say '🔴 등록되기 전까지 포털은 그 집을 **부르러 가지도 않는다.** 그래서 포털 1.8 을'
    say '   먼저 올려도 아무 일이 안 생긴다 — 조용히 기다린다.'
  else
    say "dss-rf-trouble 이 이미 $V 줄 있다 — 누가 먼저 등록했다. 주소 넷을 사람이 대조하세요."
    PASS=$((PASS+1))
  fi
else
  unk "clients 의 dss-rf-trouble 줄 수" "psql 이 수를 안 돌려줬다"
fi
printf '%s\n' "    ── 🔴 아홉째가 쓸 포트가 비어 있는가 (13900 을 권한다)"
if [ -f "$CF" ]; then
  if grep -qE '127\.0\.0\.1:13900:' "$CF"; then
    bad "compose 에 13900 이 이미 쓰이고 있다 — 다른 번호를 고르세요"
  else
    ok "compose 에 13900 이 아직 안 쓰인다"
  fi
  printf '%s\n' "      지금 쓰는 번호:"
  grep -oE '127\.0\.0\.1:1[0-9]{4}:' "$CF" | sort -u | sed 's/^/        /'
else
  unk "13900 이 비었는가" "$CF 가 없다"
fi

# ── 9 ─────────────────────────────────────────────────────────────────
sec "9. 되돌릴 자리와 야간 백업"
printf '%s\n' "    ── NAS 에 남은 dss-* 이미지 (🔴 지우지 마세요 — 되돌릴 길이다)"
"$DOCKER" images --format '{{.Repository}}:{{.Tag}}  {{.Size}}  {{.CreatedSince}}' 2>/dev/null \
  | grep -E '^dss-' | sort | sed 's/^/      /'
N_IMG=$("$DOCKER" images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -cE '^dss-')
if isnum "${N_IMG:-}" && [ "$N_IMG" -ge 8 ]; then
  ok "dss-* 이미지가 $N_IMG 개 있다"
else
  unk "dss-* 이미지 개수" "docker images 가 목록을 안 돌려줬다"
fi
printf '%s\n' "    ── 야간 백업 (🔴 배포 전에 **어젯밤 것이 있어야** 한다)"
if [ -d "$BKDB" ]; then
  ls -lt "$BKDB" 2>/dev/null | head -12 | sed 's/^/      /'
  N_BK=$(find "$BKDB" -name '*.dump' -mtime -2 2>/dev/null | wc -l | tr -d ' ')
  if isnum "${N_BK:-}" && [ "$N_BK" -ge 7 ]; then
    ok "이틀 안에 뜬 덤프가 $N_BK 개 (DB 일곱 이상)"
  else
    bad "🔴 이틀 안에 뜬 덤프가 ${N_BK:-?}개다 — 일곱을 기대했다. **배포 전에 백업부터**"
  fi
else
  unk "야간 백업 폴더" "$BKDB 가 없다"
fi

# ── 끝 ────────────────────────────────────────────────────────────────
line
printf '\n'
printf '%s\n' "🔵 ? 둘을 메우는 명령 — 🔴 이 설문은 읽기만 하므로 여기서 돌리지 않는다."
printf '%s\n' "   사람이 따로 치면 된다(컨테이너를 만들었다 바로 지우는 것이라 앱을 안 멈춘다):"
printf '%s\n' "     /usr/local/bin/docker run --rm dss-inventory-tools:2 sh -c 'ls /app/drizzle/*.sql | wc -l'"
printf '%s\n' "     /usr/local/bin/docker run --rm dss-as-tools:1       sh -c 'ls /app/drizzle/*.sql | wc -l'"
printf '%s\n' "   🔵 재고 도구는 **20** 이어야 하고(= 지금 DB 와 같다), 그것이 「올릴 것이"
printf '%s\n' "      원래 없었다」가 아니라 「새 여섯이 아직 안 구워졌다」를 가르는 값이다."
printf '\n'
line
printf '요약 — ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
if [ "$UNK" -gt 0 ]; then
  printf '%s\n' "🔴 **못 잰 것이 $UNK 개 있다.** 통과로 세지 않는다 — 종료 코드 1."
fi
if [ "$FAIL" -gt 0 ]; then
  printf '%s\n' "🔴 **어긋난 것이 $FAIL 개 있다.** 배포 범위나 기대값이 틀렸을 수 있다."
fi
printf '%s\n' "끝 — 이 출력을 그대로 복사해 주세요."
if [ "$UNK" -gt 0 ] || [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
