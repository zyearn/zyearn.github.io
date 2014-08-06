---
layout: post
title: "博客前端性能优化"
date: 2014-08-05 21:08
comments: true
categories: Program 
---

## 缘由

以前给主页index加了各种统计，字体，微博秀后，主页的载入速度实在太慢，加上本身的博客框架也需要优化，一直都没有时间做（其实是懒），最近终于受不了了，想要把主页的加载速度加快。这个博客的后台操作几乎没有，服务器是github pages，评论用的是第三方插件，所以优化余地只有前端。
<!-- more -->
## 评分

有一个很好的工具叫做[gtmetrix](http://gtmetrix.com/)，这个网站能够根据你的网站提供一份评分和详细的优化策略，本网站在优化前的评分是这样的：

<img src="http://zyearnpic.qiniudn.com/before-opt.jpg" />

Waterfall是这个样子的：

<img src="http://zyearnpic.qiniudn.com/pitfall.jpg" />

## 优化

### Recommendation 1: Remove query strings from static resources

这个没办法，query string是cnzz统计和微博识别我的唯一途径。而且若首页加入了微博秀，会有好几个带query string的http request。解决方案就是直接把微博秀给删了。

### Recommendation 2: Leverage browser caching

这个的意思是，一些可以缓存的静态资源expire时间太短，导致短时间内刷新需要重复加载。因为我用的是github pages，所以我去查了下怎么搞定这件事，结果stackoverflow上有个相同的[问题](http://stackoverflow.com/questions/14798589/github-pages-http-headers)，结论就是目前还不提供修改http header的方法。

### Recommendation 3: Defer parsing of JavaScript

浏览器对js的执行规则是，读到一个js文件就执行这个js文件，导致如果你把js文件放在html的head里的话，浏览器在构建DOM之前忙着执行js了，结果就是用户体验极差。正确的做法是先加载页面，然后再执行js。

一个有效的措施是把js放到页面的最下面，本博客用的是octopress框架，本身自带两个js，加上jquery，一个三个js文件，默认放在了head里，于是我把它放到了页面底端。

### Recommendation 4: Inline small CSS

把一些小的css文件直接inline在html里。

### Recommendation 5: Optimize images

这里说的是图片的压缩，这个图片主要来源是新浪的微博秀和多说的最近评论。后来干脆把它们全部删掉了。

### Recommendation 6: Avoid landing page redirects 

我把www.lifeofzjs.com重定向到了lifeofzjs.com，目的就是为了不让两个地址的A记录同时解析到同一个ip，防止搜索引擎认为这是两个网站，所以这条忽略。

### Recommendation 7: Use a Content Delivery Network (CDN)

感觉没什么必要，静态文件不是很多，而且放在国内的cdn上国外访问就慢了。曾经把jquery换到了新浪的国内cdn，结果测下来国外访问太慢，还是换回了谷歌的cdn。

### Recommendation 8: Make fewer HTTP requests

网上的建议是把若干个js合并成一个大的js，这样在组织结构上显然不好，牺牲一点点速度换来结构的清晰还是很有必要的，所以不合并了。

为了减少非必要的网络流量，网站以前用了两个字体，正文一个字体，标题一个字体，共500K，在拥堵网络环境下，很多时候都是网页加载好了，但字体还在加载，导致用到那个字体的地方的文字就显示不出来，于是干脆把花哨的字体全删了，默认的也挺好。

另外，好多问题都是由第三方插件引起的，比如首页的cnzz统计，微博秀，duoshuo的最近评论，除了统计留着其它的第三方都删掉了。

## 优化结果

这是优化后的waterfall：

<img src="http://zyearnpic.qiniudn.com/pit-fall-after.jpg" />

可以看出页面页面加载只有几百毫秒，从原来的29个请求降到了12个请求。图下方耗时的都是cnzz的东西了，不过这些都是发生在页面加载之后。实际上这是在国外测的速度，cnzz会显得慢一些，在国内cnzz的访问还是非常快的。

现在打开主页基本上不会有卡顿，目的基本实现了。
