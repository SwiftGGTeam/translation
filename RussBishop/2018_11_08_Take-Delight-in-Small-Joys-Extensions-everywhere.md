title: "每一点进步都是快乐：无处不在的扩展"
date: 
tags: [iOS]
categories: [Russ Bishop]
permalink: extensions-everywhere
keywords: ios
description: Swift 扩展的应用

---

原文链接=http://www.russbishop.net/take-delight-in-small-joys
作者=Russ Bishop 
原文日期=2018-11-08 
译者=俊东 
校对=xxx 
定稿=xxx

这是关于一点小工作的分享。关于我在 Swift 中那种自然扩展中的体会。

我认为 `UnsafeMutableRawBufferPointer.baseAddress` 是可选项这回事非常不合理。它使得这种类型在实践中使用起来非常困难。我也不喜欢在分配时指定对齐方式;在大多数平台上，合理的默认值都是 `Int.bitWidth / 8`。

通过扩展，我们可以很容易地解决这些问题。这样的解决方案能像标准库一样自然地使用。
<!--more-->

首先，我们需要在调试版本中进行简单的健全性检查，以确保我们不会产生无意义的对齐计算。这里提一个有关正整数的小技巧：一个 2 的 n 次幂数只有一个比特位是有值的。减去 1 时就是把后面的所有比特位设置为 1，如 8（`0b1000`）- 1 得到 7（`0b0111`）。这两个数字没有共同的位，因此按位取与应该产生零。由于这规律在零上无效，所以我们分别检查。

```swift
extension BinaryInteger {
    var isPositivePowerOf2: Bool {
        @inline(__always)
        get {
            return (self & (self - 1)) == 0 && self != 0
        }
    }
}
```

现在让我们默认使用自然整数宽度对齐。这种对齐能做的事情比我们需要的更多，但我们只需要关心存储在缓冲区中的内容就足够的。虽然断言仅在调试环境中有效。但这已经够应付我们的使用;我们知道 Swift 目前支持的每个平台都是如此。

```swift
extension UnsafeMutableRawBufferPointer {
    static func allocate(byteCount: Int) -> UnsafeMutableRawBufferPointer {
        let alignment = Int.bitWidth / 8
        assert(alignment.isPositivePowerOf2, "expected power of two")
        return self.allocate(byteCount: byteCount, alignment: alignment)
    }
}
```

最后再提一个点，我们可以添加一个隐式强制解包的 `base` 属性。

```swift
extension UnsafeMutableRawBufferPointer {
    var base: UnsafeMutableRawPointer {
        return baseAddress!
    }
}
extension UnsafeRawBufferPointer {
    var base: UnsafeRawPointer {
        return baseAddress!
    }
}
```

一切是如此简单。