#!/bin/bash
# dss-deploy/nas/setup/61-deploy.sh — 쉰일곱째 배포 (2026-11-13)
#
# 🔵 **배포 회차(쉰일곱째)와 파일 번호(61)가 어긋나는 것은 이 저장소에서 원래
#    그렇다** — 57번이 쉰세째, 58번이 쉰네째, 59번이 쉰다섯째, 60번이 쉰여섯째였다.
#
# 🔵 **판이 5.2 → 5.3 로 하나 는다.** 도구는 19 → 20.
#
# 🔴 NAS 에서 돈다. **DSM 터미널은 긴 명령을 잘라 먹는다**(2026-10-12 하루에 네
#    번 깨졌다). 그래서 손으로 치지 않고 **파일로 올려** 돌린다. 절차는 이렇다:
#      ① (개발 PC · PowerShell) — 🔴 **경로는 빗금으로**
#           cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#           scp -O 61-deploy.sh dss-nas:/volume1/dss/setup/
#           Get-FileHash -Algorithm MD5 61-deploy.sh
#      ② (NAS) md5sum /volume1/dss/setup/61-deploy.sh
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
# 🔴 **60-deploy.sh 에서 베꼈다가 「이번 판엔 거짓」이라 뒤집은 것 열둘**
# ══════════════════════════════════════════════════════════════════════
#   틀과 절 구성은 60-deploy.sh(쉰여섯째)를 그대로 썼다. 🔴 **그런데 전제가
#   다섯 자리에서 뒤집힌다.** 「배포본은 지난 판의 전제를 업고 온다」가 이
#   저장소에 기록된 함정이고, 그 함정은 넷으로 적혀 있다 — **없는 절 · 낡은
#   기대값 · 지난 판 점검표 · 아무것도 안 재는 ✓**. 앞의 둘은 ✗ 로 멈추지만
#   **뒤의 둘은 영영 안 드러난다.**
#   🔵 아래에 적은 「60번은 ~였다」는 **60-deploy.sh 를 직접 열어 확인한 것만**이다.
#
#   ① 🔵 **판이 5.2 → 5.3 · 도구 19 → 20.** 되돌릴 판은 **dss-as:5.2**(60번이 올린 그것).
#   ② 🔴 **덤프 이름이 v57 이다.** 🔵 59번이 남겼던 어긋남(사본 v55 · 덤프 v54)은
#      60번이 고쳤다. **이 판도 1절 맨 앞에서 BK 의 vNN 과 DUMP_VER 를 맞대어 본다** —
#      두 벌로 적힌 값이라 한쪽만 고치면 또 어긋난다.
#   ③ 🔴 **마이그레이션이 또 1건이지만 하는 일이 정반대다.** 0127 은 INSERT 넷뿐이고
#      표를 한 칸도 안 바꿨다. **0128 은 표를 하나 만든다**(badge_visibility_settings).
#      🔴 그래서 **--migrate 뒤에 「값으로 확인」하는 것이 통째로 다르다** —
#      60번은 「옮길 행이 0 이 됐는가」였고, 이번 판은 **「표·칸 여섯·유니크 인덱스·
#      FK 가 생겼는가」**다. 60번 것을 베끼면 **아무것도 안 재는 ✓** 가 된다.
#   ④ 🔴 **기록 기대값이 127/128 이 아니라 128/129 다.** 🔴 두 갈래인 것은 같다.
#   ⑤ 🔴 **2-ㄴ 절에 「이번 판이 만드는 것」이 생겼다.** 60번의 2-ㄴ·2-ㄷ 는
#      「어느 단계에서나 다 있어야 한다」뿐이었다. 이번 판은 **PRE 에 없고 POST 에
#      있어야 하는 것**이 넷이다 — 표 · 칸 여섯 · 유니크 인덱스(칸 2) · FK.
#      🔴 **단계마다 기대값이 다르다** — 한 잣대로 재면 가짜 ✗ 가 난다.
#   ⑥ 🔴 **도구 이미지 안 검사의 파일 목록이 79 → 52 다.** 그리고 **vendor/dss-core
#      가 움직였다** — 공용 스키마에 **새 파일 하나**가 들어왔다. 60번의
#      「칸 셋이 그대로 있는가」에 **「새 표가 있는가」 둘을 보탰다**(셋 → 다섯).
#   ⑦ 🔴 **새 시험이 여덟 → 아홉**이고 **scripts/ 변경이 2 → 3** 이다.
#      🔴 60번의 여덟 경로를 그대로 두면 **아홉 다 no 가 나와 가짜 ✗** 다.
#   ⑧ 🔴 **표식을 전부 갈았다.** 60번의 일곱은 **이번 판이 하나도 안 건드린다** —
#      그대로 두면 **옛 판에서도 전부 ✓** 인 죽은 검사가 된다.
#   ⑨ 🔴 **앱 번들 표식도 갈았다.** 60번의 domesticOrders.view 는 기준판 src/ 에
#      **17파일** 있으므로 못 쓴다. 🔵 대신 **뒷걸음 방지 ④** 로 돌렸다(셋 → 넷).
#   ⑩ 🔴 **--count 의 effect_counts() 를 통째로 갈았다.** 60번은 **권한 행 이사**와
#      **[최종 출하 승인 완료] 거르개**를 셌다 — 🔴 **그 수는 이번 판과 상관이 없다.**
#      그대로 두면 **이 배포를 재는 숫자가 하나도 없다.**
#   ⑪ 🔴 **60번이 남긴 숙제를 고쳤다 — --count 의 ⑥ 이 「못 쟀다」로 나왔다.**
#      까닭은 **SQL 이다**: 「select approval_type::text || ' ' || count(*) …
#      group by 1」 에서 **GROUP BY 1 은 첫 출력 칸을 가리키는데 그 칸에 집계함수가
#      들어 있어** PostgreSQL 이 통째로 거절한다("aggregate functions are not
#      allowed in GROUP BY"). 🔴 **같은 꼴이 ④(역할별 사람 수)에도 있었다** —
#      거기는 옆에 따로 센 수가 있어 **✓ 가 떴지만 줄은 비어 있었다**(아무것도 안
#      재는 ✓ 의 실물이다). 🔵 둘 다 **GROUP BY 를 칸 이름으로** 바꿨다.
#      🔴 **운영 DB 에 붙어 확인하지는 못했다**(이 배포본을 쓴 쪽은 DB 에 안 붙는다).
#         ✗ 가 나면 그 자리에서 psql 한 줄로 확인하세요.
#   ⑫ 🔴 **AS_COUNT_TABLES 에 role_permissions 를 되돌려 넣었다.** 60번은 그 표에
#      행을 더하는 판이라 뺐었다. **0128 은 어느 표의 행도 안 건드린다** — 그래서
#      그 표까지 「줄 수가 그대로인가」로 지킨다.
#
#   ── 🔵 **60번과 같아서 안 뒤집은 것 다섯** (그래도 값으로 다시 잰다)
#      · 양식 **0장** · 포털·PO **안 건드린다** · 공유폴더 **안 건드린다**
#      · 되돌리기는 **앱만** 되돌린다(도구는 새 판 그대로)
#      · 안 건드리는 아홉 · DB 둘이 안 멈춘다
#      🔴 같다고 절을 지우지 않았다. 「0장·안 건드림」은 **이번 판에서도 참인지
#         재야** 참이다.
#
#   갈아 끼우는 것 — **저장소 하나, 태그 둘**
#     ① A/S 앱    dss-as:5.2        → **dss-as:5.3**
#     ② A/S 도구  dss-as-tools:19   → **dss-as-tools:20**
#
#   🔵 **안 건드리는 아홉** — 포털 · 재고 · 계측기 · 게시판 · 개선요청 · 휴가 ·
#      통합 승인함 · RF 이슈관리 · PO.
#   🔵 **양식(.xlsx)은 한 장도 안 올린다.** 이번 범위에 .xlsx 변경이 0줄이다.
#      🔴 **양식이 바뀌는 날 되살릴 곳**: 51-deploy.sh 의 1056~1172줄
#         (--templates-prep) · 1174~1341줄(--templates-apply).
#      🔵 다만 **재는 쪽은 남겼다** — 1-ㄷ 절이 운영 양식 열하나를 md5 로 잰다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **--migrate 가 하는 일 — 60번과 정반대다**
# ══════════════════════════════════════════════════════════════════════
#   이번 판은 마이그레이션이 **1건**이다: drizzle/0128_true_havok.sql.
#
#   🔴 **무엇을 하는가** — **표를 하나 만든다.** 문장 셋뿐이다:
#        CREATE TABLE "badge_visibility_settings" (칸 여섯)
#        ALTER TABLE … ADD CONSTRAINT … FOREIGN KEY ("updated_by")
#                      REFERENCES "users"("id") ON DELETE restrict
#        CREATE UNIQUE INDEX "badge_visibility_settings_badge_place_unique"
#                      ON … ("badge_key","place_key")
#      🔴 **INSERT 가 0 이다** — 자료를 한 줄도 안 넣는다. **표는 비어서 나간다.**
#      🔵 빈 표 = 전부 보임이라, 그때 화면은 「정상」 배지가 사라진 것 말고는 지금과 같다.
#
#   🔴 **ON DELETE restrict 가 한 줄 있다.** 이 저장소의 「지우는 문장」 검사가
#      그 글자에 걸려 표만 더하는 판을 ✗ 로 만든 적이 있다. 🔵 이 파일의 잣대는
#      **UPDATE 를 안 넣고 주석을 먼저 걷고 ON DELETE 를 안 센다** — 앱의
#      src/lib/db/migration-safety.ts 와 같은 결론이다([실측 2026-11-13] 그 모듈로
#      0128 을 재면 **destructive: [] · risky: []**).
#      🔴 **표본 넷**으로 잣대가 살아 있는지 **먼저** 잰다.
#
#   🔴 **왜 --go 전에 꼭 돌려야 하는가** — 새 앱의 **[시스템 설정] › [배지 표시]**
#      화면이 그 표를 읽는데, **거기는 「표 없음」을 안 삼킨다**(값을 바꾸러 온
#      화면이라 일부러 그렇다 — queries/badge-visibility-settings.ts 의
#      buildBadgeVisibilityView 주석). 표가 없으면 **그 탭이 그 자리에서 터진다.**
#      🔵 배지를 **그리는** 화면들은 표가 없어도 안 죽는다(42P01 을 삼켜 전부 보임).
#      🔴 그래서 --go 는 **기록이 129 가 아니면 멈춘다.**
#
#   🔴 **묶음(as-migrations.tar.gz)을 보낸다.** 도구 이미지의 /app/drizzle 은
#      **비어 있고**(Dockerfile 의 tools 스테이지가 drizzle/ 을 안 담는다) 운영은
#      거기에 /volume1/dss/as-migrations 를 붙인다. **마이그레이션은 이미지 안이
#      아니라 볼륨에서 돈다** — 묶음을 안 보내면 볼륨이 128 그대로라 적용이 0건으로
#      조용히 끝난다(39·48·53번이 겪었다).
#      🔴 **_images-56 의 묶음(128장)을 보내지 마라** — 0128 이 없다.
#
#   🔴 **되돌리는 법**(이 판을 물릴 때 손으로 돌린다 — 자동으로 안 한다):
#        DROP TABLE IF EXISTS "badge_visibility_settings";
#      🔵 **되돌릴 일이 거의 없다** — 옛 앱은 그 표를 쳐다보지도 않는다. 표가 남아
#         있어도 해롭지 않고, 다시 올릴 때 그대로 쓴다.
#      🔴 drizzle 의 기록(__drizzle_migrations)도 함께 지워야 다시 적용된다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이번 판이 운영에 들고 가는 것 — **커밋 일곱 · 배지를 자리별로 끈다**
# ══════════════════════════════════════════════════════════════════════
#   ① f9c18022 밑바탕 — 표 · 등록부(배지 **15** · 자리 **6** · 쌍 **29**) · 판정
#   ② 07325d51 **[시스템 설정]을 탭 둘로** — [고객 안내 상태 목록] · **[배지 표시]**.
#      저장 · 🔴 **settings 권한에 MANAGE 를 열었다**(관리자 이상).
#      🔴 **읽기는 다섯 역할 전부 그대로**다(permission-baseline.ts 가 read: true 를
#      못으로 박았다) — **아무도 좁아지지 않는다.**
#   ③ f90eec14 수리건 쪽 자리 셋에서 실제로 숨기기 + (app) 레이아웃에 Provider
#   ④ 9e38c0b3 꺼도 아무 일이 안 일어나던 자리 하나를 걷어냄 (자리 7 → 6 · 쌍 33 → 29)
#   ⑤ 2bd9f440 내자 정리·기타건 쪽 자리 셋 + 배지 다섯을 제 파일로
#   ⑥ 7a625589 마지막 보기 배지 하나 (BorrowedSourceNote)
#   ⑦ 70ec2173 🔴 **「정상」 배지 제거** — 지연일 때만 [납기 지연] 하나가 뜬다.
#      🔴 **설정과 무관하게 즉시** 바뀐다 — 배포 직후 눈에 가장 먼저 띄는 자리다.
#
#   🔵 **설정은 안 바꾼다** — 이번 범위에 늘어난 process.env 이름이 0개다.
#   🔵 **공유폴더도 안 건드린다.** 🔴 그래도 1-ㅁ 절은 **그대로 둔다** —
#      한 번 빼면 다시 넣는 사람이 없다(42~60번의 규율).
#
# ── 🔴 알고도 안 고친 것 — PO 가 모르는 것이 **셋**이다 (55번에서 넘어옴) ──
#   ① dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 APPROVAL_REQUIRED 가 없다.
#   ② PO 는 납품일 칸(delivered_date·delivered_by)을 모른다.
#   ③ PO 는 회차 승인(due_date_row_order)을 모른 채 같은 표를 고친다.
#   🔵 **지금은 안전하다** — 운영에서 직원의 PO 접근 권한을 모두 빼 두었다
#      (2026-11-08 사용자). 🔴 **PO 를 다시 여는 날 셋을 한 묶음으로 이식해야 한다.**
#   🔵 **이번 판이 더한 표는 PO 가 안 쓴다** — 넷째가 되지 않는다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **상태 변수를 먼저 정하고 가지를 나눈다** — 48번이 데인 자리다
# ══════════════════════════════════════════════════════════════════════
#   48번에서 --check 의 기대값이 **한 갈래**라 적용 뒤에 다시 부르면 가짜 ✗ 가
#   났다. 그래서 이 파일은 **맨 처음에 운영의 단계(PHASE)를 읽고** 가지를 나눈다.
#     PRE   둘 다 옛 판         → 아직 아무것도 안 갈아 끼웠다
#     POST  둘 다 새 판         → --go 까지 돌았다
#     MID   도구만 새 판        → 🔴 **--migrate 까지 돌았다**가 1순위.
#           🔵 --go 뒤에 --rollback 으로 앱만 되돌린 상태도 여기 보인다 —
#           그 둘은 **DB 기록으로 가른다**(--migrate 를 돌았으면 129 다).
#     ODD   그 밖               → 표를 찍고 사람이 본다 (막지는 않는다)
#   🔴 **마이그레이션 수도 가지를 나눈다 — 128(전) · 129(뒤).**
#   🔴 **그리고 이번 판에는 「표가 있는가」가 가지를 하나 더 나눈다** —
#      PRE 에는 badge_visibility_settings 가 **없는 것이 정상**이고
#      POST 에는 **있는 것이 정상**이다. 한 잣대로 재면 둘 중 하나가 가짜 ✗ 다.
#
# ── 🔴 48~60번에서 그대로 가져온 것 ──────────────────────────────────
#   ① **3xx 판정**(grep -qE '200|30[1237]'). A/S 는 307, PO 는 303 으로 로그인에
#      보낸다. 빠뜨리면 **멀쩡한 사이트가 ✗ 로 나온다**(2026-10-30 실측).
#   ② 🔴 **치환 전에 그 줄의 낱말 수가 2 인지 본다.** 줄 끝에 주석이 붙어 있으면
#      **주석의 마지막 낱말**이 태그로 바뀌고 image: 값은 그대로 남는다.
#   ③ 🔴 **달라진 image: 줄 수를 박지 않는다 — 세어서 정한다.**
#   ④ 🔴 **설정 파일 검사**(중복 키 · auto). 값은 한 글자도 안 찍는다.
#   ⑤ 🔵 연락서 폴더 검사 · 재고 관리 통로 검사 · 발주서/견적서 폴더 검사는
#      **42~60번 것 그대로다.** 🔴 **빼지 않는다** — 한 번 빼면 다시 넣는 사람이 없다.
#   ⑥ 🔵 **--rollback 은 앱만 되돌린다.** 도구는 새 판 그대로 둔다.
#      🔴 **DB 도 자동으로 안 되돌린다** — 0128 은 표를 더하기만 하므로 옛 앱은
#         그 표를 쳐다보지도 않는다.
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
#          🔴 60번의 그 절과 **재는 것이 완전히 다르다.**
#   --preload
#       쓰는 것 : **NAS 의 도커 이미지 저장소**(docker load 로 태그 둘을 싣는다).
#       🔵 실어만 두고 **아직 안 갈아 끼운다.** 싣자마자 **둘 다 안을 센다.**
#   --migrate
#       쓰는 것 : **DB 덤프 한 장** · **compose 사본 한 장** ·
#                 **compose 의 image: 줄 하나**(tools-as 만) ·
#                 **마이그레이션 볼륨**(묶음을 풀어 128 → 129) ·
#                 🔴 **DB 에 표 하나**(badge_visibility_settings · 빈 표).
#       안 쓰는 것: 앱의 image: 줄 · 도는 컨테이너 · 양식 · 공유폴더 ·
#                 🔵 **다른 표의 자료**(0128 은 INSERT 가 0 이다).
#       🔵 **다시 돌려도 안전하다** — drizzle 은 이미 적용한 것을 건너뛴다.
#   --go
#       쓰는 것 : **DB 덤프 한 장** · **compose 사본 한 장** ·
#                 **compose 의 image: 줄**(PRE 면 둘 · MID 면 하나) ·
#                 **app-as 컨테이너를 다시 띄운다**(정지 창 약 25초).
#       안 쓰는 것: 🔴 **DB 의 자료와 스키마**(--migrate 가 이미 했다) ·
#                 마이그레이션 볼륨 · 양식 · 공유폴더 ·
#                 app-po · app-auth · tools-auth 의 image: 줄 · 나머지 아홉 상자.
#       🔴 **기록이 129 가 아니면 멈춘다** — 새 앱의 [배지 표시] 탭이 그 표를 읽는다.
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
#      0128 을 셈에 넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
#   ④ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」
#      같은 안전망을 달면 **하필 바라던 0 에서만** 터진다. 셈은 「$( … || true )」 로 받는다.
#   🔴 그리고 **tar | grep -q 를 if 에 바로 물리지 않는다.** set -uo pipefail
#      아래에서 grep -q 가 찾자마자 끝내면 앞의 tar 가 SIGPIPE 로 죽어,
#      **파일이 있을 때 오히려 ✗** 가 난다(2026-11-07 쉰째 배포에서 실제로 났다).
#      → 묶음을 읽는 자리는 전부 **세어서 담고 비교하는 꼴**(grep -c · grep -o)이다.
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
#   처방(58~60-deploy.sh 가 고쳐 둔 그대로 가져왔다):
#     · 읽자마자 **tr -d 로 \r 를 걷어낸 뒤** 맞댄다.
#     · 「-Fx」 는 **살린다** — 경로 일부만 겹치는 다른 줄에 걸리면 안 된다.
#     · **읽은 줄 수를 함께 받아 너무 적으면 ✗** 로 센다(빈 결과는 삼켜진 오류일
#       수 있다 — 「0건」과 「못 읽었다」는 다른 말이다).
#     · **없는 경로 하나를 일부러 함께 묻는다** — 그 줄이 no 로 안 나오면
#       「무조건 yes」인 검사라는 뜻이고 나머지 yes 도 못 믿는다.
#     · **cat 의 글롭은 set -f 앞에 둔다** — 뒤에 두면 *.txt 가 글자 그대로 남아
#       파일을 한 줄도 못 읽는다.
#   🔵 scripts/test-lists 는 **넷**이다: unit.txt · components.txt · db.txt · db-safety.txt.
#      🔴 **이번 판은 그중 셋을 고쳤다**(60번은 둘이었다).
#   🔴 **괄호가 든 경로가 2개 있다**(60번은 25개였다) — 적지만 글롭 함정이
#      **살아 있다.** 목록은 환경변수로 넘기고 while read 로 받고 큰따옴표로
#      감싸고 set -f 로 글롭을 끈다(넷을 다 지킨다).
#
# ── 🔴 비밀값을 찍지 않는다 ───────────────────────────────────────────
#   설정 파일은 **이름이 있는가/없는가**와 **auto 인가**만 본다. PO 권한 검사는
#   DATABASE_URL 에서 **역할 이름만** 꺼낸다. 🔵 **양식 경로는 찍어도 된다.**
#   🔴 그리고 **한글을 HTTP 머리말·argv 에 넣지 않는다** — 넣으면 요청이 아예 안
#      나가고, 그 ✗ 가 진짜 결함처럼 보인다.
#   🔵 앱 번들의 **한글 표식 셋**만 예외인데, 그것도 argv 로 한글을 넘기지 않는다 —
#      **8진 이스케이프**를 넘기고 컨테이너 안에서 다시 만든다(바이트 수를 먼저 받는다).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **--count 가 세는 것** — 60번과 완전히 다른 자리다
# ══════════════════════════════════════════════════════════════════════
#   🔴 60번은 **권한 행 이사**(domesticOrders 잎 넷)와 **[최종 출하 승인 완료]
#      거르개**를 셌다. **그 수는 이번 판과 상관이 없다.** 그대로 두면 이 배포를
#      재는 숫자가 **하나도 없다** — 그래서 통째로 갈았다.
#
#   ① 🔴 **badge_visibility_settings 표가 있는가 · 몇 줄인가.**
#      🔴 **이것이 이 배포의 목적물이다.** PRE 에는 **표가 없는 것이 정상**이고,
#         --migrate 뒤에는 **있고 0줄인 것이 정상**이다.
#      🔵 **0줄 = 아무도 아무것도 안 껐다 = 화면이 지금과 같다**(「정상」 제거 빼고).
#   ② 🔵 **끈 쌍을 배지별·자리별로** 찍는다. 배포 직후에는 아무것도 안 나온다 —
#      사람이 설정 화면에서 끄기 시작하면 여기 줄이 생긴다.
#   ③ 🔴 **role_permissions 의 settings 행** — 이번 판이 그 영역의 상한을 읽기에서
#      **관리**로 올린다. 🔴 **저장된 행이 있으면 그 역할의 수준이 운영의 답이다**
#      (저장된 칸 값이 코드 기본값을 이긴다). 🔵 행이 없으면 코드 기본값으로 돌고,
#      그 기본값은 **읽기=다섯 역할 전부 · 관리=관리자 이상**이다.
#   ④ 🔵 **역할별 사람 수**(활성 · 휴지통 뺌) — 「시스템 설정 — 관리」가 몇 사람에게
#      열리는가. 🔴 **60번의 이 줄은 SQL 이 깨져 비어 있었다**(아래 ⑥ 와 같은 까닭).
#   ⑤ 🔴 **「정상」 배지가 사라지는 줄 수** — 휴지통을 뺀 수리건 수다.
#      🔴 **지연 판정은 SQL 로 못 베낀다** — 그 함수가 내자 정리에서 날짜를 빌려
#         오는 규칙까지 들고 있다(domain/repair-case-overdue.ts). 🔵 그래서 지연
#         건수는 **위 다섯 도구 중 check:due-date-overdue 가 센 수**를 쓴다.
#         「정상」이 붙던 줄 = 전체 − 지연. 🔴 **여기서 두 수를 곱해 짜 맞추지 않는다.**
#   ⑥ 🔵 **결재 종류별 줄 수** — [최종 출하 승인 완료] 배지가 걸린 자리의 규모다
#      (그 배지는 쌍 29 중 **다섯 자리**를 차지한다 — 가장 많다).
#      🔴 **60번은 여기가 「못 쟀다」로 나왔다.** 까닭은 GROUP BY 1 이다(머리말 ⑪).
#
#   🔴 **전부 select 뿐이다.** 🔴 **--migrate 전후로 ① 이 「없다」에서 「0줄」이 되어야**
#      정상이다. 나머지는 앞뒤가 같아야 한다.
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v57-$STAMP
BKDB=$D/backups/db   # 🔴 덤프가 여기 간다 (48·52·53·55·57~60번과 같은 자리)
# 🔴 **덤프 이름의 판 꼬리표** — 🔵 59번이 여기를 안 고쳐 v54 로 남겼고 60번이 고쳤다.
#    🔴 **BK 와 이 값이 같은 v 번호여야 한다** — 아래 1-ㄱ-0 절이 값으로 확인한다.
DUMP_VER=v57
# ══ 이번에 다시 띄우는 것 — 앱 **하나** ═══════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
#   🔵 60번과 같은 모양이다 — 앱 하나, 도구 하나. **판만 하나씩 올라간다.**
SITES='
as|app-as|dss-as|dss-as:5.3|dss-as:5.2|dss-as-5.3.tar|13000
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
#   🔴 **--migrate 가 이 줄을 먼저 고친다.** 그래서 --go 에서 달라지는 줄은
#      PRE 면 둘 · MID 면 하나다.
AS_TOOLS_SVC=tools-as
AS_TOOLS_OLD=dss-as-tools:19
AS_TOOLS_NEW=dss-as-tools:20
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
# 🔴 열하나 — 이름|바이트|md5. 출처: [실측] **2026-11-11 개발 PC**, 59·60번이 물려받은 값.
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

