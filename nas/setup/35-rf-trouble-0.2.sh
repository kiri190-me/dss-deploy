#!/bin/bash
# dss-deploy/nas/setup/35-rf-trouble-0.2.sh — RF 이슈관리 0.1 → 0.2 (2026-10-23)
#
# 🔴 NAS 에서 돈다. DSM 터미널은 긴 명령을 잘라 먹으므로 **파일로 올려** 돌린다.
#    md5 를 맞춘다:  md5sum /volume1/dss/setup/35-rf-trouble-0.2.sh
#
# ── 무엇을 ────────────────────────────────────────────────────────────
#   동료(dss260818)가 올린 6a844cb 를 받아 구운 이미지로 갈아 끼운다.
#     주간보고 「조치 및 진행상황」 → 진행 이력 중 **최신 1건만**
#     Kyosan 재촉 메일 「対応・進捗状況」 → 마지막 일본어 .msg 의 **요청 사항 원문**
#     새 통로 POST /api/msgrequests
#   🔵 **갈아 끼우기다.** 세우는 것이 아니므로 폴더·포털 등록·env 는 안 건드린다.
#
# ── 모드 넷 ───────────────────────────────────────────────────────────
#   (기본)     --check   아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --load               tar 를 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --go                 compose 의 태그를 바꾸고 다시 띄운다
#   --rollback           0.1 로 되돌린다
#
# 🔴 **오늘 아침에 붙인 공유폴더 두 줄이 살아남는지**를 --go 가 따로 잰다.
#    compose 를 건드리는 작업이라 거기서 날아가면 앱이 조용히 자료를 잃는다.
set -uo pipefail

D=/volume1/dss
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
SVC=app-rf-trouble
CNAME=dss-rf-trouble
NEW=dss-rf-trouble:0.2
OLD=dss-rf-trouble:0.1
TARF=dss-rf-trouble-0.2.tar
HPORT=13900
BK=$D/backups/docker-compose.nas.yml.v02-$(date +%Y%m%d-%H%M%S)

MODE=check
case "${1:-}" in
  --check|"") MODE=check ;;
  --load)     MODE=load ;;
  --go)       MODE=go ;;
  --rollback) MODE=rollback ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --load · --go · --rollback\n' "$1"; exit 2 ;;
esac

