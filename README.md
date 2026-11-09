# SpendWise

개인 지출과 예산을 한눈에 관리하는 정적 웹앱입니다. 수입·지출 데이터를 브라우저의 `LocalStorage`에 저장하므로 별도 서버나 데이터베이스 없이 사용할 수 있습니다.

## 주요 기능

- 수입·지출 내역 추가, 수정, 삭제
- 월별 잔액·수입·지출 요약
- 최근 6개월 지출 추이 차트
- 카테고리별 소비 분석 차트
- 카테고리별 월 예산 설정 및 초과 알림
- 거래처·메모 검색 및 유형·카테고리·기간 필터
- 반응형 대시보드 UI
- GitHub Pages 정적 배포

## 프로젝트 구조

```text
.
├── index.html
├── styles.css
├── app.js
├── .gitignore
├── README.md
└── .github/
    └── workflows/
        └── pages.yml
```

## 실행 방법

별도 빌드 과정 없이 정적 파일을 실행할 수 있습니다.

### 방법 1: 파일로 열기

`index.html`을 브라우저에서 직접 열면 됩니다.

### 방법 2: 로컬 정적 서버

```powershell
cd C:\Users\당근\Desktop\sw
python -m http.server 4173
```

브라우저에서 <http://localhost:4173>을 엽니다.

Chart.js는 CDN에서 로드되므로 차트 사용 시 인터넷 연결이 필요합니다.

## Docker 실행

Docker Desktop이 설치되고 실행 중인 환경에서 프로젝트 루트에서 실행합니다.

```powershell
cd C:\Users\당근\Desktop\sw
docker build -t spendwise:local .
docker run --rm --name spendwise -p 8080:80 spendwise:local
```

브라우저에서 <http://localhost:8080>을 열면 Nginx가 SpendWise 정적 파일을 제공합니다. 종료하려면 실행 중인 터미널에서 `Ctrl+C`를 누르거나 별도 터미널에서 아래 명령을 사용합니다.

```powershell
docker stop spendwise
```

컨테이너 내부 Nginx는 `/` 요청을 `index.html`로 처리하고, CSS·JavaScript 경로를 그대로 제공하도록 설정되어 있습니다. 거래 데이터는 컨테이너가 아닌 브라우저의 LocalStorage에 저장되므로 컨테이너를 다시 만들어도 브라우저 저장 데이터는 유지됩니다.

## Docker Hub 자동 배포

`.github/workflows/ci.yml`은 `main` 브랜치 Push 또는 수동 실행 시 다음 작업을 수행합니다.

1. 필수 소스·Docker 설정 파일 확인
2. `app.js` 구문 및 정적 리소스 경로 검증
3. Nginx Dockerfile 및 `.dockerignore` 검사
4. Docker Hub 로그인
5. Docker 이미지 빌드 및 Push

Docker Hub 저장소는 `<DOCKERHUB_USERNAME>/spendwise-app`을 기준으로 합니다. 이미지에는 다음 두 태그가 생성됩니다.

```text
<DOCKERHUB_USERNAME>/spendwise-app:latest
<DOCKERHUB_USERNAME>/spendwise-app:sha-<GITHUB_SHA>
```

### GitHub Repository Secrets 설정

GitHub 저장소의 **Settings → Secrets and variables → Actions → New repository secret**에서 아래 두 값을 추가합니다.

- `DOCKERHUB_USERNAME`: Docker Hub 사용자명
- `DOCKERHUB_TOKEN`: Docker Hub Access Token

토큰은 Docker Hub의 **Account Settings → Personal access tokens**에서 생성하고, 비밀번호 대신 사용합니다. 두 값은 워크플로 파일이나 소스 코드에 작성하지 않습니다.

### 필요한 Git 명령

```powershell
git add .github/workflows/ci.yml README.md
git commit -m "Add Docker Hub CI pipeline"
git push origin main
```

Push가 완료되면 **GitHub → Actions → SpendWise CI and Docker Publish**에서 검증 및 이미지 업로드 결과를 확인할 수 있습니다. 기존 `pages.yml`은 별도의 `pages` concurrency 그룹과 GitHub Pages 권한을 사용하므로 Docker Publish 작업과 독립적으로 실행됩니다.

## 데이터 저장 및 개인정보

거래 데이터와 예산은 브라우저별·사이트별 `LocalStorage`에만 저장됩니다. 서버로 전송하지 않습니다. 브라우저 저장 데이터를 삭제하면 SpendWise 데이터도 삭제되므로, 중요한 데이터는 별도 백업 후 관리하세요.

## GitHub 저장소 연결

Git이 설치된 환경에서 아래 명령을 실행합니다. 저장소 이름은 `spendwise-app`을 기준으로 합니다.

```powershell
cd C:\Users\당근\Desktop\sw
git init
git add .
git commit -m "Initial SpendWise app"
git branch -M main
git remote add origin https://github.com/<GITHUB_USERNAME>/spendwise-app.git
git push -u origin main
```

이미 Git 저장소가 있다면 `git init`은 생략하고 현재 브랜치와 원격 저장소를 먼저 확인하세요. 이 프로젝트에는 GitHub 인증정보를 파일로 저장하지 않습니다.

## GitHub Pages 배포

`.github/workflows/pages.yml`이 `main` 브랜치 Push를 감지합니다.

1. GitHub 저장소의 **Settings → Pages**로 이동합니다.
2. **Source**에서 **GitHub Actions**를 선택합니다.
3. `main` 브랜치에 Push합니다.
4. Actions의 `SpendWise Pages` 워크플로가 정적 파일을 검증하고 Pages에 배포합니다.

배포 URL은 일반적으로 다음 형식입니다.

```text
https://<GITHUB_USERNAME>.github.io/spendwise-app/
```

## 배포 경로 참고

HTML은 `styles.css`, `app.js`, Chart.js CDN을 모두 상대 경로 또는 절대 CDN 주소로 참조하므로 프로젝트 하위 경로인 `/spendwise-app/`에서도 동작하도록 구성되어 있습니다. 서버 API나 루트(`/`) 기준의 리소스 참조는 사용하지 않습니다.
