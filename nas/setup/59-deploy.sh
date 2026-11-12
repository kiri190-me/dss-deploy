#!/bin/bash
# dss-deploy/nas/setup/59-deploy.sh — 쉰다섯째 배포 (2026-11-12)
#
# 🔵 **배포 회차(쉰다섯째)와 파일 번호(59)가 어긋나는 것은 이 저장소에서 원래
#    그렇다** — 55번 파일이 쉰두째였고, 57번이 쉰세째, 58번이 쉰네째였다.
#    (56번은 2026-11-11 의 **양식 전용**이라 배포 회차로 세지 않았다.)
#
# 🔵 **판이 5.0 → 5.1 로 그냥 하나 는다.** 도구는 17 → 18.
#    🔴 58-deploy.sh 에는 「4.10 이 아니라 5.0 이다」라는 경고가 머리말·배너·상수
#       주석 **세 곳**에 있었다. 그것은 **그 판의 사정**이다 — 이번 판에는 자릿수가
#       넘어가는 자리가 없으므로 그 글을 베껴 두면 **아무것도 안 가리키는 경고**가
#       된다. 지웠다.
#
# 🔴 NAS 에서 돈다. **DSM 터미널은 긴 명령을 잘라 먹는다**(2026-10-12 하루에 네
#    번 깨졌다). 그래서 손으로 치지 않고 **파일로 올려** 돌린다. 절차는 이렇다:
#      ① (개발 PC · PowerShell) — 🔴 **경로는 빗금으로**
#           cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#           scp -O 59-deploy.sh dss-nas:/volume1/dss/setup/
#           Get-FileHash -Algorithm MD5 59-deploy.sh
#      ② (NAS) md5sum /volume1/dss/setup/59-deploy.sh
#      ③ 🔴 **두 md5 가 같은지 눈으로 맞댄다.** 다르면 옮기다 잘린 것이다 —
#         그대로 돌리면 중간에서 끊긴 스크립트가 compose 를 고치다 만다.
#      🔵 이 파일은 돌 때 맨 위에서 **제 md5 를 스스로 찍는다.**
#    🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#    🔴 **역슬래시 경로를 쓰지 마라.** bash 와 scp 가 그 역슬래시를 먹어
#       "C:Users희만Desktop…" 가 된다.
#    🔴 **Tee-Object 로 로그를 받지 마라** — PowerShell 이 UTF-16 으로 써서
#       나중에 grep 이 한 줄도 못 찾는다. 이 파일은 **스스로 로그를 남긴다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **58-deploy.sh 에서 베꼈다가 「이번 판엔 거짓」이라 뒤집은 것 열하나**
# ══════════════════════════════════════════════════════════════════════
#   틀·절 구성은 58-deploy.sh(쉰네째)를 그대로 썼다. **58번과 이번은 겉이 매우
#   닮았다** — 마이그레이션 0건 · 묶음 안 보냄 · 양식 0장 · 포털·PO 안 건드림이
#   전부 같다. 🔴 **닮았다는 것이 곧 위험이다** — 뒤집을 것이 적어서 무심코 베끼면
#   「이 판에서 아무것도 안 재는 ✓」가 조용히 늘어난다.
#   🔴 「배포본은 지난 판의 전제를 업고 온다」가 이 저장소에 기록된 함정이다.
#   🔵 아래에 적은 「58번은 ~였다」는 **58-deploy.sh 를 직접 열어 확인한 것만**이다.
#      그 파일에 없던 말은 아예 안 적었다 — 틀린 설명은 없는 설명보다 나쁘다.
#
#   ① 🔵 **판이 5.0 → 5.1 · 도구 17 → 18.** 58번은 4.9 → 5.0 · 16 → 17 이었다.
#   ② 🔴 **되돌릴 판이 dss-as:5.0 이다**(58번이 올린 그것).
#   ③ 🔴 **덤프 이름이 v54 → v55**, compose 사본도 v55 다.
#   ④ 🔴 **도구 이미지 안 검사의 ③번 목록이 10개다.** 58번은 **20개**였다
#      (src/ 18 + scripts/ 2). 🔴 **이번 판은 scripts/ 변경이 0개**라 그 목록이
#      **전부 src/** 다. 58번의 수를 그대로 두면 **멀쩡한 판이 ✗** 다.
#      🔵 그렇다고 **「scripts/ 를 안 본다」로 만들지 않았다** — 아래 ⑤ 와
#         도구 이미지 안 검사의 **③-ㅁ** 이 「정말 0인가」를 값으로 재고,
#         **1 이상이면 ✗** 다. 🔵 ③-ㄹ 은 그 반대쪽이다 — 「바뀌지는 않았지만
#         이미지 안에는 있어야 하는 목록 파일 넷」을 따로 본다.
#   ⑤ 🔴 **「새로 생긴 일곱이 담겼는가」 절을 뜻을 바꿔 살렸다.** 58번은 새 파일이
#      **7개**였고 그 일곱을 경로로 세고 있었다. 🔴 **이번 판은 새 파일이 0개**다 —
#      그 절을 그대로 두면 0/7 로 **멀쩡한 판이 ✗** 다. 대신 **바뀐 열 장이 전부
#      새 내용인가**를 날짜 글자(2026-11-12)로 잰다. 기준판 src/ 에 **0파일**이다.
#   ⑥ 🔴 **「새 시험 다섯이 목록에 등록돼 있는가」를 「고친 시험 여섯이 이미
#      등록돼 있는가」로 바꿨다.** 이번 판에는 **새 시험 파일이 한 장도 없다** —
#      58번의 그 다섯 경로를 그대로 두면 다섯 다 no 가 나와 **가짜 ✗** 다.
#      🔵 등록이 빠지면 **이번에 고친 단언이 오류 없이 조용히 안 돈다**(이 저장소의
#         시험은 글롭이 아니라 목록 파일에 적어야 돈다).
#   ⑦ 🔴 **도구 이미지의 표식을 전부 갈았다.** 58번의 다섯은
#      status=IN_HOUSE · IN_HOUSE_STATUSES · isShortcutActive ·
#      BillingTypeFilterValue · customerNames 였다 — 🔴 **이번 판은 그 다섯을 하나도
#      안 건드린다.** 그대로 두면 **옛 판에서도 전부 ✓** 인 죽은 검사가 된다.
#      🔵 이번 판의 여섯은 아래 AS_MARKS 에 있고, 전부 **기준판(242f0f69)의 그
#         파일에 0번 · 지금 판에 1번 이상**이다(2026-11-12 실측).
#   ⑧ 🔴 **앱 번들의 표식도 갈았다.** 58번의 APP_MARK 는 status=IN_HOUSE 였다 —
#      **이번 판은 그 글자를 만들지 않는다.**
#      🔴 **상수 이름·함수 이름으로 재지 않는다.** 번들은 minify 를 거치므로
#         APPROVAL_GRANTED_BROAD_RECIPIENT_ROLES 같은 **이름이 남는다는 보증이
#         없다** — 그 이름으로 재면 멀쩡한 이미지가 ✗ 가 될 수 있다. 58번이
#         status=IN_HOUSE 를 고른 까닭도 「**href 에 들어가는 리터럴**이라 이름이 안
#         바뀐다」였다. 그래서 이번 판도 **화면에 나가는 문자열**로 잰다 —
#         알림 설정 화면의 **새 설명 글자**다(ASCII 날짜 하나 · 한글 토막 하나).
#      🔵 **뒷걸음 방지는 하나에서 둘로 늘렸다.** 58번은 APP_KEEP_MARK 하나였다
#         (그때는 쉰세째 것 하나만 지키면 됐다). 이번 판이 지킬 것은 **둘**이다:
#         status=IN_HOUSE(**쉰네째**가 올린 글자) · no-equipment-key(**쉰세째**).
#   ⑨ 🔴 **--count 의 effect_counts() 를 통째로 갈았다.** 58번은 **입고 건수 셋**
#      (휴지통을 뺀 전체 · 출하 완료가 아닌 건 · 그 차이)과 **기타건 둘**(줄 수 ·
#      공급처가 빈 줄)을 셌다 — 🔴 **그 다섯은 이번 판과 아무 상관이 없다.**
#      그대로 두면 **이 배포를 재는 숫자가 하나도 없다.** 이번 판이 재는 것은
#      아래 「--count 가 세는 것」이다.
#   ⑩ 🔴 **꼬리말의 「볼 곳」을 통째로 갈았다.** 58번은 **대시보드 카드 하나와
#      필터 일곱**이었고 「다섯 커밋이 전부 화면을 바꾼다」였다.
#      🔴 **이번 판은 거의 안 보인다** — 커밋 하나이고, 눈에 보이는 것은 설정
#      화면의 **설명 글자 한 줄**과 **종에 서는 줄**뿐이다.
#   ⑪ 🔴 **58번 꼬리말의 「이번 판은 화면만 고쳤다 · 서버 조회도 안 바뀌었다」는
#      이번 판에 거짓이다.** 이 판이 고친 열 장은 **전부 src/lib/ 아래**이고,
#      바뀐 것이 바로 **조회의 WHERE** 다. 그 두 줄을 지우고 반대로 적었다.
#
#   ── 🔵 **58번과 같아서 안 뒤집은 것 여섯** (그래도 값으로 다시 잰다)
#      · 마이그레이션 **0건** · DB 기록 **127 그대로**(앞뒤가 같다)
#      · 묶음 **안 보낸다** · **--migrate 모드가 없다**
#      · 양식 **0장** · 포털·PO **안 건드린다**
#      🔴 같다고 절을 지우지 않았다. 「0건·0장·안 건드림」은 **이번 판에서도 참인지
#         재야** 참이다 — 그것이 2-ㄹ·1-ㄷ·7절이 하는 일이다.
#
#   갈아 끼우는 것 — **저장소 하나, 태그 둘**
#     ① A/S 앱    dss-as:5.0        → **dss-as:5.1**
#     ② A/S 도구  dss-as-tools:17   → **dss-as-tools:18**
#
#   🔵 **안 건드리는 아홉** — 포털 · 재고 · 계측기 · 게시판 · 개선요청 · 휴가 ·
#      통합 승인함 · RF 이슈관리 · PO.
#   🔵 **양식(.xlsx)은 한 장도 안 올린다.** 이번 범위에 .xlsx 변경이 0줄이다.
#      그래서 이 파일에는 **--templates-prep 와 --templates-apply 가 없다.**
#      🔴 **양식이 바뀌는 날 되살릴 곳**: 51-deploy.sh 의 1056~1172줄
#         (--templates-prep) · 1174~1341줄(--templates-apply). 🔵 2026-11-11 의
#         56-stage.sh · 56-templates.sh 도 양식만 올리는 짝이다.
#      🔵 다만 **재는 쪽은 남겼다** — 1-ㄷ 절이 운영 양식 열하나를 md5 로 재고,
#         앱이 그것을 읽는지 설정 이름으로 묻는다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **--migrate 모드가 없다** — 58번과 같은 판단이다
# ══════════════════════════════════════════════════════════════════════
#   이번 판도 마이그레이션이 **0건**이고 묶음도 **안 보낸다.** 모드를 남겨 두면
#   둘 중 하나가 된다:
#     ㄱ) 묶음이 없어 **「묶음이 없다」로 멈춘다** — 멀쩡한 배포가 ✗ 로 보인다.
#     ㄴ) 멈추지 않더라도 db:migrate 가 **0건으로 조용히 끝난다** — 사람이
#         「돌긴 돌았나」를 알 수 없다.
#   🔴 어느 쪽이든 사람이 헷갈린다. 그래서 **모드를 두지 않았다.**
#
#   🔵 **대신 「이번 판에는 할 일이 없다」를 값으로 확인하고 지나간다.** 2-ㄹ 절이
#      ① 볼륨의 .sql 이 127장인가 ② meta/_journal.json 의 idx 가 127개인가
#      ③ DB 기록이 127인가 ④ **적용 대기 = 볼륨 − 기록 = 0건**인가
#      ⑤ db:preflight 가 **종료 코드 0** 으로 끝나는가 — 다섯을 잰다.
#      🔴 ①②가 핵심이다 — **마이그레이션은 이미지 안이 아니라 볼륨에서 돈다.**
#         이미지 안만 세면 0건으로 조용히 끝난다(39·48·53번이 겪었다).
#
#   🔴 **--migrate 를 치면 거절한다.** 그냥 「모르는 모드」라고 하지 않고
#      **까닭과 되살릴 길**을 찍는다 — 55번을 기억하는 사람이 반드시 쳐 본다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이번 판이 운영에 들고 가는 것 — **커밋 하나 · 종 알림의 받는 사람**
# ══════════════════════════════════════════════════════════════════════
#   1259d822 「승인 완료」 알림을 영업·관리자·최고관리자에게도
#     · 전에는 「승인 완료」 종 알림이 **승인을 요청한 사람 본인에게만** 떴다.
#     · 이제 **영업(SALES)·관리자(ADMIN)·최고관리자(SUPER_ADMIN)** 역할인 사람은
#       **남이 올린 결재의 승인 완료**도 종에서 본다.
#     · 🔵 **「반려됨」은 안 바뀐다 — 요청자 본인뿐이다.** 일부러 그렇게 두었다
#       (반려는 고쳐서 다시 올릴 사람에게 가는 할 일이라 명단을 넓히면 성격이
#       달라진다). 조회 함수가 역할을 **인자로 받지도 않는다.**
#       🔴 **이 판에서 가장 놓치기 쉬운 자리가 여기다** — 안 바꾼 쪽이 조용히
#          바뀌지 않았는지를 꼬리말의 「볼 곳」이 눈으로 확인하게 한다.
#     · 🔵 **되좁히는 손잡이**는 알림 설정의 역할 스위치다 — 영업·관리자 칸을 끄면
#       그 역할은 남이 올린 결재의 결과도 안 받는다.
#     · 🔵 설정 화면의 **설명 글자**가 바뀐다(「요청한 사람 본인에게만 가고」 →
#       「요청한 사람 본인과 영업·관리자·최고관리자에게 가고(2026-11-12)」).
#
#   🔴 **바뀐 열 장이 전부 src/lib/ 아래다** — 번들의 **서버 쪽**이다.
#      🔵 그래서 이 배포는 **화면 코드를 한 줄도 안 고친다** — 58번과 정반대다.
#         브라우저 캐시 때문에 안 보일 일도 없다(설명 글자는 서버가 그린다).
#   🔵 **DB 를 한 글자도 안 바꾼다.** 마이그레이션 0건 · 자료 변경 0.
#   🔵 **설정도 안 바꾼다** — 이번 범위에 늘어난 process.env 이름이 **0개**다
#      (2026-11-12 실측 — 바뀐 열 장에 process.env 를 더한 줄이 0줄이다).
#   🔵 **공유폴더도 안 건드린다** — 이 배포는 디스크를 아예 안 본다.
#      🔴 그래도 1-ㅁ 절(발주서·견적서 폴더)은 **그대로 둔다** — 한 번 빼면 다시
#         넣는 사람이 없다(42~58번의 규율). 다만 **이 배포의 핵심 자리는 아니다.**
#
# ── 🔴 알고도 안 고친 것 — PO 가 모르는 것이 **셋**이다 (55번에서 넘어옴) ──
#   ① dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 APPROVAL_REQUIRED 가 없다.
#   ② PO 는 납품일 칸(delivered_date·delivered_by)을 모른다.
#   ③ PO 는 회차 승인(due_date_row_order)을 모른 채 같은 표를 고친다.
#   🔵 **지금은 안전하다** — 운영에서 직원의 PO 접근 권한을 모두 빼 두었다
#      (2026-11-08 사용자). 🔴 **PO 를 다시 여는 날 셋을 한 묶음으로 이식해야 한다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **상태 변수를 먼저 정하고 가지를 나눈다** — 48번이 데인 자리다
# ══════════════════════════════════════════════════════════════════════
#   48번에서 --check 의 기대값이 **한 갈래**라 적용 뒤에 다시 부르면 가짜 ✗ 가
#   났다. 그래서 이 파일은 **맨 처음에 운영의 단계(PHASE)를 읽고** 가지를 나눈다.
#     PRE   둘 다 옛 판         → 아직 아무것도 안 갈아 끼웠다
#     POST  둘 다 새 판         → --go 까지 돌았다
#     MID   도구만 새 판        → 🔴 **--go 뒤에 --rollback 으로 앱만 되돌린 상태다**
#           🔵 55번에서는 「--migrate 까지 돌았다」였다. **이 판에도 --migrate 가
#              없으므로 그 뜻이 성립하지 않는다**(58번이 뒤집어 둔 그대로다).
#     ODD   그 밖               → 표를 찍고 사람이 본다 (막지는 않는다)
#   🔴 **이번 판도 마이그레이션 수가 가지를 나누지 않는다 — 어느 단계에서나 127.**
#      그래서 **갈래를 두지 않고** 대신 「앞뒤가 같은가」와 「적용 대기 0건인가」를 잰다.
#
# ── 🔴 48~58번에서 그대로 가져온 것 ──────────────────────────────────
#   ① **3xx 판정**(grep -qE '200|30[1237]'). A/S 는 307, PO 는 303 으로 로그인에
#      보낸다. 빠뜨리면 **멀쩡한 사이트가 ✗ 로 나온다**(2026-10-30 실측).
#   ② 🔴 **치환 전에 그 줄의 낱말 수가 2 인지 본다.** 줄 끝에 주석이 붙어 있으면
#      **주석의 마지막 낱말**이 태그로 바뀌고 image: 값은 그대로 남는다.
#   ③ 🔴 **달라진 image: 줄 수를 박지 않는다 — 세어서 정한다.**
#   ④ 🔴 **설정 파일 검사**(중복 키 · auto). 값은 한 글자도 안 찍는다.
#   ⑤ 🔵 연락서 폴더 검사 · 재고 관리 통로 검사 · 발주서/견적서 폴더 검사는
#      **42~58번 것 그대로다.** 🔴 **빼지 않는다** — 한 번 빼면 다시 넣는 사람이 없다.
#      🔵 **이번 판의 핵심 자리는 아니다** — 이 배포는 디스크를 아예 안 본다.
#         그래도 ✗ 가 나면 그것은 **지난 판이 올린 기능이 지금 고장나 있다는 뜻**이라
#         사람이 봐야 한다.
#   ⑥ 🔵 **--rollback 은 앱만 되돌린다.** 도구는 새 판 그대로 둔다 —
#      39·41~58번과 같은 판단(평소에 뜨지 않는 상자다).
#   ⑦ 🔴 **DB 둘의 StartedAt 을 앞뒤로 비교한다** — 안 멈췄다는 증거다.
#   ⑧ 🔴 **제 md5 를 스스로 찍는다** · **image: 줄을 통째로 찍는다**.
#   ⑨ 🔴 **PO 의 repair_cases 쓰기 권한을 잰다** — PO 를 안 건드려도 잰다.
#
# ── 모드 다섯 — **쓰는 것 / 안 쓰는 것** ──────────────────────────────
#   (기본) --check
#       쓰는 것 : **없다.** (로그 파일 하나만 남긴다)
#       안 쓰는 것: compose · 이미지 · DB · 볼륨 · 양식 · 공유폴더 — 전부.
#       🔴 다만 **읽기는 한다** — DB 에 select, 앱 주소에 GET, 재고 통로에 GET,
#          양식 폴더에 ls·md5sum, **도구·앱 이미지가 실려 있으면 각각 컨테이너를
#          잠깐 띄웠다 지운다**(run --rm · sh 로 열 뿐 앱을 시작하지 않는다).
#          「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#   --count
#       쓰는 것 : **없다.** 도구 다섯을 **읽기만** 해서 부른다(--apply 가 없다).
#       안 쓰는 것: 전부. DB 에 한 글자도 안 쓴다.
#       🔵 여기에 **이 배포가 바꾸는 자리를 세는 절**이 붙어 있다(effect_counts).
#          🔴 58번의 그 절과 **재는 것이 완전히 다르다** — 아래 「--count 가 세는 것」.
#   --preload
#       쓰는 것 : **NAS 의 도커 이미지 저장소**(docker load 로 태그 둘을 싣는다).
#       안 쓰는 것: compose · DB · 볼륨 · 양식 · 도는 컨테이너.
#       🔵 실어만 두고 **아직 안 갈아 끼운다.**
#       🔴 싣자마자 **둘 다 안을 센다**(도구 · 앱). 늦게 발견할수록 되돌리기가 비싸다.
#   --go
#       쓰는 것 : **DB 덤프 한 장** · **compose 사본 한 장** ·
#                 **compose 의 image: 줄 둘**(app-as · tools-as) ·
#                 **app-as 컨테이너를 다시 띄운다**(정지 창 약 25초).
#       안 쓰는 것: 🔴 **DB 의 자료와 스키마**(한 글자도 안 바꾼다) ·
#                 마이그레이션 볼륨 · 양식 · 공유폴더 ·
#                 app-po · app-auth · tools-auth 의 image: 줄 · 나머지 아홉 상자.
#   --rollback
#       쓰는 것 : **compose 사본 한 장** · **compose 의 image: 줄 하나**(app-as 만) ·
#                 **app-as 컨테이너를 다시 띄운다.**
#       안 쓰는 것: 도구 태그(새 판 그대로 둔다) · DB · 볼륨 · 덤프(안 뜬다 —
#                 되돌리는 길은 빠를수록 좋다).
#   --migrate
#       🔴 **없다.** 치면 까닭을 찍고 거절한다(위 「--migrate 모드가 없다」).
#
# ── 🔴 bash -n 이 못 잡는 넷 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 쓴 뒤 grep 으로 세었다.
#   ② 읽기 전용 자리에 콜론 하나와 꺾쇠로 빈 파일을 만들면 NAS 의 ash 가 셸을
#      그 자리에서 끝낸다(2026-10-12 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   ③ 🔴 bash 의 $(( )) 는 0 으로 시작하는 수를 **8진수**로 읽는다 —
#      0126 을 셈에 넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
#   ④ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」
#      같은 안전망을 달면 **하필 바라던 0 에서만** 터진다. 이 파일은 그 꼴을
#      한 군데도 쓰지 않는다 — 셈은 「$( … || true )」 로 받는다.
#   🔴 그리고 **tar | grep -q 를 if 에 바로 물리지 않는다.** set -uo pipefail
#      아래에서 grep -q 가 찾자마자 끝내면 앞의 tar 가 SIGPIPE 로 죽어,
#      **파일이 있을 때 오히려 ✗** 가 난다(2026-11-07 쉰째 배포에서 실제로 났다).
#      🔵 이번 판에도 묶음이 없어 tar 를 읽는 자리가 **셋**(지문 읽기)뿐이고
#         셋 다 **grep -o** 로 값을 받아 담는 꼴이다.
#   🔴 19·20·21번에는 ①②가 아직 남아 있다. **거기서 베껴 오지 마라.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **CRLF — 줄 전체로 맞대는 검사는 개발 PC 에서만 통과한다**
# ══════════════════════════════════════════════════════════════════════
#   A/S 저장소의 작업본은 **전부 CRLF** 다. 🔴 **Git Bash 의 grep 은 \r 를 스스로
#   걷어내고, 리눅스 컨테이너의 GNU grep 은 안 걷어낸다.** NAS 가 바로 그쪽이다.
#   그래서 「-Fx」(줄 전체 일치)로 맞대는 검사가 **개발 PC 에서만 맞는다** —
#   2026-11-11 쉰네째의 --go 에서 「새 시험 다섯이 목록에 등록돼 있나」가
#   **0/5 로 가짜 ✗** 를 냈다(이미지는 멀쩡했고 검사가 틀렸다).
#
#   처방(58-deploy.sh 가 고쳐 둔 그대로 가져왔다):
#     · 읽자마자 **tr -d 로 \r 를 걷어낸 뒤** 맞댄다.
#     · 「-Fx」 는 **살린다** — 경로 일부만 겹치는 다른 줄에 걸리면 안 된다.
#     · **읽은 줄 수를 함께 받아 너무 적으면 ✗** 로 센다(빈 결과는 삼켜진 오류일
#       수 있다 — 「0건」과 「못 읽었다」는 다른 말이다).
#     · **없는 경로 하나를 일부러 함께 묻는다** — 그 줄이 no 로 안 나오면
#       「무조건 yes」인 검사라는 뜻이고 나머지 yes 도 못 믿는다.
#     · **cat 의 글롭은 set -f 앞에 둔다** — 뒤에 두면 *.txt 가 글자 그대로 남아
#       파일을 한 줄도 못 읽는다.
#   🔵 이 파일에서 **파일을 읽어** 줄 전체로 맞대는 자리는 **한 곳**뿐이다 —
#      도구 이미지 안 검사의 ③-ㄷ(시험 등록)이고, 거기에 다섯이 전부 들어 있다.
#      🔵 7절의 「KEEP_BOXES 에 dss-auth 가 있는가」도 줄 전체 일치(grep -qx)지만
#         **셸 변수**를 보는 것이라 \r 가 낄 자리가 없다.
#      🔵 .dockerignore 를 줄 전체로 보는 검사는 **이 파일에 없다**(59-build.sh 쪽 일이다).
#
# ── 🔴 비밀값을 찍지 않는다 ───────────────────────────────────────────
#   설정 파일은 **이름이 있는가/없는가**와 **auto 인가**만 본다. PO 권한 검사는
#   DATABASE_URL 에서 **역할 이름만** 꺼낸다. 🔵 **양식 경로는 찍어도 된다** —
#   /templates/… 는 저장소의 compose 사본에 이미 적혀 있는 값이고 비밀이 아니다.
#   🔴 다만 **/templates 밖을 가리키는 값은 안 찍는다.**
#   🔴 그리고 **한글을 HTTP 머리말·argv 에 넣지 않는다** — 넣으면 요청이 아예 안
#      나가고, 그 ✗ 가 진짜 결함처럼 보인다.
#   🔵 앱 번들의 **한글 표식 하나**만 예외인데, 그것도 argv 로 한글을 넘기지 않는다 —
#      **8진 이스케이프**를 넘기고 컨테이너 안에서 다시 만든다(바이트 수를 먼저 받는다).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **--count 가 세는 것** — 58번과 완전히 다른 자리다
# ══════════════════════════════════════════════════════════════════════
#   🔴 58번은 **입고 건수 셋**(휴지통을 뺀 전체 · 출하 완료가 아닌 건 · 그 차이)과
#      **기타건 둘**을 셌다. **그 다섯은 이번 판과 아무 상관이 없다.** 그대로 두면
#      이 배포를 재는 숫자가 **하나도 없다** — 그래서 통째로 갈았다.
#
#   🔴 **이 배포는 DB 를 한 줄도 안 바꾼다.** 그러니 「배포 전후의 차이」로 재면
#      **전후가 똑같이 나와 아무것도 못 잰다.** 대신 **새 코드가 보여 주게 될 줄
#      수를 지금 DB 로 미리 계산한다.**
#
#   ① 🔵 **영업·관리자·최고관리자인 사람 수**(활성 계정 · 휴지통 뺌).
#      🔴 0 이면 이 배포로 달라질 사람이 아무도 없다는 뜻이다(⚠️).
#   ② 🔵 **지난 7일 안에 최종 승인된 결재** — 사건 자체의 수다(사람과 무관).
#   ③ 🔵 **지금(옛 코드) 그 사람들의 종에 뜨는 「승인 완료」 줄** — 자기가 올린
#      것만이다. 🔴 **이것이 기대값의 아래쪽**이다 — 배포 뒤에도 이 줄들은 그대로 뜬다.
#   ④ 🔴 **이 배포 뒤에 새로 뜨는 줄** — 남이 올린 결재의 승인 완료다.
#      🔵 **0 이면 ⚠️ 다. ✗ 가 아니다** — 「배포는 멀쩡한데 눈으로 확인할 거리가
#         없다」는 뜻이고, 며칠 뒤 결재가 하나 끝나면 저절로 생긴다.
#   ⑤ 🔵 ③+④ = 배포 뒤 그 사람들의 종에 설 「승인 완료」 줄의 합.
#   ⑥ 🔴 **안 바뀌는 쪽을 재는 자리** — 지난 7일 안에 **반려**된 결재 중 **남이
#      올린** 것이 몇 줄인가. 🔴 **그 수만큼은 배포 뒤에도 영업·관리자의 종에
#      「안 떠야」 한다.** 이 판에서 가장 놓치기 쉬운 자리라 수를 찍어 둔다.
#   ⑦ 🔵 **알림 설정 스위치** — 「승인 완료」 종류가 꺼져 있는지, 영업·관리자
#      역할이 꺼져 있는지. 🔴 꺼져 있으면 **코드가 맞아도 한 줄도 안 뜬다.**
#      행이 없는 것이 정상이다(없으면 코드의 기본값 = 켜짐).
#
#   🔴 **SQL 은 조회 함수의 WHERE 를 그대로 베꼈다** — 칸 이름만 보고 짜면 틀린다.
#      베낀 자리: src/lib/db/queries/approval-outcome-notifications.ts 의
#      listRepairCaseApprovalOutcomes · listQuoteApprovalOutcomes ·
#      listDomesticOrderApprovalOutcomes (바깥 입구가
#      listMyGrantedApprovalOutcomes(viewerUserId, viewerRole, options) 다 —
#      🔴 **역할이 필수 인자**다). 빼먹지 않은 조건:
#        · status = 'APPROVED' (⑥ 은 'REJECTED')
#        · decided_at >= now() − **7일**
#          (domain/notifications.ts 의 APPROVAL_OUTCOME_NOTIFICATION_WINDOW_DAYS)
#        · 붙는 쪽의 **is_deleted = false** (repair_cases · quotes · domestic_orders)
#        · **INNER JOIN** — repair_case_id·quote_id·domestic_order_id 가 NULL 인
#          행이 여기서 떨어진다(갈래를 가르는 것도 이 조인이다)
#        · **ne(decided_by_user_id, 보는 사람)** — 자기가 결재한 건은 자기 종에 안 뜬다
#        · **최종 승인만**(승인 쪽만) — 같은 묶음에 requested_at 이 더 늦은 행이
#          없다(NOT EXISTS). 묶음은 접수 건이면 (건, 결재 종류) · 견적서면 그 한 장 ·
#          기타건이면 그 내자 줄. 🔵 **반려는 이 조건이 없다**(어느 단계에서든 알린다).
#   🔴 **흉내 내지 못한 것 둘** — 그래서 ④ 는 **하한도 상한도 아닌 어림수**다:
#        · 이미 **눌러 확인한 줄**은 빠진다(withoutAcknowledged) — DB 로는 사람마다
#          달라서 여기서 안 뺀다.
#        · 알림 설정 스위치(⑦)가 꺼져 있으면 그 역할은 한 줄도 못 받는다.
#   🔴 **전부 select 뿐이다.** 🔴 **올리기 전후로 같아야** 정상이다 — 이 배포는
#      자료를 한 줄도 안 건드린다. 달라졌다면 **그 사이에 결재가 났거나 사람이
#      저장한 것**이다 — 🔵 ②③④⑥ 의 **7일 창은 시간이 가면 저절로 움직인다.**
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v55-$STAMP
BKDB=$D/backups/db   # 🔴 덤프가 여기 간다 (48·52·53·55·57·58번과 같은 자리·같은 이름 규칙)

# ══ 이번에 다시 띄우는 것 — 앱 **하나** ═══════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
#   🔵 58번과 같은 모양이다 — 앱 하나, 도구 하나.
#   🔵 **판이 5.0 → 5.1 로 그냥 하나 는다** (58번의 「4.10 이 아니라 5.0」은 그 판의
#      사정이라 이 파일에는 그 경고가 없다 — 머리말).
SITES='
as|app-as|dss-as|dss-as:5.1|dss-as:5.0|dss-as-5.1.tar|13000
'
SITES_WANT=1
# 🔵 7절의 재고 관리·발주서·양식 검사가 명령을 넣을 상자. 위 표 셋째 칸과 같은 이름이다.
AS_APP_CN=dss-as
# 🔵 포털 앱 — **안 건드린다.** 그래도 「그대로 도는가」는 본다(로그인이 걸려 있다).
AUTH_APP_CN=dss-auth
AUTH_PORT=13100
AUTH_WANT_TAG=dss-auth:2.1
# 🔴 PO 권한 검사가 명령을 넣을 상자. **이번에도 안 갈아 끼우지만 잰다.**
PO_APP_CN=dss-po
PO_PORT=13600
PO_WANT_TAG=dss-po:0.9

# ══ 🔴 도구 — **A/S 것 하나만 갈아 끼운다.** up -d 로 다시 띄우지 않는다 ══
#   🔵 profiles: [tools] 라 평소에 뜨지 않는다. 도는 컨테이너는 compose 를
#      읽지 않으므로 이 한 줄을 고쳐도 **직원이 느끼는 것이 없다.**
#   🔴 55번은 --migrate 가 이 줄을 먼저 고쳤다. **이 판에도 --migrate 가 없어
#      --go 가 둘을 함께 고친다** — 그래서 PRE 에서 달라지는 줄이 **둘**이다.
AS_TOOLS_SVC=tools-as
AS_TOOLS_OLD=dss-as-tools:17
AS_TOOLS_NEW=dss-as-tools:18
# 🔵 포털 도구 — **안 건드린다.** 53번이 올린 :4 그대로여야 한다(⚠️ 로만 센다).
AUTH_TOOLS_SVC=tools-auth
AUTH_TOOLS_KEEP=dss-auth-tools:4
IMG_MIGDIR=/app/drizzle
MIGDIR=$D/as-migrations

# ══ 🔴 양식 — **이번 판에도 올릴 것이 없다. 재기만 한다** ═════════════
#   🔵 운영 자리: compose 의 app-as·app-po 가 둘 다
#      '/volume1/dss/as-templates:/templates:ro' 로 붙인다.
#   🔴 **tools-as 에는 그 볼륨이 없다.** 그래서 양식은 **호스트에서 바로** 재고,
#      「앱이 보는가」는 app-as 안에서 따로 묻는다.
TPLDIR=$D/as-templates
TPL_IN_CONTAINER=/templates

# 🔴 열하나 — 이름|바이트|md5. 출처: [실측] **2026-11-11 개발 PC**.
#    🔴 **이번 판에서 다시 잰 값이 아니다.** 58-build.sh 가 2026-11-11 에 재서
#       55·57번이 적어 둔 값과 11/11 「같다」였고, 그 값을 그대로 물려받았다.
#       🔵 59-build.sh 의 8절이 굽기 전에 한 번 더 잰다 — 거기서 다르다고 나오면
#          **이 표가 아니라 그 출력**이 새 사실이다.
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

# ══ 🔵 발주서 공유폴더 — **이번 판은 안 건드린다. 그래도 잰다** ═══════
#   🔵 **이 배포는 디스크를 아예 안 본다** — 그래서 핵심 자리가 아니다.
#   🔴 그래도 **빼지 않는다** — 한 번 빼면 다시 넣는 사람이 없다. ✗ 가 나면
#      **지난 판이 올린 기능이 지금 고장나 있다**는 뜻이고, 되돌려도 안 고쳐진다.
#   🔴 **기대값을 박지 않는다** — 0 이면 ✗(볼륨 줄은 있는데 안 열린다),
#      1 이상이면 수를 찍고 ✓ 다.
PO_ARCHIVE=/purchase-order-archive

# ══ 🔵 견적서 공유폴더 — 이번 판이 안 건드린다. 그래도 잰다 ═══════════
#   🔴 **빼지 않는다** — 한 번 빼면 다시 넣는 사람이 없다(42~58번의 규율).
QUOTE_ARCHIVE_ENV=QUOTE_ARCHIVE_DIR

# ══ 🔴 설정 파일 — .env 쪽과 env/*.env 쪽을 **둘 다** 본다 ════════════
ENV_NAS=$D/deploy/.env.nas
ENV_AS=$D/deploy/env/as.env
ENV_AUTH=$D/deploy/env/auth.env
ENV_PO=$D/deploy/env/po.env

# ══ 🔴 tar 둘의 지문 — [배포본] 59-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   ✅ **채워 넣었다 (2026-11-12 09:4x · 구운 쪽인 개발 PC 에서 잰 값).**
#      59-build.sh --go 가 꼬리말에 찍은 두 줄을 **그대로** 옮겼고, 옮긴 뒤
#      _images-55 의 두 tar 를 **md5sum 으로 다시 재어** 같은지 확인했다.
#      🔵 --go 의 출력에서 「지문이 빌드 로그와 같다」가 둘 다 ✓ 였다 —
#         tar 안 manifest 의 Config 지문과 빌드 로그의 exporting config 가 맞았다.
#      🔵 --go 는 그 두 줄을 **세 자리**에서 찍는다(실패로 나갈 때 · 표 자리 ·
#         꼬리말 맨 끝의 🔴🔴🔴). 출력이 잘려도 마지막 몇 줄은 남기 때문이다.
#   🔴 **이 값을 NAS 에서 재서 채우지 마라.** 그러면 「옮기다 깨졌는가」를 자기가 잰
#      값으로 자기를 재는 꼴이 되어 **영영 통과한다.** 반드시 **구운 쪽**에서 잰다.
#      (바이트는 stat · md5 는 md5sum · Config 지문은 tar 안 manifest.json —
#       59-build.sh 의 tar_config_id 와 같은 방식이다.)
#   🔴 비어 있으면 3절이 **--check·--rollback 에서는 ? · --preload·--go 에서는 ✗**
#      로 센다. 🔵 막는 것은 **✗ 뿐이다** — ? 는 아무것도 안 막는다.
#      🔴 **두 번 연속으로 지문 줄을 못 받았다** — 쉰세째는 --go 의 출력을 잘라서,
#         쉰네째는 굽기가 「실패 1」로 끝나 꼬리말까지 못 가서(그때는 구운 쪽인
#         개발 PC 의 _images-54 에서 다시 재어 채웠다).
#         🔴 **쉰세째에는 빈 표가 그대로 NAS 로 올라갔고 --preload 가 ✗ 둘로
#            멈췄다**(2026-11-11). 막아야 할 자리를 제대로 막았다.
#   🔵 **셋째 줄(묶음)은 없다** — 이번 판도 마이그레이션이 0건이다.
TARS='
dss-as-5.1.tar|134702592|5573db671cce69933dc51351a3bcd3df|sha256:2a12c0600bcddb53ddb9a385652920361493a5b16c54ecc6a1b6e6eb3efb5c55
dss-as-tools-18.tar|225390592|9a2fb6d719c40e6a157a04001bd1f9af|sha256:1ca7171d2c3ca37d30a69a2b607f96a8aadf1851ef98db25cbd9fe9140187c68
'
TARS_WANT=2

# 🔴 tar 이름 → 태그. **정규식으로 되돌리지 않는다** — 이름마다 손으로 적는다.
#    dss-as-tools-17 을 「끝의 숫자 앞에 콜론」 규칙으로 풀면 맞지만, 규칙이
#    맞는지 사람이 눈으로 확인할 수 없는 자리에 두지 않는다(39번의 그 주석).
#    🔴 **dss-as-5.1.tar 은 그 규칙으로 풀리지도 않는다** — 판에 점이 있다.
tar2tag() {
  case "$1" in
    dss-as-5.1.tar)        printf 'dss-as:5.1' ;;
    dss-as-tools-18.tar)   printf 'dss-as-tools:18' ;;
  esac
}

# ══ 🔴 DB — **이번 판은 앞뒤가 같은 수다** (55번과 반대) ══════════════
#   🔵 A/S 와 PO 는 **같은 dss_as** 를 본다(PO 는 제 DB 가 없다).
#   🔵 포털은 **dss_auth** 를 따로 본다 — 이번 판에 **한 글자도 안 바꾼다.**
AS_BOX=dss-pg-app;    AS_DB=dss_as
AUTH_BOX=dss-pg-auth; AUTH_DB=dss_auth
# 🔴 **한 갈래다.** 55번은 「125 → 127 두 갈래」였다 — 그 글을 베껴 PHASE 로
#    가르면 **어느 가지로 가도 127** 이라 아무것도 안 재게 된다.
AS_MIG_KEEP=127     # [저장소·운영] 55번이 0125·0126 을 올려 127 이 됐고 그 뒤 판들은 안 건드렸다
AUTH_MIG_KEEP=10    # [README 36번] 포털은 그대로여야 한다
AS_LAST_MIG=0126
AS_NEXT_MIG=0127    # 🔴 셈으로 만들지 않는다(8진수 함정). 글자로 적는다
AS_KEEP_MIGS='0121 0122 0123 0124 0125 0126'
# 🔴 **이번 판이 올리는 마이그레이션은 0건이다.** 적용 대기도 0건이어야 한다.
AS_PENDING_WANT=0

# ══ 🔴 0124~0126 이 만든 열 — **어느 단계에서나 다 있어야 한다** ══════
#   🔵 55번은 0125·0126 쪽을 「--migrate 전에는 없고 뒤에는 있다」는 **두 갈래**로
#      두었다. 🔴 **이 판은 이미 올라가 있으므로 한 갈래다** — 전부 있어야 한다.
#   🔴 하나라도 없으면 **지금 운영이 반만 적용된 상태**라는 뜻이고, 그때는 이
#      배포가 아니라 그것부터 봐야 한다.
AS_COL_TABLE=repair_case_approvals
AS_COL=domestic_order_id
AS_IDX1=repair_case_approvals_one_active_domestic_request
AS_IDX2=repair_case_approvals_domestic_order_id_idx
AS_FK=repair_case_approvals_domestic_order_id_domestic_orders_id_fk
AS_CK1=repair_case_approvals_domestic_order_only_for_domestic_type
AS_CK2=repair_case_approvals_domestic_type_has_no_repair_case
AS_CK3=repair_case_approvals_delegation_only_for_final_shipment
AS_CK4=repair_case_approvals_route_only_for_final_shipment
AS_ENUM1=repair_case_approval_type
AS_ENUM2=shipment_approval_route_scope
AS_ENUM_VALUE=DOMESTIC_ORDER_FINAL_SHIPMENT
# 🔴 55번(0125·0126)이 만든 열 — **이번 판에서는 전부 있어야 한다.**
NEW_COL_T1=domestic_order_due_dates
NEW_COL_1=delivered_date
NEW_COL_2=delivered_by
NEW_COL_3=completed_at
NEW_COL_4=completed_by
NEW_COL_T2=repair_case_approvals
NEW_COL_5=due_date_row_order
NEW_CK1=repair_case_approvals_due_date_row_only_for_domestic_type
NEW_CK2=repair_case_approvals_domestic_type_has_due_date_row
NEW_CK3=domestic_order_due_dates_completed_columns_together
NEW_FK=domestic_order_due_dates_completed_by_users_id_fk
# 🔴 0126 이 다시 만든 유니크 인덱스 — **칸이 셋이다.** 「있는가」로는 0124 판과
#    못 가른다(이름이 같다). 🔵 이번 판은 **언제나 3** 이다(55번은 2 또는 3 이었다).
NEW_IDX=repair_case_approvals_one_active_domestic_request
NEW_IDX_COLS_WANT=3
# 🔵 48번이 올린 것 — **아직 있어야 한다.** 52~55번에서 그대로 가져왔다.
AS_OLD_TABLE=procedure_case_execution_edges
AS_OLD_COL_TABLE=procedure_template_nodes
AS_OLD_COL=next_procedure_template_id
AS_OLD_INDEX=procedure_template_nodes_next_template_idx
# 🔴 줄 수가 그대로여야 하는 표 — 이 배포는 **자료를 한 줄도 안 건드린다**.
AS_COUNT_TABLES='repair_cases domestic_orders repair_case_approvals shipment_approval_routes procedure_templates users'
# 🔴 49번이 올린 기능이 쓰는 표. 1-ㄹ 절이 이 이름으로 권한을 묻는다. **ASCII 다.**
PO_WRITE_TABLE=repair_cases

# ══ 🔵 **안 건드리는 아홉** — 「옆으로 안 샜다」는 증거로 센다 ═════════
KEEP_BOXES="dss-auth dss-inventory dss-meters dss-board dss-improvements dss-leave dss-approvals dss-rf-trouble dss-po"
KEEP_BOXES_WANT=9
# 🔵 DB 둘은 멈추지 않는다 (애초에 up -d --no-deps 가 app-as 하나만 건드린다)
KEEP_DB="dss-pg-app dss-pg-auth"

# ══ 🔴 53번 꼬리말에서 넘어온 할 일 둘을 **값으로** 센다 ══════════════
AS_ROUTE_TABLE=shipment_approval_routes
AUTH_MAIL_TABLE=approval_mail_kinds
AUTH_MAIL_CLIENT=rf-service-system

# ══ 🔴 **이번 판이 바꾼 10개** — 도구 이미지 안 검사가 쓴다 ═══════════
#   🔵 src/ **10** + scripts/ **0**. 🔴 58번은 src/ 18 · scripts/ 2 였다 —
#      그 수를 그대로 두면 **멀쩡한 판이 ✗** 다.
#   🔵 **열 장이 전부 src/lib/ 아래다**(서버 쪽이다). 괄호·대괄호가 든 경로가 하나도
#      없지만, **환경변수로 넘기고 while read 로 받는** 방식은 그대로 둔다(머리말).
AS_CHANGED_SRC='
src/lib/db/queries/approval-outcome-notifications.integration.test.ts
src/lib/db/queries/approval-outcome-notifications.ts
src/lib/db/queries/domestic-order-approvals-pending.integration.test.ts
src/lib/db/queries/notification-settings.integration.test.ts
src/lib/db/queries/notifications.ts
src/lib/db/queries/quote-approvals-notifications.integration.test.ts
src/lib/domain/notification-settings.test.ts
src/lib/domain/notification-settings.ts
src/lib/domain/notifications.test.ts
src/lib/domain/notifications.ts
'
AS_CHANGED_SRC_WANT=10
# 🔴 **scripts/ 쪽은 0개다.** 58번은 둘(test-lists)이었다.
#    🔴 **「0 이니 안 센다」로 만들지 않았다** — 도구 이미지 안 검사의 ③-ㅁ 이 ① 세는 길이 살아 있는지
#       가짜 목록으로 보고 ② 이 파일의 목록이 정말 0줄인지 본다. **1 이상이면 ✗** 다.
AS_CHANGED_SCRIPTS=''
AS_CHANGED_SCRIPTS_WANT=0
AS_CHANGED_ALL_WANT=10
# 🔴 **이번에 새로 생긴 파일은 0개다** — 58번은 7개였고 그 파일은 「일곱이 그 일곱
#    인가」를 재고 있었다. 🔴 그 절을 그대로 두면 0/7 로 **멀쩡한 판이 ✗** 다.
#    🔵 대신 **열 장이 전부 새 내용인가**를 아래 FRESH_MARK 로 덮는다.
AS_BORN_SRC_WANT=0
# 🔴 **이번 판이 고친 시험 여섯** — 이미 목록 파일에 등록돼 있어야 한다.
#    🔴 58번은 여기가 「**새** 시험 다섯이 등록됐는가」였다. 이번 판에는 새 시험이
#       한 장도 없어 그 다섯 경로를 그대로 두면 다섯 다 no 가 나와 **가짜 ✗** 다.
#    🔵 [실측 2026-11-12] 통합 넷은 scripts/test-lists/**db.txt** · 단위 둘은
#       **unit.txt** 에 **줄 전체로** 적혀 있다(개발 PC 에서 grep -lFx 로 한 장씩
#       확인했고, 여섯 다 1줄씩 잡혔다).
AS_TOUCHED_TESTS='
src/lib/db/queries/approval-outcome-notifications.integration.test.ts
src/lib/db/queries/domestic-order-approvals-pending.integration.test.ts
src/lib/db/queries/notification-settings.integration.test.ts
src/lib/db/queries/quote-approvals-notifications.integration.test.ts
src/lib/domain/notification-settings.test.ts
src/lib/domain/notifications.test.ts
'
AS_TOUCHED_TESTS_WANT=6
# 🔴 **「무조건 yes」인 검사가 되지 않게** 없는 경로 하나를 함께 묻는다.
REG_PROBE_MISS=src/__dss_probe_not_registered__.test.ts
# 🔴 목록 파일을 **얼마나 읽었나**의 바닥값. [실측 2026-11-12] 개발 PC 에서 네 장을
#    합쳐 **3620줄**이었다(components 1322 · unit 1938 · db 529 · db-safety 15,
#    빈 줄 뺀 수). 🔵 목록은 늘기만 하므로 바닥값을 낮게 잡는다 — 여기서 걸리면
#    「줄었다」가 아니라 **아예 못 읽었다**는 뜻이다.
AS_TESTLIST_MIN_LINES=1000
# 🔵 **이번 판이 안 바꾸지만 이미지 안에는 있어야 하는 것** — 시험 목록 파일 넷.
#    🔴 「이번 범위에서 **바뀐** 파일」을 세는 자리와 섞지 마라. 이 넷은 58번이
#       고쳐 올린 것이고, 이번 판은 한 줄도 안 건드린다. 그래도 **도구 이미지 안에
#       들어 있어야** 위 시험 등록 검사가 설 수 있다(tools 스테이지가 scripts/ 를
#       통째로 담는다 — Dockerfile 68줄).
AS_TESTLIST_FILES='
scripts/test-lists/components.txt
scripts/test-lists/db.txt
scripts/test-lists/db-safety.txt
scripts/test-lists/unit.txt
'
AS_TESTLIST_FILES_WANT=4
# ══ 🔴 **이번 판의 표식 여섯** — 도구 이미지(소스가 글자 그대로 있다)에서 쓴다 ══
#   🔴 58번의 다섯(status=IN_HOUSE · IN_HOUSE_STATUSES · isShortcutActive ·
#      BillingTypeFilterValue · customerNames)은 **이번 판이 하나도 안 건드린다** —
#      그대로 두면 **옛 판에서도 전부 ✓** 인 죽은 검사가 된다.
#   🔴 아래 여섯은 전부 **기준판(242f0f69)의 그 파일에 0번 · 지금 판에 1번 이상**이다
#      (2026-11-12 실측: 2 · 3 · 7 · 3 · 3 · 2).
#   🔵 **커밋이 하나뿐이라 「마지막 커밋을 가른다」는 고민이 없다** — 하나라도 있으면
#      그 커밋이 담겼다는 뜻이다. 그래도 여섯을 세는 까닭은 **한 자리만 보면 그
#      파일만 담긴 판**(여섯이 덮는 다섯 장 중 하나만 옛 것인 이미지)을 못 가르기 때문이다.
#   🔵 여섯이 덮는 파일은 다섯 장이고, 나머지 다섯 장은 아래 FRESH_MARK 가 덮는다.
#   형식: 글자|파일 — 🔴 **전부 ASCII** 라 argv 로 넘겨도 안 깨진다.
AS_MARKS='
APPROVAL_GRANTED_BROAD_RECIPIENT_ROLES|src/lib/domain/notifications.ts
receivesOthersApprovalGrantedOutcomes|src/lib/db/queries/approval-outcome-notifications.ts
includeOtherRequesters|src/lib/db/queries/approval-outcome-notifications.ts
2026-11-12|src/lib/db/queries/notifications.ts
2026-11-12|src/lib/domain/notification-settings.ts
APPROVAL_GRANTED_BROAD_RECIPIENT_ROLES|src/lib/domain/notifications.test.ts
'
AS_MARKS_WANT=6
AS_HEAD_SHORT=1259d822
AS_BASE_SHORT=242f0f69
# 🔴 **바뀐 열 장이 전부 새 내용인가** — 「파일이 있다」와 다른 말이다.
#    🔵 [실측 2026-11-12] 이 날짜 글자가 **열 장 전부에 1번 이상**(1~7번) 있고,
#       기준판 242f0f69 의 src/ 전체에는 **0파일**이다. 그래서 한 글자로 열 장을 덮는다.
FRESH_MARK=2026-11-12
# ══ 🔴 **앱 번들에서 쓸 표식** — 🔴 상수·함수 이름으로 재지 않는다 ════════
#   🔴 앱 이미지는 도구와 달리 **번들**이다(소스가 없다). minify 를 거치므로
#      APPROVAL_GRANTED_BROAD_RECIPIENT_ROLES 같은 **이름이 남는다는 보증이 없다** —
#      그 이름으로 재면 **멀쩡한 이미지가 ✗** 가 된다. 58번이 status=IN_HOUSE 를
#      고른 까닭도 「**href 에 들어가는 리터럴**이라 이름이 안 바뀐다」였다.
#   🔵 그래서 **화면에 나가는 문자열**로 잰다 — 알림 설정 화면의 **새 설명 글자**다
#      (「…요청한 사람 본인과 영업·관리자·최고관리자에게 가고(2026-11-12), …」).
#      설명은 주석이 아니라 문자열 리터럴이라 번들러가 못 바꾼다. 🔵 같은 번들의
#      같은 자리에 「반려됨」의 설명 글자가 글자 그대로 들어 있는 것으로 확인했다.
#   🔵 [실측 2026-11-12] 개발 PC 의 .next/standalone(이 커밋의 나무로 구워졌다)에서
#      .next/server **4파일** · .next/static **1파일**.
#   🔴 **도커가 구운 번들에서 센 것은 아니다** — ✗ 가 나면 검사부터 의심한다.
APP_MARK=2026-11-12
# 🔴 앱 번들에서 ✗ 로 세는 **한글** 표식 — 같은 설명 글자의 한가운데다.
#    🔴 **명령에 한글을 넣지 않는다.** 컨테이너 안에서 **8진 이스케이프로 다시
#       만들어** 쓴다. 만들기가 틀리면 0 이 나와 「없다」로 읽히므로 **바이트 수(47)를
#       먼저 받아** 가르고, 47 이 아니면 ✗ 가 아니라 ⚠️ 다(이미지가 틀린 것이 아니라
#       컨테이너 안에서 글자를 못 만든 것이다).
#    🔵 [실측 2026-11-12] 이 이스케이프가 47바이트 · 번들의 server 4파일 · static 1파일 ·
#       지금 src/ 에 1파일 · 기준판 src/ 에 0파일.
APP_MARK_KO_OCT='\354\230\201\354\227\205\302\267\352\264\200\353\246\254\354\236\220\302\267\354\265\234\352\263\240\352\264\200\353\246\254\354\236\220\354\227\220\352\262\214 \352\260\200\352\263\240'
APP_MARK_KO_BYTES=47
# 🔵 **뒷걸음 방지 둘** — 🔴 **이번 판이 만든 글자가 아니다.** 「더 옛날 나무를
#    실었나」를 가르는 자리라 **이번 판에도 있어야 참**이다.
#      · status=IN_HOUSE   — **쉰네째(58번)**가 올린 글자. [실측] server 1 · static 1
#      · no-equipment-key  — **쉰세째**가 올린 글자.       [실측] server 4 · static 2
#    🔴 58번에는 이 자리가 **하나**뿐이었다(그때는 쉰세째 것만 지키면 됐다).
#       **하나도 빼지 마라** — 뺀 자리는 다시 넣는 사람이 없다.
APP_KEEP_MARKS='
status=IN_HOUSE
no-equipment-key
'
APP_KEEP_MARKS_WANT=2

MODE=check
case "${1:-}" in
  --check|"")   MODE=check ;;
  --count)      MODE=count ;;
  --preload)    MODE=preload ;;
  --go)         MODE=go ;;
  --rollback)   MODE=rollback ;;
  --migrate)
    printf '🔴 **이 판에는 --migrate 가 없습니다.**\n'
    printf '   까닭: 이번 배포는 마이그레이션이 **0건**이고 묶음도 안 보냅니다.\n'
    printf '         (기준 %s 이후 drizzle/ 변경 0개 · 저장소도 볼륨도 %s)\n' "$AS_BASE_SHORT" "$AS_MIG_KEEP"
    printf '   🔵 「올릴 것이 정말 0건인가」는 --check 의 2-ㄹ 절이 **값으로** 잽니다 —\n'
    printf '      볼륨 .sql %s · idx %s · DB 기록 %s · 적용 대기 %s건 · db:preflight 종료 코드 0.\n' "$AS_MIG_KEEP" "$AS_MIG_KEEP" "$AS_MIG_KEEP" "$AS_PENDING_WANT"
    printf '   🔴 마이그레이션이 있는 판을 올리실 때 되살릴 곳: 55-deploy.sh 의\n'
    printf '      place_migs() · check_keep_migs() · 4-ㄴ 절(1956~2258줄).\n'
    printf '   🔵 지금 치실 것: bash %s --check\n' "$0"
    exit 2 ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --count · --preload · --go · --rollback\n   🔵 --migrate 는 이 판에 **없습니다**(마이그레이션 0건).\n' "$1"; exit 2 ;;
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
LOG="$D/setup/logs/59-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "쉰다섯째 배포 (파일 번호 59) — A/S 앱·도구 (양식 0장 · **마이그레이션 0건** · 포털·PO 안 건드림)   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  🔵 회차(쉰다섯째)와 파일 번호(59)가 어긋나는 것은 이 저장소에서 원래 그렇다 — 55번이 쉰두째 · 57번이 쉰세째 · 58번이 쉰네째였다."
printf '%s\n' "  🔵 판은 **5.0 → 5.1** 로 하나 늡니다. 도구는 17 → 18."
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  🔴 개발 PC 의 Get-FileHash 값과 **같은지 눈으로 맞대세요** (DSM 터미널이 긴 것을 잘라 먹습니다)"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  로그: $LOG"
printf '%s\n' "  🔴 차례: --check → --count → (scp tar **둘**) → --preload → --check → --go → --count"
printf '%s\n' "  🔵 **DB 를 한 글자도 안 바꿉니다** — 마이그레이션 기록이 앞뒤 모두 $AS_MIG_KEEP 입니다."
printf '%s\n' "     🔴 **--migrate 모드가 없습니다.** 치면 까닭을 찍고 거절합니다."
printf '%s\n' "     🔵 묶음(as-migrations.tar.gz)도 **안 보냅니다.**"
printf '%s\n' "  🔵 포털·PO 는 **안 건드립니다** — 7절이 「그대로 도는가」만 봅니다"
printf '%s\n' "  🔴 이번 판이 고치는 것은 **「승인 완료」 종 알림의 받는 사람**입니다 — 커밋 **하나**이고"
printf '%s\n' "     바뀐 열 장이 **전부 src/lib/ 아래**(서버 쪽)입니다."
printf '%s\n' "     🔵 영업·관리자·최고관리자가 **남이 올린 결재의 승인 완료**도 받게 됩니다."
printf '%s\n' "     🔴 **「반려됨」은 안 바뀝니다** — 요청자 본인뿐입니다(일부러 그렇게 뒀습니다)."
printf '%s\n' "     🔵 공유폴더·디스크는 **아예 안 봅니다** — 1-ㅁ 절은 지난 판이 올린 기능이"
printf '%s\n' "        지금도 멀쩡한지 보는 자리입니다(빼지 않습니다)."
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

# 🔴 운영 DB 를 **앱이 쓰는 길**(컨테이너 안 psql)로 잰다. 소켓·루프백으로 재면
#    trust 라 그냥 통과한다. 보내는 SQL 은 select 뿐이다.
#    🔴 **SQL 에 큰따옴표를 쓰지 않는다** — 이 문자열이 큰따옴표 안에 들어간다.
pgq() { # 1 상자 2 DB 3 SQL
  "$DOCKER" exec -i "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -X -tAq -c \"$3\"" 2>/dev/null | head -1 | tr -d ' \r'
}
pgn() { local v; v=$(pgq "$1" "$2" "$3"); isnum "$v" && printf '%s' "$v"; }
mig_count() { pgn "$1" "$2" 'select count(*) from drizzle.__drizzle_migrations'; }
# ══ 🔴 마이그레이션 헬퍼 — 53·55번 것을 그대로 가져왔다 ═══════════════
has_table()  { pgn "$1" "$2" "select count(*) from information_schema.tables where table_schema='public' and table_name='$3'"; }
has_column() { pgn "$1" "$2" "select count(*) from information_schema.columns where table_schema='public' and table_name='$3' and column_name='$4'"; }
has_index()  { pgn "$1" "$2" "select count(*) from pg_indexes where schemaname='public' and indexname='$3'"; }
# 🔴 제약은 pg_indexes 에 없다 — pg_constraint 로 묻는다. CHECK 도 외래키도 여기 있다.
has_constraint() { pgn "$1" "$2" "select count(*) from pg_constraint where conname='$3'"; }
# 🔴 enum 값은 표도 칸도 아니다 — pg_enum 으로 묻는다.
has_enum_value() { pgn "$1" "$2" "select count(*) from pg_enum e join pg_type t on t.oid=e.enumtypid where t.typname='$3' and e.enumlabel='$4'"; }
# 🔴 **인덱스의 칸 수.** 0126 이 0124 의 유니크 인덱스를 **같은 이름으로** 다시
#    만들었다 — 칸만 둘에서 셋이 됐다. 「있는가」로는 못 가르고 **칸 수**로 가른다.
#    🔵 이번 판은 **언제나 3** 이다(55번은 적용 전 2 · 뒤 3 이었다).
index_cols() { pgn "$1" "$2" "select coalesce(max(i.indnkeyatts),0) from pg_index i join pg_class c on c.oid=i.indexrelid where c.relname='$3'"; }

# 🔴 **볼륨**을 읽는다 — 마이그레이션은 이미지 안이 아니라 여기서 돈다.
#    🔵 이번 판은 가지가 둘뿐이다: DONE(127) · ODD(그 밖). 🔴 55번은 셋이었다
#       (OLD=125 가 뜻을 가졌다) — 이 판에는 묶음이 없어 OLD 를 고칠 길이 없다.
read_migdir() {
  MIG_N_SQL=0; MIG_N_J=0; MIG_STATE=""
  [ -d "$MIGDIR" ] || { MIG_STATE=NODIR; return 0; }
  MIG_N_SQL=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  if [ -f "$MIGDIR/meta/_journal.json" ]; then
    MIG_N_J=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  fi
  MIG_N_SQL=${MIG_N_SQL:-0}; MIG_N_J=${MIG_N_J:-0}
  if [ "$MIG_N_SQL" = "$AS_MIG_KEEP" ] && [ "$MIG_N_J" = "$AS_MIG_KEEP" ]; then MIG_STATE=DONE
  else MIG_STATE=ODD
  fi
  return 0
}

# ══ 🔴 덤프 — **DB 를 안 바꿔도 뜬다** ════════════════════════════════
#   🔵 52·55번과 같은 판단이다 — 「안 바꾸지만 그 시각의 사진으로 남긴다」.
#      되돌릴 일이 생기면 **갈아 끼우기 직전의 상태**가 필요하다.
#   🔵 **포털 DB 는 안 뜬다** — 이 배포가 dss_auth 를 한 글자도 안 바꾸고
#      야간 백업(nas/jobs/backup-nightly.sh 80줄)이 매일 dss_auth 를 받는다.
#   🔴 「파일이 생겼다」와 「쓸 만한 덤프다」는 다르다. 크기와 머리 다섯 글자를 본다.
DUMP=""
make_dump() { # 1 왜 뜨는지 한 줄
  printf '\n    ── 덤프를 뜬다 (%s)\n' "$1"
  mkdir -p "$BKDB" 2>/dev/null
  DUMP="$BKDB/dss_as-v54-$STAMP.dump"
  if "$DOCKER" exec -i "$AS_BOX" sh -c 'pg_dump -U "$POSTGRES_USER" -d dss_as -Fc' > "$DUMP" 2>/dev/null; then
    local dsz magic
    dsz=$(stat -c %s "$DUMP" 2>/dev/null || wc -c < "$DUMP")
    say "덤프 $DUMP (${dsz:-?}바이트)"
    if [ "${dsz:-0}" -gt 10240 ]; then ok "덤프가 ${dsz}바이트다 (10KB 넘음)"
    else bad "덤프가 ${dsz:-0}바이트뿐이다 — 쓸 수 없다"; fi
    # 🔴 **속을 본다.** -Fc 덤프는 첫 다섯 글자가 PGDMP 다.
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
  say "🔵 **이번 판은 DB 를 안 바꾸므로 되돌릴 일이 거의 없다** — 그래도 남긴다."
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
    say "   🔵 2026-11-11 의 56-stage.sh · 56-templates.sh 도 양식만 올리는 짝이다."
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
#       A/S 교체를 막을 일이 아니다. 🔴 다만 **못 쓴다고 나오면 ✗** 다.
po_write_privilege_check() { # 1 warnmiss|soft
  local level out line who db upd sel pl pu ps
  level=${1:-warnmiss}
  printf '\n    ── 🔴 PO 가 %s 에 **쓸 수 있는가** (49번이 올린 기능 · 이번에도 안 갈아 끼우지만 잰다)\n' "$PO_WRITE_TABLE"
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

# ══ 🔴 재고 관리 통로가 **값을 돌려주는가** (45~55번 것을 글자 그대로) ══
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

# ══ 🔴 A/S 도구 이미지 안을 센다 — 겉이 아니라 결과 ═══════════════════
#   🔴 이 도구는 평소에 안 뜬다. 안이 모자라도 **그날 아무 일이 안 일어나고**,
#      드러나는 것은 **쓸 일이 생긴 날**의 한 줄뿐이다.
#   🔴 **「✗ 가 아니면 ✓」로 세지 않는다.** ✓ 조건만 정확히 적고 나머지는 ? 다.
#
#   🔴 **이번 판을 실제로 재는 것은 셋이다**: 바뀐 **10개**가 담겼는가 ·
#      그 열 장이 **전부 새 내용**인가(날짜 글자) · 이번 판의 **표식 여섯**이 있는가.
#      🔴 58번의 표식 다섯(status=IN_HOUSE 따위)은 **이번 판이 하나도 안 건드린다** —
#         그대로 두면 옛 판에서도 ✓ 인 죽은 검사다. 전부 갈았다.
as_tools_inside_check() {
  local v got seen c nmiss nwrite ntx nok probe lines nscr
  printf '\n    ── %s 안을 센다 (겉이 아니라 결과 · 🔵 소스가 **글자 그대로** 있다)\n' "$AS_TOOLS_NEW"
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/package.json: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "A/S tools 스테이지가 맞다" \
    || { bad "🔴 /app/package.json 이 없다 — **runner 를 구웠다.**"; doubt; }
  # ② 🔴 운영에서 불릴 npm 명령 **아홉**(41번의 자리).
  #    🔵 **이번 판에도 새 명령이 없다** — 아홉이 :17 에도 :18 에도 있어야 한다.
  #    🔵 [실측 2026-11-12] package.json 의 scripts 항목이 39 → 39 로 안 늘었다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync check-due-date-overdue check-delivered-date-sync procedures:export procedures:import db:preflight db:migrate; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "9" ] && ok "npm 명령 아홉이 이미지 안에 있다 (Missing script 가 안 난다)" \
    || { bad "🔴 명령이 ${got:-0}/9 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다**"; doubt; }
  # ③ 🔴 **이번 판이 바꾼 10개가 담겼는가.**
  #    🔴 **58번은 20개였다**(src/ 18 + scripts/ 2). 이번 판은 **src/ 10 + scripts/ 0**
  #       이라 그 수를 그대로 두면 **멀쩡한 판이 ✗** 다.
  #    🔵 경로에 괄호·대괄호가 없다. 그래도 **환경변수로 넘겨 while read 로 받는**
  #       방식은 그대로 둔다(다음 판을 위해서다).
  v=$("$DOCKER" run --rm -e DSS_FILES="$AS_CHANGED_SRC$AS_CHANGED_SCRIPTS" --entrypoint sh "$AS_TOOLS_NEW" -c 'printf "%s\n" "$DSS_FILES" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  seen=$(printf '%s\n' "$v" | grep -cE '^(yes|no ) ' || true)
  say "본 것 ${seen:-0}개 · 있는 것 ${got:-0}개 (기대 $AS_CHANGED_ALL_WANT · $AS_CHANGED_ALL_WANT — src/ $AS_CHANGED_SRC_WANT + scripts/ $AS_CHANGED_SCRIPTS_WANT)"
  if [ "${seen:-0}" = "$AS_CHANGED_ALL_WANT" ] && [ "${got:-0}" = "$AS_CHANGED_ALL_WANT" ]; then
    ok "이번 판이 바꾼 $AS_CHANGED_ALL_WANT 개가 다 담겼다 (**표본이 비지 않았다**)"
  else
    bad "🔴 본 것 ${seen:-0} · 있는 것 ${got:-0} 다 — ${AS_CHANGED_ALL_WANT}/${AS_CHANGED_ALL_WANT} 을 기대했다"
    say "🔴 본 것이 ${AS_CHANGED_ALL_WANT} 가 아니면 목록을 넘기는 길이 끊긴 것이고,"
    say "   있는 것만 모자라면 **옛 소스가 담긴 이미지**입니다."
    doubt
  fi
  # ③-ㄴ 🔴 **그 열 장이 전부 새 내용인가** — 58번은 여기서 「새로 생긴 일곱」을
  #    세었다. 🔴 **이번 판은 새 파일이 0장**이라 그 절을 그대로 두면 0/7 로
  #    **멀쩡한 판이 ✗** 다. 그래서 **날짜 글자로 열 장을 덮는다.**
  #    🔵 [실측 2026-11-12] FRESH_MARK 가 기준판 src/ 전체에 0파일 · 지금 10파일(1~7번).
  #    🔴 **없는 경로 하나를 함께 묻는다** — 「무조건 yes」가 아닌지 가른다.
  v=$("$DOCKER" run --rm -e DSS_FILES="$AS_CHANGED_SRC" -e M="$FRESH_MARK" --entrypoint sh "$AS_TOOLS_NEW" -c 'set -f; printf "%s\n%s\n" "$DSS_FILES" "src/__dss_probe_no_such_file__.ts" | while IFS= read -r f; do [ -n "$f" ] || continue; if grep -qF -- "$M" "/app/$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  probe=$(printf '%s\n' "$v" | grep -c '^no  src/__dss_probe_no_such_file__' || true)
  say "새 내용 — $FRESH_MARK 가 든 파일 ${got:-0}개 (기대 $AS_CHANGED_SRC_WANT · 없는 경로 하나는 no 여야 한다)"
  if [ "${probe:-0}" != "1" ]; then
    bad "🔴 **없는 경로가 no 로 안 나왔다** — 「무조건 yes」인 검사다. 위 yes 도 못 믿는다"
    doubt
  elif [ "${got:-0}" = "$AS_CHANGED_SRC_WANT" ]; then
    ok "바뀐 ${AS_CHANGED_SRC_WANT}장이 **전부 새 내용**이다 (옛 소스가 섞여 있지 않다)"
    say "🔵 이번 판은 **새로 생긴 파일이 ${AS_BORN_SRC_WANT}장**입니다 — 열 장이 전부 고친 것(M)이라"
    say "   「새 파일이 담겼나」가 아니라 **「내용이 새것인가」**로 잽니다(58번은 반대였습니다)."
  else
    bad "🔴 새 내용인 것이 ${got:-0}/${AS_CHANGED_SRC_WANT} 장이다 — **옛 소스가 담긴 이미지다.** 올리지 마세요"
    doubt
  fi
  # ③-ㄷ 🔴 **이번 판이 고친 시험 여섯이 이미지 안의 목록 파일에 등록돼 있는가.**
  #    🔴 58번은 여기가 「**새** 시험 다섯」이었다. **이번 판에는 새 시험이 0장**이라
  #       그 다섯 경로를 그대로 두면 다섯 다 no 가 나와 **가짜 ✗** 다. 뜻을 바꿨다.
  #    🔴 「파일이 담겼다」와 「그 시험이 돈다」는 다른 말이다 — 이 저장소의 시험은
  #       글롭이 아니라 목록에 적어야 돈다. 등록이 빠지면 **이번에 고친 단언이 오류
  #       없이 조용히 안 돈다.** 🔵 여기서 시험을 돌리지는 않는다(운영 상자다).
  #
  #    🔴 **목록 파일은 CRLF 다 — 줄 전체로 맞대는 「-Fx」 가 「\r」 때문에 안 맞는다.**
  #       🔴 2026-11-11 쉰네째의 「--go」 에서 같은 줄이 **0/5 로 가짜 ✗** 를 냈다.
  #          이미지는 멀쩡했고 **검사가 틀렸다.**
  #       🔴 개발 PC 의 Git Bash grep 은 \r 를 스스로 걷어내 **거기서는 안 드러난다.**
  #          리눅스 컨테이너의 GNU grep 은 안 그런다 — NAS 가 바로 그쪽이다.
  #       🔵 그래서 **「tr -d」 로 \r 를 걷어낸 뒤** 맞댄다. 「-Fx」 는 **살린다** —
  #          경로 일부만 겹치는 다른 줄에 걸리면 안 된다.
  #    🔴 **cat 의 글롭은 「set -f」 앞에서 푼다** — 뒤에 두면 글롭이 꺼져 있어
  #       「*.txt」 가 글자 그대로 남고 **파일을 한 줄도 못 읽는다.**
  #    🔴 **없는 경로 하나를 일부러 함께 묻는다** — 그 줄이 no 로 안 나오면
  #       「무조건 yes」인 검사라는 뜻이고, 여섯의 yes 도 못 믿는다.
  v=$("$DOCKER" run --rm -e DSS_TESTS="$AS_TOUCHED_TESTS" -e DSS_MISS="$REG_PROBE_MISS" --entrypoint sh "$AS_TOOLS_NEW" -c 'L=$(cat /app/scripts/test-lists/*.txt 2>/dev/null | tr -d "\r"); echo "lines $(printf "%s\n" "$L" | grep -c .)"; set -f; printf "%s\n%s\n" "$DSS_TESTS" "$DSS_MISS" | while IFS= read -r t; do [ -n "$t" ] || continue; n=$(printf "%s\n" "$L" | grep -cFx -- "$t"); if [ "${n:-0}" -ge 1 ]; then echo "yes $t"; else echo "no  $t"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  probe=$(printf '%s\n' "$v" | grep -c "^no  $REG_PROBE_MISS" || true)
  lines=$(printf '%s\n' "$v" | sed -n 's/^lines //p')
  say "\\r 를 걷어내고 읽은 목록 줄 수: ${lines:-?}개 (기대 $AS_TESTLIST_MIN_LINES 이상 · 개발 PC 실측 3620)"
  if ! isnum "${lines:-}" || [ "${lines:-0}" -lt "$AS_TESTLIST_MIN_LINES" ]; then
    bad "🔴 이미지 안 목록을 ${lines:-못 읽음}줄밖에 못 읽었다 — **빈 결과는 삼켜진 오류일 수 있다**"
    doubt
  elif [ "${probe:-0}" != "1" ]; then
    bad "🔴 **없는 경로가 no 로 안 나왔다** — 줄 전체 일치가 깨졌다. 아래 yes 도 못 믿는다"
    doubt
  elif [ "${got:-0}" = "$AS_TOUCHED_TESTS_WANT" ]; then
    ok "이번 판이 고친 시험 $AS_TOUCHED_TESTS_WANT 개가 목록에 등록돼 있다 (고친 단언이 조용히 안 도는 일은 없다)"
    say "🔵 없는 경로 하나는 **no** 로 나왔습니다 — 「무조건 yes」인 검사가 아닙니다."
  else
    bad "🔴 등록된 것이 ${got:-0}/${AS_TOUCHED_TESTS_WANT} 개다 — **옛 목록 파일이 담겼다**"
    doubt
  fi
  # ③-ㄹ 🔵 **시험 목록 파일 넷이 이미지 안에 있는가** — 🔴 이번 판은 그 넷을
  #    한 줄도 안 바꾼다(scripts/ 변경 0개). 그래도 **담겨 있어야** 위 ③-ㄷ 이 선다.
  #    🔴 「이번 범위에서 **바뀐** 파일」을 세는 자리(③)와 **섞지 않는다.**
  v=$("$DOCKER" run --rm -e DSS_LISTS="$AS_TESTLIST_FILES" --entrypoint sh "$AS_TOOLS_NEW" -c 'printf "%s\n" "$DSS_LISTS" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "$AS_TESTLIST_FILES_WANT" ] && ok "시험 목록 파일 ${AS_TESTLIST_FILES_WANT}장이 이미지에 담겼다 (58번이 올린 것이 그대로 있다)" \
    || { bad "🔴 목록 파일이 ${got:-0}/${AS_TESTLIST_FILES_WANT} 장이다 — scripts/ 가 온전히 안 담겼다"; doubt; }
  # ③-ㅁ 🔴 **이 파일이 든 「바뀐 목록」에 scripts/ 가 정말 0줄인가.**
  #    🔴 **「0 이니 안 센다」로 만들지 않는다.** 먼저 **세는 길이 살아 있는지**
  #       가짜 목록 세 줄로 확인하고(1 이 나와야 한다), 그 다음에 이 파일의 목록이
  #       정말 0줄인지 본다. **1 이상이면 ✗** 다 — 늘었다면 도구 이미지에 담길
  #       목록이 달라진 것이고, 위 ③ 의 수와 ③-ㄹ 의 목록도 함께 고쳐야 한다.
  probe=$(printf '%s\n' 'src/lib/x.ts' 'scripts/test-lists/unit.txt' 'package.json' | grep -c '^scripts/' || true)
  nscr=$(printf '%s\n' "$AS_CHANGED_SCRIPTS" | grep -c '^scripts/' || true)
  say "표본 — 가짜 목록 세 줄에서 scripts/ 로 시작하는 줄 ${probe:-?}개 (기대 1)"
  say "이 파일이 든 scripts/ 변경 목록: ${nscr:-0}줄 (기대 $AS_CHANGED_SCRIPTS_WANT — **1 이상이면 ✗**)"
  if [ "${probe:-0}" != "1" ]; then
    bad "🔴 scripts/ 를 세는 길이 죽었다 — 아래 「0줄」이 공짜 통과다"
    doubt
  elif [ "${nscr:-x}" = "$AS_CHANGED_SCRIPTS_WANT" ]; then
    ok "이번 판이 바꾼 scripts/ 파일이 ${AS_CHANGED_SCRIPTS_WANT}개다 (**시험 목록 파일이 한 장도 안 바뀌었다**)"
    say "🔵 그것이 **새 시험이 0장**인 것과 앞뒤가 맞습니다 — 목록을 고칠 일이 없었습니다."
  else
    bad "🔴 scripts/ 변경이 ${nscr:-?}줄이다 — ${AS_CHANGED_SCRIPTS_WANT}줄을 기대했다. 이 파일의 목록을 보세요"
    doubt
  fi
  # ④ 🔴 **그 안에 이번 판의 글자가 있는가** — 「파일이 있다」와 다른 말이다.
  #    🔴 58번의 다섯(status=IN_HOUSE 따위)은 **이번 판이 하나도 안 건드린다** —
  #       그대로 두면 **옛 판에서도 전부 ✓** 인 죽은 검사다. 여섯을 전부 갈았다.
  #    🔵 **커밋이 하나뿐이라 「마지막 커밋을 가른다」는 고민이 없다** — 하나라도
  #       있으면 그 커밋이 담겼다는 뜻이다. 여섯을 세는 까닭은 **한 자리만 보면
  #       그 파일만 담긴 판을 못 가르기** 때문이다.
  #    🔴 **set -f 로 글롭을 끈다.** 지금 경로에는 대괄호가 없지만 끄는 것이 기본값이다.
  v=$("$DOCKER" run --rm -e DSS_MARKS="$AS_MARKS" --entrypoint sh "$AS_TOOLS_NEW" -c 'set -f; printf "%s\n" "$DSS_MARKS" | while IFS= read -r pair; do [ -n "$pair" ] || continue; m=${pair%%|*}; f=${pair#*|}; if grep -qF -- "$m" "/app/$f" 2>/dev/null; then echo "yes $m $f"; else echo "no  $m $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  seen=$(printf '%s\n' "$v" | grep -cE '^(yes|no ) ' || true)
  say "표식 — 본 것 ${seen:-0}개 · 있는 것 ${got:-0}개 (기대 $AS_MARKS_WANT · $AS_MARKS_WANT)"
  if [ "${seen:-0}" = "$AS_MARKS_WANT" ] && [ "${got:-0}" = "$AS_MARKS_WANT" ]; then
    ok "이번 판의 표식 $AS_MARKS_WANT 개가 이미지 안에 있다 (옛 판이 아니다)"
    say "🔵 여섯 다 **기준판 $AS_BASE_SHORT 에는 0번**이고 커밋 $AS_HEAD_SHORT 이 넣은 글자입니다."
  else
    bad "🔴 본 것 ${seen:-0} · 있는 것 ${got:-0} 다 — **옛 판이 담긴 이미지다.** 올리지 마세요"
    say "🔴 본 것이 $AS_MARKS_WANT 가 아니면 목록을 넘기는 길이 끊긴 것입니다."
    doubt
  fi
  # ⑤ 🔵 **공용 스키마가 담겼는가** — 없으면 Cannot find module 이 난다.
  #    🔵 이번 판에는 **안 바뀌었다**(핀이 그대로다). 그래서 「새 칸이 생겼나」가
  #       아니라 「쉰두째 것이 그대로 있나」를 본다 — 뒷걸음 방지다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'd=/app/vendor/dss-core/src/schema; if [ -d "$d" ]; then echo "miss=0"; echo "n=$(ls -1 "$d" | wc -l)"; else echo "miss=1"; fi' 2>/dev/null | tr -d ' \r')
  printf '%s\n' "$v" | sed 's/^/      /'
  c=$(printf '%s\n' "$v" | sed -n 's/^miss=//p'); got=$(printf '%s\n' "$v" | sed -n 's/^n=//p')
  if [ "${c:-1}" != "0" ]; then
    bad "🔴 이미지에 vendor/dss-core 의 스키마 폴더가 **없다** — Cannot find module 이 난다"; doubt
  elif [ "${got:-0}" -ge 1 ] 2>/dev/null; then
    ok "공용 스키마가 담겼다 (파일 ${got}개)"
  else
    bad "🔴 공용 스키마 폴더가 비었다 — **빈 서브모듈이 담겼다.** 올리지 마세요"; doubt
  fi
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for pair in "delivered_date /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "completed_at /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "due_date_row_order /app/vendor/dss-core/src/schema/repair-case-approvals.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "3" ] && ok "쉰두째가 더한 칸 셋이 공용 스키마에 그대로 있다 (뒷걸음친 서브모듈이 아니다)" \
    || { bad "🔴 그 칸이 ${got:-0}/3 개다 — **옛 공용 스키마가 담겼다.** 올리지 마세요"; doubt; }
  # ⑥ 🔵 **drizzle-kit 이 있는가.** 이번 판은 마이그레이션이 0건이라 db:migrate 를
  #    부를 일이 없다. 🔴 그래도 센다 — **다음 판이 그것으로 DB 를 바꾼다.**
  #    🔵 「이번에 안 쓴다」와 「없어도 된다」는 다른 말이다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "test -d /app/node_modules/drizzle-kit && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/node_modules/drizzle-kit: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "drizzle-kit 이 있다 (db:preflight·db:migrate 가 선다 — **다음 판의 준비**)" \
    || { bad "🔴 drizzle-kit 이 없다 — db:migrate 가 그 자리에서 죽는다"; doubt; }
  # ⑦ 🔴 **값으로 받아 본다.** 'node …' 가 아니라 **'npm run …'** 이어야
  #    Missing script 가 드러난다.
  #    🔵 DATABASE_URL 을 안 준다. 넷 다 맨 위에서 connection.ts 를 정적 import 하고
  #       그것이 모듈 꼭대기에서 던진다 — **DB 에는 한 글자도 안 닿는다.**
  for c in db:preflight check:due-date-overdue check:delivered-date-sync procedures:import; do
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
  # ⑧ 🔴 **도구 셋이 이미지 안에서도 읽기만 하는가** — 부르는 꼴로 센다.
  #    🔴 '--apply' 글자로 재지 않는다 — check-delivered-date-sync.ts 의 **주석**에
  #       그 낱말이 1번 나와서, 그렇게 재면 멀쩡한 도구가 ✗ 가 된다(머리말).
  #    🔴 「grep -c」 는 0 일 때 종료 코드 1 을 낸다. 파일 없음과 0번을 **갈래로** 가른다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for f in /app/scripts/check-due-date-overdue.ts /app/scripts/check-delivered-date-sync.ts /app/scripts/lib/delivered-date-sync-survey.ts; do if [ -f "$f" ]; then echo "miss=0 $f"; echo "w=$(grep -cE "\.insert\(|\.update\(|\.delete\(" "$f") $f"; echo "t=$(grep -c "db.transaction" "$f") $f"; else echo "miss=1 $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  nmiss=$(printf '%s\n' "$v" | grep -c '^miss=1' || true)
  nwrite=$(printf '%s\n' "$v" | grep -cE '^w=[1-9]' || true)
  ntx=$(printf '%s\n' "$v" | grep -cE '^t=[1-9]' || true)
  nok=$(printf '%s\n' "$v" | grep -c '^miss=0' || true)
  if [ "${nmiss:-1}" != "0" ]; then
    bad "🔴 도구 중 이미지에 **없는 것**이 ${nmiss}개다"; doubt
  elif [ "${nok:-0}" != "3" ]; then
    bad "🔴 도구 셋 중 ${nok:-0}개만 봤다 — 셋을 기대했다"; doubt
  elif [ "${nwrite:-1}" = "0" ] && [ "${ntx:-1}" = "0" ]; then
    ok "도구 셋이 이미지 안에서도 **읽기만 한다** (쓰는 꼴 0 · 트랜잭션 0)"
  else
    bad "🔴 쓰는 꼴이 든 파일 ${nwrite:-?}개 · 트랜잭션이 든 파일 ${ntx:-?}개 — **운영 DB 에 쓸 수 있는 판이다.** 올리지 마세요"
    doubt
  fi
  # ⑨ 🔵 지난 판들이 올린 도구가 **아직 있는가** — 한 번 빼면 다시 넣는 사람이 없다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts /app/scripts/check-delivered-date-sync.ts /app/scripts/lib/delivered-date-sync-survey.ts /app/scripts/import-procedure-bundle.ts /app/scripts/export-procedure-bundle.ts /app/scripts/lib/procedure-template-bundle.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "9" ] && ok "48~55번이 올린 도구 아홉이 다 들어 있다" \
    || bad "🔴 도구 파일이 ${got:-0}/9 개다 — scripts/ 가 온전히 안 담겼다"
  # ⑩ 🔵 엑셀 읽개 둘이 **개발 DB 자물쇠**를 그대로 부르는가(52·53번의 그 절).
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for f in /app/scripts/import-technical-task-procedures.ts /app/scripts/link-technical-task-next-procedures.ts; do if grep -q checkDevelopmentWriteTarget "$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "2" ] && ok "엑셀 읽개 둘이 개발 DB 자물쇠를 부른다 (NAS 에서 부르면 막힌다)" \
    || { bad "🔴 자물쇠를 부르는 것이 ${got:-0}/2 개다. **운영 DB 에 쓸 수 있는 판이다.** 올리지 마세요"; doubt; }
  # ⑪ tsx 가 있는가 — 이 도구들은 tsx 로만 돈다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/node_modules/tsx: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "A/S 도구에 tsx 가 있다" \
    || bad "🔴 tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다"
  # ⑫ 🔵 이미지 안의 drizzle/ 은 **비어 있어야** 한다 — 볼륨으로 붙는 자리다.
  #    🔴 이번 판은 묶음을 안 보내므로 **운영 볼륨이 그대로 쓰인다.** 여기에 .sql 이
  #       들어 있으면 볼륨과 이미지 중 어느 것이 도는지 알 수 없게 된다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  say "/app/drizzle 안 .sql: ${v:-?}개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)"
  if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then ok "이미지 안 drizzle/ 이 비어 있다 (🔴 그래서 마이그레이션은 **볼륨에서** 돈다)"
  else bad "🔴 이미지 안 drizzle/ 에 .sql 이 들었다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다"; doubt; fi
}

# ══ 🔴 A/S **앱** 이미지 안을 센다 — 58번이 세워 둔 자리다 ════════════
#   🔴 앱 이미지는 도구와 달리 **번들**이다 — 소스가 없다. 그래서 파일 경로가
#      아니라 **글자 리터럴**로만 가를 수 있다.
#   🔴 **상수 이름·함수 이름으로 재지 않는다** — minify 에 지워질 수 있어
#      멀쩡한 이미지가 ✗ 가 된다. 58번이 status=IN_HOUSE 를 고른 까닭도
#      「href 에 들어가는 리터럴이라 이름이 안 바뀐다」였다.
#      🔵 이번 판이 쓰는 것은 **알림 설정 화면의 새 설명 글자**다 — ASCII 날짜
#         하나와 한글 토막 하나. 설명은 **화면에 나가는 문자열**이라 안 지워진다.
#   🔵 **번들에서 실제로 재 보았다**(2026-11-12 개발 PC 의 .next/standalone) —
#      58번에는 그 실측이 없었다. 🔴 다만 **도커가 구운 번들은 아니다.**
#   🔵 컨테이너를 잠깐 띄웠다 지운다(run --rm) — **앱을 시작하지 않는다**(sh 로 연다).
as_app_inside_check() { # 1 태그
  local tag v a b kb km
  tag=$1
  printf '\n    ── %s 안을 센다 (🔵 번들이다 — 소스가 없다)\n' "$tag"
  # ① runner 가 맞는가 — tools 에는 /app/server.js 가 없다.
  v=$("$DOCKER" run --rm --entrypoint sh "$tag" -c "test -f /app/server.js && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/server.js: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "runner 스테이지가 맞다 (node server.js 를 안다)" \
    || { bad "🔴 /app/server.js 가 없다 — **runner 가 아닌 것을 실었다.** 갈아 끼우지 마세요"; doubt; }
  # ② 🔴 이번 판의 글자(ASCII) — 새 설명 글자 안의 날짜다
  #    (「…영업·관리자·최고관리자에게 가고(2026-11-12), …」).
  #    없으면 「옛 판을 실었다」이고, 증상은 **아무 일도 안 일어나는 것**이다 —
  #    배포는 성공하고 알림만 전처럼 좁게 간다.
  #    🔵 [실측 2026-11-12] 개발 PC 번들에서 server 4 · static 1.
  v=$("$DOCKER" run --rm -e M="$APP_MARK" --entrypoint sh "$tag" -c 'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  a=$(printf '%s' "$v" | awk '{print $1}'); b=$(printf '%s' "$v" | awk '{print $2}')
  say "$APP_MARK 가 든 파일 — .next/server ${a:-?}개 · .next/static ${b:-?}개 (실측 4 · 1 · 합이 1 이상)"
  if isnum "${a:-}" && isnum "${b:-}" && [ "$((a + b))" -ge 1 ]; then
    ok "번들에 이번 판의 글자가 있다 (옛 판이 아니다 — 설정 화면이 새 문장으로 뜬다)"
  else
    bad "🔴 번들에 $APP_MARK 가 없다 — **옛 판을 실었다.** 갈아 끼우지 마세요"
    say "🔵 **검사 자신도 의심하세요** — 개발 PC 의 next build 번들에서는 나왔지만"
    say "   **도커가 구운 번들에서 세어 본 적은 없습니다.**"
    doubt
  fi
  # ③ 🔴 **한글 표식** — 같은 설명 글자의 한가운데다.
  #    🔴 **명령에 한글을 넣지 않는다.** 8진 이스케이프를 넘기고 컨테이너 안에서
  #       다시 만든다. 🔴 만들기가 틀리면 0 이 나와 「없다」로 읽히므로 **바이트
  #       수를 먼저 받아** 가른다(기대 47). 47 이 아니면 ✗ 가 아니라 ⚠️ 다 —
  #       이미지가 틀린 것이 아니라 **글자를 못 만든 것**이다.
  #    🔵 [실측 2026-11-12] server 4 · static 1.
  v=$("$DOCKER" run --rm -e O="$APP_MARK_KO_OCT" --entrypoint sh "$tag" -c 'k=$(printf "$O"); n=$(printf "%s" "$k" | wc -c); printf "%s %s %s\n" "$n" "$(grep -rlF "$k" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$k" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  kb=$(printf '%s' "$v" | awk '{print $1}'); a=$(printf '%s' "$v" | awk '{print $2}'); b=$(printf '%s' "$v" | awk '{print $3}')
  say "한글 표식 — 만든 글자 ${kb:-?}바이트(기대 $APP_MARK_KO_BYTES) · server ${a:-?}개 · static ${b:-?}개 (실측 4 · 1)"
  if [ "${kb:-0}" != "$APP_MARK_KO_BYTES" ]; then
    hm "컨테이너 안에서 한글 표식을 **못 만들었다**(${kb:-?}바이트) — 🔴 위 수의 0 은 「없다」가 아니다"
    say "🔵 ② 가 ✓ 라면 판은 맞습니다 — **이 줄만으로 갈아 끼우기를 막지 않습니다.**"
  elif isnum "${a:-}" && isnum "${b:-}" && [ "$((a + b))" -ge 1 ]; then
    ok "새 설명 글자(한글)가 번들에 있다 — **설정 화면이 새 문장으로 뜬다**"
  else
    bad "🔴 그 한글 글자가 번들에 없다 — **옛 판을 실었다.** 갈아 끼우지 마세요"
    doubt
  fi
  # ④ 🔵 **뒷걸음 방지 둘** — 🔴 이번 판이 만든 글자가 **아니다.**
  #      · status=IN_HOUSE  — **쉰네째(58번)**가 올린 글자 [실측] server 1 · static 1
  #      · no-equipment-key — **쉰세째**가 올린 글자      [실측] server 4 · static 2
  #    🔴 58번에는 이 자리가 하나뿐이었다. **하나도 빼지 않는다.**
  km=0
  for KM in $(printf '%s\n' "$APP_KEEP_MARKS" | grep -v '^[[:space:]]*$'); do
    km=$((km+1))
    v=$("$DOCKER" run --rm -e M="$KM" --entrypoint sh "$tag" -c 'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
    a=$(printf '%s' "$v" | awk '{print $1}'); b=$(printf '%s' "$v" | awk '{print $2}')
    say "$KM 가 든 파일 — server ${a:-?}개 · static ${b:-?}개 (지난 판이 올린 글자)"
    if isnum "${a:-}" && isnum "${b:-}" && [ "$((a + b))" -ge 1 ]; then
      ok "$KM 가 그대로 있다 (뒷걸음친 나무가 아니다)"
    else
      bad "🔴 $KM 가 없다 — **지난 판보다 옛 나무를 실었다.** 갈아 끼우지 마세요"
      doubt
    fi
  done
  # 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다 — 둘을 다 봤는가.
  [ "$km" = "$APP_KEEP_MARKS_WANT" ] && ok "뒷걸음 방지 ${APP_KEEP_MARKS_WANT}개를 다 봤다 (표본이 비지 않았다)" \
    || bad "🔴 뒷걸음 방지를 ${km}개만 봤다 — ${APP_KEEP_MARKS_WANT}개를 기대했다. APP_KEEP_MARKS 가 깨졌다"
  # ⑤ 🔵 public/ — 없으면 아이콘·정적 파일이 404 가 되고 첫 화면부터 깨진다
  #    (layout.tsx 가 런타임에 public/theme-init.js 를 읽는다 — Dockerfile 의 주석).
  v=$("$DOCKER" run --rm --entrypoint sh "$tag" -c "test -d /app/public && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/public: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "public/ 이 담겼다" \
    || { bad "🔴 public/ 이 없다 — 첫 화면부터 깨진다"; doubt; }
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

# ══ 🔵 발주서 공유폴더가 **열리는가** — 🔴 **이번 판의 핵심 자리는 아니다** ══
#   🔵 **이 배포는 디스크를 아예 안 본다.**
#   🔴 그래도 **빼지 않는다**(42~58번의 규율). ✗ 가 나면 그것은 **지난 판이 올린
#      기능이 지금 고장나 있다**는 뜻이고, 되돌려도 안 고쳐진다.
#   🔴 **기대값을 박지 않는다** — 0 이면 ✗(볼륨 줄은 있는데 안 열린다),
#      1 이상이면 수를 찍고 ✓ 다.
purchase_order_archive_check() {
  local n
  printf '\n    ── 발주서 공유폴더가 열리는가 (🔵 **이번 판은 안 건드린다** · 지난 판 것을 지킨다)\n'
  n=$("$DOCKER" exec "$AS_APP_CN" sh -c "ls $PO_ARCHIVE 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  say "$AS_APP_CN 안에서 본 $PO_ARCHIVE 의 항목 ${n:-못 쟀다}개"
  if ! isnum "${n:-}"; then
    hm "못 쟀다 — $AS_APP_CN 가 도는지 보세요. **빈 결과는 삼켜진 오류일 수 있다**"
  elif [ "${n:-0}" -ge 1 ]; then
    ok "발주서 폴더가 열린다 (${n}개) — 🔵 지난 판이 올린 [발주서] 탭이 아직 쓸 수 있는 상태다"
  else
    bad "🔴 발주서 폴더가 **비었다** — 볼륨 줄은 있는데 안 열린다. [발주서] 탭이 **조용히** 빈다"
    say "🔵 **이 배포가 만든 일이 아니다** — 이번 판은 디스크를 아예 안 본다."
    say "🔴 그래도 **지난 판이 올린 기능이 지금 고장나 있다**는 뜻이다. 되돌려도 안 고쳐진다."
    say "🔴 compose 의 app-as 볼륨(/purchase-order-archive)과 공유폴더 권한을 보세요."
    doubt
  fi
}

# ══ 🔵 견적서 공유폴더가 **열리는가** — 이번 판이 안 건드린다 ═════════
#   🔴 **빼지 않는다** — 한 번 빼면 다시 넣는 사람이 없다.
QUOTE_DIR_PROBE='var fs=require("fs");
var v=(process.env[process.env.DSS_QA_NAME||"QUOTE_ARCHIVE_DIR"]||"").trim();
if(v===""){console.log("UNSET");}
else{var n=-1;try{n=fs.readdirSync(v).length;}catch(e){n=-1;}
console.log("DIR "+v+" items "+n);}'
quote_archive_check() {
  local out line n
  printf '\n    ── 견적서 공유폴더가 열리는가 (🔵 이번 판은 **안 건드린다**)\n'
  out=$("$DOCKER" exec -e DSS_QA_NAME="$QUOTE_ARCHIVE_ENV" "$AS_APP_CN" node -e "$QUOTE_DIR_PROBE" 2>&1 | tr -d '\r')
  line=$(printf '%s\n' "$out" | grep -E '^(DIR|UNSET)' | tail -1)
  say "받은 것: ${line:-못 쟀다}"
  case "${line:-}" in
    "DIR "*)
      n=${line##* }
      if isnum "${n:-}" && [ "${n:-0}" -ge 1 ]; then
        ok "견적서 폴더가 열린다 (${n}개)"
      elif [ "${n:-}" = "0" ]; then
        hm "견적서 폴더가 **비어 있다**(0개) — 🔵 연도 폴더가 아직 없을 수 있다. 사람이 보세요"
      else
        bad "🔴 견적서 폴더를 **못 열었다**(readdir 가 던졌다) — [견적서] 탭이 조용히 빈다"
        say "🔴 compose 의 app-as 볼륨과 공유폴더 권한을 보세요."
        doubt
      fi ;;
    UNSET*)
      hm "$QUOTE_ARCHIVE_ENV 설정이 비어 있다 — 🔵 **이 배포가 설정을 바꾸지 않는다.** 사람이 보세요" ;;
    *)
      hm "견적서 폴더를 못 쟀다 — $AS_APP_CN 가 도는지 보세요. **빈 결과는 삼켜진 오류일 수 있다**"
      printf '%s\n' "$out" | tail -6 | sed 's/^/      /' ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 실제로 바꾸는 자리를 센다** — 🔴 58번 것을 통째로 갈았다
# ══════════════════════════════════════════════════════════════════════
#   🔴 58번은 **입고 건수 셋**(전체 · 출하 완료가 아닌 건 · 차이)과 **기타건 둘**을
#      셌다. **그 다섯은 이번 판과 아무 상관이 없다.** 그대로 베껴 두면 이 배포를
#      재는 숫자가 **하나도 없다** — 그래서 재는 것을 통째로 바꿨다.
#   🔵 **select 뿐이고 한 글자도 안 쓴다.**
#
#   🔴 **이 배포는 DB 를 한 줄도 안 바꾼다.** 그래서 「전후 차이」로는 아무것도 못
#      잰다 — 대신 **새 코드가 보여 주게 될 줄 수를 지금 DB 로 미리 계산한다.**
#
#   🔴 **SQL 은 조회 함수의 WHERE 를 그대로 베꼈다.** 베낀 자리:
#      src/lib/db/queries/approval-outcome-notifications.ts 의 세 조회
#      (listRepairCaseApprovalOutcomes · listQuoteApprovalOutcomes ·
#       listDomesticOrderApprovalOutcomes). 바깥 입구는
#      listMyGrantedApprovalOutcomes(viewerUserId, viewerRole, options) 이고
#      **역할이 필수 인자**다(기본값을 두면 조용히 좁아진다는 그 파일의 주석).
#      빼먹지 않은 조건:
#        · status = 'APPROVED' (⑥ 만 'REJECTED')
#        · decided_at >= now() − **7일** (domain/notifications.ts 의
#          APPROVAL_OUTCOME_NOTIFICATION_WINDOW_DAYS = 7)
#        · 붙는 쪽의 **is_deleted = false**(repair_cases · quotes · domestic_orders)
#        · **INNER JOIN** — repair_case_id·quote_id·domestic_order_id 가 NULL 인
#          행이 거기서 떨어진다. 🔵 **갈래를 가르는 것도 그 조인이다** —
#          기타건 행은 repair_case_id 가 언제나 NULL 이라 접수 건 갈래에 못 든다.
#        · **decided_by_user_id <> 보는 사람** — 자기가 결재한 건은 자기 종에 안 뜬다
#        · **최종 승인만**(승인 쪽만) — 같은 묶음에 requested_at 이 더 늦은 행이 없다
#          (NOT EXISTS). 묶음은 접수 건이면 (건, 결재 종류) · 견적서면 그 한 장 ·
#          기타건이면 그 내자 줄. 🔵 **반려(⑥)는 이 조건이 없다** — 어느 단계에서든
#          알리므로 조회에도 그 NOT EXISTS 가 없다.
#   🔴 **흉내 내지 못한 것 둘** — 그래서 ④ 는 하한도 상한도 아닌 **어림수**다:
#        · 이미 **눌러 확인한 줄**이 빠지는 일(withoutAcknowledged)
#        · 알림 설정 스위치(⑦)가 꺼져 있으면 그 역할은 한 줄도 못 받는다
#
#   ① 영업·관리자·최고관리자인 **사람 수**(활성 · 휴지통 뺌)
#   ② 지난 7일 안에 **최종 승인된 결재**(사건 자체 · 사람과 무관)
#   ③ **지금(옛 코드)** 그 사람들의 종에 뜨는 「승인 완료」 줄 — 자기가 올린 것만
#   ④ 🔴 **이 배포 뒤에 새로 뜨는 줄** — 남이 올린 결재의 승인 완료
#   ⑤ ③+④ — 배포 뒤 그 사람들의 종에 설 「승인 완료」 줄의 합
#   ⑥ 🔴 **안 바뀌는 쪽** — 남이 올린 **반려** 줄. 그 수만큼은 **안 떠야** 한다
#   ⑦ 알림 설정 스위치가 꺼져 있는가 (꺼져 있으면 코드가 맞아도 한 줄도 안 뜬다)
#
#   🔴 **올리기 전후로 거의 같아야** 정상이다 — 자료를 한 줄도 안 건드린다.
#      🔵 다만 **7일 창은 시간이 가면 저절로 움직인다** — --check 와 --go 사이에
#         결재가 하나 나거나 7일이 지난 건이 빠지면 수가 달라질 수 있다.
# ── 🔴 세 갈래를 한 줄로 묶어 둔다 (아래 네 질의가 이것을 공유한다) ──────
#    🔴 **큰따옴표를 한 글자도 안 쓴다** — 이 글자가 pgq 안에서 큰따옴표에 싸인다.
#    🔴 **달러 기호도 안 쓴다** — 컨테이너 안 sh 가 치환해 버린다.
AS_OUTCOME_WINDOW_DAYS=7
AS_BROAD_ROLES_SQL="'SALES','ADMIN','SUPER_ADMIN'"
# 🔵 최종 승인된 결과 — 세 갈래. rby = 요청자 · dby = 결정자.
#    🔴 칸 이름을 req·dec 로 줄이지 않았다 — dec 는 Postgres 의 타입 이름(decimal)과
#       겹쳐 자리에 따라 구문 오류가 난다. 오류가 나면 pgn 이 빈 값을 주고 「못 쟀다」로
#       흐른다.
AS_GRANTED_CTE="with outcome as ( \
select rca.requested_by_user_id as rby, rca.decided_by_user_id as dby from repair_case_approvals rca \
join repair_cases rc on rc.id = rca.repair_case_id \
where rca.status::text = 'APPROVED' and rca.decided_at >= now() - interval '$AS_OUTCOME_WINDOW_DAYS days' and rc.is_deleted = false \
and not exists (select 1 from repair_case_approvals l where l.repair_case_id = rca.repair_case_id and l.approval_type = rca.approval_type and l.requested_at > rca.requested_at) \
union all \
select qa.requested_by_user_id as rby, qa.decided_by_user_id as dby from quote_approvals qa \
join quotes q on q.id = qa.quote_id \
where qa.status::text = 'APPROVED' and qa.decided_at >= now() - interval '$AS_OUTCOME_WINDOW_DAYS days' and q.is_deleted = false \
and not exists (select 1 from quote_approvals l where l.quote_id = qa.quote_id and l.requested_at > qa.requested_at) \
union all \
select rca.requested_by_user_id as rby, rca.decided_by_user_id as dby from repair_case_approvals rca \
join domestic_orders d on d.id = rca.domestic_order_id \
where rca.status::text = 'APPROVED' and rca.decided_at >= now() - interval '$AS_OUTCOME_WINDOW_DAYS days' and d.is_deleted = false \
and not exists (select 1 from repair_case_approvals l where l.domestic_order_id = rca.domestic_order_id and l.requested_at > rca.requested_at) \
), viewer as (select id from users where role::text in ($AS_BROAD_ROLES_SQL) and is_active and not is_deleted) "
# 🔵 반려 — **최종 조건이 없다**(어느 단계에서든 알린다). 나머지는 같다.
AS_REJECTED_CTE="with outcome as ( \
select rca.requested_by_user_id as rby, rca.decided_by_user_id as dby from repair_case_approvals rca \
join repair_cases rc on rc.id = rca.repair_case_id \
where rca.status::text = 'REJECTED' and rca.decided_at >= now() - interval '$AS_OUTCOME_WINDOW_DAYS days' and rc.is_deleted = false \
union all \
select qa.requested_by_user_id as rby, qa.decided_by_user_id as dby from quote_approvals qa \
join quotes q on q.id = qa.quote_id \
where qa.status::text = 'REJECTED' and qa.decided_at >= now() - interval '$AS_OUTCOME_WINDOW_DAYS days' and q.is_deleted = false \
union all \
select rca.requested_by_user_id as rby, rca.decided_by_user_id as dby from repair_case_approvals rca \
join domestic_orders d on d.id = rca.domestic_order_id \
where rca.status::text = 'REJECTED' and rca.decided_at >= now() - interval '$AS_OUTCOME_WINDOW_DAYS days' and d.is_deleted = false \
), viewer as (select id from users where role::text in ($AS_BROAD_ROLES_SQL) and is_active and not is_deleted) "
AS_NOTIF_KIND=APPROVAL_GRANTED

effect_counts() {
  local people evt old new sum rej kindoff roleoff
  printf '\n    ── 🔴 이 배포가 바꾸는 자리 (운영 수 · **select 뿐이다**)\n'
  say "🔴 이 배포는 **DB 를 한 줄도 안 바꾼다** — 그래서 「전후 차이」로는 아무것도"
  say "   못 잽니다. 대신 **새 코드가 보여 주게 될 줄 수**를 지금 DB 로 미리 셉니다."
  say "🔵 창은 **$AS_OUTCOME_WINDOW_DAYS 일**입니다(domain/notifications.ts 의 그 상수) — 시간이 가면 저절로 움직입니다."
  people=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from users where role::text in ($AS_BROAD_ROLES_SQL) and is_active and not is_deleted")
  evt=$(pgn "$AS_BOX" "$AS_DB" "${AS_GRANTED_CTE}select count(*) from outcome")
  old=$(pgn "$AS_BOX" "$AS_DB" "${AS_GRANTED_CTE}select count(*) from outcome o, viewer v where o.dby <> v.id and o.rby = v.id")
  new=$(pgn "$AS_BOX" "$AS_DB" "${AS_GRANTED_CTE}select count(*) from outcome o, viewer v where o.dby <> v.id and o.rby <> v.id")
  say "① 영업·관리자·최고관리자(활성):            ${people:-못 쟀다}명"
  say "② 지난 ${AS_OUTCOME_WINDOW_DAYS}일 안에 **최종 승인**된 결재:     ${evt:-못 쟀다}건  ← 사건 자체 (사람과 무관)"
  say "③ **지금(옛 코드)** 그분들 종에 뜨는 줄:   ${old:-못 쟀다}줄  ← 자기가 올린 것만"
  say "④ 🔴 **이 배포 뒤 새로 뜨는 줄**:          ${new:-못 쟀다}줄  ← 남이 올린 결재의 승인 완료"
  if [ -z "${people:-}" ] || [ -z "${evt:-}" ] || [ -z "${old:-}" ] || [ -z "${new:-}" ]; then
    hm "종 줄 수를 **못 쟀다** — $AS_BOX 가 도는지, 그 표들이 있는지 보세요"
    say "🔴 **빈 결과는 삼켜진 오류일 수 있다** — 「0줄」과 「못 쟀다」는 다른 말이다."
    doubt
  else
    sum=$((old + new))
    say "⑤ ③ + ④ =                                ${sum}줄  ← 배포 뒤 그분들의 「승인 완료」 합"
    ok "종 줄 수를 값으로 쟀다 (사람 ${people} · 사건 ${evt} · 지금 ${old} · 새로 ${new})"
    if [ "${people:-0}" = "0" ]; then
      hm "🔴 그 세 역할인 **활성 계정이 한 명도 없다** — 이 배포로 달라질 사람이 없습니다. 사람이 보세요"
    fi
    if [ "${new:-0}" -ge 1 ]; then
      say "🔴 **영업·관리자 계정으로 로그인해 종을 열면 그중 그분 몫이 떠야 합니다.**"
      say "   🔵 ④ 는 **사람 × 줄**을 다 더한 수입니다 — 한 사람이 그만큼 보는 것이 아닙니다."
    else
      hm "④ 가 **0줄이다** — 🔵 **배포가 잘못된 것이 아닙니다.** 지난 ${AS_OUTCOME_WINDOW_DAYS}일 안에 「남이 올린"
      say "   결재의 최종 승인」이 없었다는 뜻이고, **눈으로 확인할 거리가 지금은 없습니다.**"
      say "   🔵 결재가 한 건 끝나면 그때 종에 섭니다. 설명 글자(설정 화면)는 지금도 볼 수 있습니다."
    fi
    say "🔴 ③④ 는 **앱의 잣대를 완전히 흉내 내지 못합니다** — 이미 **눌러 확인한 줄**은"
    say "   빠지고(withoutAcknowledged), 아래 ⑦ 의 스위치가 꺼져 있으면 아예 안 뜹니다."
  fi
  # ⑥ 🔴 **안 바뀌는 쪽** — 반려는 요청자 본인뿐이다. 이 수만큼은 **안 떠야** 한다.
  rej=$(pgn "$AS_BOX" "$AS_DB" "${AS_REJECTED_CTE}select count(*) from outcome o, viewer v where o.dby <> v.id and o.rby <> v.id")
  say "⑥ 🔴 남이 올린 **반려** 줄: ${rej:-못 쟀다}줄  ← 🔴 **배포 뒤에도 그분들 종에 「안 떠야」 한다**"
  if [ -z "${rej:-}" ]; then
    hm "반려 줄을 **못 쟀다** — 사람이 보세요. 🔵 이 배포를 막지 않는다"
  elif [ "${rej:-0}" -ge 1 ]; then
    ok "반려 쪽을 값으로 쟀다 (${rej}줄 — **안 떠야 할 줄**이다)"
    say "🔴 **이 판에서 가장 놓치기 쉬운 자리입니다** — 승인 완료만 넓어졌고 반려는"
    say "   요청자 본인 그대로입니다. 종에 「반려됨」이 남의 건으로 뜨면 **멈추고 알리세요.**"
  else
    hm "반려 줄이 0줄이다 — 🔵 **「안 떠야 할 것」을 눈으로 확인할 거리가 지금은 없습니다**"
  fi
  # ⑦ 🔵 알림 설정 스위치 — 행이 없는 것이 정상이다(없으면 코드의 기본값 = 켜짐).
  kindoff=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from notification_kind_settings where kind_key = '$AS_NOTIF_KIND' and is_enabled = false")
  roleoff=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from notification_role_settings where kind_key = '$AS_NOTIF_KIND' and receives = false and role::text in ($AS_BROAD_ROLES_SQL)")
  say "⑦ 알림 설정 — 「승인 완료」 종류가 꺼진 줄 ${kindoff:-못 쟀다}개 · 그 세 역할이 꺼진 줄 ${roleoff:-못 쟀다}개 (기대 0 · 0)"
  if [ -z "${kindoff:-}" ] || [ -z "${roleoff:-}" ]; then
    hm "알림 설정을 **못 쟀다** — 그 표가 있는지 보세요. 🔵 이 배포를 막지 않는다"
  elif [ "${kindoff:-0}" = "0" ] && [ "${roleoff:-0}" = "0" ]; then
    ok "알림 설정에서 「승인 완료」를 막아 둔 줄이 없다 (행이 없으면 코드의 기본값 = 켜짐)"
  else
    hm "🔴 꺼 둔 줄이 있습니다(종류 ${kindoff} · 역할 ${roleoff}) — **코드가 맞아도 종에 안 뜹니다**"
    say "🔵 **이 배포가 만든 일이 아닙니다** — [사용자 관리] › [알림 설정] 에서 켜는 자리입니다."
    say "🔴 켜지 않은 채로 「안 뜬다」고 하면 배포를 의심하게 됩니다. 먼저 이 줄을 보세요."
  fi
}

# ══ 🔴 53번 꼬리말에서 넘어온 후속 작업 둘을 **값으로** 센다 ═════════
#   🔴 **판정하지 않는다.** 「하셨다/안 하셨다」를 이 스크립트가 가를 기준이 없다 —
#      수를 찍고 사람이 가른다.
#   🔴 **scope::text 로 비교한다.** enum 리터럴로 비교하면 그 값이 없는 DB 에서
#      질의가 통째로 오류가 나고, 빈 결과가 「0 이다」로 조용히 흘러간다.
followup_counts() {
  local r m pend
  printf '\n    ── 🔵 53번(쉰째) 꼬리말에서 넘어온 할 일 둘 (값만 찍는다 · 판정하지 않는다)\n'
  r=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $AS_ROUTE_TABLE where scope::text='$AS_ENUM_VALUE'")
  say "① 기타건 최종 출하 승인 결재선 판: ${r:-못 쟀다}개"
  if [ -z "${r:-}" ]; then
    hm "결재선 판 수를 **못 쟀다** — $AS_BOX 가 도는지, 그 표가 있는지 보세요"
  elif [ "${r:-0}" -ge 1 ] 2>/dev/null; then
    ok "결재선 판이 ${r}개 있다 — **기타건 [완료] 처리가 선다**"
  else
    hm "결재선 판이 **0개다** — 🔴 **지금은 기타건을 아무도 [완료] 처리할 수 없습니다.**"
    say "🔴 [사용자 관리] › [승인 절차] 에서 「기타건 최종 출하 승인」을 **한 판 세우세요.**"
    say "   🔵 53번(쉰째) 배포 때 넘어온 할 일입니다 — **이 배포를 막지 않습니다.**"
  fi
  m=$(pgn "$AUTH_BOX" "$AUTH_DB" "select count(*) from $AUTH_MAIL_TABLE where client_id='$AUTH_MAIL_CLIENT' and kind='$AS_ENUM_VALUE' and enabled")
  say "② 포털 결재 알림 메일 스위치(켜짐): ${m:-못 쟀다}줄"
  if [ -z "${m:-}" ]; then
    hm "메일 스위치를 **못 쟀다** — $AUTH_BOX 가 도는지, $AUTH_MAIL_TABLE 이 있는지 보세요"
  elif [ "${m:-0}" -ge 1 ] 2>/dev/null; then
    ok "「기타건 최종 출하 결재」 메일이 **켜져 있다**"
  else
    say "🔵 아직 꺼져 있습니다(기본값 끔 — 2026-10-23 결정). **종과 통합 승인함은 뜹니다.**"
    say "   메일까지 받으려면 포털 관리자 화면 › 결재 알림 메일 에서 켜세요."
  fi
  pend=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from domestic_orders where repair_case_id is null and completed_at is null and is_deleted = false")
  say "🔵 지금 열려 있는 기타건(수리건 안 붙고 아직 완료 아님): ${pend:-못 쟀다}건"
  say "   🔴 결재선이 0개이면 **그 ${pend:-?}건이 전부 [완료] 처리에서 막힙니다.**"
}

# ══════════════════════════════════════════════════════════════════════
# ── --count : 도구를 읽기만 해서 센다 + 이 배포가 바꾸는 자리 ─────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **'--silent' 를 안 붙인다.** 붙이면 npm 의 로그 수위가 내려가 'Missing
#      script' 가 **안 찍힐 수 있고**, 그러면 아래 가지가 「못 쟀다」가 아니라
#      조용히 「건수가 안 보인다」로 흘러간다.
#   🔵 **이번 판은 새 도구를 안 만들었다.** 55번에 있던 「아직 옛 태그라 없는 것이
#      정상」 가지가 **이 판에는 쓸 일이 없다** — 다섯 다 :17 에도 :18 에도 있다.
#      🔴 그래서 「없다」는 어느 단계에서나 **예상 밖**이다. 가지를 없앴다.
count_one() { # 1 npm 명령 2 사람이 부르는 이름
  local out rc
  printf '\n  ── %s  (npm run %s)\n' "$2" "$1"
  out=$(dct run --rm -T "$AS_TOOLS_SVC" npm run "$1" 2>&1)
  rc=$?
  out=$(printf '%s' "$out" | tr -d '\r')
  if printf '%s' "$out" | grep -qE 'Missing script|missing script'; then
    bad "🔴 $2 — **그 도구 이미지에 이 명령이 없다**(Missing script)"
    say "🔵 다섯은 :17 에도 :18 에도 있어야 한다 — 48·52~55번이 올려 두었고 이번 판에 안 줄었다."
    say "🔴 그러니 이 답은 **예상 밖**이다. compose 의 $AS_TOOLS_SVC 태그를 보세요."
    doubt
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
  printf '\n== 도구를 읽기만 해서 센다 + 이 배포가 바꾸는 자리\n'
  [ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
  printf '%s\n' "🔴 **다섯 다 쓰는 모드가 없다.** DB 에 한 글자도 안 쓴다."
  printf '%s\n' "   🔵 쓰는 깃발(--apply)을 **일부러** 두지 않았다 — 59-build.sh 가 그것을"
  printf '%s\n' "      **부르는 꼴**('.insert(' 따위)로 쟀다(쓰는 문장 0 · 트랜잭션 0)."
  CTL=$(img_line "$AS_TOOLS_SVC")
  if [ -n "${CTL:-}" ]; then
    printf '%s\n' "🔵 지금 compose 의 $AS_TOOLS_SVC 태그: $(tag_at "$CTL")  (${CTL}줄)"
  else
    printf '%s\n' "🔴 compose 에서 $AS_TOOLS_SVC 의 image: 줄을 못 찾았다 — 아래 수가 어느 판인지 모른다"
  fi
  printf '%s\n' "🔴 **아래 다섯은 이번 배포와 상관이 없습니다.** 앞뒤가 같으면 정상이고,"
  printf '%s\n' "   다르면 **그 사이에 사람이 저장한 것**입니다."
  printf '%s\n' "   🔵 55번(쉰두째)은 이 다섯 중 둘이 배포의 목적이었습니다 — **이번 판은 아닙니다.**"
  printf '%s\n' "   🔴 그래서 **이 배포를 재는 숫자는 맨 아래 절**(effect_counts)에 있습니다."
  printf '%s\n' "   🔴 그 절은 **58번 것과 재는 것이 완전히 다릅니다** — 58번은 입고 건수를,"
  printf '%s\n' "      이번 판은 **「승인 완료」 종에 설 줄 수**를 셉니다."
  count_one check:target-shipment-missing "사내 목표 출하일 미등록"
  count_one check:due-date-inverted       "납기 역전"
  count_one check:requested-due-date-sync "납기요청일 ↔ 고객 요청 납기일 어긋남"
  count_one check:due-date-overdue        "[납기 지연]"
  count_one check:delivered-date-sync     "납품일 ↔ 실제 출하일"
  # 🔴 **이 배포가 바꾸는 자리** — 🔴 58번 것을 통째로 갈아 끼운 절이다.
  effect_counts
  # 🔴 53번 꼬리말에서 넘어온 할 일 둘 — 값만 찍는다.
  followup_counts
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  printf '%s\n' "🔴 [납기 지연] 수가 크면 — 끄는 길은 **사용자 관리 › 알림 설정** 입니다."
  printf '%s\n' "🔴 **④(새로 뜨는 줄)와 ⑥(안 떠야 할 반려 줄)을 적어 두세요** — 배포 뒤 눈으로"
  printf '%s\n' "   맞댈 두 수입니다. 🔵 ④ 가 0 이면 지금은 확인할 거리가 없다는 뜻입니다."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 1. 지금 상태 ──────────────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
[ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
say "compose 줄 수 $(wc -l < "$CF") · image: 줄 $(grep -c '^ *image:' "$CF")개"

# ── ㄱ) 🔴 **운영이 지금 쓰는 태그 전부** — 저장소 사본을 믿지 않는다 ──
#   이 저장소의 compose 사본은 운영보다 뒤처진다(48번에 **세 줄**이 어긋나 있었다).
#   🔴 그래서 **여기서 직접 읽는다.**
printf '\n    ── 운영 compose 의 image: 줄 전부 (이 파일이 진짜다)\n'
grep -n '^ *image:' "$CF" | sed 's/^/      /'
printf '\n    ── 지금 **도는** 컨테이너와 그 이미지 (compose 와 다를 수 있다)\n'
"$DOCKER" ps -a --format '{{.Names}} {{.Image}} {{.Status}}' 2>/dev/null | sort | sed 's/^/      /'

# ══════════════════════════════════════════════════════════════════════
# 🔴 1-ㄱ-2. **상태 변수를 먼저 정한다** — 그다음에 가지를 나눈다
# ══════════════════════════════════════════════════════════════════════
#   🔴 48번이 데인 자리다. 기대값을 한 갈래로 박아 두면 **적용 뒤에 다시 부를 때
#      가짜 ✗** 가 난다.
#   🔴 **이번 판은 갈래가 둘이다**(앱 하나 · 도구 하나).
AS_NEW_TAG=$(printf '%s\n' "$(rows)" | grep '^as|' | head -1 | cut -d'|' -f4)
AS_OLD_TAG=$(printf '%s\n' "$(rows)" | grep '^as|' | head -1 | cut -d'|' -f5)
# 🔵 표의 서비스 이름도 표에서 읽는다 — 두 벌로 적으면 한쪽만 고쳤을 때 어긋난다.
AS_SVC=$(printf '%s\n' "$(rows)" | grep '^as|' | head -1 | cut -d'|' -f2)

state_of() { # 1 지금 태그 2 옛 태그 3 새 태그 → OLD|NEW|ODD
  if   [ "${1:-}" = "$3" ]; then printf 'NEW'
  elif [ "${1:-}" = "$2" ]; then printf 'OLD'
  else printf 'ODD'; fi
}
APP_AS_L=$(img_line "$AS_SVC" 2>/dev/null || true)
AS_TOOLS_L=$(img_line "$AS_TOOLS_SVC" 2>/dev/null || true)
APP_AS_TAG_NOW="";   [ -n "${APP_AS_L:-}" ]   && APP_AS_TAG_NOW=$(tag_at "$APP_AS_L")
AS_TOOLS_TAG_NOW=""; [ -n "${AS_TOOLS_L:-}" ] && AS_TOOLS_TAG_NOW=$(tag_at "$AS_TOOLS_L")
S_APP_AS=$(state_of   "$APP_AS_TAG_NOW"   "$AS_OLD_TAG"   "$AS_NEW_TAG")
S_AS_TOOLS=$(state_of "$AS_TOOLS_TAG_NOW" "$AS_TOOLS_OLD" "$AS_TOOLS_NEW")
printf '\n    ── 🔴 지금 단계(PHASE) — 둘을 각각 읽는다\n'
printf '      %-12s %-22s 옛 %-20s 새 %-20s → %s\n' "$AS_SVC"       "${APP_AS_TAG_NOW:-못 읽음}"   "$AS_OLD_TAG"   "$AS_NEW_TAG"   "$S_APP_AS"
printf '      %-12s %-22s 옛 %-20s 새 %-20s → %s\n' "$AS_TOOLS_SVC" "${AS_TOOLS_TAG_NOW:-못 읽음}" "$AS_TOOLS_OLD" "$AS_TOOLS_NEW" "$S_AS_TOOLS"
PHASE=ODD
if   [ "$S_APP_AS" = OLD ] && [ "$S_AS_TOOLS" = OLD ]; then PHASE=PRE
elif [ "$S_APP_AS" = NEW ] && [ "$S_AS_TOOLS" = NEW ]; then PHASE=POST
elif [ "$S_APP_AS" = OLD ] && [ "$S_AS_TOOLS" = NEW ]; then PHASE=MID
fi
say "PHASE=$PHASE"
case "$PHASE" in
  PRE)  ok "PHASE=PRE — 아직 아무것도 안 갈아 끼웠다 (--preload → --go 차례)"
        say "🔵 **--migrate 단계가 없다** — 그래서 --go 가 image: 줄 **둘**을 한 번에 고친다." ;;
  MID)  ok "PHASE=MID — 도구만 새 판이다"
        say "🔴 **이 판에서 MID 는 「--go 뒤에 --rollback 으로 앱만 되돌린 상태」다.**"
        say "   🔵 55번에서는 「--migrate 까지 돌았다」였다 — **이 판에는 --migrate 가 없다.**" ;;
  POST) ok "PHASE=POST — 둘 다 새 판이다. --go 까지 돌았다" ;;
  *)    hm "PHASE=ODD — 둘이 섞여 있다. **--go 가 도중에 멈췄거나 운영이 따로 움직였다.** 위 표를 보세요"
        say "🔴 **이 저장소의 compose 사본을 믿고 적은 값이 아니다** — 58번(쉰네째)이 올린 판"
        say "   ($AS_OLD_TAG · $AS_TOOLS_OLD)을 옛 값으로 적었다. 그래도 어긋났다면 운영이 그 사이"
        say "   따로 움직였다는 뜻이다. **고치지 말고 알리세요.**" ;;
esac
# 🔴 **모드마다 서 있어야 하는 PHASE 가 다르다.** 여기서 한 번만 가른다.
case "$MODE" in
  rollback)
    case "$PHASE" in
      POST) ok "되돌릴 준비가 됐다 (PHASE=POST)" ;;
      MID)  hm "앱이 이미 옛 판이다 (PHASE=MID — 벌써 되돌렸나)" ;;
      *)    hm "PHASE=$PHASE 에서 되돌리기를 부르셨다 — 🔵 막지는 않는다. 위 표를 보세요" ;;
    esac ;;
  go)
    case "$PHASE" in
      PRE)  ok "갈아 끼울 준비가 됐다 (PHASE=PRE — image: 줄 **둘**이 달라질 것이다)" ;;
      MID)  ok "갈아 끼울 준비가 됐다 (PHASE=MID — 도구는 이미 새 판이다. image: 줄 **하나**만 달라질 것이다)" ;;
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
# 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다 — 앱 **하나**를 봤는가.
[ "$SITES_SEEN" = "$SITES_WANT" ] && ok "다시 띄울 앱 ${SITES_WANT}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "🔴 앱을 ${SITES_SEEN}개만 봤다 — ${SITES_WANT}개를 기대했다. SITES 표가 깨졌다"

# ══ 🔴 안 건드리는 앱 둘 — **그래도 「그대로인가」는 본다** ════════════
#   🔵 포털은 사내 모든 시스템의 로그인을 떠받친다. 안 건드려도 **살아 있는지**는
#      봐야 한다. 🔴 어긋나도 **이 배포를 막지 않는다**(⚠️ 로만 센다).
for trio in "app-po $PO_APP_CN $PO_WANT_TAG" "app-auth $AUTH_APP_CN $AUTH_WANT_TAG"; do
  set -- $trio
  printf '\n    ── %s (이번에 **안 건드린다**)\n' "$1"
  XL=$(img_line "$1" 2>/dev/null || true)
  if [ -n "${XL:-}" ]; then
    XCUR=$(tag_at "$XL")
    XRUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$2" 2>/dev/null)
    XST=$("$DOCKER" inspect -f '{{.State.Status}}' "$2" 2>/dev/null)
    say "$1 — ${XL}줄 · compose ${XCUR} · 도는 것 ${XRUN:-없음} (${XST:-?})"
    if [ "$XCUR" = "$3" ]; then
      ok "$1 가 $3 다 (53·55번까지 올린 그 판 · 이번에 안 건드린다)"
    else
      hm "$1 가 $XCUR 다 — $3 를 기대했다. **이 배포를 막지 않는다.** 사람이 보세요"
    fi
    say "🔴 5절은 이 줄을 **안 고친다** — 달라진 image: 줄 수로 그것을 확인한다."
  else
    bad "compose 에 $1 가 없다 — 지금까지 있던 것이다. 사람이 보세요"
  fi
done

# ══ 🔴 도구 둘 — 볼륨 줄과 태그가 제자리인가 ══════════════════════════
printf '\n    ── %s 의 볼륨\n' "$AS_TOOLS_SVC"
if [ -n "${AS_TOOLS_L:-}" ]; then
  # 🔴 볼륨이 제 자리에 붙는가 — 여기가 어긋나면 **db:preflight 가 엉뚱한 것을 읽는다.**
  #    🔴 **이번 판에서 특히 중요하다** — 「올릴 것이 0건인가」를 그 볼륨으로 재기 때문이다.
  if svc_block "$AS_TOOLS_SVC" | grep -q "$MIGDIR:$IMG_MIGDIR"; then
    ok "$AS_TOOLS_SVC 가 $MIGDIR 를 $IMG_MIGDIR 로 붙인다 (🔴 2-ㄹ 절이 그 폴더로 0건을 확인한다)"
  else
    bad "🔴 $AS_TOOLS_SVC 의 drizzle 볼륨이 $MIGDIR 가 아니다 — **preflight 가 엉뚱한 폴더를 읽는다**"
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
else
  bad "compose 에 $AS_TOOLS_SVC 가 없다 — 올릴 자리가 없다"
fi
# 🔵 포털 도구 — **안 건드린다.** 53번이 올린 :4 그대로여야 한다.
printf '\n    ── %s (이번에 **안 건드린다**)\n' "$AUTH_TOOLS_SVC"
AUTH_TOOLS_L=$(img_line "$AUTH_TOOLS_SVC" 2>/dev/null || true)
if [ -n "${AUTH_TOOLS_L:-}" ]; then
  ATCUR=$(tag_at "$AUTH_TOOLS_L")
  say "$AUTH_TOOLS_SVC — ${AUTH_TOOLS_L}줄 · compose ${ATCUR}"
  if [ "$ATCUR" = "$AUTH_TOOLS_KEEP" ]; then
    ok "$AUTH_TOOLS_SVC 가 $AUTH_TOOLS_KEEP 다 (53번이 올린 그 판 · 야간 정리와 결재 메일이 그 길로 돈다)"
  else
    hm "$AUTH_TOOLS_SVC 가 $ATCUR 다 — $AUTH_TOOLS_KEEP 를 기대했다. **이 배포를 막지 않는다.** 사람이 보세요"
  fi
  if svc_block "$AUTH_TOOLS_SVC" | grep -q "$AUTH_BOX"; then
    ok "$AUTH_TOOLS_SVC 가 $AUTH_BOX 를 본다"
  else
    bad "🔴 $AUTH_TOOLS_SVC 가 $AUTH_BOX 를 안 본다 — **엉뚱한 서버에 붙는다**"
    doubt
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
say "   process.env 이름이 0개다**(2026-11-12 실측 — 바뀐 열 장에 process.env 를"
say "   더한 줄이 0줄이다). 고친 것은 **종 알림 조회의 WHERE** 뿐이다."

# ── 1-ㄷ. 🔵 **양식** — 재기만 한다 (이번 판은 올릴 것이 0장) ─────────
templates_check

# ── 1-ㄹ. 🔴 **PO 가 repair_cases 에 쓸 수 있는가** ───────────────────
case "$MODE" in
  rollback) po_write_privilege_check soft ;;
  *)        po_write_privilege_check warnmiss ;;
esac

# ── 1-ㅁ. 🔵 공유폴더 둘 — **이번 판은 안 건드린다. 그래도 잰다** ───
purchase_order_archive_check
quote_archive_check

# ── 2. 🔴 DB — **이번 판은 앞뒤가 같은 수다** (127 그대로) ───────────
#   🔵 A/S 와 PO 가 같은 dss_as 를 본다. 포털은 dss_auth 를 따로 본다.
#   🔴 **55번의 「125 → 127 두 갈래」를 그대로 베끼면 안 된다** — 이 판에서는
#      어느 가지로 가도 127 이라 **아무것도 안 재는 ✓** 가 된다.
#      그래서 갈래를 **없애고**, 대신 「적용 대기가 0건인가」를 2-ㄹ 에서 잰다.
printf '\n== 2. DB (dss_as · A/S 와 PO 가 함께 쓴다)\n'
say "🔵 이 판은 마이그레이션 **0건**이다 — 기대값이 **$AS_MIG_KEEP 한 갈래**다(앞뒤가 같다)."
MIG_AS0=$(mig_count "$AS_BOX" "$AS_DB")
say "기록 ${MIG_AS0:-?} (기대 $AS_MIG_KEEP — PHASE 와 무관하다)"
if [ -z "${MIG_AS0:-}" ]; then
  bad "DB 를 못 쟀다 — $AS_BOX 가 도는지 보세요"
  doubt
elif [ "$MIG_AS0" = "$AS_MIG_KEEP" ]; then
  ok "$AS_MIG_KEEP 다 — 55번이 0125·0126 을 올려 둔 그대로 (**이 배포는 여기를 안 건드린다**)"
else
  bad "🔴 기록이 ${MIG_AS0} 이다 — $AS_MIG_KEEP 을 기대했다"
  say "🔴 125 면 **55번(쉰두째) 배포의 --migrate 가 안 돌았거나 되돌아간 것**이다."
  say "🔴 **이 파일에는 그것을 고칠 길이 없다**(묶음도 --migrate 도 없다)."
  say "   고치는 길: 55-deploy.sh --migrate · 묶음은 개발 PC 의 _images-52/as-migrations.tar.gz."
  doubt
fi
# 🔴 포털 DB 는 **그대로여야** 한다 — 이 배포가 한 글자도 안 바꾼다.
MIG_AU0=$(mig_count "$AUTH_BOX" "$AUTH_DB")
say "포털 기록 ${MIG_AU0:-?} (기대 $AUTH_MIG_KEEP 그대로)"
if [ -z "${MIG_AU0:-}" ]; then
  bad "포털 DB 를 못 쟀다 — $AUTH_BOX 가 도는지 보세요"
  doubt
elif [ "$MIG_AU0" = "$AUTH_MIG_KEEP" ]; then
  ok "포털이 $AUTH_MIG_KEEP 이다 — **이 배포는 포털 DB 를 안 건드린다**"
else
  bad "🔴 포털이 ${MIG_AU0} 이다 ($AUTH_MIG_KEEP 이어야 한다) — 이 배포는 포털 마이그레이션을 **돌릴 길이 없다**"
  doubt
fi

# ── 2-ㄴ. 🔴 **0124~0126 이 만든 열** — 어느 단계에서나 **다 있어야** 한다 ──
#   🔴 「기록이 127 이다」와 「그 칸과 제약이 정말 있다」는 다른 말이다.
#   🔵 55번은 0125·0126 쪽을 **두 갈래**(--migrate 전/뒤)로 두었다. 🔴 이 판은
#      이미 올라가 있으므로 **한 갈래**다 — 전부 있어야 한다.
printf '\n    ── 0124 가 만든 열 (어느 단계에서나 **다 있어야** 한다)\n'
E1=$(has_enum_value  "$AS_BOX" "$AS_DB" "$AS_ENUM1" "$AS_ENUM_VALUE")
E2=$(has_enum_value  "$AS_BOX" "$AS_DB" "$AS_ENUM2" "$AS_ENUM_VALUE")
NC=$(has_column      "$AS_BOX" "$AS_DB" "$AS_COL_TABLE" "$AS_COL")
I1=$(has_index       "$AS_BOX" "$AS_DB" "$AS_IDX1")
I2=$(has_index       "$AS_BOX" "$AS_DB" "$AS_IDX2")
K0=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_FK")
K1=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_CK1")
K2=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_CK2")
K3=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_CK3")
K4=$(has_constraint  "$AS_BOX" "$AS_DB" "$AS_CK4")
MIG_SEEN=0; MIG_OK=0
for pair in "enum1 $AS_ENUM1 ${E1:-}" "enum2 $AS_ENUM2 ${E2:-}" \
            "col $AS_COL_TABLE.$AS_COL ${NC:-}" \
            "uniq $AS_IDX1 ${I1:-}" "idx $AS_IDX2 ${I2:-}" \
            "fk $AS_FK ${K0:-}" "check1 $AS_CK1 ${K1:-}" \
            "check2 $AS_CK2 ${K2:-}" "check3 $AS_CK3 ${K3:-}" \
            "check4 $AS_CK4 ${K4:-}"; do
  set -- $pair
  MIG_SEEN=$((MIG_SEEN+1))
  printf '      %-7s %-62s %s\n' "$1" "$2" "${3:-못 쟀다}"
  if [ "${3:-0}" = "1" ]; then MIG_OK=$((MIG_OK+1)); fi
done
if [ "$MIG_SEEN" = "10" ]; then ok "0124 가 만든 열을 다 물어봤다 (표본이 비지 않았다)"
else bad "열 중 ${MIG_SEEN}개만 물어봤다 — 목록이 깨졌다"; fi
if [ -z "${MIG_AS0:-}" ]; then
  hm "DB 를 못 쟀으니 열의 기대값을 못 정한다 — **못 쟀다**로 센다"
elif [ "$MIG_OK" = "10" ]; then
  ok "열이 다 있다 — 0124 가 온전하다 (수가 아니라 **값**으로 확인했다)"
else
  bad "🔴 열 중 ${MIG_OK}개만 있다 — **지난 배포가 반만 적용된 상태다.** 멈추고 알리세요"
  say "🔴 이 배포가 만든 일이 아니다. 새 앱($AS_NEW_TAG)도 그 칸을 읽으므로 **그것부터** 봐야 한다."
  doubt
fi

# ── 2-ㄷ. 🔴 **55번(0125·0126)이 만든 열** — 한 갈래다 ───────────────
printf '\n    ── 55번(0125·0126)이 만든 열 아홉 (🔵 어느 단계에서나 **다 있어야** 한다)\n'
N1=$(has_column     "$AS_BOX" "$AS_DB" "$NEW_COL_T1" "$NEW_COL_1")
N2=$(has_column     "$AS_BOX" "$AS_DB" "$NEW_COL_T1" "$NEW_COL_2")
N3=$(has_column     "$AS_BOX" "$AS_DB" "$NEW_COL_T1" "$NEW_COL_3")
N4=$(has_column     "$AS_BOX" "$AS_DB" "$NEW_COL_T1" "$NEW_COL_4")
N5=$(has_column     "$AS_BOX" "$AS_DB" "$NEW_COL_T2" "$NEW_COL_5")
NK1=$(has_constraint "$AS_BOX" "$AS_DB" "$NEW_CK1")
NK2=$(has_constraint "$AS_BOX" "$AS_DB" "$NEW_CK2")
NK3=$(has_constraint "$AS_BOX" "$AS_DB" "$NEW_CK3")
NFK=$(has_constraint "$AS_BOX" "$AS_DB" "$NEW_FK")
NEW_SEEN=0; NEW_OK=0
for pair in "col $NEW_COL_T1.$NEW_COL_1 ${N1:-}" "col $NEW_COL_T1.$NEW_COL_2 ${N2:-}" \
            "col $NEW_COL_T1.$NEW_COL_3 ${N3:-}" "col $NEW_COL_T1.$NEW_COL_4 ${N4:-}" \
            "col $NEW_COL_T2.$NEW_COL_5 ${N5:-}" \
            "check $NEW_CK1 ${NK1:-}" "check $NEW_CK2 ${NK2:-}" "check $NEW_CK3 ${NK3:-}" \
            "fk $NEW_FK ${NFK:-}"; do
  set -- $pair
  NEW_SEEN=$((NEW_SEEN+1))
  printf '      %-6s %-62s %s\n' "$1" "$2" "${3:-못 쟀다}"
  if [ "${3:-0}" = "1" ]; then NEW_OK=$((NEW_OK+1)); fi
done
if [ "$NEW_SEEN" = "9" ]; then ok "아홉을 다 물어봤다 (표본이 비지 않았다)"
else bad "아홉 중 ${NEW_SEEN}개만 물어봤다 — 목록이 깨졌다"; fi
if [ -z "${MIG_AS0:-}" ]; then
  hm "DB 를 못 쟀으니 판정하지 않는다 — **못 쟀다**로 센다"
elif [ "$NEW_OK" = "9" ]; then
  ok "아홉이 **다 있다** — 55번이 올린 0125·0126 이 온전하다"
else
  bad "🔴 아홉 중 ${NEW_OK}개만 있다 — **기록은 $AS_MIG_KEEP 인데 실물이 모자란다.** 멈추고 알리세요"
  say "🔴 이 배포가 만든 일이 아니다 — 55번(쉰두째)부터 다시 봐야 한다."
  doubt
fi
# 🔴 유니크 인덱스의 **칸 수** — 🔵 이번 판은 **언제나 3** 이다.
#    🔴 「있는가」로는 0124 판(칸 둘)과 못 가른다 — 이름이 같다.
IXC=$(index_cols "$AS_BOX" "$AS_DB" "$NEW_IDX")
say "$NEW_IDX 의 키 칸 수: ${IXC:-못 쟀다} (기대 $NEW_IDX_COLS_WANT — 🔵 55번은 2 또는 3 두 갈래였다)"
if [ -z "${MIG_AS0:-}" ]; then
  hm "DB 를 못 쟀으니 인덱스 칸 수를 판정하지 않는다"
elif [ "${IXC:-x}" = "$NEW_IDX_COLS_WANT" ]; then
  ok "유니크 인덱스가 칸 ${NEW_IDX_COLS_WANT}개다 (0126 이 회차 칸을 넣어 다시 만든 그 판이다)"
elif [ "${IXC:-x}" = "2" ]; then
  bad "🔴 유니크 인덱스의 칸이 2개다 — **0126 이 안 돌았거나 되돌아갔다.** 기록만 $AS_MIG_KEEP 이다"
  say "🔴 **이름만 보면 못 가르는 자리다** — 0124 것과 이름이 같다. 칸 수가 증거다."
  doubt
else
  bad "🔴 유니크 인덱스의 칸이 ${IXC:-못 쟀다}개다 — $NEW_IDX_COLS_WANT 를 기대했다"
  doubt
fi
# 🔵 48번이 올린 것도 **아직 있어야** 한다 — 52~55번에서 그대로 가져왔다.
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

# ══════════════════════════════════════════════════════════════════════
# ── 2-ㄹ. 🔴 **「올릴 것이 0건인가」를 값으로 확인한다** (--migrate 대신)
# ══════════════════════════════════════════════════════════════════════
#   🔴 **마이그레이션은 이미지 안이 아니라 볼륨에서 돈다.** 이미지 안만 세면
#      0건으로 조용히 끝난다(39·48·53번이 겪었다). 그래서 **볼륨**을 센다.
#   🔴 **「0건이니까 안 본다」가 아니다** — 그렇게 두면 아무도 안 보는 자리가 된다.
#      다섯을 값으로 잰다: 볼륨 .sql · 볼륨 idx · DB 기록 · 적용 대기 · preflight.
printf '\n== 2-ㄹ. 🔴 마이그레이션 볼륨 — **올릴 것이 0건인가** (--migrate 가 없는 까닭)\n'
printf '%s\n' "🔵 이 판은 **묶음을 안 보낸다.** 운영 볼륨이 이미 $AS_MIG_KEEP 이어야 한다."
printf '%s\n' "🔴 .sql 만으로는 모자라다 — **meta/_journal.json 까지** 본다."
printf '%s\n' "   목록에 없는 .sql 은 drizzle 이 아예 모르고, 적용이 **0건으로 조용히 끝난다.**"
read_migdir
say "$MIGDIR — .sql ${MIG_N_SQL}장 · meta/_journal.json 의 idx ${MIG_N_J}개 (기대 $AS_MIG_KEEP · $AS_MIG_KEEP)"
case "$MIG_STATE" in
  DONE)  ok "볼륨이 $AS_MIG_KEEP 이다 (0125·0126 까지 들어와 있다 — **올릴 것이 없다**)" ;;
  NODIR) bad "🔴 $MIGDIR 폴더가 **없다** — compose 가 $AS_TOOLS_SVC 에 붙이는 그 폴더다"
         doubt ;;
  *)     bad "🔴 볼륨이 .sql ${MIG_N_SQL} · idx ${MIG_N_J} 다 — $AS_MIG_KEEP 이어야 한다"
         say "🔴 **이 파일에는 묶음을 푸는 길이 없다**(--migrate 가 없다)."
         say "🔵 고치는 길: 개발 PC 의 _images-52/as-migrations.tar.gz 를 보내고 55-deploy.sh --migrate."
         cmd "scp -O as-migrations.tar.gz dss-nas:$D/setup/incoming/"
         say "→ 그래도 모르겠으면 고치지 말고 **먼저 알리세요.**"; doubt ;;
esac
# 🔵 두 상수가 이어지는 번호인가 — 한쪽만 고치면 아래 검사가 조용히 빗나간다.
#    🔴 10# 을 붙여 **10진수로 강제**한다. 안 붙이면 0126 이 8진수 86 으로 읽힌다.
if [ "$(printf '%04d' "$((10#$AS_LAST_MIG + 1))")" = "$AS_NEXT_MIG" ]; then
  ok "번호 둘이 이어진다 ($AS_LAST_MIG → $AS_NEXT_MIG)"
else
  bad "🔴 $AS_LAST_MIG · $AS_NEXT_MIG 가 안 이어진다 — 한쪽만 고쳤다"
fi
# 🔴 **볼륨에 0127 이 없는가** — 수만 보면 하나 빠지고 하나 생긴 경우를 못 본다.
if [ "$MIG_STATE" = NODIR ]; then
  hm "$MIGDIR 가 없어 $AS_NEXT_MIG 번을 못 쟀다"
elif ls -1 "$MIGDIR/${AS_NEXT_MIG}_"*.sql >/dev/null 2>&1; then
  bad "🔴 볼륨에 $AS_NEXT_MIG 번이 **있다** — 이 배포는 **$AS_LAST_MIG 까지**를 전제로 쓰였다. 멈추고 알리세요"
  doubt
else
  ok "볼륨에 $AS_NEXT_MIG 번이 없다 (마지막이 $AS_LAST_MIG — **올릴 것이 0건**이 맞다)"
fi
# 🔵 0121~0126 여섯이 온전한가 — 볼륨을 갈아 끼우지 않아도 **온전해야** 한다.
KEEPV_MISS=""
for t in $AS_KEEP_MIGS; do
  ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || KEEPV_MISS="$KEEPV_MISS $t(sql)"
  [ -f "$MIGDIR/meta/${t}_snapshot.json" ]   || KEEPV_MISS="$KEEPV_MISS $t(snapshot)"
done
if [ "$MIG_STATE" = NODIR ]; then
  hm "$MIGDIR 가 없어 0121~0126 을 못 쟀다"
elif [ -z "${KEEPV_MISS:-}" ]; then
  ok "볼륨에 0121~0126 의 .sql 과 meta/*_snapshot.json 이 다 있다"
else
  bad "🔴 볼륨에서 빠진 것:$KEEPV_MISS"
  doubt
fi
# 🔴 **적용 대기 = 볼륨 − 기록.** 순수한 셈이라 한글 grep 에 안 걸린다.
#    🔵 이 한 줄이 「이번 판에는 할 일이 없다」의 **값으로 된 증거**다.
if [ -z "${MIG_AS0:-}" ] || [ "$MIG_STATE" = NODIR ]; then
  hm "적용 대기를 **못 쟀다** (볼륨 ${MIG_N_SQL} · 기록 ${MIG_AS0:-?}) — 사람이 보세요"
else
  PEND=$((MIG_N_SQL - MIG_AS0))
  say "볼륨 ${MIG_N_SQL} - 기록 ${MIG_AS0} = 적용 대기 ${PEND}건 (기대 $AS_PENDING_WANT)"
  if [ "$PEND" = "$AS_PENDING_WANT" ]; then
    ok "적용 대기가 **${AS_PENDING_WANT}건**이다 — 🔵 **이번 판에는 올릴 것이 없다**(셈으로 확인했다)"
  else
    bad "🔴 적용 대기가 ${PEND}건이다 — ${AS_PENDING_WANT}건을 기대했다"
    say "🔴 **이 파일에는 그것을 올릴 길이 없다**(--migrate 가 없다). 55-deploy.sh --migrate 를 쓰세요."
    doubt
  fi
fi
# 🔴 **도구에게 직접 물어본다** — 셈과 다른 길이다. db:preflight 는 읽기만 한다
#    (Dockerfile 의 CMD 가 그것이다 — 「기본값은 읽기만 하는 쪽」).
#    🔵 종료 코드 0 · 대기 0건이어야 한다. 🔴 **종료 코드만 보고 넘기지 않는다** —
#       위 셈과 **두 길이 같은 답**을 내야 한다.
printf '\n    ── 🔴 db:preflight 로 다시 묻는다 (읽기만 한다 · 두 길이 같은 답을 내야 한다)\n'
if [ -n "${AS_TOOLS_L:-}" ]; then
  dct run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | tail -20 | sed 's/^/    /'
  PRC=${PIPESTATUS[0]}
  say "(종료 코드 ${PRC:-?} — 기대 0)"
  if [ "${PRC:-1}" = "0" ]; then
    ok "db:preflight 가 종료 코드 0 이다 (막을 것이 없다 — **올릴 것도 없다**)"
    say "🔵 위 출력에 「적용할 것이 없다」 쪽 문장이 나오는 것이 정상입니다."
    say "🔴 **「살펴볼 문장」이나 「사라질 자료」가 보이면** 볼륨에 새 .sql 이 들어온 것입니다 —"
    say "   이 배포의 전제가 깨진 것이니 **멈추고 알리세요.**"
  else
    bad "🔴 db:preflight 가 ${PRC:-?} 다 — 0 을 기대했다. **볼륨에 밀린 것이 있다는 뜻**이다"
    say "🔴 이 파일에는 그것을 올릴 길이 없다(--migrate 가 없다). 멈추고 알리세요."
    doubt
  fi
else
  hm "compose 에 $AS_TOOLS_SVC 가 없어 db:preflight 를 못 불렀다"
fi

# ── 3. 들여올 이미지 둘 ───────────────────────────────────────────────
printf '\n== 3. 들여올 이미지 둘 (앱 하나 · 도구 하나)\n'
printf '%s\n' "🔵 **셋째 줄(묶음)은 없다** — 이번 판은 마이그레이션이 0건이다."
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
      bad "🔴 $TAR — **잰 값이 이 파일에 없다.** 59-build.sh --go 가 찍어 준 두 줄로 TARS 를 채우세요"
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
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 59-build.sh --go 가 끝에 찍어 주는"
  printf '%s\n' "     **두 줄**로 이 파일의 TARS 두 줄을 통째로 갈아 끼우세요."
fi
# 🔵 되돌릴 길 — 옛 태그가 **NAS 에** 남아 있는가(앱 하나. 도구는 되돌리지 않는다)
for r in $(rows); do
  OLD=$(fld "$r" 5)
  if "$DOCKER" image inspect "$OLD" >/dev/null 2>&1; then ok "$OLD 이 NAS 에 남아 있다 (되돌릴 길)"
  else hm "$OLD 이 NAS 에 없다 — **--rollback 을 못 쓴다.** 되돌릴 일이 생기면 개발 PC 에서 다시 보내야 한다"; fi
done
# 🔴 도구 이미지가 **이미 실려 있으면** 그 자리에서 안을 센다.
if "$DOCKER" image inspect "$AS_TOOLS_NEW" >/dev/null 2>&1; then
  as_tools_inside_check
else
  if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
    hm "$AS_TOOLS_NEW 가 아직 안 실렸다 — **${MODE} 에서는 괜찮다**. 4절이 싣는다"
  else
    say "$AS_TOOLS_NEW 가 아직 안 실렸다 — 4절이 싣는다"
  fi
fi
# 🔴 **앱 이미지도 안을 센다** — 58번이 세워 둔 자리다.
#    🔵 갈아 끼우기 전에 **번들이 이번 판인지** 본다(표식 넷 — 새것 둘 · 뒷걸음 둘).
AS_APP_NEW=$(printf '%s\n' "$(rows)" | grep '^as|' | head -1 | cut -d'|' -f4)
if "$DOCKER" image inspect "$AS_APP_NEW" >/dev/null 2>&1; then
  as_app_inside_check "$AS_APP_NEW"
else
  if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
    hm "$AS_APP_NEW 가 아직 안 실렸다 — **${MODE} 에서는 괜찮다**. 4절이 싣는다"
  else
    say "$AS_APP_NEW 가 아직 안 실렸다 — 4절이 싣는다"
  fi
fi

# 🔴 **재고 관리 통로 — --check 에서 미리 재 둔다.** ? 로만 센다(교체를 막지 않는다).
if [ "$MODE" = check ]; then inventory_gateway_check soft; fi
# 🔴 **이 배포가 바꾸는 자리 — --check 에서도 미리 센다.**
#    🔵 --go 뒤에 다시 세어 **앞뒤가 같은지** 보기 위해서다.
if [ "$MODE" = check ]; then effect_counts; fi
# 🔵 **53번에서 넘어온 할 일 둘도 --check 에서 미리 본다** — 값만 찍는다.
if [ "$MODE" = check ]; then followup_counts; fi

if [ "$MODE" = check ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s   (PHASE=%s)\n' "$PASS" "$FAIL" "$WARN" "$PHASE"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  printf '%s\n' "🔴 다음 차례: --count(앞) → scp tar **둘** → --preload → (다시 --check) → --go → --count(뒤)"
  printf '%s\n' "🔴 **PHASE=PRE 에서 돌리면 ? 가 여럿 나오는 것이 정상**이다 (tar 둘이 아직 없다)."
  printf '%s\n' "🔵 마이그레이션 기록은 **어느 단계에서나 $AS_MIG_KEEP** 입니다 — 이 판은 0건입니다."
  printf '%s\n' "   🔴 **--migrate 모드가 없습니다.** 2-ㄹ 절이 「올릴 것이 0건」을 값으로 확인했습니다."
  printf '%s\n' "🔵 양식은 **올릴 것이 0장**입니다 — 1-ㄷ 절은 「안 바뀌었는가」만 봅니다."
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
  if [ "$LOADED" = "$TARS_WANT" ]; then ok "둘 다 실렸다"
  else bad "🔴 ${LOADED}/$TARS_WANT 개만 실렸다 — TARS 가 비었거나 tar 가 모자란다"; fi
  # 🔴 들여놓자마자 **둘 다** 안을 센다 — 늦게 발견할수록 되돌리기가 비싸다.
  if "$DOCKER" image inspect "$AS_TOOLS_NEW" >/dev/null 2>&1; then as_tools_inside_check
  else bad "🔴 $AS_TOOLS_NEW 가 아직 안 실렸다 — 위 load 가 실패했는지 보세요"; fi
  if "$DOCKER" image inspect "$AS_APP_NEW" >/dev/null 2>&1; then as_app_inside_check "$AS_APP_NEW"
  else bad "🔴 $AS_APP_NEW 가 아직 안 실렸다 — 위 load 가 실패했는지 보세요"; fi
fi

if [ "$MODE" = preload ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **들여놓기만 했다 — 아직 안 갈아 끼웠다.** 다음: --check 를 다시 → --go"
  printf '%s\n' "🔵 **이 배포는 마이그레이션이 0건입니다** — --migrate 단계가 없습니다."
  printf '%s\n' "   🔴 --go 가 compose 의 image: 줄 **둘**(app-as · tools-as)을 한 번에 고칩니다."
  printf '%s\n' "   🔵 DB 는 한 글자도 안 바뀝니다 (기록이 앞뒤 모두 $AS_MIG_KEEP)."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 5. --go / --rollback : compose 의 image: 줄을 바꾼다 ─────────────
#  🔴 --go 는 앱 하나와 도구 하나를 고친다. --rollback 은 **앱만** 되돌린다 —
#     도구는 새 판 그대로 둔다(39·41~58번과 같은 판단).
#  🔴 **app-po · app-auth · tools-auth 줄은 어느 모드에서도 안 건드린다.**
printf '\n== 5. compose 의 image: 줄을 바꾼다\n'
# 🔴 **덤프를 뜬다.** 🔵 이 배포는 DB 를 안 바꾸지만 **갈아 끼우기 전 사진**은 남긴다
#    (52·55번과 같은 판단). 🔵 --rollback 에서는 안 뜬다: 되돌리는 길은 빠를수록 좋다.
if [ "$MODE" = go ]; then
  make_dump "DB 를 안 바꾸지만 갈아 끼우기 전 사진을 남긴다"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 덤프를 못 떴다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi
  # 🔴 **기록이 127 그대로인지 막는다.** 🔵 55번은 여기가 「125 → 127 로 바뀌었나」
  #    였다. **이 판은 「안 바뀌었나」다** — 새 앱이 읽을 칸이 이미 있어야 한다.
  if [ "${MIG_AS0:-x}" != "$AS_MIG_KEEP" ]; then
    bad "🔴 DB 기록이 ${MIG_AS0:-못 쟀다} 다 — **$AS_MIG_KEEP 이어야 --go 할 수 있다.**"
    say "🔴 125 면 **55번(쉰두째) 배포가 덜 끝난 것**입니다 — 그것부터 보세요."
    say "🔴 **이 파일에는 올릴 길이 없습니다**(--migrate 가 없습니다)."
    printf '\n🔴 **아무것도 안 고치고 멈춘다.** 앱은 그대로 옛 판으로 돈다.\n'
    exit 1
  fi
  ok "DB 기록이 $AS_MIG_KEEP 그대로다 (새 앱이 읽을 칸이 이미 있다)"
  # 🔴 **수만 보지 않는다** — 칸이 정말 있는지 셋을 다시 묻는다.
  G1=$(has_column "$AS_BOX" "$AS_DB" "$NEW_COL_T1" "$NEW_COL_1")
  G2=$(has_column "$AS_BOX" "$AS_DB" "$NEW_COL_T1" "$NEW_COL_3")
  G3=$(has_column "$AS_BOX" "$AS_DB" "$NEW_COL_T2" "$NEW_COL_5")
  say "새 앱이 읽을 칸 — $NEW_COL_1 ${G1:-?} · $NEW_COL_3 ${G2:-?} · $NEW_COL_5 ${G3:-?} (셋 다 1)"
  if [ "${G1:-0}" = "1" ] && [ "${G2:-0}" = "1" ] && [ "${G3:-0}" = "1" ]; then
    ok "칸 셋이 실제로 있다 (기록 수가 아니라 **값**으로 확인했다)"
  else
    bad "🔴 칸이 ${G1:-?}·${G2:-?}·${G3:-?} 다 — **기록만 $AS_MIG_KEEP 이고 실물이 없다.** 멈추고 알리세요"
    doubt
    printf '\n🔴 **아무것도 안 고치고 멈춘다.** 앱은 그대로 옛 판으로 돈다.\n'
    exit 1
  fi
fi
# 🔵 1절에서 읽어 둔 상태를 쓴다. **여기서 다시 읽지 않는다** — 두 벌로 읽으면
#    한쪽만 고쳤을 때 조용히 어긋난다.
say "고치기 전 — $AS_SVC $S_APP_AS · $AS_TOOLS_SVC $S_AS_TOOLS (PHASE $PHASE)"
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
#    🔵 **이 판의 --go 는 PRE 에서 둘 · MID 에서 하나**다 (--migrate 가 없어
#       도구 줄을 먼저 고쳐 둘 길이 --rollback 뒤밖에 없다).
WANT_DIFF=0
for r in $(rows); do
  SVC=$(fld "$r" 2); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  if [ "$MODE" = rollback ]; then TO=$OLD; else TO=$NEW; fi
  L=$(img_line "$SVC" 2>/dev/null || true)
  [ -n "${L:-}" ] || continue
  [ "$(tag_at "$L")" = "$TO" ] || WANT_DIFF=$((WANT_DIFF+1))
done
if [ "$MODE" = go ]; then
  L=$(img_line "$AS_TOOLS_SVC" 2>/dev/null || true)
  if [ -n "${L:-}" ]; then
    [ "$(tag_at "$L")" = "$AS_TOOLS_NEW" ] || WANT_DIFF=$((WANT_DIFF+1))
  fi
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

# 🔴 도구는 --go 일 때만 고친다. --rollback 은 **손대지 않는다.**
if [ "$MODE" = go ]; then
  TL=$(img_line "$AS_TOOLS_SVC") || true
  # 🔴 **빈 값도 ✗ 로 센다.** img_line 은 서비스 머리를 못 찾으면 1 을 돌려주지만,
  #    **머리는 찾았는데 image: 줄이 없으면 0 과 빈 값**을 준다. 빈 값을 그냥
  #    건너뛰면 **도구 태그를 안 고치고도 조용히 통과**한다.
  if [ -z "${TL:-}" ]; then
    bad "🔴 $AS_TOOLS_SVC 의 image: 줄을 못 찾았다 — 도구 태그를 못 고쳤다"
    doubt
  fi
  if [ -n "${TL:-}" ]; then
    TNF=$(nf_at "$TL")
    if [ "${TNF:-0}" != "2" ]; then
      bad "🔴 $AS_TOOLS_SVC 의 ${TL}줄이 낱말 ${TNF:-?}개다 — 'image: 태그' 두 낱말만 있어야 한다"
      awk -v n="$TL" 'NR==n' "$CF" | sed 's/^/      /'
      doubt
    else
      TMP=$(mktemp) || exit 1
      awk -v n="$TL" -v to="$AS_TOOLS_NEW" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
      cp "$TMP" "$CF"; rm -f "$TMP"
      TNOW=$(tag_at "$TL")
      if [ "$TNOW" = "$AS_TOOLS_NEW" ]; then ok "$AS_TOOLS_SVC → $AS_TOOLS_NEW (${TL}줄)"; else bad "$AS_TOOLS_SVC 의 태그가 $TNOW 다"; fi
    fi
  fi
else
  say "🔵 도구는 이번 모드($MODE)에서 **안 건드린다** — $AS_TOOLS_NEW 그대로 둔다"
fi

L1=$(wc -l < "$CF"); IMGS1=$(grep -c '^ *image:' "$CF")
grep -n '^ *image:' "$CF" > "$AFT"
DIFFN=$(diff "$BEF" "$AFT" | grep -c '^[<>]' || true)
rm -f "$BEF" "$AFT"
say "줄 수 $L0 → $L1 · image: 줄 $IMGS0 → $IMGS1 · 달라진 image: 줄 $((DIFFN / 2))개"
[ "$L1" = "$L0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
[ "$IMGS1" = "$IMGS0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
# 🔴 **남의 image: 줄을 건드리면 안 된다.** 세어서 정한 수와 같아야 한다.
[ "$((DIFFN / 2))" = "$WANT_DIFF" ] && ok "image: 줄이 꼭 ${WANT_DIFF}개만 달라졌다 (우리 것 · app-po·app-auth·tools-auth 는 안 건드렸다)" \
  || { bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — ${WANT_DIFF}개를 기대했다. 남의 것을 건드렸을 수 있다"; doubt; }
dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 6. 앱 **하나**를 다시 띄운다 ──────────────────────────────────────
#  🔴 도구는 profiles: [tools] 라 up -d 로 띄우지 않는다. 태그만 고쳐 두면
#     다음에 run --rm 으로 부를 때 새 이미지를 쓴다.
#  🔵 **포털은 안 띄운다** — 사내 로그인이 안 멈춘다는 뜻이다.
printf '\n== 6. 앱 하나를 다시 띄운다\n'
printf '%s\n' "🔴 --no-deps 다 — app-as 하나만 갈아 끼운다. 나머지 아홉과 DB 둘은 안 건드린다."
printf '%s\n' "🔵 **포털은 안 뜬다** — 사내 로그인은 안 멈춥니다."
for r in $(rows); do
  CN=$(fld "$r" 3)
  say "$CN 지금: $("$DOCKER" inspect -f '{{.Id}}' "$CN" 2>/dev/null | cut -c1-12)"
done
say "dss-po 지금: $("$DOCKER" inspect -f '{{.Id}}' "$PO_APP_CN" 2>/dev/null | cut -c1-12)  ← 7절에서 **그대로인지** 본다"
say "dss-auth 지금: $("$DOCKER" inspect -f '{{.Id}}' "$AUTH_APP_CN" 2>/dev/null | cut -c1-12)  ← 7절에서 **그대로인지** 본다"
PO_ID0=$("$DOCKER" inspect -f '{{.Id}}' "$PO_APP_CN" 2>/dev/null)
AUTH_ID0=$("$DOCKER" inspect -f '{{.Id}}' "$AUTH_APP_CN" 2>/dev/null)
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

# 🔴 **PO 와 포털이 그대로 도는가** — 이번 판에서 안 건드렸다는 증거다.
#    🔴 **set -- 로 쪼개지 않는다.** 상자 번호가 빈 값이면 낱말이 하나 줄어 뒤의
#       것이 앞으로 밀리고, 그러면 **엉뚱한 값끼리 맞대어 보게 된다.** 인자를
#       이름으로 받는 함수로 둔다.
untouched_box_check() { # 1 컨테이너 2 호스트 포트 3 교체 전 상자 번호(빈 값일 수 있다)
  local cn port id0 id1 run code
  cn=$1; port=$2; id0=${3:-}
  id1=$("$DOCKER" inspect -f '{{.Id}}' "$cn" 2>/dev/null)
  run=$("$DOCKER" inspect -f '{{.Config.Image}}' "$cn" 2>/dev/null)
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$port/" 2>/dev/null)
  say "$cn — 이미지 ${run:-?} · 127.0.0.1:$port → ${code:-없음}"
  if [ -z "${id0:-}" ]; then
    hm "$cn 의 **교체 전 상자 번호를 못 읽었다** — 그대로인지 맞대어 볼 수 없다. 사람이 보세요"
  elif [ "$id0" = "${id1:-}" ]; then
    ok "$cn 가 **그대로다**(상자 번호가 안 바뀌었다 — 안 건드렸다)"
  else
    hm "$cn 의 상자 번호가 달라졌다 (${id0:0:12} -> ${id1:0:12}) — 안 건드렸어야 한다. 사람이 보세요"
  fi
  printf '%s' "$code" | grep -qE '200|30[1237]' && ok "$cn 가 응답한다 ($code)" \
    || bad "$cn 응답이 ${code:-없음}"
}
untouched_box_check "$PO_APP_CN"   "$PO_PORT"   "${PO_ID0:-}"
untouched_box_check "$AUTH_APP_CN" "$AUTH_PORT" "${AUTH_ID0:-}"

# 🔴 DB — 기록이 **127 그대로**인가 (앱 교체가 DB 를 건드릴 일은 없다)
#    🔵 --rollback 에서도 127 이다 — **이 배포는 DB 를 애초에 안 바꾼다.**
MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
say "A/S 마이그레이션 ${MIG_AS0:-?} -> ${MIG_AS1:-?} (기대 $AS_MIG_KEEP · **앞뒤가 같아야 한다**)"
[ "${MIG_AS1:-x}" = "$AS_MIG_KEEP" ] && ok "$AS_MIG_KEEP 다 (이 단계가 DB 를 한 글자도 안 바꿨다)" \
  || bad "🔴 ${MIG_AS1:-?} 다 — $AS_MIG_KEEP 여야 한다. **DB 가 그 사이에 움직였다**"
MIG_AU1=$(mig_count "$AUTH_BOX" "$AUTH_DB")
say "포털 마이그레이션 ${MIG_AU0:-?} -> ${MIG_AU1:-?} (기대 $AUTH_MIG_KEEP)"
[ "${MIG_AU1:-x}" = "$AUTH_MIG_KEEP" ] && ok "포털이 $AUTH_MIG_KEEP 그대로다 (안 건드렸다)" \
  || bad "🔴 포털이 ${MIG_AU1:-?} 다 — $AUTH_MIG_KEEP 그대로여야 한다"
# 🔴 **0124~0126 이 만든 것이 아직 있는가** — 새 앱이 읽고 **쓴다.**
NC=$(has_column     "$AS_BOX" "$AS_DB" "$AS_COL_TABLE" "$AS_COL")
E1=$(has_enum_value "$AS_BOX" "$AS_DB" "$AS_ENUM1" "$AS_ENUM_VALUE")
I1=$(has_index      "$AS_BOX" "$AS_DB" "$AS_IDX1")
say "0124 의 칸 ${NC:-?} · enum ${E1:-?} · 유니크 인덱스 ${I1:-?} (셋 다 1 이어야 한다)"
if [ "${NC:-0}" = "1" ] && [ "${E1:-0}" = "1" ] && [ "${I1:-0}" = "1" ]; then
  ok "0124 가 만든 것이 그대로 있다 — **앱이 읽을 칸이 있다**"
else
  bad "🔴 0124 의 칸·enum·인덱스가 ${NC:-?}·${E1:-?}·${I1:-?} 다 — **앱이 그 자리에서 깨진다**"
  doubt
fi
V1=$(has_column "$AS_BOX" "$AS_DB" "$NEW_COL_T1" "$NEW_COL_1")
V2=$(has_column "$AS_BOX" "$AS_DB" "$NEW_COL_T1" "$NEW_COL_2")
V3=$(has_column "$AS_BOX" "$AS_DB" "$NEW_COL_T1" "$NEW_COL_3")
V4=$(has_column "$AS_BOX" "$AS_DB" "$NEW_COL_T1" "$NEW_COL_4")
V5=$(has_column "$AS_BOX" "$AS_DB" "$NEW_COL_T2" "$NEW_COL_5")
VIX=$(index_cols "$AS_BOX" "$AS_DB" "$NEW_IDX")
say "55번의 칸 — $NEW_COL_1 ${V1:-?} · $NEW_COL_2 ${V2:-?} · $NEW_COL_3 ${V3:-?} · $NEW_COL_4 ${V4:-?} · $NEW_COL_5 ${V5:-?}"
say "유니크 인덱스 키 칸 수 ${VIX:-?} (기대 $NEW_IDX_COLS_WANT)"
if [ "${V1:-0}" = "1" ] && [ "${V2:-0}" = "1" ] && [ "${V3:-0}" = "1" ] && [ "${V4:-0}" = "1" ] && [ "${V5:-0}" = "1" ]; then
  ok "0125·0126 이 만든 칸 다섯이 다 있다 — **새 앱이 납품일·회차를 쓸 자리가 있다**"
else
  bad "🔴 칸이 ${V1:-?}·${V2:-?}·${V3:-?}·${V4:-?}·${V5:-?} 다 — **새 앱이 그 자리에서 깨진다**"
  doubt
fi
[ "${VIX:-x}" = "$NEW_IDX_COLS_WANT" ] && ok "유니크 인덱스가 칸 ${NEW_IDX_COLS_WANT}개다 (회차마다 승인 요청이 하나씩 설 수 있다)" \
  || { bad "🔴 유니크 인덱스의 칸이 ${VIX:-못 쟀다}개다 — $NEW_IDX_COLS_WANT 를 기대했다"; doubt; }

# 🔴 **양식을 다시 잰다** — 교체 뒤에도 그대로인지, 그리고 **새 앱이 보는지.**
templates_check
# 🔵 **공유폴더 둘을 다시 잰다** — 🔵 이번 판이 안 건드리지만 **앱을 갈아 끼운 뒤에도**
#    열리는지는 봐야 한다(볼륨은 컨테이너를 다시 띄울 때 다시 붙는다).
purchase_order_archive_check
quote_archive_check
# 🔴 **PO 권한을 다시 잰다** — 앱을 안 갈아 끼웠으니 답이 같아야 하지만, **같은지를 봐야** 안다.
po_write_privilege_check soft

# 🔴 도구 태그가 제대로 섰는지 + 이미지 안이 온전한지 다시 센다
TL=$(img_line "$AS_TOOLS_SVC" 2>/dev/null || true)
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  # 🔵 --go 도 --rollback 도 도구 기대값은 **새 판으로 같다** — 되돌려도 그대로 둔다.
  [ "$TCUR" = "$AS_TOOLS_NEW" ] && ok "$AS_TOOLS_SVC 가 $AS_TOOLS_NEW 다" \
    || bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $AS_TOOLS_NEW 를 기대했다"
  "$DOCKER" image inspect "$TCUR" >/dev/null 2>&1 && ok "$TCUR 이미지가 NAS 에 있다" \
    || bad "$TCUR 이미지가 NAS 에 없다 — 다음에 부를 때 못 쓴다"
else
  bad "compose 에 $AS_TOOLS_SVC 이 없다"
fi
# 🔵 포털 도구는 **안 건드렸다** — 그대로인지만 본다.
ATL=$(img_line "$AUTH_TOOLS_SVC" 2>/dev/null || true)
if [ -n "${ATL:-}" ]; then
  ATC=$(tag_at "$ATL")
  [ "$ATC" = "$AUTH_TOOLS_KEEP" ] && ok "$AUTH_TOOLS_SVC 가 $AUTH_TOOLS_KEEP 그대로다 (안 건드렸다)" \
    || hm "$AUTH_TOOLS_SVC 가 $ATC 다 — $AUTH_TOOLS_KEEP 를 기대했다. 사람이 보세요"
else
  bad "compose 에 $AUTH_TOOLS_SVC 가 없다"
fi
if [ "$MODE" = go ]; then as_tools_inside_check; fi
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
[ "$KEEP_SEEN" = "$KEEP_BOXES_WANT" ] && ok "안 건드린 아홉을 다 봤다 (표본이 비지 않았다)" \
  || bad "안 건드린 상자를 ${KEEP_SEEN}개만 봤다 — ${KEEP_BOXES_WANT}개를 기대했다. KEEP_BOXES 가 깨졌다"
# 🔴 **dss-auth 가 이 목록에 있는가** — 이번 판은 포털을 안 건드린다.
if printf '%s\n' "$KEEP_BOXES" | tr ' ' '\n' | grep -qx 'dss-auth'; then
  ok "KEEP_BOXES 에 dss-auth 가 있다 (이번 판은 포털을 **안 건드린다**)"
else
  bad "🔴 KEEP_BOXES 에 dss-auth 가 없다 — **이번 판은 포털을 안 건드린다**"
  doubt
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

# 🔴 **이 배포가 바꾸는 자리를 다시 센다** — 🔵 **앞뒤가 같아야** 정상이다.
if [ "$MODE" = go ]; then effect_counts; fi
# 🔵 **53번에서 넘어온 할 일 둘을 값으로 다시 센다** — 판정하지 않는다.
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
  printf '%s\n' "🔵 **DB 를 한 글자도 안 바꿨습니다** — 마이그레이션 기록이 앞뒤 모두 $AS_MIG_KEEP."
  printf '%s\n' "   🔵 묶음도 안 보냈고 --migrate 모드도 없습니다. 볼륨도 그대로입니다."
  printf '%s\n' "🔵 **백필·이관 도구는 돌릴 까닭이 없습니다** — 이번 판은 **자료를 안 고칩니다.**"
  printf '%s\n' "   🔴 다만 **「화면만 고쳤다」가 아닙니다** — 58번과 정반대입니다. 바뀐 열 장이"
  printf '%s\n' "      **전부 src/lib/ 아래**(서버 쪽)이고, 바뀐 것이 **종 알림 조회의 WHERE** 입니다."
  printf '%s\n' "   🔵 그래서 **브라우저 캐시 때문에 안 보일 일은 없습니다**(서버가 그립니다)."
  printf '%s\n' ""
  printf '%s\n' "🔴 **도구 이미지 안의 엑셀 읽개 둘은 NAS 에서 돌리지 마세요**(이번 판이 만든 것이 아닙니다)."
  printf '%s\n' "   scripts/import-technical-task-procedures.ts ·"
  printf '%s\n' "   scripts/link-technical-task-next-procedures.ts 는 이미지에 들어 있지만,"
  printf '%s\n' "   둘 다 **개발 DB 게이트**를 지나야 돌고 그 게이트는 루프백 5442 만 통과시킵니다."
  printf '%s\n' "   🔴 **npm 명령도 아닙니다** — npm run 으로 부르면 Missing script 가 납니다."
  printf '%s\n' ""
  if [ "$MODE" = go ]; then
    printf '%s\n' "══════════════════════════════════════════════════════════════"
    printf '%s\n' "🔴 **지금 바로 할 일**"
    printf '%s\n' "══════════════════════════════════════════════════════════════"
    printf '%s\n' "  🔴 **올린 뒤의 수로 다시 돌립니다.**"
    printf '%s\n' "       bash $0 --count"
    printf '%s\n' "     🔵 다섯 도구와 **이 배포가 바꾸는 자리**를 함께 셉니다."
    printf '%s\n' "     🔴 **다섯 도구는 앞뒤가 같아야 정상입니다** — 이번 판이 안 건드립니다."
    printf '%s\n' "     🔴 **종 줄 수도 앞뒤가 거의 같아야 정상입니다** — 자료를 한 줄도 안 건드립니다."
    printf '%s\n' "        🔵 다만 **7일 창은 시간이 가면 움직입니다** — 그 사이에 결재가 하나 나거나"
    printf '%s\n' "           7일이 지난 건이 빠지면 수가 달라질 수 있습니다."
    printf '%s\n' "     🔴 **④(새로 뜨는 줄)와 ⑥(안 떠야 할 반려 줄)을 적어 두세요** — 아래 눈 확인에서"
    printf '%s\n' "        그 두 수를 맞대어 봅니다."
    printf '%s\n' "══════════════════════════════════════════════════════════════"
    printf '%s\n' ""
  fi
  printf '%s\n' "🔴 **마지막은 눈입니다** — 🔴 **이번 판은 거의 안 보입니다.**"
  printf '%s\n' "   🔵 커밋 **하나**이고, 눈에 보이는 것은 **설정 화면의 설명 글자 한 줄**과"
  printf '%s\n' "      **종에 서는 줄**뿐입니다. 58번과 가장 다른 점이 여기입니다."
  printf '%s\n' ""
  printf '%s\n' "  ── A. 🔵 설정 화면의 설명 글자 (**가장 빨리 확인되는 곳**) ──"
  printf '%s\n' "  ① [사용자 관리] › [알림 설정] › **「승인 완료」**의 설명을 보세요."
  printf '%s\n' "     「… 요청한 사람 본인과 **영업·관리자·최고관리자에게 가고(2026-11-12)**, …」"
  printf '%s\n' "     로 바뀌어 있어야 합니다. 🔵 전에는 「요청한 사람 본인에게만 가고」였습니다."
  printf '%s\n' "  ② 🔴 **바로 아래 「반려됨」의 설명은 그대로** 「요청한 사람 본인에게만 가고」입니다."
  printf '%s\n' "     🔴 **둘이 달라 보이는 것이 정상입니다** — 빠뜨린 것이 아닙니다."
  printf '%s\n' ""
  printf '%s\n' "  ── B. 🔴 종에 줄이 더 서는가 ───────────────────────────────"
  printf '%s\n' "  ③ **영업 · 관리자 · 최고관리자 계정으로 로그인해 종을 누르세요.**"
  printf '%s\n' "     **남이 올린 결재의 「승인 완료」**도 떠야 합니다(전에는 자기가 올린 것만)."
  printf '%s\n' "     🔵 지난 7일 안에 **최종 승인**으로 끝난 건만 뜹니다."
  printf '%s\n' "     🔵 **내가 결재한 건은 내 종에 안 뜹니다** — 자기가 한 일을 자기에게 알리지 않습니다."
  printf '%s\n' "     🔵 몇 줄이 설지는 **--count 의 ④** 가 세어 둡니다(사람 × 줄을 다 더한 수입니다)."
  printf '%s\n' "  ④ 🔵 **엔지니어·재고 담당자 계정은 그대로**입니다 — 자기가 올린 결재의 결과만 뜹니다."
  printf '%s\n' ""
  printf '%s\n' "  ── C. 🔴 **안 바뀐 쪽이 조용히 바뀌지 않았는가** (가장 놓치기 쉽습니다) ──"
  printf '%s\n' "  ⑤ 🔴 같은 종에서 **「반려됨」**을 보세요. **남이 올린 반려는 떠서는 안 됩니다** —"
  printf '%s\n' "     반려는 **요청자 본인에게만** 가는 것이 이 판의 결정입니다(일부러 안 넓혔습니다)."
  printf '%s\n' "     🔵 --count 의 **⑥** 이 「안 떠야 할 줄」의 수입니다. 그 줄이 하나라도 남의 건으로"
  printf '%s\n' "        떠 있으면 **멈추고 알리세요.**"
  printf '%s\n' ""
  printf '%s\n' "  🔴 **「아무것도 안 바뀐 것 같다」가 가장 그럴듯한 판입니다.**"
  printf '%s\n' "     🔵 그때는 A 의 설명 글자를 보세요 — 그것이 바뀌었으면 새 판이 돌고 있는 것입니다."
  printf '%s\n' "     🔵 종에 줄이 안 늘었다면 **--count 의 ④ 가 0** 이었는지 먼저 보세요(지난 7일 안에"
  printf '%s\n' "        남이 올린 결재의 최종 승인이 없었다는 뜻이고, 배포 잘못이 아닙니다)."
  printf '%s\n' "     🔵 그래도 안 뜨면 **--count 의 ⑦**(알림 설정 스위치)을 보세요 — 영업·관리자 칸이"
  printf '%s\n' "        꺼져 있으면 코드가 맞아도 한 줄도 안 뜹니다."
  printf '%s\n' ""
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "🔴 **알고도 안 고친 것 — PO 가 모르는 것이 셋입니다**(55번에서 넘어옴)"
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "  ① **APPROVAL_REQUIRED** — dss-po:0.9 가 그 거절 코드를 모릅니다."
  printf '%s\n' "  ② **납품일 칸 둘** — delivered_date·delivered_by 를 PO 는 모릅니다."
  printf '%s\n' "  ③ **회차 승인** — due_date_row_order 를 모른 채 PO 가 같은 표를 고칩니다."
  printf '%s\n' "  🔵 **자료는 안 깨집니다** — A/S 는 한 글자도 안 쓴 채 거절합니다."
  printf '%s\n' "  🔵 **지금은 실질적으로 닫혀 있습니다** — 운영에서 직원의 PO 접근 권한을"
  printf '%s\n' "     모두 빼 두셨습니다(2026-11-08)."
  printf '%s\n' "  🔴 **PO 를 다시 여는 날 셋을 한 묶음으로 이식해야 합니다.**"
  printf '%s\n' ""
  printf '%s\n' "  🔵 **아무것도 안 바뀐 것처럼 보이면** 앱이 정말 새 태그로 도는지(위 7절) 먼저"
  printf '%s\n' "     보시고, 맞다면 알려 주세요."
  printf '%s\n' "     🔵 이번 판은 바뀐 것이 **전부 서버 쪽**이라 브라우저 캐시 탓은 아닙니다 —"
  printf '%s\n' "        그래도 설명 글자가 옛 문장으로 보이면 Ctrl+F5 를 한 번 해 보세요."
  printf '%s\n' ""
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (app-as 만 되돌립니다)"
  printf '%s\n' "  🔵 도구는 $AS_TOOLS_NEW 그대로 둡니다."
  printf '%s\n' "  🔵 **DB 는 되돌릴 것이 없습니다** — 이 배포가 DB 를 애초에 안 바꿨습니다."
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
  printf '%s\n' "  🔵 ✗ 가 **재고 관리 통로** 하나뿐이라면 되돌리기 전에 설정을 먼저 보세요 —"
  printf '%s\n' "     INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN (env/as.env). 🔴 되돌려도 같은"
  printf '%s\n' "     설정 문제는 남습니다 — 옛 판도 같은 통로를 씁니다."
  printf '%s\n' "  🔴 ✗ 가 **PO 의 repair_cases 쓰기 권한**이라면 그것은 **이 배포가 만든 일이**"
  printf '%s\n' "     **아닙니다**(PO 를 안 건드립니다). 되돌려도 안 고쳐집니다 — 사람이 봐야 합니다."
  printf '%s\n' "  🔴 ✗ 가 **양식**이라면 되돌리지 마세요 — 이 배포는 양식을 한 장도 안 건드립니다."
  printf '%s\n' "  🔴 ✗ 가 **발주서·견적서 공유폴더**라면 되돌려도 안 고쳐집니다 — 볼륨·권한 문제입니다."
  printf '%s\n' "     🔵 **이 배포와는 무관합니다** — 이번 판은 디스크를 아예 안 봅니다."
  printf '%s\n' "        다만 **지난 판이 올린 기능이 지금 고장나 있다**는 뜻이라 사람이 봐야 합니다."
  printf '%s\n' "  🔵 **DB 는 건드릴 것이 없습니다** — 이 배포가 DB 를 한 글자도 안 바꿨습니다."
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
