#!/bin/bash
# dss-deploy/nas/setup/33-rf-trouble-shares.sh — RF 이슈관리에 공유폴더 둘 붙이기 (2026-10-23)
#
# 🔴 NAS 에서 돈다. DSM 터미널은 긴 명령을 잘라 먹으므로 **파일로 올려** 돌린다.
#    올린 뒤 md5 를 맞춘다:  md5sum /volume1/dss/setup/33-rf-trouble-shares.sh
#
# ── 무엇을 ────────────────────────────────────────────────────────────
#   compose 의 app-rf-trouble 블록에 **볼륨 두 줄**을 더한다. 그뿐이다.
#     - /volume1/7_항상필요한자료:/mnt/nas7:ro
#     - /volume1/1_기술자료:/mnt/nas1:ro
#   🔵 둘 다 읽기 전용(:ro) 이다. 이 시스템이 직원 자료를 고칠 일이 없다.
#
# ── 🔴 왜 이 두 자리인가 (2026-10-23 실측) ────────────────────────────
#   동료의 개발 서버 화면에 적힌 UNC 경로를 그대로 옮긴 것이다:
#     \\192.168.0.222\7_항상필요한자료  →  /mnt/nas7
#     \\192.168.0.222\1_기술자료        →  /mnt/nas1
#   그 IP 가 **이 NAS 자신**이라 /volume1 아래에 그대로 있다(실측으로 확인).
#   🔴 오른쪽 이름(/mnt/nas7 · /mnt/nas1)은 config.json 의 pathMap 오른쪽과
#      **글자까지 같아야** 한다. 다르면 파일을 못 찾는데 **오류가 안 난다.**
#
# ── 🔴 안전 ───────────────────────────────────────────────────────────
#   사본을 먼저 뜨고, 고친 뒤 값을 센다. 하나라도 어긋나면 **사본으로 되돌리고
#   멈춘다.** compose 는 아홉 사이트가 전부 읽는 파일이다.
#   🔵 컨테이너는 **안 건드린다.** 이 스크립트는 글자만 고친다.
set -uo pipefail

CF=/volume1/dss/deploy/docker-compose.nas.yml
BK=/volume1/dss/backups/docker-compose.nas.yml.shares-$(date +%Y%m%d-%H%M%S)
ANCHOR='/volume1/dss/rf-trouble-backup:/backup'
V7='      - "/volume1/7_항상필요한자료:/mnt/nas7:ro"'
V1='      - "/volume1/1_기술자료:/mnt/nas1:ro"'

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
say() { printf '    %s\n' "$1"; }

printf '%s\n' "RF 이슈관리 · 공유폴더 두 줄 더하기   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 1. 붙일 자리가 NAS 에 실제로 있는가 ───────────────────────────────
printf '\n== 1. 붙일 공유폴더가 실재하는가\n'
printf '%s\n' "🔴 없는 경로를 주면 도커가 그 자리에 **빈 폴더를 만들어 붙이고 오류를 안 낸다.**"
for p in /volume1/7_항상필요한자료 /volume1/1_기술자료; do
  if [ -d "$p" ]; then ok "$p 가 폴더로 있다 ($(ls -1 "$p" 2>/dev/null | wc -l)개)"
  else bad "$p 가 없다 — 멈춘다"; fi
done

# ── 2. compose 가 지금 어떤 상태인가 ──────────────────────────────────
printf '\n== 2. 고치기 전 상태\n'
if [ ! -f "$CF" ]; then bad "compose 를 못 찾았다: $CF"; fi
L0=$(wc -l < "$CF")
IMG0=$(grep -c '^ *image:' "$CF")
# 🔴 앵커도 같은 함정이 있다 — 주석 줄에 붙이면 두 줄이 **주석 더미 한가운데** 끼어
#    들어가 엉뚱한 서비스의 볼륨이 되거나 YAML 이 깨진다. 줄머리 `- ` 만 본다.
HIT=$(grep -nE "^[[:space:]]*- .*$ANCHOR" "$CF" | head -1 | cut -d: -f1)
HITN=$(grep -cE "^[[:space:]]*- .*$ANCHOR" "$CF")
say "줄 수 $L0 · image: 줄 $IMG0 · 붙일 자리 ${HIT:-없음} (주석 아닌 것 ${HITN}개)"
if [ "$HITN" = "1" ] && [ -n "$HIT" ]; then ok "붙일 자리를 꼭 하나 찾았다 (${HIT}줄, 주석 아님)"
elif [ "$HITN" = "0" ]; then bad "붙일 자리를 못 찾았다 — 주석 아닌 $ANCHOR 줄이 없다"
else bad "붙일 자리가 ${HITN}개다 — 어디에 넣을지 알 수 없다. 멈춘다"; fi
# 🔴 줄머리가 `- ` 인 것만 센다 — **주석 속 예시를 세지 않기 위해서다.**
#    compose 의 app-rf-trouble 블록에는 「여기에 이렇게 붙이면 된다」는 안내 주석이
#    들어 있고, 거기에 `:/mnt/nas7:ro` 가 글자 그대로 적혀 있다(32-rf-trouble-deploy.sh
#    가 넣은 것이다). 그냥 grep 하면 **그 주석을 세어 「이미 붙어 있다」고 잘못 멈춘다.**
#    2026-10-23 에 실제로 그렇게 멈췄다. 어제 배포본도 같은 까닭으로 줄머리를 본다.
N7=$(grep -cE '^[[:space:]]*- .*:/mnt/nas7:ro' "$CF")
N1=$(grep -cE '^[[:space:]]*- .*:/mnt/nas1:ro' "$CF")
say "지금 공유폴더 볼륨: nas7 ${N7}개 · nas1 ${N1}개"
if [ "$N7" = "0" ] && [ "$N1" = "0" ]; then ok "아직 안 붙어 있다 (기대한 상태)"
else bad "이미 붙어 있다 — 두 번 더하지 않는다. 멈춘다"; fi

