![PagerTabStripView: First pager view built in pure SwiftUI](https://raw.githubusercontent.com/xmartlabs/PagerTabStripView/master/banner.png)

<p align="left">
<a href="https://github.com/xmartlabs/PagerTabStripView/actions/workflows/build-test.yml"><img src="https://github.com/xmartlabs/PagerTabStripView/actions/workflows/build-test.yml/badge.svg" alt="build and test" /></a>
<img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" />
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift5-compatible-4BC51D.svg?style=flat" alt="Swift 5 compatible" /></a>
<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage compatible" /></a>
<a href="https://cocoapods.org/pods/PagerTabStripView"><img src="https://img.shields.io/cocoapods/v/PagerTabStripView.svg" alt="CocoaPods compatible" /></a>
<a href="https://raw.githubusercontent.com/xmartlabs/PagerTabStripView/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>
</p>

Made with :heart: by [Xmartlabs](http://xmartlabs.com) team. [XLPagerTabStrip](https://github.com/xmartlabs/XLPagerTabStrip) for SwiftUI!

## Introduction

PagerTabStripView is the first pager view built in pure SwiftUI. It provides a component to create interactive pager views which contains child views. It allows the user to switch between your views either by swiping or tapping a tab bar item.

<table>
  <tr>
    <th><img src="Example/Media/twitterStyleExample.gif" width="250"/></th>
    <th><img src="Example/Media/instagramStyleExample.gif" width="250"/></th>
    <th><img src="Example/Media/LogOutExample.gif" width="250"/></th>
    <th><img src="Example/Media/scrollableStyleExample.gif" width="250"/></th>
  </tr>
</table>

Unlike Apple's TabView it provides:

1. Flexible way to fully customize pager tab views.
2. Each pager tab item view can be of different type.
3. Bar that contains pager tab item is placed on top.
4. Indicator view indicates selected child view.
5. Ability to update pager tab items according to highlighted, selected, normal state.
6. Ability to embed one page within another and not breaking scroll behavior. 
7. Ability to update UI according page selection and transition progress among pages. 

## Usage

Creating a page view is straightforward: lay out `NavBarWrapperView` wherever you want the pager navigation to appear, then place `PagerTabStripView` where the pages should render. Pass the same ordered data to the navigation bar and the pager pages so the tab identifiers match the page order.
The `id` parameter is the value that identifies each tab item. It can be any `Hashable` value and it must be unique.

```swift
import PagerTabStripView

private struct Page: Identifiable {
    let id: Int
    let title: String
}

struct MyPagerView: View {
    @State private var selection = 0

    private let pages = [
        Page(id: 0, title: "Tab 1"),
        Page(id: 1, title: "Tab 2"),
        Page(id: 2, title: "Profile")
    ]

    var body: some View {
        VStack(spacing: 0) {
            NavBarWrapperView(pages, id: \.id, selection: $selection) { page in
                TitleNavBarItem(title: page.title)
            }

            PagerTabStripView(selection: $selection) {
                ForEach(pages) { page in
                    switch page.id {
                    case 0:
                        MyFirstView()
                    case 1:
                        MySecondView()
                    default:
                        MyProfileView()
                    }
                }
            }
        }
        .pagerContext(Int.self)
    }
}
```

<div style="text-align:center">
    <img src="Example/Media/defaultExample.gif">
</div>

</br>
</br>

To specify the initial selected page you can pass the `selection` init parameter to both `NavBarWrapperView` and `PagerTabStripView` (for it to work properly this value has to be equal to one of the tab ids).

```swift
struct MyPagerView: View {

    @State var selection = 1
    let pages = [1, 2, 3]

    var body: some View {
        VStack(spacing: 0) {
            NavBarWrapperView(pages, id: \.self, selection: $selection) { page in
                TitleNavBarItem(title: "Tab \(page)")
            }

            PagerTabStripView(selection: $selection) {
                MyFirstView()
                ...
            }
        }
        .pagerContext(Int.self)
    }
}
```

As you may've already noticed, everything is SwiftUI code, so you can update the child views according to SwiftUI state objects as shown above with `if User.isLoggedIn`.

The user can also configure whether swipe paging is enabled and which horizontal edges should disable edge swiping.

Params:
- `swipeGestureEnabled`: Whether swipe paging is enabled (default is true).
- `edgeSwipeGestureDisabled`: A `HorizontalContainerEdge` `OptionSet`; available options are `.left` and `.right` (default is an empty set).

Why is this parameter important?
This parameter is important in the context of the next PagerTabStripView example in `MyPagerView2`. If the pager is on the first page and the user tries to swipe left, the pager's horizontal scroll can compete with the parent container gesture. The `edgeSwipeGestureDisabled` parameter prevents that edge swipe from being handled by the pager.

```swift
struct MyPagerView2: View {

    @State var selection = 1

    var body: some View {
        VStack(spacing: 0) {
            NavBarWrapperView([1, 2], id: \.self, selection: $selection) { page in
                TitleNavBarItem(title: "Tab \(page)")
            }

            PagerTabStripView(edgeSwipeGestureDisabled: .constant([.left]),
                              selection: $selection) {
                MyFirstView()
                ...
            }
        }
        .pagerContext(Int.self)
    }
}
```

Every pager needs a pager context whose type matches the tab tags. For example, use `.pagerContext(Int.self)` for `Int` tags, `.pagerContext(String.self)` for `String` tags, or `.pagerContext(MyPage.self)` for a custom `Hashable` enum. Add the modifier to the pager hierarchy after creating the pager and applying its style. Nested pagers should each get their own pager context.

### Customizing the pager style

PagerTabStripView provides 4 built-in styles, selected with the `pagerTabStripViewStyle` modifier:

- `.scrollableBarButton(...)`: horizontal scrolling tab bar for many pages.
- `.barButton(...)`: fixed-width tab bar for small page counts.
- `.bar(...)`: indicator-only bar.
- `.segmentedControl(...)`: segmented picker.

The pager never inserts navigation UI by itself. Put `NavBarWrapperView` directly in a `VStack`, a toolbar item, or any other layout owned by your app.

```swift
struct PagerView: View {
    @State var selection = 1
    let pages = [1, 2]

    var body: some View {
        VStack(spacing: 0) {
            NavBarWrapperView(pages, id: \.self, selection: $selection) { page in
                TitleNavBarItem(title: page == 1 ? "First big width" : "Short")
            }

            PagerTabStripView(selection: $selection) {
                MyView()
                AnotherView()
            }
        }
        .pagerTabStripViewStyle(.scrollableBarButton(tabItemSpacing: 15,
                                                     tabItemHeight: 50,
                                                     indicatorView: {
                                                        Rectangle().fill(.blue).cornerRadius(5)
                                                     }))
        .pagerContext(Int.self)
    }
}
```

Common style settings:

- `pagerAnimationOnTap`: Animation used when the selection changes.
- `pagerAnimationOnSwipe`: Animation used when the drag gesture changes the translation.
- `tabItemSpacing`, `tabItemHeight`, `padding`: Available on bar-button styles.
- `barBackgroundView`, `indicatorViewHeight`, `indicatorView`: Available on indicator styles.
- `backgroundColor`, `padding`: Available on segmented style.

For toolbar placement, put `NavBarWrapperView` in your own toolbar:

```swift
PagerTabStripView(selection: $selection) {
    GalleryView()
    ListView()
}
.toolbar {
    ToolbarItem(placement: .principal) {
        NavBarWrapperView(pages, id: \.self, selection: $selection) { page in
            Image(systemName: page.iconName)
        }
    }
}
.pagerTabStripViewStyle(.scrollableBarButton())
.pagerContext(Page.self)
```

<div style="text-align:center">
    <img src="Example/Media/scrollableStyleExample.gif">
</div>

## Navigation bar

The navigation bar supports custom tab bar views for each page. You provide each tab item in the `NavBarWrapperView` content builder.

For simplicity, we are going to implement a nav bar item with only a title. You can find more examples in the example app.

```swift
struct TitleNavBarItem: View {
    let title: String

    var body: some View {
        VStack {
            Text(title)
                .foregroundColor(Color.gray)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
```

If your custom navigation item needs transition progress, read the `PagerSettings` environment value. Because PagerTabStripView uses Perception internally, wrap the body in `WithPerceptionTracking` when observing pager state.

```swift
import SwiftUI
import PagerTabStripView
import Perception

struct ProgressNavBarItem<SelectionType: Hashable>: View {
    @Environment(PagerSettings<SelectionType>.self) private var pagerSettings

    let title: String
    let tag: SelectionType

    var body: some View {
        WithPerceptionTracking {
            Text(title)
                .opacity(0.4 + pagerSettings.transition.progress(for: tag) * 0.6)
        }
    }
}
```

To use transition progress, pass the same tag into your custom tab item:

```swift
NavBarWrapperView(pages, id: \.self, selection: $selection) { page in
    ProgressNavBarItem(title: page.title, tag: page)
}

PagerTabStripView(selection: $selection) {
    ForEach(pages, id: \.self) { page in
        pageView(for: page)
    }
}
.pagerContext(Page.self)
```

<div style="text-align:center">
    <img src="Example/Media/setStateCallback.gif">
</div>

## Examples

Follow these 3 steps to run Example project

- Clone PagerTabStripView repo.
- Open PagerTabStripView workspace.
- Run the _Example_ project.

## Installation

### Swift Package Manager

Add PagerTabStripView as a package dependency:

```swift
.package(url: "https://github.com/xmartlabs/PagerTabStripView.git", branch: "master")
```

The package depends on [SwiftUIX](https://github.com/SwiftUIX/SwiftUIX) and [swift-perception](https://github.com/pointfreeco/swift-perception).

### CocoaPods

To install PagerTabStripView using CocoaPods, simply add the following line to your Podfile:

```ruby
pod 'PagerTabStripView', '~> 4.0'
```

### Carthage

To install PagerTabStripView using Carthage, simply add the following line to your Cartfile:

```ruby
github "xmartlabs/PagerTabStripView" ~> 4.0
```

## Requirements

- iOS 15+
- macOS 14+
- Swift 5.9+
- Xcode 15+

## Author

- [Xmartlabs SRL](https://github.com/xmartlabs) ([@xmartlabs](https://twitter.com/xmartlabs))

## Getting involved

- If you **want to contribute** feel free to **submit pull requests**.
- If you **have a feature request** please **open an issue**.
- If you **found a bug** or **need help** please **check older issues and threads on [StackOverflow](http://stackoverflow.com/questions/tagged/PagerTabStripView) (Tag 'PagerTabStripView') before submitting an issue**.

Before contributing, be sure to check the [CONTRIBUTING](https://github.com/xmartlabs/PagerTabStripView/blob/master/CONTRIBUTING.md) file for more info.

We'd love to hear about your experience with **PagerTabStripView**. If you use it in your app, drop us a line on [Twitter](https://twitter.com/xmartlabs).
