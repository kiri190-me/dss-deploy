#!/bin/bash
# dss-deploy/nas/setup/51-deploy.sh — 마흔여덟째 배포 (2026-11-04)
#
# 🔴 NAS 에서 돈다. **DSM 터미널은 긴 명령을 잘라 먹는다**(2026-10-12 하루에 네
#    번 깨졌다). 그래서 손으로 치지 않고 **파일로 올려** 돌린다. 절차는 이렇다:
#      ① (개발 PC · PowerShell)
#           cd C:\Users\희만\Desktop\Development
#           scp -O dss-deploy\nas\setup\51-deploy.sh dss-nas:/volume1/dss/setup/
#           Get-FileHash -Algorithm MD5 dss-deploy\nas\setup\51-deploy.sh
#      ② (NAS) md5sum /volume1/dss/setup/51-deploy.sh
#      ③ 🔴 **두 md5 가 같은지 눈으로 맞댄다.** 다르면 옮기다 잘린 것이다 —
#         그대로 돌리면 중간에서 끊긴 스크립트가 compose 를 고치다 만다.
#      🔵 이 파일은 돌 때 맨 위에서 **제 md5 를 스스로 찍는다.** ②를 따로 안
#         쳐도 로그에 남는다.
#    🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#    🔴 tar · scp 에 드라이브 문자(C:)를 주지 마라 — 원격 호스트로 읽는다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이번 판은 **이미지 말고 양식 파일(.xlsx)도 올린다** — 그래서 모드가 일곱이다
# ══════════════════════════════════════════════════════════════════════
#   사용자가 2026-10-31 에 양식을 직접 고쳤고(2026-11-04 「양식도 새로 올려야 할
#   것 같아」), 개발 PC 에서 재어 보니 **달라진 것이 하나가 아니라 다섯**이다:
#       제너레이터 OH 견적서.xlsx        10-31 12:10  ← 작업비 번호 2) → 3)
#       검사보고서_매쳐.xlsx             10-31 14:43
#       검사보고서_제너레이터.xlsx       10-31 14:43
#       수리보고서_매쳐.xlsx             10-31 14:44
#       수리보고서_제너레이터.xlsx       10-31 14:44
#   🔵 뒤의 넷이 바뀐 시각은 커밋 a81106f(14:48:06) **4분 전**이다.
#   🔵 나머지 여섯은 안 바뀌었다(내자견적서 · 매쳐 내자/OH 견적서 · 케이블
#      견적서 · 수리보고서 · 검사보고서).
#
# ── 🔴 **차례를 못 박는다 — 양식이 먼저다** ──────────────────────────
#   (NAS)  bash /volume1/dss/setup/51-deploy.sh                    ← --check
#   (NAS)  bash /volume1/dss/setup/51-deploy.sh --count            ← 올리기 전 수
#   (NAS)  bash /volume1/dss/setup/51-deploy.sh --templates-prep   ← 백업 + 받을 자리
#   (개발) scp -O 양식 다섯 → /volume1/dss/as-templates-incoming/
#   (NAS)  bash /volume1/dss/setup/51-deploy.sh --templates-apply  ✍ 양식을 바꾼다
#   (개발) scp -O tar 둘 → /volume1/dss/images/
#   (NAS)  bash /volume1/dss/setup/51-deploy.sh --preload
#   (NAS)  bash /volume1/dss/setup/51-deploy.sh                    ← 다시 --check
#   (NAS)  bash /volume1/dss/setup/51-deploy.sh --go               ⏱ 정지 창
#   (NAS)  bash /volume1/dss/setup/51-deploy.sh --count            ← 올린 뒤 수
#
#   🔴 **왜 양식이 먼저인가** (짐작이 아니라 소스를 읽고 정했다):
#     · 새 보고서 코드는 양식의 라벨 글상자(확내·조치·정리 세 문단)를 **여전히
#       읽고, 못 찾으면 던진다**(xlsx/service-report-template.ts 의 그 주석 —
#       「그래도 계속 읽는다 … 못 찾으면 던진다」). 운영에 놓인 양식의 속을 이
#       스크립트는 **못 본다.** 그러니 **모르는 채로 코드를 먼저 올리지 않는다.**
#     · 거꾸로 **옛 코드 + 새 양식**은 재서 안전한 쪽이다. 견적서 채우개는
#       「2)/3) 작업비」 머리글 칸을 **아예 안 건드리고**(xlsx/oh-quote-template.ts
#       는 작업 내역 번호만 당긴다) 양식에 적힌 글자가 그대로 나간다. 옛 화면만
#       번호를 2) 로 그리는, **눈에 보이는 어긋남**이고 문서는 멀쩡하다.
#     · 🔵 양식은 볼륨에 놓인 **파일**이고 앱이 쓸 때마다 readFile 로 **다시
#       읽는다**(storage/quote-template.ts 84줄 · storage/service-report-
#       template.ts 213줄 — 캐시가 한 줄도 없다). **컨테이너를 안 내려도 바뀐다.**
#   🔴 그래서 **--go 는 그 다섯이 운영에 들어가 있어야 선다.** 다섯 중 하나라도
#      md5 가 다르면 --go 에서 **✗** 다(다른 모드에서는 ?). 🔴 다만 **폴더를 아예
#      못 열었을 때는 어느 모드에서나 ?** 다 — 처음 도는 검사라 「못 쟀다」를
#      「틀렸다」로 세지 않는다.
#
# ── 🔴 양식을 덮어쓰기 전에 **백업한다** ─────────────────────────────
#   --templates-prep 가 /volume1/dss/as-templates 를 통째로
#   /volume1/dss/backups/as-templates-<날짜시각>/ 로 떠 두고 md5 로 맞댄다.
#   🔴 **--rollback 은 이미지만 되돌린다. 양식은 자동으로 안 돌아간다** —
#      되돌리는 명령을 --templates-prep 가 찍어 준다.
#
# ── 🔴 받는 자리를 따로 둔다 — 도는 앱이 반쪽 파일을 읽지 않게 ───────
#   scp 는 **/volume1/dss/as-templates-incoming/** 로 받는다. 그 폴더는 컨테이너에
#   안 붙는다. --templates-apply 가 md5 를 먼저 맞대고, 맞을 때만 **mv** 로
#   제자리에 옮긴다(같은 볼륨이라 이름 바꾸기 한 번이다). 덮어쓰는 도중에
#   보고서를 만들던 사람이 반쪽 파일을 읽는 길을 그렇게 막는다.
#   🔴 **주인과 모드를 되읽는다** — scp 로 받으면 root 소유가 되고, 앱은 uid 1000
#      으로 돈다. 옮긴 뒤 **이미 잘 돌던 이웃 양식의 주인·모드를 그대로 입힌다.**
#      안 입히면 앱이 그 양식을 못 읽어 견적서·보고서가 그 자리에서 죽는다.
#
# ── 갈아 끼우는 것 — **저장소 하나, 태그 둘** ────────────────────────
#     ① A/S 앱   dss-as:4.3        → **dss-as:4.4**        커밋 6
#     ② A/S 도구 dss-as-tools:10    → **dss-as-tools:11**   커밋 6
#
#   🔴 **PO 는 이번에 안 건드린다.** dss-po 의 HEAD 가 기준 SHA(9c1b2ef) 그대로라
#      구울 것이 없다(2026-11-04 실측 — 51-build.sh 머리말). dss-po:0.9 가 그대로
#      돈다. 그래서 「안 건드리는 상자」가 여덟에서 **아홉**이 되었다.
#   🔴 **마이그레이션이 없다.** drizzle/ 이 기준 SHA 이후 **0건**이다(2026-11-04
#      재측정 — 51-build.sh 머리말에 명령과 결과를 적었다). 그래서 이 파일에는
#      **--migrate 모드가 없다** — DB 의 **구조**를 바꾸는 단계가 한 군데도 없다.
#   🔵 **나머지 여덟도 안 건드린다** — 통합 로그인 · 재고 · 게시판 · 계측기 ·
#      개선요청 · RF 이슈관리 · 휴가 · 통합 승인함.
#
# ── 🔴 기준 SHA — 두 출처를 맞대어 확인했다 ──────────────────────────
#   · **A/S df16e6c3** : README.md 의 「기준 SHA (2026-10-30 21:40 갱신)」 표가
#     | A/S 관리 | RF_Service_System | 4.2 | df16e6c3 | 이라고 적고, 50-build.sh
#     머리말의 A/S 범위 **마지막 줄**이 df16e6c3 이다 — 49번이 구운 HEAD 다.
#   · **PO 9c1b2ef** : 같은 표가 | PO | dss-po | 0.9 | 9c1b2ef | 이라고 적고,
#     50-build.sh 머리말의 PO 범위 마지막 줄이 9c1b2ef 다.
#   🔵 둘 다 지시서의 값과 맞았다. **세 출처가 전부 같았다.**
#
# ── 이 배포가 하는 일 — **견적서와 보고서의 모양** ───────────────────
#   A/S  df16e6c3..df16e6c (여섯)
#     ef6b0b4 견적서 미리보기를 양식 넷에 맞춘다
#     c54644c 절사 칸의 「0이면 숨김」 서식이 행을 따라간다
#     a81106f 보고서 단락을 이어 붙이고 남는 빈 줄을 걷어낸다
#     f1a1fe6 보고서 맺음 표시를 세 열 오른쪽으로 — 문서와 미리보기 함께
#     fc30fcb 견적서 결재 알림이 결재 탭을 열고, 수정하면 결재가 자동으로 반려된다
#     df16e6c 저장 안 된 내용을 두고 나가려 하면 묻는다
#
#   🔴 **DB 의 구조도, 저장된 글자도 이 배포가 바꾸지 않는다.** 바뀌는 것은
#      화면과 **만들어 내는 엑셀 파일의 모양**이다.
#   🔵 **설정 이름도 안 는다.** 이 범위에 새 환경변수가 한 개도 없다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 PO 를 안 건드려도 **PO 의 repair_cases 쓰기 권한은 잰다**
# ══════════════════════════════════════════════════════════════════════
#   49번이 올린 dss-po:0.9 가 **운영에서 지금도** repair_cases 를 UPDATE 한다
#   (내자 납기요청일을 고치면 수리 건의 고객 요청 납기일이 따라간다).
#   🔴 이번 판이 PO 를 안 건드린다고 그 위험이 사라진 것이 아니다 —
#      **재는 것을 빼지 않는다.** 49번의 1-ㄷ 절을 글자 그대로 가져왔다:
#        ㄱ) **앱이 쓰는 길로** — dss-po 컨테이너 안에서 그 앱의 DATABASE_URL 로
#            붙어 has_table_privilege 를 **select 로만** 묻는다.
#        ㄴ) 그 길이 막히면(postgres 모듈이 없거나 접속 실패) **psql 가지**로
#            넘어간다 — dss-po 에서 **역할 이름만** 뽑아 dss-pg-app 안에서 묻는다.
#   🔴 **실제로 UPDATE 를 돌리지 않는다.** 운영 자료다.
#   🔴 **「틀리면 안 되나」도 함께 잰다** — select=0 이면 「권한이 없다」가 아니라
#      **「내가 엉뚱한 것을 쟀다」**다. 그때는 ✗ 가 아니라 ? 다.
#   🔵 **엄함이 이번 판에서 한 칸 내려간다** — 49번은 --go 에서 block 이었다.
#      이번 판은 **PO 를 안 갈아 끼우므로** --go 에서도 warnmiss 다: 못 쓰면 ✗
#      (그건 지금 운영이 고장나 있다는 뜻이다), **못 쟀으면 ?**(A/S 교체를 막을
#      일이 아니다). 🔴 재는 것을 뺀 것이 아니라 **엄함만** 내렸다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 A/S 도구를 **왜 올리는가** — 49번과 같은 모양, 다른 파일
# ══════════════════════════════════════════════════════════════════════
#   package.json 이 **0줄** 바뀌었다 — 「늘어난 npm 명령」 잣대는 「굽는다」를
#   안 준다. 🔴 그래도 올린다. 까닭은 둘이다:
#     ㄱ) 🔴 **도구의 import 닫힘 안에 바뀐 파일이 여섯이다.**
#        닫힘은 package.json 의 scripts 가 가리키는 scripts/*.ts **전부**(+백필,
#        스물둘)에서 폈고 **223개**다(못 푼 상대경로 0 · 49번과 같은 수).
#        겹친 여섯: notifications.ts · quote-approval-rules.ts · quote-new-link.ts ·
#        service-report-body-wrap.ts · service-report-template.ts · sheet-rows.ts
#        🔵 시작점을 **스물넷**으로 더 넓혀 닫힘 226개로 재도 **겹침은 똑같이
#           여섯**이다(2026-11-04 실측). 넓혀도 답이 안 바뀐다.
#        🔵 이번에 생긴 도메인 파일 넷(quote-change-detection · quote-save-outcome ·
#           quote-form-changed · unsaved-leave-guard)은 **닫힘 밖**이다 — 도구가
#           한 번도 안 들여온다.
#     ㄴ) 🔵 39번에 넓혀 둔 잣대(「tools 스테이지가 담는 것」)로도 **72 > 0** 이다.
#        🔴 이번 범위에서 바뀐 **72개가 전부** tools 가 담는 자리 안이다(바깥 0).
#   🔵 **치르는 값**은 tar 하나(224MB)를 더 올리고 compose 의 image: 줄이 하나 더
#      달라지는 것뿐이다. tools-as 는 profiles: [tools] 라 **다시 뜨지도 않는다.**
#
# ══════════════════════════════════════════════════════════════════════
# 🔵 --count 로 무엇을 보나 — **기대값이 「안 바뀐다」다**
# ══════════════════════════════════════════════════════════════════════
#   세 도구를 읽기 전용으로 부른다(48번이 올리고 49번이 쓰던 그 셋):
#     check:target-shipment-missing   사내 목표 출하일 미등록
#     check:due-date-inverted         납기 역전
#     check:requested-due-date-sync   납기요청일 ↔ 고객 요청 납기일 어긋남
#   🔴 **이번 배포는 이 수들과 아무 상관이 없다** — 견적서·보고서의 모양만
#      바뀐다. 그래서 **--go 앞뒤의 수가 같은 것이 정상**이다. 다르면 그 사이에
#      사람이 저장한 것이고, 그것도 정상이다 — **달라진 만큼을 설명할 수 있어야**
#      한다는 뜻이다.
#   🔵 셋 다 :9 에도 :10 에도 있다. 앞뒤로 다 돌 수 있다.
#   🔴 셋 다 **쓰는 모드가 없다** — INSERT·UPDATE·DELETE 가 한 줄도 없다.
#
# ── 🔴 49번에서 그대로 가져온 것 ──────────────────────────────────────
#   ① **303 판정**(grep -qE '200|30[1237]'). A/S 는 307, PO 는 303 으로 로그인에
#      보낸다. 🔵 이번엔 PO 를 안 갈아 끼우지만 **도는 것은 재므로** 그대로 둔다.
#   ② 🔴 **치환 전에 그 줄의 낱말 수가 2 인지 본다.** 줄 끝에 주석이 붙어 있으면
#      **주석의 마지막 낱말**이 태그로 바뀌고 image: 값은 그대로 남는다.
#   ③ 🔴 **달라진 image: 줄이 꼭 몇 개인지** 센다 — --go **2**(app-as·tools-as) ·
#      --rollback **1**(app-as 하나). 🔵 49번은 3/2 였다 — PO 가 빠졌다.
#   ④ 🔴 **설정 파일 검사**(중복 키 · auto). 값은 한 글자도 안 찍는다.
#   ⑤ 🔵 연락서 폴더 검사 · 재고 관리 통로 검사는 **42~49번 것 그대로다.**
#      🔴 **빼지 않는다** — 한 번 빼면 다시 넣는 사람이 없다.
#   ⑥ 🔵 **--rollback 은 앱 하나만 되돌린다.** 도구는 :10 그대로 둔다 —
#      39·41~49번과 같은 판단(그 도구들은 전부 읽기 전용이다).
#   ⑦ 🔵 **다시 띄우는 것은 app-as 하나뿐이다.** tools-as 는 profiles: [tools] 다.
#   ⑧ 🔴 **DB 둘의 StartedAt 을 앞뒤로 비교한다** — 안 멈췄다는 증거다.
#   ⑨ 🔴 **제 md5 를 스스로 찍는다** · **image: 줄을 통째로 찍는다**.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 설정 파일 — **.env 와 env/*.env 를 둘 다 본다** (49번에서 가져왔다)
# ══════════════════════════════════════════════════════════════════════
#   ㄱ) 🔴 **같은 이름이 두 줄 있으면 아래가 이긴다.** 그래서 세 파일의 **중복
#      키를 센다.** 🔴 **값은 한 글자도 안 찍는다. 이름만 찍는다.**
#   ㄴ) 🔴 **컨테이너 안에서 'auto' 는 172.x 가 된다.** SSO_ISSUER ·
#      SSO_REDIRECT_URI 가 'auto' 면 로그인이 돌아오지 못한다.
#
# ── 모드 일곱 ─────────────────────────────────────────────────────────
#   (기본)   --check            아무것도 안 바꾸고 **잴 수 있는 것을 다 잰다**
#   --count                     세 도구를 **읽기만** 해서 센다
#   --templates-prep            🔴 양식을 **백업**하고 받을 자리를 만든다
#   --templates-apply           ✍ .incoming 의 양식을 md5 로 맞대고 **제자리로 옮긴다**
#   --preload                   tar 둘을 들여놓기만 한다 (아직 안 갈아 끼운다)
#   --go                        compose 의 image: 줄 **둘**을 바꾸고 app-as 를 다시 띄운다
#   --rollback                  app-as 만 옛 판으로 되돌린다 (도구는 :10 그대로)
#
# ── 🔴 --check 도 「아무것도 안 한다」는 아니다 ───────────────────────
#   A/S DB 에 **select** 를 몇 번 보낸다(마이그레이션 수 · PO 의 권한 — 바꾸는
#   문장은 없다). 앱의 주소에 GET 을 한 번 보낸다. 재고 관리 통로에도 **GET 을
#   한 번** 보낸다. 양식 폴더를 **읽는다**(ls 와 md5sum 뿐이다). 도구 이미지가
#   이미 실려 있으면 **안을 보려고 컨테이너를 잠깐 띄웠다 지운다.**
#   「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」가 정확하다.
#   🔴 **바꾸는 모드는 셋뿐이다**: --templates-apply · --go · --rollback.
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
#   설정 파일은 **이름이 있는가/없는가**와 **auto 인가**만 본다. PO 권한 검사는
#   DATABASE_URL 에서 **역할 이름만** 꺼낸다. 🔵 **양식 경로는 찍어도 된다** —
#   /templates/… 는 저장소의 compose 사본에 이미 적혀 있는 값이고 비밀이 아니다.
#   🔴 다만 **/templates 밖을 가리키는 값은 안 찍는다**(어디로 샜는지는 사람이
#      설정 파일에서 직접 볼 일이다).
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
BK=$D/backups/docker-compose.nas.yml.v48-$STAMP
BKDB=$D/backups/db   # 🔴 --migrate 가 뜨는 덤프가 여기 간다

# ══ 이번에 다시 띄우는 것 — 앱 **하나** ═══════════════════════════════
#   열쇠|서비스|컨테이너|새 태그|옛 태그|tar|호스트 포트
#   🔴 **PO 줄이 없다.** 49번에는 둘째 줄이 있었다 — 이번엔 안 갈아 끼운다.
SITES='
as|app-as|dss-as|dss-as:4.4|dss-as:4.3|dss-as-4.4.tar|13000
'
# 🔵 7절의 재고 관리 검사가 명령을 넣을 상자. 위 표 셋째 칸과 같은 이름이다.
AS_APP_CN=dss-as
# 🔴 PO 권한 검사가 명령을 넣을 상자. **이번엔 갈아 끼우지 않지만 잰다.**
PO_APP_CN=dss-po
# ══ 🔴 A/S 도구 — **이번에 갈아 끼운다.** up -d 로 다시 띄우지 않는다 ═══
AS_TOOLS_SVC=tools-as
TOOLS_OLD=dss-as-tools:10
TOOLS_NEW=dss-as-tools:11
IMG_MIGDIR=/app/drizzle
MIGDIR=$D/as-migrations

# ══ 🔴 양식 — 이번 판의 새 식구 ═══════════════════════════════════════
#   🔵 운영 자리: compose 의 app-as·app-po 가 둘 다
#      '/volume1/dss/as-templates:/templates:ro' 로 붙인다(저장소 사본 311·650줄).
#   🔴 **tools-as 에는 그 볼륨이 없다**(저장소 사본의 tools-as 블록을 세어 확인).
#      그래서 양식은 **호스트에서 바로** 재고, 「앱이 보는가」는 app-as 안에서
#      따로 묻는다. 🔵 호스트에서 재는 쪽이 짧고 틀릴 자리가 적다 — 이 스크립트는
#      root 로 돌고 그 폴더는 /volume1/dss 아래다.
TPLDIR=$D/as-templates
TPLIN=$D/as-templates-incoming
TPLBK=$D/backups/as-templates-$STAMP
TPL_IN_CONTAINER=/templates

# 🔴 **이번에 올리는 다섯** — 이름|바이트|md5
#    출처: [배포본] 51-build.sh --go 가 끝에 찍어 주는 다섯 줄.
#    🔵 아래 값은 2026-11-04 개발 PC 실측이다. 51-build.sh 의 TPLS 표와 같은 값.
TPL_UP='
제너레이터 OH 견적서.xlsx|62101|4ef6d9dc75f797efb7088b43e9b4c3f9
검사보고서_매쳐.xlsx|191929|5701e075c3aac71f63d29fe28ed68e0f
검사보고서_제너레이터.xlsx|190507|ef7edda07812f937381f82819fc79d22
수리보고서_매쳐.xlsx|191911|ab25c06be1799952e593c2eef810885e
수리보고서_제너레이터.xlsx|190340|f3b2c76d359c8decd33c01d8b4b0235b
'
TPL_UP_WANT=5

# 🔵 **안 바뀐 여섯** — 이름|바이트|md5. 운영 것과 같은지 **보기만** 한다.
#    🔴 다르다고 ✗ 를 내지 않는다. 운영 양식이 개발 PC 것과 꼭 같아야 한다는
#       보증이 어디에도 없다(도장·계좌번호가 든 파일이라 저장소에 없다).
#       다르면 **사람이 보라는 뜻**이다.
TPL_KEEP='
내자견적서.xlsx|85942|981edf1f1d4a1b4bf2747167c41149d5
매쳐 내자 견적서.xlsx|40079|a9f1f7e75e2ac718d86c288efec41d43
매쳐 OH 견적서.xlsx|40664|fc4ee94678b99e5c7b60ca7d1fd94c57
케이블 견적서.xlsx|50996|5450deb6182ccf4c76c2c7ea14b143d8
수리보고서.xlsx|190710|403b642d7c700a118ee515e20e4d659e
검사보고서.xlsx|190589|f7dd2fe0dbf03e6a44fa48a00ee4413e
'
TPL_KEEP_WANT=6

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

# ══ 🔴 tar 둘의 지문 — [배포본] 51-build.sh 가 굽고 **바로 잰 값**을 넣는다 ══
#   tar 이름|바이트|md5|Config 지문
#   🔴 **아직 안 채웠다.** 51-build.sh --go 가 끝에 찍어 주는 **두 줄**로 아래
#      두 줄을 통째로 갈아 끼우세요.
#      (비어 있으면 3절이 **? 로 센다** — 「옮기다 깨진 것」은 잡지만 「개발 PC 에서
#      구운 그것이 맞나」는 못 본다. ? 는 통과로 안 세므로 --preload 가 막힌다.)
#   🔵 이름만이라도 적어 두는 까닭: 줄이 아예 없으면 4절(--preload)이 **아무것도
#      안 싣고 조용히 끝난다.** 이름이 있으면 싣기는 제대로 된다.
TARS='
dss-as-4.4.tar|133611008|9c29c222576e982e823762494aa1e900|sha256:1f9245ae51573e57090108429c4f8eee129a42d7e67f6707a31c05eb14eba57b
dss-as-tools-11.tar|224566784|54d062938e70c5b1fa75fdc8000c9d93|sha256:624e1831580401b3dd9b917179564ff1ce2fe5d97b55f5af7389486ed514a75f
'
# ══ 🔴 마이그레이션 헬퍼 넷 — 39-deploy.sh 에서 줄 단위로 가져왔다 ════
#    40~50번에는 이 넷이 없다(그 열 번은 마이그레이션이 0건이었다).
has_table()  { pgn "$1" "$2" "select count(*) from information_schema.tables where table_schema='public' and table_name='$3'"; }
has_column() { pgn "$1" "$2" "select count(*) from information_schema.columns where table_schema='public' and table_name='$3' and column_name='$4'"; }
has_index()  { pgn "$1" "$2" "select count(*) from pg_indexes where schemaname='public' and indexname='$3'"; }

app_img_lines() {
  for r in $(rows); do
    L=$(img_line "$(fld "$r" 2)") || continue
    printf '%s:%s\n' "$L" "$(tag_at "$L")"
  done
}
read_migdir() {
  MIG_N_SQL=0; MIG_N_J=0; MIG_STATE=""
  [ -d "$MIGDIR" ] || { MIG_STATE=NODIR; return 0; }
  MIG_N_SQL=$(ls -1 "$MIGDIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
  if [ -f "$MIGDIR/meta/_journal.json" ]; then
    MIG_N_J=$(grep -o '"idx"' "$MIGDIR/meta/_journal.json" 2>/dev/null | wc -l | tr -d ' ')
  fi
  MIG_N_SQL=${MIG_N_SQL:-0}; MIG_N_J=${MIG_N_J:-0}
  if   [ "$MIG_N_SQL" = "$AS_WANT" ] && [ "$MIG_N_J" = "$AS_WANT" ]; then MIG_STATE=DONE
  elif [ "$MIG_N_SQL" = "$AS_HAVE" ] && [ "$MIG_N_J" = "$AS_HAVE" ]; then MIG_STATE=OLD
  else MIG_STATE=ODD
  fi
  return 0
}
check_new_migs() {
  local t miss="" f n rc=0
  for t in $AS_NEW_MIGS; do
    ls -1 "$MIGDIR/${t}_"*.sql >/dev/null 2>&1 || miss="$miss $t(sql)"
    [ -f "$MIGDIR/meta/${t}_snapshot.json" ]   || miss="$miss $t(snapshot)"
  done
  if [ -z "$miss" ]; then ok "0121·0122·0123 의 .sql 과 meta/*_snapshot.json 이 다 있다"
  else bad "🔴 빠진 것:$miss"; rc=1; fi
  n=0
  for t in $AS_NEW_MIGS; do
    f=$(ls -1 "$MIGDIR/${t}_"*.sql 2>/dev/null | head -1)
    [ -n "$f" ] || continue
    local c; c=$(grep -ciE "$DESTRUCTIVE_RE" "$f" 2>/dev/null); n=$((n + ${c:-0}))
  done
  if [ "$n" = "$MIG_DROP_WANT" ]; then
    ok "0121·0122·0123 에 지우는 문장이 ${n}줄이다 (기대 ${MIG_DROP_WANT}줄 — 더하기만 한다)"
  else
    bad "🔴 0121·0122·0123 에 지우는 문장이 ${n}줄이다 (기대 ${MIG_DROP_WANT}줄) — 고치지 말고 **먼저 알리세요**"
    rc=1
  fi
  # 🔵 글자 표식 — 올린 것이 그 파일이 맞는지. 이름만 맞고 속이 다를 수 있다.
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
place_migs() {
  if [ ! -s "$MIGTAR" ]; then
    say "incoming 에 묶음이 없다 — 폴더가 이미 새것인지 아래에서 본다"
    return 0
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

tar2tag() {
  case "$1" in
    dss-as-4.4.tar)       printf 'dss-as:4.4' ;;
    dss-as-tools-11.tar)  printf 'dss-as-tools:11' ;;
  esac
}

# ══ 🔴 DB 는 **구조가 그대로여야** 한다(마이그레이션 0건) ═════════════
#   🔵 A/S 와 PO 는 **같은 dss_as** 를 본다(PO 는 제 DB 가 없다). 재는 자리도 하나다.
AS_BOX=dss-pg-app; AS_DB=dss_as; AS_HAVE=121   # [저장소] 51-build.sh 4절과 같다
# 🔴 이 배포는 마이그레이션 **3건**이다 — 열 번 만에 처음이다.
#    운영 볼륨/기록이 121 이고 124 가 되어야 한다. 값의 출처는 51-build.sh 4절.
AS_WANT=124
AS_NEW_MIGS='0121 0122 0123'
# 🔴 「지우는 문장」의 잣대. 앱의 src/lib/db/migration-safety.ts 와 같다.
#    ⚠️ DELETE 는 **DELETE FROM** 일 때만 센다 — 0123 의 ON DELETE restrict 는
#    제약의 동작이지 지우는 문장이 아니다. 안 가르면 더하기만 하는 판이 ✗ 가 된다.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
MIG_DROP_WANT=0
# 묶음이 들어오는 자리 — 51-build.sh 가 만든 as-migrations.tar.gz 를 여기로 scp 한다.
MIGTAR=$D/setup/incoming/as-migrations.tar.gz
# 🔴 51-build.sh --go 가 2026-11-04 에 찍은 값. 묶음이 옮기다 끊겼는지를 이 둘로 가른다.
MIGTAR_SIZE=2383054
MIGTAR_MD5=c015011297edbcd4f438a3bbe3309e2a
INCOMING=$D/setup/incoming
# 🔴 적용 뒤 **값으로** 확인할 것들(겉이 아니라 결과).
#    0121 표 하나 · 0122 칸 하나 · 0123 칸 하나와 인덱스 하나.
AS_NEW_TABLE=procedure_case_execution_edges
AS_NEW_COL_TABLE=procedure_template_nodes
AS_NEW_COL=next_procedure_template_id
AS_NEW_COL2_TABLE=procedure_case_execution_nodes
AS_NEW_COL2=user_position_x
AS_NEW_INDEX=procedure_template_nodes_next_template_idx
# 🔴 줄 수가 그대로여야 하는 표 — 더하기만 하는 판이라 하나도 안 줄어야 한다.
AS_COUNT_TABLES='repair_cases procedure_templates procedure_template_nodes procedure_case_executions procedure_case_execution_nodes'
# 🔴 49번이 올린 기능이 쓰는 표. 1-ㄹ 절이 이 이름으로 권한을 묻는다. **ASCII 다.**
PO_WRITE_TABLE=repair_cases
# 🔵 안 건드리는 **아홉** — 「옆으로 안 샜다」는 증거로 센다.
#    🔴 49번의 여덟에 **dss-po** 가 늘었다 — 이번엔 PO 를 안 갈아 끼우므로
#       그쪽도 「그대로 도는가」 쪽에서 센다.
KEEP_BOXES="dss-auth dss-inventory dss-meters dss-board dss-improvements dss-leave dss-approvals dss-rf-trouble dss-po"
KEEP_BOXES_WANT=9
# 🔵 DB 둘은 멈추지 않는다 (애초에 up -d --no-deps 가 app-as 만 건드린다)
KEEP_DB="dss-pg-app dss-pg-auth"

MODE=check
case "${1:-}" in
  --check|"")         MODE=check ;;
  --migrate)          MODE=migrate ;;   # 🔴 DB 가 바뀐다
  --preload)          MODE=preload ;;
  --go)               MODE=go ;;
  --rollback)         MODE=rollback ;;
  --count)            MODE=count ;;
  --templates-prep)   MODE=tplprep ;;
  --templates-apply)  MODE=tplapply ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --count · --templates-prep · --templates-apply · --preload · --migrate · --go · --rollback\n' "$1"; exit 2 ;;
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
LOG="$D/setup/logs/50-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "마흔여덟째 배포 — A/S 앱·도구 + **양식 다섯**   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  🔴 개발 PC 의 Get-FileHash 값과 **같은지 눈으로 맞대세요** (DSM 터미널이 긴 것을 잘라 먹습니다)"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  로그: $LOG"
printf '%s\n' "  🔴 차례: --check → --count → --templates-prep → (scp 양식) → --templates-apply"
printf '%s\n' "           → (scp tar) → --preload → --check → --go → --count"
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
pgq() { # 1 상자 2 DB 3 SQL
  "$DOCKER" exec -i "$1" sh -c "psql -U \"\$POSTGRES_USER\" -d $2 -X -tAq -c \"$3\"" 2>/dev/null | head -1 | tr -d ' \r'
}
pgn() { local v; v=$(pgq "$1" "$2" "$3"); isnum "$v" && printf '%s' "$v"; }
mig_count() { pgn "$1" "$2" 'select count(*) from drizzle.__drizzle_migrations'; }

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

# 🔴 level: block(다섯이 안 맞으면 ✗) · soft(안 맞아도 ?)
#    🔴 **「못 쟀다」는 어느 level 에서나 ?** 다 — 처음 도는 검사라 그렇게 센다.
templates_check() { # 1 block|soft
  # 🔴 쓰는 이름을 **전부** local 로 묶는다. 이 함수는 7절에서 DB 시작 시각을
  #    세는 고리 **직전**에도 불리는데, 거기서도 s 라는 이름을 쓴다 — 새어 나가면
  #    그쪽이 조용히 틀린다.
  local level n got name wsz wm5 m s upok updiff upmiss keepok keepdiff keepmiss out okn missn unsetn
  level=${1:-soft}
  printf '\n    ── 🔴 운영 양식을 **값으로** 잰다 (읽기만 한다)\n'
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

  # ── 이번에 올리는 다섯 ────────────────────────────────────────────
  printf '\n    ── 이번에 올리는 다섯이 **들어가 있는가**\n'
  upok=0; updiff=0; upmiss=0; got=0
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    got=$((got+1))
    if [ ! -s "$TPLDIR/$name" ]; then
      say "없음   $name  (운영에 그 이름의 파일이 없다)"
      upmiss=$((upmiss+1)); continue
    fi
    m=$(tpl_md5 "$TPLDIR" "$name")
    s=$(tpl_size "$TPLDIR" "$name")
    if [ "${m:-x}" = "$wm5" ] && [ "${s:-x}" = "$wsz" ]; then
      say "같다   $name  ($wsz바이트 · $wm5)"
      upok=$((upok+1))
    else
      say "다르다 $name  운영 ${s:-?}바이트 ${m:-?}"
      say "       개발 PC $wsz바이트 $wm5"
      updiff=$((updiff+1))
    fi
  done <<TPLUPEOF
$(tplrows "$TPL_UP")
TPLUPEOF
  if [ "$got" = "$TPL_UP_WANT" ]; then ok "올릴 양식 $TPL_UP_WANT 개를 다 봤다 (표본이 비지 않았다)"
  else bad "올릴 양식을 ${got}개만 봤다 — $TPL_UP_WANT 개를 기대했다. TPL_UP 표가 깨졌다"; fi
  say "같다 ${upok} · 다르다 ${updiff} · 없다 ${upmiss}  (기대: 올린 뒤라면 ${TPL_UP_WANT}/0/0)"
  if [ "$upok" = "$TPL_UP_WANT" ]; then
    ok "🔴 **다섯이 다 들어가 있다** — 새 코드를 올려도 되는 상태다"
  elif [ "$level" = block ]; then
    bad "🔴 양식 다섯 중 ${upok}개만 들어가 있다 — **--go 전에 양식부터 올리세요**"
    say "🔴 차례: --templates-prep → (개발 PC 에서 scp) → --templates-apply → 다시 --go"
    say "🔴 까닭: 새 보고서 코드는 양식의 라벨 글상자를 **못 찾으면 던진다.** 운영"
    say "   양식의 속을 이 스크립트는 못 보므로, 모르는 채로 코드를 먼저 올리지 않는다."
    doubt
  else
    hm "양식 다섯 중 ${upok}개만 들어가 있다 — **아직 안 올리셨다면 정상**입니다(--templates-prep 부터)"
  fi

  # ── 안 바뀐 여섯 ──────────────────────────────────────────────────
  printf '\n    ── 안 바뀐 여섯 — **보기만 한다**(✗ 를 내지 않는다)\n'
  keepok=0; keepdiff=0; keepmiss=0; got=0
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    got=$((got+1))
    if [ ! -s "$TPLDIR/$name" ]; then
      say "없음   $name"
      keepmiss=$((keepmiss+1)); continue
    fi
    m=$(tpl_md5 "$TPLDIR" "$name")
    if [ "${m:-x}" = "$wm5" ]; then keepok=$((keepok+1)); say "같다   $name"
    else keepdiff=$((keepdiff+1)); say "다르다 $name  운영 ${m:-?} / 개발 PC $wm5"; fi
  done <<TPLKEEPEOF
$(tplrows "$TPL_KEEP")
TPLKEEPEOF
  if [ "$got" = "$TPL_KEEP_WANT" ]; then ok "안 바뀐 여섯을 다 봤다 (표본이 비지 않았다)"
  else bad "안 바뀐 양식을 ${got}개만 봤다 — $TPL_KEEP_WANT 개를 기대했다. TPL_KEEP 표가 깨졌다"; fi
  say "같다 ${keepok} · 다르다 ${keepdiff} · 없다 ${keepmiss}"
  if [ "$keepdiff" = "0" ] && [ "$keepmiss" = "0" ]; then
    ok "안 바뀐 여섯이 개발 PC 것과 같다 (이 배포가 건드릴 자리가 아니다)"
  else
    hm "안 바뀐 여섯 중 ${keepdiff}개가 다르고 ${keepmiss}개가 없다 — **이 배포를 막지 않는다.** 사람이 보세요"
    say "🔵 운영 양식이 개발 PC 것과 꼭 같아야 한다는 보증은 어디에도 없다 —"
    say "   도장·계좌번호가 든 파일이라 저장소에 없고, 운영에서 따로 고쳤을 수 있다."
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
    say "🔴 주인·모드를 보세요. scp 로 받으면 root 소유가 되고, 앱은 uid 1000 으로 돕니다."
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
#    🔵 **이번 판에는 block 을 안 쓴다** — PO 를 갈아 끼우지 않으므로, 못 쟀다고
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

# ══ 🔴 재고 관리 통로가 **값을 돌려주는가** (45~49번 것을 글자 그대로) ══
#   🔴 **빼지 않는다.** 이것은 **앱**이 쓰는 길이다.
#   🔴 「설정이 적혀 있다」가 아니라 **「물어보니 답한다」**로 잰다.
#   🔵 **읽기만 한다.** 토큰은 쓰기만 하고 **찍지 않는다.**
#   🔴 **머리말에 한글을 안 넣는다.** 받는 답도 일부러 ASCII 로만 찍게 했다.
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
  local v got c
  printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TOOLS_NEW"
  # ① runner 가 아니라 tools 인가 — runner 에는 /app/package.json 이 없다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/package.json: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "tools 스테이지가 맞다" \
    || { bad "🔴 /app/package.json 이 없다 — **runner 를 구웠다.**"; doubt; }
  # ② 🔴 **npm 명령 셋이 이미지 안 package.json 에 있는가.** 41번의 자리다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "3" ] && ok "npm 명령 셋이 이미지 안에 있다" \
    || { bad "🔴 명령이 ${got:-0}/3 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다.** 부르는 날 Missing script 가 난다"; doubt; }
  # ③ 🔴 **닫힘 안에서 바뀐 여섯이 다 담겼는가.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/src/lib/domain/notifications.ts /app/src/lib/domain/quote-approval-rules.ts /app/src/lib/domain/quote-new-link.ts /app/src/lib/domain/service-report-body-wrap.ts /app/src/lib/xlsx/service-report-template.ts /app/src/lib/xlsx/sheet-rows.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "6" ] && ok "닫힘 안에서 바뀐 여섯이 다 들어 있다" \
    || { bad "🔴 여섯 중 ${got:-0}개만 들어 있다 — src/ 가 온전히 안 담겼다"; doubt; }
  # ④ 🔵 48번이 올린 도구 넷 — **빼지 않는다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "4" ] && ok "48번이 올린 도구 넷이 다 들어 있다" \
    || bad "🔴 도구 파일이 ${got:-0}/4 개다 — scripts/ 가 온전히 안 담겼다"
  # ⑤ 백필 도구 파일 셋 — 43~49번 것 그대로. **빼지 않는다.**
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for f in /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts /app/scripts/lib/kyosan-used-parts-backfill-plan.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "3" ] && ok "백필 도구 파일 셋이 다 들어 있다" \
    || bad "🔴 백필 도구 파일이 ${got:-0}/3 개다 — scripts/ 가 온전히 안 담겼다"
  # ⑥ 🔴 **그 src/ 가 '이번 판' 인가 — 글자로 센다.** ③ 은 「있나」만 본다.
  #    🔴 이번 판에는 **닫힘 안에 새로 생긴 파일이 하나도 없다.** 여섯 다 옛날부터
  #       있던 파일이라 ③ 이 통과해도 낡은 판이 담길 수 있다 — 그 자리를 막는 것이
  #       이 단계이고, 이번 판에서는 **③ 보다 이쪽이 세다.**
  #    🔵 여섯 다 기준 df16e6c3 판에는 **0번** 나오고 지금 판에는 나온다
  #       (2026-11-04 git show 로 세어 확인: 0→2 · 0→6 · 0→4 · 0→1 · 0→3 · 0→2).
  #    🔴 이름은 전부 ASCII 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c 'for pair in "removeRowMergeCells /app/src/lib/xlsx/sheet-rows.ts" "shrinkBodyBlock /app/src/lib/xlsx/service-report-template.ts" "SERVICE_REPORT_CLOSING_MARK_COLUMN_SHIFT /app/src/lib/domain/service-report-body-wrap.ts" "QUOTE_APPROVAL_AUTO_REJECT_REASON /app/src/lib/domain/quote-approval-rules.ts" "QUOTE_EDIT_TAB_PARAM /app/src/lib/domain/quote-new-link.ts" "tab: /app/src/lib/domain/notifications.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1 $2"; else echo "no  $1 $2"; fi; done' 2>/dev/null | tr -d '\r')
  printf '%s\n' "$v" | sed 's/^/      /'
  got=$(printf '%s\n' "$v" | grep -c '^yes ')
  [ "${got:-0}" = "6" ] && ok "이번 판의 이름 여섯이 이미지 안에 있다 (옛 src/ 가 아니다)" \
    || { bad "🔴 이번 판의 이름이 ${got:-0}/6 개다 — **옛 src/ 가 담긴 이미지다.** 올리지 마세요"; doubt; }
  # ⑦ tsx 가 있는가 — 이 도구는 tsx 로만 돈다(운영 이미지에는 없는 devDependency다).
  v=$("$DOCKER" run --rm --entrypoint sh "$TOOLS_NEW" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
  say "/app/node_modules/tsx: ${v:-못 읽음} (기대 yes)"
  [ "${v:-}" = "yes" ] && ok "tsx 가 있다" \
    || bad "🔴 tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다"
  # ⑧ 🔴 **값으로 받아 본다 — 명령 둘을 npm 으로 실제로 부른다.**
  #    DATABASE_URL 을 안 준다. **DB 에는 한 글자도 안 닿는다.**
  #    🔴 'node …' 가 아니라 **'npm run …'** 으로 부르는 것이 중요하다 —
  #       41번의 실패 모양이 'npm error Missing script' 였고, node 로 직접
  #       부르면 그 실패가 **영영 안 드러난다.**
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
  # ⑨ 🔵 백필도 여전히 서는가 — 43~49번이 재던 그 줄이다. **빼지 않는다.**
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
    say "🔵 이번 판에는 :9 에도 :10 에도 셋이 다 있어야 한다 — 48번이 올려 두었다."
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
  printf '%s\n' "🔴 **이번 배포는 이 수들과 상관이 없다** — 견적서·보고서의 모양만 바뀝니다."
  printf '%s\n' "   앞뒤가 같으면 정상이고, 다르면 **그 사이에 사람이 저장한 것**입니다."
  count_one check:target-shipment-missing "사내 목표 출하일 미등록"
  count_one check:due-date-inverted       "납기 역전"
  count_one check:requested-due-date-sync "납기요청일 ↔ 고객 요청 납기일 어긋남"
  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ══════════════════════════════════════════════════════════════════════
# ── --templates-prep : 🔴 **백업**하고 받을 자리를 만든다 ─────────────
# ══════════════════════════════════════════════════════════════════════
#   🔴 이 모드가 **쓰는** 것은 둘뿐이다: 백업 폴더와 받을 폴더. 운영 양식 자체는
#      **한 글자도 안 건드린다.**
#   🔴 백업은 **md5 로 맞대어 확인한다** — cp 가 돌았다는 것과 같은 것이 들어갔다는
#      것은 다른 말이다(「겉이 아니라 결과」).
if [ "$MODE" = tplprep ]; then
  printf '\n== 양식 백업 · 받을 자리 만들기\n'
  if [ ! -d "$TPLDIR" ]; then
    bad "🔴 $TPLDIR 가 없다 — 운영 양식 폴더를 못 찾았다. 멈춘다"
    printf '\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
    exit 1
  fi
  N0=$(tpl_file_count "$TPLDIR")
  say "지금 $TPLDIR 안 파일 ${N0:-못 쟀다}개"
  if ! isnum "${N0:-}" || [ "${N0:-0}" -eq 0 ]; then
    bad "🔴 양식 폴더가 비었거나 못 읽었다 — **빈 결과는 삼켜진 오류일 수 있다.** 멈춘다"
    printf '\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
    exit 1
  fi
  say "── 백업 전 모습"
  tpl_dump "$TPLDIR"

  # ── ① 백업 ───────────────────────────────────────────────────────
  mkdir -p "$TPLBK" || { bad "백업 폴더를 못 만들었다: $TPLBK"; exit 1; }
  if cp -a "$TPLDIR/." "$TPLBK/" 2>/dev/null; then
    ok "백업했다: $TPLBK"
  else
    bad "🔴 백업에 실패했다 — **아무것도 안 하고 멈춘다.** 되돌릴 길 없이 덮어쓰지 않는다"
    printf '\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
    exit 1
  fi
  N1=$(tpl_file_count "$TPLBK")
  say "백업 폴더 안 파일 ${N1:-못 쟀다}개 (기대 ${N0})"
  if [ "${N1:-x}" = "${N0}" ]; then ok "파일 수가 같다 (${N0}개)"
  else bad "🔴 백업에 ${N1:-?}개만 들어갔다 — ${N0}개를 기대했다"; fi
  # 🔴 **md5 로 맞댄다** — 수만 세면 「같은 수의 다른 파일」을 못 가른다.
  BAD5=0; SEEN5=0
  ( cd "$TPLDIR" 2>/dev/null && find . -maxdepth 1 -type f -print 2>/dev/null | sed 's|^\./||' | sort ) > /tmp/dss-tpl-names-$STAMP.txt
  while IFS= read -r f; do
    [ -n "${f:-}" ] || continue
    SEEN5=$((SEEN5+1))
    a=$(tpl_md5 "$TPLDIR" "$f")
    b=$(tpl_md5 "$TPLBK" "$f")
    if [ -n "${a:-}" ] && [ "${a:-x}" = "${b:-y}" ]; then :
    else BAD5=$((BAD5+1)); say "🔴 백업이 다르다 — $f  (원본 ${a:-못 읽음} / 백업 ${b:-못 읽음})"; fi
  done < /tmp/dss-tpl-names-$STAMP.txt
  rm -f /tmp/dss-tpl-names-$STAMP.txt
  say "md5 로 맞댄 파일 ${SEEN5}개 · 어긋난 것 ${BAD5}개"
  if [ "${SEEN5:-0}" -ge 1 ] && [ "$BAD5" = "0" ]; then
    ok "백업이 **md5 까지 같다** (${SEEN5}개 · 겉이 아니라 결과로 확인했다)"
  else
    bad "🔴 백업이 온전하지 않다 (본 것 ${SEEN5}개 · 어긋남 ${BAD5}개) — **덮어쓰지 마세요**"
    doubt
  fi

  # ── ② 받을 자리 ──────────────────────────────────────────────────
  #   🔴 **컨테이너에 안 붙는 폴더**다. 도는 앱이 반쪽 파일을 읽는 길을 막는다.
  mkdir -p "$TPLIN" 2>/dev/null
  #   🔴 **777 이다.** 이 스크립트는 root 로 도는데 scp 는 **root 가 아닌 계정**으로
  #      붙는다. 755(root 소유)로 두면 양식을 한 장도 못 올린다 —
  #      「scp: …: Permission denied」. 2026-11-04 50번에서 실제로 걸렸다.
  #   🔵 넓게 열어도 되는 까닭 셋:
  #      · 컨테이너에 안 붙는다 (도는 앱이 이 폴더를 아예 못 본다)
  #      · --templates-apply 가 옮기면서 주인·모드를 **이웃 양식 값**으로 다시 입힌다
  #      · 옮기고 나면 이 폴더를 **비운다**
  chmod 777 "$TPLIN" 2>/dev/null
  if [ -d "$TPLIN" ]; then ok "받을 자리를 만들었다: $TPLIN (컨테이너에 안 붙는다)"
  else bad "받을 자리를 못 만들었다: $TPLIN"; fi
  OLDIN=$(tpl_file_count "$TPLIN")
  if [ "${OLDIN:-0}" != "0" ]; then
    hm "받을 자리에 파일이 이미 ${OLDIN}개 있다 — 지난번 찌꺼기일 수 있다. 아래를 보세요"
    tpl_dump "$TPLIN"
    say "🔵 --templates-apply 는 **이름과 md5 가 맞는 다섯만** 옮긴다. 나머지는 그대로 둔다."
  fi

  # ── ③ 같은 볼륨인가 — mv 가 이름 바꾸기 한 번으로 끝나는가 ──────
  DEV1=$(stat -c %d "$TPLDIR" 2>/dev/null)
  DEV2=$(stat -c %d "$TPLIN" 2>/dev/null)
  say "장치 번호 — 양식 폴더 ${DEV1:-?} · 받을 자리 ${DEV2:-?}"
  if [ -n "${DEV1:-}" ] && [ "${DEV1:-x}" = "${DEV2:-y}" ]; then
    ok "둘이 같은 볼륨이다 — mv 가 **이름 바꾸기 한 번**이라 반쪽 파일이 안 생긴다"
  else
    hm "장치 번호가 다르다 — mv 가 복사+지우기로 돈다(원자적이 아니다). 그래도 쓰긴 쓴다"
    say "🔵 그 경우 아주 잠깐 반쪽 파일이 보일 수 있다. 사람이 안 쓰는 시간에 하세요."
  fi

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$FAIL" != 0 ]; then
    printf '%s\n' "🔴 위 ✗ 를 보세요. **운영 양식은 한 글자도 안 바뀌었습니다.**"
    exit 1
  fi
  printf '%s\n' "🔵 **운영 양식은 아직 한 글자도 안 바뀌었습니다.**"
  printf '%s\n' ""
  printf '%s\n' "🔴 **다음 — 개발 PC 에서 양식 다섯을 보내세요 (PowerShell)**"
  printf '%s\n' "    cd C:\\Users\\희만\\Desktop\\Development\\_images-47\\templates"
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    printf '%s\n' "    scp -O \"$name\" dss-nas:$TPLIN/"
  done <<TPLSCPEOF
$(tplrows "$TPL_UP")
TPLSCPEOF
  printf '%s\n' "  🔴 **한 줄에 하나씩입니다.** 이름에 공백과 한글이 둘 다 있어 별표(*)로 묶으면"
  printf '%s\n' "     PowerShell 이 어떻게 쪼갤지 장담할 수 없습니다."
  printf '%s\n' "  🔴 **scp 에는 -O 를 붙입니다.** DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
  printf '%s\n' "  🔴 **보내는 쪽에 드라이브 문자(C:)를 주지 마세요** — 폴더로 들어가서 보냅니다."
  printf '%s\n' ""
  printf '%s\n' "  그다음 (NAS):  bash $0 --templates-apply"
  printf '%s\n' ""
  printf '%s\n' "🔴 **되돌리는 법** — 양식은 --rollback 으로 **안 돌아갑니다.** 손으로 되돌립니다:"
  printf '%s\n' "    cp -a $TPLBK/. $TPLDIR/"
  printf '%s\n' "    bash $0            ← --check 로 md5 를 다시 재세요"
  printf '%s\n' "  🔵 백업 폴더: $TPLBK"
  printf '%s\n' "────────────────────────────────────────────────────────────"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════
# ── --templates-apply : ✍ **양식을 제자리로 옮긴다** (쓰는 단계) ──────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **md5 를 먼저 다 맞대고, 다섯이 전부 맞을 때만 옮긴다.** 하나라도 어긋나면
#      **아무것도 안 옮긴다** — 반만 바꾼 상태가 제일 나쁘다.
#   🔴 옮긴 뒤 **주인과 모드를 되읽는다**(「주인과 모드를 둘 다 되읽을 것」).
if [ "$MODE" = tplapply ]; then
  printf '\n== 양식을 제자리로 옮긴다 (✍ 쓰는 단계)\n'
  [ -d "$TPLDIR" ] || { bad "🔴 $TPLDIR 가 없다. 멈춘다"; exit 1; }
  [ -d "$TPLIN" ]  || { bad "🔴 받을 자리가 없다: $TPLIN — 먼저 --templates-prep 를 돌리세요"; exit 1; }

  # ── ① 백업이 있는가 — **없으면 안 옮긴다** ──────────────────────
  BKN=$(ls -1d "$D/backups/as-templates-"* 2>/dev/null | wc -l | tr -d ' ')
  LASTBK=$(ls -1d "$D/backups/as-templates-"* 2>/dev/null | sort | tail -1)
  say "양식 백업 폴더 ${BKN:-0}개 · 가장 최근: ${LASTBK:-없음}"
  if isnum "${BKN:-}" && [ "${BKN:-0}" -ge 1 ]; then
    ok "되돌릴 백업이 있다 (${LASTBK})"
  else
    bad "🔴 양식 백업이 **하나도 없다** — 먼저 --templates-prep 를 돌리세요. 되돌릴 길 없이 덮어쓰지 않는다"
    printf '\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
    exit 1
  fi

  say "── 받을 자리에 들어온 것"
  tpl_dump "$TPLIN"

  # ── ② md5 를 **전부 먼저** 맞댄다 ───────────────────────────────
  printf '\n    ── 다섯의 md5 를 맞댄다 (옮기기 **전에** 전부 본다)\n'
  READY=0; SEEN=0; NOTREADY=0
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    SEEN=$((SEEN+1))
    if [ ! -s "$TPLIN/$name" ]; then
      say "없음   $name — 받을 자리에 안 왔다"
      NOTREADY=$((NOTREADY+1)); continue
    fi
    m=$(tpl_md5 "$TPLIN" "$name")
    s=$(tpl_size "$TPLIN" "$name")
    if [ "${m:-x}" = "$wm5" ] && [ "${s:-x}" = "$wsz" ]; then
      say "맞다   $name  ($wsz바이트 · $wm5)"
      READY=$((READY+1))
    else
      say "다르다 $name  받은 것 ${s:-?}바이트 ${m:-?}"
      say "       적어 둔 것 $wsz바이트 $wm5"
      NOTREADY=$((NOTREADY+1))
    fi
  done <<TPLAPEOF
$(tplrows "$TPL_UP")
TPLAPEOF
  if [ "$SEEN" = "$TPL_UP_WANT" ]; then ok "다섯을 다 봤다 (표본이 비지 않았다)"
  else bad "${SEEN}개만 봤다 — $TPL_UP_WANT 개를 기대했다. TPL_UP 표가 깨졌다"; fi
  say "맞다 ${READY} · 안 맞다 ${NOTREADY}"
  if [ "$READY" != "$TPL_UP_WANT" ] || [ "$FAIL" != 0 ]; then
    bad "🔴 다섯이 다 맞지 않는다 (${READY}/${TPL_UP_WANT}) — **아무것도 안 옮긴다**"
    say "🔴 반만 바꾼 상태가 제일 나쁘다. 덜 온 파일을 다시 보내고 이 모드를 다시 돌리세요."
    say "🔴 md5 가 다르면 **옮기다 깨진 것**이거나 **개발 PC 에서 또 고친 것**입니다 —"
    say "   뒤쪽이면 이 파일의 TPL_UP 표를 51-build.sh 가 찍어 준 값으로 갈아 끼우세요."
    doubt
    printf '\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
    exit 1
  fi
  ok "🔴 다섯이 **전부** 맞다 — 이제 옮긴다"

  # ── ③ 주인·모드의 본보기를 **이미 잘 돌던 이웃 양식**에서 뽑는다 ─
  #   🔴 scp 로 받으면 root 소유가 된다. 앱은 uid 1000 으로 돈다.
  #      안 입히면 앱이 그 양식을 **못 읽어** 견적서·보고서가 그 자리에서 죽는다.
  REFNAME=""
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    [ -s "$TPLDIR/$name" ] || continue
    REFNAME=$name
    break
  done <<TPLREFEOF
$(tplrows "$TPL_KEEP")
TPLREFEOF
  if [ -n "${REFNAME:-}" ]; then
    REFU=$(stat -c %u "$TPLDIR/$REFNAME" 2>/dev/null)
    REFG=$(stat -c %g "$TPLDIR/$REFNAME" 2>/dev/null)
    REFM=$(stat -c %a "$TPLDIR/$REFNAME" 2>/dev/null)
    say "본보기: $REFNAME — 주인 ${REFU:-?}:${REFG:-?} · 모드 ${REFM:-?}"
    if isnum "${REFU:-}" && isnum "${REFG:-}" && [ -n "${REFM:-}" ]; then
      ok "이미 잘 돌던 이웃 양식에서 주인·모드를 읽었다 (${REFU}:${REFG} ${REFM})"
    else
      hm "주인·모드를 못 읽었다 — 옮긴 뒤 **사람이 보세요**"
      REFU=""; REFG=""; REFM=""
    fi
  else
    hm "안 바뀐 여섯 중 운영에 놓인 것이 하나도 없다 — 주인·모드의 본보기가 없다. 옮긴 뒤 사람이 보세요"
    REFU=""; REFG=""; REFM=""
  fi

  # ── ④ 옮긴다 ────────────────────────────────────────────────────
  printf '\n    ── 옮긴다 (mv · 같은 볼륨이면 이름 바꾸기 한 번)\n'
  MOVED=0
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    if mv -f "$TPLIN/$name" "$TPLDIR/$name" 2>/dev/null; then
      if [ -n "${REFU:-}" ]; then chown "$REFU:$REFG" "$TPLDIR/$name" 2>/dev/null; fi
      if [ -n "${REFM:-}" ]; then chmod "$REFM" "$TPLDIR/$name" 2>/dev/null; fi
      say "옮겼다 $name"
      MOVED=$((MOVED+1))
    else
      say "🔴 못 옮겼다 $name"
    fi
  done <<TPLMVEOF
$(tplrows "$TPL_UP")
TPLMVEOF
  say "옮긴 것 ${MOVED}개 (기대 $TPL_UP_WANT)"
  if [ "$MOVED" = "$TPL_UP_WANT" ]; then ok "다섯을 다 옮겼다"
  else bad "🔴 ${MOVED}/${TPL_UP_WANT} 개만 옮겼다 — **반만 바뀐 상태다.** 위를 보고 사람이 마무리하세요"; fi

  # ── ⑤ 제자리에서 **다시 잰다** — 겉이 아니라 결과 ───────────────
  printf '\n    ── 옮긴 뒤 제자리에서 다시 잰다 (md5 · 주인 · 모드)\n'
  tpl_dump "$TPLDIR"
  AFTOK=0; AFTBAD=0
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    m=$(tpl_md5 "$TPLDIR" "$name")
    u=$(stat -c %u "$TPLDIR/$name" 2>/dev/null)
    g=$(stat -c %g "$TPLDIR/$name" 2>/dev/null)
    o=$(stat -c %a "$TPLDIR/$name" 2>/dev/null)
    if [ "${m:-x}" = "$wm5" ]; then AFTOK=$((AFTOK+1)); else AFTBAD=$((AFTBAD+1)); say "🔴 md5 가 다르다 — $name (${m:-못 읽음})"; fi
    if [ -n "${REFU:-}" ] && { [ "${u:-x}" != "$REFU" ] || [ "${g:-x}" != "$REFG" ] || [ "${o:-x}" != "$REFM" ]; }; then
      say "⚠️ 주인·모드가 본보기와 다르다 — $name (${u:-?}:${g:-?} ${o:-?} · 본보기 ${REFU}:${REFG} ${REFM})"
    fi
  done <<TPLAFEOF
$(tplrows "$TPL_UP")
TPLAFEOF
  if [ "$AFTOK" = "$TPL_UP_WANT" ] && [ "$AFTBAD" = "0" ]; then
    ok "제자리에서 다시 재도 다섯의 md5 가 맞다"
  else
    bad "🔴 제자리에서 맞는 것이 ${AFTOK}/${TPL_UP_WANT} 개다 — 사람이 보세요"
    doubt
  fi

  # ── ⑥ 🔴 **앱이 보는가** — 그것이 진짜 답이다 ──────────────────
  templates_check soft

  # ── ⑦ 받을 자리를 치운다 ────────────────────────────────────────
  LEFT=$(tpl_file_count "$TPLIN")
  say "받을 자리에 남은 파일 ${LEFT:-0}개"
  if [ "${LEFT:-0}" = "0" ]; then
    rmdir "$TPLIN" 2>/dev/null && ok "받을 자리를 치웠다 ($TPLIN)" || say "🔵 받을 자리를 못 치웠다 — 빈 폴더라 해롭지 않다"
  else
    hm "받을 자리에 ${LEFT}개가 남았다 — 우리가 안 옮긴 것이다. 아래를 보고 사람이 치우세요"
    tpl_dump "$TPLIN"
  fi

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$FAIL" = 0 ]; then
    printf '%s\n' "✅ 양식 다섯이 운영에 들어갔습니다."
    printf '%s\n' "🔵 **앱은 쓸 때마다 양식을 다시 읽습니다 — 컨테이너를 안 내려도 바뀝니다.**"
    printf '%s\n' "🔵 지금은 **옛 코드 + 새 양식** 상태입니다. 제너레이터 O/H 견적서의 미리보기"
    printf '%s\n' "   번호가 잠깐 어긋나 보일 수 있습니다(화면 2) · 파일 3)). **문서는 멀쩡합니다** —"
    printf '%s\n' "   --go 로 새 코드를 올리면 둘 다 3) 이 됩니다."
    printf '%s\n' ""
    printf '%s\n' "🔴 다음: 개발 PC 에서 tar 둘을 보내고 --preload → --check → --go"
    printf '%s\n' "    (개발 PC · PowerShell)"
    printf '%s\n' "      cd C:\\Users\\희만\\Desktop\\Development\\_images-47"
    printf '%s\n' "      scp -O dss-as-4.4.tar dss-as-tools-11.tar dss-nas:$IMGD/"
  else
    printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:"
    printf '%s\n' "    cp -a ${LASTBK:-<백업폴더>}/. $TPLDIR/"
  fi
  printf '%s\n' "────────────────────────────────────────────────────────────"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ── 1. 지금 상태 ──────────────────────────────────────────────────────
printf '\n== 1. 지금 상태\n'
[ -f "$CF" ] || { bad "compose 를 못 찾았다: $CF"; exit 1; }
say "compose 줄 수 $(wc -l < "$CF") · image: 줄 $(grep -c '^ *image:' "$CF")개"

# ── ㄱ) 🔴 **운영이 지금 쓰는 태그 전부** — 저장소 사본을 믿지 않는다 ──
#   이 저장소의 compose 사본은 운영보다 뒤처진다(아홉 판 차이가 난 적이 있다).
#   배포는 NAS 위 파일을 한 줄씩 고치고 돌아오지 않는다. 그래서 **여기서 직접
#   읽어 로그에 남긴다.**
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
        say "🔴 **이 저장소의 compose 사본을 믿고 적은 값이 아니다** — 51-build.sh 머리말이"
        say "   README 의 기준 SHA 표와 49번 머리말을 맞대어 얻은 값이다. 그래도 어긋났다면"
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

# ══ 🔴 PO — **이번엔 안 갈아 끼운다.** 그래도 「그대로 도는가」는 본다 ══
printf '\n    ── app-po (이번에 **안 건드린다**)\n'
PL=$(img_line app-po)
if [ -n "${PL:-}" ]; then
  PCUR=$(tag_at "$PL")
  PRUN=$("$DOCKER" inspect -f '{{.Config.Image}}' "$PO_APP_CN" 2>/dev/null)
  PST=$("$DOCKER" inspect -f '{{.State.Status}}' "$PO_APP_CN" 2>/dev/null)
  say "app-po — ${PL}줄 · compose ${PCUR} · 도는 것 ${PRUN:-없음} (${PST:-?})"
  if [ "$PCUR" = "dss-po:0.9" ]; then
    ok "app-po 가 dss-po:0.9 다 (49번이 올린 그 판 · 이번에 안 건드린다)"
  else
    hm "app-po 가 $PCUR 다 — dss-po:0.9 를 기대했다. **이 배포를 막지 않는다**(PO 를 안 건드린다). 사람이 보세요"
  fi
  # 🔴 **5절이 이 줄을 건드리면 안 된다.** 아래 '달라진 image: 줄 수' 검사가 그것을 센다.
  say "🔴 5절은 이 줄을 **안 고친다** — 달라진 image: 줄 수로 그것을 확인한다."
else
  bad "compose 에 app-po 가 없다 — 지금까지 있던 것이다. 사람이 보세요"
fi

# ══ 🔴 A/S 도구 — **이번엔 이 배포가 고치는 줄이다** ═════════════════
printf '\n    ── %s\n' "$AS_TOOLS_SVC"
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  say "$AS_TOOLS_SVC — ${TL}줄 · $TCUR"
  case "$MODE" in
    rollback)
      # 🔵 되돌려도 도구는 :10 그대로 둔다(머리말 ⑥). 그래서 기대값이 새 판이다.
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
say "🔵 **이 판은 설정을 하나도 안 바꾼다** — 새 환경변수가 한 개도 없다."

# ── 1-ㄷ. 🔴 **양식** — 이 판의 새 관문 ───────────────────────────────
#   🔴 **단계마다 엄함이 다르다**(기대값이 아니라 엄함이다):
#      · --go        : 다섯이 안 들어가 있으면 ✗ (**양식이 먼저다**)
#      · 그 밖       : ? (아직 안 올렸으면 정상이다)
#      · 🔴 **폴더를 못 열었으면 어느 모드에서나 ?** — 처음 도는 검사다.
case "$MODE" in
  go) templates_check block ;;
  *)  templates_check soft ;;
esac

# ── 1-ㄹ. 🔴 **PO 가 repair_cases 에 쓸 수 있는가** ───────────────────
#   🔵 이번 판은 PO 를 안 갈아 끼운다 — 그래서 block 을 안 쓴다(머리말).
case "$MODE" in
  rollback) po_write_privilege_check soft ;;
  *)        po_write_privilege_check warnmiss ;;
esac

# ── 2. 🔴 DB — 마이그레이션 수가 **그대로여야** 한다 ──────────────────
#   🔵 A/S 와 PO 가 같은 dss_as 를 본다. 그래서 재는 자리가 하나다.
printf '\n== 2. DB (dss_as · A/S 와 PO 가 함께 쓴다) — 마이그레이션 %s(적용 전) 또는 %s(적용 뒤)\n' "$AS_HAVE" "$AS_WANT"
MIG_AS0=$(mig_count "$AS_BOX" "$AS_DB")
say "기록 ${MIG_AS0:-?} (--migrate 전이면 $AS_HAVE · 뒤면 $AS_WANT)"
if [ -z "${MIG_AS0:-}" ]; then
  bad "DB 를 못 쟀다 — $AS_BOX 가 도는지 보세요"
