#!/bin/bash
# dss-deploy/nas/setup/74-deploy.sh — 일흔째 배포 (2026-11-26)
#
# 🔴 **NAS 에서 돈다.** DSM 터미널에서 sudo -i 뒤에 부른다.
#     bash /volume1/dss/setup/74-deploy.sh            ← --check (기본 · 아무것도 안 바꾼다)
#     bash /volume1/dss/setup/74-deploy.sh --count
#     bash /volume1/dss/setup/74-deploy.sh --preload
#     bash /volume1/dss/setup/74-deploy.sh --migrate  🔴🔴 **여기서 DB 가 바뀐다**
#     bash /volume1/dss/setup/74-deploy.sh --go
#     bash /volume1/dss/setup/74-deploy.sh --rollback
#
#   🔴 **DSM 터미널은 긴 명령을 잘라 먹는다.** 그래서 NAS 것은 **스크립트 파일로
#      올리고 md5 를 맞댄다** — 이 파일은 돌 때 **제 md5 를 스스로 찍는다.**
#      개발 PC 에서 「Get-FileHash -Algorithm MD5 74-deploy.sh」 로 찍은 값과
#      **눈으로 맞대고** 나서 모드를 쓰기 시작하라. 다르면 **올리다 잘린 것**이다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴🔴 **맨 먼저 — 어느 판을 왜 베꼈는가**
# ══════════════════════════════════════════════════════════════════════
#   이 파일은 **73-deploy.sh(예순아홉째 · 2026-11-26)를 복사해 값만 고친 것**이고,
#   **마이그레이션과 묶음을 다루는 자리는 71-deploy.sh(예순일곱째 · 2026-11-25)에서
#   되살린 것**이다 (2026-11-19 결정 — 「배포본은 복사하고 값만 고친다. 검사는
#   하나도 안 뺀다. diff 가 곧 검수다」).
#   🔴 **검수하는 길은 「diff 73-deploy.sh 74-deploy.sh」 와 「diff 71-deploy.sh
#      74-deploy.sh」 **둘**이다.** 앞의 것이 「값이 맞게 바뀌었나」를, 뒤의 것이
#      「묶음·단계 변수·서브모듈 꼴을 제대로 가져왔나」를 보여 준다.
#
#   ── 🔴 73번과 **다른 것 다섯** ───────────────────────────────────────
#        | 73번(예순아홉째)       | 74번(이번)
#     집  | **둘**(A/S + 재고)     | 🔴 **하나**(A/S)
#     도구 | 둘                    | 🔴 **하나**
#     tar  | 넷                    | 🔴 **둘**
#     안 건드리는 집 | 여덟         | 🔴 **아홉**(재고가 돌아왔다)
#     마이그| 0건                   | 🔴🔴 **1건**(dss_as 134 → **135**) · **묶음을 보낸다**
#
#   ── 🔴🔴 **71-deploy.sh 에서 되살린 것 여섯 — 한 벌이다** ────────────
#   73번은 마이그레이션이 0건이라 그 자리를 통째로 비워 두고 「왜 없는가」에
#   「1건이라도 생기면 71번에서 되살려라」를 적어 두었다. **그 날이 이번**이다:
#     ① **--migrate 모드** — 73번은 그 자리가 **--tools** 였다
#     ② **place_migs()** — 묶음을 볼륨에 푸는 함수
#     ③ **3-ㄴ 절** — 묶음의 지문과 **안**을 세는 자리
#     ④ **MIGTAR · MIGTAR_SIZE · MIGTAR_MD5** 변수 셋
#     ⑤ **MIGS 표와 DBPHASE · VOLPHASE** — 적용 전과 뒤의 **기대값이 뒤집히는** 자리
#     ⑥ **DESTRUCTIVE_RE · SQL_COMMENT_RE** 와 3-ㄴ 의 **잣대 표본**
#   🔴🔴 **하나만 되살리면 안 된다.** ②③④ 가 한 벌이라 하나만 되살리면 묶음을
#      받고도 **안을 한 번도 안 세거나**, 풀지 않은 채 db:migrate 를 돌려
#      **0건으로 조용히** 끝난다(31·39번이 겪었고, 70·72·73번이 그 경고를 적어 두었다).
#      ⑤ 가 없으면 「칸이 있는가」·「볼륨이 몇 장인가」의 기대값이 **단계마다 뒤집히는
#      것**을 못 가려 둘 중 하나가 **가짜 ✗** 가 된다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 파일에 「왜 없는가」를 적어 두는 절 셋**
#    (73·70·68·67·65·64·63 이 그렇게 했다 — 그 글이 없으면 다음 판이
#     「원래 없는 절」로 읽고, 되살려야 할 때 아무도 되살리지 않는다)
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴🔴 **--tools 모드가 없다. 그 자리가 --migrate 다.**
#      까닭: 올릴 .sql 이 **1건**이다(2-ㄷ 가 볼륨을 값으로 잰다 · 74-build.sh 4-ㄴ 이
#      저장소를 잰다). 🔴 **--tools 와 --migrate 를 둘 다 두지 마라** — 모드를 늘리면
#      차례가 하나 더 생겨 사람이 건너뛴다(66번이 65·64·63 의 --tools 를 --migrate 로
#      되돌린 까닭이고, 73번이 그 문장을 그대로 물려주었다).
#      🔵 --migrate 가 하는 일은 --tools 가 하던 일(덤프 · compose 사본 · 도구 태그 ·
#         db:preflight)에 **묶음 풀기와 db:migrate 와 수 다시 세기**가 더해진 것이다.
#   ② 🔴🔴 **재고관리(dss-inventory)가 「올라가는 집」에서 빠졌다.**
#      73번은 그 집이 SITES·TOOLS·TARS·APPMARKS·TOOLMARKS·INV_KEY_FILES 에 있었다.
#      까닭: 어제(예순아홉째) 0.9 가 올라갔고 **이번 범위에 한 줄도 없다** —
#      그 집은 **「안 건드리는 집」으로 돌아왔다**(여덟 → **아홉**).
#      🔴🔴 **73번은 「KEEP_BOXES 에 dss-inventory 가 **없다**(0)」를 값으로 못 박았다** —
#         그대로 두면 **가짜 ✗** 가 난다. 🔴 **이 판은 셋을 같은 줄에서 함께 센다:**
#           · dss-auth      **1** — 안 건드리는 집(73번과 같다)
#           · dss-inventory **1** — 🔴 **이번에 돌아왔다**(73번은 0 이었다)
#           · dss-as        **0** — 🔴 **이번에 올라가는 집**(목록에 있으면 안 된다)
#         🔴 한쪽만 재면 번호가 빗나가도 통과한다 — 그 규율이 AS_VOL_LAST 에서 왔다.
#      🔵 **재고를 재는 자리는 그대로 남겼다** — 2-ㄷ-2(도구 이미지 안 .sql 28장) ·
#         --count 의 ⑭~⑲ · ⑰-2 · MIGS_KEEP 의 inventory|28. 🔴 **하나도 빼지 마라** —
#         그 기능이 **어제 올라가 운영에서 돌고 있어** 뒷걸음을 봐야 한다.
#      🔴 재고를 다시 올리는 판에서는 **73-deploy.sh 에서 통째로 되살려라**(그때
#         A/S 와 **정반대**인 자리가 셋이다: drizzle 0장 ↔ 28장 · vendor 있어야 ↔
#         없어야 · public 9개 ↔ **비어 보이는 것이 정상**).
#   ③ 🔵 **「반쪽만 올라가는 것」 경고가 없다.** 73번은 한 기능이 두 집에 걸쳐 있어
#      그 글이 길었다 — 이번 판은 **A/S 한 집 안에서 끝난다.**
#      🔴 다만 **DB 와 앱이 반쪽으로 갈릴 수는 있다** — --migrate 만 하고 --go 를 안
#         하면 enum 에 값만 생기고 화면은 그대로다(해롭지 않다). 🔴 **거꾸로는 안 된다** —
#         --go 만 하면 새 앱이 내놓는 분류를 DB 가 모른다(아래 ⑤ 를 보라).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 올리는 것 — A/S 한 집 · 세 갈래**
#    🔴🔴 **DB 가 바뀐다**(마이그레이션 **1건** · dss_as 134 → 135)
# ══════════════════════════════════════════════════════════════════════
#   ㄱ) **첨부 분류에 DATA 를 더한다**(c091222c). 🔴 **DB 가 바뀌는 유일한 갈래**다 —
#      0134 가 enum attachment_category 에 값 하나를 **기타(OTHER) 앞에** 끼운다.
#      🔵 이름표가 **영문 DATA** 인 것은 실수가 아니다 — 연락서 폴더 안에 이미 있는
#         DATA 하위 폴더와 **글자가 같아야** 그 폴더로 들어간다(고치지 말 것).
#      🔵 **수리 건 전용**이다(제품 모델 · 종류 서류함 · 견적서에는 안 뜬다).
#   ㄴ) **[연락서 폴더에 저장] 창에 파일 이름을 적는 칸**(8adecea8). 기본값은 **지금
#      저장될 이름**이고, 경로 글자 · 감춰지는 이름 · 길이를 **거절**한다(치환이 아니다).
#   ㄷ) **[파일 올리기]의 칸이 「파일 이름」에서 「폴더 이름」으로 바뀐다**(158d6211 ·
#      **마지막 커밋**). 적으면 분류 폴더 **아래에 그 이름의 폴더**를 만들고 그 안에
#      넣는다. 안 적으면 **2026-11-26 전과 한 글자도 같다.**
#      🔴 **파일 이름을 정하는 기능은 이날 거뒀다**((1)(2) 번호 · 확장자 붙이기) —
#         올리는 파일은 **고른 이름 그대로** 올라간다(2026-11-18 이전과 같다).
#
#   🔵 **나머지 한 커밋(de818843)은 현황판 HTML 한 장짜리**라 **이미지에 자취가 없다.**
#
#   앱 **하나** · 도구 **하나** · tar **둘** · 마이그레이션 **1건** · 🔴 **묶음 하나** ·
#   안 건드리는 집 **아홉** · 안 바뀌는 DB **넷**.
#
#   🔴🔴 **drizzle 는 밀린 마이그레이션을 한 트랜잭션에 넣는다.** 이번에 밀린 것은
#      **0134 하나뿐**이고 그 SQL 은 ADD VALUE **한 줄**이며 **같은 판에서 그 값을
#      쓰지 않는다**(INSERT 도 UPDATE 도 없다 — 3-ㄴ 이 값으로 잰다). 🔵 그래서
#      「새 enum 값을 같은 트랜잭션에서 쓰면 쪼개도 멈춘다」는 함정에 **안 걸린다.**
#      🔴 다음 판에서 0135 가 그 값을 쓰면 **그때는 걸린다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **73번의 전제 중 이번에 깨지는 것 아홉 — 하나씩 재서 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴🔴 **마이그레이션이 1건이다**(73번은 0건). dss_as **134 → 135**.
#      볼륨 **134 → 135장**. 🔴 그래서 **--migrate 와 묶음과 단계 변수 둘**이
#      되살아났다(위 「71번에서 되살린 것」).
#      🔴 **A/S 는 .sql 이 볼륨에서 돈다** — 도구 이미지 안은 **0장**이어야 하고,
#         0134 는 **묶음으로만** 간다. 안 풀면 적용이 **0건으로 조용히** 끝난다.
#
#   ② 🔴🔴 **단계 변수 둘(DBPHASE · VOLPHASE)이 돌아왔다.**
#      73번에는 그 셋이 없었다 — 거기는 **적용 전과 뒤의 기대값이 같았기** 때문이다.
#      🔴 **이번엔 뒤집힌다:**
#        · dss_as 마이그레이션 수  — 적용 전 **134** · 뒤 **135**
#        · 볼륨의 .sql 수          — 적용 전 **134장** · 뒤 **135장**
#        · enum 의 DATA            — 적용 전 **없다(0)** · 뒤 **있다(1)**
#      🔴 **한 잣대로 재면 둘 중 하나가 반드시 가짜 ✗** 다(48번이 데인 자리).
#      🔵 **DBKEEP 은 그대로 남겼다** — 「안 바뀌는 네 집이 다 전과 같은가」를 들고 다닌다.
#
#   ③ 🔴 **NEWCOLS(예순일곱째의 칸 넷)의 뜻은 73번 그대로다** — 「늘 있어야 한다」.
#      🔴 **표를 지우지 않았다** — 지우면 DB 가 되감긴 날 아무도 못 잡는다.
#      🔴🔴 **이번 판은 칸을 하나도 안 더한다** — enum 값 하나를 더할 뿐이다. 그래서
#         「이번 판이 만드는 칸」 표가 **따로 없고**, 그 자리를 **ENUMWANT**(enum 에
#         DATA 가 있는가)가 맡는다. 🔴 71번의 NEWCOLS 를 「이번 판이 만드는 칸」으로
#         되돌리지 마라 — 이 판은 칸을 안 만든다.
#
#   ④ 🔴 **--migrate 가 도구 태그를 하나 간다**(73번은 둘이었다 · 71번도 둘이었다).
#      🔴 **A/S 도구**: src/ **30장**이 바뀌었고 **공용 스키마(vendor/dss-core)가
#         움직였다** — 그 안에서 도는 db:migrate 가 **그 스키마로** 돈다. 안 갈면
#         **DATA 를 모르는 스키마**로 올리게 된다.
#      🔵 재고 도구는 **안 간다** — 그 집은 이번 범위에 한 줄도 없다.
#
#   ⑤ 🔴 **--go 가 앱을 하나 띄운다**(73번은 둘). 그래도 **go_gate 는 둘을 잰다** —
#      dss-pg-app 이 도는가 + **dss_as 가 답하는가** + **dss_inventory 가 답하는가**.
#      🔴 **재고 DB 를 빼지 않았다** — 어제 올라간 A/S 의 **부품 반환**이 재고를
#         부르고, 그 DB 가 죽으면 **어제 올린 기능이 조용히 깨진다.**
#      🔵 dss-pg-auth 는 **켜진 때만** 끝에서 맞댄다(안 건드렸다는 증거).
#      🔴🔴 **--migrate 를 건너뛰고 --go 로 가면** 새 앱이 분류 목록에 DATA 를 내놓는데
#         DB 의 enum 에 그 값이 없어 **저장이 22P02 로 거절**된다. 그래서 --go 의
#         관문이 **DBPHASE = DONE** 과 **enum 에 DATA 가 있는가**를 둘 다 본다.
#
#   ⑥ 🔴 **표식이 전부 갈렸고 기능 표식 넷이 다 한글이다.**
#      A/S 기능 넷: 폴더 이름 (선택)(🔴 **한글** · **마지막 커밋 158d6211**) ·
#                   폴더 이름에 경로 글자(🔴 **한글** · 158d6211) ·
#                   확장자는 원본과 같게 유지됩니다(🔴 **한글** · 8adecea8) ·
#                   파일 이름에 경로 글자(🔴 **한글** · 8adecea8)
#      🔴🔴 **ASCII 기능 표식이 하나도 없다** — 이번 범위가 더한 코드에 새 ASCII
#         문자열 리터럴이 없다. 🔵 **대조는 뒷걸음 쪽이 맡는다**(return-candidates ·
#         shareDocRelativePath). 한글만 0 이고 그 둘이 ≥1 이면 **검사가 깨진 것**이다.
#      🔴🔴 **ㄱ 갈래(DATA)에는 번들 표식이 없다** — 그 갈래가 더한 리터럴이
#         DATA: "DATA" 뿐인데 **minify 가 공백을 지운다.** 그 갈래는 **도구 이미지
#         표식**과 **공용 스키마의 "DATA",** 가 가린다(preload_inside 의 astools 가지).
#         🔵 번들에는 **곁들이 둘**(공백 있는 꼴 · 없는 꼴)을 **판정 없이** 찍어 둔다.
#      🔴 뒷걸음 — **열넷**(73번의 열하나 + 73번의 기능 표식 **셋**이 내려왔다).
#      🔵 **73번의 기능 표식이 내려온 근거**: dss-as:6.4 가 지금 운영에서 돈다는 것이
#         곧 그 글자가 **그 번들에서 ≥1 이었다**는 증거다 — 0 이었으면 73번의
#         --preload 가 거기서 멈췄다(그 모드는 ✗ 가 하나라도 있으면 stop 한다).
#      🔴🔴 **이 파일의 표식은 번들에서 한 번도 안 세어 봤다** — 74-build.sh 가
#         굽기 전에 쓰였고, **--preload 가 처음** 센다.
#
#   ⑦ 🔴 **--count 에 둘이 늘었다**(⑳·㉑).
#      🔵 ⓪·⓪-2·①~⑲ 은 **70→71→72→73 을 거쳐 온 것 그대로**다. **하나도 안 뺐다.**
#         🔴 특히 **⑭~⑲(재고 쪽 여섯)을 그대로 두었다** — 그 기능이 **어제 올라가
#            운영에서 돌고 있어** 뒷걸음을 봐야 한다. 「이번 범위 밖이니 지운다」가
#            **틀린다**(지난 판들이 「한 번 빼면 다시 넣는 사람이 없다」고 반복해 적었다).
#      🔴 늘어난 둘:
#         ⑳ **DATA 분류로 올라간 첨부 수** — 🔵 **운영에는 0건일 것이다**(이 분류가
#            지금 생긴다). 🔴 **0 이 정상**이고, 그러면 눈 확인에서 그 분류의 파일이
#            **한 장도 안 보이는 것이 맞다.**
#         ㉑ **enum 에 DATA 가 있는가** — 🔴 **단계별로 기대값이 뒤집힌다**
#            (적용 전 0 · 뒤 1). 🔵 같은 줄에서 **OTHER 가 있는가(늘 1)**와
#            **DATA 가 OTHER 앞인가**와 **라벨 총수(23 → 24)**를 함께 센다.
#      🔴 **잣대 검사를 둘 다 붙였다** — 없는 분류로 물어 0 · 없는 라벨로 물어 0.
#
#   ⑧ 🔴 **tar 가 둘이고 묶음이 하나다**(73번은 넷 + 없음).
#      🔵 **보낼 것이 /volume1/dss/images 로 둘**이고 **setup/incoming 으로 하나**다.
#      🔴🔴 **거기 2026-11-25 의 옛 묶음이 아직 남아 있다**(71번이 보낸 **134장**짜리 ·
#         **2,680,441바이트** · md5 **8b7e8be4822e78094fa4441b5804df78**).
#         🔴 **이번엔 진짜 묶음을 보내므로 그 둘을 가려야 한다** — 3-ㄴ 이 그 값을 들고
#            있다가 **같으면 ✗** 를 낸다. 🔵 이름이 같아 scp 가 덮어쓰므로, 보내기만
#            하면 갈린다. 🔴 **안 보내면 옛 134장이 풀려 적용이 0건으로 끝난다.**
#
#   ⑨ 🔴🔴 **서브모듈 핀이 움직인다**(73번은 「안 움직인다」를 값으로 못 박았다).
#      vendor/dss-core **191676f → a464752**(커밋 1 · 파일 1 — src/schema/attachments.ts).
#      🔴 그래서 preload_inside 의 **공용 스키마 검사에 한 줄이 늘었다** —
#         「attachments.ts 에 "DATA", 가 있는가」. 🔴 **그 줄이 ㄱ갈래가 이미지에
#         담겼는지 재는 두 자리 중 하나다**(다른 하나는 도구 표식).
#      🔵 **일곱 쌍 고리는 그대로 뒀다** — 거기 일곱은 전부 뒷걸음이다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **73·71번에서 그대로 살린 것 — 한 번 빼면 다시 넣는 사람이 없다**
# ══════════════════════════════════════════════════════════════════════
#   · 2절 「DB 가 **안 바뀌었는가**」 — 🔵 이번에는 **네 집**(28·5·11·3) ·
#     쉰여덟째의 표 넷 · 예순일곱째의 칸 넷 · 도구 이미지 안 drizzle
#     (🔴 A/S **0장** · 재고 **28장** — **기대값이 정반대다**).
#   · 🔴 **--no-deps** 와 그 관문(DB 가 도는가 + **실제로 답하는가**) ·
#     끝에서 **DB 둘의 켜진 때 맞대기**. [실측 2026-11-18] 이것이 없어서 --go 가
#     dss-pg-app 을 Recreate 했다 — 자료는 멀쩡했지만 모든 연결이 끊겼다 붙었다.
#   · 함수 정의에 붙인 **</dev/null** — 고리 안의 docker exec 가 here 문서를 먹는다.
#     🔵 이번 판은 집이 하나라 티가 안 난다 — 🔴 **그래서 관문을 더 꼼꼼히 남겼다.**
#   · 1-ㅂ 의 **한글 바이트 확인 절**(70→71→72→73 으로 내려온 것) — 🔴 **이번 판은
#     한글 표식이 여덟이고 기능 표식이 전부 한글이다. 빼지 마라.**
#   · 덤프 · compose 사본 · db:preflight 를 값으로 받기.
#   · 4절의 **빼지 않는 검사들** — 연락서 폴더 · 양식 폴더 · PO 쓰기 권한 ·
#     발주서 공유폴더.
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
#       🔵 이 배포는 **자료를 한 글자도 안 바꾼다** — 0134 는 enum 에 값만 더한다.
#          🔴 **다만 ㉑(enum 의 DATA)은 적용 전과 뒤가 다르다**(0 → 1).
#          🔵 ⑳(DATA 분류 첨부)은 **전후 둘 다 0** 이 정상이다 — 사람이 그 분류로
#             올리기 시작하면 그때부터 는다.
#   --preload
#       쓰는 것 : **NAS 의 도커 이미지 저장소**(docker load 로 태그 **둘**).
#       🔵 실어만 두고 **아직 안 갈아 끼운다.** 싣자마자 **안을 센다.**
#       🔴 **묶음은 여기서 안 푼다** — --migrate 가 푼다.
#   --migrate  🔴🔴 **여기서 DB 가 바뀐다**
#       쓰는 것 : **DB 덤프 한 장**(dss_as) · **compose 사본 한 장** ·
#                 🔴 **A/S 마이그레이션 볼륨**(묶음을 풀어 134 → 135장) ·
#                 **compose 의 image: 줄 하나**(tools-as) · 🔴 **DB(dss_as)**.
#       안 쓰는 것: 앱의 image: 줄 · 도는 앱 컨테이너 · 공유폴더 ·
#                 🔴 **나머지 네 집의 DB**(재고 28 · 휴가 5 · 포털 11 · 계측기 3).
#       🔵 profiles: [tools] 라 도구는 평소에 안 뜬다 — **직원이 느끼는 것이 없다.**
#       🔵 **다시 돌려도 안전하다** — drizzle 은 이미 적용한 것을 건너뛴다.
#       🔴 **덤프는 dss_as 하나만 뜬다**(73번은 둘이었다 — 거기는 재고도 올라갔다).
#          🔵 재고 DB 는 이번에 **한 글자도 안 바뀐다.**
#   --go
#       쓰는 것 : **compose 사본 한 장** · **compose 의 image: 줄 하나**(app-as) ·
#                 **앱 하나를 다시 띄운다**(정지 창 — 40~60초).
#       안 쓰는 것: 🔴 **DB** · 볼륨 · 공유폴더 · 🔴 **나머지 아홉 집의 image: 줄**.
#       🔴 **--no-deps 를 쓴다** — 그것이 없어서 DB 가 Recreate 된 적이 있다.
#       🔴 **--migrate 가 먼저 돌아야 한다** — 새 앱이 분류 목록에 DATA 를 내놓는다.
#   --rollback
#       쓰는 것 : **compose 사본 한 장** · **app-as 의 image: 줄** · **앱 하나를 다시 띄운다.**
#       안 쓰는 것: 도구 태그(새 판 그대로 둔다) · DB · 볼륨 · 덤프(안 뜬다).
#       🔴🔴 **DB 는 자동으로 안 되돌린다** — PostgreSQL 은 **enum 값을 지울 수 없다.**
#          🔵 옛 앱은 그 값을 **쓰지 않으므로** 그대로 두어도 해롭지 않다.
#          🔴 다만 **그 사이에 DATA 로 올린 첨부가 있으면** 옛 앱이 모르는 분류로
#             남는다 — 되돌리기 전에 **--count 의 ⑳ 을 먼저 보라.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 환경의 함정 — 이 파일이 지키고 있는 것**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 이다.** set -e 아래라면 검사가
#      그냥 **멈춘다.** 이 파일은 **$( … || true )** 로만 받는다.
#   ② 🔴 **tar | grep -q 를 if 에 바로 물리지 않는다.** pipefail 아래서 grep -q 가
#      먼저 끝나면 앞의 tar 가 SIGPIPE 로 죽어 **파일이 있을 때 오히려 ✗** 가 난다.
#      🔴🔴 **이번 판은 묶음을 읽는다** — tar 를 읽는 자리는 **전부 세어서 담는 꼴**
#      (grep -c · grep -o)로만 적었다(73번에는 그 자리가 아예 없었다).
#   ③ 🔴 **bash -n 이 못 잡는 둘.** 큰따옴표 안의 백틱 · 읽기전용 자리의 콜론-꺾쇠 →
#      **이 파일에는 둘 다 한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#      🔴 19·20·21번에는 그 둘이 아직 남아 있다. **거기서 베껴 오지 마라.**
#   ④ 🔴 **CRLF.** 줄 전체로 맞대는 검사는 **읽자마자 tr -d 로 \r 를 걷은 뒤** 한다.
#      🔵 Git Bash 의 grep 만 \r 를 걷어내고 **NAS 의 GNU grep 은 안 걷어낸다** —
#      개발 PC 에서 ✓ 였던 것이 여기서 ✗ 가 되는 자리가 바로 그것이다.
#   ⑤ 🔴 **빈 결과는 삼켜진 오류일 수 있다.** 「비면 OK」로 읽는 자리를 안 만든다 —
#      목록은 **읽은 줄 수를 함께 받고**, **없는 값 하나를 일부러 함께 묻는다.**
#   ⑥ 🔴 **마이그레이션은 이미지가 아니라 볼륨에서 돈다**(A/S). 이미지 안만 세면
#      0건으로 조용히 끝난다. **볼륨의 .sql 과 _journal.json 을 둘 다** 센다.
#      🔴🔴 **이번 판은 거기 한 장을 더한다** — 묶음을 **풀어야** 134 → 135 가 된다.
#      🔴🔴 **재고는 정반대다 — 이미지 안에서 돈다**(28장). A/S 판을 베껴 「0장이어야
#         한다」로 재면 **멀쩡한 재고 도구가 ✗** 가 되고, 반대로 재고 판을 A/S 에
#         들이대면 **볼륨이 안 붙은 것을 못 잡는다**(69-deploy.sh 가 그 둘을 나란히
#         두고 「한 잣대로 뭉뚱그리지 마라」를 적어 두었다).
#   ⑦ 🔴 **저장소의 compose 사본은 운영보다 뒤처진다**(아홉 판 차이가 난 적이 있다).
#      이 파일은 **NAS 위의 docker-compose.nas.yml 만 읽는다.**
#   ⑧ 🔴 **bash 의 $(( )) 는 0 으로 시작하는 수를 8진수로 읽는다** — 0134·0135 를
#      셈에 넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
#   ⑨ 🔴 **한글을 HTTP 머리말에 넣지 않는다.** 넣으면 요청이 아예 안 나가고
#      그 ✗ 가 진짜 결함처럼 보인다. 🔵 **그 규칙은 그대로다** — 이 파일이 던지는
#      HTTP 요청에는 한글이 한 글자도 없다.
#      🔴 **다만 번들 표식 여덟이 한글이다**(KO_MARKS 의 주석 — 73번은 여섯이었다).
#      그 한글이 가는 길은 **docker run -e 하나뿐**이고, **1-ㅂ 절이 여덟을 다
#      보내고 되돌려 받아 바이트까지 맞댄다.**
#   ⑩ 🔴 **비밀값을 찍지 않는다.** 설정 파일은 이름이 있는가/없는가와 auto 인가만
#      본다. DATABASE_URL 에서는 **역할 이름만** 꺼낸다.
#   ⑪ 🔵 **받을 폴더는 777 로 만든다** — root 가 만든 755 는 scp 가 못 쓴다.
#   ⑫ 🔴 **「겉이 아니라 결과를 봐라」** — 「실었다」와 「쓸 만한 이미지다」는 다른
#      말이다. --preload 는 싣자마자 **안을 센다.**
#   ⑬ 🔵 **Git Bash 가 docker 인자를 번역하는 함정은 NAS 에 없다**(리눅스다).
#      🔴 그래도 **같은 꼴로 적어 둔다**: 파일 경로는 **상대로 넘기고 /app/ 를
#      컨테이너 안에서 붙인다.** 누가 이 파일을 Git Bash 에서 흉내 내도 살아남는다.
#   ⑭ 🔴 **✗ 가 났을 때 「검사가 틀렸나」를 먼저 보라.** 기대값이 틀릴 확률이
#      배포만큼 높다 — ✓ 쪽 오판은 **영영 안 드러난다.** doubt() 가 그 자리마다 찍는다.
#   ⑮ 🔴 **enum 은 없는 글자를 그대로 맞대면 22P02 로 거절된다.** 그래서 이 파일의
#      enum 질의는 **전부 ::text 로 바꿔** 묻는다(repair_status · stock_requests.type ·
#      stock_entries.type · 그리고 **이번에 생긴 attachments.category**).
#      🔴 안 바꾸면 **잣대 검사가 거절되고**, 그 빈 결과가 「잣대가 죽었다」처럼 보인다.
#   ⑯ 🔴 **집이 하나면 「고리가 한 바퀴만 돌았다」가 티가 안 난다.** 73번에서는 집이
#      둘이라 바로 드러났다 — 🔴 **그래서 「몇 개를 봤는가」 관문을 하나도 안 뺐다.**
#
# ── 🔴 알고도 안 고친 것 — PO 가 모르는 것이 **일곱**이 된다 ──────────
#   ① dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 APPROVAL_REQUIRED 가 없다.
#   ② PO 는 납품일 칸(delivered_date·delivered_by)을 모른다.
#   ③ PO 는 회차 승인(due_date_row_order)을 모른 채 같은 표를 고친다.
#   ④ PO 의 vendor/dss-core 핀이 8730c94 라 portal_approval_delegations 를 모른다.
#   ⑤ PO 는 domestic_order_due_dates 의 confirmed_at·confirmed_by 를 모른다.
#   ⑥ PO 에서 PO발행일을 적으면 작업 상태가 안 옮겨진다(예순여덟째 · 2026-11-26 결정).
#   🔴 **이번 판이 하나 더한다 — 일곱이 된다.**
#      ⑦ 🔴 **PO 의 vendor/dss-core 는 attachment_category 의 DATA 를 모른다.**
#         🔵 **칸을 더한 것이 아니라 enum 에 값을 더한 것**이라 모르는 쪽이 당장
#            깨지지는 않는다 — PO 는 그 분류로 저장하지 않는다. 🔴 다만 PO 가 첨부를
#            **읽는** 자리에서 그 값을 만나면 **타입 밖의 값**이 된다.
#   🔵 **지금은 안전하다** — 운영에서 직원의 PO 접근 권한을 모두 빼 두었다
#      (2026-11-08). 🔴 **PO 를 다시 여는 날 일곱을 한 묶음으로 이식해야 한다.**
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v70-$STAMP
BKDB=$D/backups/db
# 🔴 **BK 와 같은 v 번호여야 한다** — 59번(쉰다섯째)이 여기를 안 고쳐 v54 로 남긴
#    적이 있다. 아래 1-ㄱ-0 절이 값으로 확인한다.
DUMP_VER=v70
INCOMING=$D/setup/incoming
MIGDIR=$D/as-migrations
IMG_MIGDIR=/app/drizzle
TPLDIR=$D/as-templates
# 🔴🔴 **이번 판은 이 묶음을 실제로 읽고 푼다**(71-deploy.sh:258 에서 되살렸다).
#    자리는 incoming 이고, **푸는 것은 --migrate 뿐**이다 — --preload 는 안 푼다.
#    🔴 73번에는 이 변수가 **아예 없었다**(묶음이 없는 판이었다).
MIGTAR=$INCOMING/as-migrations.tar.gz

# ══ 🔴 앱 **하나** ════════════════════════════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트포트|사람이 부르는 이름
#   🔵 **73번은 둘이었다**(A/S + 재고). 🔴 **고리 꼴을 안 건드렸다** — 집이 다시
#      둘이 되는 날 **줄만 더하면** 된다(73-deploy.sh:402-406 이 그 꼴이다).
SITES='
as|app-as|dss-as|dss-as:6.5|dss-as:6.4|dss-as-6.5.tar|13000|A/S관리
'
SITES_WANT=1

# ══ 🔴 도구 **하나** — **--migrate 가 이 줄을 간다** ══════════════════
#   열쇠|서비스|새 태그|옛 태그|tar|이름|무엇 때문에 가는가
#   🔴 **73번은 그 자리가 --tools 였다**(마이그레이션 0건). 이번 판은 **1건**이라
#      71·66번처럼 **--migrate 안에서** 간다 — db:migrate 를 **새 도구로** 돌려야 한다.
TOOLS='
astools|tools-as|dss-as-tools:32|dss-as-tools:31|dss-as-tools-32.tar|A/S도구|🔴 공용 스키마(vendor/dss-core)에 enum 값 DATA 가 생겼고 src/ 30장이 바뀌었다 — db:migrate 가 그 스키마로 돈다
'
TOOLS_WANT=1

# ══ 🔴 안 건드리는 **아홉** — 「옆으로 안 샜다」는 증거로 센다 ════════
#   🔴 상자 이름이다(서비스 이름이 아니다) — 저장소의 compose 사본이 운영보다
#      뒤처져 있어 서비스 이름을 믿을 수 없다(⑦).
#   🔴🔴 **dss-inventory 가 여기로 돌아왔다**(73번은 여덟이었고 거기선 올라갔다).
#      **dss-auth 는 그대로 남아 있다.**
#      🔴 1-ㄷ 이 **셋을 같은 줄에서 함께** 센다 — dss-auth **1** · dss-inventory **1** ·
#         **dss-as 0**(이번에 올라가는 집은 이 목록에 있으면 안 된다).
#         🔴 한쪽만 재면 번호가 빗나가도 통과한다.
KEEP_BOXES="dss-approvals dss-leave dss-meters dss-board dss-improvements dss-rf-trouble dss-po dss-auth dss-inventory"
KEEP_BOXES_WANT=9
KEEP_DB="dss-pg-app dss-pg-auth"
KEEP_DB_WANT=2

# ══ 🔴🔴 DB ① — **이번 판이 움직이는 집 하나** (단계로 갈린다) ═══════
#   열쇠|DB상자|DB이름|전(적용 전)|후(적용 뒤)|migrate 명령|도는 자리|사람이 부르는 이름
#   🔴 **71-deploy.sh:297-300 에서 되살렸다** — 73번에는 이 표가 **아예 없었다**
#      (그 판은 움직이는 집이 0곳이었다).
#   🔴 **단계마다 기대값이 다르다.** 한 잣대로 재면 둘 중 하나가 **가짜 ✗** 다.
#   🔴 도는 자리가 **volume** 이다 — 이미지 안이 아니라 /volume1/dss/as-migrations
#      에서 돈다. 그래서 묶음을 풀어야 전(134)에서 후(135)로 갈 수 있다.
MIGS='
as|dss-pg-app|dss_as|134|135|db:migrate|volume|A/S관리
'
MIGS_WANT=1

# ══ 🔴 DB ② — **안 바뀌어야 하는 네 집** ═════════════════════════════
#   열쇠|DB상자|DB이름|지금도 뒤에도 이 수여야 한다|사람이 부르는 이름
#   🔴 **어긋나면 이 배포와 무관한 다른 사고다.** 그 자리에서 멈춘다.
#   🔴🔴 **dss_as 가 여기서 빠졌다**(73번은 다섯이었다) — 이번엔 **움직이는 집**이라
#      위 MIGS 표로 옮겨 갔다. 🔴 두 표에 같은 집을 두면 한쪽이 반드시 ✗ 가 된다.
#   🔵 **재고(28)는 여기 그대로 있다** — 그 집은 앱도 DB 도 이번에 안 바뀐다.
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
#   🔴 표 이름이 **셋으로 다르다**(A/S·재고 portal_… · 휴가 web_portal_… ·
#      포털 approval_delegations). 하나로 묻는 검사였으면 세 집이 ✗ 였다.
KEEP_TABLES='
dss-pg-app|dss_as|portal_approval_delegations|A/S관리
dss-pg-app|dss_inventory|portal_approval_delegations|재고관리
dss-pg-app|dss_leave|web_portal_approval_delegations|휴가관리
dss-pg-auth|dss_auth|approval_delegations|통합로그인포털
'
KEEP_TABLES_WANT=4

