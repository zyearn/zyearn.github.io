---
layout: post
title: "理解Javascript中的继承"
date: 2015-02-08 12:30
comments: true
categories: Program
---

在学习Javascript的过程中，哪个部分最隐涩难懂？就我个人而言，是基于原型链的继承机制。它和普通的OO语言如C++、Java中的继承在语法上相似，但内部实现则不同。Javascript里没有“类”的概念，熟悉C++、Java的同学要问了，没有类的话那哪来的继承呢？需要理解Javascript中的继承。首先得理解原型链。

<!-- more -->
## 原型链
当年Javascript被Brendan Eich设计的目标之一就是简单，它只需要能在浏览器上做一些简单的判断和交互即可。如果引入了类，那这门语言就太复杂了。但还是需要一种方法来使对象和对象之间可以串起来，于是就诞生了原型链。那原型链到底是什么意思呢，简单来说，假设我想让B继承A，那么在Javascript中只需要设置B的原型为A即可，A自己也有它的原型，那么就构成了一个“原型链”。

更准确一点，我们来看一些代码。当时C++和Java都用new来新建一个类的instance，会调一个所谓的“构造函数”，Brendan Eich也沿袭了这个思想。因为没有类，new后面应该加什么名字呢，他决定加构造函数。

{% codeblock lang:javascript %}
function Chinese(name) {
    this.name = name;
}
{% endcodeblock %}

上面的代码定义了一个构造函数，它同时也是一个object（Javascript中所有东西都是object）。new一下这个构造函数会产生一个Chinese实例：
{% codeblock lang:javascript %}
var personA = new Chinese("bob");
alert(personA.name);
{% endcodeblock %}

现在新问题来了，我们要为Chinese类加一个皮肤颜色的方法，好像这样就可以办到：
{% codeblock lang:javascript %}
function Chinese(name) {
    this.name = name;
    this.skin = "yellow";
}
{% endcodeblock %}

这样的结果就是所有的Chinese实例都会拥有一份skin的实例：
{% codeblock lang:javascript %}
var personA = new Chinese("bob");
var personB = new Chinese("Alice");
alert(personA.skin) // yellow
alert(personB.skin) // yellow

personA.skin = "black";
alert(personA.skin) // black 
alert(personB.skin) // yellow
{% endcodeblock %}

所以这种方式有一个缺点，Chinese类无法共享一个共有的属性和方法。我们希望有一个类似于“基类”的东西，所有中国人都可以共享这个基类对象。为了解决这个问题，Brendan Eich决定为构造函数设置一个prototype的属性（它是一个object），把所有需要让实例共享的属性和方法都放到prototype这个object里头去，这个prototype叫做实例的原型。实例对象一旦创建，将自动那个引用到构造函数的prototype对象。也就是说，一个实例的属性和方法有两种，一种是本地的，一种是原型的。还是上面的例子，然后把skin放到Chinese.prototype当中去：

{% codeblock lang:javascript %}
function Chinese(name) {
    this.name = name;
}
Chinese.prototype.skin = "yellow";
{% endcodeblock %}

之后访问实例的skin对象，javascript会先在本地属性中查找，若没有，则取原型中找。在这个例子中，在原型（也就是Chinese.prototype）中，找到了skin方法，所以如果想要修改所有Chinese实例的skin属性就非常容易了（好吧，就想象一下突然基因突变...），只要修改Chinese.prototype即可：

{% codeblock lang:javascript %}
var personA = new Chinese("bob");
var personB = new Chinese("Alice");
alert(personA.skin) // yellow
alert(personB.skin) // yellow

Chinese.prototype.skin = "black";
alert(personA.skin) // black 
alert(personB.skin) // 此时输出的是black，而不是上例中的yellow
{% endcodeblock %}

写到这里，有一个很自然的问题，实例能不能随意修改它的原型对象？答案是能也不能。假如typeof(原型属性)不是object（比如数字，字符串），那么不可修改；否则（比如[], {}），则能修改。

在Javascript中，是用原型来实现所谓的“继承”，一旦你理解了原型链，那么就几乎理解了Javascript中的继承。

## 构造函数的继承与非构造函数继承

理解了原型链，就可以讲javascript中的继承机制了。关于这两个主题，在搜索资料的时候发现[阮一峰](http://www.ruanyifeng.com/)在他的两篇文章里写得已经非常清楚了：
[构造函数的继承](http://www.ruanyifeng.com/blog/2010/05/object-oriented_javascript_inheritance.html)和
[非构造函数的继承](http://www.ruanyifeng.com/blog/2010/04/using_this_keyword_in_javascript.html)

## 参考

[1] [JavaScript语言精粹](http://book.douban.com/subject/3590768/)<br />
[2] [http://www.ruanyifeng.com/](http://www.ruanyifeng.com)<br />
[3] [http://blog.vjeux.com/2011/javascript/how-prototypal-inheritance-really-works.html](http://blog.vjeux.com/2011/javascript/how-prototypal-inheritance-really-works.html)
