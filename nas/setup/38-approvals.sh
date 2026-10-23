#!/bin/sh
# dss-deploy/nas/setup/38-approvals.sh — 통합 승인함을 세운다 (2026-10-24)
#   = 서른다섯째 배포 ②. 열째 사이트다.
#
# 🔴 NAS 에서 돈다. 사람이 `sudo -i` 로 돌린다.
#    DSM 터미널은 긴 명령을 잘라 먹으므로 **파일로 올려** 돌린다.
#    md5 를 맞춘다:  md5sum /volume1/dss/setup/38-approvals.sh
#
# ── 🔴 사람이 먼저 끝낸 것 둘 (2026-10-24 실측) ──────────────────────
#     approvals.dss21.co.kr → 192.168.0.222      Cloudflare A 레코드 (DNS 전용)
#     https://approvals.dss21.co.kr → 502        DSM 프록시 · 인증서 검증 0
#   🔵 502 가 맞다 — 앱이 아직 없다. 이 스크립트가 그 앱을 세운다.
#
# ── 모드 다섯 ─────────────────────────────────────────────────────────
#   (기본) --check      아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --init              env/approvals.env 를 만든다 (비밀값 셋을 **그 자리에서**)
#   --client            포털에 등록한다 (해시만 넣는다)
#   --place             이미지를 들여놓고 compose 에 블록을 더하고 띄운다
#   --inbox-url         포털에 APPROVAL_INBOX_URL 을 넣고 포털을 다시 띄운다
#
#   🔴 차례:  --check → --init → --client → --place → --inbox-url
#
# ── 🔴 이 집이 다른 아홉과 다른 것 셋 ─────────────────────────────────
#   ① **DB 가 없다.** 표가 하나도 없다 — 세션은 서명 쿠키, 로그아웃 기록은
#      프로세스 메모리다. 그래서 `dss-data` 망에 안 붙이고, `tools-approvals`
#      서비스도 두지 않고, `DATABASE_URL` 도 안 넘긴다.
#      🔴 나중에 표가 생기면 그 셋을 **함께** 더해야 한다.
#   ② **호스트 포트가 14000 이다. 13900 이 아니다.** 13900 은 RF 이슈관리가
#      쓰고 있다. 개발 PC 에서 승인함이 3900 을 써서 헷갈리기 쉬운 자리다.
#   ③ **쌓이는 파일이 없다.** 볼륨을 안 붙인다 — 그것이 곧 「쌓일 자리가
#      없다」는 보증이다.
#
# ── 🔴 비밀값을 이 파일에 박지 않는다 ─────────────────────────────────
#   --init 이 그 자리에서 셋을 만들어 env/approvals.env(root 600)에 넣는다.
#   **평문은 채팅·로그·이 파일에 한 번도 안 찍힌다.** 포털에는 sha256 만 간다.
#   🔴 셋이 서로 달라야 한다 — 둘이 같으면 앱이 시작할 때 던진다.
set -u

D=/volume1/dss
CF=$D/deploy/docker-compose.nas.yml
ENVD=$D/deploy/env
ENVF=$ENVD/approvals.env
AUTHENV=$ENVD/auth.env
IMGD=$D/images
BKD=$D/backups
DOCKER=/usr/local/bin/docker
PGBOX=dss-pg-auth
STAMP=$(date +%Y%m%d-%H%M%S)

CLIENT_ID=dss-approvals
BASE=https://approvals.dss21.co.kr
ISSUER=https://login.dss21.co.kr
SVC=app-approvals
CN=dss-approvals
TAG=dss-approvals:0.1
TAR=dss-approvals-0.1.tar
HPORT=14000
CPORT=3900
# 🔴 90 이다. 처음에 60 으로 적었다가 --check 이 찍어 준 표에서 **계측기 관리가
#    이미 60 을 쓰고 있는 것**을 보고 고쳤다(2026-10-24).
#    지금: 10 게시판 · 20 RF이슈 · 30 PO · 40 A/S · 50 재고 · 60 계측기 ·
#          70 휴가 · 80 개선요청 → 승인함은 **90**.
#    🔵 맨 뒤라 **남의 타일이 하나도 안 움직인다.** 앞으로 당기고 싶으면 이 숫자만
#       고치면 된다 — 겹쳐도 포털이 깨지지는 않지만 차례가 애매해진다.
SORT=90

# 🔴 tar 지문 — [배포본] 에서 굽고 **바로 잰 값**이다.
TAR_SIZE=94882816
TAR_MD5=63e0842447cfe6c3a883bcf5ea5003c2
TAR_CFG=sha256:123016656e4b3299dc45d71baf2d7199c91ee66a6eaaa26ad2f670df687e21e8