# ══ 🔴 **예순일곱째가 만든 칸 넷이 아직 있는가** — 뒷걸음 방지 ═══════
#   DB상자|DB이름|표|칸|자료형|NULL 허용|사람이 읽을 말
#   🔴 **뜻은 73번 그대로다** — 「늘 있어야」 ✓ 다(71번에서는 단계로 갈렸다).
#   🔴🔴 **이번 판은 칸을 하나도 안 더한다** — enum 값 하나를 더할 뿐이다.
#      그래서 「이번 판이 만드는 칸」 표가 **따로 없고**, 그 자리를 아래 ENUMWANT 가
#      맡는다. 🔴 **이 표를 「이번 판이 만드는 칸」으로 되돌리지 마라.**
#   🔴 **표를 지우지 않았다** — 지우면 DB 가 되감긴 날 아무도 못 잡는다.
#   🔴 **「있는가」만 보지 않고 꼴까지 본다** — 같은 이름으로 다른 꼴을 만든 것을
#      가르려면 자료형을 봐야 한다(2026-11-07 에 배운 것).
NEWCOLS='
dss-pg-app|dss_as|domestic_order_due_dates|confirmed_at|timestamp with time zone|YES|납기요청일 회차 확정 시각 (0133)
dss-pg-app|dss_as|domestic_order_due_dates|confirmed_by|uuid|YES|확정한 사람 (0133)
dss-pg-app|dss_as|procedure_template_nodes|share_doc_relative_path|text|YES|절차 본보기 노드의 파일 자리 (0132)
dss-pg-app|dss_as|repair_case_flowchart_nodes|share_doc_relative_path|text|YES|진단 Flowchart 노드의 파일 자리 (0132)
'
NEWCOLS_WANT=4

# ══ 🔴🔴 **이번 판이 만드는 것 — enum 에 값 하나** ════════════════════
#   🔴 **단계로 갈린다**: 적용 전 **0** · 적용 뒤 **1**.
#   🔵 **같은 줄에서 반대쪽도 센다** — OTHER 는 **늘 1**(그 값이 사라지면 다른 사고다).
#   🔴 **라벨 총수도 센다** — 적용 전 23 · 뒤 24. 「있는가」만 재면 **엉뚱한 라벨이
#      섞여 들어온 판**을 못 가른다.
#   🔵 **자리까지 본다** — 0134 가 BEFORE 'OTHER' 로 넣으므로 DATA 가 OTHER 보다
#      앞이어야 한다(enumsortorder). 🔴 자리가 틀리면 화면의 분류 차례가 달라진다.
ENUM_BOX=dss-pg-app
ENUM_DB=dss_as
ENUM_NAME=attachment_category
ENUM_VALUE=DATA
ENUM_BEFORE=OTHER
ENUM_LABELS_WAS=23
ENUM_LABELS_WANT=24
# 🔴 enum 라벨이 있는가 — pg_enum 을 직접 본다(테이블 자료가 아니라 **형의 정의**다).
ENUM_HAS_SQL="select count(*) from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = '$ENUM_NAME' and e.enumlabel = '$ENUM_VALUE'"
ENUM_BEFORE_SQL="select count(*) from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = '$ENUM_NAME' and e.enumlabel = '$ENUM_BEFORE'"
ENUM_COUNT_SQL="select count(*) from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = '$ENUM_NAME'"
# 🔵 **자리 맞대기** — DATA 가 OTHER 보다 앞이면 1.
ENUM_ORDER_SQL="select count(*) from pg_enum d join pg_enum o on o.enumtypid = d.enumtypid join pg_type t on t.oid = d.enumtypid where t.typname = '$ENUM_NAME' and d.enumlabel = '$ENUM_VALUE' and o.enumlabel = '$ENUM_BEFORE' and d.enumsortorder < o.enumsortorder"
# 🔴 **잣대가 살아 있는가** — 없는 라벨을 물어 0 이 나오는지 본다.
ENUM_PROBE_SQL="select count(*) from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = '$ENUM_NAME' and e.enumlabel = '__dss_probe_no_such_label__'"

# ══ 🔴 마이그레이션 안전 잣대 — 62·66·71번에서 글자 그대로 가져왔다 ══
#   🔴 **73번에는 이 둘이 아예 없었다**(잴 .sql 이 없는 판이었다. 73-deploy.sh:485-490
#      이 「.sql 이 한 장이라도 생기면 되살려라」를 적어 두었다 — **그 날이 이번**이다).
#   🔴 **잣대가 죽어 있으면 「지우는 문장 0줄」이 아무것도 안 재는 ✓ 가 된다.**
#      그래서 3-ㄴ 이 표본 **넷**으로 **잣대부터** 잰다.
#   🔴 **넷째 표본이 이번에 늘었다** — 0134 의 실물인 **ADD VALUE** 를 안 세는지
#      못 박았다(71번은 셋이었다 — DROP TABLE · ADD COLUMN · ON DELETE restrict).
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
SQL_COMMENT_RE='^[[:space:]]*--'

# ══ 🔴 A/S 마이그레이션 볼륨 — **134 → 135장** (단계로 갈린다) ════════
AS_VOL_SQL_WAS=134
AS_VOL_SQL_WANT=135
# 🔴 **이번 판이 올리는 번호는 하나다.** 「생기면 안 되는 것」은 **0135** 다.
AS_VOL_NEW='0134'
AS_VOL_NEW_WANT=1
AS_VOL_NEXT=0135
# 🔴 **「없는가」만 재면 번호가 빗나가도 통과한다** — 반대쪽 「있는가」를 같은 줄에서
#    함께 센다(70번이 AS_VOL_NEXT 가 한 칸 빗나가 **두 판 연속 아무것도 안 막은**
#    것을 잡아낸 뒤로 생긴 규율이다).
AS_VOL_LAST=0134

# ══ 🔵 재고 마이그레이션 — **도구 이미지 안에 28장**이어야 한다 ═══════
#   🔴 **A/S 와 정반대다**(머리말의 함정 ⑥). A/S 도구 이미지는 **0장**이어야 하고
#      재고 도구 이미지는 **28장**이어야 한다.
#   🔵 **재고는 이번에 안 올라간다** — 그래도 **2-ㄷ-2 는 그대로 남겼다**(뒷걸음).
#      운영의 compose 가 가리키는 **어제 올린 도구 이미지**를 열어 센다.
#      🔴 **빼지 마라** — 그 기능이 어제 올라가 운영에서 돌고 있다.
INV_IMG_SQL_WANT=28
INV_IMG_LAST=0027
INV_IMG_NEXT=0028

# ══ 🔴 tar **둘**의 지문 — [배포본] 74-build.sh 가 굽고 **바로 잰 값** ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 비어 있다 — 굽기 전에 쓴 파일이다.** 74-build.sh --go 가 꼬리말에
#      찍는 **두 줄**로 아래를 통째로 갈아 끼운 **뒤에** scp 하세요.
#   🔴 **이 값을 NAS 에서 재서 채우지 마라.** 그러면 「옮기다 깨졌는가」를 자기가
#      잰 값으로 자기를 재는 꼴이 되어 **영영 통과한다.** 반드시 **구운 쪽**에서 잰다.
#   🔴 비어 있으면 3절이 **--check·--count·--rollback 에서는 ? · --preload·
#      --migrate·--go 에서는 ✗** 로 센다. 🔵 막는 것은 **✗ 뿐이다.**
#      🔴 **쉰세째에는 빈 표가 그대로 NAS 로 올라갔고 --preload 가 ✗ 둘로 멈췄다.**
#   🔵 **지난 판 바이트**(74-build.sh 의 ①번 크기 견주기가 쓰는 값):
#      dss-as-6.4.tar 136987648 · dss-as-tools-31.tar 227245568  (73-deploy.sh:530-536)
#   🔵 **이름만 적고 값 칸은 비워 둔다** — 그래야 3절이 「표가 깨졌다」가 아니라
#      「지문이 비어 있다」로 센다.
TARS='
dss-as-6.5.tar|137057280|4ea5030a163ef44c3aba3bf65bb989f0|sha256:4b6389d5e9dee871cbeea862b32c1b75514d44f37426abaa369e6d562726fcdb
dss-as-tools-32.tar|227276800|a7699899cc7190663d9b0f9ab9b42bd6|sha256:35f4a0dc443da6e254e82741c1a641d52d2f37940c8f9773f3e538030788e3a9
'
TARS_WANT=2
# ══ 🔴🔴 **묶음의 지문** — 74-build.sh 가 찍어 준다 ═══════════════════
#   🔴 **73·72·70·69·68·67 에는 이 변수 둘이 아예 없었다.** 71번에서 되살렸다.
#   🔴 **아직 비어 있다.** 비어 있으면 3-ㄴ 이 --check 에서는 ? · --migrate 에서는
#      ✗ 로 센다. 🔴 **NAS 에서 재서 채우지 마라** — 자기가 잰 값으로 자기를 재면
#      영영 통과한다.
MIGTAR_SIZE=2710660
MIGTAR_MD5=425aaa33f296a9386b15645604482963
# ══ 🔴🔴 **옛 묶음의 지문** — incoming 에 아직 남아 있는 것 ═══════════
#   🔴 [실측 2026-11-26] 71번이 2026-11-25 에 보낸 **134장**짜리가 setup/incoming 에
#      **그대로 있다**(71-deploy.sh:398-399 의 값).
#   🔴🔴 **이번엔 진짜 묶음을 보내므로 그 둘을 가려야 한다** — 3-ㄴ 이 md5 를 맞대어
#      **같으면 ✗** 를 낸다. 🔵 이름이 같아 scp 가 덮어쓰므로 보내기만 하면 갈린다.
#      🔴 **안 보내면 옛 134장이 풀려** 적용이 **0건으로 조용히** 끝난다.
#      🔵 쉰여섯째·쉰일곱째가 **두 판 연속** 옛 묶음을 보내 ✗ 를 냈다.
OLD_MIGTAR_SIZE=2680441
OLD_MIGTAR_MD5=8b7e8be4822e78094fa4441b5804df78

# 🔴 tar 이름 → 태그. **정규식으로 되돌리지 않는다** — 이름마다 손으로 적는다.
#    🔴 판에 점이 있는 것과 없는 것이 섞여 있어 한 규칙으로 안 풀린다.
tar2tag() {
  case "$1" in
    dss-as-6.5.tar)       printf 'dss-as:6.5' ;;
    dss-as-tools-32.tar)  printf 'dss-as-tools:32' ;;
  esac
}

# ══ 🔴 이미지 안에서 쓸 표식 — **전부 리터럴 · 여덟이 한글** ══════════
#   열쇠|갈래(feature|keep|side)|글자|사람이 읽을 말
#   🔴 **공백이 든 표식이 있고 한글이 여덟이다.**
#      그래서 이 표는 tr -d ' ' 로 읽지 않고 **here 문서 + IFS='|' read** 로만 읽는다.
#   🔴 **전부 리터럴이어야 한다** — 코드 줄에서 따오면 minify 가 지우고, 웹팩이
#      production 에서 **export 이름까지 줄인다**(mangleExports).
#      [71번 실측 2026-11-25 · dss-as:6.2 번들] part.drawingNo, part.note = **0/0**.
#   🔴🔴 **기능 표식 넷이 전부 한글이고 ASCII 기능 표식이 하나도 없다** — 이번 범위가
#      더한 코드에 새 ASCII 문자열 리터럴이 없다. 🔵 **대조는 뒷걸음 쪽이 맡는다**
#      (return-candidates · shareDocRelativePath). 한글만 0 이고 그 둘이 ≥1 이면
#      그것 자체가 「한글 grep 이 깨진 것」이라는 증거다(1-ㅂ 절을 먼저 보라).
#   🔴🔴 **ㄱ 갈래(DATA)에는 번들 표식이 없다** — 그 갈래가 더한 리터럴이
#      DATA: "DATA" 뿐인데 **minify 가 공백을 지워** 번들에서는 DATA:"DATA" 가 된다.
#      🔵 그래서 그 갈래는 **도구 이미지 표식**(TOOLMARKS 의 첫 줄)과 **공용 스키마의
#         "DATA",**(preload_inside)가 가리고, 번들에는 **곁들이 둘**을 판정 없이 찍는다.
#   🔴 **「마지막 커밋의 글자」를 넣었다** — [폴더 이름 (선택)](158d6211).
#      🔴 그것이 0 이면 **커밋 하나가 빠진 판**을 구운 것이다.
#   🔴🔴 **아래 수는 번들에서 한 번도 안 세어 봤다** — 74-build.sh 가 굽기 전에
#      쓰였고 **--preload 가 처음** 센다.
#      🔵 **71번이 구운 번들에서 세어 둔 것**(뒷걸음 · 참고):
#         shareDocRelativePath **23** · 도번 / 비고 **2** · hasLiveApproval 3 ·
#         domesticOrders.completedEdit 5 · faultTags 19 · radiogroup 5 ·
#         "ORDER_ISSUED" 2 · domestic-order-status-filter 2 ·
#         portal_approval_delegations 23 · domesticOrders.view 8.
#      🔵 **73번의 기능 표식 셋과 NO_WAITING_REPAIR_STEP 은 번들 수가 안 적혀 있다** —
#         다만 73·72번이 그것을 **기능 표식**으로 두고 --preload 를 지나 --go 까지
#         갔으므로 dss-as:6.4 · 6.3 번들에서 **≥1 이었다**(0 이었으면 거기서 멈춘다).
#      🔴 **뒷걸음이 0 이면 진짜 결함이다.**
#   🔴 feature = 번들에 **있어야** 한다 · keep = 뒷걸음 · side = **판정에 안 쓴다**
APPMARKS='
as|feature|폴더 이름 (선택)|🔴 **한글** · ㄷ갈래 화면 글자 (158d6211 · **마지막 커밋** · 소스 기준 0 → 지금 8파일)
as|feature|폴더 이름에 경로 글자|🔴 **한글** · ㄷ갈래 거절 글귀 (158d6211 · 기준 0 → 1파일)
as|feature|확장자는 원본과 같게 유지됩니다|🔴 **한글** · ㄴ갈래 창의 안내 (8adecea8 · 기준 0 → 1파일)
as|feature|파일 이름에 경로 글자|🔴 **한글** · ㄴ갈래 거절 글귀 (8adecea8 · 기준 0 → 1파일)
as|side|INVENTORY_RETURN_REQUEST_TYPE|곁들이 — 예순아홉째 상수의 **export 이름**(웹팩이 줄일 수 있다)
as|side|DATA: "DATA"|곁들이 — ㄱ갈래의 **소스 꼴**(공백 있음). 🔴 번들에는 안 남을 것이다
as|side|DATA:"DATA"|곁들이 — ㄱ갈래의 **minify 꼴**(공백 없음). 🔵 ≥1 이면 다음 판이 이것을 기능 표식으로 쓸 수 있다
as|keep|반환 요청|🔴 **한글** · 예순아홉째의 기능 표식이 내려왔다
as|keep|return-candidates|🔵 **ASCII** · 예순아홉째의 기능 표식이 내려왔다. 🔴 **한글 0 일 때의 대조가 이것이다**
as|keep|부품 신청 거두기|🔴 **한글** · 예순아홉째의 **마지막 커밋**이 올린 글자
as|keep|NO_WAITING_REPAIR_STEP|예순여덟째가 올린 문자열 리터럴
as|keep|shareDocRelativePath|예순일곱째가 올린 칸 이름 (71번 실측 번들 23)
as|keep|도번 / 비고|🔴 **한글** · 예순여섯째가 올린 placeholder 꼬리 (번들 server 1 · static 1)
as|keep|hasLiveApproval|예순네째가 올린 프롭 이름
as|keep|domesticOrders.completedEdit|예순세째가 올린 권한 열쇠
as|keep|faultTags|예순두째가 올린 칸 이름
as|keep|radiogroup|예순한째가 올린 DOM 속성 값
as|keep|"ORDER_ISSUED"|예순째가 올린 상태 값
as|keep|domestic-order-status-filter|쉰아홉째가 올린 DOM id
as|keep|portal_approval_delegations|쉰여덟째가 올린 글자
as|keep|domesticOrders.view|쉰여섯째가 올린 권한 열쇠
'
# 🔴 번들에서 **판정에 쓰는** 표식 수 — 기능 4 + 뒷걸음 14 = **18**. 🔵 곁들이 셋은 안 들어간다.
#    (73번은 A/S 14 · 재고 6 이었다)
AS_MARKS_WANT=18

# ══ 🔴🔴 **한글 표식 — 이 판에는 여덟이다** (70→71→72→73 에서 가져왔다) ══
#   🔴 **71번의 첫 --go 에서 ✗ 가 났던 자리다.** 처음에는 예순여섯째의 뒷걸음
#      표식으로 **part.drawingNo, part.note** 를 썼다 — 「표식은 전부 ASCII」를
#      지키려고 70번의 한글 대신 같은 커밋의 ASCII 쪽을 고른 것인데, 🔴 **쓰임이
#      다른 표식이었다**: 그 글자는 70-build.sh 의 **TOOLMARK_ASCII**(도구 이미지용)
#      이고 **번들용이 아니다.** [실측 2026-11-25 · dss-as:6.2] server **0** · static **0**.
#      까닭 — inventory-gateway.ts:466 의 「part」 가 **지역 이름**이라 minify 가 갈아
#      치운다. 칸 이름은 남아도 **part. 접두사가 사라진다.**
#   🔴 **70번이 번들에서 실제로 쓴 글자는 한글**이다(placeholder 의 문자열 리터럴 —
#      minify 는 문자열 **내용**을 안 바꾼다).
#      [실측] dss-as:6.1 **1/1** · dss-as:6.2 **1/1** → 뒷걸음을 잴 수 있다.
#      🔵 **dss-as:6.5 에서도 같은 값이 나와야 한다** — 그 placeholder 를 건드린
#         커밋이 이번 범위에 **0장**이다.
#   🔴🔴 **이번 판은 한글이 여덟이다**(73번은 여섯) — **기능 표식 넷이 전부 한글**이라
#      경계가 깨지면 **기능 넷이 한꺼번에 ✗** 가 난다. **그래서 이 절이 더 중요해졌다.**
#      🔵 그 자리에서 **ASCII 뒷걸음(return-candidates · shareDocRelativePath)이 ✓ 인데
#         한글만 0** 이면 그것 자체가 「검사가 깨진 것」이라는 증거다(ASCII 대조).
#      [실측 2026-11-26 · 개발 PC] 보낼 바이트 수:
#         [도번 / 비고] **15** · [재고 관리에서 찾기] **26** ·
#         [반환 요청] **13** · [부품 신청 거두기] **23** ·
#         [폴더 이름 (선택)] **22** · [폴더 이름에 경로 글자] **30** ·
#         [파일 이름에 경로 글자] **30** · [확장자는 원본과 같게 유지됩니다] **45**
#      🔵 앞의 넷은 70·71·73번이 잰 값과 **같다.**
#   🔵 **HTTP 머리말에는 한글을 한 글자도 안 넣는다** — 그 규칙은 그대로다.
#      여기서 한글이 가는 길은 **docker run -e 하나뿐**이고, 그것을 1-ㅂ 이 잰다.
#   🔵 [재고 관리에서 찾기] 는 **판정에 안 쓰는 짝**이다 — [도번 / 비고] 와 같은
#      placeholder 의 앞부분이라, 경계가 멀쩡한지 **두 글자로** 재면 「우연히 한 글자만
#      통과」를 가른다.
KO_MARKS='
도번 / 비고
재고 관리에서 찾기
반환 요청
부품 신청 거두기
폴더 이름 (선택)
폴더 이름에 경로 글자
파일 이름에 경로 글자
확장자는 원본과 같게 유지됩니다
'
KO_MARKS_WANT=8

# ══ 🔴🔴 도구 이미지에서 쓸 표식 — **넷 (세 갈래를 다 가린다)** ═══════
#   열쇠|표식|그 표식이 있어야 하는 파일|그 파일 안 기대 줄 수
#   🔴 도구에는 소스가 **글자 그대로** 들어 있다 — minify 를 안 탄다. 번들에서
#      「없다」가 「코드가 없다」와 같은 말이 아니므로 **여기서 한 번 더** 가른다.
#   🔵 **넷 다 기준판에도 있던 파일**이다[실측 2026-11-26 · git cat-file] —
#      새 파일을 과녁으로 삼으면 「기준 0줄」이 **파일이 없어서 0** 인 것이라
#      아무것도 안 가른다(새 파일 둘은 AS_KEY_FILES 가 [ -f ] 로 묻는다).
#   🔴🔴 **첫 줄이 ㄱ갈래(DATA)의 판정 자리 둘 중 하나다** — 번들에는 그 갈래의
#      표식이 없다. 🔵 다른 하나는 **공용 스키마의 "DATA",** 다(preload_inside).
#   🔵 넷째 과녁은 **대괄호가 든 경로**다 — 이미지 안에서도 글롭 잣대가 된다.
#   🔴 **preload_inside 가 이 표를 고리로 돈다** — 71번은 row_by_key 로 **한 줄만**
#      꺼냈다. 그대로 두면 여러 줄이 이어 붙어 표식이 통째로 깨진다.
TOOLMARKS='
astools|DATA: "DATA"|src/lib/domain/attachment-category.ts|1
astools|checkContactFolderSaveFileName|src/components/repair-cases/files/ShareDocFolderPickerDialog.tsx|2
astools|폴더 이름 (선택)|src/components/repair-cases/files/FilesScreen.tsx|5
astools|uploadFolder|src/app/api/repair-cases/[id]/attachments/route.ts|12
'
TOOLMARKS_WANT=4
# 🔴 도구 이미지 **하나가** 몇 개를 돌아야 하는가 — 고리가 한 바퀴만 돌면
#    한쪽 갈래가 **아무 검사도 안 받는다.**
TOOLMARKS_PER_IMAGE_WANT=4
PROBE_MISS=src/__dss_probe_no_such_file__.ts

# ══ 🔴🔴 **지운 파일 — 이미지에 「없어야」 한다** (이 표가 이번에 생겼다) ══
#   열쇠|지운 파일|그 자리를 대신한 파일
#   🔴 **「있는가」만 재는 검사는 지우는 판을 못 막는다** — upload-file-name.ts 가
#      이미지에 남아 있으면 **옛 소스를 구운 것**이다(73번은 지운 파일이 0장이라
#      이 표가 없었다).
#   🔵 **같은 줄에서 반대쪽도 센다** — 그 자리를 대신한 파일은 **있어야** 한다.
#      한쪽만 재면 「둘 다 없는」 꼴을 통과시킨다.
TOOLMARK_GONE='
astools|src/components/repair-cases/files/upload-file-name.ts|src/lib/domain/contact-folder-upload-folder-name.ts
astools|src/components/repair-cases/files/upload-file-name.test.ts|src/components/repair-cases/files/upload-folder-name.test.ts
'
TOOLMARK_GONE_WANT=2

# ══ 🔴 **핵심 파일 표본** — 도구 이미지가 담고 있어야 한다 ════════════
#   🔴 **끝의 세 장이 글롭 잣대다**:
#        src/app/api/repair-cases/[id]/attachments/route.ts  ← 범위 **안** · 대괄호
#        src/app/(app)/repair-cases/[id]/page.tsx            ← 범위 **밖** · 괄호 **그리고** 대괄호
#        src/app/(app)/domestic-orders/page.tsx              ← 범위 **밖** · 괄호
#      🔵 **이번 범위에는 괄호가 0장**이라(73번은 1장) 괄호 잣대 둘을 **범위 밖에서
#         끌어왔다.** 길이 끊기면 그 셋이 **먼저 no 로** 떨어져 「옛 소스」와 갈린다.
#   🔵 **앞의 둘은 이번에 생긴 새 파일**이다 — 도구 표식의 과녁(옛 파일)과 짝을 이룬다.
AS_KEY_FILES='
src/lib/domain/contact-folder-save-file-name.ts
src/lib/domain/contact-folder-upload-folder-name.ts
src/lib/domain/contact-folder-naming.ts
src/lib/domain/attachment-category.ts
src/lib/domain/contact-folder-save-targets.ts
src/lib/storage/contact-folder-archive.ts
src/components/repair-cases/files/FilesScreen.tsx
src/components/repair-cases/files/ShareDocFolderPickerDialog.tsx
src/app/api/repair-cases/[id]/attachments/route.ts
src/app/(app)/repair-cases/[id]/page.tsx
src/app/(app)/domestic-orders/page.tsx
'
AS_KEY_FILES_WANT=11
# 🔵 **INV_KEY_FILES 가 없다** — 재고가 이번 판에 안 올라간다(머리말 「왜 없는가」 ②).
#    🔴 되살릴 때는 **73-deploy.sh:701-714 에서** 가져와라. 🔴 그 목록에는 **tests/ 를
#       한 장도 넣지 마라** — .dockerignore 가 막아 **이미지 안에 없는 것이 정상**이다.

# ══ 🔴 public/ 기대값 — **A/S 한 줄** ═════════════════════════════════
#   열쇠|폴더가 있나(yes|no)|이미지 안 파일 수(참고)|**판정에 쓰는 최솟값**
#   🔴🔴 **넷째 칸을 지우지 마라.** 73번이 그 칸을 만든 까닭은 **재고의 public/ 이
#      있는데 비어 보여서**다(.gitkeep 한 장뿐 · ls -1 은 숨은 파일을 안 센다).
#      재고를 되살릴 때 A/S 잣대를 들이대면 **멀쩡한 이미지가 ✗** 가 된다
#      (62번이 그 가짜 ✗ 를 냈고 69번이 고쳤다).
PUBLIC_WANT='
as|yes|9|1
'
PUBLIC_WANT_N=1

# ══ 🔵 --count 의 참고값 — [운영 실측 2026-11-19 · 예순한째 배포 뒤] ═══
#   🔴 **이것은 ✗ 를 내는 기대값이 아니다.** 사람이 내자 줄을 더하거나 발주일을
#      적으면 정상적으로 달라진다 — 다르면 **⚠️ 로만** 센다.
#   🔴 ✗ 를 내는 것은 **②-ㄴ 의 관문 둘**과 **잣대 검사들**(없는 값으로 물어 0 이
#      나오는가)뿐이다.
CNT_LIVE_REF=36
CNT_DONE_REF=14
CNT_UNDONE_REF=22
CNT_NOORDER_REF=9
# 🔵 **「발주 완료」는 예순한째부터 완료된 줄을 뺀다** — 27 이 아니라 13 이다.
CNT_ISSUED_REF=13
# 🔵 **발주발행일이 적혀 있는 줄**(④절의 세모가 세우는 줄) — 완료 여부를 안 본다.
CNT_ISSUED_ANY_REF=27
CNT_BOTH_REF=0
CNT_CUST_REF=4
CNT_NOCUST_REF=0
# 🔵 **고장 개소 태그**(66번이 더한 ⓪절) — 둘 다 0 이 정상이다. 빼지 마라.
FAULT_BOX=dss-pg-app
FAULT_DB=dss_as
FAULT_TABLE=repair_case_flowcharts
FAULT_COL=fault_tags
CNT_TAGGED_REF=0
CNT_DISTINCT_TAGS_REF=0

# ══ 🔵 **예순세째가 올린 자리** — 권한이 실제로 어떻게 서는가 (⓪-2 · ⑥) ══
PERM_BOX=dss-pg-app
PERM_DB=dss_as
PERM_TABLE=role_permissions
PERM_LIKE='domesticOrders%'
CNT_PERM_ROWS_REF=0
# 🔵 **회차 줄의 완료** — 🔴 **참고값이 없다.** 67번이 처음 센 수라 적어 두지
#    않았고, 그 뒤로도 지어내지 않는다.
ROWDONE_TABLE=domestic_order_due_dates

# ══ 🔵 **예순네째가 올린 자리** — 결재가 올라가 있는 견적서 (⑦) ══════
#   🔴 **참고값은 여전히 없다** — 지어내지 않았다.
QAPP_BOX=dss-pg-app
QAPP_DB=dss_as
QAPP_TABLE=quote_approvals
QAPP_LIVE_SQL="select count(*) from quotes q where q.is_deleted = false and (select a.status from $QAPP_TABLE a where a.quote_id = q.id order by a.requested_at desc limit 1) in ('REQUESTED','APPROVED')"
# 🔴 **없는 값을 함께 묻는다** — 「무조건 0」인 질의인지 가른다. 🔵 status 는 enum
#    이라 없는 글자를 그대로 맞대면 22P02 로 **거절**된다 — 그래서 ::text 로 바꾼다.
QAPP_PROBE_SQL="select count(*) from quotes q where q.is_deleted = false and (select a.status from $QAPP_TABLE a where a.quote_id = q.id order by a.requested_at desc limit 1)::text = '__dss_probe_no_such_status__'"

# ══ 🔵 **예순일곱째가 올린 자리** — ⑧·⑨·⑩ (이제 뒷걸음을 보는 자리다) ══
#   🔴 **71번 고유였던 넷 중 셋을 남겼다.** 「이번 범위 밖이니 지운다」고 착각하기
#      쉬운데, 지난 판들이 **「한 번 빼면 다시 넣는 사람이 없다」**고 반복해 적어 두었다.
#   🔵 **칸이 있는지 먼저 묻는 꼴을 그대로 뒀다** — 이제는 적용이 끝난 뒤라 늘
#      1 이 나와야 하지만, **DB 가 되감긴 날 그 줄만이 그것을 잡는다.**
#   🔴 **이 셋은 ✗ 를 한 번도 안 낸다** — ✗ 를 내는 것은 **잣대 검사**뿐이다.
#   🔴 **참고값이 없다 — 71번이 처음 센 수이고 그 값이 안 적혀 있다.** 지어내지 않았다.
DUE_BOX=dss-pg-app
DUE_DB=dss_as
DUE_TABLE=domestic_order_due_dates
DUE_CONFIRMED_SQL="select count(*) from domestic_order_due_dates where confirmed_at is not null"
# 🔴 두 칸이 **함께 차거나 함께 비어야** 한다 — 0133 의 CHECK 가 그것을 못 박았다.
#    🔵 그 CHECK 가 실제로 서 있으면 아래 수가 **언제나 0** 이다. 0 이 아니면
#       **CHECK 가 안 붙었거나 누가 떼어 낸 것**이다.
DUE_HALF_SQL="select count(*) from domestic_order_due_dates where (confirmed_at is null) <> (confirmed_by is null)"
# 🔴 **기타건** = 수리 건이 안 붙은 내자 줄. 가르는 자리는 repair_case_id IS NULL 하나다.
MISC_ROWS_SQL="select count(*) from domestic_orders where is_deleted = false and repair_case_id is null"
# 🔴🔴 **이 수는 「상한」이다 — 앱의 판정을 그대로 옮긴 것이 아니다.**
#    앱은 뜰지 말지를 **도메인 함수**로 정한다(isDomesticOrderDueDateRowNear) —
#    창은 「오늘 ≤ 날짜 ≤ 오늘+7, **한국 달력**」이고, 끝난 회차(완료 또는 납품일)와
#    **확정된 회차**를 뺀다. 🔵 여기서는 그 조건을 SQL 로 **흉내만** 낸다:
#      · 한국 날짜는 (now() at time zone 'Asia/Seoul')::date 로 잡는다
#      · due_date 는 date 칸이라 시각이 안 섞인다
#    🔴 **그래도 「앱이 센 수」가 아니다** — 그래서 **✗ 를 안 낸다.** 눈 확인에서
#       종을 열어 맞대는 것이 정본이다.
MISC_NEAR_SQL="select count(*) from domestic_order_due_dates d join domestic_orders o on o.id = d.domestic_order_id where o.is_deleted = false and o.repair_case_id is null and d.completed_at is null and d.delivered_date is null and d.confirmed_at is null and d.due_date between (now() at time zone 'Asia/Seoul')::date and ((now() at time zone 'Asia/Seoul')::date + 7)"
# 🔵 **확정 때문에 빠진 줄**이 몇인가 — ㄱ 갈래가 ㄴ 갈래를 실제로 끄는지 보는 자리.
MISC_NEAR_SILENCED_SQL="select count(*) from domestic_order_due_dates d join domestic_orders o on o.id = d.domestic_order_id where o.is_deleted = false and o.repair_case_id is null and d.completed_at is null and d.delivered_date is null and d.confirmed_at is not null and d.due_date between (now() at time zone 'Asia/Seoul')::date and ((now() at time zone 'Asia/Seoul')::date + 7)"
# 🔴 **노드 표 둘** — 칸이 있는가 · 가리킨 노드가 몇인가
NODE_TABLES='
procedure_template_nodes|절차 본보기 노드
repair_case_flowchart_nodes|진단 Flowchart 노드
'
NODE_TABLES_WANT=2
NODE_COL=share_doc_relative_path

# ══ 🔵 **72번이 올린 것이 운영에서 아직 도는가** (⑪·⑫·⑬) ════════════
#   🔴 **셋 다 ✗ 를 한 번도 안 낸다** — ✗ 를 내는 것은 **잣대 검사**뿐이다.
#   🔴 표·칸 이름은 전부 **스키마에서 확인한 것**이다(vendor/dss-core 의 workflow.ts ·
#      repair-cases.ts · domestic-order-due-dates.ts). 지어내지 않았다.
#
# ── ⑪ 🔴 **확정된 회차 중 「완료된」 것** — 화면에서 확정 단추가 사라지는 줄
DUE_CONFIRMED_DONE_SQL="select count(*) from domestic_order_due_dates d join domestic_orders o on o.id = d.domestic_order_id where o.is_deleted = false and d.confirmed_at is not null and (o.completed_at is not null or d.completed_at is not null)"
DUE_DONE_ANY_SQL="select count(*) from domestic_order_due_dates d join domestic_orders o on o.id = d.domestic_order_id where o.is_deleted = false and (o.completed_at is not null or d.completed_at is not null)"
#
# ── ⑫ 🔴 **작업 상태가 [수리 대기]인 건**
#   🔴 **상태는 저장 칸이 아니다** — repair_cases.current_workflow_step_id 가 가리키는
#      workflow_steps 의 **repair_status** 에서 나온다(mappers/repair-status.ts).
WR_STATUS=WAITING_REPAIR
WR_CASES_SQL="select count(*) from repair_cases c join workflow_steps s on s.id = c.current_workflow_step_id where c.is_deleted = false and s.repair_status::text = '$WR_STATUS'"
WR_STEPS_SQL="select count(*) from workflow_steps where repair_status::text = '$WR_STATUS'"
WR_VER_NOSTEP_SQL="select count(*) from workflow_versions v where not exists (select 1 from workflow_steps s where s.workflow_version_id = v.id and s.repair_status::text = '$WR_STATUS')"
# 🔴 **없는 상태로 물어 0 이 나오는가** — 🔵 repair_status 는 **enum** 이라 없는 글자를
#    그대로 맞대면 22P02 로 **거절**된다. 그래서 ::text 로 바꿔 묻는다.
WR_PROBE_SQL="select count(*) from workflow_steps where repair_status::text = '__dss_probe_no_such_status__'"
#
# ── ⑬ 🔴 **납품 요청일을 「빌려 오는」 건**
BORROW_ALL_SQL="select count(*) from repair_cases c where c.is_deleted = false and c.customer_requested_due_date is null and exists (select 1 from domestic_orders o join domestic_order_due_dates d on d.domestic_order_id = o.id where o.repair_case_id = c.id and o.is_deleted = false)"
BORROW_PORTAL_SQL="select count(*) from repair_cases c join workflow_steps s on s.id = c.current_workflow_step_id where c.is_deleted = false and s.repair_status::text <> 'SHIPMENT_COMPLETED' and c.customer_requested_due_date is null and exists (select 1 from domestic_orders o join domestic_order_due_dates d on d.domestic_order_id = o.id where o.repair_case_id = c.id and o.is_deleted = false)"
BORROW_PROBE_SQL="select count(*) from repair_cases c where c.is_deleted = false and c.customer_requested_due_date is null and exists (select 1 from domestic_orders o join domestic_order_due_dates d on d.domestic_order_id = o.id where o.repair_case_id = c.id and o.is_deleted = false and d.due_date = date '1900-01-01')"
CNT_BORROW_REF=8

