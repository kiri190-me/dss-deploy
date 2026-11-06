#!/bin/bash
# dss-deploy/nas/setup/52-deploy.sh — 마흔아홉째 배포 (2026-11-06)
#
# 🔴 NAS 에서 돈다. **DSM 터미널은 긴 명령을 잘라 먹는다**(2026-10-12 하루에 네
#    번 깨졌다). 그래서 손으로 치지 않고 **파일로 올려** 돌린다. 절차는 이렇다:
#      ① (개발 PC · PowerShell) — 🔴 **경로는 빗금으로**
#           cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#           scp -O 52-deploy.sh dss-nas:/volume1/dss/setup/
#           Get-FileHash -Algorithm MD5 52-deploy.sh
#      ② (NAS) md5sum /volume1/dss/setup/52-deploy.sh
#      ③ 🔴 **두 md5 가 같은지 눈으로 맞댄다.** 다르면 옮기다 잘린 것이다 —
#         그대로 돌리면 중간에서 끊긴 스크립트가 compose 를 고치다 만다.
#      🔵 이 파일은 돌 때 맨 위에서 **제 md5 를 스스로 찍는다.** ②를 따로 안
#         쳐도 로그에 남는다.
#    🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#    🔴 **역슬래시 경로를 쓰지 마라.** bash 와 scp 가 그 역슬래시를 먹어
#       "C:Users희만Desktop…" 가 된다. 🔵 48번이 51-build.sh 의 머리말만 고쳤고
#       **51-deploy.sh 에는 아직 역슬래시 예시가 남아 있다**(그 파일 6~9줄 ·
#       1152줄 · 1333줄). **거기서 베껴 오지 마라.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이번 판은 **이미지 둘뿐이다** — 양식도, 마이그레이션도 없다
# ══════════════════════════════════════════════════════════════════════
#   갈아 끼우는 것 — **저장소 하나, 태그 둘**
#     ① A/S 앱   dss-as:4.4       → **dss-as:4.5**        커밋 12
#     ② A/S 도구 dss-as-tools:11  → **dss-as-tools:12**   커밋 12
#
#   🔴 **PO 는 안 건드린다.** dss-po 의 HEAD 가 기준 SHA(9c1b2ef) 그대로라 구울
#      것이 없다(2026-11-06 실측 — 52-build.sh 머리말). dss-po:0.9 가 그대로 돈다.
#   🔵 **나머지 여덟도 안 건드린다** — 통합 로그인 · 재고 · 게시판 · 계측기 ·
#      개선요청 · RF 이슈관리 · 휴가 · 통합 승인함.
#
#   🔵 **양식(.xlsx)은 한 장도 안 올린다.** 이번 범위에 .xlsx 변경이 0줄이고
#      개발 PC 의 양식 열하나가 48번 값 그대로다. 그래서 이 파일에는
#      **--templates-prep 와 --templates-apply 가 없다.**
#      🔴 **양식이 바뀌는 날 되살릴 곳**: 51-deploy.sh 의 1056~1172줄
#         (--templates-prep) · 1174~1341줄(--templates-apply) · 61~74줄(머리말).
#         🔵 그 둘을 **지운 것이 아니라 이 판에서 뺀 것**이다. 자리를 적어 두는
#            까닭은 48번이 --migrate 를 찾으러 39번까지 거슬러 갔기 때문이다.
#      🔵 다만 **재는 쪽은 남겼다** — 1-ㄷ 절이 운영 양식 열하나를 md5 로 재고,
#         앱이 그것을 읽는지 설정 이름으로 묻는다. 한 번 빼면 다시 넣는 사람이 없다.
#
# ── 🔴 마이그레이션 — **0건이다.** 그래도 --migrate 모드를 안 걷어냈다 ───
#   2026-11-06 실측: git diff --name-only 8a98e461..HEAD -- drizzle/ → **0줄**
#   저장소의 drizzle/*.sql **124장** · idx **124개** · 마지막이 **0123** · 0124 없음.
#   운영 기록도 볼륨도 **124** 다(48번이 121 → 124 로 올렸다).
#
#   🔴 **왜 모드를 남기는가**: 39번 이후 40~47번이 전부 0건이었더니 마이그레이션
#      절이 **통째로 사라졌고**, 48번에서 다시 필요해졌을 때 39번까지 거슬러 가
#      가져와야 했다. 그때 DESTRUCTIVE_RE·MIG_DROP_WANT 를 같이 안 가져와 적용
#      **직전에 죽었다.** 같은 일을 반복하지 않으려고 남긴다.
#   🔴 **이번 판에서 그 모드가 재는 것** — 빈 껍데기가 아니다:
#      · 볼륨의 .sql 과 idx 가 **둘 다 124** 인가 (호스트와 **컨테이너 안** 둘 다)
#      · **0124 가 없는가** (새 마이그레이션이 0장인가)
#      · 48번이 올린 셋(0121·0122·0123)의 .sql 과 스냅샷이 **아직 온전한가**
#      · 지우는 문장이 **0줄**인가 — 잣대가 살아 있는지 표본 둘로 확인하고 센다
#      · db:preflight 의 **대기가 0건**인가
#      · db:migrate 를 **실제로 부르고**, 기록이 **앞뒤로 둘 다 124** 인가
#      · 48번이 만든 표 하나 · 칸 둘 · 인덱스 하나가 **아직 있는가**
#      · 줄 수가 그대로인가
#
# ── 🔴 기준 SHA — 두 출처를 맞대어 확인했다 (2026-11-06) ─────────────
#   · **A/S 8a98e461** : README.md 의 「기준 SHA (2026-11-04 23:40 갱신)」 표가
#     | A/S 관리 | RF_Service_System | **4.4** | **8a98e461** | 이라고 적고,
#     48번 배포 기록의 범위가 df16e6c3..**8a98e461** 이다 — 48번이 구운 HEAD 다.
#   · **PO 9c1b2ef** : 같은 표가 | PO | dss-po | 0.9 | 9c1b2ef | 이라고 적는다.
#   🔵 둘 다 지시서의 값과 맞았다. **세 출처가 전부 같았다.**
#
# ── 이 배포가 하는 일 — **절차 화면 정리 + 도구 둘** ─────────────────
#   A/S  8a98e461..c6b2b271 (열셋 · 파일 83)
#     c6b2b271 개발에서 만든 절차를 떠서 운영에 넣는 길
#     ea0dc8c9 셀로 그린 흐름도를 읽는다 — (MB) 수리 한 장에서 절차 열하나
#     949d25be NG 수평 규칙이 큰 흐름도에서 절반만 듣던 것을 고친다
#     d5d71962 연결선이 실제로 그려지는 자리를 읽는다 — 돌림각과 꺾임점
#     b3945808 엑셀 분기를 정상·NG 둘로 통일하고, 글자 없는 이음목을 이어 붙인다
#     866f00d5 절차 흐름도를 원본 엑셀처럼 세운다 — 메인줄기는 한 열, NG 는 옆으로
#     306fc695 엑셀 연결을 제대로 읽는다 — 묶음을 풀고, 끊어진 선 끝을 좌표로 잇는다
#     8c824236 엑셀 흐름도를 사람이 센 것과 같게 읽는다 — 노드 제목에 원본 글자를 다 싣는다
#     764b37a3 절차 코드를 사람 눈에서 걷고, 목록에 이름 검색과 설비 유형 거르개를 단다
#     6802a132 날짜 칸의 연도를 네 자리로 묶는다 — 상한 한 줄이면 브라우저가 한다
#     7f72c373 절차 노드를 중심점 기준으로 세운다 — 그리고 더해도 남이 안 밀린다
#     155b266b 엑셀 도형 흐름도를 기술 작업 절차로 읽는다 — 좌표로 분기 이름을 가린다
#     19dc0cb0 진행현황 — 기술 작업 절차가 운영으로 나갔다
#
#   🔴 **DB 의 구조도, 저장된 글자도 이 배포가 바꾸지 않는다.**
#   🔵 **compose·env 파일에 더할 설정 이름이 없다.** 2026-11-06 실측으로 이 범위에
#      늘어난 process.env 이름은 **APPLY 하나**뿐이다.
#      🔴 처음에는 「개발 PC 에서 쓰는 값」이라고 적었는데 **그 글이 틀렸다** —
#         APPLY 는 **NAS 에서** procedures:import 를 쓰기 모드로 돌릴 때 쓴다
#         (docker compose run 에 -e APPLY=1 로 준다). 다만 **그때 한 번만** 주는
#         값이라 .env.nas 에도 env/as.env 에도 **적지 않는다** — 적어 두면
#         드라이런이 기본이라는 안전장치가 통째로 사라진다.
#      🔵 그래서 「설정 파일은 안 바꾼다」는 결론은 그대로다. 까닭만 달라졌다.
#   🔵 **src/app/api 가 0줄 바뀌었다** — PO 와의 계약이 그대로라는 뜻이다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 새 도구 **다섯**은 갈래가 셋이다 — 하나만 NAS 에서 돈다
# ══════════════════════════════════════════════════════════════════════
#   🔴 **한 잣대로 재면 가짜 ✗ 가 난다.** 갈래마다 다른 것을 잰다.
#
#   ㄱ) 🔒 **개발 PC 전용 — NAS 에서 돌릴 것이 아니다**
#        scripts/import-technical-task-procedures.ts
#        scripts/link-technical-task-next-procedures.ts
#      둘 다 dev-database-write-guard 의 **checkDevelopmentWriteTarget** 를 지나야
#      돌고, 그 게이트는 **루프백 + 포트 5442** 만 통과시킨다 — NAS 에서 부르면
#      멈춘다. 🔴 **그래서 꼬리말에 그 둘의 NAS 명령을 적지 않는다.**
#      🔵 npm 명령도 아니다 — npm run 으로 적으면 Missing script 가 난다.
#
#   ㄴ) 🔴 **운영에서 도는 하나 — 이 배포의 뒤에 이어서 돌린다**
#        scripts/import-procedure-bundle.ts  (npm run **procedures:import**)
#      그 파일 머리말이 스스로 적는다: 「여기엔 개발 DB 에서만 자물쇠가 **없다** —
#      일부러다. 이 도구는 **운영에서 도는 것이 목적**이라 같은 자물쇠를 달면 쓸
#      수가 없다.」 대신 **드라이런 기본 + APPLY=1 + 한 트랜잭션 + 대상 DB 찍기**
#      가 지킨다. 🔴 **그래서 자물쇠가 없는 것이 맞다** — 있으면 ✗ 다.
#      🔴 **이 명령이 이미지 안에 없으면 그날 절차 이관이 통째로 막힌다**(41번의
#         Missing script 그대로). tools_inside_check 가 ②와 ⑩에서 둘 다 센다.
#      🔴 돌리는 차례는 **--go 꼬리말**에 적어 두었다.
#
#   ㄷ) 👀 **읽기 전용 — 개발 PC 에서 짐을 뜬다**
#        scripts/export-procedure-bundle.ts  (npm run procedures:export)
#      쓰는 문장이 **0** 이어야 한다. 자물쇠도 APPLY 도 필요 없다 — 안 쓰기 때문이다.
#
#   🔵 52-build.sh 가 소스에서, 이 파일이 **이미지 안에서** 셋을 각각 센다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **상태 변수를 먼저 정하고 가지를 나눈다** — 48번이 데인 자리다
# ══════════════════════════════════════════════════════════════════════
#   48번에서 --check 의 기대값이 **한 갈래**라 적용 뒤에 다시 부르면 가짜 ✗ 가
#   났다. 그래서 이 파일은 **맨 처음에 운영의 단계(PHASE)를 읽고** 가지를 나눈다.
#     PRE   app=dss-as:4.4 · tools=dss-as-tools:11  → 아직 아무것도 안 갈아 끼웠다
#     MID   app=dss-as:4.4 · tools=dss-as-tools:12  → --migrate 까지 돌았다
#                                                     (또는 --rollback 으로 앱만 되돌렸다)
#     POST  app=dss-as:4.5 · tools=dss-as-tools:12  → --go 까지 돌았다
#     SPLIT app=dss-as:4.5 · tools=dss-as-tools:11  → --go 가 도중에 멈췄다
#     ODD   그 밖 — 멈추고 사람이 본다
#   🔴 **마이그레이션 수만은 가지를 안 나눈다 — 한 갈래가 맞다.** 이번 판은 0건이라
#      **어느 단계에서나 124** 다. 48번은 121/124 로 갈랐는데, 그것을 그대로 베끼면
#      이 판에서는 **「121 이어도 ✓」가 되어 되돌아간 볼륨을 못 잡는다.**
#      🔵 다음 판에 마이그레이션이 생기면 AS_MIG_BEFORE 를 그때 수로 고치면
#         아래 가지가 **저절로 다시 살아난다**(= 로 묶어 둔 곳이 풀린다).
#
# ── 🔴 48~51번에서 그대로 가져온 것 ──────────────────────────────────
#   ① **303 판정**(grep -qE '200|30[1237]'). A/S 는 307, PO 는 303 으로 로그인에
#      보낸다. 빠뜨리면 **멀쩡한 사이트가 ✗ 로 나온다**(2026-10-30 실측).
#   ② 🔴 **치환 전에 그 줄의 낱말 수가 2 인지 본다.** 줄 끝에 주석이 붙어 있으면
#      **주석의 마지막 낱말**이 태그로 바뀌고 image: 값은 그대로 남는다.
#   ③ 🔴 **달라진 image: 줄 수를 박지 않는다 — 세어서 정한다.** 48번에서 그 숫자가
#      판마다 달라 제대로 동작한 --go 가 ✗ 를 받고 되돌아갔다.
#   ④ 🔴 **설정 파일 검사**(중복 키 · auto). 값은 한 글자도 안 찍는다.
#   ⑤ 🔵 연락서 폴더 검사 · 재고 관리 통로 검사는 **42~51번 것 그대로다.**
#      🔴 **빼지 않는다** — 한 번 빼면 다시 넣는 사람이 없다.
#   ⑥ 🔵 **--rollback 은 앱 하나만 되돌린다.** 도구는 :12 그대로 둔다 —
#      39·41~51번과 같은 판단(그 도구들은 전부 읽기 전용이다).
#   ⑦ 🔵 **다시 띄우는 것은 app-as 하나뿐이다.** tools-as 는 profiles: [tools] 다.
#   ⑧ 🔴 **DB 둘의 StartedAt 을 앞뒤로 비교한다** — 안 멈췄다는 증거다.
#   ⑨ 🔴 **제 md5 를 스스로 찍는다** · **image: 줄을 통째로 찍는다**.
#   ⑩ 🔴 **PO 의 repair_cases 쓰기 권한을 잰다** — PO 를 안 건드려도 잰다.
#
# ── 🔴 51번에서 **걷어낸 것**과 까닭 ─────────────────────────────────
#   · --templates-prep · --templates-apply — 이번 판은 양식 0장(위 참조, 자리 적어 둠)
#   · 꼬리말의 'npm run admin:promote' — 🔴 **그런 npm 명령이 없다**(2026-11-06
#     package.json 실측 0건). 부르면 Missing script 가 난다. 지난 판에서 따라온 줄이다.
#   · 「--migrate 모드가 없다」는 머리말 한 줄 — 51-deploy.sh 는 그 줄을 적어 두고
#     **실제로는 --migrate 를 갖고 있었다.** 고치다 만 글이라 안 옮겼다.
#   · 「모드 일곱」 — 51-deploy.sh 는 일곱이라 적고 여덟을 갖고 있었다. 이 파일은
#     **여섯**이고 아래 case 문과 수가 맞는다.
#   · 7-ㄷ 절의 'compose 의 tools-auth 를 :2 → :3 으로' — 37번에서 따라온 **다른
#     서비스 이름**이다. 이 판에서 고치는 것은 tools-as 다.
#   · A/S 범위 커밋 목록 'df16e6c3..df16e6c (여섯)' — 47번 것이 남아 있었다.
#
# ── 모드 여섯 ─────────────────────────────────────────────────────────
#   (기본)   --check     아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --count              세 도구를 **읽기만** 해서 센다
#   --preload            tar 둘을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --migrate            🔵 **0건을 값으로 잰다** + 덤프 + tools-as 태그를 :12 로
#   --go                 compose 의 image: 줄을 바꾸고 app-as 를 다시 띄운다
#   --rollback           app-as 만 옛 판으로 되돌린다 (도구는 :12 그대로)
#
# ── 🔴 --check 도 「아무것도 안 한다」는 아니다 ───────────────────────
#   A/S DB 에 **select** 를 몇 번 보낸다(마이그레이션 수 · 표·칸·인덱스 · PO 의
#   권한 — 바꾸는 문장은 없다). 앱의 주소에 GET 을 한 번 보낸다. 재고 관리 통로에도
#   **GET 을 한 번** 보낸다. 양식 폴더를 **읽는다**(ls 와 md5sum 뿐이다). 도구
#   이미지가 이미 실려 있으면 **안을 보려고 컨테이너를 잠깐 띄웠다 지운다.**
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
#
# ── 🔴 비밀값을 찍지 않는다 ───────────────────────────────────────────
#   설정 파일은 **이름이 있는가/없는가**와 **auto 인가**만 본다. PO 권한 검사는
#   DATABASE_URL 에서 **역할 이름만** 꺼낸다. 🔵 **양식 경로는 찍어도 된다** —
#   /templates/… 는 저장소의 compose 사본에 이미 적혀 있는 값이고 비밀이 아니다.
#   🔴 다만 **/templates 밖을 가리키는 값은 안 찍는다.**
#   🔴 그리고 **한글을 HTTP 머리말·argv 에 넣지 않는다** — 넣으면 요청이 아예 안
#      나가고, 그 ✗ 가 진짜 결함처럼 보인다. 🔵 양식 **이름**은 한글이지만 argv 로
#      넘기지 않는다 — 폴더를 열어 **데이터로** 읽고 찍기만 한다.
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v49-$STAMP
BKDB=$D/backups/db   # 🔴 덤프가 여기 간다 (48번과 같은 자리·같은 이름 규칙)

