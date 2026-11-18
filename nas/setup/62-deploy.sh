#!/bin/bash
# dss-deploy/nas/setup/62-deploy.sh — 쉰여덟째 배포 (2026-11-18)
#
# 🔴 **NAS 에서 돈다.** DSM 터미널에서 sudo -i 뒤에 부른다.
#     bash /volume1/dss/setup/62-deploy.sh            ← --check (기본 · 아무것도 안 바꾼다)
#     bash /volume1/dss/setup/62-deploy.sh --count
#     bash /volume1/dss/setup/62-deploy.sh --preload
#     bash /volume1/dss/setup/62-deploy.sh --migrate
#     bash /volume1/dss/setup/62-deploy.sh --go
#     bash /volume1/dss/setup/62-deploy.sh --rollback
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 지난 판과 근본부터 다른 점 — 집이 여섯이다**
# ══════════════════════════════════════════════════════════════════════
#   55~61번은 **A/S 한 집**만 올렸다. 이번은 **앱 여섯 · 도구 다섯 ·
#   마이그레이션 네 집 일곱 건**이다.
#
#   올리는 것 한 줄: 결재권 위임을 **포털 한 곳에서** 관리하고 A/S·재고관리·
#   휴가 **세 집에 전파**하는 기능 전체 + 통합 승인함이 **처음 갖는 자체 화면** +
#   포털 **종 알림** + A/S 의 **파일 올리기 개선** + 모바일 폭 손질 넷 +
#   계측기 **수동 발송 단추**.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **집 올리는 순서와 그 까닭** — 이 배포에서 가장 중요한 결정이다
# ══════════════════════════════════════════════════════════════════════
#   근거는 **코드 한 문장**이다. 포털의 전파 코드 머리말에 이렇게 적혀 있다
#   [실측 dss-auth/src/lib/approvals/delegation-push.ts · 설계 B-13]:
#
#       「한 곳이라도 못 적으면 포털도 적지 않는다.」
#       POST {시스템}/api/integration/delegations
#       200 {outcome:"stored"} 또는 {outcome:"not_applicable"} 만 성공,
#       그 밖(4xx·5xx·망 오류·시간 초과)은 **전파 실패 = 지정 거절**.
#
#   ── 🔴 그래서 **받는 집 셋이 먼저**다.
#      포털을 먼저 세우면, 아직 그 통로가 없는 집이 **404** 를 돌려주고
#      **위임 지정이 통째로 거절된다.** 사람이 보는 것은 「맡기기 실패」다.
#      반대로 받는 집을 먼저 세우면, 아무도 그 통로를 부르지 않는다 —
#      **표가 비어 있고 화면은 오늘과 같다.** 조용히 아무 일도 안 일어난다.
#
#   ── 🔴 **승인함은 포털 뒤**다.
#      위임을 맡기는 **화면은 승인함**에 있고 **자료는 포털**에 저장된다
#      (2026-11-13 결정). 승인함의 새 화면은 포털의
#      /api/integration/delegations 를 부른다[실측 dss-approvals/src/lib/
#      approvals/portal-delegations.ts 445줄]. 포털이 옛 판이면 그 화면이
#      **첫 걸음에서 실패**한다.
#
#   ── 🔵 **계측기는 아무 데나 와도 된다** — 이 기능과 상관이 없다.
#      그래서 **맨 뒤**에 둔다. 앞의 다섯이 끝난 뒤에 따로 보면 된다.
#
#   ── 🔴 **마이그레이션은 앱보다 먼저, 그리고 네 집을 한 번에.**
#      --migrate 가 끝나면 네 집에 표가 **다 있고** 앱은 **전부 옛 판**이다.
#      옛 앱은 그 표를 **쳐다보지도 않는다**(읽는 코드가 아예 없다) —
#      그 사이가 몇 분이어도 아무 일이 없다.
#      🔴 --migrate 안에서도 순서가 있다: **A/S → 재고 → 휴가 → 포털.**
#         까닭은 **포털 0010 이 유일하게 위험한 문장을 들고 있기 때문**이다
#         (ALTER TYPE … ADD VALUE 둘). 거기서 멈추면 앞의 셋은 **빈 표만
#         더해진 상태**로 남고 앱은 하나도 안 바뀌었다 — 되돌릴 것이 없다.
#         반대로 포털을 먼저 돌려 성공한 뒤 A/S 에서 멈추면, 포털 DB 에만
#         새 enum 값이 남는다(그것도 해롭지는 않지만 되돌리기가 더 번거롭다).
#
#   ── 정리 ──────────────────────────────────────────────────────────
#      --migrate : A/S → 재고관리 → 휴가 → **포털(마지막)**
#      --go      : A/S → 재고관리 → 휴가 → **포털** → **승인함** → 계측기
#      🔵 --go 안에서 여섯이 연달아 뜨므로 그 사이는 **몇 초**다. 그래도
#         차례를 지키는 까닭은, 그 몇 초 안에 누가 위임을 맡기면 실패하기
#         때문이 아니라 — **멈췄을 때 어디서 멈추느냐**가 다르기 때문이다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **마이그레이션이 어디서 도는가 — 집마다 다르다** [실측 2026-11-18]
# ══════════════════════════════════════════════════════════════════════
#     A/S        tools 에 drizzle/ 이 **없다** → **볼륨**(/volume1/dss/as-migrations)
#                🔴 묶음 as-migrations.tar.gz 를 풀어 넣어야 129 → 131 이 된다.
#     포털       tools 에 COPY drizzle 있다 → **이미지 안**. 🔴 도구 태그를
#                갈아야 0010 이 **세상에 존재한다.**
#     재고관리   같다. 도구 태그를 갈아야 0026·0027 이 존재한다.
#     휴가       같다. 도구 태그를 갈아야 0003·0004 가 존재한다.
#     계측기     이번 판에 마이그레이션 **0건**. 🔴 그래도 **도구를 간다** —
#                매일 09:00 배치가 부르는 scripts/send-notify.ts 가 바뀌었다.
#     통합승인함 🔴 **DB 가 아예 없다** — drizzle/ 도 tools 스테이지도 없다.
#                🔴 **다른 다섯과 같은 점검을 돌리면 전부 ✗ 가 난다.**
#                이 파일은 DBLESS 가지를 따로 둔다.
#
#   🔴 **「이미지 안에서 돈다」는 집은 도구 이미지를 안 갈면 적용이 0건으로
#      조용히 끝난다** — 겉으로는 성공으로 보인다(31·39번이 겪었다).
#      그래서 --migrate 가 **도구 태그 다섯을 먼저 갈고** 그 다음에 돌린다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **61-deploy.sh(쉰일곱째)에서 베낀 절과 버린 절**
# ══════════════════════════════════════════════════════════════════════
#   ── 베낀 것 (그리고 **이번 판에서도 참인지 값으로 다시 쟀다**)
#     · **상태 변수(PHASE)를 먼저 읽고 가지를 나눈다** — 48번이 데인 자리다.
#       🔴 이번에는 집이 여섯이라 PHASE 를 **집마다** 읽는다. 한 덩어리로
#          읽으면 「A/S 만 올라간 상태」가 ODD 로 뭉개진다.
#     · **3xx 판정**(200|30[1237]). A/S 는 307, PO 는 303 으로 보낸다.
#       빠뜨리면 멀쩡한 사이트가 ✗ 로 나온다(2026-10-30 실측).
#     · **치환 전에 그 줄의 낱말 수가 2 인지 본다.** 줄 끝 주석이 붙어 있으면
#       **주석의 마지막 낱말**이 태그로 바뀌고 image: 값은 그대로 남는다.
#     · **달라진 image: 줄 수를 박지 않는다 — 세어서 정한다.**
#     · **설정 파일 검사**(중복 키 · auto). 값은 한 글자도 안 찍는다.
#     · **덤프를 먼저 뜬다.** 🔴 이번에는 **DB 넷**을 뜬다(A/S·포털·재고·휴가).
#     · **DB 상자의 StartedAt 을 앞뒤로 비교한다** — 안 멈췄다는 증거다.
#     · **제 md5 를 스스로 찍는다** · **image: 줄을 통째로 찍는다**.
#     · **마이그레이션은 볼륨에서 돈다**(A/S) — 이미지 안만 세면 0건으로 끝난다.
#     · **PO 쓰기 권한 검사**는 그대로 가져왔다. 🔴 **빼지 않는다** —
#       한 번 빼면 다시 넣는 사람이 없다.
#     · **옛 묶음 경고** — 쉰여섯째·쉰일곱째가 **두 판 연속** 같은 자리를 밟았다.
#       🔴 이번에는 경고에 그치지 않고 **--preload 가 incoming/ 의 옛 묶음을
#          먼저 찍어 보여 준다.**
#
#   ── 버린 것 (까닭과 함께)
#     · 61번의 **양식(.xlsx) 절 전부**. 이번 범위에 .xlsx 변경이 0줄이고
#       양식은 볼륨으로 붙어 이 배포와 무관하다. 🔵 다만 **as-templates 폴더가
#       그대로 있는가**는 한 줄로 남겼다(실수로 지워졌는지).
#     · 61번의 **badge_visibility_settings 절 전부**(2-ㄱ · --count 의 ①②).
#       🔴 이번 판이 그 표를 한 글자도 안 건드린다 — 그대로 두면 **아무것도
#          안 재는 ✓** 가 된다. 그 자리에 **네 집의 새 표**를 넣었다.
#     · 61번의 **연락서·발주서·견적서 공유폴더 검사 셋**은 **A/S 쪽만 남겼다**
#       (연락서 폴더는 이번 판의 「연락서 폴더에 저장」이 실제로 쓰는 자리라
#       **더 중요해졌다**). 견적서 쪽은 이번 범위와 무관해 ⚠️ 로만 센다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **모드 여섯 — 쓰는 것 / 안 쓰는 것**
# ══════════════════════════════════════════════════════════════════════
#   (기본) --check
#       쓰는 것 : **없다.**
#       🔴 다만 **읽기는 한다** — DB 에 select, 앱 주소에 GET, 이미지가 실려
#          있으면 **run --rm 으로 잠깐 띄웠다 지운다**(sh 로 열 뿐 앱을 시작하지
#          않는다).
#   --count
#       쓰는 것 : **없다.** 이 배포가 바꾸는 자리를 **세기만** 한다.
#   --preload
#       쓰는 것 : **NAS 의 도커 이미지 저장소**(docker load 로 태그 열하나).
#       🔵 실어만 두고 **아직 안 갈아 끼운다.** 싣자마자 **안을 센다.**
#   --migrate
#       쓰는 것 : **DB 덤프 넷** · **compose 사본 한 장** ·
#                 **compose 의 image: 줄 다섯**(도구만) ·
#                 **A/S 마이그레이션 볼륨**(묶음을 풀어 129 → 131) ·
#                 🔴 **네 집의 DB**(표 넷 · 색인 여덟 · enum 값 둘).
#       안 쓰는 것: 앱의 image: 줄 · 도는 컨테이너 · 공유폴더 ·
#                 🔵 **기존 표의 자료**(일곱 건 전부 INSERT 가 0 이다).
#       🔵 **다시 돌려도 안전하다** — drizzle 은 이미 적용한 것을 건너뛴다.
#   --go
#       쓰는 것 : **compose 사본 한 장** · **compose 의 image: 줄**(앱 여섯) ·
#                 **앱 여섯을 다시 띄운다**(정지 창 — 집마다 20~30초).
#       안 쓰는 것: 🔴 **DB**(--migrate 가 이미 했다) · 볼륨 · 공유폴더 ·
#                 PO·게시판·개선요청·RF이슈관리의 image: 줄.
#       🔴 **네 집의 마이그레이션 수가 기대값이 아니면 멈춘다.**
#   --rollback
#       쓰는 것 : **compose 사본 한 장** · **앱 여섯의 image: 줄** ·
#                 **앱 여섯을 다시 띄운다.**
#       안 쓰는 것: 도구 태그(새 판 그대로 둔다) · DB · 볼륨 · 덤프(안 뜬다).
#       🔴 **DB 는 자동으로 안 되돌린다** — 일곱 건이 **더하기만** 하므로
#          옛 앱은 그 표와 색인을 쳐다보지도 않는다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 환경의 함정 — 이 파일이 지키고 있는 것**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 이다.** set -e 아래서 그대로
#      쓰면 검사가 스스로 스크립트를 쏜다. 이 파일은 **$( … || true )** 로만 받는다.
#   ② 🔴 **tar | grep -q 를 if 에 바로 물리지 않는다.** pipefail 아래서 grep -q 가
#      먼저 끝나면 앞의 tar 가 SIGPIPE 로 죽어 **파일이 있을 때 오히려 ✗** 가 난다
#      (2026-11-07 쉰째에서 실제로 났다). 묶음을 읽는 자리는 전부 **세는 꼴**이다.
#   ③ 🔴 **bash -n 이 못 잡는 둘.** 큰따옴표 안의 백틱은 명령 치환으로 읽히고,
#      읽기전용 자리의 콜론-꺾쇠는 ash 를 죽인다 →
#      **이 파일에는 둘 다 한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   ④ 🔴 **CRLF.** Git Bash 의 grep 만 \r 를 걷어내고 NAS 의 GNU grep 은 안
#      걷어낸다. 줄 전체로 맞대는 검사는 **읽자마자 tr -d 로 \r 를 걷은 뒤** 한다.
#   ⑤ 🔴 **빈 결과는 삼켜진 오류일 수 있다.** 「비면 OK」로 읽는 자리를 안 만든다 —
#      목록은 **읽은 줄 수를 함께 받고**, **없는 경로 하나를 일부러 함께 묻는다.**
#   ⑥ 🔴 **마이그레이션은 이미지가 아니라 볼륨에서 돈다**(A/S). 이미지 안만 세면
#      0건으로 조용히 끝난다. **볼륨의 .sql 과 _journal.json 을 둘 다** 센다.
#   ⑦ 🔴 **저장소의 compose 사본은 운영보다 뒤처진다**(아홉 판 차이가 난 적이 있다).
#      이 파일은 **NAS 위의 docker-compose.nas.yml 만 읽는다.** 저장소 사본을
#      한 번도 안 본다.
#   ⑧ 🔴 **ON DELETE 가 「지우는 문장」 검사에 걸린다.** 이번 일곱 중 **넷**에
#      그 글자가 있다 — 잣대에서 뺐고, **표본으로 잣대가 살아 있는지 먼저 잰다.**
#   ⑨ 🔴 **bash 의 $(( )) 는 0 으로 시작하는 수를 8진수로 읽는다** — 0129 를
#      셈에 넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
#   ⑩ 🔴 **한글을 HTTP 머리말·argv 에 넣지 않는다.** 넣으면 요청이 아예 안 나가고
#      그 ✗ 가 진짜 결함처럼 보인다. 🔵 이 파일의 표식은 **전부 ASCII** 다.
#   ⑪ 🔴 **비밀값을 찍지 않는다.** 설정 파일은 이름이 있는가/없는가와 auto 인가만
#      본다. DATABASE_URL 에서는 **역할 이름만** 꺼낸다.
#   ⑫ 🔵 **받을 폴더는 777 로 만든다** — root 가 만든 755 는 scp 가 못 쓴다.
#      새 폴더에서만 터진다. 이 파일은 incoming/ 과 backups/db 를 777 로 만든다.
#
# ── 🔴 알고도 안 고친 것 — PO 가 모르는 것이 **넷**이 됐다 ───────────
#   ① dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 APPROVAL_REQUIRED 가 없다.
#   ② PO 는 납품일 칸(delivered_date·delivered_by)을 모른다.
#   ③ PO 는 회차 승인(due_date_row_order)을 모른 채 같은 표를 고친다.
#   ④ 🔴 **이번에 하나 늘었다** — PO 의 vendor/dss-core 핀이 8730c94 라
#      **portal_approval_delegations 표를 모른다.** A/S 와 **같은 DB** 를 쓰는데
#      스키마 핀이 다르다.
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
BK=$D/backups/docker-compose.nas.yml.v58-$STAMP
BKDB=$D/backups/db
# 🔴 **BK 와 같은 v 번호여야 한다** — 59번이 여기를 안 고쳐 v54 로 남긴 적이 있다.
#    아래 1-ㄱ-0 절이 값으로 확인한다.
DUMP_VER=v58
INCOMING=$D/setup/incoming
MIGDIR=$D/as-migrations
MIGTAR=$INCOMING/as-migrations.tar.gz
IMG_MIGDIR=/app/drizzle
TPLDIR=$D/as-templates

