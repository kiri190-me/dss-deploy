#!/bin/bash
# dss-deploy/nas/setup/66-deploy.sh — 예순두째 배포 (2026-11-19)
#
# 🔴 **NAS 에서 돈다.** DSM 터미널에서 sudo -i 뒤에 부른다.
#     bash /volume1/dss/setup/66-deploy.sh            ← --check (기본 · 아무것도 안 바꾼다)
#     bash /volume1/dss/setup/66-deploy.sh --count
#     bash /volume1/dss/setup/66-deploy.sh --preload
#     bash /volume1/dss/setup/66-deploy.sh --migrate  🔴 **여기서 DB 가 바뀐다**
#     bash /volume1/dss/setup/66-deploy.sh --go
#     bash /volume1/dss/setup/66-deploy.sh --rollback
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 올리는 것 — 한 줄 요약**
# ══════════════════════════════════════════════════════════════════════
#   [진단 Flowchart] 에 **고장 개소 태그**가 생긴다.
#   ① 편집기에서 태그를 **골라 넣거나 새로 만든다**(부품 검색과 같은 방식).
#   ② [진단 Flowchart 관리] 에서 **그 태그로 찾는다.** 목록에는 **3개까지**
#      알약으로 서고 나머지는 **+N** 손잡이 → **떠 있는 메모**로 뜬다.
#   🔴 **DB 가 바뀐다** — 마이그레이션 **1건**(0131_clean_patch.sql):
#        ALTER TABLE "repair_case_flowcharts" ADD COLUMN "fault_tags" jsonb;
#      [실측] RENAME 0 · DROP/DELETE/TRUNCATE 0 · INSERT 0 · ADD COLUMN 1.
#      NULL 을 허용하는 칸 하나를 **더하기만** 한다.
#
#   앱 **하나** · 도구 **하나** · 마이그레이션 **1건** · 묶음 **하나** ·
#   안 건드리는 집 **아홉**.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴🔴 **이번 판은 지난 세 판과 모양이 다르다 — 여기가 이 일의 본체다**
# ══════════════════════════════════════════════════════════════════════
#   63·64·65 는 전부 **마이그레이션 0건 · 서브모듈 안 움직임**이었다. 이번은 둘 다
#   뒤집힌다:
#        | 63·64·65        | 66(이번)
#   -----+-----------------+---------------------------------------------
#   마이그 | **0건**         | 🔴 **1건** (131 → 132)
#   모드   | --tools         | 🔴 **--migrate 가 그 자리를 되찾았다**
#   묶음   | 안 받음         | 🔴 **as-migrations.tar.gz 를 받아 볼륨에 푼다**
#   서브모듈| 안 움직임       | 🔴 **dss-core 가 움직인다**
#
#   🔴 **A/S 의 마이그레이션은 볼륨에서 돈다**(/volume1/dss/as-migrations). 도구
#      이미지 안의 /app/drizzle 은 **비어 있다** — 그 자리에 볼륨이 붙는다.
#      그래서 **묶음을 보내 볼륨에 풀어야** 131 → 132 가 된다. 안 풀면 적용이
#      **0건으로 조용히** 끝나고 겉으로는 성공으로 보인다(31·39번이 겪었다).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **65번의 전제 중 이번에 깨지는 것 여섯 — 하나씩 재서 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴🔴 **표식이 또 갈린다 — 65번 것을 그대로 쓰면 아무것도 안 가른다.**
#      65번의 기능 표식 radiogroup 은 **예순한째가 어제 올린 글자**다.
#      🔴 그래서 **뒷걸음 표식으로 내렸다** — 이제 뒷걸음이 **다섯**이다.
#      🔴 **지시받은 글자(fault_tags)도 틀렸다 — 재 보고 알았다.**
#        [실측 2026-11-19 · 개발 PC] src/ 에서 **1파일**이고, 그 1파일마저
#        **주석 한 줄**이다(mutations/repair-case-flowcharts.ts:282).
#        🔴 **주석은 minify 가 지운다** — 번들에서 0 이 나왔을 것이고, 그 ✗ 는
#           진짜 결함처럼 보였을 것이다.
#      🔴 처방 둘을 **갈래마다 다르게** 썼다:
#        · 앱 번들 — **객체의 칸 이름** faultTags 를 쓴다.
#          [실측] 소스에서 기준 **0파일** → 지금 **13파일**. 🔵 스키마 선언
#          (faultTags: jsonb("fault_tags")) · 조회 결과의 키(row.faultTags) ·
#          React 프롭(tags={row.faultTags}) 로만 쓰이고, **minify 는 객체의 칸
#          이름을 기본으로 안 건드린다**(건드리면 JSON 과 어긋나 앱이 깨진다).
#          🔵 **fault_tags 는 곁들이로 찍는다**(판정에 안 쓴다) — 그 글자는
#          vendor/dss-core 의 **문자열 리터럴**로 번들에 들어가므로, 판정 글자가
#          0 인데 곁들이가 1 이상이면 **스키마만 들어오고 앱 코드가 안 들어온 것**이다.
#        · 도구 이미지 — **이번에 태어난 모듈의 이름**을 쓴다.
#          TOOLMARK = repair-case-flowchart-fault-tag-display
#            in src/components/diagnosis-flowcharts/DiagnosisFlowchartManagementScreen.tsx
#          [실측] 그 **파일 안에서는** 기준 **0줄** → 지금 **1줄**(import 줄).
#          🔵 **새로 생긴 파일을 과녁으로 안 삼았다** — 새 파일이면 「기준 0줄」이
#             파일이 없어서 0 인 것이라 아무것도 안 가른다.
#          🔵 그 화면은 **뒤 커밋(8d8cea3a)에서만** 바뀌었다 — 커밋이 둘이라
#             앞 커밋만 담긴 이미지를 가린다.
#      🔴 **뒷걸음 표식은 다섯이다**(65번은 넷 — 하나 늘렸다. 빼지 마라):
#          radiogroup(예순한째) · "ORDER_ISSUED"(예순째) ·
#          domestic-order-status-filter(쉰아홉째) ·
#          portal_approval_delegations(쉰여덟째) · domesticOrders.view(쉰여섯째).
#
#   ② 🔴 **tar 이름과 태그가 갈린다.** dss-as:5.7 → **5.8** · dss-as-tools:24 → **25**.
#      🔴 TARS 는 **아직 비어 있다** — 굽기 전에 쓴 파일이다(아래 TARS 절).
#      🔴 **묶음 값(MIGTAR_SIZE·MIGTAR_MD5)도 비어 있다** — 65번에는 그 변수
#         자체가 없었다. 66-build.sh --go 가 꼬리말에 찍어 준다.
#
#   ③ 🔴🔴 **2절의 DB 기대값이 단계로 갈린다 — 65번은 한 값이었다.**
#      65번은 「다섯 집이 전과 같다」 하나였다(KEEP). 이번은 **A/S 만 움직인다**:
#        · 적용 전(TODO) → dss_as **131** · 볼륨 **131장** · fault_tags 칸 **없다**
#        · 적용 뒤(DONE) → dss_as **132** · 볼륨 **132장** · fault_tags 칸 **있다**
#      🔴 **한 잣대로 재면 둘 중 하나가 가짜 ✗ 다**(48번이 데인 자리).
#      🔵 나머지 넷(재고 28 · 휴가 5 · 포털 11 · 계측기 3)은 **단계와 무관하게
#         그대로**다 — 그 넷은 65번의 잣대를 글자 그대로 쓴다.
#
#   ④ 🔴 **--tools 자리가 --migrate 로 되돌아간다.**
#      65·64·63 은 마이그레이션이 0건이라 그 자리가 --tools 였다. 이번 판은
#      **62번(마이그레이션이 있던 마지막 판)의 --migrate** 를 가져왔다 — 다만
#      62번은 **네 집 일곱 건**이었고 이번은 **A/S 한 집 한 건**이라 고리가 하나다.
#      🔴 --migrate 가 하는 일(차례가 뜻을 갖는다):
#        덤프 → compose 사본 → **묶음을 볼륨에 푼다**(131 → 132장) →
#        도구 태그를 간다 → db:preflight 로 **대기 1건** 확인 → db:migrate →
#        🔴 **수를 다시 세어 132 인지** + **칸이 실제로 생겼는지** 확인.
#      🔴 **db:migrate 는 오류를 삼키고 exit 1 만 남기는 성질이 있다** — 그래서
#         「종료 코드 0」만으로 끝내지 않고 **적용 뒤 수를 다시 센다.**
#
#   ⑤ 🔴 **--count 에 이번 기능을 세는 절이 는다.**
#      🔴 **배포 전에는 그 칸이 아예 없다** — 질의를 그냥 던지면 42703 으로 거절되고
#         그것이 ✗ 로 보인다. 그래서 **칸이 있는지 먼저 묻고** 없으면 ⚠️ 로만 센다.
#      🔵 **배포 직후에도 0건이 정상**이다 — 아무도 아직 태그를 안 달았다.
#         그래서 이 절은 **✗ 를 한 번도 안 낸다.**
#      🔵 내자 정리 절(상태 거르개 · 덮기 관문)은 **이번 범위와 무관하지만 그대로
#         둔다** — 한 번 빼면 다시 넣는 사람이 없다.
#
#   ⑥ 🔵 **안 건드리는 아홉의 「켜진 때」는 어제 배포로 안 바뀌었다**(A/S 만 떴다).
#      🔴 그래도 이 파일에는 **박아 둔 시각이 한 글자도 없다** — 1절에서 찍어
#         KEEP_SNAP 에 담고 끝에서 맞댄다. 그 길이라 판이 바뀌어도 그대로 산다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **65번에서 그대로 살린 것 — 한 번 빼면 다시 넣는 사람이 없다**
# ══════════════════════════════════════════════════════════════════════
#   · 2절 「DB 가 **안 바뀌었는가**」 — 🔴 **네 집**(28·5·11·3)과 쉰여덟째의 표 넷 ·
#     도구 이미지 안 drizzle 0장. 🔵 A/S 만 2-ㄱ 에서 **단계로 갈라** 잰다.
#   · 🔴 **--no-deps** 와 그 관문(DB 가 도는가 + **실제로 답하는가**) ·
#     끝에서 **DB 둘의 켜진 때 맞대기**. [실측 2026-11-18] 이것이 없어서 --go 가
#     dss-pg-app 을 Recreate 했다 — 자료는 멀쩡했지만 모든 연결이 끊겼다 붙었다.
#   · 함수 정의에 붙인 **</dev/null** — 고리 안의 docker exec 가 here 문서를 먹는다.
#     [실측 2026-11-18] 그것 때문에 2-ㄱ 이 **네 집 중 한 집만** 재고 끝났다.
#   · **「몇 개를 봤는가」 관문** — 고리를 도는 검사마다 끝에서 센 횟수를 단언한다.
#     🔵 이번 판도 **집이 하나**라 고리가 한 바퀴만 도는 것이 정상이다. 🔴 「1이니
#     뜻이 없다」가 아니다 — 표가 깨져 **0바퀴**를 돌아도 ✗ 0 으로 통과하는 것을 막는다.
#   · 덤프(dss_as 하나) · compose 사본 · db:preflight 를 값으로 받기.
#     🔴 다만 **기대값이 「대기 0건」에서 「대기 1건」으로 바뀐다.**
#   · 4절의 **빼지 않는 검사들** — 연락서 폴더 · 양식 폴더 · PO 쓰기 권한 ·
#     발주서 공유폴더.
#   · 🔴 **옛 묶음이 incoming 에 섞여 있는지 먼저 찍기** — 🔴 **이번 판은 거기서
#     읽는다.** 65번처럼 「쳐다보지도 않는다」가 아니다. 옛 묶음(128·129·131장)을
#     보내면 **엉뚱한 판이 볼륨을 덮는다**(쉰여섯째·쉰일곱째가 두 판 연속 밟았다).
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
#       🔵 이 배포는 **자료를 안 바꾼다**(칸을 더할 뿐이다) — 전과 후의 수가
#          같아야 정상이다. 🔴 **고장 개소 태그는 전후 모두 0건**이 정상이다.
#   --preload
#       쓰는 것 : **NAS 의 도커 이미지 저장소**(docker load 로 태그 둘).
#       🔵 실어만 두고 **아직 안 갈아 끼운다.** 싣자마자 **안을 센다.**
#       🔴 **묶음은 여기서 안 푼다** — --migrate 가 푼다(62번과 같은 자리다).
#   --migrate  🔴 **여기서 DB 가 바뀐다**
#       쓰는 것 : **DB 덤프 한 장**(dss_as) · **compose 사본 한 장** ·
#                 🔴 **A/S 마이그레이션 볼륨**(묶음을 풀어 131 → 132장) ·
#                 **compose 의 image: 줄 하나**(tools-as) · 🔴 **DB(dss_as)**.
#       안 쓰는 것: 앱의 image: 줄 · 도는 앱 컨테이너 · 공유폴더 ·
#                 🔴 **나머지 네 집의 DB**(28·5·11·3 은 한 글자도 안 바꾼다).
#       🔵 profiles: [tools] 라 도구는 평소에 안 뜬다 — **직원이 느끼는 것이 없다.**
#       🔵 **다시 돌려도 안전하다** — drizzle 은 이미 적용한 것을 건너뛴다.
#   --go
#       쓰는 것 : **compose 사본 한 장** · **compose 의 image: 줄 하나**(app-as) ·
#                 **앱 하나를 다시 띄운다**(정지 창 — 20~30초).
#       안 쓰는 것: 🔴 **DB** · 볼륨 · 공유폴더 · 🔴 **나머지 아홉 집의 image: 줄**.
#       🔴 **--no-deps 를 쓴다** — 그것이 없어서 DB 가 Recreate 된 적이 있다.
#       🔴 **--migrate 가 먼저 돌아야 한다** — 새 앱이 fault_tags 칸을 읽고 쓴다.
#   --rollback
#       쓰는 것 : **compose 사본 한 장** · **app-as 의 image: 줄** · **앱 하나를 다시 띄운다.**
#       안 쓰는 것: 도구 태그(새 판 그대로 둔다) · DB · 볼륨 · 덤프(안 뜬다).
#       🔴 **DB 는 자동으로 안 되돌린다** — 0131 은 **칸을 더하기만** 하므로 옛 앱은
#          그 칸을 쳐다보지도 않는다(읽는 코드가 없다).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 환경의 함정 — 이 파일이 지키고 있는 것**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 이다.** 이 파일은 **$( … || true )**
#      로만 받는다.
#   ② 🔴 **tar | grep -q 를 if 에 바로 물리지 않는다.** pipefail 아래서 grep -q 가
#      먼저 끝나면 앞의 tar 가 SIGPIPE 로 죽어 **파일이 있을 때 오히려 ✗** 가 난다.
#      🔴 **이번 판은 묶음을 읽는다** — 65번은 「무는 자리가 없다」였다. tar 를
#      읽는 자리는 **전부 세어서 담는 꼴**(grep -c · grep -o)로만 적었다.
#   ③ 🔴 **bash -n 이 못 잡는 둘.** 큰따옴표 안의 백틱 · 읽기전용 자리의 콜론-꺾쇠 →
#      **이 파일에는 둘 다 한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   ④ 🔴 **CRLF.** Git Bash 의 grep 만 \r 를 걷어내고 NAS 의 GNU grep 은 안 걷어낸다.
#      줄 전체로 맞대는 검사는 **읽자마자 tr -d 로 \r 를 걷은 뒤** 한다.
#   ⑤ 🔴 **빈 결과는 삼켜진 오류일 수 있다.** 「비면 OK」로 읽는 자리를 안 만든다 —
#      목록은 **읽은 줄 수를 함께 받고**, **없는 경로 하나를 일부러 함께 묻는다.**
#   ⑥ 🔴 **마이그레이션은 이미지가 아니라 볼륨에서 돈다**(A/S). 이미지 안만 세면
#      0건으로 조용히 끝난다. **볼륨의 .sql 과 _journal.json 을 둘 다** 센다.
#      🔴 이번 판은 **더할 것이 1건**이라 「131장인가 132장인가」를 **단계로 갈라** 잰다.
#   ⑦ 🔴 **저장소의 compose 사본은 운영보다 뒤처진다**(아홉 판 차이가 난 적이 있다).
#      이 파일은 **NAS 위의 docker-compose.nas.yml 만 읽는다.**
#   ⑧ 🔴 **bash 의 $(( )) 는 0 으로 시작하는 수를 8진수로 읽는다** — 0131·0132 를
#      셈에 넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
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
#   🔵 **이번 판이 거기에 더하는 것은 없다** — 이번에 더하는 칸은
#      repair_case_flowcharts.fault_tags 이고 **PO 는 그 표를 쓰지 않는다.**
#      🔵 그리고 칸을 **더하기만** 하므로 모르는 쪽이 깨질 일도 없다.
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
BK=$D/backups/docker-compose.nas.yml.v62-$STAMP
BKDB=$D/backups/db
# 🔴 **BK 와 같은 v 번호여야 한다** — 59번(쉰다섯째)이 여기를 안 고쳐 v54 로 남긴
#    적이 있다. 아래 1-ㄱ-0 절이 값으로 확인한다.
DUMP_VER=v62
INCOMING=$D/setup/incoming
MIGDIR=$D/as-migrations
IMG_MIGDIR=/app/drizzle
TPLDIR=$D/as-templates
# 🔴 **이번 판은 이 묶음을 실제로 읽고 푼다**(65번은 쳐다보지도 않았다).
#    자리는 incoming 이고, 푸는 것은 --migrate 뿐이다 — --preload 는 안 푼다.
MIGTAR=$INCOMING/as-migrations.tar.gz

# ══ 🔴 앱 **하나** ════════════════════════════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트포트|사람이 부르는 이름
SITES='
as|app-as|dss-as|dss-as:5.8|dss-as:5.7|dss-as-5.8.tar|13000|A/S관리
'
SITES_WANT=1

# ══ 🔴 도구 **하나** — --migrate 가 이 줄을 간다 ══════════════════════
#   열쇠|서비스|새 태그|옛 태그|tar|이름|무엇 때문에 가는가
#   🔵 65번은 --tools 가 이 줄을 갈았다. 이번 판은 **--migrate 안에서** 간다 —
#      db:migrate 를 **새 도구로** 돌려야 하기 때문이다(62번과 같은 차례).
TOOLS='
astools|tools-as|dss-as-tools:25|dss-as-tools:24|dss-as-tools-25.tar|A/S도구|🔴 공용 스키마(vendor/dss-core)에 fault_tags 칸이 생겼고 src/ 17장이 바뀌었다
'
TOOLS_WANT=1

# ══ 🔴 안 건드리는 **아홉** — 「옆으로 안 샜다」는 증거로 센다 ════════
#   🔴 상자 이름이다(서비스 이름이 아니다) — 저장소의 compose 사본이 운영보다
#      뒤처져 있어 서비스 이름을 믿을 수 없다(⑦). 63번이 NAS 에서 실제로 쓴 값 그대로다.
KEEP_BOXES="dss-auth dss-approvals dss-inventory dss-leave dss-meters dss-board dss-improvements dss-rf-trouble dss-po"
KEEP_BOXES_WANT=9
KEEP_DB="dss-pg-app dss-pg-auth"
KEEP_DB_WANT=2

# ══ 🔴 DB ① — **이번 판이 움직이는 집 하나** (단계로 갈린다) ══════════
#   열쇠|DB상자|DB이름|전(적용 전)|후(적용 뒤)|migrate 명령|도는 자리|사람이 부르는 이름
#   🔴 **단계마다 기대값이 다르다.** 한 잣대로 재면 둘 중 하나가 **가짜 ✗** 다.
#   🔴 도는 자리가 **volume** 이다 — 이미지 안이 아니라 /volume1/dss/as-migrations
#      에서 돈다. 그래서 묶음을 풀어야 전(131)에서 후(132)로 갈 수 있다.
MIGS='
as|dss-pg-app|dss_as|131|132|db:migrate|volume|A/S관리
'
MIGS_WANT=1

# ══ 🔴 DB ② — **안 바뀌어야 하는 네 집** ═════════════════════════════
#   열쇠|DB상자|DB이름|지금도 뒤에도 이 수여야 한다|사람이 부르는 이름
#   🔴 **어긋나면 이 배포와 무관한 다른 사고다.** 그 자리에서 멈춘다.
#   🔵 65번은 여기에 A/S 도 들어 있어 다섯이었다 — **A/S 만 위 표로 옮겼다.**
#   🔵 통합 승인함은 **DB 가 없는 집**이라 이 표에 없다 — 「0건」이 아니라 해당 없음이다.
MIGS_KEEP='
inventory|dss-pg-app|dss_inventory|28|재고관리
leave|dss-pg-app|dss_leave|5|휴가관리
auth|dss-pg-auth|dss_auth|11|통합로그인포털
meters|dss-pg-app|dss_meters|3|계측기관리
'
MIGS_KEEP_WANT=4

# ══ 🔴 **쉰여덟째가 만든 표 넷** — 뒷걸음 방지 ════════════════════════
#   DB상자|DB이름|표 이름|사람이 부르는 이름
KEEP_TABLES='
dss-pg-app|dss_as|portal_approval_delegations|A/S관리
dss-pg-app|dss_inventory|portal_approval_delegations|재고관리
dss-pg-app|dss_leave|web_portal_approval_delegations|휴가관리
dss-pg-auth|dss_auth|approval_delegations|통합로그인포털
'
KEEP_TABLES_WANT=4

# ══ 🔴 **이번 판이 만드는 칸** — TODO 면 없고 DONE 이면 있어야 한다 ═══
#   🔴 **「있는가」만 보지 않고 꼴까지 본다** — 같은 이름으로 다른 꼴을 만든 것을
#      가르려면 자료형을 봐야 한다(2026-11-07 에 배운 것).
NEWCOL_BOX=dss-pg-app
NEWCOL_DB=dss_as
NEWCOL_TABLE=repair_case_flowcharts
NEWCOL_NAME=fault_tags
NEWCOL_TYPE=jsonb
# 🔵 NULL 을 허용하는 칸이다 — 값을 채우는 마이그레이션이 없다.
NEWCOL_NULLABLE=YES

# ══ 🔴 마이그레이션 안전 잣대 — 62번에서 글자 그대로 가져왔다 ════════
#   🔴 **잣대가 죽어 있으면 「지우는 문장 0줄」이 아무것도 안 재는 ✓ 가 된다.**
#      그래서 3-ㄴ 이 표본 둘로 **잣대부터** 잰다. 🔵 65번에는 이 변수가 없었다 —
#      읽을 .sql 이 없었기 때문이다.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
SQL_COMMENT_RE='^[[:space:]]*--'

# ══ 🔴 A/S 마이그레이션 볼륨 — **131 → 132장** (단계로 갈린다) ════════
AS_VOL_SQL_WAS=131
AS_VOL_SQL_WANT=132
AS_VOL_THIS=0131
AS_VOL_NEXT=0132

# ══ 🔴 tar **둘**의 지문 — [배포본] 66-build.sh 가 굽고 **바로 잰 값** ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 비어 있다 — 굽기 전에 쓴 파일이다.** 66-build.sh --go 가 꼬리말에
#      찍는 **두 줄**로 아래를 통째로 갈아 끼운 **뒤에** scp 하세요.
#   🔴 **이 값을 NAS 에서 재서 채우지 마라.** 그러면 「옮기다 깨졌는가」를 자기가
#      잰 값으로 자기를 재는 꼴이 되어 **영영 통과한다.** 반드시 **구운 쪽**에서 잰다.
#   🔴 비어 있으면 3절이 **--check·--count·--rollback 에서는 ? · --preload·
#      --migrate·--go 에서는 ✗** 로 센다. 🔵 막는 것은 **✗ 뿐이다.**
#      🔴 **쉰세째에는 빈 표가 그대로 NAS 로 올라갔고 --preload 가 ✗ 둘로 멈췄다.**
#   🔵 **지난 판 바이트**(다음 판이 크기를 견줄 때 쓴다):
#      dss-as-5.7.tar 136037888 · dss-as-tools-24.tar 226541568
#   🔵 **이름만 적고 값 칸은 비워 둔다** — 그래야 3절이 「표가 깨졌다」가 아니라
#      「지문이 비어 있다」로 셉니다(65번의 첫 커밋과 같은 꼴입니다).
TARS='
dss-as-5.8.tar|||
dss-as-tools-25.tar|||
'
TARS_WANT=2
# ══ 🔴 **묶음의 지문** — 66-build.sh 가 찍어 준다 ═════════════════════
#   🔴 **65·64·63 에는 이 변수가 아예 없었다.** 62번에서 되살렸다.
#   🔴 **아직 비어 있다.** 비어 있으면 3-ㄴ 이 --check 에서는 ? · --migrate 에서는
#      ✗ 로 센다. 🔴 **NAS 에서 재서 채우지 마라** — 자기가 잰 값으로 자기를 재면
#      영영 통과한다.
MIGTAR_SIZE=
MIGTAR_MD5=

# 🔴 tar 이름 → 태그. **정규식으로 되돌리지 않는다** — 이름마다 손으로 적는다.
#    🔴 판에 점이 있는 것과 없는 것이 섞여 있어 한 규칙으로 안 풀린다.
tar2tag() {
  case "$1" in
    dss-as-5.8.tar)        printf 'dss-as:5.8' ;;
    dss-as-tools-25.tar)   printf 'dss-as-tools:25' ;;
  esac
}

# ══ 🔴 이미지 안에서 쓸 표식 — **전부 ASCII · 전부 리터럴** ═══════════
#   앱 이미지(번들 · minify 를 거친다)
#   🔴 **객체의 칸 이름이다**(머리말 ①). 지시받은 fault_tags 로 재면 src/ 에서
#      **주석 한 줄**뿐이라 번들에서 0 이 나온다 — 주석은 minify 가 지운다.
APPMARK=faultTags
# 🔵 판정에 **안 쓰는** 곁들이 값 — **DB 칸 이름**이다. 번들에는
#    jsonb("fault_tags") 라는 **문자열 리터럴**로 들어간다.
#    🔴 65번의 곁들이는 판정 글자의 **부분집합**(따옴표 꼴)이었지만 **이번 곁들이는
#       다른 글자**다 — 「곁들이가 더 크면 세는 쪽이 깨진 것」이라는 65번의 말이
#       이번 판에는 **거짓**이라 bundle_mark 의 ✗ 가지를 다시 썼다.
#    🔵 둘을 나란히 찍으면 갈린다: 둘 다 ≥1 이면 앱 코드도 스키마도 왔고,
#       판정 0 · 곁들이 ≥1 이면 **스키마만 오고 앱 코드가 안 온 것**이다.
APPMARK_DIAG=fault_tags
KEEPMARK1=radiogroup
KEEPMARK2='"ORDER_ISSUED"'
KEEPMARK3=domestic-order-status-filter
KEEPMARK4=portal_approval_delegations
KEEPMARK5=domesticOrders.view
#   도구 이미지(소스가 글자 그대로 있다) — 🔴 **이번에 태어난 모듈의 이름**을 쓴다.
#   🔵 과녁은 그 모듈이 아니라 **그것을 부르는 화면**이다 — 새 파일을 과녁으로
#      삼으면 「기준 0줄」이 파일이 없어서 0 인 것이라 아무것도 안 가른다.
TOOLMARK=repair-case-flowchart-fault-tag-display
TOOLMARK_FILE=src/components/diagnosis-flowcharts/DiagnosisFlowchartManagementScreen.tsx
TOOLMARK_LINES_WANT=1
# 🔴 그 표식이 가리키는 **새 모듈 자체**도 이미지에 있어야 한다.
TOOLMARK_MODULE=src/lib/domain/repair-case-flowchart-fault-tag-display.ts
PROBE_MISS=src/__dss_probe_no_such_file__.ts

# ══ 🔴 public/ 기대값 ═════════════════════════════════════════════════
#   🔵 A/S 는 yes 이고 안에 **9개**다[실측 2026-11-18 · 구운 것을 열어 셌다].
AS_PUBLIC_WANT=yes

# ══ 🔵 --count 의 참고값 — [운영 실측 2026-11-19 · 예순한째 배포 뒤] ═══
#   🔴 **이것은 ✗ 를 내는 기대값이 아니다.** 사람이 내자 줄을 더하거나 발주일을
#      적으면 정상적으로 달라진다 — 다르면 **⚠️ 로만** 센다.
#   🔴 ✗ 를 내는 것은 **관문 둘**뿐이다(아래 effect_counts의 ②-ㄴ).
#   🔵 **아래 내자 정리 값들은 이번 범위와 무관하다.** 65번 것을 글자 그대로
#      두었다 — 한 번 빼면 다시 넣는 사람이 없다.
CNT_LIVE_REF=36
CNT_DONE_REF=14
CNT_UNDONE_REF=22
CNT_NOORDER_REF=9
# 🔵 「발주 완료」는 예순한째가 **27 → 13** 으로 내린 값이다(완료된 줄을 뺀다).
CNT_ISSUED_REF=13
# 🔵 **발주발행일이 적혀 있는 줄**(④절의 세모가 세우는 줄) — 완료 여부를 안 본다.
CNT_ISSUED_ANY_REF=27
CNT_BOTH_REF=0
CNT_CUST_REF=4
CNT_NOCUST_REF=0
# ══ 🔵 --count 의 **이번 기능** 참고값 ════════════════════════════════
#   🔴 **배포 전에는 칸 자체가 없다** — 질의를 그냥 던지면 42703 으로 거절되고
#      그것이 ✗ 처럼 보인다. 그래서 칸이 있는지 **먼저 묻고** 없으면 ⚠️ 로만 센다.
#   🔴 **배포 직후에도 0건이 정상이다** — 아무도 아직 태그를 안 달았다. 그래서
#      이 절은 **✗ 를 한 번도 안 낸다.** 수가 0 보다 커지는 것도 정상이다.
CNT_TAGGED_REF=0
CNT_DISTINCT_TAGS_REF=0

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
  --check|--count|--preload|--migrate|--go|--rollback) ;;
  *) printf '쓰는 법: %s [--check|--count|--preload|--migrate|--go|--rollback]\n' "$0"
     printf '🔴 **--tools 는 없습니다** — 65·64·63 번에만 있던 자리입니다.\n'
     printf '   이번 판은 마이그레이션이 1건이라 그 자리가 **--migrate** 입니다\n'
     printf '   (묶음을 풀고 · 도구 태그를 갈고 · db:migrate 까지 한 번에 합니다).\n'
     exit 2 ;;
