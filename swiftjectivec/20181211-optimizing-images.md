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

俗话说得好，最好的相机是你身边的那个。那么毫无疑问 - iPhone 可以说是这个星球最重要的的相机。而这在业界也已经达成共识了。

在度假？不偷偷拍几张记录在你的 Instagram 故事里？不存在的。

出现爆炸新闻？查看 Twitter，就可以知道是哪些媒体正在报道，通过他们揭露事件的实时照片。

等等...

不过正因为它们（图像）在平台上无处不在，如何以高性能和节省内存的方式来展示便是一门艺术，还容易白费工夫。稍微了解下 UIKit 中发生了什么和关于它如何处理图像，是可以节省大量时间和避免纠结在一些无用功上的。

<!--more-->

### 理论知识

流行小测试 - 这张我漂亮女儿（而且还有点时髦），大小 266KB 的照片将需要多少内存在一个 iOS App 中？

![](https://www.swiftjectivec.com/assets/images/baylor.jpg)

剧透警告 - 答案不是 266KB，也不是 2.66MB，而是接近 14MB。

为啥呢？

iOS 本质是从一幅图像的*尺寸*推断出它占用的内存 - 但实际的文件大小会比这小很多。 而这张照片的尺寸是 1718 像素宽和 2048 像素高。假设每个像素会消耗我们 4 个比特：

```
1718*2048*4/1000000 = 14.07 MB 占用
```

想象一下如果你提供了一个用户列表的 table view，并且在每一行左边使用常见的圆角头像来展示他们的照片。如果你认为这些图像会像洁食（犹太人的食品，比喻事情完美无瑕）一样，每个都被类似 ImageOptim（图像压缩优化）的技术处理过，变得优雅又紧凑的话，那可就大错特错了。即使每个头像保守估计 256x256 大小，也会占用相当一部分内存。

### 渲染管道

综上所述 - 了解（图像展示）幕后是值得的。当你读取一副图像时，它会进行以下三个步骤：

1）**加载** - iOS 获取压缩的图像并加载（在我们这个例子中）到 266KB 的内存。这还不到担心的时候。

2）**解码** - 这时，iOS 获取图像并转换成 GPU 能读取和理解的方式。这是已经解压的，就会像上面提到那样占用 14MB 了。

3）**渲染** - 如同命名那样，图像数据已经准备好以任意方式渲染。即使只是在一个 60x60pt 的 image view 中。

解码阶段是消耗最大的。在这个阶段，iOS 会创建一块缓冲区 - 具体来说是一块图像缓冲区，也就是图像在内存中的表示。这解释了为啥内存占用大小和图像尺寸有关，而不是文件大小。这确切的表明图像消耗内存的时候，为什么尺寸如此重要。

针对 UIImage 的特别说明，当我们给它从网络或者其它来源接受的图像数据时，它会将数据解码到缓冲区，但不会考虑数据是用什么编码方式（考虑 PNG 或者 JPG）压缩的。而且，它（缓冲区）实际上会被挂载到它（UIImage）上。由于渲染不是一瞬间的操作，UIImage 便会一直着保留图像缓冲区，所以它只会解码一次。

沿着这个思路 - 任何 iOS app，其中都有一整块的帧缓冲区。它负责你 iOS app 从拥有内容渲染输出，到到显示在屏幕上的过程。每个 iOS 设备上负责显示的硬件会用这里面单个像素信息逐个点亮物理屏幕上合适的像素点。

耗时问题正在此。为了达到黄油般顺滑的每秒 60 帧滑动，帧缓冲区需要让 UIKit 渲染 app 的 window 以及它里面所有层级的子视图，在它们信息发生变化的时候（比如：给一个 image view 赋值一幅图像）。一旦延迟，就会丢帧。

> *认为 1/60 秒是一个很短的时间？Pro Motion 设备已经将上限拉到了 1/120 秒。*

### 尺寸正是问题所在

我们可以很简单地将这个过程和内存的消耗可视化。我创建了一个简单的 app ，可以展示需要的图像在一个 image view 上，这里用的是我女儿的照片：

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

> *注意在实际开发中影响会更大。这里我们只用了一个简单的场景示例。*

完成之后就会是这个样子：

![](https://www.swiftjectivec.com/assets/images/baylorPhone.jpg)

简单使用 LLDB 就可以知道我们所使用图像的真正尺寸了，即便使用的是更小的 image view。

```
<UIImage: 0x600003d41a40>, {1718, 2048}
```

需要注意的是 - 这里的单位是*点*。所以当我在 3x 或 2x 设备时，还需要额外乘上这个数字。让我们简单使用 vmmap 来确认这张图像是否占用了 14 MB：

```shell
vmmap --summary baylor.memgraph
```

一部分输出（截取以便展示）：

```shell
Physical footprint:         69.5M
Physical footprint (peak):  69.7M
```

我们看到这个数字接近 70MB，这可以作为基准来确认针对性优化的成果。如果我们用 grep 命令查找 Image IO 或许会看到一部分图像消耗:

```shell
vmmap --summary baylor.memgraph | grep "Image IO"

Image IO  13.4M   13.4M   13.4M    0K  0K  0K   0K  2 
```

啊哈 - 这里有大约 14MB 的脏内存。这就是我们对图像进行数学演算（《餐巾纸的背面》- 这本书讲了用餐巾纸和笔将思考视觉化来解决问题）后的消耗假设。为了说明上下文，这是一张简单的 Terminal 截图，清晰描述了 grep 查找后每一行的含义：

![](https://www.swiftjectivec.com/assets/images/vmmap.jpg)

多么清晰，在这个 300x400 image view 中，图像也需要完整的内存消耗。图像大小虽然是其中一个关键因素，但它并不是问题的唯一因素。

### 色彩空间

能确定的是，有一部分内存消耗来源于另一个重要因素 - 色彩空间。在上面的例子（计算公式里乘 4）中，我们基于以下假设 - 图像使用 sRGB 格式，但大部分 iPhone 不符合这种情况。（sRGB 的）每个像素 4 个字节，由红，蓝，绿，透明每个分量 1 个字节组成。

如果你用的是支持宽色域的设备进行拍摄（比如 iPhone 8+ 或 iPhone X），那么内存消耗将变成两倍。当然，反之亦然。Metal 会用仅有一个 8 位透明通道的 Alpha 8 格式。

这里有很多可以把控和值得思考的地方。这也是为什么你应该用 [UIGraphicsImageRenderer](https://www.swiftjectivec.com/uigraphicsimagerenderer/) 代替 `UIGraphicsBeginImageContextWithOptions` 的原因之一。后者*总是*会使用 sRGB，这意味着你可能会错失想要的宽色域格式，以及（色域）更小时的节省。在 iOS 12 中，`UIGraphicsImageRenderer` 会为你做正确的选择。

不要忘了，大部分图像并不是真正的摄影作品，而只是无关紧要的随手拍。这里贴一下我最近写过的东西，避免读者之前错过了，尽管我并不想重复它：

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

这上面的圆形图像用的是每个像素 4 个字节的格式。如果换用 UIGraphicsImageRenderer，通过渲染器自动选择正确的格式，让每个像素使用 1 个字节，可以获得高达 75％ 的节省：

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

回到简单的绘制情景 - 图像上许多问题和对它们的印象，源自于我们联想到摄影艺术中的经典图像。想到肖像，风景照片等等。

这解释了为啥一些工程师会假设（并且逻辑上认为）通过 `UIImage` 简单地缩放就够了。但实际上它（对性能的优化）并不是由于上面的原因（缩放），而且根据 Apple 的 kyle Howarth 的说法，由于内部坐标转换的原因，优化并没有那么有效。

`UIImage` 是主要原因，因为它会像我们讨论渲染管道时说的那样解压*原始图像*到内存中。我们需要一个方法来处理图像缓冲区的尺寸，如果理想的话（是会有的）。

庆幸的是，只能用实际上调整过大小的图像来调整这个尺寸，而人们通常认为这是不可能的。

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

通过这种取巧的展示方法，会获得和以前完全相同的结果。不过在这里，我们使用了 `CGImageSourceCreateThumbnailAtIndex()` 而不是仅仅将原始的图片放进 image view。依旧可以使用 vmmap 来确认优化是否有回报（同样，截取以便展示）：

```shell
vmmap -summary baylorOptimized.memgraph

Physical footprint:         56.3M
Physical footprint (peak):  56.7M
```

节省是简而易见的。经过比较，之前是 69.5M，现在是 56.3M，节省了 13.2M。这个节省*相当大*，接近整张图片的消耗了。

更进一步，你可以在自己的案例中尝试更多可能的选项来进行优化。在 WWDC 18 的 Session 219，“Images and Graphics Best Practices“中，苹果工程师 Kyle Sluder 展示了一种有趣的方式来控制解码时机，通过使用 `kCGImageSourceShouldCacheImmediately` 标志位：

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

这里 Core Graphics 在你专门请求缩略图之前，都不会开始解码图片。另外要注意的是，两个例子都传入了 `kCGImageSourceCreateThumbnailMaxPixelSize`，如果不这样做，就会获得和原图同样尺寸的缩略图。根据文档所示：

> “...如果没指定最大尺寸，（返回的）缩略图将会是完整图像的尺寸，这可能并不是你想要的。”

所以上面发生了什么？简而言之，我们将缩放的结果放入缩略图中，从而创建的是比之前小很多的图像解码缓冲区。联想之前提到的渲染过程，在第一个环节（加载）时的 UIImage 解码，我们传递的是绘制了仅展示的 image view 大小的图像缓冲区，而不是整个图像大小（的缓冲区）。

整篇文章太长不想看？（结论就是）想办法使用对图像使用向下采样，而不是使用 UIImage 去缩小比例。

### 加分点

我的个人用法是，在 iOS 11 里引入的[预加载 API](https://developer.apple.com/documentation/uikit/uitableviewdatasourceprefetching?language=swift) 之后使用它。请记住，由于我们是在解码图像，哪怕放在 table view 或者 collection view 需要 cell 之前做，也会影响 CPU 的使用峰值。

在执行连续任务时，iOS 会有高效的续航管理，但这里是间断的，所以最好亲自去解决自己任务队列中这样的类似问题。这里还将解码放到了后台线程，这是另一个至关重要的点。

做好准备，我带来了自己业余项目里 Objective-C 代码例子：

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

>对于大部分的原始图像资源，务必 asset catalog 管理，因为它已经会为你管理好缓存区的大小（还有其他更多）。

想获取更多灵感，成为处理内存和图像关系佼佼者？不要错过 WWDC 18 这些信息量巨大的 session：

* [iOS Memory Deep Dive](https://developer.apple.com/videos/play/wwdc2018/416/?time=1074)
* [Images and Graphics Best Practices](https://developer.apple.com/videos/play/wwdc2018/219/)

### 总结

学无止境。在编程方面，你起码需要完成“一万小时定律”，才能跟得上这个领域创新和变化的步伐。也就是意味着，这会有大量的 API，框架，模式或优化是你根本不知道的。

在图像领域也是这样的。大多数时候，你初始化一个了大小合适的 UIImageView 就不管了。我当然知道存在摩尔定律。现在手机是很快，也有着很大的内存，但是你要知道 - 将人类送上月球的计算机只有不到 100KB 的内存。

但是长期和魔鬼共舞（比喻不管内存问题），它总有露出獠牙的那天。不要被慢慢积攒的垃圾（代码）拉下深渊，原因却是连一张自拍都占用了 1GB 的内存。希望上述的知识和技术能省下你查找崩溃日志的精力。

下次再见 ✌️。