if [ "$FAIL" != "0" ]; then
  printf '\n🔴 멈춘다 — 위 ✗ 를 먼저 보세요. **아무것도 안 고쳤다.**\n'; exit 1
fi

# ── 3. 사본 뜨고 고친다 ───────────────────────────────────────────────
printf '\n== 3. 사본을 뜨고 두 줄을 더한다\n'
cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
ok "사본 $BK"

TMP=$(mktemp) || exit 1
awk -v n="$HIT" -v a="$V7" -v b="$V1" 'NR==n{print; print a; print b; next} {print}' "$CF" > "$TMP"
cp "$TMP" "$CF"
rm -f "$TMP"

# ── 4. 🔴 값으로 센다. 어긋나면 되돌린다 ──────────────────────────────
printf '\n== 4. 고친 결과를 값으로 센다\n'
L1=$(wc -l < "$CF")
IMG1=$(grep -c '^ *image:' "$CF")
M7=$(grep -cE '^[[:space:]]*- .*:/mnt/nas7:ro' "$CF")
M1=$(grep -cE '^[[:space:]]*- .*:/mnt/nas1:ro' "$CF")
say "줄 수 $L0 → $L1 · image: 줄 $IMG0 → $IMG1 · nas7 $M7 · nas1 $M1"

if [ "$L1" = "$((L0 + 2))" ]; then ok "줄 수가 정확히 2 늘었다"; else bad "줄 수가 2 가 아니라 $((L1 - L0)) 늘었다"; fi
if [ "$IMG1" = "$IMG0" ]; then ok "image: 줄이 하나도 안 바뀌었다"; else bad "image: 줄 수가 달라졌다"; fi
if [ "$M7" = "1" ] && [ "$M1" = "1" ]; then ok "공유폴더 볼륨이 하나씩 들어갔다"; else bad "볼륨 수가 1·1 이 아니다"; fi

if docker compose -f "$CF" config -q >/dev/null 2>&1; then ok "바꾼 compose 의 문법이 통과했다"
else bad "문법이 깨졌다"; fi

if docker compose -f "$CF" config --services 2>/dev/null | grep -qx app-rf-trouble; then
  ok "서비스 목록에 app-rf-trouble 가 그대로 보인다"
else bad "app-rf-trouble 를 못 찾는다"; fi

printf '\n    ── 그 블록의 volumes 가 지금 이렇다:\n'
sed -n "$((HIT - 4)),$((HIT + 3))p" "$CF" | sed 's/^/      /'

if [ "$FAIL" != "0" ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'
  cp "$BK" "$CF"
  printf '    되돌렸다: %s → %s\n' "$BK" "$CF"
  printf '    지금 줄 수: %s (고치기 전과 같아야 한다: %s)\n' "$(wc -l < "$CF")" "$L0"
  exit 1
fi

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s\n' "$PASS" "$FAIL"
printf '%s\n' "🔴 compose 를 고쳤다 — **아직 아무것도 안 떴고 안 멈췄다.** 글자일 뿐이다."
printf '%s\n' "  사본: $BK"
printf '\n%s\n' "✅ 이어서 — ① 설정 파일을 바꾸고 ② 다시 띄운다:"
printf '%s\n' "    cp /volume1/dss/setup/incoming/rf-trouble-config-shares.json \\"
printf '%s\n' "       /volume1/dss/rf-trouble-data/config.json"
printf '%s\n' "    chown 1026:100 /volume1/dss/rf-trouble-data/config.json"
printf '%s\n' "    chmod 640 /volume1/dss/rf-trouble-data/config.json"
printf '%s\n' "    cd /volume1/dss/deploy && docker compose -f docker-compose.nas.yml \\"
printf '%s\n' "       --env-file .env.nas up -d --no-deps app-rf-trouble"
printf '%s\n' "  🔴 인자 없는 up -d 를 부르지 마세요 — 아홉 사이트가 전부 다시 뜬다."
printf '%s\n' "────────────────────────────────────────────────────────────"
