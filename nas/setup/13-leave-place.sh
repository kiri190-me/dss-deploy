#!/bin/sh
# 휴가 설치 파일 셋을 제자리로 옮긴다. 🔴 사람이 sudo -i 로 돌린다.
#   실행:  sh /volume1/dss/setup/13-leave-place.sh
#
# 🔴 순서가 있다 — leave.env 가 **먼저**다.
#    그것 없이 compose 의 app-leave 를 켜면 docker compose 명령이 **통째로** 안 먹는다.
#    앱을 멈춘 뒤에 그걸 알면 다시 띄우지도 못한다(개선요청 첫 설치 때의 교훈).
#
# 🔴 md5 를 하나하나 맞춘다. 2026-09-29 에 새 스크립트를 제자리로 복사하는 것을
#    빠뜨린 채 --go 를 돌려, 옛 스크립트가 새 compose 를 갈아 끼우고 어긋나 멈췄다.
#    「올렸다」가 아니라 「제자리에 맞는 것이 있다」를 본다.
#
# 옛 파일은 지우지 않고 사본을 남긴다. 되돌릴 자리가 필요하다.

set -u
D=/volume1/dss
IN=$D/setup/incoming
STAMP=$(date +%Y%m%d-%H%M%S)
FAIL=0

# 개발 PC 에서 잰 값 — 이것과 다르면 옮기지 않는다.
MD5_ENV=64e58c7b108e5e8b5151e800c7415b0d
MD5_COMPOSE=e5f7ecfca0e8a0eb4e2bfa13dce1be48
MD5_BACKUP=67907332aff275540ef8751c05bfb331

say()  { echo "$@"; }
ok()   { echo "  ✓ $*"; }
bad()  { echo "  ✗ $*"; FAIL=1; }

check_in() { # 1 파일이름 2 기대md5
  if [ ! -s "$IN/$1" ]; then bad "$IN/$1 이 없다 — Claude 가 올렸는지 확인하세요"; return 1; fi
  got=$(md5sum "$IN/$1" | awk '{print $1}')
  if [ "$got" != "$2" ]; then
    bad "$1 의 md5 가 다르다 (받은 값 $got · 기대 $2)"
    say "     전송이 깨졌거나 다른 판입니다. 옮기지 않습니다."
    return 1
  fi
  ok "$1 · md5 맞음"
}

say "══ 1. 올라온 것이 맞는지 본다 (아직 안 옮긴다) ══"
check_in leave.env              "$MD5_ENV"
check_in docker-compose.nas.yml "$MD5_COMPOSE"
check_in backup-nightly.sh      "$MD5_BACKUP"
[ "$FAIL" = 0 ] || { say; say "🔴 위를 먼저 해결하세요. 아무것도 안 옮겼습니다."; exit 1; }

say
say "══ 2. leave.env 를 먼저 놓는다 (compose 보다 먼저) ══"
# 🔴 새 파일이라 덮어쓸 것이 없지만, 혹시 있으면 사본을 남긴다.
[ -f "$D/deploy/env/leave.env" ] && cp -a "$D/deploy/env/leave.env" "$D/deploy/env/leave.env.bak-$STAMP"
cp "$IN/leave.env" "$D/deploy/env/leave.env" || exit 1
chown root:root "$D/deploy/env/leave.env" && chmod 600 "$D/deploy/env/leave.env" || exit 1
ok "env/leave.env · $(stat -c '%U:%G %a' "$D/deploy/env/leave.env")"
# 🔴 값은 안 찍는다. 키 개수와 위험한 줄만 본다.
say "     키 $(grep -cE '^[A-Z_]+=' "$D/deploy/env/leave.env") 개 · \
DATABASE_URL $(grep -cE '^DATABASE_URL=' "$D/deploy/env/leave.env") 개 · \
가짜로그인 $(grep -E '^DEV_FAKE_LOGIN_ENABLED=' "$D/deploy/env/leave.env" | head -1)"

say
say "══ 3. 야간 백업 스크립트 ══"
cp -a "$D/jobs/backup-nightly.sh" "$D/jobs/backup-nightly.sh.bak-$STAMP" 2>/dev/null \
  && say "  · 옛것 사본: jobs/backup-nightly.sh.bak-$STAMP"
