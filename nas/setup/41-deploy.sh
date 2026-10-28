#!/bin/bash
# dss-deploy/nas/setup/41-deploy.sh — 서른여덟째 배포 (2026-10-28)
#
# 🔴 NAS 에서 돈다. DSM 터미널은 긴 명령을 잘라 먹으므로 **파일로 올려** 돌린다.
#    md5 를 맞춘다:  md5sum /volume1/dss/setup/41-deploy.sh
#
# ── 사람이 실행한다 ───────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/41-deploy.sh            ← 읽기만 한다
#   (NAS)         bash /volume1/dss/setup/41-deploy.sh --preload
#   (NAS)         bash /volume1/dss/setup/41-deploy.sh --go       ⏱ 정지 창
#
# ── 갈아 끼우는 것 — **저장소 하나, 태그 둘** ──────────────────────────
#     ① A/S 앱   dss-as:3.3        → **dss-as:3.4**        커밋 5
#     ② A/S 도구 dss-as-tools:1    → **dss-as-tools:2**    커밋 5
#
#   🔴 **마이그레이션이 없다.** A/S 의 drizzle/ 이 기준 SHA 이후 0건이다. 그래서
#      이 파일에는 **--migrate 모드가 없다** — DB 를 건드리는 단계가 한 군데도 없다.
#   🔵 **나머지 아홉은 안 건드린다** — 통합 로그인 2.0 · PO 0.7 · 재고 0.6 ·
#      게시판 0.3 · 계측기 1.4 · 개선요청 0.5 · RF 이슈관리 0.3 · 휴가 0.4 ·
#      통합 승인함 0.1 은 기준 SHA 이후 커밋이 **0** 이다(2026-10-28 실측).
#
# ── 이 배포가 하는 일 ─────────────────────────────────────────────────
#   **연락서·보고서·파일관리 쪽 다섯 커밋.** 보고서 휴지통에 완전 삭제가
#   생기고(개발자 표시가 켜진 사람에게만 보인다), 연락서 이식의 부품 이름을
#   품번 칸에서 읽어 사용 부품에 **덮어쓰며**(재고관리에 요청 흔적이 있으면
#   한 줄도 안 넣는다), 출하 완료된 건의 파일관리에서도 올리기·휴지통·
#   되살리기·사진 회전이 된다. 그리고 **A/S 도구에 새 명령 하나가 늘었다**
#   (check:part-name-overlap — 사용 부품 이름이 재고관리 부품명과 얼마나
#   겹치는지 재는, 읽기만 하는 점검 도구).
#
# ── 🔴 A/S 도구를 왜 올리는가 — 이번엔 **「늘었다」**이지 **「바뀌었다」**가
#    아니다 ────────────────────────────────────────────────────────────
#   🔵 **서른여섯째**: 「마이그레이션 0건이니 도구는 안 굽는다」 → **틀렸다**
#      (비상구 둘이 못 쓰는 채였다).
#   🔵 **서른일곱째**: 「그 도구가 실제로 부르는 명령이 바뀌었는가」로 판정해
#      안 구웠다 → **맞았다**(db:migrate·db:preflight 둘 다 볼륨만 읽는다).
#   🔴 **이번엔 그 잣대로도 안 걸린다** — 부르는 명령이 바뀐 게 아니라
#      'package.json' 의 'scripts' 에 **'check:part-name-overlap' 한 줄이
#      늘었다.** 그것이 운영에서 부를 새 명령이고, 이미지를 안 올리면
#      'npm error Missing script' 가 난다(2026-10-28 실측).
#   🔵 **잣대를 다시 고쳐 적는다** — 「바뀌었나」가 아니라 **「늘거나 줄었나」**다.
#
#   올린 뒤 쓰는 분이 돌려 볼 길(쓸 일이 생긴 날 — 읽기만 한다, DB 를 안 바꾼다):
#     cd /volume1/dss/deploy
#     /usr/local/bin/docker compose -f docker-compose.nas.yml --env-file .env.nas \
#       --profile tools run --rm tools-as npm run check:part-name-overlap
#   🔴 **도구를 새로 올린 뒤에만** 된다 — 그것이 이번에 도구를 올리는 까닭이다.
#   🔴 **재고 관리가 떠 있어야** 뜻이 있는 수가 나온다(그 도구가 재고 관리의
#      GET /api/v1/parts 를 두드린다). 재고 관리가 멈춰 있으면 도구가 「못
#      물어봤다」로 끝난다 — 오류가 아니라 그 도구의 설계다.
#
# ── 🔴 이번 배포에서 **동작이 바뀌는 자리 넷** — 쓰는 분이 눈으로 볼 곳 ──
#   ① **보고서 휴지통에 [완전 삭제]** — 🔵 **개발자 표시가 켜진 사람에게만**
#      보인다. 꺼진 계정에서는 그 단추 자체가 없어야 맞다.
#   ② **보고서 [지우기] → [휴지통으로 보내기]** — 0.5초 안내가 뜬 뒤 목록으로
#      넘어간다.
#   ③ **연락서 이식의 부품 이름이 품번으로** 바뀐다(예: SCV-255P110 꼴). 그리고
#      사용 부품에 **덮어쓴다** — 먼저 있던 줄이 사라진다. 🔴 **재고관리에 부품
#      요청 흔적이 있는 건에는 한 줄도 안 넣는다.**
#   ④ **출하 완료된 건의 [파일관리]** — 올리기·휴지통·되살리기·**사진 회전**이
#      된다. 🔴 회전은 **되돌릴 수 없는 덮어쓰기**다.
#
# ── 🔴 ②-보조: 재고 관리가 꺼져 있으면 연락서 이식이 막힌다 ────────────
#   부품이 든 연락서를 넣을 때 **재고관리에 요청 흔적을 물어본다.** 못 물어보면
#   막는다(「없다」로 바꾸지 않기로 한 결정). 🔵 아래 7절이 재고관리 컨테이너가
#   계속 도는지(KEEP_BOXES) 재지만, **배포 직후에는 쓰는 분이 재고관리 화면이
#   떠 있는지 직접 한 번 더 보는 것이 안전하다.**
#
# ── 🔴 40번(지난 판)과 다른 것 ─────────────────────────────────────────
#   ① 저장소 하나(A/S)뿐이지만 **태그는 둘** 바뀐다 — 앱 하나 + 도구 하나.
#      40번은 저장소 둘(A/S · RF 이슈관리)에 이미지도 둘(둘 다 앱)이었고
#      도구는 손대지 않았다. 이번엔 반대로 **저장소는 하나, 도구를 더 올린다.**
#   ② 🔴 **다시 띄우는 것은 app-as 하나뿐이다.** tools-as 는 'profiles: [tools]'
#      라 평소에 뜨지 않는 서비스다 — compose 의 태그만 새 것으로 고쳐 두면
#      다음에 'run --rm tools-as' 로 부를 때 새 이미지를 쓴다. **up -d 로
#      띄우지 않는다** — 띄우려 하면 프로필이 안 걸려 있어 compose 가 그 서비스를
#      모르는 것으로 다룬다.
#   ③ 🔵 **--rollback 은 앱만 되돌린다.** 도구는 :2 그대로 둔다 — 39번이 포털
#      도구에서 쓴 것과 같은 판단이다(판에 매이지 않고, 새 점검 도구가 있는
#      편이 낫다. 되돌릴 일이 생겨도 이 도구가 DB 를 쓰는 길은 읽기뿐이다).
#   ④ 🔴 **공유폴더·리버스 프록시 검사가 없다** — 그것은 40번의 RF 이슈관리
#      전용 검사였다(이번엔 그 저장소를 안 건드린다).
#   ⑤ 🔵 RF_Service_System 의 Dockerfile 은 tools 스테이지를 runner **앞에**
#      둔다 — --target 없이 구우면 마지막 스테이지(runner)가 기본값이 된다.
#      이 함정은 41-build.sh 쪽 이야기지만, 그 결과(올바른 tools 이미지)가
#      맞게 왔는지는 이 파일의 3절이 다시 센다.
#
# ── 🔴 개발 PC → NAS 로 올릴 것 — **셋** (마이그레이션 묶음이 없다) ─────
#   ㄱ) 이미지 tar **둘** → /volume1/dss/images/
#        dss-as-3.4.tar · dss-as-tools-2.tar
#   ㄴ) 이 파일 → /volume1/dss/setup/
#
#   (개발 PC · PowerShell)
#     cd C:\Users\희만\Desktop\Development\_images-38
#     scp -O dss-as-3.4.tar dss-as-tools-2.tar dss-nas:/volume1/dss/images/
#     cd C:\Users\희만\Desktop\Development
#     scp -O dss-deploy\nas\setup\41-deploy.sh dss-nas:/volume1/dss/setup/
#     Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\41-deploy.sh
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#   🔴 tar 에 드라이브 문자(C:)를 주지 마세요 — 원격 호스트로 읽습니다.
#
# ── 모드 넷 ───────────────────────────────────────────────────────────
#   (기본)   --check      아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --preload             tar 둘을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --go                  compose 의 image: 줄 둘(app-as·tools-as)을 바꾸고
#                         app-as 만 다시 띄운다
#   --rollback            app-as 만 옛 판으로 되돌린다 (도구는 :2 그대로)
#
#   🔴 차례:  --check → --preload → --check → --go
#
# ── 🔴 --check 도 「아무것도 안 한다」는 아니다 ───────────────────────
#   A/S DB 에 **select** 를 한 번 보낸다(마이그레이션 수가 그대로인지 — 바꾸는
#   문장은 없다). 앱의 바깥 주소에 GET 을 한 번 보낸다. 도구 이미지가 이미
#   실려 있으면 **안을 보려고 컨테이너를 잠깐 띄웠다 지운다**(docker run --rm,
#   DB 에는 안 닿는다 — DATABASE_URL 을 안 주고 부른다).
#   「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 쓴 뒤 세었다.
#   ② 읽기 전용 자리에 콜론 하나와 꺾쇠로 빈 파일을 만들면 NAS 의 ash 가 셸을
#      그 자리에서 끝낸다(2026-10-12 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#
# ── 🔴 비밀값을 찍지 않는다 ───────────────────────────────────────────
#   .env 는 **이름이 있는가/없는가**만 본다. 값도, 값의 길이도 찍지 않는다.
#   이번 판에는 새로 필요한 설정 이름이 없다.
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v38-$STAMP

