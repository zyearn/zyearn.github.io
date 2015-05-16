---
layout: post
title: "当执行kill -9 PID时系统发生了什么"
date: 2015-03-22 20:46
comments: true
categories: ComputerSystem
---

我们时常遇到这样的需求：要杀死一个正在运行运行的进程。这时候可以在终端输入
```
kill -9 <PID>
```
（其中9的意思是SIGKILL，完整的linux信号请看[这里](http://www.comptechdoc.org/os/linux/programming/linux_pgsignals.html)）之后你再用ps查看进程的时候，会发现那个进程已经被杀掉了。

<!-- more -->
本文将说明在LINUX系统下，用户在终端输入`kill -9 <PID>`之后，整个系统到底发生了什么，我们将深入到内核代码。一开始我在想这个问题的时候遇到了一些问题，比如进程是怎么知道自己收到信号的？在执行进程工作代码的同时还要不断轮询有没有新到的信号吗？代价也太大了吧？那是不是基于什么异步通知的方案呢？在说明LINUX是怎么做的之前，先解释一点基础的概念。

## 什么是信号（SIGNAL）

我自己的理解：信号之于进程，就好比中断之于CPU，是一种信息传递的方式。官方的解释是A signal is an asynchronous notification sent to a process or to a specific thread within the same process in order to notify it of an event that occurred.
一个程序在运行的时候，你可以发各种信号给这个进程，进程对这个信号做出响应。比如你发个SIGKILL给一个进程，该进程就知道用户要杀死它，然后就会终止进程。
一个更常见的例子，你在终端运行一个进程以后，如果是非后台进程，它会在console输出一些log，这时候shell也不能接受输入了，这时候你按下`control+c`，进程就被终止了，在这个过程中你就给这个进程发送了一个信号（SIGINT，interrupt signal），在默认情况下，是终止改进程。
那什么时候是非默认情况呢？这里需要引入信号处理器（signal handler）的概念，你可以为一部分信号编写特定的处理函数，比如在默认情况下，SIGINT是结束进程，你可以修改这个默认行为使它什么都不做（即一个空函数），但是有些信号的行为是无法修改的，比如SIGKILL。

## kill 命令

在LINUX下有一个`kill`的命令，第一次用的同学会以为这是一个“杀死”某个进程的命令，其实并不是很准确。这个命令的作用就是给指定PID的进程发送信号，到底发送什么信号也是由参数指定的，如果不指定信号，默认是发送SIGTERM，它的默认行为是终止进程。其实`kill`也是个程序，它内部会调用system call的kill来发起真正信号传递过程。
更详细的介绍请`man 2 kill`

## shell fork进程

当你敲下命令，按下回车，程序就执行了，其实这里也是个很复杂的过程。涉及到了shell的运行原理，每一个shell的实现都不一样，但核心原理是不变的：`fork`一个子进程，再调用`execve`那一系列系统调用。想了解一个shell是怎么写的，我觉得最好的资料是《Unix/Linux编程实践教程》第八章。本文不会详细解释`shell/fork/execve`，我会在另一篇博客里详细解释当你执行`fork`时，系统发生了什么。

好了，基础知识差不多介绍完了，下面我们进入下一阶段。

## kill -9 PID

我们先讲原理再深入实现细节。所有内核代码都基于3.16.3，本文出现的所有内核代码是我删除了一些错误处理，加锁，临界判断后的结果，所以是比较核心的代码。

执行`kill -9 <PID>`，进程是怎么知道自己被发送了一个信号的？首先要产生信号，执行kill程序需要一个pid，根据这个pid找到这个进程的task_struct（这个是Linux下表示进程/线程的结构），然后在这个结构体的特定的成员变量里记下这个信号。
这时候信号产生了但还没有被特定的进程处理，叫做Pending signal。 
等到下一次CPU调度到这个进程的时候，内核会保证先执行`do\_signal`这个函数看看有没有需要被处理的信号，若有，则处理；若没有，那么就直接继续执行该进程。所以我们看到，在Linux下，信号并不像中断那样有异步行为，而是每次调度到这个进程都是检查一下有没有未处理的信号。


当然信号的产生不仅仅在终端kill的时候才产生的。总结起来，大概有如下三种产生方式：

* 硬件异常：比如除0
* 软件通知：比如当你往一个已经被对方关闭的管道中写数据的时候，会发生SIGPIPE
* 终端信号：你输入`kill -9 <PID>`，或者`control+c`就是这种类型

大概原理就是这个样子的，接下来我们来看一看内核的实现。

## 实现

首先，你在shell里输入`kill`这个命令，它本身就是个程序，是有源代码的，它的代码可以在Linux的[coreutils](http://git.savannah.gnu.org/cgit/coreutils.git/tree/src/)里找到。代码很长，我就不全复制过来了，有兴趣的可以去仔细看看。它的核心代码是长这样的：
```
static int
send_signals (int signum, char *const *argv)
{
    ...
    kill (pid, signum);
    ...
}

int
main (int argc, char **argv)
{
    ...
    send_signals (signum, argv + optind));
    ...
}
```

我们看到最后调用了系统调用`kill`，其代码在Linux内核`linux-3.16.3/kernel/signal.c`中实现。在看kill源码之前，先把这个函数最终要操作的结构体看一下，这个struct很长，只列出了信号相关的部分：
```
struct task_struct {
    ...
/* signal handlers */
	struct signal_struct *signal; /* 一个进程所有线程共享一个signal */
	struct sighand_struct *sighand; 

	sigset_t blocked, real_blocked; /* 哪些信号被阻塞了 */
	sigset_t saved_sigmask;	/* restored if set_restore_sigmask() was used */
	struct sigpending pending; /* 进程中的多个线程有各自的pending */
    ...
}

```
继续看kill系统调用，我将核心代码列在了下面，想看完整版的点[这里](http://lxr.free-electrons.com/source/kernel/signal.c#L2893)。为了方便理解，我给核心逻辑增加了注释。


```
SYSCALL_DEFINE2(kill, pid_t, pid, int, sig)
{
    ...
    return kill_something_info(sig, &info, pid);
}

static int kill_something_info(int sig, struct siginfo *info, pid_t pid)
{
	int ret;

    // 如果pid大于0，就把信号发送给指定的进程
	if (pid > 0) {
		ret = kill_pid_info(sig, info, find_vpid(pid));
		return ret;
	}

    // 如果pid <=0 并且不等于-1，发送信号给-pid指定的进程组
	if (pid != -1) {
		ret = __kill_pgrp_info(sig, info,
				pid ? find_vpid(-pid) : task_pgrp(current));
	} else {    
        //否则发信号给除自己所属进程之外的其它所有进程
		int retval = 0, count = 0;
		struct task_struct * p;

		for_each_process(p) {
			if (task_pid_vnr(p) > 1 &&
					!same_thread_group(p, current)) {
				int err = group_send_sig_info(sig, info, p);
				++count;
				if (err != -EPERM)
					retval = err;
			}
		}
		ret = count ? retval : -ESRCH;
	}

	return ret;
}

```

因为这个`kill_something_info`函数会根据pid的正负来决定是发给特定的进程还是一个进程组，我们下面主要来看发给一个特定进程的情况，即调用`kill_pid_info`：

```
int kill_pid_info(int sig, struct siginfo *info, struct pid *pid)
{
	int error = -ESRCH;
	struct task_struct *p;
   
	p = pid_task(pid, PIDTYPE_PID);
	if (p) {
		error = group_send_sig_info(sig, info, p);
	}

	return error;
}

```

注意这个函数，出现了我们上文提到的`task_strcut`，这个是Linux下表示每个进程/线程的结构体，根据`struct pid`找到这个结构后，就调用了`group_send_sig_info`：


```
int group_send_sig_info(int sig, struct siginfo *info, struct task_struct *p)
{
	int ret;

    ret = do_send_sig_info(sig, info, p, true);

	return ret;
}


int do_send_sig_info(int sig, struct siginfo *info, struct task_struct *p,
			bool group)
{
	unsigned long flags;
	int ret = -ESRCH;

	if (lock_task_sighand(p, &flags)) {
		ret = send_signal(sig, info, p, group);
		unlock_task_sighand(p, &flags);
	}

	return ret;
}

static int send_signal(int sig, struct siginfo *info, struct task_struct *t,
			int group)
{
	int from_ancestor_ns = 0;

#ifdef CONFIG_PID_NS
	from_ancestor_ns = si_fromuser(info) &&
			   !task_pid_nr_ns(current, task_active_pid_ns(t));
#endif

	return __send_signal(sig, info, t, group, from_ancestor_ns);
}


static int __send_signal(int sig, struct siginfo *info, struct task_struct *t,
			int group, int from_ancestor_ns)
{
	struct sigpending *pending;
	struct sigqueue *q;
	int override_rlimit;
	int ret = 0, result;

    // 发送给进程和线程的区别在这里，如果是进程，则&t->signal->shared_pending，否则&t->pending
	pending = group ? &t->signal->shared_pending : &t->pending;

	/*
	 * fast-pathed signals for kernel-internal things like SIGSTOP
	 * or SIGKILL.
	 */
	if (info == SEND_SIG_FORCED)
		goto out_set;
    
    ...

out_set:
    // 把信号通知listening signalfd. 
	signalfd_notify(t, sig);

    // 将sig加入目标进程的信号位图中，待下一次CPU调度的时候读取
	sigaddset(&pending->signal, sig);

    // 用于决定由哪个进程/线程处理该信号，然后wake_up这个进程/线程
	complete_signal(sig, t, group);
ret:
	trace_signal_generate(sig, info, t, group, result);
	return ret;
}
```

可以看到，最终调用到`__send_signal`，设置信号的数据结构，wake up需要处理信号的进程，整个信号传递的过程就结束了。这时候信号还没有被进程处理，还是一个pending signal。

## 信号的处理

内核调度到该进程时，会调用`do_notify_resume`来处理信号队列中的信号，之后这个函数又会调用`do_signal`，再调用`handle_signal`，具体过程就不用代码说明了，最后会找到每一个信号的处理函数，问题是这个怎么找到？

还记得在上文提到的task_struct吗，里面有一个成员变量`sighand_struct`就是用来存储每个信号的处理函数的。
```
struct sighand_struct {
	atomic_t		count;  /* 引用计数 */
	struct k_sigaction	action[_NSIG]; /* 存储处理函数的结构 */
	spinlock_t		siglock;    /* 自旋锁 */
	wait_queue_head_t	signalfd_wqh;   /* 等待队列 */
};


struct k_sigaction {
	struct sigaction sa;
}

struct sigaction {
	__sighandler_t	sa_handler;
	unsigned long	sa_flags;
	sigset_t	sa_mask;	/* mask last for extensibility */
};
```

其中`sa_handler`就指向了信号的处理程序。

## 为某个信号注册处理函数

Linux提供了修改信号的处理函数的system call，具体如何使用这些system call不是本文的重点，如果你有兴趣可以参考《Computer System: A programmer's perspective》8.5节或者参考资料[6]，里面提供了非常详细的例子。

## 总结

这篇文章基于Linux 3.16.3讲述了从shell敲下`kill -9 <PID>`后整个系统发生了什么。主要涉及从用户态的shell程序开始，执行coreutils中kill，之后陷入到内核代码，分析了相关的数据结构，信号产生和传递的原理以及核心代码。

## 参考
[1] http://en.wikipedia.org/wiki/Unix_signal<br>
[2] http://stackoverflow.com/questions/1860175/how-does-a-process-come-to-know-that-it-has-received-a-signal<br>
[3] http://www.linuxjournal.com/article/3985<br>
[4] http://blog.csdn.net/walkingman321/article/details/6167435<br>
[5] http://blog.csdn.net/morphad/article/details/9236975<br>
[6] http://www.alexonlinux.com/signal-handling-in-linux
