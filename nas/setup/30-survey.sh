#!/bin/bash
# /volume1/dss/setup/30-survey.sh — 서른째 배포 준비: 운영 현황 재기 (2026-10-19)
#
# 🔵 **읽기만 한다.** select 와 ls 뿐이다. 컨테이너를 하나도 멈추지 않고,
#    지우거나 고치는 문장이 한 줄도 없다. 몇 번을 돌려도 안전하다.
#
# ── 🔴 1판이 틀린 자리 (2026-10-19, 29-deploy.sh 와 compose 를 읽고 바로잡음)
#   추측으로 적었다가 다섯 군데가 빗나갔다:
#     · env 폴더    /volume1/dss/env   → **/volume1/dss/deploy/env**
#     · 컨테이너    app-as             → **dss-as** (app-as 는 compose 의
#                                         서비스 이름, container_name 은 dss-as)
#     · 마이그레이션 __drizzle_migrations → **drizzle.__drizzle_migrations**
#     · compose     (몰랐다)           → **/volume1/dss/deploy/docker-compose.nas.yml**
#     · 🔴 양식 경로를 as.env 에서 찾았다 → **compose 의 environment: 절**에 있다.
#          그래서 1판 5번이 아무것도 못 찾았다. 이번 배포에서 새 네 줄을 더할
#          자리도 as.env 가 아니라 **compose** 다.
#
#   🔵 1판에서 이미 얻어 다시 안 재는 값 둘 —
#      컨테이너 열(모두 26시간 가동), 출하 완료 역할 분포(19·9·4, 개발의 22 와 다름).
#
# ── 이번에 알아야 하는 것 여섯 ────────────────────────────────────────
#   1 운영 compose 의 태그          (저장소 사본은 2.5 인데 NAS 는 2.7 로 보인다
#                                   — 사본이 낡았다. 믿을 것은 NAS 쪽이다)
#   2 운영 DB 에 적용된 마이그레이션 수
#   3 도는 이미지 안의 .sql 수       (2 와 같아야 정상)
#   4 🔴 양식 폴더의 실제 파일 목록  (새 네 장을 올릴 자리)
#   5 compose·env 에 이번 설정 줄이 이미 있는가
#   6 되돌릴 이미지가 남아 있는가
#
# ── 쓰는 법 (NAS, sudo 필요) ─────────────────────────────────────────
#     sudo bash /volume1/dss/setup/30-survey.sh
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail

DOCKER=/usr/local/bin/docker
D=/volume1/dss
CF=$D/deploy/docker-compose.nas.yml
ENVD=$D/deploy/env
AS_ENV=$ENVD/as.env
PO_ENV=$ENVD/po.env
TPLDIR=$D/as-templates
AS_DB=dss_as

line() { printf '%s\n' "────────────────────────────────────────────────────────"; }
sec() { printf '\n== %s\n' "$1"; }
# 29-deploy.sh 353줄의 qas() 를 그대로 가져왔다. 다만 오류를 숨기지 않는다
# (2>/dev/null 을 빼서, 못 물으면 못 물었다고 보이게 한다).
qas() { "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $AS_DB -Atc \"$1\"" 2>&1; }

printf '30-survey (2판) — 운영 현황   %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
line

# ── 1 ────────────────────────────────────────────────────────────────
sec "1. 운영 compose 가 말하는 태그"
if [ -f "$CF" ]; then
  grep -nE '^[[:space:]]*image:[[:space:]]*dss-' "$CF" | sed 's/^/    /'
else
  printf '    🔴 %s 가 없다\n' "$CF"
fi

# ── 2 ────────────────────────────────────────────────────────────────
sec "2. 운영 DB 에 적용된 마이그레이션 (A/S)"
printf '%s\n' "🔵 0116·0117 두 장을 올리면 이 수가 둘 늘어야 한다."
printf '  적용된 수: %s\n' "$(qas 'select count(*) from drizzle.__drizzle_migrations;' | head -1)"
printf '%s\n' "  ── 마지막 다섯 (언제 적용됐나)"
# 🔵 바깥을 큰따옴표로 묶어야 SQL 안에 작은따옴표를 쓸 수 있다.
#    (qas 는 받은 글자를 psql 의 -Atc 뒤에 큰따옴표로 감싸 넘긴다.)
qas "select id || ' · ' || to_timestamp(created_at/1000)::date from drizzle.__drizzle_migrations order by id desc limit 5;" | head -5 | sed 's/^/    /'

