---
layout: post
title: "无锁是万能药吗"
date: 2016-12-20 21:17
comments: true
categories: Program
---

经常会听到有人这样说，把某个地方的锁换成了无锁（lockfree）以后，性能提高了多少多少倍。
不禁会让人产生疑问：是不是只要有锁的地方，换成lockfree后都可以提高性能呢？

答案是具体情况需具体分析。

一部分朋友觉得用锁会影响性能，其实锁指令本身很简单，影响性能的是锁争用（Lock Contention[^1]），导致scalability非常差[^5]。什么叫锁争用，就是两个线程都想进入临界区，但只能有一个线程能进去，这样就影响了并发度。有兴趣的朋友可以去看看glibc中pthread_mutex_lock的源码实现，在没有contention的时候，就是一条CAS指令，内核都没有陷入；在contention发生的时候，选择陷入内核然后睡觉，等待某个线程unlock后唤醒（详见[Futex](https://en.wikipedia.org/wiki/Futex)）。

“只有一个线程在临界区”这件事对lockfree也是成立的，只不过所有线程都可以进临界区，最后只有一个线程可以make progress，其它线程再做一遍。

所以contention在有锁和无锁编程中都是存在的，那为什么无锁有些时候会比有锁更快？他们的不同体现在拿不到锁的态度：有锁的情况就是睡觉，无锁的情况就不断spin。睡觉这个动作会陷入内核，发生context switch，这个是有开销的，但是这个开销能有多大[^2]呢，当你的临界区很小的时候，这个开销的比重就非常大。这也是为什么临界区很小的时候，换成lockfree性能通常会提高很多的原因。

再来看lockfree的spin[^3]，一般都遵循一个固定的格式：先把一个不变的值X存到某个局部变量A里，然后做一些计算，计算/生成一个新的对象，然后做一个CAS操作，判断A和X还是不是相等的，如果是，那么这次CAS就算成功了，否则再来一遍。如果上面这个loop里面“计算/生成一个新的对象”非常耗时并且contention很严重，那么lockfree性能有时会比mutex差。另外lockfree不断地spin引起的CPU同步cacheline的开销也比mutex版本的大。

lockfree的意义不在于绝对的高性能，它比mutex的优点是使用lockfree可以避免死锁/活锁，优先级翻转等问题。但是因为ABA problem、memory order[^4]等问题，使得lockfree比mutex难实现得多。

除非性能瓶颈已经确定，否则还是乖乖用mutex+condvar，等到以后出bug了就知道mutex的好了。如果一定要换lockfree，请一定要先profile，profile，profile！确保时间花在刀刃上。

[^1]: http://preshing.com/20111118/locks-arent-slow-lock-contention-is/
[^2]: context switch的开销不仅仅是push和pop寄存器，它还引发了cache、TLB、branch predictor等CPU状态的丢失，具体如何测量CS的值，请参考“lmbench: Portable tools for performance analysis”
[^3]: 有同学问无锁和自旋锁有什么区别，不都是在一个循环里spin吗？自旋锁的本质还是应用层的锁，当一个线程持有锁后，被调度出去了，其它线程还是无法继续，而lockfree不是这样的，它可以保证至少一个线程make progress
[^4]: 关于memory order，这是个不错的入门资料：http://www.chongh.wiki/categories/High-performance/
[^5]: A classic paper on how different locking alternatives do and don’t scale: “The Performance of Spin Lock Alternatives for Shared-Memory Multiprocessors”
