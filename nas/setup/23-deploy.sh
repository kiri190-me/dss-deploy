#!/bin/bash
# /volume1/dss/setup/23-deploy.sh — 2026-10-12 열아홉째 배포
#
# ── 🔴 오늘 **세 번째** 배포다 ─────────────────────────────────────────
#
#   21번(20:50)이 A/S 2.4 · PO 0.4 를, 22번(22:22)이 A/S 2.5 · PO 0.5 를
#   올렸다. 이번은 **휴가 하나뿐**이다 — 그리고 **앞의 두 판과 결이 다르다.**
#
#     휴가  dss-leave:0.1  →  **dss-leave:0.2**        (커밋 3개)
#     도구  dss-leave-tools:1 → **dss-leave-tools:2**  (🔴 아래 ② 참조)
#
#   🔴 **운영 DB 에 표가 하나 선다.** 21 · 22번은 마이그레이션이 0건이었다.
#      이 판은 **1건**이다 — 그래서 19번(마이그레이션 셋을 돌린 판)의 절차를
#      통째로 가져왔다.
#
#   🔴 멈추는 것은 **dss-leave 하나뿐**이다.
#      포털 · A/S · 계측기 · 개선요청 · PO 는 **그대로 돈다.**
#
# ══ 이번 판에 담겨 나가는 것 ═══════════════════════════════════════════
#
#   커밋 셋 — 0454a6f(코드) · 80a87ad(문서) · 87ff906(범례 · 인쇄물)
#
#   ① **여름휴가** — 🔴 연차와 **별개인 셋째 주머니**다(연차 · 월차 · 여름휴가).
#      회사 전체 **연 3일**이고 설정 화면에서 바꾼다. 서로 메우지 않고,
#      반차가 없고, 이월이 없다. 연도 경계는 연차와 같다(입사일 기준이라
#      사람마다 다르다).
#   ② **달력 범례와 인쇄물** — 여름휴가가 안 보이던 자리 둘.
#      🔴 인쇄물이 여름휴가에 **「차감 없음」이라고 거짓**을 찍던 것도 고쳤다.
#      여름휴가는 제 주머니에서 분명히 빠진다 — 이제 「여름휴가에서 뺌」이다.
#
# ══ 🔴 ① 마이그레이션 — 0002_summer_leave_settings ═════════════════════
#
#   운영 DB(dss_leave)는 지금 **2**, 적용하면 **3** 이 된다.
#
#     CREATE TABLE "web_leave_settings" (
#       "id" integer PRIMARY KEY DEFAULT 1 NOT NULL,
#       "summer_days" numeric(5, 1) DEFAULT 3 NOT NULL,
#       "created_at" timestamp with time zone DEFAULT now() NOT NULL,
#       "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
#       CONSTRAINT "web_leave_settings_singleton_ck"   CHECK (… "id" = 1),
#       CONSTRAINT "web_leave_settings_summer_days_ck" CHECK (… >= 0)
#     );
#
#   🔴 **표 하나를 더하기만 한다. 지우는 문장이 없다.**
#   🔵 **줄이 없어도 앱이 3일로 읽는다**(src/lib/leave/data.ts 의
#      loadLeaveSettings 가 DEFAULT_SUMMER_DAYS 를 돌려준다). 표만 서면 바로
#      돌고, 관리자가 설정 화면에서 저장할 때 그 줄이 처음 생긴다.
#   🔵 CHECK 의 1 이 **숫자 그대로**다 — 바인딩 자리($1)로 굽히지 않았다.
#      이 계열에서 겪은 함정이라 이 스크립트가 **글자로 한 번, 적용 뒤
#      pg_get_constraintdef 로 또 한 번** 본다(4-ㄷ · 6-ㄷ).
#   🔴 **2026-10-12 에 운영 DB 에 아직 없는 것을 확인했다**
#      (information_schema.tables 에서 web_leave_settings → 0).
#
# ══ 🔴 ② 도구 이미지를 **다시 굽는다** — 13번을 읽고 내린 판단 ══════════
#
#   🔴 **이 판정이 지시서와 다르다. 읽고 넘어가지 말 것.**
#
#   13번(휴가 첫 설치)과 compose 를 읽어 보니 휴가의 drizzle 은 **볼륨이
#   아니라 이미지 안**이다. 근거 둘 — 둘 다 실측이다:
#
#     · docker-compose.nas.yml 의 tools-leave 주석:
#       「tools-as 와 달리 drizzle/ 볼륨이 없다. 그 저장소의 Dockerfile tools
#        스테이지가 drizzle/ 를 함께 굽기 때문이다. 대신 **마이그레이션이
#        늘면 도구 이미지를 다시 구워 옮겨야 한다.**」
#     · dss-leave/Dockerfile:81  COPY --chown=app:app drizzle ./drizzle
#     · tools-leave 에는 volumes: 가 한 줄도 없다(compose 실측).
#
#   🔴 그래서 A/S 처럼 **마이그레이션 묶음(tar.gz)을 올리는 길이 없다.**
#      0002 를 운영에서 돌리려면 **도구 이미지를 다시 구워 올리는 수밖에**
#      없다. 이것이 이번 판에 올릴 파일이 **셋**인 까닭이다.
#
#   🔴 **태그를 1 에서 2 로 올린다**(dss-leave-tools:2). 같은 태그로 다시
#      구우면 ① 되돌릴 옛 도구 이미지가 사라지고 ② 「태그는 같은데 속이 빈」
#      이미지로 9/21~9/29 여드레를 버린 그 함정에 다시 들어간다.
#      🔵 12번이 개선요청에서 똑같이 했다(dss-improvements-tools:1 → 2,
#         마이그레이션이 늘어서). 그 선례를 그대로 따른다.
#
#   🔴 **그래서 compose 가 두 줄 바뀐다** — app-leave 의 image 와
#      tools-leave 의 image. 지시서는 「휴가 태그 한 줄만」이었다.
#      🔵 tools-leave 는 profiles: [tools] 라 **떠 있지 않다** — 그 줄을
#         바꿔도 멈추는 것도 뜨는 것도 없다. 정지 창은 그대로 app-leave 하나다.
#
#   🔴 그래서 **건드리지 않는 쪽은 여덟**이다(지시서의 아홉이 아니다 —
#      dss-leave-tools:1 이 「건드리는 쪽」으로 넘어갔다). 직접 세었다:
#        dss-auth:1.5 · dss-as:2.5 · dss-as-tools:1 · dss-meters:1.3 ·
#        dss-meters-tools:1 · dss-improvements:0.3 ·
#        dss-improvements-tools:2 · dss-po:0.5
#
# ══ 🔴 ③ 차례 — **DB 가 먼저, 앱이 나중**이다 ══════════════════════════
#
#   🔴 이 판에서는 **그 차례를 지켜야 한다.** 까닭을 적어 둔다:
#
#     · 🔴 **0.2 는 표가 없으면 깨진다.** 첫 화면의 잔액 카드가
#       loadLeaveSettings() 를 부르고, 그것이 web_leave_settings 를 select
#       한다(src/lib/leave/data.ts:119 · 91). 표가 없으면 42P01 이다 —
#       「줄이 없어도 3일로 읽는다」는 **줄**이 없을 때 이야기이고,
#       **표**가 없을 때가 아니다.
#     · 🔵 **0.1 은 그 표를 쳐다보지도 않는다.** 0.1 에는 여름휴가라는 글자가
#       소스에 **하나도 없다**(실측). 그러니 표를 먼저 세워 두어도 지금 도는
#       0.1 에는 아무 일도 일어나지 않는다.
#     · 🔵 덤으로 정지 창이 짧아진다 — DB 작업이 정지 창 **밖**에서 끝난다.
#       19번도 같은 차례였다.
#
# ══ 22번에서 가져온 것 ═════════════════════════════════════════════════
#
#   뼈대 · 모드 다섯 · 「아직 안 온 것은 ✗ 가 아니다」 · 지문 대조 ·
#   compose 갈아 끼우기 · 시작 시각 대조 · 알림 링크 주소 · 바깥 주소 ·
#   사람이 칠 명령 76자 · 그리고 **오늘 깨진 자리 둘**:
#
#   ① 🔴 **큰따옴표 안에 백틱을 쓰지 않는다.** 명령 치환으로 읽혀 syntax
#      error 가 나는데 bash -n 은 치환 안쪽을 안 봐서 **못 잡는다.** 코드를
#      인용할 때는 작은따옴표나 「」 를 쓴다.
#      🔵 이 파일에는 백틱이 **하나도 없다**(짠 뒤 세어 확인했다).
#   ② 🔴 **읽기 전용 자리에 리다이렉션으로 빈 파일을 만들지 않는다.**
#      ash 가 리다이렉션 실패를 치명적으로 보고 셸을 그 자리에서 끝낸다.
#      🔵 이 판은 **애초에 볼륨이 하나도 없다** — 휴가 앱에는 업로드 폴더도
#         공유폴더도 없다(compose 실측). 그래서 쓰기 시험 자체가 없다.
#
# ══ 19번에서 가져온 것 — **마이그레이션 절차 전부** ════════════════════
#
#   · 적용 **직전** 덤프(야간 백업과 별도. --go 안에서 뜬다)
#   · 「지우는 문장」 검사 — 🔴 ON DELETE 에 걸리지 않는 그 잣대
#   · 적용 전 「이미 있는가」 판정(두 번 돌려도 안전)
#   · npm run db:migrate (tools-leave 로 떴다 사라진다)
#   · 🔴 적용 **뒤** SQL 로 다시 센다 — 「했다」가 아니라 「들어 있다」
#   · 앱을 멈추기 전에 DB 를 끝낸다 — 틀어지면 직원은 0.1 을 그대로 쓴다
#
#   🔴 **19번과 다른 것 하나 — db:preflight 가 없다.** 그 npm 스크립트는
#      A/S 저장소에만 있다(dss-leave/package.json 실측 — db:generate ·
#      db:migrate 뿐이다). 그래서 그 자리를 **이 스크립트가 직접 본다**:
#      도구 이미지 안의 .sql 을 꺼내 읽고(4-ㄴ) 지우는 문장을 세고(4-ㄷ)
#      바인딩 자리($1)가 섞였는지까지 본다. 🔵 잣대는 19번의 그것과 같다.
#
# ══ 🔴 돌리기 전에 — **값 여섯을 채워야 한다** ═════════════════════════
#
#   🔴 이 스크립트를 쓸 때 dss-leave:0.2 · dss-leave-tools:2 는 **아직 안
#      구워졌다.** 그래서 아래 여섯 상수가 **비어 있다**:
#        SZ_APP · MD5_APP · WANT_CFG_APP · SZ_TOOLS · MD5_TOOLS · WANT_CFG_TOOLS
#      비어 있는 동안 --check 는 그 자리를 ⚠️ 로만 말하고, 🔴 **--go 는 시작조차
#      하지 않는다.** 잰 적 없는 이미지를 운영에 올리지 않기 위해서다.
#
#   개발 PC(PowerShell)에서 굽고 재는 차례 — 폴더는
#   C:\Users\희만\Desktop\Development 다:
#
#     cd C:\Users\희만\Desktop\Development\dss-leave
#     git status --short                      ← **비어 있어야 한다**
#     docker build -t dss-leave:0.2 .
#     docker build --target tools -t dss-leave-tools:2 .
#     cd ..
#     docker save dss-leave:0.2 -o dss-leave-0.2.tar
#     docker save dss-leave-tools:2 -o dss-leave-tools-2.tar
#     (Get-Item dss-leave-0.2.tar).Length             ← SZ_APP
#     Get-FileHash -Algorithm MD5 dss-leave-0.2.tar   ← MD5_APP (소문자로)
#     tar -xOf dss-leave-0.2.tar manifest.json        ← Config → WANT_CFG_APP
#     (도구도 같은 세 줄)
#
#   🔴 **도구 이미지의 빌드 타깃 이름을 먼저 확인하세요.** 위 --target tools 는
#      dss-leave/Dockerfile 의 스테이지 이름이다(그 파일 51~81줄). 이름이
#      다르면 거기 적힌 대로 굽는다. 🔴 **짐작으로 굽지 마세요** — 이 자리에서
#      틀리면 drizzle 이 안 담긴 도구 이미지가 나오고, 그러면 db:migrate 가
#      **0건으로 조용히** 끝난다. 아래 2-ㄷ 이 그것을 센다.
#   🔴 **git archive 로 뽑지 마라** — 서브모듈이 빈 폴더로 나와 빌드가 깨진다.
#      작업 폴더에서 굽되 git status 가 비어야 한다.
#   🔴 **tar 가 이미지의 1/4 쯤인 것은 정상이다.** 0.1 은 tar 74,208,768 ·
#      도구 1 은 tar 189,109,760 이었다(13번 실측). 🔵 0.2 는 화면 몇 장과
#      규칙 한 덩이가 는 것뿐이라 **0.1 과 비슷한 것이 정상**이다.
#   🔴 **tar 안 Config 지문은 개발 PC 의 {{.Id}} 와 다르다.** 17번이 두 번
#      겪었다 — **맞춰 볼 값은 tar 쪽**이다.
#
# ── 사람이 실행한다 ─────────────────────────────────────────────────────
#   (PowerShell)  ssh dss-nas
#   (NAS)         sudo -i                      ← DSM 비밀번호. 한/영이 영문인지!
#   (NAS)         bash /volume1/dss/setup/23-deploy.sh            ← 읽기만 한다
#
#   🔴 NAS 의 docker 는 **sudo(root)** 가 필요하다. 이 스크립트는 root 가
#      아니면 첫 줄에서 멈춘다.
#
# ══ 🔴 개발 PC → NAS 로 올릴 것 **셋** ═════════════════════════════════
#
#   🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#      아래는 **개발 PC 의 PowerShell** 에서 친다(NAS 가 아니다).
#
#     scp -O dss-leave-0.2.tar dss-nas:/volume1/dss/images/
#     scp -O dss-leave-tools-2.tar dss-nas:/volume1/dss/images/
#     scp -O docker-compose.nas.yml dss-nas:/volume1/dss/setup/incoming/
#
#   🔴 **마이그레이션 묶음은 올리지 않는다.** A/S 와 달리 휴가의 .sql 은
#      **도구 이미지 안**에 있다(위 ②). 둘째 줄이 그 역할을 대신한다.
#   🔴 세 번째 줄의 compose 는 **dss-deploy 저장소의 nas/docker-compose.nas.yml**
#      이다(app-leave 0.2 · tools-leave 2 — **그 두 줄만** 바뀐 파일).
#   🔵 scp 가 바로 안 되면 사용자 계정(swhur)의 홈으로 올린 뒤 NAS 에서
#      sudo mv 로 옮긴다. /volume1/dss 아래는 root 만 쓸 수 있다.
#
# ══ 🔴 DSM 터미널은 긴 명령을 잘라 먹는다 ══════════════════════════════
#
#   하루에 네 번 깨진 적이 있다. **NAS 에서 돌릴 것은 스크립트 파일로 올리고
#   md5 를 맞춘 뒤** 실행한다. 이 파일 자체가 그렇다:
#
#     (PowerShell)  scp -O nas\setup\23-deploy.sh dss-nas:/volume1/dss/setup/
#     (PowerShell)  Get-FileHash -Algorithm MD5 nas\setup\23-deploy.sh
#     (NAS)         md5sum /volume1/dss/setup/23-deploy.sh
#                   → 두 값이 **같아야** 실행한다. 다르면 다시 올린다.
#
#   그래서 이 스크립트는 사람이 칠 명령을 **한 줄 76자 안쪽**으로만 찍는다.
#
# ══ 🔴 야간 백업 시각을 지킨다 — **02:30** ═════════════════════════════
#
#   🔴 **자정을 넘겨 돌리면 백업 검사에 걸린다.** 17번이 01:00 에 돌렸다가
#      실제로 배포가 막혔다 — 그것이 사고를 막았다.
#      늦은 시각에 돌려야 한다면 **먼저 손으로 한 번 뜬다**(종료 코드 0):
#
#        bash /volume1/dss/jobs/backup-nightly.sh
#
#      ✓ dss_leave 줄이 찍혀야 한다. 🔴 이번 판이 보는 것은 **dss_leave** 다
#        (21 · 22번은 dss_as 였다 — 바뀌었으니 베낄 때 조심).
#
# ── 🔴 인자 없이 돌리면 읽기만 한다 ────────────────────────────────────
#
#   11번부터 이어온 약속을 그대로 잇는다 — **인자 없이 돌리면 --check**.
#   실수로 그냥 돌려도 아무것도 바뀌지 않는다(🔵 로그 파일 **둘**만 남는다 —
#   돌아간 기록 하나와, DB 에 보낸 문장을 한 줄씩 적은 것 하나).
#   코드로는 아래 두 줄이 그 약속이다:
#     · MODE=check        (모드 절의 첫 줄)
#     · FORCE_LOAD=0      (같은 태그를 덮어쓰지 않는다)
#
#   🔴 정직하게 적어 둔다 — --check 도 이미지 **안을 보려고** 컨테이너를 잠깐
#      띄웠다 지우고(docker run --rm), 운영 DB 에 **select** 를 몇 번 보낸다.
#      디스크에도 DB 에도 아무것도 남기지 않는다. 「아무것도 안 한다」가 아니라
#      「아무것도 **바꾸지** 않는다」가 정확한 말이다.
#   🔴 **--check 가 DB 에 보내는 문장은 전부 select 다.** 믿으라고 하지 않고
#      **세어서 찍는다** — 마지막 줄에 「보낸 문장 N · select N · 그 밖 0」이
#      나온다(sql_report). db:migrate 도 pg_dump 도 --go 에서만 돈다.
#
# ── 모드 다섯 ───────────────────────────────────────────────────────────
#   (없음) · --check     읽기만 한다. 아무것도 안 바꾸고 안 멈춘다      ← 기본값
#   --preload            새 이미지 둘을 싣고 지문을 맞춘다. 안 멈춘다
#   --force-load         🔴 같은 태그가 이미 있어도 **다시 싣는다**
#   --go                 🔴 표를 세우고 휴가를 교체한다
#   --rollback           되돌리기 안내
#
#   --force-load 는 --go 와 같이 써도 된다:  bash 23-deploy.sh --go --force-load
#
# ── 차례 ────────────────────────────────────────────────────────────────
#   1) bash 23-deploy.sh                 (읽기만 · 어긋난 곳을 먼저 고친다)
#   2) bash 23-deploy.sh --preload       (새 이미지 둘을 미리 실어 둔다)
#   3) bash 23-deploy.sh                 (다시 읽기만 — 이번엔 안까지 다 본다)
#   4) bash 23-deploy.sh --go            (표 하나 + 휴가 교체)
#
# ══ 🔴 「아직 안 온 것」을 ✗ 로 세지 않는다 (17 ~ 22번의 규칙) ═════════
#
#       **--check 가 ✗ 로 세는 것은 「있는데 어긋난 것」뿐이다.**
#       「아직 안 온 것 · 아직 안 실린 것」은 ⚠️ 로 안내만 한다.
#
# ══ 🔴 건드리지 않는 여덟 ══════════════════════════════════════════════
#
#     dss-auth:1.5              dss-as:2.5
#     dss-as-tools:1            dss-meters:1.3
#     dss-meters-tools:1        dss-improvements:0.3
#     dss-improvements-tools:2  dss-po:0.5
#
#   전부 지금 운영에서 돌고 있다(도구 셋은 실려만 있다). compose 에서 이
#   태그가 흔들렸으면 **남의 변경이 섞인 것**이다 — 두 세션이 같은 저장소를
#   쓴다. 고치지 말고 **먼저 알린다.**
#
#   그리고 「안 멈췄다」를 말로 하지 않는다 — 교체 **전후로** 각 컨테이너의
#   시작 시각(.State.StartedAt)을 적어 두고 **그대로인지** 본다(7-ㅂ).
set -u
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)
TODAY=$(date +%F)
CF=$D/deploy/docker-compose.nas.yml
INC=$D/setup/incoming
INCOMING=$INC/docker-compose.nas.yml
ENV_NAS=$D/deploy/.env.nas
ENVD=$D/deploy/env
LEAVE_ENV=$ENVD/leave.env
IMAGES=$D/images
BKD=$D/backups

