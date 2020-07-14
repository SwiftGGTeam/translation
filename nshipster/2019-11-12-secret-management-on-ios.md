title: "iOS 敏感信息管理"
date: 2020-05-01
tags: [iOS, NSHipster]
categories: [NSHipster]
permalink: nshipster-secret-management-on-ios
keywords: iOS, Secret
custom_title: iOS 敏感信息管理
description: 本文讨论了客户端上存储敏感信息是否安全的问题，并向读者介绍了一些安全存储敏感信息的做法

------

原文链接=https://nshipster.com/secrets/
作者=Mattt
原文日期=2019-11-12
译者=Ji4n1ng
校对= 
定稿= 

<!--此处开始正文-->

iOS 开发中尚未解决的难题之一是：*“如何在客户端上安全地存储敏感信息？”*

<!--more-->

这个问题的前提是，如果不采取恰当的措施，这些敏感信息将会以某一种方式泄露——可能是从源码版本控制（GitHub 等）中泄露，也可能是从一个经 App Store 分发的但被分析工具分析过的 `.ipa` 文件中泄露，或以其他方式泄露。

尽管敏感信息的安全性通常不是我们的首要关注点，充其量是次要关注点，但这方面的学术研究从未止步，这迫使我们作为开发人员必须认真对待这些威胁。

例如，北卡罗莱纳州立大学的研究人员 [发现](https://www.ndss-symposium.org/ndss-paper/how-bad-can-it-git-characterizing-secret-leakage-in-public-github-repositories/)，每天都有数千个 API 密钥，多因素敏感信息（multi-factor secrets）和其他的敏感证书在 GitHub 上泄漏。[(Meli, McNiece, & Reaves, 2019)](https://nshipster.com/secrets/#meli_2019) 另一篇发布在 2018 年的论文 [发现](https://ieeexplore.ieee.org/abstract/document/8719525/authors#authors) 在 100 个流行的 iOS 应用程序样本中有 68 个存在 SDK 证书误用问题。[(Wen, Li, Zhang, & Gu, 2018)](https://nshipster.com/secrets/#wen_2018)

本周在 NSHipster 上，我们将厚着脸皮地通过 [2017 年的一个梗](https://knowyourmeme.com/memes/galaxy-brain)，来逐步地介绍更睿智的策略以保护敏感信息的安全。

如果你的应用程序包含了嵌入式的 Twitter 访问令牌、AWS Key ID 或任何其他形式的证书，那么请继续阅读并打开你的脑洞。

## 🧠 正常脑袋 - 在源码中硬编码敏感信息

假设有一个与 Web 应用程序通信的应用程序，该应用程序需要将 API 密钥（一个敏感信息）附加到出站请求中以进行身份验证。这种方式可以完全由第三方框架管理，也可以通过在 AppDelegate 中设置的 `URLSession` 来实现。无论哪种情况，都存在关于如何存储以及在何处存储所需的 API 密钥的问题。

让我们考虑一下将密钥作为字符串常量嵌入代码中的后果：

```swift
enum Secrets {
    static let apiKey = "6a0f0731d84afa4082031e3a72354991"
}
```

当你打包应用程序并进行分发时，上面代码的踪迹似乎都消失了。编译操作将人类可读的文本转换为机器可执行的二进制文件，而没有留下任何敏感信息的踪迹。。。*对吗？*

*不太对。*

使用 [Radare2](https://rada.re/) 之类的逆向工程工具，可以从编译的可执行文件内部清楚地看到该敏感信息。你可以通过在自己项目中激活 Scheme，选择“通用 iOS 设备”，创建一个归档文件（Product > Archive）并检查生成的 `.xcarchive` 包，来验证这一点：

```
$ r2 ~/Developer/Xcode/Archives/….xcarchive/Products/Applications/Swordfish.app/Swordfish
[0x1000051fc]> iz
[Strings]
Num Paddr      Vaddr      Len Size Section  Type  String
000 0x00005fa0 0x100005fa0  30  31 (3.__TEXT.__cstring) ascii _TtC9Swordfish14ViewController
001 0x00005fc7 0x100005fc7  13  14 (3.__TEXT.__cstring) ascii @32@0:8@16@24
002 0x00005fe0 0x100005fe0  36  37 (3.__TEXT.__cstring) ascii 6a0f0731d84afa4082031e3a72354991
…
```

尽管一个从 App Store 下载你的应用程序的正常用户几乎从来不会想到在他们的设备上打开 `.ipa`，但是有很多新兴移动应用行业的个人和组织出于分析和安全的目的，去研究应用程序文件里的数据。即使这些公司中的大多数都做事光明正大，但也可能会有一些机器脚本通过对应用程序进行分析，挑选出硬编码的敏感信息。

其中大部分只是推测，但我们可以确定的是：

如果你在源代码中对敏感信息进行硬编码，则它们将永远存在于源码版本控制中——“永远”对于保护敏感信息来说是一段相当漫长的时间。当你对库的权限进行错误配置，或者服务提供商发生一次数据泄露，那么所有内容都可以被公开获取。工作中跟他人的合作必不可少，所以很有可能因为某个人（的失误）而最终把一切搞砸。

直接点说，就是：

**不要向源代码中提交任何敏感信息。**

引用本杰明·富兰克林（Benjamin Franklin）的话：

> 如果你不想让敌人知道你的秘密，就不要把它告诉朋友。

## 🧠 大脑袋 - 在 Xcode 配置文件和 Info.plist 中存储敏感

在 [上一篇文章](https://nshipster.com/xcconfig/) 中，根据 [App 最佳实践的 12 要素](https://12factor.net/config)，我们描述了如何使用 `.xcconfig` 文件在代码中将配置设置到外部环境。通过对 `Info.plist` 进行修改后，这些构建设置可以用作临时的 [`.env` 文件](https://www.ibm.com/support/knowledgecenter/en/ssw_aix_72/osmanagement/env_file.html)：

```swift
// Development.xcconfig
API_KEY = 6a0f0731d84afa4082031e3a72354991

// Release.xcconfig
API_KEY = d9b3c5d63229688e4ddbeff6e1a04a49
```

只要这些文件不受源码版本控制，此方法就可以解决代码中敏感信息泄漏的问题。乍一看，这似乎可以消除我们对泄漏到静态分析中的敏感信息的担忧：

如果我们像以前那样启动 *l33t hax0r* 工具并将其定位到我们的可执行文件中（`izz` 可以列出二进制中的字符串，`〜6a0f07` 可以使用敏感信息的前几个字符进行过滤），则搜索结果将为空：

```
$ r2 ~/Developer/Xcode/Archives/….xcarchive/Products/Applications/Swordfish.app/Swordfish
[0x100005040]> izz~6a0f
[0x100005040]>
```

但是在开始庆祝之前，你可能需要重新了解应用程序文件里剩余的数据：

```
$ tree …/Swordfish.app
├── Base.lproj
│   ├── LaunchScreen.storyboardc
│   │   ├── 01J-lp-oVM-view-Ze5-6b-2t3.nib
│   │   ├── Info.plist
│   │   └── UIViewController-01J-lp-oVM.nib
│   └── Main.storyboardc
│       ├── BYZ-38-t0r-view-8bC-Xf-vdC.nib
│       ├── Info.plist
│       └── UIViewController-BYZ-38-t0r.nib
├── Info.plist
├── PkgInfo
├── Swordfish
├── _CodeSignature
│   └── CodeResources
└── embedded.mobileprovision
```

那不是我们用来存储敏感信息的 `Info.plist` 文件吗？就在这里，和可执行文件一起打包的。

在某些人看来，此方法可能比硬编码敏感信息的安全性更*低*，因为无需使用任何高级工具就可直接从应用中访问该敏感信息。

```
$ plutil -p …/Swordfish.app/Info.plist
{
  "API_KEY" => "6a0f0731d84afa4082031e3a72354991"
…
```

用户在其设备上启动你的应用程序时，似乎不存在一种配置环境的方法。正如我们在上一节中看到的那样，`Info.plist` 是用于构建设置的，如果是用来作为敏感信息的交换站，显然不是一个好主意。

但是也许还有另一种方法，我们可以用代码捕获环境……

## 🧠 世界级脑袋 - 使用代码生成混淆秘密

不久前，我们写了 [GYB](https://nshipster.com/swift-gyb/)，这是一个 Swift 标准库中使用的代码生成工具。尽管该文章着重于消除模板代码，但 GYB 的元编程能力远不止于此。

例如，我们可以使用 GYB 将环境变量提取到生成的代码中：

```
$ API_KEY=6a0f0731d84afa4082031e3a72354991 \
gyb --line-directive '' <<"EOF"
%{ import os }%
let apiKey = "${os.environ.get('API_KEY')}"
EOF

let apiKey = "6a0f0731d84afa4082031e3a72354991"
```

从 GYB 生成（*而不是向版本控制中提交*）Swift 文件，同时从环境变量中提取敏感信息解决了源码中敏感信息泄漏的问题，但是它无法防范常见的静态分析工具。但是，我们可以结合使用 Swift 和 Python 代码（通过 GYB）以更难以逆向工程的方式来混淆敏感信息。

例如，这是一个（当然是粗略的）解决方案，该解决方案使用每次随机生成的盐实现异或密码：

```swift
// Secrets.swift.gyb
%{
import os

def chunks(seq, size):
    return (seq[i:(i + size)] for i in range(0, len(seq), size))

def encode(string, cipher):
    bytes = string.encode("UTF-8")
    return [ord(bytes[i]) ^ cipher[i % len(cipher)] for i in range(0, len(bytes))]
}%
enum Secrets {
    private static let salt: [UInt8] = [
    %{ salt = [ord(byte) for byte in os.urandom(64)] }%
    % for chunk in chunks(salt, 8):
        ${"".join(["0x%02x, " % byte for byte in chunk])}
    % end
    ]

    static var apiKey: String {
        let encoded: [UInt8] = [
        % for chunk in chunks(encode(os.environ.get('API_KEY'), salt), 8):
            ${"".join(["0x%02x, " % byte for byte in chunk])}
        % end
        ]

        return decode(encoded, salt: cipher)
    }

    …
}
```

敏感信息是从环境中提取的，并在作为包含在源代码中的 `[UInt8]` 数组常量之前会由 Python 函数进行编码。然后，这些编码值将通过等效的 Swift 函数运行以恢复原始值，而无需直接在源码中暴露任何敏感信息。

结果代码如下所示：

```swift
// Secrets.swift
enum Secrets {
    private static let salt: [UInt8] = [
        0xa2, 0x00, 0xcf, …, 0x06, 0x84, 0x1c,
    ]

    static var apiKey: String {
        let encoded: [UInt8] = [
            0x94, 0x61, 0xff, … 0x15, 0x05, 0x59,
        ]

        return decode(encoded, cipher: salt)
    }

    static func decode(_ encoded: [UInt8], cipher: [UInt8]) -> String {
        String(decoding: encoded.enumerated().map { (offset, element) in
            element ^ cipher[offset % cipher.count]
        }, as: UTF8.self)
    }
}

Secrets.apiKey // "6a0f0731d84afa4082031e3a72354991"
```

如果你正在使用 [CocoaPods](https://nshipster.com/cocoapods/)，则可能对 [CocoaPods 密钥插件](https://github.com/orta/cocoapods-keys) 感兴趣，它同样也是使用代码生成来编码敏感信息（尽管没有任何混淆）。

尽管 [通过混淆实现安全性](https://en.wikipedia.org/wiki/Security_through_obscurity) 在理论上可能并不完善，但 [在实践中它是一个有效的解决方案](https://ieeexplore.ieee.org/abstract/document/8449256)。[(Wang, Wu, Chen, & Wei, 2018)](https://nshipster.com/secrets/#wang_2018)

俗话说：

> 为了安全，你不必跑过熊。你只需要跑过身边的那个人。

## 🧠 银河级脑袋 - 不要在设备上存储敏感信息

不管我们在客户端上怎样混淆敏感信息，敏感信息泄露出来只是时间问题。只要有足够的时间和足够的动力，攻击者就可以对你放进程序里的东西进行逆向工程。

在移动应用程序中保护敏感信息的唯一*正确的*方法是将其存储在服务器上。

顺着这种策略，我们脑海中的电影情节将从一部 *Oceans 11* 风格的抢劫电影变成了一部高风险 *Behind Enemy Lines* 的护送任务电影。*（你的任务：从服务器传输一个敏感数据并将其存储在 [Secure Enclave](https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/storing_keys_in_the_secure_enclave)，并确保攻击者无法泄露它）。*

如果你没有可以信任的服务器，那么可以用以下几种 Apple 服务来传输：

- [按需资源（On-Demand Resources）](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/On_Demand_Resources_Guide/index.html)：下载 [数据资产](https://nshipster.com/nsdataasset/) 包含纯文本敏感信息。
- [CloudKit 数据库](https://developer.apple.com/documentation/cloudkitjs/cloudkit/database)：在 CloudKit 仪表板的私有数据库中设置敏感信息。*（小提示：当自动证书滚动功能（automatic credential rolling functionality）更改时，可以订阅这些更改）*
- [后台更新](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app)：一旦客户端连到 [APNS](https://nshipster.com/apns-device-tokens/)，该服务便会默默地向他们推送敏感信息。

再一次声明，一旦你的敏感信息到达了 Secure Enclave，它就会与下一个使用它的出站请求一起被发送回去。偶尔的正确选择是不够的；安全是一种习惯。

或换一种说法：

> Secure Enclave 中的敏感信息是安全的，但这不是我们使用敏感信息的目的。

## 🧠 宇宙级脑袋 - 不可能实现客户端敏感信息

保护在客户端上存储的敏感信息是无法做到的。一旦有人可以在自己的设备上运行你的软件，这一切就结束了。

如果可能的话 - 可以维护一条客户端和服务器之间的安全且封闭的通信通道，但这操作起来很复杂。

也许朱利安·阿桑奇（Julian Assange）说得最好：

> 保守敏感信息的唯一方法就是永远不要拥有敏感信息。

**与其将客户敏感信息管理视为要解决的问题，不如将其视为要避免的反面模式（anti-pattern）。**

> 译者注：在软件工程中，一个反面模式（anti-pattern或antipattern）指的是在实践中明显出现但又低效或是有待优化的设计模式，是用来解决问题的带有共同性的不良方法。它们已经经过研究并分类，以防止日后重蹈覆辙，并能在研发尚未投产的系统时辨认出来。

总之，除了不安全的匿名身份验证机制之外，`API_KEY` 是什么？这是一张空头支票，任何人都可以兑现，所以业务里你需要对它的操作持续负责。

任何配置有客户端敏感信息的第三方 SDK 在设计上都是不安全的。如果应用程序使用了需要这么做的 SDK，那么应查看是否有可能将它切换并集成到服务器上。否则你应该花些时间来了解潜在的敏感信息泄漏的影响，并考虑是否愿意承担这种风险。如果认为风险很大，那么寻找一种方法来混淆敏感信息，以减少泄露的可能性。

重申最初的问题：*“如何在客户端上安全地存储敏感信息？”*

我们的答案：*“不要这么做（但是，如果必须这么做的话，使用混淆吧）。”*

##### 引用

1. Meli, M., McNiece, M. R., & Reaves, B. (2019). 用 Git 管理它有多糟糕？描述公共 GitHub 存储库中的敏感信息泄漏问题。检索自 https://www.ndss-symposium.org/ndss-paper/how-bad-can-it-git-characterizing-secret-leakage-in-public-github-repositories/
2. Wen, H., Li, J., Zhang, Y., & Gu, D. (2018). 对 iOS 应用中 SDK 证书滥用的实证研究。在*2018 年第 25 届亚太软件工程大会（APSEC）* (pp. 258–267). https://doi.org/10.1109/APSEC.2018.00040
3. Wang, P., Wu, D., Chen, Z., & Wei, T. (2018). 通过混淆保护百万用户量的 iOS 应用程序：动机，误区和经验。 在 *2018 IEEE / ACM 第 40 届软件工程国际会议：实践中的软件工程（ICSE-SEIP）* (pp. 235–244).

---

nsmutablehipster

如果有问题或者有需要更正的地方，欢迎你来 [提问题](https://github.com/NSHipster/articles/issues) 和 [提交请求](https://github.com/NSHipster/articles/blob/master/2019-11-12-secrets.md)。

*本文使用 Swift 5.1 版本*。你可以在 [状态页](https://nshipster.com/status/) 上查找所有文章的状态信息。