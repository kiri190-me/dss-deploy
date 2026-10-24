#!/bin/bash
# /volume1/dss/jobs/purge-nightly.sh — A/S 휴지통 15일 완전삭제 · 포털 만료행 정리
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
# ── 무엇을 지우나 ① A/S(+PO) 휴지통 · tools-as 세 회차 ────────────────
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
# ── 무엇을 지우나 ② 포털 다 쓴 행 · tools-auth 한 회차 (2026-10-25 더함) ──
# dss-auth 의 scripts/purge-expired.ts 가 dss_auth DB 의 다섯 표를 훑는다.
# 남기는 기간과 그 근거는 그 저장소 src/lib/db/retention.ts 에 있다 — 아래는
# 그 파일을 읽어 옮긴 것이다(2026-10-25 실측).
#
#   authorization_codes      만료 후 7일      consumedAt 표시가 남아 있어야 재사용
#                                             공격과 단순 오타를 구분할 수 있다
#   access_tokens            만료 후 7일      인가 코드와 같은 기간 — 한 사건(코드
#                                             재사용 → 토큰 폐기)이 두 표에 걸쳐
#                                             남으므로 한쪽만 먼저 사라지면 안 된다
#   sso_sessions             만료·폐기 후 30일
#   audit_logs               🔴 **3년**       ← 이 한 줄이 이 회차를 더한 까닭이다
#   notification_dismissals  지운 뒤 하루     본래 길은 로그아웃이라 평소엔 0건.
#                                             창만 닫고 간 경우를 걷는다
#
# 🔴 **감사 로그 3년을 집행하는 코드는 저것 하나뿐이다.** 스키마 주석과 보안
#    정책 문서가 「3년 보관」을 선언해 두었는데, 그 코드를 부를 길이 없어
#    2026-10-25 까지 **한 번도 돈 적이 없었다** — 실제로는 영구 보관이었고
#    source_ip·user_agent 를 의도보다 오래 들고 있었다. 이 회차가 그 빠진 자리다.
#
# 🔵 바로 위 ① 의 audit_logs 와 **다른 표다.** ① 은 A/S(dss_as)에 PURGE 기록을
#    **남기는** 쪽이고, 여기 적힌 audit_logs 는 포털(dss_auth)의 것을 **지우는**
#    쪽이다. 이름만 같고 DB 도 상자도 다르다.
#
# 🔵 ① 과 달리 이쪽은 휴지통이 아니라 **수명이 다한 행**이다. 사람이 「지운」
#    것이 아니라 되살려 달라는 요청이 올 일은 없다. 그래도 DELETE 이므로
#    문지기는 똑같이 씌운다(아래).
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
# 🔴 **포털 쪽은 다르다 — purge-expired.ts 는 --dry-run 을 받는다**
#    (그 파일 33줄 process.argv.includes("--dry-run"), 2026-10-25 실측).
#    위 세 줄을 포털에도 그대로 믿지 말라는 뜻이다. 다만 **이 야간 작업에서는
#    붙이지 않는다** — 붙이면 세기만 하고 한 건도 안 지운다. 미리 보고 싶으면
#    사람이 손으로 한 번 돌린다(조회 전용):
#
#     /usr/local/bin/docker compose -f /volume1/dss/deploy/docker-compose.nas.yml \
#       --env-file /volume1/dss/deploy/.env.nas --profile tools \
#       run --rm tools-auth node --import tsx scripts/purge-expired.ts --dry-run
#
# ── 🔴 야간 백업(02:30)보다 뒤에 돌아야 하는 까닭 ──────────────────────
# 이 작업은 **되돌릴 수 없다.** 휴지통으로 옮기는 것이 아니라 DELETE 다. 잘못
# 지워진 것을 되살릴 길은 그날 백업뿐이다. 그래서 둘을 건다:
#   1. 백업 02:30 → 완전삭제 **03:30**. 지우기 전의 상태가 반드시 덤프에 남는다.
#   2. 아래 문지기가 **오늘 날짜의 dss_as 덤프가 있는지 먼저 본다.** 없으면
#      한 건도 지우지 않고 종료 코드 2 로 멈춘다. 백업이 조용히 죽어 있는 채로
#      며칠이 지나면(이남준 님 PC 에서 2주간 실제로 일어난 일 —
#      backup-nightly.sh 머리말) 안전망 없이 영구 삭제만 계속 도는 셈이 된다.
#   3. 포털 회차에도 같은 문지기를 씌운다 — **오늘 날짜의 dss_auth 덤프**를
#      본다. 야간 백업이 그 DB 도 이미 뜨고 있어(backup-nightly.sh 의
#      `dump dss-pg-auth dss_auth_app dss_auth`) 파일 이름 모양이 dss_as 와
#      똑같다. 더 받을 백업도, 새로 만들 규칙도 없다.
#
# 🔴 **다만 두 문지기를 한 덩어리로 묶지 않았다.** 묶으면 포털 덤프 하나가
#    없는 날 A/S 셋까지 멈춘다 — 2026-09-29 부터 제 일을 하고 있는 것을
#    세우는 쪽이 손해다. 반대도 같다. 그래서 이렇게 갈라 둔다:
#      · dss_as 덤프가 없다   → 지금까지대로 **전부 멈추고 종료 코드 2**
#      · dss_as 는 있는데
#        dss_auth 만 없다     → A/S 셋은 **그대로 돌고** 포털 회차만 건너뛴다.
#                               건너뛴 사실을 로그에 적고 종료 코드 **1** 로
#                               끝낸다(사람이 봐야 한다는 뜻). 포털 쪽은 하루
#                               밀려도 지장이 없다 — 3년 보관에서 하루는
#                               의미가 없고, 다음 날 밤에 함께 걷힌다.
#
# ── 종료 코드 ──────────────────────────────────────────────────────────
#   0  네 회차 다 정상 (A/S 셋 + 포털 하나)
#   1  하나 이상 실패했거나 **포털 회차를 건너뛰었다** (나머지는 다 돌렸다)
#   2  🔴 문지기가 막았다 — 오늘 dss_as 덤프가 없어 **아무것도 지우지 않았다**
#
# ⚠️ 도구 컨테이너 tools-as · tools-auth 는 profiles: [tools] 라 `up -d` 로는
#    뜨지 않는다. 여기서 `run --rm` 으로 부를 때만 잠깐 떴다 사라진다 — 상시
#    서비스가 아니므로 메모리 예산 2.7GB 를 건드리지 않는다. 🔵 둘을 동시에
#    띄우지 않는다. 차례로 도니 한 번에 하나뿐이다.
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
echo "DSS 야간 정리 · A/S 휴지통 완전삭제 + 포털 만료행 · $(date '+%F %T')"
echo

