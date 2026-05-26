//
//  SegmentedNavBarView.swift
//  PagerTabStripView
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import Foundation
import Perception
import SwiftUI

internal struct SegmentedNavBarView<SelectionType>: View where SelectionType: Hashable {
    @Binding private var selection: SelectionType
    private var pagerSettings: PagerSettings<SelectionType>
    private var items: [NavBarContentItem<SelectionType>]

    public init(selection: Binding<SelectionType>,
                pagerSettings: PagerSettings<SelectionType>,
                items: [NavBarContentItem<SelectionType>]) {
        self._selection = selection
        self.pagerSettings = pagerSettings
        self.items = items
    }

    @MainActor var body: some View {
        WithPerceptionTracking {
            if let internalStyle = style as? SegmentedControlStyle {
                Picker("SegmentedNavBarView", selection: $selection) {
                    if items.count > 0 && pagerSettings.width > 0 {
                        ForEach(items) { item in
                            NavBarItem(id: item.id,
                                       view: item.view,
                                       selection: $selection,
                                       pagerSettings: pagerSettings)
                                .tag(item.id)
                        }
                    }
                }
                .pickerStyle(.segmented)
                .colorMultiply(internalStyle.backgroundColor)
                .padding(internalStyle.padding)
            }
        }
    }

    @Environment(\.pagerStyle) var style: PagerStyle
}
