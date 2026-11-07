#!/bin/bash
# dss-deploy/nas/setup/53-deploy.sh — 쉰째 배포 (2026-11-07)
#
# 🔴 NAS 에서 돈다. **DSM 터미널은 긴 명령을 잘라 먹는다**(2026-10-12 하루에 네
#    번 깨졌다). 그래서 손으로 치지 않고 **파일로 올려** 돌린다. 절차는 이렇다:
#      ① (개발 PC · PowerShell) — 🔴 **경로는 빗금으로**
#           cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#           scp -O 53-deploy.sh dss-nas:/volume1/dss/setup/
#           Get-FileHash -Algorithm MD5 53-deploy.sh
#      ② (NAS) md5sum /volume1/dss/setup/53-deploy.sh
#      ③ 🔴 **두 md5 가 같은지 눈으로 맞댄다.** 다르면 옮기다 잘린 것이다 —
#         그대로 돌리면 중간에서 끊긴 스크립트가 compose 를 고치다 만다.
#      🔵 이 파일은 돌 때 맨 위에서 **제 md5 를 스스로 찍는다.**
#    🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#    🔴 **역슬래시 경로를 쓰지 마라.** bash 와 scp 가 그 역슬래시를 먹어
#       "C:Users희만Desktop…" 가 된다. 🔵 51-deploy.sh 에는 아직 역슬래시 예시가
#       남아 있다(그 파일 6~9줄 · 1152줄 · 1333줄). **거기서 베껴 오지 마라.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이번 판은 **52번과 모양이 다르다** — 셋이 다르다
# ══════════════════════════════════════════════════════════════════════
#   ① **포털(dss-auth)도 갈아 끼운다.** 40~52번은 A/S 만 건드렸다. 포털을 마지막
#      으로 갈아 끼운 것은 **39-deploy.sh**(2026-10-27)이고 **14판 전**이다.
#      🔴 그래서 52번의 KEEP_BOXES 에서 **dss-auth 를 뺐다.** 🔴 **빼는 것만으로는
#         모자라다** — 그 목록은 「안 건드린 상자가 그대로 도는가」를 세는 자리라,
#         빼기만 하면 **아무도 포털이 다시 떴는지 안 본다.** 그래서 포털을
#         **SITES(다시 띄우는 표)에 넣었다.** 7절이 상태·이미지·응답을 값으로 잰다.
#   ② **마이그레이션이 1건이다 — 0124.** 52번은 0건이었다. 🔴 그래서
#      **as-migrations.tar.gz 를 반드시 받아야** 하고, 기대값이 **앞 124 · 뒤 125**
#      로 **두 갈래**다. 🔵 52번은 한 갈래(124)였다 — 그 글을 베껴 오면
#      「124 여도 ✓」가 되어 **적용이 0건으로 끝난 것을 못 잡는다.**
#   ③ **갈아 끼우는 태그가 넷이다** — 앱 둘 · 도구 둘. 52번은 둘이었다.
#      🔴 그래서 **달라질 image: 줄 수를 박지 않고 세어서 정한다.**
#
#   갈아 끼우는 것 — **저장소 둘, 태그 넷**
#     ① A/S 앱    dss-as:4.5        → **dss-as:4.6**
#     ② A/S 도구  dss-as-tools:12   → **dss-as-tools:13**
#     ③ 포털 앱   dss-auth:2.0      → **dss-auth:2.1**
#     ④ 포털 도구 dss-auth-tools:3  → **dss-auth-tools:4**
#
#   🔴 **PO 는 안 건드린다.** dss-po 의 HEAD 가 기준 SHA(9c1b2ef) 그대로라 구울
#      것이 없다(2026-11-07 실측 — 53-build.sh 2절). dss-po:0.9 가 그대로 돈다.
#   🔵 **나머지 여덟도 안 건드린다** — 재고 · 게시판 · 계측기 · 개선요청 ·
#      RF 이슈관리 · 휴가 · 통합 승인함 · PO.
#   🔵 **양식(.xlsx)은 한 장도 안 올린다.** 이번 범위에 .xlsx 변경이 0줄이고
#      개발 PC 의 양식 열하나가 52번 값 그대로다. 그래서 이 파일에는
#      **--templates-prep 와 --templates-apply 가 없다.**
#      🔴 **양식이 바뀌는 날 되살릴 곳**: 51-deploy.sh 의 1056~1172줄
#         (--templates-prep) · 1174~1341줄(--templates-apply) · 61~74줄(머리말).
#      🔵 다만 **재는 쪽은 남겼다** — 1-ㄷ 절이 운영 양식 열하나를 md5 로 재고,
#         앱이 그것을 읽는지 설정 이름으로 묻는다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 마이그레이션 0124 — 무엇이 늘고, 무엇을 값으로 확인하는가
# ══════════════════════════════════════════════════════════════════════
#   기록: **124 → 125**. 볼륨: **124 → 125**(묶음을 풀어서).
#   더하는 것:
#     · enum 값 둘   repair_case_approval_type / shipment_approval_route_scope 에
#                    'DOMESTIC_ORDER_FINAL_SHIPMENT'
#     · 칸 하나      repair_case_approvals.domestic_order_id (uuid · NULL 허용)
#     · 외래키 하나  → domestic_orders.id  **ON DELETE set null**
#     · 인덱스 둘    …_one_active_domestic_request(유니크·부분) · …_domestic_order_id_idx
#     · CHECK 넷     둘은 **새로** · 둘은 **뗐다가 넓혀 다시**
#   🔴 **지우는 문장은 0건이다.** ON DELETE set null 도 DROP CONSTRAINT 도
#      앱의 migration-safety(findDestructiveOperations)가 **안 센다**. 19번이 그
#      자리에서 넘어졌으므로 그 잣대를 글자 그대로 가져왔다(아래 DESTRUCTIVE_RE).
#   🔵 앱의 db:preflight 는 이 판을 **「자료는 그대로지만 살펴볼 문장 2건」**으로
#      통과시킨다 — 그 갈래는 **종료 코드에 관여하지 않는다**(그쪽 187줄).
#      🔴 그러니 **종료 코드 0 을 「살펴볼 것이 없다」로 읽지 마라.**
#   🔴 **drizzle 은 밀린 것을 한 트랜잭션에 넣는다.** 이 판은 새 enum 값을 더하는데
#      CHECK 을 approval_type::text 로 적은 덕에 같은 트랜잭션에서 통과한다.
#      🔴 **drizzle-kit migrate 는 오류를 삼키고 종료 코드만 남길 수 있다.** 그래서
#      이 파일은 **종료 코드만 보고 「성공」이라 말하지 않는다** — 적용 뒤 DB 를
#      다시 읽어 **enum 둘 · 칸 하나 · 인덱스 둘 · 제약 넷**을 값으로 센다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 배포 뒤 **사람이 해야 하는 일 둘** — 꼬리말이 다시 찍는다
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 [사용자 관리] › [승인 절차] 에서 **「기타건 최종 출하 승인」 결재선을
#      한 판 세운다.** 🔴 **안 세우면 기타건을 아무도 [완료] 처리할 수 없다.**
#      🔵 --count 가 그 판의 수를 **값으로** 찍는다(처음엔 0 이 맞다).
#   ② 포털 관리자 화면 › 결재 알림 메일 에서 **「기타건 최종 출하 결재」 스위치**.
#      🔵 안 켜도 종과 통합 승인함은 뜬다. 메일만 안 간다(기본값 끔 — 2026-10-23).
#      🔵 --count 가 approval_mail_kinds 에서 그 줄을 **값으로** 찍는다.
#
# ── 🔴 알고도 안 고친 것 — PO 가 새 거절 코드를 모른다 ───────────────
#   이번 판부터 A/S 의 POST /api/v1/domestic-orders/{id}/completion 이
#   **409 APPROVAL_REQUIRED** 를 돌려줄 수 있는데, 운영에 도는 dss-po:0.9 의
#   AS_COMPLETION_REJECT_CODES 에 그 코드가 **없다**(2026-11-07 실측).
#   🔴 PO 에서 기타건을 [완료 처리] 하면 A/S 가 적어 보낸 안내 문장이 **안 뜨고**
#      「모르는 응답」으로 떨어진다. 🔵 **자료는 안 깨진다** — A/S 는 한 글자도 안
#      쓴 채 거절했고, PO 도 「완료되었습니다」라고 말하지 않는다.
#   🔴 **이 배포는 그것을 안 고친다**(PO 를 안 굽는다). 꼬리말에 다시 적는다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **상태 변수를 먼저 정하고 가지를 나눈다** — 48번이 데인 자리다
# ══════════════════════════════════════════════════════════════════════
#   48번에서 --check 의 기대값이 **한 갈래**라 적용 뒤에 다시 부르면 가짜 ✗ 가
#   났다. 그래서 이 파일은 **맨 처음에 운영의 단계(PHASE)를 읽고** 가지를 나눈다.
#   🔴 **이번 판은 갈래가 넷이다**(앱 둘 · 도구 둘). 열여섯 가지를 다 적지 않고
#      **「새 판인 것이 몇이냐」로 센다** — 그러면 표가 안 깨진다.
#     PRE   넷 다 옛 판            → 아직 아무것도 안 갈아 끼웠다
#     MID   도구 둘만 새 판        → --migrate 까지 돌았다
#     POST  넷 다 새 판            → --go 까지 돌았다
#     ODD   그 밖                  → 표를 찍고 사람이 본다 (막지는 않는다)
#   🔴 **마이그레이션 수는 가지를 나눈다 — 이번 판은 두 갈래다**(124 → 125).
#      🔵 52번은 한 갈래(124)였다. 그 글을 베껴 오면 **적용이 0건으로 끝난 것을
#         「✓」로 읽는다.**
#
# ── 🔴 48~52번에서 그대로 가져온 것 ──────────────────────────────────
#   ① **3xx 판정**(grep -qE '200|30[1237]'). A/S 는 307, PO 는 303 으로 로그인에
#      보낸다. 빠뜨리면 **멀쩡한 사이트가 ✗ 로 나온다**(2026-10-30 실측).
#      🔵 포털은 제가 로그인이라 **200** 이 나온다 — 셋을 다 받는다.
#   ② 🔴 **치환 전에 그 줄의 낱말 수가 2 인지 본다.** 줄 끝에 주석이 붙어 있으면
#      **주석의 마지막 낱말**이 태그로 바뀌고 image: 값은 그대로 남는다.
#   ③ 🔴 **달라진 image: 줄 수를 박지 않는다 — 세어서 정한다.**
#   ④ 🔴 **설정 파일 검사**(중복 키 · auto). 값은 한 글자도 안 찍는다.
#   ⑤ 🔵 연락서 폴더 검사 · 재고 관리 통로 검사는 **42~52번 것 그대로다.**
#      🔴 **빼지 않는다** — 한 번 빼면 다시 넣는 사람이 없다.
#   ⑥ 🔵 **--rollback 은 앱만 되돌린다.** 도구 둘은 새 판 그대로 둔다 —
#      39·41~52번과 같은 판단(평소에 뜨지 않는 상자다).
#   ⑦ 🔴 **DB 둘의 StartedAt 을 앞뒤로 비교한다** — 안 멈췄다는 증거다.
#   ⑧ 🔴 **제 md5 를 스스로 찍는다** · **image: 줄을 통째로 찍는다**.
#   ⑨ 🔴 **PO 의 repair_cases 쓰기 권한을 잰다** — PO 를 안 건드려도 잰다.
#
# ── 🔴 52번에서 베꼈다가 **이번 판엔 거짓이라 고친 것** ───────────────
#   · 「마이그레이션 0건 · 어느 단계에서나 124」 → **1건 · 124 → 125**
#   · 「묶음은 안 보내도 된다」 → **반드시 보낸다**(볼륨이 124, 저장소가 125)
#   · KEEP_BOXES 의 dss-auth → **뺐다**(이번에 건드린다). 수도 9 → **8**
#   · 「다시 띄우는 것은 app-as 하나뿐」 → **app-as · app-auth 둘**
#   · 「48번이 올린 표·칸·인덱스 넷이 아직 있는가」 → 그대로 두되, **0124 가
#     만드는 것 아홉**을 **적용 전후로 갈래를 나눠** 새로 센다
#   · 「설정 파일에 더할 이름이 없다 · 늘어난 환경변수는 APPLY 하나」 →
#     **이번 범위에 늘어난 process.env 이름이 0개다**(2026-11-07 실측).
#     🔵 APPLY 는 52번 판에 이미 들어왔고 이번에 안 늘었다.
#   · 「src/app/api 가 0줄 바뀌었다 — PO 와의 계약이 그대로다」 →
#     🔴 **거짓이다.** 일곱 파일이 바뀌었고 **거절 코드가 하나 늘었다**(위).
#
# ── 모드 여섯 ─────────────────────────────────────────────────────────
#   (기본)   --check     아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --count              도구를 **읽기만** 해서 센다 + 후속 작업 둘을 값으로 센다
#   --preload            tar 넷을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --migrate            🔴 **DB 를 바꾼다**(124 → 125) + 덤프 + 도구 태그 둘
#   --go                 compose 의 image: 줄을 바꾸고 앱 둘을 다시 띄운다
#   --rollback           앱 둘만 옛 판으로 되돌린다 (도구는 새 판 그대로)
#
# ── 🔴 --check 도 「아무것도 안 한다」는 아니다 ───────────────────────
#   A/S 와 포털 DB 에 **select** 를 몇 번 보낸다(바꾸는 문장은 없다). 앱 둘의
#   주소에 GET 을 한 번씩 보낸다. 재고 관리 통로에도 **GET 을 한 번** 보낸다.
#   양식 폴더를 **읽는다**(ls 와 md5sum 뿐이다). 도구 이미지가 이미 실려 있으면
#   **안을 보려고 컨테이너를 잠깐 띄웠다 지운다.**
#   「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#   🔴 **바꾸는 모드는 셋뿐이다**: --migrate · --go · --rollback.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 쓴 뒤 grep 으로 세었다.
#   ② 읽기 전용 자리에 콜론 하나와 꺾쇠로 빈 파일을 만들면 NAS 의 ash 가 셸을
#      그 자리에서 끝낸다(2026-10-12 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   🔴 19·20·21번에는 그 둘이 아직 남아 있다. **거기서 베껴 오지 마라.**
#   ③ 🔴 그리고 bash 의 $(( )) 는 0 으로 시작하는 수를 **8진수**로 읽는다 —
#      0124 를 셈에 넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
#   ④ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」
#      같은 안전망을 달면 **하필 바라던 0 에서만** 터진다. 이 파일은 그 꼴을
#      한 군데도 쓰지 않는다 — 셈은 「$( … || true )」 로 받는다.
#
# ── 🔴 비밀값을 찍지 않는다 ───────────────────────────────────────────
#   설정 파일은 **이름이 있는가/없는가**와 **auto 인가**만 본다. PO 권한 검사는
#   DATABASE_URL 에서 **역할 이름만** 꺼낸다. 🔵 **양식 경로는 찍어도 된다** —
#   /templates/… 는 저장소의 compose 사본에 이미 적혀 있는 값이고 비밀이 아니다.
#   🔴 다만 **/templates 밖을 가리키는 값은 안 찍는다.**
#   🔴 그리고 **한글을 HTTP 머리말·argv 에 넣지 않는다** — 넣으면 요청이 아예 안
#      나가고, 그 ✗ 가 진짜 결함처럼 보인다.
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v50-$STAMP
BKDB=$D/backups/db   # 🔴 덤프가 여기 간다 (48·52번과 같은 자리·같은 이름 규칙)

# ══ 이번에 다시 띄우는 것 — 앱 **둘** ═════════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
#   🔴 **포털 줄이 들어왔다.** 52번에는 app-as 하나뿐이었다.
#      🔵 서비스·컨테이너·포트의 출처는 39-deploy.sh 169줄이고, 1절이 운영
#         compose 를 직접 읽어 **다시 잰다** — 그 글을 믿고 쓰지 않는다.
#   🔴 **PO 줄이 없다.** 이번엔 안 갈아 끼운다.
SITES='
as|app-as|dss-as|dss-as:4.6|dss-as:4.5|dss-as-4.6.tar|13000
auth|app-auth|dss-auth|dss-auth:2.1|dss-auth:2.0|dss-auth-2.1.tar|13100
'
SITES_WANT=2
# 🔵 7절의 재고 관리·발주서 검사가 명령을 넣을 상자. 위 표 셋째 칸과 같은 이름이다.
AS_APP_CN=dss-as
AUTH_APP_CN=dss-auth
# 🔴 PO 권한 검사가 명령을 넣을 상자. **이번엔 갈아 끼우지 않지만 잰다.**
PO_APP_CN=dss-po
PO_PORT=13600
PO_WANT_TAG=dss-po:0.9

# ══ 🔴 도구 둘 — **이번에 갈아 끼운다.** up -d 로 다시 띄우지 않는다 ═══
#   🔵 둘 다 profiles: [tools] 라 평소에 뜨지 않는다. 도는 컨테이너는 compose 를
#      읽지 않으므로 이 두 줄을 고쳐도 **직원이 느끼는 것이 없다.**
AS_TOOLS_SVC=tools-as
AS_TOOLS_OLD=dss-as-tools:12
AS_TOOLS_NEW=dss-as-tools:13
AUTH_TOOLS_SVC=tools-auth
AUTH_TOOLS_OLD=dss-auth-tools:3
AUTH_TOOLS_NEW=dss-auth-tools:4
IMG_MIGDIR=/app/drizzle
MIGDIR=$D/as-migrations

# ══ 🔴 양식 — **올릴 것이 없다. 재기만 한다** ═════════════════════════
#   🔵 운영 자리: compose 의 app-as·app-po 가 둘 다
#      '/volume1/dss/as-templates:/templates:ro' 로 붙인다.
#   🔴 **tools-as 에는 그 볼륨이 없다.** 그래서 양식은 **호스트에서 바로** 재고,
#      「앱이 보는가」는 app-as 안에서 따로 묻는다.
TPLDIR=$D/as-templates
TPL_IN_CONTAINER=/templates

# 🔴 열하나 — 이름|바이트|md5. 출처: [실측] 2026-11-07 개발 PC.
#    🔵 **52번이 적어 둔 값과 글자 그대로 같았다**(바이트도 md5 도 열하나 전부).
#    🔴 운영 것이 이 값과 달라도 **✗ 를 내지 않는다** — 운영 양식이 개발 PC 것과
#       꼭 같아야 한다는 보증이 어디에도 없다(도장·계좌번호가 든 파일이라 저장소에
#       없고, 운영에서 따로 고쳤을 수 있다). 다르면 **사람이 보라는 뜻**이다.
#    🔴 반대로 **설정이 가리키는데 파일이 없으면 ✗ 다** — 그 출력이 통째로 죽는다.
TPL_ALL='
내자견적서.xlsx|85942|981edf1f1d4a1b4bf2747167c41149d5
제너레이터 OH 견적서.xlsx|62101|4ef6d9dc75f797efb7088b43e9b4c3f9
매쳐 내자 견적서.xlsx|40079|a9f1f7e75e2ac718d86c288efec41d43
매쳐 OH 견적서.xlsx|40664|fc4ee94678b99e5c7b60ca7d1fd94c57
케이블 견적서.xlsx|50996|5450deb6182ccf4c76c2c7ea14b143d8
수리보고서.xlsx|190710|403b642d7c700a118ee515e20e4d659e
검사보고서.xlsx|190589|f7dd2fe0dbf03e6a44fa48a00ee4413e
수리보고서_매쳐.xlsx|191911|ab25c06be1799952e593c2eef810885e
검사보고서_매쳐.xlsx|191929|5701e075c3aac71f63d29fe28ed68e0f
수리보고서_제너레이터.xlsx|190340|f3b2c76d359c8decd33c01d8b4b0235b
검사보고서_제너레이터.xlsx|190507|ef7edda07812f937381f82819fc79d22
'
TPL_ALL_WANT=11
# 🔴 앱이 보는 설정 이름 열하나. **전부 ASCII** 라 argv 로 넘겨도 안 깨진다.
TPL_ENV_NAMES="QUOTE_TEMPLATE_PATH OH_QUOTE_TEMPLATE_PATH MATCHER_QUOTE_TEMPLATE_PATH MATCHER_OH_QUOTE_TEMPLATE_PATH CABLE_QUOTE_TEMPLATE_PATH REPAIR_REPORT_TEMPLATE_PATH INSPECTION_REPORT_TEMPLATE_PATH MATCHER_REPAIR_REPORT_TEMPLATE_PATH MATCHER_INSPECTION_REPORT_TEMPLATE_PATH GENERATOR_REPAIR_REPORT_TEMPLATE_PATH GENERATOR_INSPECTION_REPORT_TEMPLATE_PATH"

# ══ 🔴 연락서 원본 폴더 — 연락서를 이식할 때 읽는 자리 ════════════════
#   🔵 기대값의 출처: 2026-10-28 실측 673장 · 143장. 늘기만 하는 폴더라 아래
#      바닥값으로 잰다. 🔴 **0 이면 볼륨 줄은 있는데 안 열리는 것**이고, 그것이
#      제일 조용한 실패다.
KYO_SRC=/kyosan-src;        KYO_SRC_MIN=600
KYO_CONV=/kyosan-converted; KYO_CONV_MIN=100

# ══ 🔴 발주서 공유폴더 — **이번 판에 쓰는 자리가 하나 늘었다** ════════
#   🔵 app-as 에 이미 붙어 있다(17번 · 2026-10-12). 설정 이름도 그대로이고
#      **이번 범위에 늘어난 환경변수가 0개**다(2026-11-07 실측).
#   🔴 그런데 **이번 판에 기타건 상세의 [발주서] 탭이 같은 폴더를 읽는다** —
#      수리 건 탭만 쓰던 자리를 둘이 쓰게 됐다. 그래서 「열리는가」를 잰다.
#      🔴 **기대값을 박지 않는다** — 그 폴더의 장수를 아무도 안 재 봤다.
#      0 이면 ✗(볼륨 줄은 있는데 안 열린다), 1 이상이면 수를 찍고 ✓ 다.
PO_ARCHIVE=/purchase-order-archive

# ══ 🔴 설정 파일 — .env 쪽과 env/*.env 쪽을 **둘 다** 본다 ════════════
ENV_NAS=$D/deploy/.env.nas
ENV_AS=$D/deploy/env/as.env
ENV_AUTH=$D/deploy/env/auth.env
ENV_PO=$D/deploy/env/po.env

# ══ 🔴 tar 넷의 지문 — [배포본] 53-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 안 채웠다.** 53-build.sh --go 가 끝에 찍어 주는 **네 줄**로 아래
#      네 줄을 통째로 갈아 끼우세요.
#   🔴 비어 있으면 3절이 **--check·--rollback 에서는 ? · --preload·--go 에서는 ✗**
#      로 센다. 🔵 막는 것은 **✗ 뿐이다** — ? 는 아무것도 안 막는다.
#   🔵 이름만이라도 적어 두는 까닭: 줄이 아예 없으면 4절(--preload)이 **아무것도
#      안 싣고 조용히 끝난다.** 이름이 있으면 싣기는 제대로 된다.
TARS='
dss-as-4.6.tar|134326784|6d9fa50045f6ff6ed2770fa341e44e74|sha256:f19305c7a9b54dc7563c50da7d7df548461abbef9b60c170690e7be8b2cb0b59
dss-as-tools-13.tar|225127424|12f64217b7f094203b6bf6d119fd7477|sha256:91b5b7b6b48ec25b5c8414884ebeb78efc90ba05e9a1e42df9e9ab640067a9e8
dss-auth-2.1.tar|113688064|fba007f4c4032376326f410003860da1|sha256:0eebe6974ef8aa8742d601801e68772c23eb86e3b08b595f45bad57c02d6f8ab
dss-auth-tools-4.tar|212260864|ea2892943ac68c3243b1f5451d7c984e|sha256:b227d5b5a936b27cde8dcd33127697b630e9e1970c5fe1142e4f0a1613156521
'
TARS_WANT=4

# 🔴 tar 이름 → 태그. **정규식으로 되돌리지 않는다** — 이름마다 손으로 적는다.
#    dss-as-tools-13 을 「끝의 숫자 앞에 콜론」 규칙으로 풀면 맞지만, 규칙이
#    맞는지 사람이 눈으로 확인할 수 없는 자리에 두지 않는다(39번의 그 주석).
tar2tag() {
  case "$1" in
    dss-as-4.6.tar)        printf 'dss-as:4.6' ;;
    dss-as-tools-13.tar)   printf 'dss-as-tools:13' ;;
    dss-auth-2.1.tar)      printf 'dss-auth:2.1' ;;
    dss-auth-tools-4.tar)  printf 'dss-auth-tools:4' ;;
  esac
}