# ── 🔴 문지기 — 오늘 백업이 없는 쪽은 안 지운다 ────────────────────────
# backup-nightly.sh 가 $B/db/dss_as_<날짜>_<시각>.dump 로 남긴다. 그 파일은
# .part 로 쓰고 pg_restore -l 로 열어 본 뒤에만 제 이름을 받으므로, 이 이름이
# 있다는 것 자체가 "열리는 덤프가 오늘 남았다"는 뜻이다(빈 파일·깨진 파일은
# 애초에 이 이름을 못 얻는다). 그래도 -s 로 한 번 더 본다.
# 🔵 포털 몫(dss_auth)도 같은 함수가 같은 규칙으로 남기므로 이름 모양이 똑같다.
#    다만 **막는 범위가 다르다** — dss_as 는 전부, dss_auth 는 포털 회차만.
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

# 🔴 포털 몫 문지기는 **따로** 본다. 같은 규칙(오늘 날짜 · -s)으로 dss_auth
#    덤프를 찾되, 없어도 여기서 멈추지 않는다 — 위 머리말에 적은 대로 포털
#    덤프 하나 때문에 A/S 셋을 세우지 않는다. 대신 아래에서 포털 회차만
#    건너뛰고 종료 코드 1 로 끝낸다.
# 🔵 빈 파일이면 이름은 잡히고 -s 가 거짓이 된다. 그때 DUMP_AUTH 를 비워 두어
#    아래 판정을 `[ -n "$DUMP_AUTH" ]` 하나로 끝낸다 — 두 군데서 같은 조건을
#    다시 적으면 한쪽만 고치는 사고가 난다.
DUMP_AUTH=$(ls -1t "$B/db/dss_auth_${TODAY}"_*.dump 2>/dev/null | head -1)
if [ -n "$DUMP_AUTH" ] && [ -s "$DUMP_AUTH" ]; then
  echo "  ✓ $(basename "$DUMP_AUTH") · $(du -h "$DUMP_AUTH" | cut -f1)"
