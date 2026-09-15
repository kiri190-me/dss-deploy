#!/bin/bash
# /volume1/dss/setup/04-https-cert.sh — dss21.co.kr 인증서를 받아 DSM 에 넣고, 갱신 작업을 제자리에 둔다
#
# ── 사람이 실행한다 (처음 한 번. 다시 돌려도 같은 결과) ──────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                          ← DSM 비밀번호. 한/영이 영문인지 먼저!
#   (NAS)         bash /volume1/dss/setup/04-https-cert.sh
#
# 중간에 두 가지를 묻는다 — Cloudflare 의 Zone ID(비밀 아님)와 API 토큰(화면에 안 보인다).
# 토큰은 채팅에 붙이지 않는다. 이 창에만 붙여 넣는다.
#
# ── 하는 일 ─────────────────────────────────────────────────────────────
#   1. 먼저 볼 것 — 네임서버가 Cloudflare 인가, login·as·meters 가 192.168.0.222 인가,
#      올라온 acme.sh 의 지문 (하나라도 틀리면 아무것도 바꾸지 않고 멈춘다)
#   2. acme.sh 3.1.4 를 /volume1/dss/acme 에 설치 — root 만 읽는다. 토큰이 여기 저장된다
#   3. 토큰 시험 — 그 도메인의 DNS 를 실제로 읽을 수 있는가
#   4. Let's Encrypt 에서 dss21.co.kr · *.dss21.co.kr (DNS 인증 — NAS 를 인터넷에 열지 않는다)
#   5. DSM 에 넣는다 (이름 "dss21.co.kr"). 임시 관리자를 만들어 넣고 바로 지운다
#   6. 갱신 작업 jobs/acme-renew.sh 를 제자리에 두고 한 번 돌린다
#
# 결과는 /volume1/dss/setup/logs/04-https-*.log. 토큰은 로그에 남지 않는다.
# 인증서가 이미 있고 30일 넘게 남았으면 3·4 를 건너뛴다(토큰을 묻지 않는다).
#
# ── 왜 컨테이너가 아니라 NAS 에 직접 까나 (결정 I) ──────────────────────
# DSM 에 인증서를 넣는 훅(synology_dsm)은 NAS 의 synouser 로 임시 관리자를 만들어
# 넣고 지운다(SYNO_USE_TEMP_ADMIN). 컨테이너에는 그 도구가 없어 DSM 관리자
# 비밀번호를 파일로 남겨 두어야 한다 — 그 파일이 곧 NAS 관리자 열쇠다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
A=$D/acme
DOMAIN=dss21.co.kr
HOSTS=(login as meters)
NAS_IP=192.168.0.222
VER=3.1.4
TGZ=$D/setup/acme.sh-$VER.tar.gz
TGZ_SHA=e5f8e187bbf5251e0cd8891f2622daab9850366bd17bea9f92c2fe2ee091fd32
RENEW_SRC=$D/setup/acme-renew.sh
RENEW_DST=$D/jobs/acme-renew.sh
CERT=$A/certs/$DOMAIN/fullchain.cer

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/04-https-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

PASS=0; FAIL=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }
# 공유기 DNS 를 거치지 않고 Cloudflare 에 직접 묻는다 — 여기서 보는 것은 영역 설정이다.
# 사내 PC 가 같은 답을 받는지(rebinding 차단)는 사람이 nslookup 으로 따로 본다.
doh()  { curl -s -m 8 -H 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=$1&type=$2" \
           | grep -o '"data":"[^"]*"' | cut -d'"' -f4; }
acme() { "$A/app/acme.sh" --home "$A/app" --config-home "$A/data" --cert-home "$A/certs" "$@"; }
installed() { [ -x "$A/app/acme.sh" ] && acme --version 2>/dev/null | grep -q "v$VER"; }
have_cert() { [ -s "$CERT" ] && openssl x509 -in "$CERT" -noout -checkend $((30 * 86400)) >/dev/null 2>&1; }
echo "DSS HTTPS 인증서 · $(date '+%F %T')"

# ════════════════════════════════════════════════════════════════════
step "1. 먼저 볼 것"
ns=$(doh "$DOMAIN" NS | tr '\n' ' ')
case "$ns" in
  *ns.cloudflare.com*) ok "네임서버 Cloudflare — $ns" ;;
  *) bad "네임서버가 아직 Cloudflare 가 아님: ${ns:-없음} (카페24에서 바꾼 뒤 최대 24시간)" ;;
