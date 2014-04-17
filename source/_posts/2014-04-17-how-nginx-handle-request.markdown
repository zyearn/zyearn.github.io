---
layout: post
title: "nginx源码阅读之 从启动到接受第一个http请求"
date: 2014-04-17 19:32
comments: true
categories: Program 
---

nginx是个高性能的服务器，一个重要的因素是利用了I/O复用（在linux2.6以后的epoll，freebsd的kqueue，solaris上的eventport，在windows上用iocp，本文以epoll为例说明），epoll比poll性能提升太多，不需要一些浪费cpu的轮询操作。但这只是nginx性能高的沧海一粟，它的代码底层做了大量的优化，比如在比较4个字符的字符串的时候，nginx把这个4个字符转化为32位整型然后做整型的比较，以减少底层指令数。除了某些外部的库（openssl，pcre），所有的轮子都是自己造的，比如内存池，字符串，链表，队列，哈希表，红黑树等。
<!-- more -->

任何server本质来说无非就做了这么一件事：创建socket，接着bind，接着listen，最后accept等待tcp连接，从fd里读读写写。随着服务器编程模型的不同，会在不同的线程/进程里accept然后处理请求。本文尝试在框架上说明nginx是怎么做这件事情的。

nginx在大多数情况下是master-worker的形式工作的，因为要使多个worker共享监听同一个端口，所以在fork之前需要把这个socket初始化，然后子进程继承这个socket。

在fork之前，nginx在main函数中调用了一个重要的函数叫`ngx_init_cycle`，它主要用来初始化`ngx_cycle_t`类型的一个全局变量，这个函数接着调用`ngx_open_listening_sockets`，这个函数做的是创建一个新的socket，接着调用bind，接着在这个listenfd上listen，最后将这个listenfd保存在listen`ngx_cycle_t`类型全局变量中的listening数组里。

在fork以后，worker将调用所有注册模块的`init_process`钩子函数（就是回调函数），其中有个核心模块叫`ngx_event_core_module`，它的`init_process`这个钩子被注册为`ngx_event_process_init`(src/event/ngx\_event.c)，在这个函数中，它为每一个在listening数组中的listenfd创建一个connection，以及这个connection对应的读写事件。
然后做了非常重要的一步：将读事件的回调函数设置为`ngx_event_accept`，接着把这个listenfd放到了epoll里。这代表什么意思呢，在`epoll_wait`返回listenfd可读的时候，就回调注册的钩子函数`ngx_event_accept`，这个函数的大致代码如下：
```
void
ngx_event_accept(ngx_event_t *ev)
{
    ...
    // 从listenfd获得一个连接
    s = accept(...);
    ...
    //为该链接获得一个connection
    c = ngx_get_connection(s, ev->log);
    ...

    //回调，主要设置c的读写回调函数，并且加入epoll中
    ls->handler(c);
    ...
}
```

和预期的差不多，accpet一个连接fd，然后通过某个回调函数将fd的读写回调函数设置为http模块相关的函数，接着再放入epoll中。这里比较重要的是`ls->handler(c)`，这个handler通过下面这系列调用（ngx_http_block->ngx_http_optimize_servers->ngx_http_add_listening->ngx_http_init_listenin）被设置为`ngx_http_init_connection`。接下来来看看这个函数中设置事件回调的部分：
```
c->read->handler = ngx_http_wait_request_handler;
c->write->handler = ngx_http_empty_handler;
...
// 将事件放入epoll
ngx_add_event(...);
```

也就是说，当这个fd可读时，调用`ngx_http_wait_request_handler`来处理这个请求，之后的事情就是http模块的解析过程了，这个放在以后在写。随着请求的越来越多，epoll里的事件也越来越多，每次可读或者可写都调用相应的回调函数，并且epoll保证了高并发。以上就是从创建一个listen socket到接受一个http请求的框架，其中省略了很多很多的细节。


