#!/bin/sh
# 운영 포털에 사내 게시판(dss-board)을 등록한다. 🔴 사람이 sudo -i 로 돌린다.
#   실행:  sh /volume1/dss/setup/25-board-client.sh
#
# 왜 화면이 아니라 SQL 인가 — 포털의 등록 명령(npm run client:register)은 tsx 로
# 도는 스크립트인데 NAS 의 포털 이미지에는 그것이 없다. A/S·계측기와 달리
# 포털에는 도구 이미지가 없다. 13-leave-client.sh 가 같은 까닭으로 SQL 이다.
#
# 두 번 돌려도 안전하다 — 이미 있으면 주소·이름만 최신으로 맞춘다(UPSERT).
#
# ── 🔴 아이콘을 셸에 글자로 적지 않는다 ────────────────────────────────
#   launcher_icon 은 U+1FAA7 이다. 그 글자를 이 파일에 그대로 적으면 DSM
#   터미널과 전송 과정에서 깨진다(바이트가 바뀌어도 오류가 안 난다 — 포털
#   타일에 네모가 뜨고서야 안다). 그래서 **SQL 쪽에서 코드포인트로 만든다**:
#     chr(129703)  =  16진 1FAA7  =  U+1FAA7
#   넣은 뒤 3번이 to_hex(ascii(...)) 로 **코드값을 되읽어** 확인한다.
#
# ── 🔴 client_secret_hash 가 아직 비어 있다 ────────────────────────────
#   휴가(13-leave-client.sh)는 시크릿을 미리 발급해 둬서 해시가 박혀 있었다.
#   게시판은 **아직 발급 전**이다(점검표 1-①). 아래 HASH 가 비면 이 스크립트는
#   **아무것도 바꾸지 않고 멈춘다.**
#
#   채우는 길 둘 (둘 다 평문이 아니라 sha256 64자다):
#     ① Claude 가 이 파일의 HASH= 줄을 채워 다시 올린다
#     ② 스크립트는 그대로 두고 해시만 파일로 올린다:
#          /volume1/dss/setup/incoming/board-client-hash.txt
#
#   🔴 평문 시크릿은 개발 PC 의 nas/env/board.env 에만 있다. 여기에도,
#      채팅에도, 로그에도 적지 않는다.

set -u
DOCKER=/usr/local/bin/docker
CLIENT_ID=dss-board
BASE=https://board.dss21.co.kr
HASH_FILE=/volume1/dss/setup/incoming/board-client-hash.txt

# 🔴 여기에 sha256 64자(소문자 hex)를 적는다. 평문이 아니다.
HASH=6ceea5644ce6fb53d4d9868da87510637d3bc76eaa9464c679a6c6ee6f37255d

if [ -z "$HASH" ] && [ -r "$HASH_FILE" ]; then
  HASH=$(tr -dc 'a-f0-9' < "$HASH_FILE" | cut -c1-64)
  [ -n "$HASH" ] && echo "  · 해시를 $HASH_FILE 에서 읽었다"
fi

if [ -z "$HASH" ]; then
  echo "🔴 client_secret_hash 가 비어 있습니다. **아무것도 바꾸지 않았습니다.**"
  echo
  echo "   아직 클라이언트 시크릿을 발급하기 전입니다(점검표 1-①)."
  echo "   Claude 가 시크릿을 만들고 sha256 해시를 드리면, 둘 중 하나로 넣으세요:"
  echo
  echo "     ① 이 스크립트의 HASH= 줄이 채워진 판을 다시 올린다"
  echo "     ② 해시만 적은 파일을 올린다:"
  echo "        $HASH_FILE"
  echo
  echo "   🔴 평문 시크릿은 어디에도 적지 않습니다 — 해시(64자)만 옮깁니다."
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
echo "  ✓ 해시 모양 확인 — 64자 · 소문자 hex (값은 3번에서 앞 12자만 찍는다)"

echo
echo "══ 1. 지금 무엇이 있나 (읽기만) ══"
echo "   🔵 sort_order 를 보고 40 이 맞는지 정하세요 (휴가가 30 입니다)."
"$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL'
\pset border 2
select client_id, is_active, requires_grant, sort_order, launcher_url
from clients order by sort_order, client_id;
SQL

echo
echo "══ 2. 넣는다 (있으면 맞춘다) ══"
"$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth -v ON_ERROR_STOP=1' <<SQL || exit 1
insert into clients (
  client_id, name, description,
  client_secret_hash,
  redirect_uris,
  launcher_url, launcher_icon, sort_order,
  requires_grant, is_active,
  available_roles,
  backchannel_logout_uri
) values (
  'dss-board',
  'DSS 사내 게시판',
  '공지 · 자료 · 자유게시판',
  '$HASH',
  array['$BASE/api/auth/callback'],
  '$BASE/',
  chr(129703),
  40,
  false,
  true,
  array['MEMBER','ADMIN'],
  '$BASE/api/auth/backchannel-logout'
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
"$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL'
\pset border 2
\x on
select client_id, name, is_active, requires_grant,
       launcher_url, sort_order,
       redirect_uris, backchannel_logout_uri, available_roles,
       left(client_secret_hash, 12) as 해시앞,
       length(client_secret_hash)   as 해시길이
from clients where client_id = 'dss-board';
SQL

echo
echo "══ 4. 🔴 아이콘을 **코드값으로** 되읽는다 (글자로 보지 않는다) ══"
echo "   터미널 글꼴이 없으면 네모로 보입니다 — 그래서 눈이 아니라 코드로 봅니다."
"$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL'
\pset border 2
select length(launcher_icon)            as 글자수,
       upper(to_hex(ascii(launcher_icon))) as 코드포인트,
       octet_length(launcher_icon)      as 바이트
from clients where client_id = 'dss-board';
SQL

echo
echo "🔴 봐 주실 것"
echo "   · 해시길이 64 · 주소 셋이 전부 $BASE 로 시작"
echo "   · available_roles 가 MEMBER · ADMIN"
echo "   · 글자수 1 · 코드포인트 1FAA7 · 바이트 4"
echo "     (코드포인트가 1FAA7 이 아니면 포털 타일에 엉뚱한 그림이 뜹니다.)"
echo "   · requires_grant 가 f — 전 직원이 바로 봅니다. 명단을 따로 넣지 않습니다"
echo "     (개선요청 · 휴가와 같습니다. PO 만 t 라 명단이 필요했습니다.)"
