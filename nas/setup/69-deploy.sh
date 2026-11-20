#!/bin/bash
# dss-deploy/nas/setup/69-deploy.sh — 예순다섯째 배포 (2026-11-20)
#
# ══════════════════════════════════════════════════════════════════════
# 🔴🔴 **이 파일은 바탕이 둘이다 — 68번의 뼈대 + 62번의 재고 값** (2026-11-19 결정)
# ══════════════════════════════════════════════════════════════════════
#   🔴 **이번은 A/S 가 아니라 재고관리다.** 지난 다섯 판(64~68)이 전부 A/S 였다 —
#      그 전제를 그대로 베끼면 **기대값이 정반대가 되는 자리가 둘** 있다(머리말 ③·④).
#   · **뼈대 · 모드 여섯 · 관문 · 안 건드리는 집을 전후로 맞대는 법** → **68-deploy.sh**
#     에서 글자 그대로 가져왔다. 모양이 68번과 같다: 앱 **하나** + 도구 **하나** +
#     마이그레이션 **0건** + 묶음 **없음** + 안 건드리는 집 **아홉**.
#   · **재고관리 고유의 값** → **62-deploy.sh**(쉰여덟째)에서 가져왔다:
#     서비스 이름(app-inventory · tools-inventory) · 상자 이름(dss-inventory) ·
#     호스트 포트 13800 · DB(dss-pg-app 의 dss_inventory) · 설정 파일 inventory.env ·
#     public 이 **비어 있다**는 것 · 마이그레이션이 **이미지 안에서** 돈다는 것.
#   🔴 **62번을 통째로 복사하지 않았다** — 그 판은 **집이 여섯**이다.
#
#   🔴 **이 파일에 「왜 없는가」를 적어 두는 절 넷** (68·67·65·64·63 이 그렇게 했다):
#      · **--migrate 모드가 없다.** 까닭: 올릴 .sql 이 0건이다(2-ㄷ 가 값으로 잰다).
#        🔴 1건이라도 생기면 **62번에서 --migrate 와 img_sql_check 를 되살려라.**
#        🔵 재고의 올리는 길은 **묶음이 아니라 도구 이미지를 다시 굽는 것**이다 —
#           그래서 66번(A/S)이 아니라 **62번**에서 되살려야 한다.
#      · **묶음(as-migrations.tar.gz)을 읽는 절이 없다.** 🔴 **재고는 애초에 묶음을
#        안 쓴다** — .sql 이 도구 이미지 안에 구워져 간다. 1-ㅁ 절이 ⚠️ 로 알려만 준다.
#      · **DBPHASE / VOLPHASE 단계 가지가 없다.** 처음부터 끝까지 **같은 기대값**이라
#        뜻 없는 분기를 남기지 않는다.
#      · **go_gate 의 DB 관문이 「dss_inventory 가 28인가」로 바뀌었다**(68번은 dss_as
#        132 였다). 🔴 **--no-deps 를 쓰므로 DB 가 실제로 답하는지는 그대로 잰다** —
#        빼면 --no-deps 가 죽은 DB 위에서 돈다.
#
# 🔴 **NAS 에서 돈다.** DSM 터미널에서 sudo -i 뒤에 부른다.
#     bash /volume1/dss/setup/69-deploy.sh            ← --check (기본 · 아무것도 안 바꾼다)
#     bash /volume1/dss/setup/69-deploy.sh --count
#     bash /volume1/dss/setup/69-deploy.sh --preload
#     bash /volume1/dss/setup/69-deploy.sh --tools
#     bash /volume1/dss/setup/69-deploy.sh --go
#     bash /volume1/dss/setup/69-deploy.sh --rollback
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 올리는 것 — 한 줄 요약**
# ══════════════════════════════════════════════════════════════════════
#   [재고관리] **부품의 도번이 맨 아랫줄에 제 줄로 서고, 그 모양을 설정에서 고른다.**
#   ① 🔵 **보이는 자리가 셋이다** — [부품 요청 관리] · [승인 요청건] · **불출 신청
#      팝업**. 셋이 같은 조각(components/stock/RequestItemDetails.tsx)을 쓴다.
#      🔴 눈 확인은 **셋 다** 해야 한다 — 한 곳만 보면 나머지 둘을 못 가른다.
#   ② 🔴 **도번이 없는 부품에서는 그 줄이 통째로 안 선다**(「빈 칸은 안 그린다」).
#   ③ 🔵 **모양은 [설정] → [도번 표시] 에서 고른다**(관리자만). 넷을 고른다 —
#      알약 켬/끔 · 글자 크기 · 글자색 · 알약색. 미는 칸과 색 고르개를 움직이면
#      **저장 없이** 미리보기가 따라 바뀐다.
#   ④ 🔴 **알약을 꺼도 도번은 안 사라진다** — 글자만 커지고 색이 든다.
#      알약색 칸은 흐려지되 **값은 남는다.**
#   🔵 **DB 는 한 글자도 안 바뀐다** — 마이그레이션 **0건**. 🔴 까닭: 고른 모양이
#      **이미 있는 app_settings 표**에 열쇠 하나(drawing_no_style)로 들어간다.
#      🔵 --count 의 ⑤ 절이 **그 열쇠가 저장돼 있는지**를 올리기 전후로 센다.
#         🔴 **배포 직후에는 0줄이 정상이다** — 사람이 저장해야 줄이 생긴다.
#
#   앱 **하나** · 도구 **하나** · 마이그레이션 **0건** · 묶음 **없음** ·
#   안 건드리는 집 **아홉**(🔴 **그 아홉에 A/S 가 들어 있다** — 지난 판과 반대다).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **68번의 전제 중 이번에 깨지는 것 다섯 — 하나씩 재서 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴🔴 **갈아 끼우는 집이 A/S 가 아니라 재고관리다.**
#      SITES · TOOLS · KEEP_BOXES 가 **전부 바뀐다.** 🔴 **KEEP_BOXES 에 dss-as 가
#      들어가고 dss-inventory 가 빠진다** — 68번과 **정확히 반대**다. 한 자리만
#      안 바꾸면 「안 건드리는 집이 달라졌다」가 **배포 직후 ✗** 로 터진다.
#
#   ② 🔴🔴 **표식을 통째로 갈았다. 그리고 재는 곳이 셋으로 갈린다.**
#        · 앱 번들 — **이번 판에 태어난 DOM id** drawing-no-text-color.
#          [실측 2026-11-20 · 개발 PC] src 에서 기준 **0파일** → 지금 **1파일**이고,
#          **주석을 걷은 뒤에도 1파일**(문자열 리터럴이라 minify 가 못 지운다).
#        · 앱 번들의 **뒷걸음 둘** — portal_approval_delegations(기준 14 → 14) ·
#          stock_issue_approval_steps(기준 10 → 10). 🔵 둘 다 **DB 표 이름**이라
#          문자열로 남는다. 🔴 주석을 걷으면 각각 **3파일 · 1파일**이다 —
#          날것 수(14·10)만 보면 넉넉해 보이지만 대부분이 주석이다.
#        · 도구 이미지 — **소스 글자 그대로** 둘을 센다:
#          TOOLMARK = DrawingNoLine in src/components/stock/RequestItemDetails.tsx
#                     [실측] 그 파일 안에서 기준 **0줄** → 지금 **4줄**
#          TOOLKEEP = TOOLBAR_BTN_PRIMARY in src/components/parts/PartsList.tsx
#                     [실측] 기준 **2줄** → 지금 **2줄** (🔴 **뒷걸음 셋째다**)
#      🔴 **TOOLBAR_BTN_PRIMARY 를 앱 번들에서 세지 않는다.** 그것은 **모듈 안의
#         const 이름**이라 minify 가 **이름을 바꾼다** — 번들에서 0 이 나오고 그 ✗ 는
#         진짜 결함처럼 보인다. 🔵 62번이 그것을 **도구 이미지의 소스 글자**로 쟀다 —
#         **그 자리로 되돌렸다.** 🔴 **뒷걸음 셋 중 하나도 안 뺐다.**
#      🔴 **drawing_no_style(스네이크)은 표식으로 안 쓴다** — DB 열쇠라 소스에서
#         한 자리뿐이고 번들에서 0 이 나와 **가짜 ✗** 가 난다.
#
#   ③ 🔴🔴 **재고의 마이그레이션은 「이미지 안」에서 돈다 — A/S 와 정반대다.**
#      A/S 도구 이미지는 /app/drizzle 이 **비어 있어야** 하고(볼륨이 정본),
#      재고 도구 이미지는 **28장이 들어 있어야** 한다.
#      🔴 68번의 2-ㄷ 절을 그대로 베끼면 **멀쩡한 재고 도구가 ✗** 가 난다.
#      🔵 **A/S 볼륨(132장)을 보는 줄은 안 뺐다** — 이제 「안 건드리는 집이 뒷걸음치지
#         않았는가」를 보는 자리다(2-ㄹ).
#
#   ④ 🔴 **재고의 public/ 은 있는데 비어 있다**(ls -1 로 0개 — .gitkeep 은 숨은 파일).
#      🔴 68번의 「9개 이상이어야 한다」를 베끼면 **멀쩡한 재고 앱이 ✗** 가 난다.
#      🔵 62번이 그 자리에서 가짜 ✗ 를 냈고, 그래서 ⚠️ 가지를 따로 두었다.
#
#   ⑤ 🔴 **--count 를 통째로 갈았다.** 68번의 --count 는 **내자 줄·견적서 결재**를
#      셌다 — 그 수는 이번 판과 **상관이 없다.** 그대로 두면 이 배포를 재는 숫자가
#      **하나도 없다.** 🔵 재고의 자리로 갈았다(①~⑥). 🔴 **참고값이 없다** —
#      재고를 세는 --count 는 **이 판이 처음**이다. 지어내지 않았다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **68번에서 그대로 살린 것 — 한 번 빼면 다시 넣는 사람이 없다**
# ══════════════════════════════════════════════════════════════════════
#   · **--migrate 는 없다**(마이그레이션 0건). 그 자리에 **--tools** 가 있다.
#   · 2절 「DB 가 **안 바뀌었는가**」 — 다섯 집 132·28·5·11·3 · 쉰여덟째의 표 넷.
#     🔵 그 수들은 **이 배포로 한 자리도 안 바뀐다.**
#   · 🔴 **--no-deps** 와 그 관문(DB 가 도는가 + **실제로 답하는가**) ·
#     끝에서 **DB 둘의 켜진 때 맞대기**. [실측 2026-11-18] 이것이 없어서 --go 가
#     dss-pg-app 을 Recreate 했다 — 자료는 멀쩡했지만 모든 연결이 끊겼다 붙었다.
#   · 함수 정의에 붙인 **</dev/null** — 고리 안의 docker exec 가 here 문서를 먹는다.
#   · **「몇 개를 봤는가」 관문** — 고리를 도는 검사마다 끝에서 센 횟수를 단언한다.
#   · 덤프(🔴 **dss_inventory 하나** — 68번은 dss_as 였다) · compose 사본 ·
#     **새 도구로 안을 세어 받기**.
#   · 4절의 **빼지 않는 검사들** — 연락서 폴더 · 양식 폴더 · PO 쓰기 권한 ·
#     발주서 공유폴더. 🔴 **이번 판과 아무 상관이 없지만 안 뺐다**(한 번 빼면
#     다시 넣는 사람이 없다). 🔵 넷 다 **A/S 도구 이미지**로 재는 자리라, 이번 판에는
#     **「안 건드리는 집이 멀쩡한가」**를 보는 뜻이 된다.
#   · 🔴 **지난 판 묶음이 incoming 에 남아 있다는 ⚠️** 와 「이 배포본은 안 읽는다」.
#   · 3xx 판정(200|30[1237]) — 빼면 멀쩡한 사이트가 ✗ 로 나온다(2026-10-30 실측).
#   · 치환 전에 그 줄의 낱말 수가 2 인지 보기 · image: 줄 수를 세어서 맞대기 ·
#     설정 파일 중복 키와 auto · 제 md5 를 스스로 찍기 · image: 줄 통째로 찍기.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **모드 여섯 — 쓰는 것 / 안 쓰는 것**
# ══════════════════════════════════════════════════════════════════════
#   (기본) --check
#       쓰는 것 : **없다.**
#       🔴 다만 **읽기는 한다** — DB 에 select, 앱 주소에 GET, 이미지가 실려
#          있으면 **run --rm 으로 잠깐 띄웠다 지운다**(sh 로 열 뿐 앱을 시작하지 않는다).
#   --count
#       쓰는 것 : **없다.** 이 배포가 **보여 주는 것이 달라지는 자리**를 센다.
#       🔵 이 배포는 자료를 안 바꾸므로 **전과 후의 수가 같아야 정상**이다.
#       🔴 **올리기 전에 한 번 돌려 두세요** — 특히 ①(도번이 적힌 부품)을 봐 두어야
#          합니다. **그 부품들에서만 새 줄이 섭니다.**
#       🔴 **참고값이 하나도 없습니다** — 재고를 세는 --count 는 이 판이 처음입니다.
#   --preload
#       쓰는 것 : **NAS 의 도커 이미지 저장소**(docker load 로 태그 둘).
#       🔵 실어만 두고 **아직 안 갈아 끼운다.** 싣자마자 **안을 센다.**
#   --tools
#       쓰는 것 : **DB 덤프 한 장**(🔴 **dss_inventory**) · **compose 사본 한 장** ·
#                 **compose 의 image: 줄 하나**(tools-inventory 만).
#       안 쓰는 것: 🔴 **DB** · 앱의 image: 줄 · 도는 컨테이너 · 볼륨 · 공유폴더.
#       🔵 profiles: [tools] 라 평소에 뜨지 않는다 — **직원이 느끼는 것이 없다.**
#       🔴 새 도구의 **안을 세어** 확인한다 — 🔴 **db:migrate 를 돌리지 않는다**
#          (재고의 db:migrate 는 **실제로 적용하는 명령**이고 이번 판은 **0건**이다).
#          🔵 68번은 A/S 도구에 db:preflight 라는 **읽기 전용** 명령이 있어 그것을
#             돌렸다 — **재고에는 그 명령이 없다**(package.json 에 db:migrate 뿐).
#          🔴 **「없는 명령을 베껴 적으면」 Missing script 로 멈춘다.** 그래서
#             여기서는 **이미지 안의 .sql 수와 소스 표식**을 값으로 받는다.
#   --go
#       쓰는 것 : **compose 사본 한 장** · **compose 의 image: 줄 하나**(app-inventory) ·
#                 **앱 하나를 다시 띄운다**(정지 창 — 20~30초).
#       안 쓰는 것: 🔴 **DB** · 볼륨 · 공유폴더 · 🔴 **나머지 아홉 집의 image: 줄**.
#       🔴 **--no-deps 를 쓴다** — 그것이 없어서 DB 가 Recreate 된 적이 있다.
#   --rollback
#       쓰는 것 : **compose 사본 한 장** · **app-inventory 의 image: 줄** · **앱 하나를 다시 띄운다.**
#       안 쓰는 것: 도구 태그(새 판 그대로 둔다) · DB · 볼륨 · 덤프(안 뜬다).
#       🔵 **DB 는 되돌릴 것이 없다** — 이 배포는 한 글자도 안 바꿨다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 환경의 함정 — 이 파일이 지키고 있는 것**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 이다.** 이 파일은 **$( … || true )**
#      로만 받는다.
#   ② 🔴 **tar | grep -q 를 if 에 바로 물리지 않는다.** pipefail 아래서 grep -q 가
#      먼저 끝나면 앞의 tar 가 SIGPIPE 로 죽어 **파일이 있을 때 오히려 ✗** 가 난다.
#      🔵 이번 판은 묶음을 안 읽으므로 tar 를 파이프에 무는 자리가 **없다.**
#   ③ 🔴 **bash -n 이 못 잡는 둘.** 큰따옴표 안의 백틱 · 읽기전용 자리의 콜론-꺾쇠 →
#      **이 파일에는 둘 다 한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   ④ 🔴 **CRLF.** Git Bash 의 grep 만 \r 를 걷어내고 NAS 의 GNU grep 은 안 걷어낸다.
#      줄 전체로 맞대는 검사는 **읽자마자 tr -d 로 \r 를 걷은 뒤** 한다.
#   ⑤ 🔴 **빈 결과는 삼켜진 오류일 수 있다.** 「비면 OK」로 읽는 자리를 안 만든다 —
#      목록은 **읽은 줄 수를 함께 받고**, **없는 경로·없는 열쇠를 일부러 함께 묻는다.**
#   ⑥ 🔴 **재고의 마이그레이션은 이미지 안에서 돈다**(A/S 와 반대). 도구 이미지 안의
#      **.sql 과 meta/_journal.json 을 둘 다** 센다.
#   ⑦ 🔴 **저장소의 compose 사본은 운영보다 뒤처진다**(아홉 판 차이가 난 적이 있다).
#      이 파일은 **NAS 위의 docker-compose.nas.yml 만 읽는다.**
#   ⑧ 🔴 **bash 의 $(( )) 는 0 으로 시작하는 수를 8진수로 읽는다** — 0028 을 셈에
#      넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
#   ⑨ 🔴 **한글을 HTTP 머리말·argv 에 넣지 않는다.** 🔵 이 파일의 표식은 **전부 ASCII** 다.
#   ⑩ 🔴 **비밀값을 찍지 않는다.** 설정 파일은 이름이 있는가/없는가와 auto 인가만
#      본다. DATABASE_URL 에서는 **역할 이름만** 꺼낸다.
#   ⑪ 🔵 **받을 폴더는 777 로 만든다** — root 가 만든 755 는 scp 가 못 쓴다.
#   ⑫ 🔴 **「겉이 아니라 결과를 봐라」** — --preload 는 싣자마자 **안을 센다.**
#   ⑬ 🔵 **Git Bash 가 docker 인자를 번역하는 함정은 NAS 에 없다**(리눅스다).
#      🔴 그래도 **같은 꼴로 적어 둔다**: 파일 경로는 **상대로 넘기고 /app/ 를
#      컨테이너 안에서 붙인다.** 누가 이 파일을 Git Bash 에서 흉내 내도 살아남는다.
#
# ── 🔴 알고도 안 고친 것 — PO 가 모르는 것이 **넷**이다 ──────────────
#   🔵 **이번 판이 거기에 더하는 것은 없다** — 재고관리와 PO 는 **DB 도 표도 안
#      겹친다**(PO 는 dss_as 를 본다). 🔴 그래도 4-ㄷ 절은 **안 뺐다.**
#   🔵 **지금은 안전하다** — 운영에서 직원의 PO 접근 권한을 모두 빼 두었다
#      (2026-11-08). 🔴 **PO 를 다시 여는 날 넷을 한 묶음으로 이식해야 한다.**
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v65-$STAMP
BKDB=$D/backups/db
# 🔴 **BK 와 같은 v 번호여야 한다** — 59번(쉰다섯째)이 여기를 안 고쳐 v54 로 남긴
#    적이 있다. 아래 1-ㄱ-0 절이 값으로 확인한다.
DUMP_VER=v65
INCOMING=$D/setup/incoming
# 🔵 **A/S 의 마이그레이션 볼륨**이다 — 재고와 아무 상관이 없다. 2-ㄹ 이 「안 건드리는
#    집이 뒷걸음치지 않았는가」로 쓴다. 🔴 재고의 .sql 은 **도구 이미지 안**에 있다.
AS_MIGDIR=$D/as-migrations
IMG_MIGDIR=/app/drizzle
TPLDIR=$D/as-templates
# 🔵 지난 판 묶음이 여기 남아 있을 수 있다. 🔴 **이 파일은 그것을 쳐다보지도
#    않는다** — 푸는 코드가 한 줄도 없다. 1-ㅁ 절이 ⚠️ 로 알려만 준다.
OLD_MIGTAR=$INCOMING/as-migrations.tar.gz

