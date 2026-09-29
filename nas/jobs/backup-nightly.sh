#!/bin/bash
# /volume1/dss/jobs/backup-nightly.sh — 매일 밤 백업
#
# DSM 작업 스케줄러가 root 로 돌린다 (제어판 → 작업 스케줄러 → "DSS 야간 백업").
# 손으로 돌려도 된다:  sudo -i → bash /volume1/dss/jobs/backup-nightly.sh
#
# ── 무엇을 ─────────────────────────────────────────────────────────────
#   DB 다섯    dss_auth · dss_meters · dss_as · dss_improvements · dss_leave
#                                     →  /volume1/dss/backups/db/     (DB마다 최근 30개)
#   파일       계측기 사진·성적서 · A/S 첨부 · 서명키 · 개선요청 첨부
#                                     →  /volume1/dss/backups/files/ (쌓아 올림)
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
dump dss-pg-app  dss_improvements_app dss_improvements
# 휴가 (2026-09-29 더함). 자기 DB · 자기 롤이라 한 줄이 그대로 는다.
# PO/내자는 여기 없다 — A/S 와 **같은 dss_as** 를 보므로 위 dss_as 줄이 함께 받는다.
dump dss-pg-app  dss_leave_app  dss_leave

# 🔴 ── 고치는 것과 올리는 것은 다른 일이다 ─────────────────────────────
#
# 2026-09-29 에 확인된 일이다. 바로 위 dss_improvements 줄은 9/18 커밋 8027803
# 으로 **저장소에는** 들어가 있었는데, 그 파일을 **NAS 에 올리지 않았다.**
# 그래서 개선요청 DB 가 9/18 부터 9/29 까지 11일간 한 번도 백업되지 않았다.
#
# 아무 오류도 나지 않았다. 야간 백업은 매일 "성공"으로 끝났다 — 없는 줄은
# 실패하지 않기 때문이다. 게다가 문서에는 「더했다」고 적혀 있어서, 문서만
# 보면 된 줄 알 상황이었다.
#
# 그래서 이 줄을 더한 뒤에 할 일이 둘 더 있다:
#   1. 이 파일을 NAS 의 /volume1/dss/jobs/backup-nightly.sh 로 **올린다.**
#      (올린 뒤 md5 를 맞춘다 — 올렸다고 생각한 것과 올라간 것도 다른 일이다.)
#   2. 손으로 한 번 돌려 `✓ dss_leave` 줄이 실제로 찍히는지 본다.
#      그리고 **다음 날 아침** /volume1/dss/backups/db/ 를 다시 본다 —
#      스케줄러가 실제로 돌려서 덤프가 생기는지가 진짜 확인이다.
#
# 「있는가」가 아니라 「제 일을 하는가」를 본다.

# ── 파일 ──────────────────────────────────────────────────────────────
# 쌓아 올린다(--delete 없음). 이름이 UUID 라 한 번 생긴 파일은 바뀌지 않으므로
# 새로 생긴 것만 복사되고, 화면에서 지운 사진도 백업에는 남는다.
#
# 🔴 휴가(dss_leave)는 여기에 **더할 것이 없다.** 빠뜨린 것이 아니다 —
#    그 앱은 파일을 올리지 않는다(업로드 폴더도, UPLOADS_DIR 류 환경변수도,
#    그것을 읽는 코드도 없다. 2026-09-29 확인). docker-compose.nas.yml 의
#    app-leave 에 볼륨이 하나도 안 붙어 있는 것과 같은 이유다.
#    휴가는 위 DB 덤프 한 줄로 전부 백업된다.
echo "── 파일"
for p in meters-files as-attachments auth-keys improvements-uploads; do
  if rsync -a "$D/$p/" "$B/files/$p/"; then
    echo "  ✓ $p · 파일 $(find "$B/files/$p" -type f | wc -l)개 · $(du -sh "$B/files/$p" | cut -f1)"
  else echo "  ✗ $p 복사 실패"; FAIL=1; fi
done

# ── 정리 · 결과 ───────────────────────────────────────────────────────
ls -1t "$D/setup/logs"/backup-*.log 2>/dev/null | tail -n +61 | xargs -r rm -f
echo "── 디스크: /volume1 여유 $(df -h /volume1 | awk 'NR==2{print $4" ("100-$5+0"%)"}') · 백업 전체 $(du -sh "$B" | cut -f1)"
if [ "$FAIL" = 0 ]; then echo "── 성공 · $((SECONDS - T0))초"; exit 0
else echo "── 실패가 있다 · $((SECONDS - T0))초 — 위 ✗ 줄을 볼 것"; exit 1; fi
