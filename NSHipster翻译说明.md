# NSHipster 翻译说明

## 翻译流程

[NSHipster](https://nshipster.com/) 上面的文章之前一直是由 [NSHipster.cn](https://nshipster.cn/) 团队在负责翻译，现在是我们 (SwiftGG) 跟他们合作一起翻译。雨谨作为 SwiftGG 的代表，负责协调双方的交流。目前暂定的合作流程如下：

1. 收集待选文章。雨谨会挑选部分 [NShipster](https://nshipster.com/) 上的文章，如果大家发现了好文章，也可以发给他。
2. 确定待选文章。雨谨将待选文章发给 [NSHipster.cn](https://nshipster.cn/) 确认，如果他们觉得没问题，我们就挂到 GitHub 的 [issues](https://github.com/SwiftGGTeam/translation/issues) 上，供大家认领。
3. 认领 issue。当我们有人要翻译某篇文章时，请先联系雨谨，由他跟 [NSHipster.cn](https://nshipster.cn/) 再次确认，避免重复工作。如果他们也没做，我们就可以按正常流程开始翻译了。
4. 提交给 [NSHipster.cn](https://nshipster.cn/)。翻译完成，并在我们这边校对通过后，按照他们的[格式规范](# [NSHipster.cn](https://nshipster.cn/) 的译文规范)处理译文，然后提交 PR 到 NSHipster 的  [articles-zh-Hans](https://github.com/NSHipster/articles-zh-Hans) 仓库。可以参考 [我们提 PR 的方式](https://github.com/SwiftGGTeam/translation/blob/master/翻译流程概述及PR说明.md#如何发起-pull-request)，先 Fork 他们的仓库，本地修改 push 后再提交 PR。之后 [NSHipster.cn](https://nshipster.cn/) 会再次校对译文，然后发布到他们的 [网站](https://nshipster.cn/) 上。为了让他们能及时开始校对，提交 PR 后，请通知雨谨。
5. 同步发布到 SwiftGG 官方发布平台。

## [NSHipster.cn](https://nshipster.cn/) 的译文规范

注意，以下格式规范 **仅限** 提交到 [NSHipster.cn : articles-zh-Hans](https://github.com/NSHipster/articles-zh-Hans) 仓库时使用，提交到 [SwiftGG : translation](https://github.com/SwiftGGTeam/translation) 仓库时，依然使用 [我们自己的格式规范](https://github.com/SwiftGGTeam/translation/blob/master/SwiftGG%20排版指南.md)。

[NSHipster.cn](https://nshipster.cn/) 对 MarkDown 格式的要求如下：

1. 使用原文的格式，且**原文在上，译文在下**，方便校对者校验。原文仅用于校对，之后会被发布者删除，因此可以直接将原文粘贴上来，**不必使用注释语法**。具体参考我们提交到 NSHipster 的 [Never.md](https://raw.githubusercontent.com/mobilefellow/articles-zh-Hans/master/2018-07-30-never.md) 这篇文章中:

    > Every compiler textbook will tell you that a comment like this one can’t and won’t affect the behavior of compiled code. Murphy’s Law says otherwise.
    >
    > 所有编译器的教科书都会告诉你，这样一句注释不能也不会对编译出的代码产生任何影响。[墨菲定理](https://en.wikipedia.org/wiki/Murphy%27s_law) 告诉你并非如此，注释以下的代码一定会被触发。

2. 英文、数字与中文之间（中文标点除外）加一个空格。
3. 文章头部加上下面的内容：

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
