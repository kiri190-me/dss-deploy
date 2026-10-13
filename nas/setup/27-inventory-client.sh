#!/bin/sh
# 운영 포털에 재고 관리(dss-inventory)를 등록한다. 🔴 사람이 sudo -i 로 돌린다.
#   실행:  sh /volume1/dss/setup/27-inventory-client.sh
#
# 왜 화면이 아니라 SQL 인가 — 포털의 등록 명령(npm run client:register)은 tsx 로
# 도는 스크립트인데 NAS 의 포털 이미지에는 그것이 없다. A/S·계측기와 달리
# 포털에는 도구 이미지가 없다. 13-leave-client.sh · 25-board-client.sh 가 같은
# 까닭으로 SQL 이다.
#
# 두 번 돌려도 안전하다 — 이미 있으면 주소·이름만 최신으로 맞춘다(UPSERT).
#
# ══ 🔴 requires_grant 가 **참**이다 — 앞의 넷과 반대다 ══════════════════
#
#   개선요청 · 휴가 · 게시판은 전 직원 공개(거짓)였다. 재고 관리는 **참**이다.
#   PO 에 이어 둘째다. 짐작이 아니라 코드에서 나온 결론이다:
#
#     · 이 시스템에는 **기본 역할이 없다.** 처음 로그인인데 role 클레임이
#       없으면 **거절**한다 (dss-inventory/src/lib/auth/users.ts —
#       "처음 로그인인데 role 클레임 없음" → no_role).
#     · role 클레임은 포털의 **user_client_grants.role** 에서만 나온다
#       (dss-auth/src/lib/oidc/id-token-payload.ts: if (claims.role) …).
#     · 그러므로 requires_grant 를 거짓으로 두면, 명단에 없는 전 직원이
#       포털은 통과하고 **앱에서 거절당한다.** 증상이 「로그인이 안 된다」
#       하나라서 전 직원에게 고장처럼 보인다.
#     · 전환일 절차서도 「쓸 사람 명단·역할(VIEWER/STAFF/ADMIN)을 포털에
#       등록」이라 적고 있다 (그 저장소 docs/전환일_절차서_2026-10-12.md 1절 7번).
#
#   🔴 그래서 **이 스크립트만으로는 아무도 못 들어간다.** 사람과 역할을
#      포털 관리 화면에서 넣어야 첫 사람이 들어온다. 그리고 재고 관리에는
#      게시판의 make:admin 같은 **비상구가 없다**(그 저장소 scripts/ 에 없다) —
#      포털이 유일한 길이다. 첫 사람(정영빈 ADMIN)을 반드시 먼저 넣으세요.
#
# ── 🔴 아이콘을 셸에 글자로 적지 않는다 ────────────────────────────────
#   launcher_icon 은 U+1F4E6 이다. 그 글자를 이 파일에 그대로 적으면 DSM
#   터미널과 전송 과정에서 깨진다(바이트가 바뀌어도 오류가 안 난다 — 포털
#   타일에 네모가 뜨고서야 안다). 그래서 **SQL 쪽에서 코드포인트로 만든다**:
#     chr(128230)  =  16진 1F4E6  =  U+1F4E6
#   넣은 뒤 4번이 to_hex(ascii(...)) 로 **코드값을 되읽어** 확인한다.
#
# ── 🔴 client_secret_hash 가 아직 비어 있다 ────────────────────────────
#   아래 HASH 가 비면 이 스크립트는 **아무것도 바꾸지 않고 멈춘다.**
#
#   채우는 길 둘 (둘 다 평문이 아니라 sha256 64자다):
#     ① Claude 가 이 파일의 HASH= 줄을 채워 다시 올린다
#     ② 스크립트는 그대로 두고 해시만 파일로 올린다:
#          /volume1/dss/setup/incoming/inventory-client-hash.txt
#
#   🔴 평문 시크릿은 개발 PC 의 nas/env/inventory.env 에만 있다. 여기에도,
#      채팅에도, 로그에도 적지 않는다.

set -u
DOCKER=/usr/local/bin/docker
CLIENT_ID=dss-inventory
BASE=https://inventory.dss21.co.kr
HASH_FILE=/volume1/dss/setup/incoming/inventory-client-hash.txt

# 🔴 여기에 sha256 64자(소문자 hex)를 적는다. 평문이 아니다.
HASH=

if [ -z "$HASH" ] && [ -r "$HASH_FILE" ]; then
  HASH=$(tr -dc 'a-f0-9' < "$HASH_FILE" | cut -c1-64)
  [ -n "$HASH" ] && echo "  · 해시를 $HASH_FILE 에서 읽었다"
