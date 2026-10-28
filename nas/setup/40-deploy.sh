#!/bin/bash
# dss-deploy/nas/setup/40-deploy.sh — 서른일곱째 배포 (2026-10-28)
#
# 🔴 NAS 에서 돈다. DSM 터미널은 긴 명령을 잘라 먹으므로 **파일로 올려** 돌린다.
#    md5 를 맞춘다:  md5sum /volume1/dss/setup/40-deploy.sh
#
# ── 사람이 실행한다 ───────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/40-deploy.sh            ← 읽기만 한다
#   (NAS)         bash /volume1/dss/setup/40-deploy.sh --preload
#   (NAS)         bash /volume1/dss/setup/40-deploy.sh --go       ⏱ 정지 창
#
# ── 갈아 끼우는 것 둘 ─────────────────────────────────────────────────
#     ① A/S       dss-as:3.2          → **dss-as:3.3**          커밋 8 (조각 13)
#     ② RF 이슈관리 dss-rf-trouble:0.2 → **dss-rf-trouble:0.3**  커밋 1
#
#   🔴 **마이그레이션이 없다.** A/S 의 drizzle/ 이 기준 SHA 이후 0건, RF 이슈관리는
#      애초에 DB 가 없다. 그래서 이 파일에는 **--migrate 모드가 없다** — DB 를
#      건드리는 단계가 **한 군데도 없다.**
#   🔵 **나머지 여덟은 안 건드린다** — 포털 2.0 · 재고 0.6 · PO 0.7 · 게시판 0.3 ·
#      계측기 1.4 · 개선요청 0.5 · 휴가 0.4 · 통합 승인함 0.1 은
#      기준 SHA 이후 커밋이 **0** 이다(2026-10-28 실측).
#
# ── 이 배포가 하는 일 ─────────────────────────────────────────────────
#   **A/S — 재고 걷어내기 조각 13 전체.** 옛 재고 화면·서버 액션·알림·권한 키를
#   A/S 에서 지운다(재고는 재고관리 저장소로 넘어갔다). 동작이 바뀌는 자리는
#   둘뿐이다 — ① 알림 설정 표가 8줄→5줄(재고 알림 셋이 빠진다) ② 영업 담당자의
#   「재고 관리」 권한이 「접근 불가」로 선다.
#   **RF 이슈관리 — 쿠키 다섯을 한 자리(cookieAttrs)에서 짓는다.** 세션·시스템
#   목록·왕복 쿠키(rfsso) 가 각자 속성을 적고 있었는데, 왕복 쿠키 하나에만
#   Secure 가 안 붙어 있었다. 이제 하나가 짓고 다섯이 그것을 쓴다.
#
# ── 🔴 A/S 는 **대량으로 지우는 배포**다 — 되돌릴 길을 분명히 ──────────
#   28,500줄을 지웠지만 **DB 는 한 글자도 안 바뀐다**(마이그레이션 0건). 그래서
#   되돌리기는 **옛 이미지 태그로 돌아가는 것뿐**이고 자료 손실이 전혀 없다:
#     bash /volume1/dss/setup/40-deploy.sh --rollback
#   🔵 앱만 갈아 끼우므로 **DB 덤프조차 뜨지 않는다** — 뜰 이유가 없다(39번·31번과
#      다른 점이다. 그쪽은 DB 가 바뀌어서 덤프가 되돌릴 유일한 길이었다).
#
# ── 🔴 RF 이슈관리 — 배포 뒤 **로그아웃·로그인 왕복을 꼭 확인** ────────
#   이번 커밋이 쿠키 다섯을 한 자리에서 짓도록 바꿨다. 속성이 어긋나면
#   **로그인은 되는데 로그아웃이 안 되거나 그 반대**가 된다 — 화면에 오류가 안
#   나서 조용하다. 기계로는 Secure 플래그가 실제로 브라우저를 오가는지까지는
#   재지 못한다(세션을 실제로 맺어야 한다) — **마지막은 눈이다.**
#   🔴 포트를 127.0.0.1 로 좁힌 변경도 있었다 — 운영 compose 는 이미
#      127.0.0.1:13900 으로 좁혀 있어 **영향이 없지만**, 리버스 프록시를 통한
#      접속이 그대로 되는지는 이 파일이 값으로 확인한다(10절).
#
# ── 🔴 39번(지난 판)과 다른 것 — 이번이 더 작다 ────────────────────────
#   ① 🔴 **--migrate 모드가 없다.** DB 가 전혀 안 바뀐다. 39번은 A/S 볼륨을
#      119 → 121 로 갈아 끼우고 포털 도구를 :2 → :3 으로 고치는 단계가 있었다.
#      이번엔 그 자리가 통째로 없다.
#   ② 🔴 **도구 이미지가 없다.** dss-as-tools:1 도 안 바뀌고, 포털 도구도 이번
#      배포와 무관하다 — 건드리지 않는다.
#   ③ 🔵 **DB 덤프를 뜨지 않는다.** 바꾸는 것이 없으니 뜰 이유가 없다.
#   ④ 🔴 **공유폴더 두 줄(RF 이슈관리의 nas7·nas1)을 이번에도 센다** — compose
#      를 건드리는 모든 배포가 공통으로 지키는 것이다(33·35·39번과 같다).
#
# ── 🔴 개발 PC → NAS 로 올릴 것 — **셋** (마이그레이션 묶음이 없다) ─────
#   ㄱ) 이미지 tar **둘** → /volume1/dss/images/
#        dss-as-3.3.tar · dss-rf-trouble-0.3.tar
#   ㄴ) 이 파일 → /volume1/dss/setup/
#
#   (개발 PC · PowerShell)
#     cd C:\Users\희만\Desktop\Development\_images-37
#     scp -O dss-as-3.3.tar dss-rf-trouble-0.3.tar dss-nas:/volume1/dss/images/
#     cd C:\Users\희만\Desktop\Development
#     scp -O dss-deploy\nas\setup\40-deploy.sh dss-nas:/volume1/dss/setup/
#     Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\40-deploy.sh
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#   🔴 tar 에 드라이브 문자(C:)를 주지 마세요 — 원격 호스트로 읽습니다.
#
# ── 모드 넷 ───────────────────────────────────────────────────────────
#   (기본)   --check      아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --preload             tar 둘을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --go                  compose 의 앱 태그 둘을 바꾸고 다시 띄운다
#   --rollback            둘을 옛 판으로 되돌린다 (🔵 DB 가 안 바뀌었으므로
#                         자료 손실 없이 그냥 태그만 되돌리면 된다)
#
#   🔴 차례:  --check → --preload → --check → --go
#
# ── 🔴 --check 도 「아무것도 안 한다」는 아니다 ───────────────────────
#   A/S DB 에 **select** 를 한 번 보낸다(마이그레이션 수가 그대로인지 — 바꾸는
#   문장은 없다). 앱 둘의 바깥 주소에 GET 을 한 번씩 보낸다.
#   「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안의 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 쓴 뒤 세었다.
#   ② 읽기 전용 자리에 콜론 하나와 꺾쇠로 빈 파일을 만들면 NAS 의 ash 가 셸을
#      그 자리에서 끝낸다(2026-10-12 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#
# ── 🔴 비밀값을 찍지 않는다 ───────────────────────────────────────────
#   .env 는 **이름이 있는가/없는가**만 본다. 값도, 값의 길이도 찍지 않는다.
#   이번 판에는 새로 필요한 설정 이름이 없다 — RF 이슈관리의 COOKIE_SECURE 는
#   선택값이고(기본 auto), 비워 두면 이번 커밋이 의도한 그대로 동작한다.
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v37-$STAMP

