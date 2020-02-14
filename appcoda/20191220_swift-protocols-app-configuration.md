title: "如何利用 Swift 协议来管理应用配置"
date: 2019-12-20
tags: [教程]
categories: [AppCoda]
permalink: swift-protocols-app-configuration
keywords: 协议，应用配置
custom_title: 如何利用 Swift 协议来管理应用配置
description: 本文详细讲解了如何利用 Swift 协议来管理应用配置。

---
原文链接=https://www.appcoda.com/swift-protocols-app-configuration/
作者=Gabriel Theodoropoulos
原文日期=2019-08-30
译者=Joeytat
校对=
定稿=

<!--此处开始正文-->
大家好，欢迎阅读这篇新教程！协议是广大程序员在使用 Swift 时最常接触和使用的概念之一，我认为不会有不知道协议的程序员。协议常常被用于各种目的，但被大家记住的永远都是苹果官方文档中所描述的：

> 协议是定义方法，属性和其他符合某种特殊任务要求的蓝图。协议可以被类，结构体或是枚举采用，根据其定义提供符合要求的实现。任何类型只要满足了协议的要求，就可以被称为是遵循了该协议。
<!--more-->

简而言之，一个 Swift 协议定义了一些方法和属性，需要由协议遵循类型（类，结构体，枚举）来实现。定义的这些方法和属性被称为*约定*。

协议特别有趣的一点在于，可以简单地通过对协议提供扩展，来提供默认实现的能力。事实上正是这个功能，让协议可以如此强大并且成为 Swift 开发中流行话题的原因。通过定义一组方法来描述一系列功能，并对它们提供基础的实现。甚至可以让与其无关的类，结构体，枚举类型（与之相反的例子是类的继承）也能够获得一个通用的附加功能，这些附加能力扩展了它们的功能性。

如果你是一个新手开发者，那么我强烈推荐你阅读 [**更多关于协议的信息**](https://docs.swift.org/swift-book/LanguageGuide/Protocols.html)，你可以在那里发现有许多有趣的信息。

好了，那到底协议与这篇文章标题所说的应用设置有什么关系吗？让我来解释一下其中的联系。很久以来，我一直都因 [**UserDefaults**](https://developer.apple.com/documentation/foundation/userdefaults) 是唯一可以快速地存储少量数据的机制而感到苦恼。毋庸置疑 User Defaults 是挺好的，但这是一种笼统地并且不 “Swifty” 的方案（说实话，我已经很少使用它们了）。我需要的是一种能够为我的每个应用量身定做的解决方案。迈向这个目标的第一步很简单：创建一个包含了应用配置和用户偏好的类或者是结构体。然而这个方案的缺点在于所有的这些选项，都需要对应的文件操作方法（保存，加载，删除）。方法应该只编写*一次*，就能够在*任何*地方被*任何类型*使用。通过类和继承来实现这些基础功能的想法可以直接抛弃了，因为这会阻碍我们使用结构体（`struct`）。这就是协议大展身手的时候了！

通过协议定义一系列负责文件处理的方法，以及通过协议扩展提供这些方法的默认实现。这样一来每一个遵循了协议的类或结构体，都能够获得相同的文件相关的功能！不仅如此，支持了各种设置的类或结构体还能以这种方式同时存在于应用中，这些数据也能被分别处理。换句话说，这种协议就像是某种即插即用机制，可以使任何遵循它的自定义类型具备保存和读取数据的能力。

这是我长期以来都在使用的解决方案，现在是时候将它拿出来在这讨论了。这篇文章所讨论的内容很显然是针对 Swift 开发新人的，可以让他们了解协议，以及协议的实际用法。毫无疑问高级开发者们早已有了类似的解决方法，但无论你处于什么阶段，都推荐继续阅读下去。

## 线路图
今天的目标是创建一个协议，让遵循它的类型能以文件的形式很方便的读取或写入。将其命名为 **SettingsManageable**。我们将一步一步地从零开始，直到最后让它完全正确地运作。但是要记住，我们的重点是如何轻松地处理应用的设置以及设置相关的通用类型，并不是实现如何通过不同地方式来保存各种的类或结构体的数据。所以为了达成这个目的，接下来将要创建的文件是 *属性列表*（.plist）。毕竟当考虑到设置的实现时，编辑一个属性列表通常会是首先出现在脑海中的方案。为了更好玩一些，我们要加上对应用包中默认初始设置文件的处理（那些可以在 Xcode 属性列表编辑器中编辑的设置）。

在完成实现之后，我们还会看到一些如何使用这个协议的简单示例。虽然在这里处理的是属性列表数据，但也欢迎你来进行更深入的扩展，让协议更通用，让它可以支持任何自定义类型以及其他的数据类型，比如 JSON 或是纯文本。

最后，这里有一个供你下载的 [启动项目](https://github.com/appcoda/AppSettings/raw/master/starter.zip)。在这个项目中，你可以找到一些表示设置的自定义类型，我们将会用协议对其改造。在你下载之后，请用 Xcode 打开然后往下阅读。

## 开始：创建协议
让我们打开启动项目，然后创建一个用于实现协议的新文件来开始实践吧。在 Xcode 中，在键盘上按下 *Command+N* 或者通过选择菜单栏 *File > New > File...*。选择 *Swift File* 作为文件模版，然后点击 Next 按钮。

下一步，你必须给这个文件命名。用协议的名字来对其命名：**SettingsManageable**。然后按下 *Return* 或点击 *Create* 按钮，来让 Xcode 真正地创建新文件。

> 注意： 这篇文章中的代码是在 Xcode 10.3 中创建的，这是在撰写这篇文章时最新且最稳定的 Xcode 版本。

当新文件准备好时，去 `Project Navigator` 选中并且打开它。协议的定义是：

```swift
protocol SettingsManageable {

} 
```

我之前简单地解释过，我们将会在 `SettingsManageable` 协议中定义方法，然后提供默认的行为实现，这样可以通过遵循协议来得到我们想要的功能。在明确这一点之后，直接在上面这个协议的花括号后面加上几个空行，然后定义它的扩展：

```swift
extension SettingsManageable where Self: Codable {

}
```

注意在这里设置的条件。通过扩展尾部的 `where Self: Codable` 条件，我们要求了任何自定义类型在遵循 `SettingsManageable` 协议的同时，也要遵循 [`Codable`](https://developer.apple.com/documentation/swift/codable) 协议。

为什么我们需要 `Codable`？因为我们会对遵循了 `SettingsManageable` 的自定义类型中的值及该类型的属性列表数据，进行*编码*和*解码*。

这样可以避免有的类型没有遵循 `Codable`，但遵循了 `SettingsManageable`，导致我们接下来无法为其提供正确的功能。

## 定义并且实现协议的要求
这是这篇文章最有趣的部分了，当我们实现了所有的方法之后，就能够让任何遵循了 `SettingsManageable` 的类或结构体自动地保存及加载自身。因此我们作为开发者，可以在没有任何代价的情况下，将它们当作是设置或偏好选项来对其改动或是更新。从现在起，我们将会定义协议中的每一个方法，并且我们会在协议扩展中提供对应的实现。话不多说，让我们开始吧！

### 获取文件 URL
任何遵循了 `SettingsManageable` 协议的自定义类型（类，结构体，甚至是枚举）的值都会被存储在属性列表文件中。我们会将这些文件保存在应用的 *Caches* 目录下，这也将是我们的起点：获取到设置文件的 URL！

向协议中添加下面方法的定义：

```swift
protocol SettingsManageable {
    func settingsURL() -> URL
}
```

在协议扩展中我们对其实现：

```swift
extension SettingsManageable where Self: Codable {
    func settingsURL() -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cachesDirectory.appendingPathComponent("\(Self.self).plist")
    }
}
```

第一行从缓存目录获取到了 URL。第二行将**遵循了 `SettingsManageable` 自定义类型添加到了 URL 末尾**，还加上了 **“.plist” 扩展**，然后我们将其返回。

注意 `\(Self.self)` 动态地提供了遵循 `SettingsManageable` 的类型的名字。这挺酷的，因为这样每个类或结构体都会有属于自己名字的 .plist 文件存储在缓存目录下，并且不会重复。举例来说，一个叫 “Settings” 的类遵循了 `SettingsManageable`，那么就会在缓存目录中创建一个叫做 “Settings.plist” 的文件，当有一个叫 “AppColors” 的结构体遵循了 `SettingsManageable` 协议，那么也就会有一个 “AppColors.plist” 的文件。

### 存储（更新）一个 SettingsManageable 实例
毋庸置疑上面实现的方法是非常实用的，但是它也只是一个为了方便的辅助方法，我们完全可以在没有它的情况下处理事情。接下来才是第一个必备的方法，我们将要处理一些真正重要的事情：将遵循了协议的类型的所有属性保存到属性列表文件中。“保存”这个词涵盖了两种不同的行为：

  1. 编码为属性列表
  2. 写入文件

再次回到 `SettingsManageable` 协议中，添加下面的定义：

```swift
protocol SettingsManageable {
    ...
    func update() -> Bool
}
```

将其命名为 `update()`，是因为其作用就是*在有任何修改时都去更新保存了设置的文件*。它的底层实现是，每次方法被调用时，所有的属性都将被编码后写入文件。同时这个方法还将返回 true 或 false 来让我们知道是否更新成功。

我猜你应该听过 [**JSONEncoder**](https://developer.apple.com/documentation/foundation/jsonencoder) 这个类，它的作用是可以简单地将任何符合 Codable 的对象转化成 JSON。大概率你已经用过它了！然而，你知道除了 JSONEncoder 之外，**还有一个叫 [PropertyListEncoder](https://developer.apple.com/documentation/foundation/propertylistencoder) 的类**可以将*任何符合 Codable 的对象编码后转化成属性列表对象吗*？

噢，是的，就是有这么一个类，而且我们将要用上它！在协议扩展中，先写上如下代码：

```swift
func update() -> Bool {
    do {
        let encoded = try PropertyListEncoder().encode(self)
        return true
    } catch {
        print(error.localizedDescription)
        return false
    }
}
```

如你所见，真正起作用的是这句：`PropertyListEncoder().encode(self)`。首先创建了一个 `PropertyListEncoder` 的类，然后调用了 `encode(_:)` 方法来对 `self`（遵循了 `SettingsManageable` 的自定义类型）进行编码转化成一个属性列表对象，实际上它就是一个 `Data` 对象！

如果编码失败那么 `encode:` 方法会在错误发生时抛出一个异常，所以有必要在 `do-catch` 语句中使用 `try` 关键字。注意这里并未对异常做任何额外操作，只是打印了错误然后返回了 false。你可以根据需要来决定是否要采取额外的操作。

上面的代码并没有将编码后的数据*写入*文件。在 `do` 中，再加上这么一行：

```swift
do {
    let encoded = try PropertyListEncoder().encode(self)
    try encoded.write(to: settingsURL())
    return true
}
```

`Data` 类中的 `write(to:)` 方法同样会抛出异常， 所以配合 `try` 标记使用也是强制要求的。注意在这里我们就用上了之前实现的获取文件 URL 的 `settingsURL()` 方法。

只通过两行重要的代码，我们就实现了编码和将目标类型写入属性列表文件的功能。整个方法应该像这样：

```swift
func update() -> Bool {
    do {
        let encoded = try PropertyListEncoder().encode(self)
        try encoded.write(to: settingsURL())
        return true
    } catch {
        print(error.localizedDescription)
        return false
    }
}
```

在继续之前，让我再给你展示*另一种上述方法的实现方式*。假设我们不需要布尔返回值。取而代之的是，我们希望方法内部所使用的方法们能够自己抛出异常。这样的话，首先需要修改 `SettingsManageable` 协议的定义：

```swift
func update() throws
```

然后在协议扩展中这样修改：

```swift
func update() throws {
    let encoded = try PropertyListEncoder().encode(self)
    try encoded.write(to: settingsURL())
}
```

可以看到在这种情况下无需使用 `do-catch` 声明。由于我们将其标记了 `throws` 关键字，这个方法会将任何可能发生的错误传递出去。这意味着每一次调用它我们都需要对其进行异常的检查。我个人觉得这不太实用，我的期望是能够尽量轻松，并且没有额外操作的情况下更新配置。一个能够表示更新成功与否的标记应该足够了，所以我会选择那个方案。然而，为了让你方便，我把这个解决方案也提供给你，供你来选择。注意接下来这个方案不会再出现了，不过你仍然可以通过我刚刚展示的方式来将其转化成这个方案。

> 注意：想要了解更多关于错误处理的内容？看看 [这个文档](https://swiftgg.gitbook.io/swift/swift-jiao-cheng/17_error_handling) 吧！

### 通过文件加载设置
现在让我们过渡到通过文件加载数据，对应刚刚提到的保存数据部分。我们要跟随的步骤很简单，只需要跟着下面这几步：

1. 检查文件是否存在。
2. 将文件内容加载为 `Data` 对象。
3. 通过 **`PropertyListDecoder`** 类来对其解码，与 `PropertyListEncoder` 相对应。

和我们之前做的相似，这个方法也会返回一个布尔值来表示成功与否。在 `SettingsManageable` 协议中添加下面的内容：

```swift
protocol SettingsManageable {
    ...
    mutating func load() -> Bool
}
```

这个方法被标记为*可变*，因为它会修改遵循了 `SettingsManageable` 协议的类型的实例（简单来说，它会修改 `self`）。

这个方法的实现其实很简单并且和我们之前做的很相似。只是额外增加了对文件是否存在的检查。在协议扩展的方法中添加如下实现：

```swift
mutating func load() -> Bool {
    if FileManager.default.fileExists(atPath: settingsURL().path) {
        do {
            let fileContents = try Data(contentsOf: settingsURL())
            self = try PropertyListDecoder().decode(Self.self, from: fileContents)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}
```

我们又一次使用了 `settingsURL()` 方法来获取文件 URL。然而这次需要使用 `path` 属性来获取路径的字符串。当确定文件存在之后，就从文件中加载内容到 `fileContents` 实例中，拿到加载的数据后，通过 `PropertyListDecoder` 类解码后，对 `self`（遵循了 `SettingsManageable` 协议的类型）进行了初始化。如果所有的步骤都成功了，返回 true，如果出现了错误则会抛出异常，然后将错误打印在控制台并且返回 false。

现在方法还没完全实现，当 `if` 判断为 false 的时候，意味着文件并不存在，这种情况还没有返回值。如果没有文件可以加载设置，那么就创建一个！怎么创建？通过调用上一步我们实现的 `update()` 方法！

```swift
mutating func load() -> Bool {
    if FileManager.default.fileExists(atPath: settingsURL().path) {
        ...
    } else {
        return update()
    }
}
```

现在方法在所有的情况下都有返回值了。如果是第一次使用应用，或是文件被删除了，导致的文件不存在，那么通过调用 `update()` 方法会创建一个。如果存在，那么它会加载其内容，将其解码然后利用解码后的数据来初始化对象。

### 通过应用包中的 Plist 文件初始化设置
既然我们一直在聊设置，那么很自然就会想到它们的默认值。在编程层面，遵循了 `SettingsManageable` 的类或者是结构体的属性都应该有初始值或者说默认值。然而这并不是唯一实践或者最适合的方式。通过 Xcode 的编辑器编辑应用包内的属性列表文件来初始化也许是是更好且简单的方式。我们接下来将实现这种方式，并遵循**一条很重要的规则**：

*属性列表文件中的键，应该和那些表示着设置的类或结构体的属性名称相同！*

否则的话，解码会失败。

让我们从 `SettingsManageable` 协议中定义一个新的方法开始吧：

```swift
protocol SettingsManageable {
    ...
 
    mutating func loadUsingSettingsFile() -> Bool
}
```

在这个方法的实现中（协议扩展里），要做的第一件事就是检查应用包中是否存在一个初始设置文件：

```swift
mutating func loadUsingSettingsFile() -> Bool {
    guard let originalSettingsURL = Bundle.main.url(forResource: "\(Self.self)", withExtension: "plist")
     else { return false }
}
```

**记住**：设置文件的名字应该和遵循了 `SettingsManageable` 的类或结构体名字相同。

下一步，我们将会检查缓存目录中是否已经存在属性列表文件。如果*不存在*，那么就将*应用包中的文件拷贝到缓存目录中*：

```swift
do {
    if !FileManager.default.fileExists(atPath: settingsURL().path) {
        try FileManager.default.copyItem(at: originalSettingsURL, to: settingsURL())
    }
 
} catch {
    print(error.localizedDescription)
    return false
}
```

如果文件已经存在，条件判断则会为 false，那么拷贝的操作将不会执行！现在，要做的和之前一模一样；我们会加载文件内容到 `Data` 对象中，然后将其解码：

```swift
do {
    ...
 
    let fileContents = try Data(contentsOf: settingsURL())
    self = try PropertyListDecoder().decode(Self.self, from: fileContents)
    return true
 
} catch { ... }
```

无论缓存目录里是否存在设置文件，我们的逻辑实现都能正常运行。如果文件不存在，那么会先从应用包中拷贝到缓存目录，然后内容将会被解码，用于初始化设置对象。

### 删除设置文件
对自定义类型进行编码然后写入属性列表文件，然后再读取的流程已经完成了。接下来我们必须提供一种让文件能被轻松移除的方法。为了达到这个目的，我们将在 `SettingsManageable` 协议中添加如下方法：

```swift
protocol SettingsManageable {
    ...
    
    func delete() -> Bool
}
```

协议扩展里的方法实现不是什么秘密：

```swift
func delete() -> Bool {
    do {
        try FileManager.default.removeItem(at: settingsURL())
        return true
    } catch {
        print(error.localizedDescription)
        return false
    }
}
```

如果移除文件像上面这样成功了，那么方法会返回 true。如果在移除过程中产生了任何错误，那么返回 false。

### 重置设置
如果有办法可以在任意时间切换回最初的设置，那将会是个很有用的功能。这背后的含义其实是删除缓存目录中的属性列表文件，然后再把初始值写回去。

当原始设置存在于应用包中的 .plist 文件时，将设置重置为初始值就是个非常简单直接的事情了。直接删除缓存目录中的 .plist 文件，然后再将原始的文件拷贝放回去就行了。然而在应用包中也不存在于原始文件的情况下，初始值已经被赋值给了属性，这就让事情变得有些棘手了！因为在重置的时候，已经被加载的值会将默认值替换了，然后又重新保存到文件中，这显然是错误的！

为了解决这个问题，在覆盖之前，我们需要保存一份原始设置的拷贝。这份拷贝得是第一次在缓存目录创建的文件。我们将会以它来重置设置为初始值，并且这样的话，也不需要在意是否之前的设置已经被加载了，可以避免又重写回去的风险。

为了达到这个目的，还需要两个方法；一个用于备份 .plist 文件，一个用于恢复它。因为这两个方法算是某种“内部”操作，我们并不希望它们可以被显式调用，所以不会将它们定义在协议中。取而代之的是在协议扩展中方法实现的地方将它们标记为 `private`。第一个方法是将原始文件备份：

```swift
private func backupSettingsFile() {
    do {
        try FileManager.default.copyItem(at: settingsURL(), to: settingsURL().appendingPathExtension("init"))
    } catch {
        print(error.localizedDescription)
    }
}
```

拥有初始设置的文件将会以 “init” 作为文件扩展名。举个例子，原始设置文件叫 “AppSettings.plist”，那备份就会叫做 “AppSettings.plist.init”。

这个方法则是将初始设置拷贝到正常设置文件目录下：

```swift
private func restoreSettingsFile() -> Bool {
    do {
        try FileManager.default.copyItem(at: settingsURL().appendingPathExtension("init"), to: settingsURL())
        return true
    } catch {
        print(error.localizedDescription)
        return false
    }
}
```

有了上面的两个方法，让我们回到 `load()` 方法，在 `else` 条件下如果文件不存在，则会将属性列表文件第一次写入缓存目录。此刻这个地方看起来是这样：

```swift
mutating func load() -> Bool {
    if FileManager.default.fileExists(atPath: settingsURL().path) {
        ...
    } else {
        return update()
    }
}
```

我们将会对其作出修改，我们会在 `update()` 方法之后调用 `backupSettingsFile()`，只要 `update()` 返回的是 true。这是修改之后的样子：

```swift
mutating func load() -> Bool {
    if FileManager.default.fileExists(atPath: settingsURL().path) {
        ...
    } else {
        if update() {
            backupSettingsFile()
            return true
        } else { return false }
    }
}
```

现在我们可以专注于重置方法的实现啦。在 `SettingsManageable` 协议中添加：

```swift
protocol SettingsManageable {
    ...
 
    mutating func reset() -> Bool
}
```

在协议扩展中实现它。我们先从删除当前缓存目录中的属性列表文件开始：

```swift
mutating func reset() -> Bool {
    if delete() {
 
    }
 
    return false
}
```

下一步要小心一点。为了让 `reset()` 方法与加载设置的方法独立开来。因此，我们要首先通过 `loadUsingSettingsFile()` 方法来尝试着从应用包中设置文件加载初始设置。如果成功了，初始设置则会被拷贝到缓存目录中。如果失败了，则是由于应用包中并没有相关文件，那么我们会再尝试着使用 `restoreSettingsFile()` 方法，来从之前的初始设置备份文件中恢复，然后调用 `load()` 方法来加载设置。

这就是上面所描述「场景」的代码：

```swift
mutating func reset() -> Bool {
    if delete() {
        if !loadUsingSettingsFile() {
            if restoreSettingsFile() {
                return load()
            }
        } else {
            return true
        }
    }
    return false
}
```

如果 `loadUsingSettingsFile()` 方法返回 true，那么执行则会走到里面的 `else`，并且方法会返回 true。另一种情况，如果恢复初始设置成功了，则会返回 `load()` 方法的执行结果。无论初始设置是如何被定义的，是直接设置给属性，还是应用包中的属性列表文件，上面的实现都会正常工作。你或许会想为了实现一个重置的功能费这么多功夫是否值得，但相信我，值。随着时间的推移，你绝对会需要这个功能，而那时候就可没有那么多时间来实现了！

## 将属性列表内容当作字典
上述这些 SettingsManageable 协议的方法，为遵循了协议的类或结构体提供了保存与加载的能力。数据保存是通过 `PropertyListEncoder` 编码后存储为属性列表文件，然后通过 `PropertyListDecoder` 来解码。诚然，与属性列表数据和其相关的类打交道的次数，并不像遇到 JSON，`JSONEncoder` 和 `JSONDecoder` 那么多。所以借此机会，让我们来更进一步地使用它，看看怎么使用 `PropertyListSerialization` 类以及如何将属性列表作为字典类型获取。

在这里为了演示，我们将会在 `SettingsManageable` 中再定义一个方法：

```swift
protocol SettingsManageable {
    ...
 
    func toDictionary() -> [String: Any?]?
}
```

这个方法会返回一个范型为 `[String: Any?]` 的字典，或者是 nil，避免属性列表文件在被解码的过程中发生了如无法解码这样糟糕的事情。注意返回的字典值的数据类型被定义成了 `Any?`，这就覆盖了值是 nil 的情况。

在协议扩展中我们将会提供一个上述方法的默认实现，第一步就是检查属性列表文件是否存在，这个之前已经做过好几次了。同时还要把文件内容加载到 `Data` 对象中：

```swift
func toDictionary() -> [String: Any?]? {
    do {
        if FileManager.default.fileExists(atPath: settingsURL().path) {
            let fileContents = try Data(contentsOf: settingsURL())
        }
    } catch {
        print(error.localizedDescription)
    }
 
    return nil
}
```

可以看到如果文件不存在将直接返回 nil。接下来是重点，`PropertyListSerialization` 类提供了一个叫作 `propertyList(from:options:format:)` 的方法，可以从 `Data` 对象中返回一个属性列表对象（在我们这里就是 `fileContents` 对象）。方法这么使用：

```swift
let dictionary = try PropertyListSerialization.propertyList(from: fileContents, options: .mutableContainersAndLeaves, format: nil)
```

作为一个会抛出异常错误的方法，使用 `try` 关键字是必要的。它的结果是返回一个 `Any` 类型的对象，所以可以通过简单的转换来得到一个字典：

```swift
let dictionary = try PropertyListSerialization.propertyList(from: fileContents, options: .mutableContainersAndLeaves, format: nil) as? [String: Any?]
```

`PropertyListSerialization` 类和 `**JSONSerialization**` 类差不多，只是处理的是属性列表（如果对你来说 `JSONSerialization` 要更熟悉一些的话）。自从有了 Swift 提供的 `Codable` 协议，使用 `PropertyListSerialization` 类的几率就变小了。大部分情况下你会用 `PropertyListEncoder` 和 `PropertyListDecoder` 类。但既然我们正在讨论属性列表，就可以顺便提及此方法。

现在要怎么通过 `PropertyListSerialization` 从一个字典获取到属性列表文件呢？

嘿，我将这个问题留给你作为可选的练习。给一个小提示，如果是我的话，会去找一个叫 `data(fromPropertyList:format:options)` 的方法。

## SettingsManageable 协议实战
是时候来用用我们完成的实现了。在启动项目中你可以找到两个测试文件，分别是叫做 *AppSettings* 的类和叫做 *PlayerSettings* 的结构体。我们将会通过它们来看看我们的协议在实践中如何使用的！

首先从 *AppSettings.swift* 文件开始，`AppSettings` 类中模拟了几个能在真实应用中找到的设置选项。你会注意到，这个类有一个静态的共享实例，以及一个私有的初始化方法，它符合 [***单例***](https://en.wikipedia.org/wiki/Singleton_pattern) 的特性。我选择这种方式的理由很简单：当处理应用的设置时，创建多个实例来持有这些设置，可能不是一个好的主意，会存在数据重载的风险。而使用单例时，因为只有一个实例，搞坏设置数据的风险被降到了最低。然而如果你不同意这种方案，可以自行移除 `init()` 方法的 `private`关键字，删除静态共享实例，然后在需要的时候，像其他普通的类一样初始化创建实例。我们会在下一个例子中看到如此处理的 `PlayerSttings` 结构体。同时你会注意到设置的初始值是默认的属性值。

我们需要做的第一件事就是让 `AppSettings` 类遵循 `SettingsManageable` 协议。不要忘了也要遵循 `Codable` 协议：

```swift
class AppSettings: Codable, SettingsManageable {
    ...
}
```

因为我们一直讨论的是应用的设置，那就有必要在应用启动的时候马上就能拿到它们。所以，打开 *AppDelegate.swift* 文件，然后找到 `application(_:didFinishLaunchingWithOptions:)` 方法。修改它，然后通过之前实现的 `load()` 方法来加载设置：

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
 
    _ = AppSettings.shared.load()
 
    return true
}
```

如果应用第一次启动，那么当 `load()` 方法调用时，初始设置会被写入 “AppSettings.plist” 文件，保存在缓存目录中。与此同时，这些初始设置也会被备份到 “AppSettings.plist.init” 文件中，这样可以在需要的时候通过它来重置设置。如果 .plist 文件已经在应用启动的时候存在了，那么设置会被加载并且赋到 `AppSettings` 共享实例的属性上。

现在再到 `ViewController.swift` 文件，移动到 `tryAppSettings()` 方法中。我们将会修改一些设置：

```swift
func tryAppSettings() {
    AppSettings.shared.fontSize = 21.0
    AppSettings.shared.playSFX = false
}
```

让我们来更新一下设置文件，然后看看写入了什么：

```swift
if AppSettings.shared.update() {
    if let dictionary = AppSettings.shared.toDictionary() {
        print(dictionary.compactMapValues  { $0 })
    }
}
```

上面的代码片段除了 `update()` 之外还使用了 `toDictionary()` 方法，并且还将文件内容加载进了字典对象。然后我们将字典中除 nil 之外的值打印了出来。

同时，为了验证文件是否被成功创建，再添加一行代码，它会打印应用的真实的缓存目录，你可以通过 Finder 来查看：

```swift
print(AppSettings.shared.settingsURL().path)
```

如果你运行应用，就能在控制台中看到如下输出：

![console](https://www.appcoda.com/wp-content/uploads/2019/08/t67_3_results_1.png)

如果你通过 Finder 跳转到打印出来的路径，你还能看到创建了两个文件：

![files_created](https://www.appcoda.com/wp-content/uploads/2019/08/t67_4_files1.png)

让我们试试重置设置。在上面的指令后面再添加下面的代码：

```swift
if AppSettings.shared.reset() {
    if let dictionary = AppSettings.shared.toDictionary() {
        print(dictionary.compactMapValues  { $0 })
    }
}
```

再次运行。这次你会先看到被修改的值，然后是原始值。这意味着重置到初始设置如预期的成功了！

![reset_settings](https://www.appcoda.com/wp-content/uploads/2019/08/t67_5_results_2.png)

切换到 *PlayerSettings.swift* 文件然后找到用来表示虚拟游戏玩家设置的 `PlayerSettings` 结构体。首先让 `PlayerSettings` 结构体遵循 `Codable` 和 `SettingsManageable` 协议：

```swift
struct PlayerSettings: Codable, SettingsManageable {
    ...
}
```

与 `AppSettings` 类所使用的属性相反，这里初始值并没有直接赋给属性。与之替代的是存在于应用包中的 *PlayerSettings.plist* 文件，你可以在 Project Navigator 中找到。当你打开文件时，注意在 .plist 文件中的键名和属性名相同。

回到 `ViewController.swift` 文件，找到 `tryPlayerSettings()` 方法。要做的第一件事是初始化一个 `PlayerSettings` 对象，然后加载设置，但这一次将会使用 `loadUsingSettingsFile（）` 方法。同样的，我们也会像之前那样将结果打印出来：

```swift
func tryPlayerSettings() {
    var playerSettings = PlayerSettings()
    if playerSettings.loadUsingSettingsFile() {
        if let dictionary = playerSettings.toDictionary() {
            print(dictionary.compactMapValues  { $0 })
        }
    }
 
}
```

下面是运行应用之后打印在控制台的结果：
![console2](https://www.appcoda.com/wp-content/uploads/2019/08/t67_6_results_3.png)

以及这是与 *AppSettings.plist* 同时存在的 *PlayerSettings.plist* 文件：
![PlayerSettings](https://www.appcoda.com/wp-content/uploads/2019/08/t67_7_files2.png)

再来修改一些属性，然后更新 .plist 文件，并且再次打印：

```swift
playerSettings.isMale = false
playerSettings.gunType = 1
playerSettings.powerLevels?[0] = 1
playerSettings.powerLevels?[1] = 1
playerSettings.powerLevels?[3] = 5
playerSettings.powerLevels?[4] = 5
_ = playerSettings.update()
if let dictionary = playerSettings.toDictionary() {
    print("\n", dictionary.compactMapValues  { $0 })
}
```

注意在真正的应用中，我们应该检查下标是否越界！

这里是从 .plist 文件中获取到的更新后的设置:
![updated_plist](https://www.appcoda.com/wp-content/uploads/2019/08/t67_8_results_4.png)

最后，来尝试着重置设置，然后验证一下原始的设置文件是否会覆盖当前在缓存目录中的设置文件：

```swift
_ = playerSettings.reset()
if let dictionary = playerSettings.toDictionary() {
    print("\n", dictionary.compactMapValues  { $0 })
}
```
![reset](https://www.appcoda.com/wp-content/uploads/2019/08/t67_9_results_5.png)

## 总结
我们终于要结束这篇文章了。希望你喜欢这篇文章，并在今天学到了有用的东西。这篇文章所呈现的概念很简单，但也清晰地展示了协议与扩展是如何为其他类型提供额外的功能，以及协议如何提供了所有应用都必要的自动化任务。同时，使用上我们这里提到的解决方案，能提高工作效率，你也不需要担心像是如何保存以及加载设置这样的小事，有了更多处理重要任务的时间。现在既然你已经读到了这里，可以再想想如何改进你自己的任务。这或许要比你想象的更简单。再次感谢阅读，我们很快还会再见的！

作为参考，你可以在 GitHub 上下载到 [完整的项目](https://github.com/appcoda/AppSettings)。