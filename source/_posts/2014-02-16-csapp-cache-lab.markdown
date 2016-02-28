---
layout: post
title: "CSAPP: Cache Lab"
date: 2014-02-16 11:52
comments: true
categories: ComputerSystem
---

这个实验分为PART A和PART B。PART A要求我们写一个cache模拟器，PART B要求我们利用cache来优化一个矩阵的转置以达到cache miss最少。

目前只完成了A部分，B部分等把CSAPP的其它实验全部做完了有空的话再回来做，剩下的几个lab也都很有意思。

这个simulator完全要自己写，没有给函数接口和数据结构，这些要自己设计。最终的binary接受4个参数：
<!-- more -->
{% codeblock %}
-b  // b bits来表示block大小
-E  // 一个set里有E项，即E-way associativity
-s  // s bits来表示set大小
-t  / /测试文件
{% endcodeblock %}

在测试文件里有4种类型的命令：
{% codeblock %}
I 0400d7d4,8    // Instruction load
M 0421c7f0,4    // Modify, i.e, a data load followed by a data store
L 04f6b868,8    // a data load 
S 7ff0005c8,8   // a data store
{% endcodeblock %}

然后根据命令行指定参数的cache来模拟运行这些指令，给出最终的hit数，miss数和eviction数。替换策略为LRU。

## data structure

总的来说，无非就是一个2^s行，E列的数组，数组的元素是一个struct，由`is_valide`，`tag`和`access_time`。下面是我定义的数据结构：

``` 
struct oneSet
{
    int *v;
    clock_t *last_access_time;
    long *tag;    
};

// the global pointer to the cache, setptr[n] stands for the nth set entry
struct oneSet *setptr;
```
其中oneSet这个struct中的指针都需要根据参数动态分配，所有数组的大小为E。

## Load operation

如果当前指令是load，那么处理的伪代码伪：
```
if cache hit:
    hit++
else:   //cache miss:
    if cache is not full:
        miss++
    else:   // cache is full
        miss++
        evict++
```
## Store operation

如果当前指令是store，那么处理的伪代码伪：
```
if cache hit:
    hit++
else:   //cache miss
    do a load operation
```
## Modify operation

如果当前指令是Modify，那么处理的伪代码伪：
```
do a load operation
do a store operation
```
如果把上面的逻辑想通了，那么就可以编码了。

## 函数设计

以下是我所有函数的原型：
```
// to get the opt from the command line
void get_opt();

// do init work, i.e, malloc space
void do_init();

// do deinit work, i.e, free space
void do_deinit();

// do a load operation
void do_L(void *addr, int size);

// do a modify operation
void do_M(void *addr, int size);

// do a store operation
void do_S(void *addr, int size);

// get set number according to the address of data
int  getset(void *addr);

// get tag number according to the address of data
long gettag(void *addr);
```
## 遇到的些问题

1. 替换策略为LRU，所以要记录每个block的最后访问时间，我本来是调用clock()来获取当前cpu时间作为当前时间的，运行后程序出问题，调试发现这个值一直为0。后来查到了原因，是程序运行时间太短cpu时间太小导致精度不够...表示i7四代太强了。后来用一个long来表示时间解决这个问题。

2. 虚拟机不能用mmap。本来一个更方便读测试文件的方法是用mmap把它映射到内存然后直接内存操作，但我的host是mac，在parallel desktop上跑ubuntu，导致了mmap不能正常使用，详细见[这里](http://stackoverflow.com/questions/18420473/invalid-argument-for-read-write-mmap)

## 源码

代码放在了[github](https://github.com/zyearn/csapp-lab-2e/blob/master/cachelab-handout/csim.c)上。
