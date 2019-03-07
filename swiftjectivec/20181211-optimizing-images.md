title: "优化图像"
date: 
tags: [Swift，iOS 开发]
categories: [Swift]
permalink: optimizing-images
keywords: swift, image

------

原文链接=https://www.swiftjectivec.com/optimizing-images/
作者=Jordan Morgan
原文日期=2018-12-11
译者=Nemocdz
校对=
定稿=

<!--此处开始正文-->

他们说最棒的相机是你拥有的那个。如果这句俗话是有道理的，那么毫无疑问 - iPhone 一直是这个星球最重要的的相机。并且在我们业界这也已经达成共识了。

在度假？不偷偷拍几张记录在你的 Instagram 故事里，不存在的。

出现爆炸新闻？查看 Twitter，发现揭露事件实时的照片，就可以知道哪些媒体正在报道。

等等...

不过正因为它们（图像）在平台上无处不在，以高性能和节省内存的方式来展示是一门艺术，会容易做无用的努力。稍微了解 UIKit 中发生的事情，以及关于它如何处理图像，可以节省大量时间，并停下对无用功持续的迁怒。

<!--more-->

### 理论知识

一个热门的小测试 - 我漂亮女儿这张 266KB 的（并且还有点时髦）照片将需要多少内存在一个 iOS App 中？

![](https://www.swiftjectivec.com/assets/images/baylor.jpg)

剧透提醒 - 答案不是 266KB，也不是 2.66MB，而是接近 14MB。

为啥呢？

iOS 本质上是从一幅图像的*尺寸*推断出它占用的内存 - 但实际的文件大小会比这小很多。 而这张照片的尺寸是 1718 像素宽和 2048 像素高。假设每个像素会消耗我们 4 个比特：

```
1718*2048*4/1000000 = 14.07 MB 占用
```

想象一下如果你提供了一个用户列表的 table view，并且每一行在左边用现在普遍的圆角的头像展示他们的照片。如果你认为这些头像像洁食（犹太人的食品，比喻事情完美无瑕）一样，每个都会经过 ImageOptim（图像压缩优化）或类似的技术处理得完美又紧凑的话，那可就大错特错了。如果每个头像保守估计 256x256 大小的话，还是会占用相当一部分内存。

### 渲染管道

上面的一切说明 - 了解背后正在发生什么是值得的。当你读取一副图像时，它会进行以下三个步骤：

1）**加载** - iOS 获取压缩的图像并加载（在我们这个例子中）266KB 到内存里。实际上还没到担心的时候。

2）**解码** - 现在，iOS 获取图像并转换到 GPU 能读取和理解的方式。现在它是解压后的，这里就会像上面提到那样占用 14MB 了。

3）**渲染** - 就像听起来那样，图像数据已经准备好并将以任意方式渲染。即使只是一个 60x60pt 的 image view。

解码阶段是占有最大的。在这个步骤，iOS 会创建一块缓冲区 - 具体来说是一块图像缓冲区，也就是图像在内存中的表示。因此，这个大小本质上和图像面积有关，而不是文件大小。这清楚地描绘了为什么在图像消耗内存时尺寸是如此重要。

针对 UIImage 的特别说明，当我们给它从网络或者其它来源接收到的图像数据时，它会解码那个数据到缓冲区，无论数据是用什么编码方式（想想 PNG 或者 JPG）压缩的。然而，实际上它也会挂载在它（UIImage）上面。由于渲染不是一个一瞬间的操作，UIImage 会一直保留图像缓冲区，所以它只会解码一次。

延伸一下这个想法 - 任何 iOS app 的一快完整缓冲区是它的帧缓冲区。这展示了你的 iOS app 从它持有它内容的渲染输出，直到到显示在屏幕上的这个过程的职责。iOS 设备上负责显示的硬件会使用这里每个像素的的信息来逐个点亮物理屏幕上恰当的像素点。

这里就有耗时问题了。为了达到黄油般顺滑的每秒 60 帧滑动，帧缓冲区需要让 UIKit 渲染 app 的 window 以及它里面后续的子视图，每当它们的信息发生变化的时候（比如：给一个 image view 赋值一幅图像）。如果这里慢了，就会丢帧。

> *觉得 1/60 秒是一个很短的时间？Pro Motion 设备将上限拉到了 1/120 秒。*

### 尺寸正是问题所在

我们可以简单优雅地将这个过程和内存的消耗可视化。我创建了一个简单的 app 可以展示需要的图像在一个 image view 上，这里用我女儿的照片：

```swift
let filePath = Bundle.main.path(forResource:"baylor", ofType: "jpg")!
let url = NSURL(fileURLWithPath: filePath)
let fileImage = UIImage(contentsOfFile: filePath)

// Image view
let imageView = UIImageView(image: fileImage)
imageView.translatesAutoresizingMaskIntoConstraints = false
imageView.contentMode = .scaleAspectFit
imageView.widthAnchor.constraint(equalToConstant: 300).isActive = true
imageView.heightAnchor.constraint(equalToConstant: 400).isActive = true

view.addSubview(imageView)
imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
```

> *注意在实际开发的隐藏的威力。这里我们只是用了一个简单的示例场景。*

完成之后就会是这个样子：

![](https://www.swiftjectivec.com/assets/images/baylorPhone.jpg)

快速使用一下 LLDB 就可以知道我们使用的图像的尺寸了，即便使用了更小的 image view 来展示。

```
<UIImage: 0x600003d41a40>, {1718, 2048}
```

一个需要注意的点 - 这里的单位是*点*。所以当我在 3x 或 2x 设备时，还需要额外乘上这个数字。让我们快速使用 vmmap 看下能否确认这张图像将会占用 14 MB：

```shell
vmmap --summary baylor.memgraph
```

一部分输出（截取以便展示）：

```shell
Physical footprint:         69.5M
Physical footprint (peak):  69.7M
```

我们看到这个数字接近 70MB，这个给了我们一个基准线来确认针对性优化的效果。如果我们用 grep 命令查找 Image IO 也可以看到图像的一部分消耗:

```shell
vmmap --summary baylor.memgraph | grep "Image IO"

Image IO  13.4M   13.4M   13.4M    0K  0K  0K   0K  2 
```

啊哈 - 这里有大约 14MB 的脏内存。这就是我们数学演算（《餐巾纸的背面》- 这本书讲了用餐巾纸和笔将思考视觉化来解决问题）后我们图像的消耗假设。为了说明上下文，这里是一张 Terminal 的快速截图，简洁阐述了我们用 grep 查找后每一行的含义：

![](https://www.swiftjectivec.com/assets/images/vmmap.jpg)

多么清晰，我们的图像需要完整的内存消耗在这个 300x400 image view中。图像的大小是一个关键点，但它并不是问题的唯一因素。

### 色彩空间

能确定的是，有一部分内存消耗来源于另一个重要因素 - 色彩空间。在上面的例子中，我们假设大部分 iPhone 不可能是这种情况 - 图像使用 sRGB 格式。每个像素 4 个字节，由红，蓝，绿，透明每个分量 1 个字节组成。

如果你用的是支持宽色域的设备进行拍摄（比如 iPhone 8+ 或 iPhone X），那么你在整个内存消耗过程中可能将变成两倍。当然，反之亦然。Metal 会用仅有一个 8 位透明通道的 Alpha 8 格式。

这有很多值得控制和思考的地方。这也是为什么你应该用 [UIGraphicsImageRenderer](https://www.swiftjectivec.com/uigraphicsimagerenderer/) 代替 `UIGraphicsBeginImageContextWithOptions` 的原因之一。后者*总是*会使用 sRGB，这意味着你可能会错失想要的宽色域格式，或者如果（色域）更小时的节省。在 iOS 12，`UIGraphicsImageRenderer` 会为你做正确的选择。

我们不要忘记，大部分突然出现图像不是真正的摄影作品，而是不重要的随手拍。虽然我不想重复我最近写过的东西，但避免你之前错过（还是重复一下）：

```swift
let circleSize = CGSize(width: 60, height: 60)

UIGraphicsBeginImageContextWithOptions(circleSize, true, 0)

// Draw a circle
let ctx = UIGraphicsGetCurrentContext()!
UIColor.red.setFill()
ctx.setFillColor(UIColor.red.cgColor)
ctx.addEllipse(in: CGRect(x: 0, y: 0, width: circleSize.width, height: circleSize.height))
ctx.drawPath(using: .fill)

let circleImage = UIGraphicsGetImageFromCurrentImageContext()
UIGraphicsEndImageContext()
```

这上面的圆形图像用的是每个像素 4 个字节的格式。如果换用 UIGraphicsImageRenderer，通过渲染器自动选择正确的格式，让每个像素使用 1 个字节，你可以获得高达 75％ 的节省：

```swift
let circleSize = CGSize(width: 60, height: 60)
let renderer = UIGraphicsImageRenderer(bounds: CGRect(x: 0, y: 0, width: circleSize.width, height: circleSize.height))

let circleImage = renderer.image{ ctx in
    UIColor.red.setFill()
    ctx.cgContext.setFillColor(UIColor.red.cgColor)
    ctx.cgContext.addEllipse(in: CGRect(x: 0, y: 0, width: circleSize.width, height: circleSize.height))
    ctx.cgContext.drawPath(using: .fill)
}
```

### 缩小比例 vs 向下采样

回到简单的绘制场景 - 图像的许多问题和它们对我们记忆的影响源自我们联想到摄影艺术中的典型图像。想想肖像，风景照片等等。

这解释了为啥一些工程师会假设（并且逻辑上认为）通过 `UIImage` 简单缩放它们就够了。但它（对性能的优化）通常不是由于上面的原因，并且根据 Apple 的 kyle Howarth 的说法，由于内部坐标转换，这也没有那么高效。

`UIImage` 在这里是主要原因所在，因为它会像我们讨论渲染管道时那样解压*原始图像*到内存中。我们需要一个方法来处理图像缓冲区的尺寸，理想情况下（会有办法的）。

庆幸的是，只能用实际上调整过大小的图像来调整图像的大小，人们通常认为这种情况是不可能的。

让我们尝试用底层的 API 来对它进行向下采样：

```swift
let imageSource = CGImageSourceCreateWithURL(url, nil)!
let options: [NSString:Any] = [kCGImageSourceThumbnailMaxPixelSize:400,
                               kCGImageSourceCreateThumbnailFromImageAlways:true]

if let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) {
    let imageView = UIImageView(image: UIImage(cgImage: scaledImage))
    
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    imageView.widthAnchor.constraint(equalToConstant: 300).isActive = true
    imageView.heightAnchor.constraint(equalToConstant: 400).isActive = true
    
    view.addSubview(imageView)
    imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
}
```

取巧的显示，我们会获得和以前完全相同的结果。不过在这里，我们使用了 `CGImageSourceCreateThumbnailAtIndex()` 而不是仅仅将原始的图片放进 image view。依旧使用 vmmap 来确认我们的优化是否有回报（同样，截取以便展示）：

```shell
vmmap -summary baylorOptimized.memgraph

Physical footprint:         56.3M
Physical footprint (peak):  56.7M
```

节省是简而易见的。经过比较，之前是 69.5M，现在是 56.3M，所以我们现在节省了 13.2M。这个节省*相当大*，接近整张图片的消耗。

更进一步的话，你可以尝试更多可能的选项来打磨自己案例里的东西。在 WWDC 18 的 Session 219，“Images and Graphics Best Practices”中，苹果工程师 Kyle Sluder 展示了一种有趣的方式来控制解码时机，使用 `kCGImageSourceShouldCacheImmediately` 标志位：

```swift
func downsampleImage(at URL:NSURL, maxSize:Float) -> UIImage
{
    let sourceOptions = [kCGImageSourceShouldCache:false] as CFDictionary
    let source = CGImageSourceCreateWithURL(URL as CFURL, sourceOptions)!
    let downsampleOptions = [kCGImageSourceCreateThumbnailFromImageAlways:true,
                             kCGImageSourceThumbnailMaxPixelSize:maxSize
                             kCGImageSourceShouldCacheImmediately:true,
                             kCGImageSourceCreateThumbnailWithTransform:true,
                             ] as CFDictionary
    
    let downsampledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions)!
    
    return UIImage(cgImage: downsampledImage)
}
```

这里 Core Graphics 直到你专门请求缩略图为止，都不会开始解码图片。另外，关注我们在两个例子中都传入了 `kCGImageSourceCreateThumbnailMaxPixelSize`，因为如果不这样做，你就会获得和原图同样尺寸的缩略图。根据文档所示：

> “...如果没指定最大尺寸，（返回的）缩略图将会是完整图像的尺寸，这可能并不是你想要的。”

所以上面发生了什么？简而言之，我们创建了一个比之前小很多的图像解码缓冲区，减小等式的一部分。回想之前提到的渲染管道，在第一个环节（加载）时，我们传递绘制了只有展示 image view 大小的图像缓冲区而不是整个图像大小，去让 UIImage 解码。

觉得整篇文章太长不想看？（结论就是）想办法使用对图像使用向下采样而不是使用 UIImage 去缩小比例。

### 加分点

我的个人用法，在 iOS 11 里介绍的[预加载 API](https://developer.apple.com/documentation/uikit/uitableviewdatasourceprefetching?language=swift) 后使用这种方法。记住我们本质上是在介绍图像解码时的 CPU 使用峰值，哪怕解码发生在 table view 或者 collection view 需要 cell 的时候。

由于在持续需求时 iOS 会有高效的续航管理，但在这里的情况是断断续续的，所以最好亲自解决你队列里这样类似的问题。这里还将解码放到了后台线程，这是另一个重要的致胜点。

闭上眼睛，我的业余项目里 Objective-C 代码例子来了：

```objective-c
// 使用你自己的队列而不是全局异步的队列避免潜在的线程爆炸问题
- (void)tableView:(UITableView *)tableView prefetchRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    if (self.downsampledImage != nil || 
        self.listItem.mediaAssetData == nil) return;
    
    NSIndexPath *mediaIndexPath = [NSIndexPath indexPathForRow:0
                                                     inSection:SECTION_MEDIA];
    if ([indexPaths containsObject:mediaIndexPath])
    {
        CGFloat scale = tableView.traitCollection.displayScale;
        CGFloat maxPixelSize = (tableView.width - SSSpacingJumboMargin) * scale;
        
        dispatch_async(self.downsampleQueue, ^{
            // Downsample
            self.downsampledImage = [UIImage downsampledImageFromData:self.listItem.mediaAssetData
                               scale:scale
                        maxPixelSize:maxPixelSize];
            
            dispatch_async(dispatch_get_main_queue(), ^ {
                self.listItem.downsampledMediaImage = self.downsampledImage;
            });
        });
    }
}
```

>对于你大部分的原始图像资源，务必 asset catalog 管理，因为它已经会为你管理好缓存区的大小（还有其他）。

想获取更多灵感，成为处理内存和图像关系佼佼者，一定不要错过 WWDC 18 这些信息量巨大的 session：

* [iOS Memory Deep Dive](https://developer.apple.com/videos/play/wwdc2018/416/?time=1074)
* [Images and Graphics Best Practices](https://developer.apple.com/videos/play/wwdc2018/219/)

### 总结

学无止境。在编程方面，你起码需要完成“一万小时定律”，才能跟得上这个领域创新和变化的步伐。也就是意味着，这会有大量的 API，框架，模式或优化是你根本不知道的。

在图像领域也是这样的。大部分时间里，你初始化一个大小合适的 UIImageView 就继续了。我知道存在着摩尔定律。现在手机很快，也有着很大的内存，但是你要知道 - 将人类送上月球的计算机只有不到 100KB 的内存。

但是长期和魔鬼共舞（比喻不管内存问题），它总有露出獠牙的那天。不要被慢慢积攒的垃圾（代码）拉下深渊，到时候连一张自拍都占用了 1GB 的内存。希望这些知识和技术能节省你查找崩溃日志的精力。

下次再见 ✌️。