# ── 🔴 이번에 올라가는 것 **둘** ───────────────────────────────────────
TAG_APP=dss-leave:0.2
OLD_APP=dss-leave:0.1
# 🔴 도구도 올라간다 — 휴가의 drizzle 은 **이미지 안**이다(머리말 ②).
TAG_TOOLS=dss-leave-tools:2
OLD_TOOLS=dss-leave-tools:1

# ── 🔴 **건드리지 않는 여덟** (직접 세었다 — 지시서의 아홉이 아니다) ───
KEEP_AUTH=dss-auth:1.5
KEEP_AS=dss-as:2.5
KEEP_ASTOOLS=dss-as-tools:1
KEEP_METERS=dss-meters:1.3
KEEP_METERSTOOLS=dss-meters-tools:1
KEEP_IMP=dss-improvements:0.3
KEEP_IMPTOOLS=dss-improvements-tools:2
KEEP_PO=dss-po:0.5

# ── tar 둘 ─────────────────────────────────────────────────────────────
TAR_APP=$IMAGES/dss-leave-0.2.tar
TAR_TOOLS=$IMAGES/dss-leave-tools-2.tar
# 🔴 **2026-10-12 22:32 · 22:54 에 구워 잰 값이다.** 개발 PC 의
#    Development\dss-leave-0.2.tar · dss-leave-tools-2.tar 에서 바로 쟀다.
#    🔵 참고 — 0.1 은 tar 74,208,768 · 도구 1 은 tar 189,109,760 이었다.
#       거의 같은 것이 정상이다(바뀐 것은 여름휴가 한 덩이와 마이그레이션 하나다).
#    🔴 tar 를 다시 구우면 지문이 달라진다 — 그때는 여섯을 다시 잰다.
SZ_APP=74211328
MD5_APP=5c73953c28a909f665c540b09decc9b3
WANT_CFG_APP=sha256:6cc563d42ce94d577c6acd977272a71a00b0203176c64c7a75aea17209643ff9
SZ_TOOLS=189119488
MD5_TOOLS=13611ae882ea61472be57281e5d45d2d
WANT_CFG_TOOLS=sha256:8d3585a57bc6c2f354e850ba71ea053cd5881a2cdb92d0cad3e419d52dbfb529
# ⚠️ manifest.json 은 그 값을 'blobs/sha256/4256829e…' 로 적는다 — 앞의 'blobs/' 를
#    떼고 'sha256:' 를 붙인 모양으로 적는다(17 ~ 22번도 같은 모양이었다).

# ── 휴가의 값들 (13-deploy.sh 에서 그대로 읽어 왔다 — 짐작이 아니다) ───
#   포털 13100 · A/S 13000 · 계측기 13300 · 개선요청 13500 ·
#   PO 13600 · **휴가 13700**
LEAVE_DB=dss_leave
LEAVE_ROLE=dss_leave_app
LEAVE_SVC=app-leave
LEAVE_TOOLS_SVC=tools-leave
LEAVE_CNAME=dss-leave
LEAVE_PORT=13700
LEAVE_INNER=3700
LEAVE_BASE=https://leave.dss21.co.kr

# ══ 🔴 마이그레이션 — **하나다**(0002_summer_leave_settings) ═══════════
N_MIG_HAVE=2                   # 지금 운영에 적용돼 있는 수 (13번이 둘을 넣었다)
N_MIG_WANT=3                   # 적용 뒤 수
NEW_MIG=0002_summer_leave_settings
MIG_GLOB=/app/drizzle/0002_*.sql
# 🔴 도구 이미지 안에서 셀 값 (12번이 개선요청에서 한 그대로)
MIG_TAGS="0000_init 0001_warm_wonder_man 0002_summer_leave_settings"

# ── 적용 뒤 DB 에서 **직접 세어** 볼 것 ────────────────────────────────
NEW_TBL=web_leave_settings
NEW_COL=summer_days
NEW_CK1=web_leave_settings_singleton_ck
NEW_CK2=web_leave_settings_summer_days_ck
# 🔴 .sql 안에 반드시 있어야 할 글자 — 「이름만 맞고 속이 다른 파일」을 가린다.
MIG_MARK='CREATE TABLE "web_leave_settings"'
MIG_MARK2='"summer_days" numeric(5, 1) DEFAULT 3 NOT NULL'

# ── 🔴 지우는 문장을 세는 잣대 (19번의 그것 그대로) ────────────────────
# 🔴 **'DELETE' 만으로 세지 않는다** — 외래키의 ON DELETE restrict/cascade 가
#    정상인데도 걸린다. 19번이 그 함정을 겪고 잣대를 이렇게 좁혔다
#    (앱의 판정기 src/lib/db/migration-safety.ts 와 같은 잣대다).
# 🔵 '\b' 를 쓰지 않는다 — DSM 의 grep 이 GNU 가 아닐 수 있다. POSIX ERE 로만.
DESTRUCTIVE_RE='DROP[[:space:]]+(TABLE|COLUMN|SCHEMA|TYPE|INDEX|CONSTRAINT|DATABASE|VIEW|SEQUENCE)|TRUNCATE|DELETE[[:space:]]+FROM|ALTER[[:space:]]+TABLE.*DROP'
# 🔴 넓은 그물 — 이것은 **멈추지 않는다. 찍어 주기만 한다.** 지시서의
#    「걸리면 왜 걸렸는지 찍어 사람이 가릴 수 있게」가 이 줄이다.
WIDE_RE='DROP|DELETE|TRUNCATE'
# 🔴 drizzle 의 sql 템플릿이 상수를 **바인딩 자리**로 구워 버린 적이 있다 —
#    CHECK ("id" = $1) 이 되면 그 마이그레이션은 돌릴 수가 없다. 글자로 본다.
BIND_RE='\$[0-9]'

# ══════════════════════════════════════════════════════════════════════
#  이미지 **안에서** 찾을 글자 — 🔴 **짝으로** 본다 (20 · 22번의 길)
#
#  🔵 0.1 의 소스에는 '여름휴가' 라는 글자가 **하나도 없다**(실측). 그래서
#     새 글자 하나로도 갈리지만, 22번처럼 **옛 글자가 사라졌는가**까지 함께
#     본다 — 그래야 「반만 담긴 이미지」가 걸린다.
# ══════════════════════════════════════════════════════════════════════
NEW_M1='여름휴가'
NEW_M2='여름휴가에서 뺌'
NEW_M3='연차와 따로 셉니다'
# 🔴 0.1 에만 있는 글자. 0.2 는 이 자리를 「…빠지지 않고, 여름휴가는
#    여름휴가에서 뺍니다」 로 고쳐서 이 글자가 **사라진다.**
OLD_M='경조사·건강검진·예비군 등은 연차에서 빠지지 않습니다'
# 🔵 회귀 — 0.1 에 있던 것이 0.2 에도 그대로 있는가.
KEEP_M1='월차'
KEEP_M2='결재선'
# 대조 표시 — 두 판에 다 있다(src/lib/env.ts). 이것이 안 나오면 **글자를 못
# 읽은 것**이다. 13번이 같은 이미지에서 쓴 그 글자다.
CTRL='.env.local 파일을 확인하세요'

# ── leave.env 에 **있어야 하는** 여덟 (13번 실측 · 이번 판은 안 고친다) ─
ENV_KEYS="SSO_CLIENT_SECRET SSO_CLIENT_ID SSO_ISSUER SSO_REDIRECT_URI"
ENV_KEYS="$ENV_KEYS SSO_TX_SECRET SESSION_COOKIE_SECURE SESSION_HOURS"
ENV_KEYS="$ENV_KEYS DEV_FAKE_LOGIN_ENABLED"
# leave.env 에 **있으면 안 되는** 것 — compose 와 이미지가 넘긴다.
ENV_FORBIDDEN="DATABASE_URL PORT"

# ── 모드 ───────────────────────────────────────────────────────────────
# 🔴 기본값 둘. 인자가 없으면 이 둘 그대로라 아무것도 바뀌지 않는다.
MODE=check
FORCE_LOAD=0
usage() {
  cat <<'USAGE'
쓰는 법 — 인자가 없으면 읽기만 합니다.

  bash 23-deploy.sh                  읽기만 (기본값) · 아무것도 안 바꿉니다
  bash 23-deploy.sh --check          위와 같습니다
  bash 23-deploy.sh --preload        새 이미지 둘을 싣고 지문만 맞춥니다
  bash 23-deploy.sh --force-load     🔴 같은 태그가 있어도 **다시** 싣습니다
  bash 23-deploy.sh --go             🔴 표 하나를 세우고 휴가를 교체합니다
  bash 23-deploy.sh --go --force-load  교체하면서 이미지를 덮어씁니다
  bash 23-deploy.sh --rollback       되돌리기 안내

  🔴 --go 가 멈추는 것은 **dss-leave 하나**입니다.
     포털 · A/S · 계측기 · 개선요청 · PO · DB 는 그대로 돕니다.
  🔴 --go 는 **운영 DB(dss_leave)에 표를 하나 세웁니다.** 지우는 문장은
     없습니다. 차례는 **DB 가 먼저, 앱이 나중**입니다.
  🔴 그날 백업(dss_leave)이 없으면 시작하지 않습니다. 야간 백업은 02:30 입니다.
USAGE
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)      MODE=check ;;
    --preload)    MODE=preload ;;
    --force-load) FORCE_LOAD=1; [ "$MODE" = check ] && MODE=force-load ;;
    --go)         MODE=go ;;
    --rollback)   MODE=rollback ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "모르는 인자: $1"; usage; exit 2 ;;
  esac
  shift
done

