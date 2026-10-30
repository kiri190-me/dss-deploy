#!/bin/bash
# dss-deploy/nas/setup/49-deploy.sh — 마흔여섯째 배포 (2026-10-30)
#
# 🔴 NAS 에서 돈다. **DSM 터미널은 긴 명령을 잘라 먹는다**(2026-10-12 하루에 네
#    번 깨졌다). 그래서 손으로 치지 않고 **파일로 올려** 돌린다. 절차는 이렇다:
#      ① (개발 PC · PowerShell)
#           cd C:\Users\희만\Desktop\Development
#           scp -O dss-deploy\nas\setup\49-deploy.sh dss-nas:/volume1/dss/setup/
#           Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\49-deploy.sh
#      ② (NAS) md5sum /volume1/dss/setup/49-deploy.sh
#      ③ 🔴 **두 md5 가 같은지 눈으로 맞댄다.** 다르면 옮기다 잘린 것이다 —
#         그대로 돌리면 중간에서 끊긴 스크립트가 compose 를 고치다 만다.
#      🔵 이 파일은 돌 때 맨 위에서 **제 md5 를 스스로 찍는다.** ②를 따로 안
#         쳐도 로그에 남는다.
#    🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#    🔴 tar · scp 에 드라이브 문자(C:)를 주지 마라 — 원격 호스트로 읽는다.
#
# ── 사람이 실행한다 ───────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/49-deploy.sh            ← 읽기만 한다
#   (NAS)         bash /volume1/dss/setup/49-deploy.sh --count    ← 🔵 **올리기 전 수**
#   (NAS)         bash /volume1/dss/setup/49-deploy.sh --preload
#   (NAS)         bash /volume1/dss/setup/49-deploy.sh            ← 다시 --check
#   (NAS)         bash /volume1/dss/setup/49-deploy.sh --go       ⏱ 정지 창
#   (NAS)         bash /volume1/dss/setup/49-deploy.sh --count    ← 올린 뒤 수
#
#   🔵 **--count 를 앞에서도 돌릴 수 있다 — 48번과 다른 점이다.** 48번은 명령 셋이
#      그 판에 처음 생겨서 옛 도구(:7)로 부르면 Missing script 였다. 이번 판은
#      **:8 에도 셋이 다 있다**(48번이 올려 두었다). 그래서 앞뒤로 재어 **견줄 수**
#      있다. 🔴 아래 「--count 로 무엇을 보나」에 기대값을 적어 두었다.
#
# ── 갈아 끼우는 것 — **저장소 둘, 태그 셋** ───────────────────────────
#     ① A/S 앱   dss-as:4.1        → **dss-as:4.2**        커밋 3
#     ② A/S 도구 dss-as-tools:8    → **dss-as-tools:9**    커밋 3
#     ③ PO 앱    dss-po:0.8        → **dss-po:0.9**        커밋 3
#
#   🔵 **48번(지난 판)과 같은 모양이다** — 저장소 둘, 태그 셋.
#   🔴 **마이그레이션이 없다.** 두 저장소의 drizzle/ 이 각자의 기준 SHA 이후
#      **0건**이다(2026-10-30 재측정 — 49-build.sh 머리말에 명령과 결과를 적었다).
#      그래서 이 파일에는 **--migrate 모드가 없다** — DB 의 **구조**를 바꾸는
#      단계가 한 군데도 없다.
#   🔵 **나머지 여덟은 안 건드린다** — 통합 로그인 · 재고 · 게시판 · 계측기 ·
#      개선요청 · RF 이슈관리 · 휴가 · 통합 승인함. 여덟 모두 HEAD 가 기준 SHA
#      그대로다(2026-10-30 실측 — 49-build.sh 머리말에 SHA 를 하나씩 적었다).
#
# ── 🔴 기준 SHA — 두 출처를 맞대어 확인했다 ──────────────────────────
#   · **A/S 3851693** : README.md 의 「기준 SHA (2026-10-30 갱신)」 표가
#     | A/S 관리 | RF_Service_System | 4.1 | 3851693 | 이라고 적고, 48-build.sh
#     머리말의 A/S 범위 **마지막 줄**이 3851693 이다 — 48번이 구운 HEAD 다.
#   · **PO c32358f** : 같은 표가 | PO | dss-po | 0.8 | c32358f | 이라고 적고,
#     48-build.sh 머리말의 PO 범위가 c32358f 하나다.
#   🔵 둘 다 지시서의 값과 맞았다.
#
# ── 이 배포가 하는 일 — **납기요청일 ↔ 고객 요청 납기일을 양방향으로 묶는다** ─
#   A/S  3851693..ac3f713 (셋)
#     8ae38e3 납기요청일과 고객 요청 납기일을 양방향으로 묶는다
#     05e9806 출하 판정을 제 파일로 옮겨 고리 import 를 끊는다
#     ac3f713 PO 사본도 함께 옮겼다는 사실을 적는다
#   PO   c32358f..9c1b2ef (셋)
#     bfb2e95 뒤처진 사본을 A/S 판에 맞춘다 — 빌려 온 곳을 알리는 글자 셋
#     f9349d0 내자정리에서 고친 납기요청일이 수리 건까지 간다
#     9c1b2ef 출하 판정 사본도 shipment-finished 로 옮긴다
#
#   🔴 **지금까지는 한쪽이 비었을 때 상대 값을 「빌려 그릴」 뿐이었다.** 이제는
#      **저장할 때 상대 칸을 실제로 고친다.** A/S 는 두 방향 다, PO 는 「내자 →
#      수리 건」 한 방향이다(PO 에는 수리 건 화면도 mutation 도 없다).
#   🔵 **못 묶는 경우가 셋 있고, 셋 다 사람에게 알린다** — 저장 팝업(0.5초 뒤
#      저절로 닫힘)이 아니라 **읽어야 닫히는 알림**이다:
#        · 내자 줄이 여럿이거나 한 줄에 날짜가 여럿 → 어느 날짜인지 사람만 안다
#        · 내자에서 고친 날짜가 **수리 건의 인수일보다 이르다** → 수리 건 저장이
#          원래 거는 잣대를 우회하지 않는다
#   🔴 **행을 만들지도 지우지도 않는다**(그 커밋 본문). 비고가 적힌 행이 운영에
#      다섯 있어, 지우고 새로 만들면 비고가 말없이 사라진다.
#   🔵 **과거 건을 일괄로 묶지 않았다** — 운영 대량 변경이라 별도 승인 사항이다.
#      🔴 그래서 **이 배포만으로는 어긋난 수가 줄지 않는다.** 아래 --count 의
#         기대값이 그 사실에 기대고 있다.
#   🔵 **그 밖에 고리 import 를 끊었다** — isRepairCaseShipmentFinished 가
#      domain/notifications.ts 에서 **domain/shipment-finished.ts** 로 옮겼고 PO
#      사본도 따라 옮겼다. 🔵 **동작은 한 글자도 안 바뀐다.** 화면에서 보이는
#      변화가 없는 것이 **맞다**.
#   🔴 **저장된 글자를 이 배포가 바꾸지는 않는다.** 바꾸는 것은 그 뒤 사람이
#      저장할 때다. DB 의 **구조**는 한 글자도 안 건드린다.
#   🔵 **설정 이름도 안 는다.** 이 범위에 새 환경변수가 한 개도 없다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이번 판의 **핵심 위험** — PO 가 오늘 처음 repair_cases 에 쓴다
# ══════════════════════════════════════════════════════════════════════
#   dss-po/src/lib/db/mutations/domestic-orders.ts 가
#     select … from repair_cases … for update   (잠그고 읽는다)
#     update repair_cases set customer_requested_due_date, version, updated_at
#   를 **직접** 돌린다. 기준판(c32358f)에는 'update(repairCases)' 가 **0번**
#   나오고 지금 판에 **1번** 나온다(2026-10-30 git show 로 세어 확인).
#
#   🔴 **그 권한이 운영에 있는가를 짐작하지 않는다.** 이 저장소의 compose 사본은
#      app-po 에 dss_app(= dss_as 의 OWNER)을 주지만, **사본은 운영보다 뒤처진다** —
#      지금 사본은 아직 'image: dss-po:0.5' · 'dss-as:2.5' · 'dss-as-tools:1' 이라고
#      적는다(아홉 판까지 벌어진 적이 있다). 배포는 NAS 위 파일을 한 줄씩 고치고
#      돌아오지 않는다.
#   🔴 그래서 아래 **1-ㄷ 절**이 NAS 에서 **값으로** 묻는다. 「설정에 적혀 있나」가
#      아니라 「물어보니 쓸 수 있다고 하나」다:
#        ㄱ) **앱이 쓰는 길로** — dss-po 컨테이너 안에서 그 앱의 DATABASE_URL 로
#            붙어(같은 자격·같은 호스트·같은 DB) 이렇게 묻는다:
#              select current_user, current_database(), to_regclass($1)
#              select has_table_privilege(current_user,$1,$2)   -- $2 = UPDATE
#                   , has_table_privilege(current_user,$1,$3)   -- $3 = SELECT
#        ㄴ) 그 길이 막히면(postgres 모듈이 없거나 접속 실패) **psql 가지**로
#            넘어간다 — dss-po 에서 **역할 이름만** 뽑아(비밀번호는 안 꺼낸다)
#              select has_table_privilege(<역할>,'repair_cases','UPDATE')
#            를 dss-pg-app 안에서 묻는다. 권한은 역할에 달린 것이라 같은 답이다.
#   🔴 **실제로 UPDATE 를 돌리지 않는다.** 운영 자료다. 보내는 것은 select 뿐이다.
#   🔴 **「틀리면 안 되나」도 함께 잰다** — PO 는 **오늘도** repair_cases 를 읽고
#      있다(내자 정리 화면이 수리 건 정보를 보여 준다). 그러니 **select=1 은 반드시
#      참이어야** 한다. select 가 0 으로 나오면 그것은 「권한이 없다」가 아니라
#      **「내가 엉뚱한 것을 쟀다」**는 뜻이라, 그때는 ✗ 가 아니라 ? 로 센다.
#        · update=1 · select=1 → ✓
#        · update=0 · select=1 → 🔴 **✗. 올리지 마세요** (딱 두려워하던 그 상태다)
#        · select=0            → ? (검사 자신을 의심한다)
#   🔵 **--rollback 에서는 이 줄이 ? 다** — 되돌리면 PO 0.8 이고 그 판은 쓰지
#      않는다. 권한이 없어도 되돌리기는 막을 일이 아니다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 A/S 도구를 **왜 올리는가** — 48번과 **까닭이 다르다**
# ══════════════════════════════════════════════════════════════════════
#   48번은 **npm 명령이 셋 늘어서** 그것 하나로 구울 까닭이 섰다. 이번 판은
#   **package.json 이 0줄** 바뀌었다 — 그 잣대가 「굽는다」를 안 준다.
#   🔴 그래도 올린다. 까닭은 둘이다:
#     ㄱ) 🔴 **도구의 import 닫힘 안에 바뀐 파일이 일곱이다.**
#        닫힘은 package.json 의 scripts 가 가리키는 scripts/*.ts **전부**(+백필,
#        스물둘)에서 폈고 **223개**다(못 푼 상대경로 0). 48번의 222 에서 하나
#        늘었는데, 늘어난 그것이 이번에 **새로 생긴**
#        src/lib/domain/shipment-finished.ts 다.
#        겹친 일곱: repair-case-due-date-inverted-notifications.ts ·
#        repair-case-target-shipment-notifications.ts · due-date-inversion.ts ·
#        notifications.ts · requested-due-date-link.ts · shipment-finished.ts ·
#        repair-case-update-input.ts
#     ㄴ) 🔵 39번에 넓혀 둔 잣대(「tools 스테이지가 담는 것」)로도 **32 > 0** 이다.
#   🔵 **시작점을 백필 하나로 좁혀도 이번엔 0 이 아니다**(좁은 닫힘 164 · 겹침 2).
#      그래도 **좁혀서 재지 않는다** — 좁은 수는 다섯을 놓치고 그중 하나가
#      새로 생긴 파일이다. 「시작점을 하나로 두지 마라」(48번의 교훈)가 이번에도
#      **더 많은 참**을 준다.
#   🔵 **치르는 값**은 tar 하나(224MB)를 더 올리고 compose 의 image: 줄이 하나 더
#      달라지는 것뿐이다. tools-as 는 profiles: [tools] 라 **다시 뜨지도 않는다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔵 --count 로 무엇을 보나 — **기대값이 「안 바뀐다」다**
# ══════════════════════════════════════════════════════════════════════
#   세 도구를 읽기 전용으로 부른다:
#     check:target-shipment-missing   사내 목표 출하일 미등록 (48번이 올린 것)
#     check:due-date-inverted         납기 역전                (48번이 올린 것)
#     check:requested-due-date-sync   🔵 **이번에 더했다** — 두 날짜가 몇 건이나
#                                     어긋나 있나(묶기 전/후를 견주는 자)
#   🔴 **배포 자체는 이 수들을 안 바꾼다.** 과거 건을 일괄로 묶지 않았기 때문이다
#      (그 커밋 본문: 「과거 8건을 일괄로 묶지 않았다 — 운영 대량 변경이라 별도
#      승인 사항이다」). 그래서 **--go 앞뒤의 수가 같은 것이 정상**이다.
#      🔴 앞뒤가 다르면 전제가 깨진 것이다 — 그때는 사람이 봐야 한다.
#   🔵 그 뒤로는 **사람이 저장할 때마다 줄어야** 한다. 날마다 재 보면 묶기가
#      실제로 돌고 있는지 수로 보인다.
#   🔵 check:requested-due-date-sync 의 ⑦ 은 「덮인다」가 아니라 **「막힌다」**다 —
#      내자 날짜가 수리 건의 인수일보다 일러 저장이 거절되는 건의 수다. 그 수가
#      0 이 아니면 그 건들은 **사람이 손으로** 맞춰야 한다.
#   🔴 셋 다 **쓰는 모드가 없다** — INSERT·UPDATE·DELETE 가 한 줄도 없고
#      '--apply' 같은 깃발도 일부러 두지 않았다(세 도구의 머리말).
#
# ── 🔴 48번에서 고친 것을 그대로 가져왔다 — HTTP 판정에 303 ────────────
#   48번의 --go 7절이 '✗ dss-po 응답이 303' 을 냈다. 판정 줄이
#   grep -qE '200|30[127]' 이라 **303(See Other)이 목록에 없었다.**
#   'curl -w %{redirect_url}' 로 재니 303 -> /api/auth/sso/start — **로그인으로
#   넘기는 정상 응답**이었다. A/S 는 307, PO 는 303 으로 같은 일을 한다.
#   🔴 그래서 이 파일은 **30[1237]** 로 적는다. 「처음 도는 검사는 기대값이 틀릴
#      확률이 배포만큼 높다」가 정확히 그 자리였다.
#
# ── 🔴 47·48번에서 이어받은 것 ────────────────────────────────────────
#   ① 🔴 **1절이 「운영이 지금 쓰는 태그」를 통째로 찍는다.** 저장소 사본을
#      믿지 않는다 — 운영 파일과 **도는 컨테이너**에서 직접 읽는다.
#      🔴 compose 의 태그와 **실제로 도는 이미지**가 다를 수 있다(줄만 고치고
#         다시 안 띄운 경우). 그 둘을 **따로** 찍고 어긋나면 ? 로 센다.
#   ② 🔴 **치환 전에 그 줄의 낱말 수가 2 인지 본다.** 줄 끝에 주석이 붙어 있으면
#      **주석의 마지막 낱말**이 태그로 바뀌고 image: 값은 그대로 남는다
#      (48번이 가짜 compose 로 직접 재어 확인했다).
#   ③ 🔴 **달라진 image: 줄이 꼭 몇 개인지** 센다 — --go **3**(app-as·app-po·
#      tools-as) · --rollback **2**(앱 둘).
#   ④ 🔴 **설정 파일 검사**(중복 키 · auto). 값은 한 글자도 안 찍는다.
#   ⑤ 🔵 연락서 폴더 검사 · 재고 관리 통로 검사는 **42~48번 것 그대로다.**
#      🔴 **빼지 않는다** — 한 번 빼면 다시 넣는 사람이 없다.
#   ⑥ 🔵 **--rollback 은 앱 둘만 되돌린다.** 도구는 :9 그대로 둔다 —
#      39·41~48번과 같은 판단이다(새 도구가 있는 편이 낫다. 그 도구들은 전부
#      읽기 전용이고, 백필은 '--apply' 없이는 DB 에 한 글자도 안 쓴다).
#   ⑦ 🔵 **다시 띄우는 것은 app-as · app-po 둘뿐이다.** tools-as 는
#      'profiles: [tools]' 라 평소에 뜨지 않는다.
#   ⑧ 🔴 **DB 둘의 StartedAt 을 앞뒤로 비교한다** — 안 멈췄다는 증거다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 설정 파일 — **.env 와 env/*.env 를 둘 다 본다** (48번에서 가져왔다)
# ══════════════════════════════════════════════════════════════════════
#   ㄱ) 🔴 **같은 이름이 두 줄 있으면 아래가 이긴다.** 하루에 네 번 난 적이
#      있고, 원인은 늘 「위를 고치고 아래에 또 적었다」였다. 그러면 고친 줄이
#      **아무 일도 안 한다.** 그래서 세 파일의 **중복 키를 센다.**
#      🔴 **값은 한 글자도 안 찍는다. 이름만 찍는다.**
#   ㄴ) 🔴 **컨테이너 안에서 'auto' 는 172.x 가 된다.** SSO_ISSUER ·
#      SSO_REDIRECT_URI 가 'auto' 면 로그인이 돌아오지 못한다. 둘이 **있고,
#      'auto' 가 아닌지**를 잰다. 값은 안 찍고 fixed/auto 두 글자만 찍는다.
#      🔵 지금 운영은 이미 로그인이 되고 있으니 fixed 일 것이다. **그래도
#         짐작하지 않는다** — ✓ 쪽 오판은 영영 안 드러난다.
#
# ── 🔴 개발 PC → NAS 로 올릴 것 — **둘** ───────────────────────────────
#   ㄱ) 이미지 tar **셋** → /volume1/dss/images/
#        dss-as-4.2.tar · dss-as-tools-9.tar · dss-po-0.9.tar
#   ㄴ) 이 파일 → /volume1/dss/setup/
#
#   (개발 PC · PowerShell)
#     cd C:\Users\희만\Desktop\Development\_images-46
#     scp -O dss-as-4.2.tar dss-as-tools-9.tar dss-po-0.9.tar dss-nas:/volume1/dss/images/
#     cd C:\Users\희만\Desktop\Development
#     scp -O dss-deploy\nas\setup\49-deploy.sh dss-nas:/volume1/dss/setup/
#     Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\49-deploy.sh
#
# ── 모드 다섯 ─────────────────────────────────────────────────────────
#   (기본)   --check      아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --preload             tar 셋을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --go                  compose 의 image: 줄 **셋**을 바꾸고 앱 둘을 다시 띄운다
#   --rollback            앱 둘만 옛 판으로 되돌린다 (도구는 :9 그대로)
#   --count               🔵 세 도구를 **읽기만** 해서 센다 (--go 앞뒤 둘 다 가능)
#
#   🔴 차례:  --check → --count(앞) → --preload → --check → --go → --count(뒤)
#
# ── 🔴 --check 도 「아무것도 안 한다」는 아니다 ───────────────────────
#   A/S DB 에 **select** 를 몇 번 보낸다(마이그레이션 수 · PO 의 권한 — 바꾸는
#   문장은 없다). 앱 둘의 주소에 GET 을 한 번씩 보낸다. 재고 관리 통로에도
#   **GET 을 한 번** 보낸다(읽기만 한다). 도구 이미지가 이미 실려 있으면
#   **안을 보려고 컨테이너를 잠깐 띄웠다 지운다**(docker run --rm, DB 에는 안
#   닿는다 — DATABASE_URL 을 안 주고 부른다).
#   「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 쓴 뒤 grep 으로 세었다.
#   ② 읽기 전용 자리에 콜론 하나와 꺾쇠로 빈 파일을 만들면 NAS 의 ash 가 셸을
#      그 자리에서 끝낸다(2026-10-12 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   🔴 19·20·21번에는 그 둘이 아직 남아 있다. **거기서 베껴 오지 마라.**
#
# ── 🔴 비밀값을 찍지 않는다 ───────────────────────────────────────────
#   설정 파일은 **이름이 있는가/없는가**와 **auto 인가**만 본다. 값도, 값의
#   길이도 찍지 않는다. 🔴 PO 권한 검사는 DATABASE_URL 에서 **역할 이름만**
#   꺼낸다(dss_app 같은 것 — 이미 저장소의 compose 사본에 적혀 있는 값이다).
#   비밀번호는 꺼내지도 찍지도 않는다. 재고 관리 검사도 토큰을 **쓰기만** 한다.
#   🔴 그리고 **한글을 HTTP 머리말·argv 에 넣지 않는다** — 넣으면 요청이 아예 안
#      나가고, 그 ✗ 가 진짜 결함처럼 보인다(하필 보안 검사에서 그랬다).
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v46-$STAMP

# ══ 이번에 다시 띄우는 것 — 앱 **둘** ═════════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
SITES='
as|app-as|dss-as|dss-as:4.2|dss-as:4.1|dss-as-4.2.tar|13000
po|app-po|dss-po|dss-po:0.9|dss-po:0.8|dss-po-0.9.tar|13600
'
# 🔵 7절의 재고 관리 검사가 명령을 넣을 상자. 위 표 셋째 칸과 같은 이름이다.
AS_APP_CN=dss-as
# 🔴 1-ㄷ 절의 권한 검사가 명령을 넣을 상자. 위 표 셋째 칸과 같은 이름이다.
PO_APP_CN=dss-po
# ══ 🔴 A/S 도구 — **이번에 갈아 끼운다.** up -d 로 다시 띄우지 않는다 ═══
AS_TOOLS_SVC=tools-as
TOOLS_OLD=dss-as-tools:8
TOOLS_NEW=dss-as-tools:9
IMG_MIGDIR=/app/drizzle
MIGDIR=$D/as-migrations

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

# ══ 🔴 tar 셋의 지문 — [배포본] 49-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 안 채웠다.** 49-build.sh --go 가 끝에 찍어 주는 **세 줄**로 아래
#      세 줄을 통째로 갈아 끼우세요.
#      (비어 있으면 3절이 **? 로 센다** — 「옮기다 깨진 것」은 잡지만 「개발 PC 에서
#      구운 그것이 맞나」는 못 본다. ? 는 통과로 안 세므로 --preload 가 막힌다.)
#   🔵 이름만이라도 적어 두는 까닭: 줄이 아예 없으면 4절(--preload)이 **아무것도
#      안 싣고 조용히 끝난다.** 이름이 있으면 싣기는 제대로 된다.
TARS='
dss-as-4.2.tar|132637696|9e1636d6581f07214ea8aa2dd2e49fa2|sha256:30f3c927e2cafc0808f8df08c34cc67a42c263aae4a023353b58b49b3a102579
dss-as-tools-9.tar|223837696|54195c04c2379dc73846ab5c6c25dd4e|sha256:cbe4f6ab27aaab6549d0acb66205a8dbcb09d2f4d8a51340ba5f317b6ae9c6ca
dss-po-0.9.tar|95437824|dc8f9a174feed549b784ca7551bcc899|sha256:bc4e1d99f79c3bcd5dee73e002bd61c2508870d4cc5b14cdc921f3708f051c12
'
tar2tag() {
  case "$1" in
    dss-as-4.2.tar)      printf 'dss-as:4.2' ;;
    dss-as-tools-9.tar)  printf 'dss-as-tools:9' ;;
    dss-po-0.9.tar)      printf 'dss-po:0.9' ;;
  esac
}

# ══ 🔴 DB 는 **구조가 그대로여야** 한다(마이그레이션 0건) ═════════════
#   🔵 A/S 와 PO 는 **같은 dss_as** 를 본다(PO 는 제 DB 가 없다). 그래서 재는
#      자리도 하나다.
AS_BOX=dss-pg-app; AS_DB=dss_as; AS_KEEP=121   # [저장소] 49-build.sh 4절과 같다
# 🔴 이번 판에 PO 가 쓰기 시작하는 표. 1-ㄷ 절이 이 이름으로 권한을 묻는다.
#    🔴 **ASCII 다** — 한글을 argv 로 넘기면 깨지는 길이 열린다.
PO_WRITE_TABLE=repair_cases
# 🔵 안 건드리는 **여덟** — 「옆으로 안 샜다」는 증거로 센다.
KEEP_BOXES="dss-auth dss-inventory dss-meters dss-board dss-improvements dss-leave dss-approvals dss-rf-trouble"
# 🔵 DB 둘은 멈추지 않는다 (애초에 up -d --no-deps 가 앱 둘만 건드린다)
KEEP_DB="dss-pg-app dss-pg-auth"

MODE=check
case "${1:-}" in
  --check|"")  MODE=check ;;
  --preload)   MODE=preload ;;
  --go)        MODE=go ;;
  --rollback)  MODE=rollback ;;
  --count)     MODE=count ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --preload · --go · --rollback · --count\n' "$1"; exit 2 ;;
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

