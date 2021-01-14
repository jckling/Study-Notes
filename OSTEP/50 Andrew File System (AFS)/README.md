## 50 Andrew File System (AFS)

模拟 Andrew 文件系统（Andrew File System, AFS）
- 缓存一致性：服务器使用回调（callback）通知客户端更新缓存
- 操作：读/写，各包含三条指令

```python
# 随机种子，默认为 0
parser.add_option('-s', '--seed',      default=0,      help='the random seed',           action='store', type='int', dest='seed')
# 客户端数量，默认为 2
parser.add_option('-C', '--clients',   default=2,      help='number of clients',         action='store', type='int', dest='numclients')
# 每个客户端执行的操作数量，默认为 2
parser.add_option('-n', '--numsteps',  default=2,      help='ops each client will do',   action='store', type='int', dest='numsteps')
# 服务器的文件数量，默认为 1
parser.add_option('-f', '--numfiles',  default=1,      help='number of files in server', action='store', type='int', dest='numfiles')
# 读写比例，默认 1:1
parser.add_option('-r', '--readratio', default=0.5,    help='ratio of reads/writes',     action='store', type='float', dest='readratio')
# 指定客户端操作序列
parser.add_option('-A', '--actions',   default='',     help='client actions exactly specified, e.g., oa1:r1:c1,oa1:w1:c1 specifies two clients; each opens the file a, client 0 reads it whereas client 1 writes it, and then each closes it', action='store', type='string', dest='actions')
# 指定调度顺序，默认随机
parser.add_option('-S', '--schedule',  default='',     help='exact schedule to run; 01 alternates round robin between clients 0 and 1. Left unspecified leads to random scheduling', action='store', type='string', dest='schedule')
# 打印额外状态
parser.add_option('-p', '--printstats', default=False, help='print extra stats',      action='store_true', dest='printstats')
# 计算结果
parser.add_option('-c', '--compute',    default=False, help='compute answers for me', action='store_true', dest='solve')
# 信息级别
parser.add_option('-d', '--detail',     default=0,     help='detail level when giving answers (1:server actions,2:invalidations,4:client cache,8:extra labels); OR together for multiple', action='store', type='int', dest='detail')
```

### 1

两个客户端（`-C 2`），各执行一个操作（`-n 1`），使用随机种子 12 （`-s 12`）
- Server 初始包含文件 a，且内容为 0
- 客户端 c0 打开、写、关闭文件 a，内容修改为 1
- 客户端 c1 打开、读、关闭文件 a，内容为 1

```bash
./afs.py -C 2 -n 1 -s 12 -p -c

# 输出
ARG seed 12         <--- 随机种子
ARG numclients 2    <--- 客户端数量
ARG numsteps 1      <--- 操作数量
ARG numfiles 1      <--- 文件数量
ARG readratio 0.5   <--- 读写比例
ARG actions         <--- 操作序列
ARG schedule        <--- 调度
ARG detail 0        <--- 信息级别

[(1, 'a', 0), (3, 0), (4, 0)]
[(1, 'a', 0), (2, 0), (4, 0)]
      Server                         c0                          c1               
file:a contains:0
                            open:a [fd:0]
                            write:0 0 -> 1
                            close:0
                                                        open:a [fd:0]
                                                        read:0 -> 1
                                                        close:0
file:a contains:1
Server   -- Gets:2 Puts:1
c0       -- Reads:0 Writes:1
   Cache -- Hits:0 Misses:1 Invalidates:0
c1       -- Reads:1 Writes:0
   Cache -- Hits:0 Misses:1 Invalidates:0
```

### 2

和 1 相同，但是指定客户端操作的调度顺序（`-S 111000`）
- 先执行客户端 c1 的 3 条指令，然后执行客户端 c0 的 3 条指令，后续指令如此循环
- 客户端 c1 打开、读、关闭文件
- 客户端 c0 打开、写、关闭文件
  - 客户端 c1 的缓存失效，更新

缓存信息
- v (valid), d (dirty), and r (reference count)

```bash
./afs.py -C 2 -n 1 -s 12 -S 111000 -p -c

# 输出
...
[(1, 'a', 0), (3, 0), (4, 0)]
[(1, 'a', 0), (2, 0), (4, 0)]
      Server                         c0                          c1               
file:a contains:0
                                                        open:a [fd:0]
                                                        read:0 -> 0
                                                        close:0
                            open:a [fd:0]
                            write:0 0 -> 1
                            close:0
                                                        invalidate file:a cache: {'a': {'data': 0, 'dirty': False, 'refcnt': 0, 'valid': True}}
file:a contains:1
Server   -- Gets:2 Puts:1
c0       -- Reads:0 Writes:1
   Cache -- Hits:0 Misses:1 Invalidates:0
c1       -- Reads:1 Writes:0
   Cache -- Hits:0 Misses:1 Invalidates:1
```

### 3

两个客户端（`-C 2`），指定操作序列（`-A`）和调度顺序（`-S`），并显示额外的信息（`-d 7`）
- 客户端 c0 打开文件
- 客户端 c1 写文件
- 客户端 c0 读文件
  - 客户端 c0 的缓存失效，更新
- 客户端 c0 关闭文件

```bash
./afs.py -C 2 -A oa1:r1:c1,oa1:w1:c1 -S 011100 -p -c -d 7

# 输出
...
[(1, 'a', 1), (2, 1), (4, 1)]
[(1, 'a', 1), (3, 1), (4, 1)]
      Server                         c0                          c1               
file:a contains:0
                            open:a [fd:1]
getfile:a c:c0 [0]
                            [a: 0 (v=1,d=0,r=1)]

                                                        open:a [fd:1]
getfile:a c:c1 [0]
                                                        [a: 0 (v=1,d=0,r=1)]

                                                        write:1 0 -> 1
                                                        [a: 1 (v=1,d=1,r=1)]

                                                        close:1
putfile:a c:c1 [1]
callback: c:c0 file:a
                            invalidate file:a cache: {'a': {'data': 0, 'dirty': False, 'refcnt': 1, 'valid': True}}
                            invalidate a
                            [a: 0 (v=0,d=0,r=1)]
                                                        [a: 1 (v=1,d=0,r=0)]

                            read:1 -> 0
                            [a: 0 (v=0,d=0,r=1)]

                            close:1

file:a contains:1
Server   -- Gets:2 Puts:1
c0       -- Reads:1 Writes:0
   Cache -- Hits:0 Misses:1 Invalidates:1
c1       -- Reads:0 Writes:1
   Cache -- Hits:0 Misses:1 Invalidates:0
```

### 4

两个客户端（`-C 2`），指定操作序列（`-A`）
- 客户端 c1 打开、读文件
- 客户端 c0 打开、写文件
- 客户端 c1 关闭文件
- 客户端 c0 关闭文件
  - 客户端 c1 的缓存失效，并进行更新

```bash
./afs.py -C 2 -A oa1:w1:c1,oa1:r1:c1 -p -c

# 输出
...
[(1, 'a', 1), (3, 1), (4, 1)]
[(1, 'a', 1), (2, 1), (4, 1)]
      Server                         c0                          c1               
file:a contains:0
                                                        open:a [fd:1]
                                                        read:1 -> 0
                            open:a [fd:1]
                            write:1 0 -> 1
                                                        close:1
                            close:1
                                                        invalidate file:a cache: {'a': {'data': 0, 'dirty': False, 'refcnt': 0, 'valid': True}}
file:a contains:1
Server   -- Gets:2 Puts:1
c0       -- Reads:0 Writes:1
   Cache -- Hits:0 Misses:1 Invalidates:0
c1       -- Reads:1 Writes:0
   Cache -- Hits:0 Misses:1 Invalidates:1
```

### 5

和 4 相同，但使用不同的调度顺序（`-S`），下列调度顺序客户端 c1 都读到 0（旧值）

1. `-S 01` **c1 读到 0**

客户端 c0 和 c1 交替执行 1 条指令
- c0 打开文件
- c1 打开文件
- c0 写文件
- c1 读文件
- c0 关闭文件
  - c1 缓存失效，更新
- c1 关闭文件

```bash
./afs.py -C 2 -A oa1:w1:c1,oa1:r1:c1 -S 01 -p -c

# 输出
...
[(1, 'a', 1), (3, 1), (4, 1)]
[(1, 'a', 1), (2, 1), (4, 1)]
      Server                         c0                          c1               
file:a contains:0
                            open:a [fd:1]
                                                        open:a [fd:1]
                            write:1 0 -> 1
                                                        read:1 -> 0
                            close:1
                                                        invalidate file:a cache: {'a': {'data': 0, 'dirty': False, 'refcnt': 1, 'valid': True}}
                                                        close:1
file:a contains:1
Server   -- Gets:2 Puts:1
c0       -- Reads:0 Writes:1
   Cache -- Hits:0 Misses:1 Invalidates:0
c1       -- Reads:1 Writes:0
   Cache -- Hits:0 Misses:1 Invalidates:1
```

2. `-S 100011` **c1 读到 0**

客户端 c1 先执行 1 条指令，然后客户端 c0 执行 3 条指令，最后客户端 c1 执行 2 条指令，如此循环
- c1 打开文件
- c0 打开、写、关闭文件
  - c1 缓存失效，更新
- c1 读、关闭文件

```bash
./afs.py -C 2 -A oa1:w1:c1,oa1:r1:c1 -S 100011 -p -c

# 输出
...
[(1, 'a', 1), (3, 1), (4, 1)]
[(1, 'a', 1), (2, 1), (4, 1)]
      Server                         c0                          c1               
file:a contains:0
                                                        open:a [fd:1]
                            open:a [fd:1]
                            write:1 0 -> 1
                            close:1
                                                        invalidate file:a cache: {'a': {'data': 0, 'dirty': False, 'refcnt': 1, 'valid': True}}
                                                        read:1 -> 0
                                                        close:1
file:a contains:1
Server   -- Gets:2 Puts:1
c0       -- Reads:0 Writes:1
   Cache -- Hits:0 Misses:1 Invalidates:0
c1       -- Reads:1 Writes:0
   Cache -- Hits:0 Misses:1 Invalidates:1
```

3. `-S 011100` **c1 读到 0**

客户端 c0 先执行 1 条指令，然后客户端 c1 执行 3 条指令，最后客户端 c0 执行 2 条指令，如此循环
- c0 打开文件
- c1 打开、读、关闭文件
- c0 写、关闭文件
  - c1 缓存失效，更新

```bash
./afs.py -C 2 -A oa1:w1:c1,oa1:r1:c1 -S 011100 -p -c

# 输出
...
[(1, 'a', 1), (3, 1), (4, 1)]
[(1, 'a', 1), (2, 1), (4, 1)]
      Server                         c0                          c1               
file:a contains:0
                            open:a [fd:1]
                                                        open:a [fd:1]
                                                        read:1 -> 0
                                                        close:1
                            write:1 0 -> 1
                            close:1
                                                        invalidate file:a cache: {'a': {'data': 0, 'dirty': False, 'refcnt': 0, 'valid': True}}
file:a contains:1
Server   -- Gets:2 Puts:1
c0       -- Reads:0 Writes:1
   Cache -- Hits:0 Misses:1 Invalidates:0
c1       -- Reads:1 Writes:0
   Cache -- Hits:0 Misses:1 Invalidates:1
```

### 6

客户端 c0 和 c1 都对文件进行写入，使用不同的调度顺序（`-S`），显然可能发生更新丢失。
- 不同机器上的进程同时修改文件，最后写入者胜出（last writer win）

1. `-S 011100`

客户端 c0 先执行 1 条指令，然后客户端 c1 执行 3 条指令，最后客户端 c0 执行 2 条指令，如此循环
- c0 打开文件
- c1 打开、写、关闭文件：**a: 0 -> 1**
  - c0 缓存失效，更新
- c0 写、关闭文件：**a: 0 -> 2**
  - c1 缓存失效，更新

```bash
./afs.py -C 2 -A oa1:w1:c1,oa1:w1:c1 -S 011100 -p -c

# 输出
...
[(1, 'a', 1), (3, 1), (4, 1)]
[(1, 'a', 1), (3, 1), (4, 1)]
      Server                         c0                          c1               
file:a contains:0
                            open:a [fd:1]
                                                        open:a [fd:1]
                                                        write:1 0 -> 1
                                                        close:1
                            invalidate file:a cache: {'a': {'data': 0, 'dirty': False, 'refcnt': 1, 'valid': True}}
                            write:1 0 -> 2
                            close:1
                                                        invalidate file:a cache: {'a': {'data': 1, 'dirty': False, 'refcnt': 0, 'valid': True}}
file:a contains:2
Server   -- Gets:2 Puts:2
c0       -- Reads:0 Writes:1
   Cache -- Hits:0 Misses:1 Invalidates:1
c1       -- Reads:0 Writes:1
   Cache -- Hits:0 Misses:1 Invalidates:1
```

2. `-S 010011`

客户端 c0 先执行 1 条指令，然后客户端 c1 执行 1 条指令，接着客户端 c0 执行 2 条指令，最后客户端 c1 执行 2 条指令，如此循环
- c0 打开文件
- c1 打开文件
- c0 写、关闭文件：**a: 0 -> 1**
  - c1 缓存失效，更新
- c1 写、关闭文件：**a: 0 -> 2**
  - c0 缓存失效，更新

```bash
./afs.py -C 2 -A oa1:w1:c1,oa1:w1:c1 -S 010011 -p -c

# 输出
...
[(1, 'a', 1), (3, 1), (4, 1)]
[(1, 'a', 1), (3, 1), (4, 1)]
      Server                         c0                          c1               
file:a contains:0
                            open:a [fd:1]
                                                        open:a [fd:1]
                            write:1 0 -> 1
                            close:1
                                                        invalidate file:a cache: {'a': {'data': 0, 'dirty': False, 'refcnt': 1, 'valid': True}}
                                                        write:1 0 -> 2
                                                        close:1
                            invalidate file:a cache: {'a': {'data': 1, 'dirty': False, 'refcnt': 0, 'valid': True}}
file:a contains:2
Server   -- Gets:2 Puts:2
c0       -- Reads:0 Writes:1
   Cache -- Hits:0 Misses:1 Invalidates:1
c1       -- Reads:0 Writes:1
   Cache -- Hits:0 Misses:1 Invalidates:1
```