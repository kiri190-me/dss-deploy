#!/bin/bash
# dss-deploy/nas/setup/60-deploy.sh — 쉰여섯째 배포 (2026-11-12)
#
# 🔵 **배포 회차(쉰여섯째)와 파일 번호(60)가 어긋나는 것은 이 저장소에서 원래
#    그렇다** — 55번 파일이 쉰두째였고, 57번이 쉰세째, 58번이 쉰네째,
#    59번이 쉰다섯째였다. (56번은 2026-11-11 의 **양식 전용**이라 안 셌다.)
#
# 🔵 **판이 5.1 → 5.2 로 하나 는다.** 도구는 18 → 19.
#
# 🔴 NAS 에서 돈다. **DSM 터미널은 긴 명령을 잘라 먹는다**(2026-10-12 하루에 네
#    번 깨졌다). 그래서 손으로 치지 않고 **파일로 올려** 돌린다. 절차는 이렇다:
#      ① (개발 PC · PowerShell) — 🔴 **경로는 빗금으로**
#           cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#           scp -O 60-deploy.sh dss-nas:/volume1/dss/setup/
#           Get-FileHash -Algorithm MD5 60-deploy.sh
#      ② (NAS) md5sum /volume1/dss/setup/60-deploy.sh
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
# 🔴 **59-deploy.sh 에서 베꼈다가 「이번 판엔 거짓」이라 뒤집은 것 열둘**
# ══════════════════════════════════════════════════════════════════════
#   틀과 절 구성은 59-deploy.sh(쉰다섯째)를 그대로 썼다. 🔴 **그런데 전제가
#   크게 다르다.** 59번은 커밋 1 · 파일 10 · 새 파일 0 · scripts/ 0 ·
#   마이그레이션 0건이었고, **이번 판은 그 다섯이 전부 뒤집힌다.**
#   🔴 **「0개」가 기대값이던 절 셋**을 그대로 베끼면 멀쩡한 판이 세 자리에서 ✗ 다.
#   🔴 「배포본은 지난 판의 전제를 업고 온다」가 이 저장소에 기록된 함정이다.
#   🔵 아래에 적은 「59번은 ~였다」는 **59-deploy.sh 를 직접 열어 확인한 것만**이다.
#      그 파일에 없던 말은 아예 안 적었다 — 틀린 설명은 없는 설명보다 나쁘다.
#
#   ① 🔵 **판이 5.1 → 5.2 · 도구 18 → 19.** 59번은 5.0 → 5.1 · 17 → 18 이었다.
#   ② 🔴 **되돌릴 판이 dss-as:5.1 이다**(59번이 올린 그것).
#   ③ 🔴 **덤프 이름이 v56 이다.** 🔴 **59번이 남긴 숙제가 여기다** — 그 파일은
#      compose 사본을 …yml.v55-… 로 뜨면서 **덤프만 dss_as-v54-… 로** 만들었다
#      (make_dump() 안의 DUMP 변수를 안 고친 것이다). 그래서 어느 배포의 사진인지
#      이름으로 못 가린다. 🔵 dss-deploy/README.md 의 쉰다섯째 절에 그 사실이 적혀
#      있다. **이번 판에서 둘을 v56 으로 맞췄다.**
#   ④ 🔴 **--migrate 모드를 되살렸다.** 59번은 「0건이라 헷갈린다」고 없앴고,
#      치면 까닭을 찍고 거절하게 해 두었다. 🔴 **이번 판은 마이그레이션이 1건**
#      이므로 그 모드가 없으면 **올릴 길이 아예 없다.**
#      🔵 되살린 본보기는 **55-deploy.sh**(마지막으로 --migrate 가 있던 판)의
#         place_migs() · check_keep_migs() · 4-ㄴ 절이다.
#      🔴 **묶음(as-migrations.tar.gz)을 보낸다** — 재 보고 정했다:
#         도구 이미지의 /app/drizzle 은 **비어 있고**(Dockerfile 의 tools 스테이지가
#         drizzle/ 을 안 담는다), 운영은 거기에 볼륨을 붙인다. **마이그레이션은
#         이미지 안이 아니라 볼륨에서 돈다** — 묶음을 안 보내면 볼륨이 127 그대로라
#         적용이 0건으로 조용히 끝난다(39·48·53번이 겪었다).
#   ⑤ 🔴 **마이그레이션 기대값이 두 갈래다** — 127(적용 전) · 128(적용 뒤).
#      🔴 59번은 「어느 단계에서나 127 한 갈래」였다. 그 글을 베껴 두면 **적용 뒤에
#         가짜 ✗** 가 난다(48번이 데인 그 자리다).
#   ⑥ 🔴 **MID 의 뜻이 되돌아왔다.** 59번은 --migrate 가 없어 MID 를
#      「--go 뒤에 --rollback 으로 앱만 되돌린 상태」로 읽었다. 🔴 **이 판에서
#      MID 는 다시 「--migrate 까지 돌았다」**가 1순위다(55번과 같다).
#   ⑦ 🔴 **도구 이미지 안 검사의 ③번 목록이 79개다.** 59번은 **10개**였고
#      「전부 src/」였다. 🔴 **이번 판은 src/ 77 + scripts/ 2** 다 — 그 수를 그대로
#      두면 **멀쩡한 판이 ✗** 다.
#   ⑧ 🔴 **「새 파일 0개」를 「새 시험 여덟이 등록돼 있는가」로 바꿨다.** 59번은
#      새 파일이 0개라 「고친 시험 여섯이 **이미** 등록돼 있는가」를 재고 있었다.
#      🔴 **이번 판에는 새 시험이 여덟 장**이다 — 그 여섯 경로를 그대로 두면
#      여섯 다 no 가 나와 **가짜 ✗** 다.
#   ⑨ 🔴 **「scripts/ 가 0개인가」 절을 뒤집었다.** 59번은 **1 이상이면 ✗** 였다.
#      🔴 **이번 판은 2 가 정답**이다 — 그 절을 그대로 두면 멀쩡한 판이 ✗ 다.
#   ⑩ 🔴 **표식을 전부 갈았다.** 59번의 여섯
#      (APPROVAL_GRANTED_BROAD_RECIPIENT_ROLES · receivesOthersApprovalGrantedOutcomes ·
#      includeOtherRequesters · 2026-11-12 × 2 …)은 **이번 판이 하나도 안 건드린다** —
#      그대로 두면 **옛 판에서도 전부 ✓** 인 죽은 검사가 된다.
#      🔴 그리고 **앱 번들 표식도 갈았다.** 59번은 APP_MARK 가 2026-11-12 였는데,
#         그 글자는 **기준판 1259d822 의 src/ 에 이미 10파일** 있다(59번이 넣었다).
#         번들 표식은 「기준판에 0」이어야 서므로 **못 쓴다.**
#   ⑪ 🔴 **뒷걸음 방지가 둘 → 셋이 됐다.** 59번은 status=IN_HOUSE(쉰네째)와
#      no-equipment-key(쉰세째) 둘을 지켰다. **쉰다섯째(59번)가 올린 글자**를 보탰다.
#   ⑫ 🔴 **--count 의 effect_counts() 를 통째로 갈았다.** 59번은 **종 줄 수**
#      (영업·관리자·최고관리자가 받게 될 「승인 완료」 줄)를 셌다 — 🔴 **그 수는
#      이번 판과 아무 상관이 없다.** 그대로 두면 **이 배포를 재는 숫자가 하나도
#      없다.** 이번 판이 재는 것은 아래 「--count 가 세는 것」이다.
#
#   ── 🔵 **59번과 같아서 안 뒤집은 것 다섯** (그래도 값으로 다시 잰다)
#      · 양식 **0장** · 포털·PO **안 건드린다** · 공유폴더 **안 건드린다**
#      · 되돌리기는 **앱만** 되돌린다(도구는 새 판 그대로)
#      · 안 건드리는 아홉 · DB 둘이 안 멈춘다
#      🔴 같다고 절을 지우지 않았다. 「0장·안 건드림」은 **이번 판에서도 참인지
#         재야** 참이다.
#
#   갈아 끼우는 것 — **저장소 하나, 태그 둘**
#     ① A/S 앱    dss-as:5.1        → **dss-as:5.2**
#     ② A/S 도구  dss-as-tools:18   → **dss-as-tools:19**
#
#   🔵 **안 건드리는 아홉** — 포털 · 재고 · 계측기 · 게시판 · 개선요청 · 휴가 ·
#      통합 승인함 · RF 이슈관리 · PO.
#   🔵 **양식(.xlsx)은 한 장도 안 올린다.** 이번 범위에 .xlsx 변경이 0줄이다.
#      🔴 **양식이 바뀌는 날 되살릴 곳**: 51-deploy.sh 의 1056~1172줄
#         (--templates-prep) · 1174~1341줄(--templates-apply).
#      🔵 다만 **재는 쪽은 남겼다** — 1-ㄷ 절이 운영 양식 열하나를 md5 로 잰다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **--migrate 모드가 되살아났다** — 59번과 가장 크게 다른 자리다
# ══════════════════════════════════════════════════════════════════════
#   이번 판은 마이그레이션이 **1건**이다: drizzle/0127_domestic_order_permission_leaves.sql.
#
#   🔴 **무엇을 하는가** — 표를 **한 칸도 안 바꾼다.** INSERT ... SELECT **넷**뿐이고
#      전부 ON CONFLICT DO NOTHING 이다. 옮기는 것은 role_permissions 의 area_key
#      하나다: 옛 'domesticOrders' 행을 **잎 넷**(.view · .edit · .lifecycle ·
#      .approval)으로 **사다리를 펼쳐** 옮긴다.
#      🔵 drizzle-kit 이 이 판에서 「No schema changes」라고 답했다(2026-11-12 실측).
#
#   🔴 **왜 필요한가** — 그 전까지 domesticOrders 는 하위 기능이 없어 **메뉴 키
#      자체가 저장되는 잎**이었다. 이번 판이 잎 넷으로 쪼개면서 메뉴 키는 더 이상
#      잎이 아니다. 그냥 두면 옛 행은 읽는 쪽(queries/role-permissions.ts 의
#      isPermissionLeafKey)에서 **통째로 버려지고**, 그 역할은 **오류 한 줄 없이
#      조용히** 코드 기본값으로 되돌아간다. 같은 표의 inventory.stock 행이 그렇게
#      죽어 있는 실물이다.
#
#   🔴 **운영에서 옮길 행이 0건일 수 있다**(2026-11-12 실측:
#      area_key in ('domesticOrders','miscCases','quotes') → **0 rows**).
#      🔵 판은 0건이어도 **조용히 통과한다** — INSERT ... SELECT 라 원본이 0행이면
#         0행을 넣고 끝난다. 🔴 **그래도 배포 직전에 다시 센다** — 그 사이에 누가
#         권한 화면에서 저장하면 행이 생긴다. 2-ㅁ 절과 --count 가 그 수를 잰다.
#      🔵 개발 DB 에는 1행이 있었고 **이미 적용해** 옮겨진 것을 확인했다.
#
#   🔴 **묶음(as-migrations.tar.gz)을 보낸다.** 재 보고 정했다:
#      · 도구 이미지의 /app/drizzle 은 **비어 있다**(Dockerfile 의 tools 스테이지가
#        drizzle/ 을 안 담는다 — 60-build.sh 의 5절-ㄱ 이 그것을 값으로 확인한다).
#      · 운영은 거기에 /volume1/dss/as-migrations 를 붙인다.
#      → **마이그레이션은 이미지 안이 아니라 볼륨에서 돈다.** 묶음을 안 보내면
#        볼륨이 127 그대로라 **적용이 0건으로 조용히 끝난다**(39·48·53번).
#      🔵 _images-52 의 옛 묶음(127장)은 **쓰면 안 된다** — 0127 이 없다.
#
#   🔴 **db:preflight 로 「사라지는 자료가 없다」를 먼저 확인한다.** 개발에서 이렇게
#      나왔다(2026-11-12):
#        전체 마이그레이션 128건 · 적용 대기 1건
#        [0127_domestic_order_permission_leaves] 더하기만 합니다 — 사라지는 자료 없음
#      🔴 종료 코드가 0 이 아니면 **DB 를 안 건드리고 멈춘다.**
#
#   🔴 **되돌리는 법**(이 판을 물릴 때 손으로 돌린다 — 자동으로 안 한다):
#        DELETE FROM "role_permissions"
#         WHERE "area_key" IN ('domesticOrders.view', 'domesticOrders.edit',
#                              'domesticOrders.lifecycle', 'domesticOrders.approval');
#      옛 domesticOrders 행이 **그대로 남아 있으므로** 그 한 문장이면 이사 전 상태다.
#      🔴 **코드도 함께 되돌려야 한다** — 잎이 코드에 남은 채 행만 지우면 그 역할은
#         기본값으로 돈다(좁혀 둔 설정이 풀린다).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이번 판이 운영에 들고 가는 것 — **커밋 다섯 · 권한이 잘게 쪼개진다**
# ══════════════════════════════════════════════════════════════════════
#   ① 3442f755 [전체 A/S 현황]의 [현재 상태] 거르개에 **[최종 출하 승인 완료]**
#      선택지가 생긴다. 🔵 상태 열둘 **뒤**에 붙고, 다른 상태와 함께 고르면 **OR** 다.
#      🔵 판정 근거는 이 건의 칸이 아니라 **다른 표의 최신 결재 행과 판 번호**다.
#   ② 85aed373 [역할별 접근 권한]의 **왼쪽 목록이 메뉴 묶음·차례대로** 선다.
#      🔵 묶음 머리말 다섯 · 주간보고가 하위메뉴로 들여써짐 · 맨 아래
#         **[메뉴에 없는 항목]**(재고 관리가 거기 간다).
#   ③ 774ef54c **수리건 상세 탭 여덟에 권한 관문** — 화면과 서버 둘 다.
#      🔴 **주소를 직접 쳐도 막힌다**(탭마다 제 page.tsx 가 서버에서 다시 본다).
#      🔵 [기본 정보]는 여덟을 전부 닫아도 남는다.
#      🔵 **기본값이 지금과 같다** — 배포 직후 아무도 못 보게 되는 일은 없다.
#   ④ f7d095f7 **[내자 정리] 권한이 1칸 → 4칸** + 기타건 상세 탭 둘을 가린다.
#      🔴 **마이그레이션 0127 이 끌려 오는 자리가 바로 여기다.**
#   ⑤ 21e04c16 **[검수/승인]에 읽기+쓰기**(쓰기 = 승인 요청을 올릴 수 있는가) ·
#      '접수 건 수정' 고정 · '기타건 현황' 문구.
#      🔵 다섯 역할의 **요청 가능 여부는 전과 같다**(셋만 가능).
#
#   🔵 **설정은 안 바꾼다** — 이번 범위에 늘어난 process.env 이름이 0개다.
#   🔵 **공유폴더도 안 건드린다.** 🔴 그래도 1-ㅁ 절(발주서·견적서 폴더)은
#      **그대로 둔다** — 한 번 빼면 다시 넣는 사람이 없다(42~59번의 규율).
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
#     MID   도구만 새 판        → 🔴 **--migrate 까지 돌았다**(55번과 같은 뜻으로
#           돌아왔다). 🔵 --go 뒤에 --rollback 으로 앱만 되돌린 상태도 여기 보인다 —
#           그 둘은 **DB 기록으로 가른다**(--migrate 를 돌았으면 128 이다).
#     ODD   그 밖               → 표를 찍고 사람이 본다 (막지는 않는다)
#   🔴 **이번 판은 마이그레이션 수도 가지를 나눈다 — 127(전) · 128(뒤).**
#      🔴 59번은 「어느 단계에서나 127」이었다. 그 글을 베끼면 **적용 뒤에 가짜 ✗** 다.
#
# ── 🔴 48~59번에서 그대로 가져온 것 ──────────────────────────────────
#   ① **3xx 판정**(grep -qE '200|30[1237]'). A/S 는 307, PO 는 303 으로 로그인에
#      보낸다. 빠뜨리면 **멀쩡한 사이트가 ✗ 로 나온다**(2026-10-30 실측).
#   ② 🔴 **치환 전에 그 줄의 낱말 수가 2 인지 본다.** 줄 끝에 주석이 붙어 있으면
#      **주석의 마지막 낱말**이 태그로 바뀌고 image: 값은 그대로 남는다.
#   ③ 🔴 **달라진 image: 줄 수를 박지 않는다 — 세어서 정한다.**
#   ④ 🔴 **설정 파일 검사**(중복 키 · auto). 값은 한 글자도 안 찍는다.
#   ⑤ 🔵 연락서 폴더 검사 · 재고 관리 통로 검사 · 발주서/견적서 폴더 검사는
#      **42~59번 것 그대로다.** 🔴 **빼지 않는다** — 한 번 빼면 다시 넣는 사람이 없다.
#   ⑥ 🔵 **--rollback 은 앱만 되돌린다.** 도구는 새 판 그대로 둔다.
#      🔴 **DB 도 자동으로 안 되돌린다** — 0127 은 더하기만 하므로 옛 앱도 그냥 돈다.
#   ⑦ 🔴 **DB 둘의 StartedAt 을 앞뒤로 비교한다** — 안 멈췄다는 증거다.
#   ⑧ 🔴 **제 md5 를 스스로 찍는다** · **image: 줄을 통째로 찍는다**.
#   ⑨ 🔴 **PO 의 repair_cases 쓰기 권한을 잰다** — PO 를 안 건드려도 잰다.
#
# ── 모드 여섯 — **쓰는 것 / 안 쓰는 것** ──────────────────────────────
#   (기본) --check
#       쓰는 것 : **없다.** (로그 파일 하나만 남긴다)
#       안 쓰는 것: compose · 이미지 · DB · 볼륨 · 양식 · 공유폴더 — 전부.
#       🔴 다만 **읽기는 한다** — DB 에 select, 앱 주소에 GET, 재고 통로에 GET,
#          양식 폴더에 ls·md5sum, **도구·앱 이미지가 실려 있으면 각각 컨테이너를
#          잠깐 띄웠다 지운다**(run --rm · sh 로 열 뿐 앱을 시작하지 않는다).
#   --count
#       쓰는 것 : **없다.** 도구 다섯을 **읽기만** 해서 부른다(--apply 가 없다).
#       🔵 여기에 **이 배포가 바꾸는 자리를 세는 절**이 붙어 있다(effect_counts).
#          🔴 59번의 그 절과 **재는 것이 완전히 다르다** — 아래 「--count 가 세는 것」.
#   --preload
#       쓰는 것 : **NAS 의 도커 이미지 저장소**(docker load 로 태그 둘을 싣는다).
#       🔵 실어만 두고 **아직 안 갈아 끼운다.** 싣자마자 **둘 다 안을 센다.**
#   --migrate   🔴 **되살아났다**
#       쓰는 것 : **DB 덤프 한 장** · **compose 사본 한 장** ·
#                 **compose 의 image: 줄 하나**(tools-as 만) ·
#                 **마이그레이션 볼륨**(묶음을 풀어 127 → 128) ·
#                 🔴 **DB 의 role_permissions 자료**(INSERT 넷 · 0건일 수 있다).
#       안 쓰는 것: 앱의 image: 줄 · 도는 컨테이너 · 양식 · 공유폴더.
#       🔵 **다시 돌려도 안전하다** — drizzle 은 이미 적용한 것을 건너뛰고,
#          0127 자신도 ON CONFLICT DO NOTHING 이다.
#   --go
#       쓰는 것 : **DB 덤프 한 장** · **compose 사본 한 장** ·
#                 **compose 의 image: 줄**(PRE 면 둘 · MID 면 하나) ·
#                 **app-as 컨테이너를 다시 띄운다**(정지 창 약 25초).
#       안 쓰는 것: 🔴 **DB 의 자료와 스키마**(--migrate 가 이미 했다) ·
#                 마이그레이션 볼륨 · 양식 · 공유폴더 ·
#                 app-po · app-auth · tools-auth 의 image: 줄 · 나머지 아홉 상자.
#       🔴 **기록이 128 이 아니면 멈춘다** — 새 앱이 잎 넷을 읽는다.
#   --rollback
#       쓰는 것 : **compose 사본 한 장** · **compose 의 image: 줄 하나**(app-as 만) ·
#                 **app-as 컨테이너를 다시 띄운다.**
#       안 쓰는 것: 도구 태그(새 판 그대로 둔다) · DB · 볼륨 · 덤프(안 뜬다).
#
# ── 🔴 bash -n 이 못 잡는 넷 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 쓴 뒤 grep 으로 세었다.
#   ② 읽기 전용 자리에 콜론 하나와 꺾쇠로 빈 파일을 만들면 NAS 의 ash 가 셸을
#      그 자리에서 끝낸다(2026-10-12 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   ③ 🔴 bash 의 $(( )) 는 0 으로 시작하는 수를 **8진수**로 읽는다 —
#      0127 을 셈에 넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
#   ④ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」
#      같은 안전망을 달면 **하필 바라던 0 에서만** 터진다. 셈은 「$( … || true )」 로 받는다.
#   🔴 그리고 **tar | grep -q 를 if 에 바로 물리지 않는다.** set -uo pipefail
#      아래에서 grep -q 가 찾자마자 끝내면 앞의 tar 가 SIGPIPE 로 죽어,
#      **파일이 있을 때 오히려 ✗** 가 난다(2026-11-07 쉰째 배포에서 실제로 났다).
#      🔴 **이번 판에는 묶음이 있어 tar 를 읽는 자리가 많다** — 전부
#         **세어서 담고 비교하는 꼴**(grep -c · grep -o)이다. grep -q 는 안 쓴다.
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
#   처방(58·59-deploy.sh 가 고쳐 둔 그대로 가져왔다):
#     · 읽자마자 **tr -d 로 \r 를 걷어낸 뒤** 맞댄다.
#     · 「-Fx」 는 **살린다** — 경로 일부만 겹치는 다른 줄에 걸리면 안 된다.
#     · **읽은 줄 수를 함께 받아 너무 적으면 ✗** 로 센다(빈 결과는 삼켜진 오류일
#       수 있다 — 「0건」과 「못 읽었다」는 다른 말이다).
#     · **없는 경로 하나를 일부러 함께 묻는다** — 그 줄이 no 로 안 나오면
#       「무조건 yes」인 검사라는 뜻이고 나머지 yes 도 못 믿는다.
#     · **cat 의 글롭은 set -f 앞에 둔다** — 뒤에 두면 *.txt 가 글자 그대로 남아
#       파일을 한 줄도 못 읽는다.
#   🔵 scripts/test-lists 는 **넷**이다: unit.txt · components.txt · db.txt · db-safety.txt.
#   🔴 **이번 판에는 대괄호·괄호가 든 경로가 25개 있다**(59번은 0개였다) —
#      글롭 함정이 **살아 있다.** 목록은 환경변수로 넘기고 while read 로 받고
#      큰따옴표로 감싸고 set -f 로 글롭을 끈다(넷을 다 지킨다).
#
# ── 🔴 비밀값을 찍지 않는다 ───────────────────────────────────────────
#   설정 파일은 **이름이 있는가/없는가**와 **auto 인가**만 본다. PO 권한 검사는
#   DATABASE_URL 에서 **역할 이름만** 꺼낸다. 🔵 **양식 경로는 찍어도 된다.**
#   🔴 그리고 **한글을 HTTP 머리말·argv 에 넣지 않는다** — 넣으면 요청이 아예 안
#      나가고, 그 ✗ 가 진짜 결함처럼 보인다.
#   🔵 앱 번들의 **한글 표식 둘**만 예외인데, 그것도 argv 로 한글을 넘기지 않는다 —
#      **8진 이스케이프**를 넘기고 컨테이너 안에서 다시 만든다(바이트 수를 먼저 받는다).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **--count 가 세는 것** — 59번과 완전히 다른 자리다
# ══════════════════════════════════════════════════════════════════════
#   🔴 59번은 **종 줄 수**(영업·관리자·최고관리자가 받게 될 「승인 완료」 줄)를
#      셌다. **그 수는 이번 판과 아무 상관이 없다.** 그대로 두면 이 배포를 재는
#      숫자가 **하나도 없다** — 그래서 통째로 갈았다.
#
#   🔴 **이 배포는 DB 를 거의 안 바꾼다** — 마이그레이션이 옮기는 행이 운영에
#      0건이다(2026-11-12 실측). 그러니 「전후 차이」로 재면 **아무것도 못 잰다.**
#      대신 **새 코드가 보여 주게 될 것을 미리 센다**(59번이 그렇게 했다).
#
#   ① 🔴 **마이그레이션이 옮길 행 수** — 잎 넷에 각각 몇 줄이 들어갈 것인가.
#      🔴 **ON CONFLICT 를 흉내 낸다** — 「옛 행이 있고 그 잎에 아직 행이 없는」
#         것만 센다. 그것이 INSERT ... SELECT 가 실제로 넣을 수다.
#      🔵 **0 이면 ⚠️ 다. ✗ 가 아니다** — 운영이 전부 코드 기본값으로 돈다는 뜻이고,
#         2026-11-12 실측이 그랬다. 🔴 **그래도 매번 다시 센다** — 그 사이에 누가
#         권한 화면에서 저장하면 행이 생긴다.
#   ② 🔵 **role_permissions 에 저장된 행을 area_key 별로** 전부 찍는다.
#      🔴 **앱이 쓰는 조회 함수에는 WHERE 가 없다** — queries/role-permissions.ts 의
#         loadStoredRolePermissions() 는 'select role, area_key, level from
#         role_permissions' 를 **조건 없이** 읽고, 그 뒤 **코드에서**
#         isPermissionLeafKey(row.areaKey) 로 거른다. 그래서 여기도 **조건 없이**
#         전부 읽어 찍는다 — 그것이 앱의 잣대다.
#   ③ 🔴 **앱이 조용히 버리는 행** — 잎이 아닌 열쇠로 저장된 행이다. 그 행은
#      판정에 한 번도 안 끼고, 그 역할은 **오류 한 줄 없이** 코드 기본값으로 돈다.
#      🔵 이름을 적어 둔 넷을 센다: domesticOrders(이번 판부터 잎이 아니다) ·
#         miscCases · quotes · inventory.stock(그렇게 죽어 있는 실물이다).
#      🔴 **--migrate 뒤에는 domesticOrders 쪽이 그대로 남는 것이 정상이다** —
#         0127 은 옛 행을 **안 지운다**(되돌리기를 한 문장으로 두려고).
#   ④ 🔵 **역할별 사람 수**(활성 · 휴지통 뺌). 탭 관문과 권한 쪼개기가 **몇 사람의
#      화면을 바꾸는가**다. 🔴 0 이면 ⚠️ 다.
#   ⑤ 🔴 **[최종 출하 승인 완료] 거르개가 보여 줄 건 수** — 이번 판이 **새로
#      보여 주게 될 것**이다.
#      🔴 **앱이 쓰는 조회 함수의 WHERE 를 그대로 베꼈다.** 베낀 자리:
#        · src/lib/db/queries/repair-case-approvals.ts 의
#          loadRepairCaseFinalShipmentApprovalStates()
#            — repair_case_approvals ⨝ repair_cases (INNER JOIN)
#            — approval_type = 'FINAL_SHIPMENT'
#            — **requested_at 내림차순의 첫 행**(가장 최근 하나만 본다)
#        · src/lib/domain/local/workflow/shipment-approval-checklist.ts 의
#          resolveApprovalState() — status 가 APPROVED 이고
#          **repair_case_version_at_request = repair_cases.version** 이어야 APPROVED.
#          🔴 **판 번호가 어긋나면 STALE 이고 배지가 안 붙는다.**
#        · src/app/(app)/repair-cases/page.tsx — 휴지통을 뺀 목록이므로
#          **is_deleted = false**.
#      🔴 **칸 이름만 보고 짜면 틀린다** — 개발 DB 실측에서 「최신이 APPROVED 인
#         건」은 **7건**인데, 판 번호까지 맞는 것은 **1건**이었다. 여섯은 STALE 이라
#         배지가 안 붙는다. 그래서 **둘을 나란히 찍는다.**
#   ⑥ 🔵 **결재 종류별 줄 수** — 탭 관문이 가리는 [검수/승인] 탭이 실제로 몇 건을
#      들고 있는가. 🔵 사건의 규모를 보는 자리다(판정하지 않는다).
#
#   🔴 **전부 select 뿐이다.** 🔴 **--migrate 전후로 ① 이 줄어들고 ② 가 늘어야**
#      정상이다. 나머지는 앞뒤가 같아야 한다.
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v56-$STAMP
BKDB=$D/backups/db   # 🔴 덤프가 여기 간다 (48·52·53·55·57·58·59번과 같은 자리)
# 🔴 **덤프 이름의 판 꼬리표** — 🔴 **59번이 여기를 안 고쳐 숙제로 남겼다.**
#    그 파일은 compose 사본을 …yml.v55-… 로 뜨면서 덤프만 dss_as-v54-… 로 만들어,
#    어느 배포의 사진인지 이름으로 못 가리게 해 두었다(dss-deploy/README.md 의
#    쉰다섯째 절). 🔴 **BK 와 이 값이 같은 v 번호여야 한다** — 아래 0절이 그것을
#    값으로 확인한다.
DUMP_VER=v56
# ══ 이번에 다시 띄우는 것 — 앱 **하나** ═══════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
#   🔵 59번과 같은 모양이다 — 앱 하나, 도구 하나. **판만 하나씩 올라간다.**
SITES='
as|app-as|dss-as|dss-as:5.2|dss-as:5.1|dss-as-5.2.tar|13000
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
#   🔴 **이 판에는 --migrate 가 있다** — 55번처럼 **--migrate 가 이 줄을 먼저
#      고친다.** 그래서 --go 에서 달라지는 줄은 PRE 면 둘 · MID 면 하나다.
AS_TOOLS_SVC=tools-as
AS_TOOLS_OLD=dss-as-tools:18
AS_TOOLS_NEW=dss-as-tools:19
# 🔵 포털 도구 — **안 건드린다.** 53번이 올린 :4 그대로여야 한다(⚠️ 로만 센다).
AUTH_TOOLS_SVC=tools-auth
AUTH_TOOLS_KEEP=dss-auth-tools:4
IMG_MIGDIR=/app/drizzle
MIGDIR=$D/as-migrations
INCOMING=$D/setup/incoming
MIGTAR=$INCOMING/as-migrations.tar.gz