esac

mkdir -p "$D/setup/logs" 2>/dev/null
LOG="$D/setup/logs/deploy62-$(printf '%s' "$MODE" | tr -d '-')-$STAMP.log"
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
# 🔴 **칸은 「있는가」만 묻지 않는다** — 자료형과 NULL 허용까지 본다. 같은 이름으로
#    다른 꼴을 만든 것은 「있는가」로 안 갈린다(2026-11-07 에 배운 것).
#    1 상자 2 DB 3 표 4 칸
has_column() { pgn "$1" "$2" "select count(*) from information_schema.columns where table_schema='public' and table_name='$3' and column_name='$4'"; }
col_type()   { pgq "$1" "$2" "select data_type from information_schema.columns where table_schema='public' and table_name='$3' and column_name='$4'"; }
col_null()   { pgq "$1" "$2" "select is_nullable from information_schema.columns where table_schema='public' and table_name='$3' and column_name='$4'"; }

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
printf '%s\n' " 66-deploy.sh — 예순두째 배포 ($MODE)"
printf '%s\n' "   때      : $(date '+%F %T')"
printf '%s\n' "   로그    : $LOG"
printf '%s\n' "   compose : $CF"
printf '%s\n' "   앱 1 · 도구 1 · 🔴 **마이그레이션 1건** (dss_as $AS_VOL_SQL_WAS → $AS_VOL_SQL_WANT) ·"
printf '%s\n' "   🔴 **묶음 1** (볼륨에 푼다) · 안 건드리는 집 9 · 안 바뀌는 DB 4"
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
say "── 1-ㄴ. 🔴 도구 — **--migrate 가 이 줄을 간다**(65번은 --tools 였습니다)"
say "🔴 도구를 가는 까닭은 **공용 스키마(vendor/dss-core)에 fault_tags 칸이 생겨서**"
say "   입니다 — 66-build.sh 5-ㄹ 의 ㄹ 잣대가 그것을 값으로 쟀습니다."
say "🔴 **도구 태그를 안 갈고 db:migrate 를 돌리면 안 됩니다** — 옛 도구는 그 칸을"
say "   모르는 스키마를 들고 있습니다. 그래서 --migrate 가 **태그를 먼저 갈고** 돕니다."
say "🔵 A/S 는 .sql 이 **이미지가 아니라 볼륨**에 있으므로, 태그를 갈아도 그것만으로는"
say "   132장이 되지 않습니다 — **묶음을 풀어야** 합니다(--migrate 의 6-ㄷ)."
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
  MID)  say "🔴 **--migrate 까지 돌았습니다**(도구만 새 판). 다음은 --go 입니다."
        say "   🔵 --go 뒤에 --rollback 으로 앱만 되돌린 상태도 여기 보입니다."
        say "   🔴 **이번 판은 그 둘을 DB 로 가를 수 있습니다**(65번은 못 갈랐습니다) —"
        say "      --migrate 를 돌았으면 dss_as 가 ${AS_VOL_SQL_WANT} 이고, 그 전이면 ${AS_VOL_SQL_WAS} 입니다."
        say "      🔵 그래도 「--migrate 직후」와 「--go 뒤 --rollback」은 DB 가 같습니다 —"
        say "         가르려면 **로그 파일 이름**(deploy62-go-… / deploy62-rollback-…)을 보세요." ;;
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

# 1-ㅁ. 🔴 묶음이 와 있는가 — **이번 판은 이것을 실제로 읽고 푼다**
say ""
say "── 1-ㅁ. 🔴 incoming 폴더 — **이번 판은 여기서 묶음을 읽습니다**"
say "🔴 65번은 「쳐다보지도 않는다」였습니다 — **이번 판은 뜻이 반대입니다.**"
say "   --migrate 가 여기 있는 묶음을 풀어 볼륨을 ${AS_VOL_SQL_WAS} → ${AS_VOL_SQL_WANT}장으로 만듭니다."
say "🔴 **옛 판의 묶음이 섞여 있을 수 있습니다**(128·129·131장짜리). 아래 목록에"
say "   날짜가 오래된 묶음이 보이면 **지우고 새로 보내세요** — 쉰여섯째·쉰일곱째가"
say "   **두 판 연속** 옛 묶음을 보내 ✗ 를 냈습니다. 3-ㄴ 이 지문으로 다시 가릅니다."
mkdir -p "$INCOMING" 2>/dev/null; chmod 777 "$INCOMING" 2>/dev/null
ls -l "$INCOMING" 2>/dev/null | sed 's/^/        /'
if [ -f "$MIGTAR" ]; then
  ok "incoming 에 묶음이 있다 (3-ㄴ 이 지문과 안을 잽니다)"
else
  case "$MODE" in
    --check|--count|--rollback) unk "묶음" "아직 $INCOMING 에 없다 (보내기 전이면 정상)" ;;
    *) hm "incoming 에 묶음이 없습니다 — **--migrate 전에 보내야 합니다**"
       say "      scp -O as-migrations.tar.gz dss-nas:$INCOMING/" ;;
  esac
fi

# ══════════════════════════════════════════════════════════════════════
# ── 2. 🔴 DB — **1건이다.** 단계마다 기대값이 다르다
# ══════════════════════════════════════════════════════════════════════
step "2. 🔴 DB — 마이그레이션 **1건** (A/S 만 움직인다 · 나머지 넷은 그대로)"
say "🔴 **단계를 먼저 정하고 가지를 나눕니다**(48번이 데인 자리). 「칸이 있는가」는"
say "   적용 전에는 **없는 것이 정상**이고 적용 뒤에는 **있는 것이 정상**입니다 —"
say "   한 잣대로 재면 둘 중 하나가 **가짜 ✗** 입니다."
say "🔴 65·64·63 번은 이 절에 **단계 가지가 없었습니다**(다섯 집이 다 그대로였습니다)."
say "   그대로 베끼면 적용 뒤에 ✗ 가 나거나, 적용 전에 ✗ 가 납니다."

# 2-ㄱ. 🔴 **움직이는 집 하나** — 단계로 갈린다
say ""
say "── 2-ㄱ. 🔴 **A/S 의 마이그레이션 수** — 적용 전 ${AS_VOL_SQL_WAS} · 적용 뒤 ${AS_VOL_SQL_WANT}"
DB_DONE=0; DB_TODO=0; DB_ODD=0; DBM_SEEN=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  BOX=$(field "$r" 2); DB=$(field "$r" 3); BEF=$(field "$r" 4); AFT=$(field "$r" 5)
  WHERE=$(field "$r" 7); NAME=$(field "$r" 8)
  DBM_SEEN=$((DBM_SEEN+1))
  v=$(mig_count "$BOX" "$DB")
  printf '      %-10s %-14s %-16s 지금 %-5s (전 %s → 후 %s · 도는 자리 %s)\n' \
    "$NAME" "$BOX" "$DB" "${v:-못 읽음}" "$BEF" "$AFT" "$WHERE"
  if [ -z "${v:-}" ]; then
    unk "$NAME 마이그레이션 수" "$BOX 가 도는지, 그 DB 가 있는지 보세요"
  elif [ "$v" = "$AFT" ]; then DB_DONE=$((DB_DONE+1)); ok "$NAME 가 이미 $AFT 다 (적용이 끝났다)"
  elif [ "$v" = "$BEF" ]; then DB_TODO=$((DB_TODO+1)); ok "$NAME 가 $BEF 다 (아직 안 올렸다 — 대기 $((AFT - BEF))건)"
  else
    DB_ODD=$((DB_ODD+1))
    bad "$NAME 가 ${v} 다 — $BEF 도 $AFT 도 아니다. **멈추고 알릴 것**"
    doubt
  fi
done <<ENDMIG1
$(rows_of "$MIGS")
ENDMIG1
[ "$DBM_SEEN" = "$MIGS_WANT" ] && ok "움직이는 집 ${MIGS_WANT}곳을 다 봤다 (표본이 비지 않았다)" \
  || bad "움직이는 집을 ${DBM_SEEN}곳만 봤다 — ${MIGS_WANT}곳을 기대했다. MIGS 표가 깨졌다"
if [ "$DB_DONE" = "$MIGS_WANT" ]; then DBPHASE=DONE
elif [ "$DB_TODO" = "$MIGS_WANT" ]; then DBPHASE=TODO
else DBPHASE=ODD; fi
printf '\n  🔴 **DB 단계: %s** (끝난 집 %s · 안 올린 집 %s · 그 밖 %s)\n' "$DBPHASE" "$DB_DONE" "$DB_TODO" "$DB_ODD"
case "$DBPHASE" in
  TODO) say "적용 전입니다 — 아래의 「칸이 없다」·「볼륨 ${AS_VOL_SQL_WAS}장」이 **맞는 값**입니다." ;;
  DONE) say "적용이 끝났습니다 — 아래의 「칸이 있다」·「볼륨 ${AS_VOL_SQL_WANT}장」이 **맞는 값**입니다." ;;
  *)    hm "단계를 못 가렸습니다 — 아래는 **값만 찍고 판정하지 않습니다.**" ;;
esac

# 2-ㄱ-2. 🔴 **안 바뀌어야 하는 네 집** — 65번의 잣대를 글자 그대로 가져왔다
say ""
say "── 2-ㄱ-2. 🔴 마이그레이션 수 — **네 집은 전과 같아야 한다**"
say "🔵 65번은 여기에 A/S 도 있어 다섯이었습니다 — A/S 만 위 2-ㄱ 으로 옮겼습니다."
MIGK_SEEN=0; MIGK_OK=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  BOX=$(field "$r" 2); DB=$(field "$r" 3); WANT=$(field "$r" 4); NAME=$(field "$r" 5)
  MIGK_SEEN=$((MIGK_SEEN+1))
  v=$(mig_count "$BOX" "$DB")
  printf '      %-10s %-14s %-16s 지금 %-5s (기대 %s — **이 집은 0건**)\n' "$NAME" "$BOX" "$DB" "${v:-못 읽음}" "$WANT"
  if [ -z "${v:-}" ]; then
    unk "$NAME 마이그레이션 수" "$BOX 가 도는지, 그 DB 가 있는지 보세요"
  elif [ "$v" = "$WANT" ]; then MIGK_OK=$((MIGK_OK+1)); ok "$NAME 가 $WANT 그대로다"
  else
    bad "$NAME 가 ${v} 다 — $WANT 를 기대했다. 🔴 **이 배포와 무관한 다른 사고다**"
    say "      🔴 이 배포본은 **A/S 한 집에만** 1건을 올립니다. 다른 집의 수가 달라졌다면"
    say "         누가 다른 길로 올렸다는 뜻입니다. **멈추고 사람이 보세요.**"
    doubt
  fi
done <<ENDMIGK
$(rows_of "$MIGS_KEEP")
ENDMIGK
say "본 집 ${MIGK_SEEN} · 같은 집 ${MIGK_OK} (기대 $MIGS_KEEP_WANT · $MIGS_KEEP_WANT)"
if [ "$MIGK_SEEN" = "$MIGS_KEEP_WANT" ] && [ "$MIGK_OK" = "$MIGS_KEEP_WANT" ]; then
  ok "네 집의 마이그레이션 수가 **전부 그대로다** (표본이 비지 않았다)"
  DBKEEP=KEEP
else
  bad "본 집 ${MIGK_SEEN} · 같은 집 ${MIGK_OK} 다 — ${MIGS_KEEP_WANT} 을 기대했다"
  DBKEEP=ODD
fi
printf '\n  🔴 **안 바뀌는 네 집: %s** (KEEP = 넷이 다 전과 같다)\n' "$DBKEEP"
say "🔴 **승인함은 여기에 없습니다** — DB 가 아예 없는 집이라 select 를 한 줄도 안"
say "   던집니다. 던졌으면 전부 ✗ 가 났을 것입니다."

# 2-ㄱ-3. 🔴 **이번 판이 만드는 칸** — 단계마다 기대값이 다르다
say ""
say "── 2-ㄱ-3. 🔴 **${NEWCOL_TABLE}.${NEWCOL_NAME}** — TODO 면 없고 DONE 이면 있어야 한다"
say "🔴 **「있는가」만 보지 않습니다** — 자료형(${NEWCOL_TYPE})과 NULL 허용까지 봅니다."
say "   같은 이름으로 다른 꼴을 만든 것은 「있는가」로 안 갈립니다."
NC=$(has_column "$NEWCOL_BOX" "$NEWCOL_DB" "$NEWCOL_TABLE" "$NEWCOL_NAME")
NCT=""; NCN=""
if [ "${NC:-0}" = "1" ]; then
  NCT=$(col_type "$NEWCOL_BOX" "$NEWCOL_DB" "$NEWCOL_TABLE" "$NEWCOL_NAME")
  NCN=$(col_null "$NEWCOL_BOX" "$NEWCOL_DB" "$NEWCOL_TABLE" "$NEWCOL_NAME")
fi
printf '      %s.%s — 있나 %s · 자료형 %s (기대 %s) · NULL 허용 %s (기대 %s)\n' \
  "$NEWCOL_TABLE" "$NEWCOL_NAME" "${NC:-?}" "${NCT:-–}" "$NEWCOL_TYPE" "${NCN:-–}" "$NEWCOL_NULLABLE"
if [ -z "${NC:-}" ]; then
  unk "$NEWCOL_NAME 칸" "$NEWCOL_BOX 가 도는지, 그 DB 가 있는지 보세요"
