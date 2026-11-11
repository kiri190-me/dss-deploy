#!/bin/bash
# dss-deploy/nas/setup/56-templates.sh — 운영 양식 **두 장**만 갈아 끼운다 (2026-11-11)
#
# 🔵 **배포 번호가 아니다.** 56 은 setup/ 폴더의 파일 번호일 뿐이고, 이 일은
#    배포가 아니라 **양식 파일만** 갈아 끼우는 일이다. 이미지도 마이그레이션도
#    compose 도 없다. 그래서 개발 PC 쪽 보낼 자리도 배포본 폴더(_images-NN)가
#    **아니다** — **_templates-56** 이다(아래 DEVPC_TPLDIR).
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 **만들어는 두었지만 2026-11-11 에 돌리지 않았다** — 그것이 결정이다
# ══════════════════════════════════════════════════════════════════════
#   이 스크립트는 2026-11-11 에 만들었고 **그날 돌리지 않았다**(사용자 결정).
#   짜임이 틀려서가 아니라 **올릴 까닭이 없어서**다. 까닭을 실측으로 확인했다:
#
#   · 올리려던 둘(수리보고서.xlsx · 검사보고서.xlsx — 매쳐·제너레이터가 **안 붙은**
#     기본 둘)은 A/S 의 src/lib/storage/service-report-template.ts 에 있는
#     **LEGACY_TEMPLATE_ENV**, 곧 **물러설 자리(fallback)** 다.
#   · 보고서 양식은 문서 종류(검사·수리) × 제품 종류(매쳐·제너레이터) **넷** 중에서
#     고른다(T/C 는 제너레이터 양식을 쓴다). 그 파일 100~107줄에 「새 설정이 비어
#     있으면 옛 설정을 쓴다」고 적혀 있고, **기본 둘은 그때만** 읽힌다.
#   · 🔵 **운영 실측** — 쉰두째 배포 기록(dss-deploy/README.md 444줄)이
#     **OK 11 / MISS 0 / UNSET 0** 이다. 설정 열한 개가 **전부 채워져 있고 전부
#     읽힌다** → 운영에서 기본 둘은 **한 번도 안 읽힌다.**
#   · 그래서 운영이 9월 판이어도 **지금 나가는 보고서에는 아무 영향이 없다.**
#   🔵 이 파일의 --check 가 끝에 찍는 「읽힘 11 · 없음 0 · 설정 없음 0」이 바로
#      그 수다. **지금도 그런지는 돌려 보면 그 자리에서 다시 드러난다.**
#
#   🔴 **양식이 또 바뀌는 날 쓰려고 남긴다.**
#   🔴 **돌리기 전에 반드시 다시 재라.** 아래 TPL_UP 표의 바이트·md5 는
#      **2026-11-11 개발 PC 실측**이다. 그 사이 양식이 또 바뀌었으면 **그 값부터
#      고쳐야** 한다 — 개발 PC 에서 56-stage.sh 를 인자 없이 먼저 돌리면 **✗ 로
#      알려 준다.** 안 고치고 보내면 --apply 가 md5 가 다르다며 **한 장도 안 옮긴다.**
#
# 🔴 NAS 에서 돈다. **DSM 터미널은 긴 명령을 잘라 먹는다**(2026-10-12 하루에 네
#    번 깨졌다). 그래서 손으로 치지 않고 **파일로 올려** 돌린다. 절차는 이렇다:
#      ① (개발 PC · PowerShell) — 🔴 **경로는 빗금으로**
#           cd "C:/Users/희만/Desktop/Development/dss-deploy/nas/setup"
#           scp -O 56-templates.sh dss-nas:/volume1/dss/setup/
#           Get-FileHash -Algorithm MD5 56-templates.sh
#      ② (NAS) md5sum /volume1/dss/setup/56-templates.sh
#      ③ 🔴 **두 md5 가 같은지 눈으로 맞댄다.** 다르면 옮기다 잘린 것이다 —
#         그대로 돌리면 중간에서 끊긴 스크립트가 양식을 옮기다 만다.
#      🔵 이 파일은 돌 때 맨 위에서 **제 md5 를 스스로 찍는다.**
#    🔴 **scp 에는 -O 를 붙인다.** DSM 에 sftp 서버가 없어 -O 없이는 실패한다.
#    🔴 **역슬래시 경로를 쓰지 마라.** bash 와 scp 가 그 역슬래시를 먹어
#       "C:Users희만Desktop…" 가 된다.
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 이 파일이 하는 일 — **양식 두 장.** 그것뿐이다
# ══════════════════════════════════════════════════════════════════════
#   운영(NAS)에 놓인 엑셀 양식 둘이 개발 PC 것보다 **두 달 뒤처져 있다**:
#       수리보고서.xlsx   운영 182,773바이트 (2026-09-01)  ← 개발 PC 190,710 (10-19)
#       검사보고서.xlsx   운영 182,626바이트 (9월 판)       ← 개발 PC 190,589 (10-19)
#
#   2026-10-19 커밋 셋이 **칸 폭과 치수를 양식 파일에서 읽도록** 바꿨다:
#       6ec58d12 칸 폭을 화면이 굳혀 들지 말고 서버가 양식에서 읽어 넘긴다
#       2812d40a 양식이 바뀌어도 안 깨지게 — 시험이 굳혀 들던 치수를 양식에서 읽는다
#       322fe553 PDF 를 한 장에 맞춰 내보낸다 — 보고서가 두 장으로 갈라지고 있었다
#   운영 코드는 **이미 그 최신**(dss-as:4.8)인데 **읽히는 양식만 9월 판**이다.
#
#   🔴 **이미지를 안 굽는다. 컨테이너를 안 내린다. 마이그레이션도 compose 도 없다.**
#      양식은 /volume1/dss/as-templates 볼륨에 놓인 **파일**이고, 앱은 쓸 때마다
#      readFile 로 **다시 읽는다** — 캐시가 한 줄도 없다(2026-11-11 재확인:
#      src/lib/storage/quote-template.ts 84줄 · service-report-template.ts 213줄,
#      두 파일에 cache 라는 낱말이 0건). **앱을 안 내려도 바뀐다.**
#
#   🔵 양식 열한 장 중 매쳐·제너레이터용 넷은 2026-11-01 에 올라갔다.
#      **기본 둘만 남았고, 이 파일은 그 둘만 다룬다.**
#
# ── 🔴 차례를 못 박는다 ───────────────────────────────────────────────
#   (NAS)  bash /volume1/dss/setup/56-templates.sh            ← --check (안 바꾼다)
#   (NAS)  bash /volume1/dss/setup/56-templates.sh --prep     ← 백업 + 받을 자리
#   (개발) bash .../56-stage.sh --go  →  scp -O 두 장 → as-templates-incoming/
#   (NAS)  bash /volume1/dss/setup/56-templates.sh --apply    ✍ 양식을 바꾼다
#   (NAS)  bash /volume1/dss/setup/56-templates.sh            ← 다시 --check
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 51-deploy.sh 에서 베끼면 틀리는 것 다섯 — **전부 뒤집었다**
# ══════════════════════════════════════════════════════════════════════
#   「배포본은 지난 판의 전제를 업고 온다」가 이 저장소에 적힌 사고다. 51번
#   (마흔여덟째)의 --templates-prep(1055~1172줄) · --templates-apply(1174~1341줄)
#   를 틀로 썼지만 **아래 다섯은 값이 다르다.**
#     ① 올리는 장수    51번 다섯(TPL_UP_WANT=5) → **이번 둘(=2)**
#     ② 안 올리는 장수  51번 여섯              → **이번 아홉**
#     ③ 보내는 폴더    51번 _images-47/templates → **이번 _templates-56**
#        🔴 **_images-NN 을 쓰지 않는다.** 그 번호는 **배포본**이 쓰는 이름이고,
#           이 일은 배포가 아니다. 그 이름을 빌려 쓰면 나중에 이 파일을 돌리는
#           날 **그 폴더에 남의 배포 tar 가 이미 들어 있을 수 있다.**
#     ④ 함께 하는 일   51번 이미지 교체·마이그레이션·compose → **이번엔 없다. 양식만.**
#     ⑤ --check 가 재는 것  51번은 이미지 태그·DB 마이그레이션 수·compose 사본·
#        연락서 폴더·재고 통로까지 전부 쟀다 → **이번엔 양식 관련만 잰다.**
#        🔴 그것들을 통째로 가져오면 **기대값이 전부 낡아 가짜 ✗ 가 쏟아진다.**
#           (51번의 기대 태그는 dss-as:4.4 다. 운영은 이미 4.8 이다.)
#
# ══════════════════════════════════════════════════════════════════════
# 🔴 모드 셋 — **기본은 아무것도 안 바꾸는 모드다**
# ══════════════════════════════════════════════════════════════════════
#   (기본) --check   🔵 **아무것도 안 바꾼다.** 운영 양식을 **값으로** 잰다
#   --prep           백업하고 받을 자리를 만든다 — 🔴 **운영 양식은 안 건드린다**
#   --apply          ✍ 받을 자리의 두 장을 md5 로 맞대고 **제자리로 옮긴다**
#
# ── 각 모드가 **쓰는 것** 과 **안 쓰는 것** ──────────────────────────
#   --check   쓰는 것: **없다** (로그 파일 하나만 남긴다)
#             읽는 것: $TPLDIR · $TPLIN · $D/backups 의 목록 ·
#                      dss-as 컨테이너 안에서 설정 이름으로 node 한 번
#             🔴 docker exec 로 **읽기만 하는 node** 를 한 번 돈다 —
#                「아무것도 안 한다」가 아니라 「아무것도 **바꾸지** 않는다」다.
#   --prep    쓰는 것: $TPLBK(새 백업 폴더) · $TPLIN(받을 자리 · chmod 777)
#             🔴 **운영 양식($TPLDIR)은 한 글자도 안 건드린다.** cp 의 **원본**일 뿐이다
#             안 쓰는 것: compose · 이미지 · DB · 컨테이너 — 한 줄도 없다
#   --apply   쓰는 것: $TPLDIR 안의 **두 파일**(mv + chown + chmod) · $TPLIN(비운다)
#             🔴 **여기가 운영이 바뀌는 유일한 자리다.**
#             안 쓰는 것: 나머지 아홉 장 · compose · 이미지 · DB · 컨테이너
#             🔴 둘 다 맞을 때만 옮긴다. 하나라도 어긋나면 **아무것도 안 옮긴다** —
#                **반만 바뀐 상태가 제일 나쁘다.**
#
# ── 🔴 받는 자리를 따로 둔다 — 도는 앱이 반쪽 파일을 읽지 않게 ───────
#   scp 는 **/volume1/dss/as-templates-incoming/** 로 받는다. 그 폴더는 컨테이너에
#   안 붙는다. --apply 가 md5 를 먼저 맞대고, 맞을 때만 **mv** 로 제자리에 옮긴다
#   (같은 볼륨이라 이름 바꾸기 한 번이다). 덮어쓰는 도중에 보고서를 만들던 사람이
#   반쪽 파일을 읽는 길을 그렇게 막는다.
#   🔴 **받을 자리는 777 이어야 한다.** 이 스크립트는 root 로 도는데 scp 는
#      **root 가 아닌 계정**으로 붙는다. 755(root 소유)면 한 장도 못 올린다 —
#      「scp: …: Permission denied」. 2026-11-04 50번에서 실제로 걸렸다.
#   🔴 **옮긴 뒤 주인과 모드를 되읽는다.** scp 로 받으면 root 소유가 되고 앱은
#      uid 1000 으로 돈다. 이웃 양식의 주인·모드를 그대로 입히고 **다시 읽어**
#      확인한다. 안 입히면 앱이 그 양식을 못 읽어 보고서가 그 자리에서 죽는다.
#
# ── 🔴 양식 자리와 볼륨 ──────────────────────────────────────────────
#   🔵 운영 자리: compose 의 app-as·app-po 가 둘 다
#      '/volume1/dss/as-templates:/templates:ro' 로 붙인다.
#   🔴 **tools-as 에는 그 볼륨이 없다.** 그래서 양식은 **호스트에서 바로** 재고,
#      「앱이 보는가」는 **app-as(dss-as) 안에서** 따로 묻는다.
#
# ── 🔴 되돌리는 법 — 양식은 어떤 --rollback 으로도 안 돌아간다 ───────
#   --prep 과 --apply 가 끝에 **백업 경로와 함께** 되돌리는 명령을 찍는다:
#       cp -a <백업>/. /volume1/dss/as-templates/
#   🔵 cp -a 라 주인·모드·시각까지 함께 돌아온다.
#
# ── 🔴 bash -n 이 못 잡는 넷 — 이 파일에는 없다 ──────────────────────
#   ① 큰따옴표 안 백틱은 **명령 치환**으로 읽혀 조용히 터진다.
#      → 이 파일에는 백틱이 **한 개도 없다.** 쓴 뒤 grep 으로 세었다.
#   ② 읽기 전용 자리에 콜론 하나와 꺾쇠로 빈 파일을 만들면 NAS 의 ash 가 셸을
#      그 자리에서 끝낸다(2026-10-12 사고).
#      → 이 파일에는 그 꼴이 **한 군데도 없다.** 폴더는 mkdir 로만 만든다.
#   ③ 🔴 **grep -c 는 센 값이 0 일 때 종료 코드 1 이다.** set -uo pipefail 아래에서
#      스크립트를 쏜다 — 셈은 전부 「$( … || true )」 로 받는다.
#   ④ 🔴 **빈 결과를 ✓ 로 읽지 않는다.** 「폴더가 없다」·「못 읽었다」·「비어 있다」를
#      갈라서 적는다. 0개는 ✓ 가 아니다.
#   🔴 19·20·21번에는 ①②가 아직 남아 있다. **거기서 베껴 오지 마라.**
#
# ── 🔴 비밀값과 한글 ─────────────────────────────────────────────────
#   🔵 **양식 경로는 찍어도 된다** — /templates/… 는 저장소의 compose 사본에 이미
#      적혀 있는 값이고 비밀이 아니다. 🔴 다만 **/templates 밖을 가리키는 값은
#      안 찍는다**(어디로 샜는지는 사람이 설정 파일에서 직접 볼 일이다).
#   🔴 **한글을 argv·환경변수 이름에 넣지 않는다.** 설정 이름 열하나는 전부
#      ASCII 라 argv 로 넘겨도 안 깨진다. 양식 **이름**은 한글이지만 argv 로
#      넘기지 않는다 — 폴더를 열어 **데이터로** 읽고 찍기만 한다.
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
export PATH=/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

