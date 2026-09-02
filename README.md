# NAS 이식 — 전체 지도

사내 시스템 넷을 개발 PC에서 **Synology DS218+ NAS의 Docker**로 옮긴다.
이 파일이 전체 순서와 **지금 어디까지 왔는지**를 갖는다. 세션을 이어받으면 여기부터 읽는다.

시스템 경로·포트·확정된 결정은 [CLAUDE.md](./CLAUDE.md)에 있다.

---

## 지금 어디까지 됐나

**0단계 완료** — Postgres 통합 계획 확정 (2026-09-02). 결정 A·B 닫힘.

**1단계 진행 중** (2026-09-02)
- ✅ 4번 — `RF_Service_System/HANDOFF.md` 17번을 "staging 대신 배포 리허설"로 갱신
- ✅ 5번 — `dss-home/README.md`에 "NAS로 옮기는 것은 앱이지 DB가 아니다" 단서 추가
- ✅ 3번 — `dss-auth/scripts/backup.ts`에 `BACKUP_MODE` 추가 (`docker` 기본 · `direct` 신규).
  개발 PC 동작은 그대로, NAS용 길이 새로 생겼다. `docker` 모드 실동작 확인함
- ✅ 2번 — 비밀번호 5개 생성, `nas/.env.nas` 작성 완료. 다섯 값이 모두 다르고
  32자이며 URL에 안전한 문자만 쓴 것, git에 노출되지 않는 것까지 확인했다
  (값은 확인 과정에서도 출력하지 않았다)
- ⬜ 1번 — **NAS RAM 6GB 장착.** 남은 하나이자 2단계 이후의 선행 조건

**3단계 완료** (2026-09-02) — RAM과 무관하게 먼저 진행했다
- ✅ `RF_Service_System`에 `output: "standalone"` 추가
- ✅ `njlee/.dockerignore` 작성 (계측기는 SMTP 비밀번호를 다뤄 그물이 먼저 필요했다)
- ✅ `Dockerfile` 3개 — 멀티스테이지, `postgresql-client-17`, `node` 사용자로 실행
- ✅ 세 이미지 빌드 · **셋 다 `pg_dump 17.11`**
- ✅ `docker save` → `docker load` 왕복 — **이미지를 지웠다가 되살려** 확인.
  **옮길 파일은 셋 합쳐 324MB**다(`docker images`의 490MB는 압축 풀린 크기)
- ✅ [`nas/docker-compose.nas.yml`](./nas/docker-compose.nas.yml) 초안 —
  문법 검사 통과, **호스트 노출 포트 0개**를 기계적으로 확인
- ⚠️ **4단계로 넘긴 것** — 이미지 안에서 `npm run backup`·`db:migrate`가 안 돈다
  (`tsx`·`drizzle-kit`이 devDependency). 길 셋:
  [`runbook/02-이미지-빌드.md`](./runbook/02-이미지-빌드.md) 8절

**다음 세션 첫 작업** — RAM 장착이 끝나 있으면 **2단계**(개발 PC에서 DB 통합 리허설).
아직이면 **3단계의 `Dockerfile`**을 먼저 시작한다. RAM과 무관하게 진행할 수 있고,
`postgresql-client-17`을 넣어야 `BACKUP_MODE=direct`가 실제로 도는지 **처음으로**
확인할 수 있다(지금은 개발 PC에 클라이언트가 없어 경로 구성까지만 확인된 상태다).

`.env.nas`는 NAS로 옮길 때까지 개발 PC의 `dss-deploy/nas/`에 있다. 4단계에서
NAS로 가져간 뒤에는 **개발 PC 쪽 사본을 지운다** — 실제로 쓰이는 곳은 한 군데면 된다.

RAM 6GB 장착이 2단계 이후 전부의 선행 조건이다.

---

## 단계

| | 단계 | 무엇을 하나 | 상태 |
|---|---|---|---|
| 0 | 계획 | Postgres 인스턴스를 둘로 줄이는 계획. 결정 A·B 확정 | ✅ |
| 1 | 준비 | RAM 6GB, 비밀번호 5개, `dss-auth` 백업 모드 | ⬜ |
| 2 | 리허설 | **개발 PC에서 먼저** DB를 둘로 통합해 형태를 검증 | ⬜ |
| 3 | 이미지 | `Dockerfile` 3개, A/S에 `output: "standalone"`, 이미지에 `postgresql-client-17` | ✅ |
| 4 | DB 이전 | NAS에 인스턴스 둘 세우고 데이터 이관 | ⬜ |
| 5 | 앱 이전 | NAS에 앱 컨테이너 올리고 `DATABASE_URL` 전환 | ⬜ |
| 6 | 접근 경계 | 리버스 프록시·방화벽·HTTPS·`TRUSTED_PROXY_HOPS=1`·**VPN** | ⬜ |
| 7 | 주소 갱신 | 포털에 각 시스템 주소 재등록, 백채널 로그아웃 확인 | ⬜ |
| 8 | 정리 | 백업 스케줄, 옛 볼륨 회수, 문서 갱신 | ⬜ |

### 왜 2단계(리허설)를 먼저 두는가

개발 PC와 NAS의 **형태가 다르면 NAS에서만 나오는 버그가 생긴다.** 개발 PC에서 먼저
같은 구조(인스턴스 둘, PostgreSQL 17, 롤·`CONNECT` 분리)로 만들어 보면, 4단계에서
NAS는 이미 검증된 형태를 그대로 세우기만 하면 된다.

같은 이유로 결정 B에서 상시 staging 대신 **배포 리허설**을 택했다. 처음 해 보는 일을
운영 장비에서 처음 하지 않는다.

---

## 문서

| 문서 | 내용 |
|---|---|
| [CLAUDE.md](./CLAUDE.md) | 저장소 넷의 경로·포트, 확정된 결정, 지켜야 할 것 |
| [runbook/01-postgres-통합.md](./runbook/01-postgres-통합.md) | 0·2·4단계 — 인스턴스 둘로 줄이기, 권한 설계, Phase 0–7 절차 |
| [runbook/02-이미지-빌드.md](./runbook/02-이미지-빌드.md) | 3단계 — 빌드와 실행의 차이, 이미지를 NAS로 옮기는 법 |
| [nas/init/app/01-roles.sh](./nas/init/app/01-roles.sh) | 업무용 인스턴스의 롤·DB·권한 |
| [nas/init/auth/01-roles.sh](./nas/init/auth/01-roles.sh) | 인증용 인스턴스의 롤·DB·권한 |
| [nas/docker-compose.nas.yml](./nas/docker-compose.nas.yml) | **운영 구성 초안** — DB 둘·앱 셋, 포트를 열지 않는다 |
| [nas/.env.nas.example](./nas/.env.nas.example) | 두 인스턴스가 읽는 비밀번호 자리 |
| [nas/env/README.md](./nas/env/README.md) | 앱마다의 설정 파일을 만드는 법과 NAS에서 달라지는 값 |
| [scripts/README.md](./scripts/README.md) | 공용 실행 스크립트를 아직 옮기지 않은 이유 |

앞으로 늘어날 것: `03-리버스-프록시.md`(VPN 포함), `04-배포-리허설.md`

---

## 1단계 — 지금 할 일

| | 할 일 | 어디서 |
|---|---|---|
| 1 | NAS RAM 6GB 장착, DSM 정보 센터에서 인식 확인 | NAS |
| 2 | 비밀번호 **5개** 생성 (**모두 서로 다른 값**) | 아무 데서나 |
| 3 | `dss-auth/scripts/backup.ts`를 TCP 접속 방식으로 수정 | `dss-auth` |
| 4 | ~~`RF_Service_System/HANDOFF.md` 17번 갱신~~ ✅ 완료 | `RF_Service_System` |
| 5 | ~~`dss-home/README.md:48`에 *앱만* 단서 추가~~ ✅ 완료 | `dss-home` |

### 3번 — 처음 파악이 반대였다 (2026-09-02 정정)

계획서 초안은 "`njlee`의 백업이 NAS에서 안 돈다"고 적었지만, 실제로 읽어 보니
**반대였다.**

| | 지금 방식 | NAS에서 |
|---|---|---|
| `njlee/scripts/backup.ts` | `DATABASE_URL`로 TCP 접속 · 비밀번호는 `PGPASSWORD` | **이미 준비돼 있다** |
| `dss-auth/scripts/backup.ts` | `docker exec <컨테이너> pg_dump` | **돌지 않는다** |

`njlee`는 128행에 *"PG_BIN이 비어 있으면 PATH에서 찾는다 (NAS 컨테이너에서는
그쪽이 맞다)"*고 적혀 있다. 처음부터 컨테이너를 염두에 두고 쓴 코드다.
남은 것은 코드가 아니라 **이미지에 `postgresql-client-17`을 넣는 일**(3단계)뿐이다.

