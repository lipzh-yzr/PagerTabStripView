//
//  ScrollableNavBarView.swift
//  PagerTabStripView
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import Foundation
import Perception
import SwiftUI

internal struct ScrollableNavBarView<SelectionType>: View where SelectionType: Hashable {

    @Binding var selection: SelectionType
    private var pagerSettings: PagerSettings<SelectionType>
    @Environment(\.pagerStyle) private var style: PagerStyle
    @State private var appeared = false
    @State private var itemFrames = [SelectionType: CGRect]()

    public init(selection: Binding<SelectionType>, pagerSettings: PagerSettings<SelectionType>) {
        self._selection = selection
        self.pagerSettings = pagerSettings
    }

    @MainActor var body: some View {
        WithPerceptionTracking {
            if let internalStyle = style as? BarButtonStyle {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        ZStack(alignment: .bottomLeading) {
                            HStack(spacing: internalStyle.tabItemSpacing) {
                                ForEach(pagerSettings.itemsOrderedByIndex, id: \.self) { tag in
                                    NavBarItem(id: tag, selection: $selection, pagerSettings: pagerSettings)
                                        .background(itemFrameReader(tag: tag))
                                        .tag(tag)
                                }
                            }
                            indicatorView(style: internalStyle)
                        }
                        .frame(height: internalStyle.tabItemHeight)
                        .coordinateSpace(name: coordinateSpaceName)
                        .onPreferenceChange(ScrollableNavBarItemFramePreferenceKey<SelectionType>.self) { frames in
                            itemFrames = frames
                        }
                    }
                    .background(internalStyle.barBackgroundView())
                    .padding(internalStyle.padding)
                    .onChange(of: pagerSettings.itemsOrderedByIndex) { _ in
                        if pagerSettings.items[selection] != nil {
                            proxy.scrollTo(selection, anchor: .center)
                        }
                    }
                    .onChange(of: selection) { newSelection in
                        withAnimation {
                            if pagerSettings.items[newSelection] != nil {
                                proxy.scrollTo(newSelection, anchor: .center)
                            }
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if pagerSettings.items[selection] != nil {
                                proxy.scrollTo(selection, anchor: .center)
                            }
                            appeared = true
                        }
                    }
                    .onDisappear {
                        appeared = false
                    }
                }
            }
        }
    }

    private var coordinateSpaceName: String {
        "ScrollableNavBarView"
    }

    @ViewBuilder
    private func itemFrameReader(tag: SelectionType) -> some View {
        GeometryReader { geometryProxy in
            Color.clear.preference(
                key: ScrollableNavBarItemFramePreferenceKey<SelectionType>.self,
                value: [tag: geometryProxy.frame(in: .named(coordinateSpaceName))]
            )
        }
    }

    @ViewBuilder
    private func indicatorView(style internalStyle: BarButtonStyle) -> some View {
        let frame = indicatorFrame
        internalStyle.indicatorView()
            .frame(width: frame.width, height: internalStyle.indicatorViewHeight)
            .offset(x: frame.minX)
            .animation(appeared ? .default : .none, value: pagerSettings.contentOffset)
    }

    private var indicatorFrame: CGRect {
        let tags = pagerSettings.itemsOrderedByIndex
        guard !tags.isEmpty, pagerSettings.width > 0 else { return .zero }

        let indexAndPercentage = -pagerSettings.contentOffset / pagerSettings.width
        let percentage = (indexAndPercentage + 1).truncatingRemainder(dividingBy: 1)
        let lowIndex = Int(floor(indexAndPercentage))
        guard let currentFrame = frame(for: lowIndex, in: tags),
              let nextFrame = frame(for: lowIndex + 1, in: tags) else { return .zero }

        let width = currentFrame.width + ((nextFrame.width - currentFrame.width) * percentage)
        let center = currentFrame.midX + ((nextFrame.midX - currentFrame.midX) * percentage)
        return CGRect(x: center - width / 2, y: .zero, width: width, height: .zero)
    }

    private func frame(for index: Int, in tags: [SelectionType]) -> CGRect? {
        if tags.indices.contains(index) {
            return itemFrames[tags[index]]
        }
        if index < 0, let firstTag = tags.first, let firstFrame = itemFrames[firstTag] {
            return firstFrame.offsetBy(dx: -firstFrame.width, dy: .zero)
        }
        if let lastTag = tags.last, let lastFrame = itemFrames[lastTag] {
            return lastFrame.offsetBy(dx: lastFrame.width, dy: .zero)
        }
        return nil
    }
}

private struct ScrollableNavBarItemFramePreferenceKey<SelectionType>: PreferenceKey where SelectionType: Hashable {

    static var defaultValue: [SelectionType: CGRect] {
        [:]
    }

    static func reduce(value: inout [SelectionType: CGRect], nextValue: () -> [SelectionType: CGRect]) {
        value.merge(nextValue()) { _, newFrame in newFrame }
    }
}
