//
//  NavBarModifier.swift
//  PagerTabStripView
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import Perception
import SwiftUI

struct NavBarModifier<SelectionType>: ViewModifier where SelectionType: Hashable {
    @Binding private var selection: SelectionType

    public init(selection: Binding<SelectionType>) {
        self._selection = selection
    }

    @ViewBuilder
    @MainActor func body(content: Content) -> some View {
        if style.managedBySelf {
            content
        } else {
            VStack(alignment: .leading, spacing: 0) {
                if !style.placedInToolbar {
                    NavBarWrapperView(selection: $selection)
                    content
                } else {
                    content.toolbar(content: {
                        ToolbarItem(placement: .principal) {
                            NavBarWrapperView(selection: $selection)
                        }
                    })
                }
            }
        }
    }

    @Environment(\.pagerStyle) var style: PagerStyle
}

public struct NavBarWrapperView<SelectionType>: View where SelectionType: Hashable {
    @Binding var selection: SelectionType

    public init(selection: Binding<SelectionType>) {
        self._selection = selection
    }

    @ViewBuilder
    @MainActor public var body: some View {
        WithPerceptionTracking {
            navBar(pagerSettings: pagerSettings)
        }
    }

    @ViewBuilder
    @MainActor private func navBar(pagerSettings: PagerSettings<SelectionType>) -> some View {
        WithPerceptionTracking {
            switch style {
            case let barStyle as BarStyle:
                IndicatorBarView<SelectionType, AnyView>(selection: $selection,
                                                         pagerSettings: pagerSettings,
                                                         indicator: barStyle.indicatorView)
            case is SegmentedControlStyle:
                SegmentedNavBarView(selection: $selection, pagerSettings: pagerSettings)
            case let indicatorStyle as BarButtonStyle:
                if indicatorStyle.scrollable {
                    ScrollableNavBarView(selection: $selection, pagerSettings: pagerSettings)
                } else {
                    FixedSizeNavBarView(selection: $selection, pagerSettings: pagerSettings)
                }
            default:
                SegmentedNavBarView(selection: $selection, pagerSettings: pagerSettings)
            }
        }
    }

    @Environment(\.pagerStyle) var style: PagerStyle
    @Environment(PagerSettings<SelectionType>.self) private var pagerSettings: PagerSettings<SelectionType>
}