# ══ 이번에 다시 띄우는 것 — 앱 하나뿐이다 ═════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
SITES='
as|app-as|dss-as|dss-as:3.4|dss-as:3.3|dss-as-3.4.tar|13000
'
# ══ 🔴 A/S 도구 — **이번에 갈아 끼운다.** up -d 로 다시 띄우지 않는다 ═══
#   (profiles: [tools] 라 평소에 뜨지 않는다. compose 의 태그만 고치면
#    다음에 run --rm tools-as 로 부를 때 새 이미지를 쓴다.)
AS_TOOLS_SVC=tools-as
TOOLS_OLD=dss-as-tools:1
TOOLS_NEW=dss-as-tools:2
IMG_MIGDIR=/app/drizzle
MIGDIR=$D/as-migrations

# ══ 🔴 tar 둘의 지문 — [배포본] 41-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 비어 있다.** 41-build.sh --go 가 끝에 찍어 주는 두 줄을 여기에
#      그대로 붙여 넣는다. 비어 있으면 3절이 **? 로 센다** — 「옮기다 깨진
#      것」은 잡지만 「개발 PC 에서 구운 그것이 맞나」는 못 본다.
TARS='
dss-as-3.4.tar|132320768|864994f22e82251bc9bed923e102dd5b|sha256:6ab586a721b88d9eef97818b89c7fdac147fa4c2c005343b4d338c183b11fac7
dss-as-tools-2.tar|223557120|e7a0a6ddfbdb560276d83be34ea82d2a|sha256:ef64f0d8f13dc0ed9821e8f1c84fa618ea68be7ad4f91efeaea2b33c6beca4df
'
tar2tag() {
  case "$1" in
    dss-as-3.4.tar)      printf 'dss-as:3.4' ;;
    dss-as-tools-2.tar)  printf 'dss-as-tools:2' ;;
  esac
}