D=/volume1/dss
DOCKER=/usr/local/bin/docker
STAMP=$(date +%Y%m%d-%H%M%S)

TPLDIR=$D/as-templates
TPLIN=$D/as-templates-incoming
TPLBK=$D/backups/as-templates-$STAMP
TPL_IN_CONTAINER=/templates
# 🔴 양식 볼륨이 붙어 있는 상자. **tools-as 가 아니다** — 거기엔 그 볼륨이 없다.
AS_APP_CN=dss-as

# ══ 🔴 **이번에 올리는 둘** — 이름|바이트|md5 ═════════════════════════
#   출처: 2026-11-11 개발 PC 실측. 56-stage.sh 의 TPL_UP 표와 **글자 그대로 같다.**
#   🔴 한쪽만 고치면 --apply 가 md5 가 다르다며 **한 장도 안 옮긴다.**
TPL_UP='
수리보고서.xlsx|190710|403b642d7c700a118ee515e20e4d659e
검사보고서.xlsx|190589|f7dd2fe0dbf03e6a44fa48a00ee4413e
'
TPL_UP_WANT=2

# 🔵 **지금 운영에 놓여 있을 9월 판의 바이트 수** — [지시서] 2026-11-11 에 적힌 값.
#    🔴 **이 값은 어디서도 ✗ 를 내지 않는다.** 「지금 놓인 것이 그 9월 판이 맞나」를
#       사람이 눈으로 알아보라고 곁들이는 수일 뿐이다. 운영 양식이 이 값과 달라도
#       아무 문제가 아니다(그 사이에 누가 또 고쳤을 수 있다).
TPL_OLD='
수리보고서.xlsx|182773
검사보고서.xlsx|182626
'

