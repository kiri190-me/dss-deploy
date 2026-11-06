#!/bin/sh
# ============================================================================
# 개발에서 만든 기술 작업 절차를 **운영에 넣는다** — 짐 하나를 들여놓는 길
# ============================================================================
# 🔴 **왜 스크립트인가**: 이 일을 부르는 docker compose 한 줄이 230자가 넘는다.
#    DSM 터미널이 긴 줄을 **잘라 먹어서**, 2026-11-06 에 `--file` 뒤의 값이 날아가
#    Usage 만 뜨고 끝났다. 긴 명령을 손으로 치지 않는다 — 파일로 올리고 md5 를 맞춘다.
#
#    차례:  --who  →  --dry --actor <uuid>  →  --go --actor <uuid>
#
#    🔵 --who 와 --dry 는 **DB 를 한 글자도 안 바꾼다.**
#    🔴 --go 만 쓴다. 그것도 **한 트랜잭션** 안에서 하고, 넣기 전에 네 겹(id 충돌 ·
#       code+판 충돌 · 이름 충돌 · 작성자 계정)을 전부 세어 하나라도 걸리면 멈춘다.
#
# 🔵 짐 파일은 **이미지 안에 없다** — `-v` 로 붙여야 컨테이너가 본다.
#    넣는 도구 자체는 dss-as-tools:12 부터 들어 있다(49번째 배포).
# ============================================================================
set -u

D=/volume1/dss/deploy
CF=$D/docker-compose.nas.yml
DOCKER=/usr/local/bin/docker        # 비로그인 PATH 에 없다 — 전체 경로로 쓴다
HOSTDIR=/volume1/dss/transfer       # 짐을 놓는 자리 (scp 가 쓰려면 777 이어야 한다)
BUNDLE=bundle.json
SVC=tools-as

MODE=who
ACTOR=
NAMES=
while [ $# -gt 0 ]; do
  case "$1" in
    --who)   MODE=who ;;
    --find)  MODE=find; NAMES=${2:-}; shift ;;
    --dry)   MODE=dry ;;
    --go)    MODE=go ;;
    --actor) ACTOR=${2:-}; shift ;;
    --file)  BUNDLE=${2:-}; shift ;;
    *) printf '모르는 깃발: %s\n' "$1"; exit 1 ;;
  esac
  shift
done

[ "$(id -u)" = 0 ] || { printf '먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요.\n'; exit 1; }

# ── --find: 이름으로 사람을 찾는다 (🔵 **읽기만 한다**) ──────────────────
# 🔴 넣는 도구의 `--who` 는 **SUPER_ADMIN·ADMIN 만** 찍는다. 그것은 「고를 만한
#    사람」을 보여 주려는 편의이지 넣을 수 있는 사람의 전부가 아니다 — 실제 검증은
#    **APPROVED · 활성 · 안 지워짐** 셋뿐이고 역할을 안 본다. 그래서 엔지니어를
#    작성자로 적으려면 그 uuid 를 따로 찾아야 한다.
# 🔵 DB 비밀번호를 여기 적지 않는다 — 컨테이너 안의 $POSTGRES_USER 로 묻는다
#    (52-deploy.sh 의 q() 와 같은 길이다).
if [ "$MODE" = find ]; then
  [ -n "$NAMES" ] || { printf "🔴 --find '이름1,이름2' 처럼 주세요.\n"; exit 1; }
  IN=$(printf '%s' "$NAMES" | sed "s/,/','/g")
  printf '이름으로 찾는다: %s\n' "$NAMES"
  printf '🔵 읽기만 합니다 — SELECT 뿐입니다.\n\n'
  printf '  %s\n' 'id | 이름 | 역할 | 승인 | 활성 | 지워짐'
  "$DOCKER" exec -i dss-pg-app sh -c \
    "psql -U \"\$POSTGRES_USER\" -d dss_as -X -tAq -F' | ' -c \
     \"SELECT id, name, role, approval_status, is_active, is_deleted FROM users WHERE name IN ('$IN') ORDER BY name;\"" \
    2>/dev/null | sed 's/^/  /'
  printf '\n🔴 넣을 수 있으려면 **승인=APPROVED · 활성=t · 지워짐=f** 여야 합니다.\n'
  printf '🔵 한 줄도 안 나오면 그 이름이 운영에 **없는 것**입니다.\n'
  exit 0
