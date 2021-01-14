## 40 File System Implementation

模拟各种操作（创建目录/文件、删除目录/文件、硬链接），观察文件系统状态如何变化
- 文件系统从空状态开始，只有一个根目录
- 模拟各种操作，改变文件系统的磁盘状态

```python
# 随机种子，默认为 0
parser.add_option('-s', '--seed',        default=0,     help='the random seed',                      action='store', type='int', dest='seed')
# inode 数量，默认为 8
parser.add_option('-i', '--numInodes',   default=8,     help='number of inodes in file system',      action='store', type='int', dest='numInodes') 
# 数据块数量，默认为 8
parser.add_option('-d', '--numData',     default=8,     help='number of data blocks in file system', action='store', type='int', dest='numData') 
# 请求数量，默认为 10
parser.add_option('-n', '--numRequests', default=10,    help='number of requests to simulate',       action='store', type='int', dest='numRequests')
# 输出操作，默认输出状态
parser.add_option('-r', '--reverse',     default=False, help='instead of printing state, print ops', action='store_true',        dest='reverse')
# 打印最终的文件/目录集合
parser.add_option('-p', '--printFinal',  default=False, help='print the final set of files/dirs',    action='store_true',        dest='printFinal')
# 计算结果
parser.add_option('-c', '--compute',     default=False, help='compute answers for me',               action='store_true',        dest='solve')
```

通过打印四种不同数据结构的内容来显示文件系统的状态
- 索引节点（inode）位图：分配了哪些索引结点
- 索引节点：索引节点及其内容的表
  - 文件类型：`f` 表示常规文件，`d` 表示目录
  - 地址字段：-1 表示文件为空，没有数据
  - 引用计数：文件或目录
- 数据位图：分配了哪些数据块
- 数据：数据块的内容
  - 用户数据或目录数据
    - 名称
    - 索引节点

使用随机数种子模拟 6 个操作：

```bash
./vsfs.py -n 6 -s 16 -c

# 输出
ARG seed 16             <---- 随机数种子
ARG numInodes 8         <---- 索引节点数量
ARG numData 8           <---- 数据块数量
ARG numRequests 6       <---- 模拟请求数
ARG reverse False       <---- 输出操作
ARG printFinal False    <---- 打印最终文件/目录集合

Initial state   # 初始状态，根目录数据块地址为 0，引用为 2（指向根目录及自己）

inode bitmap  10000000
inodes       [d a:0 r:2][][][][][][][]
data bitmap   10000000
data         [(.,0) (..,0)][][][][][][][]

creat("/y");    # 创建文件 y（没有数据），因此数据块地址为 -1，引用计数为 1

inode bitmap  11000000
inodes       [d a:0 r:2][f a:-1 r:1][][][][][][]
data bitmap   10000000
data         [(.,0) (..,0) (y,1)][][][][][][][]

fd=open("/y", O_WRONLY|O_APPEND); write(fd, buf, BLOCKSIZE); close(fd); # 打开文件 y 并写入数据，数据块地址为 1

inode bitmap  11000000
inodes       [d a:0 r:2][f a:1 r:1][][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (y,1)][u][][][][][][]

link("/y", "/m");   # 硬链接文件 m 到文件 y，y 的引用计数加 1

inode bitmap  11000000
inodes       [d a:0 r:2][f a:1 r:2][][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (y,1) (m,1)][u][][][][][][]

unlink("/m");       # 取消硬链接，y 的引用计数减 1

inode bitmap  11000000
inodes       [d a:0 r:2][f a:1 r:1][][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (y,1)][u][][][][][][]

creat("/z");        # 创建文件 z（没有数据），数据块地址为 -1，引用计数为 1

inode bitmap  11100000
inodes       [d a:0 r:2][f a:1 r:1][f a:-1 r:1][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (y,1) (z,2)][u][][][][][][]

mkdir("/f");        # 创建目录 f，数据块地址为 2，引用计数为 2（指向根目录及自己）；根目录引用计数加 1

inode bitmap  11110000
inodes       [d a:0 r:3][f a:1 r:1][f a:-1 r:1][d a:2 r:2][][][][]
data bitmap   11100000
data         [(.,0) (..,0) (y,1) (z,2) (f,3)][u][(.,3) (..,0)][][][][][]
```