# ══ 🔴 DB — **이번 판은 앞뒤가 다른 수다** (52번과 반대) ══════════════
#   🔵 A/S 와 PO 는 **같은 dss_as** 를 본다(PO 는 제 DB 가 없다).
#   🔵 포털은 **dss_auth** 를 따로 본다 — 이번 판에 **한 글자도 안 바꾼다.**
AS_BOX=dss-pg-app;   AS_DB=dss_as
AUTH_BOX=dss-pg-auth; AUTH_DB=dss_auth
# 🔴 **둘이 다른 값인 것이 이 판의 사실이다.** 52번은 124/124 였다.
AS_MIG_BEFORE=124   # [저장소·운영] 48번이 올린 그 수 · 49번이 안 바꿨다
AS_MIG_AFTER=125    # [저장소] 53-build.sh 4절과 같다(.sql 125 · idx 125)
AUTH_MIG_KEEP=10    # [README 36번] 포털은 그대로여야 한다
AS_PREV_MIG=0123
AS_NEW_MIG=0124     # 🔴 셈으로 만들지 않는다(8진수 함정). 글자로 적는다
AS_NEXT_MIG=0125
AS_KEEP_MIGS='0121 0122 0123'
# 🔴 「지우는 문장」의 잣대. 앱의 src/lib/db/migration-safety.ts 와 같다.
#    ⚠️ DELETE 는 **DELETE FROM** 일 때만 센다 — 0124 의 ON DELETE set null 은
#    외래키의 동작이지 지우는 문장이 아니다. DROP CONSTRAINT 도 안 센다(그쪽은
#    risky 갈래다). 안 가르면 **더하기만 하는 판이 ✗ 가 된다**(19번이 넘어진 자리).
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
MIG_DROP_WANT=0
# 🔴 「자료는 그대로지만 살펴볼 문장」 — 앱의 findRiskyOperations 갈래다.
#    🔵 0124 는 **둘**이고(DROP CONSTRAINT 둘) 같은 파일에서 넓혀 다시 세운다.
#    🔴 **0 으로 기대하면 안 되고, 안 세도 안 된다** — 안 세면 「제약 둘이 빠진
#       판」과 「빠졌다 다시 선 판」이 구별되지 않는다.
RISKY_RE='DROP[[:space:]]+(CONSTRAINT|INDEX|TYPE)|RENAME[[:space:]]+(TO|COLUMN)|SET[[:space:]]+NOT[[:space:]]+NULL'
MIG_RISKY_WANT=2
MIG_REDO1='ADD CONSTRAINT "repair_case_approvals_delegation_only_for_final_shipment"'
MIG_REDO2='ADD CONSTRAINT "repair_case_approvals_route_only_for_final_shipment"'
# 묶음이 들어오는 자리. 🔴 **이번 판에는 반드시 와 있어야 한다**(볼륨 124 · 저장소 125).
MIGTAR=$D/setup/incoming/as-migrations.tar.gz
INCOMING=$D/setup/incoming
# 🔴 53-build.sh --go 가 찍어 주는 값. 비워 두면 ? 로만 센다.
MIGTAR_SIZE=2411789
MIGTAR_MD5=d038dacf4a0148f7b7e1b856493fba09

# ══ 🔴 0124 가 만드는 것 — 적용 뒤 **값으로** 센다 ════════════════════
#   🔴 「기록이 125 다」와 「그 칸과 제약이 정말 있다」는 다른 말이다.
AS_NEW_COL_TABLE=repair_case_approvals
AS_NEW_COL=domestic_order_id
AS_NEW_IDX1=repair_case_approvals_one_active_domestic_request
AS_NEW_IDX2=repair_case_approvals_domestic_order_id_idx
AS_NEW_FK=repair_case_approvals_domestic_order_id_domestic_orders_id_fk
AS_NEW_CK1=repair_case_approvals_domestic_order_only_for_domestic_type
AS_NEW_CK2=repair_case_approvals_domestic_type_has_no_repair_case
AS_REDO_CK1=repair_case_approvals_delegation_only_for_final_shipment
AS_REDO_CK2=repair_case_approvals_route_only_for_final_shipment
AS_NEW_ENUM1=repair_case_approval_type
AS_NEW_ENUM2=shipment_approval_route_scope
AS_NEW_ENUM_VALUE=DOMESTIC_ORDER_FINAL_SHIPMENT
# 🔵 48번이 올린 것 — **아직 있어야 한다.** 52번에서 그대로 가져왔다.
AS_OLD_TABLE=procedure_case_execution_edges
AS_OLD_COL_TABLE=procedure_template_nodes
AS_OLD_COL=next_procedure_template_id
AS_OLD_INDEX=procedure_template_nodes_next_template_idx
# 🔴 줄 수가 그대로여야 하는 표 — 이 배포는 **자료를 안 건드린다**(칸만 더한다).
AS_COUNT_TABLES='repair_cases domestic_orders repair_case_approvals shipment_approval_routes procedure_templates users'
AUTH_COUNT_TABLES='users clients approval_mail_kinds'
# 🔴 49번이 올린 기능이 쓰는 표. 1-ㄹ 절이 이 이름으로 권한을 묻는다. **ASCII 다.**
PO_WRITE_TABLE=repair_cases
# ══ 🔵 **안 건드리는 여덟** — 「옆으로 안 샜다」는 증거로 센다 ═════════
#   🔴 **52번은 아홉이었고 거기에 dss-auth 가 있었다.** 이번엔 건드리므로 뺐다.
#      🔴 빼는 것만으로는 모자라다 — 포털을 SITES 에 넣어 7절이 **다시 떴는지**
#         값으로 재게 했다. 그러지 않으면 아무도 포털을 안 본다.
KEEP_BOXES="dss-inventory dss-meters dss-board dss-improvements dss-leave dss-approvals dss-rf-trouble dss-po"
KEEP_BOXES_WANT=8
# 🔵 DB 둘은 멈추지 않는다 (애초에 up -d --no-deps 가 앱 둘만 건드린다)
KEEP_DB="dss-pg-app dss-pg-auth"

# ══ 🔴 후속 작업 둘을 **값으로** 센다 ═════════════════════════════════
#   ① 기타건 결재선 판 — shipment_approval_routes 의 scope 가 그 값인 줄
#      🔴 scope::text 로 비교한다. enum 리터럴로 비교하면 **적용 전에는 그 값이
#         없어 질의가 통째로 오류**가 난다(invalid input value for enum).
#   ② 포털 메일 스위치 — approval_mail_kinds 의 그 한 줄
AS_ROUTE_TABLE=shipment_approval_routes
AUTH_MAIL_TABLE=approval_mail_kinds
AUTH_MAIL_CLIENT=rf-service-system

MODE=check
case "${1:-}" in
  --check|"")   MODE=check ;;
  --count)      MODE=count ;;
  --preload)    MODE=preload ;;
  --migrate)    MODE=migrate ;;
  --go)         MODE=go ;;
  --rollback)   MODE=rollback ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --count · --preload · --migrate · --go · --rollback\n' "$1"; exit 2 ;;
esac

PASS=0; FAIL=0; WARN=0
ok()  { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
hm()  { WARN=$((WARN+1)); printf '  ? %s\n' "$1"; }
say() { printf '    %s\n' "$1"; }
cmd() { printf '      %s\n' "$1"; }
# 🔴 ✗ 가 났을 때 그 자리에서 찍는다 — 처음 도는 코드라 기대값이 틀릴 확률이
#    배포만큼 높다. ✓ 쪽 오판은 영영 안 드러나므로 ✗ 쪽을 크게 적는다.
doubt() { say "🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 이 줄의 기대값이"
          say "   어디서 왔는지는 파일 머리의 기대값 표에 적혀 있습니다."; }

isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }
rows()  { printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'; }
trows() { printf '%s\n' "$TARS"  | tr -d ' ' | grep -v '^$'; }
fld()   { printf '%s' "$1" | cut -d'|' -f"$2"; }
# 🔴 양식 표는 **공백을 지우면 안 된다** — 이름에 공백이 들어 있다.
tplrows() { printf '%s\n' "$1" | grep -v '^[[:space:]]*$'; }

dc()  { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas "$@" ); }
dct() { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas --profile tools "$@" ); }

[ "$(id -u)" = 0 ] || { printf '먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요.\n'; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/53-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "쉰째 배포 — A/S 앱·도구 + **포털 앱·도구** (양식 0장 · 마이그레이션 **1건**)   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  🔴 개발 PC 의 Get-FileHash 값과 **같은지 눈으로 맞대세요** (DSM 터미널이 긴 것을 잘라 먹습니다)"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  로그: $LOG"
printf '%s\n' "  🔴 차례: --check → --count → (scp tar 넷 + 묶음) → --preload → --check → --migrate → --go → --count"
printf '%s\n' "  🔴 **포털도 갈아 끼웁니다** — 14판 만입니다(마지막은 39번 · 2026-10-27)"
printf '%s\n' "  🔴 **DB 가 바뀝니다** — 마이그레이션 $AS_MIG_BEFORE → $AS_MIG_AFTER (0124)"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 공통: compose 에서 그 서비스의 image: 줄을 찾는다 ─────────────────
# 🔴 그 블록 안의 것 하나만 고쳐야 한다. 서비스 머리부터 다음 서비스 머리 전까지.
img_line() { # 1 서비스
  local s start next
  s=$1
  start=$(grep -n "^  ${s}:" "$CF" | head -1 | cut -d: -f1)
  [ -n "$start" ] || return 1
  next=$(awk -v s="$start" 'NR>s && /^  [a-z]/ {print NR; exit}' "$CF")
  awk -v s="$start" -v e="${next:-999999}" 'NR>s && NR<e && /^[[:space:]]*image:/ {print NR; exit}' "$CF"
}
tag_at() { awk -v n="$1" 'NR==n {print $2}' "$CF"; }
# 🔴 그 줄의 낱말 수. **2 가 아니면 치환하지 마라.**
#    5절의 치환은 'sub(/[^ ]+$/, to)' 로 **줄의 마지막 낱말**을 갈아 끼운다.
#    줄 끝에 주석이 붙어 있으면 **주석의 마지막 낱말**이 태그로 바뀌고 image: 값은
#    그대로 남는다 — 48번이 가짜 compose 로 직접 재어 확인했다.
nf_at() { awk -v n="$1" 'NR==n {print NF}' "$CF"; }
svc_block() { # 1 서비스 — 주석 줄은 뗀다
  awk -v s="  $1:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$CF" | sed '/^[[:space:]]*#/d'
}
# 🔵 앱 쪽 image: 줄의 「줄번호:태그」 목록. --migrate 가 앱 줄을 안 건드렸다는
#    증거로 앞뒤를 맞댄다.
app_img_lines() {
  for r in $(rows); do
    L=$(img_line "$(fld "$r" 2)") || continue
    printf '%s:%s\n' "$L" "$(tag_at "$L")"
  done
}

# 🔴 운영 DB 를 **앱이 쓰는 길**(컨테이너 안 psql)로 잰다. 소켓·루프백으로 재면
#    trust 라 그냥 통과한다. 보내는 SQL 은 select 뿐이다.
pgq() { # 1 상자 2 DB 3 SQL
  "$DOCKER" exec -i "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -X -tAq -c \"$3\"" 2>/dev/null | head -1 | tr -d ' \r'
}
pgn() { local v; v=$(pgq "$1" "$2" "$3"); isnum "$v" && printf '%s' "$v"; }
mig_count() { pgn "$1" "$2" 'select count(*) from drizzle.__drizzle_migrations'; }
# ══ 🔴 마이그레이션 헬퍼 — 48·52번 것에 **셋을 더했다** ═══════════════
#   🔵 0124 는 표를 안 만든다 — enum 값 · 칸 · 인덱스 둘 · 제약 넷을 더한다.
#      그래서 has_table 만으로는 **아무것도 못 잰다.** 재는 길을 늘렸다.
has_table()  { pgn "$1" "$2" "select count(*) from information_schema.tables where table_schema='public' and table_name='$3'"; }
has_column() { pgn "$1" "$2" "select count(*) from information_schema.columns where table_schema='public' and table_name='$3' and column_name='$4'"; }
has_index()  { pgn "$1" "$2" "select count(*) from pg_indexes where schemaname='public' and indexname='$3'"; }
# 🔴 제약은 pg_indexes 에 없다 — pg_constraint 로 묻는다. CHECK 도 외래키도 여기 있다.
has_constraint() { pgn "$1" "$2" "select count(*) from pg_constraint where conname='$3'"; }
# 🔴 enum 값은 표도 칸도 아니다 — pg_enum 으로 묻는다. 이것을 안 재면 「칸은
#    생겼는데 값이 없는」 반쪽 적용을 못 잡는다.
has_enum_value() { pgn "$1" "$2" "select count(*) from pg_enum e join pg_type t on t.oid=e.enumtypid where t.typname='$3' and e.enumlabel='$4'"; }

read_migdir() {
  MIG_N_SQL=0; MIG_N_J=0; MIG_STATE=""
  [ -d "$MIGDIR" ] || { MIG_STATE=NODIR; return 0; }
  MIG_N_SQL=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  if [ -f "$MIGDIR/meta/_journal.json" ]; then
    MIG_N_J=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  fi
  MIG_N_SQL=${MIG_N_SQL:-0}; MIG_N_J=${MIG_N_J:-0}
  # 🔴 **이번 판은 가지가 셋 다 닿는다.** 52번은 둘이 같은 수라 OLD 가 안 나왔다.
  #    DONE = 묶음을 이미 풀었다(125) · OLD = 아직 안 풀었다(124) · ODD = 그 밖.
  if   [ "$MIG_N_SQL" = "$AS_MIG_AFTER" ]  && [ "$MIG_N_J" = "$AS_MIG_AFTER" ];  then MIG_STATE=DONE
  elif [ "$MIG_N_SQL" = "$AS_MIG_BEFORE" ] && [ "$MIG_N_J" = "$AS_MIG_BEFORE" ]; then MIG_STATE=OLD
  else MIG_STATE=ODD
  fi
  return 0
}

# 🔴 볼륨이 125 가 **아닐 때** 묶음을 푼다. 🔵 52번과 반대로, 이번 판에는
#    **대개 불린다**(운영 볼륨이 124 이므로).
place_migs() {
  if [ ! -s "$MIGTAR" ]; then
    bad "🔴 볼륨을 125 로 올려야 하는데 묶음이 없다: $MIGTAR"
    say "🔵 53-build.sh --go 가 만든 as-migrations.tar.gz 를 $INCOMING 로 보내세요."
    say "   (개발 PC · PowerShell) scp -O as-migrations.tar.gz dss-nas:$INCOMING/"
    return 1
  fi
  rm -rf "$MIGDIR.new"; mkdir -p "$MIGDIR.new"
  if tar -xzf "$MIGTAR" -C "$MIGDIR.new" --strip-components=1; then
    rm -rf "$MIGDIR.old"
    [ -d "$MIGDIR" ] && mv "$MIGDIR" "$MIGDIR.old"
    mv "$MIGDIR.new" "$MIGDIR"
    chown -R root:root "$MIGDIR"; chmod -R a+rX "$MIGDIR"
    ok "as-migrations 새것으로 (옛것: as-migrations.old — 되돌릴 길이다)"
    say "🔵 묶음은 **지우지 않는다** — 다시 돌릴 때 쓴다."
    return 0
  fi
  rm -rf "$MIGDIR.new"
  bad "as-migrations 풀기 실패"
  return 1
}

# 🔴 48번이 올린 셋이 **아직 온전한가** + **0124 가 와 있는가** + 지우는 문장.
check_keep_migs() {
  local t miss="" f n rc=0 c r redo
  for t in $AS_KEEP_MIGS; do
    ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || miss="$miss $t(sql)"
    [ -f "$MIGDIR/meta/${t}_snapshot.json" ]   || miss="$miss $t(snapshot)"
  done
  if [ -z "$miss" ]; then ok "0121·0122·0123 의 .sql 과 meta/*_snapshot.json 이 다 있다 (48번이 올린 그대로)"
  else bad "🔴 빠진 것:$miss"; rc=1; fi
  # 🔴 **0124 가 와 있는가** — 이 판의 전제다. 52번과 **반대** 기대값이다.
  if ls -1 "$MIGDIR/${AS_NEW_MIG}_"*.sql >/dev/null 2>&1; then
    ok "볼륨에 $AS_NEW_MIG 번이 **있다** (이번 판이 적용할 그 한 건)"
  else
    bad "🔴 볼륨에 $AS_NEW_MIG 번이 **없다** — 묶음을 안 풀었거나 옛 묶음이다. 적용이 0건으로 끝난다"
    rc=1
  fi
  if [ -f "$MIGDIR/meta/${AS_NEW_MIG}_snapshot.json" ]; then
    ok "볼륨에 meta/${AS_NEW_MIG}_snapshot.json 이 있다"
  else
    bad "🔴 meta/${AS_NEW_MIG}_snapshot.json 이 없다 — 목록에 없는 .sql 은 drizzle 이 **아예 모른다**"
    rc=1
  fi
  # 🔴 0125 는 없어야 한다. 글자로 맞댄다(8진수 함정).
  if ls -1 "$MIGDIR/${AS_NEXT_MIG}_"*.sql >/dev/null 2>&1; then
    bad "🔴 볼륨에 $AS_NEXT_MIG 번이 **있다** — 이 배포는 1건을 전제로 쓰였다. 멈추고 알리세요"
    rc=1
  else
    ok "볼륨에 $AS_NEXT_MIG 번이 없다 (마지막이 $AS_NEW_MIG — 1건이 맞다)"
  fi
  # 🔴 지우는 문장 — 잣대가 살아 있는지 **표본 셋으로 먼저** 확인하고 센다.
  if [ "$(printf '%s\n' 'DROP TABLE foo;' | grep -ciE "$DESTRUCTIVE_RE" || true)" != "1" ]; then
    bad "🔴 지우는 문장 잣대가 죽었다 — 아래 「0줄」이 공짜 통과다. 멈추세요"; rc=1
  else
    ok "지우는 문장 잣대가 살아 있다 (가짜 DROP 하나를 제대로 잡았다)"
  fi
  if [ "$(printf '%s\n' 'REFERENCES "b"("id") ON DELETE set null;' | grep -ciE "$DESTRUCTIVE_RE" || true)" != "0" ]; then
    bad "🔴 ON DELETE 를 지우는 문장으로 센다 — **0124 가 가짜 ✗ 를 받는다**"; rc=1
  else
    ok "ON DELETE set null 은 지우는 문장으로 안 센다 (0124 가 가짜 ✗ 를 안 받는다)"
  fi
  if [ "$(printf '%s\n' 'ALTER TABLE a DROP CONSTRAINT c;' | grep -ciE "$DESTRUCTIVE_RE" || true)" != "0" ]; then
    bad "🔴 DROP CONSTRAINT 를 지우는 문장으로 센다 — 앱의 잣대와 다르다. **0124 가 가짜 ✗ 를 받는다**"; rc=1
  else
    ok "DROP CONSTRAINT 도 지우는 문장으로 안 센다 (앱의 migration-safety 와 같은 잣대다)"
  fi
  # 🔵 네 장(0121~0124) 전부를 센다 — 폴더를 통째로 갈아 끼우므로 넷 다 본다.
  n=0
  for t in $AS_KEEP_MIGS $AS_NEW_MIG; do
    f=$(ls -1 "$MIGDIR/${t}_"*.sql 2>/dev/null | head -1)
    [ -n "$f" ] || continue
    c=$(grep -ciE "$DESTRUCTIVE_RE" "$f" 2>/dev/null || true); n=$((n + ${c:-0}))
  done
  if [ "$n" = "$MIG_DROP_WANT" ]; then
    ok "0121~0124 에 지우는 문장이 ${n}줄이다 (기대 ${MIG_DROP_WANT}줄 — 더하기만 한다)"
  else
    bad "🔴 0121~0124 에 지우는 문장이 ${n}줄이다 (기대 ${MIG_DROP_WANT}줄) — 고치지 말고 **먼저 알리세요**"
    rc=1
  fi
  # 🔴 **살펴볼 문장은 따로 센다 — 0124 에 정확히 둘이어야 한다.**
  f=$(ls -1 "$MIGDIR/${AS_NEW_MIG}_"*.sql 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    r=$(grep -ciE "$RISKY_RE" "$f" 2>/dev/null || true)
    say "$AS_NEW_MIG 의 살펴볼 문장 ${r:-?}줄 (기대 $MIG_RISKY_WANT — 제약 삭제 둘)"
    if [ "${r:-x}" = "$MIG_RISKY_WANT" ]; then
      ok "$AS_NEW_MIG 에 살펴볼 문장이 $MIG_RISKY_WANT 줄이다 — 🔵 **앱의 db:preflight 도 같은 수를 찍는다**"
    else
      bad "🔴 $AS_NEW_MIG 에 살펴볼 문장이 ${r:-?}줄이다 — $MIG_RISKY_WANT 줄을 기대했다. **다른 파일이다**"
      grep -niE "$RISKY_RE" "$f" | cut -c1-110 | sed 's/^/      /'
      rc=1
    fi
    # 🔴 **뗀 둘이 같은 파일에서 다시 서는가** — 「뗐다」만 세면 사라진 판과 같다.
    redo=0
    grep -qF "$MIG_REDO1" "$f" && redo=$((redo+1))
    grep -qF "$MIG_REDO2" "$f" && redo=$((redo+1))
    if [ "$redo" = "2" ]; then
      ok "뗀 제약 둘이 **같은 파일에서 넓혀 다시 세워진다** (자료가 안 사라진다)"
    else
      bad "🔴 다시 세우는 ADD CONSTRAINT 가 ${redo}/2 개다 — **제약이 사라진 채 끝나는 판이다**"
      rc=1
    fi
  fi
  # 🔵 글자 표식 — 올려 둔 것이 그 파일이 맞는지. 이름만 맞고 속이 다를 수 있다.
  #    🔴 넷 다 본다. 하나만 보면 나머지 셋은 이름만 맞아도 통과한다.
  f=$(ls -1 "$MIGDIR/0121_"*.sql 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    grep -qF "CREATE TABLE \"$AS_OLD_TABLE\"" "$f" \
      && ok "0121 안에 표 $AS_OLD_TABLE 를 만드는 줄이 있다" \
      || { bad "🔴 0121 안에 그 표를 만드는 줄이 **없다** — 다른 파일이다"; rc=1; }
  fi
  f=$(ls -1 "$MIGDIR/0123_"*.sql 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    grep -qF "ADD COLUMN \"$AS_OLD_COL\"" "$f" \
      && ok "0123 안에 칸 $AS_OLD_COL 를 더하는 줄이 있다" \
      || { bad "🔴 0123 안에 그 칸을 더하는 줄이 **없다** — 다른 파일이다"; rc=1; }
  fi
  f=$(ls -1 "$MIGDIR/${AS_NEW_MIG}_"*.sql 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    grep -qF "ADD COLUMN \"$AS_NEW_COL\"" "$f" \
      && ok "$AS_NEW_MIG 안에 칸 $AS_NEW_COL 를 더하는 줄이 있다" \
      || { bad "🔴 $AS_NEW_MIG 안에 그 칸을 더하는 줄이 **없다** — 다른 파일이다"; rc=1; }
    grep -qF "'$AS_NEW_ENUM_VALUE'" "$f" \
      && ok "$AS_NEW_MIG 안에 enum 값 $AS_NEW_ENUM_VALUE 가 있다" \
      || { bad "🔴 $AS_NEW_MIG 안에 그 enum 값이 **없다** — 다른 파일이다"; rc=1; }
    # 🔴 CHECK 이 ::text 비교인가 — enum 리터럴이면 **같은 트랜잭션에서 죽는다.**
    c=$(grep -c 'approval_type::text' "$f" 2>/dev/null || true)
    if [ "${c:-0}" -ge 4 ] 2>/dev/null; then
      ok "$AS_NEW_MIG 의 CHECK 넷이 ::text 비교다 (방금 더한 enum 값을 같은 트랜잭션에서 **안 쓴다**)"
    else
      bad "🔴 ::text 비교가 ${c:-?}개다 — 넷을 기대했다. **적용이 그 자리에서 죽을 수 있다**"
      rc=1
    fi
  fi
  return "$rc"
}

# ══ 🔴 덤프 — **이번 판은 DB 가 바뀐다. 반드시 뜬다** ═════════════════
#   🔵 52번은 「안 바꾸지만 사진으로 남긴다」였다. 이번 판은 **되돌릴 기준**이다.
#   🔵 **포털 DB 는 안 뜬다** — 이 배포가 dss_auth 를 한 글자도 안 바꾸고
#      (마이그레이션 0건), 야간 백업(nas/jobs/backup-nightly.sh 80줄)이 매일
#      dss_auth 를 받는다. 되돌리기도 **이미지만** 되돌린다.
#   🔴 「파일이 생겼다」와 「쓸 만한 덤프다」는 다르다. 크기와 머리 다섯 글자를 본다.
DUMP=""
make_dump() { # 1 왜 뜨는지 한 줄
  printf '\n    ── 덤프를 뜬다 (%s)\n' "$1"
  mkdir -p "$BKDB" 2>/dev/null
  DUMP="$BKDB/dss_as-v50-$STAMP.dump"
  if "$DOCKER" exec -i "$AS_BOX" sh -c 'pg_dump -U "$POSTGRES_USER" -d dss_as -Fc' > "$DUMP" 2>/dev/null; then
    local dsz magic
    dsz=$(stat -c %s "$DUMP" 2>/dev/null || wc -c < "$DUMP")
    say "덤프 $DUMP (${dsz:-?}바이트)"
    if [ "${dsz:-0}" -gt 10240 ]; then ok "덤프가 ${dsz}바이트다 (10KB 넘음)"
    else bad "덤프가 ${dsz:-0}바이트뿐이다 — 쓸 수 없다"; fi
    # 🔴 **속을 본다.** -Fc 덤프는 첫 다섯 글자가 PGDMP 다. 파이프로 pg_restore 를
    #    먹이는 길은 판에 따라 「읽을 수 없는 보관본」으로 죽으므로 쓰지 않는다.
    magic=$(head -c 5 "$DUMP" 2>/dev/null)
    say "덤프 머리 다섯 글자: ${magic:-없음}"
    if [ "$magic" = "PGDMP" ]; then ok "제대로 된 -Fc 덤프다"
    else bad "머리가 PGDMP 가 아니다 — 덤프가 아니거나 깨졌다"; fi
    chmod 600 "$DUMP" 2>/dev/null
  else
    bad "덤프를 못 떴다 — $AS_BOX 가 도는지 보세요"
    doubt
  fi
  say "⚠️ PO 가 **같은 $AS_DB 를 보고 있다** — 덤프 중에 PO 에서 저장한 것은 이"
  say "   덤프에 안 들어갈 수 있다. 그래서 이것은 마지막 수단이다."
  say "🔵 포털 DB(dss_auth)는 **안 뜬다** — 이 배포가 한 글자도 안 바꾸고 야간 백업이 매일 받는다."
}

# ══ 🔴 양식 — 한 파일의 md5 (없으면 빈 줄) ════════════════════════════
#   🔴 이름에 공백과 한글이 있다. **전부 큰따옴표로 감싼다.**
tpl_md5()  { [ -s "$1/$2" ] || return 0; md5sum "$1/$2" 2>/dev/null | awk '{print $1}'; }
tpl_size() { [ -s "$1/$2" ] || return 0; stat -c %s "$1/$2" 2>/dev/null; }
tpl_dump() { # 1 폴더 — 이름 | 바이트 | 시각 | 주인 | 모드 | md5
  local f
  [ -d "$1" ] || return 0
  ( cd "$1" 2>/dev/null || exit 0
    find . -maxdepth 1 -type f -print 2>/dev/null | sed 's|^\./||' | sort | while IFS= read -r f; do
      printf '      %-30s %9s  %s  %s:%s %s  %s\n' \
        "$f" \
        "$(stat -c %s "$f" 2>/dev/null)" \
        "$(date -r "$f" '+%Y-%m-%d %H:%M' 2>/dev/null)" \
        "$(stat -c %u "$f" 2>/dev/null)" "$(stat -c %g "$f" 2>/dev/null)" \
        "$(stat -c %a "$f" 2>/dev/null)" \
        "$(md5sum "$f" 2>/dev/null | awk '{print $1}')"
    done )
}
tpl_file_count() { local n; [ -d "$1" ] || return 0; n=$(find "$1" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' '); printf '%s' "${n:-}"; }

# ══ 🔴 앱이 그 양식을 **보는가** — 설정 이름으로 묻는다 ══════════════
#   🔴 이름은 전부 ASCII 다. 한글은 **값**으로만 오가고 argv 에 안 들어간다.
TPL_ENV_PROBE='var fs=require("fs");
var ns=(process.env.DSS_TPL_NAMES||"").split(" ").filter(function(x){return x!=="";});
if(ns.length===0){console.log("NONAMES");}
ns.forEach(function(n){
var v=(process.env[n]||"").trim();
if(v===""){console.log("UNSET "+n);return;}
var inside=v.indexOf("/templates/")===0;
var shown=inside?v:"(/templates 밖이라 안 찍는다)";
var okf=false;try{okf=fs.statSync(v).isFile();}catch(e){okf=false;}
console.log((okf?"OK    ":"MISS  ")+n+" "+shown);});'

# 🔴 **이번 판에도 올릴 양식이 없다.** 그래서 level 이 하나뿐이다 — 재기만 한다.
templates_check() {
  local n got name wsz wm5 m s same diff miss out okn missn unsetn
  printf '\n    ── 🔴 운영 양식을 **값으로** 잰다 (읽기만 한다 · 이번 판은 올릴 것이 0장)\n'
  say "자리: $TPLDIR  (app-as·app-po 가 $TPL_IN_CONTAINER 로 붙인다 · 읽기 전용)"
  if [ ! -d "$TPLDIR" ]; then
    hm "$TPLDIR 가 없다 — **못 쟀다.** 사람이 보세요"
    return
  fi
  n=$(tpl_file_count "$TPLDIR")
  say "그 폴더 안 파일 ${n:-못 쟀다}개"
  if ! isnum "${n:-}" || [ "${n:-0}" -eq 0 ]; then
    hm "양식 폴더가 비었거나 못 읽었다 — **빈 결과는 삼켜진 오류일 수 있다.** 사람이 보세요"
    return
  fi
  say "── 지금 놓여 있는 것 (이름 · 바이트 · 시각 · 주인 · 모드 · md5)"
  tpl_dump "$TPLDIR"
  printf '\n    ── 열하나가 개발 PC 것과 같은가 (**다르다고 ✗ 를 내지 않는다**)\n'
  same=0; diff=0; miss=0; got=0
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    got=$((got+1))
    if [ ! -s "$TPLDIR/$name" ]; then
      say "없음   $name"; miss=$((miss+1)); continue
    fi
    m=$(tpl_md5 "$TPLDIR" "$name"); s=$(tpl_size "$TPLDIR" "$name")
    if [ "${m:-x}" = "$wm5" ] && [ "${s:-x}" = "$wsz" ]; then
      same=$((same+1)); say "같다   $name"
    else
      diff=$((diff+1)); say "다르다 $name  운영 ${s:-?}바이트 ${m:-?}"
      say "       개발 PC $wsz바이트 $wm5"
    fi
  done <<TPLALLEOF
$(tplrows "$TPL_ALL")
TPLALLEOF
  if [ "$got" = "$TPL_ALL_WANT" ]; then ok "양식 $TPL_ALL_WANT 개를 다 봤다 (표본이 비지 않았다)"
  else bad "양식을 ${got}개만 봤다 — $TPL_ALL_WANT 개를 기대했다. TPL_ALL 표가 깨졌다"; fi
  say "같다 ${same} · 다르다 ${diff} · 없다 ${miss}"
  if [ "$diff" = "0" ] && [ "$miss" = "0" ]; then
    ok "운영 양식 열하나가 개발 PC 것과 같다 (**이 배포가 건드릴 자리가 아니다**)"
  else
    hm "열하나 중 ${diff}개가 다르고 ${miss}개가 없다 — **이 배포를 막지 않는다.** 사람이 보세요"
    say "🔵 운영 양식이 개발 PC 것과 꼭 같아야 한다는 보증은 어디에도 없다."
    say "🔴 **양식을 새로 올려야 하는 판이면** 이 파일에는 그 모드가 없다. 되살릴 곳:"
    say "   51-deploy.sh 의 --templates-prep(1056~1172줄) · --templates-apply(1174~1341줄)."
  fi
  printf '\n    ── 🔴 **앱이 그 양식을 보는가** (설정 이름으로 묻는다)\n'
  out=$("$DOCKER" exec -e DSS_TPL_NAMES="$TPL_ENV_NAMES" "$AS_APP_CN" node -e "$TPL_ENV_PROBE" 2>&1 | tr -d '\r')
  if [ -z "${out:-}" ]; then
    hm "$AS_APP_CN 안에서 못 쟀다 — 그 상자가 도는지 보세요. **빈 결과는 삼켜진 오류일 수 있다**"
    return
  fi
  printf '%s\n' "$out" | sed 's/^/      /'
  okn=$(printf '%s\n' "$out" | grep -c '^OK    ' || true)
  missn=$(printf '%s\n' "$out" | grep -c '^MISS  ' || true)
  unsetn=$(printf '%s\n' "$out" | grep -c '^UNSET ' || true)
  say "앱이 보는 양식 — 읽힘 ${okn} · 설정은 있는데 파일이 없음 ${missn} · 설정 없음 ${unsetn}"
  if [ "${missn:-1}" = "0" ]; then
    ok "설정이 가리키는 양식이 **하나도 빠짐없이 읽힌다** (MISS 가 0 이다)"
  else
    bad "🔴 설정은 있는데 파일이 없는 것이 ${missn}개다 — 그 출력(견적서·보고서)이 **통째로 죽는다**"
    say "🔴 주인·모드를 보세요. 앱은 uid 1000 으로 돕니다."
    doubt
  fi
  if [ "${unsetn:-0}" != "0" ]; then
    hm "설정 이름이 비어 있는 것이 ${unsetn}개다 — **이 배포가 설정을 바꾸지 않는다.** 사람이 보세요"
    say "🔵 보고서 쪽 넷이 비어 있으면 코드가 **옛 이름 둘로 물러선다**(던지지는 않는다)."
    say "🔴 그 넷을 쓰고 싶으면 운영 compose 의 app-as 에 이름 넷을 더해야 한다 — **이 배포의 범위 밖**이다."
  fi
}

# ══════════════════════════════════════════════════════════════════════
# 🔴 PO 가 repair_cases 에 **쓸 수 있는가** — 49번의 검사를 그대로
# ══════════════════════════════════════════════════════════════════════
#   🔴 **앱이 쓰는 길로 잰다.** 🔴 **보내는 것은 select 뿐이다.**
#   🔴 **비밀번호를 꺼내지도 찍지도 않는다.**
#   🔴 **작은따옴표를 한 글자도 안 쓴다** — 이 문자열이 셸의 작은따옴표 안에
#      들어가기 때문이다. SQL 문자열은 전부 **자리표($1·$2·$3)** 로 넘긴다.
PO_PRIV_PROBE='const u=(process.env.DATABASE_URL||"").trim();
if(u===""){console.log("NOCONF");}
else{
var pg=null;
try{pg=require("postgres");}catch(e){pg=null;}
if(pg===null){console.log("NOMOD");}
else{
var sql=pg(u,{max:1,idle_timeout:2,connect_timeout:8});
var who="?";var db="?";
sql.unsafe("select current_user as who, current_database() as db, to_regclass($1)::text as rel",[process.env.DSS_PROBE_TABLE||"repair_cases"])
.then(function(rows){
var r=rows[0];who=String(r.who);db=String(r.db);
if(r.rel===null||r.rel===undefined){console.log("NOREL user="+who+" db="+db);return null;}
return sql.unsafe("select has_table_privilege(current_user,$1,$2) as upd, has_table_privilege(current_user,$1,$3) as sel",[process.env.DSS_PROBE_TABLE||"repair_cases","UPDATE","SELECT"])
.then(function(p){var q=p[0];
console.log("PRIV user="+who+" db="+db+" update="+(q.upd?1:0)+" select="+(q.sel?1:0));
return null;});})
.catch(function(e){var m=(e&&e.message)?String(e.message).split("\n")[0]:"error";console.log("FAIL "+m);})
.then(function(){return sql.end({timeout:2});})
.catch(function(){});
}}'
# 🔵 DATABASE_URL 에서 **역할 이름만** 꺼낸다. 비밀번호는 안 꺼낸다.
PO_ROLE_PROBE='try{console.log(new URL(process.env.DATABASE_URL||"").username||"");}catch(e){console.log("");}'

po_priv_via_psql() { # 찍는 것: "PSQL role=<역할> update=<t|f> select=<t|f>" 또는 빈 줄
  local role u s
  role=$("$DOCKER" exec "$PO_APP_CN" node -e "$PO_ROLE_PROBE" 2>/dev/null | tr -d ' \r')
  # 🔴 이름이 이상하면 SQL 에 넣지 않는다. 빈 결과가 조용한 ✓ 로 흐르지 않게
  #    여기서 **아무것도 안 찍고** 돌아간다 — 부르는 쪽이 「못 쟀다」로 센다.
  case "${role:-}" in
    ''|*[!A-Za-z0-9_]*) return 0 ;;
  esac
  u=$(pgq "$AS_BOX" "$AS_DB" "select has_table_privilege('$role','$PO_WRITE_TABLE','UPDATE')")
  s=$(pgq "$AS_BOX" "$AS_DB" "select has_table_privilege('$role','$PO_WRITE_TABLE','SELECT')")
  [ -n "${u:-}" ] || return 0
  printf 'PSQL role=%s update=%s select=%s' "$role" "${u:-?}" "${s:-?}"
}

# 🔴 level: warnmiss(권한 없음만 ✗ · 못 쟀으면 ?) · soft(전부 ?)
#    🔵 **이번 판에도 block 을 안 쓴다** — PO 를 갈아 끼우지 않으므로, 못 쟀다고
#       A/S·포털 교체를 막을 일이 아니다. 🔴 다만 **못 쓴다고 나오면 ✗** 다.
po_write_privilege_check() { # 1 warnmiss|soft
  local level out line who db upd sel pl pu ps
  level=${1:-warnmiss}
  printf '\n    ── 🔴 PO 가 %s 에 **쓸 수 있는가** (49번이 올린 기능 · 이번엔 안 갈아 끼우지만 잰다)\n' "$PO_WRITE_TABLE"
  say "🔵 묻기만 한다 — select 뿐이고 UPDATE 를 실제로 돌리지 않는다. 운영 자료다."
  out=$("$DOCKER" exec -e DSS_PROBE_TABLE="$PO_WRITE_TABLE" "$PO_APP_CN" node -e "$PO_PRIV_PROBE" 2>&1 | tr -d '\r')
  line=$(printf '%s\n' "$out" | grep -E '^(PRIV|NOREL|NOCONF|NOMOD|FAIL)' | tail -1)
  say "앱이 쓰는 길로 받은 것: ${line:-못 쟀다}"
  case "${line:-}" in
    PRIV*)
      who=${line#PRIV user=}; who=${who%% *}
      db=${line##* db=};      db=${db%% *}
      upd=${line##* update=}; upd=${upd%% *}
      sel=${line##* select=}; sel=${sel%% *}
      say "역할 $who · DB $db · UPDATE=$upd · SELECT=$sel"
      if [ "${db:-}" != "$AS_DB" ]; then
        hm "PO 가 보는 DB 가 $db 다 — $AS_DB 를 기대했다. **2절이 잰 DB 와 다르다.** 사람이 보세요"
        doubt
      fi
      if [ "${sel:-}" != "1" ]; then
        hm "SELECT 가 ${sel:-?} 다 — PO 는 오늘도 그 표를 읽고 있으므로 **1 이어야 한다.** 검사 자신을 의심하세요"
        doubt
        return
      fi
      if [ "${upd:-}" = "1" ]; then
        ok "PO 가 $PO_WRITE_TABLE 에 쓸 수 있다 (UPDATE=1 · SELECT=1 · 역할 $who)"
        return
      fi
      if [ "$level" = soft ]; then
        hm "PO 가 $PO_WRITE_TABLE 에 **못 쓴다**(UPDATE=0) — 🔵 되돌리기는 막지 않는다"
      else
        bad "🔴 PO 가 $PO_WRITE_TABLE 에 **못 쓴다**(UPDATE=0) — **지금 운영이 고장나 있다는 뜻**이다"
        say "🔴 이 배포가 만든 일이 아니다(PO 를 안 건드린다). 49번이 올린 기능이 막혀 있다는 뜻이고,"
        say "   PO 에서 납기요청일을 저장할 때마다 오류로 끝난다. **사람이 보세요.**"
        doubt
      fi
      return ;;
    NOREL*)
      hm "PO 가 붙은 DB 에서 $PO_WRITE_TABLE 를 **못 찾았다** — 검사 자신을 의심하세요(search_path 나 DB 가 다르다)"
      doubt
      return ;;
  esac
  say "🔵 앱이 쓰는 길로 못 쟀다 — psql 가지로 다시 묻는다(권한은 역할에 달린 것이라 같은 답이다)."
  printf '%s\n' "$out" | tail -6 | sed 's/^/      /'
  pl=$(po_priv_via_psql)
  say "psql 가지로 받은 것: ${pl:-못 쟀다}"
  case "${pl:-}" in
    PSQL*)
      pu=${pl##* update=}; pu=${pu%% *}
      ps=${pl##* select=}; ps=${ps%% *}
      if [ "${ps:-}" != "t" ]; then
        hm "psql 가지의 SELECT 가 ${ps:-?} 다 — t 여야 한다(PO 는 오늘도 읽는다). 검사 자신을 의심하세요"
        doubt
        return
      fi
      if [ "${pu:-}" = "t" ]; then
        ok "PO 의 역할이 $PO_WRITE_TABLE 에 쓸 수 있다 (psql 가지 · UPDATE=t · SELECT=t)"
        return
      fi
      if [ "$level" = soft ]; then
        hm "PO 의 역할이 $PO_WRITE_TABLE 에 **못 쓴다**(psql 가지 · UPDATE=f) — 🔵 되돌리기는 막지 않는다"
      else
        bad "🔴 PO 의 역할이 $PO_WRITE_TABLE 에 **못 쓴다**(psql 가지 · UPDATE=f) — 지금 운영이 고장나 있다는 뜻이다"
        doubt
      fi
      return ;;
  esac
  hm "PO 의 $PO_WRITE_TABLE 쓰기 권한을 **두 길 다 못 쟀다** — 🔵 이 배포를 막지는 않는다"
  say "🔴 $PO_APP_CN 가 도는지, 그 안에서 node 가 도는지, $AS_BOX 가 도는지 보세요."
}

# ══ 🔴 재고 관리 통로가 **값을 돌려주는가** (45~52번 것을 글자 그대로) ══
#   🔴 **빼지 않는다.** 이것은 **앱**이 쓰는 길이다.
#   🔴 「설정이 적혀 있다」가 아니라 **「물어보니 답한다」**로 잰다.
#   🔴 **머리말에 한글을 안 넣는다** — 한글을 HTTP 머리말에 넣으면 요청이 **아예 안
#      나가고**, 그 ✗ 가 진짜 결함처럼 보인다.
INV_PROBE='const b=(process.env.INVENTORY_API_BASE_URL||"").trim().replace(/\/+$/,"");
const t=(process.env.INVENTORY_API_TOKEN||"").trim();
if(b===""||t===""){console.log("NOCONF base="+(b===""?0:1)+" token="+(t===""?0:1));}
else{
const c=new AbortController();
const timer=setTimeout(function(){c.abort();},8000);
fetch(b+"/api/v1/parts",{method:"GET",headers:{Accept:"application/json",Authorization:"Bearer "+t},cache:"no-store",signal:c.signal})
.then(function(r){return r.json().catch(function(){return null;}).then(function(j){
var n=-1;
if(j&&typeof j==="object"&&Array.isArray(j.parts)){n=j.parts.length;}
console.log("HTTP "+r.status+" rows "+n);});})
.catch(function(e){var m=(e&&e.message)?String(e.message).split("\n")[0]:"error";console.log("FAIL "+((e&&e.name==="AbortError")?"timeout":m));})
.then(function(){clearTimeout(timer);});}'

inventory_gateway_check() { # 1 strict|soft
  local strict out line rows
  strict=0; [ "${1:-soft}" = strict ] && strict=1
  printf '\n    ── 재고 관리 통로가 값을 돌려주는가 (설정이 아니라 **답**으로 센다)\n'
  out=$("$DOCKER" exec "$AS_APP_CN" node -e "$INV_PROBE" 2>&1 | tr -d '\r')
  line=$(printf '%s\n' "$out" | grep -E '^(HTTP|NOCONF|FAIL)' | tail -1)
  say "받은 것: ${line:-못 쟀다}"
  case "${line:-}" in
    "HTTP 200 rows "*)
      rows=${line##* }
      if isnum "${rows:-}" && [ "${rows:-0}" -ge 1 ]; then
        ok "재고 관리가 답한다 — 200 · 부품 ${rows}줄"
      else
        hm "200 인데 부품 줄이 ${rows:-?} 이다 — 응답 모양이 기대와 다르다. 사람이 보세요"
        doubt
      fi ;;
    NOCONF*)
      say "🔴 **설정이 비어 있다.** 값은 안 찍는다 — 0 은 비었다는 뜻이다."
      say "   고칠 자리: $ENV_AS (root 600)"
      say "   이름 둘: INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN"
      if [ "$strict" = 1 ]; then
        bad "🔴 재고 관리 설정이 비어 **[사용부품] 칸이 막히고 [고장 부품]의 반출 몫이 빠진다**"
      else
        hm "재고 관리 설정이 비어 있다 — **이대로 --go 해도 반출 몫이 안 보인다**"
      fi ;;
    "")
      if [ "$strict" = 1 ]; then
        bad "🔴 재고 관리 통로를 **못 쟀다** — $AS_APP_CN 안에서 node 가 안 돌았다"
      else
        hm "재고 관리 통로를 못 쟀다 — $AS_APP_CN 가 도는지 보세요"
      fi
      printf '%s\n' "$out" | tail -8 | sed 's/^/      /' ;;
    *)
      say "🔴 답이 200 이 아니거나 아예 못 닿았다 — 401 이면 토큰, 404 면 주소,"
      say "   FAIL 이나 timeout 이면 망이거나 저쪽 상자다."
      if [ "$strict" = 1 ]; then
        bad "🔴 재고 관리가 안 답한다 — **[사용부품] 칸이 막히고 반출 몫이 빠진다.** 위 줄을 보세요"
      else
        hm "재고 관리가 안 답한다 — **이대로 --go 해도 반출 몫이 안 보인다**"
      fi
      printf '%s\n' "$out" | tail -8 | sed 's/^/      /'
      doubt ;;
  esac
}

# ══ 🔴 도구 이미지 안을 센다 — **집마다 다르게 잰다** ═════════════════
#   🔴 이 도구들은 평소에 안 뜬다. 안이 모자라도 **그날 아무 일이 안 일어나고**,
#      드러나는 것은 **쓸 일이 생긴 날**의 한 줄뿐이다.
#   🔴 **「✗ 가 아니면 ✓」로 세지 않는다.** ✓ 조건만 정확히 적고 나머지는 ? 다.
as_tools_inside_check() {
  local v got c pg pa pt pd rm_ rw rt cm cn
  printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$AS_TOOLS_NEW"
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/package.json: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "A/S tools 스테이지가 맞다" \
    || { bad "🔴 /app/package.json 이 없다 — **runner 를 구웠다.**"; doubt; }
  # ② 🔴 운영에서 불릴 npm 명령 일곱(41번의 자리).
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync procedures:export procedures:import db:preflight db:migrate; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "7" ] && ok "npm 명령 일곱이 이미지 안에 있다" \
    || { bad "🔴 명령이 ${got:-0}/7 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다.** db:migrate 가 없으면 적용 자체가 막힌다"; doubt; }
  # ③ 🔴 **공용 스키마가 새 판인가** — 0124 가 더하는 칸을 스키마가 알아야 한다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'f=/app/vendor/dss-core/src/schema/repair-case-approvals.ts; if [ -f "$f" ]; then echo "miss=0"; echo "n=$(grep -c domesticOrderId "$f")"; else echo "miss=1"; fi' 2>/dev/null | tr -d ' \r')
  printf '%s\n' "$v" | sed 's/^/      /'
  cm=$(printf '%s\n' "$v" | sed -n 's/^miss=//p'); cn=$(printf '%s\n' "$v" | sed -n 's/^n=//p')
  if [ "${cm:-1}" != "0" ]; then
    bad "🔴 이미지에 vendor/dss-core 의 그 스키마가 **없다** — Cannot find module 이 난다"; doubt
  elif [ "${cn:-0}" -ge 1 ] 2>/dev/null; then
    ok "공용 스키마가 **새 판이다** (domesticOrderId ${cn}번 — 0124 가 더하는 그 칸)"
  else
    bad "🔴 공용 스키마에 domesticOrderId 가 0번이다 — **옛 서브모듈이 담긴 이미지다.** 올리지 마세요"; doubt
  fi
  # ④ 🔴 소스가 이번 판인가 — 글자로 센다. 전부 기준판에 **0번**이었다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for pair in "DOMESTIC_ORDER_FINAL_SHIPMENT /app/src/lib/domain/shipment-approval-route.ts" "resolveMiscCaseCompletionGate /app/src/lib/domain/domestic-order-approval-rules.ts" "APPROVAL_REQUIRED /app/src/lib/db/mutations/domestic-orders.ts" "resolveDomesticOrderModelLink /app/src/lib/domain/domestic-order-detail-link.ts" "domesticOrderDetailHrefs /app/src/lib/domain/domestic-order-detail-tabs.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "5" ] && ok "이번 판의 이름 다섯이 이미지 안에 있다 (옛 판이 아니다)" \
    || { bad "🔴 이번 판의 이름이 ${got:-0}/5 개다 — **옛 판이 담긴 이미지다.** 올리지 마세요"; doubt; }
  # ⑤ 🔵 지난 판들이 올린 도구가 **아직 있는가** — 한 번 빼면 다시 넣는 사람이 없다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts /app/scripts/import-procedure-bundle.ts /app/scripts/export-procedure-bundle.ts /app/scripts/lib/procedure-template-bundle.ts /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "9" ] && ok "48~52번이 올린 도구 아홉이 다 들어 있다" \
    || bad "🔴 도구 파일이 ${got:-0}/9 개다 — scripts/ 가 온전히 안 담겼다"
  # ⑥ 🔴 갈래 셋을 **갈래마다 다르게** 센다(52번의 그 절 그대로).
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for f in /app/scripts/import-technical-task-procedures.ts /app/scripts/link-technical-task-next-procedures.ts; do if grep -q checkDevelopmentWriteTarget "$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "2" ] && ok "갈래 ㄱ — 엑셀 읽개 둘이 개발 DB 자물쇠를 부른다 (NAS 에서 부르면 막힌다)" \
    || { bad "🔴 갈래 ㄱ — 자물쇠를 부르는 것이 ${got:-0}/2 개다. **운영 DB 에 쓸 수 있는 판이다.** 올리지 마세요"; doubt; }
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'f=/app/scripts/import-procedure-bundle.ts; for pair in "guard:checkDevelopmentWriteTarget" "apply:process.env.APPLY" "tx:db.transaction" "target:formatDatabaseTarget"; do k=${pair%%:*}; s=${pair#*:}; n=$(grep -cF "$s" "$f" 2>/dev/null); echo "$k=$n"; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  pg=$(printf '%s\n' "$v" | sed -n 's/^guard=//p'); pa=$(printf '%s\n' "$v" | sed -n 's/^apply=//p')
  pt=$(printf '%s\n' "$v" | sed -n 's/^tx=//p');    pd=$(printf '%s\n' "$v" | sed -n 's/^target=//p')
  if [ "${pg:-x}" = "0" ] && [ "${pa:-0}" -ge 1 ] 2>/dev/null && [ "${pt:-0}" -ge 1 ] 2>/dev/null && [ "${pd:-0}" -ge 1 ] 2>/dev/null; then
    ok "갈래 ㄴ — import-procedure-bundle 가 **운영용 모양 그대로**다 (자물쇠 0 · APPLY · 트랜잭션 · 대상 DB 찍기)"
  else
    bad "🔴 갈래 ㄴ — 자물쇠 ${pg:-?}(기대 0) · APPLY ${pa:-?} · 트랜잭션 ${pt:-?} · 대상DB ${pd:-?} (셋은 1 이상)"
    doubt
  fi
  # 🔴 「grep -c」 는 0 일 때 종료 코드 1 을 낸다. 「|| echo ?」 를 달면 **하필
  #    바라던 0 에서만** 터진다. 파일 없음과 0번을 **갈래로** 가른다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'f=/app/scripts/export-procedure-bundle.ts; if [ -f "$f" ]; then echo "miss=0"; echo "w=$(grep -cE "\.insert\(|\.update\(|\.delete\(" "$f")"; echo "t=$(grep -c "transaction" "$f")"; else echo "miss=1"; fi' 2>/dev/null | tr -d ' \r')
  printf '%s\n' "$v" | sed 's/^/      /'
  rm_=$(printf '%s\n' "$v" | sed -n 's/^miss=//p'); rw=$(printf '%s\n' "$v" | sed -n 's/^w=//p'); rt=$(printf '%s\n' "$v" | sed -n 's/^t=//p')
  if [ "${rm_:-1}" != "0" ]; then
    bad "🔴 갈래 ㄷ — export-procedure-bundle.ts 가 **이미지 안에 없다**"; doubt
  elif [ "${rw:-x}" = "0" ] && [ "${rt:-x}" = "0" ]; then
    ok "갈래 ㄷ — export-procedure-bundle 는 읽기만 한다 (쓰는 문장 0 · 트랜잭션 0)"
  else
    bad "🔴 갈래 ㄷ — 쓰는 문장 ${rw:-?}번 · 트랜잭션 ${rt:-?}번이다. **읽기 전용이 아니다**"; doubt
  fi
  # ⑦ tsx 가 있는가 — 이 도구는 tsx 로만 돈다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/node_modules/tsx: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "A/S 도구에 tsx 가 있다" \
    || bad "🔴 tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다"
  # ⑧ 🔴 **값으로 받아 본다** — npm 으로 실제로 부른다. DATABASE_URL 을 안 준다.
  #    🔴 'node …' 가 아니라 **'npm run …'** 이어야 Missing script 가 드러난다.
  for c in check:due-date-inverted procedures:import; do
    v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "cd /app && npm run $c 2>&1 | head -40" 2>&1 | tr -d '\r')
    if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
      bad "🔴 npm run $c — **Missing script** (41번과 같은 실패다. 이 이미지의 package.json 이 옛 판이다)"
      printf '%s\n' "$v" | head -20 | sed 's/^/      /'
    elif printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
      ok "npm run $c 가 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)"
    elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
      bad "🔴 npm run $c 가 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다"
      printf '%s\n' "$v" | head -20 | sed 's/^/      /'
    else
      hm "npm run $c 의 답이 기대와 다르다 — 아래 20줄을 사람이 보세요"
      printf '%s\n' "$v" | head -20 | sed 's/^/      /'
    fi
  done
}

auth_tools_inside_check() {
  local v got ds dj kn mn
  printf '\n    ── %s 안을 센다 (겉이 아니라 결과 · 🔴 14판 만에 갈아 끼우는 상자다)\n' "$AUTH_TOOLS_NEW"
  v=$("$DOCKER" run --rm --entrypoint sh "$AUTH_TOOLS_NEW" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/package.json: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "포털 tools 스테이지가 맞다" \
    || { bad "🔴 /app/package.json 이 없다 — **runner 를 구웠다.**"; doubt; }
  # ② 🔴 **포털 drizzle 은 이미지 안에서 돈다** — A/S 와 반대다(39번 기록).
  #    비어 있으면 다음 판의 포털 마이그레이션이 **조용히 0건**이 된다.
  #    🔵 상자를 둘 띄운다 — 한 줄에 몰면 sh -c 안에서 따옴표가 세 겹이 된다.
  ds=$("$DOCKER" run --rm --entrypoint sh "$AUTH_TOOLS_NEW" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  dj=$("$DOCKER" run --rm --entrypoint sh "$AUTH_TOOLS_NEW" -c "grep -o idx /app/drizzle/meta/_journal.json 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  say "/app/drizzle — .sql ${ds:-?}장 · idx ${dj:-?}개 (기대 $AUTH_MIG_KEEP · $AUTH_MIG_KEEP)"
  if [ "${ds:-0}" = "$AUTH_MIG_KEEP" ] && [ "${dj:-0}" = "$AUTH_MIG_KEEP" ]; then
    ok "포털 도구 안의 drizzle 이 $AUTH_MIG_KEEP 이다 (개발 PC 와 같다)"
  else
    bad "🔴 포털 도구 안이 .sql ${ds:-?} · idx ${dj:-?} 다 — 둘 다 $AUTH_MIG_KEEP 여야 한다"
    doubt
  fi
  # ③ 🔴 39번이 연 **비상구 둘** — 이번 판의 까닭은 아니지만 **빼지 않는다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$AUTH_TOOLS_NEW" -c 'for f in /app/scripts/promote-admin.ts /app/scripts/create-emergency-admin.ts /app/scripts/purge-expired.ts /app/scripts/send-approval-mails.ts /app/scripts/check-notifications.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "5" ] && ok "비상구 둘 · 야간 정리 하나 · 메일 하나 · 진단 하나가 다 들어 있다" \
    || { bad "🔴 다섯 중 ${got:-0}개만 들어 있다 — scripts/ 가 온전히 안 담겼다. **야간 정리가 그날 멈춘다**"; doubt; }
  # ④ 🔴 **이번 판인가 — 글자로 센다.** 기준판 52cbb19 에는 0번이었다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AUTH_TOOLS_NEW" -c 'f=/app/src/lib/approvals/kinds.ts; n=$(grep -c DOMESTIC_ORDER_FINAL_SHIPMENT "$f" 2>/dev/null); echo "k=$n"' 2>/dev/null | tr -d ' \r')
  kn=$(printf '%s\n' "$v" | sed -n 's/^k=//p')
  say "kinds.ts 의 DOMESTIC_ORDER_FINAL_SHIPMENT: ${kn:-?}번 (기대 1 이상 · 기준판은 0)"
  if [ "${kn:-0}" -ge 1 ] 2>/dev/null; then
    ok "포털 도구가 **새 갈래를 아는 판**이다 (결재 메일 표에 기타건이 올라가 있다)"
  else
    bad "🔴 kinds.ts 에 그 글자가 0번이다 — **옛 판이 담긴 이미지다.** 올리지 마세요"
    doubt
  fi
  v=$("$DOCKER" run --rm --entrypoint sh "$AUTH_TOOLS_NEW" -c 'f=/app/src/lib/notifications/merge.ts; n=$(grep -cF "count: items.length" "$f" 2>/dev/null); echo "m=$n"' 2>/dev/null | tr -d ' \r')
  mn=$(printf '%s\n' "$v" | sed -n 's/^m=//p')
  say "merge.ts 의 줄 수 세기: ${mn:-?}번 (기대 1 이상 · 기준판은 0)"
  [ "${mn:-0}" -ge 1 ] 2>/dev/null && ok "배지를 **줄 수로** 세는 판이 담겼다 (check:notify 가 새 잣대로 센다)" \
    || bad "🔴 merge.ts 가 옛 판이다 — check:notify 가 옛 잣대로 센다"
  # ⑤ tsx 가 있는가
  v=$("$DOCKER" run --rm --entrypoint sh "$AUTH_TOOLS_NEW" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/node_modules/tsx: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "포털 도구에 tsx 가 있다" \
    || bad "🔴 tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다"
  # ⑥ 🔴 **이미지 안 node 가 --env-file-if-exists 를 아는가** — 39번이 재던 그 줄.
  #    모르면 비상구 둘이 **쓸 일이 생긴 날** 그 자리에서 죽는다.
  v=$("$DOCKER" run --rm --entrypoint node "$AUTH_TOOLS_NEW" --env-file-if-exists=/nonexistent.env -e "console.log('FLAG_OK')" 2>&1 | tr -d '\r' | tail -1)
  say "node --env-file-if-exists=<없는 파일> → ${v:-없음} (기대 FLAG_OK)"
  [ "${v:-}" = "FLAG_OK" ] && ok "이미지 안 node 가 그 깃발을 안다 (비상구 둘이 산다)" \
    || { bad "🔴 FLAG_OK 가 아니다 — node 가 그 깃발을 모른다. 비상구가 또 죽는다"; doubt; }
  # ⑦ 🔴 **값을 받아 본다** — 비상구를 npm 으로 부른다. 인자를 안 주면 쓰는 법만 찍는다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AUTH_TOOLS_NEW" -c "cd /app && npm run admin:promote 2>&1 | head -40" 2>&1 | tr -d '\r')
  if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
    bad "🔴 npm run admin:promote — **Missing script**. 비상구를 올려도 못 부른다"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
  elif printf '%s' "$v" | grep -qE 'Cannot find module|ERR_MODULE_NOT_FOUND'; then
    bad "🔴 npm run admin:promote 가 모듈을 못 찾는다 — 담긴 것이 모자란다"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
  else
    ok "npm run admin:promote 가 Missing script 없이 섰다 (아래 끝 6줄)"
    printf '%s\n' "$v" | tail -6 | sed 's/^/      /'
  fi
}

# ══ 🔴 연락서 폴더가 **실제로 열리는가** — 줄이 아니라 결과 ══════════
kyosan_folder_check() {
  local out src conv good
  good=1
  printf '\n    ── 연락서 폴더가 실제로 열리는가 (줄이 아니라 결과)\n'
  out=$(dct run --rm -T "$AS_TOOLS_SVC" sh -c 'ls /kyosan-src 2>/dev/null | wc -l; ls /kyosan-converted 2>/dev/null | wc -l' 2>&1 | tr -d ' \r')
  src=$(printf '%s\n' "$out"  | grep -E '^[0-9]+$' | sed -n 1p)
  conv=$(printf '%s\n' "$out" | grep -E '^[0-9]+$' | sed -n 2p)
  say "$KYO_SRC ${src:-못 쟀다}장 (기대 $KYO_SRC_MIN 이상 · 2026-10-28 실측 673)"
  if isnum "${src:-}" && [ "${src:-0}" -ge "$KYO_SRC_MIN" ]; then ok "$KYO_SRC 가 열린다 (${src}장)"
  elif [ "${src:-}" = "0" ]; then bad "🔴 $KYO_SRC 가 **비었다** — 볼륨 줄은 있는데 안 열린다"; good=0
  else hm "$KYO_SRC 가 ${src:-못 쟀다} 다 — $KYO_SRC_MIN 이상을 기대했다. 사람이 보세요"; good=0; fi
  say "$KYO_CONV ${conv:-못 쟀다}장 (기대 $KYO_CONV_MIN 이상 · 2026-10-28 실측 143)"
  if isnum "${conv:-}" && [ "${conv:-0}" -ge "$KYO_CONV_MIN" ]; then ok "$KYO_CONV 가 열린다 (${conv}장)"
  elif [ "${conv:-}" = "0" ]; then bad "🔴 $KYO_CONV 가 **비었다** — 볼륨 줄은 있는데 안 열린다"; good=0
  else hm "$KYO_CONV 가 ${conv:-못 쟀다} 다 — $KYO_CONV_MIN 이상을 기대했다. 사람이 보세요"; good=0; fi
  if [ "$good" != 1 ]; then
    say "── 받은 것 그대로 (끝 12줄)"
    printf '%s\n' "$out" | tail -12 | sed 's/^/      /'
    say "🔵 이 줄은 **앱 교체와 무관하다 — 되돌리지 마세요.**"
  fi
}

# ══ 🔴 발주서 공유폴더가 **열리는가** — 이번 판에 쓰는 자리가 하나 늘었다 ══
#   🔵 수리 건 상세의 [발주서] 탭이 2026-10-12 부터 쓰던 자리다. 이번 판에
#      **기타건 상세의 [발주서] 탭**이 같은 폴더를 읽는다.
#   🔴 **기대값을 박지 않는다** — 그 폴더의 장수를 아무도 재 본 적이 없다.
#      0 이면 ✗(볼륨 줄은 있는데 안 열린다 — 제일 조용한 실패), 1 이상이면 수를 찍는다.
purchase_order_archive_check() {
  local n
  printf '\n    ── 발주서 공유폴더가 열리는가 (🔵 이번 판에 기타건 탭이 같은 자리를 읽는다)\n'
  n=$("$DOCKER" exec "$AS_APP_CN" sh -c "ls $PO_ARCHIVE 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  say "$AS_APP_CN 안에서 본 $PO_ARCHIVE 의 항목 ${n:-못 쟀다}개"
  if ! isnum "${n:-}"; then
    hm "못 쟀다 — $AS_APP_CN 가 도는지 보세요. **빈 결과는 삼켜진 오류일 수 있다**"
  elif [ "${n:-0}" -ge 1 ]; then
    ok "발주서 폴더가 열린다 (${n}개) — 수리건 탭도 **기타건 탭도** 그 자리를 읽는다"
  else
    bad "🔴 발주서 폴더가 **비었다** — 볼륨 줄은 있는데 안 열린다. [발주서] 탭이 **조용히** 빈다"
    say "🔴 compose 의 app-as 볼륨(/purchase-order-archive)과 공유폴더 권한을 보세요."
    doubt
  fi
}

# ══ 🔴 후속 작업 둘을 **값으로** 센다 ═════════════════════════════════
#   🔴 **scope::text 로 비교한다.** enum 리터럴로 비교하면 적용 **전에는** 그 값이
#      없어 질의가 통째로 오류가 난다(invalid input value for enum). 그러면 빈
#      결과가 나오고 「0 이다」로 조용히 흘러간다.
# 🔵 **인자를 안 받는다.** 처음에는 strict/soft 로 가르려 했는데, 어느 단계에서나
#    할 말이 같다 — 「판이 0개면 기타건이 막힌다」는 배포 전에도 뒤에도 참이다.
#    🔴 쓰지도 않을 인자를 받으면 주석과 코드가 어긋난다. 그래서 뺐다.
followup_counts() {
  local r m pend
  printf '\n    ── 🔴 배포 뒤 사람이 해야 하는 일 둘 (값으로 센다)\n'
  r=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $AS_ROUTE_TABLE where scope::text='$AS_NEW_ENUM_VALUE'")
  say "① 기타건 최종 출하 승인 결재선 판: ${r:-못 쟀다}개"
  if [ -z "${r:-}" ]; then
    hm "결재선 판 수를 **못 쟀다** — $AS_BOX 가 도는지, 그 표가 있는지 보세요"
  elif [ "${r:-0}" -ge 1 ] 2>/dev/null; then
    ok "결재선 판이 ${r}개 있다 — **기타건 [완료] 처리가 선다**"
  else
    hm "결재선 판이 **0개다** — 🔴 **지금은 기타건을 아무도 [완료] 처리할 수 없습니다.**"
    say "🔴 [사용자 관리] › [승인 절차] 에서 「기타건 최종 출하 승인」을 **한 판 세우세요.**"
    say "   🔵 배포가 끝난 뒤에 하는 일입니다 — 이 줄은 **배포를 막지 않습니다.**"
  fi
  m=$(pgn "$AUTH_BOX" "$AUTH_DB" "select count(*) from $AUTH_MAIL_TABLE where client_id='$AUTH_MAIL_CLIENT' and kind='$AS_NEW_ENUM_VALUE' and enabled")
  say "② 포털 결재 알림 메일 스위치(켜짐): ${m:-못 쟀다}줄"
  if [ -z "${m:-}" ]; then
    hm "메일 스위치를 **못 쟀다** — $AUTH_BOX 가 도는지, $AUTH_MAIL_TABLE 이 있는지 보세요"
  elif [ "${m:-0}" -ge 1 ] 2>/dev/null; then
    ok "「기타건 최종 출하 결재」 메일이 **켜져 있다**"
  else
    say "🔵 아직 꺼져 있습니다(기본값 끔 — 2026-10-23 결정). **종과 통합 승인함은 뜹니다.**"
    say "   메일까지 받으려면 포털 관리자 화면 › 결재 알림 메일 에서 켜세요."
  fi
  # 🔵 **지금 막히는 기타건이 몇 건인가** — 사람이 급한지 가늠할 수 있게.
  pend=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from domestic_orders where repair_case_id is null and completed_at is null and is_deleted = false")
  say "🔵 지금 열려 있는 기타건(수리건 안 붙고 아직 완료 아님): ${pend:-못 쟀다}건"
  say "   🔴 결재선을 안 세우면 **그 ${pend:-?}건이 전부 [완료] 처리에서 막힙니다.**"
}

# ══════════════════════════════════════════════════════════════════════
# ── --count : 도구를 읽기만 해서 센다 + 후속 작업 둘 ──────────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **'--silent' 를 안 붙인다.** 붙이면 npm 의 로그 수위가 내려가 'Missing
#      script' 가 **안 찍힐 수 있고**, 그러면 아래 가지가 「못 쟀다」가 아니라
#      조용히 「건수가 안 보인다」로 흘러간다.
count_one() { # 1 npm 명령 2 사람이 부르는 이름
  local out rc
  printf '\n  ── %s  (npm run %s)\n' "$2" "$1"
  out=$(dct run --rm -T "$AS_TOOLS_SVC" npm run "$1" 2>&1)
  rc=$?
  out=$(printf '%s' "$out" | tr -d '\r')
  if printf '%s' "$out" | grep -qE 'Missing script|missing script'; then
    hm "$2 — **그 도구 이미지에 이 명령이 없다**(Missing script)"
    say "🔵 셋 다 :12 에도 :13 에도 있어야 한다 — 48번이 올려 두었고 이번 판에 안 줄었다."
    say "🔴 그러니 이 답은 **예상 밖**이다. compose 의 $AS_TOOLS_SVC 태그를 보세요."
    return
  fi
  if [ -z "${out:-}" ]; then
    hm "$2 — 아무것도 안 돌아왔다. **빈 결과는 삼켜진 오류일 수 있다** — 사람이 보세요"
    return
  fi
  printf '%s\n' "$out" | sed 's/^/      /'
  if [ "${rc:-1}" = "0" ]; then
    ok "$2 — 셌다 (위 수를 적어 두었다가 --go 뒤의 수와 견주세요)"
  else
    bad "🔴 $2 — 도구가 종료 코드 ${rc} 로 멈췄다. **세는 길과 뜨는 길이 갈라졌다는 뜻**이다"
    doubt
  fi
}

if [ "$MODE" = count ]; then
  printf '\n== 도구를 읽기만 해서 센다 + 후속 작업 둘\n'
  [ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
  printf '%s\n' "🔴 셋 다 **쓰는 모드가 없다.** DB 에 한 글자도 안 쓴다."
  CTL=$(img_line "$AS_TOOLS_SVC")
  if [ -n "${CTL:-}" ]; then
    printf '%s\n' "🔵 지금 compose 의 $AS_TOOLS_SVC 태그: $(tag_at "$CTL")  (${CTL}줄)"
  else
    printf '%s\n' "🔴 compose 에서 $AS_TOOLS_SVC 의 image: 줄을 못 찾았다 — 아래 수가 어느 판인지 모른다"
  fi
  printf '%s\n' "🔴 **이번 배포는 이 수들과 상관이 없습니다** — 기타건 기능과 결재 갈래 하나입니다."
  printf '%s\n' "   앞뒤가 같으면 정상이고, 다르면 **그 사이에 사람이 저장한 것**입니다."
  count_one check:target-shipment-missing "사내 목표 출하일 미등록"
  count_one check:due-date-inverted       "납기 역전"
  count_one check:requested-due-date-sync "납기요청일 ↔ 고객 요청 납기일 어긋남"
  # 🔴 후속 작업 둘 — 배포 뒤에 다시 부르면 **했는지 안 했는지**가 값으로 나온다.
  followup_counts
  # 🔵 52번 꼬리말에서 넘어온 할 일(절차 이관)이 끝났는지 **사람이 가르도록** 수를 찍는다.
  #    🔴 「끝났다/안 끝났다」를 이 스크립트가 판정하지 않는다 — 기준이 될 수가 없다.
  printf '\n  ── 🔵 절차 이관(52번 꼬리말에서 넘어온 할 일) — 사람이 가름\n'
  say "운영의 절차 수: $(pgn "$AS_BOX" "$AS_DB" 'select count(*) from procedure_templates')개"
  say "운영의 절차 노드 수: $(pgn "$AS_BOX" "$AS_DB" 'select count(*) from procedure_template_nodes')개"
  say "🔵 49번 기록의 짐은 **절차 25 · 노드 836** 이었습니다. 이미 넣으셨으면 건너뛰세요."
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 1. 지금 상태 ──────────────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
[ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
say "compose 줄 수 $(wc -l < "$CF") · image: 줄 $(grep -c '^ *image:' "$CF")개"

# ── ㄱ) 🔴 **운영이 지금 쓰는 태그 전부** — 저장소 사본을 믿지 않는다 ──
#   이 저장소의 compose 사본은 운영보다 뒤처진다(48번에 **세 줄**이 어긋나 있었다).
#   🔴 이번 판은 특히 그렇다 — 저장소 사본의 app-auth 는 **dss-auth:1.7** 이고
#      운영은 **2.0** 이어야 한다(39번이 올렸다). 그래서 **여기서 직접 읽는다.**
printf '\n    ── 운영 compose 의 image: 줄 전부 (이 파일이 진짜다)\n'
grep -n '^ *image:' "$CF" | sed 's/^/      /'
printf '\n    ── 지금 **도는** 컨테이너와 그 이미지 (compose 와 다를 수 있다)\n'
"$DOCKER" ps -a --format '{{.Names}} {{.Image}} {{.Status}}' 2>/dev/null | sort | sed 's/^/      /'

# ══════════════════════════════════════════════════════════════════════
# 🔴 1-ㄱ-2. **상태 변수를 먼저 정한다** — 그다음에 가지를 나눈다
# ══════════════════════════════════════════════════════════════════════
#   🔴 48번이 데인 자리다. 기대값을 한 갈래로 박아 두면 **적용 뒤에 다시 부를 때
#      가짜 ✗** 가 난다.
#   🔴 **이번 판은 갈래가 넷이다**(앱 둘 · 도구 둘). 열여섯 가지를 적지 않고
#      **「새 판인 것이 몇이냐」**로 센다.
AS_NEW_TAG=$(printf '%s\n' "$(rows)" | grep '^as|'   | head -1 | cut -d'|' -f4)
AS_OLD_TAG=$(printf '%s\n' "$(rows)" | grep '^as|'   | head -1 | cut -d'|' -f5)
AUTH_NEW_TAG=$(printf '%s\n' "$(rows)" | grep '^auth|' | head -1 | cut -d'|' -f4)
AUTH_OLD_TAG=$(printf '%s\n' "$(rows)" | grep '^auth|' | head -1 | cut -d'|' -f5)
# 🔵 표의 서비스 이름도 표에서 읽는다 — 두 벌로 적으면 한쪽만 고쳤을 때 어긋난다.
AS_SVC=$(printf '%s\n' "$(rows)" | grep '^as|'   | head -1 | cut -d'|' -f2)
AUTH_SVC=$(printf '%s\n' "$(rows)" | grep '^auth|' | head -1 | cut -d'|' -f2)

state_of() { # 1 지금 태그 2 옛 태그 3 새 태그 → OLD|NEW|ODD
  if   [ "${1:-}" = "$3" ]; then printf 'NEW'
  elif [ "${1:-}" = "$2" ]; then printf 'OLD'
  else printf 'ODD'; fi
}
APP_AS_L=$(img_line "$AS_SVC" 2>/dev/null || true)
APP_AUTH_L=$(img_line "$AUTH_SVC" 2>/dev/null || true)
AS_TOOLS_L=$(img_line "$AS_TOOLS_SVC" 2>/dev/null || true)
AUTH_TOOLS_L=$(img_line "$AUTH_TOOLS_SVC" 2>/dev/null || true)
APP_AS_TAG_NOW="";   [ -n "${APP_AS_L:-}" ]   && APP_AS_TAG_NOW=$(tag_at "$APP_AS_L")
APP_AUTH_TAG_NOW=""; [ -n "${APP_AUTH_L:-}" ] && APP_AUTH_TAG_NOW=$(tag_at "$APP_AUTH_L")
AS_TOOLS_TAG_NOW=""; [ -n "${AS_TOOLS_L:-}" ] && AS_TOOLS_TAG_NOW=$(tag_at "$AS_TOOLS_L")
AUTH_TOOLS_TAG_NOW=""; [ -n "${AUTH_TOOLS_L:-}" ] && AUTH_TOOLS_TAG_NOW=$(tag_at "$AUTH_TOOLS_L")
S_APP_AS=$(state_of   "$APP_AS_TAG_NOW"   "$AS_OLD_TAG"       "$AS_NEW_TAG")
S_APP_AUTH=$(state_of "$APP_AUTH_TAG_NOW" "$AUTH_OLD_TAG"     "$AUTH_NEW_TAG")
S_AS_TOOLS=$(state_of "$AS_TOOLS_TAG_NOW" "$AS_TOOLS_OLD"     "$AS_TOOLS_NEW")
S_AUTH_TOOLS=$(state_of "$AUTH_TOOLS_TAG_NOW" "$AUTH_TOOLS_OLD" "$AUTH_TOOLS_NEW")
printf '\n    ── 🔴 지금 단계(PHASE) — 넷을 각각 읽는다\n'
printf '      %-12s %-22s 옛 %-20s 새 %-20s → %s\n' "$AS_SVC"         "${APP_AS_TAG_NOW:-못 읽음}"   "$AS_OLD_TAG"   "$AS_NEW_TAG"   "$S_APP_AS"
printf '      %-12s %-22s 옛 %-20s 새 %-20s → %s\n' "$AUTH_SVC"       "${APP_AUTH_TAG_NOW:-못 읽음}" "$AUTH_OLD_TAG" "$AUTH_NEW_TAG" "$S_APP_AUTH"
printf '      %-12s %-22s 옛 %-20s 새 %-20s → %s\n' "$AS_TOOLS_SVC"   "${AS_TOOLS_TAG_NOW:-못 읽음}" "$AS_TOOLS_OLD" "$AS_TOOLS_NEW" "$S_AS_TOOLS"
printf '      %-12s %-22s 옛 %-20s 새 %-20s → %s\n' "$AUTH_TOOLS_SVC" "${AUTH_TOOLS_TAG_NOW:-못 읽음}" "$AUTH_TOOLS_OLD" "$AUTH_TOOLS_NEW" "$S_AUTH_TOOLS"
# 🔴 **「새 판인 것이 몇이냐」로 센다** — 열여섯 가지를 적지 않는다.
NNEW=0; NOLD=0; NODD=0
for s in "$S_APP_AS" "$S_APP_AUTH" "$S_AS_TOOLS" "$S_AUTH_TOOLS"; do
  case "$s" in (NEW) NNEW=$((NNEW+1));; (OLD) NOLD=$((NOLD+1));; (*) NODD=$((NODD+1));; esac
done
PHASE=ODD
if   [ "$NOLD" = "4" ]; then PHASE=PRE
elif [ "$NNEW" = "4" ]; then PHASE=POST
elif [ "$S_APP_AS" = OLD ] && [ "$S_APP_AUTH" = OLD ] && [ "$S_AS_TOOLS" = NEW ] && [ "$S_AUTH_TOOLS" = NEW ]; then PHASE=MID
fi
say "새 판 ${NNEW} · 옛 판 ${NOLD} · 그 밖 ${NODD}  → PHASE=$PHASE"
case "$PHASE" in
  PRE)  ok "PHASE=PRE — 아직 아무것도 안 갈아 끼웠다 (--preload → --migrate → --go 차례)" ;;
  MID)  ok "PHASE=MID — 도구 둘만 새 판이다. --migrate 까지 돌았거나 --rollback 으로 앱만 되돌렸다" ;;
  POST) ok "PHASE=POST — 넷 다 새 판이다. --go 까지 돌았다" ;;
  *)    hm "PHASE=ODD — 넷이 섞여 있다. **--go 가 도중에 멈췄거나 운영이 따로 움직였다.** 위 표를 보세요"
        say "🔴 **이 저장소의 compose 사본을 믿고 적은 값이 아니다** — README 의 기준 SHA 표와"
        say "   36번(39-deploy.sh) 기록을 맞대어 얻은 값이다. 그래도 어긋났다면 운영이 그 사이"
        say "   따로 움직였다는 뜻이다. **고치지 말고 알리세요.**" ;;
esac
# 🔴 **모드마다 서 있어야 하는 PHASE 가 다르다.** 여기서 한 번만 가른다.
case "$MODE" in
  rollback)
    case "$PHASE" in
      POST) ok "되돌릴 준비가 됐다 (PHASE=POST)" ;;
      MID)  hm "앱 둘이 이미 옛 판이다 (PHASE=MID — 벌써 되돌렸나)" ;;
      *)    hm "PHASE=$PHASE 에서 되돌리기를 부르셨다 — 🔵 막지는 않는다. 위 표를 보세요" ;;
    esac ;;
  go)
    case "$PHASE" in
      PRE)  ok "갈아 끼울 준비가 됐다 (PHASE=PRE — image: 줄 **넷**이 달라질 것이다)" ;;
      MID)  ok "갈아 끼울 준비가 됐다 (PHASE=MID — --migrate 가 도구 둘을 먼저 바꿨다. image: 줄 **둘**만 달라질 것이다)" ;;
      POST) hm "이미 POST 다 — 다시 돌리는 중인가. 🔵 막지 않는다(다시 띄우면 그만이다)" ;;
      *)    hm "PHASE=$PHASE 다 — 위 표를 보고 사람이 판단하세요" ;;
    esac ;;
  *)
    case "$PHASE" in
      PRE|MID|POST) ok "PHASE=$PHASE — $MODE 에서 설 수 있는 단계다" ;;
      *)            hm "PHASE=$PHASE 다 — $MODE 는 막지 않지만 사람이 보세요" ;;
    esac ;;
