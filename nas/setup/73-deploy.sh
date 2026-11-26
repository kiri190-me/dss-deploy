#!/bin/bash
# dss-deploy/nas/setup/73-deploy.sh — 예순아홉째 배포 (2026-11-26)
#
# 🔴 **NAS 에서 돈다.** DSM 터미널에서 sudo -i 뒤에 부른다.
#     bash /volume1/dss/setup/73-deploy.sh            ← --check (기본 · 아무것도 안 바꾼다)
#     bash /volume1/dss/setup/73-deploy.sh --count
#     bash /volume1/dss/setup/73-deploy.sh --preload
#     bash /volume1/dss/setup/73-deploy.sh --tools    🔵 **DB 는 한 글자도 안 바뀐다**
#     bash /volume1/dss/setup/73-deploy.sh --go
#     bash /volume1/dss/setup/73-deploy.sh --rollback
#
#   🔴 **DSM 터미널은 긴 명령을 잘라 먹는다.** 그래서 NAS 것은 **스크립트 파일로
#      올리고 md5 를 맞댄다** — 이 파일은 돌 때 **제 md5 를 스스로 찍는다.**
#      개발 PC 에서 「Get-FileHash -Algorithm MD5 73-deploy.sh」 로 찍은 값과
#      **눈으로 맞대고** 나서 모드를 쓰기 시작하라. 다르면 **올리다 잘린 것**이다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴🔴 **맨 먼저 — 어느 판을 왜 베꼈는가**
# ══════════════════════════════════════════════════════════════════════
#   이 파일은 **72-deploy.sh(예순여덟째 · 2026-11-26)를 복사해 값만 고친 것**이고,
#   **집이 둘인 꼴은 71-deploy.sh(예순일곱째 · 2026-11-25)에서 되살린 것**이다
#   (2026-11-19 결정 — 「배포본은 복사하고 값만 고친다. 검사는 하나도 안 뺀다.
#   diff 가 곧 검수다」).
#   🔴 **검수하는 길은 「diff 72-deploy.sh 73-deploy.sh」 와 「diff 71-deploy.sh
#      73-deploy.sh」 **둘**이다.** 앞의 것이 「값이 맞게 바뀌었나」를, 뒤의 것이
#      「집이 둘인 꼴을 제대로 가져왔나」를 보여 준다.
#
#   ── 🔴 72번과 **다른 것 다섯** ───────────────────────────────────────
#        | 72번(예순여덟째)       | 73번(이번)
#     집  | **하나**(A/S)          | 🔴 **둘**(A/S + **재고관리**)
#     도구 | 하나(A/S)              | 🔴 **둘**(A/S + 재고)
#     tar  | 둘                     | 🔴 **넷**
#     안 건드리는 집 | 아홉          | 🔴 **여덟**(재고가 빠지고 포털은 그대로 남는다)
#     마이그| 0건                    | 🔵 **0건 — 그대로다**(A/S 134 · 재고 28)
#
#   ── 🔴 **집이 둘인 자리 여섯은 71-deploy.sh 에서 가져왔다** ──────────
#   71번이 **앱 둘 · 도구 둘 · tar 넷**이라 이 판과 모양이 같다(올라가는 둘째 집만
#   포털 → 재고로 바뀐다). 그래서 72번에서 **한 집으로 줄여 둔 자리**에는 71번의
#   **이미 돌아 본 코드**를 그대로 되살렸다:
#     · **go_gate 의 두 가지 꼴**(71-deploy.sh:2543-2587) — 🔴 다만 **이 판은 DB
#       상자가 하나**다(둘 다 dss-pg-app). 그래서 ② 가지가 「다른 상자」가 아니라
#       **같은 상자의 다른 DB(dss_inventory)가 답하는가**를 묻는다. 🔴 그것을
#       빼면 **재고 앱을 띄우면서 그 DB 를 한 번도 안 보는** 꼴이 된다.
#     · **preload_inside 의 집마다 갈리는 case**(71-deploy.sh:2065-2114)
#     · **--count 의 「둘째 집이 답하는가」 절**(71-deploy.sh:1837-1848 의 ⑪)
#     · **--go 의 「차례가 뜻을 갖는다」 안내**(71-deploy.sh:2666-2669)
#     · **final_checks 의 「올라가는 집은 KEEP_BOXES 에 없다」 꼴**
#     · **ask_files 를 집마다 따로 부르는 꼴**(AS_KEY_FILES · INV_KEY_FILES)
#   🔴 **그 밖은 전부 72번 그대로다** — 72번이 71번에서 지켜 온 자리(표식을 코드
#      줄에서 따오지 않기 · 한글 바이트 확인 절 · 고리마다 「몇 개를 봤는가」 ·
#      --tools 자리)를 잃지 않으려고 뼈대를 72번으로 잡았다.
#
#   ── 🔵 재고관리의 값은 **69-deploy.sh(예순다섯째)에서** 가져왔다 ─────
#   재고를 마지막으로 올린 판이 69번이고(0.7 → 0.8 · 도구 4 → 5), 그 파일이
#   **A/S 와 정반대인 자리 넷**을 값으로 적어 두었다. 🔴 **그 넷을 A/S 판으로
#   베끼면 멀쩡한 재고 이미지가 ✗ 가 된다:**
#     ① 재고 도구 이미지 안 **drizzle 28장**(A/S 는 **0장**이어야 한다 — 볼륨이 정본)
#     ② 재고 public/ 은 **있는데 비어 보인다**(.gitkeep 한 장뿐 · ls -1 로 0개)
#     ③ 재고 도구에는 **vendor 가 없다**(A/S 도구에는 있어야 한다)
#     ④ 재고에는 **묶음(as-migrations.tar.gz)이 애초에 없다** — .sql 이 도구 tar 안이다
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 파일에 「왜 없는가」를 적어 두는 절 넷**
#    (70·68·67·65·64·63 이 그렇게 했다 — 그 글이 없으면 다음 판이
#     「원래 없는 절」로 읽고, 되살려야 할 때 아무도 되살리지 않는다)
# ══════════════════════════════════════════════════════════════════════
#   ① **--migrate 모드가 없다.** 그 자리에 **--tools** 가 있다. 까닭: 올릴 .sql 이
#      **0건**이다(2-ㄷ 가 볼륨을 값으로 잰다 · 73-build.sh 4-ㄴ 이 저장소를 잰다).
#      🔴 **1건이라도 생기면 71-deploy.sh 에서 --migrate 와 place_migs() 를
#         통째로 되살려라.** 🔴 **--tools 와 --migrate 를 둘 다 두지 마라** —
#         모드를 늘리면 차례가 하나 더 생겨 사람이 건너뛴다(66번이 65·64·63 의
#         --tools 를 --migrate 로 되돌린 까닭이다).
#   ② **묶음(as-migrations.tar.gz)을 읽는 3-ㄴ 절이 없다.** 같은 까닭이다.
#      🔴 함께 없는 것이 **셋**이고 **한 벌**이다: 3-ㄴ 절 · place_migs() ·
#         **MIGTAR_SIZE·MIGTAR_MD5 변수 둘**. 🔴 하나만 되살리면 묶음을 받고도
#         **안을 한 번도 안 세거나**, 풀지 않은 채 db:migrate 를 돌려 **0건으로
#         조용히** 끝난다. 🔵 그래서 1-ㅁ 절의 뜻도 뒤집혔다(아래 ⑤ 를 보라).
#   ③ **DBPHASE / VOLPHASE 단계 가지가 없다.** 71번은 「적용 전이냐 뒤냐」로
#      기대값이 뒤집혀서 그 변수 둘이 필요했다 — 이 판은 **처음부터 끝까지 같은
#      기대값**이라 뜻 없는 분기를 남기지 않는다. 🔵 대신 **DBKEEP** 하나가
#      「다섯 집이 다 전과 같은가」를 들고 다닌다.
#   ④ 🔴🔴 **이번에 올라가는 둘째 집은 포털이 아니라 재고관리다.**
#      72번은 포털이 「안 건드리는 집」으로 되돌아간 판이었고, **이 판도 포털은
#      그대로 「안 건드리는 집」**이다 — 대신 **재고관리가 KEEP_BOXES 에서 빠져**
#      SITES·TOOLS·TARS·APPMARKS·TOOLMARKS·INV_KEY_FILES 로 올라갔다
#      (아홉 → **여덟**).
#      🔴🔴 **71·72번이 서로 반대로 못을 박아 둔 자리다. 이 판은 둘 다 박는다:**
#         · 71번: 「KEEP_BOXES 에 dss-auth 가 **없는가**」(그때는 포털이 올라갔다)
#         · 72번: 「KEEP_BOXES 에 dss-auth 가 **있는가**」(그때는 안 건드렸다)
#         · 73번(이번): **「dss-auth 가 있는가」 + 「dss-inventory 가 없는가」 둘 다**
#      🔴 **71번 것을 그대로 베꼈으면** 포털이 목록에서 빠진 채 돌아 **「옆으로 안
#         샜다」를 한 번도 안 재게** 됐을 것이고, **72번 것을 그대로 두었으면**
#         재고관리가 목록에 남아 끝의 맞대기가 「재고가 달라졌다」로 **가짜 ✗** 를
#         냈을 것이다. 그래서 **양쪽을 같은 줄에서 함께 센다**(1-ㄷ).
#      🔵 되살린 것 둘: **--count 의 「재고관리가 답하는가」**(71번 ⑪ 의 자리) 와
#         **go_gate 의 둘째 가지**. 🔴 다만 71번의 둘째 가지는 **다른 상자**
#         (dss-pg-auth)였고, 이 판은 **같은 상자의 다른 DB**(dss_inventory)다.
#      🔵 **dss-pg-auth 의 「켜진 때 맞대기」는 그대로 있다**(final_checks) —
#         그것은 「안 건드렸다」를 재는 자리라 집이 올라가든 말든 남는다.
#   ⑤ 🔵 (넷이 아니라 다섯이다 — ② 에 딸린 것이라 번호를 안 매겼다)
#      **1-ㅁ 절은 「incoming 을 쳐다보지도 않는다」 쪽이다**(72·70·69·68·67 과 같다).
#      🔴 거기 묶음이 보이면 **옛 판의 것**이니 보내지도 풀지도 마라.
#      🔵 [실측 2026-11-26] 거기 **2026-11-25 의 묶음이 아직 남아 있다** — 71번이
#         보낸 134장짜리다. 🔴 **그것을 이번 것으로 착각하지 마라.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 배포가 올리는 것 — 한 기능이 두 집에 걸쳐 있다**
#    **DB 는 한 글자도 안 바뀐다**(두 집 다 마이그레이션 0건)
# ══════════════════════════════════════════════════════════════════════
#   🔴🔴 **이번 판의 가장 큰 위험은 「반쪽만 올라가는 것」이다.** 한 기능이 두
#      저장소에 나뉘어 있어서, 한쪽만 올리면 **화면은 멀쩡한데 눌렀을 때 실패**한다:
#        · A/S 만 올리면  → [반환 요청] 창이 뜨지만 **목록이 비고**(재고가 그 통로를
#          아직 모른다 404) 올려도 **거절**된다.
#        · 재고만 올리면  → 통로는 열려 있는데 **올리는 쪽이 없다**(직원이 보는 것이
#          하나도 안 바뀐다 — 조용하다).
#      🔴 그래서 **--go 는 둘을 한 번에 띄운다.** 하나가 안 서면 거기서 멈춘다.
#
#   ㄱ) **[A/S] 수리 건에서 쓴 부품을 돌려주겠다고 올린다.** 부품 신청 자리에
#      **[반환 요청]** 이 서고, 창에는 **그 건으로 나갔고 아직 안 돌아온 부품**이
#      뜬다(재고가 세어 준다). 올리면 재고의 신청 목록에 **반환 신청**이 선다.
#      🔵 보내는 주소와 토큰은 반출 신청과 **같고**, 달라지는 것은 type: "RETURN"
#         과 줄의 생김새뿐이다. 🔵 **유상/무상과 사유를 안 보낸다**(저쪽에 그 칸이
#         없다 — 적어 보내면 400 이다).
#   ㄴ) **[A/S] 반출만 가리키던 화면 글자 셋을 둘 다 담는 말로 바꾼다.**
#      🔵 마지막 커밋(b281ff9b)이고 **글자만** 바뀐다 — 그래서 번들 표식
#      [부품 신청 거두기] 하나가 그 커밋을 가린다.
#   ㄷ) **[재고] 수리 건별로 돌려줄 수 있는 부품을 알려 주는 통로**
#      (GET /api/v1/return-candidates) — 🔴 **읽기 토큰**이다.
#   ㄹ) **[재고] A/S 가 올리는 반환 신청을 받는다**(POST /api/v1/stock-requests
#      의 type: "RETURN"). 🔵 **같은 주소**라 반출 쪽 호출은 한 글자도 안 바뀐다.
#   ㅁ) **[재고] 반환 신청의 내용을 보이고 [반환 완료]로 받는다.**
#   ㅂ) **[재고] 반환이 끝나면 올린 사람의 종을 울린다**(「부품 반환이 완료되었습니다」).
#   ㅅ) **[재고] 기록 내역의 반환 건에 수리 건 인수번호를 띄운다**(18f5381 · **마지막**).
#      🔴 2026-11-26 저녁에 **늦게 들어온 커밋**이다 — 재고 범위가 4 → 5 가 됐다.
#      🔵 반환 건은 **제 인수번호를 안 들고 있다**(그 칸이 언제나 빈 글자다) —
#         화면이 **되돌린 원장 줄을 되짚어** 가져온다(returns_transaction_id →
#         그 줄이 달린 불출 건의 intake_number). 🔴 **「intake_number 가 찼나」로**
#         **세면 늘 0** 이 나온다 — --count 의 ⑱ 가 되짚어서 센다.
#      🔵 **갈래가 섞였거나 못 찾으면 빈 글자**이고 화면은 그 자리를 아예 안 그린다.
#
#   🔵 **A/S 의 나머지 두 커밋(342c36f8 · 4573a6ce)은 현황판 HTML 한 장짜리**라
#      **이미지에 자취가 없다** — 71번이 겪은 그 꼴이다(2절의 커밋 수가 ⚠️ 로
#      어긋나도 5-ㅁ 의 파일 수가 함께 어긋나지 않으면 그것일 수 있다).
#
#   앱 **둘** · 도구 **둘** · tar **넷** · 마이그레이션 **0건** · 묶음 **없음** ·
#   안 건드리는 집 **여덟** · 안 바뀌는 DB **다섯**.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **72번의 전제 중 이번에 깨지는 것 여덟 — 하나씩 재서 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴🔴 **재고관리가 「안 건드리는 집」에서 빠진다**(위 「왜 없는가」 ④).
#      72번은 KEEP_BOXES 가 **아홉**이었고 거기 dss-inventory 가 들어 있었다.
#      🔴 **이 판은 여덟**이고, 1-ㄷ 이 **「dss-auth 가 있는가(1)」와 「dss-inventory
#         가 없는가(0)」를 같은 줄에서 함께** 센다. 🔴 **「있는가」만 재면 번호가
#         빗나가도 통과한다** — 그 규율이 여기서도 쓰인다.
#      🔵 **재고 DB(dss_inventory 28)는 그대로 「안 바뀌는 집」이다** — 그 줄은
#         MIGS_KEEP 에 **남아 있다.** 🔴 **「올라가는 집이니 MIGS_KEEP 에서 빼야지」가
#         틀린다** — 집이 올라가는 것과 DB 가 바뀌는 것은 다른 말이고, 이번 범위는
#         양쪽 다 .sql 을 **한 장도 안 늘렸다**(71번이 포털에, 72번이 A/S 에 대해
#         적어 둔 그 문장이 이번에는 **재고에 그대로 적용된다**).
#
#   ② 🔵 **마이그레이션은 여전히 0건이다**(72번과 같다). dss_as **134 그대로** ·
#      볼륨 **134장 그대로** · dss_inventory **28 그대로**.
#      🔴 그래서 **--migrate 가 없고 그 자리가 --tools 인 꼴도 그대로**다.
#      🔴 **재고는 .sql 이 도구 이미지 안에 구워져 간다**(28장) — A/S 와 **정반대**다.
#         2-ㄷ 가 그 둘을 **다른 잣대로** 잰다. 한 잣대로 뭉뚱그리면 하나가 가짜 ✗ 다.
#
#   ③ 🔵 **새로 생기는 칸이 0개인 것도 그대로다.** NEWCOLS 표는 **「예순일곱째가
#      만든 칸이 아직 있는가」**를 보는 자리로 남아 있다. 🔴 **표를 지우지 않았다** —
#      지우면 DB 가 되감긴 날 아무도 못 잡는다. 🔵 자료형과 NULL 허용까지 본다.
#        domestic_order_due_dates.confirmed_at        timestamp with time zone · YES
#        domestic_order_due_dates.confirmed_by        uuid                      · YES
#        procedure_template_nodes.share_doc_relative_path      text            · YES
#        repair_case_flowchart_nodes.share_doc_relative_path   text            · YES
#
#   ④ 🔴 **--tools 가 도구 태그를 둘 간다**(72번은 하나였다).
#      🔴 **A/S 도구**: src/ 20장이 바뀌었고 그 안에서 도는 db:preflight·check:* 가
#         **그 소스로** 돈다. 안 갈면 **옛 몸통**으로 센다.
#      🔴 **재고 도구**: src/ 26장이 바뀌었다. 🔵 **그 집에는 db:preflight 도
#         check:* 도 없다**[실측 2026-11-26 · package.json 의 명령 17개] — 그래서
#         **명령을 돌리지 않고** 69번처럼 **이미지 안을 값으로 센다**(.sql 28장 ·
#         도구 표식 둘). 🔴 **A/S 판을 베껴 npm run db:preflight 를 부르면
#         Missing script 로 멈춘다.**
#
#   ⑤ 🔴 **--go 가 앱을 둘 띄운다.** 그래서 go_gate 가 **둘**을 잰다 —
#      dss-pg-app 이 도는가 + **dss_as 가 답하는가** + **dss_inventory 가 답하는가**.
#      🔵 **DB 상자는 하나다**(둘 다 dss-pg-app) — 71번은 상자가 둘이었다.
#      🔴 **「상자 하나니 한 번만 물으면 되지」가 틀린다** — 상자가 살아 있어도
#         그 안의 DB 하나가 없어지거나 권한이 닫힐 수 있고, 그러면 **재고 앱만**
#         죽는다. 그래서 **DB 이름마다 따로** 묻는다.
#      🔵 dss-pg-auth 는 **켜진 때만** 맞댄다(안 건드렸다는 증거).
#
#   ⑥ 🔴 **표식이 전부 갈렸고 집마다 따로다.**
#      🔵 **이번에는 기능 표식이 번들에 제대로 남는다** — 두 집 다 **새 문자열
#         리터럴**이 생겼다(72번은 갈래 셋 중 둘이 번들에 자취가 없어 애를 먹었다).
#        A/S 기능 셋:  반환 요청(🔴 **한글** · 5c02d985) ·
#                      return-candidates(ASCII · 통로 주소 리터럴 · 5c02d985) ·
#                      부품 신청 거두기(🔴 **한글** · **마지막 커밋 b281ff9b**)
#        재고 기능 셋: return-candidates(ASCII · ff0836c·5d8767e) ·
#                      돌려받을 내용을 확인하십시오(🔴 **한글** · 7256b75) ·
#                      부품 반환이 완료되었습니다(🔴 **한글** · **마지막 커밋 117d6c7**)
#      🔴 **집마다 「마지막 커밋의 글자」를 하나씩 넣었다** — 그것이 0 이면 **커밋
#         하나가 빠진 판**을 구운 것이다.
#      🔴 뒷걸음 — A/S **열하나**(72번의 열 + **NO_WAITING_REPAIR_STEP** 이 내려왔다) ·
#         재고 **셋**(drawing-no-text-color 예순다섯째 · portal_approval_delegations
#         쉰여덟째 · stock_issue_approval_steps).
#      🔵 **72번의 기능 표식이 내려온 근거**: dss-as:6.3 이 지금 운영에서 돈다는 것이
#         곧 그 글자가 **그 번들에서 ≥1 이었다**는 증거다 — 0 이었으면 72번의
#         --preload 가 거기서 멈췄다(그 모드는 ✗ 가 하나라도 있으면 stop 한다).
#         🔵 같은 근거로 재고의 drawing-no-text-color 도 dss-inventory:0.8 에서 ≥1 이다.
#      🔴🔴 **이 파일의 표식은 번들에서 한 번도 안 세어 봤다** — 73-build.sh 가
#         굽기 전에 쓰였고, **--preload 가 처음** 센다.
#         🔴 0 이 나오면 **되돌리기 전에 그 절의 안내부터 읽어라.**
#
#   ⑦ 🔴 **--count 에 여섯이 늘었다**(⑭~⑲).
#      🔵 ⓪·⓪-2·①~⑬ 은 **70→71→72 를 거쳐 온 것 그대로**다. **하나도 안 뺐다.**
#         🔴 「이번 범위 밖이니 지운다」고 착각하기 쉬운데, 지난 판들이 **「한 번
#            빼면 다시 넣는 사람이 없다」**고 반복해 적어 두었다.
#      🔴 늘어난 여섯은 **전부 재고 쪽**이다:
#         ⑭ 반환 신청(type='RETURN')을 **상태별로** · ⑮ 반출 신청(type='USE') ·
#         ⑯ [반환 완료]된 반환 수 · ⑰ **돌려줄 수 있는 부품이 있는 수리 건** ·
#         ⑱ **반환 원장 건**(ㅅ갈래 — 기록 내역 머리글 · **늦게 들어온 커밋**) ·
#         ⑲ **재고관리가 답하는가**(71번 ⑪ 의 자리).
#         🔴 **⑭~⑱ 은 ✗ 를 한 번도 안 낸다** — ✗ 를 내는 것은 **잣대 검사**뿐이다.
#         🔵 **⑭ 와 ⑱ 은 운영에서 0건일 수 있다** — 그 기능이 지금 생긴다.
#            🔴 **0 이 정상이고, 그러면 눈 확인에서 아무것도 안 보이는 것이 맞다.**
#
#   ⑧ 🔴 **tar 가 넷이고 묶음이 없다**(72번은 둘 + 없음).
#      🔵 **보낼 것이 /volume1/dss/images 로 넷뿐**이고 setup/incoming 에는
#         아무것도 안 간다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **72·71번에서 그대로 살린 것 — 한 번 빼면 다시 넣는 사람이 없다**
# ══════════════════════════════════════════════════════════════════════
#   · 2절 「DB 가 **안 바뀌었는가**」 — 🔵 이번에도 **다섯 집**(134·28·5·11·3) ·
#     쉰여덟째의 표 넷 · 도구 이미지 안 drizzle(🔴 A/S **0장** · 재고 **28장** —
#     **기대값이 정반대다**).
#   · 🔴 **--no-deps** 와 그 관문(DB 가 도는가 + **실제로 답하는가**) ·
#     끝에서 **DB 둘의 켜진 때 맞대기**. [실측 2026-11-18] 이것이 없어서 --go 가
#     dss-pg-app 을 Recreate 했다 — 자료는 멀쩡했지만 모든 연결이 끊겼다 붙었다.
#   · 함수 정의에 붙인 **</dev/null** — 고리 안의 docker exec 가 here 문서를 먹는다.
#     🔴 **이번 판은 집이 둘이라 그 결함이 실제로 티가 난다**(71번이 그랬다) —
#        고리가 한 바퀴만 돌면 **둘째 집이 아무 검사도 안 받는다.**
#        🔵 그래서 고리마다 「몇 개를 봤는가」를 끝에서 단언한다.
#   · 1-ㅂ 의 **한글 바이트 확인 절**(70→71→72 로 내려온 것) — 🔴 **이번 판은
#     한글 표식이 여섯이다**(뒷걸음 하나 + 기능 넷 + 짝 하나). **빼지 마라** —
#     한글 grep 이 깨지면 멀쩡한 이미지가 ✗ 가 된다(71번에서 실제로 났다).
#   · 덤프 · compose 사본 · db:preflight 를 값으로 받기.
#     🔴 다만 **덤프가 둘이 된다**(dss_as · dss_inventory) — 올라가는 집마다 하나다.
#     🔵 **preflight 는 A/S 에서만** 돈다(재고에는 그 명령이 없다 — 위 ④).
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
#       🔵 이 배포는 **자료를 한 글자도 안 바꾼다** — 전과 후의 수가 **전부**
#          같아야 정상이다. 🔴 **「칸이 생겨 수가 나타나는」 자리도 없다.**
#          🔵 다만 **⑭(반환 신청)과 ⑯(반환 완료)은 올린 뒤에 사람이 쓰기 시작하면
#             는다** — 그것이 **이 기능이 도는 증거**이지 사고가 아니다.
#   --preload
#       쓰는 것 : **NAS 의 도커 이미지 저장소**(docker load 로 태그 **넷**).
#       🔵 실어만 두고 **아직 안 갈아 끼운다.** 싣자마자 **안을 센다.**
#   --tools
#       쓰는 것 : **DB 덤프 두 장**(dss_as · dss_inventory) · **compose 사본 한 장** ·
#                 **compose 의 image: 줄 둘**(tools-as · tools-inventory).
#       안 쓰는 것: 🔴 **DB** · 볼륨 · 공유폴더 · 앱의 image: 줄 · 도는 앱 컨테이너.
#       🔵 profiles: [tools] 라 도구는 평소에 안 뜬다 — **직원이 느끼는 것이 없다.**
#       🔵 **덤프를 뜨는 까닭**: 이 배포는 DB 를 안 바꾸지만 **새 앱이 쓰는 쪽에서
#          무엇을 할지는 이 배포본이 모른다.** 🔴 이번 판은 **재고의 원장에 반환
#          줄이 실제로 쌓이기 시작한다** — 그래서 dss_inventory 덤프를 꼭 뜬다.
#       🔵 A/S 도구는 **db:preflight 를 돌려 값으로 받고**(대기 0건), 재고 도구는
#          **명령 없이 이미지 안을 센다**(.sql 28장 · 도구 표식 둘).
#   --go
#       쓰는 것 : **compose 사본 한 장** · **compose 의 image: 줄 둘**(app-as ·
#                 app-inventory) · **앱 둘을 다시 띄운다**(정지 창 — 40~60초).
#       안 쓰는 것: 🔴 **DB** · 볼륨 · 공유폴더 · 🔴 **나머지 여덟 집의 image: 줄**.
#       🔴 **--no-deps 를 쓴다** — 그것이 없어서 DB 가 Recreate 된 적이 있다.
#       🔴 **--tools 가 먼저 돌아야 한다** — 덤프와 preflight 가 거기서 끝난다.
#       🔴 **둘을 한 번에 띄운다** — 반쪽만 올리면 [반환 요청] 이 **빈 목록**이거나
#          **거절**된다(머리말의 「반쪽만 올라가는 것」).
#   --rollback
#       쓰는 것 : **compose 사본 한 장** · **app-as·app-inventory 의 image: 줄** ·
#                 **앱 둘을 다시 띄운다.**
#       안 쓰는 것: 도구 태그(새 판 그대로 둔다) · DB · 볼륨 · 덤프(안 뜬다).
#       🔵 **DB 는 되돌릴 것이 없다** — 이 배포는 칸을 한 개도 안 더했다.
#       🔴 **되돌리면 반환 기능이 통째로 사라진다** — 코드에만 있는 기능이다.
#          🔴 다만 **그 사이에 올라온 반환 신청 줄과 원장 줄은 자료라 남는다**
#             (되돌아가지 않는다). 🔵 남아도 해롭지 않다 — 재고 담당자가 화면에서
#             처리할 수 있고, 옛 A/S 는 그 줄을 쳐다보지 않는다.
#          🔴 **둘을 함께 되돌려라** — 한쪽만 되돌리면 반쪽만 올린 것과 같아진다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **이 환경의 함정 — 이 파일이 지키고 있는 것**
# ══════════════════════════════════════════════════════════════════════
#   ① 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 이다.** set -e 아래라면 검사가
#      그냥 **멈춘다.** 이 파일은 **$( … || true )** 로만 받는다.
#   ② 🔵 **tar | grep -q 에 물리는 자리가 아예 없다** — 이번 판은 묶음이 없어서
#      tar 를 읽는 자리가 한 군데도 없다. 🔴 묶음이 생기는 판에서는 71번의 3-ㄴ 을
#      되살리면서 **전부 세어서 담는 꼴**(grep -c · grep -o)도 함께 가져와라.
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
#      🔵 **이번 판은 거기 더할 것이 0건**이라 **줄었는지**만 본다.
#      🔴🔴 **재고는 정반대다 — 이미지 안에서 돈다**(28장). A/S 판을 베껴 「0장이어야
#         한다」로 재면 **멀쩡한 재고 도구가 ✗** 가 되고, 반대로 재고 판을 A/S 에
#         들이대면 **볼륨이 안 붙은 것을 못 잡는다**(69-deploy.sh 가 그 둘을 나란히
#         두고 「한 잣대로 뭉뚱그리지 마라」를 적어 두었다).
#   ⑦ 🔴 **저장소의 compose 사본은 운영보다 뒤처진다**(아홉 판 차이가 난 적이 있다).
#      이 파일은 **NAS 위의 docker-compose.nas.yml 만 읽는다.**
#   ⑧ 🔴 **bash 의 $(( )) 는 0 으로 시작하는 수를 8진수로 읽는다** — 0133·0134 를
#      셈에 넣지 않는다. 번호는 **글자로** 적어 두고 글자로 맞댄다.
#   ⑨ 🔴 **한글을 HTTP 머리말에 넣지 않는다.** 넣으면 요청이 아예 안 나가고
#      그 ✗ 가 진짜 결함처럼 보인다. 🔵 **그 규칙은 그대로다** — 이 파일이 던지는
#      HTTP 요청에는 한글이 한 글자도 없다.
#      🔴 **다만 번들 표식 여섯이 한글이다**(KO_MARKS 의 주석 — 72번은 하나였다).
#      그 한글이 가는 길은 **docker run -e 하나뿐**이고, **1-ㅂ 절이 여섯을 다
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
#   ⑮ 🔴 **repair_status 는 enum 이다.** 없는 글자를 그대로 맞대면 22P02 로
#      **거절**된다 — ⑫ 의 잣대 검사는 ::text 로 바꿔 묻는다(71번의 ⑦ 이 quotes
#      의 status 에서 같은 일을 했다).
#      🔴🔴 **재고 쪽은 enum 이 셋이다** — stock_requests.type(entry_type) ·
#         stock_requests.status(stock_request_status) · stock_entries.type(entry_type).
#         ⑭~⑰ 이 **전부 ::text 로 바꿔** 묻는다. 안 바꾸면 **잣대 검사가 22P02 로
#         거절되고**, 그 빈 결과가 「잣대가 죽었다」처럼 보인다.
#   ⑯ 🔴 **집이 둘이면 「둘째 집을 한 번도 안 보는」 꼴이 생긴다.** 71번이 그
#      자리를 하나씩 메워 두었다 — SITES·TOOLS 고리의 「몇 집을 봤는가」 ·
#      --count 의 「둘째 집이 답하는가」 · go_gate 의 둘째 가지 · preload 의 case.
#      🔴 **그 넷을 전부 되살렸다.** 하나라도 빠지면 재고가 조용히 안 재진다.
#
# ── 🔴 알고도 안 고친 것 — PO 가 모르는 것이 **여섯**이다 ──────────────
#   ① dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 APPROVAL_REQUIRED 가 없다.
#   ② PO 는 납품일 칸(delivered_date·delivered_by)을 모른다.
#   ③ PO 는 회차 승인(due_date_row_order)을 모른 채 같은 표를 고친다.
#   ④ PO 의 vendor/dss-core 핀이 8730c94 라 portal_approval_delegations 를 모른다.
#   ⑤ PO 는 domestic_order_due_dates 의 confirmed_at·confirmed_by 를 모른 채
#      같은 표를 고친다(예순일곱째가 더했다).
#   ⑥ PO 에서 PO발행일을 적으면 작업 상태가 안 옮겨진다(예순여덟째 · 2026-11-26 결정).
#   🔵 **이번 판은 거기에 하나도 안 더한다 — 여섯 그대로다.** 반환 기능은 A/S 와
#      재고관리 사이의 일이고 **PO 가 쓰는 표에 칸을 하나도 안 더했다**[실측:
#      마이그레이션 0건 · vendor/dss-core 0줄].
#   🔵 **지금은 안전하다** — 운영에서 직원의 PO 접근 권한을 모두 빼 두었다
#      (2026-11-08). 🔴 **PO 를 다시 여는 날 여섯을 한 묶음으로 이식해야 한다.**
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v69-$STAMP
BKDB=$D/backups/db
# 🔴 **BK 와 같은 v 번호여야 한다** — 59번(쉰다섯째)이 여기를 안 고쳐 v54 로 남긴
#    적이 있다. 아래 1-ㄱ-0 절이 값으로 확인한다.
DUMP_VER=v69
INCOMING=$D/setup/incoming
MIGDIR=$D/as-migrations
IMG_MIGDIR=/app/drizzle
TPLDIR=$D/as-templates
# 🔵 **MIGTAR 변수가 없다** — 이번 판은 묶음을 안 보낸다(머리말 「왜 없는가」 ②).
#    🔴 묶음이 생기는 판에서는 **71-deploy.sh 에서 셋을 한 벌로** 되살려라:
#       MIGTAR · MIGTAR_SIZE·MIGTAR_MD5 · 3-ㄴ 절 · place_migs().
#    🔵 1-ㅁ 절은 그래서 「쳐다보지도 않는다」 쪽이다 — 거기 묶음이 보이면 **옛 판의 것**이다.