# 🔵 **안 올리는 아홉** — 이름|바이트|md5. 운영 것과 같은지 **보기만** 한다.
#    🔴 다르다고 ✗ 를 내지 않는다. 운영 양식이 개발 PC 것과 꼭 같아야 한다는
#       보증이 어디에도 없다(직인 이미지와 계좌번호가 든 파일이라 저장소에 없고,
#       이미지에도 안 굽는다). 다르면 **사람이 보라는 뜻**이다.
#    🔵 51번에서는 이 자리가 **여섯**이었다. 그 사이 넷이 올라가 아홉이 됐다.
TPL_KEEP='
내자견적서.xlsx|85942|981edf1f1d4a1b4bf2747167c41149d5
제너레이터 OH 견적서.xlsx|62101|4ef6d9dc75f797efb7088b43e9b4c3f9
매쳐 내자 견적서.xlsx|40079|a9f1f7e75e2ac718d86c288efec41d43
매쳐 OH 견적서.xlsx|40664|fc4ee94678b99e5c7b60ca7d1fd94c57
케이블 견적서.xlsx|50996|5450deb6182ccf4c76c2c7ea14b143d8
수리보고서_매쳐.xlsx|191911|ab25c06be1799952e593c2eef810885e
검사보고서_매쳐.xlsx|191929|5701e075c3aac71f63d29fe28ed68e0f
수리보고서_제너레이터.xlsx|190340|f3b2c76d359c8decd33c01d8b4b0235b
검사보고서_제너레이터.xlsx|190507|ef7edda07812f937381f82819fc79d22
'
TPL_KEEP_WANT=9
# 🔴 둘 + 아홉 = 열하나. 이것이 전부다.
TPL_COUNT_WANT=11

# 🔴 앱이 보는 설정 이름 열하나. **전부 ASCII** 라 argv 로 넘겨도 안 깨진다.
TPL_ENV_NAMES="QUOTE_TEMPLATE_PATH OH_QUOTE_TEMPLATE_PATH MATCHER_QUOTE_TEMPLATE_PATH MATCHER_OH_QUOTE_TEMPLATE_PATH CABLE_QUOTE_TEMPLATE_PATH REPAIR_REPORT_TEMPLATE_PATH INSPECTION_REPORT_TEMPLATE_PATH MATCHER_REPAIR_REPORT_TEMPLATE_PATH MATCHER_INSPECTION_REPORT_TEMPLATE_PATH GENERATOR_REPAIR_REPORT_TEMPLATE_PATH GENERATOR_INSPECTION_REPORT_TEMPLATE_PATH"

# 🔵 개발 PC 에서 양식을 담아 둔 자리 — **scp 명령을 찍는 데에만 쓴다.**
#    🔴 51번은 _images-47 이었다. 이번 것은 **_templates-56** 이다 —
#       **_images-NN 이 아니다.** 그 번호는 배포본(이미지 tar · 마이그레이션 묶음)이
#       쓰는 이름이고 이 일은 배포가 아니다. 빌려 쓰면 나중에 돌리는 날 그 폴더에
#       **남의 배포 tar 가 들어 있다.**
#    🔴 **56-stage.sh 의 TPLOUT 과 같은 값이어야 한다.** 한쪽만 고치면 사람이
#       빈 폴더에서 scp 를 친다.
DEVPC_TPLDIR='C:/Users/희만/Desktop/Development/_templates-56'

MODE=check
case "${1:-}" in
  --check|"")  MODE=check ;;
  --prep)      MODE=prep ;;
  --apply)     MODE=apply ;;
  *) printf '🔴 모르는 모드: %s\n   쓸 수 있는 것: --check(기본) · --prep · --apply\n' "$1"; exit 2 ;;
esac

PASS=0; FAIL=0; WARN=0
ok()  { PASS=$((PASS+1)); printf '  ✓ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ✗ %s\n' "$1"; }
hm()  { WARN=$((WARN+1)); printf '  ? %s\n' "$1"; }
say() { printf '    %s\n' "$1"; }
cmd() { printf '      %s\n' "$1"; }
# 🔴 ✗ 가 났을 때 그 자리에서 찍는다 — 처음 도는 코드라 기대값이 틀릴 확률이
#    일 자체만큼 높다. ✓ 쪽 오판은 영영 안 드러나므로 ✗ 쪽을 크게 적는다.
doubt() { say "🔵 ✗ 가 났으면 **검사 자신을 먼저 의심하세요** — 이 줄의 기대값이"
          say "   어디서 왔는지는 이 파일 머리말의 표에 적혀 있습니다."; }

isnum() { case "${1:-}" in (''|*[!0-9]*) return 1;; (*) return 0;; esac; }
# 🔴 양식 표는 **공백을 지우면 안 된다** — 이름에 공백이 들어 있다
#    (「제너레이터 OH 견적서.xlsx」). 빈 줄만 걷어낸다.
tplrows() { printf '%s\n' "$1" | grep -v '^[[:space:]]*$'; }

