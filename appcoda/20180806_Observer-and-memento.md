
title: Swift 设计模式 #2： 观察者模式与备忘录模式
date: 2018.08.06
tags: [Design Patterns]
categories:[Swift]
permalink: https://www.appcoda.com/design-pattern-behavorial/

原文链接=https://www.appcoda.com/design-pattern-behavorial/
作者=ANDREW JAFFEE
原文日期=2018.08.06
译者=JOJO
校对=
定稿=

This tutorial is the second installment in an AppCoda series on design patterns [started last week](https://www.appcoda.com/design-pattern-creational/). There are 23 classic software development design patterns probably first identified, collected, and explained all in one place by the “Gang of Four” (“GoF”), Erich Gamma, Richard Helm, Ralph Johnson, and John Vlissides in their seminal book, [“Design Patterns: Elements of Reusable Object-Oriented Software.”](https://smile.amazon.com/Design-Patterns-Object-Oriented-Addison-Wesley-Professional-ebook/dp/B000SEIBB8/). Today, we’ll focus on two of these patterns, “observer” and “memento,” which fall into what the GoF calls the “behavioral” category.

本次教程是 AppCoda [上周开启](https://www.appcoda.com/design-pattern-creational/)的设计模式系列的第二期。在软件设计领域的四位大师级人物（GoF，又称“四人帮”或“Gang of Four”） —— Erich Gamma, Richard Helm, Ralph Johnson 和 John Vlissides 所著的 《设计模式：可复用面向对象软件的基础》一书中，首次对软件设计中总共 23 种设计模式进行了定义和归类，并对它们作了专业阐述。今天，我们将聚焦于其中两个行为型设计模式 —— “观察者模式” 和 “备忘录模式”。

Software development is an endeavor into modeling real world scenarios in the hopes of creating tools to enhance the human experience in such scenarios. Tools for managing finances, e.g., banking apps and shopping aids like Amazon or eBay’s iOS apps, definitely make life much simpler than it was for consumers just ten years ago. Think of how far we’ve come. While software apps have generally gotten more powerful and simpler to use for consumers, development of said apps has gotten [much more complex](http://iosbrain.com/blog/2018/04/29/controlling-chaos-why-you-should-care-about-adding-error-checking-to-your-ios-apps/#chaos) for developers.

软件开发领域致力于对真实世界的场景进行建模，并期望能创造出一系列工具来提高人类对这些场景的理解与体验。与 10 年前相比，一些类似银行应用和辅助购物应用（如亚马逊或 eBay 的 iOS 客户端应用）的财务类工具的出现，无疑让顾客们的生活变得更加简单。当我们回顾软件开发的发展历程，定会感叹我们在软件开发领域上走过了漫长而又成功的道路。如今，软件应用的功能普遍变得强大且易用，但对于开发者来说，开发这些软件却变得[越来越复杂](http://iosbrain.com/blog/2018/04/29/controlling-chaos-why-you-should-care-about-adding-error-checking-to-your-ios-apps/#chaos)

So developers have created an arsenal of best practices to manage complexity, like object-oriented programming, protocol-oriented programming, value semantics, local reasoning, breaking large pieces of code into smaller ones with well-defined interfaces (like with Swift extensions), syntactic sugar, to name some of the most popular. One of the most important best practices that I didn’t mention, but that merits much attention, is the use of design patterns.

开发者们为了管理软件的复杂性，创造了一系列的最佳实践 —— 例如面向对象编程、面向协议编程、值语义、局部推理（Local Reasoning）、把大块的代码切分成一系列小块的代码并附上友好的接口（如 Swift 中的扩展）、语法糖等。但在众多的最佳实践之中，有一个非常重要且值得我们关注的最佳实践并没有在上文中提及 —— 那就是设计模式的使用。

## Design Patterns

## 设计模式

Design patterns are an extremely important tool with which developers can manage complexity. It’s best to conceptualize them as generally templated techniques, each tailored to solving a corresponding, recurring, and readily identifiable problem. Look at them as a list of best practices you would use for coding scenarios that you see over and over again, like how to create objects from a related family of objects without having to understand all the gory implementation details of that family. The whole point of design patterns is that they apply to commonly occurring scenarios. They’re reusable because they’re generalized. A specific example should help.

对于开发者来说，设计模式是管理代码复杂度问题的一个尤其重要的工具。我们理解设计模式最好的办法，就是把设计模式概念化为 —— 有固定模版的通用技术，每一个设计模式的模版都是为一个常见且易于辨别的特定问题而量身打造的。你可以把设计模式看作是一系列最佳实践的集合，它们可以用于一些经常出现的编码场景：例如如何利用一系列有关联的对象创建出新的对象，并且不需要去理解原本那一系列对象中“又臭又长”的代码实现。设计模式最重要的意义是其可以应用于那些常见的场景。同时，由于设计模式都是已经创造出来的固定模式，拿来即用的特质令它具有很高的易用性。为了能更好的理解设计模式，我们来看一个例子：

Design patterns are not specific to some use case like iterating over a Swift array of 11 integers (`Int`). For example, the GoF defined the *iterator* pattern to provide a common interface for traversing through all items in some collection without knowing the intricacies (i.e., type) of the collection. A design pattern is not programming language code. It is a set of guidelines or rule of thumb for solving a common software scenario.

设计模式并不能解决一些非常具体的问题。例如 “如何在 Swift 中遍历一个包含 11 个整型（`Int`）的 数组”之类的的问题。我们从一个例子来更好地理解为什么设计模式不能解决此类具体问题 —— 为了给 “便捷地（例如不需要知道集合中元素的类型）遍历集合的所有元素” 提出通用的解决方案，GoF 定义了*迭代器*模式。因此，我们不能单纯地把设计模式当作某种语言的代码，它只是用于解决通用软件开发场景的规则和指引。

Remember that I discussed the [“Model-View-ViewModel” or “MVVM”](https://www.appcoda.com/mvvm-vs-mvc/) design pattern here on AppCoda — and of course the very well-known [“Model-View-Controller” or “MVC”](https://www.appcoda.com/mvvm-vs-mvc/) design pattern, long favored by Apple and many iOS developers.

我曾经在 AppCoda 中讨论过 [“Model-View-ViewModel” 或 “MVVM”](https://www.appcoda.com/mvvm-vs-mvc/)  设计模式 —— 当然也少不了那个 Apple 和 众多 iOS 开发者们长期喜爱着的经典设计模式 [“Model-View-Controller” 或 “MVC”](https://www.appcoda.com/mvvm-vs-mvc/) 

These two patterns are generally applied to *entire applications*. MVVM and MVC are *architectural*design patterns and are meant to separate the user interface (UI) from the app’s data and from code for presentation logic, and to separate the app’s data from core data processing and/or business logic. The GoF design patterns are more specific in nature, meant to solve more distinct problems *inside* an application’s code base. You may use three or seven or even twelve GoF design patterns in one app. Remember my *iterator* example. Delegation is [another great example](https://www.appcoda.com/swift-delegate/) of a design pattern, though not specifically on the GoF’s list of 23.

这两种设计模式通常来说会应用于*整个应用层面*。MVVM 和 MVC 可以看作是*架构层面上*的设计模式，它们主要的作用可以简单分成四个方面：隔离用户界面（UI）与应用的数据；隔离用户界面（UI）与负责展示逻辑的代码；隔离应用的数据与核心数据处理逻辑；隔离应用的数据与业务逻辑。GoF 的设计模式都具有特殊性，它们都旨在解决一些在应用的*代码库中*较为特别的问题。你可能会在开发一个应用的时候用到好几个 GoF 的设计模式。同时你需要记得设计模式并不只是一些具体的代码实例，它们解决的是一些更抽象层面上的问题（希望你没忘记上面的*迭代器*例子）。除此之外我还想提及一个没有在 GoF 列出的 23 个设计模式之中，但却是设计模式的[典型例子](https://www.appcoda.com/swift-delegate/) —— 代理模式。

While the GoF book has taken on biblical connotations for many developers, it is not without its detractors. We’ll talk about that in the conclusion to this article.

虽然 GoF 关于设计模式的书已经被众多开发者视为圣经般的存在，但仍存在一些对其批判的声音。我们会在本文结尾的部分讨论这个问题。

### Design pattern categories

### 设计模式类别

The GoF organized their 23 design patterns into 3 categories, “creational,” “structural,” and “behavioral.” This tutorial discusses two patterns in the *behavioral* category. This pattern’s purpose is imposing safe, common sense, and consistent etiquette, form, and best practices for behaviour onto classes and structs (actors). We want good, consistent, and predictable behavior from all actors inside an entire application. We want good behavior both within actors themselves and between different actors that interact/communicate. Evaluation of actors’ behavior should be considered before and at compile time, which I sometimes call “design time,” *and* at runtime, when we’ll have lots of *instances* of classes and structs all doing their own thing *and* constantly interacting/communicating. Since communication between instances leads to so much software complexity, having rules for consistent, efficient, and safe communications is of paramount importance, but that concept should not in any way diminish the need for good design practices when building each individual actor. Since we’re so focused on behavior, we must remember to use consistent patterns when assigning responsibilities to actors and when assigning responsibilities to combinations of actors.

GoF 把他们提出的 23 种设计模式整理到了 3 种大的类别中：“创建型模式”、“结构型模式”以及“行为型模式”。本次的教程会讨论*行为型模式*类别中的两种设计模式。行为型模式的主要作用是对类和结构体（参与者）的行为赋予安全性、合理性，以及定义一些统一的规则、统一的的形式和最佳实践。对于整个应用中的参与者，我们都希望有一个良好的、统一的、并且可预测的行为。同时，我们不仅希望参与者本身拥有良好的行为，也希望不同的参与者之间的交互/通信可以拥有良好的行为。对于参与者的行为评估，其时机应该在编译之前以及编译时 —— 我通常把这段时间称之为“设计时间”，以及在运行时 —— 此时我们会有大量的类和结构体的实例在各司其职或与其他实例交互/通信。由于实例间的通信会导致软件复杂度的增加，因此制定一系列关于一致性、高效率和安全通信的规则是极为重要的，但与此同时，在构建每个单独的参与者时，这个概念不应以任何方式降低设计的质量。由于需要非常着重于行为，我们必须牢记一点 —— 在赋予参与者职责时必须使用一致的模式。

Before I wax too far theoretical, let me provide tangible examples to assure you that I’ll be demonstrating theory with in-depth practice as realized in Swift code. In this tutorial, we’ll see how to consistently assign responsibility for maintaining an actor’s state. We’ll also see how to consistently assign responsibility for one actor, the subject, to send notifications to many actor-observers, and conversely, how to consistently assign responsibility to the observers for registering with the subject to get notifications.

在高谈阔论太多理论之前，让我先说明一下本次教程中你会有哪些收获，同时所有的相关实践代码我都会用 Swift 来实现。在本次教程中，我们会了解到如何能够通过一致地赋予职责来维持参与者的状态。我们会了解到如何一致地赋予职责给一个参与者，让他能够发送通知给其他观察者。与之对应，我们也会了解到如何一致地赋予职责给观察者们注册通知。

The whole notion of *consistency* should be self-evident to you when discussing design *patterns*. Keep in mind a theme that was highlighted in [last week’s post](https://www.appcoda.com/design-pattern-creational/), a theme that will occur over and over as we discuss more and more design patterns: [hiding complexity (encapsulation)](http://iosbrain.com/blog/2017/02/26/intro-to-object-oriented-principles-in-swift-3-via-a-message-box-class-hierarchy/#advantages). It is one the highest goals of smart developers. For example, object-oriented (OOP) classes can provide very complex, sophisticated, and powerful functionality without requiring the developer to know anything about the internal workings of those classes. In the same vein, Swift [protocol-oriented programming](https://www.appcoda.com/pop-vs-oop/) is an extremely important yet relatively new technique for controlling complexity. Managing [complexity](http://iosbrain.com/blog/2018/01/02/understanding-swift-4-generics-and-applying-them-to-your-code/#complexity) is a developer’s greatest burden, but here we are talking about taming that beast!

当你讨论设计模式时，你应该把一致性当成最显而易见的基本概念。在[上周的推送](https://www.appcoda.com/design-pattern-creational/)中，我们着重讨论了一个概念：[高复杂度（封装）](http://iosbrain.com/blog/2017/02/26/intro-to-object-oriented-principles-in-swift-3-via-a-message-box-class-hierarchy/#advantages)。你必须把这个概念当作中心思想牢记于心，因为它会随着我们更深入地讨论设计模式而出现地越发频繁。举个例子，面向对象（OOP）中的众多类，可以在不需要开发者知道任何其内部实现的前提下，提供非常复杂、成熟且强大的功能。同样， Swift 的[面向协议编程](https://www.appcoda.com/pop-vs-oop/)也是一项对于控制复杂度来说极为重要的新技术。对开发者来说，想要管理好[复杂度](http://iosbrain.com/blog/2018/01/02/understanding-swift-4-generics-and-applying-them-to-your-code/#complexity)是一件异常困难的事情，但我们现在即将把这头野兽驯服！

### A note on this tutorial’s prose and definitions

### 关于此教程的提醒

For this tutorial, I’ve decided to concentrate my explanatory prose as inline commentary in my sample apps’ code. While I will provide brief explanations of today’s design pattern concepts, I very much want you to look at my code, read the comments, and fully internalize the techniques I’m sharing with you. After all, if you can’t write the code, and can only talk about the code, you’re not going to make it through very many job interviews — and you’re not really a hardcore developer.

在这次的教程中，我决定把文字聚焦于对示例代码的解释。我将对今天所要介绍的设计模式概念进行一些简单明了的陈述，但同时为了能够让你更好地理解我所分享的技术，希望你可以认真看看代码和注释。毕竟作为一名程序员，如果你只能谈论代码而不能编写代码，那你可能会在很多面试中失利 —— 因为你还不够硬核。

You probably noticed in my definition of the behavioral design pattern that I’m following Apple’s [documentation convention](https://docs.swift.org/swift-book/LanguageGuide/ClassesAndStructures.html):

你也许会留意到，我对与行为型设计模式的定义是遵循于苹果的[文档规范](https://docs.swift.org/swift-book/LanguageGuide/ClassesAndStructures.html):

> An instance of a class is traditionally known as an object. However, Swift structures and classes are much closer in functionality than in other languages, and much of this chapter describes functionality that applies to instances of *either* a class or a structure type. Because of this, the more general term instance is used.

I’ve also taken the liberty of referring to classes and structs as “actors” at design time.

在设计时，我把对类和结构体的任何引用都描述为“参与者”。

## The observer design pattern

## 观察者模式

The observer pattern is probably something you’ve all experienced while using Apple mobile devices, but hopefully you’ve also noticed it while coding your iOS apps. Every time it rains where I live, I and a whole lot of other people around here get push notifications which pop up on our iPhones — lock screen or normal screen — whenever it rains. Here’s what they look like:

在使用苹果的移动设备时，观察者模式可能是贯穿整个应用使用过程的东西 —— 你应该在编写 iOS 应用时也发现了这一点。在我生活的地方，每当下雨天的时候，包括我在内的很大一部分人都会收到 iPhone 上的通知。不管是锁屏的状态还是解锁的状态，只要下起雨来，你都会收到一条类似下面这样的通知：

![PushNotification demo](https://www.appcoda.com/wp-content/uploads/2018/08/PushNotification.png)

*One source*, Apple, is sending out — broadcasting — notifications to *many* thousands of iPhones, on behalf of the National Weather Service, warning people in my area of the possibility of flooding. In more concrete terms, like at the level of an iOS app, one instance, the *subject*, notifies (many) other instances, the *observers*, of changes to the state of the *subject*. The instances participating in this broadcast type communication don’t need to know about one another. This is a great example of [loose coupling](https://www.webopedia.com/TERM/L/loose_coupling.html).

作为所有通知的*源头*，苹果会代表国家气象局（National Weather Service）向*成千上万*的 iPhone 用户发送（广播）通知，提醒他们在其区域内是否有洪水灾害的风险。更具体一点地在 iOS 应用层级上说，当某一个实例（也就是被观察者）的状态发生改变时，它会通知其他（不止一个）的被称为*观察者*的实例，告诉他们自己的某个状态发生了变化。所有参与此次广播通信的实例都不需要知道除了自身以外的任何其他实例。这是一个关于[松耦合](https://www.webopedia.com/TERM/L/loose_coupling.html)的绝佳示例。

The subject instance, usually a single critical resource, broadcasts notifications about a change in its state to many observer instances that depend on that resource. Interested observers must subscribe to get notifications.

被观察的实例（通常是一个重要的资源）会广播关于自身状态改变的通知给其他众多观察者实例。对这些状态改变有兴趣的观察者必须通过订阅来获取关于状态改变通知。

Thankfully, iOS has a built-in and well-known feature for enabling the observer pattern: [NotificationCenter](https://developer.apple.com/documentation/foundation/notificationcenter), which I’ll let you study up on yourself [here](http://iosbrain.com/blog/2018/02/09/nsnotificationcenter-in-swift-4-intra-app-communication-sending-receiving-listening-stop-listening-for-messages/).

这次我们不得不说苹果还是很靠谱的，iOS 已经内置了一个广为人知的用于观察者模式的特性：[NotificationCenter](https://developer.apple.com/documentation/foundation/notificationcenter)。在这里我不会对其作过多介绍，读者可自行在[这里](http://iosbrain.com/blog/2018/02/09/nsnotificationcenter-in-swift-4-intra-app-communication-sending-receiving-listening-stop-listening-for-messages/)学习相关内容。

### Use case for observer design pattern app

### 观察者模式用例

My observer example project, available on [GitHub](https://github.com/appcoda/Observer-Pattern-Swift), showcases how this broadcast type communication works.

我的观察者模式示例项目展示了这种广播类型的通信是如何工作的，你可以在 [Github 上找到它](https://github.com/appcoda/Observer-Pattern-Swift)。

I know this is not quite how the iOS Human Interface Guidelines advise you to do things, but bear with me as I needed an example of a single critical resource. Suppose we were to take a proactive approach and have a single instance of a subject responsible for monitoring network connectivity/reachability. This is the broadcaster, and to implement one, you just need to have an actor adopt my `ObservedProtocol`.

假设我们有一个工具来监视网络连接状况，并对已连接或未连接的状态作出响应。这个工具我们可以称之为广播者。为了实现此工具，你需要一个参与者遵循我提供的 `ObservedProtocol` 协议。虽然我知道这么做并不太符合苹果的 iOS Human Interface Guideline 的建议，但我为了更好地演示观察者模式，我需要一个足够重要的资源（网络状况）。

Suppose there are multiple instances of observers, like an image downloader class, a login instance that verifies user credentials via a REST API, and an in-app browser that all subscribe to the subject to get notified of network connection status. To implement these, you could take pretty much any class and make it a descendent of my “abstract” `Observer` class, which adopts the `ObserverProtocol`. (I’ll explain later why I limited my example observer code to a class.)

假设现在有许多个不同的观察者实例全都向被观察的对象订阅了关于网络连接状况的通知，例如一个图片下载类，一个通过  REST API 验证用户资格的登录业务实例，以及一个应用内浏览器。为了实现这些，你需要创建多个继承于我提供的 `Observer` 虚类（此基类同时遵循 `ObserverProtocol` 协议）的自定义子类。（我稍后会解释为何我会把我关于观察者的示例代码放在一个类中）。

To implement observers for the purposes of my example app, I created the `NetworkConnectionHandler` class. When instances of this concrete class get notifications of `NetworkConnectionStatus.connected`, they turn a `UIView` instance green; when they get notifications of `NetworkConnectionStatus.disconnected`, they turn a `UIView` instance red.

为了实现我示例应用中的观察者们，我创建了一个 `NetworkConnectionHandler` 类。当这个类的具体实例接收到 `NetworkConnectionStatus.connected` 通知时，这些实例会把几个视图变成绿色；当接收到 `NetworkConnectionStatus.disconnected` 通知时，会把视图变成红色。

Here’s my sample app code compiled, installed, and running on an iPhone 8 Plus:

下面是我的代码在 iPhone 8 Plus 设备上运行的效果：

![img](https://www.appcoda.com/wp-content/uploads/2018/08/ObserverAppDemo.gif)

Here’s the Xcode console output corresponding to the previous video:

上面的运行过程中，Xcode 控制台的输出如下：

![img](https://www.appcoda.com/wp-content/uploads/2018/08/ObserverAppConsoleOutput.gif)

### Sample code for observer design pattern app

### 观察者模式应用的示例代码

To see the heavily commented code I just described in the previous section, please look at file `Observable.swift` in my sample project:

关于我上面所说的代码，你可以在项目中的 `Observable.swift` 文件找到。每段代码我都加上了详细的注释。

```swift
import Foundation
 
import UIKit
 
// Make notification names consistent and avoid stringly-typing.
// Try to use constants instead of strings or numbers.
extension Notification.Name {
    
    static let networkConnection = Notification.Name("networkConnection")
    static let batteryStatus = Notification.Name("batteryStatus")
    static let locationChange = Notification.Name("locationChange")
 
}
 
// Various network connection states -- made consistent.
enum NetworkConnectionStatus: String {
    
    case connected
    case disconnected
    case connecting
    case disconnecting
    case error
    
}
 
// The key to the notification's "userInfo" dictionary.
enum StatusKey: String {
    case networkStatusKey
}
 
// This protocol forms the basic design for OBSERVERS,
// entities whose operation CRTICIALLY depends
// on the status of some other, usually single, entity.
// Adopters of this protocol SUBSCRIBE to and RECEIVE
// notifications about that critical entity/resource.
protocol ObserverProtocol {
    
    var statusValue: String { get set }
    var statusKey: String { get }
    var notificationOfInterest: Notification.Name { get }
    func subscribe()
    func unsubscribe()
    func handleNotification()
    
}
 
// This template class abstracts out all the details
// necessary for an entity to SUBSCRIBE to and RECEIVE
// notifications about a critical entity/resource.
// It provides a "hook" (handleNotification()) in which
// subclasses of this base class can pretty much do whatever
// they need to do when specific notifications are received.
// This is basically an "abstract" class, not detectable
// at compile time, but I felt this was an exceptional case.
class Observer: ObserverProtocol {
    
    // This specific state reported by "notificationOfInterest."
    // I use String for maximum portability. Yeah, yeah...
    // stringly-typed...
    var statusValue: String
    // The key to the notification's "userInfo" dictionary, with
    // which we can read the specific state and store in "statusValue."
    // I use String for maximum portability. Yeah, yeah...
    // stringly-typed...
    let statusKey: String
    // The name of the notification this class has registered
    // to receive whenever messages are broadcast.
    let notificationOfInterest: Notification.Name
    
    // Initializer which registers/subscribes/listens for a specific
    // notification and then watches for a specific state as reported
    // by notifications when received.
    init(statusKey: StatusKey, notification: Notification.Name) {
        
        self.statusValue = "N/A"
        self.statusKey = statusKey.rawValue
        self.notificationOfInterest = notification
        
        subscribe()
    }
    
    // We're registering self (this) with NotificationCenter to receive
    // all notifications with the name stored in "notificationOfInterest."
    // Whenever one of those notifications is received, the
    // "receiveNotification(_:)" method is called.
    func subscribe() {
        NotificationCenter.default.addObserver(self, selector: #selector(receiveNotification(_:)), name: notificationOfInterest, object: nil)
    }
    
    // It's a good idea to un-register from notifications when we no
    // longer need to listen, but this is more of a historic curiosity
    // as, since iOS 9.0, the OS does some type of cleanup.
    func unsubscribe() {
        NotificationCenter.default.removeObserver(self, name: notificationOfInterest, object: nil)
    }
    
    // Called whenever a message labelled "notificationOfInterest"
    // is received. This is our chance to do something when the
    // state of that critical resource we're observing changes.
    // This method "must have one and only one argument (an instance
    // of NSNotification)."
    @objc func receiveNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo, let status = userInfo[statusKey] as? String {
            
            statusValue = status
            handleNotification()
            
            print("Notification \(notification.name) received; status: \(status)")
            
        }
        
    } // end func receiveNotification
    
    // YOU MUST OVERRIDE THIS METHOD; YOU MUST SUBCLASS THIS CLASS.
    // I've MacGyvered this class into being "abstract" so you
    // can subclass and specialize as much as you want and not
    // have to worry about NotificationCenter details.
    func handleNotification() {
        fatalError("ERROR: You must override the [handleNotification] method.")
    }
    
    // Be kind and stop tapping a resource (NotificationCenter)
    // when we don't need to anymore.
    deinit {
        print("Observer unsubscribing from notifications.")
        unsubscribe()
    }
    
} // end class Observer
 
// An example of an observer, usually one of several
// (many?) that are all listening for notifications
// from some usually single critical resource. Notice that
// it's brief and can serve as a model for creating
// handlers for all sorts of notifications.
class NetworkConnectionHandler: Observer {
    
    var view: UIView
    
    // As long as you call "super.init" with valid
    // NotificationCenter-compatible values, you can
    // create whatever type of initializer you want.
    init(view: UIView) {
        
        self.view = view
        
        super.init(statusKey: .networkStatusKey, notification: .networkConnection)
    }
    
    // YOU MUST OVERRIDE THIS METHOD, but that
    // gives you the chance to handle notifications
    // in whatever way you deem fit.
    override func handleNotification() {
        
        if statusValue == NetworkConnectionStatus.connected.rawValue {
            view.backgroundColor = UIColor.green
        }
        else {
            view.backgroundColor = UIColor.red
        }
        
    } // end func handleNotification()
    
} // end class NetworkConnectionHandler
 
// An template for a subject, usually a single
// critical resource, that broadcasts notifications
// about a change in its state to many
// subscribers that depend on that resource.
protocol ObservedProtocol {
    var statusKey: StatusKey { get }
    var notification: Notification.Name { get }
    func notifyObservers(about changeTo: String) -> Void
}
 
// When an adopter of this ObservedProtocol
// changes status, it notifies ALL subsribed
// observers. It BROADCASTS to ALL SUBSCRIBERS.
extension ObservedProtocol {
 
    func notifyObservers(about changeTo: String) -> Void {
       NotificationCenter.default.post(name: notification, object: self, userInfo: [statusKey.rawValue : changeTo])
    }
    
} // end extension ObservedProtocol
```

I had intended to put most of the observer’s notification handling logic into an extension of `ObserverProtocol` but ran into `@objc` when setting my `#selector`, then thought about using the block-based version of [`addObserver(forName:object:queue:using:)`](https://developer.apple.com/documentation/foundation/notificationcenter/1411723-addobserver), then passing in a notification handler closure, blah, blah, blah… I decided that my notification handling code would be much more intelligible and educational as an abstract class.

我把大部分关于观察者的通知处理逻辑放在了 `ObserverProtocol` 的扩展当中，并且这段逻辑会在一个 `@objc` 修饰的方法中运行（此方法同时会设置为通知的 `#selector` 的方法）。作为虚类中的方法，相较于使用基于 block 的 [`addObserver(forName:object:queue:using:)`](https://developer.apple.com/documentation/foundation/notificationcenter/1411723-addobserver) 并把处理通知的闭包传进去，使用 selector 可以让这段通知处理代码显得更加容易理解以及更加适合教学。

I also realize that Swift has no formal concept of an abstract class, but you probably already know there is a commonly used workaround for creating one. So, again, to simplify my didactic goal of explaining the observer pattern, I made the `Observer` class “abstract” by forcing you to override its `handleNotification()` method. By doing so, I gave you the opportunity to inject *any* type of specialized logic you want to have executed whenever your `Observer` subclass instance receives a notification.

同时，我意识到 Swift 中并没有关于虚类的官方概念。因此，为了完成我解释观察者模式的教学目的，我强制使用者重写 `Observer` 的 `handleNotification()` 方法，以此来达到 “虚类” 的形态。如此以来，你可以注入任意的处理逻辑，让你的子类实例在接收到通知后有特定的行为。

Shown immediately below is my sample project’s `ViewController.swift` file, which shows you how to make use of my core logic in `Observable.swift`, which we just discussed and reviewed:

下面我将展示示例项目中的 `ViewController.swift` 文件，在这里你可以看到刚刚讨论过的  `Obesever.swift` 中的核心代码是如何使用的：

```swift
import UIKit
 
// By adopting the ObservedProtocol, this view controller
// gains the capability for broadcasting notifications via
// NotificationCenter to ANY entities throughout this
// WHOLE APP whom are interested in receiving those notifications.
// Notice how little this class needs to do to gain
// notification capability?
class ViewController: UIViewController, ObservedProtocol {
    
    @IBOutlet weak var topBox: UIView!
    @IBOutlet weak var middleBox: UIView!
    @IBOutlet weak var bottomBox: UIView!
    
    // Mock up three entities whom are dependent upon a
    // critical resource: network connectivity. They need
    // to observe the status of the critical resource.
    var networkConnectionHandler0: NetworkConnectionHandler?
    var networkConnectionHandler1: NetworkConnectionHandler?
    var networkConnectionHandler2: NetworkConnectionHandler?
    
    // ObservedProtocol conformance -- two properties.
    let statusKey: StatusKey = StatusKey.networkStatusKey
    let notification: Notification.Name = .networkConnection
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Here are three entities now listening for notifications
        // from the enclosing ViewController class.
        networkConnectionHandler0 = NetworkConnectionHandler(view: topBox)
        networkConnectionHandler1 = NetworkConnectionHandler(view: middleBox)
        networkConnectionHandler2 = NetworkConnectionHandler(view: bottomBox)
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Mock up a critical resource whose state can change.
    // I'm pretending that this ViewController is
    // responsible for network reachability/connectivity.
    // When we have a network connection, all interested
    // listeners are informed. When network access is lost,
    // all interested listeners are informed.
    @IBAction func switchChanged(_ sender: Any) {
        
        let swtich:UISwitch = sender as! UISwitch
        
        if swtich.isOn {
            notifyObservers(about: NetworkConnectionStatus.connected.rawValue)
        }
        else {
            notifyObservers(about: NetworkConnectionStatus.disconnected.rawValue)
        }
        
    } // end func switchChanged
    
} // end class ViewController
```

## The *memento* design pattern

## 备忘录模式

Most iOS developers are familiar with the memento pattern. Think of iOS facilities for [archives and serialization](https://developer.apple.com/documentation/foundation/archives_and_serialization) which allow you to “Convert objects and values to and from property list, JSON, and other flat binary representations.” Think of the iOS [state preservation and restoration](https://developer.apple.com/documentation/uikit/view_controllers/preserving_your_app_s_ui_across_launches)feature, which remembers and then returns “your app to its previous state after it is terminated by the system.”

大部分 iOS 开发者对备忘录模式都很熟悉。回忆一下 iOS 中十分便利的[归档和序列化功能](https://developer.apple.com/documentation/foundation/archives_and_serialization)，让你能够 “在对象和 plist、JSON 或者其他二进制形式的值之间相互转换”。再回忆一下 iOS 中的[状态保存和恢复功能](https://developer.apple.com/documentation/uikit/view_controllers/preserving_your_app_s_ui_across_launches)，它能够记住你的应用被系统强制杀死时的状态，并在之后恢复此状态。

The memento design pattern is meant to capture, represent, and store the internal state of an instance at a specific point in time and then allow you to find that instance’s state representation at a later time and restore it. When you restore the state of an instance, it should exactly reflect it’s state at the time of capture. While this may sound obvious, you should ensure that all instance property access levels should be respected during capture and restoration, e.g., `public` data should be restored to `public` properties and `private` data should be restored to `private`properties.

备忘录模式可以理解为在某个时刻捕捉、展示以及储存任意实例的内部状态，同时允许你可以在随后的时间内查找这些保存下来的状态并恢复它。当你恢复一个实例的某个状态时，它应当完全反映出这个实例在被捕捉时的状态。显然，要达到此效果，你必须保证所有实例属性的访问权限在捕捉和恢复时都是一样的 —— 例如，`public` 的数据应恢复为 `public` 的属性，`private`  的数据应恢复为`private` 的属性。

To keep things simple, I used iOS’s [`UserDefaults`](https://developer.apple.com/documentation/foundation/userdefaults) as the core of my instance state storage and recovery process.

为了简单起见，我使用 iOS 系统提供的 `UserDefaults` 作为我存储和恢复实例状态的核心工具。

### Use case for memento design pattern app

### 备忘录模式用例

While I understand that iOS already has facilities for archiving and serialization, I developed sample code that can save and recover an class’s state. My code does a pretty good job of abstracting archiving and de-archiving so that you can store and recover the state of a variety of different instances with varying properties. But my example is not meant for production use. It is a didactic example formulated to explain the memento pattern.

在我知道了 iOS 本身已提供了便捷的归档和序列化的功能后，我随即编写了一些可以保存和恢复类的状态的示例代码。我的代码很出色地抽象出了归档和解档的功能，因此你可以利用这些抽象方法存储和恢复许多不同的实例和实例的属性。不过我的示例代码并非用于生产环境下的，它们只是为了解释备忘录模式而编写的教学性代码。

My memento example project, available on [GitHub](https://github.com/appcoda/Memento-Pattern-Swift), showcases how a `User` class instance’s state, with `firstName`, `lastName`, and `age` properties, can be persisted to `UserDefaults` and then later recovered. At first, no `User` instance is available to recover, but then I enter one, archive it, and then recover it, as shown here:

你可以在 Github 上找到我的[示例项目](https://github.com/appcoda/Memento-Pattern-Swift)。这个项目展示了一个包含`firstName`、`lastName`  和 `age` 属性的 `User` 类实例保存在 `UserDefaults` 中，并随后从 `UserDefaults` 恢复的过程。如同下面的效果一样，一开始，并没有任何 `User` 实例提供给我进行恢复，随后我输入了一个并把它归档，然后再恢复它：

![MementoDemoApp](https://www.appcoda.com/wp-content/uploads/2018/08/MementoDemoApp.gif)

Here’s the console output corresponding to the previous video:

上面过程中控制台输出如下：

```
Empty entity.
 
lastName: Adams
age: 87
firstName: John
 
lastName: Adams
age: 87
firstName: John
```

### Sample code for memento design pattern app

### 备忘录模式示例代码

My memento code is straightforward. It provides the `Memento` protocol and protocol extension for handling and abstracting all the details of gross archiving and de-archiving of the member properties of classes that adopt the `Memento` protocol. The extension also allows you to print the entire state of an instance to console at any given point in time. I used a `Dictionary<String, String>` to store an adopting class’s property names as keys and property contents as values. I stored values as `String` to keep my implementation simple and easily understood, fully well acknowledging that there are many use cases which would require you to archive and de-archive much more complex property types. This is a tutorial about *design patterns*, not a code base for a production app.

我所实现的备忘录模式非常直白。代码中包含了一个 `Memento` 协议，以及 `Memento` 协议的扩展，用于在成员属性中存在遵循 `Memento` 协议的属性时，处理和抽象关于归档与解档的逻辑。与此同时，这个协议扩展允许在任何时候打印实例的所有状态。我使用了一个 `Dictionary<String, String>` 来存储那些遵循协议的类中的属性 —— 属性名作为字典的 Key，属性值作为字典的 Value。我把属性的值以字符串的类型存储，以此达到代码较简洁且容易理解的目的，但我必须承认实际情况中有许多用例会要求你去操作非常复杂的属性类型。归根到底，这是一个关于设计模式的教程，因此没有任何代码是基于生产环境来编写的。

Notice that I added `persist()` and `recover()` methods to the `Memento` protocol, which *must*be implemented by any class that adopts the `Memento` protocol. These methods provide developers with the opportunity to archive and de-archive `Memento` protocol-adopting class’s *specific* properties, *by name*. In other words, the elements of the `state` property of type `Dictionary<String, String>` can be matched one-to-one with the `Memento` protocol-adopting class’s properties. Each property name corresponds to a dictionary element key and each property value corresponds to the dictionary element’s value which matches said key. Just look at the code and you’ll understand.

需要注意我为 `Memento` 协议加了一个 `persist()` 方法和一个 `recover()` 方法，任何遵循此协议的类都必须实现它们。这两个方法让开发者可以根据实际需要，通过名字来归档和解档某个遵循 `Memento` 协议的类中的特定属性。换句话说，`Memento` 中类型为 `Dictionary<String, String>` 的 `state` 属性可以一对一地对应到某个遵循此协议的类中的属性，这些属性的名称对应字典中元素的 key，属性的值对应字典中元素的 value。相信你在看完具体的代码后肯定能完全理解。

Since the `persist()` and `recover()` methods *must* be implemented by any class that adopts the `Memento` protocol, properties of all access levels, e.g., `public`, `private`, and `fileprivate` are visible to, and accessible by, these methods.

由于遵循 `Memento` 协议的类必须实现  `persist()` 和 `recover()` 方法，因此这两个方法必须可以访问所有可见的属性，无论它具有什么样的访问权限 ——  `public` 、`private`  还是  `fileprivate`。

You may wonder why I made the `Memento` protocol class-only. I did so because of that horrible Swift compiler message, “Cannot use mutating member on immutable value: ‘self’ is immutable.” Discussing it is way beyond the scope of this tutorial, but if you’d like to torture yourself, read a great description of the issue [here](https://www.bignerdranch.com/blog/protocol-oriented-problems-and-the-immutable-self-error/).

你或许也想知道我为什么把 `Memento` 协议设置为类协议（class-only）。原因仅仅是因为 Swift 编译器那诡异的报错："Cannot use mutating member on immutable value: ‘self’ is immutable"。我们暂且不讨论这个问题，因为它远远超出了本次教程的范围。如果你对这个问题感兴趣，你可以看一下这个[不错的解释](https://www.bignerdranch.com/blog/protocol-oriented-problems-and-the-immutable-self-error/)。

Here’s my core logic for implementing the memento design pattern, found in file `Memento.swift` of my sample app:

接下来就到了代码的部分。首先，你可以在我示例项目中的 `Memento.swift` 文件找到关于备忘录模式的核心实现：

```swift
import Foundation
 
// I've only limited this protocol to reference types because of the
// "Cannot use mutating member on immutable value: ‘self’ is immutable"
// conundrum.
protocol Memento : class {
    
    // Key for accessing the "state" property
    // from UserDefaults.
    var stateName: String { get }
    
    // Current state of adopting class -- all
    // property names (keys) and property values.
    var state: Dictionary<String, String> { get set }
    
    // Save "state" property with key as specified
    // in "stateName" into UserDefaults ("generic" save).
    func save()
    
    // Retrieve "state" property using key as specified
    // in "stateName" from UserDefaults ("generic" restore).
    func restore()
    
    // Customized, "specific" save of "state" dictionary with
    // keys corresponding to member properties of adopting
    // class, and save of each property value (class-specific).
    func persist()
    
    // Customized, "specific" retrieval of "state" dictionary using
    // keys corresponding to member properties of adopting
    // class, and retrieval of each property value  (class-specific).
    func recover()
    
    // Print all adopting class's member properties by
    // traversing "state" dictionary, so output is of
    // format:
    //
    // Property 1 name (key): property 1 value
    // Property 2 name (key): property 2 value ...
    func show()
    
} // end protocol Memento
 
extension Memento {
    
    // Save state into dictionary archived on disk.
    func save() {
        UserDefaults.standard.set(state, forKey: stateName)
    }
    
    // Read state into dictionary archived on disk.
    func restore() {
        
        if let dictionary = UserDefaults.standard.object(forKey: stateName) as! Dictionary<String, String>? {
            state = dictionary
        }
        else {
            state.removeAll()
        }
        
    } // end func restore()
    
    // Storing state in dictionary makes display
    // of object state so easy and intuitive.
    func show() {
        
        var line = ""
        
        if state.count > 0 {
            
            for (key, value) in state {
                line += key + ": " + value + "\n"
            }
            
            print(line)
            
        }
        
        else {
            print("Empty entity.\n")
        }
            
    } // end func show()
    
} // end extension Memento
 
// By adopting the Memento protocol, we can, with relative
// ease, save the state of an entire class to persistant
// storage and then retrieve that state at a later time, i.e.,
// across different instances of this app running.
class User: Memento {
    
    // These two properties are required by Memento.
    let stateName: String
    var state: Dictionary<String, String>
    
    // These properties are specific to a class that
    // represents some kind of system user account.
    var firstName: String
    var lastName: String
    var age: String
    
    // Initializer for persisting a new user to disk, or for
    // updating an existing user. The key value used for accessing
    // persistent storage is property "stateName."
    init(firstName: String, lastName: String, age: String, stateName: String) {
        
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        
        self.stateName = stateName
        self.state = Dictionary<String, String>()
        
        persist()
        
    } // end init(firstName...
    
    // Initializer for retrieving a user from disk, if one
    // exists. The key value used for retrieving state from
    // persistent storage is property "stateName."
    init(stateName: String) {
        
        self.stateName = stateName
        self.state = Dictionary<String, String>()
        
        self.firstName = ""
        self.lastName = ""
        self.age = ""
        
        recover()
        
    } // end init(stateName...
 
    // Save the user's properties to persistent storage.
    // We intuitively save each property value by making
    // the keys in the dictionary correspond one-to-one with
    // this class's property names.
    func persist() {
        
        state["firstName"] = firstName
        state["lastName"] = lastName
        state["age"] = age
        
        save() // leverage protocol extension
        
    } // end func persist()
    
    // Read existing user's properties from persistent storage.
    // After retrieving the "state" dictionary from UserDefaults,
    // we easily restore each property value because
    // the keys in the dictionary correspond one-to-one with
    // this class's property names.
    func recover() {
        
        restore() // leverage protocol extension
            
        if state.count > 0 {
            firstName = state["firstName"]!
            lastName = state["lastName"]!
            age = state["age"]!
        }
        else {
            self.firstName = ""
            self.lastName = ""
            self.age = ""
        }
        
    } // end func recover
    
} // end class User
```

Here’s the code for implementing the memento design pattern use case I described earlier (archiving and de-archiving an instance of class `User`), as found in my sample app as file `ViewController.swift`:

接下来，你可以在示例项目中的 `ViewController.swift`  文件中找到我上问所说的关于备忘录模式的使用用例（对 `User` 类的归档和解档）：

```swift
import UIKit
 
class ViewController: UIViewController {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
    // Called when "Save User" button is tapped. Stores
    // "User" class instance properties to UserDefaults
    // based on stateName property value of "userKey" (but
    // use whatever lights your fire).
    @IBAction func saveUserTapped(_ sender: Any) {
        
        if firstNameTextField.text != "" &&
            lastNameTextField.text != "" &&
            ageTextField.text != "" {
            
            let user = User(firstName: firstNameTextField.text!,
                            lastName: lastNameTextField.text!,
                            age: ageTextField.text!,
                            stateName: "userKey")
            user.show()
            
        }
        
    } // end func saveUserTapped
    
    // Called when "Restore User" button is tapped. Retrieves
    // "User" class instance properties from UserDefaults
    // based on stateName property value of "userKey," if
    // a key/value pair with key "userKey" exists.
    @IBAction func restoreUserTapped(_ sender: Any) {
        
        let user = User(stateName: "userKey")
        firstNameTextField.text = user.firstName
        lastNameTextField.text = user.lastName
        ageTextField.text = user.age
        user.show()
 
    }
    
} // end class ViewController
```

## Conclusion

## 结论

Some critics have claimed that use of design patterns is proof of deficiencies in programming languages and that seeing recurring patterns in code is a bad thing. I disagree. Expecting a language to have a feature for *everything* is silly and would most likely lead to enormous languages like C++ into becoming even larger and more complex and thus harder to learn, use, and maintain. Recognizing and solving recurring problems is a positive human trait worthy of positive reinforcement. Design patterns are successful examples of learning from history, something humankind has failed to do too many times. Coming up with abstract and standardized solutions to common problems makes those solutions portable and more likely to be distributed.

即便 GoF 的设计模式已经在多数开发者心中被视为圣经般的存在（我在文章开头提到的），但仍有某些对设计模式持有批评意见的人认为，设计模式的使用恰恰是我们对编程语言不够了解或使用不够巧妙的证明，而且在代码中频繁使用设计模式并不是一件好事。我个人并不认同此看法。对于一些拥有几乎所有能想象得到的特性的语言，例如 C++ 这种非常庞大的编程语言来说，这种意见或许会适用，但诸如此类的语言通常极其复杂以致于我们很难去学习、使用并掌握它。能够识别出并解决一些重复出现的问题是我们作为人类的优点之一，我们并不应该抗拒它。而设计模式恰巧是人类从历史错误中吸取教训，并加以改进的绝佳例子。同时，设计模式对一些通用的问题给出了抽象化且标准化的解决方案，提高了解决这些问题的可能性和可部署性。

A combination of a compact language like Swift and an arsenal of best practices, like design patterns, is an ideal and happy medium. Consistent code is generally readable and maintainable code. Remember too that design patterns are ever-evolving as millions of developers are constantly discussing and sharing ideas. By virtue of being linked together over the World Wide Web, this developer discussion has lead to constantly self-regulating collective intelligence.

把一门简洁的编程语言和一系列最佳实践结合起来是一件美妙的事情，例如 Swift 和设计模式的结合。高一致性的代码通常也有高可读性和高可维护性。同时你要记得一件事，设计模式是通过成千上万的开发者们不断地讨论和交流想法而持续完善的。通过万维网带来的便捷性，开发者们在虚拟世界相互连接，他们的讨论不断碰撞出天才的火花。