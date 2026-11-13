#!/bin/bash
# dss-deploy/nas/setup/61-build.sh — 쉰일곱째 배포 · 이미지 굽기 (2026-11-13)
#
# 🔵 **배포 회차(쉰일곱째)와 파일 번호(61)가 어긋나는 것은 이 저장소에서 원래
#    그렇다** — 55번 파일이 쉰두째, 57번이 쉰세째, 58번이 쉰네째, 59번이
#    쉰다섯째, 60번이 쉰여섯째였다. (56번은 2026-11-11 의 **양식 전용**이다.)
#
# 🔵 **판이 5.2 → 5.3 로 하나 는다.** 도구는 19 → 20.
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · PowerShell 에서 Git Bash 를 부른다) ──────────
#     cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#     & "C:\Program Files\Git\bin\bash.exe" ./61-build.sh --check
#     & "C:\Program Files\Git\bin\bash.exe" ./61-build.sh --go
#
#   🔴 **bash.exe 만 치면 WSL 이 잡힌다**(2026-11-04 에 걸렸다). WSL 에서 돌면
#      도커도 양식도 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 내어 ✗ 가
#      셋 흩어져 난다. 단서는 로그의 뿌리 경로가 **/mnt/c/…** 인 것이다.
#      🔵 아래 0절이 그것을 **값으로** 잰다(뿌리 경로를 찍고 /mnt/ 로 시작하면 ✗).
#   🔴 **스크립트에 건네는 경로에는 역슬래시를 쓰지 않는다.** 역슬래시를 주면
#      bash 가 그것을 먹어 "C:Users희만Desktop…" 이 되어 No such file 이 난다.
#
#   둘째 인자로 산출물을 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-57):
#     & "C:\Program Files\Git\bin\bash.exe" ./61-build.sh --go "/d/배포본/_images-57"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다.
#      이 파일을 쓴 쪽은 **한 번도 굽지 않았다** — 재기만 했다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **60-build.sh 에서 베꼈다가 「이번 판엔 거짓」이라 뒤집은 것 열하나**
# ══════════════════════════════════════════════════════════════════════
#   틀과 절 구성은 60-build.sh(쉰여섯째)를 그대로 썼다. 🔴 **그런데 전제가
#   다섯 자리에서 뒤집힌다.** 「배포본은 지난 판의 전제를 업고 온다」가 이
#   저장소에 기록된 함정이고, 그 함정은 넷으로 적혀 있다 — **없는 절 · 낡은
#   기대값 · 지난 판 점검표 · 아무것도 안 재는 ✓**. 앞의 둘은 ✗ 로 멈추지만
#   **뒤의 둘은 영영 안 드러난다.**
#   🔵 아래에 적은 「60번은 ~였다」는 **60-build.sh 를 직접 열어 확인한 것만**이다.
#
#   ① 🔵 **판이 5.2 → 5.3 · 도구 19 → 20.** 60번은 5.1 → 5.2 · 18 → 19 였다.
#      기준 SHA 도 1259d822 가 아니라 **21e04c16**(=60번이 올린 HEAD)다.
#   ② 🔴 **vendor/dss-core 가 여섯 판 만에 움직인다** — 6688e5d → 5da0382.
#      60번은 「안 움직였다」였고 그 앞 **다섯 판 연속** 그랬다. 그 절이 「0이
#      정상」을 전제로 쓰여 있어서, 그대로 베끼면 **멀쩡한 판이 ✗** 다.
#      🔴 뒤집은 자리가 **셋**이다: 3절의 포인터 검사 · **3-ㄴ 절을 되살린 것**
#      (55-build.sh 의 628~676줄) · 8절의 「vendor/ 변경 0개」(이제 **1개가 정답**).
#      🔴 그리고 **굽는 까닭이 하나 늘었다** — 아래 ㄹ.
#   ③ 🔴 **커밋 7 · 파일 56.** 60번은 5 · 82 였다. 숫자 기대값 셋이 전부 다르다:
#      새 파일 **20 → 26** · scripts/ **2 → 3** · 파일 **82 → 56**.
#   ④ 🔴 **마이그레이션이 또 1건이다** — drizzle/0128_true_havok.sql.
#      🔴 **그런데 하는 일이 60번과 정반대다.** 0127 은 INSERT 넷뿐이고 표를 한
#      칸도 안 바꿨다. **0128 은 표를 하나 만든다**(badge_visibility_settings) —
#      CREATE TABLE 1 · ALTER TABLE ADD CONSTRAINT 1 · CREATE UNIQUE INDEX 1 ·
#      **INSERT 0**. 60번의 「INSERT 4 · ON CONFLICT 4 · ALTER 0 · CREATE 0」을
#      그대로 베끼면 **멀쩡한 판이 ✗** 다. 4-ㄴ 절을 통째로 다시 썼다.
#   ⑤ 🔴 **0128 에 ON DELETE restrict 가 한 줄 있다.** 이 저장소의 「지우는 문장」
#      검사가 **ON DELETE 글자에 걸려** 표만 더하는 판을 ✗ 로 만든 적이 있다.
#      🔵 잣대는 60번 것을 **글자 그대로** 가져왔고(UPDATE 를 안 넣고 주석을 먼저
#      걷는다), **표본 넷**으로 잣대가 살아 있는지 먼저 잰다.
#      🔵 [실측 2026-11-13] 앱의 src/lib/db/migration-safety.ts 와 같은 잣대를
#         0128 에 돌려 **destructive: [] · risky: []** 를 받았다. 이 파일의
#         정규식도 **날것 0줄 · 주석 걷은 뒤 0줄**로 같은 답을 낸다.
#   ⑥ 🔴 **「담기는 것」이 둘로 갈린다.** 60번은 tools 가 담는 것 중 달라진 파일이
#      79 였고 **파일 목록도 79** 였다(src 77 + scripts 2). 이번 판은 git 이 세는
#      수가 **53**(src 49 + scripts 3 + **vendor 1**)인데, 이미지 안에서 한 장씩
#      물어볼 **파일 목록은 52** 다 — 「vendor/dss-core」 는 **포인터 한 줄**이라
#      이미지 안에 그 경로의 파일이 없다. 🔴 **두 수를 같은 칸에 적으면 ✗** 다.
#      그래서 상수를 둘로 나누고 **52 + 1 = 53 · 53 + 3 = 56** 을 값으로 맞댄다.
#   ⑦ 🔴 **도구 이미지를 반드시 굽는다.** tools 스테이지가 scripts · src · vendor
#      를 담는데 **이번에 셋 다 바뀌었다.** 🔴 전에 「마이그레이션이 적으니 도구는
#      안 굽는다」고 판단했다가 비상구 기능이 못 쓰는 상태로 나간 적이 있다 —
#      **이미지가 무엇을 담는지는 Dockerfile 스테이지가 정한다.**
#   ⑧ 🔴 **이미지 안 검사의 표식을 전부 갈았다.** 60번의 일곱
#      (FINAL_SHIPMENT_APPROVED_FILTER_VALUE · PERMISSION_AREA_GROUPS ·
#      resolveRepairCaseDetailTabVisibility · canOpenRepairCaseDetailTab ·
#      repairCases.serviceReports · domesticOrders.lifecycle · repairCases.approval)은
#      **이번 판이 하나도 안 건드린다.** 그대로 두면 **옛 판에서도 전부 ✓** 인
#      죽은 검사가 된다 — 「아무것도 안 재는 ✓」의 교과서다.
#   ⑨ 🔴 **FRESH_MARK 가 2026-11-12 에서 2026-11-13 으로 바뀌었다.** 그리고
#      **기대값이 49/49 가 아니라 46/49** 다 — 바뀐 49장 중 셋에는 그 날짜가 없다
#      (아래 AS_FRESH_MISS 에 이름을 적어 두었다). 🔴 49 로 두면 가짜 ✗ 다.
#      🔵 그 대신 **기준판 src/ 에 0파일**이라 60번보다 잣대가 깨끗하다(60번은 10
#      파일이 있어 「겹침 0」을 따로 재야 했다 — 이번엔 그 줄이 **늘 참이라** 뺐다).
#   ⑩ 🔴 **앱 번들 표식을 전부 갈았다.** 60번의 domesticOrders.view 는 기준판
#      src/ 에 **17파일** 있다(60번이 넣었다) — 번들 표식은 「기준판에 0」이어야
#      서므로 **못 쓴다.** 🔵 대신 그것을 **뒷걸음 방지 ④** 로 돌렸다.
#   ⑪ 🔴 **뒷걸음 방지가 셋 → 넷이 됐다.** 쉰여섯째(60번)가 올린 ASCII 글자
#      domesticOrders.view 를 보탰다. **하나도 빼지 마라** — 뺀 자리는 다시 넣는
#      사람이 없다.
#
#   ── 🔵 **60번과 같아서 안 뒤집은 것 다섯** (그래도 값으로 다시 쟀다)
#      · vendor/dss-ui **안 움직였다**(1210d11 그대로 — 여섯째 판 연속)
#      · 양식 **0장**(.xlsx 변경 0줄) · 포털·PO **안 굽는다**
#      · npm 명령 **39 → 39** 로 안 늘었다(ㄱ 잣대가 안 걸린다)
#      · 저장소 뿌리의 .html **19 → 19** 로 안 는다
#      · 도구 닫힘 아홉 중 바뀐 것 **0개**(ㄴ 잣대가 안 걸린다)
#      🔴 같다고 절을 지우지 않았다. 「0장·안 움직임·안 늚」은 **이번 판에서도
#         참인지 재야** 참이다 — 그것이 이 절들이 하는 일이다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 운영에서 바꾸는 것 — 배지를 자리별로 끄는 설정**
# ══════════════════════════════════════════════════════════════════════
#   커밋 일곱이다(기준 21e04c16 → HEAD 70ec2173):
#     ① f9c18022 밑바탕 — 표 badge_visibility_settings · 등록부 · 판정
#     ② 07325d51 [시스템 설정]을 탭 둘로 · 저장 · **settings 권한에 MANAGE**
#     ③ f90eec14 수리건 쪽 자리 셋에서 실제로 숨기기 + (app) 레이아웃에 Provider
#     ④ 9e38c0b3 꺼도 아무 일이 안 일어나던 자리 하나를 걷어냄 (자리 7 → 6)
#     ⑤ 2bd9f440 내자 정리·기타건 쪽 자리 셋 + 배지 다섯을 제 파일로
#     ⑥ 7a625589 마지막 보기 배지 하나 (BorrowedSourceNote)
#     ⑦ 70ec2173 **「정상」 배지 제거** — 지연일 때만 [납기 지연] 하나
#
#   🔴 **운영에서 동작이 바뀌는 것 둘**(배포 뒤 눈으로 볼 자리):
#     · [역할별 접근 권한]에 **「시스템 설정 — 관리」**가 새로 생긴다(관리자 이상).
#       🔴 **읽기는 다섯 역할 전부 그대로**라 아무도 좁아지지 않는다
#       (permission-baseline.ts 의 settings 가 「read: true」 를 못으로 박았다).
#     · **「정상」 배지가 모든 화면에서 사라진다** — 설정과 무관하게 즉시.
#   🔵 **표는 비어서 나간다** — 아무도 아무것도 끄지 않은 상태이고, 그때 화면은
#      「정상」이 사라진 것 말고는 지금과 같다(빈 표 = 전부 보임).
#
# ── 이번에 굽는 것 — **저장소 하나, 이미지 둘, 그리고 묶음 하나** ─────
#     ① A/S 앱    dss-as:5.2        → **dss-as:5.3**        커밋 7  스테이지 기본(runner)
#     ② A/S 도구  dss-as-tools:19   → **dss-as-tools:20**   커밋 7  🔴 --target tools
#     ③ 🔴 **마이그레이션 묶음 as-migrations.tar.gz** — 129장
#
#   🔴 **안 보내면 운영 볼륨이 128 그대로라 적용이 0건으로 조용히 끝난다** —
#      39·48·53번이 겪었다. **마이그레이션은 이미지 안이 아니라 볼륨에서 돈다.**
#
#   🔴 **포털(dss-auth)은 안 굽는다** — HEAD 가 53번이 구운 f87bf7d 그대로다.
#   🔴 **PO(dss-po)도 안 굽는다** — HEAD 가 기준 SHA(9c1b2ef) 그대로다.
#   🔵 **양식(.xlsx)은 한 장도 안 올린다.** 이번 범위에 .xlsx 변경이 **0줄**이다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **도구 이미지를 굽는 까닭 — 마이그레이션 수로 정하지 않는다**
# ══════════════════════════════════════════════════════════════════════
#   잣대는 41·48·52~60번이 쓰던 셋에 **이번 판에서 넷째가 붙었다**:
#     ㄱ) npm 명령이 늘었나   ㄴ) 도구의 import 닫힘 안이 바뀌었나
#     ㄷ) **tools 스테이지가 담는 것 중 바뀐 파일이 있나**
#     ㄹ) 🔴 **공용 스키마(vendor/dss-core)가 움직였나** ← 이번 판에 되살아났다
#
#   ㄱ **안 걸린다.** package.json diff **0줄** · scripts 항목 **39 → 39**.
#   ㄴ **안 걸린다.** 닫힘 아홉 중 이번 범위에서 바뀐 것이 **0개**(2026-11-13 실측).
#      🔴 **그래도 「안 걸린다」를 값으로 잰다** — 바뀌었는데 0 으로 적어 두면
#         다음 판이 그 거짓을 근거로 「안 구워도 된다」를 꺼낸다.
#   ㄷ **걸린다.** tools 가 담는 것 중 달라진 파일 **53개**(src 49 + scripts 3 +
#      vendor 1). [실측 2026-11-13] Dockerfile 의 그 자리는 **tools 60 · scripts 68 ·
#      src 69 · vendor 77 · runner 90** 줄이다. 🔵 5절-ㄱ 이 그 줄들을 파일에서
#      직접 읽어 줄 번호까지 확인한다.
#   ㄹ 🔴 **걸린다 — 여섯 판 만이다.** vendor/dss-core 가 6688e5d → 5da0382 로
#      움직였고, 그 안에 **새 스키마 파일**(src/schema/badge-visibility-settings.ts)과
#      index.ts 한 줄이 들어왔다. 🔴 **A/S 쪽 git diff 에는 포인터 한 줄로만 보인다** —
#      서브모듈 안으로 들어가 세지 않으면 「56개 바뀌었다」 안에 그 변경이 안 들어 있다.
#      🔴 옛 스키마가 담긴 도구로 db:migrate 를 돌리면 **새 표를 모르는 채** 돈다.
#      🔴 그리고 **굽기 전에 서브모듈이 새 커밋으로 체크아웃돼 있어야** 이미지에
#         새 스키마가 들어간다 — 3-ㄴ 절이 그것을 값으로 확인한다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이미지 안 검사 — **증거를 어떻게 골랐나** (먼저 재 보고 골랐다)
# ══════════════════════════════════════════════════════════════════════
#   🔴 **커밋이 일곱이라 「마지막 커밋만 담긴 판」도 「마지막 커밋이 빠진 판」도
#      가려야 한다.** 그래서 표식을 **일곱 커밋에 하나씩** 흩어 두었다.
#      🔴 전부 **기준판 21e04c16 의 그 파일에 0번 · 지금 판에 1번 이상**이고,
#         **그 커밋의 바로 앞 커밋에도 0번**이다(2026-11-13 실측).
#
#   ── 도구 이미지(dss-as-tools:20) — 소스가 **글자 그대로** 있다
#      글자                                      | 파일                                    | 커밋 | 기준→지금
#      BADGE_PLACEMENTS                          | lib/domain/badge-visibility.ts          | ①   | 0→2
#      badgeVisibility                           | components/settings/settings-tab-access.ts | ② | 0→2
#      BadgeVisibilityProvider                   | app/(app)/layout.tsx                    | ③   | 0→4
#      "repairCaseDetailHeader", "repairCase…"], | lib/domain/badge-visibility.ts          | ④   | 0→2
#      miscCaseDetailHeader                      | components/domestic-orders/detail/DomesticOrderDetailHeader.tsx | ⑤ | 0→3
#      BorrowedSourceNote                        | components/repair-cases/detail/IntakeInfoSection.tsx | ⑥ | 0→3
#      if (!isOverdue) return null;              | components/repair-cases/badges.tsx      | ⑦   | 0→1
#      🔵 전부 ASCII 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
#      🔴 ④ 는 **「자리 일곱 → 여섯」을 글자로 잡는 유일한 길**이다. 그 커밋이 한 일은
#         등록부에서 자리 하나를 **빼는 것**이라, 더해진 ASCII 이름이 없다. 그래서
#         **그 줄이 짧아진 모양**을 글자 그대로 잡는다(앞 커밋에는 뒤에 자리가 하나
#         더 붙어 있어 이 글자가 안 맞는다).
#      🔴 ⑦ 도 같다 — 마지막 커밋이 한 일은 「정상」 알약을 **빼는 것**이고,
#         남은 증거가 「if (!isOverdue) return null;」 한 줄이다.
#      🔴 ③ 은 **괄호가 든 경로**다. 일부러 거기 두었다 — 이번 판에도 그런 경로가
#         **2개** 있어 글롭 함정이 **살아 있다**(60번은 25개였다).
#
#   ── 앱 이미지(dss-as:5.3) — .next/standalone 이라 번들된 결과물이다
#      🔴 **안 나오는 것을 기대값으로 박으면 가짜 ✗ 가 난다.**
#      🔴 **이번에도 번들에서 재 보지 못했다** — 개발 PC 의 RF_Service_System/.next
#         에 standalone 이 없다(지금은 dev 뿐이다). 아래 수는 **소스에서 센 값**이고,
#         번들의 파일 수는 **「합이 1 이상」으로만** 잰다.
#         🔴 **✗ 가 나면 검사부터 의심한다.** 🔵 60번의 실측으로 **권한 열쇠 같은
#            「코드가 그 글자로 묻는 리터럴」은 minify 를 견딘다**는 것이 확인됐다 —
#            그래서 이번 셋도 전부 **그 꼴**로 골랐다(상수·함수 이름이 아니다).
#      ① dueDateFromDomesticOrderShort (ASCII) — **배지 열쇠 문자열**이다.
#         RequestedDueDateValue.tsx 가 「badgeKey="…"」 로, badge-samples.tsx 가
#         객체 열쇠로, 등록부가 「key: "…"」 로 쓴다. [실측] 기준판 src/ **0파일** →
#         지금 **6파일**. → **✗ 로 센다.**
#      ② 「배지 표시」(한글 13바이트) — [시스템 설정]의 **새 탭 이름**이고 설정
#         화면의 h2 이고 서버 거절 문구다. [실측] 기준판 src/ **0파일** → 지금 **41파일**.
#         → **✗ 로 센다**(바이트가 13 이 아니면 ✗ 가 아니라 ⚠️ 「못 쟀다」다).
#      ③ 「지연이 아닌 건에는 아무것도 안 뜹니다」(한글 53바이트) — **마지막 커밋
#         (⑦)이 넣은 등록부 설명 문구**다. [실측] 기준판 **0** · 바로 앞 커밋
#         7a625589 에도 **0** · 지금 **1파일**. 🔴 **번들에서 마지막 커밋을 가리는
#         유일한 양성 증거**다(그 커밋이 한 일이 「빼는 것」이라 다른 양성이 없다).
#      🔴 **지시서가 음성 표식으로 제안한 「납기 지연 / 정상」은 안 쓴다.**
#         [실측 2026-11-13] 그 글자는 **기준판 src/ 에 0파일**이고 지금 판에 **4파일**
#         (전부 주석)이다. 곧 ㄱ) 도구 이미지에서는 **있는 것이 정상**이라
#         「없어야 한다」가 거짓이고, ㄴ) 앱 번들에서는 주석이 지워져 **옛 판에서도
#         0** 이라 **아무것도 안 가른다.** 그 자리를 위 ③ 으로 바꿨다.
#      ── 🔵 **뒷걸음 방지 넷** — 🔴 **이번 판이 만든 글자가 아니다.**
#         ㄱ status=IN_HOUSE        — **쉰네째(58번)**가 올린 글자. [실측] src/ 5→5
#         ㄴ no-equipment-key       — **쉰세째(57번)**가 올린 글자. [실측] src/ 8→8
#         ㄷ 「영업·관리자·최고관리자에게 가고」(한글 47바이트)
#                                   — **쉰다섯째(59번)**가 올린 글자. [실측] src/ 1→1
#         ㄹ domesticOrders.view    — **쉰여섯째(60번)**가 올린 글자. [실측] src/ 17→17
#            🔴 **이번에 보탠 자리다.** 60번의 **앱 번들 표식이 그대로 내려와** 뒷걸음
#               방지가 됐다 — 그 판보다 옛 나무를 구웠는지는 이 글자로만 갈린다.
#            🔵 ASCII 라 8진 변환이 필요 없다.
#         🔴 **하나도 빼지 마라** — 뺀 자리는 다시 넣는 사람이 없다.
#      🔴 「재서 나왔다」와 「앞으로도 나온다」는 다른 말이다 — 그 말을 출력에도 적어 둔다.
#
# ── 🔴 모드 둘 ────────────────────────────────────────────────────────
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다.
#            🔵 **쓰는 것**: 없다(폴더도 --go 때만 만든다).
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면
#            굽지 않고 멈춘다. 전부 ✓ 일 때만 둘을 굽고 tar 로 뽑고 **묶음을 만든다.**
#            그리고 **이미지 안을 센다**(겉이 아니라 결과).
#            🔵 **쓰는 것**: $OUT 폴더 · tar 둘 · **묶음 하나** · 빌드 로그 둘 ·
#               도커 이미지 둘.
#            🔵 **안 쓰는 것**: 저장소 안의 파일 · NAS · DB.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 tar 크기를 **두 번** 견준다 ────────────────────────────────────
#   ① **지난 판 tar 와** 견준다. 적어 둔 값의 출처:
#        dss-as-5.2.tar       134853120  [실측] 2026-11-13 _images-56 에서 stat
#        dss-as-tools-19.tar  225497088  [실측] 2026-11-13 _images-56 에서 stat
#      🔵 그 둘은 **60번이 실제로 올린 tar** 다 — 60-deploy.sh 의 TARS 에 적힌
#         바이트와 글자 그대로 같다(눈으로 맞댔다).
#      🔴 **둘 다 한 판 전이라 25% 를 넘으면 ✗ 다**(strict).
#   ② **그 이미지 자신과** 견준다. 🔴 여기가 함정이라 가지를 둘로 나눴다:
#      · containerd 저장소면 'docker image inspect {{.Size}}' 가 **압축된 내용
#        크기**를 주어 tar 와 거의 같다(90~110%).
#      · 고전 저장소면 그 값이 **펼친 크기**라 tar 는 그 **1/4쯤**이다(10~45%).
#   🔴 **tar 지문은 'docker image inspect' 의 .Id 와 맞대지 않는다.** 그것은
#      애초에 다른 값이다. 맞댈 상대는 **빌드 로그의 'exporting config sha256:'** 이다.
#
# ── 🔴 이 환경의 함정 (36~60-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싼다.
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:/… 를 /c/… 로
#      바꾸고, docker save 와 묶음 만들기는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를
#      막는다 — 5절-ㄴ 이 그것도 잰다). 🔴 그래도 **7절이 3000번을 재서 찍는다.**
#   ④ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다.** 검사 이름은 전부 ASCII 고,
#      앱 번들의 한글 표식 셋만 **8진 이스케이프**로 만들어 쓴다(바이트 수를 먼저 받는다).
#   ⑤ 🔴 **대괄호·괄호가 든 경로를 글롭에 넘기지 않는다.**
#      🔴 **이번 판에는 그런 경로가 2개 있다**(60번은 25개였다) — 적지만 **살아
#         있다.** git 의 **pathspec 은 글롭**이라 「-- "…/(app)/…"」 로 물으면
#         **조용히 0줄**이 돌아온다. 그래서 이 파일은 바뀐 목록을 **한 번만 뽑아
#         두고 grep -Fx 로 맞댄다.**
#      🔴 셸 쪽도 같다 — 목록은 **here 문서 + while read** 로만 돌린다.
#      🔴 컨테이너 안에서도 경로를 **큰따옴표**로 감싸고 set -f 로 글롭을 끈다.
#   ⑥ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」
#      같은 안전망을 달면 **하필 바라던 0 에서만** 그것이 터져 값이 "0 ?" 가 된다.
#      이 파일은 그 꼴을 **한 군데도 쓰지 않는다** — 「$( … || true )」 로 받는다.
#   ⑦ 🔴 **tar | grep -q 를 if 에 바로 물리지 않는다.** set -uo pipefail 때문에
#      grep -q 가 먼저 끝나면 앞의 tar 가 SIGPIPE 로 죽고 **파일이 있을 때 오히려
#      ✗** 가 난다(2026-11-07 쉰째에서 실제로 났다).
#      🔴 **이번 판에도 묶음이 있어 tar 를 읽는 자리가 많다** — 전부
#         **「세어서 담고 비교하는」 꼴**(grep -c · grep -o)로만 썼다.
#   ⑧ 🔴 **지우는 문장을 셀 때 주석을 먼저 걷어낸다.** 그리고 **UPDATE 를 잣대에
#      넣지 마라** — 'updated_by'·'updated_at' **칸 이름**이 걸린다.
#      🔴 **0128 에는 ON DELETE restrict 가 한 줄 있다** — 그 글자도 안 센다.
#         앱의 migration-safety.ts 가 「FK 구절의 ON DELETE restrict 는 무엇도
#         지우지 않는다」고 못 박고 있고, 이 파일의 잣대도 같은 답을 낸다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안의 백틱은 명령 치환으로 읽힌다 → 이 파일에는 백틱이 **한 개도 없다.**
#   ② 읽기 전용 자리의 콜론과 꺾쇠로 빈 파일을 만드는 꼴은 ash 를 죽인다 →
#      이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#   🔴 19·20·21번에는 그 둘이 아직 남아 있다. **거기서 베껴 오지 마라.**
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEV=${DSS_DEV:-$(cd "$SCRIPT_DIR/../../.." && pwd)}

PASS=0; FAIL=0; UNK=0
ok()   { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
unk()  { UNK=$((UNK+1));   printf '  ? %s — 못 쟀다 (%s)\n' "$1" "$2"; }
note() { printf '  ⚠️ %s\n' "$1"; }
say()  { printf '    %s\n' "$1"; }
# 🔴 ✗ 가 났을 때 그 자리에서 찍는다 — 처음 도는 코드라 기대값이 틀릴 확률이
#    굽기만큼 높다. ✓ 쪽 오판은 영영 안 드러나므로 ✗ 쪽을 크게 적는다.
doubt() { say "🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 이 줄의 기대값이"
          say "   어디서 왔는지는 이 파일 머리말에 적혀 있습니다."; }

isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }

# 🔴 C:\… 또는 C:/… 를 /c/… 로. tar 는 드라이브 문자를 원격 호스트로 읽는다.
to_unix() { # 1 경로
  local p=${1//\\//}
  case "$p" in
    [A-Za-z]:/*) p=/$(printf '%s' "${p%%:*}" | tr 'A-Z' 'a-z')${p#?:} ;;
  esac
  printf '%s' "$p"
}

tar_name() { printf '%s.tar' "$(printf '%s' "$1" | tr ':' '-')"; }

# tar 안 manifest.json 의 Config 지문 (39~60-build.sh 의 것을 글자 그대로)
tar_config_id() { # 1 tar
  tar -xOf "$1" manifest.json 2>/dev/null \
    | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 \
    | sed 's|blobs/sha256/|sha256:|'
}

# 한 저장소의 drizzle/ 을 센다 → ".sql수 journal수"
count_drizzle() { # 1 저장소 폴더
  local s j
  s=$(ls -1 "$1/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  # 🔴 _journal.json 은 drizzle/ 바로 아래가 아니라 **meta/ 안**이다.
  j=$(grep -o '"idx"' "$1/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  printf '%s %s' "${s:-0}" "${j:-0}"
}

# 두 수의 차이가 몇 퍼센트인가 (정수). 0 으로 나누지 않는다.
pct_diff() { # 1 새값 2 옛값 → 퍼센트(정수). 못 재면 아무것도 안 찍는다.
  local a b d
  a=$1; b=$2
  isnum "$a" || return 1
  isnum "$b" || return 1
  [ "$b" -gt 0 ] || return 1
  if [ "$a" -ge "$b" ]; then d=$((a - b)); else d=$((b - a)); fi
  printf '%s' $((d * 100 / b))
}

# package.json 의 scripts 블록 **안**만 센다.
count_scripts() { # stdin = package.json
  awk '
    /^  "scripts": \{/ { inb = 1; next }
    inb && /^  \}/      { inb = 0 }
    inb && /^    "/     { n++ }
    END { print n + 0 }
  '
}

# ══ 이번에 굽는 것 — 한자리에 모아 둔다 ═══════════════════════════════
#   열쇠|저장소 폴더|새 태그|기준 SHA|--target(없으면 -)|기대 drizzle 변경 수|기대 커밋 수|지난판 tar 바이트|지난판 tar 이름|크기 엄함
#
#   🔴 여섯째 칸은 「기준 SHA 이후 drizzle/ 에서 **달라진 파일 수**」다.
#      🔴 **이번 판도 3 이다**(0128 .sql · 0128 snapshot · meta/_journal.json).
#      🔴 「3 이면 통과」가 아니라 **적어 둔 수와 똑같아야** 한다 — 늘었으면
#         마이그레이션이 더 생긴 것이고 묶음 검사의 기대값이 통째로 틀린다.
#   🔵 일곱째 칸(커밋 수)은 ✗ 로 세지 않고 ⚠️ 로만 센다. A/S **일곱**이다.
#   🔴 'astools' 는 **같은 저장소**를 --target tools 로 한 번 더 굽는 줄이다.
#   🔵 열째 칸: strict = 25% 넘으면 ✗ · loose = 25% ⚠️ · 60% 넘으면 ✗ (머리말).
SITES='
as|RF_Service_System|dss-as:5.3|21e04c16|-|3|7|134853120|dss-as-5.2.tar|strict
astools|RF_Service_System|dss-as-tools:20|21e04c16|tools|3|7|225497088|dss-as-tools-19.tar|strict
'
HOWMANY=2
AS_APP_TAG=dss-as:5.3
AS_TOOLS_TAG=dss-as-tools:20
# 🔵 되돌릴 판 — 61-deploy.sh --rollback 이 쓰는 그것이다.
AS_OLD_TAG=dss-as:5.2
AS_TOOLS_OLD_TAG=dss-as-tools:19

# ── 🔴 기대값과 그 출처 — 전부 [실측] 2026-11-13 개발 PC ───────────────
#   🔴 기준 SHA 는 **출처 둘을 맞대어** 확인했다:
#      ㄱ) 60-build.sh 가 올린 HEAD 가 21e04c16 다(그 파일의 AS_HEAD_FULL).
#      ㄴ) _images-56 에 그 판으로 구운 tar 둘이 그대로 있다(dss-as-5.2.tar ·
#          dss-as-tools-19.tar) — 바이트가 60-deploy.sh 의 TARS 와 같다.
AS_BASE=21e04c16
AS_HEAD_SHORT=70ec2173
AS_HEAD_FULL=70ec2173c08e7bed8081ffbd8efddc5e3704bcfa
AUTH_BASE=f87bf7d
PO_BASE=9c1b2ef

# 🔴 A/S drizzle — **128 → 129.** 이번 판이 0128 을 올린다.
AS_SQL_WANT=129       # 🔵 저장소가 지금 들고 있어야 하는 수
AS_PROD_SQL_NOW=128   # 🔵 운영 볼륨이 지금 들고 있는 수(60번이 올린 128)
AS_LAST_MIG=0128      # 🔴 저장소의 마지막 — **이번 판이 올린다**
AS_NEXT_MIG=0129      # 🔴 이것이 생겼으면 전제(1건)가 깨진 것이다
# 🔴 **다음 번호를 셈으로 만들지 않는다.** bash 의 $(( )) 는 0 으로 시작하는 수를
#    **8진수**로 읽어 0128+1 이 깨진다 — 오류 없이 엉뚱한 파일을 찾는다.
AS_LAST_MIG_FILE=0128_true_havok.sql
# 🔴 **이번에 생긴 마이그레이션은 1건이다.**
AS_NEW_MIGS_WANT=1
# 🔵 창이 한 칸 밀렸다 — 60번은 0121~0127 이었다. **0121 이 창 밖으로 나갔고
#    0128 이 들어왔다.** 묶음을 통째로 갈아 끼우므로 일곱 다 본다.
#    🔵 0127 이 아직 창 안에 있어 **「주석 속 DELETE」 표본**이 실물로 남아 있고,
#       0128 이 **「ON DELETE restrict」 표본**을 새로 들고 왔다.
AS_KEEP_MIGS='0122 0123 0124 0125 0126 0127 0128'
AS_KEEP_MIGS_WANT=7

# ══ 🔴 지우는 문장 잣대 — **주석을 먼저 걷어낸다** ════════════════════
#   🔴 55·60-build.sh 의 잣대를 글자 그대로 가져왔다. **UPDATE 를 넣지 않는다** —
#      넣으면 'updated_by'·'updated_at' **칸 이름**이 걸린다. 🔴 0128 에도
#      updated_by·updated_at 칸이 있어 넣었으면 그 자리에서 가짜 ✗ 가 난다.
#   🔵 ON DELETE · DROP CONSTRAINT · DROP INDEX 는 **안 센다** — 앱의
#      migration-safety 와 같은 잣대다. 🔴 **0128 에 ON DELETE restrict 가 한 줄
#      있다** — 그 글자를 세는 잣대였다면 표만 더하는 이 판이 ✗ 가 된다.
#      🔵 [실측 2026-11-13] 앱의 migration-safety.ts 와 같은 잣대를 0128 에 돌려
#         **destructive: [] · risky: []** 를 받았다. 이 정규식도 같은 답이다.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
MIG_DROP_WANT=0
# 🔵 주석을 걷어내는 잣대 — SQL 한 줄 주석은 두 빼기표로 시작한다.
SQL_COMMENT_RE='^[[:space:]]*--'

# ══ 🔴 서브모듈 — **dss-core 가 여섯 판 만에 움직인다** ═══════════════
#   🔴 60번은 여기가 「안 움직였다」였고 그 앞 다섯 판 연속 그랬다.
#      **그 절을 그대로 베끼면 멀쩡한 판이 ✗** 다 — 뜻을 뒤집었다.
AS_CORE_WAS=6688e5d71939d8f36fc89eedfeb1e5b437bd9bb2
AS_CORE_PIN=5da03825baa1a6a89a47a069d73ecaca4d69bb9c
AS_CORE_COMMITS_WANT=1
# 🔵 [실측 2026-11-13] 그 한 커밋이 고친 파일 **둘**.
CORE_CHANGED='
src/schema/badge-visibility-settings.ts
src/schema/index.ts
'
CORE_CHANGED_WANT=2
# 🔵 그 새 스키마 파일 안에 있어야 하는 글자(도구 이미지 안 검사가 다시 쓴다).
CORE_NEW_FILE=src/schema/badge-visibility-settings.ts
CORE_NEW_MARK=badge_visibility_settings
# 🔵 dss-ui 는 **여섯째 판 연속** 안 움직였다.
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425
PO_CORE_PIN=8730c9433b4388a038349ab9a11ec633659da782

# 🔵 A/S — 저장소 전체 **56** · tools 스테이지가 담는 것 **53** · 바깥 **3**.
#    🔴 60번은 82 · 79 · 3 이었다. **바깥 3 은 전부 drizzle/ 이다.**
#    🔴 **53 과 52 를 헷갈리지 마라** — 53 은 git 이 세는 수(vendor/dss-core
#       포인터 한 줄을 포함)이고, 이미지 안에서 한 장씩 물어볼 **파일 목록은 52** 다.
AS_ALL_CHANGED_WANT=56
AS_TOOLS_CHANGED_WANT=53
AS_TOOLS_VENDOR_WANT=1
AS_OUTSIDE_WANT=3
# 🔴 바깥 셋이 **전부 drizzle/ 인가**를 따로 센다 — 「바깥이 3」과 「drizzle 이 3」은
#    한쪽만 깨질 수 있는 다른 말이다.
AS_OUTSIDE_DRIZZLE_WANT=3
# 🔴 포털·PO 는 0 이어야 한다(안 굽는다).
AUTH_CHANGED_WANT=0
PO_CHANGED_WANT=0

# 🔴 npm 명령 수 — **이번 판에도 안 늘었다.** 41번 잣대가 **안 걸린다.**
AS_NPM_WAS=39;  AS_NPM_NOW=39
AS_PKG_LINES_WANT=0
AS_NEW_NPM_WANT=0
# 🔴 사라지면 안 되는 A/S 명령 아홉 — 48·52~60번이 올린 것 그대로.
AS_KEEP_NPM="check:target-shipment-missing check:due-date-inverted check:requested-due-date-sync check:due-date-overdue check:delivered-date-sync procedures:export procedures:import db:preflight db:migrate"
AS_KEEP_NPM_WANT=9

# ══ 🔴 A/S 도구 닫힘 — **이번 판에도 하나도 안 바뀐다** ═══════════════
#   🔵 2026-11-13 실측: 아홉 다 저장소에 있고, 이번 범위에서 바뀐 것은 **0개**다.
#   🔴 **그래도 「안 걸린다」를 값으로 잰다** — 바뀌었는데 0 으로 적어 두면 다음
#      판이 그 거짓을 근거로 「안 구워도 된다」를 꺼낸다.
#   🔴 **그 파일이 아직 저장소에 있나** 가드를 그대로 둔다 — 이름이 바뀌었는데
#      0 이 나와 「안 바뀌었다」로 조용히 지나가는 길을 막는다.
AS_TOOLS_CALLED='
scripts/check-delivered-date-sync.ts
scripts/check-due-date-overdue.ts
scripts/lib/delivered-date-sync-survey.ts
src/lib/db/queries/repair-case-domestic-order-due-dates.ts
src/lib/db/queries/repair-case-overdue-notifications.ts
src/lib/domain/due-date-inversion.ts
src/lib/domain/notifications.ts
src/lib/domain/repair-case-overdue.ts
src/lib/domain/types.ts
'
AS_TOOLS_CALLED_WANT=9
AS_TOOLS_CALLED_CHANGED_WANT=0
# 🔵 그 모듈을 import 로 부르는 scripts/ 파일 수(2026-11-13 실측).
#    🔴 이번 판이 바꾼 모듈을 scripts/ 는 **하나도 안 부른다**.
AS_SCRIPTS_IMPORT_WANT=0
# 🔵 이번 판이 바꾼 모듈 중 「scripts/ 가 부르나」를 물을 이름들. 전부 ASCII 다.
AS_IMPORT_KEYS="badge-visibility badge-visibility-settings settings-tab-access badge-visibility-authorization permission-areas"
# 🔵 위 이름들을 한 줄 정규식으로 — test-lists **밖**을 세는 데 쓴다.
AS_IMPORT_RE='badge-visibility\|badge-visibility-settings\|settings-tab-access\|badge-visibility-authorization\|permission-areas'

# ══ 🔴 **이번 판이 바꾼 49개(src/)** — tools 이미지가 담는 자리다 ══════
#   🔵 src/ **49** + scripts/ **3** = **52**(이미지 안에서 한 장씩 물어볼 목록).
#      🔴 git 이 세는 「담기는 것」은 **53** 이다 — vendor/dss-core 포인터 한 줄이
#         더 있다. 그 한 줄은 이미지 안에 그 경로의 파일이 **없다.**
#   🔴 **괄호가 든 경로가 2개 있다**(60번은 25개였다) — 적지만 글롭 함정이
#      **살아 있으므로** here 문서 + while read · grep -Fx · set -f 를 전부 지킨다.
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
# 🔴 **scripts/ 쪽은 3개다** — 60번은 2 였다. 🔵 셋 다 시험 목록 파일이다 —
#    이번 판에 **새 시험 아홉**이 생겨 셋에 나누어 등록했다.
AS_CHANGED_SCRIPTS='
scripts/test-lists/components.txt
scripts/test-lists/db.txt
scripts/test-lists/unit.txt
'
AS_CHANGED_SCRIPTS_WANT=3
# 🔴 **이미지 안에서 물어볼 파일 수** = 49 + 3 = 52. (53 이 아니다 — 위 머리말 ⑥)
AS_CHANGED_ALL_WANT=52

# ══ 🔴 **이번에 새로 생긴 파일 26개** — 60번은 20개였다 ═══════════════
#   🔵 src/ **24** + drizzle/ **2**(0128 .sql · 0128 snapshot) = 26.
AS_BORN_SRC='
src/components/domestic-orders/badge-visibility-screens.test.tsx
src/components/domestic-orders/badges.tsx
src/components/providers/BadgeVisibilityProvider.tsx
src/components/repair-cases/BorrowedSourceNote.tsx
src/components/repair-cases/badge-visibility-screens.test.tsx
src/components/repair-cases/borrowed-source-note.test.tsx
src/components/settings/BadgeVisibilityPanel.tsx
src/components/settings/BadgeVisibilitySettings.tsx
src/components/settings/SettingsTabs.tsx
src/components/settings/badge-samples.tsx
src/components/settings/badge-visibility-draft.test.ts
src/components/settings/badge-visibility-draft.ts
src/components/settings/badge-visibility-panel.test.tsx
src/components/settings/settings-tab-access.test.ts
src/components/settings/settings-tab-access.ts
src/lib/auth/badge-visibility-authorization.ts
src/lib/auth/settings-area-permission.test.ts
src/lib/db/mutations/badge-visibility-settings.integration.test.ts
src/lib/db/mutations/badge-visibility-settings.ts
src/lib/db/queries/badge-visibility-settings.ts
src/lib/domain/badge-visibility.test.ts
src/lib/domain/badge-visibility.ts
src/lib/server/actions/badge-visibility-settings.ts
src/lib/server/badge-visibility.ts
'
AS_BORN_SRC_WANT=24
AS_BORN_ALL_WANT=26

# ══ 🔴 **이번 판이 새로 만든 시험 아홉** — 목록에 등록돼 있어야 한다 ════
#   🔴 등록이 빠지면 **새 시험이 오류 없이 조용히 안 돈다**(이 저장소의 시험은
#      글롭이 아니라 목록 파일에 적어야 돈다).
#   🔵 [실측 2026-11-13] 넷은 scripts/test-lists/**components.txt** · 넷은
#      **unit.txt** · 하나는 **db.txt** 에 **줄 전체로** 적혀 있다
#      (grep -lFx 로 한 장씩 확인했다). 🔵 그래서 scripts/ 변경이 **셋**이다.
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
# 🔵 시험 목록 파일 **넷** — 이번 판은 그중 **셋**을 고친다. 넷 다 이미지에 있어야 한다.
AS_TESTLIST_FILES='
scripts/test-lists/components.txt
scripts/test-lists/db.txt
scripts/test-lists/db-safety.txt
scripts/test-lists/unit.txt
'
AS_TESTLIST_FILES_WANT=4
# 🔴 목록 파일을 **얼마나 읽었나**의 바닥값. [실측 2026-11-13] 네 장을 합쳐
#    **3807줄**이었다(components 1337 · unit 1942 · db 514 · db-safety 14 — 빈 줄 뺌).
#    🔵 목록은 늘기만 하므로 바닥값을 낮게 잡는다 — 여기서 걸리면 「줄었다」가 아니라
#       **아예 못 읽었다**는 뜻이다.
AS_TESTLIST_MIN_LINES=1000

# ══ 🔴 「이번 판인가」를 글자로 가르는 표식 일곱 ═══════════════════════
#   🔴 전부 **기준판(21e04c16)의 그 파일에 0번 · 지금 판에 1번 이상**이고,
#      **그 커밋의 바로 앞 커밋에도 0번**이다(2026-11-13 실측: 2·2·4·2·3·3·1).
#   🔴 **커밋이 일곱이라 일곱에 하나씩 흩었다** — 하나라도 빠지면 그 커밋이 안 담긴 것이다.
#   🔴 ④ 와 ⑦ 은 **빼는 커밋**이라 더해진 이름이 없다. 그래서 **남은 줄의 모양**을
#      글자 그대로 잡는다(앞 커밋에서는 그 줄이 더 길어 안 맞는다).
#   형식: 글자|파일 — 🔴 전부 ASCII 다.
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

# 🔴 **등록부의 모양** — 배지 15 · 자리 6 · 쌍 29. 커밋 ④ 가 자리를 7 에서 6 으로
#    줄인 판이라, **수로도 한 번 더** 잰다(글자 하나로만 재면 세는 길이 죽어도 모른다).
BV_FILE=src/lib/domain/badge-visibility.ts
BV_PLACES_WANT=6
BV_BADGES_WANT=15
BV_PAIRS_WANT=29
# 🔴 **중괄호를 역슬래시로 감싸지 마라** — BRE 에서 \{ 는 **반복 횟수**의 시작이라
#    grep 이 "Unmatched \{" 로 죽고 셈이 **2(오류)** 가 된다. 맨 중괄호는 그냥 글자다.
#    🔵 2026-11-13 에 실제로 한 번 그렇게 적었다 — 돌려 보고 고쳤다.
BV_PLACE_RE='^  { key: '
BV_BADGE_RE='^    key: '
BV_PAIR_RE='"(repairCaseList|repairCaseDetailHeader|repairCaseDetailBasicInfo|domesticOrderList|miscCaseList|miscCaseDetailHeader)"'
# 🔴 커밋 ④ 가 걷어낸 자리 — **지금 판에 0번**이어야 한다.
BV_REMOVED_PLACE=repairCaseDetailWorkHistory

# 🔴 **바뀐 49장이 전부 새 내용인가** — 날짜 글자 하나로 덮는다.
#    🔵 [실측 2026-11-13] **기준판 src/ 에 0파일**이다 — 60번은 10파일이 있어
#       「겹침 0」을 따로 재야 했는데, 이번엔 그 줄이 **늘 참이라 뺐다.**
#    🔴 **49장 전부는 아니다 — 46장이다.** 아래 셋에는 그 날짜가 없다(실측).
#       49 로 적어 두면 **멀쩡한 판이 ✗** 다.
FRESH_MARK=2026-11-13
FRESH_MARK_BASE_FILES=0
AS_FRESH_HIT_WANT=46
AS_FRESH_MISS='
src/components/repair-cases/RepairCaseListPage.tsx
src/components/settings/BadgeVisibilitySettings.tsx
src/lib/server/actions/badge-visibility-settings.ts
'
AS_FRESH_MISS_WANT=3

# ══ 🔴 **구운 앱 이미지 안에서 쓸 표식** — 상수·함수 이름으로 재지 않는다 ══
#   🔴 앱 이미지는 번들이라 minify 를 거친다. 이름은 남는다는 보증이 없다.
#      🔵 60번의 실측으로 **권한 열쇠 같은 「코드가 그 글자로 묻는 리터럴」은
#         minify 를 견딘다**는 것이 확인됐다 — 셋 다 그 꼴로 골랐다.
#   🔵 [실측 2026-11-13] 소스에서 기준판 **0파일** → 지금 **6파일**.
#      🔴 **번들에서 세어 본 적은 없다** — 개발 PC 에 .next/standalone 이 없다.
#         그래서 아래 이미지 안 검사는 **「합이 1 이상」으로만** 잰다. 수를 박지 마라.
BUILD_MARK=dueDateFromDomesticOrderShort
# 🔴 앱 번들에서 ✗ 로 세는 **한글** 표식 ① — [시스템 설정]의 **새 탭 이름**이다.
#    🔴 **명령에 한글을 넣지 않는다.** 8진 이스케이프를 넘기고 컨테이너 안에서
#       다시 만든다. 만들기가 틀리면 0 이 나와 「없다」로 읽히므로 **바이트 수(13)를
#       먼저 받아** 가르고, 13 이 아니면 ✗ 가 아니라 ⚠️ 다.
#    🔵 [실측 2026-11-13] 13바이트 · 기준판 src/ 0파일 · 지금 41파일.
APP_MARK_KO_OCT='\353\260\260\354\247\200 \355\221\234\354\213\234'
APP_MARK_KO_BYTES=13
# 🔴 앱 번들의 한글 표식 ② — **마지막 커밋(⑦)이 넣은 등록부 설명 문구**다.
#    🔴 그 커밋이 한 일은 「정상」 알약을 **빼는 것**이라, 번들에서 그 커밋을
#       가리는 **유일한 양성 증거**가 이 글자다.
#    🔵 [실측 2026-11-13] 53바이트 · 기준판 0파일 · 바로 앞 커밋(7a625589) 0파일 ·
#       지금 1파일.
APP_MARK2_KO_OCT='\354\247\200\354\227\260\354\235\264 \354\225\204\353\213\214 \352\261\264\354\227\220\353\212\224 \354\225\204\353\254\264\352\262\203\353\217\204 \354\225\210 \353\234\271\353\213\210\353\213\244'
APP_MARK2_KO_BYTES=53
# 🔵 **뒷걸음 방지 ①** — **쉰네째(58번)**가 올린 글자다. [실측] src/ 5 → 5.
KEEP_MARK=status=IN_HOUSE
# 🔵 **뒷걸음 방지 ②** — **쉰세째(57번)**가 올린 글자다. [실측] src/ 8 → 8.
KEEP_MARK2=no-equipment-key
# 🔵 **뒷걸음 방지 ③** — **쉰다섯째(59번)**가 올린 글자. 한글이라 8진으로 넘긴다.
#    [실측 2026-11-13] 47바이트 · src/ 1 → 1.
KEEP_MARK3_KO_OCT='\354\230\201\354\227\205\302\267\352\264\200\353\246\254\354\236\220\302\267\354\265\234\352\263\240\352\264\200\353\246\254\354\236\220\354\227\220\352\262\214 \352\260\200\352\263\240'
KEEP_MARK3_KO_BYTES=47
# 🔴 **뒷걸음 방지 ④ — 이번에 보탠 자리다.** **쉰여섯째(60번)의 앱 번들 표식**이
#    그대로 내려와 뒷걸음 방지가 됐다. [실측 2026-11-13] src/ 17 → 17. ASCII 다.
#    🔴 이것이 없으면 **60번이 올린 판보다 옛 나무를 구웠는지** 가릴 길이 없다.
KEEP_MARK4=domesticOrders.view

# 🔴 [실측] 2026-11-13 — git -c core.quotePath=false ls-tree --name-only <ref> -- .
#    🔵 한글 파일명이라 **quotePath 를 꺼야** 센다. 안 끄면 git 이 따옴표를 둘러
#       내보내어 '.html$' 가 안 맞고 **조용히 0** 이 나온다.
#    🔴 **이번 판도 19 → 19 다 — 안 는다.** 그래서 이 수로는 판을 못 가른다.
#       이미지 안에서는 「standalone 이 뿌리 파일을 **옮기기는 하는가**」로만 쓴다.
AS_ROOT_HTML_WAS=19
AS_ROOT_HTML_NOW=19

# 🔴 **도구 셋이 아직 읽기만 하는가** — 54번이 올린 그 셋이다. 부르는 꼴로 센다.
#    🔴 '--apply' 글자로 재지 않는다 — check-delivered-date-sync.ts 의 **주석**에
#       그 낱말이 1번 나와서, 그렇게 재면 멀쩡한 도구가 ✗ 가 된다.
#    🔵 이번 판이 만든 도구는 **없다**. 그래도 재는 까닭은 「한 번 열리면 아무도 안 닫는다」.
RO_WRITE_RE='\.insert\(|\.update\(|\.delete\('
RO_TOOLS='
scripts/check-due-date-overdue.ts
scripts/check-delivered-date-sync.ts
scripts/lib/delivered-date-sync-survey.ts
'
RO_TOOLS_WANT=3
RO_TEST=scripts/check-tools-read-only-source.test.ts

# 🔴 PO 쪽에서 **모르는 거절 코드** — 53번에서 넘어온 것이다. 고치지 않고 세어서 알린다.
PO_GATEWAY=src/lib/server/as-gateway.ts
PO_MISSING_CODE=APPROVAL_REQUIRED
PO_MUT=src/lib/db/mutations/domestic-orders.ts

# ══ 🔴 양식 파일 — 이름|바이트|md5 ════════════════════════════════════
#   🔴 **이번 판에도 올릴 양식이 없다.** 열하나가 전부 55·58~60번이 적어 둔 값
#      그대로여야 한다. 🔵 이번 범위에 .xlsx 변경이 **0줄**이다.
#   🔴 **경로는 여기 없다.** 이름과 바이트와 md5 뿐이다.
TPLS='
QUOTE_TEMPLATE_PATH|내자견적서.xlsx|85942|981edf1f1d4a1b4bf2747167c41149d5
OH_QUOTE_TEMPLATE_PATH|제너레이터 OH 견적서.xlsx|62101|4ef6d9dc75f797efb7088b43e9b4c3f9
MATCHER_QUOTE_TEMPLATE_PATH|매쳐 내자 견적서.xlsx|40079|a9f1f7e75e2ac718d86c288efec41d43
MATCHER_OH_QUOTE_TEMPLATE_PATH|매쳐 OH 견적서.xlsx|40664|fc4ee94678b99e5c7b60ca7d1fd94c57
CABLE_QUOTE_TEMPLATE_PATH|케이블 견적서.xlsx|50996|5450deb6182ccf4c76c2c7ea14b143d8
REPAIR_REPORT_TEMPLATE_PATH|수리보고서.xlsx|190710|403b642d7c700a118ee515e20e4d659e
INSPECTION_REPORT_TEMPLATE_PATH|검사보고서.xlsx|190589|f7dd2fe0dbf03e6a44fa48a00ee4413e
MATCHER_REPAIR_REPORT_TEMPLATE_PATH|수리보고서_매쳐.xlsx|191911|ab25c06be1799952e593c2eef810885e
MATCHER_INSPECTION_REPORT_TEMPLATE_PATH|검사보고서_매쳐.xlsx|191929|5701e075c3aac71f63d29fe28ed68e0f
GENERATOR_REPAIR_REPORT_TEMPLATE_PATH|수리보고서_제너레이터.xlsx|190340|f3b2c76d359c8decd33c01d8b4b0235b
GENERATOR_INSPECTION_REPORT_TEMPLATE_PATH|검사보고서_제너레이터.xlsx|190507|ef7edda07812f937381f82819fc79d22
'
TPL_COUNT_WANT=11

MODE=${1:---check}
OUTARG=${2:-}
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-57"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

ASDIR="$DEV/RF_Service_System"
AUTHDIR="$DEV/dss-auth"
PODIR="$DEV/dss-po"
COREDIR="$ASDIR/vendor/dss-core"
MIGTAR="$OUT/as-migrations.tar.gz"

printf '%s\n' "쉰일곱째 배포 · 이미지 굽기 (파일 번호 61)   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  🔵 회차(쉰일곱째)와 파일 번호(61)가 어긋나는 것은 이 저장소에서 원래 그렇다 — 57번이 쉰세째 · 58번이 쉰네째 · 59번이 쉰다섯째 · 60번이 쉰여섯째였다."
printf '%s\n' "  🔵 판은 **5.2 → 5.3** · 도구는 19 → 20."
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  저장소 뿌리: $DEV"
printf '%s\n' "  산출물을 둘 자리: $OUT"
printf '%s\n' "  굽는 것: $AS_APP_TAG · $AS_TOOLS_TAG  (저장소 **하나** · 이미지 **둘**)"
printf '%s\n' "  🔴 그리고 **셋째 산출물** — as-migrations.tar.gz (마이그레이션 $AS_SQL_WANT 장)"
printf '%s\n' "  올릴 HEAD: A/S $AS_HEAD_SHORT (기준 $AS_BASE 이후 커밋 **7** · 파일 **$AS_ALL_CHANGED_WANT**)"
printf '%s\n' "     🔵 파일 $AS_ALL_CHANGED_WANT = src/ $AS_CHANGED_SRC_WANT + scripts/ $AS_CHANGED_SCRIPTS_WANT + vendor/ $AS_TOOLS_VENDOR_WANT + drizzle/ $AS_OUTSIDE_DRIZZLE_WANT · 그중 **새 파일 $AS_BORN_ALL_WANT 개**"
printf '%s\n' "     🔴 **60번과 숫자 기대값 셋이 다르다** — 새 파일 20→26 · scripts/ 2→3 · 파일 82→56."
printf '%s\n' "  🔴 이 배포가 바꾸는 것: **배지를 자리별로 끄는 설정**(배지 15 · 자리 6 · 쌍 29) ·"
printf '%s\n' "     [시스템 설정]이 탭 둘로 · settings 권한에 **관리**가 열림 · **「정상」 배지 제거**."
printf '%s\n' "  🔴 **마이그레이션 1건** — drizzle/$AS_LAST_MIG_FILE (저장소 $AS_PROD_SQL_NOW → $AS_SQL_WANT · 4절)"
printf '%s\n' "     🔴 **0128 은 표를 하나 만든다** — 60번의 0127 과 하는 일이 정반대다(그쪽은 INSERT 넷뿐)."
printf '%s\n' "     🔴 **묶음(as-migrations.tar.gz)을 반드시 만들고 반드시 보낸다.**"
printf '%s\n' "        안 보내면 운영 볼륨이 $AS_PROD_SQL_NOW 그대로라 **적용이 0건으로 조용히 끝난다.**"
printf '%s\n' "  🔴 공용 스키마 vendor/dss-core 가 **움직였다** — ${AS_CORE_WAS:0:7} → ${AS_CORE_PIN:0:7} (3절·3-ㄴ절)"
printf '%s\n' "     🔵 **여섯 판 만이다.** 60번은 「안 움직였다」였고 그 앞 다섯 판 연속 그랬다."
printf '%s\n' "  🔴 도구를 굽는 까닭은 **둘**이다 — ㄷ(담기는 것 $AS_TOOLS_CHANGED_WANT 개) · **ㄹ(공용 스키마가 움직였다)**."
printf '%s\n' "     🔵 ㄱ(npm $AS_NPM_WAS → $AS_NPM_NOW)·ㄴ(도구 닫힘 0개)은 이번 판에 **안 걸린다**."
printf '%s\n' "  🔵 포털(dss-auth)은 **안 굽는다** — HEAD 가 53번이 구운 $AUTH_BASE 그대로다(2절)"
printf '%s\n' "  🔵 PO 도 **안 굽는다** — HEAD 가 기준 $PO_BASE 그대로다(2절)"
printf '%s\n' "  🔵 양식은 **0장** — 열하나가 55·58~60번 값 그대로다(8절)"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ── 0. 🔴 Git Bash 인가 (WSL 이면 ✗ 가 셋 흩어져 난다) ────────────────
#   🔴 2026-11-04 에 걸렸다. bash.exe 만 치면 WSL 이 잡히고, 거기서는 도커도
#      양식도 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 낸다.
#   🔵 단서는 **뿌리 경로가 /mnt/c/… 인 것**이다. 값으로 잰다.
printf '\n== 0. 어디서 도는가 (Git Bash 여야 한다)\n'
say "저장소 뿌리: $DEV"
say "uname: $(uname -s 2>/dev/null) · OSTYPE=${OSTYPE:-없음}"
case "$DEV" in
  /mnt/*)
    bad "🔴 뿌리가 **/mnt/… 다 — WSL 에서 돌고 있다.** Git Bash 로 다시 여세요"
    say "🔴 WSL 에서는 도커도 양식도 안 보이고 git 이 유령 diff 를 냅니다 — ✗ 가 셋 흩어져 납니다."
    say "   & \"C:\\Program Files\\Git\\bin\\bash.exe\" ./61-build.sh --check"
    doubt ;;
  /[a-z]/*)
    ok "뿌리가 /c/… 꼴이다 (Git Bash 에서 돌고 있다)" ;;
  *)
    note "뿌리가 $DEV 다 — /c/… 도 /mnt/… 도 아니다. 사람이 보세요" ;;
esac

# ── 1. 도커가 도는가 ──────────────────────────────────────────────────
printf '\n== 1. 도커\n'
if docker version --format '{{.Server.Version}}' >/dev/null 2>&1; then
  ok "도커가 돈다 (서버 $(docker version --format '{{.Server.Version}}' 2>/dev/null))"
else
  bad "도커가 안 돈다 — Docker Desktop 을 켜세요"
fi

# ── 2. 저장소 하나 (이미지 둘) ───────────────────────────────────────
printf '\n== 2. 저장소 하나 (이미지 둘)\n'
printf '%s\n' "🔴 미커밋·미푸시가 있으면 구운 이미지를 나중에 재현하지 못한다."
printf '%s\n' "🔴 **안 받은 것도 센다** — 낡은 코드를 굽고도 모른다."
printf '%s\n' "$SITES" | while IFS='|' read -r KEY REPO TAG BASE TGT WANTMIG WANTN PREVSZ PREVTAR STRICT; do
  [ -n "${KEY:-}" ] || continue
  case "$KEY" in (astools) continue ;; esac   # 🔵 같은 저장소다. 위에서 이미 쟀다.
  DIR="$DEV/$REPO"
  printf '  ── %s (%s → %s)\n' "$KEY" "$REPO" "$TAG"
  if [ ! -d "$DIR/.git" ] && [ ! -f "$DIR/.git" ]; then
    printf '  ✗ %s — git 저장소가 아니다 (%s)\n' "$REPO" "$DIR"; continue
  fi
  dirty=$(git -C "$DIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if isnum "${dirty:-}" && [ "$dirty" -eq 0 ]; then printf '  ✓ %s 미커밋 0\n' "$REPO"
  else printf '  ✗ %s 미커밋 %s 줄\n' "$REPO" "${dirty:-?}"; git -C "$DIR" status --porcelain=v1 2>/dev/null | head -5 | sed 's/^/      /'; fi
  if git -C "$DIR" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    up=$(git -C "$DIR" log --oneline '@{u}..HEAD' 2>/dev/null | wc -l | tr -d ' ')
    dn=$(git -C "$DIR" log --oneline 'HEAD..@{u}' 2>/dev/null | wc -l | tr -d ' ')
    if [ "${up:-1}" = "0" ] && [ "${dn:-1}" = "0" ]; then printf '  ✓ %s 미푸시 0 · 안받음 0\n' "$REPO"
    else printf '  ✗ %s 미푸시 %s · 안받음 %s\n' "$REPO" "${up:-?}" "${dn:-?}"; fi
  else
    printf '  ? %s 미푸시 — 올려다볼 가지가 없다\n' "$REPO"
  fi
  # 🔵 기준 SHA 가 조상인지 — 아니면 표가 낡았거나 가지가 갈렸다.
  if git -C "$DIR" merge-base --is-ancestor "$BASE" HEAD 2>/dev/null; then
    n=$(git -C "$DIR" log --oneline "$BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
    m=$(git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | wc -l | tr -d ' ')
    if [ "${n:-x}" = "$WANTN" ]; then
      printf '  ✓ %s 기준 %s 이후 커밋 %s개 — 적어 둔 그대로\n' "$REPO" "$BASE" "$n"
    else
      printf '  ⚠️ %s 기준 %s 이후 커밋 %s개 — **%s개를 적어 두었다**. 아래를 보고 사람이 판단할 것\n' "$REPO" "$BASE" "${n:-?}" "$WANTN"
      printf '%s\n' "      🔵 커밋이 늘어도 **굽는 판정은 안 흔들린다**(이미 굽는다). 흔들리는 것은"
      printf '%s\n' "         61-deploy.sh 꼬리말의 「볼 곳」과 5절의 파일 목록, 그리고 **표식 일곱**이다."
      git -C "$DIR" log --oneline "$BASE..HEAD" 2>/dev/null | head -12 | sed 's/^/      /'
    fi
    # 🔴 「3 이면 통과」가 아니다. 적어 둔 수와 **똑같아야** 한다.
    if [ "${m:-x}" = "$WANTMIG" ]; then
      printf '  ✓ %s drizzle/ 에서 달라진 파일 %s개 — 적어 둔 그대로 (**마이그레이션 1건**의 근거 ①)\n' "$REPO" "$m"
    else
      printf '  ✗ %s drizzle/ 에서 달라진 파일 %s개 — **%s개를 기대했다**. 멈추고 알릴 것\n' "$REPO" "${m:-?}" "$WANTMIG"
      printf '%s\n' "      🔴 이 배포는 **0128 하나**를 전제로 쓰였다. 늘었다면 묶음 검사와"
      printf '%s\n' "         61-deploy.sh 의 --migrate 기대값을 통째로 다시 재야 한다. 멈추고 알리세요."
      git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | head -8 | sed 's/^/      /'
    fi
  else
    printf '  ✗ %s — 기준 SHA %s 가 조상이 아니다 (표가 낡았거나 가지가 갈렸다)\n' "$REPO" "$BASE"
  fi
  printf '    지금 HEAD: %s\n' "$(git -C "$DIR" log -1 --format='%h %s' 2>/dev/null)"
done

# 🔴 위 while 이 파이프라인 안이라 **셈이 안 넘어온다.** 다시 세어 FAIL 에 싣는다.
REPO_BAD=0; REPO_SEEN=0
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}
  rest=${rest#*|}; BASE=${rest%%|*}; rest=${rest#*|}; TGT=${rest%%|*}
  rest=${rest#*|}; WANTMIG=${rest%%|*}
  case "$KEY" in (astools) continue ;; esac   # 🔵 이미 셌다.
  REPO_SEEN=$((REPO_SEEN+1))
  DIR="$DEV/$REPO"
  d=$(git -C "$DIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  u=$(git -C "$DIR" log --oneline '@{u}..HEAD' 2>/dev/null | wc -l | tr -d ' ')
  n=$(git -C "$DIR" log --oneline 'HEAD..@{u}' 2>/dev/null | wc -l | tr -d ' ')
  m=$(git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | wc -l | tr -d ' ')
  git -C "$DIR" merge-base --is-ancestor "$BASE" HEAD 2>/dev/null || REPO_BAD=$((REPO_BAD+1))
  [ "${d:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
  [ "${u:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
  [ "${n:-1}" = "0" ] || REPO_BAD=$((REPO_BAD+1))
  [ "${m:-x}" = "$WANTMIG" ] || REPO_BAD=$((REPO_BAD+1))
done
# 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다 — 저장소 **하나**를 봤는가.
if [ "$REPO_SEEN" = "1" ]; then ok "저장소 하나를 봤다 (표본이 비지 않았다 — 이번 판은 A/S 뿐이다)"
else bad "저장소를 ${REPO_SEEN}개 봤다 — 하나를 기대했다. SITES 표가 깨졌다"; fi
if [ "$REPO_BAD" = "0" ]; then ok "A/S 가 깨끗하고 drizzle 변경 수가 적어 둔 그대로다 ($AS_OUTSIDE_DRIZZLE_WANT)"
else bad "저장소 검사에서 어긋난 것 ${REPO_BAD}가지 — 위 ✗ 를 보세요"; doubt; fi

# 🔴 **HEAD 가 정말 그 커밋인가** — 짧은 SHA 만 보면 다른 커밋을 구울 길이 있다.
ASHEAD=$(git -C "$ASDIR" rev-parse HEAD 2>/dev/null)
say "A/S HEAD 전체: ${ASHEAD:-못 읽음}"
if [ "${ASHEAD:-}" = "$AS_HEAD_FULL" ]; then
  ok "A/S HEAD 가 적어 둔 그 커밋이다 ($AS_HEAD_SHORT — 지시서의 올릴 HEAD 와 같다)"
else
  bad "🔴 A/S HEAD 가 ${ASHEAD:-못 읽음} 다 — $AS_HEAD_FULL 을 기대했다. **다른 나무를 구우려 한다**"
  doubt
fi

# 🔴 **안 굽는 아홉도 재 둔다** — 「이번 범위에 커밋이 없다」를 짐작으로 적지 않는다.
#    🔵 ✗ 가 나도 **이 배포를 막지 않는다**(⚠️ 로만 센다).
printf '\n  ── 안 굽는 아홉 (HEAD 가 기준 SHA 그대로여야 한다)\n'
IDLE='
dss-auth|f87bf7d
dss-inventory|e0d84e8
dss-board|7d4f390
dss-leave|f568fc0
njlee|a234878
dss-improvements|38fc0ef
dss-trouble|c3da85d
dss-approvals|8ab36fd
dss-po|9c1b2ef
'
IDLE_WANT=9
IDLE_SEEN=0
for row in $(printf '%s\n' "$IDLE" | tr -d ' ' | grep -v '^$'); do
  R=${row%%|*}; B=${row#*|}
  IDLE_SEEN=$((IDLE_SEEN+1))
  DIR="$DEV/$R"
  if [ ! -d "$DIR/.git" ] && [ ! -f "$DIR/.git" ]; then
    note "$R — 저장소가 여기 없다 ($DIR). 못 쟀으니 사람이 보세요"; continue
  fi
  h=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
  c=$(git -C "$DIR" rev-list --count "$B..HEAD" 2>/dev/null)
  if [ "${c:-x}" = "0" ]; then
    printf '      %-18s 기준 %s · HEAD %s · 이후 커밋 0\n' "$R" "$B" "${h:-?}"
  else
    note "$R — 기준 $B 이후 커밋 ${c:-못 쟀다}개다. **다음 판의 범위가 늘었다.** 사람이 보세요"
    git -C "$DIR" log --oneline "$B..HEAD" 2>/dev/null | head -5 | sed 's/^/      /'
  fi
done
if [ "$IDLE_SEEN" = "$IDLE_WANT" ]; then ok "안 굽는 아홉을 다 봤다 (표본이 비지 않았다)"
else bad "안 굽는 저장소를 ${IDLE_SEEN}개만 봤다 — ${IDLE_WANT}을 기대했다. IDLE 표가 깨졌다"; fi
# 🔵 포털을 안 굽는 판이므로 IDLE 에 dss-auth 가 **있어야** 한다.
#    🔴 **이 줄은 바깥을 안 잰다** — 이 파일 안의 표를 본다. 그래도 둔 까닭은,
#       다음 판에서 포털을 함께 굽게 되는 날 **이 줄을 지워야 한다는 표지**이기 때문이다.
if printf '%s\n' "$IDLE" | tr -d ' ' | grep -q '^dss-auth|'; then
  ok "IDLE 표에 dss-auth 가 있다 (이 파일의 표를 본 것이다 — 바깥을 잰 것이 아니다)"
else
  bad "🔴 IDLE 표에 dss-auth 가 없다 — **이번 판은 포털을 안 굽는다**"
  doubt
fi

# ── 3. 🔴 서브모듈 — **이번 판은 dss-core 가 움직인다**(60번과 뒤집힘) ─
printf '\n== 3. 서브모듈 (🔴 이번 판은 dss-core 가 **움직였다** — 여섯 판 만이다)\n'
# 🔴 tr 의 지우기 집합에서 빼기표는 **맨 끝**에 둔다(ASCII 역순이면 죽는다).
pin_of() { git -C "$1" submodule status "$2" 2>/dev/null | awk '{print $1}' | tr -d '+-'; }

check_pin() { # 1 저장소 2 서브모듈경로 3 기대 4 사람이 부르는 이름
  local got
  got=$(pin_of "$1" "$2")
  if [ "${got:-}" = "$3" ]; then
    ok "$4 $2 포인터가 ${3:0:7} 다 (적어 둔 그대로)"
  elif [ -n "${got:-}" ]; then
    bad "$4 $2 포인터가 ${got:0:7} 다 — **${3:0:7} 을 기대했다.** 멈추고 알릴 것"
    doubt
  else
    bad "$4 $2 포인터를 못 읽었다 — 서브모듈이 아예 없다"
  fi
}
check_pin "$ASDIR" vendor/dss-core "$AS_CORE_PIN" "A/S"
check_pin "$ASDIR" vendor/dss-ui   "$UI_PIN"      "A/S"

# 🔴 **정말 움직였는가** — 기준판의 포인터가 **옛 값**이어야 「움직였다」가 선다.
#    🔵 60번은 여기가 반대였다(기준판이 지금과 같아야 「안 움직였다」가 섰다).
#    🔴 움직였는데 「안 움직였다」로 적어 두면 공용 스키마가 바뀐 판에서
#       이미지 안 검사가 통째로 느슨해진다.
WASPIN=$(git -C "$ASDIR" ls-tree "$AS_BASE" vendor/dss-core 2>/dev/null | awk '{print $3}')
say "기준판 $AS_BASE 의 vendor/dss-core = ${WASPIN:0:7}  (지금 ${AS_CORE_PIN:0:7})"
if [ "${WASPIN:-}" = "$AS_CORE_WAS" ]; then
  ok "vendor/dss-core 가 기준판 ${AS_CORE_WAS:0:7} → 지금 ${AS_CORE_PIN:0:7} 로 **움직였다** (적어 둔 그대로)"
  say "🔴 **그래서 아래 3-ㄴ 절이 되살아났다** — 55-build.sh 에 있던 절이고 56~60번에는"
  say "   쓸 일이 없어 빠져 있었다. 🔴 **도구를 굽는 넷째 까닭(ㄹ)이 여기서 선다.**"
elif [ -z "${WASPIN:-}" ]; then
  unk "기준판의 vendor/dss-core 포인터" "git ls-tree 가 아무것도 안 돌려줬다 — 기준 SHA 를 보세요"
else
  bad "🔴 기준판의 vendor/dss-core 가 ${WASPIN:0:7} 다 — **${AS_CORE_WAS:0:7} 을 기대했다**(움직였어야 한다)"
  doubt
fi
# 🔵 dss-ui 는 **여섯째 판 연속** 안 움직였다.
WASUI=$(git -C "$ASDIR" ls-tree "$AS_BASE" vendor/dss-ui 2>/dev/null | awk '{print $3}')
say "기준판 $AS_BASE 의 vendor/dss-ui = ${WASUI:0:7}  (지금 ${UI_PIN:0:7})"
if [ "${WASUI:-}" = "$UI_PIN" ]; then
  ok "vendor/dss-ui 가 기준판과 **같다** — 이번 판에 안 움직였다 (적어 둔 그대로)"
elif [ -z "${WASUI:-}" ]; then
  unk "기준판의 vendor/dss-ui 포인터" "git ls-tree 가 아무것도 안 돌려줬다"
else
  bad "🔴 vendor/dss-ui 가 기준판 ${WASUI:0:7} → 지금 ${UI_PIN:0:7} 로 움직였다 — 안 움직인다고 적어 두었다"
  doubt
fi

# ── 🔴 3-ㄴ. 공용 스키마 안에서 **무엇이 바뀌었나** (55-build.sh 에서 되살림) ──
#   🔴 A/S 쪽 git diff 에는 **포인터 한 줄**로만 보인다. 서브모듈 안으로 들어가
#      세지 않으면 「56개 바뀌었다」 안에 스키마 변경이 **안 들어 있다.**
#   🔴 이것이 **도구를 굽는 넷째 까닭(ㄹ)** 이고, 옛 스키마가 담긴 도구로
#      db:migrate 를 돌리면 새 표를 모른 채 돈다.
#   🔴 그리고 **지금 작업본이 새 커밋으로 체크아웃돼 있어야** 이미지에 새 스키마가
#      들어간다 — 포인터만 맞고 파일이 옛것이면 **구운 이미지가 옛 스키마**다.
printf '\n  ── 공용 스키마에서 바뀐 파일 (기대 %s개 · **도구를 굽는 까닭 ㄹ**)\n' "$CORE_CHANGED_WANT"
if [ -d "$COREDIR/.git" ] || [ -f "$COREDIR/.git" ]; then
  CORE_HEAD=$(git -C "$COREDIR" rev-parse HEAD 2>/dev/null)
  say "vendor/dss-core 작업본 HEAD: ${CORE_HEAD:-못 읽음}"
  if [ "${CORE_HEAD:-}" = "$AS_CORE_PIN" ]; then
    ok "작업본이 **새 커밋으로 체크아웃돼 있다** (${AS_CORE_PIN:0:7} — 이미지에 새 스키마가 들어간다)"
  else
    bad "🔴 작업본이 ${CORE_HEAD:0:7} 다 — ${AS_CORE_PIN:0:7} 을 기대했다. **옛 스키마를 구울 참이다**"
    say "🔴 git submodule update --init --recursive 를 먼저 돌리세요."
    doubt
  fi
  CN=$(git -C "$COREDIR" rev-list --count "$AS_CORE_WAS..$AS_CORE_PIN" 2>/dev/null)
  say "dss-core 커밋 ${CN:-못 쟀다}개 (적어 둔 수 $AS_CORE_COMMITS_WANT)"
  git -C "$COREDIR" log --oneline "$AS_CORE_WAS..$AS_CORE_PIN" 2>/dev/null | sed 's/^/      /'
  if [ "${CN:-x}" = "$AS_CORE_COMMITS_WANT" ]; then
    ok "dss-core 가 $AS_CORE_COMMITS_WANT 커밋 움직였다 (적어 둔 그대로)"
  else
    note "dss-core 가 ${CN:-?}커밋이다 — $AS_CORE_COMMITS_WANT 을 적어 두었다. 사람이 보세요"
  fi
  CORE_SEEN=0; CORE_HIT=0
  while IFS= read -r f; do
    [ -n "${f:-}" ] || continue
    CORE_SEEN=$((CORE_SEEN+1))
    if [ ! -s "$COREDIR/$f" ]; then
      bad "🔴 dss-core 의 $f 가 없다 — 목록이 낡았다"; continue
    fi
    if git -C "$COREDIR" diff --name-only "$AS_CORE_WAS..$AS_CORE_PIN" -- "$f" 2>/dev/null | grep -q .; then
      CORE_HIT=$((CORE_HIT+1)); say "🔴 바뀌었다 · 도구가 읽는다 — vendor/dss-core/$f"
    else
      say "🔵 안 바뀌었다 — vendor/dss-core/$f"
    fi
  done <<COREEOF
$(printf '%s\n' "$CORE_CHANGED" | grep -v '^[[:space:]]*$')
COREEOF
  CORE_ALL=$(git -C "$COREDIR" diff --name-only "$AS_CORE_WAS..$AS_CORE_PIN" 2>/dev/null | wc -l | tr -d ' ')
  say "dss-core 에서 달라진 파일 전체 ${CORE_ALL:-?}개 · 그중 적어 둔 것 ${CORE_HIT}/${CORE_SEEN}"
  if [ "$CORE_SEEN" = "$CORE_CHANGED_WANT" ] && [ "$CORE_HIT" = "$CORE_CHANGED_WANT" ] && [ "${CORE_ALL:-x}" = "$CORE_CHANGED_WANT" ]; then
    ok "공용 스키마 $CORE_CHANGED_WANT 개가 바뀌었다 — **도구를 굽는 까닭 ㄹ 이다**"
  else
    bad "🔴 공용 스키마에서 바뀐 것이 ${CORE_HIT}/${CORE_SEEN} 개(전체 ${CORE_ALL:-?}) — ${CORE_CHANGED_WANT} 을 기대했다"
    doubt
  fi
  # 🔴 **새 스키마 파일이 정말 새 표를 적는가** — 「파일이 있다」와 다른 말이다.
  CNEW=$(grep -cF "$CORE_NEW_MARK" "$COREDIR/$CORE_NEW_FILE" 2>/dev/null || true)
  CIDX=$(grep -cF "$CORE_NEW_FILE" "$COREDIR/src/schema/index.ts" 2>/dev/null || true)
  CIDX2=$(grep -c 'badge-visibility-settings' "$COREDIR/src/schema/index.ts" 2>/dev/null || true)
  say "$CORE_NEW_FILE 안의 $CORE_NEW_MARK ${CNEW:-0}번 (기대 1 이상) · index.ts 의 export ${CIDX2:-0}줄 (기대 1 이상)"
  if [ "${CNEW:-0}" -ge 1 ] 2>/dev/null && [ "${CIDX2:-0}" -ge 1 ] 2>/dev/null; then
    ok "새 스키마가 표 $CORE_NEW_MARK 를 적고 index.ts 가 그것을 내보낸다"
    say "🔵 내보내지 않으면 도구가 @dss/core/schema 에서 그 표를 **못 찾는다** — 2026-09-21 에 겪었다."
  else
    bad "🔴 새 스키마가 ${CNEW:-0}번 · index.ts 의 export ${CIDX2:-0}줄이다 — 둘 다 1 이상이어야 한다"
    doubt
  fi
  # 🔵 서브모듈 쪽에 안 받은 커밋이 있는지 — ⚠️ 로만 센다.
  CORE_AHEAD=$(git -C "$COREDIR" rev-list --count "$AS_CORE_PIN..origin/main" 2>/dev/null)
  if isnum "${CORE_AHEAD:-}" && [ "${CORE_AHEAD:-0}" -gt 0 ]; then
    note "vendor/dss-core 의 origin/main 이 핀보다 ${CORE_AHEAD}커밋 앞서 있다 — **이 배포는 안 막는다**(핀으로 굽는다)"
  else
    say "🔵 vendor/dss-core 의 origin/main 이 핀보다 앞서 있지 않다 (또는 못 쟀다: ${CORE_AHEAD:-?})"
  fi
  # 🔴 핀이 **올라가 있는가** — 안 올라간 커밋을 구우면 다른 PC 에서 재현이 안 된다.
  CORE_UP=$(git -C "$COREDIR" rev-list --count "origin/main..$AS_CORE_PIN" 2>/dev/null)
  if [ "${CORE_UP:-x}" = "0" ]; then
    ok "vendor/dss-core 의 핀이 origin/main 에 **올라가 있다** (다른 PC 에서도 재현된다)"
  else
    bad "🔴 vendor/dss-core 의 핀이 origin/main 보다 ${CORE_UP:-?}커밋 앞선다 — **안 올라간 커밋을 굽는다**"
    doubt
  fi
  CORE_DIRTY=$(git -C "$COREDIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  if [ "${CORE_DIRTY:-1}" = "0" ]; then ok "vendor/dss-core 에 미커밋 0"
  else bad "vendor/dss-core 에 미커밋 ${CORE_DIRTY}줄 — 구운 이미지를 나중에 재현하지 못한다"; fi
else
  unk "vendor/dss-core 안" "그 폴더가 git 저장소가 아니다 — git submodule update --init 을 먼저"
fi

# 🔵 PO 는 **이번에 안 굽는다.** 핀이 어긋나도 이 배포를 막을 일이 아니다 — ⚠️ 로만 센다.
printf '\n'
for pair in "vendor/dss-core $PO_CORE_PIN" "vendor/dss-ui $UI_PIN"; do
  set -- $pair
  got=$(pin_of "$PODIR" "$1")
  if [ "${got:-}" = "$2" ]; then say "🔵 PO $1 포인터 ${2:0:7} — 적어 둔 그대로 (이번에 안 굽는다)"
  else note "PO $1 포인터가 ${got:0:7} 다 — ${2:0:7} 을 적어 두었다. **이번 배포는 안 막는다**(PO 를 안 굽는다)"; fi
done
say "🔴 A/S dss-core ${AS_CORE_PIN:0:7} · PO dss-core ${PO_CORE_PIN:0:7} — **서로 다른 것이 맞다.**"
say "   🔴 **이번 판에서 그 차이가 또 벌어졌다** — A/S 가 표를 하나 더했다(badge_visibility_settings)."
say "   🔵 PO 는 그 표를 안 쓴다(배지 설정은 A/S 화면만의 일이다). 쉰두째에서 벌어진 칸 넷의"
say "   차이가 여전히 더 중요하다. 🔵 지금 운영에서 **직원이 PO 에 못 들어간다**(2026-11-08)."
say "   🔴 **여기서 맞추지 마세요** — PO 를 여는 날 한 묶음으로 이식한다."
# 🔴 빈 폴더가 아닌가 — 포인터는 맞는데 안이 비어 있는 경우가 실제로 있다.
check_not_empty() { # 1 서브모듈 폴더 2 사람이 부르는 이름
  if [ -s "$1/package.json" ]; then ok "$2 에 파일이 있다 (빈 폴더가 아니다)"
  else bad "$2 가 **빈 폴더**다 — git submodule update --init 을 먼저"; fi
}
check_not_empty "$COREDIR"             "A/S-core"
check_not_empty "$ASDIR/vendor/dss-ui" "A/S-ui"

# ── 4. 🔴 drizzle/ — **128 → 129. 마이그레이션 1건** ─────────────────
#   🔴 여기서 재는 것은 **「올릴 것이 정확히 하나인가」**다 — 둘이면 묶음 검사의
#      기대값이 통째로 틀리고, 0 이면 이 배포의 까닭 하나가 사라진다.
printf '\n== 4. drizzle/ — A/S %s 장 (운영 볼륨은 아직 %s · **올릴 것 %s건**)\n' "$AS_SQL_WANT" "$AS_PROD_SQL_NOW" "$AS_NEW_MIGS_WANT"
AS_COUNTS=$(count_drizzle "$ASDIR"); AS_SQL=${AS_COUNTS%% *}; AS_JRN=${AS_COUNTS##* }
say "RF_Service_System/drizzle — .sql ${AS_SQL}장 · meta/_journal.json 의 idx ${AS_JRN}개"
if [ "${AS_SQL:-0}" = "$AS_SQL_WANT" ] && [ "${AS_JRN:-0}" = "$AS_SQL_WANT" ]; then
  ok "${AS_SQL_WANT}장이다 — 🔵 60번이 올린 $AS_PROD_SQL_NOW 에 **이번 판이 하나를 더했다**"
else
  bad "drizzle 이 .sql ${AS_SQL:-?} · idx ${AS_JRN:-?} 다 — **${AS_SQL_WANT} 여야 한다.** 멈추고 알릴 것"
  doubt
fi
# 🔴 **.sql 과 idx 가 서로 어긋나면** 목록에 없는 파일이 생긴 것이다 — 그쪽이 더 위험하다.
#    🔴 0128 이 목록(_journal.json)에 안 들어 있으면 drizzle 이 그 파일을 **아예 모르고**,
#       적용이 0건으로 조용히 끝난다.
if [ "${AS_SQL:-0}" != "${AS_JRN:-1}" ]; then
  bad "🔴 .sql ${AS_SQL:-?}장과 idx ${AS_JRN:-?}개가 **다르다** — 목록에 없는 .sql 은 **안 돈다**"
  doubt
else
  ok ".sql 수와 _journal.json 의 idx 수가 같다 (목록에서 빠진 .sql 이 없다 — 0128 도 목록에 있다)"
fi
# 🔵 두 상수가 이어지는 번호인가 — 한쪽만 고치면 아래 검사가 조용히 빗나간다.
#    🔴 10# 을 붙여 **10진수로 강제**한다. 안 붙이면 0128 이 8진수로 읽혀 죽는다.
if [ "$(printf '%04d' "$((10#$AS_LAST_MIG + 1))")" = "$AS_NEXT_MIG" ]; then
  ok "번호 둘이 이어진다 ($AS_LAST_MIG → $AS_NEXT_MIG)"
else
  bad "🔴 $AS_LAST_MIG · $AS_NEXT_MIG 가 안 이어진다 — 한쪽만 고쳤다"
fi
# 🔴 **기준판과 지금의 .sql 수 차이가 정확히 1 인가** — 「1건」의 둘째 근거다.
#    🔵 2절이 git diff 로 쟀고, 여기는 **나무 양쪽을 따로 세어** 맞댄다. 길이 둘이다.
WASSQL=$(git -C "$ASDIR" ls-tree --name-only "$AS_BASE" drizzle/ 2>/dev/null | grep -c '[.]sql$' || true)
say "기준판 $AS_BASE 의 drizzle/*.sql ${WASSQL:-못 쟀다}장 (지금 ${AS_SQL:-?}장 · 차이가 $AS_NEW_MIGS_WANT 이어야 한다)"
if isnum "${WASSQL:-}" && isnum "${AS_SQL:-}" && [ "$((AS_SQL - WASSQL))" = "$AS_NEW_MIGS_WANT" ]; then
  ok "기준판보다 .sql 이 **정확히 ${AS_NEW_MIGS_WANT}장 늘었다** — 마이그레이션 1건의 근거 ②"
  say "🔵 기준판이 $AS_PROD_SQL_NOW 인 것도 함께 확인됐습니다 — 운영 볼륨이 들고 있는 수와 같습니다."
else
  bad "🔴 기준판 ${WASSQL:-?}장 · 지금 ${AS_SQL:-?}장 — 차이가 $AS_NEW_MIGS_WANT 이어야 한다"
  say "🔴 둘 이상 늘었다면 **묶음 검사와 61-deploy.sh --migrate 의 기대값이 통째로 틀린다.**"
  doubt
fi
# 🔴 **이번 판이 올리는 그 파일이 정말 있는가** — 이름까지 본다.
if [ -s "$ASDIR/drizzle/$AS_LAST_MIG_FILE" ]; then
  ok "drizzle/$AS_LAST_MIG_FILE 이 있다 (**이번 판이 올리는 그 한 장**)"
else
  bad "🔴 drizzle/$AS_LAST_MIG_FILE 이 **없다** — 이 배포의 목적물이 저장소에 없다"
  ls -1 "$ASDIR/drizzle/${AS_LAST_MIG}_"*.sql 2>/dev/null | sed 's/^/      /'
  doubt
fi
# 🔴 **그 한 장이 기준판에는 없었는가** — 「이번에 생겼다」를 값으로 잰다.
WASNEW=$(git -C "$ASDIR" ls-tree --name-only "$AS_BASE" drizzle/ 2>/dev/null | grep -cF "$AS_LAST_MIG_FILE" || true)
say "기준판에 $AS_LAST_MIG_FILE 이 ${WASNEW:-?}장 (기대 0 — 이번에 생긴 것이다)"
if [ "${WASNEW:-1}" = "0" ]; then
  ok "$AS_LAST_MIG 이 **기준판에는 없었다** — 이번 범위가 올리는 것이 맞다"
else
  bad "🔴 기준판에도 $AS_LAST_MIG 이 있다 — **이미 올라간 판을 또 올리려 한다.** 멈추고 알릴 것"
  doubt
fi
if ls -1 "$ASDIR/drizzle/${AS_NEXT_MIG}_"*.sql >/dev/null 2>&1; then
  bad "🔴 drizzle 에 $AS_NEXT_MIG 번이 **생겼다** — 이 배포는 **$AS_LAST_MIG 까지**를 전제로 쓰였다"
  say "🔴 묶음과 61-deploy.sh --migrate 의 기대값이 둘 다 틀린다. 멈추고 알릴 것."
  doubt
else
  ok "$AS_NEXT_MIG 번이 없다 (마지막이 $AS_LAST_MIG — **올릴 것이 ${AS_NEW_MIGS_WANT}건**이 맞다)"
fi
# 🔵 0122~0128 일곱이 그대로 있는가 — 묶음을 통째로 보내므로 **나무가 온전해야** 한다.
#    🔵 창이 한 칸 밀렸다 — 60번은 0121~0127 이었다.
KEEPMIG_SEEN=0; KEEPMIG_OK=0
for t in $AS_KEEP_MIGS; do
  KEEPMIG_SEEN=$((KEEPMIG_SEEN+1))
  if ls -1 "$ASDIR/drizzle/${t}_"*.sql >/dev/null 2>&1 && [ -s "$ASDIR/drizzle/meta/${t}_snapshot.json" ]; then
    KEEPMIG_OK=$((KEEPMIG_OK+1))
  else
    bad "$t 의 .sql 또는 스냅샷이 없다 — 저장소의 drizzle/ 이 온전하지 않다"
  fi
done
if [ "$KEEPMIG_SEEN" = "$AS_KEEP_MIGS_WANT" ] && [ "$KEEPMIG_OK" = "$AS_KEEP_MIGS_WANT" ]; then
  ok "0122~0128 일곱이 .sql 과 스냅샷까지 그대로 있다 (0128 의 스냅샷도 있다)"
else
  bad "본 것 ${KEEPMIG_SEEN} · 온전한 것 ${KEEPMIG_OK} 다 — ${AS_KEEP_MIGS_WANT}/${AS_KEEP_MIGS_WANT} 을 기대했다"
fi

# ── 4-ㄴ. 🔴 **0128 이 무엇을 하는가** — 60번의 0127 과 하는 일이 정반대다 ──
#   🔴 **잣대부터 재 본다** — 표본이 안 걸리면 아래 「0줄」은 공짜 통과다.
#   🔴 표본 넷 중 **둘째(ON DELETE)가 이번 판의 핵심**이다 — 0128 의 FK 구절에
#      ON DELETE restrict 가 **실제로 한 줄 있다.** 그 글자를 세는 잣대였다면
#      표만 더하는 이 판이 ✗ 가 된다(이 저장소가 실제로 겪은 일이다).
printf '\n  ── 🔴 0128 이 **지우는 문장을 안 쓰는가** (주석을 걷어낸 뒤 센다)\n'
PR_DROP=$(printf '%s\n' 'DROP TABLE foo;' | grep -ciE "$DESTRUCTIVE_RE" || true)
PR_ONDEL=$(printf '%s\n' 'REFERENCES "b"("id") ON DELETE restrict;' | grep -ciE "$DESTRUCTIVE_RE" || true)
PR_CMT=$(printf '%s\n' '--     DELETE FROM "role_permissions"' | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
PR_UPD=$(printf '%s\n' '       "updated_by",' | grep -ciE "$DESTRUCTIVE_RE" || true)
say "표본 — 진짜 DROP ${PR_DROP:-?}(기대 1) · ON DELETE ${PR_ONDEL:-?}(기대 0) · 주석 속 DELETE ${PR_CMT:-?}(기대 0) · updated_by ${PR_UPD:-?}(기대 0)"
MIGJ_OK=1
[ "${PR_DROP:-0}" = "1" ] || { bad "🔴 지우는 문장 잣대가 죽었다 — 아래 「0줄」이 공짜 통과다"; MIGJ_OK=0; }
[ "${PR_ONDEL:-1}" = "0" ] || { bad "🔴 ON DELETE 를 지우는 문장으로 센다 — **0128 이 그 한 줄 때문에 가짜 ✗ 를 받는다**"; MIGJ_OK=0; }
[ "${PR_CMT:-1}" = "0" ] || { bad "🔴 주석을 안 걷어낸다 — 0127 이 제 머리말 때문에 가짜 ✗ 를 받는다"; MIGJ_OK=0; }
[ "${PR_UPD:-1}" = "0" ] || { bad "🔴 updated_by 같은 칸 이름을 지우는 문장으로 센다 — 0128 에도 그 칸이 있다"; MIGJ_OK=0; }
if [ "$MIGJ_OK" = "1" ]; then
  ok "지우는 문장 잣대가 살아 있고 **ON DELETE·주석·칸 이름에 안 속는다** (표본 넷이 다 맞았다)"
  say "🔵 [실측 2026-11-13] 앱의 src/lib/db/migration-safety.ts 와 같은 잣대를 0128 에"
  say "   돌려 **destructive: [] · risky: []** 를 받았습니다 — 이 정규식과 같은 답입니다."
fi
MIGDROP_N=0
for t in $AS_KEEP_MIGS; do
  f=$(ls -1 "$ASDIR/drizzle/${t}_"*.sql 2>/dev/null | head -1)
  [ -n "${f:-}" ] || continue
  craw=$(grep -ciE "$DESTRUCTIVE_RE" "$f" 2>/dev/null || true)
  cnet=$(grep -v "$SQL_COMMENT_RE" "$f" 2>/dev/null | grep -ciE "$DESTRUCTIVE_RE" || true)
  cond=$(grep -ciF 'ON DELETE' "$f" 2>/dev/null || true)
  printf '      %-6s 날것 %s줄 · 주석 걷은 뒤 %s줄 · (참고) ON DELETE %s줄\n' "$t" "${craw:-0}" "${cnet:-0}" "${cond:-0}"
  MIGDROP_N=$((MIGDROP_N + ${cnet:-0}))
done
say "0122~0128 에 지우는 문장(주석 걷은 뒤) ${MIGDROP_N}줄 (기대 ${MIG_DROP_WANT}줄)"
if [ "$MIGDROP_N" = "$MIG_DROP_WANT" ]; then
  ok "일곱 다 **더하기만 한다** (주석 걷은 뒤 ${MIG_DROP_WANT}줄)"
  say "🔵 0127 은 날것으로 세면 **1줄**이 나옵니다 — 제 머리말에 적힌 **되돌리는 법**입니다."
  say "🔵 0128 의 **ON DELETE 1줄은 안 셉니다** — FK 구절이라 무엇도 지우지 않습니다."
else
  bad "🔴 지우는 문장이 ${MIGDROP_N}줄이다 (기대 ${MIG_DROP_WANT}줄) — 고치지 말고 **먼저 알리세요**"
  doubt
fi
# 🔴 **0128 이 정말 「표 하나를 만드는 판」인가** — 「지우는 문장이 없다」와 다른 말이다.
#    🔴 60번은 여기가 「INSERT 4 · ON CONFLICT 4 · ALTER 0 · CREATE 0」이었다.
#       **이번 판은 그 넷이 전부 뒤집힌다** — 그대로 베끼면 멀쩡한 판이 ✗ 다.
M128=$(ls -1 "$ASDIR/drizzle/${AS_LAST_MIG}_"*.sql 2>/dev/null | head -1)
if [ -n "${M128:-}" ]; then
  B128=$(grep -v "$SQL_COMMENT_RE" "$M128" 2>/dev/null)
  N_CT=$(printf '%s\n' "$B128" | grep -c 'CREATE TABLE' || true)
  N_ALTER=$(printf '%s\n' "$B128" | grep -c 'ALTER TABLE' || true)
  N_ADDC=$(printf '%s\n' "$B128" | grep -c 'ADD CONSTRAINT' || true)
  N_UIDX=$(printf '%s\n' "$B128" | grep -c 'CREATE UNIQUE INDEX' || true)
  N_INS=$(printf '%s\n' "$B128" | grep -c 'INSERT INTO' || true)
  say "0128 (주석 걷은 뒤) — CREATE TABLE ${N_CT:-0} · ALTER TABLE ${N_ALTER:-0} · ADD CONSTRAINT ${N_ADDC:-0} · CREATE UNIQUE INDEX ${N_UIDX:-0} · INSERT ${N_INS:-0}"
  say "   (기대 1 · 1 · 1 · 1 · 0 — **표 하나를 만들고 자료는 한 줄도 안 넣는다**)"
  if [ "${N_CT:-0}" = "1" ] && [ "${N_ALTER:-0}" = "1" ] && [ "${N_ADDC:-0}" = "1" ] \
     && [ "${N_UIDX:-0}" = "1" ] && [ "${N_INS:-1}" = "0" ]; then
    ok "0128 이 **표 하나 · FK 하나 · 유니크 인덱스 하나**다 (INSERT 가 0 이라 자료를 안 건드린다)"
    say "🔵 그래서 **표가 비어서 나갑니다** — 아무도 아무것도 끄지 않은 상태이고,"
    say "   그때 화면은 「정상」이 사라진 것 말고는 지금과 같습니다(빈 표 = 전부 보임)."
  else
    bad "🔴 0128 의 생김새가 기대와 다르다 — CREATE TABLE 1 · ALTER 1 · ADD CONSTRAINT 1 · UNIQUE INDEX 1 · INSERT 0 을 기대했다"
    say "🔴 **이 배포는 「표 하나를 더하고 자료는 안 건드린다」를 전제로 쓰였다.** 멈추고 알릴 것."
    doubt
  fi
  # 🔵 칸 여섯과 이름 둘이 다 적혀 있는가 — 하나라도 빠지면 **앱이 그 칸에서 깨진다.**
  COL_OK=0; COL_SEEN=0
  for cn in id badge_key place_key is_visible updated_by updated_at; do
    COL_SEEN=$((COL_SEEN+1))
    c=$(printf '%s\n' "$B128" | grep -cF "\"$cn\"" || true)
    printf '      칸 %-12s %s번\n' "$cn" "${c:-0}"
    if [ "${c:-0}" -ge 1 ] 2>/dev/null; then COL_OK=$((COL_OK+1)); fi
  done
  NAME_OK=0; NAME_SEEN=0
  for nm in badge_visibility_settings badge_visibility_settings_badge_place_unique badge_visibility_settings_updated_by_users_id_fk; do
    NAME_SEEN=$((NAME_SEEN+1))
    c=$(printf '%s\n' "$B128" | grep -cF "$nm" || true)
    printf '      이름 %-52s %s번\n' "$nm" "${c:-0}"
    if [ "${c:-0}" -ge 1 ] 2>/dev/null; then NAME_OK=$((NAME_OK+1)); fi
  done
  if [ "$COL_SEEN" = "6" ] && [ "$COL_OK" = "6" ] && [ "$NAME_SEEN" = "3" ] && [ "$NAME_OK" = "3" ]; then
    ok "0128 이 칸 **여섯**과 이름 **셋**(표·유니크 인덱스·FK)을 다 적는다"
    say "🔴 61-deploy.sh 의 --migrate 가 **그 셋을 DB 에서 다시 찾아** 적용을 확인합니다."
  else
    bad "🔴 칸이 ${COL_OK}/6 · 이름이 ${NAME_OK}/3 개만 적혀 있다"
    doubt
  fi
else
  unk "0128 의 속" "그 .sql 을 못 찾았다"
fi
# 🔴 「삼켜진 0」을 여기서 가른다 — PO 에 drizzle/ 이 없는 것이 맞다.
if [ -d "$PODIR/drizzle" ]; then
  bad "🔴 dss-po 에 drizzle/ 폴더가 **생겼다** — 2026-09-28 부터 없던 것이다. 사람이 보세요"
  doubt
else
  ok "dss-po 에 drizzle/ 폴더가 없다 (없는 것이 맞다 — 스키마의 주인은 A/S 하나뿐이다)"
fi
printf '%s\n' "    🔴 **묶음(as-migrations.tar.gz)을 만든다.** 올릴 것이 ${AS_NEW_MIGS_WANT}건이기 때문이다."
printf '%s\n' "       🔴 **마이그레이션은 이미지 안이 아니라 볼륨에서 돈다** — 묶음을 안 보내면"
printf '%s\n' "          운영 볼륨이 $AS_PROD_SQL_NOW 그대로라 **적용이 0건으로 조용히 끝난다**(39·48·53번)."
printf '%s\n' "       🔴 **_images-56 의 묶음(128장)을 보내지 마세요** — 0128 이 없습니다."

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 담는 길 · 도구 판정 · 소스가 새 코드를 담고 있나 ────────────
# ══════════════════════════════════════════════════════════════════════
#  🔴 .dockerignore 나 Dockerfile 이 어긋나면 이미지는 멀쩡히 구워지고 **바뀐
#     코드만 조용히 빠진다.** 그래서 담는 길부터 센다.
printf '\n== 5. 담는 길 · 도구 판정 · 소스가 새 코드를 담고 있나\n'
# 🔴 기준 SHA 가 표와 이 절에 **두 벌로** 적혀 있다. 한쪽만 고치면 조용히 어긋난다.
row_f() { printf '%s\n' "$SITES" | tr -d ' ' | grep "^$1|" | head -1 | cut -d'|' -f"$2"; }
AS_ROW_BASE=$(row_f as 4)
if [ "${AS_ROW_BASE:-}" = "$AS_BASE" ]; then ok "A/S 기준 SHA 가 SITES 표와 이 절에서 같다 ($AS_BASE)"
else bad "A/S 기준 SHA 가 어긋난다 — 표는 ${AS_ROW_BASE:-못 읽음} · 이 절은 $AS_BASE"; fi
# 🔴 포털·PO 기준 SHA 는 SITES 에 없다(안 굽는다). IDLE 표와 맞댄다.
for pair in "dss-auth $AUTH_BASE" "dss-po $PO_BASE"; do
  set -- $pair
  IB=$(printf '%s\n' "$IDLE" | tr -d ' ' | grep "^$1|" | head -1 | cut -d'|' -f2)
  if [ "${IB:-}" = "$2" ]; then ok "$1 기준 SHA 가 IDLE 표와 이 절에서 같다 ($2)"
  else bad "$1 기준 SHA 가 어긋난다 — IDLE 표는 ${IB:-못 읽음} · 이 절은 $2"; fi
done
# 🔵 도구 줄이 정말 --target tools 인지. 여기가 '-' 면 runner 가 구워지고,
#    그 이미지는 **오류 없이** 쓸모가 없다.
t=$(row_f astools 5); g=$(row_f astools 3)
if [ "${t:-}" = "tools" ] && [ "${g:-}" = "$AS_TOOLS_TAG" ]; then
  ok "SITES 표의 astools 줄이 $AS_TOOLS_TAG · --target tools 다"
else
  bad "SITES 표의 astools 줄이 어긋난다 — 태그 ${g:-없음} · target ${t:-없음} (기대 $AS_TOOLS_TAG · tools)"
fi

# ── ㄱ) 🔴 A/S Dockerfile 이 담는 길 — **굽는 까닭이 여기 있다** ─────
#   🔴 A/S 의 tools 는 drizzle/ 을 **안 담는다**(볼륨이다).
#   🔴 **그리고 src/ · scripts/ · vendor/ 를 통째로 담는다** — 이번에 바뀐 53개가
#      들어가는 길이고, **셋 다 이번 판에 바뀌었다.**
check_copy() { # 1 Dockerfile 2 정규식 3 있어야 하나(yes/no) 4 사람이 읽을 말
  if grep -qE "$2" "$1" 2>/dev/null; then
    if [ "$3" = yes ]; then ok "$4"; else bad "🔴 $4"; fi
  else
    if [ "$3" = yes ]; then bad "🔴 $4"; else ok "$4"; fi
  fi
}
printf '\n  ── A/S Dockerfile — **tools 스테이지가 무엇을 담는가** (굽는 판정의 근거)\n'
if grep -q '^FROM .* AS tools' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "A/S 에 tools 스테이지가 있다 (--target tools 가 선다)"
else
  bad "A/S 에 tools 스테이지가 없다 — --target tools 가 실패한다"
fi
# 🔴 **COPY 줄을 통째로 찍는다** — 「담는다/안 담는다」를 사람이 눈으로 본다.
printf '%s\n' "      ── tools 스테이지의 COPY 줄 (파일에서 그대로 읽었다)"
awk '/^FROM .* AS tools/{inb=1} inb && /^FROM .* AS runner/{inb=0} inb && /^COPY /{print "      " NR "줄  " $0}' "$ASDIR/Dockerfile"
check_copy "$ASDIR/Dockerfile" '^COPY .*scripts \./scripts'   yes "🔴 A/S tools 가 **scripts/ 를 통째로 담는다** — 이번 판은 그 안이 **$AS_CHANGED_SCRIPTS_WANT 개** 바뀐다 (**굽는 까닭 ㄷ**)"
check_copy "$ASDIR/Dockerfile" '^COPY .*package\.json'        yes "A/S tools 가 package.json·tsconfig.json 을 담는다"
check_copy "$ASDIR/Dockerfile" '^COPY .*src \./src'           yes "🔴 A/S tools 가 **src/ 를 통째로 담는다** — 이번에 바뀐 $AS_CHANGED_SRC_WANT 개가 여기다 (**굽는 까닭 ㄷ**)"
check_copy "$ASDIR/Dockerfile" '^COPY .*vendor \./vendor'     yes "🔴 A/S tools 가 **vendor/ 를 담는다** — 🔴 이번 판은 그 안이 **바뀌었다**(dss-core · **굽는 까닭 ㄹ**)"
check_copy "$ASDIR/Dockerfile" '^COPY .*drizzle \./drizzle'   no  "🔴 A/S tools 는 drizzle/ 을 **안 담는다** — 🔴 그래서 0128 은 **묶음으로 보내야** 한다"
# 🔴 그 COPY 줄들이 **tools 스테이지 안**에 있는가 — 줄번호로 가른다. 바깥에 있으면
#    위 grep 은 통과하는데 도구에는 안 담긴다.
LT=$(grep -n '^FROM .* AS tools'  "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
LR=$(grep -n '^FROM .* AS runner' "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
LS=$(grep -n '^COPY .*src \./src' "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
LC=$(grep -n '^COPY .*scripts \./scripts' "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
LV=$(grep -n '^COPY .*vendor \./vendor' "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
say "tools ${LT:-?}줄 · 'COPY … scripts' ${LC:-?}줄 · 'COPY … src' ${LS:-?}줄 · 'COPY … vendor' ${LV:-?}줄 · runner ${LR:-?}줄"
say "🔵 [실측 2026-11-13] 그 자리는 tools 60 · scripts 68 · src 69 · vendor 77 · runner 90 이다."
if isnum "${LT:-}" && isnum "${LS:-}" && isnum "${LR:-}" && [ "$LT" -lt "$LS" ] && [ "$LS" -lt "$LR" ]; then
  ok "src/ 를 담는 COPY 가 **tools 스테이지 안**에 있다 (${LS}줄)"
else
  bad "🔴 'COPY … src ./src' 가 tools 스테이지 안이 아니다 (tools ${LT:-?} · COPY ${LS:-?} · runner ${LR:-?})"
  say "🔴 그러면 **이번에 바뀐 src/ $AS_CHANGED_SRC_WANT 개가 도구에 안 담긴다** — 판정을 다시 해야 한다."
  doubt
fi
if isnum "${LT:-}" && isnum "${LC:-}" && isnum "${LR:-}" && [ "$LT" -lt "$LC" ] && [ "$LC" -lt "$LR" ]; then
  ok "scripts/ 를 담는 COPY 가 **tools 스테이지 안**에 있다 (${LC}줄 — 🔴 이번 판은 그 안이 $AS_CHANGED_SCRIPTS_WANT 개 바뀐다)"
else
  bad "🔴 'COPY … scripts ./scripts' 가 tools 스테이지 안이 아니다 (tools ${LT:-?} · COPY ${LC:-?} · runner ${LR:-?})"
  say "🔴 그러면 **이번에 고친 시험 목록 셋이 이미지에 안 담기고**, 새 시험 아홉이 조용히 안 돈다."
  doubt
fi
# 🔴 **이번 판에서 특히 중요한 줄이다** — vendor/ 가 바뀌었기 때문이다.
if isnum "${LT:-}" && isnum "${LV:-}" && isnum "${LR:-}" && [ "$LT" -lt "$LV" ] && [ "$LV" -lt "$LR" ]; then
  ok "vendor/ 를 담는 COPY 가 **tools 스테이지 안**에 있다 (${LV}줄 — 🔴 **이번 판의 새 스키마가 들어가는 길**)"
  say "🔴 2026-09-21 에 그 줄이 없어 운영에서 **Cannot find module '@dss/core/schema'** 로"
  say "   도구가 전부 죽었습니다 — 연락서 이식·db:migrate·db:preflight·야간 완전삭제 전부."
else
  bad "🔴 'COPY … vendor ./vendor' 가 tools 스테이지 안이 아니다 (tools ${LT:-?} · COPY ${LV:-?} · runner ${LR:-?})"
  say "🔴 그러면 **이번 판의 새 스키마가 도구에 안 담긴다** — db:migrate 가 새 표를 모른다."
  doubt
fi
# 🔴 tools 가 runner **앞**이어야 한다 — 마지막 스테이지가 docker build 의 기본 대상이다.
if isnum "${LT:-}" && isnum "${LR:-}" && [ "$LT" -lt "$LR" ]; then
  ok "A/S Dockerfile 이 tools(${LT}줄) 를 runner(${LR}줄) **앞**에 둔다 (--target 없이 구우면 runner 가 나온다)"
else
  bad "🔴 A/S Dockerfile 의 차례가 tools ${LT:-?} · runner ${LR:-?} 다 — **--target 없이 구운 것이 도구가 된다**"
  doubt
fi

# ── ㄴ) .dockerignore ───────────────────────────────────────────────
printf '\n'
DIG="$ASDIR/.dockerignore"
if [ ! -s "$DIG" ]; then
  bad "A/S 에 .dockerignore 가 없거나 비었다 — .env 와 .git 이 이미지로 따라 들어간다"
else
  if grep -qE '^scripts/?$' "$DIG" 2>/dev/null; then
    bad "🔴 A/S 의 .dockerignore 가 scripts/ 를 막는다 — 도구가 통째로 빠지고 **시험 목록도 빠진다**"
  else
    ok "A/S 의 .dockerignore 가 scripts/ 를 막지 않는다 (이번에 고친 시험 목록 셋이 들어간다)"
  fi
  if grep -qE '^src/?$' "$DIG" 2>/dev/null; then
    bad "🔴 A/S 의 .dockerignore 가 src/ 를 막는다 — **이번에 바뀐 $AS_CHANGED_SRC_WANT 개가 통째로 빠진다**"
  else
    ok "A/S 의 .dockerignore 가 src/ 를 막지 않는다 (이번에 바뀐 $AS_CHANGED_SRC_WANT 개가 들어간다)"
  fi
  if grep -qE '^vendor/?$' "$DIG" 2>/dev/null; then
    bad "🔴 A/S 의 .dockerignore 가 vendor/ 를 막는다 — **이번 판의 새 공용 스키마가 빠진다**"
  else
    ok "A/S 의 .dockerignore 가 vendor/ 를 막지 않는다 (🔴 **이번 판은 그 안이 바뀌었다**)"
  fi
  if grep -qE '^\.next/?$' "$DIG" 2>/dev/null; then
    ok "A/S 의 .dockerignore 가 .next 를 막는다 (개발 서버를 띄워 둔 채로 구워도 된다)"
  else
    bad "A/S 의 .dockerignore 가 .next 를 안 막는다 — 호스트의 .next 가 빌드 문맥에 들어간다"
  fi
fi
# ── ㄷ) 🔵 npm 명령 — **이번 판도 안 늘었다.** 41번 잣대가 안 걸린다 ──
printf '\n  ── npm 명령 (🔵 이번 판도 **안 늘었다** — 굽는 까닭이 아니다)\n'
PL=$(git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | wc -l | tr -d ' ')
say "A/S package.json 의 diff ${PL:-못 쟀다}줄 (적어 둔 값 $AS_PKG_LINES_WANT)"
if [ "${PL:-x}" = "$AS_PKG_LINES_WANT" ]; then
  ok "package.json 이 안 바뀌었다 (0줄) — 🔵 **41번 잣대는 이번 판에 안 걸린다**"
  say "🔴 그렇다고 도구를 안 굽는 것이 아니다 — **ㄷ(담기는 것)과 ㄹ(공용 스키마)** 가 걸린다."
else
  note "package.json 이 ${PL:-?}줄 바뀌었다 — $AS_PKG_LINES_WANT 줄을 적어 두었다. 아래 diff 를 사람이 보세요"
  git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | head -24 | sed 's/^/      /'
fi
NN=$(count_scripts < "$ASDIR/package.json" 2>/dev/null | tr -d ' ')
WW=$(git -C "$ASDIR" show "$AS_BASE:package.json" 2>/dev/null | count_scripts | tr -d ' ')
say "A/S scripts 항목 — 기준 ${WW:-?} → 지금 ${NN:-?} (적어 둔 값 $AS_NPM_WAS → $AS_NPM_NOW)"
if [ "${WW:-x}" = "$AS_NPM_WAS" ] && [ "${NN:-x}" = "$AS_NPM_NOW" ]; then
  ok "명령 수가 적어 둔 그대로다 ($AS_NPM_WAS → $AS_NPM_NOW · 안 늘고 안 줄었다)"
elif isnum "${NN:-}" && isnum "${WW:-}" && [ "${NN:-0}" -lt "${WW:-0}" ]; then
  bad "🔴 명령이 ${WW} 에서 ${NN} 로 **줄었다** — 사라진 명령을 그날 부르면 Missing script 다"
  doubt
else
  note "명령 수가 기준 ${WW:-?} → 지금 ${NN:-?} 다 — $AS_NPM_WAS → $AS_NPM_NOW 를 적어 두었다. 사람이 보세요"
fi
NEWCNT=$(git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | grep -c '^+    "' || true)
say "A/S package.json 에서 **새로 더해진 scripts 줄** ${NEWCNT:-0}개 (기대 $AS_NEW_NPM_WANT)"
if [ "${NEWCNT:-x}" = "$AS_NEW_NPM_WANT" ]; then
  ok "새 npm 명령이 $AS_NEW_NPM_WANT 개다 — 🔵 이번 판의 목적물은 **화면의 배지 설정**이다"
else
  note "새 명령 줄이 ${NEWCNT:-?}개다 — $AS_NEW_NPM_WANT 을 기대했다. 늘었으면 꼬리말을 고쳐야 한다"
fi
# 🔴 사라지면 안 되는 아홉 — 🔴 **db:migrate 가 여기 있다.** 이번 판은 그것을 실제로 쓴다.
printf '\n  ── 사라지면 안 되는 npm 명령 아홉 (🔴 이번 판은 db:preflight·db:migrate 를 **실제로 쓴다**)\n'
KEEP_SEEN=0; KEEP_OK=0
for s in $AS_KEEP_NPM; do
  KEEP_SEEN=$((KEEP_SEEN+1))
  now=$(grep -c "\"$s\"" "$ASDIR/package.json" 2>/dev/null || true)
  printf '      %-34s 지금 %s\n' "$s" "${now:-0}"
  if [ "${now:-0}" -ge 1 ] 2>/dev/null; then KEEP_OK=$((KEEP_OK+1)); fi
done
if [ "$KEEP_SEEN" = "$AS_KEEP_NPM_WANT" ]; then ok "지킬 명령 $AS_KEEP_NPM_WANT 개를 다 봤다 (표본이 비지 않았다)"
else bad "명령을 ${KEEP_SEEN}개만 봤다 — $AS_KEEP_NPM_WANT 개를 기대했다. 목록이 깨졌다"; fi
if [ "$KEEP_OK" = "$AS_KEEP_NPM_WANT" ]; then
  ok "지킬 명령 $AS_KEEP_NPM_WANT 개가 **지금 판에 다 있다**"
  say "🔴 **이번 판도 --migrate 가 db:migrate 를 부른다** — 없으면 그 자리에서 Missing script 로 멈춥니다."
else
  bad "🔴 지금 판에 있는 명령이 ${KEEP_OK}/$AS_KEEP_NPM_WANT 개다 — **사라진 것이 있다**"; doubt
fi

# ══ 🔴 바뀐 목록을 **한 번만 뽑아 둔다** — pathspec 글롭 함정을 피한다 ══
#   🔴 src/app/(app)/… 을 git 의 pathspec 으로 물으면 **글롭**으로 읽혀 조용히
#      0줄이 돌아온다. 🔴 **이번 판에는 그런 경로가 2개 있다**(60번은 25개였다).
CHANGED_ALL=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" 2>/dev/null)
CHANGED_SRC=$(printf '%s\n' "$CHANGED_ALL" | grep '^src/' || true)
BORN_ALL=$(git -C "$ASDIR" diff --name-only --diff-filter=A "$AS_BASE..HEAD" 2>/dev/null)
# 🔵 잣대가 살아 있는지 표본으로 본다 — 안 그러면 아래 수가 전부 못 믿을 값이다.
PROBE_FX=$(printf '%s\n' 'src/app/(app)/settings/page.tsx' \
  | grep -Fxc 'src/app/(app)/settings/page.tsx' || true)
PROBE_FY=$(printf '%s\n' 'src/app/x/settings/page.tsx' \
  | grep -Fxc 'src/app/(app)/settings/page.tsx' || true)
say "표본 — 괄호가 든 경로를 글자 그대로 맞대기 ${PROBE_FX:-?}(기대 1) · 글롭으로 풀린 꼴 ${PROBE_FY:-?}(기대 0)"
if [ "${PROBE_FX:-0}" = "1" ] && [ "${PROBE_FY:-1}" = "0" ]; then
  ok "경로 맞대기 잣대가 살아 있다 (괄호를 **글자 그대로** 본다)"
else
  bad "🔴 경로 맞대기 잣대가 죽었다 — 아래 수가 전부 못 믿을 값이다. 멈추세요"
  doubt
fi
# 🔴 **이번 판의 목록에 괄호·대괄호가 몇 개인가** — 60번은 25개였고 이번은 2개다.
#    🔴 **0 이면 ✗ 가 아니라 ⚠️ 다** — 그때는 위 잣대가 「필요 없는 검사」가 된 것이다.
BRK=$(printf '%s\n' "$AS_CHANGED_SRC" "$AS_CHANGED_SCRIPTS" | grep -c '[][()]' || true)
say "이번 판의 목록에서 괄호·대괄호가 든 경로 ${BRK:-0}개 (적어 둔 값 2 — 🔴 60번은 25개였다)"
if isnum "${BRK:-}" && [ "${BRK:-0}" -ge 1 ]; then
  ok "괄호가 든 경로가 ${BRK}개다 — **글롭 함정이 살아 있는 판**이라 위 잣대가 꼭 필요하다"
  say "🔵 그래서 표식 일곱 중 **하나를 일부러 그런 경로에** 두었습니다(app/(app)/layout.tsx)."
else
  note "괄호가 든 경로가 ${BRK:-0}개다 — 2개를 기대했다. 목록을 사람이 보세요"
fi

# ── ㄹ) 🔴 도구 닫힘 — **이번 판에도 하나도 안 바뀐다** ──────────────
#   🔴 **0 을 「안 재는 것」으로 만들지 않는다** — 아홉이 저장소에 다 있는지 먼저
#      보고(이름이 바뀌면 0 이 나와 조용히 지나간다), 그 다음에 바뀐 수를 센다.
printf '\n  ── A/S 도구 닫힘 (목록 %s개 · 바뀐 것 %s개를 기대)\n' "$AS_TOOLS_CALLED_WANT" "$AS_TOOLS_CALLED_CHANGED_WANT"
CL_SEEN=0; CL_HIT=0
while IFS= read -r f; do
  [ -n "${f:-}" ] || continue
  CL_SEEN=$((CL_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 저장소에 없다 — **닫힘 목록이 낡았다.** 닫힘을 다시 재세요"
    continue
  fi
  if printf '%s\n' "$CHANGED_ALL" | grep -Fxq "$f"; then
    CL_HIT=$((CL_HIT+1)); say "🔴 바뀌었다 · 도구가 부른다 — $f"
  else
    say "🔵 안 바뀌었다 — $f"
  fi
done <<CLEOF
$(printf '%s\n' "$AS_TOOLS_CALLED" | grep -v '^[[:space:]]*$')
CLEOF
say "닫힘 목록 ${CL_SEEN}개를 봤고, 그중 바뀐 것 ${CL_HIT}개 (적어 둔 수 $AS_TOOLS_CALLED_CHANGED_WANT)"
if [ "$CL_SEEN" = "$AS_TOOLS_CALLED_WANT" ]; then ok "닫힘 목록 $AS_TOOLS_CALLED_WANT 개를 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
else bad "닫힘 목록을 ${CL_SEEN}개만 봤다 — $AS_TOOLS_CALLED_WANT 개를 기대했다. 목록이 깨졌다"; fi
if [ "${CL_HIT:-x}" = "$AS_TOOLS_CALLED_CHANGED_WANT" ]; then
  ok "도구가 부르는 길에서 바뀐 파일이 ${CL_HIT}개다 — 적어 둔 그대로 (**ㄴ 잣대가 안 걸린다**)"
  say "🔴 그래도 **도구는 굽습니다** — ㄷ(담기는 것 $AS_TOOLS_CHANGED_WANT 개)과 ㄹ(공용 스키마)이 걸립니다."
else
  note "도구가 부르는 길에서 ${CL_HIT:-?}개가 바뀌었다 — ${AS_TOOLS_CALLED_CHANGED_WANT}개를 적어 두었다"
  say "🔵 달라도 **굽는 판정은 안 흔들린다**(ㄷ·ㄹ 때문에 어차피 굽는다). 사람이 보세요."
fi
# 🔴 **반대 방향으로도 한 번 더 센다** — 이번에 바뀐 모듈을 scripts/ 가 부르는가.
#    🔵 /test-lists/ 를 빼고 **import 줄로만** 센다 — 목록 파일에 이름이 적혀 있는
#       것은 import 가 아니다(58번이 데인 자리다).
printf '\n  ── 🔴 이번에 바뀐 것을 scripts/ 가 **import 로** 부르는가 (기대 %s · 목록 파일은 안 센다)\n' "$AS_SCRIPTS_IMPORT_WANT"
RAW_HIT=0; IMP_HIT=0
for key in $AS_IMPORT_KEYS; do
  n=$(grep -rlE "^import .*$key|from \"[^\"]*$key" "$ASDIR/scripts" 2>/dev/null | grep -v '/test-lists/' | wc -l | tr -d ' ')
  r=$(grep -rl "$key" "$ASDIR/scripts" 2>/dev/null | wc -l | tr -d ' ')
  printf '      %-34s import %s개 · (참고) 글자만 든 파일 %s개\n' "$key" "${n:-0}" "${r:-0}"
  IMP_HIT=$((IMP_HIT + ${n:-0}))
  RAW_HIT=$((RAW_HIT + ${r:-0}))
done
say "scripts/ 가 이번 판의 모듈을 import 하는 파일 ${IMP_HIT}개 (기대 $AS_SCRIPTS_IMPORT_WANT)"
say "🔵 글자만 든 파일은 ${RAW_HIT}개다 — **시험 목록 파일에 적힌 이름**까지 센 수다."
if [ "$IMP_HIT" = "$AS_SCRIPTS_IMPORT_WANT" ]; then
  ok "도구가 이번에 바뀐 모듈을 ${IMP_HIT}개 파일에서 부른다 — 적어 둔 그대로 (**ㄴ 잣대의 다른 쪽도 안 걸린다**)"
else
  note "scripts/ 가 ${IMP_HIT}개 부른다 — $AS_SCRIPTS_IMPORT_WANT 을 적어 두었다. 🔵 굽는 판정은 안 흔들린다"
fi
# 🔴 **「목록 파일이라서 안 센다」를 값으로 받쳐 둔다** — 위 수가 어디서 왔는지 보인다.
RAW_OUT=$(grep -rl "$AS_IMPORT_RE" "$ASDIR/scripts" 2>/dev/null | grep -vc '/test-lists/' || true)
say "그중 test-lists 밖의 파일 ${RAW_OUT:-0}개 (🔵 이번 판은 **0 이 정답**이다)"
if [ "${RAW_OUT:-x}" = "0" ]; then
  ok "test-lists 밖에서는 한 개도 안 걸린다 — **위 import 0 과 앞뒤가 맞는다**"
else
  note "test-lists 밖에서 ${RAW_OUT}개가 걸린다 — 0 을 기대했다. 위 import 수와 어긋난다. 사람이 보세요"
  grep -rl "$AS_IMPORT_RE" "$ASDIR/scripts" 2>/dev/null | grep -v '/test-lists/' | head -6 | sed 's/^/      /'
fi

# ── ㅁ) 🔴 **「담기는 것」으로 센다 — 굽는 까닭 전부가 여기 있다** ─────
#   🔴 **이번 판은 수가 둘로 갈린다.** git 이 세는 「담기는 것」은 **53** 인데,
#      그중 「vendor/dss-core」 는 **포인터 한 줄**이라 이미지 안에 그 경로의 파일이
#      없다. 이미지 안에서 한 장씩 물어볼 **파일 목록은 52** 다.
#      🔴 두 수를 같은 칸에 적으면 **멀쩡한 판이 ✗** 다.
printf '\n  ── 담기는 것으로 세기 (🔴 굽는 까닭 **ㄷ·ㄹ**)\n'
AS_TOOLS_PATHS="scripts/ src/ package.json drizzle.config.ts tsconfig.json vendor/"
AS_TOOLS_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $AS_TOOLS_PATHS 2>/dev/null | wc -l | tr -d ' ')
AS_ALL_CHANGED=$(printf '%s\n' "$CHANGED_ALL" | grep -c . || true)
NVEN=$(printf '%s\n' "$CHANGED_ALL" | grep -c '^vendor/' || true)
say "A/S  tools 가 담는 것 중 달라진 파일 ${AS_TOOLS_CHANGED:-못 쟀다}개 (적어 둔 수 $AS_TOOLS_CHANGED_WANT)"
say "A/S  저장소 전체에서 달라진 파일 ${AS_ALL_CHANGED:-못 쟀다}개 (적어 둔 수 $AS_ALL_CHANGED_WANT)"
say "A/S  그중 vendor/ ${NVEN:-0}개 (적어 둔 수 $AS_TOOLS_VENDOR_WANT — 🔴 **포인터 한 줄이다**)"
if isnum "${AS_TOOLS_CHANGED:-}" && [ "${AS_TOOLS_CHANGED:-0}" -ge 1 ]; then
  ok "🔴 A/S 도구를 구울 까닭이 있다 — 담기는 것 중 달라진 파일 ${AS_TOOLS_CHANGED}개"
else
  bad "🔴 담기는 것 중 달라진 파일이 ${AS_TOOLS_CHANGED:-못 쟀다}개다 — **도구를 구울 까닭이 없다.** 멈추고 알릴 것"
  doubt
fi
# 🔴 **52 + 1 = 53 인가** — 파일 목록과 git 의 수가 어긋나는 자리를 **값으로** 잇는다.
if [ "$((AS_CHANGED_ALL_WANT + AS_TOOLS_VENDOR_WANT))" = "$AS_TOOLS_CHANGED_WANT" ]; then
  ok "파일 목록 $AS_CHANGED_ALL_WANT + vendor 포인터 $AS_TOOLS_VENDOR_WANT = 담기는 것 $AS_TOOLS_CHANGED_WANT (이 파일 안의 수가 서로 맞는다)"
else
  bad "🔴 $AS_CHANGED_ALL_WANT + $AS_TOOLS_VENDOR_WANT 이 $AS_TOOLS_CHANGED_WANT 가 아니다 — 이 파일의 상수가 어긋났다"
fi
if [ "${NVEN:-x}" = "$AS_TOOLS_VENDOR_WANT" ]; then
  ok "범위의 vendor/ 변경이 ${NVEN}개다 — 🔴 **60번은 0 이었다**(그 판은 서브모듈이 안 움직였다)"
  printf '%s\n' "$CHANGED_ALL" | grep '^vendor/' | sed 's/^/      /'
else
  bad "🔴 범위의 vendor/ 변경이 ${NVEN:-?}개다 — $AS_TOOLS_VENDOR_WANT 개를 기대했다"
  doubt
fi
# 🔴 **바깥이 3 이고 전부 drizzle/ 인가** — 「바깥이 3」과 「drizzle 이 3」은
#    한쪽만 깨질 수 있는 **다른 말**이다.
OUTSIDE=$((${AS_ALL_CHANGED:-0} - ${AS_TOOLS_CHANGED:-0}))
NDRZ=$(printf '%s\n' "$CHANGED_ALL" | grep -c '^drizzle/' || true)
say "A/S  tools 바깥에서 달라진 파일 ${OUTSIDE}개 (적어 둔 수 $AS_OUTSIDE_WANT — 🔴 **전부 drizzle/ 이다**)"
say "drizzle/ 에서 바뀐 파일 ${NDRZ:-0}개 (기대 $AS_OUTSIDE_DRIZZLE_WANT)"
if [ "${AS_TOOLS_CHANGED:-x}" = "$AS_TOOLS_CHANGED_WANT" ] && [ "${AS_ALL_CHANGED:-x}" = "$AS_ALL_CHANGED_WANT" ]; then
  ok "담기는 것 ${AS_TOOLS_CHANGED_WANT} · 전체 ${AS_ALL_CHANGED_WANT} · 바깥 ${AS_OUTSIDE_WANT} — 적어 둔 그대로"
else
  note "담기는 것 ${AS_TOOLS_CHANGED:-?} · 전체 ${AS_ALL_CHANGED:-?} · 바깥 ${OUTSIDE} 다 — 적어 둔 것은 ${AS_TOOLS_CHANGED_WANT}·${AS_ALL_CHANGED_WANT}·${AS_OUTSIDE_WANT} 다"
  printf '%s\n' "      ── 바깥에서 바뀐 것"
  printf '%s\n' "$CHANGED_ALL" \
    | grep -vE '^(scripts/|src/|package\.json$|drizzle\.config\.ts$|tsconfig\.json$|vendor/)' | head -10 | sed 's/^/      /'
fi
if [ "${NDRZ:-x}" = "$AS_OUTSIDE_DRIZZLE_WANT" ] && [ "${OUTSIDE:-x}" = "$AS_OUTSIDE_DRIZZLE_WANT" ]; then
  ok "바깥 ${AS_OUTSIDE_WANT}개가 **전부 drizzle/ 이다** — 묶음 하나로 다 덮인다"
  printf '%s\n' "$CHANGED_ALL" | grep '^drizzle/' | sed 's/^/      /'
else
  bad "🔴 바깥 ${OUTSIDE}개 중 drizzle/ 이 ${NDRZ:-?}개다 — 둘 다 ${AS_OUTSIDE_DRIZZLE_WANT} 를 기대했다"
  say "🔴 drizzle/ 밖에 바뀐 것이 있으면 **묶음으로도 이미지로도 안 가는 파일**이 있다는 뜻이다."
  doubt
fi

# ── ㅂ) 🔴 이번 판이 바꾼 **52개가 정말 그 52개인가** ────────────────
printf '\n  ── 🔴 이번 판이 바꾼 src/ 파일 %s개가 **그 목록 그대로인가**\n' "$AS_CHANGED_SRC_WANT"
SRC_SEEN=0; SRC_OK=0
while IFS= read -r f; do
  [ -n "${f:-}" ] || continue
  SRC_SEEN=$((SRC_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 지금 저장소에 없다 — 목록이 낡았다"; continue
  fi
  if printf '%s\n' "$CHANGED_SRC" | grep -Fxq "$f"; then
    SRC_OK=$((SRC_OK+1))
  else
    bad "🔴 $f 가 **이번 범위에서 안 바뀌었다** — 목록이 낡았다"
  fi
done <<SRCEOF
$(printf '%s\n' "$AS_CHANGED_SRC" | grep -v '^[[:space:]]*$')
SRCEOF
NSRC=$(printf '%s\n' "$CHANGED_SRC" | grep -c . || true)
say "적어 둔 ${SRC_SEEN}개 중 실제로 바뀐 것 ${SRC_OK}개 · 범위의 src/ 변경은 ${NSRC:-0}개"
if [ "$SRC_SEEN" = "$AS_CHANGED_SRC_WANT" ] && [ "$SRC_OK" = "$AS_CHANGED_SRC_WANT" ] && [ "${NSRC:-x}" = "$AS_CHANGED_SRC_WANT" ]; then
  ok "src/ 변경 ${AS_CHANGED_SRC_WANT}개가 적어 둔 목록과 **정확히 같다** (더도 덜도 없다)"
else
  bad "🔴 적어 둔 ${SRC_SEEN} · 맞은 것 ${SRC_OK} · 실제 ${NSRC:-?} 다 — 셋 다 ${AS_CHANGED_SRC_WANT} 여야 한다"
  printf '%s\n' "$CHANGED_SRC" | head -20 | sed 's/^/      /'
  doubt
fi
# 🔴 **scripts/ 는 3개다** — 60번은 2 였다.
printf '\n  ── 🔴 이번 판이 바꾼 scripts/ 파일 %s개 (🔴 60번은 2 였다)\n' "$AS_CHANGED_SCRIPTS_WANT"
CHANGED_SCR=$(printf '%s\n' "$CHANGED_ALL" | grep '^scripts/' || true)
SCR_SEEN=0; SCR_OK=0
while IFS= read -r f; do
  [ -n "${f:-}" ] || continue
  SCR_SEEN=$((SCR_SEEN+1))
  if printf '%s\n' "$CHANGED_SCR" | grep -Fxq "$f"; then SCR_OK=$((SCR_OK+1))
  else bad "🔴 $f 가 이번 범위에서 안 바뀌었다 — 목록이 낡았다"; fi
done <<SCREOF
$(printf '%s\n' "$AS_CHANGED_SCRIPTS" | grep -v '^[[:space:]]*$')
SCREOF
NSCR=$(printf '%s\n' "$CHANGED_SCR" | grep -c . || true)
say "적어 둔 ${SCR_SEEN}개 중 실제로 바뀐 것 ${SCR_OK}개 · 범위의 scripts/ 변경은 ${NSCR:-0}개"
printf '%s\n' "$CHANGED_SCR" | grep -v '^[[:space:]]*$' | sed 's/^/      /'
if [ "$SCR_SEEN" = "$AS_CHANGED_SCRIPTS_WANT" ] && [ "$SCR_OK" = "$AS_CHANGED_SCRIPTS_WANT" ] && [ "${NSCR:-x}" = "$AS_CHANGED_SCRIPTS_WANT" ]; then
  ok "scripts/ 에서 바뀐 파일이 ${AS_CHANGED_SCRIPTS_WANT}개다 — **시험 목록 셋이다**"
  say "🔵 그것이 **새 시험이 아홉 장**인 것과 앞뒤가 맞습니다 — 등록할 자리가 셋이었습니다."
else
  bad "🔴 적어 둔 ${SCR_SEEN} · 맞은 것 ${SCR_OK} · 실제 ${NSCR:-?} 다 — 셋 다 ${AS_CHANGED_SCRIPTS_WANT} 여야 한다"
  doubt
fi
# 🔴 **49 + 3 + 1 + 3 = 56 인가** — 네 목록이 저장소 전체 변경을 남김없이 덮는지 본다.
#    🔴 60번은 셋(src·scripts·drizzle)이었다. **이번 판은 vendor 가 하나 더 있다.**
if [ "$((${NSRC:-0} + ${NSCR:-0} + ${NVEN:-0} + ${NDRZ:-0}))" = "$AS_ALL_CHANGED_WANT" ]; then
  ok "src/ ${NSRC} + scripts/ ${NSCR} + vendor/ ${NVEN} + drizzle/ ${NDRZ} = ${AS_ALL_CHANGED_WANT} — 저장소 전체 변경과 **딱 맞는다**"
else
  bad "🔴 src/ ${NSRC:-?} + scripts/ ${NSCR:-?} + vendor/ ${NVEN:-?} + drizzle/ ${NDRZ:-?} 가 ${AS_ALL_CHANGED_WANT} 가 아니다 — 어느 쪽에도 안 든 변경이 있다"
  doubt
fi
# ══ 🔴 **새로 생긴 파일 26개** — 60번은 20개였다 ═══════════════════════
printf '\n  ── 🔴 이번에 **새로 생긴 파일 %s개**가 그 스물여섯인가 (🔴 60번은 20개였다)\n' "$AS_BORN_ALL_WANT"
BORN_SRC_N=$(printf '%s\n' "$BORN_ALL" | grep -c '^src/' || true)
BORN_N=$(printf '%s\n' "$BORN_ALL" | grep -c . || true)
say "이번 범위의 새 파일 — src/ 안 ${BORN_SRC_N:-0}개 · 전체 ${BORN_N:-0}개 (기대 $AS_BORN_SRC_WANT · $AS_BORN_ALL_WANT)"
BRN_SEEN=0; BRN_OK=0
while IFS= read -r f; do
  [ -n "${f:-}" ] || continue
  BRN_SEEN=$((BRN_SEEN+1))
  if printf '%s\n' "$BORN_ALL" | grep -Fxq "$f"; then BRN_OK=$((BRN_OK+1))
  else bad "🔴 $f 가 **이번 범위에서 새로 생긴 파일이 아니다** — 목록이 낡았다"; fi
done <<BRNEOF
$(printf '%s\n' "$AS_BORN_SRC" | grep -v '^[[:space:]]*$')
BRNEOF
say "적어 둔 src/ 새 파일 ${BRN_SEEN}개 중 실제로 새것인 것 ${BRN_OK}개 (기대 $AS_BORN_SRC_WANT)"
printf '%s\n' "$BORN_ALL" | grep '^drizzle/' | sed 's/^/      (drizzle) /'
if [ "$BRN_SEEN" = "$AS_BORN_SRC_WANT" ] && [ "$BRN_OK" = "$AS_BORN_SRC_WANT" ] \
   && [ "${BORN_SRC_N:-x}" = "$AS_BORN_SRC_WANT" ] && [ "${BORN_N:-x}" = "$AS_BORN_ALL_WANT" ]; then
  ok "새 파일이 **src/ ${AS_BORN_SRC_WANT} + drizzle/ 2 = ${AS_BORN_ALL_WANT}개**다 — 적어 둔 목록 그대로"
  say "🔵 drizzle/ 쪽 둘은 **0128 의 .sql 과 스냅샷**입니다 — 묶음으로 갑니다."
  say "🔵 **지운 파일은 0개**입니다(--diff-filter=A 로 센 수와 전체가 맞습니다)."
  say "🔴 새 시험이 아홉 장이므로 **목록 등록**이 아래에서 선행 조건입니다."
else
  bad "🔴 새 파일이 src/ ${BORN_SRC_N:-?} · 전체 ${BORN_N:-?} · 목록 ${BRN_OK}/${BRN_SEEN} 다 — ${AS_BORN_SRC_WANT}·${AS_BORN_ALL_WANT} 을 기대했다"
  printf '%s\n' "$BORN_ALL" | head -30 | sed 's/^/      /'
  doubt
fi
# 🔴 **지운 파일이 0개인가** — 이 배포는 지우는 것이 없다고 전제한다.
GONE=$(git -C "$ASDIR" diff --name-only --diff-filter=D "$AS_BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
say "이번 범위에서 **지워진** 파일 ${GONE:-?}개 (기대 0)"
if [ "${GONE:-1}" = "0" ]; then ok "지워진 파일이 0개다 (이 배포는 **더하기만 한다**)"
else bad "🔴 지워진 파일이 ${GONE}개다 — 0 을 기대했다. 꼬리말과 눈 확인 목록을 사람이 다시 보세요"; doubt; fi
# 🔴 **새 시험 아홉이 목록 파일에 등록돼 있는가**
#    🔴 등록이 빠지면 **새 시험이 오류 없이 조용히 안 돈다** — 이 저장소에 기록된 함정이다.
# 🔴 **목록 파일은 CRLF 다 — 줄 전체로 맞대는 「-Fx」 가 「\r」 때문에 안 맞는다.**
#    🔴 개발 PC 의 Git Bash grep 은 \r 를 스스로 걷어내 **거기서는 안 드러난다.**
#       리눅스 컨테이너의 GNU grep 은 안 그런다 — NAS 가 바로 그쪽이다.
#    🔵 그래서 **「tr -d」 로 \r 를 걷어낸 뒤** 맞댄다. 「-Fx」 는 **살린다.**
# 🔴 **「무조건 yes」인 검사가 되지 않게** 없는 경로 하나를 **일부러 함께 묻는다.**
printf '\n  ── 🔴 이번에 **새로 만든 시험 %s개**가 scripts/test-lists 에 등록돼 있는가 (빠지면 조용히 안 돈다)\n' "$AS_NEW_TESTS_WANT"
say "🔴 목록 파일은 **CRLF** 다 — \\r 를 걷어낸 뒤 줄 전체로 맞댄다(그냥 -Fx 면 안 맞는다)."
REG_LIST=$(cat "$ASDIR"/scripts/test-lists/*.txt 2>/dev/null | tr -d '\r')
REG_LINES=$(printf '%s\n' "$REG_LIST" | grep -c . || true)
say "목록 파일을 \\r 걷어내고 ${REG_LINES:-0}줄 읽었다 (기대 $AS_TESTLIST_MIN_LINES 이상 · 2026-11-13 실측 3807)"
REG_SEEN=0; REG_OK=0
while IFS= read -r t; do
  [ -n "${t:-}" ] || continue
  REG_SEEN=$((REG_SEEN+1))
  n=$(printf '%s\n' "$REG_LIST" | grep -cFx -- "$t" || true)
  printf '      %-72s 목록에 적힌 줄 %s개\n' "$t" "${n:-0}"
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then REG_OK=$((REG_OK+1)); fi
done <<REGEOF
$(printf '%s\n' "$AS_NEW_TESTS" | grep -v '^[[:space:]]*$')
REGEOF
REG_MISS_N=$(printf '%s\n' "$REG_LIST" | grep -cFx -- "$REG_PROBE_MISS" || true)
printf '      %-72s 목록에 적힌 줄 %s개 (표본 · 기대 0)\n' "$REG_PROBE_MISS" "${REG_MISS_N:-0}"
if ! isnum "${REG_LINES:-}" || [ "${REG_LINES:-0}" -lt "$AS_TESTLIST_MIN_LINES" ]; then
  bad "🔴 목록을 ${REG_LINES:-0}줄밖에 못 읽었다 — **빈 결과는 삼켜진 오류일 수 있다.** 멈추세요"
  doubt
elif [ "${REG_MISS_N:-1}" != "0" ]; then
  bad "🔴 **없는 경로가 걸렸다** — 줄 전체 일치가 깨졌다. 위 아홉의 yes 도 못 믿는다"
  doubt
elif [ "$REG_SEEN" = "$AS_NEW_TESTS_WANT" ] && [ "$REG_OK" = "$AS_NEW_TESTS_WANT" ]; then
  ok "새 시험 $AS_NEW_TESTS_WANT 개가 전부 목록에 등록돼 있다 (새 단언이 실제로 돈다 · 없는 경로는 안 걸렸다)"
  say "🔵 넷은 components.txt · 넷은 unit.txt · 하나는 **db.txt** 에 적혀 있습니다(2026-11-13 실측)."
  say "🔵 그래서 **scripts/ 변경이 3개**인 것과 앞뒤가 맞습니다 — 60번은 둘이었습니다."
else
  bad "🔴 등록된 것이 ${REG_OK}/${REG_SEEN} 개다 — $AS_NEW_TESTS_WANT 을 기대했다. **빠진 시험은 조용히 안 돈다**"
  doubt
fi
# 🔵 목록 파일 **넷**이 다 있는가 — 이번 판은 그중 셋을 고친다.
LSF_SEEN=0; LSF_OK=0
while IFS= read -r f; do
  [ -n "${f:-}" ] || continue
  LSF_SEEN=$((LSF_SEEN+1))
  if [ -s "$ASDIR/$f" ]; then LSF_OK=$((LSF_OK+1)); else bad "🔴 $f 가 저장소에 없다"; fi
done <<LSFEOF
$(printf '%s\n' "$AS_TESTLIST_FILES" | grep -v '^[[:space:]]*$')
LSFEOF
if [ "$LSF_SEEN" = "$AS_TESTLIST_FILES_WANT" ] && [ "$LSF_OK" = "$AS_TESTLIST_FILES_WANT" ]; then
  ok "시험 목록 파일 ${AS_TESTLIST_FILES_WANT}장이 다 있다 (unit · components · db · db-safety)"
else
  bad "🔴 목록 파일이 ${LSF_OK}/${LSF_SEEN} 장이다 — ${AS_TESTLIST_FILES_WANT}장을 기대했다"
fi

# ── 🔴 저장소 뿌리의 .html — 🔴 **이번 판도 19 → 19 라 아무것도 안 가른다** ──
#   🔵 이미지 안에서는 「standalone 이 뿌리 파일을 **옮기기는 하는가**」로만 쓴다.
#   🔴 **quotePath 를 꺼야 센다**(한글 파일명). 안 끄면 조용히 0 이 나온다.
say "── 저장소 뿌리의 .html — 🔴 **이번 판도 안 는다.** 그래서 판을 가르는 데 못 쓴다"
HW=$(git -c core.quotePath=false -C "$ASDIR" ls-tree --name-only "$AS_BASE" -- . 2>/dev/null | grep -c '\.html$' || true)
HN=$(git -c core.quotePath=false -C "$ASDIR" ls-tree --name-only HEAD -- . 2>/dev/null | grep -c '\.html$' || true)
say "저장소 뿌리의 .html — 기준 ${HW:-?} → 지금 ${HN:-?} (적어 둔 값 $AS_ROOT_HTML_WAS → $AS_ROOT_HTML_NOW · **같아야 한다**)"
if [ "${HW:-x}" = "$AS_ROOT_HTML_WAS" ] && [ "${HN:-x}" = "$AS_ROOT_HTML_NOW" ] && [ "${HW:-x}" = "${HN:-y}" ]; then
  ok "뿌리의 .html 이 기준판과 지금 **둘 다 $AS_ROOT_HTML_NOW** 다 (이번 범위에 .html 변경이 없다)"
  say "🔴 **그래서 이 수로는 이번 판을 못 가릅니다** — 앱 이미지 쪽은 이 수를"
  say "   「standalone 이 뿌리 파일을 옮기기는 하는가」로만 씁니다(0 이면 ✗)."
else
  note "뿌리의 .html 이 ${HW:-?} → ${HN:-?} 다 — $AS_ROOT_HTML_WAS → $AS_ROOT_HTML_NOW 를 적어 두었다"
  say "🔵 **굽는 판정은 안 흔들린다.** 다만 아래 이미지 안 검사의 기대값을 사람이 고쳐야 한다."
fi

# ── ㅅ) 🔴 포털·PO 쪽에서 달라진 파일 — **둘 다 0 이어야 한다** ───────
printf '\n  ── 안 굽는 둘에서 달라진 파일 (둘 다 0이어야 한다)\n'
for pair in "dss-auth $AUTH_BASE $AUTH_CHANGED_WANT" "dss-po $PO_BASE $PO_CHANGED_WANT"; do
  set -- $pair
  N=$(git -C "$DEV/$1" diff --name-only "$2..HEAD" 2>/dev/null | wc -l | tr -d ' ')
  say "$1 에서 달라진 파일 ${N:-못 쟀다}개 (적어 둔 수 $3 — 안 굽는다)"
  if [ "${N:-x}" = "$3" ]; then
    ok "$1 에서 달라진 파일이 0개다 — **안 굽는 것이 맞다**"
  else
    bad "🔴 $1 에서 달라진 파일이 ${N:-못 쟀다}개다 — 0개를 기대했다. **그쪽도 구워야 할 수 있다.** 멈추고 알릴 것"
    git -C "$DEV/$1" diff --name-only "$2..HEAD" 2>/dev/null | head -20 | sed 's/^/      /'
    doubt
  fi
done

# ── ㅇ) 🔴 **이번 판인가를 글자로 가른다** ───────────────────────────
#   🔴 「파일이 바뀌었다」와 「그 안에 새 코드가 있다」는 다른 말이다.
#   🔴 **커밋이 일곱이라** 일곱을 **일곱 커밋에 하나씩** 흩어 두었다 — 하나만 보면
#      「한 커밋이 빠진 판」을 못 가른다.
printf '\n  ── A/S 이번 판의 표식 일곱 (기준판에 0 · 지금 판에 1 이상 · **일곱 커밋을 덮는다**)\n'
MK_SEEN=0; MK_OK=0
while IFS='|' read -r s f; do
  [ -n "${s:-}" ] || continue
  MK_SEEN=$((MK_SEEN+1))
  # 🔴 -F 로 **글자 그대로** 센다. 표식에 괄호·따옴표·느낌표가 섞여 있고,
  #    정규식으로 읽히면 같은 글자가 다른 뜻이 되는 날이 온다.
  was=$(git -C "$ASDIR" show "$AS_BASE:$f" 2>/dev/null | grep -cF -- "$s" || true)
  now=$(grep -cF -- "$s" "$ASDIR/$f" 2>/dev/null || true)
  printf '      %-54s %-62s 기준 %s → 지금 %s\n' "$s" "$f" "${was:-0}" "${now:-0}"
  if [ "${was:-1}" = "0" ] && [ "${now:-0}" -ge 1 ] 2>/dev/null; then MK_OK=$((MK_OK+1)); fi
done <<MKEOF
$(printf '%s\n' "$AS_MARKS" | grep -v '^[[:space:]]*$')
MKEOF
if [ "$MK_SEEN" = "$AS_MARKS_WANT" ] && [ "$MK_OK" = "$AS_MARKS_WANT" ]; then
  ok "표식 $AS_MARKS_WANT 개가 전부 **이번에 생겼다** (옛 판이 아니다)"
  say "🔵 일곱이 일곱 커밋을 하나씩 덮습니다 — ① 밑바탕 · ② 설정 화면 · ③ 수리건 화면 ·"
  say "   ④ 자리 일곱→여섯 · ⑤ 내자·기타건 · ⑥ 보기 배지 하나 · ⑦ 「정상」 제거."
  say "🔴 ④ 와 ⑦ 은 **빼는 커밋**이라 더해진 이름이 없습니다 — **남은 줄의 모양**으로 잡았습니다."
  say "🔵 ③ 은 **괄호가 든 경로**입니다 — 글롭 함정이 살아 있는 판이라 일부러 거기 두었습니다."
else
  bad "🔴 표식이 ${MK_OK}/${MK_SEEN} 개다 — $AS_MARKS_WANT/$AS_MARKS_WANT 을 기대했다. 목록이 낡았거나 범위가 틀렸다"
  doubt
fi
# 🔴 **등록부의 모양을 수로도 잰다** — 글자 하나로만 재면 세는 길이 죽어도 모른다.
#    🔴 커밋 ④ 가 자리를 일곱에서 여섯으로 줄인 판이다. 그 결과를 **수**로 본다.
printf '\n  ── 🔴 등록부의 모양 — 배지 %s · 자리 %s · 쌍 %s\n' "$BV_BADGES_WANT" "$BV_PLACES_WANT" "$BV_PAIRS_WANT"
BVF="$ASDIR/$BV_FILE"
if [ -s "$BVF" ]; then
  NPLACE=$(grep -c "$BV_PLACE_RE" "$BVF" || true)
  NBADGE=$(grep -c "$BV_BADGE_RE" "$BVF" || true)
  NPAIR=$(awk '/^export const BADGES/{b=1} b{print} b && /^\];/{exit}' "$BVF" | grep -oE "$BV_PAIR_RE" | wc -l | tr -d ' ')
  NGONE=$(grep -cF "$BV_REMOVED_PLACE" "$BVF" || true)
  say "자리 ${NPLACE:-0}개 · 배지 ${NBADGE:-0}개 · 쌍 ${NPAIR:-0}개 · 걷어낸 자리($BV_REMOVED_PLACE) ${NGONE:-0}번"
  if [ "${NPLACE:-x}" = "$BV_PLACES_WANT" ] && [ "${NBADGE:-x}" = "$BV_BADGES_WANT" ] \
     && [ "${NPAIR:-x}" = "$BV_PAIRS_WANT" ] && [ "${NGONE:-1}" = "0" ]; then
    ok "등록부가 **배지 $BV_BADGES_WANT · 자리 $BV_PLACES_WANT · 쌍 $BV_PAIRS_WANT** 이고 걷어낸 자리가 0번이다"
    say "🔵 그 쌍 수가 **설정 화면의 체크상자 총수**입니다 — 배포 뒤 눈으로 셀 수 있습니다."
  else
    bad "🔴 등록부가 자리 ${NPLACE:-?} · 배지 ${NBADGE:-?} · 쌍 ${NPAIR:-?} · 걷어낸 자리 ${NGONE:-?}번 이다"
    say "🔴 ${BV_PLACES_WANT}·${BV_BADGES_WANT}·${BV_PAIRS_WANT}·0 을 기대했다. 꼬리말의 「체크상자 29개」도 함께 틀린다."
    doubt
  fi
else
  unk "등록부의 모양" "$BV_FILE 을 못 읽었다"
fi
# 🔴 **바뀐 49장이 전부 새 내용인가** — 날짜 글자 하나로 덮는다.
#    🔴 **49 가 아니라 46 이다.** 아래 셋에는 그 날짜가 없다(실측) — 49 로 두면 가짜 ✗ 다.
#    🔵 **기준판 src/ 에 0파일**이라 60번의 「겹침 0」 줄은 **늘 참이라 뺐다.**
FRW=$(git -C "$ASDIR" grep -lF "$FRESH_MARK" "$AS_BASE" -- src/ 2>/dev/null | wc -l | tr -d ' ')
say "$FRESH_MARK 가 든 src/ 파일 — 기준판 ${FRW:-?}개 (적어 둔 값 $FRESH_MARK_BASE_FILES)"
if [ "${FRW:-x}" = "$FRESH_MARK_BASE_FILES" ]; then
  ok "기준판 src/ 에 $FRESH_MARK 가 **한 파일도 없다** — 그래서 이 글자로 「새 내용」을 잴 수 있다"
  say "🔴 **그래도 앱 번들 표식으로는 못 씁니다** — 주석의 날짜라 번들에서 지워집니다."
else
  bad "🔴 기준판 src/ 에 $FRESH_MARK 가 ${FRW:-?}파일 있다 — $FRESH_MARK_BASE_FILES 을 기대했다"
  say "🔴 기준판에 있으면 「이번에 바뀐 장에 이 글자가 있다」가 **옛 판에서도 참**이 되어 잣대가 죽는다."
  doubt
fi
FR_SEEN=0; FR_OK=0; FR_MISS_LIST=""
while IFS= read -r f; do
  [ -n "${f:-}" ] || continue
  FR_SEEN=$((FR_SEEN+1))
  n=$(grep -cF -- "$FRESH_MARK" "$ASDIR/$f" 2>/dev/null || true)
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then FR_OK=$((FR_OK+1)); else FR_MISS_LIST="$FR_MISS_LIST$f
"; fi
done <<FREOF
$(printf '%s\n' "$AS_CHANGED_SRC" | grep -v '^[[:space:]]*$')
FREOF
say "바뀐 ${FR_SEEN}장 중 $FRESH_MARK 가 든 것 ${FR_OK}장 (기대 ${AS_FRESH_HIT_WANT}/${AS_CHANGED_SRC_WANT})"
printf '%s' "$FR_MISS_LIST" | grep -v '^[[:space:]]*$' | sed 's/^/      (없음) /'
# 🔴 **없는 셋이 적어 둔 그 셋인가** — 수만 맞고 다른 장이 빠졌을 수 있다.
FR_MISS_MATCH=0; FR_MISS_SEEN=0
while IFS= read -r f; do
  [ -n "${f:-}" ] || continue
  FR_MISS_SEEN=$((FR_MISS_SEEN+1))
  if printf '%s' "$FR_MISS_LIST" | grep -Fxq "$f"; then FR_MISS_MATCH=$((FR_MISS_MATCH+1)); fi
done <<FRMEOF
$(printf '%s\n' "$AS_FRESH_MISS" | grep -v '^[[:space:]]*$')
FRMEOF
say "적어 둔 「날짜가 없는 장」 ${FR_MISS_SEEN}개 중 실제로 없는 것 ${FR_MISS_MATCH}개 (기대 ${AS_FRESH_MISS_WANT})"
if [ "$FR_SEEN" = "$AS_CHANGED_SRC_WANT" ] && [ "$FR_OK" = "$AS_FRESH_HIT_WANT" ] \
   && [ "$FR_MISS_SEEN" = "$AS_FRESH_MISS_WANT" ] && [ "$FR_MISS_MATCH" = "$AS_FRESH_MISS_WANT" ]; then
  ok "바뀐 ${AS_CHANGED_SRC_WANT}장 중 ${AS_FRESH_HIT_WANT}장이 **새 내용**이고, 나머지 셋이 **적어 둔 그 셋**이다"
  say "🔴 60번은 여기가 77/77 이었습니다 — 이번 판은 **46/49** 입니다. 49 로 두면 가짜 ✗ 입니다."
else
  bad "🔴 ${FR_OK}/${FR_SEEN} 장에 $FRESH_MARK 가 있고, 없는 셋 중 맞은 것이 ${FR_MISS_MATCH}/${FR_MISS_SEEN} 이다"
  say "🔴 ${AS_FRESH_HIT_WANT}/${AS_CHANGED_SRC_WANT} 과 ${AS_FRESH_MISS_WANT} 을 기대했다."
  doubt
fi
# 🔴 구운 **앱** 이미지에서 쓸 표식이 기준판 src/ 에 **0파일**인가.
ASMW=$(git -C "$ASDIR" grep -lF "$BUILD_MARK" "$AS_BASE" -- src/ 2>/dev/null | wc -l | tr -d ' ')
ASMN=$(git -C "$ASDIR" grep -lF "$BUILD_MARK" HEAD        -- src/ 2>/dev/null | wc -l | tr -d ' ')
say "$BUILD_MARK 가 든 src/ 파일 — 기준 ${ASMW:-?} → 지금 ${ASMN:-?} (기대 0 → 1 이상 · 2026-11-13 실측 0 → 6)"
if [ "${ASMW:-1}" = "0" ] && [ "${ASMN:-0}" -ge 1 ] 2>/dev/null; then
  ok "앱 표식 $BUILD_MARK 이 **이번에 생겼다** — 번들 안에서 이 글자로 판을 가른다"
  say "🔵 **배지 열쇠 문자열**이라 minify 가 못 바꿉니다(화면이 badgeKey=\"…\" 로 묻습니다)."
  say "🔴 **번들에서 세어 본 적은 없습니다** — 개발 PC 에 .next/standalone 이 없습니다."
  say "   그래서 이미지 안 검사는 **「합이 1 이상」으로만** 잽니다. ✗ 가 나면 검사부터 의심하세요."
else
  bad "🔴 앱 표식이 기준 ${ASMW:-?} → 지금 ${ASMN:-?} 다 — 0 → 1 이상을 기대했다"
  doubt
fi
# 🔵 뒷걸음 방지 ASCII 셋 — **쉰네째·쉰세째·쉰여섯째가 올린 글자**다. **기준판에도 있어야** 한다.
KP_SEEN=0; KP_OK=0
for pair in "$KEEP_MARK 쉰네째" "$KEEP_MARK2 쉰세째" "$KEEP_MARK4 쉰여섯째"; do
  set -- $pair
  KP_SEEN=$((KP_SEEN+1))
  KPW=$(git -C "$ASDIR" grep -lF "$1" "$AS_BASE" -- src/ 2>/dev/null | wc -l | tr -d ' ')
  KPN=$(git -C "$ASDIR" grep -lF "$1" HEAD        -- src/ 2>/dev/null | wc -l | tr -d ' ')
  say "$1 가 든 src/ 파일 — 기준 ${KPW:-?} → 지금 ${KPN:-?} (둘 다 1 이상 — **$2 가 올린 글자**)"
  if [ "${KPW:-0}" -ge 1 ] 2>/dev/null && [ "${KPN:-0}" -ge 1 ] 2>/dev/null; then
    KP_OK=$((KP_OK+1))
    ok "뒷걸음 방지 표식 $1 이 기준판에도 지금에도 있다 ($2 것이 안 사라졌다)"
  else
    bad "🔴 $1 이 기준 ${KPW:-?} · 지금 ${KPN:-?} 다 — 둘 다 1 이상이어야 한다"
    doubt
  fi
done
if [ "$KP_SEEN" = "3" ] && [ "$KP_OK" = "3" ]; then
  ok "뒷걸음 방지 ASCII **셋**을 다 봤다 (🔴 60번은 둘이었다 — 쉰여섯째 것을 보탰다)"
else
  bad "🔴 뒷걸음 방지 ASCII 가 ${KP_OK}/${KP_SEEN} 개다 — 3/3 을 기대했다"
fi
# 🔴 앱 번들에서 쓸 **한글** 표식 셋을 8진 이스케이프로 다시 만들어 본다.
#    🔴 만들기가 틀리면 0 이 나와 「없다」로 읽히므로 **바이트 수를 먼저 본다.**
ko_probe() { # 1 8진문자열 2 기대 바이트 3 zero|both 4 사람이 부르는 말
  local K B W N
  K=$(printf "$1")
  B=$(printf '%s' "$K" | wc -c | tr -d ' ')
  say "$4 — 8진으로 다시 만든 글자 ${B}바이트 (기대 $2)"
  if [ "${B:-0}" != "$2" ]; then
    bad "🔴 $4 를 못 만들었다 (${B:-?}바이트 · 기대 $2) — 이미지 안 검사가 못 선다"
    doubt
    return
  fi
  W=$(git -C "$ASDIR" grep -lF "$K" "$AS_BASE" -- src/ 2>/dev/null | wc -l | tr -d ' ')
  N=$(git -C "$ASDIR" grep -lF "$K" HEAD        -- src/ 2>/dev/null | wc -l | tr -d ' ')
  say "   그 글자가 든 src/ 파일 — 기준 ${W:-?} → 지금 ${N:-?}"
  case "$3" in
    zero)
      if [ "${W:-1}" = "0" ] && [ "${N:-0}" -ge 1 ] 2>/dev/null; then
        ok "$4 가 **이번에 생겼다** (기준 0 → 지금 ${N} · 소스 쪽)"
      else
        bad "🔴 $4 가 기준 ${W:-?} → 지금 ${N:-?} 다 — 0 → 1 이상을 기대했다"; doubt
      fi ;;
    both)
      if [ "${W:-0}" -ge 1 ] 2>/dev/null && [ "${N:-0}" -ge 1 ] 2>/dev/null; then
        ok "$4 가 기준판에도 지금에도 있다 (뒷걸음 방지가 선다)"
      else
        bad "🔴 $4 가 기준 ${W:-?} · 지금 ${N:-?} 다 — 둘 다 1 이상이어야 한다"; doubt
      fi ;;
  esac
}
ko_probe "$APP_MARK_KO_OCT"   "$APP_MARK_KO_BYTES"   zero "이번 판의 한글 표식 ①(새 탭 이름)"
ko_probe "$APP_MARK2_KO_OCT"  "$APP_MARK2_KO_BYTES"  zero "이번 판의 한글 표식 ②(**마지막 커밋**의 등록부 설명)"
ko_probe "$KEEP_MARK3_KO_OCT" "$KEEP_MARK3_KO_BYTES" both "뒷걸음 방지 ③ — 쉰다섯째(59번)가 올린 한글 글자"
say "🔴 **뒷걸음 방지가 이번 판에서 셋 → 넷이 됐다.** 60번에는 ①②③ 셋뿐이었다 —"
say "   ④(domesticOrders.view)가 없으면 **60번이 올린 판보다 옛 나무를 구웠는지** 가릴 길이 없다."
say "🔴 **지시서가 음성 표식으로 제안한 「납기 지연 / 정상」은 안 쓴다** — [실측] 기준판 0파일 ·"
say "   지금 4파일(전부 주석)이라, 도구 이미지에서는 **있는 것이 정상**이고 앱 번들에서는"
say "   **옛 판에서도 0** 이라 아무것도 안 가른다. 그 자리를 위 한글 표식 ② 로 바꿨다."

# ── ㅈ) 🔴 **도구 셋이 아직 읽기만 하는가** ──────────────────────────
#   🔵 이번 판이 만든 도구는 없다. 그래도 재는 까닭은 **한 번 열리면 아무도 안 닫는다**이다.
printf '\n  ── 🔴 도구 셋이 읽기만 하는가 (부르는 꼴로 센다 · 주석에 속지 않는다)\n'
PROBE_W=$(printf '%s\n' 'await db.update(repairCases).set({});' | grep -cE "$RO_WRITE_RE" || true)
PROBE_C=$(printf '%s\n' ' * 그 도구에는 --apply 깃발이 없다. INSERT·UPDATE·DELETE 도 없다.' | grep -cE "$RO_WRITE_RE" || true)
say "표본 — 진짜 쓰는 줄 ${PROBE_W:-?}(기대 1) · 그 낱말이 든 주석 줄 ${PROBE_C:-?}(기대 0)"
if [ "${PROBE_W:-0}" = "1" ]; then ok "읽기 전용 잣대가 살아 있다 (진짜 쓰는 줄 하나를 제대로 잡았다)"
else bad "🔴 읽기 전용 잣대가 죽었다 — 아래 「0줄」이 공짜 통과다. 멈추세요"; fi
if [ "${PROBE_C:-1}" = "0" ]; then ok "낱말만 적힌 주석은 **안 센다** (멀쩡한 도구가 가짜 ✗ 를 안 받는다)"
else bad "🔴 주석의 낱말을 쓰는 문장으로 센다 — **머리말에 설명을 적은 도구가 전부 빨개진다**"; fi
RO_SEEN=0; RO_OK=0
for f in $RO_TOOLS; do
  RO_SEEN=$((RO_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then bad "🔴 $f 가 없다 — 목록이 낡았다"; continue; fi
  w=$(grep -cE "$RO_WRITE_RE" "$ASDIR/$f" || true)
  tx=$(grep -c 'db.transaction' "$ASDIR/$f" || true)
  ap=$(grep -cF -- '--apply' "$ASDIR/$f" || true)
  printf '      %-46s 쓰는 꼴 %s · 트랜잭션 %s · (참고) --apply 글자 %s\n' "$f" "${w:-0}" "${tx:-0}" "${ap:-0}"
  if [ "${w:-1}" = "0" ] && [ "${tx:-1}" = "0" ]; then RO_OK=$((RO_OK+1)); fi
done
if [ "$RO_SEEN" = "$RO_TOOLS_WANT" ] && [ "$RO_OK" = "$RO_TOOLS_WANT" ]; then
  ok "도구 $RO_TOOLS_WANT 개가 **쓰는 문장 0 · 트랜잭션 0** 이다 (운영에서 돌려도 한 글자도 안 바뀐다)"
  say "🔵 위 「--apply 글자」가 1 로 나오는 줄이 있어도 **주석**입니다 — 그래서 그 수로 재지 않습니다."
else
  bad "🔴 읽기 전용인 것이 ${RO_OK}/${RO_SEEN} 개다 — ${RO_TOOLS_WANT}/${RO_TOOLS_WANT} 을 기대했다"
  say "🔴 **운영 DB 에 쓸 수 있는 도구를 굽는 판이다.** 멈추고 알리세요."
  doubt
fi
if [ -s "$ASDIR/$RO_TEST" ]; then
  ok "$RO_TEST 가 저장소에 있다 (이 규율을 원본 글자로 지키는 짝이 아직 있다)"
else
  note "$RO_TEST 가 없다 — 54번이 올린 것으로 적어 두었다. 사람이 보세요"
fi

# ── ㅊ) 🔴 **알고도 안 고친 것** — PO 가 새 거절 코드를 모른다 ───────
#   🔵 53번에서 넘어온 것이다. 이번 판도 안 고친다(PO 를 안 굽는다). ⚠️ 라 배포를 막지 않는다.
printf '\n  ── 🔴 PO 가 A/S 의 거절 코드를 아는가 (53번에서 넘어온 할 일)\n'
if [ -s "$PODIR/$PO_GATEWAY" ]; then
  PCODE=$(grep -c "$PO_MISSING_CODE" "$PODIR/$PO_GATEWAY" || true)
  ASCODE=$(grep -c "$PO_MISSING_CODE" "$ASDIR/$PO_MUT" || true)
  say "A/S $PO_MUT 의 $PO_MISSING_CODE ${ASCODE:-0}번"
  say "PO  $PO_GATEWAY 의 $PO_MISSING_CODE ${PCODE:-0}번 (53~60번 실측 0 — **아직 모른다**)"
  if [ "${ASCODE:-0}" -ge 1 ] 2>/dev/null && [ "${PCODE:-1}" = "0" ]; then
    note "🔴 **PO 는 아직 $PO_MISSING_CODE 를 모른다.** PO 에서 기타건을 [완료 처리] 하면"
    say "   A/S 가 적어 보낸 안내 문장이 **화면에 안 뜨고** 「모르는 응답」으로 떨어집니다."
    say "   🔵 자료는 안 깨집니다 — A/S 는 한 글자도 안 쓴 채 거절합니다."
    say "   🔵 지금 운영에서는 **직원이 PO 에 못 들어갑니다**(2026-11-08 사용자)."
    say "   🔴 **PO 를 다시 여는 날 이식할 것이 셋입니다**(이 코드 · 납품일 새 칸 · 회차 승인)."
  elif [ "${PCODE:-0}" -ge 1 ] 2>/dev/null; then
    ok "PO 가 $PO_MISSING_CODE 를 안다 — 🔵 그 사이에 PO 가 고쳐졌다. 꼬리말의 그 줄은 이제 거짓이다"
  else
    note "A/S 쪽 $PO_MISSING_CODE 가 ${ASCODE:-0}번이다 — 1 이상을 기대했다. 사람이 보세요"
  fi
else
  unk "PO 의 as-gateway" "$PODIR/$PO_GATEWAY 를 못 읽었다"
fi

# ── 6. 태그가 이미 있나 ───────────────────────────────────────────────
printf '\n== 6. 새 태그가 이미 있나\n'
printf '%s\n' "🔵 있으면 **덮어쓴다** — 같은 커밋이면 같은 것이 나오므로 해롭지 않다."
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  rest=${row#*|}; rest=${rest#*|}; TAG=${rest%%|*}
  if docker image inspect "$TAG" >/dev/null 2>&1; then note "$TAG — 이미 있다 (덮어쓴다)"
  else ok "$TAG — 아직 없다"; fi
done
# 🔵 **되돌릴 판이 개발 PC 에 남아 있는가** — NAS 쪽은 61-deploy.sh 가 따로 센다.
for t in "$AS_OLD_TAG" "$AS_TOOLS_OLD_TAG"; do
  if docker image inspect "$t" >/dev/null 2>&1; then say "🔵 옛 판 $t 가 개발 PC 에 있다"
  else say "🔵 옛 판 $t 가 개발 PC 에 없다 — NAS 쪽에 있으면 되돌리기는 된다(거기서 센다)"; fi
done
say "🔵 포털은 dss-auth:2.1 · dss-auth-tools:4 그대로 둔다 — 이번에도 안 굽고 안 갈아 끼운다."
say "🔵 PO 는 dss-po:0.9 그대로 둔다 — 같다."

# ── 7. 산출물을 둘 자리 + 🔴 3000번 개발 서버 ────────────────────────
printf '\n== 7. 산출물을 둘 자리 (tar 둘 + **묶음 하나**)\n'
if [ "$MODE" = "--go" ]; then
  mkdir -p "$OUT" 2>/dev/null
fi
if [ -d "$OUT" ]; then ok "$OUT 가 있다"
elif [ "$MODE" = "--check" ]; then note "$OUT 가 아직 없다 (--go 가 만든다)"
else bad "$OUT 를 못 만들었다"; fi
# 🔵 tar 둘이면 360MB 쯤이고, 🔴 **묶음(약 2.5MB)이 더 붙는다.**
FREEKB=$(df -Pk "$(dirname "$OUT")" 2>/dev/null | awk 'NR==2 {print $4}')
if isnum "${FREEKB:-}"; then
  say "남은 자리 $((FREEKB / 1024))MB (tar 둘이 약 360MB · 🔴 묶음이 약 3MB 더)"
  if [ "$FREEKB" -ge 1000000 ]; then ok "자리가 넉넉하다"
  else bad "자리가 모자란다 — 1GB 이상을 권한다"; fi
else
  unk "남은 자리" "df 가 수를 안 돌려줬다"
fi
# ── 🔴 7-ㄴ. 3000번에 개발 서버가 떠 있는가 ─────────────────────────
#   🔵 .dockerignore 가 .next 를 막으므로 **굽기는 된다**(5절-ㄴ 이 그것을 쟀다).
#   🔴 **✗ 로 세지 않는다.** 떠 있어도 docker build 는 멀쩡하다.
printf '\n  ── 🔴 3000번 개발 서버 (떠 있어도 **굽기는 막지 않는다**)\n'
DEVPORT=$(netstat -ano 2>/dev/null | grep -cE '[^0-9.]3000[[:space:]]' || true)
DEVCODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:3000/ 2>/dev/null)
say "3000번이 보이는 줄 ${DEVPORT:-못 쟀다}개 · HTTP 응답 ${DEVCODE:-없음}"
# 🔴 **한 줄에 || 와 && 를 섞지 않는다** — 셸은 왼쪽부터 묶어 (A||B)&&C 가 된다.
DEVUP=no
if isnum "${DEVPORT:-}" && [ "${DEVPORT:-0}" -ge 1 ]; then DEVUP=yes; fi
case "${DEVCODE:-000}" in (000|'') ;; (*) DEVUP=yes ;; esac
say "판정: 개발 서버 떠 있음 = $DEVUP"
if [ "$DEVUP" = yes ]; then
  note "개발 서버가 **떠 있다** — 🔵 .dockerignore 가 .next 를 막아 **굽기는 됩니다.**"
  say "🔴 다만 이 PC 에서 'npm run build' 를 따로 돌리지 마세요 — 그쪽이 .next 를 두고 다툽니다."
  say "🔵 docker build 는 **빌드 문맥 안에서** 굽습니다(호스트의 .next 를 안 씁니다)."
else
  ok "3000번에 개발 서버가 안 떠 있다 (.next 를 다툴 상대가 없다)"
fi

# ══════════════════════════════════════════════════════════════════════
# ── 8. 🔴 양식 파일 — **이번 판에도 올릴 것이 없다. 그래도 잰다** ─────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **경로를 찍지 않는다.** 이름 · 바이트 · md5 · 수정 시각만 찍는다.
#   🔴 **md5 가 적어 둔 것과 다르면 ✗ 가 아니라 ⚠️ 다** — 사용자가 양식을 고쳤다는
#      뜻이고, 그러면 **올릴 것이 생긴다.** 굽기를 막을 일은 아니다.
printf '\n== 8. 양식 파일 — 열하나가 55·58~60번 값 그대로인가 (경로는 안 찍는다)\n'
tpl_path() { # 1 변수 이름 → 경로(없으면 빈 줄). 🔴 찍지 말 것.
  local v q
  v=$(grep -E "^$1=" "$ASDIR/.env.local" 2>/dev/null | tail -1 | cut -d= -f2-)
  v=$(printf '%s' "$v" | tr -d '\r')
  q=$(printf '%s' "'")
  v=${v#\"}; v=${v%\"}
  v=${v#"$q"}; v=${v%"$q"}
  v=${v# }; v=${v% }
  [ -n "$v" ] || return 0
  to_unix "$v"
}
TPL_SEEN=0; TPL_SAME=0; TPL_DIFF=0; TPL_MISS=0
# 🔴 양식 이름에는 **공백과 한글**이 둘 다 있다. 그래서 while/IFS 로 한 줄씩 읽는다.
while IFS='|' read -r VAR NAME WSZ WM5; do
  [ -n "${VAR:-}" ] || continue
  TPL_SEEN=$((TPL_SEEN+1))
  P=$(tpl_path "$VAR")
  if [ -z "${P:-}" ]; then
    printf '  ✗ %-42s %s — .env.local 에 그 이름이 없다\n' "$VAR" "$NAME"
    TPL_MISS=$((TPL_MISS+1)); continue
  fi
  if [ ! -s "$P" ]; then
    printf '  ✗ %-42s %s — 그 자리에 파일이 없다 (경로는 안 찍는다)\n' "$VAR" "$NAME"
    TPL_MISS=$((TPL_MISS+1)); continue
  fi
  GOTNAME=${P##*/}
  SZ=$(stat -c %s "$P" 2>/dev/null)
  M5=$(md5sum "$P" 2>/dev/null | awk '{print $1}')
  MT=$(date -r "$P" '+%Y-%m-%d %H:%M' 2>/dev/null)
  printf '      %-42s %-26s %8s바이트  %s  %s\n' "$VAR" "$GOTNAME" "${SZ:-?}" "${MT:-?}" "${M5:-?}"
  if [ "$GOTNAME" != "$NAME" ]; then
    printf '  ⚠️ %s 가 가리키는 파일 이름이 %s 다 — **%s 를 적어 두었다.** 운영 쪽도 함께 봐야 한다\n' "$VAR" "$GOTNAME" "$NAME"
  fi
  if [ "${M5:-x}" = "$WM5" ] && [ "${SZ:-x}" = "$WSZ" ]; then
    TPL_SAME=$((TPL_SAME+1))
  else
    TPL_DIFF=$((TPL_DIFF+1))
    printf '  ⚠️ %s 가 적어 둔 것과 **다르다** (적어 둔 %s바이트 %s)\n' "$NAME" "$WSZ" "$WM5"
    printf '%s\n' "      🔵 양식을 고치셨다는 뜻입니다. **굽기는 막지 않습니다.**"
    printf '%s\n' "      🔴 그러면 **올릴 양식이 생긴 것**입니다 — 이 파일에는 양식을 복사하는"
    printf '%s\n' "         절이 없습니다. 되살릴 곳: 51-build.sh 의 8절·꼬리말 ·"
    printf '%s\n' "         51-deploy.sh 의 --templates-prep(1056~1172줄)·--templates-apply(1174~1341줄)."
    printf '%s\n' "         🔵 2026-11-11 에 양식만 올리는 56-stage.sh · 56-templates.sh 도 있습니다."
  fi
done <<TPLEOF
$(printf '%s\n' "$TPLS" | grep -v '^[[:space:]]*$')
TPLEOF
say "양식 ${TPL_SEEN}개를 봤다 (적어 둔 수 $TPL_COUNT_WANT)"
say "적어 둔 것과 같은 것 ${TPL_SAME}개 · 다른 것 ${TPL_DIFF}개 · 못 찾은 것 ${TPL_MISS}개"
if [ "$TPL_SEEN" = "$TPL_COUNT_WANT" ]; then ok "양식 $TPL_COUNT_WANT 개를 다 봤다 (표본이 비지 않았다)"
else bad "양식을 ${TPL_SEEN}개만 봤다 — $TPL_COUNT_WANT 개를 기대했다. TPLS 표가 깨졌다"; fi
if [ "$TPL_MISS" = "0" ]; then ok "양식 $TPL_COUNT_WANT 개가 전부 제자리에 있다"
else bad "양식 ${TPL_MISS}개를 못 찾았다"; doubt; fi
if [ "$TPL_DIFF" = "0" ]; then
  ok "양식 $TPL_COUNT_WANT 개가 **전부 적어 둔 md5 그대로**다 — 🔵 **올릴 양식이 0장이다**"
else
  note "양식 ${TPL_DIFF}개가 적어 둔 것과 다르다 — 위를 보세요. **굽기는 막지 않는다**"
fi
# 🔵 그리고 **이번 범위에 .xlsx 변경이 0줄인가** — 저장소 쪽에서도 따로 본다.
XLSX=$(printf '%s\n' "$CHANGED_ALL" | grep -ci '\.xlsx$' || true)
say "A/S 범위에서 달라진 .xlsx ${XLSX:-0}개 (기대 0)"
if [ "${XLSX:-1}" = "0" ]; then ok "범위에 .xlsx 변경이 0줄이다 (양식 절이 없는 까닭이다)"
else note "범위에 .xlsx 가 ${XLSX}개 있다 — 0 을 기대했다. 양식 올리는 절이 필요할 수 있다"; fi
# 🔴 **vendor/ 는 이제 0 이 아니다** — 60번은 여기가 「0 이어야 한다」였다.
#    🔴 그 줄을 그대로 베끼면 **멀쩡한 판이 ⚠️** 가 된다. 위 5절-ㅁ 에서 이미
#       값으로 쟀으므로, 여기서는 **3절의 포인터 검사와 같은 말인지**만 다시 본다.
say "A/S 범위에서 달라진 vendor/ 파일 ${NVEN:-0}개 (기대 $AS_TOOLS_VENDOR_WANT — 🔴 **60번은 0 이었다**)"
if [ "${NVEN:-x}" = "$AS_TOOLS_VENDOR_WANT" ]; then
  ok "범위에 vendor/ 변경이 ${AS_TOOLS_VENDOR_WANT}줄이다 (3절의 포인터 검사와 같은 말의 다른 쪽)"
else
  bad "🔴 범위에 vendor/ 가 ${NVEN:-?}개다 — $AS_TOOLS_VENDOR_WANT 을 기대했다. 3절과 어긋난다"
  doubt
fi

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$UNK"
if [ "$FAIL" != "0" ] || [ "$UNK" != "0" ]; then
  printf '%s\n' "🔴 멈춘다 — 위 ✗ / ? 를 먼저 보세요. **아무것도 안 구웠다.**"
  exit 1
fi
if [ "$MODE" = "--check" ]; then
  printf '%s\n' "🔵 **아무것도 안 구웠다.** 전부 통과했으니 이어서: --go"
  exit 0
fi
# ══ 굽기 ══════════════════════════════════════════════════════════════
printf '\n%s\n' "════════ 굽는다 (둘) ════════"
BUILT=0; BFAIL=0; TARTABLE=""; MIGLINE=""
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}
  rest=${rest#*|}; BASE=${rest%%|*}; rest=${rest#*|}; TGT=${rest%%|*}
  rest=${rest#*|}; WANTMIG=${rest%%|*}; rest=${rest#*|}; WANTN=${rest%%|*}
  rest=${rest#*|}; PREVSZ=${rest%%|*}; rest=${rest#*|}; PREVTAR=${rest%%|*}
  rest=${rest#*|}; STRICT=${rest%%|*}
  DIR="$DEV/$REPO"
  FILE=$(tar_name "$TAG")
  LOG="$OUT/build-$(printf '%s' "$TAG" | tr ':' '-').log"
  printf '\n── %s  (%s)\n' "$TAG" "$REPO"

  # 🔴 도구 이미지만 --target tools 다. 안 주면 **runner 가 구워지고** 그 안에는
  #    scripts/ 도 package.json 도 없어 오류 없이 쓸모없는 이미지가 된다.
  if [ "$TGT" = "-" ]; then
    printf '    스테이지: 기본(runner)\n'
    ( cd "$DIR" && docker build -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG" | tail -3
    RC=${PIPESTATUS[0]}
  else
    printf '    스테이지: --target %s\n' "$TGT"
    ( cd "$DIR" && docker build --target "$TGT" -t "$TAG" . ) </dev/null 2>&1 | tee "$LOG" | tail -3
    RC=${PIPESTATUS[0]}
  fi
  if [ "${RC:-1}" = "0" ]; then
    printf '  ✓ 구웠다\n'
  else
    printf '  ✗ 굽기 실패 — %s 를 보세요\n' "$LOG"; BFAIL=$((BFAIL+1)); continue
  fi

  # 🔴 docker save 는 작업 폴더로 들어가 **상대경로**로 쓴다(tar 의 드라이브 문자 함정).
  if ( cd "$OUT" && docker save "$TAG" -o "$FILE" ) </dev/null; then
    sz=$(stat -c %s "$OUT/$FILE" 2>/dev/null || wc -c < "$OUT/$FILE")
    printf '  ✓ tar %s (%s바이트)\n' "$FILE" "$sz"
  else
    printf '  ✗ tar 내보내기 실패\n'; BFAIL=$((BFAIL+1)); continue
  fi

  # 🔴 tar 의 Config 를 **빌드 로그의 exporting config** 와 맞댄다.
  #    'docker image inspect' 의 .Id 와는 **애초에 다른 값**이다.
  cfg=$(tar_config_id "$OUT/$FILE")
  exp=$(tr -d '\000' < "$LOG" | grep -oE "exporting config sha256:[0-9a-f]+" | tail -1 | grep -oE "sha256:[0-9a-f]+")
  printf '    tar  %s\n' "${cfg:-못 읽음}"
  printf '    로그 %s\n' "${exp:-없음}"
  if [ -n "$cfg" ] && [ -n "$exp" ] && [ "$cfg" = "$exp" ]; then printf '  ✓ 지문이 빌드 로그와 같다\n'
  elif [ -z "$exp" ]; then printf '  ⚠️ 빌드 로그에 exporting config 가 없다 (buildx 판에 따라 안 찍힌다)\n'
  else printf '  ✗ 지문이 다르다\n'; BFAIL=$((BFAIL+1)); continue; fi

  # ── 🔴 크기 견주기 ① — **지난 판 tar 와** ────────────────────────────
  p=$(pct_diff "$sz" "$PREVSZ")
  if [ -n "${p:-}" ]; then
    printf '    지난 판 %s %s바이트 → 이번 %s바이트 (차이 %s%%)\n' "$PREVTAR" "$PREVSZ" "$sz" "$p"
    if [ "$p" -le 25 ]; then
      printf '  ✓ 지난 판 tar 와 크기가 비슷하다 (차이 %s%% · 25%% 이내)\n' "$p"
    elif [ "$STRICT" = "loose" ] && [ "$p" -le 60 ]; then
      printf '  ⚠️ 지난 판 tar 와 %s%% 다르다 — 기준값이 오래된 줄이라 막지 않습니다.\n' "$p"
    else
      printf '  ✗ 지난 판 tar 와 크기가 %s%% 다르다 — %s 에서는 그만큼이면 멈춘다\n' "$p" "$STRICT"
      printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 라이브러리가 늘거나 베이스 이미지가"
      printf '%s\n' "         바뀌면 정상적으로도 이만큼 뜁니다. 까닭을 알면 SITES 표의 여덟째 칸을"
      printf '%s\n' "         고쳐 적으면 됩니다. 모르겠으면 **멈추고 알리세요.**"
      printf '%s\n' "      🔵 이번 판은 **소스 52개를 고치고 새 파일 24장을 더한 판**입니다 — 크기가"
      printf '%s\n' "         조금 늘 수는 있지만 라이브러리는 안 늘었습니다(package.json diff 0줄)."
      BFAIL=$((BFAIL+1)); continue
    fi
  else
    printf '  ✗ 크기를 못 쟀다 (이번 %s · 지난 판 %s)\n' "${sz:-없음}" "${PREVSZ:-없음}"
    BFAIL=$((BFAIL+1)); continue
  fi

  # ── 🔴 크기 견주기 ② — **그 이미지 자신과** (가지를 둘로 나눈다) ───
  isz=$(docker image inspect "$TAG" --format '{{.Size}}' 2>/dev/null)
  if isnum "${isz:-}" && [ "${isz:-0}" -gt 0 ]; then
    r=$((sz * 100 / isz))
    printf '    이미지 inspect .Size %s바이트 · tar 는 그 %s%%\n' "$isz" "$r"
    if [ "$r" -ge 90 ] && [ "$r" -le 110 ]; then
      printf '  ✓ tar 가 이미지 내용 크기와 거의 같다 (%s%% — containerd 저장소다)\n' "$r"
    elif [ "$r" -ge 10 ] && [ "$r" -le 45 ]; then
      printf '  ✓ tar 가 이미지의 1/4 쯤이다 (%s%% — 고전 저장소다)\n' "$r"
    else
      printf '  ✗ tar 가 이미지의 %s%% 다 — 90~110%% 나 10~45%% 를 기대했다\n' "$r"
      printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 이 비는 docker 의 저장소 방식이 정합니다."
      BFAIL=$((BFAIL+1)); continue
    fi
  else
    printf '  ? 이미지 크기를 못 쟀다 — docker image inspect 가 수를 안 돌려줬다\n'
    BFAIL=$((BFAIL+1)); continue
  fi

  m5=$(md5sum "$OUT/$FILE" | awk '{print $1}')
  printf '    md5  %s\n' "$m5"
  TARTABLE="$TARTABLE$FILE|$sz|$m5|${cfg:-없음}
"
  BUILT=$((BUILT+1))

  # ══ 🔴 이미지 **안**을 센다 — 겉이 아니라 결과 ═══════════════════════
  #   🔴 갈래가 둘이라 **갈래마다 다른 것을 잰다.** 한 잣대로 재면 가짜 ✗ 가 난다.
  #   🔴 **앱과 도구는 담긴 것이 다르다** — 앱은 번들, 도구는 소스 그대로다.
  IMGFAIL=0
  case "$KEY" in
    as)
      printf '\n    ── %s 안을 센다 (번들이다 — 소스가 없다)\n' "$TAG"
      # ① runner 가 맞는가 — tools 에는 /app/server.js 가 없다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/server.js && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '    /app/server.js: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ runner 스테이지가 맞다 (node server.js 를 안다)\n'
      else printf '  ✗ /app/server.js 가 없다 — **runner 가 아닌 것을 구웠다.** 올리지 마세요\n'; IMGFAIL=1; fi
      # ② 🔴 **이번 판의 글자가 번들에 있는가.** 🔵 dueDateFromDomesticOrderShort 는
      #    **배지 열쇠 문자열**이다 — 화면이 badgeKey="…" 로 묻는다. minify 가 못 바꾼다.
      #    🔴 **상수·함수 이름으로 재지 않는다**(머리말).
      #    🔴 **.next/server 와 .next/static 을 둘 다 본다.** runner 가 static 을
      #       따로 복사해 담으므로(Dockerfile 116줄), 서버 쪽만 묻는 것은 반쪽이다.
      #    🔴 **번들에서 세어 본 적이 없다** — 그래서 **「합이 1 이상」으로만** 잰다.
      v=$(docker run --rm -e M="$BUILD_MARK" --entrypoint sh "$TAG" -c 'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
      bs=$(printf '%s' "$v" | awk '{print $1}'); bt=$(printf '%s' "$v" | awk '{print $2}')
      printf '    %s 가 든 파일 — .next/server %s개 · .next/static %s개 (🔴 합이 1 이상이어야 한다)\n' "$BUILD_MARK" "${bs:-?}" "${bt:-?}"
      if isnum "${bs:-}" && isnum "${bt:-}" && [ "$((bs + bt))" -ge 1 ]; then
        printf '  ✓ 번들에 이번 판의 글자가 있다 (옛 판이 아니다 — 배지 설정이 든 판이다)\n'
        printf '%s\n' "      🔵 소스에서는 기준판 0파일 → 지금 6파일입니다(2026-11-13 실측)."
      else
        printf '  ✗ 번들에 %s 가 없다 — **옛 판을 구웠다.** 캐시를 의심하세요\n' "$BUILD_MARK"; IMGFAIL=1
        printf '%s\n' "      🔵 **검사 자신도 의심하세요** — 이 글자는 소스에서만 세어 보았고"
        printf '%s\n' "         **번들에서 세어 본 적이 없습니다**(개발 PC 에 standalone 이 없습니다)."
      fi
      # ③ 🔴 **한글 표식 ①** — [시스템 설정]의 새 탭 이름이다.
      #    🔴 **명령에 한글을 넣지 않는다.** 컨테이너 안에서 8진 이스케이프로 다시
      #       만든다. 🔴 만들기가 틀리면 0 이 나와 「없다」로 읽히므로 **바이트 수를
      #       함께 받아** 가른다(기대 13). 13 이 아니면 ✗ 가 아니라 ⚠️ 「못 쟀다」다.
      v=$(docker run --rm -e O="$APP_MARK_KO_OCT" --entrypoint sh "$TAG" -c 'k=$(printf "$O"); n=$(printf "%s" "$k" | wc -c); printf "%s %s %s\n" "$n" "$(grep -rlF "$k" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$k" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
      kb=$(printf '%s' "$v" | awk '{print $1}'); qs=$(printf '%s' "$v" | awk '{print $2}'); qt=$(printf '%s' "$v" | awk '{print $3}')
      printf '    한글 표식 ①(새 탭 이름) — 만든 글자 %s바이트(기대 %s) · server %s개 · static %s개\n' "${kb:-?}" "$APP_MARK_KO_BYTES" "${qs:-?}" "${qt:-?}"
      if [ "${kb:-0}" != "$APP_MARK_KO_BYTES" ]; then
        printf '  ⚠️ 컨테이너 안에서 한글 표식 ① 을 **못 만들었다**(%s바이트) — 🔴 위 0 은 「없다」가 아니다\n' "${kb:-?}"
        printf '%s\n' "      🔵 위 ② 가 ✓ 라면 판은 맞습니다 — 이 줄만으로 올리기를 막지 않습니다."
      elif isnum "${qs:-}" && isnum "${qt:-}" && [ "$((qs + qt))" -ge 1 ]; then
        printf '  ✓ 새 탭 이름(한글)이 번들에 있다 — **[시스템 설정]이 탭 둘로 뜬다**\n'
      else
        printf '  ✗ 그 한글 글자가 번들에 없다 — **옛 판을 구웠다.** 올리지 마세요\n'; IMGFAIL=1
      fi
      # ③-ㄴ 🔴 **한글 표식 ②** — **마지막 커밋이 넣은 등록부 설명 문구**다.
      #    🔴 그 커밋이 한 일은 「정상」 알약을 **빼는 것**이라, 번들에서 그 커밋을
      #       가리는 **유일한 양성 증거**가 이 글자다. 없으면 **마지막 커밋이 빠진 판**이다.
      v=$(docker run --rm -e O="$APP_MARK2_KO_OCT" --entrypoint sh "$TAG" -c 'k=$(printf "$O"); n=$(printf "%s" "$k" | wc -c); printf "%s %s %s\n" "$n" "$(grep -rlF "$k" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$k" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
      k2b=$(printf '%s' "$v" | awk '{print $1}'); k2s=$(printf '%s' "$v" | awk '{print $2}'); k2t=$(printf '%s' "$v" | awk '{print $3}')
      printf '    한글 표식 ②(마지막 커밋) — 만든 글자 %s바이트(기대 %s) · server %s개 · static %s개\n' "${k2b:-?}" "$APP_MARK2_KO_BYTES" "${k2s:-?}" "${k2t:-?}"
      if [ "${k2b:-0}" != "$APP_MARK2_KO_BYTES" ]; then
        printf '  ⚠️ 한글 표식 ② 를 **못 만들었다**(%s바이트) — 위 0 은 「없다」가 아니다\n' "${k2b:-?}"
      elif isnum "${k2s:-}" && isnum "${k2t:-}" && [ "$((k2s + k2t))" -ge 1 ]; then
        printf '  ✓ **마지막 커밋이 담겼다** — 「정상」 배지가 사라진 판이다\n'
      else
        printf '  ✗ 마지막 커밋의 글자가 없다 — **「정상」 배지가 아직 뜨는 판이다.** 올리지 마세요\n'; IMGFAIL=1
      fi
      # ④ 🔵 **뒷걸음 방지 — 🔴 이번 판에서 셋에서 넷이 됐다.**
      #    ①②④ 는 ASCII(쉰네째·쉰세째·쉰여섯째), ③ 은 한글(쉰다섯째)이다.
      #    🔴 **하나도 빼지 않는다** — 뺀 자리는 다시 넣는 사람이 없다.
      KMN=0
      for KM in "$KEEP_MARK" "$KEEP_MARK2" "$KEEP_MARK4"; do
        KMN=$((KMN+1))
        v=$(docker run --rm -e M="$KM" --entrypoint sh "$TAG" -c 'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
        ks=$(printf '%s' "$v" | awk '{print $1}'); kt=$(printf '%s' "$v" | awk '{print $2}')
        printf '    %s 가 든 파일 — server %s개 · static %s개 (지난 판이 올린 글자)\n' "$KM" "${ks:-?}" "${kt:-?}"
        if isnum "${ks:-}" && isnum "${kt:-}" && [ "$((ks + kt))" -ge 1 ]; then
          printf '  ✓ %s 가 그대로 있다 (뒷걸음친 나무가 아니다)\n' "$KM"
        else
          printf '  ✗ %s 가 없다 — **지난 판보다 옛 나무를 구웠다.** 올리지 마세요\n' "$KM"; IMGFAIL=1
        fi
      done
      if [ "$KMN" = "3" ]; then printf '  ✓ 뒷걸음 방지 ASCII 셋을 다 봤다 (표본이 비지 않았다)\n'
      else printf '  ✗ 뒷걸음 방지 ASCII 를 %s개만 봤다 — 셋을 기대했다\n' "$KMN"; IMGFAIL=1; fi
      # 🔴 뒷걸음 방지 ③ — **쉰다섯째(59번)가 올린 한글 글자.**
      v=$(docker run --rm -e O="$KEEP_MARK3_KO_OCT" --entrypoint sh "$TAG" -c 'k=$(printf "$O"); n=$(printf "%s" "$k" | wc -c); printf "%s %s %s\n" "$n" "$(grep -rlF "$k" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$k" /app/.next/static 2>/dev/null | wc -l)"' 2>/dev/null | tr -d '\r')
      k3b=$(printf '%s' "$v" | awk '{print $1}'); k3s=$(printf '%s' "$v" | awk '{print $2}'); k3t=$(printf '%s' "$v" | awk '{print $3}')
      printf '    뒷걸음 방지 ③(쉰다섯째 한글) — 만든 글자 %s바이트(기대 %s) · server %s개 · static %s개\n' "${k3b:-?}" "$KEEP_MARK3_KO_BYTES" "${k3s:-?}" "${k3t:-?}"
      if [ "${k3b:-0}" != "$KEEP_MARK3_KO_BYTES" ]; then
        printf '  ⚠️ 그 한글을 컨테이너 안에서 **못 만들었다**(%s바이트) — 위 0 은 「없다」가 아니다\n' "${k3b:-?}"
      elif isnum "${k3s:-}" && isnum "${k3t:-}" && [ "$((k3s + k3t))" -ge 1 ]; then
        printf '  ✓ 쉰다섯째가 올린 글자가 그대로 있다 (59번보다 옛 나무가 아니다)\n'
      else
        printf '  ✗ 쉰다섯째가 올린 글자가 없다 — **59번보다 옛 나무를 구웠다.** 올리지 마세요\n'; IMGFAIL=1
      fi
      # ⑤ 🔵 public/ 이 담겼는가 — 없으면 아이콘·정적 파일이 404 가 된다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/public && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '    /app/public: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ public/ 이 담겼다\n'
      else printf '  ✗ public/ 이 없다 — 정적 파일이 404 가 된다\n'; IMGFAIL=1; fi
      # ⑥ 🔴 **뿌리의 .html — 이번 판도 이 수로 판을 못 가른다**(19 → 19).
      #    🔵 여기서 보는 것은 하나뿐이다: **standalone 이 저장소 뿌리를 옮기기는 하는가.**
      v=$(docker run --rm --entrypoint sh "$TAG" -c "ls -1 /app/*.html 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '    /app 바로 아래 .html: %s개 (기준판 %s → 이번 %s — **같은 수다**)\n' "${v:-?}" "$AS_ROOT_HTML_WAS" "$AS_ROOT_HTML_NOW"
      if ! isnum "${v:-}" || [ "${v:-0}" = "0" ]; then
        printf '  ✗ /app 바로 아래에 .html 이 %s개다 — standalone 이 뿌리 파일을 안 옮겼다\n' "${v:-못 읽음}"; IMGFAIL=1
      elif [ "${v:-0}" = "$AS_ROOT_HTML_NOW" ]; then
        printf '  ✓ 뿌리의 .html 이 %s개다 (standalone 이 저장소 뿌리를 옮겼다)\n' "$AS_ROOT_HTML_NOW"
        printf '%s\n' "      🔴 **이 수는 이번 판을 가르지 않습니다** — 기준판도 같은 수입니다."
        printf '%s\n' "         판을 가르는 것은 위 ②③ 입니다."
      else
        printf '  ⚠️ 뿌리의 .html 이 %s개다 — %s개를 기대했다. 그 사이에 문서를 더하거나 지우셨나요\n' "${v:-?}" "$AS_ROOT_HTML_NOW"
        printf '%s\n' "      🔵 **판정과는 무관합니다** — 이 수는 이번 판을 가르지 않습니다."
      fi
      ;;
    astools)
      printf '\n    ── %s 안을 센다 (겉이 아니라 결과 · 🔵 소스가 **글자 그대로** 있다)\n' "$TAG"
      # ① runner 가 아니라 tools 인가
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '      /app/package.json: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ tools 스테이지가 맞다\n'
      else printf '  ✗ /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다\n'; IMGFAIL=1; fi
      # ② 🔴 운영에서 불릴 npm 명령 **아홉**이 이미지 안 package.json 에 있는가.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync check-due-date-overdue check-delivered-date-sync procedures:export procedures:import db:preflight db:migrate; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "9" ]; then printf '  ✓ npm 명령 아홉이 이미지 안에 있다 (db:migrate 도 있다 — --migrate 가 선다)\n'
      else printf '  ✗ 명령이 %s/9 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다**\n' "${got:-0}"; IMGFAIL=1; fi
      # ③ 🔴 **이번 판이 바꾼 52개가 담겼는가.**
      #    🔴 **53 이 아니라 52 다** — vendor/dss-core 는 포인터 한 줄이라 그 경로의
      #       파일이 이미지 안에 없다. 공용 스키마는 아래 ⑤ 가 따로 센다.
      #    🔵 목록에 **괄호가 2개** 있다 — 환경변수로 넘기고 while read 로 받고
      #       큰따옴표로 감싸고 set -f 로 글롭을 끈다(넷을 다 지킨다).
      v=$(docker run --rm -e DSS_FILES="$AS_CHANGED_SRC$AS_CHANGED_SCRIPTS" --entrypoint sh "$TAG" -c 'set -f; printf "%s\n" "$DSS_FILES" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | grep '^no  ' | sed 's/^/      /'
      printf '%s\n' "$v" | grep '^yes ' | head -3 | sed 's/^/      (보기) /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      seen=$(printf '%s\n' "$v" | grep -cE '^(yes|no ) ' || true)
      printf '      본 것 %s개 · 있는 것 %s개 (기대 %s · %s — src/ %s + scripts/ %s)\n' "${seen:-0}" "${got:-0}" "$AS_CHANGED_ALL_WANT" "$AS_CHANGED_ALL_WANT" "$AS_CHANGED_SRC_WANT" "$AS_CHANGED_SCRIPTS_WANT"
      if [ "${seen:-0}" = "$AS_CHANGED_ALL_WANT" ] && [ "${got:-0}" = "$AS_CHANGED_ALL_WANT" ]; then
        printf '  ✓ 이번 판이 바꾼 %s개가 다 담겼다 (표본이 비지 않았다 · 괄호 경로도 그대로 읽혔다)\n' "$AS_CHANGED_ALL_WANT"
      else
        printf '  ✗ 본 것 %s · 있는 것 %s 다 — %s/%s 를 기대했다\n' "${seen:-0}" "${got:-0}" "$AS_CHANGED_ALL_WANT" "$AS_CHANGED_ALL_WANT"; IMGFAIL=1
        printf '%s\n' "      🔴 본 것이 모자라면 **목록을 넘기는 길이 끊긴 것**(글롭 함정)이고,"
        printf '%s\n' "         있는 것만 모자라면 **옛 소스가 담긴 이미지**입니다."
      fi
      # ③-ㄴ 🔴 **그 49장 중 46장이 새 내용인가** — 날짜 글자로 덮는다.
      #    🔴 **49 가 아니다** — 셋에는 그 날짜가 없다(이 파일의 AS_FRESH_MISS).
      #    🔴 **없는 경로 하나를 함께 묻는다** — 「무조건 yes」가 아닌지 가른다.
      v=$(docker run --rm -e DSS_FILES="$AS_CHANGED_SRC" -e M="$FRESH_MARK" --entrypoint sh "$TAG" -c 'set -f; printf "%s\n%s\n" "$DSS_FILES" "src/__dss_probe_no_such_file__.ts" | while IFS= read -r f; do [ -n "$f" ] || continue; if grep -qF -- "$M" "/app/$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | grep '^no  ' | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      probe=$(printf '%s\n' "$v" | grep -c '^no  src/__dss_probe_no_such_file__' || true)
      printf '      새 내용 — %s 가 든 파일 %s개 (기대 %s · 🔴 49 가 아니다 · 없는 경로 하나는 no 여야 한다)\n' "$FRESH_MARK" "${got:-0}" "$AS_FRESH_HIT_WANT"
      if [ "${probe:-0}" != "1" ]; then
        printf '  ✗ **없는 경로가 no 로 안 나왔다** — 「무조건 yes」인 검사다. 위 yes 도 못 믿는다\n'; IMGFAIL=1
      elif [ "${got:-0}" = "$AS_FRESH_HIT_WANT" ]; then
        printf '  ✓ 바뀐 %s장 중 %s장이 **새 내용**이다 (나머지 셋은 그 날짜를 안 적은 장이다)\n' "$AS_CHANGED_SRC_WANT" "$AS_FRESH_HIT_WANT"
      else
        printf '  ✗ 새 내용인 것이 %s/%s 장이다 — **옛 소스가 담긴 이미지일 수 있다.** 올리지 마세요\n' "${got:-0}" "$AS_FRESH_HIT_WANT"; IMGFAIL=1
      fi
      # ③-ㄷ 🔴 **새 시험 아홉이 이미지 안의 목록 파일에 등록돼 있는가.**
      #    🔴 **목록 파일은 CRLF 다** — tr -d 로 \r 를 걷어낸 뒤 -Fx 로 맞댄다.
      #    🔴 **읽은 줄 수를 함께 받아 0 이면 ✗** · **없는 경로 하나를 함께 묻는다.**
      #    🔴 **cat 의 글롭은 set -f 앞에** 둔다 — 뒤에 두면 *.txt 가 글자로 남는다.
      v=$(docker run --rm -e DSS_TESTS="$AS_NEW_TESTS" -e DSS_MISS="$REG_PROBE_MISS" --entrypoint sh "$TAG" -c 'L=$(cat /app/scripts/test-lists/*.txt 2>/dev/null | tr -d "\r"); echo "lines $(printf "%s\n" "$L" | grep -c .)"; set -f; printf "%s\n%s\n" "$DSS_TESTS" "$DSS_MISS" | while IFS= read -r t; do [ -n "$t" ] || continue; n=$(printf "%s\n" "$L" | grep -cFx -- "$t"); if [ "${n:-0}" -ge 1 ]; then echo "yes $t"; else echo "no  $t"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      probe=$(printf '%s\n' "$v" | grep -c "^no  $REG_PROBE_MISS" || true)
      lines=$(printf '%s\n' "$v" | sed -n 's/^lines //p')
      printf '      \\r 를 걷어내고 읽은 목록 줄 수: %s개 (기대 %s 이상 · 개발 PC 실측 3807)\n' "${lines:-?}" "$AS_TESTLIST_MIN_LINES"
      if ! isnum "${lines:-}" || [ "${lines:-0}" -lt "$AS_TESTLIST_MIN_LINES" ]; then
        printf '  ✗ 이미지 안 목록을 %s줄밖에 못 읽었다 — **빈 결과는 삼켜진 오류일 수 있다**\n' "${lines:-못 읽음}"; IMGFAIL=1
      elif [ "${probe:-0}" != "1" ]; then
        printf '  ✗ **없는 경로가 no 로 안 나왔다** — 줄 전체 일치가 깨졌다. 위 yes 도 못 믿는다\n'; IMGFAIL=1
      elif [ "${got:-0}" = "$AS_NEW_TESTS_WANT" ]; then
        printf '  ✓ 새 시험 %s개가 목록에 등록돼 있다 (새 단언이 조용히 안 도는 일은 없다)\n' "$AS_NEW_TESTS_WANT"
      else
        printf '  ✗ 등록된 것이 %s/%s 개다 — **옛 목록 파일이 담겼다**\n' "${got:-0}" "$AS_NEW_TESTS_WANT"; IMGFAIL=1
      fi
      # ③-ㄹ 🔵 **시험 목록 파일 넷이 이미지 안에 있는가** — 위 ③-ㄷ 이 설 바탕이다.
      v=$(docker run --rm -e DSS_LISTS="$AS_TESTLIST_FILES" --entrypoint sh "$TAG" -c 'set -f; printf "%s\n" "$DSS_LISTS" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "$AS_TESTLIST_FILES_WANT" ]; then printf '  ✓ 시험 목록 파일 %s장이 이미지에 담겼다\n' "$AS_TESTLIST_FILES_WANT"
      else printf '  ✗ 목록 파일이 %s/%s 장이다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}" "$AS_TESTLIST_FILES_WANT"; IMGFAIL=1; fi
      # ④ 🔴 **그 안에 이번 판의 글자가 있는가** — 표식 일곱(일곱 커밋을 덮는다).
      v=$(docker run --rm -e DSS_MARKS="$AS_MARKS" --entrypoint sh "$TAG" -c 'set -f; printf "%s\n" "$DSS_MARKS" | while IFS= read -r pair; do [ -n "$pair" ] || continue; m=${pair%%|*}; f=${pair#*|}; if grep -qF -- "$m" "/app/$f" 2>/dev/null; then echo "yes $m $f"; else echo "no  $m $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      seen=$(printf '%s\n' "$v" | grep -cE '^(yes|no ) ' || true)
      printf '      표식 — 본 것 %s개 · 있는 것 %s개 (기대 %s · %s)\n' "${seen:-0}" "${got:-0}" "$AS_MARKS_WANT" "$AS_MARKS_WANT"
      if [ "${seen:-0}" = "$AS_MARKS_WANT" ] && [ "${got:-0}" = "$AS_MARKS_WANT" ]; then
        printf '  ✓ 이번 판의 표식 %s개가 이미지 안에 있다 (**일곱 커밋이 다 담겼다**)\n' "$AS_MARKS_WANT"
      else
        printf '  ✗ 본 것 %s · 있는 것 %s 다 — **커밋 하나가 빠진 판일 수 있다.** 올리지 마세요\n' "${seen:-0}" "${got:-0}"; IMGFAIL=1
      fi
      # ⑤ 🔴 **공용 스키마가 담겼는가 — 그리고 이번 판의 새 표가 있는가**
      #    🔴 **이번 판에서 가장 중요한 줄이다** — dss-core 가 움직였다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'd=/app/vendor/dss-core/src/schema; if [ -d "$d" ]; then echo "miss=0"; echo "n=$(ls -1 "$d" | wc -l)"; else echo "miss=1"; fi' 2>/dev/null | tr -d ' \r')
      printf '%s\n' "$v" | sed 's/^/      /'
      c=$(printf '%s\n' "$v" | sed -n 's/^miss=//p'); got=$(printf '%s\n' "$v" | sed -n 's/^n=//p')
      if [ "${c:-1}" != "0" ]; then
        printf '  ✗ 이미지에 vendor/dss-core 의 스키마 폴더가 **없다** — Cannot find module 이 난다\n'; IMGFAIL=1
      elif [ "${got:-0}" -ge 1 ] 2>/dev/null; then
        printf '  ✓ 공용 스키마가 담겼다 (파일 %s개)\n' "$got"
      else
        printf '  ✗ 공용 스키마 폴더가 비었다 — **빈 서브모듈이 담겼다.** 올리지 마세요\n'; IMGFAIL=1
      fi
      # ⑤-ㄴ 🔴 **이번 판의 새 스키마 파일이 거기 있는가** — 없으면 db:migrate 가
      #       새 표를 모른 채 돈다. 🔴 쉰두째가 더한 칸 셋도 함께 본다(뒷걸음 방지).
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for pair in "badge_visibility_settings /app/vendor/dss-core/src/schema/badge-visibility-settings.ts" "badge-visibility-settings /app/vendor/dss-core/src/schema/index.ts" "delivered_date /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "completed_at /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "due_date_row_order /app/vendor/dss-core/src/schema/repair-case-approvals.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "5" ]; then
        printf '  ✓ **이번 판의 새 스키마**가 담겼고(표 + index 내보내기) 쉰두째의 칸 셋도 그대로다\n'
        printf '%s\n' "      🔵 index.ts 가 안 내보내면 도구가 @dss/core/schema 에서 그 표를 **못 찾습니다**"
        printf '%s\n' "         — 2026-09-21 에 운영에서 도구가 전부 죽은 그 자리입니다."
      else
        printf '  ✗ 다섯 중 %s개만 있다 — **옛 공용 스키마가 담겼다.** 올리지 마세요\n' "${got:-0}"; IMGFAIL=1
      fi
      # ⑥ 🔴 **drizzle-kit 이 있는가** — 🔴 이번 판은 **실제로 db:migrate 를 부른다.**
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/drizzle-kit && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '      /app/node_modules/drizzle-kit: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ drizzle-kit 이 있다 (🔴 **이번 판의 --migrate 가 이것으로 돈다**)\n'
      else printf '  ✗ drizzle-kit 이 없다 — **--migrate 가 그 자리에서 죽는다.** 올리지 마세요\n'; IMGFAIL=1; fi
      # ⑦ 🔴 **값으로 받아 본다.** 'npm run …' 이어야 Missing script 가 드러난다.
      #    🔵 DATABASE_URL 을 안 준다 — connection.ts 가 모듈 꼭대기에서 던진다.
      for c in db:preflight db:migrate check:due-date-overdue procedures:import; do
        v=$(docker run --rm --entrypoint sh "$TAG" -c "cd /app && npm run $c 2>&1 | head -40" 2>&1 | tr -d '\r')
        if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
          printf '  ✗ npm run %s — **Missing script** (41번과 같은 실패다)\n' "$c"; IMGFAIL=1
          printf '%s\n' "$v" | head -20 | sed 's/^/      /'
        elif printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
          printf '  ✓ npm run %s 가 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)\n' "$c"
        elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
          printf '  ✗ npm run %s 가 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다\n' "$c"; IMGFAIL=1
          printf '%s\n' "$v" | head -20 | sed 's/^/      /'
        else
          printf '  ⚠️ npm run %s 의 답이 기대와 다르다 — 아래 20줄을 사람이 보세요\n' "$c"
          printf '%s\n' "$v" | head -20 | sed 's/^/      /'
        fi
      done
      # ⑧ 🔵 tsx 가 있는가 — 이 도구들은 tsx 로만 돈다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '      /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ A/S 도구에 tsx 가 있다\n'
      else printf '  ✗ tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
      # ⑨ 🔵 지난 판들이 올린 도구가 **아직 있는가** — 한 번 빼면 다시 넣는 사람이 없다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts /app/scripts/check-delivered-date-sync.ts /app/scripts/lib/delivered-date-sync-survey.ts /app/scripts/import-procedure-bundle.ts /app/scripts/export-procedure-bundle.ts /app/scripts/lib/procedure-template-bundle.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      printf '%s\n' "$v" | grep '^no  ' | sed 's/^/      /'
      if [ "${got:-0}" = "9" ]; then printf '  ✓ 48~55번이 올린 도구 아홉이 다 들어 있다\n'
      else printf '  ✗ 도구 파일이 %s/9 개다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
      # ⑩ 🔵 엑셀 읽개 둘이 **개발 DB 자물쇠**를 그대로 부르는가.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/import-technical-task-procedures.ts /app/scripts/link-technical-task-next-procedures.ts; do if grep -q checkDevelopmentWriteTarget "$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "2" ]; then printf '  ✓ 엑셀 읽개 둘이 개발 DB 자물쇠를 부른다 (NAS 에서 부르면 막힌다)\n'
      else printf '  ✗ 자물쇠를 부르는 것이 %s/2 개다. **운영 DB 에 쓸 수 있는 판이다.** 올리지 마세요\n' "${got:-0}"; IMGFAIL=1; fi
      # ⑪ 🔵 도구 셋이 이미지 안에서도 읽기만 하는가 — 부르는 꼴로 센다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/check-due-date-overdue.ts /app/scripts/check-delivered-date-sync.ts /app/scripts/lib/delivered-date-sync-survey.ts; do if [ -f "$f" ]; then echo "miss=0 $f"; echo "w=$(grep -cE "\.insert\(|\.update\(|\.delete\(" "$f") $f"; echo "t=$(grep -c "db.transaction" "$f") $f"; else echo "miss=1 $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      nmiss=$(printf '%s\n' "$v" | grep -c '^miss=1' || true)
      nwrite=$(printf '%s\n' "$v" | grep -cE '^w=[1-9]' || true)
      ntx=$(printf '%s\n' "$v" | grep -cE '^t=[1-9]' || true)
      nok=$(printf '%s\n' "$v" | grep -c '^miss=0' || true)
      if [ "${nmiss:-1}" != "0" ]; then printf '  ✗ 도구 중 이미지에 **없는 것**이 %s개다\n' "$nmiss"; IMGFAIL=1
      elif [ "${nok:-0}" != "3" ]; then printf '  ✗ 도구 셋 중 %s개만 봤다 — 셋을 기대했다\n' "${nok:-0}"; IMGFAIL=1
      elif [ "${nwrite:-1}" = "0" ] && [ "${ntx:-1}" = "0" ]; then printf '  ✓ 도구 셋이 이미지 안에서도 **읽기만 한다** (쓰는 꼴 0 · 트랜잭션 0)\n'
      else printf '  ✗ 쓰는 꼴 %s개 · 트랜잭션 %s개 — **운영 DB 에 쓸 수 있는 판이다.** 올리지 마세요\n' "${nwrite:-?}" "${ntx:-?}"; IMGFAIL=1; fi
      # ⑫ 🔴 이미지 안의 drizzle/ 은 **비어 있어야** 한다 — 볼륨으로 붙는 자리다.
      #    🔴 0128 이 이미지 안에도 있으면 볼륨과 이미지 중 어느 것이 돌았는지 알 수 없다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '      /app/drizzle 안 .sql: %s개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)\n' "${v:-?}"
      if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ drizzle/ 이 비어 있다 (🔴 그래서 0128 은 **묶음으로** 가야 한다)\n'
      else printf '  ✗ drizzle/ 에 .sql 이 들었다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다\n'; IMGFAIL=1; fi
      # ⑬ 🔵 **양식은 이미지에 안 들어간다** — 들어갔으면 도장과 계좌번호가 구워진 것이다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "ls /templates 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '      /templates 안 파일: %s개 (기대 0 — 양식은 볼륨으로 붙는다)\n' "${v:-?}"
      if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ 양식이 이미지에 안 들어갔다\n'
      else printf '  ✗ 이미지 안에 /templates 가 %s개 있다 — 도장·계좌번호가 구워졌다. 사람이 보세요\n' "${v:-?}"; IMGFAIL=1; fi
      ;;
  esac
  if [ "$IMGFAIL" != 0 ]; then
    printf '%s\n' "🔴 $TAG 의 안이 온전하지 않다. 올리지 마세요."
    BFAIL=$((BFAIL+1))
  fi
done

# ══════════════════════════════════════════════════════════════════════
# ── 🔴 **셋째 산출물 — 마이그레이션 묶음** ────────────────────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **마이그레이션은 이미지 안이 아니라 볼륨에서 돈다.** 도구 이미지의
#      /app/drizzle 은 비어 있고(위 ⑫ 가 그것을 쟀다), 운영에서는 거기에
#      /volume1/dss/as-migrations 가 붙는다. 그래서 0128 은 **이 묶음으로만** 간다.
#   🔴 **안 보내면 적용이 0건으로 조용히 끝난다** — 39·48·53번이 겪었다.
#   🔵 묶음은 저장소의 drizzle/ 을 통째로 담는다.
#      🔴 **작업 폴더로 들어가 상대경로로** 만든다(tar 의 드라이브 문자 함정).
printf '\n%s\n' "════════ 셋째 산출물 — 마이그레이션 묶음 ($AS_SQL_WANT 장) ════════"
MIGOK=1
rm -f "$MIGTAR" 2>/dev/null
if ( cd "$ASDIR" && tar -czf "$MIGTAR" drizzle ) </dev/null; then
  msz=$(stat -c %s "$MIGTAR" 2>/dev/null || wc -c < "$MIGTAR")
  mm5=$(md5sum "$MIGTAR" | awk '{print $1}')
  printf '  ✓ as-migrations.tar.gz (%s바이트)\n' "$msz"
  printf '    md5  %s\n' "$mm5"
  printf '%s\n' "    🔵 60번의 묶음은 2,502,840바이트였습니다 — 그보다 조금 큰 것이 정상입니다(.sql 한 장 + 스냅샷 한 장)."
else
  printf '  ✗ 묶음을 못 만들었다 — 🔴 **이 배포는 묶음이 필수다**\n'
  BFAIL=$((BFAIL+1)); MIGOK=0; msz=""; mm5=""
fi
if [ "$MIGOK" = "1" ]; then
  # 🔴 **안을 센다 — 겉이 아니라 결과.** 「파일이 생겼다」와 「쓸 만한 묶음이다」는 다르다.
  #    🔴 tar 를 grep -q 에 물리지 않는다 — **전부 세어서 담고 비교하는 꼴**이다.
  INSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE '^drizzle/[0-9]{4}_.*[.]sql$' || true)
  INJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
  printf '    묶음 안 — .sql %s장 · meta/_journal.json 의 idx %s개 (기대 %s · %s)\n' "${INSQL:-?}" "${INJRN:-?}" "$AS_SQL_WANT" "$AS_SQL_WANT"
  if [ "${INSQL:-x}" = "$AS_SQL_WANT" ] && [ "${INJRN:-x}" = "$AS_SQL_WANT" ]; then
    printf '  ✓ 묶음 안이 %s장이고 목록도 %s개다 (목록에서 빠진 .sql 이 없다)\n' "$AS_SQL_WANT" "$AS_SQL_WANT"
  else
    printf '  ✗ 묶음 안이 .sql %s · idx %s 다 — %s·%s 를 기대했다\n' "${INSQL:-?}" "${INJRN:-?}" "$AS_SQL_WANT" "$AS_SQL_WANT"
    printf '%s\n' "      🔴 목록에 없는 .sql 은 drizzle 이 **아예 모르고**, 적용이 0건으로 조용히 끝납니다."
    BFAIL=$((BFAIL+1))
  fi
  # 🔴 **0128 이 묶음 안에 정말 있는가** — 수만 맞고 다른 것이 들었을 수 있다.
  HAS128=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${AS_LAST_MIG}_.*[.]sql" || true)
  HASSNAP=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/meta/${AS_LAST_MIG}_snapshot[.]json" || true)
  printf '    묶음 안의 %s — .sql %s개 · 스냅샷 %s개 (기대 1 · 1)\n' "$AS_LAST_MIG" "${HAS128:-?}" "${HASSNAP:-?}"
  if [ "${HAS128:-0}" = "1" ] && [ "${HASSNAP:-0}" = "1" ]; then
    printf '  ✓ **이번 판이 올릴 %s 이 묶음 안에 있다** (이것이 없으면 배포가 0건으로 끝난다)\n' "$AS_LAST_MIG"
  else
    printf '  ✗ 묶음 안에 %s 이 없다 — **이 배포의 목적물이 안 담겼다.** 보내지 마세요\n' "$AS_LAST_MIG"
    BFAIL=$((BFAIL+1))
  fi
  # 🔴 **0129 가 없는가** — 이 배포는 0128 까지를 전제로 쓰였다.
  HASNEXT=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${AS_NEXT_MIG}_.*[.]sql" || true)
  printf '    묶음 안의 %s: %s개 (기대 0)\n' "$AS_NEXT_MIG" "${HASNEXT:-?}"
  if [ "${HASNEXT:-1}" = "0" ]; then
    printf '  ✓ 묶음에 %s 이 없다 (마지막이 %s — 적용 대기가 %s건이 된다)\n' "$AS_NEXT_MIG" "$AS_LAST_MIG" "$AS_NEW_MIGS_WANT"
  else
    printf '  ✗ 묶음에 %s 이 **있다** — 이 배포는 %s 까지를 전제로 쓰였다. 멈추고 알릴 것\n' "$AS_NEXT_MIG" "$AS_LAST_MIG"
    BFAIL=$((BFAIL+1))
  fi
  # 🔵 0122~0128 일곱이 .sql 과 스냅샷까지 들었는가 — 폴더를 통째로 갈아 끼운다.
  KEEPIN_MISS=""
  for t in $AS_KEEP_MIGS; do
    a=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${t}_.*[.]sql" || true)
    b=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/meta/${t}_snapshot[.]json" || true)
    printf '      %-6s .sql %s · 스냅샷 %s\n' "$t" "${a:-0}" "${b:-0}"
    [ "${a:-0}" -ge 1 ] 2>/dev/null || KEEPIN_MISS="$KEEPIN_MISS $t(sql)"
    [ "${b:-0}" -ge 1 ] 2>/dev/null || KEEPIN_MISS="$KEEPIN_MISS $t(snapshot)"
  done
  if [ -z "${KEEPIN_MISS:-}" ]; then
    printf '  ✓ 묶음에 0122~0128 의 .sql 과 스냅샷이 다 있다 (폴더를 통째로 갈아 끼워도 안전하다)\n'
  else
    printf '  ✗ 묶음에서 빠진 것:%s\n' "$KEEPIN_MISS"
    BFAIL=$((BFAIL+1))
  fi
  # 🔴 **묶음 안의 0128 이 기대한 생김새인가** — 보내는 것은 저장소가 아니라 이 묶음이다.
  NM128=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -E "^drizzle/${AS_LAST_MIG}_.*[.]sql" | head -1)
  if [ -n "${NM128:-}" ]; then
    TB128=$(tar -xzOf "$MIGTAR" "$NM128" 2>/dev/null)
    traw=$(printf '%s\n' "$TB128" | grep -ciE "$DESTRUCTIVE_RE" || true)
    tnet=$(printf '%s\n' "$TB128" | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
    tct=$(printf '%s\n' "$TB128" | grep -v "$SQL_COMMENT_RE" | grep -c 'CREATE TABLE' || true)
    tix=$(printf '%s\n' "$TB128" | grep -v "$SQL_COMMENT_RE" | grep -c 'CREATE UNIQUE INDEX' || true)
    tins=$(printf '%s\n' "$TB128" | grep -v "$SQL_COMMENT_RE" | grep -c 'INSERT INTO' || true)
    tond=$(printf '%s\n' "$TB128" | grep -cF 'ON DELETE' || true)
    printf '    묶음 안 %s — 지우는 문장: 날것 %s줄 · 주석 걷은 뒤 %s줄 (기대 %s)\n' "$AS_LAST_MIG" "${traw:-?}" "${tnet:-?}" "$MIG_DROP_WANT"
    printf '      CREATE TABLE %s (기대 1) · CREATE UNIQUE INDEX %s (기대 1) · INSERT %s (기대 0) · (참고) ON DELETE %s줄\n' "${tct:-?}" "${tix:-?}" "${tins:-?}" "${tond:-?}"
    if [ "${tnet:-x}" = "$MIG_DROP_WANT" ] && [ "${tct:-0}" = "1" ] && [ "${tix:-0}" = "1" ] && [ "${tins:-1}" = "0" ]; then
      printf '  ✓ 묶음 안의 %s 이 **표 하나를 만들고 자료는 안 건드린다** (지우는 문장 0)\n' "$AS_LAST_MIG"
      printf '%s\n' "      🔵 ON DELETE 1줄은 **FK 구절**이라 안 셉니다 — 앱의 migration-safety 와 같은 잣대입니다."
    else
      printf '  ✗ 묶음 안의 %s 이 기대와 다르다 — 지우는 문장 %s줄 · CREATE TABLE %s · INSERT %s\n' "$AS_LAST_MIG" "${tnet:-?}" "${tct:-?}" "${tins:-?}"
      BFAIL=$((BFAIL+1))
    fi
  else
    printf '  ⚠️ 묶음 안의 %s 을 못 읽었다 — 위 줄을 보세요\n' "$AS_LAST_MIG"
  fi
  MIGLINE="as-migrations.tar.gz|${msz}|${mm5}|-"
fi

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  구운 것 %s / %s · 실패 %s\n' "$BUILT" "$HOWMANY" "$BFAIL"
# ══ 🔴 **✗ 가 나도 지문 줄만은 찍는다** ═══════════════════════════════
#   🔴 쉰세째·쉰네째에 **두 번 연속으로 지문을 못 받았다.** 그래서 **세 자리**에서 찍는다.
if [ "$BFAIL" != "0" ]; then
  printf '\n%s\n' "🔴🔴🔴 **실패가 있지만 지금까지 만든 산출물의 지문은 아래가 전부입니다**"
  printf '%s\n' "       (이름|바이트|md5|Config 지문 — 61-deploy.sh 의 TARS 에 넣을 꼴입니다)"
  if [ -n "${TARTABLE:-}" ]; then
    printf '%s' "$TARTABLE"
  else
    printf '%s\n' "       (tar 가 한 줄도 없습니다 — 하나도 안 구워졌다는 뜻입니다.)"
  fi
  if [ -n "${MIGLINE:-}" ]; then
    printf '%s\n' "$MIGLINE"
    printf '%s\n' "       🔴 묶음 줄은 TARS 가 아니라 **MIGTAR_SIZE · MIGTAR_MD5** 에 넣습니다:"
    printf '%s\n' "          MIGTAR_SIZE=${msz}"
    printf '%s\n' "          MIGTAR_MD5=${mm5}"
  else
    printf '%s\n' "       (묶음 줄이 없습니다 — 묶음이 안 만들어졌다는 뜻입니다.)"
  fi
  printf '%s\n' "🔴🔴🔴 **실패를 고친 뒤 다시 구우면 지문이 바뀔 수 있습니다** — 위 값을 그대로"
  printf '%s\n' "       쓰지 마시고, 다시 구운 뒤의 값을 쓰세요."
  printf '\n%s\n' "🔴 실패가 있다. 위를 보세요."
  exit 1
fi

# 🔴 **굽고 나서 저장소가 더러워졌는가** — next build 가 tsconfig.json 을 다시 접는다.
printf '\n%s\n' "════════ 구운 뒤 저장소가 그대로인가 ════════"
DIRTY_AFTER=$(git -C "$ASDIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
printf '  A/S 미커밋 %s줄 (기대 0)\n' "${DIRTY_AFTER:-?}"
if [ "${DIRTY_AFTER:-1}" = "0" ]; then
  printf '  ✓ 저장소가 그대로다 (굽기가 파일을 안 건드렸다)\n'
else
  printf '  ⚠️ 굽고 나니 미커밋이 %s줄 생겼다 — **사람에게 알리세요**\n' "$DIRTY_AFTER"
  git -C "$ASDIR" status --porcelain=v1 2>/dev/null | head -10 | sed 's/^/      /'
  printf '%s\n' "     🔴 next build 가 tsconfig.json 을 다시 접은 적이 있습니다(눈에 안 띕니다)."
  printf '%s\n' "     🔵 **tar 는 이미 구워졌습니다** — 되돌릴지 그대로 둘지는 사람이 정하세요."
fi
# 🔴 **서브모듈도 그대로인가** — 이번 판은 dss-core 가 움직인 판이라 특히 본다.
CORE_DIRTY2=$(git -C "$COREDIR" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
printf '  vendor/dss-core 미커밋 %s줄 (기대 0)\n' "${CORE_DIRTY2:-?}"
if [ "${CORE_DIRTY2:-1}" = "0" ]; then printf '  ✓ 서브모듈도 그대로다\n'
else printf '  ⚠️ 서브모듈에 미커밋이 %s줄 생겼다 — 사람에게 알리세요\n' "$CORE_DIRTY2"; fi

# ══ 🔴 61-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 61-deploy.sh 의 TARS 는 **이름만 적힌 채로** 올라간다. 지문 칸이 비어 있으면
#     --check 에서 ? 로 세고 **--preload·--migrate·--go 에서는 ✗ 다.**
printf '\n%s\n' "════════ 61-deploy.sh 에 붙여 넣을 것 (TARS 두 줄 + 묶음 값 둘) ════════"
printf '%s' "$TARTABLE"
echo "  🔴 위 **두 줄**로 TARS 의 두 줄을 통째로 갈아 끼운다."
echo "  🔴 그리고 **묶음 값 둘**을 아래 그대로 적는다 (TARS 가 아니라 따로 있는 변수다):"
printf '%s\n' "       MIGTAR_SIZE=${msz}"
printf '%s\n' "       MIGTAR_MD5=${mm5}"
printf '\n%s\n' "✅ 둘 다 구웠고 묶음도 만들었다. 산출물이 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'
printf '\n%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **올리는 차례 — 이번 판은 tar 둘 + 묶음 하나다**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  🔴 **마이그레이션이 ${AS_NEW_MIGS_WANT}건입니다.** 저장소가 $AS_SQL_WANT · 운영 볼륨은 아직 $AS_PROD_SQL_NOW 입니다."
printf '%s\n' "     🔴 **묶음을 안 보내면 적용이 0건으로 조용히 끝납니다** — 마이그레이션은"
printf '%s\n' "        이미지 안이 아니라 **볼륨에서** 돕니다(39·48·53번이 겪었습니다)."
printf '%s\n' "     🔴 **_images-56 의 묶음(128장)을 보내지 마세요** — 0128 이 없습니다."
printf '%s\n' "  🔵 양식은 **한 장도 안 올립니다** — 열하나가 적어 둔 값 그대로입니다(8절)."
printf '%s\n' "  🔵 포털(dss-auth)·PO 는 **안 건드립니다.**"
printf '%s\n' ""
printf '%s\n' "  🔴 PowerShell 경로는 **슬래시**로 적습니다. 역슬래시는 bash·scp 가 먹습니다."
printf '%s\n' "  🔴 **Tee-Object 로 로그를 받지 마세요** — PowerShell 이 UTF-16 으로 써서"
printf '%s\n' "     나중에 grep 이 한 줄도 못 찾습니다. NAS 쪽 로그 파일을 보세요(스크립트가 스스로 남깁니다)."
printf '%s\n' ""
printf '%s\n' "  ① (개발 PC · PowerShell) **스크립트부터 올린다**"
printf '%s\n' "       cd \"C:/Users/희만/Desktop/Development/dss-deploy/nas/setup\""
printf '%s\n' "       scp -O 61-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "       Get-FileHash -Algorithm MD5 61-deploy.sh"
printf '%s\n' "     🔵 NAS 에서 md5sum 을 쳐 **눈으로 맞댑니다**(DSM 터미널이 긴 것을 잘라 먹습니다)."
printf '%s\n' "     🔴 **TARS 두 줄과 MIGTAR_SIZE·MIGTAR_MD5 를 먼저 채운 뒤에 올리세요.**"
printf '%s\n' ""
printf '%s\n' "  ② (NAS) 지금 상태를 잰다 — 아직 아무것도 안 바뀐다"
printf '%s\n' "       sudo -i"
printf '%s\n' "       bash /volume1/dss/setup/61-deploy.sh            ← --check"
printf '%s\n' "       bash /volume1/dss/setup/61-deploy.sh --count    ← 올리기 전 수"
printf '%s\n' "     🔵 2절의 마이그레이션 수가 **$AS_PROD_SQL_NOW** 로 나와야 합니다(아직 안 올렸습니다)."
printf '%s\n' "     🔵 --count 의 ① 이 **「표가 아직 없다」** 로 나오는 것이 정상입니다."
printf '%s\n' ""
printf '%s\n' "  ③ (개발 PC · PowerShell) **tar 둘과 묶음 하나를 보낸다 — 한 줄에 하나씩**"
printf '%s\n' "       cd \"$(printf '%s' "$OUT" | sed 's|^/c/|C:/|')\""
printf '%s\n' "       scp -O dss-as-5.3.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "       scp -O dss-as-tools-20.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "       scp -O as-migrations.tar.gz dss-nas:/volume1/dss/setup/incoming/"
printf '%s\n' "     🔴 **-O 를 빼지 마세요** — DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' "     🔴 **묶음은 images/ 가 아니라 setup/incoming/ 으로 갑니다** — 자리가 다릅니다."
printf '%s\n' ""
printf '%s\n' "  ④ (NAS) **들여놓고 → 다시 재고 → DB 를 올리고 → 갈아 끼운다**"
printf '%s\n' "       bash /volume1/dss/setup/61-deploy.sh --preload"
printf '%s\n' "       bash /volume1/dss/setup/61-deploy.sh            ← 다시 --check"
printf '%s\n' "       bash /volume1/dss/setup/61-deploy.sh --migrate  🔴 **여기서 DB 가 바뀐다** ($AS_PROD_SQL_NOW → $AS_SQL_WANT · **표가 하나 생긴다**)"
printf '%s\n' "       bash /volume1/dss/setup/61-deploy.sh --go       ⏱ 정지 창 (앱 **하나**)"
printf '%s\n' "       bash /volume1/dss/setup/61-deploy.sh --count    ← 올린 뒤 수"
printf '%s\n' "     🔴 **--migrate 를 건너뛰고 --go 로 가지 마세요** — [시스템 설정] 화면이"
printf '%s\n' "        표가 없으면 **그 자리에서 터집니다**(값을 바꾸러 온 화면이라 일부러 안 삼킵니다)."
printf '%s\n' "        🔵 배지를 그리는 화면들은 표가 없어도 안 죽습니다(전부 보임으로 떨어집니다)."
printf '%s\n' ""
printf '%s\n' "🔴 **되돌리기**: --rollback 은 app-as 를 $AS_OLD_TAG 로 되돌립니다."
printf '%s\n' "   🔵 도구는 $AS_TOOLS_TAG 그대로 둡니다(39·41~60번과 같은 판단)."
printf '%s\n' "   🔴 **DB 는 자동으로 안 되돌립니다** — 0128 은 **표를 더하기만** 하므로 옛 앱은"
printf '%s\n' "      그 표를 쳐다보지도 않습니다. 되돌려야 하면 DROP TABLE 을 **손으로** 돌립니다."
printf '%s\n' ""
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **배포 뒤에 눈으로 볼 곳 — 이번 판은 커밋 일곱입니다**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  ① 🔴 **[설정] › [시스템 설정] 이 탭 둘**이어야 합니다 — [고객 안내 상태 목록] · **[배지 표시]**."
printf '%s\n' "     🔴 그 탭 이름이 **앱 번들 표식**입니다 — 안 보이면 옛 판이 도는 것입니다."
printf '%s\n' "  ② 🔵 [배지 표시] 탭을 열면 **배지 15줄**이 서고 체크상자가 **모두 29개**여야 합니다."
printf '%s\n' "     🔵 전부 **켜져 있는 것이 정상**입니다(표가 비어서 나갑니다)."
printf '%s\n' "     🔵 자리는 여섯입니다 — 전체 A/S 현황 목록 · 수리건 상세 머리말 · 수리건 상세"
printf '%s\n' "        기본 정보 탭 · 내자 정리 목록 · 기타건 현황 목록 · 기타건 상세 머리말."
printf '%s\n' "  ③ 🔴 **하나를 꺼서 [저장]하고 그 화면에 가 보세요** — 그 자리에서만 사라져야 합니다."
printf '%s\n' "     🔴 **29자리 전부 실제로 듣습니다** — 꺼도 아무 일이 안 일어나는 스위치는 없습니다."
printf '%s\n' "     🔵 되돌리려면 다시 켜고 저장합니다(켜는 것은 그 행을 지우는 일입니다)."
printf '%s\n' "  ④ 🔴 **[사용자 관리] › [역할별 접근 권한]의 「시스템 설정」에 「관리」 칸이 생깁니다.**"
printf '%s\n' "     🔴 **읽기는 다섯 역할 전부 그대로**입니다 — 아무도 좁아지지 않습니다."
printf '%s\n' "     🔵 관리는 **관리자 이상**이 기본값입니다. 그 아래 역할로 [배지 표시]를 저장하면"
printf '%s\n' "        거절되어야 합니다(화면도 서버도 같은 열쇠로 묻습니다)."
printf '%s\n' "  ⑤ 🔴 **「정상」 배지가 모든 화면에서 사라집니다** — 설정과 무관하게 즉시입니다."
printf '%s\n' "     🔴 [전체 A/S 현황]의 상태 칸에서 **지연이 아닌 줄에는 아무것도 안 뜹니다.**"
printf '%s\n' "     🔵 지연인 줄에는 **[납기 지연]** 하나만 뜹니다. 🔴 그 줄이 하나도 없으면"
printf '%s\n' "        --count 의 「납기 지연」 수를 보세요 — 0건이면 화면이 맞습니다."
printf '%s\n' ""
printf '%s\n' "  🔴 **「아무것도 안 바뀐 것 같다」면** ① 의 [배지 표시] 탭을 먼저 보세요 —"
printf '%s\n' "     그것이 보이면 새 판이 돌고 있는 것입니다."
printf '%s\n' ""
printf '%s\n' "🔴 **알고도 안 고친 것 — PO 가 모르는 것이 셋입니다**(55번에서 넘어옴)"
printf '%s\n' "   ① dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 APPROVAL_REQUIRED 가 없습니다."
printf '%s\n' "   ② PO 는 납품일 칸(delivered_date·delivered_by)을 모릅니다."
printf '%s\n' "   ③ PO 는 회차 승인(due_date_row_order)을 모른 채 같은 표를 고칩니다."
printf '%s\n' "   🔵 **지금은 안전합니다** — 운영에서 직원의 PO 접근 권한을 모두 빼 두셨습니다"
printf '%s\n' "      (2026-11-08). 🔴 **PO 를 다시 여는 날 셋을 한 묶음으로 이식해야 합니다.**"
printf '%s\n' "   🔵 이번 판이 더한 표(badge_visibility_settings)는 **PO 가 안 씁니다** — 넷째가 안 됩니다."
printf '%s\n' "────────────────────────────────────────────────────────────"
# 🔴 **지문 줄들을 꼬리말 맨 끝에서 한 번 더 찍는다.**
printf '\n%s\n' "🔴🔴🔴 **61-deploy.sh 에 넣을 값 (다시 찍습니다 — 여기만 복사해도 됩니다)**"
printf '%s\n' "── TARS 두 줄"
printf '%s' "$TARTABLE"
printf '%s\n' "── 묶음 값 둘 (TARS 가 아니라 따로 있는 변수다)"
printf '%s\n' "MIGTAR_SIZE=${msz}"
printf '%s\n' "MIGTAR_MD5=${mm5}"
printf '%s\n' "🔴🔴🔴 위를 61-deploy.sh 에 **그대로** 적은 뒤 scp 하세요."
printf '%s\n' "       (NAS 에서 재서 채우지 마세요 — 자기가 잰 값으로 자기를 재면 영영 통과합니다.)"