fi

printf '절차 이관 — %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
printf '  이 파일의 md5: %s\n' "$(md5sum "$0" | cut -d' ' -f1)"
printf '  모드: %s\n' "$MODE"
printf '%s\n' '────────────────────────────────────────────────────────────'

# 🔴 짐이 **정말 그 자리에 있는가**를 먼저 본다. 없으면 컨테이너를 띄울 까닭이 없고,
#    「파일이 없다」가 컨테이너 안의 오류로 뒤늦게 나오면 까닭을 가리기 어렵다.
SRC=$HOSTDIR/$BUNDLE
if [ ! -f "$SRC" ]; then
  printf '🔴 짐이 없다: %s\n' "$SRC"
  printf '   개발 PC 에서 보내세요:  scp -O "$env:TEMP/%s" dss-nas:%s/\n' "$BUNDLE" "$HOSTDIR"
  printf '   🔴 -O 를 빼면 DSM 에 sftp 서버가 없어 실패합니다.\n'
  exit 1
fi
printf '  짐: %s\n' "$SRC"
printf '      %s바이트 · md5 %s\n' "$(stat -c%s "$SRC")" "$(md5sum "$SRC" | cut -d' ' -f1)"
printf '  🔵 개발 PC 의 값과 같은지 눈으로 맞대세요 (옮기다 깨진 것을 잡는 유일한 자리)\n'
printf '%s\n' '────────────────────────────────────────────────────────────'

run() { # "$@" = 컨테이너에 더 줄 깃발
  cd "$D" || exit 1
  "$DOCKER" compose -f "$CF" --env-file .env.nas --profile tools \
    run --rm "$@" -v "$HOSTDIR:/transfer:ro" "$SVC" \
    npm run procedures:import -- --file "/transfer/$BUNDLE" ${ACTOR:+--actor "$ACTOR"}
}

case "$MODE" in
  who)
    printf '🔵 작성자를 안 주고 부른다 — 고를 수 있는 계정을 찍고 멈춘다. **읽기만 한다.**\n\n'
    # 🔵 `ACTOR= run` 으로 쓰지 않는다 — POSIX sh 에서 **함수** 앞의 변수 대입은
    #    그 뒤로도 남는다(외부 명령과 다르다). 여기서 비우고 부른다.
    ACTOR=
    run
    ;;
  dry)
    [ -n "$ACTOR" ] || { printf '🔴 --actor <uuid> 가 없다. 먼저 --who 로 고르세요.\n'; exit 1; }
    printf '🔵 드라이런 — **DB 를 한 글자도 안 바꾼다.**\n'
    printf '   맨 위에 어느 DB 에 넣는지가 찍힌다. 거기부터 보세요.\n\n'
    run
    ;;
  go)
    [ -n "$ACTOR" ] || { printf '🔴 --actor <uuid> 가 없다. 먼저 --who 로 고르세요.\n'; exit 1; }
    printf '✍ **진짜로 넣는다** (APPLY=1 · 한 트랜잭션)\n'
    printf '   🔴 끝의 두 줄을 읽으세요 — 「결과」는 내가 몇 번 불렀나이고,\n'
    printf '      「되읽기」는 **DB 를 다시 읽어 센 수**다. 어긋나면 0 아닌 종료 코드로 끝난다.\n\n'
    run -e APPLY=1
    ;;
esac
RC=$?

printf '\n%s\n' '────────────────────────────────────────────────────────────'
if [ "$MODE" = go ] && [ "$RC" = 0 ]; then
  printf '🔴 **넣은 절차는 전부 DRAFT 다.** 이 도구는 게시하지 않는다 —\n'
  printf '   화면에서 보고 사람이 따로 게시한다. 게시 전까지는 현장에서 안 보인다.\n'
  printf '🔵 뒤처리:  rm %s\n' "$SRC"
elif [ "$RC" != 0 ]; then
  printf '🔴 종료 코드 %s 로 끝났다. 위를 보세요.\n' "$RC"
  [ "$MODE" = go ] && printf '   🔵 한 트랜잭션이라 **반만 들어가지는 않는다** — 통째로 되돌아갔다.\n'
fi
exit $RC
