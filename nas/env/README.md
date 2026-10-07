# nas/env/ — 앱마다 하나씩

`docker-compose.nas.yml`이 여기서 각 앱의 설정을 읽는다.

| 파일 | 어느 앱 | 원본 |
|---|---|---|
| `auth.env` | 통합 로그인 | `dss-auth/.env.example` |
| `as.env` | A/S 관리 | `RF_Service_System/.env.example` |
| `meters.env` | 계측기 관리 | `njlee/.env.example` |
| `improvements.env` | 개선요청 (2026-09-18) | `dss-improvements/.env.example` |
| `po.env` | PO / 내자 (2026-09-29) | `dss-po/.env.example` |
| `leave.env` | 휴가 (2026-09-29) | `dss-leave/.env.example` |

**여섯 파일 모두 git에 올라가지 않는다** (`.gitignore`의 `nas/env/*.env`).
예시 파일을 여기 두지 않는 이유는 각 저장소의 `.env.example`이 이미 원본이기
때문이다. 여기 사본을 두면 언젠가 한쪽만 고쳐져 갈라진다.

## 만드는 법

각 저장소의 `.env.example`을 복사해 이름을 바꾸고 값을 채운다.

```bash
cp ../../dss-auth/.env.example          ./auth.env
cp ../../RF_Service_System/.env.example ./as.env
cp ../../njlee/.env.example             ./meters.env
cp ../../dss-improvements/.env.example  ./improvements.env
cp ../../dss-po/.env.example            ./po.env
cp ../../dss-leave/.env.example         ./leave.env
```

🔴 **복사한 뒤 반드시 지울 줄이 있다.** `DATABASE_URL` · `PORT` 는 compose 와
이미지가 주므로 여기 남으면 그쪽을 덮어쓴다. 개발 전용 값(`DEV_*` ·
`DSS_*_DB_PASSWORD` 등)도 지우거나 확실히 끈다 —
🔴 **`DEV_FAKE_LOGIN_ENABLED` 가 켜진 채 나가면 아무나 남의 계정으로 들어간다.**
(휴가는 `false` 로 **적어 두었다.** 줄을 지워도 꺼지지만, 없는 줄은 「끈 것」인지
「빠뜨린 것」인지 나중에 구별되지 않는다.)

## 채울 때 주의할 것

### `DATABASE_URL`은 여기에 넣지 않는다

compose가 `.env.nas`의 비밀번호로 직접 조립해서 넘긴다.
**여기에 또 적으면 값이 두 곳에 생기고, 언젠가 한쪽만 바뀐다.**
복사해 온 파일에 그 줄이 있으면 지운다.

계측기의 `FILE_STORAGE_ROOT`와 통합 로그인의 `BACKUP_MODE`, 개선요청의
`UPLOADS_DIR`도 같은 이유로 compose가 넘긴다.

개선요청의 `DEV_POSTGRES_PASSWORD`도 지운다 — 그 줄은 **개발 PC의 DB 상자**를
띄우는 `docker-compose.yml`이 읽는 값이고, NAS에는 그 상자가 없다.
`PORT`도 지운다 — 이미지가 `ENV PORT=3500`으로 들고 있다.

### 개발 PC용 값을 그대로 두지 않는다

`.env.example`은 개발 PC를 전제로 쓰였다. NAS에서는 달라지는 것들이 있다.
사내 주소는 **`http://192.168.0.222:<포트>`**로 정했다가(2026-09-14) 이튿날 **`https://login·as·meters.dss21.co.kr`**로
바꿨다(2026-09-15, `setup/05-https-switch.sh`). 아래 NAS 칸은 바꾼 뒤의 값이다.