tpl_md5()  { [ -s "$1/$2" ] || return 0; md5sum "$1/$2" 2>/dev/null | awk '{print $1}'; }
tpl_size() { [ -s "$1/$2" ] || return 0; stat -c %s "$1/$2" 2>/dev/null; }
# 🔵 폴더 안을 **값으로** 찍는다 — 이름 · 바이트 · 시각 · 주인 · 모드 · md5.
#    🔴 주인과 모드를 함께 찍는 까닭: 앱은 uid 1000 으로 돌고, root 소유 600 이면
#       파일이 멀쩡해도 못 읽는다. 「있는가」만 보면 그 결함이 안 보인다.
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
tpl_file_count() { local n; [ -d "$1" ] || return 0; n=$(find "$1" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' '); printf '%s' "${n:-}"; }
# 🔵 TPL_OLD 표에서 그 이름의 9월 판 바이트 수를 꺼낸다. 없으면 빈 줄.
tpl_oldsize() { # 1 이름
  tplrows "$TPL_OLD" | while IFS='|' read -r n s; do
    [ "$n" = "$1" ] && printf '%s' "$s"
  done
}

# ══ 🔴 앱이 그 양식을 **보는가** — 설정 이름으로 묻는다 ══════════════
#   🔴 이름은 전부 ASCII 다. 한글은 **값**으로만 오가고 argv 에 안 들어간다.
#   🔵 55-deploy.sh 705~800줄의 그 탐침을 글자 그대로 가져왔다.
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

# 🔴 **앱이 보는가** — 이것이 진짜 답이다. 호스트에서 재는 것은 겉이다.
app_probe() {
  local out okn missn unsetn
  printf '\n    ── 🔴 **앱이 그 양식을 보는가** (%s 안에서 설정 이름으로 묻는다)\n' "$AS_APP_CN"
  if [ ! -x "$DOCKER" ]; then
    hm "$DOCKER 가 없다 — 앱 쪽은 **못 쟀다.** 사람이 보세요"
    return
  fi
  out=$("$DOCKER" exec -e DSS_TPL_NAMES="$TPL_ENV_NAMES" "$AS_APP_CN" node -e "$TPL_ENV_PROBE" 2>&1 | tr -d '\r')
  if [ -z "${out:-}" ]; then
    hm "$AS_APP_CN 안에서 못 쟀다 — 그 상자가 도는지 보세요. **빈 결과는 삼켜진 오류일 수 있다**"
    return
  fi
  printf '%s\n' "$out" | sed 's/^/      /'
  # 🔴 grep -c 는 0 일 때 종료 코드 1 이다 — || true 로 받는다.
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
    hm "설정 이름이 비어 있는 것이 ${unsetn}개다 — **이 작업은 설정을 바꾸지 않는다.** 사람이 보세요"
    say "🔵 보고서 쪽 넷이 비어 있으면 코드가 **옛 이름 둘로 물러선다**(던지지는 않는다)."
  fi
}

# ══ 🔴 운영 양식 폴더를 **열 수 있는가** — 세 가지를 가른다 ═══════════
#   🔴 「0개」를 ✓ 로 읽지 않는다. 폴더가 **없다** · **못 읽었다** · **비어 있다**
#      는 서로 다른 일이고, 셋 다 ✗ 지만 사람이 할 일이 다르다.
#   돌려주는 값은 TPLN 에 담는다(파일 수). 0 이면 부르는 쪽이 멈춘다.
TPLN=0
tpl_open_check() { # 1 폴더
  TPLN=0
  say "자리: $1  (app-as·app-po 가 $TPL_IN_CONTAINER 로 붙인다 · 읽기 전용)"
  if [ ! -d "$1" ]; then
    bad "🔴 $1 **가 없다** — 운영 양식 폴더를 못 찾았다"
    say "🔵 볼륨 줄은 compose 에 있는데 폴더가 지워졌을 수 있습니다. 사람이 보세요."
    return 1
  fi
  if [ ! -r "$1" ]; then
    bad "🔴 $1 **를 못 읽는다** — 권한을 보세요 (이 스크립트는 root 로 돕니다)"
    return 1
  fi
  TPLN=$(tpl_file_count "$1")
  say "그 폴더 안 파일 ${TPLN:-못 쟀다}개 (적어 둔 수 $TPL_COUNT_WANT)"
  if ! isnum "${TPLN:-}"; then
    bad "🔴 파일 수를 **못 쟀다** — **빈 결과는 삼켜진 오류일 수 있다.** 사람이 보세요"
    TPLN=0; return 1
  fi
  if [ "$TPLN" -eq 0 ]; then
    bad "🔴 양식 폴더가 **비어 있다** — 열한 장이 있어야 한다"
    return 1
  fi
  if [ "$TPLN" = "$TPL_COUNT_WANT" ]; then
    ok "양식 폴더가 열리고 파일이 $TPL_COUNT_WANT 개다"
  else
    hm "파일이 ${TPLN}개다 — $TPL_COUNT_WANT 개를 적어 두었다. **막지는 않는다.** 아래 목록을 보세요"
    say "🔵 늘어난 것이면 누가 다른 양식을 더 둔 것이고, 줄었으면 사라진 것입니다."
  fi
  return 0
}

[ "$(id -u)" = 0 ] || { printf '먼저 sudo -i 로 관리자(root)가 된 뒤 실행하세요.\n'; exit 1; }
mkdir -p "$D/setup/logs"
LOG="$D/setup/logs/56-templates-$MODE-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

printf '%s\n' "운영 양식 **두 장**만 갈아 끼운다 (배포 번호와 무관하다)   $(date '+%Y-%m-%d %H:%M:%S')"
printf '%s\n' "  이 파일의 md5: $(md5sum "$0" | awk '{print $1}')"
printf '%s\n' "  🔴 개발 PC 의 Get-FileHash 값과 **같은지 눈으로 맞대세요** (DSM 터미널이 긴 것을 잘라 먹습니다)"
printf '%s\n' "  모드: $MODE"
printf '%s\n' "  로그: $LOG"
printf '%s\n' "  🔴 차례: --check → --prep → (개발 PC 에서 scp 두 장) → --apply → --check"
printf '%s\n' "  🔴 **바꾸는 모드는 --apply 하나뿐입니다.** --check 도 --prep 도 운영 양식을 안 건드립니다."
printf '%s\n' "  🔵 이미지·마이그레이션·compose 는 **이번 일에 없습니다.** 양식만입니다."
printf '%s\n' "  🔵 앱은 쓸 때마다 양식을 다시 읽습니다 — **컨테이너를 안 내려도 바뀝니다.**"
printf '%s\n' "────────────────────────────────────────────────────────────"

