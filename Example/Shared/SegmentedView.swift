//
//  SegmentedView.swift
//  Example (iOS)
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import SwiftUI
import PagerTabStripView
import Perception

struct SegmentedView: View {
    @State var toggle = true
    @State var selection = 2
    @State var selection2 = 0

    @StateObject var tweetsModel = TweetsModel()
    @StateObject var mediaModel = TweetsModel()
    @StateObject var likesModel = TweetsModel()

    private var pages: [Int] {
        toggle ? [0, 1, 2] : [0, 2]
    }

    private let embeddedPages = [0, 1, 2]

    @MainActor var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                NavBarWrapperView(pages, id: \.self, selection: $selection) { page in
                    Text(title(for: page))
                }

                PagerTabStripView(selection: $selection) {
                    WithPerceptionTracking {
                        ForEach(pages, id: \.self) { page in
                            switch page {
                            case 0:
                                PostsList(isLoading: $tweetsModel.isLoading, items: tweetsModel.posts)
                            case 1:
                                embeddedPager
                            default:
                                PostsList(isLoading: $likesModel.isLoading, items: likesModel.posts, withDescription: false)
                            }
                        }
                    }
                }
            }
            .pagerTabStripViewStyle(.segmentedControl(backgroundColor: .yellow,
                                                      padding: EdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20)))
            .pagerContext(Int.self)
            .navigationBarItems(trailing: Button("Refresh") {
                toggle.toggle()
            })
        }
    }

    @MainActor private var embeddedPager: some View {
        VStack(spacing: 0) {
            NavBarWrapperView(embeddedPages, id: \.self, selection: $selection2) { page in
                Text(title(for: page))
            }

            PagerTabStripView(edgeSwipeGestureDisabled: .constant([.left, .right]), selection: $selection2) {
                WithPerceptionTracking {
                    PostsList(isLoading: $tweetsModel.isLoading, items: tweetsModel.posts)
                    PostsList(isLoading: $mediaModel.isLoading, items: mediaModel.posts)
                    PostsList(isLoading: $likesModel.isLoading, items: likesModel.posts, withDescription: false)
                }
            }
        }
        .pagerTabStripViewStyle(.segmentedControl(backgroundColor: .blue,
                                                  padding: EdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20)))
        .pagerContext(Int.self)
    }

    private func title(for page: Int) -> String {
        switch page {
        case 0:
            return "Tweets"
        case 1:
            return "Embedded"
        default:
            return "Likes"
        }
    }
}

struct SegmentedView_Previews: PreviewProvider {
    static var previews: some View {
        SegmentedView()
    }
}
