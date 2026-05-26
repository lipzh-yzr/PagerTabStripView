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

struct PinterestView: View {

    @State var selection = 4
    @State var toggle = true

    public init() {}

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
                    ZStack {
                        Text(item.title)
                            .foregroundColor(selection == item.tag ? .black : .white)
                            .font(.subheadline)
                            .frame(maxHeight: .infinity)
                            .animation(.default, value: selection)
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))

                    }
                    .frame(height: 40)
                }

                PagerTabStripView(selection: $selection) {
                    WithPerceptionTracking {
                        ForEach(visibleItems, id: \.tag) { item in
                            PostsList(items: item.posts, withDescription: item.withDescription)
                        }
                    }
                }
            }
            .pagerTabStripViewStyle(.scrollableBarButton(tabItemSpacing: 15,
                                                         tabItemHeight: 60,
                                                         padding: EdgeInsets(),
                                                         barBackgroundView: { Color(.systemBackground) },
                                                         indicatorView: {
                                                            Rectangle().fill(.white).frame(height: 50).cornerRadius(25).offset(y: -30).zIndex(-1)
                                                         }))
            .pagerContext(Int.self)
            .navigationBarItems(trailing: Button("Refresh") {
                toggle.toggle()
            })
        }
    }

    private func HoleShapeMask(in rect: CGRect) -> Path {
        return
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            }
    }
}

struct PinterestView_Previews: PreviewProvider {
    static var previews: some View {
        PinterestView()
    }
}