# ══ 🔴 앱 **둘** ══════════════════════════════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트포트|사람이 부르는 이름
#   🔴 **재고관리가 여기로 올라왔다** — 72번은 앱이 A/S 하나뿐이었다.
#      🔵 **표 꼴은 71·72번 그대로다** — 집이 둘이 되는 날 줄만 더하면 된다고
#         72번이 적어 두었고, **그 날이 이번**이다.
#   🔵 재고의 서비스·상자·포트는 **69-deploy.sh(예순다섯째)에서 가져왔다** —
#      그 판이 dss-inventory:0.7 → 0.8 을 그 값으로 올렸다.
#   🔴 **차례에 뜻이 있다**(7-ㄷ 의 주석) — A/S 를 먼저 띄운다.
SITES='
as|app-as|dss-as|dss-as:6.4|dss-as:6.3|dss-as-6.4.tar|13000|A/S관리
inventory|app-inventory|dss-inventory|dss-inventory:0.9|dss-inventory:0.8|dss-inventory-0.9.tar|13800|재고관리
'
SITES_WANT=2

# ══ 🔴 도구 **둘** — --tools 가 이 줄들을 간다 ════════════════════════
#   열쇠|서비스|새 태그|옛 태그|tar|이름|무엇 때문에 가는가
#   🔵 72번처럼 마이그레이션이 0건이라 그 자리가 **--tools** 다(65·64·63·69·70 과
#      같은 꼴). 🔴 **71번처럼 --migrate 안에서 갈지 않는다** — 올릴 .sql 이 없다.
#   🔴 **재고 도구에는 db:preflight 도 check:* 도 없다**[실측 2026-11-26 · 명령 17개] —
#      그래서 --tools 가 **그 집에서는 명령을 안 돌리고 이미지 안을 센다**(69번 꼴).
TOOLS='
astools|tools-as|dss-as-tools:31|dss-as-tools:30|dss-as-tools-31.tar|A/S도구|🔴 src/ 20장이 바뀌었다 — 그 안에서 도는 db:preflight·check:* 가 그 소스로 돈다
inventorytools|tools-inventory|dss-inventory-tools:6|dss-inventory-tools:5|dss-inventory-tools-6.tar|재고도구|🔴 src/ 26장이 바뀌었다 — 도구가 그 소스로 돌고 .sql 28장도 이 이미지 안에 있다
'
TOOLS_WANT=2

# ══ 🔴 안 건드리는 **여덟** — 「옆으로 안 샜다」는 증거로 센다 ════════
#   🔴 상자 이름이다(서비스 이름이 아니다) — 저장소의 compose 사본이 운영보다
#      뒤처져 있어 서비스 이름을 믿을 수 없다(⑦).
#   🔴🔴 **dss-inventory 가 여기서 빠졌다**(72번은 아홉이었다 — 거기선 안 건드렸다).
#      **dss-auth 는 그대로 남아 있다**(71번에서는 빠져 있었다 — 거기선 올라갔다).
#      🔴 1-ㄷ 이 **「dss-auth 가 있는가(1)」와 「dss-inventory 가 없는가(0)」를
#         같은 줄에서 함께** 센다. 한쪽만 재면 번호가 빗나가도 통과한다.
KEEP_BOXES="dss-approvals dss-leave dss-meters dss-board dss-improvements dss-rf-trouble dss-po dss-auth"
KEEP_BOXES_WANT=8
KEEP_DB="dss-pg-app dss-pg-auth"
KEEP_DB_WANT=2

# ══ 🔵 **DB ① — 「움직이는 집」 표(MIGS)가 없다** ═════════════════════
#   🔴 71번에는 여기에 MIGS 표와 MIGS_WANT 가 있었고, 거기서 DBPHASE 가 나왔다.
#      까닭은 머리말의 「왜 없는가」 ①③ — 이번 판도 **움직이는 집이 0곳**이다.
#   🔴 **A/S 도 재고도 아래 MIGS_KEEP 에 있다.** 🔴 「올라가는 집이니 MIGS_KEEP 에서
#      빼야지」가 **틀린다** — 집이 올라가는 것과 DB 가 바뀌는 것은 다른 말이다
#      (71번이 포털에, 72번이 A/S 에 적어 둔 그 문장이 이번에는 **재고에** 적용된다).

# ══ 🔴 DB ② — **안 바뀌어야 하는 다섯 집** ═══════════════════════════
#   열쇠|DB상자|DB이름|지금도 뒤에도 이 수여야 한다|사람이 부르는 이름
#   🔴 **어긋나면 이 배포와 무관한 다른 사고다.** 그 자리에서 멈춘다.
#   🔴 **A/S 가 134 다** — 예순일곱째가 0132·0133 을 올려 132 → 134 가 됐다.
#      🔴 **132 로 두면 멀쩡한 운영에서 ✗** 가 나고, 그 ✗ 는 진짜 사고처럼 보인다.
#   🔴 **재고가 28 이다** — 예순다섯째(69번) 때도 28 이었고 이번에도 안 움직인다.
#      🔴 **올라가는 집인데도 여기 있다** — 집이 올라가는 것과 DB 가 바뀌는 것은
#         다른 말이다[실측 2026-11-26: 이번 범위의 drizzle/ 변경 0줄].
#   🔵 통합 승인함은 **DB 가 없는 집**이라 이 표에 없다 — 「0건」이 아니라 해당 없음이다.
MIGS_KEEP='
as|dss-pg-app|dss_as|134|A/S관리
inventory|dss-pg-app|dss_inventory|28|재고관리
leave|dss-pg-app|dss_leave|5|휴가관리
auth|dss-pg-auth|dss_auth|11|통합로그인포털
meters|dss-pg-app|dss_meters|3|계측기관리
'
MIGS_KEEP_WANT=5

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
#   🔴 **71번과 뜻이 뒤집힌 표다**(머리말 ③) — 거기서는 「이번 판이 만드는 칸」이라
#      적용 전에는 **없어야** ✓ 였다. 🔴 **이 판에서는 늘 있어야** ✓ 다.
#   🔴 **표를 지우지 않았다** — 지우면 DB 가 되감긴 날 아무도 못 잡는다.
#   🔴 **「있는가」만 보지 않고 꼴까지 본다** — 같은 이름으로 다른 꼴을 만든 것을
#      가르려면 자료형을 봐야 한다(2026-11-07 에 배운 것).
#   🔵 넷 다 **NULL 을 허용**한다.
NEWCOLS='
dss-pg-app|dss_as|domestic_order_due_dates|confirmed_at|timestamp with time zone|YES|납기요청일 회차 확정 시각 (0133)
dss-pg-app|dss_as|domestic_order_due_dates|confirmed_by|uuid|YES|확정한 사람 (0133)
dss-pg-app|dss_as|procedure_template_nodes|share_doc_relative_path|text|YES|절차 본보기 노드의 파일 자리 (0132)
dss-pg-app|dss_as|repair_case_flowchart_nodes|share_doc_relative_path|text|YES|진단 Flowchart 노드의 파일 자리 (0132)
'
NEWCOLS_WANT=4

