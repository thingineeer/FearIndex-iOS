---
name: ios-dev-standards
description: FearIndex iOS 프로젝트 개발 표준. Swift 코드 작성, 리뷰, 리팩토링 시 자동 적용. RIBs 아키텍처, 클린 아키텍처, SOLID 원칙, 프로토콜 지향 프로그래밍 가이드라인 포함.
---

# FearIndex iOS Development Standards

## 기술 스택 요구사항

- **iOS**: 18.0+
- **Swift**: 6.0+
- **UI Framework**: SwiftUI
- **Architecture**: RIBs + Clean Architecture
- **Concurrency**: Swift Concurrency (async/await, Actor)

## 아키텍처 원칙

### RIBs (Router, Interactor, Builder) + Clean Architecture

```
Presentation Layer (SwiftUI Views)
        ↓
    Interactor (Business Logic)
        ↓
    Use Cases (Application Logic)
        ↓
    Repository (Data Access Interface)
        ↓
    Data Sources (Network, Local Storage)
```

**각 컴포넌트 역할:**
- **Router**: 화면 전환 및 RIB 트리 관리
- **Interactor**: 비즈니스 로직, View와 UseCase 연결
- **Builder**: 의존성 주입, RIB 생성
- **View**: SwiftUI 뷰, 순수 UI 렌더링만 담당
- **UseCase**: 단일 비즈니스 규칙 캡슐화
- **Repository**: 데이터 소스 추상화
- **Entity**: 순수 도메인 모델

### 디렉토리 구조

```
FearIndex-iOS/
├── App/
│   └── FearIndex_iOSApp.swift
├── Core/
│   ├── Network/
│   ├── Storage/
│   └── Utilities/
├── Domain/
│   ├── Entities/
│   ├── UseCases/
│   └── Repositories/ (Protocols)
├── Data/
│   ├── Repositories/ (Implementations)
│   ├── DataSources/
│   └── DTOs/
├── Presentation/
│   └── Features/
│       └── FeatureName/
│           ├── FeatureNameBuilder.swift
│           ├── FeatureNameRouter.swift
│           ├── FeatureNameInteractor.swift
│           └── FeatureNameView.swift
└── Resources/
```

## 코딩 규칙

### 1. 함수는 10줄 이하로 유지

```swift
// ❌ Bad: 긴 함수
func processData() {
    // 20줄 이상의 코드...
}

// ✅ Good: 분리된 작은 함수들
func processData() {
    let validated = validateInput()
    let transformed = transformData(validated)
    saveResult(transformed)
}

private func validateInput() -> ValidatedData { ... }
private func transformData(_ data: ValidatedData) -> TransformedData { ... }
private func saveResult(_ data: TransformedData) { ... }
```

### 2. SOLID 원칙

**S - 단일 책임 원칙**
```swift
// ✅ 각 타입은 하나의 책임만
protocol FearIndexFetching {
    func fetch() async throws -> FearIndex
}

protocol FearIndexCaching {
    func cache(_ index: FearIndex) async
}
```

**O - 개방-폐쇄 원칙**
```swift
// ✅ 확장에 열려있고 수정에 닫혀있음
protocol DataSource {
    func fetchData() async throws -> Data
}

struct NetworkDataSource: DataSource { ... }
struct CacheDataSource: DataSource { ... }
```

**L - 리스코프 치환 원칙**
```swift
// ✅ 하위 타입은 상위 타입을 대체 가능
protocol Repository {
    func save(_ entity: Entity) async throws
}
```

**I - 인터페이스 분리 원칙**
```swift
// ✅ 작고 구체적인 프로토콜
protocol Readable { func read() async throws -> Data }
protocol Writable { func write(_ data: Data) async throws }
```

**D - 의존성 역전 원칙**
```swift
// ✅ 추상화에 의존
final class FearIndexInteractor {
    private let useCase: FearIndexFetchable  // 프로토콜에 의존

    init(useCase: FearIndexFetchable) {
        self.useCase = useCase
    }
}
```

### 3. 프로토콜 지향 프로그래밍

```swift
// ✅ 프로토콜 정의 후 구현
protocol FearIndexInteractable: AnyObject {
    func loadFearIndex() async
    func refresh() async
}

protocol FearIndexRouting: AnyObject {
    func routeToDetail(with index: FearIndex)
}

protocol FearIndexBuildable {
    func build() -> FearIndexRouting
}
```

### 4. Swift Concurrency 패턴

```swift
// ✅ async/await 사용
func fetchFearIndex() async throws -> FearIndex {
    try await repository.fetch()
}

// ✅ Actor로 상태 보호
actor FearIndexCache {
    private var cached: FearIndex?

    func store(_ index: FearIndex) {
        cached = index
    }

    func retrieve() -> FearIndex? {
        cached
    }
}

// ✅ MainActor로 UI 업데이트
@MainActor
final class FearIndexInteractor: ObservableObject {
    @Published private(set) var state: ViewState = .idle
}
```

### 5. 네이밍 컨벤션

| 타입 | 네이밍 | 예시 |
|------|--------|------|
| Protocol | ~able, ~ing, ~Routing | `FearIndexFetchable`, `FearIndexRouting` |
| Interactor | Feature + Interactor | `FearIndexInteractor` |
| Router | Feature + Router | `FearIndexRouter` |
| Builder | Feature + Builder | `FearIndexBuilder` |
| UseCase | 동사 + UseCase | `FetchFearIndexUseCase` |
| Repository | 도메인 + Repository | `FearIndexRepository` |
| View | Feature + View | `FearIndexView` |

### 6. 디자인 패턴 활용

**Repository Pattern**
```swift
protocol FearIndexRepositoryProtocol {
    func fetch() async throws -> FearIndex
    func save(_ index: FearIndex) async throws
}
```

**Factory Pattern (Builder)**
```swift
protocol FearIndexBuildable {
    func build(listener: FearIndexListener) -> FearIndexRouting
}

final class FearIndexBuilder: FearIndexBuildable {
    func build(listener: FearIndexListener) -> FearIndexRouting {
        let interactor = FearIndexInteractor()
        let router = FearIndexRouter(interactor: interactor)
        return router
    }
}
```

**Strategy Pattern**
```swift
protocol FearDisplayStrategy {
    func display(_ index: FearIndex) -> String
}

struct NumericDisplayStrategy: FearDisplayStrategy { ... }
struct EmojiDisplayStrategy: FearDisplayStrategy { ... }
```

## SwiftUI 뷰 규칙

```swift
// ✅ 뷰는 순수 렌더링만
struct FearIndexView: View {
    @StateObject private var interactor: FearIndexInteractor

    var body: some View {
        content
            .task { await interactor.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch interactor.state {
        case .loading: loadingView
        case .loaded(let data): dataView(data)
        case .error(let error): errorView(error)
        }
    }
}
```

## 에러 처리

```swift
// ✅ 도메인별 에러 타입 정의
enum FearIndexError: Error {
    case networkFailure(underlying: Error)
    case invalidData
    case notFound
}

// ✅ Result 또는 throws 사용
func fetch() async throws -> FearIndex
```

## 테스트 용이성

```swift
// ✅ 모든 의존성은 프로토콜로 주입
final class FearIndexInteractor {
    init(
        useCase: FearIndexFetchable,
        router: FearIndexRouting
    ) { ... }
}

// ✅ Mock 생성 용이
final class MockFearIndexUseCase: FearIndexFetchable {
    var result: Result<FearIndex, Error> = .success(.mock)

    func fetch() async throws -> FearIndex {
        try result.get()
    }
}
```