else
  case "$DBPHASE" in
    TODO)
      if [ "$NC" = "0" ]; then ok "그 칸이 **아직 없다** (적용 전이라 맞다)"
      else hm "마이그레이션 수는 아직 ${AS_VOL_SQL_WAS} 인데 칸이 벌써 있습니다 — 사람이 보세요"; fi ;;
    DONE)
      if [ "$NC" != "1" ]; then
        bad "적용이 끝났다는데 그 칸이 **없다** — 🔴 **db:migrate 가 오류를 삼켰을 수 있다.** 멈추고 알릴 것"
        doubt
      elif [ "${NCT:-x}" = "$NEWCOL_TYPE" ] && [ "${NCN:-x}" = "$NEWCOL_NULLABLE" ]; then
        ok "그 칸이 **${NEWCOL_TYPE} · NULL 허용**으로 생겼다 (0131 이 적은 그대로다)"
      else
        bad "그 칸이 ${NCT:-?} · NULL 허용 ${NCN:-?} 다 — ${NEWCOL_TYPE} · ${NEWCOL_NULLABLE} 를 기대했다"
        say "      🔴 **같은 이름의 다른 칸입니다.** 누가 손으로 만들었을 수 있습니다."
        doubt
      fi ;;
    *) say "(단계를 못 가려 판정하지 않습니다 — 값만 찍습니다)" ;;
  esac
fi
# 🔴 **잣대가 살아 있는가** — 없는 칸을 물어 0 이 나오는지 본다. 이것이 없으면
#    has_column 이 늘 1 을 돌려주는 꼴을 못 가른다(「무조건 있다」인 검사).
NCP=$(has_column "$NEWCOL_BOX" "$NEWCOL_DB" "$NEWCOL_TABLE" "__dss_probe_no_such_column__")
printf '      없는 칸을 물었을 때: %s (기대 0)\n' "${NCP:-?}"
[ "${NCP:-x}" = "0" ] && ok "칸을 묻는 잣대가 **살아 있다** (위 값을 믿을 수 있다)" \
  || bad "없는 칸을 물었는데 ${NCP:-?} 가 나왔다 — **「무조건 있다」인 검사다.** 위 값도 못 믿는다"

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

# 2-ㄷ. 🔴 A/S 마이그레이션 볼륨 — **131 → 132장** (단계로 갈린다)
say ""
say "── 2-ㄷ. 🔴 A/S 마이그레이션 **볼륨** — ${AS_VOL_SQL_WAS}장인가 ${AS_VOL_SQL_WANT}장인가"
say "🔴 **A/S 만 볼륨에서 돕니다.** 도구 이미지의 /app/drizzle 은 비어 있고 그 자리에"
say "   이 폴더가 붙습니다 — 그래서 묶음을 풀어야 ${AS_VOL_SQL_WAS} → ${AS_VOL_SQL_WANT} 가 됩니다."
say "🔴 **이미지 안만 세면 적용이 0건으로 조용히 끝납니다**(31·39번이 겪었습니다)."
VOL_SEEN=0; VOLPHASE=ODD
if [ -d "$MIGDIR" ]; then
  VOL_SEEN=$((VOL_SEEN+1))
  vs=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  vj=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  vth=$(ls -1 "$MIGDIR/${AS_VOL_THIS}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  vnx=$(ls -1 "$MIGDIR/${AS_VOL_NEXT}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  printf '      볼륨 %s — .sql %s장 · journal idx %s개 · %s %s개 · %s %s개(기대 0)\n' \
    "$MIGDIR" "${vs:-?}" "${vj:-?}" "$AS_VOL_THIS" "${vth:-?}" "$AS_VOL_NEXT" "${vnx:-?}"
  if [ "${vs:-x}" = "$AS_VOL_SQL_WANT" ] && [ "${vj:-x}" = "$AS_VOL_SQL_WANT" ]; then
    VOLPHASE=DONE
    ok "볼륨이 **${AS_VOL_SQL_WANT}장**이고 목록도 ${AS_VOL_SQL_WANT}개다 (묶음이 이미 들어왔다)"
  elif [ "${vs:-x}" = "$AS_VOL_SQL_WAS" ] && [ "${vj:-x}" = "$AS_VOL_SQL_WAS" ]; then
    VOLPHASE=TODO
    ok "볼륨이 아직 **${AS_VOL_SQL_WAS}장**이다 (🔴 **--migrate** 가 묶음을 풀어 넣는다 — --preload 가 아니다)"
  else
    bad "볼륨이 .sql ${vs:-?} · idx ${vj:-?} 다 — ${AS_VOL_SQL_WAS} 나 ${AS_VOL_SQL_WANT} 를 기대했다"
    say "      🔴 **.sql 과 idx 가 다르면** 목록에 없는 파일이 있다는 뜻이고,"
    say "         drizzle 이 그것을 **아예 모릅니다**(적용이 0건으로 조용히 끝납니다)."
    doubt
  fi
  # 🔴 **볼륨과 DB 가 같은 단계인가** — 둘이 어긋나면 사람이 손으로 만진 것이다.
  printf '      단계 맞대기 — DB %s · 볼륨 %s (같아야 한다)\n' "$DBPHASE" "$VOLPHASE"
  if [ "$DBPHASE" = "$VOLPHASE" ]; then
    ok "DB 와 볼륨의 단계가 같다 ($DBPHASE)"
  elif [ "$DBPHASE" = "TODO" ] && [ "$VOLPHASE" = "DONE" ]; then
    hm "볼륨은 ${AS_VOL_SQL_WANT}장인데 DB 는 아직 ${AS_VOL_SQL_WAS} 입니다 — **--migrate 가 가운데서 멈췄을 수 있습니다**"
    say "      🔵 --migrate 는 **다시 돌려도 안전합니다**(drizzle 이 이미 적용한 것을 건너뜁니다)."
  else
    bad "DB 는 $DBPHASE 인데 볼륨은 $VOLPHASE 다 — 🔴 **DB 가 앞서 있다.** 멈추고 사람이 보세요"
    say "      🔴 볼륨에 없는 .sql 이 DB 에 적용돼 있다는 뜻입니다 — 누가 다른 길로 올렸습니다."
    doubt
  fi
  case "$VOLPHASE" in
    TODO) [ "${vth:-1}" = "0" ] && ok "볼륨에 $AS_VOL_THIS 이 아직 없다 (적용 전이라 맞다)" \
            || hm "볼륨이 ${AS_VOL_SQL_WAS}장인데 $AS_VOL_THIS 이 있습니다 — 사람이 보세요" ;;
    DONE) [ "${vth:-0}" = "1" ] && ok "볼륨에 $AS_VOL_THIS 이 **들어왔다** (이 배포의 목적물이다)" \
            || bad "볼륨이 ${AS_VOL_SQL_WANT}장인데 $AS_VOL_THIS 이 ${vth:-?}개다 — **엉뚱한 묶음을 풀었다**" ;;
    *)    say "(단계를 못 가려 $AS_VOL_THIS 은 판정하지 않습니다)" ;;
  esac
  [ "${vnx:-1}" = "0" ] && ok "볼륨에 $AS_VOL_NEXT 이 없다 (마지막이 $AS_VOL_THIS 까지다)" \
    || bad "볼륨에 $AS_VOL_NEXT 이 **있다** — 이 배포본은 $AS_VOL_THIS 까지를 전제로 쓰였다. 멈추고 알릴 것"
  # 🔴 도구 이미지 안은 **비어 있어야** 한다 — 볼륨이 붙는 자리다.
  AST=$(svc_image tools-as)
  if [ -n "${AST:-}" ] && "$DOCKER" image inspect "$AST" >/dev/null 2>&1; then
    n=$(dock "$AST" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
    printf '      A/S 도구 이미지(%s) 안 %s 의 .sql: %s개 (기대 0 — 볼륨이 안 붙은 맨 이미지다)\n' "$AST" "$IMG_MIGDIR" "${n:-?}"
    if isnum "${n:-}" && [ "${n:-1}" = "0" ]; then ok "도구 이미지 안 drizzle/ 이 비어 있다 (🔴 그래서 **묶음을 풀어야** 한다)"
    else bad "도구 이미지 안에 .sql 이 ${n:-?}장 있다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다"; fi
  else
    unk "A/S 도구 이미지 안" "${AST:-태그를 못 읽음} 가 NAS 에 아직 없다 (--preload 전이면 정상)"
  fi
else
  bad "A/S 마이그레이션 볼륨이 없다 — $MIGDIR"
fi
[ "$VOL_SEEN" = "1" ] && ok "볼륨을 봤다" || bad "볼륨을 못 봤다"

# ══════════════════════════════════════════════════════════════════════
# ── 3. 들여올 tar **둘** + 묶음 **하나** ─────────────────────────────
# ══════════════════════════════════════════════════════════════════════
step "3. 들여올 tar 둘 + 묶음 하나 — **옮기다 깨졌는가**"
say "🔴 지문은 **굽는 쪽에서 잰 값**입니다. NAS 에서 재서 채우면 자기가 잰 값으로"
say "   자기를 재는 꼴이 되어 **영영 통과합니다.**"
say "🔴 65번은 여기가 **tar 둘뿐**이었습니다 — 이번 판은 **묶음이 하나 더** 있습니다."
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
  say "   66-build.sh --go 가 꼬리말에 찍어 주는 **두 줄**을 이 파일의 TARS 에 그대로"
  say "   붙여 넣은 **뒤에** scp 하세요. 쉰세째에는 빈 표가 그대로 올라가 --preload 가"
  say "   ✗ 둘로 멈췄습니다."
fi

# 3-ㄴ. 🔴 **묶음** — A/S 전용. 62번에서 되살렸다.
say ""
say "── 3-ㄴ. 🔴 A/S 마이그레이션 묶음 (A/S 만 그렇다)"
say "🔴 **65·64·63 에는 이 절이 없었습니다**(묶음이 없었습니다). 62번에서 가져왔습니다."
if [ -f "$MIGTAR" ]; then
  sz=$(stat -c %s "$MIGTAR" 2>/dev/null); m5=$(md5sum "$MIGTAR" 2>/dev/null | awk '{print $1}')
  printf '      as-migrations.tar.gz %s바이트 md5 %s\n' "${sz:-?}" "${m5:-?}"
  if [ -z "${MIGTAR_SIZE:-}" ] || [ -z "${MIGTAR_MD5:-}" ]; then
    case "$MODE" in
      --check|--count|--rollback) unk "묶음의 지문" "MIGTAR_SIZE·MIGTAR_MD5 가 비어 있다 — 굽고 나서 채우세요" ;;
      *) bad "묶음의 지문이 **비어 있다** — 굽기 꼬리말의 두 줄을 채우세요" ;;
    esac
  elif [ "${sz:-x}" = "$MIGTAR_SIZE" ] && [ "${m5:-x}" = "$MIGTAR_MD5" ]; then
    ok "묶음의 크기와 md5 가 구울 때와 같다"
  else
    bad "묶음이 다르다 — 크기 ${sz:-?} (기대 $MIGTAR_SIZE) · md5 ${m5:-?} (기대 $MIGTAR_MD5)"
    say "      🔴 **옛 판의 묶음일 수 있습니다** — _images-58·59·60·61 에 128·129·131장짜리가"
    say "         있습니다. 쉰여섯째·쉰일곱째가 **두 판 연속** 그것을 보냈습니다."
  fi
  # 🔴 묶음 **안을 세어서** 본다 — tar | grep -q 는 SIGPIPE 로 거짓이 된다(함정 ②).
  INSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE '^drizzle/[0-9]{4}_.*[.]sql$' || true)
  INJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
  INTHIS=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${AS_VOL_THIS}_.*[.]sql" || true)
  INSNAP=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/meta/${AS_VOL_THIS}_snapshot[.]json" || true)
  INNEXT=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${AS_VOL_NEXT}_.*[.]sql" || true)
  printf '      묶음 안 — .sql %s장 · idx %s개 · %s .sql %s · 스냅샷 %s · %s %s개(기대 0)\n' \
    "${INSQL:-?}" "${INJRN:-?}" "$AS_VOL_THIS" "${INTHIS:-?}" "${INSNAP:-?}" "$AS_VOL_NEXT" "${INNEXT:-?}"
  printf '      (기대 %s · %s · 1 · 1 · 0)\n' "$AS_VOL_SQL_WANT" "$AS_VOL_SQL_WANT"
  if [ "${INSQL:-x}" = "$AS_VOL_SQL_WANT" ] && [ "${INJRN:-x}" = "$AS_VOL_SQL_WANT" ] \
     && [ "${INTHIS:-0}" = "1" ] && [ "${INSNAP:-0}" = "1" ] && [ "${INNEXT:-1}" = "0" ]; then
    ok "묶음 안이 ${AS_VOL_SQL_WANT}장이고 ${AS_VOL_THIS} 이 .sql·스냅샷 짝으로 있다"
  else
    case "$MODE" in
      --check|--count|--rollback) hm "묶음 안이 기대와 다릅니다 — 보내기 전이면 정상일 수 있습니다" ;;
      *) bad "묶음 안이 기대와 다르다 — **보내지 마세요**"
         say "      🔴 목록에 없는 .sql 은 drizzle 이 **아예 모르고**, 적용이 0건으로 조용히 끝납니다." ;;
    esac
  fi
  # 🔴 묶음 안의 0131 에 지우는 문장이 없는가 — **잣대를 표본으로 먼저 잰다.**
  pn=$(printf 'DROP TABLE "x";\n' | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
  pa=$(printf 'ALTER TABLE "x" ADD COLUMN "y" jsonb;\n' | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
  printf '      잣대 표본 — DROP TABLE 을 잡나 %s(기대 1 이상) · ADD COLUMN 을 안 세나 %s(기대 0)\n' "${pn:-?}" "${pa:-?}"
  if [ "${pn:-0}" -ge 1 ] 2>/dev/null && [ "${pa:-1}" = "0" ]; then
    ok "지우는 문장 잣대가 **살아 있다** (아래 0줄이 아무것도 안 재는 ✓ 가 아니다)"
    NM=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -E "^drizzle/${AS_VOL_THIS}_.*[.]sql" | head -1)
    if [ -z "${NM:-}" ]; then hm "묶음 안의 $AS_VOL_THIS 을 못 읽었다"
    else
      TB=$(tar -xzOf "$MIGTAR" "$NM" 2>/dev/null)
      net=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
      ins=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'INSERT INTO' || true)
      ac=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'ADD COLUMN' || true)
      rn=$(printf '%s\n' "$TB" | grep -ciE 'RENAME' || true)
      printf '        %s — 지우는 문장 %s줄(기대 0) · INSERT %s(기대 0) · ADD COLUMN %s(기대 1) · RENAME %s(기대 0)\n' \
        "$AS_VOL_THIS" "${net:-?}" "${ins:-?}" "${ac:-?}" "${rn:-?}"
      printf '%s\n' "$TB" | sed 's/^/          /'
      if [ "${net:-x}" = "0" ] && [ "${ins:-1}" = "0" ] && [ "${ac:-0}" = "1" ] && [ "${rn:-1}" = "0" ]; then
        ok "$AS_VOL_THIS 이 **칸 하나를 더하기만 한다** (자료를 안 건드린다)"
      else
        bad "$AS_VOL_THIS 이 기대와 다르다 — 지우는 문장 ${net:-?} · INSERT ${ins:-?} · ADD COLUMN ${ac:-?} · RENAME ${rn:-?}"
        doubt
      fi
    fi
  else
    bad "지우는 문장 잣대가 **죽어 있다** — 아래 검사를 못 믿는다"
  fi
