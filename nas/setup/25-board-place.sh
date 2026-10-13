#!/bin/sh
# 게시판 설치 파일 셋을 제자리로 옮기고, 첨부 폴더를 만들어 권한을 맞춘다.
# 🔴 사람이 sudo -i 로 돌린다.
#   실행:  sh /volume1/dss/setup/25-board-place.sh
#
# 🔴 순서가 있다 — board.env 가 **먼저**다.
#    그것 없이 compose 의 app-board 를 켠 판을 놓으면 docker compose 명령이
#    **통째로** 안 먹는다. 앱을 멈춘 뒤에 그걸 알면 다시 띄우지도 못한다
#    (개선요청 첫 설치 때의 교훈 · PO 와 휴가도 같은 까닭으로 주석이었다).
#
# 🔴 옛 파일은 지우지 않고 사본을 남긴다. 되돌릴 자리가 필요하다.
#    compose 의 옛 판은 backups/docker-compose.nas.yml.<시각> 으로 간다 —
#    25-deploy.sh --rollback 이 그 자리를 안내한다.
#
# ── 🔴 첨부 폴더가 이 스크립트의 둘째 일이다 ──────────────────────────
#    컨테이너는 node(uid 1000)로 돈다. dss 공유폴더에는 시놀로지 ACL
#    (administrators 만 허용)이 걸려 있는데, uid 1000 은 DSM 계정이 아니라
#    ACL 로는 권한을 줄 수 없다. 그래서 **이 폴더만** ACL 을 걷고 리눅스
#    권한으로 준다 — 01-prepare.sh 가 as-attachments · meters-files 에 한 것과
#    같은 방식이고, 개선요청의 improvements-uploads 도 같다.
#
#    🔴 「만들었나」가 아니라 **「쓸 수 있나」**를 본다. 임시 컨테이너를
#       -u 1000:1000 으로 띄워 **실제로 파일을 만들었다 지운다.** 권한 함정은
#       배포할 때 안 보이고 사람이 사진을 붙일 때 처음 드러난다.

set -u
D=/volume1/dss
IN=$D/setup/incoming
DOCKER=/usr/local/bin/docker
ACLT=/usr/syno/bin/synoacltool
UP=$D/board-uploads
STAMP=$(date +%Y%m%d-%H%M%S)
FAIL=0

# ── 개발 PC 에서 잰 값 — 이것과 다르면 옮기지 않는다 ───────────────────
# 🔴 셋 중 하나만 채워져 있다. 까닭을 그대로 적어 둔다:
#    · backup-nightly.sh 는 이 조각에서 고쳤으므로 지금 잴 수 있었다.
#    · board.env 는 **아직 만들지 않았다**(비밀값이 들어가는 파일이라 이
#      저장소에 없다). compose 는 주석을 벗긴 판이 올라가는데, 벗기는 것은
#      점검표 3단계라 지금 저장소의 파일과 바이트가 다르다.
#    🔴 그래서 그 둘은 **대조하지 않는다.** 대신 아래 1번이 받은 값을 찍고
#       「대조하지 않았다」고 크게 말한다 — 조용히 지나가지 않게.
#       Claude 가 올리면서 잰 값과 눈으로 맞춰 주세요.
MD5_BACKUP=3784df3a1be025c9c8267ae07671ad01
MD5_ENV=
MD5_COMPOSE=

say()  { echo "$@"; }
ok()   { echo "  ✓ $*"; }
bad()  { echo "  ✗ $*"; FAIL=1; }

check_in() { # 1 파일이름 2 기대md5(비어 있으면 대조하지 않는다)
  got=""
  if [ ! -s "$IN/$1" ]; then
    bad "$IN/$1 이 없다 — 올렸는지 확인하세요 (scp 에는 -O 를 붙입니다)"
    return 1
  fi
  got=$(md5sum "$IN/$1" | awk '{print $1}')
  if [ -z "$2" ]; then
    say "  ⚠️ $1 · md5 $got — 🔴 **기대값이 없어 대조하지 않았다.**"
    say "     올리면서 잰 값과 같은지 눈으로 맞춰 주세요. 다르면 멈추세요."
    return 0
  fi
  if [ "$got" != "$2" ]; then
    bad "$1 의 md5 가 다르다 (받은 값 $got · 기대 $2)"
    say "     전송이 깨졌거나 다른 판입니다. 옮기지 않습니다."
    return 1
  fi
  ok "$1 · md5 맞음"
}

