#!/bin/bash
# dss-deploy/nas/setup/47-deploy.sh — 마흔네째 배포 (2026-10-29)
#
# 🔴 NAS 에서 돈다. DSM 터미널은 긴 명령을 잘라 먹으므로 **파일로 올려** 돌린다.
#    md5 를 맞춘다:  md5sum /volume1/dss/setup/47-deploy.sh
#
# ── 사람이 실행한다 ───────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                    ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/47-deploy.sh            ← 읽기만 한다
#   (NAS)         bash /volume1/dss/setup/47-deploy.sh --preload
#   (NAS)         bash /volume1/dss/setup/47-deploy.sh --go       ⏱ 정지 창
#
# ── 갈아 끼우는 것 — **저장소 하나, 태그 둘** ─────────────────────────
#     ① A/S 앱   dss-as:3.9        → **dss-as:4.0**        커밋 1
#     ② A/S 도구 dss-as-tools:6    → **dss-as-tools:7**    커밋 1
#
#   🔵 **앱 태그가 3.9 에서 4.0 으로 넘어간다.** 자릿수가 바뀌는 자리라 tar 이름
#      (dss-as-4.0.tar) · SITES 표 · tar2tag() 를 한 벌로 봐야 한다.
#   🔴 **마이그레이션이 없다.** A/S 의 drizzle/ 이 기준 SHA(081439b) 이후 0건이다.
#      그래서 이 파일에는 **--migrate 모드가 없다** — DB 를 건드리는 단계가 한
#      군데도 없다.
#   🔵 **나머지 아홉은 안 건드린다** — 통합 로그인 · PO · 재고 · 게시판 · 계측기 ·
#      개선요청 · RF 이슈관리 · 휴가 · 통합 승인함 아홉은 이번 범위에 커밋이
#      한 줄도 없다.
#
# ── 이 배포가 하는 일 — **커밋 하나** ─────────────────────────────────
#   3bde67e 고장 부품을 줄 수가 아니라 실제 수량으로 센다
#
#   🔴 **[고장 부품] 그래프가 「몇 줄」이 아니라 「몇 개」를 센다.**
#      · 지금(3.9)까지는 부품 요청 줄 하나를 **1** 로 셌다. 「불출 5개」인 줄도
#        1개였다.
#      · 4.0 부터는 **적힌 수량 그대로** 센다 — 요청 쪽은 requested_quantity,
#        연락서에서 읽어 저장한 사용 부품 쪽은 quantity 다.
#      · 🔴 **그래서 수가 크게 는다.** 사용자가 2026-10-29 에 본 모델은
#        「부품 4개」였는데 **18개**가 되어야 한다(불출 5+5+3+5).
#      · 🔴 **조각 차례도 바뀔 수 있다.** 순위를 줄 수가 아니라 수량으로 매기므로
#        기타로 밀려나는 부품이 달라진다 — **결함이 아니다.**
#   🔴 **저장된 글자는 한 자도 안 바뀐다.** DB 를 건드리는 단계가 없다(위).
#   🔵 **설정 이름도 안 는다.** 이 커밋에 새 환경변수가 한 개도 없다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 A/S 도구를 **왜 올리는가** — 한 판 만에 다시 「올린다」로 돌아왔다
# ══════════════════════════════════════════════════════════════════════
#   🔵 이력부터 한 줄씩. 이 판정이 넉 달 사이 여러 번 어긋났다:
#     · **서른여섯째(39번)**: 「마이그레이션 0건이니 안 올린다」 → **틀렸다**
#       (도구에 비상구 둘이 못 쓰는 채로 들어 있었다).
#     · **서른일곱째(40번)**: 「도구가 **부르는 명령**이 바뀌었나」로 판정해 안
#       올렸다 → **맞았다**.
#     · **서른여덟째(41번)**: 그 잣대로는 「**늘어난** 명령」이 안 걸렸다 → 올렸다.
#     · **서른아홉째(42번)**: 잣대를 「tools 스테이지가 담는 것 전부」로 넓혔다.
#     · **마흔째(43번)**: 도구가 **부르는 코드**가 바뀌어 올렸다.
#     · **마흔한째(44번)**: 도구가 **안 부르는** 파일이 바뀌었는데도 올렸다.
#     · **마흔두째(45번)**: 닫힘 안에 바뀐 파일이 **넷** — 「부르니까」 올렸다.
#     · **마흔세째(46번)**: 닫힘 안에 **하나도 없었다**(닫힘 161 · 바뀐 아홉 ·
#       겹침 0). 다섯 판을 내리 올린 뒤 처음으로 **안 올렸다.**
#
#   🔴 **마흔네째(이번)는 닫힘 안에 하나 있다. 그래서 다시 올린다.**
#      실측(2026-10-29, 46번이 쓴 펼치개를 글자 그대로 다시 씀):
#        · scripts/backfill-kyosan-used-parts.ts 에서 import 를 끝까지 펼치면
#          파일 **161개**(못 푼 상대경로 0개). 46번이 적은 수와 같다.
#        · 이번에 달라진 파일 **열다섯**과 맞대면 **하나가 겹친다**:
#            src/lib/domain/inventory-gateway.ts
#        · 🔴 **그 하나의 diff 는 주석뿐이다** — 실행문은 문맥 줄로 그대로 있다.
#          즉 **도는 코드는 한 글자도 안 바뀌었다.**
#
#   🔴 **그런데도 올린다. 까닭 다섯** (47-build.sh 머리말과 같은 글이다):
#     ㄱ) 46번이 세운 잣대는 「**부르는 파일**이 바뀌었나」이고 단위가 **파일**이다.
#        재면 **1 > 0** 이라 「올린다」가 나온다.
#     ㄴ) 39번의 넓은 잣대(「**담기는 것**이 바뀌었나」)로 재면 **15 > 0** 이다.
#     ㄷ) 🔵 **이번엔 두 잣대가 안 어긋난다.** 46번은 둘이 어긋났고(9 vs 0) 좁은
#        쪽이 이겼다. 이번은 둘 다 같은 답이라 다툴 것이 없다.
#     ㄹ) 🔴 「**주석만이니 안 올린다**」는 **셋째 잣대**이고 아무도 쓴 적이 없다.
#        그 잣대는 **사람이 매번 diff 를 끝까지 읽어야** 성립한다. 규칙으로 세워
#        두면 다음 판에 **주석 아닌 것이 섞여도 같은 길로 간다** — 그때 오류는
#        한 줄도 안 난다. 39번이 틀렸던 모양이 정확히 그것이었다.
#        🔵 치르는 값은 **tar 하나를 더 올리고 compose 의 image: 줄이 둘 달라지는
#           것**뿐이다. tools-as 는 profiles: [tools] 라 **다시 뜨지도 않는다.**
#     ㅁ) 🔴 **46번이 알고 진 빚을 함께 갚는다.** 46번은 「도구 이미지 안의 src/ 가
#        커밋 하나만큼 낡은 채로 남는다 · 44번 머리말 ㉡(도구와 앱의 src/ 가 같은
#        판이어야 한다)이 깨진다」고 적어 두었다. 지금 NAS 의 dss-as-tools:6 은
#        **4e918c7 판의 src/** 라 **두 판(커밋 2개 · 파일 19개)** 낡았다.
#        이번에 올리면 그 ㉡ 가 **다시 참이 된다.**
#
#   🔵 **다음 사람이 같은 판단을 다시 하는 법**은 47-build.sh 머리말에 명령 세
#      줄로 적어 두었다. 🔴 「겹치긴 하는데 주석만이다」가 나와도 **굽는 쪽**이다.
#
# ── 🔵 백필 — **이번 판에서도 다시 돌리지 않는다** ────────────────────
#   🔴 44·45·46-deploy.sh 와 같다. 까닭:
#     · 백필은 **2026-10-29 새벽에 283건이 끝났다**
#       (회차 e8c3c890-b1ba-42ec-a555-737609ad2e38). 사용 부품 **978줄**이 품번으로
#       들어가 있다.
#     · 이번 판이 바꾸는 것은 **화면 한 자리의 세는 자**다. 저장된 수량 칸을 **읽는
#       법**이 바뀔 뿐, **DB 에 들어간 값과 무관하다** — 돌려도 바뀔 줄이 없다.
#     · 🔵 46번은 여기에 「게다가 도구를 안 올리니 더더욱 할 일이 아니다」가 붙어
#       있었다. 이번 판은 **도구를 올린다** — 그래도 돌릴 까닭은 여전히 없다.
#       올리는 것과 돌리는 것은 다른 일이다.
#   🔵 백필이 다시 필요해지는 때는 **연락서를 읽는 규칙**(src/lib/kyosan/ 쪽)이
#      바뀌는 판이다. 그때 칠 명령은 43-deploy.sh 꼬리말에 그대로 있다
#      (/volume1/dss/setup/43-deploy.sh). 🔴 **--apply 가 없으면 DB 에 한 글자도 안
#      쓴다**는 것도 거기 적혀 있다.
#
# ── 🔴 연락서 폴더 검사 — 42번에서 넣었고 **그대로 둔다** ──────────────
#   41번이 compose 에서 재던 볼륨은 'as-migrations' 한 줄뿐이었다. 그런데 백필은
#   **연락서 원본 폴더를 읽어야** 돈다. 개발 PC 쪽 compose 사본은 운영보다 여러
#   판 낡아서 「사본에 있으니 운영에도 있겠지」가 성립하지 않는다 — 그래서 운영
#   파일에서 직접 센다.
#   🔵 **이번 판도 백필을 안 돌리므로 이 검사가 당장 쓰일 일은 없다.** 그래도
#      빼지 않는다 — 이 볼륨은 **연락서를 새로 이식할 때마다** 쓰이고, 조용히
#      빠져 있으면 다음에 이식하는 날 그 자리에서 막힌다. 한 번 빼면 다시 넣는
#      사람이 없다.
#     · 1절 : tools-as 블록에 '/kyosan-src' · '/kyosan-converted' 줄이 있나
#     · 7절 : --go 끝에 **폴더가 실제로 열리는지** 결과를 센다(줄이 아니라 결과)
#   🔴 **없어도 배포를 막지 않는다.** 앱 교체는 그 폴더와 무관하다. 그래서
#   1절에서는 ✗(FAIL) 가 아니라 **?** 로 센다 — ✗ 는 4·5절의 문을 닫아
#   멀쩡한 교체까지 막는다.
#   🔵 7절의 검사는 compose 에 적힌 태그로 띄운다 — --go 뒤라면 **새로 올린
#      dss-as-tools:7** 이다.
#
# ── 🔴 이번 배포에서 **동작이 바뀌는 자리** — 쓰는 분이 눈으로 볼 곳 ────
#   ① 🔴 **제품 모델 상세 → [A/S 이력] → [고장 부품].**
#      · **수가 크게 는다.** 한 부품의 조각 크기가 「그 부품이 적힌 줄 수」에서
#        「**실제 수량 합**」으로 바뀐다. 2026-10-29 에 사용자가 본 모델은
#        「부품 4개」가 **18개**가 되어야 한다(불출 5+5+3+5).
#      · 🔴 **조각 차례가 바뀔 수 있다. 결함이 아니다.** 순위를 수량으로 매기므로
#        기타로 밀려나는 부품도 달라진다.
#      · 🔵 설명 줄 맨 앞에 「개수는 부품 줄 수가 아니라 **실제 수량**입니다」가
#        생긴다.
#      · 🔵 「**부품 기록이 있는 N건**」은 **건수 그대로**다 — 그 수는 안 바뀐다.
#        바뀌는 것은 조각의 크기와 차례뿐이다.
#   ② 🔵 수량이 전부 1 인 모델은 **보이는 것이 하나도 안 바뀐다.**
#   ③ 🔵 **반출 몫을 세는 범위는 46번이 올린 그대로다** — 건수 상한이 없고 전체
#      5초 예산을 쓴다. 느린 날의 띠도 그대로다.
#   ④ 🔵 **기대치 — 이름이 안 붙고 품번만 보이는 줄이 많다. 결함이 아니다.**
#      이름이 붙으려면 맞은 재고 관리 줄에 **고객사 품명이 적혀 있어야** 하는데,
#      재고 관리 부품 **319줄 중 고객사 품명이 적힌 줄은 27개뿐**이다(2026-10-29 실측).
#      🔵 **재고 관리에서 고객사 품명을 채우면 A/S 는 아무것도 안 고쳐도 저절로
#         붙는다.**
#   ⑤ 🔵 **저장된 글자는 안 바뀐다.** 백필을 다시 돌릴 까닭이 없는 것도 그래서다.
#   ⑥ 🔵 **[사용부품] 문지기는 45번이 올린 그대로다** — 이번 판이 안 건드린다.
#      🔵 그 문지기가 쓰는 수는 여전히 **줄 수**다(그래프만 수량으로 바뀌었다).
#         두 자리가 **같은 줄 집합**을 보되 세는 자가 다른 것이고, 그 까닭이
#         src/lib/domain/inventory-gateway.ts 의 주석에 적혀 있다 — 이번 커밋이
#         바꾼 것이 바로 그 주석이다.
#   ⑦ 🔵 **연락서 이식 규칙도 안 건드린다** — 43번이 올린 판본 C 의 칸 차례와
#      겹친 줄 수량 더하기는 **그대로다.**
#
# ── 🔴 ①-보조: 재고 관리가 꺼져 있으면 **두 군데가 막힌다** ────────────
#   🔵 45번에서 처음 적었고 46번에서 한 자리가 늘었다. 이번 판도 그대로다:
#     ㄱ) **[사용부품] 칸이 모든 건에서 막힌다**(45번부터 — 이미 운영 중인 동작).
#        문지기가 「못 물어봤다」를 「없다」로 눕히지 않기 때문이다.
#     ㄴ) 🔴 **[고장 부품] 그래프의 반출 몫이 통째로 빠진다.** 46번이 건수 상한을
#        없앴기 때문에 수리 건이 많은 모델일수록 재고 관리에 묻는 횟수가 많다.
#        저쪽이 죽어 있으면 그 물음이 전부 실패하고 화면이 「받아오지 못했습니다」를
#        적는다. 🔵 **페이지가 안 뜨지는 않는다** — 전체 5초 예산이 못 박혀 있다.
#   🔴 **운영 설정이 빠져 있어도 똑같다.** 이름이 둘이다:
#        INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN  (NAS 의 env/as.env)
#      운영은 이미 재고 관리를 쓰고 있어 둘 다 있을 것이다. 🔴 **그래도 짐작하지
#      않는다** — 아래 7절이 **「설정이 적혀 있나」가 아니라 「물어보니 답하나」**를
#      앱 컨테이너 안에서 실제로 잰다(inventory_gateway_check).
#   🔵 7절은 재고관리 컨테이너가 계속 도는지(KEEP_BOXES)도 그대로 센다.
#
# ── 🔴 46번(지난 판)과 다른 것 ─────────────────────────────────────────
#   ① 🔴 **태그가 하나에서 둘로 늘었다.** 도구도 올린다. 그래서 5절의 「image: 줄이
#      꼭 몇 개 달라졌나」 기대값이 **--go 2 · --rollback 1** 이다(46번은 둘 다 1).
#   ② 🔴 **tools_inside_check 가 돌아왔다**(출처 45-deploy.sh). 올리는 이미지이므로
#      속을 센다. 🔵 단계 여섯 가운데 ③-ㄱ 이 다섯에서 **여섯**으로 늘고, ③-ㄴ 의
#      이름 셋이 **이번 판의 것으로** 바뀐다 — 까닭은 그 함수 위에 적었다.
#   ③ 🔴 **1절의 도구 검사가 「안 건드렸는가」에서 「옛 판인가」로 되돌아갔다**
#      (45번 방식). --go 가 그 줄을 고치기 때문이다.
#   ④ 🔵 **연락서 폴더 검사는 42~46번 것 그대로다.**
#   ⑤ 🔵 **재고 관리 통로 검사도 45·46번 것 그대로다** — 🔴 **빼지 않는다.**
#   ⑥ 🔵 **꼬리말의 백필 안내는 44~46번과 같다** — 「돌리지 않는다」. 다만 「도구를
#      안 올렸으니 더더욱」 한 줄은 뺐다(이번엔 올린다).
#   ⑦ 🔵 **--rollback 은 앱만 되돌린다.** 도구는 :7 그대로 둔다 — 39·41~45번과
#      같은 판단이다(새 도구가 있는 편이 낫다. 되돌릴 일이 생겨도 이 도구는
#      '--apply' 를 주지 않으면 DB 에 한 글자도 안 쓴다).
#   ⑧ 🔵 **다시 띄우는 것은 app-as 하나뿐이다.** tools-as 는 'profiles: [tools]' 라
#      평소에 뜨지 않는 서비스다 — compose 의 태그만 새 것으로 고쳐 두면 다음에
#      'run --rm tools-as' 로 부를 때 새 이미지를 쓴다. **up -d 로 띄우지 않는다.**
#   ⑨ 🔵 RF_Service_System 의 Dockerfile 은 tools 스테이지를 runner **앞에** 둔다 —
#      --target 없이 구우면 마지막 스테이지(runner)가 기본값이 된다. 그 함정은
#      47-build.sh 쪽 이야기지만, 결과가 맞게 왔는지는 이 파일의 3절이 다시 센다.
#
# ── 🔴 개발 PC → NAS 로 올릴 것 — **둘** ───────────────────────────────
#   ㄱ) 이미지 tar **둘** → /volume1/dss/images/
#        dss-as-4.0.tar · dss-as-tools-7.tar
#   ㄴ) 이 파일 → /volume1/dss/setup/
#
#   (개발 PC · PowerShell)
#     cd C:\Users\희만\Desktop\Development\_images-44
#     scp -O dss-as-4.0.tar dss-as-tools-7.tar dss-nas:/volume1/dss/images/
#     cd C:\Users\희만\Desktop\Development
#     scp -O dss-deploy\nas\setup\47-deploy.sh dss-nas:/volume1/dss/setup/
#     Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\47-deploy.sh
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#   🔴 tar 에 드라이브 문자(C:)를 주지 마세요 — 원격 호스트로 읽습니다.
#
# ── 모드 넷 ───────────────────────────────────────────────────────────
#   (기본)   --check      아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --preload             tar 둘을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --go                  compose 의 image: 줄 둘(app-as·tools-as)을 바꾸고
#                         app-as 만 다시 띄운다
#   --rollback            app-as 만 옛 판으로 되돌린다 (도구는 :7 그대로)
#
#   🔴 차례:  --check → --preload → --check → --go
#
# ── 🔴 --check 도 「아무것도 안 한다」는 아니다 ───────────────────────
#   A/S DB 에 **select** 를 한 번 보낸다(마이그레이션 수가 그대로인지 — 바꾸는
#   문장은 없다). 앱의 바깥 주소에 GET 을 한 번 보낸다. 재고 관리 통로에도
#   **GET 을 한 번** 보낸다(읽기만 한다). 도구 이미지가 이미 실려 있으면
#   **안을 보려고 컨테이너를 잠깐 띄웠다 지운다**(docker run --rm, DB 에는 안
#   닿는다 — DATABASE_URL 을 안 주고 부른다).
#   「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 쓴 뒤 세었다.
#   ② 읽기 전용 자리에 콜론 하나와 꺾쇠로 빈 파일을 만들면 NAS 의 ash 가 셸을
#      그 자리에서 끝낸다(2026-10-12 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 빈 파일은 touch, 폴더는 mkdir.
#
# ── 🔴 비밀값을 찍지 않는다 ───────────────────────────────────────────
#   .env 는 **이름이 있는가/없는가**만 본다. 값도, 값의 길이도 찍지 않는다.
#   🔴 7절의 재고 관리 검사도 마찬가지다 — 토큰을 **쓰기만** 하고 찍지 않는다.
#      찍는 것은 HTTP 상태와 받은 줄 수뿐이다.
#   이번 판에 새로 필요한 설정 이름은 없다.
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
CF=$D/deploy/docker-compose.nas.yml
IMGD=$D/images
BK=$D/backups/docker-compose.nas.yml.v44-$STAMP

# ══ 이번에 다시 띄우는 것 — 앱 하나뿐이다 ═════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
SITES='
as|app-as|dss-as|dss-as:4.0|dss-as:3.9|dss-as-4.0.tar|13000
'
# 🔵 7절의 재고 관리 검사가 명령을 넣을 상자. 위 표 셋째 칸과 같은 이름이다.
AS_APP_CN=dss-as
# ══ 🔴 A/S 도구 — **이번에 갈아 끼운다.** up -d 로 다시 띄우지 않는다 ═══
#   (profiles: [tools] 라 평소에 뜨지 않는다. compose 의 태그만 고치면
#    다음에 run --rm tools-as 로 부를 때 새 이미지를 쓴다.)
#   🔵 46번에는 이 자리에 값이 **하나**뿐이었다(안 올리는 판이라 갈아 끼울 것이
#      없었다). 45번처럼 둘로 돌아왔다.
AS_TOOLS_SVC=tools-as
TOOLS_OLD=dss-as-tools:6
TOOLS_NEW=dss-as-tools:7
IMG_MIGDIR=/app/drizzle
MIGDIR=$D/as-migrations

# ══ 🔴 연락서 원본 폴더 — 연락서를 이식할 때 읽는 자리 ════════════════
#   🔵 기대값의 출처: 2026-10-28 실측 673장 · 143장. 늘기만 하는 폴더라 아래
#      바닥값으로 잰다. 🔴 **0 이면 볼륨 줄은 있는데 안 열리는 것**이고, 그것이
#      제일 조용한 실패다.
KYO_SRC=/kyosan-src;        KYO_SRC_MIN=600
KYO_CONV=/kyosan-converted; KYO_CONV_MIN=100

# ══ 🔴 tar 둘의 지문 — [배포본] 47-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   ✅ **채웠다** — 2026-10-29 17:49 에 47-build.sh --go 가 굽고 **바로 잰 값**이다.
#      (비어 있으면 3절이 **? 로 센다** — 「옮기다 깨진 것」은 잡지만 「개발 PC 에서
#      구운 그것이 맞나」는 못 본다.)
#   🔵 이름만이라도 적어 두는 까닭: 줄이 아예 없으면 4절(--preload)이 **아무것도
#      안 싣고 조용히 끝난다.** 이름이 있으면 싣기는 제대로 된다.
TARS='
dss-as-4.0.tar|132502528|ed058dadd19d5a31ece0527e72cbb5f6|sha256:c1c8c39b5990ce8066d2093ec61b6c5fe96d51683b2e5d10bf3596a5cd556629
dss-as-tools-7.tar|223720960|940ee2e7a5e0ec8da731fd7d3f1ae85c|sha256:af02717fffff4d23871144da0a412cd6fbe9c71fdfb84b792ff2187b5d58b3cd
'
tar2tag() {
  case "$1" in
    dss-as-4.0.tar)      printf 'dss-as:4.0' ;;
    dss-as-tools-7.tar)  printf 'dss-as-tools:7' ;;
  esac
}

# ══ 🔴 A/S — DB 는 **그대로여야** 한다(마이그레이션 0건) ═════════════
AS_BOX=dss-pg-app; AS_DB=dss_as; AS_KEEP=121   # [저장소] 47-build.sh 4절과 같다
# 🔵 안 건드리는 아홉 — 「옆으로 안 샜다」는 증거로 센다
KEEP_BOXES="dss-auth dss-inventory dss-meters dss-po dss-board dss-improvements dss-leave dss-approvals dss-rf-trouble"
# 🔵 DB 둘은 멈추지 않는다 (애초에 up -d --no-deps 가 app-as 하나만 건드린다)
KEEP_DB="dss-pg-app dss-pg-auth"

MODE=check
case "${1:-}" in
  --check|"")  MODE=check ;;
  --preload)   MODE=preload ;;
  --go)        MODE=go ;;
  --rollback)  MODE=rollback ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --preload · --go · --rollback\n' "$1"; exit 2 ;;
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
LOG="$D/setup/logs/47-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "마흔네째 배포 — A/S 앱 하나 + 도구 하나   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
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

# ══ 🔴 재고 관리 통로가 **값을 돌려주는가** (45·46번 것을 글자 그대로 가져왔다) ══
#   🔴 **빼지 않는다.** 이것은 **앱**이 쓰는 길이다. 45번이 운영에서
#      'HTTP 200 rows 319' 를 받은 바로 그 검사다.
#   🔴 「설정이 적혀 있다」가 아니라 **「물어보니 답한다」**로 잰다. 설정은 있는데
#      주소가 안 닿거나 토큰이 안 맞는 경우가 제일 아픈 실패다 — [사용부품] 칸이
#      모든 건에서 막히고 **[고장 부품] 그래프의 반출 몫까지 통째로 빠진다**
#      (머리말 ①-보조 ㄴ).
#   🔴 **앱이 쓰는 길로 잰다** — 막히는 자리가 app-as 안이므로 그 컨테이너 안에서
#      묻는다. 바깥에서 재면 그 컨테이너의 설정이 아니라 NAS 의 망을 재게 된다.
#   🔵 **읽기만 한다.** GET /api/v1/parts 한 번이고(앱이 부품 이름을 얻을 때 쓰는
#      바로 그 통로다 — server/inventory-gateway.ts 216줄), 저쪽 DB 에도 A/S DB 에도
#      한 글자 안 쓴다. 토큰은 쓰기만 하고 **찍지 않는다.**
#   🔵 쓰기 토큰(INVENTORY_WRITE_TOKEN)은 안 본다 — 막히고 풀리는 자리는
#      **읽기 쪽** 하나다.
#   🔴 **도구 쪽(tools-as)은 안 잰다.** 까닭을 적어 둔다 — 백필도 같은 설정을 쓰지만
#      못 물어보면 **아무것도 안 쓰고 멈춘다**(outcome 'inventory-unknown' —
#      scripts/lib/kyosan-used-parts-backfill.ts 408-416줄). 즉 설정이 빠져도 자료가
#      상하지 않고, 이번 판은 백필을 아예 안 돌린다.
#
#   받는 답은 셋 중 하나다(일부러 ASCII 로만 찍게 했다 — 한글을 argv 로 넘겨
#   깨지는 길을 아예 두지 않는다):
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
        ok "재고 관리가 답한다 — 200 · 부품 ${rows}줄 ([고장 부품]의 반출 몫이 센다)"
        say "🔵 고객사 품명이 적힌 줄은 그중 일부뿐이다(2026-10-29 실측 319줄 중 27줄)."
        say "   이름이 안 붙고 품번만 보이는 줄이 많은 것은 **결함이 아니다.**"
      else
        hm "200 인데 부품 줄이 ${rows:-?} 이다 — 응답 모양이 기대와 다르다. 사람이 보세요"
        doubt
      fi ;;
    NOCONF*)
      say "🔴 **설정이 비어 있다.** 값은 안 찍는다 — 0 은 비었다는 뜻이다."
      say "   고칠 자리: NAS 의 /volume1/dss/deploy/env/as.env (root 600)"
      say "   이름 둘: INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN"
      if [ "$strict" = 1 ]; then
        bad "🔴 재고 관리 설정이 비어 **[사용부품] 칸이 막히고 [고장 부품]의 반출 몫이 빠진다** — 설정을 넣고 app-as 를 다시 띄우세요"
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
        bad "🔴 재고 관리가 안 답한다 — **[사용부품] 칸이 막히고 [고장 부품]의 반출 몫이 빠진다.** 위 줄을 보세요"
      else
        hm "재고 관리가 안 답한다 — **이대로 --go 해도 반출 몫이 안 보인다**"
      fi
      printf '%s\n' "$out" | tail -8 | sed 's/^/      /'
      doubt ;;
  esac
}

# ══ 🔴 도구 이미지 안을 센다 — 겉이 아니라 결과 (출처 45-deploy.sh) ═══
#   🔵 46번에는 이 함수가 **없었다**(안 올리는 이미지의 속을 세는 것은 그 배포의
#      일이 아니었다). 이번 판은 올리므로 도로 가져왔다.
#   🔴 이 도구는 평소에 안 뜬다. 안이 모자라도 **그날 아무 일이 안 일어나고**,
#      드러나는 것은 **쓸 일이 생긴 날**의 「모듈을 못 찾는다」 한 줄뿐이다.
#   🔵 단계 여섯은 45번 그대로다. 두 자리만 이번 판에 맞춰 바꿨다:
#      ③-ㄱ 파일 다섯 → **여섯**(이번에 닫힘 안에서 바뀐 domain/inventory-gateway.ts
#           를 더했다).
#      ③-ㄴ 이름 셋을 **이번 커밋에서 새로 생긴 것**으로 갈았다 — 아래 그 자리에
#           까닭을 길게 적었다.
#   🔴 **「✗ 가 아니면 ✓」로 세지 않는다.** ✓ 조건만 정확히 적고 나머지는 ? 다 —
#      ✓ 쪽 오판은 영영 안 드러난다.
tools_inside_check() {
  local v got
  printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TOOLS_NEW"
  # ① runner 가 아니라 tools 인가 — runner 에는 /app/package.json 이 없다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/package.json: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "tools 스테이지가 맞다" \
    || { bad "🔴 /app/package.json 이 없다 — **runner 를 구웠다.**"; doubt; }
  # ② 백필 도구 파일 셋이 다 담겼는가 — 하나라도 없으면 ✗.
  #    🔵 이번 판에서 이 셋은 한 글자도 안 바뀌었지만, 있어야 부를 수 있다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts /app/scripts/lib/kyosan-used-parts-backfill-plan.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "3" ] && ok "백필 도구 파일 셋이 다 들어 있다" \
    || bad "🔴 백필 도구 파일이 ${got:-0}/3 개다 — scripts/ 가 온전히 안 담겼다"
  # ③-ㄱ 🔴 **src/ 가 온전히 담겼는가 — 파일 여섯으로 센다.** 앞의 다섯은
  #    43·44·45번 것 그대로, 여섯째가 이번에 더한 것이고 **이번에 도구 닫힘 안에서
  #    바뀐 바로 그 파일**이다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/src/lib/kyosan/parts-detail-sheet.ts /app/src/lib/kyosan/report-preview.ts /app/src/lib/domain/used-part-display.ts /app/src/lib/auth/repair-case-used-parts-authorization.ts /app/src/lib/server/inventory-gateway.ts /app/src/lib/domain/inventory-gateway.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "6" ] && ok "src/ 의 파일 여섯이 다 들어 있다 (도구와 앱이 같은 판이다)" \
    || { bad "🔴 src/ 의 파일이 ${got:-0}/6 개다 — src/ 가 온전히 안 담겼다"; doubt; }
  # ③-ㄴ 🔴 **그 src/ 가 '이번 판' 인가 — 글자로 센다.** ㄱ 은 「있나」만 보므로
  #    낡은 src/ 가 담겨도 통과한다.
  #    🔴 **여기가 45번과 크게 다른 자리다.** 45번은 닫힘 안에서 바뀐 파일에서 새
  #       이름을 뽑았다. 이번 판은 닫힘 안에서 바뀐 파일이 하나뿐이고 그 하나는
  #       **주석만** 바뀌어 **새 이름이 아예 없다.** 그래서 이름 셋을 닫힘 밖,
  #       그러나 **이번 커밋에서 새로 생긴** 자리에서 뽑았다.
  #       🔵 그래도 되는 까닭: 이 검사가 묻는 것은 「도구가 무엇을 부르나」가 아니라
  #          「**이 이미지의 src/ 가 어느 판인가**」다. tools 스테이지가
  #          COPY src ./src 로 src/ 를 **통째로** 담으므로, src/ 어디서 뽑은 이름이든
  #          판을 똑같이 가른다.
  #    🔵 셋 다 기준 081439b 판의 그 파일에는 **0번** 나오고 지금 판에는 나온다
  #       (2026-10-29 git show 로 파일마다 세어 확인: 0 → 8 · 0 → 9 · 0 → 1).
  #    🔴 이름은 전부 **ASCII** 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for pair in "faultPartQuantity /app/src/lib/domain/product-model-fault-parts.ts" "weightOf /app/src/lib/domain/pie-slices.ts" "requestedQuantity /app/src/lib/db/queries/product-models.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "3" ] && ok "이번 판의 이름 셋이 이미지 안에 있다 (옛 src/ 가 아니다)" \
    || { bad "🔴 이번 판의 이름이 ${got:-0}/3 개다 — **옛 src/ 가 담긴 이미지다.** 올리지 마세요"; doubt; }
  # ④ tsx 가 있는가 — 이 도구는 tsx 로만 돈다(운영 이미지에는 없는 devDependency다).
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/node_modules/tsx: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "tsx 가 있다" \
    || bad "🔴 tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다"
  # ⑤ 🔴 값으로 받아 본다. DATABASE_URL 을 안 준다 — DB 에 안 닿는다.
  #    그 파일이 1줄에서 './load-env' 를, 9줄에서 '../src/lib/db/connection' 을
  #    정적 import 하고 connection.ts 가 모듈 맨 위에서 동기적으로 던진다.
  #    🔴 ⑤ 가 말해 주는 것은 **import 가 선다**까지다. 🔵 이번 판도 백필을 다시
  #       돌리지 않으므로, 도구가 선다는 것을 확인할 자리가 **여기 말고 없다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'cd /app && node --conditions=react-server --import tsx scripts/backfill-kyosan-used-parts.ts 2>&1 | head -40' 2>&1 | tr -d '\r')
  if printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
    ok "import 까지 갔고 DB 에는 안 닿았다 (DATABASE_URL is not set — 기대한 답)"
  elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
    bad "🔴 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
  else
    hm "기대한 답이 아니다 — 아래 20줄을 사람이 보세요"
    printf '%s\n' "$v" | head -20 | sed 's/^/      /'
  fi
}

# ══ 🔴 연락서 폴더가 **실제로 열리는가** — 줄이 아니라 결과 ══════════
#   🔵 1절은 compose 에 줄이 있는지만 본다. 줄은 있는데 안 열리는 것이 제일
#      조용한 실패라 여기서 **수를 받아** 본다. 보내는 명령은 ls 뿐이다 —
#      이 서비스에는 DATABASE_URL 이 들어 있지만 ls 는 DB 를 안 건드린다.
#   🔵 -T 는 가짜 터미널을 안 만들려고 준다. 없으면 줄 끝에 캐리지리턴이 붙어
#      수를 파싱하는 쪽이 어긋날 수 있다.
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

# ── 1. 지금 상태 ──────────────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
[ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
say "compose 줄 수 $(wc -l < "$CF") · image: 줄 $(grep -c '^ *image:' "$CF")개"
for r in $(rows); do
  SVC=$(fld "$r" 2); CN=$(fld "$r" 3); NEW=$(fld "$r" 4); OLD=$(fld "$r" 5)
  L=$(img_line "$SVC") || { bad "$SVC — compose 에서 image: 줄을 못 찾았다"; continue; }
  CUR=$(tag_at "$L")
  ST=$("$DOCKER" inspect -f '{{.State.Status}}' "$CN" 2>/dev/null)
  RUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$CN" 2>/dev/null)
  say "$SVC — ${L}줄 · compose ${CUR} · 도는 것 ${RUN:-없음} (${ST:-?})"
  if [ "$CUR" = "$OLD" ]; then ok "$SVC 가 옛 판 $OLD 다 (갈아 끼울 준비)"
  elif [ "$CUR" = "$NEW" ]; then hm "$SVC 가 이미 $NEW 다 (다시 돌리는 중인가)"
  else bad "$SVC 의 태그가 $CUR 다 — 옛 판도 새 판도 아니다. 멈추고 알릴 것"; doubt; fi
done
# ══ 🔴 A/S 도구 — **이번엔 이 배포가 고치는 줄이다** ═════════════════
#   🔵 46번은 여기서 「안 건드렸는가」를 쟀다(고칠 것이 없는 판이었다).
#      이 파일은 45번 방식으로 돌아간다 — **옛 판인가. --go 가 고친다.**
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  say "$AS_TOOLS_SVC — ${TL}줄 · $TCUR"
  case "$MODE" in
    rollback)
      # 🔵 되돌려도 도구는 :7 그대로 둔다(머리말 ⑦). 그래서 기대값이 새 판이다.
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
  # 🔴 42번에서 넣은 검사다. 연락서를 이식하려면 원본 폴더가 열려야 한다. 개발 PC 쪽
  #    compose 사본은 운영보다 여러 판 낡아서 「사본에 있으니 운영에도 있겠지」가
  #    성립하지 않는다 — 운영 파일에서 센다. 🔵 **이번 판도 백필을 안 돌리므로 당장
  #    쓰이지는 않는다.** 그래도 빼지 않는다 — 다음 이식 때 조용히 막히는 자리다.
  #    🔵 **없어도 교체를 막지 않는다.** 그래서 ✗ 가 아니라 ? 로 센다 — ✗ 는 4·5절의
  #       문을 닫아 멀쩡한 교체까지 막는다.
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

# ── 2. 🔴 A/S DB — 마이그레이션 수가 **그대로여야** 한다 ──────────────
printf '\n== 2. A/S DB — 마이그레이션 %s 그대로여야 한다\n' "$AS_KEEP"
MIG_AS0=$(mig_count "$AS_BOX" "$AS_DB")
say "A/S 기록 ${MIG_AS0:-?} (기대 $AS_KEEP 그대로)"
if [ -z "${MIG_AS0:-}" ]; then
  bad "DB 를 못 쟀다 — $AS_BOX 가 도는지 보세요"
elif [ "$MIG_AS0" = "$AS_KEEP" ]; then
  ok "A/S 가 $AS_KEEP 그대로다 (이 배포는 DB 를 건드리지 않는다)"
else
  bad "🔴 A/S 가 ${MIG_AS0} 이다 ($AS_KEEP 이어야 한다) — 다른 배포가 먼저 돌았거나 전제가 깨졌다"
  doubt
fi

# ── 3. 들여올 이미지 둘 ───────────────────────────────────────────────
printf '\n== 3. 들여올 이미지 둘 (앱 하나 · 도구 하나)\n'
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
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 47-build.sh --go 가 끝에 찍어 주는"
  printf '%s\n' "     두 줄로 이 파일의 TARS 두 줄을 통째로 갈아 끼우세요."
fi
# 🔵 되돌릴 길 — 옛 태그가 남아 있는가(app-as 만. 도구는 되돌리지 않는다)
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
#    여기서 ? 가 나면 **--go 하기 전에 설정부터 고치는 것**이 맞다 — 고치지 않고
#    올리면 [고장 부품]의 반출 몫이 안 보이고 [사용부품] 칸도 막힌다(머리말 ①-보조).
if [ "$MODE" = check ]; then inventory_gateway_check soft; fi

if [ "$MODE" = check ]; then
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.** 다음: --preload → (다시 --check) → --go"
  printf '%s\n' "🔴 올리기 전에 돌리면 ? 가 여럿 나오는 것이 **정상**이다 (tar)."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 4. --preload : tar 둘을 들여놓는다 ───────────────────────────────