else
  DUMP_AUTH=""
  echo "  ✗ 오늘 날짜의 dss_auth 덤프가 $B/db 에 없다 — **포털 회차만** 건너뛴다."
  echo "    (A/S 셋은 그대로 돈다. 아래 포털 자리와 종료 코드를 볼 것)"
fi
echo

# ── 넷을 차례로 ────────────────────────────────────────────────────────
# 🔴 **차례로만 돌린다. 절대 동시에 돌리지 않는다**(run-nightly-purge.ps1 이
#    정해 둔 규칙). 순서는 수리 건 → 진단 순서도 → 기준정보다. 안전 때문은
#    아니다 — 세 회차 모두 각자의 트랜잭션 안에서 행을 잠그고 자격을 다시
#    판정하므로 어느 순서든 안전하다. 로그가 읽히기 때문이다: 고객사는 걸린
#    접수 건이 하나도 없어야 지워지므로, 앞의 둘이 치운 결과가 마지막 회차가
#    보는 참조 수에 이미 반영돼 있다.
#
# 🔴 **포털은 넷째 — 맨 뒤다.** DB 도 상자도 달라 A/S 셋과 아무 의존이 없으니
#    순서에 안전상의 뜻은 없다. 뒤에 두는 까닭은 하나다: 한 달 가까이 제 일을
#    하고 있는 셋이 **먼저 끝나 있어야** 한다. 새로 더한 회차가 오래 걸리거나
#    죽더라도 그때는 이미 A/S 쪽이 다 끝난 뒤다.
#
# 🔴 **하나가 실패해도 나머지는 돈다.** purge()·purge_auth() 안에서 종료 코드를
#    받아 FAIL 에 모을 뿐, 어디서도 빠져나가지 않는다(set -e 를 쓰지 않는
#    까닭이 이것이다). 대신 하나라도 실패하면 맨 아래에서 종료 코드 1 로
#    끝난다 — DSM 작업 스케줄러가 그것으로 "비정상 종료"를 표시한다.
FAIL=0
RCS=""
TOTAL_PURGED=0
TOTAL_ERRORED=0
# 포털 몫은 **따로 센다.** A/S 쪽 TOTAL_PURGED 에 합치면 「휴지통에서 영구히
# 사라진 건수」라는 뜻이 흐려진다 — 그 숫자는 전날 trash-status.sh 의
# 「기한지남」과 맞대어 보는 값이라(runbook/12 의 점검표), 다른 성질의 건수가
# 섞이면 그 대조가 영영 안 맞는다.
AUTH_PURGED=0
AUTH_RAN=0
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