# ══ 이번에 다시 띄우는 것 — 앱 **하나** ═══════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
#   🔴 **PO 줄이 없다.** 이번엔 안 갈아 끼운다.
SITES='
as|app-as|dss-as|dss-as:4.5|dss-as:4.4|dss-as-4.5.tar|13000
'
# 🔵 7절의 재고 관리 검사가 명령을 넣을 상자. 위 표 셋째 칸과 같은 이름이다.
AS_APP_CN=dss-as
# 🔴 PO 권한 검사가 명령을 넣을 상자. **이번엔 갈아 끼우지 않지만 잰다.**
PO_APP_CN=dss-po
PO_PORT=13600
PO_WANT_TAG=dss-po:0.9
# ══ 🔴 A/S 도구 — **이번에 갈아 끼운다.** up -d 로 다시 띄우지 않는다 ═══
AS_TOOLS_SVC=tools-as
TOOLS_OLD=dss-as-tools:11
TOOLS_NEW=dss-as-tools:12
IMG_MIGDIR=/app/drizzle
MIGDIR=$D/as-migrations

# ══ 🔴 양식 — **올릴 것이 없다. 재기만 한다** ═════════════════════════
#   🔵 운영 자리: compose 의 app-as·app-po 가 둘 다
#      '/volume1/dss/as-templates:/templates:ro' 로 붙인다.
#   🔴 **tools-as 에는 그 볼륨이 없다.** 그래서 양식은 **호스트에서 바로** 재고,
#      「앱이 보는가」는 app-as 안에서 따로 묻는다.
TPLDIR=$D/as-templates
TPL_IN_CONTAINER=/templates

# 🔴 열하나 — 이름|바이트|md5.
#    출처: [실측] 2026-11-06 개발 PC. 🔵 **48번이 적어 둔 값과 글자 그대로 같았다**
#    (바이트도 md5 도 열하나 전부). 그래서 **이번 판에 올릴 양식이 0장**이다.
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

# ══ 🔴 설정 파일 — .env 쪽과 env/*.env 쪽을 **둘 다** 본다 ════════════
ENV_NAS=$D/deploy/.env.nas
ENV_AS=$D/deploy/env/as.env
ENV_PO=$D/deploy/env/po.env

# ══ 🔴 tar 둘의 지문 — [배포본] 52-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 안 채웠다.** 52-build.sh --go 가 끝에 찍어 주는 **두 줄**로 아래
#      두 줄을 통째로 갈아 끼우세요.
#   🔴 비어 있으면 3절이 **--check·--rollback 에서는 ? · --preload·--go 에서는 ✗**
#      로 센다. 🔵 51-deploy.sh 는 「? 라서 --preload 가 막힌다」고 적어 두었는데
#      **실제로는 ? 가 아무것도 안 막았다**(막는 것은 ✗ 뿐이다). 글이 맞도록 고쳤다.
#   🔵 이름만이라도 적어 두는 까닭: 줄이 아예 없으면 4절(--preload)이 **아무것도
#      안 싣고 조용히 끝난다.** 이름이 있으면 싣기는 제대로 된다.
TARS='
dss-as-4.5.tar|133874688|d73fbdc87620b0ca7f1391ccf58b4fb3|sha256:7f4c6bebf3f3cd5d36b48d2abac76e261135a872798ddfd282df0ff2cbefd2ec
dss-as-tools-12.tar|224836096|b6cf8faa4a40c9db88796022326461fb|sha256:b4a7c2e7c3f70c7ac55fd45929e807c066d5054d4036f85e1cd6bd249227ddaa
'
TARS_WANT=2

tar2tag() {
  case "$1" in
    dss-as-4.5.tar)       printf 'dss-as:4.5' ;;
    dss-as-tools-12.tar)  printf 'dss-as-tools:12' ;;
  esac
}

# ══ 🔴 DB — **마이그레이션 0건이라 앞뒤가 같은 수다** ═════════════════
#   🔵 A/S 와 PO 는 **같은 dss_as** 를 본다(PO 는 제 DB 가 없다). 재는 자리도 하나다.
AS_BOX=dss-pg-app; AS_DB=dss_as
# 🔴 **둘이 같은 값인 것이 이 판의 사실이다.** 48번은 121 → 124 였다.
#    다음 판에 마이그레이션이 생기면 AS_MIG_BEFORE 만 그때 수로 고치면 된다 —
#    아래 가지들이 저절로 다시 갈린다.
AS_MIG_BEFORE=124   # [저장소·운영] 48번 기록의 「기록 121 → 124」의 뒷수
AS_MIG_AFTER=124    # [저장소] 52-build.sh 4절과 같다(.sql 124 · idx 124)
AS_LAST_MIG=0123    # [저장소] 마지막 마이그레이션
AS_NEXT_MIG=0124    # 🔴 셈으로 만들지 않는다(8진수 함정). 글자로 적는다
AS_KEEP_MIGS='0121 0122 0123'
# 🔴 「지우는 문장」의 잣대. 앱의 src/lib/db/migration-safety.ts 와 같다.
#    ⚠️ DELETE 는 **DELETE FROM** 일 때만 센다 — 0123 의 ON DELETE restrict 는
#    제약의 동작이지 지우는 문장이 아니다. 안 가르면 더하기만 하는 판이 ✗ 가 된다.
#    🔴 48번은 이 둘을 안 가져와 적용 **직전에 죽었다.** 같이 가져왔다.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
MIG_DROP_WANT=0
# 묶음이 들어오는 자리. 🔵 **이번 판에는 안 보내도 된다**(볼륨이 이미 124).
#    보내면 --migrate 가 md5 로 맞대 보고, 볼륨이 124 가 아닐 때만 푼다.
MIGTAR=$D/setup/incoming/as-migrations.tar.gz
INCOMING=$D/setup/incoming
# 🔴 52-build.sh --go 가 찍어 주는 값. 비워 두면 ? 로만 센다(보험이라 안 막는다).
MIGTAR_SIZE=2383054
MIGTAR_MD5=c015011297edbcd4f438a3bbe3309e2a
# 🔴 **48번이 만든 것이 아직 있는가** — 값으로 확인한다. 기록이 124 라는 것과
#    「그 표와 칸이 정말 있다」는 다른 말이다.
AS_NEW_TABLE=procedure_case_execution_edges
AS_NEW_COL_TABLE=procedure_template_nodes
AS_NEW_COL=next_procedure_template_id
AS_NEW_COL2_TABLE=procedure_case_execution_nodes
AS_NEW_COL2=user_position_x
AS_NEW_INDEX=procedure_template_nodes_next_template_idx
# 🔴 줄 수가 그대로여야 하는 표 — 이 배포는 DB 를 안 건드린다.
AS_COUNT_TABLES='repair_cases procedure_templates procedure_template_nodes procedure_case_executions procedure_case_execution_nodes'
# 🔴 49번이 올린 기능이 쓰는 표. 1-ㄹ 절이 이 이름으로 권한을 묻는다. **ASCII 다.**
PO_WRITE_TABLE=repair_cases
# 🔵 안 건드리는 **아홉** — 「옆으로 안 샜다」는 증거로 센다.
KEEP_BOXES="dss-auth dss-inventory dss-meters dss-board dss-improvements dss-leave dss-approvals dss-rf-trouble dss-po"
KEEP_BOXES_WANT=9
# 🔵 DB 둘은 멈추지 않는다 (애초에 up -d --no-deps 가 app-as 만 건드린다)
KEEP_DB="dss-pg-app dss-pg-auth"

MODE=check
case "${1:-}" in
  --check|"")   MODE=check ;;
  --count)      MODE=count ;;
  --preload)    MODE=preload ;;
  --migrate)    MODE=migrate ;;   # 🔵 이번 판은 0건을 **값으로 잰다**
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
#    그래서 tr -d 를 안 쓰고 빈 줄만 걷는다.
tplrows() { printf '%s\n' "$1" | grep -v '^[[:space:]]*$'; }

dc()  { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas "$@" ); }
dct() { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas --profile tools "$@" ); }

