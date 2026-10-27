#!/bin/bash
# dss-deploy/nas/setup/39-deploy.sh — 서른여섯째 배포 (2026-10-27)
#
# 🔴 NAS 에서 돈다. DSM 터미널은 긴 명령을 잘라 먹으므로 **파일로 올려** 돌린다.
#    md5 를 맞춘다:  md5sum /volume1/dss/setup/39-deploy.sh
#
# ── 사람이 실행한다 ───────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/39-deploy.sh            ← 읽기만 한다
#   (NAS)         bash /volume1/dss/setup/39-deploy.sh --preload
#   (NAS)         bash /volume1/dss/setup/39-deploy.sh --migrate  🔴 DB 가 바뀐다
#   (NAS)         bash /volume1/dss/setup/39-deploy.sh --go       ⏱ 정지 창
#
# ── 갈아 끼우는 것 셋 ─────────────────────────────────────────────────
#     ① 포털  dss-auth:1.9      → **dss-auth:2.0**       커밋 1
#     ② A/S   dss-as:3.1        → **dss-as:3.2**         커밋 8   🔴 마이그레이션 2건
#     ③ 재고  dss-inventory:0.5 → **dss-inventory:0.6**  커밋 2
#   그리고 도구 하나:
#     ④ 포털도구  dss-auth-tools:2 → **dss-auth-tools:3**  🔴 **비상구 둘** 때문이다
#
#   🔵 **나머지 일곱은 안 건드린다** — PO 0.7 · 게시판 0.3 · 계측기 1.4 ·
#      개선요청 0.5 · RF 이슈관리 0.2 · 휴가 0.4 · 통합 승인함 0.1 은
#      기준 SHA 이후 커밋이 **0** 이다(2026-10-27 실측).
#
# ── 이 배포가 하는 일 ─────────────────────────────────────────────────
#   **결재권을 남에게 맡길 수 있다.** A/S 에 결재선 위임이 생기고(표 하나 + 칸 하나),
#   재고는 관리자가 남의 결재권도 맡길 수 있게 넓힌다. 포털은 결재가 생기면
#   대리인에게도 알린다.
#
# ── 🔴 도구 이미지를 왜 올리는가 — **마이그레이션 때문이 아니다** ─────
#   🔴 포털 마이그레이션은 이번에도 **0건**이다. 이 파일에는 **포털 DB 를 건드리는
#      단계가 아예 없다** — 포털은 「10 그대로, 늘면 ✗」다.
#
#   포털의 커밋 하나(52cbb19)가 고친 여섯은 Dockerfile · package.json ·
#   scripts/*.ts 넷이고, 포털 **runner 스테이지에는 package.json 도 scripts/ 도
#   없다**(.next/standalone · .next/static · public 셋뿐). 담는 쪽은 tools 다.
#   🔴 그러므로 앱만 올리면 dss-auth:2.0 은 1.9 와 **동작이 같다.**
#
#   🔵 그 커밋이 풀려던 셋 중 purge-expired.ts(감사 로그 3년 보관)는 **이미 돌고
#      있다** — 야간 정리가 npm run 을 안 거치는 길로 2026-10-25 에 풀렸다.
#   🔴 **남은 둘이 까닭이다 — admin:promote · admin:emergency 가 아직 컨테이너에서
#      못 돈다.** 포털은 사내 모든 시스템의 로그인이라 **관리자가 잠기면 되돌릴 다른
#      길이 없다.** 그 비상구 둘을 못 쓰는 채로 두는 것이 위험이라 함께 올린다.
#      (2026-10-27 사용자 승인)
#   🔵 올린 뒤 비상구를 부르는 길(쓸 일이 생긴 날):
#        cd /volume1/dss/deploy
#        /usr/local/bin/docker compose -f docker-compose.nas.yml \
#          --env-file .env.nas --profile tools run --rm tools-auth \
#          npm run admin:promote
#      🔵 **옛 길도 그대로 통한다** — node --import tsx scripts/promote-admin.ts.
#         그 길은 이 판 이전에 구운 이미지에서도 통하는 유일한 길이다.
#
# ── 🔴 37번(지난 판)과 다른 것 넷 ─────────────────────────────────────
#   ① 🔴 **마이그레이션이 A/S 쪽이고, 길이 다르다.**
#        37번(포털)은 **이미지 안**에서 돌았다. A/S 는 **볼륨**에서 돈다 —
#        /volume1/dss/as-migrations 를 tools-as 가 :ro 로 읽는다. 그 길은
#        31-deploy.sh 가 쓴 것이고, 이 파일은 그쪽을 베꼈다.
#        🔴 그래서 **이미지 넷만 올리면 안 된다.** as-migrations.tar.gz 를
#           /volume1/dss/setup/incoming/ 에 함께 올려야 한다. 안 올리면
#           오류가 아니라 **「0건 적용」으로 조용히 끝난다.**
#   ② 🔴 **도구 태그를 고치는 까닭이 다르다.** 37번은 그 도구로 포털
#        마이그레이션을 돌리려고 :1 → :2 로 고쳤다. 이번엔 **비상구 둘을 쓸 수
#        있게** 하려고 :2 → :3 으로 고친다. 고치는 **방식은 37번 그대로**다 —
#        --migrate 안에서, 사본을 뜨고, image: 줄이 **꼭 하나만** 달라졌는지 세고,
#        어긋나면 사본으로 되돌리고 멈춘다.
#        🔵 tools-auth 는 profiles: [tools] 라 평소에 뜨지 않는다. 도는 컨테이너는
#           compose 를 읽지 않으므로 그 한 줄을 고쳐도 **직원이 느끼는 것이 없다.**
#   ③ 🔵 **tools-as 는 안 바꾼다.** dss-as-tools:1 그대로다 — drizzle-kit 과 볼륨의
#        목록만 쓰고 새 스키마를 안 읽는다(31번이 0118 을 같은 이미지로 돌렸다).
#   ④ 🔴 **새 HTTP 통로가 없다.** 37번은 --go 끝에 새 통로를 자격 없이 불러
#        401 인지 봤다. 이번 셋에는 새 api 경로가 하나도 없다(2026-10-27 실측:
#        A/S 가 바꾼 src/app/ 다섯은 전부 화면이다). 그래서 --go 의 확인은
#        **도는 이미지 태그 · 응답 코드 · 로그** 셋이고, 포털의 옛 통로는
#        **안 깨졌는지** 보는 자리로만 쓴다. 🔴 마지막은 눈이다.
#
# ── 모드 다섯 ─────────────────────────────────────────────────────────
#   (기본)   --check      아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --preload             tar 넷을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --migrate             🔴 **DB 가 바뀐다.** A/S 볼륨 119 → 121 ·
#                         compose 의 tools-auth 를 :2 → :3
#   --go                  compose 의 앱 태그 셋을 바꾸고 다시 띄운다
#   --rollback            앱 셋을 옛 판으로 되돌린다 (🔵 도구는 :3 그대로 둔다 —
#                         판에 매이지 않고, 비상구는 새것이 낫다)
#
#   🔴 차례:  --check → --preload → --check → --migrate → --go
#   🔴 **--migrate 와 --go 는 따로 부른다** — 마이그레이션이 덜 된 DB 에 새 판을
#      올리면 없는 표를 읽다 그 자리에서 죽는다.
#   🔴 **마이그레이션은 되돌아가지 않는다.** --rollback 은 앱만 되돌린다.
#      🔵 0119 는 **표 하나를 더하고** 0120 은 **칸 하나를 더한다.** 기존 표를
#         안 건드리고 지우는 문장이 한 줄도 없다(2026-10-27 두 파일을 글자로 읽음).
#         그래서 옛 판 3.1 이 그 표와 칸을 몰라도 멀쩡히 돈다 — 되돌릴 수 있다.
#
# ── 🔴 기대값 — 「0 이면 통과」가 아니다 ──────────────────────────────
#   A/S  볼륨 .sql        119 → **121**     🔴 **안 늘면 ✗**
#   A/S  meta/_journal.json 의 idx  119 → **121**
#   A/S  DB __drizzle_migrations    119 → **121**
#   포털 DB __drizzle_migrations     10 → **10**   🔴 **늘면 ✗**
#   재고 DB __drizzle_migrations     26 → **26**   🔴 **늘면 ✗**
#
#   출처를 적어 둔다 — ✗ 가 나면 **검사 자신을 먼저 의심한다.**
#     [볼륨]   2026-10-27 운영 /volume1/dss/as-migrations 를 읽어서 센 값
#     [저장소] 2026-10-27 개발 PC 의 drizzle/ 에서 센 값
#     [README] 서른한째·서른다섯째 배포 결과 절에 적힌 값
#
# ── 🔴 _journal.json 은 meta/ 안에 있다 ──────────────────────────────
#   as-migrations/ 바로 아래가 **아니다.** 거기서 찾으면 0 이 나와 **가짜 ✗** 가
#   난다. 반드시 as-migrations/meta/_journal.json 을 본다. 2026-10-27 확인.
#
# ── 🔴 개발 PC → NAS 로 올릴 것 — **여섯** ───────────────────────────
#   ㄱ) 이미지 tar **넷** → /volume1/dss/images/
#        dss-auth-2.0.tar · dss-auth-tools-3.tar ·
#        dss-as-3.2.tar · dss-inventory-0.6.tar
#      🔴 **도구 tar 를 빠뜨리기 쉽다.** 빠뜨리면 비상구 둘이 그대로 못 쓰는 채
#         남고, 그 사실은 **쓸 일이 생긴 날**에만 드러난다.
#   ㄴ) 🔴 A/S 마이그레이션 묶음 → /volume1/dss/setup/incoming/
#        as-migrations.tar.gz      ← 39-build.sh --go 가 _images-36 에 만든다
#   ㄷ) 이 파일 → /volume1/dss/setup/
#
#   (개발 PC · PowerShell)
#     cd C:\Users\희만\Desktop\Development\_images-36
#     scp -O dss-auth-2.0.tar dss-auth-tools-3.tar dss-nas:/volume1/dss/images/
#     scp -O dss-as-3.2.tar dss-inventory-0.6.tar dss-nas:/volume1/dss/images/
#     scp -O as-migrations.tar.gz dss-nas:/volume1/dss/setup/incoming/
#     cd C:\Users\희만\Desktop\Development
#     scp -O dss-deploy\nas\setup\39-deploy.sh dss-nas:/volume1/dss/setup/
#     Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\39-deploy.sh
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#   🔴 tar 에 드라이브 문자(C:)를 주지 마세요 — 원격 호스트로 읽습니다.
#   🔴 묶음을 git archive 로 뽑지 마세요 — 서브모듈이 빈 폴더로 나옵니다.
#
# ── 🔴 --check 도 「아무것도 안 한다」는 아니다 ───────────────────────
#   운영 DB 에 **select** 를 여러 번 보낸다(바꾸는 문장은 하나도 없다).
#   앱 셋의 바깥 주소에 GET 을 한 번씩 보낸다.
#   🔴 도구 이미지가 이미 실려 있으면 **안을 보려고 컨테이너를 잠깐 띄웠다 지운다**
#      (docker run --rm). 🔵 비상구 스크립트를 **부르지 않는다** — 깃발과 파일만
#      세는 자리라 DB 에 닿지 않는다.
#   「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안의 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 주석에도 안 썼다. 쓴 뒤 세었다.
#   ② 읽기 전용 자리에 콜론 하나와 꺾쇠로 빈 파일을 만들면 NAS 의 ash 가 셸을
#      그 자리에서 끝낸다(2026-10-12 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#
# ── 🔴 비밀값을 찍지 않는다 ───────────────────────────────────────────
#   .env 는 **이름이 있는가/없는가**만 본다. 값도, 값의 길이도 찍지 않는다.
#   이번 판에는 새로 필요한 설정 이름이 **없다**(세 저장소의 .env.example 이
#   기준 SHA 이후로 안 바뀌었다).
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BKDB=$D/backups/db
INCOMING=$D/setup/incoming
MIGDIR=$D/as-migrations
MIGTAR=$INCOMING/as-migrations.tar.gz
BK=$D/backups/docker-compose.nas.yml.v36-$STAMP

