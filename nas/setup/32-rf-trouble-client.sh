#!/bin/sh
# /volume1/dss/setup/32-rf-trouble-client.sh
#   운영 포털에 **RF 이슈관리**(client_id = dss-rf-trouble)를 등록한다.
#   🔴 사람이 sudo -i 로 돌린다.
#
#   실행:  sh /volume1/dss/setup/32-rf-trouble-client.sh                 등록만
#          sh /volume1/dss/setup/32-rf-trouble-client.sh --make-secret   비밀값을
#                                                        **그 자리에서 만들어**
#                                                        rf-trouble.env 에 넣고 등록
#
#   두 번 돌려도 안전하다 — 이미 있으면 주소·이름만 최신으로 맞춘다(UPSERT).
#
# ══ 🔴 베낀 본과 **다른 것 넷** ═══════════════════════════════════════
#   본은 27-inventory-client.sh 다. 그대로 베끼면 넷이 틀린다:
#
#   ① 🔴 **콜백 경로에 auth 한 겹이 없다.**
#        다른 여덟 : /api/**auth**/sso/callback
#        이 집     : /api/sso/callback
#      [저장소] dss-trouble/server.js 가 그 글자로 길을 열고 있다
#      (p === '/api/sso/callback'). 백채널도 /api/sso/backchannel-logout 이다
#      (tools/portal.js 의 LOGOUT_PATH).
#      🔴 포털은 **글자 단위로 대조한다. 와일드카드도 정규화도 없다**
#      ([저장소] dss-auth/src/lib/db/schema/clients.ts 의 그 주석).
#
#   ② 🔴 **열쇠가 저장소 이름과 다르다.** 저장소는 dss-trouble 인데
#      client_id 는 **dss-rf-trouble** 이다. [저장소] dss-auth 의
#      src/lib/notifications/sources.ts 에 그 글자로 박혀 있다 — 포털의 알림
#      종이 그 열쇠로 이 집을 부른다. 한 글자라도 다르면 **부르러 오지도
#      않는다**(오류가 아니라 「아무 일도 안 일어남」이라 아무도 신고하지 않는다).
#
#   ③ 🔴 **available_roles 가 비어 있다.** 이 시스템에는 역할 개념이 없다 —
#      [저장소] dss-trouble 전체에서 role 을 읽는 곳이 tools/sso.js 의
#      「신분 토큰에 적힌 역할을 그대로 받아 둔다」 한 줄뿐이고, 들여보낼지
#      말지를 그 값으로 가르는 곳이 없다.
#      🔴 그래서 **재고 관리와 반대다.** 재고 관리는 역할이 비면 거절했지만
#      (27-inventory-client.sh 의 그 상자), 이 집은 **역할 없이도 들어온다.**
#      [저장소] dss-auth 의 clients.ts 가 「비어 있으면 그 시스템은 역할을
#      쓰지 않는다는 뜻이고, 관리 화면은 권한 있음/없음만 묻는다」고 적고 있다.
#
#   ④ 🔴 **들어오는 길이 이것 하나뿐이다.**
#      [저장소] dss-trouble 2026-10-21 커밋 9a52287 이 팀 공용 비밀번호 길을
#      코드에서 걷어냈다. 비상구가 없다 — **포털이 멈추면 아무도 못 들어온다.**
#      그리고 requires_grant 가 **참**이므로(2026-10-22 쓰는 분 결정)
#      🔴 **이 스크립트만으로는 아무도 못 들어간다.** 포털 관리 화면에서
#      사람을 넣어야 첫 사람이 들어온다.
#
# ══ 🔴 비밀값을 이 파일에 박지 않는다 ═════════════════════════════════
#   넣는 길 둘. 둘 다 **평문은 화면에 한 번도 안 찍힌다.**
#
#   ㄱ) --make-secret   이 스크립트가 그 자리에서 만들어
#                       /volume1/dss/deploy/env/rf-trouble.env 의
#                       SSO_CLIENT_SECRET= 줄에 넣고, sha256 만 포털에 넣는다.
#                       🔴 평문은 그 파일(root 600) 한 곳에만 남는다.
#   ㄴ) 사람이 만든 값  rf-trouble.env 에 먼저 적어 두고 이 스크립트를 인자
#                       없이 돌린다. 해시는 그 값에서 뽑는다.
#
#   🔴 어느 쪽이든 **채팅·로그·이 파일에 평문을 적지 않는다.**
#      dss-trouble 은 **공개 저장소**다.
#
# ══ 🔴 아이콘을 셸에 글자로 적지 않는다 ═══════════════════════════════
#   launcher_icon 은 U+1F4E1 이다. 그 글자를 이 파일에 그대로 적으면 DSM
#   터미널과 전송 과정에서 깨진다(바이트가 바뀌어도 오류가 안 난다 — 포털
#   타일에 네모가 뜨고서야 안다). 그래서 **SQL 쪽에서 코드포인트로 만든다**:
#     chr(128225)  =  16진 1F4E1  =  U+1F4E1
#   넣은 뒤 to_hex(ascii(...)) 로 **코드값을 되읽어** 확인한다.
#
# ══ 🔴 이 파일을 NAS 로 옮기는 법 ═════════════════════════════════════
#   DSM 터미널은 긴 명령을 잘라 먹는다. 파일로 올리고 md5 를 맞춘다.
#     (PowerShell) scp -O 32-rf-trouble-client.sh dss-nas:/volume1/dss/setup/
#     (PowerShell) Get-FileHash -Algorithm MD5 .\32-rf-trouble-client.sh
#     (NAS)        md5sum /volume1/dss/setup/32-rf-trouble-client.sh
#
# ══ 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ═══════════════════════
#   백틱 0개 · 읽기 전용 자리의 콜론-꺾쇠 0군데. 빈 파일은 touch 로 만든다.