# ══ 🔴 앱 여섯 — **이 차례가 곧 --go 의 차례다** ══════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트포트|사람이 부르는 이름
#   🔴 **줄 차례를 바꾸지 마라.** 위에 적은 까닭 그대로다:
#      받는 집 셋 → 포털 → 승인함 → 계측기.
SITES='
as|app-as|dss-as|dss-as:5.4|dss-as:5.3|dss-as-5.4.tar|13000|A/S관리
inventory|app-inventory|dss-inventory|dss-inventory:0.7|dss-inventory:0.6|dss-inventory-0.7.tar|13800|재고관리
leave|app-leave|dss-leave|dss-leave:0.5|dss-leave:0.4|dss-leave-0.5.tar|13700|휴가관리
auth|app-auth|dss-auth|dss-auth:2.2|dss-auth:2.1|dss-auth-2.2.tar|13100|통합로그인포털
approvals|app-approvals|dss-approvals|dss-approvals:0.2|dss-approvals:0.1|dss-approvals-0.2.tar|14000|통합승인함
meters|app-meters|dss-meters|dss-meters:1.5|dss-meters:1.4|dss-meters-1.5.tar|13300|계측기관리
'
SITES_WANT=6
# 🔵 승인함의 호스트 포트는 **14000** 이다. 13900 이 아니다 — 13900 은 RF 이슈관리
#    것이다(38-approvals.sh 28줄). 개발 PC 가 3900 이라 베끼기 쉽다.

# ══ 🔴 도구 다섯 — **--migrate 가 먼저 간다** ═════════════════════════
#   열쇠|서비스|새 태그|옛 태그|tar|사람이 부르는 이름|무엇 때문에 가는가
#   🔵 profiles: [tools] 라 평소에 뜨지 않는다. 도는 컨테이너는 compose 를
#      읽지 않으므로 이 줄들을 고쳐도 **직원이 느끼는 것이 없다.**
TOOLS='
astools|tools-as|dss-as-tools:21|dss-as-tools:20|dss-as-tools-21.tar|A/S도구|공용스키마와 src 가 바뀌었다
inventorytools|tools-inventory|dss-inventory-tools:4|dss-inventory-tools:3|dss-inventory-tools-4.tar|재고도구|0026·0027 이 이 안에 구워져 간다
leavetools|tools-leave|dss-leave-tools:3|dss-leave-tools:2|dss-leave-tools-3.tar|휴가도구|0003·0004 가 이 안에 구워져 간다
authtools|tools-auth|dss-auth-tools:5|dss-auth-tools:4|dss-auth-tools-5.tar|포털도구|0010 이 이 안에 구워져 간다
meterstools|tools-meters|dss-meters-tools:2|dss-meters-tools:1|dss-meters-tools-2.tar|계측기도구|🔴 매일 09:00 배치가 부르는 send-notify.ts 가 바뀌었다
'
TOOLS_WANT=5

# ══ 🔴 안 건드리는 집 — 「옆으로 안 샜다」는 증거로 센다 ══════════════
#   🔴 61번은 아홉이었다. 이번에 **여섯이 건드리는 쪽으로 넘어가** 넷만 남는다.
KEEP_BOXES="dss-board dss-improvements dss-rf-trouble dss-po"
KEEP_BOXES_WANT=4
KEEP_DB="dss-pg-app dss-pg-auth"

# ══ 🔴 DB — 집마다 상자도 이름도 다르다 ═══════════════════════════════
#   열쇠|DB상자|DB이름|전(운영 지금)|후(이 배포 뒤)|migrate 명령|도는 자리
#   🔴 **이 차례가 --migrate 의 차례다**(포털이 마지막).
#   🔵 A/S·재고·휴가·계측기는 **같은 dss-pg-app** 을 쓰고 포털만 dss-pg-auth 다.
MIGS='
as|dss-pg-app|dss_as|129|131|db:migrate|volume
inventory|dss-pg-app|dss_inventory|26|28|db:migrate|image
leave|dss-pg-app|dss_leave|3|5|db:migrate|image
auth|dss-pg-auth|dss_auth|10|11|db:migrate|image
'
MIGS_WANT=4
# 🔵 계측기는 이번 판에 마이그레이션 0건이라 이 표에 없다. 그래도 **수가 그대로인지**
#    따로 잰다(아래 METERS_MIG_KEEP) — 늘었으면 전제가 깨진 것이다.
METERS_BOX=dss-pg-app; METERS_DB=dss_meters; METERS_MIG_KEEP=3
# 🔴 승인함은 **DB 가 아예 없다.** 이 파일의 어느 절도 승인함에 select 를 던지지
#    않는다 — 던지면 전부 ✗ 가 난다(④).

# ══ 🔴 **이번 판이 만드는 것** — PRE 에 없고 POST 에 있어야 한다 ══════
#   🔴 **단계마다 기대값이 다르다.** 한 잣대로 재면 둘 중 하나가 가짜 ✗ 다.
#   열쇠|DB상자|DB이름|표 이름
NEW_TABLES='
as|dss-pg-app|dss_as|portal_approval_delegations
inventory|dss-pg-app|dss_inventory|portal_approval_delegations
leave|dss-pg-app|dss_leave|web_portal_approval_delegations
auth|dss-pg-auth|dss_auth|approval_delegations
'
NEW_TABLES_WANT=4
#   🔴 색인은 **「있는가」가 아니라 칸 수까지** 센다 — 같은 이름으로 다시 만든
#      것을 가르려면 **모양**을 봐야 한다(2026-11-07 에 배운 것).
#   열쇠|DB상자|DB이름|색인 이름|기대 칸 수
NEW_INDEXES='
as|dss-pg-app|dss_as|portal_approval_delegations_delegate_active_idx|3
as|dss-pg-app|dss_as|repair_case_approvals_decided_by_user_id_decided_at_idx|2
as|dss-pg-app|dss_as|repair_case_approvals_delegated_from_user_id_decided_at_idx|2
as|dss-pg-app|dss_as|quote_approvals_decided_by_user_id_decided_at_idx|2
as|dss-pg-app|dss_as|quote_approvals_delegated_from_user_id_decided_at_idx|2
inventory|dss-pg-app|dss_inventory|portal_approval_delegations_delegate_idx|3
inventory|dss-pg-app|dss_inventory|stock_issue_approval_steps_decided_by_history_idx|2
inventory|dss-pg-app|dss_inventory|stock_issue_approval_steps_approver_history_idx|2
leave|dss-pg-app|dss_leave|web_portal_approval_delegations_delegate_idx|3
leave|dss-pg-app|dss_leave|web_approval_steps_decided_by_idx|2
leave|dss-pg-app|dss_leave|web_approval_steps_decided_approver_idx|2
auth|dss-pg-auth|dss_auth|approval_delegations_delegate_active_idx|3
'
NEW_INDEXES_WANT=12
#   🔴 포털 0010 이 더하는 **enum 값 둘** — 표가 아니라 타입이다.
AUTH_ENUM_TYPE=auth_audit_action
AUTH_ENUM_VALUES='DELEGATION_CREATED DELEGATION_REVOKED'
AUTH_ENUM_WANT=2

# ══ 🔴 tar 열하나의 지문 — [배포본] 62-build.sh 가 굽고 **바로 잰 값** ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 비어 있다 — 굽기 전에 쓴 파일이다.** 62-build.sh --go 가 꼬리말에
#      찍는 **열한 줄**로 아래를 통째로 갈아 끼운 **뒤에** scp 하세요.
#   🔴 **이 값을 NAS 에서 재서 채우지 마라.** 그러면 「옮기다 깨졌는가」를 자기가
#      잰 값으로 자기를 재는 꼴이 되어 **영영 통과한다.** 반드시 **구운 쪽**에서 잰다.
#   🔴 비어 있으면 3절이 **--check·--rollback 에서는 ? · --preload·--migrate·
#      --go 에서는 ✗** 로 센다. 🔵 막는 것은 **✗ 뿐이다.**
#      🔴 **쉰세째에는 빈 표가 그대로 NAS 로 올라갔고 --preload 가 ✗ 둘로 멈췄다.**
#   🟢 **채웠다 — 2026-11-18 굽기(11/11 성공)에서 나온 값이다.**
#      🔵 두 곳에서 따로 재어 **글자 그대로 같았다**: 굽는 그 자리에서 한 번,
#         그 뒤 62-build.sh --verify 가 tar 를 다시 열어 한 번.
TARS='
dss-as-5.4.tar|135986688|f2665230fad73a1d0c87a9e70745621a|sha256:e265d9504d08ca11d83c3fc28c4e847a532da535d2bc8928b34d6ff9df9ee721
dss-as-tools-21.tar|226498560|8167000efbbfacf3aa60db6e7ca93ba3|sha256:26ebb2bb3e48e496913d247074668c8b5a0805019febd524af2386f1b2070d99
dss-inventory-0.7.tar|95449600|6fd032695dc431d277f8bb96ea27ebad|sha256:051ac57f1bcb1772c8231cb54301188238c0dd71358be82f8a60615cc3eaa2c8
dss-inventory-tools-4.tar|213334528|58d305187565ba195df863ca08553be2|sha256:3bf401b7c3a0f041ad83e35a6174c55f92e60aad5d1f3e210fbaa9af461a43ac
dss-leave-0.5.tar|75225088|d01e1d1b7da82dc1531626ead01f172f|sha256:6fe7b6bb42bbe17dca1ca647270ece3cfccf2b5bcd194d52871a1a2a11b5e16f
dss-leave-tools-3.tar|190283776|f1f501e55553881bf3269e7308d13d3d|sha256:cdfe1b972e2c4924d84a41145de00d25caa010983ef8be38d93237911210b1a4
dss-auth-2.2.tar|113711104|8ebec76df0a8e6c66e6db0d8f0099e91|sha256:ef3ca95b2acce3eed2857421b47f6c19f8e991683b2e379d96d1d50c956a822c
dss-auth-tools-5.tar|212409856|3af744ab5b379f000b3d9386c458334a|sha256:4570f9b0ace529f5ba2967d5631c6e18b39e500c1e945d8fec9079c7fe252f23
dss-approvals-0.2.tar|94961152|a5a2b0f4b51d8a3cc73aa6a01c999d29|sha256:b8a6f865ea222246fc9a54297f2d08d63b55b07000672fd109662b390ba63f84
dss-meters-1.5.tar|114123776|898c43032f4a4b081a10ec799ce86f3a|sha256:24e06854b6bb63c752e0f5a992c0df0ce614c1069178bdbcee3d0b7f0b7266ce
dss-meters-tools-2.tar|221722112|792bab9fb0ed8437c549d3dc5421baa2|sha256:295d4c1087e06ce15491f8963c650a77bfa092e3f4dac936bdf71a3ee82d8c06
'
TARS_WANT=11
# 🔵 **다음 판을 쓰는 사람에게** — 62-build.sh 를 쓸 때 「지난 판 tar 바이트」를
#    찾느라 이 저장소를 뒤지게 된다. 이번 판의 **열한 줄이 전부 위에 있다.**
#    🔴 특히 dss-leave-tools-2.tar 와 dss-meters-tools-1.tar 는 **어디에도 적힌
#       곳이 없어** 이번에 크기 견주기를 건너뛰어야 했다. 그 둘의 **이번 판**
#       값은 dss-leave-tools-3.tar **190283776** · dss-meters-tools-2.tar
#       **221722112** 다 — 다음 판은 이것을 쓰면 된다.
# 🔴 **묶음의 잰 값** — 62-build.sh 가 찍어 준 값이다 (🟢 2026-11-18 채웠다).
MIGTAR_SIZE=2591099
MIGTAR_MD5=1f193a77253be01198dc8bc580ef2add

# 🔴 tar 이름 → 태그. **정규식으로 되돌리지 않는다** — 이름마다 손으로 적는다.
#    🔴 판에 점이 있는 것과 없는 것이 섞여 있어 한 규칙으로 안 풀린다.
tar2tag() {
  case "$1" in
    dss-as-5.4.tar)             printf 'dss-as:5.4' ;;
    dss-as-tools-21.tar)        printf 'dss-as-tools:21' ;;
    dss-inventory-0.7.tar)      printf 'dss-inventory:0.7' ;;
    dss-inventory-tools-4.tar)  printf 'dss-inventory-tools:4' ;;
    dss-leave-0.5.tar)          printf 'dss-leave:0.5' ;;
    dss-leave-tools-3.tar)      printf 'dss-leave-tools:3' ;;
    dss-auth-2.2.tar)           printf 'dss-auth:2.2' ;;
    dss-auth-tools-5.tar)       printf 'dss-auth-tools:5' ;;
    dss-approvals-0.2.tar)      printf 'dss-approvals:0.2' ;;
    dss-meters-1.5.tar)         printf 'dss-meters:1.5' ;;
    dss-meters-tools-2.tar)     printf 'dss-meters-tools:2' ;;
  esac
}