### 1/2

使用不同的随机种子模拟产生 6 个操作（`-n 6`）

#### `-s 17`

```bash
./vsfs.py -n 6 -s 17 -c

# 输出
...
Initial state

inode bitmap  10000000
inodes       [d a:0 r:2][][][][][][][]
data bitmap   10000000
data         [(.,0) (..,0)][][][][][][][]

mkdir("/u");    # 创建目录 u，数据块地址为 1，引用计数为 2（指向根目录及自己）；根目录引用计数加 1

inode bitmap  11000000
inodes       [d a:0 r:3][d a:1 r:2][][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (u,1)][(.,1) (..,0)][][][][][][]

creat("/a");    # 创建文件 a（没有数据），因此数据块地址为 -1，引用计数为 1

inode bitmap  11100000
inodes       [d a:0 r:3][d a:1 r:2][f a:-1 r:1][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (u,1) (a,2)][(.,1) (..,0)][][][][][][]

unlink("/a");   # 取消文件 a 的链接，即删除文件 a

inode bitmap  11000000
inodes       [d a:0 r:3][d a:1 r:2][][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (u,1)][(.,1) (..,0)][][][][][][]

mkdir("/z");    # 创建目录 z，数据块地址为 2，引用计数为 2（指向根目录及自己）；根目录引用计数加 1

inode bitmap  11100000
inodes       [d a:0 r:4][d a:1 r:2][d a:2 r:2][][][][][]
data bitmap   11100000
data         [(.,0) (..,0) (u,1) (z,2)][(.,1) (..,0)][(.,2) (..,0)][][][][][]

mkdir("/s");    # 创建目录 s，数据块地址为 3，引用计数为 2（指向根目录及自己）；根目录引用计数加 1

inode bitmap  11110000
inodes       [d a:0 r:5][d a:1 r:2][d a:2 r:2][d a:3 r:2][][][][]
data bitmap   11110000
data         [(.,0) (..,0) (u,1) (z,2) (s,3)][(.,1) (..,0)][(.,2) (..,0)][(.,3) (..,0)][][][][]

creat("/z/x");  # 在目录 z 下创建文件 x（没有数据），数据块地址为 -1，引用计数为 1

inode bitmap  11111000
inodes       [d a:0 r:5][d a:1 r:2][d a:2 r:2][d a:3 r:2][f a:-1 r:1][][][]
data bitmap   11110000
data         [(.,0) (..,0) (u,1) (z,2) (s,3)][(.,1) (..,0)][(.,2) (..,0) (x,4)][(.,3) (..,0)][][][][]
```

#### `-s 18`

```bash
./vsfs.py -n 6 -s 18 -c

# 输出
...
Initial state

inode bitmap  10000000
inodes       [d a:0 r:2][][][][][][][]
data bitmap   10000000
data         [(.,0) (..,0)][][][][][][][]

mkdir("/f");    # 创建目录 f，数据块地址为 1，引用计数为 2（指向根目录及自己）；根目录引用计数加 1

inode bitmap  11000000
inodes       [d a:0 r:3][d a:1 r:2][][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (f,1)][(.,1) (..,0)][][][][][][]

creat("/s");    # 创建文件 s（没有数据），因此数据块地址为 -1，引用计数为 1

inode bitmap  11100000
inodes       [d a:0 r:3][d a:1 r:2][f a:-1 r:1][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (f,1) (s,2)][(.,1) (..,0)][][][][][][]

mkdir("/h");    # 创建目录 h，数据块地址为 2，引用计数为 2（指向根目录及自己）；根目录引用计数加 1

inode bitmap  11110000
inodes       [d a:0 r:4][d a:1 r:2][f a:-1 r:1][d a:2 r:2][][][][]
data bitmap   11100000
data         [(.,0) (..,0) (f,1) (s,2) (h,3)][(.,1) (..,0)][(.,3) (..,0)][][][][][]

fd=open("/s", O_WRONLY|O_APPEND); write(fd, buf, BLOCKSIZE); close(fd); # 打开文件 s 并写入数据，数据块地址为 3

inode bitmap  11110000
inodes       [d a:0 r:4][d a:1 r:2][f a:3 r:1][d a:2 r:2][][][][]
data bitmap   11110000
data         [(.,0) (..,0) (f,1) (s,2) (h,3)][(.,1) (..,0)][(.,3) (..,0)][f][][][][]

creat("/f/o");  # 在目录 f 下创建文件 o（没有数据），数据块地址为 -1，引用计数为 1

inode bitmap  11111000
inodes       [d a:0 r:4][d a:1 r:2][f a:3 r:1][d a:2 r:2][f a:-1 r:1][][][]
data bitmap   11110000
data         [(.,0) (..,0) (f,1) (s,2) (h,3)][(.,1) (..,0) (o,4)][(.,3) (..,0)][f][][][][]

creat("/c");    # 创建文件 c（没有数据），数据块地址为 -1，引用计数为 1

inode bitmap  11111100
inodes       [d a:0 r:4][d a:1 r:2][f a:3 r:1][d a:2 r:2][f a:-1 r:1][f a:-1 r:1][][]
data bitmap   11110000
data         [(.,0) (..,0) (f,1) (s,2) (h,3) (c,5)][(.,1) (..,0) (o,4)][(.,3) (..,0)][f][][][][]
```