set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DOCKER=/usr/local/bin/docker
PGBOX=dss-pg-auth
CLIENT_ID=dss-rf-trouble
BASE=https://issues.dss21.co.kr
ENVF=/volume1/dss/deploy/env/rf-trouble.env
HASH_FILE=/volume1/dss/setup/incoming/rf-trouble-client-hash.txt
SORT=60     # [설문] 재고 관리가 50 이다. 아홉째라 60 을 쓴다. 1절이 지금 값을 찍는다.

# 🔴 여기에 sha256 64자(소문자 hex)를 적을 수도 있다. 평문이 아니다.
#    비워 두는 것이 **기본**이다 — 아래 세 길 중 하나로 채워진다.
HASH=

MODE=register
while [ "$#" -gt 0 ]; do
  case "$1" in
    --make-secret) MODE=make ;;
    -h|--help)
      echo "쓰는 법:"
      echo "  sh $0                 rf-trouble.env 의 값에서 해시를 뽑아 등록합니다"
      echo "  sh $0 --make-secret   🔴 비밀값을 새로 만들어 넣고 등록합니다"
      exit 0 ;;
    *) echo "모르는 인자: $1"; exit 2 ;;
  esac
  shift
done

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
[ -x "$DOCKER" ] || { echo "🔴 docker 를 못 찾았습니다: $DOCKER"; exit 1; }
"$DOCKER" ps --format '{{.Names}}' 2>/dev/null | grep -qx "$PGBOX" \
  || { echo "🔴 $PGBOX 가 안 돌고 있습니다. **아무것도 바꾸지 않았습니다.**"; exit 1; }

# ── sha256 을 어떤 도구로 뽑을지 한 번만 정한다 ───────────────────────
sha256_of() { # 표준입력을 받아 hex 64자를 찍는다
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 | awk '{print $NF}'
  else
    echo ""
  fi
}

