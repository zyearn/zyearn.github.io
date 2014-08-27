---
layout: post
title: "服务器推送技术"
date: 2014-08-13 23:06
comments: true
categories: Program
---

服务器推送技术在现时代的网站中越来越流行，比如说，在你刷着微博的时候，有好友私信你，这时候后台的消息会实时推送到前台，在不刷新页面的前提下提示用户这条消息，显然这条消息是被“推”到客户端的，那么这个是怎么实现的呢？
<!-- more -->
## 推送技术

一般的服务器Push技术包括：

1. 基于 AJAX 的长轮询（long-polling）方式，服务器Hold一段时间后再返回信息，然后前端再往后端发起请求，以此往复

2. HTTP Streaming，通过iframe和script标签完成数据的传输，这种方法近来已经很少被使用

3. TCP 长连接

4. HTML5新引入的WebSocket，可以实现服务器主动发送数据至网页端，它和HTTP一样，是一个基于HTTP的应用层协议，跑的是TCP，所以本质上还是个长连接，双向通信，意味着服务器端和客户端可以同时发送并响应请求，而不再像HTTP的请求和响应

上述的1和2统称为comet技术，这里有个简单的介绍：[Comet：基于 HTTP 长连接的“服务器推”技术](http://www.ibm.com/developerworks/cn/web/wa-lo-comet/)

## socket.io

前些日子由于项目网站的需求，后台会产生一些提示用户的警告消息，为了实现在用户正常浏览网页的前提下，后台通知实时推送到前端显示。

综合调研下来，发现是nodejs的socket.io比较成熟地解决了这件事情。它是一个实时通信的框架，天生就是为了服务器端和客户端的双向通信。在它的[官网](http://socket.io/)上，提供了一些最简单的应用，其中一个就是多人在线聊天室，用socket.io实现的代码逻辑非常清楚。

socket.io是WebSocket的一个开源实现，对不支持websocket的浏览器降级成comet / ajax轮询，socket.io的良好封装使代码编写非常容易。

## socket.io的部署

它的部署方案极其简单，结合express框架，按照官网文档，几行代码就实现了一个实时通信server。它和Nginx/apache共存，原来的服务器还是提供原来的功能，新增的这台实时通信server只负责消息的推送。

需要连上这台server也很简单，需要在前端js中加入:

```
<script src="/socket.io/socket.io.js"></script>
<script>
  var socket = io.connect('http://<serverIP>:<port>');
</script>
```

实际上，利用服务器推送技术，我们能实现好多平常HTTP协议无法办到的事情。

## 移动端的实时推送

上述所讨论的所有东西都是Web端的实时通信，未来是属于移动端的，显然移动端的实时推送也非常重要。

在移动端主要有以下两个技术：XMPP 和 MQTT，有兴趣的同学可以自己去了解一下。
