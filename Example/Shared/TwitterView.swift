//
//  TwitterView.swift
//  Example (iOS)
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import SwiftUI
import PagerTabStripView
import Perception

private struct PageItem: Identifiable {
    var id: Int { tag }
    var tag: Int
    var title: String
    var posts: [Post]
    var withDescription: Bool = true
}

struct TwitterView: View {
    @State var selection = 4
    @State var toggle = true
    @State var swipeGestureEnabled = true

    private var items = [PageItem(tag: 1, title: "First big width", posts: TweetsModel().posts),
                         PageItem(tag: 2, title: "Short", posts: TweetsModel().posts),
                         PageItem(tag: 3, title: "Medium width", posts: TweetsModel().posts, withDescription: false),
                         PageItem(tag: 4, title: "Second big width", posts: TweetsModel().posts),
                         PageItem(tag: 5, title: "Second Medium", posts: TweetsModel().posts, withDescription: false),
                         PageItem(tag: 6, title: "Mini", posts: TweetsModel().posts)
    ]

    private var visibleItems: [PageItem] {
        toggle ? items : Array(items.reversed().dropLast(5))
    }

    @MainActor var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                NavBarWrapperView(visibleItems, id: \.tag, selection: $selection) { item in
                    TabBarView(
                        tag: item.tag,
                        title: item.title,
                        selection: $selection)
                }

                PagerTabStripView(
                    swipeGestureEnabled: $swipeGestureEnabled,
                    selection: $selection
                ) {
                    ForEach(visibleItems, id: \.tag) { item in
                        WithPerceptionTracking {
                            PostsList(items: item.posts, withDescription: item.withDescription)
                        }
                    }
                }
            }
            .pagerTabStripViewStyle(.scrollableBarButton(tabItemSpacing: 15, tabItemHeight: 50, indicatorViewHeight: 3, indicatorView: {
                Rectangle().fill(.blue).cornerRadius(5)
            }))
            .pagerContext(Int.self)
            .navigationBarItems(trailing: HStack {
                Button("Refresh") {
                    toggle.toggle()
                }
                Button(swipeGestureEnabled ? "Swipe On": "Swipe Off") {
                    swipeGestureEnabled.toggle()
                }
            }
            )
        }
    }
}

private struct TabBarView<SelectionType: Hashable>: View {

    @Environment(PagerSettings<SelectionType>.self) private var pagerSettings
    @Environment(\.colorScheme) var colorScheme
    @Binding var selection: SelectionType
    let tag: SelectionType
    let title: String

    init(tag: SelectionType, title: String, selection: Binding<SelectionType>) {
        self._selection = selection
        self.tag = tag
        self.title = title
    }

    @MainActor var body: some View {
        WithPerceptionTracking {
            VStack {
                let selectedColor: Color = colorScheme == .dark ? .white : .black
                Text(title)
                    .foregroundColor(.gray.interpolateTo(color: selection == tag ? selectedColor : Color(.systemGray),
                                                         fraction: pagerSettings.transition.progress(for: tag) ?? 0))
                    .font(.subheadline.bold())
                    .frame(maxHeight: .infinity)
                    .animation(.default, value: selection)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
            .frame(height: 40)
        }
    }
}

struct TwitterView_Previews: PreviewProvider {
    static var previews: some View {
        TwitterView()
    }
}