esac

# 🔴 **compose 의 태그와 실제로 도는 이미지가 같은가** — 줄만 고치고 다시 안
#    띄운 경우가 있다. 그때는 교체가 「아무 일도 안 한 것처럼」 보인다.
SITES_SEEN=0
for r in $(rows); do
  SITES_SEEN=$((SITES_SEEN+1))
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3)
  L=$(img_line "$SVC" 2>/dev/null || true)
  CURTAG=""; [ -n "${L:-}" ] && CURTAG=$(tag_at "$L")
  ST=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  printf '\n    ── %s\n' "$SVC"
  say "$SVC — ${L:-?}줄 · compose ${CURTAG:-?} · 도는 것 ${RUN:-없음} (${ST:-?})"
  if [ -z "${RUN:-}" ]; then
    hm "$CN 가 안 뜬 것 같다 — Config.Image 를 못 읽었다"
  elif [ "$RUN" = "$CURTAG" ]; then
    ok "$CN 가 compose 에 적힌 그 태그로 돈다 ($RUN)"
  else
    hm "$CN 는 $RUN 로 도는데 compose 는 $CURTAG 라고 적는다 — 줄만 고치고 안 띄운 상태다"
    say "🔵 **교체를 막지 않는다** — --go 가 어차피 다시 띄운다. 다만 되돌릴 때 기준이 흔들린다."
  fi
