## 15 Address Translation

首先了解一下程序的参数和默认值

```python
parser = OptionParser()
# 随机种子
parser.add_option('-s', '--seed',      default=0,     help='the random seed',                                action='store', type='int', dest='seed')
# 地址空间大小，默认为 1k
parser.add_option('-a', '--asize',     default='1k',  help='address space size (e.g., 16, 64k, 32m, 1g)',    action='store', type='string', dest='asize')
# 物理内存大小，默认为 16k
parser.add_option('-p', '--physmem',   default='16k', help='physical memory size (e.g., 16, 64k, 32m, 1g)',  action='store', type='string', dest='psize')
# 随机生成的虚拟地址数量，默认为 5
parser.add_option('-n', '--addresses', default=5,     help='number of virtual addresses to generate',        action='store', type='int', dest='num')
# 基址寄存器
parser.add_option('-b', '--b',         default='-1',  help='value of base register',                         action='store', type='string', dest='base')
# 界限寄存器
parser.add_option('-l', '--l',         default='-1',  help='value of limit register',                        action='store', type='string', dest='limit')
# 计算答案
parser.add_option('-c', '--compute',   default=False, help='compute answers for me',                         action='store_true', dest='solve')


(options, args) = parser.parse_args()
```

动态重定位
- 基址寄存器（base）
- 界限寄存器（bound/limit）
  - 边界寄存器

假设地址空间分为三个部分：代码、固定大小的栈、向下增长的堆。

```bash
  -------------- 0KB
  |    Code    |
  -------------- 2KB
  |   Stack    |
  -------------- 4KB
  |    Heap    |
  |     |      |
  |     v      |
  -------------- 7KB
  |   (free)   |
  |     ...    |
```

使用默认参数运行程序，所有地址都给出了十进制表示，因此只要将生成的虚拟地址和界限寄存器的大小比较即可。
- 基址：12418
- 界限：472
- 超出范围产生段错误（SEGMENTATION VIOLATION）

```bash
./relocation.py -c

# 输出结果
ARG seed 0
ARG address space size 1k
ARG phys mem size 16k

Base-and-Bounds register information:

  Base   : 0x00003082 (decimal 12418)
  Limit  : 472

Virtual Address Trace
  VA  0: 0x000001ae (decimal:  430) --> VALID: 0x00003230 (decimal: 12848)    <---- 430 < 472, 12418+430=12848
  VA  1: 0x00000109 (decimal:  265) --> VALID: 0x0000318b (decimal: 12683)    <---- 265 < 472, 12418+265=12683
  VA  2: 0x0000020b (decimal:  523) --> SEGMENTATION VIOLATION                <---- 523 > 472, 12418+523=12941
  VA  3: 0x0000019e (decimal:  414) --> VALID: 0x00003220 (decimal: 12832)    <---- 414 < 472, 12418+414=12832
  VA  4: 0x00000322 (decimal:  802) --> SEGMENTATION VIOLATION                <---- 802 > 472, 12418+802=13220
```

### 1

随机种子为 1
- 基址：13884
- 界限：290

```bash
./relocation.py -s 1 -c

# 输出
ARG seed 1
ARG address space size 1k
ARG phys mem size 16k

Base-and-Bounds register information:

  Base   : 0x0000363c (decimal 13884)
  Limit  : 290

Virtual Address Trace
  VA  0: 0x0000030e (decimal:  782) --> SEGMENTATION VIOLATION                <---- 782 > 290
  VA  1: 0x00000105 (decimal:  261) --> VALID: 0x00003741 (decimal: 14145)    <---- 261 < 290, 13884+261=14145
  VA  2: 0x000001fb (decimal:  507) --> SEGMENTATION VIOLATION                <---- 507 > 290
  VA  3: 0x000001cc (decimal:  460) --> SEGMENTATION VIOLATION                <---- 460 > 290
  VA  4: 0x0000029b (decimal:  667) --> SEGMENTATION VIOLATION                <---- 667 > 290
```

随机种子为 2
- 基址：15529
- 界限：500

