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

| 값 | 개발 PC | NAS |
|---|---|---|
| `OIDC_ISSUER` · `SSO_ISSUER` | `http://localhost:3100` | 리버스 프록시 뒤의 주소 |
| `SSO_REDIRECT_URI` | `http://localhost:33xx/...` | 〃 |
| `TRUSTED_PROXY_HOPS` | `0` | **`1`** (프록시 뒤에 서므로) |
| `OIDC_ALLOW_HTTP_REDIRECT_URIS` | 사내 HTTP 단계에서만 `true` | HTTPS 전환과 동시에 `false` |
| `AUTH_KEYS_DIR` | `./keys` | `/keys` (볼륨으로 붙는다) |

> ⚠️ **주소를 바꾸면 포털에도 등록해야 한다.** 포털은 `redirect_uri`를
> **글자 단위로** 대조한다 — 와일드카드도 정규화도 하지 않는다. 시스템마다
> 고칠 곳이 네 군데이고, 하나라도 빠지면 로그인이 막힌다.
> 7단계(주소 갱신)에서 한 번에 처리한다.

### 비밀값을 옮길 때

메신저나 메일로 보내지 않는다. 보낸 사람도 받은 사람도 지울 수 없는 사본이
남는다. NAS에 직접 입력하거나, 옮겼다면 옮긴 흔적을 지운다.
