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

以下是我整个simulator的代码，通过了所有测试：

{% codeblock lang:m %}
/*
 * author : zjs
 * date : 2014.02.15
 */

#include "cachelab.h"
#include <time.h>
#include <getopt.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <ctype.h>
#define MAXLINE 200

void get_opt(int argc, char **argv);
void do_init();
void do_deinit();
void do_L(void *addr, int size);
void do_M(void *addr, int size);
void do_S(void *addr, int size);
int  getset(void *addr);
long gettag(void *addr);

// data structure of one specific set entry
// the size of array is the number of lines from command line, i.e. -E 1
struct oneSet
{
    int *v;
    clock_t *last_access_time;
    long *tag;    
};

int hits, misses, evicts;
struct oneSet *setptr;          // the global pointer to the cache, setptr[n] stands for the nth set entry
int s = 0, E = 0, b = 0;
char *file = NULL;
long clocktime = 0;             // used to record the access time

int main(int argc, char **argv)
{
    get_opt(argc, argv);
    do_init();
   
    FILE *fp = fopen(file, "r");
    if (fp == NULL)
    {
        fprintf(stderr, "open file error\n");
        exit(0);
    } 

    char op[MAXLINE];
    void *addr;
    int size;
    char buf[MAXLINE];
    while (fgets(buf, MAXLINE, fp) != NULL)
    {
        //printf("\nline read: %s\n", buf);
        sscanf(buf, "%s %p,%d", op, &addr, &size);
        //printf("op = %s, addr = %p, size = %d\n", op, addr, size);
        if (*op == 'L')
        {
            do_L(addr, size);
        }
        else if (*op == 'M')
        {
            do_M(addr, size);
        }
        else if (*op == 'S')
        {
            do_S(addr, size);
        }
    }

    do_deinit();
    printSummary(hits, misses, evicts);
    return 0;
}

// get the program parameter using getopt library
void get_opt(int argc, char **argv)
{
    int c;

    while ((c = getopt(argc, argv, "s:E:b:t:")) != -1)
    {
        switch (c)
        {
            case 's':
                s = atoi(optarg);
                break;
            case 'E':
                E = atoi(optarg);
                break;
            case 'b':
                b = atoi(optarg);
                break;
            case 't':
                file = optarg;
                break;
            default:
                printf("illegal opt\n");
                exit(0);
        }
    }
}

// using malloc to initialize data structure
void do_init()
{
    int S = (1 << s);
    if ( S <= 0)
    {
        fprintf(stderr, "S is nonpositive\n");
        exit(0);
    }
    setptr = (struct oneSet*)malloc(sizeof(struct oneSet) * S);
    
    for (int ind = 0; ind < S; ++ind)
    {
        setptr[ind].v = (int *)malloc(sizeof(int) * E);
        setptr[ind].last_access_time = (clock_t *)malloc(sizeof(clock_t) * E);
        setptr[ind].tag = (long *)malloc(sizeof(long) * E);

        for(int Eind = 0 ; Eind < E; Eind++)
        {
            setptr[ind].v[Eind] = 0;
            setptr[ind].last_access_time[Eind] = 0;
            setptr[ind].tag[Eind] = 0;
        }
    }
}

// explicitly return the space back to heap
void do_deinit()
{
    int S = (1 << s);
    
    setptr = (struct oneSet*)malloc(sizeof(struct oneSet) * S);
    for (int ind = 0; ind < S; ++ind)
    {
        free(setptr[ind].v);
        free(setptr[ind].last_access_time);
        free(setptr[ind].tag);
    }

    free(setptr);
}

// do a LOAD operation
void do_L(void *addr, int size)
{
    int setnum = getset(addr);
    printf("setnum = %d, ", setnum);
    struct oneSet *this_set = &setptr[setnum];

    int index;
    int full = 1;
    int empty_item = 0;         // if not full, keep track of the empty item
    int last_item = 0;          // if full, keep track of the evict item
    int last_time = this_set->last_access_time[0];  

    for (index = 0; index < E; index++)
    {   
        // find, update the access time
        if (this_set->v[index] == 1 && gettag(addr) == this_set->tag[index])
        {
            this_set->last_access_time[index] = ++clocktime;
            break;
        }
        // not valid, then this entry is considered empty which means cache is not full
        else if (this_set->v[index] == 0)
        {
            full = 0;
            empty_item = index;
        }    
        // valid but tag not equal
        else
        { 
            // keep track of the LRU item, ready for eviction
            if (this_set->last_access_time[index] < last_time)
            {
                last_item = index;
                last_time = this_set->last_access_time[index];
            }
        }
    }

    if (index == E) // miss
    {
        misses++;
        if (full)   //evict
        {
            this_set->tag[last_item] = gettag(addr);
            this_set->last_access_time[last_item] = ++clocktime;
            evicts++;
        }
        else
        {
            this_set->v[empty_item] = 1;
            this_set->tag[empty_item] = gettag(addr);
            this_set->last_access_time[empty_item] = ++clocktime;
        }
    }
    else    // hit
    {
        hits++;
    }    

}

//the difference between S and M is that S only load when miss, while M always load first then store
void do_S(void *addr, int size)
{
    int setnum = getset(addr);
    printf("setnum = %d, ", setnum);
    struct oneSet *this_set = &setptr[setnum];

    int index;
    for (index = 0; index < E; ++index)
    {
        if (this_set->v[index] == 1 && gettag(addr) == this_set->tag[index])    //find
        {
            this_set->last_access_time[index] = ++clocktime;
            break;
        }
    } 

    if (index == E) // store miss
    {
        do_L(addr, size);   // if miss, then load
    }
    else            // store hit
    {
        hits++;
    }
}

// do a MODIFY operation, which do S afer L
void do_M(void *addr, int size)
{
    int setnum = getset(addr);
    printf("setnum = %d, ", setnum);

    do_L(addr, size);
    do_S(addr, size);
}

// get the set number from the address
int getset(void *addr)
{
    return (int)( ((long)addr >> b) & ((1 << s) - 1) );
}

// get the tag number from the address
long gettag(void *addr)
{
    return (long)((long)addr >> (s + b));
}
{% endcodeblock%}