# ══ 0. 비밀값 — 만들거나(--make-secret) 읽는다. 🔴 평문은 안 찍는다 ═══
echo
echo "══ 0. 비밀값 ══"
if [ "$MODE" = make ]; then
  if [ ! -f "$ENVF" ]; then
    echo "🔴 $ENVF 가 없습니다. **아무것도 바꾸지 않았습니다.**"
    echo "   먼저:  bash /volume1/dss/setup/32-rf-trouble-deploy.sh --init"
    exit 1
  fi
  if command -v openssl >/dev/null 2>&1; then
    S=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | cut -c1-48)
  else
    S=$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 48)
  fi
  # 🔴 영문·숫자만 쓴다. 이 값은 HTTP 폼 본문으로도, env 파일로도 흐른다 —
  #    따옴표·등호·쉼표가 들어가면 어느 한쪽에서 조용히 잘린다.
  [ "${#S}" -eq 48 ] || { echo "🔴 만들지 못했습니다(길이 ${#S}). 알려 주세요."; exit 1; }
  cp -a "$ENVF" "$ENVF.bak-$(date +%Y%m%d-%H%M%S)" || exit 1
  echo "  · 먼저 사본을 떴습니다"
  # 같은 이름이 둘이면 **나중 것이 이긴다.** 있던 줄은 지우고 새로 붙인다.
  grep -vE '^[[:space:]]*(export[[:space:]]+)?SSO_CLIENT_SECRET=' "$ENVF" > "$ENVF.new" || exit 1
  printf 'SSO_CLIENT_SECRET=%s\n' "$S" >> "$ENVF.new" || exit 1
  chown root:root "$ENVF.new" && chmod 600 "$ENVF.new" && mv "$ENVF.new" "$ENVF" || exit 1
  HASH=$(printf '%s' "$S" | sha256_of)
  S=
  echo "  ✓ 새 비밀값을 만들어 rf-trouble.env 에 넣었습니다 (root 600 · 화면에 안 찍습니다)"
else
  if [ -z "$HASH" ] && [ -r "$HASH_FILE" ]; then
    HASH=$(tr -dc 'a-f0-9' < "$HASH_FILE" | cut -c1-64)
    [ -n "$HASH" ] && echo "  · 해시를 $HASH_FILE 에서 읽었습니다"
  fi
  if [ -z "$HASH" ] && [ -r "$ENVF" ]; then
    SECRET=$(sed -n 's/^[[:space:]]*\(export[[:space:]]*\)\?SSO_CLIENT_SECRET=//p' "$ENVF" | head -1)
    case "$SECRET" in
      '"'*|"'"*)
        echo "🔴 rf-trouble.env 의 SSO_CLIENT_SECRET 이 따옴표로 시작합니다."
        echo "   따옴표를 빼고 값만 적어 주세요. **아무것도 바꾸지 않았습니다.**"
        exit 1 ;;
    esac
    if [ -n "$SECRET" ]; then
      HASH=$(printf '%s' "$SECRET" | sha256_of)
      SECRET=
      echo "  · 해시를 rf-trouble.env 의 값에서 뽑았습니다 (값은 안 찍습니다)"
    fi
  fi
fi

if [ -z "$HASH" ]; then
  echo "🔴 client_secret_hash 를 구하지 못했습니다. **아무것도 바꾸지 않았습니다.**"
  echo
  echo "   길 셋 중 하나를 고르세요:"
  echo "     ① 🔴 이 자리에서 새로 만든다 (권합니다 — 평문이 화면에 안 찍힙니다)"
  echo "          sh $0 --make-secret"
  echo "     ② rf-trouble.env 의 SSO_CLIENT_SECRET= 줄에 값을 적고 다시 돌린다"
  echo "     ③ 해시(64자)만 적은 파일을 올린다:  $HASH_FILE"
  echo
  echo "   🔴 평문은 어디에도 적지 않습니다 — rf-trouble.env(root 600) 한 곳입니다."
  exit 1