fi

if [ -z "$HASH" ]; then
  echo "🔴 client_secret_hash 가 비어 있습니다. **아무것도 바꾸지 않았습니다.**"
  echo
  echo "   아직 운영용 클라이언트 시크릿을 발급하기 전입니다."
  echo "   🔴 개발용 시크릿을 그대로 쓰지 마세요 — 운영은 다른 값입니다"
  echo "      (dss-inventory/docs/전환일_절차서_2026-10-12.md 2-2절)."
  echo "   Claude 가 시크릿을 만들고 sha256 해시를 드리면, 둘 중 하나로 넣으세요:"
  echo
  echo "     ① 이 스크립트의 HASH= 줄이 채워진 판을 다시 올린다"
  echo "     ② 해시만 적은 파일을 올린다:"
  echo "        $HASH_FILE"
  echo
  echo "   🔴 평문 시크릿은 어디에도 적지 않습니다 — 해시(64자)만 옮깁니다."
  echo "      평문은 NAS 의 /volume1/dss/deploy/env/inventory.env (root 600) 한 곳."
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
echo "   🔵 sort_order 를 보고 50 이 맞는지 정하세요 (휴가 30 · 게시판 40)."
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
  'dss-inventory',
  'DSS 재고 관리',
  '부품 재고 · 입고 · 사용 · 반출 신청',
  '$HASH',
  array['$BASE/api/auth/sso/callback'],
  '$BASE/',
  chr(128230),
  50,
  true,
  true,
  array['VIEWER','STAFF','ADMIN'],
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
from clients where client_id = 'dss-inventory';
SQL

echo
echo "══ 4. 🔴 아이콘을 **코드값으로** 되읽는다 (글자로 보지 않는다) ══"
echo "   터미널 글꼴이 없으면 네모로 보입니다 — 그래서 눈이 아니라 코드로 봅니다."
"$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL'
\pset border 2
select length(launcher_icon)            as 글자수,
       upper(to_hex(ascii(launcher_icon))) as 코드포인트,
       octet_length(launcher_icon)      as 바이트
from clients where client_id = 'dss-inventory';
SQL

echo
echo "══ 5. 🔴 명단 — 지금 이 시스템을 쓸 수 있는 사람 ══"
echo "   requires_grant 가 참이라 **여기 있는 사람만** 들어옵니다."
echo "   🔴 user_client_grants.client_id 는 글자가 아니라 clients.id(uuid)다 —"
echo "      글자로 비교하면 조용히 0건이 나온다. 그래서 clients 와 이어 본다."
echo "   🔴 역할이 비어 있는 줄(role is null)은 **포털이 role 클레임을 아예 안**"
echo "      **싣는다** — 그 사람은 처음 로그인에서 재고 관리에 거절당한다."
"$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL'
\pset border 2
select coalesce(g.role, '(역할 없음 — 🔴 이 사람은 거절된다)') as 역할,
       count(*) as 사람수
from user_client_grants g
join clients c on c.id = g.client_id
where c.client_id = 'dss-inventory'
group by 1 order by 1;
SQL

echo
echo "🔴 봐 주실 것"
echo "   · 해시길이 64 · 주소 셋이 전부 $BASE 로 시작"
echo "   · redirect 가 /api/auth/sso/callback — 🔴 게시판(/api/auth/callback)과 다릅니다"
echo "   · 백채널이 /api/auth/sso/backchannel-logout"
echo "   · available_roles 가 VIEWER · STAFF · ADMIN"
echo "   · 글자수 1 · 코드포인트 1F4E6 · 바이트 4"
echo "     (코드포인트가 1F4E6 이 아니면 포털 타일에 엉뚱한 그림이 뜹니다.)"
echo "   · 🔴 requires_grant 가 **t** — 명단에 있는 사람만 씁니다(PO 와 같습니다)."
echo
echo "🔴 이어서 사람이 할 일 — **이것을 안 하면 아무도 못 들어갑니다**"
echo "   포털 관리 화면에서 쓸 사람과 역할을 넣으세요."
echo "   전환일에는 **정영빈 님 하나를 ADMIN 으로** 넣는 것으로 시작할 수 있습니다."
echo "   🔴 재고 관리에는 비상구(make:admin 류)가 **없습니다** — 포털이 유일한 길입니다."
echo
echo "   다음:  sh /volume1/dss/setup/27-inventory-check.sh"
