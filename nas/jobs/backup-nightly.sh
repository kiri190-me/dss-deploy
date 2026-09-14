#!/bin/bash
# /volume1/dss/jobs/backup-nightly.sh — 매일 밤 백업
#
# DSM 작업 스케줄러가 root 로 돌린다 (제어판 → 작업 스케줄러 → "DSS 야간 백업").
# 손으로 돌려도 된다:  sudo -i → bash /volume1/dss/jobs/backup-nightly.sh
#
# ── 무엇을 ─────────────────────────────────────────────────────────────
#   DB 셋      dss_auth · dss_meters · dss_as  →  /volume1/dss/backups/db/     (DB마다 최근 30개)
#   파일       계측기 사진·성적서 · A/S 첨부 · 서명키 →  /volume1/dss/backups/files/ (쌓아 올림)
#   기록       /volume1/dss/setup/logs/backup-*.log  (관리자가 읽을 수 있는 곳 — 검수용)
#
# ── 이남준 님 PC 에서 배운 것 (2026-09-14) ─────────────────────────────
# 그쪽 자동 백업은 2주 넘게 0바이트 파일만 남기고 있었는데 아무도 몰랐다.
#   1. 백업은 .part 로 쓰고, pg_restore 로 열어 본 뒤에만 제 이름을 준다.
#      빈 파일·깨진 파일은 절대 백업 폴더에 남지 않는다.
#   2. 오래된 것은 날짜가 아니라 **개수**로 지운다. 작업이 몇 주 멈춰도 마지막
#      정상 백업들은 지워지지 않는다.
#   3. 하나라도 실패하면 종료 코드 1 — 작업 스케줄러가 "비정상 종료"로 표시하고
#      설정해 두면 메일로 알린다.
#
# ⚠️ 같은 디스크 안의 백업이다. 실수로 지운 것·잘못 고친 것은 되살리지만 디스크가
#    죽으면 함께 죽는다. NAS 밖(USB·클라우드)으로 한 벌 더 보내는 것은 8단계에서.
set -u
D=/volume1/dss
B=$D/backups
DOCKER=/usr/local/bin/docker
KEEP=30
STAMP=$(date +%Y-%m-%d_%H%M)

mkdir -p "$B/db" "$B/files" "$D/setup/logs"
chown root:root "$B"; chmod 700 "$B"
LOG="$D/setup/logs/backup-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

FAIL=0; T0=$SECONDS
echo "DSS 야간 백업 · $(date '+%F %T')"

# ── DB ────────────────────────────────────────────────────────────────
dump() { # 컨테이너 롤 DB
  local out="$B/db/$3_$STAMP.dump"
  local tmp="$out.part" err="$out.err"
  if "$DOCKER" exec "$1" pg_dump -U "$2" -d "$3" -Fc > "$tmp" 2> "$err" \
     && [ -s "$tmp" ] \
     && "$DOCKER" exec -i "$1" pg_restore -l < "$tmp" > /dev/null 2>> "$err"; then
    mv "$tmp" "$out"; rm -f "$err"
    local tables; tables=$("$DOCKER" exec -i "$1" pg_restore -l < "$out" | grep -c 'TABLE DATA')
    echo "  ✓ $3 · $(du -h "$out" | cut -f1) · 표 $tables"
  else
    echo "  ✗ $3 — $(tail -2 "$err" 2>/dev/null | tr '\n' ' ')"
    rm -f "$tmp" "$err"; FAIL=1
  fi
  # 개수로 정리 — 최근 $KEEP 개만 남긴다
  ls -1t "$B/db/$3"_*.dump 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f
}
echo "── DB"
dump dss-pg-auth dss_auth_app   dss_auth
dump dss-pg-app  dss_meters_app dss_meters
dump dss-pg-app  dss_app        dss_as

# ── 파일 ──────────────────────────────────────────────────────────────
# 쌓아 올린다(--delete 없음). 이름이 UUID 라 한 번 생긴 파일은 바뀌지 않으므로
# 새로 생긴 것만 복사되고, 화면에서 지운 사진도 백업에는 남는다.
echo "── 파일"
for p in meters-files as-attachments auth-keys; do
  if rsync -a "$D/$p/" "$B/files/$p/"; then
    echo "  ✓ $p · 파일 $(find "$B/files/$p" -type f | wc -l)개 · $(du -sh "$B/files/$p" | cut -f1)"
  else echo "  ✗ $p 복사 실패"; FAIL=1; fi
done

# ── 정리 · 결과 ───────────────────────────────────────────────────────
ls -1t "$D/setup/logs"/backup-*.log 2>/dev/null | tail -n +61 | xargs -r rm -f
echo "── 디스크: /volume1 여유 $(df -h /volume1 | awk 'NR==2{print $4" ("100-$5+0"%)"}') · 백업 전체 $(du -sh "$B" | cut -f1)"
if [ "$FAIL" = 0 ]; then echo "── 성공 · $((SECONDS - T0))초"; exit 0
else echo "── 실패가 있다 · $((SECONDS - T0))초 — 위 ✗ 줄을 볼 것"; exit 1; fi
