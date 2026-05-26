//
//  InstagramView.swift
//  Example (iOS)
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import SwiftUI
import PagerTabStripView
import Perception

struct InstagramView: View {

    enum Page: String {
        case gallery = "photo.stack"
        case list  = ""
        case like
        case saved
    }

    @State var selection = Page.list
    @State var toggle = true

    @StateObject var galleryModel = ListModel()
    @StateObject var listModel = ListModel()
    @StateObject var likedModel = ListModel()
    @StateObject var savedModel = ListModel()
    @State var edgeSwipe: HorizontalContainerEdge = .both

    private var pages: [Page] {
        toggle ? [.gallery, .list, .like, .saved] : [.gallery, .list]
    }

    @MainActor var body: some View {
        WithPerceptionTracking {
            PagerTabStripView(
                edgeSwipeGestureDisabled: $edgeSwipe,
                selection: $selection
            ) {
                WithPerceptionTracking {
                    ForEach(pages, id: \.self) { page in
                        switch page {
                        case .gallery:
                            PostsList(isLoading: $galleryModel.isLoading, items: galleryModel.posts)
                        case .list:
                            PostsList(isLoading: $listModel.isLoading, items: listModel.posts, withDescription: false)
                        case .like:
                            PostsList(isLoading: $likedModel.isLoading, items: likedModel.posts)
                        case .saved:
                            PostsList(isLoading: $savedModel.isLoading, items: savedModel.posts, withDescription: false)
                        }
                    }
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    NavBarWrapperView(pages, id: \.self, selection: $selection) { page in
                        InstagramNavBarItem(imageName: imageName(for: page), selection: $selection, tag: page)
                    }
                }
            })
            .pagerTabStripViewStyle(.scrollableBarButton(tabItemSpacing: 50,
                                                         tabItemHeight: 50, indicatorViewHeight: 2,
                                                         indicatorView: { Rectangle().fill(Color(.systemBlue)).cornerRadius(1) }))
            .pagerContext(Page.self)
            .navigationBarItems(trailing: Button("Refresh") {
                toggle.toggle()
            })
        }
    }

    private func imageName(for page: Page) -> String {
        switch page {
        case .gallery:
            return "photo.stack"
        case .list:
            return "chart.bar.doc.horizontal"
        case .like:
            return "heart"
        case .saved:
            return "photo.stack"
        }
    }
}

struct InstagramNavBarItem<SelectionType>: View where SelectionType: Hashable {
    @Environment(PagerSettings<SelectionType>.self) private var pagerSettings

    var image: Image
    @Binding var selection: SelectionType
    let tag: SelectionType

    init(imageName: String, selection: Binding<SelectionType>, tag: SelectionType) {
        self.tag = tag
        self.image = Image(systemName: imageName)
        _selection = selection
    }

    @MainActor var body: some View {
        WithPerceptionTracking {
            VStack {
                image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 25.0, height: 25)
                    .foregroundColor(Color(.systemGray).interpolateTo(color: Color(.systemBlue), fraction: pagerSettings.transition.progress(for: tag)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct InstagramView_Previews: PreviewProvider {
    static var previews: some View {
        InstagramView()
    }
}