# ══ 🔴 앱 **하나** — 🔴 **재고관리다** ════════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트포트|사람이 부르는 이름
#   🔴 값의 출처: **62-deploy.sh 의 SITES** 줄 그대로(태그만 0.7 → 0.8).
SITES='
inventory|app-inventory|dss-inventory|dss-inventory:0.8|dss-inventory:0.7|dss-inventory-0.8.tar|13800|재고관리
'
SITES_WANT=1

# ══ 🔴 도구 **하나** — --tools 가 이 줄을 간다 ════════════════════════
#   열쇠|서비스|새 태그|옛 태그|tar|이름|무엇 때문에 가는가
TOOLS='
inventorytools|tools-inventory|dss-inventory-tools:5|dss-inventory-tools:4|dss-inventory-tools-5.tar|재고도구|🔴 까닭이 **둘**이다 — ㄴ) tools 가 담는 것 중 바뀐 파일이 **15 중 12** · ㄷ) **도구가 부르는 모듈(src/db/schema/app-settings.ts)이 이번 범위에 있다**
'
TOOLS_WANT=1

# ══ 🔴 안 건드리는 **아홉** — 「옆으로 안 샜다」는 증거로 센다 ════════
#   🔴 상자 이름이다(서비스 이름이 아니다) — 저장소의 compose 사본이 운영보다
#      뒤처져 있어 서비스 이름을 믿을 수 없다(⑦).
#   🔴🔴 **68번과 정확히 반대다** — dss-as 가 들어오고 dss-inventory 가 빠진다.
KEEP_BOXES="dss-as dss-auth dss-approvals dss-leave dss-meters dss-board dss-improvements dss-rf-trouble dss-po"
KEEP_BOXES_WANT=9
KEEP_DB="dss-pg-app dss-pg-auth"
KEEP_DB_WANT=2

# ══ 🔴 DB — **바뀌면 안 된다** ════════════════════════════════════════
#   열쇠|DB상자|DB이름|지금도 뒤에도 이 수여야 한다|사람이 부르는 이름
#   🔴 **어긋나면 이 배포와 무관한 다른 사고다.** 그 자리에서 멈춘다.
#   🔵 통합 승인함은 **DB 가 없는 집**이라 이 표에 없다 — 「0건」이 아니라 해당 없음이다.
#   🔵 A/S 는 **132** 다(예순두째가 0131 을 올린 뒤 그대로). 재고는 **28** 이다.
MIGS_KEEP='
as|dss-pg-app|dss_as|132|A/S관리
inventory|dss-pg-app|dss_inventory|28|재고관리
leave|dss-pg-app|dss_leave|5|휴가관리
auth|dss-pg-auth|dss_auth|11|통합로그인포털
meters|dss-pg-app|dss_meters|3|계측기관리
'
MIGS_KEEP_WANT=5

# ══ 🔴 **쉰여덟째가 만든 표 넷** — 뒷걸음 방지 ════════════════════════
#   DB상자|DB이름|표 이름|사람이 부르는 이름
#   🔴 **표 이름이 셋으로 다르다**(A/S·재고 portal_… · 휴가 web_portal_… ·
#      포털 approval_delegations). 하나로 묻는 검사였으면 세 집이 ✗ 였다.
KEEP_TABLES='
dss-pg-app|dss_as|portal_approval_delegations|A/S관리
dss-pg-app|dss_inventory|portal_approval_delegations|재고관리
dss-pg-app|dss_leave|web_portal_approval_delegations|휴가관리
dss-pg-auth|dss_auth|approval_delegations|통합로그인포털
'
KEEP_TABLES_WANT=4

# ══ 🔴 재고 마이그레이션 — **도구 이미지 안에 28장**이어야 한다 ═══════
#   🔴 **A/S 와 정반대다**(머리말 ③). A/S 도구 이미지는 0장이어야 한다.
INV_IMG_SQL_WANT=28
INV_IMG_LAST=0027
INV_IMG_NEXT=0028
# ══ 🔵 A/S 볼륨 — **안 건드리는 집의 뒷걸음을 보는 자리** ═════════════
#   🔵 68번이 이 수를 올려 두었다. 이 배포는 거기에 한 장도 안 더하고 안 뺀다.
AS_VOL_SQL_WANT=132
AS_VOL_NEXT=0133

# ══ 🔴 tar **둘**의 지문 — [배포본] 69-build.sh 가 굽고 **바로 잰 값** ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 지문이 비어 있다 — 굽기 전에 쓴 파일이다.** 69-build.sh --go 가
#      꼬리말에 찍는 **두 줄**로 아래를 통째로 갈아 끼운 **뒤에** scp 하세요.
#      🔵 지금은 **이름만** 적혀 있다(dss-inventory-0.8.tar||| 꼴) — 이름이 있어야
#         3절이 **몇 줄을 봤는지** 센다.
#   🔴 **이 값을 NAS 에서 재서 채우지 마라.** 그러면 「옮기다 깨졌는가」를 자기가
#      잰 값으로 자기를 재는 꼴이 되어 **영영 통과한다.** 반드시 **구운 쪽**에서 잰다.
#   🔴 비어 있으면 3절이 **--check·--count·--rollback 에서는 ? · --preload·
#      --tools·--go 에서는 ✗** 로 센다. 🔵 막는 것은 **✗ 뿐이다.**
#      🔴 **쉰세째에는 빈 표가 그대로 NAS 로 올라갔고 --preload 가 ✗ 둘로 멈췄다.**
#   🔵 **지난 판 바이트**(62-deploy.sh 의 TARS · 다음 판이 크기를 견줄 때 쓴다):
#      dss-inventory-0.7.tar 95449600 · dss-inventory-tools-4.tar 213334528
TARS='
dss-inventory-0.8.tar|95470592|0fb51933bb8c05b9b13239bbaae76420|sha256:f5d76689cee4f3a61e50dbb04dbde57d18d93f3e1b7d05781bbcd415618b18bf
dss-inventory-tools-5.tar|213350912|0bbc4712c65366d4deed795fa03ac75b|sha256:260d2a73d2cced8a18f5ad309d193ce435f5c33d16dba9550f5bdf162eb1366a
'
TARS_WANT=2
# 🔵 **묶음 값(MIGTAR_SIZE·MIGTAR_MD5)은 아예 없다** — 🔴 **재고는 묶음을 안 쓴다.**
#    .sql 은 도구 tar 안에 들어 있다.

# 🔴 tar 이름 → 태그. **정규식으로 되돌리지 않는다** — 이름마다 손으로 적는다.
#    🔴 판에 점이 있는 것과 없는 것이 섞여 있어 한 규칙으로 안 풀린다.
tar2tag() {
  case "$1" in
    dss-inventory-0.8.tar)        printf 'dss-inventory:0.8' ;;
    dss-inventory-tools-5.tar)    printf 'dss-inventory-tools:5' ;;
  esac
}

# ══ 🔴 이미지 안에서 쓸 표식 — **전부 ASCII · 전부 리터럴** ═══════════
#   앱 이미지(번들 · minify 를 거친다)
#   🔴 **이번 판에 태어난 DOM id 다**(머리말 ②) — 색 고르개의 이름표가 가리키는
#      입력 칸의 id 이고, **문자열 리터럴**이라 minify 가 이름을 못 바꾼다.
#      [실측 2026-11-20 · 개발 PC] src 에서 기준 **0파일** → 지금 **1파일**이고,
#      **주석을 걷은 뒤에도 1파일**이다.
APPMARK=drawing-no-text-color
# 🔵 판정에 **안 쓰는** 곁들이 값 — 번들이 **따옴표를 지키는지** 찍는다.
#    🔴 곁들이 꼴은 맨 글자의 **부분집합**이라 맨 글자보다 클 수 없다 — 곁들이가
#       더 크게 나오면 **세는 쪽이 깨진 것**이다.
APPMARK_DIAG='"drawing-no-text-color"'
KEEPMARK1=portal_approval_delegations
KEEPMARK2=stock_issue_approval_steps
# 🔴 **셋째 뒷걸음 표식은 번들에서 안 센다** — const 이름이라 minify 가 이름을
#    바꾼다. 아래 TOOLKEEP 으로 **도구 이미지의 소스 글자**에서 센다(62번 자리).
#   도구 이미지(소스가 글자 그대로 있다)
TOOLMARK=DrawingNoLine
TOOLMARK_FILE=src/components/stock/RequestItemDetails.tsx
TOOLMARK_LINES_WANT=4
# 🔴 그 표식이 가리키는 **새 모듈** — 그 파일이 import 하는 쪽이다(--preload 가 센다).
TOOLMARK_MODULE=src/components/stock/DrawingNoLine.tsx
TOOLKEEP=TOOLBAR_BTN_PRIMARY
TOOLKEEP_FILE=src/components/parts/PartsList.tsx
TOOLKEEP_LINES_WANT=2
# 🔴 **ㄷ 잣대의 과녁** — scripts/ 의 둘이 부르는 모듈이고 이번 범위에 들어 있다.
TOOL_IMPORT_TARGET=src/db/schema/app-settings.ts
TOOL_IMPORT_MARK=SETTING_DRAWING_NO_STYLE
PROBE_MISS=src/__dss_probe_no_such_file__.ts

# ══ 🔴 public/ 기대값 ═════════════════════════════════════════════════
#   🔴 **재고는 yes 인데 안이 비어 있다**(ls -1 로 0개 — .gitkeep 은 숨은 파일).
#      A/S 의 「9개 이상」을 들이대면 **멀쩡한 재고 앱이 ✗** 가 된다(머리말 ④).
INV_PUBLIC_WANT=yes
INV_PUBLIC_N=0

# ══ 🔴 --count 가 쓸 자리 — **참고값이 하나도 없다** ══════════════════
#   🔴 재고를 세는 --count 는 **이 판이 처음**이다. 지어내지 않았다 —
#      올리기 전에 잰 수를 적어 두면 다음 판이 쓸 참고값이 된다.
#   🔴 표·칸 이름은 전부 **스키마에서 확인한 것**이다(src/db/schema/parts.ts 의
#      drawing_no·is_deleted · app-settings.ts 의 key). 지어내지 않았다.
CNT_BOX=dss-pg-app
CNT_DB=dss_inventory
PARTS_TABLE=parts
PARTS_DRAWING_COL=drawing_no
SETTINGS_TABLE=app_settings
SETTING_KEY_STYLE=drawing_no_style
SETTING_KEY_TRANSITION=transition_date
# 🔵 뒷걸음을 보는 표 둘 — 이 배포는 거기 한 줄도 안 넣는다.
KEEPTBL1=portal_approval_delegations
KEEPTBL2=stock_issue_approval_steps

# ══ 🔴 설정 파일 — .env 쪽과 env/*.env 쪽을 **둘 다** 본다 ════════════
ENV_NAS=$D/deploy/.env.nas
ENV_FILES="$D/deploy/env/as.env $D/deploy/env/auth.env $D/deploy/env/po.env $D/deploy/env/inventory.env $D/deploy/env/leave.env $D/deploy/env/meters.env $D/deploy/env/approvals.env"

# ══ 🔵 공유폴더 — 🔴 **한 번 빼면 다시 넣는 사람이 없다**(4절) ════════
#   🔵 넷 다 **A/S 쪽 자리**다 — 이번 판과 상관이 없지만 **안 뺀다.**
#      이제 「안 건드리는 집이 멀쩡한가」를 보는 뜻이 된다.
KYO_SRC=/kyosan-src;        KYO_SRC_MIN=600
KYO_CONV=/kyosan-converted; KYO_CONV_MIN=100
PO_ARCHIVE=/purchase-order-archive
PO_APP_CN=dss-po
PO_WRITE_TABLE=repair_cases

# ══════════════════════════════════════════════════════════════════════
MODE=${1:---check}
case "$MODE" in
  --check|--count|--preload|--tools|--go|--rollback) ;;
  *) printf '쓰는 법: %s [--check|--count|--preload|--tools|--go|--rollback]\n' "$0"
     printf '🔴 **--migrate 는 없습니다** — 이번 판은 마이그레이션이 0건입니다.\n'
     printf '   그 자리에 --tools 가 들어갔습니다(도구 태그만 갈고 DB 는 안 바꿉니다).\n'
     printf '   🔵 62-deploy.sh 에는 --migrate 가 있습니다 — 1건이라도 생기는 판에서는\n'
     printf '      거기서 그 모드를 되살리세요. 🔴 재고는 묶음이 아니라 **도구 이미지**가\n'
     printf '      .sql 을 나릅니다(A/S 와 다릅니다).\n'
     exit 2 ;;
esac

mkdir -p "$D/setup/logs" 2>/dev/null
LOG="$D/setup/logs/deploy65-$(printf '%s' "$MODE" | tr -d '-')-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

PASS=0; FAIL=0; UNK=0
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
unk()  { UNK=$((UNK+1));   printf '  ? %s — 못 쟀다 (%s)\n' "$1" "$2"; }
hm()   { printf '  ⚠️ %s\n' "$1"; }
say()  { printf '    %s\n' "$1"; }
step() { printf '\n%s\n' "══ $1"; }
doubt() { say "🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 처음 도는 코드라"
          say "   기대값이 틀릴 확률이 배포만큼 높습니다. ✓ 쪽 오판은 영영 안 드러납니다."; }
stop() { printf '\n%s\n' "🔴 멈춥니다 — $1"; printf '%s\n' "   로그: $LOG"; exit 1; }

isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }
rows_of() { printf '%s\n' "$1" | grep -v '^[[:space:]]*$'; }
field() { printf '%s' "$1" | cut -d'|' -f"$2"; }
row_by_key() { # 1 표 2 열쇠
  rows_of "$1" | while IFS= read -r r; do
    [ "$(field "$r" 1)" = "$2" ] && printf '%s' "$r"
  done
}

# ── compose 를 읽고 고치는 길 ────────────────────────────────────────
#   🔴 **저장소 사본을 한 번도 안 본다** — 운영보다 아홉 판 뒤처진 적이 있다(⑦).
svc_block() { # 1 서비스 — 그 블록의 줄 번호 범위를 찍는다
  awk -v s="  $1:" '
    $0 == s { inb = 1; start = NR; next }
    inb && /^  [a-zA-Z]/ { print start "," NR - 1; inb = 0 }
    END { if (inb) print start "," NR }
  ' "$CF" | head -1
}
svc_image_line() { # 1 서비스 → "줄번호 태그"
  local rng a b
  rng=$(svc_block "$1"); [ -n "${rng:-}" ] || return 0
  a=${rng%,*}; b=${rng#*,}
  awk -v a="$a" -v b="$b" 'NR>=a && NR<=b && $1=="image:" {print NR, $2; exit}' "$CF"
}
svc_image() { svc_image_line "$1" | awk '{print $2}'; }
svc_image_lineno() { svc_image_line "$1" | awk '{print $1}'; }
nf_at() { awk -v n="$1" 'NR==n {print NF}' "$CF"; }

# 🔴 image: 줄을 **한 줄만** 바꾼다. 치환 전에 그 줄의 낱말 수가 2 인지 본다 —
#    줄 끝에 주석이 붙어 있으면 **주석의 마지막 낱말**이 태그로 바뀌고
#    image: 값은 그대로 남는다(48번이 데인 자리다).
swap_image() { # 1 서비스 2 새 태그 → 0 성공 / 1 실패
  local n f cur now
  n=$(svc_image_lineno "$1")
  if [ -z "${n:-}" ]; then bad "compose 에 $1 의 image: 줄이 없다"; return 1; fi
  f=$(nf_at "$n")
  if [ "${f:-0}" != "2" ]; then
    bad "$1 의 image: 줄(${n})에 낱말이 ${f}개다 — 2 를 기대했다(줄 끝 주석?)"
    say "      🔴 그대로 치환하면 **주석의 마지막 낱말**이 태그로 바뀝니다. 손으로 고치세요."
    return 1
  fi
  cur=$(svc_image "$1")
  sed -i "${n}s|^\( *image: \).*$|\1$2|" "$CF" || { bad "$1 의 image: 줄을 못 고쳤다"; return 1; }
  now=$(svc_image "$1")
  if [ "$now" = "$2" ]; then ok "$1 image: $cur → $2 (${n}줄)"; return 0; fi
  bad "$1 의 image: 가 $now 다 — $2 를 기대했다"; return 1
}

# ── DB 에 묻는 길 ────────────────────────────────────────────────────
#   🔴🔴 **고리 결함의 처방** — -i 를 떼고 함수 정의에 </dev/null 을 붙인다.
#      고리 안에서 stdin 을 빨아들이는 명령을 부르면 **고리가 한 바퀴만 돈다.**
#   🔵 psql · pg_dump 는 stdin 을 **안 읽는다** — -i 가 애초에 필요 없었다.
pgq() { # 1 상자 2 DB 3 SQL
  "$DOCKER" exec "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -tAc \"$3\"" </dev/null 2>/dev/null | tr -d ' \r'
}
pgrows() { "$DOCKER" exec "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -tAc \"$3\"" </dev/null 2>/dev/null | tr -d '\r'; }
pgn() { local v; v=$(pgq "$1" "$2" "$3"); isnum "$v" && printf '%s' "$v"; }
mig_count() { pgn "$1" "$2" 'select count(*) from drizzle.__drizzle_migrations'; }
has_table() { pgn "$1" "$2" "select count(*) from information_schema.tables where table_schema='public' and table_name='$3'"; }
table_rows() { pgn "$1" "$2" "select count(*) from $3"; }
# 🔵 62·66·68번에서 가져왔다 — **칸이 있는지 먼저 묻는** 데 쓴다.
#    🔴 없는 칸에 질의를 던지면 42703 으로 거절되고, 그 빈 결과가 결함처럼 보인다.
has_column() { pgn "$1" "$2" "select count(*) from information_schema.columns where table_schema='public' and table_name='$3' and column_name='$4'"; }

# 🔴 **compose 도 stdin 을 읽는다** — 같은 까닭으로 </dev/null 을 붙인다.
dct() { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas --profile tools "$@" </dev/null ); }
dcu() { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas "$@" </dev/null ); }

