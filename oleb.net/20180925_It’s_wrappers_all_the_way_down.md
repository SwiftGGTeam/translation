# It’s wrappers all the way down

title: It’s wrappers all the way down
date: 2018-09-25
tags: [Swift, Array, Ole Begemann]
categories: [Swift, Array, Ole Begemann]
permalink: oleb-lastindex-reversed

---
原文链接=https://oleb.net/2018/lastindex-reversed/
作者=Ole Begemann
原文日期=2018-09-25
译者=雨谨
校对=
定稿=

假设我们有一个以特定模式结束的字符串，如下面所示：

```swift
let str = "abc,def,…[many fields]…,1234"
```

我们想要提取最后一个字段，即最后一个逗号之后的[子串（substring）](https://developer.apple.com/documentation/swift/substring)，也就是 `"1234"`。

## 拆分整个字符串

一个可选方案就是以逗号为分隔符将字符串拆分为一个数组，然后从中取出最后一个元素：

```swift
if let lastField = str.split(separator: ",").last {
    // lastField 为 "1234" ✅
}
```

但是字符串特别长时，这个方案效率非常低。

## 找出最后一个逗号的位置

更加高效的方案是，找出字符串中最后一个逗号的 index，然后以它为起点，以字符串的终点为终点，取出这个子字符串。从后向前搜索更有意义，不仅因为性能原因（假设最后一个字段很短），还因为前一部分的子串中可能包含我们并不感兴趣的逗号。

## `lastIndex(of:)`

在 Swift 4.2 中解决这个问题特别简单，这要归功于 [Swift Evolution proposal SE-0204](https://github.com/apple/swift-evolution/blob/master/proposals/0204-add-last-methods.md) 中引入的新方法 [last​Index​(of:)](https://developer.apple.com/documentation/swift/bidirectionalcollection/2994840-lastindex)。

```swift
if let lastCommaIndex = str.lastIndex(of: ",") {
    let lastField = str[lastCommaIndex...].dropFirst()
    // → "1234" ✅
}
```

注意 [`dropFirst`](https://developer.apple.com/documentation/swift/sequence/1641008-dropfirst) 的调用。`str[lastCommaIndex...]` 返回的子串是包含逗号的。

## 手动实现

但是让我们假设一下 `lastIndex(of:)` 还没有被引入。我们可以写一个循环来完成这个任务，手动遍历这个字符串（从后面开始），直到匹配成功为止。

让我们把这个算法封装到 [String](https://developer.apple.com/documentation/swift/string) 的 extension 中，以便复用：

```swift
extension String {
    func lastIndex1(of char: Character) -> String.Index? {
        var cursor = endIndex
        while cursor > startIndex {
            formIndex(before: &cursor)
            if self[cursor] == char {
                return cursor
            }
        }
        return nil
    }
}
```

这个代码跟 [标准库中`last​Index​(of:)`的实现](https://github.com/apple/swift/blob/be8849978a8761c766d35e8517d0bff422d2511d/stdlib/public/core/CollectionAlgorithms.swift#L184-L196) 基本一致，除了没使用泛型以外（标准库版的是实现在 [Bidirectional​Collection](https://developer.apple.com/documentation/swift/bidirectionalcollection) 上的）。它可以达到我们的目的：

```swift
if let lastCommaIndex = str.lastIndex1(of: ",") {
    let lastField = str[lastCommaIndex...].dropFirst()
    // → "1234" ✅
}
```

## 通过组合 `reversed` 和 `firstIndex(of:)`

这很好，但是还有另一个方法来解决这个问题，这也是我今天想在这篇文章中讨论的 - 并不因为它是一个特别实用的例子，而是因为我认为可以从中学到很多 Swift 标准库的设计模式。

我们还可以通过如下方式组合 [Collection](https://developer.apple.com/documentation/swift/collection) 的其他 API，实现我们自己的 `last​Index​(of:)`。

```swift
extension String {
    func lastIndex2(of char: Character) -> String.Index? {
        guard let reversedIndex = str
            .reversed()
            .firstIndex(of: char)
        else {
            return nil
        }
        return index(before: reversedIndex.base)
    }
}
```

它的逻辑可能不怎么直观，所以让我们一步步的解释一下。`guard` 语句首先翻转字符串，然后查找目标字符的 index。

```swift
guard let reversedIndex = str
    .reversed()
    .firstIndex(of: char)
```

翻转字符串很好理解，因为我们希望从它的末尾开始查找，但它会引发两个疑问：

1. 翻转整个字符串是否太过浪费？
2. 翻转的字符串的 index 有什么用？可以将它转回原字符串的 index 吗？

### 1. 翻转整个字符串是否太过浪费？

答案：不，因为 [reversed](https://developer.apple.com/documentation/swift/bidirectionalcollection/1782128-reversed) 是 [懒加载](https://en.wikipedia.org/wiki/Lazy_evaluation) 的。`reversed` 方法并没有做任何事情，[它所做的](https://github.com/apple/swift/blob/01644d5854023cb00bd191a0bc813fdf6f5f9470/stdlib/public/core/Reverse.swift#L292-L294) 只是将输入封装成一个 `Reversed​Collection` 值。

```swift
extension BidirectionalCollection {
    func reversed2() -> ReversedCollection2<Self> {
        return ReversedCollection2(base: self)
    }
}
```

（这段代码和接下来的代码都是我自己实现的 `ReversedCollection`。为了避免跟标准库的冲突，我将它命名为 `Reversed​Collection2`，不过两者的实现都差不多。）

从本质上讲，`Reversed​Collection` 只是 `Bidirectional​Collection` 的一个简单的泛型封装。

```swift
struct ReversedCollection2<Base: BidirectionalCollection> {
    var base: Base
}
```

即便输入的字符串有好几兆（M）长，调用 `reversed()` 实际上也是免费的，因为 [`String`](https://developer.apple.com/documentation/swift/string) 使用了 [写时拷贝](https://en.wikipedia.org/wiki/Copy-on-write) 的机制。只有当某个数据被修改时，真实的字符串数据才会被拷贝。

### 遵守 `Collection`

然后，上面的代码在 `Reversed​Collection` 上调用了 `first​Index​(of:)` (`firstIndex(of:)` 也就是 [Swift 4.2](https://github.com/apple/swift-evolution/blob/master/proposals/0204-add-last-methods.md#detailed-design) 之前的 `index(of:)`)。`firstIndex(of:)` 是 [`Collection`](https://developer.apple.com/documentation/swift/collection) 协议的一部分，因此 `Reversed​Collection` 必须遵守 `Collection`。让我们详细过一遍这个约束的新实现。

#### Index 类型

每个 `Collection` 都必须有一个 [index 类型](https://developer.apple.com/documentation/swift/collection/2943866-index)。对于 `Reversed​Collection`，我们可以使用处理 collection 的思路来处理我们的 index： 这个 index 类型应该是原 collection 的 index 的一个简单封装：

```swift
extension ReversedCollection2 {
    struct Index {
        var base: Base.Index
    }
}
```

Collection 的 index 必须是可以比较的（[Comparable](https://developer.apple.com/documentation/swift/comparable)），所以我们也必须添加这个约束。因为我们知道 `base` 值也是 `Comparable` 的，所以在自己的实现中，我们可以将比较的判断传递给它。不过需要注意的是，我们必须要将这个逻辑倒置过来，因为我们的 index 类型必须体现倒置关系： *最大的* `base` index 代表着 *最小的* 翻转的 index，反之亦然。

```swift
extension ReversedCollection2.Index: Comparable {
    static func <(lhs: ReversedCollection2.Index, rhs: ReversedCollection2.Index) -> Bool {
        // 将 base 的逻辑倒置过来
        return lhs.base > rhs.base
    }
}
```

#### `Collection` 的实现

打好上面的基础后，我们就可以添加 `Collection` 约束了。基本思想是基于原 collection 来完成我们的实现，记住，倒置所有东西：倒置的 collection 的 [`startIndex`](https://developer.apple.com/documentation/swift/collection/2946080-startindex) 是原 collection 的 [`endIndex`](https://developer.apple.com/documentation/swift/collection/2944204-endindex)（反之亦然），[`index(after:)`](https://developer.apple.com/documentation/swift/collection/2943746-index) 应该调用 [`base​.index​(before:)`](https://developer.apple.com/documentation/swift/bidirectionalcollection/1783013-index)，等等。

```swift
extension ReversedCollection2: Collection {
    typealias Element = Base.Element

    var startIndex: Index {
        return Index(base: base.endIndex)
    }

    var endIndex: Index {
        return Index(base: base.startIndex)
    }

    func index(after idx: Index) -> Index {
        return Index(base: base.index(before: idx.base))
    }

    subscript(position: Index) -> Element {
        return base[base.index(before: position.base)]
    }
}
```

顺便说一句，我们依赖于 `base​.index​(before:)`，因此 `Reversed​Collection` 的泛型参数必须是 `Bidirectional​Collection` 类型。一个纯 `Collection` 是没有 `index(before:)` 方法，因此也不能逆向遍历。

还有一点需要注意：一个 collection 的 `endIndex` 代表着 “最后一个元素的后一位” 的位置，而不是最后一个元素的位置。将 `base​.endIndex` 作为倒置的 collection 的 `startIndex`，我们实际上把所有倒置的 index 都向右移动了一位。这就是为什么在实现元素的下标访问时，我们是使用 `base.index(before: position.base)`，而非 `position.base`。

#### 从上到下都是封装

回到我们之前讨论的 `lastIndex2` 实现体中的那个代码片段，这个表达式：

```swift
str.reversed().firstIndex(of: char)
// 类型: Reversed​Collection​<String>​.Index?
```

返回的是一个可选的 `Reversed​Collection​<String>​.Index`，如我们所见，是未翻转的字符串中对应 index 的一个封装。

### 2. 可以将它转回原字符串的 index 吗？

答案：是的，因为 `Reversed​Collection` 在标准库中的实现，跟我在这所展示的差不多，只是再多些了花哨的东西。[这里是源码](https://github.com/apple/swift/blob/01644d5854023cb00bd191a0bc813fdf6f5f9470/stdlib/public/core/Reverse.swift#L205-L250)。

幸运的是，[Reversed​Collection​.Index​.base](https://developer.apple.com/documentation/swift/reversedcollection/index/2965437-base) 是 public 的（`ReversedCollection​._base` 也是 public 的，虽然被代码自动补全隐藏了），这就允许我们从倒置的 index 中获取底层原 collection 的 index。跟上面的一样，我们必须记得将 index 移动回去，正如文档中提醒的那样：

> 要找到这个 index 在原来的底层的 collection 中对应的位置，请使用 collection 的 `index(before:)` 方法，并传入 base 属性。

这就是为什么我们实现的 `lastIndex2` 的最后一行返回的是匹配成功的*前一个* index：

```swift
return index(before: reversedIndex.base)
```

## 结论

可以说，以上是毫无意义的练习，没有多少实际意义。但是，我相信理解这种方法的原理和原因可以教会你很多标准库中集合类型和协议结构的设计思路。[`Sequence`](https://developer.apple.com/documentation/swift/sequence) 和 `Collection` API 都被设计成为可以组合的，并提供了很多有用的操作，以便实现你自己的算法。Dave Abrahams 的 [WWDC 2018 talk Embracing Algorithms](https://developer.apple.com/videos/play/wwdc2018/223/) 提供了一些非常好的例子教你如何使用。这是我最喜欢的 WWDC 2018 session 了。

`Reversed​Collection` 并不是标准库中唯一的惰性 sequence/collection 封装器。[`enumerated`](https://developer.apple.com/documentation/swift/sequence/1641222-enumerated)，[`joined`](https://developer.apple.com/documentation/swift/sequence/2431985-joined) 和 [`zip`](https://developer.apple.com/documentation/swift/1541125-zip) 都是这样工作的。

此外，通过使用 [`lazy`](https://developer.apple.com/documentation/swift/sequence/1641562-lazy)，你可以应用同样的通用模式获取一个封装，用来延迟执行 [`map`](https://developer.apple.com/documentation/swift/lazysequence/2905499-map)，[`filter`](https://developer.apple.com/documentation/swift/lazysequence/2908552-filter) 和其他常规的即时（eager）操作 - 不同于我们之前讨论的封装，这些封装不仅存储原 collection，还存储你传入的转换函数。

为什么有些操作总是惰性的，而其他操作在默认情况下都是即时的呢？标准库现在的策略是 [如果惰性实现是“毫无疑问地'免费'"的，那就默认使用惰性](https://forums.swift.org/t/add-various-zip-related-types-and-operations/13806/9)。另一方面，如果 [惰性实现存在明显的弊端](https://forums.swift.org/t/add-various-zip-related-types-and-operations/13806/40)，那就使用 `lazy` 属性提供惰性版本。Ben Cohen 说：

> 例如，`lazy.map` 每次迭代都执行映射操作，可能导致多次迭代变得非常昂贵。同时，如果闭包是有状态的，捕获并存储映射闭包还可能有风险。