---
layout: post
title: "CSAPP: how to write a Web Proxy"
date: 2014-02-21 20:59
comments: true
categories: ComputerSystem
---

这个lab很有意思，要我们实现一个简单的多线程web proxy。看起来很简单，实现起来还是有很多细节需要考虑。这里是一个官方的<a href="http://csapp.cs.cmu.edu/public/proxylab.pdf" target="_blank">介绍</a>。一共写了一天多，功能不是非常完善，代码只能处理`GET`请求。

整体的思路是这样的，proxy作为client和server的中间媒介，client发给请求给proxy，proxy然后把请求转发给server，再从server拿到response，然后再把这个response转发给client。也就是说proxy既是client的服务器，又是server的客户。所以这个lab涉及到了客户端编程和服务器端编程。
<!-- more -->
写完以后将浏览器设置好代理，然后用telnet先测试会比较好。整个lab的原理非常简单，没有高深的算法，然后剩下的就是实现了。

## 编程时需要注意的点

1. 在proxy打开与server的TCP连接的时候，需要调用`gethostbyname`或者`gethostbyaddr`来通过DNS获取server主机的DNS信息，比如ip地址，别名之类的，返回的是一个struct的指针。但是这个struct是一个静态变量，也就是说这些函数不支持多线程的访问，是线程不安全的。解决方法是定义一个mutex来加锁，任意时刻只能又一个线程在调这些函数。

2. 本书的作者提供了robust IO让我们方便地对socket file descriptor进行读写，不要用C库。

3. 调用
        Signal(SIGPIPE, SIG_IGN);
将`SIGPIPE`这个信号忽略掉。如果尝试两次发送数据到一个已经被对方关闭的socket上时，内核会发送一个`SIGPIPE`信号给程序，在默认情况下，会终止当前程序，显然不是我们想要的，所以要忽略它。这里又一个stackoverflow上的<a href="http://stackoverflow.com/questions/108183/how-to-prevent-sigpipes-or-handle-them-properly" target="_blank">相关问题</a>。还有一点，往broken pipe里写会使errno等于EPIPE，而往broken pipe里读会使errno等于ECONNRESET。

4. HTTP/1.1里默认将connection定义为keep-alive，也就是一条TCP连接可以处理多个请求，不用每次都要重新建立TCP连接。我们的简易proxy还无法提供这样的功能，所以在读client发过来的header的时候，如果是`Connection: keep-alive`或者`Proxy-Connection: keep-alive`，我们都要把它们换成`Connection: close`或`Proxy-Connection: close`。

5. 创建线程以后记得要detach掉，否则这个线程结束后不会释放资源直到有别的线程join了这个线程。

6. 如果header里没有`Content-Length`这一项，怎么确定body的长度？这个问题一直没想过直到现在遇到了这个问题。这个长度写到了body里，这种方式叫做`Transfer Encoding`。因为服务器在处理静态对象时，事先知道对象的大小；而在处理动态对象时，无法事先知道body的长度。实现的时候分两种情况来从sock中读数据。

7. 需要正确关闭所有的文件描述符。系统给一个程序能打开的描述符数量做了一个限制。如果是ubuntu下，可以通过`cat /proc/sys/fs/file-max`来查看最大文件描述符数。在proxy运行一段时间，确保描述符不会持续增加。在ubuntu下查看程序打开的描述符方法：找到程序的pid，然后`cat /proc/$pid/fd`。

8. 记得错误处理，这个一直是个麻烦问题。

## 源码

全部的代码放在了<a href="https://github.com/zyearn/csapp-lab/tree/master/proxylab-handout" target="_blank">github</a>。
