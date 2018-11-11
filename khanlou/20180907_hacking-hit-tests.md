title: "Hacking Hit Tests"
date: 
tags: [iOS开发]
categories: [KHANLOU, khanlou.com]
permalink: hacking-hit-tests
keywords: hit test，uikit
custom_title: 
description: 

---
原文链接=http://khanlou.com/2018/09/hacking-hit-tests/
作者=Soroush Khanlou
原文日期=2018-09-07
译者=Nemocdz
校对=校对名
定稿=定稿名

<!--此处开始正文-->

在 [Crusty 教我们使用面向协议编程](https://developer.apple.com/videos/play/wwdc2015/408/)之前，共享代码的实现大多使用继承。在一般的 UIKit 编程中，会用 `UIView` 的子类，添加一些子视图，重写 `-layoutSubviews`，然后重复这些工作。也许你还会重写 `-drawRect`。而在某些特殊情况下，需要做特殊的事情时，就要看看 `UIView` 其他可以重写的方法。

<!--more-->

`UIKit` 有一个更古怪的地方是它的触摸事件处理系统。主要包括两个方法，`-pointInstide:withEvent:` 和 `-hitTest:withEvent:`。

如果给定的某个点在给定的那个视图中，`-pointInside:` 就会告诉调用者。`-hitTest:` 用 `pointInside:` 来告诉调用者哪个子视图（如果有的话）是某个触摸在给定的那个点的接受者。我今天感兴趣的是后者这个方法。

苹果给的文档勉强足够，让我们理解怎么重新实现这个方法。在你学会怎么重新实现方法之前，你都不能改变它的作用。让我们看[文档](https://developer.apple.com/documentation/uikit/uiview/1622469-hittest?language=objc)，尝试写这个函数。

```swift
override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
	// ...
}
```

第一步，我们先开始一些第二段落的工作：

> 这个方法会忽略那些隐藏的， 关闭用户交互功能，或 alpha 通道值小于 0.01 的视图。

让我们使用一些 `gurad` 语句来提前快速处理上面这些情况。

```:bride_with_veil:
override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

	guard isUserInteractionEnabled else { return nil }
	
	guard !isHidden else { return nil }
	
	guard alpha >= 0.01 else { return nil }
			
	// ...
```

相当简单。下一步是？

> 这个方法调用 `pointInside:withEvent:` 方法来遍历视图层级中每一个子视图，来决定哪个子视图应该接收触摸事件。

仔细阅读文档后，听起来 `-pointInside:` 会在每一个子视图里被调用（用一个 for 循环），但这不是完全正确的。

感谢这个[读者](https://twitter.com/an0/status/1038254836016394240)。通过他在 `-hitTest:` 和 `-pointInside:` 中放置了断点的试验，我们知道 `-pointInside:` 在 `self` 中调用（带着其他保护），而不是在每一个子视图中。 所以我们应该添加下面这行代码来进行另外的 guard 语句：

```swift
guard self.point(inside: point, with: event) else { return nil }
```

`-pointInside:` 是 `UIView` 另一个需要重写的点。它的默认实现会检查传入的某个点是否包含在视图的 `bounds` 中。如果调用 `-pointInside` 返回 true，那么意味着触摸事件在它的 bounds 中。

理解完这个小差别后，我们可以跟着文档继续了：

> 如果 `-pointInside:withEvnet:` 返回 YES，那么子视图的层级也会进行类似的遍历直到找到包含指定点的最前面的视图。

所以，从这我们知道我们需要遍历视图树。这意味着循环遍历所有的视图，并调用 `-hitTest:` 在它们每一个上去找到合适的子视图。在这种情况下，这个方法是递归的。

为了遍历视图层级，我们需要一个循环。然而，这个方法其中一个更反人类的是我们需要反向遍历视图。子视图数组中尾部的视图反而在 Z 轴中*更高*，所以它们应该被最先检验。（如果没有这篇[文章](http://smnh.me/hit-testing-in-ios/)，我记不起这个点。）

```swift
// ...
for subview in subviews.reversed() {

}
// ...
```

传入的点被定义在相对于*当前*视图的坐标系统中，而不是在我们关心子视图中。幸运的是，UIKit 给了我们一个处理函数去转换点的参考系到其他任何的视图的 frame 的参考系中。

```swift
// ...
for subview in subviews.reversed() {
	let convertedPoint = subview.convert(point, from: self)
	// ...
}
// ...
```

一旦我们有了转换后的点，我们可以简单地询问每一个子视图它认为在那个点上的视图。提醒一下，如果点在那个视图外面（换句话说，`-pointInside:` 返回 *false*），`-hitTest` 会返回 nil，那么我们应该检查层级里的下一个子视图。

```swift
// ...
let convertedPoint = subview.convert(point, from: self)
if let candidate = subview.hitTest(convertedPoint, with: event) {
	return candidate
}
//...
```

一旦的循环完成，最后一件需要做的事是 `return self`。如果视图是可被点击（被我们的 `guard` 语句断言过的情况），但却没有子视图想要处理这个触摸的话，意味着当前视图，`self`，是这个触摸正确的目标。

这是完整的算法：

```swift
override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
	
	guard isUserInteractionEnabled else { return nil }
	
	guard !isHidden else { return nil }
	
	guard alpha >= 0.01 else { return nil }
	
	guard self.point(inside: point, with: event) else { return nil }	
	
	for subview in subviews.reversed() {
		let convertedPoint = subview.convert(point, from: self)
		if let candidate = subview.hitTest(convertedPoint, with: event) {
			return candidate
		}
	}
	return self
}
```

现在我们有了一个参考的实现，我们可以开始修改它来实现具体的行为。

在之前的这篇播客[《Changing the size of a paging scroll view》](http://khanlou.com/2013/04/changing-the-size-of-a-paging-scroll-view/)中，我就已经讨论过其中一种行为。我谈到一种“落后并该被废弃”的方法来产生这种效果。本质上，你必须：

1. 关掉 `clipsToBounds`
2. 在滑动区域中放一个非隐藏视图
3. 在非隐藏视图上重写 `-hitTest:` 来传递所有触摸到 scrollview 中

`-hitTest:` 方法是这种技术的基石。因为在 UIKit 中，点击测试会被每一个视图代理，由每一个视图来决定那个视图接收它的触摸。这可以让你去重写默认的实现（期望和普通的实现）并替换它为你想做的，甚至返回一个不是原始视图的子视图。多么疯狂。

让我们看一下另一个例子。如果你已经用过 [Beacon](http://beacon.party/) 今年的版本，你会注意到滑动删除事件行为的物理效果感觉上和其他用原生系统实现的效果有点不一样。这是因为用系统的途径不能完全获得我们想要的表现，所以需要自己重新实现这个功能。

如你所想，重写滑动和反弹物理效果不需要那么复杂，所以我们用一个 `UIScrollView` 和将 `pagingEnabled` 设为 true 来获得尽可能自由的反弹力。用和[这篇旧博客](http://khanlou.com/2013/04/changing-the-size-of-a-paging-scroll-view/)里说的类似的技术，我们将滑动的视图的 `bounds` 设置得更小一些并将 `panGestureRecognizer` 移到事件的 cell 顶层的一个覆盖视图中，来设置一个自定义页面大小。

然而，当覆盖视图正确的传递触摸事件到 scroll view 时，那里会有覆盖视图不能正确拦截的其他事件。cell 包含着按钮，像 “join event” 按钮和 “delete event” 按钮，都需要接收触摸。有几种自定义实现在 `-hitTest:` 中可以处理这种情况，其中一种实现就是直接检查这两个按钮的子视图：

```swift
override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

	guard isUserInteractionEnabled else { return nil }
	
	guard !isHidden else { return nil }
	
	guard alpha >= 0.01 else { return nil }

	guard self.point(inside: point, with: event) else { return nil }

	if joinButton.point(inside: convert(point, to: joinButton), with: event) {
		return joinButton
	}
	
	if isDeleteButtonOpen && deleteButton.point(inside: convert(point, to: deleteButton), with: event) {
		return deleteButton
	}
	return super.hitTest(point, with: event)
}
```

这种方法会正确地传递正确的点击事件到正确的的按钮中，而且不用打破显示删除按钮的滑动表现。（你可以尝试只忽略 `deletionOverlay`，不过它不会正确的传递滑动事件。）

`-hitTest:` 是视图中一个很少重写的地方，但是在需要时，可以提供其他工具很难做到的行为。理解如何自己实现有助于你随意替换它。你可以用这个技术去扩大点击的目标区域，去除触摸处理中的某些子视图，而不用将它们从可见的层级中去掉，或者用一个视图作为另一个将响应触摸的视图的兜底。所有东西都是可能的。