elif [ "$MIG_AS0" = "$AS_HAVE" ]; then
  ok "$AS_HAVE 다 — 아직 --migrate 전이다. 🔴 --go 보다 **먼저** --migrate 를 돌려야 한다"
elif [ "$MIG_AS0" = "$AS_WANT" ]; then
  ok "$AS_WANT 다 — 마이그레이션이 이미 적용됐다. 이제 --go 로 가면 된다"
else
  bad "🔴 ${MIG_AS0} 이다 ($AS_HAVE 도 $AS_WANT 도 아니다) — 다른 배포가 먼저 돌았거나 전제가 깨졌다"
  doubt
fi

# ── 2. 🔴 A/S 마이그레이션 볼륨 — 이 배포의 심장 ─────────────────────
printf '\n== 2-나. 🔴 A/S 마이그레이션 볼륨 (%s → %s 의 %s)\n' "$MIGDIR" "$AS_TOOLS_SVC" "$IMG_MIGDIR"
printf '%s\n' "🔴 .sql 만으로는 모자라다 — **meta/_journal.json 과 snapshot 까지** 가야 한다."
printf '%s\n' "   목록에 없는 .sql 은 drizzle 이 아예 모르고, 적용이 **0건으로 조용히 끝난다.**"
read_migdir
say "$MIGDIR — .sql ${MIG_N_SQL}장 · meta/_journal.json 의 idx ${MIG_N_J}개"
case "$MIG_STATE" in
  DONE) ok "볼륨이 **이미 $AS_WANT 이다** — 묶음을 이미 풀었거나 다시 돌리는 중이다"
        check_new_migs || true ;;
  OLD)  if [ "$MODE" = check ]; then
          hm "볼륨이 아직 $AS_HAVE 이다 — **올리기 전이면 정상**이다. --migrate 가 갈아 끼운다"
        else
          ok "볼륨이 $AS_HAVE 이다 (--migrate 가 $AS_WANT 로 갈아 끼운다)"
        fi
        if [ -s "$MIGTAR" ]; then
          say "묶음이 있다: $MIGTAR ($(stat -c %s "$MIGTAR" 2>/dev/null)바이트 · md5 $(md5sum "$MIGTAR" | awk '{print $1}'))"
          # 🔴 풀기 전에 **안을 센다.** 「파일이 왔다」와 「담겼다」는 다르다.
          TSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -c '^drizzle/[0-9].*\.sql$')
          TJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
          say "묶음 안 — .sql ${TSQL:-?}장 · idx ${TJRN:-?}개"
          if [ "${TSQL:-0}" = "$AS_WANT" ] && [ "${TJRN:-0}" = "$AS_WANT" ]; then
            ok "묶음 안이 $AS_WANT 이다 (풀면 볼륨이 맞아진다)"
          else
            bad "🔴 묶음 안이 .sql ${TSQL:-?} · idx ${TJRN:-?} 다 — **$AS_WANT 이어야 한다.** 다시 묶어 올리세요"
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
            hm "묶음의 잰 값이 이 파일에 없다 — 39-build.sh 의 출력에서 MIGTAR_SIZE·MIGTAR_MD5 를 채우세요"
          fi
        else
          if [ "$MODE" = check ]; then
            hm "묶음이 아직 없다: $MIGTAR — **올리기 전이면 정상**이다"
          else
            bad "🔴 묶음이 없다: $MIGTAR — 이것 없이는 $AS_WANT 로 못 간다"
          fi
          say "올리는 법 (개발 PC · PowerShell):"
          cmd "cd \"C:/Users/희만/Desktop/Development/_images-48\""
          cmd "scp -O as-migrations.tar.gz dss-nas:$INCOMING/"
          say "🔴 tar 에 드라이브 문자(C:)를 주지 마세요 — 원격 호스트로 읽습니다."
        fi ;;
  NODIR) bad "🔴 $MIGDIR 폴더가 **없다** — compose 가 $AS_TOOLS_SVC 에 붙이는 그 폴더다" ;;
  *)    bad "🔴 볼륨이 $AS_HAVE 도 $AS_WANT 도 아니다 (.sql ${MIG_N_SQL} · idx ${MIG_N_J})"
        say "→ 고치지 말고 **먼저 알리세요.**"; doubt ;;
esac

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
  printf '%s\n' "  🔴 **TARS 의 빈 칸이 ${BLANK}줄 있다.** 51-build.sh --go 가 끝에 찍어 주는"
  printf '%s\n' "     **두 줄**로 이 파일의 TARS 두 줄을 통째로 갈아 끼우세요."
fi
# 🔵 되돌릴 길 — 옛 태그가 남아 있는가(앱 하나만. 도구는 되돌리지 않는다)
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
  printf '%s\n' "🔵 **아무것도 안 바꿨다.**"
  printf '%s\n' "🔴 다음 차례: --count(앞) → **--templates-prep → scp 양식 → --templates-apply**"
  printf '%s\n' "   → scp tar → --preload → (다시 --check) → --go → --count(뒤)"
  printf '%s\n' "🔴 올리기 전에 돌리면 ? 가 여럿 나오는 것이 **정상**이다 (tar 둘 · 양식 다섯)."
  printf '%s\n' "🔴 **양식 줄은 --go 에서 ✗ 가 됩니다** — 그 다섯이 들어가 있어야 --go 가 섭니다."
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
  say "실린 이미지 ${LOADED}개 (기대 2)"
  if [ "$LOADED" = "2" ]; then ok "둘이 다 실렸다"
  else bad "🔴 ${LOADED}/2 개만 실렸다 — TARS 가 비었거나 tar 가 모자란다"; fi
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
  printf '%s\n' "🔵 **들여놓기만 했다 — 아직 안 갈아 끼웠다.** 다음: --check 를 다시 → 🔴 --migrate → --go"
  printf '%s\n' "🔴 **이 배포는 마이그레이션 3건이다**(0121·0122·0123). --go 앞에 --migrate 를 반드시 돌립니다."
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

if [ "$MODE" = migrate ]; then
  printf '\n== 4-나. 🔴 마이그레이션 — A/S DB 가 바뀐다 (%s → %s)\n' "$AS_HAVE" "$AS_WANT"
  if [ "$FAIL" != 0 ]; then printf '\n🔴 위에 ✗ 가 있다 — **DB 를 안 건드리고 멈춘다.**\n'; exit 1; fi

  # ── 7-ㄱ. 🔴 지금 이 자리에서 덤프를 뜬다 ───────────────────────────
  #   🔴 **이것이 되돌릴 길이다.** 야간 백업(02:30)을 기다리지 않는다.
  #      마이그레이션은 되돌아가지 않으므로, 덤프 없이는 시작하지 않는다.
  printf '\n    ── 먼저 덤프를 뜬다\n'
  DUMP="$BKDB/dss_as-v48-$STAMP.dump"
  if "$DOCKER" exec -i "$AS_BOX" sh -c 'pg_dump -U "$POSTGRES_USER" -d dss_as -Fc' > "$DUMP" 2>/dev/null; then
    DSZ=$(stat -c %s "$DUMP" 2>/dev/null || wc -c < "$DUMP")
    say "덤프 $DUMP (${DSZ:-?}바이트)"
    # 🔴 「파일이 생겼다」와 「쓸 만한 덤프다」는 다르다. 빈 파일도 생긴다.
    if [ "${DSZ:-0}" -gt 10240 ]; then ok "덤프가 ${DSZ}바이트다 (10KB 넘음)"
    else bad "덤프가 ${DSZ:-0}바이트뿐이다 — 쓸 수 없다. **DB 를 안 건드리고 멈춘다**"; fi
    # 🔴 **속을 본다.** -Fc 덤프는 첫 다섯 글자가 PGDMP 다. 파이프로 pg_restore 를
    #    먹이는 길은 판에 따라 「읽을 수 없는 보관본」으로 죽으므로 쓰지 않는다.
    MAGIC=$(head -c 5 "$DUMP" 2>/dev/null)
    say "덤프 머리 다섯 글자: ${MAGIC:-없음}"
    [ "$MAGIC" = "PGDMP" ] && ok "제대로 된 -Fc 덤프다" || bad "머리가 PGDMP 가 아니다 — 덤프가 아니거나 깨졌다"
    chmod 600 "$DUMP" 2>/dev/null
  else
    bad "덤프를 못 떴다 — **DB 를 안 건드리고 멈춘다**"
  fi
  say "⚠️ PO 가 **같은 $AS_DB 를 보고 있다** — 덤프 중에 PO 에서 저장한 것은 이"
  say "   덤프에 안 들어갈 수 있다. 그래서 이것은 마지막 수단이고, 되돌리기의"
  say "   기본은 **앱만 되돌리고 DB 는 그대로 두는 것**이다(표·칸을 더하기만 했다)."
  if [ "$FAIL" != 0 ]; then printf '\n🔴 되돌릴 길이 없다 — **멈춘다.**\n'; exit 1; fi

  # ── 7-ㄴ. 🔴 적용 전 줄 수를 적어 둔다 ──────────────────────────────
  printf '\n    ── 적용 전 줄 수 (적용 뒤에 **그대로여야** 한다)\n'
  CNT_BEFORE=""
  for F in $AS_COUNT_TABLES; do
    V=$(pgn "$AS_BOX" "$AS_DB" "select count(*) from $F")
    CNT_BEFORE="$CNT_BEFORE as.$F=${V:-?}"; say "dss_as.$F ${V:-?}줄"
  done

  # ── 7-ㄷ. 🔴 compose 의 tools-auth 를 :2 → :3 으로 ──────────────────
  #   🔴 37번이 한 그 방식 그대로 — 사본을 먼저 뜨고, image: 줄이 **꼭 하나만**
  #      달라졌는지 세고, 어긋나면 **사본으로 되돌리고 멈춘다.**
  #   🔵 tools-auth 는 profiles: [tools] 라 평소에 뜨지 않는다. 도는 컨테이너는
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
  APPB=$(app_img_lines)            # 🔴 앱 셋은 **하나도 안 바뀌어야** 한다
  TAL=$(img_line "$AS_TOOLS_SVC") || { bad "$AS_TOOLS_SVC 를 못 찾았다"; rm -f "$TB" "$TA"; exit 1; }
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
    # 🔴 앱 셋은 --go 의 일이다. 여기서 바뀌면 안 된다.
    [ "$APPA" = "$APPB" ] && ok "앱 셋의 image: 줄은 하나도 안 바뀌었다 (--go 의 일이다)" \
      || bad "🔴 앱 image: 줄이 바뀌었다 — 이 단계가 건드릴 자리가 아니다"
    dc config -q >/dev/null 2>&1 && ok "compose 문법이 통과했다" || bad "문법이 깨졌다"
    rm -f "$TB" "$TA"
    if [ "$FAIL" != 0 ]; then
      printf '\n🔴 어긋났다 — **사본으로 되돌리고 DB 는 안 건드린다.**\n'
      cp "$BK" "$CF"; say "되돌렸다. 지금 줄 수 $(wc -l < "$CF") (원래 $TL0)"
      exit 1
    fi
  fi

  # ── 7-ㄹ. 🔴 도구 이미지 안을 센다 — 비상구가 실제로 들어갔는가 ─────
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

  # ── 7-ㅁ. 🔴 볼륨을 121 로 갈아 끼운다 ──────────────────────────────
  printf '\n    ── A/S 마이그레이션 볼륨을 %s 로\n' "$AS_WANT"
  read_migdir
  if [ "$MIG_STATE" = OLD ]; then
    if [ ! -s "$MIGTAR" ]; then
      bad "🔴 볼륨이 아직 $AS_HAVE 인데 갈아 끼울 묶음이 없다: $MIGTAR"
      printf '\n🔴 **DB 도 앱도 그대로다.** 묶음을 올린 뒤 다시 부르세요.\n'
      exit 1
    fi
    place_migs || { printf '\n🔴 **DB 도 앱도 그대로다.**\n'; exit 1; }
    read_migdir
  fi
  say "지금 $MIGDIR — .sql ${MIG_N_SQL}장 · meta/_journal.json 의 idx ${MIG_N_J}개"
  [ "$MIG_N_SQL" = "$AS_WANT" ] && ok ".sql 이 ${MIG_N_SQL}장이다" \
    || bad ".sql 이 ${AS_WANT}장이 아니다 (${MIG_N_SQL}장)"
  [ "$MIG_N_J" = "$AS_WANT" ] && ok "meta/_journal.json 의 idx 가 ${MIG_N_J}개다" \
    || bad "idx 가 ${AS_WANT}개가 아니다 (${MIG_N_J}개) — 🔴 적용이 **0건으로 끝난다**"
  check_new_migs || true
  if [ "$FAIL" != 0 ]; then printf '\n🔴 마이그레이션 파일이 온전하지 않다 — **DB 도 앱도 그대로다.**\n'; exit 1; fi
  # 🔴 컨테이너가 **실제로 그 폴더를 읽는지** 본다. 겉이 아니라 결과다 —
  #    호스트에서 보이는 것과 컨테이너 안에서 보이는 것이 다를 수 있다.
  INSQL=$(dct run --rm --entrypoint sh "$AS_TOOLS_SVC" -c "ls -1 $IMG_MIGDIR/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r' | tail -1)
  say "$AS_TOOLS_SVC 안에서 본 $IMG_MIGDIR 의 .sql: ${INSQL:-?}장"
  if [ "${INSQL:-0}" = "$AS_WANT" ]; then ok "컨테이너 안에서도 $AS_WANT 장이다 (볼륨이 제대로 붙었다)"
  else bad "컨테이너 안이 ${INSQL:-?}장이다 — $AS_WANT 장이어야 한다. **0건으로 끝날 수 있다**"; fi
  if [ "$FAIL" != 0 ]; then printf '\n🔴 **DB 도 앱도 그대로다.** 멈춘다.\n'; exit 1; fi

  # ── 7-ㅂ. 적용 전 preflight — 사라질 자료가 있는지 ──────────────────
  printf '\n    ── 적용 전 db:preflight (앱은 아직 옛 판으로 살아 있다)\n'
  dct run --rm "$AS_TOOLS_SVC" npm run db:preflight 2>&1 | tail -20 | sed 's/^/    /'
  PRC=${PIPESTATUS[0]}
  say "(종료 코드 $PRC — 기대 0 · 대기 **2건**)"
  if [ "$PRC" != 0 ]; then
    bad "db:preflight 가 0 이 아니다 ($PRC) — 사라질 자료가 있다는 뜻이다"
    say "→ 🔴 0121·0122·0123 에는 그럴 문장이 없다(지우는 문장 0줄을 위에서 셌다). **다른 것이 섞였다.**"
    printf '\n🔴 **DB 를 안 건드리고 멈춘다.** 앱 셋은 그대로 돈다.\n'
    exit 1
  fi

  printf '\n'
  say "🔴 이제 DB 를 바꿉니다. 그만두려면 **20초 안에 Ctrl+C**."
  say "   지금 Ctrl+C 하면 DB 는 손대지 않은 채로 남습니다."
  say "   (볼륨은 이미 $AS_WANT 로 바뀌었지만 그것만으로는 아무 일도 안 일어납니다 —"
  say "    읽는 것은 $AS_TOOLS_SVC 뿐이고 부를 때만 잠깐 돕니다.)"
  sleep 20

  # ── 7-ㅅ. 돌린다 ────────────────────────────────────────────────────
  printf '\n    ── 돌린다\n'
  if [ "$MIG_AS0" = "$AS_WANT" ]; then
    ok "이미 $AS_WANT 이다 — 건너뛴다 (drizzle 은 다시 돌려도 안전하다)"
  else
    dct run --rm "$AS_TOOLS_SVC" npm run db:migrate 2>&1 | tail -25 | sed 's/^/    /'
    RC=${PIPESTATUS[0]}
    if [ "$RC" = 0 ]; then ok "A/S db:migrate 끝 (종료 코드 0)"
    else
      bad "A/S db:migrate 실패 (종료 코드 $RC)"
      say "🔵 앱 셋은 **그대로 옛 판으로 돕니다.** 직원이 느끼는 것이 없습니다."
      printf '\n🔴 덤프: %s\n' "$DUMP"
      exit 1
    fi
  fi

  # ── 7-ㅇ. 🔴 값으로 확인 (겉이 아니라 결과) ─────────────────────────
  printf '\n    ── 🔴 값으로 확인\n'
  MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
  T1=$(has_table  "$AS_BOX" "$AS_DB" "$AS_NEW_TABLE")
  C1=$(has_column "$AS_BOX" "$AS_DB" "$AS_NEW_COL_TABLE" "$AS_NEW_COL")
  C2=$(has_column "$AS_BOX" "$AS_DB" "$AS_NEW_COL2_TABLE" "$AS_NEW_COL2")
  I1=$(has_index  "$AS_BOX" "$AS_DB" "$AS_NEW_INDEX")
  [ "${T1:-0}" = "1" ] && ok "0121 — 표 $AS_NEW_TABLE 가 생겼다" || bad "🔴 표 $AS_NEW_TABLE 가 없다"
  [ "${C2:-0}" = "1" ] && ok "0122 — 칸 $AS_NEW_COL2_TABLE.$AS_NEW_COL2 이 생겼다" || bad "🔴 칸 $AS_NEW_COL2 이 없다"
  [ "${C1:-0}" = "1" ] && ok "0123 — 칸 $AS_NEW_COL_TABLE.$AS_NEW_COL 이 생겼다" || bad "🔴 칸 $AS_NEW_COL 이 없다"
  [ "${I1:-0}" = "1" ] && ok "0123 — 인덱스 $AS_NEW_INDEX 가 생겼다" || bad "🔴 인덱스가 없다"

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

  printf '\n    ── 🔴 앱 셋이 **여전히 옛 판으로** 도는가 (--go 가 아직 안 돌았다)\n'
  "$DOCKER" ps --format '{{.Names}}\t{{.Image}}' 2>/dev/null | sort | sed 's/^/      /'

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$FAIL" = 0 ]; then
    printf '%s\n' "✅ A/S DB 가 바뀌었다. **앱 셋은 아직 옛 판이다.** 다음: --go"
    printf '%s\n' "  🔵 0119 는 표 하나를, 0120 은 칸 하나를 더하기만 한다 — 옛 판 3.1 이"
    printf '%s\n' "     그것을 몰라도 멀쩡히 돈다. 그래서 --rollback 으로 앱만 되돌릴 수 있다."
    printf '%s\n' "  🔴 되돌릴 길(마이그레이션 전 덤프): $DUMP"
    printf '%s\n' "  🔵 옛 볼륨: $MIGDIR.old — **그대로 두세요**"
    printf '%s\n' "  🔵 compose 의 $AS_TOOLS_SVC 도 $TOOLS_NEW 가 됐다 (사본: $BK)"
    printf '%s\n' "     비상구 둘이 이제 컨테이너에서 돈다 — 쓸 일이 생긴 날의 길:"
    printf '%s\n' "       cd /volume1/dss/deploy"
    printf '%s\n' "       $DOCKER compose -f docker-compose.nas.yml --env-file .env.nas \\"
    printf '%s\n' "         --profile tools run --rm $AS_TOOLS_SVC npm run admin:promote"
  else
    printf '%s\n' "🔴 위 ✗ 를 보세요. 🔵 마이그레이션은 **다시 돌려도 안전하다**: bash $0 --migrate"
  fi
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi


# ── 5. --go / --rollback : compose 의 image: 줄을 바꾼다 ─────────────
#  🔴 --go 는 **둘**(app-as·tools-as)을 고친다. --rollback 은 **app-as 하나**만
#     되돌린다 — 도구는 :10 그대로 둔다(39·41~49번과 같은 판단).
#  🔴 **app-po 줄은 어느 모드에서도 안 건드린다.**
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
# 🔴 **남의 image: 줄을 건드리면 안 된다.** --go 는 둘(app-as·tools-as),
#    --rollback 은 하나(app-as)만 달라져야 한다.
#    🔴 49번은 3/2 였다 — **PO 가 빠져서 하나씩 줄었다.** 여기가 PO 를 안 건드렸다는
#       기계적 증거다.
if [ "$MODE" = go ]; then WANT_DIFF=2; else WANT_DIFF=1; fi
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
#     API 계약도 안 바뀌었다(A/S 쪽 src/app/api diff 가 0줄 · 아래 7절이 PO 가
#     그대로 도는지 다시 본다).
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
PO_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:13600/" 2>/dev/null)
say "dss-po — 이미지 ${PO_RUN:-?} · 127.0.0.1:13600 → ${PO_CODE:-없음}"
[ -n "${PO_ID0:-}" ] && [ "${PO_ID0:-x}" = "${PO_ID1:-y}" ] && ok "dss-po 가 **그대로다**(상자 번호가 안 바뀌었다 — 안 건드렸다)" \
  || hm "dss-po 의 상자 번호가 달라졌다 (${PO_ID0:0:12} -> ${PO_ID1:0:12}) — 안 건드렸어야 한다. 사람이 보세요"
printf '%s' "$PO_CODE" | grep -qE '200|30[1237]' && ok "dss-po 가 응답한다 ($PO_CODE · PO 는 303 으로 로그인에 보낸다)" \
  || bad "dss-po 응답이 ${PO_CODE:-없음}"

# 🔴 DB — 마이그레이션 수가 **여전히** 그대로인가 (이 배포는 DB 구조를 안 건드린다)
MIG_AS1=$(mig_count "$AS_BOX" "$AS_DB")
say "마이그레이션 ${MIG_AS0:-?} -> ${MIG_AS1:-?} ($AS_WANT 여야 한다)"
[ "${MIG_AS1:-x}" = "$AS_WANT" ] && ok "$AS_WANT 다 (0121·0122·0123 이 적용됐다)" \
  || bad "🔴 ${MIG_AS1:-?} 다 — $AS_WANT 여야 한다. **--migrate 를 안 돌렸거나 덜 돌았다**"

# 🔴 **양식을 다시 잰다** — 교체 뒤에도 그대로인지, 그리고 **새 앱이 보는지.**
#    🔵 --go 에서는 block 이다. 여기서 ✗ 가 나면 양식이 중간에 바뀐 것이다.
if [ "$MODE" = go ]; then templates_check block; else templates_check soft; fi

# 🔴 **PO 권한을 다시 잰다** — 앱을 안 갈아 끼웠으니 답이 같아야 하지만,
#    **같은지를 봐야** 안다.
po_write_privilege_check soft

# 🔴 도구 태그가 제대로 섰는지 + 이미지 안이 온전한지 다시 센다
TL=$(img_line "$AS_TOOLS_SVC")
if [ -n "${TL:-}" ]; then
  TCUR=$(tag_at "$TL")
  # 🔵 --go 도 --rollback 도 도구 기대값은 **$TOOLS_NEW 로 같다** — 되돌려도
  #    도구는 :10 그대로 둔다(머리말 ⑥).
  [ "$TCUR" = "$TOOLS_NEW" ] && ok "$AS_TOOLS_SVC 가 $TOOLS_NEW 다" \
    || bad "$AS_TOOLS_SVC 의 태그가 $TCUR 다 — $TOOLS_NEW 를 기대했다"
  "$DOCKER" image inspect "$TCUR" >/dev/null 2>&1 && ok "$TCUR 이미지가 NAS 에 있다" \
    || bad "$TCUR 이미지가 NAS 에 없다 — 다음에 부를 때 못 쓴다"
fi
if [ "$MODE" = go ]; then tools_inside_check; fi
# 🔴 42번에서 넣은 검사는 **그대로 둔다**.
if [ "$MODE" = go ]; then kyosan_folder_check; fi

# 🔴 **안 건드린 아홉이 그대로 도는지** 센다 — 「옆으로 안 샜다」는 증거다.
printf '\n    ── 안 건드린 아홉 (그대로여야 한다 · 49번의 여덟에 dss-po 가 늘었다)\n'
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
  printf '%s\n' ""
  printf '%s\n' "🔵 **백필은 다시 돌리지 않는다.** 44~49번과 같다 — 까닭:"
  printf '%s\n' "   · 백필은 2026-10-29 새벽에 283건이 끝났다."
  printf '%s\n' "   · 이번 판은 **견적서·보고서의 모양**이다. 연락서를 읽는 규칙과 무관하다."
  printf '%s\n' "   🔵 도구는 올렸지만 돌릴 까닭은 없다 — 올리는 것과 돌리는 것은 다른 일이다."
  printf '%s\n' ""
  printf '%s\n' "🔵 **이미 만들어 둔 견적서·보고서 파일은 안 바뀐다.** 바뀌는 것은 **이제부터**"
  printf '%s\n' "   만드는 파일과 화면입니다. 지난 문서를 다시 내보내면 새 모양으로 나옵니다."
  printf '%s\n' ""
  if [ "$MODE" = go ]; then
    printf '%s\n' "🔵 **세 도구로 수를 세어 --go 전과 견줘 두세요 (읽기만 합니다):**"
    printf '%s\n' "      bash $0 --count"
    printf '%s\n' "   🔵 이번 배포는 그 수들과 **상관이 없습니다** — 달라졌다면 그 사이에 사람이"
    printf '%s\n' "      저장한 것입니다."
    printf '%s\n' ""
  fi
  printf '%s\n' "🔴 **마지막은 눈입니다** — 이번 판은 볼 곳이 **다섯**입니다."
  printf '%s\n' ""
  printf '%s\n' "  ① 🔴 **견적서 → 제너레이터 O/H 양식으로 미리보기**"
  printf '%s\n' "     금액 묶음이 **1) 부품 비용 · 2) OH 부품 비용 · 3) 작업비** 세 칸이어야 합니다."
  printf '%s\n' "     🔴 **화면의 번호와 내려받은 엑셀의 번호가 같아야** 합니다 — 둘 다 3) 입니다."
  printf '%s\n' "     🔵 양식 파일을 10-31 에 2) → 3) 으로 고쳤고, 이번 코드가 화면을 거기 맞췄습니다."
  printf '%s\n' "     🔴 화면만 3) 이고 파일이 2) 면 **양식이 안 올라간 것입니다**(--templates-apply)."
  printf '%s\n' "     🔵 매쳐 양식은 번호 모양이 다릅니다(1. 2.) — 그것이 맞습니다."
  printf '%s\n' ""
  printf '%s\n' "  ② 🔴 **견적서 → 절사 금액이 0원인 건을 엑셀로 내보내기**"
  printf '%s\n' "     절사 줄의 금액 칸이 **비어 보여야** 합니다(0 이 안 보입니다)."
  printf '%s\n' "     🔵 양식에서는 「0이면 흰 글씨」 규칙으로 숨기는데, 그 규칙이 줄을 안 따라와"
  printf '%s\n' "        부품 수가 다른 건에서 0 이 그대로 찍혀 나갔습니다(10-31 신고)."
  printf '%s\n' "     🔴 **부품 수가 다른 건을 둘 이상** 보세요 — 한 건만 보면 우연히 맞을 수 있습니다."
  printf '%s\n' ""
  printf '%s\n' "  ③ 🔴 **수리/검사 보고서 → 본문이 짧은 건으로 미리보기와 엑셀**"
  printf '%s\n' "     · 구역 사이가 **언제나 한 줄**이어야 합니다(예전엔 7~9줄까지 벌어졌습니다)."
  printf '%s\n' "     · 맺음 표시(～이 상～) **위아래가 세 줄씩**이어야 합니다."
  printf '%s\n' "     · 맺음 표시가 상자 한가운데가 아니라 **세 열 오른쪽**에 있어야 합니다."
  printf '%s\n' "     · 상자 아래가 열 줄씩 비지 않고 **비고·담당·승인·문서번호가 위로 당겨져** 있어야 합니다."
  printf '%s\n' "     🔴 **엑셀 파일을 Excel 로 열어 보세요** — 병합이 겹치면 Excel 이 열기를 거부합니다."
  printf '%s\n' "        그것이 이번 판에서 가장 조용히 깨질 자리입니다."
  printf '%s\n' "     🔴 **매쳐 건과 제너레이터 건을 둘 다** 보세요 — 양식이 서로 다릅니다."
  printf '%s\n' ""
  printf '%s\n' "  ④ 🔴 **견적서 결재 알림(종)을 눌러 보기**"
  printf '%s\n' "     바로 **[견적서 결재] 탭**이 열려야 합니다(예전엔 [견적서 수정] 탭에서 멈췄습니다)."
  printf '%s\n' "     그리고 **결재 올린 견적서를 고쳐 저장하면 그 결재가 자동으로 반려**되어야 합니다."
  printf '%s\n' ""
  printf '%s\n' "  ⑤ 🔴 **고치던 것을 저장하지 않고 화면을 떠나 보기**"
  printf '%s\n' "     「저장 안 된 내용이 있습니다」를 **묻고** 나가야 합니다."
  printf '%s\n' "     🔵 저장 팝업(0.5초 뒤 저절로 닫힘)이 **아닙니다** — 읽고 고르는 상자입니다."
  printf '%s\n' ""
  printf '%s\n' "  🔵 **아무것도 안 바뀐 것처럼 보이면** app-as 가 정말 새 태그로 도는지(위 7절) 먼저"
  printf '%s\n' "     보시고, 맞다면 알려 주세요."
  printf '%s\n' ""
  printf '%s\n' "  되돌리려면:  bash $0 --rollback   (app-as 만 되돌립니다. DB 를 안 건드렸으니"
  printf '%s\n' "               자료 손실이 없습니다. 🔵 도구는 $TOOLS_NEW 그대로 둡니다)"
  printf '%s\n' "  🔴 **양식은 --rollback 으로 안 돌아갑니다.** 되돌리려면:"
  printf '%s\n' "       cp -a $D/backups/as-templates-<날짜시각>/. $TPLDIR/"
  printf '%s\n' "     🔵 그 폴더 이름은 --templates-prep 가 찍어 주었습니다. 목록:"
  ls -1d "$D/backups/as-templates-"* 2>/dev/null | tail -3 | sed 's/^/       /'
else
  printf '%s\n' "🔴 위 ✗ 를 보세요. 되돌리려면:  bash $0 --rollback"
  printf '%s\n' "  compose 사본: $BK · 로그: $LOG"
  printf '%s\n' "  🔵 ✗ 가 **재고 관리 통로** 하나뿐이라면 되돌리기 전에 설정을 먼저 보세요 —"
  printf '%s\n' "     INVENTORY_API_BASE_URL · INVENTORY_API_TOKEN (env/as.env). 🔴 되돌려도 같은"
  printf '%s\n' "     설정 문제는 남습니다 — 옛 판도 같은 통로를 씁니다."
  printf '%s\n' "  🔴 ✗ 가 **양식**이라면 되돌리지 말고 **양식을 먼저 올리세요** —"
  printf '%s\n' "     --templates-prep → scp → --templates-apply → 다시 --go."
  printf '%s\n' "  🔴 ✗ 가 **PO 의 repair_cases 쓰기 권한**이라면 그것은 **이 배포가 만든 일이**"
  printf '%s\n' "     **아닙니다**(PO 를 안 건드립니다). 되돌려도 안 고쳐집니다 — 사람이 봐야 합니다."
fi
printf '%s\n' "────────────────────────────────────────────────────────────"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
