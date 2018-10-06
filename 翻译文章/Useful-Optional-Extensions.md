title: "Useful Optional Extensions"
date: 2018-01-10
tags: [Swift，iOS开发，Swift进阶]
categories: [APPVENTURE]
permalink: optional-extensions
keywords: Swift,Optional
custom_title: 实用的可选项(Optional)扩展
description: 关于 Swift 可选项(Optional) 扩展

---
原文链接=https://appventure.me/2018/01/10/optional-extensions/
作者=terhechte
原文日期=2018-01-10
译者=rsenjoyer
校对=
定稿=

<!--此处开始正文-->

可选值（Optional）是 Swift 语言最基础内容。我想每个人都同意它带来巨大的福音，因为它迫使我们妥善处理边缘情况。可选值的语言特性能使开发者在开发阶段发现并处理整个类别的 bug。

然而，Swift 标准库中可选值的 API 相当的有限。如果忽略 `customMirror` 和 `debugDescription` 属性，[Swift 文档](https://developer.apple.com/documentation/swift/optional#topics) 仅仅列出了几个方法/属性：

```swift
var unsafelyUnwrapped: Wrapped { get } 
func map<U>(_ transform: (Wrapped) throws -> U) rethrows -> U? 
func flatMap<U>(_ transform: (Wrapped) throws -> U?) rethrows -> U?
```
<!--more-->

即使方法如此少，可选值仍然非常有用，这是因为 Swift 在语法上通过 [可选链](https://appventure.me/2014/06/13/swift-optionals-made-simple/)、[模式匹配](https://appventure.me/2015/08/20/swift-pattern-matching-in-detail/)、`if let` 或 `guard let` 等功能来弥补它。但在某些情况下，这表现在不必要的分支条件中。有时，一个非常简洁的方法允许你用一行代码表达概念，而不是用多行组合的 `if let` 语句。

我筛选了 Github 上的 Swift 项目以及 Rust、Scala 或 C＃ 等其他语言的可选实现，目的是为 Optional 找一些有用的补充。以下 14 个有用的可选扩展，我将分类逐一解释，同时给每个类别举几个例子。最后，我将编写一个更复杂的示例，它同时使用多个可选扩展。

## 判空(Emptiness)

```swift
extension Optional {
    /// Returns true if the optional is empty
    var isNone: Bool {
	return self == .none
    }

    /// Returns true if the optional is not empty
    var isSome: Bool {
	return self != .none
    }
}

```


<!-- Those are the most basic additions to the optional type. The implementation could also use a switch pattern match instead, but the nil comparison is much shorter. What I like about these additions is that they move the concept of an empty optional being nil away from your code. This might just as well be an implementation detail. Using optional.isSome feels much cleaner and less noisy than if optional == nil: -->

这些是可选类型最基础的补充。实现也可以使用 `switch` 进行匹配。但空值(`nil`) 比较简短很多。我很喜欢这些补充内容， 因为它们将可选项为空的概念从代码中移除了。这可能也是一些实现的细节， 使用 `optional.isSome` 比 `if optional == nil` 更加简洁， 噪音更小。

```swift
// Compare
guard leftButton != nil, rightButton != nil else { fatalError("Missing Interface Builder connections") }

// With
guard leftButton.isSome, rightButton.isSome else { fatalError("Missing Interface Builder connections") }

```

## 或(Or)

```swift

extension Optional {
    /// Return the value of the Optional or the `default` parameter
    /// - param: The value to return if the optional is empty
    func or(_ default: Wrapped) -> Wrapped {
	return self ?? `default`
    }

    /// Returns the unwrapped value of the optional *or*
    /// the result of an expression `else`
    /// I.e. optional.or(else: print("Arrr"))
    func or(else: @autoclosure () -> Wrapped) -> Wrapped {
	return self ?? `else`()
    }

    /// Returns the unwrapped value of the optional *or*
    /// the result of calling the closure `else`
    /// I.e. optional.or(else: { 
    /// ... do a lot of stuff
    /// })
    func or(else: () -> Wrapped) -> Wrapped {
	return self ?? `else`()
    }

    /// Returns the unwrapped contents of the optional if it is not empty
    /// If it is empty, throws exception `throw`
    func or(throw exception: Error) throws -> Wrapped {
	guard let unwrapped = self else { throw exception }
	return unwrapped
    }
}

extension Optional where Wrapped == Error {
    /// Only perform `else` if the optional has a non-empty error value
    func or(_ else: (Error) -> Void) {
	guard let error = self else { return }
	`else`(error)
    }
}

```

<!-- Another abstraction on the isNone / isSome concept is being able to specify instructions to be performed when the invariant doesn't hold. This saves us from having to write out if or guard branches and instead codifies the logic into a simple-to-understand method.

This concept is so useful, that it is defined in three distinct functions. -->

`isNone / isSome`另一个抽象的概念是能够指定当变量不成立的时需要执行的指令。 这能让我们避免编写 `if` 或 `guard` 分支，而是将逻辑封装为一个易于理解的方法。

这个概念非常的有用，它可在四个不同功能中被定义。

### 默认值(Default Value)

第一个是返回可选项的包装值或者默认值:

```swift
let optional: Int? = nil
print(optional.or(10)) // Prints 10
```

### 默认闭包(Default Closure)

默认闭包和默认值非常的相似，但它允许从闭包中返回默认值。

```swift
let optional: Int? = nil
optional.or(else: secretValue * 32)
```

<!-- Since this uses the @autoclosure parameter we could actually use just the second or implementation. Then, using a just a default value would automatically be converted into a closure returning the value. However, I prefer having two separate implementations as that allows users to also write closures with more complex logic. -->

由于使用了 `@autoclosure` 参数, 我们实际上可以只使用默认闭包。使用默认值将会自动转换为返回值的闭包。 然而，我倾向于将两个实现单独分开， 因为它可以让用户用更加复杂的逻辑编写闭包。

```swift
let cachedUserCount: Int? = nil
...
return cachedUserCount.or(else: {
   let db = database()
   db.prefetch()
   guard db.failures.isEmpty else { return 0 }
   return db.amountOfUsers
})

```

<!-- A really nice use case for or is code where you only want to set a value on an optional if it is empty: -->

当你对一个为空的可选值赋值的时候，使用 `or` 就是一个不错的选择。

```swift
if databaseController == nil {
  databaseController = DatabaseController(config: config)
}

```
以上代码可以写的更加优雅: 

```swift
databaseController = databaseController.or(DatabaseController(config: config)
```

### 抛出异常(Throw an error)
<!-- 
This is a very useful addition as it allows to merge the chasm between Optionals and Error Handling in Swift. Depending on the code that you're using, a method or function may express invalid behaviour by returning an empty optional (imagine accessing a non-existing key in a Dictionary) or by throwing an Error. Combining these two oftentimes leads to a lot of unnecessary line noise: -->
这也是一个非常有用的补充， 因为它连接着 Swift 可选项与错误处理。 根据项目中的代码，当一个方法或函数表述无效的行为通过返回一个为空的可选值(例如访问字典中不存在的键)或抛出一个异常。 【【【将两者结合起来能避免很多不必要的线路噪声。】】】

```swift

func buildCar() throws -> Car {
  let tires = try machine1.createTires()
  let windows = try machine2.createWindows()
  guard let motor = externalMachine.deliverMotor() else {
    throw MachineError.motor
  }
  let trunk = try machine3.createTrunk()
  if let car = manufacturer.buildCar(tires, windows,  motor, trunk) {
    return car
  } else {
    throw MachineError.manufacturer
  }
}

```
<!-- In this example, we're building a car by combining internal and external code. The external code (external_machine and manufacturer) choose to use optionals instead of error handling. This makes the code unnecessary complicated. Our or(throw:) function makes this much more readable: -->

在这个例子中，我们通过组内部和调用外部代码来构建汽车，外部代码(`external_machine` 和 `manufacturer`) 选择使用可选值而不是错误处理。这使得代码变得很复杂， 我们可使用 `or(throw:)` 使函数更具有可读性。

```swift

func build_car() throws -> Car {
  let tires = try machine1.createTires()
  let windows = try machine2.createWindows()
  let motor = try externalMachine.deliverMotor().or(throw: MachineError.motor)
  let trunk = try machine3.createTrunk()
  return try manufacturer.buildCar(tires, windows,  motor, trunk).or(throw: MachineError.manufacturer)
}

```

### 错误处理(Handling Errors)

<!-- The code from the Throw an error section above becomes even more useful when you include the following free function that was proposed by Stijn Willems on Github. Thanks for the suggestion! -->

当代码中包含 [Stijn Willems 在 Github](https://github.com/doozMen) 自由函数，上面抛出异常部分的代码变更加有用。感谢 Stijn Willems 的建议。

```swift
func should(_ do: () throws -> Void) -> Error? {
    do {
	try `do`()
	return nil
    } catch let error {
	return error
    }
}
```
这个自由函数(可选的，可将它当做一个可选项的类方法)使用 `do {} catch {}` 块并返回一个错误。当且仅当 `do` 代码块捕捉到异常。以下面 Swift 代码为例：

```swift
do {
  try throwingFunction()
} catch let error {
  print(error)
}
```
这是 `Swift` 中错误处理的基本原则之一， 
这是Swift中错误处理的基本原则之一，它引入了相当多的线路噪声。使用上面的免费功能，您可以将其减少到这个简单的线上：

```swift
should { try throwingFunction) }.or(print($0))
```
我觉得在很多情况下，这样的错误处理单行程会非常有益。

### 变换(Map)

正如上面所见, `map` 和 `flatMap` 是 Swift 在可选项上面提供的唯一的方法。然而，在多数情况下，也可以稍微改进使它们变得更加通用。这有两个变体 `map` 允许定义一个默认值，类似于上面 `or` 变体的实现方式：

```swift
extension Optional {
    /// Maps the output *or* returns the default value if the optional is nil
    /// - parameter fn: The function to map over the value
    /// - parameter or: The value to use if the optional is empty
    func map<T>(_ fn: (Wrapped) throws -> T, default: T) rethrows -> T {
	return try map(fn) ?? `default`
    }

    /// Maps the output *or* returns the result of calling `else`
    /// - parameter fn: The function to map over the value
    /// - parameter else: The function to call if the optional is empty
    func map<T>(_ fn: (Wrapped) throws -> T, else: () throws -> T) rethrows -> T {
	return try map(fn) ?? `else`()
    }
}
```
第一个允许你将 `map` 可选内容添加到新类型 `T`。如果 `optional` 是空的，您可提供一个相应的默认值：

```swift
let optional1: String? = "appventure"
let optional2: String? = nil

// Without
print(optional1.map({ $0.count }) ?? 0)
print(optional2.map({ $0.count }) ?? 0)

// With 
print(optional1.map({ $0.count }, default: 0)) // prints 10
print(optional2.map({ $0.count }, default: 0)) // prints 0
```

这个改动很小，但我们不在需要使用 `??` 操作符，而是使用一个 `default` 关键词来更能表达意图。

第二种变体非常相似。主要区别在于它接受（再次）闭包返回值 `T` 而不是值 `T`。这是一个简短的例子：

```swift
let optional: String? = nil
print(optional.map({ $0.count }, else: { "default".count })
```

### 组合可选项(Combining Optionals)

这个类别包含了四个函数，它们允许你定义多个可选项之间的关系.

```swift
extension Optional {
    /// Tries to unwrap `self` and if that succeeds continues to unwrap the parameter `optional`
    /// and returns the result of that.
    func and<B>(_ optional: B?) -> B? {
	guard self != nil else { return nil }
	return optional
    }

    /// Executes a closure with the unwrapped result of an optional.
    /// This allows chaining optionals together.
    func and<T>(then: (Wrapped) throws -> T?) rethrows -> T? {
	guard let unwrapped = self else { return nil }
	return try then(unwrapped)
    }

    /// Zips the content of this optional with the content of another
    /// optional `other` only if both optionals are not empty
    func zip2<A>(with other: Optional<A>) -> (Wrapped, A)? {
	guard let first = self, let second = other else { return nil }
	return (first, second)
    }

    /// Zips the content of this optional with the content of another
    /// optional `other` only if both optionals are not empty
    func zip3<A, B>(with other: Optional<A>, another: Optional<B>) -> (Wrapped, A, B)? {
	guard let first = self,
	      let second = other,
	      let third = another else { return nil }
	return (first, second, third)
    }
}

```
上面的四个函数都是讲另外一个可选值当做参数，并返回一个可选值， 然而，它们的实现方式完全不同。

#### 依赖(Dependencies)

<!-- and<B>(_ optional) is useful if the unpacking of an optional is only required as a invariant for unpacking another optional: -->

```swift
// Compare
if user != nil, let account = userAccount() ...

// With
if let account = user.and(userAccount()) ...

```

<!-- In the example above, we're not interested in the unwrapped contents of the user optional. We just need to make sure that there is a valid user before we call the userAccount function. While this relationship is kinda codified in the user != nil line, I personally feel that the and makes it more clear. -->

#### 链接(Chaining)

<!-- and<T>(then:) is another very useful function. It allows to chain optionals together so that the output of unpacking optional A becomes the input of producing optional B. Lets start with a simple example: -->

`and<T>(then:)` 是另一个非常有用的函数, 它将多个可选项链接起来，以便将可选项 `A` 的解包输出当做可选项 `B` 的输入。我们从一个简单的例子开始：

```swift
protocol UserDatabase {
  func current() -> User?
  func spouse(of user: User) -> User?
  func father(of user: User) -> User?
  func childrenCount(of user: User) -> Int
}

let database: UserDatabase = ...

// Imagine we want to know the children of the following relationship:
// Man -> Spouse -> Father -> Father -> Spouse -> children

// Without
let childrenCount: Int
if let user = database.current(), 
   let father1 = database.father(user),
   let father2 = database.father(father1),
   let spouse = database.spouse(father2),
   let children = database.childrenCount(father2) {
  childrenCount = children
} else {
  childrenCount = 0
}

// With
let children = database.current().and(then: { database.spouse($0) })
     .and(then: { database.father($0) })
     .and(then: { database.spouse($0) })
     .and(then: { database.childrenCount($0) })
     .or(0)
```

使用 `and(then)` 函数对代码有很大的提升。首先，你没必要声明很多的临时变量名（user, father1, father2, spouse, children）, 其次，代码更加的简洁。而且，使用 `or(0)` 比 `let childrenCount` 可读性更好。

最后，原始的 Swift 示例很容易导致逻辑错误。 也许你还没有注意到，但示例中存在一个 bug。在写那样的代码时，可以很容易地引入复制粘贴错误。 你观察到了么？

是的， `children` 属性应该由调用 `database.childrenCount(spouse)` 创建， 但我写成了 `database.childrenCount(father2)`。很难发现这样的错误。使用 `and(then:)` 使得发现错误更加容易， 因为它使用依赖于变量 `$0`。

#### 组合(Zipping)
这是现有 Swift 概念的另一个变体，`zip` 可以让我们组合多个可选项，将他们一起解包或者解包失败。在上面的代码片段中，我提供了 `zip2` 与 `zip3` 函数，但你也可以命名为 `zip22`(好吧，也许是合理性和编译速度)。

```swift
// Lets start again with a normal Swift example
func buildProduct() -> Product? {
  if let var1 = machine1.makeSomething(),
    let var2 = machine2.makeAnotherThing(),
    let var3 = machine3.createThing() {
    return finalMachine.produce(var1, var2, var3)
  } else {
    return nil
  }
}

// The alternative using our extensions
func buildProduct() -> Product? {
  return machine1.makeSomething()
     .zip3(machine2.makeAnotherThing(), machine3.createThing())
     .map { finalMachine.produce($0.1, $0.2, $0.3) }
}
```
代码量更少，代码更清晰，更优雅。然而，也存一个缺点，就是更加的复杂了。读者必须了解并理解 `zip` 才能掌握完全掌握它。

#### On

```swift
extension Optional {
    /// Executes the closure `some` if and only if the optional has a value
    func on(some: () throws -> Void) rethrows {
	if self != nil { try some() }
    }

    /// Executes the closure `none` if and only if the optional has no value
    func on(none: () throws -> Void) rethrows {
	if self == nil { try none() }
    }
}
```
不论可选值是否为空，上面两个简短的方法都可以让你执行一些额外的操作。与上面讨论过的方法相反，这两个方法忽略可选项的值。因此 `on(some:)` 只会在可选项不为空的时候执行闭包 `some`，但是闭包 `some` 不会获取可选项的值。

```swift
/// Logout if there is no user anymore
self.user.on(none: { AppCoordinator.shared.logout() })

/// self.user is not empty when we are connected to the network
self.user.on(some: { AppCoordinator.shared.unlock() })
```

### Various
```swift
extension Optional {
    /// Returns the unwrapped value of the optional only if
    /// - The optional has a value
    /// - The value satisfies the predicate `predicate`
    func filter(_ predicate: (Wrapped) -> Bool) -> Wrapped? {
	guard let unwrapped = self,
	    predicate(unwrapped) else { return nil }
	return self
    }

    /// Returns the wrapped value or crashes with `fatalError(message)`
    func expect(_ message: String) -> Wrapped {
	guard let value = self else { fatalError(message) }
	return value
    }
}
```
#### 过滤(Filter)
这个方法类似于一个守护者一样，只有可选项的值满足 `predicate` 条件时才进行解包。比如说，我们希望所有的老用户都升级为高级账户，以便与我们保持更长久的联系。

```swift
// Only affect old users with id < 1000
// Normal Swift
if let aUser = user, user.id < 1000 { aUser.upgradeToPremium() }

// Using `filter`
user.filter({ $0.id < 1000 })?.upgradeToPremium()
```
在这里，`user.filter` 使用更加自然。此外，它只实现了 Swift 集合中已有的功能。

#### 期望(Expect)

这是我最喜欢的功能之一。这是我从 `Rush` 语言中借鉴而来的。我试图避免强行解包代码库中的任何东西。类似与隐式解包可选项。

然而，当使用可视化界面构建时会很棘手。我观察到下面的这种方式在项目中很常见：

```swift
func updateLabel() {
  guard let label = valueLabel else {
    fatalError("valueLabel not connected in IB")
  }
  label.text = state.title
}
```

显然，另一种方式是强制解包 `label`, 这么做可能会造成应用程序崩溃类似于 `fatalError`。 然而，我必须插入 `!`, 当造成程序崩溃后，`!` 并不能给明确的描述。 在这里，使用 上面实现的 `expect` 函数就是一个更好的选择：

```swift
func updateLabel() {
  valueLabel.expect("valueLabel not connected in IB").text = state.title
}
```

### 示例(Example)

至此我们已经实现了一系列非常有用的可选项的扩展。 我将会给出个示例，以便更好的了解如何组合这些扩展