---
layout: post
title: "CSAPP: bomb lab"
date: 2014-02-03 20:03
comments: true
categories: 'ComputerSystem'
---

这个lab是csapp这本书的第二个实验。输入是一个x86的binary代码，要求我们输入6个字符串，以满足程序的要求，达到正确执行的目的。如果输错了，程序就“爆炸”了。所以我们要做的就是根据给定的binary文件，求出这6个字符串。
解法是先对它反汇编，根据汇编代码解出代码里的6个谜题。

`objdump -d bomb`

看代码其中有6个phase，一个一个解决就可以了。我把一些重要的注释都写在了代码里。
<!-- more -->
## phase_1

<pre><code>
08048b20 &ltphase_1&gt:
 8048b20:	55                   	push   %ebp
 8048b21:	89 e5                	mov    %esp,%ebp
 8048b23:	83 ec 08             	sub    $0x8,%esp
 8048b26:	8b 45 08             	mov    0x8(%ebp),%eax
 8048b29:	83 c4 f8             	add    $0xfffffff8,%esp
 8048b2c:	68 c0 97 04 08       	push   $0x80497c0
 8048b31:	50                   	push   %eax
 8048b32:	e8 f9 04 00 00       	call   8049030 &ltstrings_not_equal&gt
 8048b37:	83 c4 10             	add    $0x10,%esp
 8048b3a:	85 c0                	test   %eax,%eax
 8048b3c:	74 05                	je     8048b43 &ltphase_1+0x23&gt
 8048b3e:	e8 b9 09 00 00       	call   80494fc &ltexplode_bomb&gt
 8048b43:	89 ec                	mov    %ebp,%esp
 8048b45:	5d                   	pop    %ebp
 8048b46:	c3                   	ret    
 8048b47:	90                   	nop
</code></pre>

第一个很简单，它调用了`strings_not_equal`，如果相等，则jump然后离开这个函数。`%eax`是用户输入字符串的地址，0x80497c0就是一个常量的地址。

用gdb设置好断点，然后`x/sb 0x80497c0`，可以得到: "Public speaking is very easy."

## phase_2

<pre><code>
08048b48 &ltphase_2&gt:
 8048b48:	55                   	push   %ebp
 8048bi49:	89 e5                	mov    %esp,%ebp
 8048b4b:	83 ec 20             	sub    $0x20,%esp
 8048b4e:	56                   	push   %esi
 8048b4f:	53                   	push   %ebx
 8048b50:	8b 55 08             	mov    0x8(%ebp),%edx
 8048b53:	83 c4 f8             	add    $0xfffffff8,%esp
 8048b56:	8d 45 e8             	lea    -0x18(%ebp),%eax
 8048b59:	50                   	push   %eax
 8048b5a:	52                   	push   %edx
 8048b5b:	e8 78 04 00 00       	call   8048fd8 &ltread_six_numbers&gt
 8048b60:	83 c4 10             	add    $0x10,%esp
// -0x18(%ebp)存储着第一个数字，这个数一定等于1，否则就error
 8048b63:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
 8048b67:	74 05                	je     8048b6e &ltphase_2+0x26&gt
 8048b69:	e8 8e 09 00 00       	call   80494fc &ltexplode_bomb&gt
 8048b6e:	bb 01 00 00 00       	mov    $0x1,%ebx
 8048b73:	8d 75 e8             	lea    -0x18(%ebp),%esi
// 下面三行code说明，(n+2) * a[n] == a[n+1]
 8048b76:	8d 43 01             	lea    0x1(%ebx),%eax
 8048b79:	0f af 44 9e fc       	imul   -0x4(%esi,%ebx,4),%eax
 8048b7e:	39 04 9e             	cmp    %eax,(%esi,%ebx,4)
 8048b81:	74 05                	je     8048b88 &ltphase_2+0x40&gt
 8048b83:	e8 74 09 00 00       	call   80494fc &ltexplode_bomb&gt
 8048b88:	43                   	inc    %ebx
 8048b89:	83 fb 05             	cmp    $0x5,%ebx
// 若ebx&lt=5，则跳回去
 8048b8c:	7e e8                	jle    8048b76 &ltphase_2+0x2e&gt
 8048b8e:	8d 65 d8             	lea    -0x28(%ebp),%esp
 8048b91:	5b                   	pop    %ebx
 8048b92:	5e                   	pop    %esi
 8048b93:	89 ec                	mov    %ebp,%esp
 8048b95:	5d                   	pop    %ebp
 8048b96:	c3                   	ret    
 8048b97:	90                   	nop
</code></pre>

首先，观察出它调用了`read_six_numbres`，即读取6个数，下面那个`cmpl`说明第一个数一定为1。

再接下去几行是个递推公式，它的代码意思是：判断`(n+2) * a[n]`和`a[n+1]`的值，若不相等，则爆炸。所以很明显，这6个数分别是：

`1 2 6 24 120 720`

## phase_3