say "══ 1. 올라온 것이 맞는지 본다 (아직 안 옮긴다) ══"
check_in board.env              "$MD5_ENV"
check_in docker-compose.nas.yml "$MD5_COMPOSE"
check_in backup-nightly.sh      "$MD5_BACKUP"
[ "$FAIL" = 0 ] || { say; say "🔴 위를 먼저 해결하세요. 아무것도 안 옮겼습니다."; exit 1; }

say
say "══ 2. board.env 를 먼저 놓는다 (compose 보다 먼저) ══"
# 🔴 새 파일이라 덮어쓸 것이 없지만, 혹시 있으면 사본을 남긴다.
[ -f "$D/deploy/env/board.env" ] && cp -a "$D/deploy/env/board.env" "$D/deploy/env/board.env.bak-$STAMP"
cp "$IN/board.env" "$D/deploy/env/board.env" || exit 1
chown root:root "$D/deploy/env/board.env" && chmod 600 "$D/deploy/env/board.env" || exit 1
ok "env/board.env · $(stat -c '%U:%G %a' "$D/deploy/env/board.env")"
# 🔴 값은 안 찍는다. 키 개수와 **있으면 안 되는 줄**만 센다.
say "     키 $(grep -cE '^[A-Z_]+=' "$D/deploy/env/board.env") 개 (일곱이어야 합니다)"
for k in DATABASE_URL PORT STORAGE_ROOT TZ SEED_DEV_ENABLED; do
  n=$(grep -cE "^[[:space:]]*(export[[:space:]]+)?$k=" "$D/deploy/env/board.env" 2>/dev/null || true)
  if [ "${n:-0}" = 0 ]; then
    ok "board.env 에 $k 가 없다 (맞다 — compose·이미지가 넘긴다)"
  else
    bad "board.env 에 $k 가 **있다** (${n}줄) — 지우세요"
  fi
done

say
say "══ 3. 야간 백업 스크립트 ══"
cp -a "$D/jobs/backup-nightly.sh" "$D/jobs/backup-nightly.sh.bak-$STAMP" 2>/dev/null \
  && say "  · 옛것 사본: jobs/backup-nightly.sh.bak-$STAMP"
cp "$IN/backup-nightly.sh" "$D/jobs/backup-nightly.sh" || exit 1
chown root:root "$D/jobs/backup-nightly.sh" && chmod 700 "$D/jobs/backup-nightly.sh" || exit 1
ok "jobs/backup-nightly.sh · dss_board 줄 $(grep -c 'dss_board' "$D/jobs/backup-nightly.sh") 개"
ok "jobs/backup-nightly.sh · board-uploads 줄 $(grep -c 'board-uploads' "$D/jobs/backup-nightly.sh") 개"
# 🔴 옮겨 놓은 것이 **돌 수 있는 파일인지**까지 본다. 문법이 깨진 백업
#    스크립트는 밤에 조용히 아무 일도 하지 않는다.
if bash -n "$D/jobs/backup-nightly.sh" 2>/dev/null; then
  ok "야간 백업 문법 통과"
else
  bad "야간 백업에 문법 오류가 있다 — 옛 사본으로 되돌리세요"
  bash -n "$D/jobs/backup-nightly.sh" 2>&1 | sed 's/^/     /' | head -5
fi

say
say "══ 4. compose — 문법을 먼저 보고 옮긴다 ══"
# 🔴 바꾸기 **전에** 새 파일이 말이 되는지 본다. 깨진 것을 놓으면 모든 docker
#    compose 명령이 안 먹어 되돌리기도 어려워진다.
#
# 🔴 --project-directory 가 반드시 있어야 한다. compose 안의 env_file 은
#    ./env/board.env 처럼 **상대 경로**인데, 그 기준은 기본적으로 -f 로 준
#    파일이 있는 폴더다. incoming 에 둔 채로 검사하면 incoming/env/auth.env 를
#    찾다가 「no such file」로 죽는다 — 파일이 멀쩡해도 그렇다
#    (2026-09-29 휴가 설치에서 실제로 걸렸다). 놓일 자리(deploy/)를 기준으로
#    봐야 진짜 검사가 된다. **2번이 board.env 를 이미 놓았으므로** 여기서
#    새 compose 가 그 파일을 제대로 찾는지까지 한 번에 드러난다.
CFG="$DOCKER compose -f $IN/docker-compose.nas.yml \
  --project-directory $D/deploy --env-file $D/deploy/.env.nas --profile tools"