# ══ 🔴 A/S — DB 는 **그대로여야** 한다(마이그레이션 0건) ═════════════
AS_BOX=dss-pg-app; AS_DB=dss_as; AS_KEEP=121   # [저장소] 41-build.sh 4절과 같다
# 🔵 안 건드리는 아홉 — 「옆으로 안 샜다」는 증거로 센다
KEEP_BOXES="dss-auth dss-inventory dss-meters dss-po dss-board dss-improvements dss-leave dss-approvals dss-rf-trouble"
# 🔵 DB 둘은 멈추지 않는다 (애초에 up -d --no-deps 가 app-as 하나만 건드린다)
KEEP_DB="dss-pg-app dss-pg-auth"

MODE=check
case "${1:-}" in
  --check|"")  MODE=check ;;
  --preload)   MODE=preload ;;
  --go)        MODE=go ;;
  --rollback)  MODE=rollback ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --preload · --go · --rollback\n' "$1"; exit 2 ;;
esac

PASS=0; FAIL=0; WARN=0
ok()  { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
hm()  { WARN=$((WARN+1)); printf '  ? %s\n' "$1"; }
say() { printf '    %s\n' "$1"; }
cmd() { printf '      %s\n' "$1"; }
# 🔴 ✗ 가 났을 때 그 자리에서 찍는다 — 처음 도는 코드라 기대값이 틀릴 확률이
#    배포만큼 높다. ✓ 쪽 오판은 영영 안 드러나므로 ✗ 쪽을 크게 적는다.
doubt() { say "🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 이 줄의 기대값이"
          say "   어디서 왔는지는 파일 머리의 기대값 표에 적혀 있습니다."; }

isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }
rows()  { printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'; }
trows() { printf '%s\n' "$TARS"  | tr -d ' ' | grep -v '^$'; }
fld()   { printf '%s' "$1" | cut -d'|' -f"$2"; }

dc()  { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas "$@" ); }
dct() { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas --profile tools "$@" ); }

