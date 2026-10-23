#!/bin/bash
# dss-deploy/nas/setup/34-rf-trouble-shares-verify.sh — 공유폴더가 실제로 닿는가 (2026-10-23)
#
# 🔴 NAS 에서 돈다. DSM 터미널은 긴 명령을 잘라 먹으므로 **파일로 올려** 돌린다.
#    md5 를 맞춘다:  md5sum /volume1/dss/setup/34-rf-trouble-shares-verify.sh
#
# ── 모드 둘 ───────────────────────────────────────────────────────────
#   (기본)   아무것도 안 바꾸고 **재기만** 한다.
#   --go     app-rf-trouble 를 다시 띄우고 나서 잰다.
#            🔵 33 번이 compose 에 볼륨 두 줄을 넣어 놨으므로, 다시 떠야
#               그 볼륨이 붙는다. 컨테이너는 갈아 끼워지고 데이터는 볼륨에 남는다.
#
# ── 🔴 왜 컨테이너 **안에서** 재는가 ──────────────────────────────────
#   호스트에서 `ls /volume1/7_항상필요한자료` 를 하면 swhur 권한으로 통과한다.
#   앱은 그 계정이 아니고 그 경로도 아니다. 호스트에서 ✓ 인데 앱은 못 읽는 일이
#   실제로 있었다(ACL 은 이름 기반이라 uid 만으로는 안 열릴 수 있다).
#   → 이 스크립트는 **config.json 을 앱의 node 로 읽어, pathMap 으로 옮긴 바로
#      그 경로를 앱 안에서 존재 확인**한다. 앱이 쓰는 길 그대로다.
set -uo pipefail

CF=/volume1/dss/deploy/docker-compose.nas.yml
CN=dss-rf-trouble
SVC=app-rf-trouble
GO=0
[ "${1:-}" = "--go" ] && GO=1

