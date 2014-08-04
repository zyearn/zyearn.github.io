---
layout: post
title: "在symmetric NAT中怎么实现p2p"
date: 2014-07-19 22:56
comments: true
categories: Program 
---

最近在研究NAT穿越实现p2p技术，这个技术有很多广泛的应用，比如大家最熟悉的qq是怎么实现点对点传输文本的？A在一个局域网里，B在一个局域网里，他们怎么实现通信？这当中有什么困难？除了qq，一般的IM软件都有遇到这个问题，比如skype和facetime。一些下载软件也运用了p2p技术，就是边下载边上传文件块给那些没有这块文件的人，这个技术也要涉及NAT穿越。

详细说之前，我们先说说背景知识。
<!-- more -->
## 背景知识之一：什么是NAT

NAT（Network Address Translation）是将IP 数据包头中的IP 地址转换为另一个IP 地址的过程，通俗来讲，就是局域网，公用一个public IP。那为什么要有这个东西，NAT是用来解决什么问题的？

时光回到上个世纪80年代，当时的人们在设计网络地址的时候，觉得再怎么样也不会有超过32bits位长即2^32台终端设备联入互联网，再加上增加ip的长度（即使是从4字节增到6字节）对当时设备的计算、存储、传输成本也是相当巨大的，想象当年的千年虫问题就是因为不存储年份的前两位导致的，现在想想，不就几个byte吗？我一顿饭不吃就省了好几个G了，但在当时的确是相当稀缺的资源。

后来逐渐发现IP地址不够用了，然后就NAT就诞生了！（虽然ipv6也是解决办法，但始终普及不开来，而且未来到底ipv6够不够用，谁知道呢）。NAT的本质就是让一群机器公用同一个IP。这样就暂时解决了IP短缺的问题。其实NAT还有一个重要的用途，就是保护NAT内的主机不受外界攻击。

## 背景知识之二：什么是p2p

p2p（peer to peer）可以定义成终端之间通过直接交换来共享计算机资源和服务，而无需经过服务器的中转。它的好处是显而易见的，不用服务器中转，不需要受限于服务器的带宽，而且大大减轻了服务器的压力。p2p的应用包括IM（qq，MSN），bittorrent等等。

## 为什么要NAT穿越

要实现p2p，我们要克服的就是NAT穿越。在现在的互联网环境下，一个终端一般都在一个NAT内，NAT会有一个网关路由，对外暴露一个public IP，那么两个都在NAT的终端怎么通信呢？我们不知道对方的内网IP，即使把消息发到对方的网关，然后呢？网关怎么知道这条消息给谁，而且谁允许网关这么做了？

## 一个容易的问题

NAT内的设备怎么和公网服务器通信？

假设路由器ip为`1.2.3.4`，公网服务器ip为`5.6.7.8`，内网机器`192.168.0.240:5060`首先发给路由器`1.2.3.4`，路由器分配一个端口，比如说54333，然后路由器代替内网机器发给服务器，即`1.2.3.4:54333 -> 5.6.7.8:80`，此时 路由器会在映射表上留下一个“洞”，来自`5.6.7.8:80`发送到`1.2.3.4`的54333端口的包都会转发到`192.168.0.250:5060`

但不是所有发往1.2.3.4:54333的包都会被转发过去，不同的NAT类型有不同的做法。下面我们来看几种NAT的类型：

## NAT类型之一：Full Cone

全锥形NAT

IP、端口都不受限。只要客户端由内到外打通一个洞之后（NatIP:NatPort -> A:P1），其他IP的主机(B)或端口(A:P2)都可以使用这个洞发送数据到客户端。

(图片均来自网络)
![full cone](http://zyearnpic.qiniudn.com/full%20cone.png)

## NAT类型之二：Restricted Cone

受限锥形NAT

IP受限，端口不受限。当客户端由内到外打通一个洞之后(NatIP:NatPort -> A:P1)，A机器可以使用他的其他端口（P2）主动连接客户端，但B机器则不被允许。

![recone](http://zyearnpic.qiniudn.com/Restricted%20Cone.png)

## NAT类型之三：Restricted Port Cone

端口受限锥型

IP、端口都受限。返回的数据只接受曾经打洞成功的对象（A:P1），由A:P2、B:P1发起的数据将不被NatIP:NatPort接收。

![pcone](http://zyearnpic.qiniudn.com/Restricted%20Port%20Cone.png)

## NAT类型之四：Symmetric NAT

对称型NAT

对称型NAT具有端口受限锥型的受限特性。但更重要的是，他对每个外部主机或端口的会话都会映射为不同的端口（洞）。只有来自相同的内部地址（IP:PORT）并且发送到相同外部地址（X:x）的请求，在NAT上才映射为相同的外网端口，即相同的映射。

举个例子：

1. client访问A:p1是这样的路径：`Client --> NatIP:Pa1 --> A:P1`
2. client访问A:p2是这样的路径：`Client --> NatIP:Pa2 --> A:P2`

(而在前面的三种NAT中，只要client不变，那么留在路由器上的“洞”就不会变，symmetric NAT会变，端口变)

## 怎么确定自己的NAT类型

为什么要知道自己的NAT类型？这为之后的打洞做准备。RFC专门定义了一套协议来做这件事（RFC 5389），这个协议的名字叫STUN（Session Traversal Utilities for NAT），它的算法输出是:

1. Public ip and port
2. 防火墙是否设置
3. 是否在NAT之后以及NAT的类型

<img src="http://zyearnpic.qiniudn.com/STUN.png" alt="turn" width="280" height="360">

## 穿透(打洞)策略

问题：有两个需要互联的client A和client B

方案：

1. A、B分别与stun server交互获得自己的NAT类型
2. A、B连接一个公网服务器（turn server，RFC5766），把自己的NAT发给turn server，此时turn server发现A和B想要互连，把对方的ip，port，NAT类型发给对方
3. Client根据自身NAT类型做出相应的策略。

<img src="http://zyearnpic.qiniudn.com/turn.png" alt="stun" width="280" height="360">

### If {有一方对称NAT}

因为每一次连接端口都不一样，所以对方无法知道在对称NAT的client下次用什么端口。
无法完全实现p2p传输（预测端口除外），需要turn server做一个relay，即所有消息通过turn server转发

### Else if {有一方是Full Cone}

一方通过与full cone的一方的public ip和port直接与full cone通信，实现了p2p通信。

### Else if {有一方是受限型NAT(两种)}

受限型一方向对方发送“打洞包”，比如”punching…”，对方收到后回复一个指定的命令，比如”end punching”，通信开始。这样做理由：受限型一方需要让IPA:portA的包进入，需要先向IPA：portA发包。实现了p2p通信。

## 对称NAT实现p2p的一种方法

我们通过上述的讨论可知，symmetric NAT好像不能实现p2p啊？其实不然，能实现，但代价太高，这个方法叫端口预测。

基本思路：

1. A向B的所有port(0~65535)发包，让路由器知道来自B的所有端口都转发到A
2. B向A的所有port(0~65535)发包，让路由器知道来自A的所有端口都转发到B
3. 于是连接完成了

## 参考资料

* webRTC： http://blog.csdn.net/kl222/article/details/17198873#\_Toc381116530
* Open source STUN server software：https://github.com/jselbie/stunserver/wiki
* A Python STUN client for getting NAT type and external IP：https://github.com/jtriley/pystun
* https://github.com/node/turn-client
* http://think-like-a-computer.com/2011/09/16/types-of-nat/
* NAT类型与穿透 及 STUN TURN 协议：http://nodex.iteye.com/blog/1488719
* stun client初试：http://blog.csdn.net/ga6840/article/details/6187084
* P2P在NAT和STUN： http://blog.csdn.net/A1989A132/article/details/17139003
* http://bbs.csdn.net/topics/360183462
* http://bbs.csdn.net/topics/320164607
