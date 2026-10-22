#!/bin/bash
# dss-deploy/nas/setup/31-build.sh — 서른한째 배포 3단계: 이미지 굽기 (2026-10-22)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 ─────────────────────────────────────────────────────────
#   (개발 PC · Git Bash)
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/31-build.sh" --check
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/31-build.sh" --go
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-31):
#     bash .../31-build.sh --go "/d/배포본/_images-31"
#
# ── 🔴 모드 둘 ────────────────────────────────────────────────────────
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다.
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면
#            굽지 않고 멈춘다. 전부 ✓ 일 때만 아홉을 굽고 tar 로 뽑는다.
#   🔵 두 모드가 **같은 함수(check_all)** 로 잰다. 두 벌로 적으면 어긋난다.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. ✗ 든 ? 든 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 이 환경의 함정 — 이 파일이 지키고 있는 것 ──────────────────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싼다. 그리고 저장소
#      자리를 적어 넣지 않고 **이 파일의 자리에서 계산한다**(SCRIPT_DIR → DEV).
#      폴더를 통째로 옮겨도 그대로 돈다.
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** 그래서 드라이브 문자가 붙은
#      경로를 tar 에 넘기지 않는다. to_unix() 가 C:\... 를 /c/... 로 바꾸고,
#      docker save 는 **작업 폴더로 들어가 상대경로**로 쓴다.
#   ③ 🔴 **큰따옴표 안 백틱**과 **읽기전용 자리의 콜론-꺾쇠**는 bash -n 이
#      못 잡는다. 그래서 이 파일에는 **둘 다 한 글자도 없다**(주석까지).
#   ④ PowerShell 문법을 쓰지 않는다. 이 파일은 POSIX sh 꼴의 bash 다.
#   ⑤ 비밀값을 찍지 않는다 — .env 를 읽는 줄이 없고 --build-arg 도 안 쓴다.
#
# ── ⚠️ dev 서버 ✗ 는 이 저장소의 실측 기록과 어긋난다 — 사람이 정할 일 ─
#   이 스크립트는 **dev 서버가 떠 있으면 ✗** 로 막는다(지시서가 그렇게 정했다).
#   그런데 이 저장소에는 **반대 기록**이 있다:
#     runbook/08-PO-배포.md:298  2026-09-28 실측 — 「3600 개발 서버가 떠 있어도
#       된다. 띄워 둔 채로 구워서 확인했다. 호스트에서 npm run build 를 할 때는
#       내려야 하지만 docker build 는 다르다 — .dockerignore 가 .next 를 막아
#       호스트의 .next 가 빌드 문맥에 아예 들어가지 않는다.」
#     runbook/11-배포-점검표.html:254 도 같은 말을 한다.
#   2026-10-22 재확인: 여덟 저장소의 .dockerignore 에 **전부 .next 가 있다.**
#   🔴 그래도 막는 쪽으로 둔 것은 **더 안전한 쪽이기 때문**이고, 느슨하게 할지는
#      사람이 정한다. 정했으면 3-ㄹ 칸의 bad 를 note 로 바꾸면 된다(한 줄이다).
#
# ── 🔴 왜 굽기 전에 멈춰 세우는가 ─────────────────────────────────────
#   구운 이미지는 **그때 그 작업 폴더의 사진**이다. 커밋 안 된 줄이 섞여 있으면
#   나중에 같은 이미지를 다시 못 만든다. 서브모듈이 어긋나 있으면 화면의 글자가
#   저장소와 다른 판으로 구워진다. 그리고 같은 태그를 다시 구우면 **되돌릴 판이
#   사라진다** — 그래서 태그가 이미 있으면 ✗ 다.
#
# ══ 굽는 것 — 아홉 ════════════════════════════════════════════════════
#   🔵 포털 도구(dss-auth-tools:1)는 **이미 구워져 있다** — 여기서 안 굽는다.
#   🔵 **dss-as-tools 는 굽지 않는다** — A/S 의 마이그레이션은 이미지가 아니라
#      볼륨(/volume1/dss/as-migrations)에서 돈다.
#   🔴 **dss-inventory-tools:3 은 반드시 굽는다** — 0020~0025 가 그 안에
#      구워진다. 안 구우면 새 여섯이 **아예 존재하지 않고** 적용이 0건으로
#      조용히 끝난다(겉으로는 성공으로 보인다).
#
#   🔵 --target 조사 결과(2026-10-22 실측, 저장소마다 Dockerfile 의 FROM 을 셌다):
#      여덟 저장소 모두 마지막 스테이지가 **runner** 다. docker build 는 기본으로
#      마지막 스테이지를 굽는다 → **앱 이미지 여덟에는 --target 이 필요 없다.**
#      tools 스테이지가 있는 곳은 auth · as · inventory · board · leave · njlee ·
#      improvements 일곱이고(dss-po 에는 tools 가 없다), 이번에 그중 굽는 것은
#      **dss-inventory 의 tools 하나뿐**이다.
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail

# ── 저장소 자리 — 적어 넣지 않고 계산한다 ─────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
DEV=${DSS_DEV:-$(cd "$SCRIPT_DIR/../../.." && pwd)}

# ── 🔴 지금 운영에 선 서브모듈 포인터 (2026-10-22 실측) ────────────────
#    일곱 저장소가 전부 이 값이다. dss-auth 에는 서브모듈이 없다.
WANT_UI=1210d112f3d7d142942fa1811262dadaed293425

# ── 굽는 아홉 ─────────────────────────────────────────────────────────
#    키|저장소폴더|태그|타깃(빈칸=기본 runner)
#    🔴 칸에 빈칸 문자를 넣지 않는다 — 줄을 공백으로 쪼개 읽기 때문이다.
JOBS='
auth|dss-auth|dss-auth:1.8|
as|RF_Service_System|dss-as:2.9|
po|dss-po|dss-po:0.7|
inv|dss-inventory|dss-inventory:0.3|
invtools|dss-inventory|dss-inventory-tools:3|tools
board|dss-board|dss-board:0.3|
leave|dss-leave|dss-leave:0.3|
meters|njlee|dss-meters:1.4|
imp|dss-improvements|dss-improvements:0.4|
'

# ── 저장소 여덟 (재고는 이미지 둘을 내지만 저장소는 하나다) ────────────
#    저장소폴더|dev서버포트|사람이 부르는 이름
REPOS='
dss-auth|3100|통합로그인
RF_Service_System|3000|A/S관리
dss-po|3600|PO
dss-inventory|3800|재고관리
dss-board|3400|게시판
dss-leave|3700|휴가
njlee|3300|계측기
dss-improvements|3500|개선요청
'

# tar 아홉이면 1.5GB 쯤이다. 두 배를 여유로 본다.
NEED_KB=3000000

PASS=0; FAIL=0; UNK=0
SHATAB=''
RESULT=''

line() { printf '%s\n' "────────────────────────────────────────────────────────────"; }
sec()  { printf '\n== %s\n' "$1"; }
say()  { printf '    %s\n' "$1"; }
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
unk()  { UNK=$((UNK+1));  printf '  ? %s — 못 쟀다 (%s)\n' "$1" "$2"; }
note() { printf '  ⚠️ %s\n' "$1"; }

isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }

# ── 🔴 C:\... 또는 C:/... 를 /c/... 로 바꾼다 ──────────────────────────
#    tar 는 드라이브 문자를 **원격 호스트 이름**으로 읽는다. 이 한 줄이 없으면
#    사람이 C:\... 를 인자로 주는 순간 지문 재기가 통째로 깨진다.
to_unix() { # 1 경로
  local p=${1//\\//}
  case "$p" in
    [A-Za-z]:/*) p=/$(printf '%s' "${p%%:*}" | tr 'A-Z' 'a-z')${p#?:} ;;
  esac
  printf '%s' "$p"
}

# 태그 → tar 파일 이름 (지난 배포본들과 같은 꼴: dss-as-2.8.tar)
tar_name() { printf '%s.tar' "$(printf '%s' "$1" | tr ':' '-')"; }

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
# 🔴 30-deploy.sh 501줄의 tar_config_id() 를 **글자 그대로** 가져왔다.
#    발명하지 않는다 — 17~30번 배포본이 전부 이 꼴로 적어 왔다.
#    manifest.json 은 그 값을 blobs/sha256/0cce865e... 로 적는다. 앞의 blobs/ 를
#    떼고 sha256: 를 붙인 모양으로 낸다.
tar_config_id() { # 1 tar 경로  → sha256:<지문>
  local raw v
  raw=$(tar -xOf  "$1" manifest.json 2>/dev/null) || raw=""
  [ -n "$raw" ] || raw=$(tar -xzOf "$1" manifest.json 2>/dev/null) || raw=""
  v=$(printf '%s' "$raw" \
      | sed -n 's/.*"Config"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  v=${v##*/}; v=${v%.json}
  [ -n "$v" ] || return 1
  echo "sha256:$v"
}
have_img() { docker image inspect "$1" >/dev/null 2>&1; }
img_id()   { docker image inspect "$1" --format '{{.Id}}' 2>/dev/null; }
md5_of()   { md5sum "$1" 2>/dev/null | awk '{print $1}'; }
size_of()  { # 1 파일 → 바이트
  local n
  n=$(stat -c %s "$1" 2>/dev/null) || n=""
  [ -n "$n" ] || n=$(wc -c < "$1" 2>/dev/null | tr -d ' ')
  printf '%s' "$n"
}

