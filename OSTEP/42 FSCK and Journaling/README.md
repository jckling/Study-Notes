## 42 FSCK and Journaling

[fsck](https://linux.die.net/man/8/fsck) 工具用于检查和修复 Linux 文件系统。[fsck.py](file-journaling/fsck.py) 首先在磁盘上生成文件系统（VSFS），然后通过随机模拟操作，更改文件系统的磁盘状态。

```python
# 生成文件系统的随机种子
parser.add_option('-s', '--seed',        default=0,     help='first random seed (for a filesystem)', action='store', type='int', dest='seed')
# 损坏文件的随机种子
parser.add_option('-S', '--seedCorrupt', default=0,     help='second random seed (for corruptions)', action='store', type='int', dest='seedCorrupt')
# 索引节点数量
parser.add_option('-i', '--numInodes',   default=16,    help='number of inodes in file system',      action='store', type='int', dest='numInodes')
# 文件块数量
parser.add_option('-d', '--numData',     default=16,    help='number of data blocks in file system', action='store', type='int', dest='numData')
# 模拟请求的数量
parser.add_option('-n', '--numRequests', default=15,    help='number of requests to simulate',       action='store', type='int', dest='numRequests')
# 打印最终的文件/目录集合
parser.add_option('-p', '--printFinal',  default=False, help='print the final set of files/dirs',    action='store_true',        dest='printFinal')
# 损坏具体的文件
parser.add_option('-w', '--whichCorrupt',default=-1,    help='do a specific corruption',             action='store', type='int', dest='whichCorrupt')
# 计算结果
parser.add_option('-c', '--compute',     default=False, help='compute answers for me',               action='store_true',        dest='solve')
# 避免崩溃
parser.add_option('-D', '--dontCorrupt', default=False,  help='actually corrupt file system',        action='store_true',        dest='dontCorrupt')
```

崩溃场景

- 只有一次写入成功
	1. 只将数据块写入磁盘
	2. 只有更新的 inode 写入了磁盘
	3. 只有更新的位图写入了磁盘

- 两次写入成功，最后一次失败
	1. inode 和位图写入了磁盘，但没有写入数据
	2. inode 和数据写入了磁盘，但没有写入位图
    3. 位图和数据写入了磁盘，但没有写入 inode

### 1

在不损坏文件的情况下，使用不同的随机种子生成文件系统
- 没有文件损坏，因此就不使用 `-c` 打印文件系统状态

文件系统检查
- 检查位图：索引节点位图↔索引节点，数据位图↔数据块
- 检查索引节点和数据块对应关系：索引节点的 `a` 指向数据块，数据块中的数字指向索引节点
- 检查索引节点的引用计数

1. 默认 `-s 0`

- 文件 `m` 和 `z` 是硬链接，共同使用索引节点，因此引用计数为 2
- 在目录 `/g` 下创建文件 `s` ，引用计数为 1 

```bash
./fsck.py -D -p

# 输出
...
Final state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

...
Summary of files, directories::
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```

2. `-s 1`

```bash
./fsck.py -s 1 -D -p

# 输出
...
Final state of file system:

inode bitmap 1000100110010001
inodes       [d a:0 r:4] [] [] [] [f a:-1 r:1] [] [] [d a:10 r:2] [d a:15 r:2] [] [] [f a:-1 r:3] [] [] [] [f a:-1 r:1] 
data bitmap  1000000000100001
data         [(.,0) (..,0) (m,7) (a,8) (g,11)] [] [] [] [] [] [] [] [] [] [(.,7) (..,0) (m,15) (e,11)] [] [] [] [] [(.,8) (..,0) (r,4) (w,11)] 

...
Summary of files, directories::
  Files:       ['/a/r', '/a/w', '/g', '/m/m', '/m/e']
  Directories: ['/', '/m', '/a']
```

3. `-s 2`

```bash
./fsck.py -s 2 -D -p

# 输出
...
Final state of file system:

inode bitmap 1000000100110101
inodes       [d a:0 r:3] [] [] [] [] [] [] [d a:4 r:3] [] [] [f a:-1 r:1] [f a:-1 r:2] [] [d a:11 r:3] [] [d a:15 r:2] 
data bitmap  1000100000010001
data         [(.,0) (..,0) (c,13)] [] [] [] [(.,7) (..,13) (u,15) (q,11)] [] [] [] [] [] [] [(.,13) (..,0) (o,7)] [] [] [] [(.,15) (..,7) (q,11) (e,10)] 

...
Summary of files, directories::
  Files:       ['/c/o/q', '/c/o/u/q', '/c/o/u/e']
  Directories: ['/', '/c', '/c/o', '/c/o/u']
```

4. `-s 3`

```bash
./fsck.py -s 3 -D -p

# 输出
...
Final state of file system:

inode bitmap 1011000000000001
inodes       [d a:0 r:3] [] [d a:13 r:3] [d a:9 r:2] [] [] [] [] [] [] [] [] [] [] [] [f a:15 r:2] 
data bitmap  1000000001000101
data         [(.,0) (..,0) (f,15) (x,15) (r,2)] [] [] [] [] [] [] [] [] [(.,3) (..,2)] [] [] [] [(.,2) (..,0) (s,3)] [] [w] 

...
Summary of files, directories::
  Files:       ['/f', '/x']
  Directories: ['/', '/r', '/r/s']
```

### 2

先看 `Final state`，即模拟执行操作后的文件系统状态； `Initial state` 表示初始未损坏的文件系统状态。

使用默认参数运行，`[f a:15 r:1]` ，索引节点和数据块可以一一对应，索引节点位图有 4 个被使用，但实际上分配了 5 个索引节点，因此这里存在文件损坏
- `-S 1`：损坏文件的随机种子
- `-p`：打印文件系统状态
- `-c`：计算结果

```bash
./fsck.py -S 1 -p -c

# 输出
ARG seed 0              <--- 随机种子，生成文件系统
ARG seedCorrupt 1       <--- 随机种子，损坏文件
ARG numInodes 16        <--- 索引节点数量
ARG numData 16          <--- 文件块数量
ARG numRequests 15      <--- 模拟请求数量
ARG printFinal True     <--- 打印最终结果
ARG whichCorrupt -1     <--- 损坏具体的哪个文件
ARG dontCorrupt False   <--- 不要损坏文件

Initial state of file system:

inode bitmap 1000100010000101   <--- 索引节点位图
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000   <--- 数据块位图
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

CORRUPTION::INODE BITMAP corrupt bit 13

Final state of file system:

inode bitmap 1000100010000001
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 


Summary of files, directories::     <--- 文件、目录
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```

### 3

使用不同的随机种子重复实验 2 。

1. `-S 3`

- 检查位图
- 检查索引节点和数据块对应关系
- 检查索引节点的引用计数
  - 索引节点 15 （文件 `/g/s`）的引用计数多 1

```bash
./fsck.py -S 3 -p -c

# 输出
...
Initial state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

CORRUPTION::INODE 15 refcnt increased

Final state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:2] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 


Summary of files, directories::
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```

2. `-S 19`

- 检查位图
- 检查索引节点和数据块对应关系
- 检查索引节点的引用计数
  - 索引节点 8 （目录 `/g`）的引用计数少 1

```bash
./fsck.py -S 19 -p -c

# 输出
...
Initial state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

CORRUPTION::INODE 8 refcnt decreased

Final state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:1] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 


Summary of files, directories::
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```

### 4

使用不同的随机种子重复实验 2 。

1. `-S 5`

- 检查位图
- 检查索引节点和数据块对应关系
  - 目录 `/g` 下对应的是文件 `s` ，结果指向的文件名变成了 `y`
- 检查索引节点的引用计数

```bash
./fsck.py -S 5 -p -c

# 输出
...
Initial state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

CORRUPTION::INODE 8 with directory [('.', 8), ('..', 0), ('s', 15)]:
  entry ('s', 15) altered to refer to different name (y)

Final state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (y,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 


Summary of files, directories::
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```

2. `-S 38`

- 检查位图
- 检查索引节点和数据块对应关系
  - 目录 `/w` 指向父目录的数据块信息被修改为指向目录 `b` ，但并不存在
- 检查索引节点的引用计数

```bash
./fsck.py -S 38 -p -c

# 输出
...
Initial state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

CORRUPTION::INODE 4 with directory [('.', 4), ('..', 0)]:
  entry ('..', 0) altered to refer to different name (b)

Final state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (b,0)] [] [] [] 


Summary of files, directories::
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```

### 5

使用不同的随机种子重复实验 2 。

1. `-S 6`

- 检查位图
  - 索引节点 12 被分配，但没有更新位图
- 检查索引节点和数据块对应关系
- 检查索引节点的引用计数

```bash
./fsck.py -S 6 -p -c

# 输出
...
Initial state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

CORRUPTION::INODE 12 orphan

Final state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [d a:-1 r:1] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 


Summary of files, directories::
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```

2. `-S 13`

- 检查位图
  - 索引节点 10 被分配，但没有更新位图
- 检查索引节点和数据块对应关系
- 检查索引节点的引用计数

```bash
./fsck.py -S 13 -p -c

# 输出
...
Initial state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

CORRUPTION::INODE 10 orphan

Final state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [f a:-1 r:1] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 


Summary of files, directories::
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```

### 6

使用不同的随机种子重复实验 2 。

- 检查位图
- 检查索引节点和数据块对应关系
  - 索引节点 13 指向目录，然而实际上是文件
  - 目录不会没有数据块地址
- 检查索引节点的引用计数

```bash
./fsck.py -S 9 -p -c

# 输出
...
Initial state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

CORRUPTION::INODE 13 was type file, now dir

Final state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [d a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 


Summary of files, directories::
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```

### 7

使用不同的随机种子重复实验 2 。

- 检查位图
- 检查索引节点和数据块对应关系
  - 索引节点 0 对应的数据块包含目录、文件，因此不可能是文件
  - 索引节点 0 的类型是文件，而实际上应该是目录
- 检查索引节点的引用计数

```bash
./fsck.py -S 15 -p -c

# 输出
...
Initial state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

CORRUPTION::INODE 0 was type file, now dir

Final state of file system:

inode bitmap 1000100010000101
inodes       [f a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 


Summary of files, directories::
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```

### 8

使用不同的随机种子重复实验 2 。

- 检查位图
- 检查索引节点和数据块对应关系
  - 目录 `/w` 的指向父目录（索引节点 3），然而该索引节点并没有被分配
- 检查索引节点的引用计数

```bash
./fsck.py -S 10 -p -c

# 输出
...
Initial state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

CORRUPTION::INODE 4 with directory [('.', 4), ('..', 0)]:
  entry ('..', 0) altered to refer to unallocated inode (3)

Final state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,3)] [] [] [] 


Summary of files, directories::
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```

### 9

使用不同的随机种子重复实验 2 。

1. `-S 16`

- 检查位图
- 检查索引节点和数据块对应关系
  - 索引节点指向数据块 7 ，然而实际并没有数据
- 检查索引节点的引用计数

```bash
./fsck.py -S 16 -p -c

# 输出
...
Initial state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

CORRUPTION::INODE 13 points to dead block 7

Final state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:7 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 


Summary of files, directories::
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```

2. `-S 20`

- 检查位图
- 检查索引节点和数据块对应关系
  - 索引节点 8 指向数据块 11 ，然而实际并没有数据
- 检查索引节点的引用计数

```bash
./fsck.py -S 20 -p -c

# 输出
...
Initial state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:6 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 

CORRUPTION::INODE 8 points to dead block 11

Final state of file system:

inode bitmap 1000100010000101
inodes       [d a:0 r:4] [] [] [] [d a:12 r:2] [] [] [] [d a:11 r:2] [] [] [] [] [f a:-1 r:2] [] [f a:-1 r:1] 
data bitmap  1000001000001000
data         [(.,0) (..,0) (g,8) (w,4) (m,13) (z,13)] [] [] [] [] [] [(.,8) (..,0) (s,15)] [] [] [] [] [] [(.,4) (..,0)] [] [] [] 


Summary of files, directories::
  Files:       ['/m', '/z', '/g/s']
  Directories: ['/', '/g', '/w']
```