# 🔴 이미지 안을 여는 길 — **경로를 상대로 넘기고 /app/ 를 컨테이너 안에서 붙인다**(⑬).
dock() { "$DOCKER" run --rm --entrypoint sh "$@" </dev/null 2>/dev/null | tr -d '\r'; }

# ── 앱이 답하는가 ────────────────────────────────────────────────────
#   🔴 **3xx 를 통과로 센다** — 로그인으로 보내는 것이다.
#      빠뜨리면 **멀쩡한 사이트가 ✗ 로 나온다**(2026-10-30 실측).
http_code() { # 1 호스트포트
  curl -s -o /dev/null -w '%{http_code}' --max-time 8 "http://127.0.0.1:$1/" 2>/dev/null
}
http_ok() { printf '%s' "${1:-}" | grep -qE '^(200|30[1237])$'; }

# ── 🔴 지금 운영이 어느 단계인가 ─────────────────────────────────────
#   PRE  옛 태그   NEW 새 태그   ODD 그 밖
state_of() { # 1 지금 2 옛 3 새
  if [ "${1:-}" = "$3" ]; then printf 'NEW'
  elif [ "${1:-}" = "$2" ]; then printf 'PRE'
  else printf 'ODD'; fi
}

printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' " 69-deploy.sh — 예순다섯째 배포 ($MODE)"
printf '%s\n' "   때      : $(date '+%F %T')"
printf '%s\n' "   로그    : $LOG"
printf '%s\n' "   compose : $CF"
printf '%s\n' "   🔴 **이번 집은 재고관리입니다** (지난 다섯 판은 A/S 였습니다)"
printf '%s\n' "   앱 1 · 도구 1 · 🔴 **마이그레이션 0건** · 묶음 없음 · 안 건드리는 집 9"
printf '%s\n' "   판      : 🔴 **dss-inventory:0.7 → 0.8** · dss-inventory-tools:4 → 5"
printf '%s\n' "   🔵 [재고관리] 도번을 **제 줄에 크게** — 모양은 [설정] → [도번 표시] 에서 고릅니다"
printf '%s\n' "══════════════════════════════════════════════════════════════"
# 🔴 **제 md5 를 스스로 찍는다** — DSM 터미널이 긴 명령을 잘라 먹으므로
#    개발 PC 의 Get-FileHash 와 **눈으로 맞댄다.**
printf '  이 파일의 md5: %s\n' "$(md5sum "$0" 2>/dev/null | awk '{print $1}')"

if [ ! -f "$CF" ]; then stop "compose 파일이 없다 — $CF"; fi
if [ ! -x "$DOCKER" ]; then stop "도커를 못 찾았다 — $DOCKER"; fi

# ══════════════════════════════════════════════════════════════════════
# ── 1. 지금 상태 ──────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════
step "1. 지금 상태 — **운영이 실제로 쓰는 것**만 본다 (저장소 사본을 안 믿는다)"

# 1-ㄱ-0. 🔴 덤프 이름과 compose 사본 이름의 판 꼬리표가 같은가
# 🔴 **이 줄은 바깥을 안 잰다** — 이 파일 안의 BK 와 DUMP_VER 가 **서로** 맞는지만 본다.
#    59번이 BK 는 v55 로 올리고 DUMP_VER 은 v54 로 두어 덤프가 엉뚱한 이름으로 쌓였다.
# 🔴 [실측 2026-11-18] 여기가 「compose 사본은 **v** 인데 덤프는 v58 다」로 **가짜 ✗**
#    를 냈다. 까닭은 잣대였다 — grep -o 'v[0-9]*' 는 별표라 **숫자 0개도 맞는다.**
#    BK 가 /volume1/… 로 시작하니 「volume1」의 **v** 가 먼저 걸렸다.
#    🔴 판 꼬리표는 **파일 이름 쪽에만** 있으므로 basename 을 먼저 떼고,
#       별표가 아니라 **더하기(한 자리 이상)**로 센다.
b1=$(basename "$BK" | grep -oE 'v[0-9]+' | head -1)
printf '    덤프 꼬리표 %s · compose 사본 이름 %s → 뽑은 꼬리표 [%s]\n' "$DUMP_VER" "$(basename "$BK")" "${b1:-못 뽑음}"
if [ -z "${b1:-}" ]; then
  unk "compose 사본의 판 꼬리표" "이름에서 v숫자 를 못 뽑았다 — 잣대를 보세요"
elif [ "$b1" = "$DUMP_VER" ]; then ok "덤프와 compose 사본의 판 꼬리표가 같다 ($DUMP_VER)"
else bad "compose 사본은 $b1 인데 덤프는 $DUMP_VER 다 — 59번이 이 자리를 놓쳤다"; fi

# 1-ㄱ. 🔴 운영이 지금 쓰는 태그 — 앱
say ""
say "── 1-ㄱ. 🔴 앱 — compose 의 image: 줄을 **통째로** 찍는다"
PHASE_APP_NEW=0; PHASE_APP_PRE=0; PHASE_APP_ODD=0; SITE_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  K=$(field "$r" 1); SVC=$(field "$r" 2); CN=$(field "$r" 3)
  NEW=$(field "$r" 4); OLD=$(field "$r" 5); PORT=$(field "$r" 7); NAME=$(field "$r" 8)
  SITE_SEEN=$((SITE_SEEN+1))
  ln=$(svc_image_line "$SVC")
  cur=$(printf '%s' "$ln" | awk '{print $2}')
  st=$(state_of "${cur:-}" "$OLD" "$NEW")
  case "$st" in
    NEW) PHASE_APP_NEW=$((PHASE_APP_NEW+1)) ;;
    PRE) PHASE_APP_PRE=$((PHASE_APP_PRE+1)) ;;
    *)   PHASE_APP_ODD=$((PHASE_APP_ODD+1)) ;;
  esac
  printf '      %-10s %-18s %-26s %s\n' "$NAME" "$SVC" "${cur:-없음}" "$st"
  if [ -z "${cur:-}" ]; then
    bad "$NAME — compose 에 $SVC 의 image: 줄이 **없다**"
    say "      🔴 **멈추고 알리세요.** 🔵 서비스 이름은 62-deploy.sh 가 쓴 값 그대로입니다."
  elif [ "$st" = "ODD" ]; then
    hm "$NAME 가 ${cur} 다 — 옛 $OLD 도 새 $NEW 도 아니다. **사람이 보세요**"
  fi
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  c=$(http_code "$PORT")
  printf '        상자 %-10s 도는 이미지 %-26s 127.0.0.1:%s → %s\n' "${s:-없음}" "${i:-}" "$PORT" "${c:-못 읽음}"
  if [ "${s:-}" = running ]; then ok "$NAME 상자가 돈다"
  else bad "$NAME 상자가 ${s:-없음} 다 — 배포 전에 이미 멈춰 있다"; fi
  if http_ok "${c:-}"; then ok "$NAME 가 답한다 ($c — 3xx 는 로그인으로 보내는 것이다)"
  else bad "$NAME 가 $c 를 돌려준다 — 200 이나 3xx 를 기대했다"; fi
done <<ENDSITE1
$(rows_of "$SITES")
ENDSITE1
# 🔴 **표본이 비어서 공짜로 통과하지 않게** 한다. 🔵 이번 판도 1 이 기대값이다 —
#    「1이니 뜻이 없다」가 아니라, 표가 깨져 **0바퀴**를 돌아도 ✗ 0 으로 통과하는
#    것을 막는 자리다.
[ "$SITE_SEEN" = "$SITES_WANT" ] && ok "앱 ${SITES_WANT}곳을 다 봤다 (표본이 비지 않았다)" \
  || bad "앱을 ${SITE_SEEN}곳만 봤다 — ${SITES_WANT}곳을 기대했다. SITES 표가 깨졌다"
say "앱 단계 — 새 판 ${PHASE_APP_NEW} · 옛 판 ${PHASE_APP_PRE} · 그 밖 ${PHASE_APP_ODD}"

# 1-ㄴ. 도구 하나
say ""
say "── 1-ㄴ. 🔴 도구 — **--tools 가 이 줄을 간다**"
say "🔴 마이그레이션이 0건인데도 도구를 가는 까닭이 **둘**입니다:"
say "   ㄴ) tools 가 담는 것 중 바뀐 파일이 **15 중 12** 입니다(빠진 셋은 tests/ 이고"
say "       .dockerignore 가 막습니다)."
say "   ㄷ) 🔴 **도구가 부르는 모듈이 이번 범위에 있습니다** —"
say "       scripts/import-workbook.ts 와 scripts/seed-demo-legacy.ts 가"
say "       src/db/schema/app-settings.ts 를 import 합니다. 도구를 안 갈면 그 둘이"
say "       **옛 몸통**으로 돕니다. 🔵 67·68번은 이 잣대가 **두 판 연속** 안 걸렸습니다."
PHASE_TOOL_NEW=0; PHASE_TOOL_PRE=0; TOOL_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  SVC=$(field "$r" 2); NEW=$(field "$r" 3); OLD=$(field "$r" 4)
  NAME=$(field "$r" 6); WHY=$(field "$r" 7)
  TOOL_SEEN=$((TOOL_SEEN+1))
  cur=$(svc_image "$SVC")
  st=$(state_of "${cur:-}" "$OLD" "$NEW")
  case "$st" in NEW) PHASE_TOOL_NEW=$((PHASE_TOOL_NEW+1)) ;; PRE) PHASE_TOOL_PRE=$((PHASE_TOOL_PRE+1)) ;; esac
  printf '      %-10s %-18s %-26s %s\n' "$NAME" "$SVC" "${cur:-없음}" "$st"
  printf '        왜 가는가: %s\n' "$WHY"
  if [ -z "${cur:-}" ]; then
    bad "$NAME — compose 에 $SVC 가 **없다**"
  elif [ "$st" = "ODD" ]; then
    hm "$NAME 가 ${cur} 다 — 옛 $OLD 도 새 $NEW 도 아니다. 사람이 보세요"
  fi
done <<ENDTOOL1
$(rows_of "$TOOLS")
ENDTOOL1
[ "$TOOL_SEEN" = "$TOOLS_WANT" ] && ok "도구 ${TOOLS_WANT}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "도구를 ${TOOL_SEEN}개만 봤다 — ${TOOLS_WANT}개를 기대했다"
say "도구 단계 — 새 판 ${PHASE_TOOL_NEW} · 옛 판 ${PHASE_TOOL_PRE}"

# 🔴 단계를 정한다 — 가지를 나누는 변수다.
if [ "$PHASE_APP_NEW" = "$SITES_WANT" ] && [ "$PHASE_TOOL_NEW" = "$TOOLS_WANT" ]; then PHASE=POST
elif [ "$PHASE_APP_PRE" = "$SITES_WANT" ] && [ "$PHASE_TOOL_PRE" = "$TOOLS_WANT" ]; then PHASE=PRE
elif [ "$PHASE_APP_PRE" = "$SITES_WANT" ] && [ "$PHASE_TOOL_NEW" = "$TOOLS_WANT" ]; then PHASE=MID
else PHASE=ODD; fi
printf '\n  🔴 **지금 단계: %s**\n' "$PHASE"
case "$PHASE" in
  PRE)  say "아직 아무것도 안 갈아 끼웠습니다 — --preload 부터 가세요." ;;
  MID)  say "🔴 **--tools 까지 돌았습니다**(도구만 새 판). 다음은 --go 입니다."
        say "   🔵 --go 뒤에 --rollback 으로 앱만 되돌린 상태도 여기 보입니다 —"
        say "      🔴 **이번 판은 DB 가 안 바뀌므로 그 둘을 DB 로 가를 수 없습니다.**"
        say "      가르려면 **로그 파일 이름**(deploy65-go-… / deploy65-rollback-…)을 보세요." ;;
  POST) say "--go 까지 돌았습니다. --count 로 뒤의 수를 재세요." ;;
  ODD)  hm "단계가 섞여 있습니다 — 위 표를 사람이 보세요. **막지는 않습니다.**" ;;
esac