# ══ 🔵 **73번이 올린 것이 운영에서 아직 도는가** (⑭~⑲) ═══════════════
#   🔴 **전부 dss_inventory 다**(dss-pg-app 안에 있다). 🔴 **그 집은 이번에 안
#      올라가지만 이 여섯을 하나도 안 뺐다** — 그 기능이 **어제 올라가 운영에서
#      돌고 있어** 뒷걸음을 봐야 한다.
#   🔴 **여섯 다 ✗ 를 한 번도 안 낸다** — ✗ 를 내는 것은 **잣대 검사**뿐이다.
#   🔴🔴 **셋 다 enum 이다** — stock_requests.type 과 stock_entries.type 은
#      entry_type, stock_requests.status 는 stock_request_status. 없는 글자를
#      그대로 맞대면 **22P02 로 거절**되므로 **잣대 검사는 ::text 로 바꿔** 묻는다.
INV_BOX=dss-pg-app
INV_DB=dss_inventory
REQ_TABLE=stock_requests
#
# ── ⑭ 🔴 **반환 신청(type='RETURN')** — 상태별로
RET_ALL_SQL="select count(*) from stock_requests where type::text = 'RETURN'"
RET_BY_STATUS_SQL="select status::text || ' | ' || count(*) from stock_requests where type::text = 'RETURN' group by status order by status"
# 🔵 **대기로 세는 상태 다섯** — 재고의 PENDING_REQUEST_STATUSES 를 글자 그대로 옮겼다.
RET_PENDING_SQL="select count(*) from stock_requests where type::text = 'RETURN' and status::text in ('PENDING','CONFIRMING','PARTIAL','ON_HOLD','IN_APPROVAL')"
RET_PROBE_SQL="select count(*) from stock_requests where type::text = '__dss_probe_no_such_type__'"
#
# ── ⑮ 🔴 **반출 신청(type='USE')** — 🔴 **이 배포가 한 줄도 안 바꿔야 한다**
USE_ALL_SQL="select count(*) from stock_requests where type::text = 'USE'"
#
# ── ⑯ 🔴 **[반환 완료]된 반환** — 종이 뜰 줄의 수 (COMPLETED_RETURN_STATUSES 는 CONFIRMED 하나)
RET_DONE_SQL="select count(*) from stock_requests where type::text = 'RETURN' and status::text = 'CONFIRMED'"
#
# ── ⑰ 🔴 **돌려줄 수 있는 부품이 있는 수리 건**
RETURNABLE_CASES_SQL="select count(distinct e.intake_number) from stock_transactions t join stock_entries e on e.id = t.entry_id where e.type::text in ('USE','LOAN') and t.delta < 0 and e.intake_number <> '' and not exists (select 1 from stock_transactions x where x.reverses_transaction_id = t.id) and ((-t.delta) - coalesce((select sum(r.delta) from stock_transactions r where r.returns_transaction_id = t.id), 0)) > 0"
RETURNABLE_LINES_SQL="select count(*) from stock_transactions t join stock_entries e on e.id = t.entry_id where e.type::text in ('USE','LOAN') and t.delta < 0 and e.intake_number <> '' and not exists (select 1 from stock_transactions x where x.reverses_transaction_id = t.id) and ((-t.delta) - coalesce((select sum(r.delta) from stock_transactions r where r.returns_transaction_id = t.id), 0)) > 0"
RETURNABLE_PROBE_SQL="select count(distinct e.intake_number) from stock_transactions t join stock_entries e on e.id = t.entry_id where e.type::text = '__dss_probe_no_such_type__' and t.delta < 0"
# 🔵 **반대쪽 잣대** — 거르개를 걷으면 수가 늘어야 한다.
RETURNABLE_WIDE_SQL="select count(distinct e.intake_number) from stock_entries e where e.intake_number <> ''"
#
# ── ⑱ 🔴 **반환 원장 건** — [기록 내역]의 머리글이 인수번호로 바뀌는 줄
RET_ENTRY_SQL="select count(*) from stock_entries where type::text = 'RETURN'"
RET_ENTRY_INTAKE_SQL="select count(*) from stock_entries where type::text = 'RETURN' and intake_number <> ''"
RET_ENTRY_TITLED_SQL="select count(*) from (select e.id from stock_entries e join stock_transactions t on t.entry_id = e.id join stock_transactions o on o.id = t.returns_transaction_id join stock_entries oe on oe.id = o.entry_id where e.type::text = 'RETURN' and oe.intake_number <> '' group by e.id having count(distinct oe.intake_number) = 1) s"
RET_ENTRY_PROBE_SQL="select count(*) from stock_entries where type::text = '__dss_probe_no_such_type__'"

# ── 🔵 **재고의 뒷걸음 표 둘** — 69번이 보던 자리 (🔴 한 번 빼면 안 넣는다)
KEEPTBL_INV1=portal_approval_delegations
KEEPTBL_INV2=stock_issue_approval_steps

# ══ 🔴🔴 **74번 고유 — DATA 분류가 운영에서 실제로 쓰일 자리** (⑳) ════
#   🔴 **첨부 표는 dss_as 안에 있다**(vendor/dss-core 의 attachments.ts).
#      칸 이름은 category(attachment_category enum) · is_deleted(boolean)다.
#      지어내지 않았다 — 스키마에서 확인했다.
#   🔴🔴 **category 는 enum 이다** — 없는 글자를 그대로 맞대면 22P02 로 **거절**된다.
#      그래서 **::text 로 바꿔** 묻는다. 🔵 그 덕에 **적용 전에도 질의가 돈다**
#      (그 값이 enum 에 없어도 거절되지 않는다 — 그냥 0 이 나온다).
#   🔵 **운영에는 0건일 것이다** — 이 분류가 **지금 생긴다.** 🔴 **0 이 정상**이고,
#      그러면 눈 확인에서 그 분류의 파일이 **한 장도 안 보이는 것이 맞다.**
ATT_BOX=dss-pg-app
ATT_DB=dss_as
ATT_TABLE=attachments
ATT_DATA_SQL="select count(*) from attachments where category::text = 'DATA' and is_deleted = false"
ATT_DATA_ALL_SQL="select count(*) from attachments where category::text = 'DATA'"
# 🔵 **반대쪽 잣대** — 거르개를 걷으면 수가 늘어야 한다(「무조건 0」인 질의를 가른다).
ATT_LIVE_SQL="select count(*) from attachments where is_deleted = false"
# 🔴 **없는 분류로 물어 0 이 나오는가** — enum 이라 ::text 로 바꿔 묻는다.
ATT_PROBE_SQL="select count(*) from attachments where category::text = '__dss_probe_no_such_category__'"

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
     printf '🔴 **--tools 는 없습니다** — 73·72·70·69 번에 있던 자리입니다.\n'
     printf '   이번 판은 마이그레이션이 **1건**이라 그 자리가 **--migrate** 입니다\n'
     printf '   (덤프 **하나**를 뜨고 · **묶음을 볼륨에 풀고**(134 → 135) · 도구 태그\n'
     printf '    **하나**를 갈고 · db:preflight 로 **대기 1건**을 값으로 받고 ·\n'
     printf '    db:migrate 를 돌린 뒤 **수를 다시 세고** · **enum 에 DATA 가 생겼는지**를 봅니다.\n'
     printf '    🔴 **거기서 DB 가 바뀝니다**).\n'
     exit 2 ;;
esac

mkdir -p "$D/setup/logs" 2>/dev/null
LOG="$D/setup/logs/deploy70-$(printf '%s' "$MODE" | tr -d '-')-$STAMP.log"
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
# 🔴 도구 열쇠(astools)에서 집 열쇠(as)를 뽑는다.
repo_key_of() { printf '%s' "${1%tools}"; }

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
#      🔴 **이번 판은 집이 둘이라 그 결함이 실제로 티가 난다.**
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
printf '%s\n' " 74-deploy.sh — 일흔째 배포 ($MODE)"
printf '%s\n' "   때      : $(date '+%F %T')"
printf '%s\n' "   로그    : $LOG"
printf '%s\n' "   compose : $CF"
printf '%s\n' "   앱 1(A/S관리) · 도구 1 · tar 2 · 🔴🔴 **마이그레이션 1건 · 묶음 하나**"
printf '%s\n' "   (dss_as $AS_VOL_SQL_WAS → $AS_VOL_SQL_WANT · 0134 가 enum 에 $ENUM_VALUE 를 더한다) ·"
printf '%s\n' "   안 건드리는 집 9 · 안 바뀌는 DB 4"
printf '%s\n' "   🔴 **묶음을 안 풀면 적용이 0건으로 조용히 끝납니다** — A/S 는 볼륨에서 돕니다."
printf '%s\n' "      🔴 **incoming 에 2026-11-25 의 옛 묶음이 남아 있습니다**(134장) —"
printf '%s\n' "         3-ㄴ 이 md5 로 그것을 가릅니다."
printf '%s\n' "   🔵 **재고관리가 「안 건드리는 집」으로 돌아왔습니다** (73번에서는 올라갔습니다)"
printf '%s\n' "      🔴 1-ㄷ 이 **셋을 같은 줄에서 함께** 못 박습니다 —"
printf '%s\n' "         dss-auth 1 · dss-inventory 1 · **dss-as 0**(올라가는 집)."
printf '%s\n' "══════════════════════════════════════════════════════════════"
# 🔴 **제 md5 를 스스로 찍는다** — DSM 터미널이 긴 명령을 잘라 먹으므로
#    개발 PC 의 Get-FileHash 와 **눈으로 맞댄다.**
printf '  이 파일의 md5: %s\n' "$(md5sum "$0" 2>/dev/null | awk '{print $1}')"
printf '%s\n' "  🔴 **위 값을 개발 PC 의 Get-FileHash -Algorithm MD5 74-deploy.sh 와 맞대세요.**"
printf '%s\n' "     다르면 **올리다 잘린 것**입니다 — 그대로 쓰면 아래 검사가 통째로 거짓이 됩니다."

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
#    🔴 판 꼬리표는 **파일 이름 쪽에만** 있으므로 basename 을 먼저 떼고,
#       별표가 아니라 **더하기(한 자리 이상)**로 센다.
b1=$(basename "$BK" | grep -oE 'v[0-9]+' | head -1)
printf '    덤프 꼬리표 %s · compose 사본 이름 %s → 뽑은 꼬리표 [%s]\n' "$DUMP_VER" "$(basename "$BK")" "${b1:-못 뽑음}"
if [ -z "${b1:-}" ]; then
  unk "compose 사본의 판 꼬리표" "이름에서 v숫자 를 못 뽑았다 — 잣대를 보세요"
elif [ "$b1" = "$DUMP_VER" ]; then ok "덤프와 compose 사본의 판 꼬리표가 같다 ($DUMP_VER)"
else bad "compose 사본은 $b1 인데 덤프는 $DUMP_VER 다 — 59번이 이 자리를 놓쳤다"; fi

# 1-ㄱ. 🔴 운영이 지금 쓰는 태그 — 앱 **하나**
say ""
say "── 1-ㄱ. 🔴 앱 **하나** — compose 의 image: 줄을 **통째로** 찍는다"
say "🔵 73번은 여기가 **두 줄**이었습니다(A/S + 재고). 🔴 **고리 꼴을 그대로 뒀습니다** —"
say "   집이 다시 둘이 되는 날 **표에 줄만 더하면** 됩니다."
say "🔴 끝의 관문이 「몇 집을 봤는가」를 값으로 셉니다 — 🔵 집이 하나라 지금은 티가"
say "   안 나지만, **빼면 집이 둘이 되는 날 조용히 반쪽만 재게** 됩니다."
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
  printf '      %-14s %-16s %-24s %s\n' "$NAME" "$SVC" "${cur:-없음}" "$st"
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
# 🔴 **표본이 비어서 공짜로 통과하지 않게** 한다.
[ "$SITE_SEEN" = "$SITES_WANT" ] && ok "앱 ${SITES_WANT}곳을 다 봤다 (표본이 비지 않았다)" \
  || bad "앱을 ${SITE_SEEN}곳만 봤다 — ${SITES_WANT}곳을 기대했다. SITES 표가 깨졌다"
say "앱 단계 — 새 판 ${PHASE_APP_NEW} · 옛 판 ${PHASE_APP_PRE} · 그 밖 ${PHASE_APP_ODD}"

# 1-ㄴ. 도구 **하나**
say ""
say "── 1-ㄴ. 🔴 도구 **하나** — **--migrate 가 이 줄을 간다**"
say "🔵 73번은 여기가 **두 줄**이었고 그 자리가 **--tools** 였습니다(마이그레이션 0건)."
say "   🔴 **이번 판은 1건**이라 71·66번처럼 **--migrate 안에서** 갑니다 —"
say "      db:migrate 를 **새 도구로** 돌려야 하기 때문입니다."
say "🔴 **A/S 도구를 가는 까닭이 둘입니다:** src/ **30장**이 바뀌었고, 🔴🔴 **공용"
say "   스키마(vendor/dss-core)에 enum 값 ${ENUM_VALUE} 가 생겼습니다.** 안 갈면 **그 값을"
say "   모르는 스키마**로 db:migrate 를 돌리게 됩니다."
say "🔴🔴 **.sql 이 어디서 도는지가 집마다 정반대입니다:**"
say "   · A/S  — **볼륨**이 정본(/volume1/dss/as-migrations · 이미지 안은 **0장**)"
say "   · 재고 — **이미지**가 정본(도구 이미지 안 **${INV_IMG_SQL_WANT}장**)"
say "   🔴 한 잣대로 뭉뚱그리면 **둘 중 하나가 반드시 가짜 ✗** 입니다(69번의 경고)."
say "🔴🔴 **이번 판은 A/S 볼륨에 한 장을 더합니다** — 묶음을 **풀어야** ${AS_VOL_SQL_WAS} → ${AS_VOL_SQL_WANT} 가"
say "   됩니다(2-ㄷ 이 단계로 갈라서 잽니다). 🔵 재고 이미지의 ${INV_IMG_SQL_WANT}장은 그대로입니다"
say "   (2-ㄷ-2 가 **뒷걸음**으로 셉니다 — 그 집은 이번에 안 올라갑니다)."
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
        say "   🔴 **이번 판은 그 둘을 DB 로 가를 수 있습니다** — --migrate 를 돌았으면"
        say "      dss_as 가 **${AS_VOL_SQL_WANT}** 이고 enum 에 ${ENUM_VALUE} 가 **있습니다**(2절이 값으로 잽니다)."
        say "      🔵 그래도 「--migrate 직후」와 「--go 뒤 --rollback」은 DB 가 같습니다 —"
        say "         그 둘을 가르려면 **로그 파일 이름**(deploy70-go-… / deploy70-rollback-…)을 보세요." ;;
  POST) say "--go 까지 돌았습니다. --count 로 뒤의 수를 재세요." ;;
  ODD)  hm "단계가 섞여 있습니다 — 위 표를 사람이 보세요. **막지는 않습니다.**"
        say "      🔵 집이 하나라 섞일 자리가 적습니다 — 앱과 도구가 서로 다른 판인 꼴이"
        say "         흔한 모양입니다(--migrate 만 돌았으면 MID 입니다)."
        say "      🔴 **DB 는 2절이 따로 잽니다** — 단계가 ODD 라도 거기서 DBPHASE 를 보세요." ;;
esac

# 1-ㄷ. 🔴 안 건드리는 **아홉** — 「옆으로 안 샜다」는 증거
say ""
say "── 1-ㄷ. 🔴 안 건드리는 **아홉** — 도는가 · 어느 이미지인가 · 언제 켜졌는가"
say "🔴 **도는가만 보지 않습니다** — 이미지와 켜진 때를 **적어 두고 끝에서 맞댑니다.**"
say "   2026-11-18 에 ✗ 가 바로 그 자리에서 났습니다(DB 가 Recreate 됐습니다)."
say "🔴🔴 **dss-inventory 가 이 목록으로 돌아왔습니다**(73번은 여덟이었고 거기선"
say "   올라갔습니다). 🔴 **73번 것을 그대로 두었으면** 「재고가 목록에 없는가(0)」가"
say "   **가짜 ✗** 를 냈을 것입니다 — 이번엔 **있어야**(1) 맞습니다."
say "🔴 **dss-auth 는 그대로 남아 있습니다** — 이번에도 안 건드립니다."
say "🔴🔴 **그리고 dss-as 는 이 목록에 있으면 안 됩니다** — 이번에 올라가는 집입니다."
say "   🔵 **셋을 같은 줄에서 함께 셉니다** — 한쪽만 재면 번호가 빗나가도 통과합니다."
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
# 🔴🔴 **세 집을 같은 줄에서 함께 못 박는다** — 「있는가」만 재면 번호가 빗나가도
#    통과한다(그 규율이 AS_VOL_LAST 에서 왔다).
#    · dss-auth      **1** 이어야 한다 — 안 건드리는 집(73번과 같다)
#    · dss-inventory **1** 이어야 한다 — 🔴 **이번에 돌아왔다**(73번은 0 이었다)
#    · dss-as        **0** 이어야 한다 — 🔴 **이번에 올라가는 집**이라 여기 있으면
#      끝의 맞대기가 「A/S 가 달라졌다」로 **가짜 ✗** 를 낸다
#    🔴 한쪽만 재서 고치면 다른 쪽이 조용히 어긋난다. 71번은 포털만, 72번은 포털만,
#       73번은 포털과 재고만 재고 있었다 — **이 판은 셋 다** 잰다.
na=$(printf '%s\n' "$KEEP_BOXES" | tr ' ' '\n' | grep -cFx 'dss-auth' || true)
ni=$(printf '%s\n' "$KEEP_BOXES" | tr ' ' '\n' | grep -cFx 'dss-inventory' || true)
ns=$(printf '%s\n' "$KEEP_BOXES" | tr ' ' '\n' | grep -cFx 'dss-as' || true)
printf '      안 건드리는 목록에 dss-auth 가 있나: %s개 (기대 1 — **안 건드리는 집이다**)\n' "${na:-?}"
printf '      안 건드리는 목록에 dss-inventory 가 있나: %s개 (기대 1 — 🔴 **73번은 0 이었다**)\n' "${ni:-?}"
printf '      안 건드리는 목록에 dss-as 가 있나: %s개 (기대 0 — **이번에 올라가는 집이다**)\n' "${ns:-?}"
if [ "${na:-x}" = "1" ] && [ "${ni:-x}" = "1" ] && [ "${ns:-x}" = "0" ]; then
  ok "포털과 재고관리는 **목록에 있고** A/S 는 **목록에 없다** (이 배포의 전제와 맞다)"
else
  [ "${na:-x}" = "1" ] || bad "포털이 「안 건드리는 집」에 **안 들어 있다** — 🔴 그 집을 한 번도 안 재게 된다"
  [ "${ni:-x}" = "1" ] || bad "재고관리가 「안 건드리는 집」에 **안 들어 있다** — 🔴 어제 올린 집을 한 번도 안 재게 된다"
  [ "${ns:-x}" = "0" ] || bad "A/S 가 「안 건드리는 집」에 **들어 있다** — 🔴 끝의 맞대기가 **가짜 ✗** 를 낸다"
  doubt
fi
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
say "🔵 **dss-pg-auth 는 이번에도 「안 건드리는 집」의 DB 입니다** — go_gate 는 그것을"
say "   안 묻고(71번은 포털 앱을 띄워서 물었습니다), **켜진 때만** 끝에서 맞댑니다."
say "   🔴 그 맞대기는 **빼지 않습니다** — --no-deps 가 안 들면 그 DB 도 다시 뜹니다."
say "🔴🔴 **이번 판은 올라가는 집이 하나인데 go_gate 는 DB 를 둘 잽니다**(dss_as ·"
say "   dss_inventory · 둘 다 dss-pg-app 안입니다). 🔴 **재고 DB 를 안 뺐습니다** —"
say "   어제 올라간 A/S 의 **부품 반환**이 그 DB 를 부르고, 거기가 죽으면 **어제 올린"
say "   기능이 조용히 깨집니다.** 🔵 상자가 살아 있어도 그 안의 DB 하나가 없어지거나"
say "   권한이 닫힐 수 있어 **DB 이름마다 따로** 묻습니다."

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

# 1-ㅁ. 🔵 incoming 폴더 — **이번 판은 쳐다보지도 않는다**
say ""
say "── 1-ㅁ. 🔴 incoming 폴더 — **이번 판은 여기서 묶음을 읽습니다**"
say "🔴 **73번과 뜻이 반대입니다**(거기는 「쳐다보지도 않는다」였습니다) —"
say "   --migrate 가 여기 있는 묶음을 풀어 볼륨을 ${AS_VOL_SQL_WAS} → ${AS_VOL_SQL_WANT}장으로 만듭니다."
say "🔴🔴 **거기에 2026-11-25 의 옛 묶음이 아직 남아 있습니다**(71번이 보낸 **134장**짜리 ·"
say "   ${OLD_MIGTAR_SIZE}바이트 · md5 ${OLD_MIGTAR_MD5})."
say "   🔵 **이름이 같아 scp 가 덮어씁니다** — 새것을 보내기만 하면 갈립니다."
say "   🔴 **안 보내면 옛 134장이 풀려** 적용이 **0건으로 조용히** 끝납니다."
say "   🔴 **3-ㄴ 이 md5 로 그 둘을 가릅니다** — 아래 날짜와 크기도 함께 보세요."
say "      쉰여섯째·쉰일곱째가 **두 판 연속** 옛 묶음을 보내 ✗ 를 냈습니다."
mkdir -p "$INCOMING" 2>/dev/null; chmod 777 "$INCOMING" 2>/dev/null
ls -l "$INCOMING" 2>/dev/null | sed 's/^/        /'
if [ -f "$MIGTAR" ]; then
  isz=$(stat -c %s "$MIGTAR" 2>/dev/null)
  im5=$(md5sum "$MIGTAR" 2>/dev/null | awk '{print $1}')
  printf '      묶음 — %s바이트 · md5 %s\n' "${isz:-?}" "${im5:-?}"
  printf '      옛 묶음(2026-11-25 · 134장) — %s바이트 · md5 %s\n' "$OLD_MIGTAR_SIZE" "$OLD_MIGTAR_MD5"
  if [ "${im5:-x}" = "$OLD_MIGTAR_MD5" ]; then
    case "$MODE" in
      --check|--count|--rollback)
        hm "🔴 **지금 거기 있는 것은 2026-11-25 의 묶음입니다**(134장) — 아직 안 보내셨습니다"
        say "      🔵 보내기 전이면 정상입니다. 🔴 **--migrate 전에는 꼭 보내세요** —"
        say "         그대로 풀면 볼륨이 ${AS_VOL_SQL_WAS}장 그대로이고 적용이 0건으로 끝납니다." ;;
      *)  bad "🔴🔴 **옛 묶음(2026-11-25 · 134장)이 그대로 있다** — 이번 것을 안 보냈다"
          say "      scp -O as-migrations.tar.gz dss-nas:$INCOMING/" ;;
    esac
  else
    ok "incoming 의 묶음이 **옛 것과 md5 가 다르다** (3-ㄴ 이 안을 셉니다)"
  fi
else
  case "$MODE" in
    --check|--count|--rollback) unk "묶음" "아직 $INCOMING 에 없다 (보내기 전이면 정상)" ;;
    *) hm "incoming 에 묶음이 없습니다 — **--migrate 전에 보내야 합니다**"
       say "      scp -O as-migrations.tar.gz dss-nas:$INCOMING/" ;;
  esac
fi

# 1-ㅂ. 🔴🔴 **한글이 컨테이너 경계를 글자 그대로 건너가는가**
#   🔴 **70→71→72→73 으로 내려온 절이다**(70-deploy.sh:803-856 이 원본).
#      🔴🔴 **이번 판은 한글 표식이 여덟이다** — 73번은 여섯이었다. **기능 표식 넷이
#         전부 한글**이라서다. 그래서 이 절이 **더 중요해졌다**: 경계가 깨지면
#         **기능 표식 넷이 한꺼번에 ✗** 가 난다.
#   🔵 길은 「보내고 **되돌려 받아** 글자와 **바이트 수**를 맞댄다」다.
#      🔴 8진 이스케이프로 우회하지 않았다 — 백슬래시 한 겹이 조용히 삼켜지는
#         함정이 적혀 있어 **그 길이 더 위험**하다.
#   🔵 NAS 는 리눅스라 Git Bash 의 인자 번역 함정은 없다. 🔴 그래도 **로케일**은
#      다를 수 있고 DSM 터미널이 긴 명령을 잘라 먹은 적도 있다 — 그래서 잰다.
say ""
say "── 1-ㅂ. 🔴🔴 **한글이 컨테이너 안까지 글자 그대로 가는가** (표식 여덟이 한글이다)"
say "🔴 이 줄이 ✗ 면 **이미지가 아니라 검사가 깨진 것**입니다 — 아래 한글 표식의"
say "   0 을 결함으로 읽지 마세요."
say "🔴🔴 **이번 판은 기능 표식 넷이 전부 한글이고 ASCII 기능 표식이 하나도 없습니다.**"
say "🔵 **대조는 뒷걸음 쪽이 맡습니다** — return-candidates · shareDocRelativePath(둘 다"
say "   ASCII)가 ≥1 인데 **한글만 0** 이면 그것 자체가 「한글 grep 이 안 되는 것」이라는"
say "   증거입니다. 🔴 **그때는 이미지를 되돌리지 마세요.**"
KOIMG=""
for t in "$(field "$(row_by_key "$SITES" as)" 4)" "$(field "$(row_by_key "$SITES" as)" 5)"; do
  [ -n "${t:-}" ] || continue
  if [ -z "${KOIMG:-}" ] && "$DOCKER" image inspect "$t" >/dev/null 2>&1; then KOIMG=$t; fi
done
if [ -z "${KOIMG:-}" ]; then
  unk "한글 경계" "잴 이미지가 없다 — 새 판도 옛 판도 NAS 에 없다"
else
  say "재는 데 쓴 이미지: $KOIMG"
  KO_SEEN=0; KO_OK=0
  ko_probe() { # 1 글자
    local hb v got cb
    KO_SEEN=$((KO_SEEN+1))
    hb=$(printf '%s' "$1" | wc -c | tr -d ' ')
    v=$("$DOCKER" run --rm -e DSSKO="$1" --entrypoint sh "$KOIMG" -c \
      'printf "%s|%s\n" "$DSSKO" "$(printf "%s" "$DSSKO" | wc -c | tr -d " ")"' </dev/null 2>/dev/null | tr -d '\r')
    got=$(printf '%s' "$v" | cut -d'|' -f1)
    cb=$(printf '%s' "$v" | cut -d'|' -f2)
    printf '      보낸 [%s] %s바이트 → 받은 [%s] %s바이트\n' "$1" "$hb" "${got:-못 읽음}" "${cb:-?}"
    if [ "${got:-}" = "$1" ] && [ "${cb:-x}" = "$hb" ]; then
      KO_OK=$((KO_OK+1))
    else
      bad "한글이 경계에서 **달라졌다** — 받은 [${got:-못 읽음}] ${cb:-?}바이트 (보낸 ${hb}바이트)"
      say "      🔴 **이미지를 의심하지 마세요.** 로케일이나 인자 전달이 깨진 것입니다."
      doubt
    fi
  }
  while IFS= read -r km; do
    [ -n "$km" ] || continue
    ko_probe "$km"
  done <<ENDKO
$(rows_of "$KO_MARKS")
ENDKO
  say "본 한글 ${KO_SEEN}개 · 그대로 건너간 것 ${KO_OK}개 (기대 $KO_MARKS_WANT · $KO_MARKS_WANT)"
  if [ "$KO_SEEN" = "$KO_MARKS_WANT" ] && [ "$KO_OK" = "$KO_MARKS_WANT" ]; then
    ok "한글 ${KO_MARKS_WANT}개가 **컨테이너까지 글자 그대로 간다** (아래 0 을 결함으로 읽어도 된다)"
    say "      🔵 [실측 2026-11-26 · 개발 PC] 보낸 바이트: [도번 / 비고] 15 ·"
    say "         [재고 관리에서 찾기] 26 · [반환 요청] 13 · [부품 신청 거두기] 23 ·"
    say "         [폴더 이름 (선택)] 22 · [폴더 이름에 경로 글자] 30 ·"
    say "         [파일 이름에 경로 글자] 30 · [확장자는 원본과 같게 유지됩니다] 45."
    say "         받은 쪽이 그와 같으면 경계가 멀쩡합니다."
  else
    bad "본 것 ${KO_SEEN} · 그대로인 것 ${KO_OK} 다 — ${KO_MARKS_WANT} 를 기대했다"
    say "      🔴 **아래 한글 표식의 ✗ 는 전부 이 줄의 결과입니다.** 되돌리지 마세요."
  fi
fi

# ══════════════════════════════════════════════════════════════════════
# ── 2. 🔴🔴 DB — **1건이다.** 단계마다 기대값이 다르다
# ══════════════════════════════════════════════════════════════════════
step "2. 🔴🔴 DB — 마이그레이션 **1건** (A/S 만 움직인다 · 네 집은 그대로)"
say "🔴 **73번은 여기가 「0건이다」였습니다** — 거기에는 MIGS 표도 DBPHASE·VOLPHASE 도"
say "   **없었습니다**(적용 전과 뒤의 기대값이 같았기 때문입니다). 🔴 **이번엔 뒤집힙니다** —"
say "   71-deploy.sh 에서 그 셋을 되살렸습니다."
say "🔴 **단계를 먼저 정하고 가지를 나눕니다**(48번이 데인 자리). 아래 셋은 적용 전과"
say "   뒤의 **기대값이 정반대**입니다:"
say "     · dss_as 마이그레이션 수 — 적용 전 **${AS_VOL_SQL_WAS}** · 뒤 **${AS_VOL_SQL_WANT}**"
say "     · 볼륨의 .sql 수        — 적용 전 **${AS_VOL_SQL_WAS}장** · 뒤 **${AS_VOL_SQL_WANT}장**"
say "     · enum 의 ${ENUM_VALUE}             — 적용 전 **없다(0)** · 뒤 **있다(1)**"
say "   🔴 한 잣대로 재면 둘 중 하나가 반드시 **가짜 ✗** 입니다."
say "🔴 **빼지 않는 까닭**: 빼면 「운영 DB 가 지금 몇 건인지」를 아무도 안 보게 되고,"
say "   그 수가 어긋나면 **이 배포와 무관한 다른 사고**인데 끝까지 모릅니다."

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
    say "      🔴 **이 배포본은 ${BEF} 에서 ${AFT} 로 가는 것만 압니다.** 다른 수가 나왔다면"
    say "         누가 다른 길로 올렸다는 뜻입니다."
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
  TODO) say "적용 전입니다 — 아래의 「enum 에 ${ENUM_VALUE} 가 없다」·「볼륨 ${AS_VOL_SQL_WAS}장」이 **맞는 값**입니다." ;;
  DONE) say "적용이 끝났습니다 — 아래의 「enum 에 ${ENUM_VALUE} 가 있다」·「볼륨 ${AS_VOL_SQL_WANT}장」이 **맞는 값**입니다." ;;
  *)    hm "단계를 못 가렸습니다 — 아래는 **값만 찍고 판정하지 않습니다.**" ;;
esac

# 2-ㄱ-2. 🔴 **안 바뀌어야 하는 네 집** (재고가 여기 있다)
say ""
say "── 2-ㄱ-2. 🔴 마이그레이션 수 — **네 집은 전과 같아야 한다**"
say "🔴🔴 **dss_as 가 여기서 빠졌습니다**(73번은 다섯이었습니다) — 이번엔 **움직이는"
say "   집**이라 위 MIGS 표로 옮겨 갔습니다. 🔴 두 표에 같은 집을 두면 한쪽이 반드시 ✗ 입니다."
say "🔵 **재고(28)는 여기 그대로 있습니다** — 그 집은 앱도 DB 도 이번에 안 바뀝니다."
MIGK_SEEN=0; MIGK_OK=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  BOX=$(field "$r" 2); DB=$(field "$r" 3); WANT=$(field "$r" 4); NAME=$(field "$r" 5)
  MIGK_SEEN=$((MIGK_SEEN+1))
  v=$(mig_count "$BOX" "$DB")
  printf '      %-14s %-14s %-16s 지금 %-5s (기대 %s)\n' "$NAME" "$BOX" "$DB" "${v:-못 읽음}" "$WANT"
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

# 2-ㄱ-3. 🔴 **예순일곱째가 만든 칸 넷이 아직 있는가** — 뒷걸음 방지
say ""
say "── 2-ㄱ-3. 🔴 **예순일곱째가 만든 칸 넷이 아직 있는가** (뒷걸음 방지)"
say "🔴 **뜻은 73번 그대로입니다** — 「늘 있어야」 ✓ 입니다(71번에서는 단계로 갈렸습니다)."
say "🔴🔴 **이번 판은 칸을 하나도 안 더합니다** — enum 값 하나를 더할 뿐입니다."
say "   그래서 「이번 판이 만드는 칸」 표가 **따로 없고**, 그 자리를 **2-ㄱ-4** 가 맡습니다."
say "🔴 **절을 지우지 않았습니다** — 지우면 DB 가 되감긴 날 아무도 못 잡습니다."
say "🔴 **「있는가」만 보지 않습니다** — 자료형과 NULL 허용까지 봅니다."
NC_SEEN=0; NC_HAVE=0; NC_SHAPE=0
while IFS='|' read -r BOX DB T C TY NU MSG; do
  [ -n "${BOX:-}" ] || continue
  NC_SEEN=$((NC_SEEN+1))
  n=$(has_column "$BOX" "$DB" "$T" "$C")
  ty=""; nu=""
  if [ "${n:-0}" = "1" ]; then
    ty=$(col_type "$BOX" "$DB" "$T" "$C")
    nu=$(col_null "$BOX" "$DB" "$T" "$C")
  fi
  printf '      %-30s.%-26s 있나 %-3s · 자료형 %-26s (기대 %s) · NULL %s (기대 %s)\n' \
    "$T" "$C" "${n:-?}" "${ty:-–}" "$TY" "${nu:-–}" "$NU"
  printf '        %s\n' "$MSG"
  if [ "${n:-0}" = "1" ]; then
    NC_HAVE=$((NC_HAVE+1))
    # 🔵 col_type 은 공백을 걷어낸 값으로 돌아온다(pgq 가 tr -d ' ' 를 한다) —
    #    기대값도 같은 꼴로 맞댄다.
    TYC=$(printf '%s' "$TY" | tr -d ' ')
    if [ "${ty:-x}" = "$TYC" ] && [ "${nu:-x}" = "$NU" ]; then NC_SHAPE=$((NC_SHAPE+1)); fi
  fi
done <<ENDNC
$(rows_of "$NEWCOLS")
ENDNC
say "본 칸 ${NC_SEEN} · 있는 칸 ${NC_HAVE} · 꼴까지 맞는 칸 ${NC_SHAPE} (표의 수 $NEWCOLS_WANT)"
if [ "$NC_SEEN" != "$NEWCOLS_WANT" ]; then
  bad "칸을 ${NC_SEEN}개만 봤다 — ${NEWCOLS_WANT}개를 기대했다. NEWCOLS 표가 깨졌다"
elif [ "$NC_HAVE" != "$NEWCOLS_WANT" ]; then
  bad "칸이 ${NC_HAVE}/${NEWCOLS_WANT} 개다 — 🔴 **예순일곱째가 올린 칸이 사라졌다.** 멈추고 알릴 것"
  say "      🔴 그 칸이 없으면 [납기일 확정]과 노드의 「관련 파일」이 **42703 으로 터집니다.**"
  doubt
elif [ "$NC_SHAPE" = "$NEWCOLS_WANT" ]; then
  ok "그 칸 넷이 **적어 둔 꼴 그대로 있다** (0132·0133 이 적은 그대로다)"