[ "$(id -u)" = 0 ] || { printf '먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요.\n'; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/52-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "마흔아홉째 배포 — A/S 앱·도구 (양식 0장 · 마이그레이션 0건)   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  🔴 개발 PC 의 Get-FileHash 값과 **같은지 눈으로 맞대세요** (DSM 터미널이 긴 것을 잘라 먹습니다)"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  로그: $LOG"
printf '%s\n' "  🔴 차례: --check → --count → (scp tar) → --preload → --check → --migrate → --go → --count"
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
# ══ 🔴 마이그레이션 헬퍼 — 48번이 39번에서 가져온 것을 그대로 ═════════
has_table()  { pgn "$1" "$2" "select count(*) from information_schema.tables where table_schema='public' and table_name='$3'"; }
has_column() { pgn "$1" "$2" "select count(*) from information_schema.columns where table_schema='public' and table_name='$3' and column_name='$4'"; }
has_index()  { pgn "$1" "$2" "select count(*) from pg_indexes where schemaname='public' and indexname='$3'"; }

read_migdir() {
  MIG_N_SQL=0; MIG_N_J=0; MIG_STATE=""
  [ -d "$MIGDIR" ] || { MIG_STATE=NODIR; return 0; }
  MIG_N_SQL=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  if [ -f "$MIGDIR/meta/_journal.json" ]; then
    MIG_N_J=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  fi
  MIG_N_SQL=${MIG_N_SQL:-0}; MIG_N_J=${MIG_N_J:-0}
  # 🔴 **가지가 셋인데 이번 판에서는 둘만 닿는다.** AS_MIG_BEFORE 와 AS_MIG_AFTER
  #    가 같은 수라 OLD 가 안 나온다 — 그것을 **조건으로 드러내** 둔다. 그냥 두면
  #    「닿지도 않는 가지가 통과한 것처럼」 보인다.
  if   [ "$MIG_N_SQL" = "$AS_MIG_AFTER" ] && [ "$MIG_N_J" = "$AS_MIG_AFTER" ]; then MIG_STATE=DONE
  elif [ "$AS_MIG_BEFORE" != "$AS_MIG_AFTER" ] \
       && [ "$MIG_N_SQL" = "$AS_MIG_BEFORE" ] && [ "$MIG_N_J" = "$AS_MIG_BEFORE" ]; then MIG_STATE=OLD
  else MIG_STATE=ODD
  fi
  return 0
}

# 🔴 48번이 올린 셋이 **아직 온전한가** + **새 것이 0장인가**.
#    🔵 이 함수가 48번에서는 「새로 올린 셋이 다 왔는가」였다. 이번 판은 새 것이
#       없으므로 **「그대로 있는가」와 「안 늘었는가」**를 잰다 — 빈 껍데기가 아니다.
check_keep_migs() {
  local t miss="" f n rc=0 c
  for t in $AS_KEEP_MIGS; do
    ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || miss="$miss $t(sql)"
    [ -f "$MIGDIR/meta/${t}_snapshot.json" ]   || miss="$miss $t(snapshot)"
  done
  if [ -z "$miss" ]; then ok "0121·0122·0123 의 .sql 과 meta/*_snapshot.json 이 다 있다 (48번이 올린 그대로)"
  else bad "🔴 빠진 것:$miss"; rc=1; fi
  # 🔴 **새 마이그레이션이 0장인가** — 이 판의 전제다. 글자로 맞댄다(8진수 함정).
  if ls -1 "$MIGDIR/${AS_NEXT_MIG}_"*.sql >/dev/null 2>&1; then
    bad "🔴 볼륨에 $AS_NEXT_MIG 번이 **있다** — 이 배포는 마이그레이션 0건을 전제로 쓰였다. 멈추고 알리세요"
    rc=1
  else
    ok "볼륨에 $AS_NEXT_MIG 번이 없다 (마지막이 $AS_LAST_MIG — 0건이 맞다)"
  fi
  # 🔴 지우는 문장 — 잣대가 살아 있는지 **표본 둘로 먼저** 확인하고 센다.
  if [ "$(printf '%s\n' 'DROP TABLE foo;' | grep -ciE "$DESTRUCTIVE_RE")" != "1" ]; then
    bad "🔴 지우는 문장 잣대가 죽었다 — 아래 「0줄」이 공짜 통과다. 멈추세요"; rc=1
  else
    ok "지우는 문장 잣대가 살아 있다 (가짜 DROP 하나를 제대로 잡았다)"
  fi
  if [ "$(printf '%s\n' 'REFERENCES "b"("id") ON DELETE restrict;' | grep -ciE "$DESTRUCTIVE_RE")" != "0" ]; then
    bad "🔴 ON DELETE 를 지우는 문장으로 센다 — 0123 이 가짜 ✗ 를 받는다"; rc=1
  else
    ok "ON DELETE 는 지우는 문장으로 안 센다 (0123 이 가짜 ✗ 를 안 받는다)"
  fi
  n=0
  for t in $AS_KEEP_MIGS; do
    f=$(ls -1 "$MIGDIR/${t}_"*.sql 2>/dev/null | head -1)
    [ -n "$f" ] || continue
    c=$(grep -ciE "$DESTRUCTIVE_RE" "$f" 2>/dev/null); n=$((n + ${c:-0}))
  done
  if [ "$n" = "$MIG_DROP_WANT" ]; then
    ok "0121·0122·0123 에 지우는 문장이 ${n}줄이다 (기대 ${MIG_DROP_WANT}줄 — 더하기만 한다)"
  else
    bad "🔴 0121·0122·0123 에 지우는 문장이 ${n}줄이다 (기대 ${MIG_DROP_WANT}줄) — 고치지 말고 **먼저 알리세요**"
    rc=1
  fi
  # 🔵 글자 표식 — 올려 둔 것이 그 파일이 맞는지. 이름만 맞고 속이 다를 수 있다.
  #    🔴 셋 다 본다. 하나만 보면 나머지 둘은 이름만 맞아도 통과한다.
  f=$(ls -1 "$MIGDIR/0121_"*.sql 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    grep -qF "CREATE TABLE \"$AS_NEW_TABLE\"" "$f" \
      && ok "0121 안에 표 $AS_NEW_TABLE 를 만드는 줄이 있다" \
      || { bad "🔴 0121 안에 그 표를 만드는 줄이 **없다** — 다른 파일이다"; rc=1; }
  fi
  f=$(ls -1 "$MIGDIR/0122_"*.sql 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    grep -qF "ADD COLUMN \"$AS_NEW_COL2\"" "$f" \
      && ok "0122 안에 칸 $AS_NEW_COL2 를 더하는 줄이 있다" \
      || { bad "🔴 0122 안에 그 칸을 더하는 줄이 **없다** — 다른 파일이다"; rc=1; }
  fi
  f=$(ls -1 "$MIGDIR/0123_"*.sql 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    grep -qF "ADD COLUMN \"$AS_NEW_COL\"" "$f" \
      && ok "0123 안에 칸 $AS_NEW_COL 를 더하는 줄이 있다" \
      || { bad "🔴 0123 안에 그 칸을 더하는 줄이 **없다** — 다른 파일이다"; rc=1; }
  fi
  return "$rc"
}

# 🔴 볼륨이 124 가 **아닐 때만** 묶음을 푼다. 이번 판에는 안 불리는 것이 정상이다.
place_migs() {
  if [ ! -s "$MIGTAR" ]; then
    bad "🔴 볼륨이 어긋났는데 갈아 끼울 묶음이 없다: $MIGTAR"
    say "🔵 52-build.sh --go 가 만든 as-migrations.tar.gz 를 $INCOMING 로 보내세요."
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

# ══ 🔴 덤프 — **마이그레이션이 0건이어도 뜬다** ═══════════════════════
#   🔵 이 배포는 DB 를 한 글자도 안 바꾼다. 그래도 뜨는 까닭:
#      · 되돌릴 때 기준이 되는 **그 시각의 사진**이다. 앱만 되돌려도 「그때 자료가
#        어땠나」를 묻게 되는 날이 온다.
#      · 48번과 **같은 자리·같은 이름 규칙**이라 다음 사람이 찾기 쉽다.
#   🔴 「파일이 생겼다」와 「쓸 만한 덤프다」는 다르다. 크기와 머리 다섯 글자를 본다.
DUMP=""
make_dump() { # 1 왜 뜨는지 한 줄
  printf '\n    ── 덤프를 뜬다 (%s)\n' "$1"
  mkdir -p "$BKDB" 2>/dev/null
  DUMP="$BKDB/dss_as-v49-$STAMP.dump"
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
}

# ══ 🔴 양식 — 한 파일의 md5 (없으면 빈 줄) ════════════════════════════
#   🔴 이름에 공백과 한글이 있다. **전부 큰따옴표로 감싼다.**
tpl_md5() { # 1 폴더 2 파일이름
  [ -s "$1/$2" ] || return 0
  md5sum "$1/$2" 2>/dev/null | awk '{print $1}'
}
tpl_size() { # 1 폴더 2 파일이름
  [ -s "$1/$2" ] || return 0
  stat -c %s "$1/$2" 2>/dev/null
}
# 폴더 안 파일을 전부 찍는다 — 이름 | 바이트 | 시각 | 주인 | 모드 | md5
tpl_dump() { # 1 폴더
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
tpl_file_count() { # 1 폴더
  local n
  [ -d "$1" ] || return 0
  n=$(find "$1" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
  printf '%s' "${n:-}"
}

# ══ 🔴 앱이 그 양식을 **보는가** — 설정 이름으로 묻는다 ══════════════
#   🔴 이름은 전부 ASCII 다. 한글은 **값**으로만 오가고 argv 에 안 들어간다.
#   🔵 /templates 밖을 가리키는 값은 안 찍는다(머리말의 비밀값 규칙).
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

# 🔴 **이번 판에는 올릴 양식이 없다.** 그래서 level 이 하나뿐이다 — 재기만 한다.
#    · md5 가 달라도 ✗ 가 아니다(운영 양식이 개발 PC 것과 같아야 할 보증이 없다)
#    · **설정이 가리키는데 파일이 없으면 ✗** — 그 출력이 통째로 죽는다
#    · 폴더를 아예 못 열었으면 **?** — 처음 도는 검사를 「틀렸다」로 세지 않는다
templates_check() {
  # 🔴 쓰는 이름을 **전부** local 로 묶는다. 이 함수는 7절에서 DB 시작 시각을
  #    세는 고리 **직전**에도 불리는데, 거기서도 s 라는 이름을 쓴다 — 새어 나가면
  #    그쪽이 조용히 틀린다.
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
      say "없음   $name"
      miss=$((miss+1)); continue
    fi
    m=$(tpl_md5 "$TPLDIR" "$name")
    s=$(tpl_size "$TPLDIR" "$name")
    if [ "${m:-x}" = "$wm5" ] && [ "${s:-x}" = "$wsz" ]; then
      same=$((same+1)); say "같다   $name"
    else
      diff=$((diff+1))
      say "다르다 $name  운영 ${s:-?}바이트 ${m:-?}"
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
    say "🔵 운영 양식이 개발 PC 것과 꼭 같아야 한다는 보증은 어디에도 없다 —"
    say "   도장·계좌번호가 든 파일이라 저장소에 없고, 운영에서 따로 고쳤을 수 있다."
    say "🔴 **양식을 새로 올려야 하는 판이면** 이 파일에는 그 모드가 없다. 되살릴 곳:"
    say "   51-deploy.sh 의 --templates-prep(1056~1172줄) · --templates-apply(1174~1341줄)."
  fi

  # ── 🔴 앱이 보는가 — 겉이 아니라 결과 ────────────────────────────
  printf '\n    ── 🔴 **앱이 그 양식을 보는가** (설정 이름으로 묻는다)\n'
  out=$("$DOCKER" exec -e DSS_TPL_NAMES="$TPL_ENV_NAMES" "$AS_APP_CN" node -e "$TPL_ENV_PROBE" 2>&1 | tr -d '\r')
  if [ -z "${out:-}" ]; then
    hm "$AS_APP_CN 안에서 못 쟀다 — 그 상자가 도는지 보세요. **빈 결과는 삼켜진 오류일 수 있다**"
    return
  fi
  printf '%s\n' "$out" | sed 's/^/      /'
  okn=$(printf '%s\n' "$out" | grep -c '^OK    ')
  missn=$(printf '%s\n' "$out" | grep -c '^MISS  ')
  unsetn=$(printf '%s\n' "$out" | grep -c '^UNSET ')
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
    say "🔵 보고서 쪽 넷(MATCHER_*·GENERATOR_*_REPORT_TEMPLATE_PATH)이 비어 있으면,"
    say "   코드가 **옛 이름 둘로 물러선다**(storage/service-report-template.ts 의 그"
    say "   물러서기 주석). 던지지는 않는다 — 매쳐·제너레이터가 같은 도장을 쓰던"
    say "   2026-10-18 이전 상태로 돌아갈 뿐이다."
    say "🔴 그 넷을 **쓰고 싶으면** 운영 compose 의 app-as 에 이름 넷을 더해야 한다 —"
    say "   **이 배포의 범위 밖**이다. 사람이 정하세요."
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

# 🔴 psql 가지 — node 길이 막혔을 때만 쓴다. 권한은 **역할**에 달린 것이라
#    같은 답이 나온다(current_user 로 묻든 역할 이름으로 묻든 같다).
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
#       A/S 교체를 막을 일이 아니다. 🔴 다만 **못 쓴다고 나오면 ✗** 다 — 그건
#       지금 운영이 고장나 있다는 뜻이고, 사람이 알아야 한다.
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
      # 🔴 「틀리면 안 되나」쪽 — PO 는 오늘도 그 표를 **읽고** 있다.
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
        say "🔴 권한을 여는 일은 이 스크립트가 하지 않는다 — 사람이 정하고 사람이 한다."
        doubt
      fi
      return ;;
    NOREL*)
      hm "PO 가 붙은 DB 에서 $PO_WRITE_TABLE 를 **못 찾았다** — 검사 자신을 의심하세요(search_path 나 DB 가 다르다)"
      doubt
      return ;;
  esac
  # ── 여기부터는 앱이 쓰는 길로 못 쟀다. psql 가지로 한 번 더 묻는다.
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
  # ── 두 길 다 못 쟀다. **「비면 OK」로 흘리지 않는다.**
  hm "PO 의 $PO_WRITE_TABLE 쓰기 권한을 **두 길 다 못 쟀다** — 🔵 이 배포(A/S)를 막지는 않는다"
  say "🔴 $PO_APP_CN 가 도는지, 그 안에서 node 가 도는지, $AS_BOX 가 도는지 보세요."
}

# ══ 🔴 재고 관리 통로가 **값을 돌려주는가** (45~51번 것을 글자 그대로) ══
#   🔴 **빼지 않는다.** 이것은 **앱**이 쓰는 길이다.
#   🔴 「설정이 적혀 있다」가 아니라 **「물어보니 답한다」**로 잰다.
#   🔵 **읽기만 한다.** 토큰은 쓰기만 하고 **찍지 않는다.**
#   🔴 **머리말에 한글을 안 넣는다.** 받는 답도 일부러 ASCII 로만 찍게 했다 —
#      한글을 HTTP 머리말에 넣으면 요청이 **아예 안 나가고**, 그 ✗ 가 진짜 결함처럼 보인다.
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

# 🔴 **단계마다 기대값이 아니라 '엄함'이 다르다.** --check 에서는 ? 로만 센다.
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

# ══ 🔴 도구 이미지 안을 센다 — 겉이 아니라 결과 ═══════════════════════
#   🔴 이 도구는 평소에 안 뜬다. 안이 모자라도 **그날 아무 일이 안 일어나고**,
#      드러나는 것은 **쓸 일이 생긴 날**의 한 줄뿐이다.
#   🔴 **「✗ 가 아니면 ✓」로 세지 않는다.** ✓ 조건만 정확히 적고 나머지는 ? 다.
tools_inside_check() {
  # 🔴 쓰는 이름을 **전부** local 로 묶는다 — 이 함수는 여러 모드에서 거듭 불리고,
  #    새어 나간 이름이 바깥 고리의 같은 이름을 조용히 덮은 전례가 있다.
  local v got c pg pa pt pd
  printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TOOLS_NEW"
  # ① runner 가 아니라 tools 인가 — runner 에는 /app/package.json 이 없다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/package.json: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "tools 스테이지가 맞다" \
    || { bad "🔴 /app/package.json 이 없다 — **runner 를 구웠다.**"; doubt; }
  # ② 🔴 **npm 명령 다섯이 이미지 안 package.json 에 있는가.** 41번의 자리다.
  #    🔵 앞의 셋은 48번이 올린 것(사라지면 안 된다), 뒤의 둘은 c6b2b271 이 올린
  #       것(들어와야 한다). 🔴 **procedures:import 는 운영에서 불릴 명령**이라
  #       여기서 빠지면 그날 절차 이관이 통째로 막힌다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync procedures:export procedures:import; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "5" ] && ok "npm 명령 다섯이 이미지 안에 있다 (48번의 셋 + c6b2b271 의 둘)" \
    || { bad "🔴 명령이 ${got:-0}/5 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다.** 부르는 날 Missing script 가 난다"; doubt; }
  # ③ 🔴 **좁은 닫힘에서 바뀐 여섯이 담겼는가.**
  #    🔵 그중 넷은 **기준판 8a98e461 에 없던 파일**이라 존재만으로 「새 판이
  #       담겼다」가 선다 — 48번에는 그런 신호가 하나도 없었다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/src/lib/db/mutations/procedure-templates.ts /app/src/lib/domain/procedure-template-code.ts /app/scripts/export-procedure-bundle.ts /app/scripts/import-procedure-bundle.ts /app/scripts/lib/procedure-template-bundle.ts /app/scripts/lib/dev-database-write-guard.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "6" ] && ok "좁은 닫힘에서 바뀐 여섯이 다 들어 있다 (그중 넷은 이번에 생긴 파일이다)" \
    || { bad "🔴 여섯 중 ${got:-0}개만 들어 있다 — src/ 나 scripts/ 가 온전히 안 담겼다"; doubt; }
  # ④ 🔴 **이번 판 엑셀 읽개 열하나가 담겼는가.** 전부 기준판에 **없던 파일**이다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/scripts/import-technical-task-procedures.ts /app/scripts/link-technical-task-next-procedures.ts /app/scripts/lib/dev-database-write-guard.ts /app/scripts/lib/xlsx/cell-grid-flowchart.ts /app/scripts/lib/xlsx/drawing-geometry.ts /app/scripts/lib/xlsx/extract-cell-grid-task-graph.ts /app/scripts/lib/xlsx/extract-technical-task-graph.ts /app/scripts/lib/xlsx/technical-task-next-procedure-plan.ts /app/scripts/lib/xlsx/technical-task-sheet-plan.ts /app/scripts/lib/xlsx/technical-task-workbook.ts /app/scripts/lib/xlsx/branch-classification.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "11" ] && ok "이번 판 엑셀 읽개 열하나가 다 들어 있다 (전부 기준판에 없던 파일이다)" \
    || { bad "🔴 열하나 중 ${got:-0}개만 들어 있다 — **옛 scripts/ 가 담긴 이미지다.** 올리지 마세요"; doubt; }
  # ⑤ 🔵 48번이 올린 도구 넷 — **빼지 않는다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "4" ] && ok "48번이 올린 도구 넷이 다 들어 있다" \
    || bad "🔴 도구 파일이 ${got:-0}/4 개다 — scripts/ 가 온전히 안 담겼다"
  # ⑥ 백필 도구 파일 셋 — 43~51번 것 그대로. **빼지 않는다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts /app/scripts/lib/kyosan-used-parts-backfill-plan.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "3" ] && ok "백필 도구 파일 셋이 다 들어 있다" \
    || bad "🔴 백필 도구 파일이 ${got:-0}/3 개다 — scripts/ 가 온전히 안 담겼다"
  # ⑦ 🔴 **그 src/ 와 scripts/ 가 '이번 판' 인가 — 글자로 센다.** ③④ 는 「있나」만 본다.
  #    🔵 여섯 다 기준 8a98e461 판에는 **0번** 나오고 지금 판에는 나온다
  #       (2026-11-06 git show 로 파일마다 세어 확인: 0→3 · 0→2 · 0→14 · 0→1 · 0→1 · 0→1).
  #    🔴 이름은 전부 ASCII 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for pair in "generateProcedureTemplateCode /app/src/lib/db/mutations/procedure-templates.ts" "GENERATED_PROCEDURE_CODE_PREFIX /app/src/lib/domain/procedure-template-code.ts" "sameRowBranch /app/src/lib/graph-editor-core/layout.ts" "buildProceduresForSheets /app/scripts/lib/xlsx/technical-task-workbook.ts" "checkDevelopmentWriteTarget /app/scripts/lib/dev-database-write-guard.ts" "planNextProcedureUnlinks /app/scripts/lib/xlsx/technical-task-next-procedure-plan.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1 $2"; else echo "no  $1 $2"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "6" ] && ok "이번 판의 이름 여섯이 이미지 안에 있다 (옛 판이 아니다)" \
    || { bad "🔴 이번 판의 이름이 ${got:-0}/6 개다 — **옛 판이 담긴 이미지다.** 올리지 마세요"; doubt; }
  # ⑧ 🔴 **갈래 셋을 이미지 안에서도 갈래마다 다르게 센다.**
  #    🔴 **부르지는 않는다** — 글자로만 센다.
  #    🔴 **한 잣대로 재면 import-procedure-bundle 이 가짜 ✗** 다. 그 파일은
  #       자물쇠를 **일부러 안 단다**(운영에서 도는 것이 목적).
  # ⑧-ㄱ 개발 PC 전용 둘 — 자물쇠가 **있어야** 한다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/scripts/import-technical-task-procedures.ts /app/scripts/link-technical-task-next-procedures.ts; do if grep -q checkDevelopmentWriteTarget "$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "2" ] && ok "갈래 ㄱ — 엑셀 읽개 둘이 이미지 안에서도 개발 DB 자물쇠를 부른다 (NAS 에서 부르면 막힌다)" \
    || { bad "🔴 갈래 ㄱ — 자물쇠를 부르는 것이 ${got:-0}/2 개다. **운영 DB 에 쓸 수 있는 판이다.** 올리지 마세요"; doubt; }
  # ⑧-ㄴ 🔴 운영에서 도는 하나 — 자물쇠가 **없고** 안전장치 셋이 **있어야** 한다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'f=/app/scripts/import-procedure-bundle.ts; for pair in "guard:checkDevelopmentWriteTarget" "apply:process.env.APPLY" "tx:db.transaction" "target:formatDatabaseTarget"; do k=${pair%%:*}; s=${pair#*:}; n=$(grep -cF "$s" "$f" 2>/dev/null); echo "$k=$n"; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  pg=$(printf '%s\n' "$v" | sed -n 's/^guard=//p')
  pa=$(printf '%s\n' "$v" | sed -n 's/^apply=//p')
  pt=$(printf '%s\n' "$v" | sed -n 's/^tx=//p')
  pd=$(printf '%s\n' "$v" | sed -n 's/^target=//p')
  if [ "${pg:-x}" = "0" ] && [ "${pa:-0}" -ge 1 ] 2>/dev/null && [ "${pt:-0}" -ge 1 ] 2>/dev/null && [ "${pd:-0}" -ge 1 ] 2>/dev/null; then
    ok "갈래 ㄴ — import-procedure-bundle 가 **운영용 모양 그대로**다 (자물쇠 0 · APPLY · 트랜잭션 · 대상 DB 찍기)"
  else
    bad "🔴 갈래 ㄴ — 자물쇠 ${pg:-?}(기대 0) · APPLY ${pa:-?} · 트랜잭션 ${pt:-?} · 대상DB ${pd:-?} (셋은 1 이상). **옛 판이거나 안전장치가 빠졌다**"
    doubt
  fi
  # ⑧-ㄷ 👀 읽기 전용 하나 — **쓰는 문장이 0** 이어야 한다.
  # 🔴 `grep -c` 는 **센 값이 0 이면 0 을 찍고 종료 코드 1** 을 낸다. 그래서 여기에
  #    `|| echo ?` 같은 안전망을 달면 **하필 바라던 0 일 때만** 그것이 터져 ✗ 가 난다
  #    (2026-11-06 52-build.sh 에서 실제로 났다). 파일이 없는 경우와 0 번인 경우는
  #    **갈래를 나눠** 가른다 — 한 값으로 뭉뚱그리면 둘이 구별되지 않는다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'f=/app/scripts/export-procedure-bundle.ts; if [ -f "$f" ]; then echo "miss=0"; echo "w=$(grep -cE "\.insert\(|\.update\(|\.delete\(" "$f")"; echo "t=$(grep -c "transaction" "$f")"; else echo "miss=1"; fi' 2>/dev/null | tr -d ' \r')
  printf '%s\n' "$v" | sed 's/^/      /'
  rm_=$(printf '%s\n' "$v" | sed -n 's/^miss=//p')
  rw=$(printf '%s\n' "$v" | sed -n 's/^w=//p')
  rt=$(printf '%s\n' "$v" | sed -n 's/^t=//p')
  if [ "${rm_:-1}" != "0" ]; then
    bad "🔴 갈래 ㄷ — /app/scripts/export-procedure-bundle.ts 가 **이미지 안에 없다**"
    doubt
  elif [ "${rw:-x}" = "0" ] && [ "${rt:-x}" = "0" ]; then
    ok "갈래 ㄷ — export-procedure-bundle 는 읽기만 한다 (쓰는 문장 0 · 트랜잭션 0)"
  else
    bad "🔴 갈래 ㄷ — 쓰는 문장 ${rw:-?}번 · 트랜잭션 ${rt:-?}번이다. **읽기 전용이 아니다**"
    doubt
  fi
  # ⑨ tsx 가 있는가 — 이 도구는 tsx 로만 돈다(운영 이미지에는 없는 devDependency다).
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/node_modules/tsx: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "tsx 가 있다" \
    || bad "🔴 tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다"
  # ⑩ 🔴 **값으로 받아 본다 — 명령 둘을 npm 으로 실제로 부른다.**
  #    DATABASE_URL 을 안 준다. **DB 에는 한 글자도 안 닿는다.**
  #    🔴 'node …' 가 아니라 **'npm run …'** 으로 부르는 것이 중요하다 —
  #       41번의 실패 모양이 'npm error Missing script' 였고, node 로 직접
  #       부르면 그 실패가 **영영 안 드러난다.**
  # 🔴 **procedures:import 를 꼭 넣는다 — 운영에서 불릴 유일한 새 명령이다.**
  #    그 파일도 import 가 정적이라 **Usage 를 찍기 전에** connection.ts 가 던진다.
  #    그래서 다른 둘과 **같은 답**('DATABASE_URL is not set')이 나온다.
  #    🔵 **procedures:export 는 여기서 안 부른다** — 개발 PC 에서 짐을 뜨는
  #       도구라 NAS 에서 부를 일이 없고, 「package.json 이 새 판인가」는 ② 가
  #       그 이름까지 세어 이미 답했다. 상자를 하나 더 띄울 값이 없다.
  for c in check:due-date-inverted check:requested-due-date-sync procedures:import; do
    v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "cd /app && npm run $c 2>&1 | head -40" 2>&1 | tr -d '\r')
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
  # ⑪ 🔵 백필도 여전히 서는가 — 43~51번이 재던 그 줄이다. **빼지 않는다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'cd /app && node --conditions=react-server --import tsx scripts/backfill-kyosan-used-parts.ts 2>&1 | head -40' 2>&1 | tr -d '\r')
  if printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
    ok "백필도 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)"
  elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
    bad "🔴 백필이 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
  else
    hm "백필의 답이 기대와 다르다 — 아래 20줄을 사람이 보세요"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
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
  if isnum "${src:-}" && [ "${src:-0}" -ge "$KYO_SRC_MIN" ]; then
    ok "$KYO_SRC 가 열린다 (${src}장)"
  elif [ "${src:-}" = "0" ]; then
    bad "🔴 $KYO_SRC 가 **비었다** — 볼륨 줄은 있는데 안 열린다"; good=0
  else
    hm "$KYO_SRC 가 ${src:-못 쟀다} 다 — $KYO_SRC_MIN 이상을 기대했다. 사람이 보세요"; good=0
  fi
  say "$KYO_CONV ${conv:-못 쟀다}장 (기대 $KYO_CONV_MIN 이상 · 2026-10-28 실측 143)"
  if isnum "${conv:-}" && [ "${conv:-0}" -ge "$KYO_CONV_MIN" ]; then
    ok "$KYO_CONV 가 열린다 (${conv}장)"
  elif [ "${conv:-}" = "0" ]; then
    bad "🔴 $KYO_CONV 가 **비었다** — 볼륨 줄은 있는데 안 열린다"; good=0
  else
    hm "$KYO_CONV 가 ${conv:-못 쟀다} 다 — $KYO_CONV_MIN 이상을 기대했다. 사람이 보세요"; good=0
  fi
  if [ "$good" != 1 ]; then
    say "── 받은 것 그대로 (끝 12줄)"
    printf '%s\n' "$out" | tail -12 | sed 's/^/      /'
    say "🔵 이 줄은 **앱 교체와 무관하다 — 되돌리지 마세요.**"
  fi
}

# ══════════════════════════════════════════════════════════════════════
# ── --count : 세 도구를 읽기만 해서 센다 ──────────────────────────────
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
    say "🔵 셋 다 :11 에도 :12 에도 있어야 한다 — 48번이 올려 두었고 이번 판에 안 줄었다."
    say "🔴 그러니 이 답은 **예상 밖**이다. compose 의 $AS_TOOLS_SVC 태그를 보세요."
    return
  fi
  if [ -z "${out:-}" ]; then
    hm "$2 — 아무것도 안 돌아왔다. **빈 결과는 삼켜진 오류일 수 있다** — 사람이 보세요"
    return
  fi
  printf '%s\n' "$out" | sed 's/^/      /'
  # 🔴 「글자가 보이나」가 아니라 **종료 코드**로 가른다.
  if [ "${rc:-1}" = "0" ]; then
    ok "$2 — 셌다 (위 수를 적어 두었다가 --go 뒤의 수와 견주세요)"
  else
    bad "🔴 $2 — 도구가 종료 코드 ${rc} 로 멈췄다. **세는 길과 뜨는 길이 갈라졌다는 뜻**이다"
    doubt
  fi
}

if [ "$MODE" = count ]; then
  printf '\n== 세 도구를 읽기만 해서 센다\n'
  [ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
  printf '%s\n' "🔴 셋 다 **쓰는 모드가 없다.** DB 에 한 글자도 안 쓴다."
  CTL=$(img_line "$AS_TOOLS_SVC")
  if [ -n "${CTL:-}" ]; then
    printf '%s\n' "🔵 지금 compose 의 $AS_TOOLS_SVC 태그: $(tag_at "$CTL")  (${CTL}줄)"
  else
    printf '%s\n' "🔴 compose 에서 $AS_TOOLS_SVC 의 image: 줄을 못 찾았다 — 아래 수가 어느 판인지 모른다"
  fi
  printf '%s\n' "🔴 **이번 배포는 이 수들과 상관이 없다** — 기술 작업 절차 화면과 엑셀 읽개입니다."
  printf '%s\n' "   앞뒤가 같으면 정상이고, 다르면 **그 사이에 사람이 저장한 것**입니다."
  count_one check:target-shipment-missing "사내 목표 출하일 미등록"
  count_one check:due-date-inverted       "납기 역전"
  count_one check:requested-due-date-sync "납기요청일 ↔ 고객 요청 납기일 어긋남"
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
#   이 저장소의 compose 사본은 운영보다 뒤처진다(48번에 **세 줄**이 어긋나 있었다:
#   dss-as:2.5 · dss-as-tools:1 · dss-po:0.5). 배포는 NAS 위 파일을 한 줄씩 고치고
#   돌아오지 않는다. 그래서 **여기서 직접 읽어 로그에 남긴다.**
printf '\n    ── 운영 compose 의 image: 줄 전부 (이 파일이 진짜다)\n'
grep -n '^ *image:' "$CF" | sed 's/^/      /'
printf '\n    ── 지금 **도는** 컨테이너와 그 이미지 (compose 와 다를 수 있다)\n'
"$DOCKER" ps -a --format '{{.Names}} {{.Image}} {{.Status}}' 2>/dev/null | sort | sed 's/^/      /'

# ══════════════════════════════════════════════════════════════════════
# 🔴 1-ㄱ-2. **상태 변수를 먼저 정한다** — 그다음에 가지를 나눈다
# ══════════════════════════════════════════════════════════════════════
#   🔴 48번이 데인 자리다. 기대값을 한 갈래로 박아 두면 **적용 뒤에 다시 부를 때
#      가짜 ✗** 가 난다. 그래서 compose 를 읽어 PHASE 를 먼저 정하고, 아래 절들이
#      그 PHASE 로 가지를 나눈다.
AS_SVC=$(printf '%s\n' "$(rows)" | head -1 | cut -d'|' -f2)
AS_NEW_TAG=$(printf '%s\n' "$(rows)" | head -1 | cut -d'|' -f4)
AS_OLD_TAG=$(printf '%s\n' "$(rows)" | head -1 | cut -d'|' -f5)
APP_L=$(img_line "$AS_SVC" 2>/dev/null || true)
TOOLS_L=$(img_line "$AS_TOOLS_SVC" 2>/dev/null || true)
APP_TAG_NOW=""; TOOLS_TAG_NOW=""
[ -n "${APP_L:-}" ]   && APP_TAG_NOW=$(tag_at "$APP_L")
[ -n "${TOOLS_L:-}" ] && TOOLS_TAG_NOW=$(tag_at "$TOOLS_L")
APP_STATE=ODD; TOOLS_STATE=ODD
[ "$APP_TAG_NOW" = "$AS_OLD_TAG" ] && APP_STATE=OLD
[ "$APP_TAG_NOW" = "$AS_NEW_TAG" ] && APP_STATE=NEW
[ "$TOOLS_TAG_NOW" = "$TOOLS_OLD" ] && TOOLS_STATE=OLD
[ "$TOOLS_TAG_NOW" = "$TOOLS_NEW" ] && TOOLS_STATE=NEW
PHASE=ODD
case "$APP_STATE/$TOOLS_STATE" in
  OLD/OLD) PHASE=PRE ;;
  OLD/NEW) PHASE=MID ;;
  NEW/NEW) PHASE=POST ;;
  NEW/OLD) PHASE=SPLIT ;;
esac
printf '\n    ── 🔴 지금 단계(PHASE)\n'
say "app-as  compose 태그 ${APP_TAG_NOW:-못 읽음}  (옛 $AS_OLD_TAG · 새 $AS_NEW_TAG) → $APP_STATE"
say "$AS_TOOLS_SVC compose 태그 ${TOOLS_TAG_NOW:-못 읽음}  (옛 $TOOLS_OLD · 새 $TOOLS_NEW) → $TOOLS_STATE"
case "$PHASE" in
  PRE)   ok "PHASE=PRE — 아직 아무것도 안 갈아 끼웠다 (--preload → --migrate → --go 차례)" ;;
  MID)   ok "PHASE=MID — 도구만 $TOOLS_NEW 다. --migrate 까지 돌았거나 --rollback 으로 앱만 되돌렸다" ;;
  POST)  ok "PHASE=POST — 둘 다 새 판이다. --go 까지 돌았다" ;;
  SPLIT) hm "PHASE=SPLIT — 앱만 새 판이고 도구가 $TOOLS_OLD 다. **--go 가 도중에 멈춘 모양**이다. 사람이 보세요" ;;
  *)     bad "🔴 PHASE 를 못 정했다 — app ${APP_TAG_NOW:-없음} · tools ${TOOLS_TAG_NOW:-없음}. 옛 판도 새 판도 아니다"
         say "🔴 **이 저장소의 compose 사본을 믿고 적은 값이 아니다** — 52-build.sh 머리말이"
         say "   README 의 기준 SHA 표와 48번 기록을 맞대어 얻은 값이다. 그래도 어긋났다면"
         say "   운영이 그 사이 따로 움직였다는 뜻이다. **고치지 말고 알리세요.**"
         doubt ;;
