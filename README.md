# fastapi-template

## 주요 기능

- **Keycloak 기반 인증/인가**
	- OAuth2 Password Grant로 토큰 발급 및 검증
	- JWT 서명 검증 및 사용자 정보 추출
	- 역할(Role), 스코프(Scope) 기반 권한 체크

- **환경별 설정 분리**
	- 환경 변수와 YAML 기반 서비스 설정 지원
	- 개발/테스트/운영 환경 분리

- **의존성 주입(DI) 구조**
	- FastAPI Depends를 활용한 설정/인증/권한 체크 모듈화

- **API 라우팅 및 문서화**
	- 인증/헬스체크 등 RESTful 엔드포인트 제공
	- OpenAPI(Swagger UI) 자동 문서화 지원

- **테스트 코드 내장**
	- 계층별 단위 테스트 및 통합 테스트 예시 포함

- **로깅 및 예외 처리**
	- 커스텀 로깅 레벨 및 예외 핸들러 확장

uv 환경의 FastAPI 템플릿입니다.

## 프로젝트 구조


아래는 실제 폴더 및 파일 구조와 각 역할별 설명입니다.

- `fastapi_template/`
	- `main.py`: 앱 진입점
	- `factory.py`: FastAPI 앱 조립(로깅, CORS, lifespan, 라우트 등록)
	- `core/`: 공통 인프라 계층
		- `config.py`: 환경 변수 및 서비스 설정 관리
		- `security.py`: JWT 검증/디코드, Keycloak 토큰 발급
		- `logging.py`: 로깅 레벨 초기화
		- `exceptions.py`: 예외 처리 확장 포인트
	- `dependencies/`: FastAPI 의존성 주입 모듈
		- `config.py`: 설정 의존성
		- `iam.py`: 인증/인가 관련 의존성
	- `routes/`: API 라우팅 계층 (HTTP 입출력 중심)
		- `auth.py`: 인증/인가 엔드포인트
		- `health.py`: liveness/readiness 엔드포인트
		- `__init__.py`: 라우트 등록 함수
	- `schemas/`: 요청/응답 스키마(Pydantic)
		- `health.py`, `token.py`, `user.py`: 각 도메인별 스키마
	- `services/`: 외부 서비스 연동/도메인 서비스
		- `security.py`: 인증/보안 관련 서비스

- `test_fastapi_template/`: 계층별 테스트 코드
	- `core/`
		- `test_security.py`: core.security 테스트
	- `dependencies/`
		- `test_security.py`: dependencies.security 테스트
	- `routes/`
		- `test_auth.py`: 인증 라우트 테스트
		- `test_health.py`: 헬스체크 라우트 테스트
	- `services/`
		- `test_security.py`: 서비스 계층 보안 테스트

- `.devcontainer/`: 개발 환경 및 설정 파일

## 설정 체계

이 템플릿은 설정을 두 레이어로 분리합니다.

- 환경 변수(`env_settings`): 실행 환경별 값(환경 타입, 설정 파일 경로, 시크릿)
- 서비스 설정(`service_config`): 기능 동작 값(로깅, CORS, JWT 정책, Keycloak URL 등)

## 환경 변수

환경 변수는 `fastapi_template/core/config.py`의 `EnvSettings` 기준입니다.

| 변수명 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `ENVIRONMENT` | `dev` \| `test` \| `prod` | `dev` | 실행 환경 구분 |
| `CONFIG_PATH` | `str` | `.devcontainer/config.yaml` | 서비스 설정 YAML 파일 경로 |
| `KEYCLOAK_USERNAME` | `str` | `test` | Keycloak 사용자명(테스트/개발용) |
| `KEYCLOAK_PASSWORD` | `str` | `test` | Keycloak 비밀번호(테스트/개발용) |

## 서비스 설정 변수 (YAML)

서비스 설정은 기본적으로 `.devcontainer/config.yaml`에서 관리합니다.

### logging

| 키 | 타입 | 기본값 | 사용 위치 |
| --- | --- | --- | --- |
| `logging.level` | `WARNING` \| `INFO` \| `DEBUG` | `DEBUG` | 애플리케이션 로그 레벨 설정 (`core/logging.py`) |

### cors

| 키 | 타입 | 기본값 | 사용 위치 |
| --- | --- | --- | --- |
| `cors.origins` | `list[str]` 또는 `comma-separated str` | `[*]` | CORS 허용 Origin (`factory.py`) |
| `cors.credentials` | `bool` | `false` | CORS credentials 허용 여부 (`factory.py`) |

### auth

| 키 | 타입 | 기본값 | 사용 위치 |
| --- | --- | --- | --- |
| `auth.verify_jwt` | `bool` | `true` | JWT 서명 검증 사용 여부 (`core/security.py`) |
| `auth.allow_insecure_jwt_decode` | `bool` | `false` | 비검증 디코드 허용 여부 (`core/security.py`) |

보안 정책:

- `ENVIRONMENT=prod`에서는 항상 JWT 검증 경로를 사용합니다.
- `dev/test`에서 `auth.verify_jwt=false`일 때는 `auth.allow_insecure_jwt_decode=true`를 명시해야만 비검증 디코드가 허용됩니다.

### keycloak

| 키 | 타입 | 기본값 | 사용 위치 |
| --- | --- | --- | --- |
| `keycloak.http_url` | `HttpUrl` | `http://keycloak:8080/` | 토큰 발급/JWKS/issuer URL 구성 |
| `keycloak.manage_url` | `HttpUrl` | `http://keycloak:9000/` | readiness check URL 구성 (`routes/health.py`) |
| `keycloak.realm` | `str` | `restapi` | Keycloak Realm |
| `keycloak.client_id` | `str` | `fastapi` | JWT audience 및 토큰 요청 client_id |

## Keycloak DB 백업

```bash
docker compose -p fastapi-template_devcontainer exec keycloak-postgres pg_dump -U postgres -d postgres > .devcontainer/init.sql
```

## Reference

- [uv - fastapi](https://docs.astral.sh/uv/guides/integration/fastapi/)
- [fastapi - deployment](https://fastapi.tiangolo.com/deployment/docker/)
