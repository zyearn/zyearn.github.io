---
layout: post
title: "初探Node.js"
date: 2014-03-25 12:59
comments: true
categories: Program
---

## 什么是node.js

[官网链接](http://nodejs.org)

简单来说，node.js可以让javascript运行在服务器端，javascript最早运行在浏览器中，为web页面添加交互。而node.js的出现使javascript在后台（脱离浏览器环境）运行。Node.js采用了Google V8虚拟机来解释和执行javascript代码。
<!-- more -->
有了node.js，就可以不用nginx/Apache这类server软件了(不代表在生产环境中完全不用)。因为*node.js本身就是服务器*，nginx/Apache是用C写的服务器，一个server做的就是帮你做掉了TCP/IP层和HTTP协议层的解析，底层无非就是写socket监听，解析协议头协议体，然后发包含html的response。用js照样写。

## 一个例子

下面一段代码是我自己写的超级简易的例子，实现了一个加法器，这个程序接受两个输入，然后返回这两个输入的和给调用者：

```
var http = require("http");
var url = require("url");

http.createServer(function(request, response) {
    response.writeHead(200, {"Content-Type": "text/plain"});

    var params = url.parse(request.url, true).query;
    var input1 = params.number1;
    var input2 = params.number2;

    var n1 = new Number(input1);
    var n2 = new Number(input2);
    response.write((n1+n2).toString());
    response.end();
}).listen(8080);

console.log("adder Running...");
```
将这份代码保存为adder.js，要启动这个应用程序，安装好node后，只需在终端输入
```
node adder.js
```
程序就跑起来了。我们来测试一下，在web浏览器里输入`http://localhost:8080/?number1=10&number2=22`看看结果吧。到这里可以直观地看到，nodejs就是个服务器，下面来看看它的优点。

## 优点

*   像JAVA和PHP，每个连接都会有个新的线程，每个线程都要吃掉2MB的内存，所以即使在8GRAM的系统上，最大的并发连接也才4000。这就导致了，服务器的瓶颈在于能够处理并发的数量。

    Node解决这个问题的方法是：事件驱动，非阻塞IO。所以Node非常适合处理高性能并发。

*   Node.js不需要像传统的框架，比如Django，一板一眼地放在nginx/Apache之后，这是一个质的变化。

*   js的匿名函数和闭包非常适合事件驱动和异步编程。

*   前端工程师瞬间变后台...

## 缺点

*   可靠性低。

*   单进程单线程，无法利用多核。

*   DEBUG 困难。

*   到处callback，容易出糟糕的代码。

## 生产环境

在nodeJS的App Server前面一般会放个nginx做反向代理和负载平衡。

但也由直接纯用nodejs的，因为nodejs的http库完整实现了HTTP1.1的全部功能，并发性能也好。

下面这个链接是那些用nodejs开发的项目：[https://github.com/joyent/node/wiki/Projects,-Applications,-and-Companies-Using-Node](https://github.com/joyent/node/wiki/Projects,-Applications,-and-Companies-Using-Node)

## 参考文档

[1] [http://www.ibm.com/developerworks/cn/opensource/os-nodejs/](http://www.ibm.com/developerworks/cn/opensource/os-nodejs/)

[2] [一个完美的入门教程](http://www.nodebeginner.org/index-zh-cn.html)
