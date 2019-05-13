title: "Swift 5 字符串插值-AttributedStrings"
date: 
tags: [Swift 进阶，Swift]
categories: [Crunchy Development]
permalink: swift5-stringinterpolation-part2
keywords: swift 5，string，interpolation
custom_title: "Swift 5 字符串插值-简介"

------

原文链接=[http://alisoftware.github.io/swift/2018/12/16/swift5-stringinterpolation-part2/](http://alisoftware.github.io/swift/2018/12/16/swift5-stringinterpolation-part2/)
作者=Olivier Halligon
原文日期=2018-12-16
译者=Nemocdz
校对=
定稿=

 <!--此处开始正文-->

我们已经在 [前文](https://swift.gg/2019/04/22/swift5-stringinterpolation-part1/) 里介绍了 Swift 5 全新的 StringInterpolation 设计。在这第二部分中，我会着眼于 `ExpressibleByStringInterpolation` 其中一种应用，让 `NSAttributedString` 变得更优雅。

 <!--more-->

 ## 目标

我看到这个 [Swift 5 全新的 StringInterpolation 设计](https://github.com/apple/swift-evolution/blob/master/proposals/0228-fix-expressiblebystringinterpolation.md) 时其中一个马上想到的应用就是简化 `NSAttributedString` 的生成。

我的目标是可以用类似下面的语法创建一个 attributed 字符串：

```swift
let username = "AliGator"
let str: AttrString = """
  Hello \(username, .color(.red)), isn't this \("cool", .color(.blue), .oblique, .underline(.purple, .single))?

  \(wrap: """
    \(" Merry Xmas! ", .font(.systemFont(ofSize: 36)), .color(.red), .bgColor(.yellow))
    \(image: #imageLiteral(resourceName: "santa.jpg"), scale: 0.2)
    """, .alignment(.center))

  Go there to \("learn more about String Interpolation", .link("https://github.com/apple/swift-evolution/blob/master/proposals/0228-fix-expressiblebystringinterpolation.md"), .underline(.blue, .single))!
  """
```

这一大串字符串使用了多行字符串的字面量语法([Swift 4 中新增，以免错过](https://github.com/apple/swift-evolution/blob/master/proposals/0168-multi-line-string-literals.md)) - 更甚的是，在其中一个多行字符串字面量中包含了另一个(见 `\(wrap: ...)` 段落）！- 并且包含了插值给一部分字符添加一些样式…所以用上了大量的 Swift 新功能！

这个 `NSAttributedString` 一旦在一个 `UILabel` 或者 `NSTextView` 中渲染，结果应该看起来像这样子的：

![image](http://alisoftware.github.io/assets/StringInterpolation-AttrString.png)

☝️ 是的，上面的文字和图片…真的**只**是一个 `NSAttributedString`(而不是一个复杂的视图布局或者其他)！ 🤯

## 初步实现

所以我们从哪来开始实现？当然和我们在第一部分中如何实现 `GitHubComment` 是类似的！

好的，在实际解决字符串插值之前，让我们先从声明特有类型开始。

```swift
struct AttrString {
  let attributedString: NSAttributedString
}

extension AttrString: ExpressibleByStringLiteral {
  init(stringLiteral: String) {
    self.attributedString = NSAttributedString(string: stringLiteral)
  }
}

extension AttrString: CustomStringConvertible {
  var description: String {
    return String(describing: self.attributedString)
  }
}
```

挺简单的吧？仅仅给 `NSAttributedString` 封装了一下。现在，让我们添加 `ExpressibleByStringInterpolation` 的支持，来同时支持字面量和带 ` NSAttributedString` 属性注释的字符串。

```swift
extension AttrString: ExpressibleByStringInterpolation {
  init(stringInterpolation: StringInterpolation) {
    self.attributedString = NSAttributedString(attributedString: stringInterpolation.attributedString)
  }

  struct StringInterpolation: StringInterpolationProtocol {
    var attributedString: NSMutableAttributedString

    init(literalCapacity: Int, interpolationCount: Int) {
      self.attributedString = NSMutableAttributedString()
    }

    func appendLiteral(_ literal: String) {
      let astr = NSAttributedString(string: literal)
      self.attributedString.append(astr)
    }

    func appendInterpolation(_ string: String, attributes: [NSAttributedString.Key: Any]) {
      let astr = NSAttributedString(string: string, attributes: attributes)
      self.attributedString.append(astr)
    }
  }
}
```

这时，我们已经可以用下面这种方式简单地构建一个 `NSAttributedString` 了：

```swift
let user = "AliSoftware"
let str: AttrString = """
  Hello \(user, attributes: [.foregroundColor: NSColor.blue])!
  """
```

这看起来已经优雅多了吧？

## 方便的样式添加

但用字典 `[NAttributedString.Key: Any]` 的方式处理属性不够优雅。特别是由于 `Any` 没有明确类型，要求我们了解每一个键值的明确类型…

所以我们可以通过创建特有的 `Style` 类型让它变得更优雅，并帮助我们构建属性的字典：

```swift
extension AttrString {
  struct Style {
    let attributes: [NSAttributedString.Key: Any]
    static func font(_ font: NSFont) -> Style {
      return Style(attributes: [.font: font])
    }
    static func color(_ color: NSColor) -> Style {
      return Style(attributes: [.foregroundColor: color])
    }
    static func bgColor(_ color: NSColor) -> Style {
      return Style(attributes: [.backgroundColor: color])
    }
    static func link(_ link: String) -> Style {
      return .link(URL(string: link)!)
    }
    static func link(_ link: URL) -> Style {
      return Style(attributes: [.link: link])
    }
    static let oblique = Style(attributes: [.obliqueness: 0.1])
    static func underline(_ color: NSColor, _ style: NSUnderlineStyle) -> Style {
      return Style(attributes: [
        .underlineColor: color,
        .underlineStyle: style.rawValue
      ])
    }
    static func alignment(_ alignment: NSTextAlignment) -> Style {
      let ps = NSMutableParagraphStyle()
      ps.alignment = alignment
      return Style(attributes: [.paragraphStyle: ps])
    }
  }
}
```

这允许我们使用 `Style.color(.blue)` 来简单地创建一个封装了 `[.foregroundColor: NSColor.blue]` 的 `Style`。

但可别止步于此，现在让我们的 `StringInterpolation` 可以处理这样的 `Style` 属性！

这个想法是可以做到像这样写：

```swift
let str: AttrString = """
  Hello \(user, .color(.blue)), how do you like this?
  """
```

那不就更优雅？而我们仅仅需要为它正确实现 `appendInterpolation` 而已！

```swift
extension AttrString.StringInterpolation {
  func appendInterpolation(_ string: String, _ style: AttrString.Style) {
    let astr = NSAttributedString(string: string, attributes: style.attributes)
    self.attributedString.append(astr)
  }
```

然后我们就完成了！但…这样一次只支持一个 `Style`。为什么不让它允许传入多个 `Style` 作为形参呢？虽然可以用一个 `[Style]` 形参来实现，但这要求我们在调用侧将样式列表用括号括起来…为什么不让它使用可变形参呢？

让我们用这种方式来代替之前的实现：

```swift
extension AttrString.StringInterpolation {
  func appendInterpolation(_ string: String, _ style: AttrString.Style...) {
    var attrs: [NSAttributedString.Key: Any] = [:]
    style.forEach { attrs.merge($0.attributes, uniquingKeysWith: {$1}) }
    let astr = NSAttributedString(string: string, attributes: attrs)
    self.attributedString.append(astr)
  }
}
```

现在我们可以将多种样式混合起来了！

```swift
let str: AttrString = """
  Hello \(user, .color(.blue), .underline(.red, .single)), how do you like this?
  """
```

## 支持图像

`NSAttributedString` 的另一种能力是使用 `NSAttributedString(attachment: NSTextAttachment)` 添加图像，让它成为字符串的一部分。要实现它，仅需要实现 `appendInterpolation(image: NSImage)` 并调用它。

我希望为这个特性一并加上缩放图像的能力。由于我都是在 macOS 的 playground 上尝试的，它的图形上下文是翻转的，所以我也得将图像翻转回来（注意这个细节可能会和 iOS 上实现对 UIImage 的支持时不一样）。这里是我的做法：

```swift
extension AttrString.StringInterpolation {
  func appendInterpolation(image: NSImage, scale: CGFloat = 1.0) {
    let attachment = NSTextAttachment()
    let size = NSSize(
      width: image.size.width * scale,
      height: image.size.height * scale
    )
    attachment.image = NSImage(size: size, flipped: false, drawingHandler: { (rect: NSRect) -> Bool in
      NSGraphicsContext.current?.cgContext.translateBy(x: 0, y: size.height)
      NSGraphicsContext.current?.cgContext.scaleBy(x: 1, y: -1)
      image.draw(in: rect)
      return true
    })
    self.attributedString.append(NSAttributedString(attachment: attachment))
  }
}
```

## 样式嵌套

最后，有时候你会希望应用一个样式在一大段文字上，但里面可能包含了子段落的样式。就像 HTML 里的 `"<b>Hello <i>world</i></b>"`，整段是粗体但包含了一部分斜体的。

我们的 API 还不支持这样，所以让我们来加上它。思路是允许将一串 `Style…` 不止应用在 `String` 上，还能应用在已经存在属性的 `AttrString` 上。

这个实现和 `appendInterpolation(_ string: String, _ style: Style…)` 相似，但会修改 `AttrString.attributedString` 来*添加*属性到上面，而不是用纯 `String` 创建一个全新的 `NSAttributedString`。

```swift
extension AttrString.StringInterpolation {
 func appendInterpolation(wrap string: AttrString, _ style: AttrString.Style...) {
    var attrs: [NSAttributedString.Key: Any] = [:]
    style.forEach { attrs.merge($0.attributes, uniquingKeysWith: {$1}) }
    let mas = NSMutableAttributedString(attributedString: string.attributedString)
    let fullRange = NSRange(mas.string.startIndex..<mas.string.endIndex, in: mas.string)
    mas.addAttributes(attrs, range: fullRange)
    self.attributedString.append(mas)
  }
}
```

完成上面全部的这些，我们就达成目标了，终于可以用单纯的字符串加上插值创建一个 AttributedString：

```swift
let username = "AliGator"
let str: AttrString = """
  Hello \(username, .color(.red)), isn't this \("cool", .color(.blue), .oblique, .underline(.purple, .single))?

  \(wrap: """
    \(" Merry Xmas! ", .font(.systemFont(ofSize: 36)), .color(.red), .bgColor(.yellow))
    \(image: #imageLiteral(resourceName: "santa.jpg"), scale: 0.2)
    """, .alignment(.center))

  Go there to \("learn more about String Interpolation", .link("https://github.com/apple/swift-evolution/blob/master/proposals/0228-fix-expressiblebystringinterpolation.md"), .underline(.blue, .single))!
  """
```

![imgage](http://alisoftware.github.io/assets/StringInterpolation-AttrString.png)

## 结论

我希望你享受这一系列 `StringInterpolation` 文章，让你能瞥到这个新设计威力的冰山一角。

你可以 [在这下载我的 Playground 文件](http://alisoftware.github.io/assets/StringInterpolation.playground.zip) 看到 `GitHubComment`(见 [第一部分](http://alisoftware.github.io/swift/2018/12/15/swift5-stringinterpolation-part1/))，`AttrString` 的全部实现，说不定还能在我尝试的 `RegEX` 简单实现中得到一些灵感。

这里有着很多更好的思路去使用 Swift 5 中新的 `ExpressibleByStringInterpolation` API - 包括 [Erica Sadun 博客里这个](https://ericasadun.com/2018/12/12/the-beauty-of-swift-5-string-interpolation/)、[这个](https://ericasadun.com/2018/12/14/more-fun-with-swift-5-string-interpolation-radix-formatting/) 和 [这个](https://ericasadun.com/2018/12/16/swift-5-interpolation-part-3-dates-and-number-formatters/) - 不要犹豫，阅读它们…从中享受乐趣吧！

---

1. 这篇文章和 Playground 里的代码，需要使用 Swift 5。在写作时，最新的 Xcode 版本是 10.1，Swift 4.2，所以你如果想尝试这些代码你需要遵循官方指南去下载开发中的 Swift 5 快照。安装 Swift 5 工具链并在 Xcode 偏好设置启用里是很简单的(见官方指南)。
2. 当然，在这我只是实现一部分样式，仅仅做为 Demo。未来顺着思路延伸可以让 `Style` 类型支持更多的样式，理想情况下可以覆盖所有可能存在 `NSAttributedString.Key`。