# ══ 🔴 양식 — **이번 판에도 올릴 것이 없다. 재기만 한다** ═════════════
TPLDIR=$D/as-templates
TPL_IN_CONTAINER=/templates
# 🔴 열하나 — 이름|바이트|md5. 출처: [실측] **2026-11-11 개발 PC**, 59번이 물려받은 값.
#    🔴 운영 것이 이 값과 달라도 **✗ 를 내지 않는다** — 다르면 **사람이 보라는 뜻**이다.
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
KYO_SRC=/kyosan-src;        KYO_SRC_MIN=600
KYO_CONV=/kyosan-converted; KYO_CONV_MIN=100
# ══ 🔵 발주서·견적서 공유폴더 — **이번 판은 안 건드린다. 그래도 잰다** ═══
PO_ARCHIVE=/purchase-order-archive
QUOTE_ARCHIVE_ENV=QUOTE_ARCHIVE_DIR

# ══ 🔴 설정 파일 — .env 쪽과 env/*.env 쪽을 **둘 다** 본다 ════════════
ENV_NAS=$D/deploy/.env.nas
ENV_AS=$D/deploy/env/as.env
ENV_AUTH=$D/deploy/env/auth.env
ENV_PO=$D/deploy/env/po.env

# ══ 🔴 tar 둘의 지문 — [배포본] 60-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 비어 있다 — 굽기 전이다.** 60-build.sh --go 가 꼬리말에 찍는
#      **두 줄**을 그대로 옮겨 적고, 옮긴 뒤 _images-56 의 두 tar 를 md5sum 으로
#      다시 재어 같은지 확인한 뒤에 scp 하세요.
#   🔴 **이 값을 NAS 에서 재서 채우지 마라.** 그러면 「옮기다 깨졌는가」를 자기가 잰
#      값으로 자기를 재는 꼴이 되어 **영영 통과한다.** 반드시 **구운 쪽**에서 잰다.
#   🔴 비어 있으면 3절이 **--check·--rollback 에서는 ? · --preload·--migrate·--go
#      에서는 ✗** 로 센다. 🔵 막는 것은 **✗ 뿐이다.**
#      🔴 **두 번 연속으로 지문 줄을 못 받았다** — 쉰세째는 --go 의 출력을 잘라서,
#         쉰네째는 굽기가 「실패 1」로 끝나 꼬리말까지 못 가서. 🔴 **쉰세째에는 빈
#         표가 그대로 NAS 로 올라갔고 --preload 가 ✗ 둘로 멈췄다**(2026-11-11).
#      🔵 60-build.sh 는 그 두 줄을 **세 자리**에서 찍는다(실패로 나갈 때 · 표 자리 ·
#         꼬리말 맨 끝의 🔴🔴🔴).
#   🔴 **이번 판에는 셋째 산출물(묶음)이 있다** — 그 값은 TARS 가 아니라
#      아래 MIGTAR_SIZE · MIGTAR_MD5 에 넣는다. 59번에는 그 변수가 **없었다.**
TARS='
dss-as-5.2.tar|||
dss-as-tools-19.tar|||
'
TARS_WANT=2
# 🔴 **묶음의 잰 값** — 60-build.sh --go 가 찍어 준다. **비어 있으면 못 잰다.**
#    🔵 55번에는 이 둘이 있었고 59번에는 **없었다**(묶음을 안 만들었다).
MIGTAR_SIZE=
MIGTAR_MD5=

# 🔴 tar 이름 → 태그. **정규식으로 되돌리지 않는다** — 이름마다 손으로 적는다.
#    🔴 dss-as-5.2.tar 은 「끝의 숫자 앞에 콜론」 규칙으로 풀리지 않는다(판에 점이 있다).
tar2tag() {
  case "$1" in
    dss-as-5.2.tar)        printf 'dss-as:5.2' ;;
    dss-as-tools-19.tar)   printf 'dss-as-tools:19' ;;
  esac
}

# ══ 🔴 DB — **이번 판은 앞뒤가 다른 수다** (59번과 반대) ══════════════
#   🔵 A/S 와 PO 는 **같은 dss_as** 를 본다(PO 는 제 DB 가 없다).
#   🔵 포털은 **dss_auth** 를 따로 본다 — 이번 판에 **한 글자도 안 바꾼다.**
AS_BOX=dss-pg-app;    AS_DB=dss_as
AUTH_BOX=dss-pg-auth; AUTH_DB=dss_auth
# 🔴 **두 갈래다.** 🔴 59번은 「어느 단계에서나 127 한 갈래」였다 — 그 글을 베끼면
#    **적용 뒤에 가짜 ✗** 가 난다.
AS_MIG_BEFORE=127   # [저장소·운영] 55번이 0125·0126 을 올려 127 이 됐다
AS_MIG_AFTER=128    # [저장소] 이번 판이 0127 을 올린다
AUTH_MIG_KEEP=10    # [README 36번] 포털은 그대로여야 한다
AS_LAST_MIG=0127
AS_NEXT_MIG=0128    # 🔴 셈으로 만들지 않는다(8진수 함정). 글자로 적는다
AS_KEEP_MIGS='0121 0122 0123 0124 0125 0126 0127'
AS_NEW_MIGS_WANT=1
# 🔴 **지우는 문장 잣대 — 주석을 먼저 걷어낸다.**
#    🔴 0127 의 머리말에 되돌리는 법으로 DELETE 한 문장이 적혀 있어, 날것으로 세면
#       **1줄**이 나온다(2026-11-12 실측). 주석을 걷으면 **0줄**이다.
#    🔴 **UPDATE 를 잣대에 넣지 마라** — updated_by·updated_at **칸 이름**이 걸려
#       0127 에서만 13 이 나온다. 처음 세었을 때 14건이 나온 것이 전부 그것이었다.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
SQL_COMMENT_RE='^[[:space:]]*--'
MIG_DROP_WANT=0

# ══ 🔴 0124~0126 이 만든 열 — **어느 단계에서나 다 있어야 한다** ══════
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
NEW_IDX=repair_case_approvals_one_active_domestic_request
NEW_IDX_COLS_WANT=3
# 🔵 48번이 올린 것 — **아직 있어야 한다.**
AS_OLD_TABLE=procedure_case_execution_edges
AS_OLD_COL_TABLE=procedure_template_nodes
AS_OLD_COL=next_procedure_template_id
AS_OLD_INDEX=procedure_template_nodes_next_template_idx
# 🔴 줄 수가 그대로여야 하는 표.
#    🔴 **role_permissions 는 여기 안 넣는다** — 이번 판이 **그 표에 행을 더한다.**
#       넣으면 --migrate 가 제 일을 하고도 ✗ 를 받는다.
AS_COUNT_TABLES='repair_cases domestic_orders repair_case_approvals shipment_approval_routes procedure_templates users'
# 🔴 49번이 올린 기능이 쓰는 표. 1-ㄹ 절이 이 이름으로 권한을 묻는다. **ASCII 다.**
PO_WRITE_TABLE=repair_cases

# ══ 🔴 이번 판이 옮기는 권한 행 — --migrate 와 --count 가 함께 쓴다 ═══
#   🔵 전부 ASCII 다(열쇠 글자다).
PERM_TABLE=role_permissions
PERM_OLD_KEY=domesticOrders
PERM_LEAVES='view edit lifecycle approval'
PERM_LEAVES_WANT=4
# 🔵 **앱이 조용히 버리는 행**을 세는 데 쓰는 이름들. inventory.stock 이 그렇게
#    죽어 있는 실물이고, 0127 의 머리말이 그것을 근거로 든다.
PERM_DEAD_KEYS="domesticOrders miscCases quotes inventory.stock"

# ══ 🔵 **안 건드리는 아홉** — 「옆으로 안 샜다」는 증거로 센다 ═════════
KEEP_BOXES="dss-auth dss-inventory dss-meters dss-board dss-improvements dss-leave dss-approvals dss-rf-trouble dss-po"
KEEP_BOXES_WANT=9
KEEP_DB="dss-pg-app dss-pg-auth"

# ══ 🔴 53번 꼬리말에서 넘어온 할 일 둘을 **값으로** 센다 ══════════════
AS_ROUTE_TABLE=shipment_approval_routes
AUTH_MAIL_TABLE=approval_mail_kinds
AUTH_MAIL_CLIENT=rf-service-system

# ══ 🔴 **이번 판이 바꾼 79개** — 도구 이미지 안 검사가 쓴다 ═══════════
#   🔵 src/ **77** + scripts/ **2**. 🔴 59번은 src/ 10 · scripts/ 0 이었다 —
#      그 수를 그대로 두면 **멀쩡한 판이 ✗** 다.
#   🔴 **대괄호·괄호가 든 경로가 25개 있다**(59번은 0개였다) — 환경변수로 넘기고
#      while read 로 받고 큰따옴표로 감싸고 set -f 로 글롭을 끈다.
AS_CHANGED_SRC='
src/app/(app)/domestic-orders/[id]/approval/page.tsx
src/app/(app)/domestic-orders/[id]/layout.tsx
src/app/(app)/domestic-orders/[id]/purchase-orders/page.tsx
src/app/(app)/domestic-orders/[id]/quotes/page.tsx
src/app/(app)/domestic-orders/page.tsx
src/app/(app)/repair-cases/[id]/approval/page.tsx
src/app/(app)/repair-cases/[id]/diagnosis/[flowchartId]/page.tsx
src/app/(app)/repair-cases/[id]/diagnosis/page.tsx
src/app/(app)/repair-cases/[id]/diagnosis/work-records/page.tsx
src/app/(app)/repair-cases/[id]/execution/page.tsx
src/app/(app)/repair-cases/[id]/files/page.tsx
src/app/(app)/repair-cases/[id]/layout.tsx
src/app/(app)/repair-cases/[id]/page.tsx
src/app/(app)/repair-cases/[id]/purchase-orders/page.tsx
src/app/(app)/repair-cases/[id]/report/page.tsx
src/app/(app)/repair-cases/[id]/report/service-report/page.tsx
src/app/(app)/repair-cases/[id]/report/service-report/print/page.tsx
src/app/(app)/repair-cases/[id]/work-history/page.tsx
src/app/(app)/repair-cases/page.tsx
src/app/api/domestic-orders/[id]/purchase-order-folder/entries/route-source.test.ts
src/app/api/domestic-orders/[id]/purchase-order-folder/entries/route.ts
src/app/api/domestic-orders/[id]/quote-archive-folder/entries/route.ts
src/app/api/repair-cases/[id]/purchase-order-folder/entries/route-source.test.ts
src/app/api/repair-cases/[id]/purchase-order-folder/entries/route.ts
src/app/api/v1/domestic-orders/[id]/completion/route.ts
src/components/domestic-orders/detail/DomesticOrderDetailTabs.tsx
src/components/domestic-orders/detail/domestic-order-approval-tab-screens.test.tsx
src/components/domestic-orders/detail/domestic-order-detail-screens.test.tsx
src/components/domestic-orders/detail/domestic-order-detail-tabs-list.ts
src/components/domestic-orders/detail/domestic-order-purchase-order-tab-screens.test.tsx
src/components/domestic-orders/detail/domestic-order-quote-tab-screens.test.tsx
src/components/domestic-orders/domestic-order-trash.test.ts
src/components/repair-cases/RepairCaseFilters.tsx
src/components/repair-cases/RepairCaseListPage.tsx
src/components/repair-cases/approval/DatabaseApprovalScreen.tsx
src/components/repair-cases/approval/DatabaseFinalShipmentCard.tsx
src/components/repair-cases/approval/DatabaseRepairInspectionCard.tsx
src/components/repair-cases/approval/approval-screen-layout.test.tsx
src/components/repair-cases/approval/approval-texts.ts
src/components/repair-cases/detail/DetailTabs.tsx
src/components/repair-cases/detail/detail-header-placement.test.ts
src/components/repair-cases/detail/detail-tab-permissions.test.ts
src/components/repair-cases/detail/detail-tabs-list.ts
src/components/repair-cases/detail/domestic-order-dates-section.test.ts
src/components/repair-cases/final-shipment-approved-status-filter.test.ts
src/components/repair-cases/purchase-orders/PurchaseOrderFolderSection.test.tsx
src/components/users/PermissionTargetTree.test.tsx
src/components/users/PermissionTargetTree.tsx
src/components/users/RolePermissionSettings.tsx
src/lib/auth/detail-tab-access.ts
src/lib/auth/detail-tab-permissions.ts
src/lib/auth/domestic-order-authorization.test.ts
src/lib/auth/domestic-order-detail-tab-access.ts
src/lib/auth/domestic-order-detail-tab-permissions.ts
src/lib/auth/domestic-order-permission-leaves.test.ts
src/lib/auth/permission-area-groups.test.ts
src/lib/auth/permission-area-groups.ts
src/lib/auth/permission-baseline.ts
src/lib/auth/permission-features.test.ts
src/lib/auth/permission-features.ts
src/lib/auth/permission-settings-truth.test.ts
src/lib/auth/repair-case-approval-request-permission.test.ts
src/lib/auth/repair-case-detail-tab-access.ts
src/lib/auth/repair-case-detail-tab-permissions.test.ts
src/lib/auth/repair-case-detail-tab-permissions.ts
src/lib/db/mutations/domestic-order-approvals.ts
src/lib/db/mutations/domestic-order-issue-dates.ts
src/lib/db/mutations/domestic-order-sheet-settings.ts
src/lib/db/mutations/repair-case-approvals.integration.test.ts
src/lib/db/mutations/repair-case-approvals.ts
src/lib/db/mutations/role-permissions.integration.test.ts
src/lib/domain/final-shipment-approval-badge.ts
src/lib/domain/in-house-filter-matches-dashboard.test.ts
src/lib/domain/repair-case-filters.test.ts
src/lib/domain/repair-case-filters.ts
src/lib/server/actions/domestic-order-approvals.ts
src/lib/server/actions/domestic-orders.ts
'
AS_CHANGED_SRC_WANT=77
# 🔴 **scripts/ 쪽은 2개다.** 🔴 59번은 0 이었고 **1 이상이면 ✗** 로 두었다 —
#    그 절을 그대로 베끼면 멀쩡한 판이 ✗ 다. **뜻을 뒤집었다.**
AS_CHANGED_SCRIPTS='
scripts/test-lists/components.txt
scripts/test-lists/unit.txt
'
AS_CHANGED_SCRIPTS_WANT=2
AS_CHANGED_ALL_WANT=79
# 🔴 **이번에 새로 생긴 파일은 src/ 18 · drizzle/ 2 = 20개다** — 59번은 0개였다.
AS_BORN_SRC_WANT=18
AS_BORN_ALL_WANT=20
# 🔴 **이번 판이 새로 만든 시험 여덟** — 목록 파일에 등록돼 있어야 한다.
#    🔴 59번은 여기가 「**고친** 시험 여섯이 이미 등록돼 있는가」였다. 이번 판에는
#       새 시험이 여덟 장이라 그 여섯 경로를 그대로 두면 **가짜 ✗** 다.
#    🔵 [실측 2026-11-12] 셋은 components.txt · 다섯은 unit.txt 에 줄 전체로 적혀 있다.
AS_NEW_TESTS='
src/components/repair-cases/detail/detail-tab-permissions.test.ts
src/components/repair-cases/final-shipment-approved-status-filter.test.ts
src/components/users/PermissionTargetTree.test.tsx
src/lib/auth/domestic-order-permission-leaves.test.ts
src/lib/auth/permission-area-groups.test.ts
src/lib/auth/permission-settings-truth.test.ts
src/lib/auth/repair-case-approval-request-permission.test.ts
src/lib/auth/repair-case-detail-tab-permissions.test.ts
'
AS_NEW_TESTS_WANT=8
# 🔴 **「무조건 yes」인 검사가 되지 않게** 없는 경로 하나를 함께 묻는다.
REG_PROBE_MISS=src/__dss_probe_not_registered__.test.ts
# 🔴 목록 파일을 **얼마나 읽었나**의 바닥값. [실측 2026-11-12] 네 장을 합쳐
#    **3698줄**(components 1281 · unit 1903 · db 500 · db-safety 14, 빈 줄 뺌).
AS_TESTLIST_MIN_LINES=1000
# 🔵 시험 목록 파일 **넷** — 이번 판은 그중 둘을 고친다. 넷 다 이미지에 있어야 한다.
AS_TESTLIST_FILES='
scripts/test-lists/components.txt
scripts/test-lists/db.txt
scripts/test-lists/db-safety.txt
scripts/test-lists/unit.txt
'
AS_TESTLIST_FILES_WANT=4
# ══ 🔴 **이번 판의 표식 일곱** — 도구 이미지(소스가 글자 그대로 있다)에서 쓴다 ══
#   🔴 59번의 여섯은 **이번 판이 하나도 안 건드린다** — 그대로 두면 **옛 판에서도
#      전부 ✓** 인 죽은 검사가 된다.
#   🔴 **커밋이 다섯이라** 일곱을 **다섯 커밋에 흩어** 두었다 — 하나만 보면
#      「마지막 커밋만 담긴 판」을 못 가른다(59번은 커밋이 하나라 그 고민이 없었다).
#   🔴 전부 **기준판(1259d822)의 그 파일에 0번 · 지금 판에 1번 이상**이다
#      (2026-11-12 실측: 5 · 2 · 2 · 2 · 2 · 2 · 1).
#   🔵 셋째·넷째는 **대괄호가 든 경로**다 — 글롭 함정이 살아 있는 판이라 일부러 거기 두었다.
#   형식: 글자|파일 — 🔴 **전부 ASCII** 라 argv 로 넘겨도 안 깨진다.
AS_MARKS='
FINAL_SHIPMENT_APPROVED_FILTER_VALUE|src/lib/domain/repair-case-filters.ts
PERMISSION_AREA_GROUPS|src/components/users/PermissionTargetTree.tsx
resolveRepairCaseDetailTabVisibility|src/app/(app)/repair-cases/[id]/layout.tsx
canOpenRepairCaseDetailTab|src/app/(app)/repair-cases/[id]/files/page.tsx
repairCases.serviceReports|src/lib/auth/permission-features.ts
domesticOrders.lifecycle|src/lib/server/actions/domestic-orders.ts
repairCases.approval|src/components/repair-cases/approval/DatabaseApprovalScreen.tsx
'
AS_MARKS_WANT=7
AS_HEAD_SHORT=21e04c16
AS_BASE_SHORT=1259d822
# 🔴 **바뀐 77장이 전부 새 내용인가** — 「파일이 있다」와 다른 말이다.
#    🔵 [실측 2026-11-12] 이 날짜 글자가 **77장 전부에** 있고, 기준판 src/ 에 그
#       글자가 든 10장과 **한 장도 안 겹친다**(겹침 0).
#    🔴 **그래서 앱 번들 표식으로는 못 쓴다** — 번들은 파일 단위로 못 가른다.
FRESH_MARK=2026-11-12
# ══ 🔴 **앱 번들에서 쓸 표식** — 🔴 상수·함수 이름으로 재지 않는다 ════════
#   🔴 앱 이미지는 도구와 달리 **번들**이다(소스가 없다). minify 를 거치므로
#      이름이 남는다는 보증이 없다 — 그 이름으로 재면 **멀쩡한 이미지가 ✗** 가 된다.
#   🔵 그래서 **화면·서버가 실제로 쓰는 문자열 리터럴**로 잰다.
#      · domesticOrders.view — **권한 열쇠 문자열**이다. [실측] 기준판 src/ 0파일 →
#        지금 **17파일**. 🔴 이번 판이 잎을 쪼개면서 생긴 글자다.
#   🔴 **59번의 2026-11-12 를 여기 쓸 수 없다** — 기준판 src/ 에 이미 10파일 있다.
#   🔴 **번들에서 세어 본 적이 없다** — 개발 PC 에 .next/standalone 이 없다.
#      그래서 수를 박지 않고 **「합이 1 이상」으로만** 잰다. ✗ 가 나면 검사부터 의심한다.
APP_MARK=domesticOrders.view
# 🔴 앱 번들에서 ✗ 로 세는 **한글** 표식 — [역할별 접근 권한]의 **새 묶음 머리말**이다.
#    🔴 **명령에 한글을 넣지 않는다.** 컨테이너 안에서 **8진 이스케이프로 다시
#       만들어** 쓴다. 만들기가 틀리면 0 이 나와 「없다」로 읽히므로 **바이트 수(23)를
#       먼저 받아** 가르고, 23 이 아니면 ✗ 가 아니라 ⚠️ 다(이미지가 틀린 것이 아니라
#       컨테이너 안에서 글자를 못 만든 것이다).
#    🔵 [실측 2026-11-12] 이 이스케이프가 23바이트 · 기준판 src/ 0파일 · 지금 3파일.
APP_MARK_KO_OCT='\353\251\224\353\211\264\354\227\220 \354\227\206\353\212\224 \355\225\255\353\252\251'
APP_MARK_KO_BYTES=23
# 🔵 **뒷걸음 방지 — 🔴 이번 판에서 둘 → 셋이 됐다.**
#      · status=IN_HOUSE   — **쉰네째(58번)**가 올린 글자. [실측] src/ 5 → 5
#      · no-equipment-key  — **쉰세째(57번)**가 올린 글자. [실측] src/ 8 → 8
#    🔴 59번에는 이 ASCII 둘뿐이었다. **쉰다섯째(59번)가 올린 한글 글자**를 보탰다 —
#       그것이 없으면 **59번이 올린 판보다 옛 나무를 실었는지** 가릴 길이 없다.
#    🔴 **하나도 빼지 마라** — 뺀 자리는 다시 넣는 사람이 없다.
APP_KEEP_MARKS='
status=IN_HOUSE
no-equipment-key
'
APP_KEEP_MARKS_WANT=2
# 🔴 뒷걸음 방지 ③ — **쉰다섯째(59번)가 올린 한글 글자.** [실측] 47바이트 · src/ 1 → 1.
KEEP_MARK3_KO_OCT='\354\230\201\354\227\205\302\267\352\264\200\353\246\254\354\236\220\302\267\354\265\234\352\263\240\352\264\200\353\246\254\354\236\220\354\227\220\352\262\214 \352\260\200\352\263\240'
KEEP_MARK3_KO_BYTES=47

MODE=check
case "${1:-}" in
  --check|"")   MODE=check ;;
  --count)      MODE=count ;;
  --preload)    MODE=preload ;;
  --migrate)    MODE=migrate ;;
  --go)         MODE=go ;;
  --rollback)   MODE=rollback ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --count · --preload · --migrate · --go · --rollback\n   🔵 --migrate 는 이 판에 **있습니다**(마이그레이션 1건 — 59번에는 없었습니다).\n' "$1"; exit 2 ;;
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
LOG="$D/setup/logs/60-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "쉰여섯째 배포 (파일 번호 60) — A/S 앱·도구 (양식 0장 · **마이그레이션 1건** · 포털·PO 안 건드림)   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  🔵 회차(쉰여섯째)와 파일 번호(60)가 어긋나는 것은 이 저장소에서 원래 그렇다 — 55번이 쉰두째 · 57번이 쉰세째 · 58번이 쉰네째 · 59번이 쉰다섯째였다."
printf '%s\n' "  🔵 판은 **5.1 → 5.2** 로 하나 늡니다. 도구는 18 → 19."
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  🔴 개발 PC 의 Get-FileHash 값과 **같은지 눈으로 맞대세요** (DSM 터미널이 긴 것을 잘라 먹습니다)"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  로그: $LOG"
printf '%s\n' "  🔴 차례: --check → --count → (scp tar **둘** + **묶음 하나**) → --preload → --check → **--migrate** → --go → --count"
printf '%s\n' "  🔴 **--migrate 모드가 되살아났습니다** — 59번에는 없었습니다(그 판은 0건이었습니다)."
printf '%s\n' "     🔴 이번 판은 **마이그레이션 1건**입니다 — drizzle/0127_domestic_order_permission_leaves.sql."
printf '%s\n' "     🔴 **묶음(as-migrations.tar.gz)을 반드시 보냅니다** — 마이그레이션은 이미지 안이"
printf '%s\n' "        아니라 **볼륨에서** 돕니다. 안 보내면 적용이 0건으로 조용히 끝납니다."
printf '%s\n' "     🔵 **표를 한 칸도 안 바꿉니다** — INSERT 넷뿐이고 전부 ON CONFLICT DO NOTHING 입니다."
printf '%s\n' "     🔵 **운영에서 옮길 행이 0건일 수 있습니다**(2026-11-12 실측 0행) — 정상입니다."
printf '%s\n' "  🔵 포털·PO 는 **안 건드립니다** — 7절이 「그대로 도는가」만 봅니다"
printf '%s\n' "  🔴 이번 판이 바꾸는 것은 **권한이 잘게 쪼개지는 것**입니다 — 커밋 **다섯**이고"
printf '%s\n' "     수리건 상세 탭 여덟 · [내자 정리] 1칸 → 4칸 · [검수/승인] 쓰기 · 권한 화면 재정비 ·"
printf '%s\n' "     [현재 상태] 거르개의 새 줄 하나입니다."
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
nf_at() { awk -v n="$1" 'NR==n {print NF}' "$CF"; }
svc_block() { # 1 서비스 — 주석 줄은 뗀다
  awk -v s="  $1:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$CF" | sed '/^[[:space:]]*#/d'
}
# 🔵 앱 쪽 image: 줄 전부 — --migrate 가 **앱을 안 건드렸다**는 증거로 쓴다.
app_img_lines() { grep -n '^ *image:' "$CF" | grep -E 'dss-as:|dss-po:|dss-auth:' | tr '\n' ' '; }