문제는 `dss-auth`다. `docker exec`를 부르므로 컨테이너 안에서는 돌지 않는다.
**돌게 만들려면 Docker 소켓을 앱 컨테이너에 물려야 하는데, 소켓 접근은 사실상
호스트 root 권한이다.** 하필 인증 컨테이너에 그걸 주는 것은 이 프로젝트가
인증 DB를 따로 격리한 이유를 정면으로 무너뜨린다.

→ **`dss-auth`를 `njlee` 방식(TCP + `PGPASSWORD`)으로 바꾼다.** 개발 PC에서
`docker exec`를 쓰던 이점(호스트에 클라이언트가 없어도 됨)은 모드 선택으로 남긴다.

비밀번호는 **셋이 아니라 다섯**이다. 앱 롤 셋(`AS_APP_PASSWORD`·`METERS_APP_PASSWORD`·
`AUTH_APP_PASSWORD`)에 더해, 상자를 세울 때 쓰는 부트스트랩 관리자 둘
(`APP_POSTGRES_PASSWORD`·`AUTH_POSTGRES_PASSWORD`)이 필요하다.
빈칸은 [`nas/.env.nas.example`](./nas/.env.nas.example)에 전부 있다.

아래 명령을 다섯 번 실행한다.

```
node -e "console.log(require('crypto').randomBytes(24).toString('base64url'))"
```

`base64url`인 이유: 이 값이 `DATABASE_URL` 안에 들어가는데, `@`·`:`·`/`가 섞이면
주소가 엉뚱하게 쪼개진다.

⚠️ **비밀번호는 상자를 처음 만들 때 굳는다.** 나중에 `.env.nas`만 고쳐도 이미
만들어진 롤은 바뀌지 않는다(초기화 스크립트가 빈 데이터 폴더에서만 돈다).
그래서 이 항목이 4단계보다 앞에 있다.

---

## 6단계에서 정할 것 — VPN 원격 접속 (2026-09-02 방향 확정)

**회사 밖에서 VPN을 통해 사내 시스템을 쓰기로 한다.** 인터넷에 앱을 직접 열지 않는다.

이 방향이 정해져 있으면 6단계 설계가 단순해진다 — VPN 사용자도 **사내 주소를 받으므로**
포털에 등록할 주소가 늘지 않고, 앱 설정을 하나도 바꾸지 않아도 된다.
`RF_Service_System/SECURITY_POLICY.md`에 원래 그렇게 적혀 있던 것이기도 하다.

착수 전 알아 둘 것:

| | 확인할 것 | 왜 |
|---|---|---|
| 1 | 공유기가 WireGuard·OpenVPN을 지원하는가 | 지원하면 NAS 부담 없이 가장 깔끔하다 |
| 2 | 회사 인터넷의 **업로드** 속도 | 밖에서의 체감을 좌우한다. CPU가 아니라 여기가 병목 |
| 3 | 밖에서 쓸 사람이 몇 명인가 | 메시 VPN은 무료 범위가 인원으로 갈린다 |
| 4 | **계측기도 밖에서 쓸 것인가** | 아래 문서 충돌을 정리해야 한다 |

> ⚠️ **문서 둘이 어긋나 있다.** `SECURITY_POLICY.md`는 "원격지는 VPN으로만"이라 하고,
> `njlee/REQUIREMENTS.md:199`는 "회사 밖 접속 없음 · 사내망 전용"이라 한다.
> 통합 로그인 하나로 둘 다 들어가므로 정리해야 한다.
> **"VPN으로 들어온 사람도 사내에 있는 것으로 본다"**로 정하면 두 문서가 하나가 된다.

⛔ PPTP는 쓰지 않는다. 설정이 가장 쉽지만 암호가 이미 깨진 방식이다.

---

## 나중에 반드시 확인할 것

**주소가 바뀌면 고칠 곳이 시스템마다 네 군데다.** NAS로 옮기면 IP와 포트가 전부
바뀌므로 7단계에서 한 번에 몰린다. 하나라도 빠지면 로그인이 막힌다
(`njlee/README.md`의 "주소가 바뀌었을 때" 표 참고).

- 각 시스템 `.env.local`의 `SSO_ISSUER`
- 각 시스템 `.env.local`의 `SSO_REDIRECT_URI`
- 포털에 등록된 `--redirect-uri`
- 포털에 등록된 `--backchannel-logout-uri`

포털은 이 주소를 **글자 단위로 정확히** 대조한다. 와일드카드도 정규화도 하지 않는다
(`dss-auth/src/lib/db/schema/clients.ts:32`에 그 이유가 있다).