# ══ 이번에 갈아 끼우는 앱 셋 ══════════════════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
SITES='
auth|app-auth|dss-auth|dss-auth:2.0|dss-auth:1.9|dss-auth-2.0.tar|13100
as|app-as|dss-as|dss-as:3.2|dss-as:3.1|dss-as-3.2.tar|13000
inventory|app-inventory|dss-inventory|dss-inventory:0.6|dss-inventory:0.5|dss-inventory-0.6.tar|13800
'
# ══ 🔴 tar 넷의 지문 — [배포본] 39-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 비어 있다.** 39-build.sh --go 가 마지막에 찍어 주는 다섯 줄 중
#      **앞 네 줄**을 여기에 그대로 붙여 넣는다(마지막 줄은 묶음이라 아래로 간다).
#      비어 있으면 3절이 **? 로 센다** — 「옮기다 깨진 것」은 잡지만 「개발 PC 에서
#      구운 그것이 맞나」는 못 본다.
#   🔴 통과로 세지 않는다. 비었으면 --check 의 끝에서 크게 적힌다.
TARS='
dss-auth-2.0.tar|113688576|c7f5ac5612eee0af15a758883ecfa8b9|sha256:28a4cae9d88aa6989c0dadafa467d9a722b86da15f795dd8160d91b5c1352787
dss-auth-tools-3.tar|212256768|f192a4664f5560df4c0be3d2d069b0a3|sha256:9b77f45d00323d94ce4c85a33589519e7726e23b8e1bfa457355830947f4609b
dss-as-3.2.tar|132666880|c5717b9eb44daf3dcdd31b20f1d0dea5|sha256:75d087c8ca045ab6b978a58d631a561c4d28a76310e0378953c5f5faff4d08ba
dss-inventory-0.6.tar|95444992|9776aadafbde8f7b1f65bca025d5969e|sha256:bd5e2893900444abf883b0a15f262747b5cd1af9f0650dbfb9d2b088c22a1f98
'
# 🔴 tar 이름 → 태그. **정규식으로 되돌리지 않는다** — 이름마다 손으로 적는다.
#    dss-auth-tools-3 을 「끝의 숫자 앞에 콜론」 규칙으로 풀면 맞지만, 규칙이
#    맞는지 사람이 눈으로 확인할 수 없는 자리에 두지 않는다.
tar2tag() {
  case "$1" in
    dss-auth-2.0.tar)      printf 'dss-auth:2.0' ;;
    dss-auth-tools-3.tar)  printf 'dss-auth-tools:3' ;;
    dss-as-3.2.tar)        printf 'dss-as:3.2' ;;
    dss-inventory-0.6.tar) printf 'dss-inventory:0.6' ;;
  esac
}
# 🔴 A/S 마이그레이션 묶음의 지문 — 같은 자리에서 채운다. 비면 ? 다.
MIGTAR_SIZE=2296619
MIGTAR_MD5=f1657e528d2ba49819fb4ec08e5d0218

# ══ 🔴 기대값과 출처 ══════════════════════════════════════════════════
AS_BOX=dss-pg-app;    AS_DB=dss_as;          AS_HAVE=119;  AS_WANT=121   # [볼륨][저장소]
AUTH_BOX=dss-pg-auth; AUTH_DB=dss_auth;      AUTH_KEEP=10                # [README] 37번 8→10
INV_BOX=dss-pg-app;   INV_DB=dss_inventory;  INV_KEEP=26                 # [README] 31번 20→26
AS_TOOLS_SVC=tools-as
AS_TOOLS_IMG=dss-as-tools:1
IMG_MIGDIR=/app/drizzle
# ══ 🔴 포털 도구 — 이번에 :2 → :3 으로 고치는 그것 ════════════════════
#   🔵 profiles: [tools] 라 평소에 뜨지 않는다. 고쳐도 직원이 느끼는 것이 없다.
AUTH_TOOLS_SVC=tools-auth
TOOLS_OLD=dss-auth-tools:2
TOOLS_NEW=dss-auth-tools:3
# 🔴 도구 이미지 안에 **있어야** 하는 것 — 이것이 이번 판의 까닭이다
TOOLS_SQL_WANT=10                 # [저장소] dss-auth/drizzle/*.sql 과 같아야 한다
TOOLS_SCRIPTS="/app/scripts/promote-admin.ts /app/scripts/create-emergency-admin.ts"
# 🔴 이번에 A/S 에 **생기는** 것 — 표 하나 · 칸 하나 · 인덱스 하나
AS_NEW_TABLE=approval_route_delegations
AS_NEW_COL_TABLE=quote_approvals
AS_NEW_COL=delegated_from_user_id
AS_NEW_INDEX=approval_route_delegations_delegate_active_idx
AS_NEW_MIGS="0119 0120"
# 🔵 줄 수가 그대로여야 하는 표 — 적용 전후로 센다
AS_COUNT_TABLES="repair_cases customers quote_approvals users"
INV_COUNT_TABLES="parts stock_requests"
AUTH_COUNT_TABLES="users clients"
# 🔴 「지우는 문장」 잣대 — 앱의 migration-safety.ts 와 **같은 것**을 쓴다.
#    DELETE 만으로 세지 않는다. 외래키의 ON DELETE 가 걸려서 표만 더하는 판이
#    ✗ 가 된다(19번이 그 자리에서 넘어졌다). 0119 에 ON DELETE restrict 가 넷 있다.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
MIG_DROP_WANT=0
# 🔵 안 건드리는 일곱 — 「옆으로 안 샜다」는 증거로 센다
KEEP_BOXES="dss-meters dss-po dss-board dss-improvements dss-rf-trouble dss-leave dss-approvals"
# 🔵 DB 둘은 멈추지 않는다
KEEP_DB="dss-pg-app dss-pg-auth"

