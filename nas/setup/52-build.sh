#!/bin/bash
# dss-deploy/nas/setup/52-build.sh — 마흔아홉째 배포 · 이미지 굽기 (2026-11-06)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · PowerShell 에서 Git Bash 를 부른다) ──────────
#     cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#     & "C:\Program Files\Git\bin\bash.exe" ./52-build.sh --check
#     & "C:\Program Files\Git\bin\bash.exe" ./52-build.sh --go
#
#   🔴 **bash.exe 만 치면 WSL 이 잡힌다**(2026-11-04 에 걸렸다). WSL 에서 돌면
#      도커도 양식도 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 내어 ✗ 가
#      셋 흩어져 난다. 단서는 로그의 뿌리 경로가 **/mnt/c/…** 인 것이다.
#      그래서 위처럼 **Git Bash 의 전체 경로를 큰따옴표로 묶어** 부른다.
#   🔴 **스크립트에 건네는 경로에는 역슬래시를 쓰지 않는다.** 역슬래시를 주면
#      bash 가 그것을 먹어 "C:Users희만Desktop…" 이 되어 No such file 이 난다.
#      위처럼 **폴더로 먼저 들어가서 ./52-build.sh** 로 부르면 그 함정이 없다.
#      🔵 49번까지 머리말에 역슬래시 예시가 박혀 있었고 베낄 때마다 따라다녔다.
#         48번이 51-build.sh 의 머리말만 고쳤고 **51-deploy.sh 에는 아직 남아
#         있다**(그 파일 6~9줄 · 1152줄 · 1333줄). 거기서 베껴 오지 마라.
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-49):
#     & "C:\Program Files\Git\bin\bash.exe" ./52-build.sh --go "/d/배포본/_images-49"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다.
#      이 파일을 쓴 쪽은 **한 번도 돌리지 않았다** — --check 도 안 돌렸다.
#
# ── 이번에 굽는 것 — **저장소 하나, 이미지 둘** ───────────────────────
#     ① A/S 앱   dss-as:4.4       → **dss-as:4.5**        커밋 12  스테이지 기본(runner)
#     ② A/S 도구 dss-as-tools:11  → **dss-as-tools:12**   커밋 12  🔴 --target tools
#
#   🔴 **PO 는 안 굽는다** — dss-po 의 HEAD 가 기준 SHA(9c1b2ef) 와 글자 그대로
#      같고 이후 커밋이 **0** 이다(2026-11-06 실측. 아래 2절이 다시 잰다).
#      48번과 같은 모양이다 — 「안 굽는 저장소」가 **아홉** 그대로.
#
#   🔵 **양식(.xlsx)은 한 장도 안 올린다.** 이번 범위에 .xlsx 변경이 0줄이고,
#      개발 PC 의 양식 열하나가 **48번이 적어 둔 md5 와 전부 같다**(8절이 다시
#      잰다). 그래서 이 파일에는 **양식을 복사하는 절이 없다.**
#      🔴 51-build.sh 는 그 절을 들고 있었는데 **TPL_UP_WANT 가 0 이라 빈 폴더를
#         만들고 「다섯이 다 복사됐다」를 찍고 통과했다**(_images-48/templates 가
#         지금도 비어 있다). 통과하는 ✓ 옆의 글이 틀려 있었던 것이라 걷어냈다.
#      🔴 **양식이 바뀌는 날 되살릴 곳**: 51-build.sh 의 8절과 꼬리말,
#         51-deploy.sh 의 --templates-prep(1056~1172줄) · --templates-apply(1174~1341줄).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 기준 SHA — **두 출처를 맞대어 확인했다** (2026-11-06)
# ══════════════════════════════════════════════════════════════════════
#   ㄱ) **A/S — 8a98e461.**
#        · dss-deploy/README.md 의 「🔴 기준 SHA … (2026-11-04 23:40 갱신)」 표:
#            | A/S 관리 | RF_Service_System | **4.4** | **8a98e461** |
#        · 48번 배포 기록(README 12~32줄)의 범위가 df16e6c3..**8a98e461** 이고
#          「커밋 30 · 파일 244」다 — 즉 48번이 실제로 구운 HEAD 가 8a98e461 이다.
#        · 🔵 지시서의 값과도 **맞았다.** 세 출처가 전부 같다.
#   ㄴ) **PO — 9c1b2ef.** 같은 표: | PO | dss-po | **0.9** | **9c1b2ef** |
#   🔴 아래 2절이 **merge-base --is-ancestor** 로 다시 잰다. 표가 낡았거나 가지가
#      갈렸으면 거기서 ✗ 가 난다 — 머리말의 글이 아니라 저장소가 답한다.
#
# ── 🔴 올릴 HEAD 가 **c6b2b271** 이다 (2026-11-06 늦게 하나 더 쌓였다) ──
#   처음 이 파일을 쓸 때의 HEAD 는 ea0dc8c9 였고 「커밋 12 · 파일 78」이었다.
#   그 뒤 **c6b2b271 「개발에서 만든 절차를 떠서 운영에 넣는 길」**이 쌓였고,
#   그 커밋이 **운영에서 도는 도구 둘**(procedures:export · procedures:import)을
#   더한다 — **도구 이미지 안에 있어야 운영에서 돌릴 수 있으므로** 이번 배포에
#   들어간다. 🔴 아래 숫자는 **전부 c6b2b271 기준으로 다시 쟀다.**
#
# ── 이번 범위의 커밋 — A/S **열셋** · PO **0** ───────────────────────
#   A/S  8a98e461..HEAD  (2026-11-06 실측: rev-list --count 가 13 · 파일 83)
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
#   PO   9c1b2ef..9c1b2ef → **0줄.** 구울 것이 없다.
#
#   🔵 이번 판의 일은 **셋**이다:
#      ① 엑셀 도형/셀 흐름도를 기술 작업 절차로 읽어 들이는 **개발 PC 도구**
#      ② 절차 화면 정리 — 코드 숨김 · 이름 검색 · 설비 유형 거르개 · 중심점 배치 ·
#         날짜 칸 연도 상한(화면 열넷)
#      ③ 🔴 **개발에서 만든 절차를 떠서 운영에 넣는 길**(c6b2b271) —
#         procedures:export(개발 PC · 읽기 전용) · procedures:import(**운영에서 돈다**)
#      → scripts/ 26개 · src/ 55개 · package.json 1개 = **82개**. 바깥은 진행현황.html 하나.
#
# ── 🔴 마이그레이션 — **0건이다.** 그래도 묶음과 절을 안 걷어낸다 ─────
#   2026-11-06 실측:
#     git -C RF_Service_System diff --name-only 8a98e461..HEAD -- drizzle/  → **0줄**
#     drizzle/*.sql **124장** · meta/_journal.json 의 idx **124개**
#     마지막 파일이 0123_slow_slapstick.sql 이고 **0124 는 없다**
#   🔴 운영 볼륨/기록도 **124** 다(48번이 121 → 124 로 올렸다). 이 배포로 **안 바뀐다.**
#
#   🔴 **그래도 묶음(as-migrations.tar.gz)을 만든다.** 까닭 둘:
#      · 운영 볼륨이 어떤 까닭으로 124 가 아니면(되돌렸거나 덜 풀렸거나) 그것이
#        고치는 길이다. 52-deploy.sh --migrate 가 **124 가 아닐 때만** 푼다.
#      · 🔴 그리고 **절이 살아 있어야 한다.** 39번 이후 40~47번이 전부 0건이었더니
#        마이그레이션 절이 **통째로 사라졌고**, 48번에서 다시 필요해졌을 때 39번까지
#        거슬러 가 가져와야 했다. 같은 일을 반복하지 않으려고 남긴다.
#      🔵 치르는 값은 2.4MB 짜리 묶음 하나다. **보내지 않아도 배포는 선다.**
#
#   🔴 **--migrate 모드도 52-deploy.sh 에 남겼다.** 이번 판에서는 그 모드가
#      「0건이어야 한다」를 잰다 — 새 .sql 이 0장인지 · 기록이 앞뒤로 **둘 다 124**
#      인지 · 48번이 올린 표 하나와 칸 둘과 인덱스 하나가 **아직 있는지**.
#      즉 이번 판에서도 **진짜로 무언가를 잰다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 A/S 도구(dss-as-tools)를 **왜 굽는가** — 잣대 셋 중 **둘**이 굽는다
# ══════════════════════════════════════════════════════════════════════
#   ㄱ) 🔴 **늘어난 npm 명령이 둘이다 — 41번의 잣대가 되살아났다.**
#      git diff 8a98e461..HEAD -- package.json → **15줄** (2026-11-06 실측)
#      scripts 항목 수 **35 → 37**. 늘어난 둘:
#            procedures:export   tsx scripts/export-procedure-bundle.ts
#            procedures:import   tsx scripts/import-procedure-bundle.ts
#      🔴 **41번의 잣대는 「명령이 늘었으면 그것만으로 굽는다」**이고, 이번 판은
#         거기에 걸린다. 🔴 그리고 41번의 **실패 모양**도 그대로 되살아난다 —
#         옛 도구 이미지(:11)로 procedures:import 를 부르면
#         **npm error Missing script** 다. 그 도구는 **운영에서 도는 것이 목적**이라
#         이미지에 없으면 절차 이관이 통째로 막힌다.
#      🔴 재는 것은 그대로 둘 다 잰다:
#         · **사라지지 않았는가** — 48번이 올린 셋(check:target-shipment-missing ·
#           check:due-date-inverted · check:requested-due-date-sync)이 기준판에도
#           1번, 지금 판에도 1번 나와야 한다(2026-11-06 실측: 셋 다 1 → 1).
#         · **늘어난 둘이 정말 있는가** — 기준판에 **0번**, 지금 판에 **1번**이어야
#           한다. 아래 NEW_NPM_SCRIPTS 가 그것을 센다.
#      🔵 반면 ②의 엑셀 읽개 둘(import-technical-task-procedures ·
#         link-technical-task-next-procedures)은 **여전히 npm 명령이 아니다** —
#         node 로 직접 부른다. 5절-ㄹ 이 그 둘을 「없는 것이 맞다」로 따로 센다.
#
#   ㄴ) 🔴 **도구의 import 닫힘 안에 바뀐 파일이 여섯이다.**
#      · 닫힘을 48·49번과 **같은 잣대**로 다시 쟀다(주석을 걷고, 상대경로 · '@/' ·
#        '@dss/core/schema' · '@dss/core/ui/*' · '@dss/ui' 를 따라가고, export … from
#        과 타입 전용 import 까지 따라간다).
#      · 🔴 **시작점이 스물둘에서 스물넷으로 늘었다** — c6b2b271 이 npm 명령 둘을
#        더해 그 둘이 **저절로 시작점에 들어왔기** 때문이다.
#        시작점 **스물넷** → 닫힘 **231개** · 못 푼 상대경로 **0개**.
#        🔵 48번은 같은 잣대로 223, ea0dc8c9 에서는 227 이었다.
#      · 그 231 과 이번에 바뀐 83 을 맞대면 **여섯이 겹친다**:
#              scripts/export-procedure-bundle.ts       ← **이번에 생긴 파일**
#              scripts/import-procedure-bundle.ts       ← **이번에 생긴 파일**
#              scripts/lib/procedure-template-bundle.ts ← **이번에 생긴 파일**
#              scripts/lib/dev-database-write-guard.ts  ← 🔴 **넓은 닫힘에서 좁은 쪽으로 옮겨 왔다**
#              src/lib/db/mutations/procedure-templates.ts
#              src/lib/domain/procedure-template-code.ts ← **이번에 생긴 파일**
#      🔴 **dev-database-write-guard.ts 의 자리가 바뀐 것을 그냥 넘기지 마라.**
#         export/import-procedure-bundle 이 거기서 describeDatabaseTarget ·
#         formatDatabaseTarget 를 들여오기 때문에, 등록된 명령에서 출발해도
#         닿게 됐다. 아래 WIDE_CALLED 에서 그만큼 **빼야** 셈이 안 겹친다.
#      🔴 **닫힘 안에 새로 생긴 파일이 넷이다.** 48번에는 하나도 없어 「있나」 검사가
#         약했는데, 이번에는 넷이 **기준판에 아예 없던 파일**이라 존재만으로
#         「새 scripts/·src/ 가 담겼다」가 선다.
#      · 🔴 **시작점을 하나로 두지 않았다.** ②의 엑셀 읽개 둘은 아직 npm 명령이
#        아니라 위 스물넷에 안 잡힌다. 그 둘까지 넣어 **스물여섯**으로 펴면
#        닫힘 **252개**가 되고, 겹치는 것이 **열일곱**이 된다(위 여섯 + 아래 열하나):
#              scripts/import-technical-task-procedures.ts
#              scripts/link-technical-task-next-procedures.ts
#              scripts/lib/xlsx/branch-classification.ts
#              scripts/lib/xlsx/cell-grid-flowchart.ts
#              scripts/lib/xlsx/drawing-geometry.ts
#              scripts/lib/xlsx/extract-cell-grid-task-graph.ts
#              scripts/lib/xlsx/extract-technical-task-graph.ts
#              scripts/lib/xlsx/technical-task-next-procedure-plan.ts
#              scripts/lib/xlsx/technical-task-sheet-plan.ts
#              scripts/lib/xlsx/technical-task-workbook.ts
#              src/lib/graph-editor-core/layout.ts
#      🔵 넓히든 좁히든 **답은 안 바뀐다 — 굽는다.** 아래 5절-ㅂ 과 5절-ㅅ 이 둘 다 센다.
#
#   ㄷ) 🔵 **39번에 넓혀 둔 잣대(「tools 스테이지가 담는 것 전부」)로도 굽는다.**
#      Dockerfile 의 tools 스테이지가 담는 것은 package.json · tsconfig.json ·
#      drizzle.config.ts · scripts/ · src/ · vendor/ 이고, 이번에 바뀐 **82개가 그
#      안**이다(package.json 1 · scripts/ 26 · src/ 55). 바깥은 **하나**뿐이다 —
#      진행현황.html. **82 > 0** 이라 굽는다.
#
#   🔵 **치르는 값**: tar 하나(224MB)를 더 굽고 올리는 것뿐이다. tools-as 는
#      profiles: [tools] 라 **다시 뜨지도 않는다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이번 판의 새 도구 **다섯**은 갈래가 셋이다 — 한 잣대로 재면 가짜 ✗ 가 난다
# ══════════════════════════════════════════════════════════════════════
#   🔴 처음 이 파일을 쓸 때는 「새 도구 둘은 전부 개발 PC 전용」이라 적고
#      checkDevelopmentWriteTarget 를 **글자로 세게** 해 두었다. c6b2b271 이
#      들어오면서 그 잣대가 **틀린 잣대**가 됐다 — import-procedure-bundle.ts 는
#      그 자물쇠를 **일부러 안 단다.** 그대로 두면 **가짜 ✗** 가 난다.
#      그래서 갈래를 셋으로 가르고 **갈래마다 다른 것을 잰다.**
#
#   갈래 ㄱ) 🔒 **개발 PC 전용 — 자물쇠가 있어야 한다**
#        scripts/import-technical-task-procedures.ts
#        scripts/link-technical-task-next-procedures.ts
#      둘 다 dev-database-write-guard.ts 의 **checkDevelopmentWriteTarget** 를
#      부른다. 그 게이트는 **접속한 호스트와 포트**로 개발인지 가르고(루프백 +
#      5442), 「개발이라고 확신할 수 없으면 멈춤」이다 — NAS 에서 부르면 **막힌다.**
#      🔴 그래서 **52-deploy.sh 꼬리말에 이 둘의 NAS 명령을 적지 않는다.**
#      잣대: checkDevelopmentWriteTarget **≥1** (2026-11-06 실측 1 · 1)
#
#   갈래 ㄴ) 🔴 **운영에서 도는 것이 목적 — 자물쇠가 없는 것이 맞다**
#        scripts/import-procedure-bundle.ts
#      그 파일 머리말이 스스로 적는다: 「여기엔 개발 DB 에서만 자물쇠가 **없다** —
#      일부러다. 이 도구는 운영에서 도는 것이 목적이라 같은 자물쇠를 달면 쓸 수가
#      없다. 대신 **다른 안전장치**를 건다.」 그 다른 안전장치를 **값으로 잰다**:
#        · 기본이 드라이런이고 APPLY=1 일 때만 쓴다  → process.env.APPLY **≥1**
#        · 쓰기는 한 트랜잭션 안에서 한다            → db.transaction   **≥1**
#        · 어느 DB 에 넣는지 맨 위에 찍는다          → formatDatabaseTarget **≥1**
#        · 실제로 쓰는 도구가 맞다                   → .insert( + .update( **≥1**
#        · 🔴 자물쇠는 **0 이어야 한다**             → checkDevelopmentWriteTarget **0**
#      2026-11-06 실측: APPLY 1 · transaction 1 · formatDatabaseTarget 2 ·
#      insert 4 · update 3 · delete 0 · 자물쇠 **0**.
#
#   갈래 ㄷ) 👀 **읽기 전용 — 쓰는 문장이 0 이어야 한다**
#        scripts/export-procedure-bundle.ts
#      개발 PC 에서 절차를 **떠 오기만** 한다. 자물쇠도 APPLY 도 필요 없다 —
#      애초에 안 쓰기 때문이다. 그것을 **값으로** 확인한다:
#        .insert( **0** · .update( **0** · .delete( **0** · transaction **0**
#      2026-11-06 실측: 넷 다 **0**.
#
#   🔵 5절-ㅌ 이 소스에서, 그리고 굽고 나서 **이미지 안에서** 이 셋을 각각 센다 —
#      짐작으로 적지 않는다. 🔴 **「자물쇠가 있으면 ✓」로 뭉뚱그리면 ㄴ 이 ✗ 가 되고,**
#      **「없어도 ✓」로 뭉뚱그리면 ㄱ 의 자물쇠가 빠진 날을 영영 못 잡는다.**
#
# ── 🔴 안 굽는 저장소 **아홉** (2026-11-06 실측 — 전부 HEAD 가 기준 SHA 그대로) ─
#     dss-auth        기준 52cbb19 · HEAD 52cbb19 · 이후 커밋 0
#     dss-inventory   기준 e0d84e8 · HEAD e0d84e8 · 이후 커밋 0
#     dss-board       기준 7d4f390 · HEAD 7d4f390 · 이후 커밋 0
#     dss-leave       기준 f568fc0 · HEAD f568fc0 · 이후 커밋 0
#     njlee(계측기)   기준 a234878 · HEAD a234878 · 이후 커밋 0
#     dss-improvements 기준 38fc0ef · HEAD 38fc0ef · 이후 커밋 0
#     dss-trouble     기준 c3da85d · HEAD c3da85d · 이후 커밋 0
#     dss-approvals   기준 8ab36fd · HEAD 8ab36fd · 이후 커밋 0
#     dss-po(PO)      기준 9c1b2ef · HEAD 9c1b2ef · 이후 커밋 0
#   🔵 기준 SHA 의 출처는 dss-deploy/README.md 의 기준 SHA 표다. 아홉 모두
#      **HEAD 가 그 SHA 와 글자 그대로 같다** — 「이후 커밋 0」이 삼켜진 0 이
#      아니라는 증거다. 🔴 48번의 표를 베끼기만 하지 않고 **아홉을 다시 쟀다.**
#
# ── 🔴 모드 둘 ────────────────────────────────────────────────────────
#   --check  재기만 한다. 아무것도 굽지 않고 아무 파일도 만들지 않는다.
#   --go     --check 를 **먼저 그대로 돌리고**, 하나라도 ✗ 나 ? 가 있으면
#            굽지 않고 멈춘다. 전부 ✓ 일 때만 둘을 굽고 tar 로 뽑는다.
#            그리고 **이미지 안을 센다**(겉이 아니라 결과). 묶음도 만든다.
#
# ── 🔴 ✓ / ✗ / ? 로 센다 ───────────────────────────────────────────────
#   ✓ 재서 맞았다   ✗ 재서 틀렸다   ? **못 쟀다**
#   🔴 ? 를 통과로 세지 않는다. 하나라도 있으면 **종료 코드 1** 이다.
#
# ── 🔴 tar 크기를 **두 번** 견준다 (48번 것을 그대로) ─────────────────
#   ① **지난 판 tar 와** 견준다. 적어 둔 값의 출처:
#        dss-as-4.4.tar      133611008  [실측] 2026-11-06 _images-48 에서 stat
#        dss-as-tools-11.tar 224566784  [실측] 2026-11-06 _images-48 에서 stat
#      🔵 51-deploy.sh 의 TARS 에 적힌 값과도 **글자 그대로 같았다**(두 출처 일치).
#      차이가 **25%** 를 넘으면 ✗ 다. 🔵 넘었다고 반드시 잘못된 것은 아니다 —
#      그때는 **사람이 보라는 뜻**이고, 까닭을 알면 그 숫자를 여기 고쳐 적으면 된다.
#   ② **그 이미지 자신과** 견준다. 🔴 여기가 함정이라 가지를 둘로 나눴다:
#      · containerd 저장소면 'docker image inspect {{.Size}}' 가 **압축된 내용
#        크기**를 주어 tar 와 거의 같다(90~110%).
#      · 고전 저장소면 그 값이 **펼친 크기**라 tar 는 그 **1/4쯤**이다(10~45%).
#      🔴 **둘 중 어느 쪽인지 미리 못 정한다.** 한 잣대로 재면 **가짜 ✗** 가 난다.
#   🔴 **tar 지문은 'docker image inspect' 의 .Id 와 맞대지 않는다.** 그것은
#      애초에 다른 값이다. 맞댈 상대는 **빌드 로그의 'exporting config sha256:'** 이다.
#      그걸로 재서 구운 아홉이 전부 ✗ 가 난 적이 있다.
#
# ── 🔴 이 환경의 함정 (36~51-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싸고, 저장소 자리를
#      이 파일의 자리에서 계산한다(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:/… 를 /c/… 로
#      바꾸고, docker save 는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#      🔴 이 파일의 tar/docker save 어디에도 드라이브 문자가 들어가지 않는다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를
#      막는다 — 아래 5절-ㄷ 이 그것도 잰다). 다만 메모리는 다르다.
#   ④ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다.** 한글을 argv 로 넘기면
#      깨지는 길이 열린다 — 아래 '새 판인가' 검사의 이름 여섯은 전부 ASCII 다.
#   ⑤ 🔵 **이번 판의 파일 목록에는 대괄호도 괄호도 없다**(2026-11-06 실측).
#      그래도 목록은 **따옴표로 감싼 여러 줄 변수**로만 다룬다 — 다음 판에 다시
#      생길 자리라 48번의 처방을 걷지 않는다.
#   ⑥ 🔵 **양식 경로는 .env.local 에서 꼴이 두 가지다** — 앞 다섯은 빗금,
#      뒤 여섯은 **역빗금**이다(2026-11-06 실측). 그래서 8절은 이름을 끊기 전에
#      **반드시 to_unix() 를 거친다.** 안 거치면 역빗금 경로의 「파일 이름」이
#      경로 전체가 되어 로그에 폴더가 찍힌다.
#
# ── 🔴 bash -n 이 못 잡는 둘 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안의 백틱은 명령 치환으로 읽힌다 → 이 파일에는 백틱이
#      **한 개도 없다**(주석에도 안 썼다). 쓴 뒤 grep 으로 세었다.
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
#    🔵 역빗금을 빗금으로 먼저 바꾸므로 **양식 경로 두 꼴을 다 받는다**(함정 ⑥).
to_unix() { # 1 경로
  local p=${1//\\//}
  case "$p" in
    [A-Za-z]:/*) p=/$(printf '%s' "${p%%:*}" | tr 'A-Z' 'a-z')${p#?:} ;;
  esac
  printf '%s' "$p"
}

tar_name() { printf '%s.tar' "$(printf '%s' "$1" | tr ':' '-')"; }

# tar 안 manifest.json 의 Config 지문 (39~51-build.sh 의 것을 글자 그대로)
tar_config_id() { # 1 tar
  tar -xOf "$1" manifest.json 2>/dev/null \
    | tr ',' '\n' | grep -o 'blobs/sha256/[0-9a-f]\{64\}' | head -1 \
    | sed 's|blobs/sha256/|sha256:|'
}

# 한 저장소의 drizzle/ 을 센다 → ".sql수 journal수"
count_drizzle() { # 1 저장소 폴더
  local s j
  s=$(ls -1 "$1/drizzle"/*.sql 2>/dev/null | wc -l | tr -d ' ')
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

# ══ 이번에 굽는 것 — 한자리에 모아 둔다 ═══════════════════════════════
#   열쇠|저장소 폴더|새 태그|기준 SHA|--target(없으면 -)|기대 drizzle 변경 수|기대 커밋 수|지난판 tar 바이트|지난판 tar 이름
#
#   🔴 여섯째 칸은 「기준 SHA 이후 drizzle/ 에서 **달라진 파일 수**」다.
#      🔴 **이번 판은 0 이다.** 0 이 아니면 전제가 깨진 것이라 ✗ 다 — 「0 이면
#      통과」가 아니라 **적어 둔 수와 똑같아야** 한다.
#   🔵 일곱째 칸(커밋 수)은 ✗ 로 세지 않고 ⚠️ 로만 센다 — 적어 둔 수와 어긋나면
#      표가 낡았다는 뜻이라 사람이 봐야 한다. A/S 열둘이다.
#   🔴 'astools' 는 **같은 저장소**(RF_Service_System)를 --target tools 로 한 번
#      더 굽는 줄이다. 저장소를 세는 자리에서는 이 줄을 건너뛴다 — 두 번 세면
#      ✗ 도 두 번 센다.
#   🔵 여덟째·아홉째 칸은 **지난 판 tar** 다. 출처는 머리말에 적었다.
#   🔴 **PO 줄이 없다.** 이번 판은 PO 를 안 굽는다.
SITES='
as|RF_Service_System|dss-as:4.5|8a98e461|-|0|13|133611008|dss-as-4.4.tar
astools|RF_Service_System|dss-as-tools:12|8a98e461|tools|0|13|224566784|dss-as-tools-11.tar
'
HOWMANY=2
TOOLS_TAG=dss-as-tools:12
# 🔵 되돌릴 판 — 52-deploy.sh --rollback 이 쓰는 그것이다.
AS_OLD_TAG=dss-as:4.4
TOOLS_OLD_TAG=dss-as-tools:11

# ── 🔴 기대값과 그 출처 ───────────────────────────────────────────────
#   [저장소] 2026-11-06 개발 PC 의 저장소에서 센 값
AS_SQL_WANT=124       # [저장소] RF_Service_System/drizzle/*.sql — **안 늘어야 한다**(0123 까지 그대로)
AS_LAST_MIG=0123      # [저장소] 마지막 마이그레이션. 0124 가 생기면 전제가 깨진 것이다
# 🔴 **다음 번호를 셈으로 만들지 않는다.** bash 의 $(( )) 는 0 으로 시작하는 수를
#    **8진수**로 읽어 0123+1 이 84 가 된다 — 오류 없이 엉뚱한 파일을 찾는다.
#    그래서 글자로 적어 두고, 아래에서 둘이 이어지는 번호인지 한 번 맞대어 본다.
AS_NEXT_MIG=0124
# 서브모듈 포인터 셋. 🔴 **A/S 와 PO 의 dss-core 가 서로 다르다 — 그것이 지금
#    상태다.** PO 의 8730c94 는 A/S 의 20bb394 의 **조상**이다. 🔴 **이 배포에서
#    맞추지 않는다.** 이번 범위에 vendor/ 변경이 한 줄도 없다.
#    🔵 세 값 모두 48번과 **같다**(2026-11-06 git submodule status 로 다시 쟀다).
AS_CORE_PIN=20bb394f5a8e33d8357a93c3c5c28b5145a9b1d4
PO_CORE_PIN=8730c9433b4388a038349ab9a11ec633659da782
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425        # 두 저장소가 같은 값이다
# 🔴 5절이 쓰는 기준 SHA. **SITES 표의 넷째 칸과 같은 값이어야 한다** — 41번에서는
#    이 값이 표와 따로 적혀 있어 한쪽만 고치면 조용히 어긋날 자리였다.
AS_BASE=8a98e461
PO_BASE=9c1b2ef
# 🔵 tools 스테이지가 담는 것 중 달라진 파일 수 — [실측] 2026-11-06 에 82.
TOOLS_CHANGED_WANT=82
# 🔵 저장소 전체에서 달라진 파일 수 — [실측] 83. 바깥 하나는 진행현황.html 이다.
ALL_CHANGED_WANT=83
# 🔵 좁은 닫힘(시작점 24 · 231개) 안에서 바뀐 파일 수 — [실측] 2026-11-06 에 6.
TOOLS_CALLED_WANT=6
# 🔵 넓은 닫힘(시작점 26 · 252개)에서 **더** 잡히는 파일 수 — [실측] 11.
#    🔴 ea0dc8c9 에서는 12 였다. dev-database-write-guard.ts 가 **좁은 쪽으로
#       옮겨 가** 하나 줄었다 — 두 수를 따로 고치지 않으면 셈이 겹친다.
WIDE_CALLED_WANT=11
# 🔴 **PO 는 이번에 0 이다.** 0 이 아니면 범위가 늘었다는 뜻이다.
PO_CHANGED_WANT=0
# 🔴 48번이 올린 npm 명령 셋. 재는 까닭은 **「사라지지 않았는가」**다(머리말 ㄱ).
#    기준판에도 1번, 지금 판에도 1번 나와야 한다.
KEEP_NPM_SCRIPTS="check:target-shipment-missing check:due-date-inverted check:requested-due-date-sync"
# 🔴 **c6b2b271 이 올린 npm 명령 둘.** 재는 까닭은 **「정말 들어왔는가」**다 —
#    기준판에 **0번** · 지금 판에 **1번**이어야 한다. 🔴 procedures:import 는
#    **운영에서 도는 도구**라, 이미지에 없으면 그날 절차 이관이 통째로 막힌다.
NEW_NPM_SCRIPTS="procedures:export procedures:import"
# 🔵 package.json 의 scripts 항목 수 — **기준판 35 · 지금 판 37** [실측] 2026-11-06.
#    🔴 둘을 한 변수로 두면 안 된다 — ea0dc8c9 까지는 둘 다 35 라 한 변수로 됐지만
#       c6b2b271 이 둘을 더해 **갈라졌다.** 한 변수로 두면 한쪽이 반드시 ✗ 가 난다.
NPM_SCRIPTS_WAS=35
NPM_SCRIPTS_NOW=37
# 🔵 package.json 의 diff 줄 수 — [실측] 15. 🔴 0 이 아니다(41번 잣대가 살아났다).
PKG_LINES_WANT=15

# ══ 🔴 양식 파일 — 이름|바이트|md5 ════════════════════════════════════
#   🔴 **이번 판에는 올릴 양식이 없다.** 열하나가 전부 48번이 적어 둔 값 그대로다
#      (2026-11-06 개발 PC 실측 — 바이트와 md5 가 글자 그대로 같았다).
#      이 절은 **「안 바뀌었다」를 확인하는 자리**이고 복사하는 절은 없다.
#   🔴 **경로는 여기 없다.** 이름과 바이트와 md5 뿐이다. 경로는 .env.local 의
#      같은 이름 줄에서 돌 때 읽는다 — 찍지 않는다.
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
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-49"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

printf '%s\n' "마흔아홉째 배포 · 이미지 굽기   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  저장소 뿌리: $DEV"
printf '%s\n' "  tar 둘을 둘 자리: $OUT"
printf '%s\n' "  굽는 것: dss-as:4.5 · dss-as-tools:12  (저장소 하나 · 이미지 둘)"
printf '%s\n' "  올릴 HEAD: c6b2b271  (기준 8a98e461 이후 커밋 13 · 파일 83)"
printf '%s\n' "  🔴 도구 이미지에 **운영에서 도는 명령**이 하나 들어간다 — procedures:import"
printf '%s\n' "  🔴 PO 는 **안 굽는다** — HEAD 가 기준 SHA 그대로다(2절이 다시 잰다)"
printf '%s\n' "  🔵 마이그레이션 **0건** — 기록도 볼륨도 124 그대로다(4절이 센다)"
printf '%s\n' "  🔵 양식도 **0장** — 열하나가 48번 값 그대로다(8절이 센다)"
printf '%s\n' "────────────────────────────────────────────────────────────"

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
printf '%s\n' "$SITES" | while IFS='|' read -r KEY REPO TAG BASE TGT WANTMIG WANTN PREVSZ PREVTAR; do
  [ -n "${KEY:-}" ] || continue
  [ "$KEY" = astools ] && continue   # 🔵 A/S 앱에서 이미 쟀다. 같은 저장소다.
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
      printf '%s\n' "         52-deploy.sh 꼬리말의 「볼 곳」과 5절의 파일 목록이다 — 사람이 보세요."
      git -C "$DIR" log --oneline "$BASE..HEAD" 2>/dev/null | head -14 | sed 's/^/      /'
    fi
    # 🔴 「0 이면 통과」가 아니다. 적어 둔 수와 **똑같아야** 한다.
    if [ "${m:-x}" = "$WANTMIG" ]; then
      printf '  ✓ %s drizzle/ 에서 달라진 파일 %s개 — 적어 둔 그대로 (마이그레이션 0건)\n' "$REPO" "$m"
    else
      printf '  ✗ %s drizzle/ 에서 달라진 파일 %s개 — **%s개를 기대했다**. 🔴 마이그레이션이 생겼다는 뜻이다. 멈추고 알릴 것\n' "$REPO" "${m:-?}" "$WANTMIG"
      git -C "$DIR" diff --name-only "$BASE..HEAD" -- drizzle/ 2>/dev/null | head -8 | sed 's/^/      /'
    fi
  else
    printf '  ✗ %s — 기준 SHA %s 가 조상이 아니다 (표가 낡았거나 가지가 갈렸다)\n' "$REPO" "$BASE"
  fi
  printf '    지금 HEAD: %s\n' "$(git -C "$DIR" log -1 --format='%h %s' 2>/dev/null)"
done

# 🔴 위 while 이 파이프라인 안이라 **셈이 안 넘어온다.** 다시 세어 FAIL 에 싣는다.
REPO_BAD=0
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}
  rest=${rest#*|}; BASE=${rest%%|*}; rest=${rest#*|}; TGT=${rest%%|*}
  rest=${rest#*|}; WANTMIG=${rest%%|*}
  [ "$KEY" = astools ] && continue   # 🔵 이미 셌다. 두 번 세면 ✗ 도 두 번이다.
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
if [ "$REPO_BAD" = "0" ]; then ok "저장소가 깨끗하고 drizzle 변경 수가 적어 둔 그대로(0)"
else bad "저장소 검사에서 어긋난 것 ${REPO_BAD}가지 — 위 ✗ 를 보세요"; doubt; fi

# 🔴 **안 굽는 아홉도 재 둔다** — 「이번 범위에 커밋이 없다」를 짐작으로 적지
#    않는다. HEAD 가 기준 SHA 와 글자 그대로 같아야 ✓ 다.
#    🔵 ✗ 가 나도 **이 배포를 막지 않는다**(⚠️ 로만 센다) — 그 저장소를 굽는 것은
#       이 판의 일이 아니고, 다음 판의 범위가 늘었다는 뜻이다.
printf '\n  ── 안 굽는 아홉 (HEAD 가 기준 SHA 그대로여야 한다)\n'
IDLE='
dss-auth|52cbb19
dss-inventory|e0d84e8
dss-board|7d4f390
dss-leave|f568fc0
njlee|a234878
dss-improvements|38fc0ef
dss-trouble|c3da85d
dss-approvals|8ab36fd
dss-po|9c1b2ef
'
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
# 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다 — 아홉을 다 봤는가.
if [ "$IDLE_SEEN" = "9" ]; then ok "안 굽는 아홉을 다 봤다 (표본이 비지 않았다)"
else bad "안 굽는 저장소를 ${IDLE_SEEN}개만 봤다 — 아홉을 기대했다. IDLE 표가 깨졌다"; fi

# ── 3. 🔴 서브모듈 — 빈 폴더면 빌드가 크게 실패한다 ───────────────────
printf '\n== 3. 서브모듈 (A/S 둘 — PO 둘은 ⚠️ 로만 본다)\n'
ASDIR="$DEV/RF_Service_System"
PODIR="$DEV/dss-po"
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
# 🔵 PO 는 **이번에 안 굽는다.** 그래서 핀이 어긋나도 이 배포를 막을 일이 아니다 —
#    ⚠️ 로만 센다. 다만 **재는 것은 뺀다는 뜻이 아니다**: 어긋나면 다음 판에서
#    PO 를 구울 때 그 코드가 따라 들어간다.
for pair in "vendor/dss-core $PO_CORE_PIN" "vendor/dss-ui $UI_PIN"; do
  set -- $pair
  got=$(pin_of "$PODIR" "$1")
  if [ "${got:-}" = "$2" ]; then say "🔵 PO $1 포인터 ${2:0:7} — 적어 둔 그대로 (이번에 안 굽는다)"
  else note "PO $1 포인터가 ${got:0:7} 다 — ${2:0:7} 을 적어 두었다. **이번 배포는 안 막는다**(PO 를 안 굽는다). 다음 판에서 보세요"; fi
done
# 🔵 **A/S 와 PO 의 dss-core 가 서로 다른 것은 지금 상태이고 이 배포가 고칠 일이
#    아니다.** 그 사실을 한 줄로 남겨 둔다 — 다음 사람이 「어긋났다」고 읽고
#    고치려 들지 않게.
say "🔵 A/S dss-core ${AS_CORE_PIN:0:7} · PO dss-core ${PO_CORE_PIN:0:7} — **서로 다른 것이 맞다.**"
say "   PO 쪽이 커밋 셋만큼 뒤에 있고(조상 관계), 이번 범위에 vendor/ 변경이 한 줄도 없다."
say "   🔴 여기서 맞추지 마세요 — 재어 보지도 않은 코드가 운영에 따라 들어간다."
# 🔴 빈 폴더가 아닌가 — 포인터는 맞는데 안이 비어 있는 경우가 실제로 있다.
#    🔵 경로에 한글이 있어 **한 줄짜리 함수**로 받는다(머리말 함정 ①).
check_not_empty() { # 1 서브모듈 폴더 2 사람이 부르는 이름
  if [ -s "$1/package.json" ]; then ok "$2 에 파일이 있다 (빈 폴더가 아니다)"
  else bad "$2 가 **빈 폴더**다 — git submodule update --init 을 먼저"; fi
}
check_not_empty "$ASDIR/vendor/dss-core" "A/S-core"
check_not_empty "$ASDIR/vendor/dss-ui"   "A/S-ui"

# ── 4. 🔴 drizzle/ — A/S 는 124 그대로 · PO 는 **없는 것이 맞다** ─────
printf '\n== 4. drizzle/ — A/S 는 %s 그대로 · PO 는 폴더가 없는 것이 맞다\n' "$AS_SQL_WANT"
AS_COUNTS=$(count_drizzle "$ASDIR"); AS_SQL=${AS_COUNTS%% *}; AS_JRN=${AS_COUNTS##* }
say "RF_Service_System/drizzle — .sql ${AS_SQL}장 · meta/_journal.json 의 idx ${AS_JRN}개"
if [ "${AS_SQL:-0}" = "$AS_SQL_WANT" ] && [ "${AS_JRN:-0}" = "$AS_SQL_WANT" ]; then
  ok "${AS_SQL_WANT}장이다 — 🔵 **48번이 올린 124 그대로다**(0121·0122·0123 까지). 이 배포는 DB 구조를 안 바꾼다"
else
  bad "drizzle 이 .sql ${AS_SQL:-?} · idx ${AS_JRN:-?} 다 — **${AS_SQL_WANT} 그대로여야 한다.** 전제가 깨졌으니 멈추고 알릴 것"
  doubt
fi
# 🔴 **「0 건이다」를 수가 아니라 파일 이름으로도 가른다.** 수만 세면 하나가 빠지고
#    하나가 생긴 경우를 못 본다. 0124 가 생겼으면 마이그레이션이 있는 판이다.
# 🔵 먼저 **두 상수가 이어지는 번호인지** 본다 — 한쪽만 고치면 조용히 어긋난다.
if [ "$(printf '%04d' "$((10#$AS_LAST_MIG + 1))")" = "$AS_NEXT_MIG" ]; then
  ok "AS_LAST_MIG($AS_LAST_MIG) 다음이 AS_NEXT_MIG($AS_NEXT_MIG) 다 (두 상수가 이어진다)"
else
  bad "🔴 AS_LAST_MIG($AS_LAST_MIG) 와 AS_NEXT_MIG($AS_NEXT_MIG) 가 안 이어진다 — 한쪽만 고쳤다"
fi
if ls -1 "$ASDIR/drizzle/${AS_NEXT_MIG}_"*.sql >/dev/null 2>&1; then
  bad "🔴 drizzle 에 $AS_NEXT_MIG 번 마이그레이션이 **생겼다** — 이 배포는 0건을 전제로 쓰였다. 멈추고 알릴 것"
  doubt
else
  ok "$AS_NEXT_MIG 번 마이그레이션이 없다 (마지막이 $AS_LAST_MIG — 마이그레이션 0건이 맞다)"
fi
# 🔴 **「삼켜진 0」을 여기서 가른다.** 2절은 git diff 로 0줄을 받았는데, 그 0 은
#    「안 바뀌었다」와 「그런 경로가 없다」를 구별하지 못한다.
if [ -d "$PODIR/drizzle" ]; then
  bad "🔴 dss-po 에 drizzle/ 폴더가 **생겼다** — 2026-09-28 부터 없던 것이다. 스키마의 주인이 바뀌었는지 사람이 보세요"
  ls -1 "$PODIR/drizzle" 2>/dev/null | head -8 | sed 's/^/      /'
  doubt
else
  ok "dss-po 에 drizzle/ 폴더가 없다 (없는 것이 맞다 — 스키마의 주인은 A/S 하나뿐이다)"
fi

# ══════════════════════════════════════════════════════════════════════
# ── 5. 🔴 도구 판정 · 담는 길 · 소스가 새 코드를 담고 있나 ────────────
# ══════════════════════════════════════════════════════════════════════
#  🔴 .dockerignore 나 Dockerfile 이 어긋나면 이미지는 멀쩡히 구워지고 **바뀐
#     코드만 조용히 빠진다.** 그래서 담는 길부터 센다.
printf '\n== 5. 도구 판정 · 담는 길 · 소스가 새 코드를 담고 있나\n'
# 🔴 기준 SHA 가 표와 이 절에 **두 벌로** 적혀 있다. 한쪽만 고치면 조용히 어긋나므로
#    먼저 맞대어 본다(41번에서 실제로 어긋날 뻔한 자리다).
AS_ROW_BASE=$(printf '%s\n' "$SITES" | tr -d ' ' | grep '^as|' | head -1 | cut -d'|' -f4)
if [ "${AS_ROW_BASE:-}" = "$AS_BASE" ]; then ok "A/S 기준 SHA 가 SITES 표와 이 절에서 같다 ($AS_BASE)"
else bad "A/S 기준 SHA 가 어긋난다 — 표는 ${AS_ROW_BASE:-못 읽음} · 이 절은 $AS_BASE"; fi
# 🔴 **PO 기준 SHA 는 SITES 에 없다**(이번엔 안 굽는다). IDLE 표의 PO 줄과 맞댄다.
PO_IDLE_BASE=$(printf '%s\n' "$IDLE" | tr -d ' ' | grep '^dss-po|' | head -1 | cut -d'|' -f2)
if [ "${PO_IDLE_BASE:-}" = "$PO_BASE" ]; then ok "PO 기준 SHA 가 IDLE 표와 이 절에서 같다 ($PO_BASE)"
else bad "PO 기준 SHA 가 어긋난다 — IDLE 표는 ${PO_IDLE_BASE:-못 읽음} · 이 절은 $PO_BASE"; fi
# 🔵 표의 'astools' 줄이 정말 --target tools 인지. 여기가 '-' 면 runner 가 구워지고,
#    그 이미지는 **오류 없이** 쓸모가 없다.
AS_TOOLS_ROW_TGT=$(printf '%s\n' "$SITES" | tr -d ' ' | grep '^astools|' | head -1 | cut -d'|' -f5)
AS_TOOLS_ROW_TAG=$(printf '%s\n' "$SITES" | tr -d ' ' | grep '^astools|' | head -1 | cut -d'|' -f3)
if [ "${AS_TOOLS_ROW_TGT:-}" = "tools" ] && [ "${AS_TOOLS_ROW_TAG:-}" = "$TOOLS_TAG" ]; then
  ok "SITES 표의 astools 줄이 $TOOLS_TAG · --target tools 다"
else
  bad "SITES 표의 astools 줄이 어긋난다 — 태그 ${AS_TOOLS_ROW_TAG:-없음} · target ${AS_TOOLS_ROW_TGT:-없음} (기대 $TOOLS_TAG · tools)"
fi

# ── ㄱ) A/S Dockerfile 의 tools 스테이지가 담는 길 ────────────────────
if grep -q '^FROM .* AS tools' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "A/S Dockerfile 에 tools 스테이지가 있다 (--target tools 가 선다)"
else
  bad "A/S Dockerfile 에 tools 스테이지가 없다 — --target tools 가 실패한다"
fi
if grep -qE '^COPY .*scripts \./scripts' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 scripts/ 를 담는다 (🔴 이번 판의 scripts/ 26개가 들어가는 유일한 길 — **procedures:import 가 운영에서 불린다**)"
else
  bad "🔴 A/S Dockerfile 이 scripts/ 를 안 담는다 — 이번 판의 도구가 통째로 빠지고 **절차 이관이 막힌다**"
fi
if grep -qE '^COPY .*package\.json' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 package.json·tsconfig.json 을 담는다 (npm 명령이 들어가는 길)"
else
  bad "A/S Dockerfile 이 package.json 을 안 담는다 — npm run 이 Missing script 로 죽는다"
fi
if grep -qE '^COPY .*src \./src' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 src/ 를 담는다 (닫힘 안에서 바뀐 여섯 중 둘이 들어가는 길)"
else
  bad "A/S Dockerfile 이 src/ 를 안 담는다 — 이번에 고친 코드가 통째로 빠진다"
fi
if grep -qE '^COPY .*vendor \./vendor' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "tools 스테이지가 vendor/ 를 담는다 (@dss/core 스키마를 찾는 길)"
else
  bad "A/S Dockerfile 이 vendor/ 를 안 담는다 — Cannot find module @dss/core/schema 가 난다"
fi

# ── ㄴ) 🔴 PO 에 tools 스테이지가 **없는 것이 맞다** ──────────────────
#   짐작으로 「없다」고 적지 않는다. 생기면 이 줄이 알려 준다.
if grep -q '^FROM .* AS tools' "$PODIR/Dockerfile" 2>/dev/null; then
  bad "🔴 dss-po/Dockerfile 에 tools 스테이지가 **생겼다** — 지금까지 없던 것이다. 도구를 굽고 올릴지 사람이 정해야 한다"
  doubt
else
  ok "dss-po 에 tools 스테이지가 없다 (없는 것이 맞다 — NAS 에서 돌릴 스크립트가 없다)"
fi
PO_STAGES=$(grep -c '^FROM ' "$PODIR/Dockerfile" 2>/dev/null | tr -d ' ')
say "dss-po/Dockerfile 의 FROM 줄 ${PO_STAGES:-못 쟀다}개 (기대 3 — deps · builder · runner)"
if [ "${PO_STAGES:-x}" = "3" ]; then ok "PO 의 스테이지가 셋이다 (deps · builder · runner)"
else note "PO 의 스테이지가 ${PO_STAGES:-?}개다 — 셋을 기대했다. 사람이 보세요"; fi

# ── ㄷ) .dockerignore — A/S ───────────────────────────────────────────
#   🔴 **.next 를 막는가**도 함께 센다. 막아야 개발 서버를 띄워 둔 채로 구울 수 있다.
check_dockerignore() { # 1 저장소 폴더 2 사람이 부르는 이름
  local DIG
  DIG="$1/.dockerignore"
  if [ ! -s "$DIG" ]; then
    bad "$2 에 .dockerignore 가 없거나 비었다 — .env 와 .git 이 이미지로 따라 들어간다"
    return
  fi
  if grep -qE '^scripts/?$' "$DIG" 2>/dev/null; then
    bad "$2 의 .dockerignore 가 scripts/ 를 막는다 — 빈 폴더가 구워진다"
  else
    ok "$2 의 .dockerignore 가 scripts/ 를 막지 않는다"
  fi
  if grep -qE '^\.next/?$' "$DIG" 2>/dev/null; then
    ok "$2 의 .dockerignore 가 .next 를 막는다 (개발 서버를 띄워 둔 채로 구워도 된다)"
  else
    bad "$2 의 .dockerignore 가 .next 를 안 막는다 — 호스트의 .next 가 빌드 문맥에 들어간다"
  fi
}
check_dockerignore "$ASDIR" "A/S"

# ── ㄹ) 🔴 **npm 명령 셋 — 「사라지지 않았는가」를 센다** ─────────────
printf '\n  ── 48번이 올린 npm 명령 셋이 **그대로 있는가**\n'
PKG_LINES=$(git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | wc -l | tr -d ' ')
say "package.json 의 diff ${PKG_LINES:-못 쟀다}줄 (적어 둔 값 $PKG_LINES_WANT — 🔴 이번 판은 명령이 **늘었다**)"
if [ "${PKG_LINES:-x}" = "$PKG_LINES_WANT" ]; then
  ok "package.json 이 $PKG_LINES_WANT 줄 바뀌었다 — 🔴 **41번의 잣대가 되살아났다**(명령이 늘면 그것만으로 굽는다)"
elif [ "${PKG_LINES:-x}" = "0" ]; then
  bad "🔴 package.json 이 **한 줄도 안 바뀌었다** — $PKG_LINES_WANT 줄을 기대했다. c6b2b271 이 범위에 안 들어왔다는 뜻이다. 멈추고 알릴 것"
  doubt
else
  note "package.json 이 ${PKG_LINES}줄 바뀌었다 — $PKG_LINES_WANT 줄을 적어 두었다. 아래 diff 를 사람이 보세요"
  git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | head -24 | sed 's/^/      /'
fi
# 🔴 **'네 칸 들여쓴 따옴표 줄'을 세면 틀린다** — dependencies·devDependencies 의
#    줄까지 섞여 51 이 나온다. scripts 블록 **안**만 세야 35 다.
count_scripts() { # stdin = package.json
  awk '
    /^  "scripts": \{/ { inb = 1; next }
    inb && /^  \}/      { inb = 0 }
    inb && /^    "/     { n++ }
    END { print n + 0 }
  '
}
NS_NOW=$(count_scripts < "$ASDIR/package.json" 2>/dev/null | tr -d ' ')
NS_WAS=$(git -C "$ASDIR" show "$AS_BASE:package.json" 2>/dev/null | count_scripts | tr -d ' ')
say "package.json 의 scripts 항목 — 기준 ${NS_WAS:-?} → 지금 ${NS_NOW:-?} (적어 둔 값 $NPM_SCRIPTS_WAS → $NPM_SCRIPTS_NOW)"
if [ "${NS_WAS:-x}" = "$NPM_SCRIPTS_WAS" ] && [ "${NS_NOW:-x}" = "$NPM_SCRIPTS_NOW" ]; then
  ok "명령이 $NPM_SCRIPTS_WAS 에서 $NPM_SCRIPTS_NOW 으로 **둘 늘었다** — 적어 둔 그대로(procedures:export · procedures:import)"
elif isnum "${NS_NOW:-}" && isnum "${NS_WAS:-}" && [ "${NS_NOW:-0}" -lt "${NS_WAS:-0}" ]; then
  bad "🔴 명령이 ${NS_WAS} 에서 ${NS_NOW} 로 **줄었다** — 사라진 명령을 그날 부르면 Missing script 다"
  doubt
else
  note "명령 수가 기준 ${NS_WAS:-?} → 지금 ${NS_NOW:-?} 다 — $NPM_SCRIPTS_WAS → $NPM_SCRIPTS_NOW 을 적어 두었다. 사람이 보세요"
fi
NPM_SEEN=0; NPM_NOW=0; NPM_WAS=0
for s in $KEEP_NPM_SCRIPTS; do
  NPM_SEEN=$((NPM_SEEN+1))
  now=$(grep -c "\"$s\"" "$ASDIR/package.json" 2>/dev/null | tr -d ' ')
  was=$(git -C "$ASDIR" show "$AS_BASE:package.json" 2>/dev/null | grep -c "\"$s\"" | tr -d ' ')
  printf '      %-34s 기준 %s → 지금 %s\n' "$s" "${was:-?}" "${now:-?}"
  if [ "${now:-0}" -ge 1 ] 2>/dev/null; then NPM_NOW=$((NPM_NOW+1)); fi
  if [ "${was:-0}" -ge 1 ] 2>/dev/null; then NPM_WAS=$((NPM_WAS+1)); fi
done
if [ "$NPM_SEEN" = "3" ]; then ok "명령 셋을 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
else bad "명령을 ${NPM_SEEN}개만 봤다 — 셋을 기대했다. 목록이 깨졌다"; fi
if [ "$NPM_NOW" = "3" ]; then
  ok "셋 다 **지금 판 package.json 에 있다** — 도구를 부르는 날 Missing script 가 안 난다"
else
  bad "지금 판에 있는 명령이 ${NPM_NOW}/3 개다 — **사라진 것이 있다.** 그 명령은 올려도 못 부른다"
  doubt
fi
if [ "$NPM_WAS" = "3" ]; then
  ok "셋 다 기준판에도 있었다 (48번이 올린 그대로)"
else
  note "기준판에 있던 명령이 ${NPM_WAS}/3 개다 — 셋을 기대했다. 사람이 보세요"
fi

# ── 🔴 **c6b2b271 이 올린 명령 둘이 정말 들어왔는가** ─────────────────
#   🔴 위 셋이 「사라지지 않았는가」라면, 여기는 **「정말 들어왔는가」**다.
#      기준판에 **0번** · 지금 판에 **1번**이어야 한다. 🔵 기준판 쪽을 함께 재는
#      까닭: 0 이 아니면 그 명령이 원래 있던 것이고, 그러면 「이번에 늘었다」는
#      머리말의 글이 틀린 것이다.
#   🔴 procedures:import 는 **운영에서 도는 도구**라, 이미지 안에 없으면 그날
#      절차 이관이 통째로 막힌다(41번의 실패 모양 그대로).
printf '\n  ── c6b2b271 이 올린 npm 명령 둘이 **정말 들어왔는가**\n'
NEW_SEEN=0; NEW_NOW=0; NEW_WAS=0
for s in $NEW_NPM_SCRIPTS; do
  NEW_SEEN=$((NEW_SEEN+1))
  now=$(grep -c "\"$s\"" "$ASDIR/package.json" 2>/dev/null | tr -d ' ')
  was=$(git -C "$ASDIR" show "$AS_BASE:package.json" 2>/dev/null | grep -c "\"$s\"" | tr -d ' ')
  printf '      %-22s 기준 %s → 지금 %s  (기대 0 → 1)\n' "$s" "${was:-?}" "${now:-?}"
  if [ "${now:-0}" -ge 1 ] 2>/dev/null; then NEW_NOW=$((NEW_NOW+1)); fi
  if [ "${was:-0}" -ge 1 ] 2>/dev/null; then NEW_WAS=$((NEW_WAS+1)); fi
done
if [ "$NEW_SEEN" = "2" ]; then ok "새 명령 둘을 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
else bad "새 명령을 ${NEW_SEEN}개만 봤다 — 둘을 기대했다. NEW_NPM_SCRIPTS 가 깨졌다"; fi
if [ "$NEW_NOW" = "2" ]; then
  ok "둘 다 **지금 판 package.json 에 있다** — 🔴 procedures:import 가 운영에서 불릴 명령이다"
else
  bad "🔴 지금 판에 있는 새 명령이 ${NEW_NOW}/2 개다 — **c6b2b271 이 범위에 안 들어왔다.** 멈추고 알릴 것"
  doubt
fi
if [ "$NEW_WAS" = "0" ]; then
  ok "둘 다 기준판에는 **없었다** (이번에 늘어난 것이 맞다 — 41번 잣대가 선다)"
else
  note "기준판에 이미 ${NEW_WAS}/2 개가 있었다 — 0개를 기대했다. 머리말의 「이번에 늘었다」가 틀렸을 수 있다. 사람이 보세요"
fi
# 🔵 그리고 그 둘이 가리키는 **파일**이 저장소에 있어야 담긴다.
for f in scripts/export-procedure-bundle.ts \
         scripts/import-procedure-bundle.ts \
         scripts/lib/procedure-template-bundle.ts; do
  if [ -s "$ASDIR/$f" ]; then ok "$f 가 저장소에 있다"
  else bad "🔴 $f 가 없다 — 명령은 있는데 담을 파일이 없다"; fi
done

# 🔵 그리고 48번이 올린 셋이 가리키는 **파일**이 저장소에 있어야 담긴다.
for f in scripts/check-target-shipment-missing.ts \
         scripts/check-due-date-inverted.ts \
         scripts/check-requested-due-date-sync.ts \
         scripts/lib/requested-due-date-sync-survey.ts; do
  if [ -s "$ASDIR/$f" ]; then ok "$f 가 저장소에 있다"
  else bad "$f 가 없다 — 명령은 있는데 담을 파일이 없다"; fi
done
# 🔴 **엑셀 읽개 둘에는 npm 명령이 없다** — 그것이 맞다. 「있어야 하는데 없다」로
#    읽히지 않게 여기서 못 박는다. 꼬리말도 node 로 적는다.
#    🔴 **바로 위에서 잰 procedures:* 둘과 헷갈리지 마라** — 그 둘은 명령이 **있어야**
#       하고, 이 둘은 **없어야** 한다. 이번 판에 네 파일이 한꺼번에 들어와 섞이기 쉽다.
for s in import-technical-task-procedures link-technical-task-next-procedures; do
  hit=$(grep -c "\"[a-z:-]*\": *\"[^\"]*scripts/$s\.ts" "$ASDIR/package.json" 2>/dev/null | tr -d ' ')
  if [ "${hit:-0}" = "0" ]; then
    ok "scripts/$s.ts 에 npm 명령이 **없다** (맞다 — node 로 직접 부른다)"
  else
    note "scripts/$s.ts 에 npm 명령이 ${hit}개 생겼다 — 없던 것이다. 꼬리말의 부르는 법을 사람이 다시 보세요"
  fi
done

# ── ㅁ) 🔵 백필 도구 파일 셋 — 43~51번이 넣은 줄, **그대로 둔다** ─────
#   이번 판에서 한 글자도 안 바뀌었지만, 여전히 이미지에 있어야 백필을 부를 수 있다.
for f in scripts/backfill-kyosan-used-parts.ts \
         scripts/lib/kyosan-used-parts-backfill.ts \
         scripts/lib/kyosan-used-parts-backfill-plan.ts; do
  if [ -s "$ASDIR/$f" ]; then ok "$f 가 저장소에 있다"
  else bad "$f 가 없다 — 담을 것이 없다"; fi
done

# ── ㅂ) 🔴 **좁은 닫힘(227개) 안의 이름난 파일 스물여덟 중 몇이 바뀌었나** ─
#   🔴 이것이 **이번 판의 첫째 까닭**이다 — 1개 이상이면 「부르니까 굽는다」다.
#   🔵 앞의 스물여섯은 **48번이 적어 둔 그 스물여섯**이고 한 줄도 안 뺐다.
#      2026-11-06 에 닫힘(231개)으로 다시 재어 **스물여섯이 다 들어 있음**을 확인했다.
#   🔵 뒤의 여섯이 **이번 판에 닫힘 안에서 바뀐 것**이다:
#      src/lib/db/mutations/procedure-templates.ts (절차 코드를 서버가 짓는다)
#      src/lib/domain/procedure-template-code.ts   (🔴 이번에 **생긴** 파일)
#      scripts/export-procedure-bundle.ts          (🔴 이번에 **생긴** 파일)
#      scripts/import-procedure-bundle.ts          (🔴 이번에 **생긴** 파일 · 운영에서 돈다)
#      scripts/lib/procedure-template-bundle.ts    (🔴 이번에 **생긴** 파일)
#      scripts/lib/dev-database-write-guard.ts     (🔴 **넓은 닫힘에서 옮겨 왔다**)
#   🔴 dev-database-write-guard.ts 가 좁은 쪽으로 옮겨 온 것을 놓치면 아래
#      WIDE_CALLED 와 **겹쳐서 두 번 세게 된다.** 그래서 거기서는 뺐다.
#   🔵 「그 파일이 아직 저장소에 있나」 가드를 **그대로 둔다** — 이름이 바뀌었는데
#      0 이 나와 「안 바뀌었다」로 조용히 지나가는 길을 막는다.
printf '\n  ── 좁은 닫힘(231개) 안의 이름난 파일 서른둘\n'
TOOLS_CALLED="scripts/backfill-kyosan-used-parts.ts scripts/lib/kyosan-used-parts-backfill.ts scripts/lib/kyosan-used-parts-backfill-plan.ts src/lib/db/connection.ts src/lib/auth/repair-case-used-parts-authorization.ts src/lib/db/queries/repair-case-used-parts.ts src/lib/domain/inventory-gateway.ts src/lib/server/inventory-gateway.ts src/lib/kyosan/parts-detail-sheet.ts src/lib/kyosan/report-preview.ts scripts/check-due-date-inverted.ts scripts/check-requested-due-date-sync.ts scripts/check-target-shipment-missing.ts scripts/lib/requested-due-date-sync-survey.ts src/lib/db/queries/repair-case-due-date-inverted-notifications.ts src/lib/db/queries/repair-case-target-shipment-notifications.ts src/lib/domain/due-date-inversion.ts src/lib/domain/notifications.ts src/lib/domain/requested-due-date-link.ts src/lib/domain/shipment-finished.ts src/lib/validation/repair-case-update-input.ts src/lib/domain/quote-approval-rules.ts src/lib/domain/quote-new-link.ts src/lib/domain/service-report-body-wrap.ts src/lib/xlsx/service-report-template.ts src/lib/xlsx/sheet-rows.ts src/lib/db/mutations/procedure-templates.ts src/lib/domain/procedure-template-code.ts scripts/export-procedure-bundle.ts scripts/import-procedure-bundle.ts scripts/lib/procedure-template-bundle.ts scripts/lib/dev-database-write-guard.ts"
CALLED_HIT=0
CALLED_SEEN=0
for f in $TOOLS_CALLED; do
  CALLED_SEEN=$((CALLED_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 저장소에 없다 — **도구 닫힘 목록이 낡았다.** 닫힘을 다시 재세요"
    continue
  fi
  if git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- "$f" 2>/dev/null | grep -q .; then
    CALLED_HIT=$((CALLED_HIT+1)); say "🔴 바뀌었다 · 도구가 부른다 — $f"
  fi
done
say "닫힘의 이름난 파일 ${CALLED_SEEN}개를 봤고, 그중 바뀐 것 ${CALLED_HIT}개 (적어 둔 수는 $TOOLS_CALLED_WANT)"
if [ "$CALLED_SEEN" = "32" ]; then
  ok "닫힘 목록 서른둘을 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
else
  bad "닫힘 목록을 ${CALLED_SEEN}개만 봤다 — 서른둘을 기대했다. 목록이 깨졌다"
fi
if isnum "${CALLED_HIT:-}" && [ "${CALLED_HIT:-0}" -ge 1 ]; then
  ok "도구가 부르는 파일이 ${CALLED_HIT}개 바뀌었다 — **부르니까 굽는다**(머리말 ㄴ)"
else
  # 🔴 늘어난 npm 명령이 **없어서** 여기가 0 이면 「굽는다」를 주는 잣대가
  #    ㄷ 하나만 남는다. 그래서 ⚠️ 가 아니라 ✗ 다.
  bad "🔴 도구가 부르는 길에서 바뀐 파일이 0개다 — ${TOOLS_CALLED_WANT}개를 적어 두었다. **머리말 ㄴ 의 실측이 낡았다.** 멈추고 알릴 것"
  doubt
fi
if [ "${CALLED_HIT:-x}" != "$TOOLS_CALLED_WANT" ]; then
  note "바뀐 것이 ${CALLED_HIT:-?}개다 — 적어 둔 것은 ${TOOLS_CALLED_WANT}개다. 커밋이 더 쌓였는지 사람이 보세요"
fi
# 🔵 **닫힘 안에 새로 생긴 파일이 넷이다** — 48번에는 하나도 없던 신호다. 이것이
#    있으면 이미지 안에서 「그 파일이 있나」만 봐도 **새 판이 담겼다**가 선다.
#    🔴 기준판에 **있으면** 머리말의 「이번에 생긴 파일」이 틀린 것이다.
printf '\n  ── 닫힘 안에 **이번에 생긴** 파일 넷 (기준판에는 없어야 한다)\n'
BORN_SEEN=0; BORN_OK=0
for f in src/lib/domain/procedure-template-code.ts \
         scripts/export-procedure-bundle.ts \
         scripts/import-procedure-bundle.ts \
         scripts/lib/procedure-template-bundle.ts; do
  BORN_SEEN=$((BORN_SEEN+1))
  if git -C "$ASDIR" cat-file -e "$AS_BASE:$f" 2>/dev/null; then
    note "$f 가 **기준판에도 있다** — 이번에 생긴 파일로 적어 두었다. 둘 중 하나가 틀렸으니 사람이 보세요"
  else
    BORN_OK=$((BORN_OK+1)); say "🔵 기준판에 없던 파일 — $f"
  fi
done
if [ "$BORN_SEEN" = "4" ] && [ "$BORN_OK" = "4" ]; then
  ok "넷 다 기준판에 **없던 파일**이다 (이미지 안에서 존재만 봐도 새 판이다)"
else
  note "본 것 ${BORN_SEEN} · 기준판에 없던 것 ${BORN_OK} 다 — 넷/넷을 기대했다. 사람이 보세요"
fi

# ── ㅅ) 🔴 **넓은 닫힘에서 더 잡히는 열둘** — 이번 판 도구의 알맹이 ───
#   🔵 이 열둘은 package.json 에 명령이 없는 도구 둘을 시작점에 더해야 보인다.
#      닫힘이 227 → 252 로 늘고 겹침이 2 → 14 가 된다(2026-11-06 실측).
#   🔴 **시작점을 하나로 두지 않는다**는 48번의 교훈을 이 절이 지킨다.
printf '\n  ── 넓은 닫힘(252개)에서 **더** 잡히는 열하나 — 엑셀 읽개의 알맹이\n'
# 🔴 **dev-database-write-guard.ts 가 여기 없다.** c6b2b271 부터 좁은 닫힘으로
#    옮겨 갔다(export/import-procedure-bundle 이 들여온다). 여기 남겨 두면
#    같은 파일을 두 번 세어 「열둘」이라는 틀린 수가 나온다.
WIDE_CALLED="scripts/import-technical-task-procedures.ts scripts/link-technical-task-next-procedures.ts scripts/lib/xlsx/branch-classification.ts scripts/lib/xlsx/cell-grid-flowchart.ts scripts/lib/xlsx/drawing-geometry.ts scripts/lib/xlsx/extract-cell-grid-task-graph.ts scripts/lib/xlsx/extract-technical-task-graph.ts scripts/lib/xlsx/technical-task-next-procedure-plan.ts scripts/lib/xlsx/technical-task-sheet-plan.ts scripts/lib/xlsx/technical-task-workbook.ts src/lib/graph-editor-core/layout.ts"
WIDE_SEEN=0; WIDE_HIT=0
for f in $WIDE_CALLED; do
  WIDE_SEEN=$((WIDE_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 저장소에 없다 — 넓은 닫힘 목록이 낡았다"
    continue
  fi
  if git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- "$f" 2>/dev/null | grep -q .; then
    WIDE_HIT=$((WIDE_HIT+1))
  fi
done
say "열하나 중 본 것 ${WIDE_SEEN}개 · 바뀐 것 ${WIDE_HIT}개 (적어 둔 수는 $WIDE_CALLED_WANT)"
if [ "$WIDE_SEEN" = "$WIDE_CALLED_WANT" ] && [ "$WIDE_HIT" = "$WIDE_CALLED_WANT" ]; then
  ok "넓은 닫힘의 열하나가 **전부 이번에 바뀌었다** (굽는 둘째 증거)"
else
  note "본 것 ${WIDE_SEEN} · 바뀐 것 ${WIDE_HIT} 다 — ${WIDE_CALLED_WANT}/${WIDE_CALLED_WANT} 을 기대했다. **굽는 판정은 안 흔들린다.** 사람이 보세요"
fi

# ── ㅇ) 🔴 **「담기는 것」으로도 센다** (39번에 넓혀 둔 잣대) ──────────
TOOLS_PATHS="scripts/ src/ package.json drizzle.config.ts tsconfig.json vendor/"
TOOLS_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | wc -l | tr -d ' ')
printf '\n  ── 담기는 것으로 세기\n'
say "tools 스테이지가 담는 것 중 달라진 파일 ${TOOLS_CHANGED:-못 쟀다}개"
if isnum "${TOOLS_CHANGED:-}" && [ "${TOOLS_CHANGED:-0}" -ge 1 ]; then
  ok "도구를 구울 둘째 까닭이 있다 — 기준 $AS_BASE 이후 달라진 파일 ${TOOLS_CHANGED}개 (적어 둔 수는 $TOOLS_CHANGED_WANT)"
else
  bad "달라진 파일이 ${TOOLS_CHANGED:-못 쟀다}개다 — 전제가 깨졌으니 멈추고 알릴 것"
  doubt
fi
if [ "${TOOLS_CHANGED:-x}" != "$TOOLS_CHANGED_WANT" ]; then
  note "달라진 파일이 ${TOOLS_CHANGED:-?}개다 — 적어 둔 것은 ${TOOLS_CHANGED_WANT}개다. 커밋이 더 쌓였는지 사람이 보세요"
fi
# 🔵 **저장소 전체에서 달라진 수**와도 맞대어 본다. 이번 판은 **바깥이 하나**다 —
#    진행현황.html. 0 을 기대하면 가짜 ⚠️ 가 난다.
ALL_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
say "저장소 전체에서 달라진 파일 ${ALL_CHANGED:-못 쟀다}개 (적어 둔 수는 $ALL_CHANGED_WANT)"
if [ "${ALL_CHANGED:-x}" = "$ALL_CHANGED_WANT" ] && [ "${TOOLS_CHANGED:-x}" = "$TOOLS_CHANGED_WANT" ]; then
  ok "바깥이 $((ALL_CHANGED_WANT - TOOLS_CHANGED_WANT))개다 — 적어 둔 그대로 (진행현황.html 하나)"
else
  note "바깥이 $((${ALL_CHANGED:-0} - ${TOOLS_CHANGED:-0}))개다 — 하나를 적어 두었다. 굽는 판정은 안 흔들린다. 무엇인지 아래에 찍는다"
fi
printf '%s\n' "      ── tools 바깥에서 바뀐 것"
git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" 2>/dev/null | grep -vE '^(scripts/|src/|package\.json$|drizzle\.config\.ts$|tsconfig\.json$|vendor/)' | head -10 | sed 's/^/      /'

# ── ㅈ) 🔵 **달라진 파일 목록이 적어 둔 여든둘과 글자 그대로 같은가** ─
#   🔵 ⚠️ 로만 센다. 굽기로 했으므로 목록이 달라져도 굽는 판정은 안 흔들린다.
#      흔들리는 것은 **머리말의 실측과 52-deploy.sh 꼬리말의 「볼 곳」**이다.
#      🔴 **재기는 그대로 잰다 — 뺀 검사가 아니다.**
TOOLS_CHANGED_LIST='
package.json
scripts/export-procedure-bundle.ts
scripts/import-procedure-bundle.ts
scripts/import-technical-task-procedures.ts
scripts/lib/dev-database-write-guard.test.ts
scripts/lib/dev-database-write-guard.ts
scripts/lib/procedure-template-bundle.test.ts
scripts/lib/procedure-template-bundle.ts
scripts/lib/xlsx/branch-classification.test.ts
scripts/lib/xlsx/branch-classification.ts
scripts/lib/xlsx/cell-grid-flowchart.test.ts
scripts/lib/xlsx/cell-grid-flowchart.ts
scripts/lib/xlsx/drawing-geometry.test.ts
scripts/lib/xlsx/drawing-geometry.ts
scripts/lib/xlsx/extract-cell-grid-task-graph.test.ts
scripts/lib/xlsx/extract-cell-grid-task-graph.ts
scripts/lib/xlsx/extract-technical-task-graph.test.ts
scripts/lib/xlsx/extract-technical-task-graph.ts
scripts/lib/xlsx/technical-task-next-procedure-plan.test.ts
scripts/lib/xlsx/technical-task-next-procedure-plan.ts
scripts/lib/xlsx/technical-task-replace-path.test.ts
scripts/lib/xlsx/technical-task-sheet-plan.test.ts
scripts/lib/xlsx/technical-task-sheet-plan.ts
scripts/lib/xlsx/technical-task-workbook.ts
scripts/link-technical-task-next-procedures.ts
scripts/test-lists/components.txt
scripts/test-lists/unit.txt
src/components/common/date-input-limits.ts
src/components/common/date-input-max-screens.test.ts
src/components/common/shift-range-selection-screens.test.ts
src/components/customer-portal/CustomerPortalScreen.tsx
src/components/domestic-orders/DomesticOrderDueDatesCell.tsx
src/components/domestic-orders/DomesticOrderEditForm.tsx
src/components/domestic-orders/DomesticOrderTextCell.tsx
src/components/procedures/ProcedureFlowGraph.tsx
src/components/procedures/ProcedureTemplateDetailScreen.tsx
src/components/procedures/ProcedureTemplateEditorScreen.tsx
src/components/procedures/ProcedureTemplateListScreen.tsx
src/components/procedures/ProcedureVersionList.tsx
src/components/procedures/TechnicalProcedureListFilterBar.tsx
src/components/procedures/TechnicalProcedureSeriesList.tsx
src/components/procedures/TechnicalProcedureTemplateListScreen.tsx
src/components/procedures/editor/CreateNodePanel.tsx
src/components/procedures/editor/CreateTechnicalTemplateForm.tsx
src/components/procedures/editor/NodePropertyPanel.tsx
src/components/procedures/execution/ProcedureExecutionScreen.tsx
src/components/procedures/execution/past-executions-section.test.tsx
src/components/procedures/execution/procedure-start-picker-panel.test.tsx
src/components/procedures/node-chip-shape-id-hidden.test.ts
src/components/procedures/procedure-code-hidden-screens.test.ts
src/components/procedures/procedure-editor-center-point-placement.test.ts
src/components/procedures/procedure-series-and-version-list.test.tsx
src/components/procedures/technical-procedure-list-filter-ui.test.tsx
src/components/procedures/validation/ValidationIssueListScreen.tsx
src/components/quotes/QuoteEditForm.tsx
src/components/repair-cases/detail/DomesticOrderDatesSection.tsx
src/components/repair-cases/detail/edit/IntakeInfoEditForm.tsx
src/components/repair-cases/new/IntakeFormInner.tsx
src/components/repair-cases/report/service-report/ServiceReportField.tsx
src/components/repair-cases/report/service-report/ServiceReportHeaderFields.tsx
src/components/repair-cases/work-history/ActivityFilterPanel.tsx
src/components/users/ApprovalRouteDelegationSection.tsx
src/components/users/DelegationSection.tsx
src/lib/db/mutations/procedure-templates.ts
src/lib/domain/procedure-auto-layout.test.ts
src/lib/domain/procedure-auto-layout.ts
src/lib/domain/procedure-editor-save-state.test.ts
src/lib/domain/procedure-editor-save-state.ts
src/lib/domain/procedure-execution-past-runs.test.ts
src/lib/domain/procedure-execution-past-runs.ts
src/lib/domain/procedure-field-added-steps.test.ts
src/lib/domain/procedure-start-picker.test.ts
src/lib/domain/procedure-start-picker.ts
src/lib/domain/procedure-template-code.test.ts
src/lib/domain/procedure-template-code.ts
src/lib/domain/procedure-template-title.test.ts
src/lib/domain/procedure-template-title.ts
src/lib/domain/technical-procedure-list-filter.test.ts
src/lib/domain/technical-procedure-list-filter.ts
src/lib/graph-editor-core/layout.test.ts
src/lib/graph-editor-core/layout.ts
src/lib/server/actions/procedure-templates.ts
'
WANT_LIST=$(printf '%s\n' "$TOOLS_CHANGED_LIST" | grep -v '^[[:space:]]*$' | sort)
GOT_LIST=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $TOOLS_PATHS 2>/dev/null | sort)
if [ -z "${GOT_LIST:-}" ]; then
  unk "A/S 에서 달라진 파일 목록" "git diff 가 아무것도 안 돌려줬다 — 기준 SHA 를 보세요"
elif [ "$GOT_LIST" = "$WANT_LIST" ]; then
  ok "A/S 에서 달라진 파일이 **적어 둔 여든둘 그대로**다 — 2026-11-06 의 닫힘 실측이 이 커밋들을 덮는다"
else
  note "달라진 파일이 적어 둔 여든둘과 **다르다** — 굽는 것은 그대로 굽되, 머리말의 닫힘 실측과 52-deploy.sh 꼬리말을 사람이 다시 보세요"
  say "── 적어 둔 것에 없는데 바뀐 것"
  printf '%s\n' "$GOT_LIST" | grep -vxF -f <(printf '%s\n' "$WANT_LIST") | head -12 | sed 's/^/      /'
  say "── 적어 두었는데 안 바뀐 것"
  printf '%s\n' "$WANT_LIST" | grep -vxF -f <(printf '%s\n' "$GOT_LIST") | head -12 | sed 's/^/      /'
fi

# ── ㅊ) 🔴 PO 쪽에서 달라진 파일 — **0 이어야 한다** ─────────────────
PO_CHANGED=$(git -C "$PODIR" diff --name-only "$PO_BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
say "PO 에서 달라진 파일 ${PO_CHANGED:-못 쟀다}개 (적어 둔 수는 $PO_CHANGED_WANT — 안 굽는다)"
if [ "${PO_CHANGED:-x}" = "$PO_CHANGED_WANT" ]; then
  ok "PO 에서 달라진 파일이 0개다 — **안 굽는 것이 맞다**"
else
  bad "🔴 PO 에서 달라진 파일이 ${PO_CHANGED:-못 쟀다}개다 — 0개를 기대했다. **PO 도 구워야 할 수 있다.** 멈추고 알릴 것"
  git -C "$PODIR" diff --name-only "$PO_BASE..HEAD" 2>/dev/null | head -20 | sed 's/^/      /'
  doubt
fi

# ── ㅋ) 🔴 **PO 가 수리 건 표에 쓴다 — 안 굽어도 재는 것을 뺀다는 뜻이 아니다** ─
#   🔵 49번이 올린 dss-po:0.9 가 **운영에서 지금도** repair_cases 를 UPDATE 한다.
#      52-deploy.sh 의 권한 검사가 왜 거기 있는지 다음 사람이 알게 하려고 못 박는다.
printf '\n  ── PO 가 repair_cases 를 UPDATE 하는가 (49번이 올린 그 기능 · 안 굽어도 잰다)\n'
PO_MUT="src/lib/db/mutations/domestic-orders.ts"
PO_UPD_NOW=$(grep -c 'update(repairCases)' "$PODIR/$PO_MUT" 2>/dev/null | tr -d ' ')
say "$PO_MUT — update(repairCases) 지금 ${PO_UPD_NOW:-?}번 (기대 1)"
if [ "${PO_UPD_NOW:-0}" -ge 1 ] 2>/dev/null; then
  ok "PO 가 repair_cases 에 **쓴다** — 🔴 52-deploy.sh --check 가 NAS 에서 그 권한을 값으로 묻는다"
else
  bad "🔴 PO 가 repair_cases 를 안 쓴다 — 49번이 올린 기능이 사라졌다. 멈추고 알릴 것"
  doubt
fi

# ── ㅌ) 🔴 **새 도구 다섯의 갈래 셋을 갈래마다 다른 것으로 잰다** ─────
#   🔴 **한 잣대로 재면 가짜 ✗ 가 난다.** 머리말의 갈래 ㄱ·ㄴ·ㄷ 을 그대로 센다:
#      ㄱ 개발 전용 둘 → 자물쇠가 **있어야**   ㄴ 운영용 하나 → 자물쇠가 **없어야**
#      ㄷ 읽기 전용 하나 → 쓰는 문장이 **0 이어야**
#   🔴 ea0dc8c9 까지는 이 절이 「자물쇠가 있으면 ✓」 하나뿐이었다. c6b2b271 이
#      들어오면서 그 잣대로는 import-procedure-bundle 이 **가짜 ✗** 가 된다.
printf '\n  ── 새 도구 다섯 — 갈래 셋을 갈래마다 다르게 잰다\n'
TOOLGRADE_SEEN=0; TOOLGRADE_OK=0

# ── 갈래 ㄱ) 🔒 개발 PC 전용 — checkDevelopmentWriteTarget 가 **있어야** 한다
printf '      ── 갈래 ㄱ) 개발 PC 전용 (자물쇠가 있어야 한다)\n'
for f in scripts/import-technical-task-procedures.ts scripts/link-technical-task-next-procedures.ts; do
  TOOLGRADE_SEEN=$((TOOLGRADE_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 저장소에 없다 — 도구 목록이 낡았다"; continue
  fi
  n=$(grep -c 'checkDevelopmentWriteTarget' "$ASDIR/$f" 2>/dev/null | tr -d ' ')
  printf '        %-50s 자물쇠 %s번 (기대 1 이상)\n' "$f" "${n:-0}"
  if [ "${n:-0}" -ge 1 ] 2>/dev/null; then TOOLGRADE_OK=$((TOOLGRADE_OK+1))
  else bad "🔴 $f 에 **자물쇠가 없다** — 그 도구가 운영 DB 에 쓸 수 있게 된다"; doubt; fi
done

# ── 갈래 ㄴ) 🔴 운영에서 도는 하나 — 자물쇠가 **없는 것이 맞다**
#   🔵 대신 다른 안전장치 넷을 값으로 센다. 「없으니 ✓」로 뭉뚱그리지 않는다.
printf '      ── 갈래 ㄴ) 운영에서 도는 하나 (자물쇠가 없는 것이 맞다 · 대신 넷을 잰다)\n'
PRODTOOL=scripts/import-procedure-bundle.ts
TOOLGRADE_SEEN=$((TOOLGRADE_SEEN+1))
if [ ! -s "$ASDIR/$PRODTOOL" ]; then
  bad "🔴 $PRODTOOL 가 저장소에 없다 — 운영에서 부를 도구가 통째로 없다"
  doubt
else
  g=$(grep -c 'checkDevelopmentWriteTarget' "$ASDIR/$PRODTOOL" 2>/dev/null | tr -d ' ')
  a=$(grep -c 'process.env.APPLY' "$ASDIR/$PRODTOOL" 2>/dev/null | tr -d ' ')
  t=$(grep -c 'db.transaction' "$ASDIR/$PRODTOOL" 2>/dev/null | tr -d ' ')
  d=$(grep -c 'formatDatabaseTarget' "$ASDIR/$PRODTOOL" 2>/dev/null | tr -d ' ')
  w=$(grep -cE '\.insert\(|\.update\(' "$ASDIR/$PRODTOOL" 2>/dev/null | tr -d ' ')
  printf '        자물쇠 %s (기대 0) · APPLY %s (기대 1+) · 트랜잭션 %s (기대 1+) · 대상 DB 찍기 %s (기대 1+) · 쓰는 문장 %s (기대 1+)\n' \
    "${g:-?}" "${a:-?}" "${t:-?}" "${d:-?}" "${w:-?}"
  PFAIL=0
  [ "${g:-1}" = "0" ] || { bad "🔴 $PRODTOOL 에 개발 전용 자물쇠가 ${g}번 있다 — **운영에서 못 쓰게 된다.** 일부러 뺀 것이 맞는지 보세요"; PFAIL=1; doubt; }
  [ "${a:-0}" -ge 1 ] 2>/dev/null || { bad "🔴 APPLY 게이트가 없다 — **부르는 순간 바로 쓴다.** 드라이런이 사라졌다"; PFAIL=1; doubt; }
  [ "${t:-0}" -ge 1 ] 2>/dev/null || { bad "🔴 트랜잭션이 없다 — 중간에 죽으면 **반만 들어간 상태**가 남는다"; PFAIL=1; doubt; }
  [ "${d:-0}" -ge 1 ] 2>/dev/null || { bad "🔴 어느 DB 에 넣는지 안 찍는다 — 자물쇠가 없는 자리에서 사람이 가릴 길이 사라진다"; PFAIL=1; doubt; }
  [ "${w:-0}" -ge 1 ] 2>/dev/null || { bad "🔴 쓰는 문장이 하나도 없다 — 넣는 도구가 아니다. 목록이 낡았다"; PFAIL=1; }
  if [ "$PFAIL" = "0" ]; then
    TOOLGRADE_OK=$((TOOLGRADE_OK+1))
    ok "$PRODTOOL 는 **운영에서 도는 것이 맞다** (자물쇠 0 · APPLY · 트랜잭션 · 대상 DB 찍기 · 쓰는 문장)"
  fi
fi

# ── 갈래 ㄷ) 👀 읽기 전용 하나 — 쓰는 문장이 **0 이어야** 한다
printf '      ── 갈래 ㄷ) 읽기 전용 하나 (쓰는 문장이 0 이어야 한다)\n'
RDTOOL=scripts/export-procedure-bundle.ts
TOOLGRADE_SEEN=$((TOOLGRADE_SEEN+1))
if [ ! -s "$ASDIR/$RDTOOL" ]; then
  bad "🔴 $RDTOOL 가 저장소에 없다 — 도구 목록이 낡았다"
else
  w=$(grep -cE '\.insert\(|\.update\(|\.delete\(' "$ASDIR/$RDTOOL" 2>/dev/null | tr -d ' ')
  t=$(grep -c 'transaction' "$ASDIR/$RDTOOL" 2>/dev/null | tr -d ' ')
  printf '        쓰는 문장 %s (기대 0) · 트랜잭션 %s (기대 0)\n' "${w:-?}" "${t:-?}"
  if [ "${w:-1}" = "0" ] && [ "${t:-1}" = "0" ]; then
    TOOLGRADE_OK=$((TOOLGRADE_OK+1))
    ok "$RDTOOL 는 **읽기만 한다** (쓰는 문장 0 · 트랜잭션 0 — 자물쇠가 없어도 되는 까닭이다)"
  else
    bad "🔴 $RDTOOL 에 쓰는 문장이 ${w}번 · 트랜잭션이 ${t}번 있다 — **읽기 전용이 아니다.** 자물쇠 없이 운영에 붙으면 쓴다"
    doubt
  fi
fi

# 🔴 표본이 비어서 공짜로 통과하는 꼴을 막는다 — 넷을 다 봤는가.
if [ "$TOOLGRADE_SEEN" = "4" ] && [ "$TOOLGRADE_OK" = "4" ]; then
  ok "갈래 셋(파일 넷)을 다 보고 다 맞았다 (표본이 비지 않았다)"
else
  bad "갈래 검사에서 본 것 ${TOOLGRADE_SEEN} · 맞은 것 ${TOOLGRADE_OK} 다 — 4/4 를 기대했다"
fi
if [ -s "$ASDIR/scripts/lib/dev-database-write-guard.ts" ]; then
  ok "scripts/lib/dev-database-write-guard.ts 가 저장소에 있다 (갈래 ㄱ 의 자물쇠 본체)"
else
  bad "🔴 자물쇠 본체가 없다 — 갈래 ㄱ 의 둘이 부르는 것이 없다"
fi

# ── 6. 태그가 이미 있나 ───────────────────────────────────────────────
printf '\n== 6. 새 태그가 이미 있나\n'
printf '%s\n' "🔵 있으면 **덮어쓴다** — 같은 커밋이면 같은 것이 나오므로 해롭지 않다."
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  rest=${row#*|}; rest=${rest#*|}; TAG=${rest%%|*}
  if docker image inspect "$TAG" >/dev/null 2>&1; then note "$TAG — 이미 있다 (덮어쓴다)"
  else ok "$TAG — 아직 없다"; fi
done
# 🔵 **되돌릴 판이 개발 PC 에 남아 있는가** — NAS 쪽은 52-deploy.sh 가 따로 센다.
#    🔴 51-build.sh 는 여기에 4.2·9 를 적고 있었다 — **두 판 전 것**이라 되돌리기와
#       상관없는 값이었다. 이번 판이 되돌릴 상대는 $AS_OLD_TAG · $TOOLS_OLD_TAG 다.
for t in "$AS_OLD_TAG" "$TOOLS_OLD_TAG"; do
  if docker image inspect "$t" >/dev/null 2>&1; then say "🔵 옛 판 $t 가 개발 PC 에 있다"
  else say "🔵 옛 판 $t 가 개발 PC 에 없다 — NAS 쪽에 있으면 되돌리기는 된다(거기서 센다)"; fi
done
say "🔵 PO 는 dss-po:0.9 그대로 둔다 — 이번에 안 굽고 안 갈아 끼운다."

# ── 7. tar 둘을 둘 자리 ──────────────────────────────────────────────
printf '\n== 7. tar 둘을 둘 자리\n'
if [ "$MODE" = "--go" ]; then
  mkdir -p "$OUT" 2>/dev/null
fi
if [ -d "$OUT" ]; then ok "$OUT 가 있다"
elif [ "$MODE" = "--check" ]; then note "$OUT 가 아직 없다 (--go 가 만든다)"
else bad "$OUT 를 못 만들었다"; fi
# 🔵 tar 둘이면 360MB 쯤이고 묶음이 2.4MB 다. 두 배를 여유로 본다.
FREEKB=$(df -Pk "$(dirname "$OUT")" 2>/dev/null | awk 'NR==2 {print $4}')
if isnum "${FREEKB:-}"; then
  say "남은 자리 $((FREEKB / 1024))MB (tar 둘이 약 360MB · 묶음이 약 2.4MB 다)"
  if [ "$FREEKB" -ge 1000000 ]; then ok "자리가 넉넉하다"
  else bad "자리가 모자란다 — 1GB 이상을 권한다"; fi
else
  unk "남은 자리" "df 가 수를 안 돌려줬다"
fi

# ══════════════════════════════════════════════════════════════════════
# ── 8. 🔴 양식 파일 — **이번 판에는 올릴 것이 없다. 그래도 잰다** ─────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **경로를 찍지 않는다.** 이름 · 바이트 · md5 · 수정 시각만 찍는다.
#   🔴 **md5 가 적어 둔 것과 다르면 ✗ 가 아니라 ⚠️ 다** — 사용자가 양식을 고쳤다는
#      뜻이고, 그러면 **올릴 것이 생긴다.** 굽기를 막을 일은 아니다(이미지와 양식은
#      다른 물건이다). 🔵 되살릴 절의 자리는 머리말에 적어 두었다.
#   🔴 **파일이 아예 없으면 ✗ 다** — 운영이 못 읽는 양식을 그대로 두는 셈이다.
printf '\n== 8. 양식 파일 — 열하나가 48번 값 그대로인가 (경로는 안 찍는다)\n'
# 🔵 .env.local 에서 그 이름의 값을 읽는다. **같은 이름이 두 줄이면 아래가 이긴다**
#    — 그래서 tail -1 이다. 값은 안 찍는다.
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
# 🔴 양식 이름에는 **공백과 한글**이 둘 다 있다. 그래서 while/IFS 로 한 줄씩 읽는다
#    — for 고리에 날것으로 넣으면 공백에서 쪼개진다.
#    🔵 while 이 파이프라인 안이면 셈이 안 넘어오므로 **여기 문자열**로 먹인다.
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
  # 🔴 to_unix() 를 이미 거쳤으므로 빗금으로 끊으면 **파일 이름만** 남는다(함정 ⑥).
  GOTNAME=${P##*/}
  SZ=$(stat -c %s "$P" 2>/dev/null)
  M5=$(md5sum "$P" 2>/dev/null | awk '{print $1}')
  MT=$(date -r "$P" '+%Y-%m-%d %H:%M' 2>/dev/null)
  printf '      %-42s %-26s %8s바이트  %s  %s\n' "$VAR" "$GOTNAME" "${SZ:-?}" "${MT:-?}" "${M5:-?}"
  if [ "$GOTNAME" != "$NAME" ]; then
    printf '  ⚠️ %s 가 가리키는 파일 이름이 %s 다 — **%s 를 적어 두었다.** 이름이 바뀌었으면 운영 쪽도 함께 봐야 한다\n' "$VAR" "$GOTNAME" "$NAME"
  fi
  if [ "${M5:-x}" = "$WM5" ] && [ "${SZ:-x}" = "$WSZ" ]; then
    TPL_SAME=$((TPL_SAME+1))
  else
    TPL_DIFF=$((TPL_DIFF+1))
    printf '  ⚠️ %s 가 적어 둔 것과 **다르다** (적어 둔 %s바이트 %s)\n' "$NAME" "$WSZ" "$WM5"
    printf '%s\n' "      🔵 양식을 고치셨다는 뜻입니다. **굽기는 막지 않습니다.**"
    printf '%s\n' "      🔴 그러면 **올릴 양식이 생긴 것**입니다 — 이 파일에는 양식을 복사하는"
    printf '%s\n' "         절이 없습니다(이번 판은 0장이라 걷어냈습니다). 되살릴 곳:"
    printf '%s\n' "         51-build.sh 의 8절·꼬리말 · 51-deploy.sh 의 --templates-prep·--templates-apply."
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
  ok "양식 $TPL_COUNT_WANT 개가 **전부 48번이 적어 둔 md5 그대로**다 — 🔵 **올릴 양식이 0장이다**"
else
  note "양식 ${TPL_DIFF}개가 적어 둔 것과 다르다 — 위를 보세요. **굽기는 막지 않는다**"
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
BUILT=0; BFAIL=0; TARTABLE=""
for row in $(printf '%s\n' "$SITES" | tr -d ' ' | grep -v '^$'); do
  KEY=${row%%|*}; rest=${row#*|}; REPO=${rest%%|*}; rest=${rest#*|}; TAG=${rest%%|*}
  rest=${rest#*|}; BASE=${rest%%|*}; rest=${rest#*|}; TGT=${rest%%|*}
  rest=${rest#*|}; WANTMIG=${rest%%|*}; rest=${rest#*|}; WANTN=${rest%%|*}
  rest=${rest#*|}; PREVSZ=${rest%%|*}; rest=${rest#*|}; PREVTAR=${rest%%|*}
  DIR="$DEV/$REPO"
  FILE=$(tar_name "$TAG")
  LOG="$OUT/build-$(printf '%s' "$TAG" | tr ':' '-').log"
  printf '\n── %s  (%s)\n' "$TAG" "$REPO"

  # 🔴 도구 이미지만 --target tools 다. 안 주면 **runner 가 구워지고** 그 안에는
  #    scripts/ 도 package.json 도 없어 오류 없이 쓸모없는 이미지가 된다
  #    (RF_Service_System/Dockerfile 은 tools 스테이지를 runner **앞에** 둔다 —
  #    --target 없이 구우면 마지막 스테이지인 runner 가 기본값이 된다).
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

  # ── 🔴 크기 견주기 ① — **지난 판 tar 와** ──────────────────────────
  p=$(pct_diff "$sz" "$PREVSZ")
  if [ -n "${p:-}" ]; then
    printf '    지난 판 %s %s바이트 → 이번 %s바이트 (차이 %s%%)\n' "$PREVTAR" "$PREVSZ" "$sz" "$p"
    if [ "$p" -le 25 ]; then printf '  ✓ 지난 판 tar 와 크기가 비슷하다 (차이 %s%% · 25%% 이내)\n' "$p"
    else
      printf '  ✗ 지난 판 tar 와 크기가 %s%% 다르다 — 25%% 이내를 기대했다\n' "$p"
      printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 라이브러리가 늘거나 베이스 이미지가"
      printf '%s\n' "         바뀌면 정상적으로도 이만큼 뜁니다. 까닭을 알면 SITES 표의 여덟째 칸을"
      printf '%s\n' "         고쳐 적으면 됩니다. 모르겠으면 **멈추고 알리세요.**"
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
      printf '%s\n' "      🔵 **검사 자신을 먼저 의심하세요.** 이 비는 docker 의 저장소 방식이"
      printf '%s\n' "         정합니다(머리말의 크기 견주기 ②)."
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

  # ── 🔴 앱 이미지 — **runner 가 맞는가**를 한 줄로 센다 ─────────────
  #   🔵 앱은 NAS 에서 실제로 떠서 응답하는지가 더 센 신호다. 그래서 **한 가지만**
  #      본다: standalone 의 /app/server.js 가 있는가. 없으면 그 이미지는
  #      'node server.js' 를 모르고 **뜨는 순간 죽는다.**
  if [ "$KEY" = as ]; then
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/server.js && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '    /app/server.js: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ runner 스테이지가 맞다 (node server.js 를 안다)\n'
    else printf '  ✗ /app/server.js 가 없다 — **runner 가 아닌 것을 구웠다.** 올리지 마세요\n'; BFAIL=$((BFAIL+1)); fi
  fi

  # 🔴 A/S 도구는 구운 뒤 **이미지 안**을 다시 센다 — 겉이 아니라 결과.
  if [ "$KEY" = "astools" ]; then
    printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TAG"
    IMGFAIL=0
    # ① runner 가 아니라 tools 인가 — runner 에는 /app/package.json 이 없다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '      /app/package.json: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tools 스테이지가 맞다\n'
    else printf '  ✗ /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다\n'; IMGFAIL=1; fi
    # ② 🔴 **npm 명령 다섯이 이미지 안 package.json 에 있는가.** 41번이 데인 자리다.
    #    🔵 앞의 셋은 48번이 올린 것(사라지면 안 된다), 뒤의 둘은 c6b2b271 이 올린
    #       것(들어와야 한다). **한 번의 docker run 으로 둘 다 본다** — 명령마다
    #       상자를 띄우면 느려지기만 한다.
    #    🔴 procedures-import 는 **운영에서 불릴 명령**이다. 여기서 빠지면 그날
    #       절차 이관이 Missing script 로 통째로 막힌다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync procedures:export procedures:import; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "5" ]; then printf '  ✓ npm 명령 다섯이 이미지 안에 있다 (48번의 셋 + c6b2b271 의 둘 — Missing script 가 안 난다)\n'
    else printf '  ✗ 명령이 %s/5 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다.** 그날 npm error Missing script 가 난다\n' "${got:-0}"; IMGFAIL=1; fi
    # ③ 🔴 **좁은 닫힘에서 바뀐 여섯이 담겼는가.**
    #    🔵 그중 넷은 **기준판에 없던 파일**이라 존재만으로 「새 판이 담겼다」가
    #       선다 — 48번에는 그런 신호가 하나도 없었다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/src/lib/db/mutations/procedure-templates.ts /app/src/lib/domain/procedure-template-code.ts /app/scripts/export-procedure-bundle.ts /app/scripts/import-procedure-bundle.ts /app/scripts/lib/procedure-template-bundle.ts /app/scripts/lib/dev-database-write-guard.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "6" ]; then printf '  ✓ 좁은 닫힘에서 바뀐 여섯이 다 들어갔다 (그중 넷은 이번에 생긴 파일이다)\n'
    else printf '  ✗ 여섯 중 %s개만 들어갔다 — src/ 나 scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
    # ④ 🔴 **이번 판 엑셀 읽개 열하나가 담겼는가.** 전부 기준판에 **없던 파일**이다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/import-technical-task-procedures.ts /app/scripts/link-technical-task-next-procedures.ts /app/scripts/lib/dev-database-write-guard.ts /app/scripts/lib/xlsx/cell-grid-flowchart.ts /app/scripts/lib/xlsx/drawing-geometry.ts /app/scripts/lib/xlsx/extract-cell-grid-task-graph.ts /app/scripts/lib/xlsx/extract-technical-task-graph.ts /app/scripts/lib/xlsx/technical-task-next-procedure-plan.ts /app/scripts/lib/xlsx/technical-task-sheet-plan.ts /app/scripts/lib/xlsx/technical-task-workbook.ts /app/scripts/lib/xlsx/branch-classification.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "11" ]; then printf '  ✓ 이번 판 엑셀 읽개 열하나가 다 들어갔다 (전부 기준판에 없던 파일이다)\n'
    else printf '  ✗ 열하나 중 %s개만 들어갔다 — **옛 scripts/ 가 담겼다.** 캐시를 의심하세요\n' "${got:-0}"; IMGFAIL=1; fi
    # ⑤ 🔵 48번이 올린 도구 넷 — **빼지 않는다.** 이번 판에 안 바뀌었지만 있어야 부른다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "4" ]; then printf '  ✓ 48번이 올린 도구 넷이 다 들어갔다\n'
    else printf '  ✗ 도구 파일이 %s/4 개다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
    # ⑥ 백필 도구 파일 셋 — 43~51번 것 그대로. **빼지 않는다.**
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts /app/scripts/lib/kyosan-used-parts-backfill-plan.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "3" ]; then printf '  ✓ 백필 도구 파일 셋이 다 들어갔다\n'
    else printf '  ✗ 백필 도구 파일이 %s/3 개다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
    # ⑦ 🔴 **그 src/ 와 scripts/ 가 '이번 판' 인가 — 글자로 센다.** ③④ 는 「있나」만 본다.
    #    🔵 여섯 다 기준 8a98e461 판에는 **0번** 나오고 지금 판에는 나온다
    #       (2026-11-06 git show 로 파일마다 세어 확인: 0→3 · 0→2 · 0→14 · 0→1 · 0→1 · 0→1).
    #    🔴 이름은 전부 **ASCII** 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for pair in "generateProcedureTemplateCode /app/src/lib/db/mutations/procedure-templates.ts" "GENERATED_PROCEDURE_CODE_PREFIX /app/src/lib/domain/procedure-template-code.ts" "sameRowBranch /app/src/lib/graph-editor-core/layout.ts" "buildProceduresForSheets /app/scripts/lib/xlsx/technical-task-workbook.ts" "checkDevelopmentWriteTarget /app/scripts/lib/dev-database-write-guard.ts" "planNextProcedureUnlinks /app/scripts/lib/xlsx/technical-task-next-procedure-plan.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1 $2"; else echo "no  $1 $2"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "6" ]; then printf '  ✓ 이번 판의 이름 여섯이 이미지 안에 있다 (옛 판이 아니다)\n'
    else printf '  ✗ 이번 판의 이름이 %s/6 개다 — **옛 판이 담겼다.** 캐시를 의심하세요\n' "${got:-0}"; IMGFAIL=1; fi
    # ⑧ 🔴 **갈래 셋을 이미지 안에서도 갈래마다 다르게 센다.**
    #    🔴 **부르지는 않는다** — 부르면 그 자리에서 DB 로 가는 길을 시험하게 된다.
    #       글자로만 센다. 🔴 **한 잣대로 재면 import-procedure-bundle 이 가짜 ✗** 다.
    #    ㄱ 개발 전용 둘 → 자물쇠 **있어야**(yes) · ㄴ 운영용 하나 → 자물쇠 **없어야**(no)
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/import-technical-task-procedures.ts /app/scripts/link-technical-task-next-procedures.ts; do if grep -q checkDevelopmentWriteTarget "$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    got=$(printf '%s\n' "$v" | grep -c '^yes ')
    if [ "${got:-0}" = "2" ]; then printf '  ✓ 갈래 ㄱ — 엑셀 읽개 둘이 이미지 안에서도 개발 DB 자물쇠를 부른다 (NAS 에서 부르면 막힌다)\n'
    else printf '  ✗ 갈래 ㄱ — 자물쇠를 부르는 것이 %s/2 개다. **운영 DB 에 쓸 수 있는 판이 담겼다.** 올리지 마세요\n' "${got:-0}"; IMGFAIL=1; fi
    # ⑧-ㄴ 🔴 운영용 하나 — **자물쇠가 없고 안전장치 셋이 있어야** 한다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'f=/app/scripts/import-procedure-bundle.ts; for pair in "guard:checkDevelopmentWriteTarget" "apply:process.env.APPLY" "tx:db.transaction" "target:formatDatabaseTarget"; do k=${pair%%:*}; s=${pair#*:}; n=$(grep -cF "$s" "$f" 2>/dev/null); echo "$k=$n"; done' 2>/dev/null | tr -d '\r')
    printf '%s\n' "$v" | sed 's/^/      /'
    pg=$(printf '%s\n' "$v" | sed -n 's/^guard=//p')
    pa=$(printf '%s\n' "$v" | sed -n 's/^apply=//p')
    pt=$(printf '%s\n' "$v" | sed -n 's/^tx=//p')
    pd=$(printf '%s\n' "$v" | sed -n 's/^target=//p')
    if [ "${pg:-x}" = "0" ] && [ "${pa:-0}" -ge 1 ] 2>/dev/null && [ "${pt:-0}" -ge 1 ] 2>/dev/null && [ "${pd:-0}" -ge 1 ] 2>/dev/null; then
      printf '  ✓ 갈래 ㄴ — import-procedure-bundle 가 **운영용 모양 그대로**다 (자물쇠 0 · APPLY · 트랜잭션 · 대상 DB 찍기)\n'
    else
      printf '  ✗ 갈래 ㄴ — 자물쇠 %s(기대 0) · APPLY %s · 트랜잭션 %s · 대상DB %s (셋은 1 이상). **옛 판이 담겼거나 안전장치가 빠졌다**\n' "${pg:-?}" "${pa:-?}" "${pt:-?}" "${pd:-?}"
      IMGFAIL=1
    fi
    # ⑧-ㄷ 👀 읽기 전용 하나 — **쓰는 문장이 0** 이어야 한다.
    # 🔴 `grep -c` 는 **센 값이 0 이면 0 을 찍고 종료 코드 1** 을 낸다. 그래서 여기에
    #    `|| echo ?` 같은 안전망을 달면 **하필 바라던 0 일 때만** 그것이 터져
    #    "0\n?" 가 되고, 읽기 전용이 맞는데도 ✗ 가 난다(2026-11-06 실제로 났다).
    #    🔵 파일이 없는 경우와 0 번인 경우는 **갈래를 나눠** 가른다 — 둘을 한 값으로
    #    뭉뚱그리면 「없어서 0」과 「있고 0」이 구별되지 않는다. ㄴ 과 같은 모양이다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'f=/app/scripts/export-procedure-bundle.ts; if [ -f "$f" ]; then echo "miss=0"; echo "w=$(grep -cE "\.insert\(|\.update\(|\.delete\(" "$f")"; echo "t=$(grep -c "transaction" "$f")"; else echo "miss=1"; fi' 2>/dev/null | tr -d ' \r')
    printf '%s\n' "$v" | sed 's/^/      /'
    rm_=$(printf '%s\n' "$v" | sed -n 's/^miss=//p')
    rw=$(printf '%s\n' "$v" | sed -n 's/^w=//p')
    rt=$(printf '%s\n' "$v" | sed -n 's/^t=//p')
    if [ "${rm_:-1}" != "0" ]; then
      printf '  ✗ 갈래 ㄷ — /app/scripts/export-procedure-bundle.ts 가 **이미지 안에 없다**\n'; IMGFAIL=1
    elif [ "${rw:-x}" = "0" ] && [ "${rt:-x}" = "0" ]; then
      printf '  ✓ 갈래 ㄷ — export-procedure-bundle 는 읽기만 한다 (쓰는 문장 0 · 트랜잭션 0)\n'
    else
      printf '  ✗ 갈래 ㄷ — 쓰는 문장 %s번 · 트랜잭션 %s번이다. **읽기 전용이 아니다**\n' "${rw:-?}" "${rt:-?}"; IMGFAIL=1
    fi
    # ⑨ tsx 가 있는가 — 이 도구는 tsx 로만 돈다(운영 이미지에는 없는 devDependency다).
    v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
    printf '      /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
    if [ "${v:-}" = "yes" ]; then printf '  ✓ tsx 가 있다\n'
    else printf '  ✗ tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
    # ⑩ 🔴 **값을 받아 본다 — 명령 셋을 npm 으로 실제로 부른다.**
    #    DATABASE_URL 을 안 준다. 세 파일이 1줄에서 './load-env' 를, 그 아래에서
    #    '../src/lib/db/connection' 을 정적 import 하고 connection.ts 가 모듈 맨
    #    위에서 동기적으로 던진다. **DB 에는 한 글자도 안 닿는다.**
    #    🔴 'node …' 가 아니라 **'npm run …'** 으로 부르는 것이 중요하다 —
    #       41번의 실패 모양이 'npm error Missing script' 였고, node 로 직접
    #       부르면 그 실패가 **영영 안 드러난다.**
    #    🔴 **procedures:import 를 꼭 넣는다 — 운영에서 불릴 유일한 새 명령이다.**
    #       그 파일도 import 가 정적이라 **Usage 를 찍기 전에** connection.ts 가
    #       던진다. 그래서 다른 둘과 **같은 답**('DATABASE_URL is not set')이 나온다.
    #    🔵 **procedures:export 는 여기서 안 부른다.** 개발 PC 에서 짐을 뜨는
    #       도구라 NAS 에서 부를 일이 없고, 「package.json 이 새 판인가」는 위 ②
    #       가 그 이름까지 세어 이미 답했다. 상자를 하나 더 띄울 값이 없다.
    for cmdname in check:due-date-inverted check:requested-due-date-sync procedures:import; do
      v=$(docker run --rm --entrypoint sh "$TAG" -c "cd /app && npm run $cmdname 2>&1 | head -40" 2>&1 | tr -d '\r')
      if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
        printf '  ✗ npm run %s — **Missing script** (41번과 같은 실패다. package.json 이 옛 판이다)\n' "$cmdname"
        printf '%s\n' "$v" | head -20 | sed 's/^/      /'
        IMGFAIL=1
      elif printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
        printf '  ✓ npm run %s 가 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)\n' "$cmdname"
      elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
        printf '  ✗ npm run %s 가 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다\n' "$cmdname"
        printf '%s\n' "$v" | head -20 | sed 's/^/      /'
        IMGFAIL=1
      else
        printf '  ? npm run %s 의 답이 기대와 다르다 — 아래 20줄을 사람이 보세요\n' "$cmdname"
        printf '%s\n' "$v" | head -20 | sed 's/^/      /'
        IMGFAIL=1
      fi
    done
    # ⑪ 🔵 백필도 여전히 서는가 — 43~51번이 재던 그 줄이다. **빼지 않는다.**
    v=$(docker run --rm --entrypoint sh "$TAG" -c 'cd /app && node --conditions=react-server --import tsx scripts/backfill-kyosan-used-parts.ts 2>&1 | head -40' 2>&1 | tr -d '\r')
    if printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
      printf '  ✓ 백필도 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)\n'
    elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
      printf '  ✗ 백필이 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다\n'
      printf '%s\n' "$v" | head -20 | sed 's/^/      /'
      IMGFAIL=1
    else
      printf '  ? 기대한 답이 아니다 — 아래 20줄을 사람이 보세요\n'
      printf '%s\n' "$v" | head -20 | sed 's/^/      /'
      IMGFAIL=1
    fi
    # ⑫ 🔵 이미지 안의 drizzle/ 은 **비어 있어야** 한다 — 볼륨으로 붙는 자리다.
    v=$(docker run --rm --entrypoint sh "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d '\r')
    printf '      /app/drizzle 안 .sql: %s개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)\n' "${v:-?}"
    if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ drizzle/ 이 비어 있다 (이미지에 안 굽는다)\n'
    else printf '  ✗ drizzle/ 에 .sql 이 들었다 — 이미지가 28MB 를 더 메고 다닌다\n'; IMGFAIL=1; fi
    # ⑬ 🔵 **양식은 이미지에 안 들어간다** — 볼륨으로 붙는 자리다. 들어갔으면
    #    도장과 계좌번호가 이미지에 구워진 것이라 **알아야 한다.**
    v=$(docker run --rm --entrypoint sh "$TAG" -c "ls /templates 2>/dev/null | wc -l" 2>/dev/null | tr -d '\r')
    printf '      /templates 안 파일: %s개 (기대 0 — 양식은 볼륨으로 붙는다)\n' "${v:-?}"
    if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ 양식이 이미지에 안 들어갔다\n'
    else printf '  ✗ 이미지 안에 /templates 가 %s개 있다 — 도장·계좌번호가 이미지에 구워졌다. 사람이 보세요\n' "${v:-?}"; IMGFAIL=1; fi
    if [ "$IMGFAIL" != 0 ]; then
      printf '%s\n' "🔴 이미지 안이 온전하지 않다. 올리지 마세요."
      BFAIL=$((BFAIL+1))
    fi
  fi
done

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  구운 것 %s / %s · 실패 %s\n' "$BUILT" "$HOWMANY" "$BFAIL"
if [ "$BFAIL" != "0" ]; then printf '%s\n' "🔴 실패가 있다. 위를 보세요."; exit 1; fi

# ══ 🔴 셋째 산출물 — A/S 마이그레이션 묶음 (이번 판에는 **보험**이다) ══
#  🔵 이번 판은 마이그레이션이 **0건**이고 운영 볼륨이 이미 124 다 — 그래서
#     **안 보내도 배포가 선다.** 그래도 만드는 까닭은 머리말에 적었다(절을 살려
#     두고, 볼륨이 124 가 아닐 때의 길을 남긴다).
#  🔴 git archive 로 뽑지 않는다 — 서브모듈이 빈 폴더로 나온다.
#  🔴 묶은 뒤 **안을 센다.** 「파일이 생겼다」와 「담겼다」는 다르다.
printf '\n%s\n' "════════ A/S 마이그레이션 묶음 (0건 판의 보험) ════════"
MIGTAR="$OUT/as-migrations.tar.gz"
rm -f "$MIGTAR" 2>/dev/null
if ( cd "$ASDIR" && tar -czf "$MIGTAR" drizzle ) </dev/null; then
  msz=$(stat -c %s "$MIGTAR" 2>/dev/null || wc -c < "$MIGTAR")
  mm5=$(md5sum "$MIGTAR" | awk '{print $1}')
  printf '  ✓ as-migrations.tar.gz (%s바이트)\n' "$msz"
  printf '    md5  %s\n' "$mm5"
else
  printf '  ✗ 묶기 실패\n'; exit 1
fi

# 🔴 안을 센다 — .sql 과 meta/_journal.json 의 idx 둘 다. 그리고 **48번이 올린
#    마지막 셋**을 하나씩. 수만 세면 어느 것이 빠졌는지는 안 알려 준다.
SQLPAT='^drizzle/[0-9][0-9][0-9][0-9]_.*[.]sql'
INSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "$SQLPAT")
INJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
printf '    묶음 안 .sql %s장 · _journal.json 의 idx %s개\n' "${INSQL:-?}" "${INJRN:-?}"
MFAIL=0
if [ "${INSQL:-0}" != "$AS_SQL_WANT" ]; then
  printf '  ✗ 묶음 안 .sql 이 %s장이다 — %s장이어야 한다\n' "${INSQL:-?}" "$AS_SQL_WANT"; MFAIL=1
fi
if [ "${INJRN:-0}" != "$AS_SQL_WANT" ]; then
  printf '  ✗ 묶음 안 idx 가 %s개다 — %s개여야 한다\n' "${INJRN:-?}" "$AS_SQL_WANT"; MFAIL=1
fi
# 🔴 **0124 가 묶음 안에 있으면 안 된다** — 있으면 이 배포의 전제(0건)가 깨진 것이다.
if tar -tzf "$MIGTAR" 2>/dev/null | grep -qE "^drizzle/${AS_NEXT_MIG}_.*[.]sql"; then
  printf '  ✗ 묶음에 %s 번 마이그레이션이 있다 — 이 배포는 0건을 전제로 쓰였다\n' "$AS_NEXT_MIG"; MFAIL=1
else
  printf '  ✓ 묶음에 %s 번이 없다 (마지막이 %s — 마이그레이션 0건이 맞다)\n' "$AS_NEXT_MIG" "$AS_LAST_MIG"
fi
for n in 0121 0122 0123; do
  hitsql=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${n}_.*[.]sql")
  hitsnap=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/meta/${n}_snapshot[.]json")
  if [ "${hitsql:-0}" = "1" ] && [ "${hitsnap:-0}" = "1" ]; then
    printf '  ✓ %s — .sql 과 스냅샷이 둘 다 묶음 안에 있다 (48번이 올린 셋)\n' "$n"
  else
    printf '  ✗ %s 가 온전하지 않다 — .sql %s · 스냅샷 %s\n' "$n" "${hitsql:-?}" "${hitsnap:-?}"; MFAIL=1
  fi
done

# 🔴 **지우는 문장이 없는지 여기서 센다.**
#    0123 에는 제약의 동작으로 ON DELETE restrict 가 들어 있다. 그것을 「지우는
#    문장」으로 세면 **더하기만 하는 판이 ✗ 가 된다.** 그래서 앱의
#    src/lib/db/migration-safety.ts 와 **같은 잣대**로 센다 —
#    DROP TABLE/COLUMN/SCHEMA · DELETE FROM · TRUNCATE 만 세고 ON DELETE 는 안 센다.
#    🔵 이번 판은 새 마이그레이션이 없으니 **마지막 셋을 표본으로** 센다.
DPAT='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|DELETE[[:space:]]+FROM|TRUNCATE'
DESTRUCT=0
for n in 0121 0122 0123; do
  sqlname=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -E "^drizzle/${n}_.*[.]sql" | head -1)
  if [ -z "$sqlname" ]; then continue; fi
  hit=$(tar -xzOf "$MIGTAR" "$sqlname" 2>/dev/null | grep -ciE "$DPAT" || true)
  if [ "${hit:-0}" = "0" ]; then
    printf '  ✓ %s — 지우는 문장 0건 (더하기만 한다)\n' "$n"
  else
    printf '  ✗ %s 에 지우는 문장이 %s건 있다 — 사람이 보세요\n' "$n" "$hit"; DESTRUCT=1
  fi
done
# 🔵 표본 둘 — 잣대가 살아 있고, ON DELETE 는 **안 걸려야** 한다.
PROBE1=$(printf '%s\n' "DROP TABLE foo;" | grep -ciE "$DPAT" || true)
PROBE2=$(printf '%s\n' 'REFERENCES "b"("id") ON DELETE restrict;' | grep -ciE "$DPAT" || true)
if [ "${PROBE1:-0}" = "1" ]; then
  printf '  ✓ 잣대가 살아 있다 (가짜 DROP 하나를 제대로 잡았다)\n'
else
  printf '  ✗ 잣대가 죽었다 — 위 「0건」이 공짜 통과다. 멈추세요\n'; MFAIL=1
fi
if [ "${PROBE2:-1}" = "0" ]; then
  printf '  ✓ ON DELETE 는 지우는 문장으로 안 센다 (0123 이 가짜 ✗ 를 안 받는다)\n'
else
  printf '  ✗ ON DELETE 를 지우는 문장으로 센다 — 0123 이 가짜 ✗ 를 받는다\n'; MFAIL=1
fi
if [ "$DESTRUCT" != "0" ]; then MFAIL=1; fi

if [ "$MFAIL" = "0" ]; then
  printf '  ✓ 묶음 안이 저장소와 같다 (.sql %s · idx %s · 0124 없음)\n' "$AS_SQL_WANT" "$AS_SQL_WANT"
else
  printf '%s\n' "🔴 묶음이 온전하지 않다. 올리지 마세요."; exit 1
fi
MIGLINE="as-migrations.tar.gz|${msz}|${mm5}|-"

# ══ 🔴 52-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 52-deploy.sh 의 TARS 는 **이름만 적힌 채로** 올라간다. 지문 칸이 비어 있으면
#     --check 에서 ? 로 세고 **--preload·--go 에서는 ✗ 다** — 아래 **두 줄**로
#     그 두 줄을 통째로 갈아 끼운다.
printf '\n%s\n' "════════ 52-deploy.sh 의 TARS 에 붙여 넣을 것 (두 줄) ════════"
printf '%s' "$TARTABLE"
echo "  🔴 위 두 줄로 TARS 의 두 줄을 통째로 갈아 끼운다."
echo "$MIGLINE"
echo "  🔴 마지막 줄(묶음)은 52-deploy.sh 의 MIGTAR_SIZE · MIGTAR_MD5 에 넣는다."
echo "  🔵 묶음은 **안 보내도 된다**(볼륨이 이미 124). 보내면 --migrate 가 md5 로 맞대 본다."
printf '\n%s\n' "✅ 둘 다 구웠다. tar · 묶음 · 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'
printf '\n%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **올리는 차례 — 이번 판은 양식도 마이그레이션도 없다**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  🔵 양식은 **한 장도 안 올립니다** — 열하나가 48번 값 그대로입니다(8절)."
printf '%s\n' "  🔵 마이그레이션도 **0건**입니다 — 기록도 볼륨도 **124 그대로**입니다."
printf '%s\n' "     그래도 --migrate 모드는 남겨 두었습니다. 그 모드가 「0건이어야 한다」를"
printf '%s\n' "     **값으로 잽니다**(기록이 앞뒤로 둘 다 124 인가 · 48번이 올린 표·칸·인덱스가"
printf '%s\n' "     아직 있는가). 🔴 **건너뛰어도 되지만, 건너뛰면 덤프를 --go 가 뜹니다.**"
printf '%s\n' ""
printf '%s\n' "  🔴 PowerShell 경로는 **슬래시**로 적습니다. 역슬래시는 bash·scp 가 먹습니다."
printf '%s\n' ""
printf '%s\n' "  ① (개발 PC · PowerShell) **스크립트부터 올린다**"
printf '%s\n' "       cd \"C:/Users/희만/Desktop/Development/dss-deploy/nas/setup\""
printf '%s\n' "       scp -O 52-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "       Get-FileHash -Algorithm MD5 52-deploy.sh"
printf '%s\n' ""
printf '%s\n' "  ② (NAS) 지금 상태를 잰다 — 아직 아무것도 안 바뀐다"
printf '%s\n' "       sudo -i"
printf '%s\n' "       bash /volume1/dss/setup/52-deploy.sh            ← --check"
printf '%s\n' "       bash /volume1/dss/setup/52-deploy.sh --count    ← 올리기 전 수"
printf '%s\n' "     🔵 2절의 마이그레이션 수가 **124** 로 나와야 합니다 — 앞에서도 뒤에서도."
printf '%s\n' ""
printf '%s\n' "  ③ (개발 PC · PowerShell) **tar 둘을 보낸다 — 한 줄에 하나씩**"
printf '%s\n' "       cd \"$(printf '%s' "$OUT" | sed 's|^/c/|C:/|')\""
printf '%s\n' "       scp -O dss-as-4.5.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "       scp -O dss-as-tools-12.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "     🔴 **-O 를 빼지 마세요** — DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' "     🔵 as-migrations.tar.gz 는 **안 보내도 됩니다**(볼륨이 이미 124)."
printf '%s\n' ""
printf '%s\n' "  ④ (NAS) **들여놓고 → (재고) → 갈아 끼운다**"
printf '%s\n' "       bash /volume1/dss/setup/52-deploy.sh --preload"
printf '%s\n' "       bash /volume1/dss/setup/52-deploy.sh            ← 다시 --check"
printf '%s\n' "       bash /volume1/dss/setup/52-deploy.sh --migrate  🔵 0건을 값으로 잰다"
printf '%s\n' "       bash /volume1/dss/setup/52-deploy.sh --go       ⏱ 정지 창"
printf '%s\n' "       bash /volume1/dss/setup/52-deploy.sh --count    ← 올린 뒤 수"
printf '%s\n' ""
printf '%s\n' "🔴 **되돌리기**: --rollback 은 app-as 를 $AS_OLD_TAG 로 되돌립니다."
printf '%s\n' "   🔵 도구는 $TOOLS_TAG 그대로 둡니다(39·41~51번과 같은 판단 — 전부 읽기 전용)."
printf '%s\n' "   🔵 **DB 는 되돌릴 것이 없습니다** — 이 배포가 DB 를 한 글자도 안 바꿉니다."
printf '%s\n' "      그래도 덤프는 뜹니다(--migrate 나 --go 가). 그 경로를 각 모드가 찍어 줍니다."
printf '%s\n' ""
printf '%s\n' "🔴 **새 도구 다섯은 갈래가 셋입니다 — 섞지 마세요**"
printf '%s\n' "   ㄱ) 🔒 **개발 PC 전용** (NAS 에서 부르면 자물쇠에 막힙니다 · npm 명령이 아닙니다)"
printf '%s\n' "        node --conditions=react-server --import tsx scripts/import-technical-task-procedures.ts"
printf '%s\n' "        node --conditions=react-server --import tsx scripts/link-technical-task-next-procedures.ts"
printf '%s\n' "   ㄷ) 👀 **개발 PC 에서 짐을 뜬다** (읽기만 합니다)"
printf '%s\n' "        npm run procedures:export -- --out \"<저장소 밖 경로>/bundle.json\""
printf '%s\n' "        🔵 --out 을 저장소 안으로 주면 그 도구가 **스스로 말립니다**(%TEMP% 를 권합니다)."
printf '%s\n' "   ㄴ) 🔴 **운영에서 넣는다** — NAS 의 tools-as 가 이 자리를 맡습니다."
printf '%s\n' "        🔴 그 차례는 **52-deploy.sh --go 꼬리말**에 적혀 있습니다. 거기를 보세요."
printf '%s\n' "        🔵 자물쇠 대신 **드라이런 기본 + APPLY=1 + 한 트랜잭션**이 지킵니다."
printf '%s\n' ""
printf '%s\n' "🔵 짐 파일(bundle.json)은 **이미지에 안 들어갑니다** — 볼륨으로 붙여 넣습니다."
printf '%s\n' "────────────────────────────────────────────────────────────"
