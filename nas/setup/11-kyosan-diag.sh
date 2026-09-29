#!/bin/sh
# 연락서 폴더 둘을 컨테이너가 왜 못 읽는지 본다. 읽기만 한다 — 아무것도 안 바꾼다.
#   실행:  sh /volume1/dss/setup/11-kyosan-diag.sh

echo "══ 1. 호스트에서 본 폴더 ══"
ls -ld /volume1/dss /volume1/dss/kyosan-converted
ls -la /volume1/dss/kyosan-converted 2>&1 | head -4
echo
echo "── 견주어 볼 것: 잘 되는 as-attachments"
ls -ld /volume1/dss/as-attachments

echo
echo "══ 2. Synology ACL ══"
echo "── kyosan-converted"
synoacltool -get /volume1/dss/kyosan-converted 2>&1 | head -24
echo
echo "── as-attachments (잘 되는 쪽)"
synoacltool -get /volume1/dss/as-attachments 2>&1 | head -12

echo
echo "══ 3. 원본 공유폴더 ══"
ls -ld "/volume1/2_AS센터/1. 수리 관련/3. 연락서(활용)/2. 연락서"
synoacltool -get "/volume1/2_AS센터/1. 수리 관련/3. 연락서(활용)/2. 연락서" 2>&1 | head -16

echo
echo "══ 4. 컨테이너 안에서 본 것 ══"
cd /volume1/dss/deploy
/usr/local/bin/docker compose \
  -f /volume1/dss/deploy/docker-compose.nas.yml \
  --env-file /volume1/dss/deploy/.env.nas \
  --profile tools \
  run --rm --entrypoint sh tools-as -c '
    echo "-- 나는 누구인가"; id
    echo; echo "-- /kyosan-converted"; ls -ld /kyosan-converted 2>&1; ls /kyosan-converted 2>&1 | head -3
    echo; echo "-- /kyosan-src"; ls -ld /kyosan-src 2>&1; ls /kyosan-src 2>&1 | head -3
    echo; echo "-- /data (잘 되는 쪽)"; ls -ld /data 2>&1
  '
