title: "NSPredicate"
date:
tags: [Objective-C, NSPredicate]
categories: [swiftjectivec]
permalink: nspredicate-objective-c
keywords: predicate, collection
custom_title: "NSPredicate"

---
原文链接=https://www.swiftjectivec.com/nspredicate-objective-c/
作者=Jordan Morgan
原文日期=2018-05-18
译者=石榴
校对=
定稿=


<!--此处开始正文-->

当 Swift 刚出现的时候，我们迷恋上了它相比于 Objective-C 的简洁性。然后面向协议编程很快成为了关键。别忘了还有引用类型和类，还有很多。

确实，这些东西都是很棒的工具，他们都有优秀的用例。但我感觉他们往往被追捧成一劳永逸的利器，而人们缺少了在做出结构性的决定时足够必要的考虑。

<!--more-->

因此在 2018 年，技术博客中充斥着各种 Swift 黑魔法（我的博客也不例外🤷🏻‍♂️），会议演讲也都在讨论 Swift 的函数式编程未来（没错，我也做了这种演讲🙋🏻‍♂️）。

所有人都对在 Swift 中使用集合（collection）感到激动，**但是**我们从 iOS 3 开始就可以用 Objective-C 来做相似的事了。所以今天我会讨论 `NSPredicate` 的威力，以及如何用🦖筛选集合。

因为我觉得和今天讲的话题有关系，有必要提一嘴：我们最近看到了一些开发者一开始学了 Swift，后来又得回去维护 Objective-C 的代码。如果说的就是你，那你很可能正在发愁如何优雅地在 Objective-C 中处理集合。

在这里，你也可能在这找到对你有用的东西。

## 用例

近几年来，Objective-C 的集合有了长足的进步。还在几年以前，我们还必须要告诉编译器我们比他聪明得多：

```Objective-C
NSString *aString = (NSString *)[anArray indexOfObject:0];
```

感谢老天、库比提诺[^1]和朋友们©终于用类型擦除（type erasure）的方式添加了泛型。这是一个很大的进步：

[^1]: 译者注：Cupertino, CA，苹果总部所在城市。

```Objective-C
NSArray *anArray = @[@"Sup"];
NSString *aString = [anArray firstObject];
```

但无论是不是泛型，我们经常通过与下面类似的方法与 Objective-C 集合中的内容交互：

```Objective-C
for (NSString *str in anArray)
{
    if ([str isEqualToString:@"The Key"])
    {
        // 做些什么
    }
}
```
很多情况下，这样写是可以接受的。但是当需求越来越复杂，关系更加多种多样，代码就会变得不确定。如果你认同『更少的代码就代表着更少的 bug 和更轻松的后期维护』这个观念，那么一个简单的对集合的查询操作就可能成为麻烦。

Predicate 可以改善这个状况。不是要在代码中耍些小聪明，而是写出简洁和务实的代码。

## 概览
`NSPredicate` 的核心用途是限制或定义对内存中的数据过滤，或进行取回（fetch）时的参数。当它和 Core Data 一起使用的时候才会如虎添翼。它和 SQL 很像，只不过没那么糟糕\*。

> 开个玩笑，只是那些以集合为基础的操作（set based operations）从来就没有让我感到说得通过。

你给它提供一个逻辑条件，然后它就会返回符合条件的东西。这意味着它可以提供基础比较、复合 predicate、键路径（key path）集合查询、子查询、合计（aggregates）以及更多的支持。

因为它用来筛选集合，它可以获得 Foundation 的类的原生支持。可变（mutable）版本从结果中直接修改，而他们的不可变版本会返回一个新实例：

```Objective-C
// 修改原数组
[mutableArray filterUsingPredicate:/*NSPredicate*/];

// 返回新的数组
[mutableArray filteredArrayUsingPredicate:/*NSPredicate*/];
```

虽然 predicate 可以从 `NSExpression`、`NSCompoundPredicate` 或 `NSComparsionPredicate` 中实例化，它还可以用一个字符串的语法中生成。这和可视化格式语言（Visual Format Language）类似，我们可以用它定义排版约束（layout constraint）。

在这里我们会集中于用字符串语法生成的方法。

## 配置

为了更好的说明，让我们以下面的代码作为这篇文章剩余部分的前提。

```Objective-C
// 伪代码
Person:NSObject
Identifier:NSString
Name:NSString
PayGrade:NSNumber

// An some property somewhere containing Person instances
NSArray *employees
```

## 查询⚡️
本文章剩下的部分都是如何用字符串格式语法来配置查询的直接的例子。

我们可以从一个简单的搜索的情景开始。先假设我们有一个含有表示 `Person` 对象的识别符的数组：

```Objective-C
{
    @"erersdg32453tr",  
    @"dfs8rw093jrkls",  
    // etc
}
```

现在，我们想通过这些识别符（identifier）从一个现存的 `Person` 数组中获取 `Person` 对象。可以使用一个双层嵌套的 `for` 循环来解决这个问题：

```Objective-C
// 假设 "employees" 是一个存有 Person 对象的数组
NSArray  *morningEventAttendees = @[/*上面的人的识别符*/];
NSMutableArray  *peopleAttendingMorningEvent = [NSMutableArray new];

for (NSString *userID in morningEventAttendees)  
{  
    for (Person *person in employees)  
    {  
        if ([person.identifier isEqualToString:userID])  
        {  
            [peopleAttending addObject:person];  
        }  
    }  
}

// 现在 peopleAttendingMorningEvent 里面就有我们想要的东西了
```

我们也可以使用 predicate 来达到完全一样的效果：

```Objective-C
NSPredicate *morningAttendees = [NSPredicate predicateWithFormat:@"SELF.identifier IN %@", peopleAttendingMorningEvent];

NSArray *peopleAttendingMorningEvent = [employees filteredArrayUsingPredicate:morningAttendees];
```

💫。

Predicate 的语法允许我们使用 SELF，它在这里发挥了很大的作用。它代表了在数组里的正在被操作的对象，在这里对于我们来说就是 `Person` 的对象。

> 另一个额外的好处是我们不用把数组定义成可变的了。

正是因为这个原因，我们可以访问与 SELF 代表的对象关联的键路径。在上面的代码中，`identifier` 属性被引用了。

如果你喜欢的话，任何键路径可以被放在 "%K" 的位置的变量来表示。这个版本和上面的版本效果一样：

```Objective-C
[NSPredicate predicateWithFormat:@"SELF.%K IN %@", @"identifier", peopleAttendingMorningEvent];
```

## 复合 Predicate

合并多个比较很简单。假设我们还需要像上面一样找到所有参加活动的人，但还要满足他们的工资水平在 50000 到 60000 之间。

如果使用传统的方法，我们的 if 语句只会越写越长：

```Objective-C
// 和上面的代码一样
if ([person.identifier isEqualToString:userID] && (person.paygrade.integerValue >= 5 && person.paygrade.integerValue <= 10))  
{  
    [peopleAttending addObject:person];  
}
```

但使用一个重构过的 predicate 可以让我们用一种更符合语言习惯的方式来解决问题：

```Objective-C
NSPredicate *morningAttendees = [NSPredicate predicateWithFormat:@"SELF.identifier IN %@ && SELF.paygrade.integerValue BETWEEN {50000, 60000}", peopleAttendingMorningEvent];
```

它的语法允许不用的符号代表同一个东西，可以根据你的偏好帮助提升可读性。比如：
- "&&" 或 "AND"
- "||" 或 "OR"（猜的（（
- "!" 或 "NOT"

可能像你想象的一样，他们经常会出使用在基本的比较操作之间，聚合在一个 predicate 里。

## 字符串比较

我们经常会处理一些基于字符串比较的匹配。大家都知道 Objective-C 对冗余的代码的单相思，在处理 NSString 的时候丝毫不减：

```Objective-C
NSString *name = @"Jordan";
name = [name stringByAppendingString:[NSString stringWithFormat:@"%@ %@", @"Wesley", @"Morgan"]];
```

……而 Swift 则一边窃笑着一边没那么小题大做地把字符串们连接起来。好在可以让我们松口气的是，在我们用 `NSPredicate` 来比较字符串时不会写出上面那么冗长的代码。

