title: "iOS教程之给日历添加事件"
date: 2019-03-13
tags: [EventKit, iOS 12]
categories: [Swift Tutorial]
permalink: add-event-calendar-ios-tutorial
keywords: EventKit
custom_title: ""
description: 这是一篇EventKit的Swift教程

---

 原文链接=https://www.ioscreator.com/tutorials/add-event-calendar-ios-tutorial
 作者=Knopper
 原文日期=2018-11-13
 译者=Dongnan Chen
 校对=
 定稿=

 <!--此处开始正文-->

使用EventKit框架可以访问iOS设备上的日历。在本教程中，我们会创建一个iCloud日历，并且为它添加一项事件。本教程使用 Xcode 10 编写并运行于 iOS 12 系统。

打开 Xcode 并创建一个新的 Singe View App。

![](https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5be885660ebbe885c5a5c16c/1541965174907/single-view-xcode-template.png?format=1000w)

给工程取名为 **iOSAddEventTutorial**，然后用你习惯的规范来填写组织名称和组织标识。选择 Swift 语言并选择下一步。

![](https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5be886038985835f89824548/1541965345387/add-event-project.png?format=1000w)

<!--more-->

首先需要在 iOS 设备或者在 OS X 系统中创建一个新的 iCloud 日历。把该日历命名为 ioscreator。

![](https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5be886a740ec9a97ddc1ccc9/1541965683918/add-calendar-icloud.png?format=1000w)

因为事件会被保存到日历中，所以需要用户授权日历的访问权限。打开Info.plist并添加下列条目

![](https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5be971e403ce64619f8e7382/1542025714657/info-plist-authorize-access-calendar.png?format=1000w)

打开 **ViewController.swift** 文件并导入 EventKit framework

```swift
import EventKit
```

把 **viewDidLoad** 方法改写为

```swift
override func viewDidLoad() {
    super.viewDidLoad()
        
    // 1
    let eventStore = EKEventStore()
        
    // 2
    switch EKEventStore.authorizationStatus(for: .event) {
    case .authorized:
        insertEvent(store: eventStore)
        case .denied:
            print("Access denied")
        case .notDetermined:
        // 3
            eventStore.requestAccess(to: .event, completion:
              {[weak self] (granted: Bool, error: Error?) -> Void in
                  if granted {
                    self!.insertEvent(store: eventStore)
                  } else {
                        print("Access denied")
                  }
            })
            default:
                print("Case default")
    }
}
```

1. 创建了一个 EKEventStore 对象。它代表了日历的数据库
2. **authorizationStatus(for:) ** 方法返回授权状态
3. 如果授权状态还没有确定，可以通过 **requestAccess(to:completion:)** 方法来提示用户拒绝或者允许该访问。

当用户授权了访问权限时， **insertEvent(store:)** 方法会被调用。

```swift
func insertEvent(store: EKEventStore) {
    // 1
    let calendars = store.calendars(for: .event)
        
    for calendar in calendars {
        // 2
        if calendar.title == "ioscreator" {
            // 3
            let startDate = Date()
            // 2 hours
            let endDate = startDate.addingTimeInterval(2 * 60 * 60)
                
            // 4
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
                
            event.title = "New Meeting"
            event.startDate = startDate
            event.endDate = endDate
                
            // 5
            do {
                try store.save(event, span: .thisEvent)
            }
            catch {
               print("Error saving event in calendar")             }
            }
    }
}
```

1.  **calendars(for:) ** 方法返回所有支持事件的日历
2.  检查之前创建的日历 "ioscreator" 是否存在
3.  事件的起始时间是当前时间，结束时间是两小时后。（2 小时 * 60 分 * 60秒）
4.  创建一个标题为“新会议”的事件
5.  事件被保存到当前日历中。


由于 iOS 模拟器没有日历功能，所以本教程只能运行在 iOS 设备上。构建并运行该工程，应用需要被授权访问日历。

![](https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5be9743a4ae23793ccaf9e47/1542026312430/ask-permission-access-calendar.png?format=500w)

下一步，在 iOS 或者 Mac 设备上打开日历 app，"新会议"事件已经被添加到了日历中。

![](https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5be96a001ae6cfbdd7af1dc0/1542026432386/add-entry-calendar.png?format=750w)

你可以从GitHub的 ioscreator 仓库中下载到 **IOS8SwiftAddEventTutorial** 的源码。