# ══ 이번에 갈아 끼우는 앱 둘 ══════════════════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
SITES='
as|app-as|dss-as|dss-as:3.3|dss-as:3.2|dss-as-3.3.tar|13000
trouble|app-rf-trouble|dss-rf-trouble|dss-rf-trouble:0.3|dss-rf-trouble:0.2|dss-rf-trouble-0.3.tar|13900
'
# ══ 🔴 tar 둘의 지문 — [배포본] 40-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 비어 있다.** 40-build.sh --go 가 끝에 찍어 주는 두 줄을 여기에
#      그대로 붙여 넣는다. 비어 있으면 3절이 **? 로 센다** — 「옮기다 깨진
#      것」은 잡지만 「개발 PC 에서 구운 그것이 맞나」는 못 본다.
TARS='
dss-as-3.3.tar|132217856|6be15ab24abe7b4f793704c47a28d510|sha256:29ec08ff5833459620ee362fd99703e0f22b91f0cebf492311f0cf85a96c3173
dss-rf-trouble-0.3.tar|63245312|7a6adeafa4f389158e528337cac62e41|sha256:ca780052a4625b330e1fff9d2534c60aa987a955ed5882e1a972d9e1142dd5f4
'
tar2tag() {
  case "$1" in
    dss-as-3.3.tar)         printf 'dss-as:3.3' ;;
    dss-rf-trouble-0.3.tar) printf 'dss-rf-trouble:0.3' ;;
  esac
}

