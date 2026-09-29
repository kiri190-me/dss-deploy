#!/bin/bash
# /volume1/dss/jobs/purge-nightly.sh — 휴지통 15일 완전삭제
#
# DSM 작업 스케줄러가 root 로 매일 03:30 에 돌린다
# (제어판 → 작업 스케줄러 → "DSS Purge"). 손으로 돌려도 된다:
#   sudo -i → bash /volume1/dss/jobs/purge-nightly.sh
#
# ── 🔴 왜 이 파일이 2026-09-29 에야 생겼나 ─────────────────────────────
# A/S 에는 「휴지통에 넣고 15일이 지나면 영구 삭제」가 처음부터 있었다. 화면도
# 사용자에게 「15일 뒤 자동 삭제」라고 말한다. 스크립트 셋도 다 있다
# (RF_Service_System/package.json 의 purge:repair-cases · purge:flowcharts ·
# purge:master-data). **그런데 그 작업은 한 번도 돈 적이 없다.**
#
# 셋을 묶어 돌리는 래퍼는 개발 PC 시절에 이미 있었다 —
# RF_Service_System/scripts/run-nightly-purge.ps1. 그것은 PowerShell 이고
# 윈도우 작업 스케줄러에 등록할 것으로 만들었다. 2026-09-14 에 운영을
# NAS(리눅스)로 옮기면서 리눅스 판을 만들지 않았고 그대로 잊혔다. A/S 의
# HANDOFF.md H절 제목이 지금도 "Nightly Purge Wrapper — written, NOT scheduled"
# 다. DSM 작업 스케줄러 실측(2026-09-29): DSS Backup 02:30 · DSS certificate
# renewal 03:10 · DSS Calibration Notification 09:00 · 공유폴더 스냅샷 여섯 —
# **완전삭제는 없었다.**
#
# 이 파일이 그 빠진 자리다. PowerShell 래퍼를 대신하는 리눅스 판이고, 무엇을
# 어떤 순서로 돌리는지·실패를 어떻게 다루는지는 그쪽과 같게 맞췄다. 그쪽은
# 지우지 않는다 — 개발 PC 에서 손으로 돌릴 때 여전히 쓸 수 있고, 두 파일이
# 같은 규칙을 적어 두는 편이 나중에 한쪽만 고치는 사고를 막는다.
#
# ── 🔴 PO 휴지통도 여기 딸려 있다 ──────────────────────────────────────
# PO(dss-po)는 A/S 와 **같은 dss_as DB** 를 본다. 견적서·발주·내자를 A/S 에서
# 떼어 낸 사이트라 보는 표가 같다. 그래서 PO 에는 도구 이미지(tools-po)도
# 마이그레이션도 야간 작업도 없고, **PO 휴지통은 아래 purge:master-data 가
# 함께 비운다**(docker-compose.nas.yml 의 app-po 머리말). 이것이 안 돌면 PO
# 휴지통도 영영 안 비워진다 — 화면은 계속 「15일 뒤 자동 삭제」라고 말하면서.
#
# ── 무엇을 지우나 ──────────────────────────────────────────────────────
#   purge:repair-cases   휴지통에서 15일 지난 **수리 건** + 거기 딸린 진단
#                        순서도 전부(따로 휴지통에 없어도 함께). 보존해야 하는
#                        이력·회계 표는 ON DELETE SET NULL 로 연결만 풀린다.
#   purge:flowcharts     따로 휴지통에 넣은 **진단 순서도**(간선 → 마디 → 본체)
#   purge:master-data    **고객사**(담당자·End-User 까지) · **제품 모델** ·
#                        **부품** · **기술 절차** · **내자 정리 줄** ·
#                        **견적서**  ← 뒤의 둘이 PO 쪽이다
#
# 셋 다 **DB 안에서만** 지운다. 첨부 파일의 디스크 실물은 건드리지 않는다
# (master-data-purge.ts: "첨부 행 · 디스크 실물은 남는다"). 그래서 아래 문지기도
# 파일 백업이 아니라 **DB 덤프**를 본다.
#
# 지운 자리마다 audit_logs 에 PURGE 한 줄이 남는다(actor_user_id = NULL — 사람이
# 아니라 시스템이 한 일). 다만 연락처·이름 같은 개인정보는 그 스냅숏에 일부러
# 담지 않는다. 즉 **이 작업이 도는 순간이 그 개인정보가 시스템에서 영구히
# 사라지는 지점이다.**
#
# ── 🔴 보기만 하는 모드는 없다 ─────────────────────────────────────────
# 세 스크립트 어느 것도 --dry-run 을 받지 않는다(2026-09-29 확인 — 셋 다
# process.argv 를 아예 읽지 않는다). 여기서도 억지로 만들지 않았다. 흉내만 낸
# --dry-run 은 「봤으니 괜찮겠지」라는 잘못된 안심을 준다.
#
# **무엇이 지워질지 미리 보려면 이것을 먼저 돌려라:**
#
#     sh /volume1/dss/setup/trash-status.sh
#
# 「기한지남」 칸이 그날 밤 지워질 건수다. 조회 전용이라 한 글자도 안 지운다.
#
# ── 🔴 야간 백업(02:30)보다 뒤에 돌아야 하는 까닭 ──────────────────────
# 이 작업은 **되돌릴 수 없다.** 휴지통으로 옮기는 것이 아니라 DELETE 다. 잘못
# 지워진 것을 되살릴 길은 그날 백업뿐이다. 그래서 둘을 건다:
#   1. 백업 02:30 → 완전삭제 **03:30**. 지우기 전의 상태가 반드시 덤프에 남는다.
#   2. 아래 문지기가 **오늘 날짜의 dss_as 덤프가 있는지 먼저 본다.** 없으면
#      한 건도 지우지 않고 종료 코드 2 로 멈춘다. 백업이 조용히 죽어 있는 채로
#      며칠이 지나면(이남준 님 PC 에서 2주간 실제로 일어난 일 —
#      backup-nightly.sh 머리말) 안전망 없이 영구 삭제만 계속 도는 셈이 된다.
#
# ── 종료 코드 ──────────────────────────────────────────────────────────
#   0  셋 다 정상
#   1  하나 이상 실패 (나머지는 그래도 다 돌렸다)
#   2  🔴 문지기가 막았다 — 오늘 백업이 없어 **아무것도 지우지 않았다**
#
# ⚠️ 도구 컨테이너 tools-as 는 profiles: [tools] 라 `up -d` 로는 뜨지 않는다.
#    여기서 `run --rm` 으로 부를 때만 잠깐 떴다 사라진다 — 상시 서비스가
#    아니므로 메모리 예산 2.7GB 를 건드리지 않는다.
set -u
D=/volume1/dss
B=$D/backups
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y-%m-%d_%H%M)
TODAY=$(date +%F)
KEEP=60   # 매일 하나 = 두 달치 (교정 알림·야간 백업과 같은 규칙)

mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/purge-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

T0=$SECONDS
echo "DSS 휴지통 완전삭제 · $(date '+%F %T')"
echo

# ── 🔴 문지기 — 오늘 백업이 없으면 아무것도 안 지운다 ──────────────────
# backup-nightly.sh 가 $B/db/dss_as_<날짜>_<시각>.dump 로 남긴다. 그 파일은
# .part 로 쓰고 pg_restore -l 로 열어 본 뒤에만 제 이름을 받으므로, 이 이름이
# 있다는 것 자체가 "열리는 덤프가 오늘 남았다"는 뜻이다(빈 파일·깨진 파일은
# 애초에 이 이름을 못 얻는다). 그래도 -s 로 한 번 더 본다.
echo "── 문지기 · 오늘($TODAY) 백업 확인"
DUMP=$(ls -1t "$B/db/dss_as_${TODAY}"_*.dump 2>/dev/null | head -1)
if [ -z "$DUMP" ] || [ ! -s "$DUMP" ]; then
  echo "  ✗ 오늘 날짜의 dss_as 덤프가 $B/db 에 없다."
  echo
  echo "🔴 아무것도 지우지 않고 멈춘다. 완전삭제는 되돌릴 수 없고, 되돌릴"
  echo "   길은 그날 백업뿐이다 — 그것이 없으면 지우지 않는 편이 맞다."
  echo
  echo "   할 일:"
  echo "     1. 야간 백업이 왜 안 돌았는지 본다 — $D/setup/logs/backup-*.log"
  echo "        (DSM 작업 스케줄러 \"DSS Backup\" 02:30 · root)"
  echo "     2. 손으로 한 번 돌린다 —  bash $D/jobs/backup-nightly.sh"
  echo "     3. 그 뒤 이 작업을 다시 돌린다 —  bash $D/jobs/purge-nightly.sh"
  echo
  echo "── 멈춤 · $((SECONDS - T0))초 (종료 코드 2)"
  ls -1t "$D/setup/logs"/purge-*.log 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f
  exit 2
