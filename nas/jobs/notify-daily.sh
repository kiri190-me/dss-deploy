#!/bin/bash
# /volume1/dss/jobs/notify-daily.sh — 교정 기한 알림 메일
#
# DSM 작업 스케줄러가 root 로 매일 09:00 에 돌린다 (제어판 → 작업 스케줄러 → "DSS 교정 알림").
# 손으로 돌려도 된다:  sudo -i → bash /volume1/dss/jobs/notify-daily.sh
#
# ── 무엇을 ─────────────────────────────────────────────────────────────
# 교정 기한이 **다음 달**인 계측기를 등록된 받는 사람에게 알린다.
# 기한이 닥쳐서 알리면 교정을 보낼 시간이 없기 때문이다(njlee/docs/NOTIFY.md).
#
#   예) 기한이 2026-11 인 계측기 → 2026-10-01 에 발송
#
# **매일 돌지만 실제로 나가는 것은 매월 1일뿐이다.** 1일이 아니면 아무것도 하지
# 않고 끝난다. 날짜 판단을 스케줄러가 아니라 코드가 하는 이유는, 스케줄러 설정이
# 어딘가에서 조용히 바뀌어도 규칙은 코드에 남아 있게 하기 위해서다.
# 같은 기한은 두 번 보내지 않는다 — web_notifications 에 성공 기록이 있으면 건너뛴다.
#
# ── 왜 스케줄러에 도커 명령을 직접 적지 않나 ───────────────────────────
#   1. 기록. 1일이 아니라 그냥 끝난 날도 남겨야 "돌기는 했는지"를 나중에 안다.
#      이남준 님 PC 의 자동 백업이 2주 넘게 0바이트만 남기는 동안 아무도 몰랐다.
#   2. root 만 고칠 수 있게. 관리자 계정이 고칠 수 있는 파일을 root 가 매일
#      실행하면, 그 파일이 곧 root 권한의 뒷문이 된다(03-install-backup.sh 와 같은 이유).
#
# ⚠️ 도구 컨테이너는 profiles: [tools] 라 `up -d` 로는 뜨지 않는다. 여기서
#    `run --rm` 으로 부를 때만 잠깐 떴다 사라진다 — 상시 서비스가 아니므로
#    메모리 예산 2.7GB 를 건드리지 않는다.
set -u
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y-%m-%d_%H%M)
KEEP=60   # 매일 하나 = 두 달치

mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/notify-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

echo "DSS 교정 알림 · $(date '+%F %T')"
echo

"$DOCKER" compose \
  -f "$D/deploy/docker-compose.nas.yml" \
  --env-file "$D/deploy/.env.nas" \
  --profile tools \
  run --rm tools-meters npm run send-notify
rc=$?

echo
if [ "$rc" = 0 ]; then
  echo "정상 종료 (0)"
else
  echo "✗ 실패 — 종료 코드 $rc"
  echo "  작업 스케줄러가 '비정상 종료'로 표시한다. 알림 메일을 켜 두었으면 메일이 온다."
fi

# 오래된 기록은 날짜가 아니라 개수로 지운다. 작업이 몇 주 멈춰도 마지막 기록들은
# 남는다 (야간 백업과 같은 규칙).
ls -1t "$D"/setup/logs/notify-*.log 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f

exit $rc