esac
# 🔴 **모드마다 서 있어야 하는 PHASE 가 다르다.** 여기서 한 번만 가른다.
case "$MODE" in
  rollback)
    case "$PHASE" in
      POST) ok "되돌릴 준비가 됐다 (PHASE=POST)" ;;
      MID)  hm "앱이 이미 $AS_OLD_TAG 다 (PHASE=MID — 벌써 되돌렸나)" ;;
      *)    hm "PHASE=$PHASE 에서 되돌리기를 부르셨다 — 🔵 막지는 않는다. 위 줄을 보세요" ;;
    esac ;;
  go)
    case "$PHASE" in
      PRE)  ok "갈아 끼울 준비가 됐다 (PHASE=PRE — image: 줄 **둘**이 달라질 것이다)" ;;
      MID)  ok "갈아 끼울 준비가 됐다 (PHASE=MID — --migrate 가 도구를 먼저 바꿨다. image: 줄 **하나**만 달라질 것이다)" ;;
      POST) hm "이미 POST 다 — 다시 돌리는 중인가. 🔵 막지 않는다(다시 띄우면 그만이다)" ;;
      *)    hm "PHASE=$PHASE 다 — 위 줄을 보고 사람이 판단하세요" ;;
    esac ;;
  *)
    case "$PHASE" in
      PRE|MID|POST) ok "PHASE=$PHASE — $MODE 에서 설 수 있는 단계다" ;;
      *)            hm "PHASE=$PHASE 다 — $MODE 는 막지 않지만 사람이 보세요" ;;
    esac ;;