[ "$(id -u)" = 0 ] || { printf '먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요.\n'; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/41-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "서른여덟째 배포 — A/S 앱 · A/S 도구   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  로그: $LOG"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 공통: compose 에서 그 서비스의 image: 줄을 찾는다 ─────────────────
# 🔴 그 블록 안의 것 하나만 고쳐야 한다. 서비스 머리부터 다음 서비스 머리 전까지.
img_line() { # 1 서비스
  local s start next
  s=$1
  start=$(grep -n "^  ${s}:" "$CF" | head -1 | cut -d: -f1)
  [ -n "$start" ] || return 1
  next=$(awk -v s="$start" 'NR>s && /^  [a-z]/ {print NR; exit}' "$CF")
  awk -v s="$start" -v e="${next:-999999}" 'NR>s && NR<e && /^[[:space:]]*image:/ {print NR; exit}' "$CF"
}
tag_at() { awk -v n="$1" 'NR==n {print $2}' "$CF"; }
svc_block() { # 1 서비스 — 주석 줄은 뗀다
  awk -v s="  $1:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$CF" | sed '/^[[:space:]]*#/d'
}

# 🔴 운영 DB 를 **앱이 쓰는 길**(컨테이너 안 psql)로 잰다. 소켓·루프백으로 재면
#    trust 라 그냥 통과한다. 보내는 SQL 은 select 뿐이다.
pgq() { # 1 상자 2 DB 3 SQL
  "$DOCKER" exec -i "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -X -tAq -c \"$3\"" 2>/dev/null | head -1 | tr -d ' \r'
}
pgn() { local v; v=$(pgq "$1" "$2" "$3"); isnum "$v" && printf '%s' "$v"; }
mig_count() { pgn "$1" "$2" 'select count(*) from drizzle.__drizzle_migrations'; }

# ══ 🔴 A/S 도구 이미지 **안**을 센다 — 겉이 아니라 결과 ══════════════
#   🔴 --target tools 를 빠뜨렸으면 runner 가 구워지고, 그 안에는 scripts/ 도
#      package.json 도 없다. 이미지는 멀쩡히 실리고 오류가 안 난다. 증상은
#      **쓸 일이 생긴 날**의 「Missing script」한 줄뿐이다. 그래서 여기서 센다.
#   🔵 명령을 **부르되 DATABASE_URL 을 안 준다** — DB 에 안 닿고, npm 이 그
#      명령을 찾아 node 까지 실행했는지만 값으로 본다.
tools_inside_check() {
  local v
  printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TOOLS_NEW"
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/package.json: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "tools 스테이지가 맞다" \
    || { bad "🔴 /app/package.json 이 없다 — **runner 를 구웠다.**"; doubt; }
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -f /app/scripts/check-part-name-overlap.ts && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/scripts/check-part-name-overlap.ts: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "새 점검 파일이 들어 있다" \
    || bad "🔴 새 점검 파일이 없다 — scripts/ 가 안 담겼다"
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "grep -cF '\"check:part-name-overlap\":' /app/package.json" 2>/dev/null | tr -d '\r')
  say "이미지 안 package.json 의 check:part-name-overlap 줄: ${v:-0}개 (기대 1 이상)"
  isnum "${v:-}" && [ "${v:-0}" -ge 1 ] && ok "이미지 안 package.json 이 그 명령을 안다" \
    || bad "🔴 ${v:-0}개다 — 이미지 안 package.json 에 그 명령이 없다"
  v=$("$DOCKER" run --rm --entrypoint npm "$TOOLS_NEW" run check:part-name-overlap 2>&1 | tr -d '\r' | head -20)
  if printf '%s' "$v" | grep -qi 'missing script'; then
    bad "🔴 npm 이 \"Missing script\" 라 한다 — 이미지 안에 그 명령이 없다"
    printf '%s\n' "$v" | sed 's/^/      /'
  elif printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
    ok "npm 이 명령을 찾아 node 까지 실행했다 (DB 에는 안 닿고 그 자리에서 멈췄다)"
  else
    hm "예상한 둘 중 무엇도 아니다 — 아래를 사람이 보세요"
    printf '%s\n' "$v" | sed 's/^/      /'
  fi
}