# 🔴 포털은 위 purge() 를 **못 쓴다.** 세 군데가 다르기 때문이다 — 셋 다
#    「조금 다름」이 아니라 「그대로 쓰면 조용히 틀림」이라 함수를 따로 뒀다.
#    (위 purge() 를 깃발 받는 함수로 고치지 않은 까닭도 이것이다. 세 가지가
#     동시에 갈리면 깃발이 셋 붙고, 그러면 한 달 가까이 제 일을 하고 있는
#     A/S 셋의 차례까지 함께 흔들린다. 더하는 변경은 더하기만 한다 —
#     backup-nightly.sh 가 게시판·재고를 더할 때 적어 둔 그 까닭 그대로다.)
#
#   ① 서비스 이름이 tools-as 가 아니라 **tools-auth** 다.
#
#   ② **npm run 을 거치지 않는다.** dss-auth/package.json 의 db:purge 는
#      `node --env-file=.env.local --import tsx scripts/purge-expired.ts` 인데,
#      컨테이너에는 .env.local 이 없어 그 줄에서 바로 죽는다. 컨테이너에는
#      환경변수(DATABASE_URL)가 compose 로 이미 들어와 있으므로 파일 없이
#      스크립트를 직접 부른다. 이 우회법은 그 저장소 Dockerfile 의 tools
#      스테이지 주석에 적혀 있고, 거기서 scripts/ 를 일부러 담는다.
#      🔵 --conditions=react-server 는 붙이지 않는다 — 원래 db:purge 줄에도
#         없고, 이 스크립트가 타는 모듈에 server-only 가 없다.
#
#   ③ **출력 형식이 다르다.** A/S 쪽은 `  purged: 3` 꼴로 찍지만 포털은 표를
#      그린 뒤 마지막에 `  합계 37건을 지웠습니다.` 또는
#      `  정리할 것이 없습니다.` 한 줄로 끝낸다. 🔴 위 purge() 의
#      `grep '^[[:space:]]+purged:'` 로 세면 **한 줄도 안 걸려 늘 0** 이다 —
#      오류 없이 「지움 0건」이라고 거짓말한다. 그래서 세는 규칙을 갈랐다.
#      🔵 포털은 errored: 를 아예 안 찍는다. 실패는 종료 코드로만 드러난다
#         (purge-expired.ts 가 catch 에서 process.exitCode = 1 을 둔다).
purge_auth() {
  echo "── 포털 · 다 쓴 행 정리 (감사 로그 3년 포함)"
  "$DOCKER" compose \
    -f "$D/deploy/docker-compose.nas.yml" \
    --env-file "$D/deploy/.env.nas" \
    --profile tools \
    run --rm tools-auth node --import tsx scripts/purge-expired.ts > "$OUT" 2>&1
  local rc=$?

  # A/S 쪽과 같은 까닭으로 출력을 삼키지 않는다. 표마다 몇 건이 사라졌는지는
  # 지워진 뒤에 이 로그 말고 확인할 곳이 없다.
  cat "$OUT"
  AUTH_RAN=1

  # 🔴 「합계 N건을 지웠습니다.」에서 N 을 뽑는다. 필드 둘째가 "37건을" 처럼
  #    숫자에 한글이 붙어 오므로 숫자 뒤를 잘라 낸다 — awk 의 암묵 변환에
  #    기대지 않는다(NAS 의 awk 가 busybox 판으로 바뀌어도 같게 돌도록).
  #    「정리할 것이 없습니다.」일 때는 한 줄도 안 걸려 0 이 된다 — 그것이 맞다.
  local p
  p=$(grep -E '^[[:space:]]*합계 [0-9]+건을 지웠습니다' "$OUT" 2>/dev/null \
      | awk '{n = $2; sub(/[^0-9].*/, "", n); s += n} END {print s + 0}')
  AUTH_PURGED=$((AUTH_PURGED + p))

  if [ "$rc" != 0 ]; then
    echo "  ✗ 포털 — 종료 코드 $rc · 지움 $p 건"
    FAIL=1
    RCS="$RCS purge-expired=$rc"
  elif ! grep -qE '^[[:space:]]*(합계 [0-9]+건을 지웠습니다|정리할 것이 없습니다)' "$OUT"; then
    # 🔴 **0 건을 그냥 믿지 않는다.** 저쪽이 마무리 문구를 바꾸면 위 grep 이
    #    조용히 한 줄도 못 찾고, 그러면 수천 건을 지우고도 「지움 0건 · 성공」
    #    이라고 적힌다. 둘 중 하나는 반드시 찍히는 문구이므로, 둘 다 없으면
    #    건수를 셀 수 없었다는 뜻이다 — 사람이 봐야 한다.
    echo "  ✗ 포털 — 돌긴 돌았는데(종료 코드 0) 마무리 줄을 못 찾았다."
    echo "     위 출력을 그대로 보고, 세는 규칙을 purge_auth() 에서 맞출 것."
    echo "     🔴 지움 건수 $p 은 믿을 수 없다(실제로는 더 지워졌을 수 있다)."
    FAIL=1
    RCS="$RCS purge-expired=출력형식"
  else
    echo "  ✓ 포털 · 지움 $p 건"
  fi
  echo
}