PASS=0; FAIL=0; WARN=0
ok()  { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
hm()  { WARN=$((WARN+1)); printf '  ? %s\n' "$1"; }
say() { printf '    %s\n' "$1"; }

printf '%s\n' "RF 이슈관리 0.1 → 0.2   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 공통: compose 에서 우리 image: 줄이 어디인가 ──────────────────────
# 🔴 compose 에는 image: 줄이 열 개 넘게 있다. **우리 블록 안의 것 하나만**
#    고쳐야 한다. 서비스 머리부터 다음 서비스 머리 전까지로 범위를 좁힌다.
SVCLINE=$(grep -n "^  ${SVC}:" "$CF" | head -1 | cut -d: -f1)
NEXTLINE=$(awk -v s="${SVCLINE:-0}" 'NR>s && /^  [a-z]/ {print NR; exit}' "$CF")
IMGLINE=$(awk -v s="${SVCLINE:-0}" -v e="${NEXTLINE:-999999}" \
  'NR>s && NR<e && /^[[:space:]]*image:[[:space:]]*dss-rf-trouble:/ {print NR; exit}' "$CF")
CURTAG=$(awk -v n="${IMGLINE:-0}" 'NR==n {print $2}' "$CF")

# ── 1. 지금 어떤 상태인가 ─────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
say "compose: ${SVC} 는 ${SVCLINE:-?}줄 · image: 는 ${IMGLINE:-못 찾음}줄 · 지금 태그 ${CURTAG:-?}"
if [ -n "$IMGLINE" ]; then ok "우리 image: 줄을 꼭 하나 찾았다"
else bad "우리 image: 줄을 못 찾았다 — 멈춘다"; fi
RUNIMG=$(docker inspect -f '{{.Config.Image}}' "$CNAME" 2>/dev/null)
RUNID=$(docker inspect -f '{{.Id}}' "$CNAME" 2>/dev/null | cut -c1-12)
ST=$(docker inspect -f '{{.State.Status}}' "$CNAME" 2>/dev/null)
say "도는 것: ${RUNIMG:-없음} · 컨테이너 ${RUNID:-없음} · ${ST:-?}"
# 🔴 줄머리 `- ` 만 센다 — 같은 블록의 안내 주석에 같은 글자가 적혀 있다.
C7=$(grep -cE '^[[:space:]]*- .*:/mnt/nas7:ro' "$CF")
C1=$(grep -cE '^[[:space:]]*- .*:/mnt/nas1:ro' "$CF")
say "공유폴더 볼륨: nas7 ${C7}개 · nas1 ${C1}개 (오늘 아침에 붙인 것)"
if [ "$C7" = "1" ] && [ "$C1" = "1" ]; then ok "공유폴더 두 줄이 지금 있다"
else bad "공유폴더 두 줄이 1·1 이 아니다 — 33 번을 먼저 보세요"; fi

# ── 2. tar 와 이미지 ──────────────────────────────────────────────────
printf '\n== 2. 들여올 이미지\n'
CFG=""        # 🔴 tar 가 없으면 아래 if 가 안 돌아 set -u 에 걸린다. 먼저 비워 둔다.
T=$IMGD/$TARF
if [ -f "$T" ]; then
  ok "tar 가 와 있다 ($(du -h "$T" | cut -f1))"
  say "md5  $(md5sum "$T" | awk '{print $1}')"
  # 🔴 맞댈 상대는 **굽는 PC 의 빌드 로그** 의 exporting config 다.
  #    (docker image inspect 의 .Id 와는 굽는 쪽에서 애초에 다른 값이다.
  #     다만 **docker load 로 올라온 뒤**에는 NAS 의 .Id 와 같아진다 — 4절이 그것을 쓴다.)
  CFG=$(tar -xOf "$T" manifest.json 2>/dev/null | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 | sed 's|blobs/sha256/|sha256:|')
  say "tar 안 Config: ${CFG:-못 읽음}"
  say "🔵 굽는 PC 의 build-dss-rf-trouble-0.2.log 의 'exporting config' 와 같아야 한다"
else
  bad "tar 가 없다: $T — 먼저 올리세요"
fi
HAVE=$(docker image inspect "$NEW" --format '{{.Id}}' 2>/dev/null | cut -c1-19)
HAVEOLD=$(docker image inspect "$OLD" --format '{{.Id}}' 2>/dev/null | cut -c1-19)
say "NAS 의 이미지: 0.2 ${HAVE:-없음} · 0.1 ${HAVEOLD:-없음}"
if [ -n "$HAVEOLD" ]; then ok "0.1 이 남아 있다 (되돌릴 길이 있다)"
else hm "0.1 이 없다 — --rollback 을 쓸 수 없다"; fi

# ── 3. --load : tar 를 들여놓는다 ─────────────────────────────────────
if [ "$MODE" = load ] || { [ "$MODE" = go ] && [ -z "$HAVE" ]; }; then
  printf '\n== 3. tar 를 들여놓는다\n'
  if [ ! -f "$T" ]; then bad "tar 가 없어 못 한다"; else
    docker load -i "$T" 2>&1 | sed 's/^/    /'
    HAVE=$(docker image inspect "$NEW" --format '{{.Id}}' 2>/dev/null | cut -c1-19)
    if [ -n "$HAVE" ]; then ok "$NEW 가 올라왔다"; else bad "$NEW 가 안 올라왔다"; fi
    # 🔴 들여놓은 뒤에는 NAS 의 .Id 가 tar 의 Config 와 **같아야** 한다.
    FULLID=$(docker image inspect "$NEW" --format '{{.Id}}' 2>/dev/null)
    if [ -n "$CFG" ] && [ "$FULLID" = "$CFG" ]; then ok "들여온 이미지가 tar 의 Config 와 같다"
    elif [ -n "$CFG" ]; then bad "지문이 다르다 — tar $CFG / 이미지 $FULLID"
    else hm "tar 의 Config 를 못 읽어 못 맞댔다"; fi
  fi
else
  printf '\n== 3. (건너뜀)\n'
fi
[ "$MODE" = load ] && { printf '\n────────────────────────────────────────────────────────────\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"; printf '%s\n' "🔵 들여놓기만 했다 — **아직 안 갈아 끼웠다.** 다음: --go"; exit $([ "$FAIL" = 0 ] && echo 0 || echo 1); }

if [ "$MODE" = check ]; then
  printf '\n────────────────────────────────────────────────────────────\n'
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.** 다음: --load (들여놓기) → --go (갈아 끼우기)"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 4. --go / --rollback : 태그를 바꾼다 ──────────────────────────────
if [ "$MODE" = rollback ]; then FROM=$NEW; TO=$OLD; else FROM=$OLD; TO=$NEW; fi
printf '\n== 4. compose 의 태그를 %s → %s 로\n' "$FROM" "$TO"
if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi
if [ "$CURTAG" = "$TO" ]; then
  ok "이미 $TO 다 — compose 는 안 고친다"
else
  cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
  ok "사본 $BK"
  L0=$(wc -l < "$CF"); IMGS0=$(grep -c '^ *image:' "$CF")
  BEFORE=$(grep -n '^ *image:' "$CF")
  TMP=$(mktemp) || exit 1
  awk -v n="$IMGLINE" -v to="$TO" 'NR==n{sub(/dss-rf-trouble:[0-9.]+/, to); print; next} {print}' "$CF" > "$TMP"
  cp "$TMP" "$CF"; rm -f "$TMP"
  L1=$(wc -l < "$CF"); IMGS1=$(grep -c '^ *image:' "$CF")
  AFTER=$(grep -n '^ *image:' "$CF")
  DIFFN=$(diff <(printf '%s\n' "$BEFORE") <(printf '%s\n' "$AFTER") | grep -c '^[<>]')
  say "줄 수 $L0 → $L1 · image: 줄 $IMGS0 → $IMGS1 · 달라진 image: 줄 $((DIFFN / 2))개"
  [ "$L1" = "$L0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
  [ "$IMGS1" = "$IMGS0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
  # 🔴 **다른 여덟 사이트의 image: 줄은 한 글자도 안 바뀌어야 한다.**
  [ "$((DIFFN / 2))" = "1" ] && ok "image: 줄이 꼭 하나만 달라졌다 (우리 것)" || bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — 남의 것을 건드렸다"
  NOWTAG=$(awk -v n="$IMGLINE" 'NR==n {print $2}' "$CF")
  [ "$NOWTAG" = "$TO" ] && ok "태그가 $TO 가 됐다" || bad "태그가 $NOWTAG 다"
  # 🔴 공유폴더 두 줄이 살아남았는가
  A7=$(grep -cE '^[[:space:]]*- .*:/mnt/nas7:ro' "$CF"); A1=$(grep -cE '^[[:space:]]*- .*:/mnt/nas1:ro' "$CF")
  [ "$A7" = "1" ] && [ "$A1" = "1" ] && ok "공유폴더 두 줄이 그대로 있다" || bad "공유폴더 줄이 날아갔다 (nas7 $A7 · nas1 $A1)"
  docker compose -f "$CF" config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"
  if [ "$FAIL" != 0 ]; then
    printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
    say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
  fi
fi

# ── 5. 다시 띄운다 ────────────────────────────────────────────────────
printf '\n== 5. %s 를 다시 띄운다\n' "$SVC"
printf '%s\n' "🔴 --no-deps 다 — 이 서비스 하나만 갈아 끼운다. 나머지 여덟은 안 건드린다."
B4=$RUNID
( cd "$D/deploy" && docker compose -f "$CF" --env-file .env.nas up -d --no-deps "$SVC" ) 2>&1 | sed 's/^/    /'
say "뜨는 것을 10초 기다린다…"; sleep 10
AF=$(docker inspect -f '{{.Id}}' "$CNAME" 2>/dev/null | cut -c1-12)
NOWIMG=$(docker inspect -f '{{.Config.Image}}' "$CNAME" 2>/dev/null)
say "컨테이너 ${B4:-없음} → ${AF:-없음} · 이미지 ${NOWIMG:-?}"
[ -n "$AF" ] && [ "$AF" != "$B4" ] && ok "컨테이너가 새 것으로 갈렸다" || bad "컨테이너가 안 갈렸다"
[ "$NOWIMG" = "$TO" ] && ok "도는 이미지가 $TO 다" || bad "도는 이미지가 $NOWIMG 다"

# ── 6. 값으로 확인 ────────────────────────────────────────────────────
printf '\n== 6. 값으로 확인\n'
ST=$(docker inspect -f '{{.State.Status}}' "$CNAME" 2>/dev/null)
HL=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}없음{{end}}' "$CNAME" 2>/dev/null)
say "상태 ${ST:-?} · 건강검사 ${HL:-?}"
[ "$ST" = running ] && ok "돌고 있다" || bad "안 돌고 있다 ($ST)"
for d in /mnt/nas7 /mnt/nas1; do
  c=$(docker exec "$CNAME" sh -c "ls -1 $d 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  if [ -n "$c" ] && [ "$c" -gt 0 ] 2>/dev/null; then ok "$d 안에 ${c}개가 보인다"
  else bad "$d 가 비었거나 못 읽는다 (${c:-못 쟀음})"; fi
done
HJ=$(docker exec "$CNAME" sh -c 'wget -qO- http://127.0.0.1:7331/api/health' 2>/dev/null)
say "/api/health → ${HJ:-응답 없음}"
printf '%s' "$HJ" | grep -q '"ok":true' && ok "건강 통로가 ok 다" || bad "건강 통로가 ok 가 아니다"
# 🔴 동료가 더한 새 통로가 **실제로 생겼는지** 본다. 없으면 404 가 온다.
RC=$(docker exec "$CNAME" sh -c 'wget -q -O /dev/null -S --post-data="{}" --header="Content-Type: application/json" http://127.0.0.1:7331/api/msgrequests 2>&1 | grep -m1 HTTP' 2>/dev/null)
say "/api/msgrequests → ${RC:-못 쟀음}"
if printf '%s' "$RC" | grep -q '404'; then bad "새 통로가 **없다** — 옛 이미지가 돌고 있다"
elif [ -n "$RC" ]; then ok "새 통로가 있다 (404 가 아니다 — 401/400 은 정상이다)"
else hm "못 쟀다"; fi
PR=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$HPORT/" 2>/dev/null)
say "127.0.0.1:$HPORT → ${PR:-못 쟀음}"
printf '%s' "$PR" | grep -qE '200|30[12]' && ok "호스트 포트가 응답한다" || hm "호스트 포트 응답이 ${PR:-없음}"

printf '\n    ── 최근 로그 25줄:\n'
docker logs --since 3m "$CNAME" 2>&1 | tail -25 | sed 's/^/      /'

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
if [ "$FAIL" = 0 ]; then
  printf '%s\n' "✅ 기계로 잴 수 있는 것은 전부 통과했다. 지금 도는 것: $TO"
  printf '%s\n' "  compose 사본: ${BK}"
  printf '%s\n' "🔴 **마지막은 눈이다** — 동료가 바꾼 자리는 시험이 하나도 안 덮는다:"
  printf '%s\n' "     · 주간보고 「조치 및 진행상황」에 줄이 **하나만** 뜨는가"
  printf '%s\n' "     · Kyosan 재촉 메일 「対応・進捗状況」에 **일본어 원문**이 뜨는가"
  printf '%s\n' "     · .msg 가 없는 이슈는 예전처럼 **번역**이 뜨는가"
  printf '%s\n' "  되돌리려면:  bash $0 --rollback"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