[ "$(id -u)" = 0 ] || { echo "먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요."; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/23-deploy-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

# ── 도우미 — 11 ~ 22-deploy.sh 의 것 그대로 ────────────────────────────
PASS=0; FAIL=0; T0=0; STOP_AT=""; UP_AT=""; DOWN=0
ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
say()  { echo "$*"; }
step() { echo; echo "── $*"; }
stop() { echo; echo "여기서 멈춥니다. $1"; echo "Claude 에게 알려 주세요 (로그: $LOG)"; exit 1; }

# 🔴 「아직 안 온 것」은 --check 에서 ✗ 가 아니다.
missing_is_fatal() { [ "$MODE" != check ]; }
notyet() { # 1 할 말   — 아직 안 **온** 것(사람이 올려야 하는 파일)
  if missing_is_fatal; then bad "$1"; else echo "    ⚠️ $1"; fi
}
notloaded() { # 1 할 말 — 아직 안 **실린** 것. 🔴 어느 모드에서도 ✗ 가 아니다.
  echo "    ⚠️ $1"
}

# 🔴 값 여섯이 채워졌는가 — 안 채워졌으면 --go 가 시작하지 않는다.
pinned() {
  [ -n "$SZ_APP" ] && [ -n "$MD5_APP" ] && [ -n "$WANT_CFG_APP" ] \
    && [ -n "$SZ_TOOLS" ] && [ -n "$MD5_TOOLS" ] && [ -n "$WANT_CFG_TOOLS" ]
}

# ── 사람이 칠 명령은 76자 안쪽으로만 찍는다 ────────────────────────────
CMDW=76
cmd() { # 1 사람이 그대로 칠 명령 한 줄
  printf '    %s\n' "$1"
  if [ "${#1}" -gt "$CMDW" ]; then
    printf '    ⚠️ 위 줄이 %s자다(%s자 넘음) — 붙여넣으면 잘릴 수 있다.\n' "${#1}" "$CMDW"
    printf '       아래 「스크립트 파일로 만들기」를 쓰세요.\n'
  fi
}
script_file_hint() { # 1 파일이름(확장자 없이)
  say "    ── 길면 붙여넣지 말고 파일로 만드세요 ──"
  cmd "cat > /volume1/dss/setup/$1.sh"
  say "      (여기에 위 줄들을 붙여넣고 Ctrl+D)"
  cmd "bash /volume1/dss/setup/$1.sh"
}

COMPOSE=("$DOCKER" compose -f "$CF" --env-file "$ENV_NAS" --profile tools)
compose_at() { # 1 compose파일  나머지: compose 에 넘길 인자
  local f="$1"; shift
  "$DOCKER" compose --project-directory "$D/deploy" -f "$f" --env-file "$ENV_NAS" --profile tools "$@"
}

running() { "$DOCKER" ps --format '{{.Names}}' | grep -qx "$1"; }
pg_up()   { running dss-pg-app; }

# ══════════════════════════════════════════════════════════════════════
#  DB 도우미 — 🔴 **보낸 문장을 한 줄씩 적어 둔다.**
#
#  🔴 「--check 는 select 만 보낸다」를 말로 하지 않는다. 이 둘을 지나는
#     문장을 **파일에 적고**, 끝에서 세어 찍는다. select 로 시작하지 않는
#     것이 하나라도 있으면 **그 문장을 그대로** 찍는다(sql_report).
#  🔴 **파일에 적는 까닭** — ql 은 거의 언제나 $( ) 안에서 불린다. 거기는
#     아래 껍데기(subshell)라 변수로 세면 **그 수가 밖으로 안 나온다.**
#     파일은 껍데기를 넘어 남는다.
#  🔴 db:migrate 와 pg_dump 는 이 둘을 지나지 않는다 — --go 에만 있고,
#     거기서는 따로 큰 글씨로 알린다.
#  🔵 그래서 --check 가 디스크에 남기는 것은 **로그 둘**이다(아래 파일과 LOG).
# ══════════════════════════════════════════════════════════════════════
SQLLOG="$D/setup/logs/23-sql-$MODE-$STAMP.txt"
touch "$SQLLOG" 2>/dev/null || true
SQL_N=0
SQL_SELECT_N=0
sql_note() { printf '%s\n' "$1" >> "$SQLLOG" 2>/dev/null || true; }
ql()  { # 한 칸만 받는다
  sql_note "$1"
  "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $LEAVE_DB -Atc \"$1\"" 2>/dev/null
}
qql() { # 표 꼴로 받는다
  sql_note "$1"
  "$DOCKER" exec dss-pg-app sh -c "psql -U \"\$POSTGRES_USER\" -d $LEAVE_DB -c   \"$1\"" 2>/dev/null
}
sql_report() {
  local n_other
  SQL_N=$(wc -l < "$SQLLOG" 2>/dev/null | tr -d ' ')
  SQL_N=${SQL_N:-0}
  SQL_SELECT_N=$(grep -c '^select' "$SQLLOG" 2>/dev/null | tr -d ' ')
  SQL_SELECT_N=${SQL_SELECT_N:-0}
  n_other=$((SQL_N - SQL_SELECT_N))
  say
  say "  ── 🔴 이 실행이 운영 DB 에 보낸 문장 ──"
  say "     모두 $SQL_N 개 · 그중 select $SQL_SELECT_N 개"
  if [ "$n_other" -gt 0 ] 2>/dev/null; then
    say "     🔴 select 로 시작하지 않는 문장이 ${n_other}개 있다:"
    grep -v '^select' "$SQLLOG" 2>/dev/null | sed 's/^/        /'
  else
    say "     ✓ select 가 아닌 문장: **0개**"
  fi
  say "     (그대로의 목록: $SQLLOG)"
  if [ "$MODE" = go ]; then
    say "     🔴 --go 는 이 밖에 **pg_dump 하나**(읽기)와 **db:migrate 하나**를"
    say "        돌린다. db:migrate 가 이 배포에서 DB 를 바꾸는 **유일한 자리**다."
  else
    say "     🔵 이 모드에는 db:migrate 도 pg_dump 도 **없다.**"
  fi
}

# ── tar 가 들고 있는 지문 ──────────────────────────────────────────────
tar_config_id() { # 1 tar 경로  → sha256:<지문>
  local raw v
  raw=$(tar -xOf  "$1" manifest.json 2>/dev/null) || raw=""
  [ -n "$raw" ] || raw=$(tar -xzOf "$1" manifest.json 2>/dev/null) || raw=""
  v=$(printf '%s' "$raw" \
      | sed -n 's/.*"Config"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  v=${v##*/}; v=${v%.json}
  [ -n "$v" ] || return 1
  echo "sha256:$v"
}
have_img() { "$DOCKER" image inspect "$1" >/dev/null 2>&1; }
img_id()   { "$DOCKER" image inspect "$1" --format '{{.Id}}' 2>/dev/null; }
md5_of()   { md5sum "$1" 2>/dev/null | awk '{print $1}'; }

verify_img() { # 1 태그 2 기대지문
  local got
  got=$(img_id "$1")
  if [ "$got" != "$2" ]; then
    bad "$1 지문이 tar 와 다르다 (NAS ${got:-없음} / tar $2)"
    return 1
  fi
  ok "$1 지문 맞음 ($(echo "$2" | cut -c1-19)…)"
}

force_load_hint() { # 1 태그
  say "    🔴 같은 태그로 **다시 구운** 이미지일 수 있다. 덮어쓰려면:"
  cmd "bash $0 --force-load"
  say "       (교체까지 한 번에 하려면:)"
  cmd "bash $0 --go --force-load"
}
bring_img() { # 1 태그 2 tar 3 지문
  if [ "$FORCE_LOAD" = 1 ]; then
    say "  · --force-load — $1 가 이미 있어도 **다시 싣는다**"
    "$DOCKER" load -i "$2" >/dev/null 2>&1 && ok "$1 다시 실었다" \
      || { bad "$1 싣기 실패 ($2)"; return 1; }
  elif have_img "$1"; then
    say "  · $1 는 이미 실려 있다 — 다시 싣지 않는다 (덮어쓰려면 --force-load)"
  else
    "$DOCKER" load -i "$2" >/dev/null 2>&1 && ok "$1 실었다" \
      || { bad "$1 싣기 실패 ($2)"; return 1; }
  fi
  verify_img "$1" "$3" || { force_load_hint "$1"; return 1; }
}

wait_http() { # 1 이름 2 포트 3 경로 4 컨테이너
  local i code
  for i in $(seq 1 90); do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://127.0.0.1:$2$3" 2>/dev/null)
    case "$code" in 2??|3??) ok "$1 응답 $code ($((SECONDS - T0))초)"; return 0 ;; esac
    sleep 2
  done
  bad "$1 이 180초 안에 대답하지 않았다 (마지막 ${code:-없음})"
  say "    로그:"
  cmd "$DOCKER logs --tail 50 $4"
  return 1
}

# ── compose 파일에서 서비스 한 덩어리만 잘라 낸다 ──────────────────────
# 🔴 파일 전체를 grep 하면 안 된다 — 주석 줄이 그대로 걸려서 꺼져 있는 서비스를
#    「가리킨다」고 세게 된다(11-deploy.sh 의 그 함정).
svc_block() { # 1 compose파일 2 서비스이름
  awk -v s="  $2:" '
    $0 == s { inb = 1; next }
    inb && /^  [A-Za-z]/ { inb = 0 }
    inb { print }
  ' "$1" | sed '/^[[:space:]]*#/d'
}
svc_image() { # 1 compose파일 2 서비스이름
  svc_block "$1" "$2" | sed -n 's/^[[:space:]]*image:[[:space:]]*//p' | head -1
}

# ══════════════════════════════════════════════════════════════════════
#  【이어받은 검사】 알림 링크의 **주소를 실제로 뽑아 본다**
#
#  🔴 2026-09-29 에 「통로가 있다(401 이 온다)」로 통과했는데, 그 통로가 내준
#     링크가 http://172.20.0.7:3500/ 이었다. 문이 있는지가 아니라 **무엇이
#     나오는지**를 봐야 잡힌다.
# ══════════════════════════════════════════════════════════════════════
NOTIFY_CB=/api/auth/sso/callback
href_shape() { # 1 주소  (값을 그대로 찍지 않는다 — 숫자를 N 으로 가린다)
  printf '%s' "$1" | cut -c1-48 | sed 's/[0-9]/N/g'
}
judge_base_url() { # 1 라벨 2 SSO_REDIRECT_URI 원본 3 기대 앞머리
  local label="$1" raw="$2" want="$3" base host
  case "$raw" in
    auto|auto:*|AUTO|"")
      bad "$label · SSO_REDIRECT_URI 가 auto(또는 빈 값)다 — 운영에서는 도메인을 적는다"
      say "      auto 는 이 기계의 랜 주소를 집는다. **컨테이너 안에서는 172.x 가 잡힌다.**"
      return 1 ;;
  esac
  case "$raw" in
    *"$NOTIFY_CB") base=${raw%"$NOTIFY_CB"} ;;
    *)
      bad "$label · SSO_REDIRECT_URI 가 $NOTIFY_CB 로 끝나지 않는다"
      say "      앱은 여기서 던지고 **알림이 통째로 빈 목록**이 된다. 꼴: $(href_shape "$raw")"
      return 1 ;;
  esac
  base=$(printf '%s' "$base" | sed 's:/*$::')
  host=${base#*://}; host=${host%%/*}; host=${host%%:*}
  case "$host" in
    172.*|10.*|192.168.*)
      bad "$label · 알림 주소가 **밖에서 닿지 않는 사설 주소**다 — $(href_shape "$base") 꼴"
      return 1 ;;
    *[!0-9.]*) : ;;   # 글자가 섞여 있다 = 이름(도메인)이다
    *)
      bad "$label · 알림 주소가 이름이 아니라 **IP** 다 — $(href_shape "$base") 꼴"
      return 1 ;;
  esac
  if [ "$base" = "$want" ]; then
    ok "$label · 알림 링크가 $want 로 시작한다"
    return 0
  fi
  bad "$label · 알림 주소가 $want 가 아니다 — $(href_shape "$base") 꼴"
  return 1
}
notify_href_check() { # 1 라벨 2 컨테이너 3 env파일 4 기대앞머리
  local label="$1" cname="$2" envf="$3" want="$4"
  local raw="" src=""
  say "  $label — 알림 링크가 무엇으로 시작하는지 본다"
  if running "$cname"; then
    raw=$("$DOCKER" exec "$cname" printenv SSO_REDIRECT_URI 2>/dev/null | tr -d '\r')
    [ -n "$raw" ] && src="지금 도는 $cname 안"
  fi
  if [ -z "$raw" ] && [ -f "$envf" ]; then
    raw=$(sed -n 's/^SSO_REDIRECT_URI=//p' "$envf" | head -1 | tr -d '\r')
    raw=${raw#\"}; raw=${raw%\"}
    raw=${raw#\'}; raw=${raw%\'}
    [ -n "$raw" ] && src="$(basename "$envf")"
  fi
  if [ -z "$raw" ]; then
    bad "$label · SSO_REDIRECT_URI 를 찾지 못했다 — 알림 주소를 계산할 수 없다"
    return 1
  fi
  say "    · $src 에서 읽었다 (🔴 값은 찍지 않는다)"
  judge_base_url "$label" "$raw" "$want"
}

# ══════════════════════════════════════════════════════════════════════
#  이미지 **안에** 이번 판이 들어 있는가 — 🔴 **짝으로** 본다
#
#  🔴 「아직 안 실린 것」은 ✗ 가 아니다. 못 봤다고 말하고 넘어간다.
#  🔴 대조 표시(CTRL)가 안 나오면 **판정하지 않는다** — 글자를 못 읽은 것과
#     옛 판인 것을 가를 수 없기 때문이다.
# ══════════════════════════════════════════════════════════════════════
pair_judge() { # 1 이름 2 새글자있나 3 옛글자있나 4 새판이름 5 옛판이름
  local label="$1" n="${2:-0}" o="${3:-0}" nw="$4" od="$5"
  if [ "$o" = 1 ]; then
    bad "🔴 $label — **$od 의 모습이다**(옛 글자가 아직 보인다). 옛 판을 올린 것이다"
    return 1
  fi
  if [ "$n" = 1 ]; then
    ok "$label — $nw 의 모습이다 (여름휴가가 들어 있다)"
    return 0
  fi
  say "    ⚠️ $label — 새 글자도 옛 글자도 **못 찾았다.** 압축기가 글자 모양을"
  say "       바꿨을 수 있다. 🔴 **판정하지 않는다** — 사람이 화면에서 봐야 한다."
  return 0
}
inside_app_check() { # 1 태그 2 라벨 3 옛태그
  local tag="$1" label="$2" old="$3"
  local out n1 n2 n3 o k1 k2 c
  if ! have_img "$tag"; then
    notloaded "$tag 가 아직 NAS 에 없어 **안을 못 봤다** — 먼저 실으세요"
    cmd "bash $0 --preload"
    return 0
  fi
  # 🔴 글자는 **-e 로 넘긴다.** sh -c 본문에 끼워 넣으면 괄호 · 물음표가 든
  #    글자에서 조용히 깨진다. 결과는 한 줄에 0/1 일곱 개로 받는다.
  out=$("$DOCKER" run --rm \
        -e A="$NEW_M1" -e B="$NEW_M2" -e C2="$NEW_M3" -e O="$OLD_M" \
        -e K1="$KEEP_M1" -e K2="$KEEP_M2" -e C="$CTRL" \
        --entrypoint sh "$tag" -c '
    r=""
    for w in "$A" "$B" "$C2" "$O" "$K1" "$K2" "$C"; do
      if grep -rlF -- "$w" /app/.next >/dev/null 2>&1; then r="$r 1"; else r="$r 0"; fi
    done
    echo "INSIDE$r"' 2>/dev/null \
    | grep '^INSIDE ' | head -1)
  n1=$(printf '%s' "$out" | awk '{print $2}')
  n2=$(printf '%s' "$out" | awk '{print $3}')
  n3=$(printf '%s' "$out" | awk '{print $4}')
  o=$(printf  '%s' "$out" | awk '{print $5}')
  k1=$(printf '%s' "$out" | awk '{print $6}')
  k2=$(printf '%s' "$out" | awk '{print $7}')
  c=$(printf  '%s' "$out" | awk '{print $8}')
  if [ "${c:-0}" != 1 ]; then
    say "    ⚠️ $tag 안을 글자로 뒤지지 못했다 — 대조 표시도 안 나왔다."
    say "       **판정하지 않는다.** 🔴 이때는 사람이 화면에서 봐야 한다."
    return 0
  fi
  ok "$label · 대조 표시를 찾았다 — 안을 실제로 읽었다는 뜻이다"
  pair_judge "$label · 여름휴가" "$n1" "$o" "$tag" "$old"
  [ "${n2:-0}" = 1 ] && ok "$label · 인쇄물의 「$NEW_M2」이 들어 있다 (거짓을 고친 자리)" \
    || say "    ⚠️ $label · 「$NEW_M2」을 못 찾았다 — 판정하지 않는다"
  [ "${n3:-0}" = 1 ] && ok "$label · 「$NEW_M3」가 들어 있다 (잔액 카드 · 인쇄물)" \
    || say "    ⚠️ $label · 「$NEW_M3」를 못 찾았다 — 판정하지 않는다"
  [ "${k1:-0}" = 1 ] && ok "$label · 회귀 — 월차가 그대로 있다" \
    || bad "🔴 $label · 월차가 **사라졌다** — $old 보다 **옛 판**을 올린 것이다"
  [ "${k2:-0}" = 1 ] && ok "$label · 회귀 — 결재선이 그대로 있다" \
    || bad "🔴 $label · 결재선이 **사라졌다** — $old 보다 **옛 판**을 올린 것이다"
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 **도구 이미지 안의 마이그레이션을 센다** (12번이 개선요청에서 한 그대로)
#
#  🔴 휴가의 drizzle 은 **이미지 안**이다. 그러니 「새 도구 이미지를 실었다」와
#     「그 안에 0002 가 있다」는 다른 일이다. 세어 본다.
#  🔴 _journal.json 의 tag 가 셋이 아니면 drizzle 은 0002 를 **아예 모른다** —
#     적용이 **조용히 0건**으로 끝나고, 그 뒤에 뜬 0.2 가 없는 표를 읽다 죽는다.
# ══════════════════════════════════════════════════════════════════════
MIG_SQL_TEXT=""
MIG_SQL_WHERE=""
tools_inside_check() { # 1 도구 태그
  local tag="$1" out_sql n_sql out_j n_j t rc=0
  if ! have_img "$tag"; then
    notloaded "$tag 가 아직 NAS 에 없어 **안을 못 봤다** — 먼저 실으세요"
    cmd "bash $0 --preload"
    return 0
  fi
  say "  $tag 구운 때: $("$DOCKER" images "$tag" --format '{{.CreatedAt}}' 2>/dev/null)"
  out_sql=$("$DOCKER" run --rm --entrypoint sh "$tag" \
            -c 'ls -1 /app/drizzle/*.sql 2>/dev/null' 2>&1)
  n_sql=$(printf '%s\n' "$out_sql" | grep -c '\.sql$')
  printf '%s\n' "$out_sql" | sed 's/^/      /' | head -10
  if [ "$n_sql" = "$N_MIG_WANT" ]; then
    ok "도구 이미지 안의 .sql 이 ${n_sql}개다 (기대 $N_MIG_WANT)"
  else
    bad "도구 이미지 안의 .sql 이 ${N_MIG_WANT}개가 아니다 (${n_sql}개)"
    say "    → 둘이면 **옛 도구 이미지**다(0002 가 없다). 그대로 적용하면"
    say "      **조용히 0건**으로 끝나고, 그 다음 0.2 가 없는 표를 읽다 죽는다."
    rc=1
  fi
  for t in $MIG_TAGS; do
    printf '%s\n' "$out_sql" | grep -q "/$t\.sql$" \
      && ok "$t.sql 있다" || { bad "$t.sql 이 **없다**"; rc=1; }
  done
  out_j=$("$DOCKER" run --rm --entrypoint sh "$tag" \
          -c 'cat /app/drizzle/meta/_journal.json 2>/dev/null' 2>&1)
  n_j=$(printf '%s\n' "$out_j" | grep -c '"tag"')
  if [ "$n_j" = "$N_MIG_WANT" ]; then
    ok "_journal.json 의 tag 가 ${n_j}줄이다"
  else
    bad "_journal.json 의 tag 가 ${N_MIG_WANT}줄이 아니다 (${n_j}줄)"
    say "    → 🔴 **적용이 0건으로 조용히 끝나는 바로 그 모양**이다."
    rc=1
  fi
  for t in $MIG_TAGS; do
    printf '%s\n' "$out_j" | grep -q "$t" \
      && ok "_journal 에 $t 가 있다" || { bad "_journal 에 $t 가 **없다**"; rc=1; }
  done
  return "$rc"
}

# 🔴 도구 이미지 안에서 **0002 의 글자 그대로**를 꺼낸다. 아래 검사 셋이 쓴다.
read_mig_sql() { # 1 도구 태그  → MIG_SQL_TEXT 에 담는다
  local tag="$1"
  MIG_SQL_TEXT=""
  MIG_SQL_WHERE=""
  have_img "$tag" || return 1
  MIG_SQL_WHERE=$("$DOCKER" run --rm --entrypoint sh "$tag" \
                  -c "ls -1 $MIG_GLOB 2>/dev/null | head -1" 2>/dev/null)
  [ -n "$MIG_SQL_WHERE" ] || return 1
  MIG_SQL_TEXT=$("$DOCKER" run --rm --entrypoint sh "$tag" \
                 -c "cat $MIG_GLOB 2>/dev/null" 2>/dev/null)
  [ -n "$MIG_SQL_TEXT" ] || return 1
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 **「지우는 문장」 검사** (19번의 잣대 그대로)
#
#  🔴 걸리면 **거기서 멈춘다.** 이번 판은 CREATE TABLE 하나뿐이라 통과해야 한다.
#  ⚠️ 이 계열에서 **ON DELETE 같은 글자 때문에 표만 더하는 판이 ✗ 가 된 적이
#     있다**(19번). 그래서 좁은 잣대로 **판정**하고, 넓은 그물은 **찍어만**
#     준다 — 걸린 줄을 사람이 눈으로 가릴 수 있게.
# ══════════════════════════════════════════════════════════════════════
destructive_check() {
  local nd nw nb rc=0
  if [ -z "$MIG_SQL_TEXT" ]; then
    bad "0002 의 .sql 을 도구 이미지에서 못 읽었다 — 검사할 글자가 없다"
    return 1
  fi
  say "  · 읽은 자리: ${MIG_SQL_WHERE:-?}"
  say "  · 그 파일 그대로 (🔴 사람이 눈으로도 보세요):"
  printf '%s\n' "$MIG_SQL_TEXT" | sed 's/^/      /'
  say
  # ── ㄱ. 진짜 그 파일인가
  printf '%s\n' "$MIG_SQL_TEXT" | grep -qF "$MIG_MARK" \
    && ok "0002 안에 $MIG_MARK 가 있다" \
    || { bad "0002 안에 $MIG_MARK 가 **없다** — 🔴 다른 파일이다"; rc=1; }
  printf '%s\n' "$MIG_SQL_TEXT" | grep -qF "$MIG_MARK2" \
    && ok "0002 가 summer_days 를 numeric(5,1) DEFAULT 3 으로 만든다" \
    || { bad "summer_days 의 꼴이 기대와 다르다 — 🔴 다른 파일이다"; rc=1; }
  printf '%s\n' "$MIG_SQL_TEXT" | grep -qF "$NEW_CK1" \
    && ok "CHECK $NEW_CK1 이 글자에 있다" \
    || { bad "CHECK $NEW_CK1 이 **없다**"; rc=1; }
  printf '%s\n' "$MIG_SQL_TEXT" | grep -qF "$NEW_CK2" \
    && ok "CHECK $NEW_CK2 가 글자에 있다" \
    || { bad "CHECK $NEW_CK2 가 **없다**"; rc=1; }
  # ── ㄴ. 🔴 지우는 문장 — **좁은 잣대로 판정한다**
  nd=$(printf '%s\n' "$MIG_SQL_TEXT" | grep -ciE "$DESTRUCTIVE_RE")
  if [ "${nd:-0}" = 0 ]; then
    ok "🔴 지우는 문장이 **하나도 없다** (DROP TABLE · TRUNCATE · DELETE FROM · ALTER … DROP)"
  else
    bad "🔴 **지우는 문장이 있다** (${nd}줄) — 이번 판에는 없어야 한다"
    say "    걸린 줄 — 🔴 **왜 걸렸는지 눈으로 가리세요**:"
    printf '%s\n' "$MIG_SQL_TEXT" | grep -niE "$DESTRUCTIVE_RE" | sed 's/^/        /' | head -8
    rc=1
  fi
  # ── ㄷ. 넓은 그물 — 🔵 **멈추지 않는다. 찍어만 준다**
  nw=$(printf '%s\n' "$MIG_SQL_TEXT" | grep -ciE "$WIDE_RE")
  if [ "${nw:-0}" = 0 ]; then
    ok "넓은 그물(DROP · DELETE · TRUNCATE 라는 **글자 자체**)에도 0줄이다"
  else
    say "    ⚠️ 넓은 그물에 ${nw}줄이 걸렸다 — 🔵 **✗ 가 아니다.** 아래를 보세요:"
    printf '%s\n' "$MIG_SQL_TEXT" | grep -niE "$WIDE_RE" | sed 's/^/        /' | head -8
    say "       (19번이 ON DELETE restrict 때문에 멀쩡한 판을 ✗ 로 셀 뻔했다.)"
  fi
  # ── ㄹ. 🔴 바인딩 자리가 섞였는가
  nb=$(printf '%s\n' "$MIG_SQL_TEXT" | grep -cE "$BIND_RE")
  if [ "${nb:-0}" = 0 ]; then
    ok "🔴 바인딩 자리(\$1 꼴)가 **없다** — CHECK 의 1 이 숫자 그대로다"
  else
    bad "🔴 바인딩 자리(\$1 꼴)가 ${nb}줄에 있다 — **이 마이그레이션은 돌릴 수 없다**"
    printf '%s\n' "$MIG_SQL_TEXT" | grep -nE "$BIND_RE" | sed 's/^/        /' | head -5
    say "    → drizzle 의 sql 템플릿이 상수를 바인딩 자리로 구운 것이다."
    say "      🔴 고치지 말고 **먼저 알리세요** — 저장소에서 다시 뽑아야 한다."
    rc=1
  fi
  return "$rc"
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 **이미 있는가** — 적용 전 판정 (두 번 돌려도 안전해야 한다)
#
#  MIG_VERDICT 가 아래 넷 중 하나가 된다:
#    apply  — 아직이다. 적용한다          (줄 2 · 표 없음)
#    done   — 이미 적용돼 있다. 건너뛴다  (줄 3 · 표 있음)
#    mixed  — 🔴 어긋났다. 멈춘다
#    unknown— DB 를 못 봤다
# ══════════════════════════════════════════════════════════════════════
MIG_VERDICT=unknown
N_MIG_DB=""
HAVE_TBL=""
mig_verdict() {
  MIG_VERDICT=unknown
  if ! pg_up; then
    bad "dss-pg-app 이 떠 있지 않다 — 마이그레이션 상태를 못 봤다"
    return 1
  fi
  if [ -z "$(ql "select to_regclass('drizzle.__drizzle_migrations')")" ]; then
    bad "$LEAVE_DB 에 drizzle.__drizzle_migrations 가 없다 — 첫 설치가 안 된 DB 다"
    return 1
  fi
  N_MIG_DB=$(ql "select count(*) from drizzle.__drizzle_migrations")
  HAVE_TBL=$(ql "select count(*) from information_schema.tables where table_schema = 'public' and table_name = '$NEW_TBL'")
  say "  · 운영 DB($LEAVE_DB)에 적용된 줄: ${N_MIG_DB:-?}  (적용 전 $N_MIG_HAVE · 뒤 $N_MIG_WANT)"
  say "  · 표 $NEW_TBL: ${HAVE_TBL:-?} 개  (적용 전 0 · 뒤 1)"
  if [ "${N_MIG_DB:-x}" = "$N_MIG_HAVE" ] && [ "${HAVE_TBL:-x}" = 0 ]; then
    MIG_VERDICT=apply
    ok "적용 전 상태가 맞다 — --go 가 0002 를 적용한다"
    return 0
  fi
  if [ "${N_MIG_DB:-x}" = "$N_MIG_WANT" ] && [ "${HAVE_TBL:-x}" = 1 ]; then
    MIG_VERDICT=done
    ok "🔵 **이미 적용이 끝난 DB 다** — --go 는 적용을 건너뛴다(두 번 돌려도 안전)"
    return 0
  fi
  MIG_VERDICT=mixed
  bad "🔴 줄 수와 표가 **서로 안 맞는다** (줄 ${N_MIG_DB:-?} · 표 ${HAVE_TBL:-?})"
  if [ "${HAVE_TBL:-0}" = 1 ] && [ "${N_MIG_DB:-0}" = "$N_MIG_HAVE" ]; then
    say "    → 🔴 표는 있는데 **적용 기록이 없다.** 누가 손으로 만든 것이다."
    say "      그대로 적용하면 drizzle 이 같은 표를 또 만들다 죽는다."
  elif [ "${HAVE_TBL:-0}" = 0 ] && [ "${N_MIG_DB:-0}" = "$N_MIG_WANT" ]; then
    say "    → 🔴 기록은 있는데 **표가 없다.** 적용이 중간에 깨졌거나 누가 지웠다."
  else
    say "    → 🔴 남의 변경이 섞였거나 누가 손으로 건드린 것이다."
  fi
  say "      🔴 **고치지 말고 먼저 알리세요.**"
  return 1
}

# ══════════════════════════════════════════════════════════════════════
#  🔴 적용 **뒤** 실제로 들어 있는가 — 「했다」가 아니라 「들어 있다」
#
#  🔴 「만든 것과 도는 것은 다르다」. CHECK 둘이 **진짜로 붙었는지**까지
#     pg_get_constraintdef 로 글자를 받아 본다. 전부 select 다.
# ══════════════════════════════════════════════════════════════════════
table_verify() { # 1 "적용 전"/"적용 뒤" 같은 꼬리표
  local tag="$1" v def owner priv rc=0
  v=$(ql "select count(*) from information_schema.tables where table_schema = 'public' and table_name = '$NEW_TBL'")
  if [ "${v:-0}" = 1 ]; then
    ok "$tag · 표 $NEW_TBL 이 **있다**"
  else
    bad "$tag · 표 $NEW_TBL 이 **없다** (${v:-?}) — 🔴 $TAG_APP 를 띄우면 첫 화면이 죽는다"
    return 1
  fi
  v=$(ql "select count(*) from information_schema.columns where table_name = '$NEW_TBL' and column_name = '$NEW_COL'")
  [ "${v:-0}" = 1 ] && ok "$tag · 칸 $NEW_COL 이 있다" \
    || { bad "$tag · 칸 $NEW_COL 이 **없다** (${v:-?})"; rc=1; }
  v=$(ql "select numeric_precision || ',' || numeric_scale || ',' || column_default from information_schema.columns where table_name = '$NEW_TBL' and column_name = '$NEW_COL'")
  say "    · $NEW_COL 의 자리수,소수점,기본값: ${v:-?}   (기대 5,1,3)"
  # ── CHECK 둘 — 🔴 **붙었는가**와 **무엇이 적혔는가**를 따로 본다
  v=$(ql "select count(*) from pg_constraint where conname = '$NEW_CK1'")
  [ "${v:-0}" = 1 ] && ok "$tag · CHECK $NEW_CK1 이 붙었다" \
    || { bad "$tag · CHECK $NEW_CK1 이 **없다** (${v:-?})"; rc=1; }
  v=$(ql "select count(*) from pg_constraint where conname = '$NEW_CK2'")
  [ "${v:-0}" = 1 ] && ok "$tag · CHECK $NEW_CK2 가 붙었다" \
    || { bad "$tag · CHECK $NEW_CK2 가 **없다** (${v:-?})"; rc=1; }
  def=$(ql "select pg_get_constraintdef(oid) from pg_constraint where conname = '$NEW_CK1'")
  say "    · $NEW_CK1 에 적힌 글자: ${def:-?}"
  if [ -n "$def" ]; then
    case "$def" in
      *'$'*) bad "🔴 CHECK 에 바인딩 자리가 구워졌다 — 1 이 숫자가 아니다"; rc=1 ;;
      *1*)   ok "🔴 CHECK 의 1 이 **숫자 그대로**다 (바인딩 자리가 아니다)" ;;
      *)     bad "🔴 CHECK 에 1 이 안 보인다 — 글자를 보세요"; rc=1 ;;
    esac
  fi
  def=$(ql "select pg_get_constraintdef(oid) from pg_constraint where conname = '$NEW_CK2'")
  say "    · $NEW_CK2 에 적힌 글자: ${def:-?}"
  # ── 🔴 **앱이 읽을 수 있는 표인가** — 주인과 권한을 본다
  owner=$(ql "select tableowner from pg_tables where tablename = '$NEW_TBL'")
  if [ "$owner" = "$LEAVE_ROLE" ]; then
    ok "$tag · 표의 주인이 $LEAVE_ROLE 이다 — 앱이 그대로 읽고 쓴다"
  else
    bad "🔴 $tag · 표의 주인이 ${owner:-?} 다 ($LEAVE_ROLE 이어야 한다)"
    say "      → 앱이 못 읽으면 첫 화면이 죽는다. 🔴 먼저 알리세요."
    rc=1
  fi
  priv=$(ql "select has_table_privilege('$LEAVE_ROLE', '$NEW_TBL', 'select')")
  [ "$priv" = t ] && ok "$tag · $LEAVE_ROLE 이 그 표를 **select 할 수 있다**" \
    || { bad "🔴 $tag · $LEAVE_ROLE 이 그 표를 못 읽는다 (${priv:-?})"; rc=1; }
  # ── 🔵 줄은 **없는 것이 맞다**
  v=$(ql "select count(*) from $NEW_TBL")
  say "    · $NEW_TBL 의 줄: ${v:-?} 건"
  if [ "${v:-0}" = 0 ]; then
    say "      🔵 **0건이 맞다.** 줄이 없으면 앱이 기본값 3일로 읽는다."
    say "         관리자가 설정 화면에서 저장할 때 그 줄이 처음 생긴다."
  else
    say "      🔵 줄이 있다 — 누군가 이미 설정 화면에서 저장한 것이다:"
    qql "select id, summer_days, updated_at::date from $NEW_TBL" | sed 's/^/        /'
  fi
  return "$rc"
}

# ══════════════════════════════════════════════════════════════════════
#  권한 — 🔴 **읽기만 한다. 어떤 모드에서도 이 표를 고치지 않는다.**
#
#  🔴 「권한은 코드가 아니라 운영 DB 가 정한다」. 휴가는 A/S 와 달리
#     role_permissions 표가 없다 — web_users.role 이 MEMBER / LEAVE_ADMIN
#     둘뿐이고, **설정 화면은 LEAVE_ADMIN 만** 연다(requireAdmin).
#  🔴 **사람 이름을 찍지 않는다. 수만 센다.**
# ══════════════════════════════════════════════════════════════════════
perm_check() {
  local n_admin n_user
  if ! pg_up; then
    say "  · dss-pg-app 이 떠 있지 않다 — 권한을 못 봤다(✗ 는 아니다)"
    return 0
  fi
  n_user=$(ql "select count(*) from web_users where is_deleted = false")
  n_admin=$(ql "select count(*) from web_users where is_deleted = false and is_active = true and role = 'LEAVE_ADMIN'")
  say "  · 살아 있는 계정: ${n_user:-?} 개 (🔴 이름은 찍지 않는다)"
  say "  · 그중 휴가 관리자(LEAVE_ADMIN): ${n_admin:-?} 명"
  if [ "${n_admin:-0}" -ge 1 ] 2>/dev/null; then
    ok "🔵 여름휴가 일수를 바꿀 수 있는 사람이 있다 — 설정 화면이 열린다"
  else
    bad "🔴 휴가 관리자가 **한 명도 없다** — 여름휴가 일수를 아무도 못 바꾼다"
    say "    🔵 그래도 **기능은 돈다** — 줄이 없으면 앱이 기본값 3일로 읽는다."
    say "       바꿀 수 없을 뿐이다. 🔴 고치지 말고 알리세요."
  fi
  say "  🔵 **이번 판은 새 권한을 하나도 만들지 않았다.** 여름휴가 잔액은"
  say "     모든 직원이 자기 첫 화면에서 본다(권한 칸이 따로 없다)."
  return 0
}

# ══════════════════════════════════════════════════════════════════════
#  .env 읽기 — 🔴 **읽기만 한다. 이 스크립트는 .env 를 한 글자도 안 고친다.**
#
#  🔵 이번 판은 **새 설정이 하나도 없다.** 여름휴가 일수는 .env 가 아니라
#     **DB 의 그 표**에서 온다(그래서 화면에서 바꿀 수 있다).
# ══════════════════════════════════════════════════════════════════════
env_count_of() { # 1 파일 2 키 → 그 이름으로 시작하는 줄 수
  [ -f "$1" ] || { echo 0; return 0; }
  grep -c "^$2=" "$1" 2>/dev/null | tr -d ' '
}
env_val_of() { # 1 파일 2 키  → 값
  local v
  [ -f "$1" ] || return 0
  v=$(sed -n "s/^$2=//p" "$1" | head -1 | tr -d '\r')
  v=${v#\"}; v=${v%\"}
  v=${v#\'}; v=${v%\'}
  printf '%s' "$v"
}

# ══════════════════════════════════════════════════════════════════════
#  보기 — --check 와 --go 가 **같은 것**을 본다
#
#  🔴 --go 는 이 함수를 먼저 통째로 돌리고, 하나라도 ✗ 가 있으면 **아무것도
#     바꾸지 않고 멈춘다.** 여기서 끝나면 직원은 아무것도 느끼지 못한다.
# ══════════════════════════════════════════════════════════════════════
CF_EFF=$CF   # 실제로 들여다볼 compose (compose_incoming 이 정한다)
EXP_APP=""
EXP_TOOLS=""
SVCS=""

see_tar() { # 1 태그 2 tar 3 tar지문 4 기대바이트 5 기대md5 6 기대지문 7 올릴파일이름
  local tag="$1" f="$2" got="$3" wsz="$4" wmd5="$5" wcfg="$6" up="$7" n m
  if [ ! -s "$f" ]; then
    notyet "$tag 의 tar 가 아직 NAS 에 없다: $f"
    say "    → 개발 PC(PowerShell)에서 올리세요. 🔴 scp 에 -O 를 붙입니다:"
    say "      scp -O $up dss-nas:/volume1/dss/images/"
    return 1
  fi
  n=$(stat -c '%s' "$f" 2>/dev/null)
  m=$(md5_of "$f")
  say "    · 지금 이 tar: 바이트 ${n:-?} · md5 ${m:-?}"
  if [ -z "$wsz" ] || [ -z "$wmd5" ] || [ -z "$wcfg" ]; then
    say "    ⚠️ 🔴 **$tag 의 기대값이 비어 있다.** 개발 PC 에서 구운 뒤 이 스크립트"
    say "       머리말의 차례대로 재어 채우세요. 채우기 전에는 --go 가 시작하지 않습니다."
    [ -n "$got" ] && say "    · 이 tar 안 Config 지문: $got"
    return 0
  fi
  [ "$n" = "$wsz" ] && ok "$tag · 바이트 $n" \
    || bad "$tag 의 바이트가 $wsz 가 아니다 ($n) — 옮기다 끊겼다"
  [ "$m" = "$wmd5" ] && ok "$tag · md5 $m" \
    || bad "$tag 의 md5 가 $wmd5 가 아니다 (${m:-못 읽음}) — 파일이 상했다"
  if [ -z "$got" ]; then
    bad "$tag 의 tar 에서 manifest.json 을 읽지 못했다: $f"
    return 1
  fi
  if [ "$got" = "$wcfg" ]; then
    ok "$tag · tar 안 Config 지문이 기대값과 같다 ($(echo "$got" | cut -c1-19)…)"
  else
    bad "$tag · tar 안 Config 지문이 기대값과 다르다"
    say "      tar   $got"
    say "      기대  $wcfg"
    say "      🔴 **다른 판을 올린 것**이거나 옮기다 깨진 것이다."
  fi
}

run_checks() {
  local tag s t f db n_bk nlog k v n
  local FREE_KB FREE_H code h

  # ── 1-ㄱ. 올릴 파일 — 이미지 tar **둘** ─────────────────────────────
  step "1-ㄱ. 올린 파일 (이미지 tar **둘** · compose 하나. 그것이 전부다)"
  say "  🔵 21 · 22번과 달리 **둘째 tar 가 도구 이미지**다 — 휴가의 마이그레이션은"
  say "     이미지 안에 있어서, 묶음(tar.gz)으로 올릴 길이 없다(머리말 ②)."
  say "  🔴 **마이그레이션 묶음은 올릴 것이 없다.** 이 스크립트는 그 파일을"
  say "     쳐다보지도 않는다 — 대신 **도구 이미지 안을 센다**(1-ㅋ)."
  EXP_APP=$(tar_config_id "$TAR_APP" 2>/dev/null) || EXP_APP=""
  EXP_TOOLS=$(tar_config_id "$TAR_TOOLS" 2>/dev/null) || EXP_TOOLS=""
  see_tar "$TAG_APP" "$TAR_APP" "$EXP_APP" \
          "$SZ_APP" "$MD5_APP" "$WANT_CFG_APP" dss-leave-0.2.tar
  see_tar "$TAG_TOOLS" "$TAR_TOOLS" "$EXP_TOOLS" \
          "$SZ_TOOLS" "$MD5_TOOLS" "$WANT_CFG_TOOLS" dss-leave-tools-2.tar
  say "  🔵 0.1 은 tar 74,208,768 · 도구 1 은 189,109,760 이었다(13번 실측)."
  say "     이번 판은 화면 몇 장과 규칙 한 덩이가 는 것뿐이라 **비슷한 것이 정상**이다."

  # ── 1-ㄴ. NAS 에 실린 이미지 ────────────────────────────────────────
  step "1-ㄴ. NAS 에 실린 이미지 (올라가는 둘 · 건드리지 않는 여덟)"
  if have_img "$TAG_APP"; then
    [ -n "$EXP_APP" ] && { verify_img "$TAG_APP" "$EXP_APP" || force_load_hint "$TAG_APP"; }
  else
    notloaded "$TAG_APP 는 아직 NAS 에 실리지 않았다 — --preload 나 --go 가 싣는다"
  fi
  if have_img "$TAG_TOOLS"; then
    [ -n "$EXP_TOOLS" ] && { verify_img "$TAG_TOOLS" "$EXP_TOOLS" || force_load_hint "$TAG_TOOLS"; }
  else
    notloaded "$TAG_TOOLS 는 아직 NAS 에 실리지 않았다 — --preload 나 --go 가 싣는다"
  fi
  say "  🔴 지문이 어긋나면 **혼자 고쳐지지 않는다.** 태그가 같으면 docker load 를"
  say "     그냥 부르는 것으로는 안 바뀐다 — 위에 찍힌 --force-load 를 쓰세요."
  say "  🔴 건드리지 않는 여덟 — 이미 실려 있어야 한다 (다시 싣지 않는다):"
  for tag in "$KEEP_AUTH" "$KEEP_AS" "$KEEP_ASTOOLS" "$KEEP_METERS" \
             "$KEEP_METERSTOOLS" "$KEEP_IMP" "$KEEP_IMPTOOLS" "$KEEP_PO"; do
    have_img "$tag" && ok "$tag 실려 있다 ($(img_id "$tag" | cut -c1-19)…)" \
      || bad "$tag 가 NAS 에 없다 — 🔴 앞 배포가 되돌아갔거나 누가 지웠다"
  done
  say "  🔴 되돌아갈 옛 이미지 둘도 그대로 둔다 — 되돌리기가 그것을 쓴다."
  have_img "$OLD_APP" && ok "$OLD_APP 도 아직 있다 (되돌릴 길이 열려 있다)" \
    || say "    ⚠️ $OLD_APP 가 NAS 에 없다 — 되돌리려면 tar 를 다시 올려야 한다"
  have_img "$OLD_TOOLS" && ok "$OLD_TOOLS 도 아직 있다 (태그를 올린 까닭이 이것이다)" \
    || say "    ⚠️ $OLD_TOOLS 가 NAS 에 없다 — 같은 태그로 덮어쓴 것이 아닌지 보세요"

  # ── 1-ㄷ. 권한 — 🔴 읽기만 한다 ─────────────────────────────────────
  step "1-ㄷ. 여름휴가를 **누가 바꿀 수 있는가** (운영 DB 를 읽는다 · select 만)"
  say "  🔴 「권한은 코드가 아니라 운영 DB 가 정한다」 — 그래서 읽어 보고 말한다."
  perm_check

  # ── 1-ㄹ. leave.env — 🔴 **있는가만 본다. 한 줄도 안 적는다** ───────
  step "1-ㄹ. leave.env — 🔴 **이번 판은 한 줄도 안 적는다. 있는가만 본다**"
  say "  🔵 여름휴가 일수는 .env 가 아니라 **DB 의 표**에서 온다 — 그래서"
  say "     화면에서 바꿀 수 있다. 새 설정이 **하나도 없다.**"
  say "  🔴 이 PC(dss-deploy)의 nas/env/*.env 를 NAS 로 **올리지 마세요.**"
  say "     그 사본에는 NAS 에만 있는 줄들이 빠져 있습니다."
  if [ -f "$LEAVE_ENV" ]; then
    s=$(stat -c '%a' "$LEAVE_ENV" 2>/dev/null)
    [ "$s" = 600 ] && ok "leave.env 있다 · 모드 600" \
      || bad "leave.env 의 모드가 ${s:-?} 다 (600 이어야 한다 — 남이 읽는다)"
    s=$(stat -c '%U:%G' "$LEAVE_ENV" 2>/dev/null)
    [ "$s" = "root:root" ] || bad "leave.env 의 주인이 ${s:-?} 다 (root:root 이어야 한다)"
    for k in $ENV_KEYS; do
      n=$(env_count_of "$LEAVE_ENV" "$k")
      if [ "${n:-0}" = 0 ]; then
        bad "leave.env · $k 가 **없다** — 🔴 앱이 뜨자마자 죽는다"
      elif [ "${n:-0}" -gt 1 ] 2>/dev/null; then
        bad "🔴 leave.env · $k 가 **두 줄 이상** 있다 — 나중 것이 이긴다. 하나만 남기세요"
      else
        ok "leave.env · $k 있다 (🔴 값은 안 찍는다)"
      fi
    done
    for k in $ENV_FORBIDDEN; do
      [ "$(env_count_of "$LEAVE_ENV" "$k")" = 0 ] \
        && ok "leave.env 에 $k 가 없다 (맞다 — compose·이미지가 넘긴다)" \
        || bad "leave.env 에 $k 가 **있다** — 지우세요(두 곳에 같은 값이 생긴다)"
    done
    v=$(env_val_of "$LEAVE_ENV" DEV_FAKE_LOGIN_ENABLED)
    [ "$v" = false ] && ok "DEV_FAKE_LOGIN_ENABLED 가 false 다" \
      || bad "🔴 DEV_FAKE_LOGIN_ENABLED 가 ${v:-?} 다 — 운영에서는 false 여야 한다"
    v=$(env_val_of "$LEAVE_ENV" SESSION_COOKIE_SECURE)
    [ "$v" = true ] && ok "SESSION_COOKIE_SECURE 가 true 다 (https 전용)" \
      || bad "SESSION_COOKIE_SECURE 가 ${v:-?} 다 — https 라 true 여야 한다"
  else
    bad "leave.env 가 없다: $LEAVE_ENV"
    say "    → 없는 env_file 하나면 docker compose 명령이 **통째로** 안 먹는다."
  fi
  for f in as.env po.env auth.env meters.env improvements.env; do
    [ -f "$ENVD/$f" ] || bad "$f 가 없다: $ENVD/$f (compose 가 통째로 실패한다)"
  done

  # ── 1-ㅁ. compose ───────────────────────────────────────────────────
  step "1-ㅁ. compose ($CF_EFF)"
  say "  🔴 이번 판에서 compose 가 바뀌는 자리는 **둘뿐**이다:"
  say "     ㄱ) app-leave 의 image 한 줄 ($OLD_APP → $TAG_APP)"
  say "     ㄴ) tools-leave 의 image 한 줄 ($OLD_TOOLS → $TAG_TOOLS)"
  say "     🔴 지시서는 「한 줄」이었다. **둘인 까닭은 머리말 ②** — 휴가의"
  say "        마이그레이션이 도구 **이미지 안**에 있어서다."
  say "     🔵 tools-leave 는 profiles: [tools] 라 **떠 있지 않다.** 그 줄을"
  say "        바꿔도 멈추는 것도 뜨는 것도 없다."
  say "     다른 것이 흔들렸으면 남의 것이 섞인 것이다."
  if compose_at "$CF_EFF" config --quiet >/dev/null 2>&1; then
    ok "문법 통과"
  else
    bad "문법 오류가 있다"
    compose_at "$CF_EFF" config --quiet 2>&1 | sed 's/^/    /' | head -10
  fi
  SVCS=$(compose_at "$CF_EFF" config --services 2>/dev/null)
  for s in app-auth app-as tools-as app-meters tools-meters \
           app-improvements tools-improvements app-po app-leave tools-leave; do
    echo "$SVCS" | grep -qx "$s" && ok "서비스 목록에 $s 가 있다" \
      || bad "서비스 목록에 $s 가 없다 — 주석으로 꺼져 있다"
  done
  see_tag() { # 1 서비스 2 태그 3 사람이 읽을 이름
    svc_block "$CF_EFF" "$1" | grep -q "image: $2$" \
      && ok "$1 가 $2 를 가리킨다 ($3)" \
      || bad "$1 의 태그가 $2 가 아니다 ($3) — 지금 값: $(svc_image "$CF_EFF" "$1")"
  }
  say "  올라가는 둘:"
  see_tag "$LEAVE_SVC"       "$TAG_APP"   "휴가"
  see_tag "$LEAVE_TOOLS_SVC" "$TAG_TOOLS" "휴가 도구 (🔴 마이그레이션이 이 안에 있다)"
  if [ "$(svc_image "$CF_EFF" "$LEAVE_SVC")" = "$OLD_APP" ]; then
    say "    🔴 compose 가 아직 **옛 태그**를 가리킵니다. 개발 PC 에서 고친 파일을"
    say "       아래에 올리면 --go 가 시험하고 제자리로 옮깁니다:"
    say "         $INCOMING"
  fi
  say "  🔴 건드리지 않는 여덟 (흔들렸으면 남의 것이 섞인 것이다):"
  see_tag app-auth            "$KEEP_AUTH"        "포털 · 그대로"
  see_tag app-as              "$KEEP_AS"          "A/S · 그대로"
  see_tag tools-as            "$KEEP_ASTOOLS"     "A/S 도구 · 그대로"
  see_tag app-meters          "$KEEP_METERS"      "계측기 · 그대로"
  see_tag tools-meters        "$KEEP_METERSTOOLS" "계측기 도구 · 그대로"
  see_tag app-improvements    "$KEEP_IMP"         "개선요청 · 그대로"
  see_tag tools-improvements  "$KEEP_IMPTOOLS"    "개선요청 도구 · 그대로"
  see_tag app-po              "$KEEP_PO"          "PO/내자 · 그대로"
  # ── 휴가 쪽 줄들이 그대로인가 (13번이 세운 모양)
  svc_block "$CF_EFF" "$LEAVE_SVC" | grep -q "127.0.0.1:$LEAVE_PORT:$LEAVE_INNER" \
    && ok "$LEAVE_SVC 가 127.0.0.1:$LEAVE_PORT 으로만 열린다" \
    || bad "$LEAVE_SVC 의 포트가 127.0.0.1:$LEAVE_PORT:$LEAVE_INNER 가 아니다"
  svc_block "$CF_EFF" "$LEAVE_SVC" | grep -q './env/leave.env' \
    && ok "$LEAVE_SVC 가 ./env/leave.env 를 읽는다" \
    || bad "$LEAVE_SVC 가 ./env/leave.env 를 안 읽는다"
  svc_block "$CF_EFF" "$LEAVE_SVC" | grep -q 'DATABASE_URL:' \
    && ok "$LEAVE_SVC 에 DATABASE_URL 이 있다" \
    || bad "🔴 $LEAVE_SVC 에 DATABASE_URL 이 없다 — 앱이 뜨자마자 죽는다"
  svc_block "$CF_EFF" "$LEAVE_TOOLS_SVC" | grep -q 'DATABASE_URL:' \
    && ok "$LEAVE_TOOLS_SVC 에 DATABASE_URL 이 있다" \
    || bad "🔴 $LEAVE_TOOLS_SVC 에 DATABASE_URL 이 없다 — db:migrate 가 곧장 죽는다"
  svc_block "$CF_EFF" "$LEAVE_TOOLS_SVC" | grep -q 'profiles:.*tools' \
    && ok "$LEAVE_TOOLS_SVC 에 profiles: [tools] 가 있다 (up -d 로 안 뜬다)" \
    || bad "🔴 $LEAVE_TOOLS_SVC 에 profiles 가 없다 — 상시 서비스가 하나 늘어난다"
  svc_block "$CF_EFF" "$LEAVE_SVC" | grep -qE '^[[:space:]]*volumes:' \
    && say "    ⚠️ $LEAVE_SVC 에 볼륨이 붙어 있다 — 이 앱은 파일을 올리지 않는다" \
    || ok "$LEAVE_SVC 에 볼륨이 없다 (맞다 — 이 앱에는 업로드 폴더가 없다)"
  svc_block "$CF_EFF" "$LEAVE_TOOLS_SVC" | grep -qE '^[[:space:]]*volumes:' \
    && bad "🔴 $LEAVE_TOOLS_SVC 에 볼륨이 생겼다 — 13번에는 없던 줄이다. 먼저 알리세요" \
    || ok "$LEAVE_TOOLS_SVC 에 볼륨이 없다 (맞다 — drizzle 은 **이미지 안**이다)"
  # 🔴 사내 전용 원칙 — DB 에 ports: 를 더하지 않는다.
  svc_block "$CF_EFF" db-app | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-app 에 ports: 가 생겼다 — 사내 전용 원칙을 깬다. 고치지 말고 알리세요" \
    || ok "db-app 에 ports: 가 없다 (DB 는 호스트 포트를 하나도 안 연다)"
  svc_block "$CF_EFF" db-auth | grep -q '^[[:space:]]*ports:' \
    && bad "🔴 db-auth 에 ports: 가 생겼다 — 고치지 말고 알리세요" \
    || ok "db-auth 에 ports: 가 없다"

  # ── 1-ㅂ. 🔴 마이그레이션 — 지금 어디까지 와 있는가 ─────────────────
  step "1-ㅂ. 🔴 마이그레이션 $NEW_MIG ($N_MIG_HAVE → $N_MIG_WANT)"
  say "  🔴 **표 하나를 더하기만 한다.** 지우는 문장이 없다."
  say "  🔵 줄이 없어도 앱이 기본값 3일로 읽는다 — 표만 서면 바로 돈다."
  mig_verdict
  if read_mig_sql "$TAG_TOOLS"; then
    say
    say "  🔴 **「지우는 문장」 검사** — 도구 이미지에서 .sql 을 꺼내 읽는다:"
    destructive_check || say "    🔴 위 ✗ 때문에 --go 는 적용을 시작하지 않는다."
  else
    notloaded "도구 이미지($TAG_TOOLS)가 없거나 그 안에 0002 가 없어 **글자를 못 읽었다**"
    say "    → 먼저 실으세요. 그 뒤에 이 검사가 돈다:"
    cmd "bash $0 --preload"
  fi
  if [ "${HAVE_TBL:-x}" = 1 ]; then
    say
    say "  🔵 표가 이미 있으니 **지금 모습**도 적어 둔다 (전부 select):"
    table_verify "지금" || true
  fi

  # ── 1-ㅅ. 🔴 야간 백업 다섯 · 야간 완전삭제 (읽기만 한다) ───────────
  step "1-ㅅ. 야간 백업 다섯 · 야간 완전삭제 (읽기만 한다)"
  say "  🔴 이번 판이 보는 것은 **$LEAVE_DB** 다 (21 · 22번은 dss_as 였다)."
  say "  🔵 야간 백업은 **02:30** 이다 — 자정 넘어 배포하면 여기 걸린다."
  say "  최근 백업 일곱:"
  ls -lt "$BKD/db/" 2>/dev/null | head -7 | sed 's/^/      /'
  n_bk=0
  for db in dss_auth dss_meters dss_as dss_improvements dss_leave; do
    f=$(ls -1t "$BKD/db/${db}_${TODAY}_"*.dump 2>/dev/null | head -1)
    if [ -n "$f" ] && [ -s "$f" ]; then
      ok "오늘 백업 $db — $(basename "$f") ($(du -h "$f" | cut -f1))"
      n_bk=$((n_bk + 1))
    else
      bad "오늘($TODAY) 뜬 $db 백업이 없다"
    fi
  done
  if [ "$n_bk" = 5 ]; then
    ok "🔴 오늘 백업이 **다섯**이다 — 야간 백업이 실제로 돌았다"
  else
    bad "🔴 오늘 백업이 ${n_bk}개뿐이다 (다섯이어야 한다)"
    say "    → 손으로 한 번 (종료 코드 0 이어야 한다):"
    cmd "bash /volume1/dss/jobs/backup-nightly.sh"
    say "    🔴 그중 **$LEAVE_DB 가 없으면 --go 는 시작조차 하지 않는다.**"
  fi
  say
  say "  야간 완전삭제 — DSM 작업 「DSS Purge」의 로그:"
  nlog=$(ls -1t "$D/setup/logs"/purge-*.log 2>/dev/null | wc -l | tr -d ' ')
  if [ "${nlog:-0}" -gt 0 ]; then
    ok "완전삭제 로그가 ${nlog}개 있다 — 스케줄러에 등록돼 돌고 있다"
    ls -lt "$D/setup/logs"/purge-*.log 2>/dev/null | head -3 | sed 's/^/      /'
  else
    bad "🔴 완전삭제 로그가 **하나도 없다** — 스케줄러에 등록이 안 된 것이다"
    say "    → 🔴 이 스크립트는 등록하지 않는다. 사람이 DSM 화면에서 합니다:"
    say "      [제어판] → [작업 스케줄러] · 이름 「DSS Purge」 · root · 매일 03:00"
  fi

  # ── 1-ㅇ. 디스크 · DB · 지금 도는 것 ────────────────────────────────
  step "1-ㅇ. 디스크 · DB · 지금 도는 것"
  if pg_up && running dss-pg-auth; then
    ok "DB 둘 다 떠 있다 (이 배포에서 DB 컨테이너는 멈추지 않는다)"
  else
    bad "DB 가 떠 있지 않다"
  fi
  for t in dss-auth dss-as dss-meters dss-improvements dss-po dss-leave; do
    running "$t" && ok "$t 가 돌고 있다" || bad "$t 가 안 돌고 있다"
  done
  FREE_KB=$(df -P "$D" | awk 'NR==2{print $4}')
  FREE_H=$(df -Ph "$D" | awk 'NR==2{print $4}')
  # 새 tar 둘(약 74MB + 190MB) + 실은 이미지 둘 + 덤프 하나.
  if [ "${FREE_KB:-0}" -ge 3000000 ]; then
    ok "디스크 여유 $FREE_H"
  else
    bad "디스크 여유가 $FREE_H 뿐이다 (tar 둘 + 실은 이미지 둘 + 덤프가 들어가야 한다)"
  fi

  # ── 1-ㅈ. 알림 링크의 주소 — 휴가 ───────────────────────────────────
  step "1-ㅈ. 알림 링크의 주소 (통로가 아니라 **나오는 주소**를 본다)"
  notify_href_check 휴가 "$LEAVE_CNAME" "$LEAVE_ENV" "$LEAVE_BASE"

  # ── 1-ㅋ. 새 이미지 **안에** 이번 판이 들어 있는가 ──────────────────
  step "1-ㅋ. 새 이미지 안을 본다 — 🔴 앱은 **글자로**, 도구는 **개수로**"
  say "  🔴 9/21~9/29 에 A/S 도구 이미지가 태그는 같은데 속이 빈 채로 돌았다."
  say "     그래서 「실었다」로 끝내지 않고 **안을 센다.**"
  if have_img "$TAG_APP"; then
    say "  $TAG_APP 구운 때: $("$DOCKER" images "$TAG_APP" --format '{{.CreatedAt}}' 2>/dev/null)"
    say "  크기: $("$DOCKER" images "$TAG_APP" --format '{{.Size}}' 2>/dev/null)"
    inside_app_check "$TAG_APP" "휴가" "$OLD_APP"
  else
    notloaded "$TAG_APP 가 아직 안 실려 **안을 못 봤다** (✗ 가 아니다)"
    cmd "bash $0 --preload"
  fi
  say
  say "  🔴 **도구 이미지 안의 마이그레이션 셋** — 여기가 이번 판의 급소다:"
  tools_inside_check "$TAG_TOOLS" || true

  # ── 1-ㅌ. 바깥 주소 여섯 ────────────────────────────────────────────
  step "1-ㅌ. 바깥 주소 여섯 (지금 상태를 적어 둔다)"
  for h in login as meters improvements po leave; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
    case "$code" in
      2??|3??) ok "https://$h.dss21.co.kr → $code" ;;
      *)       bad "https://$h.dss21.co.kr → ${code:-없음} — DNS · DSM 리버스 프록시" ;;
    esac
  done
  say "  🔵 휴가는 로그인으로 넘기므로 **307 이 정상**이다."
}

# ══════════════════════════════════════════════════════════════════════
#  compose 갈아 끼우기
#
#  🔴 --check 는 **갈아 끼우지 않는다.** 읽기만 한다는 약속이 먼저다.
#  🔴 바꾸기 **전에** 새 파일을 먼저 시험한다. 없는 env_file 하나면 docker
#     compose 명령이 **통째로** 실패해서, 앱을 멈춘 뒤에 그걸 알게 되면 다시
#     띄우지도 못한다.
# ══════════════════════════════════════════════════════════════════════
compose_incoming() {
  local e MISS NDIFF
  [ -s "$INCOMING" ] || return 0
  if cmp -s "$INCOMING" "$CF"; then
    say "  · incoming 의 compose 가 지금 것과 같다 — 할 일이 없다"
    return 0
  fi
  step "새 compose 를 먼저 시험한다 (바꾸기 전에)"
  MISS=""
  for e in $(sed '/^[[:space:]]*#/d' "$INCOMING" | grep -oE '\./env/[A-Za-z0-9_.-]+\.env' | sort -u); do
    [ -f "$D/deploy/${e#./}" ] || MISS="$MISS ${e#./}"
  done
  if [ -n "$MISS" ]; then
    bad "새 compose 가 **없는 설정 파일**을 가리킨다:$MISS"
    say "    → 하나만 없어도 docker compose 가 통째로 실패한다."
    return 1
  fi
  if compose_at "$INCOMING" config --quiet >/dev/null 2>&1; then
    ok "새 compose 문법 통과"
  else
    bad "새 compose 에 문법 오류가 있다"
    compose_at "$INCOMING" config --quiet 2>&1 | sed 's/^/    /' | head -10
    return 1
  fi
  say "  🔵 지금 것과 달라진 줄 — 🔴 **image 둘뿐이어야 한다**(app-leave · tools-leave):"
  diff "$CF" "$INCOMING" 2>/dev/null | sed 's/^/      /' | head -40
  NDIFF=$(diff "$CF" "$INCOMING" 2>/dev/null | grep -c '^[<>]')
  say "  · 달라진 줄 수: ${NDIFF:-?}  (기대 4 — 「<」 둘 · 「>」 둘)"
  if [ "${NDIFF:-0}" -gt 4 ] 2>/dev/null; then
    say "    ⚠️ 🔴 **넷보다 많다.** 남의 변경이 섞였을 수 있다 — 위 diff 를 보고,"
    say "       우리 것이 아닌 줄이 있으면 **고치지 말고 먼저 알리세요.**"
  fi
  if [ "$MODE" = go ]; then
    mkdir -p "$BKD"
    cp -p "$CF" "$BKD/docker-compose.nas.yml.$STAMP"
    cp "$INCOMING" "$CF"
    chown root:root "$CF"; chmod 644 "$CF"
    rm -f "$INCOMING"
    ok "compose 새것으로 (옛것: backups/docker-compose.nas.yml.$STAMP)"
    CF_EFF=$CF
  else
    CF_EFF=$INCOMING
    say "  🔵 --check 라서 **갈아 끼우지 않았다.** 아래 검사는 incoming 의 파일을 본 것이다:"
    say "     $INCOMING"
    say "     갈아 끼우는 것은 --go 가 한다."
  fi
  return 0
}

# ══ 되돌리기 ═══════════════════════════════════════════════════════════
if [ "$MODE" = rollback ]; then
  echo "DSS 열아홉째 배포 되돌리기 · $(date '+%F %T')"
  say
  say "  🔴 이 모드는 **아무것도 바꾸지 않는다.** 명령만 찍어 준다."
  say "     되돌리는 것은 **이미지**다:"
  say "       $TAG_APP → $OLD_APP"
  say "       $TAG_TOOLS → $OLD_TOOLS  (🔵 떠 있지 않아 급하지 않다)"
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 **표는 지우지 않습니다.** 이 판은 DB 를 바꿨지만, 되돌리기는  ║"
  say "  ║    이미지만 내리고 **표는 그대로 둡니다.**                      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     까닭 — 🔵 **0.1 은 그 표를 쳐다보지도 않는다.** 소스에 여름휴가라는"
  say "     글자가 하나도 없다. 비어 있는 표가 하나 서 있어도 0.1 은 아무 일도"
  say "     겪지 않는다. 🔴 반대로 표를 지우면 **다시 올릴 때 또 만들어야** 하고,"
  say "     그 사이에 설정 화면에서 저장한 값이 있으면 그것이 사라진다."
  say
  say "  🔴 **덤프를 되붓지 마세요.** --go 가 적용 **직전**에 뜬 덤프는"
  say "     「마이그레이션이 DB 를 깨뜨렸을 때」의 마지막 수단이다. 되부으면"
  say "     그 시각 뒤에 들어온 휴가 신청·결재가 통째로 사라진다."
  say "     자리: /volume1/dss/backups/predeploy-<도장>/$LEAVE_DB.dump"
  say "     최근 것들:"
  ls -1dt "$BKD"/predeploy-* 2>/dev/null | head -3 | sed 's/^/      /'
  say

  step "1. 옛 이미지가 아직 NAS 에 있는지 먼저 본다"
  have_img "$OLD_APP" && ok "$OLD_APP 있다 ($(img_id "$OLD_APP" | cut -c1-19)…)" \
    || bad "$OLD_APP 가 없다 — 되돌릴 이미지가 없다. tar 를 다시 올려야 한다"
  have_img "$OLD_TOOLS" && ok "$OLD_TOOLS 있다 ($(img_id "$OLD_TOOLS" | cut -c1-19)…)" \
    || bad "$OLD_TOOLS 가 없다 — 같은 태그로 덮어쓴 것이 아닌지 보세요"

  step "2. compose 를 사본으로 되돌린다"
  say "  --go 가 옛 compose 를 아래에 남겼다 (가장 최근 것):"
  ls -1t "$BKD"/docker-compose.nas.yml.* 2>/dev/null | head -3 | sed 's/^/      /'
  cmd "cd /volume1/dss/deploy"
  cmd "cp \$(ls -1t ../backups/docker-compose.nas.yml.* | head -1) ."
  say "      (파일 이름이 길면 위 한 줄 대신 두 줄로 나눠 치세요)"
  cmd "grep -n 'image: dss-leave' docker-compose.nas.yml"

  step "3. 다시 띄운다 — 🔴 인자 없는 up -d 를 부르지 않는다"
  say "  (인자 없이 부르면 DB 컨테이너까지 다시 만든다.)"
  cmd "D1=/usr/local/bin/docker"
  cmd "F=docker-compose.nas.yml"
  cmd "\$D1 compose -f \$F --env-file .env.nas up -d --no-deps app-leave"
  script_file_hint "23-rollback"

  step "4. 🔴 사람에게 알릴 것"
  say "  · 🔴 **여름휴가가 화면에서 통째로 사라진다** — 잔액 카드 · 신청 화면 ·"
  say "    달력 범례 · 인쇄물 · 설정 화면 다섯 자리 전부."
  say "  · 🔴 인쇄물이 다시 **「차감 없음」이라는 거짓**을 찍는다(여름휴가 건에)."
  say "  · 🔵 **연차 · 월차 · 결재는 그대로다.** 되돌려도 자료는 하나도 안 없어진다."
  say "  · 🔵 web_leave_settings 표는 **그대로 남는다**(0.1 은 그 표를 안 본다)."

  step "5. 지금 상태"
  say "  dss-leave : $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep '^dss-leave ' || echo '안 돌고 있다')"
  say "  (포털 · A/S · 계측기 · 개선요청 · PO · DB 둘은 이번에 건드리지 않았다.)"
  sql_report
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 여기부터 check · preload · force-load · go ═════════════════════════
echo "DSS 열아홉째 배포 · 2026-10-12 (오늘 **세 번째**) · $(date '+%F %T')"
echo "  🔴 올라가는 것은 **휴가 하나**:  $OLD_APP → $TAG_APP"
echo "  🔴 그리고 **도구 이미지**:  $OLD_TOOLS → $TAG_TOOLS"
echo "     (휴가의 마이그레이션은 도구 **이미지 안**에 있다 — 머리말 ②)"
echo "  🔴 멈추는 것은 **dss-leave 하나뿐**이다."
echo "     그대로 도는 것: 포털 · A/S · 계측기 · 개선요청 · PO · DB 둘."
echo "  🔴 **운영 DB 에 표가 하나 선다** — web_leave_settings ($N_MIG_HAVE → $N_MIG_WANT)."
echo "     🔵 더하기만 한다. 지우는 문장이 없다."
echo "  🔵 담긴 것 — ① 여름휴가(연차와 별개인 셋째 주머니 · 회사 전체 연 3일)"
echo "     ② 달력 범례와 인쇄물. 인쇄물의 **「차감 없음」이라는 거짓**도 고쳤다."
echo "  🔵 야간 백업은 **02:30** — 자정 넘어 돌리면 백업 검사에 걸립니다"
echo "  · 건드리지 않는 여덟 — $KEEP_AUTH · $KEEP_AS · $KEEP_ASTOOLS"
echo "    · $KEEP_METERS · $KEEP_METERSTOOLS · $KEEP_IMP"
echo "    · $KEEP_IMPTOOLS · $KEEP_PO"
if ! pinned; then
  echo "  ⚠️ 🔴 **이미지 기대값 여섯이 비어 있습니다.**"
  echo "     개발 PC 에서 0.2 와 도구 2 를 굽고 재어 채우기 전에는 --go 가"
  echo "     시작하지 않습니다. 재는 차례는 이 파일 머리말 「돌리기 전에」."
fi
case "$MODE" in
  check)      echo "  🔵 --check (기본값) — **읽기만 한다. 아무것도 안 바꾸고 안 멈춘다.**"
              echo "     🔵 DB 에 보내는 문장은 **전부 select** 다 — 끝에 세어서 찍는다."
              echo "     🔵 아직 안 온 것 · 안 실린 것은 ⚠️ 로만 말한다(✗ 가 아니다)." ;;
  preload)    echo "  🔵 --preload — 새 이미지 둘을 싣고 안을 센다. **아무것도 안 멈춘다.**" ;;
  force-load) echo "  🔴 --force-load — 같은 태그가 있어도 **다시 싣는다.** 안 멈춘다." ;;
  go)         echo "  🔴 --go — **DB 를 먼저 바꾸고** 휴가를 교체한다."
              [ "$FORCE_LOAD" = 1 ] && echo "  🔴 --force-load 도 켜져 있다 — 이미지를 덮어쓴다." ;;