purge "수리 건"     purge:repair-cases
purge "진단 순서도" purge:flowcharts
purge "기준정보 · PO(내자·견적서)" purge:master-data

# 🔴 넷째. 오늘 dss_auth 덤프가 없으면 **이 회차만** 건너뛴다 — 위 셋은 이미
#    다 돌았고 그것을 되돌리지 않는다.
if [ -n "$DUMP_AUTH" ]; then
  purge_auth
else
  echo "── 포털 · 다 쓴 행 정리 (감사 로그 3년 포함)"
  echo "  🔴 건너뜀 — 오늘($TODAY) dss_auth 덤프가 없다(위 문지기 참고)."
  echo "     포털 정리도 되돌릴 수 없는 DELETE 라, 그날 백업 없이는 돌리지"
  echo "     않는다. 즉 **감사 로그 3년 보관이 오늘 밤에는 집행되지 않았다.**"
  echo "     A/S 셋은 그대로 다 돌렸다."
  echo
  echo "     할 일:  bash $D/jobs/backup-nightly.sh   (왜 안 떴는지도 함께 본다)"
  echo "             bash $D/jobs/purge-nightly.sh    그 뒤 이 작업을 다시"
  echo "     🔵 하루 밀려도 지장은 없다 — 다음 날 밤에 함께 걷힌다."
  echo
  FAIL=1
  RCS="$RCS purge-expired=건너뜀"
fi

rm -f "$OUT"

# ── 정리 · 결과 ────────────────────────────────────────────────────────
# 오래된 기록은 날짜가 아니라 개수로 지운다. 작업이 몇 주 멈춰도 마지막
# 기록들은 남는다(야간 백업·교정 알림과 같은 규칙).
ls -1t "$D/setup/logs"/purge-*.log 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f

# 🔵 앞의 「영구 삭제 N 건 · 개별 오류 N 건」은 **글자 그대로 둔다.** 배포 검사
#    (setup/15·17·24…-deploy.sh)와 runbook/12 의 점검표가 사람에게 그 문구를
#    보라고 적어 두었고, 그 숫자는 전날 trash-status.sh 의 「기한지남」과 맞대는
#    값이다. 포털 몫은 **뒤에 덧붙인다** — 고치지 않고 더하기만 한다.
if [ "$AUTH_RAN" = 1 ]; then
  echo "── 합계 · 영구 삭제 $TOTAL_PURGED 건 · 개별 오류 $TOTAL_ERRORED 건 · 포털 만료행 $AUTH_PURGED 건"
else
  echo "── 합계 · 영구 삭제 $TOTAL_PURGED 건 · 개별 오류 $TOTAL_ERRORED 건 · 포털 만료행 건너뜀"
fi
if [ "$FAIL" = 0 ]; then
  echo "── 성공 · $((SECONDS - T0))초"
  exit 0
else
  echo "── 실패가 있다 ($RCS) · $((SECONDS - T0))초 — 위 ✗ 줄을 볼 것"
  echo "   건너뛴 회차 말고는 그래도 전부 돌렸다. 같은 줄이 며칠 반복되면"
  echo "   사람이 손봐야 한다는 뜻이다."
  exit 1
fi
