title: "Swift 中的集合（Set）"
date: 2018-11-20
tags: [Swift，iOS开发，Swift进阶]
categories: [thomashanning]
permalink: Sets-in-Swift
keywords: Swift,Set
custom_title: Swift 中的集合（Set）
description: 关于 Swift 中的集合（Set）

---
原文链接=http://www.thomashanning.com/sets-in-swift/
作者=Thomas Hanning
原文日期=2018-09-06
译者=rsenjoyer
校对=
定稿=

<!--此处开始正文-->

集合（Set） 是 Swift 集合类型（collection types）之一，Set 用来存储类型相同、顺序不固定且唯一的值。你可以将 Set 想象成一盒台球：它们在颜色和数量上独一无二，但在盒内没有固定的顺序。

![](http://s12572.pcdn.co/wp-content/uploads/2018/11/billiard.jpg)

<!--more-->

提示：这篇文章使用的是 Swift4 和 Xcode 10

## 创建集合

创建一个集合非常的简单：

```swift
let setA: Set<String> = ["a","b","c"]
```

在这个例子中，创建存储 `String` 类型的集合，命名为 `setA`。它存储着 `a`、`b`、`c` 三个值。与数组相比，集合内部的元素是无序的。通过编译器的类型推导，也可以像如下方式创建集合：

```swift
let setB: Set = ["a","b","c"]
```
同样也可以使用集合的构造器：

```swift
let setC = Set(["a","b","c"])
```

跟数组一样，如果使用 `let` 来定义一个集合，它就是不可变的。使用 `var ` 来申明一个可变的集合。

```swift
var setD = Set(["a","b"])
```

下面内容，我们将学习更多有关可变集合的内容。

## 访问集合中的元素

你可以使用循环来访问集合中的元素：

```swift
for value in setA {
     print(value)
}
```
注意：每次运行代码时，循环中值的顺序可能不同。从外面看来，它们像是随机挑选返回一样。

## 分析集合

首先，你可以检查集合是否为空：

```swift
print(setA.isEmpty)
```

也可以获取集合中元素的个数：

```swift
print(setA.count)
```

上面的操作对数组同样有效，对集合而言，更加通用的问题是判断集合中是否包含某个元素。为此，你可以使用 `contains` 方法：

```swift
print(setA.contains("a"))
```

## 添加和删除元素

你可以向可变集合里面添加和删除元素:

```swift
setD.insert("c")
setD.remove("a")
```
集合中的元素时唯一的，同一个元素可以多次被添加到集合，但集合中只存在一份。

```swift
var setE: Set = [1,2,3,4]
 
setE.insert(5)
setE.insert(5)
setE.insert(5)
 
print(setE) //[4,5,1,2,3]
```
和前面所说的一样，上面代码每次执行输出的顺序可能不同，因为集合没有排序。

## 集合比较
集合间能进行比较，显然，可以比较两个集合是否相等：

```swift
let setA: = [“a”, “b”, “c”]
let setB: = [“a”, “b”, “c”]
 
if setA == setB {
     print(“the sets are equal”)
}
```
这种情况下，集合是相等的。

比较两个集合的大小是没有明确的定义，但可以检查一个集合是否是另一个集合的子集：

```swift
let intSetA: Set = [1,2,3,4,5,6,7,8,9,0]
let intSetB: Set = [1,2,3]
intSetB.isSubset(of: intSetA) //true
```
也可以检查集合是否是另一个集合的真子集。这种情况就是该集合是另一个集合的子集但不想等。

```swift
let intSetA: Set = [1,2,3,4,5,6,7,8,9,0]
let intSetB: Set = [1,2,3,4,5,6,7,8,9,0]
let intSetC: Set = [3,4,5]
 
intSetB.isSubset(of: intSetA) //true
intSetB.isStrictSubset(of: intSetA) //false
intSetC.isSubset(of: intSetA) // true
intSetC.isStrictSubset(of: intSetA) //true
```

与之相对的概念就是超集：

```swift
let intSetA: Set = [1,2,3,4,5,6,7,8,9,0]
let intSetC: Set = [3,4,5]
intSetA.isSuperset(of: intSetC) //true
intSetA.isStrictSuperset(of: intSetC) //true
```
如果两个集合没有相同的元素，那么就说这两个集合不想交

```swift
let intSetA: Set = [1,2,3,4,5,6,7,8,9,0]
let intSetC: Set = [3,4,5]
let intSetD: Set = [13,14,15]
 
intSetA.isDisjoint(with: intSetC) //false
intSetA.isDisjoint(with: intSetD) //true
```

## 集合结合

两个集合可以合并起来，形成一个新的集合，新的集合中包含两个集合中所有的元素：

```swift
let stringSetA: Set = ["a","b","c"]
let stringSetB: Set = ["c","d","e"]

let unionSetAB = stringSetA.union(stringSetB)
print(unionSetAB) //["d", "b", "c", "a", "e"]
```

另一方面，交集就是仅包含两个集合中共同的元素：

```swift
let stringSetA: Set = ["a","b","c"]
let stringSetB: Set = ["c","d","e"]
 
let intersectionAB = stringSetA.intersection(stringSetB)
print(intersectionAB) //[“c”]
```

## 自定义集合元素类型

你可以在集合中存储自定义的类型。这种类型可以是类或者结构体。为了集合能正确使用，该类型必须遵循 `hashable` 协议。

```swift
class Movie: Hashable {
 
     var title: String
     var year: Int
 
     init(title: String, year: Int) {
          self.title = title
          self.year = year
     }
 
     static func == (lhs: Movie, rhs: Movie) -> Bool {
          return lhs.title == rhs.title &&
          lhs.year == rhs.year
     }
 
     var hashValue: Int {
          return title.hashValue ^ year.hashValue
     }
 
}
 
let terminator = Movie(title: "Terminator", year: 1980)
let backToTheFuture = Movie(title: "Back to the Future", year: 1985)
 
let movieSetA: Set = [terminator,backToTheFuture]
```