done
# 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다 — 앱 **둘**을 봤는가.
[ "$SITES_SEEN" = "$SITES_WANT" ] && ok "다시 띄울 앱 ${SITES_WANT}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "🔴 앱을 ${SITES_SEEN}개만 봤다 — ${SITES_WANT}개를 기대했다. SITES 표가 깨졌다"

# ══ 🔴 PO — **이번엔 안 갈아 끼운다.** 그래도 「그대로 도는가」는 본다 ══
printf '\n    ── app-po (이번에 **안 건드린다**)\n'
PL=$(img_line app-po 2>/dev/null || true)
if [ -n "${PL:-}" ]; then
  PCUR=$(tag_at "$PL")
  PRUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$PO_APP_CN" 2>/dev/null)
  PST=$("$DOCKER" inspect -f '{{.State.Status}}' "$PO_APP_CN" 2>/dev/null)
  say "app-po — ${PL}줄 · compose ${PCUR} · 도는 것 ${PRUN:-없음} (${PST:-?})"
  if [ "$PCUR" = "$PO_WANT_TAG" ]; then
    ok "app-po 가 $PO_WANT_TAG 다 (49번이 올린 그 판 · 이번에 안 건드린다)"
  else
    hm "app-po 가 $PCUR 다 — $PO_WANT_TAG 를 기대했다. **이 배포를 막지 않는다**. 사람이 보세요"
  fi
  say "🔴 5절은 이 줄을 **안 고친다** — 달라진 image: 줄 수로 그것을 확인한다."
else
  bad "compose 에 app-po 가 없다 — 지금까지 있던 것이다. 사람이 보세요"
fi

# ══ 🔴 도구 둘 — 볼륨 줄이 제자리인가 ════════════════════════════════
printf '\n    ── %s 의 볼륨\n' "$AS_TOOLS_SVC"
if [ -n "${AS_TOOLS_L:-}" ]; then
  # 🔴 볼륨이 제 자리에 붙는가 — 여기가 어긋나면 **0124 가 엉뚱한 것을 읽는다.**
  if svc_block "$AS_TOOLS_SVC" | grep -q "$MIGDIR:$IMG_MIGDIR"; then
    ok "$AS_TOOLS_SVC 가 $MIGDIR 를 $IMG_MIGDIR 로 붙인다 (🔴 0124 가 거기서 돈다)"
  else
    bad "🔴 $AS_TOOLS_SVC 의 drizzle 볼륨이 $MIGDIR 가 아니다 — **적용이 엉뚱한 폴더를 읽는다**"
    doubt
  fi
  for kv in "$KYO_SRC" "$KYO_CONV"; do
    if svc_block "$AS_TOOLS_SVC" | grep -q "$kv"; then
      ok "$AS_TOOLS_SVC 에 $kv 볼륨 줄이 있다 (연락서를 이식할 때 읽을 자리)"
    else
      hm "$AS_TOOLS_SVC 에 $kv 볼륨 줄이 **없다** — 🔵 교체는 막지 않는다"
      say "🔴 **이대로면 다음 연락서 이식이 못 돈다.**"
    fi
  done
  if svc_block "$AS_TOOLS_SVC" | grep -q "$TPLDIR:$TPL_IN_CONTAINER"; then
    say "🔵 $AS_TOOLS_SVC 에 양식 볼륨이 **생겼다** — 지금까지 없던 것이다(해롭지 않다)"
  else
    say "🔵 $AS_TOOLS_SVC 에 양식 볼륨이 없다 (지금 상태가 그렇다 — 그래서 양식은 호스트에서 잰다)"
  fi
else
  bad "compose 에 $AS_TOOLS_SVC 가 없다 — 올릴 자리가 없다"
fi
# 🔴 **포털 도구가 제 DB 를 보는가** — 39번이 재던 그 줄이다. 어긋나면 **엉뚱한
#    서버에 붙는다.** 🔵 이번 판에 포털 DB 를 안 건드리지만, 야간 정리가 그 길로 돈다.
printf '\n    ── %s (🔴 14판 만에 갈아 끼우는 상자다)\n' "$AUTH_TOOLS_SVC"
if [ -n "${AUTH_TOOLS_L:-}" ]; then
  if svc_block "$AUTH_TOOLS_SVC" | grep -q "$AUTH_BOX"; then
    ok "$AUTH_TOOLS_SVC 가 $AUTH_BOX 를 본다"
  else
    bad "🔴 $AUTH_TOOLS_SVC 가 $AUTH_BOX 를 안 본다 — **엉뚱한 서버에 붙는다**"
    doubt
  fi
  if svc_block "$AUTH_TOOLS_SVC" | grep -q 'profiles'; then
    ok "$AUTH_TOOLS_SVC 에 profiles 줄이 있다 (평소에 안 뜬다 — 태그를 고쳐도 직원이 못 느낀다)"
  else
    hm "$AUTH_TOOLS_SVC 에 profiles 줄이 없다 — 🔵 막지 않지만, up -d 에 따라 떠 버릴 수 있다"
  fi
else
  bad "compose 에 $AUTH_TOOLS_SVC 가 없다 — **비상구와 야간 정리를 부를 길이 없다**"
fi
# 🔴 PO 쪽 — **도구 서비스가 없는 것이 맞다**
if img_line tools-po >/dev/null 2>&1; then
  hm "compose 에 tools-po 가 **생겼다** — 지금까지 없던 것이다. 이 배포의 범위 밖이니 사람이 보세요"
else
  ok "compose 에 tools-po 가 없다 (없는 것이 맞다 — PO 에는 NAS 에서 돌릴 스크립트가 없다)"
fi

# ── 1-ㄴ. 🔴 설정 파일 — 중복 키와 auto (값은 안 찍는다) ──────────────
printf '\n    ── 설정 파일 (이름만 본다. 값도, 값의 길이도 안 찍는다)\n'
env_file_check() { # 1 파일 2 사람이 부르는 이름
  local f n dup
  f=$1
  if [ ! -f "$f" ]; then
    hm "$2 — 파일이 없다: $f (못 쟀다)"
    return
  fi
  n=$(grep -cE '^[A-Za-z_][A-Za-z0-9_]*=' "$f" 2>/dev/null || true)
  if ! isnum "${n:-}" || [ "${n:-0}" -eq 0 ]; then
    hm "$2 — 이름=값 꼴의 줄이 ${n:-못 쟀다}개다. **빈 결과는 삼켜진 오류일 수 있다** — 사람이 보세요"
    return
  fi
  say "$2 — 이름=값 줄 ${n}개 (값은 안 찍는다)"
  dup=$(grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' "$f" 2>/dev/null | sed 's/=$//' | sort | uniq -d)
  if [ -z "${dup:-}" ]; then
    ok "$2 에 같은 이름이 두 번 적힌 줄이 없다"
  else
    hm "$2 에 **같은 이름이 두 번** 적혀 있다 — 🔴 **아래 줄이 이긴다.** 이름만 찍는다:"
    printf '%s\n' "$dup" | head -10 | sed 's/^/      /'
    say "🔵 이 판은 설정을 안 바꾼다 — **배포를 막지 않는다.** 다음에 그 파일을 고칠 때의 함정이다."
  fi
}
# 🔴 컨테이너 안에서 auto 는 172.x 가 된다 — 이름이 있고 auto 가 아니어야 한다.
env_auto_check() { # 1 파일 2 사람이 부르는 이름 3 환경변수 이름
  local f v q
  f=$1
  if [ ! -f "$f" ]; then hm "$2 의 $3 — 파일이 없어 못 쟀다"; return; fi
  # 🔴 값은 **안 찍는다.** auto 인지 아닌지만 본다.
  # 🔴 같은 이름이 두 줄이면 **아래가 이긴다** — 그래서 tail -1 이다.
  v=$(grep -E "^$3=" "$f" 2>/dev/null | tail -1 | cut -d= -f2-)
  v=$(printf '%s' "$v" | tr -d '\r')
  q=$(printf '%s' "'")
  v=${v#\"}; v=${v%\"}
  v=${v#"$q"}; v=${v%"$q"}
  v=${v# }; v=${v% }
  if [ -z "${v:-}" ]; then
    bad "$2 에 $3 가 없거나 비었다 — 앱이 뜨면서 던진다"
    return
  fi
  case "$v" in
    auto|auto:*)
      bad "🔴 $2 의 $3 가 **auto** 다 — 컨테이너 안에서 172.x 로 풀려 **로그인이 돌아오지 못한다.** 고정 주소를 적으세요"
      doubt ;;
    *)
      ok "$2 의 $3 가 고정값이다 (auto 가 아니다 — 값은 안 찍는다)" ;;
  esac
}
env_file_check "$ENV_NAS"  ".env.nas"
env_file_check "$ENV_AS"   "env/as.env"
env_file_check "$ENV_AUTH" "env/auth.env"
env_file_check "$ENV_PO"   "env/po.env"
env_auto_check "$ENV_AS" "env/as.env" SSO_ISSUER
env_auto_check "$ENV_AS" "env/as.env" SSO_REDIRECT_URI
env_auto_check "$ENV_PO" "env/po.env" SSO_ISSUER
env_auto_check "$ENV_PO" "env/po.env" SSO_REDIRECT_URI
say "🔵 **이 판은 설정 파일을 하나도 안 바꾼다** — 🔴 **이번 범위에 늘어난"
say "   process.env 이름이 0개다**(2026-11-07 실측 · A/S 도 포털도). 52번은 APPLY"
say "   하나가 늘었다고 적었는데 **그것은 52번 판에 이미 들어왔다.**"
say "🔵 PURCHASE_ORDER_ARCHIVE_DIR 도 **이미 있는 이름**이다(17번 · 2026-10-12)."
say "   이번 판의 기타건 [발주서] 탭이 **같은 이름·같은 볼륨**을 읽는다 — 더할 것이 없다."

# ── 1-ㄷ. 🔵 **양식** — 재기만 한다 (이번 판은 올릴 것이 0장) ─────────
templates_check

# ── 1-ㄹ. 🔴 **PO 가 repair_cases 에 쓸 수 있는가** ───────────────────
case "$MODE" in
  rollback) po_write_privilege_check soft ;;
  *)        po_write_privilege_check warnmiss ;;
esac

# ── 1-ㅁ. 🔵 발주서 공유폴더 — 이번 판에 읽는 자리가 하나 늘었다 ──────
purchase_order_archive_check

# ── 2. 🔴 DB — **이번 판은 앞뒤가 다르다** (124 → 125) ────────────────
#   🔵 A/S 와 PO 가 같은 dss_as 를 본다. 포털은 dss_auth 를 따로 본다.
#   🔴 **52번의 한 갈래(124)를 그대로 베끼면 안 된다** — 이 판은 적용 전 124 ·
#      적용 뒤 125 다. 한 갈래로 두면 **적용이 0건으로 끝난 것을 ✓ 로 읽는다.**
printf '\n== 2. DB (dss_as · A/S 와 PO 가 함께 쓴다)\n'
say "🔵 이 판은 마이그레이션 **1건**이다 — 기대값이 **두 갈래**다(적용 전 $AS_MIG_BEFORE · 적용 뒤 $AS_MIG_AFTER)."
MIG_AS0=$(mig_count "$AS_BOX" "$AS_DB")
say "기록 ${MIG_AS0:-?}"
if [ -z "${MIG_AS0:-}" ]; then
  bad "DB 를 못 쟀다 — $AS_BOX 가 도는지 보세요"
  doubt
elif [ "$MIG_AS0" = "$AS_MIG_AFTER" ]; then
  ok "$AS_MIG_AFTER 다 — **--migrate 가 이미 돌았다**(0124 가 적용됐다)"
elif [ "$MIG_AS0" = "$AS_MIG_BEFORE" ]; then
  ok "$AS_MIG_BEFORE 다 — **아직 --migrate 전이다**(48번이 올린 그대로)"
else
  bad "🔴 ${MIG_AS0} 이다 — $AS_MIG_BEFORE 나 $AS_MIG_AFTER 여야 한다. 다른 배포가 먼저 돌았거나 전제가 깨졌다"
  doubt
fi
# 🔴 포털 DB 는 **그대로여야** 한다 — 이 배포가 한 글자도 안 바꾼다.
MIG_AU0=$(mig_count "$AUTH_BOX" "$AUTH_DB")
say "포털 기록 ${MIG_AU0:-?} (기대 $AUTH_MIG_KEEP 그대로)"
if [ -z "${MIG_AU0:-}" ]; then
  bad "포털 DB 를 못 쟀다 — $AUTH_BOX 가 도는지 보세요"
  doubt
elif [ "$MIG_AU0" = "$AUTH_MIG_KEEP" ]; then
  ok "포털이 $AUTH_MIG_KEEP 이다 — **이 배포는 포털 DB 를 안 건드린다**(마이그레이션 0건)"
else
  bad "🔴 포털이 ${MIG_AU0} 이다 ($AUTH_MIG_KEEP 이어야 한다) — 이 배포는 포털 마이그레이션을 **돌릴 길이 없다**"
  doubt
fi

# ── 2-ㄴ. 🔴 **0124 가 만드는 것** — 적용 전/뒤로 갈래를 나눈다 ───────
#   🔴 「기록이 125 다」와 「그 칸과 제약이 정말 있다」는 다른 말이다.
#   🔴 **적용 전에 0 인 것이 정상**이고, 적용 뒤에 9 여야 한다. 한 갈래로 재면
#      적용 전 --check 에서 **가짜 ✗ 가 아홉 개** 난다.
printf '\n    ── 0124 가 만드는 아홉 (적용 전 0 · 적용 뒤 9)\n'
E1=$(has_enum_value  "$AS_BOX" "$AS_DB" "$AS_NEW_ENUM1" "$AS_NEW_ENUM_VALUE")
E2=$(has_enum_value  "$AS_BOX" "$AS_DB" "$AS_NEW_ENUM2" "$AS_NEW_ENUM_VALUE")
NC=$(has_column      "$AS_BOX" "$AS_DB" "$AS_NEW_COL_TABLE" "$AS_NEW_COL")
I1=$(has_index       "$AS_BOX" "$AS_DB" "$AS_NEW_IDX1")
I2=$(has_index       "$AS_BOX" "$AS_DB" "$AS_NEW_IDX2")
K0=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_NEW_FK")
K1=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_NEW_CK1")
K2=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_NEW_CK2")
K3=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_REDO_CK1")
NEW_SEEN=0; NEW_OK=0
for pair in "enum $AS_NEW_ENUM1 ${E1:-}" "enum $AS_NEW_ENUM2 ${E2:-}" \
            "col $AS_NEW_COL_TABLE.$AS_NEW_COL ${NC:-}" \
            "idx $AS_NEW_IDX1 ${I1:-}" "idx $AS_NEW_IDX2 ${I2:-}" \
            "fk $AS_NEW_FK ${K0:-}" "check $AS_NEW_CK1 ${K1:-}" \
            "check $AS_NEW_CK2 ${K2:-}" "check $AS_REDO_CK1 ${K3:-}"; do
  set -- $pair
  NEW_SEEN=$((NEW_SEEN+1))
  printf '      %-6s %-62s %s\n' "$1" "$2" "${3:-못 쟀다}"
  if [ "${3:-0}" = "1" ]; then NEW_OK=$((NEW_OK+1)); fi
done
if [ "$NEW_SEEN" = "9" ]; then ok "0124 가 만드는 아홉을 다 물어봤다 (표본이 비지 않았다)"
else bad "아홉 중 ${NEW_SEEN}개만 물어봤다 — 목록이 깨졌다"; fi
# 🔴 **갈래를 기록 수로 나눈다.** 적용 전이면 0 · 적용 뒤면 9 여야 한다.
#    🔵 K3(다시 세운 CHECK)만은 **적용 전에도 1** 이다 — 0124 가 뗐다가 다시 세우는
#       제약이라 48번 판에도 같은 이름으로 있었다. 그래서 가지를 따로 적는다.
if [ -z "${MIG_AS0:-}" ]; then
  hm "DB 를 못 쟀으니 아홉의 기대값을 못 정한다 — **못 쟀다**로 센다"
elif [ "$MIG_AS0" = "$AS_MIG_AFTER" ]; then
  if [ "$NEW_OK" = "9" ]; then
    ok "아홉이 다 있다 — 운영이 정말 $AS_MIG_AFTER 상태다 (수가 아니라 **값**으로 확인했다)"
  else
    bad "🔴 기록은 $AS_MIG_AFTER 인데 실물이 ${NEW_OK}/9 개다 — **반만 적용된 상태다.** 멈추고 알리세요"
    doubt
  fi
elif [ "$MIG_AS0" = "$AS_MIG_BEFORE" ]; then
  # 적용 전: 새로 생기는 여덟은 0 · 다시 세우는 K3 는 **1** 이어야 한다.
  if [ "$NEW_OK" = "1" ] && [ "${K3:-0}" = "1" ]; then
    ok "아직 적용 전이라 여덟이 없고, 뗐다 다시 세울 제약 하나만 있다 (**기대한 모양**)"
  else
    hm "적용 전인데 아홉 중 ${NEW_OK}개가 있다 — 하나(다시 세우는 CHECK)만 기대했다. 사람이 보세요"
    say "🔵 0124 가 뗐다가 **넓혀 다시 세우는** 제약이라 48번 판에도 같은 이름으로 있다."
    doubt
  fi