esac
for h in "${HOSTS[@]}"; do
  ip=$(doh "$h.$DOMAIN" A | tr '\n' ' ' | sed 's/ $//')
  [ "$ip" = "$NAS_IP" ] && ok "$h.$DOMAIN → $ip" || bad "$h.$DOMAIN → ${ip:-없음} ($NAS_IP 여야 함)"
done
if installed; then ok "acme.sh $VER 이미 설치됨"
elif [ -s "$TGZ" ] && echo "$TGZ_SHA  $TGZ" | sha256sum -c --quiet; then ok "acme.sh-$VER.tar.gz 지문 일치"
else bad "acme.sh-$VER.tar.gz 가 없거나 지문이 다름"; fi
if [ -s "$RENEW_SRC" ] || [ -s "$RENEW_DST" ]; then ok "갱신 작업 파일"; else bad "acme-renew.sh 없음"; fi
[ "$FAIL" = 0 ] || stop "아무것도 바꾸지 않았습니다."

# ════════════════════════════════════════════════════════════════════
step "2. acme.sh 설치 — $A (root 만)"
mkdir -p "$A"
find "$A" -exec /usr/syno/bin/synoacltool -del {} \; >/dev/null 2>&1
chown root:root "$A"; chmod 700 "$A"
if installed; then ok "그대로 둔다"
else
  # /tmp 에 풀지 않는다 — DSM 의 /tmp 는 noexec 라 권한이 있어도 실행이 막힌다
  # (2026-09-15 첫 실행에서 "./acme.sh: Permission denied"). root 700 인 $A 안에서 푼다.
  src=$A/src
  rm -rf "$src"; mkdir -p "$src"
  tar -xzf "$TGZ" -C "$src"
  if (cd "$src/acme.sh-$VER" && ./acme.sh --install --home "$A/app" --config-home "$A/data" \
        --cert-home "$A/certs" --nocron --noprofile); then ok "acme.sh $VER 설치"
  else bad "설치 실패"; fi
  rm -rf "$src"
fi
# acme.sh 의 기본 발급처는 ZeroSSL 이다. 갱신도 같은 곳에서 하도록 기본값을 바꿔 둔다.
acme --set-default-ca --server letsencrypt >/dev/null && ok "발급처 Let's Encrypt" || bad "발급처 설정 실패"
chmod -R go-rwx "$A"
[ "$FAIL" = 0 ] || stop "설치에서 막혔습니다."

# ════════════════════════════════════════════════════════════════════
if have_cert; then
  step "3·4. 인증서 — 이미 있고 30일 넘게 남았다. 토큰을 묻지 않는다"
  ok "$(openssl x509 -in "$CERT" -noout -enddate)"
else
  step "3. Cloudflare 토큰"
  echo "  Cloudflare → $DOMAIN → 개요(Overview) 오른쪽 「API」 칸의 Zone ID 를 붙여 넣으세요 (비밀 아님)."
  read -r -p "  Zone ID: " zid
  echo "  API 토큰을 붙여 넣으세요. 화면에 보이지 않는 것이 정상입니다. 붙여 넣고 Enter."
  read -r -s -p "  토큰: " CF_Token; echo
  CF_Zone_ID=$(printf %s "$zid" | tr -cd 'a-f0-9')
  [ "${#CF_Zone_ID}" = 32 ] || { bad "Zone ID 는 32자리(0-9a-f)여야 함 — ${#CF_Zone_ID}자리"; stop "인증서를 받지 않았습니다."; }
  r=$(curl -s -m 15 -H "Authorization: Bearer $CF_Token" \
        "https://api.cloudflare.com/client/v4/zones/$CF_Zone_ID/dns_records?per_page=50")
  if printf %s "$r" | grep -q '"success":true'; then
    ok "토큰으로 $DOMAIN 의 DNS 를 읽었다"
  else
    bad "토큰이 그 도메인의 DNS 를 읽지 못함 — $(printf %s "$r" | grep -o '"message":"[^"]*"' | head -1)"
    unset CF_Token; stop "인증서를 받지 않았습니다. 토큰 권한(Zone · DNS · Edit, 영역 $DOMAIN)을 보세요."
  fi

  step "4. 인증서 발급 — Let's Encrypt · DNS 인증 (1~3분)"
  # Zone ID 를 함께 주면 acme.sh 가 토큰을 이 도메인 설정($A/certs, root 700)에 저장한다 — 갱신 때 쓴다.
  export CF_Token CF_Zone_ID
  acme --issue --server letsencrypt --dns dns_cf -d "$DOMAIN" -d "*.$DOMAIN" --keylength 2048
  rc=$?
  unset CF_Token CF_Zone_ID
  case $rc in
    0) ok "발급" ;;
    2) ok "이미 유효한 인증서 — 건너뜀" ;;
    *) bad "발급 실패 (종료 코드 $rc)" ;;
  esac
  [ -s "$CERT" ] && ok "$(openssl x509 -in "$CERT" -noout -enddate)" || bad "인증서 파일 없음: $CERT"
  [ "$FAIL" = 0 ] || stop "DSM 에는 아무것도 넣지 않았습니다."
fi
openssl x509 -in "$CERT" -noout -ext subjectAltName 2>/dev/null | sed -n '2p' | sed 's/^ */  이름: /'

# ════════════════════════════════════════════════════════════════════
step "5. DSM 에 넣기 — 이름 \"$DOMAIN\" (임시 관리자를 만들어 넣고 지운다)"
# 이 설정은 acme.sh 가 저장해 두고, 갱신할 때마다 같은 인증서를 바꿔 끼운다.
export SYNO_USE_TEMP_ADMIN=1 SYNO_CREATE=1 SYNO_CERTIFICATE="$DOMAIN"
if acme --deploy -d "$DOMAIN" --deploy-hook synology_dsm; then ok "DSM 에 넣음"; else bad "DSM 에 넣지 못함"; fi
if grep -q "\"$DOMAIN\"" /usr/syno/etc/certificate/_archive/INFO 2>/dev/null; then
  ok "DSM 인증서 목록에 \"$DOMAIN\" 있음"
else bad "DSM 인증서 목록에서 \"$DOMAIN\" 을 찾지 못함"; fi

# ════════════════════════════════════════════════════════════════════
step "6. 갱신 작업"
# root 가 매일 돌리는 파일이라 root 만 고칠 수 있게 둔다 (03-install-backup.sh 와 같은 이유).
mkdir -p "$D/jobs"
if [ -s "$RENEW_SRC" ]; then
  bash -n "$RENEW_SRC" || stop "acme-renew.sh 문법 오류."
  find "$D/jobs" -exec /usr/syno/bin/synoacltool -del {} \; >/dev/null 2>&1
  cp "$RENEW_SRC" "$RENEW_DST" && rm -f "$RENEW_SRC"
fi
chown root:root "$RENEW_DST"; chmod 700 "$RENEW_DST"
ok "제자리: $RENEW_DST ($(stat -c '%U:%G %a' "$RENEW_DST"))"
if bash "$RENEW_DST" >/dev/null 2>&1; then ok "한 번 돌려 봄 — 정상 (기록: logs/acme-*.log)"
else bad "갱신 작업이 실패를 돌려줌 — logs/acme-*.log 를 볼 것"; fi

# ════════════════════════════════════════════════════════════════════
echo
echo "── 결과 ✓ $PASS · ✗ $FAIL"
if [ "$FAIL" = 0 ]; then
  echo "→ 끝났습니다. Claude 에게 '끝났어'라고 알려 주세요."
  echo "  다음은 DSM 화면 두 가지 — 작업 스케줄러에 갱신 작업, 리버스 프록시 HTTPS 규칙 셋 (순서는 Claude 가 안내한다)"
else
  echo "→ ✗ 줄이 있습니다. Claude 에게 알려 주세요 (로그: $LOG)"; exit 1
fi
