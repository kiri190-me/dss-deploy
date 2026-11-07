#!/bin/bash
# dss-deploy/nas/setup/54-build.sh — 쉰한째 배포 · 이미지 굽기 (2026-11-07)
#
# 🔴 **NAS 에서 돌리는 스크립트가 아니다.** 개발 PC 의 **Git Bash** 에서 돈다.
#    NAS 에 접속하지 않는다. ssh 도 scp 도 한 줄 없다.
#
# ── 돌리는 법 (개발 PC · PowerShell 에서 Git Bash 를 부른다) ──────────
#     cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#     & "C:\Program Files\Git\bin\bash.exe" ./54-build.sh --check
#     & "C:\Program Files\Git\bin\bash.exe" ./54-build.sh --go
#
#   🔴 **bash.exe 만 치면 WSL 이 잡힌다**(2026-11-04 에 걸렸다). WSL 에서 돌면
#      도커도 양식도 안 보이고 git 이 줄바꿈 때문에 **유령 diff** 를 내어 ✗ 가
#      셋 흩어져 난다. 단서는 로그의 뿌리 경로가 **/mnt/c/…** 인 것이다.
#      그래서 위처럼 **Git Bash 의 전체 경로를 큰따옴표로 묶어** 부른다.
#   🔴 **스크립트에 건네는 경로에는 역슬래시를 쓰지 않는다.** 역슬래시를 주면
#      bash 가 그것을 먹어 "C:Users희만Desktop…" 이 되어 No such file 이 난다.
#      위처럼 **폴더로 먼저 들어가서 ./54-build.sh** 로 부르면 그 함정이 없다.
#      🔵 51-deploy.sh 의 6~9줄 · 1152줄 · 1333줄에 역슬래시 예시가 아직 남아
#         있다. **거기서 베껴 오지 마라.**
#
#   둘째 인자로 tar 를 둘 폴더를 바꿀 수 있다(기본값은 Development/_images-51):
#     & "C:\Program Files\Git\bin\bash.exe" ./54-build.sh --go "/d/배포본/_images-51"
#
#   🔴 **docker build 와 docker save 는 이 스크립트가 직접 친다.** 대화 세션의
#      명령 분류기가 그 둘을 막으므로, **사람이 이 파일을 돌려야** 한다.
#      이 파일을 쓴 쪽은 **한 번도 굽지 않았다** — --check 만 돌려 보았다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **53-build.sh 에서 베꼈다가 「이번 판엔 거짓」이라 고친 것 여덟**
# ══════════════════════════════════════════════════════════════════════
#   틀과 절 구성은 53-build.sh(쉰째 · 어제)를 그대로 썼다. 다만 **그 파일이 참이라고
#   적어 둔 것 중 여덟 가지가 이번 판에는 거짓**이라, 하나씩 다시 재서 고쳤다.
#   🔴 「배포본은 지난 판의 전제를 업고 온다」가 이 저장소에 기록된 함정이다.
#
#   ① 🔴 **포털(dss-auth)을 안 굽는다.** 53번은 14판 만에 포털을 구웠다. 지금
#      dss-auth 의 HEAD 는 **f87bf7d** 로, 53번이 구운 그 HEAD **그대로**다
#      (2026-11-07 실측 · 이후 커밋 0). 그래서 **IDLE 표에 dss-auth 를 되돌려 놓았고**
#      수를 8 에서 **9** 로 고쳤다. 🔴 53번에는 「IDLE 에 dss-auth 가 있으면 ✗」라는
#      검사가 있었다 — **이번 판에는 그 판정이 거꾸로다**(있어야 한다). 2절이 그렇게 잰다.
#   ② 🔴 **마이그레이션이 0건이다.** 53번은 1건(0124)이라 「묶음을 반드시 보낸다 ·
#      기대값이 124 → 125 두 갈래」였다. 이번 범위의 drizzle/ 변경은 **0줄**이고
#      .sql 은 **125장 · idx 125개**이며 마지막이 **0124** 다 — 운영 볼륨도 기록도
#      53번이 이미 125 로 올려 놓았다. 🔴 **125 한 갈래로 고정**이다.
#      🔵 묶음은 그래도 만든다(아래 「보험」 절) — **보내지 않아도 배포는 선다.**
#   ③ 🔴 **공용 스키마(vendor/dss-core)가 안 움직였다.** 53번은 20bb394 → 460458a
#      로 한 칸 움직였다. 이번엔 **기준판(62a42be8)의 포인터도 460458a 이고 지금도
#      460458a** 다(2026-11-07 실측). 그래서 3절을 「움직였는가」에서 **「안 움직였는가」**
#      로 뒤집었다. 🔴 53번 글을 그대로 베끼면 멀쩡한 판이 ✗ 가 난다.
#   ④ 🔴 **npm 명령이 늘었다 — 41번 잣대가 이번엔 걸린다.** 53번은 「37 → 37 ·
#      package.json diff 0줄」이라 「안 걸린다」였다. 이번은 **37 → 39 · diff 14줄**이고
#      늘어난 둘이 **운영에서 돌리려고 만든 도구**다. 🔴 **이것이 이번 판에 도구
#      이미지를 굽는 첫째 까닭이고, 안 구우면 Missing script 가 난다.**
#   ⑤ 🔵 **tools 바깥에서 바뀐 파일이 0개다.** 53번은 다섯이었다(문서 둘 + drizzle 셋).
#      이번 37개는 **전부** scripts/ · src/ · package.json 안이다.
#   ⑥ 🔵 닫힘 · 표식 · 「이번에 생긴 파일」 목록을 **전부 이번 판 값으로** 다시 쟀다.
#   ⑦ 🔵 지난 판 tar 크기 둘을 **이번 판의 상대**로 갈았다(아래 TAR 견주기).
#   ⑧ 🔵 꼬리말을 갈았다 — 53번의 「결재선을 세우라」는 **아직 남아 있을 수 있는
#      할 일**이라 판정하지 않고 **--count 가 값을 찍게** 넘겼다(53번이 그렇게 했다).
#
# ── 이번에 굽는 것 — **저장소 하나, 이미지 둘** ───────────────────────
#     ① A/S 앱    dss-as:4.6        → **dss-as:4.7**        커밋 3  스테이지 기본(runner)
#     ② A/S 도구  dss-as-tools:13   → **dss-as-tools:14**   커밋 3  🔴 --target tools
#
#   🔵 그리고 **셋째 산출물** — A/S 마이그레이션 묶음 as-migrations.tar.gz.
#      🔴 **이번 판에는 보험이다.** 적용할 것이 0건이라 **안 보내도 배포는 선다.**
#      만드는 까닭은 52-build.sh 가 적어 둔 둘과 같다 — 운영 볼륨이 어떤 까닭으로
#      125 가 아닐 때 고치는 길이고, 그 절이 살아 있어야 다음에 1건이 생긴 날
#      39번까지 거슬러 가지 않는다. 치르는 값은 2.4MB 하나다.
#
#   🔴 **포털(dss-auth)은 안 굽는다** — HEAD 가 53번이 구운 f87bf7d 그대로다.
#   🔴 **PO(dss-po)도 안 굽는다** — HEAD 가 기준 SHA(9c1b2ef) 그대로다.
#   🔵 **양식(.xlsx)은 한 장도 안 올린다.** 이번 범위에 .xlsx 변경이 **0줄**이고,
#      개발 PC 의 양식 열하나가 53번이 적어 둔 바이트·md5 와 **전부 같았다**
#      (2026-11-07 실측 — 8절이 다시 잰다). 그래서 이 파일에는 **양식을 복사하는
#      절이 없다.** 🔴 **양식이 바뀌는 날 되살릴 곳**: 51-build.sh 의 8절과 꼬리말,
#      51-deploy.sh 의 --templates-prep(1056~1172줄) · --templates-apply(1174~1341줄).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 기준 SHA — **출처 둘을 맞대어 확인했다** (2026-11-07)
# ══════════════════════════════════════════════════════════════════════
#   ㄱ) **A/S — 62a42be8.**
#        · 53번(쉰째)이 올린 HEAD 다. 53-build.sh 86~96줄의 범위가
#          c6b2b271..**62a42be8** 이고 「커밋 10 · 파일 163」이다.
#        · 🔴 **dss-deploy/README.md 의 기준 SHA 표는 이 값을 아직 모른다.**
#          그 표(2026-11-06 09:30 갱신)는 A/S 를 **4.5 · c6b2b271** 로 적는다 —
#          **쉰째 배포 기록이 아직 안 적혔기 때문**이다. 🔴 표만 믿고 c6b2b271 로
#          세면 **쉰째가 이미 올린 커밋 열을 다시 센다.** README 자신이
#          「이 표 하나만 믿지 마라」라고 적어 둔 그 자리다.
#        · 🔵 저장소가 답하게 두었다 — 아래 2절의 merge-base --is-ancestor 와
#          커밋 수·파일 수가 어긋나면 거기서 ⚠️ 또는 ✗ 가 난다.
#   ㄴ) **포털 — f87bf7d.** 53번이 구운 HEAD 이고 지금 HEAD 와 같다(이후 커밋 0).
#        🔴 README 표는 아직 **52cbb19 · 2.0** 이라고 적는다. **낡았다.**
#   ㄷ) **PO — 9c1b2ef.** README 표와 지금 HEAD 가 같다(이후 커밋 0).
#
# ── 이번 범위의 커밋 — A/S **셋** · 포털 **0** · PO **0** ─────────────
#   A/S  62a42be8..4bbf0df1  (2026-11-07 실측: 커밋 3 · 파일 37)
#     4bbf0df1 [납기 지연]이 빌려 온 납기일도 본다 · 종 알림을 더한다
#     acad072e 납품일 ↔ 실제 출하일을 세는 도구 — 옮기기 전에 무엇이 어떻게 적혀 있나
#     f7b3a776 기타건 견적서 폴더 — 번호의 띄어쓰기 한 칸을 너그럽게 본다
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 A/S 도구(dss-as-tools)를 **왜 굽는가** — 잣대 셋이 **전부** 걸린다
# ══════════════════════════════════════════════════════════════════════
#   잣대는 41·48·52·53번이 쓰던 셋 그대로다:
#     ㄱ) npm 명령이 늘었나   ㄴ) 도구의 import 닫힘 안이 바뀌었나
#     ㄷ) tools 스테이지가 담는 것 중 바뀐 파일이 있나
#
#   ㄱ **걸린다. 🔴 이번 판의 핵심이다.** package.json diff **14줄** · scripts 항목
#      **37 → 39**. 늘어난 둘이 바로 **운영에서 돌려 수를 받으려고 만든 도구**다:
#          check:due-date-overdue      scripts/check-due-date-overdue.ts
#          check:delivered-date-sync   scripts/check-delivered-date-sync.ts
#                                      (+ scripts/lib/delivered-date-sync-survey.ts)
#      🔴 **안 구우면 운영에서 npm run 이 Missing script 로 끝나고, 이번 배포의
#         목적 절반이 사라진다.** 41번이 정확히 그 실패를 한 번 겪었다.
#      🔵 53번은 여기가 **안 걸렸다**(37 → 37). 그 글을 베껴 오면 「굽지 않아도
#         된다」가 되어 이번 판의 가장 큰 실수가 된다.
#   ㄴ **걸린다.** npm 명령이 가리키는 scripts/*.ts **27개**를 시작점으로 닫힘을
#      재어 **192개**(못 푼 상대경로 0 · 2026-11-07 실측). 그 192 와 바뀐 37 이
#      겹치는 것이 **9개**이고, 그중 **다섯은 기준판에 아예 없던 파일**이다.
#      🔵 재는 법은 48·52·53번과 같은 결이다(주석을 걷고, 상대경로 · '@/' ·
#         '@dss/core/*' · '@dss/ui' 를 따라가고, export … from 과 타입 전용
#         import 까지 따라간다). 🔴 **53번이 적은 233 과 수가 다르다** — 시작점
#         고르는 법과 재는 도구가 다르기 때문이다. 🔵 **굽는 판정은 그 수에
#         안 달려 있다**(겹치는 것이 1개만 돼도 굽는다). 아래 5절-ㄹ 은 **적어 둔
#         아홉이 저장소에 아직 있고 정말 바뀌었는지**를 값으로 본다.
#   ㄷ **걸린다.** tools 스테이지가 담는 것(package.json · tsconfig.json ·
#      drizzle.config.ts · scripts/ · src/ · vendor/) 중 바뀐 파일 **37개**.
#      🔵 **바깥은 0개다** — 이번 범위에는 문서도 drizzle/ 도 안 바뀌었다.
#      🔴 53번은 바깥이 다섯이었다. 그 수를 베껴 오면 ⚠️ 가 거짓으로 난다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 새 도구 둘은 **읽기만 한다** — 그런데 글자로 세면 함정이 하나 있다
# ══════════════════════════════════════════════════════════════════════
#   둘 다 쓰는 문장이 **0줄**이고 트랜잭션도 **0번**이다(2026-11-07 실측).
#   🔴 그런데 **'--apply' 라는 글자는 check-delivered-date-sync.ts 에 1번 나온다** —
#      **머리말 주석 안**이다("--apply 같은 깃발도 **일부러** 두지 않았다").
#      🔴 그래서 「--apply 가 0번인가」로 읽기 전용을 재면 **멀쩡한 도구가 ✗** 가 된다.
#      이 저장소에 기록된 「소스 글자로 재는 검사는 주석을 먼저 센다」와 같은 뿌리다.
#   🔵 그래서 이 파일은 **부르는 꼴**로 센다 — '.insert(' · '.update(' · '.delete('.
#      저장소 쪽에서도 같은 잣대를 쓰는 짝이 있다:
#      scripts/check-tools-read-only-source.test.ts (이번 범위에 함께 들어왔다).
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
# ── 🔴 tar 크기를 **두 번** 견준다 ────────────────────────────────────
#   ① **지난 판 tar 와** 견준다. 적어 둔 값의 출처:
#        dss-as-4.6.tar       134326784  [실측] 2026-11-07 _images-50 에서 stat
#        dss-as-tools-13.tar  225127424  [실측] 2026-11-07 _images-50 에서 stat
#      🔴 **둘 다 한 판 전이라 25% 를 넘으면 ✗ 다**(strict).
#      🔵 53번에는 14판 전 기준값을 쓰는 loose 갈래가 있었다 — **이번 판에는
#         그 갈래를 쓰는 줄이 없다.** 그래도 코드는 남겨 둔다(다음에 오래된
#         기준값을 쓰는 날이 오면 그 자리가 필요하다).
#   ② **그 이미지 자신과** 견준다. 🔴 여기가 함정이라 가지를 둘로 나눴다:
#      · containerd 저장소면 'docker image inspect {{.Size}}' 가 **압축된 내용
#        크기**를 주어 tar 와 거의 같다(90~110%).
#      · 고전 저장소면 그 값이 **펼친 크기**라 tar 는 그 **1/4쯤**이다(10~45%).
#      🔴 **둘 중 어느 쪽인지 미리 못 정한다.** 한 잣대로 재면 **가짜 ✗** 가 난다.
#   🔴 **tar 지문은 'docker image inspect' 의 .Id 와 맞대지 않는다.** 그것은
#      애초에 다른 값이다. 맞댈 상대는 **빌드 로그의 'exporting config sha256:'** 이다.
#
# ── 🔴 이 환경의 함정 (36~53-build.sh 에서 그대로 가져온 처방) ────────
#   ① **경로에 한글이 있다.** 모든 경로를 큰따옴표로 감싸고, 저장소 자리를
#      이 파일의 자리에서 계산한다(SCRIPT_DIR → DEV).
#   ② 🔴 **tar 가 C: 를 원격 호스트로 읽는다.** to_unix() 가 C:/… 를 /c/… 로
#      바꾸고, docker save 는 작업 폴더로 **들어가서 상대경로**로 쓴다.
#      🔴 이 파일의 tar/docker save 어디에도 드라이브 문자가 들어가지 않는다.
#   ③ 🔵 docker build 는 개발 서버를 안 내려도 된다(.dockerignore 가 .next 를
#      막는다 — 아래 5절이 그것도 잰다). 다만 메모리는 다르다.
#   ④ 🔴 **이미지 안을 재는 명령에 한글을 넣지 않는다.** 한글을 argv 로 넘기면
#      깨지는 길이 열린다 — 아래 검사의 이름은 전부 ASCII 다.
#   ⑤ 🔵 목록은 **따옴표로 감싼 여러 줄 변수**로만 다루고 글롭으로 펴지 않는다.
#      🔴 「대괄호 폴더의 시험은 조용히 안 돈다」와 같은 뿌리다.
#   ⑥ 🔵 **양식 경로는 .env.local 에서 꼴이 두 가지다** — 앞 다섯은 빗금,
#      뒤 여섯은 **역빗금**이다(2026-11-07 실측으로 53번의 글이 여전히 맞았다).
#      그래서 8절은 이름을 끊기 전에 **반드시 to_unix() 를 거친다.**
#   ⑦ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 을 낸다.** 뒤에 「|| echo ?」
#      같은 안전망을 달면 **하필 바라던 0 에서만** 그것이 터져 값이 "0 ?" 가 된다
#      (2026-11-06 52-build.sh 에서 실제로 났다). 이 파일은 그 꼴을 **한 군데도
#      쓰지 않는다** — 셈을 받을 때는 「$( … || true )」 로 **종료 코드만** 가린다.
#   ⑧ 🔴 **tar | grep -q 를 if 에 바로 물리지 않는다.** 아래 set -uo pipefail 때문에
#      파이프라인의 어느 한 쪽이라도 0 이 아니면 if 가 거짓이 된다. grep -q 는 찾는
#      순간 끝내므로 앞의 tar 가 SIGPIPE 로 죽고 **파일이 있을 때 오히려 ✗** 가 난다
#      (2026-11-07 쉰째 배포에서 실제로 났다). **세어서 담고 비교하는 꼴**로만 쓴다.
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

