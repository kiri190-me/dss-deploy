#!/bin/bash
# dss-deploy/nas/setup/56-stage.sh — 양식 **두 장**만 올리기 · 개발 PC 쪽 (2026-11-11)
#
# 🔵 **배포 번호가 아니다.** 56 은 setup/ 폴더의 파일 번호일 뿐이고, 이 일은
#    배포가 아니라 **양식 파일만** 갈아 끼우는 일이다. 이미지도 마이그레이션도
#    compose 도 없다. 그래서 보낼 자리도 배포본 폴더(_images-NN)가 **아니다** —
#    **_templates-56** 이다(아래 「보낼 자리」 절).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **만들어는 두었지만 2026-11-11 에 돌리지 않았다** — 그것이 결정이다
# ══════════════════════════════════════════════════════════════════════
#   이 스크립트는 2026-11-11 에 만들었고 **그날 돌리지 않았다**(사용자 결정).
#   짜임이 틀려서가 아니라 **올릴 까닭이 없어서**다. 까닭을 실측으로 확인했다:
#
#   · 올리려던 둘(수리보고서.xlsx · 검사보고서.xlsx — 매쳐·제너레이터가 **안 붙은**
#     기본 둘)은 src/lib/storage/service-report-template.ts 의 **LEGACY_TEMPLATE_ENV**,
#     곧 **물러설 자리(fallback)** 다.
#   · 보고서 양식은 문서 종류(검사·수리) × 제품 종류(매쳐·제너레이터) **넷** 중에서
#     고른다(T/C 는 제너레이터 양식을 쓴다). 그 파일 100~107줄에 「새 설정이 비어
#     있으면 옛 설정을 쓴다」고 적혀 있고, **기본 둘은 그때만** 읽힌다.
#   · 🔵 **운영 실측** — 쉰두째 배포 기록(dss-deploy/README.md 444줄)이
#     **OK 11 / MISS 0 / UNSET 0** 이다. 설정 열한 개가 **전부 채워져 있고 전부
#     읽힌다** → 운영에서 기본 둘은 **한 번도 안 읽힌다.**
#   · 그래서 운영이 9월 판이어도 **지금 나가는 보고서에는 아무 영향이 없다.**
#
#   🔴 **양식이 또 바뀌는 날 쓰려고 남긴다.**
#   🔴 **돌리기 전에 반드시 다시 재라.** 아래 TPL_UP 표의 바이트·md5 는
#      **2026-11-11 실측**이다. 그 사이 양식이 또 바뀌었으면 **그 값부터 고쳐야**
#      한다 — 이 스크립트를 인자 없이 한 번 돌리면 **✗ 로 알려 준다**(2절).
#      안 고치고 보내면 NAS 쪽 --apply 가 md5 가 다르다며 **한 장도 안 옮긴다.**
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    이 파일에는 ssh 도 scp 도 docker 도 **한 줄도 없다.** scp 명령은 **찍어 주기만**
#    하고, 치는 것은 사람이다(PowerShell).
#
# ── 돌리는 법 (개발 PC · Git Bash) ────────────────────────────────────
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/56-stage.sh"
#     bash "/c/Users/희만/Desktop/Development/dss-deploy/nas/setup/56-stage.sh" --go
#
#   🔴 PowerShell 에서 부를 때는 **경로를 빗금으로** 적는다:
#     & bash.exe "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup/56-stage.sh"
#     역슬래시로 적으면 bash 가 그 역슬래시를 먹어 경로가 통째로 붙는다 —
#     "C:Users희만Desktop…" 가 되어 No such file or directory 가 난다.
#
#   둘째 인자로 보낼 자리를 바꿀 수 있다(기본값은 Development/_templates-56):
#     bash .../56-stage.sh --go "/d/배포본/_templates-56"
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이 파일이 하는 일 — **양식 두 장을 보낼 채비**. 그것뿐이다
# ══════════════════════════════════════════════════════════════════════
#   운영(NAS)에 놓인 엑셀 양식 둘이 개발 PC 것보다 **두 달 뒤처져 있다**:
#       수리보고서.xlsx   운영 182,773바이트 (2026-09-01)  ← 개발 PC 190,710 (10-19)
#       검사보고서.xlsx   운영 182,626바이트 (9월 판)       ← 개발 PC 190,589 (10-19)
#
#   2026-10-19 커밋 셋이 **칸 폭과 치수를 양식 파일에서 읽도록** 바꿨다
#   (2026-11-11 git show 로 셋 다 확인했다):
#       6ec58d12 칸 폭을 화면이 굳혀 들지 말고 서버가 양식에서 읽어 넘긴다
#       2812d40a 양식이 바뀌어도 안 깨지게 — 시험이 굳혀 들던 치수를 양식에서 읽는다
#       322fe553 PDF 를 한 장에 맞춰 내보낸다 — 보고서가 두 장으로 갈라지고 있었다
#   운영 코드는 **이미 그 최신**(dss-as:4.8)인데 **읽히는 양식만 9월 판**이다.
#   그래서 이번 일은 코드를 한 줄도 안 건드리고 **양식만** 갈아 끼운다.
#
#   🔴 **이미지를 굽지 않는다. 컨테이너를 다시 띄우지 않는다. 마이그레이션도 없다.**
#      양식은 /volume1/dss/as-templates 볼륨에 놓인 **파일**이고, 앱은 쓸 때마다
#      readFile 로 **다시 읽는다** — 캐시가 한 줄도 없다(2026-11-11 재확인:
#      src/lib/storage/quote-template.ts 84줄 · service-report-template.ts 213줄,
#      두 파일에 cache 라는 낱말이 0건). **앱을 안 내려도 바뀐다.**
#
#   🔵 양식 열한 장 중 매쳐·제너레이터용 넷은 2026-11-01 에 이미 올라갔다.
#      **기본 둘만 남았고, 이 파일은 그 둘만 다룬다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 51번에서 베끼면 틀리는 것 다섯 — **전부 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   「배포본은 지난 판의 전제를 업고 온다」가 이 저장소에 적힌 사고다. 51번
#   (마흔여덟째)의 양식 절을 틀로 썼지만 **아래 다섯은 값이 다르다.**
#     ① 올리는 장수   51번 다섯(TPL_UP_WANT=5) → **이번 둘(=2)**
#     ② 안 올리는 장수 51번 여섯              → **이번 아홉**
#     ③ 보내는 폴더   51번 _images-47/templates → **이번 _templates-56**
#        🔴 **_images-NN 을 쓰지 않는다.** 그 번호는 **배포본**이 쓰는 이름이고,
#           이 일은 배포가 아니다. 그 이름을 빌려 쓰면 나중에 이 파일을 돌리는
#           날 **그 폴더에 남의 배포 tar 가 이미 들어 있을 수 있다.**
#     ④ 함께 하는 일  51번 이미지 교체·마이그레이션·compose → **이번엔 없다. 양식만.**
#     ⑤ --check 가 재는 것 51번은 이미지·DB·볼륨·설정·연락서까지 전부
#                        → **이번엔 양식 관련만.** 51-deploy.sh 의 --check 에는
#                          이 일과 무관한 검사가 잔뜩 있고(이미지 태그 · DB
#                          마이그레이션 수 · compose 사본 · 연락서 폴더),
#                          **통째로 가져오면 기대값이 전부 낡아 가짜 ✗ 가 쏟아진다.**
#
# ── 모드 둘 ───────────────────────────────────────────────────────────
#   (기본) --check   🔵 **아무것도 안 바꾼다.** 두 장을 재서 표와 맞댄다
#   --go             ✍ 두 장을 _templates-56 으로 **복사**하고, 복사본의
#                       md5 를 **다시 재서** 원본과 같은지 보고, scp 명령을 찍는다
#
#   🔴 --go 도 **운영을 안 건드린다.** 이 파일은 NAS 에 접속하지 않는다.
#      운영이 바뀌는 자리는 NAS 쪽 56-templates.sh --apply **하나뿐**이다.
#
# ── 🔴 경로를 화면에 찍지 않는다 ──────────────────────────────────────
#   양식의 자리는 .env.local 에 적힌 **공유폴더 주소**라 비밀 취급이다
#   (51-build.sh 425~427줄에 같은 방침이 적혀 있다). 그래서 이 파일은
#   **이름 · 바이트 · md5 · 수정 시각**만 찍는다. 설정 **값**은 한 글자도 안 찍는다.
#   🔵 _templates-56 은 찍어도 된다 — 거기 보내라고 사람에게 알려 줘야 한다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안의 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 쓴 뒤 grep 으로 세었다.
#   ② 읽기 전용 자리에서 콜론 하나와 꺾쇠로 빈 파일을 만들면 ash 가 셸을 그
#      자리에서 끝낸다(2026-10-12 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 폴더는 mkdir 로만 만든다.
#   ③ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** set -uo pipefail
#      아래에서 스크립트를 쏜다 — 셈은 전부 「$( … || true )」 로 받는다.
#   ④ 🔴 **빈 결과를 ✓ 로 읽지 않는다.** 「폴더를 못 읽었다」와 「비어 있다」를
#      갈라서 적는다.
#
# ── 🔴 scp 에 대해 이 파일이 찍어 주는 것 ────────────────────────────
#   · **-O 를 붙인다** — DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#   · **보내는 쪽에 드라이브 문자(C:)를 주지 않는다** — 원격 호스트로 읽힌다.
#     그래서 폴더로 **cd 한 뒤 상대경로**로 보낸다.
#   · **한 줄에 하나씩** 찍는다 — 이름에 공백과 한글이 둘 다 있어 별표(*)로
#     묶으면 PowerShell 이 어떻게 쪼갤지 장담할 수 없다.
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEV=${DSS_DEV:-$(cd "$SCRIPT_DIR/../../.." && pwd)}
ASDIR="$DEV/RF_Service_System"