# ══ 🔵 **마이그레이션 안전 잣대(DESTRUCTIVE_RE)가 없다** ══════════════
#   🔴 71-deploy.sh:348-349 에 그 둘이 있었고 3-ㄴ 이 표본 셋으로 잣대부터 쟀다.
#      까닭은 머리말의 「왜 없는가」 ② — **이번 판은 잴 .sql 이 한 장도 없다.**
#   🔴 **.sql 이 한 장이라도 생기면 그 잣대와 표본 셋을 먼저 되살려라** —
#      잣대가 없으면 「지우는 문장 0줄」이 **아무것도 안 재는 ✓** 가 된다.
#      🔵 71번이 셋째 표본(ON DELETE restrict)을 그때 더했다. **그것까지** 가져와라.

# ══ 🔴 A/S 마이그레이션 볼륨 — **134장 그대로여야 한다** ══════════════
#   🔵 예순일곱째가 0132·0133 을 올려 132 → 134 가 됐다. **이번 판은 안 움직인다.**
AS_VOL_SQL_WANT=134
# 🔴 **「없는가」만 재면 번호가 빗나가도 통과한다** — 반대쪽 「있는가」를 같은 줄에서
#    함께 센다(70번이 AS_VOL_NEXT 가 한 칸 빗나가 **두 판 연속 아무것도 안 막은**
#    것을 잡아낸 뒤로 생긴 규율이다).
AS_VOL_LAST=0133
AS_VOL_NEXT=0134

# ══ 🔴🔴 재고 마이그레이션 — **도구 이미지 안에 28장**이어야 한다 ════
#   🔴 **A/S 와 정반대다**(머리말의 함정 ⑥). A/S 도구 이미지는 **0장**이어야 하고
#      재고 도구 이미지는 **28장**이어야 한다. 69-deploy.sh 가 그 값을 쓰던 자리다.
#   🔵 **이번 판은 거기에 한 장도 안 더한다** — 0028 이 생기면 전제가 깨진 것이다.
#   🔴 **「없는가」만 재지 않는다** — 0027 이 아직 있는지 같은 줄에서 함께 센다.
INV_IMG_SQL_WANT=28
INV_IMG_LAST=0027
INV_IMG_NEXT=0028
# 🔵 **이번 범위에서 바뀐 재고 시험 파일 수** — 판정에 안 쓰고 **말에만** 쓴다
#    (「바뀐 N장이 이미지 밖인 까닭」을 적는 자리). 🔴 이 수가 달라져도 ✗ 가 나지
#    않는다 — 재고의 시험은 .dockerignore 가 막아 **이미지에 애초에 안 들어간다.**
#    🔵 [실측 2026-11-26] 11장. 범위가 늘면 여기만 고치면 된다.
INV_TESTS_NOTE=12

# ══ 🔴 tar **넷**의 지문 — [배포본] 73-build.sh 가 굽고 **바로 잰 값** ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 비어 있다 — 굽기 전에 쓴 파일이다.** 73-build.sh --go 가 꼬리말에
#      찍는 **네 줄**로 아래를 통째로 갈아 끼운 **뒤에** scp 하세요.
#   🔴 **이 값을 NAS 에서 재서 채우지 마라.** 그러면 「옮기다 깨졌는가」를 자기가
#      잰 값으로 자기를 재는 꼴이 되어 **영영 통과한다.** 반드시 **구운 쪽**에서 잰다.
#   🔴 비어 있으면 3절이 **--check·--count·--rollback 에서는 ? · --preload·
#      --tools·--go 에서는 ✗** 로 센다. 🔵 막는 것은 **✗ 뿐이다.**
#      🔴 **쉰세째에는 빈 표가 그대로 NAS 로 올라갔고 --preload 가 ✗ 둘로 멈췄다.**
#   🔵 **지난 판 바이트**(73-build.sh 의 ①번 크기 견주기가 쓰는 값):
#      dss-as-6.3.tar 136938496 · dss-as-tools-30.tar 227207680   (72-deploy.sh:418-421)
#      dss-inventory-0.8.tar 95470592 · dss-inventory-tools-5.tar 213350912
#                                                                 (69-deploy.sh:294-297)
#   🔵 **이름만 적고 값 칸은 비워 둔다** — 그래야 3절이 「표가 깨졌다」가 아니라
#      「지문이 비어 있다」로 센다.
TARS='
dss-as-6.4.tar|||
dss-as-tools-31.tar|||
dss-inventory-0.9.tar|||
dss-inventory-tools-6.tar|||
'
TARS_WANT=4
# ══ 🔵 **묶음의 지문(MIGTAR_SIZE·MIGTAR_MD5)이 없다** ═════════════════
#   🔴 71-deploy.sh:433-442 에 그 변수 둘이 있었다. 까닭은 머리말의 「왜 없는가」 ② —
#      **이번 판은 묶음을 안 만들고 안 보낸다.**
#   🔴 묶음이 생기는 판에서는 **71번에서 셋을 한 벌로** 되살려라(변수 둘 · 3-ㄴ 절 ·
#      place_migs()). 🔴 **하나만 되살리면 묶음을 받고도 안을 한 번도 안 세거나,**
#      **풀지 않은 채 db:migrate 를 돌려 0건으로 조용히 끝난다.**

# 🔴 tar 이름 → 태그. **정규식으로 되돌리지 않는다** — 이름마다 손으로 적는다.
#    🔴 판에 점이 있는 것과 없는 것이 섞여 있어 한 규칙으로 안 풀린다.
tar2tag() {
  case "$1" in
    dss-as-6.4.tar)              printf 'dss-as:6.4' ;;
    dss-as-tools-31.tar)         printf 'dss-as-tools:31' ;;
    dss-inventory-0.9.tar)       printf 'dss-inventory:0.9' ;;
    dss-inventory-tools-6.tar)   printf 'dss-inventory-tools:6' ;;
  esac
}

# ══ 🔴 이미지 안에서 쓸 표식 — **전부 리터럴 · 넷이 한글** ════════════
#   열쇠|갈래(feature|keep|side)|글자|사람이 읽을 말
#   🔴 **공백이 든 표식이 있고 한글이 넷이다.**
#      그래서 이 표는 tr -d ' ' 로 읽지 않고 **here 문서 + IFS='|' read** 로만 읽는다.
#   🔴 **전부 리터럴이어야 한다** — 코드 줄에서 따오면 minify 가 지우고, 웹팩이
#      production 에서 **export 이름까지 줄인다**(mangleExports).
#      [71번 실측 2026-11-25 · dss-as:6.2 번들] part.drawingNo, part.note = **0/0**.
#   🔵 **이번 판은 집마다 기능 표식이 셋씩 있다** — 72번처럼 「갈래는 셋인데 표식이
#      둘」인 자리가 없다. 두 집 다 **새 문자열 리터럴**이 생겼기 때문이다.
#      🔴 그래도 **도구 표식 넷을 함께 둔다**(아래 TOOLMARKS) — 번들은 minify 를
#         거치므로 「거기 없다」가 「코드가 없다」와 같은 말이 아니다.
#   🔴 **집마다 「마지막 커밋의 글자」를 하나씩** 넣었다:
#      A/S  부품 신청 거두기            ← b281ff9b (**마지막 커밋**)
#      재고  부품 반환이 완료되었습니다  ← 117d6c7  (**마지막 커밋**)
#      🔴 그것이 0 이면 **커밋 하나가 빠진 판**을 구운 것이다.
#   🔴🔴 **아래 수는 번들에서 한 번도 안 세어 봤다** — 73-build.sh 가 굽기 전에
#      쓰였고 **--preload 가 처음** 센다.
#      🔵 **71번이 구운 번들에서 세어 둔 것**(A/S 뒷걸음 · 참고):
#         shareDocRelativePath **23** · 도번 / 비고 **2** · hasLiveApproval 3 ·
#         domesticOrders.completedEdit 5 · faultTags 19 · radiogroup 5 ·
#         "ORDER_ISSUED" 2 · domestic-order-status-filter 2 ·
#         portal_approval_delegations 23 · domesticOrders.view 8.
#      🔵 **NO_WAITING_REPAIR_STEP 은 번들 수가 안 적혀 있다** — 다만 72번이
#         그것을 **기능 표식**으로 두고 --preload 를 지나 --go 까지 갔으므로
#         **dss-as:6.3 번들에서 ≥1 이었다**(0 이었으면 거기서 멈췄다).
#         🔵 같은 근거로 재고의 drawing-no-text-color 는 dss-inventory:0.8 에서 ≥1 이다
#            (69번이 기능 표식으로 썼다).
#      🔴 **뒷걸음이 0 이면 진짜 결함이다.**
#   🔴 feature = 번들에 **있어야** 한다 · keep = 뒷걸음 · side = **판정에 안 쓴다**
APPMARKS='
as|feature|반환 요청|🔴 **한글** · 반환 기능의 화면 글자 (5c02d985 · 소스 기준 0 → 지금 8파일)
as|feature|return-candidates|🔵 **ASCII** · 돌려줄 수 있는 부품을 묻는 통로 주소 (5c02d985 · 기준 0 → 3파일)
as|feature|부품 신청 거두기|🔴 **한글** · **마지막 커밋 b281ff9b** 의 글자 (기준 0 → 1파일)
as|side|INVENTORY_RETURN_REQUEST_TYPE|곁들이 — 그 상수의 **export 이름**(웹팩이 줄일 수 있다)
as|keep|NO_WAITING_REPAIR_STEP|예순여덟째가 올린 문자열 리터럴 (🔵 72번의 기능 표식이 내려왔다)
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
inventory|feature|return-candidates|🔵 **ASCII** · A/S 에 내주는 통로 주소 (ff0836c·5d8767e · 기준 0 → 7파일)
inventory|feature|돌려받을 내용을 확인하십시오|🔴 **한글** · 반환 확인 창의 제목 리터럴 (7256b75 · 기준 0 → 1파일)
inventory|feature|부품 반환이 완료되었습니다|🔴 **한글** · **마지막 커밋 117d6c7** 의 종 글자 (기준 0 → 2파일)
inventory|side|RETURN_COMPLETED_ID_PREFIX|곁들이 — 종 id 의 **export 이름**(웹팩이 줄일 수 있다)
inventory|keep|drawing-no-text-color|예순다섯째가 올린 DOM id (🔵 69번의 기능 표식이 내려왔다)
inventory|keep|portal_approval_delegations|쉰여덟째가 올린 글자
inventory|keep|stock_issue_approval_steps|그 앞 판이 올린 표 이름
'
# 🔴 번들에서 **판정에 쓰는** 표식 수 — **집마다 다르다.** 🔵 곁들이는 안 들어간다.
#    A/S  기능 3 + 뒷걸음 11 = **14**   (72번은 기능 2 + 뒷걸음 10 = 12 였다)
#    재고  기능 3 + 뒷걸음 3  = **6**   (69번은 기능 1 + 뒷걸음 2 였다)
AS_MARKS_WANT=14
INV_MARKS_WANT=6

# ══ 🔴🔴 **한글 표식 — 이 판에는 넷이다** (70→71→72 에서 가져왔다) ══
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
#      🔵 **dss-as:6.4 에서도 같은 값이 나와야 한다** — 그 placeholder 를 건드린
#         커밋이 이번 범위에 **0장**이다.
#   🔴🔴 **이번 판은 한글이 넷으로 늘었다** — 기능 표식 넷이 전부 화면 글자라서다.
#      A/S [반환 요청]·[부품 신청 거두기] · 재고 [돌려받을 내용을 확인하십시오]·
#      [부품 반환이 완료되었습니다]. 🔴 **그래서 1-ㅂ 절이 더 중요해졌다** —
#      한글 경계가 깨지면 **멀쩡한 이미지 둘이 한꺼번에 ✗** 가 난다.
#      🔵 그 자리에서 **ASCII 표식(return-candidates)이 ✓ 인데 한글만 0** 이면
#         그것 자체가 「검사가 깨진 것」이라는 증거다(ASCII 대조).
#      [실측 2026-11-26 · 개발 PC] 보낼 바이트 수:
#         [도번 / 비고] **15** · [재고 관리에서 찾기] **26** ·
#         [반환 요청] **13** · [부품 신청 거두기] **23** ·
#         [부품 반환이 완료되었습니다] **38** · [돌려받을 내용을 확인하십시오] **41**
#      🔵 앞의 둘은 70번이 2026-11-20 에 잰 값과 **같다.**
#   🔵 **HTTP 머리말에는 한글을 한 글자도 안 넣는다** — 그 규칙은 그대로다.
#      여기서 한글이 가는 길은 **docker run -e 하나뿐**이고, 그것을 1-ㅂ 이 잰다.
#   🔵 [재고 관리에서 찾기] 는 **판정에 안 쓰는 짝**이다 — 같은 placeholder 의
#      앞부분이라, 경계가 멀쩡한지 **두 글자로** 재면 「우연히 한 글자만 통과」를 가른다.
KO_MARKS='
도번 / 비고
재고 관리에서 찾기
반환 요청
부품 신청 거두기
돌려받을 내용을 확인하십시오
부품 반환이 완료되었습니다
'
KO_MARKS_WANT=6

# ══ 🔴🔴 도구 이미지에서 쓸 표식 — **집마다 둘씩 넷이다** ═════════════
#   열쇠|표식|그 표식이 있어야 하는 파일|그 파일 안 기대 줄 수
#   🔴 도구에는 소스가 **글자 그대로** 들어 있다 — minify 를 안 탄다. 번들에서
#      「없다」가 「코드가 없다」와 같은 말이 아니므로 **여기서 한 번 더** 가른다.
#   🔵 **과녁 넷 다 기준판에도 있던 파일**이다[실측 2026-11-26 · git cat-file] —
#      새 파일을 과녁으로 삼으면 「기준 0줄」이 **파일이 없어서 0** 인 것이라
#      아무것도 안 가른다. (A/S 의 inventory-return.ts 와 재고의 return-candidates.ts
#      는 **새 파일**이라 과녁으로 안 썼다 — 그 둘은 아래 KEY_FILES 가 [ -f ] 로 묻는다.)
#   🔴 **A/S 는 「올리는 쪽」, 재고는 「받는 쪽」을 과녁으로 골랐다** — 한 기능이
#      두 집에 걸쳐 있어서, 한쪽만 재면 **반쪽만 올라간 것**을 못 가른다.
#   🔴 **preload_inside 가 이 표를 고리로 돈다** — 71번은 row_by_key 로 **한 줄만**
#      꺼냈다. 그대로 두면 두 줄이 이어 붙어 표식이 통째로 깨진다.
TOOLMARKS='
astools|createInventoryReturnRequestAction|src/lib/server/actions/inventory-stock-requests.ts|1
astools|INVENTORY_RETURN_REQUEST_TYPE|src/lib/server/inventory-gateway.ts|3
inventorytools|returnableLinesByIntake|src/lib/stock/queries.ts|1
inventorytools|RETURN_COMPLETED_ID_PREFIX|src/lib/notifications/bell-items.ts|2
'
TOOLMARKS_WANT=4
# 🔴 도구 이미지 **하나가** 몇 개를 돌아야 하는가 — 고리가 한 바퀴만 돌면
#    한쪽 갈래가 **아무 검사도 안 받는다.**
TOOLMARKS_PER_IMAGE_WANT=2
PROBE_MISS=src/__dss_probe_no_such_file__.ts

# ══ 🔴 **핵심 파일 표본** — 도구 이미지가 담고 있어야 한다 ════════════
#   🔵 **집마다 따로 묻는다**(71번 꼴) — 담기는 길이 집마다 다르다.
#   🔴 **A/S 목록의 끝 두 장은 글롭 잣대다.** 🔵 이번 범위에는 괄호·대괄호가 든
#      경로가 **하나 있다**(repair-cases/[id]/page.tsx — 72번에는 0장이었다).
#      그래도 **범위 밖의 한 장을 더 둔다** — 길이 끊기면 그 둘이 **먼저 no 로**
#      떨어져 「옛 소스가 담겼다」와 갈린다.
AS_KEY_FILES='
src/lib/domain/inventory-return.ts
src/lib/domain/inventory-contract.ts
src/lib/domain/inventory-gateway.ts
src/lib/server/inventory-gateway.ts
src/lib/server/actions/inventory-stock-requests.ts
src/components/repair-cases/detail/PartRequestSection.tsx
src/components/repair-cases/detail/RepairCaseDetailView.tsx
src/lib/db/queries/repair-cases.ts
src/app/(app)/repair-cases/[id]/page.tsx
src/app/(app)/domestic-orders/page.tsx
'
AS_KEY_FILES_WANT=10
# 🔴 **재고 목록에는 tests/ 를 한 장도 안 넣는다** — .dockerignore 가 tests 를
#    막아서(69번이 값으로 쟀다) 이미지 안에 **없는 것이 정상**이다. 넣으면 멀쩡한
#    이미지가 ✗ 가 된다. 🔵 API.md 도 같은 까닭으로 안 넣는다(*.md 를 막는다).
#    🔵 끝의 한 장이 **괄호가 든 경로**다 — 글롭 잣대다.
#    🔵 **끝에서 둘째가 늦게 들어온 커밋(18f5381)의 새 파일**이다 — 그 한 장이
#       빠지면 [기록 내역] 화면이 import 에서 죽는다.
INV_KEY_FILES='
src/lib/api/return-candidates.ts
src/lib/api/return-allocation.ts
src/lib/stock/return-request-view.ts
src/app/api/v1/return-candidates/route.ts
src/app/api/v1/stock-requests/route.ts
src/components/stock/ReturnSourceLine.tsx
src/lib/stock/queries.ts
src/lib/stock/requests.ts
src/lib/notifications/bell-items.ts
src/lib/stock/entry-title.ts
src/app/(app)/requests/page.tsx
'
INV_KEY_FILES_WANT=11

# ══ 🔴 public/ 기대값 — **집마다 다르다** ═════════════════════════════
#   열쇠|폴더가 있나(yes|no)|이미지 안 파일 수(참고)|**판정에 쓰는 최솟값**
#   🔴🔴 **넷째 칸이 이번에 생겼다.** 72번은 「yes 면 파일이 1개 이상」을 **박아**
#      두었는데, 🔴 **재고의 public/ 은 있는데 비어 보인다**(.gitkeep 한 장뿐이고
#      ls -1 은 숨은 파일을 안 센다 — 69-deploy.sh:341-344 가 값으로 적어 두었다).
#      그대로 베꼈으면 **멀쩡한 재고 앱이 ✗** 가 났을 것이다(62번이 그 가짜 ✗ 를 냈다).
#   🔵 **검사를 약하게 만든 것이 아니다** — A/S 는 여전히 **9개 이상**(최솟값 1 이
#      아니라 참고값까지 함께 찍는다)이고, 재고는 **「폴더가 있는가」**가 판정이다.
#      🔴 폴더가 아예 없으면 정적 파일이 404 가 되고 COPY 가 멈춘 것이다.
PUBLIC_WANT='
as|yes|9|1
inventory|yes|0|0
'
PUBLIC_WANT_N=2

# ══ 🔵 --count 의 참고값 — [운영 실측 2026-11-19 · 예순한째 배포 뒤] ═══
#   🔴 **이것은 ✗ 를 내는 기대값이 아니다.** 사람이 내자 줄을 더하거나 발주일을
#      적으면 정상적으로 달라진다 — 다르면 **⚠️ 로만** 센다.
#   🔴 ✗ 를 내는 것은 **②-ㄴ 의 관문 둘**과 **잣대 검사들**(없는 값으로 물어 0 이
#      나오는가)뿐이다.
#   🔵 **70번이 쓰던 값을 글자 그대로 가져왔다** — 예순여섯째 배포는 읽는 쪽
#      기능이라 이 수들을 한 자리도 안 바꿨다.
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
#      쉬운데, 지난 판들이 **「한 번 빼면 다시 넣는 사람이 없다」**고 반복해 적어
#      두었다. 🔵 내린 것은 **⑪(포털이 답하는가)** 하나뿐이다 — 포털이 안 올라간다.
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