# ── 1. 지금 상태 ──────────────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
[ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
say "compose 줄 수 $(wc -l < "$CF") · image: 줄 $(grep -c '^ *image:' "$CF")개"
for r in $(rows); do
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  L=$(img_line "$SVC") || { bad "$SVC — compose 에서 image: 줄을 못 찾았다"; continue; }
  CUR=$(tag_at "$L")
  ST=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  say "$SVC — ${L}줄 · compose ${CUR} · 도는 것 ${RUN:-없음} (${ST:-?})"
  if [ "$CUR" = "$OLD" ]; then ok "$SVC 가 옛 판 $OLD 다 (갈아 끼울 준비)"
  elif [ "$CUR" = "$NEW" ]; then hm "$SVC 가 이미 $NEW 다 (다시 돌리는 중인가)"
  else bad "$SVC 의 태그가 $CUR 다 — 옛 판도 새 판도 아니다. 멈추고 알릴 것"; doubt; fi
done
# 🔴 A/S 도구 — **--go 가 고친다. --rollback 은 안 건드린다**(머리말의 판단).
#    🔴 단계마다 기대값이 다르다. 한 잣대로 재면 가짜 ✗/? 가 난다.
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  say "$AS_TOOLS_SVC — ${TL}줄 · $TCUR"
  case "$MODE" in
    rollback)
      [ "$TCUR" = "$TOOLS_NEW" ] && ok "$AS_TOOLS_SVC 가 $TOOLS_NEW 다 (🔵 되돌려도 도구는 그대로 둔다)" \
        || hm "$AS_TOOLS_SVC 가 $TCUR 다 — 🔵 되돌리기를 막지 않는다" ;;
    *)
      if [ "$TCUR" = "$TOOLS_OLD" ]; then ok "$AS_TOOLS_SVC 가 $TOOLS_OLD 다 (고칠 준비 — --go 가 $TOOLS_NEW 로 고친다)"
      elif [ "$TCUR" = "$TOOLS_NEW" ]; then hm "$AS_TOOLS_SVC 가 이미 $TOOLS_NEW 다 (다시 돌리는 중인가)"
      else bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $TOOLS_OLD 도 $TOOLS_NEW 도 아니다. 멈추고 알릴 것"; doubt; fi ;;
  esac
  # 🔴 볼륨이 제 자리에 붙는가 — 여기가 어긋나면 **다음 마이그레이션이 엉뚱한 것을 읽는다.**
  if svc_block "$AS_TOOLS_SVC" | grep -q "$MIGDIR:$IMG_MIGDIR"; then
    ok "$AS_TOOLS_SVC 가 $MIGDIR 를 $IMG_MIGDIR 로 붙인다 (안 건드렸다)"
  else
    bad "🔴 $AS_TOOLS_SVC 의 drizzle 볼륨이 $MIGDIR 가 아니다 — 이 배포가 건드릴 자리가 아닌데 어긋났다"
  fi
else
  bad "compose 에 $AS_TOOLS_SVC 가 없다 — 올릴 자리가 없다"
fi

# ── 2. 🔴 A/S DB — 마이그레이션 수가 **그대로여야** 한다 ──────────────
printf '\n== 2. A/S DB — 마이그레이션 %s 그대로여야 한다\n' "$AS_KEEP"
MIG_AS0=$(mig_count "$AS_BOX" "$AS_DB")
say "A/S 기록 ${MIG_AS0:-?} (기대 $AS_KEEP 그대로)"
if [ -z "${MIG_AS0:-}" ]; then
  bad "DB 를 못 쟀다 — $AS_BOX 가 도는지 보세요"
elif [ "$MIG_AS0" = "$AS_KEEP" ]; then
  ok "A/S 가 $AS_KEEP 그대로다 (이 배포는 DB 를 건드리지 않는다)"
else
  bad "🔴 A/S 가 ${MIG_AS0} 이다 ($AS_KEEP 이어야 한다) — 다른 배포가 먼저 돌았거나 전제가 깨졌다"
  doubt
fi

# ── 3. 들여올 이미지 둘 ───────────────────────────────────────────────
printf '\n== 3. 들여올 이미지 둘 (앱 하나 + 도구 하나)\n'
BLANK=0
for t in $(trows); do
  TAR=$(fld "$t" 1); WSZ=$(fld "$t" 2); WM5=$(fld "$t" 3); WCFG=$(fld "$t" 4)
  T=$IMGD/$TAR
  if [ ! -s "$T" ]; then
    if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
      hm "$TAR 가 아직 없다: $T — **${MODE} 에서는 괜찮다**"
    else bad "$TAR 가 없다: $T — 먼저 올리세요"; fi
    cmd "scp -O $TAR dss-nas:$IMGD/"
    continue
  fi
  SZ=$(stat -c %s "$T" 2>/dev/null)
  M5=$(md5sum "$T" | awk '{print $1}')
  CFG=$(tar -xOf "$T" manifest.json 2>/dev/null | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 | sed 's|blobs/sha256/|sha256:|')
  say "$TAR — ${SZ}바이트 · md5 $M5"
  say "        tar 안 Config: ${CFG:-못 읽음}"
  if [ -z "$WSZ" ] || [ -z "$WM5" ] || [ -z "$WCFG" ]; then
    BLANK=$((BLANK+1))
    hm "$TAR — **잰 값이 이 파일에 없다.** 옮기다 깨진 것만 잡는다"
    continue
  fi
  [ "$SZ"  = "$WSZ"  ] && ok "$TAR 크기가 구울 때와 같다  [배포본]" || { bad "$TAR 크기가 다르다 (${SZ} != ${WSZ}) — 옮기다 깨졌다"; doubt; }
  [ "$M5"  = "$WM5"  ] && ok "$TAR md5 가 같다  [배포본]"           || { bad "$TAR md5 가 다르다 — 옮기다 깨졌다"; doubt; }
  [ "$CFG" = "$WCFG" ] && ok "$TAR 지문이 같다  [배포본]"           || { bad "$TAR 지문이 다르다 (${CFG:-못 읽음}) — **다른 판을 올렸다**"; doubt; }