# ══════════════════════════════════════════════════════════════════════
# ── --check : 🔵 **아무것도 안 바꾼다.** 값으로 잰다 ──────────────────
# ══════════════════════════════════════════════════════════════════════
#   쓰는 것: **없다** (로그 파일 하나뿐)
#   읽는 것: 양식 폴더 · 받을 자리 · 백업 목록 · dss-as 안의 설정 이름 열하나
#   🔴 **단계마다 기대값이 다르다.** 올리기 전과 뒤가 둘 다 정상이고, 그 사이의
#      **반쪽 상태만 ✗** 다. 한 갈래로 두면 한쪽에서 가짜 ✗ 가 쏟아진다
#      (48번이 데인 자리다).
if [ "$MODE" = check ]; then
  printf '\n== 1. 운영 양식 폴더\n'
  if ! tpl_open_check "$TPLDIR"; then
    printf '\n%s\n' "────────────────────────────────────────────────────────────"
    printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
    printf '%s\n' "🔵 **아무것도 안 바꿨습니다.**"
    exit 1
  fi
  printf '\n== 2. 지금 놓여 있는 것 (이름 · 바이트 · 시각 · 주인 · 모드 · md5)\n'
  tpl_dump "$TPLDIR"

  printf '\n== 3. 🔴 이번에 갈아 끼울 **둘** — 어느 단계인가\n'
  say "🔴 「올리기 전」과 「올린 뒤」는 **둘 다 정상**입니다. ✗ 는 **반쪽**일 때만 납니다."
  UP_SEEN=0; UP_NEW=0; UP_OLD=0; UP_MISS=0
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    UP_SEEN=$((UP_SEEN+1))
    if [ ! -s "$TPLDIR/$name" ]; then
      say "없음   $name — 운영에 그 파일이 **없다**"
      UP_MISS=$((UP_MISS+1)); continue
    fi
    m=$(tpl_md5 "$TPLDIR" "$name"); s=$(tpl_size "$TPLDIR" "$name")
    if [ "${m:-x}" = "$wm5" ] && [ "${s:-x}" = "$wsz" ]; then
      UP_NEW=$((UP_NEW+1))
      say "새 판   $name  ($wsz바이트 · $wm5)"
    else
      UP_OLD=$((UP_OLD+1))
      say "옛 판   $name  운영 ${s:-?}바이트 ${m:-?}"
      say "        올릴 것 $wsz바이트 $wm5"
      # 🔵 곁들이는 수. **✗ 를 내지 않는다** — 그 9월 판이 맞나 눈으로 알아보라는 뜻.
      o=$(tpl_oldsize "$name")
      if [ -n "${o:-}" ]; then
        if [ "${s:-x}" = "$o" ]; then say "        🔵 지시서에 적힌 9월 판 바이트 수(${o})와 같다 — 그 판이 맞다"
        else say "        🔵 지시서에 적힌 9월 판은 ${o}바이트였다 — 그 사이에 또 바뀐 것일 수 있다 (문제는 아니다)"; fi
      fi
    fi
  done <<TPLUPEOF
$(tplrows "$TPL_UP")
TPLUPEOF
  # 🔴 **표본이 비어서 공짜로 통과하지 않게** — 몇 장을 봤는지를 먼저 단언한다.
  if [ "$UP_SEEN" = "$TPL_UP_WANT" ]; then ok "둘을 다 봤다 (표본이 비지 않았다)"
  else bad "${UP_SEEN}장만 봤다 — $TPL_UP_WANT 장을 기대했다. TPL_UP 표가 깨졌다"; doubt; fi
  say "새 판 ${UP_NEW} · 옛 판 ${UP_OLD} · 없음 ${UP_MISS}"
  if [ "$UP_MISS" != "0" ]; then
    bad "🔴 운영에 **없는 양식이 ${UP_MISS}장** 있다 — 설정이 가리키는데 파일이 없으면 보고서가 통째로 죽는다"
    doubt
  elif [ "$UP_NEW" = "$TPL_UP_WANT" ]; then
    ok "🔵 단계: **올린 뒤** — 둘 다 개발 PC 것과 같다. 할 일이 없다"
  elif [ "$UP_OLD" = "$TPL_UP_WANT" ]; then
    ok "🔵 단계: **올리기 전** — 둘 다 옛 판이다. 이것이 지금 기대하는 상태다"
    say "🔴 다음: bash $0 --prep"
  else
    bad "🔴 단계: **반쪽** — 새 판 ${UP_NEW}장 · 옛 판 ${UP_OLD}장이 섞여 있다"
    say "🔴 **반만 바뀐 상태가 제일 나쁩니다.** 두 보고서의 치수가 서로 다른 양식에서 나옵니다."
    say "🔵 받을 자리에 나머지를 다시 보내고 --apply 를 돌리면 풀립니다."
    doubt
  fi

  printf '\n== 4. 🔵 안 올리는 **아홉** — 보기만 한다 (다르다고 ✗ 를 내지 않는다)\n'
  say "🔵 운영 양식이 개발 PC 것과 꼭 같아야 한다는 보증은 어디에도 없다."
  say "   직인 이미지와 계좌번호가 든 파일이라 저장소에 없고 이미지에도 안 굽는다."
  K_SEEN=0; K_SAME=0; K_DIFF=0; K_MISS=0
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    K_SEEN=$((K_SEEN+1))
    if [ ! -s "$TPLDIR/$name" ]; then
      say "없음   $name"; K_MISS=$((K_MISS+1)); continue
    fi
    m=$(tpl_md5 "$TPLDIR" "$name"); s=$(tpl_size "$TPLDIR" "$name")
    if [ "${m:-x}" = "$wm5" ] && [ "${s:-x}" = "$wsz" ]; then
      K_SAME=$((K_SAME+1)); say "같다   $name"
    else
      K_DIFF=$((K_DIFF+1)); say "다르다 $name  운영 ${s:-?}바이트 ${m:-?}"
      say "       개발 PC $wsz바이트 $wm5"
    fi
  done <<TPLKEEPEOF