#### `-s 19`

```bash
./vsfs.py -n 6 -s 19 -c

# 输出
...
Initial state

inode bitmap  10000000
inodes       [d a:0 r:2][][][][][][][]
data bitmap   10000000
data         [(.,0) (..,0)][][][][][][][]

creat("/k");    # 创建文件 k（没有数据），数据块地址为 -1，引用计数为 1

inode bitmap  11000000
inodes       [d a:0 r:2][f a:-1 r:1][][][][][][]
data bitmap   10000000
data         [(.,0) (..,0) (k,1)][][][][][][][]

creat("/g");    # 创建文件 g（没有数据），数据块地址为 -1，引用计数为 1

inode bitmap  11100000
inodes       [d a:0 r:2][f a:-1 r:1][f a:-1 r:1][][][][][]
data bitmap   10000000
data         [(.,0) (..,0) (k,1) (g,2)][][][][][][][]

fd=open("/k", O_WRONLY|O_APPEND); write(fd, buf, BLOCKSIZE); close(fd); # 打开文件 k 并写入数据，数据块地址为 1

inode bitmap  11100000
inodes       [d a:0 r:2][f a:1 r:1][f a:-1 r:1][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (k,1) (g,2)][g][][][][][][]

link("/k", "/b");   # 硬链接文件 k 到文件 b，k 的引用计数加 1

inode bitmap  11100000
inodes       [d a:0 r:2][f a:1 r:2][f a:-1 r:1][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (k,1) (g,2) (b,1)][g][][][][][][]

link("/b", "/t");   # 硬链接文件 b 到文件 t，k 的引用计数加 1

inode bitmap  11100000
inodes       [d a:0 r:2][f a:1 r:3][f a:-1 r:1][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (k,1) (g,2) (b,1) (t,1)][g][][][][][][]

unlink("/k");       # 取消文件 k 的链接，即删除文件 k，此时仍然有 2 个引用

inode bitmap  11100000
inodes       [d a:0 r:2][f a:1 r:2][f a:-1 r:1][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (g,2) (b,1) (t,1)][g][][][][][][]
```

#### `-s 20`

```bash
./vsfs.py -n 6 -s 20 -c

# 输出
...
Initial state

inode bitmap  10000000
inodes       [d a:0 r:2][][][][][][][]
data bitmap   10000000
data         [(.,0) (..,0)][][][][][][][]

creat("/x");    # 创建文件 x（没有数据），因此数据块地址为 -1，引用计数为 1

inode bitmap  11000000
inodes       [d a:0 r:2][f a:-1 r:1][][][][][][]
data bitmap   10000000
data         [(.,0) (..,0) (x,1)][][][][][][][]

fd=open("/x", O_WRONLY|O_APPEND); write(fd, buf, BLOCKSIZE); close(fd); # 打开文件 x 并写入数据，数据块地址为 1

inode bitmap  11000000
inodes       [d a:0 r:2][f a:1 r:1][][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (x,1)][x][][][][][][]

creat("/k");    # 创建文件 k（没有数据），因此数据块地址为 -1，引用计数为 1

inode bitmap  11100000
inodes       [d a:0 r:2][f a:1 r:1][f a:-1 r:1][][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (x,1) (k,2)][x][][][][][][]

creat("/y");    # 创建文件 y（没有数据），因此数据块地址为 -1，引用计数为 1

inode bitmap  11110000
inodes       [d a:0 r:2][f a:1 r:1][f a:-1 r:1][f a:-1 r:1][][][][]
data bitmap   11000000
data         [(.,0) (..,0) (x,1) (k,2) (y,3)][x][][][][][][]

unlink("/x");   # 取消文件 x 的链接，即删除文件 x

inode bitmap  10110000
inodes       [d a:0 r:2][][f a:-1 r:1][f a:-1 r:1][][][][]
data bitmap   10000000
data         [(.,0) (..,0) (k,2) (y,3)][][][][][][][]

unlink("/y");   # 取消文件 y 的链接，即删除文件 y

inode bitmap  10100000
inodes       [d a:0 r:2][][f a:-1 r:1][][][][][]
data bitmap   10000000
data         [(.,0) (..,0) (k,2)][][][][][][][]
```

### 3

减少文件系统中的数据块数量（`-d 2`），并模拟 100 个请求（`-n 100`）
- 创建目录失败
- 写入数据失败
- 创建目录后，没有空闲数据块，因此报错
- 文件系统只能包含一系列空文件（不超过索引节点数量）

1. 默认随机数种子（`-s 0`）

```bash
./vsfs.py -d 2 -n 100 -s 0 -c

# 输出
...
Initial state

inode bitmap  10000000
inodes       [d a:0 r:2][][][][][][][]
data bitmap   10
data         [(.,0) (..,0)][]

mkdir("/g");    # 创建目录失败
File system out of data blocks; rerun with more via command-line flag?
```

2. 随机数种子为 3 时（`-s 3`）

```bash
./vsfs.py -d 2 -n 100 -s 3 -c

# 输出
Initial state

inode bitmap  10000000
inodes       [d a:0 r:2][][][][][][][]
data bitmap   10
data         [(.,0) (..,0)][]

creat("/z");    # 创建文件 z（没有数据），因此数据块地址为 -1，引用计数为 1

inode bitmap  11000000
inodes       [d a:0 r:2][f a:-1 r:1][][][][][][]
data bitmap   10
data         [(.,0) (..,0) (z,1)][]

unlink("/z");   # 取消文件 z 的链接，即删除文件 a

inode bitmap  10000000
inodes       [d a:0 r:2][][][][][][][]
data bitmap   10
data         [(.,0) (..,0)][]

creat("/s");    # 创建文件 s（没有数据），因此数据块地址为 -1，引用计数为 1

inode bitmap  11000000
inodes       [d a:0 r:2][f a:-1 r:1][][][][][][]
data bitmap   10
data         [(.,0) (..,0) (s,1)][]

fd=open("/s", O_WRONLY|O_APPEND); write(fd, buf, BLOCKSIZE); close(fd);     # 打开文件 s，写入数据失败
File system out of data blocks; rerun with more via command-line flag?
```

### 4

减少文件系统中的索引节点数量（`-i 2`），并模拟 100 个请求（`-n 100`）
- 创建目录失败
- 创建文件失败
- 执行创建操作后，没有空闲的索引节点，因此报错
- 文件系统无法创建目录或文件

1. 默认随机数种子（`-s 0`）

```bash
./vsfs.py -i 2 -n 100 -s 0 -c

# 输出
...
Initial state

inode bitmap  10
inodes       [d a:0 r:2][]
data bitmap   10000000
data         [(.,0) (..,0)][][][][][][][]

mkdir("/g");    # 创建目录失败
File system out of inodes; rerun with more via command-line flag?
```

2. 随机数种子为 3 时（`-s 3`）

```bash

# 输出
...
Initial state

inode bitmap  10
inodes       [d a:0 r:2][]
data bitmap   10000000
data         [(.,0) (..,0)][][][][][][][]

creat("/z");    # 创建文件失败
File system out of inodes; rerun with more via command-line flag?
```