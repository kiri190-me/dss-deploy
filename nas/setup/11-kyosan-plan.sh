#!/bin/sh
# 연락서 469장 이식 — 계획만 본다. --apply 가 없으므로 한 글자도 쓰지 않는다.
# (2026-09-29 배포. DSM 의 ash 에 긴 명령을 붙여넣으면 줄이 잘려서 파일로 둔다.)
#
#   실행:  sh /volume1/dss/setup/11-kyosan-plan.sh
#
# 🔴 --conditions=react-server 가 없으면 모듈을 읽는 순간 던진다.

set -e
cd /volume1/dss/deploy

exec /usr/local/bin/docker compose \
  -f /volume1/dss/deploy/docker-compose.nas.yml \
  --env-file /volume1/dss/deploy/.env.nas \
  --profile tools \
  run --rm tools-as \
  node --conditions=react-server --import tsx scripts/import-kyosan-reports.ts \
    --dir /kyosan-src --dir /kyosan-converted
