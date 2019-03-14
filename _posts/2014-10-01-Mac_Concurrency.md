---
layout    : post
title     : Mac_Concurrency
date      : 2014-10-01
categort  : CSE
tags      : [Mac, Concurrency]
published : true
---


<!-- more -->

# 并发和程序设计

## 摆脱Threads线程

[Dispath Queues](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationQueues/OperationQueues.html#//apple_ref/doc/uid/TP40008091-CH102-SW1) 分为串行和并行队列，但都是FIFO的结构，总是按照加入的顺序来处理任务，无论串行或者并行。要加入到分发队列的任务必须是包装成函数或者block的形式。

[Dispatch Sources](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/GCDWorkQueues/GCDWorkQueues.html#//apple_ref/doc/uid/TP40008091-CH103-SW1) 是一种机制，异步的处理系统时间. DS类型有：定时器， 信号， Descriptor-related events， Process-related events， Mach port events， 自定义的触发事件。

[Operation Queues](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW1) 是cocoa框架下的并发队列，具体实现为：NSOperationQueue，这是一个抽象类，自己的任务需要定义为其子类。任务对象会产生KVO通知，用于监视。这个Operation Queues总是并行执行的，但是会有一些技巧，使其串行执行。

要确认并发是否必要，并确保主线程只用来处理UI事件。 GCD Operation Queues 都不能满足实时性的要求，如果有这方的需求，就需要自己设计线程。

# 操作队列

## 关于operation objects

NSOperation，是抽象类，系统已经提供了两个子类：NSInvocationOperation，NSBlockOperation 他们都具有以下的特性

1. 支持 配置各个op之间的依赖关系，比如要求一个op要在其他op完成之后才能运行，具体[Configuring Interoperation Dependencies](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW17)
2. 支持 添加op运行完成后的回调block，在任务完成后运行[Setting Up a Completion Block](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW33)
3. 支持 KVO来监视op的运行状态[KVO](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html#//apple_ref/doc/uid/10000177i)
4. 支持 [设定op优先级](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW31)
5. 支持 halt

NSOperation 的 isConcurrent方法可以告知，相对于调用op的start方法的那个线程，这个op是否是并发运行的，也就是说是否在calling thread

NSInvocationOperation 使用selector提取任务（这是开发人员事先写好的）。
```Objective-C
NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
                    selector:@selector(myTaskMethod:) object:data];

NSBlockOperation* theOp = [NSBlockOperation blockOperationWithBlock: ^{
      NSLog(@"Beginning operation.\n");
      // Do some work.
   }];
```

## 自定义op类

- 继承于NSOperation 
- 实现包含 initialization 方法和main方法

### 响应“取消”事件

一个op可能随时取消，op对象应该处理那些为此op而分配的资源。要支持取消事件，开发人员必须，在任务代码中周期性的调用isCancelled方法，当此方法返回YES时，立刻返回。适合isCancelled调用的地方

- 在做任何实质性任务之前
- 在每一次任务循环中，甚至更加频繁
- 在任何可以相对容易的终止任务的地方

```Objective-C
- (void)main {
   @try {
      BOOL isDone = NO;
      while (![self isCancelled] && !isDone) {
          // Do some work and set isDone to YES when finished
      }
   }
   @catch(...) {
      // Do not rethrow exceptions.
   }
}
```

### 自己配置并发

op类的对象默认是syn，同步执行的，也就是在调用(start)者的线程执行任务（main方法中的东西），然而 operation queues提供了并发的线程。如果要自己配置并发，需要override

method|option|Description
------|------|-------
start | 必须的 |manually执行op需要通过调用start方法，在此处set up the thread or other execution environment  in which to execute your task 
main  |可选的 |op的任务通常放在这个方法中，会显得代码清洁有序，但是放在start方法中，技术上完全可以
isExecuting和isFinished | 必须的 | 要注意 这个方法很可能被多个其他线程调用，一定要安全
isConcurrent  |必须的| 

举例

```Objective-C
@interface MyOperation : NSOperation { BOOL executing, finished; }
- (void)completeOperation;
@end
@implementation MyOperation
- (id)init {
    self = [super init];
    if (self) {
        executing = NO;
        finished = NO;
    }
    return self;
}
- (BOOL)isConcurrent { return YES; }
- (BOOL)isExecuting  { return executing; }
- (BOOL)isFinished   { return finished; }
- (void)start { // Always check for cancellation before launching the task.
   if ([self isCancelled]) {
      // Must move the operation to the finished state if it is canceled.
      [self willChangeValueForKey:@"isFinished"];
      finished = YES;
      [self didChangeValueForKey:@"isFinished"];
      return;
   }
   // If the operation is not canceled, begin executing the task.
   [self willChangeValueForKey:@"isExecuting"];
   [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
   executing = YES;
   [self didChangeValueForKey:@"isExecuting"];
}
- (void)main {
   @try {/* Do the main work of the operation here. */ [self completeOperation]; }
   @catch(...) { /* Do not rethrow exceptions.*/ }
} 
- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"]; 
    executing = NO;
    finished = YES; 
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}
@end
```

### KVO兼容 ？

## 自定义执行行为

- 执行顺序首先是看是否准备好，然后看优先级
- 改变优先级：setQueuePriority:
- 优先级 只适用于在同一opq（openeration queue）如果一个应用有不同opq，那么优先级仅在自己所处的opq中起作用


一个线程的优先级从0.0到1.0变化，默认是在0.5。要设定优先级必须在加入opq之前调用 setThreadPriority:(注意和上面的方法不同)，这个改变只影响main方法的优先级，其他部分的执行优先级仍然不变。

推测，这个优先级是面向系统内核的，和上面的优先级有不同的意义

完成回调块 setCompletionBlock:


## 实现op类的要点

- Avoid Per-Thread Storage：never associate any data with a thread that you do not create yourself or manage
- Keep References to Your Operation Object As Needed

错误处理

## 执行op

opq 都是并发执行的

创建opq NSOperationQueue* aQueue = [[NSOperationQueue alloc] init];

添加
```Objective-C
[aQueue addOperation:anOp]; // Add a single operation
[aQueue addOperations:anArrayOfOps waitUntilFinished:NO]; // Add multiple operations
[aQueue addOperationWithBlock:^{
   /* Do something. */
}];
```
使用setMaxConcurrentOperationCount:1尽管如此，执行顺序，仍然有几个因素影响，比如是否readiness。所以串行opq的表现和串行GCD仍然不同。[Configuring Interoperation Dependencies](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW17)

### 手动执行op

- isReady 返回YES前不会执行，这个方法也用在线程的依赖管理中
- 调用start方法，开始执行。和调用main相比，start方法可以进行一些执行前检查，做KVO通知等等，所以正确的做法是调用start
- 一旦加入opq就无法取消，唯一的办法是cancel
- waitUntilFinished 会block调用线程 等待op完成，最好不要这样，主线程阻塞不是好的表现。
- 挂起 setSuspended:针对的是opq， 这不会影响已经在执行的op，而是阻止新的op执行。

执行op的办法，典型的就是加入到operation queue中，但是也可以直接调用start方法来进行

# Dispatch Queues

所有的dq都是FIFO started in the same order that they were added

dq类型

- Serial queues execute in the same order that they were added 可以创建多个dq, 每个dq之间是并发的
- Concurrent queues（也即是global dispatch queue） 并发的执行一个或多个任务，启动（start）顺序还是按照添加的顺序来的。系统提供了四个此类型，但是优先级不同的q，自己也可以创建
- main dispatch queue 全局可见，serial,在主线程执行

## 使用blocks 实现任务

- block可以捕捉标量值，但不要捕捉大型数据结构和指针引用类型的数据
- 如果 一个q内的task要共享数据，使用[context pointer](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationQueues/OperationQueues.html#//apple_ref/doc/uid/TP40008091-CH102-SW13)
- 如果block创造了多个对象，最好在@autorelease域内进行

## 创建和管理dq

### 并发队列

使用 系统提供的全局并发队列，对于每一个app共四个：

dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); 第二个参数保留，必须为0。第一个优先级参数，由高到低：DISPATCH_QUEUE_PRIORITY_HIGH（*\_DEFAULT, *\_LOW, *\_BACKGROUND）

注意这一段：tasks in the high-priority concurrent queue execute before those in the default and low-priority queues. Similarly, tasks in the default queue execute before those in the low-priority queue.

### 串行队列

串行队列有一个系统提供的全局串行q，但是那是在主线程执行，使用要小心。dispatch_get_main_queue

串行队列 在任务执行有顺序要求时有用。串行队列，通常需要自己创建，可以创建任意数量个。尽量使一个串行q中的任务有相似purpos

dispatch_queue_t queue;
queue = dispatch_queue_create("com.example.MyQueue", NULL);

对于自定义的q，如果是传递过来的value，那么在使用前应该retain，用完后release。

- dispatch_set_context
- dispatch_get_context

 dispatch_set_finalizer_f  设定q的清理函数

## 添加任务到队列

### 添加单个任务
dispatch_async 和 dispatch_async_f添加任务，但是有时候也需要同步添加来解决类似竞争的问题： dispatch_sync and dispatch_sync_f 这会阻塞当前线程。直到添加的任务被执行完。

注意在线性q中的任务如果向自己所在q同步添加其他任务，就会出现无休止的等待，死锁。

### 添加完成回调块

- 首先retain 传递过来的q
- 然后异步提交 包装了回调块的任务 到默认权限的全局并发队列中
- 包装了回调块的任务为：
    - 原任务本身
    - 异步提交回调块到参数q中
    - release q

```Objective-C
void average_async(int *data, size_t len, dispatch_queue_t queue, void (^block)(int)) {
    // Retain the queue provided by the user to make
    // sure it does not disappear before the completion
    // block can be called.
    dispatch_retain(queue); // 前面说过 传过来的q需要retain
 
    // Do the work on the default concurrent queue and then
    // call the user-provided block with the results.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int avg = average(data, len);
        dispatch_async(queue, ^{ block(avg);});
 
        // Release the user-provided queue when done
        dispatch_release(queue);
   });
}
```

执行的过程应该是，主线程提交后返回，原任务在并发队列（默认优先级）中执行，原任务完成后，处理块又被提交到q中准备执行。

并发执行循环结构(不相互依赖的，distinct from all other iterations)的替换：使用 dispatch_apply

挂起和重启 q： dispatch_suspend 和 dispatch_resume

## 信号量

提交的任务 需要处理一些有限的资源,使用 步骤

1. 当 dispatch_semaphore_create 信号量时，可以指定一个正数，代表资源数
2. 在每个任务中，调用dispatch_semaphore_wait来等待信号
3. 当*wait返回时，表明资源已经得到，可以进行工作
4. 任务完成，需要释放，by dispatch_semaphore_signal

## Waiting on Groups of Queued Tasks

- dispatch_group_async
- dispatch_group_wait

## Dispatch Queues and Thread Safety

# dispatch sources

- 定时器
- UNIX 信号
- 描述符
- 进程处理相关信号
- mach port
- 自定义源

dispatch source 替换那些处理系统相关事件的 回调函数。配置ds（dispatch source）时，要指明需要监视的事件，和dispatch queue，和处理代码。当事件来到时，ds就会提交处理代码到dq中进行处理。

ds会不断地，重复的处理指定的事件，知道被取消。如果事件到达而前一个未能处理，会出现合并现象：数据会被替换，或者更新。。。取决于具体情况

## 创建 dispatch source

创建ds包含创建ds本身，和创建事件源

- 创建ds：dispatch_source_create
- 配置ds
    - 指定处理代码 event handler
    - 对于定时器源 需要设定定时器源  dispatch_source_set_timer
- 可选的 ：Installing a Cancellation Handler
- 开始  dispatch_resume

## 创建 event handler

dispatch_source_set_event_handler or dispatch_source_set_event_handler_f function

从dispatch source 中获取数据，（ get information about the given event from the dispatch source） dispatch_source_get_handle， dispatch_source_get_data，dispatch_source_get_mask

使用 dispatch_source_set_cancel_handler or dispatch_source_set_cancel_handler_f 来安装取消handler

dispatch_set_target_queue 改变目标队列 

## 举例

### 定时器 

```Objective-C
dispatch_source_t CreateDispatchTimer(uint64_t interval, uint64_t leeway, dispatch_queue_t queue, dispatch_block_t block) {
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
} 
void MyCreateTimer() {
    dispatch_source_t aTimer = CreateDispatchTimer(30ull * NSEC_PER_SEC, 1ull * NSEC_PER_SEC, dispatch_get_main_queue(), ^{ MyPeriodicTask(); });  
    if (aTimer) {
        MyStoreTimer(aTimer);
    }
}
```

- leeway 安全裕度 误差
- 使用dispatch_time和dispatch_walltime的区别，前者使用系统时间，后者好像基于间隔，后者适用于时间间隔交大的场合
- 创建的timer要有引用存在，不要被系统release了

### 文件描述符

### 信号 signals

没啥用

```Objective-C
void InstallSignalHandler() {
    // Make sure the signal does not terminate the application.
    signal(SIGHUP, SIG_IGN);
 
    dispatch_queue_t  queue  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGHUP, 0, queue); 
    if (source) {
        dispatch_source_set_event_handler(source, ^{ MyProcessSIGHUP(); }); 
        // Start processing signals
        dispatch_resume(source);
   }
}
```

通常 程序使用 sigacton 来install 信号处理函数，当sig一旦来到时，就进行同步处理。如果仅需要得到sig到达的通知，而并不想actually handle the signal 可以使用 signal dispatch source 来异步的处理信号

sds(signal dispatch sources) 不是替代sigaction的替代品，因为后者是同步处理的，可以捕捉信号，以阻止信号terminate app。 sds只能够帮你monitor 信号的到达。

sds是在dq上asyn执行的，所以可以避免一些 sifaction遇到的问题。比如，对处理函数没什么限制，这个特点好处是增加了灵活性，缺点是latency

### moitor 进程

Monitoring the death of a parent process

```Objective-C
void MonitorParentProcess() {
    pid_t parentPID = getppid();
 
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC, parentPID, DISPATCH_PROC_EXIT, queue);
    if (source){
        dispatch_source_set_event_handler(source, ^{ 
            MySetAppExitFlag(); // 自己的处理
            dispatch_source_cancel(source);
            dispatch_release(source);
      });
      dispatch_resume(source);
   }
}

```

## 取消dipatch source

使用dispatch_source_cancel 这是个异步的操作。

## supend 和 resume ds

dispatch_resume 和 dispatch_suspend

- 这两个必须是平衡的
- suspend之后，到达的事件会“accumulated累积” 直到resume。resume之后事件会发生合并，而不是逐个都处理。


# Migrating away from threads

## 消除锁

### 实现异步锁

多个线程 试图使用 互斥资源：
```Objective-C
ispatch_async(obj->serial_queue, ^{
   // Critical section
});
```
### 同步执行关键区

线程的运行必须要等待另一个完成了才能继续：
```Objective-C
dispatch_sync(my_queue, ^{
   // Critical section
});
```

## 提升循环
dispatch_apply or dispatch_apply_f function

## 消除join
dispatch_group_async or dispatch_group_async_f

## 生产者-消费者

## 消除信号量
use dispatch semaphores instead

## 消除 run-loop

## 兼容posix

应该避免 在gcd中调用pthread