MODE=check
case "${1:-}" in
  --check|"")  MODE=check ;;
  --preload)   MODE=preload ;;
  --migrate)   MODE=migrate ;;
  --go)        MODE=go ;;
  --rollback)  MODE=rollback ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --preload · --migrate · --go · --rollback\n' "$1"; exit 2 ;;
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
mkdir -p "$D/setup/logs" "$BKDB" "$INCOMING"
LOG="$D/setup/logs/39-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "서른여섯째 배포 — 포털 · A/S · 재고   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  로그: $LOG"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 공통: compose 에서 그 서비스의 image: 줄을 찾는다 ─────────────────
# 🔴 그 블록 안의 것 하나만 고쳐야 한다. 서비스 머리부터 다음 서비스 머리 전까지.
#    파일 전체를 grep 하면 주석 줄이 걸려 꺼져 있는 서비스를 센다.
img_line() { # 1 서비스
  local s=$1 start next
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
# 🔴 도구 image: 줄을 **글자 그대로** 모은다. 줄 수만 세면 :2 → :3 처럼 **값만**
#    바뀐 것을 못 잡는다. --go 에서는 이 글자가 **하나도 안 바뀌어야** 맞다.
tools_img_lines() { grep -nE '^[[:space:]]*image:[[:space:]]*dss-[a-z]+-tools:' "$CF"; }
# 🔴 앱 image: 줄도 같은 방식으로 — --migrate 에서는 **하나도 안 바뀌어야** 맞다.
app_img_lines() {
  for r in $(rows); do
    L=$(img_line "$(fld "$r" 2)") || continue
    printf '%s:%s\n' "$L" "$(tag_at "$L")"
  done
}

# 🔴 운영 DB 를 **앱이 쓰는 길**(컨테이너 안 psql)로 잰다. 소켓·루프백으로 재면
#    trust 라 그냥 통과한다. 보내는 SQL 은 전부 select 다.
pgq() { # 1 상자 2 DB 3 SQL
  "$DOCKER" exec -i "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -X -tAq -c \"$3\"" 2>/dev/null | head -1 | tr -d ' \r'
}
# 🔴 수가 아니면 **빈 글자**를 돌려준다. 0 을 「0건이니 통과」로 읽지 않는다.
pgn() { local v; v=$(pgq "$1" "$2" "$3"); isnum "$v" && printf '%s' "$v"; }
mig_count() { pgn "$1" "$2" 'select count(*) from drizzle.__drizzle_migrations'; }
has_table()  { pgn "$1" "$2" "select count(*) from information_schema.tables where table_schema='public' and table_name='$3'"; }
has_column() { pgn "$1" "$2" "select count(*) from information_schema.columns where table_schema='public' and table_name='$3' and column_name='$4'"; }
has_index()  { pgn "$1" "$2" "select count(*) from pg_indexes where schemaname='public' and indexname='$3'"; }

# ── A/S 마이그레이션 볼륨을 센다 (31-deploy.sh 의 read_migdir 를 고쳐 쓴다) ──
# 🔴 _journal.json 은 **meta/ 안**이다. 바로 아래에서 찾으면 0 이 나온다.
MIG_N_SQL=0; MIG_N_J=0; MIG_STATE=""
read_migdir() {
  MIG_N_SQL=0; MIG_N_J=0; MIG_STATE=""
  [ -d "$MIGDIR" ] || { MIG_STATE=NODIR; return 0; }
  MIG_N_SQL=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  if [ -f "$MIGDIR/meta/_journal.json" ]; then
    MIG_N_J=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  fi
  MIG_N_SQL=${MIG_N_SQL:-0}; MIG_N_J=${MIG_N_J:-0}
  if   [ "$MIG_N_SQL" = "$AS_WANT" ] && [ "$MIG_N_J" = "$AS_WANT" ]; then MIG_STATE=DONE
  elif [ "$MIG_N_SQL" = "$AS_HAVE" ] && [ "$MIG_N_J" = "$AS_HAVE" ]; then MIG_STATE=OLD
  else MIG_STATE=ODD
  fi
  return 0
}
# 🔴 새 둘이 **짝으로** 있는지 — .sql 과 meta/*_snapshot.json 둘 다.
#    snapshot 이 빠지면 drizzle-kit 이 그 자리에서 죽는다.
check_new_migs() {
  local t miss="" f n rc=0
  for t in $AS_NEW_MIGS; do
    ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || miss="$miss $t(sql)"
    [ -f "$MIGDIR/meta/${t}_snapshot.json" ]   || miss="$miss $t(snapshot)"
  done
  if [ -z "$miss" ]; then ok "0119·0120 의 .sql 과 meta/*_snapshot.json 이 다 있다"
  else bad "🔴 빠진 것:$miss"; rc=1; fi
  n=0
  for t in $AS_NEW_MIGS; do
    f=$(ls -1 "$MIGDIR/${t}_"*.sql 2>/dev/null | head -1)
    [ -n "$f" ] || continue
    local c; c=$(grep -ciE "$DESTRUCTIVE_RE" "$f" 2>/dev/null); n=$((n + ${c:-0}))
  done
  if [ "$n" = "$MIG_DROP_WANT" ]; then
    ok "0119·0120 에 지우는 문장이 ${n}줄이다 (기대 ${MIG_DROP_WANT}줄 — 더하기만 한다)"
  else
    bad "🔴 0119·0120 에 지우는 문장이 ${n}줄이다 (기대 ${MIG_DROP_WANT}줄) — 고치지 말고 **먼저 알리세요**"
    rc=1
  fi
  # 🔵 글자 표식 — 올린 것이 그 파일이 맞는지. 이름만 맞고 속이 다를 수 있다.
  f=$(ls -1 "$MIGDIR/0119_"*.sql 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    grep -qF "CREATE TABLE \"$AS_NEW_TABLE\"" "$f" \
      && ok "0119 안에 표 $AS_NEW_TABLE 를 만드는 줄이 있다" \
      || { bad "🔴 0119 안에 그 표를 만드는 줄이 **없다** — 다른 파일이다"; rc=1; }
  fi
  f=$(ls -1 "$MIGDIR/0120_"*.sql 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    grep -qF "ADD COLUMN \"$AS_NEW_COL\"" "$f" \
      && ok "0120 안에 칸 $AS_NEW_COL 를 더하는 줄이 있다" \
      || { bad "🔴 0120 안에 그 칸을 더하는 줄이 **없다** — 다른 파일이다"; rc=1; }
  fi
  return "$rc"
}
# 묶음을 풀어 볼륨을 통째로 갈아 끼운다 (31-deploy.sh 의 place_migs 그대로)
# 🔴 파일 넷만 복사하지 않는다. meta/ 가 통째로 짝이어야 한다 —
#    _journal.json 이 옛것이면 새 .sql 을 drizzle 이 **아예 모른다.**
place_migs() {
  if [ ! -s "$MIGTAR" ]; then
    say "incoming 에 묶음이 없다 — 폴더가 이미 새것인지 아래에서 본다"
    return 0
  fi
  rm -rf "$MIGDIR.new"; mkdir -p "$MIGDIR.new"
  if tar -xzf "$MIGTAR" -C "$MIGDIR.new" --strip-components=1; then
    rm -rf "$MIGDIR.old"
    [ -d "$MIGDIR" ] && mv "$MIGDIR" "$MIGDIR.old"
    mv "$MIGDIR.new" "$MIGDIR"
    chown -R root:root "$MIGDIR"; chmod -R a+rX "$MIGDIR"
    ok "as-migrations 새것으로 (옛것: as-migrations.old — 되돌릴 길이다)"
    say "🔵 묶음은 **지우지 않는다** — 다시 돌릴 때 쓴다."
    return 0
  fi
  rm -rf "$MIGDIR.new"
  bad "as-migrations 풀기 실패"
  return 1
}

# ══ 🔴 포털 도구 이미지 **안**을 센다 — 겉이 아니라 결과 ══════════════
#   🔴 --target tools 를 빠뜨렸으면 runner 가 구워지고, 그 안에는 scripts/ 도
#      drizzle/ 도 없다. 이미지는 멀쩡히 실리고 오류가 안 난다. 그때 증상은
#      **비상구를 써야 하는 날**의 「그런 파일 없음」 한 줄뿐이고, 그날은 되돌릴
#      다른 길이 없는 날이다. 그래서 여기서 다섯을 센다.
#   🔵 비상구 스크립트를 **부르지 않는다.** 파일과 깃발만 센다 — DB 에 안 닿는다.
tsh() { "$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "$1" 2>/dev/null | tr -d '\r' | tail -1; }
tools_inside_check() {
  local v n
  printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TOOLS_NEW"
  # ① runner 가 아니라 tools 인가 — runner 에는 /app/package.json 이 없다.
  v=$(tsh 'test -f /app/package.json && echo yes || echo no')
  say "/app/package.json: ${v:-못 읽음}"
  [ "${v:-}" = "yes" ] && ok "tools 스테이지가 맞다" \
    || { bad "🔴 /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다"; doubt; }
  # ② 🔴 비상구 둘 — 이번 판의 까닭이다.
  n=$(tsh "ls $TOOLS_SCRIPTS 2>/dev/null | wc -l")
  say "비상구 스크립트 ${n:-?}개 (기대 2)"
  [ "${n:-0}" = "2" ] && ok "promote-admin.ts · create-emergency-admin.ts 가 들어 있다" \
    || bad "🔴 비상구가 ${n:-?}개다 — scripts/ 가 안 담겼다. **올려도 못 쓴다**"
  # ③ 🔴 package.json 의 그 두 줄이 이미지 안에서도 새 깃발인가.
  #    🔵 정규식을 안 쓴다 — 셸·sh·grep 세 겹을 지나며 역슬래시가 삼켜진다.
  n=$(tsh 'n=0; for k in promote emergency; do grep -qF "\"admin:$k\": \"node --env-file-if-exists=" /app/package.json && n=$((n+1)); done; echo $n')
  say "이미지 안 package.json 의 --env-file-if-exists 비상구 줄 ${n:-?}개 (기대 2)"
  [ "${n:-0}" = "2" ] && ok "비상구 둘이 컨테이너에서 사는 꼴로 들어갔다" \
    || bad "🔴 ${n:-?}개다 — 옛 --env-file= 이 섞였다. **컨테이너에서 그 자리에 죽는다**"
  # ④ 🔴 **값을 받아 본다.** 이미지 안의 node 가 그 깃발을 실제로 아는가.
  #    없는 파일을 주고도 조용히 지나가야 맞다 — 그것이 52cbb19 가 기대는 동작이다.
  v=$("$DOCKER" run --rm --entrypoint node "$TOOLS_NEW" \
        --env-file-if-exists=/nonexistent.env -e "console.log('FLAG_OK')" 2>&1 | tr -d '\r' | tail -1)
  say "node --env-file-if-exists=<없는 파일> → ${v:-없음}"
  [ "${v:-}" = "FLAG_OK" ] && ok "이미지 안 node 가 그 깃발을 안다 (파일이 없어도 지나간다)" \
    || bad "🔴 FLAG_OK 가 아니다 — node 가 그 깃발을 모른다. 비상구가 또 죽는다"
  # ⑤ 🔵 마이그레이션은 이번에 안 돌리지만, 비어 있으면 **다음 판**이 조용히 0건이 된다.
  n=$(tsh 'ls /app/drizzle/*.sql 2>/dev/null | wc -l')
  say "/app/drizzle 의 .sql ${n:-?}장 (기대 $TOOLS_SQL_WANT · 이번엔 안 돌린다)"
  [ "${n:-0}" = "$TOOLS_SQL_WANT" ] && ok "drizzle/ 도 개발 PC 와 같다 (다음 판을 위해)" \
    || bad "🔴 ${n:-?}장이다 — $TOOLS_SQL_WANT 장이어야 한다"
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
# 🔴 A/S 도구는 **안 바꾼다.** 그래도 제자리에 맞는 것이 있는지는 본다 —
#    없거나 다른 것이면 마이그레이션을 돌릴 길이 없다.
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  say "$AS_TOOLS_SVC — ${TL}줄 · $TCUR  (🔵 이번엔 **안 고친다**)"
  if [ "$TCUR" = "$AS_TOOLS_IMG" ]; then ok "$AS_TOOLS_SVC 가 $AS_TOOLS_IMG 다 (고칠 것이 없다)"
  else bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $AS_TOOLS_IMG 를 기대했다. 멈추고 알릴 것"; fi
  if "$DOCKER" image inspect "$TCUR" >/dev/null 2>&1; then ok "$TCUR 이미지가 NAS 에 있다"
  else bad "$TCUR 이미지가 NAS 에 없다 — 마이그레이션을 돌릴 길이 없다"; fi
  # 🔴 볼륨이 제 자리에 붙는가. 여기가 어긋나면 **적용이 엉뚱한 것을 읽는다.**
  if svc_block "$AS_TOOLS_SVC" | grep -q "$MIGDIR:$IMG_MIGDIR"; then
    ok "$AS_TOOLS_SVC 가 $MIGDIR 를 $IMG_MIGDIR 로 붙인다"
  else
    bad "🔴 $AS_TOOLS_SVC 의 drizzle 볼륨이 $MIGDIR 가 아니다 — **적용이 엉뚱한 것을 읽는다**"
  fi
else
  bad "compose 에 $AS_TOOLS_SVC 가 없다 — 마이그레이션을 돌릴 길이 없다"
fi
# ── 🔴 포털 도구 — 이번엔 **판정하고 고친다** (:2 → :3) ───────────────
#    🔵 2026-10-27 결정. 그 전 판에서는 「판정하지 않는다」였는데 **취소됐다.**
#       까닭은 머리말의 「도구 이미지를 왜 올리는가」 절에 있다.
TAL=$(img_line "$AUTH_TOOLS_SVC")
if [ -n "${TAL:-}" ]; then
  TACUR=$(tag_at "$TAL")
  say "$AUTH_TOOLS_SVC — ${TAL}줄 · $TACUR  (🔴 --migrate 가 $TOOLS_NEW 로 고친다)"
  # 🔴 **단계마다 기대값이 다르다.** 한 잣대로 재면 가짜 ✗ 가 난다 —
  #    --migrate 전에는 :2 가 맞고, --go 때는 :3 이 맞다.
  #    🔵 --rollback 은 **아무 상태에서도 서야 한다.** 되돌리는 길을 검사로 막지 않는다.
  case "$MODE" in
    go)
      if [ "$TACUR" = "$TOOLS_NEW" ]; then ok "$AUTH_TOOLS_SVC 가 $TOOLS_NEW 다 (--migrate 가 고쳤다)"
      elif [ "$TACUR" = "$TOOLS_OLD" ]; then bad "$AUTH_TOOLS_SVC 가 아직 $TOOLS_OLD 다 — 🔴 --migrate 를 먼저 돌리세요"
      else bad "$AUTH_TOOLS_SVC 의 태그가 $TACUR 다 — 멈추고 알릴 것"; doubt; fi ;;
    rollback)
      if [ "$TACUR" = "$TOOLS_NEW" ]; then ok "$AUTH_TOOLS_SVC 가 $TOOLS_NEW 다 (🔵 되돌려도 그대로 둔다)"
      else hm "$AUTH_TOOLS_SVC 가 $TACUR 다 — 🔵 되돌리기를 막지 않는다"; fi ;;
    *)
      if [ "$TACUR" = "$TOOLS_OLD" ]; then ok "$AUTH_TOOLS_SVC 가 $TOOLS_OLD 다 (고칠 준비)"
      elif [ "$TACUR" = "$TOOLS_NEW" ]; then hm "$AUTH_TOOLS_SVC 가 이미 $TOOLS_NEW 다 (다시 돌리는 중인가)"
      else bad "$AUTH_TOOLS_SVC 의 태그가 $TACUR 다 — $TOOLS_OLD 도 $TOOLS_NEW 도 아니다. 멈추고 알릴 것"; doubt; fi ;;
  esac
  # 🔴 포털 DB 상자가 dss-pg-app 이 **아니라 dss-pg-auth** 여야 한다. 베끼다 틀리면
  #    호스트를 못 찾는 것이 아니라 **엉뚱한 서버에 붙어** 끝난다(31번의 그 주석).
  if svc_block "$AUTH_TOOLS_SVC" | grep -q 'dss-pg-auth'; then
    ok "$AUTH_TOOLS_SVC 가 dss-pg-auth 를 본다"
  else
    bad "🔴 $AUTH_TOOLS_SVC 가 dss-pg-auth 를 안 본다 — **엉뚱한 서버에 붙는다**"
  fi
else
  bad "compose 에 $AUTH_TOOLS_SVC 가 없다 — 비상구를 부를 길이 없다"
fi

# ── 2. 🔴 A/S 마이그레이션 볼륨 — 이 배포의 심장 ─────────────────────
printf '\n== 2. 🔴 A/S 마이그레이션 볼륨 (%s → %s 의 %s)\n' "$MIGDIR" "$AS_TOOLS_SVC" "$IMG_MIGDIR"
printf '%s\n' "🔴 .sql 만으로는 모자라다 — **meta/_journal.json 과 snapshot 까지** 가야 한다."
printf '%s\n' "   목록에 없는 .sql 은 drizzle 이 아예 모르고, 적용이 **0건으로 조용히 끝난다.**"
read_migdir
say "$MIGDIR — .sql ${MIG_N_SQL}장 · meta/_journal.json 의 idx ${MIG_N_J}개"
case "$MIG_STATE" in
  DONE) ok "볼륨이 **이미 $AS_WANT 이다** — 묶음을 이미 풀었거나 다시 돌리는 중이다"
        check_new_migs || true ;;
  OLD)  if [ "$MODE" = check ]; then
          hm "볼륨이 아직 $AS_HAVE 이다 — **올리기 전이면 정상**이다. --migrate 가 갈아 끼운다"
        else
          ok "볼륨이 $AS_HAVE 이다 (--migrate 가 $AS_WANT 로 갈아 끼운다)"
        fi
        if [ -s "$MIGTAR" ]; then
          say "묶음이 있다: $MIGTAR ($(stat -c %s "$MIGTAR" 2>/dev/null)바이트 · md5 $(md5sum "$MIGTAR" | awk '{print $1}'))"
          # 🔴 풀기 전에 **안을 센다.** 「파일이 왔다」와 「담겼다」는 다르다.
          TSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -c '^drizzle/[0-9].*\.sql$')
          TJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
          say "묶음 안 — .sql ${TSQL:-?}장 · idx ${TJRN:-?}개"
          if [ "${TSQL:-0}" = "$AS_WANT" ] && [ "${TJRN:-0}" = "$AS_WANT" ]; then
            ok "묶음 안이 $AS_WANT 이다 (풀면 볼륨이 맞아진다)"
          else
            bad "🔴 묶음 안이 .sql ${TSQL:-?} · idx ${TJRN:-?} 다 — **$AS_WANT 이어야 한다.** 다시 묶어 올리세요"
            doubt
          fi
          if [ -n "${MIGTAR_MD5:-}" ] && [ -n "${MIGTAR_SIZE:-}" ]; then
            M=$(md5sum "$MIGTAR" | awk '{print $1}')
            S=$(stat -c %s "$MIGTAR" 2>/dev/null)
            [ "$S" = "$MIGTAR_SIZE" ] && ok "묶음 크기가 구울 때와 같다  [배포본]" \
              || bad "묶음 크기가 다르다 (${S} ≠ ${MIGTAR_SIZE}) — 옮기다 끊겼다  [배포본]"
            [ "$M" = "$MIGTAR_MD5" ] && ok "묶음 md5 가 구울 때와 같다  [배포본]" \
              || bad "묶음 md5 가 다르다 — 옮기다 깨졌다  [배포본]"
          else
            hm "묶음의 잰 값이 이 파일에 없다 — 39-build.sh 의 출력에서 MIGTAR_SIZE·MIGTAR_MD5 를 채우세요"
          fi
        else
          if [ "$MODE" = check ]; then
            hm "묶음이 아직 없다: $MIGTAR — **올리기 전이면 정상**이다"
          else
            bad "🔴 묶음이 없다: $MIGTAR — 이것 없이는 $AS_WANT 로 못 간다"
          fi
          say "올리는 법 (개발 PC · PowerShell):"
          cmd "cd C:\\Users\\희만\\Desktop\\Development\\_images-36"
          cmd "scp -O as-migrations.tar.gz dss-nas:$INCOMING/"
          say "🔴 tar 에 드라이브 문자(C:)를 주지 마세요 — 원격 호스트로 읽습니다."
        fi ;;
  NODIR) bad "🔴 $MIGDIR 폴더가 **없다** — compose 가 $AS_TOOLS_SVC 에 붙이는 그 폴더다" ;;
  *)    bad "🔴 볼륨이 $AS_HAVE 도 $AS_WANT 도 아니다 (.sql ${MIG_N_SQL} · idx ${MIG_N_J})"
        say "→ 고치지 말고 **먼저 알리세요.**"; doubt ;;