$(tplrows "$TPL_KEEP")
TPLKEEPEOF
  if [ "$K_SEEN" = "$TPL_KEEP_WANT" ]; then ok "아홉을 다 봤다 (표본이 비지 않았다)"
  else bad "${K_SEEN}장만 봤다 — $TPL_KEEP_WANT 장을 기대했다. TPL_KEEP 표가 깨졌다"; doubt; fi
  say "같다 ${K_SAME} · 다르다 ${K_DIFF} · 없다 ${K_MISS}"
  if [ "$K_MISS" != "0" ]; then
    bad "🔴 아홉 중 ${K_MISS}장이 운영에 **없다** — 이 작업이 건드릴 자리가 아닌데 비어 있다"
    doubt
  elif [ "$K_DIFF" = "0" ]; then
    ok "아홉이 전부 개발 PC 것과 같다 (**이 작업이 건드릴 자리가 아니다**)"
  else
    hm "아홉 중 ${K_DIFF}장이 개발 PC 것과 다르다 — **이 작업을 막지 않는다.** 사람이 보세요"
  fi
  # 🔴 둘 + 아홉 = 열하나를 **다 봤는가**. 표가 쪼개져도 여기서 드러난다.
  ALLSEEN=$((UP_SEEN+K_SEEN))
  if [ "$ALLSEEN" = "$TPL_COUNT_WANT" ]; then ok "두 표를 합쳐 $TPL_COUNT_WANT 장을 다 봤다"
  else bad "두 표를 합쳐 ${ALLSEEN}장만 봤다 — $TPL_COUNT_WANT 장을 기대했다"; doubt; fi

  printf '\n== 5. 앱 쪽\n'
  app_probe

  printf '\n== 6. 받을 자리와 백업 (상태만 본다 · 안 만든다)\n'
  if [ -d "$TPLIN" ]; then
    INN=$(tpl_file_count "$TPLIN")
    MODEIN=$(stat -c %a "$TPLIN" 2>/dev/null)
    say "받을 자리가 이미 있다: $TPLIN  (모드 ${MODEIN:-?} · 파일 ${INN:-못 쟀다}개)"
    if [ "${INN:-0}" != "0" ]; then
      tpl_dump "$TPLIN"
      say "🔵 --apply 는 **이름과 md5 가 맞는 둘만** 옮긴다. 나머지는 그대로 둔다."
    fi
    if [ "${MODEIN:-}" != "777" ]; then
      hm "받을 자리 모드가 ${MODEIN:-?} 다 — scp 가 거절당할 수 있다. --prep 가 777 로 연다"
    fi
  else
    say "받을 자리가 아직 없다 — --prep 가 만든다 ($TPLIN)"
  fi
  BKN=$(ls -1d "$D/backups/as-templates-"* 2>/dev/null | wc -l | tr -d ' ')
  LASTBK=$(ls -1d "$D/backups/as-templates-"* 2>/dev/null | sort | tail -1)
  say "양식 백업 폴더 ${BKN:-0}개 · 가장 최근: ${LASTBK:-없음}"

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  printf '%s\n' "🔵 **아무것도 안 바꿨습니다.** (로그 파일 하나만 남겼습니다)"
  if [ "$FAIL" = 0 ]; then
    printf '%s\n' "🔴 다음: bash $0 --prep   ← 백업하고 받을 자리를 만듭니다"
  else
    printf '%s\n' "🔴 위 ✗ 를 먼저 보세요."
  fi
  printf '%s\n' "────────────────────────────────────────────────────────────"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi

# ══════════════════════════════════════════════════════════════════════
# ── --prep : 🔴 **백업**하고 받을 자리를 만든다 ───────────────────────
# ══════════════════════════════════════════════════════════════════════
#   쓰는 것: $TPLBK(새 백업 폴더) · $TPLIN(받을 자리 · chmod 777)
#   🔴 **운영 양식($TPLDIR)은 한 글자도 안 건드린다** — cp 의 원본일 뿐이다.
#   안 쓰는 것: compose · 이미지 · DB · 컨테이너 — 이 모드에 그런 줄이 한 개도 없다.
#   🔴 백업은 **md5 로 맞대어 확인한다** — 「cp 가 돌았다」와 「같은 것이 들어갔다」는
#      다른 말이다(「겉이 아니라 결과를 봐라」).
if [ "$MODE" = prep ]; then
  printf '\n== 양식 백업 · 받을 자리 만들기 (🔵 운영 양식은 안 건드린다)\n'
  if ! tpl_open_check "$TPLDIR"; then
    printf '\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
    printf '%s\n' "🔴 운영 양식 폴더를 못 열었다 — **아무것도 안 하고 멈춘다.**"
    exit 1
  fi
  N0=$TPLN
  say "── 백업 전 모습"
  tpl_dump "$TPLDIR"

  # ── ① 백업 ───────────────────────────────────────────────────────
  mkdir -p "$TPLBK" 2>/dev/null
  if [ ! -d "$TPLBK" ]; then
    bad "백업 폴더를 못 만들었다: $TPLBK"
    printf '\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
    exit 1
  fi
  # 🔵 cp -a 라 주인·모드·시각까지 함께 뜬다 — 되돌릴 때 그대로 돌아온다.
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
  #    🔵 이름 목록을 임시 파일로 뽑는 까닭: 파이프 안의 while 은 셈을 안 넘겨 준다.
  #       🔴 빈 파일은 **touch 로만** 만든다(콜론과 꺾쇠는 ash 를 죽인다).
  NAMEF=/tmp/dss-tpl-names-$STAMP.txt
  touch "$NAMEF"
  ( cd "$TPLDIR" 2>/dev/null && find . -maxdepth 1 -type f -print 2>/dev/null | sed 's|^\./||' | sort ) > "$NAMEF"
  BAD5=0; SEEN5=0
  while IFS= read -r f; do
    [ -n "${f:-}" ] || continue
    SEEN5=$((SEEN5+1))
    a=$(tpl_md5 "$TPLDIR" "$f")
    b=$(tpl_md5 "$TPLBK" "$f")
    if [ -n "${a:-}" ] && [ "${a:-x}" = "${b:-y}" ]; then
      true
    else
      BAD5=$((BAD5+1)); say "🔴 백업이 다르다 — $f  (원본 ${a:-못 읽음} / 백업 ${b:-못 읽음})"
    fi
  done < "$NAMEF"
  rm -f "$NAMEF"
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
  #      · --apply 가 옮기면서 주인·모드를 **이웃 양식 값**으로 다시 입힌다
  #      · 옮기고 나면 이 폴더를 **비운다**
  chmod 777 "$TPLIN" 2>/dev/null
  #   🔴 **chmod 가 돌았다와 777 이 됐다는 다른 말이다** — 그래서 되읽는다.
  #   🔴 다만 777 이 아니라고 **✗ 를 내지 않는다.** 까닭 둘:
  #      · 51번은 이 모드를 **아예 안 쟀고** 그대로 잘 돌았다. 여기서 ✗ 를 내면
  #        **멀쩡한 절차를 내 검사가 막는다**(「배포 검사의 ✗ 가 검사 탓일 때」).
  #      · 진짜 답은 「scp 가 올라가나」다. 모드는 그 전조일 뿐이다.
  #   🔵 그래서 **남(others)에게 쓰기가 열렸는가**로 가르고, 안 열렸으면 ? 와 함께
  #      칠 명령을 찍는다. 그 줄이 바로 위에 있으니 scp 가 막히면 그 자리에서 푼다.
  MODEIN=$(stat -c %a "$TPLIN" 2>/dev/null)
  # 🔵 모드의 **끝자리**(남에게 주는 권한)만 꺼낸다. 🔴 파이프를 안 쓴다 —
  #    set -o pipefail 아래에서 뒤쪽이 먼저 끝나면 앞쪽이 SIGPIPE 로 죽어
  #    멀쩡한 값이 거짓이 된다(「grep 의 종료 코드가 배포 검사를 쏜다」).
  MODEOTH=${MODEIN#${MODEIN%?}}
  if [ ! -d "$TPLIN" ]; then
    bad "받을 자리를 못 만들었다: $TPLIN"
  elif [ "${MODEIN:-}" = "777" ]; then
    ok "받을 자리를 만들고 **되읽어 확인했다**: $TPLIN (모드 ${MODEIN} · 컨테이너에 안 붙는다)"
  else
    case "${MODEOTH:-}" in
      2|3|6|7)
        ok "받을 자리를 만들었다: $TPLIN (모드 ${MODEIN:-?} — 777 은 아니지만 **남에게 쓰기가 열려 있다**)"
        say "🔵 scp 는 root 가 아닌 계정으로 붙습니다. 쓰기만 열려 있으면 올라갑니다." ;;
      *)
        hm "🔴 받을 자리 모드가 ${MODEIN:-?} 다 — **scp 가 거절당할 수 있습니다.** 아래를 치세요"
        cmd "chmod 777 $TPLIN"
        say "🔵 ✗ 로 세지 않는 까닭: 진짜 답은 「scp 가 올라가나」이고, 여기서 막으면"
        say "   멀쩡한 절차를 검사가 가로막습니다. 올라가면 그대로 --apply 로 가세요." ;;
    esac
  fi
  OLDIN=$(tpl_file_count "$TPLIN")
  if [ "${OLDIN:-0}" != "0" ]; then
    hm "받을 자리에 파일이 이미 ${OLDIN}개 있다 — 지난번 찌꺼기일 수 있다. 아래를 보세요"
    tpl_dump "$TPLIN"
    say "🔵 --apply 는 **이름과 md5 가 맞는 둘만** 옮긴다. 나머지는 그대로 둔다."
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
  printf '%s\n' "🔴 **다음 — 개발 PC 에서 양식 두 장을 보내세요 (PowerShell)**"
  printf '%s\n' "    cd \"$DEVPC_TPLDIR\""
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    printf '%s\n' "    scp -O \"$name\" dss-nas:$TPLIN/"
  done <<TPLSCPEOF
