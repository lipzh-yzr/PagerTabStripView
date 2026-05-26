//
//  NavBarItem.swift
//  PagerTabStripView
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import Perception
import SwiftUI

struct NavBarContentItem<SelectionType>: Identifiable where SelectionType: Hashable {
    let id: SelectionType
    let view: AnyView
}

struct NavBarItem<SelectionType>: View, Identifiable where SelectionType: Hashable {

    var id: SelectionType
    @Binding private var selection: SelectionType
    private var pagerSettings: PagerSettings<SelectionType>
    private var view: AnyView

    public init(id: SelectionType,
                view: AnyView,
                selection: Binding<SelectionType>,
                pagerSettings: PagerSettings<SelectionType>) {
        self.id = id
        self.view = view
        self._selection = selection
        self.pagerSettings = pagerSettings
    }

    @MainActor var body: some View {
        WithPerceptionTracking {
            view
                .onTapGesture {
                    selection = id
                }
                .accessibilityAddTraits(id == selection ? [.isButton, .isSelected] : .isButton)
                .environment(pagerSettings)
        }
    }
}