cp "$IN/backup-nightly.sh" "$D/jobs/backup-nightly.sh" || exit 1
chown root:root "$D/jobs/backup-nightly.sh" && chmod 700 "$D/jobs/backup-nightly.sh" || exit 1
ok "jobs/backup-nightly.sh · dss_leave 줄 $(grep -c 'dss_leave' "$D/jobs/backup-nightly.sh") 개"

say
say "══ 4. compose — 문법을 먼저 보고 옮긴다 ══"
# 🔴 바꾸기 **전에** 새 파일이 말이 되는지 본다. 깨진 것을 놓으면 모든 docker
#    compose 명령이 안 먹어 되돌리기도 어려워진다.
#
# 🔴 --project-directory 가 반드시 있어야 한다. compose 안의 env_file 은
#    `./env/leave.env` 처럼 **상대 경로**인데, 그 기준은 기본적으로 **-f 로 준 파일이
#    있는 폴더**다. incoming 에 둔 채로 검사하면 `incoming/env/auth.env` 를 찾다가
#    「no such file」로 죽는다 — 파일이 멀쩡해도 그렇다(2026-09-29 실제로 걸렸다).
#    놓일 자리(deploy/)를 기준으로 봐야 진짜 검사가 된다.
CFG="/usr/local/bin/docker compose -f $IN/docker-compose.nas.yml \
  --project-directory $D/deploy --env-file $D/deploy/.env.nas --profile tools"
if $CFG config --quiet >/dev/null 2>&1; then
  ok "새 compose 문법 통과 (놓일 자리 기준으로 봤다)"
else
  bad "새 compose 가 문법에서 걸린다 — 옮기지 않는다"
  $CFG config --quiet 2>&1 | sed 's/^/     /' | head -8
  exit 1
fi
cp -a "$D/deploy/docker-compose.nas.yml" "$D/backups/docker-compose.nas.yml.$STAMP" 2>/dev/null \
  && say "  · 옛것 사본: backups/docker-compose.nas.yml.$STAMP"
cp "$IN/docker-compose.nas.yml" "$D/deploy/docker-compose.nas.yml" || exit 1
chown root:root "$D/deploy/docker-compose.nas.yml" || exit 1
ok "deploy/docker-compose.nas.yml"

say
say "══ 5. 제자리 것이 맞는지 다시 본다 ══"
for pair in "$D/deploy/env/leave.env:$MD5_ENV" \
            "$D/deploy/docker-compose.nas.yml:$MD5_COMPOSE" \
            "$D/jobs/backup-nightly.sh:$MD5_BACKUP"; do
  f=${pair%:*}; want=${pair##*:}
  got=$(md5sum "$f" | awk '{print $1}')
  [ "$got" = "$want" ] && ok "$(basename "$f")" || bad "$(basename "$f") 가 어긋난다"
done

say
say "══ 6. 서비스 목록에 휴가가 보이나 ══"
/usr/local/bin/docker compose -f "$D/deploy/docker-compose.nas.yml" \
  --env-file "$D/deploy/.env.nas" --profile tools config --services 2>/dev/null \
  | grep -E 'leave' | sed 's/^/  · /' || bad "휴가 서비스가 안 보인다"

say
say "══ 7. 임시 자리를 비운다 ══"
# 🔴 leave.env 에는 비밀값이 있다. 아무나 읽는 폴더에 두지 않는다.
rm -f "$IN/leave.env" "$IN/docker-compose.nas.yml" "$IN/backup-nightly.sh"
ok "incoming 을 비웠다"

say
if [ "$FAIL" = 0 ]; then
  say "══ 다 됐습니다 ══"
  say "  다음: 야간 백업을 손으로 한 번 돌려 dss_leave 가 뜨는지 봅니다."
  say
  say "    bash /volume1/dss/jobs/backup-nightly.sh"
  say
  say "  그다음 설치로 갑니다 —  bash /volume1/dss/setup/13-deploy.sh"
  exit 0
else
  say "══ 🔴 위 ✗ 를 보세요 ══"
  say "  사본이 남아 있습니다 (.bak-$STAMP · backups/…$STAMP)"
  exit 1
fi