done
if [ "$BLANK" != "0" ]; then
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 41-build.sh --go 가 끝에 찍어 주는"
  printf '%s\n' "     두 줄을 이 파일의 TARS 에 넣으세요."
fi
# 🔵 되돌릴 길 — 옛 태그가 남아 있는가(app-as 만. 도구는 되돌리지 않는다)
for r in $(rows); do
  OLD=$(fld "$r" 5)
  if "$DOCKER" image inspect "$OLD" >/dev/null 2>&1; then ok "$OLD 이 남아 있다 (되돌릴 길)"
  else hm "$OLD 이 없다 — 그 시스템은 --rollback 을 못 쓴다"; fi
done
# 🔴 도구 이미지가 **이미 실려 있으면** 그 자리에서 안을 센다.
if "$DOCKER" image inspect "$TOOLS_NEW" >/dev/null 2>&1; then
  tools_inside_check
else
  if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
    hm "$TOOLS_NEW 가 아직 안 실렸다 — **${MODE} 에서는 괜찮다**. 4절이 싣는다"
  else
    say "$TOOLS_NEW 가 아직 안 실렸다 — 4절이 싣는다"
  fi
fi

if [ "$MODE" = check ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.** 다음: --preload → (다시 --check) → --go"
  printf '%s\n' "🔴 올리기 전에 돌리면 ? 가 여럿 나오는 것이 **정상**이다 (tar)."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 4. --preload : tar 둘을 들여놓는다 ───────────────────────────────
if [ "$MODE" = preload ] || [ "$MODE" = go ]; then
  printf '\n== 4. tar 둘을 들여놓는다\n'
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 하고 멈춘다.**\n'; exit 1; fi
  for t in $(trows); do
    TAR=$(fld "$t" 1); NEW=$(tar2tag "$TAR")
    if [ -z "$NEW" ]; then bad "$TAR 의 태그를 모른다 — tar2tag() 에 줄을 더하세요"; continue; fi
    T=$IMGD/$TAR
    if [ ! -s "$T" ]; then bad "$TAR 가 없다: $T"; continue; fi
    WCFG=$(tar -xOf "$T" manifest.json 2>/dev/null | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 | sed 's|blobs/sha256/|sha256:|')
    if "$DOCKER" image inspect "$NEW" --format '{{.Id}}' 2>/dev/null | grep -q "$WCFG"; then
      ok "$NEW 는 이미 있고 지문이 tar 와 같다 (건너뜀)"; continue
    fi
    "$DOCKER" load -i "$T" 2>&1 | sed 's/^/    /'
    FULL=$("$DOCKER" image inspect "$NEW" --format '{{.Id}}' 2>/dev/null)
    if [ "$FULL" = "$WCFG" ]; then ok "$NEW 가 올라왔고 지문이 tar 와 같다"
    elif [ -n "$FULL" ]; then bad "$NEW 지문이 다르다 — tar $WCFG / NAS $FULL"
    else bad "$NEW 가 안 올라왔다"; fi
  done
  # 🔴 들여놓자마자 도구 이미지 안을 센다 — 늦게 발견할수록 되돌리기가 비싸다.
  if "$DOCKER" image inspect "$TOOLS_NEW" >/dev/null 2>&1; then
    tools_inside_check
  else
    bad "🔴 $TOOLS_NEW 가 아직 안 실렸다 — 위 load 가 실패했는지 보세요"
  fi
fi

if [ "$MODE" = preload ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **들여놓기만 했다 — 아직 안 갈아 끼웠다.** 다음: --check 를 다시 → --go"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 5. --go / --rollback : compose 의 image: 줄을 바꾼다 ─────────────
#  🔴 --go 는 **둘**(app-as·tools-as)을 고친다. --rollback 은 **app-as 하나만**
#     되돌린다 — 도구는 :2 그대로 둔다(39번이 포털 도구에서 쓴 것과 같은 판단).
printf '\n== 5. compose 의 image: 줄을 바꾼다\n'
if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi

cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
chmod 644 "$BK"
ok "사본 $BK"
L0=$(wc -l < "$CF"); IMGS0=$(grep -c '^ *image:' "$CF")
BEF=$(mktemp) || exit 1
AFT=$(mktemp) || exit 1
grep -n '^ *image:' "$CF" > "$BEF"

for r in $(rows); do
  SVC=$(fld "$r" 2); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  if [ "$MODE" = rollback ]; then TO=$OLD; else TO=$NEW; fi
  L=$(img_line "$SVC") || { bad "$SVC — image: 줄을 못 찾았다"; continue; }
  TMP=$(mktemp) || exit 1
  awk -v n="$L" -v to="$TO" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
  cp "$TMP" "$CF"; rm -f "$TMP"
  NOW=$(tag_at "$L")
  if [ "$NOW" = "$TO" ]; then ok "$SVC → $TO (${L}줄)"; else bad "$SVC 의 태그가 $NOW 다"; fi
done

# 🔴 도구는 --go 일 때만 고친다. --rollback 은 **손대지 않는다.**
if [ "$MODE" = go ]; then
  TL=$(img_line "$AS_TOOLS_SVC") || { bad "$AS_TOOLS_SVC — image: 줄을 못 찾았다"; }
  if [ -n "${TL:-}" ]; then
    TMP=$(mktemp) || exit 1
    awk -v n="$TL" -v to="$TOOLS_NEW" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
    cp "$TMP" "$CF"; rm -f "$TMP"
    TNOW=$(tag_at "$TL")
    if [ "$TNOW" = "$TOOLS_NEW" ]; then ok "$AS_TOOLS_SVC → $TOOLS_NEW (${TL}줄)"; else bad "$AS_TOOLS_SVC 의 태그가 $TNOW 다"; fi
  fi
else
  say "🔵 $AS_TOOLS_SVC 는 이번 모드($MODE)에서 **안 건드린다** — :2 그대로 둔다"
fi

L1=$(wc -l < "$CF"); IMGS1=$(grep -c '^ *image:' "$CF")
grep -n '^ *image:' "$CF" > "$AFT"
DIFFN=$(diff "$BEF" "$AFT" | grep -c '^[<>]')
rm -f "$BEF" "$AFT"
say "줄 수 $L0 → $L1 · image: 줄 $IMGS0 → $IMGS1 · 달라진 image: 줄 $((DIFFN / 2))개"
[ "$L1" = "$L0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
[ "$IMGS1" = "$IMGS0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
# 🔴 **남의 image: 줄을 건드리면 안 된다.** --go 는 둘(app-as·tools-as),
#    --rollback 은 하나(app-as)만 달라져야 한다.
if [ "$MODE" = go ]; then WANT_DIFF=2; else WANT_DIFF=1; fi
[ "$((DIFFN / 2))" = "$WANT_DIFF" ] && ok "image: 줄이 꼭 ${WANT_DIFF}개만 달라졌다 (우리 것)" \
  || bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — ${WANT_DIFF}개를 기대했다. 남의 것을 건드렸을 수 있다"
dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 6. app-as 만 다시 띄운다 ──────────────────────────────────────────
#  🔴 tools-as 는 profiles: [tools] 라 up -d 로 띄우지 않는다. 태그만 고쳐
#     두면 다음에 run --rm 으로 부를 때 새 이미지를 쓴다.
printf '\n== 6. app-as 를 다시 띄운다\n'
printf '%s\n' "🔴 --no-deps 다 — app-as 하나만 갈아 끼운다. 나머지 아홉과 DB 둘은 안 건드린다."
for r in $(rows); do
  CN=$(fld "$r" 3)
  say "$CN 지금: $("$DOCKER" inspect -f '{{.Id}}' "$CN" 2>/dev/null | cut -c1-12)"
done
# 🔵 DB 둘의 시작 시각을 적어 둔다 — 교체 뒤에 **그대로인지** 본다.
DBSTART=""
for c in $KEEP_DB; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
  DBSTART="$DBSTART $c=$s"; say "$c 시작 $s"
done
TSEC=$SECONDS
SVCS=$(for r in $(rows); do printf '%s ' "$(fld "$r" 2)"; done)
dc up -d --no-deps $SVCS 2>&1 | sed 's/^/    /'
say "뜨는 것을 20초 기다린다…"; sleep 20
say "정지 구간 $((SECONDS - TSEC))초"

# ── 7. 값으로 확인 ───────────────────────────────────────────────────
printf '\n== 7. 값으로 확인\n'
for r in $(rows); do
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5); PORT=$(fld "$r" 7)
  if [ "$MODE" = rollback ]; then TO=$OLD; else TO=$NEW; fi
  ST=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  HL=$("$DOCKER" inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}없음{{end}}' "$CN" 2>/dev/null)
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$PORT/" 2>/dev/null)
  say "$CN — ${ST:-?} · 건강 ${HL:-?} · 이미지 ${RUN:-?} · 127.0.0.1:$PORT → ${CODE:-없음}"
  [ "$ST" = running ] && ok "$CN 가 돈다" || bad "$CN 가 안 돈다 (${ST:-못 찾음})"
  [ "$RUN" = "$TO" ] && ok "$CN 가 $TO 로 돈다" || bad "$CN 가 $RUN 로 돈다"
  printf '%s' "$CODE" | grep -qE '200|30[127]' && ok "$CN 가 응답한다 ($CODE)" || bad "$CN 응답이 ${CODE:-없음}"
done

# 🔴 A/S DB — 마이그레이션 수가 **여전히** 그대로인가 (이 배포는 DB 를 안 건드린다)
MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
say "A/S 마이그레이션 ${MIG_AS0:-?} -> ${MIG_AS1:-?} (그대로여야 한다)"
[ "${MIG_AS1:-x}" = "$AS_KEEP" ] && ok "A/S 가 $AS_KEEP 그대로다 (DB 를 안 건드렸다)" \
  || bad "🔴 A/S 가 ${MIG_AS1:-?} 다 — $AS_KEEP 그대로여야 한다. 이 배포가 DB 를 건드렸다면 전제가 틀렸다"

# 🔴 도구 태그가 제대로 섰는지 + 이미지 안이 온전한지 다시 센다
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  # 🔵 --go 도 --rollback 도 도구 기대값은 **$TOOLS_NEW 로 같다** — 되돌려도
  #    도구는 :2 그대로 둔다(머리말의 판단).
  [ "$TCUR" = "$TOOLS_NEW" ] && ok "$AS_TOOLS_SVC 가 $TOOLS_NEW 다" \
    || bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $TOOLS_NEW 를 기대했다"
  "$DOCKER" image inspect "$TCUR" >/dev/null 2>&1 && ok "$TCUR 이미지가 NAS 에 있다" \
    || bad "$TCUR 이미지가 NAS 에 없다 — 다음에 부를 때 못 쓴다"
fi
if [ "$MODE" = go ]; then tools_inside_check; fi

# 🔴 **안 건드린 아홉이 그대로 도는지** 센다 — 「옆으로 안 샜다」는 증거다.
#    🔵 dss-inventory 가 이 안에 있다 — 연락서 이식이 재고 관리에 물어보려면
#       이 상자가 떠 있어야 한다(머리말 ②-보조).
printf '\n    ── 안 건드린 아홉 (그대로여야 한다 — dss-inventory 도 포함)\n'
for c in $KEEP_BOXES; do
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
  [ "$s" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
done
printf '\n    ── DB 둘이 안 멈췄는가 (시작 시각이 그대로여야 한다)\n'
for c in $KEEP_DB; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
  b=$(printf '%s' "$DBSTART" | tr ' ' '\n' | sed -n "s/^$c=//p")
  printf '      %-14s %s\n' "$c" "${s:-없음}"
  [ "${s:-x}" = "${b:-y}" ] && ok "$c 가 안 멈췄다" || bad "🔴 $c 가 다시 떴다 (${b:-?} -> ${s:-?})"
done

printf '\n    ── 최근 로그 (12줄)\n'
for r in $(rows); do
  CN=$(fld "$r" 3)
  printf '      ── %s\n' "$CN"
  "$DOCKER" logs --since 3m "$CN" 2>&1 | tail -12 | sed 's/^/        /'
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
if [ "$FAIL" = 0 ]; then
  printf '%s\n' "✅ 기계로 잴 수 있는 것은 전부 통과했다."
  printf '%s\n' "  compose 사본: $BK"
  printf '%s\n' "  로그: $LOG"
  printf '%s\n' "🔴 **마지막은 눈이다** — 쓰는 분이 볼 곳(머리말의 동작 변경 넷):"
  printf '%s\n' "     · 보고서 휴지통의 [완전 삭제] — **개발자 표시가 켜진 사람에게만** 보이는가"
  printf '%s\n' "       (꺼진 계정에서는 그 단추가 아예 없는가)"
  printf '%s\n' "     · 보고서 [지우기] → [휴지통으로 보내기] — 0.5초 안내 뒤 목록으로 넘어가는가"
  printf '%s\n' "     · 부품이 든 연락서를 이식하면 사용 부품 이름이 **품번**으로 들어가는가"
  printf '%s\n' "       (재고관리에 요청 흔적이 있는 건에는 한 줄도 안 들어가는가)"
  printf '%s\n' "     · 출하 완료된 건의 [파일관리] — 올리기·휴지통·되살리기·**사진 회전**이 되는가"
  printf '%s\n' "       (회전은 되돌릴 수 없는 덮어쓰기임을 알고 확인할 것)"
  printf '%s\n' "     · 재고 관리 화면이 떠 있는가(연락서 이식이 그걸 물어본다)"
  printf '%s\n' ""
  printf '%s\n' "  🔵 새 점검 도구를 돌려 보려면(읽기만 한다, 재고 관리가 떠 있어야 뜻이 있다):"
  printf '%s\n' "    cd /volume1/dss/deploy"
  printf '%s\n' "    $DOCKER compose -f docker-compose.nas.yml --env-file .env.nas \\"
  printf '%s\n' "      --profile tools run --rm tools-as npm run check:part-name-overlap"
  printf '%s\n' ""
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (app-as 만 되돌린다. 도구는 :2 그대로"
  printf '%s\n' "               둔다 — DB 를 안 건드렸으니 자료 손실이 없다)"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
