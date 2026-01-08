//
//  AppRoot.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import SwiftUI

struct AppRoot: View {
    private let builder = FearIndexBuilder()

    var body: some View {
        builder.build()
    }
}