# ══ 🔴 A/S — DB 는 **그대로여야** 한다(마이그레이션 0건) ═════════════
AS_BOX=dss-pg-app; AS_DB=dss_as; AS_KEEP=121   # [저장소] 40-build.sh 4절과 같다
AS_TOOLS_SVC=tools-as
AS_TOOLS_IMG=dss-as-tools:1                    # 🔵 이번엔 **안 건드린다** — 확인만 한다
# 🔵 안 건드리는 여덟 — 「옆으로 안 샜다」는 증거로 센다
KEEP_BOXES="dss-auth dss-inventory dss-meters dss-po dss-board dss-improvements dss-leave dss-approvals"
# 🔵 DB 둘은 멈추지 않는다 (애초에 up -d --no-deps 가 app 둘만 건드린다)
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
LOG="$D/setup/logs/40-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "서른일곱째 배포 — A/S · RF 이슈관리   $(date '+%Y-%m-%d %H:%M:%S')"
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

# 🔴 운영 DB 를 **앱이 쓰는 길**(컨테이너 안 psql)로 잰다. 소켓·루프백으로 재면
#    trust 라 그냥 통과한다. 보내는 SQL 은 select 뿐이다.
pgq() { # 1 상자 2 DB 3 SQL
  "$DOCKER" exec -i "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -X -tAq -c \"$3\"" 2>/dev/null | head -1 | tr -d ' \r'
}
pgn() { local v; v=$(pgq "$1" "$2" "$3"); isnum "$v" && printf '%s' "$v"; }
mig_count() { pgn "$1" "$2" 'select count(*) from drizzle.__drizzle_migrations'; }

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
# 🔴 A/S 도구 — **안 건드린다.** 그래도 제자리에 맞는 것이 있는지만 본다.
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  say "$AS_TOOLS_SVC — ${TL}줄 · $TCUR  (🔵 이번엔 **안 건드린다**)"
  [ "$TCUR" = "$AS_TOOLS_IMG" ] && ok "$AS_TOOLS_SVC 가 $AS_TOOLS_IMG 그대로다 (고칠 것이 없다)" \
    || hm "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $AS_TOOLS_IMG 를 기대했지만, 이번 배포가 그것을 바꾸지 않으므로 막지 않는다"
else
  hm "compose 에 $AS_TOOLS_SVC 가 없다 — 이번 배포와 무관하다"
fi

# ── 2. 🔴 A/S DB — 마이그레이션 수가 **그대로여야** 한다 ──────────────
#  🔴 이번 판은 DB 를 전혀 안 건드린다. 「늘면 ✗」다 — 늘었다면 이 배포의
#     전제(마이그레이션 0건) 자체가 깨진 것이다.
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
printf '\n== 3. 들여올 이미지 둘\n'
BLANK=0
for t in $(trows); do
  TAR=$(fld "$t" 1); WSZ=$(fld "$t" 2); WM5=$(fld "$t" 3); WCFG=$(fld "$t" 4)
  T=$IMGD/$TAR
  if [ ! -s "$T" ]; then
    # 🔴 모드마다 기대값이 다르다. --check 는 올리기 전이 정상이고, --rollback 은
    #    새 tar 가 아예 필요 없다(옛 이미지로 돌아가는 일이다).
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
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 40-build.sh --go 가 끝에 찍어 주는"
  printf '%s\n' "     두 줄을 이 파일의 TARS 에 넣으세요."
fi
# 🔵 되돌릴 길 — 옛 태그가 남아 있는가
for r in $(rows); do
  OLD=$(fld "$r" 5)
  if "$DOCKER" image inspect "$OLD" >/dev/null 2>&1; then ok "$OLD 이 남아 있다 (되돌릴 길)"
  else hm "$OLD 이 없다 — 그 시스템은 --rollback 을 못 쓴다"; fi
done

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
fi