# ── 3 ────────────────────────────────────────────────────────────────
sec "3. 지금 도는 이미지 안의 drizzle .sql 개수"
printf '%s\n' "🔵 2번과 같아야 한다. 새 이미지에서는 둘 늘어야 한다."
"$DOCKER" exec dss-as sh -c 'ls /app/drizzle/*.sql 2>/dev/null | wc -l' 2>&1 | sed 's/^/  dss-as 안: /' | head -2

# ── 4 🔴 가장 중요 ───────────────────────────────────────────────────
sec "4. 🔴 양식 폴더 — 새 네 장을 올릴 자리"
printf '%s\n' "🔴 코드만 올리고 양식을 안 올리면 보고서 만들기가 통째로 멈춘다."
printf '  호스트 경로: %s\n' "$TPLDIR"
if [ -d "$TPLDIR" ]; then
  ls -la "$TPLDIR" | sed 's/^/    /'
else
  printf '    🔴 폴더가 없다\n'
fi
printf '%s\n' "  ── 컨테이너 안에서 같은 폴더(/templates)를 본다"
"$DOCKER" exec dss-as sh -c 'ls -la /templates 2>&1' 2>&1 | sed 's/^/    /' | head -16
printf '%s\n' "  ── 이번에 올릴 네 장이 이미 있는가"
for f in 검사보고서_매쳐.xlsx 검사보고서_제너레이터.xlsx 수리보고서_매쳐.xlsx 수리보고서_제너레이터.xlsx; do
  if [ -f "$TPLDIR/$f" ]; then
    printf '    있음  %s  (%s bytes)\n' "$f" "$(stat -c%s "$TPLDIR/$f" 2>/dev/null)"
  else
    printf '    없음  %s\n' "$f"
  fi
done

# ── 5 ────────────────────────────────────────────────────────────────
sec "5. 이번에 더할 설정 줄이 이미 있는가 (🔵 값은 한 글자도 안 찍는다)"
printf '%s\n' "  ── compose 의 environment: 절 (양식 경로가 사는 곳)"
if [ -f "$CF" ]; then
  for k in MATCHER_INSPECTION_REPORT_TEMPLATE_PATH GENERATOR_INSPECTION_REPORT_TEMPLATE_PATH \
           MATCHER_REPAIR_REPORT_TEMPLATE_PATH GENERATOR_REPAIR_REPORT_TEMPLATE_PATH \
           INSPECTION_REPORT_TEMPLATE_PATH REPAIR_REPORT_TEMPLATE_PATH; do
    n=$(grep -cE "^[[:space:]]*${k}:" "$CF")
    printf '     %-48s %s줄\n' "$k" "${n:-0}"
  done
fi
for spec in "$AS_ENV|AS_WRITE_TOKEN AS_API_TOKEN" "$PO_ENV|AS_WRITE_TOKEN AS_APP_BASE_URL INVENTORY_API_BASE_URL INVENTORY_API_TOKEN"; do
  f="${spec%%|*}"; keys="${spec#*|}"
  printf '  ── %s\n' "$f"
  if [ ! -f "$f" ]; then printf '     🔴 파일이 없다\n'; continue; fi
  for k in $keys; do
    n=$(grep -c "^${k}=" "$f")
    n=${n:-0}
    if [ "$n" = "0" ]; then
      printf '     %-48s 없음\n' "$k"
    else
      v=$(grep "^${k}=" "$f" | head -1 | sed "s/^${k}=//" | tr -d '\r')
      printf '     %-48s %s줄 · 값 길이 %s\n' "$k" "$n" "${#v}"
    fi
  done
done

# ── 6 ────────────────────────────────────────────────────────────────
sec "6. 되돌릴 자리 — NAS 에 남은 dss-as · dss-po 이미지"
"$DOCKER" images --format '{{.Repository}}:{{.Tag}}  {{.Size}}  {{.CreatedSince}}' 2>/dev/null \
  | grep -E '^dss-(as|po):' | sort | sed 's/^/  /'

line
printf '끝 — 이 출력을 그대로 복사해 주세요.\n'
