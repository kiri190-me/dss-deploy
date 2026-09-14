#!/bin/bash
# /volume1/dss/setup/01-prepare.sh — NAS 준비 (처음 한 번. 여러 번 돌려도 같은 결과)
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                        ← DSM 비밀번호. 한/영이 영문인지 먼저!
#   (NAS)         bash /volume1/dss/setup/01-prepare.sh
#
# ── 하는 일 — /volume1/dss 안만 건드린다. 다른 공유 폴더는 손대지 않는다 ────
#   1. 올라온 파일이 다 있는지 확인 (빠지면 아무것도 바꾸지 않고 멈춘다)
#   2. 폴더 권한 — 컨테이너 사용자가 읽고 쓸 수 있게
#   3. 이미지 불러오기 (dss-as·dss-auth·dss-meters 1.1) + postgres:17 받기
#   4. 실제 컨테이너를 잠깐 띄워 읽기·쓰기 시험 (시험 파일은 바로 지운다)
#
# 결과는 /volume1/dss/setup/logs/ 에 남는다. Claude 가 그 로그를 읽고 검수한다.
#
# ── 권한을 왜 이렇게 주나 ──────────────────────────────────────────────
# dss 공유 폴더에는 시놀로지 ACL(administrators 만 허용)이 걸려 있다. 그런데
# 컨테이너 안의 사용자 node(1000)·postgres(999)는 DSM 계정이 아니라 ACL 로는
# 권한을 줄 수 없다. 그래서 아래 폴더만 ACL 을 걷고 리눅스 권한으로 준다.
#   deploy/          root 만 (비밀번호가 들어 있다) · init 스크립트는 999 가 읽게
#   as-attachments/  node 읽기·쓰기      meters-files/  node 읽기·쓰기
#   as-templates/    node 읽기만         auth-keys/     node 읽기만
set -u
D=/volume1/dss
DOCKER=/usr/local/bin/docker
ACLT=/usr/syno/bin/synoacltool
TAG=1.1
TPL=(내자견적서.xlsx "제너레이터 OH 견적서.xlsx" "매쳐 내자 견적서.xlsx" "매쳐 OH 견적서.xlsx" 검사보고서.xlsx 수리보고서.xlsx)

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/01-prepare-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

PASS=0; FAIL=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
step() { echo; echo "── $*"; }
echo "DSS NAS 준비 · $(date '+%F %T')"

# ════════════════════════════════════════════════════════════════════
step "1. 올라온 파일"
for f in deploy/docker-compose.nas.yml deploy/.env.nas deploy/env/auth.env deploy/env/as.env \
         deploy/env/meters.env deploy/init/app/01-roles.sh deploy/init/auth/01-roles.sh; do
  [ -s "$D/$f" ] && ok "$f" || bad "$f 없음"
done
for f in "${TPL[@]}"; do [ -s "$D/as-templates/$f" ] || bad "양식 없음: $f"; done
[ "$(find "$D/as-templates" -maxdepth 1 -type f -name '*.xlsx' | wc -l)" = 6 ] && ok "양식 6개 (이름 그대로)"
n=$(find "$D/auth-keys" -maxdepth 1 -type f -name '*.json' | wc -l); [ "$n" = 2 ] && ok "서명키 2개" || bad "서명키 ${n}개 (2개여야 함)"
n=$(find "$D/meters-files" -type f ! -path '*/@eaDir/*' | wc -l); [ "$n" = 463 ] && ok "계측기 파일 463개" || bad "계측기 파일 ${n}개 (463개여야 함)"
if (cd "$D/images" && sha256sum -c --quiet SHA256SUMS); then ok "이미지 파일 3개 · 지문 일치"; else bad "이미지 파일이 없거나 깨짐"; fi
if [ "$FAIL" != 0 ]; then
  echo; echo "빠지거나 깨진 파일이 있어 여기서 멈춥니다. 아무것도 바꾸지 않았습니다."
  echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1
fi

# ════════════════════════════════════════════════════════════════════
step "2. 폴더 권한"
unacl() { find "$1" -exec "$ACLT" -del {} \; >/dev/null 2>&1; }

unacl "$D/deploy"
chown -R root:root "$D/deploy"
find "$D/deploy" -type d -exec chmod 755 {} +
chmod 644 "$D/deploy/docker-compose.nas.yml"
chmod 755 "$D/deploy/init/app/01-roles.sh" "$D/deploy/init/auth/01-roles.sh"
chmod 700 "$D/deploy/env"
chmod 600 "$D/deploy/.env.nas" "$D/deploy/env/"*.env

for p in as-attachments meters-files; do
  unacl "$D/$p"; chown -R 1000:1000 "$D/$p"
  find "$D/$p" -type d -exec chmod 750 {} +; find "$D/$p" -type f -exec chmod 640 {} +
done
for p in as-templates auth-keys; do
  unacl "$D/$p"; chown -R 1000:1000 "$D/$p"
  chmod 500 "$D/$p"; find "$D/$p" -type f -exec chmod 400 {} +
done
for p in deploy deploy/env as-attachments meters-files as-templates auth-keys; do
  acl=$("$ACLT" -get "$D/$p" 2>&1 | grep -cE ':(allow|deny):')
  printf "    %-15s %s · ACL 항목 %s개\n" "$p" "$(stat -c '%U:%G %a' "$D/$p")" "$acl"
  [ "$acl" = 0 ] || bad "$p 에 ACL 이 남아 있음"
done
[ "$(stat -c '%a' "$D/deploy/.env.nas")" = 600 ] && ok ".env.nas · env/*.env 는 root 만 읽는다" || bad ".env.nas 권한"

# ════════════════════════════════════════════════════════════════════
step "3. 이미지"
for t in dss-as dss-auth dss-meters; do
  "$DOCKER" load -q -i "$D/images/$t-$TAG.tar" >/dev/null 2>&1
  if "$DOCKER" image inspect "$t:$TAG" >/dev/null 2>&1; then
    ok "$t:$TAG · git $("$DOCKER" image inspect "$t:$TAG" --format '{{index .Config.Labels "dss.git-sha"}}')"
  else bad "$t:$TAG 불러오기 실패"; fi
done
if "$DOCKER" pull -q postgres:17 >/dev/null 2>&1; then
  ok "postgres:17 · $("$DOCKER" run --rm --network none postgres:17 postgres --version)"
else bad "postgres:17 받기 실패 — NAS 가 인터넷에 닿는지 확인"; fi

# ════════════════════════════════════════════════════════════════════
step "4. 실제 컨테이너로 시험 (쓰고 바로 지운다)"
probe() { # 설명 이미지 사용자 마운트 명령
  if "$DOCKER" run --rm --network none --user "$3" -v "$4" --entrypoint sh "$2" -c "$5" >/dev/null 2>&1
  then ok "$1"; else bad "$1"; fi
}
probe "A/S 첨부 폴더에 node(1000)가 쓴다"        "dss-as:$TAG"     1000:1000 "$D/as-attachments:/data" \
      'touch /data/.probe && rm /data/.probe'
probe "계측기 폴더에 node(1000)가 쓴다 · 463개 보임" "dss-meters:$TAG" 1000:1000 "$D/meters-files:/data" \
      'touch /data/.probe && rm /data/.probe && [ "$(find /data -type f | wc -l)" -eq 463 ]'
probe "양식 6개를 node(1000)가 읽는다 (한글 이름)" "dss-as:$TAG"     1000:1000 "$D/as-templates:/templates:ro" \
      'for f in "내자견적서.xlsx" "제너레이터 OH 견적서.xlsx" "매쳐 내자 견적서.xlsx" "매쳐 OH 견적서.xlsx" "검사보고서.xlsx" "수리보고서.xlsx"; do head -c 2 "/templates/$f" | grep -q PK || exit 1; done'
probe "양식 폴더에는 쓰지 못한다 (읽기 전용)"      "dss-as:$TAG"     1000:1000 "$D/as-templates:/templates:ro" \
      '! touch /templates/.probe 2>/dev/null'
probe "서명키를 node(1000)가 읽는다"               "dss-auth:$TAG"   1000:1000 "$D/auth-keys:/keys:ro" \
      'cat /keys/*.json >/dev/null'
probe "DB 초기화 스크립트를 postgres(999)가 읽는다" postgres:17      999:999   "$D/deploy/init:/i:ro" \
      'cat /i/app/01-roles.sh /i/auth/01-roles.sh >/dev/null'

# ════════════════════════════════════════════════════════════════════
step "결과 — 통과 $PASS · 실패 $FAIL"
if [ "$FAIL" = 0 ]; then echo "  → 준비 끝. Claude 에게 '끝났어'라고 알려 주세요."
else echo "  → 실패가 있습니다. Claude 에게 알려 주세요. 로그: $LOG"; fi
