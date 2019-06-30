# NSHipster 翻译说明

> 之前 [NSHipster](https://nshipster.com/) 上面的文章之前一直是由 [NSHipster.cn](https://nshipster.cn/) 团队在负责翻译。
> 现在是 SwiftGG 跟他们合作一起翻译。

## 负责人

#### 翻译负责人 @雨谨

- **收集待选文章**

 @雨谨 将挑选部分 [NSHipster](https://nshipster.com/) 上的文章，如果自己有想翻译的（NSHipster上的）文章可以找他沟通。
- **确认翻译人员**

 和 [NSHipster](https://nshipster.com/) 确认之后负责人会找一个人翻译文章。
- **确认翻译进度**

 确定好翻译人员之后会确定一个翻译交付时间，一般**不超过两周**。

#### 校对

- **确认校对人员**

 待文章翻译完成之后，进入我们自己的校对流程，等待校对。

- **校对问题反馈**

 校对完成之后，译者将文章通过 PR 形式提交给 [NSHipster](https://nshipster.com/)。他们会自己再校对一遍，请译者注意修改。

## 翻译流程

#### 1.认领和翻译文章

- 认领之后

    - 确定要翻译的文章之后，点击打开 [**Issues**](https://github.com/SwiftGGTeam/translation/issues)，在右侧的 **Assignees** 栏点击 **assign yourself**
    - 确定最后的交付日期，在保证质量的前提下尽量以最快速度完成。

- 翻译时

    - 需要注意**格式**，尤其是中英文和数字以及代码，可以参看 [这个说明](https://github.com/SwiftGGTeam/translation/blob/master/SwiftGG%20%E6%8E%92%E7%89%88%E6%8C%87%E5%8D%97.md)
    - 文章头部需要添加通用头部，具体格式可以参考 [这个说明](https://raw.githubusercontent.com/SwiftGGTeam/translation/master/%E4%B9%A6%E5%86%99%E8%A7%84%E8%8C%83%E5%8F%8ADemo/SwiftGG%E5%8D%9A%E6%96%87%E4%B9%A6%E5%86%99%E8%A7%84%E8%8C%83.md)，还有 [这个例子](https://raw.githubusercontent.com/SwiftGGTeam/translation/master/%E4%B9%A6%E5%86%99%E8%A7%84%E8%8C%83%E5%8F%8ADemo/20160726_simple-barcode-reader-app-swift.md)

- 翻译完成后，**务必自查这三件事**

    - **1. 文章头部格式是否符合文档要求**
    - **2. 文章内容格式是否符合文档要求**
    - **3. 翻译完成后至少间隔一天重新阅读整篇译文，将自己设置成读者出声阅读译文，将所有读着别扭、不通顺的句子都修改好（注意！别忘了格式）**

#### 2. 内部校对

- 按照 [这个说明](https://github.com/SwiftGGTeam/translation/blob/master/%E7%BF%BB%E8%AF%91%E6%B5%81%E7%A8%8B%E6%A6%82%E8%BF%B0%E5%8F%8APR%E8%AF%B4%E6%98%8E.md#%E5%A6%82%E4%BD%95%E5%8F%91%E8%B5%B7-pull-request) 创建 Pull requests（以下简称 PR） 在 PR 的内容里关联对应的 Issues，关联方式：将 Issues 页面的网址复制到 PR 信息中或者直接在 Pull requests 信息中评论 `#11` 11 是对应的 Issues 号
- 翻译文章放到 `translation/nshipster` 文件夹下，命名建议 `yyyyMMdd_文章名.md` 例如 `20180730_Never.md`。
- 提交 PR 之后等待校对

#### 3. [NSHipster.cn](https://nshipster.cn/) 校对

**因 [NSHipster.cn](https://nshipster.cn/) 对校对有特殊要求故需要调整你原来的译文格式**

- 校对格式，使用**原文在上，译文在下**。从 [NSHipster/articles](https://github.com/NSHipster/articles) 仓库下载的原文的 .md 文件，包含了标准的 NSHipster 格式。因此建议将译文复制到原文文件，而不是将 [https://nshipster.com](https://nshipster.com) 上的原文复制到译文文件。示例如下:

> Every compiler textbook will tell you that
a comment like this one can't and won't affect the behavior of compiled code.
[Murphy's Law](https://en.wikipedia.org/wiki/Murphy%27s_law) says otherwise.
>
> 所有编译器的教科书都会告诉你，这样一句注释不能也不会对编译出的代码产生任何影响。[墨菲定理](https://en.wikipedia.org/wiki/Murphy%27s_law) 告诉你并非如此，注释以下的代码一定会被触发。

- 按照他们的 [格式规范]( [NSHipster.cn](https://nshipster.cn/) 的译文规范 ) 处理译文

    - 英文、数字与中文之间（中文标点除外）加一个空格。
    - 对于系统名词（如 Finder，Preview）和被大众所熟悉的英文名词（如 Dark Mode），如果没有贴切的中文词语，可以不翻译。例如，Finder 和 AirDrop 的官方翻译“访达”和“隔空投递”并不是很好因此不建议在译文中使用。
    - 当需要做名词翻译时，到底是采用“中文（英文）”还是“英文（中文）”模式，如 Dark Mode（深色模式）或 深色模式（Dark Mode），取决于后续段落里再次出现同一个单词时，你打算显示中文还是英文。以 Finder 为例，如果后续段落你都打算显示 “ Finder ”，那么第一次出现时，应该显示“ Finder（访达）”，以便让中文版操作系统的用户知道，Finder 就是 访达；反之，第一次应该显示 “ 访达（Finder）”，以便让英文版操作系统的用户了解对应关系。
    - 只需要翻译 [NSHipster/articles](https://github.com/NSHipster/articles) 仓库的原文的内容。[NSHipster.com](https://nshipster.com) 的文章可能包含一些其他信息，比如 [macOS Dynamic Desktop](https://nshipster.com/macos-dynamic-desktop/) 中的 “nsmutablehipster”，这些都不需要翻译的。
    - 文章头部加上下面的内容

```
---
layout: post
title: NSDateComponents
category: Cocoa
author: Mattt
translator: Candyan
---
```

更多细节可以参考他们的 [articles-zh-Hans](https://github.com/NSHipster/articles-zh-Hans) 仓库中已发布文章的排版格式。

- 然后提交 PR 到 NSHipster 的  [articles-zh-Hans](https://github.com/NSHipster/articles-zh-Hans) 仓库。可以参考 [我们提 PR 的方式](https://github.com/SwiftGGTeam/translation/blob/master/翻译流程概述及PR说明.md#如何发起-pull-request)，先 Fork 他们的仓库，本地修改 push 后再提交 PR。
- [NSHipster.cn](https://nshipster.cn/) 会再次校对译文确定无误后发布到他们的 [网站](https://nshipster.cn/) 上。为了让他们能及时开始校对，向他们的仓库提交 PR 后，请微信通知 @雨谨。

#### 4.同步发布到 SwiftGG 官方发布平台。
- @Forelax 负责。


