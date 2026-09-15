#!/bin/bash
# /volume1/dss/jobs/acme-renew.sh — dss21.co.kr 인증서 갱신
#
# DSM 작업 스케줄러가 root 로 돌린다 (제어판 → 작업 스케줄러 → "DSS 인증서 갱신", 매일 03:10).
# 손으로 돌려도 된다:  sudo -i → bash /volume1/dss/jobs/acme-renew.sh
# 제자리에 두는 것은 setup/04-https-cert.sh 가 한다.
#
# 매일 돌지만 실제 갱신은 만료 30일 전쯤 한 번이다 — acme.sh 가 날짜를 보고 건너뛴다.
# 갱신되면 같은 이름("dss21.co.kr")의 DSM 인증서를 바꿔 끼우므로 리버스 프록시 규칙은
# 다시 손대지 않아도 된다.
#
# ── 실패를 조용히 두지 않는다 ───────────────────────────────────────────
# Let's Encrypt 는 2025 년부터 만료 안내 메일을 보내지 않는다. 그래서 여기서 직접 본다.
# 남은 날이 21일 아래면 종료 코드 1 — 작업 스케줄러가 "비정상 종료"로 표시한다.
# 갱신은 30일 전부터 매일 시도하므로, 21일 아래라는 것은 9일 넘게 실패했다는 뜻이다.
# 그래도 만료까지 3주가 남아 사람이 손볼 틈이 있다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
A=$D/acme
DOMAIN=dss21.co.kr
CERT=$A/certs/$DOMAIN/fullchain.cer
WARN_DAYS=21
STAMP=$(date +%Y-%m-%d_%H%M)

mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/acme-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

FAIL=0; T0=$SECONDS
echo "DSS 인증서 갱신 · $(date '+%F %T')"

"$A/app/acme.sh" --cron --home "$A/app" --config-home "$A/data" --cert-home "$A/certs" \
  || { echo "  ✗ acme.sh --cron 이 실패를 돌려줌 — 위 줄을 볼 것"; FAIL=1; }

if [ ! -s "$CERT" ]; then
  echo "  ✗ 인증서 파일이 없다: $CERT"; FAIL=1
elif openssl x509 -in "$CERT" -noout -checkend $((WARN_DAYS * 86400)) >/dev/null; then
  echo "  ✓ $(openssl x509 -in "$CERT" -noout -enddate) — ${WARN_DAYS}일 넘게 남음"
else
  echo "  ✗ $(openssl x509 -in "$CERT" -noout -enddate) — ${WARN_DAYS}일 아래. 갱신이 며칠째 실패하고 있다"; FAIL=1
fi

# ── 정리 · 결과 ─────────────────────────────────────────────────────────
ls -1t "$D/setup/logs"/acme-*.log 2>/dev/null | tail -n +61 | xargs -r rm -f
if [ "$FAIL" = 0 ]; then echo "── 정상 · $((SECONDS - T0))초"; exit 0
else echo "── 실패가 있다 · $((SECONDS - T0))초 — 위 ✗ 줄을 볼 것"; exit 1; fi