else
  bad "칸은 넷 다 있는데 꼴이 맞는 것이 ${NC_SHAPE}개다 — **같은 이름의 다른 칸**이 섞였다"
  say "      🔴 누가 손으로 만들었을 수 있습니다."
  doubt
fi
# 🔴 **잣대가 살아 있는가** — 없는 칸을 물어 0 이 나오는지 본다.
NCP=$(has_column dss-pg-app dss_as domestic_order_due_dates "__dss_probe_no_such_column__")
printf '      없는 칸을 물었을 때: %s (기대 0)\n' "${NCP:-?}"
[ "${NCP:-x}" = "0" ] && ok "칸을 묻는 잣대가 **살아 있다** (위 값을 믿을 수 있다)" \
  || bad "없는 칸을 물었는데 ${NCP:-?} 가 나왔다 — **「무조건 있다」인 검사다.** 위 값도 못 믿는다"

# 2-ㄱ-4. 🔴🔴 **이번 판이 만드는 것 — enum 에 값 하나** (단계로 갈린다)
say ""
say "── 2-ㄱ-4. 🔴🔴 **enum 에 ${ENUM_VALUE} 가 있는가** — 적용 전 **없다(0)** · 뒤 **있다(1)**"
say "🔴 **이 절이 이번에 생겼습니다** — 73번은 DB 를 한 글자도 안 바꿨습니다."
say "🔵 **테이블 자료가 아니라 형(enum)의 정의**를 봅니다(pg_enum) — 0134 가 하는 일이"
say "   그것 하나입니다: ALTER TYPE \"public\".\"$ENUM_NAME\" ADD VALUE '$ENUM_VALUE' BEFORE '$ENUM_BEFORE';"
say "🔵 **같은 줄에서 반대쪽도 셉니다** — ${ENUM_BEFORE} 는 **늘 1**(그 값이 사라지면 다른 사고입니다)."
say "🔴 **라벨 총수도 셉니다**(적용 전 $ENUM_LABELS_WAS · 뒤 $ENUM_LABELS_WANT) — 「있는가」만 재면"
say "   **엉뚱한 라벨이 섞여 들어온 판**을 못 가릅니다."
eh=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_HAS_SQL")
eb=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_BEFORE_SQL")
ec=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_COUNT_SQL")
eo=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_ORDER_SQL")
printf '      %s 에 [%s] 가 있나: %s · [%s] 가 있나: %s (기대 1)\n' \
  "$ENUM_NAME" "$ENUM_VALUE" "${eh:-?}" "$ENUM_BEFORE" "${eb:-?}"
printf '      라벨 총수: %s (적용 전 %s · 뒤 %s) · [%s] 가 [%s] 보다 앞인가: %s (적용 뒤 기대 1)\n' \
  "${ec:-?}" "$ENUM_LABELS_WAS" "$ENUM_LABELS_WANT" "$ENUM_VALUE" "$ENUM_BEFORE" "${eo:-?}"
if [ -z "${eh:-}" ] || [ -z "${eb:-}" ] || [ -z "${ec:-}" ]; then
  unk "enum 의 라벨" "못 쟀다 — $ENUM_BOX 가 도는지, $ENUM_DB 가 있는지 보세요"
else
  if [ "${eb}" != "1" ]; then
    bad "[$ENUM_BEFORE] 가 ${eb} 다 — 1 을 기대했다. 🔴 **엉뚱한 형을 보고 있거나 라벨이 사라졌다**"
    doubt
  else
    ok "[$ENUM_BEFORE] 가 그대로 있다 (보고 있는 형이 맞다)"
  fi
  case "$DBPHASE" in
    TODO)
      if [ "${eh}" = "0" ] && [ "${ec}" = "$ENUM_LABELS_WAS" ]; then
        ok "[$ENUM_VALUE] 가 **아직 없고** 라벨이 ${ENUM_LABELS_WAS}개다 (적용 전이라 맞다)"
      else
        hm "적용 전인데 [$ENUM_VALUE] 가 ${eh} 이고 라벨이 ${ec}개입니다 — 0 · $ENUM_LABELS_WAS 을 기대했습니다"
        say "      🔴 **1 이면 누가 다른 길로 올린 것**입니다. 사람이 보세요."
      fi ;;
    DONE)
      if [ "${eh}" = "1" ] && [ "${ec}" = "$ENUM_LABELS_WANT" ]; then
        ok "[$ENUM_VALUE] 가 **생겼고** 라벨이 ${ENUM_LABELS_WANT}개다 (**이 배포의 목적물이다**)"
      else
        bad "적용이 끝났다는데 [$ENUM_VALUE] 가 ${eh} 이고 라벨이 ${ec}개다 — 1 · $ENUM_LABELS_WANT 을 기대했다"
        say "      🔴 **수는 늘었는데 값이 없다면 db:migrate 가 오류를 삼킨 것**입니다. 멈추고 알릴 것."
        doubt
      fi
      if [ "${eo:-x}" = "1" ]; then
        ok "[$ENUM_VALUE] 가 [$ENUM_BEFORE] 보다 **앞이다** (BEFORE 가 들었다 — 화면의 분류 차례가 맞다)"
      else
        hm "[$ENUM_VALUE] 가 [$ENUM_BEFORE] 보다 앞이 **아닙니다**(${eo:-?}) — 🔴 화면의 분류 차례가 달라집니다"
        say "      🔵 ✗ 는 안 냅니다 — 자료는 멀쩡하고 **보이는 차례만** 다릅니다. 사람이 보세요."
      fi ;;
    *) say "(단계를 못 가려 판정하지 않습니다 — 값만 찍습니다)" ;;
  esac
fi
# 🔴 **잣대가 살아 있는가** — 없는 라벨을 물어 0 이 나오는지 본다.
n=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_PROBE_SQL")
printf '      없는 라벨을 물었을 때: %s (기대 0)\n' "${n:-?}"
[ "${n:-x}" = "0" ] && ok "enum 라벨을 세는 잣대가 **살아 있다** (위 값을 믿을 수 있다)" \
  || bad "없는 라벨을 물었는데 ${n:-?} 가 나왔다 — **질의가 깨졌다.** 위 값도 못 믿는다"

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
  printf '      %-14s %-34s 있나 %-3s 줄 %s\n' "$NAME" "$T" "${n:-?}" "${rows:-–}"
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
say "🔴 표 이름이 **셋으로 다릅니다** — 하나로 묻는 검사였으면 세 집이 ✗ 였습니다."