esac

# ── 3. 들여올 이미지 넷 ───────────────────────────────────────────────
#  🔴 넷이다 — 앱 셋 + **포털 도구**. 도구를 빠뜨리기 쉽고, 빠뜨린 것은
#     비상구를 써야 하는 날에만 드러난다.
printf '\n== 3. 들여올 이미지 넷 (앱 셋 + 포털 도구)\n'
BLANK=0
for t in $(trows); do
  TAR=$(fld "$t" 1); WSZ=$(fld "$t" 2); WM5=$(fld "$t" 3); WCFG=$(fld "$t" 4)
  T=$IMGD/$TAR
  if [ ! -s "$T" ]; then
    # 🔴 모드마다 기대값이 다르다. --check 는 **올리기 전이 정상**이고,
    #    --rollback 은 새 tar 가 아예 필요 없다(옛 이미지로 돌아가는 일이다).
    #    한 잣대로 재면 되돌릴 길이 가짜 ✗ 로 막힌다.
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
  [ "$SZ"  = "$WSZ"  ] && ok "$TAR 크기가 구울 때와 같다  [배포본]" || { bad "$TAR 크기가 다르다 (${SZ} ≠ ${WSZ}) — 옮기다 깨졌다"; doubt; }
  [ "$M5"  = "$WM5"  ] && ok "$TAR md5 가 같다  [배포본]"           || { bad "$TAR md5 가 다르다 — 옮기다 깨졌다"; doubt; }
  [ "$CFG" = "$WCFG" ] && ok "$TAR 지문이 같다  [배포본]"           || { bad "$TAR 지문이 다르다 (${CFG:-못 읽음}) — **다른 판을 올렸다**"; doubt; }
