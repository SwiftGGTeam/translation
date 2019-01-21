title: "PhotoKit 的数据模型"
date: 2018-09-28
tags: [iOS 开发]
categories: [PhotoKit, Ole Begemann]
permalink: photos-data-model
keywords: PhotoKit
custom_title: PhotoKit 的数据模型
description: PhotoKit 的数据模型

---
原文链接=https://oleb.net/2018/photos-data-model/
作者=Ole Begemann
原文日期=2018-09-28
译者=张弛
校对=待定
定稿=待定

<!--此处开始正文-->

Apple 的 [Photo.framework](https://developer.apple.com/documentation/photokit) 为 iOS Photos 应用程序提供支持，并允许开发人员访问设备的照片库，其使用的是 [Core Data](https://developer.apple.com/documentation/coredata)。

你可以在至少两个地方确认这点：

1. 编写一个访问照片库并使用以下命令行参数启动这个应用程序：[`-com.apple.CoreData.SQLDebug 1.`](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/TroubleshootingCoreData.html#//apple_ref/doc/uid/TP40001075-CH26-SW21)当你访问照片库时，你将看到 Core Data 将调试信息记录到控制台。
2. 如果查看 Photos 框架的 [class dump](http://stevenygard.com/projects/class-dump/)，你将在主类中看到对 [`NSManagedObjectID`](https://developer.apple.com/documentation/coredata/nsmanagedobjectid) 和其他 Core Data 类型的引用，例如 [`PHObject` 有一个 `_objectID：NSManagedObjectID` ivar](https://github.com/nst/iOS-Runtime-Headers/blob/fbb634c78269b0169efdead80955ba64eaaa2f21/Frameworks/Photos.framework/PHObject.h)。

###寻找 PhotoKit 的核心数据模型

为了更好地理解 Photos 框架（特别是它的性能特征），我检查了它的数据模型。我在 Xcode 10.0 应用程序包的内容中找到了一个名为 `PhotoLibraryServices.framework / photos.momd / photos-10.0.mom` 的文件：

> 你可以使用此终端命令查找与 Xcode 捆绑在一起的模拟器运行时内的其他 Core Data 模型：

> 找到 /Applications/Xcode-10.app -name '*.mom'

> /Applications/Xcode-10.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks/PhotoLibraryServices.framework/photos.momd/photos-10.0.mom

###在 Xcode 中打开已编译的 Core Data 模型

`.mom` 文件是*已编译的*核心数据模型。Xcode 无法直接打开它，但可以将它*导入*到另一个 Core Data 模型。按照以下步骤在 Xcode 中查看模型：

1. 创建一个新的空项目。Xcode 10 不喜欢在项目之外显示 Core Data 模型包。
2. 在项目中创建一个新的空“核心数据数据模型”文件。 这将创建一个 `.xcdatamodeld` 包。
3. 打开新数据模型，然后选择编辑器>导入.... 选择要导入的 `.mom` 文件。

不幸的是，编译的模型不存储 Xcode 的图形模型编辑器的布局信息，因此你必须手动将实体拖动到令人愉悦的布局中。这花了我几个小时。

> 温馨提示：你可以使用箭头键（和 shift 键+箭头键）精确定位事物。专家提示：请勿点击 ⌘Z 撤消移动操作。图形编辑不会注册为可撤销操作，因此 Xcode 可能会撤消初始导入，这意味着你将丢失所有未保存的工作。

###格式化的照片模型

这是与 Xcode 10.0（iOS 12.0）捆绑在一起的 `photos-10.0.mom`：

![](https://oleb.net/media/photos-10.0-core-data-model-5974px.png)
iOS 12.0 中 PhotoLibraryServices.framework 的核心数据数据模型。请下载图片并在本地打开以获得最佳效果。

并非所有内容都能在此图片中看到。[下载完整模型](https://github.com/ole/AppleCoreDataModels)并在 Xcode 中打开它以检查属性属性等。
请注意，这不一定是 iOS 上照片的整个数据模型。 `PrivateFrameworks/PhotoAnalysis.framework` 中有更多 Core Data 模型，但我忽略了它们。