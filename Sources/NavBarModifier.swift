//
//  NavBarModifier.swift
//  PagerTabStripView
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import SwiftUI

struct NavBarModifier<SelectionType>: ViewModifier where SelectionType: Hashable {
    @Binding private var selection: SelectionType
    private var pagerSettings: PagerSettings<SelectionType>
    private var navigationBar: (() -> AnyView)?

    public init(selection: Binding<SelectionType>,
                pagerSettings: PagerSettings<SelectionType>,
                navigationBar: (() -> AnyView)?) {
        self._selection = selection
        self.pagerSettings = pagerSettings
        self.navigationBar = navigationBar
    }

    @ViewBuilder
    @MainActor func body(content: Content) -> some View {
        if let navigationBar {
            if style.placedInToolbar {
                content.toolbar(content: {
                    ToolbarItem(placement: .principal) {
                        navigationBar()
                            .environment(pagerSettings)
                    }
                })
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    navigationBar()
                        .environment(pagerSettings)
                    content
                }
            }
        } else if style.managedBySelf {
            content
        } else {
            VStack(alignment: .leading, spacing: 0) {
                if !style.placedInToolbar {
                    NavBarWrapperView(selection: $selection, pagerSettings: pagerSettings)
                    content
                } else {
                    content.toolbar(content: {
                        ToolbarItem(placement: .principal) {
                            NavBarWrapperView(selection: $selection, pagerSettings: pagerSettings)
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
    private var pagerSettings: PagerSettings<SelectionType>?

    public init(selection: Binding<SelectionType>) {
        self._selection = selection
        self.pagerSettings = nil
    }

    public init(selection: Binding<SelectionType>, pagerSettings: PagerSettings<SelectionType>?) {
        self._selection = selection
        self.pagerSettings = pagerSettings
    }

    @ViewBuilder
    @MainActor public var body: some View {
        if let pagerSettings = pagerSettings ?? environmentPagerSettings {
            navBar(pagerSettings: pagerSettings)
                .environment(pagerSettings)
        }
    }

    @ViewBuilder
    @MainActor private func navBar(pagerSettings: PagerSettings<SelectionType>) -> some View {
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

    @Environment(\.pagerStyle) var style: PagerStyle
    @Environment(PagerSettings<SelectionType>.self) private var environmentPagerSettings: PagerSettings<SelectionType>?
}