# 2-ㄷ. 🔴 A/S 마이그레이션 볼륨 — **134 → 135장** (단계로 갈린다)
say ""
say "── 2-ㄷ. 🔴 A/S 마이그레이션 **볼륨** — ${AS_VOL_SQL_WAS}장인가 ${AS_VOL_SQL_WANT}장인가"
say "🔴 **A/S 만 볼륨에서 돕니다.** 도구 이미지의 /app/drizzle 은 비어 있고 그 자리에"
say "   이 폴더가 붙습니다 — 그래서 묶음을 풀어야 ${AS_VOL_SQL_WAS} → ${AS_VOL_SQL_WANT} 가 됩니다."
say "🔴 **이미지 안만 세면 적용이 0건으로 조용히 끝납니다**(31·39번이 겪었습니다)."
say "🔵 **재고는 반대입니다** — .sql 이 이미지 안에 있습니다. 2-ㄷ-2 가 **따로** 셉니다."
VOL_SEEN=0; VOLPHASE=ODD
if [ -d "$MIGDIR" ]; then
  VOL_SEEN=$((VOL_SEEN+1))
  vs=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  vj=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  vnx=$(ls -1 "$MIGDIR/${AS_VOL_NEXT}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  vth=0; vthseen=0
  for t in $AS_VOL_NEW; do
    vthseen=$((vthseen+1))
    a=$(ls -1 "$MIGDIR/${t}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
    b=$(ls -1 "$MIGDIR/meta/${t}"_snapshot.json 2>/dev/null | wc -l | tr -d ' ')
    printf '      볼륨 안의 %-6s .sql %s개 · 스냅샷 %s개\n' "$t" "${a:-0}" "${b:-0}"
    [ "${a:-0}" = "1" ] && [ "${b:-0}" = "1" ] && vth=$((vth+1))
  done
  printf '      볼륨 %s — .sql %s장 · journal idx %s개 · 이번 장 %s/%s · %s %s개(기대 0)\n' \
    "$MIGDIR" "${vs:-?}" "${vj:-?}" "$vth" "$AS_VOL_NEW_WANT" "$AS_VOL_NEXT" "${vnx:-?}"
  if [ "${vthseen}" != "$AS_VOL_NEW_WANT" ]; then
    bad "볼륨에서 이번 장을 ${vthseen}개만 봤다 — ${AS_VOL_NEW_WANT}개를 기대했다"
  fi
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
    say "      🔴 **132·133 이면 옛 판의 묶음을 푼 것**입니다 — 3-ㄴ 의 지문을 보세요."
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
    TODO) [ "${vth:-1}" = "0" ] && ok "볼륨에 이번 장이 아직 없다 (적용 전이라 맞다)" \
            || hm "볼륨이 ${AS_VOL_SQL_WAS}장인데 이번 장이 ${vth}개 있습니다 — 사람이 보세요" ;;
    DONE) [ "${vth:-0}" = "$AS_VOL_NEW_WANT" ] && ok "볼륨에 $AS_VOL_NEW 이 **.sql·스냅샷 짝으로 들어왔다** (이 배포의 목적물이다)" \
            || bad "볼륨이 ${AS_VOL_SQL_WANT}장인데 이번 장이 ${vth}/${AS_VOL_NEW_WANT} 개다 — **엉뚱한 묶음을 풀었다**" ;;
    *)    say "(단계를 못 가려 이번 장은 판정하지 않습니다)" ;;
  esac
  [ "${vnx:-1}" = "0" ] && ok "볼륨에 $AS_VOL_NEXT 이 없다 (마지막이 $AS_VOL_LAST 까지다)" \
    || bad "볼륨에 $AS_VOL_NEXT 이 **있다** — 이 배포본은 $AS_VOL_LAST 까지를 전제로 쓰였다. 멈추고 알릴 것"
  # 🔴 A/S 도구 이미지 안은 **비어 있어야** 한다 — 볼륨이 붙는 자리다.
  AST=$(svc_image tools-as)
  if [ -n "${AST:-}" ] && "$DOCKER" image inspect "$AST" >/dev/null 2>&1; then
    n=$(dock "$AST" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
    printf '      A/S 도구 이미지(%s) 안 %s 의 .sql: %s개 (기대 0 — 볼륨이 안 붙은 맨 이미지다)\n' "$AST" "$IMG_MIGDIR" "${n:-?}"
    if isnum "${n:-}" && [ "${n:-1}" = "0" ]; then ok "A/S 도구 이미지 안 drizzle/ 이 비어 있다 (🔴 그래서 **묶음을 풀어야** 한다)"
    else bad "A/S 도구 이미지 안에 .sql 이 ${n:-?}장 있다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다"; fi
  else
    unk "A/S 도구 이미지 안" "${AST:-태그를 못 읽음} 가 NAS 에 아직 없다 (--preload 전이면 정상)"
  fi
else
  bad "A/S 마이그레이션 볼륨이 없다 — $MIGDIR"
fi
[ "$VOL_SEEN" = "1" ] && ok "볼륨을 봤다" || bad "볼륨을 못 봤다"

# 2-ㄷ-2. 🔵 **재고 마이그레이션은 이미지 안에서 돈다** — A/S 와 정반대 (뒷걸음)
#   🔴 **73번에서 그대로 가져왔다.** 🔵 그 집은 이번에 **안 올라간다** — 그래도
#      **운영의 compose 가 가리키는 어제 올린 도구 이미지**를 열어 센다.
#   🔴 **빼지 마라** — 그 기능이 어제 올라가 운영에서 돌고 있다. 「이번 범위 밖이니
#      지운다」가 틀린다.
say ""
say "── 2-ㄷ-2. 🔵 **재고 마이그레이션은 이미지 안**에 있다 (A/S 와 **정반대** · 뒷걸음)"
say "🔴 **재고는 볼륨이 없습니다** — .sql 이 도구 이미지에 **구워져** 갑니다."
say "   그래서 여기 기대값이 **${INV_IMG_SQL_WANT}장**입니다(A/S 는 **0장**)."
say "🔵 **그 집은 이번에 안 올라갑니다** — 이 절은 **뒷걸음**을 보는 자리입니다."
say "   🔴 **빼지 마세요** — 어제 올라간 기능이 운영에서 돌고 있습니다."
say "🔴🔴 **「없는가」만 재면 번호가 빗나가도 통과합니다** — ${INV_IMG_LAST} 이 아직 있는지"
say "   **같은 줄에서** 함께 셉니다."
IVT=$(svc_image tools-inventory)
if [ -n "${IVT:-}" ] && "$DOCKER" image inspect "$IVT" >/dev/null 2>&1; then
  n=$(dock "$IVT" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
  j=$(dock "$IVT" -c "grep -c 'idx' $IMG_MIGDIR/meta/_journal.json 2>/dev/null"); j=$(printf '%s' "$j" | tr -d ' ')
  lt=$(dock "$IVT" -c "ls $IMG_MIGDIR/${INV_IMG_LAST}_*.sql 2>/dev/null | wc -l"); lt=$(printf '%s' "$lt" | tr -d ' ')
  nx=$(dock "$IVT" -c "ls $IMG_MIGDIR/${INV_IMG_NEXT}_*.sql 2>/dev/null | wc -l"); nx=$(printf '%s' "$nx" | tr -d ' ')
  printf '      재고 도구 이미지(%s) 안 %s — .sql %s장(기대 %s) · idx %s개(기대 %s) · %s %s개(기대 1) · %s %s개(기대 0)\n' \
    "$IVT" "$IMG_MIGDIR" "${n:-?}" "$INV_IMG_SQL_WANT" "${j:-?}" "$INV_IMG_SQL_WANT" \
    "$INV_IMG_LAST" "${lt:-?}" "$INV_IMG_NEXT" "${nx:-?}"
  if [ "${n:-x}" = "$INV_IMG_SQL_WANT" ] && [ "${j:-x}" = "$INV_IMG_SQL_WANT" ]; then
    ok "재고 도구 이미지 안이 **${INV_IMG_SQL_WANT}장**이고 목록도 ${INV_IMG_SQL_WANT}개다 (어제 올린 자리 그대로)"
  else
    bad "재고 도구 이미지 안이 .sql ${n:-?} · idx ${j:-?} 다 — ${INV_IMG_SQL_WANT} 을 기대했다"
    say "      🔴 **A/S 판을 베껴 0 을 기대하지 마세요** — 재고는 **이미지가 정본**입니다."
    doubt
  fi
  if [ "${lt:-0}" = "1" ] && [ "${nx:-1}" = "0" ]; then
    ok "이미지 안 마지막이 $INV_IMG_LAST 이고 $INV_IMG_NEXT 은 없다 (예순다섯째가 올린 자리 그대로)"
  elif [ "${nx:-1}" != "0" ]; then
    bad "이미지 안에 $INV_IMG_NEXT 이 **있다** — 이 배포본은 $INV_IMG_LAST 까지를 전제로 쓰였다. 멈추고 알릴 것"
  else
    bad "이미지 안에 $INV_IMG_LAST 이 ${lt:-?}개다 — 1 을 기대했다. 🔴 **번호 잣대가 빗나가 있다**"
    doubt
  fi
else
  unk "재고 도구 이미지 안" "${IVT:-태그를 못 읽음} 가 NAS 에 없다"
fi


# ══════════════════════════════════════════════════════════════════════
# ── 3. 들여올 tar **둘** + 🔴 **묶음 하나** ──────────────────────────
# ══════════════════════════════════════════════════════════════════════
step "3. 들여올 tar 둘 + 🔴 **묶음 하나** — **옮기다 깨졌는가**"
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
      *) bad "$T 의 지문이 TARS 표에 **비어 있다** — 굽기 꼬리말의 네 줄을 채우세요" ;;
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
  say "   74-build.sh --go 가 꼬리말에 찍어 주는 **두 줄**을 이 파일의 TARS 에 그대로"
  say "   붙여 넣은 **뒤에** scp 하세요. 쉰세째에는 빈 표가 그대로 올라가 --preload 가"
  say "   ✗ 둘로 멈췄습니다."
fi

# 3-ㄴ. 🔴🔴 **묶음** — A/S 전용. 71-deploy.sh:1296-1394 에서 되살렸다.
say ""
say "── 3-ㄴ. 🔴🔴 A/S 마이그레이션 묶음 (A/S 만 그렇다)"
say "🔴 **73·72·70·69·68·67 에는 이 절이 없었습니다**(묶음이 없었습니다). 71번에서"
say "   가져왔습니다 — 🔴 **place_migs() 와 MIGTAR_SIZE·MIGTAR_MD5 와 한 벌**입니다."
say "🔵 **재고 쪽 묶음은 없습니다** — 그 집은 .sql 이 도구 이미지 안에서 돕니다."
if [ -f "$MIGTAR" ]; then
  sz=$(stat -c %s "$MIGTAR" 2>/dev/null); m5=$(md5sum "$MIGTAR" 2>/dev/null | awk '{print $1}')
  printf '      as-migrations.tar.gz %s바이트 md5 %s\n' "${sz:-?}" "${m5:-?}"
  # 🔴🔴 **먼저 옛 묶음과 가른다** — 지문이 유일한 길이다(이름이 같다).
  printf '      옛 묶음(2026-11-25 · 134장) %s바이트 md5 %s\n' "$OLD_MIGTAR_SIZE" "$OLD_MIGTAR_MD5"
  if [ "${m5:-x}" = "$OLD_MIGTAR_MD5" ]; then
    case "$MODE" in
      --check|--count|--rollback)
        hm "🔴 **지금 거기 있는 것은 2026-11-25 의 묶음입니다**(134장) — 아직 안 보내셨습니다" ;;
      *)  bad "🔴🔴 **옛 묶음(2026-11-25 · 134장)이 그대로 있다** — 이번 것을 안 보냈다. 보내세요"
          say "      scp -O as-migrations.tar.gz dss-nas:$INCOMING/" ;;
    esac
  else
    ok "묶음이 **옛 것과 md5 가 다르다** (2026-11-25 의 것이 아니다)"
  fi
  if [ -z "${MIGTAR_SIZE:-}" ] || [ -z "${MIGTAR_MD5:-}" ]; then
    case "$MODE" in
      --check|--count|--rollback) unk "묶음의 지문" "MIGTAR_SIZE·MIGTAR_MD5 가 비어 있다 — 굽고 나서 채우세요" ;;
      *) bad "묶음의 지문이 **비어 있다** — 굽기 꼬리말의 두 줄을 채우세요" ;;
    esac
  elif [ "${sz:-x}" = "$MIGTAR_SIZE" ] && [ "${m5:-x}" = "$MIGTAR_MD5" ]; then
    ok "묶음의 크기와 md5 가 구울 때와 같다"
  else
    bad "묶음이 다르다 — 크기 ${sz:-?} (기대 $MIGTAR_SIZE) · md5 ${m5:-?} (기대 $MIGTAR_MD5)"
    say "      🔴 **옛 판의 묶음이거나 옮기다 깨진 것입니다** — _images-58 … _images-73 에"
    say "         128·129·131·132·134장짜리가 있습니다. 쉰여섯째·쉰일곱째가 **두 판 연속**"
    say "         그것을 보냈습니다."
  fi
  # 🔴 묶음 **안을 세어서** 본다 — tar | grep -q 는 SIGPIPE 로 거짓이 된다(함정 ②).
  INSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE '^drizzle/[0-9]{4}_.*[.]sql$' || true)
  INJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
  INNEXT=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${AS_VOL_NEXT}_.*[.]sql" || true)
  INTHIS=0; INSEEN=0
  for t in $AS_VOL_NEW; do
    INSEEN=$((INSEEN+1))
    a=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${t}_.*[.]sql" || true)
    b=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/meta/${t}_snapshot[.]json" || true)
    printf '      묶음 안의 %-6s .sql %s · 스냅샷 %s (기대 1 · 1)\n' "$t" "${a:-?}" "${b:-?}"
    [ "${a:-0}" = "1" ] && [ "${b:-0}" = "1" ] && INTHIS=$((INTHIS+1))
  done
  printf '      묶음 안 — .sql %s장 · idx %s개 · 이번 장 %s/%s · %s %s개(기대 0)\n' \
    "${INSQL:-?}" "${INJRN:-?}" "$INTHIS" "$AS_VOL_NEW_WANT" "$AS_VOL_NEXT" "${INNEXT:-?}"
  printf '      (기대 %s · %s · %s · 0)\n' "$AS_VOL_SQL_WANT" "$AS_VOL_SQL_WANT" "$AS_VOL_NEW_WANT"
  if [ "$INSEEN" != "$AS_VOL_NEW_WANT" ]; then
    bad "묶음에서 이번 장을 ${INSEEN}개만 봤다 — ${AS_VOL_NEW_WANT}개를 기대했다"
  fi
  if [ "${INSQL:-x}" = "$AS_VOL_SQL_WANT" ] && [ "${INJRN:-x}" = "$AS_VOL_SQL_WANT" ] \
     && [ "${INTHIS:-0}" = "$AS_VOL_NEW_WANT" ] && [ "${INNEXT:-1}" = "0" ]; then
    ok "묶음 안이 ${AS_VOL_SQL_WANT}장이고 $AS_VOL_NEW 이 .sql·스냅샷 짝으로 있다"
  else
    case "$MODE" in
      --check|--count|--rollback) hm "묶음 안이 기대와 다릅니다 — 보내기 전이면 정상일 수 있습니다" ;;
      *) bad "묶음 안이 기대와 다르다 — **보내지 마세요**"
         say "      🔴 목록에 없는 .sql 은 drizzle 이 **아예 모르고**, 적용이 0건으로 조용히 끝납니다."
         say "      🔴 **134 가 나오면 2026-11-25 의 묶음**입니다(위 md5 를 보세요)." ;;
    esac
  fi
  # 🔴 묶음 안의 장에 지우는 문장이 없는가 — **잣대를 표본으로 먼저 잰다.**
  #    🔴 **표본이 넷이다**(71번은 셋) — 0134 의 실물인 ADD VALUE 를 안 세는지 못 박았다.
  pn=$(printf 'DROP TABLE "x";\n' | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
  pa=$(printf 'ALTER TABLE "x" ADD COLUMN "y" text;\n' | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
  po=$(printf 'REFERENCES "u"("id") ON DELETE restrict\n' | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
  pv=$(printf 'ALTER TYPE "p"."c" ADD VALUE (quote)D(quote) BEFORE (quote)O(quote);\n' | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
  printf '      잣대 표본 넷 — DROP TABLE 을 잡나 %s(기대 1 이상) · ADD COLUMN 을 안 세나 %s(기대 0) · ON DELETE 를 안 세나 %s(기대 0) · ADD VALUE 를 안 세나 %s(기대 0)\n' \
    "${pn:-?}" "${pa:-?}" "${po:-?}" "${pv:-?}"
  if [ "${pn:-0}" -ge 1 ] 2>/dev/null && [ "${pa:-1}" = "0" ] && [ "${po:-1}" = "0" ] && [ "${pv:-1}" = "0" ]; then
    ok "지우는 문장 잣대가 **살아 있다** (아래 0줄이 아무것도 안 재는 ✓ 가 아니다)"
    say "      🔴 **넷째 표본이 이번에 늘었습니다** — 0134 의 실물이 ADD VALUE 입니다."
    say "         🔵 작은따옴표는 (quote) 로 적었습니다 — 잣대가 보는 것은 DROP/TRUNCATE/"
    say "            DELETE FROM 뿐이라 판정이 안 달라집니다."
    MIGSH_SEEN=0; MIGSH_OK=0
    for t in $AS_VOL_NEW; do
      MIGSH_SEEN=$((MIGSH_SEEN+1))
      NM=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -E "^drizzle/${t}_.*[.]sql" | head -1)
      if [ -z "${NM:-}" ]; then hm "묶음 안의 $t 을 못 읽었다"; continue; fi
      TB=$(tar -xzOf "$MIGTAR" "$NM" 2>/dev/null)
      net=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -ciE "$DESTRUCTIVE_RE" || true)
      ins=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'INSERT INTO' || true)
      upd=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'UPDATE ' || true)
      ct=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'CREATE TABLE' || true)
      ac=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'ADD COLUMN' || true)
      av=$(printf '%s\n' "$TB" | grep -v "$SQL_COMMENT_RE" | grep -c 'ADD VALUE' || true)
      rn=$(printf '%s\n' "$TB" | grep -ciE 'RENAME' || true)
      en=$(printf '%s\n' "$TB" | grep -cF "$ENUM_NAME" || true)
      ev=$(printf '%s\n' "$TB" | grep -cF "$ENUM_VALUE" || true)
      printf '        %s — 지우는 문장 %s줄(기대 0) · ADD VALUE %s(기대 1 이상) · ADD COLUMN %s(기대 0)\n' \
        "$t" "${net:-?}" "${av:-?}" "${ac:-?}"
      printf '        %s — INSERT %s(기대 0) · UPDATE %s(기대 0) · CREATE TABLE %s(기대 0) · RENAME %s(기대 0) · enum 이름 %s · 값 %s\n' \
        "$t" "${ins:-?}" "${upd:-?}" "${ct:-?}" "${rn:-?}" "${en:-?}" "${ev:-?}"
      if [ "${net:-x}" = "0" ] && [ "${ins:-1}" = "0" ] && [ "${upd:-1}" = "0" ] \
         && [ "${ct:-1}" = "0" ] && [ "${rn:-1}" = "0" ] \
         && [ "${av:-0}" -ge 1 ] 2>/dev/null && [ "${ac:-1}" = "0" ] \
         && [ "${en:-0}" -ge 1 ] 2>/dev/null && [ "${ev:-0}" -ge 1 ] 2>/dev/null; then
        MIGSH_OK=$((MIGSH_OK+1))
      else
        bad "$t 이 기대와 다르다 — 지우는 문장 ${net:-?} · INSERT ${ins:-?} · UPDATE ${upd:-?} · CREATE TABLE ${ct:-?} · RENAME ${rn:-?} · ADD VALUE ${av:-?} · ADD COLUMN ${ac:-?}"
        say "      🔴 **71번은 여기가 「ADD COLUMN 이 1줄 이상」이었습니다** — 그대로 베끼면"
        say "         **멀쩡한 마이그레이션이 ✗** 입니다. 이 판의 과녁은 **ADD VALUE** 이고"
        say "         **ADD COLUMN 은 0** 입니다(두 쪽을 같은 줄에서 셉니다)."
        say "      🔴 **UPDATE 나 INSERT 가 0 이 아니면 멈추세요** — 같은 트랜잭션에서 새"
        say "         enum 값을 쓰는 판이고, 그러면 **쪼개도 안 넘어갑니다.**"
        doubt
      fi
    done
    say "본 장 ${MIGSH_SEEN} · 온전한 장 ${MIGSH_OK} (기대 $AS_VOL_NEW_WANT · $AS_VOL_NEW_WANT)"
    [ "$MIGSH_SEEN" = "$AS_VOL_NEW_WANT" ] && [ "$MIGSH_OK" = "$AS_VOL_NEW_WANT" ] \
      && ok "그 장이 **enum 값을 더하기만 한다** (자료를 안 건드린다 · 칸도 안 더한다)" \
      || bad "본 장 ${MIGSH_SEEN} · 온전한 장 ${MIGSH_OK} 다 — $AS_VOL_NEW_WANT 을 기대했다"
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
say "🔴 **이번 판도 PO 가 모르는 것을 하나 늘립니다 — 일곱이 됩니다**(머리말)."
say "   🔴 **PO 의 vendor/dss-core 는 ${ENUM_NAME} 의 ${ENUM_VALUE} 를 모릅니다.**"
say "   🔵 **칸을 더한 것이 아니라 enum 에 값을 더한 것**이라 모르는 쪽이 당장"
say "      깨지지는 않습니다 — PO 는 그 분류로 저장하지 않습니다."
say "      🔴 다만 PO 가 첨부를 **읽는** 자리에서 그 값을 만나면 **타입 밖의 값**입니다."
say "   🔵 **칸은 하나도 안 늘었습니다** — 이번 판이 바꾸는 것은 enum 하나뿐입니다."
say "   🔴 **PO 를 다시 여는 날 일곱을 한 묶음으로 이식하세요.**"
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
#   🔴 **이 배포는 자료를 한 글자도 안 바꾸고 칸도 하나도 안 더한다.**
#      🔴🔴 **딱 하나만 달라진다 — ㉑(enum 에 DATA 가 있는가)**: 적용 전 **0** · 뒤 **1**.
#      그 밖은 **전과 후가 같아야** 한다. 🔵 73번은 그 하나조차 없었다(0건이었다).
#   🔵 **⓪~⑦ 은 70→71→72→73 을 거쳐 온 것 그대로다. 하나도 안 뺐다.**
#      🔴 ⓪·⓪-2·⑥·⑦ 은 **지난 판들이 올린 것을 보는 자리**다 — 「이번 범위 밖이니
#      지운다」고 착각하기 쉬운데, 지난 판들이 **「한 번 빼면 다시 넣는 사람이
#      없다」**고 반복해 적어 두었다.
#   🔵 **71번 고유였던 ⑧·⑨·⑩ 도 남겼다** — 이제 그 셋도 **지난 판이 올린 것을
#      보는 자리**다(확정 두 칸 · 기타건 납기 임박 · 노드 파일 자리).
#   🔵 **72번 고유였던 ⑪·⑫·⑬ 도 남겼다** — 이제 그 셋도 **어제 올린 것이 아직
#      도는가**를 보는 자리다(확정+완료 회차 · [수리 대기] 단계 · 납품 요청일 빌리기).
#      🔴 「이번 범위 밖이니 지운다」고 착각하기 쉬운 자리가 **이제 여덟**이다.
#   🔴 **73번 고유 여섯(⑭~⑲)도 남겼다** — 전부 **재고 쪽**이다. 🔴 그 집은 이번에
#      **안 올라가지만** 그 기능이 **어제 올라가 운영에서 돌고 있어** 뒷걸음을 봐야 한다.
#      🔴 「이번 범위 밖이니 지운다」고 착각하기 가장 쉬운 자리가 바로 여기다.
#   🔴 **74번 고유 둘(⑳·㉑)을 그 뒤에 넣었다** — ⑳ 은 **전후 둘 다 0** 이 정상이고,
#      ㉑ 은 **적용 전과 뒤가 뒤집히는 유일한 자리**다.
#   🔴 **GROUP BY 1 을 쓰지 않는다.** 62번이 그것 때문에 질의 둘이 통째로 거절돼
#      **✓ 를 띄운 채 속이 비어** 있었다. 🔵 ⑭ 는 **group by status** 로 적었다.
#   🔴 표·칸 이름은 전부 **스키마에서 확인한 것**이다(A/S 쪽은 vendor/dss-core 의
#      domestic-order-due-dates.ts · procedure-template-nodes.ts ·
#      repair-case-flowchart-nodes.ts · workflow.ts · repair-cases.ts,
#      재고 쪽은 dss-inventory/src/db/schema/stock-requests.ts · stock.ts).
#      지어내지 않았다.
effect_counts() {
  step "🔢 이 배포가 **보여 주는 것**이 달라지는 자리 — 세기만 한다 (전부 select)"
  say "🔵 이 배포는 자료를 한 글자도 안 바꾸고 **칸도 하나도 안 더합니다.**"
  say "   🔴🔴 **딱 하나만 바뀝니다 — ㉑(enum 에 ${ENUM_VALUE} 가 있는가)**: 적용 전 **0** · 뒤 **1**."
  say "   그 밖은 **전과 후의 수가 전부 같아야 정상**입니다."
  say "   🔴 **올린 뒤에 늘 수 있는 것이 셋입니다** — ⑭(반환 신청) · ⑯(반환 완료) ·"
  say "      **⑳(${ENUM_VALUE} 분류 첨부)**. 사람이 그것을 쓰기 시작하는 순간부터이고,"
  say "      **그것이 이 기능들이 도는 증거**입니다."
  say "🔵 아래 괄호의 「참고」는 **2026-11-19 예순한째 배포 뒤 운영 실측**입니다 —"
  say "   🔴 **✗ 를 내는 기대값이 아닙니다.** ✗ 를 내는 것은 **②-ㄴ 의 관문 둘**과"
  say "   **잣대 검사들**(없는 값으로 물어 0 이 나오는가)뿐입니다."

  local t live done_ undone noorder issued issued_any both cust nocust
  local nc tagged distinct flows prow rowdone n qlive qprobe
  local ca cb half misc near silenced nrow ncol npt
  # 🔵 72번 고유 셋(⑪·⑫·⑬)이 쓰는 것
  local cdone adone wrc wrs wrv bo bp
  # 🔵 73번 고유 여섯(⑭~⑲)이 쓰는 것 — 🔴 **하나도 안 뺐다**(뒷걸음을 본다)
  local rall rpend rdone uall rcase rline rwide ic ren reti rett
  # 🔵 74번 고유 둘(⑳·㉑)이 쓰는 것
  local adata adataall alive eh2 eb2 ec2 eo2

  # ── ⓪ 🔵 고장 개소 태그 — **66번이 더한 절. 그대로 둔다.**
  say ""
  say "── ⓪ 🔵 **고장 개소 태그** — 예순두째가 올린 것 (이 배포와 무관하게 센다)"
  say "🔴 **칸이 있는지 먼저 묻습니다** — 없는데 질의를 던지면 42703(칸 없음)으로"
  say "   거절되고, 그 빈 결과가 **진짜 결함처럼** 보입니다."
  say "🔵 이 절은 **✗ 를 한 번도 안 냅니다.**"
  flows=$(pgn "$FAULT_BOX" "$FAULT_DB" "select count(*) from $FAULT_TABLE where is_deleted = false")
  nc=$(has_column "$FAULT_BOX" "$FAULT_DB" "$FAULT_TABLE" "$FAULT_COL")
  printf '      %s 휴지통 밖 %s줄 · %s 칸이 있나 %s (기대 1 — 예순두째가 올렸다)\n' \
    "$FAULT_TABLE" "${flows:-?}" "$FAULT_COL" "${nc:-?}"
  if [ -z "${nc:-}" ]; then
    unk "$FAULT_COL 칸" "못 쟀다 — $FAULT_BOX 가 도는지 보세요"
  elif [ "$nc" != "1" ]; then
    hm "**그 칸이 없습니다** — 🔴 예순두째 배포가 안 끝났거나 되돌려졌습니다. 사람이 보세요"
  else
    tagged=$(pgn "$FAULT_BOX" "$FAULT_DB" "select count(*) from $FAULT_TABLE where is_deleted = false and $FAULT_COL is not null and jsonb_array_length($FAULT_COL) > 0")
    distinct=$(pgn "$FAULT_BOX" "$FAULT_DB" "select count(distinct t) from $FAULT_TABLE f, lateral jsonb_array_elements_text(f.$FAULT_COL) as t where f.is_deleted = false")
    printf '      태그가 달린 Flowchart %s개 (참고 %s) · 서로 다른 태그 %s가지 (참고 %s)\n' \
      "${tagged:-?}" "$CNT_TAGGED_REF" "${distinct:-?}" "$CNT_DISTINCT_TAGS_REF"
    if [ -z "${tagged:-}" ] || [ -z "${distinct:-}" ]; then
      hm "둘 중 못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
    else
      ok "고장 개소 태그를 값으로 쟀다 (달린 Flowchart ${tagged}개 · 태그 ${distinct}가지)"
    fi
  fi

  # ── ⓪-2 🔵 **예순세째가 올린 것** — 권한이 실제로 어떻게 서는가 (뒷걸음을 본다)
  say ""
  say "── ⓪-2 🔵 **「완료 시 수정」 권한이 아직 기본값으로 도는가** (예순세째가 올린 것)"
  say "🔴 **0행이 정상입니다.** $PERM_TABLE 에 저장된 설정이 없으면 코드의 기본값"
  say "   (최고관리자·관리자 둘)이 **그대로 실효 권한**이 됩니다."
  say "🔴 **0행이 아니면 ⚠️ 로 찍고 그 값을 보여 줍니다** — 저장된 값이 기본값을"
  say "   **이기므로 누가 실제로 막히는지가 달라집니다.** 🔴 ✗ 는 안 냅니다."
  prow=$(pgn "$PERM_BOX" "$PERM_DB" "select count(*) from $PERM_TABLE where area_key like '$PERM_LIKE'")
  printf '      %s 에서 area_key like %s 인 행: %s개 (참고 %s)\n' \
    "$PERM_TABLE" "$PERM_LIKE" "${prow:-?}" "$CNT_PERM_ROWS_REF"
  if [ -z "${prow:-}" ]; then
    unk "$PERM_TABLE 의 domesticOrders 행" "못 쟀다 — $PERM_BOX 가 도는지, 그 표가 있는지 보세요"
  elif [ "${prow}" = "$CNT_PERM_ROWS_REF" ]; then
    ok "그 표에 domesticOrders 행이 **${CNT_PERM_ROWS_REF}개다** (저장된 설정이 없어 **기본값이 곧 운영 동작**이다)"
  else
    hm "그 표에 domesticOrders 행이 **${prow}개 있습니다** — 🔴 **저장된 값이 기본값을 이깁니다**"
    pgrows "$PERM_BOX" "$PERM_DB" "select role || ' | ' || area_key || ' | ' || level from $PERM_TABLE where area_key like '$PERM_LIKE' order by area_key, role" | sed 's/^/        /'
  fi
  # 🔴 **없는 글자를 함께 묻는다** — 「무조건 0」인 질의인지 가른다.
  n=$(pgn "$PERM_BOX" "$PERM_DB" "select count(*) from $PERM_TABLE where area_key like '__dss_probe_no_such_area__%'")
  printf '      없는 열쇠로 물었을 때: %s개 (기대 0)\n' "${n:-?}"
  [ "${n:-x}" = "0" ] && ok "권한 행을 세는 잣대가 **살아 있다** (위 수를 믿을 수 있다)" \
    || bad "없는 열쇠를 물었는데 ${n:-?} 가 나왔다 — **질의가 깨졌다.** 위 수도 못 믿는다"

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
  say "🔵 **예순한째부터 「발주 완료」가 완료된 줄을 뺍니다**(and completed_at is null)."
  say "   🔴 이 배포는 그 질의를 **한 글자도 안 건드립니다** — 그대로 둡니다."
  say "🔴 「발주 대기」는 코드에서 **order_issued_date 가 NULL 인 한 줄** 그대로입니다."
  say "   🔴 **둘은 이제 여집합이 아닙니다** — 날짜 조건만 뒤집음입니다."
  done_=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and completed_at is not null")
  undone=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and completed_at is null")
  noorder=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and order_issued_date is null")
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
  say "🔴 ㄴ) **덮기 관문** — 발주 대기 + 발주 완료 + 완료됨 − (완료됨 ∩ 발주 대기)"
  say "       == 휴지통 밖. [운영 실측 2026-11-19] 9 + 13 + 14 − 0 = **36**."
  say "   🔴 **「발주 대기 + 발주 완료 == 휴지통 밖」은 예순한째부터 거짓입니다.**"
  say "   🔵 그래서 65번이 덮기 관문으로 바꿔 두었고, **그대로 가져왔습니다.**"
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
  printf '      완료됨이면서 발주 대기인 줄 %s개 (참고 %s)\n' "${both:-?}" "$CNT_BOTH_REF"
  if [ -z "${both:-}" ]; then unk "겹치는 줄 수" "못 쟀다"
  elif [ "${both:-0}" -ge 1 ] 2>/dev/null; then
    ok "겹치는 줄이 ${both}개 있다 — 🔴 **거르개가 OR 이라야 맞다는 실물 증거다**"
  else
    ok "겹치는 줄이 0개다 (🔵 지금은 없지만 **생길 수 있습니다**)"
    say "      🔴 **0 이라고 덮기 관문에서 빼는 항을 지우지 마세요** — 그 줄이 하나라도"
    say "         생기는 날 관문이 **까닭 없이 ✗** 가 됩니다."
  fi

  say ""
  say "── ③ 🔴 **고객사 거르개**의 후보 수 (화면은 **올라온 줄에서** 뽑는다)"
  say "🔴 화면의 고객사는 **내자 줄 자신의 고객사**이고, 비어 있으면 **붙어 있는**"
  say "   **수리 건의 고객사**를 빌려 옵니다 — 여기서는 **빌려 오는 쪽까지 이어서** 셉니다."
  cust=$(pgn dss-pg-app dss_as "select count(distinct coalesce(d.customer_id, r.customer_id)) from domestic_orders d left join repair_cases r on r.id = d.repair_case_id where d.is_deleted = false")
  nocust=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders d left join repair_cases r on r.id = d.repair_case_id where d.is_deleted = false and coalesce(d.customer_id, r.customer_id) is null")
  printf '      고객사 가짓수 %s(참고 %s) · 고객사를 못 찾는 줄 %s개(참고 %s · = 드롭다운의 「미지정」)\n' \
    "${cust:-?}" "$CNT_CUST_REF" "${nocust:-?}" "$CNT_NOCUST_REF"
  if [ -z "${cust:-}" ]; then
    unk "고객사 가짓수" "못 쟀다 — 이어 세는 질의가 거절됐을 수 있습니다"
  elif [ "${cust:-0}" -ge 1 ] 2>/dev/null; then
    ok "고객사 거르개에 ${cust}가지가 설 수 있다 (미지정 줄 ${nocust:-?}개)"
  else
    hm "고객사 가짓수가 0 입니다 — **그러면 고객사 칸이 빈 채로 섭니다.** 사람이 보세요"
  fi

  say ""
  say "── ④ 🔵 **발주발행일 세우기**가 실제로 할 일이 있는가"
  say "🔴 **세모는 완료된 줄도 세웁니다** — 반면 거르개의 「발주 완료」는 완료된 줄을"
  say "   뺍니다(②). 🔵 그래서 **두 수가 다른 것이 맞습니다**(참고 27 ≠ 13)."
  issued_any=$(pgn dss-pg-app dss_as "select count(*) from domestic_orders where is_deleted = false and order_issued_date is not null")
  printf '      발주발행일이 적혀 있는 줄 %s개 (참고 %s) · ② 의 「발주 완료」는 %s개 (참고 %s)\n' \
    "${issued_any:-?}" "$CNT_ISSUED_ANY_REF" "${issued:-?}" "$CNT_ISSUED_REF"
  if [ -z "${issued_any:-}" ]; then
    unk "발행일 있는 줄 수" "질의가 거절됐을 수 있습니다 — 🔴 빈 결과는 삼켜진 오류일 수 있습니다"
  elif [ "${issued_any:-0}" -ge 2 ] 2>/dev/null; then
    ok "발행일이 있는 줄이 ${issued_any}개다 (세울 거리가 있다)"
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
  say "── ⑤ 🔴 **A/S 가 답하는가**"
  local rr pt c
  rr=$(row_by_key "$SITES" as); pt=$(field "$rr" 7)
  c=$(http_code "$pt")
  printf '      A/S 127.0.0.1:%s → %s\n' "$pt" "${c:-못 읽음}"
  if http_ok "${c:-}"; then ok "A/S 가 답한다 ($c — 307 은 로그인으로 보내는 것이다)"
  else bad "A/S 가 $c 를 돌려준다"; fi

  # ── ⑥ 🔵 **예순세째가 올린 자리** — 권한이 걸리는 줄 수
  say ""
  say "── ⑥ 🔵 **예순세째의 권한이 걸리는 줄** — 읽기 전용이 서는 자리 (뒷걸음을 본다)"
  say "🔴 **여기서 「완료됨」을 다시 재지 않습니다** — ② 가 쟀습니다."
  if [ -n "${done_:-}" ] && [ -n "${live:-}" ]; then
    ok "완료된 내자 줄 ${done_}개 / 휴지통 밖 ${live}개 — **이만큼이 읽기 전용이다**"
  else
    unk "완료된 내자 줄 수" "② 에서 못 쟀습니다"
  fi
  say "🔵 **참고값이 없습니다 — 67번이 처음 센 수입니다.** 지어내지 않았습니다."
  rowdone=$(pgn dss-pg-app dss_as "select count(*) from $ROWDONE_TABLE r join domestic_orders d on d.id = r.domestic_order_id where d.is_deleted = false and r.completed_at is not null")
  printf '      완료된 회차 줄 %s개 (%s · 참고값 없음)\n' "${rowdone:-?}" "$ROWDONE_TABLE"
  if [ -z "${rowdone:-}" ]; then
    hm "회차 줄을 못 쟀습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
  else
    ok "완료된 회차 줄을 값으로 쟀다 (${rowdone}개 — [N차 해제]가 사라지는 자리다)"
  fi

  # ── ⑦ 🔵 **예순네째가 올린 자리** — 결재가 올라가 있는 견적서 (뒷걸음을 본다)
  say ""
  say "── ⑦ 🔵 **결재가 올라가 있는 견적서** — 예순네째가 올린 창이 뜨는 자리"
  say "🔴 **마지막 결재 줄의 status 가 REQUESTED 거나 APPROVED 인 장**만 셉니다 —"
  say "   앱이 쓰는 조건입니다(이미 반려된 장은 창이 안 뜹니다)."
  say "🔴 **참고값이 없습니다** — 지어내지 않았습니다."
  say "🔴 **이 절은 ✗ 를 안 냅니다** — ✗ 를 내는 것은 아래 잣대 검사 하나뿐입니다."
  qlive=$(pgn "$QAPP_BOX" "$QAPP_DB" "$QAPP_LIVE_SQL")
  printf '      결재가 올라가 있는 견적서 %s건 (참고값 없음)\n' "${qlive:-?}"
  if [ -z "${qlive:-}" ]; then
    hm "못 쟀습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** $QAPP_TABLE 이 있는지 보세요"
  else
    ok "결재가 올라가 있는 견적서를 값으로 쟀다 (${qlive}건)"
    say "      🔵 0 이어도 정상입니다 — 지금 올라가 있는 결재가 없다는 뜻입니다."
  fi
  qprobe=$(pgn "$QAPP_BOX" "$QAPP_DB" "$QAPP_PROBE_SQL")
  printf '      없는 상태로 물었을 때: %s건 (기대 0)\n' "${qprobe:-?}"
  [ "${qprobe:-x}" = "0" ] && ok "결재 상태를 세는 잣대가 **살아 있다** (위 수를 믿을 수 있다)" \
    || bad "없는 상태를 물었는데 ${qprobe:-?} 가 나왔다 — **질의가 깨졌다.** 위 수도 못 믿는다"

  # ══════════════════════════════════════════════════════════════════
  # ── 🔵 여기부터 **예순일곱째가 올린 것을 보는 자리** (⑧·⑨·⑩)
  # ══════════════════════════════════════════════════════════════════
  say ""
  say "══ 🔵 **여기부터 ⑧·⑨·⑩ — 예순일곱째가 올린 것을 보는 자리입니다**"
  say "🔴 71번에서는 이 셋이 「이번에 올리는 것」이었습니다. **이제는 뒷걸음을 보는**"
  say "   **자리**입니다 — 「이번 범위 밖이니 지운다」고 착각하기 쉬운 자리입니다."
  say "🔵 **칸이 있는지 먼저 묻는 꼴을 그대로 뒀습니다** — 이제는 늘 1 이 나와야"
  say "   하지만, **DB 가 되감긴 날 그 줄만이 그것을 잡습니다.**"
  say "🔴 **이 셋은 ✗ 를 한 번도 안 냅니다** — ✗ 를 내는 것은 **잣대 검사**뿐입니다."

  # ── ⑧ 🔴 납기요청일 회차의 **확정 두 칸**
  say ""
  say "── ⑧ 🔴 **납기요청일 회차의 확정 두 칸** (🔵 예순일곱째가 0133 으로 올린 것)"
  say "🔵 두 칸은 **함께 차거나 함께 비어야** 합니다 — 0133 의 CHECK 가 그것을 못 박았습니다"
  say "   (confirmed_at IS NULL AND confirmed_by IS NULL) OR (둘 다 NOT NULL)."
  ca=$(has_column "$DUE_BOX" "$DUE_DB" "$DUE_TABLE" confirmed_at)
  cb=$(has_column "$DUE_BOX" "$DUE_DB" "$DUE_TABLE" confirmed_by)
  printf '      %s — confirmed_at 있나 %s · confirmed_by 있나 %s (적용 뒤 기대 1 · 1)\n' \
    "$DUE_TABLE" "${ca:-?}" "${cb:-?}"
  if [ -z "${ca:-}" ] || [ -z "${cb:-}" ]; then
    unk "확정 두 칸" "못 쟀다 — $DUE_BOX 가 도는지 보세요"
  elif [ "${ca}" != "1" ] || [ "${cb}" != "1" ]; then
    hm "**그 칸이 없습니다**(at ${ca} · by ${cb}) — 🔴 **예순일곱째가 올린 칸이 사라졌습니다**"
    say "      🔴 **이 판에서는 늘 있어야 합니다**(71번에서는 --migrate 전이면 정상이었습니다)."
    say "         2-ㄱ-2 가 같은 것을 ✗ 로 잡았을 것입니다 — 거기부터 보세요."
  else
    nrow=$(pgn "$DUE_BOX" "$DUE_DB" "select count(*) from $DUE_TABLE")
    ncol=$(pgn "$DUE_BOX" "$DUE_DB" "$DUE_CONFIRMED_SQL")
    half=$(pgn "$DUE_BOX" "$DUE_DB" "$DUE_HALF_SQL")
    printf '      회차 줄 전체 %s · **확정된 회차 %s개** (참고값 없음 — 71번이 처음 센 수라 적혀 있지 않다)\n' "${nrow:-?}" "${ncol:-?}"
    printf '      한쪽만 찬 줄 %s개 (기대 0 — 0133 의 CHECK 가 막는다)\n' "${half:-?}"
    if [ -z "${ncol:-}" ] || [ -z "${half:-}" ]; then
      hm "못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
    else
      ok "확정된 회차를 값으로 쟀다 (${ncol}개 / 전체 ${nrow:-?}줄)"
      if [ "${ncol}" = "0" ]; then
        say "      🔵 **0 입니다 — 올린 직후라면 맞습니다.** 아무도 아직 [납기일 확정]을 안 눌렀습니다."
      else
        say "      🔵 **0 보다 큽니다 — 누군가 이미 확정했다는 뜻이고 그것도 정상입니다.**"
        say "         🔴 그 회차들은 **종의 「기타건 납기 임박」에서 빠집니다** — ⑨ 가 그 수를 따로 셉니다."
      fi
      if [ "${half}" = "0" ]; then
        ok "한쪽만 찬 줄이 **0개다** (CHECK 가 서 있다 — 두 칸이 늘 짝으로 움직인다)"
      else
        hm "한쪽만 찬 줄이 ${half}개 있습니다 — 🔴 **CHECK 가 안 붙었거나 누가 떼어 냈습니다.** 사람이 보세요"
      fi
    fi
  fi
  # 🔴 **잣대가 살아 있는가** — 없는 칸을 물어 0 이 나오는지 본다.
  n=$(has_column "$DUE_BOX" "$DUE_DB" "$DUE_TABLE" "__dss_probe_no_such_column__")
  printf '      없는 칸을 물었을 때: %s (기대 0)\n' "${n:-?}"
  [ "${n:-x}" = "0" ] && ok "칸을 묻는 잣대가 **살아 있다** (위 수를 믿을 수 있다)" \
    || bad "없는 칸을 물었는데 ${n:-?} 가 나왔다 — **「무조건 있다」인 검사다.** 위 수도 못 믿는다"

  # ── ⑨ 🔴 **기타건 납기 임박**이 몇 건인가 (새 알림 종류)
  say ""
  say "── ⑨ 🔴 **기타건 납기 임박** — 🔵 예순일곱째가 울리게 만든 종"
  say "🔴🔴 **이 수는 「앱이 센 수」가 아닙니다 — 상한입니다.**"
  say "   앱은 뜰지 말지를 **도메인 함수**로 정합니다(isDomesticOrderDueDateRowNear) —"
  say "   창은 「오늘 ≤ 날짜 ≤ 오늘+7, **한국 달력**」이고 끝난 회차(완료 또는 납품일)와"
  say "   **확정된 회차**를 뺍니다. 여기서는 그 조건을 SQL 로 **흉내만** 냅니다:"
  say "     · 한국 날짜를 (now() at time zone 'Asia/Seoul')::date 로 잡습니다"
  say "     · due_date 는 date 칸이라 시각이 안 섞입니다"
  say "   🔴 **그래도 같은 수라고 단정하지 마세요** — 판정이 코드에 있고 그 코드가"
  say "      바뀌는 날 이 SQL 만 옛 창으로 남습니다. **그래서 ✗ 를 안 냅니다.**"
  say "      정본은 **눈 확인에서 종을 열어 맞대는 것**입니다."
  say "🔴 **기타건** = 수리 건이 안 붙은 내자 줄입니다 — 가르는 자리는"
  say "   repair_case_id IS NULL 하나입니다(앱과 같은 잣대)."
  misc=$(pgn dss-pg-app dss_as "$MISC_ROWS_SQL")
  near=$(pgn dss-pg-app dss_as "$MISC_NEAR_SQL")
  silenced=$(pgn dss-pg-app dss_as "$MISC_NEAR_SILENCED_SQL")
  printf '      기타건 줄 %s개 · **납기 임박 상한 %s건** · 확정 때문에 빠진 줄 %s건 (참고값 없음)\n' \
    "${misc:-?}" "${near:-?}" "${silenced:-?}"
  if [ -z "${misc:-}" ] || [ -z "${near:-}" ] || [ -z "${silenced:-}" ]; then
    hm "셋 중 못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.**"
    say "      🔴 **이 판에서는 정상이 아닙니다**(71번에서는 --migrate 전이면 정상이었습니다) —"
    say "         confirmed_at 칸이 없으면 질의가 42703 으로 거절됩니다. 2-ㄱ-2 를 보세요."
  else
    ok "기타건 납기 임박을 값으로 쟀다 (상한 ${near}건 / 기타건 ${misc}줄)"
    if [ "${near}" = "0" ]; then
      say "      🔵 **0 입니다** — 앞으로 7일 안에 납기가 걸린 기타건 회차가 없다는 뜻입니다."
      say "         🔴 그러면 **눈 확인에서 종에 그 줄이 안 뜨는 것이 정상**입니다 — 「안 뜬다」를"
      say "            결함으로 읽지 마세요. 표본을 만들려면 기타건 회차의 납기요청일을"
      say "            오늘~7일 안으로 하나 넣어 보세요."
    else
      say "      🔵 **${near}건입니다** — 눈 확인에서 종을 열면 그만큼 보일 것입니다(상한)."
    fi
    if [ "${silenced:-0}" -ge 1 ] 2>/dev/null; then
      say "      🔵 **확정 때문에 ${silenced}건이 빠져 있습니다** — ㄱ 갈래가 ㄴ 갈래를 실제로"
      say "         끄고 있다는 값 증거입니다."
    else
      say "      🔵 확정 때문에 빠진 줄이 0건입니다 — **아무도 아직 확정을 안 눌렀거나**"
      say "         확정한 회차의 납기가 창 밖입니다. 둘 다 정상입니다."
    fi
  fi

  # ── ⑩ 🔴 **노드 표 둘에 파일 자리 칸**이 생겼는가 · 가리킨 노드 수
  say ""
  say "── ⑩ 🔴 **노드 표 둘의 「관련 파일」 칸** (🔵 예순일곱째가 0132 로 올린 것)"
  say "🔴 **표가 둘입니다** — 절차 본보기 노드와 진단 Flowchart 노드. 한쪽만 재면"
  say "   **나머지 한쪽이 아무 검사도 안 받습니다**(마이그레이션 한 장에 둘이 같이 있습니다)."
  NODE_SEEN=0; NODE_HAVE=0
  while IFS='|' read -r NT NN; do
    [ -n "${NT:-}" ] || continue
    NODE_SEEN=$((NODE_SEEN+1))
    n=$(has_column dss-pg-app dss_as "$NT" "$NODE_COL")
    if [ -z "${n:-}" ]; then
      unk "$NN 의 $NODE_COL 칸" "못 쟀다 — dss-pg-app 이 도는지 보세요"
      continue
    fi
    if [ "$n" != "1" ]; then
      printf '      %-30s %s 칸이 **없다** (🔴 예순일곱째가 올린 칸이 사라졌다)\n' "$NT" "$NODE_COL"
      continue
    fi
    NODE_HAVE=$((NODE_HAVE+1))
    nrow=$(pgn dss-pg-app dss_as "select count(*) from $NT")
    npt=$(pgn dss-pg-app dss_as "select count(*) from $NT where $NODE_COL is not null")
    printf '      %-30s 노드 %s개 · **파일을 가리킨 노드 %s개** (참고값 없음)\n' "$NT" "${nrow:-?}" "${npt:-?}"
    if [ -z "${npt:-}" ]; then
      hm "$NN 의 가리킨 노드 수를 못 쟀습니다 — 🔴 빈 결과는 삼켜진 오류일 수 있습니다"
    else
      ok "$NN — 파일을 가리킨 노드 ${npt}개 (전체 ${nrow:-?}개)"
    fi
  done <<ENDNODE
$(rows_of "$NODE_TABLES")
ENDNODE
  printf '      본 표 %s · 칸이 있는 표 %s (표의 수 %s)\n' "$NODE_SEEN" "$NODE_HAVE" "$NODE_TABLES_WANT"
  if [ "$NODE_SEEN" != "$NODE_TABLES_WANT" ]; then
    bad "노드 표를 ${NODE_SEEN}개만 봤다 — ${NODE_TABLES_WANT}개를 기대했다. NODE_TABLES 표가 깨졌다"
  elif [ "$NODE_HAVE" = "$NODE_TABLES_WANT" ]; then
    ok "**노드 표 둘 다 파일 자리 칸을 갖췄다** (0132 가 적용됐다)"
    say "      🔵 **가리킨 노드가 0개여도 정상입니다** — 아무도 아직 파일을 안 달았습니다."
  elif [ "$NODE_HAVE" = "0" ]; then
    hm "둘 다 **칸이 없습니다** — 🔴 **예순일곱째가 올린 0132 가 되감겼습니다.** 사람이 보세요"
  else
    hm "둘 중 ${NODE_HAVE}개만 칸이 있습니다 — 🔴 **한 마이그레이션에 둘이 같이 있으므로**"
    say "      그 꼴은 정상 경로로는 안 생깁니다. **사람이 보세요.**"
  fi

  # ══════════════════════════════════════════════════════════════════
  # ── 🔴🔴 여기부터 **72번 고유** — 이번에 올리는 것이 운영에서 도는가
  # ══════════════════════════════════════════════════════════════════
  say ""
  say "══ 🔴🔴 **여기부터 72번 고유입니다** (71번의 ⑪ 「포털이 답하는가」가 있던 자리)"
  say "🔴 **셋 다 보는 칸이 이미 있습니다** — 그래서 71번처럼 「칸이 있는지 먼저 묻기」가"
  say "   필요 없습니다(0132·0133 이 예순일곱째에 올라갔고, 나머지는 2026-08 부터 있습니다)."
  say "🔴 **이 셋은 ✗ 를 한 번도 안 냅니다** — ✗ 를 내는 것은 **잣대 검사**뿐입니다."
  say "🔴 **이 배포는 자료를 한 글자도 안 바꿉니다** — 전과 후의 수가 **같아야** 정상입니다."
  say "🔴 **참고값이 없습니다 — 이 판이 처음 세는 수입니다**(⑬ 하나만 2026-10-30 의"
  say "   비슷한 실측이 있습니다). 지어내지 않았습니다."

  # ── ⑪ 🔴 **확정된 회차 중 완료된 것** — ㄱ 갈래가 화면에서 지우는 줄
  say ""
  say "── ⑪ 🔴 **확정된 회차 중 「완료된」 것** (ㄱ갈래 — 완료된 건에서 확정 단추가 사라진다)"
  say "🔴 **세 수의 뜻이 다릅니다. 섞어 읽지 마세요:**"
  say "   ㄱ) 확정된 회차 **전체**            — ⑧ 이 이미 센 수입니다"
  say "   ㄴ) 그중 **줄이나 회차가 완료된 것** — 🔴 **「확정 ✓」 표까지 사라지는 줄**"
  say "   ㄷ) 완료된 회차 **전체**            — 🔵 **단추가 사라지는 줄의 상한**"
  say "      (확정 안 된 줄에서도 [납기일 확정] 단추가 사라집니다 — 고칠 수 있는"
  say "       세션에서만 보이던 단추입니다)"
  say "🔵 화면 판정은 도메인 한 곳이 쥡니다(showDomesticOrderDueDateConfirmControls) —"
  say "   **줄의 완료**(domestic_orders.completed_at)든 **그 회차의 완료**"
  say "   (domestic_order_due_dates.completed_at)든 하나라도 차 있으면 셋이 다 사라집니다."
  say "🔴 **서버는 한 글자도 안 바뀝니다** — 이미 찍힌 확정은 **안 풀립니다.**"
  say "   그래서 ㄱ 의 수가 **배포 전후로 같아야** 정상입니다."
  cdone=$(pgn "$DUE_BOX" "$DUE_DB" "$DUE_CONFIRMED_DONE_SQL")
  adone=$(pgn "$DUE_BOX" "$DUE_DB" "$DUE_DONE_ANY_SQL")
  printf '      ㄴ) 확정 **그리고** 완료인 회차 %s개 (참고값 없음)\n' "${cdone:-?}"
  printf '      ㄷ) 완료된 회차 전체 %s개 (참고값 없음 — 단추가 사라지는 줄의 상한)\n' "${adone:-?}"
  if [ -z "${cdone:-}" ] || [ -z "${adone:-}" ]; then
    hm "둘 중 못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
  else
    ok "ㄱ갈래가 지우는 줄을 값으로 쟀다 (표까지 사라지는 줄 ${cdone}개 / 단추가 사라지는 줄 ${adone}개)"
    if [ "${cdone}" = "0" ]; then
      say "      🔵 **0 입니다** — 확정된 회차 중 완료된 것이 없다는 뜻입니다."
      say "         🔴 그러면 **눈 확인에서 「확정 ✓」 표가 사라지는 줄을 못 봅니다** —"
      say "            「안 바뀐다」를 결함으로 읽지 마세요. 표본을 만들려면 확정된"
      say "            회차가 있는 줄을 하나 [완료 처리] 해 보세요."
    else
      say "      🔵 **${cdone}개입니다** — 눈 확인에서 그만큼이 「확정 ✓」 표까지 사라집니다."
    fi
    if [ "${adone:-0}" -lt "${cdone:-0}" ] 2>/dev/null; then
      bad "ㄷ(${adone})가 ㄴ(${cdone})보다 작다 — **ㄷ 는 ㄴ 을 품어야 한다.** 질의가 깨졌다"
      doubt
    else
      ok "ㄷ 가 ㄴ 을 품는다 (${adone} ≥ ${cdone} — 두 질의가 같은 집합을 보고 있다)"
    fi
  fi
  # 🔴 **잣대가 살아 있는가** — ⑧ 이 이미 쟀다(없는 칸을 물어 0 이 나오는가).
  say "      🔵 **이 절의 잣대는 ⑧ 이 이미 쟀습니다**(없는 칸으로 물어 0) — 두 번 안 묻습니다."

  # ── ⑫ 🔴 **작업 상태가 [수리 대기]인 건** — ㄴ 갈래가 옮기는 자리
  say ""
  say "── ⑫ 🔴 **작업 상태가 [수리 대기]인 건** (ㄴ갈래 — PO발행일이 적히면 여기로 간다)"
  say "🔴 **상태는 저장 칸이 아닙니다** — repair_cases.current_workflow_step_id 가"
  say "   가리키는 workflow_steps 의 **repair_status** 에서 나옵니다. 그래서 **조인해서**"
  say "   세어야 합니다(앱이 쓰는 조건 그대로입니다)."
  say "🔵 **배포 전과 뒤가 같은 것이 정상입니다** — 이 배포는 자료를 안 바꿉니다."
  say "   🔴 **사람이 PO발행일을 적는 순간부터** 늡니다. 그래서 올린 뒤에 늘어 있어도"
  say "      사고가 아닙니다 — **그것이 이 기능이 도는 증거**입니다."
  wrc=$(pgn dss-pg-app dss_as "$WR_CASES_SQL")
  wrs=$(pgn dss-pg-app dss_as "$WR_STEPS_SQL")
  wrv=$(pgn dss-pg-app dss_as "$WR_VER_NOSTEP_SQL")
  printf '      작업 상태가 [수리 대기]인 건 %s개 (참고값 없음)\n' "${wrc:-?}"
  printf '      repair_status = %s 인 **단계** %s개 (🔵 유상 셋에만 있고 무상에는 없다)\n' "$WR_STATUS" "${wrs:-?}"
  printf '      그 단계가 **없는** 워크플로 버전 %s개 (그 버전에 선 건은 안 옮겨진다)\n' "${wrv:-?}"
  if [ -z "${wrc:-}" ] || [ -z "${wrs:-}" ] || [ -z "${wrv:-}" ]; then
    hm "셋 중 못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
  else
    ok "[수리 대기]의 자리를 값으로 쟀다 (건 ${wrc}개 · 단계 ${wrs}개 · 그 단계가 없는 버전 ${wrv}개)"
    if [ "${wrs:-0}" = "0" ]; then
      hm "🔴 **그 상태의 단계가 운영에 하나도 없습니다** — 그러면 이 기능은 **어디에서도**"
      say "         **안 걸립니다**(앱이 NO_WAITING_REPAIR_STEP 으로 조용히 건너뜁니다)."
      say "      🔴 눈 확인에서 「날짜를 적어도 상태가 안 바뀐다」가 나올 것입니다 —"
      say "         **결함이 아니라 이 수의 결과**입니다. 먼저 이 줄을 보세요."
    else
      say "      🔵 **그 상태의 단계가 ${wrs}개 있습니다** — 그 단계를 가진 워크플로에 선"
      say "         건만 옮겨집니다. 🔴 **무상 워크플로에는 그 단계가 없습니다**(결정이"
      say "         아니라 운영 실측입니다 — 그 건은 날짜를 적어도 아무 일도 안 일어납니다)."
    fi
    if [ "${wrv:-0}" -ge 1 ] 2>/dev/null; then
      say "      🔵 **그 단계가 없는 버전이 ${wrv}개**입니다 — 거기 선 건은 이 기능이"
      say "         아예 안 걸립니다. 눈 확인 표본을 **유상 건**에서 고르세요."
    fi
  fi
  # 🔴 **잣대가 살아 있는가** — 🔵 repair_status 는 **enum** 이라 없는 글자를 그대로
  #    맞대면 22P02 로 **거절**된다. 그래서 ::text 로 바꿔 묻는다.
  n=$(pgn dss-pg-app dss_as "$WR_PROBE_SQL")
  printf '      없는 상태로 물었을 때: %s개 (기대 0)\n' "${n:-?}"
  [ "${n:-x}" = "0" ] && ok "단계를 세는 잣대가 **살아 있다** (위 수를 믿을 수 있다)" \
    || bad "없는 상태를 물었는데 ${n:-?} 가 나왔다 — **질의가 깨졌다.** 위 수도 못 믿는다"

  # ── ⑬ 🔴 **납품 요청일을 빌려 오는 건** — ㄷ 갈래가 화면을 바꾸는 줄
  say ""
  say "── ⑬ 🔴 **납품 요청일을 「빌려 오는」 건** (ㄷ갈래 — 이 수가 곧 달라지는 줄 수다)"
  say "🔴 그 건에 적힌 **고객 요청 납기일이 비었는데** 연결된 내자 줄에 **납기요청일이"
  say "   있는** 건입니다. 🔵 customer_requested_due_date 는 **date 칸**이라 공백이"
  say "   섞일 수 없습니다 — IS NULL 하나로 「비었다」가 다 걸립니다."
  say "🔴🔴 **이 수가 0 이면 눈 확인에서 아무것도 안 바뀌는 것이 정상입니다** —"
  say "   「안 바뀐다」를 결함으로 읽지 마세요."
  say "🔵 **두 수의 뜻이 다릅니다:** 위는 **상한**(휴지통 밖 전부)이고, 아래가"
  say "   **고객 안내 현황이 실제로 보는 수**입니다 — 그 화면은 **출하 완료를 뺍니다**"
  say "   (queries/customer-portal.ts 의 그 한 줄이 유일한 근거입니다)."
  bo=$(pgn dss-pg-app dss_as "$BORROW_ALL_SQL")
  bp=$(pgn dss-pg-app dss_as "$BORROW_PORTAL_SQL")
  printf '      빌려 오는 건 (상한) %s개 (참고 %s — 2026-10-30 의 비슷한 실측)\n' "${bo:-?}" "$CNT_BORROW_REF"
  printf '      그중 **출하 완료를 뺀 것** %s개 (🔴 고객 안내 현황이 실제로 보는 수)\n' "${bp:-?}"
  if [ -z "${bo:-}" ] || [ -z "${bp:-}" ]; then
    hm "둘 중 못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
  else
    ok "빌려 오는 건을 값으로 쟀다 (상한 ${bo}개 · 화면이 보는 것 ${bp}개)"
    if [ "${bp}" = "0" ]; then
      say "      🔵 **0 입니다** — 고객 안내 현황에서 **「납품 요청일」 칸이 한 줄도**"
      say "         **안 달라집니다.** 🔴 그것이 정상입니다. 표본을 만들려면 고객 요청"
      say "         납기일이 빈 건의 내자 줄에 납기요청일을 하나 넣어 보세요."
    else
      say "      🔵 **${bp}개입니다** — 눈 확인에서 그만큼의 「납품 요청일」 칸에 날짜가"
      say "         새로 뜹니다(전에는 빈칸이었습니다)."
    fi
    if [ "${bo:-0}" -lt "${bp:-0}" ] 2>/dev/null; then
      bad "상한(${bo})이 화면 수(${bp})보다 작다 — **품어야 한다.** 질의가 깨졌다"
      doubt
    else
      ok "상한이 화면 수를 품는다 (${bo} ≥ ${bp} — 두 질의가 같은 집합을 보고 있다)"
    fi
    [ "${bo}" = "$CNT_BORROW_REF" ] || say "      🔵 2026-10-30 의 ${CNT_BORROW_REF}건과 다릅니다 — **그 수는 다른 잣대로 센 것**이라 달라도 됩니다."
  fi
  # 🔴 **잣대가 살아 있는가** — 있을 수 없는 날짜로 물어 0 이 나오는지 본다.
  n=$(pgn dss-pg-app dss_as "$BORROW_PROBE_SQL")
  printf '      없는 날짜(1900-01-01)로 물었을 때: %s개 (기대 0)\n' "${n:-?}"
  [ "${n:-x}" = "0" ] && ok "빌려 오는 건을 세는 잣대가 **살아 있다** (위 수를 믿을 수 있다)" \
    || bad "없는 날짜를 물었는데 ${n:-?} 가 나왔다 — **질의가 깨졌다.** 위 수도 못 믿는다"

  # ══════════════════════════════════════════════════════════════════
  # ── 🔵 여기부터 **73번이 올린 것을 보는 자리** (⑭~⑲ · 뒷걸음)
  #    🔴 그 집은 이번에 **안 올라간다** — 그래도 **하나도 안 뺐다.**
  # ══════════════════════════════════════════════════════════════════
  say ""
  say "══ 🔵 **여기부터 ⑭~⑲ — 73번이 올린 것을 보는 자리입니다**(전부 재고관리 쪽)"
  say "🔴 **A/S 쪽 DB 는 이 기능으로 칸도 줄도 안 늘립니다** — A/S 는 통로로 보내기만"
  say "   하고, 신청과 원장은 **재고에 쌓입니다.** 그래서 셀 자리가 저쪽입니다."
  say "🔴 **⑭~⑱ 은 ✗ 를 한 번도 안 냅니다** — ✗ 를 내는 것은 **잣대 검사**뿐입니다."
  say "🔴 **참고값이 하나도 없습니다 — 73번이 처음 센 수이고 그 값이 안 적혀 있습니다.**"
  say "   지어내지 않았습니다. 🔵 **올리기 전에 잰 수를 적어 두세요** — 다음 판이 씁니다."
  say "🔴 **이번 판은 이 여섯을 한 자리도 안 바꿉니다** — 전후가 같아야 정상입니다."

  # ── ⑭ 🔴 **반환 신청(type='RETURN')** — 🔵 운영에는 **0건**일 것이다
  say ""
  say "── ⑭ 🔴 **반환 신청(type='RETURN')** — 상태별로 (🔵 어제 생긴 기능입니다)"
  say "🔴🔴 **0 이어도 정상입니다** — 그 기능이 **어제** 올라갔고 아직 아무도 안 눌렀을"
  say "   수 있습니다. 그러면 재고의 신청 목록에 **반환이 한 줄도 안 보이는 것이 맞습니다.**"
  say "🔴 **이번 배포는 이 수를 한 자리도 안 바꿉니다** — 전후가 같아야 정상입니다."
  say "   🔵 [실측 2026-11-26 · 개발 DB] 그날 아침까지 신청 29줄이 **전부 USE** 였습니다"
  say "      (dss-inventory 의 listPendingReturnPayloads 주석)."
  say "🔴 **올린 뒤에는 늡니다** — 사람이 [반환 요청]을 누르는 순간부터입니다."
  say "   **그것이 이 기능이 도는 증거**이지 사고가 아닙니다."
  rall=$(pgn "$INV_BOX" "$INV_DB" "$RET_ALL_SQL")
  rpend=$(pgn "$INV_BOX" "$INV_DB" "$RET_PENDING_SQL")
  printf '      반환 신청 전체 %s건 · 그중 **대기** %s건 (참고값 없음)\n' "${rall:-?}" "${rpend:-?}"
  if [ -z "${rall:-}" ] || [ -z "${rpend:-}" ]; then
    hm "둘 중 못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
    say "      🔵 $REQ_TABLE 이 있는지, $INV_DB 에 닿는지 보세요."
  else
    ok "반환 신청을 값으로 쟀다 (전체 ${rall}건 · 대기 ${rpend}건)"
    if [ "${rall}" = "0" ]; then
      say "      🔵 **0 입니다 — 올리기 전이라면 맞습니다.** 아직 아무도 안 올렸습니다."
    else
      say "      🔵 **${rall}건입니다** — 상태별 내역을 아래에 폅니다."
      pgrows "$INV_BOX" "$INV_DB" "$RET_BY_STATUS_SQL" | sed 's/^/        /'
    fi
    say "      🔵 **대기로 세는 상태는 다섯**입니다(PENDING·CONFIRMING·PARTIAL·ON_HOLD·"
    say "         IN_APPROVAL) — 재고의 PENDING_REQUEST_STATUSES 를 그대로 옮겼습니다."
  fi
  # 🔴 **잣대가 살아 있는가** — 🔵 type 은 enum 이라 ::text 로 바꿔 묻는다.
  n=$(pgn "$INV_BOX" "$INV_DB" "$RET_PROBE_SQL")
  printf '      없는 종류로 물었을 때: %s건 (기대 0)\n' "${n:-?}"
  [ "${n:-x}" = "0" ] && ok "신청 종류를 세는 잣대가 **살아 있다** (위 수를 믿을 수 있다)" \
    || bad "없는 종류를 물었는데 ${n:-?} 가 나왔다 — **질의가 깨졌다.** 위 수도 못 믿는다"

  # ── ⑮ 🔴 **반출 신청(type='USE')** — 이 배포가 한 줄도 안 바꿔야 한다
  say ""
  say "── ⑮ 🔴 **반출 신청(type='USE')** — 🔴 **이 배포가 한 줄도 안 바꿔야 합니다**"
  say "🔵 반환은 **같은 주소·같은 표**에 type 만 달리 적습니다(저쪽이 그렇게 열었습니다)."
  say "   🔴 그래서 **반출 수가 달라졌다면 반출 쪽을 건드렸다는 뜻**입니다 —"
  say "      전과 후가 **같아야** 정상입니다."
  uall=$(pgn "$INV_BOX" "$INV_DB" "$USE_ALL_SQL")
  printf '      반출 신청 %s건 (참고값 없음 · 🔴 **전후가 같아야 한다**)\n' "${uall:-?}"
  if [ -z "${uall:-}" ]; then
    hm "못 쟀습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.**"
  else
    ok "반출 신청을 값으로 쟀다 (${uall}건 — 올린 뒤에 이 수가 달라지면 사람이 보세요)"
  fi

  # ── ⑯ 🔴 **[반환 완료]된 반환** — 종이 뜰 줄의 수
  say ""
  say "── ⑯ 🔴 **[반환 완료]된 반환** — 🔵 올린 사람의 종이 울릴 줄의 수"
  say "🔵 **끝난 것으로 치는 상태는 CONFIRMED 하나**입니다(재고의 COMPLETED_RETURN_"
  say "   STATUSES). 반려·거둠은 **물건이 안 돌아온 것**이라 거기 없습니다 — 그 신청에"
  say "   종이 울리면 거짓말이 됩니다."
  rdone=$(pgn "$INV_BOX" "$INV_DB" "$RET_DONE_SQL")
  printf '      [반환 완료]된 반환 %s건 (참고값 없음)\n' "${rdone:-?}"
  if [ -z "${rdone:-}" ]; then
    hm "못 쟀습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.**"
  else
    ok "반환 완료를 값으로 쟀다 (${rdone}건 — 종에 그만큼 뜹니다)"
    if [ "${rdone}" = "0" ]; then
      say "      🔵 **0 입니다** — 아직 아무 반환도 안 끝났으니 **종에 그 줄이 없는 것이"
      say "         정상**입니다. 눈 확인 표본을 만들려면 A/S 에서 하나 올리고 재고에서"
      say "         [반환 완료]를 눌러 보세요."
    fi
    if [ -n "${rall:-}" ] && [ "${rdone:-0}" -gt "${rall:-0}" ] 2>/dev/null; then
      bad "완료(${rdone})가 전체(${rall})보다 많다 — **품어야 한다.** 질의가 깨졌다"
      doubt
    elif [ -n "${rall:-}" ]; then
      ok "완료가 전체를 안 넘는다 (${rdone} ≤ ${rall} — 두 질의가 같은 집합을 보고 있다)"
    fi
  fi

  # ── ⑰ 🔴 **돌려줄 수 있는 부품이 있는 수리 건** — 창에 목록이 뜰 건
  say ""
  say "── ⑰ 🔴 **돌려줄 수 있는 부품이 있는 수리 건** ([반환 요청] 창에 목록이 뜰 건)"
  say "🔴🔴 **앱이 쓰는 조건을 그대로 흉내 냈습니다** — 짐작으로 세지 않았습니다"
  say "   (dss-inventory 의 readReturnableTransactions · 인수번호 가지):"
  say "     · 기록 종류가 **USE 또는 LOAN** · 줄의 delta 가 **음수**(나간 줄)"
  say "     · **기록 취소된 줄은 뺀다**(그 줄을 reverses_transaction_id 로 가리키는 줄)"
  say "     · 이미 돌아온 수량 = 그 줄을 returns_transaction_id 로 가리키는 줄의 합"
  say "     · **남은 수량 > 0** 인 줄만 센다"
  say "🔴 **대기 중인 반환 신청(pending)은 안 뺐습니다** — 앱은 뺍니다. 그 값이 신청의"
  say "   payload(jsonb) 안이라 SQL 로 흉내 내면 틀릴 자리가 많습니다."
  say "   🔵 **⑭ 가 0 이면 두 수가 정확히 같습니다**(올리기 전이 그렇습니다). 올린"
  say "      뒤에는 **이 수가 상한**이 됩니다 — 그래서 ✗ 를 안 냅니다."
  say "🔵 **0 이면 눈 확인에서 [반환 요청] 창이 비어 있는 것이 정상**입니다."
  rcase=$(pgn "$INV_BOX" "$INV_DB" "$RETURNABLE_CASES_SQL")
  rline=$(pgn "$INV_BOX" "$INV_DB" "$RETURNABLE_LINES_SQL")
  printf '      돌려줄 것이 남은 **수리 건(인수번호)** %s개 · 그 **원장 줄** %s개 (참고값 없음)\n' \
    "${rcase:-?}" "${rline:-?}"
  if [ -z "${rcase:-}" ] || [ -z "${rline:-}" ]; then
    hm "둘 중 못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
  else
    ok "돌려줄 수 있는 자리를 값으로 쟀다 (건 ${rcase}개 · 줄 ${rline}개)"
    if [ "${rcase}" = "0" ]; then
      say "      🔵 **0 입니다** — 어느 수리 건에서도 돌려줄 것이 없다는 뜻입니다."
      say "         🔴 그러면 **눈 확인에서 [반환 요청] 창이 비는 것이 정상**입니다 —"
      say "            「목록이 안 뜬다」를 결함으로 읽지 마세요. 표본을 만들려면 재고에서"
      say "            부품을 하나 반출(USE)하고 그 인수번호로 열어 보세요."
    else
      say "      🔵 **${rcase}건입니다** — 그 인수번호로 [반환 요청] 을 열면 목록이 뜹니다."
    fi
    if [ "${rline:-0}" -lt "${rcase:-0}" ] 2>/dev/null; then
      bad "줄(${rline})이 건(${rcase})보다 적다 — **한 건에 줄이 하나 이상**이어야 한다. 질의가 깨졌다"
      doubt
    else
      ok "줄이 건을 품는다 (${rline} ≥ ${rcase} — 두 질의가 같은 집합을 보고 있다)"
    fi
  fi
  # 🔴 **잣대 둘** — 없는 종류로 물어 0 이 나오는가 · 거르개를 걷으면 늘어나는가.
  #    🔵 뒤쪽이 없으면 「WHERE 가 통째로 안 걸리는 질의」를 못 가른다.
  n=$(pgn "$INV_BOX" "$INV_DB" "$RETURNABLE_PROBE_SQL")
  printf '      없는 종류로 물었을 때: %s개 (기대 0)\n' "${n:-?}"
  [ "${n:-x}" = "0" ] && ok "돌려줄 자리를 세는 잣대가 **살아 있다** (위 수를 믿을 수 있다)" \
    || bad "없는 종류를 물었는데 ${n:-?} 가 나왔다 — **질의가 깨졌다.** 위 수도 못 믿는다"
  rwide=$(pgn "$INV_BOX" "$INV_DB" "$RETURNABLE_WIDE_SQL")
  printf '      거르개를 걷었을 때 인수번호 가짓수: %s개 (🔴 위 %s 보다 **크거나 같아야** 한다)\n' \
    "${rwide:-?}" "${rcase:-?}"
  if [ -z "${rwide:-}" ] || [ -z "${rcase:-}" ]; then
    hm "반대쪽 잣대를 못 쟀습니다 — 사람이 보세요"
  elif [ "${rwide}" -ge "${rcase}" ] 2>/dev/null; then
    ok "거르개를 걷으면 수가 줄지 않는다 (${rwide} ≥ ${rcase} — 거르개가 실제로 거르고 있다)"
  else
    bad "거르개를 걷었는데 수가 **줄었다** (${rwide} < ${rcase}) — 질의가 깨졌다"
    doubt
  fi

  # ── 🔵 **재고의 뒷걸음 표 둘** — 69번이 보던 자리
  say ""
  say "── ⑰-2 🔵 **재고의 뒷걸음 표 둘** (69번이 보던 자리 — 🔴 빼지 않습니다)"
  for ic in "$KEEPTBL_INV1" "$KEEPTBL_INV2"; do
    n=$(has_table "$INV_BOX" "$INV_DB" "$ic")
    rowdone=""
    [ "${n:-0}" = "1" ] && rowdone=$(table_rows "$INV_BOX" "$INV_DB" "$ic")
    printf '      %-34s 있나 %-3s 줄 %s\n' "$ic" "${n:-?}" "${rowdone:-–}"
    if [ "${n:-0}" = "1" ]; then ok "재고에 $ic 가 **그대로 있다** (${rowdone:-?}줄)"
    else hm "재고에 $ic 가 **없습니다** — 🔴 지난 판이 올린 표가 사라졌습니다. 사람이 보세요"; fi
  done
  say "      🔵 **줄 수가 0 이어도 정상입니다** — 아직 아무도 안 썼을 수 있습니다."

  # ── ⑱ 🔴 **반환 원장 건** — ㅅ 갈래(기록 내역 머리글)가 바꾸는 줄
  say ""
  say "── ⑱ 🔴 **반환 원장 건** (ㅅ갈래 — [기록 내역]의 머리글이 인수번호로 바뀐다)"
  say "🔴🔴 **반환 건은 제 인수번호를 안 들고 있습니다** — 그 칸이 **언제나 빈 글자**"
  say "   입니다(원장의 반환 갈래가 그 칸을 아예 안 씁니다). 🔴 그래서 「그 칸이"
  say "   찼나」로 세면 **늘 0** 이고, 그 0 을 「기능이 안 돈다」로 읽게 됩니다."
  say "🔵 **앱이 쓰는 길 그대로 되짚습니다**: 반환 건의 줄 → returns_transaction_id 가"
  say "   가리키는 **원래 줄** → 그 줄이 달린 **불출 건의 인수번호**."
  say "   🔵 빈 글자는 안 담고, **갈래가 하나일 때만** 머리글에 적습니다(섞였으면 빈 글자)."
  say "🔴 **운영에 0건일 수 있습니다** — 그러면 **눈 확인에서 아무것도 안 바뀌는 것이"
  say "   정상**입니다. 「고장」으로 읽지 마세요."
  ren=$(pgn "$INV_BOX" "$INV_DB" "$RET_ENTRY_SQL")
  reti=$(pgn "$INV_BOX" "$INV_DB" "$RET_ENTRY_INTAKE_SQL")
  rett=$(pgn "$INV_BOX" "$INV_DB" "$RET_ENTRY_TITLED_SQL")
  printf '      반환 원장 건 %s건 (참고값 없음)\n' "${ren:-?}"
  printf '      그중 **제 칸에 인수번호가 든 것** %s건 (기대 0 — 원장이 그 칸을 안 쓴다)\n' "${reti:-?}"
  printf '      **머리글에 번호가 뜨는 건** %s건 (되짚어서 센 수 · 갈래가 하나인 것만)\n' "${rett:-?}"
  if [ -z "${ren:-}" ] || [ -z "${rett:-}" ]; then
    hm "못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
  else
    ok "반환 원장 건을 값으로 쟀다 (전체 ${ren}건 · 머리글에 번호가 뜨는 것 ${rett}건)"
    if [ "${ren}" = "0" ]; then
      say "      🔵 **0 입니다** — 아직 아무 반환도 원장에 안 쌓였습니다."
      say "         🔴 그러면 **[기록 내역]에서 달라지는 줄이 한 줄도 없는 것이 정상**입니다."
      say "         표본을 만들려면 반환 신청을 하나 [반환 완료] 해 보세요."
    else
      say "      🔵 **${ren}건 중 ${rett}건**의 머리글이 인수번호로 바뀝니다."
      say "         🔵 나머지는 **대여·「수리 건 없음」 반출을 되돌린 것**이거나 **여러 수리"
      say "            건이 섞인 반환**입니다 — 그 자리는 **빈 글자**이고 화면이 아예 안"
      say "            그립니다(「반환」으로 되돌아가지 않습니다)."
    fi
    if [ "${rett:-0}" -gt "${ren:-0}" ] 2>/dev/null; then
      bad "머리글에 뜨는 건(${rett})이 전체(${ren})보다 많다 — **품어야 한다.** 질의가 깨졌다"
      doubt
    else
      ok "머리글에 뜨는 건이 전체를 안 넘는다 (${rett} ≤ ${ren} — 두 질의가 같은 집합을 보고 있다)"
    fi
    if [ "${reti:-x}" = "0" ]; then
      ok "반환 건의 intake_number 가 **전부 비어 있다** (머리말의 그 말이 실제와 맞다)"
    else
      hm "반환 건 ${reti}건의 intake_number 가 **차 있습니다** — 🔴 **머리말의 설명이 틀렸거나**"
      say "         누가 그 칸을 손으로 채운 것입니다. 사람이 보세요(✗ 는 안 냅니다)."
    fi
  fi
  # 🔴 **잣대가 살아 있는가** — 없는 종류로 물어 0 이 나오는지 본다.
  n=$(pgn "$INV_BOX" "$INV_DB" "$RET_ENTRY_PROBE_SQL")
  printf '      없는 종류로 물었을 때: %s건 (기대 0)\n' "${n:-?}"
  [ "${n:-x}" = "0" ] && ok "원장 건을 세는 잣대가 **살아 있다** (위 수를 믿을 수 있다)" \
    || bad "없는 종류를 물었는데 ${n:-?} 가 나왔다 — **질의가 깨졌다.** 위 수도 못 믿는다"

  # ── ⑲ 🔴 **재고관리가 답하는가** — 이번엔 올라가지 않지만 **빼지 않는다**
  say ""
  say "── ⑲ 🔴 **재고관리가 답하는가** (🔵 이번 판에 **안 올라가는 집**이지만 뺄 수 없다)"
  say "🔴 **73번에서 그대로 가져왔습니다.** 그 집은 이번에 안 올라가지만, **어제 올라간**"
  say "   **A/S 의 부품 반환이 그 집의 통로를 부릅니다** — 거기가 죽으면 [반환 요청] 창이"
  say "   **빈 목록**이 되고 올려도 **거절**됩니다."
  say "🔵 **SITES 표에는 그 집이 없으므로 포트를 여기 박았습니다** — 73-deploy.sh 는"
  say "   표에서 꺼냈습니다(거기서는 올라가는 집이었습니다)."
  pt=13800
  c=$(http_code "$pt")
  printf '      재고관리 127.0.0.1:%s → %s\n' "$pt" "${c:-못 읽음}"
  if http_ok "${c:-}"; then ok "재고관리가 답한다 ($c — 3xx 는 로그인으로 보내는 것이다)"
  else bad "재고관리가 $c 를 돌려준다 — 200 이나 3xx 를 기대했다"; fi
  say "🔴 **이 줄이 ✗ 면 이번 배포 탓이 아닙니다** — 그 집은 한 줄도 안 건드렸습니다."
  say "   🔵 1-ㄷ 의 상자 목록과 함께 보세요(거기서도 그 집이 도는지 잽니다)."

  # ══════════════════════════════════════════════════════════════════
  # ── 🔴🔴 여기부터 **74번 고유** — DATA 분류가 서는 자리 (⑳·㉑)
  # ══════════════════════════════════════════════════════════════════
  say ""
  say "══ 🔴🔴 **여기부터 74번 고유입니다 — 첨부 분류 ${ENUM_VALUE}**"
  say "🔴 **둘의 성질이 다릅니다:**"
  say "   ⑳ **${ENUM_VALUE} 분류로 올라간 첨부 수** — 🔵 **전후 둘 다 0 이 정상**입니다"
  say "      (그 분류가 지금 생깁니다). ✗ 를 안 냅니다."
  say "   ㉑ **enum 에 ${ENUM_VALUE} 가 있는가** — 🔴 **적용 전 0 · 뒤 1 로 뒤집힙니다.**"
  say "      ✗ 를 안 냅니다(2-ㄱ-4 가 단계로 갈라서 판정합니다 — 여기는 **세기만** 합니다)."
  say "🔴 **잣대 검사 둘만 ✗ 를 냅니다** — 없는 분류로 물어 0 · 없는 라벨로 물어 0."

  # ── ⑳ 🔴 **DATA 분류로 올라간 첨부** — 🔵 **운영에는 0건일 것이다**
  say ""
  say "── ⑳ 🔴 **${ENUM_VALUE} 분류로 올라간 첨부** (🔵 **운영에는 0건일 것입니다**)"
  say "🔴🔴 **0 이 정상입니다 — 이 분류가 지금 생깁니다.** 그러면 눈 확인에서 그 분류의"
  say "   파일이 **한 장도 안 보이는 것이 맞습니다.** 「고장」으로 읽지 마세요."
  say "🔵 **category 는 enum 이라 ::text 로 바꿔 묻습니다** — 그 덕에 **적용 전에도**"
  say "   **질의가 돕니다**(그 값이 enum 에 없어도 22P02 로 거절되지 않고 0 이 나옵니다)."
  say "   🔴 ::text 를 빼면 **적용 전에 거절되고**, 그 빈 결과가 진짜 결함처럼 보입니다."
  say "🔴 **올린 뒤에는 늡니다** — 사람이 그 분류로 올리는 순간부터입니다."
  adata=$(pgn "$ATT_BOX" "$ATT_DB" "$ATT_DATA_SQL")
  adataall=$(pgn "$ATT_BOX" "$ATT_DB" "$ATT_DATA_ALL_SQL")
  alive=$(pgn "$ATT_BOX" "$ATT_DB" "$ATT_LIVE_SQL")
  printf '      %s 분류 첨부 — 휴지통 밖 %s장 · 휴지통까지 %s장 (참고값 없음 · 🔵 **0 이 정상**)\n' \
    "$ENUM_VALUE" "${adata:-?}" "${adataall:-?}"
  printf '      거르개를 걷었을 때(휴지통 밖 전부): %s장 (🔴 위 %s 보다 **크거나 같아야** 한다)\n' \
    "${alive:-?}" "${adata:-?}"
  if [ -z "${adata:-}" ] || [ -z "${adataall:-}" ] || [ -z "${alive:-}" ]; then
    hm "못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
    say "      🔵 $ATT_TABLE 이 있는지, $ATT_DB 에 닿는지 보세요."
  else
    ok "${ENUM_VALUE} 분류 첨부를 값으로 쟀다 (휴지통 밖 ${adata}장 · 전체 ${adataall}장)"
    if [ "${adata}" = "0" ]; then
      say "      🔵 **0 입니다 — 올리기 전이라면 맞습니다.** 아직 아무도 그 분류로 안 올렸습니다."
      say "         🔴 그러면 **눈 확인에서 그 분류의 파일이 안 보이는 것이 정상**입니다."
      say "            표본을 만들려면 수리 건에서 파일 하나를 ${ENUM_VALUE} 분류로 올려 보세요."
    else
      say "      🔵 **${adata}장입니다** — 사람이 이미 그 분류를 쓰기 시작했다는 뜻이고 정상입니다."
    fi
    if [ "${adataall:-0}" -lt "${adata:-0}" ] 2>/dev/null; then
      bad "전체(${adataall})가 휴지통 밖(${adata})보다 적다 — **품어야 한다.** 질의가 깨졌다"
      doubt
    else
      ok "전체가 휴지통 밖을 품는다 (${adataall} ≥ ${adata} — 두 질의가 같은 집합을 보고 있다)"
    fi
    if [ "${alive:-0}" -lt "${adata:-0}" ] 2>/dev/null; then
      bad "거르개를 걷었는데 수가 **줄었다** (${alive} < ${adata}) — 질의가 깨졌다"
      doubt
    else
      ok "거르개를 걷으면 수가 줄지 않는다 (${alive} ≥ ${adata} — 거르개가 실제로 거르고 있다)"
    fi
  fi
  # 🔴 **잣대가 살아 있는가** — 없는 분류로 물어 0 이 나오는지 본다(enum 이라 ::text).
  n=$(pgn "$ATT_BOX" "$ATT_DB" "$ATT_PROBE_SQL")
  printf '      없는 분류로 물었을 때: %s장 (기대 0)\n' "${n:-?}"
  [ "${n:-x}" = "0" ] && ok "첨부 분류를 세는 잣대가 **살아 있다** (위 수를 믿을 수 있다)" \
    || bad "없는 분류를 물었는데 ${n:-?} 가 나왔다 — **질의가 깨졌다.** 위 수도 못 믿는다"

  # ── ㉑ 🔴 **enum 에 DATA 가 있는가** — 🔴 단계로 뒤집힌다
  say ""
  say "── ㉑ 🔴 **enum(${ENUM_NAME}) 에 ${ENUM_VALUE} 가 있는가** — 🔴 **적용 전 0 · 뒤 1**"
  say "🔴 **--count 를 올리기 전과 뒤에 한 번씩 돌려 이 줄을 맞대세요** — 이 배포에서"
  say "   **DB 가 달라지는 자리는 여기 하나뿐**입니다."
  say "🔵 **같은 줄에서 반대쪽도 셉니다** — ${ENUM_BEFORE} 는 **늘 1** 이어야 합니다."
  say "   🔴 그것이 0 이면 **엉뚱한 형을 보고 있거나** 라벨이 사라진 것입니다."
  say "🔵 **라벨 총수**(적용 전 $ENUM_LABELS_WAS · 뒤 $ENUM_LABELS_WANT)와 **자리**(DATA 가 OTHER 앞인가)도 함께 찍습니다."
  say "🔴 **이 절은 ✗ 를 안 냅니다** — 판정은 2-ㄱ-4 가 **단계로 갈라서** 합니다."
  eh2=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_HAS_SQL")
  eb2=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_BEFORE_SQL")
  ec2=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_COUNT_SQL")
  eo2=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_ORDER_SQL")
  printf '      [%s] 가 있나 %s (적용 전 0 · 뒤 1) · [%s] 가 있나 %s (늘 1)\n' \
    "$ENUM_VALUE" "${eh2:-?}" "$ENUM_BEFORE" "${eb2:-?}"
  printf '      라벨 총수 %s (적용 전 %s · 뒤 %s) · [%s] 가 [%s] 앞인가 %s (적용 뒤 1)\n' \
    "${ec2:-?}" "$ENUM_LABELS_WAS" "$ENUM_LABELS_WANT" "$ENUM_VALUE" "$ENUM_BEFORE" "${eo2:-?}"
  if [ -z "${eh2:-}" ] || [ -z "${ec2:-}" ]; then
    hm "못 잰 것이 있습니다 — 🔴 **빈 결과는 삼켜진 오류일 수 있습니다.** 사람이 보세요"
  else
    ok "enum 의 라벨을 값으로 쟀다 ([$ENUM_VALUE] ${eh2} · 총 ${ec2}개)"
    if [ "${eh2}" = "0" ]; then
      say "      🔵 **0 입니다 — --migrate 전이라면 맞습니다.**"
      say "         🔴 그러면 **눈 확인에서 분류 목록에 ${ENUM_VALUE} 가 안 보이는 것이 정상**입니다."
    else
      say "      🔵 **1 입니다 — --migrate 가 돌았다는 뜻입니다.** 분류 목록에 ${ENUM_VALUE} 가 섭니다."
    fi
  fi
  # 🔴 **잣대가 살아 있는가** — 없는 라벨을 물어 0 이 나오는지 본다.
  n=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_PROBE_SQL")
  printf '      없는 라벨을 물었을 때: %s (기대 0)\n' "${n:-?}"
  [ "${n:-x}" = "0" ] && ok "enum 라벨을 세는 잣대가 **살아 있다** (위 값을 믿을 수 있다)" \
    || bad "없는 라벨을 물었는데 ${n:-?} 가 나왔다 — **질의가 깨졌다.** 위 값도 못 믿는다"
}

if [ "$MODE" = "--count" ]; then
  effect_counts
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '%s\n' "🔵 --count 는 **아무것도 안 바꿉니다.** 올리기 전과 뒤에 한 번씩 돌려 맞대세요."
  printf '%s\n' "   🔴🔴 **이 배포에서 달라지는 자리는 ㉑ 하나뿐입니다** — enum 에 ${ENUM_VALUE} 가"
  printf '%s\n' "      적용 전 **0** 에서 뒤 **1** 이 됩니다. 🔵 라벨 총수도 ${ENUM_LABELS_WAS} → ${ENUM_LABELS_WANT} 입니다."
  printf '%s\n' "   🔴 **⓪~⑲ 과 ⑳ 은 전부 같은 수가 나오는 것이 정상**입니다 — 이 배포는"
  printf '%s\n' "      자료를 한 글자도 안 바꾸고 **칸도 하나도 안 더합니다.**"
  printf '%s\n' "   🔴 **올린 뒤에 늘 수 있는 것이 넷입니다** — ⑭·⑯·⑱(반환 · 어제 올라간 기능)과"
  printf '%s\n' "      **⑳(${ENUM_VALUE} 분류 첨부)**. 사람이 그것을 쓰기 시작하는 순간부터이고,"
  printf '%s\n' "      **그것이 그 기능들이 도는 증거**이지 사고가 아닙니다."
  printf '%s\n' "      🔵 ⑭ 가 늘면 ⑰ 이 **줄어듭니다**(돌려준 만큼 남은 수량이 빠집니다)."
  printf '%s\n' "   🔴 **⑳·⑭·⑰·⑱ 의 수를 먼저 적어 두세요** — 0 이면 눈 확인에서"
  printf '%s\n' "      **아무것도 안 보이는 것이 정상**이고, 그것을 모르면 「고장」으로 읽습니다:"
  printf '%s\n' "        ⑳ ${ENUM_VALUE} 분류 첨부 0 → 그 분류의 파일이 **한 장도 없다** (**지금은 이것이 맞다**)"
  printf '%s\n' "        ⑭ 반환 신청 0   → 재고의 신청 목록에 반환이 한 줄도 없다"
  printf '%s\n' "        ⑰ 돌려줄 건 0   → A/S 의 [반환 요청] 창이 **빈 목록**이다"
  printf '%s\n' "        ⑯ 반환 완료 0   → 종에 「부품 반환이 완료되었습니다」가 안 뜬다"
  printf '%s\n' "        ⑱ 반환 원장 0   → [기록 내역]에서 머리글이 달라지는 줄이 **한 줄도 없다**"
  printf '%s\n' "   🔴 **⑮(반출 신청)가 달라졌으면 사람이 보세요** — 반환과 **같은 표**라서"
  printf '%s\n' "      거기까지 움직였다면 반출 쪽을 건드린 것입니다."
  printf '%s\n' "   🔵 ⓪·⓪-2·⑥~⑲ 과 ⑰-2 는 **지난 판들이 올린 것을 보는 자리**입니다 —"
  printf '%s\n' "      🔴 **⑭~⑲(재고 쪽 여섯)을 하나도 안 뺐습니다.** 그 기능이 **어제 올라가"
  printf '%s\n' "      운영에서 돌고 있어** 뒷걸음을 봐야 합니다."
  [ "$FAIL" = "0" ] && [ "$UNK" = "0" ] && exit 0
  exit 1
fi

if [ "$MODE" = "--check" ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s   · 단계 %s · DB %s · 볼륨 %s · 안 바뀌는 넷 %s\n' \
    "$PASS" "$FAIL" "$UNK" "$PHASE" "${DBPHASE:-?}" "${VOLPHASE:-?}" "$DBKEEP"
  printf '\n%s\n' "🔵 --check 는 **아무것도 안 바꿨습니다.**"
  printf '%s\n' "   다음: tar **둘**과 **묶음 하나**를 보낸 뒤 --preload → --check → --migrate → --go"
  printf '%s\n' "   🔴 **--tools 는 없습니다** — 이번 판은 마이그레이션이 **1건**이라 그"
  printf '%s\n' "      자리가 **--migrate** 입니다: 덤프 **하나**를 뜨고 · **묶음을 볼륨에 풀고**"
  printf '%s\n' "      (${AS_VOL_SQL_WAS} → ${AS_VOL_SQL_WANT}) · **도구 태그 하나**를 갈고 · db:preflight 로 **대기 1건**을"
  printf '%s\n' "      값으로 받고 · db:migrate 를 돌린 뒤 **수를 다시 세고** · **enum 에"
  printf '%s\n' "      ${ENUM_VALUE} 가 생겼는지**를 봅니다. 🔴 **거기서 DB 가 바뀝니다.**"
  printf '%s\n' "   🔴🔴 **묶음을 꼭 보내세요** — incoming 에 **2026-11-25 의 134장짜리**가 아직"
  printf '%s\n' "      있습니다. 안 보내면 그것이 풀려 적용이 **0건으로 조용히** 끝납니다."
  printf '%s\n' "      🔵 이름이 같아 scp 가 덮어씁니다 — 3-ㄴ 이 md5 로 가릅니다."
  printf '%s\n' "   🔵 **이번 판은 집이 하나입니다** — --go 가 앱 **하나**만 띄웁니다."
  printf '%s\n' "   🔴 ✗ 가 났으면 **검사가 틀렸나를 먼저 보세요** — 기대값이 틀릴 확률이"
  printf '%s\n' "      배포만큼 높습니다. 기대값의 출처는 이 파일 머리말에 적혀 있습니다."
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
#      그리고 **A/S 와 포털이 drizzle 에서 반대다.** 한 잣대로 재면 가짜 ✗ 가 난다.
#   🔵 넷째 인자는 **판정에 안 쓰는 곁들이 값**이다.
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
    say "      🔵 **검사 자신을 먼저 의심하세요.** 🔴 **이 파일의 표식은 번들에서 한 번도**"
    say "         **안 세어 봤습니다** — 73-build.sh 가 굽기 전에 쓰였고, **--preload 가**"
    say "         **처음** 세는 자리입니다(71번은 구운 뒤 열여덟을 다 세어 적었습니다)."
    say "      🔵 71번이 **구운 번들에서** 확인해 둔 것(참고): 뒷걸음 열 중 아홉이 ≥1 이고"
    say "         shareDocRelativePath 는 **23개**였습니다. **뒷걸음이 0 이면 진짜 결함**입니다."
    say "      🔴 **기능 표식이 0 이면** 그것이 **객체 칸 이름**(autoAdvancedOnPoIssuedDate)인지"
    say "         **문자열 리터럴**(NO_WAITING_REPAIR_STEP)인지 보세요 — 뒤쪽이 0 이면"
    say "         **그 코드가 안 담긴 것**이고, 앞쪽만 0 이면 **minify 가 칸 이름까지 줄인**"
    say "         **것**입니다(그때는 이미지가 아니라 **이 검사**를 고칩니다)."
    say "      🔴 **그 글자가 한글이면 1-ㅂ 절부터 보세요** — ASCII 표식이 ✓ 인데"
    say "         한글만 0 이면 그것은 **검사 탓**입니다(이미지를 되돌리지 마세요)."
    say "      🔴 **코드 줄에서 따온 글자는 번들에 안 남습니다** — 지역 이름은 minify 가"
    say "         갈아 치우고 export 이름은 웹팩이 줄입니다(part.drawingNo, part.note 가"
    say "         71번에서 그 실물이었습니다 — 소스 1줄 · 번들 0/0)."
    if [ -n "${4:-}" ] && isnum "${ds:-}" && isnum "${dt:-}" && [ "$((ds + dt))" -ge 1 ]; then
      say "      🔴 **곁들이 글자는 1 이상입니다** — 이미지가 통째로 비어 있지는 않습니다."
      say "         🔵 이 판의 곁들이는 **export 이름**이라 **남는 것이 오히려 뜻밖**입니다."
      say "         🔵 올리지 말고 개발 PC 에서 다시 재세요(73-build.sh --verify) —"
      say "            검사 쪽이 틀린 것이면 **다시 구울 일이 아닙니다.**"
    else
      say "      🔴 **곁들이 글자도 0 입니다** — 옛 소스가 담긴 이미지일 수 있습니다."
      say "         🔵 다만 이 판의 곁들이는 **export 이름**이라 **멀쩡한 판에서도 0 일 수**"
      say "            **있습니다** — 곁들이 0 만으로 결함이라 단정하지 마세요."
    fi
  fi
}

# 🔵 **판정에 안 쓰고 찍기만 하는 곁들이.**
#    🔴 이 판의 곁들이 둘은 **export 이름**이라 번들에 남는지 모른다(웹팩이
#       production 에서 줄인다) — 그래서 ✗ 를 안 내고 값만 남긴다.
#       🔵 다음 판이 「그때 번들에 남았나」를 이 로그에서 읽을 수 있다
#          (71번이 TONE_COUNT 로 같은 일을 했고, 그 값은 **0** 이었다).
bundle_note() { # 1 태그 2 글자 3 사람이 부르는 말
  local v s t
  v=$("$DOCKER" run --rm -e M="$2" --entrypoint sh "$1" -c \
    'printf "%s %s\n" "$(grep -rlF "$M" /app/.next/server 2>/dev/null | wc -l)" "$(grep -rlF "$M" /app/.next/static 2>/dev/null | wc -l)"' </dev/null 2>/dev/null | tr -d '\r')
  s=$(printf '%s' "$v" | awk '{print $1}'); t=$(printf '%s' "$v" | awk '{print $2}')
  printf '        [%s] — server %s개 · static %s개 (🔵 **판정에 안 씀** — %s)\n' "$2" "${s:-?}" "${t:-?}" "$3"
}

# 🔴 목록 하나를 이미지 안에서 한 장씩 묻는다 — **없는 경로 하나를 함께** 묻는다.
#    🔴 set -f 로 글롭을 끈다. A/S 목록에는 **괄호·대괄호가 든 경로가 둘** 있다
#       (이번 범위 밖에서 일부러 끌어온 잣대 두 장 — AS_KEY_FILES 의 주석).
ask_files() { # 1 태그 2 목록(줄바꿈) 3 기대 수 4 사람이 부르는 말
  local v got seen probe
  v=$("$DOCKER" run --rm -e DSS_FILES="$2" -e DSS_MISS="$PROBE_MISS" --entrypoint sh "$1" -c \
    'set -f; printf "%s\n%s\n" "$DSS_FILES" "$DSS_MISS" | while IFS= read -r f; do [ -n "$f" ] || continue; if [ -f "/app/$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' </dev/null 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/          /'
  seen=$(printf '%s\n' "$v" | grep -c '^\(yes\|no \)' || true)
  got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
  probe=$(printf '%s\n' "$v" | grep -c "^no  $PROBE_MISS" || true)
  printf '        %s — 본 것 %s · 있는 것 %s (기대 %s · %s) · 없는 경로가 no 로 나왔나 %s(기대 1)\n' \
    "$4" "${seen:-0}" "${got:-0}" "$(( $3 + 1 ))" "$3" "${probe:-0}"
  if [ "${probe:-0}" != "1" ]; then
    bad "**없는 경로가 no 로 안 나왔다** — 「무조건 yes」인 검사다. 위 yes 도 못 믿는다"
  elif [ "${seen:-0}" = "$(( $3 + 1 ))" ] && [ "${got:-0}" = "$3" ]; then
    ok "$4 ${3}장이 다 담겼다 (표본이 비지 않았다)"
  else
    bad "$4 — 본 것 ${seen:-0} · 있는 것 ${got:-0} 다 — $3 을 기대했다"
    say "      🔴 본 것이 모자라면 **목록을 넘기는 길이 끊긴 것**(글롭 함정)이고,"
    say "         있는 것만 모자라면 **옛 소스가 담긴 이미지**입니다."
  fi
}

preload_inside() {
  step "🔎 들여온 이미지 **안**을 센다 — 겉이 아니라 결과"
  say "🔴 「실었다」와 「쓸 만한 이미지다」는 다른 말입니다."
  # 🔴 **몇 개를 실제로 봤는지 센다.** 고리가 한 바퀴만 돌고 끝나도 ✗ 0 으로
  #    통과할 수 있다. 🔵 이번 판은 집이 하나라 티가 안 난다 — 🔴 **그래서 관문을
  #    더 꼼꼼히 남겼다**(73번은 집이 둘이라 그 결함이 바로 드러났다).
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
    # 🔴🔴 **public/ 의 기대값이 집마다 다르다**(PUBLIC_WANT 의 주석).
    #    A/S 는 **9개쯤** 있어야 하고, 재고는 **있는데 비어 보이는 것이 정상**이다
    #    (.gitkeep 한 장뿐 — ls -1 은 숨은 파일을 안 센다). 🔴 A/S 잣대를 재고에
    #    들이대면 **멀쩡한 이미지가 ✗** 다(62번이 그 가짜 ✗ 를 냈고 69번이 고쳤다).
    PR=$(row_by_key "$PUBLIC_WANT" "$K"); PW=$(field "$PR" 2); PNW=$(field "$PR" 3); PMIN=$(field "$PR" 4)
    v=$(dock "$NEW" -c 'if [ -d /app/public ]; then printf "yes %s\n" "$(ls -1 /app/public 2>/dev/null | wc -l)"; else printf "no 0\n"; fi')
    pst=$(printf '%s' "$v" | awk '{print $1}'); pn=$(printf '%s' "$v" | awk '{print $2}')
    printf '        /app/public: %s (파일 %s개 · 기대 %s · 참고 %s개 · 판정 최솟값 %s)\n' \
      "${pst:-못 읽음}" "${pn:-?}" "${PW:-?}" "${PNW:-?}" "${PMIN:-?}"
    if [ "${pst:-}" != "${PW:-}" ]; then
      bad "$NAME 의 /app/public 이 ${pst:-못 읽음} 다 — ${PW:-?} 를 기대했다"
      say "      🔵 없으면 정적 파일이 404 가 되고 COPY 가 멈춘 것입니다(새 사이트에서 걸리는 셋 중 하나)."
    elif [ "${pn:-0}" -ge "${PMIN:-1}" ] 2>/dev/null; then
      if [ "${PMIN:-1}" = "0" ]; then
        ok "$NAME public/ 폴더가 있다 (${pn}개 — 🔵 **이 집은 비어 보이는 것이 정상**입니다)"
        say "      🔵 .gitkeep 한 장뿐이고 ls -1 은 숨은 파일을 안 셉니다 — A/S 의 9개를"
        say "         여기 들이대면 **가짜 ✗** 가 납니다(69-deploy.sh 의 그 자리)."
      else
        ok "$NAME public/ 이 담겼다 (${pn}개 · 참고 ${PNW:-?}개)"
      fi
    else
      bad "$NAME public/ 은 있는데 파일이 ${pn:-?}개다 — ${PMIN:-1}개 이상(참고 ${PNW:-?})을 기대했다"
    fi
    # 🔴 **표식을 APPMARKS 표에서 그 집 것만 꺼내 돈다** — 집마다 다르다.
    #    🔵 이 판은 기능 4 + 뒷걸음 14 + 곁들이 3 이고 **판정에 쓰는 것은 18** 이다.
    SIDE=$(rows_of "$APPMARKS" | while IFS='|' read -r R KD M N; do
             [ "$R" = "$K" ] && [ "$KD" = "side" ] && printf '%s\n' "$M"; done | head -1)
    MKRAN=0
    while IFS='|' read -r R KD M N; do
      [ -n "${R:-}" ] || continue
      [ "$R" = "$K" ] || continue
      case "$KD" in
        feature) MKRAN=$((MKRAN+1)); bundle_mark "$NEW" "$M" "$NAME 번들에 **이번 판의 글자**가 있다 ($N)" "${SIDE:-}" ;;
        keep)    MKRAN=$((MKRAN+1)); bundle_mark "$NEW" "$M" "$NAME 에 **지난 판이 올린 글자**가 그대로 있다 ($N)" ;;
        side)    bundle_note "$NEW" "$M" "$N" ;;
      esac
    done <<ENDBM
$(rows_of "$APPMARKS")
ENDBM
    # 🔴 **집마다 기대 수가 다르다** — 한 수로 뭉뚱그리면 둘 중 하나가 늘 ✗ 다.
    #    🔵 이 판은 집이 하나지만 **꼴을 그대로 뒀다**(73번은 A/S 14 · 재고 6 이었다).
    if [ "$K" = "as" ]; then MKWANT=$AS_MARKS_WANT; else MKWANT=0; fi
    printf '        이 집에서 **판정에 쓴 표식** %s개 (기대 %s)\n' "$MKRAN" "$MKWANT"
    if [ "$MKRAN" = "$MKWANT" ]; then
      ok "$NAME 번들 표식 ${MKWANT}개를 다 돌았다 (표본이 비지 않았다)"
      say "      🔴🔴 **ㄱ갈래(${ENUM_VALUE})는 여기서 안 가려집니다** — minify 가 공백을 지워"
      say "         번들에는 소스 꼴이 안 남습니다. 그 갈래는 **도구 이미지 쪽**이 가립니다"
      say "         (도구 표식 첫 줄과 공용 스키마의 DATA 줄)."
      say "      🔵 위 **곁들이 둘**(공백 있는 꼴 · 없는 꼴)의 수를 **다음 판이 읽습니다.**"
    else
      bad "$NAME 번들 표식을 ${MKRAN}개만 돌았다 — ${MKWANT}개를 기대했다. APPMARKS 표가 깨졌다"
    fi
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
    v=$(dock "$NEW" -c "test -d /app/node_modules/drizzle-kit && echo yes || echo no")
    printf '        /app/node_modules/drizzle-kit: %s (기대 yes)\n' "${v:-못 읽음}"
    [ "${v:-}" = "yes" ] && ok "$NAME 에 drizzle-kit 이 있다" \
      || bad "$NAME 에 drizzle-kit 이 없다 — db:preflight·db:migrate 가 그 자리에서 죽는다"
    # 🔴🔴 **도구 표식이 집마다 둘이라 고리로 돈다** — 71번은 row_by_key 로 **한
    #    줄만** 꺼냈다. 그 함수는 맞는 줄을 **이어 붙여** 돌려주므로 두 줄이면
    #    글자가 통째로 깨진다. 🔴 **몇 개를 돌았는지 끝에서 단언한다**(고리가 한
    #    바퀴만 돌면 **한 갈래가 아무 검사도 안 받는다**).
    #    🔵 경로를 상대로 넘기고 /app/ 를 컨테이너 안에서 붙인다(⑬).
    #    🔵 yes/no 가 아니라 **센 줄 수**를 받는다 — 0 과 「못 읽음」을 가른다.
    TMRAN=0
    while IFS='|' read -r TK TMK TMF TMW; do
      [ -n "${TK:-}" ] || continue
      [ "$TK" = "$K" ] || continue
      TMRAN=$((TMRAN+1))
      v=$("$DOCKER" run --rm -e M="$TMK" -e F="$TMF" --entrypoint sh "$NEW" -c \
        'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s\n" "$(grep -cF -- "$M" "$p")"; else printf "missing 0\n"; fi' </dev/null 2>/dev/null | tr -d '\r')
      tst=$(printf '%s' "$v" | awk '{print $1}'); tn=$(printf '%s' "$v" | awk '{print $2}')
      printf '        도구 표식 [%s] in %s — 파일 %s · 그 글자 %s줄 (기대 hit · %s)\n' \
        "$TMK" "$TMF" "${tst:-못 읽음}" "${tn:-?}" "${TMW:-1}"
      if [ "${tst:-}" = "hit" ] && [ "${tn:-0}" -ge 1 ] 2>/dev/null; then
        ok "$NAME — **그 갈래의 코드가 담겼다** (${tn}줄)"
        [ "${tn}" = "${TMW:-1}" ] || hm "그 글자가 ${tn}줄입니다 — ${TMW:-1} 을 기대했습니다. 사람이 보세요"
      elif [ "${tst:-}" = "hit" ]; then
        bad "$NAME 에 그 글자가 **0줄**이다 — **옛 소스가 담긴 이미지다**"
      elif [ "${tst:-}" = "missing" ]; then
        bad "$NAME 에 그 파일 자체가 없다 — src/ 가 온전히 안 담겼다"
      else
        bad "$NAME 의 표식을 못 읽었다 (받은 값 [${v:-}])"
      fi
    done <<ENDTMIMG
$(rows_of "$TOOLMARKS")
ENDTMIMG
    printf '        이 이미지에서 돈 도구 표식 %s개 (기대 %s)\n' "$TMRAN" "$TOOLMARKS_PER_IMAGE_WANT"
    if [ "$TMRAN" = "$TOOLMARKS_PER_IMAGE_WANT" ]; then
      ok "도구 표식 ${TOOLMARKS_PER_IMAGE_WANT}개를 다 돌았다 (이 집의 두 자리를 다 가렸다)"
      say "      🔴 **A/S 는 「올리는 쪽」, 재고는 「받는 쪽」을 가립니다** — 한쪽만 ✓ 면"
      say "         **반쪽만 올라간 것**입니다. 두 이미지가 다 ✓ 여야 기능이 섭니다."
    else
      bad "도구 표식을 ${TMRAN}개만 돌았다 — ${TOOLMARKS_PER_IMAGE_WANT}개를 기대했다. **한 갈래가 아무 검사도 안 받았다**"
    fi
    # ── 🔴 여기부터 **집마다 갈린다** — 🔴🔴 **A/S 와 재고가 정반대인 자리가 셋**:
    #       drizzle(0장 ↔ 28장) · vendor(있어야 ↔ 없어야) · /templates(A/S 만).
    #    🔴 **한 가지로 뭉뚱그리지 마라** — 둘 중 하나가 반드시 가짜 ✗ 가 된다
    #       (69-deploy.sh 와 62-build.sh 가 같은 경고를 적어 두었다).
    case "$K" in
      astools)
        ask_files "$NEW" "$AS_KEY_FILES" "$AS_KEY_FILES_WANT" "A/S 의 핵심 파일"
        say "      🔵 그 열한 장 중 **끝의 셋이 글롭 잣대**입니다 — 하나는 범위 안(대괄호),"
        say "         둘은 범위 밖(괄호 · 괄호+대괄호)입니다. 길이 끊기면 **그 셋이 먼저"
        say "         no 로** 떨어져 「옛 소스가 담겼다」와 갈립니다."
        say "      🔵 **이번 범위에는 괄호가 0장**이라 괄호 잣대 둘을 범위 밖에서 끌어왔습니다."
        # 🔴 A/S 도구는 drizzle 을 **안 담아야** 한다 — 볼륨이 정본이다.
        n=$(dock "$NEW" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
        printf '        %s 안 .sql: %s장 (기대 0 — 볼륨이 정본이다)\n' "$IMG_MIGDIR" "${n:-?}"
        if isnum "${n:-}" && [ "${n:-1}" = "0" ]; then
          ok "$NAME 은 drizzle/ 이 **비어 있다**"
          say "      🔴🔴 **그래서 이번 판은 묶음을 보냅니다** — 0134 는 이미지로 안 갑니다."
          say "         운영의 볼륨이 ${AS_VOL_SQL_WAS} → ${AS_VOL_SQL_WANT}장이 되어야 합니다(2-ㄷ · --migrate)."
        else bad "$NAME 안에 .sql 이 ${n:-?}장 있다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다"; fi
        # 🔴 **공용 스키마** — 핀이 맞아도 **빈 서브모듈이 담길 수 있다**.
        #    🔵 이 일곱은 **전부 뒷걸음**이다. 🔴 **하나라도 빼지 마라.**
        #    🔴 **이번 판이 더한 것은 그 아래 줄이 따로 센다**(enum 의 DATA).
        v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c 'for pair in "portal_approval_delegations /app/vendor/dss-core/src/schema/portal-approval-delegations.ts" "portal-approval-delegations /app/vendor/dss-core/src/schema/index.ts" "fault_tags /app/vendor/dss-core/src/schema/repair-case-flowcharts.ts" "confirmed_at /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "confirmed_by /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "share_doc_relative_path /app/vendor/dss-core/src/schema/procedure-template-nodes.ts" "share_doc_relative_path /app/vendor/dss-core/src/schema/repair-case-flowchart-nodes.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' </dev/null 2>/dev/null | tr -d '\r')
        printf '%s\n' "$v" | sed 's/^/          /'
        g=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
        if [ "${g:-0}" = "7" ]; then
          ok "$NAME 에 **공용 스키마가 일곱 다 담겼다** (🔵 이 일곱은 전부 **뒷걸음**이다)"
          say "      🔵 index.ts 가 안 내보내면 도구가 그 표를 **못 찾습니다** — 2026-09-21 에"
          say "         운영에서 도구가 전부 죽은 그 자리입니다."
        else
          bad "$NAME 의 공용 스키마가 일곱 중 ${g:-0}개다 — **빈 서브모듈이나 옛 판이 담겼다**"
          say "      🔴 **뒤의 넷(confirmed_* · share_doc_*)만 no 면 서브모듈이 예순여섯째"
          say "         핀으로 되감긴 것**입니다 — 그 기능이 통째로 사라집니다."
        fi
        # 🔴🔴 **이번 판이 공용 스키마에 더한 것** — enum 의 DATA. (이 줄이 이번에 생겼다)
        #    🔴 **위 일곱 고리에 끼워 넣지 않았다** — 그 고리는 「공백 없는 낱말 쌍」을
        #       set -- 로 쪼개 읽어서 **따옴표가 든 글자를 못 넘긴다.** 그래서 도구 표식과
        #       **같은 길**(-e 로 넘기기)로 따로 묻는다.
        #    🔴🔴 **ㄱ갈래(DATA)가 이미지에 담겼는지 재는 자리가 여기와 도구 표식 둘뿐이다** —
        #       번들에는 그 갈래의 표식이 없다(APPMARKS 의 주석).
        v=$("$DOCKER" run --rm -e M='"DATA",' -e F=vendor/dss-core/src/schema/attachments.ts --entrypoint sh "$NEW" -c \
          'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s\n" "$(grep -cF -- "$M" "$p")"; else printf "missing 0\n"; fi' </dev/null 2>/dev/null | tr -d '\r')
        cst=$(printf '%s' "$v" | awk '{print $1}'); csn=$(printf '%s' "$v" | awk '{print $2}')
        printf '        공용 스키마의 enum 값 ["DATA",] in attachments.ts — 파일 %s · 그 글자 %s줄 (기대 hit · 1)\n' \
          "${cst:-못 읽음}" "${csn:-?}"
        if [ "${cst:-}" = "hit" ] && [ "${csn:-0}" -ge 1 ] 2>/dev/null; then
          ok "$NAME 에 **이번 판의 enum 값이 담겼다** (${csn}줄)"
          say "      🔴 그 값이 없으면 db:migrate 가 **${ENUM_VALUE} 를 모르는 스키마**로 돕니다."
        elif [ "${cst:-}" = "hit" ]; then
          bad "그 값이 **0줄**이다 — **옛 핀의 공용 스키마가 담겼다.** 올리지 마세요"
          say "      🔴 74-build.sh 의 3-ㄱ·3-ㅁ 을 다시 보세요 — 핀은 맞는데 담긴 것이 옛 것일 수 있습니다."
        elif [ "${cst:-}" = "missing" ]; then
          bad "attachments.ts 자체가 이미지에 없다 — vendor 가 온전히 안 담겼다"
        else
          bad "그 값을 못 읽었다 (받은 값 [${v:-}])"
        fi
        # 🔴🔴 **지운 파일 둘이 이미지에서도 사라졌는가** (이 절이 이번에 생겼다)
        #    🔴 **「있는가」만 재는 검사는 지우는 판을 못 막는다** — upload-file-name.ts 가
        #       이미지에 남아 있으면 **옛 소스를 구운 것**이다.
        #    🔵 **같은 줄에서 반대쪽도 센다** — 대신 선 파일은 **있어야** 한다.
        TGI_SEEN=0; TGI_OK=0
        while IFS='|' read -r TK GF RF; do
          [ -n "${TK:-}" ] || continue
          [ "$TK" = "$K" ] || continue
          TGI_SEEN=$((TGI_SEEN+1))
          v=$("$DOCKER" run --rm -e G="$GF" -e R="$RF" --entrypoint sh "$NEW" -c \
            'set -f; a=no; b=no; [ -f "/app/$G" ] && a=yes; [ -f "/app/$R" ] && b=yes; printf "%s %s\n" "$a" "$b"' </dev/null 2>/dev/null | tr -d '\r')
          ga=$(printf '%s' "$v" | awk '{print $1}'); gb=$(printf '%s' "$v" | awk '{print $2}')
          printf '        지운 것 [%s] %s (기대 no) · 대신 선 것 [%s] %s (기대 yes)\n' \
            "$GF" "${ga:-못 읽음}" "$RF" "${gb:-못 읽음}"
          if [ "${ga:-}" = "no" ] && [ "${gb:-}" = "yes" ]; then TGI_OK=$((TGI_OK+1))
          elif [ "${ga:-}" = "yes" ]; then
            bad "$GF 이 **이미지에 아직 있다** — 옛 소스를 구웠다. 올리지 마세요"
          else
            bad "$RF 이 **이미지에 없다** — 지운 자리를 대신할 파일이 안 담겼다"
          fi
        done <<ENDTGI
