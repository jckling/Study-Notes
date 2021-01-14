## 22 Swapping Policies

首先了解一下程序的参数和默认值

```python
parser = OptionParser()
# 访问页列表，默认为随机生成
parser.add_option('-a', '--addresses', default='-1',   help='a set of comma-separated pages to access; -1 means randomly generate',  action='store', type='string', dest='addresses')
# 包含访问页列表的文件
parser.add_option('-f', '--addressfile', default='',   help='a file with a bunch of addresses in it',                                action='store', type='string', dest='addressfile')
# 随机生成的访问页数量，默认为 10
parser.add_option('-n', '--numaddrs', default='10',    help='if -a (--addresses) is -1, this is the number of addrs to generate',    action='store', type='string', dest='numaddrs')
# 交换策略，默认 FIFO
parser.add_option('-p', '--policy', default='FIFO',    help='replacement policy: FIFO, LRU, MRU, OPT, UNOPT, RAND, CLOCK',                action='store', type='string', dest='policy')
# Clock算法的时钟位，默认为 2 ，即 0/1 两种状态
parser.add_option('-b', '--clockbits', default=2,      help='for CLOCK policy, how many clock bits to use',                          action='store', type='int', dest='clockbits')
# 页缓存大小，默认为 3
parser.add_option('-C', '--cachesize', default='3',    help='size of the page cache, in pages',                                      action='store', type='string', dest='cachesize')
# 随机生成的访问页的最大页号，默认为 10
parser.add_option('-m', '--maxpage', default='10',     help='if randomly generating page accesses, this is the max page number',     action='store', type='string', dest='maxpage')
# 随机种子
parser.add_option('-s', '--seed', default='0',         help='random number seed',                                                    action='store', type='string', dest='seed')
# 不显示计算答案的过程，默认显示
parser.add_option('-N', '--notrace', default=False,    help='do not print out a detailed trace',                                     action='store_true', dest='notrace')
# 计算答案
parser.add_option('-c', '--compute', default=False,    help='compute answers for me',                                                action='store_true', dest='solve')

(options, args) = parser.parse_args()
```

替换策略
- 最优替换（OPT）
- 最差替换（UNOPT）
- 先进先出（FIFO）
- 最少最近使用（LRU）
- 最多最近使用（MRU）
- 随机（RAND）
- Clock算法（CLOCK）

使用 LRU 算法，缓存大小为 3 页

```bash
./paging-policy.py --addresses=0,1,2,0,1,3,0,3,1,2,1 --policy=LRU --cachesize=3 -c

# 输出
ARG addresses 0,1,2,0,1,3,0,3,1,2,1 <---- 访问页序列
ARG addressfile                     <---- 包含访问页序列的文件
ARG numaddrs 10                     <---- 随机生成的地址数量
ARG policy LRU                      <---- 替换策略：LRU
ARG clockbits 2                     <---- Clock算法使用的时钟位数
ARG cachesize 3                     <---- 缓存大小（页）
ARG maxpage 10                      <---- 访问的最大页号
ARG seed 0                          <---- 随机数种子
ARG notrace False

Solving...

Access: 0  MISS LRU ->          [0] <- MRU Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 1  MISS LRU ->       [0, 1] <- MRU Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 2  MISS LRU ->    [0, 1, 2] <- MRU Replaced:- [Hits:0 Misses:3]     <---- 填充缓存
Access: 0  HIT  LRU ->    [1, 2, 0] <- MRU Replaced:- [Hits:1 Misses:3]     <---- 命中 0
Access: 1  HIT  LRU ->    [2, 0, 1] <- MRU Replaced:- [Hits:2 Misses:3]     <---- 命中 1
Access: 3  MISS LRU ->    [0, 1, 3] <- MRU Replaced:2 [Hits:2 Misses:4]     <---- 最少最近使用 2，替换为 3
Access: 0  HIT  LRU ->    [1, 3, 0] <- MRU Replaced:- [Hits:3 Misses:4]     <---- 命中 0
Access: 3  HIT  LRU ->    [1, 0, 3] <- MRU Replaced:- [Hits:4 Misses:4]     <---- 命中 3
Access: 1  HIT  LRU ->    [0, 3, 1] <- MRU Replaced:- [Hits:5 Misses:4]     <---- 命中 1
Access: 2  MISS LRU ->    [3, 1, 2] <- MRU Replaced:0 [Hits:5 Misses:5]     <---- 最少最近使用 0，替换为 2
Access: 1  HIT  LRU ->    [3, 2, 1] <- MRU Replaced:- [Hits:6 Misses:5]     <---- 命中 1

FINALSTATS hits 6   misses 5   hitrate 54.55                                <---- 命中率 6/11 = 54.55%
```

### Belady 异常

缓存大小的增大反而使得缓存命中率下降。

使用 FIFO 策略，缓存为 3 页时

```bash
./paging-policy.py -C 3 -a 1,2,3,4,1,2,5,1,2,3,4,5 -c

# 输出
ARG addresses 1,2,3,4,1,2,5,1,2,3,4,5
ARG addressfile 
ARG numaddrs 10
ARG policy FIFO
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 1  MISS FirstIn ->          [1] <- Lastin  Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 2  MISS FirstIn ->       [1, 2] <- Lastin  Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 3  MISS FirstIn ->    [1, 2, 3] <- Lastin  Replaced:- [Hits:0 Misses:3]     <---- 填充缓存
Access: 4  MISS FirstIn ->    [2, 3, 4] <- Lastin  Replaced:1 [Hits:0 Misses:4]     <---- 1 替换为 2
Access: 1  MISS FirstIn ->    [3, 4, 1] <- Lastin  Replaced:2 [Hits:0 Misses:5]     <---- 2 替换为 3
Access: 2  MISS FirstIn ->    [4, 1, 2] <- Lastin  Replaced:3 [Hits:0 Misses:6]     <---- 3 替换为 4
Access: 5  MISS FirstIn ->    [1, 2, 5] <- Lastin  Replaced:4 [Hits:0 Misses:7]     <---- 4 替换为 5
Access: 1  HIT  FirstIn ->    [1, 2, 5] <- Lastin  Replaced:- [Hits:1 Misses:7]     <---- 命中 1
Access: 2  HIT  FirstIn ->    [1, 2, 5] <- Lastin  Replaced:- [Hits:2 Misses:7]     <---- 命中 2
Access: 3  MISS FirstIn ->    [2, 5, 3] <- Lastin  Replaced:1 [Hits:2 Misses:8]     <---- 1 替换为 3
Access: 4  MISS FirstIn ->    [5, 3, 4] <- Lastin  Replaced:2 [Hits:2 Misses:9]     <---- 2 替换为 5
Access: 5  HIT  FirstIn ->    [5, 3, 4] <- Lastin  Replaced:- [Hits:3 Misses:9]     <---- 命中 5

FINALSTATS hits 3   misses 9   hitrate 25.00                                        <---- 命中率 3/12 = 25.00%
```

