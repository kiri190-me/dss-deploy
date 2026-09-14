# nas/env/ — 앱마다 하나씩

`docker-compose.nas.yml`이 여기서 각 앱의 설정을 읽는다.

| 파일 | 어느 앱 | 원본 |
|---|---|---|
| `auth.env` | 통합 로그인 | `dss-auth/.env.example` |
| `as.env` | A/S 관리 | `RF_Service_System/.env.example` |
| `meters.env` | 계측기 관리 | `njlee/.env.example` |

**세 파일 모두 git에 올라가지 않는다** (`.gitignore`의 `.env.*`).
예시 파일을 여기 두지 않는 이유는 각 저장소의 `.env.example`이 이미 원본이기
때문이다. 여기 사본을 두면 언젠가 한쪽만 고쳐져 갈라진다.

## 만드는 법

각 저장소의 `.env.example`을 복사해 이름을 바꾸고 값을 채운다.

```bash
cp ../../dss-auth/.env.example          ./auth.env
cp ../../RF_Service_System/.env.example ./as.env
cp ../../njlee/.env.example             ./meters.env
```

## 채울 때 주의할 것

### `DATABASE_URL`은 여기에 넣지 않는다

compose가 `.env.nas`의 비밀번호로 직접 조립해서 넘긴다.
**여기에 또 적으면 값이 두 곳에 생기고, 언젠가 한쪽만 바뀐다.**
복사해 온 파일에 그 줄이 있으면 지운다.

계측기의 `FILE_STORAGE_ROOT`와 통합 로그인의 `BACKUP_MODE`도 같은 이유로
compose가 넘긴다.

### 개발 PC용 값을 그대로 두지 않는다

`.env.example`은 개발 PC를 전제로 쓰였다. NAS에서는 달라지는 것들이 있다.
사내 주소는 **`http://192.168.0.222:<포트>`**로 정했다(2026-09-14) — 로그인 3100 · A/S 3000 · 계측기 3300.

| 값 | 개발 PC | NAS | 누가 넣나 |
|---|---|---|---|
| `OIDC_ISSUER` · `SSO_ISSUER` | `auto` | `http://192.168.0.222:3100` — 컨테이너 안에서 `auto`는 172.x를 잡는다 | env 파일 |
| `SSO_REDIRECT_URI` | `auto` | `http://192.168.0.222:3000`(계측기 `:3300`)`/api/auth/sso/callback` | env 파일 |
| `KAKAO_REDIRECT_URI` | `auto` | `http://192.168.0.222:3100/api/kakao/callback` — **카카오 콘솔에도 등록** | env 파일 |
| `SITE_URL` (계측기) | `http://localhost:3300` | `http://192.168.0.222:3300` | env 파일 |
| `TRUSTED_PROXY_HOPS` | `0` | **`1`** (DSM 프록시 뒤. 앱 포트는 `127.0.0.1`에만 열려 우회로가 없다) | env 파일 |
| `OIDC_ALLOW_HTTP_REDIRECT_URIS` | `true` | `true` — HTTPS 전환과 동시에 `false` | env 파일 |
| `DEMO_LOGIN_ENABLED` (A/S) | `true` | **`false`** — 운영에서 켜면 뒷문이다 | env 파일 |
| 서명·세션 키 (`AUTH_TX_SECRET` · `AUTH_SESSION_SECRET` · `SSO_TX_SECRET` · `CUSTOMER_LINK_TOKEN_KEY`) | 개발용 | **운영용으로 새로 만든다** — 개발과 운영이 같은 비밀을 쓰지 않는다 | env 파일 |
| 밖에 등록된 값 (카카오 키 · 메일 계정 · 포털 클라이언트 시크릿 · `AUTH_ACTIVE_KID`) | — | **개발 PC 것을 그대로** — 바꾸면 밖의 등록도 함께 바꿔야 한다 | env 파일 |
| `DSS_HOME_URL` · `DSS_HOME_SYNC_SECRET` (A/S) | `localhost:3200` | **비움** — 홈페이지 배포 전까지 고객 포털이 꺼져 있다 | env 파일 |
| `SMTP_USER` · `SMTP_PASSWORD` · `SMTP_FROM` (계측기) | **이 PC엔 없다** | 이남준 님 PC의 값을 **사람이** 옮겨 적는다. 비면 교정 알림 메일이 안 나간다 | 사람 |
| `TZ` | Windows 시각 | `Asia/Seoul` — 세 이미지 모두 tzdata가 있다(실측) | compose |
| `UPLOADS_DIR` (A/S) · `FILE_STORAGE_ROOT` (계측기) | `C:\…` | `/data` (볼륨) | compose |
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

### 비밀값을 옮길 때

메신저나 메일로 보내지 않는다. 보낸 사람도 받은 사람도 지울 수 없는 사본이
남는다. NAS에 직접 입력하거나, 옮겼다면 옮긴 흔적을 지운다.