# 🔴 운영 DB 를 **앱이 쓰는 길**(컨테이너 안 psql)로 잰다. 소켓·루프백으로 재면
#    trust 라 그냥 통과한다. 보내는 SQL 은 select 뿐이다.
#    🔴 **SQL 에 큰따옴표를 쓰지 않는다** — 이 문자열이 큰따옴표 안에 들어간다.
#    🔴 **달러 기호도 쓰지 않는다** — 컨테이너 안 sh 가 치환해 버린다.
pgq() { # 1 상자 2 DB 3 SQL
  "$DOCKER" exec -i "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -X -tAq -c \"$3\"" 2>/dev/null | head -1 | tr -d ' \r'
}
# 🔵 여러 줄이 돌아오는 질의용 — head -1 을 안 한다.
pgrows() { # 1 상자 2 DB 3 SQL
  "$DOCKER" exec -i "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -X -tAq -c \"$3\"" 2>/dev/null | tr -d '\r'
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
#    만들었다 — 「있는가」로는 못 가르고 **칸 수**로 가른다.
index_cols() { pgn "$1" "$2" "select coalesce(max(i.indnkeyatts),0) from pg_index i join pg_class c on c.oid=i.indexrelid where c.relname='$3'"; }

# ══ 🔴 **이번 판이 옮기는 행을 세는 자리** — --migrate 도 --count 도 쓴다 ══
#   🔴 **ON CONFLICT DO NOTHING 을 흉내 낸다** — 「옛 행이 있고 그 잎에 아직 행이
#      없는」 것만 센다. 그것이 INSERT ... SELECT 가 **실제로 넣을 수**다.
#      🔴 옛 행 수만 세면 **이미 옮겨진 판에서도 그 수가 나와** 「아직 할 일이
#         있다」로 잘못 읽힌다.
perm_pending_for() { # 1 잎 이름(view/edit/...) → 넣을 행 수
  pgn "$AS_BOX" "$AS_DB" "select count(*) from $PERM_TABLE o where o.area_key = '$PERM_OLD_KEY' and not exists (select 1 from $PERM_TABLE t where t.role = o.role and t.area_key = '$PERM_OLD_KEY.$1')"
}
perm_rows_of() { # 1 area_key → 그 열쇠로 저장된 행 수
  pgn "$AS_BOX" "$AS_DB" "select count(*) from $PERM_TABLE where area_key = '$1'"
}

# 🔴 **볼륨**을 읽는다 — 마이그레이션은 이미지 안이 아니라 여기서 돈다.
#    🔵 가지가 셋이다: DONE(128 · 묶음을 풀었다) · OLD(127 · 아직이다) · ODD(그 밖).
#    🔴 59번은 「DONE(127) · ODD」 둘이었다 — 그 글을 베끼면 **127 이 DONE 으로
#       읽혀 묶음을 영영 안 푼다.**
read_migdir() {
  MIG_N_SQL=0; MIG_N_J=0; MIG_STATE=""
  [ -d "$MIGDIR" ] || { MIG_STATE=NODIR; return 0; }
  MIG_N_SQL=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  if [ -f "$MIGDIR/meta/_journal.json" ]; then
    MIG_N_J=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  fi
  MIG_N_SQL=${MIG_N_SQL:-0}; MIG_N_J=${MIG_N_J:-0}
  if   [ "$MIG_N_SQL" = "$AS_MIG_AFTER" ]  && [ "$MIG_N_J" = "$AS_MIG_AFTER" ];  then MIG_STATE=DONE
  elif [ "$MIG_N_SQL" = "$AS_MIG_BEFORE" ] && [ "$MIG_N_J" = "$AS_MIG_BEFORE" ]; then MIG_STATE=OLD
  else MIG_STATE=ODD
  fi
  return 0
}

# ══ 🔴 묶음을 푼다 — **이번 판에는 반드시 불린다** ════════════════════
#   🔴 운영 볼륨이 지금 127 이고 0127 이 묶음 안에만 있다.
#   🔵 옛 폴더는 **지우지 않고 .old 로 치워 둔다** — 그것이 되돌릴 길이다.
place_migs() {
  if [ ! -s "$MIGTAR" ]; then
    bad "🔴 볼륨을 $AS_MIG_AFTER 로 올려야 하는데 묶음이 없다: $MIGTAR"
    say "🔴 **이번 판은 묶음이 필수다** — 0127 이 그 안에만 있다."
    say "🔵 60-build.sh --go 가 만든 as-migrations.tar.gz 를 $INCOMING 로 보내세요."
    cmd "scp -O as-migrations.tar.gz dss-nas:$INCOMING/"
    say "🔴 **_images-52 의 옛 묶음(127장)을 보내지 마세요** — 0127 이 없습니다."
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

# 🔴 0121~0127 이 **아직 온전한가** + 0128 이 없는가 + 지우는 문장 0.
#    🔴 **주석을 먼저 걷어낸다** — 0127 의 머리말에 되돌리는 법으로 DELETE 한
#       문장이 적혀 있어, 날것으로 세면 1줄이 나온다(2026-11-12 실측).
#    🔴 **UPDATE 를 잣대에 넣지 않는다** — updated_by·updated_at 칸 이름이 걸린다.
check_keep_migs() {
  local t miss="" f n rc=0 c craw
  for t in $AS_KEEP_MIGS; do
    ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || miss="$miss $t(sql)"
    [ -f "$MIGDIR/meta/${t}_snapshot.json" ]   || miss="$miss $t(snapshot)"
  done
  if [ -z "$miss" ]; then ok "0121~0127 의 .sql 과 meta/*_snapshot.json 이 다 있다 (0127 포함)"
  else bad "🔴 빠진 것:$miss"; rc=1; fi
  # 🔴 0128 은 없어야 한다. 글자로 맞댄다(8진수 함정).
  if ls -1 "$MIGDIR/${AS_NEXT_MIG}_"*.sql >/dev/null 2>&1; then
    bad "🔴 볼륨에 $AS_NEXT_MIG 번이 **있다** — 이 배포는 **$AS_LAST_MIG 까지**를 전제로 쓰였다. 멈추고 알리세요"
    rc=1
  else
    ok "볼륨에 $AS_NEXT_MIG 번이 없다 (마지막이 $AS_LAST_MIG — $AS_NEW_MIGS_WANT 건이 맞다)"
  fi
  # 🔴 **지우는 문장 잣대가 살아 있는지 표본 넷으로 먼저** 확인하고 센다.
  if [ "$(printf '%s\n' 'DROP TABLE foo;' | grep -ciE "$DESTRUCTIVE_RE" || true)" != "1" ]; then
    bad "🔴 지우는 문장 잣대가 죽었다 — 아래 「0줄」이 공짜 통과다. 멈추세요"; rc=1
  else
    ok "지우는 문장 잣대가 살아 있다 (가짜 DROP 하나를 제대로 잡았다)"
  fi
  if [ "$(printf '%s\n' 'REFERENCES "b"("id") ON DELETE restrict;' | grep -ciE "$DESTRUCTIVE_RE" || true)" != "0" ]; then
    bad "🔴 ON DELETE 를 지우는 문장으로 센다 — **0126 이 가짜 ✗ 를 받는다**"; rc=1
  else
    ok "ON DELETE restrict 는 지우는 문장으로 안 센다 (앱의 migration-safety 와 같은 잣대다)"
  fi
  if [ "$(printf '%s\n' '--     DELETE FROM "role_permissions"' | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)" != "0" ]; then
    bad "🔴 **주석을 안 걷어낸다** — 0127 이 제 머리말(되돌리는 법) 때문에 가짜 ✗ 를 받는다"; rc=1
  else
    ok "주석 속 DELETE 는 안 센다 (0127 의 되돌리는 법이 가짜 ✗ 를 안 만든다)"
  fi
  if [ "$(printf '%s\n' '       "updated_by",' | grep -ciE "$DESTRUCTIVE_RE" || true)" != "0" ]; then
    bad "🔴 updated_by 같은 **칸 이름**을 지우는 문장으로 센다 — 0127 에서만 13 이 나온다"; rc=1
  else
    ok "updated_by·updated_at 칸 이름은 안 센다 (UPDATE 를 잣대에 안 넣었다)"
  fi
  # 🔵 일곱 전부를 센다 — 폴더를 통째로 갈아 끼우므로 일곱 다 본다.
  n=0
  for t in $AS_KEEP_MIGS; do
    f=$(ls -1 "$MIGDIR/${t}_"*.sql 2>/dev/null | head -1)
    [ -n "$f" ] || continue
    craw=$(grep -ciE "$DESTRUCTIVE_RE" "$f" 2>/dev/null || true)
    c=$(grep -v "$SQL_COMMENT_RE" "$f" 2>/dev/null | grep -ciE "$DESTRUCTIVE_RE" || true)
    printf '      %-6s 날것 %s줄 · 주석 걷은 뒤 %s줄\n' "$t" "${craw:-0}" "${c:-0}"
    n=$((n + ${c:-0}))
  done
  if [ "$n" = "$MIG_DROP_WANT" ]; then
    ok "0121~0127 에 지우는 문장이 ${n}줄이다 (기대 ${MIG_DROP_WANT}줄 — 더하기만 한다)"
    say "🔵 0127 은 **날것으로 세면 1줄**이 나옵니다 — 제 머리말에 적힌 되돌리는 법입니다."
  else
    bad "🔴 0121~0127 에 지우는 문장이 ${n}줄이다 (기대 ${MIG_DROP_WANT}줄) — 고치지 말고 **먼저 알리세요**"
    rc=1
  fi
  # 🔴 **0127 의 속을 본다** — 「이름이 맞다」와 「그 내용이다」는 다른 말이다.
  f=$(ls -1 "$MIGDIR/${AS_LAST_MIG}_"*.sql 2>/dev/null | head -1)
  if [ -n "${f:-}" ]; then
    local body ins conf alt crt leafok leafseen lf lc
    body=$(grep -v "$SQL_COMMENT_RE" "$f" 2>/dev/null)
    ins=$(printf '%s\n' "$body" | grep -c 'INSERT INTO "role_permissions"' || true)
    conf=$(printf '%s\n' "$body" | grep -c 'ON CONFLICT' || true)
    alt=$(printf '%s\n' "$body" | grep -c 'ALTER TABLE' || true)
    crt=$(printf '%s\n' "$body" | grep -c 'CREATE ' || true)
    say "$AS_LAST_MIG (주석 걷은 뒤) — INSERT ${ins:-0} · ON CONFLICT ${conf:-0} · ALTER ${alt:-0} · CREATE ${crt:-0} (기대 4·4·0·0)"
    if [ "${ins:-0}" = "4" ] && [ "${conf:-0}" = "4" ] && [ "${alt:-1}" = "0" ] && [ "${crt:-1}" = "0" ]; then
      ok "$AS_LAST_MIG 이 **INSERT ... SELECT 넷뿐**이고 넷 다 ON CONFLICT 다 (표를 한 칸도 안 바꾼다)"
    else
      bad "🔴 $AS_LAST_MIG 의 생김새가 기대와 다르다 — **표를 바꾸는 판일 수 있다.** 멈추고 알리세요"
      rc=1
    fi
    leafok=0; leafseen=0
    for lf in $PERM_LEAVES; do
      leafseen=$((leafseen+1))
      lc=$(printf '%s\n' "$body" | grep -cF "$PERM_OLD_KEY.$lf" || true)
      printf '      %s.%-10s %s번\n' "$PERM_OLD_KEY" "$lf" "${lc:-0}"
      if [ "${lc:-0}" -ge 1 ] 2>/dev/null; then leafok=$((leafok+1)); fi
    done
    if [ "$leafseen" = "$PERM_LEAVES_WANT" ] && [ "$leafok" = "$PERM_LEAVES_WANT" ]; then
      ok "$AS_LAST_MIG 이 잎 ${PERM_LEAVES_WANT}개를 다 적는다 (하나라도 빠지면 그 잎이 기본값으로 떨어진다)"
    else
      bad "🔴 잎이 ${leafok}/${leafseen} 개만 적혀 있다 — ${PERM_LEAVES_WANT}개를 기대했다"
      rc=1
    fi
  else
    hm "$AS_LAST_MIG 의 .sql 을 못 찾았다 — 위 줄을 보세요"
  fi
  return $rc
}

# ══ 🔴 덤프 — **이번 판에는 진짜 되돌릴 길이다** ══════════════════════
#   🔴 --migrate 가 **DB 의 자료를 바꾼다**(행이 0건일 수 있지만 0 이라는 보증은
#      배포 시점에만 있다). 그래서 바꾸기 직전의 사진이 필요하다.
#   🔵 **포털 DB 는 안 뜬다** — 이 배포가 dss_auth 를 한 글자도 안 바꾸고
#      야간 백업이 매일 받는다.
#   🔴 「파일이 생겼다」와 「쓸 만한 덤프다」는 다르다. 크기와 머리 다섯 글자를 본다.
#   🔴 **이름의 판 꼬리표가 $DUMP_VER 다** — 59번이 여기를 안 고쳐 v54 로 남겼다.
DUMP=""
make_dump() { # 1 왜 뜨는지 한 줄
  printf '\n    ── 덤프를 뜬다 (%s)\n' "$1"
  mkdir -p "$BKDB" 2>/dev/null
  DUMP="$BKDB/dss_as-$DUMP_VER-$STAMP.dump"
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
  say "🔵 **0127 은 더하기만 한다** — 되돌릴 일이 생기면 그 .sql 머리말의 DELETE 한"
  say "   문장이 더 빠르고 안전하다. 이 덤프는 그보다 더 나쁜 일이 났을 때의 길이다."
}

# ══ 🔴 양식 — 한 파일의 md5 (없으면 빈 줄) ════════════════════════════
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
  fi
}
# ══════════════════════════════════════════════════════════════════════
# 🔴 PO 가 repair_cases 에 **쓸 수 있는가** — 49번의 검사를 그대로
# ══════════════════════════════════════════════════════════════════════
#   🔴 **앱이 쓰는 길로 잰다.** 🔴 **보내는 것은 select 뿐이다.**
#   🔴 **작은따옴표를 한 글자도 안 쓴다** — 이 문자열이 셸의 작은따옴표 안에
#      들어가기 때문이다. SQL 문자열은 전부 **자리표**로 넘긴다.
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
PO_ROLE_PROBE='try{console.log(new URL(process.env.DATABASE_URL||"").username||"");}catch(e){console.log("");}'

po_priv_via_psql() {
  local role u s
  role=$("$DOCKER" exec "$PO_APP_CN" node -e "$PO_ROLE_PROBE" 2>/dev/null | tr -d ' \r')
  case "${role:-}" in
    ''|*[!A-Za-z0-9_]*) return 0 ;;
  esac
  u=$(pgq "$AS_BOX" "$AS_DB" "select has_table_privilege('$role','$PO_WRITE_TABLE','UPDATE')")
  s=$(pgq "$AS_BOX" "$AS_DB" "select has_table_privilege('$role','$PO_WRITE_TABLE','SELECT')")
  [ -n "${u:-}" ] || return 0
  printf 'PSQL role=%s update=%s select=%s' "$role" "${u:-?}" "${s:-?}"
}

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
        hm "PO 가 보는 DB 가 $db 다 — $AS_DB 를 기대했다. 사람이 보세요"; doubt
      fi
      if [ "${sel:-}" != "1" ]; then
        hm "SELECT 가 ${sel:-?} 다 — PO 는 오늘도 그 표를 읽으므로 **1 이어야 한다.** 검사 자신을 의심하세요"
        doubt; return
      fi
      if [ "${upd:-}" = "1" ]; then
        ok "PO 가 $PO_WRITE_TABLE 에 쓸 수 있다 (UPDATE=1 · SELECT=1 · 역할 $who)"; return
      fi
      if [ "$level" = soft ]; then
        hm "PO 가 $PO_WRITE_TABLE 에 **못 쓴다**(UPDATE=0) — 🔵 되돌리기는 막지 않는다"
      else
        bad "🔴 PO 가 $PO_WRITE_TABLE 에 **못 쓴다**(UPDATE=0) — **지금 운영이 고장나 있다는 뜻**이다"
        say "🔴 이 배포가 만든 일이 아니다(PO 를 안 건드린다). **사람이 보세요.**"
        doubt
      fi
      return ;;
    NOREL*)
      hm "PO 가 붙은 DB 에서 $PO_WRITE_TABLE 를 **못 찾았다** — 검사 자신을 의심하세요"
      doubt; return ;;
  esac
  say "🔵 앱이 쓰는 길로 못 쟀다 — psql 가지로 다시 묻는다."
  printf '%s\n' "$out" | tail -6 | sed 's/^/      /'
  pl=$(po_priv_via_psql)
  say "psql 가지로 받은 것: ${pl:-못 쟀다}"
  case "${pl:-}" in
    PSQL*)
      pu=${pl##* update=}; pu=${pu%% *}
      ps=${pl##* select=}; ps=${ps%% *}
      if [ "${ps:-}" != "t" ]; then
        hm "psql 가지의 SELECT 가 ${ps:-?} 다 — t 여야 한다. 검사 자신을 의심하세요"; doubt; return
      fi
      if [ "${pu:-}" = "t" ]; then
        ok "PO 의 역할이 $PO_WRITE_TABLE 에 쓸 수 있다 (psql 가지 · UPDATE=t · SELECT=t)"; return
      fi
      if [ "$level" = soft ]; then
        hm "PO 의 역할이 $PO_WRITE_TABLE 에 **못 쓴다**(psql 가지) — 🔵 되돌리기는 막지 않는다"
      else
        bad "🔴 PO 의 역할이 $PO_WRITE_TABLE 에 **못 쓴다**(psql 가지) — 지금 운영이 고장나 있다는 뜻이다"
        doubt
      fi
      return ;;
  esac
  hm "PO 의 $PO_WRITE_TABLE 쓰기 권한을 **두 길 다 못 쟀다** — 🔵 이 배포를 막지는 않는다"
  say "🔴 $PO_APP_CN 가 도는지, 그 안에서 node 가 도는지, $AS_BOX 가 도는지 보세요."
}

# ══ 🔴 재고 관리 통로가 **값을 돌려주는가** (45~59번 것을 글자 그대로) ══
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
        hm "200 인데 부품 줄이 ${rows:-?} 이다 — 응답 모양이 기대와 다르다. 사람이 보세요"; doubt
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
#   🔴 **이번 판을 실제로 재는 것은 넷이다**: 바뀐 **79개**가 담겼는가 ·
#      그 77장이 **전부 새 내용**인가 · **새 시험 여덟**이 등록돼 있는가 ·
#      이번 판의 **표식 일곱**이 있는가(다섯 커밋을 덮는다).
as_tools_inside_check() {
  local v got seen c nmiss nwrite ntx nok probe lines
  printf '\n    ── %s 안을 센다 (겉이 아니라 결과 · 🔵 소스가 **글자 그대로** 있다)\n' "$AS_TOOLS_NEW"
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/package.json: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "A/S tools 스테이지가 맞다" \
    || { bad "🔴 /app/package.json 이 없다 — **runner 를 구웠다.**"; doubt; }
  # ② 🔴 운영에서 불릴 npm 명령 **아홉**.
  #    🔴 **이번 판은 db:migrate 를 실제로 쓴다** — 없으면 --migrate 가 그 자리에서 멈춘다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync check-due-date-overdue check-delivered-date-sync procedures:export procedures:import db:preflight db:migrate; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "9" ] && ok "npm 명령 아홉이 이미지 안에 있다 (🔴 db:migrate 도 있다 — --migrate 가 선다)" \
    || { bad "🔴 명령이 ${got:-0}/9 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다**"; doubt; }
  # ③ 🔴 **이번 판이 바꾼 79개가 담겼는가.** 🔴 59번은 10개였다.
  #    🔵 목록에 **대괄호·괄호가 25개** 있다 — set -f · 환경변수 · while read · 큰따옴표.
  #    🔵 79줄을 다 찍으면 DSM 터미널이 넘치므로 **「no」 줄과 셈만** 찍는다.
  v=$("$DOCKER" run --rm -e DSS_FILES="$AS_CHANGED_SRC$AS_CHANGED_SCRIPTS" --entrypoint sh "$AS_TOOLS_NEW" -c 'set -f; printf "%s\n" "$DSS_FILES" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | grep '^no  ' | sed 's/^/      /'
  printf '%s\n' "$v" | grep '^yes ' | head -3 | sed 's/^/      (보기) /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  seen=$(printf '%s\n' "$v" | grep -cE '^(yes|no ) ' || true)
  say "본 것 ${seen:-0}개 · 있는 것 ${got:-0}개 (기대 $AS_CHANGED_ALL_WANT · $AS_CHANGED_ALL_WANT — src/ $AS_CHANGED_SRC_WANT + scripts/ $AS_CHANGED_SCRIPTS_WANT)"
  if [ "${seen:-0}" = "$AS_CHANGED_ALL_WANT" ] && [ "${got:-0}" = "$AS_CHANGED_ALL_WANT" ]; then
    ok "이번 판이 바꾼 $AS_CHANGED_ALL_WANT 개가 다 담겼다 (**표본이 비지 않았다** · 대괄호 경로도 그대로 읽혔다)"
  else
    bad "🔴 본 것 ${seen:-0} · 있는 것 ${got:-0} 다 — ${AS_CHANGED_ALL_WANT}/${AS_CHANGED_ALL_WANT} 을 기대했다"
    say "🔴 본 것이 모자라면 **목록을 넘기는 길이 끊긴 것**(글롭 함정)이고,"
    say "   있는 것만 모자라면 **옛 소스가 담긴 이미지**입니다."
    doubt
  fi
  # ③-ㄴ 🔴 **그 77장이 전부 새 내용인가** — 날짜 글자로 덮는다.
  #    🔴 **없는 경로 하나를 함께 묻는다** — 「무조건 yes」가 아닌지 가른다.
  v=$("$DOCKER" run --rm -e DSS_FILES="$AS_CHANGED_SRC" -e M="$FRESH_MARK" --entrypoint sh "$AS_TOOLS_NEW" -c 'set -f; printf "%s\n%s\n" "$DSS_FILES" "src/__dss_probe_no_such_file__.ts" | while IFS= read -r f; do [ -n "$f" ] || continue; if grep -qF -- "$M" "/app/$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | grep '^no  ' | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  probe=$(printf '%s\n' "$v" | grep -c '^no  src/__dss_probe_no_such_file__' || true)
  say "새 내용 — $FRESH_MARK 가 든 파일 ${got:-0}개 (기대 $AS_CHANGED_SRC_WANT · 없는 경로 하나는 no 여야 한다)"
  if [ "${probe:-0}" != "1" ]; then
    bad "🔴 **없는 경로가 no 로 안 나왔다** — 「무조건 yes」인 검사다. 위 yes 도 못 믿는다"
    doubt
  elif [ "${got:-0}" = "$AS_CHANGED_SRC_WANT" ]; then
    ok "바뀐 ${AS_CHANGED_SRC_WANT}장이 **전부 새 내용**이다 (옛 소스가 섞여 있지 않다)"
    say "🔵 이번 판은 **새로 생긴 파일이 ${AS_BORN_SRC_WANT}장**입니다(59번은 0장이었습니다)."
  else
    bad "🔴 새 내용인 것이 ${got:-0}/${AS_CHANGED_SRC_WANT} 장이다 — **옛 소스가 담긴 이미지다.** 올리지 마세요"
    doubt
  fi
  # ③-ㄷ 🔴 **새 시험 여덟이 이미지 안의 목록 파일에 등록돼 있는가.**
  #    🔴 59번은 여기가 「**고친** 시험 여섯」이었다 — 이번 판에는 새 시험이 여덟 장이다.
  #    🔴 **목록 파일은 CRLF 다** — tr -d 로 \r 를 걷어낸 뒤 -Fx 로 맞댄다.
  #    🔴 **읽은 줄 수를 함께 받아 너무 적으면 ✗** · **없는 경로 하나를 함께 묻는다.**
  #    🔴 **cat 의 글롭은 set -f 앞에** 둔다 — 뒤에 두면 *.txt 가 글자 그대로 남는다.
  v=$("$DOCKER" run --rm -e DSS_TESTS="$AS_NEW_TESTS" -e DSS_MISS="$REG_PROBE_MISS" --entrypoint sh "$AS_TOOLS_NEW" -c 'L=$(cat /app/scripts/test-lists/*.txt 2>/dev/null | tr -d "\r"); echo "lines $(printf "%s\n" "$L" | grep -c .)"; set -f; printf "%s\n%s\n" "$DSS_TESTS" "$DSS_MISS" | while IFS= read -r t; do [ -n "$t" ] || continue; n=$(printf "%s\n" "$L" | grep -cFx -- "$t"); if [ "${n:-0}" -ge 1 ]; then echo "yes $t"; else echo "no  $t"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  probe=$(printf '%s\n' "$v" | grep -c "^no  $REG_PROBE_MISS" || true)
  lines=$(printf '%s\n' "$v" | sed -n 's/^lines //p')
  say "\\r 를 걷어내고 읽은 목록 줄 수: ${lines:-?}개 (기대 $AS_TESTLIST_MIN_LINES 이상 · 개발 PC 실측 3698)"
  if ! isnum "${lines:-}" || [ "${lines:-0}" -lt "$AS_TESTLIST_MIN_LINES" ]; then
    bad "🔴 이미지 안 목록을 ${lines:-못 읽음}줄밖에 못 읽었다 — **빈 결과는 삼켜진 오류일 수 있다**"
    doubt
  elif [ "${probe:-0}" != "1" ]; then
    bad "🔴 **없는 경로가 no 로 안 나왔다** — 줄 전체 일치가 깨졌다. 아래 yes 도 못 믿는다"
    doubt
  elif [ "${got:-0}" = "$AS_NEW_TESTS_WANT" ]; then
    ok "이번 판이 새로 만든 시험 $AS_NEW_TESTS_WANT 개가 목록에 등록돼 있다 (조용히 안 도는 일은 없다)"
    say "🔵 없는 경로 하나는 **no** 로 나왔습니다 — 「무조건 yes」인 검사가 아닙니다."
  else
    bad "🔴 등록된 것이 ${got:-0}/${AS_NEW_TESTS_WANT} 개다 — **옛 목록 파일이 담겼다**"
    doubt
  fi
  # ③-ㄹ 🔵 **시험 목록 파일 넷이 이미지 안에 있는가** — 위 ③-ㄷ 이 설 바탕이다.
  v=$("$DOCKER" run --rm -e DSS_LISTS="$AS_TESTLIST_FILES" --entrypoint sh "$AS_TOOLS_NEW" -c 'set -f; printf "%s\n" "$DSS_LISTS" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "$AS_TESTLIST_FILES_WANT" ] && ok "시험 목록 파일 ${AS_TESTLIST_FILES_WANT}장이 이미지에 담겼다" \
    || { bad "🔴 목록 파일이 ${got:-0}/${AS_TESTLIST_FILES_WANT} 장이다 — scripts/ 가 온전히 안 담겼다"; doubt; }
  # ③-ㅁ 🔴 **이 파일이 든 「바뀐 목록」에 scripts/ 가 정말 2줄인가.**
  #    🔴 **59번은 여기가 「0줄인가 · 1 이상이면 ✗」였다.** 뜻이 뒤집혔다 —
  #       이번 판은 **2 가 정답**이다. 먼저 **세는 길이 살아 있는지** 가짜 목록으로
  #       확인하고, 그 다음에 이 파일의 목록이 2줄인지 본다.
  probe=$(printf '%s\n' 'src/lib/x.ts' 'scripts/test-lists/unit.txt' 'package.json' | grep -c '^scripts/' || true)
  c=$(printf '%s\n' "$AS_CHANGED_SCRIPTS" | grep -c '^scripts/' || true)
  say "표본 — 가짜 목록 세 줄에서 scripts/ 로 시작하는 줄 ${probe:-?}개 (기대 1)"
  say "이 파일이 든 scripts/ 변경 목록: ${c:-0}줄 (기대 $AS_CHANGED_SCRIPTS_WANT — 🔴 59번은 0 이었다)"
  if [ "${probe:-0}" != "1" ]; then
    bad "🔴 scripts/ 를 세는 길이 죽었다 — 아래 수가 공짜 통과다"
    doubt
  elif [ "${c:-x}" = "$AS_CHANGED_SCRIPTS_WANT" ]; then
    ok "이번 판이 바꾼 scripts/ 파일이 ${AS_CHANGED_SCRIPTS_WANT}개다 (**시험 목록 둘을 고쳐 올렸다**)"
    say "🔵 그것이 **새 시험이 여덟 장**인 것과 앞뒤가 맞습니다 — 등록할 자리가 둘이었습니다."
  else
    bad "🔴 scripts/ 변경이 ${c:-?}줄이다 — ${AS_CHANGED_SCRIPTS_WANT}줄을 기대했다. 이 파일의 목록을 보세요"
    doubt
  fi
  # ④ 🔴 **그 안에 이번 판의 글자가 있는가** — 표식 일곱(다섯 커밋을 덮는다).
  #    🔴 59번의 여섯은 **이번 판이 하나도 안 건드린다** — 그대로 두면 옛 판에서도 ✓ 다.
  v=$("$DOCKER" run --rm -e DSS_MARKS="$AS_MARKS" --entrypoint sh "$AS_TOOLS_NEW" -c 'set -f; printf "%s\n" "$DSS_MARKS" | while IFS= read -r pair; do [ -n "$pair" ] || continue; m=${pair%%|*}; f=${pair#*|}; if grep -qF -- "$m" "/app/$f" 2>/dev/null; then echo "yes $m $f"; else echo "no  $m $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  seen=$(printf '%s\n' "$v" | grep -cE '^(yes|no ) ' || true)
  say "표식 — 본 것 ${seen:-0}개 · 있는 것 ${got:-0}개 (기대 $AS_MARKS_WANT · $AS_MARKS_WANT)"
  if [ "${seen:-0}" = "$AS_MARKS_WANT" ] && [ "${got:-0}" = "$AS_MARKS_WANT" ]; then
    ok "이번 판의 표식 $AS_MARKS_WANT 개가 이미지 안에 있다 (**다섯 커밋이 다 담겼다**)"
    say "🔵 일곱 다 **기준판 $AS_BASE_SHORT 에는 0번**이고 이번 다섯 커밋이 넣은 글자입니다."
  else
    bad "🔴 본 것 ${seen:-0} · 있는 것 ${got:-0} 다 — **커밋 하나가 빠진 판일 수 있다.** 올리지 마세요"
    doubt
  fi
  # ⑤ 🔵 **공용 스키마가 담겼는가** — 없으면 Cannot find module 이 난다.
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
  # ⑥ 🔴 **drizzle-kit 이 있는가** — 🔴 이번 판은 **실제로 db:migrate 를 부른다.**
  #    🔵 59번은 「다음 판의 준비」로 세었다. **이번 판이 그 다음 판이다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "test -d /app/node_modules/drizzle-kit && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/node_modules/drizzle-kit: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "drizzle-kit 이 있다 (🔴 **이번 판의 --migrate 가 이것으로 돈다**)" \
    || { bad "🔴 drizzle-kit 이 없다 — **--migrate 가 그 자리에서 죽는다.** 올리지 마세요"; doubt; }
  # ⑦ 🔴 **값으로 받아 본다.** 'npm run …' 이어야 Missing script 가 드러난다.
  for c in db:preflight db:migrate check:due-date-overdue procedures:import; do
    v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "cd /app && npm run $c 2>&1 | head -40" 2>&1 | tr -d '\r')
    if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
      bad "🔴 npm run $c — **Missing script** (41번과 같은 실패다)"
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
  # ⑨ 🔵 지난 판들이 올린 도구가 **아직 있는가**
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts /app/scripts/check-delivered-date-sync.ts /app/scripts/lib/delivered-date-sync-survey.ts /app/scripts/import-procedure-bundle.ts /app/scripts/export-procedure-bundle.ts /app/scripts/lib/procedure-template-bundle.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | grep '^no  ' | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "9" ] && ok "48~55번이 올린 도구 아홉이 다 들어 있다" \
    || bad "🔴 도구 파일이 ${got:-0}/9 개다 — scripts/ 가 온전히 안 담겼다"
  # ⑩ 🔵 엑셀 읽개 둘이 **개발 DB 자물쇠**를 그대로 부르는가.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for f in /app/scripts/import-technical-task-procedures.ts /app/scripts/link-technical-task-next-procedures.ts; do if grep -q checkDevelopmentWriteTarget "$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "2" ] && ok "엑셀 읽개 둘이 개발 DB 자물쇠를 부른다 (NAS 에서 부르면 막힌다)" \
    || { bad "🔴 자물쇠를 부르는 것이 ${got:-0}/2 개다. **운영 DB 에 쓸 수 있는 판이다.** 올리지 마세요"; doubt; }
  # ⑪ tsx 가 있는가
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/node_modules/tsx: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "A/S 도구에 tsx 가 있다" \
    || bad "🔴 tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다"
  # ⑫ 🔴 이미지 안의 drizzle/ 은 **비어 있어야** 한다 — 볼륨으로 붙는 자리다.
  #    🔴 **이번 판에서 특히 중요하다** — 0127 이 이미지 안에도 있으면 볼륨과
  #       이미지 중 어느 것이 돌았는지 알 수 없게 된다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  say "/app/drizzle 안 .sql: ${v:-?}개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)"
  if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then ok "이미지 안 drizzle/ 이 비어 있다 (🔴 그래서 0127 은 **볼륨으로** 가야 한다)"
  else bad "🔴 이미지 안 drizzle/ 에 .sql 이 들었다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다"; doubt; fi
}

# ══ 🔴 A/S **앱** 이미지 안을 센다 ════════════════════════════════════
#   🔴 앱 이미지는 도구와 달리 **번들**이다 — 소스가 없다. 그래서 파일 경로가
#      아니라 **글자 리터럴**로만 가를 수 있다.
#   🔴 **상수 이름·함수 이름으로 재지 않는다** — minify 에 지워질 수 있어
#      멀쩡한 이미지가 ✗ 가 된다.
#   🔴 **번들에서 세어 본 적이 없다**(개발 PC 에 standalone 이 없다) — 그래서
#      수를 박지 않고 **「합이 1 이상」으로만** 잰다. ✗ 가 나면 검사부터 의심한다.
as_app_inside_check() { # 1 태그
  local tag v a b kb km
  tag=$1
  printf '\n    ── %s 안을 센다 (🔵 번들이다 — 소스가 없다)\n' "$tag"
  # ① runner 가 맞는가 — tools 에는 /app/server.js 가 없다.
  v=$("$DOCKER" run --rm --entrypoint sh "$tag" -c "test -f /app/server.js && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/server.js: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "runner 스테이지가 맞다 (node server.js 를 안다)" \
    || { bad "🔴 /app/server.js 가 없다 — **runner 가 아닌 것을 실었다.** 갈아 끼우지 마세요"; doubt; }
  # ② 🔴 이번 판의 글자(ASCII) — **권한 열쇠 문자열**이다.
  #    🔴 59번의 2026-11-12 는 **못 쓴다** — 기준판 src/ 에 이미 10파일 있다.
  v=$("$DOCKER" run --rm -e M="$APP_MARK" --entrypoint sh "$tag" -c 'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  a=$(printf '%s' "$v" | awk '{print $1}'); b=$(printf '%s' "$v" | awk '{print $2}')
  say "$APP_MARK 가 든 파일 — .next/server ${a:-?}개 · .next/static ${b:-?}개 (🔴 합이 1 이상이어야 한다)"
  if isnum "${a:-}" && isnum "${b:-}" && [ "$((a + b))" -ge 1 ]; then
    ok "번들에 이번 판의 글자가 있다 (옛 판이 아니다 — 권한 잎이 쪼개진 판이다)"
    say "🔵 소스에서는 기준판 0파일 → 지금 17파일입니다(2026-11-12 실측)."
  else
    bad "🔴 번들에 $APP_MARK 가 없다 — **옛 판을 실었다.** 갈아 끼우지 마세요"
    say "🔵 **검사 자신도 의심하세요** — 이 글자는 소스에서만 세어 보았고"
    say "   **번들에서 세어 본 적이 없습니다**(개발 PC 에 standalone 이 없습니다)."
    doubt
  fi
  # ③ 🔴 **한글 표식** — [역할별 접근 권한]의 새 묶음 머리말이다.
  #    🔴 **명령에 한글을 넣지 않는다.** 8진 이스케이프를 넘기고 컨테이너 안에서
  #       다시 만든다. 🔴 바이트 수를 먼저 받아 가른다(기대 23).
  v=$("$DOCKER" run --rm -e O="$APP_MARK_KO_OCT" --entrypoint sh "$tag" -c 'k=$(printf "$O"); n=$(printf "%s" "$k" | wc -c); printf "%s %s %s\n" "$n" "$(grep -rlF "$k" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$k" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  kb=$(printf '%s' "$v" | awk '{print $1}'); a=$(printf '%s' "$v" | awk '{print $2}'); b=$(printf '%s' "$v" | awk '{print $3}')
  say "한글 표식 — 만든 글자 ${kb:-?}바이트(기대 $APP_MARK_KO_BYTES) · server ${a:-?}개 · static ${b:-?}개"
  if [ "${kb:-0}" != "$APP_MARK_KO_BYTES" ]; then
    hm "컨테이너 안에서 한글 표식을 **못 만들었다**(${kb:-?}바이트) — 🔴 위 수의 0 은 「없다」가 아니다"
    say "🔵 ② 가 ✓ 라면 판은 맞습니다 — **이 줄만으로 갈아 끼우기를 막지 않습니다.**"
  elif isnum "${a:-}" && isnum "${b:-}" && [ "$((a + b))" -ge 1 ]; then
    ok "새 묶음 머리말(한글)이 번들에 있다 — **권한 화면이 새 모양으로 뜬다**"
  else
    bad "🔴 그 한글 글자가 번들에 없다 — **옛 판을 실었다.** 갈아 끼우지 마세요"
    doubt
  fi
  # ④ 🔵 **뒷걸음 방지 — 🔴 이번 판에서 둘 → 셋이 됐다.**
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
  [ "$km" = "$APP_KEEP_MARKS_WANT" ] && ok "뒷걸음 방지 ASCII ${APP_KEEP_MARKS_WANT}개를 다 봤다 (표본이 비지 않았다)" \
    || bad "🔴 뒷걸음 방지를 ${km}개만 봤다 — ${APP_KEEP_MARKS_WANT}개를 기대했다. APP_KEEP_MARKS 가 깨졌다"
  # 🔴 뒷걸음 방지 ③ — **쉰다섯째(59번)가 올린 한글 글자.** 🔴 59번에는 없던 자리다.
  v=$("$DOCKER" run --rm -e O="$KEEP_MARK3_KO_OCT" --entrypoint sh "$tag" -c 'k=$(printf "$O"); n=$(printf "%s" "$k" | wc -c); printf "%s %s %s\n" "$n" "$(grep -rlF "$k" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$k" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  kb=$(printf '%s' "$v" | awk '{print $1}'); a=$(printf '%s' "$v" | awk '{print $2}'); b=$(printf '%s' "$v" | awk '{print $3}')
  say "뒷걸음 방지 ③(쉰다섯째 한글) — 만든 글자 ${kb:-?}바이트(기대 $KEEP_MARK3_KO_BYTES) · server ${a:-?}개 · static ${b:-?}개"
  if [ "${kb:-0}" != "$KEEP_MARK3_KO_BYTES" ]; then
    hm "그 한글을 컨테이너 안에서 **못 만들었다**(${kb:-?}바이트) — 위 0 은 「없다」가 아니다"
  elif isnum "${a:-}" && isnum "${b:-}" && [ "$((a + b))" -ge 1 ]; then
    ok "쉰다섯째(59번)가 올린 글자가 그대로 있다 (**59번보다 옛 나무가 아니다**)"
  else
    bad "🔴 쉰다섯째가 올린 글자가 없다 — **59번보다 옛 나무를 실었다.** 갈아 끼우지 마세요"
    doubt
  fi
  # ⑤ 🔵 public/ — 없으면 아이콘·정적 파일이 404 가 되고 첫 화면부터 깨진다.
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

# ══ 🔵 발주서 공유폴더가 **열리는가** — 🔴 이번 판의 핵심 자리는 아니다 ══
#   🔴 그래도 **빼지 않는다**(42~59번의 규율). ✗ 가 나면 **지난 판이 올린 기능이
#      지금 고장나 있다**는 뜻이고, 되돌려도 안 고쳐진다.
purchase_order_archive_check() {
  local n
  printf '\n    ── 발주서 공유폴더가 열리는가 (🔵 **이번 판은 안 건드린다** · 지난 판 것을 지킨다)\n'
  n=$("$DOCKER" exec "$AS_APP_CN" sh -c "ls $PO_ARCHIVE 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  say "$AS_APP_CN 안에서 본 $PO_ARCHIVE 의 항목 ${n:-못 쟀다}개"
  if ! isnum "${n:-}"; then
    hm "못 쟀다 — $AS_APP_CN 가 도는지 보세요. **빈 결과는 삼켜진 오류일 수 있다**"
  elif [ "${n:-0}" -ge 1 ]; then
    ok "발주서 폴더가 열린다 (${n}개)"
    say "🔵 이번 판이 **그 탭에 권한 관문을 세웁니다** — 폴더가 안 열리면 관문과 무관하게 빕니다."
  else
    bad "🔴 발주서 폴더가 **비었다** — 볼륨 줄은 있는데 안 열린다. [발주서] 탭이 **조용히** 빈다"
    say "🔵 **이 배포가 만든 일이 아니다.** compose 의 app-as 볼륨과 공유폴더 권한을 보세요."
    doubt
  fi
}

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
# 🔴 **이 배포가 실제로 바꾸는 자리를 센다** — 🔴 59번 것을 통째로 갈았다
# ══════════════════════════════════════════════════════════════════════
#   🔴 59번은 **종 줄 수**(영업·관리자·최고관리자가 받게 될 「승인 완료」 줄)를
#      셌다. **그 수는 이번 판과 아무 상관이 없다.** 그대로 베껴 두면 이 배포를
#      재는 숫자가 **하나도 없다** — 그래서 재는 것을 통째로 바꿨다.
#   🔵 **select 뿐이고 한 글자도 안 쓴다.**
#
#   🔴 **이 배포는 DB 를 거의 안 바꾼다** — 마이그레이션이 옮기는 행이 운영에
#      0건이다(2026-11-12 실측). 그래서 「전후 차이」로는 거의 못 잰다. 대신
#      **새 코드가 보여 주게 될 것을 미리 센다**(59번이 그렇게 했다).
#
#   🔴 **앱이 쓰는 조회 함수의 WHERE 를 그대로 베꼈다.** 베낀 자리는 아래 각 절의
#      주석에 적었다. 🔴 **칸 이름만 보고 짜면 틀린다** — ⑤ 가 그 실물이다.
#
# ── 🔴 ⑤ 가 쓰는 SQL — **앱의 조건을 그대로 옮겼다** ─────────────────
#    🔴 **큰따옴표를 한 글자도 안 쓴다**(pgq 안에서 큰따옴표에 싸인다).
#    🔴 **달러 기호도 안 쓴다**(컨테이너 안 sh 가 치환해 버린다).
#    베낀 자리 셋:
#      · queries/repair-case-approvals.ts 의 loadRepairCaseFinalShipmentApprovalStates()
#        — repair_case_approvals ⨝ repair_cases (**INNER JOIN**)
#        — approval_type = 'FINAL_SHIPMENT'
#        — **requested_at 내림차순의 첫 행 하나만** 본다(distinct on 이 그것이다)
#      · domain/local/workflow/shipment-approval-checklist.ts 의 resolveApprovalState()
#        — status 가 APPROVED 이고 **repair_case_version_at_request = repair_cases.version**
#          이어야 APPROVED 다. 🔴 어긋나면 **STALE 이고 배지가 안 붙는다.**
#      · app/(app)/repair-cases/page.tsx — 휴지통을 뺀 목록이라 **is_deleted = false**.
FS_LATEST_CTE="with latest as (select distinct on (rca.repair_case_id) rca.repair_case_id as cid, rca.status::text as st, rca.repair_case_version_at_request as vreq, rc.version as vnow from repair_case_approvals rca join repair_cases rc on rc.id = rca.repair_case_id where rca.approval_type::text = 'FINAL_SHIPMENT' and rc.is_deleted = false order by rca.repair_case_id, rca.requested_at desc) "

effect_counts() {
  local lf n tot sum rows dead deadtot naive real roles kinds
  printf '\n    ── 🔴 이 배포가 바꾸는 자리 (운영 수 · **select 뿐이다**)\n'
  say "🔴 59번은 여기서 **종 줄 수**를 셌습니다 — 그 수는 이번 판과 아무 상관이 없어"
  say "   통째로 갈았습니다. 🔵 이번 판이 재는 것은 **권한 행과 새 거르개**입니다."

  # ── ① 🔴 마이그레이션이 **옮길 행 수** ────────────────────────────
  #    🔴 ON CONFLICT DO NOTHING 을 흉내 낸다 — 「옛 행이 있고 그 잎에 아직 행이
  #       없는」 것만 센다. 옛 행 수만 세면 **이미 옮겨진 판에서도** 그 수가 나와
  #       「아직 할 일이 있다」로 잘못 읽힌다.
  printf '\n    ① 🔴 마이그레이션(%s)이 **옮길 행 수** — 잎마다\n' "$AS_LAST_MIG"
  sum=0; tot=0
  for lf in $PERM_LEAVES; do
    n=$(perm_pending_for "$lf")
    printf '        %s.%-10s %s줄\n' "$PERM_OLD_KEY" "$lf" "${n:-못 쟀다}"
    if isnum "${n:-}"; then sum=$((sum + n)); tot=$((tot + 1)); fi
  done
  if [ "$tot" != "$PERM_LEAVES_WANT" ]; then
    hm "잎 ${tot}개만 쟀다 — ${PERM_LEAVES_WANT}개를 기대했다. $AS_BOX 가 도는지, 그 표가 있는지 보세요"
    say "🔴 **빈 결과는 삼켜진 오류일 수 있다** — 「0줄」과 「못 쟀다」는 다른 말이다."
    doubt
  else
    say "        합계 ${sum}줄"
    if [ "$sum" -ge 1 ]; then
      ok "--migrate 가 넣을 행이 **${sum}줄**이다 (잎 ${PERM_LEAVES_WANT}개에 나누어 들어간다)"
      say "🔴 **--migrate 뒤에 이 수가 0 이 되어야** 정상입니다. 안 되면 적용이 안 된 것입니다."
    else
      hm "옮길 행이 **0줄이다** — 🔵 **배포가 잘못된 것이 아닙니다.**"
      say "   운영이 **전부 코드 기본값으로 돈다**는 뜻이고, 2026-11-12 실측이 그랬습니다"
      say "   (area_key in ('domesticOrders','miscCases','quotes') → 0 rows)."
      say "🔴 **그래도 --migrate 를 건너뛰지 마세요** — 기록이 $AS_MIG_AFTER 가 되어야"
      say "   --go 가 섭니다. 판은 0건이어도 조용히 통과합니다."
      say "🔵 이 수는 **배포 직전에 다시 세는 것이 요점**입니다 — 그 사이에 누가 권한"
      say "   화면에서 저장하면 행이 생깁니다."
    fi
  fi

  # ── ② 🔵 role_permissions 에 저장된 행 — **앱의 조회에는 WHERE 가 없다** ──
  #    🔴 queries/role-permissions.ts 의 loadStoredRolePermissions() 는
  #       'select role, area_key, level from role_permissions' 를 **조건 없이** 읽고,
  #       그 뒤 **코드에서** isPermissionLeafKey(row.areaKey) 로 거른다.
  #       그래서 여기도 **조건 없이** 전부 읽는다 — 그것이 앱의 잣대다.
  printf '\n    ② 🔵 %s 에 저장된 행 — area_key 별 (🔴 앱의 조회에는 WHERE 가 없다)\n' "$PERM_TABLE"
  tot=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $PERM_TABLE")
  rows=$(pgrows "$AS_BOX" "$AS_DB" "select area_key || ' ' || count(*) from $PERM_TABLE group by area_key order by 1")
  if [ -z "${tot:-}" ]; then
    hm "$PERM_TABLE 를 **못 쟀다** — $AS_BOX 가 도는지, 그 표가 있는지 보세요"
    doubt
  else
    printf '%s\n' "$rows" | grep -v '^[[:space:]]*$' | sed 's/^/        /'
    say "        전체 ${tot}줄"
    ok "저장된 권한 행을 값으로 쟀다 (${tot}줄 · 조건 없이 전부 읽었다 — 앱과 같은 잣대다)"
    if [ "${tot:-0}" = "0" ]; then
      say "🔵 **0줄이면 운영이 전부 코드 기본값으로 돈다**는 뜻입니다 — 그것이 2026-11-12 실측입니다."
    fi
  fi

  # ── ③ 🔴 **앱이 조용히 버리는 행** — 잎이 아닌 열쇠로 저장된 행 ────
  #    🔴 그 행은 판정에 한 번도 안 끼고, 그 역할은 **오류 한 줄 없이** 기본값으로 돈다.
  printf '\n    ③ 🔴 **앱이 조용히 버리는 행** — 잎이 아닌 열쇠로 저장된 것\n'
  deadtot=0; dead=0
  for lf in $PERM_DEAD_KEYS; do
    n=$(perm_rows_of "$lf")
    printf '        %-20s %s줄\n' "$lf" "${n:-못 쟀다}"
    if isnum "${n:-}"; then deadtot=$((deadtot + n)); dead=$((dead + 1)); fi
  done
  if [ "$dead" != "4" ]; then
    hm "넷 중 ${dead}개만 쟀다 — 사람이 보세요"
  else
    say "        합계 ${deadtot}줄"
    if [ "${deadtot:-0}" = "0" ]; then
      ok "잎이 아닌 열쇠로 저장된 행이 **없다** (조용히 버려지는 설정이 없다)"
    else
      hm "잎이 아닌 열쇠로 저장된 행이 ${deadtot}줄 있다 — 🔵 **이 배포를 막지 않는다**"
      say "🔴 그 행은 **판정에 한 번도 안 낍니다** — 그 역할은 오류 없이 코드 기본값으로 돕니다."
      say "🔵 inventory.stock 이 그렇게 죽어 있는 실물이고, 0127 의 머리말이 그것을 근거로 듭니다."
      say "🔴 **--migrate 뒤에도 $PERM_OLD_KEY 쪽은 그대로 남는 것이 정상입니다** —"
      say "   0127 은 옛 행을 **안 지웁니다**(되돌리기를 한 문장으로 두려고)."
      say "🔵 권한 화면에서 그 역할을 한 번 저장하면 그 행은 저절로 정리됩니다."
    fi
  fi

  # ── ④ 🔵 역할별 사람 수 — 탭 관문이 **몇 사람의 화면을 바꾸는가** ──
  printf '\n    ④ 🔵 역할별 사람 수 (활성 · 휴지통 뺌) — 탭 관문이 몇 사람의 화면을 바꾸는가\n'
  roles=$(pgrows "$AS_BOX" "$AS_DB" "select role::text || ' ' || count(*) from users where is_active and not is_deleted group by 1 order by 1")
  n=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from users where is_active and not is_deleted")
  if [ -z "${n:-}" ]; then
    hm "사람 수를 **못 쟀다** — $AS_BOX 가 도는지 보세요"
  else
    printf '%s\n' "$roles" | grep -v '^[[:space:]]*$' | sed 's/^/        /'
    say "        전체 ${n}명"
    if [ "${n:-0}" -ge 1 ]; then
      ok "역할별 사람 수를 값으로 쟀다 (활성 ${n}명)"
      say "🔴 **탭 여덟의 기본값은 지금과 같습니다** — 배포 직후 아무도 못 보게 되는 일은 없습니다."
    else
      hm "활성 계정이 **한 명도 없다** — 이 배포로 달라질 사람이 없다는 뜻입니다. 사람이 보세요"
    fi
  fi

  # ── ⑤ 🔴 **[최종 출하 승인 완료] 거르개가 보여 줄 건 수** ──────────
  #    🔴 **칸 이름만 보고 짜면 틀린다** — 개발 DB 실측에서 「최신이 APPROVED 인
  #       건」은 **7건**인데 판 번호까지 맞는 것은 **1건**이었다. 여섯은 STALE 이라
  #       배지가 안 붙는다. 그래서 **둘을 나란히 찍는다.**
  printf '\n    ⑤ 🔴 **새 거르개 [최종 출하 승인 완료] 가 보여 줄 건 수** (앱의 조건을 그대로 베꼈다)\n'
  naive=$(pgn "$AS_BOX" "$AS_DB" "${FS_LATEST_CTE}select count(*) from latest where st = 'APPROVED'")
  real=$(pgn "$AS_BOX" "$AS_DB" "${FS_LATEST_CTE}select count(*) from latest where st = 'APPROVED' and vreq = vnow")
  say "최신 결재가 APPROVED 인 건:                ${naive:-못 쟀다}건  ← 🔴 **이것은 앱의 잣대가 아니다**"
  say "그중 판 번호까지 맞는 건(= 배지가 붙는다): ${real:-못 쟀다}건  ← 🔵 **거르개가 실제로 보여 줄 수**"
  if [ -z "${naive:-}" ] || [ -z "${real:-}" ]; then
    hm "거르개 건수를 **못 쟀다** — 그 표들이 있는지 보세요"
    say "🔴 **빈 결과는 삼켜진 오류일 수 있다** — 「0건」과 「못 쟀다」는 다른 말이다."
    doubt
  else
    ok "새 거르개가 보여 줄 건을 값으로 쟀다 (앱의 조건: 최신 하나 · APPROVED · 판 번호 일치 · 휴지통 뺌)"
    if [ "${naive:-0}" != "${real:-0}" ]; then
      say "🔴 **둘이 다릅니다** — 차이 $((naive - real))건은 **STALE** 입니다(승인 뒤에 건이 고쳐져"
      say "   판 번호가 어긋난 것). 🔵 배지가 안 붙으므로 거르개에도 **안 나오는 것이 맞습니다.**"
      say "   🔵 개발 DB 에서도 7 vs 1 로 갈렸습니다 — 칸 이름만 보고 짜면 틀리는 자리입니다."
    fi
    if [ "${real:-0}" = "0" ]; then
      hm "거르개가 보여 줄 건이 **0건이다** — 🔵 **배포가 잘못된 것이 아닙니다.**"
      say "   지금 그런 건이 없다는 뜻이고, 거르개 줄 자체는 화면에 뜹니다(고르면 0건이 나옵니다)."
    else
      say "🔴 **배포 뒤에 [전체 A/S 현황]에서 그 줄을 골라 ${real}건이 나오는지 보세요** —"
      say "   그 건들에는 **[최종 출하 승인 완료] 배지**가 붙어 있어야 합니다(같은 묶음입니다)."
    fi
  fi

  # ── ⑥ 🔵 결재 종류별 줄 수 — [검수/승인] 탭이 들고 있는 규모 ──────
  printf '\n    ⑥ 🔵 결재 종류별 줄 수 (판정하지 않는다 · 규모를 본다)\n'
  kinds=$(pgrows "$AS_BOX" "$AS_DB" "select approval_type::text || ' ' || count(*) from repair_case_approvals group by 1 order by 1")
  if [ -z "${kinds:-}" ]; then
    hm "결재 줄 수를 못 쟀다 — 🔵 이 배포를 막지 않는다"
  else
    printf '%s\n' "$kinds" | grep -v '^[[:space:]]*$' | sed 's/^/        /'
    ok "결재 종류별 줄 수를 값으로 쟀다 (이번 판이 [검수/승인] 탭에 관문을 세운다)"
  fi
  printf '\n'
  say "🔴 **--migrate 전후로 ① 이 0 이 되고 ② 가 늘어야** 정상입니다."
  say "🔴 나머지(③④⑤⑥)는 **앞뒤가 같아야** 정상입니다 — 이 배포는 그 자료를 안 건드립니다."
  say "   🔵 ③ 의 $PERM_OLD_KEY 줄만은 --migrate 뒤에도 **그대로 남습니다**(안 지웁니다)."
}

# ══ 🔴 53번 꼬리말에서 넘어온 후속 작업 둘을 **값으로** 센다 ═════════
#   🔴 **판정하지 않는다.** 수를 찍고 사람이 가른다.
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
  fi
  pend=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from domestic_orders where repair_case_id is null and completed_at is null and is_deleted = false")
  say "🔵 지금 열려 있는 기타건(수리건 안 붙고 아직 완료 아님): ${pend:-못 쟀다}건"
  say "   🔴 결재선이 0개이면 **그 ${pend:-?}건이 전부 [완료] 처리에서 막힙니다.**"
}

# ══════════════════════════════════════════════════════════════════════
# ── --count : 도구를 읽기만 해서 센다 + 이 배포가 바꾸는 자리 ─────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **'--silent' 를 안 붙인다.** 붙이면 npm 의 로그 수위가 내려가 'Missing
#      script' 가 **안 찍힐 수 있다.**
count_one() { # 1 npm 명령 2 사람이 부르는 이름
  local out rc
  printf '\n  ── %s  (npm run %s)\n' "$2" "$1"
  out=$(dct run --rm -T "$AS_TOOLS_SVC" npm run "$1" 2>&1)
  rc=$?
  out=$(printf '%s' "$out" | tr -d '\r')
  if printf '%s' "$out" | grep -qE 'Missing script|missing script'; then
    bad "🔴 $2 — **그 도구 이미지에 이 명령이 없다**(Missing script)"
    say "🔵 다섯은 :18 에도 :19 에도 있어야 한다 — 48·52~55번이 올려 두었고 이번 판에 안 줄었다."
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
  CTL=$(img_line "$AS_TOOLS_SVC")
  if [ -n "${CTL:-}" ]; then
    printf '%s\n' "🔵 지금 compose 의 $AS_TOOLS_SVC 태그: $(tag_at "$CTL")  (${CTL}줄)"
  else
    printf '%s\n' "🔴 compose 에서 $AS_TOOLS_SVC 의 image: 줄을 못 찾았다 — 아래 수가 어느 판인지 모른다"
  fi
  printf '%s\n' "🔴 **아래 다섯은 이번 배포와 상관이 없습니다.** 앞뒤가 같으면 정상이고,"
  printf '%s\n' "   다르면 **그 사이에 사람이 저장한 것**입니다."
  printf '%s\n' "   🔴 **이 배포를 재는 숫자는 맨 아래 절**(effect_counts)에 있습니다."
  printf '%s\n' "   🔴 그 절은 **59번 것과 재는 것이 완전히 다릅니다** — 59번은 종 줄 수를,"
  printf '%s\n' "      이번 판은 **권한 행과 새 거르개**를 셉니다."
  count_one check:target-shipment-missing "사내 목표 출하일 미등록"
  count_one check:due-date-inverted       "납기 역전"
  count_one check:requested-due-date-sync "납기요청일 ↔ 고객 요청 납기일 어긋남"
  count_one check:due-date-overdue        "[납기 지연]"
  count_one check:delivered-date-sync     "납품일 ↔ 실제 출하일"
  effect_counts
  followup_counts
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  printf '%s\n' "🔴 **①(옮길 행 수)과 ⑤(거르개가 보여 줄 건 수)를 적어 두세요** — 배포 뒤 맞댈 두 수입니다."
  printf '%s\n' "   🔵 ① 이 0 이면 운영이 전부 코드 기본값으로 돈다는 뜻이고, 그것이 실측값이었습니다."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi
# ── 1. 지금 상태 ──────────────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
[ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
say "compose 줄 수 $(wc -l < "$CF") · image: 줄 $(grep -c '^ *image:' "$CF")개"

# ── 🔴 1-ㄱ-0. **덤프 이름과 compose 사본 이름의 판 꼬리표가 같은가** ──
#   🔴 **59번이 남긴 숙제가 여기다.** 그 파일은 compose 사본을 …yml.v55-… 로 뜨면서
#      덤프만 dss_as-v54-… 로 만들었다(make_dump() 안의 DUMP 변수를 안 고쳤다).
#      그러면 **어느 배포의 사진인지 이름으로 못 가린다.**
#   🔴 그래서 이 판은 둘을 **한 곳에서 읽고, 같은지 값으로 확인한다.**
printf '\n    ── 🔴 덤프 이름과 compose 사본 이름의 판 꼬리표 (59번이 여기서 어긋났다)\n'
BK_VER=$(printf '%s' "${BK##*/}" | sed -n 's/.*\.\(v[0-9][0-9]*\)-.*/\1/p')
say "compose 사본: ${BK##*/}   → 꼬리표 ${BK_VER:-못 읽음}"
say "DB 덤프     : dss_as-$DUMP_VER-<시각>.dump   → 꼬리표 $DUMP_VER"
if [ "${BK_VER:-}" = "$DUMP_VER" ]; then
  ok "둘의 판 꼬리표가 **같다** ($DUMP_VER) — 어느 배포의 사진인지 이름으로 가릴 수 있다"
  say "🔵 59번은 사본이 v55 · 덤프가 **v54** 로 어긋나 있었습니다(README 의 쉰다섯째 절)."
else
  bad "🔴 사본은 ${BK_VER:-못 읽음} · 덤프는 $DUMP_VER 로 **어긋난다** — 59번과 같은 실수다"
  say "🔴 BK 와 DUMP_VER 를 같은 v 번호로 맞추세요. **두 벌로 적힌 값**이라 한쪽만 고치면 이렇게 됩니다."
  doubt
fi

# ── ㄱ) 🔴 **운영이 지금 쓰는 태그 전부** — 저장소 사본을 믿지 않는다 ──
#   이 저장소의 compose 사본은 운영보다 뒤처진다(48번에 **세 줄**이 어긋나 있었다).
printf '\n    ── 운영 compose 의 image: 줄 전부 (이 파일이 진짜다)\n'
grep -n '^ *image:' "$CF" | sed 's/^/      /'
printf '\n    ── 지금 **도는** 컨테이너와 그 이미지 (compose 와 다를 수 있다)\n'
"$DOCKER" ps -a --format '{{.Names}} {{.Image}} {{.Status}}' 2>/dev/null | sort | sed 's/^/      /'

# ══════════════════════════════════════════════════════════════════════
# 🔴 1-ㄱ-2. **상태 변수를 먼저 정한다** — 그다음에 가지를 나눈다
# ══════════════════════════════════════════════════════════════════════
AS_NEW_TAG=$(printf '%s\n' "$(rows)" | grep '^as|' | head -1 | cut -d'|' -f4)
AS_OLD_TAG=$(printf '%s\n' "$(rows)" | grep '^as|' | head -1 | cut -d'|' -f5)
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
  PRE)  ok "PHASE=PRE — 아직 아무것도 안 갈아 끼웠다 (--preload → **--migrate** → --go 차례)"
        say "🔴 **--migrate 단계가 있다** — 그것이 도구 줄을 먼저 고치고 DB 를 올린다." ;;
  MID)  ok "PHASE=MID — 도구만 새 판이다"
        say "🔴 **이 판에서 MID 는 1순위로 「--migrate 까지 돌았다」는 뜻이다**(55번과 같다)."
        say "   🔵 59번에는 --migrate 가 없어 「--go 뒤에 --rollback 했다」로만 읽었다."
        say "🔴 **둘을 DB 기록으로 가른다** — 2절의 기록이 $AS_MIG_AFTER 면 --migrate 를 돌았고,"
        say "   $AS_MIG_BEFORE 면 아직이다(그때는 --migrate 부터 돌리세요)." ;;
  POST) ok "PHASE=POST — 둘 다 새 판이다. --go 까지 돌았다" ;;
  *)    hm "PHASE=ODD — 둘이 섞여 있다. **어느 단계가 도중에 멈췄거나 운영이 따로 움직였다.** 위 표를 보세요"
        say "🔴 59번(쉰다섯째)이 올린 판($AS_OLD_TAG · $AS_TOOLS_OLD)을 옛 값으로 적었다."
        say "   그래도 어긋났다면 운영이 그 사이 따로 움직였다는 뜻이다. **고치지 말고 알리세요.**" ;;
esac
# 🔴 **모드마다 서 있어야 하는 PHASE 가 다르다.** 여기서 한 번만 가른다.
case "$MODE" in
  rollback)
    case "$PHASE" in
      POST) ok "되돌릴 준비가 됐다 (PHASE=POST)" ;;
      MID)  hm "앱이 이미 옛 판이다 (PHASE=MID — 벌써 되돌렸나, 또는 --migrate 까지만 돌았나)" ;;
      *)    hm "PHASE=$PHASE 에서 되돌리기를 부르셨다 — 🔵 막지는 않는다. 위 표를 보세요" ;;
    esac ;;
  migrate)
    case "$PHASE" in
      PRE)  ok "DB 를 올릴 준비가 됐다 (PHASE=PRE — 도구 줄 **하나**가 달라질 것이다)" ;;
      MID)  hm "이미 MID 다 — 🔵 **다시 돌려도 안전하다**(drizzle 이 건너뛰고 0127 도 ON CONFLICT 다)" ;;
      POST) hm "이미 POST 다 — 앱까지 올라가 있다. 🔵 막지 않는다(다시 돌려도 안전하다)" ;;
      *)    hm "PHASE=$PHASE 다 — 위 표를 보고 사람이 판단하세요" ;;
    esac ;;
  go)
    case "$PHASE" in
      PRE)  ok "갈아 끼울 준비가 됐다 (PHASE=PRE — image: 줄 **둘**이 달라질 것이다)"
            say "🔴 **--migrate 를 건너뛰셨나요?** 아래 5절이 DB 기록을 보고 $AS_MIG_AFTER 가 아니면 멈춥니다." ;;
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

# 🔴 **compose 의 태그와 실제로 도는 이미지가 같은가**
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
    say "🔵 **교체를 막지 않는다** — --go 가 어차피 다시 띄운다."
  fi
done
[ "$SITES_SEEN" = "$SITES_WANT" ] && ok "다시 띄울 앱 ${SITES_WANT}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "🔴 앱을 ${SITES_SEEN}개만 봤다 — ${SITES_WANT}개를 기대했다. SITES 표가 깨졌다"

# ══ 🔴 안 건드리는 앱 둘 — **그래도 「그대로인가」는 본다** ════════════
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
  # 🔴 볼륨이 제 자리에 붙는가 — 🔴 **이번 판에서 특히 중요하다.**
  #    여기가 어긋나면 **묶음을 풀어도 db:migrate 가 엉뚱한 폴더를 읽는다.**
  if svc_block "$AS_TOOLS_SVC" | grep -q "$MIGDIR:$IMG_MIGDIR"; then
    ok "$AS_TOOLS_SVC 가 $MIGDIR 를 $IMG_MIGDIR 로 붙인다 (🔴 --migrate 가 그 폴더로 돈다)"
  else
    bad "🔴 $AS_TOOLS_SVC 의 drizzle 볼륨이 $MIGDIR 가 아니다 — **묶음을 풀어도 엉뚱한 폴더를 읽는다**"
    doubt
  fi
  for kv in "$KYO_SRC" "$KYO_CONV"; do
    if svc_block "$AS_TOOLS_SVC" | grep -q "$kv"; then
      ok "$AS_TOOLS_SVC 에 $kv 볼륨 줄이 있다 (연락서를 이식할 때 읽을 자리)"
    else
      hm "$AS_TOOLS_SVC 에 $kv 볼륨 줄이 **없다** — 🔵 교체는 막지 않는다"
    fi
  done
else
  bad "compose 에 $AS_TOOLS_SVC 가 없다 — 올릴 자리가 없다"
fi
printf '\n    ── %s (이번에 **안 건드린다**)\n' "$AUTH_TOOLS_SVC"
AUTH_TOOLS_L=$(img_line "$AUTH_TOOLS_SVC" 2>/dev/null || true)
if [ -n "${AUTH_TOOLS_L:-}" ]; then
  ATCUR=$(tag_at "$AUTH_TOOLS_L")
  say "$AUTH_TOOLS_SVC — ${AUTH_TOOLS_L}줄 · compose ${ATCUR}"
  if [ "$ATCUR" = "$AUTH_TOOLS_KEEP" ]; then
    ok "$AUTH_TOOLS_SVC 가 $AUTH_TOOLS_KEEP 다 (53번이 올린 그 판)"
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
if img_line tools-po >/dev/null 2>&1; then
  hm "compose 에 tools-po 가 **생겼다** — 이 배포의 범위 밖이니 사람이 보세요"
else
  ok "compose 에 tools-po 가 없다 (없는 것이 맞다)"
fi

# ── 1-ㄴ. 🔴 설정 파일 — 중복 키와 auto (값은 안 찍는다) ──────────────
printf '\n    ── 설정 파일 (이름만 본다. 값도, 값의 길이도 안 찍는다)\n'
env_file_check() { # 1 파일 2 사람이 부르는 이름
  local f n dup
  f=$1
  if [ ! -f "$f" ]; then hm "$2 — 파일이 없다: $f (못 쟀다)"; return; fi
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
  fi
}
env_auto_check() { # 1 파일 2 이름 3 환경변수 이름
  local f v q
  f=$1
  if [ ! -f "$f" ]; then hm "$2 의 $3 — 파일이 없어 못 쟀다"; return; fi
  v=$(grep -E "^$3=" "$f" 2>/dev/null | tail -1 | cut -d= -f2-)
  v=$(printf '%s' "$v" | tr -d '\r')
  q=$(printf '%s' "'")
  v=${v#\"}; v=${v%\"}
  v=${v#"$q"}; v=${v%"$q"}
  v=${v# }; v=${v% }
  if [ -z "${v:-}" ]; then bad "$2 에 $3 가 없거나 비었다 — 앱이 뜨면서 던진다"; return; fi
  case "$v" in
    auto|auto:*)
      bad "🔴 $2 의 $3 가 **auto** 다 — 컨테이너 안에서 172.x 로 풀려 **로그인이 돌아오지 못한다.**"
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
say "🔵 **이 판은 설정 파일을 하나도 안 바꾼다** — 이번 범위에 늘어난 process.env 이름이 0개다."

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

# ── 2. 🔴 DB — **이번 판은 앞뒤가 다른 수다** (127 → 128) ────────────
#   🔴 **59번의 「어느 단계에서나 127 한 갈래」를 그대로 베끼면 안 된다** —
#      적용 뒤에 **가짜 ✗** 가 난다(48번이 데인 그 자리다).
printf '\n== 2. DB (dss_as · A/S 와 PO 가 함께 쓴다)\n'
say "🔵 이 판은 마이그레이션 **$AS_NEW_MIGS_WANT 건**이다 — 기대값이 **두 갈래**다($AS_MIG_BEFORE 또는 $AS_MIG_AFTER)."
MIG_AS0=$(mig_count "$AS_BOX" "$AS_DB")
say "기록 ${MIG_AS0:-?} (기대 $AS_MIG_BEFORE = 적용 전 · $AS_MIG_AFTER = 적용 뒤)"
MIG_DONE=no
if [ -z "${MIG_AS0:-}" ]; then
  bad "DB 를 못 쟀다 — $AS_BOX 가 도는지 보세요"
  doubt
elif [ "$MIG_AS0" = "$AS_MIG_AFTER" ]; then
  MIG_DONE=yes
  ok "$AS_MIG_AFTER 다 — **--migrate 가 이미 돌았다**(0127 이 올라가 있다)"
elif [ "$MIG_AS0" = "$AS_MIG_BEFORE" ]; then
  ok "$AS_MIG_BEFORE 다 — 55번이 올려 둔 그대로다 (**--migrate 가 아직이다**)"
  say "🔴 **--go 전에 --migrate 를 돌리세요** — 5절이 $AS_MIG_AFTER 가 아니면 멈춥니다."
else
  bad "🔴 기록이 ${MIG_AS0} 이다 — $AS_MIG_BEFORE 나 $AS_MIG_AFTER 를 기대했다"
  say "🔴 125 면 **55번(쉰두째) 배포의 --migrate 가 안 돌았거나 되돌아간 것**이다."
  doubt
fi
# 🔴 포털 DB 는 **그대로여야** 한다.
MIG_AU0=$(mig_count "$AUTH_BOX" "$AUTH_DB")
say "포털 기록 ${MIG_AU0:-?} (기대 $AUTH_MIG_KEEP 그대로)"
if [ -z "${MIG_AU0:-}" ]; then
  bad "포털 DB 를 못 쟀다 — $AUTH_BOX 가 도는지 보세요"; doubt
elif [ "$MIG_AU0" = "$AUTH_MIG_KEEP" ]; then
  ok "포털이 $AUTH_MIG_KEEP 이다 — **이 배포는 포털 DB 를 안 건드린다**"
else
  bad "🔴 포털이 ${MIG_AU0} 이다 ($AUTH_MIG_KEEP 이어야 한다) — 이 배포는 포털 마이그레이션을 **돌릴 길이 없다**"
  doubt
fi

# ── 2-ㄴ. 🔴 **0124~0126 이 만든 열** — 어느 단계에서나 **다 있어야** 한다 ──
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
  doubt
fi
# ── 2-ㄷ. 🔴 **55번(0125·0126)이 만든 열 아홉** ─────────────────────
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
  bad "🔴 아홉 중 ${NEW_OK}개만 있다 — **기록은 맞는데 실물이 모자란다.** 멈추고 알리세요"
  doubt
fi
IXC=$(index_cols "$AS_BOX" "$AS_DB" "$NEW_IDX")
say "$NEW_IDX 의 키 칸 수: ${IXC:-못 쟀다} (기대 $NEW_IDX_COLS_WANT — 🔵 0127 은 인덱스를 안 건드린다)"
if [ -z "${MIG_AS0:-}" ]; then
  hm "DB 를 못 쟀으니 인덱스 칸 수를 판정하지 않는다"
elif [ "${IXC:-x}" = "$NEW_IDX_COLS_WANT" ]; then
  ok "유니크 인덱스가 칸 ${NEW_IDX_COLS_WANT}개다 (0126 이 회차 칸을 넣어 다시 만든 그 판이다)"
elif [ "${IXC:-x}" = "2" ]; then
  bad "🔴 유니크 인덱스의 칸이 2개다 — **0126 이 안 돌았거나 되돌아갔다**"
  say "🔴 **이름만 보면 못 가르는 자리다** — 0124 것과 이름이 같다. 칸 수가 증거다."
  doubt
else
  bad "🔴 유니크 인덱스의 칸이 ${IXC:-못 쟀다}개다 — $NEW_IDX_COLS_WANT 를 기대했다"
  doubt
fi
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
if [ "$OBJ_OK" = "3" ]; then ok "48번이 올린 셋이 다 있다"
elif [ -z "${MIG_AS0:-}" ]; then hm "셋 중 ${OBJ_OK}개만 찾았다 — 위에서 DB 를 아예 못 쟀으니 **못 쟀다**로 센다"
else bad "🔴 셋 중 ${OBJ_OK}개만 있다 — **실물이 모자란다.** 멈추고 알리세요"; doubt; fi

# ══════════════════════════════════════════════════════════════════════
# ── 2-ㄹ. 🔴 **마이그레이션 볼륨** — 올릴 것이 하나인가 ───────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **마이그레이션은 이미지 안이 아니라 볼륨에서 돈다.** 이미지 안만 세면
#      0건으로 조용히 끝난다(39·48·53번이 겪었다). 그래서 **볼륨**을 센다.
printf '\n== 2-ㄹ. 🔴 마이그레이션 볼륨 — **올릴 것이 %s건인가**\n' "$AS_NEW_MIGS_WANT"
printf '%s\n' "🔴 이 판은 **묶음을 보낸다.** 운영 볼륨이 아직 $AS_MIG_BEFORE 이고 0127 이 묶음 안에만 있다."
printf '%s\n' "🔴 .sql 만으로는 모자라다 — **meta/_journal.json 까지** 본다."
printf '%s\n' "   목록에 없는 .sql 은 drizzle 이 아예 모르고, 적용이 **0건으로 조용히 끝난다.**"
read_migdir
say "$MIGDIR — .sql ${MIG_N_SQL}장 · meta/_journal.json 의 idx ${MIG_N_J}개 (기대 $AS_MIG_BEFORE = 아직 · $AS_MIG_AFTER = 풀었다)"
case "$MIG_STATE" in
  DONE)  ok "볼륨이 $AS_MIG_AFTER 다 (**묶음을 이미 풀었다**)" ;;
  OLD)   ok "볼륨이 $AS_MIG_BEFORE 다 (**아직 안 풀었다** — --migrate 가 푼다)"
         say "🔴 **묶음이 $MIGTAR 에 있어야 한다.** 없으면 --migrate 가 멈춘다." ;;
  NODIR) bad "🔴 $MIGDIR 폴더가 **없다** — compose 가 $AS_TOOLS_SVC 에 붙이는 그 폴더다"
         doubt ;;
  *)     bad "🔴 볼륨이 .sql ${MIG_N_SQL} · idx ${MIG_N_J} 다 — $AS_MIG_BEFORE 나 $AS_MIG_AFTER 를 기대했다"
         say "🔴 **고치지 말고 먼저 알리세요.**"; doubt ;;
esac
# 🔵 두 상수가 이어지는 번호인가 — 🔴 10# 으로 **10진수를 강제**한다(8진수 함정).
if [ "$(printf '%04d' "$((10#$AS_LAST_MIG + 1))")" = "$AS_NEXT_MIG" ]; then
  ok "번호 둘이 이어진다 ($AS_LAST_MIG → $AS_NEXT_MIG)"
else
  bad "🔴 $AS_LAST_MIG · $AS_NEXT_MIG 가 안 이어진다 — 한쪽만 고쳤다"
fi
# 🔴 **묶음이 와 있는가** — --migrate 가 그것으로 돈다.
printf '\n    ── 🔴 묶음(as-migrations.tar.gz)이 와 있는가\n'
if [ -s "$MIGTAR" ]; then
  MSZ=$(stat -c %s "$MIGTAR" 2>/dev/null)
  MM5=$(md5sum "$MIGTAR" 2>/dev/null | awk '{print $1}')
  say "$MIGTAR — ${MSZ:-?}바이트 · md5 ${MM5:-?}"
  if [ -n "${MIGTAR_MD5:-}" ] && [ -n "${MIGTAR_SIZE:-}" ]; then
    [ "${MSZ:-x}" = "$MIGTAR_SIZE" ] && ok "묶음 크기가 만들 때와 같다  [배포본]" \
      || { bad "🔴 묶음 크기가 다르다 (${MSZ:-?} != ${MIGTAR_SIZE}) — **옛 묶음이거나 옮기다 깨졌다**"; doubt; }
    [ "${MM5:-x}" = "$MIGTAR_MD5" ] && ok "묶음 md5 가 만들 때와 같다  [배포본]" \
      || { bad "🔴 묶음 md5 가 다르다 — **옛 묶음이거나 옮기다 깨졌다**"; doubt; }
    say "🔴 **_images-52 의 옛 묶음(127장)을 보내지 마세요** — 0127 이 없습니다."
  else
    if [ "$MODE" = migrate ]; then
      bad "🔴 묶음의 잰 값이 이 파일에 없다 — **60-build.sh --go 의 MIGTAR_SIZE·MIGTAR_MD5 를 채우세요**"
      say "🔴 안 채우면 「개발 PC 에서 만든 그 묶음이 맞나」를 **아예 못 본다.**"
    else
      hm "묶음의 잰 값이 이 파일에 없다 — **${MODE} 에서는 괜찮다.** --migrate 전에 채우세요"
    fi
  fi
  # 🔴 **안을 센다** — 「파일이 왔다」와 「쓸 만한 묶음이다」는 다르다.
  #    🔴 tar 를 grep -q 에 물리지 않는다 — **세어서 담고 비교하는 꼴**이다.
  TSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE '^drizzle/[0-9]{4}_.*[.]sql$' || true)
  T127=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${AS_LAST_MIG}_.*[.]sql" || true)
  TNEXT=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${AS_NEXT_MIG}_.*[.]sql" || true)
  say "묶음 안 — .sql ${TSQL:-?}장 (기대 $AS_MIG_AFTER) · $AS_LAST_MIG ${T127:-?}개 (기대 1) · $AS_NEXT_MIG ${TNEXT:-?}개 (기대 0)"
  if [ "${TSQL:-x}" = "$AS_MIG_AFTER" ] && [ "${T127:-0}" = "1" ] && [ "${TNEXT:-1}" = "0" ]; then
    ok "묶음 안이 $AS_MIG_AFTER 장이고 $AS_LAST_MIG 이 들어 있다 (**이것이 없으면 적용이 0건으로 끝난다**)"
  else
    if [ "$MODE" = migrate ] || [ "$MODE" = go ]; then
      bad "🔴 묶음 안이 기대와 다르다 — .sql ${TSQL:-?} · $AS_LAST_MIG ${T127:-?} · $AS_NEXT_MIG ${TNEXT:-?}"
      say "🔴 **_images-52 의 옛 묶음(127장)을 보내셨나요?** 거기에는 0127 이 없습니다."
      doubt
    else
      hm "묶음 안이 기대와 다르다 (.sql ${TSQL:-?} · $AS_LAST_MIG ${T127:-?}) — **${MODE} 에서는 막지 않는다**"
    fi
  fi
else
  if [ "$MIG_STATE" = DONE ]; then
    say "🔵 묶음이 없지만 볼륨이 이미 $AS_MIG_AFTER 다 — **이미 풀어 둔 것이다.**"
    ok "볼륨이 이미 $AS_MIG_AFTER 라 묶음이 없어도 된다"
  elif [ "$MODE" = check ] || [ "$MODE" = rollback ] || [ "$MODE" = count ]; then
    hm "묶음이 아직 없다: $MIGTAR — **${MODE} 에서는 괜찮다**"
    cmd "scp -O as-migrations.tar.gz dss-nas:$INCOMING/"
  else
    bad "🔴 묶음이 없고 볼륨도 $AS_MIG_AFTER 가 아니다 — **0127 을 올릴 길이 없다**"
    cmd "scp -O as-migrations.tar.gz dss-nas:$INCOMING/"
    doubt
  fi
fi
# 🔴 **적용 대기 = 볼륨 − 기록.** 순수한 셈이라 한글 grep 에 안 걸린다.
if [ -z "${MIG_AS0:-}" ] || [ "$MIG_STATE" = NODIR ]; then
  hm "적용 대기를 **못 쟀다** (볼륨 ${MIG_N_SQL} · 기록 ${MIG_AS0:-?}) — 사람이 보세요"
else
  PEND=$((MIG_N_SQL - MIG_AS0))
  say "볼륨 ${MIG_N_SQL} - 기록 ${MIG_AS0} = 적용 대기 ${PEND}건"
  if [ "$MIG_STATE" = OLD ] && [ "$PEND" = "0" ]; then
    ok "적용 대기가 0건이다 — 🔵 **아직 묶음을 안 풀었다**(볼륨도 기록도 $AS_MIG_BEFORE). --migrate 가 푼다"
  elif [ "$MIG_STATE" = DONE ] && [ "$PEND" = "$AS_NEW_MIGS_WANT" ]; then
    ok "적용 대기가 **${AS_NEW_MIGS_WANT}건**이다 — 🔵 묶음은 풀었고 **아직 안 돌렸다.** --migrate 가 돌린다"
  elif [ "$MIG_STATE" = DONE ] && [ "$PEND" = "0" ]; then
    ok "적용 대기가 0건이다 — 🔵 **--migrate 까지 끝났다**(볼륨도 기록도 $AS_MIG_AFTER)"
  else
    bad "🔴 볼륨 ${MIG_N_SQL} · 기록 ${MIG_AS0} · 대기 ${PEND}건 — 셋이 아는 꼴이 아니다"
    say "🔴 아는 꼴: ($AS_MIG_BEFORE·$AS_MIG_BEFORE·0) · ($AS_MIG_AFTER·$AS_MIG_BEFORE·1) · ($AS_MIG_AFTER·$AS_MIG_AFTER·0)"
    doubt
  fi
fi
# 🔴 **도구에게 직접 물어본다** — 셈과 다른 길이다. db:preflight 는 읽기만 한다.
printf '\n    ── 🔴 db:preflight 로 다시 묻는다 (읽기만 한다 · 두 길이 같은 답을 내야 한다)\n'
if [ -n "${AS_TOOLS_L:-}" ]; then
  dct run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | tail -25 | sed 's/^/    /'
  PRC=${PIPESTATUS[0]}
  say "(종료 코드 ${PRC:-?} — 기대 0)"
  if [ "${PRC:-1}" = "0" ]; then
    ok "db:preflight 가 종료 코드 0 이다 (**사라지는 자료가 없다**)"
    say "🔵 개발에서는 이렇게 나왔습니다(2026-11-12):"
    say "   전체 마이그레이션 $AS_MIG_AFTER 건 · 적용 대기 $AS_NEW_MIGS_WANT 건"
    say "   [${AS_LAST_MIG}_domestic_order_permission_leaves] 더하기만 합니다 — 사라지는 자료 없음"
    say "🔴 **「사라질 자료」가 보이면** 이 배포의 전제가 깨진 것입니다 — **멈추고 알리세요.**"
  else
    bad "🔴 db:preflight 가 ${PRC:-?} 다 — 0 을 기대했다. **사라질 자료가 있다는 뜻이다**"
    say "🔴 0127 은 **더하기만 한다**(INSERT 넷). 0 이 아니면 **전제가 깨진 것**이다."
    doubt
  fi
else
  hm "compose 에 $AS_TOOLS_SVC 가 없어 db:preflight 를 못 불렀다"
fi

# ── 2-ㅁ. 🔴 **마이그레이션이 옮길 행을 지금 센다** ──────────────────
#   🔴 **운영 실측은 0건이었다**(2026-11-12). 🔴 **그래도 매번 다시 센다** —
#      그 사이에 누가 권한 화면에서 저장하면 행이 생긴다.
printf '\n    ── 🔴 %s 이 **옮길 행**을 지금 센다 (0건이어도 정상 · 그래도 매번 잰다)\n' "$AS_LAST_MIG"
PERM_SUM=0; PERM_SEEN=0
for lf in $PERM_LEAVES; do
  n=$(perm_pending_for "$lf")
  printf '      %s.%-10s %s줄\n' "$PERM_OLD_KEY" "$lf" "${n:-못 쟀다}"
  if isnum "${n:-}"; then PERM_SUM=$((PERM_SUM + n)); PERM_SEEN=$((PERM_SEEN + 1)); fi
done
PERM_OLD_N=$(perm_rows_of "$PERM_OLD_KEY")
say "옛 $PERM_OLD_KEY 행 ${PERM_OLD_N:-못 쟀다}줄 · --migrate 가 넣을 행 합계 ${PERM_SUM}줄"
if [ "$PERM_SEEN" != "$PERM_LEAVES_WANT" ]; then
  hm "잎 ${PERM_SEEN}개만 쟀다 — ${PERM_LEAVES_WANT}개를 기대했다. **빈 결과는 삼켜진 오류일 수 있다**"
  doubt
elif [ "$PERM_SUM" -ge 1 ]; then
  ok "--migrate 가 넣을 행이 **${PERM_SUM}줄**이다 (그 사이에 누가 저장했다 — 2026-11-12 실측은 0이었다)"
  say "🔴 **--migrate 뒤에 이 수가 0 이 되어야** 정상입니다."
else
  hm "옮길 행이 **0줄이다** — 🔵 **정상입니다.** 운영이 전부 코드 기본값으로 돕니다"
  say "   (2026-11-12 실측: area_key in ('domesticOrders','miscCases','quotes') → 0 rows)."
  say "🔴 **--migrate 를 건너뛰지 마세요** — 기록이 $AS_MIG_AFTER 가 되어야 --go 가 섭니다."
  say "🔵 판은 0건이어도 조용히 통과합니다(INSERT ... SELECT 라 원본이 0행이면 0행을 넣습니다)."
fi

# ── 3. 들여올 이미지 둘 ───────────────────────────────────────────────
printf '\n== 3. 들여올 이미지 둘 (앱 하나 · 도구 하나)\n'
printf '%s\n' "🔴 **셋째 산출물(묶음)은 위 2-ㄹ 절이 따로 본다** — 자리가 다르다(images/ 가 아니라 setup/incoming/)."
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
    if [ "$MODE" = check ] || [ "$MODE" = rollback ]; then
      hm "$TAR — **잰 값이 이 파일에 없다.** 옮기다 깨진 것만 잡는다"
    else
      bad "🔴 $TAR — **잰 값이 이 파일에 없다.** 60-build.sh --go 가 찍어 준 두 줄로 TARS 를 채우세요"
      say "🔴 안 채우면 「개발 PC 에서 구운 그것이 맞나」를 **아예 못 본다.**"
    fi
    continue
  fi
  [ "$SZ"  = "$WSZ"  ] && ok "$TAR 크기가 구울 때와 같다  [배포본]" || { bad "$TAR 크기가 다르다 (${SZ} != ${WSZ}) — 옮기다 깨졌다"; doubt; }
  [ "$M5"  = "$WM5"  ] && ok "$TAR md5 가 같다  [배포본]"           || { bad "$TAR md5 가 다르다 — 옮기다 깨졌다"; doubt; }
  [ "$CFG" = "$WCFG" ] && ok "$TAR 지문이 같다  [배포본]"           || { bad "$TAR 지문이 다르다 (${CFG:-못 읽음}) — **다른 판을 올렸다**"; doubt; }
done
if [ "$TSEEN" = "$TARS_WANT" ]; then ok "TARS 표의 ${TARS_WANT}줄을 다 봤다 (표가 비지 않았다)"
else bad "🔴 TARS 표에서 ${TSEEN}줄만 봤다 — ${TARS_WANT}줄을 기대했다. 표가 깨졌다"; fi
if [ "$BLANK" != "0" ]; then
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 60-build.sh --go 가 끝에 찍어 주는"
  printf '%s\n' "     **두 줄**로 이 파일의 TARS 두 줄을 통째로 갈아 끼우세요."
  printf '%s\n' "     🔴 그리고 **MIGTAR_SIZE · MIGTAR_MD5** 도 함께 채우세요(묶음 값입니다)."
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

# 🔴 **재고 관리 통로 — --check 에서 미리 재 둔다.** ? 로만 센다.
if [ "$MODE" = check ]; then inventory_gateway_check soft; fi
# 🔴 **이 배포가 바꾸는 자리 — --check 에서도 미리 센다.**
if [ "$MODE" = check ]; then effect_counts; fi
if [ "$MODE" = check ]; then followup_counts; fi

if [ "$MODE" = check ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s   (PHASE=%s · DB 기록 %s)\n' "$PASS" "$FAIL" "$WARN" "$PHASE" "${MIG_AS0:-?}"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  printf '%s\n' "🔴 다음 차례: --count(앞) → scp tar **둘** + **묶음 하나** → --preload → (다시 --check)"
  printf '%s\n' "   → **--migrate** → --go → --count(뒤)"
  printf '%s\n' "🔴 **PHASE=PRE 에서 돌리면 ? 가 여럿 나오는 것이 정상**이다 (tar 둘과 묶음이 아직 없다)."
  printf '%s\n' "🔴 **--migrate 를 건너뛰지 마세요** — 5절이 DB 기록이 $AS_MIG_AFTER 가 아니면 멈춥니다."
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
  printf '%s\n' "🔵 **들여놓기만 했다 — 아직 안 갈아 끼웠다.** 다음: --check 를 다시 → **--migrate** → --go"
  printf '%s\n' "🔴 **이 배포는 마이그레이션이 $AS_NEW_MIGS_WANT 건입니다.** --migrate 가 덤프를 뜨고 →"
  printf '%s\n' "   $AS_TOOLS_SVC 태그를 $AS_TOOLS_NEW 로 바꾸고 → **묶음을 풀고** → db:migrate 로"
  printf '%s\n' "   **DB 를 $AS_MIG_BEFORE 에서 $AS_MIG_AFTER 로** 올립니다."
  printf '%s\n' "   🔵 **옮기는 행이 0건일 수 있습니다** — 그래도 기록은 $AS_MIG_AFTER 가 되어야 합니다."
  printf '%s\n' "🔴 **건너뛰고 --go 로 가지 마세요.** --go 는 기록이 $AS_MIG_AFTER 가 아니면 멈춥니다 —"
  printf '%s\n' "   새 앱이 권한 잎 넷을 읽습니다."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ══════════════════════════════════════════════════════════════════════
# ── 4-ㄴ. --migrate : 🔴 **DB 를 바꾼다** (127 → 128) ────────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **59번과 가장 크게 다른 절이다.** 59번은 0건이라 이 모드를 **없앴고**,
#      치면 까닭을 찍고 거절하게 해 두었다. 이번 판은 **묶음을 풀고 진짜로 적용한다.**
#   🔵 되살린 본보기는 **55-deploy.sh** 의 같은 절이다.
#   🔴 **종료 코드만 보고 「성공」이라 말하지 않는다** — 적용 뒤 DB 를 다시 읽어
#      기록이 128 인지 · 잎 넷이 생겼는지 **값으로** 센다.
#   🔵 **다시 돌려도 안전하다** — drizzle 은 이미 적용한 것을 건너뛰고,
#      0127 자신도 ON CONFLICT DO NOTHING 이다.
if [ "$MODE" = migrate ]; then
  printf '\n== 4-ㄴ. 🔴 마이그레이션 — 이 판은 **%s건**이다 (기록 %s → %s)\n' "$AS_NEW_MIGS_WANT" "$AS_MIG_BEFORE" "$AS_MIG_AFTER"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **DB 를 안 건드리고 멈춘다.**\n'; exit 1; fi

  # ── ㄱ. 🔴 덤프 — **이번 판에는 진짜 되돌릴 길이다** ───────────────
  make_dump "🔴 이번 판은 DB 의 자료를 바꾼다 — 바꾸기 직전의 사진이다"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 되돌릴 길이 없다 — **DB 도 앱도 그대로 두고 멈춘다.**\n'; exit 1; fi

  # ── ㄴ. 🔴 적용 전 줄 수를 적어 둔다 ────────────────────────────────
  #    🔴 **role_permissions 는 이 목록에 없다** — 이번 판이 **그 표에 행을 더한다.**
  #       넣으면 --migrate 가 제 일을 하고도 ✗ 를 받는다. 그 표는 따로 센다.
  printf '\n    ── 적용 전 줄 수 (뒤에 **그대로여야** 한다 · role_permissions 는 따로 센다)\n'
  CNT_BEFORE=""
  for F in $AS_COUNT_TABLES; do
    V=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $F")
    CNT_BEFORE="$CNT_BEFORE as.$F=${V:-?}"; say "dss_as.$F ${V:-?}줄"
  done
  PERM_BEFORE=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $PERM_TABLE")
  say "🔴 dss_as.$PERM_TABLE ${PERM_BEFORE:-?}줄 — **이 표만 늘어난다**(기대 +${PERM_SUM})"

  # ── ㄷ. 🔴 compose 의 **도구 한 줄**을 새 태그로 ───────────────────
  #   🔴 사본을 먼저 뜨고, image: 줄이 **꼭 세어 둔 수만큼** 달라졌는지 세고,
  #      어긋나면 **사본으로 되돌리고 멈춘다.**
  #   🔵 profiles: [tools] 라 평소에 뜨지 않는다. up -d 를 안 부른다.
  #   🔴 **앱 줄은 하나도 안 바뀌어야 한다** — 그것은 --go 의 일이다.
  printf '\n    ── compose 의 도구 한 줄을 새 태그로 (%s)\n' "$AS_TOOLS_NEW"
  cp "$CF" "$BK" || { printf '🔴 사본을 못 떴다. 멈춘다.\n'; exit 1; }
  chmod 644 "$BK"
  ok "사본 $BK"
  TL0=$(wc -l < "$CF"); TI0=$(grep -c '^ *image:' "$CF")
  TB=$(mktemp) || exit 1; TA=$(mktemp) || exit 1
  grep -n '^ *image:' "$CF" > "$TB"
  APPB=$(app_img_lines)
  # 🔴 **고치기 전에 몇 줄이 달라질지 센다 — 박지 않는다.**
  TWANT=0
  [ "$S_AS_TOOLS" != NEW ] && TWANT=$((TWANT+1))
  say "기대 — 지금 상태가 A/S 도구 $S_AS_TOOLS 이므로 달라질 image: 줄은 ${TWANT}개다 (세어서 정했다)"
  TOOLFAIL=0
  TAL=$(img_line "$AS_TOOLS_SVC") || true
  # 🔴 **빈 값도 막는다.** 머리는 찾았는데 image: 줄이 없으면 빈 값을 준다 —
  #    그 빈 값을 awk 의 NR 비교에 넘기면 **아무 줄도 안 바뀌는데 조용히 성공**한다.
  if [ -z "${TAL:-}" ]; then
    bad "🔴 $AS_TOOLS_SVC 의 image: 줄을 못 찾았다 (서비스가 없거나 그 블록에 image: 가 없다)"
    doubt; TOOLFAIL=1
  fi
  if [ "${TOOLFAIL}" = "0" ]; then
    TNF0=$(nf_at "$TAL")
    if [ "${TNF0:-0}" != "2" ]; then
      bad "🔴 $AS_TOOLS_SVC 의 ${TAL}줄이 낱말 ${TNF0:-?}개다 — 'image: 태그' 두 낱말만 있어야 한다"
      awk -v n="$TAL" 'NR==n' "$CF" | sed 's/^/      /'
      doubt; TOOLFAIL=1
    elif [ "$(tag_at "$TAL")" = "$AS_TOOLS_NEW" ]; then
      ok "$AS_TOOLS_SVC 가 이미 $AS_TOOLS_NEW 다 — 고칠 것이 없다"
    else
      TMP=$(mktemp) || exit 1
      awk -v n="$TAL" -v to="$AS_TOOLS_NEW" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
      cp "$TMP" "$CF"; rm -f "$TMP"
      [ "$(tag_at "$TAL")" = "$AS_TOOLS_NEW" ] && ok "$AS_TOOLS_SVC → $AS_TOOLS_NEW (${TAL}줄)" \
        || { bad "$AS_TOOLS_SVC 의 태그가 $(tag_at "$TAL") 다"; TOOLFAIL=1; }
    fi
  fi
  grep -n '^ *image:' "$CF" > "$TA"
  TDIFF=$(diff "$TB" "$TA" | grep -c '^[<>]' || true)
  APPA=$(app_img_lines)
  say "줄 수 $TL0 → $(wc -l < "$CF") · image: 줄 $TI0 → $(grep -c '^ *image:' "$CF") · 달라진 image: 줄 $((TDIFF / 2))개"
  [ "$(wc -l < "$CF")" = "$TL0" ] && ok "줄 수가 그대로다" || bad "줄 수가 달라졌다"
  [ "$(grep -c '^ *image:' "$CF")" = "$TI0" ] && ok "image: 줄 수가 그대로다" || bad "image: 줄 수가 달라졌다"
  [ "$((TDIFF / 2))" = "$TWANT" ] && ok "image: 줄이 **꼭 ${TWANT}개만** 달라졌다 (도구 하나 · 남의 것은 안 건드렸다)" \
    || { bad "image: 줄이 $((TDIFF / 2))개 달라졌다 — ${TWANT}개를 기대했다. 남의 것을 건드렸다"; doubt; }
  [ "$APPA" = "$APPB" ] && ok "앱의 image: 줄은 안 바뀌었다 (--go 의 일이다)" \
    || bad "🔴 앱 image: 줄이 바뀌었다 — 이 단계가 건드릴 자리가 아니다"
  dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"
  rm -f "$TB" "$TA"
  if [ "$FAIL" != 0 ] || [ "$TOOLFAIL" != 0 ]; then
    printf '\n🔴 어긋났다 — **사본으로 되돌리고 DB 는 안 건드린다.**\n'
    cp "$BK" "$CF"; say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $TL0)"
    exit 1
  fi

  # ── ㄹ. 🔴 도구 이미지의 안을 센다 — 쓸 수 있는 판이 맞는가 ─────────
  #   🔴 「태그를 고쳤다」와 「쓸 수 있다」는 다르다. 겉이 아니라 결과를 본다.
  if "$DOCKER" image inspect "$AS_TOOLS_NEW" >/dev/null 2>&1; then as_tools_inside_check
  else bad "🔴 $AS_TOOLS_NEW 가 NAS 에 없다 — compose 가 없는 이미지를 가리키게 됐다"; fi
  if [ "$FAIL" != 0 ]; then
    printf '\n🔴 도구가 온전하지 않다 — **사본으로 되돌리고 DB 는 안 건드린다.**\n'
    cp "$BK" "$CF"; exit 1
  fi

  # ── ㅁ. 🔴 볼륨을 128 로 올린다 — **이번 판에는 반드시 푼다** ───────
  printf '\n    ── A/S 마이그레이션 볼륨을 %s 로 (%s 이 묶음 안에만 있다)\n' "$AS_MIG_AFTER" "$AS_LAST_MIG"
  read_migdir
  if [ "$MIG_STATE" != DONE ]; then
    say "볼륨이 .sql ${MIG_N_SQL} · idx ${MIG_N_J} 다 — $AS_MIG_AFTER 를 기대했다. **묶음을 푼다**"
    place_migs || { printf '\n🔴 **DB 도 앱도 그대로다.**\n'; cp "$BK" "$CF"; exit 1; }
    read_migdir
  else
    say "볼륨이 이미 $AS_MIG_AFTER 다 — **묶음을 안 푼다**(이미 풀어 둔 것이다)"
  fi
  say "지금 $MIGDIR — .sql ${MIG_N_SQL}장 · meta/_journal.json 의 idx ${MIG_N_J}개"
  [ "$MIG_N_SQL" = "$AS_MIG_AFTER" ] && ok ".sql 이 ${MIG_N_SQL}장이다" \
    || bad ".sql 이 ${AS_MIG_AFTER}장이 아니다 (${MIG_N_SQL}장)"
  [ "$MIG_N_J" = "$AS_MIG_AFTER" ] && ok "meta/_journal.json 의 idx 가 ${MIG_N_J}개다" \
    || bad "idx 가 ${AS_MIG_AFTER}개가 아니다 (${MIG_N_J}개)"
  # 🔴 0121~0127 이 온전한가 + 0128 이 없는가 + 지우는 문장 0 + 0127 의 속.
  check_keep_migs || true
  if [ "$FAIL" != 0 ]; then printf '\n🔴 마이그레이션 파일이 온전하지 않다 — **DB 도 앱도 그대로다.**\n'; cp "$BK" "$CF"; exit 1; fi
  # 🔴 컨테이너가 **실제로 그 폴더를 읽는지** 본다. 겉이 아니라 결과다 —
  #    호스트에서 보이는 것과 컨테이너 안에서 보이는 것이 다를 수 있다.
  INSQL=$(dct run --rm --entrypoint sh "$AS_TOOLS_SVC" -c "ls -1 $IMG_MIGDIR/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r' | tail -1)
  say "$AS_TOOLS_SVC 안에서 본 $IMG_MIGDIR 의 .sql: ${INSQL:-?}장 (기대 $AS_MIG_AFTER)"
  if [ "${INSQL:-0}" = "$AS_MIG_AFTER" ]; then ok "컨테이너 안에서도 $AS_MIG_AFTER 장이다 (볼륨이 제대로 붙었다)"
  else bad "컨테이너 안이 ${INSQL:-?}장이다 — $AS_MIG_AFTER 장이어야 한다"; fi
  # 🔴 **0127 이 컨테이너 안에서도 보이는가** — 수만 맞고 다른 것이 들었을 수 있다.
  #    🔴 이것이 안 보이면 적용이 **0건으로 조용히 끝난다.**
  INNEW=$(dct run --rm --entrypoint sh "$AS_TOOLS_SVC" -c "ls -1 $IMG_MIGDIR/${AS_LAST_MIG}_*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r' | tail -1)
  say "$AS_TOOLS_SVC 안에서 본 $AS_LAST_MIG: ${INNEW:-?}장 (기대 $AS_NEW_MIGS_WANT)"
  if [ "${INNEW:-0}" = "$AS_NEW_MIGS_WANT" ]; then ok "컨테이너 안에 $AS_LAST_MIG 이 있다 (적용할 것이 보인다)"
  else bad "🔴 컨테이너 안에 ${INNEW:-?}장만 있다 — **적용이 0건으로 조용히 끝난다**"; doubt; fi
  if [ "$FAIL" != 0 ]; then printf '\n🔴 **DB 도 앱도 그대로다.** 멈춘다.\n'; cp "$BK" "$CF"; exit 1; fi

  # ── ㅂ. 적용 전 preflight — **대기 1건**이어야 한다 ────────────────
  #   🔴 **대기 건수는 글자로 안 센다** — 그 줄이 한글이라 grep 이 환경에 따라
  #      어긋날 수 있다. **DB 기록과 볼륨 수의 차이**로 센다(순수한 셈이다).
  printf '\n    ── 적용 전 db:preflight (이 판은 **대기 %s건**이 맞다)\n' "$AS_NEW_MIGS_WANT"
  PEND=$((MIG_N_SQL - ${MIG_AS0:-0}))
  say "볼륨 ${MIG_N_SQL} - 기록 ${MIG_AS0:-?} = 적용 대기 ${PEND}건 (기대 $AS_NEW_MIGS_WANT)"
  if [ "${MIG_AS0:-x}" = "$AS_MIG_BEFORE" ] && [ "$PEND" = "$AS_NEW_MIGS_WANT" ]; then
    ok "적용 대기가 **${AS_NEW_MIGS_WANT}건**이다 (셈으로 확인했다 — $AS_LAST_MIG 이다)"
  elif [ "${MIG_AS0:-x}" = "$AS_MIG_AFTER" ] && [ "$PEND" = "0" ]; then
    hm "적용 대기가 **0건**이다 — 이미 적용돼 있다. 🔵 **다시 돌려도 안전하다**(건너뛴다)"
  else
    bad "🔴 적용 대기가 ${PEND}건이다 — $AS_NEW_MIGS_WANT 건(또는 이미 끝났으면 0건)을 기대했다"
    say "🔴 **볼륨이나 DB 가 전제와 다르다.** 고치지 말고 먼저 알리세요."
    doubt
    printf '\n🔴 **DB 를 안 건드리고 멈춘다.** 앱은 그대로 돈다.\n'
    cp "$BK" "$CF"
    exit 1
  fi
  dct run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | tail -30 | sed 's/^/    /'
  PRC=${PIPESTATUS[0]}
  say "(종료 코드 $PRC — 기대 0)"
  say "🔵 위 출력에 이렇게 나오는 것이 **정상입니다**(개발 실측 2026-11-12):"
  say "   전체 마이그레이션 $AS_MIG_AFTER 건 · 적용 대기 $AS_NEW_MIGS_WANT 건"
  say "   [${AS_LAST_MIG}_domestic_order_permission_leaves] **더하기만 합니다 — 사라지는 자료 없음**"
  say "🔴 **「사라질 자료」가 있다고 나오면 종료 코드가 1 이고 여기서 멈춥니다.**"
  if [ "$PRC" != 0 ]; then
    bad "🔴 db:preflight 가 0 이 아니다 ($PRC) — **사라질 자료가 있다는 뜻이다**"
    say "🔴 $AS_LAST_MIG 은 **INSERT 넷뿐**이다. 0 이 아니면 **전제가 깨진 것**이다."
    doubt
    printf '\n🔴 **DB 를 안 건드리고 멈춘다.** 앱은 그대로 돈다.\n'
    cp "$BK" "$CF"
    exit 1
  fi

  # ── ㅅ. 돌린다 — 🔴 **여기서 DB 가 바뀐다** ────────────────────────
  printf '\n    ── 🔴 돌린다 (여기서 DB 가 바뀐다 · drizzle 은 다시 돌려도 안전하다)\n'
  say "🔴 drizzle 은 **밀린 것을 한 트랜잭션에** 넣습니다 — 하나라도 실패하면 안 올라갑니다."
  say "🔵 $AS_LAST_MIG 은 **표를 한 칸도 안 바꿉니다** — INSERT ... SELECT 넷뿐입니다."
  say "🔵 **옮길 행이 ${PERM_SUM}줄입니다**(위 2-ㅁ 에서 쟀습니다). 0 이어도 조용히 통과합니다."
  say "🔴 되돌릴 길(방금 뜬 사진): ${DUMP:-없음}"
  dct run --rm "$AS_TOOLS_SVC" npm run db:migrate 2>&1 | tail -30 | sed 's/^/    /'
  RC=${PIPESTATUS[0]}
  if [ "$RC" = 0 ]; then ok "A/S db:migrate 가 종료 코드 0 으로 끝났다"
  else
    bad "🔴 A/S db:migrate 실패 (종료 코드 $RC)"
    say "🔴 **drizzle-kit migrate 는 오류를 삼킨다** — 종료 코드 1 만 남는 일이 흔하다."
    say "   위 30줄을 보시고, 안 보이면 로그 전체($LOG)를 보세요."
    say "🔵 앱은 **그대로 옛 판으로 돕니다.** 직원이 느끼는 것이 없습니다."
  fi
  say "🔴 **종료 코드만으로 「성공」이라 하지 않습니다** — 아래에서 **DB 를 다시 읽어** 셉니다."

  # ── ㅇ. 🔴 값으로 확인 (겉이 아니라 결과) ───────────────────────────
  printf '\n    ── 🔴 값으로 확인 — **기록이 %s 에서 %s 로 올라갔어야** 한다\n' "$AS_MIG_BEFORE" "$AS_MIG_AFTER"
  MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
  say "기록 ${MIG_AS0:-?} → ${MIG_AS1:-?} (뒤가 $AS_MIG_AFTER 여야 한다)"
  if [ "${MIG_AS1:-x}" = "$AS_MIG_AFTER" ]; then
    if [ "${MIG_AS0:-x}" = "$AS_MIG_BEFORE" ]; then
      ok "기록이 **$AS_MIG_BEFORE → $AS_MIG_AFTER** 다 — $AS_LAST_MIG 이 올라갔다 (값으로 확인했다)"
    else
      ok "기록이 $AS_MIG_AFTER 다 — 이미 올라가 있었다 (다시 돌린 것이고 해롭지 않다)"
    fi
  else
    bad "🔴 기록이 ${MIG_AS0:-?} → ${MIG_AS1:-?} 다 — 뒤가 $AS_MIG_AFTER 여야 한다"
    say "🔴 **drizzle-kit migrate 는 오류를 삼킨다.** 종료 코드가 0 이어도 안 올라갈 수 있다 —"
    say "   그래서 이 줄이 있다. 위 30줄과 로그($LOG)를 보세요."
    doubt
  fi
  # ── 🔴 **이 판의 진짜 증거** — 잎 넷에 행이 들어갔는가 ─────────────
  #    🔴 **기록만 보고 끝내지 않는다.** 0127 은 표를 안 바꾸므로 「칸이 생겼나」로
  #       잴 수 없다 — **옮길 행이 0 이 됐는가**로 잰다.
  printf '\n    ── 🔴 %s 이 **제 일을 했는가** (옮길 행이 0 이 되어야 한다)\n' "$AS_LAST_MIG"
  PERM_AFTER=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $PERM_TABLE")
  say "$PERM_TABLE 줄 수 ${PERM_BEFORE:-?} → ${PERM_AFTER:-?} (기대 +${PERM_SUM})"
  PSUM2=0; PSEEN2=0
  for lf in $PERM_LEAVES; do
    n=$(perm_pending_for "$lf")
    m=$(perm_rows_of "$PERM_OLD_KEY.$lf")
    printf '      %s.%-10s 아직 넣을 것 %s줄 · 지금 저장된 행 %s줄\n' "$PERM_OLD_KEY" "$lf" "${n:-못 쟀다}" "${m:-못 쟀다}"
    if isnum "${n:-}"; then PSUM2=$((PSUM2 + n)); PSEEN2=$((PSEEN2 + 1)); fi
  done
  if [ "$PSEEN2" != "$PERM_LEAVES_WANT" ]; then
    hm "잎 ${PSEEN2}개만 쟀다 — ${PERM_LEAVES_WANT}개를 기대했다. **빈 결과는 삼켜진 오류일 수 있다**"
    doubt
  elif [ "$PSUM2" = "0" ]; then
    ok "**아직 넣을 행이 0줄이다** — $AS_LAST_MIG 이 제 일을 다 했다 (값으로 확인했다)"
    if [ "${PERM_SUM:-0}" -ge 1 ]; then
      say "🔵 적용 전 ${PERM_SUM}줄 → 지금 0줄. $PERM_TABLE 가 ${PERM_BEFORE:-?} → ${PERM_AFTER:-?} 로 늘었습니다."
    else
      say "🔵 적용 전에도 0줄이었습니다 — **운영이 전부 코드 기본값으로 돈다**는 뜻이고 정상입니다."
      say "   🔵 그래도 **기록은 $AS_MIG_AFTER 가 됐습니다** — 그것이 --go 의 선행 조건입니다."
    fi
  else
    bad "🔴 아직 넣을 행이 ${PSUM2}줄 남았다 — **0 이어야 한다.** 적용이 덜 됐다"
    say "🔴 위 db:migrate 의 출력과 기록 수를 보세요. **--go 로 넘어가지 마세요.**"
    doubt
  fi
  # 🔵 옛 행은 **안 지운다** — 되돌리기를 한 문장으로 두려는 것이다.
  PERM_OLD_AFTER=$(perm_rows_of "$PERM_OLD_KEY")
  say "옛 $PERM_OLD_KEY 행: ${PERM_OLD_N:-?} → ${PERM_OLD_AFTER:-?} (🔵 **그대로인 것이 정상**이다)"
  if [ "${PERM_OLD_AFTER:-x}" = "${PERM_OLD_N:-y}" ]; then
    ok "옛 $PERM_OLD_KEY 행이 **그대로 남아 있다** ($AS_LAST_MIG 은 안 지운다 — 되돌리기가 한 문장이 된다)"
    say "🔵 남아도 해롭지 않습니다 — 읽는 쪽이 잎이 아닌 키를 거르므로 **아무 판정에도 안 낍니다.**"
  else
    hm "옛 행이 ${PERM_OLD_N:-?} → ${PERM_OLD_AFTER:-?} 로 달라졌다 — 그대로를 기대했다. 사람이 보세요"
  fi
  # 🔴 0124~0126 이 만든 것이 **아직 그대로 있는가** — 0127 이 건드릴 자리는 아니다.
  NC=$(has_column     "$AS_BOX" "$AS_DB" "$AS_COL_TABLE" "$AS_COL")
  E1=$(has_enum_value "$AS_BOX" "$AS_DB" "$AS_ENUM1" "$AS_ENUM_VALUE")
  I1=$(has_index      "$AS_BOX" "$AS_DB" "$AS_IDX1")
  IXC2=$(index_cols   "$AS_BOX" "$AS_DB" "$NEW_IDX")
  say "0124 의 칸 ${NC:-?} · enum ${E1:-?} · 유니크 인덱스 ${I1:-?} · 그 칸 수 ${IXC2:-?} (1·1·1·$NEW_IDX_COLS_WANT)"
  if [ "${NC:-0}" = "1" ] && [ "${E1:-0}" = "1" ] && [ "${I1:-0}" = "1" ] && [ "${IXC2:-x}" = "$NEW_IDX_COLS_WANT" ]; then
    ok "지난 판들이 만든 것이 그대로 있다 ($AS_LAST_MIG 은 표를 안 건드린다)"
  else
    bad "🔴 지난 판의 칸·enum·인덱스가 ${NC:-?}·${E1:-?}·${I1:-?}·${IXC2:-?} 다 — **그대로여야 한다**"
    doubt
  fi
  printf '\n    ── 🔴 줄 수가 그대로인가 (role_permissions 말고는 하나도 안 바뀐다)\n'
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
    || bad "🔴 포털 DB 가 ${MIG_AU1:-?} 다 — $AUTH_MIG_KEEP 그대로여야 한다"

  printf '\n    ── 🔴 앱이 **여전히 옛 판으로** 도는가 (--go 가 아직 안 돌았다)\n'
  "$DOCKER" ps --format '{{.Names}}\t{{.Image}}' 2>/dev/null | sort | sed 's/^/      /'

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$FAIL" = 0 ]; then
    printf '%s\n' "✅ **DB 가 $AS_MIG_BEFORE 에서 $AS_MIG_AFTER 로 올라갔습니다** ($AS_LAST_MIG)."
    printf '%s\n' "  🔵 확인한 것: 기록 $AS_MIG_AFTER · 아직 넣을 행 0줄 · 옛 행 그대로 ·"
    printf '%s\n' "     지난 판의 칸·enum·인덱스 그대로 · 지우는 문장 0줄 · 나머지 표 줄 수 그대로 ·"
    printf '%s\n' "     포털 DB 그대로."
    printf '%s\n' "  🔵 compose 의 $AS_TOOLS_SVC 가 $AS_TOOLS_NEW 가 됐습니다 (사본: $BK)"
    printf '%s\n' "  🔴 되돌릴 길(바꾸기 직전의 덤프): $DUMP"
    printf '%s\n' "     🔵 **되돌릴 일은 거의 없습니다** — $AS_LAST_MIG 은 더하기만 합니다. 옛 앱도 그냥 돕니다."
    printf '%s\n' "     🔴 그래도 물려야 하면 그 .sql 머리말의 **DELETE 한 문장**이 더 빠릅니다(코드도 함께)."
    printf '%s\n' "  🔴 **다음: --go** — 이제 PHASE=MID 라 --go 에서 image: 줄이 **하나만** 달라집니다."
    printf '%s\n' "     🔴 **지금 앱은 아직 옛 판($AS_OLD_TAG)입니다.** 잎 넷은 생겼지만 아무도 안 씁니다 —"
    printf '%s\n' "        그 상태로 두어도 해롭지 않습니다."
  else
    printf '%s\n' "🔴 위 ✗ 를 보세요. 🔵 이 모드는 **다시 돌려도 안전합니다**: bash $0 --migrate"
    printf '%s\n' "  🔴 **DB 가 바뀌었을 수 있습니다** — 위 「값으로 확인」 절의 기록 수를 보세요."
    printf '%s\n' "  🔴 덤프: ${DUMP:-없음}"
    printf '%s\n' "  🔴 **--go 로 넘어가지 마세요** — --go 는 기록이 $AS_MIG_AFTER 가 아니면 멈춥니다."
  fi
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi
# ── 5. --go / --rollback : compose 의 image: 줄을 바꾼다 ─────────────
#  🔴 --go 는 앱 하나(와 PRE 면 도구 하나)를 고친다. --rollback 은 **앱만** 되돌린다 —
#     도구는 새 판 그대로 둔다(39·41~59번과 같은 판단).
#  🔴 **app-po · app-auth · tools-auth 줄은 어느 모드에서도 안 건드린다.**
printf '\n== 5. compose 의 image: 줄을 바꾼다\n'
# 🔴 **덤프를 여기서도 뜬다.** --migrate 를 건너뛰고 --go 로 바로 올 수 있기 때문이다.
#    🔵 --migrate 를 이미 돌리셨으면 사진이 둘이 된다 — 해롭지 않다.
#    🔵 --rollback 에서는 안 뜬다: 되돌리는 길은 빠를수록 좋다.
if [ "$MODE" = go ]; then
  make_dump "--migrate 를 건너뛰었을 수 있다 — 갈아 끼우기 전 사진을 남긴다"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 덤프를 못 떴다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi
  # 🔴 **기록이 128 인지 막는다.** 🔵 59번은 여기가 「127 그대로인가」였다.
  #    🔴 **이 판은 「128 로 올라갔나」다** — 새 앱이 권한 잎 넷을 읽는다.
  if [ "${MIG_AS0:-x}" != "$AS_MIG_AFTER" ]; then
    bad "🔴 DB 기록이 ${MIG_AS0:-못 쟀다} 다 — **$AS_MIG_AFTER 이어야 --go 할 수 있다.**"
    say "🔴 **--migrate 를 먼저 돌리세요**: bash $0 --migrate"
    say "   🔵 그 모드가 묶음을 풀고 $AS_MIG_BEFORE → $AS_MIG_AFTER 로 올립니다."
    say "🔵 **옮길 행이 0건이어도 --migrate 는 돌려야 합니다** — 기록이 올라가야 합니다."
    printf '\n🔴 **아무것도 안 고치고 멈춘다.** 앱은 그대로 옛 판으로 돈다.\n'
    exit 1
  fi
  ok "DB 기록이 $AS_MIG_AFTER 다 (--migrate 가 끝났다 — 새 앱이 읽을 잎이 있다)"
  # 🔴 **수만 보지 않는다** — 잎 넷에 아직 넣을 것이 없는지 다시 묻는다.
  GSUM=0; GSEEN=0
  for lf in $PERM_LEAVES; do
    n=$(perm_pending_for "$lf")
    if isnum "${n:-}"; then GSUM=$((GSUM + n)); GSEEN=$((GSEEN + 1)); fi
  done
  say "잎 넷에 아직 넣을 행: ${GSUM}줄 (기대 0 · 잰 잎 ${GSEEN}/${PERM_LEAVES_WANT}개)"
  if [ "$GSEEN" != "$PERM_LEAVES_WANT" ]; then
    hm "잎 ${GSEEN}개만 쟀다 — **빈 결과는 삼켜진 오류일 수 있다.** 사람이 보세요"
  elif [ "$GSUM" = "0" ]; then
    ok "아직 넣을 행이 0줄이다 (기록 수가 아니라 **값**으로 확인했다)"
  else
    bad "🔴 아직 넣을 행이 ${GSUM}줄이다 — **기록만 $AS_MIG_AFTER 이고 이사가 덜 끝났다.** 멈추고 알리세요"
    say "🔴 **그 사이에 누가 권한 화면에서 저장했을 수 있습니다** — --migrate 를 한 번 더 돌리세요."
    doubt
    printf '\n🔴 **아무것도 안 고치고 멈춘다.** 앱은 그대로 옛 판으로 돈다.\n'
    exit 1
  fi
fi
# 🔵 1절에서 읽어 둔 상태를 쓴다. **여기서 다시 읽지 않는다.**
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
#    🔵 **이 판의 --go 는 PRE 에서 둘 · MID 에서 하나**다 (--migrate 가 도구 줄을
#       먼저 고쳐 두기 때문이다).
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
[ "$((DIFFN / 2))" = "$WANT_DIFF" ] && ok "image: 줄이 꼭 ${WANT_DIFF}개만 달라졌다 (우리 것 · app-po·app-auth·tools-auth 는 안 건드렸다)" \
  || { bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — ${WANT_DIFF}개를 기대했다. 남의 것을 건드렸을 수 있다"; doubt; }
dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 6. 앱 **하나**를 다시 띄운다 ──────────────────────────────────────
#  🔴 도구는 profiles: [tools] 라 up -d 로 띄우지 않는다.
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
  printf '%s' "$CODE" | grep -qE '200|30[1237]' && ok "$CN 가 응답한다 ($CODE)" || bad "$CN 응답이 ${CODE:-없음}"
done
[ "$VER_SEEN" = "$SITES_WANT" ] && ok "앱 ${SITES_WANT}개를 다 봤다 (표본이 비지 않았다)" \
  || bad "🔴 앱을 ${VER_SEEN}개만 봤다 — ${SITES_WANT}개를 기대했다"

# 🔴 **PO 와 포털이 그대로 도는가** — 이번 판에서 안 건드렸다는 증거다.
#    🔴 **set -- 로 쪼개지 않는다.** 상자 번호가 빈 값이면 낱말이 하나 줄어
#       **엉뚱한 값끼리 맞대어 보게 된다.** 인자를 이름으로 받는 함수로 둔다.
untouched_box_check() { # 1 컨테이너 2 호스트 포트 3 교체 전 상자 번호
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

# 🔴 DB — 기록이 **128 그대로**인가 (앱 교체가 DB 를 건드릴 일은 없다)
#    🔵 --rollback 에서도 128 이다 — **0127 은 자동으로 안 되돌린다.**
MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
say "A/S 마이그레이션 ${MIG_AS0:-?} -> ${MIG_AS1:-?} (기대 $AS_MIG_AFTER · **이 단계가 DB 를 안 바꾼다**)"
[ "${MIG_AS1:-x}" = "$AS_MIG_AFTER" ] && ok "$AS_MIG_AFTER 다 (이 단계가 DB 를 한 글자도 안 바꿨다)" \
  || bad "🔴 ${MIG_AS1:-?} 다 — $AS_MIG_AFTER 여야 한다. **DB 가 그 사이에 움직였다**"
MIG_AU1=$(mig_count "$AUTH_BOX" "$AUTH_DB")
say "포털 마이그레이션 ${MIG_AU0:-?} -> ${MIG_AU1:-?} (기대 $AUTH_MIG_KEEP)"
[ "${MIG_AU1:-x}" = "$AUTH_MIG_KEEP" ] && ok "포털이 $AUTH_MIG_KEEP 그대로다 (안 건드렸다)" \
  || bad "🔴 포털이 ${MIG_AU1:-?} 다 — $AUTH_MIG_KEEP 그대로여야 한다"
# 🔴 **새 앱이 읽을 잎이 있는가** — 기록 수가 아니라 **값**으로 다시 묻는다.
VSUM=0; VSEEN=0
for lf in $PERM_LEAVES; do
  n=$(perm_pending_for "$lf")
  if isnum "${n:-}"; then VSUM=$((VSUM + n)); VSEEN=$((VSEEN + 1)); fi
done
say "잎 넷에 아직 넣을 행: ${VSUM}줄 (기대 0 · 잰 잎 ${VSEEN}/${PERM_LEAVES_WANT}개)"
if [ "$VSEEN" != "$PERM_LEAVES_WANT" ]; then
  hm "잎 ${VSEEN}개만 쟀다 — **빈 결과는 삼켜진 오류일 수 있다.** 사람이 보세요"
elif [ "$VSUM" = "0" ]; then
  ok "잎 넷에 아직 넣을 행이 0줄이다 (**새 앱이 읽을 자리가 온전하다**)"
else
  bad "🔴 아직 넣을 행이 ${VSUM}줄이다 — **좁혀 둔 설정이 조용히 풀린 역할이 있다는 뜻**이다"
  say "🔴 --migrate 를 한 번 더 돌리세요(다시 돌려도 안전합니다)."
  doubt
fi
# 🔴 지난 판들이 만든 칸도 **아직 있는가** — 새 앱이 읽고 **쓴다.**
NC=$(has_column     "$AS_BOX" "$AS_DB" "$AS_COL_TABLE" "$AS_COL")
E1=$(has_enum_value "$AS_BOX" "$AS_DB" "$AS_ENUM1" "$AS_ENUM_VALUE")
I1=$(has_index      "$AS_BOX" "$AS_DB" "$AS_IDX1")
V5=$(has_column     "$AS_BOX" "$AS_DB" "$NEW_COL_T2" "$NEW_COL_5")
VIX=$(index_cols    "$AS_BOX" "$AS_DB" "$NEW_IDX")
say "0124 의 칸 ${NC:-?} · enum ${E1:-?} · 인덱스 ${I1:-?} · 0126 의 ${NEW_COL_5} ${V5:-?} · 인덱스 칸 수 ${VIX:-?}"
if [ "${NC:-0}" = "1" ] && [ "${E1:-0}" = "1" ] && [ "${I1:-0}" = "1" ] && [ "${V5:-0}" = "1" ] && [ "${VIX:-x}" = "$NEW_IDX_COLS_WANT" ]; then
  ok "지난 판들이 만든 것이 그대로 있다 — **앱이 읽을 칸이 있다**"
else
  bad "🔴 칸·enum·인덱스가 ${NC:-?}·${E1:-?}·${I1:-?}·${V5:-?}·${VIX:-?} 다 — **앱이 그 자리에서 깨진다**"
  doubt
fi

# 🔴 **양식을 다시 잰다** — 교체 뒤에도 그대로인지, 그리고 **새 앱이 보는지.**
templates_check
# 🔵 **공유폴더 둘을 다시 잰다** — 볼륨은 컨테이너를 다시 띄울 때 다시 붙는다.
purchase_order_archive_check
quote_archive_check
# 🔴 **PO 권한을 다시 잰다** — 답이 같아야 하지만, **같은지를 봐야** 안다.
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
ATL=$(img_line "$AUTH_TOOLS_SVC" 2>/dev/null || true)
if [ -n "${ATL:-}" ]; then
  ATC=$(tag_at "$ATL")
  [ "$ATC" = "$AUTH_TOOLS_KEEP" ] && ok "$AUTH_TOOLS_SVC 가 $AUTH_TOOLS_KEEP 그대로다 (안 건드렸다)" \
    || hm "$AUTH_TOOLS_SVC 가 $ATC 다 — $AUTH_TOOLS_KEEP 를 기대했다. 사람이 보세요"
else
  bad "compose 에 $AUTH_TOOLS_SVC 가 없다"
fi
if [ "$MODE" = go ]; then as_tools_inside_check; fi
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
  printf '%s\n' "🔵 **DB 는 --migrate 가 이미 올렸습니다** — 기록이 $AS_MIG_AFTER 입니다."
  printf '%s\n' "   🔵 이 단계(--go)는 DB 를 **한 글자도 안 바꿨습니다.**"
  printf '%s\n' "   🔵 $AS_LAST_MIG 은 **표를 한 칸도 안 바꿨습니다** — 자료만 옮겼습니다(0건일 수 있습니다)."
  printf '%s\n' ""
  printf '%s\n' "🔴 **도구 이미지 안의 엑셀 읽개 둘은 NAS 에서 돌리지 마세요**(이번 판이 만든 것이 아닙니다)."
  printf '%s\n' "   둘 다 **개발 DB 게이트**를 지나야 돌고 그 게이트는 루프백 5442 만 통과시킵니다."
  printf '%s\n' ""
  if [ "$MODE" = go ]; then
    printf '%s\n' "══════════════════════════════════════════════════════════════"
    printf '%s\n' "🔴 **지금 바로 할 일**"
    printf '%s\n' "══════════════════════════════════════════════════════════════"
    printf '%s\n' "  🔴 **올린 뒤의 수로 다시 돌립니다.**"
    printf '%s\n' "       bash $0 --count"
    printf '%s\n' "     🔴 **①(옮길 행)이 0 이어야 합니다** — --migrate 가 제 일을 했다는 증거입니다."
    printf '%s\n' "     🔴 **⑤(거르개가 보여 줄 건 수)를 적어 두세요** — 아래 눈 확인에서 맞댑니다."
    printf '%s\n' "     🔵 다섯 도구는 앞뒤가 같아야 정상입니다 — 이번 판이 안 건드립니다."
    printf '%s\n' "══════════════════════════════════════════════════════════════"
    printf '%s\n' ""
  fi
  printf '%s\n' "🔴 **마지막은 눈입니다** — 이번 판은 **커밋 다섯**이고 화면이 여러 곳에서 바뀝니다."
  printf '%s\n' ""
  printf '%s\n' "  ── A. 🔵 [역할별 접근 권한] 화면 (**가장 빨리 확인되는 곳**) ──"
  printf '%s\n' "  ① [사용자 관리] › [역할별 접근 권한] 의 **왼쪽 목록**을 보세요."
  printf '%s\n' "     **메뉴 묶음·차례대로** 서야 하고, 묶음 머리말 다섯이 메뉴와 같은 글자여야 합니다."
  printf '%s\n' "     🔵 주간보고가 대시보드 아래 **하위메뉴**로 들여써집니다."
  printf '%s\n' "     🔴 맨 아래에 **[메뉴에 없는 항목]** 묶음이 있고 거기에 재고 관리가 들어갑니다 —"
  printf '%s\n' "        🔴 **그 머리말이 앱 번들 표식입니다.** 안 보이면 옛 판이 도는 것입니다."
  printf '%s\n' "     🔵 개발자 모드는 **여기 안 나옵니다**(일부러 없습니다)."
  printf '%s\n' "  ② 🔴 **[내자 정리]가 1칸에서 4칸**(조회·수정·삭제복원·승인)으로 쪼개져 있어야 합니다."
  printf '%s\n' "     🔴 **역할별 수준이 쪼개기 전과 같아야** 합니다 — 달라졌으면 멈추고 알리세요."
  printf '%s\n' "  ③ 🔵 [검수/승인] 칸에 **쓰기**가 생깁니다(= 승인 요청을 올릴 수 있는가)."
  printf '%s\n' "     🔵 읽기만 가진 역할은 **탭은 보이고 단추만 없습니다.**"
  printf '%s\n' ""
  printf '%s\n' "  ── B. 🔴 수리 건 상세의 탭 여덟 ───────────────────────────"
  printf '%s\n' "  ④ 역할 하나의 탭 권한을 **닫아 보고** 그 탭이 사라지는지 보세요."
  printf '%s\n' "     🔴 **주소를 직접 쳐도 막혀야** 합니다 — 탭마다 서버가 다시 봅니다."
  printf '%s\n' "     🔵 [기본 정보]는 여덟을 전부 닫아도 **남습니다**(정상입니다)."
  printf '%s\n' "     🔵 기본값은 지금과 같으므로 **배포 직후에는 아무것도 안 사라집니다.**"
  printf '%s\n' ""
  printf '%s\n' "  ── C. 🔵 [전체 A/S 현황]의 새 거르개 ──────────────────────"
  printf '%s\n' "  ⑤ [현재 상태] 칸을 열면 **마지막 줄에 [최종 출하 승인 완료]** 가 있어야 합니다."
  printf '%s\n' "     🔵 상태 열둘 **뒤**입니다. 고르면 그 배지가 붙은 건만 남습니다."
  printf '%s\n' "     🔴 **--count 의 ⑤ 와 건수가 같아야** 합니다 — 같은 묶음을 씁니다."
  printf '%s\n' "     🔵 0건으로 나와도 **배포 잘못이 아닙니다** — 지금 그런 건이 없다는 뜻입니다."
  printf '%s\n' ""
  printf '%s\n' "  🔴 **「아무것도 안 바뀐 것 같다」면** A① 의 [메뉴에 없는 항목] 머리말을 먼저 보세요 —"
  printf '%s\n' "     그것이 보이면 새 판이 돌고 있는 것입니다."
  printf '%s\n' ""
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "🔴 **알고도 안 고친 것 — PO 가 모르는 것이 셋입니다**(55번에서 넘어옴)"
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "  ① dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 APPROVAL_REQUIRED 가 없습니다."
  printf '%s\n' "  ② PO 는 납품일 칸(delivered_date·delivered_by)을 모릅니다."
  printf '%s\n' "  ③ PO 는 회차 승인(due_date_row_order)을 모른 채 같은 표를 고칩니다."
  printf '%s\n' "  🔵 **지금은 안전합니다** — 운영에서 직원의 PO 접근 권한을 모두 빼 두셨습니다"
  printf '%s\n' "     (2026-11-08). 🔴 **PO 를 다시 여는 날 셋을 한 묶음으로 이식해야 합니다.**"
  printf '%s\n' ""
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (app-as 만 되돌립니다)"
  printf '%s\n' "  🔵 도구는 $AS_TOOLS_NEW 그대로 둡니다."
  printf '%s\n' "  🔴 **DB 는 자동으로 안 되돌립니다** — $AS_LAST_MIG 은 더하기만 하므로 옛 앱도 그냥 돕니다."
  printf '%s\n' "     🔴 그래도 물려야 하면 그 .sql 머리말의 **DELETE 한 문장**을 손으로 돌리고"
  printf '%s\n' "        **코드도 함께** 되돌리세요 — 잎이 코드에 남은 채 행만 지우면 그 역할은"
  printf '%s\n' "        기본값으로 돌아가 **좁혀 둔 설정이 풀립니다.**"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
  printf '%s\n' "  🔵 ✗ 가 **재고 관리 통로** 하나뿐이라면 되돌리기 전에 설정을 먼저 보세요 —"
  printf '%s\n' "     INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN (env/as.env). 🔴 되돌려도 같은"
  printf '%s\n' "     설정 문제는 남습니다 — 옛 판도 같은 통로를 씁니다."
  printf '%s\n' "  🔴 ✗ 가 **PO 의 repair_cases 쓰기 권한**이라면 그것은 **이 배포가 만든 일이**"
  printf '%s\n' "     **아닙니다**(PO 를 안 건드립니다). 되돌려도 안 고쳐집니다."
  printf '%s\n' "  🔴 ✗ 가 **양식**이라면 되돌리지 마세요 — 이 배포는 양식을 한 장도 안 건드립니다."
  printf '%s\n' "  🔴 ✗ 가 **발주서·견적서 공유폴더**라면 되돌려도 안 고쳐집니다 — 볼륨·권한 문제입니다."
  printf '%s\n' "  🔴 ✗ 가 **잎 넷에 아직 넣을 행이 남았다**이면 **--migrate 를 한 번 더** 돌리세요"
  printf '%s\n' "     (다시 돌려도 안전합니다 — drizzle 도 0127 도 이미 된 것은 건너뜁니다)."
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)