fi
if [ "${#HASH}" != 64 ]; then
  echo "🔴 해시가 64자가 아닙니다 (${#HASH}자). sha256 hex 가 아닙니다."
  echo "   **아무것도 바꾸지 않았습니다.**"
  exit 1
fi
case "$HASH" in
  *[!0-9a-f]*)
    echo "🔴 해시에 16진수가 아닌 글자가 있습니다 (소문자 0-9a-f 만)."
    echo "   **아무것도 바꾸지 않았습니다.**"
    exit 1 ;;
esac
echo "  ✓ 해시 모양 확인 — 64자 · 소문자 hex (앞 12자만 뒤에서 찍습니다)"

echo
echo "══ 1. 지금 무엇이 있나 (읽기만) ══"
echo "   🔵 sort_order 를 보고 $SORT 이 맞는지 정하세요 (재고 관리가 50 입니다)."
"$DOCKER" exec -i "$PGBOX" sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL'
\pset border 2
select client_id, is_active, requires_grant, sort_order, launcher_url
from clients order by sort_order, client_id;
SQL

echo
echo "══ 2. 넣는다 (있으면 맞춘다) ══"
echo "   🔴 콜백이 /api/sso/callback 입니다 — 다른 여덟(/api/auth/sso/callback)과 다릅니다."
"$DOCKER" exec -i "$PGBOX" sh -c 'psql -U "$POSTGRES_USER" -d dss_auth -v ON_ERROR_STOP=1' <<SQL || exit 1
insert into clients (
  client_id, name, description,
  client_secret_hash,
  redirect_uris,
  launcher_url, launcher_icon, sort_order,
  requires_grant, is_active,
  available_roles,
  backchannel_logout_uri
) values (
  '$CLIENT_ID',
  'RF 이슈관리',
  'RF 기술이슈 · 고객 문의 이력 · 주간보고',
  '$HASH',
  array['$BASE/api/sso/callback'],
  '$BASE/',
  chr(128225),
  $SORT,
  true,
  true,
  '{}'::text[],
  '$BASE/api/sso/backchannel-logout'
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
echo "  ✓ 넣었다"

echo
echo "══ 3. 확인 (시크릿 해시는 앞 12글자만) ══"
"$DOCKER" exec -i "$PGBOX" sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL'
\pset border 2
\x on
select client_id, name, is_active, requires_grant,
       launcher_url, sort_order,
       redirect_uris, backchannel_logout_uri, available_roles,
       left(client_secret_hash, 12) as 해시앞,
       length(client_secret_hash)   as 해시길이
from clients where client_id = 'dss-rf-trouble';
SQL

echo
echo "══ 4. 🔴 아이콘을 **코드값으로** 되읽는다 (글자로 보지 않는다) ══"
echo "   터미널 글꼴이 없으면 네모로 보입니다 — 그래서 눈이 아니라 코드로 봅니다."
"$DOCKER" exec -i "$PGBOX" sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL'
\pset border 2
select length(launcher_icon)               as 글자수,
       upper(to_hex(ascii(launcher_icon))) as 코드포인트,
       octet_length(launcher_icon)         as 바이트
from clients where client_id = 'dss-rf-trouble';
SQL

echo
echo "══ 5. 🔴 포털의 해시와 앱의 평문이 **정말 짝인가** ══"
echo "   🔴 이 대조를 아무도 안 하면, 어긋나도 오류가 한 번도 안 납니다 —"
echo "      사람이 로그인을 눌러 봐야 「다녀왔는데 안 된다」로 드러납니다."
echo "   🔴 값은 한 글자도 찍지 않습니다. 해시 앞 12자만 맞대 봅니다."
DBH=$("$DOCKER" exec -i "$PGBOX" sh -c 'psql -U "$POSTGRES_USER" -d dss_auth -X -tAq' <<'SQL' 2>/dev/null | head -1 | tr -d ' \r'
select client_secret_hash from clients where client_id = 'dss-rf-trouble';
SQL
)
if [ ! -r "$ENVF" ]; then
  echo "  ? rf-trouble.env 를 아직 못 읽어 대조하지 못했습니다 (--init 전이면 정상입니다)"
elif [ -z "$DBH" ]; then
  echo "  ? 포털에서 해시를 못 읽어 대조하지 못했습니다"
else
  SECRET=$(sed -n 's/^[[:space:]]*\(export[[:space:]]*\)\?SSO_CLIENT_SECRET=//p' "$ENVF" | head -1)
  if [ -z "$SECRET" ]; then
    echo "  ? rf-trouble.env 의 SSO_CLIENT_SECRET 이 비어 있습니다 — 대조 못 했습니다"
    echo "    🔴 비어 있으면 앱은 로그인을 **꺼진 채로** 띄우고, 그러면 컨테이너가"
    echo "       제 안 127.0.0.1 에만 열어 바깥에서 아예 안 닿습니다."
  else
    EH=$(printf '%s' "$SECRET" | sha256_of)
    SECRET=
    if [ "$EH" = "$DBH" ]; then
      echo "  ✓ 🔴 **짝이 맞습니다** (해시 앞 12자: $(printf '%s' "$DBH" | cut -c1-12))"
    else
      echo "  ✗ 🔴 **어긋났습니다.** 포털 $(printf '%s' "$DBH" | cut -c1-12) · 앱 $(printf '%s' "$EH" | cut -c1-12)"
      echo "    둘 중 하나를 맞추세요. 가장 쉬운 길:  sh $0 --make-secret"
    fi
  fi
fi

echo
echo "══ 6. 🔴 명단 — 지금 이 시스템을 쓸 수 있는 사람 ══"
echo "   requires_grant 가 참이라 **여기 있는 사람만** 들어옵니다."
echo "   🔴 user_client_grants.client_id 는 글자가 아니라 clients.id(uuid)다 —"
echo "      글자로 비교하면 조용히 0건이 나온다. 그래서 clients 와 이어 본다."
echo "   🔵 🔴 **재고 관리와 반대로, 역할이 비어 있어도 들어옵니다.**"
echo "      이 시스템에는 역할 개념이 없습니다(available_roles 가 빈 표입니다)."
"$DOCKER" exec -i "$PGBOX" sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL'
\pset border 2
select coalesce(g.role, '(역할 없음 — 이 시스템에서는 맞습니다)') as 역할,
       count(*) as 사람수
from user_client_grants g
join clients c on c.id = g.client_id
where c.client_id = 'dss-rf-trouble'
group by 1 order by 1;
SQL

cat <<'NOTE'

🔴 봐 주실 것
   · 해시길이 64 · 주소 셋이 전부 https://issues.dss21.co.kr 로 시작
   · 🔴 redirect 가 /api/sso/callback — **auth 한 겹이 없습니다**
   · 🔴 백채널이 /api/sso/backchannel-logout
   · available_roles 가 **빈 표** ({}) — 이 시스템은 역할을 안 씁니다
   · 글자수 1 · 코드포인트 1F4E1 · 바이트 4
     (코드포인트가 1F4E1 이 아니면 포털 타일에 엉뚱한 그림이 뜹니다.)
   · 🔴 requires_grant 가 **t** — 명단에 있는 사람만 씁니다(2026-10-22 결정).

🔴 이어서 사람이 할 일 — **이것을 안 하면 아무도 못 들어갑니다**
   포털 관리 화면에서 쓸 사람을 넣으세요(역할은 묻지 않습니다).
   🔴 이 시스템에는 비상구가 **없습니다.** 팀 공용 비밀번호 길이
      2026-10-21 에 코드에서 걷혔습니다 — 포털이 유일한 길입니다.

   다음:  bash /volume1/dss/setup/32-rf-trouble-deploy.sh
NOTE
