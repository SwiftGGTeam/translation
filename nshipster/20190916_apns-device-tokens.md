title: "Apple Push Notification Device Tokens"
date: 
tags: [APNs, NSHipster]
categories: [Cocoa]
permalink: apns-device-tokens
keywords: NSHipster, Cocoa, APNs
custom_title: 
description: 

---
原文链接=https://nshipster.com/apns-device-tokens/
作者=Mattt
原文日期=2019-09-16
译者=SunsetWan
校对=
定稿=

<!--此处开始正文-->
在法律里，拉丁短语 *stare decisis* (遵循先例) 常指的是先例原则——这个概念是：当判决一个案例时，法院应该查阅先前相似案例所做的决定。该原则是美国法律体系以及由此产生的英国普通法的基础。

Apple 和 Pepper 的 [诉讼案](https://www.oyez.org/cases/2018/17-204) 最近在美国最高法院的会议上引起争议，会议上试图辩论下面的问题：
> 如果 Apple 和它的 App Store 构成垄断，那么消费者能以应用程序价格高于竞争价格为由起诉 Apple 吗？尽管这个价格是由第三方开发者设定的。
<!--more-->

在最终判决中，法院依据 1977 年 *Illinois Brick* [案例](https://www.oyez.org/cases/1976/76-404) 中的判决，而它本身肯定了十年前在 *Hanover Shoe* [案例](https://www.oyez.org/cases/1967/335) 中的判决。表面上，2010 年的 iPhone 似乎和 1970 年的砖块没有什么联系（除了 [明显的含义](https://www.theiphonewiki.com/wiki/Brick)），但在 [美国反托拉斯法](https://en.wikipedia.org/wiki/United_States_antitrust_law) 的范畴内，两者之间有不可避免的联系。

> 当然，也有*许多*其他更简单更全面的案例来诠释先例在美国法学中的作用，但是我们认为这个案例是最不可能导致读者联想到 NSHipster 被 [Atrium](https://www.atrium.co/) 还是其他什么的收购这件事情。

坚持优先考虑先例会带来决策惯性，它提高了整个法律体系和依赖法律实施一致性机构的稳定性。

然而，像惯性一样，在有足够说服力的理由下，我们也可以打破优先考虑先例的原则；我们只在深思熟虑之后才遵循过去的约束。

记住上面这些，让我们马上切入本周文章的主题：Apple Push Notification Device Tokens——且特别地，iOS 13 的一个改变会不经意地破坏上千个应用程序的推送通知功能。

## 推送通知的基础入门
推送通知使应用能在未被使用时与用户沟通，以响应远程事件。

不像短信或电子邮件那样能使发送者利用唯一标识符（即手机号码和电子邮箱地址）来和接收者直接沟通，应用程序的远程服务器与用户本地设备之间的沟通是在 Apple Push Notification service（APNS）的帮助下达成的。

这是它的工作原理：
* 在启动应用程序之后，这个应用程序调用 `registerForRemoteNotifications()` [方法](https://developer.apple.com/documentation/uikit/uiapplication/1623078-registerforremotenotifications)，提示用户授予这个应用程序发送推送通知的权限。
* 这个应用程序的 delegate 调用 `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` [方法](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application) 来响应用户授予的权限。

应用程序 delegate 方法中的 `deviceToken` 参数是一个不透明 `Data` 值，这个值像一长串唯一手机号或电子邮件地址。这个应用程序的推送通知提供程序通过 APNs 使用这个值来发送通知到安装了这个应用程序的设备上。

本质上，用 `Data` 值来表示这个参数是有意义的——但这个值本身是没有意义的。但是，实际上，这个 API 的设计决策是造成无数开发者心痛的根源。

## device token 发到服务器是个持久战
当这个应用程序的 delegate 收到了它的 `deviceToken` 之后，这还没完。为了使其用于发送推送通知，我们需要把它从客户端发送到服务器。

问题是，“怎么发送呢？”

在你查找具体的答案之前，考虑一下 iOS 3 的历史背景（约为 2009 年），那时 Apple 首次引入推送通知：

### “回到旧时光...”
你可以创建一个 `NSURLRequest` 对象，把它的 `httpBody` 属性设置为 `deviceToken`，接着使用 `NSURLConnection` 发送它。但你可能想加入额外信息——比如用户名或电子邮件地址——将其与应用程序中的账户相关联。这就意味着作为 HTTP 请求体的 `Data` 不仅仅只是 device token。

发送一个请求体带有 `application/x-www-form-urlencoded` 的 `Post` 类型 HTTP 请求（举个例子：`username=jappleseed&deviceToken=____`）是将多个字段编码为单个有效载荷（a single payload）的方法之一，但那么问题变为，“如何把二进制数据编码为文本？”

[**Base 64**](https://en.wikipedia.org/wiki/Base64) 是个很好的二进制转文本编码方法，但是，`NSData -base64EncodedStringWithOptions:` 这个方法直到 iOS 7 才出现，这是在 iOS 3 中 Apple 首次引入推送通知四年后的事情了。在没有 [CocoaPods](https://nshipster.com/cocoapods/) 或其他强大的开源生态系统的帮助下，你只能去关注这篇讲如何自己完成这部分实现的 [博客文章](https://nshipster.com/apns-device-tokens/)，且希望一切能如愿。

> 回想起来，将带有 device token 和其他信息的 `NSDictionary` 序列化为属性列表可能是最好的答案（至少在利用内置功能范畴内）。
> 服务器端对 `.plist` 文件的支持在历史上是很少的，所有这种方式不会说比其他方法要好。

鉴于在低于 iOS 7 的版本下使用 Base64 编码的复杂性，大多数开发者转而选择使用更简单的内置替代方法：

### 用 NSData 来理解 Device Token
在尝试理解 `deviceToken` 参数到底是什么的过程中，开发者往往使用 `NSLog` 语句把它打印出来：

```
NSLog(@"%@", deviceToken);
// 打印 "<965b251c 6cb1926d e3cb366f dfb16ddd e6b9086a 8a3cac9e 5f857679 376eab7C>"
```

不幸的是，对于那些在数据和编码方面缺少经验的开发者来说，`NSLog` 的输出内容可能会误导他们：
“哇，`deviceToken` 实际上是一个字符串！（我很好奇为什么起初 Apple 要弄这么复杂）但是无所谓啦，我可以从这里获取到它。”


```
// ⚠️ 警告：别这样做
NSString *token = [[[[deviceToken description]
                    stringByReplacingOccurrencesOfString:@" " withString:@""]
                    stringByReplacingOccurrencesOfString:@"<" withString:@""]
                    stringByReplacingOccurrencesOfString:@">" withString:@""];
```

是推送通知服务提供者从一开始就要求用 Base16/十六进制表示 deviceToken，还是因为开发者早就习惯这种做法，所以推送通知服务提供者采取了同样做法？这已无从得知，但无论怎么样，这种做法有些死板。近十年内，很多应用程序都采用这种做法来注册推送通知 device token。

这种情况一直持续到 Swift 3 和 iOS 10。

> 必须承认的一点是：用文本的形式来表示二进制数据的方法不是唯一的——同样的 token 可以用 Base64 编码方式表示为 "llslHGyxkm3jyzZv37Ft3ea5CGqKPKyeX4V2eTduq3w=" 或者用 [Ascii85 编码方式](https://en.wikipedia.org/wiki/Ascii85) 表示为 "Q\<PXTCpB.?j3'?!hm%%Sk.(b4MEIu3?\NZK2f>\[D"。甚至可以用 [Base🧑 编码方式](https://github.com/Flight-School/Guide-to-Swift-Strings-Sample-Code#base-encoding) 表示为 "👩🏻‍🦱👩🏻‍🦱👩🏼‍🦳👩🏻‍🦱👨🏻‍🦱👨🏻‍🦰👩🏾👩🏽‍🦳👩🏻‍🦰👩🏻‍🦲👩🏿👩🏻👩🏾👩🏾‍🦰👨🏿👩🏽‍🦱👩🏿👩🏿‍🦳👨🏻👩🏽👩🏿👩👨🏿‍🦰👩🏿‍🦱👨‍🦱👨🏻‍🦰👩🏼‍🦱👨🏼👨🏽👨🏼👩🏾👩👨🏾‍🦲👩🏿‍🦰👨🏾‍🦰👩🏾‍🦳👩👨🏽‍🦳👨🏿‍🦳👩🏽‍🦰👩🏼‍🦱👩🏿👩🏽‍🦲🤡"。但是如果你的推送通知服务提供商希望以经典的 Base16 十六进制字符串来表示 device token，你应该采用如上所述的做法。

### 和 Swift3 一起重新审视过去
到 2016 年，Swift 趋于稳定和成熟，以至于大多数开发人员选择使用 Swift 编写新应用，或者至少使用 Swift 为现有应用编写新代码。

对于这样做的开发者来说，向 Swift 3 过渡过程中最令人难忘的是从 Swift 2 到 Swift 3 的痛苦迁移。作为常见基础类型的 [API 重命名](https://github.com/apple/swift-evolution/blob/master/proposals/0005-objective-c-name-translation.md) 的一部分，包括 `NSData` ，剔除掉它们的 `NS` 前缀，使用一个桥接的 Swift 值类型来取代它们。在大多数情况下，一切如愿以偿。但是在一些没有文档说明的行为，或不常见的行为上却存在一些差异，这些差异导致了巨大的变化。举例来说，考虑下面这个在 `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` 方法中的变化：


```
// Swift 2: deviceToken 的类型为 NSData
deviceToken.description // "<965b251c 6cb1926d e3cb366f dfb16ddd e6b9086a 8a3cac9e 5f857679 376eab7C>"

// Swift 3: deviceToken 的类型是 Data
deviceToken.description // "32 bytes"
```

但是许多开发者未被这点小麻烦阻挡住。他们一意孤行，把 `Data` 类型转化为 `NSData` ，再用之前的做法来解决这个问题。


```
// ⚠️ 警告：别这样做
let tokenData = deviceToken as NSData
let token = tokenData.description

let token = "\(deviceToken)".replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: "<", with: "")
                            .replacingOccurrences(of: ">", with: "")
```

用这种错误的方式想方设法使事情照旧进行，这一情况又持续了好几年。

但这一切随着 iOS 13 的到来走向一个句号。

> 这个改变的影响是很大的，而且值得多次强调:
> 如果你在 `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` 方法里的实现包括把 `deviceToken` 转换为 `String` 和调用 `replacingOccurrences(of:with:)` 方法，这种做法将会在用 iOS 13 SDK 编译的应用程序里失效，无论这个应用是用 Swift 写的还是用 Objective-C 写的。


### iOS 13 中的巨大变化
iOS 13 改变对基础对象描述的格式，包括 `NSData`：

```
// iOS 12
(deviceToken as NSData).description // "<965b251c 6cb1926d e3cb366f dfb16ddd e6b9086a 8a3cac9e 5f857679 376eab7C>"

// iOS 13
(deviceToken as NSData).description // "{length = 32, bytes = 0x965b251c 6cb1926d e3cb366f dfb16ddd ... 5f857679 376eab7c }"
```

之前，你可以把 `NSDate` 转换为 `String` 来强制拆解它的整个内容。而现在，`(deviceToken as NSData).description` 的输出变为 `deviceToken` 的长度和一个其内部字节的摘要。

所以从现在开始，如果需要把推送通知注册 `deviceToken` 转换为 Base 16 编码 / 十六进制字符串表示形式，你应该这样做：

```
let deviceTokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
```

为了条理清晰，让我们拆分这句代码且解释各个部分：
* `map` 方法操作这个序列的每个元素。因为 `Data` 在 Swift 中是一个字节序列，所以被传递的闭包对 `deviceToken` 中的每个字节都执行一遍。
* `String(format:)` 构造器使用 `%02x` [格式说明符](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) 计算数据中的每个字节（每个字节以匿名参数 `$0` 表示），以生成以零填充（当输出宽度小于 2 时）的两位十六进制表示形式的字节/8 位整数。
* 在收集完每个由 `map` 方法创建的字节表示形式后，`joined()` 把每个元素拼凑成一个字符串。


> 对于每个 `UInt8` 字节值，我们偏好使用 `String(_:radix:)` 构造器来创建一个 16 进制字符串表示形式。但在 Swift 标准库里没有内置可以从左边填充到两位数的 [Lpad 函数](https://www.theregister.co.uk/2016/03/23/npm_left_pad_chaos/)，所以我们选择 `printf` 格式说明符（[尽管有点令人担忧](https://nshipster.com/expressiblebystringinterpolation/)）

> 在 Stack Overflow 网站上，这个评价最高的 [回答](https://stackoverflow.com/questions/9372815/how-can-i-convert-my-device-token-nsdata-into-an-nsstring/24979958#24979958) 主张使用 `"%02.2hhx"` 格式说明符，而不是 `"02x"` 格式说明符。
> 开发者很容易迷失在 [IEEE 规范] (https://pubs.opengroup.org/onlinepubs/009695399/functions/printf.html) 中，所以这里用一些最少的代码示例来说明两种格式说明符之间的区别：

> ```
> //大于 UInt.max (255) 时
> String(format: "%02.2hhx", 256) // "00"
> String(format: "%02x", 256) // "100"

> // 小于 UInt.min (0) 时
> String(format: "%02.2hhx", -1) // "ff"
> String(format: "%02x", -1) // "ffffffff"
> ```
> 当数值超过 `UInt` 的表示范围时，`%02.2hhx` 格式说明符能确保产生两位 16 进制数（尽管有人可能会争论在这里默认失败是否更好）。

> 只要 `Data` 是一个元素类型为 `UInt8` 的集合，上述两种行为是无差别的：

> ```
> (UInt.min...UInt.max).map {
>     String(format: "%02.2hhx", $0) == String(format: "%02x", $0)
> }.contains(false) // false
> ```
> 别担心 `reduce` 和 `map` 加 `join` 之间任何传闻的性能差异。任何性能差异都是可以忽略不计的，更别说像这种不频繁的操作。


Apple 是不负责任地做出这一特定的改变吗？
我们为此讨论过，结果是：不，不是。

**开发者不应该依赖对象特定格式的** [描述](https://developer.apple.com/documentation/objectivec/nsobjectprotocol/1418746-description)。

在某个时候，转储整个 `Data` 值的内容的方式变得不可靠。更改为更简洁的摘要使调试更大的二进制数据更加容易。

如在本文开篇所谈及的法律条文一样，优先考虑先例是惯性的一种形式，而不是一成不变的真理。

*stare decisis* （遵循先例）在整个软件工程中扮演着很重要的角色。
举些例子，如 ["Referer" [sic] Header"](https://en.wikipedia.org/wiki/HTTP_referer)[^1] 和我们对 [电流方向](https://en.wikipedia.org/wiki/Electric_current#Conventions) 的约定。这些实例都展示了除非万不得已的改变外，坚持决策的价值。

[^1]: [[sic]](https://www.grammarly.com/blog/sic/)