$(tplrows "$TPL_UP")
TPLSCPEOF
  printf '%s\n' "  🔵 그 폴더는 개발 PC 에서 **56-stage.sh --go** 가 채워 줍니다."
  printf '%s\n' "  🔴 **한 줄에 하나씩입니다.** 이름에 공백과 한글이 둘 다 있어 별표(*)로 묶으면"
  printf '%s\n' "     PowerShell 이 어떻게 쪼갤지 장담할 수 없습니다."
  printf '%s\n' "  🔴 **scp 에는 -O 를 붙입니다.** DSM 에 sftp 서버가 없어 -O 없이는 실패합니다."
  printf '%s\n' "  🔴 **보내는 쪽에 드라이브 문자(C:)를 주지 마세요** — 위처럼 폴더로 들어가서 보냅니다."
  printf '%s\n' ""
  printf '%s\n' "  그다음 (NAS):  bash $0 --apply"
  printf '%s\n' ""
  printf '%s\n' "🔴 **되돌리는 법** — 양식은 어떤 --rollback 으로도 **안 돌아갑니다.** 손으로 되돌립니다:"
  printf '%s\n' "    cp -a $TPLBK/. $TPLDIR/"
  printf '%s\n' "    bash $0            ← --check 로 md5 를 다시 재세요"
  printf '%s\n' "  🔵 백업 폴더: $TPLBK"
  printf '%s\n' "  🔵 cp -a 라 주인·모드·시각까지 함께 돌아옵니다."
  printf '%s\n' "────────────────────────────────────────────────────────────"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════
# ── --apply : ✍ **양식 둘을 제자리로 옮긴다** (운영이 바뀌는 유일한 자리)
# ══════════════════════════════════════════════════════════════════════
#   쓰는 것: $TPLDIR 안의 **두 파일**(mv · chown · chmod) · $TPLIN(끝에 치운다)
#   안 쓰는 것: 나머지 아홉 장 · compose · 이미지 · DB · 컨테이너 ·
#               다시 띄우기 — 이 모드에 그런 줄이 한 개도 없다.
#   🔴 **md5 를 먼저 다 맞대고, 둘이 전부 맞을 때만 옮긴다.** 하나라도 어긋나면
#      **아무것도 안 옮긴다** — 반만 바꾼 상태가 제일 나쁘다.
#   🔴 옮긴 뒤 **주인과 모드를 되읽는다**(「주인과 모드를 둘 다 되읽을 것」).
if [ "$MODE" = apply ]; then
  printf '\n== 양식 둘을 제자리로 옮긴다 (✍ 쓰는 단계)\n'
  [ -d "$TPLDIR" ] || { bad "🔴 $TPLDIR 가 없다. 멈춘다"; exit 1; }
  [ -d "$TPLIN" ]  || { bad "🔴 받을 자리가 없다: $TPLIN — 먼저 --prep 를 돌리세요"; exit 1; }

  # ── ① 백업이 있는가 — **없으면 안 옮긴다** ──────────────────────
  BKN=$(ls -1d "$D/backups/as-templates-"* 2>/dev/null | wc -l | tr -d ' ')
  LASTBK=$(ls -1d "$D/backups/as-templates-"* 2>/dev/null | sort | tail -1)
  say "양식 백업 폴더 ${BKN:-0}개 · 가장 최근: ${LASTBK:-없음}"
  if isnum "${BKN:-}" && [ "${BKN:-0}" -ge 1 ]; then
    ok "되돌릴 백업이 있다 (${LASTBK})"
  else
    bad "🔴 양식 백업이 **하나도 없다** — 먼저 --prep 를 돌리세요. 되돌릴 길 없이 덮어쓰지 않는다"
    printf '\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
    exit 1
  fi

  say "── 받을 자리에 들어온 것"
  tpl_dump "$TPLIN"
  INN=$(tpl_file_count "$TPLIN")
  say "받을 자리 안 파일 ${INN:-못 쟀다}개 (우리가 기다리는 것은 $TPL_UP_WANT 장)"
  if ! isnum "${INN:-}" || [ "${INN:-0}" -eq 0 ]; then
    bad "🔴 받을 자리가 비었거나 못 읽었다 — **빈 결과는 삼켜진 오류일 수 있다.** 멈춘다"
    say "🔵 scp 가 거절당하지 않았는지 보세요(받을 자리는 777 이어야 합니다)."
    printf '\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
    exit 1
  fi

  # ── ② md5 를 **전부 먼저** 맞댄다 ───────────────────────────────
  printf '\n    ── 둘의 이름과 md5 를 맞댄다 (옮기기 **전에** 전부 본다)\n'
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
  if [ "$SEEN" = "$TPL_UP_WANT" ]; then ok "둘을 다 봤다 (표본이 비지 않았다)"
  else bad "${SEEN}장만 봤다 — $TPL_UP_WANT 장을 기대했다. TPL_UP 표가 깨졌다"; fi
  say "맞다 ${READY} · 안 맞다 ${NOTREADY}"
  if [ "$READY" != "$TPL_UP_WANT" ] || [ "$FAIL" != 0 ]; then
    bad "🔴 둘이 다 맞지 않는다 (${READY}/${TPL_UP_WANT}) — **아무것도 안 옮긴다**"
    say "🔴 반만 바꾼 상태가 제일 나쁘다. 덜 온 파일을 다시 보내고 이 모드를 다시 돌리세요."
    say "🔴 md5 가 다르면 **옮기다 깨진 것**이거나 **개발 PC 에서 또 고친 것**입니다 —"
    say "   뒤쪽이면 이 파일의 TPL_UP 표와 56-stage.sh 의 TPL_UP 표를 **둘 다** 고치세요."
    doubt
    printf '\n  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
    exit 1
  fi
  ok "🔴 둘이 **전부** 맞다 — 이제 옮긴다"

  # ── ③ 주인·모드의 본보기를 **이미 잘 돌던 이웃 양식**에서 뽑는다 ─
  #   🔴 scp 로 받으면 root 소유가 된다. 앱은 uid 1000 으로 돈다.
  #      안 입히면 앱이 그 양식을 **못 읽어** 보고서가 그 자리에서 죽는다.
  #   🔵 본보기는 **안 올리는 아홉** 중에서 고른다 — 이번에 안 건드리는, 이미 잘
  #      돌고 있는 파일이라야 믿을 수 있다.
  REFNAME=""
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    [ -s "$TPLDIR/$name" ] || continue
    REFNAME=$name
    break
  done <<TPLREFEOF
$(tplrows "$TPL_KEEP")
TPLREFEOF
  REFU=""; REFG=""; REFM=""
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
    hm "안 올리는 아홉 중 운영에 놓인 것이 하나도 없다 — 주인·모드의 본보기가 없다. 옮긴 뒤 사람이 보세요"
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
  if [ "$MOVED" = "$TPL_UP_WANT" ]; then ok "둘을 다 옮겼다"
  else bad "🔴 ${MOVED}/${TPL_UP_WANT} 개만 옮겼다 — **반만 바뀐 상태다.** 위를 보고 사람이 마무리하세요"; fi

  # ── ⑤ 제자리에서 **다시 잰다** — 겉이 아니라 결과 ───────────────
  printf '\n    ── 옮긴 뒤 제자리에서 다시 잰다 (md5 · 주인 · 모드를 **되읽는다**)\n'
  tpl_dump "$TPLDIR"
  AFTOK=0; AFTBAD=0; AFTPERM=0
  while IFS='|' read -r name wsz wm5; do
    [ -n "${name:-}" ] || continue
    m=$(tpl_md5 "$TPLDIR" "$name")
    u=$(stat -c %u "$TPLDIR/$name" 2>/dev/null)
    g=$(stat -c %g "$TPLDIR/$name" 2>/dev/null)
    o=$(stat -c %a "$TPLDIR/$name" 2>/dev/null)
    if [ "${m:-x}" = "$wm5" ]; then AFTOK=$((AFTOK+1))
    else AFTBAD=$((AFTBAD+1)); say "🔴 md5 가 다르다 — $name (${m:-못 읽음})"; fi
    if [ -n "${REFU:-}" ] && { [ "${u:-x}" != "$REFU" ] || [ "${g:-x}" != "$REFG" ] || [ "${o:-x}" != "$REFM" ]; }; then
      AFTPERM=$((AFTPERM+1))
      say "⚠️ 주인·모드가 본보기와 다르다 — $name (${u:-?}:${g:-?} ${o:-?} · 본보기 ${REFU}:${REFG} ${REFM})"
    fi
  done <<TPLAFEOF
$(tplrows "$TPL_UP")
TPLAFEOF
  if [ "$AFTOK" = "$TPL_UP_WANT" ] && [ "$AFTBAD" = "0" ]; then
    ok "제자리에서 다시 재도 둘의 md5 가 맞다"
  else
    bad "🔴 제자리에서 맞는 것이 ${AFTOK}/${TPL_UP_WANT} 개다 — 사람이 보세요"
    doubt
  fi
  if [ -n "${REFU:-}" ]; then
    if [ "$AFTPERM" = "0" ]; then ok "주인·모드를 입히고 **되읽어 확인했다** (${REFU}:${REFG} ${REFM})"
    else bad "🔴 주인·모드가 어긋난 것이 ${AFTPERM}개다 — 앱이 uid 1000 으로 돕니다. 손으로 맞추세요"
         cmd "chown $REFU:$REFG $TPLDIR/<파일>  &&  chmod $REFM $TPLDIR/<파일>"; fi
  fi

  # ── ⑥ 🔴 **앱이 보는가** — 그것이 진짜 답이다 ──────────────────
  app_probe

  # ── ⑦ 받을 자리를 치운다 ────────────────────────────────────────
  #   🔴 **남은 것을 지우지 않는다.** 우리가 안 옮긴 것은 우리 것이 아니다.
  #      비었을 때만 폴더를 거둔다.
  printf '\n    ── 받을 자리 정리\n'
  LEFT=$(tpl_file_count "$TPLIN")
  say "받을 자리에 남은 파일 ${LEFT:-0}개"
  if [ "${LEFT:-0}" = "0" ]; then
    if rmdir "$TPLIN" 2>/dev/null; then ok "받을 자리를 치웠다 ($TPLIN)"
    else say "🔵 받을 자리를 못 치웠다 — 빈 폴더라 해롭지 않다"; fi
  else
    hm "받을 자리에 ${LEFT}개가 남았다 — 우리가 안 옮긴 것이다. 아래를 보고 사람이 치우세요"
    tpl_dump "$TPLIN"
  fi

  printf '\n%s\n' "────────────────────────────────────────────────────────────"
  printf '  ✓ %s · ✗ %s · ? %s\n' "$PASS" "$FAIL" "$WARN"
  if [ "$FAIL" = 0 ]; then
    printf '%s\n' "✅ 양식 두 장이 운영에 들어갔습니다."
    printf '%s\n' "🔵 **앱은 쓸 때마다 양식을 다시 읽습니다 — 컨테이너를 안 내려도 바뀝니다.**"
    printf '%s\n' "   이미지도 마이그레이션도 compose 도 이번 일에는 없습니다."
    printf '%s\n' ""
    printf '%s\n' "🔴 다음 (NAS):  bash $0            ← --check 로 다시 재세요 (단계가 「올린 뒤」여야 합니다)"
    printf '%s\n' "🔵 그다음은 **눈 확인**입니다 — A/S 에서 수리보고서와 검사보고서를 한 장씩"
    printf '%s\n' "   내려받아 **칸 폭과 한 장짜리 PDF** 를 보세요. 그것이 이번 판의 까닭입니다."
  else
    printf '%s\n' "🔴 위 ✗ 를 보세요."
  fi
  printf '%s\n' ""
  printf '%s\n' "🔴 **되돌리는 법** — 양식은 어떤 --rollback 으로도 **안 돌아갑니다.** 손으로 되돌립니다:"
  printf '%s\n' "    cp -a ${LASTBK:-<백업폴더>}/. $TPLDIR/"
  printf '%s\n' "    bash $0            ← --check 로 md5 를 다시 재세요"
  printf '%s\n' "  🔵 백업 폴더: ${LASTBK:-없음}"
  printf '%s\n' "  🔵 cp -a 라 주인·모드·시각까지 함께 돌아옵니다."
  printf '%s\n' "────────────────────────────────────────────────────────────"
  exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
fi
