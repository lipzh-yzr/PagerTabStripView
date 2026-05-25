//
//  pagerSettings.swift
//  PagerTabStripView
//
//  Copyright © 2022 Xmartlabs SRL. All rights reserved.
//

import Perception
import SwiftUI

struct DataItem<SelectedType>: Identifiable, Equatable where SelectedType: Hashable {

    static func == (lhs: DataItem<SelectedType>, rhs: DataItem<SelectedType>) -> Bool {
        return lhs.tag == rhs.tag
    }
    private(set) var tag: SelectedType
    fileprivate(set) var view: AnyView
    fileprivate(set) var index: Int

    var id: SelectedType { tag }

    fileprivate init(tag: SelectedType, index: Int, view: AnyView) {
        self.tag = tag
        self.index = index
        self.view = view
    }
}

public enum TransitionProgress<SelectionType: Hashable>: Equatable {
    case none
    case transition(from: SelectionType?, to: SelectionType?, percentage: Double)

    fileprivate init(from: SelectionType?, to: SelectionType?, percentage: Double) {
        if from == nil && to == nil {
            self = .none
        }
        self = .transition(from: from, to: to, percentage: percentage)
    }

    // swiftlint:disable:next cyclomatic_complexity
    public static func == (lhs: TransitionProgress<SelectionType>, rhs: TransitionProgress<SelectionType>) -> Bool {
        switch (lhs, rhs) {
        case (.none, .transition),
             (.transition, .none):
            return false
        case (.none, .none):
            return true
        case (.transition(let from, let to, let percentage), .transition(let from2, let to2, let percentage2)):
            guard percentage == percentage2 else { return false }
            switch (from, from2) {
            case (.some, .none), (.none, .some):
                return false
            case (.some(let lhs), .some(let rhs)):
                guard  lhs == rhs else { return false }
            case (.none, .none):
                break
            }
            switch (to, to2) {
            case (.some, .none), (.none, .some):
                return false
            case (.some(let lhs), .some(let rhs)):
                guard lhs == rhs else { return false }
            case (.none, .none):
                break
            }
        }
        return true
    }

    private var percetage: Double {
        switch self {
        case .none:
            return 0
        case .transition(_, _, let percentage):
            return percentage
        }
    }

    private var fromSelection: SelectionType? {
        switch self {
        case .none:
            return nil
        case .transition(let from, _, _):
            return from
        }
    }

    private var toSelection: SelectionType? {
        switch self {
        case .none:
            return nil
        case .transition(_, let to, _):
            return to
        }
    }

    public func progress(for tag: SelectionType) -> Double {
        if let fromSelection, fromSelection == tag {
            return 1 - percetage
        } else if let toSelection, toSelection == tag {
            return percetage
        }
        return 0
    }
}

@MainActor
@Perceptible
public final class PagerSettings<SelectionType> where SelectionType: Hashable {

    var width: CGFloat = 0 {
        didSet {
            recalculateTransition()
        }
    }

    var contentOffset: CGFloat = 0 {
        didSet {
            recalculateTransition()
        }
    }

    var scrollContentOffset: CGPoint = .zero {
        didSet {
            syncContentOffsetWithScrollContentOffset()
        }
    }

    public private(set) var transition = TransitionProgress<SelectionType>.none

    private(set) var items = [SelectionType: DataItem<SelectionType>]() {
        didSet {
            itemsOrderedByIndex = items.values.sorted { $0.index < $1.index }.map { $0.tag }
        }
    }
    private(set) var itemsOrderedByIndex = [SelectionType]()

    public init() {}

    func updateWidth(_ width: CGFloat, selection: SelectionType) {
        self.width = width
        updateScrollContentOffset(for: selection)
    }

    func updateScrollContentOffset(_ contentOffset: CGPoint) {
        scrollContentOffset = contentOffset
    }

    func updateContentOffset(_ contentOffset: CGFloat) {
        self.contentOffset = contentOffset
        let scrollOffset = CGPoint(x: -contentOffset, y: scrollContentOffset.y)

        if scrollContentOffset != scrollOffset {
            scrollContentOffset = scrollOffset
        }
    }

    func updateScrollContentOffset(for selection: SelectionType) {
        guard let scrollOffset = scrollContentOffset(for: selection) else {
            return
        }

        updateScrollContentOffset(scrollOffset)
    }

    func nearestSelectionForCurrentScrollOffset() -> SelectionType? {
        guard width > 0 else {
            return nil
        }

        let index = Int(round(scrollContentOffset.x / width))

        return itemsOrderedByIndex[safe: index]
    }

    func settledSelectionForCurrentScrollOffset(tolerance: CGFloat = 1) -> SelectionType? {
        guard width > 0 else {
            return nil
        }

        let rawIndex = scrollContentOffset.x / width
        let roundedIndex = round(rawIndex)
        let distance = abs(scrollContentOffset.x - roundedIndex * width)

        guard distance <= tolerance else {
            return nil
        }

        return itemsOrderedByIndex[safe: Int(roundedIndex)]
    }

    private func recalculateTransition() {
        let indexAndPercentage = width == 0 ? 0 : -contentOffset / width
        let percentage = (indexAndPercentage + 1).truncatingRemainder(dividingBy: 1)
        let lowIndex = Int(floor(indexAndPercentage))
        transition = TransitionProgress(from: itemsOrderedByIndex[safe: lowIndex], to: itemsOrderedByIndex[safe: lowIndex+1], percentage: percentage)
    }

    func createOrUpdate<TabView: View>(tag: SelectionType, index: Int, view: TabView) {
        if var dataItem = items[tag] {
            dataItem.index = index
            dataItem.view = AnyView(view)
            items[tag] = dataItem
        } else {
            items[tag] = DataItem(tag: tag, index: index, view: AnyView(view))
        }
    }

    func remove(tag: SelectionType) {
        items.removeValue(forKey: tag)
    }

    func nextSelection(for selection: SelectionType) -> SelectionType {
        guard let selectionIndex = itemsOrderedByIndex.firstIndex(of: selection) else {
            return self.itemsOrderedByIndex.first!
        }
        return itemsOrderedByIndex[safe: selectionIndex + 1] ?? selection
    }

    func previousSelection(for selection: SelectionType) -> SelectionType {
        guard let selectionIndex = itemsOrderedByIndex.firstIndex(of: selection) else {
            return itemsOrderedByIndex.first!
        }
        return itemsOrderedByIndex[safe: selectionIndex - 1] ?? selection
    }

    func indexOf(tag: SelectionType) -> Int? {
        return itemsOrderedByIndex.firstIndex(of: tag)
    }

    private func scrollContentOffset(for selection: SelectionType) -> CGPoint? {
        guard let index = indexOf(tag: selection) else {
            return nil
        }

        return CGPoint(x: CGFloat(index) * width, y: scrollContentOffset.y)
    }

    private func syncContentOffsetWithScrollContentOffset() {
        let contentOffset = -scrollContentOffset.x

        if self.contentOffset != contentOffset {
            self.contentOffset = contentOffset
        }
    }
}