else
  # 🔴 **--rollback 은 첫 가지에서 걸린다** — 그 뒤에 또 적으면 영영 안 닿는 줄이
  #    된다(62번에 그 꼴이 있었다). 가지는 **겹치지 않게** 적는다.
  case "$MODE" in
    --check|--count|--rollback) unk "묶음" "아직 $INCOMING 에 없다 (보내기 전이면 정상)" ;;
    --go) hm "묶음이 없습니다 — **--migrate 에서 이미 풀었다면 정상**입니다 (2-ㄷ 이 볼륨을 쟀습니다)" ;;
    *) bad "묶음이 **없다** — $MIGTAR"
       say "      🔴 --migrate 가 이것을 풀어 볼륨을 $AS_VOL_SQL_WAS → $AS_VOL_SQL_WANT장으로 만듭니다."
       say "      scp -O as-migrations.tar.gz dss-nas:$INCOMING/" ;;
  esac
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
#   🔴 **이 배포는 자료를 한 글자도 안 바꾼다** — 칸을 하나 더할 뿐이다.
#      그래서 이 모드의 뜻은 **「전과 후가 같은가」**다.
#   🔴 **⓪ 절이 새로 생겼다** — 이번 기능(고장 개소 태그)을 세는 자리다.
#      🔴 **배포 전에는 그 칸이 아예 없다** — 질의를 그냥 던지면 42703 으로
#         거절되고 그것이 ✗ 처럼 보인다. 그래서 **칸이 있는지 먼저 묻는다.**
#      🔴 **배포 직후에도 0건이 정상이다**(아무도 아직 안 달았다) — 그래서 이
#         절은 **✗ 를 한 번도 안 낸다. ⚠️ 와 ✓ 만 쓴다.**
#   🔵 아래 ①~⑤(내자 정리)는 **이번 범위와 무관하다.** 65번 것을 글자 그대로
#      두었다 — 한 번 빼면 다시 넣는 사람이 없다.
#   🔴 **GROUP BY 1 을 쓰지 않는다.** 62번이 그것 때문에 질의 둘이 통째로 거절돼
#      **✓ 를 띄운 채 속이 비어** 있었다.
#   🔴 표·칸 이름은 전부 **스키마에서 확인한 것**이다(vendor/dss-core 의
#      repair-case-flowcharts.ts · domestic-orders.ts · repair-cases.ts).
effect_counts() {
  step "🔢 이 배포가 **보여 주는 것**이 달라지는 자리 — 세기만 한다 (전부 select)"
  say "🔵 이 배포는 자료를 한 글자도 안 바꿉니다 — **칸을 하나 더할 뿐**입니다."
  say "   그래서 **전과 후의 수가 같아야 정상**입니다."
  say "🔵 아래 괄호의 「참고」는 **2026-11-19 예순한째 배포 뒤 운영 실측**입니다 —"
  say "   🔴 **✗ 를 내는 기대값이 아닙니다.** 사람이 줄을 더하거나 발주일을 적으면"
  say "   정상적으로 달라집니다. ✗ 를 내는 것은 **아래 ②-ㄴ 의 관문 둘**뿐입니다."

  local t live done_ undone noorder issued issued_any both cust nocust
  local nc tagged distinct flows

  # ── ⓪ 🔴 **이번 기능** — 고장 개소 태그 (65번에는 없던 절이다)
  say ""
  say "── ⓪ 🔴 **고장 개소 태그** — 이 배포가 올리는 바로 그것"
  say "🔴 **배포 전에는 칸이 아예 없습니다.** 질의를 그냥 던지면 42703(칸 없음)으로"
  say "   거절되고, 그 빈 결과가 **진짜 결함처럼** 보입니다 — 그래서 칸이 있는지"
  say "   **먼저 묻고** 없으면 ⚠️ 로만 셉니다."
  say "🔴 **배포 직후에도 0건이 정상입니다** — 아무도 아직 태그를 안 달았습니다."
  say "   그래서 이 절은 **✗ 를 한 번도 안 냅니다.** 0 이 아니어도 정상입니다."
  flows=$(pgn "$NEWCOL_BOX" "$NEWCOL_DB" "select count(*) from $NEWCOL_TABLE where is_deleted = false")
  nc=$(has_column "$NEWCOL_BOX" "$NEWCOL_DB" "$NEWCOL_TABLE" "$NEWCOL_NAME")
  printf '      %s 휴지통 밖 %s줄 · %s 칸이 있나 %s\n' "$NEWCOL_TABLE" "${flows:-?}" "$NEWCOL_NAME" "${nc:-?}"
  if [ -z "${nc:-}" ]; then
    unk "$NEWCOL_NAME 칸" "못 쟀다 — $NEWCOL_BOX 가 도는지 보세요"
  elif [ "$nc" != "1" ]; then
    hm "아직 **그 칸이 없습니다** — 🔵 --migrate 전이면 **정상**입니다. 세지 않고 넘어갑니다"
    say "      🔵 올린 뒤에 다시 돌리면 아래 두 수가 나옵니다(둘 다 0 이 정상입니다)."
  else
    tagged=$(pgn "$NEWCOL_BOX" "$NEWCOL_DB" "select count(*) from $NEWCOL_TABLE where is_deleted = false and $NEWCOL_NAME is not null and jsonb_array_length($NEWCOL_NAME) > 0")
    distinct=$(pgn "$NEWCOL_BOX" "$NEWCOL_DB" "select count(distinct t) from $NEWCOL_TABLE f, lateral jsonb_array_elements_text(f.$NEWCOL_NAME) as t where f.is_deleted = false")
    printf '      태그가 달린 Flowchart %s개 (참고 %s) · 서로 다른 태그 %s가지 (참고 %s)\n' \
      "${tagged:-?}" "$CNT_TAGGED_REF" "${distinct:-?}" "$CNT_DISTINCT_TAGS_REF"
    if [ -z "${tagged:-}" ] || [ -z "${distinct:-}" ]; then
      hm "둘 중 못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
    else
      ok "고장 개소 태그를 값으로 쟀다 (달린 Flowchart ${tagged}개 · 태그 ${distinct}가지)"
      if [ "${tagged}" = "0" ] && [ "${distinct}" = "0" ]; then
        say "      🔵 **둘 다 0 입니다 — 올린 직후라면 맞습니다.** 아무도 아직 안 달았습니다."
      else
        say "      🔵 **0 보다 큽니다 — 누군가 이미 달았다는 뜻이고 그것도 정상입니다.**"
        say "         🔴 두 수의 관계: 태그 가짓수는 달린 Flowchart 수보다 클 수도 작을 수도"
        say "            있습니다(한 줄에 여러 개 · 여러 줄이 같은 것). 관문을 두지 않습니다."
      fi
    fi
  fi
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
  say "🔴 64번은 「발주 완료」를 **order_issued_date is not null 하나**로 셌습니다."
  say "   🔴 **이번 판에 조건이 하나 붙습니다** — and completed_at is null."
  say "   🔵 그래서 그 칸이 **27 → 13** 으로 줄어 보이는 것이 **정상**입니다."
  say "🔴 「발주 대기」는 코드에서 **order_issued_date 가 NULL 인 한 줄** 그대로입니다"
  say "   (공백 접기를 안 합니다 — 화면의 배지와 **같은 한 줄**이라야 사람이 필터를"
  say "   믿습니다). 🔴 **둘은 이제 여집합이 아닙니다** — 날짜 조건만 뒤집음입니다."
  done_=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and completed_at is not null")
  undone=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and completed_at is null")
  noorder=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and order_issued_date is null")
  # 🔴 **64번과 갈리는 한 줄이다.** 64번은 뒤의 and 가 없었고, 그래서 이 값이
  #    ④ 의 「세모가 세우는 줄」과 **같은 수**였다. 이제 다른 수다 — ④ 가 제 질의를
  #    따로 던진다. 🔴 「두 번 재지 마라」는 64번의 말이 **이번 판에 거짓이 됐다.**
  issued=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and order_issued_date is not null and completed_at is null")
  printf '      완료됨 %s(참고 %s) · 미완료 %s(참고 %s) · 발주 대기 %s(참고 %s) · 발주 완료 %s(참고 %s)\n' \
    "${done_:-?}" "$CNT_DONE_REF" "${undone:-?}" "$CNT_UNDONE_REF" "${noorder:-?}" "$CNT_NOORDER_REF" "${issued:-?}" "$CNT_ISSUED_REF"
  if [ -z "${done_:-}" ] || [ -z "${undone:-}" ] || [ -z "${noorder:-}" ] || [ -z "${issued:-}" ]; then
    bad "넷 중 못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
  else
    ok "상태 거르개 **넷**의 줄 수를 다 쟀다 (완료 ${done_} · 미완료 ${undone} · 발주 대기 ${noorder} · 발주 완료 ${issued})"
    [ "${issued}" = "$CNT_ISSUED_REF" ] || hm "「발주 완료」가 참고값 $CNT_ISSUED_REF 와 다릅니다 (${issued}) — 사람이 발주일을 적었거나 완료 처리를 했을 수 있습니다"
  fi

  # 🔴 **관문이 쓸 값이라 여기서 먼저 잰다** — 아래 ②-ㄷ 이 이 변수를 **다시 재지**
  #    **않고 그대로** 쓴다. 두 번 재면 그 사이에 누가 완료 처리를 했을 때 관문과
  #    설명이 서로 다른 수를 말한다.
  both=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and completed_at is not null and order_issued_date is null")

  say ""
  say "── ②-ㄴ 🔴 **관문 둘** — 여기만 ✗ 를 냅니다"
  say "🔴 ㄱ) 완료됨 + 미완료 == 휴지통 밖 (completed_at 하나로 갈리는 반대쪽)"
  say "   🔵 **이 쌍은 이번 판에 한 글자도 안 건드렸습니다** — 64번 그대로입니다."
  say "🔴 ㄴ) **덮기 관문** — 발주 대기 + 발주 완료 + 완료됨 − (완료됨 ∩ 발주 대기)"
  say "       == 휴지통 밖. [운영 실측 2026-11-19] 9 + 13 + 14 − 0 = **36**."
  say "   🔴 **64번의 「발주 대기 + 발주 완료 == 휴지통 밖」은 이번 판에 거짓입니다.**"
  say "      「발주 완료」가 완료된 줄을 빼므로 둘을 더해도 전체가 안 됩니다 —"
  say "      완료되고 발주일도 적힌 줄이 **양쪽 어디에도 안 걸립니다**(실측 14건)."
  say "      그대로 베꼈으면 **진짜 결함처럼 보이는 ✗** 가 났을 자리입니다."
  say "   🔵 셋이 전체를 덮는 까닭: 한 줄은 발주일이 없거나(대기) · 발주일이 있고"
  say "      완료됐거나(완료됨) · 발주일이 있고 아직 안 끝났거나(발주 완료) 셋 중"
  say "      하나입니다. 겹치는 것은 [완료됨 ∩ 발주 대기] **하나뿐**이라 그만큼 뺍니다."
  say "🔵 **이 관문이 실제로 잡는 것은 질의 하나가 조용히 거절된 것**입니다 —"
  say "   order_issued_date 는 **date 칸**이라 DB 쪽에는 빈 문자열이 애초에 못"
  say "   들어갑니다. 🔴 다만 누가 나중에 한쪽 질의에만 공백 접기를 더하면"
  say "   **그때 이 줄이 울립니다.** 그러라고 둔 자리입니다."
  if [ -n "${live:-}" ] && [ -n "${done_:-}" ] && [ -n "${undone:-}" ]; then
    printf '      ㄱ) 완료됨 %s + 미완료 %s = %s (휴지통 밖 %s)\n' "$done_" "$undone" "$((done_ + undone))" "$live"
    if [ "$((done_ + undone))" = "$live" ]; then ok "완료됨 + 미완료 == 휴지통 밖 (${live})"
    else bad "완료됨 + 미완료 가 $((done_ + undone)) 다 — 휴지통 밖 ${live} 를 기대했다"; doubt; fi
  else
    unk "완료 여집합 관문" "앞의 수 중 못 잰 것이 있다"
  fi
  if [ -n "${live:-}" ] && [ -n "${noorder:-}" ] && [ -n "${issued:-}" ] && [ -n "${both:-}" ]; then
    printf '      ㄴ) 발주 대기 %s + 발주 완료 %s + 완료됨 %s − 겹침 %s = %s (휴지통 밖 %s)\n' \
      "$noorder" "$issued" "$done_" "$both" "$((noorder + issued + done_ - both))" "$live"
    if [ "$((noorder + issued + done_ - both))" = "$live" ]; then
      ok "발주 대기 + 발주 완료 + 완료됨 − 겹침 == 휴지통 밖 (${live})"
    else
      bad "덮기 관문이 $((noorder + issued + done_ - both)) 다 — 휴지통 밖 ${live} 를 기대했다"
      say "      🔴 **질의 하나가 거절됐거나, 한쪽에만 공백 접기가 섞였습니다.**"
      doubt
    fi
  else
    unk "덮기 관문" "앞의 수 중 못 잰 것이 있다"
  fi

  say ""
  say "── ②-ㄷ 🔵 **겹치는 줄** — 거르개가 OR 이라야 맞다는 실물"
  say "🔴 **여기서 다시 재지 않습니다** — ②-ㄴ 의 관문이 쓴 값 그대로입니다."
  say "🔴 **겹침이 이제 하나뿐입니다**(2026-11-19 에 바뀌었습니다). 전날까지는"
  say "   「완료됨」과 「발주 완료」도 겹쳤는데, 이제 그 둘은 **배타적**입니다 —"
  say "   「발주 완료」가 완료된 줄을 빼기 때문입니다."
  printf '      완료됨이면서 발주 대기인 줄 %s개 (참고 %s)\n' "${both:-?}" "$CNT_BOTH_REF"
  if [ -z "${both:-}" ]; then unk "겹치는 줄 수" "못 쟀다"
  elif [ "${both:-0}" -ge 1 ] 2>/dev/null; then
    ok "겹치는 줄이 ${both}개 있다 — 🔴 **거르개가 OR 이라야 맞다는 실물 증거다**"
    say "      🔵 교집합이었으면 「완료됨 + 발주 대기」가 **이 ${both}줄만** 나왔을"
    say "         것이고, 사람은 그 뜻으로 고르지 않습니다."
    say "      🔵 **덮기 관문이 이 수만큼 빼는 것도 같은 까닭**입니다."
  else
    ok "겹치는 줄이 0개다 (🔵 지금은 없지만 **생길 수 있습니다** — 완료 처리에"
    say "      「발주일이 적혀 있어야 한다」는 관문이 없습니다)"
    say "      🔴 **0 이라고 덮기 관문에서 빼는 항을 지우지 마세요** — 그 줄이 하나라도"
    say "         생기는 날 관문이 **까닭 없이 ✗** 가 됩니다."
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
  say "🔴🔴 **64번은 여기서 「다시 재지 마라, ② 의 발주 완료와 같은 수인 것이 맞다」고**"
  say "   **적어 두었습니다. 이번 판에 그 말이 거짓이 됐습니다.**"
  say "   🔴 **세모는 완료된 줄도 세웁니다** — 표에서 완료된 줄을 숨기지 않으므로"
  say "      발주발행일 칸에 날짜가 적힌 줄은 **완료 여부와 상관없이 전부** 세워집니다."
  say "   🔴 반면 거르개의 「발주 완료」는 **완료된 줄을 뺍니다**(②)."
  say "   🔵 그래서 **질의가 둘로 갈립니다**: 세모 쪽은 order_issued_date is not null"
  say "      **하나뿐**(참고 27), 거르개 쪽은 거기에 completed_at is null 이 붙습니다"
  say "      (참고 13). 🔴 **두 수가 다른 것이 맞습니다** — 같으면 오히려 한쪽이"
  say "      엉뚱한 질의를 던지고 있다는 뜻입니다."
  # 🔴 그래서 **여기서는 제 질의를 따로 던진다.** ② 의 issued 를 빌려 쓰면 세모가
  #    세우는 줄을 완료된 14건만큼 적게 보고하고, 그 수를 보고 「세울 거리가 없다」로
  #    잘못 읽는다. 🔵 뜻이 다르면 질의도 달라야 한다.
  issued_any=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and order_issued_date is not null")
  printf '      발주발행일이 적혀 있는 줄 %s개 (참고 %s) · ② 의 「발주 완료」는 %s개 (참고 %s)\n' \
    "${issued_any:-?}" "$CNT_ISSUED_ANY_REF" "${issued:-?}" "$CNT_ISSUED_REF"
  if [ -z "${issued_any:-}" ]; then
    unk "발행일 있는 줄 수" "질의가 거절됐을 수 있습니다 — 🔴 빈 결과는 삼켜진 오류일 수 있습니다"
  elif [ "${issued_any:-0}" -ge 2 ] 2>/dev/null; then
    ok "발행일이 있는 줄이 ${issued_any}개다 (세울 거리가 있다)"
    # 🔴 **둘의 관계를 값으로 단언한다** — 세모 쪽이 거르개 쪽을 품어야 한다.
    #    뒤집히면 한쪽 질의에 엉뚱한 조건이 붙은 것이고, 수만 봐서는 안 드러난다.
    if [ -n "${issued:-}" ] && [ "${issued_any}" -ge "${issued}" ] 2>/dev/null; then
      ok "세모가 세우는 줄(${issued_any})이 「발주 완료」(${issued})를 **품는다** (완료된 줄만큼 더 많다)"
    elif [ -n "${issued:-}" ]; then
      bad "세모가 세우는 줄이 ${issued_any} 인데 「발주 완료」가 ${issued} 다 — 품어야 한다"
      say "      🔴 한쪽 질의에 **엉뚱한 조건**이 붙었습니다. 위 두 줄을 보세요."
      doubt
    else
      unk "둘의 관계" "② 에서 「발주 완료」를 못 쟀습니다"
    fi
  else
    hm "발행일이 있는 줄이 ${issued_any}개뿐입니다 — **눌러도 눈에 안 보일 수 있습니다.** 사람이 보세요"
  fi

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
  printf '%s\n' "   🔴 이번 판도 **같은 수가 나오는 것이 정상**입니다 — 칸을 더할 뿐이고"
  printf '%s\n' "      자료는 한 글자도 안 바꿉니다."
  printf '%s\n' "   🔵 **딱 하나 달라지는 것**: ⓪절이 올리기 전에는 「칸이 없다」로 ⚠️ 를"
  printf '%s\n' "      내고, 올린 뒤에는 **0건 · 0가지**를 값으로 찍습니다."
  [ "$FAIL" = "0" ] && [ "$UNK" = "0" ] && exit 0
  exit 1
fi

if [ "$MODE" = "--check" ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s   · 단계 %s · DB %s · 안 바뀌는 넷 %s · 볼륨 %s\n' \
    "$PASS" "$FAIL" "$UNK" "$PHASE" "$DBPHASE" "$DBKEEP" "$VOLPHASE"
  printf '\n%s\n' "🔵 --check 는 **아무것도 안 바꿨습니다.**"
  printf '%s\n' "   다음: tar 둘과 **묶음 하나**를 보낸 뒤 --preload → --check → --migrate → --go"
  printf '%s\n' "   🔴 **--tools 는 없습니다** — 65·64·63 번에만 있던 자리입니다."
  printf '%s\n' "      이번 판은 그 자리가 **--migrate** 입니다: 묶음을 볼륨에 풀고($AS_VOL_SQL_WAS → $AS_VOL_SQL_WANT장) ·"
  printf '%s\n' "      도구 태그를 갈고 · db:migrate 로 **DB 를 $AS_VOL_SQL_WAS → $AS_VOL_SQL_WANT** 로 올립니다."
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
#   🔵 넷째 인자는 **판정에 안 쓰는 곁들이 값**이다.
#   🔴🔴 **65번과 뜻이 다르다.** 65번의 곁들이는 판정 글자의 **부분집합**(따옴표 꼴)
#      이라 「곁들이가 더 크면 세는 쪽이 깨진 것」이라고 적어 두었다. **이번 판의
#      곁들이는 아예 다른 글자**(판정 faultTags · 곁들이 fault_tags)이므로 그 말이
#      **거짓**이다 — ✗ 가지의 설명을 그에 맞게 다시 썼다.
#   🔵 이번 곁들이가 말해 주는 것:
#      · 둘 다 ≥1 → 앱 코드도 스키마도 번들에 들어왔다
#      · 판정 0 · 곁들이 ≥1 → **스키마 문자열만 들어오고 앱 코드가 안 들어왔다**
#      · 둘 다 0 → 옛 소스를 구웠다
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
      say "      🔴 **곁들이 글자는 1 이상입니다** — 이미지가 통째로 비어 있지는 않습니다."
      say "         곁들이는 **스키마의 문자열 리터럴**이고 판정 글자는 **객체의 칸 이름**이라,"
      say "         이 꼴은 **앱 코드가 안 들어왔거나 minify 가 칸 이름까지 줄인 것**입니다."
      say "         🔵 올리지 말고 개발 PC 에서 다시 재세요(66-build.sh --verify) —"
      say "            검사 쪽이 틀린 것이면 **다시 구울 일이 아닙니다.**"
    else
      say "      🔴 **곁들이 글자도 0 입니다** — 옛 소스가 담긴 이미지입니다."
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
    bundle_mark "$NEW" "$APPMARK"   "$NAME 번들에 **이번 판의 글자**가 있다 (고장 개소 태그의 칸 이름)" "$APPMARK_DIAG"
    bundle_mark "$NEW" "$KEEPMARK1" "$NAME 에 **예순한째가 올린 글자**가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$NEW" "$KEEPMARK2" "$NAME 에 **예순째가 올린 글자**가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$NEW" "$KEEPMARK3" "$NAME 에 **쉰아홉째가 올린 글자**가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$NEW" "$KEEPMARK4" "$NAME 에 **쉰여덟째가 올린 글자**가 그대로 있다 (뒷걸음친 나무가 아니다)"
    bundle_mark "$NEW" "$KEEPMARK5" "$NAME 에 **쉰여섯째가 올린 글자**가 그대로 있다 (뒷걸음친 나무가 아니다)"
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
    #    🔵 이 표식은 **이번에 태어난 모듈의 이름**이고 과녁은 **그것을 부르는 화면**
    #       이다. 그 화면은 **뒤 커밋(8d8cea3a)에서만** 바뀌었다 — 커밋이 둘이라
    #       앞 커밋만 담긴 이미지를 가린다(머리말 ①).
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
    # 🔴 **이번 판이 담아야 하는 것** — 새로 생긴 도메인 모듈과 괄호·대괄호 경로.
    #    🔴 그 괄호 경로가 **글롭 함정의 실물**이다(65번까지는 그런 경로가 0장이었다) —
    #       set -f 가 없으면 그 줄이 파일 이름 확장으로 읽혀 **없는 것으로 나온다.**
    #    🔵 없는 경로 하나를 함께 묻는다 — 「무조건 yes」인 검사인지 가른다.
    v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c \
      'set -f; n=0; m=0; for f in "src/lib/domain/repair-case-flowchart-fault-tag-display.ts" "src/components/repair-cases/flowchart/FaultTagSuggestionList.tsx" "src/app/(app)/repair-cases/[id]/diagnosis/[flowchartId]/page.tsx"; do [ -f "/app/$f" ] && n=$((n+1)); done; [ -f "/app/src/__dss_probe_no_such_file__.ts" ] && m=1; printf "n=%s miss=%s\n" "$n" "$m"' </dev/null 2>/dev/null | tr -d '\r')
    g=$(printf '%s' "$v" | sed -n 's/.*n=\([0-9]*\).*/\1/p')
    mm=$(printf '%s' "$v" | sed -n 's/.*miss=\([0-9]*\).*/\1/p')
    printf '        이번 판의 새 파일 셋(%s 외 둘): %s개 (기대 3) · 없는 경로가 있다고 나왔나 %s (기대 0)\n' \
      "$TOOLMARK_MODULE" "${g:-?}" "${mm:-?}"
    # 🔴 **빈 결과와 「1」을 가른다** — 둘 다 ✗ 지만 **까닭이 반대**다. 한 말로
    #    뭉개면 다음 사람이 엉뚱한 곳을 판다(「빈 결과는 삼켜진 오류일 수 있다」).
    if [ -z "${mm:-}" ] || [ -z "${g:-}" ]; then
      bad "$NAME — **컨테이너에서 값을 못 받았다** (받은 값 [${v:-}]). 위 수를 믿지 마세요"
    elif [ "${mm:-1}" != "0" ]; then
      bad "$NAME — **없는 경로가 있다고 나왔다.** 「무조건 yes」인 검사다. 위 수도 못 믿는다"
    elif [ "${g:-x}" = "3" ]; then
      ok "$NAME 에 이번 판의 새 파일 셋이 담겼다 (괄호·대괄호가 든 경로 하나 포함)"
      say "      🔵 그 셋이 고장 개소 태그의 **몸통**입니다 — 가르는 규칙 · 후보 목록 ·"
      say "         편집기를 띄우는 페이지."
    else
      bad "$NAME 에 그 셋이 ${g:-?}/3 개다 — src/ 가 온전히 안 담겼다"
    fi
    # 🔵 **ㄷ 잣대가 살아 있는 자리** — 지난 판들이 지켜 온 도구 둘이 아직 있는가.
    #    🔴 이번 판에는 그 둘이 부르는 모듈이 안 바뀌었다. **그래도 빼지 않는다** —
    #       scripts/ 가 온전히 담겼는지를 값으로 보이는 자리이기도 하다.
    v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c \
      'set -f; n=0; for f in scripts/lib/delivered-date-sync-survey.ts scripts/lib/requested-due-date-sync-survey.ts; do [ -f "/app/$f" ] && n=$((n+1)); done; printf "n=%s\n" "$n"' </dev/null 2>/dev/null | tr -d '\r')
    g=$(printf '%s' "$v" | sed -n 's/.*n=\([0-9]*\).*/\1/p')
    printf '        지난 판들이 지켜 온 scripts/ 둘: %s개 (기대 2)\n' "${g:-?}"
    if [ "${g:-x}" = "2" ]; then ok "$NAME 에 그 둘이 담겼다 (scripts/ 가 온전히 담겼다)"
    else bad "$NAME 에 그 둘이 ${g:-?}/2 개다 — scripts/ 가 온전히 안 담겼다"; fi
    # 🔴 A/S 도구는 drizzle 을 **안 담아야** 한다 — 볼륨이 정본이다.
    n=$(dock "$NEW" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
    printf '        %s 안 .sql: %s장 (기대 0 — 볼륨이 정본이다)\n' "$IMG_MIGDIR" "${n:-?}"
    if isnum "${n:-}" && [ "${n:-1}" = "0" ]; then ok "$NAME 은 drizzle/ 이 **비어 있다**"
    else bad "$NAME 안에 .sql 이 ${n:-?}장 있다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다"; fi
    # 🔴 **공용 스키마** — 핀이 맞아도 **빈 서브모듈이 담길 수 있다**.
    #    🔴 **넷으로 늘렸다**(65번은 셋이었다): 앞의 셋은 뒷걸음, **넷째는 이번 판이
    #       더한 칸**이다. 넷째가 없으면 0131 만 올라가고 코드는 그 칸을 모른다.
    v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c 'for pair in "portal_approval_delegations /app/vendor/dss-core/src/schema/portal-approval-delegations.ts" "portal-approval-delegations /app/vendor/dss-core/src/schema/index.ts" "due_date_row_order /app/vendor/dss-core/src/schema/repair-case-approvals.ts" "fault_tags /app/vendor/dss-core/src/schema/repair-case-flowcharts.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' </dev/null 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/          /'
    g=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
    if [ "${g:-0}" = "4" ]; then
      ok "$NAME 에 **공용 스키마가 넷 다 담겼다** (지난 판들의 셋 + 🔴 **이번 판의 fault_tags 칸**)"
      say "      🔵 index.ts 가 안 내보내면 도구가 그 표를 **못 찾습니다** — 2026-09-21 에"
      say "         운영에서 도구가 전부 죽은 그 자리입니다."
    else
      bad "$NAME 의 공용 스키마가 넷 중 ${g:-0}개다 — **빈 서브모듈이나 옛 판이 담겼다**"
      say "      🔴 fault_tags 만 no 면 **서브모듈 핀이 옛 것인 채로 구웠다**는 뜻입니다."
    fi
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
  say "🔴 **묶음은 여기서 안 풉니다** — --migrate 가 풉니다(62번과 같은 자리입니다)."
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
  printf '%s\n' "   다음: --check 로 다시 재고 → --migrate (🔴 **거기서 DB 가 바뀝니다**)"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════
# ══ 덤프 · compose 사본 ═══════════════════════════════════════════════
# ══════════════════════════════════════════════════════════════════════
#   🔴 **dss_as 하나만 뜬다**(62번은 넷이었다 — 네 집의 스키마가 바뀌었다).
#   🔴 **이번 판은 그 DB 가 실제로 바뀐다** — 65번처럼 「바꿀 것이 없는데 그래도
#      뜬다」가 아니다. 덤프가 **되돌릴 유일한 길**이다.
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
# ══ 🔴 묶음을 볼륨에 푼다 — **A/S 만 그렇다** (62번에서 되살렸다) ════
# ══════════════════════════════════════════════════════════════════════
#   🔴 A/S 도구의 /app/drizzle 은 **비어 있고**(2-ㄷ 이 값으로 쟀다) 운영에서는
#      거기에 이 폴더가 붙는다. 그래서 0131 은 **이 묶음으로만** 간다.
#      🔴 안 풀면 적용이 **0건으로 조용히** 끝나고 겉으로는 성공으로 보인다.
#   🔴 **폴더를 통째로 갈아 끼운다** — 그래서 묶음 안에 창 안 일곱이 .sql 과
#      스냅샷 짝으로 다 들어 있어야 한다(66-build.sh 가 그것을 쟀다).
place_migs() {
  local U B s j t
  if [ ! -f "$MIGTAR" ]; then
    s=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
    if [ "${s:-0}" = "$AS_VOL_SQL_WANT" ]; then
      ok "묶음이 없지만 볼륨이 이미 ${AS_VOL_SQL_WANT}장이다 (이미 풀었다 — 건너뛴다)"; return 0
    fi
    bad "묶음이 없고 볼륨도 ${s:-?}장이다 — $MIGTAR 를 보내세요"; return 1
  fi
  U="$INCOMING/unpack-$STAMP"
  mkdir -p "$U" || { bad "푸는 자리를 못 만들었다"; return 1; }
  if ! tar -xzf "$MIGTAR" -C "$U"; then bad "묶음을 못 풀었다"; return 1; fi
  s=$(ls -1 "$U/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  j=$(grep -o '"idx"' "$U/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  t=$(ls -1 "$U/drizzle/${AS_VOL_THIS}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  printf '    푼 것 — .sql %s장 · idx %s개 · %s %s개 (기대 %s · %s · 1)\n' \
    "${s:-?}" "${j:-?}" "$AS_VOL_THIS" "${t:-?}" "$AS_VOL_SQL_WANT" "$AS_VOL_SQL_WANT"
  if [ "${s:-x}" != "$AS_VOL_SQL_WANT" ] || [ "${j:-x}" != "$AS_VOL_SQL_WANT" ] || [ "${t:-0}" != "1" ]; then
    bad "푼 것이 기대와 다르다 — **볼륨을 안 건드렸다**"
    say "      🔴 목록에 없는 .sql 은 drizzle 이 **아예 모릅니다**(적용이 0건으로 끝납니다)."
    say "      🔴 **옛 판의 묶음일 수 있습니다**(128·129·131장짜리). 3-ㄴ 을 보세요."
    return 1
  fi
  B="$D/backups/as-migrations-$DUMP_VER-$STAMP"
  if cp -a "$MIGDIR" "$B" 2>/dev/null; then ok "옛 볼륨을 치워 두었다 — $B"
  else hm "옛 볼륨 사본을 못 떴습니다 — 그래도 진행합니다(덤프가 있습니다)"; fi
  if ! cp -a "$U/drizzle/." "$MIGDIR/"; then bad "볼륨에 못 넣었다"; return 1; fi
  s=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  j=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  t=$(ls -1 "$MIGDIR/${AS_VOL_THIS}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  printf '    볼륨 — .sql %s장 · idx %s개 · %s %s개 (기대 %s · %s · 1)\n' \
    "${s:-?}" "${j:-?}" "$AS_VOL_THIS" "${t:-?}" "$AS_VOL_SQL_WANT" "$AS_VOL_SQL_WANT"
  if [ "${s:-x}" = "$AS_VOL_SQL_WANT" ] && [ "${j:-x}" = "$AS_VOL_SQL_WANT" ] && [ "${t:-0}" = "1" ]; then
    ok "볼륨이 **${AS_VOL_SQL_WANT}장**이 됐다 ($AS_VOL_THIS 이 들어왔다)"
    rm -rf "$U" 2>/dev/null
    return 0
  fi
  bad "볼륨이 .sql ${s:-?} · idx ${j:-?} · $AS_VOL_THIS ${t:-?} 다 — ${AS_VOL_SQL_WANT} 을 기대했다"
  return 1
}

# ══════════════════════════════════════════════════════════════════════
# ── 6. --migrate : 🔴 **여기서 DB 가 바뀐다** (A/S 한 집 · 한 건) ────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--migrate" ]; then
  step "6. --migrate — 🔴 **여기서 DB 가 바뀐다** (A/S 한 집 · 한 건)"
  say "🔴 65·64·63 번에는 이 자리가 **--tools** 였습니다(마이그레이션 0건이라)."
  say "   이번 판은 62번의 --migrate 를 가져왔습니다 — 다만 62번은 **네 집 일곱 건**"
  say "   이었고 이번은 **A/S 한 집 한 건**이라 고리가 한 바퀴만 돕니다."
  say "🔴 차례가 **뜻을 갖습니다**: 덤프 → compose 사본 → **묶음을 볼륨에 푼다** →"
  say "   도구 태그를 간다 → db:preflight → db:migrate → **수를 다시 센다.**"
  say "   🔴 묶음을 안 풀면 적용이 **0건으로 조용히** 끝납니다(31·39번)."
  say "   🔴 도구 태그를 안 갈면 **옛 스키마**로 돕니다."
  say "🔵 **다시 돌려도 안전합니다** — drizzle 은 이미 적용한 것을 건너뜁니다."
  if [ "$DBPHASE" = "DONE" ] && [ "$PHASE_TOOL_NEW" = "$TOOLS_WANT" ]; then
    ok "DB 가 이미 $AS_VOL_SQL_WANT 이고 도구도 새 판이다 — 바꿀 것이 없다"
    printf '\n%s\n' "✅ 할 일이 없습니다. 다음은 --go 입니다."
    exit 0
  fi

  say ""
  say "── 6-ㄱ. 🔴 되돌릴 길부터 만든다 — **덤프 한 장**(dss_as)"
  say "🔴 **이번 판은 DB 가 실제로 바뀝니다**(65번은 안 바뀌었습니다) — 이 덤프가"
  say "   되돌릴 **유일한 길**입니다."
  if ! make_dump; then stop "덤프를 못 떴습니다 — **아무것도 안 바꿨습니다.** 되돌릴 길부터 만드세요."; fi

  say ""
  say "── 6-ㄴ. compose 사본"
  backup_compose

  say ""
  say "── 6-ㄷ. 🔴 **A/S 마이그레이션 볼륨** — 묶음을 푼다 ($AS_VOL_SQL_WAS → $AS_VOL_SQL_WANT)"
  say "🔴 A/S 만 그렇습니다 — 도구 이미지 안의 /app/drizzle 은 비어 있고 그 자리에"
  say "   /volume1/dss/as-migrations 가 붙습니다."
  if ! place_migs; then stop "볼륨을 못 올렸습니다 — DB 는 한 글자도 안 바꿨습니다."; fi

  say ""
  say "── 6-ㄹ. 🔴 **도구 태그 한 줄을 간다**"
  say "🔴 **db:migrate 는 새 도구로 돌려야 합니다** — 옛 도구는 fault_tags 칸을 모르는"
  say "   스키마를 들고 있습니다. 62번도 같은 차례였습니다(태그 먼저 · migrate 나중)."
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
  say "── 6-ㅁ. 🔴 **적용 전 확인** — db:preflight 를 값으로 받는다"
  say "🔴 **기대값이 「대기 1건」입니다**(65번은 0건이었습니다). 0건이면 볼륨을 안"
  say "   풀었거나 이미 올린 것이고, 2건 이상이면 누가 .sql 을 더 넣은 것입니다."
  say "🔵 db:preflight 는 **읽기만 합니다**(Dockerfile 85~87줄의 기본 명령입니다)."
  say "🔴 여기서 **Cannot find module** 이 보이면 도구 이미지에 담긴 것이 모자랍니다."
  # 🔴 서비스 이름을 **여기 다시 적지 않는다** — TOOLS 표에서 꺼낸다.
  #    두 곳에 적으면 표를 고친 날 한 곳만 바뀌고, 그때 나는 오류는
  #    「서비스를 못 찾았다」라 **도구 이미지 탓처럼 보인다.**
  PFSVC=$(field "$(row_by_key "$TOOLS" astools)" 2)
  if [ -z "${PFSVC:-}" ]; then
    bad "TOOLS 표에서 astools 의 서비스 이름을 못 꺼냈다 — 표가 깨졌다"
    stop "DB 는 한 글자도 안 바꿨습니다. 앱도 안 건드렸습니다."
  fi
  say "도구 서비스: $PFSVC (TOOLS 표에서 꺼낸 값입니다)"
  dct run --rm "$PFSVC" npm run db:preflight 2>&1 | sed 's/^/      /'
  PRC=${PIPESTATUS[0]}
  say "(종료 코드 $PRC — 기대 0)"
  if [ "$PRC" = "0" ]; then
    ok "새 도구가 db:preflight 를 끝까지 돌았다 (import 가 닫혀 있다)"
    say "      🔴 위 글에 **대기 건수**가 적혀 있습니다. **1건이어야 합니다**(0131) —"
    say "         0 이면 볼륨을 안 풀었거나 이미 올린 것이고, 2 이상이면 **멈추고 알리세요.**"
    say "      🔵 0131 은 **칸 하나를 더하기만** 합니다 — 사라질 자료가 없습니다."
  else
    bad "db:preflight 가 0 이 아니다 ($PRC)"
    say "      🔴 **Cannot find module 이 보이면** 도구 이미지에 담긴 것이 모자랍니다"
    say "         (vendor/dss-core 나 src/ 가 빠진 것입니다)."
    say "      🔴 그 밖이면 **볼륨에 사라질 자료가 있다는 뜻**입니다 — 0131 에는 그럴"
    say "         문장이 없으니 **다른 것이 섞였습니다.**"
    say "      🔵 **도구 줄과 볼륨은 이미 갈았습니다.** 되돌리려면 compose 사본: $BK"
    stop "DB 는 아직 한 글자도 안 바꿨습니다. 앱도 안 건드렸습니다."
  fi

  say ""
  say "── 6-ㅂ. 🔴🔴 **db:migrate 를 돌린다 — 여기서 DB 가 바뀐다**"
  MIG_RAN=0; MIG_SEEN2=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    K=$(field "$r" 1); BOX=$(field "$r" 2); DB=$(field "$r" 3)
    BEF=$(field "$r" 4); AFT=$(field "$r" 5); CMDN=$(field "$r" 6); NAME=$(field "$r" 8)
    tr2=$(row_by_key "$TOOLS" "${K}tools"); SVC=$(field "$tr2" 2)
    MIG_SEEN2=$((MIG_SEEN2+1))
    printf '\n    ── %s (%s · %s)\n' "$NAME" "$DB" "$SVC"
    if [ -z "${SVC:-}" ]; then
      bad "$NAME — TOOLS 표에서 ${K}tools 의 서비스 이름을 못 꺼냈다. 표가 깨졌다"
      stop "DB 는 한 글자도 안 바꿨습니다."
    fi
    v=$(mig_count "$BOX" "$DB")
    if [ "${v:-x}" = "$AFT" ]; then ok "$NAME 가 이미 $AFT 다 (건너뛴다)"; MIG_RAN=$((MIG_RAN+1)); continue; fi
    if [ "${v:-x}" != "$BEF" ]; then
      bad "$NAME 가 ${v:-?} 다 — $BEF 를 기대했다. **돌리지 않습니다**"
      stop "DB 는 한 글자도 안 바꿨습니다. 위 수를 보고 사람이 판단하세요. 덤프: $BKDB"
    fi
    dct run --rm "$SVC" npm run "$CMDN" 2>&1 | sed 's/^/      /'
    RC=${PIPESTATUS[0]}
    if [ "$RC" = "0" ]; then ok "$NAME $CMDN 끝 (종료 코드 0)"
    else
      bad "$NAME $CMDN 실패 (종료 코드 $RC)"
      say "      🔴 **db:migrate 는 오류를 삼키고 exit 1 만 남기는 성질이 있습니다** —"
      say "         위 글에 까닭이 안 보일 수 있습니다. 아래 수 세기로 어디까지 갔는지 봅니다."
      say "      🔵 덤프: $BKDB · compose 사본: $BK · 옛 볼륨 사본: $D/backups/as-migrations-$DUMP_VER-$STAMP"
      stop "앱은 한 줄도 안 건드렸습니다."
    fi
    # 🔴🔴 **수를 다시 센다** — 「종료 코드 0」만으로 끝내지 않는다.
    #    db:migrate 가 오류를 삼키면 0 을 돌려주고도 아무것도 안 올렸을 수 있다.
    v=$(mig_count "$BOX" "$DB")
    if [ "${v:-x}" = "$AFT" ]; then ok "$NAME 가 **${AFT} 가 됐다** (전 ${BEF})"; MIG_RAN=$((MIG_RAN+1))
    else
      bad "$NAME 가 ${v:-?} 다 — $AFT 를 기대했다. 🔴 **종료 코드는 0 인데 안 올라갔습니다**"
      doubt
      stop "덤프: $BKDB · 앱은 한 줄도 안 건드렸습니다."
    fi
  done <<ENDMIGRUN
$(rows_of "$MIGS")
ENDMIGRUN
  printf '\n  돌린 집 %s / %s (본 줄 %s)\n' "$MIG_RAN" "$MIGS_WANT" "$MIG_SEEN2"
  [ "$MIG_SEEN2" = "$MIGS_WANT" ] && ok "집 ${MIGS_WANT}곳을 다 돌았다 (표본이 비지 않았다)" \
    || bad "집을 ${MIG_SEEN2}곳만 돌았다 — MIGS 표가 깨졌다"
  if [ "$MIG_RAN" != "$MIGS_WANT" ]; then stop "다 못 올렸습니다. 덤프: $BKDB"; fi

  say ""
  say "── 6-ㅅ. 🔴 **값으로 확인한다** — 칸이 실제로 생겼는가"
  say "🔴 「마이그레이션 수가 늘었다」와 「칸이 생겼다」는 **다른 말**입니다 —"
  say "   둘을 따로 재야 합니다. 🔴 꼴(${NEWCOL_TYPE})과 NULL 허용까지 봅니다."
  n=$(has_column "$NEWCOL_BOX" "$NEWCOL_DB" "$NEWCOL_TABLE" "$NEWCOL_NAME")
  t=""; u=""
  if [ "${n:-0}" = "1" ]; then
    t=$(col_type "$NEWCOL_BOX" "$NEWCOL_DB" "$NEWCOL_TABLE" "$NEWCOL_NAME")
    u=$(col_null "$NEWCOL_BOX" "$NEWCOL_DB" "$NEWCOL_TABLE" "$NEWCOL_NAME")
  fi
  printf '      %s.%s — 있나 %s (기대 1) · 자료형 %s (기대 %s) · NULL 허용 %s (기대 %s)\n' \
    "$NEWCOL_TABLE" "$NEWCOL_NAME" "${n:-?}" "${t:-–}" "$NEWCOL_TYPE" "${u:-–}" "$NEWCOL_NULLABLE"
  if [ "${n:-0}" != "1" ]; then
    bad "그 칸이 **안 생겼다** — 🔴 수는 늘었는데 칸이 없습니다. 멈추고 알릴 것"
    doubt
  elif [ "${t:-x}" = "$NEWCOL_TYPE" ] && [ "${u:-x}" = "$NEWCOL_NULLABLE" ]; then
    ok "**${NEWCOL_TABLE}.${NEWCOL_NAME} 이 ${NEWCOL_TYPE} · NULL 허용으로 생겼다** (이 배포의 목적물이다)"
    say "      🔵 **값은 아직 전부 NULL 입니다** — 0131 에 INSERT 도 UPDATE 도 없습니다."
  else
    bad "그 칸이 ${t:-?} · NULL 허용 ${u:-?} 다 — ${NEWCOL_TYPE} · ${NEWCOL_NULLABLE} 를 기대했다"
    doubt
  fi
  # 🔴 **자료가 안 바뀌었는가** — 칸을 더하는 판이라 줄 수가 그대로여야 한다.
  rowsn=$(table_rows "$NEWCOL_BOX" "$NEWCOL_DB" "$NEWCOL_TABLE")
  printf '      %s 줄 수: %s (🔵 이 배포는 줄을 더하거나 지우지 않는다)\n' "$NEWCOL_TABLE" "${rowsn:-?}"
  [ -n "${rowsn:-}" ] && ok "표의 줄 수를 값으로 읽었다 (${rowsn}줄)" \
    || unk "$NEWCOL_TABLE 줄 수" "못 쟀다 — 사람이 보세요"

  say ""
  say "── 6-ㅇ. 🔴 **안 바뀌어야 하는 네 집** — 다시 센다"
  say "🔴 이 모드는 **A/S 한 집에만** 썼습니다. 나머지 넷이 그대로인지 값으로 보입니다."
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
    && ok "네 집의 마이그레이션 수가 **그대로다** (옆으로 안 샜다)" \
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
  printf '\n%s\n' "✅ A/S 의 DB 가 $AS_VOL_SQL_WAS → $AS_VOL_SQL_WANT 로 올라갔고 도구가 새 판을 가리킵니다."
  printf '%s\n' "   🔵 **앱은 아직 옛 판입니다** — 직원이 보는 화면은 그대로입니다."
  printf '%s\n' "   🔵 옛 앱은 새 칸을 **쳐다보지도 않습니다**(읽는 코드가 없습니다)."
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
  # 🔴 **기대값이 단계로 갈린다** — --go 는 적용 뒤(132)이고, --rollback 은 적용 뒤든
  #    전이든 올 수 있다. 그래서 **부르는 쪽이 기대값을 넘긴다.**
  #    🔵 65번은 여기에 131 이 **박혀 있었다** — 이번 판에 그 수가 움직이므로
  #       박아 두면 --go 가 영영 못 지나간다.
  v=$(mig_count dss-pg-app dss_as)
  printf '      dss-pg-app 이 **답하는가**: dss_as 마이그레이션 수 %s (기대 %s)\n' "${v:-못 읽음}" "${1:-$AS_VOL_SQL_WANT}"
  if [ "${v:-x}" != "${1:-$AS_VOL_SQL_WANT}" ]; then
    bad "dss-pg-app 이 답을 안 하거나 수가 다르다 (${v:-못 읽음})"
    say "      🔴 **「도는가」만 보면 안에서 죽은 DB 를 못 가릅니다** — 그래서 값을 받습니다."
    return 1
  fi
  ok "dss-pg-app 이 **실제로 답한다** (dss_as ${v})"
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

  # 🔴 관문 ① — 🔴 **DB 가 올라갔는가**(65번은 「안 바뀌었는가」였다 — 뜻이 반대다)
  if [ "$DBPHASE" != "DONE" ]; then
    bad "DB 단계가 $DBPHASE 다 — DONE 이어야 한다 (dss_as 가 $AS_VOL_SQL_WANT 여야 한다)"
    say "      🔴 **새 앱은 ${NEWCOL_TABLE}.${NEWCOL_NAME} 칸을 읽고 씁니다** — 칸이 없으면"
    say "         진단 Flowchart 화면이 **42703(칸 없음)** 으로 터집니다."
    say "      🔴 먼저 --migrate 를 돌리세요."
    stop "**아무것도 안 바꿨습니다.** 사람이 보세요."
  fi
  ok "A/S 의 DB 가 $AS_VOL_SQL_WANT 다 (--migrate 가 돌았다)"
  # 🔴 관문 ①-2 — **칸이 실제로 있는가.** 수만 믿지 않는다.
  n=$(has_column "$NEWCOL_BOX" "$NEWCOL_DB" "$NEWCOL_TABLE" "$NEWCOL_NAME")
  if [ "${n:-0}" != "1" ]; then
    bad "${NEWCOL_TABLE}.${NEWCOL_NAME} 칸이 **없다**(${n:-못 읽음}) — 수는 맞는데 칸이 없습니다"
    say "      🔴 **수가 늘었다고 칸이 생긴 것이 아닙니다.** 멈추고 사람이 보세요."
    stop "**아무것도 안 바꿨습니다.**"
  fi
  ok "${NEWCOL_TABLE}.${NEWCOL_NAME} 칸이 실제로 있다 (새 앱이 쓸 자리가 있다)"
  # 🔴 관문 ①-3 — **안 바뀌어야 하는 네 집**이 그대로인가
  if [ "$DBKEEP" != "KEEP" ]; then
    bad "안 바뀌는 네 집의 상태가 $DBKEEP 다 — KEEP 이어야 한다"
    say "      🔴 재고 28 · 휴가 5 · 포털 11 · 계측기 3 이 아닙니다."
    say "         이 배포본은 **A/S 한 집에만** 1건을 올립니다 — 다른 집의 수가"
    say "         달라졌다면 **이 배포와 무관한 다른 사고**입니다."
    stop "**아무것도 안 바꿨습니다.** 사람이 보세요."
  fi
  ok "안 바뀌는 네 집이 전과 같다"

  # 🔴 관문 ② — 도구가 새 판인가(--migrate 가 돌았는가)
  if [ "$PHASE_TOOL_NEW" != "$TOOLS_WANT" ]; then
    bad "도구가 ${PHASE_TOOL_NEW}/${TOOLS_WANT} 만 새 판이다 — --migrate 가 안 돌았다"
    say "      🔴 --migrate 가 **덤프를 뜨고** · **묶음을 볼륨에 풀고** · 새 도구로"
    say "         **db:migrate 를 돌립니다.** 그 셋을 건너뛰지 마세요."
    stop "먼저 --migrate 를 돌리세요. **아무것도 안 바꿨습니다.**"
  fi
  ok "도구가 새 판이다 (--migrate 가 돌았다 — 덤프·묶음·migrate 가 끝났다)"

  # 🔴 관문 ③ — **--no-deps 를 쓰므로 DB 를 직접 잰다**
  #    🔴 기대값을 **넘긴다** — 이번 판은 그 수가 움직이므로 박아 두면 안 된다.
  say ""
  if ! go_gate "$AS_VOL_SQL_WANT"; then stop "**아무것도 안 바꿨습니다.** DB 부터 보세요."; fi

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
      say "      🔵 **DB 는 그대로 둡니다** — 0131 은 칸을 **더하기만** 했으므로 옛 앱은"
      say "         그 칸을 쳐다보지도 않습니다(읽는 코드가 없습니다)."
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
  printf '%s\n' "🔴 **배포 뒤에 눈으로 볼 곳 — [진단 Flowchart] 의 고장 개소 태그입니다**"
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "  🔵 **아무 수리 건의 [진단 Flowchart] 를 하나 열고** 편집기로 들어가세요."
  printf '%s\n' "  ① 🔴 **고장 개소 태그 칸**이 있어야 합니다. 칸에 글을 치면 **그 글로"
  printf '%s\n' "     좁혀진 후보 목록**이 바로 아래 뜹니다(부품 검색과 같은 모양입니다)."
  printf '%s\n' "     🔵 칸이 아예 없으면 **옛 판**입니다."
  printf '%s\n' "  ② 🔴 **후보를 눌러서 더해지는지** 보세요 — 눌리지 않으면 목록이 먼저"
  printf '%s\n' "     닫히는 결함입니다. **Enter 로도 더해져야** 합니다(새 태그 만들기)."
  printf '%s\n' "  ③ 🔴 **이미 단 태그는 후보에 안 보여야** 합니다. 알약의 **✕ 로 빠져야**"
  printf '%s\n' "     하고, Escape 로 목록이 닫혀야 합니다."
  printf '%s\n' "  ④ 🔴 **저장 단추가 눌려야** 합니다 — 태그만 고쳤는데 단추가 죽어 있으면"
  printf '%s\n' "     **적어 놓고도 못 저장**합니다(오류는 한 줄도 안 납니다)."
  printf '%s\n' "     🔵 단추 글자는 **「저장」**입니다(옛 글자 「제목/설명 저장」이 아닙니다)."
  printf '%s\n' "  ⑤ 🔴 **[진단 Flowchart 관리] 에서 그 태그로 찾아지는지** 보세요."
  printf '%s\n' "     🔴 **# 를 붙여 쳐도 찾아져야** 합니다(「#우내」). 🔴 **휴지통 탭에서도**"
  printf '%s\n' "        같은 글자로 찾아져야 합니다 — 거르는 함수가 둘이라 반쪽이 되기 쉽습니다."
  printf '%s\n' "  ⑥ 🔴 **알약은 줄에 3개까지**고 나머지는 **+N** 입니다. +N 을 누르면"
  printf '%s\n' "     **떠 있는 메모**로 뜨고 — 🔴 **표 폭이 변하면 안 됩니다**(그게 이"
  printf '%s\n' "     변경의 목적입니다). 창을 좁혀 **카드로 바뀐 뒤에도** 같아야 합니다."
  printf '%s\n' "  ⑦ 🔵 **찾는 글에 걸린 태그는 상한을 넘겨서라도 줄에 섭니다** — 넷째 태그로"
  printf '%s\n' "     찾았는데 안 보이면 「검색이 고장 났다」로 읽힙니다."
  printf '%s\n' "  ⑧ 🔵 **태그를 아직 아무도 안 달았으면 알약이 한 개도 안 보이는 것이"
  printf '%s\n' "     정상입니다** — --count 의 ⓪ 가 0건으로 나옵니다."
  printf '%s\n' "  ⑨ 🔵 **어제 것이 그대로 있는지도 보세요**(뒷걸음 눈 확인) —"
  printf '%s\n' "     [내자 정리]의 [상태] 드롭다운이 **동그라미(단독 선택)** 그대로이고"
  printf '%s\n' "     맨 위에 「전체」 한 줄이 있으며, [고객사]는 **네모 체크(복수)** 입니다."
  printf '%s\n' ""
  printf '%s\n' "🔴 **다음에 할 일 둘** (아직 그대로입니다)"
  printf '%s\n' "  ㄱ) 06-notify-install.sh 에 **IMAGE=dss-meters-tools:1** 이 박혀 있습니다."
  printf '%s\n' "     지금 운영은 dss-meters-tools:2 입니다 — 그 파일을 다시 돌리는 사람이"
  printf '%s\n' "     **옛 태그를 싣습니다.** 2 로 고쳐 두세요."
  printf '%s\n' "  ㄴ) 🔴 **PO 가 모르는 것이 넷**입니다. PO 를 다시 여는 날 넷을 한 묶음으로"
  printf '%s\n' "     이식하세요(머리말). 🔵 이번 판이 거기에 더한 것은 **없습니다** —"
  printf '%s\n' "     PO 는 repair_case_flowcharts 를 쓰지 않습니다."
  printf '%s\n' ""
  printf '%s\n' "🔴 **되돌리기**: bash $0 --rollback  (앱 하나만 되돌립니다)"
  printf '%s\n' "   🔵 도구는 새 판 그대로 둡니다."
  printf '%s\n' "   🔴 **DB 는 자동으로 안 되돌립니다** — 0131 은 칸을 **더하기만** 했으므로"
  printf '%s\n' "      옛 앱은 그 칸을 쳐다보지도 않습니다."
  printf '%s\n' "   🔵 덤프: $BKDB · compose 사본: $BK"
  printf '%s\n' "  다음: bash $0 --count  ← 올린 뒤 수를 재어 앞의 수와 맞대세요"
  printf '%s\n' "        🔴 내자 정리 수는 **같은 수가 나오는 것이 정상**입니다."
  printf '%s\n' "        🔵 ⓪절은 올리기 전 「칸이 없다」에서 **0건 · 0가지**로 바뀝니다."
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════
# ── 8. --rollback : 앱 하나만 되돌린다 ──────────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--rollback" ]; then
  step "8. --rollback — 앱 하나를 옛 태그로 되돌린다"
  say "🔵 **도구는 새 판 그대로 둡니다**(39·41~65번과 같은 판단) — profiles: [tools]"
  say "   라 평소에 뜨지 않고, 옛 앱이 도구를 부르는 일도 없습니다."
  say "🔴 **DB 는 자동으로 안 되돌립니다** — 0131 은 **칸을 더하기만** 했으므로 옛 앱은"
  say "   그 칸을 쳐다보지도 않습니다(읽는 코드가 없습니다). 덤프: $BKDB"
  say "🔴 **--no-deps 로 띄웁니다** — 되돌릴 때도 DB 를 Recreate 하면 안 됩니다."
  say ""
  # 🔴 **기대값을 지금 값으로 넘긴다** — --rollback 은 적용 뒤에도 전에도 올 수 있다.
  #    여기서 재는 것은 「수가 맞는가」가 아니라 **「DB 가 실제로 답하는가」**다.
  RBWANT=$(mig_count dss-pg-app dss_as)
  if [ -z "${RBWANT:-}" ]; then
    bad "dss-pg-app 에서 dss_as 마이그레이션 수를 못 읽었다"
    stop "**아무것도 안 바꿨습니다.** DB 부터 보세요."
  fi
  say "지금 dss_as 는 ${RBWANT} 입니다 (${AS_VOL_SQL_WAS} 면 --migrate 전 · ${AS_VOL_SQL_WANT} 면 뒤입니다)"
  if ! go_gate "$RBWANT"; then stop "**아무것도 안 바꿨습니다.** DB 부터 보세요."; fi
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
  printf '%s\n' "   🔴 **1절의 단계는 MID 로 보입니다** — --migrate 만 돌린 상태와 같은 모양입니다."
  printf '%s\n' "      🔵 DB 로는 「--migrate 를 돌았는가」까지만 갈립니다($AS_VOL_SQL_WAS / $AS_VOL_SQL_WANT) —"
  printf '%s\n' "      「--migrate 직후」와 「--go 뒤 --rollback」은 DB 가 같습니다."
  printf '%s\n' "      가르려면 **로그 파일 이름**(deploy62-go-… / deploy62-rollback-…)을 보세요."
  printf '%s\n' "   🔴 **DB 는 그대로 둡니다** — 되돌리고 싶으면 덤프로 사람이 합니다: $BKDB"
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi
