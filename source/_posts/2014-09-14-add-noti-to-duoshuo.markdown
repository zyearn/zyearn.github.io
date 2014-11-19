---
layout: post
title: "为多说增加评论推送"
date: 2014-09-14 10:30
comments: true
categories: Program
---

先说下为什么会有这篇文章。

曾经在搭博客的时候，使用的是disqus作为评论插件，使用了一阵后发现它有两个缺点，首先，它的加载速度非常慢，其次，很多人都没有disqus账号导致要注册才能评论。于是想找个本土化的评论系统，满足我的加载速度要求和可以通过社交平台账号登陆然后评论的要求。
<!-- more -->
调查下来发现[duoshuo](http://duoshuo.com/)这款评论插件比较符合，速度快，社交网站登录，还提供邮件提醒功能，就决定用它了！

问题很快就出现了，多说只有在一个用户第一次评论完，另外一个用户回复第一个用户的时候，才会有邮件通知说“xxx回复了你”，也就是说如果不点“回复某人”的按钮，而直接留言，多说是不会邮件提示你有留言了。不知道多说为什么不解决这个问题，流量太大不好解决？反正让人很不舒服。

那就让我们来解决这个问题。调查了下，大概有下面两种思路：

1. 调用duoshuo的API
2. 爬下duoshuo的admin页面，里面有admin的所有评论

## 调用duoshuo的API

多说开放了获取某一篇文章评论的API，但这个API有个限制就是这篇文章一定要有个unique key才能获取。而这个unique key本身就是可有可无的，我现在所有的文章都没有这个key。如果要用API的话，要给所有的文章加上这个key，还得保证以后所有的文章都要自动生成这个key，当然手动也可以，就是太麻烦。

更麻烦的是，对于每篇新的文章，我都要在调API的地方注册这个新的key，之后才会获取到这篇文章的评论。太麻烦了，放弃这种方法。

## 爬虫

登录多说的admin页面，会发现所有的评论都列在页面上，那直接把它们爬下来不就行了。定时运行爬虫脚本，如果这次爬的评论数比上次爬的多，那么说明有新的评论。

这里的爬虫是用nodejs写的，因为它发起一个自定义header的get请求实在太容易了。具体应该发什么，在浏览器中打开审查元素看一下浏览器发送请求带了哪些header就可以。admin页面如果不设置cookie是无法登录的，所以这里我们要模拟浏览器设置cookie来发送GET请求。马上试了下，发现爬下来的页面什么都没有，定神再看，它的评论列表是通过ajax拿到然后通过jquery的插件画出来的。

于是问题就变成了，模拟发送这个ajax，然后分析返回数据得出评论数，和上一次的结果比较，若大于，则有新评论。好，开始写程序，header比较重要，正确设置好cookie才能拿到数据，在我浏览器中是下面这样的：

```
var options = {
    hostname: 'zyearn.duoshuo.com',
    port: 80,
    path: '/api/posts/list.json?order=desc&source=duoshuo%2Crepost&max_depth=1&limit=30&related%5B%5D=thread&related%5B%5D=iplocation&nonce=xxxxxxxx&status=all',
    headers:{
        'Connection': 'Close',
        'Cache-Control': 'max-age=0',
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'Referer': 'http://zyearn.duoshuo.com/admin/',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.143 Safari/537.36',
        'Accept-Language': 'zh-CN,zh;q=0.8',
        'Accept-Charset': 'utf-8',
        'Cookie': 'duoshuo_unique=xxxx; PHPSESSID=xxxx'
    }
};
```

返回的是一个json数据，其中有一个域值正好是评论数，拿到以后和原来的比较即可。还需要保存上一次运行的评论数结果，我将它保存在一个文件中，每次去读取。

### 推送

既然我们已经知道了是否有新的评论，那么就要推送给用户，这里提供两个方案，短信和邮件。

#### 短信推送

飞信提供了一个免费的命令行工具，能通过它来发送短信。具体教程请参考[这里](http://bbs.it-adv.net/viewthread.php?tid=1081);

#### 邮件推送

Mutt是一个命令行邮件发送工具，能达到我们的目的，设置请参考我的[wiki](http://wiki.lifeofzjs.com/tool/mutt.html)。

### 设置cron

因为这是一个定时运行的脚本，所以要设置crontab任务。在cron中加入下列代码：

```
*/1 * * * * /usr/local/sbin/node /root/duoshuo/duoshuoCrawler.js
```

意思是每隔1分钟去检查一下是否有新评论，如果你的服务器压力太大，可以把时间改长。

至此，我们的推送功能就开发好了。全部的代码已经放在了[github](https://github.com/zyearn/duoshuo--notification)。
