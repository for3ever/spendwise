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