done
if [ "$BLANK" != "0" ]; then
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 39-build.sh --go 가 마지막에 찍어 주는"
  printf '%s\n' "     다섯 줄을 이 파일의 TARS(앞 넷)와 MIGTAR_SIZE·MIGTAR_MD5(마지막)에 넣으세요."
fi
# 🔴 도구 이미지가 **이미 실려 있으면** 그 자리에서 안을 센다. 안 실렸으면
#    6절이 싣고 7절이 다시 센다 — 거기가 막는 자리다.
if "$DOCKER" image inspect "$TOOLS_NEW" >/dev/null 2>&1; then
  tools_inside_check
else
  if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
    hm "$TOOLS_NEW 가 아직 안 실렸다 — **${MODE} 에서는 괜찮다**. 6절이 싣는다"
  else
    say "$TOOLS_NEW 가 아직 안 실렸다 — 6절이 싣고 7절이 안을 센다"
  fi
fi
# 🔵 되돌릴 길 — 옛 태그가 남아 있는가
for r in $(rows); do
  OLD=$(fld "$r" 5)
  if "$DOCKER" image inspect "$OLD" >/dev/null 2>&1; then ok "$OLD 이 남아 있다 (되돌릴 길)"
  else hm "$OLD 이 없다 — 그 시스템은 --rollback 을 못 쓴다"; fi
done

# ── 4. 백업 ───────────────────────────────────────────────────────────
#
# 🔴 **야간 백업(02:30)에 기대지 않는다.** 배포는 자정을 넘겨 도는 일이 잦고
#    (서른다섯째는 01:43 에 준비했다), 그러면 「오늘 백업이 없다」로 막힌다.
#    기다리는 것보다 **--migrate 가 그 자리에서 덤프를 뜨는** 편이 낫다 —
#    더 최신이고 시각에 안 매인다. 37번·31번이 같은 판단이었다.
#    🔵 그래서 여기서는 **재기만 하고 막지 않는다.** 막는 자리는 --migrate 다.
printf '\n== 4. 백업 — **DB 가 바뀌는 배포다**\n'
# 🔴 **백업 파일 이름은 하이픈이 있다** — `dss_as_2026-10-27_0230.dump`.
#    2026-10-27 첫 실행에서 `date +%Y%m%d`(=20261027)로 grep 해 **여섯 개가 있는데도
#    「없다」**가 나왔다. 재는 쪽이 틀린 가짜 경고였다. 막는 자리가 아니라 피해는
#    없었지만, 그대로 두면 다음 사람이 이 줄을 믿는다.
#    🔵 그 뒤 야간 작업이 이름 꼴을 바꿔도 걸리도록 **둘 다** 본다.
TODAY=$(date +%Y-%m-%d)
TODAY_NODASH=$(date +%Y%m%d)
if [ -d "$BKDB" ]; then
  say "최근 백업 여섯:"
  ls -1t "$BKDB" 2>/dev/null | head -6 | sed 's/^/      /'
  HIT=$(ls -1 "$BKDB" 2>/dev/null | grep -cE "$TODAY|$TODAY_NODASH")
  if [ "${HIT:-0}" -gt 0 ]; then ok "오늘($TODAY) 백업이 ${HIT}개 있다"
  else hm "오늘($TODAY) 야간 백업이 아직 없다 (02:30 에 돈다) — 🔵 --migrate 가 그 자리에서 뜬다"; fi
  ok "백업 폴더에 닿는다 ($BKDB)"
else
  bad "$BKDB 가 없거나 못 읽는다 — 🔴 root 로 돌리고 있는지 보세요"
fi

# ── 5. 🔴 DB 셋의 지금 ────────────────────────────────────────────────
#  🔴 「맞으면 되나」와 「틀리면 안 되나」를 둘 다 본다 — A/S 는 **늘어야** 맞고
#     포털·재고는 **그대로여야** 맞다. 한 잣대로 재면 가짜 ✗ 가 난다.
printf '\n== 5. DB 셋의 지금\n'
MIG_AS0=$(mig_count "$AS_BOX" "$AS_DB")
MIG_AU0=$(mig_count "$AUTH_BOX" "$AUTH_DB")
MIG_IN0=$(mig_count "$INV_BOX" "$INV_DB")
say "A/S ${MIG_AS0:-?} (기대 $AS_HAVE → $AS_WANT) · 포털 ${MIG_AU0:-?} (기대 $AUTH_KEEP 그대로) · 재고 ${MIG_IN0:-?} (기대 $INV_KEEP 그대로)"
if [ -z "${MIG_AS0:-}" ] || [ -z "${MIG_AU0:-}" ] || [ -z "${MIG_IN0:-}" ]; then
  bad "DB 를 못 쟀다 — dss-pg-app · dss-pg-auth 가 도는지 보세요"
else
  ok "DB 셋에 붙어 잴 수 있다"
  if [ "$MIG_AS0" = "$AS_HAVE" ]; then ok "A/S 가 $AS_HAVE 다 (적용 전 — 맞다)"
  elif [ "$MIG_AS0" = "$AS_WANT" ]; then hm "A/S 가 이미 $AS_WANT 다 (--migrate 를 이미 돌렸다)"
  else bad "🔴 A/S 가 $AS_HAVE 도 $AS_WANT 도 아니다 (${MIG_AS0}) — 멈추고 알릴 것"; doubt; fi
  [ "$MIG_AU0" = "$AUTH_KEEP" ] && ok "포털이 $AUTH_KEEP 이다  [README]" \
    || { bad "🔴 포털이 ${MIG_AU0} 이다 ($AUTH_KEEP 이어야 한다) — 이 배포는 포털 마이그레이션을 **돌릴 길이 없다**"; doubt; }
  [ "$MIG_IN0" = "$INV_KEEP" ] && ok "재고가 $INV_KEEP 이다  [README]" \
    || { bad "🔴 재고가 ${MIG_IN0} 이다 ($INV_KEEP 이어야 한다) — 이 배포는 재고 마이그레이션을 **돌릴 길이 없다**"; doubt; }
fi
# 🔴 생길 것 셋 — 지금은 **없어야** 맞다(적용 전). 있으면 이미 돌린 것이다.
T0=$(has_table  "$AS_BOX" "$AS_DB" "$AS_NEW_TABLE")
C0=$(has_column "$AS_BOX" "$AS_DB" "$AS_NEW_COL_TABLE" "$AS_NEW_COL")
I0=$(has_index  "$AS_BOX" "$AS_DB" "$AS_NEW_INDEX")
say "표 $AS_NEW_TABLE ${T0:-?} · 칸 $AS_NEW_COL_TABLE.$AS_NEW_COL ${C0:-?} · 인덱스 ${I0:-?}"
if [ "${T0:-x}" = "0" ] && [ "${C0:-x}" = "0" ]; then ok "셋 다 아직 없다 (적용 전 — 맞다)"
elif [ "${T0:-x}" = "1" ] && [ "${C0:-x}" = "1" ]; then hm "셋 다 이미 있다 (--migrate 를 이미 돌렸다)"
else bad "🔴 표 ${T0:-?} · 칸 ${C0:-?} — 반만 적용된 꼴이다. 멈추고 알릴 것"; fi

