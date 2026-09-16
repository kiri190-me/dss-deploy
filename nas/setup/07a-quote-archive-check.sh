#!/bin/bash
# /volume1/dss/setup/07a-quote-archive-check.sh — 견적서 공유폴더에 컨테이너가 쓸 수 있게 하는 길 찾기
#
#   (NAS · sudo -i)  bash /volume1/dss/setup/07a-quote-archive-check.sh
#
# 07-deploy.sh 2단계가 "루트에 쓸 수 없다"로 멈춰서 그 까닭을 가린다.
# **아무것도 바꾸지 않는다.** 임시 파일을 만들었다 지우기만 하고, ACL 은 읽기만 한다.
#
# ── 왜 못 쓰나 (2026-09-16 확인) ────────────────────────────────────────
# 그 폴더는 /volume1/dss 와 달리 **Synology ACL 이 사람 이름으로 허용**하는 곳이다.
# POSIX 모드가 777 로 보여도 실제 판정은 ACL 이 한다. 컨테이너의 node(uid 1000 ·
# gid 1000)는 그 목록에 없다 — DSM 사용자가 아니기 때문이다.
#
# 목록에 `group:users:allow:rwxpdDaARWc--` 가 있다. 컨테이너에 **gid 100(users)** 을
# 곁들이면(`group_add`) 그 줄에 걸릴 수 있다. uid 는 1000 그대로라 /data ·
# /templates 의 주인은 바뀌지 않는다.
#
# ⚠️ ACL 을 걷지 않는다. 걷으면 직원의 탐색기 접근이 끊긴다.
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DOCKER=/usr/local/bin/docker
IMG=dss-as:1.2
P="/volume1/3_견적-세금계산서-국내발주/4. DSS 내자견적서 (활용)"
Y=$(ls -1d "$P"/*"$(date +%Y)"* 2>/dev/null | head -1)

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }

echo "══ 컨테이너가 누구로 도는가"
"$DOCKER" run --rm "$IMG" sh -c 'echo "  uid=$(id -u) gid=$(id -g) groups=$(id -G)"'

echo
echo "══ 시험 — 같은 폴더에 파일 하나 만들었다 지우기"
try() { # 이름 추가인자...
  local name=$1; shift
  local out
  out=$("$DOCKER" run --rm "$@" -v "$P:/quote-archive" "$IMG" \
        sh -c 'set -e; t=/quote-archive/.dss-write-test; : > "$t"; rm -f "$t"; d=/quote-archive/.dss-dir-test; mkdir "$d"; rmdir "$d"; echo OK' 2>&1)
  if [ "$out" = OK ]; then
    echo "  ✓ $name"
    return 0
  fi
  echo "  ✗ $name"
  echo "$out" | sed 's/^/      /' | head -4
  return 1
}

try "지금 그대로 (uid 1000 · gid 1000)"
BASE=$?
try "gid 100(users) 곁들임 — group_add" --group-add 100
ADD=$?
try "gid 100 을 주 그룹으로 — user 1000:100" --user 1000:100
MAIN=$?

if [ -n "$Y" ]; then
  echo
  echo "══ 올해 폴더($(basename "$Y")) 안에도 되는지 — 되는 길로만"
  if [ "$ADD" = 0 ]; then
    "$DOCKER" run --rm --group-add 100 -v "$Y:/y" "$IMG" \
      sh -c 'set -e; t=/y/.dss-write-test; : > "$t"; rm -f "$t"; echo OK' >/dev/null 2>&1 \
      && echo "  ✓ group_add 100 으로 올해 폴더에도 쓸 수 있다" \
      || echo "  ✗ group_add 100 으로도 올해 폴더에는 못 쓴다"
  fi
fi

echo
echo "══ 새로 만든 파일을 직원이 열 수 있나 — 물려받는 ACL 확인"
if [ "$ADD" = 0 ]; then
  "$DOCKER" run --rm --group-add 100 -v "$P:/quote-archive" "$IMG" \
    sh -c ': > /quote-archive/.dss-inherit-test' 2>/dev/null
  if [ -e "$P/.dss-inherit-test" ]; then
    echo "  만들어진 파일의 주인·모드:"
    ls -l "$P/.dss-inherit-test" | sed 's/^/    /'
    echo "  물려받은 ACL:"
    synoacltool -get "$P/.dss-inherit-test" 2>&1 | grep -E "allow|deny" | head -8 | sed 's/^/    /'
    rm -f "$P/.dss-inherit-test"
    echo "  (시험 파일은 지웠다)"
  fi
fi

echo
echo "════════════════════════════════════════════════════════════"
if [ "$ADD" = 0 ]; then
  echo "  → group_add 100 으로 된다. compose 의 app-as 에 그 줄을 넣고"
  echo "    07-deploy.sh 를 다시 돌리면 된다. Claude 에게 이 결과를 알려 주세요."
elif [ "$MAIN" = 0 ]; then
  echo "  → user 1000:100 이어야 된다. /data 의 주인도 함께 봐야 한다."
  echo "    Claude 에게 이 결과를 알려 주세요."
elif [ "$BASE" = 0 ]; then
  echo "  → 지금 그대로도 된다. 07 의 시험이 다른 까닭으로 실패했다(파일 이름?)."
else
  echo "  → 셋 다 안 된다. 견적서 공유폴더 저장은 이번 배포에서 빼는 것이 낫다."
  echo "    as.env 의 QUOTE_ARCHIVE_ 두 줄을 지우면 나머지는 그대로 간다."
fi
echo "════════════════════════════════════════════════════════════"