$(rows_of "$TOOLMARK_GONE")
ENDTGI
        printf '        지운 파일 검사 %s개 (기대 %s) · 맞는 것 %s\n' "$TGI_SEEN" "$TOOLMARK_GONE_WANT" "$TGI_OK"
        [ "$TGI_SEEN" = "$TOOLMARK_GONE_WANT" ] && [ "$TGI_OK" = "$TOOLMARK_GONE_WANT" ] \
          && ok "지운 파일 ${TOOLMARK_GONE_WANT}장이 이미지에서도 사라졌고 대신 선 파일이 다 담겼다" \
          || bad "본 것 ${TGI_SEEN} · 맞는 것 ${TGI_OK} 다 — ${TOOLMARK_GONE_WANT} 을 기대했다"
        # 🔵 양식이 이미지에 안 들어갔는가 — 들어갔으면 도장과 계좌번호가 구워진 것이다.
        n=$(dock "$NEW" -c "ls /templates 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
        printf '        /templates 안 파일: %s개 (기대 0 — 양식은 볼륨으로 붙는다)\n' "${n:-?}"
        if isnum "${n:-}" && [ "${n:-1}" = "0" ]; then ok "양식이 이미지에 안 들어갔다"
        else bad "이미지 안에 /templates 가 ${n:-?}개 있다 — 도장·계좌번호가 구워졌다"; fi
        ;;
      # 🔵 **inventorytools 가지가 없다** — 재고가 이번 판에 안 올라간다(머리말 「왜 없는가」 ②).
      #    🔴 되살릴 때는 **73-deploy.sh:2800-2850 을 통째로** 가져와라. 거기서 A/S 와
      #       **정반대**인 자리가 셋이다: drizzle(0장 ↔ 28장) · vendor(있어야 ↔ 없어야) ·
      #       /templates(A/S 만 — 그 볼륨은 A/S 양식이고 재고와 아무 상관이 없다).
      #       🔴 그 집의 tests/ 는 **이미지에 없는 것이 정상**이다(.dockerignore).
    esac
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
# ── 5. --preload : tar 둘을 들여놓는다 ──────────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--preload" ]; then
  step "5. --preload — tar 둘을 싣는다 (🔴 **아직 안 갈아 끼운다**)"
  say "🔵 쓰는 것: NAS 의 도커 이미지 저장소뿐입니다. compose 도 DB 도 안 건드립니다."
  say "🔴 **묶음은 여기서 안 풉니다** — **--migrate** 가 풉니다(71번의 그 규율입니다)."
  say "   🔵 73번에는 「풀 묶음이 없습니다」라고 적혀 있었습니다 — 이번엔 있습니다."
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
  printf '%s\n' "   🔴 **묶음은 아직 안 풀었습니다** — --migrate 가 풉니다(볼륨 ${AS_VOL_SQL_WAS} → ${AS_VOL_SQL_WANT}장)."
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════
# ══ 덤프 · compose 사본 ═══════════════════════════════════════════════
# ══════════════════════════════════════════════════════════════════════
#   🔴 **하나가 뜬다**(73번은 둘이었다 — 거기는 재고도 올라갔다). **올라가는 집은
#      A/S 하나**이고, 🔴🔴 **이번 판은 그 집의 DB 가 실제로 바뀐다** — 이 덤프가
#      **되돌릴 유일한 길**이다.
#   🔵 **재고 DB 는 안 뜬다** — 그 집은 앱도 DB 도 이번에 한 글자도 안 바뀐다
#      (71번이 포털에 대해 적어 둔 그 문장이 이번에는 재고에 그대로 적용된다).
#   🔴 **고리 꼴로 적었다**(62번의 make_dumps 꼴) — 집이 늘면 줄만 더한다.
#      🔵 **못 뜨면 멈춘다** — 되돌릴 길부터 만드는 자리다.
DUMPS='
dss-pg-app|dss_as|A/S관리
'
DUMPS_WANT=1
make_dump() {
  mkdir -p "$BKDB" 2>/dev/null; chmod 777 "$BKDB" 2>/dev/null
  say "🔵 덤프 자리: $BKDB (🔴 받을 폴더는 777 이어야 scp·컨테이너가 쓸 수 있습니다)"
  DUMP_N=0; DUMP_SEEN=0
  while IFS='|' read -r DBOX DNAME DLABEL; do
    [ -n "${DBOX:-}" ] || continue
    DUMP_SEEN=$((DUMP_SEEN+1))
    f="$BKDB/$DNAME-$DUMP_VER-$STAMP.dump"
    printf '    뜨는 중 %s (%s) …\n' "$DNAME" "$DLABEL"
    # 🔵 pg_dump 도 stdin 을 안 읽는다 — -i 를 떼고 </dev/null 을 붙인다.
    #    🔴 **고리 안이라 더 중요하다** — stdin 을 빨아들이면 고리가 한 바퀴만 돈다.
    if "$DOCKER" exec "$DBOX" sh -c "pg_dump -U \"\$POSTGRES_USER\" -d $DNAME -Fc" </dev/null > "$f" 2>/dev/null; then
      sz=$(stat -c %s "$f" 2>/dev/null)
      if isnum "${sz:-}" && [ "${sz:-0}" -gt 1000 ]; then
        ok "$DNAME 덤프 ${sz}바이트 — $f"; DUMP_N=$((DUMP_N+1))
      else
        bad "$DNAME 덤프가 ${sz:-0}바이트다 — **쓸 수 없는 덤프다**"
      fi
    else
      bad "$DNAME 덤프를 못 떴다 — $DBOX 가 도는지 보세요"
    fi
  done <<ENDDUMP
$(rows_of "$DUMPS")
ENDDUMP
  printf '  뜬 덤프 %s / %s (본 줄 %s)\n' "$DUMP_N" "$DUMPS_WANT" "$DUMP_SEEN"
  if [ "$DUMP_SEEN" != "$DUMPS_WANT" ]; then
    bad "덤프 표를 ${DUMP_SEEN}줄만 돌았다 — ${DUMPS_WANT}줄을 기대했다. **고리가 안 돌았다**"
    return 1
  fi
  [ "$DUMP_N" = "$DUMPS_WANT" ] || return 1
  ok "되돌릴 길이 있다 (🔴 **이번 판은 DB 가 실제로 바뀐다** — 이것이 유일한 길이다)"
  return 0
}

backup_compose() {
  mkdir -p "$D/backups" 2>/dev/null
  if cp -a "$CF" "$BK"; then ok "compose 사본을 떴다 — $BK"
  else stop "compose 사본을 못 떴다 — **아무것도 안 바꿨습니다.**"; fi
}

# ══════════════════════════════════════════════════════════════════════
# ══ 🔴 묶음을 볼륨에 푼다 — **A/S 만 그렇다** (71번에서 되살렸다) ════
# ══════════════════════════════════════════════════════════════════════
#   🔴 **71-deploy.sh:2212-2259 에서 가져왔다.** 73번에는 이 함수가 **아예 없었다**
#      (그 판은 올릴 .sql 이 0건이었고, 「1건이라도 생기면 71번에서 되살려라」가
#      거기 적혀 있었다 — **그 날이 이번**이다).
#   🔴 A/S 도구의 /app/drizzle 은 **비어 있고**(2-ㄷ 가 값으로 쟀다) 운영에서는
#      거기에 이 폴더가 붙는다. 그래서 0134 는 **이 묶음으로만** 간다.
#      🔴 안 풀면 적용이 **0건으로 조용히** 끝나고 겉으로는 성공으로 보인다.
#   🔴 **폴더를 통째로 갈아 끼운다** — 그래서 묶음 안에 창 안 여덟이 .sql 과
#      스냅샷 짝으로 다 들어 있어야 한다(3-ㄴ 이 그것을 쟀다).
place_migs() {
  local U B s j t n
  if [ ! -f "$MIGTAR" ]; then
    s=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
    if [ "${s:-0}" = "$AS_VOL_SQL_WANT" ]; then
      ok "묶음이 없지만 볼륨이 이미 ${AS_VOL_SQL_WANT}장이다 (이미 풀었다 — 건너뛴다)"; return 0
    fi
    bad "묶음이 없고 볼륨도 ${s:-?}장이다 — $MIGTAR 를 보내세요"; return 1
  fi
  # 🔴🔴 **옛 묶음을 풀지 않는다** — 지문으로 먼저 가른다(이름이 같다).
  m5=$(md5sum "$MIGTAR" 2>/dev/null | awk '{print $1}')
  if [ "${m5:-x}" = "$OLD_MIGTAR_MD5" ]; then
    bad "🔴🔴 **그것은 2026-11-25 의 묶음이다**(134장) — 풀면 볼륨이 ${AS_VOL_SQL_WAS}장 그대로다"
    say "      scp -O as-migrations.tar.gz dss-nas:$INCOMING/  ← 이번 것을 보내세요"
    return 1
  fi
  U="$INCOMING/unpack-$STAMP"
  mkdir -p "$U" || { bad "푸는 자리를 못 만들었다"; return 1; }
  if ! tar -xzf "$MIGTAR" -C "$U"; then bad "묶음을 못 풀었다"; return 1; fi
  s=$(ls -1 "$U/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  j=$(grep -o '"idx"' "$U/drizzle/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  n=0
  for t in $AS_VOL_NEW; do
    a=$(ls -1 "$U/drizzle/${t}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
    b=$(ls -1 "$U/drizzle/meta/${t}"_snapshot.json 2>/dev/null | wc -l | tr -d ' ')
    [ "${a:-0}" = "1" ] && [ "${b:-0}" = "1" ] && n=$((n+1))
  done
  printf '    푼 것 — .sql %s장 · idx %s개 · 이번 장 %s/%s (기대 %s · %s · %s)\n' \
    "${s:-?}" "${j:-?}" "$n" "$AS_VOL_NEW_WANT" "$AS_VOL_SQL_WANT" "$AS_VOL_SQL_WANT" "$AS_VOL_NEW_WANT"
  if [ "${s:-x}" != "$AS_VOL_SQL_WANT" ] || [ "${j:-x}" != "$AS_VOL_SQL_WANT" ] || [ "${n}" != "$AS_VOL_NEW_WANT" ]; then
    bad "푼 것이 기대와 다르다 — **볼륨을 안 건드렸다**"
    say "      🔴 목록에 없는 .sql 은 drizzle 이 **아예 모릅니다**(적용이 0건으로 끝납니다)."
    say "      🔴 **옛 판의 묶음일 수 있습니다**(128·129·131·132·134장짜리). 3-ㄴ 을 보세요."
    return 1
  fi
  B="$D/backups/as-migrations-$DUMP_VER-$STAMP"
  if cp -a "$MIGDIR" "$B" 2>/dev/null; then ok "옛 볼륨을 치워 두었다 — $B"
  else hm "옛 볼륨 사본을 못 떴습니다 — 그래도 진행합니다(덤프가 있습니다)"; fi
  if ! cp -a "$U/drizzle/." "$MIGDIR/"; then bad "볼륨에 못 넣었다"; return 1; fi
  s=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  j=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  n=0
  for t in $AS_VOL_NEW; do
    a=$(ls -1 "$MIGDIR/${t}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
    b=$(ls -1 "$MIGDIR/meta/${t}"_snapshot.json 2>/dev/null | wc -l | tr -d ' ')
    [ "${a:-0}" = "1" ] && [ "${b:-0}" = "1" ] && n=$((n+1))
  done
  printf '    볼륨 — .sql %s장 · idx %s개 · 이번 장 %s/%s (기대 %s · %s · %s)\n' \
    "${s:-?}" "${j:-?}" "$n" "$AS_VOL_NEW_WANT" "$AS_VOL_SQL_WANT" "$AS_VOL_SQL_WANT" "$AS_VOL_NEW_WANT"
  if [ "${s:-x}" = "$AS_VOL_SQL_WANT" ] && [ "${j:-x}" = "$AS_VOL_SQL_WANT" ] && [ "${n}" = "$AS_VOL_NEW_WANT" ]; then
    ok "볼륨이 **${AS_VOL_SQL_WANT}장**이 됐다 ($AS_VOL_NEW 이 .sql·스냅샷 짝으로 들어왔다)"
    rm -rf "$U" 2>/dev/null
    return 0
  fi
  bad "볼륨이 .sql ${s:-?} · idx ${j:-?} · 이번 장 ${n} 다 — ${AS_VOL_SQL_WANT} 을 기대했다"
  return 1
}

# ══════════════════════════════════════════════════════════════════════
# ── 6. --migrate : 🔴🔴 **여기서 DB 가 바뀐다** (A/S 한 집 · 한 건) ──
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--migrate" ]; then
  step "6. --migrate — 🔴🔴 **여기서 DB 가 바뀐다** (A/S 한 집 · **한 건**)"
  say "🔴 **73·72·70·69번에는 이 자리가 --tools 였습니다**(마이그레이션 0건이라)."
  say "   71번의 --migrate 를 가져왔습니다 — 다만 71번은 **두 건 · 도구 둘**이었고"
  say "   이번은 **한 건 · 도구 하나**입니다."
  say "🔴 차례가 **뜻을 갖습니다**: 덤프 → compose 사본 → **묶음을 볼륨에 푼다** →"
  say "   **도구 태그를 간다** → db:preflight → db:migrate → **수를 다시 센다** →"
  say "   🔴 **enum 에 ${ENUM_VALUE} 가 생겼는지 본다.**"
  say "   🔴 묶음을 안 풀면 적용이 **0건으로 조용히** 끝납니다(31·39번)."
  say "   🔴 도구 태그를 안 갈면 **${ENUM_VALUE} 를 모르는 공용 스키마**로 돕니다."
  say "🔵 **다시 돌려도 안전합니다** — drizzle 은 이미 적용한 것을 건너뜁니다."
  say "🔵 **재고 DB 는 안 건드립니다** — 덤프도 안 뜹니다(그 집은 한 글자도 안 바뀝니다)."
  if [ "$DBPHASE" = "DONE" ] && [ "$PHASE_TOOL_NEW" = "$TOOLS_WANT" ]; then
    ok "DB 가 이미 $AS_VOL_SQL_WANT 이고 도구도 새 판이다 — 바꿀 것이 없다"
    printf '\n%s\n' "✅ 할 일이 없습니다. 다음은 --go 입니다."
    exit 0
  fi

  say ""
  say "── 6-ㄱ. 🔴 되돌릴 길부터 만든다 — **덤프 한 장**(dss_as)"
  say "🔴 **이번 판은 DB 가 실제로 바뀝니다** — 이 덤프가 되돌릴 **유일한 길**입니다."
  say "   🔴🔴 **PostgreSQL 은 enum 값을 지울 수 없습니다** — --rollback 이 DB 를 안"
  say "      되돌리는 까닭이 그것입니다(머리말의 모드 설명)."
  say "🔵 재고 DB(dss_inventory)는 안 뜹니다 — **한 글자도 안 바뀝니다**(73번은 떴습니다)."
  if ! make_dump; then stop "덤프를 못 떴습니다 — **아무것도 안 바꿨습니다.** 되돌릴 길부터 만드세요."; fi

  say ""
  say "── 6-ㄴ. compose 사본"
  backup_compose

  say ""
  say "── 6-ㄷ. 🔴 **A/S 마이그레이션 볼륨** — 묶음을 푼다 ($AS_VOL_SQL_WAS → $AS_VOL_SQL_WANT)"
  say "🔴 A/S 만 그렇습니다 — 도구 이미지 안의 /app/drizzle 은 비어 있고 그 자리에"
  say "   /volume1/dss/as-migrations 가 붙습니다."
  say "🔴🔴 **옛 묶음(2026-11-25 · 134장)이면 안 풉니다** — md5 로 먼저 가릅니다."
  if ! place_migs; then stop "볼륨을 못 올렸습니다 — DB 는 한 글자도 안 바꿨습니다."; fi

  say ""
  say "── 6-ㄹ. 🔴 **도구 태그를 간다**"
  say "🔴 **db:migrate 는 새 도구로 돌려야 합니다** — 옛 A/S 도구는 **${ENUM_VALUE} 가 없는**"
  say "   공용 스키마를 들고 있습니다(vendor/dss-core 가 이번에 움직였습니다)."
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
  say "🔴 **기대값이 「대기 1건」입니다**(71번은 2건 · 73번은 0건이었습니다). 0건이면"
  say "   볼륨을 안 풀었거나 이미 올린 것이고, 2건 이상이면 누가 .sql 을 더 넣은 것입니다."
  say "🔵 db:preflight 는 **읽기만 합니다**."
  say "🔴 여기서 **Cannot find module** 이 보이면 도구 이미지에 담긴 것이 모자랍니다"
  say "   (src/ 30장이 바뀐 판이라 그 길이 끊길 자리가 있습니다)."
  # 🔴 서비스 이름을 **여기 다시 적지 않는다** — TOOLS 표에서 꺼낸다.
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
    say "      🔴 위 글에 **대기 건수**가 적혀 있습니다. **1건이어야 합니다**($AS_VOL_NEW) —"
    say "         0 이면 볼륨을 안 풀었거나 이미 올린 것이고, 2 이상이면 **멈추고 알리세요.**"
    say "      🔵 그 한 장은 **enum 에 값을 더하기만** 합니다 — 사라질 자료가 없습니다."
    say "      🔴 **같은 판에서 그 값을 쓰지 않습니다**(3-ㄴ 이 INSERT·UPDATE 0 을 쟀습니다)."
  else
    bad "db:preflight 가 0 이 아니다 ($PRC)"
    say "      🔴 **Cannot find module 이 보이면** 도구 이미지에 담긴 것이 모자랍니다"
    say "         (vendor/dss-core 나 src/ 가 빠진 것입니다)."
    say "      🔴 그 밖이면 **볼륨에 사라질 자료가 있다는 뜻입니다** — 0134 에는 그럴"
    say "         문장이 없으니 **다른 것이 섞였습니다.**"
    say "      🔵 **도구 줄과 볼륨은 이미 갈았습니다.** 되돌리려면 compose 사본: $BK"
    stop "DB 는 아직 한 글자도 안 바꿨습니다. 앱도 안 건드렸습니다."
  fi

  say ""
  say "── 6-ㅂ. 🔴🔴 **db:migrate 를 돌린다 — 여기서 DB 가 바뀐다**"
  say "🔵 **A/S 한 집만 돕니다** — 나머지 네 집은 올릴 것이 0건이라 MIGS 표에 없습니다."
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
  say "── 6-ㅅ. 🔴🔴 **값으로 확인한다** — enum 에 ${ENUM_VALUE} 가 실제로 생겼는가"
  say "🔴 「마이그레이션 수가 늘었다」와 「값이 생겼다」는 **다른 말**입니다 —"
  say "   둘을 따로 재야 합니다(71번은 그 자리에서 **칸**을 쟀습니다)."
  say "🔵 **같은 줄에서 반대쪽도 셉니다** — ${ENUM_BEFORE} 는 늘 1 · 라벨 총수는 $ENUM_LABELS_WANT ·"
  say "   ${ENUM_VALUE} 가 ${ENUM_BEFORE} 보다 **앞**(BEFORE 가 들었는가)."
  ph=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_HAS_SQL")
  pb=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_BEFORE_SQL")
  pc=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_COUNT_SQL")
  po2=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_ORDER_SQL")
  printf '      [%s] 가 있나 %s (기대 1) · [%s] 가 있나 %s (기대 1)\n' \
    "$ENUM_VALUE" "${ph:-?}" "$ENUM_BEFORE" "${pb:-?}"
  printf '      라벨 총수 %s (기대 %s) · [%s] 가 [%s] 앞인가 %s (기대 1)\n' \
    "${pc:-?}" "$ENUM_LABELS_WANT" "$ENUM_VALUE" "$ENUM_BEFORE" "${po2:-?}"
  if [ "${ph:-x}" = "1" ] && [ "${pb:-x}" = "1" ] && [ "${pc:-x}" = "$ENUM_LABELS_WANT" ]; then
    ok "**enum 에 ${ENUM_VALUE} 가 생겼다** (라벨 ${ENUM_LABELS_WANT}개 — 이 배포의 목적물이다)"
  else
    bad "[$ENUM_VALUE] ${ph:-?} · [$ENUM_BEFORE] ${pb:-?} · 라벨 ${pc:-?} 다 — 1 · 1 · $ENUM_LABELS_WANT 을 기대했다"
    say "      🔴 **수는 늘었는데 값이 없다면 db:migrate 가 오류를 삼킨 것**입니다. 멈추고 알릴 것."
    doubt
  fi
  if [ "${po2:-x}" = "1" ]; then
    ok "[$ENUM_VALUE] 가 [$ENUM_BEFORE] 보다 **앞이다** (BEFORE 가 들었다)"
  else
    hm "[$ENUM_VALUE] 가 [$ENUM_BEFORE] 보다 앞이 **아닙니다**(${po2:-?}) — 🔴 화면의 분류 차례가 달라집니다"
    say "      🔵 ✗ 는 안 냅니다 — 자료는 멀쩡하고 **보이는 차례만** 다릅니다."
  fi
  # 🔴 **잣대가 살아 있는가** — 없는 라벨을 물어 0 이 나오는지 본다.
  n=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_PROBE_SQL")
  printf '      없는 라벨을 물었을 때: %s (기대 0)\n' "${n:-?}"
  [ "${n:-x}" = "0" ] && ok "enum 라벨을 세는 잣대가 **살아 있다** (위 값을 믿을 수 있다)" \
    || bad "없는 라벨을 물었는데 ${n:-?} 가 나왔다 — **질의가 깨졌다.** 위 값도 못 믿는다"
  # 🔴 **자료가 안 바뀌었는가** — enum 에 값만 더하는 판이라 줄 수가 그대로여야 한다.
  arows=$(table_rows "$ATT_BOX" "$ATT_DB" "$ATT_TABLE")
  adata=$(pgn "$ATT_BOX" "$ATT_DB" "$ATT_DATA_ALL_SQL")
  printf '      %s 줄 수 %s · 그중 %s 분류 %s장 (🔵 **0 이 정상** — 이 분류가 지금 생겼다)\n' \
    "$ATT_TABLE" "${arows:-?}" "$ENUM_VALUE" "${adata:-?}"
  say "      🔵 이 배포는 **줄을 더하거나 지우지 않습니다** — 위 수를 적어 두고 --count 와 맞대세요."
  [ -n "${arows:-}" ] && [ -n "${adata:-}" ] \
    && ok "첨부 표의 줄 수를 값으로 읽었다" \
    || unk "첨부 표의 줄 수" "못 쟀다 — 사람이 보세요"

  say ""
  say "── 6-ㅇ. 🔴 **예순일곱째의 칸 넷이 아직 있는가** — 뒷걸음 방지"
  say "🔴 **이 판은 칸을 하나도 안 더합니다** — 그래도 **뒷걸음을 봅니다.**"
  PNC_SEEN=0; PNC_HAVE=0; PNC_SHAPE=0
  while IFS='|' read -r BOX DB T C TY NU MSG; do
    [ -n "${BOX:-}" ] || continue
    PNC_SEEN=$((PNC_SEEN+1))
    n=$(has_column "$BOX" "$DB" "$T" "$C")
    ty=""; nu=""
    if [ "${n:-0}" = "1" ]; then
      ty=$(col_type "$BOX" "$DB" "$T" "$C"); nu=$(col_null "$BOX" "$DB" "$T" "$C")
      PNC_HAVE=$((PNC_HAVE+1))
      TYC=$(printf '%s' "$TY" | tr -d ' ')
      [ "${ty:-x}" = "$TYC" ] && [ "${nu:-x}" = "$NU" ] && PNC_SHAPE=$((PNC_SHAPE+1))
    fi
    printf '      %-30s.%-26s 있나 %-3s · 자료형 %-26s (기대 %s) · NULL %s (기대 %s)\n' \
      "$T" "$C" "${n:-?}" "${ty:-–}" "$TY" "${nu:-–}" "$NU"
  done <<ENDPNC
$(rows_of "$NEWCOLS")
ENDPNC
  printf '      본 칸 %s · 있는 칸 %s · 꼴까지 맞는 칸 %s (기대 %s)\n' "$PNC_SEEN" "$PNC_HAVE" "$PNC_SHAPE" "$NEWCOLS_WANT"
  if [ "$PNC_SEEN" != "$NEWCOLS_WANT" ]; then
    bad "칸을 ${PNC_SEEN}개만 봤다 — ${NEWCOLS_WANT}개를 기대했다. NEWCOLS 표가 깨졌다"
  elif [ "$PNC_HAVE" != "$NEWCOLS_WANT" ] || [ "$PNC_SHAPE" != "$NEWCOLS_WANT" ]; then
    bad "칸이 ${PNC_HAVE}/${NEWCOLS_WANT} 개(꼴까지 맞는 것 ${PNC_SHAPE})다 — 🔴 **되감겼습니다.** 멈추고 알릴 것"
    doubt
  else
    ok "예순일곱째의 칸 넷이 **적어 둔 꼴 그대로 있다** (db:migrate 가 그것을 안 건드렸다)"
  fi

  say ""
  say "── 6-ㅈ. 🔴 **안 바뀌어야 하는 네 집** — 다시 센다"
  say "🔴 이 모드는 **A/S 한 집에만** 썼습니다. 나머지 넷(재고 포함)이 그대로인지 값으로 보입니다."
  POSTK_SEEN=0; POSTK_OK=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    BOX=$(field "$r" 2); DB=$(field "$r" 3); WANT=$(field "$r" 4); NAME=$(field "$r" 5)
    POSTK_SEEN=$((POSTK_SEEN+1))
    v=$(mig_count "$BOX" "$DB")
    printf '      %-14s %-16s 지금 %-5s (기대 %s)\n' "$NAME" "$DB" "${v:-못 읽음}" "$WANT"
    if [ "${v:-x}" = "$WANT" ]; then POSTK_OK=$((POSTK_OK+1))
    else bad "$NAME 가 ${v:-?} 다 — $WANT 를 기대했다. **멈추고 알릴 것**"; fi
  done <<ENDPOSTK
$(rows_of "$MIGS_KEEP")
ENDPOSTK
  [ "$POSTK_SEEN" = "$MIGS_KEEP_WANT" ] && [ "$POSTK_OK" = "$MIGS_KEEP_WANT" ] \
    && ok "네 집의 마이그레이션 수가 **그대로다** (옆으로 안 샜다 — 재고 DB 도 28 그대로다)" \
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
  printf '\n%s\n' "✅ A/S 의 DB 가 $AS_VOL_SQL_WAS → $AS_VOL_SQL_WANT 로 올라갔고 enum 에 $ENUM_VALUE 가 생겼습니다."
  printf '%s\n' "   🔵 **도구가 새 판을 가리킵니다.** 앱은 아직 옛 판입니다 — 직원이 보는 화면은 그대로입니다."
  printf '%s\n' "   🔵 옛 앱은 그 enum 값을 **쓰지 않습니다**(분류 목록에 안 내놓습니다)."
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
#      🔴🔴 **이번 판은 상자 하나를 보고 DB 이름 둘을 따로 묻는다**(dss_as ·
#         dss_inventory). 71번은 **상자가 둘**이었고(dss-pg-app · dss-pg-auth),
#         72번은 **하나**였다. 🔴 **「상자 하나니 한 번만 물으면 되지」가 틀린다** —
#         상자가 살아 있어도 그 안의 DB 하나가 없어지거나 권한이 닫히면 **재고 앱만**
#         죽고, 상자만 보면 그것을 못 가른다.
#      🔴 **dss-pg-auth 의 「켜진 때 맞대기」는 final_checks 에 그대로 있다** —
#         그것은 「안 건드렸다」를 재는 자리라 집이 올라가든 말든 남는다.
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
    say "         그때는 그 집의 DB 가 도는지부터 보세요."
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
#   🔴🔴 **기대 수를 부르는 쪽이 넘긴다** — 이번 판은 **단계로 갈린다**(적용 전 134 ·
#      뒤 135). 🔵 66번은 여기에 수가 박혀 있었고 그래서 --go 가 영영 못 지나갔다.
#      🔵 --rollback 은 적용 전에도 뒤에도 올 수 있어 **지금 값을 그대로 넘긴다.**
go_gate() { # 1 dss_as 의 기대 수 (부르는 쪽이 넘긴다)
  local s v w
  say "── 🔴 **--no-deps 관문** — 의존 서비스를 compose 에게 안 맡기므로 직접 잰다"
  GATE_SEEN=0
  # ── ① dss-pg-app 상자가 도는가 + **dss_as 가 답하는가** (A/S)
  GATE_SEEN=$((GATE_SEEN+1))
  s=$("$DOCKER" inspect -f '{{.State.Status}}' dss-pg-app 2>/dev/null)
  printf '      dss-pg-app 상자: %s (기대 running)\n' "${s:-없음}"
  if [ "${s:-}" != running ]; then
    bad "dss-pg-app 이 ${s:-없음} 다 — **DB 가 안 돌면 앱이 서도 아무것도 못 합니다**"
    say "      🔴 **그 상자 하나에 DB 둘이 들어 있습니다**(dss_as · dss_inventory) — 아래가"
    say "         **DB 이름마다 따로** 묻습니다."
    return 1
  fi
  ok "dss-pg-app 이 돈다"
  # 🔴 **숫자를 글자로 박지 않는다.** 65번은 여기에 131 이 두 번 박혀 있었다 —
  #    그런 자리는 판이 바뀌는 날 **조용히 틀린다**(위 표만 고치고 여기를 잊는다).
  v=$(mig_count dss-pg-app dss_as)
  printf '      dss_as 가 **답하는가**: 마이그레이션 수 %s (기대 %s)\n' "${v:-못 읽음}" "${1:-$AS_VOL_SQL_WANT}"
  if [ "${v:-x}" != "${1:-$AS_VOL_SQL_WANT}" ]; then
    bad "dss_as 가 답을 안 하거나 수가 다르다 (${v:-못 읽음})"
    say "      🔴 **「도는가」만 보면 안에서 죽은 DB 를 못 가릅니다** — 그래서 값을 받습니다."
    return 1
  fi
  ok "dss_as 가 **실제로 답한다** (${v})"
  # ── ② **dss_inventory 가 답하는가** (재고) — 🔴 **73번에서 가져왔다. 안 뺐다.**
  #    🔵 그 집은 이번 판에 **안 올라간다** — 그래도 **어제 올라간 A/S 의 부품 반환이
  #       그 DB 를 부른다.** 거기가 죽으면 **어제 올린 기능이 조용히 깨진다.**
  #    🔵 71번의 둘째 가지는 **다른 상자**(dss-pg-auth)였다. 이 판은 **같은 상자의
  #       다른 DB** 다 — 그래서 「상자가 도는가」를 다시 묻지 않고 **답하는가**만 묻는다.
  #    🔴 **기대 수를 표에서 꺼낸다** — 여기 숫자를 박으면 판이 바뀌는 날 조용히 틀린다.
  GATE_SEEN=$((GATE_SEEN+1))
  w=$(row_by_key "$MIGS_KEEP" inventory); w=$(field "$w" 4)
  v=$(mig_count dss-pg-app dss_inventory)
  printf '      dss_inventory 가 **답하는가**: 마이그레이션 수 %s (기대 %s — 안 바뀐다)\n' "${v:-못 읽음}" "${w:-28}"
  if [ "${v:-x}" != "${w:-28}" ]; then
    bad "dss_inventory 가 답을 안 하거나 수가 다르다 (${v:-못 읽음})"
    say "      🔴 **재고 DB 는 이번 판에 한 글자도 안 바뀝니다** — 수가 다르면 다른 사고입니다."
    say "      🔴 **상자가 돌아도 이 DB 가 안 답하면 재고 앱만 죽습니다** — 그래서 따로 묻습니다."
    return 1
  fi
  ok "dss_inventory 가 **실제로 답한다** (${v})"
  printf '      본 DB %s / 2 (표본이 비지 않았다)\n' "$GATE_SEEN"
  [ "$GATE_SEEN" = "2" ] || { bad "DB 를 ${GATE_SEEN}개만 봤다 — 2개를 기대했다"; return 1; }
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
  say "🔵 **포털(dss-auth)과 재고관리(dss-inventory)가 둘 다 이 목록에 있습니다** —"
  say "   🔴 **재고는 73번에서 돌아온 집**입니다(거기서는 올라갔습니다)."
  say "   🔴 **그 둘이 여기서 달라지면 이 배포가 옆으로 샌 것**입니다."
  say "🔵 **A/S(dss-as)는 이 목록에 없습니다** — 이번에 올라가는 집이라 1절에서 뺐습니다."
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
    && ok "안 건드리는 아홉이 **이미지도 켜진 때도 그대로다** (포털·재고 포함)" \
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
    say "      🔴 --no-deps 가 안 들었습니다. **compose 의 depends_on 을 보세요.**"
    say "      🔵 자료는 멀쩡합니다. 끊겼다 붙은 연결만 다시 섭니다."
  fi
  if [ "${b:-x}" = "${DBSTART_BEFORE2:-y}" ]; then ok "dss-pg-auth 가 **안 멈췄다**"
  else
    bad "dss-pg-auth 의 켜진 때가 달라졌다 — **DB 가 다시 떴다**"
    say "      🔴 **이번 판은 포털을 한 줄도 안 건드립니다** — 그 DB 가 다시 떴다면"
    say "         이 배포가 **옆으로 샌 것**입니다. 사람이 보세요."
  fi
  say ""
  say "── 🔴 compose 의 image: 줄을 **통째로** 찍는다 (사람이 눈으로 본다)"
  grep -n '^ *image:' "$CF" | sed 's/^/        /'
}

# ══════════════════════════════════════════════════════════════════════
# ── 7. --go : 앱 둘을 갈아 끼운다 ───────────────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--go" ]; then
  step "7. --go — 앱 **하나**를 갈아 끼운다 ⏱ 정지 창"
  say "🔵 **73번은 둘이었습니다**(A/S + 재고) — 이번엔 **A/S 하나**입니다."
  say "   🔴 **고리 꼴을 그대로 뒀습니다** — 집이 다시 둘이 되는 날 표에 줄만 더하면 됩니다."
  say "🔴 **차례는 SITES 표대로입니다.** 🔵 71번은 여기서 **A/S 를 먼저, 포털을 나중에**"
  say "   띄웠습니다(포털이 먼저 내려가면 그동안 모든 사이트의 로그인이 멈춥니다)."
  say "   🔴 포털이 다시 올라가는 판에서는 **SITES 표의 차례가 그 뜻을 갖는다**는 것을"
  say "      잊지 마세요."
  say "🔴 **안 서면 거기서 멈춥니다** — 그때는 --rollback 으로 되돌리세요."

  # 🔴🔴 관문 ① — **DB 가 올라갔는가**(DBPHASE = DONE)
  #    🔵 73번은 여기가 「DB 가 **안 바뀌었는가**」(DBKEEP = KEEP)였다 — **뜻이 반대다.**
  #    🔴 71번의 꼴로 되돌렸다.
  if [ "$DBPHASE" != "DONE" ]; then
    bad "DB 단계가 $DBPHASE 다 — DONE 이어야 한다 (dss_as 가 $AS_VOL_SQL_WANT 여야 한다)"
    say "      🔴🔴 **새 A/S 앱은 분류 목록에 ${ENUM_VALUE} 를 내놓습니다** — DB 의 enum 에"
    say "         그 값이 없으면 저장이 **22P02 로 거절**됩니다."
    say "      🔴 먼저 --migrate 를 돌리세요."
    stop "**아무것도 안 바꿨습니다.** 사람이 보세요."
  fi
  ok "A/S 의 DB 가 $AS_VOL_SQL_WANT 다 (--migrate 가 돌았다)"
  # 🔴🔴 관문 ①-2 — **enum 에 DATA 가 실제로 있는가.** 수만 믿지 않는다.
  #    🔴 「마이그레이션 수가 늘었다」와 「값이 생겼다」는 **다른 말**이다.
  GEH=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_HAS_SQL")
  GEB=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_BEFORE_SQL")
  GEC=$(pgn "$ENUM_BOX" "$ENUM_DB" "$ENUM_COUNT_SQL")
  printf '  enum [%s] 가 있나 %s (기대 1) · [%s] 가 있나 %s (기대 1) · 라벨 총수 %s (기대 %s)\n' \
    "$ENUM_VALUE" "${GEH:-?}" "$ENUM_BEFORE" "${GEB:-?}" "${GEC:-?}" "$ENUM_LABELS_WANT"
  if [ "${GEH:-x}" != "1" ] || [ "${GEB:-x}" != "1" ] || [ "${GEC:-x}" != "$ENUM_LABELS_WANT" ]; then
    bad "enum 이 기대와 다르다 — [$ENUM_VALUE] ${GEH:-?} · [$ENUM_BEFORE] ${GEB:-?} · 라벨 ${GEC:-?}"
    say "      🔴 **수가 늘었다고 값이 생긴 것이 아닙니다.** 멈추고 사람이 보세요."
    stop "**아무것도 안 바꿨습니다.**"
  fi
  ok "enum 에 ${ENUM_VALUE} 가 실제로 있다 (새 앱이 내놓을 분류를 DB 가 안다)"
  # 🔴 관문 ①-3 — **예순일곱째의 칸 넷이 아직 있는가.** 뒷걸음을 본다.
  #    🔴 **그 칸이 사라지면 그 기능이 42703 으로 터진다** — 그래서 남겼다.
  GNC=0; GNC_SEEN=0
  while IFS='|' read -r BOX DB T C TY NU MSG; do
    [ -n "${BOX:-}" ] || continue
    GNC_SEEN=$((GNC_SEEN+1))
    n=$(has_column "$BOX" "$DB" "$T" "$C")
    [ "${n:-0}" = "1" ] && GNC=$((GNC+1)) || printf '      🔴 없는 칸: %s.%s\n' "$T" "$C"
  done <<ENDGNC
$(rows_of "$NEWCOLS")
ENDGNC
  printf '  본 칸 %s / %s · 있는 칸 %s\n' "$GNC_SEEN" "$NEWCOLS_WANT" "$GNC"
  if [ "$GNC_SEEN" != "$NEWCOLS_WANT" ] || [ "$GNC" != "$NEWCOLS_WANT" ]; then
    bad "칸이 ${GNC}/${NEWCOLS_WANT} 개다 — 🔴 **예순일곱째가 올린 칸이 사라졌습니다**"
    say "      🔴 **수가 맞는다고 칸이 있는 것이 아닙니다.** 멈추고 사람이 보세요."
    stop "**아무것도 안 바꿨습니다.**"
  fi
  ok "예순일곱째의 칸 넷이 아직 다 있다 (뒷걸음친 DB 가 아니다)"
  # 🔴 관문 ①-4 — **안 바뀌어야 하는 네 집**이 그대로인가
  if [ "$DBKEEP" != "KEEP" ]; then
    bad "안 바뀌는 네 집의 상태가 $DBKEEP 다 — KEEP 이어야 한다"
    say "      🔴 재고 28 · 휴가 5 · 포털 11 · 계측기 3 이 아닙니다."
    say "         이 배포본은 **A/S 한 집에만** 1건을 올립니다."
    stop "**아무것도 안 바꿨습니다.** 사람이 보세요."
  fi
  ok "안 바뀌는 네 집이 전과 같다 (재고 DB 도 28 그대로다)"

  # 🔴 관문 ② — 도구가 새 판인가(--migrate 가 돌았는가)
  if [ "$PHASE_TOOL_NEW" != "$TOOLS_WANT" ]; then
    bad "도구가 ${PHASE_TOOL_NEW}/${TOOLS_WANT} 만 새 판이다 — --migrate 가 안 돌았다"
    say "      🔴 --migrate 가 **덤프를 뜨고** · **묶음을 볼륨에 풀고** · **도구 태그를**"
    say "         **갈고** · 새 도구로 **db:migrate 를 돌립니다.** 그 넷을 건너뛰지 마세요."
    stop "먼저 --migrate 를 돌리세요. **아무것도 안 바꿨습니다.**"
  fi
  ok "도구가 새 판이다 (--migrate 가 돌았다)"

  # 🔴 관문 ③ — **--no-deps 를 쓰므로 DB 를 직접 잰다**
  say ""
  if ! go_gate "$AS_VOL_SQL_WANT"; then stop "**아무것도 안 바꿨습니다.** DB 부터 보세요."; fi

  say ""
  say "── 7-ㄱ. compose 사본"
  backup_compose

  say ""
  say "── 7-ㄴ. 🔴 image: 줄 **하나**를 바꾼다 (아직 안 띄운다)"
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
  say "── 7-ㄷ. ⏱ **여기서부터 정지 창** — 앱 **하나**를 띄운다 (40~60초)"
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
      say "      🔵 **DB 는 그대로 둡니다** — 🔴 **enum 값은 지울 수 없습니다**(PostgreSQL)."
      say "         🔵 옛 앱은 그 값을 **안 씁니다** — 그대로 두어도 해롭지 않습니다."
      say "      🔵 **포털과 재고는 이번에 안 건드립니다** — 로그인도 재고 화면도 그대로입니다."
      stop "compose 사본: $BK · 덤프: $BKDB · 옛 볼륨 사본: $D/backups/as-migrations-$DUMP_VER-*"
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
  printf '%s\n' "🔴 **배포 뒤에 눈으로 볼 곳 — 세 갈래**"
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "  🔵 **--count 의 ⑳ 을 먼저 보세요** — 그 수가 0 이면 ㄱ 갈래에서"
  printf '%s\n' "     **아무것도 안 보이는 것이 정상**입니다. 모르면 「고장」으로 읽습니다."
  printf '%s\n' "       ⑳ ${ENUM_VALUE} 분류 첨부 0 → 그 분류의 파일이 **한 장도 없다** (지금은 맞다)"
  printf '%s\n' "     🔵 **㉑ 은 1 이어야 합니다** — enum 에 ${ENUM_VALUE} 가 생겼다는 뜻입니다."
  printf '%s\n' ""
  printf '%s\n' "  🔴 **ㄱ) 첨부 분류에 ${ENUM_VALUE} 가 선다**"
  printf '%s\n' "  ① 수리 건 상세의 **파일 올리기**에서 분류 드롭다운을 여세요 —"
  printf '%s\n' "     **${ENUM_VALUE}** 가 **기타 바로 앞**에 있어야 합니다(차례가 뜻을 갖습니다)."
  printf '%s\n' "     🔴 **영문 ${ENUM_VALUE} 가 맞습니다** — 다른 분류는 한글인데 이것만 영문인 까닭은"
  printf '%s\n' "        연락서 폴더 안의 ${ENUM_VALUE} 폴더와 **글자가 같아야** 하기 때문입니다."
  printf '%s\n' "  ② 🔴 **제품 모델 · 종류 서류함 · 견적서 화면에는 안 떠야** 합니다"
  printf '%s\n' "     (수리 건 전용입니다). 거기 뜨면 **갈 곳 없는 선택지**가 됩니다."
  printf '%s\n' "  ③ 그 분류로 파일을 하나 올려 보세요 — 저장이 되고, [연락서 폴더에 저장]을"
  printf '%s\n' "     누르면 **연락서 폴더의 ${ENUM_VALUE} 폴더**에 들어가야 합니다."
  printf '%s\n' "     🔴 **22P02 가 나면 --migrate 가 안 돌았다는 뜻**입니다(2-ㄱ-4 를 보세요)."
  printf '%s\n' ""
  printf '%s\n' "  🔴 **ㄴ) [연락서 폴더에 저장] 창에 파일 이름 칸이 생긴다**"
  printf '%s\n' "  ④ 폴더를 고른 **아래**에 **[파일 이름]** 칸이 있어야 합니다(라디오 아래입니다)."
  printf '%s\n' "  ⑤ 기본값이 **지금 저장될 이름**이어야 합니다(원본 이름이 아니라 다듬기를 지난 뒤)."
  printf '%s\n' "  ⑥ 🔴 경로 글자(/ \\ ..)를 적으면 **거절**되고 까닭이 한 줄 떠야 합니다 —"
  printf '%s\n' "     조용히 바꾸지 **않습니다**(적은 사람이 탐색기에서 제 이름을 찾아야 합니다)."
  printf '%s\n' "  ⑦ 🔵 **비우거나 손대지 않으면 2026-11-18 과 한 글자도 같은 요청**이 나갑니다."
  printf '%s\n' "  ⑧ 확장자는 **원본 것으로 끝나야** 합니다(지워도 붙습니다)."
  printf '%s\n' ""
  printf '%s\n' "  🔴 **ㄷ) [파일 올리기]의 칸이 「폴더 이름」으로 바뀐다** (마지막 커밋)"
  printf '%s\n' "  ⑨ 칸 이름이 **[폴더 이름 (선택)]** 이어야 합니다(전에는 [파일 이름 (선택)])."
  printf '%s\n' "  ⑩ 적고 올리면 **분류 폴더 아래에 그 이름의 폴더**가 서고 파일이 그 안에 들어갑니다."
  printf '%s\n' "  ⑪ 🔵 **비우면 2026-11-26 전과 한 글자도 같습니다** — 분류 폴더에 바로 들어갑니다."
  printf '%s\n' "  ⑫ 🔴 **파일 이름에 (1)(2) 번호가 더는 안 붙습니다** — 고른 이름 그대로입니다."
  printf '%s\n' "     (겹칠 때의 ' (2)' 는 연락서 폴더 쪽 덮어쓰기 방지라 그대로 있습니다.)"
  printf '%s\n' "  ⑬ 🔴 경로 글자나 **감춰지는 이름**(점 · ~\$ 로 시작)은 **거절**돼야 합니다 —"
  printf '%s\n' "     폴더가 멀쩡히 만들어지는데 목록에도 탐색기에도 안 보이는 일을 막습니다."
  printf '%s\n' "  ⑭ 🔵 여러 장을 한 번에 고르면 **같은 폴더**에 들어가야 합니다."
  printf '%s\n' ""
  printf '%s\n' "  🔵 ⑮ **어제 것이 그대로 있는지도 보세요**(뒷걸음 눈 확인) —"
  printf '%s\n' "     ㄱ) 수리 건의 **[반환 요청]** 단추가 그대로 서는지(예순아홉째)."
  printf '%s\n' "     ㄴ) 재고의 **신청 관리**와 **[기록 내역]** 이 그대로인지(예순아홉째)."
  printf '%s\n' "     ㄷ) [내자 정리]에서 **완료된 줄에 확정 단추가 안 서는지**(예순여덟째)."
  printf '%s\n' "     ㄹ) 아이폰 사진(heic) 올리기가 그대로 되는지(쉰여덟째 · heic2any)."
  printf '%s\n' ""
  printf '%s\n' "🔴 **다음에 할 일 둘** (아직 그대로입니다)"
  printf '%s\n' "  ㄱ) 06-notify-install.sh 의 **확인할 도구 태그**가 지금 운영과 맞는지 보세요."
  printf '%s\n' "     🔴 **이번 판이 도구 태그를 하나 갈았습니다**(A/S 32)."
  printf '%s\n' "  ㄴ) 🔴 **PO 가 모르는 것이 일곱**입니다(머리말). PO 를 다시 여는 날 일곱을"
  printf '%s\n' "     한 묶음으로 이식하세요 — 🔴 **이번 판이 하나 더했습니다**(enum 의 ${ENUM_VALUE})."
  printf '%s\n' ""
  printf '%s\n' "🔴 **되돌리기**: bash $0 --rollback  (앱 하나를 옛 태그로 되돌립니다)"
  printf '%s\n' "   🔵 도구는 새 판 그대로 둡니다."
  printf '%s\n' "   🔴🔴 **DB 는 자동으로 안 되돌립니다** — PostgreSQL 은 **enum 값을 지울 수**"
  printf '%s\n' "      **없습니다.** 🔵 옛 앱은 그 값을 **안 씁니다**(분류 목록에 안 내놓습니다)."
  printf '%s\n' "      🔴 다만 **그 사이에 ${ENUM_VALUE} 로 올린 첨부가 있으면** 옛 앱이 모르는 분류로"
  printf '%s\n' "         남습니다 — 되돌리기 전에 **--count 의 ⑳ 을 먼저 보세요.**"
  printf '%s\n' "   🔵 덤프: $BKDB · compose 사본: $BK · 옛 볼륨 사본: $D/backups/as-migrations-$DUMP_VER-*"
  printf '%s\n' "  다음: bash $0 --count  ← 올린 뒤 수를 재어 앞의 수와 맞대세요"
  printf '%s\n' "        🔴 **㉑ 만 0 → 1 로 바뀌는 것이 정상**입니다."
  printf '%s\n' "        🔵 **⑳ 과 ⑭·⑯·⑱ 은 사람이 쓰기 시작하면 늡니다** — 사고가 아닙니다."
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════
# ── 8. --rollback : 앱 둘을 함께 되돌린다 ───────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--rollback" ]; then
  step "8. --rollback — 앱 **하나**를 옛 태그로 되돌린다"
  say "🔵 **도구는 새 판 그대로 둡니다**(39·41~73번과 같은 판단) — profiles: [tools]"
  say "   라 평소에 뜨지 않고, 옛 앱이 도구를 부르는 일도 없습니다."
  say "🔴🔴 **DB 는 자동으로 안 되돌립니다** — PostgreSQL 은 **enum 값을 지울 수 없습니다.**"
  say "   🔵 옛 앱은 그 값을 **안 씁니다**(분류 목록에 ${ENUM_VALUE} 를 안 내놓습니다) —"
  say "      그대로 두어도 해롭지 않습니다."
  say "   🔴 다만 **그 사이에 ${ENUM_VALUE} 로 올린 첨부가 있으면** 옛 앱이 **모르는 분류**로"
  say "      남습니다. 🔴 **되돌리기 전에 --count 의 ⑳ 을 먼저 보세요.**"
  say "🔴 **되돌리면 이 판의 세 갈래가 통째로 사라집니다** — 코드에만 있는 것입니다:"
  say "   ㄱ) 분류 드롭다운에서 **${ENUM_VALUE} 가 없어집니다**(DB 의 enum 값은 남습니다)."
  say "   ㄴ) [연락서 폴더에 저장]의 **파일 이름 칸**이 없어집니다."
  say "   ㄷ) [파일 올리기]의 칸이 **다시 「파일 이름」**이 되고 (1)(2) 번호가 돌아옵니다."
  say "      🔴 그러면 2026-11-26 **이전의 동작**으로 돌아갑니다 — 그 사이에 만들어진"
  say "         **폴더와 파일은 공유폴더에 그대로 남습니다**(되돌아가지 않습니다)."
  say "🔵 포털과 재고관리는 이번에 안 건드렸습니다."
  say "🔴 **--no-deps 로 띄웁니다** — 되돌릴 때도 DB 를 Recreate 하면 안 됩니다."
  say ""
  # 🔴 **기대값을 지금 값으로 넘긴다** — --rollback 은 적용 전에도 뒤에도 올 수 있다.
  #    여기서 재는 것은 「수가 맞는가」가 아니라 **「DB 가 실제로 답하는가」**다.
  RBWANT=$(mig_count dss-pg-app dss_as)
  if [ -z "${RBWANT:-}" ]; then
    bad "dss-pg-app 에서 dss_as 마이그레이션 수를 못 읽었다"
    stop "**아무것도 안 바꿨습니다.** DB 부터 보세요."
  fi
  say "지금 dss_as 는 ${RBWANT} 입니다 (🔵 --migrate 를 돌았으면 ${AS_VOL_SQL_WANT} · 전이면 ${AS_VOL_SQL_WAS} 입니다)"
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
  printf '%s\n' "🔵 앱을 옛 판(dss-as:6.4)으로 되돌렸습니다. 도구는 새 판 그대로입니다."
  printf '%s\n' "   🔴 **1절의 단계는 MID 로 보입니다** — --migrate 만 돌린 상태와 같은 모양입니다."
  printf '%s\n' "      🔵 **DB 로는 그 둘을 못 가릅니다** — 둘 다 dss_as ${AS_VOL_SQL_WANT} 이고 enum 에"
  printf '%s\n' "         ${ENUM_VALUE} 가 있습니다. 가르려면 **로그 파일 이름**"
  printf '%s\n' "         (deploy70-go-… / deploy70-rollback-…)을 보세요."
  printf '%s\n' "   🔴🔴 **enum 의 ${ENUM_VALUE} 는 그대로 남습니다** — 지울 수 없습니다(PostgreSQL)."
  printf '%s\n' "      🔵 옛 앱은 그 값을 안 씁니다 — 해롭지 않습니다."
  printf '%s\n' "   🔴 **이미 ${ENUM_VALUE} 로 올린 첨부가 있으면** 옛 앱이 모르는 분류로 남습니다 —"
  printf '%s\n' "      --count 의 ⑳ 을 보세요. 🔵 파일과 폴더는 공유폴더에 그대로 있습니다."
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi
