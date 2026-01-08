//
//  FearIndexRouter.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import SwiftUI

protocol FearIndexRouting: AnyObject {
    func routeToHistory()
    func routeToSettings()
}

@MainActor
final class FearIndexRouter: FearIndexRouting {
    weak var interactor: FearIndexInteractor?

    init(interactor: FearIndexInteractor) {
        self.interactor = interactor
    }

    func routeToHistory() {
        // 추후 히스토리 상세 화면으로 라우팅
    }

    func routeToSettings() {
        // 추후 설정 화면으로 라우팅
    }
}