# 1-ㄷ. 🔴 안 건드리는 **아홉** — 「옆으로 안 샜다」는 증거
say ""
say "── 1-ㄷ. 🔴 안 건드리는 **아홉** — 도는가 · 어느 이미지인가 · 언제 켜졌는가"
say "🔴🔴 **이번 판의 아홉에는 dss-as 가 들어 있고 dss-inventory 가 빠집니다** —"
say "   68번과 **정확히 반대**입니다. 한 자리만 안 바꾸면 배포 직후 ✗ 가 터집니다."
say "🔴 **상자가 도는가만 보지 않습니다** — 이미지와 켜진 때를 **적어 두고 끝에서**"
say "   **맞댑니다.** 2026-11-18 에 ✗ 가 바로 그 자리에서 났습니다(DB 가 Recreate 됐다)."
say "🔵 **박아 둔 시각이 한 글자도 없습니다** — 여기서 찍은 값을 끝에서 맞댑니다."
KEEP_SEEN=0
KEEP_SNAP=""
for c in $KEEP_BOXES; do
  KEEP_SEEN=$((KEEP_SEEN+1))
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
  t=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s %-26s 켜진 때 %s\n' "$c" "${s:-없음}" "${i:-}" "${t:-}"
  [ "${s:-}" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
  KEEP_SNAP="$KEEP_SNAP$c|${i:-없음}|${t:-없음}
"
done
[ "$KEEP_SEEN" = "$KEEP_BOXES_WANT" ] && ok "안 건드리는 ${KEEP_BOXES_WANT}곳을 다 봤다 (표본이 비지 않았다)" \
  || bad "안 건드리는 상자를 ${KEEP_SEEN}개만 봤다 — ${KEEP_BOXES_WANT}개를 기대했다"
DB_SEEN=0
for c in $KEEP_DB; do
  DB_SEEN=$((DB_SEEN+1))
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  t=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s 켜진 때 %s\n' "$c" "${s:-없음}" "${t:-}"
  [ "${s:-}" = running ] || bad "$c 가 안 돈다 — DB 가 멈춰 있다"
done
[ "$DB_SEEN" = "$KEEP_DB_WANT" ] && ok "DB 상자 ${KEEP_DB_WANT}개를 다 봤다" \
  || bad "DB 상자를 ${DB_SEEN}개만 봤다"
DBSTART_BEFORE=$("$DOCKER" inspect -f '{{.State.StartedAt}}' dss-pg-app 2>/dev/null)
DBSTART_BEFORE2=$("$DOCKER" inspect -f '{{.State.StartedAt}}' dss-pg-auth 2>/dev/null)
ok "DB 둘의 켜진 때를 적어 두었다 (끝에서 다시 봐 **안 멈췄다**는 증거로 쓴다)"

# 1-ㄹ. 설정 파일 — 중복 키와 auto (🔴 값은 한 글자도 안 찍는다)
say ""
say "── 1-ㄹ. 🔴 설정 파일 — 중복 줄과 auto (**값은 안 찍는다**)"
say "🔴 중복 줄은 **아래가 이깁니다** — 위를 고치고 아래에 또 적은 것이 원인입니다."
say "🔵 **inventory.env 가 이번 판의 집입니다** — 없으면 ⚠️ 가 아니라 사람이 봐야 합니다."
ENV_SEEN=0
for f in $ENV_NAS $ENV_FILES; do
  ENV_SEEN=$((ENV_SEEN+1))
  if [ ! -f "$f" ]; then hm "$(basename "$f") 가 없다 — 그 집을 아직 안 쓰는 것일 수 있다"; continue; fi
  d=$(grep -oE '^[A-Z_][A-Z0-9_]*=' "$f" 2>/dev/null | sort | uniq -d | tr '\n' ' ')
  if [ -z "${d:-}" ]; then ok "$(basename "$f") 중복 키 0"
  else bad "$(basename "$f") 에 중복 키가 있다: $d (🔴 **아래가 이긴다**)"; fi
  a=$(grep -cE '^[A-Z_][A-Z0-9_]*=auto$' "$f" 2>/dev/null || true)
  if [ "${a:-0}" = "0" ]; then ok "$(basename "$f") 에 auto 가 없다"
  else bad "$(basename "$f") 에 auto 가 ${a}줄 있다 — 🔴 컨테이너 안에서 auto 는 172.x 가 된다"; fi
done
say "본 설정 파일 ${ENV_SEEN}개 (없는 것은 ⚠️ 로만 셉니다)"
# 🔴 **이번 집의 설정 파일만은 따로 단언한다** — 「없어도 ⚠️」로 뭉개면 이 배포의
#    집이 설정 없이 돌고 있는 것을 놓친다.
if [ -f "$D/deploy/env/inventory.env" ]; then ok "inventory.env 가 있다 (이번 판의 집이다)"
else bad "inventory.env 가 **없다** — 🔴 이번 배포의 집인데 설정 파일이 없다. 사람이 보세요"; fi

# 1-ㅁ. 🔵 지난 판 묶음이 남아 있는가 — 🔴 **이 파일은 쳐다보지도 않는다**
say ""
say "── 1-ㅁ. 🔵 incoming 폴더 — 🔴 **재고는 묶음을 안 씁니다**"
say "🔴 A/S 는 .sql 이 **볼륨**에 있어 묶음으로 보냅니다. **재고는 도구 이미지 안**에"
say "   구워져 갑니다 — 이 배포본에는 묶음을 푸는 코드가 **한 줄도 없습니다.**"
say "   🔴 .sql 이 생기는 판에서는 **62번에서 되살리세요**(66번이 아닙니다 — 그것은 A/S 길입니다)."
mkdir -p "$INCOMING" 2>/dev/null; chmod 777 "$INCOMING" 2>/dev/null
ls -l "$INCOMING" 2>/dev/null | sed 's/^/        /'
if [ -f "$OLD_MIGTAR" ]; then
  hm "지난 판 묶음(as-migrations.tar.gz)이 남아 있습니다 — **이 배포본은 그것을 안 읽습니다**"
  say "      🔵 푸는 코드가 **한 줄도 없습니다.** 지워도 되고 둬도 됩니다."
  say "      🔴 **그것은 A/S 것입니다** — 재고와 아무 상관이 없습니다. 새로 보내지 마세요."
else
  ok "incoming 에 묶음이 없다 (이번 판은 쓸 일이 없다)"
fi

# ══════════════════════════════════════════════════════════════════════
# ── 2. 🔴 DB — **0건이다.** 「바뀌지 않았는가」를 잰다
# ══════════════════════════════════════════════════════════════════════
step "2. 🔴 DB — **마이그레이션 0건.** 「안 바뀌었는가」를 잰다"
say "🔴 **빼지 않는 까닭**: 빼면 「운영 DB 가 지금 몇 건인지」를 아무도 안 보게 되고,"
say "   그 수가 어긋나면 **이 배포와 무관한 다른 사고**인데 끝까지 모릅니다."
say "🔴 **재고는 28 입니다.** 27 로 두면 **멀쩡한 운영에서 ✗** 가 나고, 그 ✗ 는"
say "   진짜 사고처럼 보입니다(쉰여덟째가 0026·0027 을 올려 28 이 됐습니다)."

# 2-ㄱ. 다섯 집의 마이그레이션 수 — **바뀌면 안 된다**
say ""
say "── 2-ㄱ. 🔴 마이그레이션 수 — **다섯 집이 전과 같아야 한다**"
MIGK_SEEN=0; MIGK_OK=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  BOX=$(field "$r" 2); DB=$(field "$r" 3); WANT=$(field "$r" 4); NAME=$(field "$r" 5)
  MIGK_SEEN=$((MIGK_SEEN+1))
  v=$(mig_count "$BOX" "$DB")
  printf '      %-10s %-14s %-16s 지금 %-5s (기대 %s — **이번 판은 0건**)\n' "$NAME" "$BOX" "$DB" "${v:-못 읽음}" "$WANT"
  if [ -z "${v:-}" ]; then
    unk "$NAME 마이그레이션 수" "$BOX 가 도는지, 그 DB 가 있는지 보세요"
  elif [ "$v" = "$WANT" ]; then MIGK_OK=$((MIGK_OK+1)); ok "$NAME 가 $WANT 그대로다"
  else
    bad "$NAME 가 ${v} 다 — $WANT 를 기대했다. 🔴 **이 배포와 무관한 다른 사고다**"
    say "      🔴 이 배포본은 마이그레이션을 **한 건도 올리지 않습니다.** 수가 달라졌다면"
    say "         누가 다른 길로 올렸다는 뜻입니다. **멈추고 사람이 보세요.**"
    doubt
  fi
done <<ENDMIGK
$(rows_of "$MIGS_KEEP")
ENDMIGK
say "본 집 ${MIGK_SEEN} · 같은 집 ${MIGK_OK} (기대 $MIGS_KEEP_WANT · $MIGS_KEEP_WANT)"
if [ "$MIGK_SEEN" = "$MIGS_KEEP_WANT" ] && [ "$MIGK_OK" = "$MIGS_KEEP_WANT" ]; then
  ok "다섯 집의 마이그레이션 수가 **전부 그대로다** (표본이 비지 않았다)"
  DBKEEP=KEEP
else
  bad "본 집 ${MIGK_SEEN} · 같은 집 ${MIGK_OK} 다 — ${MIGS_KEEP_WANT} 을 기대했다"
  DBKEEP=ODD
fi
printf '\n  🔴 **DB 상태: %s** (KEEP = 다섯 집이 다 전과 같다)\n' "$DBKEEP"
say "🔴 **승인함은 여기에 없습니다** — DB 가 아예 없는 집이라 select 를 한 줄도 안"
say "   던집니다. 던졌으면 전부 ✗ 가 났을 것입니다."

# 2-ㄴ. 🔴 쉰여덟째가 만든 표 넷 — **뒷걸음 방지**
say ""
say "── 2-ㄴ. 🔴 **쉰여덟째가 만든 표 넷이 아직 있는가** (뒷걸음 방지)"
KT_SEEN=0; KT_OK=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  BOX=$(field "$r" 1); DB=$(field "$r" 2); T=$(field "$r" 3); NAME=$(field "$r" 4)
  KT_SEEN=$((KT_SEEN+1))
  n=$(has_table "$BOX" "$DB" "$T")
  rows=""
  [ "${n:-0}" = "1" ] && rows=$(table_rows "$BOX" "$DB" "$T")
  printf '      %-10s %-34s 있나 %-3s 줄 %s\n' "$NAME" "$T" "${n:-?}" "${rows:-–}"
  if [ -z "${n:-}" ]; then unk "$NAME 의 $T" "$BOX 가 도는지 보세요"
  elif [ "$n" = "1" ]; then KT_OK=$((KT_OK+1)); ok "$NAME 에 $T 가 **그대로 있다** (${rows:-?}줄)"
  else bad "$NAME 에 $T 가 **없다** — 🔴 쉰여덟째가 올린 표가 사라졌다. 멈추고 알릴 것"; fi
done <<ENDKT
$(rows_of "$KEEP_TABLES")
ENDKT
say "본 표 ${KT_SEEN} · 있는 표 ${KT_OK} (기대 $KEEP_TABLES_WANT · $KEEP_TABLES_WANT)"
[ "$KT_SEEN" = "$KEEP_TABLES_WANT" ] && [ "$KT_OK" = "$KEEP_TABLES_WANT" ] \
  && ok "쉰여덟째의 표 넷이 다 있다 (뒷걸음친 DB 가 아니다)" \
  || bad "본 표 ${KT_SEEN} · 있는 표 ${KT_OK} 다 — ${KEEP_TABLES_WANT} 을 기대했다"
say "🔵 **줄 수가 0 이어도 정상입니다** — 위임을 아직 아무도 안 맡겼을 수 있습니다."

# 2-ㄷ. 🔴 재고 마이그레이션 — **도구 이미지 안**에 28장이어야 한다
say ""
say "── 2-ㄷ. 🔴 재고 마이그레이션은 **도구 이미지 안**에 있다 (A/S 와 정반대다)"
say "🔴 A/S 는 **볼륨**이 정본이라 도구 이미지 안이 **비어 있어야** 합니다."
say "   🔴 **재고는 이미지가 정본입니다** — /app/drizzle 에 **${INV_IMG_SQL_WANT}장**이 들어 있어야 합니다."
say "   🔴 68번의 그 절을 그대로 베끼면 **멀쩡한 재고 도구가 ✗** 가 납니다."
say "🔵 **--preload 전에도 뒤에도 기대값이 같습니다** — 옛 판(:4)도 ${INV_IMG_SQL_WANT}장이기 때문입니다."
IVT=$(svc_image tools-inventory)
if [ -n "${IVT:-}" ] && "$DOCKER" image inspect "$IVT" >/dev/null 2>&1; then
  n=$(dock "$IVT" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
  j=$(dock "$IVT" -c "grep -c 'idx' $IMG_MIGDIR/meta/_journal.json 2>/dev/null"); j=$(printf '%s' "$j" | tr -d ' ')
  nx=$(dock "$IVT" -c "ls $IMG_MIGDIR/${INV_IMG_NEXT}_*.sql 2>/dev/null | wc -l"); nx=$(printf '%s' "$nx" | tr -d ' ')
  printf '      재고 도구 이미지(%s) — .sql %s장 · journal idx %s개 · %s %s개(기대 0)\n' \
    "$IVT" "${n:-?}" "${j:-?}" "$INV_IMG_NEXT" "${nx:-?}"
  if [ "${n:-x}" = "$INV_IMG_SQL_WANT" ] && [ "${j:-x}" = "$INV_IMG_SQL_WANT" ]; then
    ok "도구 이미지 안이 **${INV_IMG_SQL_WANT}장**이고 목록도 ${INV_IMG_SQL_WANT}개다"
  else
    bad "도구 이미지 안이 .sql ${n:-?} · idx ${j:-?} 다 — ${INV_IMG_SQL_WANT} 을 기대했다"
    say "      🔴 **.sql 과 idx 가 다르면** 목록에 없는 파일이 있다는 뜻이고,"
    say "         drizzle 이 그것을 **아예 모릅니다**(적용이 0건으로 조용히 끝납니다)."
    doubt
  fi
  [ "${nx:-1}" = "0" ] && ok "이미지에 $INV_IMG_NEXT 이 없다 (마지막이 $INV_IMG_LAST 그대로 — 이 배포는 **0건**이다)" \
    || bad "이미지에 $INV_IMG_NEXT 이 **있다** — 이 배포본은 $INV_IMG_LAST 까지를 전제로 쓰였다. 멈추고 알릴 것"
else
  unk "재고 도구 이미지 안" "${IVT:-태그를 못 읽음} 가 NAS 에 아직 없다 (--preload 전이면 정상)"
fi

# 2-ㄹ. 🔵 A/S 볼륨 — **안 건드리는 집이 뒷걸음치지 않았는가**
say ""
say "── 2-ㄹ. 🔵 A/S 마이그레이션 **볼륨** — 🔴 **이번 판과 상관이 없지만 안 뺀다**"
say "🔵 A/S 는 안 건드리는 아홉 중 하나입니다. 여기서 보는 것은 **뒷걸음**입니다 —"
say "   볼륨이 ${AS_VOL_SQL_WANT}장 그대로인가. 줄었으면 **이 배포와 무관한 다른 사고**입니다."
VOL_SEEN=0
if [ -d "$AS_MIGDIR" ]; then
  VOL_SEEN=$((VOL_SEEN+1))
  vs=$(ls -1 "$AS_MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  vj=$(grep -o '"idx"' "$AS_MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  vnx=$(ls -1 "$AS_MIGDIR/${AS_VOL_NEXT}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  printf '      볼륨 %s — .sql %s장 · journal idx %s개 · %s %s개(기대 0)\n' \
    "$AS_MIGDIR" "${vs:-?}" "${vj:-?}" "$AS_VOL_NEXT" "${vnx:-?}"
  if [ "${vs:-x}" = "$AS_VOL_SQL_WANT" ] && [ "${vj:-x}" = "$AS_VOL_SQL_WANT" ]; then
    ok "A/S 볼륨이 **${AS_VOL_SQL_WANT}장**이고 목록도 ${AS_VOL_SQL_WANT}개다 (안 건드리는 집이 그대로다)"
  else
    bad "A/S 볼륨이 .sql ${vs:-?} · idx ${vj:-?} 다 — ${AS_VOL_SQL_WANT} 을 기대했다"
    doubt
  fi
  [ "${vnx:-1}" = "0" ] && ok "A/S 볼륨에 $AS_VOL_NEXT 이 없다" \
    || hm "A/S 볼륨에 $AS_VOL_NEXT 이 있다 — 🔵 이 배포와 무관합니다. 사람이 보세요"
else
  bad "A/S 마이그레이션 볼륨이 없다 — $AS_MIGDIR"
fi
[ "$VOL_SEEN" = "1" ] && ok "A/S 볼륨을 봤다" || bad "A/S 볼륨을 못 봤다"

# ══════════════════════════════════════════════════════════════════════
# ── 3. 들여올 tar **둘** ─────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════
step "3. 들여올 tar 둘 — **옮기다 깨졌는가** (🔵 묶음은 없다)"
say "🔴 지문은 **굽는 쪽에서 잰 값**입니다. NAS 에서 재서 채우면 자기가 잰 값으로"
say "   자기를 재는 꼴이 되어 **영영 통과합니다.**"
say "🔴 **재고의 .sql 은 도구 tar 안에 들어 있습니다** — 따로 보낼 묶음이 없습니다."
TAR_SEEN=0; TAR_OK=0; TAR_BLANK=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  T=$(field "$r" 1); WSZ=$(field "$r" 2); WM5=$(field "$r" 3)
  TAR_SEEN=$((TAR_SEEN+1))
  P="$IMGD/$T"
  if [ ! -f "$P" ]; then
    case "$MODE" in
      --check|--count|--rollback) unk "$T" "아직 $IMGD 에 없다 (--preload 전이면 정상)" ;;
      *) bad "$T 가 $IMGD 에 **없다** — scp 로 보내셨나요"; say "      scp -O $T dss-nas:$IMGD/" ;;
    esac
    continue
  fi
  sz=$(stat -c %s "$P" 2>/dev/null)
  m5=$(md5sum "$P" 2>/dev/null | awk '{print $1}')
  printf '      %-30s %s바이트  md5 %s\n' "$T" "${sz:-?}" "${m5:-?}"
  if [ -z "${WSZ:-}" ] || [ -z "${WM5:-}" ]; then
    TAR_BLANK=$((TAR_BLANK+1))
    case "$MODE" in
      --check|--count|--rollback) unk "$T 의 지문" "TARS 표가 **비어 있다** — 굽고 나서 채우세요" ;;
      *) bad "$T 의 지문이 TARS 표에 **비어 있다** — 굽기 꼬리말의 두 줄을 채우세요" ;;
    esac
    continue
  fi
  if [ "${sz:-x}" = "$WSZ" ] && [ "${m5:-x}" = "$WM5" ]; then
    TAR_OK=$((TAR_OK+1)); ok "$T 크기와 md5 가 구울 때와 같다"
  else
    bad "$T 가 다르다 — 크기 ${sz:-?} (기대 $WSZ) · md5 ${m5:-?} (기대 $WM5)"
    say "      🔴 **옮기다 깨졌거나 옛 판을 보냈습니다.** 다시 보내세요."
  fi
done <<ENDTAR1
$(rows_of "$TARS")
ENDTAR1
[ "$TAR_SEEN" = "$TARS_WANT" ] && ok "tar ${TARS_WANT}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "tar 을 ${TAR_SEEN}개만 봤다 — ${TARS_WANT}개를 기대했다. TARS 표가 깨졌다"
if [ "$TAR_BLANK" != "0" ]; then
  printf '\n  🔴🔴🔴 **TARS 표가 %s줄 비어 있습니다.**\n' "$TAR_BLANK"
  say "   69-build.sh --go 가 꼬리말에 찍어 주는 **두 줄**을 이 파일의 TARS 에 그대로"
  say "   붙여 넣은 **뒤에** scp 하세요. 쉰세째에는 빈 표가 그대로 올라가 --preload 가"
  say "   ✗ 둘로 멈췄습니다."
fi

# ══════════════════════════════════════════════════════════════════════
# ── 4. 🔵 이번 판과 무관하지만 **빼지 않는** 검사들 ──────────────────
# ══════════════════════════════════════════════════════════════════════
step "4. 🔵 빼지 않는 검사 — 한 번 빼면 다시 넣는 사람이 없다"
say "🔵 넷 다 **A/S 쪽 자리**입니다 — 이번 판과 상관이 없습니다. 🔴 그래도 안 뺐습니다."
say "   이제 이 넷은 **「안 건드리는 집이 멀쩡한가」**를 보는 뜻이 됩니다."
# 4-ㄱ. 🔵 연락서 폴더
say ""
say "── 4-ㄱ. 연락서 폴더 — 🔵 **A/S 가 늘 쓰는 자리**다"
AST=$(svc_image tools-as)
if [ -n "${AST:-}" ] && "$DOCKER" image inspect "$AST" >/dev/null 2>&1; then
  v=$(dct run --rm --entrypoint sh tools-as -c "printf '%s %s\n' \"\$(ls $KYO_SRC 2>/dev/null | wc -l)\" \"\$(ls $KYO_CONV 2>/dev/null | wc -l)\"" 2>/dev/null | tr -d '\r' | tail -1)
  a=$(printf '%s' "$v" | awk '{print $1}'); b=$(printf '%s' "$v" | awk '{print $2}')
  printf '      %s %s개(기대 %s 이상) · %s %s개(기대 %s 이상)\n' "$KYO_SRC" "${a:-?}" "$KYO_SRC_MIN" "$KYO_CONV" "${b:-?}" "$KYO_CONV_MIN"
  if isnum "${a:-}" && [ "${a:-0}" -ge "$KYO_SRC_MIN" ] 2>/dev/null; then ok "연락서 원본 폴더가 **실제로 열린다** (${a}개)"
  else bad "연락서 원본 폴더가 ${a:-못 읽음}개다 — ACL 때문에 안 열릴 수 있다(group_add 100)"; fi
  if isnum "${b:-}" && [ "${b:-0}" -ge "$KYO_CONV_MIN" ] 2>/dev/null; then ok "변환본 폴더가 열린다 (${b}개)"
  else hm "변환본 폴더가 ${b:-못 읽음}개다 — 사람이 보세요"; fi
else
  unk "연락서 폴더" "A/S 도구 이미지를 아직 못 쓴다"
fi
# 4-ㄴ. 🔵 양식 폴더가 그대로 있는가 (이번 판은 양식을 **한 장도 안 올린다**)
say ""
if [ -d "$TPLDIR" ]; then
  n=$(find "$TPLDIR" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
  printf '      %s 안 파일 %s개 (이번 판은 양식을 **한 장도 안 올린다**)\n' "$TPLDIR" "${n:-?}"
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then ok "양식 폴더가 그대로 있다 (${n}장)"
  else bad "양식 폴더가 비었다 — A/S 의 견적서·보고서 출력이 통째로 죽는다"; fi
else
  bad "양식 폴더가 없다 — $TPLDIR"
fi
# 4-ㄷ. 🔴 PO 가 repair_cases 에 쓸 수 있는가 — PO 를 안 건드려도 잰다
say ""
say "── 4-ㄷ. 🔴 PO 의 쓰기 권한 — PO 를 안 건드려도 잰다"
say "🔵 **이번 판은 PO 가 모르는 것을 늘리지 않습니다** — 재고관리와 PO 는 DB 도 표도"
say "   안 겹칩니다(PO 는 dss_as 를 봅니다). 그래도 **빼지 않습니다.**"
role=$("$DOCKER" exec "$PO_APP_CN" sh -c 'printf "%s" "$DATABASE_URL"' </dev/null 2>/dev/null | sed -n 's|^[a-z]*://\([^:]*\):.*|\1|p')
if [ -n "${role:-}" ]; then
  say "PO 가 쓰는 역할 이름: $role (🔴 비밀값은 안 찍습니다)"
  u=$(pgq dss-pg-app dss_as "select has_table_privilege('$role','$PO_WRITE_TABLE','UPDATE')")
  s=$(pgq dss-pg-app dss_as "select has_table_privilege('$role','$PO_WRITE_TABLE','SELECT')")
  printf '      %s 에 UPDATE %s · SELECT %s\n' "$PO_WRITE_TABLE" "${u:-?}" "${s:-?}"
  if [ "${u:-}" = "t" ] || [ "${s:-}" = "t" ]; then
    ok "PO 의 권한을 값으로 쟀다 (UPDATE ${u:-?} · SELECT ${s:-?})"
  else
    hm "PO 의 권한을 못 쟀거나 둘 다 f 다 — 사람이 보세요"
  fi
else
  unk "PO 의 역할 이름" "$PO_APP_CN 안에서 DATABASE_URL 을 못 읽었다"
fi
# 4-ㄹ. 🔵 발주서 공유폴더
say ""
if [ -n "${AST:-}" ] && "$DOCKER" image inspect "$AST" >/dev/null 2>&1; then
  n=$(dct run --rm --entrypoint sh tools-as -c "ls $PO_ARCHIVE 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r' | tail -1)
  printf '      %s 안 %s개\n' "$PO_ARCHIVE" "${n:-?}"
  if isnum "${n:-}" && [ "${n:-0}" -ge 1 ] 2>/dev/null; then ok "발주서 공유폴더가 열린다 (${n}개)"
  else hm "발주서 공유폴더가 ${n:-못 읽음}개다 — 이번 범위와 무관해 ⚠️ 로만 셉니다"; fi
else
  unk "발주서 공유폴더" "A/S 도구 이미지를 아직 못 쓴다"
fi

# ══════════════════════════════════════════════════════════════════════
# ── --count : 🔴 **이 배포가 보여 주는 것이 달라지는 자리를 센다** ────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **68번의 --count 를 통째로 갈았다.** 그것은 내자 줄·견적서 결재를 셌다 —
#      이번 판과 **상관이 없다.** 그대로 두면 이 배포를 재는 숫자가 **하나도 없다.**
#   🔴 **참고값이 하나도 없다** — 재고를 세는 --count 는 **이 판이 처음**이다.
#      지어내지 않았다. 올리기 전에 잰 수를 적어 두면 다음 판이 쓸 참고값이 된다.
#   🔴 **이 배포는 자료를 한 글자도 안 바꾼다.** 그래서 이 모드의 뜻은
#      **「전과 후가 같은가」**다. 🔵 두 번 돌려 같은 수가 나오는 것이 정상이다.
#   🔴 표·칸 이름은 전부 **스키마에서 확인한 것**이다. 지어내지 않았다.
effect_counts() {
  step "🔢 이 배포가 **보여 주는 것**이 달라지는 자리 — 세기만 한다 (전부 select)"
  say "🔵 이 배포는 **보이는 쪽 기능**입니다 — 자료를 한 글자도 안 바꿉니다."
  say "   그래서 **전과 후의 수가 같아야 정상**입니다."
  say "🔴 **참고값이 하나도 없습니다** — 재고를 세는 --count 는 이 판이 처음입니다."
  say "   🔴 ✗ 를 내는 것은 **잣대가 살아 있는가**를 보는 줄 둘뿐입니다(②·⑤)."

  local live total drawn nodraw keyn trans probe r1 r2 nc rr pt c

  # ── ① 🔴🔴 **이 배포가 올리는 바로 그것** — 도번이 적힌 부품이 몇 개인가
  say ""
  say "── ① 🔴🔴 **도번이 적힌 부품** — 새 줄이 서는 자리"
  say "🔴 **도번이 빈 부품에서는 그 줄이 통째로 안 섭니다**(「빈 칸은 안 그린다」)."
  say "   그래서 이 수가 **화면에서 달라지는 줄의 수**입니다."
  say "🔵 $PARTS_DRAWING_COL 은 **NOT NULL 이고 기본값이 빈 글자**입니다 — null 이 아니라"
  say "   **빈 글자가 「없음」**입니다. 🔴 is not null 로 세면 **전부 걸려** 거짓이 됩니다."
  say "🔵 휴지통(is_deleted)은 뺍니다 — 지워진 부품은 화면에 안 뜹니다."
  nc=$(has_column "$CNT_BOX" "$CNT_DB" "$PARTS_TABLE" "$PARTS_DRAWING_COL")
  printf '      %s 에 %s 칸이 있나: %s (기대 1)\n' "$PARTS_TABLE" "$PARTS_DRAWING_COL" "${nc:-?}"
  if [ -z "${nc:-}" ]; then
    unk "$PARTS_DRAWING_COL 칸" "못 쟀다 — $CNT_BOX 가 도는지 보세요"
  elif [ "$nc" != "1" ]; then
    bad "**그 칸이 없습니다** — 🔴 이 배포가 그리려는 값이 DB 에 없습니다. 멈추고 알리세요"
    doubt
  else
    live=$(pgn "$CNT_BOX" "$CNT_DB" "select count(*) from $PARTS_TABLE where is_deleted = false")
    drawn=$(pgn "$CNT_BOX" "$CNT_DB" "select count(*) from $PARTS_TABLE where is_deleted = false and $PARTS_DRAWING_COL <> ''")
    nodraw=$(pgn "$CNT_BOX" "$CNT_DB" "select count(*) from $PARTS_TABLE where is_deleted = false and $PARTS_DRAWING_COL = ''")
    printf '      휴지통 밖 부품 %s개 · 도번이 적힌 것 %s개 · 빈 것 %s개 (참고값 없음)\n' \
      "${live:-?}" "${drawn:-?}" "${nodraw:-?}"
    if [ -z "${live:-}" ] || [ -z "${drawn:-}" ] || [ -z "${nodraw:-}" ]; then
      bad "셋 중 못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
    else
      ok "도번이 적힌 부품을 값으로 쟀다 (${drawn}개 — **그 부품들에서만 새 줄이 선다**)"
      say "      🔵 0 이어도 정상입니다 — 그때는 **눈 확인을 하려면 도번을 하나 적어야** 합니다."
      # 🔴 **덮기 관문** — 적힌 것 + 빈 것 == 휴지통 밖. 한쪽 질의가 조용히 거절되면
      #    여기서 울린다. 🔵 이 칸은 NOT NULL 이라 셋이 정확히 맞아야 한다.
      printf '      관문) 적힌 것 %s + 빈 것 %s = %s (휴지통 밖 %s)\n' \
        "$drawn" "$nodraw" "$((drawn + nodraw))" "$live"
      if [ "$((drawn + nodraw))" = "$live" ]; then
        ok "적힌 것 + 빈 것 == 휴지통 밖 (${live}) — **세는 잣대가 살아 있다**"
      else
        bad "둘을 더하면 $((drawn + nodraw)) 다 — 휴지통 밖 ${live} 를 기대했다"
        say "      🔴 **질의 하나가 조용히 거절됐거나 그 칸이 NULL 을 받기 시작했습니다.**"
        doubt
      fi
    fi
  fi

  # ── ② 🔴 **세는 잣대가 살아 있는가** — 없는 값을 함께 묻는다
  say ""
  say "── ② 🔴 **없는 값을 함께 묻는다** — 「무조건 0」인 질의인지 가른다"
  probe=$(pgn "$CNT_BOX" "$CNT_DB" "select count(*) from $PARTS_TABLE where is_deleted = false and $PARTS_DRAWING_COL = '__dss_probe_no_such_drawing__'")
  printf '      없는 도번으로 물었을 때: %s개 (기대 0)\n' "${probe:-?}"
  [ "${probe:-x}" = "0" ] && ok "부품을 세는 잣대가 **살아 있다** (① 의 수를 믿을 수 있다)" \
    || bad "없는 도번을 물었는데 ${probe:-?} 가 나왔다 — **질의가 깨졌다.** ① 도 못 믿는다"

  # ── ③ 🔵 부품 요청 줄 — **그 줄이 실제로 보이는 화면에 자료가 있는가**
  say ""
  say "── ③ 🔵 **부품 요청·승인 줄** — 새 줄이 실제로 눈에 띄는 자리에 자료가 있는가"
  say "🔵 화면 셋이 같은 조각을 씁니다 — [부품 요청 관리] · [승인 요청건] · 불출 신청 팝업."
  say "🔴 **이 수가 0 이면 눈 확인을 할 거리가 없습니다** — 그때는 신청을 하나 넣어야 합니다."
  say "🔴 ✗ 는 안 냅니다 — 사람이 신청을 넣고 처리하면 정상적으로 달라집니다."
  r1=$(pgn "$CNT_BOX" "$CNT_DB" "select count(*) from $KEEPTBL2")
  printf '      %s 줄 %s개 (참고값 없음)\n' "$KEEPTBL2" "${r1:-?}"
  if [ -z "${r1:-}" ]; then
    hm "못 쟀습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 그 표가 있는지 보세요"
  else
    ok "승인 단계 줄을 값으로 쟀다 (${r1}개)"
    say "      🔵 0 이어도 정상입니다 — 올라가 있는 신청이 없다는 뜻입니다."
  fi

  # ── ④ 🔵 뒷걸음 — 쉰여덟째가 올린 위임 표
  say ""
  say "── ④ 🔵 **뒷걸음** — 쉰여덟째가 올린 위임 표 (이 배포는 한 줄도 안 넣는다)"
  r2=$(pgn "$CNT_BOX" "$CNT_DB" "select count(*) from $KEEPTBL1")
  printf '      %s 줄 %s개 (참고값 없음 · 0 이어도 정상)\n' "$KEEPTBL1" "${r2:-?}"
  if [ -z "${r2:-}" ]; then
    hm "못 쟀습니다 — 2-ㄴ 에서 그 표가 **있다**고 나왔는지 보세요"
  else
    ok "위임 표 줄을 값으로 쟀다 (${r2}개 — 배포 전후로 같아야 한다)"
  fi

  # ── ⑤ 🔴🔴 **고른 모양이 저장돼 있는가** — 배포 직후에는 0줄이 정상
  say ""
  say "── ⑤ 🔴🔴 **[도번 표시] 에서 고른 모양** — app_settings 의 열쇠 하나"
  say "🔴 **배포 직후에는 0줄이 정상입니다** — 사람이 [설정] → [도번 표시] 에서"
  say "   [저장]을 눌러야 줄이 생깁니다. 그 전까지는 **코드의 기본값**이 그대로 섭니다."
  say "🔴 **마이그레이션이 0건인 까닭이 여기 있습니다** — 이 표는 「열쇠 하나에 글자"
  say "   하나」 꼴이라 **열쇠만 더하면** 됩니다. 칸도 표도 안 더합니다."
  say "🔵 **눈 확인 뒤에는 1줄이 됩니다** — 그것이 정상이고 되돌려도 그 줄은 남습니다."
  keyn=$(pgn "$CNT_BOX" "$CNT_DB" "select count(*) from $SETTINGS_TABLE where key = '$SETTING_KEY_STYLE'")
  trans=$(pgn "$CNT_BOX" "$CNT_DB" "select count(*) from $SETTINGS_TABLE where key = '$SETTING_KEY_TRANSITION'")
  printf '      %s 의 [%s] %s줄 (배포 직후 기대 0) · [%s] %s줄 (표본이 비지 않았다는 증거)\n' \
    "$SETTINGS_TABLE" "$SETTING_KEY_STYLE" "${keyn:-?}" "$SETTING_KEY_TRANSITION" "${trans:-?}"
  if [ -z "${keyn:-}" ]; then
    hm "못 쟀습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** $SETTINGS_TABLE 이 있는지 보세요"
  elif [ "${keyn}" = "0" ]; then
    ok "아직 아무도 모양을 저장하지 않았다 (0줄 — **코드의 기본값이 그대로 선다**)"
  else
    hm "모양이 **${keyn}줄 저장돼 있습니다** — 🔵 누가 이미 [저장]을 눌렀다는 뜻입니다"
    say "      🔵 ✗ 가 아닙니다. 올린 **뒤**라면 정상이고, 올리기 **전**이라면 이상합니다"
    say "         (그 화면이 아직 없기 때문입니다 — 그때는 사람이 보세요)."
    pgrows "$CNT_BOX" "$CNT_DB" "select key || ' | ' || value || ' | ' || updated_by_name from $SETTINGS_TABLE where key = '$SETTING_KEY_STYLE'" | sed 's/^/        /'
  fi
  # 🔴 **없는 열쇠를 함께 묻는다** — 「무조건 0」인 질의인지 가른다.
  probe=$(pgn "$CNT_BOX" "$CNT_DB" "select count(*) from $SETTINGS_TABLE where key = '__dss_probe_no_such_key__'")
  printf '      없는 열쇠로 물었을 때: %s개 (기대 0)\n' "${probe:-?}"
  [ "${probe:-x}" = "0" ] && ok "설정 열쇠를 세는 잣대가 **살아 있다** (위 수를 믿을 수 있다)" \
    || bad "없는 열쇠를 물었는데 ${probe:-?} 가 나왔다 — **질의가 깨졌다.** 위 수도 못 믿는다"

  # ── ⑥ 🔴 **재고관리가 답하는가** — 집이 하나라 이것이 가장 큰 값이다
  say ""
  say "── ⑥ 🔴 **재고관리가 답하는가** — 집이 하나라 이것이 가장 큰 값이다"
  rr=$(row_by_key "$SITES" inventory); pt=$(field "$rr" 7)
  c=$(http_code "$pt")
  printf '      재고관리 127.0.0.1:%s → %s\n' "$pt" "${c:-못 읽음}"
  if http_ok "${c:-}"; then ok "재고관리가 답한다 ($c — 3xx 는 로그인으로 보내는 것이다)"
  else bad "재고관리가 $c 를 돌려준다"; fi
}

if [ "$MODE" = "--count" ]; then
  effect_counts
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '%s\n' "🔵 --count 는 **아무것도 안 바꿉니다.** 올리기 전과 뒤에 한 번씩 돌려 맞대세요."
  printf '%s\n' "   🔴 이번 판도 **같은 수가 나오는 것이 정상**입니다(보이는 쪽 기능입니다)."
  printf '%s\n' "   🔴 **① 의 수를 먼저 적어 두세요** — 도번이 적힌 부품이 **이번 줄이 서는**"
  printf '%s\n' "      **바로 그 부품들**이고, **참고값이 아직 없습니다.**"
  printf '%s\n' "      🔵 0 이면 눈 확인을 하려면 **도번을 하나 적어야** 합니다."
  printf '%s\n' "   🔴 **⑤ 는 올리기 전에 0줄이어야 합니다** — 그 화면이 아직 없기 때문입니다."
  printf '%s\n' "      눈 확인으로 [저장]을 누르면 **1줄이 됩니다**(정상입니다)."
  [ "$FAIL" = "0" ] && [ "$UNK" = "0" ] && exit 0
  exit 1
fi

if [ "$MODE" = "--check" ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s   · 단계 %s · DB %s\n' "$PASS" "$FAIL" "$UNK" "$PHASE" "$DBKEEP"
  printf '\n%s\n' "🔵 --check 는 **아무것도 안 바꿨습니다.**"
  printf '%s\n' "   다음: tar 둘을 보낸 뒤 --preload → --check → --tools → --go"
  printf '%s\n' "   🔴 **--migrate 는 없습니다** — 이번 판은 마이그레이션이 0건입니다."
  printf '%s\n' "      그 자리의 --tools 는 **도구 태그만 갈고 DB 는 안 건드립니다.**"
  printf '%s\n' "      🔴 **재고는 묶음을 안 씁니다** — .sql 은 도구 이미지 안에 있습니다."
  [ "$FAIL" = "0" ] && [ "$UNK" = "0" ] && exit 0
  exit 1
fi

# 🔴 여기부터는 **바꾸는 모드**다. ✗ 가 있으면 가지 않는다.
if [ "$FAIL" != "0" ]; then
  stop "✗ 가 ${FAIL}개 있습니다. 위를 보세요 — **아무것도 안 바꿨습니다.**"
fi

# ══════════════════════════════════════════════════════════════════════
# ══ 이미지 안을 재는 길 (--preload · --tools 가 쓴다) ═════════════════
# ══════════════════════════════════════════════════════════════════════
#   🔴 **앱과 도구는 담긴 것이 다르다** — 앱은 번들, 도구는 소스 그대로다.
#      한 잣대로 재면 가짜 ✗ 가 난다.
#   🔵 넷째 인자는 **판정에 안 쓰는 곁들이 값**이다 — 이 판은 판정 글자가 **맨 글자**
#      라 **따옴표 꼴을 곁들여 찍어** 다음 판이 「따옴표째 써도 되나」를 로그에서
#      바로 읽게 한다. 🔴 따옴표 꼴은 맨 글자의 **부분집합**이라 맨 글자보다 클 수 없다.
bundle_mark() { # 1 태그 2 글자 3 사람이 부르는 말 4 (선택) 곁들여 찍을 글자
  local v s t d ds dt
  v=$("$DOCKER" run --rm -e M="$2" --entrypoint sh "$1" -c \
    'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' </dev/null 2>/dev/null | tr -d '\r')
  s=$(printf '%s' "$v" | awk '{print $1}'); t=$(printf '%s' "$v" | awk '{print $2}')
  printf '        [%s] — server %s개 · static %s개 (🔴 합이 1 이상이어야 한다)\n' "$2" "${s:-?}" "${t:-?}"
  if [ -n "${4:-}" ]; then
    d=$("$DOCKER" run --rm -e M="$4" --entrypoint sh "$1" -c \
      'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' </dev/null 2>/dev/null | tr -d '\r')
    ds=$(printf '%s' "$d" | awk '{print $1}'); dt=$(printf '%s' "$d" | awk '{print $2}')
    printf '        [%s] — server %s개 · static %s개 (🔵 **판정에 안 쓰는 곁들이 값**)\n' "$4" "${ds:-?}" "${dt:-?}"
  fi
  if isnum "${s:-}" && isnum "${t:-}" && [ "$((s + t))" -ge 1 ]; then ok "$3"
  else
    bad "$3 — **없다.** 올리지 마세요"
    say "      🔵 **검사 자신도 의심하세요** — 이 글자는 소스에서만 세어 보았습니다."
    if [ -n "${4:-}" ] && isnum "${ds:-}" && isnum "${dt:-}" && [ "$((ds + dt))" -ge 1 ]; then
      say "      🔴🔴 **세는 쪽이 깨졌습니다** — 맨 글자가 0 인데 따옴표 꼴이 1 이상입니다."
      say "         따옴표 꼴은 맨 글자의 **부분집합**이라 그럴 수 없습니다. 이미지가"
      say "         아니라 **이 검사를 먼저 보세요** — 올리지 말고 개발 PC 에서 다시"
      say "         재세요(69-build.sh --verify). 이미지를 다시 구울 일은 아닙니다."
    fi
  fi
}

# 🔴 도구 이미지 안에서 **파일 하나 안의 글자 줄 수**를 받는다.
#    🔴 경로를 **상대로 넘기고 /app/ 를 컨테이너 안에서 붙인다**(⑬).
#    🔴 yes/no 가 아니라 **센 줄 수**를 받는다 — 0 과 「못 읽음」을 가른다.
tool_mark() { # 1 태그 2 글자 3 파일 4 기대 줄수 5 사람이 부르는 말
  local v st n
  v=$("$DOCKER" run --rm -e M="$2" -e F="$3" --entrypoint sh "$1" -c \
    'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s\n" "$(grep -cF -- "$M" "$p")"; else printf "missing 0\n"; fi' </dev/null 2>/dev/null | tr -d '\r')
  st=$(printf '%s' "$v" | awk '{print $1}'); n=$(printf '%s' "$v" | awk '{print $2}')
  printf '        [%s] in %s — 파일 %s · 그 글자 %s줄 (기대 hit · %s)\n' \
    "$2" "$3" "${st:-못 읽음}" "${n:-?}" "$4"
  if [ "${st:-}" = "hit" ] && [ "${n:-x}" = "$4" ]; then
    ok "$5 (${n}줄)"
  elif [ "${st:-}" = "hit" ] && [ "${n:-0}" -ge 1 ] 2>/dev/null; then
    hm "$5 — 그 글자가 ${n}줄입니다. $4 를 기대했습니다. 사람이 보세요"
  elif [ "${st:-}" = "hit" ]; then
    bad "$5 — 그 파일은 있는데 글자가 **0줄**이다. **옛 소스가 담긴 이미지다**"
  elif [ "${st:-}" = "missing" ]; then
    bad "$5 — 그 파일 자체가 이미지에 없다. src/ 가 온전히 안 담겼다"
  else
    bad "$5 — 못 읽었다 (받은 값 [${v:-}])"
  fi
}

# 🔴 도구 이미지 안의 **재고 마이그레이션**을 센다 — A/S 와 정반대 기대값이다.
tool_sql_check() { # 1 태그 2 이름
  local n j last nx
  n=$(dock "$1" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
  j=$(dock "$1" -c "grep -c 'idx' $IMG_MIGDIR/meta/_journal.json 2>/dev/null"); j=$(printf '%s' "$j" | tr -d ' ')
  last=$(dock "$1" -c "ls $IMG_MIGDIR/${INV_IMG_LAST}_*.sql 2>/dev/null | wc -l"); last=$(printf '%s' "$last" | tr -d ' ')
  nx=$(dock "$1" -c "ls $IMG_MIGDIR/${INV_IMG_NEXT}_*.sql 2>/dev/null | wc -l"); nx=$(printf '%s' "$nx" | tr -d ' ')
  printf '        %s 안 — .sql %s장(기대 %s) · idx %s개(기대 %s) · %s %s개(기대 1) · %s %s개(기대 0)\n' \
    "$IMG_MIGDIR" "${n:-?}" "$INV_IMG_SQL_WANT" "${j:-?}" "$INV_IMG_SQL_WANT" \
    "$INV_IMG_LAST" "${last:-?}" "$INV_IMG_NEXT" "${nx:-?}"
  if [ "${n:-x}" = "$INV_IMG_SQL_WANT" ] && [ "${j:-x}" = "$INV_IMG_SQL_WANT" ]; then
    ok "$2 에 마이그레이션 ${INV_IMG_SQL_WANT}장과 목록이 다 담겼다 (🔴 재고는 **이미지가 정본**이다)"
  else
    bad "$2 안이 .sql ${n:-?} · idx ${j:-?} 다 — ${INV_IMG_SQL_WANT} 을 기대했다"
    say "      🔴 **A/S 판을 베껴 0 을 기대하지 마세요** — A/S 는 볼륨이 정본이고"
    say "         재고는 이미지가 정본입니다. 줄었으면 **운영이 올릴 .sql 을 잃습니다.**"
    doubt
  fi
  [ "${last:-x}" = "1" ] && ok "$2 에 $INV_IMG_LAST 이 그대로 있다 (쉰여덟째가 올린 마지막 번호다)" \
    || bad "$2 에 $INV_IMG_LAST 이 없다 — 옛 판이 담겼다"
  [ "${nx:-x}" = "0" ] && ok "$2 에 $INV_IMG_NEXT 이 없다 (이 배포는 DB 를 한 글자도 안 바꾼다)" \
    || bad "$2 에 $INV_IMG_NEXT 이 **있다** — 이 배포본은 $INV_IMG_LAST 까지를 전제로 쓰였다. 멈추고 알릴 것"
}

preload_inside() {
  step "🔎 들여온 이미지 **안**을 센다 — 겉이 아니라 결과"
  say "🔴 「실었다」와 「쓸 만한 이미지다」는 다른 말입니다."
  # 🔴 **몇 개를 실제로 봤는지 센다.** 고리가 한 바퀴만 돌고 끝나도 ✗ 0 으로
  #    통과할 수 있다 — 2026-11-18 에 2-ㄱ 이 그렇게 **세 집을 안 잰 채** 지나갈 뻔했다.
  PRE_APP_SEEN=0; PRE_TOOL_SEEN=0
  # ── 앱 하나
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    K=$(field "$r" 1); NEW=$(field "$r" 4); NAME=$(field "$r" 8)
    PRE_APP_SEEN=$((PRE_APP_SEEN+1))
    printf '\n    ── %s  %s (앱 · **번들**)\n' "$NAME" "$NEW"
    if ! "$DOCKER" image inspect "$NEW" >/dev/null 2>&1; then bad "$NAME — $NEW 가 안 실렸다"; continue; fi
    v=$(dock "$NEW" -c "test -f /app/server.js && echo yes || echo no")
    printf '        /app/server.js: %s (기대 yes)\n' "${v:-못 읽음}"
    [ "${v:-}" = "yes" ] && ok "$NAME runner 스테이지가 맞다" \
      || bad "$NAME 에 /app/server.js 가 없다 — runner 가 아닌 것을 구웠다"
    # 🔴 **재고의 public/ 은 있는데 비어 있다**(ls -1 로 0개 — .gitkeep 은 숨은 파일).
    #    🔴 A/S 의 「9개 이상」을 들이대면 **멀쩡한 재고 앱이 ✗** 가 된다(머리말 ④).
    v=$(dock "$NEW" -c 'if [ -d /app/public ]; then printf "yes %s\n" "$(ls -1 /app/public 2>/dev/null | wc -l)"; else printf "no 0\n"; fi')
    pst=$(printf '%s' "$v" | awk '{print $1}'); pn=$(printf '%s' "$v" | awk '{print $2}')
    printf '        /app/public: %s (파일 %s개 · 기대 %s · 재고는 참고 %s개)\n' "${pst:-못 읽음}" "${pn:-?}" "$INV_PUBLIC_WANT" "$INV_PUBLIC_N"
    if [ "${pst:-}" != "$INV_PUBLIC_WANT" ]; then
      bad "$NAME 의 /app/public 이 ${pst:-못 읽음} 다 — $INV_PUBLIC_WANT 를 기대했다"
      say "      🔵 없으면 COPY 가 /app/public not found 로 멈췄다는 뜻입니다."
    elif [ "${pn:-0}" = "0" ]; then
      hm "$NAME public/ 은 있는데 **비어 있다** — 🔵 **재고는 원래 그렇습니다**(.gitkeep 한 장뿐)"
      say "      🔴 A/S 는 9개를 기대합니다 — 그 수를 여기 들이대면 가짜 ✗ 가 납니다."
    else
      ok "$NAME public/ 이 담겼다 (${pn}개 — 참고 ${INV_PUBLIC_N}개보다 늘었습니다. 사람이 보세요)"
    fi
    bundle_mark "$NEW" "$APPMARK"   "$NAME 번들에 **이번 판의 글자**가 있다 (색 고르개의 DOM id)" "$APPMARK_DIAG"
    bundle_mark "$NEW" "$KEEPMARK1" "$NAME 에 **쉰여덟째가 올린 글자**가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$NEW" "$KEEPMARK2" "$NAME 에 **그 앞 판이 올린 글자**가 그대로 있다 (뒷걸음친 나무가 아니다)"
    say "      🔴 **셋째 뒷걸음 표식(TOOLBAR_BTN_PRIMARY)은 여기서 안 셉니다** — 모듈 안의"
    say "         const 이름이라 minify 가 **이름을 바꿉니다.** 아래 도구 이미지에서"
    say "         **소스 글자 그대로** 셉니다(62번이 쓰던 자리)."
  done <<ENDPRE1
$(rows_of "$SITES")
ENDPRE1
  # ── 도구 하나
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    K=$(field "$r" 1); NEW=$(field "$r" 3); NAME=$(field "$r" 6)
    PRE_TOOL_SEEN=$((PRE_TOOL_SEEN+1))
    printf '\n    ── %s  %s (도구 · **소스가 글자 그대로**)\n' "$NAME" "$NEW"
    if ! "$DOCKER" image inspect "$NEW" >/dev/null 2>&1; then bad "$NAME — $NEW 가 안 실렸다"; continue; fi
    v=$(dock "$NEW" -c "test -f /app/package.json && echo yes || echo no")
    printf '        /app/package.json: %s (기대 yes)\n' "${v:-못 읽음}"
    [ "${v:-}" = "yes" ] && ok "$NAME tools 스테이지가 맞다" \
      || bad "$NAME 에 /app/package.json 이 없다 — **runner 를 구웠다**(--target tools 를 빠뜨렸다)"
    v=$(dock "$NEW" -c "test -d /app/node_modules/tsx && echo yes || echo no")
    printf '        /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
    [ "${v:-}" = "yes" ] && ok "$NAME 에 tsx 가 있다" \
      || bad "$NAME 에 tsx 가 없다 — tsx 로 도는 도구가 그 자리에서 죽는다"
    # 🔴 마지막 커밋 표식 — **이번 판에 태어난 조각 이름**이고, 과녁은 **기준판에도
    #    있던 화면**이다(머리말 ②). 새로 생긴 파일을 과녁으로 쓰면 「기준 0줄」이
    #    파일이 없어서 0 인 것이라 아무것도 안 가른다.
    tool_mark "$NEW" "$TOOLMARK" "$TOOLMARK_FILE" "$TOOLMARK_LINES_WANT" \
      "$NAME **이번 판의 커밋이 담겼다**"
    # 🔴 **셋째 뒷걸음 표식** — 번들에서 못 세는 것을 여기서 소스 글자로 센다.
    tool_mark "$NEW" "$TOOLKEEP" "$TOOLKEEP_FILE" "$TOOLKEEP_LINES_WANT" \
      "$NAME 에 **지난 판이 올린 도구 모음**이 그대로 있다 (뒷걸음친 나무가 아니다)"
    # 🔴 **ㄷ 잣대의 과녁이 새 몸통인가** — scripts/ 의 둘이 부르는 모듈이다.
    tool_mark "$NEW" "$TOOL_IMPORT_MARK" "$TOOL_IMPORT_TARGET" "1" \
      "$NAME 의 **도구가 부르는 모듈이 새 몸통이다** (옛 몸통으로 돌지 않는다)"
    # 🔴 **도구를 가는 까닭의 실물** — 이번 판의 새 모듈과 **괄호가 든 경로 둘**이
    #    담겼는가. 🔵 그 경로를 일부러 넣는다 — set -f 로 글롭을 끄는 길이 여기서
    #    실제로 쓰이고, 안 쓰면 다음 판이 그 함정을 밟는다(이번 판은 대괄호가 0이다).
    #    🔵 없는 경로 하나를 함께 묻는다 — 「무조건 yes」인 검사인지 가른다.
    v=$("$DOCKER" run --rm -e NM="$TOOLMARK_MODULE" --entrypoint sh "$NEW" -c \
      'set -f; n=0; m=0; for f in "$NM" "src/app/(app)/settings/drawing-no/page.tsx" "src/app/(app)/layout.tsx" "src/components/settings/DrawingNoStyleForm.tsx"; do [ -f "/app/$f" ] && n=$((n+1)); done; [ -f "/app/src/__dss_probe_no_such_file__.ts" ] && m=1; printf "n=%s miss=%s\n" "$n" "$m"' </dev/null 2>/dev/null | tr -d '\r')
    g=$(printf '%s' "$v" | sed -n 's/.*n=\([0-9]*\).*/\1/p')
    mm=$(printf '%s' "$v" | sed -n 's/.*miss=\([0-9]*\).*/\1/p')
    printf '        이번 판의 네 파일(%s 외 셋): %s개 (기대 4) · 없는 경로가 있다고 나왔나 %s (기대 0)\n' \
      "$TOOLMARK_MODULE" "${g:-?}" "${mm:-?}"
    # 🔴 **빈 결과와 「1」을 가른다** — 둘 다 ✗ 지만 **까닭이 반대**다.
    if [ -z "${mm:-}" ] || [ -z "${g:-}" ]; then
      bad "$NAME — **컨테이너에서 값을 못 받았다** (받은 값 [${v:-}]). 위 수를 믿지 마세요"
    elif [ "${mm:-1}" != "0" ]; then
      bad "$NAME — **없는 경로가 있다고 나왔다.** 「무조건 yes」인 검사다. 위 수도 못 믿는다"
    elif [ "${g:-x}" = "4" ]; then
      ok "$NAME 에 이번 판의 네 파일이 담겼다 (괄호가 든 경로 둘 포함)"
      say "      🔵 넷이 이 기능의 몸통입니다 — 도번 줄 조각(새 파일) · 설정 화면 ·"
      say "         값을 내려 주는 인증 구간 레이아웃 · 모양을 고르는 폼."
    else
      bad "$NAME 에 그 넷이 ${g:-?}/4 개다 — src/ 가 온전히 안 담겼다"
    fi
    # 🔴 **scripts/ 가 온전히 담겼는가** — ㄷ 잣대의 둘과 migrate.ts.
    v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c \
      'set -f; n=0; for f in scripts/import-workbook.ts scripts/seed-demo-legacy.ts scripts/migrate.ts; do [ -f "/app/$f" ] && n=$((n+1)); done; printf "n=%s\n" "$n"' </dev/null 2>/dev/null | tr -d '\r')
    g=$(printf '%s' "$v" | sed -n 's/.*n=\([0-9]*\).*/\1/p')
    printf '        ㄷ 잣대의 scripts/ 둘 + migrate.ts: %s개 (기대 3)\n' "${g:-?}"
    if [ "${g:-x}" = "3" ]; then ok "$NAME 에 그 셋이 담겼다 (scripts/ 가 온전히 담겼다)"
    else bad "$NAME 에 그 셋이 ${g:-?}/3 개다 — scripts/ 가 온전히 안 담겼다"; fi
    # 🔴 **재고는 drizzle 을 담아야 한다** — A/S 와 정반대다.
    tool_sql_check "$NEW" "$NAME"
    # 🔵 **tests/ 는 안 담기는 것이 맞다** — .dockerignore 가 막는다. 「12 중 12」의 까닭.
    v=$(dock "$NEW" -c "test -d /app/tests && echo yes || echo no")
    printf '        /app/tests: %s (기대 no — .dockerignore 가 막는다)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "no" ]; then ok "$NAME 에 tests/ 가 **안 담겼다** (바뀐 15장 중 12장만 담기는 까닭이다)"
    else hm "$NAME 에 tests/ 가 담겼다 — .dockerignore 가 바뀐 것 같습니다. 🔵 해롭지는 않습니다"; fi
    # 🔴 **재고 tools 는 vendor 를 안 담는다** — 62번이 포털에 쓰던 잣대 그대로.
    v=$(dock "$NEW" -c "test -d /app/vendor && echo yes || echo no")
    printf '        /app/vendor: %s (기대 no — 재고 tools 는 vendor 를 안 담는다)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "no" ]; then ok "$NAME 에 vendor 가 없다 (Dockerfile 과 같다)"
    else hm "$NAME 에 vendor 가 있다 — Dockerfile 이 바뀐 것 같습니다. 사람이 보세요"; fi
  done <<ENDPRE2
$(rows_of "$TOOLS")
ENDPRE2
  # 🔴 **표본이 비어서 공짜로 통과하지 않게** 한다.
  say ""
  printf '    본 앱 %s / %s · 본 도구 %s / %s\n' "$PRE_APP_SEEN" "$SITES_WANT" "$PRE_TOOL_SEEN" "$TOOLS_WANT"
  [ "$PRE_APP_SEEN" = "$SITES_WANT" ] && ok "앱 ${SITES_WANT}개의 안을 다 봤다" \
    || bad "앱을 ${PRE_APP_SEEN}개만 봤다 — ${SITES_WANT}개를 기대했다. **고리가 안 돌았다**"
  [ "$PRE_TOOL_SEEN" = "$TOOLS_WANT" ] && ok "도구 ${TOOLS_WANT}개의 안을 다 봤다" \
    || bad "도구를 ${PRE_TOOL_SEEN}개만 봤다 — ${TOOLS_WANT}개를 기대했다. **고리가 안 돌았다**"
}

# ══════════════════════════════════════════════════════════════════════
# ── 5. --preload : tar 둘을 들여놓는다 ───────────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--preload" ]; then
  step "5. --preload — tar 둘을 싣는다 (🔴 **아직 안 갈아 끼운다**)"
  say "🔵 쓰는 것: NAS 의 도커 이미지 저장소뿐입니다. compose 도 DB 도 안 건드립니다."
  LOADED=0; LOADFAIL=0; LOAD_SEEN=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    T=$(field "$r" 1)
    LOAD_SEEN=$((LOAD_SEEN+1))
    TAG=$(tar2tag "$T")
    if [ -z "${TAG:-}" ]; then bad "$T 의 태그를 모른다 — tar2tag 에 적혀 있지 않다"; LOADFAIL=$((LOADFAIL+1)); continue; fi
    if "$DOCKER" image inspect "$TAG" >/dev/null 2>&1; then
      ok "$TAG 가 이미 실려 있다 (건너뛴다)"; LOADED=$((LOADED+1)); continue
    fi
    printf '    싣는 중 %s → %s\n' "$T" "$TAG"
    # 🔵 docker load -i <파일> 은 **파일 입력**이라 고리 결함과 무관하다.
    if "$DOCKER" load -i "$IMGD/$T" >/dev/null 2>&1; then
      if "$DOCKER" image inspect "$TAG" >/dev/null 2>&1; then
        ok "$TAG 를 실었다"; LOADED=$((LOADED+1))
      else
        bad "$T 를 실었는데 $TAG 가 안 생겼다 — **tar 안의 태그가 다르다**"; LOADFAIL=$((LOADFAIL+1))
      fi
    else
      bad "$T 를 못 실었다"; LOADFAIL=$((LOADFAIL+1))
    fi
  done <<ENDLOAD
$(rows_of "$TARS")
ENDLOAD
  printf '\n  실은 것 %s / %s · 실패 %s (본 줄 %s)\n' "$LOADED" "$TARS_WANT" "$LOADFAIL" "$LOAD_SEEN"
  [ "$LOAD_SEEN" = "$TARS_WANT" ] && ok "tar ${TARS_WANT}개를 다 봤다" \
    || bad "tar 을 ${LOAD_SEEN}개만 봤다 — TARS 표가 깨졌다"
  if [ "$LOADFAIL" != "0" ]; then stop "싣기에 실패한 것이 ${LOADFAIL}개 있습니다. **compose 는 안 건드렸습니다.**"; fi
  preload_inside
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  if [ "$FAIL" != "0" ]; then
    stop "이미지 안에 ✗ 가 ${FAIL}개 있습니다 — **compose 는 안 건드렸습니다.**"
  fi
  printf '\n%s\n' "✅ 둘을 다 실었고 안도 온전합니다. **아직 아무것도 안 갈아 끼웠습니다.**"
  printf '%s\n' "   다음: --check 로 다시 재고 → --tools (🔵 DB 는 안 바뀝니다)"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════
# ══ 덤프 · compose 사본 ═══════════════════════════════════════════════
# ══════════════════════════════════════════════════════════════════════
#   🔴 **dss_inventory 하나만 뜬다**(68번은 dss_as 였다 — 집이 바뀌었다).
#   🔵 이 배포는 DB 를 한 글자도 안 바꾼다. 그래도 뜨는 까닭은 **새 앱이 쓰는 쪽에서
#      무엇을 할지는 이 배포본이 모르기** 때문이다. 오래 걸리지 않는다.
make_dump() {
  mkdir -p "$BKDB" 2>/dev/null; chmod 777 "$BKDB" 2>/dev/null
  say "🔵 덤프 자리: $BKDB (🔴 받을 폴더는 777 이어야 scp·컨테이너가 쓸 수 있습니다)"
  local f sz
  f="$BKDB/dss_inventory-$DUMP_VER-$STAMP.dump"
  printf '    뜨는 중 dss_inventory …\n'
  # 🔵 pg_dump 도 stdin 을 안 읽는다 — -i 를 떼고 </dev/null 을 붙인다.
  if "$DOCKER" exec dss-pg-app sh -c "pg_dump -U \"\$POSTGRES_USER\" -d dss_inventory -Fc" </dev/null > "$f" 2>/dev/null; then
    sz=$(stat -c %s "$f" 2>/dev/null)
    if isnum "${sz:-}" && [ "${sz:-0}" -gt 1000 ]; then
      ok "dss_inventory 덤프 ${sz}바이트 — $f"
      return 0
    fi
    bad "dss_inventory 덤프가 ${sz:-0}바이트다 — **쓸 수 없는 덤프다**"
    return 1
  fi
  bad "dss_inventory 덤프를 못 떴다 — dss-pg-app 이 도는지 보세요"
  return 1
}

backup_compose() {
  mkdir -p "$D/backups" 2>/dev/null
  if cp -a "$CF" "$BK"; then ok "compose 사본을 떴다 — $BK"
  else stop "compose 사본을 못 떴다 — **아무것도 안 바꿨습니다.**"; fi
}

# ══════════════════════════════════════════════════════════════════════
# ── 6. --tools : 🔴 **도구 태그만 간다. DB 는 안 바꾼다** ────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--tools" ]; then
  step "6. --tools — 🔴 **도구 태그 한 줄만 간다** (🔵 DB 는 한 글자도 안 바꾼다)"
  say "🔴 62번에는 이 자리가 **--migrate** 였습니다 — 재고에 0026·0027 을 올렸습니다."
  say "   🔴 **이번 판은 마이그레이션이 0건**이라 올릴 것이 없습니다. 그 대신"
  say "   **ㄴ 과 ㄷ 두 까닭**으로 도구 태그를 갑니다(1-ㄴ)."
  say "   🔴 1건이라도 생기는 판에서는 **62번에서 --migrate 를 되살리세요** —"
  say "      태그를 갈고 · npm run db:migrate 를 돌리고 · 수를 다시 셉니다."
  say "🔵 profiles: [tools] 라 평소에 뜨지 않습니다 — **직원이 느끼는 것이 없습니다.**"
  say ""
  say "🔴🔴 **이 모드는 재고 도구의 명령을 한 줄도 안 돌립니다.** 까닭이 둘입니다:"
  say "   ㉠ 🔴 **재고에는 db:preflight 가 없습니다**(package.json 에 db:migrate 뿐)."
  say "      68번처럼 그 이름을 베껴 적으면 **Missing script 로 멈춥니다.**"
  say "   ㉡ 🔴 **db:migrate 는 읽기 전용이 아닙니다** — 재고의 그 명령은 **실제로"
  say "      적용하는 명령**입니다(A/S 의 db:preflight 와 성격이 다릅니다)."
  say "   🔵 대신 **이미지 안을 값으로 셉니다** — .sql 수 · 목록 · 소스 표식 셋."
  if [ "$PHASE_TOOL_NEW" = "$TOOLS_WANT" ]; then
    ok "도구가 이미 새 판이다 — 바꿀 것이 없다"
    say "🔵 그래도 아래에서 **이미지 안과 DB 수**는 다시 잽니다."
  fi

  say ""
  say "── 6-ㄱ. 🔴 되돌릴 길부터 만든다 — **덤프 한 장**(dss_inventory)"
  say "🔵 이 배포는 DB 를 한 글자도 안 바꿉니다. 그래도 뜨는 까닭은 **새 앱이 쓰는**"
  say "   **쪽에서 무엇을 할지는 이 배포본이 모르기** 때문입니다."
  if ! make_dump; then stop "덤프를 못 떴습니다 — **아무것도 안 바꿨습니다.** 되돌릴 길부터 만드세요."; fi

  say ""
  say "── 6-ㄴ. compose 사본"
  backup_compose

  say ""
  say "── 6-ㄷ. 🔴 **도구 태그 한 줄을 간다**"
  SWAP_T=0; SWAP_T_SEEN=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    SVC=$(field "$r" 2); NEW=$(field "$r" 3); NAME=$(field "$r" 6)
    SWAP_T_SEEN=$((SWAP_T_SEEN+1))
    cur=$(svc_image "$SVC")
    if [ "${cur:-}" = "$NEW" ]; then ok "$NAME 가 이미 $NEW 다 (건너뛴다)"; SWAP_T=$((SWAP_T+1)); continue; fi
    if ! "$DOCKER" image inspect "$NEW" >/dev/null 2>&1; then
      bad "$NAME — $NEW 가 NAS 에 **없다**. --preload 부터 하세요"; continue
    fi
    swap_image "$SVC" "$NEW" && SWAP_T=$((SWAP_T+1))
  done <<ENDSWAPT
$(rows_of "$TOOLS")
ENDSWAPT
  printf '  바꾼 도구 줄 %s / %s (본 줄 %s)\n' "$SWAP_T" "$TOOLS_WANT" "$SWAP_T_SEEN"
  if [ "$SWAP_T_SEEN" != "$TOOLS_WANT" ] || [ "$SWAP_T" != "$TOOLS_WANT" ]; then
    stop "도구 줄을 다 못 바꿨습니다 — **DB 도 앱도 안 건드렸습니다.** compose 사본: $BK"
  fi
  # 🔴 compose 가 아직 읽히는가 — 한 줄이 깨지면 **모든 compose 명령이 통째로 죽는다.**
  if dcu config >/dev/null 2>&1; then ok "compose 가 아직 읽힌다 (config 가 통과한다)"
  else
    bad "compose 가 **안 읽힌다** — 되돌립니다"
    cp -a "$BK" "$CF" && say "compose 를 사본으로 되돌렸습니다: $BK"
    stop "compose 가 깨졌습니다. DB 도 앱도 안 건드렸습니다."
  fi

  say ""
  say "── 6-ㄹ. 🔴 **compose 가 가리키는 새 도구의 안을 센다** (명령은 안 돌린다)"
  # 🔴 서비스 이름을 **여기 다시 적지 않는다** — TOOLS 표에서 꺼낸다.
  #    두 곳에 적으면 표를 고친 날 한 곳만 바뀌고, 그때 나는 오류는
  #    「서비스를 못 찾았다」라 **도구 이미지 탓처럼 보인다.**
  TSVC=$(field "$(row_by_key "$TOOLS" inventorytools)" 2)
  if [ -z "${TSVC:-}" ]; then
    bad "TOOLS 표에서 inventorytools 의 서비스 이름을 못 꺼냈다 — 표가 깨졌다"
    stop "앱은 한 줄도 안 건드렸습니다."
  fi
  say "도구 서비스: $TSVC (TOOLS 표에서 꺼낸 값입니다)"
  NOWT=$(svc_image "$TSVC")
  say "compose 가 지금 가리키는 도구 이미지: ${NOWT:-못 읽음}"
  if [ -n "${NOWT:-}" ] && "$DOCKER" image inspect "$NOWT" >/dev/null 2>&1; then
    tool_sql_check "$NOWT" "새 도구"
    tool_mark "$NOWT" "$TOOLMARK" "$TOOLMARK_FILE" "$TOOLMARK_LINES_WANT" \
      "새 도구에 **이번 판의 커밋이 담겼다**"
    tool_mark "$NOWT" "$TOOLKEEP" "$TOOLKEEP_FILE" "$TOOLKEEP_LINES_WANT" \
      "새 도구에 **지난 판이 올린 도구 모음**이 그대로 있다"
    tool_mark "$NOWT" "$TOOL_IMPORT_MARK" "$TOOL_IMPORT_TARGET" "1" \
      "새 도구가 부르는 모듈이 **새 몸통이다** (ㄷ 잣대의 실물)"
  else
    bad "compose 가 가리키는 도구 이미지를 못 열었다 (${NOWT:-못 읽음})"
    say "      🔵 **도구 줄은 이미 갈았습니다.** 되돌리려면 compose 사본: $BK"
    stop "앱은 한 줄도 안 건드렸습니다. 직원이 보는 화면은 그대로입니다."
  fi

  say ""
  say "── 6-ㅁ. 🔴 **DB 가 정말 안 바뀌었는가** — 다섯 집을 다시 센다"
  say "🔴 이 모드는 DB 에 **쓰는 명령을 한 줄도 안 돌렸습니다.** 그래도 다시 재는"
  say "   까닭은, 그 사실을 **값으로 보이기** 위해서입니다."
  POSTK_SEEN=0; POSTK_OK=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    BOX=$(field "$r" 2); DB=$(field "$r" 3); WANT=$(field "$r" 4); NAME=$(field "$r" 5)
    POSTK_SEEN=$((POSTK_SEEN+1))
    v=$(mig_count "$BOX" "$DB")
    printf '      %-10s %-16s 지금 %-5s (기대 %s)\n' "$NAME" "$DB" "${v:-못 읽음}" "$WANT"
    if [ "${v:-x}" = "$WANT" ]; then POSTK_OK=$((POSTK_OK+1))
    else bad "$NAME 가 ${v:-?} 다 — $WANT 를 기대했다. **멈추고 알릴 것**"; fi
  done <<ENDPOSTK
$(rows_of "$MIGS_KEEP")
ENDPOSTK
  [ "$POSTK_SEEN" = "$MIGS_KEEP_WANT" ] && [ "$POSTK_OK" = "$MIGS_KEEP_WANT" ] \
    && ok "다섯 집의 마이그레이션 수가 **그대로다** (DB 를 한 글자도 안 바꿨다)" \
    || bad "본 집 ${POSTK_SEEN} · 같은 집 ${POSTK_OK} 다 — ${MIGS_KEEP_WANT} 을 기대했다"

  # 🔴 DB 가 안 멈췄는가 — 켜진 때를 앞뒤로 맞댄다.
  a=$("$DOCKER" inspect -f '{{.State.StartedAt}}' dss-pg-app 2>/dev/null)
  b=$("$DOCKER" inspect -f '{{.State.StartedAt}}' dss-pg-auth 2>/dev/null)
  [ "${a:-x}" = "${DBSTART_BEFORE:-y}" ] && ok "dss-pg-app 이 **안 멈췄다**" \
    || bad "dss-pg-app 의 켜진 때가 달라졌다 — DB 가 다시 떴다"
  [ "${b:-x}" = "${DBSTART_BEFORE2:-y}" ] && ok "dss-pg-auth 가 **안 멈췄다**" \
    || bad "dss-pg-auth 의 켜진 때가 달라졌다 — DB 가 다시 떴다"

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '\n%s\n' "✅ 도구가 새 판을 가리키고, 그 안이 온전합니다."
  printf '%s\n' "   🔵 **DB 는 한 글자도 안 바뀌었습니다** — 이 배포는 바꿀 것이 없습니다."
  printf '%s\n' "   🔵 **앱은 아직 옛 판입니다** — 직원이 보는 화면은 그대로입니다."
  printf '%s\n' "   다음: --go  ⏱ 앱 **하나**가 다시 뜹니다"
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════
# ══ 앱을 갈아 끼우고 다시 띄우는 길 (--go · --rollback 이 함께 쓴다) ══
# ══════════════════════════════════════════════════════════════════════
#   🔴🔴 **--no-deps 를 쓴다.**
#     [실측 2026-11-18 · NAS] --go 가 끝나고 「dss-pg-app 의 켜진 때가 달라졌다」가
#     ✗ 로 났다. 자료는 멀쩡했지만 **모든 연결이 끊겼다 붙었다.**
#     까닭은 compose 의 앱에 **depends_on: db-app (condition: service_healthy)**
#     가 걸려 있어서다 — 「compose up -d <앱>」 이 **의존 서비스까지 손댄다.**
#   🔴 --no-deps 는 「DB 가 떠 있다」를 compose 에게 맡기지 않겠다는 뜻이다.
#      그래서 **아래 go_gate() 가 그것을 직접 값으로 잰다** — 도는가 + **답하는가.**
up_one() { # 1 서비스 2 컨테이너 3 포트 4 이름 5 기대 태그
  local s c i n rc
  printf '    다시 띄우는 중 %s … (🔴 --no-deps — 의존 서비스는 안 건드린다)\n' "$4"
  # 🔴 **파이프의 종료 코드를 sed 에서 받지 않는다** — sed 는 거의 늘 성공해서
  #    「띄우기 실패」가 조용히 통과한다. PIPESTATUS 로 앞의 것을 받는다.
  dcu up -d --no-deps "$1" 2>&1 | sed 's/^/      /'
  rc=${PIPESTATUS[0]}
  if [ "${rc:-1}" != "0" ]; then
    bad "$4 를 못 띄웠다 (종료 코드 $rc)"
    say "      🔵 --no-deps 때문이라면 로그에 **의존 서비스를 못 찾았다**가 보입니다."
    say "         그때는 dss-pg-app 이 도는지부터 보세요."
    return 1
  fi
  n=0
  while [ "$n" -lt 30 ]; do
    c=$(http_code "$3")
    http_ok "${c:-}" && break
    n=$((n+1)); sleep 2
  done
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$2" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$2" 2>/dev/null)
  c=$(http_code "$3")
  printf '      상자 %-10s 도는 이미지 %-26s 127.0.0.1:%s → %s (기다린 시간 %s초)\n' \
    "${s:-없음}" "${i:-}" "$3" "${c:-못 읽음}" "$((n * 2))"
  if [ "${s:-}" != running ]; then bad "$4 상자가 ${s:-없음} 다"; return 1; fi
  if [ "${i:-}" != "$5" ]; then
    bad "$4 가 ${i:-?} 로 돈다 — $5 를 기대했다 (**compose 를 안 읽고 옛 상자가 살아 있다**)"
    return 1
  fi
  if http_ok "${c:-}"; then ok "$4 가 $5 로 서고 $c 를 돌려준다"; return 0; fi
  bad "$4 가 $c 를 돌려준다 — 200 이나 3xx 를 기대했다"
  say "      → 로그: $DOCKER logs --tail 50 $2"
  return 1
}

# 🔴 **--no-deps 를 쓰는 대신 세우는 관문**
#   compose 에게 맡기지 않는 그 조건을 **이 파일이 직접 값으로 잰다.**
#   🔴 「도는가」만 보면 **안에서 죽은 DB** 를 못 가른다 — select 를 던져 수를 받는다.
#   🔴 **숫자를 글자로 박지 않는다.** 68번은 dss_as 132 를 봤다 — 이 판은 **이번
#      집의 DB**(dss_inventory)를 보고, 기대값은 MIGS_KEEP 표에서 꺼낸다.
go_gate() {
  local s v want
  say "── 🔴 **--no-deps 관문** — 의존 서비스를 compose 에게 안 맡기므로 직접 잰다"
  s=$("$DOCKER" inspect -f '{{.State.Status}}' dss-pg-app 2>/dev/null)
  printf '      dss-pg-app 상자: %s (기대 running)\n' "${s:-없음}"
  if [ "${s:-}" != running ]; then
    bad "dss-pg-app 이 ${s:-없음} 다 — **DB 가 안 돌면 앱이 서도 아무것도 못 합니다**"
    return 1
  fi
  ok "dss-pg-app 이 돈다"
  # 🔴 표에서 꺼낸다 — 그런 자리를 글자로 박으면 판이 바뀌는 날 **조용히 틀린다.**
  want=$(field "$(row_by_key "$MIGS_KEEP" inventory)" 4)
  if [ -z "${want:-}" ]; then
    bad "MIGS_KEEP 표에서 재고의 기대값을 못 꺼냈다 — 표가 깨졌다"
    return 1
  fi
  v=$(mig_count dss-pg-app dss_inventory)
  printf '      dss-pg-app 이 **답하는가**: dss_inventory 마이그레이션 수 %s (기대 %s)\n' "${v:-못 읽음}" "$want"
  if [ "${v:-x}" != "$want" ]; then
    bad "dss-pg-app 이 답을 안 하거나 수가 다르다 (${v:-못 읽음})"
    say "      🔴 **「도는가」만 보면 안에서 죽은 DB 를 못 가릅니다** — 그래서 값을 받습니다."
    return 1
  fi
  ok "dss-pg-app 이 **실제로 답한다** (dss_inventory ${v})"
  return 0
}

swap_apps() { # 1 new|old
  local n seen
  n=0; seen=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    SVC=$(field "$r" 2); NEW=$(field "$r" 4); OLD=$(field "$r" 5); NAME=$(field "$r" 8)
    seen=$((seen+1))
    if [ "$1" = "new" ]; then WANT=$NEW; else WANT=$OLD; fi
    cur=$(svc_image "$SVC")
    if [ "${cur:-}" = "$WANT" ]; then ok "$NAME 가 이미 $WANT 다 (건너뛴다)"; n=$((n+1)); continue; fi
    if ! "$DOCKER" image inspect "$WANT" >/dev/null 2>&1; then
      bad "$NAME — $WANT 가 NAS 에 **없다**"; continue
    fi
    swap_image "$SVC" "$WANT" && n=$((n+1))
  done <<ENDSWAPA
$(rows_of "$SITES")
ENDSWAPA
  printf '  바꾼 앱 줄 %s / %s (본 것 %s)\n' "$n" "$SITES_WANT" "$seen"
  [ "$seen" = "$SITES_WANT" ] || { bad "앱을 ${seen}곳만 봤다 — SITES 표가 깨졌다"; return 1; }
  [ "$n" = "$SITES_WANT" ] || return 1
  return 0
}

final_checks() {
  say ""
  say "── 🔴 옆으로 안 샜는가 — **안 건드리는 아홉을 1절의 값과 맞댄다**"
  say "🔴 **도는가만** 보지 않습니다 — **이미지와 켜진 때까지** 맞댑니다."
  say "   2026-11-18 에 ✗ 가 바로 그 자리에서 났습니다(DB 가 Recreate 됐습니다)."
  say "🔴 **이번 판의 아홉에는 dss-as 가 들어 있습니다** — 지난 판과 반대입니다."
  local seen same
  seen=0; same=0
  while IFS='|' read -r c wi wt; do
    [ -n "${c:-}" ] || continue
    seen=$((seen+1))
    s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
    i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
    t=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
    printf '      %-18s %-10s %-26s 켜진 때 %s\n' "$c" "${s:-없음}" "${i:-}" "${t:-}"
    [ "${s:-}" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
    if [ "${i:-없음}" = "$wi" ] && [ "${t:-없음}" = "$wt" ]; then
      same=$((same+1))
    else
      bad "$c 가 달라졌다 — 이미지 [${i:-없음}] (전 [$wi]) · 켜진 때 [${t:-없음}] (전 [$wt])"
      say "      🔴 **이 배포는 이 집을 건드리면 안 됩니다.** --no-deps 가 안 들었거나"
      say "         compose 의 의존 관계가 바뀐 것입니다. 사람이 보세요."
    fi
  done <<ENDFIN
$(rows_of "$KEEP_SNAP")
ENDFIN
  printf '  본 것 %s / %s · 1절과 같은 것 %s\n' "$seen" "$KEEP_BOXES_WANT" "$same"
  [ "$seen" = "$KEEP_BOXES_WANT" ] && [ "$same" = "$KEEP_BOXES_WANT" ] \
    && ok "안 건드리는 아홉이 **이미지도 켜진 때도 그대로다**" \
    || bad "본 것 ${seen} · 같은 것 ${same} 다 — ${KEEP_BOXES_WANT} 을 기대했다"
  say ""
  say "── 🔴 DB 둘이 안 멈췄는가 — **--no-deps 가 들었는지 재는 자리다**"
  a=$("$DOCKER" inspect -f '{{.State.StartedAt}}' dss-pg-app 2>/dev/null)
  b=$("$DOCKER" inspect -f '{{.State.StartedAt}}' dss-pg-auth 2>/dev/null)
  printf '      dss-pg-app  전 [%s] → 후 [%s]\n' "${DBSTART_BEFORE:-없음}" "${a:-없음}"
  printf '      dss-pg-auth 전 [%s] → 후 [%s]\n' "${DBSTART_BEFORE2:-없음}" "${b:-없음}"
  if [ "${a:-x}" = "${DBSTART_BEFORE:-y}" ]; then ok "dss-pg-app 이 **안 멈췄다** (🔴 2026-11-18 에 여기가 ✗ 였다)"
  else
    bad "dss-pg-app 의 켜진 때가 달라졌다 — **DB 가 다시 떴다**"
    say "      🔴 --no-deps 가 안 들었습니다. **compose 의 depends_on 을 보세요.**"
    say "      🔵 자료는 멀쩡합니다. 끊겼다 붙은 연결만 다시 섭니다."
  fi
  [ "${b:-x}" = "${DBSTART_BEFORE2:-y}" ] && ok "dss-pg-auth 가 **안 멈췄다**" \
    || bad "dss-pg-auth 의 켜진 때가 달라졌다 — DB 가 다시 떴다"
  say ""
  say "── 🔴 compose 의 image: 줄을 **통째로** 찍는다 (사람이 눈으로 본다)"
  grep -n '^ *image:' "$CF" | sed 's/^/        /'
}

# ══════════════════════════════════════════════════════════════════════
# ── 7. --go : 앱 하나를 갈아 끼운다 ─────────────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--go" ]; then
  step "7. --go — 앱 **하나**를 갈아 끼운다 ⏱ 정지 창"
  say "🔵 집이 하나라 차례가 뜻을 갖지 않습니다 — **그래도 관문과 고리는 그대로입니다.**"

  # 🔴 관문 ① — DB 가 안 바뀌었는가(이 배포는 바꿀 것이 없다)
  if [ "$DBKEEP" != "KEEP" ]; then
    bad "DB 상태가 $DBKEEP 다 — KEEP 이어야 한다"
    say "      🔴 다섯 집의 마이그레이션 수가 **132·28·5·11·3** 이 아닙니다."
    say "         이 배포본은 마이그레이션을 **한 건도 올리지 않습니다** — 수가"
    say "         달라졌다면 **이 배포와 무관한 다른 사고**입니다."
    stop "**아무것도 안 바꿨습니다.** 사람이 보세요."
  fi
  ok "DB 가 전과 같다 (이 배포는 DB 를 바꿀 것이 없다)"

  # 🔴 관문 ② — 도구가 새 판인가(--tools 가 돌았는가)
  if [ "$PHASE_TOOL_NEW" != "$TOOLS_WANT" ]; then
    bad "도구가 ${PHASE_TOOL_NEW}/${TOOLS_WANT} 만 새 판이다 — --tools 가 안 돌았다"
    say "      🔴 --tools 가 **덤프를 뜨고** 새 도구의 **안을 세어** 확인합니다."
    say "         그 둘을 건너뛰지 마세요."
    say "      🔵 62번에는 이 자리가 --migrate 였습니다 — 이 판은 DB 를 안 바꿉니다."
    stop "먼저 --tools 를 돌리세요. **아무것도 안 바꿨습니다.**"
  fi
  ok "도구가 새 판이다 (--tools 가 돌았다 — 덤프와 이미지 안 세기가 끝났다)"

  # 🔴 관문 ③ — **--no-deps 를 쓰므로 DB 를 직접 잰다**
  say ""
  if ! go_gate; then stop "**아무것도 안 바꿨습니다.** DB 부터 보세요."; fi

  say ""
  say "── 7-ㄱ. compose 사본"
  backup_compose

  say ""
  say "── 7-ㄴ. 🔴 image: 줄 하나를 바꾼다 (아직 안 띄운다)"
  BEFORE_LINES=$(grep -c '^ *image:' "$CF" || true)
  if ! swap_apps new; then
    bad "앱 줄을 다 못 바꿨다 — 되돌립니다"
    cp -a "$BK" "$CF" && say "compose 를 사본으로 되돌렸습니다: $BK"
    stop "**컨테이너는 하나도 안 건드렸습니다.**"
  fi
  AFTER_LINES=$(grep -c '^ *image:' "$CF" || true)
  printf '  image: 줄 수 — 전 %s · 후 %s (같아야 한다)\n' "${BEFORE_LINES:-?}" "${AFTER_LINES:-?}"
  [ "${BEFORE_LINES:-x}" = "${AFTER_LINES:-y}" ] && ok "image: 줄 수가 그대로다 (줄을 더하거나 지우지 않았다)" \
    || bad "image: 줄 수가 달라졌다 — 사람이 보세요"
  if dcu config >/dev/null 2>&1; then ok "compose 가 아직 읽힌다"
  else
    bad "compose 가 **안 읽힌다** — 되돌립니다"
    cp -a "$BK" "$CF" && say "compose 를 사본으로 되돌렸습니다: $BK"
    stop "**컨테이너는 하나도 안 건드렸습니다.**"
  fi

  say ""
  say "── 7-ㄷ. ⏱ **여기서부터 정지 창** — 앱 하나를 띄운다"
  T0=$(date +%s)
  UP_N=0; UP_SEEN=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    SVC=$(field "$r" 2); CN=$(field "$r" 3); NEW=$(field "$r" 4)
    PORT=$(field "$r" 7); NAME=$(field "$r" 8)
    UP_SEEN=$((UP_SEEN+1))
    printf '\n    ── %s/%s  %s\n' "$UP_SEEN" "$SITES_WANT" "$NAME"
    if up_one "$SVC" "$CN" "$PORT" "$NAME" "$NEW"; then
      UP_N=$((UP_N+1))
    else
      bad "$NAME 가 안 섰다 — **여기서 멈춥니다**"
      say "      🔴 되돌리려면: bash $0 --rollback"
      say "      🔵 DB 는 그대로 둡니다 — 이 배포는 DB 를 한 글자도 안 바꿨습니다."
      stop "compose 사본: $BK · 덤프: $BKDB"
    fi
  done <<ENDUP
$(rows_of "$SITES")
ENDUP
  T1=$(date +%s)
  printf '\n  ⏱ 정지 창 약 %s초 (앱 %s곳 · 본 것 %s)\n' "$((T1 - T0))" "$UP_N" "$UP_SEEN"
  [ "$UP_SEEN" = "$SITES_WANT" ] && ok "앱 ${SITES_WANT}곳을 다 띄웠다 (표본이 비지 않았다)" \
    || bad "앱을 ${UP_SEEN}곳만 띄웠다"

  final_checks
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '\n%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "🔴 **배포 뒤에 눈으로 볼 곳 — [재고관리] 입니다**"
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "  🔴 **--count 의 ① 에서 센 부품** 중 하나를 쓰는 신청을 여세요 — **도번이**"
  printf '%s\n' "     **적힌 부품**이라야 새 줄이 섭니다. ① 이 0건이면 **도번을 하나 적은 뒤** 보세요."
  printf '%s\n' ""
  printf '%s\n' "  ① 🔴 [설정] → **[도번 표시]** 가 메뉴에 서는가 (**항목 관리 바로 뒤**)."
  printf '%s\n' "     🔵 **관리자에게만 보입니다** — 다른 역할로 들어가면 그 줄이 없는 것이 맞습니다."
  printf '%s\n' "  ② 🔴 미는 칸·색 고르개를 움직이면 **저장 없이** 미리보기가 따라 바뀌는가."
  printf '%s\n' "     🔵 [저장]을 누르기 전에도 바뀌어야 합니다."
  printf '%s\n' "  ③ 🔴 **알약을 꺼도 도번이 안 사라지는가** — 글자만 커지고 색이 듭니다."
  printf '%s\n' "     🔴 **알약색 칸은 흐려지되 값이 남아야** 합니다(다시 켜면 그대로 돌아옵니다)."
  printf '%s\n' "  ④ 🔴 **색 고르개 오른쪽 빈 자리를 눌렀을 때 팔레트가 안 열리는가.**"
  printf '%s\n' "     🔵 2026-11-20 에 고친 자리입니다 — 이름표가 **줄 전체를 덮고** 있었습니다."
  printf '%s\n' "     🔴 **색 상자와 「글자색」·「알약색」 글자를 누를 때만** 열려야 합니다."
  printf '%s\n' "  ⑤ 🔴 [부품 요청 관리] · [승인 요청건] · **불출 신청 팝업** 셋에서 도번이"
  printf '%s\n' "     **맨 아랫줄에 제 줄로** 서는가. 🔴 **셋 다 보세요** — 같은 부품을 씁니다."
  printf '%s\n' "     🔵 한 곳만 보면 나머지 둘을 못 가릅니다(세 화면이 같은 조각을 씁니다)."
  printf '%s\n' "  ⑥ 🔴 **도번이 없는 부품에서 그 줄이 통째로 안 서는가**(빈 칸은 안 그립니다)."
  printf '%s\n' "     🔴 「도번: -」 처럼 빈 값이 그려지면 **틀린 것**입니다."
  printf '%s\n' "  ⑦ 🔵 **뒷걸음 눈 확인 — 지난 판들이 올린 것이 그대로 있는지**"
  printf '%s\n' "     · [설정] → **[결재권 위임]** 이 그대로 서는가(쉰여덟째가 올린 것)."
  printf '%s\n' "     · **부품 목록의 도구 모음**(오른쪽 위 [부품 등록] 등)이 그대로인가(지난 판)."
  printf '%s\n' ""
  printf '%s\n' "🔴 **눈 확인으로 [저장]을 누르면 app_settings 에 한 줄이 생깁니다** — 그것이"
  printf '%s\n' "   정상입니다. --count 의 ⑤ 가 **0 → 1** 로 바뀌는 것이 맞습니다."
  printf '%s\n' ""
  printf '%s\n' "🔴 **다음에 할 일 둘** (아직 그대로입니다)"
  printf '%s\n' "  ㄱ) 06-notify-install.sh 에 **IMAGE=dss-meters-tools:1** 이 박혀 있습니다."
  printf '%s\n' "     지금 운영은 dss-meters-tools:2 입니다 — 그 파일을 다시 돌리는 사람이"
  printf '%s\n' "     **옛 태그를 싣습니다.** 2 로 고쳐 두세요."
  printf '%s\n' "  ㄴ) 🔴 **PO 가 모르는 것이 넷**입니다. PO 를 다시 여는 날 넷을 한 묶음으로"
  printf '%s\n' "     이식하세요(머리말). 🔵 이번 판이 거기에 더한 것은 **없습니다.**"
  printf '%s\n' ""
  printf '%s\n' "🔴 **되돌리기**: bash $0 --rollback  (앱 하나만 되돌립니다)"
  printf '%s\n' "   🔵 도구는 새 판 그대로 둡니다 · **DB 는 되돌릴 것이 없습니다.**"
  printf '%s\n' "   🔴 **되돌리면 도번 줄이 사라지고 [도번 표시] 메뉴도 없어집니다** — 둘 다"
  printf '%s\n' "      **코드에만** 있습니다. 🔵 사람이 저장해 둔 모양(app_settings 의 한 줄)은"
  printf '%s\n' "      **DB 에 남습니다** — 다시 올리면 그대로 돌아옵니다."
  printf '%s\n' "   🔵 덤프: $BKDB · compose 사본: $BK"
  printf '%s\n' "  다음: bash $0 --count  ← 올린 뒤 수를 재어 앞의 수와 맞대세요"
  printf '%s\n' "        🔴 ① ~ ④ 는 **같은 수가 나오는 것이 정상**입니다."
  printf '%s\n' "        🔴 **⑤ 만은 눈 확인 뒤에 0 → 1 로 늘어납니다**(사람이 저장한 것입니다)."
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════
# ── 8. --rollback : 앱 하나만 되돌린다 ──────────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--rollback" ]; then
  step "8. --rollback — 앱 하나를 옛 태그로 되돌린다"
  say "🔵 **도구는 새 판 그대로 둡니다**(39·41~68번과 같은 판단) — profiles: [tools]"
  say "   라 평소에 뜨지 않고, 옛 앱이 도구를 부르는 일도 없습니다."
  say "🔵 **DB 는 되돌릴 것이 없습니다** — 이 배포는 DB 를 한 글자도 안 바꿨습니다."
  say "🔴 **되돌리면 도번 줄이 사라지고 [도번 표시] 메뉴도 없어집니다** — 둘 다"
  say "   **코드에만** 있고 DB 에는 한 줄도 없습니다."
  say "🔵 **사람이 저장해 둔 모양은 app_settings 에 남습니다** — 되돌려도 안 지워지고,"
  say "   다시 올리면 그대로 돌아옵니다(그 줄은 옛 판이 읽지 않을 뿐입니다)."
  say "🔴 **--no-deps 로 띄웁니다** — 되돌릴 때도 DB 를 Recreate 하면 안 됩니다."
  say ""
  if ! go_gate; then stop "**아무것도 안 바꿨습니다.** DB 부터 보세요."; fi
  say ""
  backup_compose
  if ! swap_apps old; then
    bad "앱 줄을 다 못 되돌렸다"
    stop "compose 사본: $BK — 사람이 보세요"
  fi
  if dcu config >/dev/null 2>&1; then ok "compose 가 아직 읽힌다"
  else
    cp -a "$BK" "$CF"; stop "compose 가 깨져 사본으로 되돌렸습니다: $BK"
  fi
  T0=$(date +%s); RB_N=0; RB_SEEN=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    SVC=$(field "$r" 2); CN=$(field "$r" 3); OLD=$(field "$r" 5)
    PORT=$(field "$r" 7); NAME=$(field "$r" 8)
    RB_SEEN=$((RB_SEEN+1))
    printf '\n    ── %s\n' "$NAME"
    up_one "$SVC" "$CN" "$PORT" "$NAME" "$OLD" && RB_N=$((RB_N+1))
  done <<ENDRB
$(rows_of "$SITES")
ENDRB
  T1=$(date +%s)
  printf '\n  ⏱ 약 %s초 · 되돌린 집 %s / %s (본 것 %s)\n' "$((T1 - T0))" "$RB_N" "$SITES_WANT" "$RB_SEEN"
  [ "$RB_SEEN" = "$SITES_WANT" ] && ok "앱 ${SITES_WANT}곳을 다 봤다" \
    || bad "앱을 ${RB_SEEN}곳만 봤다 — SITES 표가 깨졌다"
  final_checks
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '%s\n' "🔵 앱 하나를 옛 판으로 되돌렸습니다. 도구는 새 판 그대로입니다."
  printf '%s\n' "   🔴 **1절의 단계는 MID 로 보입니다** — --tools 만 돌린 상태와 같은 모양입니다."
  printf '%s\n' "      이번 판은 DB 가 안 바뀌어 **그 둘을 DB 로 가를 수 없습니다.**"
  printf '%s\n' "      가르려면 **로그 파일 이름**(deploy65-go-… / deploy65-rollback-…)을 보세요."
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi
