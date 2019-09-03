title: iOS 13 自然语言的 API 中有什么新功能
tags:
categories:
permalink: natural-language-apis-ios-13

- - - -
原文链接=https://www.appcoda.com/natural-language-apis-ios-13/
作者=Sai Kambampati
原文日期=2019-07-09
译者=CyberHex
校对=
定稿=

去年苹果发布了一个叫 NaturalLanguage 新的架构。这是让更多程序员能够使用基于文本的机器学习的第一步。今年，整个项目还是在继续，苹果给这个新框架进行了一些改进。

在本教程中，我们将了解 NaturalLanguage 中新的 API， 并且同时学习它的其他一些用法。

在本教程中，你需要使用 Xcode 11 和 Swift 5.1来跑示例的 app。在发表这篇博客的时间点，这些版本还处于 beta 阶段，所以其中的一些功能可能和正式发布的版本有所不同。

在写这个示例 app 的过程中，由于为了测试 [Project Catalyst](https://techcrunch.com/2019/06/03/ios-apps-will-run-on-macos-with-project-catalyst/)，我让整个项目可以在 Mac 上执行。你会发现下边一些截图是 Mac app 的。

> 小贴士： 想复习关于自然语言处理的知识的话，推荐你看一下下边这个 [介绍教程](https://www.appcoda.com/natural-language-processing-swift/) 

## 什么是自然语言处理？

那到底什么是自然语言处理（NLP）呢？简单的来说，就是苹果的这个框架会让你的 app 有能力去分析自然语言文本然后理解这些文本的不同部分。通过给文本设定标记方案（tag scheme），框架会对文本进行不同种类的处理。

所以，标记方案（tag scheme）又是个啥？咋说呢，基本上就是用来识别的从文本中提取出来的信息的常数。你可以把它们想象成我们想让标注器（tagger）作用在文本上的一堆任务。一些我们让标注器寻找的最常见的标记方案是语言类型，名字类型，论点。

所有的 NLP 的任务都可以被分为两个部分：文本分类和词语标记。在 WWDC 2019 中，苹果发布了`NaturalLanguage `中这两个部分的改进。下边我们就一个一个来看看到底有啥新东西。

## 起始项目

在你开始看这篇教程之前，请先下载 [起始项目](https://github.com/appcoda/NLP-Sentiment-Analysis/raw/master/starter.zip)

在我们的起始项目中，你可以看到一个叫`Text+`的应用。这是一个基于 Tab 的应用，这么起名因为使用了新的 API 和以前叫教程中的应用区分一下。在这个项目的最后，我们将得到在一个 Tab 可以进行情感分析，另一个 Tab 可以进行词语嵌入的应用。在后边我会对这些概念进行更深的解释。下边就是我们要做的应用：
![image-1](https://www.appcoda.com/wp-content/uploads/2019/07/Image-1.png)  
![image-12](https://www.appcoda.com/wp-content/uploads/2019/07/Image-12.png)  

## 文本分类

文本分类就是给一堆文本（比如一句话，一个段落甚至整个文件）贴标签。这些可以是任何你选的标签：不管是话题标签，情感标签或者是任何可以帮助你分类的标签。

`NatrualLanguage` 今年最新的改变就是加入了对情感分析的内置支持。情感分析就是根据某一堆文本所表达的情绪来给他们分类。从 -1.0 到 1.0，我们可以决定这些文本所表达的是积极地情绪还是消极的情绪。

在示例应用中，选择`SuggestionViewController.swift`文件，你可以看到一个叫做`analyzeText()`的方法。这个方法会在 `analyzeButton` 被点的时候触发。

用户可以在输入框中输入任何信息。我们想做的是对这些信息进行情感分析，然后根据不同的感情来改变 button 的颜色：

1. 绿色代表信息传达的是正能量
2. 红色代表信息传达的是负能量
3. 蓝色代表信息的情绪是中立的

我们接下来开始实现这个功能。下边已经声明了 `IBOutlets`,我们再来声明标注器。

```
import UIKit
import NaturalLanguage
 
class SentimentViewController: UIViewController {
    @IBOutlet var analyzeButton: UIButton!
    @IBOutlet var messageTextField: UITextField!
    let tagger = NLTagger(tagSchemes: [.sentimentScore])
 
    ...
}
```

我们声明的标注器是一个 `NSTagger` 的类型，我们可以用它来观测 `情感得分`（sentimentScore）。也就是说当我们把这个标注器作用在我们得到的文本信息中，它会对这些信息中包含的情感进行打分。

下一步我们就是要把这些逻辑加到 `analyzeText` 的函数中。下面就是具体的实现方式：

```
import UIKit
import NaturalLanguage
 
class SentimentViewController: UIViewController {
    tagger.string = messageTextField.text
    let (sentiment, _) = tagger.tag(at: messageTextField.text!.startIndex, unit: .paragraph, scheme: .sentimentScore)
    print(sentiment!.rawValue)
}
```

如果你之前用过 `NatrualLanguage` 的话，上边这一小段代码就是不言自明了。如果没用过的话也没关系，下边就给你来解释。

首先，我们把 `messageTextField` 中的 text 赋值给 tagger 的 string 属性。接下来，我们触发 tagger 的 `tag` 方法。这个方法基于所给的文本和指定的方案找到合适的标签。在这段代码中我们用到的方案是 `.sentimentScore`。这个方案会根据文本的情感等级来判定它到底是积极，消极还是中立的。

`tag`方法还需要我们来指定语言单位。因为用户有可能输入一大段文字，所以我们指定语言单位为 `.paragraph`。

这个函数会返回两个值：标签和判定情感得分所在的范围。因为我们并不需要这个范围，所以我们可以用`_`来忽略它。最后我们在终端里打印出来`sentiment`的值。

你可以试着跑一遍代码然后看看 console 中打印出来的得分是多少。

![image-4](https://www.appcoda.com/wp-content/uploads/2019/07/Image-4.png)  
![image-5](https://www.appcoda.com/wp-content/uploads/2019/07/Image-5.png)  

你可以看到对于我输入的句子“我对我能写出这些代码感到相当的开心！”，得到了很积极的 0.6 分。

这样我们就完成了关于 NLP（Natural Language Processing）的部分。接下来，给你一个小挑战 - 根据我们得到的情感得分来改变 `analyzeButton` 的背景颜色。如果得分高于 0 分，意味着态度是积极的，所以我们把背景颜色设置为绿色。如果得分低于 0 分，意味着态度是消极的，所以我们把背景颜色设置为红色。最后，如果得分是为 0，说明态度是中立的，我们就把背景色设置为蓝色。

怎么样，能做出来不？不行的话也不用担心，下边有答案。给 `analyzeText()` 方法中加入下边几行代码：

```
let score = Double(sentiment!.rawValue)!
if score < 0 {
    self.analyzeButton.backgroundColor = .systemRed
} else if score > 0 {
    self.analyzeButton.backgroundColor = .systemGreen
} else {
    self.analyzeButton.backgroundColor = .systemBlue
}
```

这段代码非常简单。我们把我们得到的 `情感` 常数的原始值转换成 `Double`。然后使用 if-else 来改变 button 的背景颜色。

如果可以的话，在你的应用中尝试着使用`.system`，因为从现在开始这个参数在苹果的所有 OS 中都可以使用，而且不需要你做任何事情就可以自动适配深色模式和辅助功能。

![image-8](https://www.appcoda.com/wp-content/uploads/2019/07/Image-8.png)  

恭喜你！就用这几行代码，你就可以把一个完整的情感分析的功能加入你的应用中。放在以前，你还得用 `CoreML` 而不是 `NaturalLanguage` ，而后者要用起来简单很多。接下来我们看看在词组标记（Word Tagging）中有什么新东西吧。

## 词组标记

词语标记和文本分类还有一些略微的不同。在词语标记的过程中，考虑到我们有一系列的词语（在 NLP 中被称为 tokens），我们希望给每一个 token 都贴一个标签。这些标签可以是它们在演讲中所在的部分、被命名好的实体识别、或者其他的可以帮助你分配给 token 的标签系统。

NLP 的一个很大的任务就是词语嵌入。词语嵌入是一个对象到向量表达的映射，而向量不过是一个连续的数字序列。所以这到底意味着什么而又为什么这么重要呢？通过对对象进行映射，我们可以对一堆对象进行量化的整理。当我们在坐标系中画出这些向量的时候我们会发现相似的对象会聚集在一起。这在我们想展示与目标对象相似对象时很有用。除了词语，我们还可以对图片，词组和其他东西进行嵌入。

在我们要做的应用的第二部分，我们可以借助词语嵌入的力量来做一个帮助别人购物的建议系统。下边是具体实现。我们先来看看 Storyboard，你可以看到我们有一个可以输入想要的东西的输入框，一个可以点击来进行购物建议的 button，和一个 label 来展示系统所给出的建议。因为所有的 UI 已经连好了，所以我们只需要在 `suggest()` 函数里加入下边的代码。

```
	@IBAction func suggest(_ sender: Any) {
   //1
   suggestionLabel.text = "You may be interested in:\n"
   let embedding = NLEmbedding.wordEmbedding(for: .english)
 
   //2
   embedding?.enumerateNeighbors(for: itemTextField.text!.lowercased(), maximumCount: 5) { (string, distance) -> Bool in
       //3
       print("\(string) - \(distance)")
       suggestionLabel.text! += (string.capitalized + "\n")
       return true
   }
```

我们来逐行的对上边的代码来进行解释：

1.首先，我们重置了 `suggestionLabel` 以确保以前的建议不被显示。你可以使用 `NLEmbedding` 来寻找相似的字符串。这个框架有我们能立即使用的内置词语嵌入。在这里，我们在调用 `wordEmbedding` 并传入语言偏好参数以后，我们会得到一个可以寻找英语中相似词语的 `NLEmbedding` 的返回。

2.有 `NLEmbedding` 在手，我们就可以调用 `enumerateNeighbors` 来为输入的文本寻找相似的词语。我已经设置了让函数只返回最相似的5个词语，你也可以修改这个数字。

3.最后，我在终端打出相似的词语和他们与原词的“距离”。这个“距离”指的是两个单词之间的相似度。所以“距离”越小越相似。

编译并跑一遍代码。我们可以看到整个程序完美运行！

![image-11](https://www.appcoda.com/wp-content/uploads/2019/07/Image-11.png)  

现在，你会发现这个建议体验并没有那么好，因为词语嵌入只能显示与原词相近的词语，并不一定是和对象相关的。比如，我想让系统给我一个关于“肉”的建议，其中一个词就是“素食”。虽然这个
词跟“肉”关系很近，但是对于购物者来说并没有什么卵用。对我们这个应用来说，一个`推荐系统`好像更符合我们的需求。这也会用到机器学习，并且一个在接下来的教程中讲到  `CreateML`。

那么在什么情况下还会用到词语嵌入呢？在图片应用中，当你搜索“大海”的时候，他还会给你展示出关于海滩，冲浪板，还有一些其他的与海相关的图片。这些很有可能也是通过词语嵌入实现的。

词语嵌入的另一个应用是 `模糊查询`。不知道你有没有这样的经历，你想查一些东西，比如一本书或者一首歌，你明明打错了几个字母但还是得到了你想要的结果。这是因为模糊查询使用了词语嵌入在数据库中对错误输入和正确输入之间的相似度进行计算，然后展示出正确的词组。

## 还有哪些新东西

情感分析和词语嵌入是今年 `NaturalLanguage` 里最大的两个更新。除了它们，还发布了其他两个新功能。但是如果细说的话会让本教程太长了，所以我就一笔带过。

### 自定义词语嵌入

之前我们用的是所有苹果操作系统都自带的词语嵌入模型。但是，有是有我们会想去使用一些在某些领域更加特定的词语嵌入模型，比如金融词汇或者医学词汇。苹果也考虑到了这个问题，所以 `NaturalLanguage` 也支持自定义词语嵌入。

当我们在CreateML中创建一个推荐系统的时候，其实本质就是，利用所得到的数据创建一个自定义的词语嵌入。但是，如果你想自己控制底层的算法，苹果也允许你这么做。你可以很方便的使用 `CreateML` 实现一个你自己的词语嵌入。

```
import CreateML
 
let vectors = ["Object A": [0.112, 0.324, -2.24, ...],
                "Object B": [0.112, 0.324, -2.24, ...],
                "Object C": [0.112, 0.324, -2.24, ...],
                  ...
              ]
let embedding = try MLWordEmbedding(dictionary: vectors)
try embedding.write(to: url)

```

你可以通过使用 TensorFlow 或者 PyTorch 生成的自定义神经网络来得到上边的数组向量。对于本教程这些有一点超纲，但是如果你感兴趣的话，我强烈建议你在网上搜一搜，因为这些是 NLP 中比较热门的研究领域，而且也很有意思。

### 文本目录

我们之前简单的提过如何用`MLWordTagger`来生成你想要的词语标注器。但是，我们需要花费大量的经历建立一个词语标注的模型。

今年新引入的一个库就是 `MLGazetteer`，`gazetteer` 是一个文本目录，或者是一个词典，里边全都是名字和标注。`CreateML` 就会把这个 gazetteer 转化为一个可以在应用中使用标注器。比如你想要一个可以吧电子产品按照类型分类的标注器，你可以使用以下的文件：

```
import CreateML
 
let entities = ["smartphone": ["iPhone XS", "Samsung S10", "Google Pixel 3a", ...],
"laptop": ["MacBook Pro", "Surface Laptop", "Chromebook", ...],
"smartwatch": ["Apple Watch", "Samsung Galaxy Watch", "Fitbit Versa", ...],
...
]
let gazetteer = try MLGazetteer(dictionary: entities)
try gazetteer.write(to: url)

```

理想状态下，在这个 JSON 文件中，你会有成千个实体。然后，你就可以用 `CreatML` 来建立一个下边这样一个 gazetteer：

```
import CreateML
 
let entities = ["smartphone": ["iPhone XS", "Samsung S10", "Google Pixel 3a", ...],
"laptop": ["MacBook Pro", "Surface Laptop", "Chromebook", ...],
"smartwatch": ["Apple Watch", "Samsung Galaxy Watch", "Fitbit Versa", ...],
...
]
let gazetteer = try MLGazetteer(dictionary: entities)
try gazetteer.write(to: url)
```

然后你就可以把它用在 `NaturalLanguage` 框架中：

```
import NaturalLanguage
 
let gazetteer = try! MLGazetteer(contentsOf: url)
let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
tagger.setGazetteers([gazetteer], for: .nameTypeOrLexicalClass)
```

如果你想让我给本教程写一个续集对上边的这些新功能进行深入的讲解的话，记得在下边的评论中留言。

## 结论

综上所述，你可以看到自然语言处理领域是如何扩张，也会看到苹果为了让更多的开发者使用到这些前沿技术做出了他们最大的努力。我建议你看看下边的这些材料，包括苹果的官方文档和 WWDC 2019 关于这个框架的讲座。

* [Natual Language Documentation](https://developer.apple.com/documentation/naturallanguage?language=objc)
* [WWDC 2019 - Advancement in Natural Language Framework](https://developer.apple.com/videos/play/wwdc2019/232/)

有了像情感分析和词语嵌入这样的强有力的工具，只要是与可以利用到机器学习的领域相关的应用，你都可以开发出来。如果你有什么问题，记得在评论中留言。

 [这里](https://github.com/appcoda/NLP-Sentiment-Analysis) 是完整的项目下载链接，以供参考。