PASS=0; FAIL=0; WARN=0
ok()  { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
hm()  { WARN=$((WARN+1)); printf '  ? %s\n' "$1"; }
say() { printf '    %s\n' "$1"; }

printf '%s\n' "RF 이슈관리 · 공유폴더 실측   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $([ "$GO" = 1 ] && echo '--go (다시 띄우고 잰다)' || echo '기본 (안 바꾸고 재기만 한다)')"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 1. compose 에 두 줄이 있는가 (글자) ───────────────────────────────
printf '\n== 1. compose 의 볼륨 두 줄\n'
# 🔴 줄머리 `- ` 만 센다 — 같은 블록의 **안내 주석**에 같은 글자가 적혀 있어서,
#    그냥 grep 하면 주석을 세어 버린다(2026-10-23 에 실제로 그래서 잘못 멈췄다).
C7=$(grep -cE '^[[:space:]]*- .*:/mnt/nas7:ro' "$CF")
C1=$(grep -cE '^[[:space:]]*- .*:/mnt/nas1:ro' "$CF")
say "nas7 ${C7}개 · nas1 ${C1}개 · 전체 $(wc -l < "$CF")줄"
if [ "$C7" = "1" ] && [ "$C1" = "1" ]; then ok "두 줄이 하나씩 있다"
else bad "두 줄이 1·1 이 아니다 — 33 번을 먼저 돌리세요"; fi
if [ "$FAIL" != "0" ]; then printf '\n🔴 멈춘다.\n'; exit 1; fi

# ── 2. --go 일 때만 다시 띄운다 ───────────────────────────────────────
if [ "$GO" = 1 ]; then
  printf '\n== 2. %s 를 다시 띄운다\n' "$SVC"
  printf '%s\n' "🔴 --no-deps 다 — 이 서비스 하나만 갈아 끼운다. 나머지 여덟은 안 건드린다."
  B4=$(docker inspect -f '{{.Id}}' "$CN" 2>/dev/null | cut -c1-12)
  say "지금 컨테이너: ${B4:-없음}"
  ( cd /volume1/dss/deploy && docker compose -f "$CF" --env-file .env.nas up -d --no-deps "$SVC" ) 2>&1 | sed 's/^/    /'
  AF=$(docker inspect -f '{{.Id}}' "$CN" 2>/dev/null | cut -c1-12)
  say "바뀐 뒤 컨테이너: ${AF:-없음}"
  if [ -n "$AF" ] && [ "$AF" != "$B4" ]; then ok "컨테이너가 새 것으로 갈렸다"
  elif [ -n "$AF" ]; then bad "컨테이너 id 가 그대로다 — 볼륨이 안 붙었을 수 있다"
  else bad "컨테이너가 없다"; fi
  say "뜨는 것을 8초 기다린다…"; sleep 8
else
  printf '\n== 2. (건너뜀 — 기본 모드는 안 바꾼다)\n'
fi

# ── 3. 컨테이너가 떠 있고, 마운트가 실제로 붙었는가 ───────────────────
printf '\n== 3. 컨테이너와 마운트\n'
ST=$(docker inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
say "상태: ${ST:-못 찾음} · 시작 $(docker inspect -f '{{.State.StartedAt}}' "$CN" 2>/dev/null)"
if [ "$ST" = "running" ]; then ok "돌고 있다"; else bad "안 돌고 있다 (${ST:-못 찾음})"; fi

printf '\n    ── docker 가 보는 마운트 목록:\n'
docker inspect -f '{{range .Mounts}}{{.Source}} -> {{.Destination}} ({{if .RW}}rw{{else}}ro{{end}}){{"\n"}}{{end}}' "$CN" 2>/dev/null | sed 's/^/      /'
for d in /mnt/nas7 /mnt/nas1; do
  n=$(docker inspect -f "{{range .Mounts}}{{if eq .Destination \"$d\"}}{{.Source}}{{end}}{{end}}" "$CN" 2>/dev/null)
  if [ -n "$n" ]; then ok "$d 가 $n 에 붙어 있다"; else bad "$d 가 안 붙어 있다"; fi
done

# ── 4. 🔴 컨테이너 **안에서** 세어 본다 ───────────────────────────────
printf '\n== 4. 컨테이너 안에서 실제로 보이는가\n'
printf '%s\n' "🔴 0개면 **빈 폴더가 붙은 것**이다 — 도커는 그래도 오류를 안 낸다."
for d in /mnt/nas7 /mnt/nas1; do
  c=$(docker exec "$CN" sh -c "ls -1 $d 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  if [ -n "$c" ] && [ "$c" -gt 0 ] 2>/dev/null; then ok "$d 안에 ${c}개가 보인다"
  else bad "$d 안이 비어 있거나 못 읽는다 (${c:-못 쟀음})"; fi
done

# ── 5. 앱이 제 설정을 읽을 수 있는가 ──────────────────────────────────
printf '\n== 5. 앱이 config.json 을 읽는가\n'
H=$(md5sum /volume1/dss/rf-trouble-data/config.json 2>/dev/null | awk '{print $1}')
G=$(docker exec "$CN" sh -c 'md5sum /app/config.json 2>/dev/null' 2>/dev/null | awk '{print $1}')
say "호스트 ${H:-못 쟀음}"
say "앱 안  ${G:-못 쟀음}"
if [ -n "$G" ] && [ "$G" = "$H" ]; then ok "같은 파일을 읽고 있다"
elif [ -z "$G" ]; then bad "앱이 /app/config.json 을 못 읽는다 (권한이나 마운트)"
else bad "지문이 다르다 — 다른 파일을 읽고 있다"; fi

# ── 6. 🔴 config 의 경로 전부를 **앱 안에서** 존재 확인 ───────────────
printf '\n== 6. config 에 적힌 경로가 앱 안에서 닿는가\n'
printf '%s\n' "🔵 config 를 앱의 node 로 읽어 pathMap 으로 옮긴 **그 경로**를 확인한다."
JS=$(cat <<'JSEOF'
var fs = require('fs');
var c = JSON.parse(fs.readFileSync('/app/config.json', 'utf8'));
var map = c.pathMap || {};
var keys = Object.keys(map).sort(function (a, b) { return b.length - a.length; });
function tr(p) {
  if (!p) return null;
  for (var i = 0; i < keys.length; i++) {
    if (p.indexOf(keys[i]) === 0) {
      return (map[keys[i]] + p.slice(keys[i].length)).split('\\').join('/');
    }
  }
  return null;
}
function chk(label, p) {
  var t = tr(p);
  if (t === null) { console.log('X  ' + label + ' : pathMap 에 안 걸린다'); return; }
  var mark = 'X  ', tail = '';
  try {
    var st = fs.statSync(t);
    mark = 'O  ';
    tail = st.isDirectory() ? ('  [폴더 ' + fs.readdirSync(t).length + '개]')
                            : ('  [파일 ' + st.size + 'B]');
  } catch (e) { tail = '  [' + e.code + ']'; }
  console.log(mark + label + tail + '  ' + t);
}
chk('sourceExcel', c.sourceExcel);
chk('baseDir', c.baseDir);
(c.scanDirs || []).forEach(function (d, i) { chk('scanDirs[' + i + ']', c.baseDir + '\\' + d); });
(c.extraExcels || []).forEach(function (d, i) { chk('extraExcels[' + i + ']', d); });
JSEOF
)
OUT=$(printf '%s\n' "$JS" | docker exec -i "$CN" node 2>&1)
printf '%s\n' "$OUT" | sed 's/^/      /'
NO=$(printf '%s\n' "$OUT" | grep -c '^O  ')
NX=$(printf '%s\n' "$OUT" | grep -c '^X  ')
say "닿음 ${NO} · 못 닿음 ${NX}"
if [ "$NX" = "0" ] && [ "$NO" -ge 5 ] 2>/dev/null; then ok "config 의 경로가 전부 앱 안에서 닿는다 (${NO}개)"
elif [ "$NO" = "0" ]; then bad "하나도 못 쟀다 — 위 출력을 보세요(node 가 안 돌았을 수 있다)"
else bad "못 닿는 경로가 ${NX}개 있다 — 위에서 X 를 보세요"; fi

# ── 7. 로그에 갱신 실패가 남아 있는가 ─────────────────────────────────
printf '\n== 7. 다시 뜬 뒤의 로그\n'
LG=$(docker logs --since 5m "$CN" 2>&1 | tail -40)
printf '%s\n' "$LG" | sed 's/^/      /'
E=$(printf '%s\n' "$LG" | grep -ciE 'ENOENT|EACCES|실패|error' )
if [ "$E" = "0" ]; then ok "최근 5분 로그에 실패가 없다"
else hm "실패처럼 보이는 줄이 ${E}개 있다 — 위를 읽어 보세요"; fi

# ── 8. 화면이 뜨는가 ──────────────────────────────────────────────────
printf '\n== 8. 7331 이 응답하는가\n'
CODE=$(docker exec "$CN" sh -c 'wget -q -O /dev/null -S http://127.0.0.1:7331/ 2>&1 | grep -m1 HTTP' 2>/dev/null)
say "${CODE:-응답 없음}"
if printf '%s' "$CODE" | grep -qE '200|30[12]'; then ok "앱이 응답한다"
else hm "응답을 못 읽었다 — 브라우저로 직접 봐 주세요"; fi

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
if [ "$FAIL" = "0" ]; then
  printf '%s\n' "✅ 기계로 잴 수 있는 것은 전부 통과했다."
  printf '%s\n' "🔴 **마지막은 눈이다** — 브라우저에서 RF 이슈관리를 열고 확인해 주세요:"
  printf '%s\n' "     · 지식 수가 0 이 아닌가 (동료 개발 서버 기준 321 근처)"
  printf '%s\n' "     · 파일 수가 0 이 아닌가 (기준 3,492 근처)"
  printf '%s\n' "     · 「자동 갱신 실패」 알림이 사라졌는가"
else
  printf '%s\n' "🔴 위 ✗ 를 먼저 보세요. 되돌리려면 33 번이 뜬 사본을 쓰면 된다."
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
