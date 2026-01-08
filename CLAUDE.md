# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the app
xcodebuild -project FearIndex-iOS.xcodeproj -scheme FearIndex-iOS -sdk iphonesimulator build

# Run unit tests
xcodebuild -project FearIndex-iOS.xcodeproj -scheme FearIndex-iOS -sdk iphonesimulator test

# Run UI tests
xcodebuild -project FearIndex-iOS.xcodeproj -scheme FearIndex-iOSUITests -sdk iphonesimulator test
```

## Project Overview

FearIndex-iOS는 시장 공포지수(VIX, Fear & Greed Index 등)를 표시하는 SwiftUI 앱입니다.

## Tech Stack

- **iOS**: 18.0+
- **Swift**: 6.0+
- **UI Framework**: SwiftUI
- **Architecture**: RIBs + Clean Architecture
- **Concurrency**: Swift Concurrency (async/await, Actor)
- **Bundle ID**: `th1ngjin.FearIndex-iOS`

## Architecture

```
Presentation (SwiftUI Views)
    ↓
Interactor (Business Logic)
    ↓
UseCase (Application Logic)
    ↓
Repository (Data Interface)
    ↓
DataSource (Network/Storage)
```

## Directory Structure

```
FearIndex-iOS/
├── App/                    # App entry point
├── Core/                   # Network, Storage, Utilities
├── Domain/                 # Entities, UseCases, Repository protocols
├── Data/                   # Repository impl, DataSources, DTOs
├── Presentation/Features/  # RIBs (Builder, Router, Interactor, View)
└── Resources/              # Assets, Localizations
```

## Coding Standards

- 함수 10줄 이하 유지
- SOLID 원칙 준수
- 프로토콜 지향 프로그래밍
- 모든 의존성은 프로토콜로 주입
- Swift Concurrency 사용 (async/await, Actor, @MainActor)

자세한 가이드라인은 `.claude/skills/ios-dev-standards/SKILL.md` 참조