if [ "$MODE" = check ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.** 다음: --preload → (다시 --check) → --migrate → --go"
  printf '%s\n' "🔴 올리기 전에 돌리면 ? 가 여럿 나오는 것이 **정상**이다 (tar · 묶음)."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 6. --preload : tar 넷을 들여놓는다 ───────────────────────────────
#  🔴 앱 셋이 아니라 **TARS 넷**을 돈다 — 포털 도구가 거기 있다. 앱 표(SITES)만
#     돌면 도구가 조용히 빠지고, 7절이 그것을 ✗ 로 잡지만 한 걸음 늦다.
if [ "$MODE" = preload ] || [ "$MODE" = migrate ] || [ "$MODE" = go ]; then
  printf '\n== 6. tar 넷을 들여놓는다\n'
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
    # 🔴 NAS 는 tar 안의 config 지문을 image ID 로 낸다. 맞댈 값은 **tar 쪽**이다.
    if [ "$FULL" = "$WCFG" ]; then ok "$NEW 가 올라왔고 지문이 tar 와 같다"
    elif [ -n "$FULL" ]; then bad "$NEW 지문이 다르다 — tar $WCFG / NAS $FULL"
    else bad "$NEW 가 안 올라왔다"; fi
  done
fi

if [ "$MODE" = preload ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **들여놓기만 했다 — 아직 안 갈아 끼웠다.** 다음: --check 를 다시 → --migrate"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 7. --migrate : 🔴 DB 가 바뀐다 ────────────────────────────────────
if [ "$MODE" = migrate ]; then
  printf '\n== 7. 🔴 마이그레이션 — A/S DB 가 바뀐다 (%s → %s)\n' "$AS_HAVE" "$AS_WANT"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **DB 를 안 건드리고 멈춘다.**\n'; exit 1; fi

  # ── 7-ㄱ. 🔴 지금 이 자리에서 덤프를 뜬다 ───────────────────────────
  #   🔴 **이것이 되돌릴 길이다.** 야간 백업(02:30)을 기다리지 않는다.
  #      마이그레이션은 되돌아가지 않으므로, 덤프 없이는 시작하지 않는다.
  printf '\n    ── 먼저 덤프를 뜬다\n'
  DUMP="$BKDB/dss_as-v36-$STAMP.dump"
  if "$DOCKER" exec -i "$AS_BOX" sh -c 'pg_dump -U "$POSTGRES_USER" -d dss_as -Fc' > "$DUMP" 2>/dev/null; then
    DSZ=$(stat -c %s "$DUMP" 2>/dev/null || wc -c < "$DUMP")
    say "덤프 $DUMP (${DSZ:-?}바이트)"
    # 🔴 「파일이 생겼다」와 「쓸 만한 덤프다」는 다르다. 빈 파일도 생긴다.
    if [ "${DSZ:-0}" -gt 10240 ]; then ok "덤프가 ${DSZ}바이트다 (10KB 넘음)"
    else bad "덤프가 ${DSZ:-0}바이트뿐이다 — 쓸 수 없다. **DB 를 안 건드리고 멈춘다**"; fi
    # 🔴 **속을 본다.** -Fc 덤프는 첫 다섯 글자가 PGDMP 다. 파이프로 pg_restore 를
    #    먹이는 길은 판에 따라 「읽을 수 없는 보관본」으로 죽으므로 쓰지 않는다.
    MAGIC=$(head -c 5 "$DUMP" 2>/dev/null)
    say "덤프 머리 다섯 글자: ${MAGIC:-없음}"
    [ "$MAGIC" = "PGDMP" ] && ok "제대로 된 -Fc 덤프다" || bad "머리가 PGDMP 가 아니다 — 덤프가 아니거나 깨졌다"
    chmod 600 "$DUMP" 2>/dev/null
  else
    bad "덤프를 못 떴다 — **DB 를 안 건드리고 멈춘다**"
  fi
  say "⚠️ PO 가 **같은 $AS_DB 를 보고 있다** — 덤프 중에 PO 에서 저장한 것은 이"
  say "   덤프에 안 들어갈 수 있다. 그래서 이것은 마지막 수단이고, 되돌리기의"
  say "   기본은 **앱만 되돌리고 DB 는 그대로 두는 것**이다(표·칸을 더하기만 했다)."
  if [ "$FAIL" != 0 ]; then printf '\n🔴 되돌릴 길이 없다 — **멈춘다.**\n'; exit 1; fi

  # ── 7-ㄴ. 🔴 적용 전 줄 수를 적어 둔다 ──────────────────────────────
  printf '\n    ── 적용 전 줄 수 (적용 뒤에 **그대로여야** 한다)\n'
  CNT_BEFORE=""
  for F in $AS_COUNT_TABLES; do
    V=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $F")
    CNT_BEFORE="$CNT_BEFORE as.$F=${V:-?}"; say "dss_as.$F ${V:-?}줄"
  done
  for F in $INV_COUNT_TABLES; do
    V=$(pgn "$INV_BOX" "$INV_DB" "select count(*) from $F")
    CNT_BEFORE="$CNT_BEFORE inv.$F=${V:-?}"; say "dss_inventory.$F ${V:-?}줄"
  done
  for F in $AUTH_COUNT_TABLES; do
    V=$(pgn "$AUTH_BOX" "$AUTH_DB" "select count(*) from $F")
    CNT_BEFORE="$CNT_BEFORE auth.$F=${V:-?}"; say "dss_auth.$F ${V:-?}줄"
  done

  # ── 7-ㄷ. 🔴 compose 의 tools-auth 를 :2 → :3 으로 ──────────────────
  #   🔴 37번이 한 그 방식 그대로 — 사본을 먼저 뜨고, image: 줄이 **꼭 하나만**
  #      달라졌는지 세고, 어긋나면 **사본으로 되돌리고 멈춘다.**
  #   🔵 tools-auth 는 profiles: [tools] 라 평소에 뜨지 않는다. 도는 컨테이너는
  #      compose 를 읽지 않으므로 이 한 줄을 고쳐도 **직원이 느끼는 것이 없다.**
  #      up -d 를 부르지 않는다.
  #   🔴 이 자리를 DB 앞에 둔다 — 여기서 어긋나면 DB 를 안 건드리고 끝난다.
  printf '\n    ── compose 의 %s 를 %s 로\n' "$AUTH_TOOLS_SVC" "$TOOLS_NEW"
  cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
  chmod 644 "$BK"
  ok "사본 $BK"
  TL0=$(wc -l < "$CF"); TI0=$(grep -c '^ *image:' "$CF")
  TB=$(mktemp) || exit 1; TA=$(mktemp) || exit 1
  grep -n '^ *image:' "$CF" > "$TB"
  APPB=$(app_img_lines)            # 🔴 앱 셋은 **하나도 안 바뀌어야** 한다
  TAL=$(img_line "$AUTH_TOOLS_SVC") || { bad "$AUTH_TOOLS_SVC 를 못 찾았다"; rm -f "$TB" "$TA"; exit 1; }
  if [ "$(tag_at "$TAL")" = "$TOOLS_NEW" ]; then
    ok "$AUTH_TOOLS_SVC 가 이미 $TOOLS_NEW 다 — 고칠 것이 없다"
    rm -f "$TB" "$TA"
  else
    TMP=$(mktemp) || exit 1
    awk -v n="$TAL" -v to="$TOOLS_NEW" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
    cp "$TMP" "$CF"; rm -f "$TMP"
    grep -n '^ *image:' "$CF" > "$TA"
    TDIFF=$(diff "$TB" "$TA" | grep -c '^[<>]')
    APPA=$(app_img_lines)
    say "줄 수 $TL0 → $(wc -l < "$CF") · image: 줄 $TI0 → $(grep -c '^ *image:' "$CF") · 달라진 image: 줄 $((TDIFF / 2))개"
    [ "$(tag_at "$TAL")" = "$TOOLS_NEW" ] && ok "$AUTH_TOOLS_SVC → $TOOLS_NEW (${TAL}줄)" \
      || bad "$AUTH_TOOLS_SVC 의 태그가 $(tag_at "$TAL") 다"
    [ "$(wc -l < "$CF")" = "$TL0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
    [ "$(grep -c '^ *image:' "$CF")" = "$TI0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
    # 🔴 **꼭 하나**다. 둘이면 남의 것을 건드렸다.
    [ "$((TDIFF / 2))" = "1" ] && ok "image: 줄이 **꼭 하나만** 달라졌다 (도구 한 줄)" \
      || bad "image: 줄이 $((TDIFF / 2))개 달라졌다 — 남의 것을 건드렸다"
    # 🔴 앱 셋은 --go 의 일이다. 여기서 바뀌면 안 된다.
    [ "$APPA" = "$APPB" ] && ok "앱 셋의 image: 줄은 하나도 안 바뀌었다 (--go 의 일이다)" \
      || bad "🔴 앱 image: 줄이 바뀌었다 — 이 단계가 건드릴 자리가 아니다"
    dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"
    rm -f "$TB" "$TA"
    if [ "$FAIL" != 0 ]; then
      printf '\n🔴 어긋났다 — **사본으로 되돌리고 DB 는 안 건드린다.**\n'
      cp "$BK" "$CF"; say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $TL0)"
      exit 1
    fi
  fi

  # ── 7-ㄹ. 🔴 도구 이미지 안을 센다 — 비상구가 실제로 들어갔는가 ─────
  #   🔴 「태그를 고쳤다」와 「쓸 수 있다」는 다르다. 겉이 아니라 결과를 본다.
  if "$DOCKER" image inspect "$TOOLS_NEW" >/dev/null 2>&1; then
    tools_inside_check
  else
    bad "🔴 $TOOLS_NEW 가 NAS 에 없다 — compose 가 없는 이미지를 가리키게 됐다"
  fi
  if [ "$FAIL" != 0 ]; then
    printf '\n🔴 도구가 온전하지 않다 — **사본으로 되돌리고 DB 는 안 건드린다.**\n'
    cp "$BK" "$CF"; exit 1
  fi

  # ── 7-ㅁ. 🔴 볼륨을 121 로 갈아 끼운다 ──────────────────────────────
  printf '\n    ── A/S 마이그레이션 볼륨을 %s 로\n' "$AS_WANT"
  read_migdir
  if [ "$MIG_STATE" = OLD ]; then
    if [ ! -s "$MIGTAR" ]; then
      bad "🔴 볼륨이 아직 $AS_HAVE 인데 갈아 끼울 묶음이 없다: $MIGTAR"
      printf '\n🔴 **DB 도 앱도 그대로다.** 묶음을 올린 뒤 다시 부르세요.\n'
      exit 1
    fi
    place_migs || { printf '\n🔴 **DB 도 앱도 그대로다.**\n'; exit 1; }
    read_migdir
  fi
  say "지금 $MIGDIR — .sql ${MIG_N_SQL}장 · meta/_journal.json 의 idx ${MIG_N_J}개"
  [ "$MIG_N_SQL" = "$AS_WANT" ] && ok ".sql 이 ${MIG_N_SQL}장이다" \
    || bad ".sql 이 ${AS_WANT}장이 아니다 (${MIG_N_SQL}장)"
  [ "$MIG_N_J" = "$AS_WANT" ] && ok "meta/_journal.json 의 idx 가 ${MIG_N_J}개다" \
    || bad "idx 가 ${AS_WANT}개가 아니다 (${MIG_N_J}개) — 🔴 적용이 **0건으로 끝난다**"
  check_new_migs || true
  if [ "$FAIL" != 0 ]; then printf '\n🔴 마이그레이션 파일이 온전하지 않다 — **DB 도 앱도 그대로다.**\n'; exit 1; fi
  # 🔴 컨테이너가 **실제로 그 폴더를 읽는지** 본다. 겉이 아니라 결과다 —
  #    호스트에서 보이는 것과 컨테이너 안에서 보이는 것이 다를 수 있다.
  INSQL=$(dct run --rm --entrypoint sh "$AS_TOOLS_SVC" -c "ls -1 $IMG_MIGDIR/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r' | tail -1)
  say "$AS_TOOLS_SVC 안에서 본 $IMG_MIGDIR 의 .sql: ${INSQL:-?}장"
  if [ "${INSQL:-0}" = "$AS_WANT" ]; then ok "컨테이너 안에서도 $AS_WANT 장이다 (볼륨이 제대로 붙었다)"
  else bad "컨테이너 안이 ${INSQL:-?}장이다 — $AS_WANT 장이어야 한다. **0건으로 끝날 수 있다**"; fi
  if [ "$FAIL" != 0 ]; then printf '\n🔴 **DB 도 앱도 그대로다.** 멈춘다.\n'; exit 1; fi

  # ── 7-ㅂ. 적용 전 preflight — 사라질 자료가 있는지 ──────────────────
  printf '\n    ── 적용 전 db:preflight (앱은 아직 옛 판으로 살아 있다)\n'
  dct run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | tail -20 | sed 's/^/    /'
  PRC=${PIPESTATUS[0]}
  say "(종료 코드 $PRC — 기대 0 · 대기 **2건**)"
  if [ "$PRC" != 0 ]; then
    bad "db:preflight 가 0 이 아니다 ($PRC) — 사라질 자료가 있다는 뜻이다"
    say "→ 🔴 0119·0120 에는 그럴 문장이 없다(지우는 문장 0줄을 위에서 셌다). **다른 것이 섞였다.**"
    printf '\n🔴 **DB 를 안 건드리고 멈춘다.** 앱 셋은 그대로 돈다.\n'
    exit 1
  fi

  printf '\n'
  say "🔴 이제 DB 를 바꿉니다. 그만두려면 **20초 안에 Ctrl+C**."
  say "   지금 Ctrl+C 하면 DB 는 손대지 않은 채로 남습니다."
  say "   (볼륨은 이미 $AS_WANT 로 바뀌었지만 그것만으로는 아무 일도 안 일어납니다 —"
  say "    읽는 것은 $AS_TOOLS_SVC 뿐이고 부를 때만 잠깐 돕니다.)"
  sleep 20

  # ── 7-ㅅ. 돌린다 ────────────────────────────────────────────────────
  printf '\n    ── 돌린다\n'
  if [ "$MIG_AS0" = "$AS_WANT" ]; then
    ok "이미 $AS_WANT 이다 — 건너뛴다 (drizzle 은 다시 돌려도 안전하다)"
  else
    dct run --rm "$AS_TOOLS_SVC" npm run db:migrate 2>&1 | tail -25 | sed 's/^/    /'
    RC=${PIPESTATUS[0]}
    if [ "$RC" = 0 ]; then ok "A/S db:migrate 끝 (종료 코드 0)"
    else
      bad "A/S db:migrate 실패 (종료 코드 $RC)"
      say "🔵 앱 셋은 **그대로 옛 판으로 돕니다.** 직원이 느끼는 것이 없습니다."
      printf '\n🔴 덤프: %s\n' "$DUMP"
      exit 1
    fi
  fi

  # ── 7-ㅇ. 🔴 값으로 확인 (겉이 아니라 결과) ─────────────────────────
  printf '\n    ── 🔴 값으로 확인\n'
  MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
  MIG_AU1=$(mig_count "$AUTH_BOX" "$AUTH_DB")
  MIG_IN1=$(mig_count "$INV_BOX" "$INV_DB")
  say "A/S ${MIG_AS0:-?} → ${MIG_AS1:-?} · 포털 ${MIG_AU0:-?} → ${MIG_AU1:-?} · 재고 ${MIG_IN0:-?} → ${MIG_IN1:-?}"
  [ "${MIG_AS1:-x}" = "$AS_WANT" ] && ok "A/S 가 $AS_WANT 다 (둘 늘었다)" \
    || { bad "🔴 A/S 가 ${MIG_AS1:-?} 다 — $AS_WANT 이어야 한다"; doubt; }
  # 🔴 「늘면 ✗」 쪽. 이 배포는 포털·재고 마이그레이션을 **돌리지 않았다.**
  [ "${MIG_AU1:-x}" = "$AUTH_KEEP" ] && ok "포털이 $AUTH_KEEP 그대로다 (안 건드렸다)" \
    || bad "🔴 포털이 ${MIG_AU1:-?} 다 — $AUTH_KEEP 그대로여야 한다. **이 배포가 건드렸다**"
  [ "${MIG_IN1:-x}" = "$INV_KEEP" ] && ok "재고가 $INV_KEEP 그대로다 (안 건드렸다)" \
    || bad "🔴 재고가 ${MIG_IN1:-?} 다 — $INV_KEEP 그대로여야 한다. **이 배포가 건드렸다**"
  T1=$(has_table  "$AS_BOX" "$AS_DB" "$AS_NEW_TABLE")
  C1=$(has_column "$AS_BOX" "$AS_DB" "$AS_NEW_COL_TABLE" "$AS_NEW_COL")
  I1=$(has_index  "$AS_BOX" "$AS_DB" "$AS_NEW_INDEX")
  [ "${T1:-0}" = "1" ] && ok "표 $AS_NEW_TABLE 가 생겼다" || bad "🔴 표 $AS_NEW_TABLE 가 없다"
  [ "${C1:-0}" = "1" ] && ok "칸 $AS_NEW_COL_TABLE.$AS_NEW_COL 이 생겼다" || bad "🔴 칸 $AS_NEW_COL 이 없다"
  [ "${I1:-0}" = "1" ] && ok "인덱스 $AS_NEW_INDEX 가 생겼다" || bad "🔴 인덱스가 없다 — 목록이 느려진다"

  printf '\n    ── 🔴 줄 수가 그대로인가 (하나라도 줄었으면 자료가 사라진 것이다)\n'
  for F in $AS_COUNT_TABLES; do
    V=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $F")
    B=$(printf '%s' "$CNT_BEFORE" | tr ' ' '\n' | sed -n "s/^as\\.$F=//p")
    [ "${V:-x}" = "${B:-y}" ] && ok "dss_as.$F ${V}줄 — 그대로" \
      || bad "🔴 dss_as.$F 가 ${B:-?} → ${V:-?} 로 **달라졌다**"
  done
  for F in $INV_COUNT_TABLES; do
    V=$(pgn "$INV_BOX" "$INV_DB" "select count(*) from $F")
    B=$(printf '%s' "$CNT_BEFORE" | tr ' ' '\n' | sed -n "s/^inv\\.$F=//p")
    [ "${V:-x}" = "${B:-y}" ] && ok "dss_inventory.$F ${V}줄 — 그대로" \
      || bad "🔴 dss_inventory.$F 가 ${B:-?} → ${V:-?} 로 **달라졌다**"
  done
  for F in $AUTH_COUNT_TABLES; do
    V=$(pgn "$AUTH_BOX" "$AUTH_DB" "select count(*) from $F")
    B=$(printf '%s' "$CNT_BEFORE" | tr ' ' '\n' | sed -n "s/^auth\\.$F=//p")
    [ "${V:-x}" = "${B:-y}" ] && ok "dss_auth.$F ${V}줄 — 그대로" \
      || bad "🔴 dss_auth.$F 가 ${B:-?} → ${V:-?} 로 **달라졌다**"
  done

  printf '\n    ── 적용 뒤 db:preflight — **대기 0건**이어야 한다\n'
  dct run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | tail -15 | sed 's/^/    /'
  say "(종료 코드 ${PIPESTATUS[0]})"

  printf '\n    ── 🔴 앱 셋이 **여전히 옛 판으로** 도는가 (--go 가 아직 안 돌았다)\n'
  "$DOCKER" ps --format '{{.Names}}\t{{.Image}}' 2>/dev/null | sort | sed 's/^/      /'

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$FAIL" = 0 ]; then
    printf '%s\n' "✅ A/S DB 가 바뀌었다. **앱 셋은 아직 옛 판이다.** 다음: --go"
    printf '%s\n' "  🔵 0119 는 표 하나를, 0120 은 칸 하나를 더하기만 한다 — 옛 판 3.1 이"
    printf '%s\n' "     그것을 몰라도 멀쩡히 돈다. 그래서 --rollback 으로 앱만 되돌릴 수 있다."
    printf '%s\n' "  🔴 되돌릴 길(마이그레이션 전 덤프): $DUMP"
    printf '%s\n' "  🔵 옛 볼륨: $MIGDIR.old — **그대로 두세요**"
    printf '%s\n' "  🔵 compose 의 $AUTH_TOOLS_SVC 도 $TOOLS_NEW 가 됐다 (사본: $BK)"
    printf '%s\n' "     비상구 둘이 이제 컨테이너에서 돈다 — 쓸 일이 생긴 날의 길:"
    printf '%s\n' "       cd /volume1/dss/deploy"
    printf '%s\n' "       $DOCKER compose -f docker-compose.nas.yml --env-file .env.nas \\"
    printf '%s\n' "         --profile tools run --rm $AUTH_TOOLS_SVC npm run admin:promote"
  else
    printf '%s\n' "🔴 위 ✗ 를 보세요. 🔵 마이그레이션은 **다시 돌려도 안전하다**: bash $0 --migrate"
  fi
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 8. --go / --rollback : 앱 태그 셋을 바꾼다 ────────────────────────
printf '\n== 8. compose 의 앱 태그 셋을 바꾼다\n'
if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi

# 🔴 --go 는 마이그레이션이 끝난 뒤여야 한다. 안 끝났으면 3.2 가 없는 표를 읽는다.
if [ "$MODE" = go ]; then
  G1=$(has_table  "$AS_BOX" "$AS_DB" "$AS_NEW_TABLE")
  G2=$(has_column "$AS_BOX" "$AS_DB" "$AS_NEW_COL_TABLE" "$AS_NEW_COL")
  G3=$(mig_count  "$AS_BOX" "$AS_DB")
  say "표 ${G1:-?} · 칸 ${G2:-?} · A/S 기록 ${G3:-?} (기대 $AS_WANT)"
  [ "${G1:-0}" = "1" ] && ok "표 $AS_NEW_TABLE 가 있다" || bad "표가 없다 — 🔴 --migrate 를 먼저 돌리세요"
  [ "${G2:-0}" = "1" ] && ok "칸 $AS_NEW_COL 이 있다"   || bad "칸이 없다 — 🔴 --migrate 를 먼저 돌리세요"
  [ "${G3:-x}" = "$AS_WANT" ] && ok "A/S 기록이 $AS_WANT 다" || bad "A/S 기록이 ${G3:-?} 다 — 🔴 --migrate 를 먼저 돌리세요"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 마이그레이션이 덜 됐다 — **멈춘다.**\n'; exit 1; fi
fi

cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
chmod 644 "$BK"
ok "사본 $BK"
L0=$(wc -l < "$CF"); IMGS0=$(grep -c '^ *image:' "$CF")
BEF=$(mktemp) || exit 1
AFT=$(mktemp) || exit 1
grep -n '^ *image:' "$CF" > "$BEF"
# 🔴 공유폴더 두 줄(RF 이슈관리)이 살아남는지도 센다 — 남의 것을 건드리면 안 된다.
C7_0=$(grep -cE '^[[:space:]]*- .*:/mnt/nas7:ro' "$CF"); C1_0=$(grep -cE '^[[:space:]]*- .*:/mnt/nas1:ro' "$CF")
# 🔴 도구 image: 줄을 **글자 그대로** 적어 둔다. --go 는 앱만 건드리므로 여기서는
#    **하나도 안 바뀌어야** 맞다(도구는 --migrate 가 이미 :2 → :3 으로 고쳤다).
#    🔵 줄 **수**만 세면 :2 → :3 처럼 값만 바뀐 것을 못 잡는다. 그래서 글자로 본다.
TOOLS_B=$(tools_img_lines)

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

L1=$(wc -l < "$CF"); IMGS1=$(grep -c '^ *image:' "$CF")
grep -n '^ *image:' "$CF" > "$AFT"
DIFFN=$(diff "$BEF" "$AFT" | grep -c '^[<>]')
rm -f "$BEF" "$AFT"
C7_1=$(grep -cE '^[[:space:]]*- .*:/mnt/nas7:ro' "$CF"); C1_1=$(grep -cE '^[[:space:]]*- .*:/mnt/nas1:ro' "$CF")
TOOLS_A=$(tools_img_lines)
say "줄 수 $L0 → $L1 · image: 줄 $IMGS0 → $IMGS1 · 달라진 image: 줄 $((DIFFN / 2))개"
[ "$L1" = "$L0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
[ "$IMGS1" = "$IMGS0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
# 🔴 **남의 image: 줄을 건드리면 안 된다.** 달라진 것이 꼭 셋이어야 한다.
[ "$((DIFFN / 2))" = "3" ] && ok "image: 줄이 꼭 셋만 달라졌다 (우리 것)" || bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — 남의 것을 건드렸다"
# 🔴 도구 줄은 **글자까지** 그대로여야 한다. 고치는 자리는 --migrate 다.
[ "$TOOLS_A" = "$TOOLS_B" ] && ok "도구 image: 줄이 글자까지 그대로다 (--go 는 앱만 건드린다)" \
  || { bad "🔴 도구 image: 줄이 달라졌다 — --go 가 건드릴 자리가 아니다"; say "전: $TOOLS_B"; say "후: $TOOLS_A"; }
[ "$C7_1" = "$C7_0" ] && [ "$C1_1" = "$C1_0" ] && ok "RF 이슈관리의 공유폴더 두 줄이 그대로다" || bad "공유폴더 줄이 달라졌다 ($C7_0→$C7_1 · $C1_0→$C1_1)"
dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 9. 셋을 다시 띄운다 ───────────────────────────────────────────────
printf '\n== 9. 셋을 다시 띄운다\n'
printf '%s\n' "🔴 --no-deps 다 — 이 셋만 갈아 끼운다. 나머지 일곱과 DB 둘은 안 건드린다."
for r in $(rows); do
  CN=$(fld "$r" 3)
  say "$CN 지금: $("$DOCKER" inspect -f '{{.Id}}' "$CN" 2>/dev/null | cut -c1-12)"
done
# 🔵 DB 둘의 시작 시각을 적어 둔다 — 교체 뒤에 **그대로인지** 본다. 말로 하지 않는다.
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

# ── 10. 값으로 확인 ───────────────────────────────────────────────────
printf '\n== 10. 값으로 확인\n'
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

# 🔴 포털의 **옛** 통로가 안 깨졌는지 — 이번 판에는 새 통로가 없다.
#    자격 없이 부르면 401 이 맞다. 404 면 포털이 안 떴거나 다른 것이 돈다.
printf '\n    ── 포털의 옛 통로 (자격 없이 부르면 401 이 맞다)\n'
NC=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 -X POST \
      -d 'approverSub=none' http://127.0.0.1:13100/api/integration/approval-created 2>/dev/null)
say "POST /api/integration/approval-created → ${NC:-없음}"
if [ "${NC:-}" = "401" ]; then ok "포털의 통로가 그대로 서 있고 자격 없는 호출을 막는다"
elif [ "${NC:-}" = "404" ]; then bad "404 다 — 포털이 엉뚱한 판으로 떴다"
else hm "${NC:-없음} 이다 — 401 을 기대했다. 로그를 보세요"; fi

# 🔴 **안 건드린 일곱이 그대로 도는지** 센다 — 「옆으로 안 샜다」는 증거다.
printf '\n    ── 안 건드린 일곱 (그대로여야 한다)\n'
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
  [ "${s:-x}" = "${b:-y}" ] && ok "$c 가 안 멈췄다" || bad "🔴 $c 가 다시 떴다 (${b:-?} → ${s:-?})"
done

printf '\n    ── 최근 로그 (각 12줄)\n'
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
  printf '%s\n' "🔴 **마지막은 눈이다** — 이번 판에는 새 HTTP 통로가 없어 기계로는 여기까지다."
  printf '%s\n' "   쓰는 분이 볼 곳:"
  printf '%s\n' "     · A/S 사용자 화면에서 **결재권 위임**을 하나 만들고 되돌려 본다"
  printf '%s\n' "     · 그 기간 안에 결재를 올려 **대리인에게 단계가 가는지** 본다"
  printf '%s\n' "     · 견적서 결재 이력에 **「누구 자리였나」**가 이름으로 뜨는가"
  printf '%s\n' "     · 재고에서 **관리자가 남의 결재권을 맡길 수 있는가**"
  printf '%s\n' "     · 🔵 포털 **화면**은 이번 판에서 달라지는 것이 없다 — 평소대로 로그인되면 된다."
  printf '%s\n' "       달라진 것은 **도구 이미지**다(비상구 둘). 화면으로는 안 보인다."
  printf '%s\n' "  🔵 비상구를 **한 번 눌러 보고 싶다면** (아무것도 안 바꾸는 꼴):"
  printf '%s\n' "       cd /volume1/dss/deploy"
  printf '%s\n' "       $DOCKER compose -f docker-compose.nas.yml --env-file .env.nas \\"
  printf '%s\n' "         --profile tools run --rm $AUTH_TOOLS_SVC npm run admin:promote"
  printf '%s\n' "     🔴 인자를 안 주면 **쓰는 법만 찍고 끝난다** — 그것이 보이면 길이 열린 것이다."
  printf '%s\n' "        옛 --env-file= 이었다면 그 줄에 닿기 전에 .env.local 이 없다고 죽었다."
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (앱만 되돌린다. 표·칸·도구는 남는다)"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