<pre><code>
08048b98 &ltphase_3&gt:
 8048b98:	55                   	push   %ebp
 8048b99:	89 e5                	mov    %esp,%ebp
 8048b9b:	83 ec 14             	sub    $0x14,%esp
 8048b9e:	53                   	push   %ebx
 8048b9f:	8b 55 08             	mov    0x8(%ebp),%edx
 8048ba2:	83 c4 f4             	add    $0xfffffff4,%esp
 8048ba5:	8d 45 fc             	lea    -0x4(%ebp),%eax
 8048ba8:	50                   	push   %eax
 8048ba9:	8d 45 fb             	lea    -0x5(%ebp),%eax
 8048bac:	50                   	push   %eax
 8048bad:	8d 45 f4             	lea    -0xc(%ebp),%eax
 8048bb0:	50                   	push   %eax
 8048bb1:	68 de 97 04 08       	push   $0x80497de
 8048bb6:	52                   	push   %edx
 // %edx为用户输入的起始地址，$0x80497de为格式字符串的起始地址
 8048bb7:	e8 a4 fc ff ff       	call   8048860 &ltsscanf@plt&gt
 8048bbc:	83 c4 20             	add    $0x20,%esp
 // %eax为sscanf的返回值，正确值为3
 8048bbf:	83 f8 02             	cmp    $0x2,%eax
 8048bc2:	7f 05                	jg     8048bc9 &ltphase_3+0x31&gt
 8048bc4:	e8 33 09 00 00       	call   80494fc &ltexplode_bomb&gt
 // 说明第一个数小于等于7
 8048bc9:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
 8048bcd:	0f 87 b5 00 00 00    	ja     8048c88 &ltphase_3+0xf0&gt
 8048bd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 // 跳转，0x80497e8为起始地址，%eax为偏移
 8048bd6:	ff 24 85 e8 97 04 08 	jmp    *0x80497e8(,%eax,4)
 8048bdd:	8d 76 00             	lea    0x0(%esi),%esi
 8048be0:	b3 71                	mov    $0x71,%bl
 8048be2:	81 7d fc 09 03 00 00 	cmpl   $0x309,-0x4(%ebp)
 8048be9:	0f 84 a0 00 00 00    	je     8048c8f &ltphase_3+0xf7&gt
 8048bef:	e8 08 09 00 00       	call   80494fc &ltexplode_bomb&gt
 8048bf4:	e9 96 00 00 00       	jmp    8048c8f &ltphase_3+0xf7&gt
 8048bf9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
 8048c00:	b3 62                	mov    $0x62,%bl
 8048c02:	81 7d fc d6 00 00 00 	cmpl   $0xd6,-0x4(%ebp)
 8048c09:	0f 84 80 00 00 00    	je     8048c8f &ltphase_3+0xf7&gt
 8048c0f:	e8 e8 08 00 00       	call   80494fc &ltexplode_bomb&gt
 8048c14:	eb 79                	jmp    8048c8f &ltphase_3+0xf7&gt
 8048c16:	b3 62                	mov    $0x62,%bl
 8048c18:	81 7d fc f3 02 00 00 	cmpl   $0x2f3,-0x4(%ebp)
 8048c1f:	74 6e                	je     8048c8f &ltphase_3+0xf7&gt
 8048c21:	e8 d6 08 00 00       	call   80494fc &ltexplode_bomb&gt
 8048c26:	eb 67                	jmp    8048c8f &ltphase_3+0xf7&gt
 8048c28:	b3 6b                	mov    $0x6b,%bl
 8048c2a:	81 7d fc fb 00 00 00 	cmpl   $0xfb,-0x4(%ebp)
 8048c31:	74 5c                	je     8048c8f &ltphase_3+0xf7&gt
 8048c33:	e8 c4 08 00 00       	call   80494fc &ltexplode_bomb&gt
 8048c38:	eb 55                	jmp    8048c8f &ltphase_3+0xf7&gt
 8048c3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
 8048c40:	b3 6f                	mov    $0x6f,%bl
 8048c42:	81 7d fc a0 00 00 00 	cmpl   $0xa0,-0x4(%ebp)
 8048c49:	74 44                	je     8048c8f &ltphase_3+0xf7&gt
 8048c4b:	e8 ac 08 00 00       	call   80494fc &ltexplode_bomb&gt
 8048c50:	eb 3d                	jmp    8048c8f &ltphase_3+0xf7&gt
 8048c52:	b3 74                	mov    $0x74,%bl
 8048c54:	81 7d fc ca 01 00 00 	cmpl   $0x1ca,-0x4(%ebp)
 8048c5b:	74 32                	je     8048c8f &ltphase_3+0xf7&gt
 8048c5d:	e8 9a 08 00 00       	call   80494fc &ltexplode_bomb&gt
 8048c62:	eb 2b                	jmp    8048c8f &ltphase_3+0xf7&gt
 8048c64:	b3 76                	mov    $0x76,%bl
 8048c66:	81 7d fc 0c 03 00 00 	cmpl   $0x30c,-0x4(%ebp)
 8048c6d:	74 20                	je     8048c8f &ltphase_3+0xf7&gt
 8048c6f:	e8 88 08 00 00       	call   80494fc &ltexplode_bomb&gt
 8048c74:	eb 19                	jmp    8048c8f &ltphase_3+0xf7&gt
 8048c76:	b3 62                	mov    $0x62,%bl
 8048c78:	81 7d fc 0c 02 00 00 	cmpl   $0x20c,-0x4(%ebp)
 8048c7f:	74 0e                	je     8048c8f &ltphase_3+0xf7&gt
 8048c81:	e8 76 08 00 00       	call   80494fc &ltexplode_bomb&gt
 8048c86:	eb 07                	jmp    8048c8f &ltphase_3+0xf7&gt
 8048c88:	b3 78                	mov    $0x78,%bl
 8048c8a:	e8 6d 08 00 00       	call   80494fc &ltexplode_bomb&gt
 8048c8f:	3a 5d fb             	cmp    -0x5(%ebp),%bl
 8048c92:	74 05                	je     8048c99 &ltphase_3+0x101&gt
 8048c94:	e8 63 08 00 00       	call   80494fc &ltexplode_bomb&gt
 8048c99:	8b 5d e8             	mov    -0x18(%ebp),%ebx
 8048c9c:	89 ec                	mov    %ebp,%esp
 8048c9e:	5d                   	pop    %ebp
</code></pre>

一开始，调用了sscanf，它的第二个参数即0x80497de所在的地址是输入的格式，用`x/sb 0x80497de`看到这个格式为`%d %c %d`。

然后会根据第一个整数的值来进行跳转，从代码里看出起始地址为`0x80497e8`，%eax为偏移，用gdb观察`0x80497e8`的值，可以发现从这个地址开始存储着若干个地址的值，这些值正好是phase_3的地址空间里面的值。所以可以猜到，这可能是一个switch语句，根据第一个整数作为switch分支比较的对象。

我们来分析一下其中第一个switch语句，它对应的代码是：
<pre><code>
 8048be0:	b3 71                	mov    $0x71,%bl
 8048be2:	81 7d fc 09 03 00 00 	cmpl   $0x309,-0x4(%ebp)
 8048be9:	0f 84 a0 00 00 00    	je     8048c8f &ltphase_3+0xf7&gt
 8048bef:	e8 08 09 00 00       	call   80494fc &ltexplode_bomb&gt
 8048bf4:	e9 96 00 00 00       	jmp    8048c8f &ltphase_3+0xf7&gt
 8048bf9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
</code></pre>
代码首先把'q'赋给%bl，然后看下面jmp的地址8048c8f是一个cmpl，如果用户字符不和%bl相等则爆炸，所以第二个字符是'q'。第二行代码说明第三个数要和`0x309`相等。

所以，本题的一个答案为`0 q 777`。因为第一个数小于等于7，所以此题一共有8个答案，其它答案的推导过程类似。

## phase_4

<pre><code>
08048ce0 &ltphase_4&gt:
 8048ce0:	55                   	push   %ebp
 8048ce1:	89 e5                	mov    %esp,%ebp
 8048ce3:	83 ec 18             	sub    $0x18,%esp
 8048ce6:	8b 55 08             	mov    0x8(%ebp),%edx
 8048ce9:	83 c4 fc             	add    $0xfffffffc,%esp
 8048cec:	8d 45 fc             	lea    -0x4(%ebp),%eax
 // $eax为用户输入的值
 8048cef:	50                   	push   %eax
 8048cf0:	68 08 98 04 08       	push   $0x8049808
 8048cf5:	52                   	push   %edx
 8048cf6:	e8 65 fb ff ff       	call   8048860 &ltsscanf@plt&gt
 8048cfb:	83 c4 10             	add    $0x10,%esp
 // sscanf的返回值为1
 8048cfe:	83 f8 01             	cmp    $0x1,%eax
 8048d01:	75 06                	jne    8048d09 &ltphase_4+0x29&gt
 // 输入的值比0大
 8048d03:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
 8048d07:	7f 05                	jg     8048d0e &ltphase_4+0x2e&gt
 8048d09:	e8 ee 07 00 00       	call   80494fc &ltexplode_bomb&gt
 8048d0e:	83 c4 f4             	add    $0xfffffff4,%esp
 8048d11:	8b 45 fc             	mov    -0x4(%ebp),%eax
 8048d14:	50                   	push   %eax
 // 调用func4
 8048d15:	e8 86 ff ff ff       	call   8048ca0 &ltfunc4&gt
 8048d1a:	83 c4 10             	add    $0x10,%esp
 8048d1d:	83 f8 37             	cmp    $0x37,%eax
 8048d20:	74 05                	je     8048d27 &ltphase_4+0x47&gt
 8048d22:	e8 d5 07 00 00       	call   80494fc &ltexplode_bomb&gt
 8048d27:	89 ec                	mov    %ebp,%esp
 8048d29:	5d                   	pop    %ebp
 8048d2a:	c3                   	ret    
 8048d2b:	90                   	nop
</code></pre>

调用了sscanf，并且地址`0x8049808`保存着输入格式，gdb调用`x/sb 0x8049808`得知格式为"%d"，即要求我们输入一个整数。在下面又调用了func4，并且要求返回值%eax与0x37相等。所以我们只要搞懂func4在做什么就可以了。以下是func4的汇编代码：

<pre><code>
08048ca0 &ltfunc4&gt:
 8048ca0:	55                   	push   %ebp
 8048ca1:	89 e5                	mov    %esp,%ebp
 8048ca3:	83 ec 10             	sub    $0x10,%esp
 8048ca6:	56                   	push   %esi
 8048ca7:	53                   	push   %ebx
 8048ca8:	8b 5d 08             	mov    0x8(%ebp),%ebx
 8048cab:	83 fb 01             	cmp    $0x1,%ebx
 8048cae:	7e 20                	jle    8048cd0 &ltfunc4+0x30&gt
 8048cb0:	83 c4 f4             	add    $0xfffffff4,%esp
 8048cb3:	8d 43 ff             	lea    -0x1(%ebx),%eax
 8048cb6:	50                   	push   %eax
 // call func4(n-1)
 8048cb7:	e8 e4 ff ff ff       	call   8048ca0 &ltfunc4&gt
 8048cbc:	89 c6                	mov    %eax,%esi
 8048cbe:	83 c4 f4             	add    $0xfffffff4,%esp
 8048cc1:	8d 43 fe             	lea    -0x2(%ebx),%eax
 8048cc4:	50                   	push   %eax
 // call func4(n-2)
 8048cc5:	e8 d6 ff ff ff       	call   8048ca0 &ltfunc4&gt
 8048cca:	01 f0                	add    %esi,%eax
 8048ccc:	eb 07                	jmp    8048cd5 &ltfunc4+0x35&gt
 8048cce:	89 f6                	mov    %esi,%esi
 8048cd0:	b8 01 00 00 00       	mov    $0x1,%eax
 8048cd5:	8d 65 e8             	lea    -0x18(%ebp),%esp
 8048cd8:	5b                   	pop    %ebx
 8048cd9:	5e                   	pop    %esi
 8048cda:	89 ec                	mov    %ebp,%esp
 8048cdc:	5d                   	pop    %ebp
 8048cdd:	c3                   	ret    
 8048cde:	89 f6                	mov    %esi,%esi
</code></pre>

这段代码非常容易看懂，递归调用了一下自己，递归中止条件是参数小于等于1，否则返回`func(n-1)+func(n-2)`，这段汇编的效果和下面这段C代码等价：

<pre><code>
int func4(int n) 
{
	if (n &lt= 1)
		return 1;
	else
		return func4(n-1) + func4(n-2);
}
</code></pre>

这就是一个斐波那契数列。然后问题等价于，第多少个斐波那契数等于0x37，非常简单，答案是`9`。

## phase_5

<pre><code>
08048d2c &ltphase_5&gt:
 8048d2c:	55                   	push   %ebp
 8048d2d:	89 e5                	mov    %esp,%ebp
 8048d2f:	83 ec 10             	sub    $0x10,%esp
 8048d32:	56                   	push   %esi
 8048d33:	53                   	push   %ebx
 8048d34:	8b 5d 08             	mov    0x8(%ebp),%ebx
 8048d37:	83 c4 f4             	add    $0xfffffff4,%esp
 8048d3a:	53                   	push   %ebx
 8048d3b:	e8 d8 02 00 00       	call   8049018 &ltstring_length&gt
 8048d40:	83 c4 10             	add    $0x10,%esp
 // 说明输入字符串的长度为6
 8048d43:	83 f8 06             	cmp    $0x6,%eax
 8048d46:	74 05                	je     8048d4d &ltphase_5+0x21&gt
 8048d48:	e8 af 07 00 00       	call   80494fc &ltexplode_bomb&gt
 8048d4d:	31 d2                	xor    %edx,%edx
 8048d4f:	8d 4d f8             	lea    -0x8(%ebp),%ecx
 // 0x804b220是一些常量字符的地址
 8048d52:	be 20 b2 04 08       	mov    $0x804b220,%esi
 // %ebx是输入字符的起始地址，%edx被初始化为0，所以这是用来遍历输入字符
 8048d57:	8a 04 1a             	mov    (%edx,%ebx,1),%al
 // 取低4位
 8048d5a:	24 0f                	and    $0xf,%al
 8048d5c:	0f be c0             	movsbl %al,%eax
 // 将%esi + %eax作为地址，取这个字符存到%al
 8048d5f:	8a 04 30             	mov    (%eax,%esi,1),%al
 // 将%al存在局部变量中
 8048d62:	88 04 0a             	mov    %al,(%edx,%ecx,1)
 8048d65:	42                   	inc    %edx
 // 依次处理6个字符
 8048d66:	83 fa 05             	cmp    $0x5,%edx
 8048d69:	7e ec                	jle    8048d57 &ltphase_5+0x2b&gt
 // 字符串末尾的0
 8048d6b:	c6 45 fe 00          	movb   $0x0,-0x2(%ebp)
 8048d6f:	83 c4 f8             	add    $0xfffffff8,%esp
 8048d72:	68 0b 98 04 08       	push   $0x804980b
 8048d77:	8d 45 f8             	lea    -0x8(%ebp),%eax
 8048d7a:	50                   	push   %eax
 // 字符串比较，比较对象为0x804980b地址的字符串常量 和 以%ebp - 0x08为地址的字符串
 8048d7b:	e8 b0 02 00 00       	call   8049030 &ltstrings_not_equal&gt
 8048d80:	83 c4 10             	add    $0x10,%esp
 8048d83:	85 c0                	test   %eax,%eax
 8048d85:	74 05                	je     8048d8c &ltphase_5+0x60&gt
 8048d87:	e8 70 07 00 00       	call   80494fc &ltexplode_bomb&gt
 8048d8c:	8d 65 e8             	lea    -0x18(%ebp),%esp
 8048d8f:	5b                   	pop    %ebx
 8048d90:	5e                   	pop    %esi
 8048d91:	89 ec                	mov    %ebp,%esp
 8048d93:	5d                   	pop    %ebp
 8048d94:	c3                   	ret    
 8048d95:	8d 76 00             	lea    0x0(%esi),%esi
</code></pre>

在代码中可以看到，代码最终做的是一个字符串比较，字符串1是常量，保存在`0x804980b`里，用gdb看一下这块内存的值，可以得到字符串1为"giants"。字符串2的值是我们生成的，不过过程会复杂一些。看代码可知，我们的输入为长度为6的字符串，遍历这个字符串，对于每个字符，取低4位，然后作为`0x804b220`地址的偏移，得到一个地址。取这个偏移地址的字符作为字符串2的字符。

具体的做法就是，先找到`0x804b220`地址的内容，用gdb得到是"isrveawhobpnutfg"，字符串1第一个字符是g，偏移量是0xF，所以我们的第一个输入字符的后4位是0xF就可以了，即 '/' 或 '?' 或 'O' 或 '_' 或 'o' 都可以。

依此类推，第2、3、4、5、6个字符都是这么得到，此phase其中一个答案是`opekma`。还有其它很多答案。

## phase_6

<pre><code>
08048d98 &ltphase_6&gt:
 8048d98:	55                   	push   %ebp
 8048d99:	89 e5                	mov    %esp,%ebp
 8048d9b:	83 ec 4c             	sub    $0x4c,%esp
 8048d9e:	57                   	push   %edi
 8048d9f:	56                   	push   %esi
 8048da0:	53                   	push   %ebx
 8048da1:	8b 55 08             	mov    0x8(%ebp),%edx
 8048da4:	c7 45 cc 6c b2 04 08 	movl   $0x804b26c,-0x34(%ebp)
 8048dab:	83 c4 f8             	add    $0xfffffff8,%esp
 8048dae:	8d 45 e8             	lea    -0x18(%ebp),%eax
 8048db1:	50                   	push   %eax
 8048db2:	52                   	push   %edx
 // 读取6个数，存在 %ebp - 0x18 开始的地址中
 8048db3:	e8 20 02 00 00       	call   8048fd8 &ltread_six_numbers&gt
 8048db8:	31 ff                	xor    %edi,%edi
 8048dba:	83 c4 10             	add    $0x10,%esp
 8048dbd:	8d 76 00             	lea    0x0(%esi),%esi

 8048dc0:	8d 45 e8             	lea    -0x18(%ebp),%eax
 8048dc3:	8b 04 b8             	mov    (%eax,%edi,4),%eax
 8048dc6:	48                   	dec    %eax
 8048dc7:	83 f8 05             	cmp    $0x5,%eax
 8048dca:	76 05                	jbe    8048dd1 &ltphase_6+0x39&gt
 8048dcc:	e8 2b 07 00 00       	call   80494fc &ltexplode_bomb&gt
 8048dd1:	8d 5f 01             	lea    0x1(%edi),%ebx
 8048dd4:	83 fb 05             	cmp    $0x5,%ebx
 8048dd7:	7f 23                	jg     8048dfc &ltphase_6+0x64&gt
 8048dd9:	8d 04 bd 00 00 00 00 	lea    0x0(,%edi,4),%eax
 8048de0:	89 45 c8             	mov    %eax,-0x38(%ebp)
 8048de3:	8d 75 e8             	lea    -0x18(%ebp),%esi
 8048de6:	8b 55 c8             	mov    -0x38(%ebp),%edx
 8048de9:	8b 04 32             	mov    (%edx,%esi,1),%eax
 8048dec:	3b 04 9e             	cmp    (%esi,%ebx,4),%eax
 8048def:	75 05                	jne    8048df6 &ltphase_6+0x5e&gt
 8048df1:	e8 06 07 00 00       	call   80494fc &ltexplode_bomb&gt
 8048df6:	43                   	inc    %ebx
 8048df7:	83 fb 05             	cmp    $0x5,%ebx
 8048dfa:	7e ea                	jle    8048de6 &ltphase_6+0x4e&gt
 8048dfc:	47                   	inc    %edi
 8048dfd:	83 ff 05             	cmp    $0x5,%edi
 8048e00:	7e be                	jle    8048dc0 &ltphase_6+0x28&gt
// 从 0x8048dc0 到这里在确认输入的6个数都不同

 8048e02:	31 ff                	xor    %edi,%edi
 8048e04:	8d 4d e8             	lea    -0x18(%ebp),%ecx
 8048e07:	8d 45 d0             	lea    -0x30(%ebp),%eax
 8048e0a:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 8048e0d:	8d 76 00             	lea    0x0(%esi),%esi

.lab3
 8048e10:	8b 75 cc             	mov    -0x34(%ebp),%esi
 8048e13:	bb 01 00 00 00       	mov    $0x1,%ebx
 8048e18:	8d 04 bd 00 00 00 00 	lea    0x0(,%edi,4),%eax
 8048e1f:	89 c2                	mov    %eax,%edx
 8048e21:	3b 1c 08             	cmp    (%eax,%ecx,1),%ebx
 8048e24:	7d 12                	jge    .lab1 
 8048e26:	8b 04 0a             	mov    (%edx,%ecx,1),%eax
 8048e29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

.lab2
 8048e30:	8b 76 08             	mov    0x8(%esi),%esi
 8048e33:	43                   	inc    %ebx
 8048e34:	39 c3                	cmp    %eax,%ebx
 8048e36:	7c f8                	jl     .lab2

.lab1: 
// 根据输入将对应的指针按序存放，*(%ebp - 0x3c)为指针数组的起始地址
8048e38:	8b 55 c4             	mov    -0x3c(%ebp),%edx
 8048e3b:	89 34 ba             	mov    %esi,(%edx,%edi,4)
 8048e3e:	47                   	inc    %edi
 8048e3f:	83 ff 05             	cmp    $0x5,%edi
 8048e42:	7e cc                	jle    .lab3 
 8048e44:	8b 75 d0             	mov    -0x30(%ebp),%esi
 8048e47:	89 75 cc             	mov    %esi,-0x34(%ebp)
 8048e4a:	bf 01 00 00 00       	mov    $0x1,%edi
 8048e4f:	8d 55 d0             	lea    -0x30(%ebp),%edx

.lab4
// 以下代码重新排序链表，上面代码已经将6个节点的地址都存下来了
 8048e52:	8b 04 ba             	mov    (%edx,%edi,4),%eax
 8048e55:	89 46 08             	mov    %eax,0x8(%esi)
 8048e58:	89 c6                	mov    %eax,%esi
 8048e5a:	47                   	inc    %edi
 8048e5b:	83 ff 05             	cmp    $0x5,%edi
 8048e5e:	7e f2                	jle    .lab4 
 8048e60:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
 8048e67:	8b 75 cc             	mov    -0x34(%ebp),%esi
 8048e6a:	31 ff                	xor    %edi,%edi
 8048e6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

.lab6
 8048e70:	8b 56 08             	mov    0x8(%esi),%edx
 8048e73:	8b 06                	mov    (%esi),%eax
 8048e75:	3b 02                	cmp    (%edx),%eax
 8048e77:	7d 05                	jge    .lab5 
 8048e79:	e8 7e 06 00 00       	call   80494fc &ltexplode_bomb&gt

.lab5 
 8048e7e:	8b 76 08             	mov    0x8(%esi),%esi
 8048e81:	47                   	inc    %edi
 8048e82:	83 ff 04             	cmp    $0x4,%edi
 8048e85:	7e e9                	jle    .lab6 
 8048e87:	8d 65 a8             	lea    -0x58(%ebp),%esp
 8048e8a:	5b                   	pop    %ebx
 8048e8b:	5e                   	pop    %esi
 8048e8c:	5f                   	pop    %edi
 8048e8d:	89 ec                	mov    %ebp,%esp
 8048e8f:	5d                   	pop    %ebp
 8048e90:	c3                   	ret    
 8048e91:	8d 76 00             	lea    0x0(%esi),%esi
</code></pre>

这个phase的代码看起来非常非常地乱，好多jmp，所以我把一部分jmp地地址换成了标签(.labx)，这样看起来会清楚很多。经过很长时间地看代码，发现这个phase做的事情是对一个链表重新排序，当然这个顺序是由我们的输入决定的，最后的这些链表的数据部分要逆序。

地址`0x804b26c`保存着第一个节点的地址。

这个节点的结构为:
<pre><code>
struct st
{
	int data1;	// 以data1为键排序
	int data2;	// data2是有值的，但这个程序好像没用
	strcut st* next;
};
</code></pre>

程序根据我们的输入作为节点编号，找到对应的节点，按序将节点的地址存储起来，为重新排序做准备。
所以假如我们的输入是`6 5 4 3 2 1`，那么这个程序将按照这个顺序，即第6个节点的data1值最大，然后节点5、4...，然后程序将验证这个顺序的正确性。

通过gdb观察`0x804b26c`内存的值，结果是
<pre><code>
0x804b26c &ltnode1&gt:	0xfd	0x00	0x00	0x00	0x01	0x00	0x00	0x000x804b274 &ltnode1+8&gt:	0x60	0xb2	0x04	0x08</code></pre>
即，data1 == 0xfd, data2 == 0x01, next == `0x0804b260`。根据next可以找到这6个节点，然后根据data1排一下序就好了，最终的答案是`4 2 6 3 1 5`

## secret_phase

往下翻代码，还有一个叫`secret_phase`的一关，一看就是隐藏关卡，就像超级玛丽钻地洞。
先看代码：
<pre><code>
08048ee8 &ltsecret_phase&gt:
 8048ee8:	55                   	push   %ebp
 8048ee9:	89 e5                	mov    %esp,%ebp
 8048eeb:	83 ec 14             	sub    $0x14,%esp
 8048eee:	53                   	push   %ebx
 8048eef:	e8 08 03 00 00       	call   80491fc &ltread_line&gt
 8048ef4:	6a 00                	push   $0x0
 8048ef6:	6a 0a                	push   $0xa
 8048ef8:	6a 00                	push   $0x0
 8048efa:	50                   	push   %eax
 8048efb:	e8 f0 f8 ff ff       	call   80487f0 &lt__strtol_internal@plt&gt
 8048f00:	83 c4 10             	add    $0x10,%esp
 8048f03:	89 c3                	mov    %eax,%ebx
 // 以下4行说明 %ebx <= 1001
 8048f05:	8d 43 ff             	lea    -0x1(%ebx),%eax
 8048f08:	3d e8 03 00 00       	cmp    $0x3e8,%eax
 8048f0d:	76 05                	jbe    8048f14 &ltsecret_phase+0x2c&gt
 8048f0f:	e8 e8 05 00 00       	call   80494fc &ltexplode_bomb&gt
 8048f14:	83 c4 f8             	add    $0xfffffff8,%esp
 8048f17:	53                   	push   %ebx
 8048f18:	68 20 b3 04 08       	push   $0x804b320
 // 看func7的代码可知，0x804b320存着一棵树的root指针
 8048f1d:	e8 72 ff ff ff       	call   8048e94 &ltfun7&gt
 8048f22:	83 c4 10             	add    $0x10,%esp
 8048f25:	83 f8 07             	cmp    $0x7,%eax
 8048f28:	74 05                	je     8048f2f &ltsecret_phase+0x47&gt
 8048f2a:	e8 cd 05 00 00       	call   80494fc &ltexplode_bomb&gt
 8048f2f:	83 c4 f4             	add    $0xfffffff4,%esp
 8048f32:	68 20 98 04 08       	push   $0x8049820
 8048f37:	e8 d4 f8 ff ff       	call   8048810 &ltprintf@plt&gt
 8048f3c:	e8 eb 05 00 00       	call   804952c &ltphase_defused&gt
 8048f41:	8b 5d e8             	mov    -0x18(%ebp),%ebx
 8048f44:	89 ec                	mov    %ebp,%esp
 8048f46:	5d                   	pop    %ebp
 8048f47:	c3                   	ret    
 8048f48:	90                   	nop
 8048f49:	90                   	nop
 8048f4a:	90                   	nop
 8048f4b:	90                   	nop
 8048f4c:	90                   	nop
 8048f4d:	90                   	nop
 8048f4e:	90                   	nop
 8048f4f:	90                   	nop
</code></pre>

首先得确定哪里调这个函数，发现在`phase_defused`里调了，这个函数在每次成功过关后会调用，下面是这个函数的代码：
<pre><code>
0804952c &ltphase_defused&gt:
 804952c:	55                   	push   %ebp
 804952d:	89 e5                	mov    %esp,%ebp
 804952f:	83 ec 64             	sub    $0x64,%esp
 8049532:	53                   	push   %ebx
 // 0x804b480保存着一个全局变量，每通一关加1，如果不是6，则直接跳过
 8049533:	83 3d 80 b4 04 08 06 	cmpl   $0x6,0x804b480
 804953a:	75 63                	jne    804959f &ltphase_defused+0x73&gt
 804953c:	8d 5d b0             	lea    -0x50(%ebp),%ebx
 804953f:	53                   	push   %ebx
 8049540:	8d 45 ac             	lea    -0x54(%ebp),%eax
 8049543:	50                   	push   %eax
 8049544:	68 03 9d 04 08       	push   $0x8049d03
 8049549:	68 70 b7 04 08       	push   $0x804b770
 // 0x804b770是源字符串，0x8049d03是格式
 804954e:	e8 0d f3 ff ff       	call   8048860 &ltsscanf@plt&gt
 8049553:	83 c4 10             	add    $0x10,%esp
 // sscanf 返回2
 8049556:	83 f8 02             	cmp    $0x2,%eax
 8049559:	75 37                	jne    8049592 &ltphase_defused+0x66&gt
 804955b:	83 c4 f8             	add    $0xfffffff8,%esp
 804955e:	68 09 9d 04 08       	push   $0x8049d09
 8049563:	53                   	push   %ebx
 // sscanf读取的字符串和0x8049d09为地址的字符串要相等
 8049564:	e8 c7 fa ff ff       	call   8049030 &ltstrings_not_equal&gt
 8049569:	83 c4 10             	add    $0x10,%esp
 804956c:	85 c0                	test   %eax,%eax
 804956e:	75 22                	jne    8049592 &ltphase_defused+0x66&gt
 8049570:	83 c4 f4             	add    $0xfffffff4,%esp
 8049573:	68 20 9d 04 08       	push   $0x8049d20
 8049578:	e8 93 f2 ff ff       	call   8048810 &ltprintf@plt&gt
 804957d:	83 c4 f4             	add    $0xfffffff4,%esp
 8049580:	68 60 9d 04 08       	push   $0x8049d60
 8049585:	e8 86 f2 ff ff       	call   8048810 &ltprintf@plt&gt
 804958a:	83 c4 20             	add    $0x20,%esp
 804958d:	e8 56 f9 ff ff       	call   8048ee8 &ltsecret_phase&gt
 8049592:	83 c4 f4             	add    $0xfffffff4,%esp
 8049595:	68 a0 9d 04 08       	push   $0x8049da0
 804959a:	e8 71 f2 ff ff       	call   8048810 &ltprintf@plt&gt
 804959f:	8b 5d 98             	mov    -0x68(%ebp),%ebx
 80495a2:	89 ec                	mov    %ebp,%esp
 80495a4:	5d                   	pop    %ebp
 80495a5:	c3                   	ret    
 80495a6:	90                   	nop
 80495a7:	90                   	nop
 80495a8:	90                   	nop
 80495a9:	90                   	nop
 80495aa:	90                   	nop
 80495ab:	90                   	nop
 80495ac:	90                   	nop
 80495ad:	90                   	nop
 80495ae:	90                   	nop
 80495af:	90                   	nop
</code></pre>

这个隐藏关卡也不是说进就进的，首先要全部通关才能进。查看`0x8049d03`，得知我们sscanf想要读取的格式是"%d %s"，查看源地址`0x804b770`，看到的是"9"，很奇怪，缺一个string。这里卡了很久，做不下去了。后来发现`0x804b770`这个地址正好是第4题输入的地址，所以我们要在第4题答案`9`的后面加一个string，就能被现在读到了。
接下去是一个string的比较，查看`$0x8049d09`这个内存里面存的是"austinpowers"，要和刚刚sscanf读到的字符串相等，于是只要在第4关答案后面加上` austinpowers`就可以了。这时候代码就会执行call secret_phase了。

在`secret_phase`里，首先调的是read_line，所以这一关的输入是要和第6关一起输的。然后调用`strtol`将字符串转化为十进制整数，并调用fun7，使得fun7的返回值等于7

<pre><code>
08048e94 &ltfun7&gt:
 8048e94:	55                   	push   %ebp
 8048e95:	89 e5                	mov    %esp,%ebp
 8048e97:	83 ec 08             	sub    $0x8,%esp
 8048e9a:	8b 55 08             	mov    0x8(%ebp),%edx
 8048e9d:	8b 45 0c             	mov    0xc(%ebp),%eax
 8048ea0:	85 d2                	test   %edx,%edx
 8048ea2:	75 0c                	jne    8048eb0 &ltfun7+0x1c&gt
 8048ea4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 8048ea9:	eb 37                	jmp    8048ee2 &ltfun7+0x4e&gt
 8048eab:	90                   	nop
 8048eac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
 // compare *arg1 ans arg2
 8048eb0:	3b 02                	cmp    (%edx),%eax
 8048eb2:	7d 11                	jge    8048ec5 &ltfun7+0x31&gt
 8048eb4:	83 c4 f8             	add    $0xfffffff8,%esp
 8048eb7:	50                   	push   %eax
 8048eb8:	8b 42 04             	mov    0x4(%edx),%eax
 8048ebb:	50                   	push   %eax
 8048ebc:	e8 d3 ff ff ff       	call   8048e94 &ltfun7&gt
 8048ec1:	01 c0                	add    %eax,%eax
 8048ec3:	eb 1d                	jmp    8048ee2 &ltfun7+0x4e&gt
 8048ec5:	3b 02                	cmp    (%edx),%eax
 8048ec7:	74 17                	je     8048ee0 &ltfun7+0x4c&gt
 8048ec9:	83 c4 f8             	add    $0xfffffff8,%esp
 8048ecc:	50                   	push   %eax
 8048ecd:	8b 42 08             	mov    0x8(%edx),%eax
 8048ed0:	50                   	push   %eax
 8048ed1:	e8 be ff ff ff       	call   8048e94 &ltfun7&gt
 8048ed6:	01 c0                	add    %eax,%eax
 8048ed8:	40                   	inc    %eax
 8048ed9:	eb 07                	jmp    8048ee2 &ltfun7+0x4e&gt
 8048edb:	90                   	nop
 8048edc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
 8048ee0:	31 c0                	xor    %eax,%eax
 8048ee2:	89 ec                	mov    %ebp,%esp
 8048ee4:	5d                   	pop    %ebp
 8048ee5:	c3                   	ret    
 8048ee6:	89 f6                	mov    %esi,%esi
</code></pre>

这个函数看起来也不算复杂，和下面的C代码等价：
<pre><code>
struct treeNode
{
	int data;
	struct treeNode* leftChild;
	struct treeNode* rightChild;
};

int fun7(struct treeNode* p, int v)
{
	if (p == NULL)
		return -1;
	else if (v &lt p-&gtdata)
		return 2 * fun7(p-&gtleftChild, v);
	else if (v == p-&gtdata)
		return 0;
	else 
		return 2 * fun7(p-&gtrightChild, v) + 1;
}
</code></pre>

所以我们的问题等价于，找到这棵树，并且找到让fun7的返回值为7的v即可。这棵数很好找到，在`secret_phase`里调用fun7前push了2个参数，其中一个是树的root，即`0x804b320`，另一个参数是v，这个v是随附在关卡6的答案后面的。通过gdb查看`0x804b320`内存的值是：

	0x804b320 :	0x24	0x00	0x00	0x00	0x14	0xb3	0x04	0x08
	0x804b328 :	0x08	0xb3	0x04	0x08

那么data，左指针，右指针这三个值都有了，所以这棵树就有了。（这棵树高度只有3，所以用笔画出来不麻烦），然后很容易得出这个v的值大于1000。别忘了`secret_phase`代码里有个限定条件是输入的v小于等于1001，所以答案为1001。

## 答案

所有关卡的答案为：

	Public speaking is very easy.
	1 2 6 24 120 720
	0 q 777
	9 austinpowers
	opekma
	4 2 6 3 1 5
	1001
	
	
