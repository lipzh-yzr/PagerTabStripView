//
//  PagerTabStripView.swift
//  PagerTabStripView
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//
import SwiftUI

public struct HorizontalContainerEdge: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let left = HorizontalContainerEdge(rawValue: 1 << 0)
    public static let right = HorizontalContainerEdge(rawValue: 1 << 1)

    public static let both: HorizontalContainerEdge = [.left, .right]
}

@available(iOS 17.0, macOS 14.0, *)
public struct PagerTabStripView<SelectionType, Content>: View where SelectionType: Hashable, Content: View {
    private var content: () -> Content
    private var navigationBar: (() -> AnyView)?
    private var swipeGestureEnabled: Binding<Bool>
    private var edgeSwipeGestureDisabled: Binding<HorizontalContainerEdge>
    private var selection: Binding<SelectionType>?
    @State private var internalSelection: SelectionType

    public init(swipeGestureEnabled: Binding<Bool> = .constant(true),
                edgeSwipeGestureDisabled: Binding<HorizontalContainerEdge> = .constant([]),
                selection: Binding<SelectionType>, @ViewBuilder content: @escaping () -> Content) {
        self.swipeGestureEnabled = swipeGestureEnabled
        self.edgeSwipeGestureDisabled = edgeSwipeGestureDisabled
        self.selection = selection
        self._internalSelection = State(initialValue: selection.wrappedValue)
        self.navigationBar = nil
        self.content = content
    }

    public init<NavigationBar>(swipeGestureEnabled: Binding<Bool> = .constant(true),
                               edgeSwipeGestureDisabled: Binding<HorizontalContainerEdge> = .constant([]),
                               selection: Binding<SelectionType>,
                               @ViewBuilder content: @escaping () -> Content,
                               @ViewBuilder navigationBar: @escaping () -> NavigationBar) where NavigationBar: View {
        self.swipeGestureEnabled = swipeGestureEnabled
        self.edgeSwipeGestureDisabled = edgeSwipeGestureDisabled
        self.selection = selection
        self._internalSelection = State(initialValue: selection.wrappedValue)
        self.navigationBar = { AnyView(navigationBar()) }
        self.content = content
    }

    @MainActor public var body: some View {
        let selection = selection ?? $internalSelection
        WrapperPagerTabStripView(swipeGestureEnabled: swipeGestureEnabled,
                                 edgeSwipeGestureDisabled: edgeSwipeGestureDisabled,
                                 selection: selection,
                                 navigationBar: navigationBar,
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
        self.navigationBar = nil
        self.content = content
    }

    public init<NavigationBar>(swipeGestureEnabled: Binding<Bool> = .constant(true),
                               edgeSwipeGestureDisabled: Binding<HorizontalContainerEdge> = .constant([]),
                               @ViewBuilder content: @escaping () -> Content,
                               @ViewBuilder navigationBar: @escaping () -> NavigationBar) where NavigationBar: View {
        self.swipeGestureEnabled = swipeGestureEnabled
        self.edgeSwipeGestureDisabled = edgeSwipeGestureDisabled
        self.selection = nil
        self._internalSelection = State(initialValue: 0)
        self.navigationBar = { AnyView(navigationBar()) }
        self.content = content
    }
}

private struct WrapperPagerTabStripView<SelectionType, Content>: View where SelectionType: Hashable, Content: View {

    private var content: Content
    private var navigationBar: (() -> AnyView)?
    @State private var pagerSettings = PagerSettings<SelectionType>()
    @Environment(\.pagerStyle) var style: PagerStyle
    @Binding private var selection: SelectionType
    @GestureState private var translation: CGFloat = 0
    @Binding private var swipeGestureEnabled: Bool
    @Binding private var edgeSwipeGestureDisabled: HorizontalContainerEdge
    @State private var swipeOn: Bool = true

    public init(swipeGestureEnabled: Binding<Bool>,
                edgeSwipeGestureDisabled: Binding<HorizontalContainerEdge>,
                selection: Binding<SelectionType>,
                navigationBar: (() -> AnyView)?,
                @ViewBuilder content: @escaping () -> Content) {
        self._swipeGestureEnabled = swipeGestureEnabled
        self._edgeSwipeGestureDisabled = edgeSwipeGestureDisabled
        self._selection = selection
        self.navigationBar = navigationBar
        self.content = content()
    }

    @MainActor public var body: some View {
        GeometryReader { geometryProxy in
            HStack(spacing: 0) {
                content
                    .frame(width: geometryProxy.size.width)
            }
            .coordinateSpace(name: "PagerViewScrollView")
            .offset(x: -CGFloat(pagerSettings.indexOf(tag: selection) ?? 0) * geometryProxy.size.width)
            .offset(x: translation)
            .animation(style.pagerAnimationOnTap, value: selection)
            .animation(style.pagerAnimationOnSwipe, value: translation)
            .gesture(swipeGestureEnabled && swipeOn ?
                        DragGesture(minimumDistance: 25).onChanged { value in
                            swipeOn = !(edgeSwipeGestureDisabled.contains(.left) &&
                                            (selection == pagerSettings.itemsOrderedByIndex.first && value.translation.width > 0) ||
                                            edgeSwipeGestureDisabled.contains(.right) &&
                                            (selection == pagerSettings.itemsOrderedByIndex.last && value.translation.width < 0))
                        }.updating($translation) { value, state, _ in
                            if selection == pagerSettings.itemsOrderedByIndex.first && value.translation.width > 0 {
                                let normTrans = value.translation.width / (geometryProxy.size.width + 50)
                                let logValue = log(1 + normTrans)
                                state = geometryProxy.size.width/1.5 * logValue
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
                                selection =  pagerSettings.nextSelection(for: selection)
                            } else if newIndex < selectionIndex {
                                selection = pagerSettings.previousSelection(for: selection)
                            }
                        }
                        : nil)
            .onAppear {
                let frame = geometryProxy.frame(in: .local)
                pagerSettings.width = frame.width
                if let index = pagerSettings.indexOf(tag: selection) {
                    pagerSettings.contentOffset = -CGFloat(index) * frame.width
                }
            }
            .onChange(of: pagerSettings.itemsOrderedByIndex) {
                pagerSettings.contentOffset = -(CGFloat(pagerSettings.indexOf(tag: selection) ?? 0) * geometryProxy.size.width)
            }
            .onChange(of: geometryProxy.frame(in: .local)) { _, geometry in
                pagerSettings.width = geometry.width
                if let index = pagerSettings.indexOf(tag: selection) {
                    pagerSettings.contentOffset = -(CGFloat(index)) * geometry.width
                }
            }
            .onChange(of: selection) { _, newSelection in
                pagerSettings.contentOffset = -(CGFloat(pagerSettings.indexOf(tag: newSelection) ?? 0) * geometryProxy.size.width)
                swipeOn = true
            }
            .onChange(of: translation) {
                pagerSettings.contentOffset = translation - (CGFloat(pagerSettings.indexOf(tag: selection) ?? 0) * geometryProxy.size.width)
                swipeOn = true
            }
        }
        .modifier(NavBarModifier(selection: $selection,
                                 pagerSettings: pagerSettings,
                                 navigationBar: navigationBar))
        .environment(pagerSettings)
        .preference(key: PagerSettingsPreferenceKey<SelectionType>.self,
                    value: PagerSettingsPreferenceValue(settings: pagerSettings))
        .clipped()
    }

}

private struct PagerSettingsPreferenceValue<SelectionType>: Equatable where SelectionType: Hashable {
    let settings: PagerSettings<SelectionType>?

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs.settings, rhs.settings) {
        case (.none, .none):
            return true
        case let (.some(lhsSettings), .some(rhsSettings)):
            return lhsSettings === rhsSettings
        default:
            return false
        }
    }
}

private struct PagerSettingsPreferenceKey<SelectionType>: PreferenceKey where SelectionType: Hashable {
    static var defaultValue: PagerSettingsPreferenceValue<SelectionType> {
        PagerSettingsPreferenceValue(settings: nil)
    }

    static func reduce(value: inout PagerSettingsPreferenceValue<SelectionType>,
                       nextValue: () -> PagerSettingsPreferenceValue<SelectionType>) {
        value = nextValue()
    }
}

extension View {

    public func onPagerSettingsChange<SelectionType>(
        for selectionType: SelectionType.Type,
        perform action: @escaping (PagerSettings<SelectionType>?) -> Void
    ) -> some View where SelectionType: Hashable {
        onPreferenceChange(PagerSettingsPreferenceKey<SelectionType>.self) { value in
            action(value.settings)
        }
    }
}