# ══ 🔴 이미지 안에서 쓸 표식 — **전부 ASCII · 전부 리터럴** ═══════════
#   열쇠|기능 표식|뒷걸음 표식   (앱 이미지 · 번들이라 minify 를 거친다)
APPMARKS='
as|portal_approval_delegations|domesticOrders.view
inventory|portal_approval_delegations|stock_issue_approval_steps
leave|web_portal_approval_delegations|web_approval_steps
auth|dss.delegations.write|approval_mail_kinds
approvals|/api/integration/delegations|rf-service-system
meters|/settings/notify|web_notifications
'
#   열쇠|마지막 커밋 표식|그 표식이 있어야 하는 파일 (도구 이미지 · 소스 그대로)
TOOLMARKS='
astools|UPLOAD_FILE_NAME_MAX_LENGTH|src/components/repair-cases/files/upload-file-name.ts
authtools|h-7 shrink-0 items-center whitespace-nowrap|src/app/apps/page.tsx
inventorytools|TOOLBAR_BTN_PRIMARY|src/components/parts/PartsList.tsx
leavetools|loadDelegationFoldActingFor|src/lib/auth/portal-delegations.ts
meterstools|onConflictDoNothing|scripts/send-notify.ts
'
# 🔴 승인함은 도구 이미지가 없다 — **앱 번들에서** 마지막 커밋을 가린다.
APPROVALS_LAST_MARK='grid grid-cols-2 gap-3 sm:col-span-2'
PROBE_MISS=src/__dss_probe_no_such_file__.ts

# ══ 🔴 public/ 기대값 — **집마다 다르다** ═════════════════════════════
#   열쇠|기대(yes|no)|이미지 안 파일 수(참고 · 판정에 안 쓴다)
#   🔴 **승인함만 no 다.** [실측 2026-11-18 · 구운 열하나와 옛 판 다섯을 열어 셌다]
#      dss-approvals:0.1 **no** · dss-approvals:0.2 **no** · 저장소에도 **없다**.
#   🔵 재고·휴가는 폴더는 있는데 **비어 있다**(0개). 그것도 원래 그렇다 —
#      「담겼다 ✓」가 아니라 ⚠️ 로 적어 사람이 속지 않게 한다.
PUBLIC_WANT='
as|yes|9
inventory|yes|0
leave|yes|0
auth|yes|6
approvals|no|0
meters|yes|5
'

# ══ 🔴 지우는 문장 잣대 — **주석을 먼저 걷어낸다** ════════════════════
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
SQL_COMMENT_RE='^[[:space:]]*--'

# ══ 🔴 설정 파일 — .env 쪽과 env/*.env 쪽을 **둘 다** 본다 ════════════
ENV_NAS=$D/deploy/.env.nas
ENV_FILES="$D/deploy/env/as.env $D/deploy/env/auth.env $D/deploy/env/po.env $D/deploy/env/inventory.env $D/deploy/env/leave.env $D/deploy/env/meters.env $D/deploy/env/approvals.env"

# ══ 🔵 연락서 원본 폴더 — 🔴 이번 판에 **더 중요해졌다** ══════════════
#   「연락서 폴더에 저장」이 실제로 쓰는 자리다(커밋 e612d863·1992ca49).
KYO_SRC=/kyosan-src;        KYO_SRC_MIN=600
KYO_CONV=/kyosan-converted; KYO_CONV_MIN=100
PO_ARCHIVE=/purchase-order-archive
# 🔴 PO 쓰기 권한 — PO 를 안 건드려도 잰다.
PO_APP_CN=dss-po
PO_WRITE_TABLE=repair_cases

# ══════════════════════════════════════════════════════════════════════
MODE=${1:---check}
case "$MODE" in
  --check|--count|--preload|--migrate|--go|--rollback) ;;
  *) printf '쓰는 법: %s [--check|--count|--preload|--migrate|--go|--rollback]\n' "$0"; exit 2 ;;
esac

mkdir -p "$D/setup/logs" 2>/dev/null
LOG="$D/setup/logs/deploy58-$(printf '%s' "$MODE" | tr -d '-')-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

PASS=0; FAIL=0; UNK=0
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
unk()  { UNK=$((UNK+1));   printf '  ? %s — 못 쟀다 (%s)\n' "$1" "$2"; }
hm()   { printf '  ⚠️ %s\n' "$1"; }
say()  { printf '    %s\n' "$1"; }
cmd()  { printf '      %s\n' "$1"; }
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
  local n f cur
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
  local now
  now=$(svc_image "$1")
  if [ "$now" = "$2" ]; then ok "$1 image: $cur → $2 (${n}줄)"; return 0; fi
  bad "$1 의 image: 가 $now 다 — $2 를 기대했다"; return 1
}

# ── DB 에 묻는 길 ────────────────────────────────────────────────────
#   🔴 **앱이 쓰는 길로 재지 않는다** — 여기는 관리용 조회뿐이고 전부 select 다.
pgq() { # 1 상자 2 DB 3 SQL
  "$DOCKER" exec -i "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -tAc \"$3\"" 2>/dev/null | tr -d ' \r'
}
pgrows() { "$DOCKER" exec -i "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -tAc \"$3\"" 2>/dev/null | tr -d '\r'; }
pgn() { local v; v=$(pgq "$1" "$2" "$3"); isnum "$v" && printf '%s' "$v"; }
mig_count() { pgn "$1" "$2" 'select count(*) from drizzle.__drizzle_migrations'; }
has_table() { pgn "$1" "$2" "select count(*) from information_schema.tables where table_schema='public' and table_name='$3'"; }
has_index() { pgn "$1" "$2" "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where c.relkind='i' and c.relname='$3' and n.nspname='public'"; }
# 🔴 「있는가」가 아니라 **칸 수**까지 센다 — 같은 이름으로 다시 만든 것을 가른다.
index_cols() { pgn "$1" "$2" "select coalesce(max(i.indnkeyatts),0) from pg_index i join pg_class c on c.oid=i.indexrelid join pg_namespace n on n.oid=c.relnamespace where c.relname='$3' and n.nspname='public'"; }
has_enum_value() { pgn "$1" "$2" "select count(*) from pg_enum e join pg_type t on t.oid=e.enumtypid where t.typname='$3' and e.enumlabel='$4'"; }
table_rows() { pgn "$1" "$2" "select count(*) from $3"; }

dct() { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas --profile tools "$@" ); }
dcu() { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas "$@" ); }

# ── 앱이 답하는가 ────────────────────────────────────────────────────
#   🔴 **3xx 를 통과로 센다** — A/S 는 307, PO 는 303 으로 로그인에 보낸다.
#      빠뜨리면 **멀쩡한 사이트가 ✗ 로 나온다**(2026-10-30 실측).
http_code() { # 1 호스트포트
  curl -s -o /dev/null -w '%{http_code}' --max-time 8 "http://127.0.0.1:$1/" 2>/dev/null
}
http_ok() { printf '%s' "${1:-}" | grep -qE '^(200|30[1237])$'; }

# ── 🔴 지금 운영이 어느 단계인가 — **집마다** 읽는다 ─────────────────
#   PRE  옛 태그   NEW 새 태그   ODD 그 밖
#   🔴 한 덩어리로 읽으면 「A/S 만 올라간 상태」가 ODD 로 뭉개진다.
state_of() { # 1 지금 2 옛 3 새
  if [ "${1:-}" = "$3" ]; then printf 'NEW'
  elif [ "${1:-}" = "$2" ]; then printf 'PRE'
  else printf 'ODD'; fi
}

printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' " 62-deploy.sh — 쉰여덟째 배포 ($MODE)"
printf '%s\n' "   때      : $(date '+%F %T')"
printf '%s\n' "   로그    : $LOG"
printf '%s\n' "   compose : $CF"
printf '%s\n' "   앱 6 · 도구 5 · 마이그레이션 네 집 일곱 건 · 묶음 1(A/S)"
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
b1=$(printf '%s' "$BK" | grep -o 'v[0-9]*' | head -1)
if [ "$b1" = "$DUMP_VER" ]; then ok "덤프와 compose 사본의 판 꼬리표가 같다 ($DUMP_VER)"
else bad "compose 사본은 $b1 인데 덤프는 $DUMP_VER 다 — 59번이 이 자리를 놓쳤다"; fi

# 1-ㄱ. 🔴 운영이 지금 쓰는 태그 전부
say ""
say "── 1-ㄱ. 🔴 운영이 지금 쓰는 태그 — compose 의 image: 줄을 **통째로** 찍는다"
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
    say "      🔴 운영 compose 에 그 서비스가 없다는 뜻입니다. **멈추고 알리세요** —"
    say "         이 배포본은 여섯 집이 전부 있다는 전제로 쓰였습니다."
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
[ "$SITE_SEEN" = "$SITES_WANT" ] && ok "앱 ${SITES_WANT}곳을 다 봤다 (표본이 비지 않았다)" \
  || bad "앱을 ${SITE_SEEN}곳만 봤다 — ${SITES_WANT}곳을 기대했다. SITES 표가 깨졌다"
say "앱 단계 — 새 판 ${PHASE_APP_NEW} · 옛 판 ${PHASE_APP_PRE} · 그 밖 ${PHASE_APP_ODD}"

# 1-ㄴ. 도구 다섯
say ""
say "── 1-ㄴ. 🔴 도구 다섯 — **--migrate 가 이 줄들을 먼저 간다**"
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
    say "      🔴 재고관리 도구는 2026-10-14 에 NAS 에서 주석을 벗겼습니다(27번)."
    say "         저장소 사본에는 아직 주석으로 남아 있습니다 — **운영 쪽을 보세요.**"
  elif [ "$st" = "ODD" ]; then
    hm "$NAME 가 ${cur} 다 — 옛 $OLD 도 새 $NEW 도 아니다. 사람이 보세요"
  fi
done <<ENDTOOL1
$(rows_of "$TOOLS")
ENDTOOL1
[ "$TOOL_SEEN" = "$TOOLS_WANT" ] && ok "도구 ${TOOLS_WANT}개를 다 봤다" \
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
  MID)  say "🔴 **--migrate 까지 돌았습니다**(도구만 새 판). 다음은 --go 입니다."
        say "   🔵 --go 뒤에 --rollback 으로 앱만 되돌린 상태도 여기 보입니다 —"
        say "      그 둘은 **DB 기록으로 가릅니다**(2절의 마이그레이션 수)." ;;
  POST) say "--go 까지 돌았습니다. --count 로 뒤의 수를 재세요." ;;
  ODD)  hm "단계가 섞여 있습니다 — 위 표를 사람이 보세요. **막지는 않습니다.**" ;;
esac

# 1-ㄷ. 🔴 안 건드리는 넷 — 「옆으로 안 샜다」는 증거
say ""
say "── 1-ㄷ. 🔵 안 건드리는 넷 — **그래도 「그대로 도는가」는 본다**"
KEEP_SEEN=0
for c in $KEEP_BOXES; do
  KEEP_SEEN=$((KEEP_SEEN+1))
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
  [ "${s:-}" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
done
[ "$KEEP_SEEN" = "$KEEP_BOXES_WANT" ] && ok "안 건드린 넷을 다 봤다 (표본이 비지 않았다)" \
  || bad "안 건드린 상자를 ${KEEP_SEEN}개만 봤다 — ${KEEP_BOXES_WANT}개를 기대했다"
say "🔴 61번은 여기가 **아홉**이었습니다 — 이번에 **여섯이 건드리는 쪽으로 넘어가** 넷만 남았습니다."
for c in $KEEP_DB; do
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  t=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s 켜진 때 %s\n' "$c" "${s:-없음}" "${t:-}"
  [ "${s:-}" = running ] || bad "$c 가 안 돈다 — DB 가 멈춰 있다"
done
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

# ══════════════════════════════════════════════════════════════════════
# ── 2. 🔴 DB — **네 집 · 일곱 건.** 단계마다 기대값이 다르다 ──────────
# ══════════════════════════════════════════════════════════════════════
step "2. 🔴 DB — 네 집에 일곱 건 (승인함은 **해당 없음**)"
say "🔴 **단계를 먼저 정하고 가지를 나눕니다**(48번이 데인 자리). 「표가 있는가」는"
say "   적용 전에는 **없는 것이 정상**이고 적용 뒤에는 **있는 것이 정상**입니다 —"
say "   한 잣대로 재면 둘 중 하나가 **가짜 ✗** 입니다."

# 2-ㄱ. 집마다 마이그레이션 수
say ""
say "── 2-ㄱ. 마이그레이션 수 (drizzle.__drizzle_migrations)"
DB_DONE=0; DB_TODO=0; DB_ODD=0; DBM_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  K=$(field "$r" 1); BOX=$(field "$r" 2); DB=$(field "$r" 3)
  BEF=$(field "$r" 4); AFT=$(field "$r" 5); WHERE=$(field "$r" 7)
  rr=$(row_by_key "$SITES" "$K"); NAME=$(field "$rr" 8)
  DBM_SEEN=$((DBM_SEEN+1))
  v=$(mig_count "$BOX" "$DB")
  printf '      %-10s %-14s %-16s 지금 %-5s (전 %s → 후 %s · %s)\n' "$NAME" "$BOX" "$DB" "${v:-못 읽음}" "$BEF" "$AFT" "$WHERE"
  if [ -z "${v:-}" ]; then
    unk "$NAME 마이그레이션 수" "$BOX 가 도는지, 그 DB 가 있는지 보세요"
  elif [ "$v" = "$AFT" ]; then DB_DONE=$((DB_DONE+1)); ok "$NAME 가 이미 $AFT 다 (적용이 끝났다)"
  elif [ "$v" = "$BEF" ]; then DB_TODO=$((DB_TODO+1)); ok "$NAME 가 $BEF 다 (아직 안 올렸다 — 대기 $(( AFT - BEF ))건)"
  else DB_ODD=$((DB_ODD+1)); bad "$NAME 가 ${v} 다 — $BEF 도 $AFT 도 아니다. **멈추고 알릴 것**"; fi
done <<ENDMIG1
$(rows_of "$MIGS")
ENDMIG1
[ "$DBM_SEEN" = "$MIGS_WANT" ] && ok "DB 네 곳을 다 봤다 (표본이 비지 않았다)" \
  || bad "DB 를 ${DBM_SEEN}곳만 봤다 — ${MIGS_WANT}곳을 기대했다"
if [ "$DB_DONE" = "$MIGS_WANT" ]; then DBPHASE=DONE
elif [ "$DB_TODO" = "$MIGS_WANT" ]; then DBPHASE=TODO
else DBPHASE=MIXED; fi
printf '\n  🔴 **DB 단계: %s** (끝난 집 %s · 안 올린 집 %s · 그 밖 %s)\n' "$DBPHASE" "$DB_DONE" "$DB_TODO" "$DB_ODD"
if [ "$DBPHASE" = "MIXED" ]; then
  hm "네 집이 **서로 다른 단계**입니다 — --migrate 가 가운데서 멈췄을 수 있습니다."
  say "   🔵 --migrate 는 **다시 돌려도 안전합니다**(drizzle 이 이미 적용한 것을 건너뜁니다)."
fi
# 🔵 계측기 — 이번 판에 0건. **늘었으면 전제가 깨진 것이다.**
v=$(mig_count "$METERS_BOX" "$METERS_DB")
printf '      %-10s %-14s %-16s 지금 %-5s (기대 %s — 이번 판에 0건)\n' "계측기관리" "$METERS_BOX" "$METERS_DB" "${v:-못 읽음}" "$METERS_MIG_KEEP"
if [ "${v:-x}" = "$METERS_MIG_KEEP" ]; then ok "계측기가 $METERS_MIG_KEEP 그대로다 (올릴 것이 없다)"
elif [ -z "${v:-}" ]; then unk "계측기 마이그레이션 수" "$METERS_BOX 가 도는지 보세요"
else bad "계측기가 ${v} 다 — $METERS_MIG_KEEP 를 기대했다. 전제가 깨졌다"; fi
say "🔴 **승인함은 여기에 없습니다** — DB 가 아예 없는 집이라 select 를 한 줄도 안 던집니다."
say "   던졌으면 전부 ✗ 가 났을 것입니다(④)."

# 2-ㄴ. 🔴 이번 판이 만드는 표 넷 — 단계마다 기대값이 다르다
say ""
say "── 2-ㄴ. 🔴 **이번 판이 만드는 표 넷** — TODO 면 없어야 하고 DONE 이면 있어야 한다"
NT_SEEN=0; NT_HAVE=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  K=$(field "$r" 1); BOX=$(field "$r" 2); DB=$(field "$r" 3); T=$(field "$r" 4)
  rr=$(row_by_key "$SITES" "$K"); NAME=$(field "$rr" 8)
  NT_SEEN=$((NT_SEEN+1))
  n=$(has_table "$BOX" "$DB" "$T")
  rows=""
  [ "${n:-0}" = "1" ] && rows=$(table_rows "$BOX" "$DB" "$T")
  printf '      %-10s %-34s 있나 %-3s 줄 %s\n' "$NAME" "$T" "${n:-?}" "${rows:-–}"
  if [ -z "${n:-}" ]; then unk "$NAME 의 $T" "$BOX 가 도는지 보세요"; continue; fi
  [ "$n" = "1" ] && NT_HAVE=$((NT_HAVE+1))
  case "$DBPHASE" in
    TODO) if [ "$n" = "0" ]; then ok "$NAME 에 $T 가 **아직 없다** (적용 전이라 맞다)"
          else hm "$NAME 에 $T 가 벌써 있다 — 마이그레이션 수는 아직 전인데 표가 있다. 사람이 보세요"; fi ;;
    DONE) if [ "$n" = "1" ]; then ok "$NAME 에 $T 가 **있다** (${rows:-?}줄 — 🔵 0줄이 정상이다)"
          else bad "$NAME 에 $T 가 **없다** — 적용이 끝났다는데 표가 없다. 멈추고 알릴 것"; fi ;;
    *)    say "(단계가 섞여 있어 판정하지 않습니다 — 값만 찍습니다)" ;;
  esac