# ══ 🔴 tar 둘의 지문 — [배포본] 61-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 비어 있다 — 굽기 전에 쓴 파일이다.** 61-build.sh --go 가 꼬리말에
#      찍는 **두 줄**로 아래 두 줄을 통째로 갈아 끼운 **뒤에** scp 하세요.
#   🔴 **이 값을 NAS 에서 재서 채우지 마라.** 그러면 「옮기다 깨졌는가」를 자기가 잰
#      값으로 자기를 재는 꼴이 되어 **영영 통과한다.** 반드시 **구운 쪽**에서 잰다.
#   🔴 비어 있으면 3절이 **--check·--rollback 에서는 ? · --preload·--migrate·--go
#      에서는 ✗** 로 센다. 🔵 막는 것은 **✗ 뿐이다.**
#      🔴 **쉰세째에는 빈 표가 그대로 NAS 로 올라갔고 --preload 가 ✗ 둘로 멈췄다**
#         (2026-11-11). 🔵 61-build.sh 는 그 두 줄을 **세 자리**에서 찍는다.
TARS='
dss-as-5.3.tar|134987776|1280924f8d74cedd0fa0666e61ca53f8|sha256:632eb38546191242c5b380152c3e273ff86e8a8a7fc0a210e15929a2d7b46887
dss-as-tools-20.tar|225588736|c8707b03141b03a09a8365b35143e5f5|sha256:4d655ed0a6a1c08aef124adc2d5b3887ce436b68aeab6e7fdfd4380cfc047f83
'
TARS_WANT=2
# 🔴 **묶음의 잰 값** — 61-build.sh --go 가 찍어 준다 (2026-11-13 17:41 굽기에서 채웠다).
MIGTAR_SIZE=2532210
MIGTAR_MD5=4d2c8376080bd60ce1c105b06526a489

# 🔴 tar 이름 → 태그. **정규식으로 되돌리지 않는다** — 이름마다 손으로 적는다.
#    🔴 dss-as-5.3.tar 은 「끝의 숫자 앞에 콜론」 규칙으로 풀리지 않는다(판에 점이 있다).
tar2tag() {
  case "$1" in
    dss-as-5.3.tar)        printf 'dss-as:5.3' ;;
    dss-as-tools-20.tar)   printf 'dss-as-tools:20' ;;
  esac
}

# ══ 🔴 DB — **이번 판도 앞뒤가 다른 수다** ════════════════════════════
#   🔵 A/S 와 PO 는 **같은 dss_as** 를 본다(PO 는 제 DB 가 없다).
#   🔵 포털은 **dss_auth** 를 따로 본다 — 이번 판에 **한 글자도 안 바꾼다.**
AS_BOX=dss-pg-app;    AS_DB=dss_as
AUTH_BOX=dss-pg-auth; AUTH_DB=dss_auth
# 🔴 **두 갈래다.** 🔴 60번은 127/128 이었다 — 그 수를 그대로 두면 **두 갈래가 다
#    어긋나** 어느 단계에서도 ✗ 가 난다.
AS_MIG_BEFORE=128   # [저장소·운영] 60번이 0127 을 올려 128 이 됐다
AS_MIG_AFTER=129    # [저장소] 이번 판이 0128 을 올린다
AUTH_MIG_KEEP=10    # [README 36번] 포털은 그대로여야 한다
AS_LAST_MIG=0128
AS_NEXT_MIG=0129    # 🔴 셈으로 만들지 않는다(8진수 함정). 글자로 적는다
# 🔵 창이 한 칸 밀렸다 — 60번은 0121~0127 이었다.
AS_KEEP_MIGS='0122 0123 0124 0125 0126 0127 0128'
AS_NEW_MIGS_WANT=1
# 🔴 **지우는 문장 잣대 — 주석을 먼저 걷어낸다.**
#    🔴 **UPDATE 를 잣대에 넣지 마라** — updated_by·updated_at **칸 이름**이 걸린다.
#       🔴 **0128 에도 그 칸 둘이 있다** — 넣었으면 그 자리에서 가짜 ✗ 다.
#    🔴 **ON DELETE 도 안 센다** — 0128 의 FK 구절에 restrict 가 한 줄 있다.
#       🔵 [실측 2026-11-13] 앱의 migration-safety.ts 로 0128 을 재면
#          **destructive: [] · risky: []** 다. 이 정규식도 같은 답이다.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
SQL_COMMENT_RE='^[[:space:]]*--'
MIG_DROP_WANT=0

# ══ 🔴 **이번 판이 만드는 것** — PRE 에 없고 POST 에 있어야 한다 ══════
#   🔴 **60번에는 이 묶음이 없었다** — 그 판의 0127 은 표를 한 칸도 안 바꿨다.
#      그래서 「값으로 확인」이 「옮길 행이 0 이 됐는가」였다. 이번 판은 **실물**이다.
#   🔴 **단계마다 기대값이 다르다** — PRE 0 · POST 1. 한 잣대로 재면 가짜 ✗ 다.
BV_TABLE=badge_visibility_settings
BV_COLS='id badge_key place_key is_visible updated_by updated_at'
BV_COLS_WANT=6
BV_IDX=badge_visibility_settings_badge_place_unique
BV_IDX_COLS_WANT=2
BV_FK=badge_visibility_settings_updated_by_users_id_fk
# 🔵 등록부의 모양 — 도구 이미지 안 검사가 소스에서 다시 센다.
BV_PLACES_WANT=6
BV_BADGES_WANT=15
BV_PAIRS_WANT=29
# 🔵 이번 판이 상한을 올린 권한 영역. --count 의 ③ 이 이 열쇠로 묻는다.
PERM_TABLE=role_permissions
SETTINGS_AREA=settings

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
#    🔴 **role_permissions 를 되돌려 넣었다** — 60번은 그 표에 행을 더하는 판이라
#       뺐었다. **0128 은 어느 표의 행도 안 건드린다**(INSERT 가 0 이다).
#    🔴 **badge_visibility_settings 는 여기 안 넣는다** — PRE 에는 그 표가 없다.
AS_COUNT_TABLES='repair_cases domestic_orders repair_case_approvals shipment_approval_routes procedure_templates users role_permissions'
# 🔴 49번이 올린 기능이 쓰는 표. 1-ㄹ 절이 이 이름으로 권한을 묻는다. **ASCII 다.**
PO_WRITE_TABLE=repair_cases

# ══ 🔵 **안 건드리는 아홉** — 「옆으로 안 샜다」는 증거로 센다 ═════════
KEEP_BOXES="dss-auth dss-inventory dss-meters dss-board dss-improvements dss-leave dss-approvals dss-rf-trouble dss-po"
KEEP_BOXES_WANT=9
KEEP_DB="dss-pg-app dss-pg-auth"

# ══ 🔴 53번 꼬리말에서 넘어온 할 일 둘을 **값으로** 센다 ══════════════
AS_ROUTE_TABLE=shipment_approval_routes
AUTH_MAIL_TABLE=approval_mail_kinds
AUTH_MAIL_CLIENT=rf-service-system

# ══ 🔴 **이번 판이 바꾼 52개** — 도구 이미지 안 검사가 쓴다 ═══════════
#   🔵 src/ **49** + scripts/ **3** = **52**. 🔴 60번은 77 + 2 = 79 였다.
#   🔴 **53 이 아니다** — git 이 세는 「담기는 것」에는 vendor/dss-core 포인터가
#      한 줄 더 있는데, 그 경로의 파일은 **이미지 안에 없다.** 공용 스키마는
#      as_tools_inside_check 의 ⑤ 가 따로 센다.
#   🔴 **괄호가 든 경로가 2개 있다** — 환경변수로 넘기고 while read 로 받고
#      큰따옴표로 감싸고 set -f 로 글롭을 끈다.
AS_CHANGED_SRC='
src/app/(app)/layout.tsx
src/app/(app)/settings/page.tsx
src/components/approvals/FinalShipmentApprovedBadge.tsx
src/components/approvals/final-shipment-approved-badge-screens.test.tsx
src/components/domestic-orders/DomesticOrderListScreen.tsx
src/components/domestic-orders/badge-visibility-screens.test.tsx
src/components/domestic-orders/badges.tsx
src/components/domestic-orders/detail/DomesticOrderDetailHeader.tsx
src/components/domestic-orders/domestic-order-due-date-inversion.test.ts
src/components/domestic-orders/domestic-order-inline-cells.test.ts
src/components/domestic-orders/domestic-order-model-link-screens.test.ts
src/components/misc-cases/MiscCaseStatusBadge.tsx
src/components/misc-cases/misc-case-fields.tsx
src/components/providers/BadgeVisibilityProvider.tsx
src/components/repair-cases/BorrowedSourceNote.tsx
src/components/repair-cases/RepairCaseCardList.tsx
src/components/repair-cases/RepairCaseListPage.tsx
src/components/repair-cases/RepairCaseTable.tsx
src/components/repair-cases/RequestedDueDateValue.tsx
src/components/repair-cases/badge-visibility-screens.test.tsx
src/components/repair-cases/badges.tsx
src/components/repair-cases/borrowed-source-note.test.tsx
src/components/repair-cases/detail/DetailHeader.tsx
src/components/repair-cases/detail/IntakeInfoSection.tsx
src/components/repair-cases/detail/ProductInfoSection.tsx
src/components/repair-cases/detail/product-info-history-disclosure.test.ts
src/components/repair-cases/work-history/ActivityHeaderSummary.tsx
src/components/settings/BadgeVisibilityPanel.tsx
src/components/settings/BadgeVisibilitySettings.tsx
src/components/settings/SettingsTabs.tsx
src/components/settings/badge-samples.tsx
src/components/settings/badge-visibility-draft.test.ts
src/components/settings/badge-visibility-draft.ts
src/components/settings/badge-visibility-panel.test.tsx
src/components/settings/settings-tab-access.test.ts
src/components/settings/settings-tab-access.ts
src/components/users/users-area-gate.test.ts
src/lib/auth/badge-visibility-authorization.ts
src/lib/auth/permission-areas.ts
src/lib/auth/permission-baseline.ts
src/lib/auth/permission-settings-truth.test.ts
src/lib/auth/settings-area-permission.test.ts
src/lib/db/mutations/badge-visibility-settings.integration.test.ts
src/lib/db/mutations/badge-visibility-settings.ts
src/lib/db/queries/badge-visibility-settings.ts
src/lib/domain/badge-visibility.test.ts
src/lib/domain/badge-visibility.ts
src/lib/server/actions/badge-visibility-settings.ts
src/lib/server/badge-visibility.ts
'
AS_CHANGED_SRC_WANT=49
# 🔴 **scripts/ 쪽은 3개다.** 🔴 60번은 2 였다 — 그 목록을 그대로 두면 ✗ 다.
AS_CHANGED_SCRIPTS='
scripts/test-lists/components.txt
scripts/test-lists/db.txt
scripts/test-lists/unit.txt
'
AS_CHANGED_SCRIPTS_WANT=3
AS_CHANGED_ALL_WANT=52
# 🔴 **이번에 새로 생긴 파일은 src/ 24 · drizzle/ 2 = 26개다** — 60번은 20개였다.
AS_BORN_SRC_WANT=24
AS_BORN_ALL_WANT=26
# 🔴 **이번 판이 새로 만든 시험 아홉** — 목록 파일에 등록돼 있어야 한다.
#    🔴 60번은 여덟이었다. 그 여덟 경로를 그대로 두면 **아홉 다 no 가 나와 가짜 ✗** 다.
#    🔵 [실측 2026-11-13] 넷은 components.txt · 넷은 unit.txt · 하나는 **db.txt** 다.
AS_NEW_TESTS='
src/components/domestic-orders/badge-visibility-screens.test.tsx
src/components/repair-cases/badge-visibility-screens.test.tsx
src/components/repair-cases/borrowed-source-note.test.tsx
src/components/settings/badge-visibility-draft.test.ts
src/components/settings/badge-visibility-panel.test.tsx
src/components/settings/settings-tab-access.test.ts
src/lib/auth/settings-area-permission.test.ts
src/lib/db/mutations/badge-visibility-settings.integration.test.ts
src/lib/domain/badge-visibility.test.ts
'
AS_NEW_TESTS_WANT=9
# 🔴 **「무조건 yes」인 검사가 되지 않게** 없는 경로 하나를 함께 묻는다.
REG_PROBE_MISS=src/__dss_probe_not_registered__.test.ts
# 🔴 목록 파일을 **얼마나 읽었나**의 바닥값. [실측 2026-11-13] 네 장을 합쳐
#    **3807줄**(components 1337 · unit 1942 · db 514 · db-safety 14, 빈 줄 뺌).
AS_TESTLIST_MIN_LINES=1000
# 🔵 시험 목록 파일 **넷** — 이번 판은 그중 셋을 고친다. 넷 다 이미지에 있어야 한다.
AS_TESTLIST_FILES='
scripts/test-lists/components.txt
scripts/test-lists/db.txt
scripts/test-lists/db-safety.txt
scripts/test-lists/unit.txt
'
AS_TESTLIST_FILES_WANT=4
# ══ 🔴 **이번 판의 표식 일곱** — 도구 이미지(소스가 글자 그대로 있다)에서 쓴다 ══
#   🔴 60번의 일곱은 **이번 판이 하나도 안 건드린다** — 그대로 두면 **옛 판에서도
#      전부 ✓** 인 죽은 검사가 된다.
#   🔴 전부 **기준판(21e04c16)의 그 파일에 0번 · 지금 판에 1번 이상**이고,
#      **그 커밋의 바로 앞 커밋에도 0번**이다(2026-11-13 실측: 2·2·4·2·3·3·1).
#   🔴 ④ 와 ⑦ 은 **빼는 커밋**이라 더해진 이름이 없다 — **남은 줄의 모양**으로 잡았다.
#   🔵 ③ 은 **괄호가 든 경로**다 — 글롭 함정이 살아 있는 판이라 일부러 거기 두었다.
#   형식: 글자|파일 — 🔴 **전부 ASCII** 라 argv 로 넘겨도 안 깨진다.
AS_MARKS='
BADGE_PLACEMENTS|src/lib/domain/badge-visibility.ts
badgeVisibility|src/components/settings/settings-tab-access.ts
BadgeVisibilityProvider|src/app/(app)/layout.tsx
"repairCaseDetailHeader", "repairCaseDetailBasicInfo"],|src/lib/domain/badge-visibility.ts
miscCaseDetailHeader|src/components/domestic-orders/detail/DomesticOrderDetailHeader.tsx
BorrowedSourceNote|src/components/repair-cases/detail/IntakeInfoSection.tsx
if (!isOverdue) return null;|src/components/repair-cases/badges.tsx
'
AS_MARKS_WANT=7
AS_HEAD_SHORT=70ec2173
AS_BASE_SHORT=21e04c16
# 🔴 **바뀐 49장 중 46장이 새 내용인가** — 「파일이 있다」와 다른 말이다.
#    🔵 [실측 2026-11-13] **기준판 src/ 에 0파일**이다(60번은 10파일이었다).
#    🔴 **49 가 아니라 46 이다** — 셋에는 그 날짜가 없다. 49 로 두면 가짜 ✗ 다.
#    🔴 **앱 번들 표식으로는 못 쓴다** — 주석의 날짜라 번들에서 지워진다.
FRESH_MARK=2026-11-13
AS_FRESH_HIT_WANT=46
# ══ 🔴 **앱 번들에서 쓸 표식** — 🔴 상수·함수 이름으로 재지 않는다 ════════
#   🔴 앱 이미지는 도구와 달리 **번들**이다(소스가 없다). minify 를 거치므로
#      이름이 남는다는 보증이 없다 — 그 이름으로 재면 **멀쩡한 이미지가 ✗** 가 된다.
#   🔵 60번의 실측으로 **권한 열쇠 같은 「코드가 그 글자로 묻는 리터럴」은 minify 를
#      견딘다**는 것이 확인됐다 — 셋 다 그 꼴로 골랐다.
#      · dueDateFromDomesticOrderShort — **배지 열쇠 문자열**이다. 화면이
#        badgeKey="…" 로 묻는다. [실측] 기준판 src/ 0파일 → 지금 6파일.
#   🔴 **60번의 domesticOrders.view 를 여기 쓸 수 없다** — 기준판 src/ 에 17파일 있다.
#      🔵 그래서 그것을 **뒷걸음 방지 ④** 로 돌렸다.
#   🔴 **번들에서 세어 본 적이 없다** — 개발 PC 에 .next/standalone 이 없다.
#      그래서 수를 박지 않고 **「합이 1 이상」으로만** 잰다. ✗ 가 나면 검사부터 의심한다.
APP_MARK=dueDateFromDomesticOrderShort
# 🔴 앱 번들의 **한글** 표식 ① — [시스템 설정]의 **새 탭 이름**이다.
#    🔴 **명령에 한글을 넣지 않는다.** 8진 이스케이프를 넘기고 컨테이너 안에서
#       다시 만든다. **바이트 수(13)를 먼저 받아** 가르고, 13 이 아니면 ✗ 가 아니라 ⚠️ 다.
#    🔵 [실측 2026-11-13] 13바이트 · 기준판 src/ 0파일 · 지금 41파일.
APP_MARK_KO_OCT='\353\260\260\354\247\200 \355\221\234\354\213\234'
APP_MARK_KO_BYTES=13
# 🔴 앱 번들의 한글 표식 ② — **마지막 커밋(⑦)이 넣은 등록부 설명 문구**다.
#    🔴 그 커밋이 한 일은 「정상」 알약을 **빼는 것**이라, 번들에서 그 커밋을 가리는
#       **유일한 양성 증거**가 이 글자다. 없으면 **「정상」이 아직 뜨는 판**이다.
#    🔵 [실측 2026-11-13] 53바이트 · 기준판 0파일 · 바로 앞 커밋 0파일 · 지금 1파일.
APP_MARK2_KO_OCT='\354\247\200\354\227\260\354\235\264 \354\225\204\353\213\214 \352\261\264\354\227\220\353\212\224 \354\225\204\353\254\264\352\262\203\353\217\204 \354\225\210 \353\234\271\353\213\210\353\213\244'
APP_MARK2_KO_BYTES=53
# 🔵 **뒷걸음 방지 — 🔴 이번 판에서 셋 → 넷이 됐다.**
#      · status=IN_HOUSE      — **쉰네째(58번)**가 올린 글자. [실측] src/ 5 → 5
#      · no-equipment-key     — **쉰세째(57번)**가 올린 글자. [실측] src/ 8 → 8
#      · domesticOrders.view  — 🔴 **쉰여섯째(60번)**가 올린 글자. [실측] src/ 17 → 17
#        **이번에 보탠 자리다** — 60번의 앱 번들 표식이 그대로 내려왔다.
#    🔴 **하나도 빼지 마라** — 뺀 자리는 다시 넣는 사람이 없다.
APP_KEEP_MARKS='
status=IN_HOUSE
no-equipment-key
domesticOrders.view
'
APP_KEEP_MARKS_WANT=3
# 🔴 뒷걸음 방지 ③(한글) — **쉰다섯째(59번)가 올린 글자.** [실측] 47바이트 · src/ 1 → 1.
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
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --count · --preload · --migrate · --go · --rollback\n   🔵 --migrate 는 이 판에 **있습니다**(마이그레이션 1건 — 표를 하나 만듭니다).\n' "$1"; exit 2 ;;
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
LOG="$D/setup/logs/61-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "쉰일곱째 배포 (파일 번호 61) — A/S 앱·도구 (양식 0장 · **마이그레이션 1건 · 표를 하나 만든다** · 포털·PO 안 건드림)   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  🔵 회차(쉰일곱째)와 파일 번호(61)가 어긋나는 것은 이 저장소에서 원래 그렇다 — 58번이 쉰네째 · 59번이 쉰다섯째 · 60번이 쉰여섯째였다."
printf '%s\n' "  🔵 판은 **5.2 → 5.3** 로 하나 늡니다. 도구는 19 → 20."
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  🔴 개발 PC 의 Get-FileHash 값과 **같은지 눈으로 맞대세요** (DSM 터미널이 긴 것을 잘라 먹습니다)"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  로그: $LOG"
printf '%s\n' "  🔴 차례: --check → --count → (scp tar **둘** + **묶음 하나**) → --preload → --check → **--migrate** → --go → --count"
printf '%s\n' "  🔴 **마이그레이션 1건** — drizzle/${AS_LAST_MIG}_true_havok.sql."
printf '%s\n' "     🔴 **0128 은 표를 하나 만듭니다**(badge_visibility_settings) — 60번의 0127 과 하는 일이 정반대입니다."
printf '%s\n' "     🔴 **INSERT 가 0 입니다** — 자료를 한 줄도 안 넣습니다. **표는 비어서 나갑니다.**"
printf '%s\n' "     🔴 **묶음(as-migrations.tar.gz)을 반드시 보냅니다** — 마이그레이션은 이미지 안이"
printf '%s\n' "        아니라 **볼륨에서** 돕니다. 안 보내면 적용이 0건으로 조용히 끝납니다."
printf '%s\n' "     🔴 **--migrate 를 건너뛰면 [시스템 설정] › [배지 표시] 탭이 그 자리에서 터집니다** —"
printf '%s\n' "        그 화면만은 「표 없음」을 안 삼킵니다(값을 바꾸러 온 화면이라 일부러 그렇습니다)."
printf '%s\n' "  🔵 포털·PO 는 **안 건드립니다** — 7절이 「그대로 도는가」만 봅니다"
printf '%s\n' "  🔴 이번 판이 바꾸는 것: **배지를 자리별로 끄는 설정**(배지 15 · 자리 6 · 쌍 29) ·"
printf '%s\n' "     [시스템 설정]이 탭 둘로 · settings 권한에 **관리**가 열림 · **「정상」 배지 제거**."
printf '%s\n' "     🔵 읽기 권한은 **다섯 역할 전부 그대로**입니다 — 아무도 좁아지지 않습니다."
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
# ══ 🔴 마이그레이션 헬퍼 — 53·55·60번 것을 그대로 가져왔다 ════════════
has_table()  { pgn "$1" "$2" "select count(*) from information_schema.tables where table_schema='public' and table_name='$3'"; }
has_column() { pgn "$1" "$2" "select count(*) from information_schema.columns where table_schema='public' and table_name='$3' and column_name='$4'"; }
has_index()  { pgn "$1" "$2" "select count(*) from pg_indexes where schemaname='public' and indexname='$3'"; }
# 🔴 제약은 pg_indexes 에 없다 — pg_constraint 로 묻는다. CHECK 도 외래키도 여기 있다.
has_constraint() { pgn "$1" "$2" "select count(*) from pg_constraint where conname='$3'"; }
# 🔴 enum 값은 표도 칸도 아니다 — pg_enum 으로 묻는다.
has_enum_value() { pgn "$1" "$2" "select count(*) from pg_enum e join pg_type t on t.oid=e.enumtypid where t.typname='$3' and e.enumlabel='$4'"; }
# 🔴 **인덱스의 칸 수.** 0126 이 0124 의 유니크 인덱스를 **같은 이름으로** 다시
#    만들었다 — 「있는가」로는 못 가르고 **칸 수**로 가른다.
#    🔴 **이번 판의 새 인덱스도 같은 잣대로 잰다**(칸 2 — badge_key · place_key).
index_cols() { pgn "$1" "$2" "select coalesce(max(i.indnkeyatts),0) from pg_index i join pg_class c on c.oid=i.indexrelid where c.relname='$3'"; }

# ══ 🔴 **이번 판이 만드는 표를 재는 자리** — --migrate 도 --count 도 쓴다 ══
#   🔴 **표가 없으면 「0줄」이 아니라 「없다」다.** 그 둘을 가르지 않으면
#      PRE 에서 「0줄이니 정상」으로 읽히고, --migrate 가 제 일을 했는지 영영 모른다.
bv_table_exists() { has_table "$AS_BOX" "$AS_DB" "$BV_TABLE"; }
bv_rows() { pgn "$AS_BOX" "$AS_DB" "select count(*) from $BV_TABLE"; }

# 🔴 **볼륨**을 읽는다 — 마이그레이션은 이미지 안이 아니라 여기서 돈다.
#    🔵 가지가 셋이다: DONE(129 · 묶음을 풀었다) · OLD(128 · 아직이다) · ODD(그 밖).
#    🔴 60번은 DONE 이 128 이고 OLD 가 127 이었다 — 그 수를 그대로 두면
#       **128 이 DONE 으로 읽혀 묶음을 영영 안 푼다.**
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
#   🔴 운영 볼륨이 지금 128 이고 0128 이 묶음 안에만 있다.
#   🔵 옛 폴더는 **지우지 않고 .old 로 치워 둔다** — 그것이 되돌릴 길이다.
place_migs() {
  if [ ! -s "$MIGTAR" ]; then
    bad "🔴 볼륨을 $AS_MIG_AFTER 로 올려야 하는데 묶음이 없다: $MIGTAR"
    say "🔴 **이번 판은 묶음이 필수다** — 0128 이 그 안에만 있다."
    say "🔵 61-build.sh --go 가 만든 as-migrations.tar.gz 를 $INCOMING 로 보내세요."
    cmd "scp -O as-migrations.tar.gz dss-nas:$INCOMING/"
    say "🔴 **_images-56 의 묶음(128장)을 보내지 마세요** — 0128 이 없습니다."
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

# 🔴 0122~0128 이 **아직 온전한가** + 0129 가 없는가 + 지우는 문장 0 + 0128 의 속.
#    🔴 **주석을 먼저 걷어낸다** — 0127 의 머리말에 되돌리는 법으로 DELETE 한
#       문장이 적혀 있어, 날것으로 세면 1줄이 나온다.
#    🔴 **UPDATE 를 잣대에 넣지 않는다** · **ON DELETE 도 안 센다**(0128 에 한 줄 있다).
check_keep_migs() {
  local t miss="" f n rc=0 c craw
  for t in $AS_KEEP_MIGS; do
    ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || miss="$miss $t(sql)"
    [ -f "$MIGDIR/meta/${t}_snapshot.json" ]   || miss="$miss $t(snapshot)"
  done
  if [ -z "$miss" ]; then ok "0122~0128 의 .sql 과 meta/*_snapshot.json 이 다 있다 (0128 포함)"
  else bad "🔴 빠진 것:$miss"; rc=1; fi
  # 🔴 0129 는 없어야 한다. 글자로 맞댄다(8진수 함정).
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
    bad "🔴 ON DELETE 를 지우는 문장으로 센다 — **0128 이 그 한 줄 때문에 가짜 ✗ 를 받는다**"; rc=1
  else
    ok "ON DELETE restrict 는 지우는 문장으로 안 센다 (앱의 migration-safety 와 같은 잣대다)"
  fi
  if [ "$(printf '%s\n' '--     DELETE FROM "role_permissions"' | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)" != "0" ]; then
    bad "🔴 **주석을 안 걷어낸다** — 0127 이 제 머리말(되돌리는 법) 때문에 가짜 ✗ 를 받는다"; rc=1
  else
    ok "주석 속 DELETE 는 안 센다 (0127 의 되돌리는 법이 가짜 ✗ 를 안 만든다)"
  fi
  if [ "$(printf '%s\n' '       "updated_by",' | grep -ciE "$DESTRUCTIVE_RE" || true)" != "0" ]; then
    bad "🔴 updated_by 같은 **칸 이름**을 지우는 문장으로 센다 — 0128 에도 그 칸이 있다"; rc=1
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
    ok "0122~0128 에 지우는 문장이 ${n}줄이다 (기대 ${MIG_DROP_WANT}줄 — 더하기만 한다)"
    say "🔵 0127 은 **날것으로 세면 1줄**이 나옵니다 — 제 머리말에 적힌 되돌리는 법입니다."
  else
    bad "🔴 0122~0128 에 지우는 문장이 ${n}줄이다 (기대 ${MIG_DROP_WANT}줄) — 고치지 말고 **먼저 알리세요**"
    rc=1
  fi
  # 🔴 **0128 의 속을 본다** — 「이름이 맞다」와 「그 내용이다」는 다른 말이다.
  #    🔴 60번은 여기가 「INSERT 4 · ON CONFLICT 4 · ALTER 0 · CREATE 0」이었다.
  #       **이번 판은 그 넷이 전부 뒤집힌다.**
  f=$(ls -1 "$MIGDIR/${AS_LAST_MIG}_"*.sql 2>/dev/null | head -1)
  if [ -n "${f:-}" ]; then
    local body ct alt addc uidx ins colok colseen cn c2 nmok nmseen nm
    body=$(grep -v "$SQL_COMMENT_RE" "$f" 2>/dev/null)
    ct=$(printf '%s\n' "$body" | grep -c 'CREATE TABLE' || true)
    alt=$(printf '%s\n' "$body" | grep -c 'ALTER TABLE' || true)
    addc=$(printf '%s\n' "$body" | grep -c 'ADD CONSTRAINT' || true)
    uidx=$(printf '%s\n' "$body" | grep -c 'CREATE UNIQUE INDEX' || true)
    ins=$(printf '%s\n' "$body" | grep -c 'INSERT INTO' || true)
    say "$AS_LAST_MIG (주석 걷은 뒤) — CREATE TABLE ${ct:-0} · ALTER ${alt:-0} · ADD CONSTRAINT ${addc:-0} · UNIQUE INDEX ${uidx:-0} · INSERT ${ins:-0} (기대 1·1·1·1·0)"
    if [ "${ct:-0}" = "1" ] && [ "${alt:-0}" = "1" ] && [ "${addc:-0}" = "1" ] \
       && [ "${uidx:-0}" = "1" ] && [ "${ins:-1}" = "0" ]; then
      ok "$AS_LAST_MIG 이 **표 하나 · FK 하나 · 유니크 인덱스 하나**다 (INSERT 0 — 자료를 안 건드린다)"
    else
      bad "🔴 $AS_LAST_MIG 의 생김새가 기대와 다르다 — **자료를 건드리는 판일 수 있다.** 멈추고 알리세요"
      rc=1
    fi
    colok=0; colseen=0
    for cn in $BV_COLS; do
      colseen=$((colseen+1))
      c2=$(printf '%s\n' "$body" | grep -cF "\"$cn\"" || true)
      printf '      칸 %-12s %s번\n' "$cn" "${c2:-0}"
      if [ "${c2:-0}" -ge 1 ] 2>/dev/null; then colok=$((colok+1)); fi
    done
    nmok=0; nmseen=0
    for nm in "$BV_TABLE" "$BV_IDX" "$BV_FK"; do
      nmseen=$((nmseen+1))
      c2=$(printf '%s\n' "$body" | grep -cF "$nm" || true)
      printf '      이름 %-52s %s번\n' "$nm" "${c2:-0}"
      if [ "${c2:-0}" -ge 1 ] 2>/dev/null; then nmok=$((nmok+1)); fi
    done
    if [ "$colseen" = "$BV_COLS_WANT" ] && [ "$colok" = "$BV_COLS_WANT" ] && [ "$nmseen" = "3" ] && [ "$nmok" = "3" ]; then
      ok "$AS_LAST_MIG 이 칸 ${BV_COLS_WANT}개와 이름 셋(표·유니크 인덱스·FK)을 다 적는다"
      say "🔴 아래 --migrate 가 **그 셋을 DB 에서 다시 찾아** 적용을 확인합니다 — 기록 수만 믿지 않습니다."
    else
      bad "🔴 칸이 ${colok}/${BV_COLS_WANT} · 이름이 ${nmok}/3 개만 적혀 있다"
      rc=1
    fi
  else
    hm "$AS_LAST_MIG 의 .sql 을 못 찾았다 — 위 줄을 보세요"
  fi
  return $rc
}

# ══ 🔴 덤프 — **이번 판에도 진짜 되돌릴 길이다** ══════════════════════
#   🔴 --migrate 가 **스키마를 바꾼다**(표를 하나 만든다). 자료는 안 건드리지만,
#      바꾸기 직전의 사진은 그래도 필요하다.
#   🔵 **포털 DB 는 안 뜬다** — 이 배포가 dss_auth 를 한 글자도 안 바꾸고
#      야간 백업이 매일 받는다.
#   🔴 「파일이 생겼다」와 「쓸 만한 덤프다」는 다르다. 크기와 머리 다섯 글자를 본다.
#   🔴 **이름의 판 꼬리표가 $DUMP_VER 다** — 1-ㄱ-0 절이 BK 와 맞대어 본다.
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
  say "🔵 **0128 은 표를 더하기만 한다** — 되돌릴 일이 생기면"
  say "   DROP TABLE IF EXISTS \"$BV_TABLE\"; 한 문장이 더 빠르고 안전하다."
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
#   🔴 **이번 판을 실제로 재는 것은 다섯이다**: 바뀐 **52개**가 담겼는가 ·
#      그 49장 중 **46장이 새 내용**인가 · **새 시험 아홉**이 등록돼 있는가 ·
#      이번 판의 **표식 일곱**이 있는가(일곱 커밋을 덮는다) ·
#      🔴 **새 공용 스키마**가 담겼는가(dss-core 가 움직인 판이다).
as_tools_inside_check() {
  local v got seen c nmiss nwrite ntx nok probe lines
  printf '\n    ── %s 안을 센다 (겉이 아니라 결과 · 🔵 소스가 **글자 그대로** 있다)\n' "$AS_TOOLS_NEW"
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/package.json: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "A/S tools 스테이지가 맞다" \
    || { bad "🔴 /app/package.json 이 없다 — **runner 를 구웠다.**"; doubt; }
  # ② 🔴 운영에서 불릴 npm 명령 **아홉**.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync check-due-date-overdue check-delivered-date-sync procedures:export procedures:import db:preflight db:migrate; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  [ "${got:-0}" = "9" ] && ok "npm 명령 아홉이 이미지 안에 있다 (🔴 db:migrate 도 있다 — --migrate 가 선다)" \
    || { bad "🔴 명령이 ${got:-0}/9 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다**"; doubt; }
  # ③ 🔴 **이번 판이 바꾼 52개가 담겼는가.** 🔴 60번은 79개였다.
  #    🔵 목록에 **괄호가 2개** 있다 — set -f · 환경변수 · while read · 큰따옴표.
  v=$("$DOCKER" run --rm -e DSS_FILES="$AS_CHANGED_SRC$AS_CHANGED_SCRIPTS" --entrypoint sh "$AS_TOOLS_NEW" -c 'set -f; printf "%s\n" "$DSS_FILES" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | grep '^no  ' | sed 's/^/      /'
  printf '%s\n' "$v" | grep '^yes ' | head -3 | sed 's/^/      (보기) /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  seen=$(printf '%s\n' "$v" | grep -cE '^(yes|no ) ' || true)
  say "본 것 ${seen:-0}개 · 있는 것 ${got:-0}개 (기대 $AS_CHANGED_ALL_WANT · $AS_CHANGED_ALL_WANT — src/ $AS_CHANGED_SRC_WANT + scripts/ $AS_CHANGED_SCRIPTS_WANT)"
  if [ "${seen:-0}" = "$AS_CHANGED_ALL_WANT" ] && [ "${got:-0}" = "$AS_CHANGED_ALL_WANT" ]; then
    ok "이번 판이 바꾼 $AS_CHANGED_ALL_WANT 개가 다 담겼다 (**표본이 비지 않았다** · 괄호 경로도 그대로 읽혔다)"
    say "🔵 **53 이 아니라 52 입니다** — vendor/dss-core 는 포인터 한 줄이라 그 경로의 파일이 없습니다."
    say "   공용 스키마는 아래 ⑤ 가 따로 셉니다."
  else
    bad "🔴 본 것 ${seen:-0} · 있는 것 ${got:-0} 다 — ${AS_CHANGED_ALL_WANT}/${AS_CHANGED_ALL_WANT} 을 기대했다"
    say "🔴 본 것이 모자라면 **목록을 넘기는 길이 끊긴 것**(글롭 함정)이고,"
    say "   있는 것만 모자라면 **옛 소스가 담긴 이미지**입니다."
    doubt
  fi
  # ③-ㄴ 🔴 **그 49장 중 46장이 새 내용인가** — 날짜 글자로 덮는다.
  #    🔴 **49 가 아니다** — 셋에는 그 날짜가 없다(61-build.sh 의 AS_FRESH_MISS).
  #    🔴 **없는 경로 하나를 함께 묻는다** — 「무조건 yes」가 아닌지 가른다.
  v=$("$DOCKER" run --rm -e DSS_FILES="$AS_CHANGED_SRC" -e M="$FRESH_MARK" --entrypoint sh "$AS_TOOLS_NEW" -c 'set -f; printf "%s\n%s\n" "$DSS_FILES" "src/__dss_probe_no_such_file__.ts" | while IFS= read -r f; do [ -n "$f" ] || continue; if grep -qF -- "$M" "/app/$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | grep '^no  ' | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  probe=$(printf '%s\n' "$v" | grep -c '^no  src/__dss_probe_no_such_file__' || true)
  say "새 내용 — $FRESH_MARK 가 든 파일 ${got:-0}개 (기대 $AS_FRESH_HIT_WANT · 🔴 49 가 아니다 · 없는 경로 하나는 no 여야 한다)"
  if [ "${probe:-0}" != "1" ]; then
    bad "🔴 **없는 경로가 no 로 안 나왔다** — 「무조건 yes」인 검사다. 위 yes 도 못 믿는다"
    doubt
  elif [ "${got:-0}" = "$AS_FRESH_HIT_WANT" ]; then
    ok "바뀐 ${AS_CHANGED_SRC_WANT}장 중 ${AS_FRESH_HIT_WANT}장이 **새 내용**이다 (나머지 셋은 그 날짜를 안 적은 장이다)"
    say "🔵 이번 판은 **새로 생긴 파일이 ${AS_BORN_SRC_WANT}장**입니다(60번은 18장이었습니다)."
  else
    bad "🔴 새 내용인 것이 ${got:-0}/${AS_FRESH_HIT_WANT} 장이다 — **옛 소스가 담긴 이미지일 수 있다.** 올리지 마세요"
    doubt
  fi
  # ③-ㄷ 🔴 **새 시험 아홉이 이미지 안의 목록 파일에 등록돼 있는가.**
  #    🔴 **목록 파일은 CRLF 다** — tr -d 로 \r 를 걷어낸 뒤 -Fx 로 맞댄다.
  #    🔴 **읽은 줄 수를 함께 받아 너무 적으면 ✗** · **없는 경로 하나를 함께 묻는다.**
  #    🔴 **cat 의 글롭은 set -f 앞에** 둔다 — 뒤에 두면 *.txt 가 글자 그대로 남는다.
  v=$("$DOCKER" run --rm -e DSS_TESTS="$AS_NEW_TESTS" -e DSS_MISS="$REG_PROBE_MISS" --entrypoint sh "$AS_TOOLS_NEW" -c 'L=$(cat /app/scripts/test-lists/*.txt 2>/dev/null | tr -d "\r"); echo "lines $(printf "%s\n" "$L" | grep -c .)"; set -f; printf "%s\n%s\n" "$DSS_TESTS" "$DSS_MISS" | while IFS= read -r t; do [ -n "$t" ] || continue; n=$(printf "%s\n" "$L" | grep -cFx -- "$t"); if [ "${n:-0}" -ge 1 ]; then echo "yes $t"; else echo "no  $t"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  probe=$(printf '%s\n' "$v" | grep -c "^no  $REG_PROBE_MISS" || true)
  lines=$(printf '%s\n' "$v" | sed -n 's/^lines //p')
  say "\\r 를 걷어내고 읽은 목록 줄 수: ${lines:-?}개 (기대 $AS_TESTLIST_MIN_LINES 이상 · 개발 PC 실측 3807)"
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
  # ③-ㅁ 🔴 **이 파일이 든 「바뀐 목록」에 scripts/ 가 정말 3줄인가.**
  #    🔴 **60번은 2 였다.** 먼저 **세는 길이 살아 있는지** 가짜 목록으로 확인하고,
  #       그 다음에 이 파일의 목록이 3줄인지 본다.
  probe=$(printf '%s\n' 'src/lib/x.ts' 'scripts/test-lists/unit.txt' 'package.json' | grep -c '^scripts/' || true)
  c=$(printf '%s\n' "$AS_CHANGED_SCRIPTS" | grep -c '^scripts/' || true)
  say "표본 — 가짜 목록 세 줄에서 scripts/ 로 시작하는 줄 ${probe:-?}개 (기대 1)"
  say "이 파일이 든 scripts/ 변경 목록: ${c:-0}줄 (기대 $AS_CHANGED_SCRIPTS_WANT — 🔴 60번은 2 였다)"
  if [ "${probe:-0}" != "1" ]; then
    bad "🔴 scripts/ 를 세는 길이 죽었다 — 아래 수가 공짜 통과다"
    doubt
  elif [ "${c:-x}" = "$AS_CHANGED_SCRIPTS_WANT" ]; then
    ok "이번 판이 바꾼 scripts/ 파일이 ${AS_CHANGED_SCRIPTS_WANT}개다 (**시험 목록 셋을 고쳐 올렸다**)"
    say "🔵 그것이 **새 시험이 아홉 장**인 것과 앞뒤가 맞습니다 — 등록할 자리가 셋이었습니다."
  else
    bad "🔴 scripts/ 변경이 ${c:-?}줄이다 — ${AS_CHANGED_SCRIPTS_WANT}줄을 기대했다. 이 파일의 목록을 보세요"
    doubt
  fi
  # ④ 🔴 **그 안에 이번 판의 글자가 있는가** — 표식 일곱(일곱 커밋을 덮는다).
  #    🔴 60번의 일곱은 **이번 판이 하나도 안 건드린다** — 그대로 두면 옛 판에서도 ✓ 다.
  v=$("$DOCKER" run --rm -e DSS_MARKS="$AS_MARKS" --entrypoint sh "$AS_TOOLS_NEW" -c 'set -f; printf "%s\n" "$DSS_MARKS" | while IFS= read -r pair; do [ -n "$pair" ] || continue; m=${pair%%|*}; f=${pair#*|}; if grep -qF -- "$m" "/app/$f" 2>/dev/null; then echo "yes $m $f"; else echo "no  $m $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  seen=$(printf '%s\n' "$v" | grep -cE '^(yes|no ) ' || true)
  say "표식 — 본 것 ${seen:-0}개 · 있는 것 ${got:-0}개 (기대 $AS_MARKS_WANT · $AS_MARKS_WANT)"
  if [ "${seen:-0}" = "$AS_MARKS_WANT" ] && [ "${got:-0}" = "$AS_MARKS_WANT" ]; then
    ok "이번 판의 표식 $AS_MARKS_WANT 개가 이미지 안에 있다 (**일곱 커밋이 다 담겼다**)"
    say "🔵 일곱 다 **기준판 $AS_BASE_SHORT 에는 0번**이고 이번 일곱 커밋이 하나씩 넣은 글자입니다."
    say "🔴 넷째·일곱째는 **빼는 커밋**이라 「남은 줄의 모양」으로 잡았습니다."
  else
    bad "🔴 본 것 ${seen:-0} · 있는 것 ${got:-0} 다 — **커밋 하나가 빠진 판일 수 있다.** 올리지 마세요"
    doubt
  fi
  # ④-ㄴ 🔴 **등록부의 모양을 수로도 잰다** — 자리 6 · 배지 15 · 걷어낸 자리 0.
  #    🔴 넷째 커밋이 자리를 일곱에서 여섯으로 줄인 판이다. 그 결과를 **수**로 본다.
  #    🔵 **쌍 29 는 여기서 안 센다** — 그러려면 BADGES 블록만 떼어 내는 awk 가 필요하고,
  #       그 awk 를 sh -c 안에 넣으면 따옴표가 세 겹이 되어 **깨져도 조용히 0** 이 된다.
  #       쌍 29 는 **61-build.sh 가 호스트에서** 잰다(거기는 따옴표가 한 겹이다).
  #    🔴 그리고 **빈 답은 ✗ 가 아니라 ⚠️ 다** — 못 잰 것과 틀린 것은 다른 말이다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'f=/app/src/lib/domain/badge-visibility.ts; if [ ! -f "$f" ]; then echo "miss=1"; else echo "miss=0"; echo "places=$(grep -c "^  { key: " "$f")"; echo "badges=$(grep -c "^    key: " "$f")"; echo "gone=$(grep -c repairCaseDetailWorkHistory "$f")"; fi' 2>/dev/null | tr -d ' \r')
  printf '%s\n' "$v" | sed 's/^/      /'
  c=$(printf '%s\n' "$v" | sed -n 's/^miss=//p')
  if [ -z "${v:-}" ] || [ -z "${c:-}" ]; then
    hm "등록부의 모양을 **못 쟀다** — 컨테이너가 아무것도 안 돌려줬다. 사람이 보세요"
  elif [ "${c:-1}" != "0" ]; then
    bad "🔴 이미지에 등록부(badge-visibility.ts)가 **없다** — src/ 가 온전히 안 담겼다"; doubt
  else
    local np nb ng
    np=$(printf '%s\n' "$v" | sed -n 's/^places=//p')
    nb=$(printf '%s\n' "$v" | sed -n 's/^badges=//p')
    ng=$(printf '%s\n' "$v" | sed -n 's/^gone=//p')
    say "자리 ${np:-?} (기대 $BV_PLACES_WANT) · 배지 ${nb:-?} (기대 $BV_BADGES_WANT) · 걷어낸 자리 ${ng:-?}번 (기대 0)"
    if [ "${np:-x}" = "$BV_PLACES_WANT" ] && [ "${nb:-x}" = "$BV_BADGES_WANT" ] && [ "${ng:-1}" = "0" ]; then
      ok "등록부가 **배지 $BV_BADGES_WANT · 자리 $BV_PLACES_WANT** 이고 걷어낸 자리가 0번이다 (넷째 커밋까지 담겼다)"
      say "🔵 그 둘에서 나오는 쌍이 **$BV_PAIRS_WANT 개**이고, 그것이 설정 화면의 체크상자 총수입니다."
      say "   🔵 쌍 수 자체는 61-build.sh 가 굽기 전에 호스트에서 셌습니다."
    else
      bad "🔴 등록부가 자리 ${np:-?} · 배지 ${nb:-?} · 걷어낸 자리 ${ng:-?}번 이다"
      say "🔴 꼬리말의 「체크상자 ${BV_PAIRS_WANT}개」도 함께 틀립니다. 사람이 보세요."
      doubt
    fi
  fi
  # ⑤ 🔴 **공용 스키마가 담겼는가 — 그리고 이번 판의 새 표가 있는가**
  #    🔴 **이번 판에서 가장 중요한 줄이다** — dss-core 가 여섯 판 만에 움직였다.
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
  # ⑤-ㄴ 🔴 **새 스키마 파일 + index 내보내기 + 쉰두째의 칸 셋** = 다섯.
  #    🔴 60번은 셋이었다(칸 셋). **둘을 보탰다** — 이번 판이 공용 스키마를 바꿨다.
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c 'for pair in "badge_visibility_settings /app/vendor/dss-core/src/schema/badge-visibility-settings.ts" "badge-visibility-settings /app/vendor/dss-core/src/schema/index.ts" "delivered_date /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "completed_at /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "due_date_row_order /app/vendor/dss-core/src/schema/repair-case-approvals.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  if [ "${got:-0}" = "5" ]; then
    ok "**이번 판의 새 공용 스키마**가 담겼고(표 + index 내보내기) 쉰두째의 칸 셋도 그대로다"
    say "🔵 index.ts 가 안 내보내면 도구가 @dss/core/schema 에서 그 표를 **못 찾습니다** —"
    say "   2026-09-21 에 운영에서 도구가 전부 죽은 그 자리입니다."
    say "🔴 **옛 공용 스키마가 담기면 db:migrate 가 새 표를 모른 채 돕니다.**"
  else
    bad "🔴 다섯 중 ${got:-0}개만 있다 — **옛 공용 스키마가 담겼다.** 올리지 마세요"; doubt
  fi
  # ⑥ 🔴 **drizzle-kit 이 있는가** — 🔴 이번 판은 **실제로 db:migrate 를 부른다.**
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
  v=$("$DOCKER" run --rm --entrypoint sh "$AS_TOOLS_NEW" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
  say "/app/drizzle 안 .sql: ${v:-?}개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)"
  if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then ok "이미지 안 drizzle/ 이 비어 있다 (🔴 그래서 0128 은 **볼륨으로** 가야 한다)"
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
  # ② 🔴 이번 판의 글자(ASCII) — **배지 열쇠 문자열**이다.
  #    🔴 60번의 domesticOrders.view 는 **못 쓴다** — 기준판 src/ 에 17파일 있다.
  #       🔵 그것은 아래 ④ 의 뒷걸음 방지로 내려갔다.
  v=$("$DOCKER" run --rm -e M="$APP_MARK" --entrypoint sh "$tag" -c 'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  a=$(printf '%s' "$v" | awk '{print $1}'); b=$(printf '%s' "$v" | awk '{print $2}')
  say "$APP_MARK 가 든 파일 — .next/server ${a:-?}개 · .next/static ${b:-?}개 (🔴 합이 1 이상이어야 한다)"
  if isnum "${a:-}" && isnum "${b:-}" && [ "$((a + b))" -ge 1 ]; then
    ok "번들에 이번 판의 글자가 있다 (옛 판이 아니다 — 배지 설정이 든 판이다)"
    say "🔵 소스에서는 기준판 0파일 → 지금 6파일입니다(2026-11-13 실측)."
  else
    bad "🔴 번들에 $APP_MARK 가 없다 — **옛 판을 실었다.** 갈아 끼우지 마세요"
    say "🔵 **검사 자신도 의심하세요** — 이 글자는 소스에서만 세어 보았고"
    say "   **번들에서 세어 본 적이 없습니다**(개발 PC 에 standalone 이 없습니다)."
    doubt
  fi
  # ③ 🔴 **한글 표식 ①** — [시스템 설정]의 **새 탭 이름**이다.
  #    🔴 **명령에 한글을 넣지 않는다.** 8진 이스케이프를 넘기고 컨테이너 안에서
  #       다시 만든다. 🔴 바이트 수를 먼저 받아 가른다(기대 13).
  v=$("$DOCKER" run --rm -e O="$APP_MARK_KO_OCT" --entrypoint sh "$tag" -c 'k=$(printf "$O"); n=$(printf "%s" "$k" | wc -c); printf "%s %s %s\n" "$n" "$(grep -rlF "$k" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$k" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  kb=$(printf '%s' "$v" | awk '{print $1}'); a=$(printf '%s' "$v" | awk '{print $2}'); b=$(printf '%s' "$v" | awk '{print $3}')
  say "한글 표식 ①(새 탭 이름) — 만든 글자 ${kb:-?}바이트(기대 $APP_MARK_KO_BYTES) · server ${a:-?}개 · static ${b:-?}개"
  if [ "${kb:-0}" != "$APP_MARK_KO_BYTES" ]; then
    hm "컨테이너 안에서 한글 표식 ① 을 **못 만들었다**(${kb:-?}바이트) — 🔴 위 수의 0 은 「없다」가 아니다"
    say "🔵 ② 가 ✓ 라면 판은 맞습니다 — **이 줄만으로 갈아 끼우기를 막지 않습니다.**"
  elif isnum "${a:-}" && isnum "${b:-}" && [ "$((a + b))" -ge 1 ]; then
    ok "새 탭 이름(한글)이 번들에 있다 — **[시스템 설정]이 탭 둘로 뜬다**"
  else
    bad "🔴 그 한글 글자가 번들에 없다 — **옛 판을 실었다.** 갈아 끼우지 마세요"
    doubt
  fi
  # ③-ㄴ 🔴 **한글 표식 ②** — **마지막 커밋이 넣은 등록부 설명 문구**다.
  #    🔴 그 커밋이 한 일은 「정상」 알약을 **빼는 것**이라, 번들에서 그 커밋을
  #       가리는 **유일한 양성 증거**가 이 글자다.
  #    🔴 **지시서가 제안한 음성 표식(「납기 지연 / 정상」)은 안 쓴다** — [실측]
  #       기준판 src/ 에 **0파일**이라 번들에서는 **옛 판에서도 0** 이고,
  #       아무것도 안 가른다(지금 판 소스에는 4파일 있지만 전부 주석이다).
  v=$("$DOCKER" run --rm -e O="$APP_MARK2_KO_OCT" --entrypoint sh "$tag" -c 'k=$(printf "$O"); n=$(printf "%s" "$k" | wc -c); printf "%s %s %s\n" "$n" "$(grep -rlF "$k" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$k" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
  kb=$(printf '%s' "$v" | awk '{print $1}'); a=$(printf '%s' "$v" | awk '{print $2}'); b=$(printf '%s' "$v" | awk '{print $3}')
  say "한글 표식 ②(마지막 커밋) — 만든 글자 ${kb:-?}바이트(기대 $APP_MARK2_KO_BYTES) · server ${a:-?}개 · static ${b:-?}개"
  if [ "${kb:-0}" != "$APP_MARK2_KO_BYTES" ]; then
    hm "한글 표식 ② 를 **못 만들었다**(${kb:-?}바이트) — 위 0 은 「없다」가 아니다"
  elif isnum "${a:-}" && isnum "${b:-}" && [ "$((a + b))" -ge 1 ]; then
    ok "**마지막 커밋이 담겼다** — 「정상」 배지가 사라진 판이다"
  else
    bad "🔴 마지막 커밋의 글자가 없다 — **「정상」 배지가 아직 뜨는 판이다.** 갈아 끼우지 마세요"
    doubt
  fi
  # ④ 🔵 **뒷걸음 방지 — 🔴 이번 판에서 셋 → 넷이 됐다.**
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
  [ "$km" = "$APP_KEEP_MARKS_WANT" ] && ok "뒷걸음 방지 ASCII ${APP_KEEP_MARKS_WANT}개를 다 봤다 (🔴 60번은 둘이었다 — 쉰여섯째 것을 보탰다)" \
    || bad "🔴 뒷걸음 방지를 ${km}개만 봤다 — ${APP_KEEP_MARKS_WANT}개를 기대했다. APP_KEEP_MARKS 가 깨졌다"
  # 🔴 뒷걸음 방지 ③ — **쉰다섯째(59번)가 올린 한글 글자.**
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
#   🔴 그래도 **빼지 않는다**(42~60번의 규율). ✗ 가 나면 **지난 판이 올린 기능이
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
    say "🔵 **이번 판은 이 탭을 안 건드립니다** — 60번이 거기 권한 관문을 세웠고 그대로입니다."
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
# 🔴 **이 배포가 실제로 바꾸는 자리를 센다** — 🔴 60번 것을 통째로 갈았다
# ══════════════════════════════════════════════════════════════════════
#   🔴 60번은 **권한 행 이사**(domesticOrders 잎 넷)와 **[최종 출하 승인 완료]
#      거르개**를 셌다. **그 수는 이번 판과 상관이 없다.** 그대로 베껴 두면 이
#      배포를 재는 숫자가 **하나도 없다** — 그래서 재는 것을 통째로 바꿨다.
#   🔵 **select 뿐이고 한 글자도 안 쓴다.**
#
#   🔴 **이 배포는 DB 에 표 하나를 더한다 — 자료는 한 줄도 안 넣는다.**
#      그래서 「전후 차이」로 잴 수 있는 것은 **「표가 있는가」 하나**이고,
#      그것이 이 배포의 목적물이다. 나머지는 **새 코드가 보여 줄 것**을 미리 센다.
#
# ── 🔴 SQL 의 함정 — **GROUP BY 1 을 쓰지 않는다** ───────────────────
#    🔴 60번의 ④ 와 ⑥ 은 다음 꼴이었다:
#         select X::text || ' ' || count(*) from T group by 1 order by 1
#       **GROUP BY 1 은 첫 출력 칸**을 가리키는데 그 칸에 **집계함수가 들어 있다** —
#       PostgreSQL 이 "aggregate functions are not allowed in GROUP BY" 로
#       질의를 통째로 거절한다.
#    🔴 ⑥ 은 그래서 **「못 쟀다」로 나왔고**(dss-deploy/README.md 의 쉰여섯째 절),
#       ④ 는 옆에 따로 센 수가 있어 **✓ 가 뜬 채 줄만 비어 있었다** —
#       「아무것도 안 재는 ✓」의 실물이다.
#    🔵 처방은 한 줄이다: **GROUP BY 를 칸 이름으로 적는다.**
#    🔴 **운영 DB 에 붙어 확인하지는 못했다**(이 배포본을 쓴 쪽은 DB 에 안 붙는다).
#       그래서 **줄이 비면 ✗ 가 아니라 ⚠️ 로 세고, 「무엇이 비었나」를 찍는다.**
effect_counts() {
  local ex n tot rows roles kinds dead seen
  printf '\n    ── 🔴 이 배포가 바꾸는 자리 (운영 수 · **select 뿐이다**)\n'
  say "🔴 60번은 여기서 **권한 행 이사**와 **거르개 건수**를 셌습니다 — 그 수는 이번"
  say "   판과 상관이 없어 통째로 갈았습니다. 🔵 이번 판이 재는 것은 **배지 설정 표**입니다."

  # ── ① 🔴 **이 배포의 목적물** — 표가 있는가 · 몇 줄인가 ────────────
  #    🔴 **「표가 없다」와 「0줄」은 다른 말이다.** 안 가르면 PRE 에서 「0줄이니
  #       정상」으로 읽히고 --migrate 가 제 일을 했는지 영영 모른다.
  printf '\n    ① 🔴 **%s 표** — 이 배포의 목적물\n' "$BV_TABLE"
  ex=$(bv_table_exists)
  say "표가 있는가: ${ex:-못 쟀다} (PRE 기대 0 · --migrate 뒤 기대 1)"
  if [ -z "${ex:-}" ]; then
    hm "표가 있는지 **못 쟀다** — $AS_BOX 가 도는지 보세요"
    say "🔴 **빈 결과는 삼켜진 오류일 수 있다** — 「없다」와 「못 쟀다」는 다른 말이다."
    doubt
  elif [ "$ex" = "0" ]; then
    hm "표가 **아직 없다** — 🔵 **--migrate 전이면 정상입니다.**"
    say "🔴 --migrate 뒤에 이 줄이 그대로면 **적용이 0건으로 끝난 것**입니다."
    say "🔵 지금 상태에서도 배지는 **전부 보입니다** — 그리는 화면들은 표가 없어도 안 죽습니다."
    say "🔴 다만 **[시스템 설정] › [배지 표시] 탭은 터집니다** — 그래서 --go 전에 꼭 돌립니다."
  else
    ok "표가 **있다** ($BV_TABLE — 0128 이 적용됐다)"
    n=$(bv_rows)
    say "그 표의 줄 수: ${n:-못 쟀다}줄 (배포 직후 기대 **0줄**)"
    if [ -z "${n:-}" ]; then
      hm "줄 수를 **못 쟀다** — 표는 있는데 읽히지 않는다. 사람이 보세요"; doubt
    elif [ "$n" = "0" ]; then
      ok "0줄이다 — **아무도 아무것도 안 껐다**(빈 표 = 전부 보임)"
      say "🔵 그래서 배포 직후 화면은 **「정상」 배지가 사라진 것 말고는 지금과 같습니다.**"
    else
      ok "${n}줄이다 — 누군가 배지를 껐다는 뜻입니다(아래 ② 가 어느 쌍인지 찍습니다)"
    fi
  fi

  # ── ② 🔵 끈 쌍을 배지별·자리별로 ───────────────────────────────────
  #    🔵 배포 직후에는 아무것도 안 나온다. 사람이 끄기 시작하면 여기 줄이 생긴다.
  #    🔴 **GROUP BY 를 칸 이름으로 적는다**(머리말의 함정).
  printf '\n    ② 🔵 끈 (배지, 자리) 쌍 — 배포 직후에는 **아무 줄도 안 나오는 것이 정상**\n'
  if [ "${ex:-0}" = "1" ]; then
    # 🔴 **enum·boolean 은 ::text 로 캐스트한다** — 이어붙이기가 타입 때문에 거절되면
    #    질의가 통째로 죽고 **빈 줄이 「없다」로 읽힌다**(53번 꼬리말에서 겪은 모양).
    rows=$(pgrows "$AS_BOX" "$AS_DB" "select badge_key || ' / ' || place_key || ' is_visible=' || is_visible::text from $BV_TABLE order by badge_key, place_key")
    if [ -z "${rows:-}" ]; then
      ok "끈 쌍이 **하나도 없다** (위 ① 의 0줄과 앞뒤가 맞는다)"
    else
      printf '%s\n' "$rows" | grep -v '^[[:space:]]*$' | sed 's/^/        /'
      ok "끈 쌍을 값으로 쟀다 (위 줄들이 지금 숨겨져 있는 자리다)"
      say "🔵 다시 켜는 것은 **그 행을 지우는 일**입니다 — 설정 화면에서 체크하면 됩니다."
    fi
  else
    say "        (표가 아직 없어 셀 것이 없다 — ① 을 보세요)"
  fi

  # ── ③ 🔴 settings 권한 — 이번 판이 **관리**를 여는 자리 ─────────────
  #    🔴 **저장된 칸 값이 코드 기본값을 이긴다.** 행이 있으면 그 수준이 운영의 답이다.
  #    🔵 행이 없으면 코드 기본값 — **읽기=다섯 역할 전부 · 관리=관리자 이상**.
  printf '\n    ③ 🔴 %s 의 %s 행 — 이번 판이 **관리**를 여는 자리\n' "$PERM_TABLE" "$SETTINGS_AREA"
  # 🔴 role 도 level 도 **enum** 이다 — ::text 를 빼면 이어붙이기가 거절되어
  #    질의가 통째로 죽고 **빈 줄이 「행이 없다」로 읽힌다.**
  rows=$(pgrows "$AS_BOX" "$AS_DB" "select role::text || ' ' || level::text from $PERM_TABLE where area_key = '$SETTINGS_AREA' order by role")
  n=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $PERM_TABLE where area_key = '$SETTINGS_AREA'")
  say "저장된 행: ${n:-못 쟀다}줄"
  if [ -z "${n:-}" ]; then
    hm "settings 행을 **못 쟀다** — $AS_BOX 가 도는지, 그 표가 있는지 보세요"; doubt
  elif [ "$n" = "0" ]; then
    ok "저장된 행이 **없다** — 다섯 역할이 전부 **코드 기본값**으로 돈다"
    say "🔵 기본값: **읽기 = 다섯 역할 전부** · **관리 = 관리자 이상**."
    say "🔴 그래서 이 배포로 **읽기가 좁아지는 역할은 없습니다.**"
  else
    printf '%s\n' "$rows" | grep -v '^[[:space:]]*$' | sed 's/^/        /'
    ok "settings 에 저장된 행이 ${n}줄이다 — **그 역할은 위 값이 운영의 답**이다"
    say "🔴 NONE 으로 저장된 역할이 있으면 **그 사람은 지금도 이 화면을 못 봅니다** —"
    say "   이 배포가 만든 일이 아닙니다(저장된 칸 값이 코드 기본값을 이깁니다)."
  fi

  # ── ④ 🔵 역할별 사람 수 — 「시스템 설정 — 관리」가 몇 사람에게 열리는가 ──
  #    🔴 **60번의 이 줄은 SQL 이 깨져 비어 있었다**(GROUP BY 1). 칸 이름으로 고쳤다.
  printf '\n    ④ 🔵 역할별 사람 수 (활성 · 휴지통 뺌) — **관리**가 몇 사람에게 열리는가\n'
  roles=$(pgrows "$AS_BOX" "$AS_DB" "select role::text || ' ' || count(*) from users where is_active and not is_deleted group by role order by role")
  n=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from users where is_active and not is_deleted")
  seen=$(printf '%s\n' "$roles" | grep -c . || true)
  if [ -z "${n:-}" ]; then
    hm "사람 수를 **못 쟀다** — $AS_BOX 가 도는지 보세요"
  else
    printf '%s\n' "$roles" | grep -v '^[[:space:]]*$' | sed 's/^/        /'
    say "        전체 ${n}명 · 역할 줄 ${seen:-0}개"
    if [ "${seen:-0}" = "0" ]; then
      hm "🔴 **역할별 줄이 한 개도 안 나왔다** — 전체는 ${n}명인데 쪼갠 줄이 비었다."
      say "🔴 60번이 바로 이 모양이었습니다(GROUP BY 1 이 집계함수에 걸려 질의가 거절됨)."
      say "   🔴 고쳤는데도 비면 **이 줄의 SQL 을 psql 로 직접 쳐 보세요** — 검사부터 의심합니다."
      doubt
    elif [ "${n:-0}" -ge 1 ]; then
      ok "역할별 사람 수를 값으로 쟀다 (활성 ${n}명 · 역할 ${seen}가지)"
      say "🔵 **관리는 관리자 이상**입니다 — 위 줄에서 그 역할의 사람 수가 이 설정을 쓸 사람입니다."
      say "🔴 **읽기는 다섯 역할 전부 그대로**라 아무도 좁아지지 않습니다."
    else
      hm "활성 계정이 **한 명도 없다** — 이 배포로 달라질 사람이 없다는 뜻입니다. 사람이 보세요"
    fi
  fi

  # ── ⑤ 🔴 「정상」 배지가 사라지는 줄 수 ────────────────────────────
  #    🔴 **지연 판정은 SQL 로 못 베낀다** — 그 함수가 내자 정리에서 날짜를 빌려
  #       오는 규칙(domain/requested-due-date-link.ts)과 출하 완료 잣대
  #       (domain/shipment-finished.ts)까지 들고 있다. **칸 하나로 못 적는다.**
  #    🔵 그래서 여기서는 **전체 규모만** 세고, 지연 건수는 위 다섯 도구 중
  #       **check:due-date-overdue 가 센 수**를 쓴다. 「정상」이 붙던 줄 = 전체 − 지연.
  #    🔴 **두 수를 곱해 짜 맞추지 않는다** — 재는 길이 둘이고 섞으면 둘 다 못 믿는다.
  printf '\n    ⑤ 🔴 **「정상」 배지가 사라지는 줄** — 전체 규모 (지연 건수는 위 도구가 센다)\n'
  n=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from repair_cases where is_deleted = false")
  say "휴지통 뺀 수리건: ${n:-못 쟀다}건"
  if [ -z "${n:-}" ]; then
    hm "수리건 수를 **못 쟀다** — $AS_BOX 가 도는지 보세요"; doubt
  else
    ok "전체 A/S 현황이 들고 있는 건을 값으로 쟀다 (${n}건)"
    say "🔴 그중 **[납기 지연] 이 아닌 줄에서 「정상」 알약이 사라집니다** — 그것이 이"
    say "   배포에서 눈에 가장 먼저 띄는 변화입니다(설정과 무관하게 즉시)."
    say "🔵 지연 건수는 위 **[납기 지연]** 도구가 센 수를 보세요. 전체 − 지연 = 달라지는 줄."
    say "🔴 그 둘을 여기서 빼서 적지 않습니다 — 재는 길이 둘이라 섞으면 둘 다 못 믿습니다."
  fi

  # ── ⑥ 🔵 결재 종류별 줄 수 — [최종 출하 승인 완료] 배지가 걸린 자리 ──
  #    🔵 그 배지는 쌍 29 중 **다섯 자리**를 차지한다 — 가장 많은 배지다.
  #    🔴 **60번이 여기서 「못 쟀다」를 냈다.** GROUP BY 1 을 칸 이름으로 고쳤다.
  printf '\n    ⑥ 🔵 결재 종류별 줄 수 — [최종 출하 승인 완료] 배지가 걸린 자리의 규모\n'
  kinds=$(pgrows "$AS_BOX" "$AS_DB" "select approval_type::text || ' ' || count(*) from repair_case_approvals group by approval_type order by approval_type")
  tot=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from repair_case_approvals")
  seen=$(printf '%s\n' "$kinds" | grep -c . || true)
  say "전체 결재 줄: ${tot:-못 쟀다}줄 · 종류 줄 ${seen:-0}개"
  if [ -z "${tot:-}" ]; then
    hm "결재 줄 수를 **못 쟀다** — 🔵 이 배포를 막지 않는다. $AS_BOX 가 도는지 보세요"
  elif [ "${seen:-0}" = "0" ] && [ "${tot:-0}" != "0" ]; then
    hm "🔴 **종류별 줄이 한 개도 안 나왔다** — 전체는 ${tot}줄인데 쪼갠 줄이 비었다."
    say "🔴 **60번이 바로 이 자리에서 「못 쟀다」를 냈습니다** — GROUP BY 1 이 집계함수에"
    say "   걸려 질의가 통째로 거절됐습니다. 이 판은 칸 이름으로 고쳤는데도 비었다면"
    say "   **이 줄의 SQL 을 psql 로 직접 쳐 보세요.** 검사부터 의심합니다."
    doubt
  else
    printf '%s\n' "$kinds" | grep -v '^[[:space:]]*$' | sed 's/^/        /'
    ok "결재 종류별 줄 수를 값으로 쟀다 (종류 ${seen}가지 · 전체 ${tot}줄)"
    say "🔵 **60번이 남긴 숙제가 이 줄이었습니다** — 거기서는 「못 쟀다」로 나왔습니다."
  fi

  printf '\n'
  say "🔴 **--migrate 전후로 ① 이 「없다」에서 「있다 · 0줄」이 되어야** 정상입니다."
  say "🔴 나머지(②③④⑤⑥)는 **앞뒤가 같아야** 정상입니다 — 이 배포는 그 자료를 안 건드립니다."
  say "   🔵 0128 은 **INSERT 가 0** 이라 어느 표의 행도 안 늘립니다."
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
    say "🔵 다섯은 :19 에도 :20 에도 있어야 한다 — 48·52~55번이 올려 두었고 이번 판에 안 줄었다."
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
  printf '%s\n' "🔴 **아래 다섯 중 넷은 이번 배포와 상관이 없습니다.** 앞뒤가 같으면 정상입니다."
  printf '%s\n' "   🔴 **다만 [납기 지연] 하나는 이번 판과 상관이 있습니다** — 그 수가 곧"
  printf '%s\n' "      「배지가 뜨는 줄」이고, 나머지 줄에서 「정상」 알약이 사라집니다."
  printf '%s\n' "   🔴 **이 배포를 재는 숫자는 맨 아래 절**(effect_counts)에 있습니다."
  printf '%s\n' "      🔴 그 절은 **60번 것과 재는 것이 완전히 다릅니다** — 60번은 권한 행 이사를,"
  printf '%s\n' "         이번 판은 **배지 설정 표**를 셉니다."
  count_one check:target-shipment-missing "사내 목표 출하일 미등록"
  count_one check:due-date-inverted       "납기 역전"
  count_one check:requested-due-date-sync "납기요청일 ↔ 고객 요청 납기일 어긋남"
  count_one check:due-date-overdue        "[납기 지연]  🔴 이번 판과 상관 있는 수"
  count_one check:delivered-date-sync     "납품일 ↔ 실제 출하일"
  effect_counts
  followup_counts
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  printf '%s\n' "🔴 **①(표가 있는가)과 [납기 지연] 건수를 적어 두세요** — 배포 뒤 맞댈 두 수입니다."
  printf '%s\n' "   🔵 ① 이 **--migrate 전에는 「없다」· 뒤에는 「있다 · 0줄」**이어야 합니다."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi
# ── 1. 지금 상태 ──────────────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
[ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
say "compose 줄 수 $(wc -l < "$CF") · image: 줄 $(grep -c '^ *image:' "$CF")개"

# ── 🔴 1-ㄱ-0. **덤프 이름과 compose 사본 이름의 판 꼬리표가 같은가** ──
#   🔴 **59번이 여기서 어긋났다**(사본 v55 · 덤프 v54) — 60번이 고쳤고 이 판도 잰다.
#   🔴 둘을 **한 곳에서 읽고, 같은지 값으로 확인한다.** 두 벌로 적힌 값이다.
printf '\n    ── 🔴 덤프 이름과 compose 사본 이름의 판 꼬리표\n'
BK_VER=$(printf '%s' "${BK##*/}" | sed -n 's/.*\.\(v[0-9][0-9]*\)-.*/\1/p')
say "compose 사본: ${BK##*/}   → 꼬리표 ${BK_VER:-못 읽음}"
say "DB 덤프     : dss_as-$DUMP_VER-<시각>.dump   → 꼬리표 $DUMP_VER"
if [ "${BK_VER:-}" = "$DUMP_VER" ]; then
  ok "둘의 판 꼬리표가 **같다** ($DUMP_VER) — 어느 배포의 사진인지 이름으로 가릴 수 있다"
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
        say "🔴 **--migrate 단계가 있다** — 그것이 도구 줄을 먼저 고치고 DB 에 표를 만든다." ;;
  MID)  ok "PHASE=MID — 도구만 새 판이다"
        say "🔴 **이 판에서 MID 는 1순위로 「--migrate 까지 돌았다」는 뜻이다.**"
        say "   🔵 --go 뒤에 --rollback 한 상태도 여기 보인다."
        say "🔴 **둘을 DB 기록으로 가른다** — 2절의 기록이 $AS_MIG_AFTER 면 --migrate 를 돌았고,"
        say "   $AS_MIG_BEFORE 면 아직이다(그때는 --migrate 부터 돌리세요)." ;;
  POST) ok "PHASE=POST — 둘 다 새 판이다. --go 까지 돌았다" ;;
  *)    hm "PHASE=ODD — 둘이 섞여 있다. **어느 단계가 도중에 멈췄거나 운영이 따로 움직였다.** 위 표를 보세요"
        say "🔴 60번(쉰여섯째)이 올린 판($AS_OLD_TAG · $AS_TOOLS_OLD)을 옛 값으로 적었다."
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
      MID)  hm "이미 MID 다 — 🔵 **다시 돌려도 안전하다**(drizzle 이 이미 적용한 것을 건너뛴다)" ;;
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
  # 🔴 볼륨이 제 자리에 붙는가 — 🔴 **이번 판에서도 중요하다.**
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


# ── 2. 🔴 DB — **이번 판도 앞뒤가 다른 수다** (128 → 129) ────────────
#   🔴 **60번의 127/128 을 그대로 베끼면 어느 단계에서도 ✗** 다.
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
  ok "$AS_MIG_AFTER 다 — **--migrate 가 이미 돌았다**(0128 이 올라가 있다)"
elif [ "$MIG_AS0" = "$AS_MIG_BEFORE" ]; then
  ok "$AS_MIG_BEFORE 다 — 60번이 올려 둔 그대로다 (**--migrate 가 아직이다**)"
  say "🔴 **--go 전에 --migrate 를 돌리세요** — 5절이 $AS_MIG_AFTER 가 아니면 멈춥니다."
else
  bad "🔴 기록이 ${MIG_AS0} 이다 — $AS_MIG_BEFORE 나 $AS_MIG_AFTER 를 기대했다"
  say "🔴 127 이면 **60번(쉰여섯째) 배포의 --migrate 가 안 돌았거나 되돌아간 것**이다."
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

# ══════════════════════════════════════════════════════════════════════
# ── 2-ㄱ. 🔴 **이번 판이 만드는 표** — 🔴 단계마다 기대값이 다르다
# ══════════════════════════════════════════════════════════════════════
#   🔴 **60번에는 이 절이 없었다** — 그 판의 0127 은 표를 한 칸도 안 바꿨다.
#   🔴 **PRE 에는 없는 것이 정상 · POST 에는 있는 것이 정상**이다.
#      한 잣대로 재면 둘 중 하나가 **가짜 ✗** 가 된다(48번이 데인 그 모양).
#   🔵 **기록 수로 기대값을 정한다** — 기록이 129 면 있어야 하고 128 이면 없어야 한다.
printf '\n== 2-ㄱ. 🔴 이번 판이 만드는 표 (%s) — 단계마다 기대값이 다르다\n' "$BV_TABLE"
BV_EX=$(bv_table_exists)
BV_IX=$(has_index      "$AS_BOX" "$AS_DB" "$BV_IDX")
BV_IXC=$(index_cols    "$AS_BOX" "$AS_DB" "$BV_IDX")
BV_FKN=$(has_constraint "$AS_BOX" "$AS_DB" "$BV_FK")
BV_COL_OK=0; BV_COL_SEEN=0
for cn in $BV_COLS; do
  BV_COL_SEEN=$((BV_COL_SEEN+1))
  c=$(has_column "$AS_BOX" "$AS_DB" "$BV_TABLE" "$cn")
  printf '      칸 %-12s %s\n' "$cn" "${c:-못 쟀다}"
  if [ "${c:-0}" = "1" ]; then BV_COL_OK=$((BV_COL_OK+1)); fi
done
say "표 ${BV_EX:-못 쟀다} · 칸 ${BV_COL_OK}/${BV_COL_SEEN} · 유니크 인덱스 ${BV_IX:-못 쟀다}(칸 ${BV_IXC:-?} · 기대 $BV_IDX_COLS_WANT) · FK ${BV_FKN:-못 쟀다}"
if [ "$BV_COL_SEEN" != "$BV_COLS_WANT" ]; then
  bad "🔴 칸을 ${BV_COL_SEEN}개만 물어봤다 — ${BV_COLS_WANT}개를 기대했다. BV_COLS 가 깨졌다"
fi
if [ -z "${MIG_AS0:-}" ] || [ -z "${BV_EX:-}" ]; then
  hm "DB 를 못 쟀으니 표의 기대값을 못 정한다 — **못 쟀다**로 센다"
elif [ "$MIG_AS0" = "$AS_MIG_BEFORE" ]; then
  # ── 적용 전: 없는 것이 정상 ──
  if [ "$BV_EX" = "0" ] && [ "$BV_COL_OK" = "0" ] && [ "${BV_IX:-0}" = "0" ] && [ "${BV_FKN:-0}" = "0" ]; then
    ok "기록이 $AS_MIG_BEFORE 이고 표도 **아직 없다** — 앞뒤가 맞는다 (--migrate 가 만든다)"
    say "🔵 이 상태에서도 **배지는 전부 보입니다** — 그리는 화면은 「표 없음」을 삼킵니다."
    say "🔴 다만 **[시스템 설정] › [배지 표시] 탭은 터집니다** — 그래서 --go 전에 꼭 --migrate 입니다."
  else
    bad "🔴 기록은 $AS_MIG_BEFORE 인데 표/칸/인덱스/FK 가 ${BV_EX}·${BV_COL_OK}·${BV_IX:-?}·${BV_FKN:-?} 다"
    say "🔴 **기록과 실물이 어긋난다** — 손으로 만든 표가 있거나 기록이 되돌아갔다. 고치지 말고 알리세요."
    doubt
  fi
elif [ "$MIG_AS0" = "$AS_MIG_AFTER" ]; then
  # ── 적용 뒤: 넷이 다 있어야 한다 ──
  if [ "$BV_EX" = "1" ] && [ "$BV_COL_OK" = "$BV_COLS_WANT" ] \
     && [ "${BV_IX:-0}" = "1" ] && [ "${BV_IXC:-x}" = "$BV_IDX_COLS_WANT" ] && [ "${BV_FKN:-0}" = "1" ]; then
    ok "기록이 $AS_MIG_AFTER 이고 **표·칸 ${BV_COLS_WANT}·유니크 인덱스(칸 $BV_IDX_COLS_WANT)·FK 가 다 있다**"
    say "🔵 **인덱스는 「있는가」만으로 안 가릅니다** — 같은 이름으로 다시 만든 것과"
    say "   구별하려고 **칸 수**를 함께 셉니다(0126 에서 겪은 자리)."
  else
    bad "🔴 기록은 $AS_MIG_AFTER 인데 표 ${BV_EX} · 칸 ${BV_COL_OK}/${BV_COLS_WANT} · 인덱스 ${BV_IX:-?}(칸 ${BV_IXC:-?}) · FK ${BV_FKN:-?} 다"
    say "🔴 **기록만 올라가고 실물이 안 생긴 것**일 수 있다 — drizzle 은 오류를 삼킨다. 멈추고 알리세요."
    doubt
  fi
else
  hm "기록이 ${MIG_AS0} 이라 표의 기대값을 못 정한다 — 위 2절의 ✗ 를 먼저 보세요"
fi

# ── 2-ㄴ. 🔴 **0124 가 만든 열** — 어느 단계에서나 **다 있어야** 한다 ──
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
say "$NEW_IDX 의 키 칸 수: ${IXC:-못 쟀다} (기대 $NEW_IDX_COLS_WANT — 🔵 0128 은 그 인덱스를 안 건드린다)"
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
printf '%s\n' "🔴 이 판은 **묶음을 보낸다.** 운영 볼륨이 아직 $AS_MIG_BEFORE 이고 0128 이 묶음 안에만 있다."
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
    say "🔴 **_images-56 의 묶음(128장)을 보내지 마세요** — 0128 이 없습니다."
  else
    if [ "$MODE" = migrate ]; then
      bad "🔴 묶음의 잰 값이 이 파일에 없다 — **61-build.sh --go 의 MIGTAR_SIZE·MIGTAR_MD5 를 채우세요**"
      say "🔴 안 채우면 「개발 PC 에서 만든 그 묶음이 맞나」를 **아예 못 본다.**"
    else
      hm "묶음의 잰 값이 이 파일에 없다 — **${MODE} 에서는 괜찮다.** --migrate 전에 채우세요"
    fi
  fi
  # 🔴 **안을 센다** — 「파일이 왔다」와 「쓸 만한 묶음이다」는 다르다.
  #    🔴 tar 를 grep -q 에 물리지 않는다 — **세어서 담고 비교하는 꼴**이다.
  TSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE '^drizzle/[0-9]{4}_.*[.]sql$' || true)
  T128=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${AS_LAST_MIG}_.*[.]sql" || true)
  TNEXT=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${AS_NEXT_MIG}_.*[.]sql" || true)
  say "묶음 안 — .sql ${TSQL:-?}장 (기대 $AS_MIG_AFTER) · $AS_LAST_MIG ${T128:-?}개 (기대 1) · $AS_NEXT_MIG ${TNEXT:-?}개 (기대 0)"
  if [ "${TSQL:-x}" = "$AS_MIG_AFTER" ] && [ "${T128:-0}" = "1" ] && [ "${TNEXT:-1}" = "0" ]; then
    ok "묶음 안이 $AS_MIG_AFTER 장이고 $AS_LAST_MIG 이 들어 있다 (**이것이 없으면 적용이 0건으로 끝난다**)"
  else
    if [ "$MODE" = migrate ] || [ "$MODE" = go ]; then
      bad "🔴 묶음 안이 기대와 다르다 — .sql ${TSQL:-?} · $AS_LAST_MIG ${T128:-?} · $AS_NEXT_MIG ${TNEXT:-?}"
      say "🔴 **_images-56 의 묶음(128장)을 보내셨나요?** 거기에는 0128 이 없습니다."
      doubt
    else
      hm "묶음 안이 기대와 다르다 (.sql ${TSQL:-?} · $AS_LAST_MIG ${T128:-?}) — **${MODE} 에서는 막지 않는다**"
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
    bad "🔴 묶음이 없고 볼륨도 $AS_MIG_AFTER 가 아니다 — **0128 을 올릴 길이 없다**"
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
    say "🔵 묶음을 푼 뒤에는 이렇게 나와야 합니다:"
    say "   전체 마이그레이션 $AS_MIG_AFTER 건 · 적용 대기 $AS_NEW_MIGS_WANT 건"
    say "   [${AS_LAST_MIG}_true_havok] 더하기만 합니다 — 사라지는 자료 없음"
    say "🔴 **「사라질 자료」가 보이면** 이 배포의 전제가 깨진 것입니다 — **멈추고 알리세요.**"
    say "🔵 0128 은 **CREATE TABLE 하나 · FK 하나 · 유니크 인덱스 하나**뿐입니다(INSERT 0)."
  else
    bad "🔴 db:preflight 가 ${PRC:-?} 다 — 0 을 기대했다. **사라질 자료가 있다는 뜻이다**"
    say "🔴 0128 은 **표를 더하기만 한다.** 0 이 아니면 **전제가 깨진 것**이다."
    doubt
  fi
else
  hm "compose 에 $AS_TOOLS_SVC 가 없어 db:preflight 를 못 불렀다"
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
      bad "🔴 $TAR — **잰 값이 이 파일에 없다.** 61-build.sh --go 가 찍어 준 두 줄로 TARS 를 채우세요"
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
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 61-build.sh --go 가 끝에 찍어 주는"
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
  printf '  ✓ %s · ✗ %s · ? %s   (PHASE=%s · DB 기록 %s · %s 표 %s)\n' "$PASS" "$FAIL" "$WARN" "$PHASE" "${MIG_AS0:-?}" "$BV_TABLE" "${BV_EX:-?}"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  printf '%s\n' "🔴 다음 차례: --count(앞) → scp tar **둘** + **묶음 하나** → --preload → (다시 --check)"
  printf '%s\n' "   → **--migrate** → --go → --count(뒤)"
  printf '%s\n' "🔴 **PHASE=PRE 에서 돌리면 ? 가 여럿 나오는 것이 정상**이다 (tar 둘과 묶음이 아직 없다)."
  printf '%s\n' "🔴 **--migrate 를 건너뛰지 마세요** — 5절이 DB 기록이 $AS_MIG_AFTER 가 아니면 멈춥니다."
  printf '%s\n' "   🔴 그리고 그 전에는 **[시스템 설정] › [배지 표시] 탭이 터집니다**(표가 없습니다)."
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
  printf '%s\n' "   **DB 에 표 하나를 만듭니다**($BV_TABLE · 기록 $AS_MIG_BEFORE → $AS_MIG_AFTER)."
  printf '%s\n' "   🔵 **자료는 한 줄도 안 넣습니다** — INSERT 가 0 입니다. 표는 비어서 섭니다."
  printf '%s\n' "🔴 **건너뛰고 --go 로 가지 마세요.** --go 는 기록이 $AS_MIG_AFTER 가 아니면 멈춥니다 —"
  printf '%s\n' "   새 앱의 **[시스템 설정] › [배지 표시]** 탭이 그 표를 읽고, 거기는 「표 없음」을"
  printf '%s\n' "   **안 삼킵니다**(값을 바꾸러 온 화면이라 일부러 그렇습니다)."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ══════════════════════════════════════════════════════════════════════
# ── 4-ㄴ. --migrate : 🔴 **DB 에 표를 하나 만든다** (128 → 129) ──────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **60번과 하는 일이 정반대인 절이다.** 그 판의 0127 은 INSERT 넷뿐이라
#      「옮길 행이 0 이 됐는가」로 확인했다. **0128 은 표를 만든다** — 그래서
#      확인도 **「표·칸 여섯·유니크 인덱스(칸 2)·FK 가 생겼는가」**다.
#      🔴 60번의 확인 절을 그대로 베끼면 **아무것도 안 재는 ✓** 가 된다.
#   🔴 **종료 코드만 보고 「성공」이라 말하지 않는다** — 적용 뒤 DB 를 다시 읽는다.
#   🔵 **다시 돌려도 안전하다** — drizzle 은 이미 적용한 것을 건너뛴다.
if [ "$MODE" = migrate ]; then
  printf '\n== 4-ㄴ. 🔴 마이그레이션 — 이 판은 **%s건**이다 (기록 %s → %s · **표를 하나 만든다**)\n' "$AS_NEW_MIGS_WANT" "$AS_MIG_BEFORE" "$AS_MIG_AFTER"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **DB 를 안 건드리고 멈춘다.**\n'; exit 1; fi

  # ── ㄱ. 🔴 덤프 — 스키마를 바꾸기 직전의 사진 ──────────────────────
  make_dump "🔴 이번 판은 DB 의 **스키마**를 바꾼다(표 하나) — 바꾸기 직전의 사진이다"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 되돌릴 길이 없다 — **DB 도 앱도 그대로 두고 멈춘다.**\n'; exit 1; fi

  # ── ㄴ. 🔴 적용 전 줄 수를 적어 둔다 ────────────────────────────────
  #    🔴 **role_permissions 도 이 목록에 있다** — 60번은 그 표에 행을 더하는 판이라
  #       뺐었다. **0128 은 어느 표의 행도 안 건드린다**(INSERT 가 0 이다).
  printf '\n    ── 적용 전 줄 수 (뒤에 **전부 그대로여야** 한다 · 0128 은 INSERT 가 0 이다)\n'
  CNT_BEFORE=""
  for F in $AS_COUNT_TABLES; do
    V=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $F")
    CNT_BEFORE="$CNT_BEFORE as.$F=${V:-?}"; say "dss_as.$F ${V:-?}줄"
  done

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
  #   🔴 **이번 판에서 특히 중요하다** — 공용 스키마가 움직였다. 옛 스키마가 담긴
  #      도구로 db:migrate 를 돌리면 **새 표를 모르는 채** 돈다.
  if "$DOCKER" image inspect "$AS_TOOLS_NEW" >/dev/null 2>&1; then as_tools_inside_check
  else bad "🔴 $AS_TOOLS_NEW 가 NAS 에 없다 — compose 가 없는 이미지를 가리키게 됐다"; fi
  if [ "$FAIL" != 0 ]; then
    printf '\n🔴 도구가 온전하지 않다 — **사본으로 되돌리고 DB 는 안 건드린다.**\n'
    cp "$BK" "$CF"; exit 1
  fi

  # ── ㅁ. 🔴 볼륨을 129 로 올린다 — **이번 판에는 반드시 푼다** ───────
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
  # 🔴 0122~0128 이 온전한가 + 0129 가 없는가 + 지우는 문장 0 + 0128 의 속.
  check_keep_migs || true
  if [ "$FAIL" != 0 ]; then printf '\n🔴 마이그레이션 파일이 온전하지 않다 — **DB 도 앱도 그대로다.**\n'; cp "$BK" "$CF"; exit 1; fi
  # 🔴 컨테이너가 **실제로 그 폴더를 읽는지** 본다. 겉이 아니라 결과다.
  INSQL=$(dct run --rm --entrypoint sh "$AS_TOOLS_SVC" -c "ls -1 $IMG_MIGDIR/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r' | tail -1)
  say "$AS_TOOLS_SVC 안에서 본 $IMG_MIGDIR 의 .sql: ${INSQL:-?}장 (기대 $AS_MIG_AFTER)"
  if [ "${INSQL:-0}" = "$AS_MIG_AFTER" ]; then ok "컨테이너 안에서도 $AS_MIG_AFTER 장이다 (볼륨이 제대로 붙었다)"
  else bad "컨테이너 안이 ${INSQL:-?}장이다 — $AS_MIG_AFTER 장이어야 한다"; fi
  # 🔴 **0128 이 컨테이너 안에서도 보이는가** — 이것이 안 보이면 적용이
  #    **0건으로 조용히 끝난다.**
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
  say "🔵 위 출력에 이렇게 나오는 것이 **정상입니다**:"
  say "   전체 마이그레이션 $AS_MIG_AFTER 건 · 적용 대기 $AS_NEW_MIGS_WANT 건"
  say "   [${AS_LAST_MIG}_true_havok] **더하기만 합니다 — 사라지는 자료 없음**"
  say "🔴 **「사라질 자료」가 있다고 나오면 종료 코드가 1 이고 여기서 멈춥니다.**"
  say "🔵 0128 의 **ON DELETE restrict 한 줄은 아무것도 안 지웁니다** — FK 구절입니다."
  if [ "$PRC" != 0 ]; then
    bad "🔴 db:preflight 가 0 이 아니다 ($PRC) — **사라질 자료가 있다는 뜻이다**"
    say "🔴 $AS_LAST_MIG 은 **CREATE TABLE 하나뿐**이다. 0 이 아니면 **전제가 깨진 것**이다."
    doubt
    printf '\n🔴 **DB 를 안 건드리고 멈춘다.** 앱은 그대로 돈다.\n'
    cp "$BK" "$CF"
    exit 1
  fi

  # ── ㅅ. 돌린다 — 🔴 **여기서 DB 가 바뀐다** ────────────────────────
  printf '\n    ── 🔴 돌린다 (여기서 DB 가 바뀐다 · drizzle 은 다시 돌려도 안전하다)\n'
  say "🔴 drizzle 은 **밀린 것을 한 트랜잭션에** 넣습니다 — 하나라도 실패하면 안 올라갑니다."
  say "🔵 $AS_LAST_MIG 은 **표 하나를 만들 뿐**입니다 — INSERT 가 0 이라 자료를 안 건드립니다."
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
  # ── 🔴 **이 판의 진짜 증거** — 표·칸·인덱스·FK 가 생겼는가 ─────────
  #    🔴 **기록만 보고 끝내지 않는다.** 60번은 0127 이 표를 안 바꿔 「옮길 행이
  #       0 이 됐는가」로 쟀다. **이번 판은 실물이 생기므로 실물을 센다.**
  printf '\n    ── 🔴 %s 이 **제 일을 했는가** (표·칸 %s·유니크 인덱스·FK 가 생겨야 한다)\n' "$AS_LAST_MIG" "$BV_COLS_WANT"
  BV_EX1=$(bv_table_exists)
  BV_IX1=$(has_index      "$AS_BOX" "$AS_DB" "$BV_IDX")
  BV_IXC1=$(index_cols    "$AS_BOX" "$AS_DB" "$BV_IDX")
  BV_FK1=$(has_constraint "$AS_BOX" "$AS_DB" "$BV_FK")
  BVC_OK=0; BVC_SEEN=0
  for cn in $BV_COLS; do
    BVC_SEEN=$((BVC_SEEN+1))
    c=$(has_column "$AS_BOX" "$AS_DB" "$BV_TABLE" "$cn")
    printf '      칸 %-12s %s\n' "$cn" "${c:-못 쟀다}"
    if [ "${c:-0}" = "1" ]; then BVC_OK=$((BVC_OK+1)); fi
  done
  say "표 ${BV_EX1:-?} · 칸 ${BVC_OK}/${BVC_SEEN} · 유니크 인덱스 ${BV_IX1:-?}(칸 ${BV_IXC1:-?} · 기대 $BV_IDX_COLS_WANT) · FK ${BV_FK1:-?}"
  if [ "${BV_EX1:-0}" = "1" ] && [ "$BVC_OK" = "$BV_COLS_WANT" ] \
     && [ "${BV_IX1:-0}" = "1" ] && [ "${BV_IXC1:-x}" = "$BV_IDX_COLS_WANT" ] && [ "${BV_FK1:-0}" = "1" ]; then
    ok "**표·칸 ${BV_COLS_WANT}개·유니크 인덱스(칸 $BV_IDX_COLS_WANT)·FK 가 전부 생겼다** (값으로 확인했다)"
    say "🔵 **인덱스는 「있는가」만으로 안 가릅니다** — 칸 수까지 셉니다(같은 이름으로 다시"
    say "   만든 것과 구별하려고 — 0126 에서 겪은 자리입니다)."
    BV_N1=$(bv_rows)
    say "그 표의 줄 수: ${BV_N1:-못 쟀다}줄 (기대 **0** — 0128 은 INSERT 가 0 이다)"
    if [ "${BV_N1:-x}" = "0" ]; then
      ok "표가 **비어 있다** — 아무도 아무것도 안 껐다(빈 표 = 전부 보임)"
    elif [ -z "${BV_N1:-}" ]; then
      hm "줄 수를 못 쟀다 — 표는 있는데 읽히지 않는다. 사람이 보세요"
    else
      hm "표에 ${BV_N1}줄이 있다 — 0 을 기대했다. **누가 손으로 넣었나요?** 사람이 보세요"
    fi
  else
    bad "🔴 표 ${BV_EX1:-?} · 칸 ${BVC_OK}/${BV_COLS_WANT} · 인덱스 ${BV_IX1:-?}(칸 ${BV_IXC1:-?}) · FK ${BV_FK1:-?} 다"
    say "🔴 **기록만 올라가고 실물이 안 생겼다** — drizzle 은 오류를 삼킨다."
    say "🔴 **--go 로 넘어가지 마세요** — 새 앱의 [배지 표시] 탭이 그 자리에서 터집니다."
    doubt
  fi
  # 🔴 0124~0126 이 만든 것이 **아직 그대로 있는가** — 0128 이 건드릴 자리는 아니다.
  NC=$(has_column     "$AS_BOX" "$AS_DB" "$AS_COL_TABLE" "$AS_COL")
  E1=$(has_enum_value "$AS_BOX" "$AS_DB" "$AS_ENUM1" "$AS_ENUM_VALUE")
  I1=$(has_index      "$AS_BOX" "$AS_DB" "$AS_IDX1")
  IXC2=$(index_cols   "$AS_BOX" "$AS_DB" "$NEW_IDX")
  say "0124 의 칸 ${NC:-?} · enum ${E1:-?} · 유니크 인덱스 ${I1:-?} · 그 칸 수 ${IXC2:-?} (1·1·1·$NEW_IDX_COLS_WANT)"
  if [ "${NC:-0}" = "1" ] && [ "${E1:-0}" = "1" ] && [ "${I1:-0}" = "1" ] && [ "${IXC2:-x}" = "$NEW_IDX_COLS_WANT" ]; then
    ok "지난 판들이 만든 것이 그대로 있다 ($AS_LAST_MIG 은 그 표들을 안 건드린다)"
  else
    bad "🔴 지난 판의 칸·enum·인덱스가 ${NC:-?}·${E1:-?}·${I1:-?}·${IXC2:-?} 다 — **그대로여야 한다**"
    doubt
  fi
  printf '\n    ── 🔴 줄 수가 그대로인가 (0128 은 INSERT 가 0 이라 **하나도 안 바뀐다**)\n'
  for F in $AS_COUNT_TABLES; do
    V=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $F")
    B=$(printf '%s' "$CNT_BEFORE" | tr ' ' '\n' | sed -n "s/^as\\.$F=//p")
    [ "${V:-x}" = "${B:-y}" ] && ok "dss_as.$F ${V}줄 — 그대로" \
      || bad "🔴 dss_as.$F 가 ${B:-?} → ${V:-?} 로 **달라졌다**"
  done
  say "🔵 **role_permissions 도 이 목록에 있습니다** — 60번은 그 표에 행을 더하는 판이라"
  say "   뺐었습니다. 이번 판은 **어느 표의 행도 안 건드립니다.**"
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
    printf '%s\n' "  🔵 확인한 것: 기록 $AS_MIG_AFTER · **표 $BV_TABLE 과 칸 $BV_COLS_WANT 개** ·"
    printf '%s\n' "     유니크 인덱스(칸 $BV_IDX_COLS_WANT) · FK · 그 표가 **0줄** ·"
    printf '%s\n' "     지난 판의 칸·enum·인덱스 그대로 · 지우는 문장 0줄 · 나머지 표 줄 수 그대로 ·"
    printf '%s\n' "     포털 DB 그대로."
    printf '%s\n' "  🔵 compose 의 $AS_TOOLS_SVC 가 $AS_TOOLS_NEW 가 됐습니다 (사본: $BK)"
    printf '%s\n' "  🔴 되돌릴 길(바꾸기 직전의 덤프): $DUMP"
    printf '%s\n' "     🔵 **되돌릴 일은 거의 없습니다** — 옛 앱은 그 표를 쳐다보지도 않습니다."
    printf '%s\n' "     🔴 그래도 물려야 하면 DROP TABLE IF EXISTS \"$BV_TABLE\"; 한 문장이 더 빠릅니다"
    printf '%s\n' "        (drizzle 의 기록도 함께 지워야 다시 적용됩니다)."
    printf '%s\n' "  🔴 **다음: --go** — 이제 PHASE=MID 라 --go 에서 image: 줄이 **하나만** 달라집니다."
    printf '%s\n' "     🔴 **지금 앱은 아직 옛 판($AS_OLD_TAG)입니다.** 표는 생겼지만 아무도 안 씁니다 —"
    printf '%s\n' "        그 상태로 두어도 해롭지 않습니다."
  else
    printf '%s\n' "🔴 위 ✗ 를 보세요. 🔵 이 모드는 **다시 돌려도 안전합니다**: bash $0 --migrate"
    printf '%s\n' "  🔴 **DB 가 바뀌었을 수 있습니다** — 위 「값으로 확인」 절의 기록 수와 표를 보세요."
    printf '%s\n' "  🔴 덤프: ${DUMP:-없음}"
    printf '%s\n' "  🔴 **--go 로 넘어가지 마세요** — --go 는 기록이 $AS_MIG_AFTER 가 아니면 멈춥니다."
  fi
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 5. --go / --rollback : compose 의 image: 줄을 바꾼다 ─────────────
#  🔴 --go 는 앱 하나(와 PRE 면 도구 하나)를 고친다. --rollback 은 **앱만** 되돌린다 —
#     도구는 새 판 그대로 둔다(39·41~60번과 같은 판단).
#  🔴 **app-po · app-auth · tools-auth 줄은 어느 모드에서도 안 건드린다.**
printf '\n== 5. compose 의 image: 줄을 바꾼다\n'
# 🔴 **덤프를 여기서도 뜬다.** --migrate 를 건너뛰고 --go 로 바로 올 수 있기 때문이다.
#    🔵 --migrate 를 이미 돌리셨으면 사진이 둘이 된다 — 해롭지 않다.
#    🔵 --rollback 에서는 안 뜬다: 되돌리는 길은 빠를수록 좋다.
if [ "$MODE" = go ]; then
  make_dump "--migrate 를 건너뛰었을 수 있다 — 갈아 끼우기 전 사진을 남긴다"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 덤프를 못 떴다 — **아무것도 안 고치고 멈춘다.**\n'; exit 1; fi
  # 🔴 **기록이 129 인지 막는다.** 🔵 60번은 128 이었다.
  if [ "${MIG_AS0:-x}" != "$AS_MIG_AFTER" ]; then
    bad "🔴 DB 기록이 ${MIG_AS0:-못 쟀다} 다 — **$AS_MIG_AFTER 이어야 --go 할 수 있다.**"
    say "🔴 **--migrate 를 먼저 돌리세요**: bash $0 --migrate"
    say "   🔵 그 모드가 묶음을 풀고 $AS_MIG_BEFORE → $AS_MIG_AFTER 로 올립니다."
    say "🔴 **표가 없으면 새 앱의 [시스템 설정] › [배지 표시] 탭이 그 자리에서 터집니다** —"
    say "   그 화면만은 「표 없음」을 안 삼킵니다(값을 바꾸러 온 화면이라 일부러 그렇습니다)."
    printf '\n🔴 **아무것도 안 고치고 멈춘다.** 앱은 그대로 옛 판으로 돈다.\n'
    exit 1
  fi
  ok "DB 기록이 $AS_MIG_AFTER 다 (--migrate 가 끝났다)"
  # 🔴 **수만 보지 않는다** — 새 앱이 읽을 **표가 실제로 있는지** 다시 묻는다.
  #    🔴 60번은 여기가 「잎 넷에 아직 넣을 행이 0인가」였다. **이번 판은 실물이다.**
  GEX=$(bv_table_exists)
  GIX=$(has_index "$AS_BOX" "$AS_DB" "$BV_IDX")
  say "새 앱이 읽을 표 $BV_TABLE: ${GEX:-못 쟀다} · 유니크 인덱스 ${GIX:-못 쟀다} (둘 다 1 이어야 한다)"
  if [ -z "${GEX:-}" ]; then
    hm "표가 있는지 **못 쟀다** — **빈 결과는 삼켜진 오류일 수 있다.** 사람이 보세요"
  elif [ "${GEX:-0}" = "1" ] && [ "${GIX:-0}" = "1" ]; then
    ok "표와 유니크 인덱스가 **둘 다 있다** (기록 수가 아니라 **값**으로 확인했다)"
  else
    bad "🔴 표 ${GEX:-?} · 인덱스 ${GIX:-?} 다 — **기록만 $AS_MIG_AFTER 이고 실물이 없다.** 멈추고 알릴 것"
    say "🔴 **--migrate 를 한 번 더 돌리세요**(다시 돌려도 안전합니다)."
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

# 🔴 DB — 기록이 **129 그대로**인가 (앱 교체가 DB 를 건드릴 일은 없다)
#    🔵 --rollback 에서도 129 다 — **0128 은 자동으로 안 되돌린다.**
MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
say "A/S 마이그레이션 ${MIG_AS0:-?} -> ${MIG_AS1:-?} (기대 $AS_MIG_AFTER · **이 단계가 DB 를 안 바꾼다**)"
[ "${MIG_AS1:-x}" = "$AS_MIG_AFTER" ] && ok "$AS_MIG_AFTER 다 (이 단계가 DB 를 한 글자도 안 바꿨다)" \
  || bad "🔴 ${MIG_AS1:-?} 다 — $AS_MIG_AFTER 여야 한다. **DB 가 그 사이에 움직였다**"
MIG_AU1=$(mig_count "$AUTH_BOX" "$AUTH_DB")
say "포털 마이그레이션 ${MIG_AU0:-?} -> ${MIG_AU1:-?} (기대 $AUTH_MIG_KEEP)"
[ "${MIG_AU1:-x}" = "$AUTH_MIG_KEEP" ] && ok "포털이 $AUTH_MIG_KEEP 그대로다 (안 건드렸다)" \
  || bad "🔴 포털이 ${MIG_AU1:-?} 다 — $AUTH_MIG_KEEP 그대로여야 한다"
# 🔴 **새 앱이 읽을 표가 있는가** — 기록 수가 아니라 **값**으로 다시 묻는다.
#    🔴 60번은 여기가 「잎 넷에 아직 넣을 행이 0인가」였다. **이번 판은 실물이다.**
VEX=$(bv_table_exists)
VIX=$(has_index "$AS_BOX" "$AS_DB" "$BV_IDX")
VN=$(bv_rows)
say "$BV_TABLE: 표 ${VEX:-못 쟀다} · 유니크 인덱스 ${VIX:-못 쟀다} · 줄 수 ${VN:-못 쟀다} (기대 1 · 1 · 0)"
if [ -z "${VEX:-}" ]; then
  hm "표가 있는지 **못 쟀다** — **빈 결과는 삼켜진 오류일 수 있다.** 사람이 보세요"
elif [ "${VEX:-0}" = "1" ] && [ "${VIX:-0}" = "1" ]; then
  ok "표와 유니크 인덱스가 둘 다 있다 (**새 앱의 [배지 표시] 탭이 설 자리가 있다**)"
  if [ "${VN:-x}" = "0" ]; then
    say "🔵 줄 수가 0 입니다 — **아무도 아무것도 안 껐습니다.** 화면은 「정상」이 사라진 것"
    say "   말고는 지금과 같습니다(빈 표 = 전부 보임)."
  else
    say "🔵 줄 수가 ${VN:-?} 입니다 — 누군가 배지를 껐다는 뜻입니다(--count 의 ② 가 어느 쌍인지 찍습니다)."
  fi
else
  bad "🔴 표 ${VEX:-?} · 인덱스 ${VIX:-?} 다 — **새 앱의 [배지 표시] 탭이 그 자리에서 터진다**"
  say "🔴 --migrate 를 한 번 더 돌리세요(다시 돌려도 안전합니다)."
  doubt
fi
# 🔴 지난 판들이 만든 칸도 **아직 있는가** — 새 앱이 읽고 **쓴다.**
NC=$(has_column     "$AS_BOX" "$AS_DB" "$AS_COL_TABLE" "$AS_COL")
E1=$(has_enum_value "$AS_BOX" "$AS_DB" "$AS_ENUM1" "$AS_ENUM_VALUE")
I1=$(has_index      "$AS_BOX" "$AS_DB" "$AS_IDX1")
V5=$(has_column     "$AS_BOX" "$AS_DB" "$NEW_COL_T2" "$NEW_COL_5")
VIX2=$(index_cols   "$AS_BOX" "$AS_DB" "$NEW_IDX")
say "0124 의 칸 ${NC:-?} · enum ${E1:-?} · 인덱스 ${I1:-?} · 0126 의 ${NEW_COL_5} ${V5:-?} · 인덱스 칸 수 ${VIX2:-?}"
if [ "${NC:-0}" = "1" ] && [ "${E1:-0}" = "1" ] && [ "${I1:-0}" = "1" ] && [ "${V5:-0}" = "1" ] && [ "${VIX2:-x}" = "$NEW_IDX_COLS_WANT" ]; then
  ok "지난 판들이 만든 것이 그대로 있다 — **앱이 읽을 칸이 있다**"
else
  bad "🔴 칸·enum·인덱스가 ${NC:-?}·${E1:-?}·${I1:-?}·${V5:-?}·${VIX2:-?} 다 — **앱이 그 자리에서 깨진다**"
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
# 🔴 **이 줄은 바깥을 안 잰다** — 이 파일 안의 목록을 본다. 그래도 둔 까닭은,
#    포털을 함께 갈아 끼우게 되는 날 **이 줄을 지워야 한다는 표지**이기 때문이다.
if printf '%s\n' "$KEEP_BOXES" | tr ' ' '\n' | grep -qx 'dss-auth'; then
  ok "KEEP_BOXES 에 dss-auth 가 있다 (이 파일의 목록을 본 것이다 — 바깥을 잰 것이 아니다)"
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

# 🔴 **이 배포가 바꾸는 자리를 다시 센다** — 🔵 ① 말고는 **앞뒤가 같아야** 정상이다.
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
  printf '%s\n' "🔵 **DB 는 --migrate 가 이미 올렸습니다** — 기록이 $AS_MIG_AFTER 이고 표가 섰습니다."
  printf '%s\n' "   🔵 이 단계(--go)는 DB 를 **한 글자도 안 바꿨습니다.**"
  printf '%s\n' "   🔵 $AS_LAST_MIG 은 **표 하나를 만들 뿐**이었습니다 — 자료는 한 줄도 안 넣습니다."
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
    printf '%s\n' "     🔴 **①(표)이 「있다 · 0줄」이어야 합니다** — --migrate 가 제 일을 했다는 증거입니다."
    printf '%s\n' "     🔴 **[납기 지연] 건수를 적어 두세요** — 아래 눈 확인 ⑤ 에서 맞댑니다."
    printf '%s\n' "     🔵 다섯 도구는 앞뒤가 같아야 정상입니다 — 이번 판이 그 자료를 안 건드립니다."
    printf '%s\n' "══════════════════════════════════════════════════════════════"
    printf '%s\n' ""
  fi
  printf '%s\n' "🔴 **마지막은 눈입니다** — 이번 판은 **커밋 일곱**이고 화면이 여러 곳에서 바뀝니다."
  printf '%s\n' ""
  printf '%s\n' "  ── A. 🔴 [시스템 설정] (**가장 빨리 확인되는 곳**) ──────────"
  printf '%s\n' "  ① [설정] › [시스템 설정] 이 **탭 둘**이어야 합니다 — [고객 안내 상태 목록] · **[배지 표시]**."
  printf '%s\n' "     🔴 그 탭 이름이 **앱 번들 표식**입니다 — 안 보이면 옛 판이 도는 것입니다."
  printf '%s\n' "  ② 🔵 [배지 표시] 탭을 열면 **배지 ${BV_BADGES_WANT}줄**이 서고 체크상자가 **모두 ${BV_PAIRS_WANT}개**여야 합니다."
  printf '%s\n' "     🔵 자리는 **${BV_PLACES_WANT}곳**입니다 — 전체 A/S 현황 목록 · 수리건 상세 머리말 ·"
  printf '%s\n' "        수리건 상세 기본 정보 탭 · 내자 정리 목록 · 기타건 현황 목록 · 기타건 상세 머리말."
  printf '%s\n' "     🔵 **전부 켜져 있는 것이 정상**입니다(표가 비어서 나갑니다 — --count 의 ① 이 0줄)."
  printf '%s\n' "     🔴 배지마다 **「언제 뜨는가」 설명 한 줄**이 붙어 있어야 합니다 — 끄기 전에 읽을 글입니다."
  printf '%s\n' "  ③ 🔴 **하나를 꺼서 [저장]하고 그 화면에 가 보세요** — 그 자리에서만 사라져야 합니다."
  printf '%s\n' "     🔴 **${BV_PAIRS_WANT}자리가 전부 실제로 듣습니다** — 꺼도 아무 일이 안 일어나는 스위치는 없습니다."
  printf '%s\n' "     🔵 되돌리려면 다시 켜고 저장합니다(켜는 것은 **그 행을 지우는 일**입니다)."
  printf '%s\n' "     🔵 끈 자리는 --count 의 ② 에 줄로 나옵니다 — 거기서도 맞대어 보세요."
  printf '%s\n' ""
  printf '%s\n' "  ── B. 🔴 권한 — **읽기는 아무도 안 좁아진다** ──────────────"
  printf '%s\n' "  ④ [사용자 관리] › [역할별 접근 권한]의 **「시스템 설정」에 「관리」 칸이 새로** 생깁니다."
  printf '%s\n' "     🔴 **읽기는 다섯 역할 전부 그대로**입니다 — 배포 직후 못 보게 되는 사람이 없습니다."
  printf '%s\n' "     🔵 관리는 **관리자 이상**이 기본값입니다. 그 아래 역할로 [배지 표시]를 저장하면"
  printf '%s\n' "        거절되어야 합니다(화면도 서버도 같은 열쇠로 묻습니다)."
  printf '%s\n' "     🔵 그 칸의 설명이 **「고객 안내 상태 목록을 고치는 권한은 「고객 안내 현황」의"
  printf '%s\n' "        관리가 정합니다」**라고 적혀 있어야 합니다 — 여기만 열고 그 카드가 안 열리면"
  printf '%s\n' "        올린 사람이 고장으로 읽습니다."
  printf '%s\n' ""
  printf '%s\n' "  ── C. 🔴 「정상」 배지 제거 (**설정과 무관하게 즉시**) ──────"
  printf '%s\n' "  ⑤ [전체 A/S 현황]의 상태 칸에서 **지연이 아닌 줄에는 아무것도 안 떠야** 합니다."
  printf '%s\n' "     🔴 그 전까지는 거기에 파란 알약 **「정상」**이 있었습니다 — 그것이 사라집니다."
  printf '%s\n' "     🔵 지연인 줄에는 **[납기 지연]** 하나만 뜹니다."
  printf '%s\n' "     🔴 **--count 의 [납기 지연] 건수와 맞대어 보세요** — 그 수만큼만 배지가 있어야 합니다."
  printf '%s\n' "     🔵 0건이면 화면에 그 배지가 하나도 없는 것이 **맞습니다**(배포 잘못이 아닙니다)."
  printf '%s\n' "     🔵 수리건 상세 머리말과 카드 목록에서도 같습니다."
  printf '%s\n' ""
  printf '%s\n' "  🔴 **「아무것도 안 바뀐 것 같다」면** A① 의 [배지 표시] 탭을 먼저 보세요 —"
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
  printf '%s\n' "  🔵 **이번 판이 더한 표($BV_TABLE)는 PO 가 안 씁니다** — 넷째가 되지 않습니다."
  printf '%s\n' ""
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (app-as 만 되돌립니다)"
  printf '%s\n' "  🔵 도구는 $AS_TOOLS_NEW 그대로 둡니다."
  printf '%s\n' "  🔴 **DB 는 자동으로 안 되돌립니다** — $AS_LAST_MIG 은 표를 **더하기만** 했으므로"
  printf '%s\n' "     옛 앱은 그 표를 쳐다보지도 않습니다. 남겨 두어도 해롭지 않습니다."
  printf '%s\n' "     🔴 그래도 물려야 하면 DROP TABLE IF EXISTS \"$BV_TABLE\"; 를 손으로 돌리고"
  printf '%s\n' "        **drizzle 의 기록도 함께** 지우세요 — 안 지우면 다시 올릴 때 건너뜁니다."
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
  printf '%s\n' "  🔴 ✗ 가 **$BV_TABLE 표가 없다**이면 **--migrate 를 한 번 더** 돌리세요"
  printf '%s\n' "     (다시 돌려도 안전합니다 — drizzle 이 이미 적용한 것은 건너뜁니다)."
  printf '%s\n' "     🔵 되돌려도 그 ✗ 는 안 고쳐집니다 — 표는 앱이 아니라 DB 에 있습니다."
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
