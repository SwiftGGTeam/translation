---
title: "宏定义与可选括号"
date: 2019.3.10
tags: [iOS,macro]
categories: [Mike Ash]
permalink: https://www.github.com/xxx
keywords: macro
description: Objective-C 中 C 语言宏定义扩展

---
<!--此处开始正文-->
原文链接= [https://www.mikeash.com/pyblog/friday-qa-2015-03-20-preprocessor-abuse-and-optional-parentheses.html](https://www.mikeash.com/pyblog/friday-qa-2015-03-20-preprocessor-abuse-and-optional-parentheses.html) 
作者= Mike Ash 
原文日期= 2015-03-20 
译者=俊东 
校对=xxx 
定稿=xxx

# 宏定义与可选括号

前几天我遇到了一个有趣的问题： 如何编写一个 C 语言预处理器的宏，删除围绕在参数上的括号？

今天的文章，将为大家分享我的解决方案。 
<!--more-->
## 起源

C 语言预处理器是一个相当盲目的文本替换引擎，它并不理解 C 代码，更不用说 Objective-C 了。它的工作原理是挺好的，可以应付大部分情况，但偶尔也会判断失误。

这里举个典型的例子：

```objc
	XCTAssertEqualObjects(someArray,@[ @"one",@"two" ],@"Array is not as expected”);
```

这会无法编译，并且错误提示会非常古怪。预处理器查找分隔宏参数的逗号时没能将数组结构 `@ [...]` 中的东西应该理解为一个单一的元素。结果代码尝试比较 `someArray` 和 `@[@“one”` 。断言失败消息为 ` @"two” ] and @"Array is not as expected"` 。这些不完整的代码组合到了 `XCTAssertEqualObjects` 的宏扩展中，生成的代码错的离谱。

要解决这个问题也很容易：添加一个括号就行。预编译器不能识别 `[ ]` ，但它知道 `（）` 并且能够理解需要忽略里面的括号。下面的代码就能正常运行：

```objc
    XCTAssertEqualObjects(someArray,(@[ @"one",@"two" ]),@"Array is not as expected");
```

在 C 语言的许多场景下，你添加多余的括号也不会有任何区别。就像宏扩展之后，生成的代码虽然在数组文字周围有括号，但没有异常。你可以编写充满多余括号的表达式，而编译器会愉快地为你挖掘到最底部：

```objc
    NSLog(@"%d",((((((((((42)))))))))));
```

甚至可以将 `NSLog` 这样处理也行：

```
    ((((((((((NSLog))))))))))(@"%d",42);
```

在 C 中有一个地方你不能只添加随机括号：类型 （type） 。例如：

```objc
    int f(void); // 合法
    (int) f(void); // 不合法
```

所以怎么区分这种情况呢？这种情况并不常见，但如果你有一个使用类型的宏，并且您的类型包含不在括号内的逗号，则会出现这种情况。宏可以做很多事情，当一个类型遵循多个协议时，在 Objective-C 中可能出现一些类型带有未加括号的逗号;当使用带有多个模板参数的模板化类型时，在 C++ 中就可能出现。举个例子，这有一个简单的宏，创建从字典中提供静态类型值的 `getter` ：

```objc
 #define GETTER(type,name) \
        - (type)name { \
            return [_dictionary objectForKey: @#name]; \
        }
```

你能这样使用它：

```objc
    @implementation SomeClass {
        NSDictionary *_dictionary;
    }

    GETTER(NSView *,view)
    GETTER(NSString *,name)
    GETTER(id<NSCopying>,someCopyableThing)
```

到目前为止没问题。现在假设我们想要制作一个遵循两个协议的类型：

```objc
    GETTER(id<NSCopying,NSCoding>,someCopyableAndCodeableThing)
```

哎呀！宏不起作用了。而且添加括号也无济于事：

```objc
    GETTER((id<NSCopying,NSCoding>),someCopyableAndCodeableThing)
```

这会产生无效代码。这时我们需要一个删除可选括号的 `UNPAREN` 宏。将 `GETTER` 宏重写：

```
#define GETTER(type,name) \
        - (UNPAREN(type))name { \
            return [_dictionary objectForKey: @#name]; \
        }
```

我们该怎么做呢？

## 必须的括号

删除括号很容易：

```objc
	#define UNPAREN(...) __VA_ARGS__
    #define GETTER(type,name) \
        - (UNPAREN type)name { \
            return [_dictionary objectForKey: @#name]; \
        }
```

虽然看上去很扯，但这的确能运行。 预编译器将 `type` 扩展为 `（id <NSCopying，NSCoding>）` ，生成 `UNPAREN（id <NSCopying，NSCoding>）` 。然后它会将 `UNPAREN` 宏扩展为 `id <NSCopying，NSCoding>` 。

但是，之前使用的 `GETTER` 失败了。例如，`GETTER（NSView *，view）` 在宏扩展中生成 `UNPAREN NSView *`。不会进一步扩展就直接提供给编译器。结果自然会报编译器错误，因为 `UNPAREN NSView *` 是无法编译的。这虽然可以通过编写 `GETTER（（NSView *），view）` 来解决，但是被迫添加这些括号很烦人。这样的结果不是我们想要的。

## 宏不能被重载

我立刻想到了如何摆脱剩余的 `UNPAREN` 。当你想要一个标识符消失时，你可以使用一个空的 `#define` ，如下所示：

```objc
    #define UNPAREN
```

有了这个，`UNPAREN b` 的序列变为 `b` 。完美解决问题！但是，如果已经存在带参数的另一个定义，则预处理器会拒绝此操作。即使预处理器可能选择其中一个，它也不会同时存在两种形式。虽然可行的话，这能有效解决我们的问题，但可惜的是并不允许：

```objc
    #define UNPAREN(...) __VA_ARGS__
    #define UNPAREN
    #define GETTER(type,name) \
        - (UNPAREN type)name { \
            return [_dictionary objectForKey: @#name]; \
        }
```

这无法通过预处理器，因为它会由于 `UNPAREN` 的重复 `#define` 而报错。不过，它确实引导我们走上了胜利的道路。现在的问题是怎么找出一种方法来实现相同的效果，而不会使两个宏具有相同的名称。

## 瓶颈

最终目标是让 `UNPAREN（x）` 和 `UNPAREN（（x））` 结果都是 x 。朝着这个目标迈出的第一步是制作一些宏，其中传递 x 和（ x ）产生相同的输出，即使它并不确定 x 是什么。 这可以通过将宏名称放在宏扩展中来实现，如下所示：

```objc
    #define EXTRACT(...) EXTRACT __VA_ARGS__
```

现在如果你写` EXTRACT（ x ） `，结果是 `EXTRACT x` 。当然，如果你写 `EXTRACT x` ，结果也是 `EXTRACT x` ，因为没有宏扩展的情况。这仍然留给我们一个剩余的提取物。这种 `#define` 方式并不简单，但这种做法也算是进步。

## 标识符粘贴

预处理器有一个操作符 `##` ，它将两个标识符粘贴在一起。例如，`a ## b` 变为 `ab` 。这可以用于从片段构造标识符，但也可以用于调用宏。例如：

```objc
    #define AA 1
    #define AB 2
    #define A(x) A ## x
```

从这里可以看到， `A（A）` 产生 1 ， `A（B）` 产生 2 。

让我们将这个运算符与上面的 EXTRACT 宏结合起来，尝试生成一个 UNPAREN 宏。由于 `EXTRACT（...）` 使用前导 EXTRACT 生成参数，因此我们可以使用标识符粘贴来生成以 EXTRACT 结尾的其他标记。如果我们 `#define` 那个新标记为空，我们将全部设置。

这是一个以 EXTRACT 结尾的宏，它不会产生任何结果：

```objc
	#define NOTHING_EXTRACT
```

这是对 UNPAREN 宏的尝试，它将所有内容放在一起：

```objc
    #define UNPAREN(x) NOTHING_ ## EXTRACT x
```

不幸的是，这并不能实现我们的目标。操作顺序是问题所在。如果我们写 `UNPAREN（（int））` ，我们将会得到：

```objc
    UNPAREN((int))
    NOTHING_ ## EXTRACT (int)
    NOTHING_EXTRACT (int)
    (int)
```

标示符粘贴发生的顺序太前，EXTRACT 宏永远不会扩展。

你可以通过使用间接强制预处理器以不同的顺序判断事件。我们不是直接使用 `##` ，而是制作一个 PASTE 宏：

```objc
    #define PASTE(x,...) x ## __VA_ARGS__
```

然后我们将根据它写下 UNPAREN ：

```objc
    #define UNPAREN(x)  PASTE(NOTHING_,EXTRACT x)
```

这仍然不起作用。情况如下：

```objc
    UNPAREN((int))
    PASTE(NOTHING_,EXTRACT (int))
    NOTHING_ ## EXTRACT (int)
    NOTHING_EXTRACT (int)
    (int)
```

但更接近我们的目标了。序列 `EXTRACT（int）` 显然没有出发触发标示符粘贴操作符。我们必须让预处理器在它看到 `##` 之前解析它。另一层间接将迫使它表现出来。让我们定义一个只包装 PASTE 的 EVALUATING_PASTE 宏：

```objc
    #define EVALUATING_PASTE(x,...) PASTE(x,__VA_ARGS__)
```

现在让我们用这个写 UNPAREN ：

```objc
    #define UNPAREN(x) EVALUATING_PASTE(NOTHING_,EXTRACT x)
```

这是扩展：

```objc    
    UNPAREN((int))
    EVALUATING_PASTE(NOTHING_,EXTRACT (int))
    PASTE(NOTHING_,EXTRACT int)
    NOTHING_ ## EXTRACT int
    NOTHING_EXTRACT int
    int
```

即使没有额外加括号也能正常运行，因为额外的赋值并没有影响：

```objc
    UNPAREN(int)
    EVALUATING_PASTE(NOTHING_,EXTRACT int)
    PASTE(NOTHING_,EXTRACT int)
    NOTHING_ ## EXTRACT int
    NOTHING_EXTRACT int
    int
```
    
成功了！我们现在可以不需要用括号围绕 type 来编写 GETTER ：

```objc
 		#define GETTER(type,name) \
        - (UNPAREN(type))name { \
            return [_dictionary objectForKey: @#name]; \
        }
```

## 宏的奖励
在提出可以证明这个结构的宏的同时，我构建了一个很好的 dispatch_once 宏来制作延迟初始化的常量。实现如下：

```objc
    	#define ONCE(type,name,...) \
        UNPAREN(type) name() { \
            static UNPAREN(type) static_ ## name; \
            static dispatch_once_t predicate; \
            dispatch_once(&predicate,^{ \
                static_ ## name = ({ __VA_ARGS__; }); \
            }); \
            return static_ ## name; \
        }
```

使用案例：

```objc
    ONCE(NSSet *,AllowedFileTypes,[NSSet setWithArray: @[ @"mp3",@"m4a",@"aiff" ]])
```
    
然后，你可以调用 `AllowedFileTypes()` 来获取集合，并根据需要高效创建集合。如果类型包含逗号，添加括号就能运行。

## 结论

仅仅写这个宏，我就是发现了很多艰涩的知识。我希望接触这些知识也不会影响你的代码思维。请谨慎使用这些知识。

今天就是这样。更多令人兴奋的冒险以后也会有，可能是比这更不可思议的事情。在此之前，如果你对此处的主题有任何建议，请发送给 [我们](mike@mikeash.com)！