title: "属性修饰器"
date: 
tags: [新特性]
categories: [Swift]
permalink: propertywrapper
keywords: 新特性,修饰器
custom_title: 属性修饰器
description: Swift 属性修饰器要让 SwiftUI 成为可能还有很长的路要走，但他们在塑造整个语言的未来方面可能发挥着更重要的作用。

---
原文链接=https://nshipster.com/propertywrapper/
作者=Mattt
原文日期=2019-06-24
译者=ericchuhong
校对=
定稿=

<!--此处开始正文-->

几年前，我们
我们 [会说](/at-compiler-directives/) “at 符号”（`@`）——以及方括号和可笑的长方法名称——是 Objective-C 的特性，正如括号之于 [Lisp](https://en.wikipedia.org/wiki/Lisp_%28programming_language%29) 或者标点之于 [Perl](https://nshipster.com/assets/qbert-fe44c1a26bd163d2dfafa5334c7bfa7957c3c243cd0c19591f494a9cea9302dc.png)。

然后 Swift 来了，并用它来结束这些古怪小 🥨 图案一样的字形。或者我们想到的是这样。

<!--more-->

首先，`@` 的功能仅限于 Objective-C 的相互操作性：`@IBAction`，`@NSCopying`，`@UIApplicationMain`，等等。但同时，Swift 继续采用越来越多的 `@` 前缀 [属性](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html)。

我们在 [WWDC 2019](/wwdc-2019/) 上第一次看到了 Swift 5.1 和 SwiftUI 的同时公布。并且随着每一张“令人兴奋”的幻灯片出现了一个个前所未有的属性：`@State`，`@Binding`，`@EnvironmentObject`……

我们看到了Swift的未来，它充满了 `@` 的符号。

---

一旦开始逐步升温一段时间，我们就会深入了解 SwiftUI。

但本周，我们想仔细看看 SwiftUI 的一个关键语言特性——可能会对 Swift 5.1 之前版本产生最大影响的东西：*属性修饰器*

---

## 关于 属性 ~~代理~~ ++修饰器++

属性修饰器是在 2019 年 3 月第一次 [开始在 Swift 论坛使用](https://forums.swift.org/t/pitch-property-delegates/21895)——SwiftUI 公布的前一个月。

在它开始使用的时候，Swift 核心团队成员 Douglas Gregor 称该特性（当时称为 *“属性代理”*）为用户可使用的功能统称，现在则由 `lazy` 关键字等语言特性提供。

懒惰是编程的一种美德，这种普遍适用的功能是周到设计决策的特征，这让 Swift 成为一种很好用的语言。当一个属性被声明为 `lazy` 时，它推迟初始化其默认值，直到第一次访问才进行初始化。例如，你可以自己尝试实现这样的功能，使用一个私有属性，它需通过计算后才行被访问。而单单一个 `lazy` 关键字就可以让所有这些都变得没有必要。

```swift
struct <#Structure#> {
    // 使用lazy关键字进行属性延迟初始化
    lazy var deferred = <#...#>

    // 没有lazy关键字的等效行为
    private var _deferred: <#Type#>?
    var deferred: <#Type#> {
        get {
            if let value = _deferred { return value }
            let initialValue = <#...#>
            _deferred = initialValue
            return initialValue
        }

        set {
            _deferred = newValue
        }
    }
}
```

[SE-0258: 属性修饰器](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md) 目前正在进行第三次审核
（预定于昨天结束，就在发布的时候）, 并且承诺开放像 `lazy` 这样的功能，以便库作者可以自己实现类似的功能。

这个提案在概述其设计和实现非常出色。因此比起尝试改善这种解释，我们认为着眼于让属性修饰器实现一些可能的新模式要有趣些——而且，在这个过程中，我们可以更好了解如何在项目使用这些功能。

所以，供你参考，以下是新的 `@propertyWrapper` 属性的四个潜在用例：

- [约束值](#constraining-values)
- [转换属性赋值时的值](#transforming-values-on-property-assignment)
- [改变生成的等式和比较语义](#changing-synthesized-equality-and-comparison-semantics)
- [审查属性访问](#auditing-property-access)

---

<a name="constraining-values"></a>
## 约束值

SE-0258 提供了大量实用案例，包括了 `@Lazy`，`@Atomic`，`@ThreadSpecific` 和 `@Box`。但最让我们兴奋的是那个关于 `@Constrained` 的属性修饰器。

Swift 的标准库提供了 [正确](https://en.wikipedia.org/wiki/IEEE_754)，你可以拥有高性能，浮点数类型，并且你可以拥有任何你想要的大小——只要他是 [32](https://developer.apple.com/documentation/swift/float) 或 [64](https://developer.apple.com/documentation/swift/double) （或 [80](https://developer.apple.com/documentation/swift/float80)）位长度（[就像 Henry Ford](https://en.wikiquote.org/wiki/Henry_Ford)）。

如果你想要实现自定义浮点数类型，而且有强制要求有效值范围，这从 [Swift 3](https://github.com/apple/swift-evolution/blob/master/proposals/0067-floating-point-protocols.md)开始 已经成为可能。但是这样做需要遵循错综复杂的协议要求：

<svg xmlns="http://www.w3.org/2000/svg" font-size="14" viewBox="0 0 808 592" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" fill="none">
    <defs>
      <marker id="triangle" markerHeight="8" markerWidth="8" orient="auto" refX="4" refY="2" viewBox="0 0 8 4">
        <polygon fill="black" points="0,0 0,4 8,2 0,0"></polygon>
      </marker>
      <marker id="clear_triangle" markerHeight="10" markerWidth="10" orient="auto" refX="1" refY="7" viewBox="0 0 20 14">
        <polygon fill="none" points="2,2 2,12 18,7 2,2" stroke="black" stroke-width="2"></polygon>
      </marker>
      <marker id="circle" markerHeight="5" markerWidth="5" orient="auto" refX="10" refY="10" viewBox="0 0 20 20">
        <circle cx="10" cy="10" fill="black" r="8"></circle>
      </marker>
      <marker id="square" markerHeight="5" markerWidth="5" orient="auto" refX="10" refY="10" viewBox="0 0 20 20">
        <rect fill="black" width="20" height="20" viewBox="0 0 20 20" x="0" y="0"></rect>
      </marker>
      <marker id="open_circle" markerHeight="10" markerWidth="10" orient="auto" refX="10" refY="10" viewBox="0 0 20 20">
        <circle cx="10" cy="10" fill="white" r="4" stroke="black" stroke-width="2"></circle>
      </marker>
      <marker id="big_open_circle" markerHeight="20" markerWidth="20" orient="auto" refX="20" refY="20" viewBox="0 0 40 40">
        <circle cx="20" cy="20" fill="white" r="6" stroke="black" stroke-width="2"></circle>
      </marker>
    </defs>
    <style>
      text{stroke: none; fill: currentColor;}
      polygon{fill:currentColor;}
    </style>
    <g>
      <line x1="12" x2="12" y1="104" y2="520"></line>
      <line marker-end="url(#triangle)" x1="12" x2="60" y1="104" y2="104"></line>
      <line x1="12" x2="36" y1="520" y2="520"></line>
      <line x1="36" x2="36" y1="460" y2="520"></line>
      <line x1="36" x2="36" y1="520" y2="580"></line>
      <path d="M 36 580 A 4 4 0 0 0 40 584" fill="none"></path>
      <path d="M 40 456 A 4 4 0 0 0 36 460" fill="none"></path>
    </g>
    <g>
      <line x1="40" x2="56" y1="456" y2="456"></line>
    </g>
    <g>
      <line x1="40" x2="56" y1="584" y2="584"></line>
    </g>
    <g>
      <line x1="44" x2="44" y1="168" y2="312"></line>
      <line marker-end="url(#triangle)" x1="44" x2="60" y1="168" y2="168"></line>
      <line x1="44" x2="84" y1="312" y2="312"></line>
    </g>
    <g>
      <line x1="68" x2="68" y1="88" y2="120"></line>
      <line x1="68" x2="308" y1="88" y2="88"></line>
      <line x1="68" x2="308" y1="120" y2="120"></line>
      <line x1="308" x2="308" y1="88" y2="120"></line>
    </g>
    <g>
      <line x1="68" x2="68" y1="152" y2="184"></line>
      <line x1="68" x2="308" y1="152" y2="152"></line>
      <line x1="68" x2="308" y1="184" y2="184"></line>
      <line x1="308" x2="308" y1="152" y2="184"></line>
    </g>
    <g>
      <line x1="72" x2="74" y1="496" y2="500"></line>
      <path d="M 72 480 A 16 16 0 0 0 72 496" fill="none"></path>
      <path d="M 74 500 A 8 8 0 0 0 80 504" fill="none"></path>
    </g>
    <g>
      <line x1="74" x2="72" y1="476" y2="480"></line>
      <path d="M 80 472 A 8 8 0 0 0 74 476" fill="none"></path>
    </g>
    <g>
      <line x1="80" x2="136" y1="472" y2="472"></line>
      <path d="M 142 476 A 8 8 0 0 0 136 472" fill="none"></path>
    </g>
    <g>
      <line x1="80" x2="136" y1="504" y2="504"></line>
      <path d="M 136 504 A 8 8 0 0 0 142 500" fill="none"></path>
    </g>
    <g>
      <line x1="84" x2="84" y1="296" y2="328"></line>
      <line x1="84" x2="260" y1="296" y2="296"></line>
      <line x1="84" x2="260" y1="328" y2="328"></line>
      <line x1="260" x2="260" y1="296" y2="328"></line>
    </g>
    <g>
      <line x1="84" x2="84" y1="392" y2="424"></line>
      <line x1="84" x2="260" y1="392" y2="392"></line>
      <line x1="84" x2="260" y1="424" y2="424"></line>
      <line x1="260" x2="260" y1="392" y2="424"></line>
    </g>
    <g>
      <line x1="128" x2="130" y1="560" y2="564"></line>
      <path d="M 128 544 A 16 16 0 0 0 128 560" fill="none"></path>
      <path d="M 130 564 A 8 8 0 0 0 136 568" fill="none"></path>
    </g>
    <g>
      <line x1="130" x2="128" y1="540" y2="544"></line>
      <path d="M 136 536 A 8 8 0 0 0 130 540" fill="none"></path>
    </g>
    <g>
      <line x1="136" x2="208" y1="536" y2="536"></line>
      <path d="M 214 540 A 8 8 0 0 0 208 536" fill="none"></path>
    </g>
    <g>
      <line x1="136" x2="208" y1="568" y2="568"></line>
      <path d="M 208 568 A 8 8 0 0 0 214 564" fill="none"></path>
    </g>
    <g>
      <line x1="142" x2="144" y1="476" y2="480"></line>
      <path d="M 144 496 A 16 16 0 0 0 144 480" fill="none"></path>
    </g>
    <g>
      <line x1="142" x2="144" y1="500" y2="496"></line>
    </g>
    <g>
      <line x1="172" x2="172" y1="248" y2="288"></line>
      <line marker-end="url(#triangle)" x1="172" x2="244" y1="248" y2="248"></line>
    </g>
    <g>
      <line marker-end="url(#triangle)" x1="172" x2="172" y1="352" y2="340"></line>
      <line x1="172" x2="172" y1="352" y2="384"></line>
    </g>
    <g>
      <line x1="200" x2="202" y1="496" y2="500"></line>
      <path d="M 200 480 A 16 16 0 0 0 200 496" fill="none"></path>
      <path d="M 202 500 A 8 8 0 0 0 208 504" fill="none"></path>
    </g>
    <g>
      <line x1="202" x2="200" y1="476" y2="480"></line>
      <path d="M 208 472 A 8 8 0 0 0 202 476" fill="none"></path>
    </g>
    <g>
      <line x1="208" x2="272" y1="472" y2="472"></line>
      <path d="M 278 476 A 8 8 0 0 0 272 472" fill="none"></path>
    </g>
    <g>
      <line x1="208" x2="272" y1="504" y2="504"></line>
      <path d="M 272 504 A 8 8 0 0 0 278 500" fill="none"></path>
    </g>
    <g>
      <line x1="214" x2="216" y1="540" y2="544"></line>
      <path d="M 216 560 A 16 16 0 0 0 216 544" fill="none"></path>
    </g>
    <g>
      <line x1="214" x2="216" y1="564" y2="560"></line>
    </g>
    <g>
      <line x1="252" x2="252" y1="232" y2="264"></line>
      <line x1="252" x2="428" y1="232" y2="232"></line>
      <line x1="252" x2="428" y1="264" y2="264"></line>
      <line x1="428" x2="428" y1="232" y2="264"></line>
    </g>
    <g>
      <line x1="278" x2="280" y1="476" y2="480"></line>
      <path d="M 280 496 A 16 16 0 0 0 280 480" fill="none"></path>
    </g>
    <g>
      <line x1="278" x2="280" y1="500" y2="496"></line>
    </g>
    <g>
      <line x1="308" x2="308" y1="472" y2="504"></line>
      <line x1="308" x2="484" y1="472" y2="472"></line>
      <line x1="308" x2="484" y1="504" y2="504"></line>
      <line x1="484" x2="484" y1="472" y2="504"></line>
    </g>
    <g>
      <line marker-end="url(#triangle)" x1="320" x2="316" y1="104" y2="104"></line>
      <line x1="320" x2="428" y1="104" y2="104"></line>
      <line x1="428" x2="428" y1="104" y2="160"></line>
    </g>
    <g>
      <line x1="340" x2="340" y1="184" y2="224"></line>
      <line marker-end="url(#triangle)" x1="340" x2="396" y1="184" y2="184"></line>
    </g>
    <g>
      <line marker-end="url(#triangle)" x1="340" x2="340" y1="288" y2="276"></line>
      <line x1="340" x2="340" y1="288" y2="464"></line>
    </g>
    <g>
      <line x1="376" x2="378" y1="576" y2="580"></line>
      <path d="M 376 560 A 16 16 0 0 0 376 576" fill="none"></path>
      <path d="M 378 580 A 8 8 0 0 0 384 584" fill="none"></path>
    </g>
    <g>
      <line x1="378" x2="376" y1="556" y2="560"></line>
      <path d="M 384 552 A 8 8 0 0 0 378 556" fill="none"></path>
    </g>
    <g>
      <line x1="380" x2="380" y1="376" y2="464"></line>
      <line x1="380" x2="476" y1="376" y2="376"></line>
      <line x1="476" x2="476" y1="352" y2="376"></line>
    </g>
    <g>
      <line x1="384" x2="424" y1="552" y2="552"></line>
      <path d="M 430 556 A 8 8 0 0 0 424 552" fill="none"></path>
    </g>
    <g>
      <line x1="384" x2="424" y1="584" y2="584"></line>
      <path d="M 424 584 A 8 8 0 0 0 430 580" fill="none"></path>
    </g>
    <g>
      <line x1="404" x2="404" y1="168" y2="200"></line>
      <line x1="404" x2="580" y1="168" y2="168"></line>
      <line x1="404" x2="580" y1="200" y2="200"></line>
      <line x1="580" x2="580" y1="168" y2="200"></line>
    </g>
    <g>
      <line x1="412" x2="412" y1="24" y2="56"></line>
      <line x1="412" x2="580" y1="24" y2="24"></line>
      <line x1="412" x2="580" y1="56" y2="56"></line>
      <line x1="580" x2="580" y1="24" y2="56"></line>
    </g>
    <g>
      <line x1="430" x2="432" y1="556" y2="560"></line>
      <path d="M 432 576 A 16 16 0 0 0 432 560" fill="none"></path>
    </g>
    <g>
      <line x1="430" x2="432" y1="580" y2="576"></line>
    </g>
    <g>
      <line x1="440" x2="516" y1="568" y2="568"></line>
      <line marker-start="url(#open_circle)" x1="516" x2="516" y1="440" y2="568"></line>
    </g>
    <g>
      <line x1="452" x2="452" y1="296" y2="328"></line>
      <line x1="452" x2="628" y1="296" y2="296"></line>
      <line x1="452" x2="628" y1="328" y2="328"></line>
      <line x1="628" x2="628" y1="296" y2="328"></line>
    </g>
    <g>
      <line x1="452" x2="452" y1="392" y2="424"></line>
      <line x1="452" x2="628" y1="392" y2="392"></line>
      <line x1="452" x2="628" y1="424" y2="424"></line>
      <line x1="628" x2="628" y1="392" y2="424"></line>
    </g>
    <g>
      <line marker-end="url(#triangle)" x1="476" x2="476" y1="352" y2="340"></line>
    </g>
    <g>
      <line marker-end="url(#triangle)" x1="492" x2="492" y1="80" y2="68"></line>
      <line x1="492" x2="492" y1="80" y2="160"></line>
    </g>
    <g>
      <line marker-end="url(#triangle)" x1="492" x2="492" y1="224" y2="212"></line>
      <line x1="492" x2="492" y1="224" y2="288"></line>
    </g>
    <g>
      <line marker-end="url(#triangle)" x1="532" x2="532" y1="352" y2="340"></line>
      <line x1="532" x2="532" y1="352" y2="384"></line>
    </g>
    <g>
      <line x1="548" x2="616" y1="568" y2="568"></line>
      <line marker-start="url(#open_circle)" x1="548" x2="548" y1="440" y2="568"></line>
    </g>
    <g>
      <line x1="556" x2="556" y1="88" y2="120"></line>
      <line x1="556" x2="732" y1="88" y2="88"></line>
      <line x1="556" x2="732" y1="120" y2="120"></line>
      <line x1="732" x2="732" y1="88" y2="120"></line>
    </g>
    <g>
      <line x1="556" x2="556" y1="232" y2="264"></line>
      <line x1="556" x2="732" y1="232" y2="232"></line>
      <line x1="556" x2="732" y1="264" y2="264"></line>
      <line x1="732" x2="732" y1="232" y2="264"></line>
    </g>
    <g>
      <line x1="580" x2="620" y1="184" y2="184"></line>
      <line x1="620" x2="620" y1="144" y2="184"></line>
    </g>
    <g>
      <line x1="580" x2="580" y1="472" y2="504"></line>
      <line x1="580" x2="756" y1="472" y2="472"></line>
      <line x1="580" x2="756" y1="504" y2="504"></line>
      <line x1="756" x2="756" y1="472" y2="504"></line>
    </g>
    <g>
      <line marker-end="url(#triangle)" x1="588" x2="588" y1="352" y2="340"></line>
      <line x1="588" x2="588" y1="352" y2="376"></line>
      <line x1="588" x2="700" y1="376" y2="376"></line>
      <line x1="700" x2="700" y1="376" y2="464"></line>
    </g>
    <g>
      <line marker-end="url(#triangle)" x1="620" x2="620" y1="144" y2="132"></line>
    </g>
    <g>
      <line x1="624" x2="626" y1="576" y2="580"></line>
      <path d="M 624 560 A 16 16 0 0 0 624 576" fill="none"></path>
      <path d="M 626 580 A 8 8 0 0 0 632 584" fill="none"></path>
    </g>
    <g>
      <line x1="626" x2="624" y1="556" y2="560"></line>
      <path d="M 632 552 A 8 8 0 0 0 626 556" fill="none"></path>
    </g>
    <g>
      <line x1="628" x2="676" y1="312" y2="312"></line>
      <line x1="676" x2="676" y1="288" y2="312"></line>
    </g>
    <g>
      <line x1="632" x2="696" y1="552" y2="552"></line>
      <path d="M 702 556 A 8 8 0 0 0 696 552" fill="none"></path>
    </g>
    <g>
      <line x1="632" x2="696" y1="584" y2="584"></line>
      <path d="M 696 584 A 8 8 0 0 0 702 580" fill="none"></path>
    </g>
    <g>
      <line marker-end="url(#triangle)" x1="676" x2="676" y1="144" y2="132"></line>
      <line x1="676" x2="676" y1="144" y2="224"></line>
    </g>
    <g>
      <line marker-end="url(#triangle)" x1="676" x2="676" y1="288" y2="276"></line>
    </g>
    <g>
      <line x1="702" x2="704" y1="556" y2="560"></line>
      <path d="M 704 576 A 16 16 0 0 0 704 560" fill="none"></path>
    </g>
    <g>
      <line x1="702" x2="704" y1="580" y2="576"></line>
    </g>
    <g>
      <text x="81" y="108">ExpressibleByIntegerLiteral</text>
    </g>
    <g>
      <text x="81" y="492">Float</text>
    </g>
    <g>
      <text x="89" y="172">ExpressibleByFloatLiteral</text>
    </g>
    <g>
      <text x="97" y="316">BinaryFloatingPoint</text>
    </g>
    <g>
      <text x="121" y="412">FloatingPoint</text>
    </g>
    <g>
      <text x="137" y="556">Float80</text>
    </g>
    <g>
      <text x="209" y="492">Double</text>
    </g>
    <g>
      <text x="289" y="252">SignedNumeric</text>
    </g>
    <g>
      <text x="345" y="492">SignedInteger</text>
    </g>
    <g>
      <text x="385" y="572">Int</text>
    </g>
    <g>
      <text x="425" y="44">AdditiveArithmetic</text>
    </g>
    <g>
      <text x="465" y="188">Numeric</text>
    </g>
    <g>
      <text x="473" y="412">FixedWidthInteger</text>
    </g>
    <g>
      <text x="489" y="316">BinaryInteger</text>
    </g>
    <g>
      <text x="601" y="252">Comparable</text>
    </g>
    <g>
      <text x="609" y="108">Equatable</text>
    </g>
    <g>
      <text x="609" y="492">UnsignedInteger</text>
    </g>
    <g>
      <text x="641" y="572">UInt</text>
    </g>
    <g>
      <line marker-start="url(#open_circle)" x1="108" x2="108" y1="440" y2="464"></line>
    </g>
    <g>
      <line marker-start="url(#open_circle)" x1="172" x2="172" y1="440" y2="528"></line>
    </g>
    <g>
      <line marker-start="url(#open_circle)" x1="236" x2="236" y1="440" y2="464"></line>
    </g>
    <g>
      <line marker-start="url(#open_circle)" x1="404" x2="404" y1="520" y2="544"></line>
    </g>
    <g>
      <line marker-start="url(#open_circle)" x1="660" x2="660" y1="520" y2="544"></line>
    </g>
 </svg>
来自：[航空学院的 Swift 数字指引](https://flight.school/books/numbers/)
            
查看下来是个不小的壮举，并且对于大多数用例，通常需要非常多工作才能证明。

幸好，属性修饰器提供了一种将标准数字类型参数化的方式，同时又大大减少工作量。

### 实现一个限制值范围的属性修饰器

思考下面的 `Clamping` 结构。作为一个属性修饰器（由 `@propertyWrapper` 属性表示），它会自动在规定的范围内“限制”越界的值。

```swift
@propertyWrapper
struct Clamping<Value: Comparable> {
    var value: Value
    let range: ClosedRange<Value>

    init(initialValue value: Value, _ range: ClosedRange<Value>) {
        precondition(range.contains(value))
        self.value = value
        self.range = range
    }

    var wrappedValue: Value {
        get { value }
        set { value = min(max(range.lowerBound, newValue), range.upperBound) }
    }
}
```

你可以使用 `@Clamping` 保证属性在转成模型 [化学溶液中的酸度](https://en.wikipedia.org/wiki/PH) 的过程中，处于 0-14 的常规范围内。

```swift
struct Solution {
    @Clamping(0...14) var pH: Double = 7.0
}

let carbonicAcid = Solution(pH: 4.68) // 在标准情况下为 1 mM
```

如果尝试将 pH 值设定在限制的范围之外，将得到最接近的边界值（最小值或者最大值）来代替。

```swift
let superDuperAcid = Solution(pH: -1)
superDuperAcid.pH // 0
```

你可以在其他属性修饰器的实现中使用属性修饰器。例如，这个 `UnitInterval` 属性修饰起器委托给 `@Clamping`，把值约束在 0 和 1 之间，包括 0 和 1。

```swift
@propertyWrapper
struct UnitInterval<Value: FloatingPoint> {
    @Clamping(0...1)
    var wrappedValue: Value = .zero

    init(initialValue value: Value) {
        self.wrappedValue = value
    }
}
```

再比如，你可以使用 `@UnitInterval` 属性修饰器定义一个 `RGB` 的类型，用来表示红色，绿色，蓝色的百分比强度。

```swift
struct RGB {
    @UnitInterval var red: Double
    @UnitInterval var green: Double
    @UnitInterval var blue: Double
}

let cornflowerBlue = RGB(red: 0.392, green: 0.584, blue: 0.929)
```

#### 有关想法

- 实现一个 `@Positive`/`@NonNegative` 属性装饰器，将无符号整数赋值成有符号整数类型。
- 实现一个 `@NonZero` 属性装饰器，使得一个数值要么大于，要么小于 `0`。
- `@Validated` 或者 `@Whitelisted`/`@Blacklisted` 属性装饰器，约束了什么样的值可以被赋值。

<a name="transforming-values-on-property-assignment"></a>
## 转换属性赋值时的值

从用户接受文本输入是应用开发者经常头疼的问题。有很多事情需要跟踪，从字符串编码的乏味，到尝试通过文本字段恶意注入代码。但在开发者面对的的问题中，最难以捉摸和令人困扰的是接收用户生成的内容，而且这些内容开头和结尾都带有空格。

在内容开头有一个单独的空格，可以让 URL 无效，混淆日期解析器，还有通过一个接一个的错误来造成混乱：

```swift
import Foundation

URL(string: " https://nshipster.com") // nil (!)

ISO8601DateFormatter().date(from: " 2019-06-24") // nil (!)

let words = " Hello, world!".components(separatedBy: .whitespaces)
words.count // 3 (!)
```

说到用户输入，客户端经常以没留意做理由，然后把任何东西 *原原本本* 发送给服务器。`¯\_(ツ)_/¯`。

当然我不是在倡导客户端应该为此负责更多处理工作，这种情况就涉及到了 Swift 属性修饰器另外一个引人注目的用例。

---

Foundation 框架将 `trimmingCharacters(in:)` 方法桥接到了 Swift 的字符串中，除了一些其他作用以外，它提供了方便的方式来裁剪掉 `String` 值首位两端的空格。你想每次通过调用这个方法来保证数据健全，但是，它到底不太方便。如果你曾经或多或少做过这种事，你肯定会想知道有没有更好的方法来实现。

或许你找到了一种不是那么特别的方法，通过 `willSet` 属性回调来寻解脱……而结果只有感到失望，因为你不能用这个办法去改变已经发生的事情。

```swift
struct Post {
    var title: String {
        willSet {
            title = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            /* ⚠️ 尝试在它自己的 willSet 中存储属性 'title'，但该属性将会被新值覆盖*/
        }
    }
}
```

从上面看，你可能想到可以用 `didSet`，作为解决问题的康庄大道……但往往后来才发现，`didSet` 在属性初始化赋值时没有被调用。

```swift
struct Post {
    var title: String {
        // 😓 初始化期间未调用
        didSet {
            self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
```
> 在属性自己的 `didSet` 回调方法里面，很幸运不会再次触发回调，所以你不必担心意料之外的递归调用。

顺利的，你可能试了其他方法……想要同时满足人类工程学和性能要求，最终却找不到可以接受的方式。

如果你个人有遇上面到任何一种经历，那可以为此感到高兴，你对方法的探索已经结束了：属性装饰器就是你长久以来等待的解决方案。

### 实现为字符串值裁截空格的属性修饰器

看下下面的 `Trimmed` 结构体，它从输入的字符串裁截了空格和换行。

```swift
import Foundation

@propertyWrapper
struct Trimmed {
    private(set) var value: String = ""

    var wrappedValue: String {
        get { value }
        set { value = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    init(initialValue: String) {
        self.wrappedValue = initialValue
    }
}
```

通过在下面的 `Post` 结构中，给每个 `String` 属性标记上 `@Trimmed`。任何赋值给 `title` 或 `body` 的字符串值——无论是在初始化期间还是通过属性访问后——都将自动删除其开头或结尾的空格。

```swift
struct Post {
    @Trimmed var title: String
    @Trimmed var body: String
}

let quine = Post(title: "  Swift Property Wrappers  ", body: "<#...#>")
quine.title // "Swift Property Wrappers" (no leading or trailing spaces!)

quine.title = "      @propertyWrapper     "
quine.title // "@propertyWrapper" (still no leading or trailing spaces!)
```

#### 有关想法

- 实现一个 `@Transformed` 属性修饰器，它允许对输入的字符串进行 [ICU 转换](https://developer.apple.com/documentation/foundation/nsstring/1407787-applyingtransform)。
- 实现一个 `@Normalized` 属性修饰器，它允许一个 `String` 属性自定义它[规范化形式](https://unicode.org/reports/tr15/#Norm_Forms)
- 实现一个 `@Quantized`/`@Rounded`/`@Truncated` 属性修饰器，它会把数值转换到一种特定的精度（例如：向上舍入到最近的 ½ 精度），但是内部要关注到精确过程的中间值，防止连锁的舍入错误。

<a name="changing-synthesized-equality-and-comparison-semantics"></a>
## 改变生成的等式和比较语义

> 这个方式取决于遵循 synthesized 协议的实现细节，并且可能会在这个功能完成之前改变掉（尽管我们希望这个方法仍然像下面所说一样继续可用）。

在 Swift 中，两个 `String` 值如果他们 [*常规性等价*](https://unicode.org/reports/tr15/#Canon_Compat_Equivalence) 就会被人认为是相等。通过采用这些等价的语义，Swift 字符串的比较方式正如你在大多数情况下所想象的那样：如果两个字符串包含有相同的字符，不管它是任何独特的字符组合或者复合而成——结果就是，“é”（`U+00E9 带有锐音的拉丁小写字母 E`）等于“e”（`U+0065 拉丁小写字母 E`）+“◌́”（`U+0301T 和锐音组合`）。

但是，如果你在特殊的情况下需要不同的相等语义呢？假设你需要一个 *不区分大小写* 的字符串相等概念？

在今天，你可以使用许多方法，利用已有的语言特性解决这个问题：

- 你可以随时对经过 `lowercased()` 处理的结果做 `==` 比较，但和任何手动处理一样，这个方法容易出错。
- 你可以创建一个包含 `String` 值的自定义 `CaseInsensitive` 类型。但你必须要完成很多额外的工作，这样才能像标准的 `String` 类型一样符合人类工程学和功能主义。
- 你可以自定义一个比较函数来封装整个比较过程——哎呀，你甚至可以定义一个 [自定义操作符](https://nshipster.com/swift-operators/#defining-custom-operators) 给它——但是在两个操作数之间的比较，没有什么可以接近绝对的 `==`。

这些方法中没有特别吸引人的，但幸好 Swift 5.1 中的属性修饰器，终于给我们找到了一个想要的解决方案。

> 和数字一样，Swift 采用面向协议的方式，通过一组狭义的类型委托字符串负责处理。对于好奇心强的读者，这里是一张关系图，里面展示了在 Swift 标准库中所有的字符串类型之间的关系。

<svg xmlns="http://www.w3.org/2000/svg" class="bob" font-size="14" viewBox="0 0 920 736" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" fill="none">
  <defs>
    <marker id="triangle" markerHeight="8" markerWidth="8" orient="auto" refX="4" refY="2" viewBox="0 0 8 4">
      <polygon fill="black" points="0,0 0,4 8,2 0,0"></polygon>
    </marker>
    <marker id="clear_triangle" markerHeight="10" markerWidth="10" orient="auto" refX="1" refY="7" viewBox="0 0 20 14">
      <polygon fill="none" points="2,2 2,12 18,7 2,2" stroke="black" stroke-width="2"></polygon>
    </marker>
    <marker id="circle" markerHeight="5" markerWidth="5" orient="auto" refX="10" refY="10" viewBox="0 0 20 20">
      <circle cx="10" cy="10" fill="black" r="8"></circle>
    </marker>
    <marker id="square" markerHeight="5" markerWidth="5" orient="auto" refX="10" refY="10" viewBox="0 0 20 20">
      <rect fill="black" width="20" height="20" viewBox="0 0 20 20" x="0" y="0"></rect>
    </marker>
    <marker id="open_circle" markerHeight="10" markerWidth="10" orient="auto" refX="10" refY="10" viewBox="0 0 20 20">
      <circle cx="10" cy="10" fill="white" r="4" stroke="black" stroke-width="2"></circle>
    </marker>
    <marker id="big_open_circle" markerHeight="20" markerWidth="20" orient="auto" refX="20" refY="20" viewBox="0 0 40 40">
      <circle cx="20" cy="20" fill="white" r="6" stroke="black" stroke-width="2"></circle>
    </marker>
  </defs>
  <style>
    text{stroke: none; fill: currentColor;}
    polygon{fill:currentColor;}
  </style>
  <g>
    <line x1="4" x2="4" y1="232" y2="264"></line>
    <line x1="4" x2="252" y1="232" y2="232"></line>
    <line x1="4" x2="252" y1="264" y2="264"></line>
    <line x1="252" x2="252" y1="232" y2="264"></line>
  </g>
  <g>
    <line x1="132" x2="132" y1="200" y2="224"></line>
    <line x1="132" x2="236" y1="200" y2="200"></line>
    <line x1="236" x2="236" y1="176" y2="200"></line>
  </g>
  <g>
    <line x1="132" x2="272" y1="536" y2="536"></line>
    <line marker-start="url(#open_circle)" x1="132" x2="132" y1="280" y2="536"></line>
  </g>
  <g>
    <line x1="148" x2="148" y1="360" y2="392"></line>
    <line x1="148" x2="340" y1="360" y2="360"></line>
    <line x1="148" x2="340" y1="392" y2="392"></line>
    <line x1="340" x2="340" y1="360" y2="392"></line>
  </g>
  <g>
    <line x1="148" x2="148" y1="424" y2="456"></line>
    <line x1="148" x2="340" y1="424" y2="424"></line>
    <line x1="148" x2="340" y1="456" y2="456"></line>
    <line x1="340" x2="340" y1="424" y2="456"></line>
  </g>
  <g>
    <line x1="212" x2="212" y1="120" y2="152"></line>
    <line x1="212" x2="332" y1="120" y2="120"></line>
    <line x1="212" x2="332" y1="152" y2="152"></line>
    <line x1="332" x2="332" y1="120" y2="152"></line>
  </g>
  <g>
    <line x1="220" x2="220" y1="40" y2="72"></line>
    <line x1="220" x2="324" y1="40" y2="40"></line>
    <line x1="220" x2="324" y1="72" y2="72"></line>
    <line x1="324" x2="324" y1="40" y2="72"></line>
  </g>
  <g>
    <line marker-end="url(#triangle)" x1="236" x2="236" y1="176" y2="164"></line>
  </g>
  <g>
    <line marker-end="url(#triangle)" x1="276" x2="276" y1="96" y2="84"></line>
    <line x1="276" x2="276" y1="96" y2="112"></line>
  </g>
  <g>
    <line x1="276" x2="276" y1="232" y2="264"></line>
    <line x1="276" x2="500" y1="232" y2="232"></line>
    <line x1="276" x2="500" y1="264" y2="264"></line>
    <line x1="500" x2="500" y1="232" y2="264"></line>
  </g>
  <g>
    <line x1="280" x2="282" y1="544" y2="548"></line>
    <path d="M 280 528 A 16 16 0 0 0 280 544" fill="none"></path>
    <path d="M 282 548 A 8 8 0 0 0 288 552" fill="none"></path>
  </g>
  <g>
    <line x1="282" x2="280" y1="524" y2="528"></line>
    <path d="M 288 520 A 8 8 0 0 0 282 524" fill="none"></path>
  </g>
  <g>
    <line x1="288" x2="448" y1="520" y2="520"></line>
    <path d="M 454 524 A 8 8 0 0 0 448 520" fill="none"></path>
  </g>
  <g>
    <line x1="288" x2="448" y1="552" y2="552"></line>
    <path d="M 448 552 A 8 8 0 0 0 454 548" fill="none"></path>
  </g>
  <g>
    <line marker-end="url(#triangle)" x1="308" x2="308" y1="176" y2="164"></line>
    <line x1="308" x2="308" y1="176" y2="200"></line>
    <line x1="308" x2="412" y1="200" y2="200"></line>
    <line x1="412" x2="412" y1="200" y2="224"></line>
  </g>
  <g>
    <line marker-end="url(#triangle)" x1="352" x2="348" y1="376" y2="376"></line>
    <line x1="352" x2="364" y1="376" y2="376"></line>
    <line x1="364" x2="364" y1="376" y2="408"></line>
    <line x1="364" x2="364" y1="408" y2="440"></line>
    <line x1="364" x2="396" y1="408" y2="408"></line>
  </g>
  <g>
    <line marker-end="url(#triangle)" x1="352" x2="348" y1="440" y2="440"></line>
    <line x1="352" x2="364" y1="440" y2="440"></line>
  </g>
  <g>
    <line x1="372" x2="372" y1="472" y2="512"></line>
    <line x1="372" x2="420" y1="472" y2="472"></line>
    <line marker-start="url(#open_circle)" x1="420" x2="420" y1="440" y2="472"></line>
  </g>
  <g>
    <line x1="372" x2="372" y1="560" y2="696"></line>
    <line marker-end="url(#open_circle)" x1="372" x2="484" y1="696" y2="696"></line>
  </g>
  <g>
    <line x1="396" x2="396" y1="392" y2="424"></line>
    <line x1="396" x2="548" y1="392" y2="392"></line>
    <line x1="396" x2="548" y1="424" y2="424"></line>
    <line x1="548" x2="548" y1="392" y2="424"></line>
  </g>
  <g>
    <line x1="454" x2="456" y1="524" y2="528"></line>
    <path d="M 456 544 A 16 16 0 0 0 456 528" fill="none"></path>
  </g>
  <g>
    <line x1="454" x2="456" y1="548" y2="544"></line>
  </g>
  <g>
    <line marker-end="url(#triangle)" x1="468" x2="468" y1="288" y2="276"></line>
    <line x1="468" x2="468" y1="288" y2="384"></line>
  </g>
  <g>
    <line x1="492" x2="492" y1="520" y2="552"></line>
    <line x1="492" x2="756" y1="520" y2="520"></line>
    <line x1="492" x2="756" y1="552" y2="552"></line>
    <line x1="756" x2="756" y1="520" y2="552"></line>
  </g>
  <g>
    <line x1="492" x2="492" y1="600" y2="632"></line>
    <line x1="492" x2="756" y1="600" y2="600"></line>
    <line x1="492" x2="756" y1="632" y2="632"></line>
    <line x1="756" x2="756" y1="600" y2="632"></line>
  </g>
  <g>
    <line x1="492" x2="492" y1="680" y2="712"></line>
    <line x1="492" x2="756" y1="680" y2="680"></line>
    <line x1="492" x2="756" y1="712" y2="712"></line>
    <line x1="756" x2="756" y1="680" y2="712"></line>
  </g>
  <g>
    <line x1="508" x2="508" y1="120" y2="152"></line>
    <line x1="508" x2="908" y1="120" y2="120"></line>
    <line x1="508" x2="908" y1="152" y2="152"></line>
    <line x1="908" x2="908" y1="120" y2="152"></line>
  </g>
  <g>
    <line x1="524" x2="524" y1="296" y2="384"></line>
    <line marker-end="url(#triangle)" x1="524" x2="548" y1="296" y2="296"></line>
  </g>
  <g>
    <line x1="524" x2="524" y1="432" y2="472"></line>
    <line x1="524" x2="628" y1="472" y2="472"></line>
    <line marker-end="url(#triangle)" x1="628" x2="628" y1="472" y2="508"></line>
  </g>
  <g>
    <line x1="548" x2="596" y1="408" y2="408"></line>
    <line x1="596" x2="596" y1="376" y2="408"></line>
    <line marker-end="url(#triangle)" x1="596" x2="636" y1="376" y2="376"></line>
    <line x1="596" x2="596" y1="408" y2="440"></line>
    <line marker-end="url(#triangle)" x1="596" x2="636" y1="440" y2="440"></line>
  </g>
  <g>
    <line x1="556" x2="556" y1="40" y2="72"></line>
    <line x1="556" x2="860" y1="40" y2="40"></line>
    <line x1="556" x2="860" y1="72" y2="72"></line>
    <line x1="860" x2="860" y1="40" y2="72"></line>
  </g>
  <g>
    <line x1="556" x2="556" y1="280" y2="312"></line>
    <line x1="556" x2="868" y1="280" y2="280"></line>
    <line x1="556" x2="868" y1="312" y2="312"></line>
    <line x1="868" x2="868" y1="280" y2="312"></line>
  </g>
  <g>
    <line x1="580" x2="580" y1="200" y2="232"></line>
    <line x1="580" x2="844" y1="200" y2="200"></line>
    <line x1="580" x2="844" y1="232" y2="232"></line>
    <line x1="844" x2="844" y1="200" y2="232"></line>
  </g>
  <g>
    <line marker-end="url(#triangle)" x1="628" x2="628" y1="560" y2="588"></line>
  </g>
  <g>
    <line marker-end="url(#triangle)" x1="628" x2="628" y1="656" y2="644"></line>
    <line x1="628" x2="628" y1="656" y2="672"></line>
  </g>
  <g>
    <line x1="644" x2="644" y1="360" y2="392"></line>
    <line x1="644" x2="748" y1="360" y2="360"></line>
    <line x1="644" x2="748" y1="392" y2="392"></line>
    <line x1="748" x2="748" y1="360" y2="392"></line>
  </g>
  <g>
    <line x1="644" x2="644" y1="424" y2="456"></line>
    <line x1="644" x2="748" y1="424" y2="424"></line>
    <line x1="644" x2="748" y1="456" y2="456"></line>
    <line x1="748" x2="748" y1="424" y2="456"></line>
  </g>
  <g>
    <line marker-end="url(#triangle)" x1="708" x2="708" y1="96" y2="84"></line>
    <line x1="708" x2="708" y1="96" y2="112"></line>
  </g>
  <g>
    <line marker-end="url(#triangle)" x1="708" x2="708" y1="176" y2="164"></line>
    <line x1="708" x2="708" y1="176" y2="192"></line>
  </g>
  <g>
    <line marker-end="url(#triangle)" x1="708" x2="708" y1="256" y2="244"></line>
    <line x1="708" x2="708" y1="256" y2="272"></line>
  </g>
  <g>
    <line x1="748" x2="772" y1="376" y2="376"></line>
    <line x1="772" x2="772" y1="344" y2="376"></line>
    <line x1="772" x2="852" y1="344" y2="344"></line>
    <line marker-end="url(#triangle)" x1="852" x2="852" y1="344" y2="380"></line>
  </g>
  <g>
    <line x1="748" x2="772" y1="440" y2="440"></line>
    <line x1="772" x2="772" y1="440" y2="472"></line>
    <line x1="772" x2="852" y1="472" y2="472"></line>
    <line x1="852" x2="852" y1="448" y2="472"></line>
  </g>
  <g>
    <line x1="796" x2="796" y1="392" y2="424"></line>
    <line x1="796" x2="908" y1="392" y2="392"></line>
    <line x1="796" x2="908" y1="424" y2="424"></line>
    <line x1="908" x2="908" y1="392" y2="424"></line>
  </g>
  <g>
    <line marker-end="url(#triangle)" x1="852" x2="852" y1="448" y2="436"></line>
  </g>
  <g>
    <text x="17" y="252">RangeReplaceableCollection</text>
  </g>
  <g>
    <text x="161" y="444">TextOutputStreamable</text>
  </g>
  <g>
    <text x="177" y="380">TextOutputStream</text>
  </g>
  <g>
    <text x="225" y="140">Collection</text>
  </g>
  <g>
    <text x="233" y="60">Sequence</text>
  </g>
  <g>
    <text x="289" y="252">BidirectionalCollection</text>
  </g>
  <g>
    <text x="329" y="540">String</text>
  </g>
  <g>
    <text x="409" y="412">StringProtocol</text>
  </g>
  <g>
    <text x="505" y="700">CustomDebugStringConvertible</text>
  </g>
  <g>
    <text x="513" y="540">LosslessStringConvertible</text>
  </g>
  <g>
    <text x="521" y="620">CustomStringConvertible</text>
  </g>
  <g>
    <text x="529" y="140">
      ExpressibleByExtendedGraphemeClusterLiteral</text>
  </g>
  <g>
    <text x="569" y="60">ExpressibleByUnicodeScalarLiteral</text>
  </g>
  <g>
    <text x="577" y="300">ExpressibleByStringInterpolation</text>
  </g>
  <g>
    <text x="601" y="220">ExpressibleByStringLiteral</text>
  </g>
  <g>
    <text x="649" y="380">Comparable</text>
  </g>
  <g>
    <text x="657" y="444">Hashable</text>
  </g>
  <g>
    <text x="809" y="412">Equatable</text>
  </g>
</svg>
来自：[航空学院的 Swift 字符串指引](https://flight.school/books/strings/)

当你 *能够* 创建自己的 `String` 等价类型时，[文档](https://developer.apple.com/documentation/swift/stringprotocol) 却有强烈的建议不要这样做：

> 不要声明 StringProtocol 新的遵循对象。保持在标准库中只有 `String` 和 `Substring` 是有效的遵循类型。

### 实现一个不区分大小写的属性修饰器

下面的 `CaseInsensitive` 类型实现了一个修饰 `String`/`SubString` 的属性修饰器。该类型通过桥接了 `NSString` 的 API [`caseInsensitiveCompare(_:)`](https://developer.apple.com/documentation/foundation/nsstring/1414769-caseinsensitivecompare) 遵循于 `Comparable`（并且扩展了 `Equatable`）：

```swift
import Foundation

@propertyWrapper
struct CaseInsensitive<Value: StringProtocol> {
    var wrappedValue: Value
}

extension CaseInsensitive: Comparable {
    private func compare(_ other: CaseInsensitive) -> ComparisonResult {
        wrappedValue.caseInsensitiveCompare(other.wrappedValue)
    }

    static func == (lhs: CaseInsensitive, rhs: CaseInsensitive) -> Bool {
        lhs.compare(rhs) == .orderedSame
    }

    static func < (lhs: CaseInsensitive, rhs: CaseInsensitive) -> Bool {
        lhs.compare(rhs) == .orderedAscending
    }

    static func > (lhs: CaseInsensitive, rhs: CaseInsensitive) -> Bool {
        lhs.compare(rhs) == .orderedDescending
    }
}
```

> 虽然大于运算符（`>`）[可以被自动派生](https://nshipster.com/equatable-and-comparable/#comparable)，我们为了优化性能应该在这里实现它，避免对底层方法 `caseInsensitiveCompare` 进行不必要的调用。

构造两个只是大小写不同的字符串，并且对于标准的相等检查他们会返回 `false`，但是在用 `CaseInsensitive` 对象修饰的时候返回 `true`。

```swift
let hello: String = "hello"
let HELLO: String = "HELLO"

hello == HELLO // false
CaseInsensitive(wrappedValue: hello) == CaseInsensitive(wrappedValue: HELLO) // true
```

到目前为止，这个方法跟上面提到的自定义"修饰器类型"没有区别。对于 `ExpressibleByStringLiteral` 和其他所有协议的遵循实现，如果想让大家像对 `String` 感觉满意那样，也使得 `CaseInsensitive` 让人逐渐开始觉得满足，那这只是漫长道路的简单开始。

属性修饰器允许我们完全抛下所有这些繁琐的工作：

```swift
struct Account: Equatable {
    @CaseInsensitive var name: String

    init(name: String) {
        $name = CaseInsensitive(wrappedValue: name)
    }
}

var johnny = Account(name: "johnny")
let JOHNNY = Account(name: "JOHNNY")
let Jane = Account(name: "Jane")

johnny == JOHNNY // true
johnny == Jane // false

johnny.name == JOHNNY.name // false

johnny.name = "Johnny"
johnny.name // "Johnny"
```

这里，`Account` 对象通过对他们的 `name` 属性进行一个不区分大小写的比较，以此来检查他们是否相等。但是当我们去获取或设置 `name` 属性时，它是一个 *真正的* `String` 值。

*这很整洁，但这里到底发生了什么？*

自 Swift 4 以来，编译器会在采用的类型声明中，自动生成 `Equatable` 的实现。并且其存储的属性本身都是 `Equatable`。由于编译器生成的都是实现好的（至少目前是），封装的属性是通过他们的修饰器进行比较，而不是他们背后的值。

```swift
// 有 Swift 编译器生成
extension Account: Equatable {
    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.$name == rhs.$name
    }
}
```

#### 有关想法

- 定义 `@CompatibilityEquivalence`，这样被修饰的 `String` 属性，在带有 `"①"` 和 `"1"` 的值会被认为是相等。
- 实现一个 `@Approximate` 属性修饰器，来重新定义浮点数类型的相等语义 （另见 [SE-0259](https://github.com/apple/swift-evolution/blob/master/proposals/0259-approximately-equal.md)）。
- 实现一个 `@Ranked` 属性修饰器，它会带有一个函数，函数中定义了枚举值的严格排序；这就会像打牌中的 `.ace` 排序，可以在不同的情况下分为高低两种。

<a name="auditing-property-access"></a>
## 审查属性访问

业务要求可能会用某些控制措施，规定谁可以访问哪些记录，或者规定一些形式表格要随着时间变换。

又来一次，这不是 iOS 应用程序通常执行的任务；许多业务逻辑是在服务器端定义的，并且大多数客户端开发者都希望保持这种方式。但当我们开始通过带有属性修饰器的眼镜看这个世界的时候，会发现这是另一种引人注目的用例，不容忽视。

### 实现属性值的版本管理

下面的 `Versioned` 结构体函数用作一个属性修饰器，拦截了输入的值，并在设置每个值的时候创建带时间戳的记录。

```swift
import Foundation

@propertyWrapper
struct Versioned<Value> {
    private var value: Value
    private(set) var timestampedValues: [(Date, Value)] = []

    var wrappedValue: Value {
        get { value }

        set {
            defer { timestampedValues.append((Date(), value)) }
            value = newValue
        }
    }

    init(initialValue value: Value) {
        self.wrappedValue = value
    }
}
```

假设有一个 `ExpenseReport` 的类可以用带有 `@Versioned` 封装它的 `state` 属性，使得处理过程中的每个操作都保留有记录。

```swift
class ExpenseReport {
    enum State { case submitted, received, approved, denied }

    @Versioned var state: State = .submitted
}
```

### 有关想法

- 实现一个 `@Audited` 属性修饰器可以每次读取或者写入的时候都打印到日志。
- 实现一个 `@Decaying` 属性修饰器，它在每次值被读取的时候都会去除以一个设定的值。

---

然而，这个特殊例子凸显出了一个当前属性修饰器主要的局限，这也是源于 Swift 存在已久的缺陷：**属性无法被标记为 `throws`。**

缺少参与错误处理的能力，属性修饰器没有提供和合理的方式去执行和沟通策略。例如，如果我们拓展 `@Versioned` 属性修饰器，防止在 `state` 属性的时候，在前一个值被 `.denied` 之后，不会被设为 `.approved`，我们的最好选择是 `fatalError()`，但它不是太适合真实的应用场景：

```swift
class ExpenseReport {
    @Versioned var state: State = .submitted {
        willSet {
            if newValue == .approved,
                $state.timestampedValues.map { $0.1 }.contains(.denied)
            {
                fatalError("J'Accuse!")
            }
        }
    }
}

var tripExpenses = ExpenseReport()
tripExpenses.state = .denied
tripExpenses.state = .approved // Fatal error: "J'Accuse!"
```

这只是我们目前遇到属性修饰器的几种局限之一。为了对这个新功能有一个公平的衡量角度，我们会用文章接下来的篇幅来列举它们。

## 局限性

> 下面描述的一些缺点可能更多地是我目前理解或者想象能力的局限，而不是已给出的语言本身。
> 如果你在解决问题的过程中，有任何纠正或者建议，欢迎 [指出](https://twitter.com/NSHipster/) 。

### 属性不能参与错误处理

属性不像函数，无法使用 `throws` 标记。

原本，这是和类型成员两者之间少数的几个区别之一。由于属性同时有获取方法（getter）和设置方法（setter），而且怎么样才是正确的设计也没有很清晰的规定，如果我们要添加错误处理——尤其是当你考虑要如何写出优雅的语法，还有其他像访问控制，自定义获取方法/设置方法和回调。

如上一节所述，属性修饰器有两个方法可以求助，用以解决非法值：

1. 忽略它们（静默地）
2. 用 `fatalError()` 抛出崩溃。

这些选项都不是特别的好，所以我们对解决这个问题的任何提议都很感兴趣。

### 已经被修饰的属性无法起别名

现在提议有另外一个限制，你不能使用属性修饰器的实例作为属性修饰器。

我们前面的 `UnitInterval` 例子中把修饰的值约束在 0 和 1（包含在内） 之间，它可以简述为：

```swift
typealias UnitInterval = Clamping(0...1) // ❌
```

但是，这是不可能的。你也不能使用属性修饰的实例来修饰属性。

```swift
let UnitInterval = Clamping(0...1)
struct Solution { @UnitInterval var pH: Double } // ❌
```

所有的这些事实上意味着，在实践中，更多的代码复制会比理想情况要好。但是，考虑到这个问题产生于一个语言中类型和值之间根本的区别，如果它意味这可以避免错误的抽象的话，我们可以稍微原谅一些重复的工作。

### 属性修饰器很难组合

属性修饰器的组合不是一个可交换的操作；你声明它们的顺序影响了它们的作用顺序。

属性在进行 [字符串变形](https://nshipster.com/valuetransformer/#thinking-forwards-and-backwards) 和其他字符串变换时，考虑下它们之间的相互影响。例如，有一个属性修饰器组合，是自动规范化博客文章中的 URL “slug” ，如果在空格被裁截之前或之后，用短划线替换空格，将会产生不同的结果。

```swift
struct Post {
    <#...#>
    @Dasherized @Trimmed var slug: String
}
```

但是，要让它先发挥作用，说起来容易做起来难！尝试组合 `String` 值的两个属性修饰器方法失败，因为最外层修饰器影响了在最内层的修饰器类型的值。

```swift
@propertyWrapper
struct Dasherized {
    private(set) var value: String = ""

    var wrappedValue: String {
        get { value }
        set { value = newValue.replacingOccurrences(of: " ", with: "-") }
    }

    init(initialValue: String) {
        self.wrappedValue = initialValue
    }
}

struct Post {
    <#...#>
    @Dasherized @Trimmed var slug: String // ⚠️ 发生内部错误.
}
```

有个办法可以让这个起作用，但它不完全清晰或让人觉得舒服。这是否可以在实现中修复或者仅仅通过文档的纠正仍有待观察。

### 属性修饰器不是一等依赖类型

*依赖类型* 是由它的值定义的类型。例如，“一对后者比前者更大的整数”和“一个具有素数元素的数组”都是依赖类型，因为他们的类型定义取决与他们的值。

Swift 在它的类型系统里面缺少对依赖类型的支持，这意味对依赖类型的保证必须在运行时执行。

好消息是，属性修饰器在填补这一空白上，比目前提出的任何其他语言特征更近一步了。但是，他们仍然不是真正值依赖类型的完全替代品。

有些事情你不能使用类型修饰器去做，例如定义一个新的类型，其中包含可能的值的约束。

```swift
typealias pH = @Clamping(0...14) Double // ❌
func acidity(of: Chemical) -> pH {}
```

你也不能使用属性修饰器去注解集合中的键类型或值类型。

```swift
enum HTTP {
    struct Request {
        var headers: [@CaseInsensitive String: String] // ❌
    }
}
```

这些缺点绝不是不能接受的；属性修饰器非常有用，并且弥补了语言中的重要空白。

不知道这些属性修饰器的附加功能会不会再次引起人们对 Swift 引入依赖类型的兴趣呢？这会很有趣。或者它们会被认为是已经“足够好”，因为它们避免进一步形式化概念的需要。

### 属性修饰器难以被文档化

**突击测验：**SwiftUI 框架提供了哪些可用的属性修饰器？

去吧，看下 [SwiftUI 官方文档](https://developer.apple.com/documentation/swiftui)，然后试着回答。

😬

公平地讲，这种失败不是属性修饰器所特有的。

如果你的任务是确定在标准库中哪一个协议是对一个特定 API 负责的，或者确定哪一个运算符是否支持 `developer.apple.com` 中文档记载的一对类型，你可能要开始考虑在职业生涯中从计算机行业转行了。

这种对可理解性的缺乏让事情变得更加可怕，也让 Swift 变得越来越复杂。

### 属性修饰器让 Swift 进一步复杂化

Swift 是一门比 Objective-C 更复杂 *许多* 的语言。自 Swift 1.0 以来，这一直都是真的，并且随着时间的推移变得更加如此。

Swift 中 `@` 前缀的丰富功能——不管它是不是 [`@dynamicMemberLookup`](https://github.com/apple/swift-evolution/blob/master/proposals/0195-dynamic-member-lookup.md) 还是从 Swift 4 以来的 [`@dynamicCallable`](https://github.com/apple/swift-evolution/blob/master/proposals/0216-dynamic-callable.md)，或者 [Swift for Tensorflow](https://github.com/tensorflow/swift) 中的 [`@differentiable` 和 `@memberwise`](https://forums.swift.org/t/pre-pitch-swift-differentiable-programming-design-overview/25992)——仅基于文档方面的 Swift APIs，这已经让它变得越来越难以形成合理的理解。在这方面，`@propertyWrapper` 的引入将是有力的增效器。

我们要如何理解这一切？（这是一个客观的真是问题，不是反问。）

---

好吧，让我们试着把这件事总结一下——

Swift 属性修饰器允许库作者使用之前为语言特性保留的那种高级方式。它们对提高代码安全性和降低代码复杂性潜力巨大，我们只是开始尽可能的抓住一些表层的东西。

然而，他们有所承诺，属性修饰器及其他语言特性与 SwiftUI 一起的首次亮相将给 Swift 带来了巨大的变化。

或者，正如 Nataliya Patsovska 在 [一篇推特](https://twitter.com/nataliya_bg/status/1140519869361926144) 中所提到的:

> iOS API 设计简史：
>
> - Objective C - 在名字中描述了所有语义，类型并不重要
> - Swift 1 到 5 - 名字侧重于清晰度，基础结构体，枚举，类和协议持有语义
> - Swift 5.1 - @wrapped \$path @yolo
> 
> ——[@nataliya_bg](https://twitter.com/nataliya_bg/)

也许我们后面回头看才能知道， Swift 5.1 是不是为我们热爱的语言树立了一个临界点或者转折点。