使用 FIFO 策略，缓存为 4 页时

```bash
./paging-policy.py -C 4 -a 1,2,3,4,1,2,5,1,2,3,4,5 -c

# 输出
ARG addresses 1,2,3,4,1,2,5,1,2,3,4,5
ARG addressfile 
ARG numaddrs 10
ARG policy FIFO
ARG clockbits 2
ARG cachesize 4
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 1  MISS FirstIn ->          [1] <- Lastin  Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 2  MISS FirstIn ->       [1, 2] <- Lastin  Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 3  MISS FirstIn ->    [1, 2, 3] <- Lastin  Replaced:- [Hits:0 Misses:3]     <---- 填充缓存
Access: 4  MISS FirstIn -> [1, 2, 3, 4] <- Lastin  Replaced:- [Hits:0 Misses:4]     <---- 填充缓存
Access: 1  HIT  FirstIn -> [1, 2, 3, 4] <- Lastin  Replaced:- [Hits:1 Misses:4]     <---- 命中 1
Access: 2  HIT  FirstIn -> [1, 2, 3, 4] <- Lastin  Replaced:- [Hits:2 Misses:4]     <---- 命中 2
Access: 5  MISS FirstIn -> [2, 3, 4, 5] <- Lastin  Replaced:1 [Hits:2 Misses:5]     <---- 1 替换为 5
Access: 1  MISS FirstIn -> [3, 4, 5, 1] <- Lastin  Replaced:2 [Hits:2 Misses:6]     <---- 2 替换为 1
Access: 2  MISS FirstIn -> [4, 5, 1, 2] <- Lastin  Replaced:3 [Hits:2 Misses:7]     <---- 3 替换为 2
Access: 3  MISS FirstIn -> [5, 1, 2, 3] <- Lastin  Replaced:4 [Hits:2 Misses:8]     <---- 4 替换为 3
Access: 4  MISS FirstIn -> [1, 2, 3, 4] <- Lastin  Replaced:5 [Hits:2 Misses:9]     <---- 5 替换为 4
Access: 5  MISS FirstIn -> [2, 3, 4, 5] <- Lastin  Replaced:1 [Hits:2 Misses:10]    <---- 1 替换为 5

FINALSTATS hits 2   misses 10   hitrate 16.67                                       <---- 命中率 2/12 = 16.67%
```

### 1

#### 随机种子为 0

地址引用序列

```
    8, 7, 4, 2, 5, 4, 7, 3, 4, 5
```

1. OPT

```bash
./paging-policy.py -n 10 -s 0 -p OPT -c

# 输出
ARG addresses -1    <---- 访问页序列
ARG addressfile     <---- 包含访问页序列的文件
ARG numaddrs 10     <---- 随机生成的地址数量
ARG policy OPT      <---- 替换策略：OPT
ARG clockbits 2     <---- Clock算法使用的时钟位数
ARG cachesize 3     <---- 缓存大小（页）
ARG maxpage 10      <---- 访问的最大页号
ARG seed 0          <---- 随机数种子
ARG notrace False

Solving...

Access: 8  MISS Left  ->          [8] <- Right Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 7  MISS Left  ->       [8, 7] <- Right Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 4  MISS Left  ->    [8, 7, 4] <- Right Replaced:- [Hits:0 Misses:3]     <---- 填充缓存
Access: 2  MISS Left  ->    [7, 4, 2] <- Right Replaced:8 [Hits:0 Misses:4]     <---- 最优替换 8，替换为 2
Access: 5  MISS Left  ->    [7, 4, 5] <- Right Replaced:2 [Hits:0 Misses:5]     <---- 最优替换 2，替换为 5
Access: 4  HIT  Left  ->    [7, 4, 5] <- Right Replaced:- [Hits:1 Misses:5]     <---- 命中 4
Access: 7  HIT  Left  ->    [7, 4, 5] <- Right Replaced:- [Hits:2 Misses:5]     <---- 命中 7
Access: 3  MISS Left  ->    [4, 5, 3] <- Right Replaced:7 [Hits:2 Misses:6]     <---- 最优替换 7，替换为 3
Access: 4  HIT  Left  ->    [4, 5, 3] <- Right Replaced:- [Hits:3 Misses:6]     <---- 命中 4
Access: 5  HIT  Left  ->    [4, 5, 3] <- Right Replaced:- [Hits:4 Misses:6]     <---- 命中 5

FINALSTATS hits 4   misses 6   hitrate 40.00                                    <---- 命中率 4/10 = 40.00%
```

2. FIFO

```bash
./paging-policy.py -n 10 -s 0 -p FIFO -c

# 输出
ARG addresses -1
ARG addressfile 
ARG numaddrs 10
ARG policy FIFO
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 8  MISS FirstIn ->          [8] <- Lastin  Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 7  MISS FirstIn ->       [8, 7] <- Lastin  Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 4  MISS FirstIn ->    [8, 7, 4] <- Lastin  Replaced:- [Hits:0 Misses:3]     <---- 填充缓存
Access: 2  MISS FirstIn ->    [7, 4, 2] <- Lastin  Replaced:8 [Hits:0 Misses:4]     <---- 8 替换为 2
Access: 5  MISS FirstIn ->    [4, 2, 5] <- Lastin  Replaced:7 [Hits:0 Misses:5]     <---- 7 替换为 5
Access: 4  HIT  FirstIn ->    [4, 2, 5] <- Lastin  Replaced:- [Hits:1 Misses:5]     <---- 命中 4
Access: 7  MISS FirstIn ->    [2, 5, 7] <- Lastin  Replaced:4 [Hits:1 Misses:6]     <---- 4 替换为 7
Access: 3  MISS FirstIn ->    [5, 7, 3] <- Lastin  Replaced:2 [Hits:1 Misses:7]     <---- 2 替换为 3
Access: 4  MISS FirstIn ->    [7, 3, 4] <- Lastin  Replaced:5 [Hits:1 Misses:8]     <---- 5 替换为 4
Access: 5  MISS FirstIn ->    [3, 4, 5] <- Lastin  Replaced:7 [Hits:1 Misses:9]     <---- 7 替换为 5

FINALSTATS hits 1   misses 9   hitrate 10.00                                        <---- 命中率 1/10 = 10.00%
```

3. LRU

