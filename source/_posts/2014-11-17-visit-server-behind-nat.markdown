---
layout: post
title: "如何访问NAT后的server"
date: 2014-11-17 11:48
comments: true
categories: Program
---

最近项目中有一个需求，需要访问NAT后面的一个restful server，这个NAT是由家用路由器产生的。现在的家用路由器都有端口转发的功能，配合上动态dns解析，这个问题就很容易解决。但是现在问题来了，我们面向的客户是普通用户，对他们而言路由器可能就是透明的，更别说要配置路由器了。所以我们得想其它不让用户参与的解决方案。
<!-- more -->
把问题再说得清楚一些：NAT后面有一台设备，运行着linux，restful server跑在这台设备上，我们需要的做的是使它向外界暴露一个特定的ip和port，外网直接可以对这个ip和port进行请求(我们用curl)。问题大概是下面这个图的样子：

<img src="http://zyearnpic.qiniudn.com/nat_rest.png" />

为了解决这个问题，大致有三种思路：

## NAT打洞

关于NAT打洞的细节请参考之前写的[这篇博文](http://lifeofzjs.com/blog/2014/07/19/how-p2p-in-symmetric-nat/)。思路貌似很简单，在路由器转发表上打个洞，然后所有对这个port的请求都会转发到NAT后的server上。但这是个不能用的方案。

为什么不能用？考虑symmetric NAT的情况，这是四种NAT类型中最严格的一种，只要解决了这一种，那么NAT打洞就可以用。symmetric NAT的问题在于打完洞了以后这个洞两端的ip和port这四个值需要全部确定，restful server没问题，局域网ip和80端口都不变，但外网无法保证每次都用一个port，比如说curl命令，你无法保证curl每次都用相同的port来发请求。因为这个致命问题所以这个方法不能用。

## ssh反向隧道

这个方法网上资料很多。总结来说，需要一台公网服务器来做relay，比如ip是120.120.120.120。在内网机器上运行

```
ssh -g -N -f -R 12345:127.0.0.1:80 -p 22 root@120.120.120.120
```

12345是120.120.120.120的端口，然后访问120.120.120.120上的12345端口，都被重定向到本机的80端口。

但是这个方法不太稳定，连接一直会断，有一些工具来保证稳定性，比如autossh。

## 长连接，请求转发

因为我们对ssh反向隧道内部详细机制和代码不了解，并且稳定性等等方面考虑的原因，打算自己写了一个类似的工具。其实道理很简单，比如公司需要开发一个网络程序，如果对libevent内部机制和代码不熟悉，谁敢用？出了事谁负责？所以现在很多公司都有自己的网络通信库。开源工具的特点是要满足大众，导致了每个功能可能都很平庸，而如果能自己写工具则能针对公司的业务特点来有所侧重。

ssh反向隧道的本质是长连接+请求转发，所以我们也要实现个类似的东西。需要多加两个模块：

1. Nat后面需要有一个client
2. 需要一个公网服务器来跑relayServer

client和relayServer之间通过长连接保持连接。relayServer暴露一个publicip和port，外界通过这个publicip和port请求relayServer。relayServer接受到请求之后，把请求通过长连接转发给NAT后面的client，client收到请求以后再访问同一网段的restful server。这样，我们对publicip:port请求，就等于对NAT内的restful server请求。

架构变为下图所示：

<img src="http://zyearnpic.qiniudn.com/nat_rest_2.png" />

### 实现

因为开发进度和难度等因素的考虑，我们选择了nodejs(关于node的优点和介绍在[这篇文章](http://lifeofzjs.com/blog/2014/03/25/node-glance/)里)来实现这个工具。最好的当然是C，效率上最高，但需要自己写网络库或者用第三方的网络库，而且不能现场调试，所以还是放弃了。

如何维持长连接？

虽然node有内置的net库，但不能保证high availability。所以要选择一个第三方已经包装好的连接库，能断线重连和错误处理的。我们选择了socket.io来实现这个长连接，好像有点大材小用的感觉。

最后这个代码放在了[github](https://github.com/zyearn/vsbnat)上，这个代码对NAT后的所有server适用，不一定要是restful server，只要是在内网的server，有ip和port进行访问，都可以用。
