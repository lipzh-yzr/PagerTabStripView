//
//  PagerTabStripView.swift
//  PagerTabStripView
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//
import Perception
import SwiftUI
import SwiftUIX

public struct HorizontalContainerEdge: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let left = HorizontalContainerEdge(rawValue: 1 << 0)
    public static let right = HorizontalContainerEdge(rawValue: 1 << 1)

    public static let both: HorizontalContainerEdge = [.left, .right]
}

@available(iOS 15.0, macOS 14.0, *)
public struct PagerTabStripView<SelectionType, Content>: View where SelectionType: Hashable, Content: View {
    private var content: () -> Content
    private var swipeGestureEnabled: Binding<Bool>
    private var edgeSwipeGestureDisabled: Binding<HorizontalContainerEdge>
    private var selection: Binding<SelectionType>?
    @State private var internalSelection: SelectionType

    public init(swipeGestureEnabled: Binding<Bool> = .constant(true),
                edgeSwipeGestureDisabled: Binding<HorizontalContainerEdge> = .constant([]),
                selection: Binding<SelectionType>,
                @ViewBuilder content: @escaping () -> Content) {
        self.swipeGestureEnabled = swipeGestureEnabled
        self.edgeSwipeGestureDisabled = edgeSwipeGestureDisabled
        self.selection = selection
        self._internalSelection = State(initialValue: selection.wrappedValue)
        self.content = content
    }

    @MainActor public var body: some View {
        let selection = selection ?? $internalSelection
        WrapperPagerTabStripView(swipeGestureEnabled: swipeGestureEnabled,
                                 edgeSwipeGestureDisabled: edgeSwipeGestureDisabled,
                                 selection: selection,
                                 content: content)
    }
}

extension PagerTabStripView where SelectionType == Int {

    public init(swipeGestureEnabled: Binding<Bool> = .constant(true),
                edgeSwipeGestureDisabled: Binding<HorizontalContainerEdge> = .constant([]),
                @ViewBuilder content: @escaping () -> Content) {
        self.swipeGestureEnabled = swipeGestureEnabled
        self.edgeSwipeGestureDisabled = edgeSwipeGestureDisabled
        self.selection = nil
        self._internalSelection = State(initialValue: 0)
        self.content = content
    }
}

private struct WrapperPagerTabStripView<SelectionType, Content>: View where SelectionType: Hashable, Content: View {

    private var content: Content
    private var navigationBar: (() -> AnyView)?
    @Environment(PagerSettings<SelectionType>.self) private var pagerSettings
    @Environment(\.pagerStyle) var style: PagerStyle
    @Binding private var selection: SelectionType
    @GestureState private var translation: CGFloat = 0
    @Binding private var swipeGestureEnabled: Bool
    @Binding private var edgeSwipeGestureDisabled: HorizontalContainerEdge
    @State private var swipeOn: Bool = true

    public init(swipeGestureEnabled: Binding<Bool>,
                edgeSwipeGestureDisabled: Binding<HorizontalContainerEdge>,
                selection: Binding<SelectionType>,
                @ViewBuilder content: @escaping () -> Content) {
        self._swipeGestureEnabled = swipeGestureEnabled
        self._edgeSwipeGestureDisabled = edgeSwipeGestureDisabled
        self._selection = selection
        self.content = content()
    }

    @MainActor public var body: some View {
        WithPerceptionTracking {
            GeometryReader { geometryProxy in
                WithPerceptionTracking {
                    pagerPages(in: geometryProxy)
                        .onAppear {
                            pagerSettings.updateWidth(geometryProxy.frame(in: .local).width, selection: selection)
                        }
                        .onChange(of: pagerSettings.itemsOrderedByIndex) { _ in
                            pagerSettings.updateScrollContentOffset(for: selection)
                        }
                        .onChange(of: geometryProxy.frame(in: .local)) { geometry in
                            pagerSettings.updateWidth(geometry.width, selection: selection)
                        }
                        .onChange(of: selection) { newSelection in
                            pagerSettings.updateScrollContentOffset(for: newSelection)
                            swipeOn = true
                        }
                }
            }
            .modifier(NavBarModifier(selection: $selection))
            .clipped()
        }
    }

    @ViewBuilder
    @MainActor private func pagerPages(in geometryProxy: GeometryProxy) -> some View {
//        #if canImport(SwiftUIX) && ((os(iOS) && canImport(CoreTelephony)) || os(tvOS) || targetEnvironment(macCatalyst))
        CocoaScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                WithPerceptionTracking {
                    content
                        .frame(width: geometryProxy.size.width)
                }
            }
            .coordinateSpace(name: "PagerViewScrollView")
        }
        .contentOffset(Binding(
            get: {
                pagerSettings.scrollContentOffset
            },
            set: { contentOffset in
                pagerSettings.updateScrollContentOffset(contentOffset)
            }
        ))
        .onOffsetChange { contentOffset in
            pagerSettings.updateScrollContentOffset(contentOffset.value(from: .topLeading))
            updateSelectionIfScrollSettled()
        }
        .onDragEnd {
            updateSelectionToNearestPage()
        }
        .isPagingEnabled(true)
        .alwaysBounceHorizontal(!shouldDisableHorizontalBounce)
        .alwaysBounceVertical(false)
        .scrollDisabled(!swipeGestureEnabled)
//        #else
//        legacyPagerPages(in: geometryProxy)
//        #endif
    }

    @ViewBuilder
    @MainActor private func legacyPagerPages(in geometryProxy: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            content
                .frame(width: geometryProxy.size.width)
        }
        .coordinateSpace(name: "PagerViewScrollView")
        .offset(x: -CGFloat(pagerSettings.indexOf(tag: selection) ?? 0) * geometryProxy.size.width)
        .offset(x: translation)
        .animation(style.pagerAnimationOnTap, value: selection)
        .animation(style.pagerAnimationOnSwipe, value: translation)
        .simultaneousGesture(
            DragGesture(minimumDistance: 25).onChanged { value in
                swipeOn = !(edgeSwipeGestureDisabled.contains(.left) &&
                                (selection == pagerSettings.itemsOrderedByIndex.first && value.translation.width > 0) ||
                            edgeSwipeGestureDisabled.contains(.right) &&
                                (selection == pagerSettings.itemsOrderedByIndex.last && value.translation.width < 0))
            }.updating($translation) { value, state, _ in
                if selection == pagerSettings.itemsOrderedByIndex.first && value.translation.width > 0 {
                    let normTrans = value.translation.width / (geometryProxy.size.width + 50)
                    let logValue = log(1 + normTrans)
                    state = geometryProxy.size.width / 1.5 * logValue
                } else if selection == pagerSettings.itemsOrderedByIndex.last && value.translation.width < 0 {
                    let normTrans = -value.translation.width / (geometryProxy.size.width + 50)
                    let logValue = log(1 + normTrans)
                    state = -geometryProxy.size.width / 1.5 * logValue
                } else {
                    state = value.translation.width
                }
            }.onEnded { value in
                let offset = value.predictedEndTranslation.width / geometryProxy.size.width
                let selectionIndex = pagerSettings.indexOf(tag: selection) ?? 0
                let newPredictedIndex = (CGFloat(selectionIndex) - offset).rounded()
                let newIndex = min(max(Int(newPredictedIndex), 0), pagerSettings.items.count - 1)
                if newIndex > selectionIndex {
                    selection = pagerSettings.nextSelection(for: selection)
                } else if newIndex < selectionIndex {
                    selection = pagerSettings.previousSelection(for: selection)
                }
            },
            isEnabled: swipeGestureEnabled && swipeOn
        )
        .onChange(of: translation) { newTranslation in
            let selectionIndex = CGFloat(pagerSettings.indexOf(tag: selection) ?? 0)
            pagerSettings.updateContentOffset(newTranslation - selectionIndex * geometryProxy.size.width)
            swipeOn = true
        }
    }

    @MainActor private var shouldDisableHorizontalBounce: Bool {
        return edgeSwipeGestureDisabled.contains(.left) && selection == pagerSettings.itemsOrderedByIndex.first ||
            edgeSwipeGestureDisabled.contains(.right) && selection == pagerSettings.itemsOrderedByIndex.last
    }

    @MainActor private func updateSelectionIfScrollSettled() {
        guard let newSelection = pagerSettings.settledSelectionForCurrentScrollOffset(),
              newSelection != selection else {
            return
        }

        selection = newSelection
    }

    @MainActor private func updateSelectionToNearestPage() {
        guard let newSelection = pagerSettings.nearestSelectionForCurrentScrollOffset(),
              newSelection != selection else {
            return
        }

        selection = newSelection
    }

}
