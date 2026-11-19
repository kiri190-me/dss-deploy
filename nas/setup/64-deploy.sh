#!/bin/bash
# dss-deploy/nas/setup/64-deploy.sh — 예순째 배포 (2026-11-19)
#
# 🔴 **NAS 에서 돈다.** DSM 터미널에서 sudo -i 뒤에 부른다.
#     bash /volume1/dss/setup/64-deploy.sh            ← --check (기본 · 아무것도 안 바꾼다)
#     bash /volume1/dss/setup/64-deploy.sh --count
#     bash /volume1/dss/setup/64-deploy.sh --preload
#     bash /volume1/dss/setup/64-deploy.sh --tools
#     bash /volume1/dss/setup/64-deploy.sh --go
#     bash /volume1/dss/setup/64-deploy.sh --rollback
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 올리는 것 — 한 줄 요약**
# ══════════════════════════════════════════════════════════════════════
#   [내자 정리]의 **상태 거르개가 셋에서 넷**이 된다. NO_ORDER_DATE 의 이름표가
#   「발주일 미정」 → **「발주 대기」**로 바뀌고, 새 값 **ORDER_ISSUED**
#   (= 「발주 완료」 · orderIssuedDate 가 NULL 이 아닌 줄)가 생긴다.
#   🔵 **판정은 한 줄도 안 바뀌었고 DB 는 한 글자도 안 바뀐다** — 읽는 쪽 기능이다.
#   🔴 **필터 이름만 바꿨다.** NO_ORDER_DATE_LABEL(= "발주일 미정")은 배지 ·
#      주황 안내 · 기타건 칸 · 내자 상세 **넷이 그대로** 쓴다.
#      **같은 줄을 화면이 두 말로 부르는 것이 2026-11-19 사용자 결정이다.**
#      🔴 **고장이 아니다** — 아래 「눈으로 볼 곳」에 그 말을 적어 두었다.
#
#   앱 **하나** · 도구 **하나** · 마이그레이션 **0건** · 묶음 **없음** ·
#   안 건드리는 집 **아홉**. 🔵 **얼개는 63번(쉰아홉째)과 같다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **63번의 전제 중 이번에 깨지는 것 넷 — 하나씩 재서 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴🔴 **표식이 통째로 갈린다 — 63번 것을 그대로 쓰면 아무것도 안 가른다.**
#      63번의 기능 표식 domestic-order-status-filter 는 **쉰아홉째가 어제 올린
#      글자**다. 오늘 이미지에서 그것이 「있다」는 것은 **아무 뜻이 없다.**
#      🔴 그래서 **뒷걸음 표식으로 내리고** 기능 표식을 새로 골랐다.
#      🔴 **그런데 새로 고른 맨 글자 ORDER_ISSUED 도 틀렸다 — 재 보고 알았다.**
#        [실측 2026-11-19 · 개발 PC] git grep -lF ORDER_ISSUED 48011ab4 -- src
#        → **2파일**. 쉰아홉째가 올린 상수 **ORDER_ISSUED_SORT_HINT** 의 앞부분에
#        걸린다. 그대로 썼으면 「기준판에도 있다」로 ✗ 가 났을 것이다.
#      🔴 처방 둘을 **갈래마다 다르게** 썼다:
#        · 앱 번들 — **따옴표를 포함한 리터럴** "ORDER_ISSUED" 로 좁혔다.
#          [실측] 소스에서 기준 **0파일** → 지금 **2파일**. 🔵 번들에 실제로 남는
#          꼴이 이것이다(값 배열과 switch 의 case). 상수 이름은 minify 가 지운다.
#          🔴 **홑따옴표로 적힐 가능성**이 남아 bundle_mark 가 **맨 글자를 곁들여
#          찍는다** — 판정에는 안 쓰고, ✗ 가 났을 때 「따옴표만 안 맞는 것」을 가른다.
#        · 도구 이미지 — **파일을 좁혀서** 맨 글자를 쓴다.
#          TOOLMARK = ORDER_ISSUED in src/lib/domain/domestic-order-list.ts
#          [실측] 그 **파일 안에서는** 기준 **0줄** → 지금 **4줄**. SORT_HINT 는
#          그 파일에 없다(화면 파일과 그 화면 시험에만 있다).
#      🔴 **뒷걸음 표식은 셋이다**(63번은 둘):
#          domestic-order-status-filter(쉰아홉째) · portal_approval_delegations
#          (쉰여덟째) · domesticOrders.view(쉰여섯째).
#
#   ② 🔴 **tar 이름과 태그가 갈린다.** dss-as:5.5 → **5.6** · dss-as-tools:22 → **23**.
#      🔴 TARS 는 **아직 비어 있다** — 굽기 전에 쓴 파일이다(아래 TARS 절).
#
#   ③ 🔵 **--count 가 세는 것이 넷으로 는다.** 63번은 상태 셋(완료 14 · 미완료 22 ·
#      발주일 미정 9)을 쟀다. **「발주 완료」가 생겨 넷**이다.
#      🔴 그리고 **여집합 관문**을 더했다: 발주 대기 + 발주 완료 == 휴지통 밖.
#      🔴 63번이 ④절에서 세던 「발행일이 적힌 줄」은 **발주 완료와 글자 그대로 같은
#         질의**다. **두 번 재지 않는다** — 한 번 재서 두 자리에 쓴다(까닭은 그 절에).
#      🔵 이 배포도 **읽는 쪽 기능**이라 **전후 수가 같아야 정상**이다.
#
#   ④ 🔵 **안 건드리는 아홉의 「켜진 때」는 어제 배포로 안 바뀌었다**(A/S 만 떴다).
#      🔴 그래도 이 파일에는 **박아 둔 시각이 한 글자도 없다** — 1절에서 찍어
#         KEEP_SNAP 에 담고 끝에서 맞댄다. 그 길이라 판이 바뀌어도 그대로 산다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **63번에서 그대로 살린 것 — 한 번 빼면 다시 넣는 사람이 없다**
# ══════════════════════════════════════════════════════════════════════
#   · **--migrate 는 없다**(마이그레이션 0건). 그 자리에 **--tools** 가 있다.
#   · 2절 「DB 가 **안 바뀌었는가**」 — 다섯 집 131·28·5·11·3 · 쉰여덟째의 표 넷 ·
#     A/S 볼륨 131장 · 0131 이 안 생겼는가 · 도구 이미지 안 drizzle 0장.
#   · 🔴 **--no-deps** 와 그 관문(DB 가 도는가 + **실제로 답하는가**) ·
#     끝에서 **DB 둘의 켜진 때 맞대기**. [실측 2026-11-18] 이것이 없어서 --go 가
#     dss-pg-app 을 Recreate 했다 — 자료는 멀쩡했지만 모든 연결이 끊겼다 붙었다.
#   · 함수 정의에 붙인 **</dev/null** — 고리 안의 docker exec 가 here 문서를 먹는다.
#     [실측 2026-11-18] 그것 때문에 2-ㄱ 이 **네 집 중 한 집만** 재고 끝났다.
#   · **「몇 개를 봤는가」 관문** — 고리를 도는 검사마다 끝에서 센 횟수를 단언한다.
#     🔵 이번 판도 **집이 하나**라 고리가 한 바퀴만 도는 것이 정상이다. 🔴 「1이니
#     뜻이 없다」가 아니다 — 표가 깨져 **0바퀴**를 돌아도 ✗ 0 으로 통과하는 것을 막는다.
#   · 덤프(dss_as 하나) · compose 사본 · db:preflight 로 **「대기 0건」** 받기.
#   · 4절의 **빼지 않는 검사들** — 연락서 폴더 · 양식 폴더 · PO 쓰기 권한 ·
#     발주서 공유폴더.
#   · 🔴 **지난 판 묶음이 incoming 에 남아 있다는 ⚠️** 와 「이 배포본은 안 읽는다」.
#   · 3xx 판정(200|30[1237]) — A/S 는 **307** 로 로그인에 보낸다. 빼면 멀쩡한
#     사이트가 ✗ 로 나온다(2026-10-30 실측).
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
#   --preload
#       쓰는 것 : **NAS 의 도커 이미지 저장소**(docker load 로 태그 둘).
#       🔵 실어만 두고 **아직 안 갈아 끼운다.** 싣자마자 **안을 센다.**
#   --tools
#       쓰는 것 : **DB 덤프 한 장**(dss_as) · **compose 사본 한 장** ·
#                 **compose 의 image: 줄 하나**(tools-as 만).
#       안 쓰는 것: 🔴 **DB** · 앱의 image: 줄 · 도는 컨테이너 · 볼륨 · 공유폴더.
#       🔵 profiles: [tools] 라 평소에 뜨지 않는다 — **직원이 느끼는 것이 없다.**
#       🔴 새 도구로 **db:preflight** 를 돌려 「대기 0건」과 **import 가 닫히는가**를
#          값으로 받는다. 도구의 import 닫힘이 바뀐 판이라 이것이 실물 시험이다.
#   --go
#       쓰는 것 : **compose 사본 한 장** · **compose 의 image: 줄 하나**(app-as) ·
#                 **앱 하나를 다시 띄운다**(정지 창 — 20~30초).
#       안 쓰는 것: 🔴 **DB** · 볼륨 · 공유폴더 · 🔴 **나머지 아홉 집의 image: 줄**.
#       🔴 **--no-deps 를 쓴다** — 그것이 없어서 DB 가 Recreate 된 적이 있다.
#   --rollback
#       쓰는 것 : **compose 사본 한 장** · **app-as 의 image: 줄** · **앱 하나를 다시 띄운다.**
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
#      목록은 **읽은 줄 수를 함께 받고**, **없는 경로 하나를 일부러 함께 묻는다.**
#   ⑥ 🔴 **마이그레이션은 이미지가 아니라 볼륨에서 돈다**(A/S). 이미지 안만 세면
#      0건으로 조용히 끝난다. **볼륨의 .sql 과 _journal.json 을 둘 다** 센다.
#      🔵 이번 판은 **더할 것이 0건**이라 「131장 그대로인가」를 잰다.
#   ⑦ 🔴 **저장소의 compose 사본은 운영보다 뒤처진다**(아홉 판 차이가 난 적이 있다).
#      이 파일은 **NAS 위의 docker-compose.nas.yml 만 읽는다.**
#   ⑧ 🔴 **bash 의 $(( )) 는 0 으로 시작하는 수를 8진수로 읽는다** — 0131 을 셈에
#      넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
#   ⑨ 🔴 **한글을 HTTP 머리말·argv 에 넣지 않는다.** 넣으면 요청이 아예 안 나가고
#      그 ✗ 가 진짜 결함처럼 보인다. 🔵 이 파일의 표식은 **전부 ASCII** 다.
#   ⑩ 🔴 **비밀값을 찍지 않는다.** 설정 파일은 이름이 있는가/없는가와 auto 인가만
#      본다. DATABASE_URL 에서는 **역할 이름만** 꺼낸다.
#   ⑪ 🔵 **받을 폴더는 777 로 만든다** — root 가 만든 755 는 scp 가 못 쓴다.
#   ⑫ 🔴 **「겉이 아니라 결과를 봐라」** — 「실었다」와 「쓸 만한 이미지다」는 다른
#      말이다. --preload 는 싣자마자 **안을 센다.**
#   ⑬ 🔵 **Git Bash 가 docker 인자를 번역하는 함정은 NAS 에 없다**(리눅스다).
#      🔴 그래도 **같은 꼴로 적어 둔다**: 파일 경로는 **상대로 넘기고 /app/ 를
#      컨테이너 안에서 붙인다.** 누가 이 파일을 Git Bash 에서 흉내 내도 살아남는다.
#
# ── 🔴 알고도 안 고친 것 — PO 가 모르는 것이 **넷**이다 ──────────────
#   ① dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 APPROVAL_REQUIRED 가 없다.
#   ② PO 는 납품일 칸(delivered_date·delivered_by)을 모른다.
#   ③ PO 는 회차 승인(due_date_row_order)을 모른 채 같은 표를 고친다.
#   ④ PO 의 vendor/dss-core 핀이 8730c94 라 portal_approval_delegations 를 모른다.
#   🔵 **이번 판이 거기에 더하는 것은 없다** — 읽는 쪽 기능이고 표를 안 건드린다.
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
BK=$D/backups/docker-compose.nas.yml.v60-$STAMP
BKDB=$D/backups/db
# 🔴 **BK 와 같은 v 번호여야 한다** — 59번(쉰다섯째)이 여기를 안 고쳐 v54 로 남긴
#    적이 있다. 아래 1-ㄱ-0 절이 값으로 확인한다.
DUMP_VER=v60
INCOMING=$D/setup/incoming
MIGDIR=$D/as-migrations
IMG_MIGDIR=/app/drizzle
TPLDIR=$D/as-templates
# 🔵 지난 판 묶음이 여기 남아 있을 수 있다. 🔴 **이 파일은 그것을 쳐다보지도
#    않는다** — 푸는 코드가 한 줄도 없다. 1-ㅁ 절이 ⚠️ 로 알려만 준다.
OLD_MIGTAR=$INCOMING/as-migrations.tar.gz

# ══ 🔴 앱 **하나** ════════════════════════════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트포트|사람이 부르는 이름
SITES='
as|app-as|dss-as|dss-as:5.6|dss-as:5.5|dss-as-5.6.tar|13000|A/S관리
'
SITES_WANT=1

# ══ 🔴 도구 **하나** — --tools 가 이 줄을 간다 ════════════════════════
#   열쇠|서비스|새 태그|옛 태그|tar|이름|무엇 때문에 가는가
TOOLS='
astools|tools-as|dss-as-tools:23|dss-as-tools:22|dss-as-tools-23.tar|A/S도구|🔴 조사 도구 둘이 import 하는 domestic-order-list.ts 가 +54/−22 바뀌었다
'
TOOLS_WANT=1

# ══ 🔴 안 건드리는 **아홉** — 「옆으로 안 샜다」는 증거로 센다 ════════
#   🔴 상자 이름이다(서비스 이름이 아니다) — 저장소의 compose 사본이 운영보다
#      뒤처져 있어 서비스 이름을 믿을 수 없다(⑦). 63번이 NAS 에서 실제로 쓴 값 그대로다.
KEEP_BOXES="dss-auth dss-approvals dss-inventory dss-leave dss-meters dss-board dss-improvements dss-rf-trouble dss-po"
KEEP_BOXES_WANT=9
KEEP_DB="dss-pg-app dss-pg-auth"
KEEP_DB_WANT=2

# ══ 🔴 DB — **바뀌면 안 된다** ════════════════════════════════════════
#   열쇠|DB상자|DB이름|지금도 뒤에도 이 수여야 한다|사람이 부르는 이름
#   🔴 **어긋나면 이 배포와 무관한 다른 사고다.** 그 자리에서 멈춘다.
#   🔵 통합 승인함은 **DB 가 없는 집**이라 이 표에 없다 — 「0건」이 아니라 해당 없음이다.
MIGS_KEEP='
as|dss-pg-app|dss_as|131|A/S관리
inventory|dss-pg-app|dss_inventory|28|재고관리
leave|dss-pg-app|dss_leave|5|휴가관리
auth|dss-pg-auth|dss_auth|11|통합로그인포털
meters|dss-pg-app|dss_meters|3|계측기관리
'
MIGS_KEEP_WANT=5

# ══ 🔴 **쉰여덟째가 만든 표 넷** — 뒷걸음 방지 ════════════════════════
#   DB상자|DB이름|표 이름|사람이 부르는 이름
KEEP_TABLES='
dss-pg-app|dss_as|portal_approval_delegations|A/S관리
dss-pg-app|dss_inventory|portal_approval_delegations|재고관리
dss-pg-app|dss_leave|web_portal_approval_delegations|휴가관리
dss-pg-auth|dss_auth|approval_delegations|통합로그인포털
'
KEEP_TABLES_WANT=4

# ══ 🔴 A/S 마이그레이션 볼륨 — **131장 그대로여야 한다** ══════════════
AS_VOL_SQL_WANT=131
AS_VOL_NEXT=0131

# ══ 🔴 tar **둘**의 지문 — [배포본] 64-build.sh 가 굽고 **바로 잰 값** ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 비어 있다 — 굽기 전에 쓴 파일이다.** 64-build.sh --go 가 꼬리말에
#      찍는 **두 줄**로 아래를 통째로 갈아 끼운 **뒤에** scp 하세요.
#   🔴 **이 값을 NAS 에서 재서 채우지 마라.** 그러면 「옮기다 깨졌는가」를 자기가
#      잰 값으로 자기를 재는 꼴이 되어 **영영 통과한다.** 반드시 **구운 쪽**에서 잰다.
#   🔴 비어 있으면 3절이 **--check·--count·--rollback 에서는 ? · --preload·
#      --tools·--go 에서는 ✗** 로 센다. 🔵 막는 것은 **✗ 뿐이다.**
#      🔴 **쉰세째에는 빈 표가 그대로 NAS 로 올라갔고 --preload 가 ✗ 둘로 멈췄다.**
#   🔵 **지난 판 바이트**(다음 판이 크기를 견줄 때 쓴다):
#      dss-as-5.5.tar 136025088 · dss-as-tools-22.tar 226528768
TARS='
dss-as-5.6.tar|||
dss-as-tools-23.tar|||
'
TARS_WANT=2
# 🔵 **묶음 값(MIGTAR_SIZE·MIGTAR_MD5)은 없다** — 이번 판은 묶음을 안 만든다.

# 🔴 tar 이름 → 태그. **정규식으로 되돌리지 않는다** — 이름마다 손으로 적는다.
#    🔴 판에 점이 있는 것과 없는 것이 섞여 있어 한 규칙으로 안 풀린다.
tar2tag() {
  case "$1" in
    dss-as-5.6.tar)        printf 'dss-as:5.6' ;;
    dss-as-tools-23.tar)   printf 'dss-as-tools:23' ;;
  esac
}

# ══ 🔴 이미지 안에서 쓸 표식 — **전부 ASCII · 전부 리터럴** ═══════════
#   앱 이미지(번들 · minify 를 거친다)
#   🔴 **따옴표가 글자의 일부다**(머리말 ①). 맨 글자로 재면 기준판의
#      ORDER_ISSUED_SORT_HINT 에 걸려 **아무것도 안 가른다.**
APPMARK='"ORDER_ISSUED"'
# 🔵 판정에 **안 쓰는** 곁들이 값 — ✗ 가 났을 때 「따옴표만 안 맞는 것」을 가른다.
APPMARK_DIAG=ORDER_ISSUED
KEEPMARK1=domestic-order-status-filter
KEEPMARK2=portal_approval_delegations
KEEPMARK3=domesticOrders.view
#   도구 이미지(소스가 글자 그대로 있다) — 🔴 **파일을 좁혀서** 맨 글자를 쓴다.
TOOLMARK=ORDER_ISSUED
TOOLMARK_FILE=src/lib/domain/domestic-order-list.ts
TOOLMARK_LINES_WANT=4
PROBE_MISS=src/__dss_probe_no_such_file__.ts

# ══ 🔴 public/ 기대값 ═════════════════════════════════════════════════
#   🔵 A/S 는 yes 이고 안에 **9개**다[실측 2026-11-18 · 구운 것을 열어 셌다].
AS_PUBLIC_WANT=yes

# ══ 🔵 --count 의 참고값 — [운영 실측 2026-11-19 · 쉰아홉째 배포 뒤] ═══
#   🔴 **이것은 ✗ 를 내는 기대값이 아니다.** 사람이 내자 줄을 더하거나 발주일을
#      적으면 정상적으로 달라진다 — 다르면 **⚠️ 로만** 센다.
#   🔴 ✗ 를 내는 것은 **여집합 관문 둘**뿐이다(아래 effect_counts).
CNT_LIVE_REF=36
CNT_DONE_REF=14
CNT_UNDONE_REF=22
CNT_NOORDER_REF=9
CNT_ISSUED_REF=27
CNT_CUST_REF=4
CNT_NOCUST_REF=0

# ══ 🔴 설정 파일 — .env 쪽과 env/*.env 쪽을 **둘 다** 본다 ════════════
ENV_NAS=$D/deploy/.env.nas
ENV_FILES="$D/deploy/env/as.env $D/deploy/env/auth.env $D/deploy/env/po.env $D/deploy/env/inventory.env $D/deploy/env/leave.env $D/deploy/env/meters.env $D/deploy/env/approvals.env"

# ══ 🔵 공유폴더 — 🔴 **한 번 빼면 다시 넣는 사람이 없다**(4절) ════════
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
     exit 2 ;;
esac

mkdir -p "$D/setup/logs" 2>/dev/null
LOG="$D/setup/logs/deploy60-$(printf '%s' "$MODE" | tr -d '-')-$STAMP.log"
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

# 🔴 **compose 도 stdin 을 읽는다** — 같은 까닭으로 </dev/null 을 붙인다.
dct() { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas --profile tools "$@" </dev/null ); }
dcu() { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas "$@" </dev/null ); }

# 🔴 이미지 안을 여는 길 — **경로를 상대로 넘기고 /app/ 를 컨테이너 안에서 붙인다**(⑬).
dock() { "$DOCKER" run --rm --entrypoint sh "$@" </dev/null 2>/dev/null | tr -d '\r'; }

# ── 앱이 답하는가 ────────────────────────────────────────────────────
#   🔴 **3xx 를 통과로 센다** — A/S 는 **307** 로 로그인에 보낸다.
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
printf '%s\n' " 64-deploy.sh — 예순째 배포 ($MODE)"
printf '%s\n' "   때      : $(date '+%F %T')"
printf '%s\n' "   로그    : $LOG"
printf '%s\n' "   compose : $CF"
printf '%s\n' "   앱 1 · 도구 1 · 🔴 **마이그레이션 0건** · 묶음 없음 · 안 건드리는 집 9"
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
  printf '      %-10s %-16s %-24s %s\n' "$NAME" "$SVC" "${cur:-없음}" "$st"
  if [ -z "${cur:-}" ]; then
    bad "$NAME — compose 에 $SVC 의 image: 줄이 **없다**"
    say "      🔴 **멈추고 알리세요.**"
  elif [ "$st" = "ODD" ]; then
    hm "$NAME 가 ${cur} 다 — 옛 $OLD 도 새 $NEW 도 아니다. **사람이 보세요**"
  fi
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  c=$(http_code "$PORT")
  printf '        상자 %-10s 도는 이미지 %-24s 127.0.0.1:%s → %s\n' "${s:-없음}" "${i:-}" "$PORT" "${c:-못 읽음}"
  if [ "${s:-}" = running ]; then ok "$NAME 상자가 돈다"
  else bad "$NAME 상자가 ${s:-없음} 다 — 배포 전에 이미 멈춰 있다"; fi
  if http_ok "${c:-}"; then ok "$NAME 가 답한다 ($c — 3xx 는 로그인으로 보내는 것이다)"
  else bad "$NAME 가 $c 를 돌려준다 — 200 이나 3xx 를 기대했다"; fi
done <<ENDSITE1
$(rows_of "$SITES")
ENDSITE1
# 🔴 **표본이 비어서 공짜로 통과하지 않게** 한다. 🔵 이번 판도 1 이 기대값이다 —
#    「1이니 뜻이 없다」가 아니라, 표가 깨져 **0바퀴**를 돌아도 ✗ 0 으로 통과하는
#    것을 막는 자리다(어제 이 관문이 「DB 를 1곳만 봤다」로 결함을 잡았다).
[ "$SITE_SEEN" = "$SITES_WANT" ] && ok "앱 ${SITES_WANT}곳을 다 봤다 (표본이 비지 않았다)" \
  || bad "앱을 ${SITE_SEEN}곳만 봤다 — ${SITES_WANT}곳을 기대했다. SITES 표가 깨졌다"
say "앱 단계 — 새 판 ${PHASE_APP_NEW} · 옛 판 ${PHASE_APP_PRE} · 그 밖 ${PHASE_APP_ODD}"

# 1-ㄴ. 도구 하나
say ""
say "── 1-ㄴ. 🔴 도구 — **--tools 가 이 줄을 간다**"
say "🔴 마이그레이션이 0건인데도 도구를 가는 까닭은 **도구의 import 닫힘이 바뀌어서**"
say "   입니다. 64-build.sh 5-ㄹ 이 그것을 값으로 쟀습니다."
say "🔵 이번 판은 scripts/ 가 **한 장도 안 바뀌었습니다** — 바뀐 것은 그 둘이"
say "   **import 하는 쪽**입니다. 「scripts 가 0장이니 도구는 그대로다」가 틀린 자리입니다."
PHASE_TOOL_NEW=0; PHASE_TOOL_PRE=0; TOOL_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  SVC=$(field "$r" 2); NEW=$(field "$r" 3); OLD=$(field "$r" 4)
  NAME=$(field "$r" 6); WHY=$(field "$r" 7)
  TOOL_SEEN=$((TOOL_SEEN+1))
  cur=$(svc_image "$SVC")
  st=$(state_of "${cur:-}" "$OLD" "$NEW")
  case "$st" in NEW) PHASE_TOOL_NEW=$((PHASE_TOOL_NEW+1)) ;; PRE) PHASE_TOOL_PRE=$((PHASE_TOOL_PRE+1)) ;; esac
  printf '      %-10s %-16s %-24s %s\n' "$NAME" "$SVC" "${cur:-없음}" "$st"
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
        say "      🔴 **이번 판도 DB 가 안 바뀌므로 그 둘을 DB 로 가를 수 없습니다.**"
        say "      가르려면 **로그 파일 이름**(deploy60-go-… / deploy60-rollback-…)을 보세요." ;;
  POST) say "--go 까지 돌았습니다. --count 로 뒤의 수를 재세요." ;;
  ODD)  hm "단계가 섞여 있습니다 — 위 표를 사람이 보세요. **막지는 않습니다.**" ;;
esac

# 1-ㄷ. 🔴 안 건드리는 **아홉** — 「옆으로 안 샜다」는 증거
say ""
say "── 1-ㄷ. 🔴 안 건드리는 **아홉** — 도는가 · 어느 이미지인가 · 언제 켜졌는가"
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

# 1-ㅁ. 🔵 지난 판 묶음이 남아 있는가 — 🔴 **이 파일은 쳐다보지도 않는다**
say ""
say "── 1-ㅁ. 🔵 incoming 폴더 — 🔴 **이번 판도 묶음을 안 씁니다**"
mkdir -p "$INCOMING" 2>/dev/null; chmod 777 "$INCOMING" 2>/dev/null
ls -l "$INCOMING" 2>/dev/null | sed 's/^/        /'
if [ -f "$OLD_MIGTAR" ]; then
  hm "지난 판 묶음(as-migrations.tar.gz)이 남아 있습니다 — **이 배포본은 그것을 안 읽습니다**"
  say "      🔵 푸는 코드가 **한 줄도 없습니다.** 지워도 되고 둬도 됩니다."
  say "      🔴 **옛 폴더(_images-58·59)의 묶음을 새로 보내지는 마세요** — 쉰여섯째·"
  say "         쉰일곱째가 **두 판 연속** 옛 묶음을 보내 ✗ 를 냈습니다."
else
  ok "incoming 에 묶음이 없다 (이번 판은 쓸 일이 없다)"
fi

# ══════════════════════════════════════════════════════════════════════
# ── 2. 🔴 DB — **0건이다.** 「바뀌지 않았는가」를 잰다
# ══════════════════════════════════════════════════════════════════════
step "2. 🔴 DB — **마이그레이션 0건.** 「안 바뀌었는가」를 잰다"
say "🔵 **어제(63번)와 같습니다** — 이 절은 글자 그대로 가져왔습니다."
say "🔴 **빼지 않는 까닭**: 빼면 「운영 DB 가 지금 몇 건인지」를 아무도 안 보게 되고,"
say "   그 수가 어긋나면 **이 배포와 무관한 다른 사고**인데 끝까지 모릅니다."
say "🔵 이 절에는 **단계로 갈리는 가지가 없습니다** — 처음부터 끝까지 같은"
say "   기대값입니다. 뜻 없는 분기를 남기면 다음 판이 그것을 베껴 씁니다."

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
say "🔴 표 이름이 **셋으로 다릅니다**(A/S·재고 portal_… · 휴가 web_portal_… ·"
say "   포털 approval_delegations). 하나로 묻는 검사였으면 세 집이 ✗ 였습니다."

# 2-ㄷ. 🔴 A/S 마이그레이션 볼륨 — **131장 그대로여야 한다**
say ""
say "── 2-ㄷ. 🔴 A/S 마이그레이션 **볼륨** — 131장 그대로인가"
say "🔴 A/S 만 볼륨에서 돕니다. 🔵 **이번 판도 거기 더할 것이 0건**이라 묶음을"
say "   안 보냅니다 — 그래도 **줄었는지**는 봅니다. 줄었으면 다른 사고입니다."
VOL_SEEN=0
if [ -d "$MIGDIR" ]; then
  VOL_SEEN=$((VOL_SEEN+1))
  vs=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  vj=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  vnx=$(ls -1 "$MIGDIR/${AS_VOL_NEXT}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  printf '      볼륨 %s — .sql %s장 · journal idx %s개 · %s %s개(기대 0)\n' \
    "$MIGDIR" "${vs:-?}" "${vj:-?}" "$AS_VOL_NEXT" "${vnx:-?}"
  if [ "${vs:-x}" = "$AS_VOL_SQL_WANT" ] && [ "${vj:-x}" = "$AS_VOL_SQL_WANT" ]; then
    ok "볼륨이 **${AS_VOL_SQL_WANT}장**이고 목록도 ${AS_VOL_SQL_WANT}개다 (쉰여덟째가 올린 수 그대로)"
  else
    bad "볼륨이 .sql ${vs:-?} · idx ${vj:-?} 다 — ${AS_VOL_SQL_WANT} 을 기대했다"
    say "      🔴 **.sql 과 idx 가 다르면** 목록에 없는 파일이 있다는 뜻이고,"
    say "         drizzle 이 그것을 **아예 모릅니다**(적용이 0건으로 조용히 끝납니다)."
    doubt
  fi
  [ "${vnx:-1}" = "0" ] && ok "볼륨에 $AS_VOL_NEXT 이 없다 (마지막이 0130 그대로)" \
    || bad "볼륨에 $AS_VOL_NEXT 이 **있다** — 이 배포본은 0130 까지를 전제로 쓰였다. 멈추고 알릴 것"
  # 🔴 도구 이미지 안은 **비어 있어야** 한다 — 볼륨이 붙는 자리다.
  AST=$(svc_image tools-as)
  if [ -n "${AST:-}" ] && "$DOCKER" image inspect "$AST" >/dev/null 2>&1; then
    n=$(dock "$AST" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
    printf '      A/S 도구 이미지(%s) 안 %s 의 .sql: %s개 (기대 0 — 볼륨이 안 붙은 맨 이미지다)\n' "$AST" "$IMG_MIGDIR" "${n:-?}"
    if isnum "${n:-}" && [ "${n:-1}" = "0" ]; then ok "도구 이미지 안 drizzle/ 이 비어 있다 (볼륨이 정본이다)"
    else bad "도구 이미지 안에 .sql 이 ${n:-?}장 있다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다"; fi
  else
    unk "A/S 도구 이미지 안" "${AST:-태그를 못 읽음} 가 NAS 에 아직 없다 (--preload 전이면 정상)"
  fi
else
  bad "A/S 마이그레이션 볼륨이 없다 — $MIGDIR"
fi
[ "$VOL_SEEN" = "1" ] && ok "볼륨을 봤다" || bad "볼륨을 못 봤다"

# ══════════════════════════════════════════════════════════════════════
# ── 3. 들여올 tar **둘** ─────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════
step "3. 들여올 tar 둘 — **옮기다 깨졌는가** (🔵 묶음은 없다)"
say "🔴 지문은 **굽는 쪽에서 잰 값**입니다. NAS 에서 재서 채우면 자기가 잰 값으로"
say "   자기를 재는 꼴이 되어 **영영 통과합니다.**"
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
  printf '      %-28s %s바이트  md5 %s\n' "$T" "${sz:-?}" "${m5:-?}"
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
  say "   64-build.sh --go 가 꼬리말에 찍어 주는 **두 줄**을 이 파일의 TARS 에 그대로"
  say "   붙여 넣은 **뒤에** scp 하세요. 쉰세째에는 빈 표가 그대로 올라가 --preload 가"
  say "   ✗ 둘로 멈췄습니다."
fi

# ══════════════════════════════════════════════════════════════════════
# ── 4. 🔵 이번 판과 무관하지만 **빼지 않는** 검사들 ──────────────────
# ══════════════════════════════════════════════════════════════════════
step "4. 🔵 빼지 않는 검사 — 한 번 빼면 다시 넣는 사람이 없다"
# 4-ㄱ. 🔵 연락서 폴더
say "── 4-ㄱ. 연락서 폴더 — 🔵 이번 범위와 무관하지만 **A/S 가 늘 쓰는 자리**다"
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
  else bad "양식 폴더가 비었다 — 견적서·보고서 출력이 통째로 죽는다"; fi
else
  bad "양식 폴더가 없다 — $TPLDIR"
fi
# 4-ㄷ. 🔴 PO 가 repair_cases 에 쓸 수 있는가 — PO 를 안 건드려도 잰다
say ""
say "── 4-ㄷ. 🔴 PO 의 쓰기 권한 — PO 를 안 건드려도 잰다"
say "🔵 **이번 판은 PO 가 모르는 것을 늘리지 않습니다** — 읽는 쪽 기능이고 표를"
say "   한 글자도 안 건드립니다. 그래도 **빼지 않습니다**(한 번 빼면 안 돌아옵니다)."
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
#   🔴 **이 배포는 자료를 한 글자도 안 바꾼다.** 그래서 이 모드의 뜻은
#      **「전과 후가 같은가」**다. 🔵 두 번 돌려 같은 수가 나오는 것이 정상이다.
#   🔴 63번은 상태 **셋**을 셌다. 이번엔 **넷**이다(「발주 완료」가 생겼다).
#   🔴 **GROUP BY 1 을 쓰지 않는다.** 62번이 그것 때문에 질의 둘이 통째로 거절돼
#      **✓ 를 띄운 채 속이 비어** 있었다.
#   🔴 표·칸 이름은 전부 **스키마에서 확인한 것**이다(vendor/dss-core 의
#      domestic-orders.ts · repair-cases.ts). 지어내지 않았다.
effect_counts() {
  step "🔢 이 배포가 **보여 주는 것**이 달라지는 자리 — 세기만 한다 (전부 select)"
  say "🔵 이 배포는 **읽는 쪽 기능**입니다 — 자료를 한 글자도 안 바꿉니다."
  say "   그래서 **전과 후의 수가 같아야 정상**입니다."
  say "🔵 아래 괄호의 「참고」는 **2026-11-19 쉰아홉째 배포 뒤 운영 실측**입니다 —"
  say "   🔴 **✗ 를 내는 기대값이 아닙니다.** 사람이 줄을 더하거나 발주일을 적으면"
  say "   정상적으로 달라집니다. ✗ 를 내는 것은 **아래 여집합 관문 둘**뿐입니다."

  local t live done_ undone noorder issued both cust nocust
  say ""
  say "── ① 내자 줄 전체 (거르개가 걸리는 바탕)"
  t=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders")
  live=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false")
  printf '      domestic_orders 전체 %s줄 · 휴지통 밖 %s줄 (참고 %s)\n' "${t:-?}" "${live:-?}" "$CNT_LIVE_REF"
  if [ -z "${t:-}" ]; then unk "내자 줄 수" "못 쟀다 — dss-pg-app 이 도는지 보세요"
  elif [ -z "${live:-}" ]; then hm "전체는 ${t}줄인데 **휴지통 밖을 못 쟀다** — 질의가 거절됐을 수 있습니다"
  elif [ "${live:-0}" -ge 1 ] 2>/dev/null; then
    ok "내자 줄 ${t}줄 (휴지통 밖 ${live}줄 — **이 화면이 보는 것이 이쪽입니다**)"
    [ "${live}" = "$CNT_LIVE_REF" ] || hm "휴지통 밖이 참고값 $CNT_LIVE_REF 와 다릅니다 (${live}) — 사람이 줄을 더했을 수 있습니다"
  else
    hm "휴지통 밖이 0줄입니다 — **그러면 거르개가 아무것도 안 거릅니다.** 사람이 보세요"
  fi

  say ""
  say "── ② 🔴 **상태 거르개 넷**이 실제로 뽑는 줄 (화면과 같은 판정으로 센다)"
  say "🔴 63번은 여기가 **셋**이었습니다. 이번 판에 **「발주 완료」가 생겨 넷**입니다."
  say "🔴 「발주 대기」는 코드에서 **order_issued_date 가 NULL 인 한 줄**이고"
  say "   「발주 완료」는 그 **정확한 여집합**입니다(공백 접기를 둘 다 안 합니다 —"
  say "   화면의 배지와 **같은 한 줄**이라야 사람이 필터를 믿습니다)."
  say "🔵 **이름만 바뀐 줄입니다** — 2026-11-18 의 「발주일 미정」과 **같은 줄**을"
  say "   이제 「발주 대기」로 부릅니다. 세는 질의는 한 글자도 안 바뀌었습니다."
  done_=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and completed_at is not null")
  undone=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and completed_at is null")
  noorder=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and order_issued_date is null")
  # 🔴 **이 한 줄이 ② 의 「발주 완료」이자 ④ 의 「세모가 세우는 줄」이다.**
  #    뜻이 둘이라 두 자리에 적지만 **값은 한 번만 잰다** — 두 번 재면 사람이
  #    「다른 수인가」를 묻고, 그 사이 누가 발주일을 적으면 두 수가 실제로 갈린다.
  issued=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and order_issued_date is not null")
  printf '      완료됨 %s(참고 %s) · 미완료 %s(참고 %s) · 발주 대기 %s(참고 %s) · 발주 완료 %s(참고 %s)\n' \
    "${done_:-?}" "$CNT_DONE_REF" "${undone:-?}" "$CNT_UNDONE_REF" "${noorder:-?}" "$CNT_NOORDER_REF" "${issued:-?}" "$CNT_ISSUED_REF"
  if [ -z "${done_:-}" ] || [ -z "${undone:-}" ] || [ -z "${noorder:-}" ] || [ -z "${issued:-}" ]; then
    bad "넷 중 못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
  else
    ok "상태 거르개 **넷**의 줄 수를 다 쟀다 (완료 ${done_} · 미완료 ${undone} · 발주 대기 ${noorder} · 발주 완료 ${issued})"
  fi

  say ""
  say "── ②-ㄴ 🔴 **여집합 관문 둘** — 여기만 ✗ 를 냅니다"
  say "🔴 완료됨 + 미완료 == 휴지통 밖 (completed_at 하나로 갈리는 반대쪽)"
  say "🔴 발주 대기 + 발주 완료 == 휴지통 밖 (order_issued_date 하나로 갈리는 반대쪽)"
  say "🔵 **이 관문이 실제로 잡는 것은 질의 하나가 조용히 거절된 것**입니다 —"
  say "   order_issued_date 는 **date 칸**이라 DB 쪽에는 빈 문자열이 애초에 못"
  say "   들어갑니다. 🔴 다만 누가 나중에 한쪽 질의에만 공백 접기를 더하면"
  say "   **그때 이 줄이 울립니다.** 그러라고 둔 자리입니다."
  if [ -n "${live:-}" ] && [ -n "${done_:-}" ] && [ -n "${undone:-}" ]; then
    printf '      완료됨 %s + 미완료 %s = %s (휴지통 밖 %s)\n' "$done_" "$undone" "$((done_ + undone))" "$live"
    if [ "$((done_ + undone))" = "$live" ]; then ok "완료됨 + 미완료 == 휴지통 밖 (${live})"
    else bad "완료됨 + 미완료 가 $((done_ + undone)) 다 — 휴지통 밖 ${live} 를 기대했다"; doubt; fi
  else
    unk "완료 여집합 관문" "앞의 수 중 못 잰 것이 있다"
  fi
  if [ -n "${live:-}" ] && [ -n "${noorder:-}" ] && [ -n "${issued:-}" ]; then
    printf '      발주 대기 %s + 발주 완료 %s = %s (휴지통 밖 %s)\n' "$noorder" "$issued" "$((noorder + issued))" "$live"
    if [ "$((noorder + issued))" = "$live" ]; then ok "발주 대기 + 발주 완료 == 휴지통 밖 (${live})"
    else
      bad "발주 대기 + 발주 완료 가 $((noorder + issued)) 다 — 휴지통 밖 ${live} 를 기대했다"
      say "      🔴 **질의 하나가 거절됐거나, 한쪽에만 공백 접기가 섞였습니다.**"
      doubt
    fi
  else
    unk "발주 여집합 관문" "앞의 수 중 못 잰 것이 있다"
  fi

  say ""
  say "🔴 **상태 넷은 쌍과 쌍 사이에서 배타적이 아닙니다** — 아래 수가 그 증거입니다."
  both=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and completed_at is not null and order_issued_date is null")
  printf '      완료됨이면서 발주 대기인 줄 %s개\n' "${both:-?}"
  if [ -z "${both:-}" ]; then unk "겹치는 줄 수" "못 쟀다"
  elif [ "${both:-0}" -ge 1 ] 2>/dev/null; then
    ok "겹치는 줄이 ${both}개 있다 — 🔴 **거르개가 OR 이라야 맞다는 실물 증거다**"
    say "      🔵 교집합이었으면 「완료됨 + 발주 대기」가 **이 ${both}줄만** 나왔을"
    say "         것이고, 사람은 그 뜻으로 고르지 않습니다."
  else
    ok "겹치는 줄이 0개다 (🔵 지금은 없지만 **생길 수 있습니다** — 완료 처리에"
    say "      「발주일이 적혀 있어야 한다」는 관문이 없습니다)"
  fi

  say ""
  say "── ③ 🔴 **고객사 거르개**의 후보 수 (화면은 **올라온 줄에서** 뽑는다)"
  say "🔴 화면의 고객사는 **내자 줄 자신의 고객사**이고, 비어 있으면 **붙어 있는**"
  say "   **수리 건의 고객사**를 빌려 옵니다(queries/domestic-orders.ts 의"
  say "   resolveDomesticOrderValue). 그래서 domestic_orders.customer_id 만 세면"
  say "   **적게 나옵니다** — 여기서는 **빌려 오는 쪽까지 이어서** 셉니다."
  cust=$(pgn dss-pg-app dss_as "select count(distinct coalesce(d.customer_id, r.customer_id)) from domestic_orders d left join repair_cases r on r.id = d.repair_case_id where d.is_deleted = false")
  nocust=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders d left join repair_cases r on r.id = d.repair_case_id where d.is_deleted = false and coalesce(d.customer_id, r.customer_id) is null")
  printf '      고객사 가짓수 %s(참고 %s) · 고객사를 못 찾는 줄 %s개(참고 %s · = 드롭다운의 「미지정」)\n' \
    "${cust:-?}" "$CNT_CUST_REF" "${nocust:-?}" "$CNT_NOCUST_REF"
  if [ -z "${cust:-}" ]; then
    unk "고객사 가짓수" "못 쟀다 — 이어 세는 질의가 거절됐을 수 있습니다"
    say "      🔵 **이 줄이 ? 면 아래 판단을 하지 마세요.** 빈 결과는 삼켜진 오류일 수 있습니다."
  elif [ "${cust:-0}" -ge 1 ] 2>/dev/null; then
    ok "고객사 거르개에 ${cust}가지가 설 수 있다 (미지정 줄 ${nocust:-?}개)"
    say "      🔵 **드롭다운에 실제로 서는 수는 이보다 적을 수 있습니다** — 화면은"
    say "         **지금 올라온 줄**(년도·검색이 걸린 뒤)에서 뽑습니다."
  else
    hm "고객사 가짓수가 0 입니다 — **그러면 고객사 칸이 빈 채로 섭니다.** 사람이 보세요"
  fi

  say ""
  say "── ④ 🔵 **발주발행일 세우기**가 실제로 할 일이 있는가"
  say "🔵 세모는 **고객사 묶음 안에서만** 세웁니다. 세울 줄이 하나뿐이면 눌러도"
  say "   눈에 보이는 변화가 없습니다 — 그때 「고장」으로 신고가 들어옵니다."
  say "🔴 **여기서 다시 재지 않습니다** — 「발행일이 적힌 줄」은 ② 의 **「발주 완료」와**"
  say "   **글자 그대로 같은 질의**입니다. 두 번 재면 사람이 「다른 수인가」를 묻고,"
  say "   그 사이 누가 발주일을 적으면 두 수가 실제로 갈립니다. 🔵 **같은 수인 것이**"
  say "   **맞습니다** — 뜻이 둘(거르개의 한 줄 · 세모가 세우는 줄)일 뿐입니다."
  printf '      발주발행일이 적혀 있는 줄 %s개 (② 의 「발주 완료」와 같은 값)\n' "${issued:-?}"
  if [ -z "${issued:-}" ]; then unk "발행일 있는 줄 수" "② 에서 이미 ✗ 를 냈습니다"
  elif [ "${issued:-0}" -ge 2 ] 2>/dev/null; then ok "발행일이 있는 줄이 ${issued}개다 (세울 거리가 있다)"
  else hm "발행일이 있는 줄이 ${issued}개뿐입니다 — **눌러도 눈에 안 보일 수 있습니다.** 사람이 보세요"; fi

  say ""
  say "── ⑤ 🔴 **A/S 가 답하는가** — 집이 하나라 이것이 가장 큰 값이다"
  local rr pt c
  rr=$(row_by_key "$SITES" as); pt=$(field "$rr" 7)
  c=$(http_code "$pt")
  printf '      A/S 127.0.0.1:%s → %s\n' "$pt" "${c:-못 읽음}"
  if http_ok "${c:-}"; then ok "A/S 가 답한다 ($c — 307 은 로그인으로 보내는 것이다)"
  else bad "A/S 가 $c 를 돌려준다"; fi
}

if [ "$MODE" = "--count" ]; then
  effect_counts
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '%s\n' "🔵 --count 는 **아무것도 안 바꿉니다.** 올리기 전과 뒤에 한 번씩 돌려 맞대세요."
  printf '%s\n' "   🔴 이번 판도 **같은 수가 나오는 것이 정상**입니다(읽는 쪽 기능입니다)."
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
  [ "$FAIL" = "0" ] && [ "$UNK" = "0" ] && exit 0
  exit 1
fi

# 🔴 여기부터는 **바꾸는 모드**다. ✗ 가 있으면 가지 않는다.
if [ "$FAIL" != "0" ]; then
  stop "✗ 가 ${FAIL}개 있습니다. 위를 보세요 — **아무것도 안 바꿨습니다.**"
fi

# ══════════════════════════════════════════════════════════════════════
# ══ 이미지 안을 재는 길 (--preload 가 쓴다) ═══════════════════════════
# ══════════════════════════════════════════════════════════════════════
#   🔴 **앱과 도구는 담긴 것이 다르다** — 앱은 번들, 도구는 소스 그대로다.
#      한 잣대로 재면 가짜 ✗ 가 난다.
#   🔵 넷째 인자는 **판정에 안 쓰는 곁들이 값**이다(따옴표 꼴을 가르려고 찍는다).
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
      say "      🔴 **따옴표만 안 맞는 것입니다** — 곁들인 글자는 번들에 있습니다."
      say "         번들이 홑따옴표로 적었다는 뜻이니 **올리지 말고 개발 PC 에서 다시**"
      say "         **재세요**(64-build.sh --verify). 이미지를 다시 구울 일은 아닙니다."
    fi
  fi
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
    v=$(dock "$NEW" -c 'if [ -d /app/public ]; then printf "yes %s\n" "$(ls -1 /app/public 2>/dev/null | wc -l)"; else printf "no 0\n"; fi')
    pst=$(printf '%s' "$v" | awk '{print $1}'); pn=$(printf '%s' "$v" | awk '{print $2}')
    printf '        /app/public: %s (파일 %s개 · 기대 %s)\n' "${pst:-못 읽음}" "${pn:-?}" "$AS_PUBLIC_WANT"
    if [ "${pst:-}" != "$AS_PUBLIC_WANT" ]; then
      bad "$NAME 의 /app/public 이 ${pst:-못 읽음} 다 — $AS_PUBLIC_WANT 를 기대했다"
      say "      🔵 없으면 정적 파일이 404 가 됩니다(새 사이트에서 걸리는 셋 중 하나)."
    elif [ "${pn:-0}" -ge 1 ] 2>/dev/null; then ok "$NAME public/ 이 담겼다 (${pn}개)"
    else bad "$NAME public/ 은 있는데 **비어 있다** — A/S 는 9개를 기대했다"; fi
    bundle_mark "$NEW" "$APPMARK"   "$NAME 번들에 **이번 판의 글자**가 있다 (상태 거르개의 네 번째 값)" "$APPMARK_DIAG"
    bundle_mark "$NEW" "$KEEPMARK1" "$NAME 에 **쉰아홉째가 올린 글자**가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$NEW" "$KEEPMARK2" "$NAME 에 **쉰여덟째가 올린 글자**가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$NEW" "$KEEPMARK3" "$NAME 에 **쉰여섯째가 올린 글자**가 그대로 있다 (뒷걸음친 나무가 아니다)"
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
    # 🔴 **경로를 상대로 넘기고 /app/ 를 컨테이너 안에서 붙인다**(⑬).
    #    🔴 그리고 yes/no 가 아니라 **센 줄 수**를 받는다 — 0 과 「못 읽음」을 가른다.
    #    🔵 이 표식은 **파일을 좁혔다** — 같은 글자가 화면 파일의
    #       ORDER_ISSUED_SORT_HINT 에도 걸리지만 **이 파일에는 그것이 없다**(머리말 ①).
    v=$("$DOCKER" run --rm -e M="$TOOLMARK" -e F="$TOOLMARK_FILE" --entrypoint sh "$NEW" -c \
      'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s\n" "$(grep -cF -- "$M" "$p")"; else printf "missing 0\n"; fi' </dev/null 2>/dev/null | tr -d '\r')
    tst=$(printf '%s' "$v" | awk '{print $1}'); tn=$(printf '%s' "$v" | awk '{print $2}')
    printf '        마지막 커밋 표식 [%s] in %s — 파일 %s · 그 글자 %s줄 (기대 hit · %s)\n' \
      "$TOOLMARK" "$TOOLMARK_FILE" "${tst:-못 읽음}" "${tn:-?}" "$TOOLMARK_LINES_WANT"
    if [ "${tst:-}" = "hit" ] && [ "${tn:-0}" -ge 1 ] 2>/dev/null; then
      ok "$NAME **이번 판의 커밋이 담겼다** (${tn}줄)"
      [ "${tn}" = "$TOOLMARK_LINES_WANT" ] || hm "그 글자가 ${tn}줄입니다 — $TOOLMARK_LINES_WANT 을 기대했습니다. 사람이 보세요"
    elif [ "${tst:-}" = "hit" ]; then
      bad "$NAME 에 이번 판의 글자가 **0줄**이다 — **옛 소스가 담긴 이미지다**"
    elif [ "${tst:-}" = "missing" ]; then
      bad "$NAME 에 그 파일 자체가 없다 — src/ 가 온전히 안 담겼다"
    else
      bad "$NAME 의 표식을 못 읽었다 (받은 값 [${v:-}])"
    fi
    # 🔴 **도구를 가는 까닭의 실물** — import 하는 scripts/ 둘이 담겼는가.
    #    🔵 없는 경로 하나를 함께 묻는다 — 「무조건 yes」인 검사인지 가른다.
    v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c \
      'set -f; n=0; m=0; for f in scripts/lib/delivered-date-sync-survey.ts scripts/lib/requested-due-date-sync-survey.ts; do [ -f "/app/$f" ] && n=$((n+1)); done; [ -f "/app/src/__dss_probe_no_such_file__.ts" ] && m=1; printf "n=%s miss=%s\n" "$n" "$m"' </dev/null 2>/dev/null | tr -d '\r')
    g=$(printf '%s' "$v" | sed -n 's/.*n=\([0-9]*\).*/\1/p')
    mm=$(printf '%s' "$v" | sed -n 's/.*miss=\([0-9]*\).*/\1/p')
    printf '        바뀐 모듈을 import 하는 scripts/ 둘: %s개 (기대 2) · 없는 경로가 있다고 나왔나 %s (기대 0)\n' "${g:-?}" "${mm:-?}"
    # 🔴 **빈 결과와 「1」을 가른다** — 둘 다 ✗ 지만 **까닭이 반대**다. 한 말로
    #    뭉개면 다음 사람이 엉뚱한 곳을 판다(「빈 결과는 삼켜진 오류일 수 있다」).
    if [ -z "${mm:-}" ] || [ -z "${g:-}" ]; then
      bad "$NAME — **컨테이너에서 값을 못 받았다** (받은 값 [${v:-}]). 위 수를 믿지 마세요"
    elif [ "${mm:-1}" != "0" ]; then
      bad "$NAME — **없는 경로가 있다고 나왔다.** 「무조건 yes」인 검사다. 위 수도 못 믿는다"
    elif [ "${g:-x}" = "2" ]; then
      ok "$NAME 에 그 둘이 담겼다 — 🔴 **이것이 도구를 가는 까닭의 실물이다**"
      say "      🔵 그 둘이 import 하는 domestic-order-list.ts 가 이번에 +54/−22 바뀌었습니다."
    else
      bad "$NAME 에 그 둘이 ${g:-?}/2 개다 — scripts/ 가 온전히 안 담겼다"
    fi
    # 🔴 A/S 도구는 drizzle 을 **안 담아야** 한다 — 볼륨이 정본이다.
    n=$(dock "$NEW" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
    printf '        %s 안 .sql: %s장 (기대 0 — 볼륨이 정본이다)\n' "$IMG_MIGDIR" "${n:-?}"
    if isnum "${n:-}" && [ "${n:-1}" = "0" ]; then ok "$NAME 은 drizzle/ 이 **비어 있다**"
    else bad "$NAME 안에 .sql 이 ${n:-?}장 있다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다"; fi
    # 🔴 **공용 스키마** — 핀이 안 움직여도 **빈 서브모듈이 담길 수 있다**.
    v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c 'for pair in "portal_approval_delegations /app/vendor/dss-core/src/schema/portal-approval-delegations.ts" "portal-approval-delegations /app/vendor/dss-core/src/schema/index.ts" "due_date_row_order /app/vendor/dss-core/src/schema/repair-case-approvals.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' </dev/null 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/          /'
    g=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
    if [ "${g:-0}" = "3" ]; then
      ok "$NAME 에 **쉰여덟째가 올린 공용 스키마가 그대로 담겼다** (표 + index 내보내기 + 지난 판의 칸)"
      say "      🔵 index.ts 가 안 내보내면 도구가 그 표를 **못 찾습니다** — 2026-09-21 에"
      say "         운영에서 도구가 전부 죽은 그 자리입니다."
    else bad "$NAME 의 공용 스키마가 셋 중 ${g:-0}개다 — **빈 서브모듈이나 옛 판이 담겼다**"; fi
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
#   🔴 **dss_as 하나만 뜬다**(62번은 넷이었다 — 네 집의 스키마가 바뀌었다).
#   🔵 이 배포는 DB 를 한 글자도 안 바꾼다. 그래도 뜨는 까닭은 **새 앱이 쓰는 쪽에서
#      무엇을 할지는 이 배포본이 모르기** 때문이다. 오래 걸리지 않는다.
make_dump() {
  mkdir -p "$BKDB" 2>/dev/null; chmod 777 "$BKDB" 2>/dev/null
  say "🔵 덤프 자리: $BKDB (🔴 받을 폴더는 777 이어야 scp·컨테이너가 쓸 수 있습니다)"
  local f sz
  f="$BKDB/dss_as-$DUMP_VER-$STAMP.dump"
  printf '    뜨는 중 dss_as …\n'
  # 🔵 pg_dump 도 stdin 을 안 읽는다 — -i 를 떼고 </dev/null 을 붙인다.
  if "$DOCKER" exec dss-pg-app sh -c "pg_dump -U \"\$POSTGRES_USER\" -d dss_as -Fc" </dev/null > "$f" 2>/dev/null; then
    sz=$(stat -c %s "$f" 2>/dev/null)
    if isnum "${sz:-}" && [ "${sz:-0}" -gt 1000 ]; then
      ok "dss_as 덤프 ${sz}바이트 — $f"
      return 0
    fi
    bad "dss_as 덤프가 ${sz:-0}바이트다 — **쓸 수 없는 덤프다**"
    return 1
  fi
  bad "dss_as 덤프를 못 떴다 — dss-pg-app 이 도는지 보세요"
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
  say "🔴 62번에는 이 자리가 **--migrate** 였습니다 — 네 집에 일곱 건을 올렸습니다."
  say "   🔴 **이번 판도 마이그레이션이 0건**이라 올릴 것이 없습니다. 그 대신"
  say "   **도구의 import 닫힘이 바뀌어서** 도구 태그를 갑니다."
  say "🔵 profiles: [tools] 라 평소에 뜨지 않습니다 — **직원이 느끼는 것이 없습니다.**"
  if [ "$PHASE_TOOL_NEW" = "$TOOLS_WANT" ]; then
    ok "도구가 이미 새 판이다 — 바꿀 것이 없다"
    say "🔵 그래도 아래에서 **db:preflight 와 DB 수**는 다시 잽니다."
  fi

  say ""
  say "── 6-ㄱ. 🔴 되돌릴 길부터 만든다 — **덤프 한 장**(dss_as)"
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
  say "── 6-ㄹ. 🔴 **새 도구가 실제로 도는가** — db:preflight 를 값으로 받는다"
  say "🔴 이번 판도 **도구의 import 닫힘이 바뀐 판**입니다. 그것이 끊겼으면"
  say "   여기서 **Cannot find module** 로 드러납니다 — 그게 이 줄의 전부입니다."
  say "🔵 db:preflight 는 **읽기만 합니다**(Dockerfile 85~87줄의 기본 명령입니다)."
  say "🔵 이번 판의 기대값은 **대기 0건**입니다."
  # 🔴 서비스 이름을 **여기 다시 적지 않는다** — TOOLS 표에서 꺼낸다.
  #    두 곳에 적으면 표를 고친 날 한 곳만 바뀌고, 그때 나는 오류는
  #    「서비스를 못 찾았다」라 **도구 이미지 탓처럼 보인다.**
  PFSVC=$(field "$(row_by_key "$TOOLS" astools)" 2)
  if [ -z "${PFSVC:-}" ]; then
    bad "TOOLS 표에서 astools 의 서비스 이름을 못 꺼냈다 — 표가 깨졌다"
    stop "앱은 한 줄도 안 건드렸습니다."
  fi
  say "도구 서비스: $PFSVC (TOOLS 표에서 꺼낸 값입니다)"
  dct run --rm "$PFSVC" npm run db:preflight 2>&1 | sed 's/^/      /'
  PRC=${PIPESTATUS[0]}
  say "(종료 코드 $PRC — 기대 0)"
  if [ "$PRC" = "0" ]; then
    ok "새 도구가 db:preflight 를 끝까지 돌았다 (import 가 닫혀 있다)"
    say "      🔴 위 글에 **대기 건수**가 적혀 있습니다. **0건이어야 합니다** —"
    say "         0 이 아니면 누가 볼륨에 .sql 을 넣었다는 뜻이니 **멈추고 알리세요.**"
  else
    bad "db:preflight 가 0 이 아니다 ($PRC)"
    say "      🔴 **Cannot find module 이 보이면** 도구 이미지에 담긴 것이 모자랍니다"
    say "         (vendor/dss-core 나 src/ 가 빠진 것입니다)."
    say "      🔴 그 밖이면 **볼륨에 사라질 자료가 있다는 뜻**입니다."
    say "      🔵 **도구 줄은 이미 갈았습니다.** 되돌리려면 compose 사본: $BK"
    stop "앱은 한 줄도 안 건드렸습니다. 직원이 보는 화면은 그대로입니다."
  fi

  say ""
  say "── 6-ㅁ. 🔴 **DB 가 정말 안 바뀌었는가** — 다섯 집을 다시 센다"
  say "🔴 이 모드는 DB 에 **쓰는 명령을 한 줄도 안 돌렸습니다.** 그래도 다시 재는"
  say "   까닭은, db:preflight 가 읽기 전용이라는 것을 **값으로 보이기** 위해서입니다."
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
  printf '\n%s\n' "✅ 도구가 새 판을 가리키고, 새 도구가 실제로 돕니다."
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
#     까닭은 compose 의 app-as 에 **depends_on: db-app (condition: service_healthy)**
#     가 걸려 있어서다 — 「compose up -d app-as」 가 **의존 서비스까지 손댄다.**
#   🔴 --no-deps 는 「DB 가 떠 있다」를 compose 에게 맡기지 않겠다는 뜻이다.
#      그래서 **아래 go_gate() 가 그것을 직접 값으로 잰다** — 도는가 + **답하는가.**
#   🔵 「up -d」 자체는 그대로다. 바뀌는 것은 **의존 서비스를 손대지 않는 것**뿐이다.
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
  printf '      상자 %-10s 도는 이미지 %-24s 127.0.0.1:%s → %s (기다린 시간 %s초)\n' \
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
go_gate() {
  local s v
  say "── 🔴 **--no-deps 관문** — 의존 서비스를 compose 에게 안 맡기므로 직접 잰다"
  s=$("$DOCKER" inspect -f '{{.State.Status}}' dss-pg-app 2>/dev/null)
  printf '      dss-pg-app 상자: %s (기대 running)\n' "${s:-없음}"
  if [ "${s:-}" != running ]; then
    bad "dss-pg-app 이 ${s:-없음} 다 — **DB 가 안 돌면 앱이 서도 아무것도 못 합니다**"
    return 1
  fi
  ok "dss-pg-app 이 돈다"
  v=$(mig_count dss-pg-app dss_as)
  printf '      dss-pg-app 이 **답하는가**: dss_as 마이그레이션 수 %s (기대 %s)\n' "${v:-못 읽음}" "131"
  if [ "${v:-x}" != "131" ]; then
    bad "dss-pg-app 이 답을 안 하거나 수가 다르다 (${v:-못 읽음})"
    say "      🔴 **「도는가」만 보면 안에서 죽은 DB 를 못 가릅니다** — 그래서 값을 받습니다."
    return 1
  fi
  ok "dss-pg-app 이 **실제로 답한다** (dss_as 131)"
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
    say "      🔴 --no-deps 가 안 들었습니다. **compose 의 depends_on 을 보세요** —"
    say "         app-as 에 db-app(condition: service_healthy)이 걸려 있습니다."
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
    say "      🔴 다섯 집의 마이그레이션 수가 **131·28·5·11·3** 이 아닙니다."
    say "         이 배포본은 마이그레이션을 **한 건도 올리지 않습니다** — 수가"
    say "         달라졌다면 **이 배포와 무관한 다른 사고**입니다."
    stop "**아무것도 안 바꿨습니다.** 사람이 보세요."
  fi
  ok "DB 가 전과 같다 (이 배포는 DB 를 바꿀 것이 없다)"

  # 🔴 관문 ② — 도구가 새 판인가(--tools 가 돌았는가)
  if [ "$PHASE_TOOL_NEW" != "$TOOLS_WANT" ]; then
    bad "도구가 ${PHASE_TOOL_NEW}/${TOOLS_WANT} 만 새 판이다 — --tools 가 안 돌았다"
    say "      🔴 --tools 가 **덤프를 뜨고** 새 도구로 **db:preflight 를 돌려**"
    say "         import 가 닫혀 있는지 값으로 받습니다. 그 둘을 건너뛰지 마세요."
    stop "먼저 --tools 를 돌리세요. **아무것도 안 바꿨습니다.**"
  fi
  ok "도구가 새 판이다 (--tools 가 돌았다 — 덤프와 preflight 가 끝났다)"

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
  printf '%s\n' "🔴 **배포 뒤에 눈으로 볼 곳 — [내자 정리] 의 [상태] 드롭다운 하나입니다**"
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "  ① 🔴 **[상태] 드롭다운이 네 줄**이어야 합니다 — 위에서부터"
  printf '%s\n' "     **완료됨 · 미완료 · 발주 대기 · 발주 완료**."
  printf '%s\n' "     🔵 셋만 보이고 셋째가 「발주일 미정」이면 **옛 판**입니다."
  printf '%s\n' "  ② 🔴 **「발주 대기」는 이름만 바뀐 줄**입니다 — 어제의 「발주일 미정」과"
  printf '%s\n' "     **같은 줄을 가리킵니다.** 거른 결과가 어제와 같아야 맞습니다."
  printf '%s\n' "  ③ 🔴🔴 **같은 줄을 화면이 두 말로 부릅니다 — 고장이 아닙니다.**"
  printf '%s\n' "     거르개는 「발주 대기」, 그런데 **발주발행일 칸의 배지 · 주황 안내**"
  printf '%s\n' "     **(「발주일 미정 N건」) · 기타건 칸 · 내자 상세**는 그대로"
  printf '%s\n' "     **「발주일 미정」**입니다. 🔴 **2026-11-19 사용자 결정**입니다"
  printf '%s\n' "     (「필터 이름만 바꾸자」). 🔴 **「통일해 드릴까요」를 다시 묻지 마세요.**"
  printf '%s\n' "  ④ 🔴 **「발주 완료」는 「발주 대기」의 정확한 여집합**입니다."
  printf '%s\n' "     🔵 둘을 **다 켜면 전체**가 됩니다 — 합집합(OR)의 당연한 결과이고"
  printf '%s\n' "        고장이 아닙니다(「완료됨 + 미완료」도 같습니다)."
  printf '%s\n' "     🔵 「발주 완료」로 거른 줄에는 **발주일 미정 배지가 하나도 없어야**"
  printf '%s\n' "        합니다. 하나라도 보이면 판정이 두 곳에서 갈라진 것입니다."
  printf '%s\n' "  ⑤ 🔵 **「완료됨 + 발주 대기」를 같이 켜 보세요** — 둘 중 하나라도"
  printf '%s\n' "     해당되는 줄이 **다** 나와야 합니다(교집합이 아닙니다)."
  printf '%s\n' "  ⑥ 🔵 **어제 것이 그대로 있는지도 보세요**(뒷걸음 눈 확인) —"
  printf '%s\n' "     [상태]·[고객사] 드롭다운이 「검색」·「발주 년도」와 **한 줄에 나란히**"
  printf '%s\n' "     서 있고, **발주발행일 머리글의 세모**가 그대로 눌립니다."
  printf '%s\n' "  ⑦ 🔵 **[전체 A/S 현황]·[기타건 현황]은 한 픽셀도 안 바뀝니다.**"
  printf '%s\n' "     🔴 거기가 달라져 보이면 **되돌리세요.**"
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
  printf '%s\n' "   🔵 덤프: $BKDB · compose 사본: $BK"
  printf '%s\n' "  다음: bash $0 --count  ← 올린 뒤 수를 재어 앞의 수와 맞대세요"
  printf '%s\n' "        🔴 이번 판도 **같은 수가 나오는 것이 정상**입니다."
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════
# ── 8. --rollback : 앱 하나만 되돌린다 ──────────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--rollback" ]; then
  step "8. --rollback — 앱 하나를 옛 태그로 되돌린다"
  say "🔵 **도구는 새 판 그대로 둡니다**(39·41~63번과 같은 판단) — profiles: [tools]"
  say "   라 평소에 뜨지 않고, 옛 앱이 도구를 부르는 일도 없습니다."
  say "🔵 **DB 는 되돌릴 것이 없습니다** — 이 배포는 DB 를 한 글자도 안 바꿨습니다."
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
  printf '%s\n' "      이번 판도 DB 가 안 바뀌어 **그 둘을 DB 로 가를 수 없습니다.**"
  printf '%s\n' "      가르려면 **로그 파일 이름**(deploy60-go-… / deploy60-rollback-…)을 보세요."
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi
