
title: "在你的 Swift 应用中创建或修改 URL"
date: 2018-08-27
tags: [Swift]
categories: codingexplorer
permalink: creating-and-modifying-nsurl-in-swift
keywords: Swift,URL,codingexplorer
custom_title: 在你的 Swift 应用中创建或修改 URL
description: 本文介绍了基于 Swift 4.1.2 和 Xcode 9.2 如何创建或者修改一个 URL 的常用 API 的描述。
---
原文链接=http://www.codingexplorer.com/creating-and-modifying-nsurl-in-swift/
作者=codingexplorer
原文日期=2018-07-18
译者=Damonwong
校对=
定稿=


对于大部分应用来说，都需要访问一些文件资源。这些文件资源可能在你的应用安装包中，或者在文件系统内，亦或者在某个网站服务器上。你需要用某种方法将他们体现在代码中。对于苹果平台而言，你主要有两种选择方式，用字符串或者 `URL`。

当你遇到一个地址栏，或者在使用终端的时候，Swift 字符串是一个毋庸置疑的选择，我的意思是，将所有的文本都填写到地址栏中，理解吧？虽然在 `Cocoa` 和 `Cocoa Touch` SDKs 中许多旧的 API 同时采用 `URL` 和字符串 (对于这些 API 来说通常称为“路径”) 作为参数，但是越来越多的 API 倾向于只能用 `URL` 对象。相比较于字符串路径来说，`URL` 对象有很多的优势，最明显的优势就是你可以直接通过属性访问 `URL` 的不同的部分，而不需要自己编写一个解析组件来解析路径字符串的不同部分。

请继续关注一些关于在 Swift 应用中创建和使用 `URL` 对象的知识点。

## 在 Swift 中创建一个 `URL` 对象

在 Swift 中有好几个构造器和工厂方法可用于创建 `URL` 对象，下面我要讲一些更有用的初始化方法。

#### init?(string URLString: String)

这个是普通的，也是最常用的初始化方法。将一个用于表示 `URL` 的 Swift 字符串转变成一个 `URL` 对象。但并不是所有的字符串都可以有效的表示一个 `URL`，所以这是一个可失败构造器。由于有些字符不能在 `URL` 中使用，因此需要进行百分比编码，将这些不能使用的字符转化为可以在 `URL` 中发送的编码。我个人见过最多的是 `%20`，也就是“空格”字符。这个构造器需要有效的字符，它不会为您进行百分比编码转化。如果字符串中包含无法转换为有效 `URL` 的字符或者内容，构造器将会返回 `nil`。

```Swift 
let NSHipster  = URL(string: "http://nshipster.com/")                 //返回一个有效的 URL
let invalidURL = URL(string: "www.example.com/This is a sentence")    //返回 nil
```

这个构造器其实是遵从于下面这个构造器的一个便利构造器。

#### init?(string: String, relativeTo: URL?)

这是一个指定构造器。和上面的构造器一样，也是一个可失败的构造器，而且需要一个类似 `URL` 的 Swift 字符串和一个可选的 `baseURL` 对象，这个 `baseURL` 本身也是一个 `URL` 对象。如果 `baseURL` 为 `nil`，那么内部会像第一个构造器一样，根据提供的 `URL` 字符串生成一个 `URL` 对象。

```Swift 
let NSHipsterTwo = URL(string: "http://nshipster.com/", relativeTo: nil)   //返回一个有效的 NSHipster URL
let article      = URL(string: "ios9/", relativeTo: NSHipster)             //返回 "http://nshipster.com/ios9/" URL 
```

#### init(fileURLWithPath: String, isDirectory: Bool)

这个构造器和上面的构造器类似，只是专门用于指向本地文件或者目录。我不太确定为什么会有一个本地文件的特殊版本，我猜有可能是做了一些优化（至少需要是文件 `scheme` 开头，而不应该是 `http` 之类的）。虽然有一个不需要传 `isDirectory` 参数的版本，但如果你知道它是否是一个目录时，头文件建议你使用这个这个方法。在我看来，有可能另外一个需要自己判断是否是一个目录，而这个方法通过传入参数避免了检查。

#### init(fileURLWithPath: String, isDirectory: Bool, relativeTo: URL?)

在 iOS 9 中新增，这与前一个类似，但新增了 `relativeToURL` 参数。和之前的构造器一样，它将返回一个将路径附加到 `baseURL` 的 `URL` 对象。当你需要为了某个事情重复访问某个目录下的不同文件时，可以使用这个初始化方法。你可以将文件所在的目录作为 `baseURL`，然后 只需要一个文件名作为 Swift 字符串路径来创建 `URL` 对象。

## 将 URL 转回 Swift 字符串

有时候，特别是在处理旧的 API 或者向用户展示时，你需要将 `URL` 对象转回 Swift 字符串。值得庆幸的是，`URL` 提供了一个简单的只读属性来解决这个问题: `absoluteString`。只需要在你的 `URL` 对象调用该属性即可：

```Swift 
let articleString = article?.absoluteString
//ArticleString 现在包含 "http://nshipster.com/ios9/"
```

在这个例子中，我们使用了 `relativeToURL` 版本的构造器定义了一个 `article` 常量，将其解析为从 `scheme` 开始的完整 `URL` (在这种情况下是一个路径)。如果我们在这个 `URL` 上有文件拓展名，查询或者片段，它依旧可以被解析。原来的 `article` 对象是由一个可失败构造器返回的，这就是为什么那儿有一个 Swift 可选访问。

## 修改一个 URL 对象

这些函数中的每一个都会在请求修改完成时根据调用的 `URL` 对象返回一个新的 `URL` 对象。它们不会更改调用它们的 `URL` 对象，调用对象依旧还是原来的。

#### func appendingPathComponent(String, isDirectory: Bool) -> URL

这个方法可以为你的 `URL` 添加更多的路径组件，比如你将要添加一个文件到你所在的目录 (存储在这个方法调用返回的 `URL` ) 中。像初始化方法一样，这个方法也有一个没有 `isDirectory` 参数的版本，但是无论你是否知道它是不是一个目录，都更推荐你使用这个方法来确保元数据可以存储在正确的目录下。


#### func deletingLastPathComponent() -> URL

这个方法将会返回删除了最后一个路径组件的新 `URL` 对象。这方法适用于 `URL` 的路径部分，`URL` 的其他部分不受影响， 比如域名。所以我们可以这样子做:

```Swift
let articleTwo = NSHipster?.appendingPathComponent("ios9", isDirectory: true)
//articleTwo now contains "http://nshipster.com/ios9/"

let deletePathComp = articleTwo?.deletingLastPathComponent
//deletePathComp now contains "http://nshipster.com/"
```

如果没有路径信息，可能有点儿奇怪。为了好玩，我链式调用了几次 `deletingLastPathComponent`，最后只是添加了 “../”，类似于在命令行（cd ..）中上一个目录。

当然还有几种修改方法和属性，但这些可能是最常用的。

## 总结

如果你对 URL 格式规范感兴趣的话，可以看一下在苹果关于 `URL` 类的参考文档关于如何处理 `URL` 章节中提及到的 `RFC` 文档。用于初始化的字符串必须符合 [RFC 2396](https://tools.ietf.org/html/rfc2396)，并且 `URL` 根据 [RFC 1738](https://tools.ietf.org/html/rfc1738) 和 [RFC 1808](https://tools.ietf.org/html/rfc1808) 进行解析。这些规范内容很多，但你能找到所有可能关于 URL，URI 等的信息。

如果你需要完整的解析 `URL`，`URL` 还有许多其他的属性，包括 `baseURL`，`host`，`query`，`fragment` 等，你可以在苹果提供的关于 `URL` 类的参考文档中查看它们。但我自己来说，主要使用 `absoluteString`，偶尔也会使用 `pathExtension`。

我希望你能发现这篇文章很有帮助。如果你觉得有用，请不要犹豫，在 Twitter 或者其他社交媒体上分享这篇文章。当然，如果您有任何疑问，请随时通过[联系页面](http://www.codingexplorer.com/contact/) 或者 [Twitter@CodingExplorer](https://twitter.com/CodingExplorer) 与我联系。我会尽可能的帮助你。谢谢。

## 参考

[URL Class Reference – Apple Inc.](https://developer.apple.com/documentation/foundation/url)

