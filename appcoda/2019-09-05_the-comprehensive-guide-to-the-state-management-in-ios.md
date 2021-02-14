title: "iOS 状态管理的全面指导"
date: 
tags: [Reswift,Redux,iOS,Swift,开发,单向,数据,流,Flux]
categories: [iOS 编程,MVC,MVVM,状态管理,Swift]
permalink: state-management-ios
keywords: iOS 状态管理,数据流动
custom_title: iOS 状态管理
description: 处理程序状态时的常见问题和解决这些问题的方法。ReSwift — iOS 版 REDUX。

---
原文链接=https://www.appcoda.com/state-management-ios/
作者=Alexey Naumov
原文日期=2019-09-05
译者=ericchuhong
校对=
定稿=

<!--此处开始正文-->

在软件的开发过程中会有许多挑战，但是相比较之下有一个最让人抓狂的大难题是：应用的状态管理和数据传输问题。

![state](https://nalexn.github.io/assets/img/state_001.jpg)

应用中的 [状态](https://en.wikipedia.org/wiki/State_(computer_science)) 不过是一个平时用来读写的数据，能有什么问题呢？

<!--more-->

### 处理状态时常见的问题

1. **[竞态条件](https://searchstorage.techtarget.com/definition/race-condition)** - 在并发环境中非同步访问数据。导致许多难以查找的 bug，例如在竞争后非预期或者错误的计算结果、数据错误甚至应用奔溃。
2. **[非预期的副作用](https://en.wikipedia.org/wiki/Side_effect_(computer_science))**。当程序中多个实体通过持有一个状态值的引用来共享状态时，其中一个实体对状态做的修改可能会给其他实体带来非预期的影响。这样通常是因为数据访问不受限制导致的。造成的后果千差万别，从 UI 显示问题，到 [死锁](https://en.wikipedia.org/wiki/Deadlock)，甚至是崩溃。
3. **[值共生性](https://en.wikipedia.org/wiki/Connascence#Connascence_of_Values_(CoV))**。程序中，当多个实体通过存储自己对状态的拷贝来共享状态时，对拷贝进行修改不会自动的应用到其他拷贝。当任意一份拷贝更新时，就需要额外的代码来更新其他拷贝。由于无法正确地同步这些状态的拷贝，当用户或者系统跟这些数据交互时，通常会导致应用把后续带有错误的状态数据展示给用户。
4. **[类型共生性](https://en.wikipedia.org/wiki/Connascence#Connascence_of_Type_(CoT))** 在 [动态类型](https://stackoverflow.com/questions/1517582/what-is-the-difference-between-statically-typed-and-dynamically-typed-languages) 语言中，指的是一个变量在它的生命周期过程中，值和类型都被改变了。尽管这项技术有些 [实际用处](https://softwareengineering.stackexchange.com/questions/115520/should-i-reuse-variables)，但通常被当作一种 [错误的做法](https://softwareengineering.stackexchange.com/questions/187332/is-changing-the-type-of-a-variable-partway-through-a-procedure-in-a-dynamically)。它会让算法变得难以读懂，也让我们在维护这样的代码时更容易造成人为的错误。即使经验丰富的程序员在修改类型的时候，也有可能在无意中赋值了错误的变量。这样的错误造成的结果因语言而异，但你说能有什么好事发生。
5. **[约定共生性](https://en.wikipedia.org/wiki/Connascence#Connascence_of_Meaning_(CoM)_or_Connascence_of_Convention_(CoC))**。如果对值的含义有误解时，就会不小心用另一个有相同类型的参数替换掉这个值。例如，如果我们有两个声明为 `String` 类型的 `UserID` 和 `BlogID`，就可能误把 `UserID` 传给需要 `BlogID` 的函数。错误的值可能会被服务器调用，或者被存在本地应用的状态里，无论哪一种 — 都是错误的情况。有一种解决办法就是使用 `struct` 封装原有的值，这样可以让编译器区分开这些类型，并且在类型不匹配的时候发出警告。
6. **[内存泄漏](https://en.wikipedia.org/wiki/Memory_leak)**。像程序中其他的资源一样，如果处理不当，状态会驻留在内存中，即便它不再被访问。太多的内存泄漏（例如分配了上百兆内存的图片）最终会导致大量可用内存的减少，以及后续的奔溃。当状态对象内存泄漏时，我们可能最多失去几 KB 的内存，但谁知道我们的程序会泄漏 _多少次_ 呢？最终的后果就是性能变得更低还有崩溃。
7. **[有限的可测试性](https://en.wikipedia.org/wiki/Software_testing)**。状态对象在 [单元测试](https://en.wikipedia.org/wiki/Unit_testing) 中扮演着一个重要的角色。通过共享状态的值或者引用其他的实体对像造成 [耦合](https://en.wikipedia.org/wiki/Coupling_(computer_programming))，导致他们在各自的处理逻辑中相互依赖。在程序中不当的状态管理设计，会让测试变得更加低效，甚至无法为设计糟糕的模块编写测试代码。

---
当引入一个新的状态时，开发者总要面对两个问题：_“状态数据存在哪里？”_ 和 _“状态更新时如何通知应用中的其他实体？”_。让我们详细地分析一下每个问题，看看是否存在解决这些问题的银弹。

## 1. 状态数据存在哪里？

我们可以在方法中访问本地变量，或者在类中访问实例变量，或者在任何地方访问全局变量 — 它们的主要区别是在程序中可以读或写的范围不同。

当我们决定在 _哪里_ 来存储新的值时，我们需要考虑状态的主要特征 - 它所存放的位置，或者说是可访问范围。

有一个通用的规则是 __尽可能地缩小可访问范围__。在方法中定义一个本地变量比一个全局变量更好，不仅为了避免我们一下子没注意，就在其他的区域将状态数据改成了意料之外的其他值，也为了给其他使用到相关数据的模块增加可测试性。

当前界面的状态，是不跟其他界面共享的，可以被模块自身安全的存储下来。这只取决于你在模块中用的  [架构](https://medium.com/ios-os-x-development/ios-architecture-patterns-ecba4c38de52)。例如在 [Model-View-Controller](https://ru.wikipedia.org/wiki/Model-View-Controller) 的架构中，存储状态的地方就是 `ViewController`，对于 [Model-View-ViewModel](https://en.wikipedia.org/wiki/Model-view-viewmodel) 架构则是在 `Model` 中。

当我们想要在多个模块之间传输或者共享数据时，事情就变得复杂得多。主要有两个情形：

* 我们需要把一些状态的值传到后续的界面中并且监听它，当它完成工作时可能会返回一些数据回来。
* 我们有一个被整个 app 分享的状态对象。可以是被多个界面展示的数据，不像上一条中那种父级子级的形式。这个数据可以被读取或者修改，而且每一方都应该优雅地处理这些修改。

在这篇文章，我会讨论这两种情况，接下来开始分析第一种。为了你不会迷茫，第二种情况将在下面的章节 __共享状态管理__ 中详细介绍，请继续阅读。

好，来说下在两个界面（父级子级）中的数据交互。为了能够实现两个模块之间 [解耦](https://en.wikipedia.org/wiki/Loose_coupling) 的目的，我们需要保证设计出来的数据传输方式中，没有因为暴露关于发送和接收数据双方不必要的细节，而导致引用了不必要的依赖。_他们越不清楚对方 - 越好。_

关于数据的跨界面传递，我们有相当标准的技巧 - [依赖注入](https://en.wikipedia.org/wiki/Dependency_injection) 值本身或者引用一个实体来读取数据。

反向地回传数据给回调方则显得有些棘手，我们可以自然地过渡到对第二个问题的解答上：

## 2. 状态更新时如何通知应用中的其他实体？

我之前的文章已经分析了这个问题可能的答案，在这些标准的方式中我们可以用：

* [代理](https://nalexn.github.io/callbacks-part-1-delegation-notificationcenter-kvo/#delegate)
* [NotificationCenter](https://nalexn.github.io/callbacks-part-1-delegation-notificationcenter-kvo/#NotificationCenter)
* [KVO](https://nalexn.github.io/callbacks-part-1-delegation-notificationcenter-kvo/#KeyValueObserving)
* [闭包](https://nalexn.github.io/callbacks-part-2-closure-target-action-responder-chain/#Closure_Block)
* [Target-Action](https://nalexn.github.io/callbacks-part-2-closure-target-action-responder-chain/#Target-Action)
* [响应者链](https://nalexn.github.io/callbacks-part-2-closure-target-action-responder-chain/#Responder_chain)

可以使用的方式有很多种，开发者可以单独使用其中的一种方法或者两两之间组合，更不用说可以自由地给使用到的方法和参数进行命名。

如果我们也要在文章中介绍 [Promise](https://nalexn.github.io/callbacks-part-3-promise-event-stream/#Promise)、 [Event](https://nalexn.github.io/callbacks-part-3-promise-event-stream/#Event) 或者 [数据流（Stream of values）](https://nalexn.github.io/callbacks-part-3-promise-event-stream/#Stream) 的话，有些读者（和他们的程序）可能会吃不消。

![john-travolta-01.gif](http://nalexn.github.io/assets/img/john-travolta-01.gif)

### 所以到底应该用哪一种方式来传递状态变化呢？

在过去的几年里，我总结了下当我选择数据传输方式时遵循的一些规则（你可能有不同的偏好）：

* **[代理](https://nalexn.github.io/callbacks-part-1-delegation-notificationcenter-kvo/#delegate)**。虽然这个技巧在 iOS 社区仍然很受欢迎，但我是 [闭包](https://medium.cobeisfresh.com/why-you-shouldn-t-use-delegates-in-swift-7ef808a7f16b) 的支持者，作为 `代理` 的替代品它显得更灵活、便利。它们的使用目的相同，但是使用 `闭包` 可以让我们写更少胶水代码的同时拥有更高的 [内聚性](https://en.wikipedia.org/wiki/Cohesion_(computer_science))。
* **[Target-Action](https://nalexn.github.io/callbacks-part-2-closure-target-action-responder-chain/#Target-Action)**。它和 `代理` 的受欢迎程度相似。我仍然会用它的唯一原因，就是当我声明了 `UIControl` 或 `UIGestureRecognizer` 子类的时候，因为它们本身就支持 `Target-Action`。
* **[闭包](https://nalexn.github.io/callbacks-part-2-closure-target-action-responder-chain/#Closure_Block)**。在两个模块之间做最简单的交互时，这是我的首选。只有在情况复杂起来时，例如后续的异步任务也带有 `闭包` 回调，或者当我需要通知的模块数量超过一个时 - 我会考虑 `Promise`，`Event` 或者 `数据流` 的方式。
* **[Promise](https://nalexn.github.io/callbacks-part-3-promise-event-stream/#Promise)** 是我最喜欢用来处理链式异步回调的工具，例如后端 API 的接口调用。使用 `数据流` 也可以处理这种情形，但 `Promise` 提供了更简洁的 API，适合那些想要极力避免采用 `Rx` 和其他响应式工具的工程师团队。
* **[Event](https://nalexn.github.io/callbacks-part-3-promise-event-stream/#Event)** 是观察者模式的一种既轻量又强大的实现，一个 `NotificationCenter` 和 `KVO` 了不起的替代品。不管你是要广播一个带或不带数据的通知 - 这个工具提供了一个种便捷的订阅方式，可以安全地执行逻辑并且也容易测试。它也能够用作被观察的属性 - 一个一直带有值的变量，并且对于任意数量的订阅者，它都提供了转换为 “KVO” 监听的方式。
* **[数据流](https://nalexn.github.io/callbacks-part-3-promise-event-stream/#Stream)**。这是一种可以被 `Promise` 和 `Event` 替换的通用工具，同时也提供 `UI 绑定` 和其他功能。不过要注意！我自己是 [函数响应式编程](https://en.wikipedia.org/wiki/Functional_reactive_programming) 的重度粉丝，但仍然没有多少人能 _完全_ 明白它的思想，并在实践中 _恰当_ 地使用这个工具。在一次大型技术交流会中，有一位团队经理偷偷地跟我说了他的担忧，他们不得不聘请有 _特长_ 的高级工程师，__只因为__ 他们的 app 完全是用 `RxSwift` 编写的，并且 __无法__ 被低水平的工程师维护（他们尝试聘请过的）。一个工具本意是想着让开发变得更容易，而实际上却是相反！在另一个采访中，是一个在俄罗斯排行前三的银行，他们在所有超过 10 个的产品团队中，他们严令禁止使用响应式编程，正也是因为相同的原因。
* **[NotificationCenter](https://nalexn.github.io/callbacks-part-1-delegation-notificationcenter-kvo/#NotificationCenter)**。在我的项目中，我使用了一个自定义的 [SwiftLint](https://github.com/realm/SwiftLint) 规则以 _避免_ `NotificationCenter` 被滥用。我相信这是在你的 app 中做数据传递 可以用的 [最有害的工具之一](https://davidnix.io/post/stop-using-nsnotificationcenter/)。不仅因为需要依赖使用  [单例](https://stackoverflow.com/questions/12755539/why-is-singleton-considered-an-anti-pattern)（会让单元测试变得更难），它也会导致数据流的不可控。*它是编程噩梦的前兆！* 只有当 Apple 没有提供可替代的 API，而我又需要监听一些来自 Apple 官方框架的通知时，我才仍会用它们。如果你需要一些观察者模式完好的实现 - 考虑使用 `Event` 或者 `数据流`。
* **[KVO](https://nalexn.github.io/callbacks-part-1-delegation-notificationcenter-kvo/#KeyValueObserving)**。一个非常强大的技术，当我需要对一个封闭的类进行监听，并且没有其他办法可以监听它的状态改变时，我会把它作为最后的手段。我们都应该感谢 `KVO` - 没有它（数据流）我们不会拥有 UIKit 的响应式扩展。当你需要监听一个属性时，`Event` 是一个更加实用的选择。
* **[响应者链](https://nalexn.github.io/callbacks-part-2-closure-target-action-responder-chain/#Responder_chain)**。由于它无法在通知中携带数据，这个技巧对于我们想做的事情显得十分有限。即使我们有一个对状态对象的引用，并且只需要触发它来刷新 UI，这个技巧也仍然是个糟糕的选择。它建立了一个隐式并且十分不稳定的通知通道，导致它很难被测试和维护。

## 共享状态管理

好，我们有一些数据需要被应用中多个模块访问。我们可以把它声明为全局变量或单例，然后一整天一直调用它吗？答案是可以的，如果我们是在参加一场几个小时的黑客马拉松，然后打算等它结束后就把这个项目丢掉的话……

今天的移动应用不得不处理日益增长的复杂业务需求，不仅涉及到功能丰富、与底层数据紧密绑定的响应式 UI，还有来自服务器、本地创建、缓存在内存中或者数据库中复杂的数据状态管理。

每个项目必须确定一种统一的存储数据策略，以及数据在系统中传递方式；要是无法提前确定好的话，难免会导致数据流、数据的一致性不受控制，也无法对应用的运行有个基本的理解。

既然我上面列出了关于状态的常见问题，那让我给一些关于如何在应用中实现状态共享的 _推荐做法_。

### 单一信息源

你需要作出一个选择，是把状态缓存在多个地方还是一个。在我看来，状态按照 [单一信息源](https://en.wikipedia.org/wiki/Single_source_of_truth) 的原则更加实用，因为你不需要担心数据过期 - 一旦你改变数据 - 旧的值就会消失，没办法从其地方蹦出来毁掉你的用户体验。

假如我们正在开发一个简单的 TODO 列表应用。我们把列表数据存在本地数据库和后端服务器上。当应用启动时，我们展示了本地的拷贝数据，同时向服务器请求一份可能被其他设备更新过的列表数据。

如果我们不太关心用户的体验，我们可以冻结住 UI 直到请求完成，但如果我们继续运行，允许用户在请求过程中勾选-反选列表中的任务，并且用任一种其它的方式修改它。

用户对本地拷贝数据的编辑，和延迟完成的网络请求产生的竞态条件，会导致我们在有冲突的时候，需要强制实现合并编辑文档的逻辑。

为此我们可以引用一个本地数据库的封装器，并且当它更新了最新任务列表的时候，依赖它并将它作为单一信息源。通过这种方法我们可以避免程序中不必要的麻烦。

一旦你统一了存放状态的地方，要进行扩展或者因项目发展而需重构就变得容易许多：如果我们后面决定给任务添加一个单独的编辑界面，在那个界面中我们可以安全地从封装器中读取数据，并且不管谁在什么时候更新了它，都需要保证它总能提供最新的数据。

### 约束对状态进行的修改

你需要设一个拦截器，避免外层的代码在改完状态后就撇下不管。要是有其他模块需要知道状态已经被修改了呢？通知其他模块的责任应该落在调用的一方，因为我们很容易忘记在每个数据变动的地方加上通知的相关代码。

另一方面，如果我们为修改数据的操作引用一个封装器，那我们之后可以从封装器中发送通知，同时如果有需要的话，也可以执行其他的一些操作。

在 TODO 列表的示例中，封装器可以做为外观层（facade），同时隐藏本地数据库和后端的调用，留给客户端代码一个整洁的 API，不会暴露出数据的来源，并且给数据修改提供一个简单的方式。

### 单向数据流

这是另一种你可以在应用中实行的约束，它会极大地改进整个系统的清晰度和稳定性。

假设你并没有将后端 API 请求交由外观层处理，而是直接在主 `ViewController` 中发起网络请求。

在这种情况，我们会有两个数据的来源 - 第一个仍然是来自使用中的外观层，另一个是网络请求完成后的回调，而且我们不得不分别为两种情况更新 UI。

以前我做过一个 app，里面通常的做法是每有一个数据修改就通过 `NotificationCenter` 发送一条 `Notification`。它有一个通知专门负责单条记录的更新，和另一个通知负责整个列表的数据更新。当然，网络的回调也是会返回一份列表数据或单个数据 - UI 需要处理来自 4 个地方的数据！你能想象到要如何给这样的框架编写测试？

在应用中，数据流会快速增多，需要开发人员为更新已有功能一致努力，随着应用迭代，存放数据的地方在数量上会呈指数级增长。

[单向数据流](https://flaviocopes.com/react-unidirectional-data-flow/) 的这种方法允许我们构建一个统一的通道，用以处理单次数据更新，而随着我们项目不断发展，会让我们逐渐忘记它的存在。

所有这些做法都大大有助于遵循 [最小惊讶原则](https://en.wikipedia.org/wiki/Principle_of_least_astonishment)，让项目中的每个人都能更容易地快速定位到状态的数据、所有状态可能被修改的情况和数据分布的通道。

有许多方法可以一次性遵循三种模式。其中一个是 [Redux](https://github.com/reduxjs/redux) 库，始源于 JavaScript 语言，之后促进 iOS 社区创建了它们自己的：[ReSwift](https://github.com/ReSwift/ReSwift)。

如果你用这三个理念设计自己的共享状态管理，并且决定在项目使用 `数据流` 的方式，你可以轻易地 [绑定 UI 和状态](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Examples.md#simple-ui-bindings)，并编写清晰的声明式编码更新 UI，让整个应用很好地响应任意状态变化。

### 获取共享状态的引用

我不推荐创建一个全局的访问方式（单例对象或者全局变量），不管是 ReSwift 的状态还是别的什么方式。许多实际用的方法会证实，在使用状态分享的模块中，最好的解耦和隔离方式是之前提到的 [依赖注入](https://en.wikipedia.org/wiki/Dependency_injection)。为此，你可以利用 DI 库像是 [typhoon](https://github.com/appsquickly/typhoon) 或者在创建了新模块的实体中，通过直接赋值引用注入实例。对于后面一种，就像在 `AppDelegate` 中给 `RootViewController` 赋值依赖，或者在一些 `Builder` 或者 `Router` 中，创建新 `ViewController` 之后注入依赖。

---
> “任何事情都应该做到最简单，而不仅仅是相对的简单。” —— 阿尔伯特·爱因斯坦

从某些方面来说，开发者都应该把写出简洁的代码作为目标，但不该因此投机取巧，其中有一种情况就是他们忽视了为应用设计一个稳定的状态管理方案。

> 编者记：这篇文章来源于 [Alexey 的 GitHub](https://nalexn.github.io/state-management-guide-ios/)。