esac

# ══ --preload · --force-load — 이미지만 본다 ═══════════════════════════
#
# 🔴 이미지 절만 본다. 이미지를 실어 두려는 시점에는 뒤 항목(백업 · DB 상태)이
#    아직 안 맞는 것이 정상인데, 거기서 멈추면 「미리 실어 두기」 자체를 못 한다.
if [ "$MODE" = preload ] || [ "$MODE" = force-load ]; then
  step "새 이미지 tar 둘 · 지문"
  EXP_APP=$(tar_config_id "$TAR_APP" 2>/dev/null) || EXP_APP=""
  EXP_TOOLS=$(tar_config_id "$TAR_TOOLS" 2>/dev/null) || EXP_TOOLS=""
  see_tar "$TAG_APP" "$TAR_APP" "$EXP_APP" \
          "$SZ_APP" "$MD5_APP" "$WANT_CFG_APP" dss-leave-0.2.tar
  see_tar "$TAG_TOOLS" "$TAR_TOOLS" "$EXP_TOOLS" \
          "$SZ_TOOLS" "$MD5_TOOLS" "$WANT_CFG_TOOLS" dss-leave-tools-2.tar
  if [ -s "$TAR_APP" ] && [ -n "$EXP_APP" ]; then
    bring_img "$TAG_APP" "$TAR_APP" "$EXP_APP"
  else
    bad "$TAG_APP 를 싣지 않았다 — tar 가 없거나 manifest.json 을 못 읽었다"
  fi
  if [ -s "$TAR_TOOLS" ] && [ -n "$EXP_TOOLS" ]; then
    bring_img "$TAG_TOOLS" "$TAR_TOOLS" "$EXP_TOOLS"
  else
    bad "$TAG_TOOLS 를 싣지 않았다 — tar 가 없거나 manifest.json 을 못 읽었다"
  fi

  # 🔴 실어 놓고 **안을 본다.** 앱은 글자로, 도구는 개수로.
  step "새 이미지 안에 이번 판이 들어 있는가"
  if have_img "$TAG_APP"; then
    inside_app_check "$TAG_APP" "휴가" "$OLD_APP"
  fi
  say
  say "  🔴 도구 이미지 안의 마이그레이션 셋:"
  tools_inside_check "$TAG_TOOLS" || true
  if read_mig_sql "$TAG_TOOLS"; then
    say
    say "  🔴 **「지우는 문장」 검사** (적용 전에 미리 본다):"
    destructive_check || true
  fi

  sql_report
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 멈추지 않았다 · DB 도 안 바꿨다**"
  if [ "$FAIL" != 0 ] && [ "$FORCE_LOAD" != 1 ]; then
    echo "  🔴 지문이 어긋난 것이 있으면 **같은 태그로 다시 구운 것**이다:"
    echo "       bash $0 --force-load"
  fi
  echo "  🔵 나머지 항목은 안 봤다. 이어서: bash $0        (읽기만)"
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi

# ══ 1. 먼저 볼 것 ══════════════════════════════════════════════════════
#
# 🔴 규칙 하나: **앱을 멈추기 전에 · DB 를 바꾸기 전에 볼 것을 다 보고,
#    어긋나면 앱이 살아 있는 채로 멈춘다.** 여기서 끝나면 직원은 아무것도
#    느끼지 못한다.
step "1. 점검표를 기계로 옮긴 것 (앱은 살아 있다 · DB 는 아직 손도 안 댔다)"
compose_incoming || stop "compose 를 바꾸지 않았습니다. 앱은 그대로 돕니다."
run_checks

if [ "$MODE" = check ]; then
  sql_report
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  통과 $PASS · 실패 $FAIL · **아무것도 바꾸지 않았습니다**"
  echo "  🔵 DB 에 보낸 문장 $SQL_N 개 · select $SQL_SELECT_N 개 · 그 밖 0개"
  if [ "$FAIL" = 0 ]; then
    if pinned; then
      echo "  ✅ 이어서 (DB 에 표가 서고, dss-leave 가 잠깐 멈춥니다):"
      echo "       bash $0 --go"
      echo "     🔴 --go 는 오늘 백업($LEAVE_DB)이 없으면 **시작하자마자 멈춥니다.**"
      echo "     🔵 야간 백업은 02:30 입니다 — 먼저 손으로 뜨려면:"
      echo "          bash /volume1/dss/jobs/backup-nightly.sh"
    else
      echo "  🔴 아직 --go 를 부를 수 없습니다 — 이미지 기대값 여섯이 비어 있습니다."
      echo "     개발 PC 에서 굽고 재어 이 파일에 채운 뒤 다시 올리세요."
    fi
    echo "     🔵 ⚠️ 가 있었다면 아직 안 온 파일이 있다는 뜻입니다 — 올리고"
    echo "        --preload 한 뒤 이 명령을 한 번 더 돌리세요."
  else
    echo "  ✗ 위 ✗ 를 먼저 해결하세요. Claude 에게 알려 주세요."
    echo "    🔵 「아직 안 온 것 · 안 실린 것」은 ✗ 가 아닙니다 — ⚠️ 로 찍혔습니다."
  fi
  echo "  로그: $LOG"
  echo "════════════════════════════════════════════════════════════"
  exit "$FAIL"