if [ "$MODE" = preload ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **들여놓기만 했다 — 아직 안 갈아 끼웠다.** 다음: --check 를 다시 → --go"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 5. --go / --rollback : compose 의 앱 태그 둘을 바꾼다 ─────────────
printf '\n== 5. compose 의 앱 태그 둘을 바꾼다\n'
if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi

cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
chmod 644 "$BK"
ok "사본 $BK"
L0=$(wc -l < "$CF"); IMGS0=$(grep -c '^ *image:' "$CF")
BEF=$(mktemp) || exit 1
AFT=$(mktemp) || exit 1
grep -n '^ *image:' "$CF" > "$BEF"
# 🔴 공유폴더 두 줄(RF 이슈관리)이 살아남는지도 센다 — compose 를 건드리는
#    모든 배포가 공통으로 지키는 검사다(33·35·39번과 같다).
C7_0=$(grep -cE '^[[:space:]]*- .*:/mnt/nas7:ro' "$CF"); C1_0=$(grep -cE '^[[:space:]]*- .*:/mnt/nas1:ro' "$CF")

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
say "줄 수 $L0 → $L1 · image: 줄 $IMGS0 → $IMGS1 · 달라진 image: 줄 $((DIFFN / 2))개"
[ "$L1" = "$L0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
[ "$IMGS1" = "$IMGS0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
# 🔴 **남의 image: 줄을 건드리면 안 된다.** 달라진 것이 꼭 둘이어야 한다.
[ "$((DIFFN / 2))" = "2" ] && ok "image: 줄이 꼭 둘만 달라졌다 (우리 것)" || bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — 남의 것을 건드렸다"
[ "$C7_1" = "$C7_0" ] && [ "$C1_1" = "$C1_0" ] && ok "RF 이슈관리의 공유폴더 두 줄이 그대로다" || bad "공유폴더 줄이 달라졌다 ($C7_0->$C7_1 · $C1_0->$C1_1)"
dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 6. 둘을 다시 띄운다 ───────────────────────────────────────────────
printf '\n== 6. 둘을 다시 띄운다\n'
printf '%s\n' "🔴 --no-deps 다 — 이 둘만 갈아 끼운다. 나머지 여덟과 DB 둘은 안 건드린다."
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

# 🔴 RF 이슈관리 — 공유폴더 둘이 컨테이너 안에서도 보이는가
CNT=dss-rf-trouble   # SITES 의 trouble 행 3번째 칸과 같다
printf '\n    ── %s 의 공유폴더 둘\n' "$CNT"
for d in /mnt/nas7 /mnt/nas1; do
  c=$("$DOCKER" exec "$CNT" sh -c "ls -1 $d 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  if [ -n "$c" ] && [ "$c" -gt 0 ] 2>/dev/null; then ok "$d 안에 ${c}개가 보인다"
  else bad "$d 가 비었거나 못 읽는다 (${c:-못 쟀음})"; fi
done
HJ=$("$DOCKER" exec "$CNT" sh -c 'wget -qO- http://127.0.0.1:7331/api/health' 2>/dev/null)
say "/api/health → ${HJ:-응답 없음}"
printf '%s' "$HJ" | grep -q '"ok":true' && ok "건강 통로가 ok 다" || bad "건강 통로가 ok 가 아니다"

# 🔴 RF 이슈관리 — 리버스 프록시를 통한 접속이 그대로 되는가
#    바깥에서 직접 포트로 붙던 길이 있었다면 그것이 막히는 자리이기도 하다 —
#    이 길(https://issues.dss21.co.kr/)만 열려 있어야 정상이다.
printf '\n    ── 리버스 프록시 경유 접속 (https://issues.dss21.co.kr/)\n'
PC=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://issues.dss21.co.kr/" 2>/dev/null)
say "https://issues.dss21.co.kr/ → ${PC:-없음}"
case "${PC:-}" in
  2??|3??) ok "리버스 프록시를 통한 접속이 된다 ($PC)" ;;
  *) bad "🔴 https://issues.dss21.co.kr/ → ${PC:-없음} — 프록시나 포트 좁히기 쪽을 보세요" ;;
esac

# 🔴 **안 건드린 여덟이 그대로 도는지** 센다 — 「옆으로 안 샜다」는 증거다.
printf '\n    ── 안 건드린 여덟 (그대로여야 한다)\n'
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
  printf '%s\n' "🔴 **마지막은 눈이다** — 쓰는 분이 볼 곳:"
  printf '%s\n' "     A/S:"
  printf '%s\n' "       · 설정 › 알림 설정의 표가 **8줄 → 5줄**인가(재고 알림 셋이 빠졌다)"
  printf '%s\n' "       · 종 패널에도 재고 알림 줄이 없는가"
  printf '%s\n' "       · 설정 › 역할별 접근 권한에서 영업 담당자의 **재고 관리**가"
  printf '%s\n' "         **접근 불가**로 서는가(그 영역 설명 글도 새로 바뀌었다)"
  printf '%s\n' "     RF 이슈관리:"
  printf '%s\n' "       · **로그아웃 → 다시 로그인** 왕복이 끝까지 가는가"
  printf '%s\n' "       · 로그아웃을 눌렀을 때 쿠키가 실제로 브라우저에서 사라지는가"
  printf '%s\n' "         (개발자 도구 › 응용프로그램 › 쿠키 에서 rfsso 가 지워지는지)"
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (앱만 되돌린다. DB 는 안 건드렸으니"
  printf '%s\n' "               자료 손실이 없다 — 그냥 태그만 되돌아간다)"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