if $CFG config --quiet >/dev/null 2>&1; then
  ok "새 compose 문법 통과 (놓일 자리 기준으로 봤다)"
else
  bad "새 compose 가 문법에서 걸린다 — 옮기지 않는다"
  $CFG config --quiet 2>&1 | sed 's/^/     /' | head -8
  say "  🔴 board.env 가 2번에서 제대로 놓였는지부터 보세요."
  exit 1
fi
cp -a "$D/deploy/docker-compose.nas.yml" "$D/backups/docker-compose.nas.yml.$STAMP" 2>/dev/null \
  && say "  · 옛것 사본: backups/docker-compose.nas.yml.$STAMP"
cp "$IN/docker-compose.nas.yml" "$D/deploy/docker-compose.nas.yml" || exit 1
chown root:root "$D/deploy/docker-compose.nas.yml" && chmod 644 "$D/deploy/docker-compose.nas.yml" || exit 1
ok "deploy/docker-compose.nas.yml"

say
say "══ 5. 🔴 첨부 폴더를 만들고 권한을 맞춘다 ══"
say "  $UP — 컨테이너가 node(uid 1000)로 돈다. ACL 을 걷고 리눅스 권한으로 준다."
mkdir -p "$UP" || exit 1
# find … -exec 로 폴더와 그 아래 전부에서 ACL 을 뗀다 (01-prepare.sh 의 unacl).
find "$UP" -exec "$ACLT" -del {} \; >/dev/null 2>&1
chown -R 1000:1000 "$UP" || exit 1
chmod 750 "$UP" || exit 1
# 🔴 판정은 **숫자**(%u:%g)로 한다. DSM 에 uid 1000 짜리 계정이 있으면 %U 가
#    그 이름으로 보여 「1000 이 아니다」로 잘못 읽는다. 이름은 보여 주기만 한다.
MODE=$(stat -c '%u:%g %a' "$UP" 2>/dev/null)
say "  · $UP · $MODE (숫자) · $(stat -c '%U:%G' "$UP" 2>/dev/null) (이름)"
case "$MODE" in
  *" 750") ok "모드 750" ;;
  *)       bad "모드가 750 이 아니다 ($MODE)" ;;
esac
case "$MODE" in
  "1000:1000 "*) ok "주인이 uid 1000 (node)이다" ;;
  *)             bad "주인이 uid 1000 이 아니다 ($MODE) — 컨테이너가 못 쓴다" ;;
esac
ACLN=$("$ACLT" -get "$UP" 2>&1 | grep -cE ':(allow|deny):')
[ "${ACLN:-1}" = 0 ] && ok "ACL 항목 0개 (걷혔다)" \
  || bad "ACL 항목이 ${ACLN}개 남아 있다 — 컨테이너가 막힌다"

say
say "══ 6. 🔴 진짜 확인 — uid 1000 이 **실제로 쓸 수 있나** ══"
say "  「있는가」가 아니라 「쓸 수 있는가」를 봅니다. 임시 컨테이너를 띄워"
say "  파일을 하나 만들었다 지웁니다 (01-prepare.sh 의 probe 와 같은 방식)."
PROBE_IMG=""
for t in dss-board:0.1 dss-leave:0.2 dss-improvements:0.3 dss-as:2.5 dss-auth:1.6; do
  if "$DOCKER" image inspect "$t" >/dev/null 2>&1; then PROBE_IMG=$t; break; fi
done
if [ -z "$PROBE_IMG" ]; then
  bad "시험에 쓸 이미지를 하나도 찾지 못했다 — 쓰기 시험을 **못 했다**"
  say "     (게시판 이미지를 실은 뒤 25-deploy.sh 가 같은 시험을 다시 합니다.)"