if [ "$MODE" = preload ] || [ "$MODE" = go ]; then
  printf '\n== 4. tar 둘을 들여놓는다\n'
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **아무것도 안 하고 멈춘다.**\n'; exit 1; fi
  for t in $(trows); do
    TAR=$(fld "$t" 1); NEW=$(tar2tag "$TAR")
    if [ -z "$NEW" ]; then bad "$TAR 의 태그를 모른다 — tar2tag() 에 줄을 더하세요"; continue; fi
    T=$IMGD/$TAR
    if [ ! -s "$T" ]; then bad "$TAR 가 없다: $T"; continue; fi
    WCFG=$(tar -xOf "$T" manifest.json 2>/dev/null | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 | sed 's|blobs/sha256/|sha256:|')
    if "$DOCKER" image inspect "$NEW" --format '{{.Id}}' 2>/dev/null | grep -q "$WCFG"; then
      ok "$NEW 는 이미 있고 지문이 tar 와 같다 (건너뜀)"; continue
    fi
    "$DOCKER" load -i "$T" 2>&1 | sed 's/^/    /'
    FULL=$("$DOCKER" image inspect "$NEW" --format '{{.Id}}' 2>/dev/null)
    if [ "$FULL" = "$WCFG" ]; then ok "$NEW 가 올라왔고 지문이 tar 와 같다"
    elif [ -n "$FULL" ]; then bad "$NEW 지문이 다르다 — tar $WCFG / NAS $FULL"
    else bad "$NEW 가 안 올라왔다"; fi
  done
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
#  🔴 --go 는 **둘**(app-as·tools-as)을 고친다. --rollback 은 **app-as 하나만**
#     되돌린다 — 도구는 :7 그대로 둔다(39·41~45번과 같은 판단).
#  🔵 46번은 모드와 상관없이 하나였다(도구를 안 올리는 판이었다).
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
  TMP=$(mktemp) || exit 1
  awk -v n="$L" -v to="$TO" 'NR==n{sub(/[^ ]+$/, to); print; next} {print}' "$CF" > "$TMP"
  cp "$TMP" "$CF"; rm -f "$TMP"
  NOW=$(tag_at "$L")
  if [ "$NOW" = "$TO" ]; then ok "$SVC → $TO (${L}줄)"; else bad "$SVC 의 태그가 $NOW 다"; fi
done

# 🔴 도구는 --go 일 때만 고친다. --rollback 은 **손대지 않는다.**
if [ "$MODE" = go ]; then
  TL=$(img_line "$AS_TOOLS_SVC") || { bad "$AS_TOOLS_SVC — image: 줄을 못 찾았다"; }
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
# 🔴 **남의 image: 줄을 건드리면 안 된다.** --go 는 둘(app-as·tools-as),
#    --rollback 은 하나(app-as)만 달라져야 한다.
if [ "$MODE" = go ]; then WANT_DIFF=2; else WANT_DIFF=1; fi
[ "$((DIFFN / 2))" = "$WANT_DIFF" ] && ok "image: 줄이 꼭 ${WANT_DIFF}개만 달라졌다 (우리 것)" \
  || bad "image: 줄이 $((DIFFN / 2))개 달라졌다 — ${WANT_DIFF}개를 기대했다. 남의 것을 건드렸을 수 있다"
dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"

if [ "$FAIL" != 0 ]; then
  printf '\n🔴 어긋났다 — **사본으로 되돌린다.**\n'; cp "$BK" "$CF"
  say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $L0)"; exit 1
fi

# ── 6. app-as 만 다시 띄운다 ──────────────────────────────────────────
#  🔴 tools-as 는 profiles: [tools] 라 up -d 로 띄우지 않는다. 태그만 고쳐 두면
#     다음에 run --rm tools-as 로 부를 때 새 이미지를 쓴다.
printf '\n== 6. app-as 를 다시 띄운다\n'
printf '%s\n' "🔴 --no-deps 다 — app-as 하나만 갈아 끼운다. 나머지 아홉과 DB 둘은 안 건드린다."
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
  printf '%s' "$CODE" | grep -qE '200|30[127]' && ok "$CN 가 응답한다 ($CODE)" || bad "$CN 응답이 ${CODE:-없음}"
done

# 🔴 A/S DB — 마이그레이션 수가 **여전히** 그대로인가 (이 배포는 DB 를 안 건드린다)
MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
say "A/S 마이그레이션 ${MIG_AS0:-?} -> ${MIG_AS1:-?} (그대로여야 한다)"
[ "${MIG_AS1:-x}" = "$AS_KEEP" ] && ok "A/S 가 $AS_KEEP 그대로다 (DB 를 안 건드렸다)" \
  || bad "🔴 A/S 가 ${MIG_AS1:-?} 다 — $AS_KEEP 그대로여야 한다. 이 배포가 DB 를 건드렸다면 전제가 틀렸다"

# 🔴 도구 태그가 제대로 섰는지 + 이미지 안이 온전한지 다시 센다
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  # 🔵 --go 도 --rollback 도 도구 기대값은 **$TOOLS_NEW 로 같다** — 되돌려도
  #    도구는 :7 그대로 둔다(머리말 ⑦).
  [ "$TCUR" = "$TOOLS_NEW" ] && ok "$AS_TOOLS_SVC 가 $TOOLS_NEW 다" \
    || bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $TOOLS_NEW 를 기대했다"
  "$DOCKER" image inspect "$TCUR" >/dev/null 2>&1 && ok "$TCUR 이미지가 NAS 에 있다" \
    || bad "$TCUR 이미지가 NAS 에 없다 — 다음에 부를 때 못 쓴다"
fi
if [ "$MODE" = go ]; then tools_inside_check; fi
# 🔴 42번에서 넣은 검사는 **그대로 둔다** — 연락서 폴더가 줄만 있는 게 아니라
#    실제로 열리는지 센다. 🔵 **이번 판도 백필을 안 돌리므로 여기서 ✗ 가 나도 이
#    배포의 일은 끝난 것이다** — 다음 이식 때 막히지 않게 지금 재 두는 것이다.
if [ "$MODE" = go ]; then kyosan_folder_check; fi

# 🔴 **안 건드린 아홉이 그대로 도는지** 센다 — 「옆으로 안 샜다」는 증거다.
#    🔴 dss-inventory 가 이 안에 있다 — 그 상자가 멈추면 **[고장 부품] 그래프의
#       반출 몫이 통째로 빠지고 [사용부품] 칸도 막힌다**(머리말 ①-보조).
#       바로 아래에서 실제로 물어본다.
printf '\n    ── 안 건드린 아홉 (그대로여야 한다 — dss-inventory 도 포함)\n'
for c in $KEEP_BOXES; do
  s=$("$DOCKER" inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  i=$("$DOCKER" inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)
  printf '      %-18s %-10s %s\n' "$c" "${s:-없음}" "${i:-}"
  [ "$s" = running ] || bad "$c 가 안 돈다 — 안 건드렸어야 한다"
done

# 🔴 **「상자가 돈다」와 「물어보니 답한다」는 다른 말이다.** 바로 위는 앞의 것이고
#    이 줄이 뒤의 것이다 — 설정이 빠졌거나 토큰이 안 맞으면 상자는 멀쩡히 돌면서
#    반출 몫만 빠진다. 🔴 --go 에서는 ✗ 로 센다(사람이 실제로 막혀 있다).
if [ "$MODE" = go ]; then inventory_gateway_check strict; fi

printf '\n    ── DB 둘이 안 멈췄는가 (시작 시각이 그대로여야 한다)\n'
for c in $KEEP_DB; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$c" 2>/dev/null)
  b=$(printf '%s' "$DBSTART" | tr ' ' '\n' | sed -n "s/^$c=//p")
  printf '      %-14s %s\n' "$c" "${s:-없음}"
  [ "${s:-x}" = "${b:-y}" ] && ok "$c 가 안 멈췄다" || bad "🔴 $c 가 다시 떴다 (${b:-?} -> ${s:-?})"
done

printf '\n    ── 최근 로그 (12줄)\n'
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
  printf '%s\n' "🔵 **백필은 다시 돌리지 않는다.** 44~46번과 같다 — 까닭:"
  printf '%s\n' "   · 백필은 2026-10-29 새벽에 283건이 끝났다"
  printf '%s\n' "     (회차 e8c3c890-b1ba-42ec-a555-737609ad2e38 · 사용 부품 978줄이 품번으로 들어가 있다)."
  printf '%s\n' "   · 이번 판은 **화면 한 자리의 세는 자**를 바꾼다. 저장된 수량 칸을 **읽는 법**이"
  printf '%s\n' "     바뀔 뿐, **DB 에 들어간 값과 무관하다.**"
  printf '%s\n' "   🔵 **도구는 올렸지만 돌릴 까닭은 없다** — 올리는 것과 돌리는 것은 다른 일이다."
  printf '%s\n' "   🔵 백필이 다시 필요해지는 때는 **연락서를 읽는 규칙**이 바뀌는 판이다."
  printf '%s\n' "      그때 칠 명령은 /volume1/dss/setup/43-deploy.sh 꼬리말에 그대로 있다."
  printf '%s\n' ""
  printf '%s\n' "🔴 **마지막은 눈이다** — 이번 판은 볼 곳이 **한 자리**다:"
  printf '%s\n' ""
  printf '%s\n' "  **제품 모델 상세 → [A/S 이력] → [고장 부품]**"
  printf '%s\n' "   🔴 [고장 부품] 그래프가 **줄 수가 아니라 실제 수량**을 셉니다. 전에는 「불출 5개」인"
  printf '%s\n' "      줄도 1개로 셌습니다."
  printf '%s\n' "   ㄱ) **수가 크게 늡니다.** 2026-10-29 에 보신 모델은 「부품 4개」가 **18개**가 되어야"
  printf '%s\n' "       합니다(불출 5+5+3+5)."
  printf '%s\n' "   ㄴ) 🔴 **조각 차례가 바뀔 수 있습니다. 결함이 아닙니다.** 순위를 줄 수가 아니라"
  printf '%s\n' "       수량으로 매기므로 기타로 밀려나는 부품도 달라집니다."
  printf '%s\n' "   ㄷ) 🔵 설명 줄 맨 앞에 「개수는 부품 줄 수가 아니라 **실제 수량**입니다」가 생깁니다."
  printf '%s\n' "   ㄹ) 🔵 「**부품 기록이 있는 N건**」은 **건수 그대로**입니다 — 그 수는 안 바뀝니다."
  printf '%s\n' "   🔵 **수가 그대로면 이번 판이 안 먹은 것입니다.** 그때는 app-as 가 정말 dss-as:4.0"
  printf '%s\n' "      으로 도는지(위 7절) 먼저 보고, 맞다면 알려 주세요."
  printf '%s\n' ""
  printf '%s\n' "  🔵 **수량이 전부 1 인 모델은 보이는 것이 하나도 안 바뀝니다.**"
  printf '%s\n' "  🔵 **반출 몫을 세는 범위는 46번이 올린 그대로입니다** — 건수 상한이 없고 전체 5초"
  printf '%s\n' "     예산을 씁니다. 느린 날의 띠도 그대로입니다."
  printf '%s\n' "  🔵 **기대치 — 이름이 안 붙고 품번만 보이는 줄이 많습니다. 결함이 아닙니다.**"
  printf '%s\n' "     재고 관리 부품 **319줄 중 고객사 품명이 적힌 줄은 27개뿐**입니다(2026-10-29 실측)."
  printf '%s\n' "     🔵 재고 관리에서 고객사 품명을 채우면 A/S 는 아무것도 안 고쳐도 저절로 붙습니다."
  printf '%s\n' "  🔵 **[사용부품] 문지기는 45번이 올린 그대로입니다** — 이번 판이 안 건드렸습니다."
  printf '%s\n' "     그 문지기가 쓰는 수는 여전히 **줄 수**입니다(그래프만 수량으로 바뀌었습니다)."
  printf '%s\n' "  🔵 저장된 글자는 안 바뀝니다 — 이 배포는 DB 를 한 줄도 건드리지 않았습니다."
  printf '%s\n' "  🔵 연락서 이식 규칙(43번이 올린 판본 C 칸 차례 · 겹친 줄 수량)은 그대로입니다."
  printf '%s\n' ""
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (app-as 만 되돌린다. DB 를 안 건드렸으니"
  printf '%s\n' "               자료 손실이 없다. 🔵 도구는 $TOOLS_NEW 그대로 둔다)"
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
  printf '%s\n' "  🔵 ✗ 가 **재고 관리 통로** 하나뿐이라면 되돌리기 전에 설정을 먼저 보세요 —"
  printf '%s\n' "     INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN (env/as.env). 그 둘을 고치고"
  printf '%s\n' "     app-as 를 다시 띄우면 반출 몫이 다시 세어집니다. 🔴 되돌려도 같은 설정 문제는"
  printf '%s\n' "     남습니다 — 옛 판도 같은 통로를 씁니다."
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