fi
# ══ --go ═══════════════════════════════════════════════════════════════
[ "$FAIL" = 0 ] || stop "위 ✗ 를 먼저 해결해야 합니다. **아직 아무것도 바꾸지 않았고 앱은 살아 있습니다.**"
pinned || {
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 이미지 기대값 여섯이 **비어 있습니다.** 재지 않은 이미지를    ║"
  say "  ║    운영에 올리지 않습니다.                                     ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  stop "아무것도 바꾸지 않았습니다. 앱도 DB 도 그대로입니다."
}

# ── 2. 이미지를 싣고 지문을 맞춘다 (아직 아무것도 안 멈췄다) ───────────
step "2. 새 이미지 둘 싣기 · 지문 대조 (tar 의 Config ↔ NAS 의 .Id)"
[ -n "$EXP_APP" ]   || stop "휴가 tar 에서 지문을 못 읽었습니다. **아무것도 바꾸지 않았습니다.**"
[ -n "$EXP_TOOLS" ] || stop "도구 tar 에서 지문을 못 읽었습니다. **아무것도 바꾸지 않았습니다.**"
bring_img "$TAG_APP" "$TAR_APP" "$EXP_APP" || {
  say "  🔴 휴가 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
}
bring_img "$TAG_TOOLS" "$TAR_TOOLS" "$EXP_TOOLS" || {
  say "  🔴 도구 이미지가 기대한 것과 다릅니다. **아직 아무것도 멈추지 않았습니다.**"
  stop "교체를 시작하지 않았습니다."
}