else
  say "  · 시험에 쓴 이미지: $PROBE_IMG"
  # 🔴 콜론과 리다이렉션으로 빈 파일을 만드는 방식을 쓰지 마라 — 쓰기가 막히면
  #    ash 가 셸을 그 자리에서 끝내, 뒤 줄이 아예 안 돌고 판정이 **빈 채로**
  #    지나간다(2026-10-12 실측). touch 는 외부 명령이라 실패해도 셸이 산다.
  OUT=$("$DOCKER" run --rm --network none -u 1000:1000 \
        -v "$UP:/data/uploads" --entrypoint sh "$PROBE_IMG" -c '
          id
          if touch /data/uploads/.dss-write-test 2>/dev/null; then
            echo "PROBE WRITE_OK"
            rm -f /data/uploads/.dss-write-test 2>/dev/null
          else
            echo "PROBE WRITE_FAIL"
          fi' 2>&1)
  printf '%s\n' "$OUT" | grep -E '^(uid=|PROBE )' | sed 's/^/     /'
  case "$OUT" in
    *"PROBE WRITE_OK"*)
      ok "🔴 uid 1000 이 $UP 에 **실제로 썼다** (바로 지웠다)" ;;
    *"PROBE WRITE_FAIL"*)
      bad "🔴 uid 1000 이 못 쓴다 — 사람이 사진을 붙이는 순간 깨진다"
      say "     ACL 이 남았거나 주인이 다릅니다. 위 5번 값을 보세요." ;;
    *)
      bad "쓰기 시험을 판정하지 못했다 — 아래가 그대로의 출력이다"
      printf '%s\n' "$OUT" | sed 's/^/     /' | head -6 ;;
  esac
  # 시험 파일이 남지 않았는지까지 본다.
  LEFT=$(find "$UP" -maxdepth 1 -name '.dss-write-test' 2>/dev/null | wc -l)
  [ "${LEFT:-0}" = 0 ] && ok "시험 파일이 남지 않았다" \
    || bad "시험 파일이 남아 있다 — 손으로 지우세요: rm -f $UP/.dss-write-test"
fi

say
say "══ 7. 제자리 것이 맞는지 다시 본다 ══"
# 🔴 「올렸다」가 아니라 「제자리에 맞는 것이 있다」를 본다. 2026-09-29 에
#    새 스크립트를 제자리로 복사하는 것을 빠뜨린 채 --go 를 돌려, 옛 스크립트가
#    새 compose 를 갈아 끼우고 어긋나 멈췄다.
for f in "$D/deploy/env/board.env" "$D/deploy/docker-compose.nas.yml" "$D/jobs/backup-nightly.sh"; do
  if [ -s "$f" ]; then
    say "  · $(basename "$f") · $(stat -c '%U:%G %a' "$f") · md5 $(md5sum "$f" | awk '{print $1}')"
  else
    bad "$(basename "$f") 가 제자리에 없다"
  fi
done
if [ "$(md5sum "$D/jobs/backup-nightly.sh" | awk '{print $1}')" = "$MD5_BACKUP" ]; then
  ok "backup-nightly.sh 가 기대한 판이다"
else
  bad "backup-nightly.sh 가 기대한 판이 아니다"
fi

say
say "══ 8. 서비스 목록에 게시판이 보이나 ══"
"$DOCKER" compose -f "$D/deploy/docker-compose.nas.yml" \
  --project-directory "$D/deploy" --env-file "$D/deploy/.env.nas" --profile tools \
  config --services 2>/dev/null | grep -E 'board' | sed 's/^/  · /' \
  || bad "게시판 서비스가 안 보인다 — compose 의 주석을 안 벗긴 판을 올린 것이다"

say
say "══ 9. 임시 자리를 비운다 ══"
# 🔴 board.env 에는 비밀값이 있다. 아무나 읽는 폴더에 두지 않는다.
rm -f "$IN/board.env" "$IN/docker-compose.nas.yml" "$IN/backup-nightly.sh"
ok "incoming 을 비웠다"

say
if [ "$FAIL" = 0 ]; then
  say "══ 다 됐습니다 ══"
  say "  다음: 야간 백업을 손으로 한 번 돌려 dss_board 가 뜨는지 봅니다."
  say
  say "    bash /volume1/dss/jobs/backup-nightly.sh"
  say
  say "  ✓ dss_board 줄과 ✓ board-uploads 줄이 찍혀야 합니다 (DB 여섯)."
  say "  그다음 설치로 갑니다 —  bash /volume1/dss/setup/25-deploy.sh"
  exit 0
else
  say "══ 🔴 위 ✗ 를 보세요 ══"
  say "  사본이 남아 있습니다 (.bak-$STAMP · backups/…$STAMP)"
  exit 1
fi
