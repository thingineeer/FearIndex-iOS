//
//  FearIndexBuilder.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import SwiftUI

protocol FearIndexBuildable {
    @MainActor func build() -> FearIndexView
}

final class FearIndexBuilder: FearIndexBuildable {
    @MainActor
    func build() -> FearIndexView {
        let dataSource = createDataSource()
        let repository = FearIndexRepository(dataSource: dataSource)

        let fetchUseCase = FetchFearIndexUseCase(repository: repository)
        let fetchHistoryUseCase = FetchFearIndexHistoryUseCase(repository: repository)

        let interactor = FearIndexInteractor(
            fetchUseCase: fetchUseCase,
            fetchHistoryUseCase: fetchHistoryUseCase
        )

        let router = FearIndexRouter(interactor: interactor)
        _ = router

        Logger.info("FearIndexBuilder - build() completed")

        return FearIndexView(interactor: interactor)
    }

    private func createDataSource() -> FearIndexDataSourceProtocol {
        // Mock 데이터 사용 (테스트용)
        Logger.info("Using Mock DataSource")
        return MockFearIndexDataSource()

        // 실제 CNN API 사용 시 아래 코드로 교체
        // let networkClient = NetworkClient()
        // return FearIndexDataSource(networkClient: networkClient)
    }
}
