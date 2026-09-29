#!/bin/sh
# 운영 포털에 휴가 시스템(dss-leave)을 등록한다. 🔴 사람이 sudo -i 로 돌린다.
#   실행:  sh /volume1/dss/setup/13-leave-client.sh
#
# 왜 화면이 아니라 SQL 인가 — 포털의 등록 명령은 tsx 로 도는 스크립트인데 NAS 의
# 포털 이미지에는 그것이 없다. A/S·계측기와 달리 포털에는 도구 이미지가 없다.
#
# 값은 개발 포털에 이미 있는 줄을 본으로 했다(2026-09-21 등록, 실측).
# 주소만 사내 도메인으로 바꾼다.
#
# 🔴 client_secret_hash 는 개발 PC 에서 만든 시크릿의 sha256 이다. 평문은
#    nas/env/leave.env 에만 있고 어디에도 찍지 않았다.
#
# 두 번 돌려도 안전하다 — 이미 있으면 주소·이름만 최신으로 맞춘다(UPSERT).

set -u
DOCKER=/usr/local/bin/docker
HASH=18783c276efd9d14ea4685468c330132ac72ba1bc4bb3abe583b7067013e219e

echo "══ 1. 지금 무엇이 있나 (읽기만) ══"
"$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL'
\pset border 2
select client_id, is_active, requires_grant, launcher_url
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
  'dss-leave',
  'DSS 휴가 관리',
  '휴가 신청 · 결재 · 남은 연차',
  '$HASH',
  array['https://leave.dss21.co.kr/api/auth/sso/callback'],
  'https://leave.dss21.co.kr/',
  '🌴',
  30,
  false,
  true,
  array['MEMBER','LEAVE_ADMIN'],
  'https://leave.dss21.co.kr/api/auth/sso/backchannel-logout'
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
echo "══ 3. 확인 (시크릿은 앞 12글자만) ══"
"$DOCKER" exec -i dss-pg-auth sh -c 'psql -U "$POSTGRES_USER" -d dss_auth' <<'SQL'
\pset border 2
\x on
select client_id, name, is_active, requires_grant,
       launcher_url, launcher_icon, sort_order,
       redirect_uris, backchannel_logout_uri, available_roles,
       left(client_secret_hash, 12) as 해시앞,
       length(client_secret_hash)   as 해시길이
from clients where client_id = 'dss-leave';
SQL

echo
echo "🔴 해시앞이 18783c276efd · 해시길이가 64 여야 합니다."
echo "🔴 requires_grant 가 f 라 전 직원이 바로 봅니다 — 명단(--grant)을 따로 넣지 않습니다."
echo "   (PO 는 t 라 명단이 필요했습니다. 휴가는 개선요청·계측기와 같습니다.)"
