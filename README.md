# NAS 이식 — 전체 지도

사내 시스템 넷을 개발 PC에서 **Synology DS218+ NAS의 Docker**로 옮긴다.
이 파일이 전체 순서와 **지금 어디까지 왔는지**를 갖는다. 세션을 이어받으면 여기부터 읽는다.

시스템 경로·포트·확정된 결정은 [CLAUDE.md](./CLAUDE.md)에 있다.

---

## 지금 어디까지 됐나

**0단계 완료** — Postgres 통합 계획 확정 (2026-09-02). 결정 A·B 닫힘.

다음은 **1단계**다. RAM 6GB 장착이 나머지 전부의 선행 조건이다.

---

## 단계

| | 단계 | 무엇을 하나 | 상태 |
|---|---|---|---|
| 0 | 계획 | Postgres 인스턴스를 둘로 줄이는 계획. 결정 A·B 확정 | ✅ |
| 1 | 준비 | RAM 6GB, 롤 비밀번호, `njlee` 백업 스크립트 수정 | ⬜ |
| 2 | 리허설 | **개발 PC에서 먼저** DB를 둘로 통합해 형태를 검증 | ⬜ |
| 3 | 이미지 | `Dockerfile` 4개, A/S에 `output: "standalone"` 추가 | ⬜ |
| 4 | DB 이전 | NAS에 인스턴스 둘 세우고 데이터 이관 | ⬜ |
| 5 | 앱 이전 | NAS에 앱 컨테이너 올리고 `DATABASE_URL` 전환 | ⬜ |
| 6 | 접근 경계 | 리버스 프록시·방화벽·HTTPS·`TRUSTED_PROXY_HOPS=1` | ⬜ |
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
| [nas/init/app/01-roles.sh](./nas/init/app/01-roles.sh) | 업무용 인스턴스의 롤·DB·권한 |
| [nas/init/auth/01-roles.sh](./nas/init/auth/01-roles.sh) | 인증용 인스턴스의 롤·DB·권한 |
| [nas/.env.nas.example](./nas/.env.nas.example) | 두 인스턴스가 읽는 비밀번호 자리 |
| [scripts/README.md](./scripts/README.md) | 공용 실행 스크립트를 아직 옮기지 않은 이유 |

앞으로 늘어날 것: `02-이미지-빌드.md`, `03-리버스-프록시.md`, `04-배포-리허설.md`

---

## 1단계 — 지금 할 일

| | 할 일 | 어디서 |
|---|---|---|
| 1 | NAS RAM 6GB 장착, DSM 정보 센터에서 인식 확인 | NAS |
| 2 | 롤 비밀번호 3개 생성 (**서로 다른 값**) | 개발 PC |
| 3 | `njlee/scripts/backup.ts`를 `docker exec` 방식으로 수정 | `njlee` |
| 4 | `RF_Service_System/HANDOFF.md` 17번을 "staging 대신 배포 리허설"로 갱신 | `RF_Service_System` |
| 5 | `dss-home/README.md:48`의 "NAS로 옮길 때"에 *앱만*이라는 단서 추가 | `dss-home` |

3번이 필수인 이유: 지금 스크립트가 **호스트에 설치된 `pg_dump`를 부르는데 NAS에는 없다.**
고치지 않으면 계측기 백업이 NAS에서 동작하지 않는다.

비밀번호 생성:

```
node -e "console.log(require('crypto').randomBytes(24).toString('base64url'))"
```

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