| 값 | 개발 PC | NAS | 누가 넣나 |
|---|---|---|---|
| `OIDC_ISSUER` · `SSO_ISSUER` | `auto` | `https://login.dss21.co.kr` — 컨테이너 안에서 `auto`는 172.x를 잡는다 | env 파일 |
| `SSO_REDIRECT_URI` | `auto` | `https://as.dss21.co.kr`(계측기 `https://meters.dss21.co.kr`, 개선요청 `https://improvements.dss21.co.kr`)`/api/auth/sso/callback` | env 파일 |
| `KAKAO_REDIRECT_URI` | `auto` | `https://login.dss21.co.kr/api/kakao/callback` — **카카오 콘솔에도 등록**(옛 http 값도 남아 있다) | env 파일 |
| `SITE_URL` (계측기) | `http://localhost:3300` | `https://meters.dss21.co.kr` — 알림 메일 속 링크 | env 파일 |
| `TRUSTED_PROXY_HOPS` | `0` | **`1`** (DSM 프록시 뒤. 앱 포트는 `127.0.0.1`에만 열려 우회로가 없다) | env 파일 |
| `OIDC_ALLOW_HTTP_REDIRECT_URIS` | `true` | **`false`** — issuer 가 https 인데 `true` 면 포털이 **시작을 거부한다** | env 파일 |
| `SESSION_COOKIE_SECURE` (계측기 · 개선요청) | `false` | **`true`** — 사내 주소가 https 다(2026-09-15부터). 반대로 http 에서 켜면 쿠키가 저장되지 않아 로그인이 **조용히** 실패한다 | env 파일 |
| `DEMO_LOGIN_ENABLED` (A/S) | `true` | **`false`** — 운영에서 켜면 뒷문이다 | env 파일 |
| 서명·세션 키 (`AUTH_TX_SECRET` · `AUTH_SESSION_SECRET` · `SSO_TX_SECRET` · `CUSTOMER_LINK_TOKEN_KEY`) | 개발용 | **운영용으로 새로 만든다** — 개발과 운영이 같은 비밀을 쓰지 않는다 | env 파일 |
| 밖에 등록된 값 (카카오 키 · 메일 계정 · 포털 클라이언트 시크릿 · `AUTH_ACTIVE_KID`) | — | **개발 PC 것을 그대로** — 바꾸면 밖의 등록도 함께 바꿔야 한다 | env 파일 |
| `DSS_HOME_URL` · `DSS_HOME_SYNC_SECRET` (A/S) | `localhost:3200` | **비움** — 홈페이지 배포 전까지 고객 포털이 꺼져 있다 | env 파일 |
| `SMTP_USER` · `SMTP_PASSWORD` · `SMTP_FROM` (계측기) | **이 PC엔 없다** | 이남준 님 PC의 값을 **사람이** 옮겨 적는다. 비면 교정 알림 메일이 안 나간다 | 사람 |
| `TZ` | Windows 시각 | `Asia/Seoul` — 세 이미지 모두 tzdata가 있다(실측) | compose |
| `UPLOADS_DIR` (A/S) · `FILE_STORAGE_ROOT` (계측기) | `C:\…` | `/data` (볼륨) | compose |
| `UPLOADS_DIR` (개선요청) | `C:/DSS-IMPROVEMENTS-DATA/uploads` | `/data/uploads` (볼륨 — NAS 쪽은 `/volume1/dss/improvements-uploads`) | compose |
| 양식 경로 여섯 (A/S `*_TEMPLATE_PATH`) | `C:\DSS-AS-DATA\templates\…` | `/templates/…` (읽기 전용 볼륨) | compose |
| `AUTH_KEYS_DIR` · `BACKUP_MODE` (로그인) | `./keys` · `docker` | `/keys` · `direct` | compose |

> **표 아래 여덟 줄(`UPLOADS_DIR`, 양식 여섯, `TZ`)이 처음에 빠져 있었다** —
> `runbook/05` 11절 구멍 ㄱ. 이대로 세웠으면 견적서·보고서 출력이 전부 실패했다.
> 경로는 볼륨과 짝이라 compose가 넘기도록 옮겼다(2026-09-14).

### 2026-09-14에 실제로 만든 방법

세 파일을 손으로 복사하지 않고 스크립트로 만들었다. 개발 PC의 `.env.local`에서
**밖에 등록된 값만 가져오고**, 서명·세션 키는 새로 만들고, 주소는 위 표대로 적었다.
**값은 한 번도 화면에 찍지 않았고** 검사는 해시 대조로만 했다.
compose를 거쳐 값이 글자 그대로 들어가는지까지 확인했다 — compose는 `env_file` 값 안의
`$`를 변수로 풀어 버리므로 가져온 값은 전부 작은따옴표로 감쌌다.

> ⚠️ **주소를 바꾸면 포털에도 등록해야 한다.** 포털은 `redirect_uri`를
> **글자 단위로** 대조한다 — 와일드카드도 정규화도 하지 않는다. 시스템마다
> 고칠 곳이 네 군데이고, 하나라도 빠지면 로그인이 막힌다.
> 7단계(주소 갱신)에서 한 번에 처리한다.

### 공유폴더 설정 — A/S(`as.env`)에만 있는 네 묶음

A/S 는 **직원이 탐색기로 쓰는 공유폴더 넷**에 붙는다. 넷은 서로 **다른 곳**이고
설정도 따로다. 🔴 **한쪽 값을 다른 쪽에 베껴 쓰지 않는다.**

| 묶음 | compose 의 `target` | 설정 앞머리 | 앱이 하는 일 | 들어온 때 |
|---|---|---|---|---|
| 견적서 | `/quote-archive` | `QUOTE_ARCHIVE_*` | 읽고 **쓴다** | 2026-09-16 (일곱째) |
| 고객사 현황표 | `/customer-portal-archive` | `CUSTOMER_PORTAL_ARCHIVE_*` | 읽고 **쓴다** | 2026-10-02 (열두째) |
| 연락서 | `/contact-folder-archive` | `CONTACT_FOLDER_ARCHIVE_*` | 읽고 **쓴다** | 2026-10-05 (열넷째) |
| **「수리 관련」 서류** | `/repair-docs-archive` | `REPAIR_DOCS_ARCHIVE_*` | 🔴 **읽기만 한다** | **2026-10-08 (열다섯째)** |

🔴 **넷째만 `read_only: true` 로 붙인다**(사용자 결정 2026-10-08). 앱은 그 폴더를
훑어 **경로를 DB 에 적을 뿐** 만들지도 쓰지도 지우지도 않는다 — 파일을 **여는** 일은
사람 PC 의 탐색기 도우미가 한다. 그래서 거기에 쓰기가 되면 **오히려 이상한 것**이고,
`setup/19-deploy.sh` 는 「쓰기가 막혀 있는가」를 ✗ 로 센다.
🔵 넷째 볼륨은 셋째(연락서)의 **윗 폴더**다. 도커의 바인드는 서로 독립이라
**연락서 쪽 쓰기는 그대로 산다** — 19번 7-ㄴ 이 교체 뒤에 실제로 확인한다.

🔴 **실제 값은 여기 적지 않는다.** `as.env` 는 git 에 올라가지 않고(위 14행),
NAS 의 그 파일은 **배포 스크립트가 없는 줄만 덧붙인다**
(`setup/16-deploy.sh` 3-ㄹ · `setup/18-deploy.sh` 3-ㄷ · `setup/19-deploy.sh` 3-ㅁ).
🔴 **이 PC 의 `as.env` 를 NAS 로 올리지 않는다** — 그 사본에는 NAS 에만 있는 줄이
빠져 있어, 올리면 그 기능이 운영에서 통째로 사라진다.

#### 연락서 세 줄 (2026-10-05 · 열넷째 배포가 덧붙인다)

```
# 앱이 폴더를 찾고 만드는 **컨테이너 안** 경로. compose 의 target 과 같아야 한다.
# 비우면 연락서 연동만 꺼진다 — 수리 건 조회 · 파일 관리는 그대로 돈다.
CONTACT_FOLDER_ARCHIVE_DIR=

# 사람이 탐색기에서 보는 **연락서 쪽 루트**(UNC). 🔴 **도우미 설치본에만** 들어간다 —
# 서버 응답에도 로그에도 나가지 않는다. 도우미가 열 수 있는 범위가 곧 이 루트
# 아래 전부라 **될 수 있는 대로 좁게** 적는다(연락서 폴더들이 모여 있는 바로 그 폴더까지).
# 🔴 연락서에는 _ALT 가 **없다** — 루트 한 자리뿐이라 비켜 갈 두 번째 주소가 없다.
#    그래서 **IP 쪽**을 적는다(사내 DNS 가 없어 이름 풀이가 안 되는 PC 가 있다).
CONTACT_FOLDER_ARCHIVE_UNC_ROOT=

# 사람이 탐색기 주소창에 붙여넣을 **전체 주소**. 🔴 **이 값만 화면으로 나간다**([위치 복사]).
# 서버가 폴더 이름을 이어 붙이지 않는다 — 적힌 값 그대로 나가고, 사람이 그 안에서
# 제 인수번호 폴더를 찾는다. 그래서 **_UNC_ROOT 와 같은 값인 것이 맞다.**
# 사내 폴더 구조를 브라우저로 내보내고 싶지 않으면 비운다(그러면 단추가 없다).
CONTACT_FOLDER_ARCHIVE_UNC_PATH=
```

⚠️ **값에 따옴표를 두르지 않는다.** `env_file` 의 큰따옴표 안에서는 역슬래시가
이스케이프로 읽혀 `\2` · `\3` 이 조용히 사라진다. 따옴표 없이 적으면 줄 끝까지가
그대로 값이다(빈칸·괄호가 들어 있어도 된다).
🔴 배포 스크립트가 교체 뒤에 **컨테이너 안에서 역슬래시 개수를 센다**(넷 이상이어야 맞다).

#### 「수리 관련」 서류 두 줄 (2026-10-08 · 열다섯째 배포가 덧붙인다)

```
# 앱이 **읽기만** 하는 컨테이너 안 경로. compose 의 target 과 같아야 한다.
# 🔴 그 볼륨은 read_only: true 다 — 앱에 만들기·쓰기·지우기 코드가 한 글자도 없다
#    (RF_Service_System/src/lib/storage/repair-docs-archive.ts 머리말).
# 비우면 「가리킨 서류」 기능만 꺼진다 — 제품 모델 조회 · 사진·도면은 그대로 돈다.
REPAIR_DOCS_ARCHIVE_DIR=

# 사람이 탐색기에서 보는 **「수리 관련」 쪽 루트**(UNC). 🔴 **도우미 설치본에만**
# 들어간다 — 서버 응답에도 로그에도 나가지 않는다. 도우미가 열 수 있는 범위가 곧 이
# 루트 아래 전부라 **될 수 있는 대로 좁게** 적는다(공유 뿌리가 아니라 수리 관련
# 서류가 모여 있는 바로 그 폴더까지).
# 🔴 이쪽에도 _ALT 가 **없다** — 비켜 갈 두 번째 주소가 없으므로 **IP 쪽**을 적는다
#    (사내 DNS 가 없어 이름 풀이가 안 되는 PC 가 있다. 연락서와 같은 판단).
# 🔴 설치본에 심기는 루트는 이 루트가 **맨 뒤**다 — 앞에 끼워 넣으면 이미 설치된
#    PC 의 루트 차례가 통째로 밀린다(quote-folder-helper.ts 의 그 당부).
REPAIR_DOCS_ARCHIVE_UNC_ROOT=
```

🔵 연락서와 달리 **`_UNC_PATH` 가 없다** — 이 화면에는 [위치 복사]가 없어서
화면으로 나가는 값이 하나도 없다. 그래서 두 줄뿐이다.

🔴 **도우미는 PC 당 한 벌**이다(레지스트리 `dss-folder`). 설치본 하나에 견적서 ·
현황표 · 연락서 · **「수리 관련」** 루트가 **함께** 심기므로, 설치 명령은
**A/S 화면에서만** 받는다 — PO 화면에서 받으면 그 PC 의 현황표 [폴더 열기]가
먹통이 된다.
🔴 **루트가 늘어난 판에서는 모든 PC 가 다시 설치해야 한다**(열다섯째가 그렇다).
옛 도우미는 새 루트의 주소를 받으면 **조용히 아무 일도 하지 않는다.**
🔵 2026-10-08 판부터 **세대 표시**(`dss.helper.gen1.openfile`)가 생겨, 다음 판부터는
이미 새 도우미가 있는 PC 에 재설치 안내가 안 뜬다.

### 비밀값을 옮길 때

메신저나 메일로 보내지 않는다. 보낸 사람도 받은 사람도 지울 수 없는 사본이
남는다. NAS에 직접 입력하거나, 옮겼다면 옮긴 흔적을 지운다.