# ── 그 포트에 무엇이 듣고 있나 ────────────────────────────────────────
# 🔴 netstat 이 없으면 ? 다. 「안 보인다」를 「안 떠 있다」로 세지 않는다.
have_netstat() { command -v netstat >/dev/null 2>&1; }
port_lines() { # 1 포트 → 듣고 있는 줄들
  netstat -ano 2>/dev/null | grep LISTENING | grep -E ":$1[[:space:]]"
}

# ══════════════════════════════════════════════════════════════════════
#  재기 — 🔴 --check 와 --go 가 **이 함수 하나**를 쓴다
#  돌려주는 값: 전부 ✓ 면 0, ✗ 나 ? 가 하나라도 있으면 1
# ══════════════════════════════════════════════════════════════════════
check_all() {
  PASS=0; FAIL=0; UNK=0; SHATAB=''

  # ── 0 ───────────────────────────────────────────────────────────────
  sec "0. 자리 — 저장소 폴더와 작업 폴더"
  say "저장소 자리 : $DEV"
  say "작업 폴더   : $OUT"
  if [ -d "$DEV/dss-auth" ] && [ -d "$DEV/RF_Service_System" ]; then
    ok "저장소 자리가 맞다 (dss-auth · RF_Service_System 이 보인다)"
  else
    bad "저장소 자리가 아니다 — $DEV 밑에 dss-auth 가 없다. DSS_DEV 로 일러 주세요"
    say "    예: DSS_DEV=/c/Users/희만/Desktop/Development bash $0 --check"
  fi
  case "$OUT" in
    [A-Za-z]:*) bad "작업 폴더에 드라이브 문자가 남았다 ($OUT) — tar 가 원격 호스트로 읽는다" ;;
    /*)         ok "작업 폴더가 /c/... 꼴이다 (tar 가 원격 호스트로 안 읽는다)" ;;
    *)          bad "작업 폴더가 절대경로가 아니다 ($OUT)" ;;
  esac

  # ── 1 ───────────────────────────────────────────────────────────────
  sec "1. Docker 가 도는가"
  local dv
  dv=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
  if [ -n "$dv" ]; then
    ok "Docker 엔진 $dv 가 돈다"
  else
    unk "Docker 엔진" "docker version 이 서버 판을 안 돌려줬다 — Docker Desktop 을 켜 주세요"
  fi

  # ── 2 ───────────────────────────────────────────────────────────────
  sec "2. 디스크 여유 — tar 아홉이 들어갈 자리"
  local dcheck free_kb
  dcheck=$OUT
  [ -d "$dcheck" ] || dcheck=$(dirname "$OUT")
  free_kb=$(df -Pk "$dcheck" 2>/dev/null | awk 'NR==2 {print $4}')
  if isnum "${free_kb:-}"; then
    say "여유 $((free_kb / 1024))MB · 필요 $((NEED_KB / 1024))MB 쯤"
    if [ "$free_kb" -ge "$NEED_KB" ]; then
      ok "작업 폴더 쪽 여유가 넉넉하다"
    else
      bad "작업 폴더 쪽 여유가 모자란다 ($((free_kb / 1024))MB)"
    fi
  else
    unk "디스크 여유" "df 가 숫자를 안 돌려줬다 ($dcheck)"
  fi
  note "🔵 이것은 tar 가 놓일 자리만 잰 것이다. docker build 가 쓰는 자리는 Docker"
  note "   Desktop 쪽(WSL 디스크)에 따로 있다 — 거기가 모자라면 build 가 멈춘다."

  # ── 3 ───────────────────────────────────────────────────────────────
  sec "3. 저장소 여덟 — 미커밋 · 미푸시 · 서브모듈 · dev 서버"
  local R P NAME DIR dirty ahead behind lr sub badsub uiline uisha gd fh age
  for RLINE in $REPOS; do
    IFS='|' read -r R P NAME <<< "$RLINE"
    DIR="$DEV/$R"
    printf '  ── %s (%s)\n' "$NAME" "$R"

    if [ ! -d "$DIR/.git" ] && [ ! -f "$DIR/.git" ]; then
      bad "$R — git 저장소가 아니다 ($DIR)"
      continue
    fi

    # 3-ㄱ 미커밋
    dirty=$(git -C "$DIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
    if isnum "${dirty:-}"; then
      if [ "$dirty" -eq 0 ]; then
        ok "$R 미커밋 0"
      else
        bad "$R 미커밋 $dirty 줄 — 구운 이미지를 나중에 재현 못 한다"
        git -C "$DIR" status --porcelain=v1 2>/dev/null | head -10 | sed 's/^/      /'
      fi
    else
      unk "$R 미커밋" "git status 가 안 된다"
    fi

    # 3-ㄴ 미푸시 · 🔴 안 받은 것도 센다
    if git -C "$DIR" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
      lr=$(git -C "$DIR" rev-list --left-right --count '@{u}'...HEAD 2>/dev/null)
      behind=$(printf '%s' "$lr" | awk '{print $1}')
      ahead=$(printf '%s' "$lr" | awk '{print $2}')
      if isnum "${ahead:-}" && isnum "${behind:-}"; then
        if [ "$ahead" -eq 0 ]; then
          ok "$R 미푸시 0"
        else
          bad "$R 미푸시 $ahead 개 — 올린 뒤에 구워야 재현된다"
          git -C "$DIR" log --oneline '@{u}'..HEAD 2>/dev/null | head -10 | sed 's/^/      /'
        fi
        if [ "$behind" -eq 0 ]; then
          ok "$R 안 받은 커밋 0"
        else
          bad "$R 안 받은 커밋 $behind 개 — 남이 올린 것을 빼고 굽게 된다"
          say "    git -C \"$DIR\" pull --ff-only"
        fi
      else
        unk "$R 미푸시" "rev-list 가 숫자를 안 돌려줬다"
      fi
      # 원격 쪽 눈이 얼마나 낡았는지 — 막지는 않고 알려만 준다
      gd=$(to_unix "$(git -C "$DIR" rev-parse --absolute-git-dir 2>/dev/null)")
      fh="$gd/FETCH_HEAD"
      if [ -f "$fh" ]; then
        age=$(( ( $(date +%s) - $(stat -c %Y "$fh" 2>/dev/null || echo 0) ) / 86400 ))
        if isnum "${age:-}" && [ "$age" -ge 2 ]; then
          note "$R 의 origin 눈이 ${age}일 낡았다 — 위 두 줄은 그 낡은 눈으로 센 것이다"
        fi
      fi
    else
      bad "$R 에 업스트림이 없다 — 미푸시를 잴 수가 없다"
    fi

    # 3-ㄷ 서브모듈 포인터
    sub=$(git -C "$DIR" submodule status --recursive 2>/dev/null)
    if [ -z "$sub" ]; then
      ok "$R 서브모듈 없음"
    else
      badsub=$(printf '%s\n' "$sub" | grep -c '^[-+U]')
      if isnum "${badsub:-}" && [ "$badsub" -eq 0 ]; then
        ok "$R 서브모듈 전부 제자리 (미초기화 · 어긋남 0)"
      else
        bad "$R 서브모듈 $badsub 개가 미초기화(-) 나 어긋남(+) 이다"
        printf '%s\n' "$sub" | grep '^[-+U]' | sed 's/^/      /'
        say "    git -C \"$DIR\" submodule update --init --recursive"
      fi
      uiline=$(printf '%s\n' "$sub" | grep 'vendor/dss-ui' | head -1)
      if [ -n "$uiline" ]; then
        uisha=$(printf '%s' "$uiline" | sed 's/^[-+U ]//' | awk '{print $1}')
        if [ "$uisha" = "$WANT_UI" ]; then
          ok "$R vendor/dss-ui = $(printf '%s' "$WANT_UI" | cut -c1-8) (운영과 같다)"
        else
          bad "$R vendor/dss-ui 가 $(printf '%s' "${uisha:-없음}" | cut -c1-8) 다 — $(printf '%s' "$WANT_UI" | cut -c1-8) 를 기대했다"
        fi
      fi
    fi

    # 3-ㄹ 🔴 dev 서버
    if have_netstat; then
      if [ -n "$(port_lines "$P")" ]; then
        bad "$R 의 dev 서버가 **$P 번에 떠 있다** — .next 를 두고 다퉈 빌드가 깨진다"
        port_lines "$P" | sed 's/^/      /'
        say "    맨 오른쪽 숫자가 PID 다. 바탕화면 「작업 종료」 메뉴로 내리세요."
      else
        ok "$R 포트 $P 비어 있다"
      fi
    else
      unk "$R 포트 $P" "이 셸에 netstat 이 없다"
    fi

    # 3-ㅁ 🔵 기준 SHA — 다음 배포가 범위를 셀 자리
    local sha cdate
    sha=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
    cdate=$(git -C "$DIR" log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M' 2>/dev/null)
    if [ -n "$sha" ]; then
      say "HEAD $sha ($cdate)"
      SHATAB="$SHATAB$R|$sha|$cdate
"
    else
      unk "$R HEAD" "rev-parse 가 안 된다"
    fi
  done

  # ── 4 ───────────────────────────────────────────────────────────────
  sec "4. 🔴 그 태그가 이미 있는가 — 있으면 되돌릴 판이 사라진다"
  local K RR TAG TGT
  for JLINE in $JOBS; do
    IFS='|' read -r K RR TAG TGT <<< "$JLINE"
    if [ -z "$dv" ]; then
      unk "$TAG" "Docker 가 안 돌아 못 봤다"
      continue
    fi
    if have_img "$TAG"; then
      bad "$TAG 가 **이미 있다** — 덮어쓰면 되돌릴 판이 사라진다"
      say "    정말 다시 구우려면 사람이 먼저: docker image rm $TAG"
    else
      ok "$TAG 없음 (새로 굽는다)"
    fi
  done

  # ── 5 ───────────────────────────────────────────────────────────────
  sec "5. Dockerfile 과 --target"
  for JLINE in $JOBS; do
    IFS='|' read -r K RR TAG TGT <<< "$JLINE"
    DIR="$DEV/$RR"
    if [ ! -f "$DIR/Dockerfile" ]; then
      bad "$RR 에 Dockerfile 이 없다"
      continue
    fi
    if [ -z "$TGT" ]; then
      if grep -qE '^FROM .* AS runner$' "$DIR/Dockerfile"; then
        ok "$TAG — 마지막 스테이지 runner 를 굽는다 (--target 없음)"
      else
        bad "$RR 의 Dockerfile 에 runner 스테이지가 없다 — 태그 규칙을 다시 보세요"
      fi
    else
      if grep -qE "^FROM .* AS $TGT\$" "$DIR/Dockerfile"; then
        ok "$TAG — --target $TGT 가 Dockerfile 에 있다"
      else
        bad "$RR 의 Dockerfile 에 $TGT 스테이지가 없다"
      fi
    fi
  done

  # ── 6 ───────────────────────────────────────────────────────────────
  sec "6. 🔵 기준 SHA — README 에 그대로 붙일 표"
  printf '%s\n' "🔴 이 표가 **다음 배포의 기준 SHA** 다. 계측기(njlee)는 이번 판의 SHA 가"
  printf '%s\n' "   README 에 없어 서른한째 범위를 못 쟀다 — 다시 그러지 않게 아홉을 다 찍는다."
  printf '\n'
  printf '%s\n' "| 시스템 | 저장소 | 이번 태그 | 기준 SHA | 커밋 시각 |"
  printf '%s\n' "|---|---|---|---|---|"
  for JLINE in $JOBS; do
    IFS='|' read -r K RR TAG TGT <<< "$JLINE"
    NAME=$(printf '%s' "$REPOS" | tr ' ' '\n' | grep "^$RR|" | head -1 | awk -F'|' '{print $3}')
    local row sha cdate
    row=$(printf '%s' "$SHATAB" | grep "^$RR|" | head -1)
    sha=$(printf '%s' "$row" | awk -F'|' '{print $2}')
    cdate=$(printf '%s' "$row" | awk -F'|' '{print $3}')
    printf '| %s | %s | %s | %s | %s |\n' \
      "${NAME:-?}" "$RR" "$TAG" "${sha:-?}" "${cdate:-?}"
  done
  printf '\n'
  printf '%s\n' "🔵 재고관리가 두 줄인 것은 한 저장소에서 이미지 둘이 나오기 때문이다 —"
  printf '%s\n' "   앱과 도구의 기준 SHA 는 같은 값이다."

  [ "$FAIL" -eq 0 ] && [ "$UNK" -eq 0 ]
}

# ══════════════════════════════════════════════════════════════════════
#  굽기 — 🔴 --go 일 때만 돈다
# ══════════════════════════════════════════════════════════════════════
build_all() {
  local K RR TAG TGT DIR FILE TARP LOG rc cfg iid sz md5 n total
  n=0; total=$(printf '%s' "$JOBS" | grep -c '|')
  RESULT=''
  # 🔵 재기의 ✓ 와 섞이지 않게 여기서 다시 센다 — 「굽기 요약」이 굽기만 말한다.
  PASS=0; FAIL=0; UNK=0

  mkdir -p "$OUT" || { printf '🔴 작업 폴더를 못 만들었다: %s\n' "$OUT"; exit 1; }

  for JLINE in $JOBS; do
    IFS='|' read -r K RR TAG TGT <<< "$JLINE"
    n=$((n+1))
    DIR="$DEV/$RR"
    FILE=$(tar_name "$TAG")
    TARP="$OUT/$FILE"
    LOG="$OUT/build-$(printf '%s' "$TAG" | tr ':' '-').log"

    line
    printf '[%s/%s] %s  ←  %s%s\n' "$n" "$total" "$TAG" "$RR" \
      "$([ -n "$TGT" ] && printf ' (--target %s)' "$TGT")"
    line

    # ── 굽는다. 🔴 작업 폴더로 들어가서 점(.) 을 쓴다 — 17~30번과 같은 꼴이고
    #    한글 경로가 docker 인자로 안 넘어간다.
    if [ -n "$TGT" ]; then
      ( cd "$DIR" && docker build --target "$TGT" -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG"
    else
      ( cd "$DIR" && docker build -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG"
    fi
    rc=$?
    if [ "$rc" -ne 0 ]; then
      bad "$TAG 굽기 실패 (종료 코드 $rc) — 로그: $LOG"
      say "    🔴 여기서 멈춘다. 앞의 것들은 이미 구워졌다 — 다시 돌리기 전에"
      say "       이미 생긴 태그를 docker image rm 으로 지워야 --check 가 통과한다."
      return 1
    fi
    ok "$TAG 구웠다"

    # ── tar 로 뽑는다. 🔴 작업 폴더로 들어가 **상대경로**로 쓴다
    #    (드라이브 문자를 어디에도 안 넘긴다)
    ( cd "$OUT" && docker save "$TAG" -o "$FILE" ) </dev/null
    rc=$?
    if [ "$rc" -ne 0 ] || [ ! -s "$TARP" ]; then
      bad "$TAG 를 tar 로 못 뽑았다 ($TARP)"
      return 1
    fi

    # ── 🔴 지문 셋 ──────────────────────────────────────────────────
    sz=$(size_of "$TARP")
    md5=$(md5_of "$TARP")
    cfg=$(tar_config_id "$TARP" 2>/dev/null) || cfg=''
    iid=$(img_id "$TAG")

    if isnum "${sz:-}" && [ "$sz" -gt 0 ]; then
      ok "$FILE  크기 $sz 바이트 ($((sz / 1048576))MB)"
    else
      unk "$FILE 크기" "stat 도 wc 도 숫자를 안 돌려줬다"
    fi
    if [ -n "$md5" ]; then ok "md5 $md5"; else unk "$FILE md5" "md5sum 이 안 된다"; fi
    if [ -n "$cfg" ]; then
      ok "Config $cfg"
      # 🔴 2026-10-22 고침 — 전에는 여기서 tar 의 Config 와 그 값
      #    (docker image inspect 의 .Id) 를 맞대어 보고 다르면 ✗ 를 냈다.
      #    그런데 **구운 아홉이 전부 ✗ 였다.**
      #    요즘 Docker(containerd 저장소)는 그 둘이 애초에 다른 값이다 — 하나는
      #    config 블롭의 지문이고 하나는 매니페스트의 지문이다. 같을 수가 없다.
      #    지난 배포본(30-deploy.sh:127)이 맞대는 상대는 image ID 가 아니라
      #    **빌드 로그의 「exporting config sha256:」** 이다. 그쪽으로 바꾼다.
      #    🔵 실측으로 확인했다: dss-auth-1.8 · dss-board-0.3 둘 다 빌드 로그와
      #       tar 의 Config 가 글자까지 같았다.
      lg="build-$(printf '%s' "$TAG" | tr ':/' '--').log"
      if [ -f "$lg" ]; then
        exp=$(grep -oE "exporting config sha256:[0-9a-f]+" "$lg" | tail -1 | grep -oE "sha256:[0-9a-f]+")
        if [ -n "$exp" ] && [ "$exp" != "$cfg" ]; then
          bad "$TAG — tar 의 Config 가 빌드 로그의 exporting config 와 다르다 ($exp)"
        elif [ -n "$exp" ]; then
          ok "$TAG — tar 의 Config 가 빌드 로그와 같다"
        else
          note "$TAG — 빌드 로그에 exporting config 가 없다 (buildx 판에 따라 안 찍힌다)"
        fi
      else
        note "$TAG — 빌드 로그가 없어 교차 확인을 건너뛴다"
      fi
      if [ -n "$iid" ]; then
        note "$TAG — 이 PC 의 image ID 는 $iid (tar 의 Config 와 다른 것이 정상이다)"
      fi
    else
      unk "$FILE 의 Config" "manifest.json 을 못 읽었다 — tar 가 드라이브 문자를 원격으로 읽었을 수 있다"
    fi

    RESULT="$RESULT$TAG|$FILE|${sz:-?}|${md5:-?}|${cfg:-?}
"
  done
  return 0
}

print_result_table() {
  sec "🔴 배포본(31-deploy.sh)에 그대로 붙일 표"
  printf '\n'
  printf '%s\n' "| 태그 | tar 파일 | 크기(바이트) | md5 | Config |"
  printf '%s\n' "|---|---|---|---|---|"
  printf '%s' "$RESULT" | while IFS='|' read -r T F S M C; do
    [ -n "$T" ] || continue
    printf '| %s | %s | %s | %s | %s |\n' "$T" "$F" "$S" "$M" "$C"
  done
  printf '\n'
  printf '%s\n' "🔵 30-deploy.sh 는 이 값들을 변수 셋으로 들고 있었다(SZ_* · MD5_* · WANT_CFG_*)."
  printf '%s\n' "   31-deploy.sh 가 바로 쓰게 그 꼴로도 찍는다:"
  printf '\n'
  printf '%s' "$RESULT" | while IFS='|' read -r T F S M C; do
    [ -n "$T" ] || continue
    KEY=$(printf '%s' "$T" | sed 's/^dss-//; s/:.*$//' | tr 'a-z-' 'A-Z_')
    printf 'TAG_%s="%s"\n'      "$KEY" "$T"
    printf 'TAR_%s="$IMAGES/%s"\n' "$KEY" "$F"
    printf 'SZ_%s="%s"\n'       "$KEY" "$S"
    printf 'MD5_%s="%s"\n'      "$KEY" "$M"
    printf 'WANT_CFG_%s="%s"\n' "$KEY" "$C"
  done
  printf '\n'
  printf '%s\n' "🔴 tar 가 이미지의 1/4 쯤인 것은 **정상**이다 — 지난 판 tar 와 견주세요"
  printf '%s\n' "   (dss-as-2.8.tar 132020224 · dss-po-0.6.tar 95434240 · dss-auth-1.7.tar 113596928)."
}

usage() {
  printf '%s\n' "쓰는 법:"
  printf '%s\n' "  bash $0 --check [작업폴더]   재기만 한다 (아무것도 안 굽는다)"
  printf '%s\n' "  bash $0 --go    [작업폴더]   재고 전부 ✓ 면 아홉을 굽고 tar 로 뽑는다"
  printf '\n'
  printf '%s\n' "  작업폴더 기본값: $DEV/_images-31"
}

# ══════════════════════════════════════════════════════════════════════
#  인자
# ══════════════════════════════════════════════════════════════════════
MODE=''
OUTARG=''
for A in "$@"; do
  case "$A" in
    --check) MODE=check ;;
    --go)    MODE=go ;;
    -h|--help) usage; exit 0 ;;
    -*) printf '🔴 모르는 옵션이다: %s\n\n' "$A"; usage; exit 2 ;;
    *)
      if [ -z "$OUTARG" ]; then
        OUTARG=$A
      else
        printf '🔴 작업 폴더는 하나만 받는다 (%s 가 둘째다)\n' "$A"; exit 2
      fi
      ;;
  esac
done

if [ -z "$MODE" ]; then
  printf '🔴 --check 인지 --go 인지 적어 주세요.\n\n'
  usage
  exit 2
fi

if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-31"; fi

printf '31-build — 서른한째 배포 · 3단계 이미지 굽기   %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
printf '모드: %s\n' "$MODE"
printf '🔵 이 스크립트는 NAS 에 접속하지 않는다. 개발 PC 에서만 돈다.\n'
line

check_all
CHECK_OK=$?

line
printf '재기 요약 — ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
if [ "$UNK" -gt 0 ]; then
  printf '%s\n' "🔴 **못 잰 것이 $UNK 개 있다.** 통과로 세지 않는다."
fi
if [ "$FAIL" -gt 0 ]; then
  printf '%s\n' "🔴 **어긋난 것이 $FAIL 개 있다.**"
fi

if [ "$MODE" = check ]; then
  line
  if [ "$CHECK_OK" -eq 0 ]; then
    printf '%s\n' "✅ 전부 ✓ 다 — 이제 구워도 된다:"
    printf '%s\n' "    bash $0 --go"
  else
    printf '%s\n' "🔴 위의 ✗ 와 ? 가 **사람이 먼저 해결할 일**이다. 그 전에는 --go 가 안 돈다."
  fi
  printf '%s\n' "끝 — 이 출력을 그대로 복사해 주세요."
  [ "$CHECK_OK" -eq 0 ] || exit 1
  exit 0
fi

# ── --go ──────────────────────────────────────────────────────────────
if [ "$CHECK_OK" -ne 0 ]; then
  line
  printf '%s\n' "🔴 재기에서 ✗ 나 ? 가 나왔다 — **굽지 않고 멈춘다.**"
  printf '%s\n' "   위의 것을 먼저 해결하고 다시 돌려 주세요."
  exit 1
fi

line
printf '%s\n' "✅ 재기 전부 ✓ — 아홉을 굽는다. 30분쯤 걸린다."
printf '%s\n' "   tar 와 빌드 로그는 여기 쌓인다: $OUT"
line

GO_FAIL=0
build_all || GO_FAIL=1

line
printf '굽기 요약 — ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
if [ -n "$RESULT" ]; then print_result_table; fi

line
if [ "$GO_FAIL" -ne 0 ] || [ "$FAIL" -gt 0 ] || [ "$UNK" -gt 0 ]; then
  printf '%s\n' "🔴 끝까지 못 갔다. 위의 ✗ 와 ? 를 보세요."
  printf '%s\n' "끝 — 이 출력을 그대로 복사해 주세요."
  exit 1
fi
printf '%s\n' "✅ 아홉을 다 구웠다. 다음은 4단계 — tar 를 NAS 로 올리는 일이다."
printf '%s\n' "   🔴 올리는 것도, 31-deploy.sh 를 돌리는 것도 **사람이 한다.**"
printf '%s\n' "끝 — 이 출력을 그대로 복사해 주세요."
exit 0