# tar 안 manifest.json 의 Config 지문 (39~53-build.sh 의 것을 글자 그대로)
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
# 🔴 '네 칸 들여쓴 따옴표 줄'을 통째로 세면 dependencies 까지 섞인다.
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
#      🔴 **이번 판은 0 이다.** 53번은 3 이었다(0124.sql · 스냅샷 · _journal).
#         그 글을 베껴 오면 멀쩡한 판이 ✗ 가 난다.
#      🔴 「0 이면 통과」가 아니라 **적어 둔 수와 똑같아야** 한다.
#   🔵 일곱째 칸(커밋 수)은 ✗ 로 세지 않고 ⚠️ 로만 센다 — 어긋나면 표가 낡았다는
#      뜻이라 사람이 봐야 한다. A/S **셋**이다.
#   🔴 'astools' 는 **같은 저장소**를 --target tools 로 한 번 더 굽는 줄이다.
#      저장소를 세는 자리에서는 건너뛴다 — 두 번 세면 ✗ 도 두 번 센다.
#   🔵 열째 칸: strict = 25% 넘으면 ✗ · loose = 25% ⚠️ · 60% 넘으면 ✗ (머리말).
#      🔴 **이번 판에는 loose 줄이 없다** — 둘 다 한 판 전 값이다.
#   🔴 **포털 줄도 PO 줄도 없다.** 이번 판은 A/S 하나뿐이다.
SITES='
as|RF_Service_System|dss-as:4.7|62a42be8|-|0|3|134326784|dss-as-4.6.tar|strict
astools|RF_Service_System|dss-as-tools:14|62a42be8|tools|0|3|225127424|dss-as-tools-13.tar|strict
'
HOWMANY=2
AS_APP_TAG=dss-as:4.7
AS_TOOLS_TAG=dss-as-tools:14
# 🔵 되돌릴 판 — 54-deploy.sh --rollback 이 쓰는 그것이다.
AS_OLD_TAG=dss-as:4.6
AS_TOOLS_OLD_TAG=dss-as-tools:13

# ── 🔴 기대값과 그 출처 — 전부 [실측] 2026-11-07 개발 PC ───────────────
AS_BASE=62a42be8
AS_HEAD_SHORT=4bbf0df1
AUTH_BASE=f87bf7d
PO_BASE=9c1b2ef

# 🔴 A/S drizzle — **125 그대로다.** 53번이 0124 를 올려 125 가 됐고 이번엔 0건이다.
AS_SQL_WANT=125
AS_LAST_MIG=0124     # 🔵 53번이 올린 마지막
AS_NEXT_MIG=0125     # 🔴 이것이 생겼으면 전제(0건)가 깨진 것이다
# 🔴 **다음 번호를 셈으로 만들지 않는다.** bash 의 $(( )) 는 0 으로 시작하는 수를
#    **8진수**로 읽어 0124+1 이 85 가 된다 — 오류 없이 엉뚱한 파일을 찾는다.
#    그래서 글자로 적어 두고, 아래에서 이어지는 번호인지 한 번 맞대어 본다.
AS_LAST_MIG_FILE=0124_deep_masked_marvel.sql
# 🔵 묶음이 온전한지 볼 때 함께 보는 넷 — 48번의 셋 + 53번의 0124.
AS_KEEP_MIGS='0121 0122 0123 0124'
AS_KEEP_MIGS_WANT=4

# 🔴 「지우는 문장」의 잣대. 앱의 src/lib/db/migration-safety.ts 와 **같다**(19번 452줄).
#    🔵 이번 판에는 새 .sql 이 없지만 **묶음 안의 넷을 다시 센다** — 묶음을 보내는
#       날이 오면 그 넷이 통째로 볼륨을 갈아 끼우기 때문이다.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE|DELETE[[:space:]]+FROM'
MIG_DESTRUCT_WANT=0

# 서브모듈 포인터 둘. 🔴 **이번 판에는 둘 다 안 움직인다.**
#    🔵 53번은 dss-core 가 20bb394 → 460458a 로 움직였다. 이번엔 **기준판의
#       포인터도 460458a** 다(2026-11-07 실측) — 즉 안 움직였다.
AS_CORE_PIN=460458ad3ae1cd8703930cb7208d0c12391cee64
UI_PIN=1210d112f3d7d142942fa1811262dadaed293425
PO_CORE_PIN=8730c9433b4388a038349ab9a11ec633659da782

# 🔵 A/S — 저장소 전체 37 · tools 스테이지가 담는 것 37 · 바깥 **0**.
AS_ALL_CHANGED_WANT=37
AS_TOOLS_CHANGED_WANT=37
AS_OUTSIDE_WANT=0
# 🔴 포털·PO 는 0 이어야 한다(안 굽는다).
AUTH_CHANGED_WANT=0
PO_CHANGED_WANT=0

# 🔴 npm 명령 수 — **이번 판에는 늘었다.** 41번 잣대가 **걸린다.**
AS_NPM_WAS=37;  AS_NPM_NOW=39
AS_PKG_LINES_WANT=14
# 🔴 **이번에 생긴 둘** — 이 배포의 목적이다. 기준판에 0 · 지금 판에 1 이어야 한다.
AS_NEW_NPM="check:due-date-overdue check:delivered-date-sync"
AS_NEW_NPM_WANT=2
# 🔴 사라지면 안 되는 A/S 명령 아홉 — 48·52·53번이 올린 것 일곱 + 이번 둘.
AS_KEEP_NPM="check:target-shipment-missing check:due-date-inverted check:requested-due-date-sync check:due-date-overdue check:delivered-date-sync procedures:export procedures:import db:preflight db:migrate"
AS_KEEP_NPM_WANT=9

# ══ 🔴 A/S 도구 닫힘 — 시작점 27 · 닫힘 192 · 겹침 9 ══════════════════
#   🔵 2026-11-07 실측(못 푼 상대경로 0). 🔴 **그 파일이 아직 저장소에 있나**
#      가드를 그대로 둔다 — 이름이 바뀌었는데 0 이 나와 「안 바뀌었다」로 조용히
#      지나가는 길을 막는다.
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
# 🔴 그중 **기준판에 아예 없던 파일 다섯** — 이미지 안에서 존재만 봐도 새 판이다.
AS_BORN='
scripts/check-delivered-date-sync.ts
scripts/check-due-date-overdue.ts
scripts/lib/delivered-date-sync-survey.ts
src/lib/db/queries/repair-case-overdue-notifications.ts
src/lib/domain/repair-case-overdue.ts
'
AS_BORN_WANT=5