done <<ENDNT
$(rows_of "$NEW_TABLES")
ENDNT
[ "$NT_SEEN" = "$NEW_TABLES_WANT" ] && ok "새 표 ${NEW_TABLES_WANT}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "새 표를 ${NT_SEEN}개만 봤다 — ${NEW_TABLES_WANT}개를 기대했다"
say "🔵 **빈 표가 정상입니다** — 아무도 아직 위임을 맡기지 않았습니다."
say "🔴 네 집의 표 이름이 **셋으로 다릅니다**(A/S·재고 portal_… · 휴가 web_portal_… ·"
say "   포털 approval_delegations). 하나로 묻는 검사였으면 세 집이 ✗ 였습니다."

# 2-ㄷ. 🔴 색인 열둘 — **「있는가」가 아니라 칸 수까지 센다**
say ""
say "── 2-ㄷ. 🔴 색인 열둘 — **칸 수까지 센다**(같은 이름으로 다시 만든 것을 가른다)"
IX_SEEN=0; IX_OK=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  K=$(field "$r" 1); BOX=$(field "$r" 2); DB=$(field "$r" 3); IX=$(field "$r" 4); WC=$(field "$r" 5)
  rr=$(row_by_key "$SITES" "$K"); NAME=$(field "$rr" 8)
  IX_SEEN=$((IX_SEEN+1))
  n=$(has_index "$BOX" "$DB" "$IX")
  c=$(index_cols "$BOX" "$DB" "$IX")
  printf '      %-10s %-56s 있나 %-3s 칸 %-3s (기대 %s)\n' "$NAME" "$IX" "${n:-?}" "${c:-?}" "$WC"
  if [ -z "${n:-}" ]; then unk "$NAME 의 $IX" "$BOX 가 도는지 보세요"; continue; fi
  case "$DBPHASE" in
    TODO) [ "$n" = "0" ] && ok "$NAME $IX 가 아직 없다 (맞다)" \
            || hm "$NAME $IX 가 벌써 있다 — 사람이 보세요" ;;
    DONE) if [ "$n" = "1" ] && [ "${c:-x}" = "$WC" ]; then IX_OK=$((IX_OK+1)); ok "$NAME $IX 가 있고 칸이 ${WC}개다"
          elif [ "$n" = "1" ]; then bad "$NAME $IX 의 칸이 ${c:-?}개다 — $WC 를 기대했다 (**다른 모양으로 다시 만든 것**)"
          else bad "$NAME $IX 가 **없다** — 적용이 끝났다는데 색인이 없다"; fi ;;
    *)    say "(단계가 섞여 있어 판정하지 않습니다)" ;;
  esac
done <<ENDIX
$(rows_of "$NEW_INDEXES")
ENDIX
[ "$IX_SEEN" = "$NEW_INDEXES_WANT" ] && ok "색인 ${NEW_INDEXES_WANT}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "색인을 ${IX_SEEN}개만 봤다 — ${NEW_INDEXES_WANT}개를 기대했다"
say "🔴 휴가의 색인 둘은 **부분 색인**입니다(WHERE is_deleted=false and status in (…))."
say "   indnkeyatts 는 그 조건을 안 세므로 칸 수는 2 가 맞습니다."

# 2-ㄹ. 🔴 포털의 enum 값 둘
say ""
say "── 2-ㄹ. 🔴 포털 0010 이 더하는 **enum 값 둘** — 표가 아니라 타입이다"
EN_SEEN=0; EN_HAVE=0
for v in $AUTH_ENUM_VALUES; do
  EN_SEEN=$((EN_SEEN+1))
  n=$(has_enum_value dss-pg-auth dss_auth "$AUTH_ENUM_TYPE" "$v")
  printf '      %-22s %s (있나 %s)\n' "$AUTH_ENUM_TYPE" "$v" "${n:-?}"
  [ "${n:-0}" = "1" ] && EN_HAVE=$((EN_HAVE+1))
done
printf '      enum 값 — 본 것 %s · 있는 것 %s (기대 %s)\n' "$EN_SEEN" "$EN_HAVE" "$AUTH_ENUM_WANT"
case "$DBPHASE" in
  TODO) [ "$EN_HAVE" = "0" ] && ok "enum 값 둘이 아직 없다 (적용 전이라 맞다)" \
          || hm "enum 값이 ${EN_HAVE}개 있다 — 적용 전인데 있습니다. 사람이 보세요" ;;
  DONE) [ "$EN_HAVE" = "$AUTH_ENUM_WANT" ] && ok "enum 값 둘이 생겼다" \
          || bad "enum 값이 ${EN_HAVE}/${AUTH_ENUM_WANT} 개다 — 0010 이 반만 들어갔다" ;;
  *)    say "(단계가 섞여 있어 판정하지 않습니다)" ;;
esac
[ "$EN_SEEN" = "$AUTH_ENUM_WANT" ] && ok "enum 값 ${AUTH_ENUM_WANT}개를 다 봤다" \
  || bad "enum 값을 ${EN_SEEN}개만 봤다"
say "🔴 **ALTER TYPE … ADD VALUE 는 같은 트랜잭션에서 그 값을 쓰면 55P04 로 거절됩니다.**"
say "   0010 은 그 값을 **쓰지 않습니다**(INSERT 0) — 62-build.sh 4-ㄹ 이 값으로 쟀습니다."
say "   🔴 포털에 0011 이 생기면 **같은 트랜잭션에 둘이 들어가** 위험해집니다."

