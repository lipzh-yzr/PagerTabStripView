//
//  NavBarModifier.swift
//  PagerTabStripView
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import Perception
import SwiftUI

public struct NavBarWrapperView<Data, ID, Content>: View where Data: RandomAccessCollection, ID: Hashable, Content: View {
    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    @Binding private var selection: ID
    private let content: (Data.Element) -> Content

    public init(_ data: Data,
                id: KeyPath<Data.Element, ID>,
                selection: Binding<ID>,
                @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.id = id
        self._selection = selection
        self.content = content
    }

    @ViewBuilder
    @MainActor public var body: some View {
        WithPerceptionTracking {
            navBar(pagerSettings: pagerSettings, items: navBarItems)
                .onAppear {
                    updatePagerItems()
                }
                .onChange(of: itemIDs) { _ in
                    updatePagerItems()
                }
        }
    }

    @ViewBuilder
    @MainActor private func navBar(pagerSettings: PagerSettings<ID>, items: [NavBarContentItem<ID>]) -> some View {
        WithPerceptionTracking {
            switch style {
            case let barStyle as BarStyle:
                IndicatorBarView<ID, AnyView>(selection: $selection,
                                              pagerSettings: pagerSettings,
                                              indicator: barStyle.indicatorView)
            case is SegmentedControlStyle:
                SegmentedNavBarView(selection: $selection, pagerSettings: pagerSettings, items: items)
            case let indicatorStyle as BarButtonStyle:
                if indicatorStyle.scrollable {
                    ScrollableNavBarView(selection: $selection, pagerSettings: pagerSettings, items: items)
                } else {
                    FixedSizeNavBarView(selection: $selection, pagerSettings: pagerSettings, items: items)
                }
            default:
                SegmentedNavBarView(selection: $selection, pagerSettings: pagerSettings, items: items)
            }
        }
    }

    @Environment(\.pagerStyle) var style: PagerStyle
    @Environment(PagerSettings<ID>.self) private var pagerSettings: PagerSettings<ID>

    private var itemIDs: [ID] {
        data.map { $0[keyPath: id] }
    }

    private var navBarItems: [NavBarContentItem<ID>] {
        data.map { element in
            NavBarContentItem(id: element[keyPath: id], view: AnyView(content(element)))
        }
    }

    @MainActor private func updatePagerItems() {
        pagerSettings.updateItems(itemIDs)
    }
}

extension NavBarWrapperView where Data.Element: Identifiable, Data.Element.ID == ID {

    public init(_ data: Data,
                selection: Binding<ID>,
                @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.init(data, id: \.id, selection: selection, content: content)
    }
}
