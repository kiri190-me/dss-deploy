#!/bin/bash
# dss-deploy/nas/setup/36-deploy.sh — 서른넷째 배포 (2026-10-23)
#
# 🔴 NAS 에서 돈다. DSM 터미널은 긴 명령을 잘라 먹으므로 **파일로 올려** 돌린다.
#    md5 를 맞춘다:  md5sum /volume1/dss/setup/36-deploy.sh
#
# ── 갈아 끼우는 것 셋 ─────────────────────────────────────────────────
#     ① A/S       dss-as:2.9           → **dss-as:3.0**            커밋 2
#     ② 재고      dss-inventory:0.3    → **dss-inventory:0.4**     커밋 5
#     ③ 개선요청  dss-improvements:0.4 → **dss-improvements:0.5**  커밋 1
#
#   🔵 **나머지 여섯은 안 건드린다** — 포털 1.8 · PO 0.7 · 게시판 0.3 · 휴가 0.3 ·
#      계측기 1.4 · RF 이슈관리 0.2 는 기준 SHA 이후 커밋이 **0** 이다(실측).
#
# ── 🔴 `--migrate` 가 없다 ────────────────────────────────────────────
#   세 곳 다 `drizzle/` 변경이 **0건**이라 돌릴 마이그레이션이 없다. 그래서
#   tools 이미지도 안 굽고 안 부른다. 그만큼 짧고 위험이 적은 배포다.
#   🔴 **마이그레이션이 생긴 날에는 이 스크립트를 쓰지 마라** — 31-deploy.sh 처럼
#      `--migrate` 를 가진 것을 쓰거나 이 파일에 그 단계를 더해야 한다.
#
# ── 모드 넷 ───────────────────────────────────────────────────────────
#   (기본)   --check      아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --preload             tar 셋을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --go                  compose 의 태그 셋을 바꾸고 다시 띄운다
#   --rollback            옛 판으로 되돌린다
set -uo pipefail

D=/volume1/dss
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v34-$(date +%Y%m%d-%H%M%S)

# ══ 이번에 갈아 끼우는 것 ═════════════════════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
SITES='
as|app-as|dss-as|dss-as:3.0|dss-as:2.9|dss-as-3.0.tar|13000
inventory|app-inventory|dss-inventory|dss-inventory:0.4|dss-inventory:0.3|dss-inventory-0.4.tar|13800
improvements|app-improvements|dss-improvements|dss-improvements:0.5|dss-improvements:0.4|dss-improvements-0.5.tar|13500
'

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

rows() { printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'; }
fld()  { printf '%s' "$1" | cut -d'|' -f"$2"; }

printf '%s\n' "서른넷째 배포 — A/S · 재고 · 개선요청   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 공통: compose 에서 그 서비스의 image: 줄을 찾는다 ─────────────────
# 🔴 compose 에는 image: 줄이 열여섯 개 있다. **그 블록 안의 것 하나만** 고쳐야 한다.
#    서비스 머리부터 다음 서비스 머리 전까지로 범위를 좁힌다.
img_line() { # 1 서비스
  local s=$1 start next
  start=$(grep -n "^  ${s}:" "$CF" | head -1 | cut -d: -f1)
  [ -n "$start" ] || return 1
  next=$(awk -v s="$start" 'NR>s && /^  [a-z]/ {print NR; exit}' "$CF")
  awk -v s="$start" -v e="${next:-999999}" 'NR>s && NR<e && /^[[:space:]]*image:/ {print NR; exit}' "$CF"
}
tag_at() { awk -v n="$1" 'NR==n {print $2}' "$CF"; }

# ── 1. 지금 상태 ──────────────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
[ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
say "compose 줄 수 $(wc -l < "$CF") · image: 줄 $(grep -c '^ *image:' "$CF")개"
for r in $(rows); do
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  L=$(img_line "$SVC") || { bad "$SVC — compose 에서 image: 줄을 못 찾았다"; continue; }
  CUR=$(tag_at "$L")
  ST=$(docker inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$(docker inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  say "$SVC — ${L}줄 · compose ${CUR} · 도는 것 ${RUN:-없음} (${ST:-?})"
  if [ "$CUR" = "$OLD" ]; then ok "$SVC 가 옛 판 $OLD 다 (갈아 끼울 준비)"
  elif [ "$CUR" = "$NEW" ]; then hm "$SVC 가 이미 $NEW 다 (다시 돌리는 중인가)"
  else bad "$SVC 의 태그가 $CUR 다 — 옛 판도 새 판도 아니다. 멈추고 알릴 것"; fi
done

# ── 2. tar 와 이미지 ──────────────────────────────────────────────────
printf '\n== 2. 들여올 이미지 셋\n'
for r in $(rows); do
  NEW=$(fld "$r" 4); TAR=$(fld "$r" 6)
  T=$IMGD/$TAR
  if [ -f "$T" ]; then
    say "$TAR — $(du -h "$T" | cut -f1) · md5 $(md5sum "$T" | awk '{print $1}')"
    ok "$TAR 가 와 있다"
  else
    bad "$TAR 가 없다: $T — 먼저 올리세요"
  fi
  HAVE=$(docker image inspect "$NEW" --format '{{.Id}}' 2>/dev/null | cut -c1-19)
  say "NAS 의 $NEW: ${HAVE:-없음}"
done
for r in $(rows); do
  OLD=$(fld "$r" 5)
  if docker image inspect "$OLD" >/dev/null 2>&1; then ok "$OLD 이 남아 있다 (되돌릴 길)"
  else hm "$OLD 이 없다 — 그 시스템은 --rollback 을 못 쓴다"; fi
done

# ── 3. --preload : tar 를 들여놓는다 ──────────────────────────────────
if [ "$MODE" = preload ] || [ "$MODE" = go ]; then
  printf '\n== 3. tar 를 들여놓는다\n'
  for r in $(rows); do
    NEW=$(fld "$r" 4); TAR=$(fld "$r" 6)
    T=$IMGD/$TAR
    if docker image inspect "$NEW" >/dev/null 2>&1; then ok "$NEW 는 이미 있다 (건너뜀)"; continue; fi
    [ -f "$T" ] || { bad "$TAR 가 없어 못 한다"; continue; }
    docker load -i "$T" 2>&1 | sed 's/^/    /'
    # 🔴 들여놓은 뒤에는 NAS 의 .Id 가 tar 의 Config 와 **같아야** 한다.
    CFG=$(tar -xOf "$T" manifest.json 2>/dev/null | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 | sed 's|blobs/sha256/|sha256:|')
    FULL=$(docker image inspect "$NEW" --format '{{.Id}}' 2>/dev/null)
    if [ -n "$FULL" ] && [ "$FULL" = "$CFG" ]; then ok "$NEW 가 올라왔고 지문이 tar 와 같다"
    elif [ -n "$FULL" ]; then bad "$NEW 지문이 다르다 — tar $CFG / 이미지 $FULL"
    else bad "$NEW 가 안 올라왔다"; fi
  done
else
  printf '\n== 3. (건너뜀)\n'
fi

if [ "$MODE" = check ] || [ "$MODE" = preload ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$MODE" = check ]; then printf '%s\n' "🔵 **아무것도 안 바꿨다.** 다음: --preload → --go"
  else printf '%s\n' "🔵 **들여놓기만 했다 — 아직 안 갈아 끼웠다.** 다음: --go"; fi
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 4. 태그를 바꾼다 ──────────────────────────────────────────────────
printf '\n== 4. compose 의 태그 셋을 바꾼다\n'
if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi

cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
ok "사본 $BK"
L0=$(wc -l < "$CF"); IMGS0=$(grep -c '^ *image:' "$CF")
BEFORE=$(grep -n '^ *image:' "$CF")
# 🔴 공유폴더 두 줄(2026-10-23 아침 작업)이 살아남는지도 센다.
C7_0=$(grep -cE '^[[:space:]]*- .*:/mnt/nas7:ro' "$CF"); C1_0=$(grep -cE '^[[:space:]]*- .*:/mnt/nas1:ro' "$CF")

for r in $(rows); do
  SVC=$(fld "$r" 2); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  [ "$MODE" = rollback ] && { TO=$OLD; } || { TO=$NEW; }
  L=$(img_line "$SVC") || { bad "$SVC — image: 줄을 못 찾았다"; continue; }
  TMP=$(mktemp) || exit 1
  awk -v n="$L" -v to="$TO" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
  cp "$TMP" "$CF"; rm -f "$TMP"
  NOW=$(tag_at "$L")
  if [ "$NOW" = "$TO" ]; then ok "$SVC → $TO (${L}줄)"; else bad "$SVC 의 태그가 $NOW 다"; fi
done

L1=$(wc -l < "$CF"); IMGS1=$(grep -c '^ *image:' "$CF")
AFTER=$(grep -n '^ *image:' "$CF")
DIFFN=$(diff <(printf '%s\n' "$BEFORE") <(printf '%s\n' "$AFTER") | grep -c '^[<>]')
C7_1=$(grep -cE '^[[:space:]]*- .*:/mnt/nas7:ro' "$CF"); C1_1=$(grep -cE '^[[:space:]]*- .*:/mnt/nas1:ro' "$CF")
say "줄 수 $L0 → $L1 · image: 줄 $IMGS0 → $IMGS1 · 달라진 image: 줄 $((DIFFN / 2))개"
[ "$L1" = "$L0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
[ "$IMGS1" = "$IMGS0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
# 🔴 **남의 image: 줄을 건드리면 안 된다.** 달라진 것이 꼭 셋이어야 한다.
[ "$((DIFFN / 2))" = "3" ] && ok "image: 줄이 꼭 셋만 달라졌다 (우리 것)" || bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — 남의 것을 건드렸다"
[ "$C7_1" = "$C7_0" ] && [ "$C1_1" = "$C1_0" ] && ok "RF 이슈관리의 공유폴더 두 줄이 그대로다" || bad "공유폴더 줄이 달라졌다 ($C7_0→$C7_1 · $C1_0→$C1_1)"
docker compose -f "$CF" config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 5. 셋을 다시 띄운다 ───────────────────────────────────────────────
printf '\n== 5. 셋을 다시 띄운다\n'
printf '%s\n' "🔴 --no-deps 다 — 이 셋만 갈아 끼운다. 나머지 여섯과 DB 는 안 건드린다."
for r in $(rows); do
  CN=$(fld "$r" 3)
  say "$CN 지금: $(docker inspect -f '{{.Id}}' "$CN" 2>/dev/null | cut -c1-12)"
done
T0=$SECONDS
SVCS=$(for r in $(rows); do printf '%s ' "$(fld "$r" 2)"; done)
( cd "$D/deploy" && docker compose -f "$CF" --env-file .env.nas up -d --no-deps $SVCS ) 2>&1 | sed 's/^/    /'
say "뜨는 것을 15초 기다린다…"; sleep 15
say "정지 구간 $((SECONDS - T0))초"

# ── 6. 값으로 확인 ────────────────────────────────────────────────────
printf '\n== 6. 값으로 확인\n'
for r in $(rows); do
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5); PORT=$(fld "$r" 7)
  [ "$MODE" = rollback ] && TO=$OLD || TO=$NEW
  ST=$(docker inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$(docker inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  HL=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}없음{{end}}' "$CN" 2>/dev/null)
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$PORT/" 2>/dev/null)
  say "$CN — ${ST:-?} · 건강 ${HL:-?} · 이미지 ${RUN:-?} · 127.0.0.1:$PORT → ${CODE:-없음}"
  [ "$ST" = running ] && ok "$CN 가 돈다" || bad "$CN 가 안 돈다 (${ST:-못 찾음})"
  [ "$RUN" = "$TO" ] && ok "$CN 가 $TO 로 돈다" || bad "$CN 가 $RUN 로 돈다"
  printf '%s' "$CODE" | grep -qE '200|30[12]|307' && ok "$CN 가 응답한다 ($CODE)" || bad "$CN 응답이 ${CODE:-없음}"
done

# 🔴 **안 건드린 여섯이 그대로 도는지** 센다 — 이것이 「옆으로 안 샜다」는 증거다.
printf '\n    ── 안 건드린 것들 (그대로여야 한다)\n'
for c in dss-auth dss-meters dss-po dss-leave dss-board dss-rf-trouble; do
  s=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  i=$(docker inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
  [ "$s" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
done

printf '\n    ── 최근 로그 (각 10줄)\n'
for r in $(rows); do
  CN=$(fld "$r" 3)
  printf '      ── %s\n' "$CN"
  docker logs --since 3m "$CN" 2>&1 | tail -10 | sed 's/^/        /'
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
if [ "$FAIL" = 0 ]; then
  printf '%s\n' "✅ 기계로 잴 수 있는 것은 전부 통과했다."
  printf '%s\n' "  compose 사본: $BK"
  printf '%s\n' "🔴 **마지막은 눈이다** — 쓰는 분이 볼 곳:"
  printf '%s\n' "     · A/S      수리건 상세 → 인수 정보 → [수정] 에 납기일·우선순위가 서는가"
  printf '%s\n' "     · 재고관리  재고 현황의 단추 넷 · [설정] → 변경 이력의 글자"
  printf '%s\n' "     · 개선요청  시스템 고르개에 열 개가 다 있는가"
  printf '%s\n' "  되돌리려면:  bash $0 --rollback"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
