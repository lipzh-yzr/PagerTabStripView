//
//  BarStyleView.swift
//  Example (iOS)
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import SwiftUI
import PagerTabStripView
import Perception

struct BarStyleView: View {
    @State var selection = 1

    @StateObject var tweetsModel = TweetsModel()
    @StateObject var mediaModel = TweetsModel()
    @StateObject var likesModel = TweetsModel()
    private let tabs = [0, 1, 2]

    @MainActor var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                NavBarWrapperView(tabs, id: \.self, selection: $selection) { _ in
                    EmptyView()
                }

                PagerTabStripView(selection: $selection) {
                    WithPerceptionTracking {
                        PostsList(isLoading: $tweetsModel.isLoading, items: tweetsModel.posts)

                        PostsList(isLoading: $mediaModel.isLoading, items: mediaModel.posts)

                        PostsList(isLoading: $likesModel.isLoading, items: likesModel.posts, withDescription: false)
                    }
                }
            }
            .pagerTabStripViewStyle(.bar(indicatorViewHeight: 6) {
                Rectangle().fill(.yellow)
            })
            .pagerContext(Int.self)
            .navigationTitle("Bar Style View")
        }
    }
}

struct BarStyleView_Previews: PreviewProvider {
    static var previews: some View {
        BarStyleView()
    }
}
