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

    @MainActor var body: some View {
        WithPerceptionTracking {
            PagerTabStripView(selection: $selection) {
                WithPerceptionTracking {
                    PostsList(isLoading: $tweetsModel.isLoading, items: tweetsModel.posts)
                        .pagerTabItem(tag: 0) {
                        }
                    
                    PostsList(isLoading: $mediaModel.isLoading, items: mediaModel.posts)
                        .pagerTabItem(tag: 1) {
                        }
                    
                    PostsList(isLoading: $likesModel.isLoading, items: likesModel.posts, withDescription: false)
                        .pagerTabItem(tag: 2) {
                        }
                }
            }
            .pagerTabStripViewStyle(.bar(placedInToolbar: false, indicatorViewHeight: 6) {
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