esac

# 🔴 **compose 의 태그와 실제로 도는 이미지가 같은가** — 줄만 고치고 다시 안
#    띄운 경우가 있다. 그때는 교체가 「아무 일도 안 한 것처럼」 보인다.
for r in $(rows); do
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3)
  ST=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  printf '\n    ── %s\n' "$SVC"
  say "$SVC — ${APP_L:-?}줄 · compose ${APP_TAG_NOW:-?} · 도는 것 ${RUN:-없음} (${ST:-?})"
  if [ -z "${RUN:-}" ]; then
    hm "$CN 가 안 뜬 것 같다 — Config.Image 를 못 읽었다"
  elif [ "$RUN" = "$APP_TAG_NOW" ]; then
    ok "$CN 가 compose 에 적힌 그 태그로 돈다 ($RUN)"
  else
    hm "$CN 는 $RUN 로 도는데 compose 는 $APP_TAG_NOW 라고 적는다 — 줄만 고치고 안 띄운 상태다"
    say "🔵 **교체를 막지 않는다** — --go 가 어차피 다시 띄운다. 다만 되돌릴 때 기준이 흔들린다."
  fi
done

# ══ 🔴 PO — **이번엔 안 갈아 끼운다.** 그래도 「그대로 도는가」는 본다 ══
printf '\n    ── app-po (이번에 **안 건드린다**)\n'
PL=$(img_line app-po)
if [ -n "${PL:-}" ]; then
  PCUR=$(tag_at "$PL")
  PRUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$PO_APP_CN" 2>/dev/null)
  PST=$("$DOCKER" inspect -f '{{.State.Status}}' "$PO_APP_CN" 2>/dev/null)
  say "app-po — ${PL}줄 · compose ${PCUR} · 도는 것 ${PRUN:-없음} (${PST:-?})"
  if [ "$PCUR" = "$PO_WANT_TAG" ]; then
    ok "app-po 가 $PO_WANT_TAG 다 (49번이 올린 그 판 · 이번에 안 건드린다)"
  else
    hm "app-po 가 $PCUR 다 — $PO_WANT_TAG 를 기대했다. **이 배포를 막지 않는다**(PO 를 안 건드린다). 사람이 보세요"
  fi
  # 🔴 **5절이 이 줄을 건드리면 안 된다.** 아래 '달라진 image: 줄 수' 검사가 그것을 센다.
  say "🔴 5절은 이 줄을 **안 고친다** — 달라진 image: 줄 수로 그것을 확인한다."
else
  bad "compose 에 app-po 가 없다 — 지금까지 있던 것이다. 사람이 보세요"
fi

# ══ 🔴 A/S 도구 — 볼륨 줄이 제자리인가 ═══════════════════════════════
printf '\n    ── %s 의 볼륨\n' "$AS_TOOLS_SVC"
if [ -n "${TOOLS_L:-}" ]; then
  # 🔴 볼륨이 제 자리에 붙는가 — 여기가 어긋나면 **다음 마이그레이션이 엉뚱한 것을 읽는다.**
  if svc_block "$AS_TOOLS_SVC" | grep -q "$MIGDIR:$IMG_MIGDIR"; then
    ok "$AS_TOOLS_SVC 가 $MIGDIR 를 $IMG_MIGDIR 로 붙인다 (안 건드렸다)"
  else
    bad "🔴 $AS_TOOLS_SVC 의 drizzle 볼륨이 $MIGDIR 가 아니다 — 이 배포가 건드릴 자리가 아닌데 어긋났다"
  fi
  # 🔴 42번에서 넣은 검사다. **없어도 교체를 막지 않는다** — 그래서 ✗ 가 아니라 ? 다.
  for kv in "$KYO_SRC" "$KYO_CONV"; do
    if svc_block "$AS_TOOLS_SVC" | grep -q "$kv"; then
      ok "$AS_TOOLS_SVC 에 $kv 볼륨 줄이 있다 (연락서를 이식할 때 읽을 자리)"
    else
      hm "$AS_TOOLS_SVC 에 $kv 볼륨 줄이 **없다** — 🔵 교체는 막지 않는다"
      say "🔴 **이대로면 다음 연락서 이식이 못 돈다.** compose 의 $AS_TOOLS_SVC 에 그 줄을 먼저 넣으세요."
    fi
  done
  # 🔵 **$TPL_IN_CONTAINER 볼륨은 tools-as 에 없는 것이 지금 상태다.** 짐작으로
  #    적지 않고 재어 둔다 — 생기면 양식을 재는 길이 하나 더 열린다.
  if svc_block "$AS_TOOLS_SVC" | grep -q "$TPLDIR:$TPL_IN_CONTAINER"; then
    say "🔵 $AS_TOOLS_SVC 에 양식 볼륨이 **생겼다** — 지금까지 없던 것이다(해롭지 않다)"
  else
    say "🔵 $AS_TOOLS_SVC 에 양식 볼륨이 없다 (지금 상태가 그렇다 — 그래서 양식은 호스트에서 잰다)"
  fi
else
  bad "compose 에 $AS_TOOLS_SVC 가 없다 — 올릴 자리가 없다"
fi

# ══ 🔴 PO 쪽 — **도구 서비스가 없는 것이 맞다** ═══════════════════════
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
  n=$(grep -cE '^[A-Za-z_][A-Za-z0-9_]*=' "$f" 2>/dev/null | tr -d ' ')
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
# 🔴 컨테이너 안에서 auto 는 172.x 가 된다 — 이름 둘이 있고 auto 가 아니어야 한다.
env_auto_check() { # 1 파일 2 사람이 부르는 이름 3 환경변수 이름
  local f v q
  f=$1
  if [ ! -f "$f" ]; then hm "$2 의 $3 — 파일이 없어 못 쟀다"; return; fi
  # 🔴 값은 **안 찍는다.** auto 인지 아닌지만 본다.
  # 🔴 같은 이름이 두 줄이면 **아래가 이긴다** — 그래서 tail -1 이다.
  v=$(grep -E "^$3=" "$f" 2>/dev/null | tail -1 | cut -d= -f2-)
  v=$(printf '%s' "$v" | tr -d '\r')
  q=$(printf '%s' "'")                    # 작은따옴표 한 글자 — 인용이 꼬이지 않게 따로 만든다
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
env_file_check "$ENV_NAS" ".env.nas"
env_file_check "$ENV_AS"  "env/as.env"
env_file_check "$ENV_PO"  "env/po.env"
env_auto_check "$ENV_AS" "env/as.env" SSO_ISSUER
env_auto_check "$ENV_AS" "env/as.env" SSO_REDIRECT_URI
env_auto_check "$ENV_PO" "env/po.env" SSO_ISSUER
env_auto_check "$ENV_PO" "env/po.env" SSO_REDIRECT_URI
say "🔵 **이 판은 설정 파일을 하나도 안 바꾼다** — compose·env 에 더할 이름이 없다(2026-11-06 실측)."
say "🔴 늘어난 환경변수는 **APPLY 하나**뿐이고, 그것은 procedures:import 를 쓰기 모드로"
say "   돌릴 때 **그 한 번만** -e APPLY=1 로 준다. **설정 파일에 적지 마세요** —"
say "   적어 두면 「드라이런이 기본」이라는 안전장치가 통째로 사라진다."

# ── 1-ㄷ. 🔵 **양식** — 재기만 한다 (이번 판은 올릴 것이 0장) ─────────
templates_check

# ── 1-ㄹ. 🔴 **PO 가 repair_cases 에 쓸 수 있는가** ───────────────────
#   🔵 이번 판도 PO 를 안 갈아 끼운다 — 그래서 block 을 안 쓴다(머리말).
case "$MODE" in
  rollback) po_write_privilege_check soft ;;
  *)        po_write_privilege_check warnmiss ;;
esac

# ── 2. 🔴 DB — 마이그레이션 수가 **어느 단계에서나 124** 여야 한다 ────
#   🔵 A/S 와 PO 가 같은 dss_as 를 본다. 그래서 재는 자리가 하나다.
#   🔴 **여기만은 가지를 안 나눈다.** 이 배포는 마이그레이션이 0건이라 --migrate
#      앞에서도 뒤에서도 **같은 수**다. 48번의 121/124 두 갈래를 그대로 베끼면
#      **「121 이어도 ✓」가 되어 되돌아간 DB 를 못 잡는다.**
#   🔵 다음 판에 마이그레이션이 생기면 AS_MIG_BEFORE 만 고치면 아래 가지가
#      저절로 다시 살아난다 — 그래서 조건을 지우지 않고 **둘이 같을 때는 안 쓰도록**
#      묶어 두었다.
printf '\n== 2. DB (dss_as · A/S 와 PO 가 함께 쓴다)\n'
if [ "$AS_MIG_BEFORE" = "$AS_MIG_AFTER" ]; then
  say "🔵 이 판은 마이그레이션 **0건**이다 — 기대값이 **$AS_MIG_AFTER 한 갈래**다(앞뒤가 같다)."
else
  say "🔵 기대값이 두 갈래다 — 적용 전 $AS_MIG_BEFORE · 적용 뒤 $AS_MIG_AFTER."
fi
MIG_AS0=$(mig_count "$AS_BOX" "$AS_DB")
say "기록 ${MIG_AS0:-?}"
if [ -z "${MIG_AS0:-}" ]; then
  bad "DB 를 못 쟀다 — $AS_BOX 가 도는지 보세요"
  doubt
elif [ "$MIG_AS0" = "$AS_MIG_AFTER" ]; then
  ok "$AS_MIG_AFTER 다 — 48번이 올려 둔 그대로다. **이 배포가 이 수를 안 바꾼다**"
elif [ "$AS_MIG_BEFORE" != "$AS_MIG_AFTER" ] && [ "$MIG_AS0" = "$AS_MIG_BEFORE" ]; then
  ok "$AS_MIG_BEFORE 다 — 아직 --migrate 전이다"
else
  bad "🔴 ${MIG_AS0} 이다 — $AS_MIG_AFTER 여야 한다. 다른 배포가 먼저 돌았거나 전제가 깨졌다"
  doubt
fi

# ── 2-ㄴ. 🔴 **48번이 만든 것이 아직 있는가** — 값으로 확인 ───────────
#   🔵 「기록이 124 다」와 「그 표와 칸이 정말 있다」는 다른 말이다. 수만 세면
#      누가 손으로 DROP 한 경우를 못 본다. 넷 다 **어느 단계에서나 있어야 한다.**
printf '\n    ── 48번이 올린 표 하나 · 칸 둘 · 인덱스 하나 (아직 있어야 한다)\n'
T1=$(has_table  "$AS_BOX" "$AS_DB" "$AS_NEW_TABLE")
C1=$(has_column "$AS_BOX" "$AS_DB" "$AS_NEW_COL_TABLE" "$AS_NEW_COL")
C2=$(has_column "$AS_BOX" "$AS_DB" "$AS_NEW_COL2_TABLE" "$AS_NEW_COL2")
I1=$(has_index  "$AS_BOX" "$AS_DB" "$AS_NEW_INDEX")
OBJ_SEEN=0; OBJ_OK=0
for pair in "표 $AS_NEW_TABLE ${T1:-}" "칸 $AS_NEW_COL2_TABLE.$AS_NEW_COL2 ${C2:-}" "칸 $AS_NEW_COL_TABLE.$AS_NEW_COL ${C1:-}" "인덱스 $AS_NEW_INDEX ${I1:-}"; do
  set -- $pair
  OBJ_SEEN=$((OBJ_SEEN+1))
  printf '      %-8s %-48s %s\n' "$1" "$2" "${3:-못 쟀다}"
  if [ "${3:-0}" = "1" ]; then OBJ_OK=$((OBJ_OK+1)); fi
done
if [ "$OBJ_SEEN" = "4" ]; then ok "넷을 다 물어봤다 (표본이 비지 않았다)"
else bad "넷 중 ${OBJ_SEEN}개만 물어봤다 — 목록이 깨졌다"; fi
if [ "$OBJ_OK" = "4" ]; then
  ok "넷이 다 있다 — 운영이 정말 $AS_MIG_AFTER 상태다 (수가 아니라 **값**으로 확인했다)"
elif [ -z "${MIG_AS0:-}" ]; then
  hm "넷 중 ${OBJ_OK}개만 찾았다 — 위에서 DB 를 아예 못 쟀으니 **못 쟀다**로 센다"
else
  bad "🔴 넷 중 ${OBJ_OK}개만 있다 — 기록은 $AS_MIG_AFTER 인데 **실물이 모자란다.** 멈추고 알리세요"
  doubt
fi

# ── 2-ㄷ. 🔴 A/S 마이그레이션 볼륨 — **124 그대로여야 한다** ──────────
printf '\n== 2-ㄷ. A/S 마이그레이션 볼륨 (%s → %s 의 %s)\n' "$MIGDIR" "$AS_TOOLS_SVC" "$IMG_MIGDIR"
printf '%s\n' "🔴 .sql 만으로는 모자라다 — **meta/_journal.json 과 snapshot 까지** 가야 한다."
printf '%s\n' "   목록에 없는 .sql 은 drizzle 이 아예 모르고, 적용이 **0건으로 조용히 끝난다.**"
printf '%s\n' "🔵 이번 판은 **올릴 마이그레이션이 없다** — 볼륨이 이미 $AS_MIG_AFTER 이어야 맞다."
read_migdir
say "$MIGDIR — .sql ${MIG_N_SQL}장 · meta/_journal.json 의 idx ${MIG_N_J}개"
case "$MIG_STATE" in
  DONE) ok "볼륨이 $AS_MIG_AFTER 이다 (48번이 올려 둔 그대로 — 이 배포가 안 건드린다)" ;;
  OLD)  bad "🔴 볼륨이 $AS_MIG_BEFORE 이다 — $AS_MIG_AFTER 를 기대했다. --migrate 가 묶음으로 고친다"
        say "🔵 묶음을 보내세요: scp -O as-migrations.tar.gz dss-nas:$INCOMING/" ;;
  NODIR) bad "🔴 $MIGDIR 폴더가 **없다** — compose 가 $AS_TOOLS_SVC 에 붙이는 그 폴더다" ;;
  *)    bad "🔴 볼륨이 .sql ${MIG_N_SQL} · idx ${MIG_N_J} 다 — 둘 다 $AS_MIG_AFTER 여야 한다"
        say "→ 고치지 말고 **먼저 알리세요.**"; doubt ;;
esac
# 🔵 두 상수가 이어지는 번호인가 — 한쪽만 고치면 아래 검사가 조용히 빗나간다.
#    🔴 10# 을 붙여 **10진수로 강제**한다. 안 붙이면 0123 이 8진수 83 으로 읽힌다.
if [ "$(printf '%04d' "$((10#$AS_LAST_MIG + 1))")" = "$AS_NEXT_MIG" ]; then
  ok "AS_LAST_MIG($AS_LAST_MIG) 다음이 AS_NEXT_MIG($AS_NEXT_MIG) 다 (두 상수가 이어진다)"
else
  bad "🔴 AS_LAST_MIG($AS_LAST_MIG) 와 AS_NEXT_MIG($AS_NEXT_MIG) 가 안 이어진다 — 한쪽만 고쳤다"
fi
# 🔴 **볼륨에 새 마이그레이션이 없는가** — 이 판의 전제다. --check 에서도 잰다.
#    🔵 수(124)만 보면 「하나 빠지고 하나 생긴」 경우를 못 본다.
if [ "$MIG_STATE" = NODIR ]; then
  hm "$MIGDIR 가 없어 $AS_NEXT_MIG 번을 못 쟀다"
elif ls -1 "$MIGDIR/${AS_NEXT_MIG}_"*.sql >/dev/null 2>&1; then
  bad "🔴 볼륨에 $AS_NEXT_MIG 번이 **있다** — 이 배포는 마이그레이션 0건을 전제로 쓰였다. 멈추고 알리세요"
  doubt
else
  ok "볼륨에 $AS_NEXT_MIG 번이 없다 (마지막이 $AS_LAST_MIG — 0건이 맞다)"
fi
# 🔵 묶음이 와 있으면 맞대어 본다. **없어도 ✗ 가 아니다** — 이번 판에는 보험이다.
if [ -s "$MIGTAR" ]; then
  say "묶음이 있다: $MIGTAR ($(stat -c %s "$MIGTAR" 2>/dev/null)바이트 · md5 $(md5sum "$MIGTAR" | awk '{print $1}'))"
  TSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -c '^drizzle/[0-9].*\.sql$')
  TJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
  say "묶음 안 — .sql ${TSQL:-?}장 · idx ${TJRN:-?}개"
  if [ "${TSQL:-0}" = "$AS_MIG_AFTER" ] && [ "${TJRN:-0}" = "$AS_MIG_AFTER" ]; then
    ok "묶음 안이 $AS_MIG_AFTER 이다 (볼륨이 어긋났을 때 이것으로 고친다)"
  else
    bad "🔴 묶음 안이 .sql ${TSQL:-?} · idx ${TJRN:-?} 다 — **$AS_MIG_AFTER 이어야 한다.** 다시 묶어 올리세요"
    doubt
  fi
  if [ -n "${MIGTAR_MD5:-}" ] && [ -n "${MIGTAR_SIZE:-}" ]; then
    M=$(md5sum "$MIGTAR" | awk '{print $1}')
    S=$(stat -c %s "$MIGTAR" 2>/dev/null)
    [ "$S" = "$MIGTAR_SIZE" ] && ok "묶음 크기가 구울 때와 같다  [배포본]" \
      || bad "묶음 크기가 다르다 (${S} ≠ ${MIGTAR_SIZE}) — 옮기다 끊겼다  [배포본]"
    [ "$M" = "$MIGTAR_MD5" ] && ok "묶음 md5 가 구울 때와 같다  [배포본]" \
      || bad "묶음 md5 가 다르다 — 옮기다 깨졌다  [배포본]"
  else
    hm "묶음의 잰 값이 이 파일에 없다 — 52-build.sh --go 의 출력에서 MIGTAR_SIZE·MIGTAR_MD5 를 채우세요"
    say "🔵 **이 판에서는 막지 않는다** — 묶음은 보험이고 볼륨이 이미 $AS_MIG_AFTER 다."
  fi
else
  say "🔵 묶음이 없다: $MIGTAR — **이번 판에는 없어도 된다**(볼륨이 이미 $AS_MIG_AFTER)."
fi

# ── 3. 들여올 이미지 둘 ───────────────────────────────────────────────
printf '\n== 3. 들여올 이미지 둘 (앱 하나 · 도구 하나)\n'
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
    #    아예 못 보게 된다.** 51-deploy.sh 는 둘 다 ? 로 세어 아무것도 안 막았다.
    if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
      hm "$TAR — **잰 값이 이 파일에 없다.** 옮기다 깨진 것만 잡는다"
    else
      bad "🔴 $TAR — **잰 값이 이 파일에 없다.** 52-build.sh --go 가 찍어 준 두 줄로 TARS 를 채우세요"
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
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 52-build.sh --go 가 끝에 찍어 주는"
  printf '%s\n' "     **두 줄**로 이 파일의 TARS 두 줄을 통째로 갈아 끼우세요."
fi
# 🔵 되돌릴 길 — 옛 태그가 **NAS 에** 남아 있는가(앱 하나만. 도구는 되돌리지 않는다)
for r in $(rows); do
  OLD=$(fld "$r" 5)
  if "$DOCKER" image inspect "$OLD" >/dev/null 2>&1; then ok "$OLD 이 NAS 에 남아 있다 (되돌릴 길)"
  else hm "$OLD 이 NAS 에 없다 — **--rollback 을 못 쓴다.** 되돌릴 일이 생기면 개발 PC 에서 다시 보내야 한다"; fi
done
# 🔴 도구 이미지가 **이미 실려 있으면** 그 자리에서 안을 센다.
if "$DOCKER" image inspect "$TOOLS_NEW" >/dev/null 2>&1; then
  tools_inside_check
else
  if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
    hm "$TOOLS_NEW 가 아직 안 실렸다 — **${MODE} 에서는 괜찮다**. 4절이 싣는다"
  else
    say "$TOOLS_NEW 가 아직 안 실렸다 — 4절이 싣는다"
  fi
fi

# 🔴 **재고 관리 통로 — --check 에서 미리 재 둔다.** ? 로만 센다(교체를 막지 않는다).
if [ "$MODE" = check ]; then inventory_gateway_check soft; fi

if [ "$MODE" = check ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s   (PHASE=%s)\n' "$PASS" "$FAIL" "$WARN" "$PHASE"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  printf '%s\n' "🔴 다음 차례: --count(앞) → scp tar → --preload → (다시 --check) → --migrate → --go → --count(뒤)"
  printf '%s\n' "🔴 **PHASE=PRE 에서 돌리면 ? 가 여럿 나오는 것이 정상**이다 (tar 둘이 아직 없다)."
  printf '%s\n' "🔵 마이그레이션 기록은 **어느 단계에서나 $AS_MIG_AFTER** 여야 한다 — 이 판은 0건이다."
  printf '%s\n' "🔵 양식도 **올릴 것이 0장**이다 — 1-ㄷ 절은 「안 바뀌었는가」만 봅니다."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 4. --preload : tar 둘을 들여놓는다 ───────────────────────────────
if [ "$MODE" = preload ] || [ "$MODE" = go ]; then
  printf '\n== 4. tar 둘을 들여놓는다\n'
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
  if [ "$LOADED" = "$TARS_WANT" ]; then ok "둘이 다 실렸다"
  else bad "🔴 ${LOADED}/$TARS_WANT 개만 실렸다 — TARS 가 비었거나 tar 가 모자란다"; fi
  # 🔴 들여놓자마자 도구 이미지 안을 센다 — 늦게 발견할수록 되돌리기가 비싸다.
  if "$DOCKER" image inspect "$TOOLS_NEW" >/dev/null 2>&1; then
    tools_inside_check
  else
    bad "🔴 $TOOLS_NEW 가 아직 안 실렸다 — 위 load 가 실패했는지 보세요"
  fi
fi

if [ "$MODE" = preload ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **들여놓기만 했다 — 아직 안 갈아 끼웠다.** 다음: --check 를 다시 → --migrate → --go"
  printf '%s\n' "🔵 **이 배포는 마이그레이션 0건이다.** --migrate 는 DB 를 안 바꾸지만,"
  printf '%s\n' "   「정말 0건인가」를 값으로 재고 **덤프를 뜨고** $AS_TOOLS_SVC 태그를 $TOOLS_NEW 로 바꿉니다."
  printf '%s\n' "🔴 건너뛰어도 됩니다 — 그러면 --go 가 도구 태그까지 한꺼번에 바꾸고 덤프도 거기서 뜹니다."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ══════════════════════════════════════════════════════════════════════
# ── 4-ㄴ. --migrate : 🔵 **0건을 값으로 잰다** ────────────────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **이 모드를 걷어내지 않았다.** 39번 이후 열 번이 0건이었더니 절이 통째로
#      사라졌고, 48번에서 다시 필요해졌을 때 39번까지 거슬러 가야 했다.
#   🔴 **이번 판에서도 진짜로 무언가를 잰다** — 머리말에 여덟 가지를 적어 두었다.
#   🔵 DB 는 안 바뀌는 것이 **정상**이다. 바뀌면 전제가 깨진 것이라 ✗ 다.
if [ "$MODE" = migrate ]; then
  printf '\n== 4-ㄴ. 🔴 마이그레이션 — 이 판은 **0건이어야 한다** (기록 %s 그대로)\n' "$AS_MIG_AFTER"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **DB 를 안 건드리고 멈춘다.**\n'; exit 1; fi

  # ── ㄱ. 🔴 덤프 — **0건이어도 뜬다** ────────────────────────────────
  make_dump "마이그레이션 0건이어도 뜬다 — 되돌릴 때 기준이 되는 그 시각의 사진이다"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 되돌릴 길이 없다 — **DB 도 앱도 그대로 두고 멈춘다.**\n'; exit 1; fi

  # ── ㄴ. 🔴 적용 전 줄 수를 적어 둔다 ────────────────────────────────
  printf '\n    ── 적용 전 줄 수 (적용 뒤에 **그대로여야** 한다)\n'
  CNT_BEFORE=""
  for F in $AS_COUNT_TABLES; do
    V=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $F")
    CNT_BEFORE="$CNT_BEFORE as.$F=${V:-?}"; say "dss_as.$F ${V:-?}줄"
  done

  # ── ㄷ. 🔴 compose 의 **tools-as** 를 :11 → :12 로 ──────────────────
  #   🔴 37번이 한 그 방식 그대로 — 사본을 먼저 뜨고, image: 줄이 **꼭 하나만**
  #      달라졌는지 세고, 어긋나면 **사본으로 되돌리고 멈춘다.**
  #   🔵 tools-as 는 profiles: [tools] 라 평소에 뜨지 않는다. 도는 컨테이너는
  #      compose 를 읽지 않으므로 이 한 줄을 고쳐도 **직원이 느끼는 것이 없다.**
  #      up -d 를 부르지 않는다.
  #   🔴 이 자리를 DB 앞에 둔다 — 여기서 어긋나면 DB 를 안 건드리고 끝난다.
  printf '\n    ── compose 의 %s 를 %s 로\n' "$AS_TOOLS_SVC" "$TOOLS_NEW"
  cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
  chmod 644 "$BK"
  ok "사본 $BK"
  TL0=$(wc -l < "$CF"); TI0=$(grep -c '^ *image:' "$CF")
  TB=$(mktemp) || exit 1; TA=$(mktemp) || exit 1
  grep -n '^ *image:' "$CF" > "$TB"
  APPB=$(app_img_lines)            # 🔴 앱 줄은 **하나도 안 바뀌어야** 한다
  TAL=$(img_line "$AS_TOOLS_SVC") || { bad "$AS_TOOLS_SVC 를 못 찾았다"; rm -f "$TB" "$TA"; exit 1; }
  # 🔴 치환 **전에** 줄 모양을 본다 — 주석이 붙어 있으면 엉뚱한 낱말이 바뀐다.
  TNF0=$(nf_at "$TAL")
  if [ "${TNF0:-0}" != "2" ]; then
    bad "🔴 $AS_TOOLS_SVC 의 ${TAL}줄이 낱말 ${TNF0:-?}개다 — 'image: 태그' 두 낱말만 있어야 한다"
    awk -v n="$TAL" 'NR==n' "$CF" | sed 's/^/      /'
    doubt
    rm -f "$TB" "$TA"
    printf '\n🔴 **DB 도 앱도 그대로다.** 멈춘다.\n'; exit 1
  fi
  if [ "$(tag_at "$TAL")" = "$TOOLS_NEW" ]; then
    ok "$AS_TOOLS_SVC 가 이미 $TOOLS_NEW 다 — 고칠 것이 없다"
    rm -f "$TB" "$TA"
  else
    TMP=$(mktemp) || exit 1
    awk -v n="$TAL" -v to="$TOOLS_NEW" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
    cp "$TMP" "$CF"; rm -f "$TMP"
    grep -n '^ *image:' "$CF" > "$TA"
    TDIFF=$(diff "$TB" "$TA" | grep -c '^[<>]')
    APPA=$(app_img_lines)
    say "줄 수 $TL0 → $(wc -l < "$CF") · image: 줄 $TI0 → $(grep -c '^ *image:' "$CF") · 달라진 image: 줄 $((TDIFF / 2))개"
    [ "$(tag_at "$TAL")" = "$TOOLS_NEW" ] && ok "$AS_TOOLS_SVC → $TOOLS_NEW (${TAL}줄)" \
      || bad "$AS_TOOLS_SVC 의 태그가 $(tag_at "$TAL") 다"
    [ "$(wc -l < "$CF")" = "$TL0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
    [ "$(grep -c '^ *image:' "$CF")" = "$TI0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
    # 🔴 **꼭 하나**다. 둘이면 남의 것을 건드렸다.
    [ "$((TDIFF / 2))" = "1" ] && ok "image: 줄이 **꼭 하나만** 달라졌다 (도구 한 줄)" \
      || bad "image: 줄이 $((TDIFF / 2))개 달라졌다 — 남의 것을 건드렸다"
    # 🔴 앱 줄은 --go 의 일이다. 여기서 바뀌면 안 된다.
    [ "$APPA" = "$APPB" ] && ok "앱의 image: 줄은 하나도 안 바뀌었다 (--go 의 일이다)" \
      || bad "🔴 앱 image: 줄이 바뀌었다 — 이 단계가 건드릴 자리가 아니다"
    dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"
    rm -f "$TB" "$TA"
    if [ "$FAIL" != 0 ]; then
      printf '\n🔴 어긋났다 — **사본으로 되돌리고 DB 는 안 건드린다.**\n'
      cp "$BK" "$CF"; say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $TL0)"
      exit 1
    fi
  fi

  # ── ㄹ. 🔴 도구 이미지 안을 센다 — 쓸 수 있는 판이 맞는가 ───────────
  #   🔴 「태그를 고쳤다」와 「쓸 수 있다」는 다르다. 겉이 아니라 결과를 본다.
  if "$DOCKER" image inspect "$TOOLS_NEW" >/dev/null 2>&1; then
    tools_inside_check
  else
    bad "🔴 $TOOLS_NEW 가 NAS 에 없다 — compose 가 없는 이미지를 가리키게 됐다"
  fi
  if [ "$FAIL" != 0 ]; then
    printf '\n🔴 도구가 온전하지 않다 — **사본으로 되돌리고 DB 는 안 건드린다.**\n'
    cp "$BK" "$CF"; exit 1
  fi

  # ── ㅁ. 🔴 볼륨이 124 인가 — 아니면 묶음으로 고친다 ─────────────────
  printf '\n    ── A/S 마이그레이션 볼륨이 %s 인가\n' "$AS_MIG_AFTER"
  read_migdir
  if [ "$MIG_STATE" != DONE ]; then
    bad "🔴 볼륨이 .sql ${MIG_N_SQL} · idx ${MIG_N_J} 다 — 둘 다 $AS_MIG_AFTER 여야 한다"
    say "🔵 묶음이 있으면 그것으로 고친다. 없으면 여기서 멈춘다."
    place_migs || { printf '\n🔴 **DB 도 앱도 그대로다.**\n'; cp "$BK" "$CF"; exit 1; }
    read_migdir
  fi
  say "지금 $MIGDIR — .sql ${MIG_N_SQL}장 · meta/_journal.json 의 idx ${MIG_N_J}개"
  [ "$MIG_N_SQL" = "$AS_MIG_AFTER" ] && ok ".sql 이 ${MIG_N_SQL}장이다" \
    || bad ".sql 이 ${AS_MIG_AFTER}장이 아니다 (${MIG_N_SQL}장)"
  [ "$MIG_N_J" = "$AS_MIG_AFTER" ] && ok "meta/_journal.json 의 idx 가 ${MIG_N_J}개다" \
    || bad "idx 가 ${AS_MIG_AFTER}개가 아니다 (${MIG_N_J}개) — 🔴 적용이 **0건으로 끝난다**"
  # 🔴 48번이 올린 셋이 온전한가 + 0124 가 없는가 + 지우는 문장이 0줄인가.
  check_keep_migs || true
  if [ "$FAIL" != 0 ]; then printf '\n🔴 마이그레이션 파일이 온전하지 않다 — **DB 도 앱도 그대로다.**\n'; cp "$BK" "$CF"; exit 1; fi
  # 🔴 컨테이너가 **실제로 그 폴더를 읽는지** 본다. 겉이 아니라 결과다 —
  #    호스트에서 보이는 것과 컨테이너 안에서 보이는 것이 다를 수 있다.
  INSQL=$(dct run --rm --entrypoint sh "$AS_TOOLS_SVC" -c "ls -1 $IMG_MIGDIR/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r' | tail -1)
  say "$AS_TOOLS_SVC 안에서 본 $IMG_MIGDIR 의 .sql: ${INSQL:-?}장"
  if [ "${INSQL:-0}" = "$AS_MIG_AFTER" ]; then ok "컨테이너 안에서도 $AS_MIG_AFTER 장이다 (볼륨이 제대로 붙었다)"
  else bad "컨테이너 안이 ${INSQL:-?}장이다 — $AS_MIG_AFTER 장이어야 한다. **0건으로 끝날 수 있다**"; fi
  if [ "$FAIL" != 0 ]; then printf '\n🔴 **DB 도 앱도 그대로다.** 멈춘다.\n'; cp "$BK" "$CF"; exit 1; fi

  # ── ㅂ. 적용 전 preflight — **대기 0건**이어야 한다 ─────────────────
  printf '\n    ── 적용 전 db:preflight (이 판은 **대기 0건**이 맞다)\n'
  dct run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | tail -20 | sed 's/^/    /'
  PRC=${PIPESTATUS[0]}
  say "(종료 코드 $PRC — 기대 0 · 대기 **0건**)"
  if [ "$PRC" != 0 ]; then
    bad "db:preflight 가 0 이 아니다 ($PRC) — 사라질 자료가 있거나 대기가 남았다는 뜻이다"
    say "→ 🔴 이 판은 **적용할 것이 0건**이다. 대기가 있다면 **볼륨이나 DB 가 전제와 다르다.**"
    printf '\n🔴 **DB 를 안 건드리고 멈춘다.** 앱은 그대로 돈다.\n'
    cp "$BK" "$CF"
    exit 1
  fi

  printf '\n'
  say "🔵 이 판은 적용할 것이 **0건**이라 db:migrate 가 DB 를 안 바꿉니다."
  say "🔴 그래도 멈출 창을 둡니다 — 위 검사에서 볼륨이 어긋나 묶음으로 고쳤다면"
  say "   **진짜로 적용될 수 있습니다.** 그만두려면 **20초 안에 Ctrl+C**."
  sleep 20

  # ── ㅅ. 돌린다 ──────────────────────────────────────────────────────
  printf '\n    ── 돌린다 (drizzle 은 다시 돌려도 안전하다)\n'
  dct run --rm "$AS_TOOLS_SVC" npm run db:migrate 2>&1 | tail -25 | sed 's/^/    /'
  RC=${PIPESTATUS[0]}
  if [ "$RC" = 0 ]; then ok "A/S db:migrate 끝 (종료 코드 0)"
  else
    bad "A/S db:migrate 실패 (종료 코드 $RC)"
    say "🔵 앱은 **그대로 옛 판으로 돕니다.** 직원이 느끼는 것이 없습니다."
    printf '\n🔴 덤프: %s\n' "$DUMP"
    exit 1
  fi

  # ── ㅇ. 🔴 값으로 확인 (겉이 아니라 결과) ───────────────────────────
  printf '\n    ── 🔴 값으로 확인 — **아무것도 안 바뀌어야** 한다\n'
  MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
  say "기록 ${MIG_AS0:-?} → ${MIG_AS1:-?} (둘 다 $AS_MIG_AFTER 여야 한다)"
  if [ "${MIG_AS1:-x}" = "$AS_MIG_AFTER" ] && [ "${MIG_AS0:-x}" = "$AS_MIG_AFTER" ]; then
    ok "기록이 **앞뒤로 둘 다 $AS_MIG_AFTER** 다 — 이 판이 0건이라는 것을 값으로 확인했다"
  else
    bad "🔴 기록이 ${MIG_AS0:-?} → ${MIG_AS1:-?} 다 — 둘 다 $AS_MIG_AFTER 여야 한다. **무언가 적용됐다**"
    doubt
  fi
  T1=$(has_table  "$AS_BOX" "$AS_DB" "$AS_NEW_TABLE")
  C1=$(has_column "$AS_BOX" "$AS_DB" "$AS_NEW_COL_TABLE" "$AS_NEW_COL")
  C2=$(has_column "$AS_BOX" "$AS_DB" "$AS_NEW_COL2_TABLE" "$AS_NEW_COL2")
  I1=$(has_index  "$AS_BOX" "$AS_DB" "$AS_NEW_INDEX")
  [ "${T1:-0}" = "1" ] && ok "0121 — 표 $AS_NEW_TABLE 가 **아직 있다**" || bad "🔴 표 $AS_NEW_TABLE 가 없다"
  [ "${C2:-0}" = "1" ] && ok "0122 — 칸 $AS_NEW_COL2_TABLE.$AS_NEW_COL2 이 **아직 있다**" || bad "🔴 칸 $AS_NEW_COL2 이 없다"
  [ "${C1:-0}" = "1" ] && ok "0123 — 칸 $AS_NEW_COL_TABLE.$AS_NEW_COL 이 **아직 있다**" || bad "🔴 칸 $AS_NEW_COL 이 없다"
  [ "${I1:-0}" = "1" ] && ok "0123 — 인덱스 $AS_NEW_INDEX 가 **아직 있다**" || bad "🔴 인덱스가 없다"

  printf '\n    ── 🔴 줄 수가 그대로인가 (하나라도 줄었으면 자료가 사라진 것이다)\n'
  for F in $AS_COUNT_TABLES; do
    V=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $F")
    B=$(printf '%s' "$CNT_BEFORE" | tr ' ' '\n' | sed -n "s/^as\\.$F=//p")
    [ "${V:-x}" = "${B:-y}" ] && ok "dss_as.$F ${V}줄 — 그대로" \
      || bad "🔴 dss_as.$F 가 ${B:-?} → ${V:-?} 로 **달라졌다**"
  done

  printf '\n    ── 적용 뒤 db:preflight — **대기 0건**이어야 한다\n'
  dct run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | tail -15 | sed 's/^/    /'
  say "(종료 코드 ${PIPESTATUS[0]})"

  printf '\n    ── 🔴 앱이 **여전히 옛 판으로** 도는가 (--go 가 아직 안 돌았다)\n'
  "$DOCKER" ps --format '{{.Names}}\t{{.Image}}' 2>/dev/null | sort | sed 's/^/      /'

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$FAIL" = 0 ]; then
    printf '%s\n' "✅ **DB 는 한 글자도 안 바뀌었습니다** — 그것이 이 판의 기대값입니다(0건)."
    printf '%s\n' "  🔵 확인한 것: 기록이 앞뒤로 둘 다 $AS_MIG_AFTER · 0124 없음 · 48번의 표·칸·인덱스가"
    printf '%s\n' "     아직 있음 · 지우는 문장 0줄 · 줄 수 그대로 · 대기 0건."
    printf '%s\n' "  🔵 compose 의 $AS_TOOLS_SVC 가 $TOOLS_NEW 가 됐습니다 (사본: $BK)"
    printf '%s\n' "  🔴 되돌릴 길(이 시각의 덤프): $DUMP"
    printf '%s\n' "  🔴 **다음: --go** — 이제 PHASE=MID 라 --go 에서 image: 줄이 **하나만** 달라집니다."
  else
    printf '%s\n' "🔴 위 ✗ 를 보세요. 🔵 이 모드는 **다시 돌려도 안전합니다**: bash $0 --migrate"
  fi
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 5. --go / --rollback : compose 의 image: 줄을 바꾼다 ─────────────
#  🔴 --go 는 app-as 와 tools-as 를 고친다. --rollback 은 **app-as 하나**만
#     되돌린다 — 도구는 $TOOLS_NEW 그대로 둔다(39·41~51번과 같은 판단).
#  🔴 **app-po 줄은 어느 모드에서도 안 건드린다.**
printf '\n== 5. compose 의 image: 줄을 바꾼다\n'
# 🔴 **덤프를 여기서도 뜬다.** --migrate 를 건너뛰고 --go 로 바로 올 수 있기
#    때문이다. 🔵 이 배포는 DB 를 안 바꾸지만, 되돌릴 때 기준이 되는 사진이다.
#    🔵 --migrate 를 이미 돌리셨으면 사진이 둘이 된다 — 해롭지 않다.
#    🔵 --rollback 에서는 안 뜬다: DB 가 안 바뀌었으니 지킬 것이 없고,
#       되돌리는 길은 빠를수록 좋다.
if [ "$MODE" = go ]; then
  make_dump "--migrate 를 건너뛰었을 수 있다 — 갈아 끼우기 전 사진을 남긴다"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 덤프를 못 떴다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi
fi
# 🔵 1절에서 읽어 둔 TOOLS_STATE 를 쓴다. **여기서 다시 읽지 않는다** — 두 벌로
#    읽으면 한쪽만 고쳤을 때 조용히 어긋난다.
say "고치기 전 $AS_TOOLS_SVC — ${TOOLS_TAG_NOW:-못 읽음} (상태 $TOOLS_STATE · PHASE $PHASE)"
if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi

cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
chmod 644 "$BK"
ok "사본 $BK"
L0=$(wc -l < "$CF"); IMGS0=$(grep -c '^ *image:' "$CF")
BEF=$(mktemp) || exit 1
AFT=$(mktemp) || exit 1
grep -n '^ *image:' "$CF" > "$BEF"

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

# 🔴 도구는 --go 일 때만 고친다. --rollback 은 **손대지 않는다.**
if [ "$MODE" = go ]; then
  TL=$(img_line "$AS_TOOLS_SVC") || { bad "$AS_TOOLS_SVC — image: 줄을 못 찾았다"; }
  TNF=$(nf_at "${TL:-0}")
  if [ -n "${TL:-}" ] && [ "${TNF:-0}" != "2" ]; then
    bad "🔴 $AS_TOOLS_SVC 의 ${TL}줄이 낱말 ${TNF:-?}개다 — 'image: 태그' 두 낱말만 있어야 한다"
    awk -v n="$TL" 'NR==n' "$CF" | sed 's/^/      /'
    doubt
    TL=""
  fi
  if [ -n "${TL:-}" ]; then
    TMP=$(mktemp) || exit 1
    awk -v n="$TL" -v to="$TOOLS_NEW" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
    cp "$TMP" "$CF"; rm -f "$TMP"
    TNOW=$(tag_at "$TL")
    if [ "$TNOW" = "$TOOLS_NEW" ]; then ok "$AS_TOOLS_SVC → $TOOLS_NEW (${TL}줄)"; else bad "$AS_TOOLS_SVC 의 태그가 $TNOW 다"; fi
  fi
else
  say "🔵 $AS_TOOLS_SVC 는 이번 모드($MODE)에서 **안 건드린다** — $TOOLS_NEW 그대로 둔다"
fi

L1=$(wc -l < "$CF"); IMGS1=$(grep -c '^ *image:' "$CF")
grep -n '^ *image:' "$CF" > "$AFT"
DIFFN=$(diff "$BEF" "$AFT" | grep -c '^[<>]')
rm -f "$BEF" "$AFT"
say "줄 수 $L0 → $L1 · image: 줄 $IMGS0 → $IMGS1 · 달라진 image: 줄 $((DIFFN / 2))개"
[ "$L1" = "$L0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
[ "$IMGS1" = "$IMGS0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
# 🔴 **남의 image: 줄을 건드리면 안 된다.**
# 🔴 **몇 개가 달라지는지 박지 않는다 — 세어서 정한다.** 48번에서 이 숫자를 2 로
#    박아 두었다가, --migrate 가 tools 줄을 **먼저** 바꾼 판에서 제대로 동작한
#    --go 가 ✗ 를 받고 **되돌아갔다.**
#    🔵 고치기 전의 tools-as 가 이미 새 태그면 1(app-as 하나), 아니면 2.
#       사람이 --migrate 를 건너뛰고 --go 를 먼저 불러도 맞는다.
if [ "$MODE" = go ]; then
  if [ "$TOOLS_STATE" = "NEW" ]; then WANT_DIFF=1; else WANT_DIFF=2; fi
  say "기대 — 고치기 전 도구가 $TOOLS_STATE 이므로 달라질 image: 줄은 ${WANT_DIFF}개다"
else
  WANT_DIFF=1
  say "기대 — --rollback 은 app-as 한 줄만 되돌린다(도구는 그대로)"
fi
[ "$((DIFFN / 2))" = "$WANT_DIFF" ] && ok "image: 줄이 꼭 ${WANT_DIFF}개만 달라졌다 (우리 것 · app-po 는 안 건드렸다)" \
  || { bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — ${WANT_DIFF}개를 기대했다. 남의 것을 건드렸을 수 있다"; doubt; }
dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 6. app-as 를 다시 띄운다 ──────────────────────────────────────────
#  🔴 tools-as 는 profiles: [tools] 라 up -d 로 띄우지 않는다. 태그만 고쳐 두면
#     다음에 run --rm tools-as 로 부를 때 새 이미지를 쓴다.
#  🔵 **app-po 는 안 띄운다.** 이번 범위에 PO 코드가 0줄이고, 두 시스템이 쓰는
#     API 계약도 안 바뀌었다(A/S 쪽 src/app/api diff 가 **0줄** · 2026-11-06 실측).
printf '\n== 6. app-as 를 다시 띄운다\n'
printf '%s\n' "🔴 --no-deps 다 — app-as 하나만 갈아 끼운다. 나머지 아홉과 DB 둘은 안 건드린다."
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
dc up -d --no-deps $SVCS 2>&1 | sed 's/^/    /'
say "뜨는 것을 20초 기다린다…"; sleep 20
say "정지 구간 $((SECONDS - TSEC))초"

# ── 7. 값으로 확인 ───────────────────────────────────────────────────
printf '\n== 7. 값으로 확인\n'
for r in $(rows); do
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
  #    A/S 는 307 로 로그인에 보내는데 PO 는 303 으로 보낸다 — 로그인으로 넘기는
  #    방식이 사이트마다 다르므로 3xx 리다이렉트는 넷을 다 받는다.
  printf '%s' "$CODE" | grep -qE '200|30[1237]' && ok "$CN 가 응답한다 ($CODE)" || bad "$CN 응답이 ${CODE:-없음}"
done

# 🔴 **PO 가 그대로 도는가** — 이번 판에서 안 건드렸다는 증거다.
PO_ID1=$("$DOCKER" inspect -f '{{.Id}}' "$PO_APP_CN" 2>/dev/null)
PO_RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$PO_APP_CN" 2>/dev/null)
PO_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$PO_PORT/" 2>/dev/null)
say "dss-po — 이미지 ${PO_RUN:-?} · 127.0.0.1:$PO_PORT → ${PO_CODE:-없음}"
[ -n "${PO_ID0:-}" ] && [ "${PO_ID0:-x}" = "${PO_ID1:-y}" ] && ok "dss-po 가 **그대로다**(상자 번호가 안 바뀌었다 — 안 건드렸다)" \
  || hm "dss-po 의 상자 번호가 달라졌다 (${PO_ID0:0:12} -> ${PO_ID1:0:12}) — 안 건드렸어야 한다. 사람이 보세요"
printf '%s' "$PO_CODE" | grep -qE '200|30[1237]' && ok "dss-po 가 응답한다 ($PO_CODE · PO 는 303 으로 로그인에 보낸다)" \
  || bad "dss-po 응답이 ${PO_CODE:-없음}"

# 🔴 DB — 마이그레이션 수가 **여전히** 그대로인가 (이 배포는 DB 구조를 안 건드린다)
MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
say "마이그레이션 ${MIG_AS0:-?} -> ${MIG_AS1:-?} (둘 다 $AS_MIG_AFTER 여야 한다)"
[ "${MIG_AS1:-x}" = "$AS_MIG_AFTER" ] && ok "$AS_MIG_AFTER 다 (이 배포가 DB 를 안 건드렸다)" \
  || bad "🔴 ${MIG_AS1:-?} 다 — $AS_MIG_AFTER 여야 한다. **DB 가 그 사이에 움직였다**"

# 🔴 **양식을 다시 잰다** — 교체 뒤에도 그대로인지, 그리고 **새 앱이 보는지.**
templates_check

# 🔴 **PO 권한을 다시 잰다** — 앱을 안 갈아 끼웠으니 답이 같아야 하지만,
#    **같은지를 봐야** 안다.
po_write_privilege_check soft

# 🔴 도구 태그가 제대로 섰는지 + 이미지 안이 온전한지 다시 센다
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  # 🔵 --go 도 --rollback 도 도구 기대값은 **$TOOLS_NEW 로 같다** — 되돌려도
  #    도구는 그대로 둔다(머리말 ⑥).
  [ "$TCUR" = "$TOOLS_NEW" ] && ok "$AS_TOOLS_SVC 가 $TOOLS_NEW 다" \
    || bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $TOOLS_NEW 를 기대했다"
  "$DOCKER" image inspect "$TCUR" >/dev/null 2>&1 && ok "$TCUR 이미지가 NAS 에 있다" \
    || bad "$TCUR 이미지가 NAS 에 없다 — 다음에 부를 때 못 쓴다"
fi
if [ "$MODE" = go ]; then tools_inside_check; fi
# 🔴 42번에서 넣은 검사는 **그대로 둔다**.
if [ "$MODE" = go ]; then kyosan_folder_check; fi

# 🔴 **안 건드린 아홉이 그대로 도는지** 센다 — 「옆으로 안 샜다」는 증거다.
printf '\n    ── 안 건드린 아홉 (그대로여야 한다)\n'
KEEP_SEEN=0
for c in $KEEP_BOXES; do
  KEEP_SEEN=$((KEEP_SEEN+1))
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
  [ "$s" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
done
# 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다.
[ "$KEEP_SEEN" = "$KEEP_BOXES_WANT" ] && ok "안 건드린 아홉을 다 봤다 (표본이 비지 않았다)" \
  || bad "안 건드린 상자를 ${KEEP_SEEN}개만 봤다 — ${KEEP_BOXES_WANT}개를 기대했다. KEEP_BOXES 가 깨졌다"

# 🔴 **「상자가 돈다」와 「물어보니 답한다」는 다른 말이다.**
if [ "$MODE" = go ]; then inventory_gateway_check strict; fi

printf '\n    ── DB 둘이 안 멈췄는가 (시작 시각이 그대로여야 한다)\n'
for c in $KEEP_DB; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
  b=$(printf '%s' "$DBSTART" | tr ' ' '\n' | sed -n "s/^$c=//p")
  printf '      %-14s %s\n' "$c" "${s:-없음}"
  [ "${s:-x}" = "${b:-y}" ] && ok "$c 가 안 멈췄다" || bad "🔴 $c 가 다시 떴다 (${b:-?} -> ${s:-?})"
done

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
  printf '%s\n' "🔵 **백필은 다시 돌리지 않는다.** 44~51번과 같다 — 까닭:"
  printf '%s\n' "   · 백필은 2026-10-29 새벽에 283건이 끝났다."
  printf '%s\n' "   · 이번 판은 **기술 작업 절차 화면과 엑셀 읽개**다. 연락서를 읽는 규칙과 무관하다."
  printf '%s\n' "   🔵 도구는 올렸지만 돌릴 까닭은 없다 — 올리는 것과 돌리는 것은 다른 일이다."
  printf '%s\n' ""
  printf '%s\n' "🔴 **이번 판의 새 도구 둘은 NAS 에서 돌리지 마세요.**"
  printf '%s\n' "   scripts/import-technical-task-procedures.ts ·"
  printf '%s\n' "   scripts/link-technical-task-next-procedures.ts 는 이미지에 들어 있지만,"
  printf '%s\n' "   둘 다 **개발 DB 게이트**를 지나야 돌고 그 게이트는 루프백 5442 만 통과시킵니다."
  printf '%s\n' "   NAS 에서 부르면 멈춥니다. 🔴 **npm 명령도 아닙니다** — npm run 으로 부르면"
  printf '%s\n' "   Missing script 가 납니다. 절차를 들여오는 일은 **개발 PC 에서** 합니다."
  printf '%s\n' ""
  if [ "$MODE" = go ]; then
    printf '%s\n' "🔵 **세 도구로 수를 세어 --go 전과 견줘 두세요 (읽기만 합니다):**"
    printf '%s\n' "      bash $0 --count"
    printf '%s\n' "   🔵 이번 배포는 그 수들과 **상관이 없습니다** — 달라졌다면 그 사이에 사람이"
    printf '%s\n' "      저장한 것입니다."
    printf '%s\n' ""
  fi
  printf '%s\n' "🔴 **마지막은 눈입니다** — 이번 판은 **절차 화면 정리 + 날짜 칸**입니다."
  printf '%s\n' ""
  printf '%s\n' "  ── A. 기술 작업 절차 목록 ───────────────────────────────────"
  printf '%s\n' "  ① 목록에서 **절차 코드가 안 보이는가** (TECH-… 글자가 화면 열두 자리에서 걷혔다)"
  printf '%s\n' "  ② **이름 검색**과 **설비 유형 거르개**가 머리에 서는가"
  printf '%s\n' "  ③ 🔴 삭제 모드에서 **보이는 것만 골라지는가** — 거르개를 바꿔 화면에서"
  printf '%s\n' "     사라진 줄은 **고르기가 풀려야** 합니다(전에는 원본 목록 전체를 골랐습니다)."
  printf '%s\n' "     🔵 Shift 범위 고르기도 **화면에 보이는 줄** 기준이어야 합니다."
  printf '%s\n' "  ④ 새 절차를 만들 때 **코드 적는 칸이 없는가** (서버가 TECH-날짜-여섯자리로 짓습니다)"
  printf '%s\n' ""
  printf '%s\n' "  ── B. 절차 편집기 · 플로우차트 ──────────────────────────────"
  printf '%s\n' "  ⑤ 노드를 **아래/옆에 더해도 남이 안 밀리는가** (중심점 기준으로 자리를 잡습니다)"
  printf '%s\n' "  ⑥ 높이가 다른 노드를 나란히 놓았을 때 **연결선이 안 꺾이는가**"
  printf '%s\n' "  ⑦ 노드 칩에 **도형 번호(shape id)가 안 보이는가**"
  printf '%s\n' ""
  printf '%s\n' "  ── C. 날짜 칸 (화면 **열넷**에 같은 상한이 들어갔습니다) ────"
  printf '%s\n' "  ⑧ 🔴 연도를 **다섯 자리로 못 치는가** — 한 곳만 보지 마세요. 들어간 자리:"
  printf '%s\n' "     수리건 접수 · 수리건 상세 편집 · 내자 편집/표 칸 · 견적서 편집 ·"
  printf '%s\n' "     서비스 보고서 머리/본문 칸 · 작업 이력 거르개 · 결재 위임 기간 둘 ·"
  printf '%s\n' "     고객 포털 화면."
  printf '%s\n' "     🔵 **한 곳만 보고 넘어가면 나머지 열셋이 안 들어갔는지 모릅니다.**"
  printf '%s\n' ""
  printf '%s\n' "  🔵 **엑셀 읽개는 눈 확인 대상이 아닙니다** — 개발 PC 에서만 도는 도구입니다."
  printf '%s\n' ""
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "🔴 **이어서 — 개발에서 만든 절차를 운영에 넣습니다 (c6b2b271 의 길)**"
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "  🔵 **배포와 별개의 일입니다.** 안 해도 운영은 멀쩡히 돕니다 — 넣을 절차가"
  printf '%s\n' "     있을 때만 하세요. 🔴 **이 스크립트는 여기에 손대지 않습니다**(안내만 합니다)."
  printf '%s\n' ""
  printf '%s\n' "  🔴 아래 명령의 자리값은 **이 스크립트가 방금 실제로 쓴 값**입니다 —"
  printf '%s\n' "     저장소 문서에서 베낀 글이 아닙니다(1절이 그 파일을 직접 읽었습니다):"
  printf '%s\n' "       작업 폴더   : $D/deploy"
  printf '%s\n' "       compose     : $CF"
  printf '%s\n' "       설정 파일   : .env.nas"
  # 🔵 **방금 고친 compose 에서 다시 읽는다** — 1절의 값은 고치기 전 것이다.
  #    🔴 img_line 이 빈 값을 줄 수 있으므로 변수로 받아 가린다(awk 에 빈 n 을
  #       넘기지 않는다). 못 읽으면 그렇게 적는다 — 빈칸으로 두지 않는다.
  TLTAIL=$(img_line "$AS_TOOLS_SVC" 2>/dev/null || true)
  if [ -n "${TLTAIL:-}" ]; then TTAGTAIL=$(tag_at "$TLTAIL"); else TTAGTAIL="못 읽음"; fi
  printf '%s\n' "       도구 서비스 : $AS_TOOLS_SVC  (지금 태그: ${TTAGTAIL})"
  printf '%s\n' "     🔵 docker 는 $DOCKER 입니다(비로그인 PATH 에 없어 전체 경로로 씁니다)."
  printf '%s\n' ""
  printf '%s\n' "  ① (NAS) 받을 자리를 만든다 — 🔴 **777 이어야 합니다**"
  printf '%s\n' "       mkdir -p $D/transfer"
  printf '%s\n' "       chmod 777 $D/transfer"
  printf '%s\n' "     🔴 root 가 만든 755 는 **scp 가 못 씁니다**(scp 는 root 가 아닌 계정으로 붙습니다)."
  printf '%s\n' "        50번에서 실제로 「Permission denied」로 걸렸습니다."
  printf '%s\n' ""
  printf '%s\n' "  ② (개발 PC · PowerShell) 짐을 떠서 보낸다 — 🔴 경로는 **빗금**으로"
  printf '%s\n' "       cd \"C:/Users/희만/Desktop/Development/RF_Service_System\""
  printf '%s\n' "       npm run procedures:export -- --out \"\$env:TEMP/bundle.json\""
  printf '%s\n' "       scp -O \"\$env:TEMP/bundle.json\" dss-nas:$D/transfer/"
  printf '%s\n' "     🔴 **-O 를 빼지 마세요.** 🔵 --out 을 저장소 안으로 주면 그 도구가 스스로 말립니다."
  printf '%s\n' ""
  printf '%s\n' "  ③ (NAS) **작성자를 고른다** — --actor 없이 부르면 고를 수 있는 계정을 찍고 멈춥니다"
  printf '%s\n' "       cd $D/deploy"
  printf '%s\n' "       $DOCKER compose -f $CF --env-file .env.nas --profile tools \\"
  printf '%s\n' "         run --rm -v $D/transfer:/transfer:ro $AS_TOOLS_SVC \\"
  printf '%s\n' "         npm run procedures:import -- --file /transfer/bundle.json"
  printf '%s\n' "     🔵 **읽기만 합니다.** 찍힌 uuid 중 하나를 ④ 의 <uuid> 에 넣으세요."
  printf '%s\n' "     🔴 짐 파일은 **이미지 안에 없습니다** — -v 로 붙이지 않으면 못 찾습니다."
  printf '%s\n' ""
  printf '%s\n' "  ④ (NAS) **드라이런** — DB 를 한 글자도 안 바꿉니다"
  printf '%s\n' "       $DOCKER compose -f $CF --env-file .env.nas --profile tools \\"
  printf '%s\n' "         run --rm -v $D/transfer:/transfer:ro $AS_TOOLS_SVC \\"
  printf '%s\n' "         npm run procedures:import -- --file /transfer/bundle.json --actor <uuid>"
  printf '%s\n' "     🔵 맨 위에 **어느 DB 에 넣는지**가 찍힙니다(호스트:포트/DB 이름). 거기부터 보세요."
  printf '%s\n' "     🔵 걸리는 것이 하나라도 있으면 **한 글자도 안 쓰고** 멈춥니다."
  printf '%s\n' ""
  printf '%s\n' "  ⑤ (NAS) ✍ **넣는다** — 앞에 -e APPLY=1 을 더하는 것이 전부입니다"
  printf '%s\n' "       $DOCKER compose -f $CF --env-file .env.nas --profile tools \\"
  printf '%s\n' "         run --rm -e APPLY=1 -v $D/transfer:/transfer:ro $AS_TOOLS_SVC \\"
  printf '%s\n' "         npm run procedures:import -- --file /transfer/bundle.json --actor <uuid>"
  printf '%s\n' "     🔵 쓰기는 **한 트랜잭션**입니다 — 중간에 죽으면 통째로 되돌아갑니다."
  printf '%s\n' ""
  printf '%s\n' "  ⑥ 🔴 **끝의 두 줄을 읽으세요.** 「결과」는 내가 몇 번 불렀나이고,"
  printf '%s\n' "     「되읽기」는 **DB 를 다시 읽어 센 수**입니다. 둘이 어긋나면 0 아닌 종료 코드로 끝납니다."
  printf '%s\n' "     🔵 메인이 알려 준 이번 짐의 기대값(🔴 **내가 재어 본 값이 아닙니다**):"
  printf '%s\n' "        결과: 절차 25 · 노드 836 · 분기 1095 · 메모 58 · 이어가기 12"
  printf '%s\n' "        되읽기: … 12/12   ← **분모와 분자가 같아야** 합니다"
  printf '%s\n' "     🔴 수가 다르면 **짐이 다른 것**입니다. 되읽기가 어긋나면 화면에서 확인하세요."
  printf '%s\n' ""
  printf '%s\n' "  ⑦ 🔴 **넣은 25개는 전부 DRAFT 입니다.** 이 도구는 **게시하지 않습니다** —"
  printf '%s\n' "     화면에서 보고 사람이 따로 게시합니다. 게시 전까지는 현장에서 안 보입니다."
  printf '%s\n' ""
  printf '%s\n' "  🔵 되돌리기: 넣은 절차는 **DRAFT 라 화면에서 지울 수 있습니다.** 이 배포의"
  printf '%s\n' "     --rollback 과는 **아무 상관이 없습니다**(이미지만 되돌립니다)."
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' ""
  printf '%s\n' "  🔵 **아무것도 안 바뀐 것처럼 보이면** app-as 가 정말 새 태그로 도는지(위 7절) 먼저"
  printf '%s\n' "     보시고, 맞다면 알려 주세요."
  printf '%s\n' ""
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (app-as 만 되돌립니다. 🔵 도구는 $TOOLS_NEW 그대로)"
  printf '%s\n' "  🔵 **DB 는 되돌릴 것이 없습니다** — 이 배포가 DB 를 한 글자도 안 바꿉니다."
  printf '%s\n' "     그래도 위에 적힌 덤프는 그 시각의 사진으로 남겨 둡니다."
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
  printf '%s\n' "  🔵 ✗ 가 **재고 관리 통로** 하나뿐이라면 되돌리기 전에 설정을 먼저 보세요 —"
  printf '%s\n' "     INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN (env/as.env). 🔴 되돌려도 같은"
  printf '%s\n' "     설정 문제는 남습니다 — 옛 판도 같은 통로를 씁니다."
  printf '%s\n' "  🔴 ✗ 가 **PO 의 repair_cases 쓰기 권한**이라면 그것은 **이 배포가 만든 일이**"
  printf '%s\n' "     **아닙니다**(PO 를 안 건드립니다). 되돌려도 안 고쳐집니다 — 사람이 봐야 합니다."
  printf '%s\n' "  🔴 ✗ 가 **양식**이라면 되돌리지 마세요 — 이 배포는 양식을 한 장도 안 건드립니다."
  printf '%s\n' "     운영 양식이 개발 PC 것과 달라진 것이고, 올리는 모드는 51-deploy.sh 에 있습니다."
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