# ══ 🔴 「이번 판인가」를 글자로 가르는 표식 여섯 ═══════════════════════
#   🔴 전부 **기준판에 0번 · 지금 판에 1번 이상**이다(2026-11-07 실측).
#      이름은 모두 ASCII 다 — 한글을 argv 로 넘기면 깨지는 길이 열린다.
#   형식: 글자|파일
AS_MARKS='
REPAIR_CASE_DUE_DATE_OVERDUE|src/lib/domain/notifications.ts
countRepairCaseOverdueStages|src/lib/db/queries/repair-case-overdue-notifications.ts
isDueDateOverdue|src/lib/domain/repair-case-overdue.ts
LETTERS_SPACE_YEAR|src/lib/domain/quote-archive-naming.ts
quoteArchiveFolderNumberCandidates|src/lib/domain/quote-archive-naming.ts
foldBlankToNull|scripts/lib/delivered-date-sync-survey.ts
'
AS_MARKS_WANT=6

# 🔴 **구운 이미지 안에서 쓸 표식.** 기준판 src/ 에 **0파일** · 지금 판에 6파일이다
#    (2026-11-07 실측). 🔵 runner 이미지는 소스가 없고 .next/standalone 만 있는데,
#    이 글자는 알림 종류 **문자열 리터럴**이라 묶음 안에 박혀 나온다
#    (src/lib/db/queries/notifications.ts · src/lib/domain/notification-settings.ts).
#    그래서 앱 이미지도 「새 판인가」를 이 한 글자로 가를 수 있다.
BUILD_MARK=REPAIR_CASE_DUE_DATE_OVERDUE

# 🔴 **새 도구 둘이 정말 읽기만 하는가** — 부르는 꼴로 센다(머리말의 함정).
RO_WRITE_RE='\.insert\(|\.update\(|\.delete\('
RO_TOOLS='
scripts/check-due-date-overdue.ts
scripts/check-delivered-date-sync.ts
scripts/lib/delivered-date-sync-survey.ts
'
RO_TOOLS_WANT=3
# 🔵 저장소 쪽 짝 — 이 규율을 원본 글자로 지키는 시험이 이번 범위에 함께 들어왔다.
RO_TEST=scripts/check-tools-read-only-source.test.ts

# 🔴 PO 쪽에서 **모르는 거절 코드** — 53번에서 넘어온 것이다. 고치지 않고 세어서 알린다.
PO_GATEWAY=src/lib/server/as-gateway.ts
PO_MISSING_CODE=APPROVAL_REQUIRED
PO_MUT=src/lib/db/mutations/domestic-orders.ts

# ══ 🔴 양식 파일 — 이름|바이트|md5 ════════════════════════════════════
#   🔴 **이번 판에도 올릴 양식이 없다.** 열하나가 전부 53번이 적어 둔 값 그대로다
#      (2026-11-07 개발 PC 실측 — 바이트와 md5 가 글자 그대로 같았다).
#      이 절은 **「안 바뀌었다」를 확인하는 자리**이고 복사하는 절은 없다.
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
if [ -n "$OUTARG" ]; then OUT=$(to_unix "$OUTARG"); else OUT="$DEV/_images-51"; fi

case "$MODE" in
  --check|--go) ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check · --go\n' "$MODE"; exit 2 ;;
esac

ASDIR="$DEV/RF_Service_System"
AUTHDIR="$DEV/dss-auth"
PODIR="$DEV/dss-po"
COREDIR="$ASDIR/vendor/dss-core"

printf '%s\n' "쉰한째 배포 · 이미지 굽기   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  저장소 뿌리: $DEV"
printf '%s\n' "  tar 둘을 둘 자리: $OUT"
printf '%s\n' "  굽는 것: $AS_APP_TAG · $AS_TOOLS_TAG  (저장소 **하나** · 이미지 **둘**)"
printf '%s\n' "  올릴 HEAD: A/S $AS_HEAD_SHORT (기준 $AS_BASE 이후 커밋 3 · 파일 37)"
printf '%s\n' "  🔴 **도구 이미지가 이번 판의 핵심이다** — npm 명령이 37 → 39 로 늘었다"
printf '%s\n' "     (check:due-date-overdue · check:delivered-date-sync). 안 구우면 Missing script 다."
printf '%s\n' "  🔵 포털(dss-auth)은 **안 굽는다** — HEAD 가 53번이 구운 $AUTH_BASE 그대로다(2절)"
printf '%s\n' "  🔵 PO 도 **안 굽는다** — HEAD 가 기준 $PO_BASE 그대로다(2절)"
printf '%s\n' "  🔵 마이그레이션 **0건** — .sql 도 idx 도 $AS_SQL_WANT 그대로다(4절)"
printf '%s\n' "  🔵 공용 스키마 vendor/dss-core 는 **안 움직였다** — ${AS_CORE_PIN:0:7} 그대로(3절)"
printf '%s\n' "  🔵 양식은 **0장** — 열하나가 53번 값 그대로다(8절)"
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
      printf '%s\n' "         54-deploy.sh 꼬리말의 「볼 곳」과 5절의 파일 목록이다 — 사람이 보세요."
      git -C "$DIR" log --oneline "$BASE..HEAD" 2>/dev/null | head -12 | sed 's/^/      /'
    fi
    # 🔴 「0 이면 통과」가 아니다. 적어 둔 수와 **똑같아야** 한다.
    if [ "${m:-x}" = "$WANTMIG" ]; then
      printf '  ✓ %s drizzle/ 에서 달라진 파일 %s개 — 적어 둔 그대로 (이번 판은 **0건**이다)\n' "$REPO" "$m"
    else
      printf '  ✗ %s drizzle/ 에서 달라진 파일 %s개 — **%s개를 기대했다**. 멈추고 알릴 것\n' "$REPO" "${m:-?}" "$WANTMIG"
      printf '%s\n' "      🔴 늘었다면 이 배포의 설계가 틀렸다 — 54-deploy.sh 에 **적용하는 절이 없다.**"
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
if [ "$REPO_BAD" = "0" ]; then ok "A/S 가 깨끗하고 drizzle 변경 수가 적어 둔 그대로다 (0)"
else bad "저장소 검사에서 어긋난 것 ${REPO_BAD}가지 — 위 ✗ 를 보세요"; doubt; fi

# 🔴 **안 굽는 아홉도 재 둔다** — 「이번 범위에 커밋이 없다」를 짐작으로 적지
#    않는다. HEAD 가 기준 SHA 와 글자 그대로 같아야 한다.
#    🔴 **53번은 여덟이었다.** 거기에서 dss-auth 를 뺐었는데 **이번엔 안 굽는다** —
#       그래서 이 목록에 되돌려 놓았고, 수도 8 에서 **9** 로 고쳤다.
#       🔵 dss-auth 의 기준은 README 표의 52cbb19 가 **아니다.** 53번이 그 뒤
#          f87bf7d 를 dss-auth:2.1 로 구워 올렸다 — 그것이 지금 기준이다.
#    🔵 ✗ 가 나도 **이 배포를 막지 않는다**(⚠️ 로만 센다) — 다음 판의 범위가
#       늘었다는 뜻이다.
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
# 🔴 **dss-auth 가 이 목록에 돌아와 있는가** — 53번에서 그대로 베껴 오면 빠져 있다.
#    🔵 53번에는 정반대의 검사가 있었다(「남아 있으면 ✗」). **이번 판은 거꾸로다.**
if printf '%s\n' "$IDLE" | tr -d ' ' | grep -q '^dss-auth|'; then
  ok "IDLE 표에 dss-auth 가 있다 (이번 판은 포털을 **안 굽는다** — 53번에서 되돌린 자리다)"
else
  bad "🔴 IDLE 표에 dss-auth 가 없다 — **이번 판은 포털을 안 굽는다.** 53번에서 그대로 베꼈다"
  doubt
fi

# ── 3. 🔴 서브모듈 — 이번엔 **안 움직인다** ──────────────────────────
printf '\n== 3. 서브모듈 (A/S 둘 — 🔴 이번 판에는 **둘 다 안 움직인다**)\n'
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
# 🔴 **정말 안 움직였는가** — 기준판의 포인터가 **지금과 같아야** 「안 움직였다」가 선다.
#    🔵 53번은 여기가 반대였다(기준판이 옛 값이어야 「움직였다」가 섰다).
#    🔴 **움직였는데 「안 움직였다」로 적어 두면**, 공용 스키마가 바뀐 판에서
#       이미지 안 검사가 통째로 느슨해진다.
for pair in "vendor/dss-core $AS_CORE_PIN" "vendor/dss-ui $UI_PIN"; do
  set -- $pair
  WASPIN=$(git -C "$ASDIR" ls-tree "$AS_BASE" "$1" 2>/dev/null | awk '{print $3}')
  say "기준판 $AS_BASE 의 $1 = ${WASPIN:0:7}  (지금 ${2:0:7})"
  if [ "${WASPIN:-}" = "$2" ]; then
    ok "$1 가 기준판과 **같다** — 이번 판에 안 움직였다 (적어 둔 그대로)"
  elif [ -z "${WASPIN:-}" ]; then
    unk "기준판의 $1 포인터" "git ls-tree 가 아무것도 안 돌려줬다 — 기준 SHA 를 보세요"
  else
    bad "🔴 $1 가 기준판 ${WASPIN:0:7} → 지금 ${2:0:7} 로 **움직였다** — 안 움직인다고 적어 두었다"
    say "🔴 공용 묶음이 바뀌었다는 뜻이다. **고치지 말고 먼저 알리세요** —"
    say "   도구 이미지 안 검사(⑤)에 그 변경을 재는 줄을 더해야 한다(53-build.sh 가 그 본보기다)."
    doubt
  fi
done
# 🔵 그래도 **서브모듈 쪽에 안 받은 커밋이 있는지**는 본다 — 포인터가 같아도
#    공용 묶음 원격이 앞서 있으면 다음 판의 범위가 늘어난다. ⚠️ 로만 센다.
if [ -d "$COREDIR/.git" ] || [ -f "$COREDIR/.git" ]; then
  CORE_AHEAD=$(git -C "$COREDIR" rev-list --count "$AS_CORE_PIN..origin/main" 2>/dev/null)
  if isnum "${CORE_AHEAD:-}" && [ "${CORE_AHEAD:-0}" -gt 0 ]; then
    note "vendor/dss-core 의 origin/main 이 핀보다 ${CORE_AHEAD}커밋 앞서 있다 — **이 배포는 안 막는다**(핀으로 굽는다)"
  else
    say "🔵 vendor/dss-core 의 origin/main 이 핀보다 앞서 있지 않다 (또는 못 쟀다: ${CORE_AHEAD:-?})"
  fi
else
  unk "vendor/dss-core 안" "그 폴더가 git 저장소가 아니다 — git submodule update --init 을 먼저"
fi
# 🔵 PO 는 **이번에 안 굽는다.** 핀이 어긋나도 이 배포를 막을 일이 아니다 — ⚠️ 로만 센다.
for pair in "vendor/dss-core $PO_CORE_PIN" "vendor/dss-ui $UI_PIN"; do
  set -- $pair
  got=$(pin_of "$PODIR" "$1")
  if [ "${got:-}" = "$2" ]; then say "🔵 PO $1 포인터 ${2:0:7} — 적어 둔 그대로 (이번에 안 굽는다)"
  else note "PO $1 포인터가 ${got:0:7} 다 — ${2:0:7} 을 적어 두었다. **이번 배포는 안 막는다**(PO 를 안 굽는다)"; fi
done
say "🔵 A/S dss-core ${AS_CORE_PIN:0:7} · PO dss-core ${PO_CORE_PIN:0:7} — **서로 다른 것이 맞다.**"
say "   PO 쪽이 뒤에 있고, PO 는 이번 판이 건드린 표를 아예 안 쓴다. 🔴 여기서 맞추지 마세요."
# 🔴 빈 폴더가 아닌가 — 포인터는 맞는데 안이 비어 있는 경우가 실제로 있다.
check_not_empty() { # 1 서브모듈 폴더 2 사람이 부르는 이름
  if [ -s "$1/package.json" ]; then ok "$2 에 파일이 있다 (빈 폴더가 아니다)"
  else bad "$2 가 **빈 폴더**다 — git submodule update --init 을 먼저"; fi
}
check_not_empty "$COREDIR"             "A/S-core"
check_not_empty "$ASDIR/vendor/dss-ui" "A/S-ui"

# ── 4. 🔴 drizzle/ — **125 그대로다. 마이그레이션 0건** ───────────────
printf '\n== 4. drizzle/ — A/S %s 그대로 (마이그레이션 **0건**)\n' "$AS_SQL_WANT"
AS_COUNTS=$(count_drizzle "$ASDIR"); AS_SQL=${AS_COUNTS%% *}; AS_JRN=${AS_COUNTS##* }
say "RF_Service_System/drizzle — .sql ${AS_SQL}장 · meta/_journal.json 의 idx ${AS_JRN}개"
if [ "${AS_SQL:-0}" = "$AS_SQL_WANT" ] && [ "${AS_JRN:-0}" = "$AS_SQL_WANT" ]; then
  ok "${AS_SQL_WANT}장이다 — 🔵 53번이 올린 125 **그대로**다(이번 판은 0건)"
else
  bad "drizzle 이 .sql ${AS_SQL:-?} · idx ${AS_JRN:-?} 다 — **${AS_SQL_WANT} 여야 한다.** 멈추고 알릴 것"
  doubt
fi
# 🔵 두 상수가 이어지는 번호인가 — 한쪽만 고치면 아래 검사가 조용히 빗나간다.
#    🔴 10# 을 붙여 **10진수로 강제**한다. 안 붙이면 0124 가 8진수 84 로 읽힌다.
if [ "$(printf '%04d' "$((10#$AS_LAST_MIG + 1))")" = "$AS_NEXT_MIG" ]; then
  ok "번호 둘이 이어진다 ($AS_LAST_MIG → $AS_NEXT_MIG)"
else
  bad "🔴 $AS_LAST_MIG · $AS_NEXT_MIG 가 안 이어진다 — 한쪽만 고쳤다"
fi
# 🔴 **53번이 올린 0124 가 그대로 있는가.** 수만 세면 하나 빠지고 하나 생긴 경우를 못 본다.
if [ -s "$ASDIR/drizzle/$AS_LAST_MIG_FILE" ]; then
  ok "drizzle/$AS_LAST_MIG_FILE 이 있다 (53번이 올린 그 한 건)"
else
  bad "🔴 drizzle/$AS_LAST_MIG_FILE 이 **없다** — 이 배포는 그 파일이 있는 나무를 전제로 쓰였다"
  ls -1 "$ASDIR/drizzle/${AS_LAST_MIG}_"*.sql 2>/dev/null | sed 's/^/      /'
  doubt
fi
if ls -1 "$ASDIR/drizzle/${AS_NEXT_MIG}_"*.sql >/dev/null 2>&1; then
  bad "🔴 drizzle 에 $AS_NEXT_MIG 번이 **생겼다** — 이 배포는 **0건**을 전제로 쓰였다. 멈추고 알릴 것"
  say "🔴 54-deploy.sh 에는 **적용하는 절이 없다** — 묶음을 보내고 --migrate 를 돌려야 하는 판이면"
  say "   53-build.sh · 53-deploy.sh 의 마이그레이션 절을 가져와야 한다."
  doubt
else
  ok "$AS_NEXT_MIG 번이 없다 (마지막이 $AS_LAST_MIG — 이번 판은 **0건**이 맞다)"
fi
# 🔵 48번·53번이 올린 넷도 그대로 있어야 한다 — 묶음을 통째로 갈아 끼우기 때문이다.
KEEPMIG_SEEN=0; KEEPMIG_OK=0
for t in $AS_KEEP_MIGS; do
  KEEPMIG_SEEN=$((KEEPMIG_SEEN+1))
  if ls -1 "$ASDIR/drizzle/${t}_"*.sql >/dev/null 2>&1 && [ -s "$ASDIR/drizzle/meta/${t}_snapshot.json" ]; then
    KEEPMIG_OK=$((KEEPMIG_OK+1))
  else
    bad "$t 의 .sql 또는 스냅샷이 없다 — 묶음이 온전하지 않게 된다"
  fi
done
if [ "$KEEPMIG_SEEN" = "$AS_KEEP_MIGS_WANT" ] && [ "$KEEPMIG_OK" = "$AS_KEEP_MIGS_WANT" ]; then
  ok "48·53번이 올린 넷(0121~0124)이 .sql 과 스냅샷까지 그대로 있다"
else
  bad "본 것 ${KEEPMIG_SEEN} · 온전한 것 ${KEEPMIG_OK} 다 — ${AS_KEEP_MIGS_WANT}/${AS_KEEP_MIGS_WANT} 을 기대했다"
fi
# 🔴 「삼켜진 0」을 여기서 가른다 — PO 에 drizzle/ 이 없는 것이 맞다.
if [ -d "$PODIR/drizzle" ]; then
  bad "🔴 dss-po 에 drizzle/ 폴더가 **생겼다** — 2026-09-28 부터 없던 것이다. 스키마의 주인이 바뀌었는지 사람이 보세요"
  doubt
else
  ok "dss-po 에 drizzle/ 폴더가 없다 (없는 것이 맞다 — 스키마의 주인은 A/S 하나뿐이다)"
fi

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

# ── ㄱ) A/S Dockerfile 이 담는 길 ────────────────────────────────────
#   🔴 A/S 의 tools 는 drizzle/ 을 **안 담는다**(28MB — 볼륨이다). 2026-11-07 에
#      Dockerfile 을 다시 읽어 확인했다.
check_copy() { # 1 Dockerfile 2 정규식 3 있어야 하나(yes/no) 4 사람이 읽을 말
  if grep -qE "$2" "$1" 2>/dev/null; then
    if [ "$3" = yes ]; then ok "$4"; else bad "🔴 $4"; fi
  else
    if [ "$3" = yes ]; then bad "🔴 $4"; else ok "$4"; fi
  fi
}
printf '\n  ── A/S Dockerfile\n'
if grep -q '^FROM .* AS tools' "$ASDIR/Dockerfile" 2>/dev/null; then
  ok "A/S 에 tools 스테이지가 있다 (--target tools 가 선다)"
else
  bad "A/S 에 tools 스테이지가 없다 — --target tools 가 실패한다"
fi
check_copy "$ASDIR/Dockerfile" '^COPY .*scripts \./scripts'   yes "A/S tools 가 scripts/ 를 담는다 (🔴 이번에 생긴 도구 셋이 들어가는 유일한 길)"
check_copy "$ASDIR/Dockerfile" '^COPY .*package\.json'        yes "A/S tools 가 package.json·tsconfig.json 을 담는다 (🔴 새 npm 명령 둘이 들어가는 길)"
check_copy "$ASDIR/Dockerfile" '^COPY .*src \./src'           yes "A/S tools 가 src/ 를 담는다 (닫힘에서 바뀐 아홉 중 여섯이 여기다)"
check_copy "$ASDIR/Dockerfile" '^COPY .*vendor \./vendor'     yes "A/S tools 가 vendor/ 를 담는다 (공용 스키마가 들어가는 길 — 이번엔 안 바뀌었지만 없으면 Cannot find module 이다)"
check_copy "$ASDIR/Dockerfile" '^COPY .*drizzle \./drizzle'   no  "A/S tools 는 drizzle/ 을 **안 담는다** (28MB — 볼륨으로 붙인다)"
# 🔴 tools 가 runner **앞**이어야 한다 — 마지막 스테이지가 docker build 의 기본
#    대상이다. 뒤에 두면 --target 없이 구운 이미지가 앱이 아니라 도구가 된다.
lt=$(grep -n '^FROM .* AS tools'  "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
lr=$(grep -n '^FROM .* AS runner' "$ASDIR/Dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
if isnum "${lt:-}" && isnum "${lr:-}" && [ "$lt" -lt "$lr" ]; then
  ok "A/S Dockerfile 이 tools(${lt}줄) 를 runner(${lr}줄) **앞**에 둔다 (--target 없이 구우면 runner 가 나온다)"
else
  bad "🔴 A/S Dockerfile 의 차례가 tools ${lt:-?} · runner ${lr:-?} 다 — **--target 없이 구운 것이 도구가 된다**"
  doubt
fi

# ── ㄴ) .dockerignore ───────────────────────────────────────────────
printf '\n'
DIG="$ASDIR/.dockerignore"
if [ ! -s "$DIG" ]; then
  bad "A/S 에 .dockerignore 가 없거나 비었다 — .env 와 .git 이 이미지로 따라 들어간다"
else
  if grep -qE '^scripts/?$' "$DIG" 2>/dev/null; then
    bad "A/S 의 .dockerignore 가 scripts/ 를 막는다 — **이번에 생긴 도구 셋이 통째로 빠진다**"
  else
    ok "A/S 의 .dockerignore 가 scripts/ 를 막지 않는다"
  fi
  if grep -qE '^src/?$' "$DIG" 2>/dev/null; then
    bad "A/S 의 .dockerignore 가 src/ 를 막는다 — 이번에 고친 코드가 통째로 빠진다"
  else
    ok "A/S 의 .dockerignore 가 src/ 를 막지 않는다"
  fi
  if grep -qE '^\.next/?$' "$DIG" 2>/dev/null; then
    ok "A/S 의 .dockerignore 가 .next 를 막는다 (개발 서버를 띄워 둔 채로 구워도 된다)"
  else
    bad "A/S 의 .dockerignore 가 .next 를 안 막는다 — 호스트의 .next 가 빌드 문맥에 들어간다"
  fi
fi

# ── ㄷ) 🔴 npm 명령 — **이번 판은 늘었다.** 41번 잣대가 걸린다 ───────
printf '\n  ── npm 명령 (🔴 이번 판의 **첫째 까닭** — 둘이 늘었다)\n'
PL=$(git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | wc -l | tr -d ' ')
say "A/S package.json 의 diff ${PL:-못 쟀다}줄 (적어 둔 값 $AS_PKG_LINES_WANT)"
if [ "${PL:-x}" = "$AS_PKG_LINES_WANT" ]; then
  ok "package.json 이 $AS_PKG_LINES_WANT 줄 바뀌었다 — 🔴 **명령이 늘었다**(41번 잣대가 걸린다)"
else
  note "package.json 이 ${PL:-?}줄 바뀌었다 — $AS_PKG_LINES_WANT 줄을 적어 두었다. 아래 diff 를 사람이 보세요"
  git -C "$ASDIR" diff "$AS_BASE..HEAD" -- package.json 2>/dev/null | head -24 | sed 's/^/      /'
fi
NN=$(count_scripts < "$ASDIR/package.json" 2>/dev/null | tr -d ' ')
WW=$(git -C "$ASDIR" show "$AS_BASE:package.json" 2>/dev/null | count_scripts | tr -d ' ')
say "A/S scripts 항목 — 기준 ${WW:-?} → 지금 ${NN:-?} (적어 둔 값 $AS_NPM_WAS → $AS_NPM_NOW)"
if [ "${WW:-x}" = "$AS_NPM_WAS" ] && [ "${NN:-x}" = "$AS_NPM_NOW" ]; then
  ok "명령 수가 적어 둔 그대로다 ($AS_NPM_WAS → $AS_NPM_NOW)"
elif isnum "${NN:-}" && isnum "${WW:-}" && [ "${NN:-0}" -lt "${WW:-0}" ]; then
  bad "🔴 명령이 ${WW} 에서 ${NN} 로 **줄었다** — 사라진 명령을 그날 부르면 Missing script 다"
  doubt
else
  note "명령 수가 기준 ${WW:-?} → 지금 ${NN:-?} 다 — $AS_NPM_WAS → $AS_NPM_NOW 를 적어 두었다. 사람이 보세요"
fi
# 🔴 **이번에 생긴 둘** — 이 배포의 목적이다. 기준판에 0 · 지금 1 이어야 한다.
printf '\n  ── 🔴 이번에 생긴 npm 명령 둘 (운영에서 돌리려고 만든 것이다)\n'
NEWNPM_SEEN=0; NEWNPM_OK=0
for s in $AS_NEW_NPM; do
  NEWNPM_SEEN=$((NEWNPM_SEEN+1))
  was=$(git -C "$ASDIR" show "$AS_BASE:package.json" 2>/dev/null | grep -c "\"$s\"" || true)
  now=$(grep -c "\"$s\"" "$ASDIR/package.json" 2>/dev/null || true)
  printf '      %-34s 기준 %s → 지금 %s  (기대 0 → 1)\n' "$s" "${was:-0}" "${now:-0}"
  if [ "${was:-1}" = "0" ] && [ "${now:-0}" -ge 1 ] 2>/dev/null; then NEWNPM_OK=$((NEWNPM_OK+1)); fi
done
if [ "$NEWNPM_SEEN" = "$AS_NEW_NPM_WANT" ] && [ "$NEWNPM_OK" = "$AS_NEW_NPM_WANT" ]; then
  ok "새 명령 $AS_NEW_NPM_WANT 개가 **이번에 생겼다** — 🔴 **도구 이미지를 굽는 첫째 까닭이다**"
else
  bad "🔴 새 명령이 ${NEWNPM_OK}/${NEWNPM_SEEN} 개다 — ${AS_NEW_NPM_WANT}/${AS_NEW_NPM_WANT} 을 기대했다"
  say "🔴 **이 배포의 목적이 그 둘이다.** 없다면 범위가 틀렸다 — 멈추고 알리세요."
  doubt
fi
# 🔴 사라지면 안 되는 아홉
printf '\n  ── 사라지면 안 되는 npm 명령 아홉\n'
KEEP_SEEN=0; KEEP_OK=0
for s in $AS_KEEP_NPM; do
  KEEP_SEEN=$((KEEP_SEEN+1))
  now=$(grep -c "\"$s\"" "$ASDIR/package.json" 2>/dev/null || true)
  printf '      %-34s 지금 %s\n' "$s" "${now:-0}"
  if [ "${now:-0}" -ge 1 ] 2>/dev/null; then KEEP_OK=$((KEEP_OK+1)); fi
done
if [ "$KEEP_SEEN" = "$AS_KEEP_NPM_WANT" ]; then ok "지킬 명령 $AS_KEEP_NPM_WANT 개를 다 봤다 (표본이 비지 않았다)"
else bad "명령을 ${KEEP_SEEN}개만 봤다 — $AS_KEEP_NPM_WANT 개를 기대했다. 목록이 깨졌다"; fi
if [ "$KEEP_OK" = "$AS_KEEP_NPM_WANT" ]; then ok "지킬 명령 $AS_KEEP_NPM_WANT 개가 **지금 판에 다 있다** (부르는 날 Missing script 가 안 난다)"
else bad "🔴 지금 판에 있는 명령이 ${KEEP_OK}/$AS_KEEP_NPM_WANT 개다 — **사라진 것이 있다**"; doubt; fi

# ── ㄹ) 🔴 도구 닫힘 안에서 바뀐 파일 아홉 ──────────────────────────
printf '\n  ── A/S 도구 닫힘 안에서 바뀐 파일 (기대 %s개)\n' "$AS_TOOLS_CALLED_WANT"
CL_SEEN=0; CL_HIT=0
for f in $AS_TOOLS_CALLED; do
  CL_SEEN=$((CL_SEEN+1))
  if [ ! -s "$ASDIR/$f" ]; then
    bad "🔴 $f 가 저장소에 없다 — **닫힘 목록이 낡았다.** 닫힘을 다시 재세요"
    continue
  fi
  if git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- "$f" 2>/dev/null | grep -q .; then
    CL_HIT=$((CL_HIT+1)); say "🔴 바뀌었다 · 도구가 부른다 — $f"
  else
    say "🔵 안 바뀌었다 — $f"
  fi
done
say "닫힘 목록 ${CL_SEEN}개를 봤고, 그중 바뀐 것 ${CL_HIT}개 (적어 둔 수 $AS_TOOLS_CALLED_WANT)"
if [ "$CL_SEEN" = "$AS_TOOLS_CALLED_WANT" ]; then ok "닫힘 목록 $AS_TOOLS_CALLED_WANT 개를 다 봤다 (표본이 비어서 공짜로 통과한 것이 아니다)"
else bad "닫힘 목록을 ${CL_SEEN}개만 봤다 — $AS_TOOLS_CALLED_WANT 개를 기대했다. 목록이 깨졌다"; fi
if [ "${CL_HIT:-0}" -ge 1 ] 2>/dev/null; then
  ok "도구가 부르는 파일이 ${CL_HIT}개 바뀌었다 — **부르니까 굽는다**(둘째 까닭)"
else
  bad "🔴 도구가 부르는 길에서 바뀐 파일이 0개다 — $AS_TOOLS_CALLED_WANT 개를 적어 두었다. **머리말의 실측이 낡았다**"
  doubt
fi
if [ "${CL_HIT:-x}" != "$AS_TOOLS_CALLED_WANT" ]; then
  note "바뀐 것이 ${CL_HIT:-?}개다 — 적어 둔 것은 $AS_TOOLS_CALLED_WANT 개다. 커밋이 더 쌓였는지 사람이 보세요"
fi
# 🔵 **닫힘 안에 이번에 생긴 파일 다섯** — 이미지 안에서 「그 파일이 있나」만 봐도
#    새 판이 담겼다가 선다.
printf '\n  ── A/S 닫힘 안에 **이번에 생긴** 파일 다섯 (기준판에는 없어야 한다)\n'
BORN_SEEN=0; BORN_OK=0
for f in $AS_BORN; do
  BORN_SEEN=$((BORN_SEEN+1))
  if git -C "$ASDIR" cat-file -e "$AS_BASE:$f" 2>/dev/null; then
    note "$f 가 **기준판에도 있다** — 이번에 생긴 파일로 적어 두었다. 사람이 보세요"
  else
    BORN_OK=$((BORN_OK+1)); say "🔵 기준판에 없던 파일 — $f"
  fi
done
if [ "$BORN_SEEN" = "$AS_BORN_WANT" ] && [ "$BORN_OK" = "$AS_BORN_WANT" ]; then
  ok "다섯 다 기준판에 **없던 파일**이다 (이미지 안에서 존재만 봐도 새 판이다)"
else
  note "본 것 ${BORN_SEEN} · 기준판에 없던 것 ${BORN_OK} 다 — ${AS_BORN_WANT}/${AS_BORN_WANT} 을 기대했다. 사람이 보세요"
fi

# ── ㅁ) 🔴 **「담기는 것」으로도 센다** (39번에 넓혀 둔 잣대) ──────────
printf '\n  ── 담기는 것으로 세기\n'
AS_TOOLS_PATHS="scripts/ src/ package.json drizzle.config.ts tsconfig.json vendor/"
AS_TOOLS_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" -- $AS_TOOLS_PATHS 2>/dev/null | wc -l | tr -d ' ')
AS_ALL_CHANGED=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
say "A/S  tools 가 담는 것 중 달라진 파일 ${AS_TOOLS_CHANGED:-못 쟀다}개 (적어 둔 수 $AS_TOOLS_CHANGED_WANT)"
say "A/S  저장소 전체에서 달라진 파일 ${AS_ALL_CHANGED:-못 쟀다}개 (적어 둔 수 $AS_ALL_CHANGED_WANT)"
if isnum "${AS_TOOLS_CHANGED:-}" && [ "${AS_TOOLS_CHANGED:-0}" -ge 1 ]; then
  ok "A/S 도구를 구울 셋째 까닭이 있다 — 담기는 것 중 달라진 파일 ${AS_TOOLS_CHANGED}개"
else
  bad "A/S 달라진 파일이 ${AS_TOOLS_CHANGED:-못 쟀다}개다 — 전제가 깨졌으니 멈추고 알릴 것"
  doubt
fi
# 🔴 **이번 판은 바깥이 0 이다.** 53번은 다섯이었다 — 그 수를 베껴 오면 ⚠️ 가 거짓으로 난다.
OUTSIDE=$((${AS_ALL_CHANGED:-0} - ${AS_TOOLS_CHANGED:-0}))
say "A/S  tools 바깥에서 달라진 파일 ${OUTSIDE}개 (적어 둔 수 $AS_OUTSIDE_WANT)"
if [ "${AS_TOOLS_CHANGED:-x}" = "$AS_TOOLS_CHANGED_WANT" ] && [ "${AS_ALL_CHANGED:-x}" = "$AS_ALL_CHANGED_WANT" ]; then
  ok "바깥이 ${AS_OUTSIDE_WANT}개다 — 적어 둔 그대로 (이번 범위에는 문서도 drizzle/ 도 안 바뀌었다)"
else
  note "바깥이 ${OUTSIDE}개다 — ${AS_OUTSIDE_WANT}개를 적어 두었다. 굽는 판정은 안 흔들린다"
  printf '%s\n' "      ── 바깥에서 바뀐 것"
  git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" 2>/dev/null \
    | grep -vE '^(scripts/|src/|package\.json$|drizzle\.config\.ts$|tsconfig\.json$|vendor/)' | head -10 | sed 's/^/      /'
fi

# ── ㅂ) 🔴 포털·PO 쪽에서 달라진 파일 — **둘 다 0 이어야 한다** ───────
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

# ── ㅅ) 🔴 **이번 판인가를 글자로 가른다** ───────────────────────────
#   🔴 「파일이 바뀌었다」와 「그 안에 새 코드가 있다」는 다른 말이다.
printf '\n  ── A/S 이번 판의 표식 여섯 (기준판에 0 · 지금 판에 1 이상)\n'
MK_SEEN=0; MK_OK=0
for row in $(printf '%s\n' "$AS_MARKS" | tr -d ' ' | grep -v '^$'); do
  s=${row%%|*}; f=${row#*|}
  MK_SEEN=$((MK_SEEN+1))
  was=$(git -C "$ASDIR" show "$AS_BASE:$f" 2>/dev/null | grep -c "$s" || true)
  now=$(grep -c "$s" "$ASDIR/$f" 2>/dev/null || true)
  printf '      %-36s %-56s 기준 %s → 지금 %s\n' "$s" "$f" "${was:-0}" "${now:-0}"
  if [ "${was:-1}" = "0" ] && [ "${now:-0}" -ge 1 ] 2>/dev/null; then MK_OK=$((MK_OK+1)); fi
done
if [ "$MK_SEEN" = "$AS_MARKS_WANT" ] && [ "$MK_OK" = "$AS_MARKS_WANT" ]; then
  ok "표식 $AS_MARKS_WANT 개가 전부 **이번에 생겼다** (옛 판이 아니다)"
else
  bad "🔴 표식이 ${MK_OK}/${MK_SEEN} 개다 — $AS_MARKS_WANT/$AS_MARKS_WANT 을 기대했다. 목록이 낡았거나 범위가 틀렸다"
  doubt
fi
# 🔴 구운 이미지 안에서 쓸 표식이 기준판 src/ 에 **0파일**인가.
#    🔵 이 값이 0 이 아니면 아래 「새 판이 담겼다」 검사가 통째로 공짜 통과가 된다.
ASMW=$(git -C "$ASDIR" grep -l "$BUILD_MARK" "$AS_BASE" -- src/ 2>/dev/null | wc -l | tr -d ' ')
ASMN=$(git -C "$ASDIR" grep -l "$BUILD_MARK" HEAD        -- src/ 2>/dev/null | wc -l | tr -d ' ')
say "$BUILD_MARK 가 든 src/ 파일 — 기준 ${ASMW:-?} → 지금 ${ASMN:-?} (기대 0 → 1 이상)"
if [ "${ASMW:-1}" = "0" ] && [ "${ASMN:-0}" -ge 1 ] 2>/dev/null; then
  ok "표식 $BUILD_MARK 이 **이번에 생겼다** — 구운 앱·도구 둘을 이 한 글자로 가를 수 있다"
else
  bad "🔴 표식이 기준 ${ASMW:-?} → 지금 ${ASMN:-?} 다 — 0 → 1 이상을 기대했다"
  doubt
fi

# ── ㅇ) 🔴 **새 도구 둘이 정말 읽기만 하는가** ───────────────────────
#   🔴 '--apply' 글자로 재지 않는다 — check-delivered-date-sync.ts 의 **주석**에
#      그 낱말이 1번 나와서, 그렇게 재면 멀쩡한 도구가 ✗ 가 된다(머리말).
printf '\n  ── 🔴 새 도구 셋이 읽기만 하는가 (부르는 꼴로 센다 · 주석에 속지 않는다)\n'
# 🔵 먼저 **잣대가 살아 있는지** 표본 둘로 본다 — 안 그러면 아래 0 이 공짜 통과다.
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
  ok "새 도구 $RO_TOOLS_WANT 개가 **쓰는 문장 0 · 트랜잭션 0** 이다 (운영에서 돌려도 한 글자도 안 바뀐다)"
  say "🔵 위 「--apply 글자」가 1 로 나오는 줄이 있어도 **주석**입니다 — 그래서 그 수로 재지 않습니다."
else
  bad "🔴 읽기 전용인 것이 ${RO_OK}/${RO_SEEN} 개다 — ${RO_TOOLS_WANT}/${RO_TOOLS_WANT} 을 기대했다"
  say "🔴 **운영 DB 에 쓸 수 있는 도구를 굽는 판이다.** 멈추고 알리세요."
  doubt
fi
# 🔵 저장소 쪽 짝이 함께 들어왔는가 — 이 규율을 원본 글자로 지키는 시험이다.
if [ -s "$ASDIR/$RO_TEST" ]; then
  ok "$RO_TEST 가 저장소에 있다 (이 규율을 원본 글자로 지키는 짝이 함께 들어왔다)"
else
  note "$RO_TEST 가 없다 — 이번 범위에 들어온 것으로 적어 두었다. 사람이 보세요"
fi

# ── ㅈ) 🔴 **알고도 안 고친 것** — PO 가 새 거절 코드를 모른다 ───────
#   🔵 53번에서 넘어온 것이다. **이번 판이 만든 일이 아니고** 이번 판도 안 고친다
#      (PO 를 안 굽는다). **세어서 알리는 것**이 이 절의 일이다. ⚠️ 라 배포를 막지 않는다.
printf '\n  ── 🔴 PO 가 A/S 의 거절 코드를 아는가 (53번에서 넘어온 할 일)\n'
if [ -s "$PODIR/$PO_GATEWAY" ]; then
  PCODE=$(grep -c "$PO_MISSING_CODE" "$PODIR/$PO_GATEWAY" || true)
  ASCODE=$(grep -c "$PO_MISSING_CODE" "$ASDIR/$PO_MUT" || true)
  say "A/S $PO_MUT 의 $PO_MISSING_CODE ${ASCODE:-0}번"
  say "PO  $PO_GATEWAY 의 $PO_MISSING_CODE ${PCODE:-0}번 (53번 실측 0 — **아직 모른다**)"
  if [ "${ASCODE:-0}" -ge 1 ] 2>/dev/null && [ "${PCODE:-1}" = "0" ]; then
    note "🔴 **PO 는 아직 $PO_MISSING_CODE 를 모른다.** PO 에서 기타건을 [완료 처리] 하면"
    say "   A/S 가 적어 보낸 안내 문장이 **화면에 안 뜨고** 「모르는 응답」으로 떨어집니다."
    say "   🔵 자료는 안 깨집니다 — A/S 는 한 글자도 안 쓴 채 거절합니다."
    say "   🔴 **이것은 53번(쉰째)에서 넘어온 것이고 이 배포도 안 고칩니다**(PO 를 안 굽습니다)."
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
# 🔵 **되돌릴 판이 개발 PC 에 남아 있는가** — NAS 쪽은 54-deploy.sh 가 따로 센다.
#    🔴 **이번 판이 되돌릴 상대는 둘이다.** 53번은 넷이었다.
for t in "$AS_OLD_TAG" "$AS_TOOLS_OLD_TAG"; do
  if docker image inspect "$t" >/dev/null 2>&1; then say "🔵 옛 판 $t 가 개발 PC 에 있다"
  else say "🔵 옛 판 $t 가 개발 PC 에 없다 — NAS 쪽에 있으면 되돌리기는 된다(거기서 센다)"; fi
done
say "🔵 포털은 dss-auth:2.1 · dss-auth-tools:4 그대로 둔다 — 이번에 안 굽고 안 갈아 끼운다."
say "🔵 PO 는 dss-po:0.9 그대로 둔다 — 같다."

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
# ── 8. 🔴 양식 파일 — **이번 판에도 올릴 것이 없다. 그래도 잰다** ─────
# ══════════════════════════════════════════════════════════════════════
#   🔴 **경로를 찍지 않는다.** 이름 · 바이트 · md5 · 수정 시각만 찍는다.
#   🔴 **md5 가 적어 둔 것과 다르면 ✗ 가 아니라 ⚠️ 다** — 사용자가 양식을 고쳤다는
#      뜻이고, 그러면 **올릴 것이 생긴다.** 굽기를 막을 일은 아니다.
#   🔴 **파일이 아예 없으면 ✗ 다** — 운영이 못 읽는 양식을 그대로 두는 셈이다.
printf '\n== 8. 양식 파일 — 열하나가 53번 값 그대로인가 (경로는 안 찍는다)\n'
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
  ok "양식 $TPL_COUNT_WANT 개가 **전부 53번이 적어 둔 md5 그대로**다 — 🔵 **올릴 양식이 0장이다**"
else
  note "양식 ${TPL_DIFF}개가 적어 둔 것과 다르다 — 위를 보세요. **굽기는 막지 않는다**"
fi
# 🔵 그리고 **이번 범위에 .xlsx 변경이 0줄인가** — 저장소 쪽에서도 따로 본다.
XLSX=$(git -C "$ASDIR" diff --name-only "$AS_BASE..HEAD" 2>/dev/null | grep -ci '\.xlsx$' || true)
say "A/S 범위에서 달라진 .xlsx ${XLSX:-0}개 (기대 0)"
if [ "${XLSX:-1}" = "0" ]; then ok "범위에 .xlsx 변경이 0줄이다 (양식 절이 없는 까닭이다)"
else note "범위에 .xlsx 가 ${XLSX}개 있다 — 0 을 기대했다. 양식 올리는 절이 필요할 수 있다"; fi

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
  rest=${rest#*|}; STRICT=${rest%%|*}
  DIR="$DEV/$REPO"
  FILE=$(tar_name "$TAG")
  LOG="$OUT/build-$(printf '%s' "$TAG" | tr ':' '-').log"
  printf '\n── %s  (%s)\n' "$TAG" "$REPO"

  # 🔴 도구 이미지만 --target tools 다. 안 주면 **runner 가 구워지고** 그 안에는
  #    scripts/ 도 package.json 도 없어 오류 없이 쓸모없는 이미지가 된다
  #    (Dockerfile 이 tools 를 runner **앞에** 둔다 — 5절-ㄱ 이 그것을 쟀다).
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
      # 🔵 이번 판에는 loose 줄이 없다 — 오래된 기준값을 쓰는 날을 위해 남겨 둔다.
      printf '  ⚠️ 지난 판 tar 와 %s%% 다르다 — 기준값이 오래된 줄이라 막지 않습니다.\n' "$p"
    else
      printf '  ✗ 지난 판 tar 와 크기가 %s%% 다르다 — %s 에서는 그만큼이면 멈춘다\n' "$p" "$STRICT"
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
  #   🔴 갈래가 둘이라 **갈래마다 다른 것을 잰다.** 한 잣대로 재면 가짜 ✗ 가 난다:
  #      앱(runner) → server.js 가 있고 **.next 묶음 안에 새 글자**가 있나
  #      도구(tools) → package.json 이 있고 **새 명령 둘이 실제로 서는가**
  IMGFAIL=0
  case "$KEY" in
    as)
      # ① runner 가 맞는가 — tools 에는 /app/server.js 가 없다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/server.js && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '    /app/server.js: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ runner 스테이지가 맞다 (node server.js 를 안다)\n'
      else printf '  ✗ /app/server.js 가 없다 — **runner 가 아닌 것을 구웠다.** 올리지 마세요\n'; IMGFAIL=1; fi
      # ② 🔴 **묶음 안에 이번 판의 글자가 있는가.** runner 에는 소스가 없고
      #    .next/standalone 만 있다 — 그래도 알림 종류 문자열이 묶음에 박혀 나온다.
      #    🔵 기준판 src/ 에는 **0파일**이었다(5절-ㅅ 이 그것을 쟀다).
      #    🔴 이것이 없으면 「옛 판을 구웠다」이고, 그때 증상은 **아무 일도 안
      #       일어나는 것**이다 — 배포는 성공하고 기능만 없다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "grep -rlF $BUILD_MARK /app/.next/server 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '    /app/.next/server 안에서 %s 가 든 파일: %s개 (기대 1 이상)\n' "$BUILD_MARK" "${v:-?}"
      if isnum "${v:-}" && [ "${v:-0}" -ge 1 ]; then
        printf '  ✓ 묶음에 이번 판의 글자가 있다 (옛 판이 아니다)\n'
      else
        printf '  ✗ 묶음에 %s 가 없다 — **옛 판을 구웠다.** 캐시를 의심하세요\n' "$BUILD_MARK"; IMGFAIL=1
      fi
      # ③ 🔵 public/ 이 담겼는가 — 없으면 아이콘·정적 파일이 404 가 된다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/public && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '    /app/public: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ public/ 이 담겼다\n'
      else printf '  ✗ public/ 이 없다 — 정적 파일이 404 가 된다\n'; IMGFAIL=1; fi
      ;;
    astools)
      printf '\n    ── %s 안을 센다 (겉이 아니라 결과)\n' "$TAG"
      # ① runner 가 아니라 tools 인가
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -f /app/package.json && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '      /app/package.json: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ tools 스테이지가 맞다\n'
      else printf '  ✗ /app/package.json 이 없다 — **runner 를 구웠다.** --target tools 를 빠뜨렸다\n'; IMGFAIL=1; fi
      # ② 🔴 운영에서 불릴 npm 명령 **아홉**이 이미지 안 package.json 에 있는가(41번의 자리).
      #    🔵 이름은 package.json 의 **값**(scripts/check-….ts)에도 나오도록 빼기표 꼴로 본다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for s in check-target-shipment-missing check-due-date-inverted check-requested-due-date-sync check-due-date-overdue check-delivered-date-sync procedures:export procedures:import db:preflight db:migrate; do if grep -q "$s" /app/package.json 2>/dev/null; then echo "yes $s"; else echo "no  $s"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "9" ]; then printf '  ✓ npm 명령 아홉이 이미지 안에 있다 (Missing script 가 안 난다)\n'
      else printf '  ✗ 명령이 %s/9 개다 — **옛 package.json 이 담겼거나 명령이 사라졌다**\n' "${got:-0}"; IMGFAIL=1; fi
      # ③ 🔴 닫힘 안에서 바뀐 아홉이 담겼는가. 🔵 그중 다섯은 기준판에 **없던 파일**이다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/check-delivered-date-sync.ts /app/scripts/check-due-date-overdue.ts /app/scripts/lib/delivered-date-sync-survey.ts /app/src/lib/db/queries/repair-case-domestic-order-due-dates.ts /app/src/lib/db/queries/repair-case-overdue-notifications.ts /app/src/lib/domain/due-date-inversion.ts /app/src/lib/domain/notifications.ts /app/src/lib/domain/repair-case-overdue.ts /app/src/lib/domain/types.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "9" ]; then printf '  ✓ 닫힘에서 바뀐 아홉이 다 들어갔다 (그중 다섯은 이번에 생긴 파일이다)\n'
      else printf '  ✗ 아홉 중 %s개만 들어갔다 — src/ 나 scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
      # ④ 🔴 **공용 스키마가 담겼는가** — 이번 판에 안 바뀌었지만 없으면
      #    Cannot find module 이 난다(2026-09-21 에 실제로 났다).
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'd=/app/vendor/dss-core/src/schema; if [ -d "$d" ]; then echo "miss=0"; echo "n=$(ls -1 "$d" | wc -l)"; else echo "miss=1"; fi' 2>/dev/null | tr -d ' \r')
      printf '%s\n' "$v" | sed 's/^/      /'
      cm=$(printf '%s\n' "$v" | sed -n 's/^miss=//p'); cn=$(printf '%s\n' "$v" | sed -n 's/^n=//p')
      if [ "${cm:-1}" != "0" ]; then
        printf '  ✗ 이미지에 vendor/dss-core 의 스키마 폴더가 **없다** — Cannot find module 이 난다\n'; IMGFAIL=1
      elif [ "${cn:-0}" -ge 1 ] 2>/dev/null; then
        printf '  ✓ 공용 스키마가 담겼다 (파일 %s개)\n' "$cn"
      else
        printf '  ✗ 공용 스키마 폴더가 비었다 — **빈 서브모듈이 담겼다.** 올리지 마세요\n'; IMGFAIL=1
      fi
      # ⑤ 🔴 소스가 이번 판인가 — 글자로 센다. 전부 기준판에 **0번**이다(5절-ㅅ).
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for pair in "REPAIR_CASE_DUE_DATE_OVERDUE /app/src/lib/domain/notifications.ts" "countRepairCaseOverdueStages /app/src/lib/db/queries/repair-case-overdue-notifications.ts" "isDueDateOverdue /app/src/lib/domain/repair-case-overdue.ts" "quoteArchiveFolderNumberCandidates /app/src/lib/domain/quote-archive-naming.ts" "foldBlankToNull /app/scripts/lib/delivered-date-sync-survey.ts"; do set -- $pair; if grep -q "$1" "$2" 2>/dev/null; then echo "yes $1"; else echo "no  $1"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "5" ]; then printf '  ✓ 이번 판의 이름 다섯이 이미지 안에 있다 (옛 판이 아니다)\n'
      else printf '  ✗ 이번 판의 이름이 %s/5 개다 — **옛 판이 담겼다.** 캐시를 의심하세요\n' "${got:-0}"; IMGFAIL=1; fi
      # ⑥ 🔵 지난 판들이 올린 도구가 **아직 있는가** — 한 번 빼면 다시 넣는 사람이 없다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/check-due-date-inverted.ts /app/scripts/check-requested-due-date-sync.ts /app/scripts/check-target-shipment-missing.ts /app/scripts/lib/requested-due-date-sync-survey.ts /app/scripts/import-procedure-bundle.ts /app/scripts/export-procedure-bundle.ts /app/scripts/lib/procedure-template-bundle.ts /app/scripts/backfill-kyosan-used-parts.ts /app/scripts/lib/kyosan-used-parts-backfill.ts; do if [ -f "$f" ]; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "9" ]; then printf '  ✓ 48~53번이 올린 도구 아홉이 다 들어갔다\n'
      else printf '  ✗ 도구 파일이 %s/9 개다 — scripts/ 가 온전히 안 담겼다\n' "${got:-0}"; IMGFAIL=1; fi
      # ⑦ 🔴 **새 도구 둘이 이미지 안에서도 읽기만 하는가** — 부르는 꼴로 센다.
      #    🔴 「grep -c」 는 0 일 때 종료 코드 1 을 낸다. 「|| echo ?」 를 달면 **하필
      #       바라던 0 에서만** 터진다(2026-11-06 실제로 났다). 파일 없음과 0번을
      #       **갈래로** 가른다. 🔴 '--apply' 글자로 재지 않는다 — 주석에 있다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/check-due-date-overdue.ts /app/scripts/check-delivered-date-sync.ts /app/scripts/lib/delivered-date-sync-survey.ts; do if [ -f "$f" ]; then echo "miss=0 $f"; echo "w=$(grep -cE "\.insert\(|\.update\(|\.delete\(" "$f") $f"; echo "t=$(grep -c "db.transaction" "$f") $f"; else echo "miss=1 $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      nmiss=$(printf '%s\n' "$v" | grep -c '^miss=1' || true)
      nwrite=$(printf '%s\n' "$v" | grep -cE '^w=[1-9]' || true)
      ntx=$(printf '%s\n' "$v" | grep -cE '^t=[1-9]' || true)
      nok=$(printf '%s\n' "$v" | grep -c '^miss=0' || true)
      if [ "${nmiss:-1}" != "0" ]; then
        printf '  ✗ 새 도구 중 이미지에 **없는 것**이 %s개다\n' "$nmiss"; IMGFAIL=1
      elif [ "${nok:-0}" != "3" ]; then
        printf '  ✗ 새 도구 셋 중 %s개만 봤다 — 셋을 기대했다\n' "${nok:-0}"; IMGFAIL=1
      elif [ "${nwrite:-1}" = "0" ] && [ "${ntx:-1}" = "0" ]; then
        printf '  ✓ 새 도구 셋이 이미지 안에서도 **읽기만 한다** (쓰는 꼴 0 · 트랜잭션 0)\n'
      else
        printf '  ✗ 쓰는 꼴이 든 파일 %s개 · 트랜잭션이 든 파일 %s개 — **운영 DB 에 쓸 수 있는 판이다.** 올리지 마세요\n' "${nwrite:-?}" "${ntx:-?}"; IMGFAIL=1
      fi
      # ⑧ 🔵 옛 엑셀 읽개 둘은 **개발 DB 자물쇠**를 그대로 부르는가(53번의 그 절).
      v=$(docker run --rm --entrypoint sh "$TAG" -c 'for f in /app/scripts/import-technical-task-procedures.ts /app/scripts/link-technical-task-next-procedures.ts; do if grep -q checkDevelopmentWriteTarget "$f" 2>/dev/null; then echo "yes $f"; else echo "no  $f"; fi; done' 2>/dev/null | tr -d '\r')
      printf '%s\n' "$v" | sed 's/^/      /'
      got=$(printf '%s\n' "$v" | grep -c '^yes ' || true)
      if [ "${got:-0}" = "2" ]; then printf '  ✓ 엑셀 읽개 둘이 개발 DB 자물쇠를 부른다 (NAS 에서 부르면 막힌다)\n'
      else printf '  ✗ 자물쇠를 부르는 것이 %s/2 개다. **운영 DB 에 쓸 수 있는 판이다.** 올리지 마세요\n' "${got:-0}"; IMGFAIL=1; fi
      # ⑨ tsx 가 있는가 — 이 도구들은 tsx 로만 돈다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "test -d /app/node_modules/tsx && echo yes || echo no" 2>/dev/null | tr -d '\r')
      printf '      /app/node_modules/tsx: %s (기대 yes)\n' "${v:-못 읽음}"
      if [ "${v:-}" = "yes" ]; then printf '  ✓ tsx 가 있다\n'
      else printf '  ✗ tsx 가 없다 — node --import tsx 가 그 자리에서 죽는다\n'; IMGFAIL=1; fi
      # ⑩ 🔴 **값을 받아 본다 — 이번 판의 핵심 검사다.**
      #    🔴 'node …' 가 아니라 **'npm run …'** 이어야 Missing script 가 드러난다.
      #    🔵 DATABASE_URL 을 안 준다. 넷 다 맨 위에서 connection.ts 를 정적 import 하고
      #       그것이 모듈 꼭대기에서 던진다 — **DB 에는 한 글자도 안 닿는다.**
      #    🔴 **새 둘을 반드시 넣는다** — 이것이 「이미지에 담겼나」가 아니라
      #       「운영에서 부를 수 있나」를 재는 유일한 줄이다.
      for cmdname in check:due-date-overdue check:delivered-date-sync check:due-date-inverted procedures:import; do
        v=$(docker run --rm --entrypoint sh "$TAG" -c "cd /app && npm run $cmdname 2>&1 | head -40" 2>&1 | tr -d '\r')
        if printf '%s' "$v" | grep -qE 'Missing script|missing script'; then
          printf '  ✗ npm run %s — **Missing script** (41번과 같은 실패다)\n' "$cmdname"
          printf '%s\n' "$v" | head -20 | sed 's/^/      /'; IMGFAIL=1
        elif printf '%s' "$v" | grep -qF 'DATABASE_URL is not set'; then
          printf '  ✓ npm run %s 가 import 까지 갔고 DB 에는 안 닿았다 (기대한 답)\n' "$cmdname"
        elif printf '%s' "$v" | grep -qE 'Cannot find module|No such file|ERR_MODULE_NOT_FOUND'; then
          printf '  ✗ npm run %s 가 모듈을 못 찾는다 — 이미지에 담긴 것이 모자란다\n' "$cmdname"
          printf '%s\n' "$v" | head -20 | sed 's/^/      /'; IMGFAIL=1
        else
          printf '  ? npm run %s 의 답이 기대와 다르다 — 아래 20줄을 사람이 보세요\n' "$cmdname"
          printf '%s\n' "$v" | head -20 | sed 's/^/      /'; IMGFAIL=1
        fi
      done
      # ⑪ 🔵 이미지 안의 drizzle/ 은 **비어 있어야** 한다 — 볼륨으로 붙는 자리다.
      v=$(docker run --rm --entrypoint sh "$TAG" -c "ls /app/drizzle/*.sql 2>/dev/null | wc -l" 2>/dev/null | tr -d ' \r')
      printf '      /app/drizzle 안 .sql: %s개 (기대 0 — 볼륨이 붙지 않은 맨 이미지다)\n' "${v:-?}"
      if isnum "${v:-}" && [ "${v:-1}" = "0" ]; then printf '  ✓ drizzle/ 이 비어 있다 (이미지에 안 굽는다)\n'
      else printf '  ✗ drizzle/ 에 .sql 이 들었다 — 이미지가 28MB 를 더 메고 다닌다\n'; IMGFAIL=1; fi
      # ⑫ 🔵 **양식은 이미지에 안 들어간다** — 들어갔으면 도장과 계좌번호가 구워진 것이다.
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

printf '\n%s\n' "────────────────────────────────────────────────────────────"
printf '  구운 것 %s / %s · 실패 %s\n' "$BUILT" "$HOWMANY" "$BFAIL"
if [ "$BFAIL" != "0" ]; then printf '%s\n' "🔴 실패가 있다. 위를 보세요."; exit 1; fi

# ══ 🔴 셋째 산출물 — A/S 마이그레이션 묶음 (이번 판에는 **보험**이다) ══
#  🔴 **이번 판에는 보낼 까닭이 없다.** 운영 볼륨도 저장소도 125 이고 적용할 것이
#     0건이다. 🔵 **보내지 않아도 배포는 선다** — 54-deploy.sh 는 묶음이 없어도
#     ✗ 를 내지 않는다(볼륨이 이미 125 인지만 본다).
#  🔴 **그래도 만드는 까닭 둘**(52-build.sh 의 글 그대로):
#     · 운영 볼륨이 어떤 까닭으로 125 가 아니면(되돌렸거나 덜 풀렸거나) 그것이
#       고치는 길이다. 54-deploy.sh --migrate 가 **125 가 아닐 때만** 푼다.
#     · 🔴 그리고 **절이 살아 있어야 한다.** 39번 이후 40~47번이 전부 0건이었더니
#       마이그레이션 절이 통째로 사라졌고, 48번에서 다시 필요해졌을 때 39번까지
#       거슬러 가 가져와야 했다. 같은 일을 반복하지 않으려고 남긴다.
#  🔴 git archive 로 뽑지 않는다 — 서브모듈이 빈 폴더로 나온다.
#  🔴 묶은 뒤 **안을 센다.** 「파일이 생겼다」와 「담겼다」는 다르다.
printf '\n%s\n' "════════ A/S 마이그레이션 묶음 (🔵 이번 판에는 **보험**이다) ════════"
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

SQLPAT='^drizzle/[0-9][0-9][0-9][0-9]_.*[.]sql'
INSQL=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "$SQLPAT" || true)
INJRN=$(tar -xzOf "$MIGTAR" drizzle/meta/_journal.json 2>/dev/null | grep -o '"idx"' | wc -l | tr -d ' ')
printf '    묶음 안 .sql %s장 · _journal.json 의 idx %s개 (기대 %s · %s)\n' "${INSQL:-?}" "${INJRN:-?}" "$AS_SQL_WANT" "$AS_SQL_WANT"
MFAIL=0
if [ "${INSQL:-0}" != "$AS_SQL_WANT" ]; then
  printf '  ✗ 묶음 안 .sql 이 %s장이다 — %s장이어야 한다\n' "${INSQL:-?}" "$AS_SQL_WANT"; MFAIL=1
fi
if [ "${INJRN:-0}" != "$AS_SQL_WANT" ]; then
  printf '  ✗ 묶음 안 idx 가 %s개다 — %s개여야 한다. 🔴 목록에 없는 .sql 은 **안 돈다**\n' "${INJRN:-?}" "$AS_SQL_WANT"; MFAIL=1
fi
# 🔴 **0125 는 없어야 한다** — 있으면 이 배포의 전제(0건)가 깨진 것이다.
#    🔴 **tar | grep -q 를 if 에 바로 물리지 않는다**(머리말 함정 ⑧). 세어서 담는다.
HASNEXT=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${AS_NEXT_MIG}_.*[.]sql" || true)
if [ "${HASNEXT:-0}" -ge 1 ] 2>/dev/null; then
  printf '  ✗ 묶음에 %s 번이 있다 — 이 배포는 **0건**을 전제로 쓰였다\n' "$AS_NEXT_MIG"; MFAIL=1
else
  printf '  ✓ 묶음에 %s 번이 없다 (마지막이 %s — 0건이 맞다)\n' "$AS_NEXT_MIG" "$AS_LAST_MIG"
fi
# 🔵 48·53번이 올린 넷이 온전한가 — 폴더를 통째로 갈아 끼우기 때문이다.
for n in $AS_KEEP_MIGS; do
  hitsql=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/${n}_.*[.]sql" || true)
  hitsnap=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -cE "^drizzle/meta/${n}_snapshot[.]json" || true)
  if [ "${hitsql:-0}" = "1" ] && [ "${hitsnap:-0}" = "1" ]; then
    printf '  ✓ %s — .sql 과 스냅샷이 둘 다 묶음 안에 있다\n' "$n"
  else
    printf '  ✗ %s 가 온전하지 않다 — .sql %s · 스냅샷 %s\n' "$n" "${hitsql:-?}" "${hitsnap:-?}"; MFAIL=1
  fi
done
# 🔵 표본 둘 — 잣대가 살아 있고, ON DELETE 는 **안 걸려야** 한다(0124 가 그 꼴이다).
PROBE1=$(printf '%s\n' "DROP TABLE foo;" | grep -ciE "$DESTRUCTIVE_RE" || true)
PROBE2=$(printf '%s\n' 'REFERENCES "b"("id") ON DELETE set null;' | grep -ciE "$DESTRUCTIVE_RE" || true)
if [ "${PROBE1:-0}" = "1" ]; then printf '  ✓ 지우는 잣대가 살아 있다 (가짜 DROP 하나를 제대로 잡았다)\n'
else printf '  ✗ 지우는 잣대가 죽었다 — 아래 「0줄」이 공짜 통과다. 멈추세요\n'; MFAIL=1; fi
if [ "${PROBE2:-1}" = "0" ]; then printf '  ✓ ON DELETE set null 은 지우는 문장으로 안 센다 (0124 가 가짜 ✗ 를 안 받는다)\n'
else printf '  ✗ ON DELETE 를 지우는 문장으로 센다 — 0124 가 가짜 ✗ 를 받는다\n'; MFAIL=1; fi
# 🔴 묶음 안 넷에 지우는 문장이 **0줄**인가 — 보내는 날이 오면 통째로 갈아 끼운다.
DN=0
for n in $AS_KEEP_MIGS; do
  nm=$(tar -tzf "$MIGTAR" 2>/dev/null | grep -E "^drizzle/${n}_.*[.]sql" | head -1)
  [ -n "${nm:-}" ] || continue
  c=$(tar -xzOf "$MIGTAR" "$nm" 2>/dev/null | grep -ciE "$DESTRUCTIVE_RE" || true)
  DN=$((DN + ${c:-0}))
done
printf '    묶음 안 0121~0124 의 지우는 문장 %s줄 (기대 %s)\n' "$DN" "$MIG_DESTRUCT_WANT"
if [ "$DN" = "$MIG_DESTRUCT_WANT" ]; then
  printf '  ✓ 넷이 **더하기만 한다** (DROP TABLE/COLUMN/SCHEMA · TRUNCATE · DELETE FROM 없음)\n'
else
  printf '  ✗ 지우는 문장이 %s줄이다 — %s줄을 기대했다. **고치지 말고 먼저 알리세요**\n' "$DN" "$MIG_DESTRUCT_WANT"; MFAIL=1
fi

if [ "$MFAIL" = "0" ]; then
  printf '  ✓ 묶음 안이 저장소와 같다 (.sql %s · idx %s · %s 있음 · %s 없음)\n' "$AS_SQL_WANT" "$AS_SQL_WANT" "$AS_LAST_MIG" "$AS_NEXT_MIG"
else
  printf '%s\n' "🔴 묶음이 온전하지 않다. 올리지 마세요."; exit 1
fi
MIGLINE="as-migrations.tar.gz|${msz}|${mm5}|-"

# ══ 🔴 54-deploy.sh 에 붙여 넣을 표 ═══════════════════════════════════
#  🔴 54-deploy.sh 의 TARS 는 **이름만 적힌 채로** 올라간다. 지문 칸이 비어 있으면
#     --check 에서 ? 로 세고 **--preload·--go 에서는 ✗ 다** — 아래 **두 줄**로
#     그 두 줄을 통째로 갈아 끼운다.
printf '\n%s\n' "════════ 54-deploy.sh 의 TARS 에 붙여 넣을 것 (두 줄) ════════"
printf '%s' "$TARTABLE"
echo "  🔴 위 두 줄로 TARS 의 두 줄을 통째로 갈아 끼운다."
echo "$MIGLINE"
echo "  🔵 마지막 줄(묶음)은 54-deploy.sh 의 MIGTAR_SIZE · MIGTAR_MD5 에 넣는다."
echo "  🔵 **묶음은 이번 판에 안 보내도 된다** — 볼륨도 저장소도 125 이고 적용할 것이 0건이다."
printf '\n%s\n' "✅ 둘 다 구웠다. tar · 묶음 · 로그가 여기 있다:"
printf '%s\n' "    $OUT"
ls -1 "$OUT" 2>/dev/null | sed 's/^/      /'

printf '\n%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **올리는 차례 — 이번 판은 tar 가 둘이다**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  🔵 양식은 **한 장도 안 올립니다** — 열하나가 53번 값 그대로입니다(8절)."
printf '%s\n' "  🔵 마이그레이션은 **0건**입니다 — 묶음은 **안 보내도 됩니다.**"
printf '%s\n' "  🔵 포털(dss-auth)·PO 는 **안 건드립니다.**"
printf '%s\n' ""
printf '%s\n' "  🔴 PowerShell 경로는 **슬래시**로 적습니다. 역슬래시는 bash·scp 가 먹습니다."
printf '%s\n' ""
printf '%s\n' "  ① (개발 PC · PowerShell) **스크립트부터 올린다**"
printf '%s\n' "       cd \"C:/Users/희만/Desktop/Development/dss-deploy/nas/setup\""
printf '%s\n' "       scp -O 54-deploy.sh dss-nas:/volume1/dss/setup/"
printf '%s\n' "       Get-FileHash -Algorithm MD5 54-deploy.sh"
printf '%s\n' "     🔵 NAS 에서 md5sum 을 쳐 **눈으로 맞댑니다**(DSM 터미널이 긴 것을 잘라 먹습니다)."
printf '%s\n' ""
printf '%s\n' "  ② (NAS) 지금 상태를 잰다 — 아직 아무것도 안 바뀐다"
printf '%s\n' "       sudo -i"
printf '%s\n' "       bash /volume1/dss/setup/54-deploy.sh            ← --check"
printf '%s\n' "       bash /volume1/dss/setup/54-deploy.sh --count    ← 올리기 전 수"
printf '%s\n' "     🔵 2절의 마이그레이션 수가 **$AS_SQL_WANT** 로 나와야 합니다 (53번이 올려 둔 그대로)."
printf '%s\n' ""
printf '%s\n' "  ③ (개발 PC · PowerShell) **tar 둘을 보낸다 — 한 줄에 하나씩**"
printf '%s\n' "       cd \"$(printf '%s' "$OUT" | sed 's|^/c/|C:/|')\""
printf '%s\n' "       scp -O dss-as-4.7.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "       scp -O dss-as-tools-14.tar dss-nas:/volume1/dss/images/"
printf '%s\n' "     🔴 **-O 를 빼지 마세요** — DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
printf '%s\n' "     🔵 as-migrations.tar.gz 는 **안 보내도 됩니다**(적용할 것이 0건입니다)."
printf '%s\n' ""
printf '%s\n' "  ④ (NAS) **들여놓고 → 재고 → 갈아 끼운다**"
printf '%s\n' "       bash /volume1/dss/setup/54-deploy.sh --preload"
printf '%s\n' "       bash /volume1/dss/setup/54-deploy.sh            ← 다시 --check"
printf '%s\n' "       bash /volume1/dss/setup/54-deploy.sh --migrate  🔵 **DB 를 안 바꿉니다**(0건을 값으로 잽니다)"
printf '%s\n' "       bash /volume1/dss/setup/54-deploy.sh --go       ⏱ 정지 창 (앱 **하나**)"
printf '%s\n' "       bash /volume1/dss/setup/54-deploy.sh --count    ← 올린 뒤 수"
printf '%s\n' "     🔵 --migrate 는 이번 판에서 **덤프를 뜨고 tools-as 태그를 바꾸고 0건을 확인**합니다."
printf '%s\n' "        건너뛰고 --go 로 바로 가도 됩니다 — --go 가 태그 둘을 함께 고칩니다."
printf '%s\n' ""
printf '%s\n' "🔴 **되돌리기**: --rollback 은 app-as 를 $AS_OLD_TAG 로 되돌립니다."
printf '%s\n' "   🔵 도구는 $AS_TOOLS_TAG 그대로 둡니다(39·41~53번과 같은 판단 — 평소에 뜨지 않는 상자입니다)."
printf '%s\n' "   🔵 **DB 는 되돌릴 것이 없습니다** — 이 배포는 한 글자도 안 바꿉니다."
printf '%s\n' ""
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "🔴 **배포 뒤에 할 일 — 이번 판의 목적이 여기 있습니다**"
printf '%s\n' "══════════════════════════════════════════════════════════════"
printf '%s\n' "  🔴 **운영에서 세는 도구 둘을 돌립니다.** 개발 DB 에는 과거 건이 거의 없어"
printf '%s\n' "     규모를 못 잽니다 — 운영에서 돌려야 뜻이 있는 수가 나옵니다."
printf '%s\n' "       bash /volume1/dss/setup/54-deploy.sh --count"
printf '%s\n' "     🔵 --count 가 둘을 **읽기만 해서** 부릅니다. 손으로 부르려면:"
printf '%s\n' "       (NAS) $(printf '%s' 'cd /volume1/dss/deploy')"
printf '%s\n' "       (NAS) sudo docker compose -f docker-compose.nas.yml --env-file .env.nas \\"
printf '%s\n' "               --profile tools run --rm tools-as npm run check:due-date-overdue"
printf '%s\n' "       (NAS) 같은 줄의 마지막만 바꿔  npm run check:delivered-date-sync"
printf '%s\n' "     🔴 **둘 다 읽기만 합니다 — 쓰는 깃발(--apply)이 없습니다.**"
printf '%s\n' "        5절-ㅇ 와 이미지 안 검사 ⑦ 이 그것을 **글자로** 쟀습니다."
printf '%s\n' ""
printf '%s\n' "  🔴 **종에 [납기 지연]이 많이 뜰 수 있습니다.** 개발 기준 165줄이었고 운영은"
printf '%s\n' "     더 클 수 있습니다 — check:due-date-overdue 가 **올리기 전에** 그 수를 말해 줍니다."
printf '%s\n' "     🔵 끄는 길: **사용자 관리 › 알림 설정**."
printf '%s\n' ""
printf '%s\n' "  🔵 **53번(쉰째) 꼬리말에서 넘어온 할 일 둘이 아직 남아 있을 수 있습니다.**"
printf '%s\n' "     ① [사용자 관리] › [승인 절차] 의 「기타건 최종 출하 승인」 결재선"
printf '%s\n' "     ② 포털 관리자 화면 › 결재 알림 메일 의 「기타건 최종 출하 결재」 스위치"
printf '%s\n' "     🔴 **이 스크립트는 하셨는지 판정하지 않습니다** — 54-deploy.sh --count 가"
printf '%s\n' "        **값으로** 찍습니다. 이미 하셨으면 건너뛰세요."
printf '%s\n' ""
printf '%s\n' "🔴 **알고도 안 고친 것 — PO 가 거절 코드 하나를 모릅니다(53번에서 넘어왔습니다)**"
printf '%s\n' "   dss-po:0.9 의 AS_COMPLETION_REJECT_CODES 에 APPROVAL_REQUIRED 가 없습니다."
printf '%s\n' "   PO 에서 기타건을 [완료 처리] 하면 A/S 가 적어 보낸 안내 문장이 안 뜨고"
printf '%s\n' "   「모르는 응답」으로 떨어집니다. 🔵 자료는 안 깨집니다. 🔴 **이 배포도 안 고칩니다**"
printf '%s\n' "   (PO 를 안 굽습니다). 🔵 기타건 완료는 **A/S 화면에서** 하세요."
printf '%s\n' "────────────────────────────────────────────────────────────"