# 🔴 실어 놓고 **도구 이미지 안을 다시 센다.** 여기가 이번 판의 급소다 —
#    0002 가 안 담긴 도구 이미지로 적용하면 **조용히 0건**으로 끝난다.
step "2-ㄷ. 🔴 도구 이미지 안에 0002 가 실제로 들어 있는가"
tools_inside_check "$TAG_TOOLS" \
  || stop "도구 이미지 안이 기대와 다릅니다. **DB 도 앱도 그대로입니다.**"
step "2-ㄹ. 휴가 이미지 안에 여름휴가가 들어 있는가"
inside_app_check "$TAG_APP" "휴가" "$OLD_APP"
[ "$FAIL" = 0 ] || stop "이미지 안이 기대와 다릅니다. **DB 도 앱도 그대로입니다.**"

# ══ 3. 🔴 DB 를 바꾸기 전에 — 백업 · 덤프 · 시작 시각 ══════════════════
#
# 🔴 여기까지가 「돌이킬 수 있는 자리」다. 앱은 아직 $OLD_APP 로 **살아 있다.**

# ── 3-ㄱ. 🔴 오늘 백업을 **지금 다시** 찾는다. 없으면 멈춘다 ───────────
#
# 🔴 --check 에서 봤다는 것으로는 부족하다 — 그 뒤에 지워졌을 수 있고, 무엇보다
#    --check 를 안 돌리고 바로 여기로 올 수 있다. 🔴 스크립트가 **대신 뜨지 않는다.**
step "3-ㄱ. 🔴 오늘 백업($LEAVE_DB)을 **지금 다시** 찾는다 (없으면 멈춘다)"
BK_TODAY=$(ls -1t "$BKD/db/${LEAVE_DB}_${TODAY}_"*.dump 2>/dev/null | head -1)
if [ -n "$BK_TODAY" ] && [ -s "$BK_TODAY" ]; then
  ok "오늘 백업 — $(basename "$BK_TODAY") ($(du -h "$BK_TODAY" | cut -f1))"
else
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 오늘($TODAY) 뜬 $LEAVE_DB 백업을 **지금 찾지 못했습니다.**   ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     이 판은 **운영 DB 에 표를 세웁니다.** 더하기만 하지만, 백업 없이"
  say "     DB 를 바꾸지 않습니다. 🔵 야간 백업은 **02:30** 입니다 — 자정을"
  say "     넘겨 돌리면 여기 걸립니다. 먼저 이것부터 (종료 코드 0):"
  cmd "bash /volume1/dss/jobs/backup-nightly.sh"
  say "     ✓ $LEAVE_DB 줄이 찍혀야 합니다. 그 뒤에 다시:"
  cmd "bash $0 --go"
  stop "백업 없이 DB 를 바꾸지 않습니다. **DB 도 앱도 그대로입니다.**"
fi

# ── 3-ㄴ. 🔴 적용 **직전** 덤프 — 야간 백업과 **별도**다 ───────────────
#
# 🔴 되돌리기의 **기본 수단이 아니다.** 되돌리기는 이미지만 0.1 로 내리고
#    표는 그대로 두는 것이다(--rollback 참조). 이 덤프는 「마이그레이션이 DB 를
#    깨뜨렸을 때」의 마지막 수단이다.
step "3-ㄴ. 🔴 적용 직전 덤프 ($LEAVE_DB) — 어디에 두는지 아래에 찍힙니다"
BK=$BKD/predeploy-$STAMP
mkdir -p "$BK"; chown root:root "$BK"; chmod 700 "$BK"
if "$DOCKER" exec dss-pg-app sh -c "pg_dump -U \"\$POSTGRES_USER\" -d $LEAVE_DB -Fc" \
     > "$BK/$LEAVE_DB.dump.part" 2>/dev/null \
   && "$DOCKER" exec -i dss-pg-app pg_restore -l < "$BK/$LEAVE_DB.dump.part" >/dev/null 2>&1; then
  mv "$BK/$LEAVE_DB.dump.part" "$BK/$LEAVE_DB.dump"
  ok "$LEAVE_DB 덤프 $(du -h "$BK/$LEAVE_DB.dump" | cut -f1)"
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔴 **되돌릴 때 쓸 덤프는 여기 있습니다:**                      ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     $BK/$LEAVE_DB.dump"
  say "     (pg_restore -l 로 **열어 보기까지 했습니다** — 껍데기가 아닙니다.)"
else
  rm -f "$BK/$LEAVE_DB.dump.part"
  bad "$LEAVE_DB 덤프 실패"
  say "    🔴 3-ㄱ 의 야간 백업은 있습니다. 그래도 **적용 직전 덤프 없이는**"
  say "       가지 않습니다 — 야간 백업은 02:30 것이라 그 뒤의 일이 빠집니다."
  stop "DB 를 바꾸지 않았습니다. **앱도 그대로입니다.**"
fi
if [ -f "$LEAVE_ENV" ]; then
  cp -p "$LEAVE_ENV" "$BKD/leave.env.$STAMP"; chmod 600 "$BKD/leave.env.$STAMP"
  ok "leave.env 사본 — backups/leave.env.$STAMP (root 600 · 🔵 **고치지는 않는다**)"
else
  bad "leave.env 가 없다: $LEAVE_ENV"
  stop "설정 파일이 없습니다. **DB 도 앱도 그대로입니다.**"
fi
say "  🔵 휴가 앱에는 **첨부 폴더가 없다** — 뜰 스냅숏이 없다(13번 확인)."

# ── 3-ㄷ. 건드리지 않는 쪽의 **시작 시각**을 적어 둔다 ─────────────────
step "3-ㄷ. 건드리지 않는 쪽의 시작 시각을 적어 둔다 (뒤에서 대조한다)"
KEEP_BOXES="dss-auth dss-as dss-meters dss-improvements dss-po dss-pg-app dss-pg-auth"
STARTED_BEFORE=""
for t in $KEEP_BOXES; do
  s=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  STARTED_BEFORE="$STARTED_BEFORE$t=$s
"
  say "  · $t  시작 ${s:-?}"
done

# ══ 4. 적용 전 마지막 문 — 글자 · 판정 ═════════════════════════════════
step "4. 🔴 적용 전 마지막 문 (🔴 앱은 아직 $OLD_APP 로 살아 있다)"
say "  🔴 여기를 지나야 db:migrate 가 돈다. 넷을 본다:"
say "     ㄱ) 0002 의 글자를 도구 이미지에서 꺼내 읽는다"
say "     ㄴ) 🔴 지우는 문장이 있으면 **멈춘다**"
say "     ㄷ) 🔴 바인딩 자리(\$1)가 섞였으면 **멈춘다**"
say "     ㄹ) 🔴 이미 적용돼 있으면 **건너뛴다**(두 번 돌려도 안전)"
say
read_mig_sql "$TAG_TOOLS" \
  || stop "도구 이미지에서 0002 의 글자를 못 읽었습니다. **DB 도 앱도 그대로입니다.**"
destructive_check \
  || stop "🔴 마이그레이션이 기대한 모습이 아닙니다. **DB 도 앱도 그대로입니다.**"
say
mig_verdict || stop "DB 가 기대한 상태가 아닙니다. **DB 도 앱도 그대로입니다.**"

if [ "$MIG_VERDICT" = done ]; then
  say
  say "  ╔══════════════════════════════════════════════════════════════╗"
  say "  ║ 🔵 **이미 적용돼 있습니다 — 이번에는 DB 를 건드리지 않습니다.**  ║"
  say "  ╚══════════════════════════════════════════════════════════════╝"
  say "     줄 $N_MIG_DB · 표 $HAVE_TBL 이라 적용이 끝난 DB 입니다."
  say "     🔵 db:migrate 를 부르지 않습니다. 바로 앱 교체로 갑니다."
  say "     (두 번 돌려도 안전하다는 약속이 이 갈래입니다.)"