# ══ 🔴🔴 **72번 고유 — 이번에 올리는 것이 운영에서 실제로 도는가** ════
#   🔴 **셋 다 보는 칸이 이미 있다** — 71번처럼 「칸이 있는지 먼저 묻기」가 필요
#      없다(0132·0133 이 예순일곱째에 올라갔고, 나머지는 2026-08 부터 있는 칸이다).
#   🔴 **셋 다 ✗ 를 한 번도 안 낸다** — ✗ 를 내는 것은 **잣대 검사**뿐이다.
#   🔴 **이 배포는 자료를 한 글자도 안 바꾼다** — 전과 후의 수가 **같아야** 정상이다.
#   🔴 표·칸 이름은 전부 **스키마에서 확인한 것**이다(vendor/dss-core 의 workflow.ts ·
#      repair-cases.ts · domestic-order-due-dates.ts). 지어내지 않았다.
#
# ── ⑪ 🔴 **확정된 회차 중 「완료된」 것** — ㄱ 갈래가 화면에서 지우는 줄
#   🔵 화면 판정은 도메인 한 곳이 쥔다(showDomesticOrderDueDateConfirmControls):
#      **줄의 완료**(domestic_orders.completed_at)든 **그 회차의 완료**
#      (domestic_order_due_dates.completed_at)든 하나라도 차 있으면 셋이 다 사라진다.
#   🔴 **아래 셋은 뜻이 다르다. 섞어 읽지 마라:**
#      ㄱ) 확정된 회차 **전체**            — ⑧ 과 같은 수다(그 줄이 먼저 센다)
#      ㄴ) 그중 **줄이나 회차가 완료된 것** — 🔴 **「확정 ✓」 표까지 사라지는 줄**
#      ㄷ) 완료된 회차 **전체**            — 🔵 **단추가 사라지는 줄의 상한**
#          (확정 안 된 줄에서도 [납기일 확정] 단추가 사라진다 — 고칠 수 있는
#           세션에서만 보이던 단추다)
#   🔵 **0 이어도 정상이다** — 그러면 눈 확인에서 **아무것도 안 바뀐 것이 맞다.**
DUE_CONFIRMED_DONE_SQL="select count(*) from domestic_order_due_dates d join domestic_orders o on o.id = d.domestic_order_id where o.is_deleted = false and d.confirmed_at is not null and (o.completed_at is not null or d.completed_at is not null)"
DUE_DONE_ANY_SQL="select count(*) from domestic_order_due_dates d join domestic_orders o on o.id = d.domestic_order_id where o.is_deleted = false and (o.completed_at is not null or d.completed_at is not null)"
#
# ── ⑫ 🔴 **작업 상태가 [수리 대기]인 건** — ㄴ 갈래가 옮기는 자리
#   🔴 **상태는 저장 칸이 아니다** — repair_cases.current_workflow_step_id 가 가리키는
#      workflow_steps 의 **repair_status** 에서 나온다(mappers/repair-status.ts).
#      그래서 「작업 상태가 [수리 대기]인 건」은 **조인해서** 세어야 한다.
#   🔵 **앱이 쓰는 조건 그대로다** — mutations/po-issued-repair-waiting.ts 가
#      repair_cases ⋈ workflow_steps 를 같은 칸으로 잇고 is_deleted = false 로 좁힌다.
#   🔴 **is_active 로 안 좁힌다** — 앱의 판정(decidePoIssuedRepairWaiting)이 그 칸을
#      안 본다. 좁히면 **앱과 다른 수**가 된다.
WR_STATUS=WAITING_REPAIR
WR_CASES_SQL="select count(*) from repair_cases c join workflow_steps s on s.id = c.current_workflow_step_id where c.is_deleted = false and s.repair_status::text = '$WR_STATUS'"
# 🔴 **그 상태의 단계가 운영에 몇 개 있는가** — 🔵 **유상 셋에만 있고 무상에는 없다.**
#    그래서 **무상 워크플로에 선 건은 이 기능이 아예 안 걸린다**(NO_WAITING_REPAIR_STEP).
WR_STEPS_SQL="select count(*) from workflow_steps where repair_status::text = '$WR_STATUS'"
# 🔵 그 단계가 **없는 워크플로 버전**이 몇인가 — 그 버전에 선 건은 날짜를 적어도
#    아무 일도 안 일어난다(정상 갈래다).
WR_VER_NOSTEP_SQL="select count(*) from workflow_versions v where not exists (select 1 from workflow_steps s where s.workflow_version_id = v.id and s.repair_status::text = '$WR_STATUS')"
# 🔴 **없는 상태로 물어 0 이 나오는가** — 🔵 repair_status 는 **enum** 이라 없는 글자를
#    그대로 맞대면 22P02 로 **거절**된다. 그래서 ::text 로 바꿔 묻는다(71번의 ⑦ 과 같은 처방).
WR_PROBE_SQL="select count(*) from workflow_steps where repair_status::text = '__dss_probe_no_such_status__'"
#
# ── ⑬ 🔴 **납품 요청일을 「빌려 오는」 건** — ㄷ 갈래가 화면을 바꾸는 줄
#   🔴 그 건에 적힌 고객 요청 납기일(repair_cases.customer_requested_due_date)이
#      **비었는데** 연결된 내자 줄에 납기요청일이 **있는** 건이다.
#      🔵 customer_requested_due_date 는 **date 칸**이라 공백이 섞일 수 없다 —
#         IS NULL 하나로 「비었다」가 다 걸린다.
#   🔵 읽는 조건은 공용 조각과 같다(queries/repair-case-domestic-order-due-dates.ts):
#      **domestic_orders.is_deleted = false** 인 줄의 회차만 센다.
#   🔴 **이 수가 곧 이 배포로 화면이 달라지는 줄 수**다 — 0 이면 눈 확인에서
#      **아무것도 안 바뀌는 것이 정상**이다.
#   🔵 [2026-10-30 실측] 「npm run check:requested-due-date-sync」 의 ④ 「내자에만 적힘」이
#      **8건**이었다. 🔴 그 수와 아래 수는 **같은 뜻이 아니다**(그쪽은 휴지통과
#      출하 완료를 다르게 센다) — **참고값으로만** 쓴다.
BORROW_ALL_SQL="select count(*) from repair_cases c where c.is_deleted = false and c.customer_requested_due_date is null and exists (select 1 from domestic_orders o join domestic_order_due_dates d on d.domestic_order_id = o.id where o.repair_case_id = c.id and o.is_deleted = false)"
# 🔴 **고객 안내 현황은 출하 완료를 뺀다**(queries/customer-portal.ts 의 그 한 줄) —
#    그래서 **그 화면이 실제로 보는 수**는 아래다. 🔵 위는 **상한**이다.
BORROW_PORTAL_SQL="select count(*) from repair_cases c join workflow_steps s on s.id = c.current_workflow_step_id where c.is_deleted = false and s.repair_status::text <> 'SHIPMENT_COMPLETED' and c.customer_requested_due_date is null and exists (select 1 from domestic_orders o join domestic_order_due_dates d on d.domestic_order_id = o.id where o.repair_case_id = c.id and o.is_deleted = false)"
# 🔴 **없는 칸으로 물어 0 이 나오는가** — 「무조건 0」인 질의인지 가른다.
BORROW_PROBE_SQL="select count(*) from repair_cases c where c.is_deleted = false and c.customer_requested_due_date is null and exists (select 1 from domestic_orders o join domestic_order_due_dates d on d.domestic_order_id = o.id where o.repair_case_id = c.id and o.is_deleted = false and d.due_date = date '1900-01-01')"
CNT_BORROW_REF=8

# ══ 🔴🔴 **73번 고유 — 반환이 운영에서 실제로 돌 자리** (⑭~⑰) ════════
#   🔴 **전부 dss_inventory 다**(dss-pg-app 안에 있다). A/S 쪽 DB 는 이 기능으로
#      칸도 줄도 안 늘린다 — A/S 는 **통로로 보내기만** 한다.
#   🔴 **넷 다 ✗ 를 한 번도 안 낸다** — ✗ 를 내는 것은 **잣대 검사**뿐이다.
#   🔴 표·칸 이름은 전부 **스키마에서 확인한 것**이다
#      (dss-inventory/src/db/schema/stock-requests.ts · stock.ts). 지어내지 않았다.
#   🔴🔴 **셋 다 enum 이다** — stock_requests.type 과 stock_entries.type 은
#      entry_type, stock_requests.status 는 stock_request_status. 없는 글자를
#      그대로 맞대면 **22P02 로 거절**되므로 **잣대 검사는 ::text 로 바꿔** 묻는다.
INV_BOX=dss-pg-app
INV_DB=dss_inventory
REQ_TABLE=stock_requests
#
# ── ⑭ 🔴 **반환 신청(type='RETURN')** — 🔵 **운영에는 0건일 것이다**
#   🔴 **이 기능이 지금 생긴다.** 그러니 **0 이 정상**이고, 그러면 눈 확인에서
#      재고의 신청 목록에 **반환이 한 줄도 안 보이는 것이 맞다** — 「고장」으로
#      읽지 마라. 🔵 [실측 2026-11-26 · 개발 DB] 그날 아침까지 신청 29줄이 전부
#      USE 였다(dss-inventory/src/lib/stock/requests.ts 의 주석).
#   🔴 **올린 뒤에는 는다** — 사람이 [반환 요청]을 누르는 순간부터다. 그것이
#      **이 기능이 도는 증거**이지 사고가 아니다.
RET_ALL_SQL="select count(*) from stock_requests where type::text = 'RETURN'"
RET_BY_STATUS_SQL="select status::text || ' | ' || count(*) from stock_requests where type::text = 'RETURN' group by status order by status"
# 🔵 **대기로 세는 상태 다섯** — 재고의 PENDING_REQUEST_STATUSES 를 글자 그대로
#    옮겼다(src/lib/stock/codes.ts). 🔴 거기 상태가 늘면 **이 줄도 함께 고쳐라** —
#    안 고치면 그 상태의 반환이 조용히 빠진다.
RET_PENDING_SQL="select count(*) from stock_requests where type::text = 'RETURN' and status::text in ('PENDING','CONFIRMING','PARTIAL','ON_HOLD','IN_APPROVAL')"
# 🔴 **없는 종류로 물어 0 이 나오는가** — enum 이라 ::text 로 바꿔 묻는다.
RET_PROBE_SQL="select count(*) from stock_requests where type::text = '__dss_probe_no_such_type__'"
#
# ── ⑮ 🔴 **반출 신청(type='USE')** — 🔴 **이 배포가 한 줄도 안 바꿔야 한다**
#   🔵 반환은 **같은 주소·같은 표**에 type 만 달리 적는다. 그래서 「반출이 줄거나
#      늘었다」는 **반출 쪽을 건드렸다는 뜻**이다 — 전후가 같아야 정상이다.
USE_ALL_SQL="select count(*) from stock_requests where type::text = 'USE'"
#
# ── ⑯ 🔴 **[반환 완료]된 반환** — 종이 뜰 줄의 수
#   🔵 재고의 COMPLETED_RETURN_STATUSES 는 **CONFIRMED 하나**다(codes.ts).
#      반려(REJECTED)·거둠(CANCELLED)은 **물건이 안 돌아온 것**이라 거기 없다.
#   🔴 **그 묶음이 늘면 이 줄도 함께 고쳐라.**
RET_DONE_SQL="select count(*) from stock_requests where type::text = 'RETURN' and status::text = 'CONFIRMED'"
#
# ── ⑰ 🔴 **돌려줄 수 있는 부품이 있는 수리 건** — [반환 요청] 창에 목록이 뜰 건
#   🔴🔴 **앱이 쓰는 조건을 그대로 흉내 냈다**(dss-inventory/src/lib/stock/queries.ts
#      의 readReturnableTransactions · 인수번호 가지). 짐작으로 세지 않았다:
#        · stock_entries.type 이 **USE 또는 LOAN**
#        · stock_transactions.delta < 0   (+ 줄은 「나간 수량」이 아니다)
#        · **기록 취소된 줄은 뺀다** — 그 줄을 reverses_transaction_id 로 가리키는
#          줄이 있으면 나간 적이 없는 것이다
#        · 이미 돌아온 수량 = 그 줄을 returns_transaction_id 로 가리키는 줄의 delta 합
#        · remaining = (−delta) − 돌아온 수량 > 0
#      🔵 intake_number 는 **NOT NULL · 기본값 빈 글자**라 빈 줄을 따로 뺀다.
#   🔴 **pending(대기 중인 반환 신청)은 안 뺐다** — 앱은 뺀다(remainingOf). 그 값은
#      신청의 **payload(jsonb) 안**에 있어 SQL 로 흉내 내면 틀릴 자리가 많다.
#      🔵 **⑭ 가 0 이면 두 수가 같다** — 올리기 전에는 정확히 같고, 올린 뒤에는
#         **이 수가 상한**이 된다. 그래서 ✗ 를 안 낸다.
#   🔵 **이 수가 곧 「창에 목록이 뜨는 건」의 상한**이다 — 0 이면 눈 확인에서
#      [반환 요청] 창이 **비어 있는 것이 정상**이다.
RETURNABLE_CASES_SQL="select count(distinct e.intake_number) from stock_transactions t join stock_entries e on e.id = t.entry_id where e.type::text in ('USE','LOAN') and t.delta < 0 and e.intake_number <> '' and not exists (select 1 from stock_transactions x where x.reverses_transaction_id = t.id) and ((-t.delta) - coalesce((select sum(r.delta) from stock_transactions r where r.returns_transaction_id = t.id), 0)) > 0"
# 🔵 **줄 수도 함께 센다** — 건이 아니라 **원장 줄**이 몇이나 남았는가. 건 수만
#    보면 「한 건에 열 줄」과 「열 건에 한 줄」이 같은 수로 보인다.
RETURNABLE_LINES_SQL="select count(*) from stock_transactions t join stock_entries e on e.id = t.entry_id where e.type::text in ('USE','LOAN') and t.delta < 0 and e.intake_number <> '' and not exists (select 1 from stock_transactions x where x.reverses_transaction_id = t.id) and ((-t.delta) - coalesce((select sum(r.delta) from stock_transactions r where r.returns_transaction_id = t.id), 0)) > 0"
# 🔴 **없는 종류로 물어 0 이 나오는가** — 「무조건 0」인 질의인지 가른다.
RETURNABLE_PROBE_SQL="select count(distinct e.intake_number) from stock_transactions t join stock_entries e on e.id = t.entry_id where e.type::text = '__dss_probe_no_such_type__' and t.delta < 0"
# 🔵 **반대쪽 잣대** — 거르개를 걷으면 수가 늘어야 한다. 늘지 않으면 WHERE 가
#    통째로 안 걸리고 있다는 뜻이다(「무조건 같은 수」인 질의를 가른다).
RETURNABLE_WIDE_SQL="select count(distinct e.intake_number) from stock_entries e where e.intake_number <> ''"
#
# ── ⑱ 🔴 **반환 원장 건** — ㅅ 갈래(기록 내역 머리글)가 바꾸는 줄
#   🔴 **늦게 들어온 커밋(18f5381) 때문에 생긴 자리다.** [기록 내역]의 반환 건
#      머리글이 **종류 이름 「반환」에서 수리 건 인수번호로** 바뀐다.
#   🔴🔴 **반환 건 자신은 인수번호를 안 들고 있다** — 그 칸(stock_entries.intake_number)이
#      **언제나 빈 글자**다(원장의 반환 갈래가 그 칸을 아예 안 쓴다). 🔴 그래서
#      **「그 칸이 찼나」로 세면 늘 0** 이고, 그 0 을 「기능이 안 돈다」로 읽게 된다.
#   🔵 **앱이 쓰는 길 그대로 되짚는다**(queries.ts 의 returnIntakeNumbersFor):
#      반환 건의 줄 → returns_transaction_id 가 가리키는 **원래 줄** → 그 줄이 달린
#      **불출 건의 intake_number**. 🔵 빈 글자는 담지 않고, **갈래가 하나일 때만**
#      머리글에 적는다(entry-title.ts 의 soleIntakeNumber) — 섞였으면 빈 글자다.
#   🔴 **✗ 를 안 낸다** — ✗ 를 내는 것은 잣대 검사뿐이다.
RET_ENTRY_SQL="select count(*) from stock_entries where type::text = 'RETURN'"
# 🔵 **그 칸이 정말 늘 비었는가** — 머리말의 그 말이 실제와 맞는지 값으로 본다.
#    🔴 0 이 아니면 **이 주석이 틀린 것**이다(⚠️ 로만 센다).
RET_ENTRY_INTAKE_SQL="select count(*) from stock_entries where type::text = 'RETURN' and intake_number <> ''"
# 🔴 **머리글에 번호가 뜨는 건** — 되짚은 인수번호가 **딱 하나**인 반환 건.
#    🔵 GROUP BY 1 을 안 쓴다(62번이 그것으로 질의 둘을 통째로 잃었다).
RET_ENTRY_TITLED_SQL="select count(*) from (select e.id from stock_entries e join stock_transactions t on t.entry_id = e.id join stock_transactions o on o.id = t.returns_transaction_id join stock_entries oe on oe.id = o.entry_id where e.type::text = 'RETURN' and oe.intake_number <> '' group by e.id having count(distinct oe.intake_number) = 1) s"
# 🔴 **없는 종류로 물어 0 이 나오는가** — enum 이라 ::text 로 바꿔 묻는다.
RET_ENTRY_PROBE_SQL="select count(*) from stock_entries where type::text = '__dss_probe_no_such_type__'"

# ── 🔵 **재고의 뒷걸음 표 둘** — 69번이 보던 자리 (🔴 한 번 빼면 안 넣는다)
KEEPTBL_INV1=portal_approval_delegations
KEEPTBL_INV2=stock_issue_approval_steps

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
  --check|--count|--preload|--tools|--go|--rollback) ;;
  *) printf '쓰는 법: %s [--check|--count|--preload|--tools|--go|--rollback]\n' "$0"
     printf '🔴 **--migrate 는 없습니다** — 71·66 번에 있던 자리입니다.\n'
     printf '   이번 판은 마이그레이션이 **0건**이라 그 자리가 **--tools** 입니다\n'
     printf '   (덤프 **둘**을 뜨고 · 도구 태그 **둘**을 갈고 · A/S 는 db:preflight 로\n'
     printf '    대기 0건을 값으로 받고 · 재고는 이미지 안의 .sql 28장을 셉니다.\n'
     printf '    🔵 **DB 는 한 글자도 안 바뀝니다**).\n'
     exit 2 ;;
esac

mkdir -p "$D/setup/logs" 2>/dev/null
LOG="$D/setup/logs/deploy69-$(printf '%s' "$MODE" | tr -d '-')-$STAMP.log"
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
printf '%s\n' " 73-deploy.sh — 예순아홉째 배포 ($MODE)"
printf '%s\n' "   때      : $(date '+%F %T')"
printf '%s\n' "   로그    : $LOG"
printf '%s\n' "   compose : $CF"
printf '%s\n' "   앱 2(A/S · 재고관리) · 도구 2 · tar 4 · 🔵 **마이그레이션 0건**"
printf '%s\n' "   (dss_as $AS_VOL_SQL_WANT 그대로 · dss_inventory 28 그대로) ·"
printf '%s\n' "   🔵 **묶음 없음** · 안 건드리는 집 8 · 안 바뀌는 DB 5"
printf '%s\n' "   🔴 **한 기능이 두 집에 걸쳐 있습니다** — 반쪽만 올리면 [반환 요청] 창이"
printf '%s\n' "      비거나 올려도 거절됩니다. --go 가 **둘을 한 번에** 띄웁니다."
printf '%s\n' "   🔵 **재고관리가 「안 건드리는 집」에서 빠졌습니다** (72번에서는 안 건드렸습니다)"
printf '%s\n' "      🔴 **포털(dss-auth)은 그대로 그 목록에 있습니다** — 1-ㄷ 이 둘을"
printf '%s\n' "         **같은 줄에서 함께** 못 박습니다(있는가 1 · 없는가 0)."
printf '%s\n' "══════════════════════════════════════════════════════════════"
# 🔴 **제 md5 를 스스로 찍는다** — DSM 터미널이 긴 명령을 잘라 먹으므로
#    개발 PC 의 Get-FileHash 와 **눈으로 맞댄다.**
printf '  이 파일의 md5: %s\n' "$(md5sum "$0" 2>/dev/null | awk '{print $1}')"
printf '%s\n' "  🔴 **위 값을 개발 PC 의 Get-FileHash -Algorithm MD5 73-deploy.sh 와 맞대세요.**"
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

# 1-ㄱ. 🔴 운영이 지금 쓰는 태그 — 앱 **둘**
say ""
say "── 1-ㄱ. 🔴 앱 **둘** — compose 의 image: 줄을 **통째로** 찍는다"
say "🔵 72번은 여기가 **한 줄**이었습니다(A/S 만). 🔴 **고리 꼴을 그대로 둔 덕에**"
say "   이번에는 **표에 줄 하나만 더하면** 됐습니다 — 72번이 적어 둔 그대로입니다."
say "🔴 끝의 관문이 「몇 집을 봤는가」를 값으로 셉니다 — 고리가 한 바퀴만 돌면"
say "   **재고관리가 아무 검사도 안 받습니다**(71번이 그 자리를 메워 두었습니다)."
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

# 1-ㄴ. 도구 **둘**
say ""
say "── 1-ㄴ. 🔴 도구 **둘** — **--tools 가 이 줄들을 간다**"
say "🔵 72번은 여기가 **한 줄**이었습니다. 마이그레이션이 **0건**이라 그 자리가"
say "   **--tools** 인 것은 그대로입니다(65·64·63·69·70 번과 같은 꼴)."
say "🔴 **A/S 도구를 가는 까닭은 src/ 20장이 바뀌어서**입니다 — 그 안에서 도는"
say "   db:preflight·check:* 가 **그 소스로** 돕니다. 안 갈면 **옛 몸통**으로 셉니다."
say "🔴 **재고 도구를 가는 까닭은 src/ 26장이 바뀌어서**입니다. 🔵 그 집에는"
say "   **db:preflight 도 check:* 도 없습니다** — 그래서 --tools 가 거기서는 명령을"
say "   **안 돌리고** 이미지 안을 값으로 셉니다(.sql ${INV_IMG_SQL_WANT}장 · 도구 표식 둘)."
say "🔴🔴 **.sql 이 어디서 도는지가 두 집에서 정반대입니다:**"
say "   · A/S  — **볼륨**이 정본(/volume1/dss/as-migrations · 이미지 안은 **0장**)"
say "   · 재고 — **이미지**가 정본(도구 이미지 안 **${INV_IMG_SQL_WANT}장**)"
say "   🔴 한 잣대로 뭉뚱그리면 **둘 중 하나가 반드시 가짜 ✗** 입니다(69번의 경고)."
say "🔵 **이번 판은 양쪽 다 더할 것이 0건**이라 묶음을 안 보냅니다"
say "   (2-ㄷ 이 A/S 볼륨 ${AS_VOL_SQL_WANT}장 · 재고 이미지 ${INV_IMG_SQL_WANT}장을 둘 다 잽니다)."
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
  MID)  say "🔴 **--tools 까지 돌았습니다**(도구만 새 판). 다음은 --go 입니다."
        say "   🔵 --go 뒤에 --rollback 으로 앱만 되돌린 상태도 여기 보입니다."
        say "   🔴 **이번 판은 DB 가 안 바뀌어 그 둘을 DB 로 가를 수 없습니다**(71번은"
        say "      dss_as 의 수로 갈렸습니다) — 가르려면 **로그 파일 이름**"
        say "      (deploy69-go-… / deploy69-rollback-…)을 보세요." ;;
  POST) say "--go 까지 돌았습니다. --count 로 뒤의 수를 재세요." ;;
  ODD)  hm "단계가 섞여 있습니다 — 위 표를 사람이 보세요. **막지는 않습니다.**"
        say "      🔴 **집이 둘이라 섞일 자리가 늡니다** — 한 집만 새 판인 꼴이 실제로"
        say "         생길 수 있습니다(--go 가 중간에 멈춘 뒤). 🔴 **그 상태로 두지"
        say "         마세요** — 반쪽만 올라간 것이라 [반환 요청] 이 빈 목록이거나"
        say "         거절됩니다. 1-ㄱ·1-ㄴ 의 표를 보고 --go 를 다시 돌리거나"
        say "         --rollback 으로 **둘을 함께** 되돌리세요." ;;
esac

# 1-ㄷ. 🔴 안 건드리는 **여덟** — 「옆으로 안 샜다」는 증거
say ""
say "── 1-ㄷ. 🔴 안 건드리는 **여덟** — 도는가 · 어느 이미지인가 · 언제 켜졌는가"
say "🔴 **도는가만 보지 않습니다** — 이미지와 켜진 때를 **적어 두고 끝에서 맞댑니다.**"
say "   2026-11-18 에 ✗ 가 바로 그 자리에서 났습니다(DB 가 Recreate 됐습니다)."
say "🔴🔴 **dss-inventory 가 이 목록에서 빠졌습니다**(72번은 아홉이었습니다) —"
say "   이번엔 **올라가는 집**입니다. 72번 것을 그대로 두었으면 끝의 맞대기가"
say "   「재고가 달라졌다」로 **가짜 ✗** 를 냈을 것입니다."
say "🔴 **dss-auth 는 그대로 남아 있습니다** — 71번은 그것을 뺐지만(거기선 올라갔다)"
say "   이번엔 **안 건드립니다.** 71번 것을 그대로 베꼈으면 포털이 목록에서 빠진 채로"
say "   돌아 **「옆으로 안 샜다」를 한 번도 안 재게** 됐을 것입니다."
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
# 🔴🔴 **두 집을 같은 줄에서 함께 못 박는다** — 「있는가」만 재면 번호가 빗나가도
#    통과한다(그 규율이 AS_VOL_LAST 에서 왔다).
#    · dss-auth      **1** 이어야 한다 — 이번엔 **안 건드리는 집**(71번은 0 이었다)
#    · dss-inventory **0** 이어야 한다 — 이번엔 **올라가는 집**(72번은 1 이었다)
#    🔴 한쪽만 재서 고치면 다른 쪽이 조용히 어긋난다. 71번은 포털만, 72번은 포털만
#       재고 있었다 — **이 판은 둘 다** 잰다.
na=$(printf '%s\n' "$KEEP_BOXES" | tr ' ' '\n' | grep -cFx 'dss-auth' || true)
ni=$(printf '%s\n' "$KEEP_BOXES" | tr ' ' '\n' | grep -cFx 'dss-inventory' || true)
printf '      안 건드리는 목록에 dss-auth 가 있나: %s개 (기대 1 — **안 건드리는 집이다**)\n' "${na:-?}"
printf '      안 건드리는 목록에 dss-inventory 가 있나: %s개 (기대 0 — **이번에 올라가는 집이다**)\n' "${ni:-?}"
if [ "${na:-x}" = "1" ] && [ "${ni:-x}" = "0" ]; then
  ok "포털은 **목록에 있고** 재고관리는 **목록에 없다** (이 배포의 전제와 맞다)"
else
  [ "${na:-x}" = "1" ] || bad "포털이 「안 건드리는 집」에 **안 들어 있다** — 🔴 그 집을 한 번도 안 재게 된다"
  [ "${ni:-x}" = "0" ] || bad "재고관리가 「안 건드리는 집」에 **들어 있다** — 🔴 끝의 맞대기가 **가짜 ✗** 를 낸다"
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
say "🔴🔴 **이번 판은 올라가는 집이 둘인데 DB 상자는 하나입니다**(둘 다 dss-pg-app) —"
say "   71번은 상자가 둘이었습니다. 🔴 그래서 go_gate 가 **상자 하나를 보고 DB 이름"
say "   둘을 따로** 묻습니다. 상자가 살아 있어도 그 안의 DB 하나가 없어지거나 권한이"
say "   닫히면 **재고 앱만** 죽는데, 상자만 보면 그것을 못 가릅니다."

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
say "── 1-ㅁ. 🔵 incoming 폴더 — **이번 판은 여기서 아무것도 안 읽습니다**"
say "🔴 **71번과 뜻이 반대입니다**(머리말 「왜 없는가」 ⑤) — 거기서는 --migrate 가"
say "   여기 있는 묶음을 풀어 볼륨을 132 → ${AS_VOL_SQL_WANT}장으로 만들었습니다."
say "🔵 **이번 판은 마이그레이션이 0건**이라 보낼 묶음이 없습니다 — 찍기만 합니다."
say "🔴 **아래에 as-migrations.tar.gz 가 보이면 옛 판의 것입니다** — 풀지 마세요."
say "   쉰여섯째·쉰일곱째가 **두 판 연속** 옛 묶음을 보내 ✗ 를 냈습니다."
mkdir -p "$INCOMING" 2>/dev/null; chmod 777 "$INCOMING" 2>/dev/null
ls -l "$INCOMING" 2>/dev/null | sed 's/^/        /'
n=$(ls -1 "$INCOMING"/as-migrations.tar.gz 2>/dev/null | wc -l | tr -d ' ')
printf '      incoming 의 as-migrations.tar.gz: %s개 (기대 0 — 이번 판은 안 보냅니다)\n' "${n:-?}"
if [ "${n:-1}" = "0" ]; then
  ok "incoming 에 묶음이 없다 (이 배포의 전제와 맞다)"
else
  hm "incoming 에 묶음이 ${n}개 있습니다 — 🔴 **옛 판의 것입니다. 안 풉니다.**"
  say "      🔵 이 파일에는 그것을 푸는 길(place_migs)이 **아예 없습니다** — 그래서"
  say "         남아 있어도 아무 일도 안 일어납니다. 🔴 다만 **다음 판이 그것을**"
  say "         **이번 것으로 착각**할 수 있으니 지워 두시길 권합니다."
fi

# 1-ㅂ. 🔴🔴 **한글이 컨테이너 경계를 글자 그대로 건너가는가**
#   🔴 **70→71→72 로 내려온 절이다**(70-deploy.sh:803-856 이 원본).
#      🔴🔴 **이번 판은 한글 표식이 여섯이다** — 72번은 둘이었다. 기능 표식 넷이
#         전부 **화면 글자**라서다. 그래서 이 절이 **더 중요해졌다**: 경계가 깨지면
#         **멀쩡한 이미지 둘이 한꺼번에 ✗** 가 난다.
#   🔵 길은 「보내고 **되돌려 받아** 글자와 **바이트 수**를 맞댄다」다.
#      🔴 8진 이스케이프로 우회하지 않았다 — 백슬래시 한 겹이 조용히 삼켜지는
#         함정이 적혀 있어 **그 길이 더 위험**하다.
#   🔵 NAS 는 리눅스라 Git Bash 의 인자 번역 함정은 없다. 🔴 그래도 **로케일**은
#      다를 수 있고 DSM 터미널이 긴 명령을 잘라 먹은 적도 있다 — 그래서 잰다.
say ""
say "── 1-ㅂ. 🔴🔴 **한글이 컨테이너 안까지 글자 그대로 가는가** (표식 여섯이 한글이다)"
say "🔴 이 줄이 ✗ 면 **이미지가 아니라 검사가 깨진 것**입니다 — 아래 한글 표식의"
say "   0 을 결함으로 읽지 마세요."
say "🔵 이 판은 **집마다 ASCII 기능 표식이 하나씩** 있습니다(return-candidates) —"
say "   한글만 0 이고 그 ASCII 가 ≥1 이면 그것 자체가 「한글 grep 이 안 되는 것」"
say "   이라는 증거입니다(ASCII 대조). 🔴 **그때는 이미지를 되돌리지 마세요.**"
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
    say "         [돌려받을 내용을 확인하십시오] 41 · [부품 반환이 완료되었습니다] 38."
    say "         받은 쪽이 그와 같으면 경계가 멀쩡합니다."
  else
    bad "본 것 ${KO_SEEN} · 그대로인 것 ${KO_OK} 다 — ${KO_MARKS_WANT} 를 기대했다"
    say "      🔴 **아래 한글 표식의 ✗ 는 전부 이 줄의 결과입니다.** 되돌리지 마세요."
  fi
fi

# ══════════════════════════════════════════════════════════════════════
# ── 2. 🔵 DB — **0건이다.** 「바뀌지 않았는가」를 잰다
# ══════════════════════════════════════════════════════════════════════
step "2. 🔵 DB — **마이그레이션 0건.** 「안 바뀌었는가」를 잰다"
say "🔴 **71번은 여기가 「2건이다」였습니다** — 거기에는 MIGS 표와 DBPHASE·VOLPHASE"
say "   라는 **단계 변수 둘**이 있었고, 「칸 넷이 있는가」의 기대값이 단계마다"
say "   뒤집혔습니다. **이 판에는 그 셋이 없습니다** — 적용 전과 뒤의 기대값이"
say "   **같기** 때문입니다(한 글자도 안 바꿉니다). 🔵 까닭은 머리말 「왜 없는가」 ①③."
say "🔴 **A/S 가 134 입니다** — 예순일곱째가 0132·0133 을 올려 132 → 134 가 됐습니다."
say "   🔴 **132 로 두면 멀쩡한 운영에서 ✗** 가 나고, 그 ✗ 는 진짜 사고처럼 보입니다."
say "🔴 **재고가 28 입니다** — 예순다섯째 때도 28 이었고 이번에도 안 움직입니다."
say "   🔴 **올라가는 집인데도 「안 바뀌는 집」 표에 있습니다** — 집이 올라가는 것과"
say "      DB 가 바뀌는 것은 다른 말입니다(이번 범위의 drizzle/ 변경 **0줄**)."
say "🔴 **빼지 않는 까닭**: 빼면 「운영 DB 가 지금 몇 건인지」를 아무도 안 보게 되고,"
say "   그 수가 어긋나면 **이 배포와 무관한 다른 사고**인데 끝까지 모릅니다."

# 2-ㄱ. 다섯 집의 마이그레이션 수 — **바뀌면 안 된다**
say ""
say "── 2-ㄱ. 🔴 마이그레이션 수 — **다섯 집이 전과 같아야 한다**"
say "🔴 **올라가는 두 집이 둘 다 이 표에 있습니다.** 「올라가는 집이니"
say "   여기서 빼야지」가 **틀립니다** — 집이 올라가는 것과 DB 가 바뀌는 것은"
say "   **다른 말**이고, 이번 범위는 .sql 을 한 장도 안 늘렸습니다."
MIGK_SEEN=0; MIGK_OK=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  BOX=$(field "$r" 2); DB=$(field "$r" 3); WANT=$(field "$r" 4); NAME=$(field "$r" 5)
  MIGK_SEEN=$((MIGK_SEEN+1))
  v=$(mig_count "$BOX" "$DB")
  printf '      %-14s %-14s %-16s 지금 %-5s (기대 %s — **이번 판은 0건**)\n' "$NAME" "$BOX" "$DB" "${v:-못 읽음}" "$WANT"
  if [ -z "${v:-}" ]; then
    unk "$NAME 마이그레이션 수" "$BOX 가 도는지, 그 DB 가 있는지 보세요"
  elif [ "$v" = "$WANT" ]; then MIGK_OK=$((MIGK_OK+1)); ok "$NAME 가 $WANT 그대로다"
  else
    bad "$NAME 가 ${v} 다 — $WANT 를 기대했다. 🔴 **이 배포와 무관한 다른 사고다**"
    say "      🔴 이 배포본은 마이그레이션을 **한 건도 올리지 않습니다.** 수가 달라졌다면"
    say "         누가 다른 길로 올렸다는 뜻입니다. **멈추고 사람이 보세요.**"
    doubt
  fi
done <<ENDMIGK
$(rows_of "$MIGS_KEEP")
ENDMIGK
say "본 집 ${MIGK_SEEN} · 같은 집 ${MIGK_OK} (기대 $MIGS_KEEP_WANT · $MIGS_KEEP_WANT)"
if [ "$MIGK_SEEN" = "$MIGS_KEEP_WANT" ] && [ "$MIGK_OK" = "$MIGS_KEEP_WANT" ]; then
  ok "다섯 집의 마이그레이션 수가 **전부 그대로다** (표본이 비지 않았다)"
  DBKEEP=KEEP
else
  bad "본 집 ${MIGK_SEEN} · 같은 집 ${MIGK_OK} 다 — ${MIGS_KEEP_WANT} 을 기대했다"
  DBKEEP=ODD
fi
printf '\n  🔴 **DB 상태: %s** (KEEP = 다섯 집이 다 전과 같다)\n' "$DBKEEP"
say "🔴 **승인함은 여기에 없습니다** — DB 가 아예 없는 집이라 select 를 한 줄도 안"
say "   던집니다. 던졌으면 전부 ✗ 가 났을 것입니다."

# 2-ㄱ-2. 🔴 **예순일곱째가 만든 칸 넷이 아직 있는가** — 뒷걸음 방지
say ""
say "── 2-ㄱ-2. 🔴 **예순일곱째가 만든 칸 넷이 아직 있는가** (뒷걸음 방지)"
say "🔴 **71번과 뜻이 뒤집힌 절입니다**(머리말 ③) — 거기서는 「이번 판이 만드는 칸」"
say "   이라 적용 전에는 **없어야** ✓ 였습니다. 🔴 **이 판에서는 늘 있어야** ✓ 입니다."
say "🔴 **절을 지우지 않았습니다** — 지우면 DB 가 되감긴 날 아무도 못 잡습니다."
say "🔴 **「있는가」만 보지 않습니다** — 자료형과 NULL 허용까지 봅니다. 같은 이름으로"
say "   다른 꼴을 만든 것은 「있는가」로 안 갈립니다."
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
    #    기대값도 같은 꼴로 맞댄다. 그래서 'timestamp with time zone' 이
    #    'timestampwithtimezone' 과 맞는다.
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
# 🔴 **잣대가 살아 있는가** — 없는 칸을 물어 0 이 나오는지 본다. 이것이 없으면
#    has_column 이 늘 1 을 돌려주는 꼴을 못 가른다(「무조건 있다」인 검사).
NCP=$(has_column dss-pg-app dss_as domestic_order_due_dates "__dss_probe_no_such_column__")
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

# 2-ㄷ. 🔴 A/S 마이그레이션 볼륨 — **134장 그대로여야 한다**
say ""
say "── 2-ㄷ. 🔴 A/S 마이그레이션 **볼륨** — ${AS_VOL_SQL_WANT}장 그대로인가"
say "🔴 A/S 만 볼륨에서 돕니다(/volume1/dss/as-migrations). 🔵 **이번 판은 거기 더할"
say "   것이 0건**이라 묶음을 안 보냅니다 — 그래도 **줄었는지**는 봅니다."
say "🔴 **이미지 안만 세면 적용이 0건으로 조용히 끝납니다**(31·39번이 겪었습니다)."
say "🔴🔴 **「없는가」만 재면 번호가 빗나가도 통과합니다** — 그래서 **${AS_VOL_LAST} 이"
say "   아직 있는가**도 함께 셉니다. 70번이 AS_VOL_NEXT 가 한 칸 빗나가 **두 판 연속"
say "   아무것도 안 막은** 것을 잡아낸 뒤로 생긴 규율입니다."
VOL_SEEN=0
if [ -d "$MIGDIR" ]; then
  VOL_SEEN=$((VOL_SEEN+1))
  vs=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  vj=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  vnx=$(ls -1 "$MIGDIR/${AS_VOL_NEXT}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  vlt=$(ls -1 "$MIGDIR/${AS_VOL_LAST}"_*.sql 2>/dev/null | wc -l | tr -d ' ')
  printf '      볼륨 %s — .sql %s장 · journal idx %s개 · %s %s개(기대 0) · %s %s개(기대 1)\n' \
    "$MIGDIR" "${vs:-?}" "${vj:-?}" "$AS_VOL_NEXT" "${vnx:-?}" "$AS_VOL_LAST" "${vlt:-?}"
  if [ "${vs:-x}" = "$AS_VOL_SQL_WANT" ] && [ "${vj:-x}" = "$AS_VOL_SQL_WANT" ]; then
    ok "볼륨이 **${AS_VOL_SQL_WANT}장**이고 목록도 ${AS_VOL_SQL_WANT}개다 (예순일곱째가 올린 수 그대로)"
  else
    bad "볼륨이 .sql ${vs:-?} · idx ${vj:-?} 다 — ${AS_VOL_SQL_WANT} 을 기대했다"
    say "      🔴 **.sql 과 idx 가 다르면** 목록에 없는 파일이 있다는 뜻이고,"
    say "         drizzle 이 그것을 **아예 모릅니다**(적용이 0건으로 조용히 끝납니다)."
    say "      🔴 **132 가 나오면 누가 옛 묶음을 푼 것**입니다 — 1-ㅁ 을 보세요."
    doubt
  fi
  if [ "${vnx:-1}" = "0" ] && [ "${vlt:-0}" = "1" ]; then
    ok "볼륨에 $AS_VOL_NEXT 이 없고 $AS_VOL_LAST 이 있다 (마지막이 $AS_VOL_LAST 그대로)"
  elif [ "${vnx:-1}" != "0" ]; then
    bad "볼륨에 $AS_VOL_NEXT 이 **있다** — 이 배포본은 $AS_VOL_LAST 까지를 전제로 쓰였다. 멈추고 알릴 것"
  else
    bad "볼륨에 $AS_VOL_LAST 이 ${vlt:-?}개다 — 1 을 기대했다. 🔴 **번호 잣대가 빗나가 있다**"
    doubt
  fi
  # 🔴 도구 이미지 안은 **비어 있어야** 한다 — 볼륨이 붙는 자리다.
  AST=$(svc_image tools-as)
  if [ -n "${AST:-}" ] && "$DOCKER" image inspect "$AST" >/dev/null 2>&1; then
    n=$(dock "$AST" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
    printf '      A/S 도구 이미지(%s) 안 %s 의 .sql: %s개 (기대 0 — 볼륨이 안 붙은 맨 이미지다)\n' "$AST" "$IMG_MIGDIR" "${n:-?}"
    if isnum "${n:-}" && [ "${n:-1}" = "0" ]; then ok "도구 이미지 안 drizzle/ 이 비어 있다 (볼륨이 정본이다)"
    else bad "도구 이미지 안에 .sql 이 ${n:-?}장 있다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다"; fi
  else
    unk "A/S 도구 이미지 안" "${AST:-태그를 못 읽음} 가 NAS 에 아직 없다 (--preload 전이면 정상)"
  fi
else
  bad "A/S 마이그레이션 볼륨이 없다 — $MIGDIR"
fi
[ "$VOL_SEEN" = "1" ] && ok "볼륨을 봤다" || bad "볼륨을 못 봤다"

# 2-ㄷ-2. 🔴🔴 **재고 마이그레이션은 이미지 안에서 돈다** — A/S 와 정반대
#   🔴 69-deploy.sh:762-790 에서 가져왔다. **A/S 판을 베껴 「0장이어야 한다」로 재면
#      멀쩡한 재고 도구가 ✗** 가 된다.
#   🔵 **--preload 전에도 뒤에도 기대값이 같다** — 옛 판(:5)도 ${INV_IMG_SQL_WANT}장이다.
say ""
say "── 2-ㄷ-2. 🔴🔴 **재고 마이그레이션은 이미지 안**에 있다 (A/S 와 **정반대**)"
say "🔴 **재고는 볼륨이 없습니다** — .sql 이 도구 이미지에 **구워져** 갑니다."
say "   그래서 여기 기대값이 **${INV_IMG_SQL_WANT}장**입니다(A/S 는 **0장**)."
say "🔵 **이번 판은 거기에 한 장도 안 더합니다** — ${INV_IMG_NEXT} 이 생기면 전제가 깨진 것입니다."
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
    ok "재고 도구 이미지 안이 **${INV_IMG_SQL_WANT}장**이고 목록도 ${INV_IMG_SQL_WANT}개다"
  else
    bad "재고 도구 이미지 안이 .sql ${n:-?} · idx ${j:-?} 다 — ${INV_IMG_SQL_WANT} 을 기대했다"
    say "      🔴 **A/S 판을 베껴 0 을 기대하지 마세요** — 재고는 **이미지가 정본**입니다."
    say "      🔴 **.sql 과 idx 가 다르면** 목록에 없는 파일이 있다는 뜻이고 drizzle 이"
    say "         그것을 **아예 모릅니다**(적용이 0건으로 조용히 끝납니다)."
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
  unk "재고 도구 이미지 안" "${IVT:-태그를 못 읽음} 가 NAS 에 아직 없다 (--preload 전이면 정상)"
fi


# ══════════════════════════════════════════════════════════════════════
# ── 3. 들여올 tar **넷** (🔵 묶음은 없다) ────────────────────────────
# ══════════════════════════════════════════════════════════════════════
step "3. 들여올 tar 넷 — **옮기다 깨졌는가** (🔵 묶음은 없다)"
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
  say "   73-build.sh --go 가 꼬리말에 찍어 주는 **네 줄**을 이 파일의 TARS 에 그대로"
  say "   붙여 넣은 **뒤에** scp 하세요. 쉰세째에는 빈 표가 그대로 올라가 --preload 가"
  say "   ✗ 둘로 멈췄습니다."
fi

# 3-ㄴ. 🔵 **묶음을 읽는 절이 없다** — 이번 판은 묶음이 없다
say ""
say "── 3-ㄴ. 🔵 **묶음(as-migrations.tar.gz)을 읽는 절이 없습니다**"
say "🔴 71번에는 여기에 그 절이 있었고 묶음의 지문·안·생김새를 다 쟀습니다."
say "   까닭은 머리말의 「왜 없는가」 ② — **이번 판은 마이그레이션이 0건**입니다."
say "🔴 **묶음이 생기는 판에서는 71-deploy.sh 에서 셋을 한 벌로 되살리세요** —"
say "   이 절 · place_migs() · MIGTAR_SIZE·MIGTAR_MD5 변수 둘."
say "   🔴 하나만 되살리면 **묶음을 받고도 안을 한 번도 안 세거나**, 풀지 않은 채"
say "      db:migrate 를 돌려 **0건으로 조용히** 끝납니다."
say "🔵 그래서 이 파일에는 **tar 를 읽는 자리가 한 군데도 없습니다** —"
say "   「tar | grep -q 가 SIGPIPE 로 거짓이 된다」는 함정이 이번에는 걸릴 자리가 없습니다."

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
say "🔴 **이번 판도 PO 가 모르는 것을 하나 늘립니다 — 여섯이 됩니다**(머리말)."
say "   🔴 **PO 에서 PO발행일을 적으면 작업 상태가 안 옮겨집니다**(2026-11-26 결정)."
say "   🔵 **그것이 결정이지 결함이 아닙니다** — A/S 통로 셋에만 걸었습니다."
say "      🔴 다만 **PO 를 다시 여는 날 「왜 한쪽만 옮겨지나」를 묻는 사람이 생깁니다.**"
say "   🔵 **칸은 하나도 안 늘었습니다** — 이번 판은 DB 를 한 글자도 안 바꿉니다."
say "   🔴 **PO 를 다시 여는 날 여섯을 한 묶음으로 이식하세요.**"
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
#      그래서 이 모드의 뜻은 **「전과 후가 같은가」**다. 🔴 71번과 달리 **「칸이 생겨
#      수가 나타나는」 자리도 없다** — 처음부터 끝까지 같은 수가 나와야 한다.
#   🔵 **⓪~⑦ 은 70→71 을 거쳐 온 것 그대로다. 하나도 안 뺐다.**
#      🔴 ⓪·⓪-2·⑥·⑦ 은 **지난 판들이 올린 것을 보는 자리**다 — 「이번 범위 밖이니
#      지운다」고 착각하기 쉬운데, 지난 판들이 **「한 번 빼면 다시 넣는 사람이
#      없다」**고 반복해 적어 두었다.
#   🔵 **71번 고유였던 ⑧·⑨·⑩ 도 남겼다** — 이제 그 셋도 **지난 판이 올린 것을
#      보는 자리**다(확정 두 칸 · 기타건 납기 임박 · 노드 파일 자리).
#   🔵 **72번 고유였던 ⑪·⑫·⑬ 도 남겼다** — 이제 그 셋도 **어제 올린 것이 아직
#      도는가**를 보는 자리다(확정+완료 회차 · [수리 대기] 단계 · 납품 요청일 빌리기).
#      🔴 「이번 범위 밖이니 지운다」고 착각하기 쉬운 자리가 **이제 여덟**이다.
#   🔴 **73번 고유 여섯(⑭~⑲)을 그 뒤에 넣었다** — 전부 **재고 쪽**이다.
#      ⑲ 는 71번의 ⑪(포털이 답하는가)이 있던 자리를 **재고로** 되살린 것이다.
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
  say "   그래서 **전과 후의 수가 전부 같아야 정상**입니다."
  say "   🔴 **딱 둘만 올린 뒤에 늘 수 있습니다** — ⑭(반환 신청)과 ⑯(반환 완료)."
  say "      사람이 [반환 요청]을 누르는 순간부터이고, **그것이 이 기능이 도는 증거**입니다."
  say "🔵 아래 괄호의 「참고」는 **2026-11-19 예순한째 배포 뒤 운영 실측**입니다 —"
  say "   🔴 **✗ 를 내는 기대값이 아닙니다.** ✗ 를 내는 것은 **②-ㄴ 의 관문 둘**과"
  say "   **잣대 검사들**(없는 값으로 물어 0 이 나오는가)뿐입니다."

  local t live done_ undone noorder issued issued_any both cust nocust
  local nc tagged distinct flows prow rowdone n qlive qprobe
  local ca cb half misc near silenced nrow ncol npt
  # 🔵 72번 고유 셋(⑪·⑫·⑬)이 쓰는 것
  local cdone adone wrc wrs wrv bo bp
  # 🔵 73번 고유 여섯(⑭~⑲)이 쓰는 것
  local rall rpend rdone uall rcase rline rwide ic ren reti rett

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
  # ── 🔴🔴 여기부터 **73번 고유** — 반환이 운영에서 돌 자리 (⑭~⑲)
  # ══════════════════════════════════════════════════════════════════
  say ""
  say "══ 🔴🔴 **여기부터 73번 고유입니다 — 전부 재고관리(dss_inventory) 쪽입니다**"
  say "🔴 **A/S 쪽 DB 는 이 기능으로 칸도 줄도 안 늘립니다** — A/S 는 통로로 보내기만"
  say "   하고, 신청과 원장은 **재고에 쌓입니다.** 그래서 셀 자리가 저쪽입니다."
  say "🔴 **⑭~⑱ 은 ✗ 를 한 번도 안 냅니다** — ✗ 를 내는 것은 **잣대 검사**뿐입니다."
  say "🔴 **참고값이 하나도 없습니다 — 이 판이 처음 세는 수입니다.** 지어내지 않았습니다."
  say "   🔵 **올리기 전에 잰 수를 적어 두세요** — 다음 판이 쓸 참고값이 됩니다."

  # ── ⑭ 🔴 **반환 신청(type='RETURN')** — 🔵 운영에는 **0건**일 것이다
  say ""
  say "── ⑭ 🔴 **반환 신청(type='RETURN')** — 상태별로 (🔵 **운영에는 0건일 것입니다**)"
  say "🔴🔴 **0 이 정상입니다 — 이 기능이 지금 생깁니다.** 그러면 눈 확인에서 재고의"
  say "   신청 목록에 **반환이 한 줄도 안 보이는 것이 맞습니다.** 「고장」으로 읽지 마세요."
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

  # ── ⑲ 🔴 **재고관리가 답하는가** — 집이 둘이라 ⑤ 만으로는 반쪽이다
  say ""
  say "── ⑲ 🔴 **재고관리가 답하는가** — 🔴 **집이 둘이라 ⑤ 만으로는 반쪽입니다**"
  say "🔵 72번은 집이 하나라 ⑤ 하나로 끝났습니다. 그대로 베꼈으면 **재고를 올리고도**"
  say "   **한 번도 안 두드리는** 꼴이 됐을 것입니다(71번이 포털에서 메워 둔 자리입니다)."
  rr=$(row_by_key "$SITES" inventory); pt=$(field "$rr" 7)
  c=$(http_code "$pt")
  printf '      재고관리 127.0.0.1:%s → %s\n' "$pt" "${c:-못 읽음}"
  if http_ok "${c:-}"; then ok "재고관리가 답한다 ($c — 3xx 는 로그인으로 보내는 것이다)"
  else bad "재고관리가 $c 를 돌려준다 — 200 이나 3xx 를 기대했다"; fi
  say "🔴 **재고가 죽으면 A/S 의 [반환 요청] 창이 빈 목록이 되고 올려도 거절됩니다** —"
  say "   이 줄이 ✗ 면 **바로 --rollback 을 생각하세요**(둘을 함께 되돌립니다)."
}

if [ "$MODE" = "--count" ]; then
  effect_counts
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s\n' "$PASS" "$FAIL" "$UNK"
  printf '%s\n' "🔵 --count 는 **아무것도 안 바꿉니다.** 올리기 전과 뒤에 한 번씩 돌려 맞대세요."
  printf '%s\n' "   🔴 **⓪~⑬ 과 ⑮·⑰ 은 전부 같은 수가 나오는 것이 정상**입니다 — 이 배포는"
  printf '%s\n' "      자료를 한 글자도 안 바꾸고 **칸도 하나도 안 더합니다.**"
  printf '%s\n' "      🔵 71번과 다릅니다 — 거기서는 ⑧·⑩ 이 「칸이 없다」에서 수로 바뀌었습니다."
  printf '%s\n' "   🔴 **⑭·⑯·⑱ 만 올린 뒤에 늘 수 있습니다** — 사람이 [반환 요청]을 누르는"
  printf '%s\n' "      순간부터입니다. **그것이 이 기능이 도는 증거**이지 사고가 아닙니다."
  printf '%s\n' "      🔵 그때는 ⑰ 이 **줄어듭니다**(돌려준 만큼 남은 수량이 빠집니다)."
  printf '%s\n' "   🔴 **⑭·⑰·⑱ 의 수를 먼저 적어 두세요** — 0 이면 눈 확인에서"
  printf '%s\n' "      **아무것도 안 보이는 것이 정상**이고, 그것을 모르면 「고장」으로 읽습니다:"
  printf '%s\n' "        ⑭ 반환 신청 0   → 재고의 신청 목록에 반환이 한 줄도 없다 (**지금은 이것이 맞다**)"
  printf '%s\n' "        ⑰ 돌려줄 건 0   → A/S 의 [반환 요청] 창이 **빈 목록**이다"
  printf '%s\n' "        ⑯ 반환 완료 0   → 종에 「부품 반환이 완료되었습니다」가 안 뜬다"
  printf '%s\n' "        ⑱ 반환 원장 0   → [기록 내역]에서 머리글이 달라지는 줄이 **한 줄도 없다**"
  printf '%s\n' "   🔴 **⑮(반출 신청)가 달라졌으면 사람이 보세요** — 반환과 **같은 표**라서"
  printf '%s\n' "      거기까지 움직였다면 반출 쪽을 건드린 것입니다."
  printf '%s\n' "   🔵 ⓪·⓪-2·⑥·⑦·⑧·⑨·⑩·⑪·⑫·⑬ 과 ⑰-2 는 **지난 판들이 올린 것을 보는"
  printf '%s\n' "      자리**입니다 — 이 배포는 그 열하나를 한 자리도 안 바꿉니다."
  [ "$FAIL" = "0" ] && [ "$UNK" = "0" ] && exit 0
  exit 1
fi

if [ "$MODE" = "--check" ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s   ✗ %s   ? %s   · 단계 %s · 안 바뀌는 다섯 %s\n' \
    "$PASS" "$FAIL" "$UNK" "$PHASE" "$DBKEEP"
  printf '\n%s\n' "🔵 --check 는 **아무것도 안 바꿨습니다.**"
  printf '%s\n' "   다음: tar **넷**을 보낸 뒤 --preload → --check → --tools → --go"
  printf '%s\n' "   🔴 **--migrate 는 없습니다** — 이번 판은 마이그레이션이 **0건**이라 그"
  printf '%s\n' "      자리가 **--tools** 입니다: 덤프 **둘**을 뜨고 · **도구 태그 둘**을 갈고 ·"
  printf '%s\n' "      A/S 는 db:preflight 로 **대기 0건**을 값으로 받고 · 재고는 이미지 안의"
  printf '%s\n' "      .sql ${INV_IMG_SQL_WANT}장을 셉니다(그 집에는 preflight 명령이 없습니다)."
  printf '%s\n' "      🔵 **DB 는 한 글자도 안 바뀝니다**(dss_as $AS_VOL_SQL_WANT · dss_inventory 28 그대로)."
  printf '%s\n' "   🔵 **보낼 묶음도 없습니다** — setup/incoming 에는 아무것도 안 갑니다."
  printf '%s\n' "   🔴 **반쪽만 올리지 마세요** — --go 가 앱 **둘**을 한 번에 띄웁니다."
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
  #    통과할 수 있다. 🔴 **이번 판은 집이 둘이라 그 결함이 실제로 티가 난다** —
  #    한 바퀴만 돌면 **재고 이미지가 아무 검사도 안 받는다.**
  PRE_APP_SEEN=0; PRE_TOOL_SEEN=0
  # ── 앱 둘
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
    #    🔵 A/S 는 기능 3 + 뒷걸음 11 + 곁들이 1 · 재고는 기능 3 + 뒷걸음 3 + 곁들이 1.
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
    if [ "$K" = "as" ]; then MKWANT=$AS_MARKS_WANT; else MKWANT=$INV_MARKS_WANT; fi
    printf '        이 집에서 **판정에 쓴 표식** %s개 (기대 %s)\n' "$MKRAN" "$MKWANT"
    if [ "$MKRAN" = "$MKWANT" ]; then
      ok "$NAME 번들 표식 ${MKWANT}개를 다 돌았다 (표본이 비지 않았다)"
      say "      🔴 **이 집의 ✓ 가 다른 집의 ✓ 를 말해 주지 않습니다** — 한 기능이 두"
      say "         집에 걸쳐 있어서, 반쪽만 담기면 눌렀을 때 실패합니다."
    else
      bad "$NAME 번들 표식을 ${MKRAN}개만 돌았다 — ${MKWANT}개를 기대했다. APPMARKS 표가 깨졌다"
    fi
  done <<ENDPRE1
$(rows_of "$SITES")
ENDPRE1
  # ── 도구 둘
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
        say "      🔵 그 열 중 **끝의 둘이 글롭 잣대**입니다 — 괄호·대괄호가 든 경로라"
        say "         **목록을 넘기는 길이 살아 있는지** 재는 자리입니다. 길이 끊기면"
        say "         **그 둘이 먼저 no 로** 떨어져 「옛 소스」와 갈립니다."
        # 🔴 A/S 도구는 drizzle 을 **안 담아야** 한다 — 볼륨이 정본이다.
        n=$(dock "$NEW" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
        printf '        %s 안 .sql: %s장 (기대 0 — 볼륨이 정본이다)\n' "$IMG_MIGDIR" "${n:-?}"
        if isnum "${n:-}" && [ "${n:-1}" = "0" ]; then
          ok "$NAME 은 drizzle/ 이 **비어 있다**"
          say "      🔵 **이번 판은 그 볼륨에 더할 것이 0건**이라 묶음을 안 보냅니다 —"
          say "         운영의 볼륨은 ${AS_VOL_SQL_WANT}장 그대로입니다(2-ㄷ)."
        else bad "$NAME 안에 .sql 이 ${n:-?}장 있다 — 볼륨과 이미지 중 어느 것이 도는지 못 가른다"; fi
        # 🔴 **공용 스키마** — 핀이 맞아도 **빈 서브모듈이 담길 수 있다**.
        #    🔵 이 판에서는 **일곱이 전부 뒷걸음**이다(이번 판은 공용 스키마에 한
        #       글자도 안 더했다). 🔴 **하나라도 빼지 마라.**
        v=$("$DOCKER" run --rm --entrypoint sh "$NEW" -c 'for pair in "portal_approval_delegations /app/vendor/dss-core/src/schema/portal-approval-delegations.ts" "portal-approval-delegations /app/vendor/dss-core/src/schema/index.ts" "fault_tags /app/vendor/dss-core/src/schema/repair-case-flowcharts.ts" "confirmed_at /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "confirmed_by /app/vendor/dss-core/src/schema/domestic-order-due-dates.ts" "share_doc_relative_path /app/vendor/dss-core/src/schema/procedure-template-nodes.ts" "share_doc_relative_path /app/vendor/dss-core/src/schema/repair-case-flowchart-nodes.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' </dev/null 2>/dev/null | tr -d '\r')
        printf '%s\n' "$v" | sed 's/^/          /'
        g=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
        if [ "${g:-0}" = "7" ]; then
          ok "$NAME 에 **공용 스키마가 일곱 다 담겼다** (🔵 이 판에서는 일곱이 전부 **뒷걸음**이다)"
          say "      🔵 index.ts 가 안 내보내면 도구가 그 표를 **못 찾습니다** — 2026-09-21 에"
          say "         운영에서 도구가 전부 죽은 그 자리입니다."
        else
          bad "$NAME 의 공용 스키마가 일곱 중 ${g:-0}개다 — **빈 서브모듈이나 옛 판이 담겼다**"
          say "      🔴 **뒤의 넷(confirmed_* · share_doc_*)만 no 면 서브모듈이 예순여섯째"
          say "         핀으로 되감긴 것**입니다 — 어제 올린 기능이 통째로 사라집니다."
        fi
        # 🔵 양식이 이미지에 안 들어갔는가 — 들어갔으면 도장과 계좌번호가 구워진 것이다.
        n=$(dock "$NEW" -c "ls /templates 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
        printf '        /templates 안 파일: %s개 (기대 0 — 양식은 볼륨으로 붙는다)\n' "${n:-?}"
        if isnum "${n:-}" && [ "${n:-1}" = "0" ]; then ok "양식이 이미지에 안 들어갔다"
        else bad "이미지 안에 /templates 가 ${n:-?}개 있다 — 도장·계좌번호가 구워졌다"; fi
        ;;
      inventorytools)
        ask_files "$NEW" "$INV_KEY_FILES" "$INV_KEY_FILES_WANT" "재고의 핵심 파일"
        say "      🔵 끝의 한 장이 **괄호가 든 경로**입니다 — 글롭 잣대입니다."
        say "      🔵 그 앞 한 장(entry-title.ts)은 **늦게 들어온 커밋(18f5381)의 새 파일**"
        say "         입니다 — 그 한 장이 빠지면 [기록 내역] 화면이 import 에서 죽습니다."
        say "      🔴 **tests/ 와 API.md 는 목록에 없습니다** — .dockerignore 가 둘 다"
        say "         막아서 **이미지 안에 없는 것이 정상**입니다(아래에서 값으로 셉니다)."
        # 🔴🔴 **재고는 drizzle 을 담아야 한다** — A/S 와 **정반대**다.
        n=$(dock "$NEW" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
        j=$(dock "$NEW" -c "grep -c 'idx' $IMG_MIGDIR/meta/_journal.json 2>/dev/null"); j=$(printf '%s' "$j" | tr -d ' ')
        printf '        %s 안 .sql: %s장 · idx %s개 (기대 %s · %s — 🔴 **이미지가 정본이다**)\n' \
          "$IMG_MIGDIR" "${n:-?}" "${j:-?}" "$INV_IMG_SQL_WANT" "$INV_IMG_SQL_WANT"
        if [ "${n:-x}" = "$INV_IMG_SQL_WANT" ] && [ "${j:-x}" = "$INV_IMG_SQL_WANT" ]; then
          ok "$NAME 에 마이그레이션 ${INV_IMG_SQL_WANT}장과 목록이 다 담겼다"
          say "      🔵 **이번 판은 거기에 한 장도 안 더합니다** — 수가 같아야 정상입니다."
        else
          bad "$NAME 안이 .sql ${n:-?} · idx ${j:-?} 다 — ${INV_IMG_SQL_WANT} 을 기대했다"
          say "      🔴 **A/S 판을 베껴 0 을 기대하지 마세요** — A/S 는 볼륨이 정본이고"
          say "         재고는 **이미지가 정본**입니다. 줄었으면 운영이 올릴 .sql 을 잃습니다."
          doubt
        fi
        # 🔴 **「없는가」만 재지 않는다** — 마지막 번호가 아직 있는지 함께 센다.
        lt=$(dock "$NEW" -c "ls $IMG_MIGDIR/${INV_IMG_LAST}_*.sql 2>/dev/null | wc -l"); lt=$(printf '%s' "$lt" | tr -d ' ')
        nx=$(dock "$NEW" -c "ls $IMG_MIGDIR/${INV_IMG_NEXT}_*.sql 2>/dev/null | wc -l"); nx=$(printf '%s' "$nx" | tr -d ' ')
        printf '        %s: %s개(기대 1) · %s: %s개(기대 0)\n' "$INV_IMG_LAST" "${lt:-?}" "$INV_IMG_NEXT" "${nx:-?}"
        if [ "${lt:-0}" = "1" ] && [ "${nx:-1}" = "0" ]; then
          ok "$NAME 안 마지막이 $INV_IMG_LAST 이고 $INV_IMG_NEXT 은 없다"
        elif [ "${nx:-1}" != "0" ]; then
          bad "$NAME 안에 $INV_IMG_NEXT 이 **있다** — 이 배포본은 $INV_IMG_LAST 까지를 전제로 쓰였다"
        else
          bad "$NAME 안에 $INV_IMG_LAST 이 ${lt:-?}개다 — 1 을 기대했다. 🔴 **번호 잣대가 빗나가 있다**"
          doubt
        fi
        # 🔴 **tests/ 는 이미지에 없어야 한다** — .dockerignore 가 막는다.
        #    🔵 ✗ 가 아니라 ⚠️ 다: 담겨도 해롭지 않고 Dockerfile·무시 목록이 바뀐 신호다.
        v=$(dock "$NEW" -c 'if [ -d /app/tests ]; then printf "yes %s\n" "$(ls -1 /app/tests 2>/dev/null | wc -l)"; else printf "no 0\n"; fi')
        tsd=$(printf '%s' "$v" | awk '{print $1}'); tsn=$(printf '%s' "$v" | awk '{print $2}')
        printf '        /app/tests: %s (파일 %s개 · 기대 no — .dockerignore 가 막는다)\n' "${tsd:-못 읽음}" "${tsn:-?}"
        if [ "${tsd:-}" = "no" ]; then ok "$NAME 에 tests/ 가 **안 담겼다** (바뀐 시험 ${INV_TESTS_NOTE}장이 이미지 밖인 까닭)"
        else hm "$NAME 에 tests/ 가 담겼습니다(${tsn:-?}개) — .dockerignore 가 바뀐 것 같습니다. 사람이 보세요"; fi
        # 🔵 **재고 tools 는 vendor 를 안 담는다** — 🔴 A/S 와 **정반대**다.
        #    🔵 ✗ 가 아니라 ⚠️ 다(69번의 판단 그대로) — 담겨도 해롭지 않다.
        v=$(dock "$NEW" -c "test -d /app/vendor && echo yes || echo no")
        printf '        /app/vendor: %s (기대 no — 🔴 재고 tools 는 vendor 를 **안 담는다**)\n' "${v:-못 읽음}"
        if [ "${v:-}" = "no" ]; then ok "재고 도구에 vendor 가 없다 (Dockerfile 과 같다)"
        else hm "재고 도구에 vendor 가 있습니다 — Dockerfile 이 바뀐 것 같습니다. 사람이 보세요"; fi
        # 🔴 **/templates 를 보는 절이 없다** — 그 볼륨은 **A/S 양식**이고 재고와
        #    아무 상관이 없다. A/S 판에서 그대로 베끼면 **뜻 없는 ✓** 가 된다(69번).
        say "      🔵 **/templates 는 안 봅니다** — 그 볼륨은 A/S 양식이고 재고와 상관이"
        say "         없습니다. 베껴 두면 아무것도 안 재는 ✓ 가 됩니다."
        ;;
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
# ── 5. --preload : tar 넷을 들여놓는다 ──────────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--preload" ]; then
  step "5. --preload — tar 넷을 싣는다 (🔴 **아직 안 갈아 끼운다**)"
  say "🔵 쓰는 것: NAS 의 도커 이미지 저장소뿐입니다. compose 도 DB 도 안 건드립니다."
  say "🔵 **풀 묶음이 없습니다** — 이번 판은 마이그레이션이 0건입니다."
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
  printf '\n%s\n' "✅ 넷을 다 실었고 안도 온전합니다. **아직 아무것도 안 갈아 끼웠습니다.**"
  printf '%s\n' "   다음: --check 로 다시 재고 → --tools (🔵 **DB 는 안 바뀝니다**)"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════
# ══ 덤프 · compose 사본 ═══════════════════════════════════════════════
# ══════════════════════════════════════════════════════════════════════
#   🔴 **둘이 뜬다**(72번은 dss_as 하나였다 — 62번은 넷이었다). **올라가는 집마다
#      하나씩**이다: dss_as · dss_inventory. 둘 다 **dss-pg-app 안**에 있다.
#   🔵 **이 배포는 DB 를 한 글자도 안 바꾼다.** 그래도 뜨는 까닭은 **새 앱이 쓰는
#      쪽에서 무엇을 할지는 이 배포본이 모르기** 때문이다. 오래 걸리지 않는다.
#      🔴🔴 특히 **재고의 원장에 반환 줄이 실제로 쌓이기 시작한다** — stock_requests
#         에 새 줄이 서고 [반환 완료]를 누르면 stock_transactions 에도 선다.
#         자료를 바꾸는 코드가 새로 생겼다는 뜻이다(마이그레이션 0건과는 다른 말이다).
#   🔴 **고리 꼴로 적었다**(62번의 make_dumps 꼴) — 집이 늘면 줄만 더한다.
#      🔵 **하나라도 못 뜨면 멈춘다** — 되돌릴 길부터 만드는 자리다.
DUMPS='
dss-pg-app|dss_as|A/S관리
dss-pg-app|dss_inventory|재고관리
'
DUMPS_WANT=2
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
  ok "되돌릴 길이 **둘 다** 있다 (올라가는 집마다 하나씩)"
  return 0
}

backup_compose() {
  mkdir -p "$D/backups" 2>/dev/null
  if cp -a "$CF" "$BK"; then ok "compose 사본을 떴다 — $BK"
  else stop "compose 사본을 못 떴다 — **아무것도 안 바꿨습니다.**"; fi
}

# ══════════════════════════════════════════════════════════════════════
# 🔵 **묶음을 볼륨에 푸는 길(place_migs)이 없다**
# ══════════════════════════════════════════════════════════════════════
#   🔴 71-deploy.sh:2212-2259 에 그 함수가 있었다. 까닭은 머리말의 「왜 없는가」 ② —
#      **이번 범위의 drizzle/ 변경이 0줄**이라 볼륨에 더할 .sql 이 없다.
#   🔴 A/S 도구의 /app/drizzle 은 **여전히 비어 있고**(2-ㄷ 가 값으로 쟀다) 운영에서는
#      거기에 /volume1/dss/as-migrations 가 붙는다. 🔴 **.sql 이 한 장이라도 생기는
#      판에서는 71번에서 셋을 한 벌로 되살려라**(이 함수 · 3-ㄴ 절 · MIGTAR 변수 셋).
#      🔴 안 되살리면 적용이 **0건으로 조용히** 끝나고 겉으로는 성공으로 보인다.
#   🔵 그래서 이 파일에는 **볼륨에 쓰는 줄이 한 군데도 없다** — 2-ㄷ 는 **세기만** 한다.

# ══════════════════════════════════════════════════════════════════════
# ── 6. --tools : 🔴 **도구 태그만 간다. DB 는 안 바꾼다** ────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--tools" ]; then
  step "6. --tools — 🔴 **도구 태그 두 줄만 간다** (🔵 DB 는 한 글자도 안 바꾼다)"
  say "🔴 **71번에는 이 자리가 --migrate 였습니다** — 묶음을 볼륨에 풀고 · 도구 태그"
  say "   **둘**을 갈고 · db:migrate 로 A/S 의 DB 를 132 → 134 로 올렸습니다."
  say "   🔴 **이번 판은 마이그레이션이 0건**이라 올릴 것이 없습니다. 그 대신"
  say "   **tools 가 담는 것 중 바뀐 파일**이 A/S 21 · 재고 26 이라 도구 태그를 갑니다."
  say "   🔴 **1건이라도 생기는 판에서는 71번에서 --migrate 를 되살리세요.**"
  say "🔴🔴 **두 집에서 하는 일이 다릅니다:**"
  say "   · A/S  — 새 도구로 **db:preflight 를 돌려** 대기 0건을 값으로 받습니다."
  say "   · 재고 — 🔴 **그 집에는 db:preflight 도 check:* 도 없습니다**[실측: 명령 17개]."
  say "            그래서 **명령을 안 돌리고** compose 가 가리키는 이미지 **안을 셉니다**"
  say "            (.sql ${INV_IMG_SQL_WANT}장 · 도구 표식 둘 — 69번이 쓰던 길입니다)."
  say "   🔴 **A/S 판을 베껴 재고에 npm run db:preflight 를 부르면 Missing script 로**"
  say "      **멈춥니다** — 41번이 그 실패로 데었습니다."
  say "🔵 profiles: [tools] 라 평소에 뜨지 않습니다 — **직원이 느끼는 것이 없습니다.**"
  if [ "$PHASE_TOOL_NEW" = "$TOOLS_WANT" ]; then
    ok "도구가 이미 새 판이다 — 바꿀 것이 없다"
    say "🔵 그래도 아래에서 **db:preflight 와 이미지 안과 DB 수**는 다시 잽니다."
  fi

  say ""
  say "── 6-ㄱ. 🔴 되돌릴 길부터 만든다 — **덤프 둘**(dss_as · dss_inventory)"
  say "🔵 이 배포는 DB 를 한 글자도 안 바꿉니다. 그래도 뜨는 까닭은 **새 앱이 쓰는**"
  say "   **쪽에서 무엇을 할지는 이 배포본이 모르기** 때문입니다."
  say "   🔴 특히 **재고의 원장에 반환 줄이 실제로 쌓이기 시작합니다** — 신청 표에"
  say "      새 줄이 서고 [반환 완료]를 누르면 원장에도 섭니다. 자료를 바꾸는 코드가"
  say "      새로 생겼다는 뜻입니다(마이그레이션이 0건인 것과는 다른 말입니다)."
  if ! make_dump; then stop "덤프를 못 떴습니다 — **아무것도 안 바꿨습니다.** 되돌릴 길부터 만드세요."; fi

  say ""
  say "── 6-ㄴ. compose 사본"
  backup_compose

  say ""
  say "── 6-ㄷ. 🔴 **도구 태그 두 줄을 간다**"
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
  say "── 6-ㄹ. 🔴 **새 A/S 도구가 실제로 도는가** — db:preflight 를 값으로 받는다"
  say "🔴 **이번 판은 A/S 의 src/ 20장이 바뀌었습니다** — 그중 하나라도 import 가"
  say "   끊기면 여기서 **Cannot find module** 로 드러납니다. 🔵 db:preflight 는"
  say "   **읽기만** 합니다(Dockerfile 의 기본 명령입니다)."
  say "🔵 **이번 판의 기대값은 대기 0건입니다**(71번은 2건이었습니다)."
  say "   🔴 0 이 아니면 누가 볼륨에 .sql 을 넣었다는 뜻입니다 — **멈추고 알리세요.**"
  # 🔴 서비스 이름을 **여기 다시 적지 않는다** — TOOLS 표에서 꺼낸다.
  PFSVC=$(field "$(row_by_key "$TOOLS" astools)" 2)
  if [ -z "${PFSVC:-}" ]; then
    bad "TOOLS 표에서 astools 의 서비스 이름을 못 꺼냈다 — 표가 깨졌다"
    stop "앱은 한 줄도 안 건드렸습니다."
  fi
  say "도구 서비스: $PFSVC (TOOLS 표에서 꺼낸 값입니다)"
  dct run --rm "$PFSVC" npm run db:preflight 2>&1 | sed 's/^/      /'
  PRC=${PIPESTATUS[0]}
  say "(종료 코드 $PRC — 기대 0)"
  if [ "$PRC" = "0" ]; then
    ok "새 도구가 db:preflight 를 끝까지 돌았다 (import 가 닫혀 있다)"
    say "      🔴 위 글에 **대기 건수**가 적혀 있습니다. **0건이어야 합니다** —"
    say "         0 이 아니면 누가 볼륨에 .sql 을 넣었다는 뜻이니 **멈추고 알리세요.**"
  else
    bad "db:preflight 가 0 이 아니다 ($PRC)"
    say "      🔴 **Cannot find module 이 보이면** 도구 이미지에 담긴 것이 모자랍니다"
    say "         (vendor/dss-core 나 src/ 가 빠진 것입니다)."
    say "      🔴 그 밖이면 **볼륨에 사라질 자료가 있다는 뜻입니다.**"
    say "      🔵 **도구 줄은 이미 갈았습니다.** 되돌리려면 compose 사본: $BK"
    stop "앱은 한 줄도 안 건드렸습니다. 직원이 보는 화면은 그대로입니다."
  fi

  say ""
  say "── 6-ㄹ-2. 🔴🔴 **compose 가 가리키는 새 재고 도구의 안을 센다** (명령은 안 돌린다)"
  say "🔴 **이 집에는 db:preflight 가 없습니다** — 그래서 69번처럼 **이미지 안을 값으로**"
  say "   **재는 것**이 여기서 할 수 있는 전부입니다. 🔵 그래도 「옛 몸통으로 도는가」는"
  say "   가릴 수 있습니다 — 도구 표식 둘이 그 자리입니다."
  say "🔴 **서비스 이름을 여기 다시 적지 않습니다** — TOOLS 표에서 꺼냅니다."
  ITSVC=$(field "$(row_by_key "$TOOLS" inventorytools)" 2)
  if [ -z "${ITSVC:-}" ]; then
    bad "TOOLS 표에서 inventorytools 의 서비스 이름을 못 꺼냈다 — 표가 깨졌다"
    stop "앱은 한 줄도 안 건드렸습니다."
  fi
  say "도구 서비스: $ITSVC (TOOLS 표에서 꺼낸 값입니다)"
  NOWT=$(svc_image "$ITSVC")
  say "compose 가 지금 가리키는 재고 도구 이미지: ${NOWT:-못 읽음}"
  if [ -n "${NOWT:-}" ] && "$DOCKER" image inspect "$NOWT" >/dev/null 2>&1; then
    # 🔴 **이미지 안 .sql** — A/S 와 **정반대**로 ${INV_IMG_SQL_WANT}장이어야 한다.
    n=$(dock "$NOWT" -c "ls $IMG_MIGDIR/*.sql 2>/dev/null | wc -l"); n=$(printf '%s' "$n" | tr -d ' ')
    j=$(dock "$NOWT" -c "grep -c 'idx' $IMG_MIGDIR/meta/_journal.json 2>/dev/null"); j=$(printf '%s' "$j" | tr -d ' ')
    printf '      %s 안 .sql %s장 · idx %s개 (기대 %s · %s)\n' \
      "$IMG_MIGDIR" "${n:-?}" "${j:-?}" "$INV_IMG_SQL_WANT" "$INV_IMG_SQL_WANT"
    if [ "${n:-x}" = "$INV_IMG_SQL_WANT" ] && [ "${j:-x}" = "$INV_IMG_SQL_WANT" ]; then
      ok "새 재고 도구에 마이그레이션 ${INV_IMG_SQL_WANT}장과 목록이 다 담겼다"
    else
      bad "새 재고 도구 안이 .sql ${n:-?} · idx ${j:-?} 다 — ${INV_IMG_SQL_WANT} 을 기대했다"
      say "      🔴 **A/S 판을 베껴 0 을 기대하지 마세요** — 재고는 이미지가 정본입니다."
      doubt
    fi
    # 🔴 **도구 표식 둘** — 고리로 돈다(한 줄만 꺼내면 글자가 이어 붙어 깨진다).
    ITRAN=0
    while IFS='|' read -r TK TMK TMF TMW; do
      [ -n "${TK:-}" ] || continue
      [ "$TK" = "inventorytools" ] || continue
      ITRAN=$((ITRAN+1))
      v=$("$DOCKER" run --rm -e M="$TMK" -e F="$TMF" --entrypoint sh "$NOWT" -c \
        'p="/app/$F"; if [ -f "$p" ]; then printf "hit %s\n" "$(grep -cF -- "$M" "$p")"; else printf "missing 0\n"; fi' </dev/null 2>/dev/null | tr -d '\r')
      tst=$(printf '%s' "$v" | awk '{print $1}'); tn=$(printf '%s' "$v" | awk '{print $2}')
      printf '      도구 표식 [%s] in %s — 파일 %s · 그 글자 %s줄 (기대 hit · %s)\n' \
        "$TMK" "$TMF" "${tst:-못 읽음}" "${tn:-?}" "${TMW:-1}"
      if [ "${tst:-}" = "hit" ] && [ "${tn:-0}" -ge 1 ] 2>/dev/null; then
        ok "새 재고 도구에 **이번 판의 코드가 담겼다** (${tn}줄)"
        [ "${tn}" = "${TMW:-1}" ] || hm "그 글자가 ${tn}줄입니다 — ${TMW:-1} 을 기대했습니다. 사람이 보세요"
      elif [ "${tst:-}" = "hit" ]; then
        bad "그 글자가 **0줄**이다 — **옛 소스가 담긴 이미지다**"
      elif [ "${tst:-}" = "missing" ]; then
        bad "그 파일 자체가 없다 — src/ 가 온전히 안 담겼다"
      else
        bad "표식을 못 읽었다 (받은 값 [${v:-}])"
      fi
    done <<ENDITM
$(rows_of "$TOOLMARKS")
ENDITM
    printf '      이 이미지에서 돈 도구 표식 %s개 (기대 %s)\n' "$ITRAN" "$TOOLMARKS_PER_IMAGE_WANT"
    [ "$ITRAN" = "$TOOLMARKS_PER_IMAGE_WANT" ] && ok "재고 도구 표식 ${TOOLMARKS_PER_IMAGE_WANT}개를 다 돌았다" \
      || bad "재고 도구 표식을 ${ITRAN}개만 돌았다 — ${TOOLMARKS_PER_IMAGE_WANT}개를 기대했다. **한 자리가 아무 검사도 안 받았다**"
  else
    bad "compose 가 가리키는 재고 도구 이미지를 못 열었다 (${NOWT:-못 읽음})"
    say "      🔵 **도구 줄은 이미 갈았습니다.** 되돌리려면 compose 사본: $BK"
    stop "앱은 한 줄도 안 건드렸습니다. 직원이 보는 화면은 그대로입니다."
  fi

  say ""
  say "── 6-ㅁ. 🔴 **DB 가 정말 안 바뀌었는가** — 다섯 집을 다시 센다"
  say "🔴 이 모드는 DB 에 **쓰는 명령을 한 줄도 안 돌렸습니다.** 그래도 다시 재는"
  say "   까닭은, db:preflight 가 읽기 전용이라는 것을 **값으로 보이기** 위해서입니다."
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
    && ok "다섯 집의 마이그레이션 수가 **그대로다** (DB 를 한 글자도 안 바꿨다)" \
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
  printf '\n%s\n' "✅ 도구 **둘**이 새 판을 가리키고, A/S 도구는 실제로 돌았고 재고 도구는 안이 온전합니다."
  printf '%s\n' "   🔵 **DB 는 한 글자도 안 바뀌었습니다** — 이 배포는 바꿀 것이 없습니다."
  printf '%s\n' "   🔵 **앱은 아직 둘 다 옛 판입니다** — 직원이 보는 화면은 그대로입니다."
  printf '%s\n' "   다음: --go  ⏱ 앱 **둘**이 다시 뜹니다"
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
#   🔵 **기대 수를 부르는 쪽이 넘기는 꼴은 그대로 뒀다** — 이번 판은 늘 같은 수지만,
#      --rollback 은 적용 전에도 뒤에도 올 수 있어 그 길이 살아 있어야 한다.
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
    say "      🔴 **이번 판은 그 상자 하나에 두 집이 매달려 있습니다**(dss_as · dss_inventory)."
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
  # ── ② **dss_inventory 가 답하는가** (재고) — 🔴 **이번 판에 새로 생긴 자리다**
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
  say "── 🔴 옆으로 안 샜는가 — **안 건드리는 여덟을 1절의 값과 맞댄다**"
  say "🔴 **도는가만** 보지 않습니다 — **이미지와 켜진 때까지** 맞댑니다."
  say "🔵 **포털(dss-auth)이 이 목록에 있습니다** — 71번은 올라가는 집이라 빠져"
  say "   있었습니다. 🔴 **그 집이 여기서 달라지면 이 배포가 옆으로 샌 것**입니다."
  say "🔵 **재고관리(dss-inventory)는 이 목록에 없습니다** — 이번에 올라가는 집이라"
  say "   1절에서 빼 두었습니다(72번에는 들어 있었습니다)."
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
    && ok "안 건드리는 여덟이 **이미지도 켜진 때도 그대로다** (포털 포함)" \
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
  step "7. --go — 앱 **둘**을 갈아 끼운다 ⏱ 정지 창"
  say "🔴🔴 **둘을 한 번에 띄웁니다** — 한 기능이 두 집에 걸쳐 있어서 반쪽만 올리면"
  say "   [반환 요청] 창이 **빈 목록**이거나 올려도 **거절**됩니다."
  say "🔴 **차례는 SITES 표대로 A/S → 재고** 입니다. 🔵 이번 둘 사이에는 로그인 같은"
  say "   앞뒤 매듭이 없습니다 — 다만 **A/S 가 먼저 서야** 사람이 [반환 요청]을 눌렀을"
  say "   때 재고 쪽이 이미 받을 준비가 된 꼴이 되지 않습니다(그 반대가 더 위험합니다)."
  say "🔵 71번은 여기서 **A/S 를 먼저, 포털을 나중에** 띄웠습니다(포털이 먼저 내려가면"
  say "   그동안 모든 사이트의 로그인이 멈춥니다). 🔴 포털이 다시 올라가는 판에서는"
  say "   **SITES 표의 차례가 그 뜻을 갖는다**는 것을 잊지 마세요."
  say "🔴 **하나가 안 서면 거기서 멈춥니다** — 그때는 --rollback 으로 **둘을 함께**"
  say "   되돌리세요(1절의 단계가 ODD 로 보이면 그 상태입니다)."

  # 🔴 관문 ① — **DB 가 안 바뀌었는가**(이 배포는 바꿀 것이 없다)
  #    🔵 71번은 여기가 「DB 가 **올라갔는가**」(DBPHASE = DONE)였다 — 뜻이 반대다.
  if [ "$DBKEEP" != "KEEP" ]; then
    bad "DB 상태가 $DBKEEP 다 — KEEP 이어야 한다"
    say "      🔴 다섯 집의 마이그레이션 수가 **${AS_VOL_SQL_WANT}·28·5·11·3** 이 아닙니다."
    say "         이 배포본은 마이그레이션을 **한 건도 올리지 않습니다** — 수가"
    say "         달라졌다면 **이 배포와 무관한 다른 사고**입니다."
    stop "**아무것도 안 바꿨습니다.** 사람이 보세요."
  fi
  ok "DB 가 전과 같다 (이 배포는 DB 를 바꿀 것이 없다)"
  # 🔴 관문 ①-2 — **예순일곱째의 칸 넷이 아직 있는가.** 수만 믿지 않는다.
  #    🔵 71번은 「이번 판이 만든 칸이 생겼는가」였다 — 여기서는 **뒷걸음**을 본다.
  #       🔴 **그 칸이 사라지면 어제 올린 기능이 42703 으로 터진다** — 그래서 남겼다.
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

  # 🔴 관문 ② — 도구 **둘**이 새 판인가(--tools 가 돌았는가)
  if [ "$PHASE_TOOL_NEW" != "$TOOLS_WANT" ]; then
    bad "도구가 ${PHASE_TOOL_NEW}/${TOOLS_WANT} 만 새 판이다 — --tools 가 안 돌았다"
    say "      🔴 --tools 가 **덤프 둘을 뜨고** · 도구 태그 **둘**을 갈고 · A/S 는"
    say "         **db:preflight 를 돌려** import 가 닫혀 있는지 값으로 받고 · 재고는"
    say "         **이미지 안을 셉니다**(.sql ${INV_IMG_SQL_WANT}장 · 도구 표식 둘). 건너뛰지 마세요."
    stop "먼저 --tools 를 돌리세요. **아무것도 안 바꿨습니다.**"
  fi
  ok "도구 **둘**이 새 판이다 (--tools 가 돌았다 — 덤프와 preflight 와 이미지 세기가 끝났다)"

  # 🔴 관문 ③ — **--no-deps 를 쓰므로 DB 를 직접 잰다**
  say ""
  if ! go_gate "$AS_VOL_SQL_WANT"; then stop "**아무것도 안 바꿨습니다.** DB 부터 보세요."; fi

  say ""
  say "── 7-ㄱ. compose 사본"
  backup_compose

  say ""
  say "── 7-ㄴ. 🔴 image: 줄 **둘**을 바꾼다 (아직 안 띄운다)"
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
  say "── 7-ㄷ. ⏱ **여기서부터 정지 창** — 앱 **둘**을 띄운다 (40~60초)"
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
      say "      🔴 되돌리려면: bash $0 --rollback  (**둘을 함께** 되돌립니다)"
      say "      🔵 **DB 는 그대로 둡니다** — 이 배포는 DB 를 한 글자도 안 바꿨습니다."
      say "      🔵 **포털은 이번에 안 건드립니다** — 로그인은 그대로 됩니다."
      say "      🔴🔴 **지금은 반쪽만 올라간 상태입니다** — 한쪽만 새 판이면 [반환 요청]"
      say "         창이 **빈 목록**이거나 올려도 **거절**됩니다. 그대로 두지 마세요."
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
  printf '%s\n' "🔴 **배포 뒤에 눈으로 볼 곳 — 한 기능이 두 화면에 걸쳐 있습니다**"
  printf '%s\n' "══════════════════════════════════════════════════════════════"
  printf '%s\n' "  🔵 **--count 의 ⑭·⑯·⑰ 을 먼저 보세요** — 그 수가 0 이면 아래에서"
  printf '%s\n' "     **아무것도 안 보이는 것이 정상**입니다. 모르면 「고장」으로 읽습니다."
  printf '%s\n' "       ⑰ 돌려줄 건 0 → [반환 요청] 창이 **빈 목록**"
  printf '%s\n' "       ⑭ 반환 신청 0 → 재고의 신청 목록에 반환이 **한 줄도 없다**(지금은 맞다)"
  printf '%s\n' "       ⑯ 반환 완료 0 → 종에 「부품 반환이 완료되었습니다」가 **안 뜬다**"
  printf '%s\n' ""
  printf '%s\n' "  🔴 **ㄱ) [A/S] 수리 건에서 [반환 요청]을 올린다**"
  printf '%s\n' "  ① 수리 건 상세의 **부품 신청 자리**에 **[반환 요청]** 단추가 서야 합니다."
  printf '%s\n' "  ② 누르면 **그 건으로 나갔고 아직 안 돌아온 부품**이 목록에 떠야 합니다."
  printf '%s\n' "     🔴 **목록이 비면 먼저 --count 의 ⑰ 을 보세요** — 거기 0 이면 **정상**입니다."
  printf '%s\n' "     🔴 ⑰ 이 0 이 아닌데 비면 **재고 쪽 통로가 안 열린 것**입니다"
  printf '%s\n' "        (재고 앱이 옛 판이면 404 입니다 — 1절의 단계를 보세요)."
  printf '%s\n' "  ③ 🔴 **수량 칸의 최댓값이 「돌려줄 수 있는 수」여야** 합니다 — 나간 수량이"
  printf '%s\n' "     아닙니다. 그 수는 **재고가 세어 줍니다.**"
  printf '%s\n' "  ④ 올리면 **재고의 신청 목록에 반환 신청이 서야** 합니다(⑭ 가 하나 늡니다)."
  printf '%s\n' "  ⑤ 🔵 **유상/무상과 사유를 안 보냅니다** — 저쪽에 그 칸이 없습니다."
  printf '%s\n' "     적을 말은 **비고(note)** 입니다."
  printf '%s\n' ""
  printf '%s\n' "  🔴 **ㄴ) [A/S] 반출만 가리키던 글자 셋이 둘 다 담는 말로 바뀐다**"
  printf '%s\n' "  ⑥ 부품 신청 자리의 제목과 단추 글자를 보세요 — 「부품 신청 거두기」 꼴로"
  printf '%s\n' "     **반출과 반환을 함께 가리키는 말**이어야 합니다."
  printf '%s\n' ""
  printf '%s\n' "  🔴 **ㄷ) [재고] 반환 신청을 받고 [반환 완료]로 닫는다**"
  printf '%s\n' "  ⑦ 재고의 **신청 관리** 화면에서 그 반환 신청을 여세요 — 🔴 **돌려받을 내용**"
  printf '%s\n' "     (「돌려받을 내용을 확인하십시오」)이 보여야 합니다."
  printf '%s\n' "  ⑧ **[반환 완료]** 를 누르면 원장에 **되돌아온 줄**이 서고 신청이 닫힙니다."
  printf '%s\n' "     🔴 **그 뒤 A/S 에서 같은 건의 [반환 요청] 을 다시 열면 남은 수량이"
  printf '%s\n' "        그만큼 줄어** 있어야 합니다(두 번 돌려주는 길이 막혔다는 증거)."
  printf '%s\n' "  ⑨ 🔴 **반려·거둠은 종을 안 울립니다** — 물건이 안 돌아온 것이라 그렇습니다."
  printf '%s\n' ""
  printf '%s\n' "  🔴 **ㄹ) [재고] 반환이 끝나면 올린 사람의 종이 울린다**"
  printf '%s\n' "  ⑩ **올린 사람의 계정**으로 종을 여세요 — 「부품 반환이 완료되었습니다」가"
  printf '%s\n' "     **건마다 한 줄** 떠야 합니다."
  printf '%s\n' "  ⑪ 🔵 **남의 계정에는 안 떠야** 합니다(올린 사람에게만 가는 줄입니다)."
  printf '%s\n' ""
  printf '%s\n' "  🔴 **ㅁ) [재고] 기록 내역의 반환 건 머리글**"
  printf '%s\n' "  ⑫ 🔴 **--count 의 ⑱ 이 0 이면 한 줄도 안 달라집니다** — 먼저 그 수를 보세요."
  printf '%s\n' "  ⑬ [기록 내역]에서 **반환 건**을 보세요. 🔴 굵은 머리글이 **「반환」이 아니라**"
  printf '%s\n' "     **수리 건 인수번호**여야 합니다(옆의 종류 딱지는 그대로 「반환」입니다)."
  printf '%s\n' "  ⑭ 🔵 **대여나 「수리 건 없음」 반출을 되돌린 반환**은 머리글이 **빈 자리**입니다"
  printf '%s\n' "     — 「반환」으로 되돌아가지 않습니다. 🔴 그것이 정상입니다."
  printf '%s\n' "  ⑮ 🔵 **여러 수리 건이 섞인 반환**도 빈 자리입니다(하나를 골라 적지 않습니다)."
  printf '%s\n' "  ⑯ 🔴 **다른 종류(입고·폐기·조정·소유 옮김)는 한 글자도 안 바뀌어야** 합니다 —"
  printf '%s\n' "     거기에 인수번호가 뜨면 거짓말입니다."
  printf '%s\n' ""
  printf '%s\n' "  🔴 **ㅂ) 반출 쪽이 그대로인지도 꼭 보세요**(같은 표·같은 주소를 씁니다)"
  printf '%s\n' "  ⑰ 수리 건에서 **부품 반출 신청**을 전처럼 올릴 수 있어야 합니다."
  printf '%s\n' "     🔴 **--count 의 ⑮(반출 신청 수)가 배포 전후로 같아야** 합니다."
  printf '%s\n' "  ⑱ 재고의 **대기 목록·머리말 배지**에 반출 신청이 전처럼 세어져야 합니다."
  printf '%s\n' ""
  printf '%s\n' "  🔵 ⑲ **어제 것이 그대로 있는지도 보세요**(뒷걸음 눈 확인) —"
  printf '%s\n' "     ㄱ) [내자 정리]에서 **완료된 줄에 확정 단추가 안 서는지**(예순여덟째)."
  printf '%s\n' "     ㄴ) PO발행일을 적으면 **작업 상태가 [수리 대기]로 가는지**(예순여덟째)."
  printf '%s\n' "     ㄷ) 고객 안내 현황의 **「납품 요청일」**이 그대로 뜨는지(예순여덟째)."
  printf '%s\n' "     ㄹ) 재고의 **부품 요청 화면에서 도번이 제 줄에 크게** 뜨는지(예순다섯째)."
  printf '%s\n' ""
  printf '%s\n' "🔴 **다음에 할 일 둘** (아직 그대로입니다)"
  printf '%s\n' "  ㄱ) 06-notify-install.sh 의 **확인할 도구 태그**가 지금 운영과 맞는지 보세요."
  printf '%s\n' "     🔴 **이번 판이 도구 태그를 둘 갈았습니다**(A/S 31 · 재고 6)."
  printf '%s\n' "  ㄴ) 🔴 **PO 가 모르는 것이 여섯**입니다(머리말). PO 를 다시 여는 날 여섯을"
  printf '%s\n' "     한 묶음으로 이식하세요 — 🔵 **이번 판은 거기에 하나도 안 더했습니다.**"
  printf '%s\n' ""
  printf '%s\n' "🔴 **되돌리기**: bash $0 --rollback  (앱 **둘**을 함께 되돌립니다)"
  printf '%s\n' "   🔵 도구는 새 판 그대로 둡니다."
  printf '%s\n' "   🔵 **DB 는 되돌릴 것이 없습니다** — 칸을 한 개도 안 더했습니다."
  printf '%s\n' "   🔴 **되돌리면 반환 기능이 통째로 사라집니다** — 코드에만 있는 기능입니다."
  printf '%s\n' "      🔴 다만 **그 사이에 올라온 반환 신청 줄과 원장 줄은 자료라 남습니다**"
  printf '%s\n' "         (되돌아가지 않습니다). 🔵 남아도 해롭지 않습니다 — 재고 담당자가"
  printf '%s\n' "         화면에서 처리할 수 있고 옛 A/S 는 그 줄을 쳐다보지 않습니다."
  printf '%s\n' "      🔴 **한쪽만 되돌리지 마세요** — 반쪽만 올린 것과 같아집니다."
  printf '%s\n' "   🔵 덤프: $BKDB · compose 사본: $BK"
  printf '%s\n' "  다음: bash $0 --count  ← 올린 뒤 수를 재어 앞의 수와 맞대세요"
  printf '%s\n' "        🔴 **⓪~⑬ 과 ⑮·⑰ 이 전부 같은 수가 나오는 것이 정상**입니다."
  printf '%s\n' "        🔵 **⑭·⑯·⑱ 만 늘 수 있습니다** — 사람이 [반환 요청]을 누르는 순간부터"
  printf '%s\n' "           늡니다. 그것이 이 기능이 도는 증거이지 사고가 아닙니다."
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════
# ── 8. --rollback : 앱 둘을 함께 되돌린다 ───────────────────────────
# ══════════════════════════════════════════════════════════════════════
if [ "$MODE" = "--rollback" ]; then
  step "8. --rollback — 앱 **둘**을 옛 태그로 되돌린다"
  say "🔵 **도구는 새 판 그대로 둡니다**(39·41~72번과 같은 판단) — profiles: [tools]"
  say "   라 평소에 뜨지 않고, 옛 앱이 도구를 부르는 일도 없습니다."
  say "🔵 **DB 는 되돌릴 것이 없습니다** — 이 배포는 칸을 한 개도 안 더했습니다."
  say "🔴 **되돌리면 반환 기능이 통째로 사라집니다** — 코드에만 있는 기능입니다:"
  say "   ㄱ) A/S 에서 **[반환 요청] 단추가 없어집니다.**"
  say "   ㄴ) 재고의 통로(/api/v1/return-candidates)가 **404 로 돌아갑니다.**"
  say "   ㄷ) 반환 신청을 받는 길과 [반환 완료]와 종이 **다 없어집니다.**"
  say "🔴🔴 **그 사이에 올라온 반환 신청 줄과 원장 줄은 자료라 남습니다** — 되돌아"
  say "   가지 않습니다. 🔵 남아도 해롭지 않습니다: 재고 담당자가 화면에서 처리할 수"
  say "   있고, 옛 A/S 는 그 줄을 쳐다보지 않습니다."
  say "🔴🔴 **둘을 함께 되돌립니다** — 한쪽만 되돌리면 **반쪽만 올린 것과 같아집니다.**"
  say "🔵 포털은 이번에 안 건드렸습니다."
  say "🔴 **--no-deps 로 띄웁니다** — 되돌릴 때도 DB 를 Recreate 하면 안 됩니다."
  say ""
  # 🔴 **기대값을 지금 값으로 넘긴다** — --rollback 은 언제든 올 수 있다.
  #    여기서 재는 것은 「수가 맞는가」가 아니라 **「DB 가 실제로 답하는가」**다.
  RBWANT=$(mig_count dss-pg-app dss_as)
  if [ -z "${RBWANT:-}" ]; then
    bad "dss-pg-app 에서 dss_as 마이그레이션 수를 못 읽었다"
    stop "**아무것도 안 바꿨습니다.** DB 부터 보세요."
  fi
  say "지금 dss_as 는 ${RBWANT} 입니다 (🔵 이 배포는 그 수를 안 건드렸으므로 ${AS_VOL_SQL_WANT} 여야 합니다)"
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
  printf '%s\n' "🔵 앱 **둘**을 옛 판으로 되돌렸습니다. 도구는 새 판 그대로입니다."
  printf '%s\n' "   🔴 **1절의 단계는 MID 로 보입니다** — --tools 만 돌린 상태와 같은 모양입니다."
  printf '%s\n' "      🔴 **이번 판은 DB 가 안 바뀌어 그 둘을 DB 로 가를 수 없습니다**(71번은"
  printf '%s\n' "         dss_as 의 수로 갈렸습니다)."
  printf '%s\n' "      가르려면 **로그 파일 이름**(deploy69-go-… / deploy69-rollback-…)을 보세요."
  printf '%s\n' "   🔴 **이미 올라온 반환 신청 줄과 원장 줄은 그대로 남습니다** — 자료라서"
  printf '%s\n' "      되돌아가지 않습니다. 재고 화면에서 처리할 수 있습니다."
  printf '%s\n' "   🔵 **--count 의 ⑭·⑯ 은 되돌린 뒤에도 그 수 그대로입니다** — 0 으로"
  printf '%s\n' "      돌아가지 않습니다(그것이 정상입니다)."
  [ "$FAIL" = "0" ] && exit 0
  exit 1
fi