fi
echo "  ✓ $(basename "$DUMP") · $(du -h "$DUMP" | cut -f1)"
echo

# ── 셋을 차례로 ────────────────────────────────────────────────────────
# 🔴 **차례로만 돌린다. 절대 동시에 돌리지 않는다**(run-nightly-purge.ps1 이
#    정해 둔 규칙). 순서는 수리 건 → 진단 순서도 → 기준정보다. 안전 때문은
#    아니다 — 세 회차 모두 각자의 트랜잭션 안에서 행을 잠그고 자격을 다시
#    판정하므로 어느 순서든 안전하다. 로그가 읽히기 때문이다: 고객사는 걸린
#    접수 건이 하나도 없어야 지워지므로, 앞의 둘이 치운 결과가 마지막 회차가
#    보는 참조 수에 이미 반영돼 있다.
#
# 🔴 **하나가 실패해도 나머지는 돈다.** purge() 안에서 종료 코드를 받아 FAIL 에
#    모을 뿐, 어디서도 빠져나가지 않는다(set -e 를 쓰지 않는 까닭이 이것이다).
#    대신 하나라도 실패하면 맨 아래에서 종료 코드 1 로 끝난다 — DSM 작업
#    스케줄러가 그것으로 "비정상 종료"를 표시한다.
FAIL=0
RCS=""
TOTAL_PURGED=0
TOTAL_ERRORED=0
OUT=$D/setup/logs/.purge-$STAMP.out

purge() { # $1 = 보여 줄 이름, $2 = npm 스크립트
  echo "── $1"
  "$DOCKER" compose \
    -f "$D/deploy/docker-compose.nas.yml" \
    --env-file "$D/deploy/.env.nas" \
    --profile tools \
    run --rm tools-as npm run "$2" > "$OUT" 2>&1
  local rc=$?

  # 🔴 스크립트가 찍는 줄(eligible · purged · skipped … · errored)을 삼키지
  #    않는다. 그대로 로그에 남아야 "그날 밤 무엇이 몇 건 사라졌는지"를
  #    나중에 알 수 있다 — 지워진 뒤에는 이 로그 말고 확인할 곳이 없다.
  cat "$OUT"

  local p e
  p=$(grep -E '^[[:space:]]+purged:' "$OUT" 2>/dev/null | awk '{s += $2} END {print s + 0}')
  e=$(grep -E '^[[:space:]]+errored:' "$OUT" 2>/dev/null | awk '{s += $2} END {print s + 0}')
  TOTAL_PURGED=$((TOTAL_PURGED + p))
  TOTAL_ERRORED=$((TOTAL_ERRORED + e))

  if [ "$rc" = 0 ]; then
    echo "  ✓ $1 · 지움 $p 건"
  else
    echo "  ✗ $1 — 종료 코드 $rc · 지움 $p 건 · 오류 $e 건"
    FAIL=1
    RCS="$RCS $2=$rc"
  fi
  echo
}

purge "수리 건"     purge:repair-cases
purge "진단 순서도" purge:flowcharts
purge "기준정보 · PO(내자·견적서)" purge:master-data

rm -f "$OUT"

# ── 정리 · 결과 ────────────────────────────────────────────────────────
# 오래된 기록은 날짜가 아니라 개수로 지운다. 작업이 몇 주 멈춰도 마지막
# 기록들은 남는다(야간 백업·교정 알림과 같은 규칙).
ls -1t "$D/setup/logs"/purge-*.log 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f

echo "── 합계 · 영구 삭제 $TOTAL_PURGED 건 · 개별 오류 $TOTAL_ERRORED 건"
if [ "$FAIL" = 0 ]; then
  echo "── 성공 · $((SECONDS - T0))초"
  exit 0
else
  echo "── 실패가 있다 ($RCS) · $((SECONDS - T0))초 — 위 ✗ 줄을 볼 것"
  echo "   나머지 회차는 그래도 전부 돌렸다. 같은 줄이 며칠 반복되면 사람이"
  echo "   손봐야 한다는 뜻이다."
  exit 1
fi