PASS=0; FAIL=0; UNK=0
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
unk()  { UNK=$((UNK+1));   printf '  ? %s — 못 쟀다 (%s)\n' "$1" "$2"; }
note() { printf '  ⚠️ %s\n' "$1"; }
say()  { printf '    %s\n' "$1"; }
# 🔴 ✗ 가 났을 때 그 자리에서 찍는다 — 처음 도는 코드라 기대값이 틀릴 확률이
#    일 자체만큼 높다. ✓ 쪽 오판은 영영 안 드러나므로 ✗ 쪽을 크게 적는다.
doubt() { say "🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 이 줄의 기대값이"
          say "   어디서 왔는지는 이 파일 머리말의 표에 적혀 있습니다."; }

isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }

# 🔴 C:\… 또는 C:/… 를 /c/… 로. 역슬래시를 먼저 빗금으로 바꾼다.
#    🔵 공유폴더(\\서버\…)는 //서버/… 가 되고 Git Bash 가 그대로 연다.
to_unix() { # 1 경로
  local p=${1//\\//}
  case "$p" in
    [A-Za-z]:/*) p=/$(printf '%s' "${p%%:*}" | tr 'A-Z' 'a-z')${p#?:} ;;
  esac
  printf '%s' "$p"
}
# 🔵 /c/… 를 C:/… 로 — **사람이 PowerShell 에 칠 줄**에만 쓴다.
to_win() { # 1 유닉스 경로
  local p d r
  p=$1
  case "$p" in
    /?/*) d=$(printf '%s' "$p" | cut -c2 | tr 'a-z' 'A-Z')
          r=$(printf '%s' "$p" | cut -c3-)
          printf '%s:%s' "$d" "$r" ;;
    *)    printf '%s' "$p" ;;
  esac
}

# ══ 🔴 이번에 올리는 **둘** — 설정이름|파일이름|바이트|md5 ════════════
#   🔴 **경로는 여기 없다.** 이름과 바이트와 md5 뿐이다. 경로는 .env.local 의
#      같은 이름 줄에서 돌 때 읽고, **찍지 않는다.**
#   🔵 아래 값은 2026-11-11 개발 PC 실측이다. 56-templates.sh 의 TPL_UP 표와
#      **글자 그대로 같아야 한다** — 다르면 NAS 쪽이 md5 가 다르다며 안 옮긴다.
TPL_UP='
REPAIR_REPORT_TEMPLATE_PATH|수리보고서.xlsx|190710|403b642d7c700a118ee515e20e4d659e
INSPECTION_REPORT_TEMPLATE_PATH|검사보고서.xlsx|190589|f7dd2fe0dbf03e6a44fa48a00ee4413e
'
TPL_UP_WANT=2

# 🔵 NAS 쪽 받을 자리. **56-templates.sh --prep 가 만들고 777 로 연다.**
#    여기서는 scp 명령을 찍는 데에만 쓴다 — 이 파일은 NAS 에 붙지 않는다.
TPLIN=/volume1/dss/as-templates-incoming

MODE=${1:---check}
OUTARG=${2:-}
case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --go\n' "$MODE"; exit 2 ;;
esac
# 🔴 **보낼 자리는 _templates-56 이다 — _images-NN 이 아니다.**
#    _images-NN 은 **배포본**(이미지 tar · 마이그레이션 묶음)이 쓰는 이름이다.
#    이 일은 배포가 아니라 양식만 올리는 일이고, 게다가 2026-11-11 에는 안 돌렸다.
#    그 이름을 빌려 쓰면 나중에 이 파일을 돌리는 날 **그 폴더에 남의 배포 tar 가
#    들어 있다.** 🔵 56-templates.sh 의 DEVPC_TPLDIR 과 **같은 자리**여야 한다.
if [ -n "$OUTARG" ]; then TPLOUT=$(to_unix "$OUTARG"); else TPLOUT="$DEV/_templates-56"; fi

printf '%s\n' "양식 **두 장**만 올리기 · 개발 PC 쪽 (배포 번호와 무관하다)   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  저장소 뿌리: $DEV"
printf '%s\n' "  보낼 자리: $TPLOUT"
printf '%s\n' "  🔴 **이미지도 마이그레이션도 compose 도 이번엔 없다 — 양식만입니다.**"
printf '%s\n' "  🔴 **경로(공유폴더 주소)는 안 찍습니다.** 이름·바이트·md5·시각만 찍습니다."
printf '%s\n' "────────────────────────────────────────────────────────────"

# ══════════════════════════════════════════════════════════════════════
# ── 1. 설정 파일 — .env.local 이 먼저, 없으면 .env ────────────────────
# ══════════════════════════════════════════════════════════════════════
printf '\n== 1. 설정 파일 (이름만 본다 · 값은 한 글자도 안 찍는다)\n'
ENVF=""; ENVNAME=""
if [ -f "$ASDIR/.env.local" ]; then
  ENVF="$ASDIR/.env.local"; ENVNAME=".env.local"
elif [ -f "$ASDIR/.env" ]; then
  ENVF="$ASDIR/.env"; ENVNAME=".env"
fi
if [ -z "$ENVF" ]; then
  bad "RF_Service_System 에 .env.local 도 .env 도 없다 — 양식 경로를 읽을 데가 없다"
  say "🔵 이 스크립트는 RF_Service_System 을 **읽기만** 한다. 한 글자도 안 고친다."
  printf '\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
  exit 1
fi
ok "설정 파일을 찾았다: RF_Service_System/$ENVNAME  (값은 안 찍는다)"
if [ "$ENVNAME" = ".env" ]; then
  note ".env.local 이 없어 .env 를 읽는다 — 평소와 다른 자리다. 사람이 보세요"
fi

# 🔴 **같은 이름이 두 줄이면 아래가 이긴다**(이 PC 에서 하루에 네 번 난 사고).
#    그래서 값은 tail -1 로 뽑고, 두 줄 이상이면 ⚠️ 로 알린다.
#    🔴 grep -c 는 0 일 때 종료 코드 1 이다 — || true 로 받는다.
envcount() { # 1 이름 → 그 이름으로 시작하는 줄 수
  local n
  n=$(grep -c "^$1=" "$ENVF" 2>/dev/null || true)
  printf '%s' "${n:-0}"
}
# 🔵 값 읽기. 🔴 **돌려받은 것을 찍지 말 것.** 따옴표와 \r 을 걷어낸다.
tpl_path() { # 1 이름 → 경로(없으면 빈 줄)
  local v q
  v=$(grep -E "^$1=" "$ENVF" 2>/dev/null | tail -1 | cut -d= -f2-)
  v=$(printf '%s' "$v" | tr -d '\r')
  q=$(printf '%s' "'")
  v=${v#\"}; v=${v%\"}
  v=${v#"$q"}; v=${v%"$q"}
  v=${v# }; v=${v% }
  [ -n "$v" ] || return 0
  to_unix "$v"
}

# ══════════════════════════════════════════════════════════════════════
# ── 2. 올릴 두 장을 **값으로** 잰다 ───────────────────────────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 표와 맞대어 ✓/✗ 를 낸다. 여기서는 **다르면 ✗ 다** — 이 둘은 개발 PC 가
#      원본이고 표는 2026-11-11 에 그 원본에서 뜬 값이다. 어긋났다는 것은
#      ㄱ) 그 뒤에 양식을 또 고쳤거나  ㄴ) 표가 낡았다는 뜻이고,
#      그대로 보내면 **NAS 쪽 --apply 가 md5 가 다르다며 한 장도 안 옮긴다.**
#   🔵 NAS 쪽 「안 올리는 아홉」과는 잣대가 다르다 — 그쪽은 다르다고 ✗ 를
#      내지 않는다(운영 양식이 개발 PC 것과 꼭 같아야 한다는 보증이 없다).
printf '\n== 2. 올릴 양식 두 장 (이름·바이트·md5·수정 시각만 찍는다)\n'
TPL_SEEN=0; TPL_SAME=0; TPL_DIFF=0; TPL_MISS=0
TPL_SRC_LIST=""
while IFS='|' read -r VAR NAME WSZ WM5; do
  [ -n "${VAR:-}" ] || continue
  TPL_SEEN=$((TPL_SEEN+1))
  NDUP=$(envcount "$VAR")
  if [ "${NDUP:-0}" = "0" ]; then
    bad "$VAR — $ENVNAME 에 그 이름이 없다 ($NAME 을 못 찾는다)"
    TPL_MISS=$((TPL_MISS+1)); continue
  fi
  if [ "${NDUP:-0}" != "1" ]; then
    note "$VAR 이 $ENVNAME 에 ${NDUP}줄 있다 — **아래 줄이 이긴다.** 아래 것으로 쟀다"
  fi
  P=$(tpl_path "$VAR")
  if [ -z "${P:-}" ]; then
    bad "$VAR — 이름은 있는데 값이 비어 있다 ($NAME)"
    TPL_MISS=$((TPL_MISS+1)); continue
  fi
  if [ ! -s "$P" ]; then
    bad "$VAR — 그 자리에 파일이 없거나 0바이트다 ($NAME · 경로는 안 찍는다)"
    say "🔵 공유폴더가 안 붙어 있을 수도 있습니다. 탐색기에서 그 폴더를 먼저 열어 보세요."
    TPL_MISS=$((TPL_MISS+1)); continue
  fi
  GOTNAME=${P##*/}
  SZ=$(stat -c %s "$P" 2>/dev/null)
  M5=$(md5sum "$P" 2>/dev/null | awk '{print $1}')
  MT=$(date -r "$P" '+%Y-%m-%d %H:%M' 2>/dev/null)
  printf '      %-34s %-20s %9s바이트  %s  %s\n' "$VAR" "$GOTNAME" "${SZ:-?}" "${MT:-?}" "${M5:-?}"
  # 🔴 경로는 안 찍어도 **끝 조각(파일 이름)** 은 찍는다 — 이름이 바뀌었으면
  #    운영 쪽 이름과 어긋나 --apply 가 영영 못 찾는다.
  if [ "$GOTNAME" != "$NAME" ]; then
    note "$VAR 이 가리키는 파일 이름이 $GOTNAME 다 — **$NAME 을 적어 두었다.**"
    say "🔴 이름이 바뀌었으면 56-templates.sh 의 TPL_UP 표도 함께 고쳐야 합니다."
  fi
  if [ "${M5:-x}" = "$WM5" ] && [ "${SZ:-x}" = "$WSZ" ]; then
    TPL_SAME=$((TPL_SAME+1))
    ok "$NAME — 적어 둔 그대로다 ($WSZ바이트 · $WM5)"
    TPL_SRC_LIST="$TPL_SRC_LIST$P
"
  else
    TPL_DIFF=$((TPL_DIFF+1))
    bad "$NAME 이 적어 둔 것과 **다르다** (적어 둔 $WSZ바이트 $WM5)"
    say "🔴 양식을 또 고치셨다는 뜻이거나 표가 낡았다는 뜻입니다."
    say "🔴 이 파일의 TPL_UP 표와 **56-templates.sh 의 TPL_UP 표를 둘 다** 위 값으로"
    say "   고치세요 — 안 고치면 NAS 쪽 --apply 가 md5 가 다르다며 **한 장도 안 옮깁니다.**"
    doubt
  fi
done <<TPLEOF
$(printf '%s\n' "$TPL_UP" | grep -v '^[[:space:]]*$')
TPLEOF
say "본 것 ${TPL_SEEN}장 (적어 둔 수 $TPL_UP_WANT) · 같다 ${TPL_SAME} · 다르다 ${TPL_DIFF} · 못 찾음 ${TPL_MISS}"
# 🔴 **표본이 비어서 공짜로 통과하지 않게** — 몇 장을 봤는지를 먼저 단언한다.
if [ "$TPL_SEEN" = "$TPL_UP_WANT" ]; then
  ok "두 장을 다 봤다 (표본이 비지 않았다)"
else
  bad "${TPL_SEEN}장만 봤다 — $TPL_UP_WANT 장을 기대했다. TPL_UP 표가 깨졌다"
  doubt
fi

# ══════════════════════════════════════════════════════════════════════
# ── 3. 보낼 자리 — **이미 있으면 덮어쓰기 전에 알린다** ───────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 「0개」를 그냥 ✓ 로 읽지 않는다. 폴더가 없는 것과 비어 있는 것을 가른다.
printf '\n== 3. 보낼 자리: %s\n' "$TPLOUT"
OLDN=0
if [ ! -d "$TPLOUT" ]; then
  say "아직 없다 — --go 가 만든다"
else
  OLDN=$(find "$TPLOUT" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
  OLDN=${OLDN:-0}
  say "지금 그 폴더 안 파일 ${OLDN}개"
  if [ "$OLDN" != "0" ]; then
    note "🔴 **이미 파일이 있습니다.** --go 는 같은 이름을 **덮어씁니다.** 지금 것은 이렇습니다:"
    ( cd "$TPLOUT" 2>/dev/null || exit 0
      find . -maxdepth 1 -type f -print 2>/dev/null | sed 's|^\./||' | sort | while IFS= read -r f; do
        printf '      %-24s %9s바이트  %s  %s\n' \
          "$f" \
          "$(stat -c %s "$f" 2>/dev/null)" \
          "$(date -r "$f" '+%Y-%m-%d %H:%M' 2>/dev/null)" \
          "$(md5sum "$f" 2>/dev/null | awk '{print $1}')"
      done )
    say "🔵 우리 둘이 아닌 파일이 섞여 있으면 **scp 로 안 보냅니다** — 아래 명령은"
    say "   이름을 하나씩 적어 줍니다. 그래도 남아 있으면 사람이 치우세요."
  fi
fi

if [ "$MODE" = "--check" ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '%s\n' "🔵 **아무것도 안 바꿨습니다.** 복사도 안 했고 NAS 에 붙지도 않았습니다."
  if [ "$FAIL" != "0" ]; then
    printf '%s\n' "🔴 위 ✗ 를 먼저 보세요. 그대로 보내면 NAS 쪽 --apply 가 **한 장도 안 옮깁니다.**"
    exit 1
  fi
  printf '%s\n' "🔴 다음: bash $0 --go   ← 두 장을 복사하고 scp 명령을 찍어 줍니다"
  printf '%s\n' "────────────────────────────────────────────────────────────"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════
# ── 4. --go : ✍ 두 장을 복사한다 (쓰는 단계 · 그래도 운영은 안 건드린다)
# ══════════════════════════════════════════════════════════════════════
#   🔴 **이 모드가 쓰는 것은 _templates-56 하나뿐이다.**
#      · RF_Service_System 은 **읽기만** 한다
#      · NAS 에는 **붙지 않는다** (ssh·scp 가 이 파일에 한 줄도 없다)
#      · 운영 양식은 **한 글자도 안 바뀐다**
#   🔴 2절에서 ✗ 가 하나라도 났으면 **복사하지 않는다.** 틀린 것을 보내면
#      NAS 쪽이 md5 가 다르다며 안 옮기고, 그 ✗ 가 진짜 결함처럼 보인다.
if [ "$FAIL" != "0" ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '%s\n' "🔴 2절에서 ✗ 가 났습니다 — **아무것도 복사하지 않습니다.**"
  printf '%s\n' "────────────────────────────────────────────────────────────"
  exit 1
fi

printf '\n== 4. 두 장을 복사한다 (✍ 쓰는 단계 — 바뀌는 곳은 %s 뿐)\n' "$TPLOUT"
mkdir -p "$TPLOUT" 2>/dev/null
if [ ! -d "$TPLOUT" ]; then
  bad "보낼 자리를 못 만들었다: $TPLOUT"
  printf '\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
  exit 1
fi

# 🔴 복사한 뒤 **복사본을 다시 재서** 원본과 맞댄다 — 「cp 가 돌았다」와
#    「같은 것이 들어갔다」는 다른 말이다(「겉이 아니라 결과를 봐라」).
#    🔵 while 이 파이프라인 안이면 셈이 안 넘어온다 — **여기 문자열**로 먹인다.
CP_OK=0; CP_BAD=0
while IFS= read -r p; do
  [ -n "${p:-}" ] || continue
  n=${p##*/}
  if [ -s "$TPLOUT/$n" ]; then
    b0=$(md5sum "$TPLOUT/$n" 2>/dev/null | awk '{print $1}')
    say "덮어쓴다 $n — 지금 거기 있는 것 ${b0:-못 읽음}"
  fi
  if cp "$p" "$TPLOUT/$n" 2>/dev/null; then
    a=$(md5sum "$p" 2>/dev/null | awk '{print $1}')
    b=$(md5sum "$TPLOUT/$n" 2>/dev/null | awk '{print $1}')
    sb=$(stat -c %s "$TPLOUT/$n" 2>/dev/null)
    if [ -n "${a:-}" ] && [ "${a:-x}" = "${b:-y}" ]; then
      CP_OK=$((CP_OK+1))
      printf '  ✓ %s  (%s바이트 · md5 %s — 복사본을 다시 재서 맞췄다)\n' "$n" "${sb:-?}" "$b"
    else
      CP_BAD=$((CP_BAD+1))
      printf '  ✗ %s — 복사본의 md5 가 원본과 다르다 (원본 %s / 복사본 %s)\n' "$n" "${a:-못 읽음}" "${b:-못 읽음}"
    fi
  else
    CP_BAD=$((CP_BAD+1))
    printf '  ✗ %s — 복사 실패\n' "$n"
  fi
done <<CPEOF
$(printf '%s\n' "$TPL_SRC_LIST" | grep -v '^[[:space:]]*$')
CPEOF
# 🔴 위 셈과 따로 **결과 폴더를 다시 센다** — 셈 변수만 믿지 않는다.
CPN=$(find "$TPLOUT" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
say "복사 성공 ${CP_OK} · 실패 ${CP_BAD} · 그 폴더 안 파일 ${CPN:-못 쟀다}개"
if [ "$CP_OK" = "$TPL_UP_WANT" ] && [ "$CP_BAD" = "0" ]; then
  PASS=$((PASS+1)); printf '  ✓ 두 장을 다 복사했고 **복사본의 md5 가 원본과 같다**\n'
else
  FAIL=$((FAIL+1)); printf '  ✗ %s/%s 장만 됐다 — 위를 보세요\n' "$CP_OK" "$TPL_UP_WANT"
  doubt
fi
if [ "${CPN:-0}" != "$TPL_UP_WANT" ]; then
  note "그 폴더에 ${CPN:-?}개가 있다 — 우리 둘 말고 다른 것이 섞여 있다. 아래 명령은 **둘만** 보낸다"
fi

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
if [ "$FAIL" != "0" ]; then
  printf '%s\n' "🔴 위 ✗ 를 보세요. **NAS 에는 아무것도 안 보냈습니다** (이 파일은 NAS 에 붙지 않습니다)."
  printf '%s\n' "────────────────────────────────────────────────────────────"
  exit 1
fi

# ══ 🔴 사람이 칠 명령 — **한 줄에 하나씩** ════════════════════════════
#   🔵 보내기 전에 NAS 에서 **--prep 가 먼저 돌아야** 한다. 받을 자리가 없거나
#      777 이 아니면 scp 가 "Permission denied" 로 한 장도 못 올린다
#      (스크립트는 root 로 도는데 scp 는 다른 계정으로 붙는다).
printf '%s\n' "✅ 두 장이 보낼 자리에 들어갔습니다. **운영은 아직 한 글자도 안 바뀌었습니다.**"
printf '%s\n' ""
printf '%s\n' "🔴 **① 먼저 NAS 에서 받을 자리를 만드세요** (안 만들면 scp 가 거절당합니다)"
printf '%s\n' "    (NAS)  sudo -i"
printf '%s\n' "           bash /volume1/dss/setup/56-templates.sh --prep"
printf '%s\n' ""
printf '%s\n' "🔴 **② 그다음 개발 PC (PowerShell) 에서 두 장을 보내세요**"
printf '%s\n' "    cd \"$(to_win "$TPLOUT")\""
while IFS='|' read -r VAR NAME WSZ WM5; do
  [ -n "${NAME:-}" ] || continue
  printf '%s\n' "    scp -O \"$NAME\" dss-nas:$TPLIN/"
done <<SCPEOF
$(printf '%s\n' "$TPL_UP" | grep -v '^[[:space:]]*$')
SCPEOF
printf '%s\n' "  🔴 **한 줄에 하나씩입니다.** 이름에 공백과 한글이 둘 다 있어 별표(*)로 묶으면"
printf '%s\n' "     PowerShell 이 어떻게 쪼갤지 장담할 수 없습니다."
printf '%s\n' "  🔴 **scp 에는 -O 를 붙입니다.** DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' "  🔴 **보내는 쪽에 드라이브 문자(C:)를 주지 마세요** — 위처럼 폴더로 들어가서 보냅니다."
printf '%s\n' ""
printf '%s\n' "🔴 **③ 마지막으로 NAS 에서 제자리로 옮기세요** (여기가 운영이 바뀌는 유일한 자리입니다)"
printf '%s\n' "    (NAS)  bash /volume1/dss/setup/56-templates.sh --apply"
printf '%s\n' "    (NAS)  bash /volume1/dss/setup/56-templates.sh            ← 다시 --check"
printf '%s\n' ""
printf '%s\n' "🔵 **앱은 쓸 때마다 양식을 다시 읽습니다 — 컨테이너를 안 내려도 바뀝니다.**"
printf '%s\n' "   이미지도 마이그레이션도 compose 도 이번엔 손대지 않습니다."
printf '%s\n' "🔴 **되돌리는 법**은 --prep 와 --apply 가 백업 경로와 함께 찍어 줍니다 —"
printf '%s\n' "   양식은 어떤 --rollback 으로도 안 돌아갑니다."
printf '%s\n' "────────────────────────────────────────────────────────────"
exit 0
