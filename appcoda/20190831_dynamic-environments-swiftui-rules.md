title: "SwiftUI 规则"
date: 
tags: [SwiftUI, 声明式]
categories: [SwiftUI, 特性]
permalink: swiftuirules
keywords: SwiftUI, SwiftUI Rules, Environment, 声明式
custom_title: SwiftUI 规则
description: SwiftUI 支持一种叫做 Environment 的特性。它允许我们给子视图注入值，而不是显式的传值。SwiftUI 规则新增了一个声明式规则系统：SwiftUI 的级联样式表。

---
原文链接=http://www.alwaysrightinstitute.com/swiftuirules/
作者=Helge Heß
原文日期=2019-08-31
译者=ericchuhong
校对=
定稿=

<!--此处开始正文-->

![SwiftUIRulesIcon128](http://www.alwaysrightinstitute.com/images/swiftuirules/SwiftUIRulesIcon128.png)

[SwiftUI](https://developer.apple.com/xcode/swiftui/) 支持一种叫做 [Environment](https://developer.apple.com/documentation/swiftui/environment) 的特性。它允许我们给子视图注入值，而不是显式的传值。 [SwiftUI 规则](https://github.com/DirectToSwift/SwiftUIRules) 增加了一个声明式规则系统：SwiftUI 的级联样式表。
<!--more-->
> 将是完全声明式的: SwiftUI 规则.

## SwiftUI Environments

在我们开始讨论 [SwiftUI 规则](https://github.com/DirectToSwift/SwiftUIRules) 之前，让我们先回顾一下 [SwiftUI](https://developer.apple.com/xcode/swiftui/) 中常规的 environments 是如何工作的。

在这里，我们对下方所有 `Text` 视图使用 `lineLimit` 视图修饰语，规定它们有相同的行数约束，注意这里视图不管如何嵌套都没有关系：
```swift
struct Page: View {
  var body: some View {
    VStack {
      HStack {
        Text("Bla blub loooong text") // 行数限制是 3 行
        Spacer()
      }
      Text("Blub bla")                // 行数限制是 3 行
    }
    .lineLimit(3) // 修饰 environment
  }
}
```
`lineLimit` 不仅是 `Text` 视图上的一个方法，也可以被视图层次结构中任何视图对象访问，并在任何地方设值。同时会下渗到自身视图层次之下的任一（想要使用它的）视图。

对于下面这个更加常见的修饰语，`.lineLimit` 修饰语只是一个语法糖。
```swift
SomeView()
  .environment(\.lineLimit, 3)
```

`Text` 视图是如何获得限制它渲染的值呢？它是用了 [@Environment](https://developer.apple.com/documentation/swiftui/environment) 属性封装器来提取这个值。我们也可以效仿着来做：
```swift
struct ShowLineLimit: View {
  
  @Environment(\.lineLimit) var limit
  
  var body: some View {
    Text(verbatim: "The line limit is: \(limit)")
  }
}
```

请注意 environment 可以在任意一视图层次中_变换_：
```swift
var body: some View {
  VStack {
    ShowLineLimit()   // 限制 3 行
    ShowLineLimit()   // 限制 3 行
    Group {
      ShowLineLimit() // 限制 5 行
    }
    .environment(\.lineLimit, 5)
  }
  .environment(\.lineLimit, 3)
}
```

## 声明自己的 Environment 键

SwiftUI environments 对内置键的数量是不限制的，你可以添加自己的键。除了 `foregroundColor` 之外，我们如果说想要添加一个自己的 environment 键，叫做 `fancyColor`。

我们首先需要一个对 [`EnvironmentKey`](https://developer.apple.com/documentation/swiftui/environmentkey) 进行声明：
```swift
struct FancyColorEnvironmentKey: EnvironmentKey {
  public static let defaultValue = Color.black
}
```
最关键是指定 environment key (`Color`) 为静态 Swift 类型，然后赋给它一个默认值。当 environment key 被访问的时候这个值就会被用到，但不会让用户显式地给它赋值。

其次，我们需要在 [EnvironmentValues](https://developer.apple.com/documentation/swiftui/environmentvalues) 结构体中声明一个属性：
```swift
extension EnvironmentValues {
  var fancyColor : Color {
    set { self[FancyColorEnvironmentKey.self] = newValue }
    get { self[FancyColorEnvironmentKey.self] }
  }
}
```
这样就可以了。我们可以开始使用我们的新 key 了。

> [EnvironmentValues](https://developer.apple.com/documentation/swiftui/environmentvalues) 这个结构体代表了视图当前使用中的值。开发者不能直接访问到它底层的数据。想要访问的当前状态，下标值需要用 **type** 作为 key。

所以我们应该如何使用它呢？还是跟之前展示过的一样！让某个 View 通过使用 [@Environment](https://developer.apple.com/documentation/swiftui/environment) 属性封装器访问我们崭新的 key —— `fancyColor`：
```swift
struct FancyText: View {
  
  @Environment(\.fancyColor) private var color
  
  var label : String
  
  var body: some View {
    Text(label)
      .foregroundColor(color) // 十分无聊
  }
}
```

另一个 View 来提供它的值：
```swift
struct MyPage: View {
  
  var body: some View {
    VStack {
      Text("Hello")
      FancyText("World")
    }
    .environment(\.fancyColor, .red)
  }
}
```

顺着视图层次结构传递值多么简单和高效。

> 那如果是 [EnvironmentObject](https://developer.apple.com/documentation/swiftui/environmentobject) 呢？它们和常规的 environment 值很相似，但规定了对应值的类型需要遵循 ObservableObject 协议。对一些简单的行限制或者颜色限制规则来说，这显得有点太繁琐了。

# SwiftUI 规则

这个概念已经是相当棒而且强大了！但目前为止 environment key 仍需要有静态值的支持。它们需要通过 `.environment` 视图封装器（如果为空则是 `defaultValue` ）来赋值到当前的 enviroment。

如果我们能够避免 `.environment(\.fancyColor, .red)` 这样的声明，然后基于其他 environment key 的值定义我们自己的 `fancyColor` 呢？这甚至可以**制定**如何从其他 key 值衍生的规则。**欢迎来到 [SwiftUI 规则](https://github.com/DirectToSwift/SwiftUIRules)**：

```swift
let ruleModel : RuleModel = [
  (\.todo.priority == .low)    => (\.fancyColor <= .gray),
  (\.todo.priority == .high)   => (\.fancyColor <= .red),
  (\.todo.priority == .normal) => (\.fancyColor <= .black)
]
```

首先这里假设当前 environment 带有一个 `todo` 的 environment key，而且这个 environment key 持有一个 todo 对象。然后我们定义了值 `fancyColor` 将带有 todo 的 priority 值。通过用**规则**，我们**声明**了它。 

## Rules

一个规则有三个主要的组成部分：

### 谓词

一个**谓词**或者说“规则条件”。谓词获取规则上下文，决定规则是否应用于当前的上下文状态。
在示例中的 `\.todo.priority == .low` 就是这样的谓词。如果在上下文中的 todo 对象中有一个值为 `.low` 的优先级，规则的值就会被拦截处理。

谓词是可选实现的：如果没有提供实现，那规则匹配的结果就总是成功。

### Environment Key

**environment key** 适用于我们例子中的 `fancyColor`。那意味着如果一个 View 想要 `fancyColor` 环境值，规则引擎将会找到规则中可以给 key 用的那个。
之后它会检查对应谓词是否匹配，如果匹配的话……

### 规则值
……就返回**返回规则值**，例如示例中高优先级的待办所对应的 `Color.red`。规则值也不需要是一个常量键，它可以是一个关键路径（key path）。也就是说一个规则值可以通过获取 _另外一个键_ 的值来表示！

## 编码

编写一个规则的代码可以是这样：
```swift
predicate => environment key <= rule-value
```
例如（括号只是为了区分出各个部分）
```swift
(\.todo.priority == .low) => (\.fancyColor <= .gray)
```
这里**声明**了如果待办的优先级是 `.low`（谓词）。被使用的 `fancyColor`（键）就是 `gray`（规则值）。

## 递归规则

有一个 page 视图定义如下：
```swift
struct PageView: View {
  
  @Environment(\.navigationBarTitle) var title
  
  var body: some View {
    TodoView()
      .navigationBarTitle(title)
  }
}
```

然后一个对象使用了**递归规则**的值：
```swift
let ruleModel : RuleModel = [
  \.todo.title == "IMPORTANT" => \.title <= "Can wait."
  \.title              <= \.todo.title // 没有谓词，总是为真
  \.navigationBarTitle <= \.title
]
```

大概意思就是：给导航栏使用这个标题。这个标题是待办的标题。除非待办的是 "IMPORTANT"，我们才用 "Can wait." 重写它。

详细讲讲过程中发生的事情：

1. `PageView` 中的 `@Environment` 想获取 `navigationBarTitle`，
2. 规则系统查看了模型，并找到了标题的这个规则：`\.navigationBarTitle <= \.title`，
3. 规则系统从自身请求 `title` 的值，
4. 规则系统查看了模型，然后给标题找到了 *两个* 规则：
   1. `\.todo.title == "IMPORTANT" => \.title <= "Can wait."`
   2. ` \.title              <= \.todo.title`
5. 对于 `title` 有两个选项，一个带有谓词的规则而另外一个没有。它首先检查了更高优先级的谓词 “complexity” - 它评估出 `\.todo.title == "IMPORTANT"`。
6. 它去查找了在 environment 中的 `todo` 对象，然后将它标题和常量 “IMPORTANT” 对比。假若情况是谓词匹配到了，规则就会被使用，`title` 的值将会是 `“Can wait.”`。
7. 规则系统现在决策出 `title` 的值 - `"Can wait."`，然后返回给 `navigationBarTitle`，并把值赋值到 `PageView`。

要留意的关键点是一个规则可以从其他规则中声明。

> 在这里示例中，规则的顺序没有太大关系，因为他们有一个基于谓词关系复杂度继承的顺序。但是，有可能会有多个规则同时匹配。在这情况下，你可以给规则设一个显式的优先级例如（例如：在规则中调用 `.priority(.high)`）。

# 使用 SwiftUI 规则

这个 [仓库](https://github.com/DirectToSwift/SwiftUIRules) 在 [`Samples`](https://github.com/DirectToSwift/SwiftUIRules/tree/develop/Samples/)
子文件夹中提供了一个小型的 [示例应用](https://github.com/DirectToSwift/SwiftUIRules/tree/develop/Samples/RulesTestApp)，去看看吧。它虽然是个没什么条理的示例，但是展示了如何设置和运行整个架构。

## 在你的 View 中使用基于规则的属性
一般规则系统不关心中你的 View 是否有 SwiftUI 规则。所有的值都被当作常规的 [Environment](https://developer.apple.com/documentation/swiftui/environment) 属性：

```swift
struct FancyText: View {
  
  @Environment(\.fancyColor) private var color
  
}
```

## 暴露你的 EnvironmentKeys 给规则系统

我们上面展示了你要如何给静态环境值声明你自己的环境键。为了 “规则能作用” 于它们，你需要轻微调整一下。

首先，声明它们为 **[`DynamicEnvironmentKey`](https://github.com/DirectToSwift/SwiftUIRules/blob/develop/Sources/SwiftUIRules/DynamicEnvironment/DynamicEnvironmentKey.swift#L17)** 的，而不是 [`EnvironmentKey`](https://developer.apple.com/documentation/swiftui/environmentkey)。

```swift
struct FancyColorEnvironmentKey: DynamicEnvironmentKey { // <==
  public static let defaultValue = Color.black
}
```

其次，在 **[DynamicEnvironmentPathes](https://github.com/DirectToSwift/SwiftUIRules/blob/develop/Sources/SwiftUIRules/DynamicEnvironment/DynamicEnvironmentPathes.swift#L19)** 声明属性，而不是在 `EnvironmentValues`，接着使用 **`dynamic` 下标**：
```swift
extension DynamicEnvironmentPathes { // <==
  var fancyColor : Color {
    set { self[dynamic: FancyColorEnvironmentKey.self] = newValue }
    get { self[dynamic: FancyColorEnvironmentKey.self] }
  }
}
```

这就是全部需要调整的地方了。

## 设置一个规则的 Environment

我们推荐创建一个 `RuleModel.swift` Swift 文件。把你全部的规则放在最重要的位置。
```swift
// RuleModel.swift
import SwiftUIRules

let ruleModel : RuleModel = [
  \.priority == .low    => \.fancyColor <= .gray,
  \.priority == .high   => \.fancyColor <= .red,
  \.priority == .normal => \.fancyColor <= .black
]
```

你可以在 SwiftUI 视图层次架构中的任何地方拦截注入规则系统，但我们依旧推荐在每个最上层的视图中做。例如，在 Xcode 中新生成一个应用，你可以给生成的 `ContentView` 做如下的修改：

```swift
struct ContentView: View {
  private let ruleContext = RuleContext(ruleModel: ruleModel)
  
  var body: some View {
    Group {
      // 你的视图
    }
    .environment(\.ruleContext, ruleContext)
  }
}
```

经常有些 “root” 属性需要被注入：
```swift
struct TodoList: View {
  let todos: [ Todo ]
  
  var body: someView {
    VStack {
      Text("Todos:")
      ForEach(todos) { todo in
        TodoView()
           // make todo available to the rule system
          .environment(\.todo, todo)
      }
    }
  }
}
```
`TodoView` 和子视图现在就可以使用规则系统获取 `todo` 键的环境值。

## 用例

哈！还有呢 🤓 它和 “Think In Rules”™（又称声明式）差别很大，但是它们可以让你以一种高度解耦的方式来组合应用，实际上还是“声明式”的方式。

它可以被简简单单的使用，像是 CSS。从各方面考虑，动态环境键有点像是 CSS 类。例如：你可以实现基于平台切换设置：
```swift
[
  \.platform == "watch" => \.details <= "minimal",
  \.platform == "phone" => \.details <= "regular",
  \.platform == "mac" || \.platform == "pad" 
  => \.details <= "high"
]
```

但它也可以被用得很高级，例如在一个工作流系统：
```swift
[
  \.task.status == "done"    => \.view <= TaskFinishedView(),
  \.task.status == "done"    => \.actions <= [],
  \.task.status == "created" => \.view <= NewTaskView(),
  \.task.status == "created" => \.actions = [ .accept, .reject ]
]

struct TaskView: View {
  @Environment(\.view) var body // body derived from rules
}
```

因为 SwiftUI Views 也只是一个轻量的结构体，你可以构建动态的属性携带它们！

不管怎么说：我们对任何关于它的使用方法都感兴趣！

## 限制

### 仅限 `DynamicEnvironmentKey`

当前的规则只可以推导出 [`DynamicEnvironmentKey`](https://github.com/DirectToSwift/SwiftUIRules/blob/develop/Sources/SwiftUIRules/DynamicEnvironment/DynamicEnvironmentKey.swift#L17)。它没有把常规的环境键计算在内。也就是说，你不能像内置 SwiftUI `lineLimit` 那样用规则系统去驱动。
```swift
[
  \.user.status == "VIP" => \.lineLimit <= 10,
  \.lineLimit <= 2
]
```
**这没有效果**。这是当下依赖系统使用的键来显式创建才有的 [`DynamicEnvironmentKey`](https://github.com/DirectToSwift/SwiftUIRules/blob/develop/Sources/SwiftUIRules/DynamicEnvironment/DynamicEnvironmentKey.swift#L17) 类型。所以你没办法立刻就用上。

我们有可能会开放它给任意的
[`EnvironmentKey`](https://developer.apple.com/documentation/swiftui/environmentkey)，有待商榷。

### 不要用键路径赋值

有时候有人会想要这样做：
```swift
\.todos.count > 10 => \.person.status <= "VIP"
```
也就是赋值给一个多组合关键路径（`\.person.status`）。这样是**无法运行**的。

### SwiftUI 的 Bug

有时候，SwiftUI 在导航或者位于列表中时会“丢失”它的 environment。watchOS 和 macOS 似乎尤其容易出现这个问题，这样的情况 iOS 则少点。如果发生了，可以通过 `ruleContext` 手动传递：
```swift
struct MyNavLink<Destination, Content>: View {
  @Environment(\.ruleContext) var ruleContext
  ...
  var body: someView {
    NavLink(destination: destination
      // 显式向前传递:
      .environment(\.ruleContext, ruleContext)) 
  ...
}
```

# 总结

我们希望你喜欢它！

## 链接

- [SwiftUI 规则](https://github.com/DirectToSwift/SwiftUIRules)
  - [SOPE 规则系统](http://sope.opengroupware.org/en/docs/snippets/rulesystem.html)
- iOS Astronaut: [在 SwiftUI 中自定义 @Environment 键](https://sergdort.github.io/custom-environment-swift-ui/)
- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
  - [SwiftUI 入门介绍](https://developer.apple.com/videos/play/wwdc2019/204/) (204)
  - [SwiftUI 要素](https://developer.apple.com/videos/play/wwdc2019/216) (216)
  - [SwiftUI 中的数据流](https://developer.apple.com/videos/play/wwdc2019/226) (226)
  - [SwiftUI 架构 API](https://developer.apple.com/documentation/swiftui)

## 联系方式

嘿！我们希望你喜欢这篇文章，并且我们喜欢反馈！这下面任意一个的 Twitter：
[@helje5](https://twitter.com/helje5)，[@ar_institute](https://twitter.com/ar_institute)。
邮箱：[wrong@alwaysrightinstitute.com](mailto:wrong@alwaysrightinstitute.com)。
Slack：在 SwiftDE，swift-server，noze，ios-developers 可以找到我们。