```bash
./relocation.py -s 2 -c

# 输出
ARG seed 2
ARG address space size 1k
ARG phys mem size 16k

Base-and-Bounds register information:

  Base   : 0x00003ca9 (decimal 15529)
  Limit  : 500

Virtual Address Trace
  VA  0: 0x00000039 (decimal:   57) --> VALID: 0x00003ce2 (decimal: 15586)    <----  57 < 500, 15529+57=15586
  VA  1: 0x00000056 (decimal:   86) --> VALID: 0x00003cff (decimal: 15615)    <----  86 < 500, 15529+86=15615
  VA  2: 0x00000357 (decimal:  855) --> SEGMENTATION VIOLATION                <---- 855 > 500
  VA  3: 0x000002f1 (decimal:  753) --> SEGMENTATION VIOLATION                <---- 753 > 500
  VA  4: 0x000002ad (decimal:  685) --> SEGMENTATION VIOLATION                <---- 685 > 500
```

随机种子为 3
- 基址：8916
- 界限：316

```bash
./relocation.py -s 3 -c

# 输出
ARG seed 3
ARG address space size 1k
ARG phys mem size 16k

Base-and-Bounds register information:

  Base   : 0x000022d4 (decimal 8916)
  Limit  : 316

Virtual Address Trace
  VA  0: 0x0000017a (decimal:  378) --> SEGMENTATION VIOLATION               <---- 378 > 316
  VA  1: 0x0000026a (decimal:  618) --> SEGMENTATION VIOLATION               <---- 618 > 316
  VA  2: 0x00000280 (decimal:  640) --> SEGMENTATION VIOLATION               <---- 640 > 316
  VA  3: 0x00000043 (decimal:   67) --> VALID: 0x00002317 (decimal: 8983)    <----  67 < 316, 8916+67=8983
  VA  4: 0x0000000d (decimal:   13) --> VALID: 0x000022e1 (decimal: 8929)    <----  13 < 316, 8916+13=8929
```

### 2

基址寄存器和界限寄存器的值默认随机生成，地址空间大小为 1k，因此只要界限小于 1k 就有可能出现段错误。

```bash
./relocation.py -s 0 -n 10 -c

# 输出
ARG seed 0
ARG address space size 1k
ARG phys mem size 16k

Base-and-Bounds register information:

  Base   : 0x00003082 (decimal 12418)
  Limit  : 472

Virtual Address Trace
  VA  0: 0x000001ae (decimal:  430) --> VALID: 0x00003230 (decimal: 12848)    <---- 430 < 472, 12418+430=12848
  VA  1: 0x00000109 (decimal:  265) --> VALID: 0x0000318b (decimal: 12683)    <---- 265 < 472, 12418+265=12683
  VA  2: 0x0000020b (decimal:  523) --> SEGMENTATION VIOLATION                <---- 523 > 472
  VA  3: 0x0000019e (decimal:  414) --> VALID: 0x00003220 (decimal: 12832)    <---- 414 < 472, 12418+414=12832
  VA  4: 0x00000322 (decimal:  802) --> SEGMENTATION VIOLATION                <---- 802 > 472
  VA  5: 0x00000136 (decimal:  310) --> VALID: 0x000031b8 (decimal: 12728)    <---- 310 < 472, 12418+310=12728
  VA  6: 0x000001e8 (decimal:  488) --> SEGMENTATION VIOLATION                <---- 488 > 472
  VA  7: 0x00000255 (decimal:  597) --> SEGMENTATION VIOLATION                <---- 597 > 472
  VA  8: 0x000003a1 (decimal:  929) --> SEGMENTATION VIOLATION                <---- 929 > 472
  VA  9: 0x00000204 (decimal:  516) --> SEGMENTATION VIOLATION                <---- 516 > 472
```

确保所有生成的虚拟地址都处于边界内，界限寄存器应该设置为 1k 。

```bash
./relocation.py -s 0 -n 10 -l 1k -c

# 输出
ARG seed 0
ARG address space size 1k
ARG phys mem size 16k

Base-and-Bounds register information:

  Base   : 0x0000360b (decimal 13835)
  Limit  : 1024

Virtual Address Trace
  VA  0: 0x00000308 (decimal:  776) --> VALID: 0x00003913 (decimal: 14611)    <---- 776 < 1024, 13835+776=14611
  VA  1: 0x000001ae (decimal:  430) --> VALID: 0x000037b9 (decimal: 14265)    <---- 430 < 1024, 13835+430=14265
  VA  2: 0x00000109 (decimal:  265) --> VALID: 0x00003714 (decimal: 14100)    <---- 265 < 1024, 13835+265=14100
  VA  3: 0x0000020b (decimal:  523) --> VALID: 0x00003816 (decimal: 14358)    <---- 523 < 1024, 13835+523=14358
  VA  4: 0x0000019e (decimal:  414) --> VALID: 0x000037a9 (decimal: 14249)    <---- 414 < 1024, 13835+414=14249
  VA  5: 0x00000322 (decimal:  802) --> VALID: 0x0000392d (decimal: 14637)    <---- 802 < 1024, 13835+802=14637
  VA  6: 0x00000136 (decimal:  310) --> VALID: 0x00003741 (decimal: 14145)    <---- 310 < 1024, 13835+310=14145
  VA  7: 0x000001e8 (decimal:  488) --> VALID: 0x000037f3 (decimal: 14323)    <---- 488 < 1024, 13835+488=14323
  VA  8: 0x00000255 (decimal:  597) --> VALID: 0x00003860 (decimal: 14432)    <---- 597 < 1024, 13835+597=14432
  VA  9: 0x000003a1 (decimal:  929) --> VALID: 0x000039ac (decimal: 14764)    <---- 929 < 1024, 13835+929=14764
```

### 3

虚拟地址大小为 1k，当界限大小为 100 时，生成的虚拟地址大半都超出范围。

```bash
./relocation.py -s 1 -n 10 -l 100 -c

# 输出
ARG seed 1
ARG address space size 1k
ARG phys mem size 16k

Base-and-Bounds register information:

  Base   : 0x00000899 (decimal 2201)
  Limit  : 100

Virtual Address Trace
  VA  0: 0x00000363 (decimal:  867) --> SEGMENTATION VIOLATION               <---- 867 > 100
  VA  1: 0x0000030e (decimal:  782) --> SEGMENTATION VIOLATION               <---- 782 > 100
  VA  2: 0x00000105 (decimal:  261) --> SEGMENTATION VIOLATION               <---- 261 > 100
  VA  3: 0x000001fb (decimal:  507) --> SEGMENTATION VIOLATION               <---- 507 > 100
  VA  4: 0x000001cc (decimal:  460) --> SEGMENTATION VIOLATION               <---- 460 > 100
  VA  5: 0x0000029b (decimal:  667) --> SEGMENTATION VIOLATION               <---- 667 > 100
  VA  6: 0x00000327 (decimal:  807) --> SEGMENTATION VIOLATION               <---- 807 > 100
  VA  7: 0x00000060 (decimal:   96) --> VALID: 0x000008f9 (decimal: 2297)    <----  96 < 100, 2201+96=2297
  VA  8: 0x0000001d (decimal:   29) --> VALID: 0x000008b6 (decimal: 2230)    <----  29 < 100, 2201+29=2230
  VA  9: 0x00000357 (decimal:  855) --> SEGMENTATION VIOLATION               <---- 855 > 100
```

可以设置界限的最大值是多少，以便地址空间仍然完全放在物理内存中
- 物理内存 16k，因此界限的最大值为 16k - base = 16384 - 2201 = 14183
- 由于从 0 开始编号，所以界限的最大值实际是 14183 -1 = 14182

```bash
./relocation.py -s 1 -n 10 -l 14182 -c

# 输出
ARG seed 1
ARG address space size 1k
ARG phys mem size 16k

Base-and-Bounds register information:

  Base   : 0x00000899 (decimal 2201)
  Limit  : 14182

Virtual Address Trace
  VA  0: 0x00000363 (decimal:  867) --> VALID: 0x00000bfc (decimal: 3068)    <---- 867 < 14182, 14182+867=3068
  VA  1: 0x0000030e (decimal:  782) --> VALID: 0x00000ba7 (decimal: 2983)    <---- 782 < 14182, 14182+782=2983
  VA  2: 0x00000105 (decimal:  261) --> VALID: 0x0000099e (decimal: 2462)    <---- 261 < 14182, 14182+261=2462
  VA  3: 0x000001fb (decimal:  507) --> VALID: 0x00000a94 (decimal: 2708)    <---- 507 < 14182, 14182+507=2708
  VA  4: 0x000001cc (decimal:  460) --> VALID: 0x00000a65 (decimal: 2661)    <---- 460 < 14182, 14182+460=2661
  VA  5: 0x0000029b (decimal:  667) --> VALID: 0x00000b34 (decimal: 2868)    <---- 667 < 14182, 14182+667=2868
  VA  6: 0x00000327 (decimal:  807) --> VALID: 0x00000bc0 (decimal: 3008)    <---- 807 < 14182, 14182+807=3008
  VA  7: 0x00000060 (decimal:   96) --> VALID: 0x000008f9 (decimal: 2297)    <----  96 < 14182, 14182+96=2297
  VA  8: 0x0000001d (decimal:   29) --> VALID: 0x000008b6 (decimal: 2230)    <----  29 < 14182, 14182+29=2230
  VA  9: 0x00000357 (decimal:  855) --> VALID: 0x00000bf0 (decimal: 3056)    <---- 855 < 14182, 14182+855=3056
```

