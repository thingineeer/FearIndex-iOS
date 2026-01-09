# continue-fearindex

FearIndex-iOS 프로젝트 개발 컨텍스트를 로드합니다.

## 프로젝트 개요

CNN Fear & Greed Index를 표시하는 iOS 앱

- **iOS**: 18.0+
- **Swift**: 6.0+
- **Architecture**: RIBs + Clean Architecture
- **UI**: SwiftUI + Swift Charts

## 현재 상태 (2025-01-09)

### 완료된 작업

1. **기본 구조 구현**
   - RIBs 아키텍처 (Builder, Router, Interactor, View)
   - Clean Architecture (UseCase, Repository, DataSource)
   - SwiftUI 기반 UI

2. **CNN Fear & Greed API 연동**
   - 현재 지수: `https://production.dataviz.cnn.io/index/fearandgreed/current`
   - 히스토리: CNN 내부 API (1년치 무료)

3. **캐시 시스템**
   - 메모리 캐시 (NSCache)
   - 디스크 캐시 (FileManager)
   - 파일: `FearIndex-iOS/Core/Cache/CacheManager.swift`

4. **차트 기능**
   - SwiftUI Charts 사용
   - 기간 필터: 1일, 7일, 30일, 1년
   - 터치 인터랙션 (드래그로 값 확인)
   - 데이터 샘플링 (1년: 52개 포인트)

5. **성능 최적화**
   - Lazy loading
   - 장기 데이터 샘플링
   - 5분 자동 새로고침

### 주요 파일

```
FearIndex-iOS/
├── Core/
│   ├── Cache/CacheManager.swift          # 메모리 + 디스크 캐시
│   └── Network/NetworkClient.swift       # HTTP 클라이언트
├── Data/
│   ├── DataSources/
│   │   ├── FearIndexDataSource.swift     # CNN API
│   │   └── CryptoFearIndexDataSource.swift # 암호화폐 API (미사용)
│   └── DTOs/CNNFearGreedResponse.swift
├── Domain/
│   ├── Entities/FearIndex.swift
│   └── UseCases/
│       ├── FetchFearIndexUseCase.swift
│       └── FetchFearIndexHistoryUseCase.swift
└── Presentation/Features/FearIndex/
    ├── FearIndexBuilder.swift
    ├── FearIndexInteractor.swift
    ├── FearIndexView.swift
    └── Components/
        ├── SwiftUIChartView.swift        # 메인 차트
        ├── FearHistoryChartView.swift    # 히스토리 + 기간 선택
        └── FearGaugeView.swift           # 게이지 뷰
```

### 남겨둔 코드 (미사용)

- **Crypto Fear Index**: `CryptoFearIndexDataSource`, `FetchCryptoFearIndexUseCase`
  - alternative.me API 사용
  - 암호화폐 Fear & Greed (주식시장과 다른 지수)
  - Interactor에 코드 남아있음, 필요시 활성화 가능

### 커밋 정책

`.claude/commit-policy.md` 참조:
- Author: `thingineeer <dlaudwls1203@gmail.com>`
- 한글 커밋 메시지
- AI 생성 문구 금지
- HEREDOC 형식 사용

```bash
GIT_COMMITTER_NAME="thingineeer" GIT_COMMITTER_EMAIL="dlaudwls1203@gmail.com" \
git commit --author="thingineeer <dlaudwls1203@gmail.com>" -m "$(cat <<'EOF'
<type>: <subject>

<description>
EOF
)"
```

### 빌드 명령어

```bash
xcodebuild -project FearIndex-iOS.xcodeproj -scheme FearIndex-iOS -sdk iphonesimulator build
```

## 다음 작업 후보

1. **RapidAPI 연동** (유료)
   - Fear and Greed Index API (apimaker)
   - 5년+ 히스토리 데이터
   - API Key: `f2f74ce93emsh18778ba44080237p1fbdacjsnf3e0b1c02a86`

2. **UI 개선**
   - 다크모드 최적화
   - 위젯 지원
   - 알림 기능

3. **테스트**
   - Unit Tests
   - UI Tests

## 참고

- CNN API는 브라우저 헤더 필요 (418 에러 방지)
- 무료 CNN API는 약 1년치 데이터만 제공
- 암호화폐 지수와 주식시장 지수는 다른 값임 (혼동 주의)
