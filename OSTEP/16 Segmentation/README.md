## 16 Segmentation

首先了解一下程序的参数和默认值

```python
parser = OptionParser()
# 随机种子
parser.add_option("-s", "--seed", default=0, help="the random seed", action="store", type="int", dest="seed")
# 虚拟地址，用逗号分隔
parser.add_option("-A", "--addresses", default="-1", help="a set of comma-separated pages to access; -1 means randomly generate", action="store", type="string", dest="addresses")
# 地址空间大小，默认为 1k
parser.add_option("-a", "--asize", default="1k", help="address space size (e.g., 16, 64k, 32m, 1g)", action="store", type="string", dest="asize")
# 物理内存大小，默认为 16k
parser.add_option("-p", "--physmem", default="16k", help="physical memory size (e.g., 16, 64k, 32m, 1g)", action="store", type="string", dest="psize")
# 随机生成的虚拟地址数量，默认为 5
parser.add_option("-n", "--numaddrs", default=5, help="number of virtual addresses to generate", action="store", type="int", dest="num")
# 段0的基址寄存器（顶）
parser.add_option("-b", "--b0", default="-1", help="value of segment 0 base register", action="store", type="string", dest="base0")
# 段0的界限寄存器
parser.add_option("-l", "--l0", default="-1", help="value of segment 0 limit register", action="store", type="string", dest="len0")
# 段1的基址寄存器（底）
parser.add_option("-B", "--b1", default="-1", help="value of segment 1 base register", action="store", type="string", dest="base1")
# 段1的界限寄存器
parser.add_option("-L", "--l1", default="-1", help="value of segment 1 limit register", action="store", type="string", dest="len1")
# 计算答案
parser.add_option("-c", help="compute answers for me", action="store_true", default=False, dest="solve")

(options, args) = parser.parse_args()
```

假设地址空间只有 2 个段
- 段0：代码、堆
  - 向下增长，地址从小到大
  - [0, 界限)
- 段1：栈
  - 向上增长，地址从大到小
  - [-界限, 0)

```bash
 --------------- virtual address 0
 |    seg0     |
 |             |
 |             |
 |-------------|
 |             |
 |             |
 |             |
 |             |
 |(unallocated)|
 |             |
 |             |
 |             |
 |-------------|
 |             |
 |    seg1     |
 |-------------| virtual address max (size of address space)
```

使用默认参数运行程序，首先判断生成的虚拟地址属于哪一个段，然后再判断是否超出界限。
- 超出范围产生段错误（SEGMENTATION VIOLATION）
- 地址空间大小为 1k，使用 1 位区分两个段
  - 0 ~ 1023（11 1111 1111）
  - 最高位为 0 表示段0
  - 最高位为 1 表示段1
- 剩余位数表示偏移量
  - 反向偏移量：偏移量 - 地址空间大小

根据虚拟地址（十六进制）的倒数第三位即可区分所属的段，0/1 属于段0，2/3 属于段1 。

```bash
./segmentation.py -c

# 输出
ARG seed 0
ARG address space size 1k
ARG phys mem size 16k

Segment register information:

  Segment 0 base  (grows positive) : 0x00001aea (decimal 6890)
  Segment 0 limit                  : 472                          <---- 6890 ~ 7362, [0, 472)

  Segment 1 base  (grows negative) : 0x00001254 (decimal 4692)
  Segment 1 limit                  : 450                          <---- 4242 ~ 4692, [-450, 0)

Virtual Address Trace
  VA  0: 0x0000020b (decimal:  523) --> SEGMENTATION VIOLATION (SEG1)                <---- 10 0000 1011 段1，523-1024=-501
  VA  1: 0x0000019e (decimal:  414) --> VALID in SEG0: 0x00001c88 (decimal: 7304)    <---- 01 1001 1110 段0，414 < 472
  VA  2: 0x00000322 (decimal:  802) --> VALID in SEG1: 0x00001176 (decimal: 4470)    <---- 11 0010 0010 段1，802-1024=-222
  VA  3: 0x00000136 (decimal:  310) --> VALID in SEG0: 0x00001c20 (decimal: 7200)    <---- 01 0011 0110 段0，310 < 472
  VA  4: 0x000001e8 (decimal:  488) --> SEGMENTATION VIOLATION (SEG0)                <---- 01 1110 1000 段0，488 > 472
```

### 1

使用不同的随机种子
- 地址空间大小为 128 字节
  - 0 ~ 127（111 1111）
- 物理内存大小为 512 字节
- 段0 基址寄存器：0
- 段0 界限寄存器：20
- 段1 基址寄存器：512
- 段1 界限寄存器：20

根据虚拟地址（十六进制）的倒数第二位即可区分所属的段，0/1/2/3 属于段0，4/5/6/7 属于段1 。


随机种子为 0

```bash
./segmentation.py -a 128 -p 512 -b 0 -l 20 -B 512 -L 20 -s 0 -c

# 输出
ARG seed 0
ARG address space size 128
ARG phys mem size 512

Segment register information:

  Segment 0 base  (grows positive) : 0x00000000 (decimal 0)
  Segment 0 limit                  : 20

  Segment 1 base  (grows negative) : 0x00000200 (decimal 512)
  Segment 1 limit                  : 20

Virtual Address Trace
  VA  0: 0x0000006c (decimal:  108) --> VALID in SEG1: 0x000001ec (decimal:  492)    <---- 段1，108-128=-20
  VA  1: 0x00000061 (decimal:   97) --> SEGMENTATION VIOLATION (SEG1)                <---- 段1，97-128=-31
  VA  2: 0x00000035 (decimal:   53) --> SEGMENTATION VIOLATION (SEG0)                <---- 段0，53 > 20
  VA  3: 0x00000021 (decimal:   33) --> SEGMENTATION VIOLATION (SEG0)                <---- 段0，33 > 20
  VA  4: 0x00000041 (decimal:   65) --> SEGMENTATION VIOLATION (SEG1)                <---- 段1，65-128=-63
```

随机种子为 1

```bash
./segmentation.py -a 128 -p 512 -b 0 -l 20 -B 512 -L 20 -s 1 -c

# 输出
ARG seed 1
ARG address space size 128
ARG phys mem size 512

Segment register information:

  Segment 0 base  (grows positive) : 0x00000000 (decimal 0)
  Segment 0 limit                  : 20

  Segment 1 base  (grows negative) : 0x00000200 (decimal 512)
  Segment 1 limit                  : 20

Virtual Address Trace
  VA  0: 0x00000011 (decimal:   17) --> VALID in SEG0: 0x00000011 (decimal:   17)    <---- 段0，17 < 20
  VA  1: 0x0000006c (decimal:  108) --> VALID in SEG1: 0x000001ec (decimal:  492)    <---- 段1，108-128=-20
  VA  2: 0x00000061 (decimal:   97) --> SEGMENTATION VIOLATION (SEG1)                <---- 段1，97-128=-31
  VA  3: 0x00000020 (decimal:   32) --> SEGMENTATION VIOLATION (SEG0)                <---- 段0，32 > 20
  VA  4: 0x0000003f (decimal:   63) --> SEGMENTATION VIOLATION (SEG0)                <---- 段0，63 > 20
```

随机种子为 2

```bash
./segmentation.py -a 128 -p 512 -b 0 -l 20 -B 512 -L 20 -s 2 -c

# 输出
ARG seed 2
ARG address space size 128
ARG phys mem size 512

Segment register information:

  Segment 0 base  (grows positive) : 0x00000000 (decimal 0)
  Segment 0 limit                  : 20

  Segment 1 base  (grows negative) : 0x00000200 (decimal 512)
  Segment 1 limit                  : 20

Virtual Address Trace
  VA  0: 0x0000007a (decimal:  122) --> VALID in SEG1: 0x000001fa (decimal:  506)    <---- 段1，122-128=-6
  VA  1: 0x00000079 (decimal:  121) --> VALID in SEG1: 0x000001f9 (decimal:  505)    <---- 段1，121-128=-7
  VA  2: 0x00000007 (decimal:    7) --> VALID in SEG0: 0x00000007 (decimal:    7)    <---- 段0，  7 < 20
  VA  3: 0x0000000a (decimal:   10) --> VALID in SEG0: 0x0000000a (decimal:   10)    <---- 段0， 10 < 20
  VA  4: 0x0000006a (decimal:  106) --> SEGMENTATION VIOLATION (SEG1)                <---- 段0，106 > 20
```

### 2

根据参数 `-a 128 -p 512 -b 0 -l 20 -B 512 -L 20`
- 段0 中最高的合法虚拟地址：19
- 段1 中最低的合法虚拟地址：108
- 整个地址空间中
  - 最低的非法地址：20
  - 最高的非法地址：107

运行 `-A` 参数进行测试

```bash
./segmentation.py -a 128 -p 512 -b 0 -l 20 -B 512 -L 20 -A 18,19,20,107,108,109 -c

# 输出
ARG seed 0
ARG address space size 128
ARG phys mem size 512

Segment register information:

  Segment 0 base  (grows positive) : 0x00000000 (decimal 0)
  Segment 0 limit                  : 20

  Segment 1 base  (grows negative) : 0x00000200 (decimal 512)
  Segment 1 limit                  : 20

Virtual Address Trace
  VA  0: 0x00000012 (decimal:   18) --> VALID in SEG0: 0x00000012 (decimal:   18)    <---- 段0，18 < 20
  VA  1: 0x00000013 (decimal:   19) --> VALID in SEG0: 0x00000013 (decimal:   19)    <---- 段0，19 < 20
  VA  2: 0x00000014 (decimal:   20) --> SEGMENTATION VIOLATION (SEG0)                <---- 段0，20 >= 20
  VA  3: 0x0000006b (decimal:  107) --> SEGMENTATION VIOLATION (SEG1)                <---- 段1，107-128=-21
  VA  4: 0x0000006c (decimal:  108) --> VALID in SEG1: 0x000001ec (decimal:  492)    <---- 段1，108-128=-20
  VA  5: 0x0000006d (decimal:  109) --> VALID in SEG1: 0x000001ed (decimal:  493)    <---- 段1，109-128=-19
```

### 3

如何设置基址寄存器和界限寄存器使得以下地址序列结果为：有效-有效-无效-...-无效-有效-有效
- 128 字节物理内存
- 16 字节地址空间

1. 首尾各 2 个地址有效，因此段0和段1的界限寄存器都是 2
2. 地址范围 0~15，因此段0的基址寄存器为0，段1的基址寄存器为 16

```bash
./segmentation.py -a 16 -p 128 -A 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 -b 0 -l 2 -B 16 -L 2 -c

# 输出
ARG seed 0
ARG address space size 16
ARG phys mem size 128

Segment register information:

  Segment 0 base  (grows positive) : 0x00000000 (decimal 0)
  Segment 0 limit                  : 2

  Segment 1 base  (grows negative) : 0x00000010 (decimal 16)
  Segment 1 limit                  : 2

Virtual Address Trace
  VA  0: 0x00000000 (decimal:    0) --> VALID in SEG0: 0x00000000 (decimal:    0)    <---- 段0,  0 < 2
  VA  1: 0x00000001 (decimal:    1) --> VALID in SEG0: 0x00000001 (decimal:    1)    <---- 段0,  1 < 2
  VA  2: 0x00000002 (decimal:    2) --> SEGMENTATION VIOLATION (SEG0)                <---- 段0,  2 >= 2
  VA  3: 0x00000003 (decimal:    3) --> SEGMENTATION VIOLATION (SEG0)                <---- 段0,  3 > 2
  VA  4: 0x00000004 (decimal:    4) --> SEGMENTATION VIOLATION (SEG0)                <---- 段0,  4 > 2
  VA  5: 0x00000005 (decimal:    5) --> SEGMENTATION VIOLATION (SEG0)                <---- 段0,  5 > 2
  VA  6: 0x00000006 (decimal:    6) --> SEGMENTATION VIOLATION (SEG0)                <---- 段0,  6 > 2
  VA  7: 0x00000007 (decimal:    7) --> SEGMENTATION VIOLATION (SEG0)                <---- 段0,  7 > 2
  VA  8: 0x00000008 (decimal:    8) --> SEGMENTATION VIOLATION (SEG1)                <---- 段0,  8-16=-8
  VA  9: 0x00000009 (decimal:    9) --> SEGMENTATION VIOLATION (SEG1)                <---- 段0,  9-16=-7
  VA 10: 0x0000000a (decimal:   10) --> SEGMENTATION VIOLATION (SEG1)                <---- 段0, 10-16=-6
  VA 11: 0x0000000b (decimal:   11) --> SEGMENTATION VIOLATION (SEG1)                <---- 段0, 11-16=-5
  VA 12: 0x0000000c (decimal:   12) --> SEGMENTATION VIOLATION (SEG1)                <---- 段0, 12-16=-4
  VA 13: 0x0000000d (decimal:   13) --> SEGMENTATION VIOLATION (SEG1)                <---- 段0, 13-16=-3
  VA 14: 0x0000000e (decimal:   14) --> VALID in SEG1: 0x0000000e (decimal:   14)    <---- 段0, 14-16=-2
  VA 15: 0x0000000f (decimal:   15) --> VALID in SEG1: 0x0000000f (decimal:   15)    <---- 段0, 15-16=-1
```

### 4

构造参数，使得 90% 随机生成的虚拟地址有效
- 段0 和段1 使用虚拟地址空间 90% 的地址即可

```bash
./segmentation.py -a 10 -p 128 -A 0,1,2,3,4,5,6,7,8,9 -b 0 -l 5 -B 10 -L 4 -c

# 输出
ARG seed 0
ARG address space size 10
ARG phys mem size 128

Segment register information:

  Segment 0 base  (grows positive) : 0x00000000 (decimal 0)
  Segment 0 limit                  : 5

  Segment 1 base  (grows negative) : 0x0000000a (decimal 10)
  Segment 1 limit                  : 4

Virtual Address Trace
  VA  0: 0x00000000 (decimal:    0) --> VALID in SEG0: 0x00000000 (decimal:    0)    <---- 段0, 0 < 5
  VA  1: 0x00000001 (decimal:    1) --> VALID in SEG0: 0x00000001 (decimal:    1)    <---- 段0, 1 < 5
  VA  2: 0x00000002 (decimal:    2) --> VALID in SEG0: 0x00000002 (decimal:    2)    <---- 段0, 2 < 5
  VA  3: 0x00000003 (decimal:    3) --> VALID in SEG0: 0x00000003 (decimal:    3)    <---- 段0, 3 < 5
  VA  4: 0x00000004 (decimal:    4) --> VALID in SEG0: 0x00000004 (decimal:    4)    <---- 段0, 4 < 5
  VA  5: 0x00000005 (decimal:    5) --> SEGMENTATION VIOLATION (SEG1)                <---- 段1, 5-10=-5
  VA  6: 0x00000006 (decimal:    6) --> VALID in SEG1: 0x00000006 (decimal:    6)    <---- 段1, 6-10=-4
  VA  7: 0x00000007 (decimal:    7) --> VALID in SEG1: 0x00000007 (decimal:    7)    <---- 段1, 7-10=-3
  VA  8: 0x00000008 (decimal:    8) --> VALID in SEG1: 0x00000008 (decimal:    8)    <---- 段1, 8-10=-2
  VA  9: 0x00000009 (decimal:    9) --> VALID in SEG1: 0x00000009 (decimal:    9)    <---- 段1, 9-10=-1
```

### 5

构造参数，使所有虚拟地址无效
- 界限寄存器全部为 0 即可

```bash
./segmentation.py -l 0 -L 0 -c

# 输出
ARG seed 0
ARG address space size 1k
ARG phys mem size 16k

Segment register information:

  Segment 0 base  (grows positive) : 0x0000360b (decimal 13835)
  Segment 0 limit                  : 0

  Segment 1 base  (grows negative) : 0x00003082 (decimal 12418)
  Segment 1 limit                  : 0

Virtual Address Trace
  VA  0: 0x000001ae (decimal:  430) --> SEGMENTATION VIOLATION (SEG0)    <---- 段0, 430 > 0
  VA  1: 0x00000109 (decimal:  265) --> SEGMENTATION VIOLATION (SEG0)    <---- 段0, 265 > 0
  VA  2: 0x0000020b (decimal:  523) --> SEGMENTATION VIOLATION (SEG1)    <---- 段1, 523-1024=-501
  VA  3: 0x0000019e (decimal:  414) --> SEGMENTATION VIOLATION (SEG0)    <---- 段0, 414 > 0
  VA  4: 0x00000322 (decimal:  802) --> SEGMENTATION VIOLATION (SEG1)    <---- 段1, 802-1024=-222
```

遍历整个地址空间

```bash
./segmentation.py -a 10 -p 128 -A 0,1,2,3,4,5,6,7,8,9 -b 0 -l 0 -B 10 -L 0 -c

# 输出
ARG seed 0
ARG address space size 10
ARG phys mem size 128

Segment register information:

  Segment 0 base  (grows positive) : 0x00000000 (decimal 0)
  Segment 0 limit                  : 0

  Segment 1 base  (grows negative) : 0x0000000a (decimal 10)
  Segment 1 limit                  : 0

Virtual Address Trace
  VA  0: 0x00000000 (decimal:    0) --> SEGMENTATION VIOLATION (SEG0)    <---- 段0, 0 >= 0
  VA  1: 0x00000001 (decimal:    1) --> SEGMENTATION VIOLATION (SEG0)    <---- 段0, 1 > 0
  VA  2: 0x00000002 (decimal:    2) --> SEGMENTATION VIOLATION (SEG0)    <---- 段0, 2 > 0
  VA  3: 0x00000003 (decimal:    3) --> SEGMENTATION VIOLATION (SEG0)    <---- 段0, 3 > 0
  VA  4: 0x00000004 (decimal:    4) --> SEGMENTATION VIOLATION (SEG0)    <---- 段0, 4 > 0
  VA  5: 0x00000005 (decimal:    5) --> SEGMENTATION VIOLATION (SEG1)    <---- 段1, 5-10=-5
  VA  6: 0x00000006 (decimal:    6) --> SEGMENTATION VIOLATION (SEG1)    <---- 段1, 6-10=-4
  VA  7: 0x00000007 (decimal:    7) --> SEGMENTATION VIOLATION (SEG1)    <---- 段1, 7-10=-3
  VA  8: 0x00000008 (decimal:    8) --> SEGMENTATION VIOLATION (SEG1)    <---- 段1, 8-10=-2
  VA  9: 0x00000009 (decimal:    9) --> SEGMENTATION VIOLATION (SEG1)    <---- 段1, 9-10=-1
```