else
  hm "기록이 ${MIG_AS0} 이라 아홉의 기대값을 못 정한다 — 위 ✗ 를 먼저 보세요"
fi
# 🔵 48번이 올린 것도 **아직 있어야** 한다 — 52번에서 그대로 가져왔다.
printf '\n    ── 48번이 올린 표 하나 · 칸 하나 · 인덱스 하나 (어느 단계에서나 있어야 한다)\n'
T1=$(has_table  "$AS_BOX" "$AS_DB" "$AS_OLD_TABLE")
C1=$(has_column "$AS_BOX" "$AS_DB" "$AS_OLD_COL_TABLE" "$AS_OLD_COL")
X1=$(has_index  "$AS_BOX" "$AS_DB" "$AS_OLD_INDEX")
OBJ_SEEN=0; OBJ_OK=0
for pair in "표 $AS_OLD_TABLE ${T1:-}" "칸 $AS_OLD_COL_TABLE.$AS_OLD_COL ${C1:-}" "인덱스 $AS_OLD_INDEX ${X1:-}"; do
  set -- $pair
  OBJ_SEEN=$((OBJ_SEEN+1))
  printf '      %-8s %-56s %s\n' "$1" "$2" "${3:-못 쟀다}"
  if [ "${3:-0}" = "1" ]; then OBJ_OK=$((OBJ_OK+1)); fi
done
if [ "$OBJ_SEEN" = "3" ]; then ok "셋을 다 물어봤다 (표본이 비지 않았다)"
else bad "셋 중 ${OBJ_SEEN}개만 물어봤다 — 목록이 깨졌다"; fi
if [ "$OBJ_OK" = "3" ]; then
  ok "48번이 올린 셋이 다 있다"
elif [ -z "${MIG_AS0:-}" ]; then
  hm "셋 중 ${OBJ_OK}개만 찾았다 — 위에서 DB 를 아예 못 쟀으니 **못 쟀다**로 센다"
else
  bad "🔴 셋 중 ${OBJ_OK}개만 있다 — **실물이 모자란다.** 멈추고 알리세요"
  doubt
fi

# ── 2-ㄷ. 🔴 A/S 마이그레이션 볼륨 — **124 에서 125 로 올려야 한다** ──
printf '\n== 2-ㄷ. A/S 마이그레이션 볼륨 (%s → %s 의 %s)\n' "$MIGDIR" "$AS_TOOLS_SVC" "$IMG_MIGDIR"
printf '%s\n' "🔴 .sql 만으로는 모자라다 — **meta/_journal.json 과 snapshot 까지** 가야 한다."
printf '%s\n' "   목록에 없는 .sql 은 drizzle 이 아예 모르고, 적용이 **0건으로 조용히 끝난다.**"
printf '%s\n' "🔴 이번 판은 **올릴 마이그레이션이 1건**이다 — 묶음을 **반드시** 받아야 한다."
read_migdir
say "$MIGDIR — .sql ${MIG_N_SQL}장 · meta/_journal.json 의 idx ${MIG_N_J}개"
case "$MIG_STATE" in
  DONE) ok "볼륨이 $AS_MIG_AFTER 이다 (묶음을 이미 풀었다 — 적용할 준비가 됐거나 이미 적용했다)" ;;
  # 🔴 **migrate 도 봐주는 쪽이다**(2026-11-07 쉰째 배포에서 걸렸다). 묶음을 푸는
  #    절(4-ㄴ)이 **이 줄보다 뒤**에 있어서, --migrate 가 제 할 일을 하기도 전에
  #    「왜 아직 안 풀었냐」로 스스로를 막았다. 🔵 묶음이 성한지는 바로 아래에서
  #    크기·md5·125장·0124 넷으로 이미 본다 — 여기서 또 막을 까닭이 없다.
  #    🔴 **go 는 그대로 엄격하다** — 그때는 --migrate 가 이미 풀어 둔 뒤여야 한다.
  OLD)  if [ "$MODE" = check ] || [ "$MODE" = preload ] || [ "$MODE" = rollback ]; then
          hm "볼륨이 $AS_MIG_BEFORE 이다 — **$MODE 에서는 맞는 모습이다.** --migrate 가 묶음으로 올린다"
        elif [ "$MODE" = migrate ]; then
          hm "볼륨이 $AS_MIG_BEFORE 이다 — **--migrate 가 지금 푼다**(4-ㄴ). 여기서는 맞는 모습이다"
        else
          bad "🔴 볼륨이 $AS_MIG_BEFORE 이다 — $AS_MIG_AFTER 를 기대했다. 묶음을 풀어야 한다"
        fi
        say "🔵 묶음을 보내세요: scp -O as-migrations.tar.gz dss-nas:$INCOMING/" ;;
  NODIR) bad "🔴 $MIGDIR 폴더가 **없다** — compose 가 $AS_TOOLS_SVC 에 붙이는 그 폴더다" ;;
  *)    bad "🔴 볼륨이 .sql ${MIG_N_SQL} · idx ${MIG_N_J} 다 — $AS_MIG_BEFORE 나 $AS_MIG_AFTER 여야 한다"
        say "→ 고치지 말고 **먼저 알리세요.**"; doubt ;;