```Objective-C
// 假设 mutablePersonAr 是一个 Person 数组，里面有 "Karl" 和 "Jordan"
NSPredicate *namesStartingWithK = [NSPredicate predicateWithFormat:@"SELF.name BEGINSWITH 'K'"];
// 现在只有 Karl 了
[mutablePersonAr filterUsingPredicate:namesStartingWithK];
```

实际上任何比较都可以用 predicate 语法中的 `CONTAINS`、`BEGINSWITH`、`ENDSWITH` 和 `LIKE` 来实现：

```Objective-C
// 假设 mutablePersonAr 是一个 Person 数组，里面有 "Karl" 和 "Kathryn"
NSPredicate *namesStartingWithK = [NSPredicate predicateWithFormat:@"SELF.name LIKE 'Kar*'"];

// 现在只有 Karl 了
[mutablePersonAr filterUsingPredicate:namesStartingWithK];
```

> 你可能已经注意到上面的星号了；和很多的 DSL 一样，这个星号代表一个通配符。

当你把很多比较运算符结合在一个查询中的时候，这种简洁用法的重要性才会被显示出来：

```Objective-C
NSString *predicateFormat = @"(SELF.name LIKE 'Kar*') AND (SELF.paygrade.intValue >= 10)";

NSPredicate *namesStringWithK = [NSPredicate predicateWithFormat:predicateFormat];

// 现在只有 Karl 了
[mutablePersonAr filterUsingPredicate:namesStartingWithK];
```

更进一步，它还支持用 `MATCHES` 语法实现 `NSPredicate` 的像 SQL 的语法与正则表达式混用：

```Objective-C
[NSPredicate predicateWithFormat:@"SELF.phoneNumber MATCHES %@", phoneNumberRegex];
```

是时候指出 predicate 语法十分严格。它就是一个字符串。除非你是 Mavis Beacon[^2], 否则你总会一遍又一遍的不小心打错字。

[^2]: 译者注：*Mavis Beacon Teaches Typing*，一款在 1987 年发售的教盲打的软件。

好消息是你会很快的发现问题 — 运行时的异常在等着你。我们获得的能力和灵活性，会通过某些方式被失去的静态查错提供的安全网所抵消。

为了说明这一点，这段从上面的代码稍微改过的代码会导致崩溃。你能看出来是为什么吗？

```Objective-C
NSString *predicateFormat = @"SELF.name LIKE 'Kar*') AND (SELF.paygrade.intValue >= 10)"

NSPredicate *namesStartingWithK = [NSPredicate predicateWithFormat:predicateFormat];

// 现在只有 Karl 了 
[mutablePersonAr filterUsingPredicate:namesStartingWithK];
```

为了对付这些问题，我经常把 predicate 和 `NSStringFromSelector()` 结合在一起用，以此为应对打错字和以后的重构提供多一层的安全保障。

```Objective-C
NSString *predicateFormat = @"(SELF.%@ LIKE 'Kar*') AND (SELF.paygrade.intValue >= 10)"

NSString *kpName = NSStringFromSelector(@selector(identifier));  
NSString *kpPaygrade = NSStringFromSelector(@selector(paygrade));

NSPredicate *namesStartingWithK = [NSPredicate predicateWithFormat:predicateFormat, kpName, kpPaygrade];

// Now only contains Karl  
[mutablePersonAr filterUsingPredicate:namesStartingWithK];
```

有点复杂了？确实。更安全了？当然。

## 键路径集合查询

由于基于键路径的用法，`NSPredicate` 拥有一全套工具去操作他们，以提供一个更好的搜索。考虑下面的代码：

```Objective-C
// 假设一个 Person 对象现在有一个下面的属性：
// NSArray *previousPay

// 找到满足之前的所有工资的平均值大于 10 的人
NSString *predicateFormat = @"SELF.previousPay.@avg.doubleValue > 10";
NSPredicate *previousPayOverTen = [NSPredicate predicateWithFormat:predicateFormat];

// 所有之前的所有工资的平均值大于 10 的人
[mutablePersonAr filterUsingPredicate:previousPayOverTen];
```

你可以把 `@avg` 换成：  
* `@sum`
* `@max`
* `@min`
* `@count`

当你考虑到完成同样的工作而不使用 predicate 而不得不写的的代码的量（尽管很简单），这些技巧将开始成为你日常工具链的一部分。

## 深入挖掘数组

和键路径查询很像，predicate 也支持对隐式数组的查看：
- `array[FIRST]`
- `array[LAST]`
- `array[SIZE]`
- `array[index]`

通过使用这些语法，修改上面的代码段后我们就可以这样查询：

```Obejective-C
// 找到所有过去有三个不同的工资的人
NSString *predicateFormat = @"previousPay[SIZE] == 3";

NSPredicate *threePreviousSalaries = [NSPredicate predicateWithFormat:predicateFormat];

// 这些 Person 对象过去有三个不同的工资
[mutablePersonAr filterUsingPredicate:threePreviousSalaries];
```

和在上面提到的一样，我们也可以应用多个条件：

```Objective-C 
// 找到所有过去有三个不同的工资以及第一个工资大于 8 的人
NSString *predicateFormat = @"(previousPay[SIZE] == 3) AND (previousPay[FIRST].intValue > 8)";

NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
[mutablePersonAr filterUsingPredicate:predicate];
```

更加深入，你可以使用下面的操作符来实现更复杂的操作：
- `@distinctUnionOfArrays`
- `@unionOfArrays`
- `@unionOfObjects`
- `@distinctUnionOfObjects`

假设我们有一个数组的含有 `Person` 对象的数组，我们需要的是找出在所有数组中识别符不同的 `Person` 实例：

```Objective-C
// 假设 p1/2/3/4 都是 Person 对象
NSArray  *> *previousEmployees = @[@[p1],@[p2,p1,p2],@[p1],@[p4,p2],@[p4],@[p4],@[p1]];

// 获取所有不同的 ID
NSArray *unqiuePreviousEmployeeIDs = [previousEmployees valueForKeyPath:@"@distinctUnionOfObjects.identifier"];

// 现在数组里应该只含有不同的 ID
```

厉害吧！

好玩的还不止于此，还支持子查询：

```Objective-C
// 假设 Person 对象有了一个新的属性表示他们的队伍：
// NSArray  *team;
  
// 找到所有满足队伍里有工资超过 1，且没有其他工资历史的人的要求的人
NSString *predicateFormat = @"SUBQUERY(team, $teamMember, $teamMember.paygrade.intValue > 1 AND $teamMember.previousPay == nil).@count > 0";

NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
[employeeAr filterUsingPredicate:predicate];
```

当你发现你需要在一个含有对象的数组里搜索，而这些对象含有的属性自己就是一个集合的时候，子查询十分有用。所以在上面的例子里，我们有一个 `Person` 对象的数组，查询它的 `teamMember` 数组。

## 便捷才是关键[^3]

[^3]: 译者注：此处原作者用了双关。原文是 "Convenience is Key(Path)"，既有便捷是关键的意思，又在暗指这里的关键其实是 Key Path。

尽管 `NSPredicate` 是为了搜索而设计出来的，但如果你不能把它用在偏离它原本的用途*一点*那它就不是 Objective-C 了。这里也不意外。

当你想到 predicate，你想到的是从一个集合里筛选 — 也就是说它的返回值（或更改过的原来数组（in place mutation））还含有相同的东西。

但是也可以让他们含有*不*同的东西。其实我们在之前的代码中已经这样操作过了。上面的二维数组被用来返回一个识别符的数组 — `NSString` 实例。键路径让这些变的可能。

这有一个更直接的例子：

```Objective-C
// 我们得到一个长度大于 10 的识别符字符串的数组
NSString *predicateFormat = @"SELF.identifier.length > 10";
NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
NSArray  *longEmployeeIDs = [[employeeArray filteredArrayUsingPredicate:predicate] valueForKey:@"identifier"];

// 现在 longEmployeeIDs 已经不含有 Person 对象了，只有字符串
```

## 总结

你可以用语法糖烧穿 Objective-C 的集合，也可以不使用嵌套循环从一个特定的子集中提取数据。使用 `NSPredicate` 可以让眼睛轻松很多。

虽然 Swift 从语言级别支持对集合进行切片操作，但 predicate 专门为其设计，使用它来解决问题也未尝不是一个方法。如果你发现你在维护一个成熟的代码库，或是一个新的 Objetive-C 项目，让 predicate 自由地流动吧。

下次见吧✌️。