# SwiftMultiThreadDemo

## 多线程基础

### 什么是线程

线程，也被称为轻量级进程，是程序执行的最小单元。一个标准的线程由线程 ID、当前指令指针、寄存器和堆栈组成。一个进程由一到多个线程组成，线程之间又共享程序的内存空间和一些进程级资源。

线程和进程的关系：

![Progress _ Thread](http://oupcsiea7.bkt.clouddn.com/Progress & Thread.png)

### 线程调度优先级

当线程数小于处理器核心数量时，是真正的并发，当大于的时候，线程的并发会受到一定阻碍。这可能也是为什么 Intel 即将要推出的 i7 - 9700k 是 8 核心 8 线程的原因，而不是 i7 - 8700k 那样拥有超线程技术的 6 核心 12 线程的 CPU。

在单核处理多线程的情况下，并发操作是模拟出来的一种状态，操作系统会让这些线程轮流执行一段时间，时间短到足以看起来这些线程是在同步执行的。这种行为称为线程调度。在线程调度中是有优先级调度的，高优先级的先执行，低优先级的线程通常要等到系统已经没有高优先级的可执行线程存在时才会开始执行，这也是为什么 GCD 会提供 Background、utility 等优先级选项。

除了用户手动控制线程的优先级，操作系统还会自动调整线程优先级。频繁进入等待状态的线程被称为 **IO 密集型线程**，很少等待，处理耗时操作长时间占用时间片的线程一般称为 **CPU 密集型线程**，IO 密集型线程比 CPU 密集型线程在线程优先级的调整中，更容易获得优先级的提升。

在线程调度中存在一种*饿死*现象。饿死现象是说，这个线程的优先级较低，而在它之前又有一个耗时的线程执行，导致它无法执行，最后饿死。为了避免这种情况，调度系统通常会提升那些等待时间过长线程的优先级，提升到足够让它执行的程度。

## 线程安全

### 数据竞争

举个例子，线程 1 有一个变量 i，并且在做 i += 1 的操作，线程 2 同时对这个变量做 i -= 1 的操作，线程 1、2 是并发执行的，这时就会发生竞争关系。

### 同步和锁

同步，指在一个线程操作一个数据未结束时，其他线程不得对同一个数据进行访问。为了避免多个线程同事读写一个数据而产生不可预知的结果，我们要将各个线程对这个数据的访问进行同步。

同步最常见的方法是使用锁。每个线程在访问数据之前会先获取锁，并在访问之后释放锁。在锁已经被占用时，试图获取锁，线程会等待到锁重新可用。

#### 信号量（Semaphore）

在 iOS 中，信号量主要表现方式为 `dispatch_semaphore_t`，最终会调用 `sem_wait` 方法。
和 dispatch_semaphore 相关的函数有三个，创建信号，等待信号，发送信号。
信号量是允许并发访问的，可以由一个线程获取，另一个线程释放。

#### 互斥量（Mutex）

互斥量仅允许一个线程访问。互斥量和信号量不同的是，互斥量要求哪个线程获取了，哪个线程就要负责去释放。
在 iOS 中，`pthread_mutex` 可以作为互斥锁。`pthread_mutex` 不是使用忙等，会阻塞线程并进行等待。它本身拥有设置协议的功能，通过设置协议来解决优先级反转的问题：

```C
pthread_mutexattr_setprotocol(pthread_mutexattr_t *attr, int protocol)
```

`NSLock` 也是互斥锁，只不过是用 OC 的方式暴露出来，内部封装了一个 `pthread_mutex`。在 YYKit 源码中，ibireme 大佬频繁使用 `pthread_mutex` 而不是 NSLock，是应为 NSLock 是 OC 类，在使用时会经过消息转发，方法调用等操作，比 pthread 略慢。

```Swift
let lock = NSLock()
lock.lock()
// Todo
lock.unlock()
```

`@synchronized(Obj)` 也是一种便捷的互斥锁创建方式，同事它也是一个递归锁。

#### 读写锁（Read-Write Lock）

读写锁，在对文件进行操作的时候，写操作是排他的，一旦有多个线程对同一个文件进行写操作，后果不可估量，但读是可以的，多个线程读取时没有问题的。
1. 当读写锁被一个线程以读模式占用的时候，写操作的其他线程会被阻塞，读操作的其他线程还可以继续进行
2. 当读写锁被一个线程以写模式占用的时候，写操作的其他线程会被阻塞，读操作的其他线程也被阻塞

在 iOS 中，读写锁主要变现为 `pthread_rwlock_t`。

#### 条件变量（Condition Variable）

条件变量，作用类似于一个栅栏。

1. 线程可以等待条件变量，一个条件变量可以被多个线程等待。
2. 线程可以唤醒条件变量，此时所有等待此变量的线程都会被唤醒。

使用条件变量，可以让许多线程一起等待某个事件的发生，当事件发生时，所有线程可以恢复执行。

在 iOS 中，`NSCondition` 表现为条件变量。

> 介绍条件变量的文章非常多，但大多都对一个一个基本问题避而不谈:“为什么要用条件变量？它仅仅是控制了线程的执行顺序，用信号量或者互斥锁能不能模拟出类似效果？”

> 网上的相关资料比较少，我简单说一下个人看法。信号量可以一定程度上替代 condition，但是互斥锁不行。在以上给出的生产者-消费者模式的代码中， pthread_cond_wait 方法的本质是锁的转移，消费者放弃锁，然后生产者获得锁，同理，pthread_cond_signal 则是一个锁从生产者到消费者转移的过程。

参考链接：[bestswifter iOS锁的博文](https://bestswifter.com/ios-lock/)。

#### 自旋锁（Spin lock）

关于自旋锁，可以查阅 [ibirme 大佬的《不再安全的 OSSpinLock》](https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/)

## Thread

### 创建

Thread 创建有三种方式：

```Swift
// 第一种，手动调用 start
// convenience init(target: Any, selector: Selector, object argument: Any?)
let thread = Thread(target: self, selector: #selector(thread1Action(_:)), object: "Thread1")
thread.name = "Background 1"
thread.start()

// 第二种，类方法
// class func detachNewThreadSelector(_ selector: Selector, toTarget target: Any, with argument: Any?)
Thread.detachNewThreadSelector(#selector(thread2Action(_:)), toTarget: self, with: "Thread2")

// 第三种 performSelector
performSelector(inBackground: #selector(thread3Action(_:)), with: "Thread3")
```

### 线程安全

在 OC 中可以添加 @synchronized() 方法方便的给线程加锁，但是 Swift 中，这个方法已经不存在。@synchronized 实际上在底层是调用了 `objc_sync_enter` 和 `objc_sync_exit` 方法以及一些异常处理。所以忽略异常问题可以简单实现一个 synchronized 方法：

```Swift
func synchronized(_ lock: AnyObject, closure:() -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}
```

经典的售票系统简单模拟：

```Swift
@IBAction func saleTicket(_ sender: Any) {
    
    firstTicketWindow = Thread(target: self, selector: #selector(saleTicketAction), object: "Ticket Window 1")
    firstTicketWindow.name = "Ticket Window 1"
    
    secondTicketWindow = Thread(target: self, selector: #selector(saleTicketAction), object: "Ticket Window 2")
    secondTicketWindow.name = "Ticket Window 2"
    
    thirdTicketWindow = Thread(target: self, selector: #selector(saleTicketAction), object: "Ticket Window 3")
    thirdTicketWindow.name = "Ticket Window 3"
    
    firstTicketWindow.start()
    secondTicketWindow.start()
    thirdTicketWindow.start()
}

@objc func saleTicketAction() {
    
    while ticketCount > 0 {
        synchronized(self) {
            Thread.sleep(forTimeInterval: 0.1)
            if ticketCount > 0 {
                ticketCount -= 1
                print("\(Thread.current.name!) sold 1 ticket, \(self.ticketCount) remains.")
            } else {
                print("Tickets have been sold out.")
            }
        }
    }
}
```

此时如果不加自己定义的 synchronized 方法，控制台会输出以下信息：
![Thread unlock](http://oupcsiea7.bkt.clouddn.com/Thread unlock.png)
很明显的，票务系统已经错乱。

如果加上 synchronized 方法，则会输出正确的信息：
![Thread locked](http://oupcsiea7.bkt.clouddn.com/Thread locked.png)

### 线程间通信

在主线程上显示余票：

```Swift
if ticketCount > 0 {
    ticketCount -= 1
    print("\(Thread.current.name!) sold 1 ticket, \(self.ticketCount) remains.")
                    
    // 主线程显示余票
    self.performSelector(onMainThread: #selector(showTicketNum), with: nil, waitUntilDone: true)
}

@objc func showTicketNum() {
    remainingLabel.text = "Ticket remains: \(ticketCount)"
}
```

## Operation

Operation 是 Apple 对于 GCD 的封装，但是并不局限于 GCD 的先进先出队列。API 更加面向对象化，操作起来十分方便。

### Operation 和 OperationQueue

Operation 相当于 GCD 的任务， OperationQueue 相当于 GCD 的队列。
使用 Operation 实现多线程的具体步骤：
* 将需要执行的操作封装到 Operation 对象中
* 将 Operation 添加到 OperationQueue

### 创建

一般情况下有三种使用方法：

* NSInvocaionOperation

NSInvocation 在 Swift 中已被废除，因为它不是类型安全和 ARC 安全的。

下面是 OC 实现：

```ObjC
- (void)testNSInvocationOperation {
    NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(invocationOperation) object:nil];
    [invocationOperation start];
}

- (void)invocationOperation {
    NSLog(@"NSInvocationOperation: %@", [NSThread currentThread]);
}
```

* BlockOperation

```Swift
let operation = BlockOperation {
    print("An block operation without being added in a queue, the thread is: \(Thread.current)")
}
operation.start()
```

Block Operation 添加执行闭包：

```Swift
let operation = BlockOperation {
    print("Create a block operation in \(Thread.current).")
}
operation.addExecutionBlock {
    print("The block operation has add an execution block in \(Thread.current).")
}
operation.addExecutionBlock {
    print("The block operation has add an execution block in \(Thread.current).")
}
operation.start()
```

* Operation 子类

Operation 子类需要创建一个继承于 Operation 的类，需要重写 `main()` 方法：

```Swift
class CustomOperation: Operation {
    override func main() {
        
        // Things to do
        for _ in 0 ..< 2 {
            print("Cunstom operation in thread: \(Thread.current)")
        }
    }
}
```

使用：

```Swift
let operation = CustomOperation()
operation.start()
```

### OperationQueue

* `OperationQueue` 直接创建为子线程：`let queue = OperationQueue()`。
* `OperationQueue` 获取主线程方法：`OperationQueue.main`。

**将 Operation 添加到 Queue 中 会自动异步执行 Operation 中封装的操作，不需要再调用 Operation 的 start() 方法。**

#### 使用 `addOperation(_:)` 方法把 Operation 添加到队列

```Swift
let queue = OperationQueue()
        
let operation1 = BlockOperation {
    print("Operation 1 has beed added in a queue, in \(Thread.current).")
}
        
let operation2 = BlockOperation {
    print("Operation 2 has beed added in a queue, in \(Thread.current).")
}
        
// Operation1 和 Operation2 执行顺序是不固定的
queue.addOperation(operation1)
queue.addOperation(operation2)
```

#### 使用 `addOperation {}` 方法添加 Operation

```Swift
let queue = OperationQueue()
queue.addOperation {
    for _ in 0 ..< 2 {
        print("A queue add operation with block in \(Thread.current).")
    }
}
```

### OperationQueue 线程间通信

下面以一个伪下载图片的代码来模拟 Operation 线程间通信：

```Swift
let downloadQueue = OperationQueue()

indicator.startAnimating()

downloadQueue.addOperation {
    
    Thread.sleep(forTimeInterval: 1)
    
    let imageURLString = "https://clutchpoints.com/wp-content/uploads/2018/09/lebron-james.png"
    let imageURL = URL(string: imageURLString)
    let data = try? Data(contentsOf: imageURL!)
    
    guard let theData = data else {
        // 如果没有图片数据，回到主线程停止 indicator
        OperationQueue.main.addOperation {
            self.indicator.stopAnimating()
        }
        print("Download failed.")
        return
    }
    let image = UIImage(data: theData)
    
    // 下载完图片回到主线程更新 UI  
    OperationQueue.main.addOperation {
        if let image = image {
            self.imageView.image = image
            self.hideButton.isHidden = false
            self.imageView.isHidden = false
            self.indicator.stopAnimating()
        }
    }
}
```

### 控制 OperationQueue 最大并发数

可以通过 `maxConcurrentOperationCount` 来控制并发数。

```Swift
let queue = OperationQueue()
queue.maxConcurrentOperationCount = 1
queue.addOperation {
    print("First operation - max concurrent number in \(Thread.current).")
}
queue.addOperation {
    print("Second operation - max concurrent number in \(Thread.current).")
}
queue.addOperation {
    print("Third operation - max concurrent number in \(Thread.current).")
}
queue.addOperation {
    print("Fourth operation - max concurrent number in \(Thread.current).")
}
```

### 依赖和完成监听

你可以通过 Operation 的 `addDependency(_ op: Operation)` 方法来添加操作间的依赖关系：
例如 `operation2.addDependency(operation1)` 就是说 Operation1 执行完毕后 Operation2 才会执行。

你也可以通过 `completionBlock` 属性来监听某个操作已经完成。

```Swift
let queue = OperationQueue()

var flag = false
let operation1 = BlockOperation {
    // 模拟一个操作是否成功
    flag = true
    print("Operation 1 in \(Thread.current).")
    Thread.sleep(forTimeInterval: 2)
}

// 监听 Operation 1 是否完成
operation1.completionBlock = {
    print("Operation 1 is completed.")
}

let operation2 = BlockOperation {
    if flag {
        print("Operation 2 in \(Thread.current).")
    } else {
        print("Something went wrong.")
    }
}

operation2.addDependency(operation1)

// 过两秒之后控制台才会打印 Operation1 完成和 Operation2 的执行信息
queue.addOperation(operation1)
queue.addOperation(operation2)
```

### 取消 Operation

可以通过 **Operation 的 `cancel()` 方法** 或 Queue 的 `cancelAllOperations()` 来取消 Operation。

但，值得注意的是，**`cancel()` 方法，它做的唯一做的就是将 Operation 的 isCancelled 属性从 false 改为 true**。由于它并不会真正去深入代码将具体执行的工作暂停，所以我们必须利用 `isCancelled` 属性的变化来暂停 main() 方法中的工作。

```Swift
let queue = OperationQueue()
queue.addOperation {
    for i in 0 ... 100000000 {
        print("i: \(i) in \(Thread.current)")
    }
}
queue.cancelAllOperations()
queue.addOperation {
    print("Second operation in \(Thread.current)")
}

let operation = CustomOperation()
// 将 isCancelled 属性更改为 true
operation.cancel()

// 控制台只会输出第二个 Operation 的执行信息。
```

## GCD

> GCD（Grand Central Dispatch） 是 Apple 推荐的方式，它将线程管理推给了系统，用的是名为 dispatch queue 的队列。开发者只要定义每个线程需要执行的工作即可。所有的工作都是先进先出，每一个 block 运转速度极快（纳秒级别）。使用场景主要是为了追求高效处理大量并发数据，如图片异步加载、网络请求等。

[Dispatch 在 Swift 3 中的改变](https://github.com/apple/swift-evolution/blob/master/proposals/0088-libdispatch-for-swift3.md)

### 任务和队列

* Async：异步任务
* Sync：同步任务

DispatchQueue 是一个类似线程的概念，这里称作对列队列是一个FIFO数据结构，意味着先提交到队列的任务会先开始执行）。DispatchQueue 背后是一个由系统管理的线程池。

DispatchQueue 又分为串行队列和并发队列。

**串行队列使用同步操作容易造成死锁，例如主线程进行同步操作 `DispatchQueue.main.sync {}`。**

### 创建队列

#### 创建串行队列

如果不设置 DispatchQueue 的 Attributes，那么默认就会创建串行队列。

* 串行队列的同步操作：

```Swift
let queue = DispatchQueue(label: "com.demo.Serial1")
// 串行队列做同步操作, 容易造成死锁, 不建议这样使用
queue.sync {
    print("Sync operation in a serial queue.")
}
```

* 串行队列的异步操作：

```Swift
let queue = DispatchQueue(label: "com.demo.Serial2")
// 串行队列做异步操作是顺序执行
queue.async {
    for i in 0 ..< 2 {
        print("First i: \(i)")
    }
}
queue.async {
    for i in 0 ..< 2 {
        print("Second i: \(i)")
    }
}
```

#### 创建并发队列

* 并发队列同步操作是顺序执行

```Swift
let label = "com.demo.Concurrent1"
let qos = DispatchQoS.default
let attributes = DispatchQueue.Attributes.concurrent
let autoreleaseFrequency = DispatchQueue.AutoreleaseFrequency.never
let queue = DispatchQueue(label: label, qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: nil)

// 并发队列同步操作是顺序执行
queue.sync {
    for i in 0 ..< 2 {
        print("First sync i: \(i)")
    }
}
queue.sync {
    for i in 0 ..< 2 {
        print("Second sync i: \(i)")
    }
}
```

* 并发队列异步操作执行顺序不定

```Swift
let label = "com.demo.Concurrent2"
let attributes = DispatchQueue.Attributes.concurrent
let queue = DispatchQueue(label: label, attributes: attributes)
        
// 并发队列做异步操作执行顺序不固定
queue.async {
    for i in 0 ..< 2 {
        print("First async i: \(i)")
    }
}
queue.async {
    for i in 0 ..< 2 {
        print("Second async i: \(i)")
    }
}
```

#### 创建主队列和全局队列

```Swift
let mainQueue = DispatchQueue.main
let globalQueue = DispatchQueue.global()
let globalQueueWithQos = DispatchQueue.global(qos: .userInitiated)
```

### QoS

QoS 全称 `Quality of Service`，在 Swift 中是一个结构体，用来指定队列或任务的优先级。

全局队列肯定是并发队列。如果不指定优先级，就是默认（default）优先级。另外还有 background，utility，user-Initiated，unspecified，user-Interactive。下面按照优先级顺序从低到高来排列：

* Background：用来处理特别耗时的后台操作，例如同步、备份数据。
* Utility：用来处理需要一点时间而又不需要立刻返回结果的操作。特别适用于异步操作，例如下载、导入数据。
* Default：默认优先级。一般来说开发者应该指定优先级。属于特殊情况。
* User-Initiated：用来处理用户触发的、需要立刻返回结果的操作。比如打开用户点击的文件。
* User-Interactive：用来处理用户交互的操作。一般用于主线程，如果不及时响应就可能阻塞主线程的操作。
* Unspecified：未确定优先级，由系统根据不同环境推断。比如使用过时的 API 不支持优先级，此时就可以设定为未确定优先级。属于特殊情况。

### After 延迟

Swift 写法如下：

```Swift
override func viewDidLoad() {
    super.viewDidLoad()
    
    print("View did load.")
    let dispatchTime = DispatchTime.now() + 0.5
    DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
        print("After 0.5 seconds.")
    }
}
```

### 线程间通信

模拟下载单张图片并在 imageView 上展示：

使用 `DispatchQueue.global().async {}` 和 `DispatchQueue.main.async {}`。

```Swift
@IBAction func downloadImage(_ sender: Any) {
    indicator1.startAnimating()
    // let queue = DispatchQueue.global(qos: .default)
    DispatchQueue.global().async {
        sleep(1)
        let imageURL = URL(string: self.imageURLString1)
        let data = try? Data(contentsOf: imageURL!)
        
        guard let theData = data else {
            OperationQueue.main.addOperation {
                self.indicator1.stopAnimating()
            }
            print("Download failed.")
            return
        }
        let image = UIImage(data: theData)
        
        DispatchQueue.main.async {
            if let image = image {
                self.imageView1.image = image
                self.hideButton.isHidden = false
                self.imageView1.isHidden = false
                self.indicator1.stopAnimating()
            }
        }
    }
}
```

### DispatchGroup

组操作，用来管理一组任务的执行，然后监听任务都完成的事件。比如，多个网络请求同时发出去，等网络请求都完成后 reload UI。

步骤：
1. 创建一个 DispatchGroup
2. 在并发队列中进行异步组操作
3. 通过 `group.notify {}` 来组合那些单个的组操作

模拟多图下载操作：

```Swift
@IBAction func downloadImagesInGroup(_ sender: Any) {
    
    indicator1.startAnimating()
    indicator2.startAnimating()
    
    let group = DispatchGroup()
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    var fileURL1 = URL(fileURLWithPath: documentsPath!)
    fileURL1 = fileURL1.appendingPathComponent("LBJ1")
    fileURL1 = fileURL1.appendingPathExtension("png")
    
    var fileURL2 = URL(fileURLWithPath: documentsPath!)
    fileURL2 = fileURL2.appendingPathComponent("LBJ2")
    fileURL2 = fileURL2.appendingPathExtension("jpg")
    
    // 下载图片1
    group.enter()
    DispatchQueue.global().async {
        
        print("Begin to download image1.")
        
        let imageURL = URL(string: self.imageURLString1)
        let data = try? Data(contentsOf: imageURL!)
        
        guard let theData = data else {
            DispatchQueue.main.async {
                self.indicator1.stopAnimating()
            }
            print("Image 1 download failed.")
            return
        }
        
        try! theData.write(to: fileURL1, options: .atomic)
        
        print("Image1 downloaded.")
        sleep(1)
        group.leave()
    }
    
    // 下载图片2
    group.enter()
    DispatchQueue.global().async {
        
        print("Begin to download image2.")
        
        let imageURL = URL(string: self.imageURLString2)
        let data = try? Data(contentsOf: imageURL!)
        
        guard let theData = data else {
            DispatchQueue.main.async {
                self.indicator2.stopAnimating()
            }
            print("Image 2 Download failed.")
            return
        }
        
        try! theData.write(to: fileURL2, options: .atomic)
        
        sleep(1)
        print("Image2 downloaded.")
        group.leave()
    }
    
    // 在主线程展示
    group.notify(queue: .main) {
        
        let imageData1 = try? Data(contentsOf: fileURL1)
        let imageData2 = try? Data(contentsOf: fileURL2)
        
        guard let theData1 = imageData1 else {
            return
        }
        guard let theData2 = imageData2 else {
            return
        }
        
        let image1 = UIImage(data: theData1)
        let image2 = UIImage(data: theData2)
        
        self.imageView1.image = image1
        self.imageView2.image = image2
        self.imageView1.isHidden = false
        self.imageView2.isHidden = false
        self.indicator1.stopAnimating()
        self.indicator2.stopAnimating()
        self.hideButton.isHidden = false
    }
}
```

### DispatchBarrier

栅栏函数，函数之前的任务提交完了才会执行后续的任务：

```Swift
let label = "com.demo.Concurrent3"
let queue = DispatchQueue(label: label, attributes: .concurrent)

queue.async {
    for i in 0 ..< 2 {
        print("First i: \(i)")
    }
}
queue.async {
    for i in 0 ..< 2 {
        print("Second i: \(i)")
    }
}

queue.async(flags: .barrier) {
    print("This is a barrier.")
}

queue.async {
    for i in 0 ..< 2 {
        print("Third i: \(i)")
    }
}
queue.async {
    for i in 0 ..< 2 {
        print("Fourth i: \(i)")
    }
}
```

控制台输出：
![GCDBarrier](http://oupcsiea7.bkt.clouddn.com/GCDBarrier.png)

由此可见，只有当 First 和 Second 执行完毕才会执行 Third 和 Fourth，并且 First 和 Second 执行顺序是不确定的，Third 和 Fourth 也是如此。

### Semaphore

信号量，是锁机制。

> DispatchSemaphore 是传统计数信号量的封装，用来控制资源被多任务访问的情况。

举个例子，一共有两个停车位，现在 A、B、C 都需要停车，A 和 B 先挺的情况下，C 过来了，这时 C 就要等待 A 或 B 其中有一个出来，才会继续停进去。

**注意：在串行队列上使用信号量要注意死锁的问题。**

模拟停车操作：

```Swift
let semaphore = DispatchSemaphore(value: 2)

// semaphore 在串行队列需要注意死锁问题
let queue = DispatchQueue(label: "com.demo.Concurrent4", qos: .default, attributes: .concurrent)

queue.async {
    semaphore.wait()
    print("First car in.")
    sleep(2)
    print("First car out.")
    semaphore.signal()
}

queue.async {
    semaphore.wait()
    print("Second car in.")
    sleep(3)
    print("Second car out.")
    semaphore.signal()
}

queue.async {
    semaphore.wait()
    print("Third car in.")
    sleep(4)
    print("Third car out.")
    semaphore.signal()
}
```

控制台输出：

![GCDSemaphore](http://oupcsiea7.bkt.clouddn.com/GCDSemaphore.png)

由此可见，第一辆车出来了，第三辆车才能进去。

## 本文 Demo

[本文 Demo 已更新到 Swift 4.2](https://github.com/Oniityann/SwiftMultiThreadDemo)

