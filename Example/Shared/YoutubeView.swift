//
//  YoutubeView.swift
//  Example (iOS)
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import SwiftUI
import PagerTabStripView
import Perception

private struct YoutubePage: Identifiable {
    let id: Int
    let title: String
    let imageName: String
}

struct YoutubeView: View {

    @StateObject var homeModel = HomeModel()
    @StateObject var trendingModel = HomeModel()
    @StateObject var accountModel = AccountModel()

    @State var selection = 1

    @State var toggle: Bool = false

    private var pages: [YoutubePage] {
        var pages = [
            YoutubePage(id: 0, title: "Home", imageName: "house"),
            YoutubePage(id: 1, title: "Trending", imageName: "flame")
        ]

        if toggle {
            pages.append(YoutubePage(id: 2, title: "Account", imageName: "person.fill"))
        }

        return pages
    }

    @MainActor var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                NavBarWrapperView(pages, id: \.id, selection: $selection) { page in
                    YoutubeNavBarItem(title: page.title, imageName: page.imageName, selection: $selection, tag: page.id)
                }

                PagerTabStripView(selection: $selection) {
                    WithPerceptionTracking {
                        ForEach(pages) { page in
                            switch page.id {
                            case 0:
                                PostsList(isLoading: $homeModel.isLoading, items: homeModel.posts)
                                    .onAppear {
                                        homeModel.isLoading = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            homeModel.isLoading = false
                                        }
                                    }
                            case 1:
                                PostsList(isLoading: $trendingModel.isLoading, items: trendingModel.posts, withDescription: false)
                                    .onAppear {
                                        trendingModel.isLoading = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            trendingModel.isLoading = false
                                        }
                                    }
                            default:
                                PostDetail(post: accountModel.post)
                            }
                        }
                    }
                }
            }
            .pagerTabStripViewStyle(.barButton(tabItemHeight: 80, padding: EdgeInsets(), indicatorViewHeight: 5, barBackgroundView: {
                Color(red: 221/255.0, green: 0/255.0, blue: 19/255.0, opacity: 1.0)
            }, indicatorView: {
                Rectangle().fill(selectedColor)
            }))
            .pagerContext(Int.self)
            .navigationBarItems(trailing: Button(toggle ? "Hide Pofile" : "Show Profile") {
                toggle.toggle()
            })
        }
    }
}

private let selectedColor = Color(red: 234/255.0, green: 234/255.0, blue: 234/255.0, opacity: 0.7)

private struct YoutubeNavBarItem<SelectionType>: View where SelectionType: Hashable {

    @Environment(PagerSettings<SelectionType>.self) private var pagerSettings: PagerSettings<SelectionType>

    let unselectedColor = Color(red: 73/255.0, green: 8/255.0, blue: 10/255.0, opacity: 1.0)

    let title: String
    let image: Image
    @Binding var selection: SelectionType
    let tag: SelectionType

    init(title: String, imageName: String, selection: Binding<SelectionType>, tag: SelectionType) {
        self.tag = tag
        self.title = title
        self.image = Image(systemName: imageName)
        _selection = selection
    }

    @MainActor var body: some View {
        WithPerceptionTracking {
            VStack {
                image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundColor(unselectedColor.interpolateTo(color: selectedColor,
                                                                   fraction: pagerSettings.transition.progress(for: tag)))
                Text(title.uppercased())
                    .foregroundColor(unselectedColor.interpolateTo(color: selectedColor,
                                                                   fraction: pagerSettings.transition.progress(for: tag)))
                    .fontWeight(.semibold)
            }
            .animation(.default, value: selection)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct YoutubeView_Previews: PreviewProvider {
    static var previews: some View {
        YoutubeView()
    }
}
