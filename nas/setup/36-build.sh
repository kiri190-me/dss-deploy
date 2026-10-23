#!/bin/bash
# dss-deploy/nas/setup/36-build.sh — 서른넷째 배포 · 이미지 굽기 (2026-10-23)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · Git Bash) ────────────────────────────────────
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/36-build.sh" --check
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/36-build.sh" --go
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-34):
#     bash .../36-build.sh --go "/d/배포본/_images-34"
#
# ── 이번에 굽는 것 셋 ─────────────────────────────────────────────────
#     ① A/S       dss-as:2.9           → **dss-as:3.0**            커밋 2
#     ② 재고      dss-inventory:0.3    → **dss-inventory:0.4**     커밋 5
#     ③ 개선요청  dss-improvements:0.4 → **dss-improvements:0.5**  커밋 1
#
#   🔵 **나머지 여섯은 안 굽는다** — 포털 1.8 · PO 0.7 · 게시판 0.3 · 휴가 0.3 ·
#      계측기 1.4 · RF 이슈관리 0.2 는 기준 SHA 이후 커밋이 **0** 이다(실측).
#   🔵 **tools 이미지도 안 굽는다** — 세 곳 다 마이그레이션 **0건**이라 바뀐 것이 없다.
#
# ── 🔴 모드 둘 ────────────────────────────────────────────────────────
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다.
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면
#            굽지 않고 멈춘다. 전부 ✓ 일 때만 셋을 굽고 tar 로 뽑는다.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 이 환경의 함정 (31-build.sh 에서 그대로 가져온 처방) ───────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싸고, 저장소 자리를 적어
#      넣지 않고 **이 파일의 자리에서 계산한다**(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** `to_unix()` 가 `C:\…` 를 `/c/…` 로
#      바꾸고, `docker save` 는 **작업 폴더로 들어가 상대경로**로 쓴다.
#   ③ 🔴 **tar 의 Config 를 `docker image inspect .Id` 와 맞대지 마라.** 요즘
#      Docker 는 그 둘이 애초에 다른 값이다(하나는 config 블롭, 하나는 매니페스트).
#      맞댈 상대는 **빌드 로그의 `exporting config sha256:`** 이다.
#   ④ 🔵 `docker build` 는 개발 서버를 안 내려도 된다 — `.dockerignore` 가 `.next` 를
#      막아 호스트의 `.next` 가 빌드 문맥에 아예 안 들어간다. 다만 **메모리**는
#      다르다. 아홉이 떠 있으면 빌드가 죽을 수 있다.
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEV=${DSS_DEV:-$(cd "$SCRIPT_DIR/../../.." && pwd)}

PASS=0; FAIL=0; UNK=0
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
unk()  { UNK=$((UNK+1));   printf '  ? %s — 못 쟀다 (%s)\n' "$1" "$2"; }
note() { printf '  ⚠️ %s\n' "$1"; }
say()  { printf '    %s\n' "$1"; }

isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }

# 🔴 C:\… 또는 C:/… 를 /c/… 로. tar 는 드라이브 문자를 원격 호스트로 읽는다.
to_unix() { # 1 경로
  local p=${1//\\//}
  case "$p" in
    [A-Za-z]:/*) p=/$(printf '%s' "${p%%:*}" | tr 'A-Z' 'a-z')${p#?:} ;;
  esac
  printf '%s' "$p"
}

tar_name() { printf '%s.tar' "$(printf '%s' "$1" | tr ':' '-')"; }

# tar 안 manifest.json 의 Config 지문 (30-deploy.sh 의 tar_config_id 를 그대로)
tar_config_id() { # 1 tar
  tar -xOf "$1" manifest.json 2>/dev/null \
    | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 \
    | sed 's|blobs/sha256/|sha256:|'
}

# ══ 이번에 굽는 것 — 한자리에 모아 둔다 ═══════════════════════════════
#   열쇠|저장소 폴더|새 태그|기준 SHA(지금 떠 있는 판이 담은 커밋)
SITES='
as|RF_Service_System|dss-as:3.0|37b5e34
inventory|dss-inventory|dss-inventory:0.4|f046338
improvements|dss-improvements|dss-improvements:0.5|f45bdd5
'

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-34"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

printf '%s\n' "서른넷째 배포 · 이미지 굽기   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  저장소 뿌리: $DEV"
printf '%s\n' "  tar 둘 자리: $OUT"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 1. 도커가 도는가 ──────────────────────────────────────────────────
printf '\n== 1. 도커\n'
if docker version --format '{{.Server.Version}}' >/dev/null 2>&1; then
  ok "도커가 돈다 (서버 $(docker version --format '{{.Server.Version}}' 2>/dev/null))"
else
  bad "도커가 안 돈다 — Docker Desktop 을 켜세요"
fi

# ── 2. 저장소 셋 ──────────────────────────────────────────────────────
printf '\n== 2. 저장소 셋\n'
printf '%s\n' "🔴 미커밋·미푸시가 있으면 구운 이미지를 나중에 재현하지 못한다."
printf '%s\n' "🔴 **안 받은 것도 센다** — 낡은 코드를 굽고도 모른다."
printf '%s\n' "$SITES" | while IFS='|' read -r KEY REPO TAG BASE; do
  [ -n "${KEY:-}" ] || continue
  DIR="$DEV/$REPO"
  printf '  ── %s (%s → %s)\n' "$KEY" "$REPO" "$TAG"
  if [ ! -d "$DIR/.git" ] && [ ! -f "$DIR/.git" ]; then
    printf '  ✗ %s — git 저장소가 아니다 (%s)\n' "$REPO" "$DIR"; continue
  fi
  dirty=$(git -C "$DIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if isnum "${dirty:-}" && [ "$dirty" -eq 0 ]; then printf '  ✓ %s 미커밋 0\n' "$REPO"
  else printf '  ✗ %s 미커밋 %s 줄\n' "$REPO" "${dirty:-?}"; git -C "$DIR" status --porcelain=v1 2>/dev/null | head -5 | sed 's/^/      /'; fi
  if git -C "$DIR" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    up=$(git -C "$DIR" log --oneline '@{u}..HEAD' 2>/dev/null | wc -l | tr -d ' ')
    dn=$(git -C "$DIR" log --oneline 'HEAD..@{u}' 2>/dev/null | wc -l | tr -d ' ')
    if [ "${up:-1}" = "0" ] && [ "${dn:-1}" = "0" ]; then printf '  ✓ %s 미푸시 0 · 안받음 0\n' "$REPO"
    else printf '  ✗ %s 미푸시 %s · 안받음 %s\n' "$REPO" "${up:-?}" "${dn:-?}"; fi
  else
    printf '  ? %s 미푸시 — 올려다볼 가지가 없다\n' "$REPO"
  fi
  # 🔵 기준 SHA 가 조상인지 — 아니면 표가 낡았거나 가지가 갈렸다.
  if git -C "$DIR" merge-base --is-ancestor "$BASE" HEAD 2>/dev/null; then
    n=$(git -C "$DIR" log --oneline "$BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
    m=$(git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | wc -l | tr -d ' ')
    printf '  ✓ %s 기준 %s 이후 커밋 %s개 · 마이그레이션 %s개\n' "$REPO" "$BASE" "$n" "$m"
    if [ "${m:-0}" != "0" ]; then printf '  ✗ %s — 🔴 마이그레이션이 늘었다. 이번 배포는 0건을 전제로 짰다. 멈추고 알릴 것\n' "$REPO"; fi
  else
    printf '  ✗ %s — 기준 SHA %s 가 조상이 아니다 (표가 낡았거나 가지가 갈렸다)\n' "$REPO" "$BASE"
  fi
  printf '    지금 HEAD: %s\n' "$(git -C "$DIR" log -1 --format='%h %s' 2>/dev/null)"
done

# 🔴 위 while 이 파이프라인 안이라 **셈이 안 넘어온다.** 다시 세어 FAIL 에 싣는다.
REPO_BAD=0
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}; BASE=${rest#*|}
  DIR="$DEV/$REPO"
  d=$(git -C "$DIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  u=$(git -C "$DIR" log --oneline '@{u}..HEAD' 2>/dev/null | wc -l | tr -d ' ')
  n=$(git -C "$DIR" log --oneline 'HEAD..@{u}' 2>/dev/null | wc -l | tr -d ' ')
  m=$(git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | wc -l | tr -d ' ')
  git -C "$DIR" merge-base --is-ancestor "$BASE" HEAD 2>/dev/null || REPO_BAD=$((REPO_BAD+1))
  [ "${d:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
  [ "${u:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
  [ "${n:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
  [ "${m:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
done
if [ "$REPO_BAD" = "0" ]; then ok "저장소 셋 전부 깨끗하고 마이그레이션 0건"
else bad "저장소 검사에서 어긋난 것 ${REPO_BAD}가지 — 위 ✗ 를 보세요"; fi

# ── 3. 태그가 이미 있나 ───────────────────────────────────────────────
printf '\n== 3. 새 태그가 이미 있나\n'
printf '%s\n' "🔵 있으면 **덮어쓴다** — 같은 커밋이면 같은 것이 나오므로 해롭지 않다."
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  rest=${row#*|}; rest=${rest#*|}; TAG=${rest%%|*}
  if docker image inspect "$TAG" >/dev/null 2>&1; then note "$TAG — 이미 있다 (덮어쓴다)"
  else ok "$TAG — 아직 없다"; fi
done

# ── 4. tar 둘 자리 ────────────────────────────────────────────────────
printf '\n== 4. tar 둘 자리\n'
if [ "$MODE" = "--go" ]; then
  mkdir -p "$OUT" 2>/dev/null
fi
if [ -d "$OUT" ]; then ok "$OUT 가 있다"
elif [ "$MODE" = "--check" ]; then note "$OUT 가 아직 없다 (--go 가 만든다)"
else bad "$OUT 를 못 만들었다"; fi

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
if [ "$FAIL" != "0" ] || [ "$UNK" != "0" ]; then
  printf '%s\n' "🔴 멈춘다 — 위 ✗ / ? 를 먼저 보세요. **아무것도 안 구웠다.**"
  exit 1
fi
if [ "$MODE" = "--check" ]; then
  printf '%s\n' "🔵 **아무것도 안 구웠다.** 전부 통과했으니 이어서: --go"
  exit 0
fi

# ══ 굽기 ══════════════════════════════════════════════════════════════
printf '\n%s\n' "════════ 굽는다 ════════"
BUILT=0; BFAIL=0
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}
  DIR="$DEV/$REPO"
  FILE=$(tar_name "$TAG")
  LOG="$OUT/build-$(printf '%s' "$TAG" | tr ':' '-').log"
  printf '\n── %s  (%s)\n' "$TAG" "$REPO"

  # 🔵 마지막 스테이지가 runner 라 --target 을 안 준다(31-build.sh 와 같다).
  if ( cd "$DIR" && docker build -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG" | tail -3; then
    printf '  ✓ 구웠다\n'
  else
    printf '  ✗ 굽기 실패 — %s 를 보세요\n' "$LOG"; BFAIL=$((BFAIL+1)); continue
  fi

  # 🔴 docker save 는 작업 폴더로 들어가 **상대경로**로 쓴다(tar 의 드라이브 문자 함정).
  if ( cd "$OUT" && docker save "$TAG" -o "$FILE" ) </dev/null; then
    sz=$(stat -c %s "$OUT/$FILE" 2>/dev/null || wc -c < "$OUT/$FILE")
    printf '  ✓ tar %s (%s바이트)\n' "$FILE" "$sz"
  else
    printf '  ✗ tar 내보내기 실패\n'; BFAIL=$((BFAIL+1)); continue
  fi

  # 🔴 tar 의 Config 를 **빌드 로그의 exporting config** 와 맞댄다.
  cfg=$(tar_config_id "$OUT/$FILE")
  exp=$(grep -oE "exporting config sha256:[0-9a-f]+" "$LOG" | tail -1 | grep -oE "sha256:[0-9a-f]+")
  printf '    tar  %s\n' "${cfg:-못 읽음}"
  printf '    로그 %s\n' "${exp:-없음}"
  if [ -n "$cfg" ] && [ -n "$exp" ] && [ "$cfg" = "$exp" ]; then printf '  ✓ 지문이 빌드 로그와 같다\n'
  elif [ -z "$exp" ]; then printf '  ⚠️ 빌드 로그에 exporting config 가 없다 (buildx 판에 따라 안 찍힌다)\n'
  else printf '  ✗ 지문이 다르다\n'; BFAIL=$((BFAIL+1)); continue; fi

  printf '    md5  %s\n' "$(md5sum "$OUT/$FILE" | awk '{print $1}')"
  BUILT=$((BUILT+1))
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  구운 것 %s / 3 · 실패 %s\n' "$BUILT" "$BFAIL"
if [ "$BFAIL" != "0" ]; then printf '%s\n' "🔴 실패가 있다. 위를 보세요."; exit 1; fi
printf '%s\n' "✅ 셋 다 구웠다. tar 와 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'
printf '\n%s\n' "🔵 다음: 이 폴더의 tar 셋을 NAS 의 /volume1/dss/images/ 로 올린다 (대화에서 내가 한다)."
printf '%s\n' "────────────────────────────────────────────────────────────"