### 4

使用更大的地址空间（`-a`）和更大的物理内存（`-p`）
- 地址空间 2k，物理内存 24k

```bash
./relocation.py -s 1 -n 10 -l 100 -a 2k -p 24k -c

# 输出
ARG seed 1
ARG address space size 2k
ARG phys mem size 24k

Base-and-Bounds register information:

  Base   : 0x00000ce6 (decimal 3302)
  Limit  : 100

Virtual Address Trace
  VA  0: 0x000006c7 (decimal: 1735) --> SEGMENTATION VIOLATION               <---- 1735 > 100
  VA  1: 0x0000061c (decimal: 1564) --> SEGMENTATION VIOLATION               <---- 1564 > 100
  VA  2: 0x0000020a (decimal:  522) --> SEGMENTATION VIOLATION               <----  522 > 100
  VA  3: 0x000003f6 (decimal: 1014) --> SEGMENTATION VIOLATION               <---- 1014 > 100
  VA  4: 0x00000398 (decimal:  920) --> SEGMENTATION VIOLATION               <----  920 > 100
  VA  5: 0x00000536 (decimal: 1334) --> SEGMENTATION VIOLATION               <---- 1334 > 100
  VA  6: 0x0000064f (decimal: 1615) --> SEGMENTATION VIOLATION               <---- 1615 > 100
  VA  7: 0x000000c0 (decimal:  192) --> SEGMENTATION VIOLATION               <----  192 > 100
  VA  8: 0x0000003a (decimal:   58) --> VALID: 0x00000d20 (decimal: 3360)    <----   58 < 100, 3302+58=3360
  VA  9: 0x000006af (decimal: 1711) --> SEGMENTATION VIOLATION               <---- 1711 > 100
```

同样的方法可以计算最大的界限，以便地址空间仍然完全放在物理内存中
- 24k - base = 24576 - 3302 = 21274，即界限寄存器最大值为 21274 - 1 = 21273

```bash
./relocation.py -s 1 -n 10 -l 100 -a 2k -p 24k -l 21273 -c

# 输出
ARG seed 1
ARG address space size 2k
ARG phys mem size 24k

Base-and-Bounds register information:

  Base   : 0x00000ce6 (decimal 3302)
  Limit  : 21273

Virtual Address Trace
  VA  0: 0x000006c7 (decimal: 1735) --> VALID: 0x000013ad (decimal: 5037)    <---- 1735 < 21273, 3302+1735=5037
  VA  1: 0x0000061c (decimal: 1564) --> VALID: 0x00001302 (decimal: 4866)    <---- 1564 < 21273, 3302+1564=4866
  VA  2: 0x0000020a (decimal:  522) --> VALID: 0x00000ef0 (decimal: 3824)    <----  522 < 21273, 3302+522=3824
  VA  3: 0x000003f6 (decimal: 1014) --> VALID: 0x000010dc (decimal: 4316)    <---- 1014 < 21273, 3302+1014=4316
  VA  4: 0x00000398 (decimal:  920) --> VALID: 0x0000107e (decimal: 4222)    <----  920 < 21273, 3302+920=4222
  VA  5: 0x00000536 (decimal: 1334) --> VALID: 0x0000121c (decimal: 4636)    <---- 1334 < 21273, 3302+1334=4636
  VA  6: 0x0000064f (decimal: 1615) --> VALID: 0x00001335 (decimal: 4917)    <---- 1615 < 21273, 3302+1615=4917
  VA  7: 0x000000c0 (decimal:  192) --> VALID: 0x00000da6 (decimal: 3494)    <----  192 < 21273, 3302+192=3494
  VA  8: 0x0000003a (decimal:   58) --> VALID: 0x00000d20 (decimal: 3360)    <----   58 < 21273, 3302+58=3360
  VA  9: 0x000006af (decimal: 1711) --> VALID: 0x00001395 (decimal: 5013)    <---- 1711 < 21273, 3302+1711=5013
```