else
  say
  say "  🔴 이제 **DB 를 바꿉니다.** 그만두려면 **20초 안에 Ctrl+C**."
  say "     지금 Ctrl+C 하면 DB 도 앱도 손대지 않은 채로 남습니다."
  say "     (compose 는 이미 바뀌었지만 그것만으로는 아무 일도 일어나지 않습니다 —"
  say "      $OLD_APP 가 그대로 돌고 있습니다.)"
  sleep 20

  # ══ 5. 🔴 마이그레이션 적용 — 앱은 아직 0.1 로 살아 있다 ═════════════
  step "5. 마이그레이션 적용 ($NEW_MIG)  🔴 여기서 DB 가 바뀐다"
  say "  표 하나($NEW_TBL)를 **더하기만** 한다."
  say "  🔴 다시 돌려도 안전하다 — drizzle 은 이미 적용된 것을 건너뛴다."
  say "  🔵 도는 동안 직원은 **$OLD_APP 를 그대로 쓰고 있다.** 아직 안 멈췄다."
  say "  🔵 도구는 profiles: [tools] 라 **떴다 사라진다**(run --rm)."
  N_BEFORE=$(ql "select count(*) from drizzle.__drizzle_migrations")
  say "  · 적용 전 DB 의 마이그레이션 줄: ${N_BEFORE:-?}  (기대 $N_MIG_HAVE)"
  "${COMPOSE[@]}" run --rm "$LEAVE_TOOLS_SVC" npm run db:migrate 2>&1 | sed 's/^/    /'
  rc=${PIPESTATUS[0]}
  if [ "$rc" = 0 ]; then
    ok "db:migrate 끝 (종료 코드 0)"
  else
    bad "db:migrate 실패 (종료 코드 $rc)"
    say "    ╔══════════════════════════════════════════════════════════════╗"
    say "    ║ 🔵 **직원은 아직 $OLD_APP 를 그대로 쓰고 있습니다.** 안 멈췄습니다.║"
    say "    ╚══════════════════════════════════════════════════════════════╝"
    say "    🔴 **새 이미지를 띄우지 않습니다.** $TAG_APP 는 없는 표를 읽습니다."
    say "    🔴 compose 는 이미 $TAG_APP 를 가리키고 있으니, 누가 up -d 를 부르면"
    say "       $TAG_APP 가 올라옵니다 — 부르지 마세요."
    say "    🔴 「.env.local 파일을 확인하세요」가 보이면 그 파일이 아니라"
    say "       compose 의 $LEAVE_TOOLS_SVC 에 DATABASE_URL 이 없는 것입니다."
    say "    → 고친 뒤 **다시 돌리면 됩니다**(이미 적용된 것은 건너뜁니다):"
    cmd "bash $0 --go"
    say "    → 오늘은 그만두려면 compose 를 $OLD_APP 로 되돌려 두세요:"
    cmd "bash $0 --rollback"
    stop "마이그레이션이 중간에 멈췄습니다. 적용 직전 덤프: $BK/$LEAVE_DB.dump"
  fi
  N_AFTER=$(ql "select count(*) from drizzle.__drizzle_migrations")
  [ "${N_AFTER:-0}" = "$N_MIG_WANT" ] \
    && ok "DB 의 마이그레이션 줄 ${N_AFTER} (전 ${N_BEFORE:-?})" \
    || bad "마이그레이션 줄이 ${N_MIG_WANT}이 아니다 (${N_AFTER:-?})"
  if [ "${N_AFTER:-0}" = "${N_BEFORE:-0}" ]; then
    bad "🔴 **0건 적용으로 끝났다** — 도구 이미지의 _journal 이 0002 를 모른다"
    say "    → 머리말 ② 를 보세요. 도구 이미지를 다시 구워야 합니다."
  fi
fi

# ══ 6. 🔴 적용 뒤 — SQL 로 직접 센다 (「했다」가 아니라 「들어 있다」) ══
step "6. 🔴 표가 **실제로** 섰는가 — SQL 로 다시 본다 (전부 select)"
say "  🔵 「만든 것과 도는 것은 다르다」. 표 · 칸 · CHECK 둘 · 주인 · 권한을"
say "     하나씩 되묻는다. 🔴 CHECK 는 **적힌 글자까지** 받아 본다."
table_verify "적용 뒤" \
  || stop "DB 가 기대한 상태가 아닙니다. 직원은 **아직 $OLD_APP 를 쓰고 있습니다.** 적용 직전 덤프: $BK/$LEAVE_DB.dump"
[ "$FAIL" = 0 ] || stop "위 ✗ 를 보세요. 직원은 **아직 $OLD_APP 를 쓰고 있습니다.** 적용 직전 덤프: $BK/$LEAVE_DB.dump"

# ══ 7. 휴가를 새 판으로 바꿔 끼운다 — 🔴 여기 하나가 정지 창이다 ═══════
#
# 🔴 인자 없이 up -d 를 부르지 않는다 — DB 컨테이너가 다시 만들어지고,
#    compose 에 있는 것을 전부 띄우려 든다. --no-deps 로 **이름을 적은 하나만**.
step "7. 새 이미지로 바꿔 끼운다 ($OLD_APP → $TAG_APP)  ⏱ 여기부터 정지 창"
say "  🔴 **멈추는 것은 dss-leave 하나뿐이다.**"
say "     그대로 도는 것: 포털 · A/S · 계측기 · 개선요청 · PO · DB 둘."
say "     즉 https://leave.dss21.co.kr 만 몇십 초 대답하지 않는다."
say "  🔵 **DB 는 이미 끝나 있다** — 정지 창 안에서 하는 일은 up -d 하나뿐이다."
T0=$SECONDS
STOP_AT=$(date '+%F %T')
say "  멈춘 시각: $STOP_AT"
"${COMPOSE[@]}" up -d --no-deps "$LEAVE_SVC" 2>&1 | sed 's/^/    /'
wait_http "휴가" "$LEAVE_PORT" / "$LEAVE_CNAME"
UP_AT=$(date '+%F %T')
DOWN=$((SECONDS - T0))
say
say "  ⏱ 멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · **약 ${DOWN}초**"

# ══ 8. 스모크 ══════════════════════════════════════════════════════════
step "8. 스모크 — 컨테이너 · 🔴 **여름휴가** · 표 · 알림 · 안 멈췄는가 · 주소"

say "  8-ㄱ. 컨테이너가 떠 있는가"
if running "$LEAVE_CNAME"; then
  ok "$LEAVE_CNAME 이 돌고 있다"
  say "      $("$DOCKER" ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep "^$LEAVE_CNAME " || true)"
else
  bad "$LEAVE_CNAME 이 안 돌고 있다 — 떴다가 죽었다"
  cmd "$DOCKER logs --tail 50 $LEAVE_CNAME"
fi

# 8-ㄴ. 🔴 **도는 컨테이너 안에** 여름휴가가 들어 있는가
say "  8-ㄴ. 🔴 **도는 컨테이너 안에** 여름휴가가 들어 있는가"
say "     (「만든 것과 도는 것은 다르다」. 위 2-ㄹ 은 이미지를 봤고 여기는 **도는 것**이다.)"
if running "$LEAVE_CNAME"; then
  SMOKE=$("$DOCKER" exec \
          -e A="$NEW_M1" -e B="$NEW_M2" -e C2="$NEW_M3" -e O="$OLD_M" -e C="$CTRL" \
          "$LEAVE_CNAME" sh -c '
    r=""
    for w in "$A" "$B" "$C2" "$O" "$C"; do
      if grep -rlF -- "$w" /app/.next >/dev/null 2>&1; then r="$r 1"; else r="$r 0"; fi
    done
    echo "RUN$r"' 2>/dev/null | grep '^RUN ' | head -1)
  R1=$(printf '%s' "$SMOKE" | awk '{print $2}')
  R2=$(printf '%s' "$SMOKE" | awk '{print $3}')
  R3=$(printf '%s' "$SMOKE" | awk '{print $4}')
  RO=$(printf '%s' "$SMOKE" | awk '{print $5}')
  RC=$(printf '%s' "$SMOKE" | awk '{print $6}')
  if [ "${RC:-0}" != 1 ]; then
    say "    ⚠️ 도는 컨테이너 안을 글자로 뒤지지 못했다 — **판정하지 않는다.**"
    say "       🔴 이때는 사람이 화면에서 봐야 한다(아래 눈으로 볼 것)."
  else
    ok "도는 컨테이너 안을 실제로 읽었다 (대조 표시를 찾았다)"
    [ "${RO:-0}" = 0 ] && ok "🔴 옛 글자가 **사라졌다** — $OLD_APP 가 아니다" \
      || bad "🔴 옛 글자가 아직 있다 — **$OLD_APP 가 돌고 있다.** 교체가 안 된 것이다"
    [ "${R1:-0}" = 1 ] && ok "🔴 도는 컨테이너에 **여름휴가**가 들어 있다" \
      || bad "🔴 도는 컨테이너에 여름휴가가 **없다**"
    [ "${R2:-0}" = 1 ] && ok "인쇄물의 「$NEW_M2」이 들어 있다" \
      || say "    ⚠️ 「$NEW_M2」을 못 찾았다 — 판정하지 않는다"
    [ "${R3:-0}" = 1 ] && ok "「$NEW_M3」가 들어 있다" \
      || say "    ⚠️ 「$NEW_M3」를 못 찾았다 — 판정하지 않는다"
  fi
else
  bad "$LEAVE_CNAME 이 안 돌고 있어 안을 못 봤다"
fi

# 8-ㄷ. 🔴 표를 한 번 더 — 앱이 뜬 **뒤**에 본다
say "  8-ㄷ. 🔴 표를 교체 **뒤**에 한 번 더 센다"
table_verify "교체 뒤" || true

# 8-ㄹ. 알림 통로 · 알림 링크
say "  8-ㄹ. 알림 통로 · 알림 링크의 주소"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 \
       "http://127.0.0.1:$LEAVE_PORT/api/integration/notifications" 2>/dev/null)
case "$code" in
  404) bad "휴가의 /api/integration/notifications 가 404 다 — **옛 이미지다**" ;;
  000|"") bad "휴가의 알림 통로가 대답하지 않는다 (${code:-없음})" ;;
  *)   ok "휴가의 알림 통로가 있다 (토큰 없이 부르면 401 이 맞다 — 지금 $code)" ;;
esac
notify_href_check 휴가 "$LEAVE_CNAME" "$LEAVE_ENV" "$LEAVE_BASE"

# 8-ㅁ. 권한 — 교체 뒤에 다시 읽는다
say "  8-ㅁ. 여름휴가를 바꿀 수 있는 사람 (🔴 select 만 · 이름은 안 찍는다)"
perm_check

# 8-ㅂ. 🔴 건드리지 않는 쪽이 **정말 안 멈췄는가**
say "  8-ㅂ. 🔴 건드리지 않는 쪽이 안 멈췄는가 (시작 시각을 대조한다)"
for t in $KEEP_BOXES; do
  before=$(printf '%s\n' "$STARTED_BEFORE" | sed -n "s/^$t=//p" | head -1)
  after=$("$DOCKER" inspect -f '{{.State.StartedAt}}' "$t" 2>/dev/null)
  if [ -n "$before" ] && [ "$before" = "$after" ]; then
    ok "$t · 시작 시각 그대로 — **한 번도 안 멈췄다**"
  else
    bad "🔴 $t 의 시작 시각이 바뀌었다 ($before → $after) — 이 배포가 건드렸다"
  fi
done

say "  8-ㅅ. 바깥 주소 여섯"
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$LEAVE_BASE/" 2>/dev/null)
case "$code" in
  307)     ok "$LEAVE_BASE → $code (로그인으로 넘긴다 — 기대한 값이다)" ;;
  2??|3??) ok "$LEAVE_BASE → $code (바뀐 쪽)" ;;
  502)     bad "$LEAVE_BASE → 502 — 앱은 떴는데 프록시가 못 닿는다"
           say "      DSM 프록시의 대상이 localhost:$LEAVE_PORT 인지 보세요." ;;
  *)       bad "$LEAVE_BASE → ${code:-없음} — DNS · DSM 리버스 프록시 · 인증서" ;;
esac
say "    🔵 307 은 「로그인으로 넘긴다」는 뜻일 뿐이다 — **표가 섰는지는 말해 주지"
say "       않는다.** 표는 위 8-ㄷ 이 SQL 로 보았다."
say "  🔴 안 바뀌는 쪽 다섯 — 흔들렸으면 **이 배포가 건드린 것**이다:"
for h in login as meters improvements po; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$h.dss21.co.kr/" 2>/dev/null)
  case "$code" in
    2??|3??) ok "https://$h.dss21.co.kr → $code (건드리지 않은 쪽 · 그대로다)" ;;
    *)       bad "🔴 https://$h.dss21.co.kr → ${code:-없음} — 건드리지 않기로 한 쪽이 흔들렸다" ;;
  esac
done
say "  열린 포트 (127.0.0.1 만이어야 한다):"
netstat -tln 2>/dev/null | grep ':13[0-9]\{3\}' | sed 's/^/      /'
say "  지금 도는 이미지:"
"$DOCKER" ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | sed 's/^/      /'

# ══ 9. 마무리 ══════════════════════════════════════════════════════════
sql_report
echo
echo "════════════════════════════════════════════════════════════"
echo "  통과 $PASS · 실패 $FAIL"
echo "  멈춘 시각 $STOP_AT → 다 대답한 시각 $UP_AT · 약 ${DOWN}초"
echo "  🔴 바꾼 것 — 이미지 둘 · **운영 DB 에 표 하나**($NEW_TBL)"
echo "  🔵 .env 0줄 · 볼륨 0 · 양식 0벌 · 지운 것 0"
echo "  🔴 적용 직전 덤프: $BK/$LEAVE_DB.dump"
echo "  .env 사본: $BKD/leave.env.$STAMP (고치지는 않았습니다)"
echo "  로그: $LOG"
echo "════════════════════════════════════════════════════════════"
if [ "$FAIL" != 0 ]; then
  echo
  echo "✗ 가 있습니다. Claude 에게 로그를 알려 주세요."
  echo "되돌리기 안내:  bash $0 --rollback"
  exit "$FAIL"
fi
cat <<ANNOUNCE

╔════════════════════════════════════════════════════════════════════╗
║ 🔵 **도우미도 설정도 다시 할 것이 없습니다.** 휴가 하나만 올라갔습니다  ║
╚════════════════════════════════════════════════════════════════════╝

🔴 **눈으로 보아 주세요** — 스크립트가 못 보는 자리입니다.
   스크립트는 ① 표가 섰는지를 SQL 로 ② 여름휴가라는 글자가 **도는
   컨테이너 안에** 있는지를 보았습니다. 🔴 **화면에 그려지는지는 사람만**
   볼 수 있습니다(로그인한 사람의 화면이라 스크립트가 못 엽니다).

   https://leave.dss21.co.kr — 사내망에서, 이 순서로:

   1. 🔴 **첫 화면의 잔액 카드** — 연차 **바로 아래**에 「여름휴가」 줄이
      보입니까. 「받은 3일 · 남음 3일」 꼴이면 맞습니다.
      🔵 아직 설정을 저장한 적이 없어도 **3일**로 보이는 것이 정상입니다
         (줄이 없으면 앱이 기본값으로 읽습니다).
      · 그 아래에 「연차와 따로 셉니다 (연차를 깎지 않습니다)」가 있습니까.

   2. 🔴 **휴가 신청 화면** — 종류 고르는 곳에 **여름휴가**가 있습니까.
      🔵 하루 단위만 됩니다(반차 칸이 안 열리는 것이 맞습니다).

   3. 🔴 **달력의 범례** — 여름휴가 표가 하나 늘었습니까(호박색).

   4. 🔴 **인쇄물**([내 휴가] → 인쇄) — 표에 여름휴가 줄이 **항상** 보이고,
      여름휴가 건에 「**여름휴가에서 뺌**」이라고 적힙니까.
      🔴 전에는 거기에 「**차감 없음**」이라는 **거짓**이 찍혔습니다.

   5. 🔴 **설정 화면**(휴가 관리자만) — [관리] → [설정] 에 「여름휴가」 구역이
      있고, 「직원 1명당 연 [3] 일」을 바꿔 저장할 수 있습니까.
      🔵 저장하면 그때 표에 줄이 하나 생깁니다 — 그것이 정상입니다.

   6. 🔵 **연차 · 월차 · 결재가 그대로입니까.** 여름휴가는 **별개 주머니**라
      연차를 깎지 않습니다. 여름휴가를 하루 써도 연차 남은 날이 그대로여야
      맞습니다.

   7. 🔵 **포털 · A/S · 계측기 · 개선요청 · PO 가 그대로입니까** — 이번 판은
      그 다섯을 건드리지 않았습니다(스크립트가 8-ㅂ 에서 시작 시각으로 이미
      확인했습니다).

🔴 사람이 이어서 할 일:
  · https://login.dss21.co.kr/release-notes 를 한 번 봅니다.
  · 내일 아침 백업을 한 번 더 보세요 — 다섯이 다 있어야 합니다:
      ls -lt /volume1/dss/backups/db/ | head -7
  · 🔴 **적용 직전 덤프**는 $BK 에 있습니다. 한 주쯤 두었다 지우세요.
  · 🔵 옛 이미지 $OLD_APP · $OLD_TOOLS 는 **그대로 두세요** — 되돌리기가
    그것을 씁니다.

되돌리기 안내:  bash $0 --rollback
  🔵 되돌릴 것은 **이미지**뿐입니다 — 🔴 **표는 지우지 않습니다**(0.1 은 그
     표를 쳐다보지도 않습니다).
  🔴 되돌리면 **여름휴가가 화면에서 통째로 사라지고**, 인쇄물이 다시
     「차감 없음」이라는 거짓을 찍습니다. 🔵 자료는 그대로입니다.
ANNOUNCE
exit "$FAIL"
