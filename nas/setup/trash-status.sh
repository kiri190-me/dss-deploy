#!/bin/sh
# 휴지통에 무엇이 얼마나 쌓였는지 본다. 🔴 읽기만 한다 — 한 글자도 안 지운다.
#   실행:  sh /volume1/dss/setup/trash-status.sh
#
# 왜 필요한가 (2026-09-29 실측)
#   15일 뒤 완전삭제는 코드가 다 있는데(purge:repair-cases · purge:flowcharts ·
#   purge:master-data) **어느 스케줄러에도 등록된 적이 없다.** 개발 PC 시절에
#   만든 래퍼가 run-nightly-purge.ps1 — PowerShell 이라 NAS 에서 못 쓴다.
#   화면은 「15일 뒤 자동 삭제」라고 말하는데 실제로는 안 지워지고 있다.
#   PO 휴지통도 같은 작업이 비우는 구조라 함께 영향을 받는다.

D=/usr/local/bin/docker

echo "══ 수리 건 · 진단 순서도 · 기준정보 휴지통 (dss_as) ══"
"$D" exec -i dss-pg-app sh -c 'psql -U "$POSTGRES_USER" -d dss_as' <<'SQL'
\pset border 2
select
  '수리 건'                                                        as 무엇,
  count(*) filter (where deleted_at is not null)                   as 휴지통,
  count(*) filter (where deleted_at < now() - interval '15 days')  as 기한지남
from repair_cases
union all
select
  '진단 순서도',
  count(*) filter (where deleted_at is not null),
  count(*) filter (where deleted_at < now() - interval '15 days')
from repair_case_flowcharts
union all
select
  '고객사',
  count(*) filter (where deleted_at is not null),
  count(*) filter (where deleted_at < now() - interval '15 days')
from customers
union all
select
  '제품 모델',
  count(*) filter (where deleted_at is not null),
  count(*) filter (where deleted_at < now() - interval '15 days')
from product_models;

-- 가장 오래 묵은 것이 며칠 됐나
select
  '가장 오래된 휴지통 항목' as 무엇,
  coalesce(max(extract(day from now() - deleted_at))::text, '없음') as 며칠전
from repair_cases
where deleted_at is not null;
SQL

echo
echo "🔴 기한지남 이 0 이 아니면 그만큼 지워졌어야 할 것이 남아 있습니다."
echo "   (운영 전환이 2026-09-14 라 그 뒤 지운 것은 아직 15일이 안 됐을 수 있습니다.)"
