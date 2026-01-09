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
        let networkClient = NetworkClient()

        // CNN Fear & Greed (주식시장, 최근 1년)
        let cnnDataSource = FearIndexDataSource(networkClient: networkClient)
        let repository = FearIndexRepository(dataSource: cnnDataSource)
        let fetchUseCase = FetchFearIndexUseCase(repository: repository)
        let fetchHistoryUseCase = FetchFearIndexHistoryUseCase(repository: repository)

        // Alternative.me Crypto Fear & Greed (암호화폐, 2018년부터)
        let cryptoDataSource = CryptoFearIndexDataSource(networkClient: networkClient)
        let fetchCryptoUseCase = FetchCryptoFearIndexUseCase(dataSource: cryptoDataSource)

        let interactor = FearIndexInteractor(
            fetchUseCase: fetchUseCase,
            fetchHistoryUseCase: fetchHistoryUseCase,
            fetchCryptoUseCase: fetchCryptoUseCase
        )

        let router = FearIndexRouter(interactor: interactor)
        _ = router

        Logger.info("FearIndexBuilder - build() completed (CNN + Crypto APIs)")

        return FearIndexView(interactor: interactor)
    }
}
