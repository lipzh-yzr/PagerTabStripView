//
//  SimpleVIew.swift
//  Example (iOS)
//
//  Created by Martin Barreto on 24/11/22.
//

import SwiftUI
import PagerTabStripView
import Perception

struct SimpleView: View {

    let textForColor = [Color.purple: "Swiftable 2022",
                        .green: "SwiftUI",
                        .yellow: "iOS 16.1",
                        .orange: "PagerTabStripView"]
    let colors = [Color.purple, .green, .yellow, .orange]
    @State var selection: Color = .green

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                NavBarWrapperView(colors, id: \.self, selection: $selection) { color in
                    Text(textForColor[color]!)
                        .foregroundColor(color)
                }

                PagerTabStripView(selection: $selection) {
                    WithPerceptionTracking {
                        ForEach(colors, id: \.self) { color in
                            Rectangle()
                                .fill(color.gradient)
                        }
                    }
                }
            }
            .pagerTabStripViewStyle(
                .scrollableBarButton(tabItemSpacing: 25,
                                     tabItemHeight: 50,
                                     indicatorViewHeight: 13,
                                     indicatorView: {
                                        Circle()
                                            .offset(y: -5)
                                            .foregroundColor(selection)
                                            .animation(.linear(duration: 0.5)
                                                        .repeatForever(autoreverses: true),
                                                       value: selection)
                                     }))
            .pagerContext(Color.self)
        }
    }

}

struct SimpleView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleView()
    }
}
