title: "TimeInterval, Date, and DateInterval"
date: 发布时间（例如：2016-01-01）
tags: [Swift, NSHipster]
categories: [Swift, NSHipster]
permalink: timeinterval-date-dateinterval
keywords: 关键字（多个关键字用逗号隔开）
custom_title: 自定义标题
description: 本文介绍了 Foundation 框架中涉及 Date 时间的相关概念。

---
原文链接=https://nshipster.com/timeinterval-date-dateinterval/
作者=Mattt
原文日期=2018-10-08
译者=大罗
校对=校对名
定稿=定稿名

<!--此处开始正文-->

普拉多博物馆坐落在马德里市中心和萨拉曼卡区之间，距离广阔的 Buen Retiro 公园仅有几步之遥，这个博物馆吹逼说他们从很多欧洲有名画家那里搜集了各种珍藏画作。

<!--more-->

# 时间间隔，日期和日期间隔

普拉多博物馆坐落在马德里市中心和萨拉曼卡区之间，距离广阔的 Buen Retiro 公园仅有几步之遥，这个博物馆吹逼说他们从很多欧洲有名画家那里搜集了各种珍藏画作。不过，在你参观期间，你是会很快厌倦那些 17 世纪西班牙君主私人定制的肖像画的，考虑下参观 1 楼最北端的房间 - Sala 002。在那里你可以找到[法国艺术家 Simon Vouet 的巴洛克时代画作](https://www.museodelprado.es/en/the-collection/art-work/time-defeated-by-hope-and-beauty/ebaeb191-f3ff-43b1-9207-fb36a3e5ad5a)。

这不是你的问题，你会好奇为什么这对年轻女子气势汹汹的挥舞着一只铁钩和一柄长矛，站着威胁一个畏缩的老人，与此同时还有一群小天使在撕裂着老人的背。当然，这是个寓意啦。阅读旁边的解释牌，你会发现这画作的标题叫做 *Time defeated by Hope and Beauty*。那个老人代表时间。看到了他手中的沙漏和他脚下的长柄大镰刀了吗？

让我们花一点时间，站在这幅画的前面，来深入思考一下时间的神秘本质。

现在回头一想，我们对时间认知的局限性，从 Foundation 日期和时间 API 糟糕的命名上就反映出来了。

嗯，是时候让我们来把它们弄明白了。

***

秒是时间的基本单位。 也是唯一一个拥有固定时长的时间单位。

月份的长短各不相同（9 月份有 30 天......），年份也是一样（以每 400 年为周期每第 71 个年头有 53 个周......）某些年份会多出一天（如果你思考一下就会发现闰年的命名是不合理的）从夏令时减去一小时保留下来的时间转化成了增加的天数（感谢，本杰明·富兰克林）。 闰秒就没什么好说的了，正是因为闰秒的引入导致了，比如一分钟有 61 秒，一个小时有 3601 秒，当然，两周就是 1209601 秒这类奇怪的事。

`TimeInterval` （néeNSTimeInterval）是  `Double`  的一个别名，表示为以秒为单位的间隔时长数。在处理间隔时间问题上，你会看到它有作为 APIs 的参数和返回值类型。 作为一个双精度浮点数，TimeInterval 可用于表示时间数的一部分（但是对于超过毫秒精度的任何度量，你应该用其他方法来表示）。

## 日期和时间

很不幸，在 Foundation 中代表时间的类型被命名成了 `date`。通俗说，人们把“日期”从“时间”中区分出来的惯用思维是说前者和日历有关而后者和日常时间有关。但是  `date` 是源于日历中的一个完整独立概念。 与我们认知相反，它代表一个绝对时间点。

>为什么不把 `NSDate` 命名成 `NSTime` 呢？我们猜测是创作者想让 Objective-C API 和 Java 在文档中 [`java.util.date` 名称更加一致些](https://docs.oracle.com/javase/7/docs/api/java/util/Date.html) 。

另一个关于 `Date` 的困惑之处是，尽管它代表一个绝对时间点，但是我们在提及日期的时候是[通过一个时间段来定义它的](https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/Date.swift#L17-L20):

```swift
public struct Date : ReferenceConvertible, Comparable, Equatable {
    public typealias ReferenceType = NSDate

    fileprivate var _time: TimeInterval

    // ...
}
```

这个案例中，参考日期以是 2010 年 1 月 1 日起，格林尼标准时间(GMT)。

> 聊到这个话题时我们来推测一下哇，有人知道为什么 Apple 创造了一个新的标准替代 Unix Epoch（1970 年 1 月 1 日）吗? Mac OS X 第一次发布是在 2001 年，但是之前的 NSDate 中  `NSDate` 类源自 NeXT 时期。它是有可能在回避 [Y2K](https://en.wikipedia.org/wiki/Year_2000_problem) 冲突吗？ 

## 日期间隔与时间间隔

`DateInterval` 是最近添加到 Foundation 框架中的。它们在 iOS 10 和 macOS Sierra 有被介绍，这个类型代表两个绝对时间点之间的离散间隔（再次强调，和 `TimeInterval` 不同，它代表的以秒为单位的时长数）。

这样的好处是什么呢？考虑一下面这些使用情况。

### 从日历单元中获取日期间隔

为了知道某段时间的时间点——或者日子的起始点——你需要查看日历。在这里，你可以指定日历单元中的特定时间范围，比如说一天，一个月，或者一年。通过 `Calendar` 类中的 `dateInterval(of:for:)` 方法可以很轻松的做到。

```swift
let calendar = Calendar.current
let date = Date()
let dateInterval = calendar.dateInterval(of: .month, for: date)
```

因为我们正在调用 `Calendar`，我们对我们获取的返回值有信心。 看看它是如何处理夏令时时间保留转化问题，却不会忙的满头大汗。

```swift
let dstComponents = DateComponents(year: 2018,
                                   month: 11,
                                   day: 4)
calendar.dateInterval(of: .day,
                      for: calendar.date(from: dstComponents)!)?.duration
// 90000 second
```

现在是 2018 年了。你不觉得是时候该停止 `secondsInDay = 86400` 这样的硬编码了么？

## 计算日期间隔的交集

在这个例子中，让我们回到普拉多博物馆来欣赏一下彼得·保罗·鲁本斯的各种画作珍品——尤其是[这幅栩栩如生的 Swift 编程之神](https://www.museodelprado.es/coleccion/obra-de-arte/eolo/e447dadb-b93f-4ce5-84e9-e6ae1d95c6cd)。

鲁本斯和乌伟一样都有着巴洛克式的传统画风。他们都是同时代下的画家，在 `DateInterval` 的帮助下，我们几乎可以确定他们在艺术史上时间的重叠程度。

```swift
import Foundation

let calendar = Calendar.current

// Simon Vouet
// 西蒙・乌伟
// 9 January 1590 – 30 June 1649
// 1590/01/09 - 1649/06/30
let vouet =
    DateInterval(start: calendar.date(from:
        DateComponents(year: 1590, month: 1, day: 9))!,
                 end: calendar.date(from:
                    DateComponents(year: 1649, month: 6, day: 30))!)

// Peter Paul Rubens
// 彼得·保罗·鲁本斯
// 28 June 1577 – 30 May 1640
// 1577/06/28 - 1640/03/30
let rubens =
    DateInterval(start: calendar.date(from:
                            DateComponents(year: 1577, month: 6, day: 28))!,
                 end: calendar.date(from:
                            DateComponents(year: 1640, month: 5, day: 30))!)

let overlap = rubens.intersection(with: vouet)!

calendar.dateComponents([.year],
                        from: overlap.start,
                        to: overlap.end) // 50 years 
```

根据我们的计算，两位画家有 50 年时间活在同时期。

我们甚至可以更近一步，使用 `DateIntervalFormatter` 来提供一个更好的时间格式来描述那段时间。

```swift
let formatter = DateIntervalFormatter()
formatter.timeStyle = .none
formatter.dateTemplate = "%Y"
formatter.string(from: overlap)
// "1590 – 1640"
```

完美。你也能把这个代码打印出来，装上画框。把它挂在[巴黎审判](https://www.museodelprado.es/en/the-collection/art-work/the-judgement-of-paris/f8b061e1-8248-42ae-81f8-6acb5b1d5a0a)的旁边。

---

事实上，我们依旧不能了解时间到底是什么（或者它们是否真的存在）。但作为开发者，我对从 Foundation 的 `Date` APIs 里找到某种美感与及时明白如何来克服我们的理解上的不足都是充满希望的。

这就是这周的文章啦，我们下周见。

......