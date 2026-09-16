#!/bin/bash
# /volume1/dss/setup/06-notify-install.sh — 교정 기한 알림을 NAS 에서 돌게 한다
#
# ── 사람이 실행한다 (처음 한 번. 다시 돌려도 같은 결과) ──────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                          ← DSM 비밀번호. 한/영이 영문인지 먼저!
#   (NAS)         bash /volume1/dss/setup/06-notify-install.sh
#
# ── 하는 일 ─────────────────────────────────────────────────────────────
#   1. 먼저 볼 것 — 도구 이미지·compose 의 tools-meters·DB (하나라도 아니면
#      아무것도 바꾸지 않고 멈춘다)
#   2. 지금 막혀 있는지 본다 — 08-28 시험 발송 기록이 10-01·11-01 을 막고 있다
#   3. 그 기록을 치운다 — 되살릴 INSERT 문을 backups/ 에 남기고 지운다
#   4. 메일 서버에 로그인만 해 본다 — 계정은 NAS 의 env/meters.env 에만 있어
#      개발 PC 에서는 확인할 수 없던 자리다
#   5. 확인 — --dry 로 무엇이 나갈지만 본다 (메일은 나가지 않는다)
#   6. 매일 돌 스크립트를 제자리에 (jobs/notify-daily.sh, root 700)
#   7. 한 번 돌려 본다 — 오늘이 1일이 아니면 아무것도 나가지 않는 것이 정상
#
# 결과는 /volume1/dss/setup/logs/06-notify-*.log.
#
# ── 2·3 이 왜 필요한가 (2026-09-16 개발 PC 에서 찾음) ───────────────────
# web_notifications 에 08-28 시험 발송 두 줄(2026-11 · 2026-12, 각 1~2대·1명)이
# result='SENT' 로 남아 있다. 이 시스템은 같은 기한을 두 번 보내지 않으므로,
# 그대로 두면 **10-01 과 11-01 에 아무것도 나가지 않는다.** 그런데 화면에는
# 아무 이상이 없다 — 이 기능의 정상 동작과 구분되지 않는다.
# 계측기 자료는 개발 PC 사본이므로(결정 G) NAS 에도 같은 두 줄이 있을 것이다.
# 다르면 3 이 아무것도 지우지 않고 그대로 알린다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
IMAGE=dss-meters-tools:1
SRC=$D/setup/notify-daily.sh
DST=$D/jobs/notify-daily.sh
STAMP=$(date +%Y%m%d-%H%M%S)
KEEP=$D/backups/notify-blocking-rows-$STAMP.sql

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/06-notify-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

PASS=0; FAIL=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# DB 에 묻는다. 비밀번호를 적지 않는다 — 컨테이너 안의 POSTGRES_USER 를 쓴다.
q()  { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d dss_meters -Atc \"$1\"" 2>/dev/null; }
qq() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d dss_meters -c \"$1\"" 2>/dev/null; }

COMPOSE=("$DOCKER" compose -f "$D/deploy/docker-compose.nas.yml" --env-file "$D/deploy/.env.nas" --profile tools)

echo "DSS 교정 알림 설치 · $(date '+%F %T')"

# ══ 1. 먼저 볼 것 ═══════════════════════════════════════════════════════
step "1. 먼저 볼 것"

if "$DOCKER" image inspect "$IMAGE" >/dev/null 2>&1; then
  ok "도구 이미지 $IMAGE ($("$DOCKER" image inspect "$IMAGE" --format '{{.Id}}' | cut -c1-19)…)"
else
  bad "도구 이미지 $IMAGE 가 없다"
  stop "먼저 images/ 의 tar 를 docker load 하고 지문을 개발 PC 값과 맞춰 보세요."
fi

if grep -q "^  tools-meters:" "$D/deploy/docker-compose.nas.yml"; then
  ok "compose 에 tools-meters 가 있다"
else
  bad "deploy/docker-compose.nas.yml 에 tools-meters 가 없다"
  stop "새 compose 파일이 아직 안 올라왔습니다."
fi

if "$DOCKER" ps --format '{{.Names}}' | grep -qx dss-pg-app; then
  ok "DB(dss-pg-app)가 떠 있다"
else
  bad "DB(dss-pg-app)가 떠 있지 않다"
  stop "docker compose ... up -d 로 먼저 띄우세요."
fi

n=$(q "select count(*) from web_notify_recipients where is_active and deleted_at is null")
if [ "${n:-0}" -gt 0 ]; then
  ok "받는 사람 ${n}명 등록됨"
else
  bad "받는 사람이 0명이다 — 보낼 곳이 없다"
  stop "https://meters.dss21.co.kr/settings/notify 에서 먼저 등록하세요."
fi

[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다."

# ══ 2. 지금 막혀 있는가 ════════════════════════════════════════════════
step "2. 지금 무엇이 막고 있나 — web_notifications 의 성공 기록"
qq "select target_ym as 기한, sent_on as 보낸날, meter_count as 대수, recipient_count as 받은이, result from web_notifications order by created_at"

BLOCKED=$(q "select count(*) from web_notifications where result='SENT' and sent_on='2026-08-28' and target_ym in ('2026-11','2026-12')")
echo
if [ "${BLOCKED:-0}" -gt 0 ]; then
  echo "  → 08-28 시험 발송 ${BLOCKED}줄이 다음 두 달을 막고 있다."
else
  echo "  → 막는 기록이 없다. 3 은 아무것도 지우지 않는다."
fi

# ══ 3. 막는 기록을 치운다 ══════════════════════════════════════════════
step "3. 막는 기록을 치운다 (되살릴 문장을 먼저 남긴다)"

if [ "${BLOCKED:-0}" -gt 0 ]; then
  mkdir -p "$D/backups"
  q "select format('INSERT INTO web_notifications (id,target_ym,sent_on,meter_count,recipient_count,result,error,created_at) VALUES (%L,%L,%L,%s,%s,%L,%L,%L);', id,target_ym,sent_on,meter_count,recipient_count,result,error,created_at) from web_notifications where result='SENT' and sent_on='2026-08-28' and target_ym in ('2026-11','2026-12')" > "$KEEP"
  chown root:root "$KEEP"; chmod 600 "$KEEP"

  if [ -s "$KEEP" ]; then
    ok "되살릴 문장 $(wc -l < "$KEEP")줄 → $KEEP"
  else
    bad "되살릴 문장을 남기지 못했다"
    stop "지우지 않았습니다."
  fi

  del=$(q "with d as (delete from web_notifications where result='SENT' and sent_on='2026-08-28' and target_ym in ('2026-11','2026-12') returning 1) select count(*) from d")
  [ "${del:-0}" = "$BLOCKED" ] && ok "${del}줄 지움" || bad "지운 줄 수가 다르다 (${del:-0}/${BLOCKED})"

  left=$(q "select count(*) from web_notifications where result='SENT' and target_ym in ('2026-11','2026-12')")
  [ "${left:-1}" = 0 ] && ok "2026-11·2026-12 를 막는 기록이 이제 없다" || bad "아직 ${left}줄 남아 있다"
else
  ok "치울 것이 없다 (이미 돌린 적이 있거나, NAS 기록이 개발 PC 와 다르다)"
fi

# ══ 4. 메일 서버에 붙을 수 있는가 (보내지는 않는다) ════════════════════
#
# 개발 PC 의 .env.local 에는 SMTP 계정이 없다(HOST·PORT 뿐). 그래서 이 확인은
# 여기서만 할 수 있다 — 계정은 NAS 의 env/meters.env 에만 있다.
# cafe24 서버는 TLSv1 까지만 하고 RFC 5746 을 지원하지 않아 요즘 Node 가 기본으로
# 거절한다. njlee 의 src/lib/mail/transport.ts 가 그 예외를 열어 두었는데, 그것이
# 리눅스 컨테이너에서도 통하는지는 이 자리에서 처음 확인된다.
step "4. 메일 서버(cafe24)에 로그인만 해 본다 — 보내지 않는다"
"${COMPOSE[@]}" run --rm tools-meters npm run check-smtp 2>&1 | sed 's/^/  /'
rc=${PIPESTATUS[0]}
if [ "$rc" = 0 ]; then
  ok "SMTP 로그인 성공"
else
  bad "SMTP 로그인 실패 (종료 코드 $rc)"
  echo "    535 라면: 웹메일에 그 비밀번호로 직접 로그인되는지 → 환경설정의"
  echo "    POP3/SMTP 사용설정이 '사용함' 인지 → 비밀번호를 방금 바꿨다면 30분."
fi

# ══ 5. 무엇이 나갈지 본다 (메일은 나가지 않는다) ═══════════════════════
step "5. 다음 발송에 무엇이 나갈지 — 메일은 보내지 않는다"
YM=$(date -d "+1 month" +%Y-%m 2>/dev/null || date +%Y-%m)
echo "  (다음 달 = $YM 기한 기준)"
echo
"${COMPOSE[@]}" run --rm tools-meters npm run send-notify -- --dry --ym="$YM" 2>&1 | sed 's/^/  /'
rc=${PIPESTATUS[0]}
[ "$rc" = 0 ] && ok "도구 컨테이너가 DB 와 본문까지 갔다" || bad "도구 컨테이너 실패 (종료 코드 $rc)"

# ══ 6. 매일 돌 스크립트를 제자리에 ═════════════════════════════════════
step "6. 매일 돌 스크립트를 제자리에"

if [ -s "$SRC" ]; then
  bash -n "$SRC" || stop "스크립트 문법 오류. Claude 에게 알려 주세요."
  mkdir -p "$D/jobs"
  find "$D/jobs" -exec /usr/syno/bin/synoacltool -del {} \; >/dev/null 2>&1
  cp "$SRC" "$DST" && rm -f "$SRC"
  chown -R root:root "$D/jobs"; chmod 700 "$D/jobs"; chmod 700 "$DST"
  ok "제자리: $DST ($(stat -c '%U:%G %a' "$DST"))"
elif [ -s "$DST" ]; then
  ok "이미 제자리에 있다: $DST ($(stat -c '%U:%G %a' "$DST"))"
else
  bad "$SRC 도 $DST 도 없다"
  stop "notify-daily.sh 가 아직 안 올라왔습니다."
fi

# ══ 7. 한 번 돌려 본다 ═════════════════════════════════════════════════
step "7. 한 번 돌려 본다"
echo "  오늘이 매월 1일이 아니면 '보낼 것이 없습니다' 로 끝나는 것이 정상이다."
echo
bash "$DST" | sed 's/^/  /'
rc=${PIPESTATUS[0]}
[ "$rc" = 0 ] && ok "정상 종료" || bad "종료 코드 $rc"

# ══ 끝 ═════════════════════════════════════════════════════════════════
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"

if [ "$FAIL" = 0 ]; then
  cat <<'ANNOUNCE'

남은 것은 DSM 작업 스케줄러 등록 하나입니다 (사람이 합니다).

  제어판 → 작업 스케줄러 → 생성 → 예약된 작업 → 사용자 정의 스크립트

    작업 이름   DSS 교정 알림
    사용자      root
    일정        매일 · 09:00
    스크립트    bash /volume1/dss/jobs/notify-daily.sh
    설정 탭     「비정상 종료한 경우에만 실행 세부 정보 보내기」 켜기

  등록한 뒤 [실행] 을 한 번 눌러 보세요. 1일이 아니므로 아무것도 나가지 않고
  끝나는 것이 정상이고, 그 사실이 setup/logs/notify-*.log 에 남습니다.

ANNOUNCE
else
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
fi

exit "$FAIL"
