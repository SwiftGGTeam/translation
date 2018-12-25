title: "Swift 5 字符串插值之美"
date: 2018-12-12
tags: [Swift]
categories: [ericasadun.com]
permalink: the-beauty-of-swift-5-string-interpolation
keywords: Swift 5, String Interpolation
custom_title: Swift 5 字符串插值之美
description: 本文对 Swift 5 中 SE-0228 对 String Interpolation 相关功能的改进进行了举例说明，展示了一些控制字符串插值的方式。

---

原文链接=https://ericasadun.com/2018/12/12/the-beauty-of-swift-5-string-interpolation/ 
作者=Erica Sadun 
原文日期=2018-12-12 
译者=Roc Zhang 
校对= 
定稿= 

<!--此处开始正文-->

感谢提案 [SE-0228](https://github.com/apple/swift-evolution/blob/master/proposals/0228-fix-expressiblebystringinterpolation.md)，让我们能够用希望的方式去精确控制字符串插值的打印方式。感谢 Brent 把这个非常棒的功能带给我们。让我来分享一些例子。

<!--more-->

回想一下在我们要打印可选值的时候，会这样写：

```swift
"There's \(value1) and \(value2)"
```

会立即得到一个警告：
![](https://i2.wp.com/ericasadun.com/wp-content/uploads/2018/12/Screen-Shot-2018-12-12-at-2.38.51-PM.png?w=1065&ssl=1)

我们可以点击修复按钮来消除这些警告，但仍然会看到一个类似于这样的输出：“There’s Optional(23) and nil”。

```swift
"There's \(String(describing: value1)) and \(String(describing: value2))"
```

上面这种写法可以去掉“Optional”，直接打印值。我们还可以进一步优化：

```swift
extension String.StringInterpolation {
  /// 提供 `Optional` 字符串插值
  /// 而不必强制使用 `String(describing:)`
  public mutating func appendInterpolation(_ value: T?, default defaultValue: String) {
    if let value = value {
      appendInterpolation(value)
    } else {
      appendLiteral(defaultValue)
    }
  }
}

// There's 23 and nil
"There's \(value1, default: "nil") and \(value2, default: "nil")"

```

我们也可以创建一组样式，从而使可选值能够保持一致的输出展示方式：

```swift
extension String.StringInterpolation {
  /// 可选值插值样式
  public enum OptionalStyle {
    /// 有值和没有值两种情况下都包含单词 `Optional`
    case descriptive
    /// 有值和没有值两种情况下都去除单词 `Optional`
    case stripped
    /// 使用系统的插值方式，在有值时包含单词 `Optional`，没有值时则不包含
    case `default`
  }

  /// 使用提供的 `optStyle` 样式来插入可选值
  public mutating func appendInterpolation(_ value: T?, optStyle style: String.StringInterpolation.OptionalStyle) {
    switch style {
    // 有值和没有值两种情况下都包含单词 `Optional`
    case .descriptive:
      if value == nil {
        appendLiteral("Optional(nil)")
      } else {
        appendLiteral(String(describing: value))
      }
    // 有值和没有值两种情况下都去除单词 `Optional`
    case .stripped:
      if let value = value {
        appendInterpolation(value)
      } else {
        appendLiteral("nil")
      }
    // 使用系统的插值方式，在有值时包含单词 `Optional`，没有值时则不包含
    default:
      appendLiteral(String(describing: value))
    }
  }

  /// 使用 `stripped` 样式来对可选值进行插值
  /// 有值和没有值两种情况下都省略单词 `Optional`
  public mutating func appendInterpolation(describing value: T?) {
    appendInterpolation(value, optStyle: .stripped)
  }

}

// "There's Optional(23) and nil"
"There's \(value1, optStyle: .default) and \(value2, optStyle: .default)"

// "There's Optional(23) and Optional(nil)"
"There's \(value1, optStyle: .descriptive) and \(value2, optStyle: .descriptive)"

// "There's 23 and nil"
"There's \(describing: value1) and \(describing: value2)"

```

插值不仅仅可用于调整可选值的输出方式。假设你想控制是否要添加一个字符串，而不必去使用带有空字符串的三元表达式：

```swift
// 成功时包含（感谢 Nate Cook）
extension String.StringInterpolation {
  /// 只有 `condition` 的返回值为 `true` 才进行插值
  mutating func appendInterpolation(if condition: @autoclosure () -> Bool, _ literal: StringLiteralType) {
    guard condition() else { return }
    appendLiteral(literal)
  }
}

// 旧写法
"Cheese Sandwich \(isStarred ? "(*)" : "")"

// 新写法
"Cheese Sandwich \(if: isStarred, "(*)")"
```

我们还可以用字符串插值来做更多有趣的事情。
