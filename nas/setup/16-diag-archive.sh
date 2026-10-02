#!/bin/bash
# 16-diag-archive.sh — 열두째 배포 --check 의 ✗ 하나를 가린다. **읽기만 한다.**
#
# 증상: `--check` 가 「A/S · /customer-portal-archive 를 못 읽는다(EACCES)」로 멈춘다.
#
# 내 짐작: 그 검사는 **지금 도는 컨테이너**(dss-as = 1.8) 안을 들여다본다.
#          새 볼륨은 **새 compose 를 적용해야** 생긴다. 그러니 1.8 안에 있을 수가 없다 —
#          폴더 권한 문제가 아니라 **검사가 틀린 것**이다.
#
# 이 스크립트는 그 짐작이 맞는지만 본다. 아무것도 바꾸지 않는다.
#   ① 도는 컨테이너에 그 자리가 붙어 있나
#   ② 붙여서 띄우면 uid 1000 + users 그룹이 실제로 읽히나  ← 이것이 진짜 물음
#
# 쓰는 법:  sudo bash /volume1/dss/setup/16-diag-archive.sh

set -u
SRC="/volume1/2_AS센터/1. 수리 관련/7. 수리품 목록/3. 업체별 수리품현황"
IMG=dss-as:1.8

echo "════════════════════════════════════════════════════════"
echo " ① 지금 도는 dss-as 에 붙어 있는 자리"
echo "════════════════════════════════════════════════════════"
docker inspect dss-as --format '{{range .Mounts}}{{.Destination}}
{{end}}' 2>&1 | sed '/^$/d' | sed 's/^/   /'
echo
echo "   도는 이미지: $(docker inspect dss-as --format '{{.Config.Image}}' 2>&1)"
echo
if docker inspect dss-as --format '{{range .Mounts}}{{.Destination}}
{{end}}' 2>/dev/null | grep -qx "/customer-portal-archive"; then
  echo "   → 붙어 있다. 그렇다면 짐작이 틀렸다 — 진짜 권한 문제다."
else
  echo "   → **안 붙어 있다.** 새 compose 를 적용해야 생기는 자리다."
  echo "      즉 --check 의 그 ✗ 는 **검사가 틀린 것**이지 폴더 탓이 아니다."
fi

echo
echo "════════════════════════════════════════════════════════"
echo " ② 붙여서 띄우면 실제로 읽히나 (진짜 물음)"
echo "════════════════════════════════════════════════════════"
echo "   uid 1000 · users(100) 로, 읽기 전용으로 붙여 본다."
docker run --rm -u 1000:1000 --group-add 100 \
  -v "$SRC":/t:ro "$IMG" \
  sh -c 'echo "   id: $(id)"; if ls /t >/dev/null 2>&1; then echo "   READ  OK  (맨 위 칸 $(ls /t | wc -l) 개)"; ls /t | head -3 | sed "s/^/     · /"; else echo "   READ  FAIL"; fi' 2>&1 | sed 's/^/ /'

echo
echo "   (쓰기는 보지 않는다 — --go 가 할 일이다. 여기서는 아무것도 안 만든다.)"
echo
echo "════════════════════════════════════════════════════════"
echo " 이 출력을 그대로 Claude 에게 붙여 주세요."
echo "════════════════════════════════════════════════════════"