dc()  { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas "$@" ); }
dct() { ( cd "$D/deploy" && "$DOCKER" compose -f "$CF" --env-file .env.nas --profile tools "$@" ); }

[ "$(id -u)" = 0 ] || { printf '먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요.\n'; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/49-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "마흔여섯째 배포 — A/S 앱·도구 + PO 앱   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  🔴 개발 PC 의 Get-FileHash 값과 **같은지 눈으로 맞대세요** (DSM 터미널이 긴 것을 잘라 먹습니다)"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  로그: $LOG"
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
#    줄 끝에 주석이 붙어 있으면(예: 'image: dss-x:1.0   # 2026-10-22 에 올림')
#    **주석의 마지막 낱말**이 태그로 바뀌고 image: 값은 그대로 남는다 —
#    48번이 가짜 compose 로 직접 재어 확인했다. 그러면 compose 가 옛 이미지로
#    뜨면서 파일만 망가진다. 그 자리를 치환 **전에** 막는다.
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
pgq() { # 1 상자 2 DB 3 SQL
  "$DOCKER" exec -i "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -X -tAq -c \"$3\"" 2>/dev/null | head -1 | tr -d ' \r'
}
pgn() { local v; v=$(pgq "$1" "$2" "$3"); isnum "$v" && printf '%s' "$v"; }
mig_count() { pgn "$1" "$2" 'select count(*) from drizzle.__drizzle_migrations'; }

# ══ 🔴 설정 파일 — 중복 키와 auto (값은 한 글자도 안 찍는다) ══════════
#   🔴 **「비면 OK」 자리를 만들지 않는다.** 파일이 없거나 키가 0개면 그것은
#      「중복이 없다」가 아니라 **「못 쟀다」**다 — ? 로 센다.
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

# ══════════════════════════════════════════════════════════════════════
# 🔴 PO 가 repair_cases 에 **쓸 수 있는가** — 이번 판의 핵심 위험
# ══════════════════════════════════════════════════════════════════════
#   🔴 **앱이 쓰는 길로 잰다.** dss-po 컨테이너 안에서 그 앱의 DATABASE_URL 로
#      붙는다 — 같은 자격 · 같은 호스트 · 같은 DB 다.
#   🔴 **보내는 것은 select 뿐이다.** UPDATE 를 실제로 돌리지 않는다. 운영 자료다.
#   🔴 **비밀번호를 꺼내지도 찍지도 않는다.** 찍는 것은 역할 이름 · DB 이름 ·
#      0/1 두 개뿐이고, 역할 이름은 이미 저장소의 compose 사본에 적혀 있는 값이다.
#   🔴 **작은따옴표를 한 글자도 안 쓴다** — 이 문자열이 셸의 작은따옴표 안에
#      들어가기 때문이다. SQL 문자열은 전부 **자리표($1·$2·$3)** 로 넘긴다.
#   🔵 to_regclass 가 null 이면 「표가 없다」다. has_table_privilege 를 그 상태로
#      부르면 오류로 죽으므로 **먼저 표가 보이는지** 묻고 가른다.
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
  # 🔵 울타리가 좁은 것은 일부러다. 빼기표가 든 역할 이름(dss-app 같은 것)은
  #    SQL 에서 따옴표로 감싸야 하고, 그 인용이 이 겹겹의 따옴표 안에서 꼬이기
  #    쉽다. 운영 역할은 dss_app 이라 걸리지 않는다. 혹시 걸려도 **✓ 쪽으로
  #    기울지 않는다** — 「못 쟀다」가 되고, --go 에서는 그것이 ✗ 다.
  case "${role:-}" in
    ''|*[!A-Za-z0-9_]*) return 0 ;;
  esac
  u=$(pgq "$AS_BOX" "$AS_DB" "select has_table_privilege('$role','$PO_WRITE_TABLE','UPDATE')")
  s=$(pgq "$AS_BOX" "$AS_DB" "select has_table_privilege('$role','$PO_WRITE_TABLE','SELECT')")
  [ -n "${u:-}" ] || return 0
  printf 'PSQL role=%s update=%s select=%s' "$role" "${u:-?}" "${s:-?}"
}

# 🔴 level: block(✗ 로 다 막는다) · warnmiss(권한 없음만 ✗ · 못 쟀으면 ?) · soft(전부 ?)
po_write_privilege_check() { # 1 block|warnmiss|soft
  local level out line who db upd sel pl pu ps
  level=${1:-warnmiss}
  printf '\n    ── 🔴 PO 가 %s 에 **쓸 수 있는가** (이번 판의 핵심 위험)\n' "$PO_WRITE_TABLE"
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
      # 🔴 「틀리면 안 되나」쪽 — PO 는 오늘도 그 표를 **읽고** 있다. SELECT 가
      #    0 이면 권한 문제가 아니라 **내가 엉뚱한 것을 쟀다**는 뜻이다.
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
        hm "PO 가 $PO_WRITE_TABLE 에 **못 쓴다**(UPDATE=0) — 🔵 되돌리기는 막지 않는다(PO 0.8 은 안 쓴다)"
      else
        bad "🔴 PO 가 $PO_WRITE_TABLE 에 **못 쓴다**(UPDATE=0) — 이대로 올리면 PO 에서 납기요청일을 저장할 때마다 오류로 끝난다"
        say "🔴 고칠 자리: 운영 compose 의 app-po 블록 DATABASE_URL 이 가리키는 역할."
        say "   저장소 사본은 dss_app(= $AS_DB 의 OWNER)을 주지만 **사본은 운영보다 뒤처진다.**"
        say "   🔴 권한을 여는 일은 이 스크립트가 하지 않는다 — 사람이 정하고 사람이 한다."
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
        bad "🔴 PO 의 역할이 $PO_WRITE_TABLE 에 **못 쓴다**(psql 가지 · UPDATE=f) — 이대로 올리면 PO 의 납기요청일 저장이 오류로 끝난다"
        doubt
      fi
      return ;;
  esac
  # ── 두 길 다 못 쟀다. **「비면 OK」로 흘리지 않는다.**
  if [ "$level" = block ]; then
    bad "🔴 PO 의 $PO_WRITE_TABLE 쓰기 권한을 **두 길 다 못 쟀다** — 이 판의 핵심 위험이라 모르는 채로 올리지 않는다"
    say "🔴 $PO_APP_CN 가 도는지, 그 안에서 node 가 도는지, $AS_BOX 가 도는지 보세요."
    doubt
  else
    hm "PO 의 $PO_WRITE_TABLE 쓰기 권한을 **두 길 다 못 쟀다** — 🔴 --go 전에 반드시 다시 재세요"
    say "🔴 --go 에서는 이 줄이 ✗ 다. 모르는 채로 올리지 않는다."
  fi
}

# ══ 🔴 재고 관리 통로가 **값을 돌려주는가** (45~48번 것을 글자 그대로) ══
#   🔴 **빼지 않는다.** 이것은 **앱**이 쓰는 길이다. 45번이 운영에서
#      'HTTP 200 rows 319' 를 받은 바로 그 검사다.
#   🔴 「설정이 적혀 있다」가 아니라 **「물어보니 답한다」**로 잰다.
#   🔵 **읽기만 한다.** GET /api/v1/parts 한 번이고, 저쪽 DB 에도 A/S DB 에도
#      한 글자 안 쓴다. 토큰은 쓰기만 하고 **찍지 않는다.**
#   🔵 **이번 판은 재고 관리와 무관하다** — 그래도 뺄 자리가 아니다. 이 통로가
#      막히면 [사용부품] 칸과 [고장 부품] 그래프의 반출 몫이 통째로 빠진다.
#   🔴 **머리말에 한글을 안 넣는다.** 받는 답도 일부러 ASCII 로만 찍게 했다.
#     NOCONF base=0 token=1   설정이 비었다
#     HTTP 200 rows 319       물어봤고 답이 왔다
#     FAIL timeout            못 닿았다
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

# 🔴 **단계마다 기대값이 아니라 '엄함'이 다르다.** --check 에서는 ? 로만 센다 —
#    아직 안 갈아 끼웠으니 그 자리에서 배포를 막을 일이 아니고, ✗ 로 세면 4·5절의
#    문이 닫혀 멀쩡한 교체까지 막는다. --go 에서는 ✗ 다 — 그때는 **사람이 실제로
#    막혀 있는 상태**이기 때문이다.
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
#   🔴 **「✗ 가 아니면 ✓」로 세지 않는다.** ✓ 조건만 정확히 적고 나머지는 ? 다 —
#      ✓ 쪽 오판은 영영 안 드러난다.
tools_inside_check() {
  local v got c
  printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TOOLS_NEW"
  # ① runner 가 아니라 tools 인가 — runner 에는 /app/package.json 이 없다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/package.json: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "tools 스테이지가 맞다" \
    || { bad "🔴 /app/package.json 이 없다 — **runner 를 구웠다.**"; doubt; }
  # ② 🔴 **npm 명령 셋이 이미지 안 package.json 에 있는가.** 41번의 자리다.
  #    🔵 이번 판에 명령이 안 늘었다 — 그래도 **사라지지 않았는지**는 봐야 한다.
  #    🔴 이름은 전부 ASCII 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "3" ] && ok "npm 명령 셋이 이미지 안에 있다" \
    || { bad "🔴 명령이 ${got:-0}/3 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다.** 부르는 날 Missing script 가 난다"; doubt; }
  # ③ 🔴 **닫힘 안에서 바뀐 일곱이 다 담겼는가.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/src/lib/db/queries/repair-case-due-date-inverted-notifications.ts /app/src/lib/db/queries/repair-case-target-shipment-notifications.ts /app/src/lib/domain/due-date-inversion.ts /app/src/lib/domain/notifications.ts /app/src/lib/domain/requested-due-date-link.ts /app/src/lib/domain/shipment-finished.ts /app/src/lib/validation/repair-case-update-input.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "7" ] && ok "닫힘 안에서 바뀐 일곱이 다 들어 있다" \
    || { bad "🔴 일곱 중 ${got:-0}개만 들어 있다 — src/ 가 온전히 안 담겼다"; doubt; }
  # ④ 🔵 48번이 올린 도구 넷 — **빼지 않는다.** 이번 판에 안 바뀌었지만 있어야 부른다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "4" ] && ok "48번이 올린 도구 넷이 다 들어 있다" \
    || bad "🔴 도구 파일이 ${got:-0}/4 개다 — scripts/ 가 온전히 안 담겼다"
  # ⑤ 백필 도구 파일 셋 — 43~48번 것 그대로. **빼지 않는다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts /app/scripts/lib/kyosan-used-parts-backfill-plan.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "3" ] && ok "백필 도구 파일 셋이 다 들어 있다" \
    || bad "🔴 백필 도구 파일이 ${got:-0}/3 개다 — scripts/ 가 온전히 안 담겼다"
  # ⑥ 🔴 **그 src/ 가 '이번 판' 인가 — 글자로 센다.** ③ 은 「있나」만 본다.
  #    🔵 shipment-finished.ts 는 **이번 판에 새로 생긴 파일**이라 ③ 이 이미
  #       갈라 주지만, 나머지 셋은 **옛날부터 있던 파일**이라 ③ 이 통과해도 낡은
  #       판이 담길 수 있다. 그 자리를 막는 것이 이 단계다.
  #    🔵 넷 다 기준 3851693 판에는 **0번** 나오고 지금 판에는 나온다
  #       (2026-10-30 git show 로 파일마다 세어 확인: 0→2 · 0→7 · 0→1 · 0→1).
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for pair in "shipment-finished /app/src/lib/domain/due-date-inversion.ts" "shipment-finished /app/src/lib/domain/notifications.ts" "requestedDueDateLink /app/src/lib/validation/repair-case-update-input.ts" "resolveRepairCaseDueDateWriteThrough /app/src/lib/domain/requested-due-date-link.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1 $2"; else echo "no  $1 $2"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "4" ] && ok "이번 판의 이름 넷이 이미지 안에 있다 (옛 src/ 가 아니다)" \
    || { bad "🔴 이번 판의 이름이 ${got:-0}/4 개다 — **옛 src/ 가 담긴 이미지다.** 올리지 마세요"; doubt; }
  # ⑦ tsx 가 있는가 — 이 도구는 tsx 로만 돈다(운영 이미지에는 없는 devDependency다).
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/node_modules/tsx: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "tsx 가 있다" \
    || bad "🔴 tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다"
  # ⑧ 🔴 **값으로 받아 본다 — 명령 둘을 npm 으로 실제로 부른다.**
  #    DATABASE_URL 을 안 준다. 두 파일이 1줄에서 './load-env' 를, 그 다음 줄에서
  #    '../src/lib/db/connection' 을 정적 import 하고 connection.ts 가 모듈 맨
  #    위에서 동기적으로 던진다. **DB 에는 한 글자도 안 닿는다.**
  #    🔴 'node …' 가 아니라 **'npm run …'** 으로 부르는 것이 중요하다 —
  #       41번의 실패 모양이 'npm error Missing script' 였고, node 로 직접
  #       부르면 그 실패가 **영영 안 드러난다.**
  #    🔵 48번은 하나만 불렀다. 이번 판은 **둘**을 부른다 —
  #       check:requested-due-date-sync 가 --count 에 새로 들어가므로 그 명령이
  #       서는지를 여기서 미리 본다.
  for c in check:due-date-inverted check:requested-due-date-sync; do
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
  # ⑨ 🔵 백필도 여전히 서는가 — 43~48번이 재던 그 줄이다. **빼지 않는다.**
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
#   🔵 1절은 compose 에 줄이 있는지만 본다. 줄은 있는데 안 열리는 것이 제일
#      조용한 실패라 여기서 **수를 받아** 본다. 보내는 명령은 ls 뿐이다.
#   🔵 **이번 판도 백필을 안 돌리므로 여기서 ✗ 가 나도 이 배포의 일은 끝난 것이다.**
#      다음에 연락서를 이식할 때 막히지 않게 지금 재 두는 것이다.
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
    say "   연락서를 이식할 때만 필요한 폴더다. compose 의 $AS_TOOLS_SVC 볼륨을"
    say "   고치고 이 절만 다시 재면 된다."
  fi
}

# ══════════════════════════════════════════════════════════════════════
# ── --count : 세 도구를 읽기만 해서 센다 ──────────────────────────────
# ══════════════════════════════════════════════════════════════════════
#   🔵 **--go 앞뒤로 다 돌 수 있다.** 세 명령은 :8 에도 :9 에도 있다(48번이
#      올려 두었다). 그래서 **앞에서 한 번, 뒤에서 한 번** 재어 견주는 것이
#      이번 판의 쓰임이다.
#   🔴 **기대값은 「앞뒤가 같다」**다 — 이 배포는 과거 건을 일괄로 묶지 않는다.
#      앞뒤가 다르면 전제가 깨진 것이니 사람이 봐야 한다.
#   🔴 이 셋은 **읽기 전용이다** — INSERT·UPDATE·DELETE 가 한 줄도 없고
#      '--apply' 같은 깃발도 일부러 두지 않았다(세 도구의 머리말).
#   🔵 찍히는 것은 접수번호와 날짜까지다. 고객사·L/N·S/N 은 조회가 애초에 안 읽는다.
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
    say "🔵 이번 판에는 :8 에도 :9 에도 셋이 다 있어야 한다 — 48번이 올려 두었다."
    say "🔴 그러니 이 답은 **예상 밖**이다. compose 의 $AS_TOOLS_SVC 태그를 보세요."
    return
  fi
  if [ -z "${out:-}" ]; then
    hm "$2 — 아무것도 안 돌아왔다. **빈 결과는 삼켜진 오류일 수 있다** — 사람이 보세요"
    return
  fi
  printf '%s\n' "$out" | sed 's/^/      /'
  # 🔴 「글자가 보이나」가 아니라 **종료 코드**로 가른다. 세 도구는 세는 길과
  #    뜨는 길이 갈라지면 **찍지 않고 0 이 아닌 값으로 멈춘다**(그 머리말).
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
  # 🔵 어느 도구 이미지로 세고 있는지 로그에 남긴다 — --go 앞뒤의 수를 견줄 때
  #    「같은 것으로 쟀나」가 먼저 궁금해진다. 못 읽으면 못 읽었다고 적는다.
  CTL=$(img_line "$AS_TOOLS_SVC")
  if [ -n "${CTL:-}" ]; then
    printf '%s\n' "🔵 지금 compose 의 $AS_TOOLS_SVC 태그: $(tag_at "$CTL")  (${CTL}줄)"
  else
    printf '%s\n' "🔴 compose 에서 $AS_TOOLS_SVC 의 image: 줄을 못 찾았다 — 아래 수가 어느 판인지 모른다"
  fi
  printf '%s\n' "🔴 **기대값은 「--go 앞뒤가 같다」**입니다 — 이 배포는 과거 건을 일괄로 묶지 않습니다."
  count_one check:target-shipment-missing "사내 목표 출하일 미등록"
  count_one check:due-date-inverted       "납기 역전"
  count_one check:requested-due-date-sync "납기요청일 ↔ 고객 요청 납기일 어긋남 (이번 판이 묶는 것)"
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  printf '%s\n' "🔵 셋째 도구의 ⑦ 은 「덮인다」가 아니라 **「막힌다」**입니다 — 내자 날짜가"
  printf '%s\n' "   수리 건의 인수일보다 일러 저장이 거절되는 건입니다. 0 이 아니면 그 건들은"
  printf '%s\n' "   **사람이 손으로** 맞춰야 합니다(화면이 그때마다 읽어야 닫히는 알림을 띄웁니다)."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 1. 지금 상태 ──────────────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
[ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
say "compose 줄 수 $(wc -l < "$CF") · image: 줄 $(grep -c '^ *image:' "$CF")개"

# ── ㄱ) 🔴 **운영이 지금 쓰는 태그 전부** — 저장소 사본을 믿지 않는다 ──
#   이 저장소의 compose 사본은 운영보다 뒤처진다(아홉 판 차이가 난 적이 있고,
#   지금도 사본에는 'image: dss-po:0.5' · 'dss-as:2.5' · 'dss-as-tools:1' 이라고
#   적혀 있다). 배포는 NAS 위 파일을 한 줄씩 고치고 돌아오지 않는다. 그래서
#   **여기서 직접 읽어 로그에 남긴다.**
printf '\n    ── 운영 compose 의 image: 줄 전부 (이 파일이 진짜다)\n'
grep -n '^ *image:' "$CF" | sed 's/^/      /'
printf '\n    ── 지금 **도는** 컨테이너와 그 이미지 (compose 와 다를 수 있다)\n'
"$DOCKER" ps -a --format '{{.Names}} {{.Image}} {{.Status}}' 2>/dev/null | sort | sed 's/^/      /'

for r in $(rows); do
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  printf '\n    ── %s\n' "$SVC"
  L=$(img_line "$SVC") || { bad "$SVC — compose 에서 image: 줄을 못 찾았다"; continue; }
  CUR=$(tag_at "$L")
  ST=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  say "$SVC — ${L}줄 · compose ${CUR} · 도는 것 ${RUN:-없음} (${ST:-?})"
  case "$MODE" in
    rollback)
      # 🔵 되돌릴 때는 새 판이 서 있어야 정상이다. 기대값이 모드마다 다르다.
      if [ "$CUR" = "$NEW" ]; then ok "$SVC 가 $NEW 다 (되돌릴 준비)"
      elif [ "$CUR" = "$OLD" ]; then hm "$SVC 가 이미 $OLD 다 (벌써 되돌렸나)"
      else bad "$SVC 의 태그가 $CUR 다 — 옛 판도 새 판도 아니다. 멈추고 알릴 것"; doubt; fi ;;
    *)
      if [ "$CUR" = "$OLD" ]; then ok "$SVC 가 옛 판 $OLD 다 (갈아 끼울 준비)"
      elif [ "$CUR" = "$NEW" ]; then hm "$SVC 가 이미 $NEW 다 (다시 돌리는 중인가)"
      else
        bad "$SVC 의 태그가 $CUR 다 — $OLD 도 $NEW 도 아니다. 멈추고 알릴 것"
        say "🔴 **이 저장소의 compose 사본을 믿고 적은 값이 아니다** — 49-build.sh 머리말이"
        say "   README 의 기준 SHA 표와 48번 머리말을 맞대어 얻은 값이다. 그래도 어긋났다면"
        say "   운영이 그 사이 따로 움직였다는 뜻이다. **고치지 말고 알리세요.**"
        doubt
      fi ;;
  esac
  # 🔴 **compose 의 태그와 실제로 도는 이미지가 같은가** — 줄만 고치고 다시 안
  #    띄운 경우가 있다. 그때는 교체가 「아무 일도 안 한 것처럼」 보인다.
  if [ -z "${RUN:-}" ]; then
    hm "$CN 가 안 뜬 것 같다 — Config.Image 를 못 읽었다"
  elif [ "$RUN" = "$CUR" ]; then
    ok "$CN 가 compose 에 적힌 그 태그로 돈다 ($RUN)"
  else
    hm "$CN 는 $RUN 로 도는데 compose 는 $CUR 라고 적는다 — 줄만 고치고 안 띄운 상태다"
    say "🔵 **교체를 막지 않는다** — --go 가 어차피 다시 띄운다. 다만 되돌릴 때 기준이 흔들린다."
  fi
done

# ══ 🔴 A/S 도구 — **이번엔 이 배포가 고치는 줄이다** ═════════════════
printf '\n    ── %s\n' "$AS_TOOLS_SVC"
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  say "$AS_TOOLS_SVC — ${TL}줄 · $TCUR"
  case "$MODE" in
    rollback)
      # 🔵 되돌려도 도구는 :9 그대로 둔다(머리말 ⑥). 그래서 기대값이 새 판이다.
      [ "$TCUR" = "$TOOLS_NEW" ] && ok "$AS_TOOLS_SVC 가 $TOOLS_NEW 다 (🔵 되돌려도 도구는 그대로 둔다)" \
        || hm "$AS_TOOLS_SVC 가 $TCUR 다 — 🔵 되돌리기를 막지 않는다" ;;
    *)
      if [ "$TCUR" = "$TOOLS_OLD" ]; then ok "$AS_TOOLS_SVC 가 $TOOLS_OLD 다 (고칠 준비 — --go 가 $TOOLS_NEW 로 고친다)"
      elif [ "$TCUR" = "$TOOLS_NEW" ]; then hm "$AS_TOOLS_SVC 가 이미 $TOOLS_NEW 다 (다시 돌리는 중인가)"
      else bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $TOOLS_OLD 도 $TOOLS_NEW 도 아니다. 멈추고 알릴 것"; doubt; fi ;;
  esac
  # 🔴 볼륨이 제 자리에 붙는가 — 여기가 어긋나면 **다음 마이그레이션이 엉뚱한 것을 읽는다.**
  if svc_block "$AS_TOOLS_SVC" | grep -q "$MIGDIR:$IMG_MIGDIR"; then
    ok "$AS_TOOLS_SVC 가 $MIGDIR 를 $IMG_MIGDIR 로 붙인다 (안 건드렸다)"
  else
    bad "🔴 $AS_TOOLS_SVC 의 drizzle 볼륨이 $MIGDIR 가 아니다 — 이 배포가 건드릴 자리가 아닌데 어긋났다"
  fi
  # 🔴 42번에서 넣은 검사다. **없어도 교체를 막지 않는다** — 그래서 ✗ 가 아니라
  #    ? 로 센다(✗ 는 4·5절의 문을 닫아 멀쩡한 교체까지 막는다).
  for kv in "$KYO_SRC" "$KYO_CONV"; do
    if svc_block "$AS_TOOLS_SVC" | grep -q "$kv"; then
      ok "$AS_TOOLS_SVC 에 $kv 볼륨 줄이 있다 (연락서를 이식할 때 읽을 자리)"
    else
      hm "$AS_TOOLS_SVC 에 $kv 볼륨 줄이 **없다** — 🔵 교체는 막지 않는다"
      say "🔴 **이대로면 다음 연락서 이식이 못 돈다.** compose 의 $AS_TOOLS_SVC 에 그 줄을 먼저 넣으세요."
    fi
  done
else
  bad "compose 에 $AS_TOOLS_SVC 가 없다 — 올릴 자리가 없다"
fi

# ══ 🔴 PO 쪽 — **도구 서비스가 없는 것이 맞다** ═══════════════════════
#   짐작으로 「없다」고 적지 않는다. 생겼으면 이 줄이 알려 준다.
if img_line tools-po >/dev/null 2>&1; then
  hm "compose 에 tools-po 가 **생겼다** — 지금까지 없던 것이다. 이 배포의 범위 밖이니 사람이 보세요"
else
  ok "compose 에 tools-po 가 없다 (없는 것이 맞다 — PO 에는 NAS 에서 돌릴 스크립트가 없다)"
fi

# ── 1-ㄴ. 🔴 설정 파일 — 중복 키와 auto (값은 안 찍는다) ──────────────
printf '\n    ── 설정 파일 (이름만 본다. 값도, 값의 길이도 안 찍는다)\n'
env_file_check "$ENV_NAS" ".env.nas"
env_file_check "$ENV_AS"  "env/as.env"
env_file_check "$ENV_PO"  "env/po.env"
env_auto_check "$ENV_AS" "env/as.env" SSO_ISSUER
env_auto_check "$ENV_AS" "env/as.env" SSO_REDIRECT_URI
env_auto_check "$ENV_PO" "env/po.env" SSO_ISSUER
env_auto_check "$ENV_PO" "env/po.env" SSO_REDIRECT_URI
say "🔵 **이 판은 설정을 하나도 안 바꾼다** — 새 환경변수가 한 개도 없다."

# ── 1-ㄷ. 🔴 **PO 가 repair_cases 에 쓸 수 있는가** — 이 판의 핵심 위험 ─
#   🔴 **단계마다 엄함이 다르다**(기대값이 아니라 엄함이다):
#      · --go        : 못 쓰면 ✗ · **못 쟀어도 ✗**(모르는 채로 올리지 않는다)
#      · --check/--preload : 못 쓰면 ✗ · 못 쟀으면 ?(그 자리에서 막을 일은 아니다)
#      · --rollback  : 전부 ? (되돌리면 PO 0.8 이고 그 판은 안 쓴다)
case "$MODE" in
  go)       po_write_privilege_check block ;;
  rollback) po_write_privilege_check soft ;;
  *)        po_write_privilege_check warnmiss ;;
esac

# ── 2. 🔴 DB — 마이그레이션 수가 **그대로여야** 한다 ──────────────────
#   🔵 A/S 와 PO 가 같은 dss_as 를 본다. 그래서 재는 자리가 하나다.
printf '\n== 2. DB (dss_as · A/S 와 PO 가 함께 쓴다) — 마이그레이션 %s 그대로여야 한다\n' "$AS_KEEP"
MIG_AS0=$(mig_count "$AS_BOX" "$AS_DB")
say "기록 ${MIG_AS0:-?} (기대 $AS_KEEP 그대로)"
if [ -z "${MIG_AS0:-}" ]; then
  bad "DB 를 못 쟀다 — $AS_BOX 가 도는지 보세요"
elif [ "$MIG_AS0" = "$AS_KEEP" ]; then
  ok "$AS_KEEP 그대로다 (이 배포는 DB 의 구조를 건드리지 않는다)"
else
  bad "🔴 ${MIG_AS0} 이다 ($AS_KEEP 이어야 한다) — 다른 배포가 먼저 돌았거나 전제가 깨졌다"
  doubt
fi

# ── 3. 들여올 이미지 셋 ───────────────────────────────────────────────
printf '\n== 3. 들여올 이미지 셋 (앱 둘 · 도구 하나)\n'
BLANK=0
for t in $(trows); do
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
    hm "$TAR — **잰 값이 이 파일에 없다.** 옮기다 깨진 것만 잡는다"
    continue
  fi
  [ "$SZ"  = "$WSZ"  ] && ok "$TAR 크기가 구울 때와 같다  [배포본]" || { bad "$TAR 크기가 다르다 (${SZ} != ${WSZ}) — 옮기다 깨졌다"; doubt; }
  [ "$M5"  = "$WM5"  ] && ok "$TAR md5 가 같다  [배포본]"           || { bad "$TAR md5 가 다르다 — 옮기다 깨졌다"; doubt; }
  [ "$CFG" = "$WCFG" ] && ok "$TAR 지문이 같다  [배포본]"           || { bad "$TAR 지문이 다르다 (${CFG:-못 읽음}) — **다른 판을 올렸다**"; doubt; }
done
if [ "$BLANK" != "0" ]; then
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 49-build.sh --go 가 끝에 찍어 주는"
  printf '%s\n' "     **세 줄**로 이 파일의 TARS 세 줄을 통째로 갈아 끼우세요."
fi
# 🔵 되돌릴 길 — 옛 태그가 남아 있는가(앱 둘만. 도구는 되돌리지 않는다)
for r in $(rows); do
  OLD=$(fld "$r" 5)
  if "$DOCKER" image inspect "$OLD" >/dev/null 2>&1; then ok "$OLD 이 남아 있다 (되돌릴 길)"
  else hm "$OLD 이 없다 — 그 시스템은 --rollback 을 못 쓴다"; fi
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
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.** 다음: --count(앞) → --preload → (다시 --check) → --go → --count(뒤)"
  printf '%s\n' "🔴 올리기 전에 돌리면 ? 가 여럿 나오는 것이 **정상**이다 (tar 셋)."
  printf '%s\n' "🔴 **1-ㄷ 절의 PO 권한 줄만은 ? 로 넘기지 마세요** — 거기서 ✗ 가 나면 올리면 안 됩니다."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 4. --preload : tar 셋을 들여놓는다 ───────────────────────────────
if [ "$MODE" = preload ] || [ "$MODE" = go ]; then
  printf '\n== 4. tar 셋을 들여놓는다\n'
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
  say "실린 이미지 ${LOADED}개 (기대 3)"
  if [ "$LOADED" = "3" ]; then ok "셋이 다 실렸다"
  else bad "🔴 ${LOADED}/3 개만 실렸다 — TARS 가 비었거나 tar 가 모자란다"; fi
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
  printf '%s\n' "🔵 **들여놓기만 했다 — 아직 안 갈아 끼웠다.** 다음: --check 를 다시 → --go"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 5. --go / --rollback : compose 의 image: 줄을 바꾼다 ─────────────
#  🔴 --go 는 **셋**(app-as·app-po·tools-as)을 고친다. --rollback 은 **앱 둘**만
#     되돌린다 — 도구는 :9 그대로 둔다(39·41~48번과 같은 판단).
printf '\n== 5. compose 의 image: 줄을 바꾼다\n'
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
# 🔴 **남의 image: 줄을 건드리면 안 된다.** --go 는 셋(app-as·app-po·tools-as),
#    --rollback 은 둘(앱 둘)만 달라져야 한다.
if [ "$MODE" = go ]; then WANT_DIFF=3; else WANT_DIFF=2; fi
[ "$((DIFFN / 2))" = "$WANT_DIFF" ] && ok "image: 줄이 꼭 ${WANT_DIFF}개만 달라졌다 (우리 것)" \
  || { bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — ${WANT_DIFF}개를 기대했다. 남의 것을 건드렸을 수 있다"; doubt; }
dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 6. 앱 둘을 다시 띄운다 ────────────────────────────────────────────
#  🔴 tools-as 는 profiles: [tools] 라 up -d 로 띄우지 않는다. 태그만 고쳐 두면
#     다음에 run --rm tools-as 로 부를 때 새 이미지를 쓴다.
#  🔵 **둘을 한 번에 띄운다.** 이번 범위에 API 계약이 바뀐 자리가 없고(양쪽
#     diff 모두 src/app/api 0줄 · fetch( · /api/v1/ · /api/integration/ 더하고
#     지운 줄 0), 두 시스템은 **같은 dss_as 의 이미 있는 칸**을 쓴다. 그래서
#     PO 0.9 는 A/S 4.1 옆에서도, A/S 4.2 는 PO 0.8 옆에서도 선다.
printf '\n== 6. 앱 둘(app-as · app-po)을 다시 띄운다\n'
printf '%s\n' "🔴 --no-deps 다 — 앱 둘만 갈아 끼운다. 나머지 여덟과 DB 둘은 안 건드린다."
for r in $(rows); do
  CN=$(fld "$r" 3)
  say "$CN 지금: $("$DOCKER" inspect -f '{{.Id}}' "$CN" 2>/dev/null | cut -c1-12)"
done
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
  #    A/S 는 307 로 로그인에 보내는데 PO 는 303 으로 보낸다 —
  #    curl -w 의 redirect_url 로 재니 둘 다 /api/auth/sso/start 였다.
  #    로그인으로 넘기는 방식이 사이트마다 다르므로 3xx 리다이렉트는 넷을 다 받는다.
  printf '%s' "$CODE" | grep -qE '200|30[1237]' && ok "$CN 가 응답한다 ($CODE)" || bad "$CN 응답이 ${CODE:-없음}"
done

# 🔴 DB — 마이그레이션 수가 **여전히** 그대로인가 (이 배포는 DB 구조를 안 건드린다)
MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
say "마이그레이션 ${MIG_AS0:-?} -> ${MIG_AS1:-?} (그대로여야 한다)"
[ "${MIG_AS1:-x}" = "$AS_KEEP" ] && ok "$AS_KEEP 그대로다 (DB 구조를 안 건드렸다)" \
  || bad "🔴 ${MIG_AS1:-?} 다 — $AS_KEEP 그대로여야 한다. 이 배포가 DB 를 건드렸다면 전제가 틀렸다"

# 🔴 **새 PO 가 뜬 뒤 권한을 다시 잰다** — 1-ㄷ 은 옛 판이 떠 있을 때 쟀다.
#    권한은 역할에 달린 것이라 답이 같아야 하지만, **같은지를 봐야** 안다.
#    🔵 --rollback 에서는 여기서도 soft 다(되돌린 판은 안 쓴다).
if [ "$MODE" = go ]; then po_write_privilege_check block; else po_write_privilege_check soft; fi

# 🔴 도구 태그가 제대로 섰는지 + 이미지 안이 온전한지 다시 센다
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  # 🔵 --go 도 --rollback 도 도구 기대값은 **$TOOLS_NEW 로 같다** — 되돌려도
  #    도구는 :9 그대로 둔다(머리말 ⑥).
  [ "$TCUR" = "$TOOLS_NEW" ] && ok "$AS_TOOLS_SVC 가 $TOOLS_NEW 다" \
    || bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $TOOLS_NEW 를 기대했다"
  "$DOCKER" image inspect "$TCUR" >/dev/null 2>&1 && ok "$TCUR 이미지가 NAS 에 있다" \
    || bad "$TCUR 이미지가 NAS 에 없다 — 다음에 부를 때 못 쓴다"
fi
if [ "$MODE" = go ]; then tools_inside_check; fi
# 🔴 42번에서 넣은 검사는 **그대로 둔다** — 연락서 폴더가 줄만 있는 게 아니라
#    실제로 열리는지 센다.
if [ "$MODE" = go ]; then kyosan_folder_check; fi

# 🔴 **안 건드린 여덟이 그대로 도는지** 센다 — 「옆으로 안 샜다」는 증거다.
printf '\n    ── 안 건드린 여덟 (그대로여야 한다)\n'
KEEP_SEEN=0
for c in $KEEP_BOXES; do
  KEEP_SEEN=$((KEEP_SEEN+1))
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
  [ "$s" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
done
# 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다.
[ "$KEEP_SEEN" = "8" ] && ok "안 건드린 여덟을 다 봤다 (표본이 비지 않았다)" \
  || bad "안 건드린 상자를 ${KEEP_SEEN}개만 봤다 — 여덟을 기대했다. KEEP_BOXES 가 깨졌다"

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
  printf '%s\n' ""
  printf '%s\n' "🔵 **백필은 다시 돌리지 않는다.** 44~48번과 같다 — 까닭:"
  printf '%s\n' "   · 백필은 2026-10-29 새벽에 283건이 끝났다(사용 부품 978줄이 품번으로 들어가 있다)."
  printf '%s\n' "   · 이번 판은 **날짜 둘을 서로 맞추는 일**이다. 연락서를 읽는 규칙과 무관하다."
  printf '%s\n' "   🔵 도구는 올렸지만 돌릴 까닭은 없다 — 올리는 것과 돌리는 것은 다른 일이다."
  printf '%s\n' ""
  printf '%s\n' "🔵 **과거 건을 일괄로 묶지 않았다.** 지금 어긋나 있는 건은 그대로 남아 있고,"
  printf '%s\n' "   사람이 어느 한쪽에서 저장할 때마다 하나씩 맞춰집니다. 일괄로 맞추는 일은"
  printf '%s\n' "   **운영 대량 변경**이라 따로 승인받아야 합니다."
  printf '%s\n' ""
  if [ "$MODE" = go ]; then
    printf '%s\n' "🔴 **먼저 이것부터 — 세 도구로 수를 세어 --go 전과 견주세요 (읽기만 합니다):**"
    printf '%s\n' "      bash $0 --count"
    printf '%s\n' "   🔴 **기대값은 「앞뒤가 같다」**입니다. 다르면 전제가 깨진 것이니 알려 주세요."
    printf '%s\n' ""
  fi
  printf '%s\n' "🔴 **마지막은 눈입니다** — 이번 판은 볼 곳이 **넷**입니다."
  printf '%s\n' ""
  printf '%s\n' "  ① **A/S → 수리 건 상세 → 접수 정보 → 고객 요청 납기일을 고쳐 저장**"
  printf '%s\n' "     그 건에 붙은 **내자 정리의 납기요청일이 따라와야** 합니다."
  printf '%s\n' "     🔵 줄이 하나이고 그 줄에 날짜도 하나일 때만 따라옵니다."
  printf '%s\n' "     🔴 여럿이면 **읽어야 닫히는 알림**이 뜹니다 — 「고객 요청 납기일은 저장했습니다."
  printf '%s\n' "        … 내자 정리의 납기요청일은 그대로 두었으니, 내자 정리에서 직접 맞춰 주세요.」"
  printf '%s\n' "        🔵 0.5초 뒤 저절로 닫히는 저장 팝업이 **아닙니다.** 읽고 닫아야 합니다."
  printf '%s\n' ""
  printf '%s\n' "  ② **A/S → 내자 정리 → 납기요청일을 고쳐 저장**"
  printf '%s\n' "     그 줄이 가리키는 **수리 건의 고객 요청 납기일이 따라와야** 합니다."
  printf '%s\n' "     🔴 고친 날짜가 그 수리 건의 **인수일보다 이르면** 안 따라가고 알림이 뜹니다 —"
  printf '%s\n' "        「납기요청일은 저장했습니다. 다만 그 날짜가 수리 건의 인수일보다 일러 …」"
  printf '%s\n' "        🔵 **막는 것이 맞습니다.** 수리 건 상세에서도 적을 수 없는 날짜입니다."
  printf '%s\n' "     🔵 비고가 적힌 줄에서도 **비고가 그대로 남아 있어야** 합니다 — 행을 지우고"
  printf '%s\n' "        새로 만들지 않기 때문입니다. 비고가 사라졌다면 **그것이 결함입니다.**"
  printf '%s\n' ""
  printf '%s\n' "  ③ 🔴 **PO → 내자 정리 → 납기요청일을 고쳐 저장** — 이번 판의 핵심 확인입니다"
  printf '%s\n' "     PO 쪽은 A/S 의 같은 조각을 **바이트 그대로 옮긴 사본**입니다."
  printf '%s\n' "     🔴 **저장이 오류로 끝나면 바로 알려 주세요** — PO 가 수리 건 표에 쓰는 것이"
  printf '%s\n' "        오늘이 처음이라 권한 문제가 여기서 드러납니다(--check 의 1-ㄷ 절)."
  printf '%s\n' "     🔵 PO 에는 수리 건 화면이 없어 **한 방향만** 합니다 — 내자에서 고치면 수리"
  printf '%s\n' "        건이 따라오고, 그 반대는 A/S 에서만 일어납니다."
  printf '%s\n' "     🔵 A/S 내자 정리와 **같은 줄에서 같은 말이 나와야** 맞습니다."
  printf '%s\n' ""
  printf '%s\n' "  ④ 🔵 **아무것도 안 바뀐 것처럼 보이는 자리** — 그것이 맞습니다"
  printf '%s\n' "     납기 역전의 붉은 날짜 · 「협의 필요」 · 종의 알림 둘은 **48번 그대로**입니다."
  printf '%s\n' "     이번에 고친 것은 그 판정 함수가 **어느 파일에 사는가**뿐이고(고리 import 를"
  printf '%s\n' "     끊었습니다), 동작은 한 글자도 안 바뀝니다."
  printf '%s\n' "     🔴 **거꾸로, 그 자리가 달라졌다면 그것이 결함입니다** — 알려 주세요."
  printf '%s\n' ""
  printf '%s\n' "  🔵 **아무것도 안 바뀐 것처럼 보이면** 앱 둘이 정말 새 태그로 도는지(위 7절) 먼저"
  printf '%s\n' "     보시고, 맞다면 알려 주세요."
  printf '%s\n' ""
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (앱 둘만 되돌립니다. DB 를 안 건드렸으니"
  printf '%s\n' "               자료 손실이 없습니다. 🔵 도구는 $TOOLS_NEW 그대로 둡니다)"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
  printf '%s\n' "  🔵 ✗ 가 **재고 관리 통로** 하나뿐이라면 되돌리기 전에 설정을 먼저 보세요 —"
  printf '%s\n' "     INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN (env/as.env). 🔴 되돌려도 같은"
  printf '%s\n' "     설정 문제는 남습니다 — 옛 판도 같은 통로를 씁니다."
  printf '%s\n' "  🔴 ✗ 가 **PO 의 repair_cases 쓰기 권한**이라면 되돌리는 것이 맞습니다 —"
  printf '%s\n' "     PO 0.8 은 그 표에 쓰지 않습니다. 권한을 여는 일은 사람이 정하고 사람이 합니다."
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
