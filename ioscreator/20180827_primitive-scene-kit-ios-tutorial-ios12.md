title: "SceneKit 教程中的基本单元"
date: 2018-08-27
tags: [Swift, iOS 开发]
categories: [SceneKit]
permalink: primitive-scene-kit-ios-tutorial-ios12
keywords: SceneKit
custom_title: SceneKit 教程中的基本单元
description: SceneKit 的简单教程

---
原文链接=https://www.ioscreator.com/tutorials/primitive-scene-kit-ios-tutorial-ios12
作者=Arthur Knopper
原文日期=2018-08-27
译者=张弛
校对=待定
定稿=待定

<!--此处开始正文-->

`SceneKit` 是一个可将三维图像添加到你应用中的高级的框架工具。在本教程中，基本对象将定位在三维坐标中，并为每个基本单元分配一种颜色。本教程使用 Xcode 10 制作并专为 iOS 12 而构建。

<!--more-->

打开 Xcode 并创建一个新的工程；选择 Game 模板。

![](https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5b82f07b88251bb51ff63d96/1535307914368/game-template.png?format=1000w)

对于产品名称，请使用 **iOS12SceneKitTutorial**，然后使用你的常规值填写组织名称和组织标识符。输入 Swift 作为语言和 SceneKit 作为游戏技术，点击 Next。

![](https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5b82f1ad21c67c8d1fb3d3db/1535308226051/scene-kit%3Dproject.png?format=1000w)

将新文件添加到项目中，将其命名为 `MyScene` 并使其成为 `SCNScene` 的子类

![](https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5b82f298f950b729a34601df/1535308446050/add-file-scn-scene.png?format=1000w)

在 **MyScene.swift** 文件的顶部导入 SceneKit 框架

```swift
import SceneKit
```

下一步，在类中添加必要的初始化方法

```swift
class MyScene: SCNScene {
  
  override init() {
    super.init()
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
```

自定义代码将在 `init` 方法的末尾填充。首先道航到 **GameViewController.swift** 文件。Game 模板在这个类中创建了一些样板代码。删除 `GameViewController` 类中的所有代码并添加 `viewDidLoad` 方法

```swift
override func viewDidLoad() {
    super.viewDidLoad()
        
    let scnView = self.view as! SCNView
    scnView.scene = MyScene()
    scnView.backgroundColor = UIColor.black
}
```

创建 `SCNView` 时，场景属性设置为 `MyScene` 并具有黑色背景。返回 **MyScene.swift** 文件，并在 `init` 方法的末尾添加以下代码。

```swift
let plane = SCNPlane(width: 1.0, height: 1.0)
plane.firstMaterial?.diffuse.contents = UIColor.blue
let planeNode = SCNNode(geometry: plane)
        
rootNode.addChildNode(planeNode)
```

创建一个平面对象，其宽度和高度为一个单位。`SceneKit` 是基于节点的，这意味着场景包含一个 `rootNode`，并且可以向其添加子节点。创建包含蓝色平面对象的节点，并将此节点作为子节点添加到根节点。构建并运行项目。

![](https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5b82f99e8a922d080021c3de/1535310248382/blue-plane-scene-kit.png?format=750w)

平面的前视图是可见的。如果有一些照相机控制可用并且有一些闪电应用于场景，那应该不错。转到 **GameViewController.swift** 文件并将以下行添加到 `viewDidLoad` 的末尾。

```swift
scnView.autoenablesDefaultLighting = true
scnView.allowsCameraControl = true
```

启用场景的默认闪电，并且还可以通过使用一个或两个手指点击来控制模拟器/设备上的摄像机。返回 **MyScene.swift** 文件并在 `init` 方法的末尾添加一个新对象。

```swift
let sphere = SCNSphere(radius: 1.0)
sphere.firstMaterial?.diffuse.contents = UIColor.red
let sphereNode = SCNNode(geometry: sphere)
sphereNode.position = SCNVector3(x: 0.0, y: 3.0, z: 0.0)
    
rootNode.addChildNode(sphereNode)
```

创建半径为1单位的球体,颜色设置为红色。 `firstMaterial` 属性是材质的类型，`diffuse` 属性是材质的基色。使用 `SCNVector3` 功能，节点可以按三维（x，y，z）定位。构建并运行项目。

![](https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5b82fac2758d46345de3f1ce/1535310542606/plane-sphere-scene-kit.png?format=750w)

两个基本单元是可见的。球体位于平面上方，因为y坐标的值为3.平面的默认坐标为（0, 0, 0）。现在在 `init` 方法的末尾添加所有其他原始对象。

```swift
let box = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.2)
box.firstMaterial?.diffuse.contents = UIColor.green
let boxNode = SCNNode(geometry: box)
boxNode.position = SCNVector3(x: 0.0, y: -3.0, z: 0.0)
    
rootNode.addChildNode(boxNode)
    
let cylinder = SCNCylinder(radius: 1.0, height: 1.0)
cylinder.firstMaterial?.diffuse.contents = UIColor.yellow
let cylinderNode = SCNNode(geometry: cylinder)
cylinderNode.position = SCNVector3(x: -3.0, y: 3.0, z: 0.0)
    
rootNode.addChildNode(cylinderNode)
    
let torus = SCNTorus(ringRadius: 1.0, pipeRadius: 0.3)
torus.firstMaterial?.diffuse.contents = UIColor.white
let torusNode = SCNNode(geometry: torus)
torusNode.position = SCNVector3(x: -3.0, y: 0.0, z: 0.0)
    
rootNode.addChildNode(torusNode)
    
let capsule = SCNCapsule(capRadius: 0.3, height: 1.0)
capsule.firstMaterial?.diffuse.contents = UIColor.gray
let capsuleNode = SCNNode(geometry: capsule)
capsuleNode.position = SCNVector3(x: -3.0, y: -3.0, z: 0.0)
    
rootNode.addChildNode(capsuleNode)
    
let cone = SCNCone(topRadius: 1.0, bottomRadius: 2.0, height: 1.0)
cone.firstMaterial?.diffuse.contents = UIColor.magenta
let coneNode = SCNNode(geometry: cone)
coneNode.position = SCNVector3(x: 3.0, y: -2.0, z: 0.0)
    
rootNode.addChildNode(coneNode)
    
let tube = SCNTube(innerRadius: 1.0, outerRadius: 2.0, height: 1.0)
tube.firstMaterial?.diffuse.contents = UIColor.brown
let tubeNode = SCNNode(geometry: tube)
tubeNode.position = SCNVector3(x: 3.0, y: 2.0, z: 0.0)
    
rootNode.addChildNode(tubeNode)
```

**构建并运行**项目。所有基本单元都位于场景中，并且它们都是可见的。

![](https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5b82fbb06d2a73bb5c1acd3a/1535310779018/scene-kit-simulator.png?format=1000w)

你可以在 [Github](https://github.com/ioscreator/ioscreator) 上的 `ioscreator` 存储库中下载 **IOS12SceneKitTutorial** 的源代码。