esac
# 🔵 두 상수가 이어지는 번호인가 — 한쪽만 고치면 아래 검사가 조용히 빗나간다.
#    🔴 10# 을 붙여 **10진수로 강제**한다. 안 붙이면 0124 가 8진수 84 로 읽힌다.
if [ "$(printf '%04d' "$((10#$AS_PREV_MIG + 1))")" = "$AS_NEW_MIG" ] \
   && [ "$(printf '%04d' "$((10#$AS_NEW_MIG + 1))")" = "$AS_NEXT_MIG" ]; then
  ok "번호 셋이 이어진다 ($AS_PREV_MIG → $AS_NEW_MIG → $AS_NEXT_MIG)"
else
  bad "🔴 $AS_PREV_MIG · $AS_NEW_MIG · $AS_NEXT_MIG 가 안 이어진다 — 한쪽만 고쳤다"
fi
# 🔴 **볼륨에 0125 가 없는가** — 이 판의 전제다. 수(125)만 보면 하나 빠지고
#    하나 생긴 경우를 못 본다.
if [ "$MIG_STATE" = NODIR ]; then
  hm "$MIGDIR 가 없어 $AS_NEXT_MIG 번을 못 쟀다"
elif ls -1 "$MIGDIR/${AS_NEXT_MIG}_"*.sql >/dev/null 2>&1; then
  bad "🔴 볼륨에 $AS_NEXT_MIG 번이 **있다** — 이 배포는 1건을 전제로 쓰였다. 멈추고 알리세요"
  doubt
else
  ok "볼륨에 $AS_NEXT_MIG 번이 없다 (마지막이 $AS_NEW_MIG — 1건이 맞다)"
fi
# 🔴 **묶음이 와 있는가** — 이번 판에는 **없으면 ✗ 다.** 52번과 반대다.
#    🔵 다만 볼륨이 이미 125 면(DONE) 없어도 된다 — 이미 풀었다는 뜻이다.
if [ -s "$MIGTAR" ]; then
  say "묶음이 있다: $MIGTAR ($(stat -c %s "$MIGTAR" 2>/dev/null)바이트 · md5 $(md5sum "$MIGTAR" | awk '{print $1}'))"
  TSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -c '^drizzle/[0-9].*\.sql$' || true)
  TJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
  say "묶음 안 — .sql ${TSQL:-?}장 · idx ${TJRN:-?}개"
  if [ "${TSQL:-0}" = "$AS_MIG_AFTER" ] && [ "${TJRN:-0}" = "$AS_MIG_AFTER" ]; then
    ok "묶음 안이 $AS_MIG_AFTER 이다 (0124 가 들어 있는 그 묶음이다)"
  else
    bad "🔴 묶음 안이 .sql ${TSQL:-?} · idx ${TJRN:-?} 다 — **$AS_MIG_AFTER 이어야 한다.** 다시 묶어 올리세요"
    doubt
  fi
  # 🔴 **`grep -q` 를 `if` 에 바로 물리지 않는다**(2026-11-07 쉰째 배포에서 걸렸다).
  #    176줄에 `set -uo pipefail` 이 켜져 있어서, 파이프라인의 **어느 한 쪽이라도**
  #    0 이 아니면 `if` 가 거짓이 된다. `grep -q` 는 찾는 순간 끝내므로 앞의 `tar` 가
  #    SIGPIPE(141)로 죽고, **파일이 있을 때 오히려 ✗ 가 난다.** 바로 위 두 줄이
  #    멀쩡했던 까닭은 `|| true` 가 그 종료 코드를 가려 주었기 때문이다.
  #    🔵 개발 PC 의 GNU tar 로는 안 드러났다 — NAS 에서만 터지는 자리다.
  MIG_HAS_NEW=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${AS_NEW_MIG}_.*[.]sql" || true)
  if [ "${MIG_HAS_NEW:-0}" -ge 1 ]; then
    ok "묶음에 $AS_NEW_MIG 번이 **있다** (${MIG_HAS_NEW}장)"
  else
    bad "🔴 묶음에 $AS_NEW_MIG 번이 **없다** — 옛 묶음이다. 풀어도 적용이 0건으로 끝난다"
    doubt
  fi
  if [ -n "${MIGTAR_MD5:-}" ] && [ -n "${MIGTAR_SIZE:-}" ]; then
    M=$(md5sum "$MIGTAR" | awk '{print $1}')
    S=$(stat -c %s "$MIGTAR" 2>/dev/null)
    [ "$S" = "$MIGTAR_SIZE" ] && ok "묶음 크기가 구울 때와 같다  [배포본]" \
      || { bad "묶음 크기가 다르다 (${S} != ${MIGTAR_SIZE}) — 옮기다 끊겼다  [배포본]"; doubt; }
    [ "$M" = "$MIGTAR_MD5" ] && ok "묶음 md5 가 구울 때와 같다  [배포본]" \
      || { bad "묶음 md5 가 다르다 — 옮기다 깨졌다  [배포본]"; doubt; }
  else
    hm "묶음의 잰 값이 이 파일에 없다 — 53-build.sh --go 의 출력에서 MIGTAR_SIZE·MIGTAR_MD5 를 채우세요"
    say "🔴 **안 채우면 「개발 PC 에서 묶은 그것이 맞나」를 아예 못 본다.**"
  fi
elif [ "$MIG_STATE" = DONE ]; then
  say "🔵 묶음이 없지만 볼륨이 이미 $AS_MIG_AFTER 다 — **이미 풀었다는 뜻이라 없어도 된다.**"
else
  if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
    hm "묶음이 아직 없다: $MIGTAR — **${MODE} 에서는 괜찮다.** --migrate 전에 보내세요"
  else
    bad "🔴 묶음이 없다: $MIGTAR — **이번 판에는 반드시 있어야 한다**(볼륨 $AS_MIG_BEFORE · 저장소 $AS_MIG_AFTER)"
  fi
  cmd "scp -O as-migrations.tar.gz dss-nas:$INCOMING/"
fi

# ── 3. 들여올 이미지 넷 ───────────────────────────────────────────────
printf '\n== 3. 들여올 이미지 넷 (앱 둘 · 도구 둘)\n'
BLANK=0; TSEEN=0
for t in $(trows); do
  TSEEN=$((TSEEN+1))
  TAR=$(fld "$t" 1); WSZ=$(fld "$t" 2); WM5=$(fld "$t" 3); WCFG=$(fld "$t" 4)
  T=$IMGD/$TAR
  if [ ! -s "$T" ]; then
    if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
      hm "$TAR 가 아직 없다: $T — **${MODE} 에서는 괜찮다**"
    else bad "$TAR 가 없다: $T — 먼저 올리세요"; fi
    cmd "scp -O $TAR dss-nas:$IMGD/"
    continue
  fi
  SZ=$(stat -c %s "$T" 2>/dev/null)
  M5=$(md5sum "$T" | awk '{print $1}')
  CFG=$(tar -xOf "$T" manifest.json 2>/dev/null | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 | sed 's|blobs/sha256/|sha256:|')
  say "$TAR — ${SZ}바이트 · md5 $M5"
  say "        tar 안 Config: ${CFG:-못 읽음}"
  if [ -z "$WSZ" ] || [ -z "$WM5" ] || [ -z "$WCFG" ]; then
    BLANK=$((BLANK+1))
    # 🔴 **단계마다 엄함이 다르다.** --check 에서는 「아직 안 채웠나 보다」가
    #    정상이지만, --preload·--go 에서는 **올린 것이 개발 PC 에서 구운 그것인지
    #    아예 못 보게 된다.**
    if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
      hm "$TAR — **잰 값이 이 파일에 없다.** 옮기다 깨진 것만 잡는다"
    else
      bad "🔴 $TAR — **잰 값이 이 파일에 없다.** 53-build.sh --go 가 찍어 준 네 줄로 TARS 를 채우세요"
      say "🔴 안 채우면 「개발 PC 에서 구운 그것이 맞나」를 **아예 못 본다.**"
    fi
    continue
  fi
  [ "$SZ"  = "$WSZ"  ] && ok "$TAR 크기가 구울 때와 같다  [배포본]" || { bad "$TAR 크기가 다르다 (${SZ} != ${WSZ}) — 옮기다 깨졌다"; doubt; }
  [ "$M5"  = "$WM5"  ] && ok "$TAR md5 가 같다  [배포본]"           || { bad "$TAR md5 가 다르다 — 옮기다 깨졌다"; doubt; }
  [ "$CFG" = "$WCFG" ] && ok "$TAR 지문이 같다  [배포본]"           || { bad "$TAR 지문이 다르다 (${CFG:-못 읽음}) — **다른 판을 올렸다**"; doubt; }
done
# 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다 — TARS 가 통째로 비면 위 고리가
#    **아무 말도 안 하고** 끝난다.
if [ "$TSEEN" = "$TARS_WANT" ]; then ok "TARS 표의 ${TARS_WANT}줄을 다 봤다 (표가 비지 않았다)"
else bad "🔴 TARS 표에서 ${TSEEN}줄만 봤다 — ${TARS_WANT}줄을 기대했다. 표가 깨졌다"; fi
if [ "$BLANK" != "0" ]; then
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 53-build.sh --go 가 끝에 찍어 주는"
  printf '%s\n' "     **네 줄**로 이 파일의 TARS 네 줄을 통째로 갈아 끼우세요."
fi
# 🔵 되돌릴 길 — 옛 태그가 **NAS 에** 남아 있는가(앱 둘. 도구는 되돌리지 않는다)
for r in $(rows); do
  OLD=$(fld "$r" 5)
  if "$DOCKER" image inspect "$OLD" >/dev/null 2>&1; then ok "$OLD 이 NAS 에 남아 있다 (되돌릴 길)"
  else hm "$OLD 이 NAS 에 없다 — **--rollback 을 못 쓴다.** 되돌릴 일이 생기면 개발 PC 에서 다시 보내야 한다"; fi
done
# 🔴 도구 이미지가 **이미 실려 있으면** 그 자리에서 안을 센다. 🔵 집마다 따로.
if "$DOCKER" image inspect "$AS_TOOLS_NEW" >/dev/null 2>&1; then
  as_tools_inside_check
else
  if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
    hm "$AS_TOOLS_NEW 가 아직 안 실렸다 — **${MODE} 에서는 괜찮다**. 4절이 싣는다"
  else
    say "$AS_TOOLS_NEW 가 아직 안 실렸다 — 4절이 싣는다"
  fi
fi
if "$DOCKER" image inspect "$AUTH_TOOLS_NEW" >/dev/null 2>&1; then
  auth_tools_inside_check
else
  if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
    hm "$AUTH_TOOLS_NEW 가 아직 안 실렸다 — **${MODE} 에서는 괜찮다**. 4절이 싣는다"
  else
    say "$AUTH_TOOLS_NEW 가 아직 안 실렸다 — 4절이 싣는다"
  fi
fi

# 🔴 **재고 관리 통로 — --check 에서 미리 재 둔다.** ? 로만 센다(교체를 막지 않는다).
if [ "$MODE" = check ]; then inventory_gateway_check soft; fi
# 🔵 **후속 작업 둘도 --check 에서 미리 본다** — 배포 전에 0 인 것이 정상이다.
if [ "$MODE" = check ]; then followup_counts; fi

if [ "$MODE" = check ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s   (PHASE=%s)\n' "$PASS" "$FAIL" "$WARN" "$PHASE"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  printf '%s\n' "🔴 다음 차례: --count(앞) → scp tar 넷 + 묶음 → --preload → (다시 --check) → --migrate → --go → --count(뒤)"
  printf '%s\n' "🔴 **PHASE=PRE 에서 돌리면 ? 가 여럿 나오는 것이 정상**이다 (tar 넷과 묶음이 아직 없다)."
  printf '%s\n' "🔵 마이그레이션 기록은 적용 전 $AS_MIG_BEFORE · 적용 뒤 $AS_MIG_AFTER 입니다 — **두 갈래**입니다."
  printf '%s\n' "🔵 양식은 **올릴 것이 0장**입니다 — 1-ㄷ 절은 「안 바뀌었는가」만 봅니다."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 4. --preload : tar 넷을 들여놓는다 ───────────────────────────────
if [ "$MODE" = preload ] || [ "$MODE" = go ]; then
  printf '\n== 4. tar 넷을 들여놓는다\n'
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 하고 멈춘다.**\n'; exit 1; fi
  LOADED=0
  for t in $(trows); do
    TAR=$(fld "$t" 1); NEW=$(tar2tag "$TAR")
    if [ -z "$NEW" ]; then bad "$TAR 의 태그를 모른다 — tar2tag() 에 줄을 더하세요"; continue; fi
    T=$IMGD/$TAR
    if [ ! -s "$T" ]; then bad "$TAR 가 없다: $T"; continue; fi
    WCFG=$(tar -xOf "$T" manifest.json 2>/dev/null | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 | sed 's|blobs/sha256/|sha256:|')
    if "$DOCKER" image inspect "$NEW" --format '{{.Id}}' 2>/dev/null | grep -q "$WCFG"; then
      ok "$NEW 는 이미 있고 지문이 tar 와 같다 (건너뜀)"; LOADED=$((LOADED+1)); continue
    fi
    "$DOCKER" load -i "$T" 2>&1 | sed 's/^/    /'
    FULL=$("$DOCKER" image inspect "$NEW" --format '{{.Id}}' 2>/dev/null)
    if [ "$FULL" = "$WCFG" ]; then ok "$NEW 가 올라왔고 지문이 tar 와 같다"; LOADED=$((LOADED+1))
    elif [ -n "$FULL" ]; then bad "$NEW 지문이 다르다 — tar $WCFG / NAS $FULL"
    else bad "$NEW 가 안 올라왔다"; fi
  done
  # 🔴 **「몇 개 실었나」를 센다.** 줄이 비어 있으면 위 고리가 **아무것도 안 하고
  #    조용히 끝난다** — 그 자리를 막는다.
  say "실린 이미지 ${LOADED}개 (기대 $TARS_WANT)"
  if [ "$LOADED" = "$TARS_WANT" ]; then ok "넷이 다 실렸다"
  else bad "🔴 ${LOADED}/$TARS_WANT 개만 실렸다 — TARS 가 비었거나 tar 가 모자란다"; fi
  # 🔴 들여놓자마자 도구 이미지 **둘**의 안을 센다 — 늦게 발견할수록 되돌리기가 비싸다.
  if "$DOCKER" image inspect "$AS_TOOLS_NEW" >/dev/null 2>&1; then as_tools_inside_check
  else bad "🔴 $AS_TOOLS_NEW 가 아직 안 실렸다 — 위 load 가 실패했는지 보세요"; fi
  if "$DOCKER" image inspect "$AUTH_TOOLS_NEW" >/dev/null 2>&1; then auth_tools_inside_check
  else bad "🔴 $AUTH_TOOLS_NEW 가 아직 안 실렸다 — 위 load 가 실패했는지 보세요"; fi
fi

if [ "$MODE" = preload ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **들여놓기만 했다 — 아직 안 갈아 끼웠다.** 다음: --check 를 다시 → --migrate → --go"
  printf '%s\n' "🔴 **이 배포는 마이그레이션이 1건입니다.** --migrate 가 볼륨을 $AS_MIG_BEFORE → $AS_MIG_AFTER 로"
  printf '%s\n' "   올리고 **DB 를 실제로 바꿉니다**(덤프를 먼저 뜹니다)."
  printf '%s\n' "🔴 **건너뛰지 마세요.** 52번과 다릅니다 — 건너뛰면 새 앱이 **없는 칸을 읽습니다.**"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ══════════════════════════════════════════════════════════════════════
# ── 4-ㄴ. --migrate : 🔴 **DB 를 실제로 바꾼다** (124 → 125) ──────────
# ══════════════════════════════════════════════════════════════════════
#   🔵 52번은 「0건을 값으로 잰다」였다. **이번 판은 진짜로 적용한다.**
#   🔴 그래서 차례가 중요하다: 덤프 → compose 의 도구 둘 → 도구 안 세기 →
#      볼륨 올리기 → 파일 세기 → preflight → 멈출 창 → 적용 → **값으로 다시 세기**.
#   🔴 **종료 코드만 보고 「성공」이라 말하지 않는다** — drizzle-kit 은 오류를
#      삼키고 종료 코드만 남길 수 있다. 적용 뒤 DB 를 다시 읽어 아홉을 센다.
if [ "$MODE" = migrate ]; then
  printf '\n== 4-ㄴ. 🔴 마이그레이션 — 이 판은 **1건(%s)** 이다 (기록 %s → %s)\n' "$AS_NEW_MIG" "$AS_MIG_BEFORE" "$AS_MIG_AFTER"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **DB 를 안 건드리고 멈춘다.**\n'; exit 1; fi

  # ── ㄱ. 🔴 덤프 — **이번 판은 되돌릴 기준이다** ────────────────────
  make_dump "🔴 DB 가 실제로 바뀐다 — 이 덤프가 되돌릴 기준이다"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 되돌릴 길이 없다 — **DB 도 앱도 그대로 두고 멈춘다.**\n'; exit 1; fi

  # ── ㄴ. 🔴 적용 전 줄 수를 적어 둔다 ────────────────────────────────
  #   🔵 0124 는 칸과 제약만 더한다 — **줄은 하나도 안 움직여야** 한다.
  printf '\n    ── 적용 전 줄 수 (적용 뒤에 **그대로여야** 한다)\n'
  CNT_BEFORE=""
  for F in $AS_COUNT_TABLES; do
    V=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $F")
    CNT_BEFORE="$CNT_BEFORE as.$F=${V:-?}"; say "dss_as.$F ${V:-?}줄"
  done

  # ── ㄷ. 🔴 compose 의 **도구 둘**을 새 태그로 ──────────────────────
  #   🔴 37번이 한 그 방식 그대로 — 사본을 먼저 뜨고, image: 줄이 **꼭 둘만**
  #      달라졌는지 세고, 어긋나면 **사본으로 되돌리고 멈춘다.**
  #   🔵 둘 다 profiles: [tools] 라 평소에 뜨지 않는다. 도는 컨테이너는 compose 를
  #      읽지 않으므로 이 두 줄을 고쳐도 **직원이 느끼는 것이 없다.** up -d 를 안 부른다.
  #   🔴 이 자리를 DB 앞에 둔다 — 여기서 어긋나면 DB 를 안 건드리고 끝난다.
  #   🔴 **52번은 한 줄이었다.** 그 「꼭 하나만」을 베껴 오면 여기서 가짜 ✗ 가 난다.
  printf '\n    ── compose 의 도구 둘을 새 태그로 (%s · %s)\n' "$AS_TOOLS_NEW" "$AUTH_TOOLS_NEW"
  cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
  chmod 644 "$BK"
  ok "사본 $BK"
  TL0=$(wc -l < "$CF"); TI0=$(grep -c '^ *image:' "$CF")
  TB=$(mktemp) || exit 1; TA=$(mktemp) || exit 1
  grep -n '^ *image:' "$CF" > "$TB"
  APPB=$(app_img_lines)            # 🔴 앱 줄은 **하나도 안 바뀌어야** 한다
  # 🔴 **고치기 전에 몇 줄이 달라질지 센다 — 박지 않는다.**
  #    🔵 이미 새 태그면 0 이다(다시 돌리는 중). 48번이 이 숫자를 박아 두었다가
  #       제대로 동작한 모드가 ✗ 를 받고 되돌아갔다.
  TWANT=0
  [ "$S_AS_TOOLS"   != NEW ] && TWANT=$((TWANT+1))
  [ "$S_AUTH_TOOLS" != NEW ] && TWANT=$((TWANT+1))
  say "기대 — 지금 상태가 A/S 도구 $S_AS_TOOLS · 포털 도구 $S_AUTH_TOOLS 이므로 달라질 image: 줄은 ${TWANT}개다"
  TOOLFAIL=0
  for pair in "$AS_TOOLS_SVC $AS_TOOLS_NEW" "$AUTH_TOOLS_SVC $AUTH_TOOLS_NEW"; do
    set -- $pair
    TAL=$(img_line "$1") || { bad "$1 를 못 찾았다"; TOOLFAIL=1; continue; }
    # 🔴 치환 **전에** 줄 모양을 본다 — 주석이 붙어 있으면 엉뚱한 낱말이 바뀐다.
    TNF0=$(nf_at "$TAL")
    if [ "${TNF0:-0}" != "2" ]; then
      bad "🔴 $1 의 ${TAL}줄이 낱말 ${TNF0:-?}개다 — 'image: 태그' 두 낱말만 있어야 한다"
      awk -v n="$TAL" 'NR==n' "$CF" | sed 's/^/      /'
      doubt; TOOLFAIL=1; continue
    fi
    if [ "$(tag_at "$TAL")" = "$2" ]; then
      ok "$1 가 이미 $2 다 — 고칠 것이 없다"
      continue
    fi
    TMP=$(mktemp) || exit 1
    awk -v n="$TAL" -v to="$2" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
    cp "$TMP" "$CF"; rm -f "$TMP"
    [ "$(tag_at "$TAL")" = "$2" ] && ok "$1 → $2 (${TAL}줄)" \
      || { bad "$1 의 태그가 $(tag_at "$TAL") 다"; TOOLFAIL=1; }
  done
  grep -n '^ *image:' "$CF" > "$TA"
  TDIFF=$(diff "$TB" "$TA" | grep -c '^[<>]' || true)
  APPA=$(app_img_lines)
  say "줄 수 $TL0 → $(wc -l < "$CF") · image: 줄 $TI0 → $(grep -c '^ *image:' "$CF") · 달라진 image: 줄 $((TDIFF / 2))개"
  [ "$(wc -l < "$CF")" = "$TL0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
  [ "$(grep -c '^ *image:' "$CF")" = "$TI0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
  # 🔴 **세어서 정한 수와 같아야** 한다. 박은 수가 아니다.
  [ "$((TDIFF / 2))" = "$TWANT" ] && ok "image: 줄이 **꼭 ${TWANT}개만** 달라졌다 (도구 둘 · 남의 것은 안 건드렸다)" \
    || { bad "image: 줄이 $((TDIFF / 2))개 달라졌다 — ${TWANT}개를 기대했다. 남의 것을 건드렸다"; doubt; }
  # 🔴 앱 줄은 --go 의 일이다. 여기서 바뀌면 안 된다.
  [ "$APPA" = "$APPB" ] && ok "앱 둘의 image: 줄은 하나도 안 바뀌었다 (--go 의 일이다)" \
    || bad "🔴 앱 image: 줄이 바뀌었다 — 이 단계가 건드릴 자리가 아니다"
  dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"
  rm -f "$TB" "$TA"
  if [ "$FAIL" != 0 ] || [ "$TOOLFAIL" != 0 ]; then
    printf '\n🔴 어긋났다 — **사본으로 되돌리고 DB 는 안 건드린다.**\n'
    cp "$BK" "$CF"; say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $TL0)"
    exit 1
  fi

  # ── ㄹ. 🔴 도구 이미지 **둘**의 안을 센다 — 쓸 수 있는 판이 맞는가 ──
  #   🔴 「태그를 고쳤다」와 「쓸 수 있다」는 다르다. 겉이 아니라 결과를 본다.
  if "$DOCKER" image inspect "$AS_TOOLS_NEW" >/dev/null 2>&1; then as_tools_inside_check
  else bad "🔴 $AS_TOOLS_NEW 가 NAS 에 없다 — compose 가 없는 이미지를 가리키게 됐다"; fi
  if "$DOCKER" image inspect "$AUTH_TOOLS_NEW" >/dev/null 2>&1; then auth_tools_inside_check
  else bad "🔴 $AUTH_TOOLS_NEW 가 NAS 에 없다 — compose 가 없는 이미지를 가리키게 됐다"; fi
  if [ "$FAIL" != 0 ]; then
    printf '\n🔴 도구가 온전하지 않다 — **사본으로 되돌리고 DB 는 안 건드린다.**\n'
    cp "$BK" "$CF"; exit 1
  fi

  # ── ㅁ. 🔴 볼륨을 125 로 올린다 ────────────────────────────────────
  printf '\n    ── A/S 마이그레이션 볼륨을 %s 로\n' "$AS_MIG_AFTER"
  read_migdir
  if [ "$MIG_STATE" != DONE ]; then
    say "볼륨이 .sql ${MIG_N_SQL} · idx ${MIG_N_J} 다 — 묶음으로 $AS_MIG_AFTER 로 올린다"
    place_migs || { printf '\n🔴 **DB 도 앱도 그대로다.**\n'; cp "$BK" "$CF"; exit 1; }
    read_migdir
  else
    say "볼륨이 이미 $AS_MIG_AFTER 다 — 묶음을 안 푼다(다시 돌리는 중인가)"
  fi
  say "지금 $MIGDIR — .sql ${MIG_N_SQL}장 · meta/_journal.json 의 idx ${MIG_N_J}개"
  [ "$MIG_N_SQL" = "$AS_MIG_AFTER" ] && ok ".sql 이 ${MIG_N_SQL}장이다" \
    || bad ".sql 이 ${AS_MIG_AFTER}장이 아니다 (${MIG_N_SQL}장)"
  [ "$MIG_N_J" = "$AS_MIG_AFTER" ] && ok "meta/_journal.json 의 idx 가 ${MIG_N_J}개다" \
    || bad "idx 가 ${AS_MIG_AFTER}개가 아니다 (${MIG_N_J}개) — 🔴 적용이 **0건으로 끝난다**"
  # 🔴 0121~0124 가 온전한가 + 0125 가 없는가 + 지우는 문장 0 + 살펴볼 문장 2.
  check_keep_migs || true
  if [ "$FAIL" != 0 ]; then printf '\n🔴 마이그레이션 파일이 온전하지 않다 — **DB 도 앱도 그대로다.**\n'; cp "$BK" "$CF"; exit 1; fi
  # 🔴 컨테이너가 **실제로 그 폴더를 읽는지** 본다. 겉이 아니라 결과다 —
  #    호스트에서 보이는 것과 컨테이너 안에서 보이는 것이 다를 수 있다.
  INSQL=$(dct run --rm --entrypoint sh "$AS_TOOLS_SVC" -c "ls -1 $IMG_MIGDIR/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r' | tail -1)
  say "$AS_TOOLS_SVC 안에서 본 $IMG_MIGDIR 의 .sql: ${INSQL:-?}장"
  if [ "${INSQL:-0}" = "$AS_MIG_AFTER" ]; then ok "컨테이너 안에서도 $AS_MIG_AFTER 장이다 (볼륨이 제대로 붙었다)"
  else bad "컨테이너 안이 ${INSQL:-?}장이다 — $AS_MIG_AFTER 장이어야 한다. **0건으로 끝날 수 있다**"; fi
  if [ "$FAIL" != 0 ]; then printf '\n🔴 **DB 도 앱도 그대로다.** 멈춘다.\n'; cp "$BK" "$CF"; exit 1; fi

  # ── ㅂ. 적용 전 preflight — **대기 1건**이어야 한다 ────────────────
  #   🔴 **종료 코드만 보지 않는다.** 이 판은 「살펴볼 문장 2건」이 뜨는데 그 갈래는
  #      **종료 코드에 관여하지 않는다**(앱의 check-pending-migrations.ts 187줄).
  #      그래서 0 이 나온다고 「살펴볼 것이 없다」로 읽으면 안 된다.
  #   🔴 **대기 건수는 글자로 안 센다** — 그 줄이 한글이라 grep 이 환경에 따라
  #      어긋날 수 있다. **DB 기록과 볼륨 수의 차이**로 센다(순수한 셈이다).
  printf '\n    ── 적용 전 db:preflight (이 판은 **대기 1건**이 맞다)\n'
  PEND=$((MIG_N_SQL - ${MIG_AS0:-0}))
  say "볼륨 ${MIG_N_SQL} - 기록 ${MIG_AS0:-?} = 적용 대기 ${PEND}건 (기대 1)"
  if [ "${MIG_AS0:-x}" = "$AS_MIG_BEFORE" ] && [ "$PEND" = "1" ]; then
    ok "적용 대기가 **1건**이다 (0124 하나 — 셈으로 확인했다)"
  elif [ "${MIG_AS0:-x}" = "$AS_MIG_AFTER" ] && [ "$PEND" = "0" ]; then
    hm "적용 대기가 0건이다 — **이미 적용된 DB 다**(다시 돌리는 중인가). 🔵 막지 않는다"
  else
    bad "🔴 적용 대기가 ${PEND}건이다 — 1건(또는 이미 적용됐으면 0건)을 기대했다"
    doubt
    printf '\n🔴 **DB 를 안 건드리고 멈춘다.** 앱은 그대로 돈다.\n'
    cp "$BK" "$CF"
    exit 1
  fi
  dct run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | tail -25 | sed 's/^/    /'
  PRC=${PIPESTATUS[0]}
  say "(종료 코드 $PRC — 기대 0)"
  say "🔵 위 출력에 **「살펴볼 문장 2건」**이 보여야 합니다 — 제약 둘을 뗐다가 같은"
  say "   파일에서 **넓혀 다시 세우기** 때문입니다. 🔴 그 갈래는 종료 코드를 안 건드립니다."
  if [ "$PRC" != 0 ]; then
    bad "db:preflight 가 0 이 아니다 ($PRC) — **사라질 자료가 있다는 뜻**이다"
    say "→ 🔴 이 판은 **더하기만** 해야 한다. 0 이 아니면 전제가 깨진 것이다."
    printf '\n🔴 **DB 를 안 건드리고 멈춘다.** 앱은 그대로 돈다.\n'
    cp "$BK" "$CF"
    exit 1
  fi

  printf '\n'
  say "🔴 **여기서부터 DB 가 바뀝니다.** 0124 하나가 적용됩니다 —"
  say "   enum 값 둘 · 칸 하나 · 인덱스 둘 · 제약 넷(둘은 넓혀 다시)."
  say "🔵 **자료는 한 줄도 안 사라집니다** — 더하기만 합니다(preflight 가 그것을 쟀습니다)."
  say "🔴 그만두려면 **20초 안에 Ctrl+C**. 덤프는 이미 떠 두었습니다: ${DUMP:-없음}"
  sleep 20

  # ── ㅅ. 돌린다 ──────────────────────────────────────────────────────
  printf '\n    ── 돌린다 (drizzle 은 다시 돌려도 안전하다)\n'
  say "🔵 drizzle 은 밀린 것을 **한 트랜잭션**에 넣습니다. 이 판은 새 enum 값을"
  say "   더하면서 같은 트랜잭션에서 CHECK 을 세우는데, CHECK 이 approval_type::text"
  say "   비교라 **방금 더한 enum 값을 쓰지 않아** 통과합니다(개발에서 고친 자리)."
  dct run --rm "$AS_TOOLS_SVC" npm run db:migrate 2>&1 | tail -30 | sed 's/^/    /'
  RC=${PIPESTATUS[0]}
  if [ "$RC" = 0 ]; then ok "A/S db:migrate 가 종료 코드 0 으로 끝났다"
  else
    bad "A/S db:migrate 실패 (종료 코드 $RC)"
    say "🔵 앱 둘은 **그대로 옛 판으로 돕니다.** 직원이 느끼는 것이 없습니다."
    say "🔴 아래 「값으로 확인」이 **무엇이 들어가고 무엇이 안 들어갔는지**를 말해 줍니다."
  fi
  say "🔴 **종료 코드만으로 「성공」이라 하지 않습니다** — drizzle-kit 은 오류를"
  say "   삼키고 코드만 남길 수 있습니다. 아래에서 **DB 를 다시 읽어** 셉니다."

  # ── ㅇ. 🔴 값으로 확인 (겉이 아니라 결과) ───────────────────────────
  printf '\n    ── 🔴 값으로 확인 — **기록이 %s 가 되고 아홉이 생겨야** 한다\n' "$AS_MIG_AFTER"
  MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
  say "기록 ${MIG_AS0:-?} → ${MIG_AS1:-?} (기대 $AS_MIG_BEFORE → $AS_MIG_AFTER)"
  if [ "${MIG_AS1:-x}" = "$AS_MIG_AFTER" ]; then
    ok "기록이 **$AS_MIG_AFTER** 이다 — 0124 가 적용됐다"
  else
    bad "🔴 기록이 ${MIG_AS1:-?} 다 — $AS_MIG_AFTER 여야 한다. **적용이 0건으로 끝났거나 실패했다**"
    doubt
  fi
  E1=$(has_enum_value  "$AS_BOX" "$AS_DB" "$AS_NEW_ENUM1" "$AS_NEW_ENUM_VALUE")
  E2=$(has_enum_value  "$AS_BOX" "$AS_DB" "$AS_NEW_ENUM2" "$AS_NEW_ENUM_VALUE")
  NC=$(has_column      "$AS_BOX" "$AS_DB" "$AS_NEW_COL_TABLE" "$AS_NEW_COL")
  I1=$(has_index       "$AS_BOX" "$AS_DB" "$AS_NEW_IDX1")
  I2=$(has_index       "$AS_BOX" "$AS_DB" "$AS_NEW_IDX2")
  K0=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_NEW_FK")
  K1=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_NEW_CK1")
  K2=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_NEW_CK2")
  K3=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_REDO_CK1")
  K4=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_REDO_CK2")
  AFTER_SEEN=0; AFTER_OK=0
  for pair in "enum1 $AS_NEW_ENUM1 ${E1:-}" "enum2 $AS_NEW_ENUM2 ${E2:-}" \
              "col $AS_NEW_COL_TABLE.$AS_NEW_COL ${NC:-}" \
              "uniq $AS_NEW_IDX1 ${I1:-}" "idx $AS_NEW_IDX2 ${I2:-}" \
              "fk $AS_NEW_FK ${K0:-}" "check1 $AS_NEW_CK1 ${K1:-}" \
              "check2 $AS_NEW_CK2 ${K2:-}" "redo1 $AS_REDO_CK1 ${K3:-}" \
              "redo2 $AS_REDO_CK2 ${K4:-}"; do
    set -- $pair
    AFTER_SEEN=$((AFTER_SEEN+1))
    printf '      %-7s %-62s %s\n' "$1" "$2" "${3:-못 쟀다}"
    if [ "${3:-0}" = "1" ]; then AFTER_OK=$((AFTER_OK+1)); fi
  done
  if [ "$AFTER_SEEN" = "10" ]; then ok "열을 다 물어봤다 (표본이 비지 않았다)"
  else bad "열 중 ${AFTER_SEEN}개만 물어봤다 — 목록이 깨졌다"; fi
  if [ "$AFTER_OK" = "10" ]; then
    ok "0124 가 만드는 **열이 다 생겼다** — enum 둘 · 칸 하나 · 인덱스 둘 · 제약 다섯"
    say "🔵 **뗐다가 다시 세운 둘(redo1·redo2)도 서 있다** — 제약이 사라진 채 끝나지 않았다."
  else
    bad "🔴 열 중 ${AFTER_OK}개만 있다 — **반만 적용됐다.** 위 표에서 무엇이 빠졌는지 보세요"
    say "🔴 **종료 코드가 0 이어도 이 줄이 진짜 답이다**(drizzle-kit 은 오류를 삼킬 수 있다)."
    say "🔴 되돌릴 길(이 시각의 덤프): ${DUMP:-없음}"
    doubt
  fi

  printf '\n    ── 🔴 줄 수가 그대로인가 (하나라도 줄었으면 자료가 사라진 것이다)\n'
  for F in $AS_COUNT_TABLES; do
    V=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $F")
    B=$(printf '%s' "$CNT_BEFORE" | tr ' ' '\n' | sed -n "s/^as\\.$F=//p")
    [ "${V:-x}" = "${B:-y}" ] && ok "dss_as.$F ${V}줄 — 그대로" \
      || bad "🔴 dss_as.$F 가 ${B:-?} → ${V:-?} 로 **달라졌다**"
  done
  # 🔴 포털 DB 는 손도 안 댔다 — **그대로인지 확인**한다.
  MIG_AU1=$(mig_count "$AUTH_BOX" "$AUTH_DB")
  say "포털 기록 ${MIG_AU0:-?} → ${MIG_AU1:-?} (둘 다 $AUTH_MIG_KEEP 이어야 한다)"
  [ "${MIG_AU1:-x}" = "$AUTH_MIG_KEEP" ] && ok "포털 DB 가 $AUTH_MIG_KEEP 그대로다 (안 건드렸다)" \
    || bad "🔴 포털 DB 가 ${MIG_AU1:-?} 다 — $AUTH_MIG_KEEP 그대로여야 한다. **이 단계가 건드렸다**"

  printf '\n    ── 적용 뒤 db:preflight — **대기 0건**이어야 한다\n'
  dct run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | tail -15 | sed 's/^/    /'
  say "(종료 코드 ${PIPESTATUS[0]})"
  say "🔵 이제 **「적용할 것이 없습니다」**가 보여야 합니다. 「살펴볼 문장」은 안 나옵니다"
  say "   — 대기가 0건이면 그 갈래를 셀 파일이 없기 때문입니다."

  printf '\n    ── 🔴 앱 둘이 **여전히 옛 판으로** 도는가 (--go 가 아직 안 돌았다)\n'
  "$DOCKER" ps --format '{{.Names}}\t{{.Image}}' 2>/dev/null | sort | sed 's/^/      /'

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$FAIL" = 0 ]; then
    printf '%s\n' "✅ **DB 가 $AS_MIG_BEFORE 에서 $AS_MIG_AFTER 로 올라갔습니다.**"
    printf '%s\n' "  🔵 확인한 것: 기록 $AS_MIG_AFTER · enum 둘 · 칸 하나 · 인덱스 둘 · 제약 다섯 ·"
    printf '%s\n' "     줄 수 그대로 · 포털 DB 그대로 · 대기 0건."
    printf '%s\n' "  🔵 compose 의 $AS_TOOLS_SVC 가 $AS_TOOLS_NEW · $AUTH_TOOLS_SVC 가 $AUTH_TOOLS_NEW 가 됐습니다"
    printf '%s\n' "     (사본: $BK)"
    printf '%s\n' "  🔴 되돌릴 길(이 시각의 덤프): $DUMP"
    printf '%s\n' "  🔵 옛 볼륨: $MIGDIR.old — **그대로 두세요**"
    printf '%s\n' "  🔴 **다음: --go** — 이제 PHASE=MID 라 --go 에서 image: 줄이 **둘만** 달라집니다."
    printf '%s\n' "  🔵 **지금 운영에 도는 앱은 옛 판입니다.** 0124 는 더하기만 했으므로 옛 판도"
    printf '%s\n' "     그 칸을 모르는 채 멀쩡히 돕니다 — 급히 --go 를 치지 않아도 됩니다."
  else
    printf '%s\n' "🔴 위 ✗ 를 보세요. 🔵 이 모드는 **다시 돌려도 안전합니다**: bash $0 --migrate"
    printf '%s\n' "  🔴 다만 **DB 가 반만 바뀌었을 수 있습니다** — 위 「값으로 확인」 표를 먼저 보세요."
    printf '%s\n' "  🔴 덤프: ${DUMP:-없음}"
  fi
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 5. --go / --rollback : compose 의 image: 줄을 바꾼다 ─────────────
#  🔴 --go 는 앱 둘과 도구 둘을 고친다. --rollback 은 **앱 둘**만 되돌린다 —
#     도구는 새 판 그대로 둔다(39·41~52번과 같은 판단).
#  🔴 **app-po 줄은 어느 모드에서도 안 건드린다.**
printf '\n== 5. compose 의 image: 줄을 바꾼다\n'
# 🔴 **덤프를 여기서도 뜬다.** --migrate 를 건너뛰고 --go 로 바로 올 수 있기 때문이다.
#    🔵 --migrate 를 이미 돌리셨으면 사진이 둘이 된다 — 해롭지 않다.
#    🔵 --rollback 에서는 안 뜬다: 되돌리는 길은 빠를수록 좋고, --migrate 가 이미 떴다.
if [ "$MODE" = go ]; then
  make_dump "--migrate 를 건너뛰었을 수 있다 — 갈아 끼우기 전 사진을 남긴다"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 덤프를 못 떴다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi
  # 🔴 **--migrate 를 건너뛰었으면 여기서 막는다.** 52번과 다르다 — 이번 판의
  #    새 앱은 **없는 칸을 읽는다.** 기록이 125 가 아니면 새 앱이 그 자리에서 깨진다.
  if [ "${MIG_AS0:-x}" != "$AS_MIG_AFTER" ]; then
    bad "🔴 DB 기록이 ${MIG_AS0:-못 쟀다} 다 — **$AS_MIG_AFTER 여야 --go 할 수 있다.**"
    say "🔴 새 앱($AS_NEW_TAG)은 $AS_NEW_COL_TABLE.$AS_NEW_COL 칸을 읽습니다. 지금 갈아 끼우면"
    say "   기타건 화면이 그 자리에서 깨집니다. **먼저 --migrate 를 돌리세요:**"
    cmd "bash $0 --migrate"
    printf '\n🔴 **아무것도 안 고치고 멈춘다.** 앱 둘은 그대로 옛 판으로 돈다.\n'
    exit 1
  fi
  ok "DB 기록이 $AS_MIG_AFTER 다 — 새 앱이 읽을 칸이 이미 있다 (--migrate 가 돌았다)"
fi
# 🔵 1절에서 읽어 둔 상태를 쓴다. **여기서 다시 읽지 않는다** — 두 벌로 읽으면
#    한쪽만 고쳤을 때 조용히 어긋난다.
say "고치기 전 — $AS_SVC $S_APP_AS · $AUTH_SVC $S_APP_AUTH · $AS_TOOLS_SVC $S_AS_TOOLS · $AUTH_TOOLS_SVC $S_AUTH_TOOLS (PHASE $PHASE)"
if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi

cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
chmod 644 "$BK"
ok "사본 $BK"
L0=$(wc -l < "$CF"); IMGS0=$(grep -c '^ *image:' "$CF")
BEF=$(mktemp) || exit 1
AFT=$(mktemp) || exit 1
grep -n '^ *image:' "$CF" > "$BEF"

# 🔴 **달라질 줄 수를 먼저 센다 — 박지 않는다.**
#    🔵 이미 목표 태그면 그 줄은 안 바뀐다. 48번이 이 숫자를 박아 두었다가
#       제대로 동작한 --go 가 ✗ 를 받고 되돌아갔다.
WANT_DIFF=0
for r in $(rows); do
  SVC=$(fld "$r" 2); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  if [ "$MODE" = rollback ]; then TO=$OLD; else TO=$NEW; fi
  L=$(img_line "$SVC" 2>/dev/null || true)
  [ -n "${L:-}" ] || continue
  [ "$(tag_at "$L")" = "$TO" ] || WANT_DIFF=$((WANT_DIFF+1))
done
if [ "$MODE" = go ]; then
  for pair in "$AS_TOOLS_SVC $AS_TOOLS_NEW" "$AUTH_TOOLS_SVC $AUTH_TOOLS_NEW"; do
    set -- $pair
    L=$(img_line "$1" 2>/dev/null || true)
    [ -n "${L:-}" ] || continue
    [ "$(tag_at "$L")" = "$2" ] || WANT_DIFF=$((WANT_DIFF+1))
  done
fi
say "기대 — 지금 상태로 보아 달라질 image: 줄은 ${WANT_DIFF}개다 (세어서 정했다 · 박은 값이 아니다)"

for r in $(rows); do
  SVC=$(fld "$r" 2); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  if [ "$MODE" = rollback ]; then TO=$OLD; else TO=$NEW; fi
  L=$(img_line "$SVC") || { bad "$SVC — image: 줄을 못 찾았다"; continue; }
  # 🔴 치환 **전에** 줄 모양을 본다 — 주석이 붙어 있으면 엉뚱한 낱말이 바뀐다.
  NF=$(nf_at "$L")
  if [ "${NF:-0}" != "2" ]; then
    bad "🔴 $SVC 의 ${L}줄이 낱말 ${NF:-?}개다 — 'image: 태그' 두 낱말만 있어야 한다. 줄 끝에 주석이 붙었는지 보세요"
    awk -v n="$L" 'NR==n' "$CF" | sed 's/^/      /'
    doubt
    continue
  fi
  TMP=$(mktemp) || exit 1
  awk -v n="$L" -v to="$TO" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
  cp "$TMP" "$CF"; rm -f "$TMP"
  NOW=$(tag_at "$L")
  if [ "$NOW" = "$TO" ]; then ok "$SVC → $TO (${L}줄)"; else bad "$SVC 의 태그가 $NOW 다"; fi
done

# 🔴 도구 둘은 --go 일 때만 고친다. --rollback 은 **손대지 않는다.**
if [ "$MODE" = go ]; then
  for pair in "$AS_TOOLS_SVC $AS_TOOLS_NEW" "$AUTH_TOOLS_SVC $AUTH_TOOLS_NEW"; do
    set -- $pair
    TL=$(img_line "$1") || { bad "$1 — image: 줄을 못 찾았다"; continue; }
    TNF=$(nf_at "$TL")
    if [ "${TNF:-0}" != "2" ]; then
      bad "🔴 $1 의 ${TL}줄이 낱말 ${TNF:-?}개다 — 'image: 태그' 두 낱말만 있어야 한다"
      awk -v n="$TL" 'NR==n' "$CF" | sed 's/^/      /'
      doubt
      continue
    fi
    TMP=$(mktemp) || exit 1
    awk -v n="$TL" -v to="$2" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
    cp "$TMP" "$CF"; rm -f "$TMP"
    TNOW=$(tag_at "$TL")
    if [ "$TNOW" = "$2" ]; then ok "$1 → $2 (${TL}줄)"; else bad "$1 의 태그가 $TNOW 다"; fi
  done
else
  say "🔵 도구 둘은 이번 모드($MODE)에서 **안 건드린다** — $AS_TOOLS_NEW · $AUTH_TOOLS_NEW 그대로 둔다"
fi

L1=$(wc -l < "$CF"); IMGS1=$(grep -c '^ *image:' "$CF")
grep -n '^ *image:' "$CF" > "$AFT"
DIFFN=$(diff "$BEF" "$AFT" | grep -c '^[<>]' || true)
rm -f "$BEF" "$AFT"
say "줄 수 $L0 → $L1 · image: 줄 $IMGS0 → $IMGS1 · 달라진 image: 줄 $((DIFFN / 2))개"
[ "$L1" = "$L0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
[ "$IMGS1" = "$IMGS0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
# 🔴 **남의 image: 줄을 건드리면 안 된다.** 세어서 정한 수와 같아야 한다.
[ "$((DIFFN / 2))" = "$WANT_DIFF" ] && ok "image: 줄이 꼭 ${WANT_DIFF}개만 달라졌다 (우리 것 · app-po 는 안 건드렸다)" \
  || { bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — ${WANT_DIFF}개를 기대했다. 남의 것을 건드렸을 수 있다"; doubt; }
dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 6. 앱 **둘**을 다시 띄운다 ────────────────────────────────────────
#  🔴 도구 둘은 profiles: [tools] 라 up -d 로 띄우지 않는다. 태그만 고쳐 두면
#     다음에 run --rm 으로 부를 때 새 이미지를 쓴다.
#  🔴 **앱이 둘이라 52번보다 정지 창이 길다.** 🔵 그래도 --no-deps 라 DB 둘과
#     나머지 여덟은 안 멈춘다.
#  🔵 **app-po 는 안 띄운다.** 이번 범위에 PO 코드가 0줄이다.
#     🔴 다만 **A/S 쪽 API 의 거절 코드가 하나 늘었다** — 꼬리말에 적었다.
printf '\n== 6. 앱 둘을 다시 띄운다\n'
printf '%s\n' "🔴 --no-deps 다 — 앱 둘만 갈아 끼운다. 나머지 여덟과 DB 둘은 안 건드린다."
printf '%s\n' "🔴 **포털도 함께 뜬다** — 뜨는 동안 **사내 모든 시스템의 로그인이 잠깐 멈춥니다.**"
for r in $(rows); do
  CN=$(fld "$r" 3)
  say "$CN 지금: $("$DOCKER" inspect -f '{{.Id}}' "$CN" 2>/dev/null | cut -c1-12)"
done
say "dss-po 지금: $("$DOCKER" inspect -f '{{.Id}}' "$PO_APP_CN" 2>/dev/null | cut -c1-12)  ← 7절에서 **그대로인지** 본다"
PO_ID0=$("$DOCKER" inspect -f '{{.Id}}' "$PO_APP_CN" 2>/dev/null)
# 🔵 DB 둘의 시작 시각을 적어 둔다 — 교체 뒤에 **그대로인지** 본다.
DBSTART=""
for c in $KEEP_DB; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
  DBSTART="$DBSTART $c=$s"; say "$c 시작 $s"
done
TSEC=$SECONDS
SVCS=$(for r in $(rows); do printf '%s ' "$(fld "$r" 2)"; done)
say "다시 띄울 서비스: $SVCS"
dc up -d --no-deps $SVCS 2>&1 | sed 's/^/    /'
say "뜨는 것을 25초 기다린다…"; sleep 25
say "정지 구간 $((SECONDS - TSEC))초"

# ── 7. 값으로 확인 ───────────────────────────────────────────────────
printf '\n== 7. 값으로 확인\n'
VER_SEEN=0
for r in $(rows); do
  VER_SEEN=$((VER_SEEN+1))
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5); PORT=$(fld "$r" 7)
  if [ "$MODE" = rollback ]; then TO=$OLD; else TO=$NEW; fi
  ST=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  HL=$("$DOCKER" inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}없음{{end}}' "$CN" 2>/dev/null)
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$PORT/" 2>/dev/null)
  say "$CN — ${ST:-?} · 건강 ${HL:-?} · 이미지 ${RUN:-?} · 127.0.0.1:$PORT → ${CODE:-없음}"
  [ "$ST" = running ] && ok "$CN 가 돈다" || bad "$CN 가 안 돈다 (${ST:-못 찾음})"
  [ "$RUN" = "$TO" ] && ok "$CN 가 $TO 로 돈다" || bad "$CN 가 $RUN 로 돈다"
  # 🔴 303(See Other)을 빠뜨리면 **멀쩡한 사이트가 ✗ 로 나온다**(2026-10-30 실측).
  #    A/S 는 307 로 로그인에 보내고 PO 는 303 으로 보낸다. 🔵 포털은 제가 로그인이라
  #    **200** 이 나온다 — 넷을 다 받는다.
  printf '%s' "$CODE" | grep -qE '200|30[1237]' && ok "$CN 가 응답한다 ($CODE)" || bad "$CN 응답이 ${CODE:-없음}"
done
[ "$VER_SEEN" = "$SITES_WANT" ] && ok "앱 ${SITES_WANT}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "🔴 앱을 ${VER_SEEN}개만 봤다 — ${SITES_WANT}개를 기대했다"

# 🔴 **PO 가 그대로 도는가** — 이번 판에서 안 건드렸다는 증거다.
PO_ID1=$("$DOCKER" inspect -f '{{.Id}}' "$PO_APP_CN" 2>/dev/null)
PO_RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$PO_APP_CN" 2>/dev/null)
PO_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$PO_PORT/" 2>/dev/null)
say "dss-po — 이미지 ${PO_RUN:-?} · 127.0.0.1:$PO_PORT → ${PO_CODE:-없음}"
[ -n "${PO_ID0:-}" ] && [ "${PO_ID0:-x}" = "${PO_ID1:-y}" ] && ok "dss-po 가 **그대로다**(상자 번호가 안 바뀌었다 — 안 건드렸다)" \
  || hm "dss-po 의 상자 번호가 달라졌다 (${PO_ID0:0:12} -> ${PO_ID1:0:12}) — 안 건드렸어야 한다. 사람이 보세요"
printf '%s' "$PO_CODE" | grep -qE '200|30[1237]' && ok "dss-po 가 응답한다 ($PO_CODE · PO 는 303 으로 로그인에 보낸다)" \
  || bad "dss-po 응답이 ${PO_CODE:-없음}"

# 🔴 DB — 기록이 **125 그대로**인가 (앱 교체가 DB 를 건드릴 일은 없다)
MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
say "A/S 마이그레이션 ${MIG_AS0:-?} -> ${MIG_AS1:-?} (기대 $AS_MIG_AFTER)"
[ "${MIG_AS1:-x}" = "$AS_MIG_AFTER" ] && ok "$AS_MIG_AFTER 다 (0124 가 적용된 상태 그대로다)" \
  || bad "🔴 ${MIG_AS1:-?} 다 — $AS_MIG_AFTER 여야 한다. **DB 가 그 사이에 움직였다**"
MIG_AU1=$(mig_count "$AUTH_BOX" "$AUTH_DB")
say "포털 마이그레이션 ${MIG_AU0:-?} -> ${MIG_AU1:-?} (기대 $AUTH_MIG_KEEP)"
[ "${MIG_AU1:-x}" = "$AUTH_MIG_KEEP" ] && ok "포털이 $AUTH_MIG_KEEP 그대로다 (안 건드렸다)" \
  || bad "🔴 포털이 ${MIG_AU1:-?} 다 — $AUTH_MIG_KEEP 그대로여야 한다"
# 🔴 **0124 가 만든 열이 아직 있는가** — --rollback 에서도 있어야 한다(더하기만 했다).
if [ "$MODE" = go ]; then
  NC=$(has_column     "$AS_BOX" "$AS_DB" "$AS_NEW_COL_TABLE" "$AS_NEW_COL")
  E1=$(has_enum_value "$AS_BOX" "$AS_DB" "$AS_NEW_ENUM1" "$AS_NEW_ENUM_VALUE")
  I1=$(has_index      "$AS_BOX" "$AS_DB" "$AS_NEW_IDX1")
  say "0124 의 칸 ${NC:-?} · enum ${E1:-?} · 유니크 인덱스 ${I1:-?} (셋 다 1 이어야 한다)"
  if [ "${NC:-0}" = "1" ] && [ "${E1:-0}" = "1" ] && [ "${I1:-0}" = "1" ]; then
    ok "0124 가 만든 것이 그대로 있다 — **새 앱이 읽을 칸이 있다**"
  else
    bad "🔴 0124 의 칸·enum·인덱스가 ${NC:-?}·${E1:-?}·${I1:-?} 다 — **새 앱이 그 자리에서 깨진다**"
    doubt
  fi
fi

# 🔴 **양식을 다시 잰다** — 교체 뒤에도 그대로인지, 그리고 **새 앱이 보는지.**
templates_check
# 🔴 **발주서 폴더를 다시 잰다** — 새 앱의 기타건 [발주서] 탭이 그 자리를 읽는다.
purchase_order_archive_check
# 🔴 **PO 권한을 다시 잰다** — 앱을 안 갈아 끼웠으니 답이 같아야 하지만, **같은지를 봐야** 안다.
po_write_privilege_check soft

# 🔴 도구 태그 둘이 제대로 섰는지 + 이미지 안이 온전한지 다시 센다
for pair in "$AS_TOOLS_SVC $AS_TOOLS_NEW" "$AUTH_TOOLS_SVC $AUTH_TOOLS_NEW"; do
  set -- $pair
  TL=$(img_line "$1" 2>/dev/null || true)
  if [ -n "${TL:-}" ]; then
    TCUR=$(tag_at "$TL")
    # 🔵 --go 도 --rollback 도 도구 기대값은 **새 판으로 같다** — 되돌려도 그대로 둔다.
    [ "$TCUR" = "$2" ] && ok "$1 가 $2 다" || bad "$1 의 태그가 $TCUR 다 — $2 를 기대했다"
    "$DOCKER" image inspect "$TCUR" >/dev/null 2>&1 && ok "$TCUR 이미지가 NAS 에 있다" \
      || bad "$TCUR 이미지가 NAS 에 없다 — 다음에 부를 때 못 쓴다"
  else
    bad "compose 에 $1 이 없다"
  fi
done
if [ "$MODE" = go ]; then as_tools_inside_check; auth_tools_inside_check; fi
# 🔴 42번에서 넣은 검사는 **그대로 둔다**.
if [ "$MODE" = go ]; then kyosan_folder_check; fi

# 🔴 **안 건드린 여덟이 그대로 도는지** 센다 — 「옆으로 안 샜다」는 증거다.
#    🔴 **52번은 아홉이었다**(dss-auth 포함). 이번엔 포털을 건드리므로 여덟이고,
#       포털은 위 7절 첫 고리가 **다시 떴는지**까지 값으로 쟀다.
printf '\n    ── 안 건드린 여덟 (그대로여야 한다)\n'
KEEP_SEEN=0
for c in $KEEP_BOXES; do
  KEEP_SEEN=$((KEEP_SEEN+1))
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
  [ "$s" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
done
[ "$KEEP_SEEN" = "$KEEP_BOXES_WANT" ] && ok "안 건드린 여덟을 다 봤다 (표본이 비지 않았다)" \
  || bad "안 건드린 상자를 ${KEEP_SEEN}개만 봤다 — ${KEEP_BOXES_WANT}개를 기대했다. KEEP_BOXES 가 깨졌다"
# 🔴 **dss-auth 가 이 목록에 남아 있지 않은가** — 52번에서 베껴 올 때 빠뜨리기 쉽다.
#    🔵 남아 있으면 「안 건드렸는데 왜 다시 떴지」로 읽혀 ✗ 가 엉뚱하게 난다.
if printf '%s\n' "$KEEP_BOXES" | tr ' ' '\n' | grep -qx 'dss-auth'; then
  bad "🔴 KEEP_BOXES 에 dss-auth 가 남아 있다 — **이번 판은 포털을 건드린다.** 52번에서 그대로 베꼈다"
else
  ok "KEEP_BOXES 에 dss-auth 가 없다 (포털은 SITES 에서 **다시 떴는지**까지 쟀다)"
fi

# 🔴 **「상자가 돈다」와 「물어보니 답한다」는 다른 말이다.**
if [ "$MODE" = go ]; then inventory_gateway_check strict; fi

printf '\n    ── DB 둘이 안 멈췄는가 (시작 시각이 그대로여야 한다)\n'
for c in $KEEP_DB; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
  b=$(printf '%s' "$DBSTART" | tr ' ' '\n' | sed -n "s/^$c=//p")
  printf '      %-14s %s\n' "$c" "${s:-없음}"
  [ "${s:-x}" = "${b:-y}" ] && ok "$c 가 안 멈췄다" || bad "🔴 $c 가 다시 떴다 (${b:-?} -> ${s:-?})"
done

# 🔴 **후속 작업 둘을 값으로 다시 센다** — 배포 직후엔 ① 이 0 인 것이 정상이다.
if [ "$MODE" = go ]; then followup_counts; fi

printf '\n    ── 최근 로그 (12줄씩)\n'
for r in $(rows); do
  CN=$(fld "$r" 3)
  printf '      ── %s\n' "$CN"
  "$DOCKER" logs --since 3m "$CN" 2>&1 | tail -12 | sed 's/^/        /'
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
if [ "$FAIL" = 0 ]; then
  printf '%s\n' "✅ 기계로 잴 수 있는 것은 전부 통과했다."
  printf '%s\n' "  compose 사본: $BK"
  printf '%s\n' "  로그: $LOG"
  if [ -n "${DUMP:-}" ]; then printf '%s\n' "  DB 덤프: $DUMP"; fi
  printf '%s\n' ""
  printf '%s\n' "🔵 **백필은 다시 돌리지 않는다.** 44~52번과 같다 — 백필은 2026-10-29 새벽에"
  printf '%s\n' "   283건이 끝났고, 이번 판은 **기타건**이다. 연락서를 읽는 규칙과 무관하다."
  printf '%s\n' "   🔵 도구는 올렸지만 돌릴 까닭은 없다 — 올리는 것과 돌리는 것은 다른 일이다."
  printf '%s\n' ""
  printf '%s\n' "🔴 **이번 판의 엑셀 읽개 둘은 NAS 에서 돌리지 마세요.**"
  printf '%s\n' "   scripts/import-technical-task-procedures.ts ·"
  printf '%s\n' "   scripts/link-technical-task-next-procedures.ts 는 이미지에 들어 있지만,"
  printf '%s\n' "   둘 다 **개발 DB 게이트**를 지나야 돌고 그 게이트는 루프백 5442 만 통과시킵니다."
  printf '%s\n' "   🔴 **npm 명령도 아닙니다** — npm run 으로 부르면 Missing script 가 납니다."
  printf '%s\n' ""
  if [ "$MODE" = go ]; then
    printf '%s\n' "══════════════════════════════════════════════════════════════"
    printf '%s\n' "🔴 **지금 바로 해야 하는 일 — ① 이 가장 중요합니다**"
    printf '%s\n' "══════════════════════════════════════════════════════════════"
    printf '%s\n' "  ① 🔴 **[사용자 관리] › [승인 절차] 에서 「기타건 최종 출하 승인」 결재선을 한 판 세우세요.**"
    printf '%s\n' "     🔴 **안 세우면 기타건을 아무도 [완료] 처리할 수 없습니다.** 새 갈래는 판이"
    printf '%s\n' "        0개이고, 이번 판부터 완료에 승인이 필요합니다."
    printf '%s\n' "     🔵 위 「배포 뒤 사람이 해야 하는 일 둘」에 **지금 막히는 기타건이 몇 건인지**"
    printf '%s\n' "        찍혀 있습니다. 그 수만큼이 [완료]에서 막힙니다."
    printf '%s\n' "     🔵 세운 뒤 다시 재려면:  bash $0 --count"
    printf '%s\n' ""
    printf '%s\n' "  ② 포털 관리자 화면 › **결재 알림 메일** 에서 「기타건 최종 출하 결재」 스위치를 켜세요."
    printf '%s\n' "     🔵 **안 켜도 종과 통합 승인함은 뜹니다.** 메일만 안 갑니다."
    printf '%s\n' "     🔵 기본값이 끔인 것은 2026-10-23 결정입니다 — 안 켜는 것도 정상입니다."
    printf '%s\n' "══════════════════════════════════════════════════════════════"
    printf '%s\n' ""
    printf '%s\n' "🔵 **도구로 수를 세어 --go 전과 견줘 두세요 (읽기만 합니다):**"
    printf '%s\n' "      bash $0 --count"
    printf '%s\n' "   🔵 이번 배포는 그 수들과 **상관이 없습니다** — 달라졌다면 그 사이에 사람이"
    printf '%s\n' "      저장한 것입니다."
    printf '%s\n' ""
  fi
  printf '%s\n' "🔴 **마지막은 눈입니다** — 이번 판은 **기타건 기능 전체**입니다."
  printf '%s\n' ""
  printf '%s\n' "  ── A. 기타건 현황 · 상세 ────────────────────────────────────"
  printf '%s\n' "  ① [내자정리]에서 **수리건이 안 붙은 줄의 [형식]을 누르면** 기타건 상세가 열리는가"
  printf '%s\n' "  ② 기타건 현황 화면이 **수리건 안 붙은 줄만** 모아 보여 주는가"
  printf '%s\n' "  ③ 상세의 **기본정보가 두 박스**로 보이는가"
  printf '%s\n' "  ④ [견적서] 탭 — 연결된 견적서가 뜨고, 없으면 **번호로 공유폴더**를 찾는가"
  printf '%s\n' "  ⑤ [발주서] 탭 — **내자에 적힌 발주서번호**로 폴더를 찾는가"
  printf '%s\n' "     🔵 위 7절이 그 공유폴더가 **열리는지**를 값으로 쟀습니다. 안 열리면 거기부터입니다."
  printf '%s\n' ""
  printf '%s\n' "  ── B. 승인 ──────────────────────────────────────────────────"
  printf '%s\n' "  ⑥ 🔴 [승인] 탭에서 **승인을 올릴 수 있는가** — 결재선을 먼저 세워야 합니다(위 ①)."
  printf '%s\n' "  ⑦ 🔴 **승인 전에는 [완료] 처리가 막히고**, 막히는 **까닭이 글로 보이는가**"
  printf '%s\n' "     (판이 없으면 「판을 만들라」 · 안 올렸으면 「올리라」 · 반려면 「다시 올리라」)"
  printf '%s\n' "  ⑧ 승인이 끝난 뒤 **[완료] 처리가 되는가**"
  printf '%s\n' ""
  printf '%s\n' "  ── C. 알림 ──────────────────────────────────────────────────"
  printf '%s\n' "  ⑨ 승인을 올리면 **포털 종**에 뜨는가 · **통합 승인함**에 뜨는가"
  printf '%s\n' "  ⑩ 🔴 **종 배지의 숫자와, 종을 눌렀을 때 나오는 줄 수가 같은가**"
  printf '%s\n' "     (이번 판에서 고친 자리입니다 — 전에는 배지가 덜 세어졌습니다)"
  printf '%s\n' "  ⑪ 견적서 공급처가 **고르개**로 바뀌었는가 (고객사 마스터와 이어집니다)"
  printf '%s\n' ""
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "🔴 **알고도 안 고친 것 — PO 가 새 거절 코드를 모릅니다**"
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "  이번 판부터 A/S 의 내자 완료 통로가 **409 APPROVAL_REQUIRED** 를 돌려줄 수"
  printf '%s\n' "  있는데, 운영에 도는 **dss-po:0.9 가 그 코드를 모릅니다**(2026-11-07 실측)."
  printf '%s\n' "  🔴 그래서 **PO 에서** 기타건을 [완료 처리] 하면 A/S 가 적어 보낸 안내 문장이"
  printf '%s\n' "     안 뜨고 「모르는 응답」으로 떨어집니다."
  printf '%s\n' "  🔵 **자료는 안 깨집니다** — A/S 는 한 글자도 안 쓴 채 거절했고, PO 도"
  printf '%s\n' "     「완료되었습니다」라고 말하지 않습니다(「바뀌었는지 알 수 없다」로 끝납니다)."
  printf '%s\n' "  🔵 **A/S 화면에서는 까닭이 제대로 보입니다** — 기타건 완료는 A/S 에서 하세요."
  printf '%s\n' "  🔴 **이 배포는 그것을 안 고칩니다**(PO 를 안 굽습니다). 다음 PO 판에서"
  printf '%s\n' "     AS_COMPLETION_REJECT_CODES 에 그 코드를 더하면 문장이 뜹니다."
  printf '%s\n' ""
  printf '%s\n' "🔵 **절차 이관(52번 꼬리말에서 넘어온 할 일)** — 🔴 이미 하셨으면 건너뛰세요."
  printf '%s\n' "   --count 가 운영의 절차 수를 찍습니다. 안 하셨으면 **개발 PC 에서 짐을 뜨고**"
  printf '%s\n' "   (541287aa 부터 --prefix 로 갈래를 나눌 수 있습니다) 아래 차례로 넣습니다:"
  printf '%s\n' "     (NAS) mkdir -p $D/transfer && chmod 777 $D/transfer   🔴 755 는 scp 가 못 씁니다"
  printf '%s\n' "     (개발 PC) npm run procedures:export -- --prefix \"[RFG]\" --out \"\$env:TEMP/rfg.json\""
  printf '%s\n' "     (개발 PC) scp -O \"\$env:TEMP/rfg.json\" dss-nas:$D/transfer/"
  printf '%s\n' "     (NAS) $DOCKER compose -f $CF --env-file .env.nas --profile tools \\"
  printf '%s\n' "             run --rm -v $D/transfer:/transfer:ro $AS_TOOLS_SVC \\"
  printf '%s\n' "             npm run procedures:import -- --file /transfer/rfg.json --actor <uuid>"
  printf '%s\n' "     (NAS) 같은 명령 앞에 **-e APPLY=1** 을 더하면 실제로 넣습니다."
  printf '%s\n' "   🔵 --actor 없이 부르면 고를 수 있는 계정을 찍고 멈춥니다(읽기만 합니다)."
  printf '%s\n' "   🔵 넣은 절차는 **전부 DRAFT** 입니다 — 화면에서 보고 사람이 따로 게시합니다."
  printf '%s\n' ""
  printf '%s\n' "  🔵 **아무것도 안 바뀐 것처럼 보이면** 앱 둘이 정말 새 태그로 도는지(위 7절) 먼저"
  printf '%s\n' "     보시고, 맞다면 알려 주세요."
  printf '%s\n' ""
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (앱 **둘**만 되돌립니다)"
  printf '%s\n' "  🔵 도구 둘은 $AS_TOOLS_NEW · $AUTH_TOOLS_NEW 그대로 둡니다."
  printf '%s\n' "  🔵 **DB 는 되돌리지 않아도 됩니다** — 0124 는 칸과 제약을 **더하기만** 했고,"
  printf '%s\n' "     옛 판은 그 칸을 모르는 채 멀쩡히 돕니다. 그래도 덤프는 위에 적혀 있습니다."
  printf '%s\n' "  🔴 **옛 볼륨 $MIGDIR.old 는 그대로 두세요** — DB 까지 되돌려야 하는 날의 길입니다."
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
  printf '%s\n' "  🔵 ✗ 가 **재고 관리 통로** 하나뿐이라면 되돌리기 전에 설정을 먼저 보세요 —"
  printf '%s\n' "     INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN (env/as.env). 🔴 되돌려도 같은"
  printf '%s\n' "     설정 문제는 남습니다 — 옛 판도 같은 통로를 씁니다."
  printf '%s\n' "  🔴 ✗ 가 **PO 의 repair_cases 쓰기 권한**이라면 그것은 **이 배포가 만든 일이**"
  printf '%s\n' "     **아닙니다**(PO 를 안 건드립니다). 되돌려도 안 고쳐집니다 — 사람이 봐야 합니다."
  printf '%s\n' "  🔴 ✗ 가 **양식**이라면 되돌리지 마세요 — 이 배포는 양식을 한 장도 안 건드립니다."
  printf '%s\n' "  🔴 ✗ 가 **발주서 공유폴더**라면 되돌려도 안 고쳐집니다 — 볼륨·권한 문제입니다."
  printf '%s\n' "  🔵 **DB 는 되돌리지 마세요** — 0124 는 더하기만 했고 옛 판도 그대로 돕니다."
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