MODE=check
case "${1:-}" in
  ""|--check)   MODE=check ;;
  --init)       MODE=init ;;
  --client)     MODE=client ;;
  --place)      MODE=place ;;
  --inbox-url)  MODE=inboxurl ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --init · --client · --place · --inbox-url\n' "$1"; exit 2 ;;
esac

PASS=0; FAIL=0; WARN=0
ok()  { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
hm()  { WARN=$((WARN+1)); printf '  ? %s\n' "$1"; }
say() { printf '    %s\n' "$1"; }

printf '%s\n' "통합 승인함 세우기 (서른다섯째 ②)   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "────────────────────────────────────────────────────────────"

[ "$(id -u)" = 0 ] || { printf '🔴 먼저 sudo -i 로 관리자(root)가 되세요.\n'; exit 1; }
[ -x "$DOCKER" ] || { printf '🔴 docker 를 못 찾았습니다: %s\n' "$DOCKER"; exit 1; }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then openssl dgst -sha256 | awk '{print $NF}'
  else echo ""; fi
}
mkpass() { # 48자 영문·숫자. 🔴 따옴표·등호가 들어가면 env 나 폼에서 조용히 잘린다.
  if command -v openssl >/dev/null 2>&1; then openssl rand -base64 64 | tr -dc 'A-Za-z0-9' | cut -c1-48
  else tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 48; fi
}
pg() { "$DOCKER" exec -i "$PGBOX" sh -c "psql -U \"\$POSTGRES_USER\" -d dss_auth -X -tAq -c \"$1\"" 2>/dev/null | head -1 | tr -d ' \r'; }

# ── 1. 둘레 ───────────────────────────────────────────────────────────
printf '\n== 1. 둘레\n'
[ -f "$CF" ] && ok "compose 가 있다 ($(wc -l < "$CF")줄 · image: $(grep -c '^ *image:' "$CF")개)" || bad "compose 가 없다: $CF"
"$DOCKER" ps --format '{{.Names}}' 2>/dev/null | grep -qx "$PGBOX" && ok "$PGBOX 가 돈다" || bad "$PGBOX 가 안 돈다"
"$DOCKER" ps --format '{{.Names}}' 2>/dev/null | grep -qx dss-auth && ok "포털이 돈다" || bad "포털이 안 돈다"

# 🔴 **먼저 「어느 단계인가」를 정하고 그 다음에 잰다.**
#    2026-10-24 에 여기서 가짜 ✗ 가 났다 — 「14000 이 이미 쓰이고 있다」를
#    --place 를 지난 뒤에도 그대로 재서, **우리가 쓰고 있는 것**을 남의 것처럼
#    세었다. 🔴 「전제가 단계마다 다른 검사」는 단계를 먼저 묻고 재야 한다.
if grep -qE "^  ${SVC}:" "$CF" 2>/dev/null; then PLACED=yes; else PLACED=no; fi

if [ "$PLACED" = yes ]; then
  hm "compose 에 $SVC 가 이미 있다 (--place 를 지났다)"
  if grep -q "127.0.0.1:$HPORT:" "$CF" 2>/dev/null; then ok "$HPORT 을 **우리 블록이** 쓰고 있다"
  else bad "$SVC 가 있는데 $HPORT 이 없다 — 블록이 반만 들어갔다"; fi
else
  ok "compose 에 $SVC 가 아직 없다"
  # 🔴 포트가 정말 비어 있는가. 저장소 사본이 아니라 **NAS 의 compose** 로 센다.
  if grep -q "127.0.0.1:$HPORT:" "$CF" 2>/dev/null; then bad "compose 에 $HPORT 이 이미 쓰이고 있다 — **남의 것이다.** 다른 번호를 고르세요"
  else ok "compose 에 $HPORT 이 아직 안 쓰인다"; fi
fi
# 🔴 13900 을 안 쓴다는 것도 못 박는다. 개발 PC 가 3900 이라 베끼기 쉽다.
grep -q "127.0.0.1:13900:" "$CF" 2>/dev/null && ok "13900 은 RF 이슈관리 것이다 (우리가 안 쓴다)" \
  || hm "13900 이 compose 에 없다 — RF 이슈관리를 확인해 보세요"

# ── 2. 바깥 주소 ──────────────────────────────────────────────────────
printf '\n== 2. 바깥 주소 (사람이 미리 넣은 것)\n'
CODE=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 15 "$BASE/" 2>/dev/null)
say "$BASE/ → ${CODE:-없음}"
# 🔴 기대값이 **단계마다 다르다.** --place 전에는 502 가 맞고, 지난 뒤에는 307 이
#    맞다. 한 잣대로 재면 둘 중 한쪽이 언제나 틀린 소리를 한다.
if [ "$PLACED" = yes ]; then
  case "${CODE:-}" in
    200|30[127]) ok "${CODE} 다 — 앱이 서 있다 (--place 를 지났으니 이게 맞다)" ;;
    502) bad "502 다 — 블록은 있는데 앱이 안 뜬다. 로그를 보세요" ;;
    "")  bad "응답이 없다 — DNS 나 DSM 프록시 규칙을 보세요" ;;
    *)   hm "${CODE} 다 — 307 을 기대했다" ;;
  esac
else
  case "${CODE:-}" in
    502) ok "502 다 — 프록시가 섰고 앱이 아직 없다 (지금은 이게 맞다)" ;;
    200|30[127]) hm "${CODE} 다 — 앱이 벌써 서 있다 (compose 블록 없이?)" ;;
    "")  bad "응답이 없다 — DNS 나 DSM 프록시 규칙을 보세요" ;;
    *)   hm "${CODE} 다 — 502 를 기대했다" ;;
  esac
fi
# 🔴 인증서까지 본다. 규칙만 만들고 인증서를 안 고르면 자물쇠 경고가 뜬다.
VR=$(curl -s -o /dev/null -w '%{ssl_verify_result}' --max-time 15 "$BASE/" 2>/dev/null)
say "인증서 검증 결과: ${VR:-못 쟀음} (0 이면 통과)"
[ "${VR:-x}" = "0" ] && ok "와일드카드 인증서가 걸렸다" || bad "인증서가 안 걸렸다 — 제어판 → 보안 → 인증서 → 설정"

# ── 3. 설정 파일 ──────────────────────────────────────────────────────
printf '\n== 3. 설정 파일\n'
NEEDED='SSO_CLIENT_ID SSO_ISSUER SSO_REDIRECT_URI SESSION_COOKIE_SECURE SESSION_HOURS SSO_CLIENT_SECRET AUTH_SESSION_SECRET SSO_TX_SECRET'
if [ -f "$ENVF" ]; then
  MISS=""
  for k in $NEEDED; do grep -qE "^${k}=.+" "$ENVF" || MISS="$MISS $k"; done
  if [ -z "$MISS" ]; then ok "$ENVF 에 여덟이 다 있다"
  else bad "$ENVF 에 빠졌다:$MISS  → --init 으로 만드세요"; fi
  DUP=$(grep -oE '^[A-Z_]+' "$ENVF" 2>/dev/null | sort | uniq -d | tr '\n' ' ')
  [ -z "$DUP" ] && ok "겹친 이름이 없다" || bad "이름이 겹쳤다: $DUP (아래 줄이 이긴다)"
  P=$(ls -l "$ENVF" | awk '{print $1}')
  printf '%s' "$P" | grep -q '^-rw-------' && ok "다른 사람은 못 읽는다 (600)" || bad "모드가 $P 다 — 600 이어야 한다"
else
  hm "$ENVF 가 아직 없다 — --init 이 만든다"
fi

# ── 4. 이미지 ─────────────────────────────────────────────────────────
printf '\n== 4. 이미지\n'
T=$IMGD/$TAR
if [ -f "$T" ]; then
  SZ=$(stat -c %s "$T" 2>/dev/null); M5=$(md5sum "$T" | awk '{print $1}')
  CFG=$(tar -xOf "$T" manifest.json 2>/dev/null | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 | sed 's|blobs/sha256/|sha256:|')
  say "$TAR — ${SZ}바이트 · md5 $M5"
  [ "$SZ"  = "$TAR_SIZE" ] && ok "크기가 구울 때와 같다" || bad "크기가 다르다 (${SZ} ≠ ${TAR_SIZE})"
  [ "$M5"  = "$TAR_MD5"  ] && ok "md5 가 같다"           || bad "md5 가 다르다 — 옮기다 깨졌다"
  [ "$CFG" = "$TAR_CFG"  ] && ok "지문이 같다"           || bad "지문이 다르다 (${CFG:-못 읽음})"
else
  bad "$TAR 가 없다: $T — 먼저 올리세요"
fi
"$DOCKER" image inspect "$TAG" >/dev/null 2>&1 && hm "$TAG 가 NAS 에 이미 있다" || ok "$TAG 는 아직 안 들여놨다"

# ── 5. 포털 등록 ──────────────────────────────────────────────────────
printf '\n== 5. 포털 등록\n'
N=$(pg "select count(*) from clients where client_id='$CLIENT_ID'")
if [ "${N:-0}" = "1" ]; then
  hm "$CLIENT_ID 가 이미 등록돼 있다 (--client 가 최신으로 맞춘다)"
  say "지금 값:"
  "$DOCKER" exec -i "$PGBOX" sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<SQL 2>/dev/null | sed 's/^/      /'
\pset border 2
\x on
select client_id, name, is_active, requires_grant, sort_order,
       launcher_url, redirect_uris, backchannel_logout_uri,
       left(client_secret_hash,12) as 해시앞, length(client_secret_hash) as 해시길이
from clients where client_id = '$CLIENT_ID';
SQL
else
  ok "$CLIENT_ID 가 아직 없다 (--client 가 넣는다)"
  say "지금 등록된 것들 (sort_order 를 보고 $SORT 이 맞는지 정하세요):"
  "$DOCKER" exec -i "$PGBOX" sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL' 2>/dev/null | sed 's/^/      /'
\pset border 2
select client_id, sort_order, requires_grant, launcher_url from clients order by sort_order, client_id;
SQL
fi

# ── 6. 승인함 주소가 포털에 적혔나 ────────────────────────────────────
printf '\n== 6. 포털의 APPROVAL_INBOX_URL\n'
if grep -qE "^APPROVAL_INBOX_URL=.+" "$AUTHENV" 2>/dev/null; then
  ok "적혀 있다 (메일에 주소 줄이 생긴다)"
else
  hm "아직 없다 — 메일은 나가고 **주소 줄만** 빠진다. --inbox-url 이 넣는다"
fi

if [ "$MODE" = check ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.** 다음: --init → --client → --place → --inbox-url"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ══ --init : 설정 파일을 만든다 ═══════════════════════════════════════
if [ "$MODE" = init ]; then
  printf '\n== 7. 설정 파일을 만든다\n'
  if [ -f "$ENVF" ]; then
    printf '%s\n' "🔵 $ENVF 가 이미 있다. **아무것도 안 한다.**"
    printf '%s\n' "   겹쳐 넣으면 같은 이름이 두 줄이 되고 **아래가 이긴다.**"
    printf '%s\n' "   다시 만들려면 먼저 그 파일을 치우세요."
    exit 0
  fi
  S1=$(mkpass); S2=$(mkpass); S3=$(mkpass)
  for v in "$S1" "$S2" "$S3"; do
    [ "${#v}" -eq 48 ] || { printf '🔴 비밀값을 못 만들었다(길이 %s). 알려 주세요.\n' "${#v}"; exit 1; }
  done
  # 🔴 셋이 서로 달라야 한다. 앱이 시작할 때 그것을 보고 던진다.
  if [ "$S1" = "$S2" ] || [ "$S2" = "$S3" ] || [ "$S1" = "$S3" ]; then
    printf '🔴 만든 값 중 둘이 같다. 다시 돌려 주세요.\n'; exit 1
  fi
  mkdir -p "$ENVD"
  umask 077
  {
    printf '# DSS 통합 승인함 — 운영 설정 (38-approvals.sh --init 이 만들었다 %s)\n' "$STAMP"
    printf '#\n'
    printf '# 🔴 이 파일에만 평문이 있다. 채팅·로그·git 에 적지 않는다.\n'
    printf '# 🔴 DATABASE_URL 은 없다 — 이 집에는 표가 하나도 없다.\n'
    printf '# 🔴 PORT 도 안 적는다 — 이미지가 ENV PORT=%s 로 들고 있다.\n' "$CPORT"
    printf '\n'
    printf 'SSO_CLIENT_ID=%s\n' "$CLIENT_ID"
    printf 'SSO_ISSUER=%s\n' "$ISSUER"
    printf 'SSO_REDIRECT_URI=%s/api/auth/sso/callback\n' "$BASE"
    printf 'SESSION_COOKIE_SECURE=true\n'
    printf 'SESSION_HOURS=8\n'
    printf '\n'
    printf 'SSO_CLIENT_SECRET=%s\n' "$S1"
    printf 'AUTH_SESSION_SECRET=%s\n' "$S2"
    printf 'SSO_TX_SECRET=%s\n' "$S3"
  } > "$ENVF"
  S1=; S2=; S3=
  chown root:root "$ENVF"; chmod 600 "$ENVF"
  ok "만들었다 ($(wc -l < "$ENVF")줄)"
  # 🔴 되읽어 확인한다. chmod 를 불렀다는 것과 그렇게 됐다는 것은 다르다.
  say "주인 $(ls -l "$ENVF" | awk '{print $3":"$4}') · 모드 $(ls -l "$ENVF" | awk '{print $1}')"
  ls -l "$ENVF" | awk '{print $1}' | grep -q '^-rw-------' && ok "600 이다" || bad "600 이 아니다"
  printf '    들어간 이름:\n'
  for k in $NEEDED; do
    n=$(grep -cE "^${k}=.+" "$ENVF")
    [ "$n" = "1" ] && printf '      ✓ %s\n' "$k" || bad "$k 가 ${n}줄이다"
  done
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "✅ 만들었다. **평문은 한 번도 안 찍혔다.** 다음: --client"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ══ --client : 포털에 등록한다 ════════════════════════════════════════
if [ "$MODE" = client ]; then
  printf '\n== 7. 포털에 등록한다\n'
  [ -r "$ENVF" ] || { printf '🔴 %s 를 못 읽는다. 먼저 --init 하세요.\n' "$ENVF"; exit 1; }
  SECRET=$(sed -n 's/^SSO_CLIENT_SECRET=//p' "$ENVF" | head -1)
  case "$SECRET" in
    '') printf '🔴 SSO_CLIENT_SECRET 이 비어 있다.\n'; exit 1 ;;
    '"'*|"'"*) printf '🔴 SSO_CLIENT_SECRET 이 따옴표로 시작한다. 따옴표를 빼세요.\n'; exit 1 ;;
  esac
  HASH=$(printf '%s' "$SECRET" | sha256_of)
  SECRET=
  [ "${#HASH}" = 64 ] || { printf '🔴 해시가 64자가 아니다 (%s자).\n' "${#HASH}"; exit 1; }
  case "$HASH" in *[!0-9a-f]*) printf '🔴 해시에 16진수가 아닌 글자가 있다.\n'; exit 1 ;; esac
  ok "해시 모양 확인 — 64자 소문자 hex (평문은 안 찍는다)"

  # 🔴 아이콘을 셸에 글자로 적지 않는다 — 터미널·파일 인코딩에서 깨진다.
  #    chr(128229) = 📥 (받은 편지함).
  "$DOCKER" exec -i "$PGBOX" sh -c 'psql -U "$POSTGRES_USER" -d dss_auth -v ON_ERROR_STOP=1' <<SQL || { bad "등록 실패"; exit 1; }
insert into clients (
  client_id, name, description,
  client_secret_hash, redirect_uris,
  launcher_url, launcher_icon, sort_order,
  requires_grant, is_active, available_roles,
  backchannel_logout_uri
) values (
  '$CLIENT_ID',
  'DSS 통합 승인함',
  '여러 시스템의 결재 대기 건을 한자리에 모아 본다',
  '$HASH',
  array['$BASE/api/auth/sso/callback'],
  '$BASE/',
  chr(128229),
  $SORT,
  true,
  true,
  '{}'::text[],
  '$BASE/api/auth/sso/backchannel-logout'
)
on conflict (client_id) do update set
  name                   = excluded.name,
  description            = excluded.description,
  client_secret_hash     = excluded.client_secret_hash,
  redirect_uris          = excluded.redirect_uris,
  launcher_url           = excluded.launcher_url,
  launcher_icon          = excluded.launcher_icon,
  sort_order             = excluded.sort_order,
  requires_grant         = excluded.requires_grant,
  is_active              = excluded.is_active,
  available_roles        = excluded.available_roles,
  backchannel_logout_uri = excluded.backchannel_logout_uri,
  updated_at             = now();
SQL
  ok "넣었다"

  printf '\n    ── 되읽어 확인\n'
  "$DOCKER" exec -i "$PGBOX" sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<SQL 2>/dev/null | sed 's/^/      /'
\pset border 2
\x on
select client_id, name, is_active, requires_grant, sort_order,
       launcher_url, redirect_uris, backchannel_logout_uri, available_roles,
       left(client_secret_hash,12) as 해시앞, length(client_secret_hash) as 해시길이
from clients where client_id = '$CLIENT_ID';
SQL
  # 🔴 값으로 못 박는다. 화면의 글자는 터미널 글꼴에 따라 거짓말을 한다.
  R=$(pg "select case when redirect_uris[1]='$BASE/api/auth/sso/callback' then 'ok' else 'no' end from clients where client_id='$CLIENT_ID'")
  [ "$R" = "ok" ] && ok "콜백 주소가 글자까지 맞다" || bad "콜백 주소가 다르다 — 포털은 글자 단위로 대조한다"
  B=$(pg "select case when backchannel_logout_uri='$BASE/api/auth/sso/backchannel-logout' then 'ok' else 'no' end from clients where client_id='$CLIENT_ID'")
  [ "$B" = "ok" ] && ok "백채널 주소가 맞다" || bad "백채널 주소가 다르다"
  # 🔴 아이콘을 **코드값으로** 되읽는다. 네모로 보이는 것이 깨진 것인지 글꼴 탓인지 눈으로는 못 가른다.
  IC=$(pg "select upper(to_hex(ascii(launcher_icon))) from clients where client_id='$CLIENT_ID'")
  say "아이콘 코드포인트: ${IC:-못 읽음} (1F4E5 면 받은편지함)"
  [ "$IC" = "1F4E5" ] && ok "아이콘이 제대로 들어갔다" || bad "아이콘 코드가 ${IC:-?} 다"

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$FAIL" = 0 ]; then
    printf '%s\n' "✅ 등록했다. 다음: --place"
    printf '%s\n' "🔴 **등록만으로는 아무도 못 들어간다** — requires_grant 가 참이다."
    printf '%s\n' "   포털 관리 화면에서 **쓸 사람을 넣어야** 첫 사람이 들어온다."
  fi
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ══ --place : 이미지 + compose 블록 + 띄우기 ══════════════════════════
if [ "$MODE" = place ]; then
  printf '\n== 7. 세운다\n'
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 하고 멈춘다.**\n'; exit 1; fi
  [ -f "$ENVF" ] || { printf '🔴 %s 가 없다. 먼저 --init 하세요.\n' "$ENVF"; exit 1; }
  N=$(pg "select count(*) from clients where client_id='$CLIENT_ID'")
  [ "${N:-0}" = "1" ] || { printf '🔴 포털에 아직 등록이 없다. 먼저 --client 하세요.\n'; exit 1; }

  # ── 7-ㄱ. 이미지 들여놓기 ──────────────────────────────────────────
  printf '\n    ── 이미지를 들여놓는다\n'
  if "$DOCKER" image inspect "$TAG" --format '{{.Id}}' 2>/dev/null | grep -q "$TAR_CFG"; then
    ok "$TAG 는 이미 있고 지문이 같다 (건너뜀)"
  else
    "$DOCKER" load -i "$IMGD/$TAR" 2>&1 | sed 's/^/      /'
    FULL=$("$DOCKER" image inspect "$TAG" --format '{{.Id}}' 2>/dev/null)
    [ "$FULL" = "$TAR_CFG" ] && ok "$TAG 가 올라왔고 지문이 tar 와 같다" || bad "지문이 다르다 (${FULL:-없음})"
  fi
  [ "$FAIL" = 0 ] || { printf '\n🔴 멈춘다.\n'; exit 1; }

  # ── 7-ㄴ. compose 에 블록을 더한다 ────────────────────────────────
  printf '\n    ── compose 에 블록을 더한다\n'
  if grep -qE "^  ${SVC}:" "$CF"; then
    ok "$SVC 가 이미 있다 (건너뜀)"
  else
    BK="$BKD/docker-compose.nas.yml.v35b-$STAMP"
    mkdir -p "$BKD"; cp -p "$CF" "$BK" || { bad "사본을 못 떴다"; exit 1; }
    chmod 644 "$BK"; ok "사본 $BK"
    L0=$(wc -l < "$CF")
    SVCS0=$("$DOCKER" compose -f "$CF" config --services 2>/dev/null | sort | tr '\n' ' ')
    # 🔴 파일 끝에 붙인다. 맨 끝 블록은 app-rf-trouble 이고 그 뒤는 주석뿐이다 —
    #    YAML 에서 주석은 블록을 끝내지 않으므로 2칸 들여쓰기면 services: 의
    #    자식이 된다. 남의 블록을 가를 일이 없어 이 자리가 가장 안전하다.
    cat >> "$CF" <<BLOCK

  # ══ 통합 승인함 — 열째 사이트 (2026-10-24, 38-approvals.sh 가 더했다) ══
  #
  # 🔴 **DB 가 없다.** 표가 하나도 없는 유일한 Next.js 사이트다 — 세션은 서명
  #    쿠키, 로그아웃 기록은 프로세스 메모리다. 그래서 dss-data 망에 안 붙이고
  #    DATABASE_URL 도 안 넘긴다. tools-approvals 서비스도 없다.
  #    🔴 나중에 표가 생기면 그 셋을 **함께** 더해야 한다. 하나만 더하면
  #       마이그레이션이 0건으로 조용히 끝난다.
  #
  # 🔴 dss-edge 는 꼭 있어야 한다 — 로그인 토큰 교환이 login.dss21.co.kr 로
  #    나갔다 들어오고, 결재 목록을 세 시스템에 묻는 길도 그 망을 탄다.
  #    빠뜨리면 화면은 뜨는데 **로그인만** 안 된다.
  #
  # 🔴 호스트 포트가 **14000** 이다. 13900 이 아니다 — 13900 은 RF 이슈관리가
  #    쓰고 있다. 개발 PC 에서 이 집이 3900 을 써서 헷갈리기 쉬운 자리다.
  #
  # 🔴 볼륨이 없다. 쌓이는 파일이 없다는 보증이다.
  ${SVC}:
    image: ${TAG}
    container_name: ${CN}
    restart: unless-stopped
    logging: *logging
    networks: [dss-edge]
    ports: ["127.0.0.1:${HPORT}:${CPORT}"]
    env_file:
      - ./env/approvals.env
    environment:
      TZ: Asia/Seoul
      # PORT 는 적지 않는다 — 이미지가 ENV PORT=${CPORT} 로 들고 있다.
    deploy:
      resources:
        limits:
          memory: 512M
BLOCK
    L1=$(wc -l < "$CF")
    say "줄 수 $L0 → $L1 (늘어난 것 $((L1 - L0)))"
    [ "$((L1 - L0))" -gt 20 ] && ok "블록이 들어갔다" || bad "블록이 제대로 안 들어갔다"
    [ "$(grep -cE "^  ${SVC}:" "$CF")" = "1" ] && ok "$SVC 가 꼭 하나다" || bad "$SVC 가 여럿이다"
    "$DOCKER" compose -f "$CF" config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"
    SVCS1=$("$DOCKER" compose -f "$CF" config --services 2>/dev/null | sort | tr '\n' ' ')
    # 🔴 서비스 목록이 **우리 것 하나만** 늘었는가. 남의 블록을 건드리면 여기서 드러난다.
    ADDED=$(printf '%s\n' $SVCS1 | sort > /tmp/s1.$$; printf '%s\n' $SVCS0 | sort > /tmp/s0.$$; comm -13 /tmp/s0.$$ /tmp/s1.$$ | tr '\n' ' '; rm -f /tmp/s0.$$ /tmp/s1.$$)
    REMOVED=$(printf '%s\n' $SVCS1 | sort > /tmp/s1.$$; printf '%s\n' $SVCS0 | sort > /tmp/s0.$$; comm -23 /tmp/s0.$$ /tmp/s1.$$ | tr '\n' ' '; rm -f /tmp/s0.$$ /tmp/s1.$$)
    say "늘어난 서비스: ${ADDED:-없음} · 사라진 서비스: ${REMOVED:-없음}"
    [ "$(printf '%s' "$ADDED" | tr -d ' ')" = "$SVC" ] && ok "서비스가 $SVC 하나만 늘었다" || bad "늘어난 것이 '${ADDED}' 다"
    [ -z "$(printf '%s' "$REMOVED" | tr -d ' ')" ] && ok "사라진 서비스가 없다" || bad "사라진 것이 있다: $REMOVED"
    if [ "$FAIL" != 0 ]; then
      printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp -p "$BK" "$CF"
      say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
    fi
  fi

  # ── 7-ㄷ. 띄운다 ──────────────────────────────────────────────────
  printf '\n    ── 띄운다 (🔴 --no-deps · 이 하나만)\n'
  ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas up -d --no-deps "$SVC" ) 2>&1 | sed 's/^/      /'
  say "뜨는 것을 20초 기다린다…"; sleep 20

  printf '\n    ── 🔴 값으로 확인\n'
  ST=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  say "$CN — ${ST:-?} · 이미지 ${RUN:-?}"
  [ "$ST" = running ] && ok "$CN 가 돈다" || bad "$CN 가 안 돈다 (${ST:-못 찾음})"
  [ "$RUN" = "$TAG" ] && ok "$TAG 로 돈다" || bad "$RUN 로 돈다"
  LC=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$HPORT/" 2>/dev/null)
  say "127.0.0.1:$HPORT/ → ${LC:-없음}"
  printf '%s' "$LC" | grep -qE '200|30[127]' && ok "안에서 응답한다 ($LC)" || bad "안에서 응답이 ${LC:-없음}"
  # 🔴 **바깥 주소로도** 받아 본다. 안에서 되는 것과 프록시를 타고 되는 것은 다르다.
  OC=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$BASE/" 2>/dev/null)
  say "$BASE/ → ${OC:-없음}"
  printf '%s' "$OC" | grep -qE '200|30[127]' && ok "바깥 주소로도 선다 ($OC) — 502 를 벗어났다" || bad "바깥에서 ${OC:-없음} 이다"

  # 🔴 **안 건드린 아홉이 그대로 도는지** 센다.
  printf '\n    ── 안 건드린 것들 (그대로여야 한다)\n'
  for c in dss-auth dss-as dss-meters dss-po dss-board dss-improvements dss-leave dss-inventory dss-rf-trouble; do
    s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
    i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
    printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
    [ "$s" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
  done

  printf '\n    ── 최근 로그\n'
  "$DOCKER" logs --since 3m "$CN" 2>&1 | tail -12 | sed 's/^/      /'

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$FAIL" = 0 ]; then
    printf '%s\n' "✅ 섰다. 다음: --inbox-url"
    printf '%s\n' "🔴 **아직 아무도 못 들어간다** — 포털 관리 화면에서 쓸 사람을 넣으세요."
  fi
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ══ --inbox-url : 메일에 주소 줄을 생기게 한다 ════════════════════════
if [ "$MODE" = inboxurl ]; then
  printf '\n== 7. 포털에 승인함 주소를 적는다\n'
  [ -f "$AUTHENV" ] || { printf '🔴 %s 가 없다.\n' "$AUTHENV"; exit 1; }
  if grep -qE "^APPROVAL_INBOX_URL=.+" "$AUTHENV"; then
    printf '%s\n' "🔵 이미 적혀 있다. **아무것도 안 한다.**"
    say "$(grep -E '^APPROVAL_INBOX_URL=' "$AUTHENV" | head -1)"
    exit 0
  fi
  BK="$BKD/auth.env.v35b-$STAMP"
  mkdir -p "$BKD"; cp -p "$AUTHENV" "$BK" || { bad "사본을 못 떴다"; exit 1; }
  chmod 600 "$BK"; ok "사본 $BK"
  {
    printf '\n'
    printf '# 통합 승인함 주소 (2026-10-24, 38-approvals.sh) — 결재 메일에 이 줄이 실린다\n'
    printf 'APPROVAL_INBOX_URL=%s\n' "$BASE"
  } >> "$AUTHENV"
  chown root:root "$AUTHENV"; chmod 600 "$AUTHENV"
  n=$(grep -cE "^APPROVAL_INBOX_URL=.+" "$AUTHENV")
  [ "$n" = "1" ] && ok "꼭 한 줄 들어갔다" || bad "${n}줄이다 (아래가 이긴다)"
  say "$(grep -E '^APPROVAL_INBOX_URL=' "$AUTHENV" | head -1)"
  ls -l "$AUTHENV" | awk '{print $1}' | grep -q '^-rw-------' && ok "600 이다" || bad "600 이 아니다"

  printf '\n    ── 포털을 다시 띄운다 (🔴 이것 하나만)\n'
  ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas up -d --no-deps app-auth ) 2>&1 | sed 's/^/      /'
  say "뜨는 것을 20초 기다린다…"; sleep 20
  ST=$("$DOCKER" inspect -f '{{.State.Status}}' dss-auth 2>/dev/null)
  AC=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://127.0.0.1:13100/ 2>/dev/null)
  say "dss-auth — ${ST:-?} · 127.0.0.1:13100 → ${AC:-없음}"
  [ "$ST" = running ] && ok "포털이 돈다" || bad "포털이 안 돈다"
  printf '%s' "$AC" | grep -qE '200|30[127]' && ok "포털이 응답한다 ($AC)" || bad "포털 응답이 ${AC:-없음}"

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$FAIL" = 0 ]; then
    printf '%s\n' "✅ 끝났다. 이제 결재 메일에 승인함 주소 줄이 실린다."
    printf '%s\n' "🔴 **마지막은 눈이다** — 쓰는 분이 볼 곳:"
    printf '%s\n' "     · 포털 관리 화면에서 승인함을 **쓸 사람을 넣는다** (안 넣으면 아무도 못 들어간다)"
    printf '%s\n' "     · 앱 목록에 승인함 타일이 보이는가 · 눌러서 들어가지는가"
    printf '%s\n' "     · 결재를 하나 올리고 — 타일에 ● 새 결재 가 뜨는가 · 메일에 주소 줄이 생겼는가"
    printf '%s\n' "     · 승인함을 열면 점이 사라지는가"
  fi
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi
