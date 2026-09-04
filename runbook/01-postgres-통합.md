# PostgreSQL 인스턴스를 둘로 줄인다

DS218+(RAM 6GB) 이전을 앞두고, 다섯 갈래로 흩어진 PostgreSQL을
**인증용 하나 · 업무용 하나**로 합친다. 데이터 경계는 DB와 롤로 그대로 지키면서
인스턴스 개수만 줄인다.

| | |
|---|---|
| 작성 | 2026-09-02 |
| 대상 | `dss-auth` · `RF_Service_System` · `njlee` |
| 상태 | 결정 A·B 확정 — 착수 가능 |
| 해소 | `njlee/REQUIREMENTS.md` 미정 항목 T4 (운영 DB 계정·비밀번호) |

---

## 1. 조사에서 바뀐 전제

계획을 세우려고 네 저장소를 열어 보니 처음 그림과 다른 점이 셋 나왔다.
계획의 값어치를 좌우하므로 먼저 적는다.

### ① 지금 넷이 아니라 다섯이다

A/S 시스템이 `db-dev`(5432)와 `db-staging`(5433) 둘을 정의하고 있다.
staging은 `profiles: [staging]`이라 평소엔 안 뜨지만, 정의상 인스턴스는 다섯이다.

### ② NAS에 실제로 올라갈 DB는 셋이다

`dss-home/docker-compose.yml`에 이렇게 적혀 있다 —
*"이 DB는 개발용일 뿐이다. 운영에서 이 표들은 회사 밖 호스팅의 관리형 Postgres에
있게 된다(사내 NAS가 아니다)."* 회사 홈페이지는 공개 사이트고, 사내 A/S가
`customer-portal-sync.ts`로 당겨오는 구조다.

그래서 절감 폭을 정직하게 다시 쓰면 이렇다.

| | 줄어드는 폭 | 뜻 |
|---|---|---|
| 개발 PC | 5 → 2 | 체감이 가장 큰 쪽 |
| 운영 NAS | 3 → 2 | 메모리 절감 약 150MB |
| HDD fsync 경로 | 3 → 2 | DS218+의 진짜 병목 |

즉 **NAS 메모리만 놓고 보면 통합의 이득은 크지 않다.** RAM 6GB로 올리면 인스턴스
셋도 충분히 돌아간다. 통합의 실익은 **디스크 I/O 경합과 운영 단순화**에 있다.

### ③ 더 급한 문제가 따로 있다 — 버전 혼재

> **이것이 이 문서의 가장 중요한 발견이다.**

계측기 DB만 **PostgreSQL 17.11**이고 나머지 셋은 **16.14**다.
`njlee/docker-compose.yml` 주석에 이유가 있다 — 이남준 님 PC가 17.11이라,
거기서 뜬 덤프를 16의 `pg_restore`가 열지 못한다("unsupported version").

이 상태로 NAS에 올리면 **백업 복구가 조건부로만 되는 시스템**이 된다.
인스턴스를 둘로 줄이든 셋으로 두든 버전 통일은 어차피 해야 한다.
통합 작업은 그 통일을 자연스럽게 끼워 넣을 수 있는 창구다.

---

## 2. 현황 — 지금 다섯 개다

각 저장소 `docker-compose.yml`에서 그대로 읽은 값이다.

| 컨테이너 | 버전 | 포트 | DB | 앱 롤 | NAS |
|---|---|---|---|---|---|
| `dss-as-postgres-dev` | 16.14 | 5432 | `dss_as_dev` · `dss_as_test` | `dss_app` | ✅ |
| `dss-as-postgres-staging` | 16.14 | 5433 | `dss_as_staging` | `dss_app` | ❌ 개발 PC 전용 |
| `dss-auth-postgres-dev` | 16.14 | 5434 | `dss_auth_dev` | `dss_auth_app` | ✅ |
| `dss-home-postgres-dev` | 16.14 | 5436 | `dss_home_dev` | `dss_home_app` | ❌ 바깥 호스팅 |
| `dss-meters-postgres-dev` | **17.11** | 5438 | `dss_meters_dev` | `dss_meters_app` | ✅ |

### 이관을 쉽게 만드는 사실 셋

- **확장(extension)을 하나도 안 쓴다.** 네 저장소 어디에도 `CREATE EXTENSION`이 없다.
  UUID는 `gen_random_uuid()`로 만드는데 PostgreSQL 13부터 코어에 있다.
- **A/S가 이미 한 인스턴스에 DB 둘을 돌리고 있다.** `dss_as_dev`와 `dss_as_test`가
  같은 5432에 있다. 하려는 일이 이미 부분적으로 검증돼 있다.
- **모든 앱이 `DATABASE_URL` 하나만 본다.** 접속 대상을 바꾸는 데 코드 수정이 필요 없다.

---

## 3. 목표 구조

결정 A·B가 확정되어 아래가 최종 형태다. NAS는 운영 전용이고, 공개 사이트와 staging은 여기 없다.

| 인스턴스 | 포트 | 담는 DB | 접속 롤 | 왜 여기인가 |
|---|---|---|---|---|
| **`dss-pg-auth`** | 5434 | `dss_auth` | `dss_auth_app` | 서명 개인키·카카오 시크릿·클라이언트 시크릿 해시를 다룬다. 등급이 다르므로 프로세스째 격리한다. |
| **`dss-pg-app`** | 5432 | `dss_as` · `dss_meters` | `dss_app` · `dss_meters_app` | 업무 데이터. 서로 참조하지 않고 보안 등급이 같다. 인스턴스를 나눌 이유가 없다. |

### 경계를 왜 인증에 긋는가

`dss-auth/src/lib/db/schema/users.ts`에 적힌 원칙과 같은 선이다 — 포털이 답하는
질문은 "이 사람이 우리 회사 사람이고 지금 쓸 수 있는 상태인가" 하나뿐이고, 역할과
권한은 각 시스템이 자기 DB에서 관리한다. 인증 DB는 **업무 DB가 전부 털려도 닿을 수
없는 곳**에 있어야 그 원칙이 실제로 성립한다.

반대로 A/S와 계측기 사이에는 그런 등급 차이가 없다. 둘을 갈라 두는 것은 비용만 내고
얻는 게 없다.

**앱 프로세스 넷은 그대로 둔다.** 이 계획은 DB 인스턴스만 건드린다.

---

## 4. 확정된 결정

### 결정 A — 회사 홈페이지는 앱도 DB도 NAS에 두지 않는다 ✅

**DB 확정 (2026-09-02)** — 운영 DB는 회사 밖 관리형 Postgres. NAS가 담는 DB는
`dss_auth` · `dss_as` · `dss_meters` 셋이다.

**앱도 확정 (2026-09-02)** — 처음에는 "앱은 NAS, DB만 바깥"으로 갈라져 있었으나
앱까지 바깥으로 정했다. 공개 사이트를 사내 NAS에 두면 외부 공개를 위해 방화벽에
구멍을 내야 하고, **그 구멍이 포털·A/S·계측기 옆에 뚫린다.** 사내 전용 원칙을
지키는 가장 확실한 방법은 공개돼야 하는 것을 애초에 같은 상자에 넣지 않는 것이다.

**따라가는 결과**

- NAS는 **사내 전용 시스템 셋만** 담는다. 예외가 없어져 6단계(접근 경계) 설계가
  단순해진다 — 인터넷에서 들어오는 길을 아예 검토하지 않아도 된다.
- 홈페이지의 「사내 시스템」 버튼(`PORTAL_URL`)은 **사내망에서만 닿는다.**
  밖의 손님이 눌러도 들어가지 못하고, 그게 맞다. 사원이 밖에서 쓰려면 VPN이다.
  ⚠️ 이것을 "고치려고" 포털을 인터넷에 열지 않는다.
- 사내 A/S가 홈페이지의 `/api/nas-sync/*`를 **불러 간다**(`DSS_HOME_URL`로
  나가는 요청, `customer-portal-sync.ts`). 방향이 **안에서 밖**이라 방화벽에
  구멍이 필요 없다. 인증은 `DSS_HOME_SYNC_SECRET`이 맡는다.

### 결정 B — staging은 NAS에 두지 않는다 ✅

NAS는 운영 전용으로 간다. 배포 전 검증은 **배포 리허설**로 대신한다.

개발 PC의 `db-staging` 정의는 **지우지 않고 그대로 둔다.** `profiles`가 걸려 있어
자원을 쓰지 않고, 나중에 필요해질 때 다시 꺼내 쓸 수 있다.

> ⚠️ `RF_Service_System/HANDOFF.md`의 운영 준비 **17번을 갱신해야 한다.**
> 지금 문구("운영 환경(staging) 구성 — 앱 쪽 설정이 없어 연결만 안 된 상태")를
> 그대로 두면, 다음 세션이 이 결정을 모른 채 staging을 마저 만들려 든다.

### staging이란 무엇인가

운영과 똑같이 생겼지만 진짜 데이터가 없는 **예행연습용 복제본**이다.
A/S 저장소의 배포 규칙(`CLAUDE.md:37`)이 요구하는 "테스트 서버 검증"이 이 자리다.

| 환경 | DB | 데이터 | 누가 쓰나 | 지금 |
|---|---|---|---|---|
| **dev** 개발 | `dss_as_dev` | 손으로 만든 씨앗 데이터 | 개발자 본인 | 쓴다 |
| **test** 자동 테스트 | `dss_as_test` | 테스트가 매번 만들고 지운다 | `npm run test:db` | 쓴다 |
| **staging** 예행연습 | `dss_as_staging` | 운영 복제본이 들어갈 자리 | 배포 전 검증 | **껍데기** |
| **production** 운영 | `dss_as` | 진짜 A/S 데이터 | 사원 15명 | 아직 없음 |

저장소 전체를 뒤져 보면 `staging`은 **`docker-compose.yml` 안에서만** 나온다.
npm 스크립트에도, `.env.example`에도, 앱 코드에도 없다.

### 채택 — 상시 staging 대신 배포 리허설

배포 직전에 **운영 DB를 덤프해 개발 PC에 복원하고, 거기서 마이그레이션을 먼저 돌려 본다.**

```bash
# 1. 운영에서 뜬다
docker exec dss-pg-app pg_dump -U dss_app -d dss_as -Fc > rehearsal.dump

# 2. 개발 PC의 빈 DB에 넣는다
createdb dss_as_rehearsal && pg_restore -d dss_as_rehearsal rehearsal.dump

# 3. 새 마이그레이션을 진짜 데이터에 돌려 본다 — 시간도 잰다
DATABASE_URL=...dss_as_rehearsal npm run db:migrate
```

상시 컨테이너가 필요 없고, 진짜 데이터로 검증하며, NAS 자원을 쓰지 않는다.
A/S에 이미 있는 `npm run db:preflight`를 리허설의 첫 단계로 넣으면 된다.

> **나중에 마음이 바뀌면** — 상시 staging이 정말 필요해지면 이 계획을 되돌릴 필요는
> 없다. `dss_as_staging`을 `dss-pg-app` 안의 DB로 하나 더 만들고 권한을 한 벌 더
> 걸면 된다. **인스턴스는 그때도 둘이다.**

---

## 5. 버전은 17로 통일

| 방향 | 가능한가 | 근거 |
|---|---|---|
| 16 → 17 | ✅ 가능 | `pg_dump`로 뽑아 상위 버전에 복원하는 것은 정상 경로다 |
| 17 → 16 | ❌ 불가 | 17이 만든 아카이브를 16의 `pg_restore`가 거절한다 |

따라서 **두 인스턴스 모두 PostgreSQL 17**로 세운다.

### 이미지는 alpine 대신 Debian 계열로

`njlee`가 `LANG: ko_KR.UTF-8`을 걸어 두었지만 alpine은 musl libc라 로케일 지원이
사실상 없다. 지금 이 설정은 효과가 없을 가능성이 높다.

> **그런데 왜 정렬이 멀쩡해 보였나** — 현대 한글 음절(U+AC00–U+D7A3)은 유니코드
> 상에서 이미 가나다 순으로 배열돼 있다. 그래서 **순수 한글 이름만 정렬할 때는
> 바이트 순서가 우연히 맞는다.** 문제는 한글·영문·숫자·한자가 섞일 때다 —
> 계측기 이름이 딱 그렇다.

`postgres:17`(Debian 계열)을 쓰고 DB를 만들 때 ICU 로케일을 지정한다.

---

## 6. 권한 설계 — 계획의 핵심

인스턴스를 합쳐도 데이터가 섞이지 않는다는 보장은 전적으로 여기서 나온다.
이 절을 대충 하면 통합은 그냥 **격리를 버린 것**이 된다.

> ⚠️ **가장 빠지기 쉬운 함정**
> PostgreSQL의 기본값은 **"모든 롤이 모든 DB에 접속 가능"**이다. `PUBLIC`에
> `CONNECT`가 기본으로 부여돼 있기 때문이다. 롤을 나누기만 하고 이걸 걷어내지 않으면
> `dss_meters_app`으로 `dss_as`에 그냥 붙을 수 있다. **롤을 나눴다는 것이 착각이 된다.**

초기화 스크립트는 [`nas/init/app/01-roles.sh`](../nas/init/app/01-roles.sh)(업무)와
[`nas/init/auth/01-roles.sh`](../nas/init/auth/01-roles.sh)(인증)에 있다.
각각 그 인스턴스의 `/docker-entrypoint-initdb.d`에 마운트한다.

`.sql`이 아니라 `.sh`인 이유는 **비밀번호를 파일에 박지 않기 위해서**다.
docker의 initdb는 `.sql`에 psql 변수를 넘길 방법이 없어서, 셸에서 `-v`로
환경변수를 건넨다. 두 스크립트 모두 **처음 만들어질 때 한 번만** 돌고,
볼륨이 이미 있으면 실행되지 않는다.

PostgreSQL 15부터 `public` 스키마의 `CREATE` 권한이 `PUBLIC`에서 기본 제거됐다.
17을 쓰므로 이 부분은 추가 조치가 필요 없다.

### 격리 검증 — 반드시 실패해야 하는 명령

```bash
# 계측기 계정으로 A/S DB에 붙어 본다. 거절돼야 정상이다.
docker exec -it dss-pg-app psql -U dss_meters_app -d dss_as
# 기대: FATAL: permission denied for database "dss_as"

# 반대 방향도 본다.
docker exec -it dss-pg-app psql -U dss_app -d dss_meters
# 기대: FATAL: permission denied for database "dss_meters"
```

> ⛔ **중단 조건** — 위 두 명령 중 하나라도 접속에 성공하면 **이관을 진행하지 않는다.**
> 그 상태로 데이터를 넣으면 A/S 앱의 SQL 인젝션 하나가 계측기 데이터까지 읽는
> 통로가 된다. 원인을 찾아 고친 뒤 다시 검증한다.

### 비밀번호

`njlee/REQUIREMENTS.md`의 미정 항목 **T4**가 여기서 해소된다.

필요한 비밀번호는 **다섯 개**다 — 앱 롤 셋과, 상자를 세울 때 쓰는 부트스트랩
관리자 둘(인스턴스마다 하나). 관리자 계정은 **앱이 쓰지 않는다.** 초기화와
사람이 직접 손보는 일에만 쓴다.

**다섯이 모두 서로 달라야 한다** — 같은 값을 돌려쓰면 롤을 나눈 의미가 사라진다.
한쪽이 새면 나머지 DB에도 그대로 들어갈 수 있기 때문이다.
업무용 두 개가 같으면 초기화 스크립트가 거절하지만, 나머지는 사람이 챙겨야 한다.

```bash
node -e "console.log(require('crypto').randomBytes(24).toString('base64url'))"
```

---

## 7. 접근 경계 — 나스 안에서만

"통합 로그인으로 들어가는 모든 화면은 NAS의 Docker를 통해 사내에서만 열린다"는
원칙이 이 통합으로 흔들리는가. **흔들리지 않는다.** 다만 DB 쪽에서 지켜야 할
조건이 하나 있다.

### 왜 영향이 없는가 — 층이 다르다

브라우저가 만나는 것은 **앱 포트**(3000·3100·3300)이지 DB 포트가 아니다.
접근 경계는 리버스 프록시·방화벽·Docker 네트워크가 앱 앞에서 긋고, DB는 그 경계
*안쪽*에서 앱하고만 이야기한다. 오히려 **통합은 이 원칙에 유리하다** — 지켜야 할
DB 노출 지점이 셋에서 둘로 줄기 때문이다.

> ⚠️ **DB 쪽 조건 — 이것 하나만 지키면 된다**
> 개발용 compose는 전부 `ports: "127.0.0.1:54xx:5432"`로 DB를 호스트에 내놓는다.
> **NAS 운영 파일에는 `ports:`를 아예 쓰지 않는다.** 같은 Docker 네트워크에서
> `dss-pg-app:5432`처럼 서비스 이름으로 부르면 DB는 호스트 포트를 하나도 열지 않는다.

```yaml
services:
  db-app:
    image: postgres:17
    networks: [dss-internal]
    # ports: 를 쓰지 않는다. 개발 PC 파일에서 복사해 올 때 가장 흔한 실수다.

  app-as:
    networks: [dss-internal, dss-edge]   # 프록시가 닿는 망은 edge 하나뿐

networks:
  dss-internal:
    internal: true     # 이 망은 바깥으로 나가지도 들어오지도 못한다
  dss-edge:
```

### 원칙을 실제로 지탱하는 네 겹

| 겹 | 무엇을 막나 | 이 통합의 영향 |
|---|---|---|
| 공유기 포트포워딩 | 인터넷에서 NAS로 들어오는 길. 열지 않는다 | 무관 |
| DSM 방화벽 | 사내망에서도 앱 포트에 직접 붙는 것. 443만 연다 | 무관 |
| Docker 포트 노출 | 컨테이너가 호스트에 포트를 내놓는 것 | **지점 3 → 2** |
| DSM 리버스 프록시 | 유일한 입구 | 무관 |

### 진짜 위험은 DB가 아니라 앱 포트다

`dss-auth/.env.example:55`에 이미 경고가 있다 —
*"리버스 프록시를 세우면 `TRUSTED_PROXY_HOPS`를 1로 바꾸세요. 그리고 각 앱의 포트를
방화벽에서 막아야 합니다 — 프록시를 우회해 직접 들어오면 XFF를 통째로 위조할 수 있고,
그때는 이 설정이 오히려 위조된 값을 믿게 됩니다."*

즉 앱 포트를 막는 것은 접근 통제만의 문제가 아니라 **속도 제한이 성립하기 위한 전제**다.

### 정책이 시스템마다 다르다

| 시스템 | 문서에 적힌 접근 정책 | 출처 |
|---|---|---|
| A/S 관리 | 내부망 기본. **원격지는 회사 VPN을 통해서만** | `SECURITY_POLICY.md:56` |
| 계측기 관리 | 사내망 전용. **회사 밖 접속 없음** | `REQUIREMENTS.md:199` |
| 통합 로그인 | 명시 없음 — 둘의 관문이므로 더 느슨한 쪽을 따라야 한다 | — |

두 정책이 달라 보이지만 충돌하지 않는다. **VPN으로 들어오면 사내망 주소를 받는다** —
NAS 입장에서는 사무실 PC와 구분되지 않는다.

계측기 쪽이 *"VPN이어도 안 된다"*는 뜻이라면, 그 제한은 DB나 방화벽이 아니라
**계측기 앱 안에서** 걸어야 한다. 포털은 사람을 확인할 뿐 어디서 들어왔는지로
시스템을 가르지 않는다.

---

## 8. 자원 예산

RAM 6GB · 2코어 · HDD 기준. 기본값 그대로 두면 인스턴스 하나가 필요 이상으로 잡는다.

| 설정 | `dss-pg-app` | `dss-pg-auth` | 이유 |
|---|---|---|---|
| `shared_buffers` | 256MB | 128MB | 기본값 128MB. 업무 DB는 조회가 많아 올린다 |
| `effective_cache_size` | 768MB | 384MB | 플래너에게 알려 주는 값일 뿐 메모리를 잡지 않는다 |
| `work_mem` | 4MB | 4MB | 커넥션마다 잡히므로 올리지 않는다 |
| `max_connections` | 40 | 20 | 기본 100은 6GB에서 과하다 |
| `maintenance_work_mem` | 64MB | 64MB | 복원과 `VACUUM`이 빨라진다. 상시 점유가 아니다 |
| `random_page_cost` | 4.0 | 4.0 | HDD이므로 기본값이 맞다. SSD면 1.1 |

### 앱 쪽 커넥션 풀도 함께 낮춘다

네 저장소 모두 `postgres.js`를 `max: 10`으로 열고 있다
(`src/lib/db/connection.ts`, njlee는 `src/lib/db/index.ts`).
DS218+에서는 커넥션 하나하나가 백엔드 프로세스다.

| 앱 | 현재 | NAS 권장 | 붙는 인스턴스 |
|---|---|---|---|
| A/S 관리 | 10 | 5 | `dss-pg-app` |
| 계측기 관리 | 10 | 5 | `dss-pg-app` |
| 통합 로그인 | 10 | 5 | `dss-pg-auth` |

15명 규모에서 앱당 5개면 충분하고도 남는다. 부족해지면 그때 올린다.

### 컨테이너 메모리 상한

A/S의 엑셀 업로드 한도가 21MB다(`next.config.ts:87`). 큰 워크북을 파싱할 때 순간
메모리가 크게 튄다. NAS에서는 이 한 번이 다른 컨테이너를 밀어낼 수 있으므로,
**컨테이너마다 상한을 걸어 터지더라도 그 하나만 죽게 한다.**

```yaml
services:
  db-app:
    deploy:
      resources:
        limits:
          memory: 768M
```

---

## 9. 이관 절차

순서가 중요하다. 실제 중단은 Phase 3–5뿐이고 예상 30–60분이다.

### Phase 0 — 준비 · 중단 없음 · 1~2시간

새 구성을 만들되 아무것도 끄지 않는다.

- 비밀번호 다섯 개를 생성해 안전한 곳에 적어 둔다(6절). 상자를 만든 뒤에는
  파일만 고쳐서 바꿀 수 없으므로 **반드시 먼저** 정한다.
- `docker-compose.nas.yml`을 쓴다 — 인스턴스 둘, `postgres:17`, 볼륨은 **새 이름**으로.
- 초기화 SQL(`nas/init/`)이 컨테이너 기동 시 실행되도록 마운트한다.

### Phase 1 — 덤프 · 중단 없음 · 5~15분

```bash
# DB마다 하나씩. --clean --if-exists는 붙이지 않는다 —
# 비어 있는 새 DB에 넣을 것이므로 불필요하고, 실수 여지만 만든다.
docker exec dss-as-postgres-dev \
  pg_dump -U dss_app -d dss_as_dev -Fc > dss_as.dump

docker exec dss-meters-postgres-dev \
  pg_dump -U dss_meters_app -d dss_meters_dev -Fc > dss_meters.dump

docker exec dss-auth-postgres-dev \
  pg_dump -U dss_auth_app -d dss_auth_dev -Fc > dss_auth.dump
```

덤프 직후 **각 DB의 테이블별 행 수를 기록해 둔다.** Phase 4에서 대조한다.

```bash
docker exec dss-as-postgres-dev psql -U dss_app -d dss_as_dev -c \
  "SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY relname;" \
  > before-as.txt
```

> ⚠️ **위 A/S 명령은 4단계에서 쓰지 않는다 — 결정 D (2026-09-04).**
> A/S의 업무 자료는 전부 데모라 **가져가지 않는다.** 아래 「Phase 1-A」로 대신한다.
> **계측기와 인증은 위 그대로** 통째로 뜬다 — 그쪽은 실제 자료다.

#### Phase 1-A — A/S는 뼈대만 뜬다 (결정 D)

버릴 것이 58장, 가져갈 것이 20장이다. **제외 목록(`--exclude-table-data`)을 58줄 쓰는 대신
가져갈 20장을 `-t`로 적는다** — 짧고, 새 표가 생겨도 저절로 빠진다(안전한 쪽으로 틀린다).

```bash
docker exec dss-pg-app pg_dump -U dss_app -d dss_as -Fc --data-only \
  -t users \
  -t procedure_templates -t procedure_template_nodes -t procedure_template_edges \
  -t procedure_reference_items -t procedure_checklist_sections \
  -t procedure_checklist_items -t procedure_troubleshooting_entries \
  -t workflow_templates -t workflow_versions -t workflow_steps -t workflow_transitions \
  -t repair_task_catalog -t role_permissions -t customer_status_options \
  -t exception_statuses -t repair_labor_settings -t notification_role_settings \
  -t shipment_approval_delegations -t intake_mail_signature_images \
  > as-skeleton.dump
```

`--data-only`인 이유: NAS의 스키마는 `db:migrate`가 만든다. 이 덤프에 스키마가 들어 있으면
마이그레이션 journal과 두 주인이 생긴다. **확인함 — 이 덤프에 `drizzle` 항목은 0개다.**

**왜 이 20장인가** — 참조가 이 집합 안에서 닫히는 최소 단위다.

| | 무엇 | 행 |
|---|---|---|
| 절차 | 템플릿 6 · 노드 450 · 연결 565 · 참고자료 193 · 체크리스트 30 · 트러블슈팅 11 | 1,255 |
| 워크플로 | 템플릿 10 · 버전 19 · 단계 257 · 전이 389 | 675 |
| 목록·설정 | `repair_task_catalog` 36 · 권한 3 · 상태문구 7 · 예외 9 · 공임 3 · 알림 2 · 결재위임 1 · 메일서명 1 | 62 |
| 계정 | `users` | 14 |
| | | **2,006** |

**`users`는 고르는 것이 아니라 딸려 오는 것이다.** 절차·워크플로·작업목록·설정이 전부
"누가 만들었나"로 `users`를 참조한다. 빼면 뼈대가 통째로 안 들어간다.
데모 계정이 섞여 있으면 **NAS에 올린 뒤 지운다** — 자료가 아니라 계정이라 지우기 쉽다.

**함께 버려지는 것 둘** (참조가 밖을 향해 못 가져온다)

| | 왜 |
|---|---|
| OH 부품 템플릿 44행 | `oh_part_template_items → parts`, `oh_part_template_models → product_models`. 부품과 제품모델이 데모라 함께 간다 |
| `weekly_report_goals` 6행 | `→ repair_cases`. 접수를 버리므로 이것도 못 남는다 |

**인수번호는 1번부터 다시 시작한다.** `repair_case_intake_sequences`를 안 가져가기 때문이고,
데모를 버리는 것이 목적이므로 **의도한 결과다.** (자료를 이관하는 경우였다면 이 4행을
빠뜨리는 것이 가장 비싼 실수였다 — 번호가 겹친다.)

#### 개발 PC에서 실제로 해 본 결과 (2026-09-04)

위 명령을 그대로 돌리고, 빈 DB에 스키마를 넣은 뒤 복원까지 마쳤다.

| 확인 | 결과 |
|---|---|
| 덤프 | 163KB · `TABLE DATA` **정확히 20개** · 전부 `public`/`dss_app` · `drizzle` 0개 |
| 복원 | `pg_restore --data-only` **오류 0** |
| 행 수 | 20장 **전부 일치 · 합계 2,006행** |
| 업무 표 | `repair_cases`·`customers`·`products`·`quotes`·`attachments`·`stock_transactions` 모두 **0행** |

> **`pg_dump`가 경고를 하나 낸다** — `users`·`procedure_templates`·`procedure_template_edges`에
> 자기참조 FK가 있어 *"`--disable-triggers` 없이는 복원이 안 될 수 있다"*고 한다.
> **실제로는 없이도 됐다.** 다만 이건 행이 담긴 물리적 순서에 기대는 것이라 보장이 아니다.
> 복원이 FK 오류로 멈추면 부트스트랩 관리자(`dss_admin`)로 `--disable-triggers`를 붙인다.

### Phase 2 — 기동 · 중단 없음 · 10분

- 새 컨테이너를 **옛 것과 다른 포트**로 먼저 띄운다(예: 5442·5444).
  겹치지 않아야 되돌리기가 쉽다.
- 초기화 SQL이 돌았는지 확인한다.
- **6절의 격리 검증을 여기서 돌린다.** 데이터를 넣기 전에 확인해야 한다.

### Phase 3 — 복원 · **중단 시작** · 10~30분

여기서부터 앱을 멈춘다. 멈추지 않으면 덤프 이후에 들어온 데이터가 사라진다.

```bash
cat dss_as.dump | docker exec -i dss-pg-app \
  pg_restore -U dss_app -d dss_as --no-owner --role=dss_app

cat dss_meters.dump | docker exec -i dss-pg-app \
  pg_restore -U dss_meters_app -d dss_meters --no-owner --role=dss_meters_app

cat dss_auth.dump | docker exec -i dss-pg-auth \
  pg_restore -U dss_auth_app -d dss_auth --no-owner --role=dss_auth_app
```

`--no-owner`를 쓰는 이유: 덤프에 적힌 소유자 이름이 새 인스턴스의 롤과 다를 수 있고,
그때 `pg_restore`가 경고를 쏟아낸다. `--role`로 명시하는 편이 조용하고 확실하다.

### Phase 4 — 검증 · 중단 계속 · 15분

- **행 수 대조** — `before-*.txt`와 같은 쿼리를 새 DB에서 돌려 비교한다.
  `ANALYZE`를 먼저 돌려야 `n_live_tup`이 정확해진다.
  > ⚠️ **A/S는 일치하면 안 된다 (결정 D).** 뼈대 20장만 옮기므로 나머지 58장은 **0이어야 정상**이다.
  > A/S의 합격 기준은 "원본과 같다"가 아니라 아래 둘이다.
  > - 뼈대 **20장이 정확히 일치**한다 (Phase 1-A 표의 2,006행 — 뜬 시점 기준)
  > - `repair_cases`·`customers`·`products`·`quotes`·`attachments`·`stock_transactions`가 **모두 0**이다
  >
  > 계측기와 인증은 종전대로 **전부 일치**해야 한다.
- **시퀀스** — 인수번호처럼 순번이 의미를 갖는 곳은 눈으로 확인한다
  (A/S 인수번호 규칙 `D+YYMM+순번`).
  > **A/S 인수번호는 1번부터 시작하는 것이 정상이다 (결정 D).** 데모를 버렸기 때문이다.
  > 첫 접수를 하나 넣어 `D<YYMM>01`이 나오는지만 본다. 계측기·인증은 종전대로 이어져야 한다.
- **정렬** — 계측기 목록을 한글 이름순으로 정렬해 본다. ICU 로케일 확인의 가장 빠른 방법.
- **격리 재확인** — 6절의 두 명령을 다시 돌린다. 복원 과정에서 권한이 바뀌었을 수 있다.

### Phase 5 — 전환 · **중단 끝** · 10분

각 저장소 운영 env의 `DATABASE_URL`만 바꾼다. **코드는 한 줄도 고치지 않는다.**

```
# A/S
DATABASE_URL=postgresql://dss_app:***@dss-pg-app:5432/dss_as
# 계측기
DATABASE_URL=postgres://dss_meters_app:***@dss-pg-app:5432/dss_meters
# 통합 로그인
DATABASE_URL=postgresql://dss_auth_app:***@dss-pg-auth:5432/dss_auth
```

앱을 차례로 올리고 로그인 왕복을 확인한다 — `dss-auth`의 `npm run check:oidc`가
정상 왕복 한 번과 공격 시나리오 다섯 가지를 자동으로 돌린다.

### Phase 6 — 정지 · 중단 없음 · 5분

옛 컨테이너를 멈춘다. **지우지 않는다.**

```bash
docker stop dss-as-postgres-dev dss-meters-postgres-dev dss-auth-postgres-dev
# docker rm 도, docker volume rm 도 하지 않는다.
```

볼륨이 남아 있는 한 되돌리기는 `docker start` 한 번이다.

### Phase 7 — 회수 · **착수 2주 후**

- 2주 동안 문제없이 돌았는지 확인한다. 월말 마감처럼 **드물게 도는 작업**이
  한 번은 지나가야 한다.
- 정리 전에 NAS 백업 폴더에 마지막 덤프를 남긴다.
- 그 뒤 `docker rm` · `docker volume rm`으로 회수한다.

---

### 9절 부록 — 개발 PC 리허설 기록 (2026-09-03)

**2단계 완료.** Phase 0~6을 개발 PC에서 이 절 그대로 밟았고, 검증이 전부 통과했다.
Phase 3~5(앱 중단)는 **약 7분**이었다. 자료가 작아서(A/S 21MB · 계측기 9MB · 인증 9MB)
복원이 초 단위로 끝났다. NAS에서는 HDD라 더 걸리겠지만 자릿수가 바뀌지는 않는다.

| Phase | 한 일 | 결과 |
|---|---|---|
| 0 | [`nas/docker-compose.rehearsal.yml`](../nas/docker-compose.rehearsal.yml) 작성. NAS 파일의 DB 둘을 `extends`로 끌어오고 포트만 5442·5444로 연다 | NAS 파일은 한 줄도 안 바꿨다 |
| 1 | 옛 컨테이너 셋에서 `pg_dump -Fc` 넷(`dss_as_test` 포함) + 테이블별 **정확한 행 수**·시퀀스 값 스냅숏 | `rehearsal/` (git 제외) |
| 2 | `postgres:17` 인스턴스 둘 기동. 초기화 스크립트가 롤·DB·`CONNECT` 분리까지 돌았다 | 6절 격리 검증 **소켓·TCP 양쪽 모두 거절** |
| 3 | 앱 셋(3000·3100·3300) 정지 → `pg_restore --no-owner --role=<앱 롤>` 넷 | **오류 0 · 경고 0** |
| 4 | 행 수·시퀀스 넷 모두 일치. 인덱스·제약·enum 수 일치. 격리 재확인. 인수번호 카운터(2609→1)와 최대 인수번호(D260901) 이어짐 | 통과 |
| 5 | 세 저장소 `.env.local`의 `DATABASE_URL`만 교체(A/S는 `.env.test.local`도). 앱 셋 재기동 | `db:preflight` 80/0 · 마이그레이션 3/3·5/5 · **`check:oidc` 26/26** · 인증 백업 정상 |
| 6 | 옛 컨테이너 셋 `docker stop`. 볼륨 여섯 보존 | 되돌리기는 `docker start` 한 번 |
| 7 | **2026-09-17 이후** 옛 볼륨 회수 | ⬜ |

#### 이 절과 달랐던 것 — 다음에 이 절을 따를 사람이 알아야 한다

1. **Phase 1 덤프와 Phase 3 사이에 들어온 자료는 사라진다.** 이 절은 덤프를
   "중단 없음"에 두고 그 뒤에 앱을 멈추는데, 그 사이의 쓰기는 새 DB에 없다.
   리허설에서는 아무도 쓰지 않아 문제가 없었지만 **운영(4단계)에서는 앱을 멈춘 뒤
   최종 덤프를 다시 떠야 한다.** Phase 1 덤프는 복원 연습용, Phase 3 첫 줄이 진짜 덤프다.
2. **`-f` 둘로 덧씌우면 `config`가 실패한다.** compose는 고르지 않은 앱 서비스의
   `env_file`(`env/*.env`)까지 읽고, 그 파일이 없으면 멈춘다. 그래서 리허설 파일은
   `extends`로 DB 둘만 가져온다. 설정은 여전히 NAS 파일 한 곳에만 있다.
3. **Git Bash는 `/tmp/…`를 Windows 경로로 바꿔 넘긴다.** `docker exec … -f /tmp/x.dump`가
   "could not open output file C:/Users/…/Temp/x.dump"로 죽는다. `MSYS_NO_PATHCONV=1`을 앞에 둔다.
4. **행 수 대조는 `n_live_tup`이 아니라 `count(*)`로 한다.** 통계값은 `ANALYZE` 뒤에도
   추정치라 같은 자료에서 다르게 나올 수 있다. 정확한 값을 한 줄로 뽑는 쿼리:
   ```sql
   SELECT table_schema||'.'||table_name||' = '||(xpath('/row/c/text()',
     query_to_xml(format('select count(*) as c from %I.%I', table_schema, table_name),
     false, true, '')))[1]::text
   FROM information_schema.tables
   WHERE table_schema IN ('public','drizzle') AND table_type='BASE TABLE' ORDER BY 1;
   ```
5. **`ANALYZE`를 앱 롤로 돌리면 카탈로그 경고 11줄이 나온다** (`pg_authid` 등
   permission denied). 앱 롤이 슈퍼유저가 아니라서 생기는 것이고 무해하다. 옛 개발
   DB에서는 앱 롤이 곧 슈퍼유저였기 때문에 이 경고를 본 적이 없었을 뿐이다.
6. **정렬이 바뀐다.** 새 DB(ICU `ko-KR`)는 `123 < ㄱ < 가나 < 나비 < 다람쥐 < 한자漢 < apple < B < Zebra`,
   옛 DB 셋은 코드포인트 순 `123 < B < Zebra < apple < ㄱ < 가나 …`였다(alpine의
   `ko_KR.UTF-8`은 musl이라 실제로는 정렬을 안 했다). **한글이 영문 앞에 오고 대소문자를
   구분하지 않는다.** 이름순 목록의 모양이 달라지는데, 이것이 ICU를 고른 이유이므로 의도한 변화다.
7. **`dss_as_test`는 개발 PC 전용이다.** A/S 테스트가 같은 인스턴스의 `_test` DB를 요구해서
   리허설에서 손으로 만들었다(같은 로케일, `dss_app` 소유, `CONNECT` 분리). 초기화
   스크립트에는 없고 **NAS에는 만들지 않는다.**
8. **개발 PC의 시작·종료 스크립트 여섯을 새 구조로 다시 썼다** (2026-09-03, Phase 7에서 앞당김).
   처음에는 A/S `end-work.ps1`의 **일일 백업이 옛 DB를 뜨는 것**만 고치고 나머지는
   Phase 7로 미뤘다. 미룰 수 없었던 것은 **끄는 대상**이다 — 옛 상자를 끄는 동안
   새 인스턴스 둘은 아무도 끄지 않아 계속 떠 있고, 그렇다고 끄는 대상만 새 것으로
   바꾸면 A/S 종료가 계측기 DB를 함께 죽인다. 어느 쪽도 한 줄로 고쳐지지 않아
   **공용이라는 사실 자체를 스크립트에 넣었다.**

   | | 어떻게 |
   |---|---|
   | 켜기 | 저장소의 `db:up`(옛 상자)을 부르지 않고, `nas/docker-compose.rehearsal.yml`로 만든 컨테이너를 `docker start` |
   | 만들기 | 없을 때만 그 compose로. `.env.nas`가 없으면 빈 비밀번호로 만들어져 재시작 루프에 빠지므로, 먼저 막고 어디를 채우라고 알린다 |
   | 끄기 | **상대 서버 포트가 아직 떠 있으면 끄지 않는다.** A/S는 3300을, 계측기는 3000을 본다 — 마지막에 나가는 쪽이 끈다 |
   | 경합 | `start-all.ps1`이 컨테이너 둘을 **먼저 한 번** 켠다. A/S 창과 계측기 창이 몇 초 차이로 같은 것을 만들려 들면 하나가 "이미 있다"며 죽기 때문이다 |

   여섯 중 넷(`start-work`·`end-work`·`start-sso-work`·`end-sso-work`)은 각 저장소 안에 있고,
   둘(`start-meters-work`·`end-meters-work`)과 `start-all`·`end-all`은 아직 `Development/`에
   git 밖으로 떠 있다(`scripts/README.md`). **`dss-home`은 그대로다** — 그 DB(5436)는
   통합 대상이 아니다. 옛 상자 셋은 정지된 채 남고 이 스크립트들은 더 건드리지 않는다.
9. **`dss-auth` 백업의 docker 모드 기본값이 옛 컨테이너다** (`dss-auth-postgres-dev` / `dss_auth_dev`).
   `.env.local`에 `BACKUP_DB_CONTAINER=dss-pg-auth`·`BACKUP_DB_NAME=dss_auth`를 넣었다.
   NAS에서는 `BACKUP_MODE=direct`라 무관하다.
10. **계측기 백업은 이 PC에서 원래 돌지 않는다.** `PG_BIN`이 이남준 님 PC 경로이고 백업
    폴더가 네트워크 공유다. 리허설과 무관한 기존 조건이라 손대지 않았다.
11. **격리 검증은 TCP로도 한다.** 6절의 두 명령은 소켓(trust)이라 비밀번호를 안 거친다.
    앱이 실제로 오는 길로 한 번 더 확인한다:
    ```bash
    docker exec -e PGPASSWORD="$METERS_APP_PASSWORD" dss-pg-app \
      psql -h 127.0.0.1 -U dss_meters_app -d dss_as -c 'select 1'   # FATAL 이어야 한다
    ```
12. PostgreSQL 17은 `pg_database.daticulocale`이 **`datlocale`**로 이름이 바뀌었다.
    로케일 확인 쿼리를 16 기준으로 쓰면 열이 없다고 나온다.

#### 지금 되돌리려면 (Phase 7 전까지)

```bash
# 1. env 원본을 되돌린다 — rehearsal/env-backup/ 에 넷이 있다
# 2. 옛 컨테이너를 켠다
docker start dss-as-postgres-dev dss-meters-postgres-dev dss-auth-postgres-dev
# 3. 앱 셋을 다시 띄운다. 전환 뒤 들어온 자료는 새 인스턴스에만 있다.
```

---

## 10. 되돌리기

| 시점 | 되돌리는 법 | 잃는 것 |
|---|---|---|
| Phase 4 검증 실패 | 새 컨테이너를 끄고 앱을 그대로 다시 켠다. `DATABASE_URL`을 아직 안 바꿨으므로 할 일이 없다 | 없음 |
| Phase 5 직후 | `DATABASE_URL`을 옛 값으로 되돌리고 옛 컨테이너를 `docker start` | 전환 후 들어온 데이터 |
| 며칠 지난 뒤 | 새 인스턴스에서 덤프를 떠 옛 인스턴스에 복원한 뒤 되돌린다 | 다시 한 번의 중단(30분) |

> **되돌리기를 지키는 규칙 하나** — Phase 7 이전에는 옛 볼륨을 절대 지우지 않는다.
> 디스크가 아깝게 느껴져도 2주는 둔다. 통합 작업에서 가장 비싼 실수는
> "잘 되는 것 같아서" 일찍 지우는 것이다.

---

## 11. 함께 고쳐야 할 것

| 위치 | 지금 | 필요한 조치 | 난이도 |
|---|---|---|---|
| `dss-auth/scripts/backup.ts:57` | `docker exec <컨테이너> pg_dump`를 부른다 | **컨테이너 안에서 돌지 않는다.** `njlee` 방식(TCP + `PGPASSWORD`)으로 바꾼다 | 필수 |
| `RF_Service_System/HANDOFF.md` | 운영 준비 17번이 "staging 구성"을 미완료 과제로 남겨 둔다 | 결정 B에 따라 "staging 대신 배포 리허설"로 갱신 | ✅ 완료 |
| 각 앱 이미지 | `pg_dump`가 없다 | `postgresql-client-17`을 설치한다. 서버가 17이므로 클라이언트도 17이어야 한다 | 별건(3단계) |
| `njlee/scripts/backup.ts` | — | **고칠 것 없다.** 128행 주석대로 이미 컨테이너를 염두에 두고 쓰였다 | — |
| `njlee/docker-compose.yml` | `LANG: ko_KR.UTF-8` on alpine | 운영은 Debian 이미지 + ICU로 대체. 개발용은 그대로 둬도 된다 | 선택 |
| `RF_Service_System/next.config.ts` | `output: "standalone"`이 없다 | 이 문서 범위 밖이지만 **같은 NAS 배포에서 반드시 필요하다.** 나머지 셋은 이미 있다 | 별건 |
| 네 저장소 전부 | `Dockerfile`이 하나도 없다 | `njlee/DESIGN.md:331`에 계획만 있고 실물이 없다 | 별건 |

> ⛔ **`docker exec`를 컨테이너 안에서 쓰려고 소켓을 물리지 않는다.**
> `dss-auth`의 백업을 그대로 두고 돌게 만드는 가장 빠른 길은 앱 컨테이너에
> `/var/run/docker.sock`을 마운트하는 것이다. **하지 말아야 한다.**
> Docker 소켓 접근은 사실상 호스트 root 권한이다 — 그 소켓으로 특권 컨테이너를
> 띄우면 NAS 전체를 가져갈 수 있다.
>
> 하필 그것을 **인증 컨테이너**에 주는 것은, 인증 DB를 따로 격리한 이 계획의
> 이유를 정면으로 무너뜨린다. DB를 갈라 놓고 앱에 호스트 root를 쥐여 주면
> 3절에서 그은 경계는 아무 의미가 없다.

`Dockerfile`과 `standalone`은 DB 통합과 별개의 작업이지만
**NAS 이전이라는 같은 관문에 함께 걸려 있다.** 통합만 끝내고 배포를 시작하면
거기서 다시 막힌다.

---

## 12. 잃는 것

얻는 것만 적은 계획서는 검토할 수가 없다.

> **사라지는 보장** — "계측기 DB가 죽어도 A/S는 산다"가 더는 참이 아니다.
> `dss-pg-app` 인스턴스가 멈추면 두 시스템이 함께 멈춘다.

- **재시작·업그레이드가 함께 걸린다.** PostgreSQL 마이너 버전을 올리려면 A/S와
  계측기가 동시에 내려간다.
- **한쪽의 부하가 다른 쪽에 번진다.** 계측기 엑셀 이관 같은 무거운 작업이 같은
  인스턴스의 버퍼와 I/O를 쓴다.
- **복원 단위가 커진다.** DB 단위 복원은 여전히 가능하지만 절차가 한 단계 는다.

### 그래도 지켜지는 것

- 인증 DB는 별도 인스턴스로 **완전히 격리된다.**
- DB·롤·`CONNECT` 권한 분리로 **A/S 앱은 계측기 데이터를 읽을 수 없다.**
  인스턴스를 나눴을 때와 같은 보장이다.
- 앱 프로세스 넷은 그대로다. 배포 독립성과 시스템별 역할 소유권은 손대지 않는다.

### 판단

15명이 쓰는 사내 시스템에서, DS218+ 한 대에 어차피 다 올라가는 이상
**"인스턴스가 따로면 따로 죽는다"는 보장은 실질적 가치가 크지 않다.**
NAS 자체가 이미 공통 단일 실패점이기 때문이다. 반면 fsync 경합 감소와
백업·버전 관리 단순화는 매일 값을 한다.

---

## 13. 체크리스트

### 착수 전

- [x] 결정 A — `dss_home`은 바깥 호스팅으로 확정
- [x] 결정 B — staging은 NAS에 두지 않는 것으로 확정
- [ ] NAS RAM 6GB 장착 및 DSM 정보 센터에서 인식 확인
- [x] 비밀번호 5개 생성(앱 롤 3 + 부트스트랩 관리자 2), 모두 서로 다른 값인지 확인 — 2026-09-02
- [ ] `njlee/scripts/backup.ts`를 `docker exec` 방식으로 수정
- [ ] `RF_Service_System/HANDOFF.md` 17번 갱신
- [ ] `dss-home/README.md:48`에 *앱만*이라는 단서 추가
- [ ] Phase 1 덤프 3개 + 행 수 스냅숏 `before-*.txt` 확보
- [ ] 덤프 파일을 NAS 백업 폴더에 별도 사본으로 보관

### 완료 후

- [ ] 격리 검증 2건이 **모두 거절**되는지 확인 (6절)
- [ ] NAS compose에 DB `ports:`가 **하나도 없는지** 확인 (7절)
- [ ] `docker port dss-pg-app`이 아무것도 출력하지 않음
- [ ] 사내 PC에서 `nas:3100` 직접 접속이 **막히는지** 확인
- [ ] 테이블별 행 수가 이관 전과 일치
- [ ] 계측기 목록 한글 정렬이 가나다 순으로 나옴
- [ ] A/S 인수번호 시퀀스가 이어서 발번됨
- [ ] `npm run check:oidc` 전 항목 통과
- [ ] 세 시스템 로그인 왕복 + 백채널 로그아웃 확인
- [ ] 각 시스템 백업 스크립트가 새 컨테이너를 상대로 정상 동작
- [ ] 옛 컨테이너 정지, **볼륨은 보존**
- [ ] D+14 이후 옛 볼륨 회수

---

## 요약

통합 자체의 메모리 이득은 NAS에서 약 150MB로 크지 않다. 이 작업의 실익은
HDD fsync 경로를 셋에서 둘로 줄이는 것, 백업·복구 대상을 단순화하는 것,
그리고 무엇보다 **16과 17로 갈린 버전을 17로 통일해 백업 복구가 항상 되게 만드는 것**이다.
마지막 항목은 통합을 하지 않더라도 NAS 이전 전에 반드시 해야 한다.

**근거 파일** — `*/docker-compose.yml` · `*/drizzle.config.ts` ·
`*/src/lib/db/connection.ts` · `dss-auth/src/lib/db/schema/{users,clients}.ts` ·
`njlee/REQUIREMENTS.md` · `RF_Service_System/HANDOFF.md` · `RF_Service_System/SECURITY_POLICY.md`
