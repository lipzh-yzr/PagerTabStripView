//
//  FixedSizeNavBarView.swift
//  PagerTabStripView
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import Foundation
import Perception
import SwiftUI

internal struct FixedSizeNavBarView<SelectionType>: View where SelectionType: Hashable {

    @Binding private var selection: SelectionType
    @Environment(\.pagerStyle) private var style: PagerStyle
    private var pagerSettings: PagerSettings<SelectionType>
    @State private var appeared = false

    public init(selection: Binding<SelectionType>, pagerSettings: PagerSettings<SelectionType>) {
        self._selection = selection
        self.pagerSettings = pagerSettings
    }

    @MainActor var body: some View {
        WithPerceptionTracking {
            if let internalStyle = style as? BarButtonStyle {
                GeometryReader { geometryProxy in
                    ZStack(alignment: .bottomLeading) {
                        HStack(spacing: internalStyle.tabItemSpacing) {
                            ForEach(pagerSettings.itemsOrderedByIndex, id: \.self) { tag in
                                NavBarItem(id: tag, selection: $selection, pagerSettings: pagerSettings)
                                    .frame(maxWidth: .infinity)
                                    .tag(tag)
                            }
                        }
                        .frame(width: geometryProxy.size.width, height: geometryProxy.size.height)
                        internalStyle.indicatorView()
                            .frame(width: indicatorWidth(containerWidth: geometryProxy.size.width,
                                                         spacing: internalStyle.tabItemSpacing),
                                   height: internalStyle.indicatorViewHeight)
                            .offset(x: indicatorOffset(containerWidth: geometryProxy.size.width,
                                                       spacing: internalStyle.tabItemSpacing))
                            .animation(appeared ? .default : .none, value: pagerSettings.contentOffset)
                    }
                }
                .frame(height: internalStyle.tabItemHeight)
                .padding(internalStyle.padding)
                .background(internalStyle.barBackgroundView())
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        appeared = true
                    }
                }
                .onDisappear {
                    appeared = false
                }
            }
        }
    }

    private func indicatorWidth(containerWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        let itemsCount = pagerSettings.items.count
        guard itemsCount > 0, pagerSettings.width > 0 else { return .zero }
        let totalSpacing = spacing * CGFloat(max(itemsCount - 1, 0))
        return max((containerWidth - totalSpacing) / CGFloat(itemsCount), .zero)
    }

    private func indicatorOffset(containerWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        guard pagerSettings.width > 0 else { return .zero }
        return (-pagerSettings.contentOffset / pagerSettings.width) * (indicatorWidth(containerWidth: containerWidth, spacing: spacing) + spacing)
    }
}