# 2-ㅁ. 🔴 A/S 마이그레이션 볼륨 — **이미지가 아니라 볼륨에서 돈다**
say ""
say "── 2-ㅁ. 🔴 A/S 마이그레이션 **볼륨** — 이미지 안만 세면 0건으로 조용히 끝난다"
if [ -d "$MIGDIR" ]; then
  vs=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  vj=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  v129=$(ls -1 "$MIGDIR"/0129_*.sql 2>/dev/null | wc -l | tr -d ' ')
  v130=$(ls -1 "$MIGDIR"/0130_*.sql 2>/dev/null | wc -l | tr -d ' ')
  v131=$(ls -1 "$MIGDIR"/0131_*.sql 2>/dev/null | wc -l | tr -d ' ')
  printf '      볼륨 %s — .sql %s장 · journal idx %s개 · 0129 %s · 0130 %s · 0131 %s(기대 0)\n' \
    "$MIGDIR" "${vs:-?}" "${vj:-?}" "${v129:-?}" "${v130:-?}" "${v131:-?}"
  if [ "${vs:-x}" = "131" ] && [ "${vj:-x}" = "131" ]; then
    ok "볼륨이 **131장**이다 (묶음이 이미 들어왔다)"
  elif [ "${vs:-x}" = "129" ] && [ "${vj:-x}" = "129" ]; then
    ok "볼륨이 아직 **129장**이다 (🔴 **--migrate** 가 묶음을 풀어 넣는다 — --preload 가 아니다)"
  else
    bad "볼륨이 .sql ${vs:-?} · idx ${vj:-?} 다 — 129 나 131 을 기대했다"
    say "      🔴 **.sql 과 idx 가 다르면** 목록에 없는 파일이 있다는 뜻이고,"
    say "         drizzle 이 그것을 **아예 모릅니다**(적용이 0건으로 끝납니다)."
    doubt
  fi
  [ "${v131:-1}" = "0" ] && ok "볼륨에 0131 이 없다 (이 배포는 0130 까지를 전제로 쓰였다)" \
    || bad "볼륨에 0131 이 **있다** — 멈추고 알릴 것"
  # 🔴 도구 이미지 안은 **비어 있어야** 한다 — 볼륨이 붙는 자리다.
  AST=$(svc_image tools-as)
  if [ -n "${AST:-}" ] && "$DOCKER" image inspect "$AST" >/dev/null 2>&1; then
    n=$("$DOCKER" run --rm --entrypoint sh "$AST" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
    printf '      A/S 도구 이미지(%s) 안 %s 의 .sql: %s개 (기대 0 — 볼륨이 안 붙은 맨 이미지다)\n' "$AST" "$IMG_MIGDIR" "${n:-?}"
    if isnum "${n:-}" && [ "${n:-1}" = "0" ]; then ok "도구 이미지 안 drizzle/ 이 비어 있다 (볼륨이 정본이다)"
    else bad "도구 이미지 안에 .sql 이 ${n:-?}장 있다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다"; fi
  else
    unk "A/S 도구 이미지 안" "${AST:-태그를 못 읽음} 가 NAS 에 아직 없다"
  fi
else
  bad "A/S 마이그레이션 볼륨이 없다 — $MIGDIR"
fi

# 2-ㅂ. 🔴 「이미지 안에서 도는」 세 집 — 도구 이미지가 그 .sql 을 들고 있나
say ""
say "── 2-ㅂ. 🔴 **이미지 안에서 도는 세 집** — 도구가 새 .sql 을 들고 있나"
say "🔴 도구 태그를 안 갈면 **새 .sql 이 세상에 존재하지 않습니다** — 적용이 0건으로"
say "   조용히 끝나고 겉으로는 성공으로 보입니다(31·39번이 겪었습니다)."
img_sql_check() { # 1 서비스 2 기대 .sql 수 3 기대 마지막 번호들(빈칸 구분) 4 이름
  local tag n miss
  tag=$(svc_image "$1")
  if [ -z "${tag:-}" ]; then bad "$4 — compose 에 $1 이 없다"; return; fi
  if ! "$DOCKER" image inspect "$tag" >/dev/null 2>&1; then
    unk "$4 도구 이미지 안" "$tag 가 NAS 에 아직 없다 (--preload 전이면 정상)"; return
  fi
  n=$("$DOCKER" run --rm --entrypoint sh "$tag" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  printf '      %-10s %-26s 안 .sql %s장 (기대 %s)\n' "$4" "$tag" "${n:-?}" "$2"
  if [ "${n:-x}" = "$2" ]; then ok "$4 도구가 ${2}장을 들고 있다"
  else bad "$4 도구가 ${n:-?}장이다 — ${2}장을 기대했다 (**옛 도구 태그다**)"; fi
  miss=""
  for t in $3; do
    local a
    a=$("$DOCKER" run --rm --entrypoint sh "$tag" -c "ls $IMG_MIGDIR/${t}_*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
    printf '        %s: %s개 (기대 1)\n' "$t" "${a:-?}"
    [ "${a:-0}" = "1" ] || miss="$miss $t"
  done
  if [ -z "${miss:-}" ]; then ok "$4 도구가 **이번 판이 올릴 것**을 다 들고 있다"
  else bad "$4 도구에 없는 것:$miss — 이 배포의 목적물이 안 담겼다"; fi
}
img_sql_check tools-inventory 28 "0026 0027" "재고관리"
img_sql_check tools-leave      5 "0003 0004" "휴가관리"
img_sql_check tools-auth      11 "0010"      "통합로그인포털"
say "🔵 위 수가 옛 태그 기준이면(재고 26 · 휴가 3 · 포털 10) **아직 안 갈았다**는 뜻이고"
say "   --migrate 가 태그를 먼저 갈아 끼운 뒤 db:migrate 를 돌립니다."

# ══════════════════════════════════════════════════════════════════════
# ── 3. 들여올 tar 열하나 + 묶음 하나 ─────────────────────────────────
# ══════════════════════════════════════════════════════════════════════
step "3. 들여올 tar 열하나 + 묶음 하나 — **옮기다 깨졌는가**"
say "🔴 지문은 **굽는 쪽에서 잰 값**입니다. NAS 에서 재서 채우면 자기가 잰 값으로"
say "   자기를 재는 꼴이 되어 **영영 통과합니다.**"
TAR_SEEN=0; TAR_OK=0; TAR_BLANK=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  T=$(field "$r" 1); WSZ=$(field "$r" 2); WM5=$(field "$r" 3); WCFG=$(field "$r" 4)
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
      --check|--rollback) unk "$T 의 지문" "TARS 표가 **비어 있다** — 굽고 나서 채우세요" ;;
      *) bad "$T 의 지문이 TARS 표에 **비어 있다** — 굽기 꼬리말의 열한 줄을 채우세요" ;;
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
  say "   62-build.sh --go 가 꼬리말에 찍어 주는 **열한 줄**을 이 파일의 TARS 에 그대로"
  say "   붙여 넣은 **뒤에** scp 하세요. 쉰세째에는 빈 표가 그대로 올라가 --preload 가"
  say "   ✗ 둘로 멈췄습니다."
fi

# 🔴 묶음 — A/S 전용. **옛 묶음이 섞여 있는지 먼저 찍는다.**
say ""
say "── 3-ㄴ. 🔴 A/S 마이그레이션 묶음 (A/S 만 그렇다)"
mkdir -p "$INCOMING" 2>/dev/null; chmod 777 "$INCOMING" 2>/dev/null
say "incoming 폴더 안:"
ls -l "$INCOMING" 2>/dev/null | sed 's/^/        /'
say "🔴 **쉰여섯째·쉰일곱째가 두 판 연속 같은 자리를 밟았습니다** — _images-56 의"
say "   옛 묶음(128장)이 섞여 있었습니다. 위 목록에 **지난 판 묶음이 보이면 지우세요.**"
if [ -f "$MIGTAR" ]; then
  sz=$(stat -c %s "$MIGTAR" 2>/dev/null); m5=$(md5sum "$MIGTAR" 2>/dev/null | awk '{print $1}')
  printf '      as-migrations.tar.gz %s바이트 md5 %s\n' "${sz:-?}" "${m5:-?}"
  if [ -z "${MIGTAR_SIZE:-}" ] || [ -z "${MIGTAR_MD5:-}" ]; then
    case "$MODE" in
      --check|--count|--rollback) unk "묶음의 지문" "MIGTAR_SIZE·MIGTAR_MD5 가 비어 있다" ;;
      *) bad "묶음의 지문이 **비어 있다** — 굽기 꼬리말의 두 줄을 채우세요" ;;
    esac
  elif [ "${sz:-x}" = "$MIGTAR_SIZE" ] && [ "${m5:-x}" = "$MIGTAR_MD5" ]; then
    ok "묶음의 크기와 md5 가 구울 때와 같다"
  else
    bad "묶음이 다르다 — 크기 ${sz:-?} (기대 $MIGTAR_SIZE) · md5 ${m5:-?} (기대 $MIGTAR_MD5)"
    say "      🔴 **옛 판의 묶음일 수 있습니다**(_images-57 에 129장짜리가 있습니다)."
  fi
  # 🔴 묶음 안을 **세어서** 본다 — tar | grep -q 는 SIGPIPE 로 거짓이 된다(②).
  INSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE '^drizzle/[0-9]{4}_.*[.]sql$' || true)
  IN129=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE '^drizzle/0129_.*[.]sql' || true)
  IN130=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE '^drizzle/0130_.*[.]sql' || true)
  INJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
  printf '      묶음 안 — .sql %s장 · idx %s개 · 0129 %s · 0130 %s (기대 131 · 131 · 1 · 1)\n' \
    "${INSQL:-?}" "${INJRN:-?}" "${IN129:-?}" "${IN130:-?}"
  if [ "${INSQL:-x}" = "131" ] && [ "${INJRN:-x}" = "131" ] && [ "${IN129:-0}" = "1" ] && [ "${IN130:-0}" = "1" ]; then
    ok "묶음 안이 131장이고 0129·0130 이 둘 다 있다"
  else
    case "$MODE" in
      --check|--count|--rollback) hm "묶음 안이 기대와 다릅니다 — 보내기 전이면 정상일 수 있습니다" ;;
      *) bad "묶음 안이 기대와 다르다 — **보내지 마세요**" ;;
    esac
  fi
  # 🔴 묶음 안의 두 장에 지우는 문장이 없는가 — **잣대를 표본으로 먼저 잰다.**
  pn=$(printf 'DROP TABLE "x";\n' | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
  pf=$(printf 'REFERENCES "b"("id") ON DELETE restrict;\n' | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
  printf '      잣대 표본 — DROP TABLE 을 잡나 %s(기대 1 이상) · ON DELETE 를 안 세나 %s(기대 0)\n' "${pn:-?}" "${pf:-?}"
  if [ "${pn:-0}" -ge 1 ] 2>/dev/null && [ "${pf:-1}" = "0" ]; then
    ok "지우는 문장 잣대가 **살아 있다** (아래 0줄이 아무것도 안 재는 ✓ 가 아니다)"
    for t in 0129 0130; do
      NM=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -E "^drizzle/${t}_.*[.]sql" | head -1)
      if [ -z "${NM:-}" ]; then hm "묶음 안의 $t 을 못 읽었다"; continue; fi
      TB=$(tar -xzOf "$MIGTAR" "$NM" 2>/dev/null)
      net=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
      ond=$(printf '%s\n' "$TB" | grep -cF 'ON DELETE' || true)
      printf '        %s — 지우는 문장 %s줄(기대 0) · (참고) ON DELETE %s줄\n' "$t" "${net:-?}" "${ond:-?}"
      [ "${net:-x}" = "0" ] && ok "$t 이 **더하기만 한다**" || bad "$t 에 지우는 문장이 ${net}줄 있다"
    done
  else
    bad "지우는 문장 잣대가 **죽어 있다** — 아래 검사를 못 믿는다"
  fi
else
  case "$MODE" in
    --check|--count|--rollback) unk "묶음" "아직 $INCOMING 에 없다 (보내기 전이면 정상)" ;;
    --go) hm "묶음이 없습니다 — --preload·--migrate 에서 이미 풀었다면 정상입니다" ;;
    *) bad "묶음이 **없다** — $MIGTAR"; say "      scp -O as-migrations.tar.gz dss-nas:$INCOMING/" ;;
  esac
fi

# ══════════════════════════════════════════════════════════════════════
# ── 4. 🔵 이번 판과 무관하지만 **빼지 않는** 검사들 ──────────────────
# ══════════════════════════════════════════════════════════════════════
step "4. 🔵 빼지 않는 검사 — 한 번 빼면 다시 넣는 사람이 없다"
# 4-ㄱ. 🔴 연락서 폴더 — **이번 판에 더 중요해졌다**
say "── 4-ㄱ. 🔴 연락서 폴더 — 이번 판의 「연락서 폴더에 저장」이 쓰는 자리다"
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
say "🔴 PO 는 A/S 와 **같은 dss_as** 를 보고, 이번 판이 그 DB 에 표를 하나 더합니다."
say "   🔴 PO 의 공용 스키마 핀은 8730c94 라 **그 표를 모릅니다** — 「PO 가 모르는 것」이"
say "      셋에서 **넷**이 됐습니다. 🔵 지금은 직원 접근이 닫혀 있어 안전합니다(2026-11-08)."
role=$("$DOCKER" exec "$PO_APP_CN" sh -c 'printf "%s" "$DATABASE_URL"' 2>/dev/null | sed -n 's|^[a-z]*://\([^:]*\):.*|\1|p')
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
# ── --count : 🔴 **이 배포가 바꾸는 자리를 센다** (전부 select 다) ────
# ══════════════════════════════════════════════════════════════════════
#   🔴 61번의 --count 는 **배지 설정**을 셌다. 그 수는 이번 판과 **상관이 없다** —
#      그대로 두면 이 배포를 재는 숫자가 **하나도 없다.** 통째로 갈았다.
#   🔴 **GROUP BY 1 을 쓰지 않는다.** 61번이 그것 때문에 질의 둘이 통째로 거절돼
#      **✓ 를 띄운 채 속이 비어** 있었다(「아무것도 안 재는 ✓」의 실물).
#      칸 이름으로 묶는다. 그리고 **전체는 있는데 쪼갠 줄이 0 이면 ⚠️** 로 잡는다.
#   🔴 표 이름은 전부 **마이그레이션 .sql 에서 확인한 것**이다 — 지어내지 않았다.
effect_counts() {
  step "🔢 이 배포가 바꾸는 자리 — 세기만 한다 (전부 select)"

  say "── ① 네 집의 **위임 표** (이 배포의 목적물)"
  say "🔵 배포 직후에는 **네 집 다 0줄이 정상**입니다 — 아무도 아직 안 맡겼습니다."
  CNT_SEEN=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    K=$(field "$r" 1); BOX=$(field "$r" 2); DB=$(field "$r" 3); T=$(field "$r" 4)
    rr=$(row_by_key "$SITES" "$K"); NAME=$(field "$rr" 8)
    CNT_SEEN=$((CNT_SEEN+1))
    h=$(has_table "$BOX" "$DB" "$T")
    if [ "${h:-0}" != "1" ]; then
      printf '      %-10s %-34s 표가 **아직 없다**\n' "$NAME" "$T"
      continue
    fi
    all=$(table_rows "$BOX" "$DB" "$T")
    live=$(pgn "$BOX" "$DB" "select count(*) from $T where revoked_at is null and ends_at > now()")
    rev=$(pgn "$BOX" "$DB" "select count(*) from $T where revoked_at is not null")
    printf '      %-10s %-34s 전체 %-5s 살아 있는 줄 %-5s 철회된 줄 %s\n' "$NAME" "$T" "${all:-?}" "${live:-?}" "${rev:-?}"
    if [ -z "${all:-}" ]; then unk "$NAME $T 줄 수" "못 쟀다"
    elif [ "${all:-0}" -ge 1 ] 2>/dev/null && [ -z "${live:-}" ]; then
      hm "$NAME — 전체는 ${all}줄인데 **쪼갠 줄을 못 쟀다**. 질의가 거절됐을 수 있습니다"
    else ok "$NAME $T ${all}줄 (살아 있는 줄 ${live:-?} · 철회 ${rev:-?})"; fi
  done <<ENDCNT1
$(rows_of "$NEW_TABLES")
ENDCNT1
  [ "$CNT_SEEN" = "$NEW_TABLES_WANT" ] && ok "위임 표 ${NEW_TABLES_WANT}개를 다 셌다" \
    || bad "위임 표를 ${CNT_SEEN}개만 셌다"

  say ""
  say "── ② 포털의 **위임 감사 기록** (0010 이 더한 enum 값 둘이 쓰이는 자리)"
  t=$(pgn dss-pg-auth dss_auth "select count(*) from audit_logs")
  c=$(pgn dss-pg-auth dss_auth "select count(*) from audit_logs where action_type = 'DELEGATION_CREATED'")
  v=$(pgn dss-pg-auth dss_auth "select count(*) from audit_logs where action_type = 'DELEGATION_REVOKED'")
  printf '      audit_logs 전체 %s줄 · DELEGATION_CREATED %s · DELEGATION_REVOKED %s\n' "${t:-?}" "${c:-?}" "${v:-?}"
  if [ -z "${t:-}" ]; then unk "포털 감사 기록" "못 쟀다"
  elif [ -z "${c:-}" ] || [ -z "${v:-}" ]; then
    hm "전체는 ${t}줄인데 **쪼갠 줄을 못 쟀다** — enum 값이 아직 없으면 질의가 거절됩니다"
    say "      🔵 --migrate 전에는 그 값이 없으므로 **이것이 정상**입니다."
  else ok "포털 위임 감사 기록 — 생김 ${c} · 철회 ${v} (배포 직후에는 둘 다 0 이 정상)"; fi

  say ""
  say "── ③ **전파 대상** — 포털이 써 줄 시스템 (clients 표)"
  say "🔴 전파가 **한 곳이라도 실패하면 지정 자체가 거절됩니다**(설계 B-13)."
  n=$(pgn dss-pg-auth dss_auth "select count(*) from clients where is_active")
  rows=$(pgrows dss-pg-auth dss_auth "select client_id from clients where is_active order by client_id")
  printf '      살아 있는 clients %s개\n' "${n:-?}"
  printf '%s\n' "$rows" | sed 's/^/        /'
  if [ -z "${n:-}" ]; then unk "clients 수" "못 쟀다"
  elif [ "${n:-0}" -ge 1 ] 2>/dev/null; then
    ok "전파 대상 후보 ${n}개를 찍었다 (표본이 비지 않았다)"
    say "      🔵 이 중 **A/S·재고관리·휴가** 셋이 위임을 받습니다. 셋이 다 새 판이어야"
    say "         포털에서 위임을 맡길 수 있습니다 — 그것이 **올리는 차례**의 까닭입니다."
  else hm "clients 가 0개다 — 사람이 보세요"; fi

  say ""
  say "── ④ **결재 기록 규모** — 새 색인 여덟이 걸린 자리"
  cnt1() { # 1 상자 2 DB 3 표 4 이름
    local h v
    h=$(has_table "$1" "$2" "$3")
    if [ "${h:-0}" != "1" ]; then printf '      %-10s %-34s 표가 없다\n' "$4" "$3"; return; fi
    v=$(table_rows "$1" "$2" "$3")
    printf '      %-10s %-34s %s줄\n' "$4" "$3" "${v:-?}"
    if [ -z "${v:-}" ]; then unk "$4 $3" "못 쟀다"; else ok "$4 $3 ${v}줄"; fi
  }
  cnt1 dss-pg-app dss_as        repair_case_approvals      "A/S관리"
  cnt1 dss-pg-app dss_as        quote_approvals            "A/S관리"
  cnt1 dss-pg-app dss_inventory stock_issue_approval_steps "재고관리"
  cnt1 dss-pg-app dss_leave     web_approval_steps         "휴가관리"
  say "      🔵 이 수가 클수록 새 색인이 하는 일이 큽니다 — [결재 내역]이 **사람과"
  say "         기간**으로 이 표들을 가로지릅니다."

  say ""
  say "── ⑤ **계측기 수동 발송** 이 걸리는 자리 (web_notifications)"
  t=$(pgn dss-pg-app dss_meters "select count(*) from web_notifications")
  s=$(pgn dss-pg-app dss_meters "select count(*) from web_notifications where result = 'SENT'")
  f=$(pgn dss-pg-app dss_meters "select count(*) from web_notifications where result = 'FAILED'")
  last=$(pgq dss-pg-app dss_meters "select coalesce(max(target_ym),'(없음)') from web_notifications")
  printf '      web_notifications 전체 %s줄 · SENT %s · FAILED %s · 마지막 대상 달 %s\n' "${t:-?}" "${s:-?}" "${f:-?}" "${last:-?}"
  if [ -z "${t:-}" ]; then unk "계측기 발송 기록" "못 쟀다"
  elif [ "${t:-0}" -ge 1 ] 2>/dev/null && [ -z "${s:-}" ]; then
    hm "전체는 ${t}줄인데 **쪼갠 줄을 못 쟀다** — 질의가 거절됐을 수 있습니다"
  else
    ok "계측기 발송 기록 ${t}줄 (SENT ${s:-?} · FAILED ${f:-?} · 마지막 ${last:-?})"
    say "      🔴 **--force 가 기록에 부딪혀 터지던 것**을 이번 판이 고쳤습니다. 그 손잡이는"
    say "         [알림 설정] 화면의 **손으로 다시 보내기** 단추입니다."
  fi
  n=$(pgn dss-pg-app dss_meters "select count(*) from web_notify_recipients")
  printf '      받는 사람 %s명\n' "${n:-?}"
  if [ -z "${n:-}" ]; then unk "받는 사람 수" "못 쟀다"
  elif [ "${n:-0}" -ge 1 ] 2>/dev/null; then ok "받는 사람이 ${n}명 등록돼 있다"
  else hm "받는 사람이 0명이다 — 손으로 보내도 아무 데도 안 갑니다"; fi

  say ""
  say "── ⑥ 🔴 **통합 승인함은 셀 DB 가 없다**"
  say "🔴 「0건」이 아니라 **해당 없음**입니다. 이 절은 select 를 한 줄도 안 던집니다 —"
  say "   던졌으면 전부 ✗ 가 났을 것입니다."
  rr=$(row_by_key "$SITES" approvals); PT=$(field "$rr" 7)
  c=$(http_code "$PT")
  printf '      승인함 127.0.0.1:%s → %s\n' "$PT" "${c:-못 읽음}"
  if http_ok "${c:-}"; then ok "승인함이 답한다 ($c) — DB 가 없는 집은 이것이 유일한 값이다"
  else bad "승인함이 $c 를 돌려준다"; fi
}

if [ "$MODE" = "--count" ]; then
  effect_counts
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '%s\n' "🔵 --count 는 **아무것도 안 바꿉니다.** 올리기 전과 뒤에 한 번씩 돌려 맞대세요."
  [ "$FAIL" = "0" ] && [ "$UNK" = "0" ] && exit 0
  exit 1
fi

if [ "$MODE" = "--check" ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s   · 단계 %s · DB 단계 %s\n' "$PASS" "$FAIL" "$UNK" "$PHASE" "$DBPHASE"
  printf '\n%s\n' "🔵 --check 는 **아무것도 안 바꿨습니다.**"
  printf '%s\n' "   다음: tar 열하나와 묶음 하나를 보낸 뒤 --preload → --check → --migrate → --go"
  printf '%s\n' "   🔴 **--migrate 를 건너뛰고 --go 로 가지 마세요** — 네 집의 위임 화면이"
  printf '%s\n' "      표가 없으면 42P01 로 터집니다."
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
bundle_mark() { # 1 태그 2 글자 3 사람이 부르는 말
  local v s t
  v=$("$DOCKER" run --rm -e M="$2" --entrypoint sh "$1" -c \
    'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  s=$(printf '%s' "$v" | awk '{print $1}'); t=$(printf '%s' "$v" | awk '{print $2}')
  printf '        [%s] — server %s개 · static %s개 (🔴 합이 1 이상이어야 한다)\n' "$2" "${s:-?}" "${t:-?}"
  if isnum "${s:-}" && isnum "${t:-}" && [ "$((s + t))" -ge 1 ]; then ok "$3"
  else
    bad "$3 — **없다.** 올리지 마세요"
    say "      🔵 **검사 자신도 의심하세요** — 이 글자는 소스에서만 세어 보았습니다."
  fi
}

preload_inside() {
  step "🔎 들여온 이미지 **안**을 센다 — 겉이 아니라 결과"
  say "🔴 「실었다」와 「쓸 만한 이미지다」는 다른 말입니다."
  # ── 앱 여섯
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    K=$(field "$r" 1); NEW=$(field "$r" 4); NAME=$(field "$r" 8)
    printf '\n    ── %s  %s (앱 · **번들**)\n' "$NAME" "$NEW"
    if ! "$DOCKER" image inspect "$NEW" >/dev/null 2>&1; then bad "$NAME — $NEW 가 안 실렸다"; continue; fi
    v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c "test -f /app/server.js && echo yes || echo no" 2>/dev/null | tr -d '\r')
    [ "${v:-}" = "yes" ] && ok "$NAME runner 스테이지가 맞다" \
      || { bad "$NAME 에 /app/server.js 가 없다 — runner 가 아닌 것을 구웠다"; }
    # 🔴 **public/ 기대값은 집마다 다르다.** 승인함에는 그 폴더가 **아예 없다** —
    #    [실측 2026-11-18] 저장소에도 없고 옛 판(dss-approvals:0.1)에도 없는데
    #    운영이 그 상태로 잘 돌고 있다. 그 집 Dockerfile 88줄이 까닭을 적어 두었다:
    #    「public/ 을 안 담는다 — 이 집에는 그 폴더가 없다. 아홉을 베끼면 여기서
    #     "/app/public": not found 로 멈춘다(2026-10-24 실제로 겪었다)」.
    #    🔴 여섯에 「yes 가 맞다」를 똑같이 들이대 **가짜 ✗** 가 났던 자리다.
    prow=$(row_by_key "$PUBLIC_WANT" "$K"); pw=$(field "$prow" 2)
    v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c 'if [ -d /app/public ]; then printf "yes %s\n" "$(ls -1 /app/public 2>/dev/null | wc -l)"; else printf "no 0\n"; fi' 2>/dev/null | tr -d '\r')
    pst=$(printf '%s' "$v" | awk '{print $1}'); pn=$(printf '%s' "$v" | awk '{print $2}')
    printf '        /app/public: %s (파일 %s개 · 이 집의 기대값 %s)\n' "${pst:-못 읽음}" "${pn:-?}" "${pw:-yes}"
    if [ -z "${pw:-}" ]; then bad "$NAME 의 public 기대값이 PUBLIC_WANT 표에 없다 — 표가 깨졌다"
    elif [ "${pst:-}" != "$pw" ]; then bad "$NAME 의 /app/public 이 ${pst:-못 읽음} 다 — 이 집은 $pw 를 기대했다"
    elif [ "$pw" = "no" ]; then ok "$NAME 에는 public/ 이 **없는 것이 정상**이다 (옛 판에도 없다)"
    elif [ "${pn:-0}" = "0" ]; then hm "$NAME public/ 은 있는데 **비어 있다** — 이 집은 원래 그렇습니다"
    else ok "$NAME public/ 이 담겼다 (${pn}개)"; fi
    mrow=$(row_by_key "$APPMARKS" "$K")
    bundle_mark "$NEW" "$(field "$mrow" 2)" "$NAME 번들에 **이번 판의 글자**가 있다"
    bundle_mark "$NEW" "$(field "$mrow" 3)" "$NAME 에 지난 판의 글자가 그대로 있다 (뒷걸음친 나무가 아니다)"
    if [ "$K" = "approvals" ]; then
      bundle_mark "$NEW" "$APPROVALS_LAST_MARK" "승인함 **마지막 커밋이 담겼다**"
      say "      🔵 승인함만 앱 번들에서 마지막 커밋을 가립니다 — **도구 이미지가 없는 집**입니다."
    fi
    if [ "$K" = "meters" ]; then
      say "      🔴 **계측기 앱은 마지막 커밋을 가리지 못합니다** — 그 커밋이 고친 것이"
      say "         scripts/ · 시험 · 문서뿐입니다. 마지막 커밋은 **도구 이미지**에서 가립니다."
    fi
  done <<ENDPRE1
$(rows_of "$SITES")
ENDPRE1
  # ── 도구 다섯
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    K=$(field "$r" 1); NEW=$(field "$r" 3); NAME=$(field "$r" 6)
    printf '\n    ── %s  %s (도구 · **소스가 글자 그대로**)\n' "$NAME" "$NEW"
    if ! "$DOCKER" image inspect "$NEW" >/dev/null 2>&1; then bad "$NAME — $NEW 가 안 실렸다"; continue; fi
    v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
    [ "${v:-}" = "yes" ] && ok "$NAME tools 스테이지가 맞다" \
      || bad "$NAME 에 /app/package.json 이 없다 — **runner 를 구웠다**(--target tools 를 빠뜨렸다)"
    tmrow=$(row_by_key "$TOOLMARKS" "$K")
    TMK=$(field "$tmrow" 2); TMF=$(field "$tmrow" 3)
    # 🔴 **경로를 상대로 넘기고 /app/ 를 컨테이너 안에서 붙인다.**
    #    [실측 2026-11-18] 개발 PC 의 Git Bash 는 -e F="/app/…" 의 값을
    #    **C:/Program Files/Git/app/…** 으로 조용히 바꾼다(MSYS 경로 번역).
    #    굽기 쪽에서 그 탓에 **멀쩡한 파일 다섯이 missing** 으로 나왔다.
    #    🔵 NAS 는 리눅스라 그 번역이 없다 — 여기서는 안 걸린다. 그래도 같은 꼴로
    #       적어 둔다: 누가 이 파일을 Git Bash 에서 흉내 내 돌려도 살아남는다.
    # 🔴 그리고 yes/no 가 아니라 **센 줄 수**를 받는다 — 0 과 「못 읽음」을 가른다.
    if [ -z "${TMF:-}" ]; then
      bad "$NAME 의 마지막 커밋 표식이 TOOLMARKS 표에 **없다** — 표가 깨졌다"
    else
      v=$("$DOCKER" run --rm -e M="$TMK" -e F="$TMF" --entrypoint sh "$NEW" -c \
        'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s\n" "$(grep -cF -- "$M" "$p")"; else printf "missing 0\n"; fi' 2>/dev/null | tr -d '\r')
      tst=$(printf '%s' "$v" | awk '{print $1}'); tn=$(printf '%s' "$v" | awk '{print $2}')
      printf '        마지막 커밋 표식 [%s] in %s — 파일 %s · 그 글자 %s줄 (기대 hit · 1 이상)\n' \
        "$TMK" "$TMF" "${tst:-못 읽음}" "${tn:-?}"
      if [ "${tst:-}" = "hit" ] && [ "${tn:-0}" -ge 1 ] 2>/dev/null; then
        ok "$NAME **마지막 커밋이 담겼다** (${tn}줄)"
      elif [ "${tst:-}" = "hit" ]; then
        bad "$NAME 에 마지막 커밋의 글자가 **0줄**이다 — **커밋 하나가 빠진 판이다**"
      elif [ "${tst:-}" = "missing" ]; then
        bad "$NAME 에 그 파일 자체가 없다 — src/ 나 scripts/ 가 온전히 안 담겼다"
      else
        bad "$NAME 의 표식을 못 읽었다 (받은 값 [${v:-}])"
      fi
    fi
    # 🔴 마이그레이션이 **이미지 안에서 도는** 세 집은 .sql 수까지 센다.
    case "$K" in
      authtools)      want=11; need="0010" ;;
      inventorytools) want=28; need="0026 0027" ;;
      leavetools)     want=5;  need="0003 0004" ;;
      astools)        want=0;  need="" ;;
      *)              want=-1; need="" ;;
    esac
    if [ "$want" -ge 0 ] 2>/dev/null; then
      n=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '        %s 안 .sql: %s장 (기대 %s)\n' "$IMG_MIGDIR" "${n:-?}" "$want"
      if [ "${n:-x}" = "$want" ]; then
        if [ "$want" = "0" ]; then ok "$NAME 은 drizzle/ 이 **비어 있다** (볼륨이 정본이다)"
        else ok "$NAME 이 ${want}장을 들고 있다"; fi
      else bad "$NAME 이 ${n:-?}장이다 — ${want}장을 기대했다"; fi
      for t in $need; do
        a=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c "ls $IMG_MIGDIR/${t}_*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
        [ "${a:-0}" = "1" ] && ok "$NAME 안에 $t 이 있다" \
          || bad "$NAME 안에 $t 이 없다 — **이 배포의 목적물이 안 담겼다**"
      done
    fi
    if [ "$K" = "astools" ]; then
      v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c 'for pair in "portal_approval_delegations /app/vendor/dss-core/src/schema/portal-approval-delegations.ts" "portal-approval-delegations /app/vendor/dss-core/src/schema/index.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/        /'
      g=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${g:-0}" = "2" ]; then
        ok "A/S도구에 **새 공용 스키마**가 담겼다 (표 + index 내보내기)"
        say "      🔵 index.ts 가 안 내보내면 도구가 그 표를 **못 찾습니다** — 2026-09-21 에"
        say "         운영에서 도구가 전부 죽은 그 자리입니다."
      else bad "A/S도구의 공용 스키마가 둘 중 ${g:-0}개다 — **옛 서브모듈이 담겼다**"; fi
    fi
    if [ "$K" = "meterstools" ]; then
      v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c 'if grep -q "notify-send" /app/scripts/send-notify.ts 2>/dev/null; then echo yes; else echo no; fi' 2>/dev/null | tr -d '\r')
      printf '        send-notify.ts 가 공용 몸통(notify-send)을 부르는가: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then
        ok "계측기도구가 **새 코드**다 (매일 09:00 배치가 이것을 부른다)"
      else bad "계측기도구가 **옛 send-notify.ts** 다 — 배치가 옛 코드로 계속 돈다"; fi
    fi
  done <<ENDPRE2
$(rows_of "$TOOLS")
ENDPRE2
}

# ══════════════════════════════════════════════════════════════════════
# ── 5. --preload : tar 열하나를 들여놓는다 ───────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--preload" ]; then
  step "5. --preload — tar 열하나를 싣는다 (🔴 **아직 안 갈아 끼운다**)"
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
  printf '\n  실은 것 %s / %s · 실패 %s\n' "$LOADED" "$TARS_WANT" "$LOADFAIL"
  [ "$LOAD_SEEN" = "$TARS_WANT" ] && ok "tar ${TARS_WANT}개를 다 봤다" \
    || bad "tar 을 ${LOAD_SEEN}개만 봤다 — TARS 표가 깨졌다"
  if [ "$LOADFAIL" != "0" ]; then stop "싣기에 실패한 것이 ${LOADFAIL}개 있습니다. **compose 는 안 건드렸습니다.**"; fi
  preload_inside
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  if [ "$FAIL" != "0" ]; then
    stop "이미지 안에 ✗ 가 ${FAIL}개 있습니다 — **compose 는 안 건드렸습니다.**"
  fi
  printf '\n%s\n' "✅ 열하나를 다 실었고 안도 온전합니다. **아직 아무것도 안 갈아 끼웠습니다.**"
  printf '%s\n' "   다음: --check 로 다시 재고 → --migrate (🔴 여기서 DB 가 바뀝니다)"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════
# ══ 덤프 · compose 사본 · 묶음 풀기 ═══════════════════════════════════
# ══════════════════════════════════════════════════════════════════════
#   🔴 **이번에는 DB 를 넷 뜬다**(61번은 하나였다). 네 집의 스키마가 바뀐다.
make_dumps() {
  mkdir -p "$BKDB" 2>/dev/null; chmod 777 "$BKDB" 2>/dev/null
  say "🔵 덤프 자리: $BKDB (🔴 받을 폴더는 777 이어야 scp·컨테이너가 쓸 수 있습니다)"
  DUMP_N=0
  dump_one() { # 1 상자 2 DB
    local f
    f="$BKDB/$2-$DUMP_VER-$STAMP.dump"
    printf '    뜨는 중 %s …\n' "$2"
    if "$DOCKER" exec -i "$1" sh -c "pg_dump -U \"\$POSTGRES_USER\" -d $2 -Fc" > "$f" 2>/dev/null; then
      local sz; sz=$(stat -c %s "$f" 2>/dev/null)
      if isnum "${sz:-}" && [ "${sz:-0}" -gt 1000 ]; then
        ok "$2 덤프 ${sz}바이트 — $f"; DUMP_N=$((DUMP_N+1))
      else
        bad "$2 덤프가 ${sz:-0}바이트다 — **쓸 수 없는 덤프다**"
      fi
    else
      bad "$2 덤프를 못 떴다 — $1 이 도는지 보세요"
    fi
  }
  dump_one dss-pg-app  dss_as
  dump_one dss-pg-app  dss_inventory
  dump_one dss-pg-app  dss_leave
  dump_one dss-pg-auth dss_auth
  printf '  뜬 덤프 %s / 4\n' "$DUMP_N"
  if [ "$DUMP_N" != "4" ]; then
    stop "덤프를 넷 다 못 떴습니다 — **아무것도 안 바꿨습니다.** 되돌릴 길부터 만드세요."
  fi
  ok "되돌릴 길이 넷 다 있다 (🔵 승인함은 DB 가 없어 뜰 것이 없다)"
}

backup_compose() {
  mkdir -p "$D/backups" 2>/dev/null
  if cp -a "$CF" "$BK"; then ok "compose 사본을 떴다 — $BK"
  else stop "compose 사본을 못 떴다 — **아무것도 안 바꿨습니다.**"; fi
}

# 🔴 묶음을 푼다 — **A/S 만 그렇다.** 129 → 131.
place_migs() {
  local U B s j
  if [ ! -f "$MIGTAR" ]; then
    s=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
    if [ "${s:-0}" = "131" ]; then
      ok "묶음이 없지만 볼륨이 이미 131장이다 (이미 풀었다 — 건너뛴다)"; return 0
    fi
    bad "묶음이 없고 볼륨도 ${s:-?}장이다 — $MIGTAR 를 보내세요"; return 1
  fi
  U="$INCOMING/unpack-$STAMP"
  mkdir -p "$U" || { bad "푸는 자리를 못 만들었다"; return 1; }
  if ! tar -xzf "$MIGTAR" -C "$U"; then bad "묶음을 못 풀었다"; return 1; fi
  s=$(ls -1 "$U/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  j=$(grep -o '"idx"' "$U/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  printf '    푼 것 — .sql %s장 · idx %s개 (기대 131 · 131)\n' "${s:-?}" "${j:-?}"
  if [ "${s:-x}" != "131" ] || [ "${j:-x}" != "131" ]; then
    bad "푼 것이 기대와 다르다 — **볼륨을 안 건드렸다**"
    say "      🔴 목록에 없는 .sql 은 drizzle 이 **아예 모릅니다**(적용이 0건으로 끝납니다)."
    return 1
  fi
  B="$D/backups/as-migrations-$DUMP_VER-$STAMP"
  if cp -a "$MIGDIR" "$B" 2>/dev/null; then ok "옛 볼륨을 치워 두었다 — $B"
  else hm "옛 볼륨 사본을 못 떴다 — 그래도 진행합니다(덤프가 있습니다)"; fi
  if ! cp -a "$U/drizzle/." "$MIGDIR/"; then bad "볼륨에 못 넣었다"; return 1; fi
  s=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  j=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  printf '    볼륨 — .sql %s장 · idx %s개 (기대 131 · 131)\n' "${s:-?}" "${j:-?}"
  if [ "${s:-x}" = "131" ] && [ "${j:-x}" = "131" ]; then
    ok "볼륨이 **131장**이 됐다 (0129·0130 이 들어왔다)"
    rm -rf "$U" 2>/dev/null
    return 0
  fi
  bad "볼륨이 .sql ${s:-?} · idx ${j:-?} 다 — 131 을 기대했다"
  return 1
}

# ══════════════════════════════════════════════════════════════════════
# ── 6. --migrate : 🔴 **네 집의 DB 를 올린다** ───────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--migrate" ]; then
  step "6. --migrate — 🔴 **여기서 DB 가 바뀐다** (네 집 · 일곱 건)"
  say "🔴 차례: **A/S → 재고관리 → 휴가 → 포털(마지막)**."
  say "   까닭은 **포털 0010 이 유일하게 위험한 문장(ALTER TYPE … ADD VALUE)을**"
  say "   들고 있기 때문입니다. 거기서 멈추면 앞의 셋은 **빈 표만 더해진 상태**로"
  say "   남고 앱은 하나도 안 바뀌었습니다 — 되돌릴 것이 없습니다."
  say "🔵 **다시 돌려도 안전합니다** — drizzle 은 이미 적용한 것을 건너뜁니다."
  if [ "$DBPHASE" = "DONE" ]; then
    ok "네 집이 이미 다 올라가 있다 — 바꿀 것이 없다"
    printf '\n%s\n' "✅ 할 일이 없습니다. 다음은 --go 입니다."
    exit 0
  fi

  say ""
  say "── 6-ㄱ. 🔴 되돌릴 길부터 만든다 — **덤프 넷**"
  make_dumps
  say ""
  say "── 6-ㄴ. compose 사본"
  backup_compose

  say ""
  say "── 6-ㄷ. 🔴 **A/S 마이그레이션 볼륨** — 묶음을 푼다 (129 → 131)"
  say "🔴 A/S 만 그렇습니다. 나머지 셋은 **도구 이미지 안**에 구워져 옵니다."
  if ! place_migs; then stop "볼륨을 못 올렸습니다 — DB 는 한 글자도 안 바꿨습니다."; fi

  say ""
  say "── 6-ㄹ. 🔴 **도구 태그 다섯을 먼저 간다**"
  say "🔴 세 집은 **도구 이미지 안에 .sql 이 들어 있습니다** — 태그를 안 갈면"
  say "   적용이 **0건으로 조용히 끝나고 겉으로는 성공으로 보입니다**(31·39번)."
  say "🔵 profiles: [tools] 라 **직원이 느끼는 것이 없습니다.**"
  SWAP_T=0; SWAP_T_SEEN=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    SVC=$(field "$r" 2); NEW=$(field "$r" 3); OLD=$(field "$r" 4); NAME=$(field "$r" 6)
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
  printf '  바꾼 도구 줄 %s / %s\n' "$SWAP_T" "$TOOLS_WANT"
  if [ "$SWAP_T_SEEN" != "$TOOLS_WANT" ] || [ "$SWAP_T" != "$TOOLS_WANT" ]; then
    stop "도구 줄을 다 못 바꿨습니다 — DB 는 한 글자도 안 바꿨습니다. compose 사본: $BK"
  fi
  # 🔴 compose 가 아직 읽히는가 — 한 줄이 깨지면 **모든 compose 명령이 통째로 죽는다.**
  if dcu config >/dev/null 2>&1; then ok "compose 가 아직 읽힌다 (config 가 통과한다)"
  else
    bad "compose 가 **안 읽힌다** — 되돌립니다"
    cp -a "$BK" "$CF" && say "compose 를 사본으로 되돌렸습니다: $BK"
    stop "compose 가 깨졌습니다. DB 는 한 글자도 안 바꿨습니다."
  fi

  say ""
  say "── 6-ㅁ. 🔴 **db:migrate 를 집마다 돌린다** (차례가 있다)"
  MIG_RAN=0; MIG_SEEN2=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    K=$(field "$r" 1); BOX=$(field "$r" 2); DB=$(field "$r" 3)
    BEF=$(field "$r" 4); AFT=$(field "$r" 5); CMDN=$(field "$r" 6)
    rr=$(row_by_key "$SITES" "$K"); NAME=$(field "$rr" 8)
    tr2=$(row_by_key "$TOOLS" "${K}tools"); SVC=$(field "$tr2" 2)
    MIG_SEEN2=$((MIG_SEEN2+1))
    printf '\n    ── %s (%s · %s)\n' "$NAME" "$DB" "$SVC"
    v=$(mig_count "$BOX" "$DB")
    if [ "${v:-x}" = "$AFT" ]; then ok "$NAME 가 이미 $AFT 다 (건너뛴다)"; MIG_RAN=$((MIG_RAN+1)); continue; fi
    if [ "${v:-x}" != "$BEF" ]; then
      bad "$NAME 가 ${v:-?} 다 — $BEF 를 기대했다. **돌리지 않습니다**"
      stop "앞의 집들은 이미 올라갔을 수 있습니다. 위 표를 보고 사람이 판단하세요. 덤프: $BKDB"
    fi
    # 🔴 A/S 만 적용 전 확인을 할 수 있다(db:preflight 가 그 집에만 있다).
    if [ "$K" = "as" ]; then
      say "🔴 적용 전 확인 — db:preflight (앱은 아직 옛 판으로 살아 있다)"
      dct run --rm "$SVC" npm run db:preflight 2>&1 | sed 's/^/      /'
      PRC=${PIPESTATUS[0]}
      say "(종료 코드 $PRC — 기대 0 · 대기 2건)"
      if [ "$PRC" != "0" ]; then
        bad "db:preflight 가 0 이 아니다 ($PRC) — 사라질 자료가 있다는 뜻이다"
        say "      🔴 0129·0130 에는 그럴 문장이 없습니다. **다른 것이 섞였습니다.**"
        stop "A/S 마이그레이션을 시작하지 않았습니다. 앱은 전부 옛 판 그대로 돕니다."
      fi
    fi
    dct run --rm "$SVC" npm run "$CMDN" 2>&1 | sed 's/^/      /'
    RC=${PIPESTATUS[0]}
    if [ "$RC" = "0" ]; then ok "$NAME $CMDN 끝 (종료 코드 0)"
    else
      bad "$NAME $CMDN 실패 (종료 코드 $RC)"
      if [ "$K" = "auth" ]; then
        say "      🔴 위 글에 **unsafe use of new value**(55P04)가 있습니까?"
        say "         그렇다면 0010 이 **같은 트랜잭션에서 새 enum 값을 썼다**는 뜻입니다 —"
        say "         62-build.sh 4-ㄹ 이 「안 쓴다」로 쟀으니 **그 검사부터 의심하세요.**"
      fi
      say "      🔵 **앞의 집들은 이미 올라갔습니다.** 앱은 하나도 안 바뀌었습니다."
      stop "덤프: $BKDB · compose 사본: $BK"
    fi
    v=$(mig_count "$BOX" "$DB")
    if [ "${v:-x}" = "$AFT" ]; then ok "$NAME 가 ${AFT} 가 됐다 (전 ${BEF})"; MIG_RAN=$((MIG_RAN+1))
    else bad "$NAME 가 ${v:-?} 다 — $AFT 를 기대했다"; stop "덤프: $BKDB"; fi
  done <<ENDMIGRUN
$(rows_of "$MIGS")
ENDMIGRUN
  printf '\n  돌린 집 %s / %s\n' "$MIG_RAN" "$MIGS_WANT"
  [ "$MIG_SEEN2" = "$MIGS_WANT" ] && ok "집 ${MIGS_WANT}곳을 다 돌았다" \
    || bad "집을 ${MIG_SEEN2}곳만 돌았다 — MIGS 표가 깨졌다"
  if [ "$MIG_RAN" != "$MIGS_WANT" ]; then stop "네 집을 다 못 올렸습니다. 덤프: $BKDB"; fi

  say ""
  say "── 6-ㅂ. 🔴 **값으로 확인한다** — 표 넷 · 색인 열둘 · enum 둘"
  POST_T=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    BOX=$(field "$r" 2); DB=$(field "$r" 3); T=$(field "$r" 4)
    K=$(field "$r" 1); rr=$(row_by_key "$SITES" "$K"); NAME=$(field "$rr" 8)
    n=$(has_table "$BOX" "$DB" "$T")
    rows=""; [ "${n:-0}" = "1" ] && rows=$(table_rows "$BOX" "$DB" "$T")
    printf '      %-10s %-34s 있나 %-3s 줄 %s\n' "$NAME" "$T" "${n:-?}" "${rows:-–}"
    if [ "${n:-0}" = "1" ]; then POST_T=$((POST_T+1)); ok "$NAME 에 $T 가 **생겼다** (${rows:-?}줄 — 0 이 정상)"
    else bad "$NAME 에 $T 가 **안 생겼다**"; fi
  done <<ENDPOSTT
$(rows_of "$NEW_TABLES")
ENDPOSTT
  [ "$POST_T" = "$NEW_TABLES_WANT" ] && ok "표 ${NEW_TABLES_WANT}개가 다 생겼다" \
    || bad "표가 ${POST_T}/${NEW_TABLES_WANT} 개 생겼다"
  POST_I=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    BOX=$(field "$r" 2); DB=$(field "$r" 3); IX=$(field "$r" 4); WC=$(field "$r" 5)
    n=$(has_index "$BOX" "$DB" "$IX"); c=$(index_cols "$BOX" "$DB" "$IX")
    printf '      %-56s 있나 %-3s 칸 %-3s (기대 %s)\n' "$IX" "${n:-?}" "${c:-?}" "$WC"
    if [ "${n:-0}" = "1" ] && [ "${c:-x}" = "$WC" ]; then POST_I=$((POST_I+1))
    elif [ "${n:-0}" = "1" ]; then bad "$IX 의 칸이 ${c:-?}개다 — $WC 를 기대했다 (**모양이 다르다**)"
    else bad "$IX 가 **안 생겼다**"; fi
  done <<ENDPOSTI
$(rows_of "$NEW_INDEXES")
ENDPOSTI
  [ "$POST_I" = "$NEW_INDEXES_WANT" ] && ok "색인 ${NEW_INDEXES_WANT}개가 다 생겼고 **칸 수까지 맞다**" \
    || bad "색인이 ${POST_I}/${NEW_INDEXES_WANT} 개다"
  POST_E=0
  for v in $AUTH_ENUM_VALUES; do
    n=$(has_enum_value dss-pg-auth dss_auth "$AUTH_ENUM_TYPE" "$v")
    printf '      %-22s %s (있나 %s)\n' "$AUTH_ENUM_TYPE" "$v" "${n:-?}"
    [ "${n:-0}" = "1" ] && POST_E=$((POST_E+1))
  done
  [ "$POST_E" = "$AUTH_ENUM_WANT" ] && ok "enum 값 ${AUTH_ENUM_WANT}개가 생겼다" \
    || bad "enum 값이 ${POST_E}/${AUTH_ENUM_WANT} 개다"

  # 🔴 DB 가 안 멈췄는가 — 켜진 때를 앞뒤로 맞댄다.
  a=$("$DOCKER" inspect -f '{{.State.StartedAt}}' dss-pg-app 2>/dev/null)
  b=$("$DOCKER" inspect -f '{{.State.StartedAt}}' dss-pg-auth 2>/dev/null)
  [ "${a:-x}" = "${DBSTART_BEFORE:-y}" ] && ok "dss-pg-app 이 **안 멈췄다**" \
    || bad "dss-pg-app 의 켜진 때가 달라졌다 — DB 가 다시 떴다"
  [ "${b:-x}" = "${DBSTART_BEFORE2:-y}" ] && ok "dss-pg-auth 가 **안 멈췄다**" \
    || bad "dss-pg-auth 의 켜진 때가 달라졌다 — DB 가 다시 떴다"

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '\n%s\n' "✅ 네 집의 DB 가 올라갔고 도구 다섯이 새 판을 가리킵니다."
  printf '%s\n' "   🔵 **앱은 아직 전부 옛 판입니다** — 직원이 보는 화면은 그대로입니다."
  printf '%s\n' "   🔵 옛 앱은 새 표와 색인을 **쳐다보지도 않습니다**(읽는 코드가 없습니다)."
  printf '%s\n' "   다음: --go  ⏱ 앱 여섯이 차례로 다시 뜹니다"
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════
# ══ 앱을 갈아 끼우고 다시 띄우는 길 (--go · --rollback 이 함께 쓴다) ══
# ══════════════════════════════════════════════════════════════════════
#   🔴 **차례대로** 한 집씩 띄운다. 한 집이 안 서면 거기서 멈춘다 —
#      다음 집을 띄우면 「반만 새 판」이 더 길어진다.
up_one() { # 1 서비스 2 컨테이너 3 포트 4 이름 5 기대 태그
  local s c i n rc
  printf '    다시 띄우는 중 %s …\n' "$4"
  # 🔴 **파이프의 종료 코드를 sed 에서 받지 않는다** — sed 는 거의 늘 성공해서
  #    「띄우기 실패」가 조용히 통과한다. PIPESTATUS 로 앞의 것을 받는다.
  dcu up -d "$1" 2>&1 | sed 's/^/      /'
  rc=${PIPESTATUS[0]}
  if [ "${rc:-1}" != "0" ]; then
    bad "$4 를 못 띄웠다 (종료 코드 $rc)"; return 1
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
  say "── 🔴 옆으로 안 샜는가 — 안 건드린 넷"
  local seen
  seen=0
  for c in $KEEP_BOXES; do
    seen=$((seen+1))
    s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
    i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
    printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
    [ "${s:-}" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
  done
  [ "$seen" = "$KEEP_BOXES_WANT" ] && ok "안 건드린 넷이 다 돈다" \
    || bad "안 건드린 상자를 ${seen}개만 봤다"
  a=$("$DOCKER" inspect -f '{{.State.StartedAt}}' dss-pg-app 2>/dev/null)
  b=$("$DOCKER" inspect -f '{{.State.StartedAt}}' dss-pg-auth 2>/dev/null)
  [ "${a:-x}" = "${DBSTART_BEFORE:-y}" ] && ok "dss-pg-app 이 **안 멈췄다**" \
    || bad "dss-pg-app 의 켜진 때가 달라졌다 — DB 가 다시 떴다"
  [ "${b:-x}" = "${DBSTART_BEFORE2:-y}" ] && ok "dss-pg-auth 가 **안 멈췄다**" \
    || bad "dss-pg-auth 의 켜진 때가 달라졌다 — DB 가 다시 떴다"
  say ""
  say "── 🔴 compose 의 image: 줄을 **통째로** 찍는다 (사람이 눈으로 본다)"
  grep -n '^ *image:' "$CF" | sed 's/^/        /'
}

# ══════════════════════════════════════════════════════════════════════
# ── 7. --go : 앱 여섯을 차례로 갈아 끼운다 ──────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--go" ]; then
  step "7. --go — 앱 여섯을 **차례로** 갈아 끼운다 ⏱ 정지 창"
  say "🔴 차례: **A/S → 재고관리 → 휴가 → 포털 → 승인함 → 계측기**."
  say "   받는 집 셋이 먼저인 까닭: 포털을 먼저 세우면 아직 통로가 없는 집이 404 를"
  say "   돌려주고 **위임 지정이 통째로 거절됩니다**(설계 B-13). 반대 차례면 아무 일도"
  say "   안 일어납니다 — 표가 비어 있고 화면이 오늘과 같습니다."
  say "   승인함이 포털 뒤인 까닭: **위임을 맡기는 화면이 승인함**이고 그 화면이"
  say "   포털의 통로를 부릅니다. 포털이 옛 판이면 첫 걸음에서 실패합니다."

  # 🔴 관문 — DB 가 안 올라갔으면 가지 않는다.
  if [ "$DBPHASE" != "DONE" ]; then
    bad "DB 단계가 $DBPHASE 다 — DONE 이어야 한다"
    say "      🔴 **--migrate 를 건너뛰고 --go 하면 네 집의 위임 화면이 42P01 로 터집니다.**"
    say "         새 앱은 **제 표를 읽습니다**(포털 왕복이 사라졌습니다) — 표가 없으면"
    say "         그 자리에서 죽습니다."
    stop "먼저 --migrate 를 돌리세요. **아무것도 안 바꿨습니다.**"
  fi
  ok "DB 단계가 DONE 이다 (네 집에 표와 색인이 다 있다)"
  if [ "$PHASE_TOOL_NEW" != "$TOOLS_WANT" ]; then
    bad "도구가 ${PHASE_TOOL_NEW}/${TOOLS_WANT} 만 새 판이다 — --migrate 가 다 안 돌았다"
    stop "먼저 --migrate 를 끝내세요."
  fi
  ok "도구 다섯이 다 새 판이다"

  say ""
  say "── 7-ㄱ. compose 사본"
  backup_compose

  say ""
  say "── 7-ㄴ. 🔴 image: 줄 여섯을 바꾼다 (아직 안 띄운다)"
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
  say "── 7-ㄷ. ⏱ **여기서부터 정지 창** — 한 집씩 차례로 띄운다"
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
      say "      🔵 앞의 $((UP_N)) 집은 새 판으로 서 있고 뒤의 집들은 **옛 판 그대로 돕니다.**"
      say "      🔴 되돌리려면: bash $0 --rollback"
      say "      🔵 DB 는 그대로 둡니다 — 일곱 건이 더하기만 하므로 옛 앱은 안 봅니다."
      stop "compose 사본: $BK · 덤프: $BKDB"
    fi
  done <<ENDUP
$(rows_of "$SITES")
ENDUP
  T1=$(date +%s)
  printf '\n  ⏱ 정지 창 약 %s초 (앱 %s곳)\n' "$((T1 - T0))" "$UP_N"
  [ "$UP_SEEN" = "$SITES_WANT" ] && ok "앱 ${SITES_WANT}곳을 다 띄웠다" \
    || bad "앱을 ${UP_SEEN}곳만 띄웠다"

  final_checks
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '\n%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "🔴 **배포 뒤에 눈으로 볼 곳 — 집이 여섯입니다**"
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "  ① 🔴 **통합 승인함에 [결재권 위임] 화면이 생깁니다** — 이 시스템이 처음으로"
  printf '%s\n' "     갖는 자체 화면입니다. 거기서 **맡기기**를 한 번 해 보세요."
  printf '%s\n' "     🔴 그 한 번이 **네 집을 한꺼번에 재는 시험**입니다 — 포털이 저장하고"
  printf '%s\n' "        A/S·재고관리·휴가 **셋 다에 써 줘야** 성공합니다. 한 곳이라도 실패하면"
  printf '%s\n' "        **지정 자체가 거절**됩니다(설계 B-13)."
  printf '%s\n' "     🔵 거절되면 --count 의 ③ 으로 **전파 대상 목록**을 먼저 보세요."
  printf '%s\n' "  ② 🔵 맡긴 뒤 **네 집의 위임 목록**에 그 줄이 보여야 합니다:"
  printf '%s\n' "     · A/S [사용자 관리] 쪽 위임 구역 · 재고관리 [설정] › 위임"
  printf '%s\n' "     · 휴가 [휴가 설정] › [결재권 위임] · 승인함 [결재권 위임]"
  printf '%s\n' "     🔵 **끝난 위임은 접혀 있습니다**(네 집 다 그렇게 고쳤습니다)."
  printf '%s\n' "  ③ 🔴 **포털 앱 목록 화면 오른쪽 끝에 알림 종**이 생깁니다."
  printf '%s\n' "     🔴 종의 **✕ 와 바깥 눌러 닫기**가 먹는지 보세요 — 그 둘이 함께 안 먹던"
  printf '%s\n' "        일이 있었습니다(allowedDevOrigins 였습니다 · 운영은 무관합니다)."
  printf '%s\n' "  ④ 🔴 **A/S [파일 올리기]** — 셋을 봅니다:"
  printf '%s\n' "     · 아이폰 사진(heic)을 **고를 수 있고** 올리면 **jpg 로 바뀝니다**"
  printf '%s\n' "     · [설명 (선택)] 이 **[파일 이름 (선택)]** 으로 바뀌었습니다"
  printf '%s\n' "       🔵 **비워 두면 한 글자도 안 달라집니다** · 여럿이면 (1)(2) 가 붙습니다"
  printf '%s\n' "     · [연락서 폴더에 저장] 에서 **어느 폴더에 넣을지 고르는 창**이 뜹니다"
  printf '%s\n' "       🔵 넣은 뒤 「공유폴더」 구역이 **새로고침 없이** 다시 읽습니다"
  printf '%s\n' "  ⑤ 🔵 **폰으로 네 화면**을 보세요(모바일 폭 손질 넷):"
  printf '%s\n' "     포털 앱 목록 머리말 · 승인함 기간 고르개 · 재고 현황 단추 넷 ·"
  printf '%s\n' "     A/S [파일 올리기] 패널(분류·파일 칸이 점선 상자를 안 넘어야 합니다)"
  printf '%s\n' "  ⑥ 🔵 **계측기 [알림 설정]에 손으로 다시 보내기 단추**가 생깁니다."
  printf '%s\n' "     🔴 **매일 09:00 배치는 다음 날 아침에야 확인됩니다** — 도구 이미지를"
  printf '%s\n' "        갈았으므로 그때부터 새 코드로 돕니다. 손으로 미리 보려면:"
  printf '%s\n' "        bash $D/jobs/notify-daily.sh"
  printf '%s\n' "  ⑦ 🔴 **「아무것도 안 바뀐 것 같다」면** ① 의 승인함 [결재권 위임] 화면을"
  printf '%s\n' "     먼저 보세요 — 그 화면이 보이면 새 판이 돌고 있는 것입니다."
  printf '%s\n' ""
  printf '%s\n' "🔴 **다음에 할 일 둘**"
  printf '%s\n' "  ㄱ) 06-notify-install.sh 에 **IMAGE=dss-meters-tools:1** 이 박혀 있습니다."
  printf '%s\n' "     그 파일을 다시 돌리는 사람이 **옛 태그를 싣습니다.** 2 로 고쳐 두세요."
  printf '%s\n' "  ㄴ) 🔴 **PO 가 모르는 것이 넷**이 됐습니다 — PO 의 공용 스키마 핀이"
  printf '%s\n' "     8730c94 라 portal_approval_delegations 를 모릅니다. PO 를 다시 여는"
  printf '%s\n' "     날 넷을 한 묶음으로 이식하세요(머리말)."
  printf '%s\n' ""
  printf '%s\n' "🔴 **되돌리기**: bash $0 --rollback  (앱 여섯만 되돌립니다)"
  printf '%s\n' "   🔵 도구 다섯은 새 판 그대로 둡니다 · DB 도 그대로 둡니다."
  printf '%s\n' "   🔵 덤프: $BKDB · compose 사본: $BK"
  printf '%s\n' "  다음: bash $0 --count  ← 올린 뒤 수를 재어 앞의 수와 맞대세요"
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════
# ── 8. --rollback : 앱 여섯만 되돌린다 ──────────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--rollback" ]; then
  step "8. --rollback — 앱 여섯을 옛 태그로 되돌린다"
  say "🔵 **도구 다섯은 새 판 그대로 둡니다**(39·41~61번과 같은 판단) — profiles: [tools]"
  say "   라 평소에 뜨지 않고, 옛 앱이 도구를 부르는 일도 없습니다."
  say "🔴 **DB 는 자동으로 안 되돌립니다** — 일곱 건이 **더하기만** 하므로 옛 앱은"
  say "   그 표와 색인을 **쳐다보지도 않습니다**(읽는 코드가 아예 없습니다)."
  say "   🔵 꼭 되돌려야 하면 표 넷을 **손으로** DROP 합니다. 색인은 그대로 둬도 됩니다."
  say "🔴 되돌리는 차례는 **올린 차례의 거꾸로가 아닙니다** — 같은 차례로 갑니다."
  say "   옛 판끼리는 서로를 안 부르므로 차례가 뜻을 갖지 않습니다."
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
  T0=$(date +%s); RB_N=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    SVC=$(field "$r" 2); CN=$(field "$r" 3); OLD=$(field "$r" 5)
    PORT=$(field "$r" 7); NAME=$(field "$r" 8)
    printf '\n    ── %s\n' "$NAME"
    up_one "$SVC" "$CN" "$PORT" "$NAME" "$OLD" && RB_N=$((RB_N+1))
  done <<ENDRB
$(rows_of "$SITES")
ENDRB
  T1=$(date +%s)
  printf '\n  ⏱ 약 %s초 · 되돌린 집 %s / %s\n' "$((T1 - T0))" "$RB_N" "$SITES_WANT"
  final_checks
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '%s\n' "🔵 앱 여섯을 옛 판으로 되돌렸습니다. 도구와 DB 는 새 판 그대로입니다."
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi

