//
//  Extensions.swift
//  PagerTabStripView
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import SwiftUI

extension View {

    /// Sets the style for the pager view within the the current environment.
    ///
    /// - Parameter style: The style to apply to this pager view.
    public func pagerTabStripViewStyle(_ style: PagerStyle) -> some View {
        return self.environment(\.pagerStyle, style)
    }
    
    public func pagerContext<SelectionType>(_ type: SelectionType.Type) -> some View where SelectionType: Hashable {
        modifier(PagerContextModifier<SelectionType>())
    }
}

struct PagerContextModifier<SelectionType>: ViewModifier where SelectionType: Hashable {
    @State private var pagerSettings = PagerSettings<SelectionType>()

    public init() { }

    @ViewBuilder
    @MainActor func body(content: Content) -> some View {
        content
            .environment(pagerSettings)
    }
}
