---
layout: post
title: "CSAPP: Shell Lab"
date: 2014-02-18 15:46
comments: true
categories: ComputerSystem
---

这个实验要求我们写一个简单的shell，能够执行一些内置的命令和系统提供的程序，比如echo和ps，这里是详细的<a href="http://csapp.cs.cmu.edu/public/shlab.pdf" target="_blank">要求</a>。这个shell需要提供最基础的功能，前台执行程序，后台执行程序，能从terminal接受SIGINT(ctrl+c)信号和SIGTSTP(ctrl+z)信号来终止和停止程序。

整体框架是这样的：从stdin读入用户命令，然后parse这个命令，如果是内置命令(比如quit，退出shell的命令)，则立刻执行，否则`fork`一个子进程，用`execve`把子进程的地址空间替换为相应的程序。另外为了支持用户发送信号给shell，还需要写3个信号处理程序，分为处理SIGCHLD, SIGINT和SIGTSTP。

<!-- more -->
这个lab里不要求我们写管道的功能，比如`ls | grep "abc"`，如果要写的话也比较方便，用pipe就可以实现，有兴趣的同学可以自己实现，这里需要注意每个进程一定把不用的file descriptor关闭掉。原因是在`fork`之前要初始化管道，于是父子进程的管道descripor指向的file table的`ref count`是2，如果父子进程不关闭它不需要的读写描述符，那么资源不回收是小事，更要命的是子进程可能会一直读不到管道EOF然后一直等待管道另一方的输入。

## 需要注意的一些东西：

1. 需要修改子进程的进程组ID。原因是，fork出来的子进程和父进程的进程组ID是相同的，所以启动我们的shell后按ctrl+c发送SIGINT信号给shell，会同时发给shell和shell的子进程，包括后台进程，然后这个进程组的进程都将会被关闭。这显然不是正确的，我们的预期是只发给shell，然后由信号的handler来处理这个信号（如果有前台进程，那么发送SIGINT给这个进程组；否则就什么都不做）。所以在`fork`之后`execve`之前需要调用`setpgid(0, 0)`，这个函数把当前进程的进程组id设置为当前进程的进程号。

2. 当shell接收到用户发来的SIGINT或SIGTSTP时，shell需要将这个信号转发相关的进程组，而不是单个进程，所以在用kill函数的时候第一个参数是`-pid`。

3. 在fork之前，主进程需要先用`sigprocmask`函数来block信号SIGCHLD，然后再unblock，这样做的目的是防止`addjob`和`deletejob`乱序执行。在某种调度顺序下，子进程先完成任务，发送SIGCHLD给父进程，父进程于是执行handler来处理，其中需要调用`deletejob`，这个时候`addjob`可能没有执行。注意在子进程也要unblock这个信号。

4. 程序需要处理别的程序给子进程发送信号的情况，此时的shell需要正确处理。比如，子进程自己给自己发送了一个SIGTSTP，然后kernel会给shell发送一个SIGCHLD（子进程终止或停止，kernel都会给父进程发送SIGCHLD），shell需要正确地输出相关信息到标准输出。

## 拓展

这个shell功能非常基础，接下来为它提供一些高级功能，这些高级功能会更新到我的第三版实现中。

1. 管道。虽然上面说了管道实现起来比较容易，其实实际实现起来还是有很多值得讨论的地方，比如多级管道怎么实现呢？我认为一个比较好的实现方法是实现一个自顶向下的parser，输出一个语法树，递归地对它进行处理即可。

2. 重定向。这个比较简单，只要打开文件，dup文件描述符到标准输出或标准输入即可。

## 源码

这个lab我分别为第二版和第三版做了两次，第二版的代码在[这里](https://github.com/zyearn/csapp-lab-2e/tree/master/shlab-handout)，第三版的代码在[这里](https://github.com/zyearn/csapp-lab-3e/tree/master/shlab-handout)。