```bash
./paging-policy.py -n 10 -s 0 -p LRU -c

# 输出
ARG addresses -1
ARG addressfile 
ARG numaddrs 10
ARG policy LRU
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 8  MISS LRU ->          [8] <- MRU Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 7  MISS LRU ->       [8, 7] <- MRU Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 4  MISS LRU ->    [8, 7, 4] <- MRU Replaced:- [Hits:0 Misses:3]     <---- 填充缓存
Access: 2  MISS LRU ->    [7, 4, 2] <- MRU Replaced:8 [Hits:0 Misses:4]     <---- 最近最少使用 8，替换为 2
Access: 5  MISS LRU ->    [4, 2, 5] <- MRU Replaced:7 [Hits:0 Misses:5]     <---- 最近最少使用 7，替换为 5
Access: 4  HIT  LRU ->    [2, 5, 4] <- MRU Replaced:- [Hits:1 Misses:5]     <---- 命中 4
Access: 7  MISS LRU ->    [5, 4, 7] <- MRU Replaced:2 [Hits:1 Misses:6]     <---- 最近最少使用 2，替换为 7
Access: 3  MISS LRU ->    [4, 7, 3] <- MRU Replaced:5 [Hits:1 Misses:7]     <---- 最近最少使用 5，替换为 3
Access: 4  HIT  LRU ->    [7, 3, 4] <- MRU Replaced:- [Hits:2 Misses:7]     <---- 命中 4
Access: 5  MISS LRU ->    [3, 4, 5] <- MRU Replaced:7 [Hits:2 Misses:8]     <---- 最近最少使用 7，替换为 5

FINALSTATS hits 2   misses 8   hitrate 20.00                                <---- 命中率 2/10 = 20.00%
```

#### 随机种子为 1

地址引用序列

```
    1, 8, 7, 2, 4, 4, 6, 7, 0, 0
```

1. OPT

```bash
./paging-policy.py -n 10 -s 1 -p OPT -c

# 输出
ARG addresses -1
ARG addressfile 
ARG numaddrs 10
ARG policy OPT
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 1
ARG notrace False

Solving...

Access: 1  MISS Left  ->          [1] <- Right Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 8  MISS Left  ->       [1, 8] <- Right Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 7  MISS Left  ->    [1, 8, 7] <- Right Replaced:- [Hits:0 Misses:3]     <---- 填充缓存
Access: 2  MISS Left  ->    [1, 7, 2] <- Right Replaced:8 [Hits:0 Misses:4]     <---- 最优替换 8，替换为 2 【这里将 1 进行替换也可以】
Access: 4  MISS Left  ->    [1, 7, 4] <- Right Replaced:2 [Hits:0 Misses:5]     <---- 最优替换 2，替换为 4
Access: 4  HIT  Left  ->    [1, 7, 4] <- Right Replaced:- [Hits:1 Misses:5]     <---- 命中 4
Access: 6  MISS Left  ->    [1, 7, 6] <- Right Replaced:4 [Hits:1 Misses:6]     <---- 最优替换 4，替换为 6
Access: 7  HIT  Left  ->    [1, 7, 6] <- Right Replaced:- [Hits:2 Misses:6]     <---- 命中 7
Access: 0  MISS Left  ->    [1, 7, 0] <- Right Replaced:6 [Hits:2 Misses:7]     <---- 最优替换 6，替换为 0
Access: 0  HIT  Left  ->    [1, 7, 0] <- Right Replaced:- [Hits:3 Misses:7]     <---- 命中 0

FINALSTATS hits 3   misses 7   hitrate 30.00                                    <---- 命中率 3/10 = 30.00%
```

2. FIFO

```bash
./paging-policy.py -n 10 -s 1 -p FIFO -c

# 输出
ARG addresses -1
ARG addressfile 
ARG numaddrs 10
ARG policy FIFO
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 1
ARG notrace False

Solving...

Access: 1  MISS FirstIn ->          [1] <- Lastin  Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 8  MISS FirstIn ->       [1, 8] <- Lastin  Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 7  MISS FirstIn ->    [1, 8, 7] <- Lastin  Replaced:- [Hits:0 Misses:3]     <---- 填充缓存
Access: 2  MISS FirstIn ->    [8, 7, 2] <- Lastin  Replaced:1 [Hits:0 Misses:4]     <---- 1 替换为 2
Access: 4  MISS FirstIn ->    [7, 2, 4] <- Lastin  Replaced:8 [Hits:0 Misses:5]     <---- 8 替换为 4
Access: 4  HIT  FirstIn ->    [7, 2, 4] <- Lastin  Replaced:- [Hits:1 Misses:5]     <---- 命中 4
Access: 6  MISS FirstIn ->    [2, 4, 6] <- Lastin  Replaced:7 [Hits:1 Misses:6]     <---- 7 替换为 6
Access: 7  MISS FirstIn ->    [4, 6, 7] <- Lastin  Replaced:2 [Hits:1 Misses:7]     <---- 2 替换为 7
Access: 0  MISS FirstIn ->    [6, 7, 0] <- Lastin  Replaced:4 [Hits:1 Misses:8]     <---- 4 替换为 0
Access: 0  HIT  FirstIn ->    [6, 7, 0] <- Lastin  Replaced:- [Hits:2 Misses:8]     <---- 命中 0

FINALSTATS hits 2   misses 8   hitrate 20.00                                        <---- 命中率 2/10 = 20.00%
```

3. LRU

```bash
./paging-policy.py -n 10 -s 1 -p LRU -c

# 输出
ARG addresses -1
ARG addressfile 
ARG numaddrs 10
ARG policy LRU
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 1
ARG notrace False

Solving...

Access: 1  MISS LRU ->          [1] <- MRU Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 8  MISS LRU ->       [1, 8] <- MRU Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 7  MISS LRU ->    [1, 8, 7] <- MRU Replaced:- [Hits:0 Misses:3]     <---- 填充缓存
Access: 2  MISS LRU ->    [8, 7, 2] <- MRU Replaced:1 [Hits:0 Misses:4]     <---- 最近最少使用 1，替换为 2
Access: 4  MISS LRU ->    [7, 2, 4] <- MRU Replaced:8 [Hits:0 Misses:5]     <---- 最近最少使用 8，替换为 4
Access: 4  HIT  LRU ->    [7, 2, 4] <- MRU Replaced:- [Hits:1 Misses:5]     <---- 命中 4
Access: 6  MISS LRU ->    [2, 4, 6] <- MRU Replaced:7 [Hits:1 Misses:6]     <---- 最近最少使用 7，替换为 5
Access: 7  MISS LRU ->    [4, 6, 7] <- MRU Replaced:2 [Hits:1 Misses:7]     <---- 最近最少使用 2，替换为 7
Access: 0  MISS LRU ->    [6, 7, 0] <- MRU Replaced:4 [Hits:1 Misses:8]     <---- 最近最少使用 4，替换为 0
Access: 0  HIT  LRU ->    [6, 7, 0] <- MRU Replaced:- [Hits:2 Misses:8]     <---- 命中 0

FINALSTATS hits 2   misses 8   hitrate 20.00                                <---- 命中率 2/10 = 20.00%
```

#### 随机种子为 2

地址引用序列

```
    9, 9, 0, 0, 8, 7, 6, 3, 6, 6
```

1. OPT

```bash
./paging-policy.py -n 10 -s 2 -p OPT -c

# 输出
ARG addresses -1
ARG addressfile 
ARG numaddrs 10
ARG policy OPT
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 2
ARG notrace False

Solving...

Access: 9  MISS Left  ->          [9] <- Right Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 9  HIT  Left  ->          [9] <- Right Replaced:- [Hits:1 Misses:1]     <---- 命中 9
Access: 0  MISS Left  ->       [9, 0] <- Right Replaced:- [Hits:1 Misses:2]     <---- 填充缓存
Access: 0  HIT  Left  ->       [9, 0] <- Right Replaced:- [Hits:2 Misses:2]     <---- 命中 0
Access: 8  MISS Left  ->    [9, 0, 8] <- Right Replaced:- [Hits:2 Misses:3]     <---- 填充缓存
Access: 7  MISS Left  ->    [9, 0, 7] <- Right Replaced:8 [Hits:2 Misses:4]     <---- 最优替换 8，替换为 7 【这里将 0 进行替换也可以】
Access: 6  MISS Left  ->    [9, 0, 6] <- Right Replaced:7 [Hits:2 Misses:5]     <---- 最优替换 7，替换为 6
Access: 3  MISS Left  ->    [9, 6, 3] <- Right Replaced:0 [Hits:2 Misses:6]     <---- 最优替换 0，替换为 3
Access: 6  HIT  Left  ->    [9, 6, 3] <- Right Replaced:- [Hits:3 Misses:6]     <---- 命中 6
Access: 6  HIT  Left  ->    [9, 6, 3] <- Right Replaced:- [Hits:4 Misses:6]     <---- 命中 6

FINALSTATS hits 4   misses 6   hitrate 40.00                                    <---- 命中率 4/10 = 40.00%
```

2. FIFO

```bash
./paging-policy.py -n 10 -s 2 -p FIFO -c

# 输出
ARG addresses -1
ARG addressfile 
ARG numaddrs 10
ARG policy FIFO
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 2
ARG notrace False

Solving...

Access: 9  MISS FirstIn ->          [9] <- Lastin  Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 9  HIT  FirstIn ->          [9] <- Lastin  Replaced:- [Hits:1 Misses:1]     <---- 命中 9
Access: 0  MISS FirstIn ->       [9, 0] <- Lastin  Replaced:- [Hits:1 Misses:2]     <---- 填充缓存
Access: 0  HIT  FirstIn ->       [9, 0] <- Lastin  Replaced:- [Hits:2 Misses:2]     <---- 命中 0
Access: 8  MISS FirstIn ->    [9, 0, 8] <- Lastin  Replaced:- [Hits:2 Misses:3]     <---- 填充缓存
Access: 7  MISS FirstIn ->    [0, 8, 7] <- Lastin  Replaced:9 [Hits:2 Misses:4]     <---- 9 替换为 7
Access: 6  MISS FirstIn ->    [8, 7, 6] <- Lastin  Replaced:0 [Hits:2 Misses:5]     <---- 0 替换为 6
Access: 3  MISS FirstIn ->    [7, 6, 3] <- Lastin  Replaced:8 [Hits:2 Misses:6]     <---- 8 替换为 3
Access: 6  HIT  FirstIn ->    [7, 6, 3] <- Lastin  Replaced:- [Hits:3 Misses:6]     <---- 命中 6
Access: 6  HIT  FirstIn ->    [7, 6, 3] <- Lastin  Replaced:- [Hits:4 Misses:6]     <---- 命中 6

FINALSTATS hits 4   misses 6   hitrate 40.00                                        <---- 命中率 4/10 = 40.00%
```

3. LRU

```bash
./paging-policy.py -n 10 -s 2 -p LRU -c

# 输出
ARG addresses -1
ARG addressfile 
ARG numaddrs 10
ARG policy LRU
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 2
ARG notrace False

Solving...

Access: 9  MISS LRU ->          [9] <- MRU Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 9  HIT  LRU ->          [9] <- MRU Replaced:- [Hits:1 Misses:1]     <---- 命中 9
Access: 0  MISS LRU ->       [9, 0] <- MRU Replaced:- [Hits:1 Misses:2]     <---- 填充缓存
Access: 0  HIT  LRU ->       [9, 0] <- MRU Replaced:- [Hits:2 Misses:2]     <---- 命中 0
Access: 8  MISS LRU ->    [9, 0, 8] <- MRU Replaced:- [Hits:2 Misses:3]     <---- 填充缓存
Access: 7  MISS LRU ->    [0, 8, 7] <- MRU Replaced:9 [Hits:2 Misses:4]     <---- 最近最少使用 9，替换为 7
Access: 6  MISS LRU ->    [8, 7, 6] <- MRU Replaced:0 [Hits:2 Misses:5]     <---- 最近最少使用 0，替换为 6
Access: 3  MISS LRU ->    [7, 6, 3] <- MRU Replaced:8 [Hits:2 Misses:6]     <---- 最近最少使用 8，替换为 3
Access: 6  HIT  LRU ->    [7, 3, 6] <- MRU Replaced:- [Hits:3 Misses:6]     <---- 命中 6
Access: 6  HIT  LRU ->    [7, 3, 6] <- MRU Replaced:- [Hits:4 Misses:6]     <---- 命中 6

FINALSTATS hits 4   misses 6   hitrate 40.00                                <---- 命中率 4/10 = 40.00%
```

### 2

缓存为 5 页时，为 FIFO、LRU、MRU 设计最差情况的地址引用序列，使其尽可能未命中，并考虑缓存需要增大多少才能提高性能，并接近 OPT 。

#### FIFO

只要待访问的页面始终不在缓存中即可。

```
    1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6
```

```bash
./paging-policy.py -p FIFO -a 1,2,3,4,5,6,1,2,3,4,5,6 -C 5 -c

# 输出
ARG addresses 1,2,3,4,5,6,1,2,3,4,5,6
ARG addressfile 
ARG numaddrs 10
ARG policy FIFO
ARG clockbits 2
ARG cachesize 5
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 1  MISS FirstIn ->          [1] <- Lastin  Replaced:- [Hits:0 Misses:1]         <---- 冷启动，填充缓存
Access: 2  MISS FirstIn ->       [1, 2] <- Lastin  Replaced:- [Hits:0 Misses:2]         <---- 填充缓存
Access: 3  MISS FirstIn ->    [1, 2, 3] <- Lastin  Replaced:- [Hits:0 Misses:3]         <---- 填充缓存
Access: 4  MISS FirstIn -> [1, 2, 3, 4] <- Lastin  Replaced:- [Hits:0 Misses:4]         <---- 填充缓存
Access: 5  MISS FirstIn -> [1, 2, 3, 4, 5] <- Lastin  Replaced:- [Hits:0 Misses:5]      <---- 填充缓存
Access: 6  MISS FirstIn -> [2, 3, 4, 5, 6] <- Lastin  Replaced:1 [Hits:0 Misses:6]      <---- 1 替换为 6
Access: 1  MISS FirstIn -> [3, 4, 5, 6, 1] <- Lastin  Replaced:2 [Hits:0 Misses:7]      <---- 2 替换为 1
Access: 2  MISS FirstIn -> [4, 5, 6, 1, 2] <- Lastin  Replaced:3 [Hits:0 Misses:8]      <---- 3 替换为 2
Access: 3  MISS FirstIn -> [5, 6, 1, 2, 3] <- Lastin  Replaced:4 [Hits:0 Misses:9]      <---- 4 替换为 3
Access: 4  MISS FirstIn -> [6, 1, 2, 3, 4] <- Lastin  Replaced:5 [Hits:0 Misses:10]     <---- 5 替换为 4
Access: 5  MISS FirstIn -> [1, 2, 3, 4, 5] <- Lastin  Replaced:6 [Hits:0 Misses:11]     <---- 6 替换为 5
Access: 6  MISS FirstIn -> [2, 3, 4, 5, 6] <- Lastin  Replaced:1 [Hits:0 Misses:12]     <---- 1 替换为 6

FINALSTATS hits 0   misses 12   hitrate 0.00                                            <---- 命中率 0/12 = 0.00%
```

只要将缓存增加到 6 页就可以提高性能，除了填充缓存时的未命中以外，其余的页访问全部命中。

```bash
./paging-policy.py -p FIFO -a 1,2,3,4,5,6,1,2,3,4,5,6 -C 6 -c

# 输出
ARG addresses 1,2,3,4,5,6,1,2,3,4,5,6
ARG addressfile 
ARG numaddrs 10
ARG policy FIFO
ARG clockbits 2
ARG cachesize 6
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 1  MISS FirstIn ->          [1] <- Lastin  Replaced:- [Hits:0 Misses:1]         <---- 冷启动，填充缓存
Access: 2  MISS FirstIn ->       [1, 2] <- Lastin  Replaced:- [Hits:0 Misses:2]         <---- 填充缓存
Access: 3  MISS FirstIn ->    [1, 2, 3] <- Lastin  Replaced:- [Hits:0 Misses:3]         <---- 填充缓存
Access: 4  MISS FirstIn -> [1, 2, 3, 4] <- Lastin  Replaced:- [Hits:0 Misses:4]         <---- 填充缓存
Access: 5  MISS FirstIn -> [1, 2, 3, 4, 5] <- Lastin  Replaced:- [Hits:0 Misses:5]      <---- 填充缓存
Access: 6  MISS FirstIn -> [1, 2, 3, 4, 5, 6] <- Lastin  Replaced:- [Hits:0 Misses:6]   <---- 填充缓存
Access: 1  HIT  FirstIn -> [1, 2, 3, 4, 5, 6] <- Lastin  Replaced:- [Hits:1 Misses:6]   <---- 命中 1
Access: 2  HIT  FirstIn -> [1, 2, 3, 4, 5, 6] <- Lastin  Replaced:- [Hits:2 Misses:6]   <---- 命中 2
Access: 3  HIT  FirstIn -> [1, 2, 3, 4, 5, 6] <- Lastin  Replaced:- [Hits:3 Misses:6]   <---- 命中 3
Access: 4  HIT  FirstIn -> [1, 2, 3, 4, 5, 6] <- Lastin  Replaced:- [Hits:4 Misses:6]   <---- 命中 4
Access: 5  HIT  FirstIn -> [1, 2, 3, 4, 5, 6] <- Lastin  Replaced:- [Hits:5 Misses:6]   <---- 命中 5
Access: 6  HIT  FirstIn -> [1, 2, 3, 4, 5, 6] <- Lastin  Replaced:- [Hits:6 Misses:6]   <---- 命中 6

FINALSTATS hits 6   misses 6   hitrate 50.00                                            <---- 命中率 6/12 = 50.00%
```

#### LRU

使用和 FIFO 相同的序列即可。
- 对于这个地址引用序列，LRU 和 FIFO 没有区别

```
    1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6
```

```bash
./paging-policy.py -p LRU -a 1,2,3,4,5,6,1,2,3,4,5,6 -C 5 -c

# 输出
ARG addresses 1,2,3,4,5,6,1,2,3,4,5,6
ARG addressfile 
ARG numaddrs 10
ARG policy LRU
ARG clockbits 2
ARG cachesize 5
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 1  MISS LRU ->          [1] <- MRU Replaced:- [Hits:0 Misses:1]         <---- 冷启动，填充缓存
Access: 2  MISS LRU ->       [1, 2] <- MRU Replaced:- [Hits:0 Misses:2]         <---- 填充缓存
Access: 3  MISS LRU ->    [1, 2, 3] <- MRU Replaced:- [Hits:0 Misses:3]         <---- 填充缓存
Access: 4  MISS LRU -> [1, 2, 3, 4] <- MRU Replaced:- [Hits:0 Misses:4]         <---- 填充缓存
Access: 5  MISS LRU -> [1, 2, 3, 4, 5] <- MRU Replaced:- [Hits:0 Misses:5]      <---- 填充缓存
Access: 6  MISS LRU -> [2, 3, 4, 5, 6] <- MRU Replaced:1 [Hits:0 Misses:6]      <---- 最近最少使用 1，替换为 6
Access: 1  MISS LRU -> [3, 4, 5, 6, 1] <- MRU Replaced:2 [Hits:0 Misses:7]      <---- 最近最少使用 2，替换为 1
Access: 2  MISS LRU -> [4, 5, 6, 1, 2] <- MRU Replaced:3 [Hits:0 Misses:8]      <---- 最近最少使用 3，替换为 2
Access: 3  MISS LRU -> [5, 6, 1, 2, 3] <- MRU Replaced:4 [Hits:0 Misses:9]      <---- 最近最少使用 4，替换为 3
Access: 4  MISS LRU -> [6, 1, 2, 3, 4] <- MRU Replaced:5 [Hits:0 Misses:10]     <---- 最近最少使用 5，替换为 4
Access: 5  MISS LRU -> [1, 2, 3, 4, 5] <- MRU Replaced:6 [Hits:0 Misses:11]     <---- 最近最少使用 6，替换为 5
Access: 6  MISS LRU -> [2, 3, 4, 5, 6] <- MRU Replaced:1 [Hits:0 Misses:12]     <---- 最近最少使用 1，替换为 6

FINALSTATS hits 0   misses 12   hitrate 0.00                                    <---- 命中率 0/12 = 0.00%
```

和 FIFO 相同，将缓存增大到 6 页即可提高性能，同样除了填充缓存的未命中之外，其余的页访问全部命中。

```bash
./paging-policy.py -p LRU -a 1,2,3,4,5,6,1,2,3,4,5,6 -C 6 -c

# 输出
ARG addresses 1,2,3,4,5,6,1,2,3,4,5,6
ARG addressfile 
ARG numaddrs 10
ARG policy LRU
ARG clockbits 2
ARG cachesize 6
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 1  MISS LRU ->          [1] <- MRU Replaced:- [Hits:0 Misses:1]         <---- 冷启动，填充缓存
Access: 2  MISS LRU ->       [1, 2] <- MRU Replaced:- [Hits:0 Misses:2]         <---- 填充缓存
Access: 3  MISS LRU ->    [1, 2, 3] <- MRU Replaced:- [Hits:0 Misses:3]         <---- 填充缓存
Access: 4  MISS LRU -> [1, 2, 3, 4] <- MRU Replaced:- [Hits:0 Misses:4]         <---- 填充缓存
Access: 5  MISS LRU -> [1, 2, 3, 4, 5] <- MRU Replaced:- [Hits:0 Misses:5]      <---- 填充缓存
Access: 6  MISS LRU -> [1, 2, 3, 4, 5, 6] <- MRU Replaced:- [Hits:0 Misses:6]   <---- 填充缓存
Access: 1  HIT  LRU -> [2, 3, 4, 5, 6, 1] <- MRU Replaced:- [Hits:1 Misses:6]   <---- 命中 1
Access: 2  HIT  LRU -> [3, 4, 5, 6, 1, 2] <- MRU Replaced:- [Hits:2 Misses:6]   <---- 命中 2
Access: 3  HIT  LRU -> [4, 5, 6, 1, 2, 3] <- MRU Replaced:- [Hits:3 Misses:6]   <---- 命中 3
Access: 4  HIT  LRU -> [5, 6, 1, 2, 3, 4] <- MRU Replaced:- [Hits:4 Misses:6]   <---- 命中 4
Access: 5  HIT  LRU -> [6, 1, 2, 3, 4, 5] <- MRU Replaced:- [Hits:5 Misses:6]   <---- 命中 5
Access: 6  HIT  LRU -> [1, 2, 3, 4, 5, 6] <- MRU Replaced:- [Hits:6 Misses:6]   <---- 命中 6

FINALSTATS hits 6   misses 6   hitrate 50.00                                    <---- 命中率 6/12 = 50.00%
```

#### MRU

优先替换最近最多使用的页面，因此填充完缓存后，不断循环访问倒数第二个加入缓存的页面和最新加入缓存的页面，将导致缓存命中率为零。

```
    1, 2, 3, 4, 5, 6, 5, 6, 5, 6, 5, 6
```

```bash
./paging-policy.py -p MRU -a 1,2,3,4,5,6,5,6,5,6,5,6 -C 5 -c

# 输出
ARG addresses 1,2,3,4,5,6,5,6,5,6,5,6
ARG addressfile 
ARG numaddrs 10
ARG policy MRU
ARG clockbits 2
ARG cachesize 5
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 1  MISS LRU ->          [1] <- MRU Replaced:- [Hits:0 Misses:1]         <---- 冷启动，填充缓存
Access: 2  MISS LRU ->       [1, 2] <- MRU Replaced:- [Hits:0 Misses:2]         <---- 填充缓存
Access: 3  MISS LRU ->    [1, 2, 3] <- MRU Replaced:- [Hits:0 Misses:3]         <---- 填充缓存
Access: 4  MISS LRU -> [1, 2, 3, 4] <- MRU Replaced:- [Hits:0 Misses:4]         <---- 填充缓存
Access: 5  MISS LRU -> [1, 2, 3, 4, 5] <- MRU Replaced:- [Hits:0 Misses:5]      <---- 填充缓存
Access: 6  MISS LRU -> [1, 2, 3, 4, 6] <- MRU Replaced:5 [Hits:0 Misses:6]      <---- 最近最多使用 5，替换为 6
Access: 5  MISS LRU -> [1, 2, 3, 4, 5] <- MRU Replaced:6 [Hits:0 Misses:7]      <---- 最近最多使用 6，替换为 5
Access: 6  MISS LRU -> [1, 2, 3, 4, 6] <- MRU Replaced:5 [Hits:0 Misses:8]      <---- 最近最多使用 5，替换为 6
Access: 5  MISS LRU -> [1, 2, 3, 4, 5] <- MRU Replaced:6 [Hits:0 Misses:9]      <---- 最近最多使用 6，替换为 5
Access: 6  MISS LRU -> [1, 2, 3, 4, 6] <- MRU Replaced:5 [Hits:0 Misses:10]     <---- 最近最多使用 5，替换为 6
Access: 5  MISS LRU -> [1, 2, 3, 4, 5] <- MRU Replaced:6 [Hits:0 Misses:11]     <---- 最近最多使用 6，替换为 5
Access: 6  MISS LRU -> [1, 2, 3, 4, 6] <- MRU Replaced:5 [Hits:0 Misses:12]     <---- 最近最多使用 5，替换为 6

FINALSTATS hits 0   misses 12   hitrate 0.00                                    <---- 命中率 0/12 = 0.00%
```

将缓存增大到 6 页即可提高性能，循环访问的页面始终在缓存内。

```bash
./paging-policy.py -p MRU -a 1,2,3,4,5,6,5,6,5,6,5,6 -C 6 -c

# 输出
ARG addresses 1,2,3,4,5,6,5,6,5,6,5,6
ARG addressfile 
ARG numaddrs 10
ARG policy MRU
ARG clockbits 2
ARG cachesize 6
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 1  MISS LRU ->          [1] <- MRU Replaced:- [Hits:0 Misses:1]         <---- 冷启动，填充缓存
Access: 2  MISS LRU ->       [1, 2] <- MRU Replaced:- [Hits:0 Misses:2]         <---- 填充缓存
Access: 3  MISS LRU ->    [1, 2, 3] <- MRU Replaced:- [Hits:0 Misses:3]         <---- 填充缓存
Access: 4  MISS LRU -> [1, 2, 3, 4] <- MRU Replaced:- [Hits:0 Misses:4]         <---- 填充缓存
Access: 5  MISS LRU -> [1, 2, 3, 4, 5] <- MRU Replaced:- [Hits:0 Misses:5]      <---- 填充缓存
Access: 6  MISS LRU -> [1, 2, 3, 4, 5, 6] <- MRU Replaced:- [Hits:0 Misses:6]   <---- 填充缓存
Access: 5  HIT  LRU -> [1, 2, 3, 4, 6, 5] <- MRU Replaced:- [Hits:1 Misses:6]   <---- 命中 5
Access: 6  HIT  LRU -> [1, 2, 3, 4, 5, 6] <- MRU Replaced:- [Hits:2 Misses:6]   <---- 命中 6
Access: 5  HIT  LRU -> [1, 2, 3, 4, 6, 5] <- MRU Replaced:- [Hits:3 Misses:6]   <---- 命中 5
Access: 6  HIT  LRU -> [1, 2, 3, 4, 5, 6] <- MRU Replaced:- [Hits:4 Misses:6]   <---- 命中 6
Access: 5  HIT  LRU -> [1, 2, 3, 4, 6, 5] <- MRU Replaced:- [Hits:5 Misses:6]   <---- 命中 5
Access: 6  HIT  LRU -> [1, 2, 3, 4, 5, 6] <- MRU Replaced:- [Hits:6 Misses:6]   <---- 命中 6

FINALSTATS hits 6   misses 6   hitrate 50.00                                    <---- 命中率 6/12 = 50.00%
```

### 3

生成一个随机的地址引用序列

```python
import random
random.choices(range(10), k=10)
# 2, 7, 2, 1, 3, 2, 4, 1, 8, 2
```

不同的策略在该序列上的表现
- 默认缓存大小为 3 页

#### OPT

```bash
./paging-policy.py -p OPT -a 2,7,2,1,3,2,4,1,8,2 -c

# 输出
ARG addresses 2,7,2,1,3,2,4,1,8,2
ARG addressfile 
ARG numaddrs 10
ARG policy OPT
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 2  MISS Left  ->          [2] <- Right Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 7  MISS Left  ->       [2, 7] <- Right Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 2  HIT  Left  ->       [2, 7] <- Right Replaced:- [Hits:1 Misses:2]     <---- 命中 2
Access: 1  MISS Left  ->    [2, 7, 1] <- Right Replaced:- [Hits:1 Misses:3]     <---- 填充缓存
Access: 3  MISS Left  ->    [2, 1, 3] <- Right Replaced:7 [Hits:1 Misses:4]     <---- 最优替换 7，替换为 3
Access: 2  HIT  Left  ->    [2, 1, 3] <- Right Replaced:- [Hits:2 Misses:4]     <---- 命中 2
Access: 4  MISS Left  ->    [2, 1, 4] <- Right Replaced:3 [Hits:2 Misses:5]     <---- 最优替换 3，替换为 4
Access: 1  HIT  Left  ->    [2, 1, 4] <- Right Replaced:- [Hits:3 Misses:5]     <---- 命中 1
Access: 8  MISS Left  ->    [2, 1, 8] <- Right Replaced:4 [Hits:3 Misses:6]     <---- 最优替换 4，替换为 8 【这里替换 1 也可以】
Access: 2  HIT  Left  ->    [2, 1, 8] <- Right Replaced:- [Hits:4 Misses:6]     <---- 命中 2

FINALSTATS hits 4   misses 6   hitrate 40.00                                    <---- 命中率 4/10 = 40.00%
```

#### UNOPT

```bash
./paging-policy.py -p UNOPT -a 2,7,2,1,3,2,4,1,8,2 -c

# 输出
ARG addresses 2,7,2,1,3,2,4,1,8,2
ARG addressfile 
ARG numaddrs 10
ARG policy UNOPT
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 2  MISS Left  ->          [2] <- Right Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 7  MISS Left  ->       [2, 7] <- Right Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 2  HIT  Left  ->       [2, 7] <- Right Replaced:- [Hits:1 Misses:2]     <---- 命中 2
Access: 1  MISS Left  ->    [2, 7, 1] <- Right Replaced:- [Hits:1 Misses:3]     <---- 填充缓存
Access: 3  MISS Left  ->    [7, 1, 3] <- Right Replaced:2 [Hits:1 Misses:4]     <---- 最差替换 2，替换为 3
Access: 2  MISS Left  ->    [7, 3, 2] <- Right Replaced:1 [Hits:1 Misses:5]     <---- 最差替换 1，替换为 2
Access: 4  MISS Left  ->    [7, 3, 4] <- Right Replaced:2 [Hits:1 Misses:6]     <---- 最差替换 2，替换为 4
Access: 1  MISS Left  ->    [3, 4, 1] <- Right Replaced:7 [Hits:1 Misses:7]     <---- 最差替换 7，替换为 1
Access: 8  MISS Left  ->    [4, 1, 8] <- Right Replaced:3 [Hits:1 Misses:8]     <---- 最差替换 3，替换为 8
Access: 2  MISS Left  ->    [1, 8, 2] <- Right Replaced:4 [Hits:1 Misses:9]     <---- 最差替换 4，替换为 2

FINALSTATS hits 1   misses 9   hitrate 10.00                                    <---- 命中率 1/10 = 10.00%
```

#### FIFO

```bash
./paging-policy.py -p FIFO -a 2,7,2,1,3,2,4,1,8,2 -c

# 输出
ARG addresses 2,7,2,1,3,2,4,1,8,2
ARG addressfile 
ARG numaddrs 10
ARG policy FIFO
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 2  MISS FirstIn ->          [2] <- Lastin  Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 7  MISS FirstIn ->       [2, 7] <- Lastin  Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 2  HIT  FirstIn ->       [2, 7] <- Lastin  Replaced:- [Hits:1 Misses:2]     <---- 命中 2
Access: 1  MISS FirstIn ->    [2, 7, 1] <- Lastin  Replaced:- [Hits:1 Misses:3]     <---- 填充缓存
Access: 3  MISS FirstIn ->    [7, 1, 3] <- Lastin  Replaced:2 [Hits:1 Misses:4]     <---- 2 替换为 3
Access: 2  MISS FirstIn ->    [1, 3, 2] <- Lastin  Replaced:7 [Hits:1 Misses:5]     <---- 7 替换为 2
Access: 4  MISS FirstIn ->    [3, 2, 4] <- Lastin  Replaced:1 [Hits:1 Misses:6]     <---- 1 替换为 4
Access: 1  MISS FirstIn ->    [2, 4, 1] <- Lastin  Replaced:3 [Hits:1 Misses:7]     <---- 3 替换为 1
Access: 8  MISS FirstIn ->    [4, 1, 8] <- Lastin  Replaced:2 [Hits:1 Misses:8]     <---- 2 替换为 8
Access: 2  MISS FirstIn ->    [1, 8, 2] <- Lastin  Replaced:4 [Hits:1 Misses:9]     <---- 4 替换为 2

FINALSTATS hits 1   misses 9   hitrate 10.00                                        <---- 命中率 1/10 = 10.00%
```

#### LRU

```bash
./paging-policy.py -p LRU -a 2,7,2,1,3,2,4,1,8,2 -c

# 输出
ARG addresses 2,7,2,1,3,2,4,1,8,2
ARG addressfile 
ARG numaddrs 10
ARG policy LRU
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 2  MISS LRU ->          [2] <- MRU Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 7  MISS LRU ->       [2, 7] <- MRU Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 2  HIT  LRU ->       [7, 2] <- MRU Replaced:- [Hits:1 Misses:2]     <---- 命中 2
Access: 1  MISS LRU ->    [7, 2, 1] <- MRU Replaced:- [Hits:1 Misses:3]     <---- 填充缓存
Access: 3  MISS LRU ->    [2, 1, 3] <- MRU Replaced:7 [Hits:1 Misses:4]     <---- 最近最少使用 7，替换为 3
Access: 2  HIT  LRU ->    [1, 3, 2] <- MRU Replaced:- [Hits:2 Misses:4]     <---- 命中 2
Access: 4  MISS LRU ->    [3, 2, 4] <- MRU Replaced:1 [Hits:2 Misses:5]     <---- 最近最少使用 1，替换为 4
Access: 1  MISS LRU ->    [2, 4, 1] <- MRU Replaced:3 [Hits:2 Misses:6]     <---- 最近最少使用 3，替换为 1
Access: 8  MISS LRU ->    [4, 1, 8] <- MRU Replaced:2 [Hits:2 Misses:7]     <---- 最近最少使用 2，替换为 8
Access: 2  MISS LRU ->    [1, 8, 2] <- MRU Replaced:4 [Hits:2 Misses:8]     <---- 最近最少使用 4，替换为 2

FINALSTATS hits 2   misses 8   hitrate 20.00                                <---- 命中率 2/10 = 20.00%
```

#### MRU

```bash
./paging-policy.py -p MRU -a 2,7,2,1,3,2,4,1,8,2 -c

# 输出
ARG addresses 2,7,2,1,3,2,4,1,8,2
ARG addressfile 
ARG numaddrs 10
ARG policy MRU
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 2  MISS LRU ->          [2] <- MRU Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 7  MISS LRU ->       [2, 7] <- MRU Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 2  HIT  LRU ->       [7, 2] <- MRU Replaced:- [Hits:1 Misses:2]     <---- 命中 2
Access: 1  MISS LRU ->    [7, 2, 1] <- MRU Replaced:- [Hits:1 Misses:3]     <---- 填充缓存
Access: 3  MISS LRU ->    [7, 2, 3] <- MRU Replaced:1 [Hits:1 Misses:4]     <---- 最近最多使用 1，替换为 3
Access: 2  HIT  LRU ->    [7, 3, 2] <- MRU Replaced:- [Hits:2 Misses:4]     <---- 命中 2
Access: 4  MISS LRU ->    [7, 3, 4] <- MRU Replaced:2 [Hits:2 Misses:5]     <---- 最近最多使用 2，替换为 4
Access: 1  MISS LRU ->    [7, 3, 1] <- MRU Replaced:4 [Hits:2 Misses:6]     <---- 最近最多使用 4，替换为 1
Access: 8  MISS LRU ->    [7, 3, 8] <- MRU Replaced:1 [Hits:2 Misses:7]     <---- 最近最多使用 1，替换为 8
Access: 2  MISS LRU ->    [7, 3, 2] <- MRU Replaced:8 [Hits:2 Misses:8]     <---- 最近最多使用 8，替换为 2

FINALSTATS hits 2   misses 8   hitrate 20.00                                <---- 命中率 2/10 = 20.00%
```

#### RAND

```bash
./paging-policy.py -p RAND -a 2,7,2,1,3,2,4,1,8,2 -c

# 输出
ARG addresses 2,7,2,1,3,2,4,1,8,2
ARG addressfile 
ARG numaddrs 10
ARG policy RAND
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 2  MISS Left  ->          [2] <- Right Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存
Access: 7  MISS Left  ->       [2, 7] <- Right Replaced:- [Hits:0 Misses:2]     <---- 填充缓存
Access: 2  HIT  Left  ->       [2, 7] <- Right Replaced:- [Hits:1 Misses:2]     <---- 命中 2
Access: 1  MISS Left  ->    [2, 7, 1] <- Right Replaced:- [Hits:1 Misses:3]     <---- 填充缓存
Access: 3  MISS Left  ->    [2, 7, 3] <- Right Replaced:1 [Hits:1 Misses:4]     <---- 随机替换 1，替换为 3
Access: 2  HIT  Left  ->    [2, 7, 3] <- Right Replaced:- [Hits:2 Misses:4]     <---- 命中 2
Access: 4  MISS Left  ->    [2, 7, 4] <- Right Replaced:3 [Hits:2 Misses:5]     <---- 随机替换 3，替换为 4
Access: 1  MISS Left  ->    [2, 4, 1] <- Right Replaced:7 [Hits:2 Misses:6]     <---- 随机替换 7，替换为 1
Access: 8  MISS Left  ->    [4, 1, 8] <- Right Replaced:2 [Hits:2 Misses:7]     <---- 随机替换 2，替换为 8
Access: 2  MISS Left  ->    [4, 8, 2] <- Right Replaced:1 [Hits:2 Misses:8]     <---- 随机替换 1，替换为 2

FINALSTATS hits 2   misses 8   hitrate 20.00                                    <---- 命中率 2/10 = 20.00%
```

#### CLOCK

默认 clockbit 为 2，即 0/1 两种状态。

```bash
./paging-policy.py -p CLOCK -a 2,7,2,1,3,2,4,1,8,2 -c

# 输出
ARG addresses 2,7,2,1,3,2,4,1,8,2
ARG addressfile 
ARG numaddrs 10
ARG policy CLOCK
ARG clockbits 2
ARG cachesize 3
ARG maxpage 10
ARG seed 0
ARG notrace False

Solving...

Access: 2  MISS Left  ->          [2] <- Right Replaced:- [Hits:0 Misses:1]     <---- 冷启动，填充缓存   【2】
Access: 7  MISS Left  ->       [2, 7] <- Right Replaced:- [Hits:0 Misses:2]     <---- 填充缓存          【7】
Access: 2  HIT  Left  ->       [2, 7] <- Right Replaced:- [Hits:1 Misses:2]     <---- 命中 2            【2】
Access: 1  MISS Left  ->    [2, 7, 1] <- Right Replaced:- [Hits:1 Misses:3]     <---- 填充缓存          【7】
Access: 3  MISS Left  ->    [2, 7, 3] <- Right Replaced:1 [Hits:1 Misses:4]     <---- 1 替换为 3        【1】
Access: 2  HIT  Left  ->    [2, 7, 3] <- Right Replaced:- [Hits:2 Misses:4]     <---- 命中 2            【2】
Access: 4  MISS Left  ->    [2, 3, 4] <- Right Replaced:7 [Hits:2 Misses:5]     <---- 7 替换为 4        【7】
Access: 1  MISS Left  ->    [2, 4, 1] <- Right Replaced:3 [Hits:2 Misses:6]     <---- 3 替换为 1        【3】
Access: 8  MISS Left  ->    [2, 1, 8] <- Right Replaced:4 [Hits:2 Misses:7]     <---- 4 替换为 8        【4】
Access: 2  HIT  Left  ->    [2, 1, 8] <- Right Replaced:- [Hits:3 Misses:7]     <---- 命中 2            【1】

FINALSTATS hits 3   misses 7   hitrate 30.00                                    <---- 命中率 3/10 = 30.00%
```