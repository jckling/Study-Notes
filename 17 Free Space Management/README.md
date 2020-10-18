## 	17 Free Space Management

首先了解一下程序的参数和默认值

```python
parser = OptionParser()
# 随机种子
parser.add_option('-s', '--seed',        default=0,          help='the random seed',                             action='store', type='int',    dest='seed')
# 堆大小，默认为 100 字节
parser.add_option('-S', '--size',        default=100,        help='size of the heap',                            action='store', type='int',    dest='heapSize') 
# 堆的起始位置，默认为 1000
parser.add_option('-b', '--baseAddr',    default=1000,       help='base address of heap',                        action='store', type='int',    dest='baseAddr') 
# 头块大小，默认为 0
parser.add_option('-H', '--headerSize',  default=0,          help='size of the header',                          action='store', type='int',    dest='headerSize')
# 对齐，默认不对齐
parser.add_option('-a', '--alignment',   default=-1,         help='align allocated units to size; -1->no align', action='store', type='int',    dest='alignment')
# 搜素策略，默认最优匹配（BEST）
parser.add_option('-p', '--policy',      default='BEST',     help='list search (BEST, WORST, FIRST)',            action='store', type='string', dest='policy') 
# 空闲列表顺序，默认按照地址排列
parser.add_option('-l', '--listOrder',   default='ADDRSORT', help='list order (ADDRSORT, SIZESORT+, SIZESORT-, INSERT-FRONT, INSERT-BACK)', action='store', type='string', dest='order') 
# 合并空前列表，默认不合并
parser.add_option('-C', '--coalesce',    default=False,      help='coalesce the free list?',                     action='store_true',           dest='coalesce')
# 随机生成的操作的数量，默认为 10
parser.add_option('-n', '--numOps',      default=10,         help='number of random ops to generate',            action='store', type='int',    dest='opsNum')
# 最大分配大小，默认为 10 字节
parser.add_option('-r', '--range',       default=10,         help='max alloc size',                              action='store', type='int',    dest='opsRange')
# 分配操作占所有操作的比例，默认 50%
parser.add_option('-P', '--percentAlloc',default=50,         help='percent of ops that are allocs',              action='store', type='int',    dest='opsPAlloc')
# 操作序列，分配大小,释放第n块
parser.add_option('-A', '--allocList',   default='',         help='instead of random, list of ops (+10,-0,etc)', action='store', type='string', dest='opsList')
# 计算答案
parser.add_option('-c', '--compute',     default=False,      help='compute answers for me',                      action='store_true',           dest='solve')

(options, args) = parser.parse_args()
```

使用默认参数的运行程序
- 空闲块回收后不进行合并，因此空闲列表中有小块

```bash
./malloc.py -c

# 输出
seed 0              <---- 随机种子
size 100            <---- 堆大小
baseAddr 1000       <---- 堆的起始位置
headerSize 0        <---- 没有头块
alignment -1        <---- 不对齐
policy BEST         <---- 最优匹配
listOrder ADDRSORT  <---- 空闲列表按照地址排序
coalesce False      <---- 不合并空闲块
numOps 10           <---- 操作数量
range 10            <---- 分配的块的最大大小
percentAlloc 50     <---- 50% 分配操作
allocList 
compute True

ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]                   <---- 分配 3 字节空间给 ptr[0]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1003 sz:97 ] <---- 释放 ptr[0] 的空间

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1008 sz:92 ] <---- 分配 1 字节空间给 ptr[1]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:92 ]   <---- 释放 ptr[1] 的空间

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]   <---- 分配 8 字节空间给 ptr[2]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ] <---- 释放 ptr[2] 的空间

ptr[3] = Alloc(8) returned 1008 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]   <---- 分配 8 字节空间给 ptr[3]

Free(ptr[3])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ] <---- 释放 ptr[3] 的空间

ptr[4] = Alloc(2) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ] <---- 分配 4 字节空间给 ptr[4]

ptr[5] = Alloc(7) returned 1008 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1015 sz:1 ][ addr:1016 sz:84 ] <---- 分配 4 字节空间给 ptr[5]
```

### 1

其实就是使用默认参数的输出，使用最优匹配策略，返回和请求大小一样或更大的空闲块（最小的那块），空间回收后不进行合并，前面分割的块大小不满足只能往后面寻找，导致空闲列表前面的分块都很小。

```bash
./malloc.py -n 10 -H 0 -p BEST -s 0 -c

# 输出（省略参数）
seed 0              <---- 随机种子
size 100            <---- 堆大小
baseAddr 1000       <---- 堆的起始位置
headerSize 0        <---- 没有头块
alignment -1        <---- 不对齐
policy BEST         <---- 最优匹配
listOrder ADDRSORT  <---- 空闲列表按照地址排序
coalesce False      <---- 不合并空闲块
numOps 10           <---- 操作数量
range 10            <---- 分配的块的最大大小
percentAlloc 50     <---- 50% 分配操作
allocList 
compute True

ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1003 sz:97 ]

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1008 sz:92 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:92 ]

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[3] = Alloc(8) returned 1008 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[3])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[4] = Alloc(2) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[5] = Alloc(7) returned 1008 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1015 sz:1 ][ addr:1016 sz:84 ]
```

### 2

改用最差匹配策略搜索空闲列表，最差匹配尝试寻找最大的空闲块，然后分割足够的空间，结果导致产生了更多小的分块。
- 每次都从大块中分割小块进行分配

```bash
./malloc.py -n 10 -H 0 -p WORST -s 0 -c

# 输出
seed 0
size 100
baseAddr 1000
headerSize 0
alignment -1
policy WORST        <---- 最差匹配
listOrder ADDRSORT
coalesce False
numOps 10
range 10
percentAlloc 50
allocList 
compute True

ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1003 sz:97 ]

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1008 sz:92 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:92 ]

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[3] = Alloc(8) returned 1016 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1024 sz:76 ]

Free(ptr[3])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1024 sz:76 ]

ptr[4] = Alloc(2) returned 1024 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1026 sz:74 ]

ptr[5] = Alloc(7) returned 1026 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1033 sz:67 ]
```

### 3

改用首次匹配策略，从分配结果来看和最优匹配相同，但是搜索次数减少了，因为只要匹配就返回，而不是选择返回“最优”大小的块。
- 找到大于等于分配大小的块就返回，相比最优匹配搜索次数大大减少

```bash
./malloc.py -n 10 -H 0 -p FIRST -s 0 -c

# 输出
seed 0
size 100
baseAddr 1000
headerSize 0
alignment -1
policy FIRST
listOrder ADDRSORT  <---- 首次匹配
coalesce False
numOps 10
range 10
percentAlloc 50
allocList 
compute True

ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1003 sz:97 ]

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1008 sz:92 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:92 ]

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[3] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[3])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[4] = Alloc(2) returned 1000 (searched 1 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[5] = Alloc(7) returned 1008 (searched 3 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1015 sz:1 ][ addr:1016 sz:84 ]
```

### 4

空闲列表的排序方式也会影响搜索效率。

#### 最优匹配（BEST）

最优匹配需要遍历整个空闲列表找到最优的选择，因此无论怎样排序都一样。

1. 按地址顺序排列

```bash
./malloc.py -n 10 -H 0 -p BEST -l ADDRSORT -s 0 -c

# 输出（省略配置说明）
ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1003 sz:97 ]

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1008 sz:92 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:92 ]

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[3] = Alloc(8) returned 1008 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[3])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[4] = Alloc(2) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[5] = Alloc(7) returned 1008 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1015 sz:1 ][ addr:1016 sz:84 ]
```

2. 按大小升序排列

```bash
./malloc.py -n 10 -H 0 -p BEST -l SIZESORT+ -s 0 -c

# 输出（省略配置说明）
ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1003 sz:97 ]

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1008 sz:92 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:92 ]

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[3] = Alloc(8) returned 1008 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[3])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[4] = Alloc(2) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[5] = Alloc(7) returned 1008 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1015 sz:1 ][ addr:1016 sz:84 ]
```

3. 按大小降序排列

```bash
./malloc.py -n 10 -H 0 -p BEST -l SIZESORT- -s 0 -c

# 输出（省略配置说明）
ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1003 sz:97 ][ addr:1000 sz:3 ]

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1008 sz:92 ][ addr:1000 sz:3 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1008 sz:92 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1016 sz:84 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1016 sz:84 ][ addr:1008 sz:8 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

ptr[3] = Alloc(8) returned 1008 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1016 sz:84 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

Free(ptr[3])
returned 0
Free List [ Size 4 ]: [ addr:1016 sz:84 ][ addr:1008 sz:8 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

ptr[4] = Alloc(2) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1016 sz:84 ][ addr:1008 sz:8 ][ addr:1003 sz:5 ][ addr:1002 sz:1 ]

ptr[5] = Alloc(7) returned 1008 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1016 sz:84 ][ addr:1015 sz:1 ][ addr:1003 sz:5 ][ addr:1002 sz:1 ]
```

#### 最差匹配（WORST）

最差匹配也要遍历整个空闲列表，因此无论怎样排序也是一样的。

1. 按地址顺序排列

```bash
./malloc.py -n 10 -H 0 -p WORST -l ADDRSORT -s 0 -c

# 输出（省略配置说明）
ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1003 sz:97 ]

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1008 sz:92 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:92 ]

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[3] = Alloc(8) returned 1016 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1024 sz:76 ]

Free(ptr[3])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1024 sz:76 ]

ptr[4] = Alloc(2) returned 1024 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1026 sz:74 ]

ptr[5] = Alloc(7) returned 1026 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1033 sz:67 ]
```

2. 按大小升序排列

```bash
./malloc.py -n 10 -H 0 -p WORST -l SIZESORT+ -s 0 -c

# 输出（省略配置说明）
ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1003 sz:97 ]

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1008 sz:92 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:92 ]

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[3] = Alloc(8) returned 1016 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1024 sz:76 ]

Free(ptr[3])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1024 sz:76 ]

ptr[4] = Alloc(2) returned 1024 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1026 sz:74 ]

ptr[5] = Alloc(7) returned 1026 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1033 sz:67 ]
```

3. 按大小降序排列

```bash
./malloc.py -n 10 -H 0 -p WORST -l SIZESORT- -s 0 -c

# 输出（省略配置说明）
ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1003 sz:97 ][ addr:1000 sz:3 ]

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1008 sz:92 ][ addr:1000 sz:3 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1008 sz:92 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1016 sz:84 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1016 sz:84 ][ addr:1008 sz:8 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

ptr[3] = Alloc(8) returned 1016 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1024 sz:76 ][ addr:1008 sz:8 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

Free(ptr[3])
returned 0
Free List [ Size 5 ]: [ addr:1024 sz:76 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

ptr[4] = Alloc(2) returned 1024 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1026 sz:74 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

ptr[5] = Alloc(7) returned 1026 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1033 sz:67 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]
```

#### 首次匹配（FIRST）

首次匹配找到大于等于请求大小的空闲块就返回，因此空闲块的排序会影响查找速度。
- 按地址顺序排列，看分配的大小，比较随机
- 按大小升序排列，请求大块需要更久地查找
- 按大小降序排列，只需检查第一个块是否满足大小，容易产生较多的小块

1. 按地址顺序排列

```bash
./malloc.py -n 10 -H 0 -p FIRST -l ADDRSORT -s 0 -c

# 输出（省略配置说明）
ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1003 sz:97 ]

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1008 sz:92 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:92 ]

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[3] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[3])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[4] = Alloc(2) returned 1000 (searched 1 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[5] = Alloc(7) returned 1008 (searched 3 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1015 sz:1 ][ addr:1016 sz:84 ]
```

2. 按大小升序排列

```bash
./malloc.py -n 10 -H 0 -p FIRST -l SIZESORT+ -s 0 -c

# 输出（省略配置说明）
ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1003 sz:97 ]

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1008 sz:92 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:92 ]

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[3] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[3])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[4] = Alloc(2) returned 1000 (searched 1 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[5] = Alloc(7) returned 1008 (searched 3 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1015 sz:1 ][ addr:1016 sz:84 ]
```

3. 按大小降序排列

```bash
./malloc.py -n 10 -H 0 -p FIRST -l SIZESORT- -s 0 -c

# 输出（省略配置说明）
ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1003 sz:97 ][ addr:1000 sz:3 ]

ptr[1] = Alloc(5) returned 1003 (searched 1 elements)
Free List [ Size 2 ]: [ addr:1008 sz:92 ][ addr:1000 sz:3 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1008 sz:92 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

ptr[2] = Alloc(8) returned 1008 (searched 1 elements)
Free List [ Size 3 ]: [ addr:1016 sz:84 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1016 sz:84 ][ addr:1008 sz:8 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

ptr[3] = Alloc(8) returned 1016 (searched 1 elements)
Free List [ Size 4 ]: [ addr:1024 sz:76 ][ addr:1008 sz:8 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

Free(ptr[3])
returned 0
Free List [ Size 5 ]: [ addr:1024 sz:76 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

ptr[4] = Alloc(2) returned 1024 (searched 1 elements)
Free List [ Size 5 ]: [ addr:1026 sz:74 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]

ptr[5] = Alloc(7) returned 1026 (searched 1 elements)
Free List [ Size 5 ]: [ addr:1033 sz:67 ][ addr:1008 sz:8 ][ addr:1016 sz:8 ][ addr:1003 sz:5 ][ addr:1000 sz:3 ]
```

### 5

增加随机操作的数量（`-n 1000`），可以看到不合并的话产生了非常多的小块空闲空间，难以利用，同时还导致了空闲列表的长度增加，使得遍历效率低下。

<details>
  <summary>运行结果</summary>

```bash
./malloc.py -n 1000 -c

# 输出
seed 0
size 100
baseAddr 1000
headerSize 0
alignment -1
policy BEST
listOrder ADDRSORT
coalesce False
numOps 1000
range 10
percentAlloc 50
allocList 
compute True

ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1003 sz:97 ]

ptr[1] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1008 sz:92 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:92 ]

ptr[2] = Alloc(8) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[3] = Alloc(8) returned 1008 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1016 sz:84 ]

Free(ptr[3])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:3 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[4] = Alloc(2) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:8 ][ addr:1016 sz:84 ]

ptr[5] = Alloc(7) returned 1008 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1015 sz:1 ][ addr:1016 sz:84 ]

Free(ptr[5])
returned 0
Free List [ Size 5 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:7 ][ addr:1015 sz:1 ][ addr:1016 sz:84 ]

ptr[6] = Alloc(9) returned 1016 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:7 ][ addr:1015 sz:1 ][ addr:1025 sz:75 ]

ptr[7] = Alloc(9) returned 1025 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:7 ][ addr:1015 sz:1 ][ addr:1034 sz:66 ]

Free(ptr[4])
returned 0
Free List [ Size 6 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:7 ][ addr:1015 sz:1 ][ addr:1034 sz:66 ]

Free(ptr[6])
returned 0
Free List [ Size 7 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:7 ][ addr:1015 sz:1 ][ addr:1016 sz:9 ][ addr:1034 sz:66 ]

Free(ptr[7])
returned 0
Free List [ Size 8 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:7 ][ addr:1015 sz:1 ][ addr:1016 sz:9 ][ addr:1025 sz:9 ][ addr:1034 sz:66 ]

ptr[8] = Alloc(5) returned 1003 (searched 8 elements)
Free List [ Size 7 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1008 sz:7 ][ addr:1015 sz:1 ][ addr:1016 sz:9 ][ addr:1025 sz:9 ][ addr:1034 sz:66 ]

Free(ptr[8])
returned 0
Free List [ Size 8 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:7 ][ addr:1015 sz:1 ][ addr:1016 sz:9 ][ addr:1025 sz:9 ][ addr:1034 sz:66 ]

ptr[9] = Alloc(9) returned 1016 (searched 8 elements)
Free List [ Size 7 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:7 ][ addr:1015 sz:1 ][ addr:1025 sz:9 ][ addr:1034 sz:66 ]

ptr[10] = Alloc(6) returned 1008 (searched 7 elements)
Free List [ Size 7 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1025 sz:9 ][ addr:1034 sz:66 ]

ptr[11] = Alloc(10) returned 1034 (searched 7 elements)
Free List [ Size 7 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1025 sz:9 ][ addr:1044 sz:56 ]

Free(ptr[10])
returned 0
Free List [ Size 8 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:5 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1025 sz:9 ][ addr:1044 sz:56 ]

ptr[12] = Alloc(4) returned 1003 (searched 8 elements)
Free List [ Size 8 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1025 sz:9 ][ addr:1044 sz:56 ]

Free(ptr[12])
returned 0
Free List [ Size 9 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1025 sz:9 ][ addr:1044 sz:56 ]

ptr[13] = Alloc(6) returned 1008 (searched 9 elements)
Free List [ Size 8 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1025 sz:9 ][ addr:1044 sz:56 ]

Free(ptr[11])
returned 0
Free List [ Size 9 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1025 sz:9 ][ addr:1034 sz:10 ][ addr:1044 sz:56 ]

Free(ptr[13])
returned 0
Free List [ Size 10 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1025 sz:9 ][ addr:1034 sz:10 ][ addr:1044 sz:56 ]

Free(ptr[9])
returned 0
Free List [ Size 11 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:9 ][ addr:1025 sz:9 ][ addr:1034 sz:10 ][ addr:1044 sz:56 ]

ptr[14] = Alloc(6) returned 1008 (searched 11 elements)
Free List [ Size 10 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:9 ][ addr:1025 sz:9 ][ addr:1034 sz:10 ][ addr:1044 sz:56 ]

ptr[15] = Alloc(6) returned 1016 (searched 10 elements)
Free List [ Size 10 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:9 ][ addr:1034 sz:10 ][ addr:1044 sz:56 ]

ptr[16] = Alloc(2) returned 1000 (searched 10 elements)
Free List [ Size 9 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:9 ][ addr:1034 sz:10 ][ addr:1044 sz:56 ]

ptr[17] = Alloc(7) returned 1025 (searched 9 elements)
Free List [ Size 9 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1022 sz:3 ][ addr:1032 sz:2 ][ addr:1034 sz:10 ][ addr:1044 sz:56 ]

Free(ptr[15])
returned 0
Free List [ Size 10 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1032 sz:2 ][ addr:1034 sz:10 ][ addr:1044 sz:56 ]

ptr[18] = Alloc(8) returned 1034 (searched 10 elements)
Free List [ Size 10 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1032 sz:2 ][ addr:1042 sz:2 ][ addr:1044 sz:56 ]

Free(ptr[18])
returned 0
Free List [ Size 11 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1032 sz:2 ][ addr:1034 sz:8 ][ addr:1042 sz:2 ][ addr:1044 sz:56 ]

Free(ptr[17])
returned 0
Free List [ Size 12 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:8 ][ addr:1042 sz:2 ][ addr:1044 sz:56 ]

Free(ptr[16])
returned 0
Free List [ Size 13 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:8 ][ addr:1042 sz:2 ][ addr:1044 sz:56 ]

ptr[19] = Alloc(8) returned 1034 (searched 13 elements)
Free List [ Size 12 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1042 sz:2 ][ addr:1044 sz:56 ]

ptr[20] = Alloc(9) returned 1044 (searched 12 elements)
Free List [ Size 12 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1042 sz:2 ][ addr:1053 sz:47 ]

Free(ptr[20])
returned 0
Free List [ Size 13 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1042 sz:2 ][ addr:1044 sz:9 ][ addr:1053 sz:47 ]

Free(ptr[19])
returned 0
Free List [ Size 14 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:8 ][ addr:1042 sz:2 ][ addr:1044 sz:9 ][ addr:1053 sz:47 ]

Free(ptr[14])
returned 0
Free List [ Size 15 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:8 ][ addr:1042 sz:2 ][ addr:1044 sz:9 ][ addr:1053 sz:47 ]

ptr[21] = Alloc(7) returned 1025 (searched 15 elements)
Free List [ Size 14 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1032 sz:2 ][ addr:1034 sz:8 ][ addr:1042 sz:2 ][ addr:1044 sz:9 ][ addr:1053 sz:47 ]

ptr[22] = Alloc(7) returned 1034 (searched 14 elements)
Free List [ Size 14 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:9 ][ addr:1053 sz:47 ]

Free(ptr[21])
returned 0
Free List [ Size 15 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:9 ][ addr:1053 sz:47 ]

Free(ptr[22])
returned 0
Free List [ Size 16 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:9 ][ addr:1053 sz:47 ]

ptr[23] = Alloc(8) returned 1044 (searched 16 elements)
Free List [ Size 16 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:47 ]

ptr[24] = Alloc(9) returned 1053 (searched 16 elements)
Free List [ Size 16 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1062 sz:38 ]

ptr[25] = Alloc(2) returned 1000 (searched 16 elements)
Free List [ Size 15 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1062 sz:38 ]

Free(ptr[23])
returned 0
Free List [ Size 16 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1062 sz:38 ]

Free(ptr[25])
returned 0
Free List [ Size 17 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1062 sz:38 ]

Free(ptr[24])
returned 0
Free List [ Size 18 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:38 ]

ptr[26] = Alloc(7) returned 1025 (searched 18 elements)
Free List [ Size 17 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:38 ]

Free(ptr[26])
returned 0
Free List [ Size 18 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:38 ]

ptr[27] = Alloc(4) returned 1003 (searched 18 elements)
Free List [ Size 17 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:38 ]

Free(ptr[27])
returned 0
Free List [ Size 18 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:38 ]

ptr[28] = Alloc(10) returned 1062 (searched 18 elements)
Free List [ Size 18 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1072 sz:28 ]

ptr[29] = Alloc(2) returned 1000 (searched 18 elements)
Free List [ Size 17 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1072 sz:28 ]

ptr[30] = Alloc(9) returned 1053 (searched 17 elements)
Free List [ Size 16 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1072 sz:28 ]

Free(ptr[28])
returned 0
Free List [ Size 17 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[31] = Alloc(2) returned 1032 (searched 17 elements)
Free List [ Size 16 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1022 sz:3 ][ addr:1025 sz:7 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[32] = Alloc(3) returned 1022 (searched 16 elements)
Free List [ Size 15 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1025 sz:7 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

Free(ptr[30])
returned 0
Free List [ Size 16 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1025 sz:7 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[33] = Alloc(6) returned 1008 (searched 16 elements)
Free List [ Size 15 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1025 sz:7 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[34] = Alloc(2) returned 1042 (searched 15 elements)
Free List [ Size 14 ]: [ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1025 sz:7 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

Free(ptr[29])
returned 0
Free List [ Size 15 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1025 sz:7 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[35] = Alloc(8) returned 1044 (searched 15 elements)
Free List [ Size 14 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1025 sz:7 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

Free(ptr[35])
returned 0
Free List [ Size 15 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1025 sz:7 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[36] = Alloc(7) returned 1025 (searched 15 elements)
Free List [ Size 14 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

Free(ptr[31])
returned 0
Free List [ Size 15 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

Free(ptr[36])
returned 0
Free List [ Size 16 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:4 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[37] = Alloc(3) returned 1003 (searched 16 elements)
Free List [ Size 16 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

Free(ptr[33])
returned 0
Free List [ Size 17 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:6 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[38] = Alloc(5) returned 1008 (searched 17 elements)
Free List [ Size 17 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[39] = Alloc(6) returned 1016 (searched 17 elements)
Free List [ Size 16 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

Free(ptr[34])
returned 0
Free List [ Size 17 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[40] = Alloc(9) returned 1053 (searched 17 elements)
Free List [ Size 16 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1025 sz:7 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[41] = Alloc(6) returned 1025 (searched 16 elements)
Free List [ Size 16 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[42] = Alloc(8) returned 1044 (searched 16 elements)
Free List [ Size 15 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[43] = Alloc(1) returned 1002 (searched 15 elements)
Free List [ Size 14 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:7 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[44] = Alloc(3) returned 1034 (searched 14 elements)
Free List [ Size 14 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

Free(ptr[39])
returned 0
Free List [ Size 15 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[45] = Alloc(4) returned 1037 (searched 15 elements)
Free List [ Size 14 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

Free(ptr[42])
returned 0
Free List [ Size 15 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

Free(ptr[43])
returned 0
Free List [ Size 16 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[46] = Alloc(5) returned 1016 (searched 16 elements)
Free List [ Size 16 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

Free(ptr[32])
returned 0
Free List [ Size 17 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:8 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[47] = Alloc(4) returned 1044 (searched 17 elements)
Free List [ Size 17 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1062 sz:10 ][ addr:1072 sz:28 ]

ptr[48] = Alloc(7) returned 1062 (searched 17 elements)
Free List [ Size 17 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:28 ]

ptr[49] = Alloc(9) returned 1072 (searched 17 elements)
Free List [ Size 17 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1081 sz:19 ]

Free(ptr[44])
returned 0
Free List [ Size 18 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1081 sz:19 ]

ptr[50] = Alloc(8) returned 1081 (searched 18 elements)
Free List [ Size 18 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1089 sz:11 ]

ptr[51] = Alloc(7) returned 1089 (searched 18 elements)
Free List [ Size 18 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1096 sz:4 ]

ptr[52] = Alloc(5) returned -1 (searched 18 elements)
Free List [ Size 18 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1096 sz:4 ]

ptr[53] = Alloc(2) returned 1000 (searched 18 elements)
Free List [ Size 17 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1096 sz:4 ]

Free(ptr[46])
returned 0
Free List [ Size 18 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1096 sz:4 ]

Free(ptr[50])
returned 0
Free List [ Size 19 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1081 sz:8 ][ addr:1096 sz:4 ]

Free(ptr[45])
returned 0
Free List [ Size 20 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1081 sz:8 ][ addr:1096 sz:4 ]

ptr[54] = Alloc(5) returned 1016 (searched 20 elements)
Free List [ Size 19 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1081 sz:8 ][ addr:1096 sz:4 ]

Free(ptr[53])
returned 0
Free List [ Size 20 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1081 sz:8 ][ addr:1096 sz:4 ]

Free(ptr[38])
returned 0
Free List [ Size 21 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1081 sz:8 ][ addr:1096 sz:4 ]

Free(ptr[49])
returned 0
Free List [ Size 22 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:9 ][ addr:1081 sz:8 ][ addr:1096 sz:4 ]

ptr[55] = Alloc(8) returned 1081 (searched 22 elements)
Free List [ Size 21 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:9 ][ addr:1096 sz:4 ]

Free(ptr[47])
returned 0
Free List [ Size 22 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:9 ][ addr:1096 sz:4 ]

Free(ptr[41])
returned 0
Free List [ Size 23 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:9 ][ addr:1096 sz:4 ]

ptr[56] = Alloc(8) returned 1072 (searched 23 elements)
Free List [ Size 23 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1096 sz:4 ]

ptr[57] = Alloc(9) returned -1 (searched 23 elements)
Free List [ Size 23 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1096 sz:4 ]

Free(ptr[37])
returned 0
Free List [ Size 24 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1096 sz:4 ]

ptr[58] = Alloc(7) returned -1 (searched 24 elements)
Free List [ Size 24 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1096 sz:4 ]

Free(ptr[48])
returned 0
Free List [ Size 25 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1096 sz:4 ]

Free(ptr[40])
returned 0
Free List [ Size 26 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1096 sz:4 ]

Free(ptr[54])
returned 0
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1096 sz:4 ]

ptr[59] = Alloc(3) returned 1003 (searched 27 elements)
Free List [ Size 26 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:9 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1096 sz:4 ]

ptr[60] = Alloc(8) returned 1053 (searched 26 elements)
Free List [ Size 26 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1096 sz:4 ]

Free(ptr[51])
returned 0
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[59])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[61] = Alloc(9) returned -1 (searched 28 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[62] = Alloc(1) returned 1002 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[63] = Alloc(7) returned 1062 (searched 27 elements)
Free List [ Size 26 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[63])
returned 0
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[62])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[64] = Alloc(8) returned -1 (searched 28 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[56])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[60])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[55])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[65] = Alloc(6) returned 1025 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[66] = Alloc(2) returned 1000 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[67] = Alloc(8) returned 1053 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[66])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[65])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[68] = Alloc(10) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[69] = Alloc(4) returned 1037 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[67])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[70] = Alloc(3) returned 1003 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[71] = Alloc(2) returned 1000 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[69])
returned 0
Free List [ Size 29 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[72] = Alloc(4) returned 1037 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[73] = Alloc(1) returned 1002 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[71])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[73])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[74] = Alloc(5) returned 1008 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[72])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[75] = Alloc(8) returned 1053 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[75])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[70])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[74])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[76] = Alloc(1) returned 1002 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[76])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[77] = Alloc(4) returned 1037 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[77])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[78] = Alloc(6) returned 1025 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[78])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[79] = Alloc(10) returned -1 (searched 31 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[80] = Alloc(8) returned 1053 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[81] = Alloc(4) returned 1037 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[82] = Alloc(9) returned -1 (searched 29 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[81])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[83] = Alloc(7) returned 1062 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[84] = Alloc(4) returned 1037 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[85] = Alloc(1) returned 1002 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[80])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[86] = Alloc(2) returned 1000 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[87] = Alloc(6) returned 1025 (searched 27 elements)
Free List [ Size 26 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[88] = Alloc(10) returned -1 (searched 26 elements)
Free List [ Size 26 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[83])
returned 0
Free List [ Size 27 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[89] = Alloc(7) returned 1062 (searched 27 elements)
Free List [ Size 26 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[86])
returned 0
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[85])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[90] = Alloc(5) returned 1008 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[84])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[87])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[91] = Alloc(10) returned -1 (searched 29 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[90])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[92] = Alloc(2) returned 1000 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[93] = Alloc(8) returned 1053 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[92])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[93])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[94] = Alloc(1) returned 1002 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[89])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[95] = Alloc(1) returned 1006 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[96] = Alloc(9) returned -1 (searched 29 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[97] = Alloc(2) returned 1000 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[98] = Alloc(7) returned 1062 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[97])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[95])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[98])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[94])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[99] = Alloc(6) returned 1025 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[99])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[100] = Alloc(8) returned 1053 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[101] = Alloc(6) returned 1025 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[101])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[100])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[102] = Alloc(6) returned 1025 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[103] = Alloc(1) returned 1002 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[103])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[104] = Alloc(5) returned 1008 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[102])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[104])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[105] = Alloc(9) returned -1 (searched 31 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[106] = Alloc(1) returned 1002 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[107] = Alloc(5) returned 1008 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[107])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[106])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[108] = Alloc(7) returned 1062 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[109] = Alloc(1) returned 1002 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[110] = Alloc(2) returned 1000 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[111] = Alloc(7) returned 1089 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1096 sz:4 ]

Free(ptr[108])
returned 0
Free List [ Size 28 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1096 sz:4 ]

Free(ptr[110])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1096 sz:4 ]

ptr[112] = Alloc(8) returned 1053 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1096 sz:4 ]

ptr[113] = Alloc(9) returned -1 (searched 28 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1096 sz:4 ]

Free(ptr[111])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[109])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[114] = Alloc(7) returned 1062 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[114])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[115] = Alloc(10) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[112])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[116] = Alloc(8) returned 1053 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[117] = Alloc(8) returned 1072 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[118] = Alloc(8) returned 1081 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[119] = Alloc(1) returned 1002 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[117])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[119])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[118])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[120] = Alloc(1) returned 1002 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[120])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[116])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[121] = Alloc(4) returned 1037 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[122] = Alloc(5) returned 1008 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[122])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[121])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[123] = Alloc(8) returned 1053 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[123])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[124] = Alloc(7) returned 1062 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[125] = Alloc(10) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[124])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[126] = Alloc(1) returned 1002 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[127] = Alloc(1) returned 1006 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[128] = Alloc(1) returned 1007 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[128])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[129] = Alloc(9) returned -1 (searched 29 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[130] = Alloc(3) returned 1003 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[130])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[131] = Alloc(1) returned 1007 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[132] = Alloc(1) returned 1013 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1008 sz:5 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[132])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[133] = Alloc(2) returned 1000 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1003 sz:3 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[134] = Alloc(10) returned -1 (searched 27 elements)
Free List [ Size 27 ]: [ addr:1003 sz:3 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[135] = Alloc(10) returned -1 (searched 27 elements)
Free List [ Size 27 ]: [ addr:1003 sz:3 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[136] = Alloc(5) returned 1008 (searched 27 elements)
Free List [ Size 26 ]: [ addr:1003 sz:3 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[137] = Alloc(10) returned -1 (searched 26 elements)
Free List [ Size 26 ]: [ addr:1003 sz:3 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[133])
returned 0
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[138] = Alloc(10) returned -1 (searched 27 elements)
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[139] = Alloc(6) returned 1025 (searched 27 elements)
Free List [ Size 26 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[140] = Alloc(9) returned -1 (searched 26 elements)
Free List [ Size 26 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[139])
returned 0
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[141] = Alloc(3) returned 1003 (searched 27 elements)
Free List [ Size 26 ]: [ addr:1000 sz:2 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[127])
returned 0
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[142] = Alloc(1) returned 1006 (searched 27 elements)
Free List [ Size 26 ]: [ addr:1000 sz:2 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[143] = Alloc(1) returned 1013 (searched 26 elements)
Free List [ Size 25 ]: [ addr:1000 sz:2 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[144] = Alloc(1) returned 1014 (searched 25 elements)
Free List [ Size 24 ]: [ addr:1000 sz:2 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[145] = Alloc(6) returned 1025 (searched 24 elements)
Free List [ Size 23 ]: [ addr:1000 sz:2 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

Free(ptr[131])
returned 0
Free List [ Size 24 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[146] = Alloc(7) returned 1062 (searched 24 elements)
Free List [ Size 23 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[147] = Alloc(5) returned 1016 (searched 23 elements)
Free List [ Size 22 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[148] = Alloc(10) returned -1 (searched 22 elements)
Free List [ Size 22 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1089 sz:7 ][ addr:1096 sz:4 ]

ptr[149] = Alloc(5) returned 1089 (searched 22 elements)
Free List [ Size 22 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[150] = Alloc(8) returned 1053 (searched 22 elements)
Free List [ Size 21 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[151] = Alloc(3) returned 1022 (searched 21 elements)
Free List [ Size 20 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:8 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[152] = Alloc(5) returned 1072 (searched 20 elements)
Free List [ Size 20 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[150])
returned 0
Free List [ Size 21 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:8 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[153] = Alloc(6) returned 1053 (searched 21 elements)
Free List [ Size 21 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[151])
returned 0
Free List [ Size 22 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[154] = Alloc(4) returned 1037 (searched 22 elements)
Free List [ Size 21 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[144])
returned 0
Free List [ Size 22 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:8 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[155] = Alloc(5) returned 1081 (searched 22 elements)
Free List [ Size 22 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[136])
returned 0
Free List [ Size 23 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[156] = Alloc(7) returned -1 (searched 23 elements)
Free List [ Size 23 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[157] = Alloc(3) returned 1022 (searched 23 elements)
Free List [ Size 22 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[158] = Alloc(7) returned -1 (searched 22 elements)
Free List [ Size 22 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[126])
returned 0
Free List [ Size 23 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[159] = Alloc(8) returned -1 (searched 23 elements)
Free List [ Size 23 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[149])
returned 0
Free List [ Size 24 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[160] = Alloc(8) returned -1 (searched 24 elements)
Free List [ Size 24 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[161] = Alloc(7) returned -1 (searched 24 elements)
Free List [ Size 24 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[143])
returned 0
Free List [ Size 25 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[145])
returned 0
Free List [ Size 26 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[142])
returned 0
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[141])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[162] = Alloc(6) returned 1025 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[153])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[163] = Alloc(3) returned 1003 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[164] = Alloc(8) returned -1 (searched 27 elements)
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[155])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[165] = Alloc(8) returned -1 (searched 28 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[166] = Alloc(4) returned 1044 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[147])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[152])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[167] = Alloc(3) returned 1034 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[163])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[162])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[168] = Alloc(7) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[169] = Alloc(8) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[154])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[170] = Alloc(7) returned -1 (searched 31 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[171] = Alloc(7) returned -1 (searched 31 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[172] = Alloc(6) returned 1025 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[173] = Alloc(7) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[174] = Alloc(5) returned 1008 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[175] = Alloc(5) returned 1016 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[166])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[146])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[176] = Alloc(8) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[177] = Alloc(7) returned 1062 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[178] = Alloc(5) returned 1072 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[157])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[167])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[177])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[175])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[179] = Alloc(1) returned 1002 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[179])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[178])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[172])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[174])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[180] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[181] = Alloc(2) returned 1000 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[182] = Alloc(9) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[183] = Alloc(5) returned 1016 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[181])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[184] = Alloc(10) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[185] = Alloc(8) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[186] = Alloc(9) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[187] = Alloc(3) returned 1003 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[188] = Alloc(10) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[180])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[189] = Alloc(3) returned 1022 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[190] = Alloc(2) returned 1000 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[191] = Alloc(7) returned 1062 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[192] = Alloc(7) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[190])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[187])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[189])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[193] = Alloc(7) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[191])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[183])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[194] = Alloc(8) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[195] = Alloc(3) returned 1003 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[196] = Alloc(2) returned 1000 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[197] = Alloc(7) returned 1062 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[198] = Alloc(8) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[197])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[199] = Alloc(10) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[200] = Alloc(4) returned 1037 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[201] = Alloc(9) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[195])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[202] = Alloc(4) returned 1044 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[203] = Alloc(1) returned 1002 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[204] = Alloc(3) returned 1003 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[196])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[205] = Alloc(7) returned 1062 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[202])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[203])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[206] = Alloc(8) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[207] = Alloc(10) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[208] = Alloc(5) returned 1008 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[200])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[208])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[209] = Alloc(2) returned 1000 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[210] = Alloc(1) returned 1002 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[205])
returned 0
Free List [ Size 32 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[209])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[211] = Alloc(5) returned 1008 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[211])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[212] = Alloc(2) returned 1000 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[213] = Alloc(2) returned 1032 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[213])
returned 0
Free List [ Size 32 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[214] = Alloc(5) returned 1008 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[210])
returned 0
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[204])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[215] = Alloc(5) returned 1016 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[214])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[216] = Alloc(3) returned 1003 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[217] = Alloc(8) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[218] = Alloc(8) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[219] = Alloc(3) returned 1022 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[216])
returned 0
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[215])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[212])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[219])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[220] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[220])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[221] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[222] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[222])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[223] = Alloc(2) returned 1000 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[223])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[224] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[225] = Alloc(2) returned 1000 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[226] = Alloc(10) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[224])
returned 0
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[225])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[227] = Alloc(8) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[228] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[228])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[229] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[230] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[231] = Alloc(3) returned 1003 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[231])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[232] = Alloc(10) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[233] = Alloc(4) returned 1037 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[230])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[233])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[234] = Alloc(1) returned 1002 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[235] = Alloc(8) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[234])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[236] = Alloc(8) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[237] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[238] = Alloc(4) returned 1037 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[238])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[239] = Alloc(1) returned 1002 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[237])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[240] = Alloc(3) returned 1003 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[239])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[241] = Alloc(10) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[242] = Alloc(9) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[243] = Alloc(5) returned 1008 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[244] = Alloc(2) returned 1000 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[245] = Alloc(10) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[243])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[246] = Alloc(3) returned 1022 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[246])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[240])
returned 0
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[247] = Alloc(10) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[248] = Alloc(4) returned 1037 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[249] = Alloc(2) returned 1032 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[248])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[244])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[250] = Alloc(9) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[249])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[251] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[252] = Alloc(8) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[253] = Alloc(1) returned 1002 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[253])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[254] = Alloc(2) returned 1000 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[254])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[255] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[256] = Alloc(1) returned 1002 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[257] = Alloc(2) returned 1000 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[258] = Alloc(4) returned 1037 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[257])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[259] = Alloc(5) returned 1008 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[260] = Alloc(4) returned 1044 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[259])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[260])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[256])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[258])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[261] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[262] = Alloc(8) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[263] = Alloc(7) returned 1062 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[263])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[264] = Alloc(7) returned 1062 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[265] = Alloc(6) returned 1025 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[266] = Alloc(10) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[261])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[264])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[265])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[267] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[268] = Alloc(8) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[269] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[270] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[271] = Alloc(8) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[270])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[272] = Alloc(2) returned 1000 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[273] = Alloc(2) returned 1032 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[273])
returned 0
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[274] = Alloc(10) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[272])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[275] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[276] = Alloc(10) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[277] = Alloc(2) returned 1000 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[275])
returned 0
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[278] = Alloc(6) returned 1025 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[278])
returned 0
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[277])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[279] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[279])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[280] = Alloc(8) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[281] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[281])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[282] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[283] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[283])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[284] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[284])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[285] = Alloc(8) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[286] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[287] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[288] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[288])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[289] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[290] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[291] = Alloc(1) returned 1002 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[292] = Alloc(3) returned 1003 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[291])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[292])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[293] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[294] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[294])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[295] = Alloc(1) returned 1002 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[296] = Alloc(6) returned 1025 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[297] = Alloc(6) returned 1053 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[298] = Alloc(1) returned 1006 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[299] = Alloc(2) returned 1000 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[295])
returned 0
Free List [ Size 31 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[299])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[296])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[298])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[297])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[300] = Alloc(4) returned 1037 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[301] = Alloc(2) returned 1000 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[302] = Alloc(5) returned 1008 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[302])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[303] = Alloc(9) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[304] = Alloc(6) returned 1025 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[301])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[300])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[304])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[305] = Alloc(3) returned 1003 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[305])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[306] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[307] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[308] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[308])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[309] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[310] = Alloc(3) returned 1003 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[311] = Alloc(2) returned 1000 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[312] = Alloc(7) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[313] = Alloc(6) returned 1025 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[313])
returned 0
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[314] = Alloc(9) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[315] = Alloc(5) returned 1008 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[316] = Alloc(5) returned 1016 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[311])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[316])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[317] = Alloc(4) returned 1037 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[318] = Alloc(8) returned -1 (searched 31 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[319] = Alloc(9) returned -1 (searched 31 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[320] = Alloc(5) returned 1016 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[321] = Alloc(4) returned 1044 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[322] = Alloc(1) returned 1002 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[320])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[323] = Alloc(9) returned -1 (searched 29 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[324] = Alloc(1) returned 1006 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[325] = Alloc(10) returned -1 (searched 28 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[321])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[322])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[326] = Alloc(1) returned 1002 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[310])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[327] = Alloc(4) returned 1044 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[328] = Alloc(4) returned 1048 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[329] = Alloc(7) returned -1 (searched 28 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[309])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[330] = Alloc(6) returned 1025 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[326])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[331] = Alloc(1) returned 1002 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[330])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[317])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[315])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[327])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[328])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[332] = Alloc(10) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[324])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[333] = Alloc(4) returned 1037 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[334] = Alloc(6) returned 1025 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[335] = Alloc(2) returned 1000 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[334])
returned 0
Free List [ Size 32 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[336] = Alloc(9) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[335])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[337] = Alloc(9) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[331])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[338] = Alloc(3) returned 1003 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[339] = Alloc(3) returned 1022 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[340] = Alloc(9) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[341] = Alloc(9) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[342] = Alloc(6) returned 1025 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[343] = Alloc(10) returned -1 (searched 31 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[344] = Alloc(4) returned 1044 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[344])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[345] = Alloc(9) returned -1 (searched 31 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[333])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[338])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[342])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[339])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[346] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[346])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[347] = Alloc(2) returned 1000 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[347])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[348] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[348])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[349] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[350] = Alloc(3) returned 1003 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[351] = Alloc(7) returned 1062 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[352] = Alloc(6) returned 1025 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[352])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[350])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[353] = Alloc(7) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[354] = Alloc(3) returned 1003 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[355] = Alloc(4) returned 1037 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[355])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[356] = Alloc(9) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[357] = Alloc(8) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[358] = Alloc(5) returned 1016 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[351])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[358])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[349])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[359] = Alloc(5) returned 1008 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[359])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[360] = Alloc(6) returned 1025 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[354])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[360])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[361] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[362] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[363] = Alloc(7) returned 1062 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[364] = Alloc(5) returned 1008 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[362])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[363])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[365] = Alloc(7) returned 1062 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[366] = Alloc(5) returned 1016 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[367] = Alloc(1) returned 1002 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[366])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[365])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[364])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[368] = Alloc(3) returned 1003 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[368])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[369] = Alloc(9) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[367])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[370] = Alloc(2) returned 1000 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[370])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[371] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[372] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[373] = Alloc(7) returned 1062 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[373])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[372])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[374] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[375] = Alloc(1) returned 1002 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[375])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[376] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[376])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[377] = Alloc(8) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[378] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[379] = Alloc(2) returned 1000 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[380] = Alloc(6) returned 1025 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[381] = Alloc(5) returned 1008 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[381])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[380])
returned 0
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[382] = Alloc(9) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[379])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[383] = Alloc(8) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[384] = Alloc(1) returned 1002 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[385] = Alloc(4) returned 1037 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[385])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[384])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[386] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[387] = Alloc(6) returned 1053 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[388] = Alloc(5) returned 1008 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[389] = Alloc(9) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[390] = Alloc(7) returned 1062 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[391] = Alloc(2) returned 1000 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[386])
returned 0
Free List [ Size 31 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[391])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[392] = Alloc(1) returned 1002 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[393] = Alloc(4) returned 1037 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[390])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[394] = Alloc(3) returned 1003 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[395] = Alloc(2) returned 1000 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[387])
returned 0
Free List [ Size 30 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[395])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[396] = Alloc(6) returned 1025 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[397] = Alloc(9) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[394])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[398] = Alloc(7) returned 1062 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[393])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[392])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[399] = Alloc(1) returned 1002 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[400] = Alloc(9) returned -1 (searched 31 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[401] = Alloc(3) returned 1003 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[402] = Alloc(10) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[396])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[403] = Alloc(6) returned 1025 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[404] = Alloc(4) returned 1037 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[405] = Alloc(8) returned -1 (searched 29 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[406] = Alloc(10) returned -1 (searched 29 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[399])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[398])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[407] = Alloc(2) returned 1000 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[403])
returned 0
Free List [ Size 31 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[401])
returned 0
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[404])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[388])
returned 0
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[408] = Alloc(5) returned 1008 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[408])
returned 0
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[407])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[409] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[410] = Alloc(3) returned 1003 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[411] = Alloc(10) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[412] = Alloc(2) returned 1000 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[413] = Alloc(4) returned 1037 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[413])
returned 0
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[410])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[412])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[409])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[414] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[415] = Alloc(4) returned 1037 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[414])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[415])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[416] = Alloc(1) returned 1002 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[417] = Alloc(4) returned 1037 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[418] = Alloc(8) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[419] = Alloc(3) returned 1003 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[420] = Alloc(4) returned 1044 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[421] = Alloc(2) returned 1000 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[421])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[422] = Alloc(8) returned -1 (searched 31 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[423] = Alloc(1) returned 1006 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[423])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[424] = Alloc(2) returned 1000 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[425] = Alloc(10) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[426] = Alloc(9) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[427] = Alloc(4) returned 1048 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[420])
returned 0
Free List [ Size 30 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[428] = Alloc(6) returned 1025 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[427])
returned 0
Free List [ Size 30 ]: [ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[424])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[416])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[428])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[429] = Alloc(7) returned 1062 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[419])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[430] = Alloc(6) returned 1025 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[417])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[429])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[431] = Alloc(10) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[432] = Alloc(9) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[433] = Alloc(5) returned 1008 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[434] = Alloc(5) returned 1016 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[435] = Alloc(6) returned 1053 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[436] = Alloc(9) returned -1 (searched 31 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[437] = Alloc(3) returned 1003 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[438] = Alloc(10) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[439] = Alloc(8) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[440] = Alloc(5) returned 1072 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[434])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[441] = Alloc(3) returned 1022 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[442] = Alloc(3) returned 1034 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[443] = Alloc(7) returned 1062 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[443])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[437])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[444] = Alloc(3) returned 1003 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[441])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[430])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[445] = Alloc(9) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[442])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[446] = Alloc(7) returned 1062 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[447] = Alloc(2) returned 1000 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[448] = Alloc(8) returned -1 (searched 29 elements)
Free List [ Size 29 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[447])
returned 0
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[444])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[440])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[449] = Alloc(10) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[435])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[450] = Alloc(7) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[446])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[433])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[451] = Alloc(3) returned 1003 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[451])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[452] = Alloc(1) returned 1002 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[453] = Alloc(5) returned 1008 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[452])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[453])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[454] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[454])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[455] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[456] = Alloc(6) returned 1025 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[457] = Alloc(5) returned 1008 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[458] = Alloc(7) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[456])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[459] = Alloc(8) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[457])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[460] = Alloc(5) returned 1008 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[460])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[455])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[461] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[462] = Alloc(3) returned 1003 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[463] = Alloc(10) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[464] = Alloc(7) returned 1062 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[465] = Alloc(4) returned 1037 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[462])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[464])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[466] = Alloc(5) returned 1008 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[465])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[466])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[467] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[468] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[469] = Alloc(3) returned 1003 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[469])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[470] = Alloc(4) returned 1037 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[470])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[471] = Alloc(1) returned 1002 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[472] = Alloc(7) returned 1062 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[471])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[472])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[473] = Alloc(8) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[474] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[474])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[475] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[476] = Alloc(3) returned 1003 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[477] = Alloc(4) returned 1037 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[478] = Alloc(9) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[479] = Alloc(9) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[476])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[475])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[480] = Alloc(1) returned 1002 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[477])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[481] = Alloc(10) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[480])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[482] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[482])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[483] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[483])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[484] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[484])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[485] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[486] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[487] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[488] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[488])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[489] = Alloc(8) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[490] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[491] = Alloc(2) returned 1000 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[491])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[490])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[492] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[492])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[493] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[494] = Alloc(3) returned 1003 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[495] = Alloc(7) returned 1062 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[496] = Alloc(9) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[494])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[495])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[497] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[497])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[498] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[498])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[499] = Alloc(4) returned 1037 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[499])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[500] = Alloc(2) returned 1000 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[501] = Alloc(6) returned 1025 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[502] = Alloc(9) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[503] = Alloc(3) returned 1003 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[504] = Alloc(9) returned -1 (searched 32 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[503])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[505] = Alloc(8) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[500])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[506] = Alloc(3) returned 1003 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[507] = Alloc(5) returned 1008 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[501])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[507])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[508] = Alloc(3) returned 1022 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[509] = Alloc(4) returned 1037 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[510] = Alloc(6) returned 1025 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[511] = Alloc(1) returned 1002 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[512] = Alloc(9) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[513] = Alloc(9) returned -1 (searched 30 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[508])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[511])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[506])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[514] = Alloc(10) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[515] = Alloc(9) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[510])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[509])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[516] = Alloc(2) returned 1000 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[516])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[517] = Alloc(2) returned 1000 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[518] = Alloc(1) returned 1002 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[517])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[518])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[519] = Alloc(3) returned 1003 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[520] = Alloc(4) returned 1037 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[521] = Alloc(8) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[519])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[522] = Alloc(3) returned 1003 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[523] = Alloc(9) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[520])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[524] = Alloc(5) returned 1008 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[524])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[525] = Alloc(7) returned 1062 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[522])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[526] = Alloc(7) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[527] = Alloc(10) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[525])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[528] = Alloc(5) returned 1008 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[528])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[529] = Alloc(4) returned 1037 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[530] = Alloc(5) returned 1008 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[531] = Alloc(3) returned 1003 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[531])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[532] = Alloc(7) returned 1062 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[533] = Alloc(6) returned 1025 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[532])
returned 0
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[533])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[529])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[534] = Alloc(6) returned 1025 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[534])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[530])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[535] = Alloc(4) returned 1037 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[536] = Alloc(5) returned 1008 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[535])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[536])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[537] = Alloc(1) returned 1002 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[538] = Alloc(2) returned 1000 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[539] = Alloc(8) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[540] = Alloc(9) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[537])
returned 0
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[541] = Alloc(10) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[542] = Alloc(9) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[543] = Alloc(10) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[544] = Alloc(7) returned 1062 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[544])
returned 0
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[545] = Alloc(9) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[546] = Alloc(5) returned 1008 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[547] = Alloc(4) returned 1037 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[547])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[546])
returned 0
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[548] = Alloc(6) returned 1025 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[549] = Alloc(3) returned 1003 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[538])
returned 0
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[550] = Alloc(2) returned 1000 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[549])
returned 0
Free List [ Size 33 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[550])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[548])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[551] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[552] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[552])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[553] = Alloc(4) returned 1037 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[553])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[554] = Alloc(2) returned 1000 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[554])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[555] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[556] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[557] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[558] = Alloc(2) returned 1000 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[559] = Alloc(8) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[558])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[560] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[561] = Alloc(8) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[562] = Alloc(7) returned 1062 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[563] = Alloc(8) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[564] = Alloc(8) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[562])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[565] = Alloc(1) returned 1002 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[566] = Alloc(8) returned -1 (searched 34 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[567] = Alloc(2) returned 1000 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[568] = Alloc(10) returned -1 (searched 33 elements)
Free List [ Size 33 ]: [ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[565])
returned 0
Free List [ Size 34 ]: [ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[567])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[569] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[569])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[570] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[571] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[572] = Alloc(6) returned 1053 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[571])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[572])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[573] = Alloc(9) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[574] = Alloc(10) returned -1 (searched 35 elements)
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[575] = Alloc(3) returned 1003 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[575])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[576] = Alloc(3) returned 1003 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[577] = Alloc(1) returned 1002 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[576])
returned 0
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[577])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[578] = Alloc(3) returned 1003 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[578])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[579] = Alloc(4) returned 1037 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[579])
returned 0
Free List [ Size 35 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1025 sz:6 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[580] = Alloc(6) returned 1025 (searched 35 elements)
Free List [ Size 34 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[581] = Alloc(4) returned 1037 (searched 34 elements)
Free List [ Size 33 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1044 sz:4 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[582] = Alloc(4) returned 1044 (searched 33 elements)
Free List [ Size 32 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[583] = Alloc(6) returned 1053 (searched 32 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1048 sz:4 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[584] = Alloc(4) returned 1048 (searched 31 elements)
Free List [ Size 30 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[585] = Alloc(5) returned 1008 (searched 30 elements)
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[586] = Alloc(5) returned 1016 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1003 sz:3 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[587] = Alloc(3) returned 1003 (searched 28 elements)
Free List [ Size 27 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[586])
returned 0
Free List [ Size 28 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[581])
returned 0
Free List [ Size 29 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[588] = Alloc(2) returned 1000 (searched 29 elements)
Free List [ Size 28 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1062 sz:7 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[589] = Alloc(6) returned 1062 (searched 28 elements)
Free List [ Size 28 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1068 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[585])
returned 0
Free List [ Size 29 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1068 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[583])
returned 0
Free List [ Size 30 ]: [ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1068 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

Free(ptr[588])
returned 0
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1068 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]

ptr[590] = Alloc(9) returned -1 (searched 31 elements)
Free List [ Size 31 ]: [ addr:1000 sz:2 ][ addr:1002 sz:1 ][ addr:1006 sz:1 ][ addr:1007 sz:1 ][ addr:1008 sz:5 ][ addr:1013 sz:1 ][ addr:1014 sz:1 ][ addr:1015 sz:1 ][ addr:1016 sz:5 ][ addr:1021 sz:1 ][ addr:1022 sz:3 ][ addr:1031 sz:1 ][ addr:1032 sz:2 ][ addr:1034 sz:3 ][ addr:1037 sz:4 ][ addr:1041 sz:1 ][ addr:1042 sz:2 ][ addr:1052 sz:1 ][ addr:1053 sz:6 ][ addr:1059 sz:2 ][ addr:1061 sz:1 ][ addr:1068 sz:1 ][ addr:1069 sz:3 ][ addr:1072 sz:5 ][ addr:1077 sz:3 ][ addr:1080 sz:1 ][ addr:1081 sz:5 ][ addr:1086 sz:3 ][ addr:1089 sz:5 ][ addr:1094 sz:2 ][ addr:1096 sz:4 ]
```

</details>
</br>

合并空闲列表（`-C`），几乎没有不可用的小块碎片，而且搜索次数大大减少。

<details>
  <summary>运行结果</summary>

```bash
./malloc.py -n 1000 -C -c

# 输出
seed 0
size 100
baseAddr 1000
headerSize 0
alignment -1
policy BEST
listOrder ADDRSORT
coalesce True
numOps 1000
range 10
percentAlloc 50
allocList 
compute True

ptr[0] = Alloc(3) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[0])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[1] = Alloc(5) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1005 sz:95 ]

Free(ptr[1])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[2] = Alloc(8) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1008 sz:92 ]

Free(ptr[2])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[3] = Alloc(8) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1008 sz:92 ]

Free(ptr[3])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[4] = Alloc(2) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1002 sz:98 ]

ptr[5] = Alloc(7) returned 1002 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1009 sz:91 ]

Free(ptr[5])
returned 0
Free List [ Size 1 ]: [ addr:1002 sz:98 ]

ptr[6] = Alloc(9) returned 1002 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1011 sz:89 ]

ptr[7] = Alloc(9) returned 1011 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1020 sz:80 ]

Free(ptr[4])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:2 ][ addr:1020 sz:80 ]

Free(ptr[6])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:11 ][ addr:1020 sz:80 ]

Free(ptr[7])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[8] = Alloc(5) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1005 sz:95 ]

Free(ptr[8])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[9] = Alloc(9) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1009 sz:91 ]

ptr[10] = Alloc(6) returned 1009 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1015 sz:85 ]

ptr[11] = Alloc(10) returned 1015 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1025 sz:75 ]

Free(ptr[10])
returned 0
Free List [ Size 2 ]: [ addr:1009 sz:6 ][ addr:1025 sz:75 ]

ptr[12] = Alloc(4) returned 1009 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1013 sz:2 ][ addr:1025 sz:75 ]

Free(ptr[12])
returned 0
Free List [ Size 2 ]: [ addr:1009 sz:6 ][ addr:1025 sz:75 ]

ptr[13] = Alloc(6) returned 1009 (searched 2 elements)
Free List [ Size 1 ]: [ addr:1025 sz:75 ]

Free(ptr[11])
returned 0
Free List [ Size 1 ]: [ addr:1015 sz:85 ]

Free(ptr[13])
returned 0
Free List [ Size 1 ]: [ addr:1009 sz:91 ]

Free(ptr[9])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[14] = Alloc(6) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1006 sz:94 ]

ptr[15] = Alloc(6) returned 1006 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1012 sz:88 ]

ptr[16] = Alloc(2) returned 1012 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1014 sz:86 ]

ptr[17] = Alloc(7) returned 1014 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1021 sz:79 ]

Free(ptr[15])
returned 0
Free List [ Size 2 ]: [ addr:1006 sz:6 ][ addr:1021 sz:79 ]

ptr[18] = Alloc(8) returned 1021 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1006 sz:6 ][ addr:1029 sz:71 ]

Free(ptr[18])
returned 0
Free List [ Size 2 ]: [ addr:1006 sz:6 ][ addr:1021 sz:79 ]

Free(ptr[17])
returned 0
Free List [ Size 2 ]: [ addr:1006 sz:6 ][ addr:1014 sz:86 ]

Free(ptr[16])
returned 0
Free List [ Size 1 ]: [ addr:1006 sz:94 ]

ptr[19] = Alloc(8) returned 1006 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1014 sz:86 ]

ptr[20] = Alloc(9) returned 1014 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1023 sz:77 ]

Free(ptr[20])
returned 0
Free List [ Size 1 ]: [ addr:1014 sz:86 ]

Free(ptr[19])
returned 0
Free List [ Size 1 ]: [ addr:1006 sz:94 ]

Free(ptr[14])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[21] = Alloc(7) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1007 sz:93 ]

ptr[22] = Alloc(7) returned 1007 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1014 sz:86 ]

Free(ptr[21])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:7 ][ addr:1014 sz:86 ]

Free(ptr[22])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[23] = Alloc(8) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1008 sz:92 ]

ptr[24] = Alloc(9) returned 1008 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1017 sz:83 ]

ptr[25] = Alloc(2) returned 1017 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1019 sz:81 ]

Free(ptr[23])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:8 ][ addr:1019 sz:81 ]

Free(ptr[25])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:8 ][ addr:1017 sz:83 ]

Free(ptr[24])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[26] = Alloc(7) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1007 sz:93 ]

Free(ptr[26])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[27] = Alloc(4) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1004 sz:96 ]

Free(ptr[27])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[28] = Alloc(10) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1010 sz:90 ]

ptr[29] = Alloc(2) returned 1010 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1012 sz:88 ]

ptr[30] = Alloc(9) returned 1012 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1021 sz:79 ]

Free(ptr[28])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:10 ][ addr:1021 sz:79 ]

ptr[31] = Alloc(2) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1002 sz:8 ][ addr:1021 sz:79 ]

ptr[32] = Alloc(3) returned 1002 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1005 sz:5 ][ addr:1021 sz:79 ]

Free(ptr[30])
returned 0
Free List [ Size 2 ]: [ addr:1005 sz:5 ][ addr:1012 sz:88 ]

ptr[33] = Alloc(6) returned 1012 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1005 sz:5 ][ addr:1018 sz:82 ]

ptr[34] = Alloc(2) returned 1005 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1007 sz:3 ][ addr:1018 sz:82 ]

Free(ptr[29])
returned 0
Free List [ Size 2 ]: [ addr:1007 sz:5 ][ addr:1018 sz:82 ]

ptr[35] = Alloc(8) returned 1018 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1007 sz:5 ][ addr:1026 sz:74 ]

Free(ptr[35])
returned 0
Free List [ Size 2 ]: [ addr:1007 sz:5 ][ addr:1018 sz:82 ]

ptr[36] = Alloc(7) returned 1018 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1007 sz:5 ][ addr:1025 sz:75 ]

Free(ptr[31])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:2 ][ addr:1007 sz:5 ][ addr:1025 sz:75 ]

Free(ptr[36])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:2 ][ addr:1007 sz:5 ][ addr:1018 sz:82 ]

ptr[37] = Alloc(3) returned 1007 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:2 ][ addr:1010 sz:2 ][ addr:1018 sz:82 ]

Free(ptr[33])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:2 ][ addr:1010 sz:90 ]

ptr[38] = Alloc(5) returned 1010 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:2 ][ addr:1015 sz:85 ]

ptr[39] = Alloc(6) returned 1015 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:2 ][ addr:1021 sz:79 ]

Free(ptr[34])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:2 ][ addr:1005 sz:2 ][ addr:1021 sz:79 ]

ptr[40] = Alloc(9) returned 1021 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:2 ][ addr:1005 sz:2 ][ addr:1030 sz:70 ]

ptr[41] = Alloc(6) returned 1030 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:2 ][ addr:1005 sz:2 ][ addr:1036 sz:64 ]

ptr[42] = Alloc(8) returned 1036 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:2 ][ addr:1005 sz:2 ][ addr:1044 sz:56 ]

ptr[43] = Alloc(1) returned 1000 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1001 sz:1 ][ addr:1005 sz:2 ][ addr:1044 sz:56 ]

ptr[44] = Alloc(3) returned 1044 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1001 sz:1 ][ addr:1005 sz:2 ][ addr:1047 sz:53 ]

Free(ptr[39])
returned 0
Free List [ Size 4 ]: [ addr:1001 sz:1 ][ addr:1005 sz:2 ][ addr:1015 sz:6 ][ addr:1047 sz:53 ]

ptr[45] = Alloc(4) returned 1015 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1001 sz:1 ][ addr:1005 sz:2 ][ addr:1019 sz:2 ][ addr:1047 sz:53 ]

Free(ptr[42])
returned 0
Free List [ Size 5 ]: [ addr:1001 sz:1 ][ addr:1005 sz:2 ][ addr:1019 sz:2 ][ addr:1036 sz:8 ][ addr:1047 sz:53 ]

Free(ptr[43])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:2 ][ addr:1005 sz:2 ][ addr:1019 sz:2 ][ addr:1036 sz:8 ][ addr:1047 sz:53 ]

ptr[46] = Alloc(5) returned 1036 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1000 sz:2 ][ addr:1005 sz:2 ][ addr:1019 sz:2 ][ addr:1041 sz:3 ][ addr:1047 sz:53 ]

Free(ptr[32])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:7 ][ addr:1019 sz:2 ][ addr:1041 sz:3 ][ addr:1047 sz:53 ]

ptr[47] = Alloc(4) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1004 sz:3 ][ addr:1019 sz:2 ][ addr:1041 sz:3 ][ addr:1047 sz:53 ]

ptr[48] = Alloc(7) returned 1047 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1004 sz:3 ][ addr:1019 sz:2 ][ addr:1041 sz:3 ][ addr:1054 sz:46 ]

ptr[49] = Alloc(9) returned 1054 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1004 sz:3 ][ addr:1019 sz:2 ][ addr:1041 sz:3 ][ addr:1063 sz:37 ]

Free(ptr[44])
returned 0
Free List [ Size 4 ]: [ addr:1004 sz:3 ][ addr:1019 sz:2 ][ addr:1041 sz:6 ][ addr:1063 sz:37 ]

ptr[50] = Alloc(8) returned 1063 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1004 sz:3 ][ addr:1019 sz:2 ][ addr:1041 sz:6 ][ addr:1071 sz:29 ]

ptr[51] = Alloc(7) returned 1071 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1004 sz:3 ][ addr:1019 sz:2 ][ addr:1041 sz:6 ][ addr:1078 sz:22 ]

ptr[52] = Alloc(5) returned 1041 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1004 sz:3 ][ addr:1019 sz:2 ][ addr:1046 sz:1 ][ addr:1078 sz:22 ]

ptr[53] = Alloc(2) returned 1019 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1004 sz:3 ][ addr:1046 sz:1 ][ addr:1078 sz:22 ]

Free(ptr[47])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:7 ][ addr:1046 sz:1 ][ addr:1078 sz:22 ]

Free(ptr[51])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:7 ][ addr:1046 sz:1 ][ addr:1071 sz:29 ]

Free(ptr[46])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:7 ][ addr:1036 sz:5 ][ addr:1046 sz:1 ][ addr:1071 sz:29 ]

ptr[54] = Alloc(5) returned 1036 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1000 sz:7 ][ addr:1046 sz:1 ][ addr:1071 sz:29 ]

Free(ptr[53])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:7 ][ addr:1019 sz:2 ][ addr:1046 sz:1 ][ addr:1071 sz:29 ]

Free(ptr[38])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:7 ][ addr:1010 sz:5 ][ addr:1019 sz:2 ][ addr:1046 sz:1 ][ addr:1071 sz:29 ]

Free(ptr[49])
returned 0
Free List [ Size 6 ]: [ addr:1000 sz:7 ][ addr:1010 sz:5 ][ addr:1019 sz:2 ][ addr:1046 sz:1 ][ addr:1054 sz:9 ][ addr:1071 sz:29 ]

ptr[55] = Alloc(8) returned 1054 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1000 sz:7 ][ addr:1010 sz:5 ][ addr:1019 sz:2 ][ addr:1046 sz:1 ][ addr:1062 sz:1 ][ addr:1071 sz:29 ]

Free(ptr[45])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:7 ][ addr:1010 sz:11 ][ addr:1046 sz:1 ][ addr:1062 sz:1 ][ addr:1071 sz:29 ]

Free(ptr[41])
returned 0
Free List [ Size 6 ]: [ addr:1000 sz:7 ][ addr:1010 sz:11 ][ addr:1030 sz:6 ][ addr:1046 sz:1 ][ addr:1062 sz:1 ][ addr:1071 sz:29 ]

ptr[56] = Alloc(8) returned 1010 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1000 sz:7 ][ addr:1018 sz:3 ][ addr:1030 sz:6 ][ addr:1046 sz:1 ][ addr:1062 sz:1 ][ addr:1071 sz:29 ]

ptr[57] = Alloc(9) returned 1071 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1000 sz:7 ][ addr:1018 sz:3 ][ addr:1030 sz:6 ][ addr:1046 sz:1 ][ addr:1062 sz:1 ][ addr:1080 sz:20 ]

Free(ptr[37])
returned 0
Free List [ Size 6 ]: [ addr:1000 sz:10 ][ addr:1018 sz:3 ][ addr:1030 sz:6 ][ addr:1046 sz:1 ][ addr:1062 sz:1 ][ addr:1080 sz:20 ]

ptr[58] = Alloc(7) returned 1000 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1007 sz:3 ][ addr:1018 sz:3 ][ addr:1030 sz:6 ][ addr:1046 sz:1 ][ addr:1062 sz:1 ][ addr:1080 sz:20 ]

Free(ptr[50])
returned 0
Free List [ Size 6 ]: [ addr:1007 sz:3 ][ addr:1018 sz:3 ][ addr:1030 sz:6 ][ addr:1046 sz:1 ][ addr:1062 sz:9 ][ addr:1080 sz:20 ]

Free(ptr[40])
returned 0
Free List [ Size 5 ]: [ addr:1007 sz:3 ][ addr:1018 sz:18 ][ addr:1046 sz:1 ][ addr:1062 sz:9 ][ addr:1080 sz:20 ]

Free(ptr[54])
returned 0
Free List [ Size 5 ]: [ addr:1007 sz:3 ][ addr:1018 sz:23 ][ addr:1046 sz:1 ][ addr:1062 sz:9 ][ addr:1080 sz:20 ]

ptr[59] = Alloc(3) returned 1007 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1018 sz:23 ][ addr:1046 sz:1 ][ addr:1062 sz:9 ][ addr:1080 sz:20 ]

ptr[60] = Alloc(8) returned 1062 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1018 sz:23 ][ addr:1046 sz:1 ][ addr:1070 sz:1 ][ addr:1080 sz:20 ]

Free(ptr[52])
returned 0
Free List [ Size 3 ]: [ addr:1018 sz:29 ][ addr:1070 sz:1 ][ addr:1080 sz:20 ]

Free(ptr[58])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:7 ][ addr:1018 sz:29 ][ addr:1070 sz:1 ][ addr:1080 sz:20 ]

ptr[61] = Alloc(9) returned 1080 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:7 ][ addr:1018 sz:29 ][ addr:1070 sz:1 ][ addr:1089 sz:11 ]

ptr[62] = Alloc(1) returned 1070 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1000 sz:7 ][ addr:1018 sz:29 ][ addr:1089 sz:11 ]

ptr[63] = Alloc(7) returned 1000 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1018 sz:29 ][ addr:1089 sz:11 ]

Free(ptr[63])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:7 ][ addr:1018 sz:29 ][ addr:1089 sz:11 ]

Free(ptr[62])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:7 ][ addr:1018 sz:29 ][ addr:1070 sz:1 ][ addr:1089 sz:11 ]

ptr[64] = Alloc(8) returned 1089 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:7 ][ addr:1018 sz:29 ][ addr:1070 sz:1 ][ addr:1097 sz:3 ]

Free(ptr[60])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:7 ][ addr:1018 sz:29 ][ addr:1062 sz:9 ][ addr:1097 sz:3 ]

Free(ptr[64])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:7 ][ addr:1018 sz:29 ][ addr:1062 sz:9 ][ addr:1089 sz:11 ]

Free(ptr[56])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:7 ][ addr:1010 sz:37 ][ addr:1062 sz:9 ][ addr:1089 sz:11 ]

Free(ptr[55])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:7 ][ addr:1010 sz:37 ][ addr:1054 sz:17 ][ addr:1089 sz:11 ]

Free(ptr[48])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:7 ][ addr:1010 sz:61 ][ addr:1089 sz:11 ]

ptr[65] = Alloc(4) returned 1000 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1004 sz:3 ][ addr:1010 sz:61 ][ addr:1089 sz:11 ]

Free(ptr[61])
returned 0
Free List [ Size 3 ]: [ addr:1004 sz:3 ][ addr:1010 sz:61 ][ addr:1080 sz:20 ]

ptr[66] = Alloc(7) returned 1080 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1004 sz:3 ][ addr:1010 sz:61 ][ addr:1087 sz:13 ]

ptr[67] = Alloc(2) returned 1004 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1006 sz:1 ][ addr:1010 sz:61 ][ addr:1087 sz:13 ]

Free(ptr[59])
returned 0
Free List [ Size 2 ]: [ addr:1006 sz:65 ][ addr:1087 sz:13 ]

ptr[68] = Alloc(6) returned 1087 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1006 sz:65 ][ addr:1093 sz:7 ]

ptr[69] = Alloc(5) returned 1093 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1006 sz:65 ][ addr:1098 sz:2 ]

ptr[70] = Alloc(1) returned 1098 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1006 sz:65 ][ addr:1099 sz:1 ]

ptr[71] = Alloc(6) returned 1006 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1012 sz:59 ][ addr:1099 sz:1 ]

ptr[72] = Alloc(5) returned 1012 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1017 sz:54 ][ addr:1099 sz:1 ]

ptr[73] = Alloc(5) returned 1017 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1022 sz:49 ][ addr:1099 sz:1 ]

ptr[74] = Alloc(10) returned 1022 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1032 sz:39 ][ addr:1099 sz:1 ]

ptr[75] = Alloc(9) returned 1032 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1041 sz:30 ][ addr:1099 sz:1 ]

Free(ptr[68])
returned 0
Free List [ Size 3 ]: [ addr:1041 sz:30 ][ addr:1087 sz:6 ][ addr:1099 sz:1 ]

ptr[76] = Alloc(7) returned 1041 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1048 sz:23 ][ addr:1087 sz:6 ][ addr:1099 sz:1 ]

ptr[77] = Alloc(4) returned 1087 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1048 sz:23 ][ addr:1091 sz:2 ][ addr:1099 sz:1 ]

Free(ptr[76])
returned 0
Free List [ Size 3 ]: [ addr:1041 sz:30 ][ addr:1091 sz:2 ][ addr:1099 sz:1 ]

Free(ptr[72])
returned 0
Free List [ Size 4 ]: [ addr:1012 sz:5 ][ addr:1041 sz:30 ][ addr:1091 sz:2 ][ addr:1099 sz:1 ]

ptr[78] = Alloc(10) returned 1041 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1012 sz:5 ][ addr:1051 sz:20 ][ addr:1091 sz:2 ][ addr:1099 sz:1 ]

Free(ptr[57])
returned 0
Free List [ Size 4 ]: [ addr:1012 sz:5 ][ addr:1051 sz:29 ][ addr:1091 sz:2 ][ addr:1099 sz:1 ]

ptr[79] = Alloc(8) returned 1051 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1012 sz:5 ][ addr:1059 sz:21 ][ addr:1091 sz:2 ][ addr:1099 sz:1 ]

ptr[80] = Alloc(1) returned 1099 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1012 sz:5 ][ addr:1059 sz:21 ][ addr:1091 sz:2 ]

ptr[81] = Alloc(6) returned 1059 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1012 sz:5 ][ addr:1065 sz:15 ][ addr:1091 sz:2 ]

ptr[82] = Alloc(5) returned 1012 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1065 sz:15 ][ addr:1091 sz:2 ]

Free(ptr[78])
returned 0
Free List [ Size 3 ]: [ addr:1041 sz:10 ][ addr:1065 sz:15 ][ addr:1091 sz:2 ]

ptr[83] = Alloc(4) returned 1041 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1045 sz:6 ][ addr:1065 sz:15 ][ addr:1091 sz:2 ]

Free(ptr[69])
returned 0
Free List [ Size 3 ]: [ addr:1045 sz:6 ][ addr:1065 sz:15 ][ addr:1091 sz:7 ]

Free(ptr[74])
returned 0
Free List [ Size 4 ]: [ addr:1022 sz:10 ][ addr:1045 sz:6 ][ addr:1065 sz:15 ][ addr:1091 sz:7 ]

ptr[84] = Alloc(1) returned 1045 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1022 sz:10 ][ addr:1046 sz:5 ][ addr:1065 sz:15 ][ addr:1091 sz:7 ]

Free(ptr[80])
returned 0
Free List [ Size 5 ]: [ addr:1022 sz:10 ][ addr:1046 sz:5 ][ addr:1065 sz:15 ][ addr:1091 sz:7 ][ addr:1099 sz:1 ]

Free(ptr[73])
returned 0
Free List [ Size 5 ]: [ addr:1017 sz:15 ][ addr:1046 sz:5 ][ addr:1065 sz:15 ][ addr:1091 sz:7 ][ addr:1099 sz:1 ]

Free(ptr[66])
returned 0
Free List [ Size 5 ]: [ addr:1017 sz:15 ][ addr:1046 sz:5 ][ addr:1065 sz:22 ][ addr:1091 sz:7 ][ addr:1099 sz:1 ]

ptr[85] = Alloc(3) returned 1046 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1017 sz:15 ][ addr:1049 sz:2 ][ addr:1065 sz:22 ][ addr:1091 sz:7 ][ addr:1099 sz:1 ]

ptr[86] = Alloc(10) returned 1017 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1027 sz:5 ][ addr:1049 sz:2 ][ addr:1065 sz:22 ][ addr:1091 sz:7 ][ addr:1099 sz:1 ]

ptr[87] = Alloc(2) returned 1049 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1027 sz:5 ][ addr:1065 sz:22 ][ addr:1091 sz:7 ][ addr:1099 sz:1 ]

ptr[88] = Alloc(4) returned 1027 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1031 sz:1 ][ addr:1065 sz:22 ][ addr:1091 sz:7 ][ addr:1099 sz:1 ]

Free(ptr[70])
returned 0
Free List [ Size 3 ]: [ addr:1031 sz:1 ][ addr:1065 sz:22 ][ addr:1091 sz:9 ]

Free(ptr[88])
returned 0
Free List [ Size 3 ]: [ addr:1027 sz:5 ][ addr:1065 sz:22 ][ addr:1091 sz:9 ]

ptr[89] = Alloc(5) returned 1027 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1065 sz:22 ][ addr:1091 sz:9 ]

Free(ptr[87])
returned 0
Free List [ Size 3 ]: [ addr:1049 sz:2 ][ addr:1065 sz:22 ][ addr:1091 sz:9 ]

ptr[90] = Alloc(10) returned 1065 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:9 ]

ptr[91] = Alloc(5) returned 1091 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1096 sz:4 ]

ptr[92] = Alloc(7) returned 1075 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1049 sz:2 ][ addr:1082 sz:5 ][ addr:1096 sz:4 ]

ptr[93] = Alloc(7) returned -1 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1049 sz:2 ][ addr:1082 sz:5 ][ addr:1096 sz:4 ]

ptr[94] = Alloc(4) returned 1096 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1049 sz:2 ][ addr:1082 sz:5 ]

Free(ptr[92])
returned 0
Free List [ Size 2 ]: [ addr:1049 sz:2 ][ addr:1075 sz:12 ]

Free(ptr[65])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:4 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ]

ptr[95] = Alloc(3) returned 1000 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1003 sz:1 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ]

Free(ptr[91])
returned 0
Free List [ Size 4 ]: [ addr:1003 sz:1 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

Free(ptr[86])
returned 0
Free List [ Size 5 ]: [ addr:1003 sz:1 ][ addr:1017 sz:10 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

Free(ptr[67])
returned 0
Free List [ Size 5 ]: [ addr:1003 sz:3 ][ addr:1017 sz:10 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

ptr[96] = Alloc(9) returned 1017 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1003 sz:3 ][ addr:1026 sz:1 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

ptr[97] = Alloc(3) returned 1003 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1026 sz:1 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

ptr[98] = Alloc(1) returned 1026 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

Free(ptr[82])
returned 0
Free List [ Size 4 ]: [ addr:1012 sz:5 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

ptr[99] = Alloc(2) returned 1049 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1012 sz:5 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

Free(ptr[99])
returned 0
Free List [ Size 4 ]: [ addr:1012 sz:5 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

Free(ptr[97])
returned 0
Free List [ Size 5 ]: [ addr:1003 sz:3 ][ addr:1012 sz:5 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

Free(ptr[89])
returned 0
Free List [ Size 6 ]: [ addr:1003 sz:3 ][ addr:1012 sz:5 ][ addr:1027 sz:5 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

Free(ptr[95])
returned 0
Free List [ Size 6 ]: [ addr:1000 sz:6 ][ addr:1012 sz:5 ][ addr:1027 sz:5 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

Free(ptr[98])
returned 0
Free List [ Size 6 ]: [ addr:1000 sz:6 ][ addr:1012 sz:5 ][ addr:1026 sz:6 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:5 ]

Free(ptr[94])
returned 0
Free List [ Size 6 ]: [ addr:1000 sz:6 ][ addr:1012 sz:5 ][ addr:1026 sz:6 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:9 ]

ptr[100] = Alloc(6) returned 1000 (searched 6 elements)
Free List [ Size 5 ]: [ addr:1012 sz:5 ][ addr:1026 sz:6 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:9 ]

Free(ptr[96])
returned 0
Free List [ Size 4 ]: [ addr:1012 sz:20 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1091 sz:9 ]

ptr[101] = Alloc(8) returned 1091 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1012 sz:20 ][ addr:1049 sz:2 ][ addr:1075 sz:12 ][ addr:1099 sz:1 ]

ptr[102] = Alloc(6) returned 1075 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1012 sz:20 ][ addr:1049 sz:2 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

Free(ptr[100])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:6 ][ addr:1012 sz:20 ][ addr:1049 sz:2 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

Free(ptr[71])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:32 ][ addr:1049 sz:2 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

ptr[103] = Alloc(6) returned 1081 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1000 sz:32 ][ addr:1049 sz:2 ][ addr:1099 sz:1 ]

ptr[104] = Alloc(1) returned 1099 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1000 sz:32 ][ addr:1049 sz:2 ]

Free(ptr[104])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:32 ][ addr:1049 sz:2 ][ addr:1099 sz:1 ]

ptr[105] = Alloc(5) returned 1000 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1005 sz:27 ][ addr:1049 sz:2 ][ addr:1099 sz:1 ]

Free(ptr[75])
returned 0
Free List [ Size 3 ]: [ addr:1005 sz:36 ][ addr:1049 sz:2 ][ addr:1099 sz:1 ]

Free(ptr[79])
returned 0
Free List [ Size 3 ]: [ addr:1005 sz:36 ][ addr:1049 sz:10 ][ addr:1099 sz:1 ]

ptr[106] = Alloc(9) returned 1049 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1005 sz:36 ][ addr:1058 sz:1 ][ addr:1099 sz:1 ]

ptr[107] = Alloc(1) returned 1058 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1005 sz:36 ][ addr:1099 sz:1 ]

ptr[108] = Alloc(5) returned 1005 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1010 sz:31 ][ addr:1099 sz:1 ]

Free(ptr[105])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:5 ][ addr:1010 sz:31 ][ addr:1099 sz:1 ]

Free(ptr[81])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:5 ][ addr:1010 sz:31 ][ addr:1059 sz:6 ][ addr:1099 sz:1 ]

Free(ptr[90])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:5 ][ addr:1010 sz:31 ][ addr:1059 sz:16 ][ addr:1099 sz:1 ]

Free(ptr[85])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:5 ][ addr:1010 sz:31 ][ addr:1046 sz:3 ][ addr:1059 sz:16 ][ addr:1099 sz:1 ]

ptr[109] = Alloc(5) returned 1000 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1010 sz:31 ][ addr:1046 sz:3 ][ addr:1059 sz:16 ][ addr:1099 sz:1 ]

ptr[110] = Alloc(1) returned 1099 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1010 sz:31 ][ addr:1046 sz:3 ][ addr:1059 sz:16 ]

Free(ptr[106])
returned 0
Free List [ Size 3 ]: [ addr:1010 sz:31 ][ addr:1046 sz:12 ][ addr:1059 sz:16 ]

ptr[111] = Alloc(6) returned 1046 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1010 sz:31 ][ addr:1052 sz:6 ][ addr:1059 sz:16 ]

ptr[112] = Alloc(4) returned 1052 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1010 sz:31 ][ addr:1056 sz:2 ][ addr:1059 sz:16 ]

Free(ptr[103])
returned 0
Free List [ Size 4 ]: [ addr:1010 sz:31 ][ addr:1056 sz:2 ][ addr:1059 sz:16 ][ addr:1081 sz:6 ]

Free(ptr[108])
returned 0
Free List [ Size 4 ]: [ addr:1005 sz:36 ][ addr:1056 sz:2 ][ addr:1059 sz:16 ][ addr:1081 sz:6 ]

ptr[113] = Alloc(7) returned 1059 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1005 sz:36 ][ addr:1056 sz:2 ][ addr:1066 sz:9 ][ addr:1081 sz:6 ]

ptr[114] = Alloc(2) returned 1056 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1005 sz:36 ][ addr:1066 sz:9 ][ addr:1081 sz:6 ]

Free(ptr[110])
returned 0
Free List [ Size 4 ]: [ addr:1005 sz:36 ][ addr:1066 sz:9 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

Free(ptr[83])
returned 0
Free List [ Size 4 ]: [ addr:1005 sz:40 ][ addr:1066 sz:9 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

Free(ptr[112])
returned 0
Free List [ Size 5 ]: [ addr:1005 sz:40 ][ addr:1052 sz:4 ][ addr:1066 sz:9 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

Free(ptr[113])
returned 0
Free List [ Size 5 ]: [ addr:1005 sz:40 ][ addr:1052 sz:4 ][ addr:1059 sz:16 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

Free(ptr[111])
returned 0
Free List [ Size 5 ]: [ addr:1005 sz:40 ][ addr:1046 sz:10 ][ addr:1059 sz:16 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

Free(ptr[109])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:45 ][ addr:1046 sz:10 ][ addr:1059 sz:16 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

ptr[115] = Alloc(8) returned 1046 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1000 sz:45 ][ addr:1054 sz:2 ][ addr:1059 sz:16 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

ptr[116] = Alloc(8) returned 1059 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1000 sz:45 ][ addr:1054 sz:2 ][ addr:1067 sz:8 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

ptr[117] = Alloc(8) returned 1067 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1000 sz:45 ][ addr:1054 sz:2 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

ptr[118] = Alloc(1) returned 1099 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1000 sz:45 ][ addr:1054 sz:2 ][ addr:1081 sz:6 ]

Free(ptr[107])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:45 ][ addr:1054 sz:2 ][ addr:1058 sz:1 ][ addr:1081 sz:6 ]

Free(ptr[118])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:45 ][ addr:1054 sz:2 ][ addr:1058 sz:1 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

Free(ptr[114])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:45 ][ addr:1054 sz:5 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

ptr[119] = Alloc(1) returned 1099 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1000 sz:45 ][ addr:1054 sz:5 ][ addr:1081 sz:6 ]

Free(ptr[119])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:45 ][ addr:1054 sz:5 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

Free(ptr[115])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:45 ][ addr:1046 sz:13 ][ addr:1081 sz:6 ][ addr:1099 sz:1 ]

ptr[120] = Alloc(4) returned 1081 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:45 ][ addr:1046 sz:13 ][ addr:1085 sz:2 ][ addr:1099 sz:1 ]

ptr[121] = Alloc(5) returned 1046 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:45 ][ addr:1051 sz:8 ][ addr:1085 sz:2 ][ addr:1099 sz:1 ]

Free(ptr[121])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:45 ][ addr:1046 sz:13 ][ addr:1085 sz:2 ][ addr:1099 sz:1 ]

Free(ptr[101])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:45 ][ addr:1046 sz:13 ][ addr:1085 sz:2 ][ addr:1091 sz:9 ]

ptr[122] = Alloc(8) returned 1091 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:45 ][ addr:1046 sz:13 ][ addr:1085 sz:2 ][ addr:1099 sz:1 ]

Free(ptr[77])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:45 ][ addr:1046 sz:13 ][ addr:1085 sz:6 ][ addr:1099 sz:1 ]

ptr[123] = Alloc(7) returned 1046 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:45 ][ addr:1053 sz:6 ][ addr:1085 sz:6 ][ addr:1099 sz:1 ]

ptr[124] = Alloc(10) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1010 sz:35 ][ addr:1053 sz:6 ][ addr:1085 sz:6 ][ addr:1099 sz:1 ]

Free(ptr[122])
returned 0
Free List [ Size 3 ]: [ addr:1010 sz:35 ][ addr:1053 sz:6 ][ addr:1085 sz:15 ]

ptr[125] = Alloc(1) returned 1053 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1010 sz:35 ][ addr:1054 sz:5 ][ addr:1085 sz:15 ]

ptr[126] = Alloc(1) returned 1054 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1010 sz:35 ][ addr:1055 sz:4 ][ addr:1085 sz:15 ]

ptr[127] = Alloc(1) returned 1055 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1010 sz:35 ][ addr:1056 sz:3 ][ addr:1085 sz:15 ]

Free(ptr[126])
returned 0
Free List [ Size 4 ]: [ addr:1010 sz:35 ][ addr:1054 sz:1 ][ addr:1056 sz:3 ][ addr:1085 sz:15 ]

ptr[128] = Alloc(9) returned 1085 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1010 sz:35 ][ addr:1054 sz:1 ][ addr:1056 sz:3 ][ addr:1094 sz:6 ]

ptr[129] = Alloc(3) returned 1056 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1010 sz:35 ][ addr:1054 sz:1 ][ addr:1094 sz:6 ]

Free(ptr[129])
returned 0
Free List [ Size 4 ]: [ addr:1010 sz:35 ][ addr:1054 sz:1 ][ addr:1056 sz:3 ][ addr:1094 sz:6 ]

ptr[130] = Alloc(1) returned 1054 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1010 sz:35 ][ addr:1056 sz:3 ][ addr:1094 sz:6 ]

ptr[131] = Alloc(1) returned 1056 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1010 sz:35 ][ addr:1057 sz:2 ][ addr:1094 sz:6 ]

Free(ptr[130])
returned 0
Free List [ Size 4 ]: [ addr:1010 sz:35 ][ addr:1054 sz:1 ][ addr:1057 sz:2 ][ addr:1094 sz:6 ]

ptr[132] = Alloc(2) returned 1057 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1010 sz:35 ][ addr:1054 sz:1 ][ addr:1094 sz:6 ]

ptr[133] = Alloc(10) returned 1010 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1020 sz:25 ][ addr:1054 sz:1 ][ addr:1094 sz:6 ]

ptr[134] = Alloc(10) returned 1020 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1030 sz:15 ][ addr:1054 sz:1 ][ addr:1094 sz:6 ]

ptr[135] = Alloc(5) returned 1094 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1030 sz:15 ][ addr:1054 sz:1 ][ addr:1099 sz:1 ]

ptr[136] = Alloc(10) returned 1030 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1040 sz:5 ][ addr:1054 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[131])
returned 0
Free List [ Size 4 ]: [ addr:1040 sz:5 ][ addr:1054 sz:1 ][ addr:1056 sz:1 ][ addr:1099 sz:1 ]

ptr[137] = Alloc(10) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1040 sz:5 ][ addr:1054 sz:1 ][ addr:1056 sz:1 ][ addr:1099 sz:1 ]

ptr[138] = Alloc(6) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1040 sz:5 ][ addr:1054 sz:1 ][ addr:1056 sz:1 ][ addr:1099 sz:1 ]

ptr[139] = Alloc(9) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1040 sz:5 ][ addr:1054 sz:1 ][ addr:1056 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[134])
returned 0
Free List [ Size 5 ]: [ addr:1020 sz:10 ][ addr:1040 sz:5 ][ addr:1054 sz:1 ][ addr:1056 sz:1 ][ addr:1099 sz:1 ]

ptr[140] = Alloc(3) returned 1040 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1020 sz:10 ][ addr:1043 sz:2 ][ addr:1054 sz:1 ][ addr:1056 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[120])
returned 0
Free List [ Size 6 ]: [ addr:1020 sz:10 ][ addr:1043 sz:2 ][ addr:1054 sz:1 ][ addr:1056 sz:1 ][ addr:1081 sz:4 ][ addr:1099 sz:1 ]

ptr[141] = Alloc(1) returned 1054 (searched 6 elements)
Free List [ Size 5 ]: [ addr:1020 sz:10 ][ addr:1043 sz:2 ][ addr:1056 sz:1 ][ addr:1081 sz:4 ][ addr:1099 sz:1 ]

ptr[142] = Alloc(1) returned 1056 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1020 sz:10 ][ addr:1043 sz:2 ][ addr:1081 sz:4 ][ addr:1099 sz:1 ]

ptr[143] = Alloc(1) returned 1099 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1020 sz:10 ][ addr:1043 sz:2 ][ addr:1081 sz:4 ]

ptr[144] = Alloc(6) returned 1020 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1026 sz:4 ][ addr:1043 sz:2 ][ addr:1081 sz:4 ]

Free(ptr[116])
returned 0
Free List [ Size 4 ]: [ addr:1026 sz:4 ][ addr:1043 sz:2 ][ addr:1059 sz:8 ][ addr:1081 sz:4 ]

ptr[145] = Alloc(7) returned 1059 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1026 sz:4 ][ addr:1043 sz:2 ][ addr:1066 sz:1 ][ addr:1081 sz:4 ]

ptr[146] = Alloc(5) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1026 sz:4 ][ addr:1043 sz:2 ][ addr:1066 sz:1 ][ addr:1081 sz:4 ]

ptr[147] = Alloc(10) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1026 sz:4 ][ addr:1043 sz:2 ][ addr:1066 sz:1 ][ addr:1081 sz:4 ]

ptr[148] = Alloc(5) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1026 sz:4 ][ addr:1043 sz:2 ][ addr:1066 sz:1 ][ addr:1081 sz:4 ]

ptr[149] = Alloc(8) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1026 sz:4 ][ addr:1043 sz:2 ][ addr:1066 sz:1 ][ addr:1081 sz:4 ]

ptr[150] = Alloc(3) returned 1026 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1029 sz:1 ][ addr:1043 sz:2 ][ addr:1066 sz:1 ][ addr:1081 sz:4 ]

ptr[151] = Alloc(5) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1029 sz:1 ][ addr:1043 sz:2 ][ addr:1066 sz:1 ][ addr:1081 sz:4 ]

Free(ptr[143])
returned 0
Free List [ Size 5 ]: [ addr:1029 sz:1 ][ addr:1043 sz:2 ][ addr:1066 sz:1 ][ addr:1081 sz:4 ][ addr:1099 sz:1 ]

ptr[152] = Alloc(6) returned -1 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1029 sz:1 ][ addr:1043 sz:2 ][ addr:1066 sz:1 ][ addr:1081 sz:4 ][ addr:1099 sz:1 ]

Free(ptr[142])
returned 0
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1043 sz:2 ][ addr:1056 sz:1 ][ addr:1066 sz:1 ][ addr:1081 sz:4 ][ addr:1099 sz:1 ]

ptr[153] = Alloc(4) returned 1081 (searched 6 elements)
Free List [ Size 5 ]: [ addr:1029 sz:1 ][ addr:1043 sz:2 ][ addr:1056 sz:1 ][ addr:1066 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[128])
returned 0
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1043 sz:2 ][ addr:1056 sz:1 ][ addr:1066 sz:1 ][ addr:1085 sz:9 ][ addr:1099 sz:1 ]

ptr[154] = Alloc(5) returned 1085 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1043 sz:2 ][ addr:1056 sz:1 ][ addr:1066 sz:1 ][ addr:1090 sz:4 ][ addr:1099 sz:1 ]

Free(ptr[117])
returned 0
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1043 sz:2 ][ addr:1056 sz:1 ][ addr:1066 sz:9 ][ addr:1090 sz:4 ][ addr:1099 sz:1 ]

ptr[155] = Alloc(7) returned 1066 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1043 sz:2 ][ addr:1056 sz:1 ][ addr:1073 sz:2 ][ addr:1090 sz:4 ][ addr:1099 sz:1 ]

ptr[156] = Alloc(3) returned 1090 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1043 sz:2 ][ addr:1056 sz:1 ][ addr:1073 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

ptr[157] = Alloc(7) returned -1 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1043 sz:2 ][ addr:1056 sz:1 ][ addr:1073 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[84])
returned 0
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1043 sz:3 ][ addr:1056 sz:1 ][ addr:1073 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

ptr[158] = Alloc(8) returned -1 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1043 sz:3 ][ addr:1056 sz:1 ][ addr:1073 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[140])
returned 0
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1040 sz:6 ][ addr:1056 sz:1 ][ addr:1073 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

ptr[159] = Alloc(8) returned -1 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1040 sz:6 ][ addr:1056 sz:1 ][ addr:1073 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

ptr[160] = Alloc(7) returned -1 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1040 sz:6 ][ addr:1056 sz:1 ][ addr:1073 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[125])
returned 0
Free List [ Size 7 ]: [ addr:1029 sz:1 ][ addr:1040 sz:6 ][ addr:1053 sz:1 ][ addr:1056 sz:1 ][ addr:1073 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[132])
returned 0
Free List [ Size 7 ]: [ addr:1029 sz:1 ][ addr:1040 sz:6 ][ addr:1053 sz:1 ][ addr:1056 sz:3 ][ addr:1073 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[123])
returned 0
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1040 sz:14 ][ addr:1056 sz:3 ][ addr:1073 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[102])
returned 0
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1040 sz:14 ][ addr:1056 sz:3 ][ addr:1073 sz:8 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

ptr[161] = Alloc(6) returned 1073 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1040 sz:14 ][ addr:1056 sz:3 ][ addr:1079 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[141])
returned 0
Free List [ Size 6 ]: [ addr:1029 sz:1 ][ addr:1040 sz:15 ][ addr:1056 sz:3 ][ addr:1079 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

ptr[162] = Alloc(3) returned 1056 (searched 6 elements)
Free List [ Size 5 ]: [ addr:1029 sz:1 ][ addr:1040 sz:15 ][ addr:1079 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

ptr[163] = Alloc(8) returned 1040 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1029 sz:1 ][ addr:1048 sz:7 ][ addr:1079 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[153])
returned 0
Free List [ Size 5 ]: [ addr:1029 sz:1 ][ addr:1048 sz:7 ][ addr:1079 sz:6 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

ptr[164] = Alloc(8) returned -1 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1029 sz:1 ][ addr:1048 sz:7 ][ addr:1079 sz:6 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

ptr[165] = Alloc(4) returned 1079 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1029 sz:1 ][ addr:1048 sz:7 ][ addr:1083 sz:2 ][ addr:1093 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[135])
returned 0
Free List [ Size 4 ]: [ addr:1029 sz:1 ][ addr:1048 sz:7 ][ addr:1083 sz:2 ][ addr:1093 sz:7 ]

Free(ptr[133])
returned 0
Free List [ Size 5 ]: [ addr:1010 sz:10 ][ addr:1029 sz:1 ][ addr:1048 sz:7 ][ addr:1083 sz:2 ][ addr:1093 sz:7 ]

ptr[166] = Alloc(3) returned 1048 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1010 sz:10 ][ addr:1029 sz:1 ][ addr:1051 sz:4 ][ addr:1083 sz:2 ][ addr:1093 sz:7 ]

Free(ptr[156])
returned 0
Free List [ Size 5 ]: [ addr:1010 sz:10 ][ addr:1029 sz:1 ][ addr:1051 sz:4 ][ addr:1083 sz:2 ][ addr:1090 sz:10 ]

Free(ptr[154])
returned 0
Free List [ Size 4 ]: [ addr:1010 sz:10 ][ addr:1029 sz:1 ][ addr:1051 sz:4 ][ addr:1083 sz:17 ]

ptr[167] = Alloc(7) returned 1010 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1017 sz:3 ][ addr:1029 sz:1 ][ addr:1051 sz:4 ][ addr:1083 sz:17 ]

ptr[168] = Alloc(8) returned 1083 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1017 sz:3 ][ addr:1029 sz:1 ][ addr:1051 sz:4 ][ addr:1091 sz:9 ]

Free(ptr[145])
returned 0
Free List [ Size 5 ]: [ addr:1017 sz:3 ][ addr:1029 sz:1 ][ addr:1051 sz:4 ][ addr:1059 sz:7 ][ addr:1091 sz:9 ]

ptr[169] = Alloc(7) returned 1059 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1017 sz:3 ][ addr:1029 sz:1 ][ addr:1051 sz:4 ][ addr:1091 sz:9 ]

ptr[170] = Alloc(7) returned 1091 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1017 sz:3 ][ addr:1029 sz:1 ][ addr:1051 sz:4 ][ addr:1098 sz:2 ]

ptr[171] = Alloc(6) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1017 sz:3 ][ addr:1029 sz:1 ][ addr:1051 sz:4 ][ addr:1098 sz:2 ]

ptr[172] = Alloc(7) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1017 sz:3 ][ addr:1029 sz:1 ][ addr:1051 sz:4 ][ addr:1098 sz:2 ]

ptr[173] = Alloc(5) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1017 sz:3 ][ addr:1029 sz:1 ][ addr:1051 sz:4 ][ addr:1098 sz:2 ]

ptr[174] = Alloc(5) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1017 sz:3 ][ addr:1029 sz:1 ][ addr:1051 sz:4 ][ addr:1098 sz:2 ]

Free(ptr[150])
returned 0
Free List [ Size 4 ]: [ addr:1017 sz:3 ][ addr:1026 sz:4 ][ addr:1051 sz:4 ][ addr:1098 sz:2 ]

Free(ptr[124])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:10 ][ addr:1017 sz:3 ][ addr:1026 sz:4 ][ addr:1051 sz:4 ][ addr:1098 sz:2 ]

ptr[175] = Alloc(8) returned 1000 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1008 sz:2 ][ addr:1017 sz:3 ][ addr:1026 sz:4 ][ addr:1051 sz:4 ][ addr:1098 sz:2 ]

ptr[176] = Alloc(7) returned -1 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1008 sz:2 ][ addr:1017 sz:3 ][ addr:1026 sz:4 ][ addr:1051 sz:4 ][ addr:1098 sz:2 ]

ptr[177] = Alloc(5) returned -1 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1008 sz:2 ][ addr:1017 sz:3 ][ addr:1026 sz:4 ][ addr:1051 sz:4 ][ addr:1098 sz:2 ]

Free(ptr[127])
returned 0
Free List [ Size 5 ]: [ addr:1008 sz:2 ][ addr:1017 sz:3 ][ addr:1026 sz:4 ][ addr:1051 sz:5 ][ addr:1098 sz:2 ]

Free(ptr[136])
returned 0
Free List [ Size 5 ]: [ addr:1008 sz:2 ][ addr:1017 sz:3 ][ addr:1026 sz:14 ][ addr:1051 sz:5 ][ addr:1098 sz:2 ]

Free(ptr[168])
returned 0
Free List [ Size 6 ]: [ addr:1008 sz:2 ][ addr:1017 sz:3 ][ addr:1026 sz:14 ][ addr:1051 sz:5 ][ addr:1083 sz:8 ][ addr:1098 sz:2 ]

Free(ptr[167])
returned 0
Free List [ Size 5 ]: [ addr:1008 sz:12 ][ addr:1026 sz:14 ][ addr:1051 sz:5 ][ addr:1083 sz:8 ][ addr:1098 sz:2 ]

ptr[178] = Alloc(1) returned 1098 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1008 sz:12 ][ addr:1026 sz:14 ][ addr:1051 sz:5 ][ addr:1083 sz:8 ][ addr:1099 sz:1 ]

Free(ptr[178])
returned 0
Free List [ Size 5 ]: [ addr:1008 sz:12 ][ addr:1026 sz:14 ][ addr:1051 sz:5 ][ addr:1083 sz:8 ][ addr:1098 sz:2 ]

Free(ptr[166])
returned 0
Free List [ Size 5 ]: [ addr:1008 sz:12 ][ addr:1026 sz:14 ][ addr:1048 sz:8 ][ addr:1083 sz:8 ][ addr:1098 sz:2 ]

Free(ptr[161])
returned 0
Free List [ Size 6 ]: [ addr:1008 sz:12 ][ addr:1026 sz:14 ][ addr:1048 sz:8 ][ addr:1073 sz:6 ][ addr:1083 sz:8 ][ addr:1098 sz:2 ]

Free(ptr[162])
returned 0
Free List [ Size 6 ]: [ addr:1008 sz:12 ][ addr:1026 sz:14 ][ addr:1048 sz:11 ][ addr:1073 sz:6 ][ addr:1083 sz:8 ][ addr:1098 sz:2 ]

ptr[179] = Alloc(5) returned 1073 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1008 sz:12 ][ addr:1026 sz:14 ][ addr:1048 sz:11 ][ addr:1078 sz:1 ][ addr:1083 sz:8 ][ addr:1098 sz:2 ]

ptr[180] = Alloc(2) returned 1098 (searched 6 elements)
Free List [ Size 5 ]: [ addr:1008 sz:12 ][ addr:1026 sz:14 ][ addr:1048 sz:11 ][ addr:1078 sz:1 ][ addr:1083 sz:8 ]

ptr[181] = Alloc(9) returned 1048 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1008 sz:12 ][ addr:1026 sz:14 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ][ addr:1083 sz:8 ]

ptr[182] = Alloc(5) returned 1083 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1008 sz:12 ][ addr:1026 sz:14 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ][ addr:1088 sz:3 ]

Free(ptr[170])
returned 0
Free List [ Size 5 ]: [ addr:1008 sz:12 ][ addr:1026 sz:14 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ][ addr:1088 sz:10 ]

ptr[183] = Alloc(10) returned 1088 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1008 sz:12 ][ addr:1026 sz:14 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ]

ptr[184] = Alloc(8) returned 1008 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1016 sz:4 ][ addr:1026 sz:14 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ]

ptr[185] = Alloc(9) returned 1026 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1016 sz:4 ][ addr:1035 sz:5 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ]

ptr[186] = Alloc(3) returned 1016 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1019 sz:1 ][ addr:1035 sz:5 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ]

ptr[187] = Alloc(10) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1019 sz:1 ][ addr:1035 sz:5 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ]

Free(ptr[144])
returned 0
Free List [ Size 4 ]: [ addr:1019 sz:7 ][ addr:1035 sz:5 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ]

ptr[188] = Alloc(3) returned 1035 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1019 sz:7 ][ addr:1038 sz:2 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ]

ptr[189] = Alloc(2) returned 1038 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1019 sz:7 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ]

ptr[190] = Alloc(7) returned 1019 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1057 sz:2 ][ addr:1078 sz:1 ]

ptr[191] = Alloc(7) returned -1 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1057 sz:2 ][ addr:1078 sz:1 ]

Free(ptr[185])
returned 0
Free List [ Size 3 ]: [ addr:1026 sz:9 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ]

Free(ptr[175])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:8 ][ addr:1026 sz:9 ][ addr:1057 sz:2 ][ addr:1078 sz:1 ]

Free(ptr[179])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:8 ][ addr:1026 sz:9 ][ addr:1057 sz:2 ][ addr:1073 sz:6 ]

ptr[192] = Alloc(7) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1007 sz:1 ][ addr:1026 sz:9 ][ addr:1057 sz:2 ][ addr:1073 sz:6 ]

Free(ptr[192])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:8 ][ addr:1026 sz:9 ][ addr:1057 sz:2 ][ addr:1073 sz:6 ]

Free(ptr[190])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:8 ][ addr:1019 sz:16 ][ addr:1057 sz:2 ][ addr:1073 sz:6 ]

Free(ptr[182])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:8 ][ addr:1019 sz:16 ][ addr:1057 sz:2 ][ addr:1073 sz:6 ][ addr:1083 sz:5 ]

ptr[193] = Alloc(8) returned 1000 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1019 sz:16 ][ addr:1057 sz:2 ][ addr:1073 sz:6 ][ addr:1083 sz:5 ]

ptr[194] = Alloc(3) returned 1083 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1019 sz:16 ][ addr:1057 sz:2 ][ addr:1073 sz:6 ][ addr:1086 sz:2 ]

ptr[195] = Alloc(2) returned 1057 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1019 sz:16 ][ addr:1073 sz:6 ][ addr:1086 sz:2 ]

ptr[196] = Alloc(7) returned 1019 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1026 sz:9 ][ addr:1073 sz:6 ][ addr:1086 sz:2 ]

ptr[197] = Alloc(8) returned 1026 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1034 sz:1 ][ addr:1073 sz:6 ][ addr:1086 sz:2 ]

Free(ptr[197])
returned 0
Free List [ Size 3 ]: [ addr:1026 sz:9 ][ addr:1073 sz:6 ][ addr:1086 sz:2 ]

ptr[198] = Alloc(10) returned -1 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1026 sz:9 ][ addr:1073 sz:6 ][ addr:1086 sz:2 ]

ptr[199] = Alloc(4) returned 1073 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1026 sz:9 ][ addr:1077 sz:2 ][ addr:1086 sz:2 ]

ptr[200] = Alloc(9) returned 1026 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1077 sz:2 ][ addr:1086 sz:2 ]

Free(ptr[181])
returned 0
Free List [ Size 3 ]: [ addr:1048 sz:9 ][ addr:1077 sz:2 ][ addr:1086 sz:2 ]

ptr[201] = Alloc(4) returned 1048 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1052 sz:5 ][ addr:1077 sz:2 ][ addr:1086 sz:2 ]

ptr[202] = Alloc(1) returned 1077 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1052 sz:5 ][ addr:1078 sz:1 ][ addr:1086 sz:2 ]

ptr[203] = Alloc(3) returned 1052 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1055 sz:2 ][ addr:1078 sz:1 ][ addr:1086 sz:2 ]

Free(ptr[169])
returned 0
Free List [ Size 4 ]: [ addr:1055 sz:2 ][ addr:1059 sz:7 ][ addr:1078 sz:1 ][ addr:1086 sz:2 ]

ptr[204] = Alloc(7) returned 1059 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1055 sz:2 ][ addr:1078 sz:1 ][ addr:1086 sz:2 ]

Free(ptr[184])
returned 0
Free List [ Size 4 ]: [ addr:1008 sz:8 ][ addr:1055 sz:2 ][ addr:1078 sz:1 ][ addr:1086 sz:2 ]

Free(ptr[183])
returned 0
Free List [ Size 4 ]: [ addr:1008 sz:8 ][ addr:1055 sz:2 ][ addr:1078 sz:1 ][ addr:1086 sz:12 ]

ptr[205] = Alloc(8) returned 1008 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1055 sz:2 ][ addr:1078 sz:1 ][ addr:1086 sz:12 ]

ptr[206] = Alloc(10) returned 1086 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1055 sz:2 ][ addr:1078 sz:1 ][ addr:1096 sz:2 ]

ptr[207] = Alloc(5) returned -1 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1055 sz:2 ][ addr:1078 sz:1 ][ addr:1096 sz:2 ]

Free(ptr[155])
returned 0
Free List [ Size 4 ]: [ addr:1055 sz:2 ][ addr:1066 sz:7 ][ addr:1078 sz:1 ][ addr:1096 sz:2 ]

Free(ptr[206])
returned 0
Free List [ Size 4 ]: [ addr:1055 sz:2 ][ addr:1066 sz:7 ][ addr:1078 sz:1 ][ addr:1086 sz:12 ]

ptr[208] = Alloc(2) returned 1055 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1066 sz:7 ][ addr:1078 sz:1 ][ addr:1086 sz:12 ]

ptr[209] = Alloc(1) returned 1078 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1066 sz:7 ][ addr:1086 sz:12 ]

Free(ptr[194])
returned 0
Free List [ Size 2 ]: [ addr:1066 sz:7 ][ addr:1083 sz:15 ]

Free(ptr[195])
returned 0
Free List [ Size 3 ]: [ addr:1057 sz:2 ][ addr:1066 sz:7 ][ addr:1083 sz:15 ]

ptr[210] = Alloc(5) returned 1066 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1057 sz:2 ][ addr:1071 sz:2 ][ addr:1083 sz:15 ]

Free(ptr[205])
returned 0
Free List [ Size 4 ]: [ addr:1008 sz:8 ][ addr:1057 sz:2 ][ addr:1071 sz:2 ][ addr:1083 sz:15 ]

ptr[211] = Alloc(2) returned 1057 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1008 sz:8 ][ addr:1071 sz:2 ][ addr:1083 sz:15 ]

ptr[212] = Alloc(2) returned 1071 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1008 sz:8 ][ addr:1083 sz:15 ]

Free(ptr[211])
returned 0
Free List [ Size 3 ]: [ addr:1008 sz:8 ][ addr:1057 sz:2 ][ addr:1083 sz:15 ]

ptr[213] = Alloc(5) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1013 sz:3 ][ addr:1057 sz:2 ][ addr:1083 sz:15 ]

Free(ptr[189])
returned 0
Free List [ Size 4 ]: [ addr:1013 sz:3 ][ addr:1038 sz:2 ][ addr:1057 sz:2 ][ addr:1083 sz:15 ]

Free(ptr[186])
returned 0
Free List [ Size 4 ]: [ addr:1013 sz:6 ][ addr:1038 sz:2 ][ addr:1057 sz:2 ][ addr:1083 sz:15 ]

ptr[214] = Alloc(5) returned 1013 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1018 sz:1 ][ addr:1038 sz:2 ][ addr:1057 sz:2 ][ addr:1083 sz:15 ]

Free(ptr[202])
returned 0
Free List [ Size 5 ]: [ addr:1018 sz:1 ][ addr:1038 sz:2 ][ addr:1057 sz:2 ][ addr:1077 sz:1 ][ addr:1083 sz:15 ]

ptr[215] = Alloc(3) returned 1083 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1018 sz:1 ][ addr:1038 sz:2 ][ addr:1057 sz:2 ][ addr:1077 sz:1 ][ addr:1086 sz:12 ]

ptr[216] = Alloc(8) returned 1086 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1018 sz:1 ][ addr:1038 sz:2 ][ addr:1057 sz:2 ][ addr:1077 sz:1 ][ addr:1094 sz:4 ]

ptr[217] = Alloc(8) returned -1 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1018 sz:1 ][ addr:1038 sz:2 ][ addr:1057 sz:2 ][ addr:1077 sz:1 ][ addr:1094 sz:4 ]

ptr[218] = Alloc(3) returned 1094 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1018 sz:1 ][ addr:1038 sz:2 ][ addr:1057 sz:2 ][ addr:1077 sz:1 ][ addr:1097 sz:1 ]

Free(ptr[210])
returned 0
Free List [ Size 6 ]: [ addr:1018 sz:1 ][ addr:1038 sz:2 ][ addr:1057 sz:2 ][ addr:1066 sz:5 ][ addr:1077 sz:1 ][ addr:1097 sz:1 ]

Free(ptr[203])
returned 0
Free List [ Size 7 ]: [ addr:1018 sz:1 ][ addr:1038 sz:2 ][ addr:1052 sz:3 ][ addr:1057 sz:2 ][ addr:1066 sz:5 ][ addr:1077 sz:1 ][ addr:1097 sz:1 ]

Free(ptr[180])
returned 0
Free List [ Size 7 ]: [ addr:1018 sz:1 ][ addr:1038 sz:2 ][ addr:1052 sz:3 ][ addr:1057 sz:2 ][ addr:1066 sz:5 ][ addr:1077 sz:1 ][ addr:1097 sz:3 ]

Free(ptr[188])
returned 0
Free List [ Size 7 ]: [ addr:1018 sz:1 ][ addr:1035 sz:5 ][ addr:1052 sz:3 ][ addr:1057 sz:2 ][ addr:1066 sz:5 ][ addr:1077 sz:1 ][ addr:1097 sz:3 ]

Free(ptr[200])
returned 0
Free List [ Size 7 ]: [ addr:1018 sz:1 ][ addr:1026 sz:14 ][ addr:1052 sz:3 ][ addr:1057 sz:2 ][ addr:1066 sz:5 ][ addr:1077 sz:1 ][ addr:1097 sz:3 ]

Free(ptr[213])
returned 0
Free List [ Size 8 ]: [ addr:1008 sz:5 ][ addr:1018 sz:1 ][ addr:1026 sz:14 ][ addr:1052 sz:3 ][ addr:1057 sz:2 ][ addr:1066 sz:5 ][ addr:1077 sz:1 ][ addr:1097 sz:3 ]

Free(ptr[196])
returned 0
Free List [ Size 7 ]: [ addr:1008 sz:5 ][ addr:1018 sz:22 ][ addr:1052 sz:3 ][ addr:1057 sz:2 ][ addr:1066 sz:5 ][ addr:1077 sz:1 ][ addr:1097 sz:3 ]

Free(ptr[199])
returned 0
Free List [ Size 7 ]: [ addr:1008 sz:5 ][ addr:1018 sz:22 ][ addr:1052 sz:3 ][ addr:1057 sz:2 ][ addr:1066 sz:5 ][ addr:1073 sz:5 ][ addr:1097 sz:3 ]

Free(ptr[214])
returned 0
Free List [ Size 6 ]: [ addr:1008 sz:32 ][ addr:1052 sz:3 ][ addr:1057 sz:2 ][ addr:1066 sz:5 ][ addr:1073 sz:5 ][ addr:1097 sz:3 ]

ptr[219] = Alloc(7) returned 1008 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1015 sz:25 ][ addr:1052 sz:3 ][ addr:1057 sz:2 ][ addr:1066 sz:5 ][ addr:1073 sz:5 ][ addr:1097 sz:3 ]

ptr[220] = Alloc(2) returned 1057 (searched 6 elements)
Free List [ Size 5 ]: [ addr:1015 sz:25 ][ addr:1052 sz:3 ][ addr:1066 sz:5 ][ addr:1073 sz:5 ][ addr:1097 sz:3 ]

Free(ptr[212])
returned 0
Free List [ Size 4 ]: [ addr:1015 sz:25 ][ addr:1052 sz:3 ][ addr:1066 sz:12 ][ addr:1097 sz:3 ]

ptr[221] = Alloc(6) returned 1066 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1015 sz:25 ][ addr:1052 sz:3 ][ addr:1072 sz:6 ][ addr:1097 sz:3 ]

ptr[222] = Alloc(2) returned 1052 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1015 sz:25 ][ addr:1054 sz:1 ][ addr:1072 sz:6 ][ addr:1097 sz:3 ]

ptr[223] = Alloc(10) returned 1015 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1025 sz:15 ][ addr:1054 sz:1 ][ addr:1072 sz:6 ][ addr:1097 sz:3 ]

Free(ptr[165])
returned 0
Free List [ Size 5 ]: [ addr:1025 sz:15 ][ addr:1054 sz:1 ][ addr:1072 sz:6 ][ addr:1079 sz:4 ][ addr:1097 sz:3 ]

Free(ptr[220])
returned 0
Free List [ Size 6 ]: [ addr:1025 sz:15 ][ addr:1054 sz:1 ][ addr:1057 sz:2 ][ addr:1072 sz:6 ][ addr:1079 sz:4 ][ addr:1097 sz:3 ]

Free(ptr[216])
returned 0
Free List [ Size 7 ]: [ addr:1025 sz:15 ][ addr:1054 sz:1 ][ addr:1057 sz:2 ][ addr:1072 sz:6 ][ addr:1079 sz:4 ][ addr:1086 sz:8 ][ addr:1097 sz:3 ]

Free(ptr[201])
returned 0
Free List [ Size 8 ]: [ addr:1025 sz:15 ][ addr:1048 sz:4 ][ addr:1054 sz:1 ][ addr:1057 sz:2 ][ addr:1072 sz:6 ][ addr:1079 sz:4 ][ addr:1086 sz:8 ][ addr:1097 sz:3 ]

Free(ptr[221])
returned 0
Free List [ Size 8 ]: [ addr:1025 sz:15 ][ addr:1048 sz:4 ][ addr:1054 sz:1 ][ addr:1057 sz:2 ][ addr:1066 sz:12 ][ addr:1079 sz:4 ][ addr:1086 sz:8 ][ addr:1097 sz:3 ]

Free(ptr[208])
returned 0
Free List [ Size 7 ]: [ addr:1025 sz:15 ][ addr:1048 sz:4 ][ addr:1054 sz:5 ][ addr:1066 sz:12 ][ addr:1079 sz:4 ][ addr:1086 sz:8 ][ addr:1097 sz:3 ]

Free(ptr[218])
returned 0
Free List [ Size 6 ]: [ addr:1025 sz:15 ][ addr:1048 sz:4 ][ addr:1054 sz:5 ][ addr:1066 sz:12 ][ addr:1079 sz:4 ][ addr:1086 sz:14 ]

Free(ptr[163])
returned 0
Free List [ Size 5 ]: [ addr:1025 sz:27 ][ addr:1054 sz:5 ][ addr:1066 sz:12 ][ addr:1079 sz:4 ][ addr:1086 sz:14 ]

Free(ptr[215])
returned 0
Free List [ Size 4 ]: [ addr:1025 sz:27 ][ addr:1054 sz:5 ][ addr:1066 sz:12 ][ addr:1079 sz:21 ]

ptr[224] = Alloc(5) returned 1054 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1025 sz:27 ][ addr:1066 sz:12 ][ addr:1079 sz:21 ]

ptr[225] = Alloc(3) returned 1066 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1025 sz:27 ][ addr:1069 sz:9 ][ addr:1079 sz:21 ]

Free(ptr[223])
returned 0
Free List [ Size 3 ]: [ addr:1015 sz:37 ][ addr:1069 sz:9 ][ addr:1079 sz:21 ]

ptr[226] = Alloc(10) returned 1079 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1015 sz:37 ][ addr:1069 sz:9 ][ addr:1089 sz:11 ]

ptr[227] = Alloc(4) returned 1069 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1015 sz:37 ][ addr:1073 sz:5 ][ addr:1089 sz:11 ]

Free(ptr[209])
returned 0
Free List [ Size 3 ]: [ addr:1015 sz:37 ][ addr:1073 sz:6 ][ addr:1089 sz:11 ]

Free(ptr[225])
returned 0
Free List [ Size 4 ]: [ addr:1015 sz:37 ][ addr:1066 sz:3 ][ addr:1073 sz:6 ][ addr:1089 sz:11 ]

Free(ptr[226])
returned 0
Free List [ Size 3 ]: [ addr:1015 sz:37 ][ addr:1066 sz:3 ][ addr:1073 sz:27 ]

ptr[228] = Alloc(1) returned 1066 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1015 sz:37 ][ addr:1067 sz:2 ][ addr:1073 sz:27 ]

ptr[229] = Alloc(8) returned 1073 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1015 sz:37 ][ addr:1067 sz:2 ][ addr:1081 sz:19 ]

Free(ptr[219])
returned 0
Free List [ Size 3 ]: [ addr:1008 sz:44 ][ addr:1067 sz:2 ][ addr:1081 sz:19 ]

ptr[230] = Alloc(8) returned 1081 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1008 sz:44 ][ addr:1067 sz:2 ][ addr:1089 sz:11 ]

Free(ptr[222])
returned 0
Free List [ Size 3 ]: [ addr:1008 sz:46 ][ addr:1067 sz:2 ][ addr:1089 sz:11 ]

Free(ptr[224])
returned 0
Free List [ Size 3 ]: [ addr:1008 sz:51 ][ addr:1067 sz:2 ][ addr:1089 sz:11 ]

ptr[231] = Alloc(6) returned 1089 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1008 sz:51 ][ addr:1067 sz:2 ][ addr:1095 sz:5 ]

Free(ptr[204])
returned 0
Free List [ Size 3 ]: [ addr:1008 sz:58 ][ addr:1067 sz:2 ][ addr:1095 sz:5 ]

ptr[232] = Alloc(7) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1015 sz:51 ][ addr:1067 sz:2 ][ addr:1095 sz:5 ]

ptr[233] = Alloc(1) returned 1067 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1015 sz:51 ][ addr:1068 sz:1 ][ addr:1095 sz:5 ]

ptr[234] = Alloc(7) returned 1015 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1022 sz:44 ][ addr:1068 sz:1 ][ addr:1095 sz:5 ]

ptr[235] = Alloc(1) returned 1068 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1022 sz:44 ][ addr:1095 sz:5 ]

Free(ptr[230])
returned 0
Free List [ Size 3 ]: [ addr:1022 sz:44 ][ addr:1081 sz:8 ][ addr:1095 sz:5 ]

Free(ptr[227])
returned 0
Free List [ Size 4 ]: [ addr:1022 sz:44 ][ addr:1069 sz:4 ][ addr:1081 sz:8 ][ addr:1095 sz:5 ]

ptr[236] = Alloc(4) returned 1069 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1022 sz:44 ][ addr:1081 sz:8 ][ addr:1095 sz:5 ]

ptr[237] = Alloc(4) returned 1095 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1022 sz:44 ][ addr:1081 sz:8 ][ addr:1099 sz:1 ]

Free(ptr[235])
returned 0
Free List [ Size 4 ]: [ addr:1022 sz:44 ][ addr:1068 sz:1 ][ addr:1081 sz:8 ][ addr:1099 sz:1 ]

ptr[238] = Alloc(5) returned 1081 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1022 sz:44 ][ addr:1068 sz:1 ][ addr:1086 sz:3 ][ addr:1099 sz:1 ]

ptr[239] = Alloc(6) returned 1022 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1028 sz:38 ][ addr:1068 sz:1 ][ addr:1086 sz:3 ][ addr:1099 sz:1 ]

Free(ptr[236])
returned 0
Free List [ Size 4 ]: [ addr:1028 sz:38 ][ addr:1068 sz:5 ][ addr:1086 sz:3 ][ addr:1099 sz:1 ]

ptr[240] = Alloc(1) returned 1099 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1028 sz:38 ][ addr:1068 sz:5 ][ addr:1086 sz:3 ]

Free(ptr[232])
returned 0
Free List [ Size 4 ]: [ addr:1008 sz:7 ][ addr:1028 sz:38 ][ addr:1068 sz:5 ][ addr:1086 sz:3 ]

ptr[241] = Alloc(1) returned 1086 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1008 sz:7 ][ addr:1028 sz:38 ][ addr:1068 sz:5 ][ addr:1087 sz:2 ]

ptr[242] = Alloc(9) returned 1028 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1008 sz:7 ][ addr:1037 sz:29 ][ addr:1068 sz:5 ][ addr:1087 sz:2 ]

Free(ptr[239])
returned 0
Free List [ Size 5 ]: [ addr:1008 sz:7 ][ addr:1022 sz:6 ][ addr:1037 sz:29 ][ addr:1068 sz:5 ][ addr:1087 sz:2 ]

ptr[243] = Alloc(4) returned 1068 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1008 sz:7 ][ addr:1022 sz:6 ][ addr:1037 sz:29 ][ addr:1072 sz:1 ][ addr:1087 sz:2 ]

Free(ptr[241])
returned 0
Free List [ Size 5 ]: [ addr:1008 sz:7 ][ addr:1022 sz:6 ][ addr:1037 sz:29 ][ addr:1072 sz:1 ][ addr:1086 sz:3 ]

ptr[244] = Alloc(1) returned 1072 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1008 sz:7 ][ addr:1022 sz:6 ][ addr:1037 sz:29 ][ addr:1086 sz:3 ]

Free(ptr[229])
returned 0
Free List [ Size 5 ]: [ addr:1008 sz:7 ][ addr:1022 sz:6 ][ addr:1037 sz:29 ][ addr:1073 sz:8 ][ addr:1086 sz:3 ]

Free(ptr[240])
returned 0
Free List [ Size 6 ]: [ addr:1008 sz:7 ][ addr:1022 sz:6 ][ addr:1037 sz:29 ][ addr:1073 sz:8 ][ addr:1086 sz:3 ][ addr:1099 sz:1 ]

ptr[245] = Alloc(1) returned 1099 (searched 6 elements)
Free List [ Size 5 ]: [ addr:1008 sz:7 ][ addr:1022 sz:6 ][ addr:1037 sz:29 ][ addr:1073 sz:8 ][ addr:1086 sz:3 ]

Free(ptr[238])
returned 0
Free List [ Size 4 ]: [ addr:1008 sz:7 ][ addr:1022 sz:6 ][ addr:1037 sz:29 ][ addr:1073 sz:16 ]

Free(ptr[234])
returned 0
Free List [ Size 3 ]: [ addr:1008 sz:20 ][ addr:1037 sz:29 ][ addr:1073 sz:16 ]

ptr[246] = Alloc(7) returned 1073 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1008 sz:20 ][ addr:1037 sz:29 ][ addr:1080 sz:9 ]

ptr[247] = Alloc(9) returned 1080 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1008 sz:20 ][ addr:1037 sz:29 ]

Free(ptr[193])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:28 ][ addr:1037 sz:29 ]

Free(ptr[228])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:28 ][ addr:1037 sz:30 ]

ptr[248] = Alloc(3) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1003 sz:25 ][ addr:1037 sz:30 ]

ptr[249] = Alloc(3) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1006 sz:22 ][ addr:1037 sz:30 ]

ptr[250] = Alloc(8) returned 1006 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1014 sz:14 ][ addr:1037 sz:30 ]

ptr[251] = Alloc(3) returned 1014 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1017 sz:11 ][ addr:1037 sz:30 ]

ptr[252] = Alloc(4) returned 1017 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1021 sz:7 ][ addr:1037 sz:30 ]

ptr[253] = Alloc(10) returned 1037 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1021 sz:7 ][ addr:1047 sz:20 ]

Free(ptr[253])
returned 0
Free List [ Size 2 ]: [ addr:1021 sz:7 ][ addr:1037 sz:30 ]

Free(ptr[246])
returned 0
Free List [ Size 3 ]: [ addr:1021 sz:7 ][ addr:1037 sz:30 ][ addr:1073 sz:7 ]

ptr[254] = Alloc(7) returned 1021 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1037 sz:30 ][ addr:1073 sz:7 ]

ptr[255] = Alloc(8) returned 1037 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1045 sz:22 ][ addr:1073 sz:7 ]

ptr[256] = Alloc(5) returned 1073 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1045 sz:22 ][ addr:1078 sz:2 ]

ptr[257] = Alloc(8) returned 1045 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1053 sz:14 ][ addr:1078 sz:2 ]

ptr[258] = Alloc(7) returned 1053 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1060 sz:7 ][ addr:1078 sz:2 ]

Free(ptr[254])
returned 0
Free List [ Size 3 ]: [ addr:1021 sz:7 ][ addr:1060 sz:7 ][ addr:1078 sz:2 ]

ptr[259] = Alloc(7) returned 1021 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1060 sz:7 ][ addr:1078 sz:2 ]

ptr[260] = Alloc(6) returned 1060 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1066 sz:1 ][ addr:1078 sz:2 ]

ptr[261] = Alloc(10) returned -1 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1066 sz:1 ][ addr:1078 sz:2 ]

Free(ptr[242])
returned 0
Free List [ Size 3 ]: [ addr:1028 sz:9 ][ addr:1066 sz:1 ][ addr:1078 sz:2 ]

Free(ptr[245])
returned 0
Free List [ Size 4 ]: [ addr:1028 sz:9 ][ addr:1066 sz:1 ][ addr:1078 sz:2 ][ addr:1099 sz:1 ]

Free(ptr[259])
returned 0
Free List [ Size 4 ]: [ addr:1021 sz:16 ][ addr:1066 sz:1 ][ addr:1078 sz:2 ][ addr:1099 sz:1 ]

Free(ptr[255])
returned 0
Free List [ Size 4 ]: [ addr:1021 sz:24 ][ addr:1066 sz:1 ][ addr:1078 sz:2 ][ addr:1099 sz:1 ]

Free(ptr[247])
returned 0
Free List [ Size 4 ]: [ addr:1021 sz:24 ][ addr:1066 sz:1 ][ addr:1078 sz:11 ][ addr:1099 sz:1 ]

Free(ptr[258])
returned 0
Free List [ Size 5 ]: [ addr:1021 sz:24 ][ addr:1053 sz:7 ][ addr:1066 sz:1 ][ addr:1078 sz:11 ][ addr:1099 sz:1 ]

ptr[262] = Alloc(8) returned 1078 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1021 sz:24 ][ addr:1053 sz:7 ][ addr:1066 sz:1 ][ addr:1086 sz:3 ][ addr:1099 sz:1 ]

ptr[263] = Alloc(9) returned 1021 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1030 sz:15 ][ addr:1053 sz:7 ][ addr:1066 sz:1 ][ addr:1086 sz:3 ][ addr:1099 sz:1 ]

Free(ptr[263])
returned 0
Free List [ Size 5 ]: [ addr:1021 sz:24 ][ addr:1053 sz:7 ][ addr:1066 sz:1 ][ addr:1086 sz:3 ][ addr:1099 sz:1 ]

ptr[264] = Alloc(7) returned 1053 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1021 sz:24 ][ addr:1066 sz:1 ][ addr:1086 sz:3 ][ addr:1099 sz:1 ]

ptr[265] = Alloc(8) returned 1021 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1029 sz:16 ][ addr:1066 sz:1 ][ addr:1086 sz:3 ][ addr:1099 sz:1 ]

Free(ptr[265])
returned 0
Free List [ Size 4 ]: [ addr:1021 sz:24 ][ addr:1066 sz:1 ][ addr:1086 sz:3 ][ addr:1099 sz:1 ]

ptr[266] = Alloc(2) returned 1086 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1021 sz:24 ][ addr:1066 sz:1 ][ addr:1088 sz:1 ][ addr:1099 sz:1 ]

ptr[267] = Alloc(2) returned 1021 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1023 sz:22 ][ addr:1066 sz:1 ][ addr:1088 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[267])
returned 0
Free List [ Size 4 ]: [ addr:1021 sz:24 ][ addr:1066 sz:1 ][ addr:1088 sz:1 ][ addr:1099 sz:1 ]

ptr[268] = Alloc(10) returned 1021 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1031 sz:14 ][ addr:1066 sz:1 ][ addr:1088 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[262])
returned 0
Free List [ Size 5 ]: [ addr:1031 sz:14 ][ addr:1066 sz:1 ][ addr:1078 sz:8 ][ addr:1088 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[243])
returned 0
Free List [ Size 6 ]: [ addr:1031 sz:14 ][ addr:1066 sz:1 ][ addr:1068 sz:4 ][ addr:1078 sz:8 ][ addr:1088 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[250])
returned 0
Free List [ Size 7 ]: [ addr:1006 sz:8 ][ addr:1031 sz:14 ][ addr:1066 sz:1 ][ addr:1068 sz:4 ][ addr:1078 sz:8 ][ addr:1088 sz:1 ][ addr:1099 sz:1 ]

Free(ptr[237])
returned 0
Free List [ Size 7 ]: [ addr:1006 sz:8 ][ addr:1031 sz:14 ][ addr:1066 sz:1 ][ addr:1068 sz:4 ][ addr:1078 sz:8 ][ addr:1088 sz:1 ][ addr:1095 sz:5 ]

ptr[269] = Alloc(7) returned 1006 (searched 7 elements)
Free List [ Size 7 ]: [ addr:1013 sz:1 ][ addr:1031 sz:14 ][ addr:1066 sz:1 ][ addr:1068 sz:4 ][ addr:1078 sz:8 ][ addr:1088 sz:1 ][ addr:1095 sz:5 ]

ptr[270] = Alloc(2) returned 1068 (searched 7 elements)
Free List [ Size 7 ]: [ addr:1013 sz:1 ][ addr:1031 sz:14 ][ addr:1066 sz:1 ][ addr:1070 sz:2 ][ addr:1078 sz:8 ][ addr:1088 sz:1 ][ addr:1095 sz:5 ]

Free(ptr[266])
returned 0
Free List [ Size 6 ]: [ addr:1013 sz:1 ][ addr:1031 sz:14 ][ addr:1066 sz:1 ][ addr:1070 sz:2 ][ addr:1078 sz:11 ][ addr:1095 sz:5 ]

Free(ptr[264])
returned 0
Free List [ Size 7 ]: [ addr:1013 sz:1 ][ addr:1031 sz:14 ][ addr:1053 sz:7 ][ addr:1066 sz:1 ][ addr:1070 sz:2 ][ addr:1078 sz:11 ][ addr:1095 sz:5 ]

ptr[271] = Alloc(3) returned 1095 (searched 7 elements)
Free List [ Size 7 ]: [ addr:1013 sz:1 ][ addr:1031 sz:14 ][ addr:1053 sz:7 ][ addr:1066 sz:1 ][ addr:1070 sz:2 ][ addr:1078 sz:11 ][ addr:1098 sz:2 ]

ptr[272] = Alloc(10) returned 1078 (searched 7 elements)
Free List [ Size 7 ]: [ addr:1013 sz:1 ][ addr:1031 sz:14 ][ addr:1053 sz:7 ][ addr:1066 sz:1 ][ addr:1070 sz:2 ][ addr:1088 sz:1 ][ addr:1098 sz:2 ]

Free(ptr[272])
returned 0
Free List [ Size 7 ]: [ addr:1013 sz:1 ][ addr:1031 sz:14 ][ addr:1053 sz:7 ][ addr:1066 sz:1 ][ addr:1070 sz:2 ][ addr:1078 sz:11 ][ addr:1098 sz:2 ]

Free(ptr[256])
returned 0
Free List [ Size 7 ]: [ addr:1013 sz:1 ][ addr:1031 sz:14 ][ addr:1053 sz:7 ][ addr:1066 sz:1 ][ addr:1070 sz:2 ][ addr:1073 sz:16 ][ addr:1098 sz:2 ]

Free(ptr[244])
returned 0
Free List [ Size 6 ]: [ addr:1013 sz:1 ][ addr:1031 sz:14 ][ addr:1053 sz:7 ][ addr:1066 sz:1 ][ addr:1070 sz:19 ][ addr:1098 sz:2 ]

Free(ptr[269])
returned 0
Free List [ Size 6 ]: [ addr:1006 sz:8 ][ addr:1031 sz:14 ][ addr:1053 sz:7 ][ addr:1066 sz:1 ][ addr:1070 sz:19 ][ addr:1098 sz:2 ]

Free(ptr[268])
returned 0
Free List [ Size 6 ]: [ addr:1006 sz:8 ][ addr:1021 sz:24 ][ addr:1053 sz:7 ][ addr:1066 sz:1 ][ addr:1070 sz:19 ][ addr:1098 sz:2 ]

ptr[273] = Alloc(7) returned 1053 (searched 6 elements)
Free List [ Size 5 ]: [ addr:1006 sz:8 ][ addr:1021 sz:24 ][ addr:1066 sz:1 ][ addr:1070 sz:19 ][ addr:1098 sz:2 ]

Free(ptr[257])
returned 0
Free List [ Size 5 ]: [ addr:1006 sz:8 ][ addr:1021 sz:32 ][ addr:1066 sz:1 ][ addr:1070 sz:19 ][ addr:1098 sz:2 ]

ptr[274] = Alloc(10) returned 1070 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1006 sz:8 ][ addr:1021 sz:32 ][ addr:1066 sz:1 ][ addr:1080 sz:9 ][ addr:1098 sz:2 ]

Free(ptr[251])
returned 0
Free List [ Size 5 ]: [ addr:1006 sz:11 ][ addr:1021 sz:32 ][ addr:1066 sz:1 ][ addr:1080 sz:9 ][ addr:1098 sz:2 ]

Free(ptr[273])
returned 0
Free List [ Size 5 ]: [ addr:1006 sz:11 ][ addr:1021 sz:39 ][ addr:1066 sz:1 ][ addr:1080 sz:9 ][ addr:1098 sz:2 ]

ptr[275] = Alloc(1) returned 1066 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1006 sz:11 ][ addr:1021 sz:39 ][ addr:1080 sz:9 ][ addr:1098 sz:2 ]

Free(ptr[275])
returned 0
Free List [ Size 5 ]: [ addr:1006 sz:11 ][ addr:1021 sz:39 ][ addr:1066 sz:1 ][ addr:1080 sz:9 ][ addr:1098 sz:2 ]

Free(ptr[260])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:11 ][ addr:1021 sz:46 ][ addr:1080 sz:9 ][ addr:1098 sz:2 ]

Free(ptr[249])
returned 0
Free List [ Size 4 ]: [ addr:1003 sz:14 ][ addr:1021 sz:46 ][ addr:1080 sz:9 ][ addr:1098 sz:2 ]

Free(ptr[233])
returned 0
Free List [ Size 4 ]: [ addr:1003 sz:14 ][ addr:1021 sz:47 ][ addr:1080 sz:9 ][ addr:1098 sz:2 ]

Free(ptr[248])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:17 ][ addr:1021 sz:47 ][ addr:1080 sz:9 ][ addr:1098 sz:2 ]

Free(ptr[274])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:17 ][ addr:1021 sz:47 ][ addr:1070 sz:19 ][ addr:1098 sz:2 ]

ptr[276] = Alloc(5) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1005 sz:12 ][ addr:1021 sz:47 ][ addr:1070 sz:19 ][ addr:1098 sz:2 ]

Free(ptr[270])
returned 0
Free List [ Size 3 ]: [ addr:1005 sz:12 ][ addr:1021 sz:68 ][ addr:1098 sz:2 ]

Free(ptr[276])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:17 ][ addr:1021 sz:68 ][ addr:1098 sz:2 ]

Free(ptr[271])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:17 ][ addr:1021 sz:68 ][ addr:1095 sz:5 ]

ptr[277] = Alloc(10) returned 1000 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1010 sz:7 ][ addr:1021 sz:68 ][ addr:1095 sz:5 ]

Free(ptr[252])
returned 0
Free List [ Size 2 ]: [ addr:1010 sz:79 ][ addr:1095 sz:5 ]

Free(ptr[231])
returned 0
Free List [ Size 1 ]: [ addr:1010 sz:90 ]

Free(ptr[277])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[278] = Alloc(1) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1001 sz:99 ]

ptr[279] = Alloc(3) returned 1001 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1004 sz:96 ]

Free(ptr[278])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:1 ][ addr:1004 sz:96 ]

Free(ptr[279])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[280] = Alloc(9) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1009 sz:91 ]

ptr[281] = Alloc(5) returned 1009 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1014 sz:86 ]

Free(ptr[280])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:9 ][ addr:1014 sz:86 ]

Free(ptr[281])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[282] = Alloc(5) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1005 sz:95 ]

Free(ptr[282])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[283] = Alloc(1) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1001 sz:99 ]

ptr[284] = Alloc(2) returned 1001 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

Free(ptr[283])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:1 ][ addr:1003 sz:97 ]

Free(ptr[284])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[285] = Alloc(10) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1010 sz:90 ]

Free(ptr[285])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[286] = Alloc(7) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1007 sz:93 ]

Free(ptr[286])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[287] = Alloc(1) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1001 sz:99 ]

ptr[288] = Alloc(2) returned 1001 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1003 sz:97 ]

ptr[289] = Alloc(7) returned 1003 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1010 sz:90 ]

Free(ptr[287])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:1 ][ addr:1010 sz:90 ]

Free(ptr[288])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:3 ][ addr:1010 sz:90 ]

Free(ptr[289])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[290] = Alloc(6) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1006 sz:94 ]

ptr[291] = Alloc(6) returned 1006 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1012 sz:88 ]

Free(ptr[290])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:6 ][ addr:1012 sz:88 ]

ptr[292] = Alloc(8) returned 1012 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:6 ][ addr:1020 sz:80 ]

ptr[293] = Alloc(3) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1003 sz:3 ][ addr:1020 sz:80 ]

Free(ptr[293])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:6 ][ addr:1020 sz:80 ]

ptr[294] = Alloc(10) returned 1020 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:6 ][ addr:1030 sz:70 ]

Free(ptr[291])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:12 ][ addr:1030 sz:70 ]

Free(ptr[294])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:12 ][ addr:1020 sz:80 ]

ptr[295] = Alloc(8) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1008 sz:4 ][ addr:1020 sz:80 ]

Free(ptr[292])
returned 0
Free List [ Size 1 ]: [ addr:1008 sz:92 ]

Free(ptr[295])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[296] = Alloc(5) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1005 sz:95 ]

ptr[297] = Alloc(4) returned 1005 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1009 sz:91 ]

Free(ptr[296])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:5 ][ addr:1009 sz:91 ]

Free(ptr[297])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[298] = Alloc(9) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1009 sz:91 ]

ptr[299] = Alloc(5) returned 1009 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1014 sz:86 ]

ptr[300] = Alloc(5) returned 1014 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1019 sz:81 ]

Free(ptr[299])
returned 0
Free List [ Size 2 ]: [ addr:1009 sz:5 ][ addr:1019 sz:81 ]

Free(ptr[300])
returned 0
Free List [ Size 1 ]: [ addr:1009 sz:91 ]

ptr[301] = Alloc(4) returned 1009 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1013 sz:87 ]

ptr[302] = Alloc(8) returned 1013 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1021 sz:79 ]

ptr[303] = Alloc(9) returned 1021 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1030 sz:70 ]

ptr[304] = Alloc(5) returned 1030 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1035 sz:65 ]

ptr[305] = Alloc(4) returned 1035 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1039 sz:61 ]

ptr[306] = Alloc(1) returned 1039 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1040 sz:60 ]

Free(ptr[304])
returned 0
Free List [ Size 2 ]: [ addr:1030 sz:5 ][ addr:1040 sz:60 ]

ptr[307] = Alloc(9) returned 1040 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1030 sz:5 ][ addr:1049 sz:51 ]

ptr[308] = Alloc(1) returned 1030 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1031 sz:4 ][ addr:1049 sz:51 ]

ptr[309] = Alloc(10) returned 1049 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1031 sz:4 ][ addr:1059 sz:41 ]

Free(ptr[307])
returned 0
Free List [ Size 3 ]: [ addr:1031 sz:4 ][ addr:1040 sz:9 ][ addr:1059 sz:41 ]

Free(ptr[308])
returned 0
Free List [ Size 3 ]: [ addr:1030 sz:5 ][ addr:1040 sz:9 ][ addr:1059 sz:41 ]

ptr[310] = Alloc(1) returned 1030 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1031 sz:4 ][ addr:1040 sz:9 ][ addr:1059 sz:41 ]

Free(ptr[301])
returned 0
Free List [ Size 4 ]: [ addr:1009 sz:4 ][ addr:1031 sz:4 ][ addr:1040 sz:9 ][ addr:1059 sz:41 ]

ptr[311] = Alloc(4) returned 1009 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1031 sz:4 ][ addr:1040 sz:9 ][ addr:1059 sz:41 ]

ptr[312] = Alloc(4) returned 1031 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1040 sz:9 ][ addr:1059 sz:41 ]

ptr[313] = Alloc(7) returned 1040 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1047 sz:2 ][ addr:1059 sz:41 ]

Free(ptr[298])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:9 ][ addr:1047 sz:2 ][ addr:1059 sz:41 ]

ptr[314] = Alloc(6) returned 1000 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1006 sz:3 ][ addr:1047 sz:2 ][ addr:1059 sz:41 ]

Free(ptr[309])
returned 0
Free List [ Size 2 ]: [ addr:1006 sz:3 ][ addr:1047 sz:53 ]

ptr[315] = Alloc(1) returned 1006 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1007 sz:2 ][ addr:1047 sz:53 ]

Free(ptr[313])
returned 0
Free List [ Size 2 ]: [ addr:1007 sz:2 ][ addr:1040 sz:60 ]

Free(ptr[305])
returned 0
Free List [ Size 3 ]: [ addr:1007 sz:2 ][ addr:1035 sz:4 ][ addr:1040 sz:60 ]

Free(ptr[302])
returned 0
Free List [ Size 4 ]: [ addr:1007 sz:2 ][ addr:1013 sz:8 ][ addr:1035 sz:4 ][ addr:1040 sz:60 ]

Free(ptr[310])
returned 0
Free List [ Size 5 ]: [ addr:1007 sz:2 ][ addr:1013 sz:8 ][ addr:1030 sz:1 ][ addr:1035 sz:4 ][ addr:1040 sz:60 ]

Free(ptr[311])
returned 0
Free List [ Size 4 ]: [ addr:1007 sz:14 ][ addr:1030 sz:1 ][ addr:1035 sz:4 ][ addr:1040 sz:60 ]

ptr[316] = Alloc(10) returned 1007 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1017 sz:4 ][ addr:1030 sz:1 ][ addr:1035 sz:4 ][ addr:1040 sz:60 ]

Free(ptr[306])
returned 0
Free List [ Size 3 ]: [ addr:1017 sz:4 ][ addr:1030 sz:1 ][ addr:1035 sz:65 ]

ptr[317] = Alloc(4) returned 1017 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1030 sz:1 ][ addr:1035 sz:65 ]

ptr[318] = Alloc(6) returned 1035 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1030 sz:1 ][ addr:1041 sz:59 ]

ptr[319] = Alloc(2) returned 1041 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1030 sz:1 ][ addr:1043 sz:57 ]

Free(ptr[317])
returned 0
Free List [ Size 3 ]: [ addr:1017 sz:4 ][ addr:1030 sz:1 ][ addr:1043 sz:57 ]

ptr[320] = Alloc(9) returned 1043 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1017 sz:4 ][ addr:1030 sz:1 ][ addr:1052 sz:48 ]

Free(ptr[320])
returned 0
Free List [ Size 3 ]: [ addr:1017 sz:4 ][ addr:1030 sz:1 ][ addr:1043 sz:57 ]

ptr[321] = Alloc(9) returned 1043 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1017 sz:4 ][ addr:1030 sz:1 ][ addr:1052 sz:48 ]

Free(ptr[303])
returned 0
Free List [ Size 2 ]: [ addr:1017 sz:14 ][ addr:1052 sz:48 ]

ptr[322] = Alloc(3) returned 1017 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1020 sz:11 ][ addr:1052 sz:48 ]

ptr[323] = Alloc(3) returned 1020 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1023 sz:8 ][ addr:1052 sz:48 ]

ptr[324] = Alloc(9) returned 1052 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1023 sz:8 ][ addr:1061 sz:39 ]

ptr[325] = Alloc(9) returned 1061 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1023 sz:8 ][ addr:1070 sz:30 ]

ptr[326] = Alloc(6) returned 1023 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1029 sz:2 ][ addr:1070 sz:30 ]

ptr[327] = Alloc(10) returned 1070 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1029 sz:2 ][ addr:1080 sz:20 ]

ptr[328] = Alloc(4) returned 1080 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1029 sz:2 ][ addr:1084 sz:16 ]

Free(ptr[328])
returned 0
Free List [ Size 2 ]: [ addr:1029 sz:2 ][ addr:1080 sz:20 ]

ptr[329] = Alloc(9) returned 1080 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1029 sz:2 ][ addr:1089 sz:11 ]

Free(ptr[312])
returned 0
Free List [ Size 2 ]: [ addr:1029 sz:6 ][ addr:1089 sz:11 ]

Free(ptr[315])
returned 0
Free List [ Size 3 ]: [ addr:1006 sz:1 ][ addr:1029 sz:6 ][ addr:1089 sz:11 ]

Free(ptr[326])
returned 0
Free List [ Size 3 ]: [ addr:1006 sz:1 ][ addr:1023 sz:12 ][ addr:1089 sz:11 ]

Free(ptr[321])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1023 sz:12 ][ addr:1043 sz:9 ][ addr:1089 sz:11 ]

ptr[330] = Alloc(5) returned 1043 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1023 sz:12 ][ addr:1048 sz:4 ][ addr:1089 sz:11 ]

Free(ptr[319])
returned 0
Free List [ Size 5 ]: [ addr:1006 sz:1 ][ addr:1023 sz:12 ][ addr:1041 sz:2 ][ addr:1048 sz:4 ][ addr:1089 sz:11 ]

ptr[331] = Alloc(2) returned 1041 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1023 sz:12 ][ addr:1048 sz:4 ][ addr:1089 sz:11 ]

Free(ptr[324])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1023 sz:12 ][ addr:1048 sz:13 ][ addr:1089 sz:11 ]

ptr[332] = Alloc(5) returned 1089 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1023 sz:12 ][ addr:1048 sz:13 ][ addr:1094 sz:6 ]

Free(ptr[332])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1023 sz:12 ][ addr:1048 sz:13 ][ addr:1089 sz:11 ]

ptr[333] = Alloc(5) returned 1089 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1023 sz:12 ][ addr:1048 sz:13 ][ addr:1094 sz:6 ]

ptr[334] = Alloc(3) returned 1094 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1023 sz:12 ][ addr:1048 sz:13 ][ addr:1097 sz:3 ]

ptr[335] = Alloc(7) returned 1023 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1030 sz:5 ][ addr:1048 sz:13 ][ addr:1097 sz:3 ]

ptr[336] = Alloc(6) returned 1048 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1030 sz:5 ][ addr:1054 sz:7 ][ addr:1097 sz:3 ]

Free(ptr[336])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1030 sz:5 ][ addr:1048 sz:13 ][ addr:1097 sz:3 ]

Free(ptr[323])
returned 0
Free List [ Size 5 ]: [ addr:1006 sz:1 ][ addr:1020 sz:3 ][ addr:1030 sz:5 ][ addr:1048 sz:13 ][ addr:1097 sz:3 ]

ptr[337] = Alloc(7) returned 1048 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1006 sz:1 ][ addr:1020 sz:3 ][ addr:1030 sz:5 ][ addr:1055 sz:6 ][ addr:1097 sz:3 ]

ptr[338] = Alloc(3) returned 1020 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1030 sz:5 ][ addr:1055 sz:6 ][ addr:1097 sz:3 ]

ptr[339] = Alloc(4) returned 1030 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1034 sz:1 ][ addr:1055 sz:6 ][ addr:1097 sz:3 ]

Free(ptr[339])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1030 sz:5 ][ addr:1055 sz:6 ][ addr:1097 sz:3 ]

ptr[340] = Alloc(9) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1030 sz:5 ][ addr:1055 sz:6 ][ addr:1097 sz:3 ]

ptr[341] = Alloc(8) returned -1 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1030 sz:5 ][ addr:1055 sz:6 ][ addr:1097 sz:3 ]

ptr[342] = Alloc(5) returned 1030 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1006 sz:1 ][ addr:1055 sz:6 ][ addr:1097 sz:3 ]

Free(ptr[327])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1055 sz:6 ][ addr:1070 sz:10 ][ addr:1097 sz:3 ]

Free(ptr[334])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1055 sz:6 ][ addr:1070 sz:10 ][ addr:1094 sz:6 ]

Free(ptr[318])
returned 0
Free List [ Size 5 ]: [ addr:1006 sz:1 ][ addr:1035 sz:6 ][ addr:1055 sz:6 ][ addr:1070 sz:10 ][ addr:1094 sz:6 ]

ptr[343] = Alloc(5) returned 1035 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1006 sz:1 ][ addr:1040 sz:1 ][ addr:1055 sz:6 ][ addr:1070 sz:10 ][ addr:1094 sz:6 ]

Free(ptr[343])
returned 0
Free List [ Size 5 ]: [ addr:1006 sz:1 ][ addr:1035 sz:6 ][ addr:1055 sz:6 ][ addr:1070 sz:10 ][ addr:1094 sz:6 ]

ptr[344] = Alloc(6) returned 1035 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1055 sz:6 ][ addr:1070 sz:10 ][ addr:1094 sz:6 ]

Free(ptr[329])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1055 sz:6 ][ addr:1070 sz:19 ][ addr:1094 sz:6 ]

Free(ptr[338])
returned 0
Free List [ Size 5 ]: [ addr:1006 sz:1 ][ addr:1020 sz:3 ][ addr:1055 sz:6 ][ addr:1070 sz:19 ][ addr:1094 sz:6 ]

Free(ptr[337])
returned 0
Free List [ Size 5 ]: [ addr:1006 sz:1 ][ addr:1020 sz:3 ][ addr:1048 sz:13 ][ addr:1070 sz:19 ][ addr:1094 sz:6 ]

ptr[345] = Alloc(10) returned 1048 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1006 sz:1 ][ addr:1020 sz:3 ][ addr:1058 sz:3 ][ addr:1070 sz:19 ][ addr:1094 sz:6 ]

ptr[346] = Alloc(6) returned 1094 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1020 sz:3 ][ addr:1058 sz:3 ][ addr:1070 sz:19 ]

ptr[347] = Alloc(7) returned 1070 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1020 sz:3 ][ addr:1058 sz:3 ][ addr:1077 sz:12 ]

ptr[348] = Alloc(5) returned 1077 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1020 sz:3 ][ addr:1058 sz:3 ][ addr:1082 sz:7 ]

Free(ptr[325])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1020 sz:3 ][ addr:1058 sz:12 ][ addr:1082 sz:7 ]

Free(ptr[331])
returned 0
Free List [ Size 5 ]: [ addr:1006 sz:1 ][ addr:1020 sz:3 ][ addr:1041 sz:2 ][ addr:1058 sz:12 ][ addr:1082 sz:7 ]

ptr[349] = Alloc(7) returned 1082 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1020 sz:3 ][ addr:1041 sz:2 ][ addr:1058 sz:12 ]

ptr[350] = Alloc(5) returned 1058 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1020 sz:3 ][ addr:1041 sz:2 ][ addr:1063 sz:7 ]

ptr[351] = Alloc(1) returned 1006 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1020 sz:3 ][ addr:1041 sz:2 ][ addr:1063 sz:7 ]

Free(ptr[347])
returned 0
Free List [ Size 3 ]: [ addr:1020 sz:3 ][ addr:1041 sz:2 ][ addr:1063 sz:14 ]

Free(ptr[344])
returned 0
Free List [ Size 3 ]: [ addr:1020 sz:3 ][ addr:1035 sz:8 ][ addr:1063 sz:14 ]

Free(ptr[322])
returned 0
Free List [ Size 3 ]: [ addr:1017 sz:6 ][ addr:1035 sz:8 ][ addr:1063 sz:14 ]

ptr[352] = Alloc(3) returned 1017 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1020 sz:3 ][ addr:1035 sz:8 ][ addr:1063 sz:14 ]

Free(ptr[350])
returned 0
Free List [ Size 3 ]: [ addr:1020 sz:3 ][ addr:1035 sz:8 ][ addr:1058 sz:19 ]

ptr[353] = Alloc(9) returned 1058 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1020 sz:3 ][ addr:1035 sz:8 ][ addr:1067 sz:10 ]

Free(ptr[349])
returned 0
Free List [ Size 4 ]: [ addr:1020 sz:3 ][ addr:1035 sz:8 ][ addr:1067 sz:10 ][ addr:1082 sz:7 ]

ptr[354] = Alloc(2) returned 1020 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1022 sz:1 ][ addr:1035 sz:8 ][ addr:1067 sz:10 ][ addr:1082 sz:7 ]

Free(ptr[353])
returned 0
Free List [ Size 4 ]: [ addr:1022 sz:1 ][ addr:1035 sz:8 ][ addr:1058 sz:19 ][ addr:1082 sz:7 ]

ptr[355] = Alloc(9) returned 1058 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1022 sz:1 ][ addr:1035 sz:8 ][ addr:1067 sz:10 ][ addr:1082 sz:7 ]

Free(ptr[335])
returned 0
Free List [ Size 4 ]: [ addr:1022 sz:8 ][ addr:1035 sz:8 ][ addr:1067 sz:10 ][ addr:1082 sz:7 ]

Free(ptr[333])
returned 0
Free List [ Size 4 ]: [ addr:1022 sz:8 ][ addr:1035 sz:8 ][ addr:1067 sz:10 ][ addr:1082 sz:12 ]

Free(ptr[355])
returned 0
Free List [ Size 4 ]: [ addr:1022 sz:8 ][ addr:1035 sz:8 ][ addr:1058 sz:19 ][ addr:1082 sz:12 ]

Free(ptr[351])
returned 0
Free List [ Size 5 ]: [ addr:1006 sz:1 ][ addr:1022 sz:8 ][ addr:1035 sz:8 ][ addr:1058 sz:19 ][ addr:1082 sz:12 ]

ptr[356] = Alloc(9) returned 1082 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1006 sz:1 ][ addr:1022 sz:8 ][ addr:1035 sz:8 ][ addr:1058 sz:19 ][ addr:1091 sz:3 ]

Free(ptr[342])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1022 sz:21 ][ addr:1058 sz:19 ][ addr:1091 sz:3 ]

Free(ptr[346])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1022 sz:21 ][ addr:1058 sz:19 ][ addr:1091 sz:9 ]

Free(ptr[356])
returned 0
Free List [ Size 4 ]: [ addr:1006 sz:1 ][ addr:1022 sz:21 ][ addr:1058 sz:19 ][ addr:1082 sz:18 ]

Free(ptr[348])
returned 0
Free List [ Size 3 ]: [ addr:1006 sz:1 ][ addr:1022 sz:21 ][ addr:1058 sz:42 ]

ptr[357] = Alloc(1) returned 1006 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1022 sz:21 ][ addr:1058 sz:42 ]

Free(ptr[352])
returned 0
Free List [ Size 3 ]: [ addr:1017 sz:3 ][ addr:1022 sz:21 ][ addr:1058 sz:42 ]

Free(ptr[345])
returned 0
Free List [ Size 3 ]: [ addr:1017 sz:3 ][ addr:1022 sz:21 ][ addr:1048 sz:52 ]

Free(ptr[354])
returned 0
Free List [ Size 2 ]: [ addr:1017 sz:26 ][ addr:1048 sz:52 ]

ptr[358] = Alloc(7) returned 1017 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1024 sz:19 ][ addr:1048 sz:52 ]

Free(ptr[314])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:6 ][ addr:1024 sz:19 ][ addr:1048 sz:52 ]

Free(ptr[357])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:7 ][ addr:1024 sz:19 ][ addr:1048 sz:52 ]

ptr[359] = Alloc(8) returned 1024 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:7 ][ addr:1032 sz:11 ][ addr:1048 sz:52 ]

ptr[360] = Alloc(9) returned 1032 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:7 ][ addr:1041 sz:2 ][ addr:1048 sz:52 ]

Free(ptr[358])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:7 ][ addr:1017 sz:7 ][ addr:1041 sz:2 ][ addr:1048 sz:52 ]

ptr[361] = Alloc(5) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1005 sz:2 ][ addr:1017 sz:7 ][ addr:1041 sz:2 ][ addr:1048 sz:52 ]

Free(ptr[330])
returned 0
Free List [ Size 3 ]: [ addr:1005 sz:2 ][ addr:1017 sz:7 ][ addr:1041 sz:59 ]

ptr[362] = Alloc(8) returned 1041 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1005 sz:2 ][ addr:1017 sz:7 ][ addr:1049 sz:51 ]

Free(ptr[360])
returned 0
Free List [ Size 4 ]: [ addr:1005 sz:2 ][ addr:1017 sz:7 ][ addr:1032 sz:9 ][ addr:1049 sz:51 ]

Free(ptr[316])
returned 0
Free List [ Size 3 ]: [ addr:1005 sz:19 ][ addr:1032 sz:9 ][ addr:1049 sz:51 ]

Free(ptr[362])
returned 0
Free List [ Size 2 ]: [ addr:1005 sz:19 ][ addr:1032 sz:68 ]

ptr[363] = Alloc(9) returned 1005 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1014 sz:10 ][ addr:1032 sz:68 ]

Free(ptr[363])
returned 0
Free List [ Size 2 ]: [ addr:1005 sz:19 ][ addr:1032 sz:68 ]

Free(ptr[361])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:24 ][ addr:1032 sz:68 ]

ptr[364] = Alloc(8) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1008 sz:16 ][ addr:1032 sz:68 ]

ptr[365] = Alloc(1) returned 1008 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1009 sz:15 ][ addr:1032 sz:68 ]

ptr[366] = Alloc(4) returned 1009 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1013 sz:11 ][ addr:1032 sz:68 ]

Free(ptr[365])
returned 0
Free List [ Size 3 ]: [ addr:1008 sz:1 ][ addr:1013 sz:11 ][ addr:1032 sz:68 ]

Free(ptr[366])
returned 0
Free List [ Size 2 ]: [ addr:1008 sz:16 ][ addr:1032 sz:68 ]

ptr[367] = Alloc(6) returned 1008 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1014 sz:10 ][ addr:1032 sz:68 ]

ptr[368] = Alloc(6) returned 1014 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1020 sz:4 ][ addr:1032 sz:68 ]

ptr[369] = Alloc(5) returned 1032 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1020 sz:4 ][ addr:1037 sz:63 ]

ptr[370] = Alloc(9) returned 1037 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1020 sz:4 ][ addr:1046 sz:54 ]

ptr[371] = Alloc(7) returned 1046 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1020 sz:4 ][ addr:1053 sz:47 ]

ptr[372] = Alloc(2) returned 1020 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1022 sz:2 ][ addr:1053 sz:47 ]

Free(ptr[364])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:8 ][ addr:1022 sz:2 ][ addr:1053 sz:47 ]

Free(ptr[371])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:8 ][ addr:1022 sz:2 ][ addr:1046 sz:54 ]

ptr[373] = Alloc(1) returned 1022 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:8 ][ addr:1023 sz:1 ][ addr:1046 sz:54 ]

ptr[374] = Alloc(4) returned 1000 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1004 sz:4 ][ addr:1023 sz:1 ][ addr:1046 sz:54 ]

Free(ptr[370])
returned 0
Free List [ Size 3 ]: [ addr:1004 sz:4 ][ addr:1023 sz:1 ][ addr:1037 sz:63 ]

ptr[375] = Alloc(3) returned 1004 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1007 sz:1 ][ addr:1023 sz:1 ][ addr:1037 sz:63 ]

ptr[376] = Alloc(2) returned 1037 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1007 sz:1 ][ addr:1023 sz:1 ][ addr:1039 sz:61 ]

Free(ptr[367])
returned 0
Free List [ Size 3 ]: [ addr:1007 sz:7 ][ addr:1023 sz:1 ][ addr:1039 sz:61 ]

Free(ptr[375])
returned 0
Free List [ Size 3 ]: [ addr:1004 sz:10 ][ addr:1023 sz:1 ][ addr:1039 sz:61 ]

ptr[377] = Alloc(6) returned 1004 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1010 sz:4 ][ addr:1023 sz:1 ][ addr:1039 sz:61 ]

ptr[378] = Alloc(9) returned 1039 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1010 sz:4 ][ addr:1023 sz:1 ][ addr:1048 sz:52 ]

Free(ptr[376])
returned 0
Free List [ Size 4 ]: [ addr:1010 sz:4 ][ addr:1023 sz:1 ][ addr:1037 sz:2 ][ addr:1048 sz:52 ]

ptr[379] = Alloc(7) returned 1048 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1010 sz:4 ][ addr:1023 sz:1 ][ addr:1037 sz:2 ][ addr:1055 sz:45 ]

Free(ptr[374])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:4 ][ addr:1010 sz:4 ][ addr:1023 sz:1 ][ addr:1037 sz:2 ][ addr:1055 sz:45 ]

Free(ptr[369])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:4 ][ addr:1010 sz:4 ][ addr:1023 sz:1 ][ addr:1032 sz:7 ][ addr:1055 sz:45 ]

ptr[380] = Alloc(1) returned 1023 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1000 sz:4 ][ addr:1010 sz:4 ][ addr:1032 sz:7 ][ addr:1055 sz:45 ]

ptr[381] = Alloc(9) returned 1055 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:4 ][ addr:1010 sz:4 ][ addr:1032 sz:7 ][ addr:1064 sz:36 ]

ptr[382] = Alloc(3) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1003 sz:1 ][ addr:1010 sz:4 ][ addr:1032 sz:7 ][ addr:1064 sz:36 ]

ptr[383] = Alloc(10) returned 1064 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1003 sz:1 ][ addr:1010 sz:4 ][ addr:1032 sz:7 ][ addr:1074 sz:26 ]

Free(ptr[373])
returned 0
Free List [ Size 5 ]: [ addr:1003 sz:1 ][ addr:1010 sz:4 ][ addr:1022 sz:1 ][ addr:1032 sz:7 ][ addr:1074 sz:26 ]

ptr[384] = Alloc(6) returned 1032 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1003 sz:1 ][ addr:1010 sz:4 ][ addr:1022 sz:1 ][ addr:1038 sz:1 ][ addr:1074 sz:26 ]

ptr[385] = Alloc(4) returned 1010 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1003 sz:1 ][ addr:1022 sz:1 ][ addr:1038 sz:1 ][ addr:1074 sz:26 ]

ptr[386] = Alloc(8) returned 1074 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1003 sz:1 ][ addr:1022 sz:1 ][ addr:1038 sz:1 ][ addr:1082 sz:18 ]

ptr[387] = Alloc(10) returned 1082 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1003 sz:1 ][ addr:1022 sz:1 ][ addr:1038 sz:1 ][ addr:1092 sz:8 ]

Free(ptr[380])
returned 0
Free List [ Size 4 ]: [ addr:1003 sz:1 ][ addr:1022 sz:2 ][ addr:1038 sz:1 ][ addr:1092 sz:8 ]

Free(ptr[378])
returned 0
Free List [ Size 4 ]: [ addr:1003 sz:1 ][ addr:1022 sz:2 ][ addr:1038 sz:10 ][ addr:1092 sz:8 ]

ptr[388] = Alloc(2) returned 1022 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1003 sz:1 ][ addr:1038 sz:10 ][ addr:1092 sz:8 ]

Free(ptr[381])
returned 0
Free List [ Size 4 ]: [ addr:1003 sz:1 ][ addr:1038 sz:10 ][ addr:1055 sz:9 ][ addr:1092 sz:8 ]

Free(ptr[382])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:4 ][ addr:1038 sz:10 ][ addr:1055 sz:9 ][ addr:1092 sz:8 ]

Free(ptr[379])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:4 ][ addr:1038 sz:26 ][ addr:1092 sz:8 ]

Free(ptr[383])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:4 ][ addr:1038 sz:36 ][ addr:1092 sz:8 ]

ptr[389] = Alloc(5) returned 1092 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:4 ][ addr:1038 sz:36 ][ addr:1097 sz:3 ]

Free(ptr[389])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:4 ][ addr:1038 sz:36 ][ addr:1092 sz:8 ]

Free(ptr[384])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:4 ][ addr:1032 sz:42 ][ addr:1092 sz:8 ]

ptr[390] = Alloc(5) returned 1092 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:4 ][ addr:1032 sz:42 ][ addr:1097 sz:3 ]

ptr[391] = Alloc(3) returned 1097 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1000 sz:4 ][ addr:1032 sz:42 ]

ptr[392] = Alloc(10) returned 1032 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:4 ][ addr:1042 sz:32 ]

ptr[393] = Alloc(2) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1002 sz:2 ][ addr:1042 sz:32 ]

ptr[394] = Alloc(4) returned 1042 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1002 sz:2 ][ addr:1046 sz:28 ]

Free(ptr[394])
returned 0
Free List [ Size 2 ]: [ addr:1002 sz:2 ][ addr:1042 sz:32 ]

Free(ptr[387])
returned 0
Free List [ Size 3 ]: [ addr:1002 sz:2 ][ addr:1042 sz:32 ][ addr:1082 sz:10 ]

Free(ptr[390])
returned 0
Free List [ Size 3 ]: [ addr:1002 sz:2 ][ addr:1042 sz:32 ][ addr:1082 sz:15 ]

Free(ptr[385])
returned 0
Free List [ Size 4 ]: [ addr:1002 sz:2 ][ addr:1010 sz:4 ][ addr:1042 sz:32 ][ addr:1082 sz:15 ]

ptr[395] = Alloc(7) returned 1082 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1002 sz:2 ][ addr:1010 sz:4 ][ addr:1042 sz:32 ][ addr:1089 sz:8 ]

ptr[396] = Alloc(4) returned 1010 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1002 sz:2 ][ addr:1042 sz:32 ][ addr:1089 sz:8 ]

Free(ptr[372])
returned 0
Free List [ Size 4 ]: [ addr:1002 sz:2 ][ addr:1020 sz:2 ][ addr:1042 sz:32 ][ addr:1089 sz:8 ]

Free(ptr[396])
returned 0
Free List [ Size 5 ]: [ addr:1002 sz:2 ][ addr:1010 sz:4 ][ addr:1020 sz:2 ][ addr:1042 sz:32 ][ addr:1089 sz:8 ]

Free(ptr[359])
returned 0
Free List [ Size 6 ]: [ addr:1002 sz:2 ][ addr:1010 sz:4 ][ addr:1020 sz:2 ][ addr:1024 sz:8 ][ addr:1042 sz:32 ][ addr:1089 sz:8 ]

ptr[397] = Alloc(3) returned 1010 (searched 6 elements)
Free List [ Size 6 ]: [ addr:1002 sz:2 ][ addr:1013 sz:1 ][ addr:1020 sz:2 ][ addr:1024 sz:8 ][ addr:1042 sz:32 ][ addr:1089 sz:8 ]

ptr[398] = Alloc(2) returned 1002 (searched 6 elements)
Free List [ Size 5 ]: [ addr:1013 sz:1 ][ addr:1020 sz:2 ][ addr:1024 sz:8 ][ addr:1042 sz:32 ][ addr:1089 sz:8 ]

Free(ptr[388])
returned 0
Free List [ Size 4 ]: [ addr:1013 sz:1 ][ addr:1020 sz:12 ][ addr:1042 sz:32 ][ addr:1089 sz:8 ]

ptr[399] = Alloc(1) returned 1013 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1020 sz:12 ][ addr:1042 sz:32 ][ addr:1089 sz:8 ]

ptr[400] = Alloc(1) returned 1089 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1020 sz:12 ][ addr:1042 sz:32 ][ addr:1090 sz:7 ]

ptr[401] = Alloc(7) returned 1090 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1020 sz:12 ][ addr:1042 sz:32 ]

Free(ptr[386])
returned 0
Free List [ Size 2 ]: [ addr:1020 sz:12 ][ addr:1042 sz:40 ]

Free(ptr[391])
returned 0
Free List [ Size 3 ]: [ addr:1020 sz:12 ][ addr:1042 sz:40 ][ addr:1097 sz:3 ]

ptr[402] = Alloc(9) returned 1020 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1029 sz:3 ][ addr:1042 sz:40 ][ addr:1097 sz:3 ]

Free(ptr[368])
returned 0
Free List [ Size 4 ]: [ addr:1014 sz:6 ][ addr:1029 sz:3 ][ addr:1042 sz:40 ][ addr:1097 sz:3 ]

ptr[403] = Alloc(3) returned 1029 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1014 sz:6 ][ addr:1042 sz:40 ][ addr:1097 sz:3 ]

Free(ptr[397])
returned 0
Free List [ Size 4 ]: [ addr:1010 sz:3 ][ addr:1014 sz:6 ][ addr:1042 sz:40 ][ addr:1097 sz:3 ]

Free(ptr[398])
returned 0
Free List [ Size 5 ]: [ addr:1002 sz:2 ][ addr:1010 sz:3 ][ addr:1014 sz:6 ][ addr:1042 sz:40 ][ addr:1097 sz:3 ]

ptr[404] = Alloc(8) returned 1042 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1002 sz:2 ][ addr:1010 sz:3 ][ addr:1014 sz:6 ][ addr:1050 sz:32 ][ addr:1097 sz:3 ]

Free(ptr[393])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:4 ][ addr:1010 sz:3 ][ addr:1014 sz:6 ][ addr:1050 sz:32 ][ addr:1097 sz:3 ]

Free(ptr[402])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:4 ][ addr:1010 sz:3 ][ addr:1014 sz:15 ][ addr:1050 sz:32 ][ addr:1097 sz:3 ]

Free(ptr[401])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:4 ][ addr:1010 sz:3 ][ addr:1014 sz:15 ][ addr:1050 sz:32 ][ addr:1090 sz:10 ]

Free(ptr[400])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:4 ][ addr:1010 sz:3 ][ addr:1014 sz:15 ][ addr:1050 sz:32 ][ addr:1089 sz:11 ]

ptr[405] = Alloc(10) returned 1089 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1000 sz:4 ][ addr:1010 sz:3 ][ addr:1014 sz:15 ][ addr:1050 sz:32 ][ addr:1099 sz:1 ]

Free(ptr[392])
returned 0
Free List [ Size 6 ]: [ addr:1000 sz:4 ][ addr:1010 sz:3 ][ addr:1014 sz:15 ][ addr:1032 sz:10 ][ addr:1050 sz:32 ][ addr:1099 sz:1 ]

Free(ptr[403])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:4 ][ addr:1010 sz:3 ][ addr:1014 sz:28 ][ addr:1050 sz:32 ][ addr:1099 sz:1 ]

Free(ptr[395])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:4 ][ addr:1010 sz:3 ][ addr:1014 sz:28 ][ addr:1050 sz:39 ][ addr:1099 sz:1 ]

Free(ptr[404])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:4 ][ addr:1010 sz:3 ][ addr:1014 sz:75 ][ addr:1099 sz:1 ]

ptr[406] = Alloc(6) returned 1014 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:4 ][ addr:1010 sz:3 ][ addr:1020 sz:69 ][ addr:1099 sz:1 ]

ptr[407] = Alloc(2) returned 1010 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:4 ][ addr:1012 sz:1 ][ addr:1020 sz:69 ][ addr:1099 sz:1 ]

Free(ptr[377])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:10 ][ addr:1012 sz:1 ][ addr:1020 sz:69 ][ addr:1099 sz:1 ]

Free(ptr[405])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:10 ][ addr:1012 sz:1 ][ addr:1020 sz:80 ]

ptr[408] = Alloc(4) returned 1000 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1004 sz:6 ][ addr:1012 sz:1 ][ addr:1020 sz:80 ]

ptr[409] = Alloc(4) returned 1004 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1008 sz:2 ][ addr:1012 sz:1 ][ addr:1020 sz:80 ]

Free(ptr[406])
returned 0
Free List [ Size 3 ]: [ addr:1008 sz:2 ][ addr:1012 sz:1 ][ addr:1014 sz:86 ]

Free(ptr[399])
returned 0
Free List [ Size 2 ]: [ addr:1008 sz:2 ][ addr:1012 sz:88 ]

ptr[410] = Alloc(5) returned 1012 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1008 sz:2 ][ addr:1017 sz:83 ]

Free(ptr[407])
returned 0
Free List [ Size 2 ]: [ addr:1008 sz:4 ][ addr:1017 sz:83 ]

Free(ptr[408])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:4 ][ addr:1008 sz:4 ][ addr:1017 sz:83 ]

ptr[411] = Alloc(8) returned 1017 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:4 ][ addr:1008 sz:4 ][ addr:1025 sz:75 ]

ptr[412] = Alloc(5) returned 1025 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:4 ][ addr:1008 sz:4 ][ addr:1030 sz:70 ]

ptr[413] = Alloc(5) returned 1030 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:4 ][ addr:1008 sz:4 ][ addr:1035 sz:65 ]

ptr[414] = Alloc(3) returned 1000 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1003 sz:1 ][ addr:1008 sz:4 ][ addr:1035 sz:65 ]

Free(ptr[412])
returned 0
Free List [ Size 4 ]: [ addr:1003 sz:1 ][ addr:1008 sz:4 ][ addr:1025 sz:5 ][ addr:1035 sz:65 ]

Free(ptr[414])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:4 ][ addr:1008 sz:4 ][ addr:1025 sz:5 ][ addr:1035 sz:65 ]

Free(ptr[409])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:12 ][ addr:1025 sz:5 ][ addr:1035 sz:65 ]

ptr[415] = Alloc(6) returned 1000 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1006 sz:6 ][ addr:1025 sz:5 ][ addr:1035 sz:65 ]

Free(ptr[415])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:12 ][ addr:1025 sz:5 ][ addr:1035 sz:65 ]

ptr[416] = Alloc(1) returned 1025 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:12 ][ addr:1026 sz:4 ][ addr:1035 sz:65 ]

Free(ptr[416])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:12 ][ addr:1025 sz:5 ][ addr:1035 sz:65 ]

Free(ptr[411])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:12 ][ addr:1017 sz:13 ][ addr:1035 sz:65 ]

Free(ptr[410])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:30 ][ addr:1035 sz:65 ]

ptr[417] = Alloc(4) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1004 sz:26 ][ addr:1035 sz:65 ]

Free(ptr[417])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:30 ][ addr:1035 sz:65 ]

Free(ptr[413])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[418] = Alloc(10) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1010 sz:90 ]

Free(ptr[418])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[419] = Alloc(7) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1007 sz:93 ]

Free(ptr[419])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[420] = Alloc(5) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1005 sz:95 ]

ptr[421] = Alloc(10) returned 1005 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1015 sz:85 ]

Free(ptr[421])
returned 0
Free List [ Size 1 ]: [ addr:1005 sz:95 ]

ptr[422] = Alloc(1) returned 1005 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1006 sz:94 ]

ptr[423] = Alloc(5) returned 1006 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1011 sz:89 ]

Free(ptr[420])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:5 ][ addr:1011 sz:89 ]

Free(ptr[423])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:5 ][ addr:1006 sz:94 ]

Free(ptr[422])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[424] = Alloc(7) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1007 sz:93 ]

ptr[425] = Alloc(6) returned 1007 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1013 sz:87 ]

ptr[426] = Alloc(5) returned 1013 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1018 sz:82 ]

ptr[427] = Alloc(7) returned 1018 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1025 sz:75 ]

Free(ptr[425])
returned 0
Free List [ Size 2 ]: [ addr:1007 sz:6 ][ addr:1025 sz:75 ]

ptr[428] = Alloc(8) returned 1025 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1007 sz:6 ][ addr:1033 sz:67 ]

Free(ptr[428])
returned 0
Free List [ Size 2 ]: [ addr:1007 sz:6 ][ addr:1025 sz:75 ]

ptr[429] = Alloc(5) returned 1007 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1012 sz:1 ][ addr:1025 sz:75 ]

Free(ptr[429])
returned 0
Free List [ Size 2 ]: [ addr:1007 sz:6 ][ addr:1025 sz:75 ]

Free(ptr[424])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:13 ][ addr:1025 sz:75 ]

ptr[430] = Alloc(9) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1009 sz:4 ][ addr:1025 sz:75 ]

Free(ptr[430])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:13 ][ addr:1025 sz:75 ]

ptr[431] = Alloc(3) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1003 sz:10 ][ addr:1025 sz:75 ]

ptr[432] = Alloc(10) returned 1003 (searched 2 elements)
Free List [ Size 1 ]: [ addr:1025 sz:75 ]

ptr[433] = Alloc(7) returned 1025 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1032 sz:68 ]

ptr[434] = Alloc(4) returned 1032 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1036 sz:64 ]

Free(ptr[426])
returned 0
Free List [ Size 2 ]: [ addr:1013 sz:5 ][ addr:1036 sz:64 ]

Free(ptr[432])
returned 0
Free List [ Size 2 ]: [ addr:1003 sz:15 ][ addr:1036 sz:64 ]

ptr[435] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1008 sz:10 ][ addr:1036 sz:64 ]

Free(ptr[431])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1008 sz:10 ][ addr:1036 sz:64 ]

Free(ptr[435])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:18 ][ addr:1036 sz:64 ]

ptr[436] = Alloc(10) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1010 sz:8 ][ addr:1036 sz:64 ]

ptr[437] = Alloc(9) returned 1036 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1010 sz:8 ][ addr:1045 sz:55 ]

Free(ptr[427])
returned 0
Free List [ Size 2 ]: [ addr:1010 sz:15 ][ addr:1045 sz:55 ]

ptr[438] = Alloc(6) returned 1010 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1016 sz:9 ][ addr:1045 sz:55 ]

ptr[439] = Alloc(9) returned 1016 (searched 2 elements)
Free List [ Size 1 ]: [ addr:1045 sz:55 ]

ptr[440] = Alloc(4) returned 1045 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1049 sz:51 ]

Free(ptr[436])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:10 ][ addr:1049 sz:51 ]

Free(ptr[434])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:10 ][ addr:1032 sz:4 ][ addr:1049 sz:51 ]

ptr[441] = Alloc(2) returned 1032 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:10 ][ addr:1034 sz:2 ][ addr:1049 sz:51 ]

Free(ptr[439])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:10 ][ addr:1016 sz:9 ][ addr:1034 sz:2 ][ addr:1049 sz:51 ]

ptr[442] = Alloc(10) returned 1000 (searched 4 elements)
Free List [ Size 3 ]: [ addr:1016 sz:9 ][ addr:1034 sz:2 ][ addr:1049 sz:51 ]

ptr[443] = Alloc(4) returned 1016 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1020 sz:5 ][ addr:1034 sz:2 ][ addr:1049 sz:51 ]

Free(ptr[433])
returned 0
Free List [ Size 3 ]: [ addr:1020 sz:12 ][ addr:1034 sz:2 ][ addr:1049 sz:51 ]

ptr[444] = Alloc(7) returned 1020 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1027 sz:5 ][ addr:1034 sz:2 ][ addr:1049 sz:51 ]

Free(ptr[443])
returned 0
Free List [ Size 4 ]: [ addr:1016 sz:4 ][ addr:1027 sz:5 ][ addr:1034 sz:2 ][ addr:1049 sz:51 ]

Free(ptr[437])
returned 0
Free List [ Size 4 ]: [ addr:1016 sz:4 ][ addr:1027 sz:5 ][ addr:1034 sz:11 ][ addr:1049 sz:51 ]

ptr[445] = Alloc(1) returned 1016 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1017 sz:3 ][ addr:1027 sz:5 ][ addr:1034 sz:11 ][ addr:1049 sz:51 ]

ptr[446] = Alloc(4) returned 1027 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1017 sz:3 ][ addr:1031 sz:1 ][ addr:1034 sz:11 ][ addr:1049 sz:51 ]

ptr[447] = Alloc(4) returned 1034 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1017 sz:3 ][ addr:1031 sz:1 ][ addr:1038 sz:7 ][ addr:1049 sz:51 ]

Free(ptr[440])
returned 0
Free List [ Size 3 ]: [ addr:1017 sz:3 ][ addr:1031 sz:1 ][ addr:1038 sz:62 ]

Free(ptr[444])
returned 0
Free List [ Size 3 ]: [ addr:1017 sz:10 ][ addr:1031 sz:1 ][ addr:1038 sz:62 ]

ptr[448] = Alloc(6) returned 1017 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1023 sz:4 ][ addr:1031 sz:1 ][ addr:1038 sz:62 ]

ptr[449] = Alloc(5) returned 1038 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1023 sz:4 ][ addr:1031 sz:1 ][ addr:1043 sz:57 ]

ptr[450] = Alloc(9) returned 1043 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1023 sz:4 ][ addr:1031 sz:1 ][ addr:1052 sz:48 ]

ptr[451] = Alloc(4) returned 1023 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1031 sz:1 ][ addr:1052 sz:48 ]

Free(ptr[448])
returned 0
Free List [ Size 3 ]: [ addr:1017 sz:6 ][ addr:1031 sz:1 ][ addr:1052 sz:48 ]

ptr[452] = Alloc(8) returned 1052 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1017 sz:6 ][ addr:1031 sz:1 ][ addr:1060 sz:40 ]

ptr[453] = Alloc(6) returned 1017 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1031 sz:1 ][ addr:1060 sz:40 ]

Free(ptr[452])
returned 0
Free List [ Size 2 ]: [ addr:1031 sz:1 ][ addr:1052 sz:48 ]

Free(ptr[446])
returned 0
Free List [ Size 2 ]: [ addr:1027 sz:5 ][ addr:1052 sz:48 ]

Free(ptr[451])
returned 0
Free List [ Size 2 ]: [ addr:1023 sz:9 ][ addr:1052 sz:48 ]

ptr[454] = Alloc(6) returned 1023 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1029 sz:3 ][ addr:1052 sz:48 ]

Free(ptr[454])
returned 0
Free List [ Size 2 ]: [ addr:1023 sz:9 ][ addr:1052 sz:48 ]

Free(ptr[453])
returned 0
Free List [ Size 2 ]: [ addr:1017 sz:15 ][ addr:1052 sz:48 ]

ptr[455] = Alloc(7) returned 1017 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1024 sz:8 ][ addr:1052 sz:48 ]

Free(ptr[442])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:10 ][ addr:1024 sz:8 ][ addr:1052 sz:48 ]

ptr[456] = Alloc(10) returned 1000 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1024 sz:8 ][ addr:1052 sz:48 ]

ptr[457] = Alloc(10) returned 1052 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1024 sz:8 ][ addr:1062 sz:38 ]

Free(ptr[441])
returned 0
Free List [ Size 2 ]: [ addr:1024 sz:10 ][ addr:1062 sz:38 ]

Free(ptr[457])
returned 0
Free List [ Size 2 ]: [ addr:1024 sz:10 ][ addr:1052 sz:48 ]

ptr[458] = Alloc(7) returned 1024 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1031 sz:3 ][ addr:1052 sz:48 ]

Free(ptr[438])
returned 0
Free List [ Size 3 ]: [ addr:1010 sz:6 ][ addr:1031 sz:3 ][ addr:1052 sz:48 ]

Free(ptr[449])
returned 0
Free List [ Size 4 ]: [ addr:1010 sz:6 ][ addr:1031 sz:3 ][ addr:1038 sz:5 ][ addr:1052 sz:48 ]

Free(ptr[458])
returned 0
Free List [ Size 4 ]: [ addr:1010 sz:6 ][ addr:1024 sz:10 ][ addr:1038 sz:5 ][ addr:1052 sz:48 ]

ptr[459] = Alloc(7) returned 1024 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1010 sz:6 ][ addr:1031 sz:3 ][ addr:1038 sz:5 ][ addr:1052 sz:48 ]

ptr[460] = Alloc(2) returned 1031 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1010 sz:6 ][ addr:1033 sz:1 ][ addr:1038 sz:5 ][ addr:1052 sz:48 ]

Free(ptr[460])
returned 0
Free List [ Size 4 ]: [ addr:1010 sz:6 ][ addr:1031 sz:3 ][ addr:1038 sz:5 ][ addr:1052 sz:48 ]

Free(ptr[450])
returned 0
Free List [ Size 3 ]: [ addr:1010 sz:6 ][ addr:1031 sz:3 ][ addr:1038 sz:62 ]

ptr[461] = Alloc(5) returned 1010 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1015 sz:1 ][ addr:1031 sz:3 ][ addr:1038 sz:62 ]

Free(ptr[455])
returned 0
Free List [ Size 4 ]: [ addr:1015 sz:1 ][ addr:1017 sz:7 ][ addr:1031 sz:3 ][ addr:1038 sz:62 ]

ptr[462] = Alloc(10) returned 1038 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1015 sz:1 ][ addr:1017 sz:7 ][ addr:1031 sz:3 ][ addr:1048 sz:52 ]

Free(ptr[447])
returned 0
Free List [ Size 4 ]: [ addr:1015 sz:1 ][ addr:1017 sz:7 ][ addr:1031 sz:7 ][ addr:1048 sz:52 ]

ptr[463] = Alloc(5) returned 1017 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1015 sz:1 ][ addr:1022 sz:2 ][ addr:1031 sz:7 ][ addr:1048 sz:52 ]

Free(ptr[445])
returned 0
Free List [ Size 4 ]: [ addr:1015 sz:2 ][ addr:1022 sz:2 ][ addr:1031 sz:7 ][ addr:1048 sz:52 ]

Free(ptr[462])
returned 0
Free List [ Size 3 ]: [ addr:1015 sz:2 ][ addr:1022 sz:2 ][ addr:1031 sz:69 ]

ptr[464] = Alloc(9) returned 1031 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1015 sz:2 ][ addr:1022 sz:2 ][ addr:1040 sz:60 ]

Free(ptr[459])
returned 0
Free List [ Size 3 ]: [ addr:1015 sz:2 ][ addr:1022 sz:9 ][ addr:1040 sz:60 ]

Free(ptr[464])
returned 0
Free List [ Size 2 ]: [ addr:1015 sz:2 ][ addr:1022 sz:78 ]

ptr[465] = Alloc(8) returned 1022 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1015 sz:2 ][ addr:1030 sz:70 ]

Free(ptr[463])
returned 0
Free List [ Size 2 ]: [ addr:1015 sz:7 ][ addr:1030 sz:70 ]

ptr[466] = Alloc(6) returned 1015 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1021 sz:1 ][ addr:1030 sz:70 ]

Free(ptr[461])
returned 0
Free List [ Size 3 ]: [ addr:1010 sz:5 ][ addr:1021 sz:1 ][ addr:1030 sz:70 ]

Free(ptr[456])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:15 ][ addr:1021 sz:1 ][ addr:1030 sz:70 ]

ptr[467] = Alloc(9) returned 1000 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1009 sz:6 ][ addr:1021 sz:1 ][ addr:1030 sz:70 ]

ptr[468] = Alloc(5) returned 1009 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1014 sz:1 ][ addr:1021 sz:1 ][ addr:1030 sz:70 ]

ptr[469] = Alloc(4) returned 1030 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1014 sz:1 ][ addr:1021 sz:1 ][ addr:1034 sz:66 ]

Free(ptr[466])
returned 0
Free List [ Size 2 ]: [ addr:1014 sz:8 ][ addr:1034 sz:66 ]

Free(ptr[467])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:9 ][ addr:1014 sz:8 ][ addr:1034 sz:66 ]

ptr[470] = Alloc(4) returned 1014 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:9 ][ addr:1018 sz:4 ][ addr:1034 sz:66 ]

Free(ptr[470])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:9 ][ addr:1014 sz:8 ][ addr:1034 sz:66 ]

Free(ptr[465])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:9 ][ addr:1014 sz:16 ][ addr:1034 sz:66 ]

Free(ptr[469])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:9 ][ addr:1014 sz:86 ]

ptr[471] = Alloc(3) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1003 sz:6 ][ addr:1014 sz:86 ]

ptr[472] = Alloc(5) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1008 sz:1 ][ addr:1014 sz:86 ]

ptr[473] = Alloc(10) returned 1014 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1008 sz:1 ][ addr:1024 sz:76 ]

ptr[474] = Alloc(8) returned 1024 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1008 sz:1 ][ addr:1032 sz:68 ]

Free(ptr[471])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1008 sz:1 ][ addr:1032 sz:68 ]

ptr[475] = Alloc(3) returned 1000 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1008 sz:1 ][ addr:1032 sz:68 ]

ptr[476] = Alloc(2) returned 1032 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1008 sz:1 ][ addr:1034 sz:66 ]

Free(ptr[472])
returned 0
Free List [ Size 2 ]: [ addr:1003 sz:6 ][ addr:1034 sz:66 ]

ptr[477] = Alloc(3) returned 1003 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1006 sz:3 ][ addr:1034 sz:66 ]

Free(ptr[474])
returned 0
Free List [ Size 3 ]: [ addr:1006 sz:3 ][ addr:1024 sz:8 ][ addr:1034 sz:66 ]

Free(ptr[477])
returned 0
Free List [ Size 3 ]: [ addr:1003 sz:6 ][ addr:1024 sz:8 ][ addr:1034 sz:66 ]

ptr[478] = Alloc(6) returned 1003 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1024 sz:8 ][ addr:1034 sz:66 ]

Free(ptr[475])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1024 sz:8 ][ addr:1034 sz:66 ]

ptr[479] = Alloc(3) returned 1000 (searched 3 elements)
Free List [ Size 2 ]: [ addr:1024 sz:8 ][ addr:1034 sz:66 ]

Free(ptr[473])
returned 0
Free List [ Size 2 ]: [ addr:1014 sz:18 ][ addr:1034 sz:66 ]

Free(ptr[479])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:3 ][ addr:1014 sz:18 ][ addr:1034 sz:66 ]

Free(ptr[478])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:9 ][ addr:1014 sz:18 ][ addr:1034 sz:66 ]

Free(ptr[476])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:9 ][ addr:1014 sz:86 ]

ptr[480] = Alloc(2) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1002 sz:7 ][ addr:1014 sz:86 ]

Free(ptr[468])
returned 0
Free List [ Size 1 ]: [ addr:1002 sz:98 ]

Free(ptr[480])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[481] = Alloc(1) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1001 sz:99 ]

ptr[482] = Alloc(9) returned 1001 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1010 sz:90 ]

ptr[483] = Alloc(10) returned 1010 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1020 sz:80 ]

Free(ptr[483])
returned 0
Free List [ Size 1 ]: [ addr:1010 sz:90 ]

ptr[484] = Alloc(3) returned 1010 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1013 sz:87 ]

ptr[485] = Alloc(4) returned 1013 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1017 sz:83 ]

ptr[486] = Alloc(8) returned 1017 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1025 sz:75 ]

Free(ptr[481])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:1 ][ addr:1025 sz:75 ]

ptr[487] = Alloc(3) returned 1025 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:1 ][ addr:1028 sz:72 ]

ptr[488] = Alloc(9) returned 1028 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1000 sz:1 ][ addr:1037 sz:63 ]

Free(ptr[482])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:10 ][ addr:1037 sz:63 ]

ptr[489] = Alloc(5) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1005 sz:5 ][ addr:1037 sz:63 ]

Free(ptr[488])
returned 0
Free List [ Size 2 ]: [ addr:1005 sz:5 ][ addr:1028 sz:72 ]

ptr[490] = Alloc(7) returned 1028 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1005 sz:5 ][ addr:1035 sz:65 ]

Free(ptr[484])
returned 0
Free List [ Size 2 ]: [ addr:1005 sz:8 ][ addr:1035 sz:65 ]

ptr[491] = Alloc(7) returned 1005 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1012 sz:1 ][ addr:1035 sz:65 ]

ptr[492] = Alloc(10) returned 1035 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1012 sz:1 ][ addr:1045 sz:55 ]

Free(ptr[490])
returned 0
Free List [ Size 3 ]: [ addr:1012 sz:1 ][ addr:1028 sz:7 ][ addr:1045 sz:55 ]

ptr[493] = Alloc(5) returned 1028 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1012 sz:1 ][ addr:1033 sz:2 ][ addr:1045 sz:55 ]

Free(ptr[492])
returned 0
Free List [ Size 2 ]: [ addr:1012 sz:1 ][ addr:1033 sz:67 ]

ptr[494] = Alloc(4) returned 1033 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1012 sz:1 ][ addr:1037 sz:63 ]

ptr[495] = Alloc(5) returned 1037 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1012 sz:1 ][ addr:1042 sz:58 ]

ptr[496] = Alloc(3) returned 1042 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1012 sz:1 ][ addr:1045 sz:55 ]

Free(ptr[496])
returned 0
Free List [ Size 2 ]: [ addr:1012 sz:1 ][ addr:1042 sz:58 ]

ptr[497] = Alloc(7) returned 1042 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1012 sz:1 ][ addr:1049 sz:51 ]

ptr[498] = Alloc(6) returned 1049 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1012 sz:1 ][ addr:1055 sz:45 ]

Free(ptr[493])
returned 0
Free List [ Size 3 ]: [ addr:1012 sz:1 ][ addr:1028 sz:5 ][ addr:1055 sz:45 ]

Free(ptr[495])
returned 0
Free List [ Size 4 ]: [ addr:1012 sz:1 ][ addr:1028 sz:5 ][ addr:1037 sz:5 ][ addr:1055 sz:45 ]

Free(ptr[486])
returned 0
Free List [ Size 5 ]: [ addr:1012 sz:1 ][ addr:1017 sz:8 ][ addr:1028 sz:5 ][ addr:1037 sz:5 ][ addr:1055 sz:45 ]

ptr[499] = Alloc(6) returned 1017 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1012 sz:1 ][ addr:1023 sz:2 ][ addr:1028 sz:5 ][ addr:1037 sz:5 ][ addr:1055 sz:45 ]

Free(ptr[498])
returned 0
Free List [ Size 5 ]: [ addr:1012 sz:1 ][ addr:1023 sz:2 ][ addr:1028 sz:5 ][ addr:1037 sz:5 ][ addr:1049 sz:51 ]

Free(ptr[499])
returned 0
Free List [ Size 5 ]: [ addr:1012 sz:1 ][ addr:1017 sz:8 ][ addr:1028 sz:5 ][ addr:1037 sz:5 ][ addr:1049 sz:51 ]

Free(ptr[491])
returned 0
Free List [ Size 5 ]: [ addr:1005 sz:8 ][ addr:1017 sz:8 ][ addr:1028 sz:5 ][ addr:1037 sz:5 ][ addr:1049 sz:51 ]

Free(ptr[489])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:13 ][ addr:1017 sz:8 ][ addr:1028 sz:5 ][ addr:1037 sz:5 ][ addr:1049 sz:51 ]

ptr[500] = Alloc(5) returned 1028 (searched 5 elements)
Free List [ Size 4 ]: [ addr:1000 sz:13 ][ addr:1017 sz:8 ][ addr:1037 sz:5 ][ addr:1049 sz:51 ]

ptr[501] = Alloc(7) returned 1017 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:13 ][ addr:1024 sz:1 ][ addr:1037 sz:5 ][ addr:1049 sz:51 ]

ptr[502] = Alloc(8) returned 1000 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1008 sz:5 ][ addr:1024 sz:1 ][ addr:1037 sz:5 ][ addr:1049 sz:51 ]

Free(ptr[497])
returned 0
Free List [ Size 3 ]: [ addr:1008 sz:5 ][ addr:1024 sz:1 ][ addr:1037 sz:63 ]

ptr[503] = Alloc(3) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1011 sz:2 ][ addr:1024 sz:1 ][ addr:1037 sz:63 ]

ptr[504] = Alloc(3) returned 1037 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1011 sz:2 ][ addr:1024 sz:1 ][ addr:1040 sz:60 ]

Free(ptr[485])
returned 0
Free List [ Size 3 ]: [ addr:1011 sz:6 ][ addr:1024 sz:1 ][ addr:1040 sz:60 ]

Free(ptr[504])
returned 0
Free List [ Size 3 ]: [ addr:1011 sz:6 ][ addr:1024 sz:1 ][ addr:1037 sz:63 ]

ptr[505] = Alloc(2) returned 1011 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1013 sz:4 ][ addr:1024 sz:1 ][ addr:1037 sz:63 ]

Free(ptr[500])
returned 0
Free List [ Size 4 ]: [ addr:1013 sz:4 ][ addr:1024 sz:1 ][ addr:1028 sz:5 ][ addr:1037 sz:63 ]

Free(ptr[487])
returned 0
Free List [ Size 3 ]: [ addr:1013 sz:4 ][ addr:1024 sz:9 ][ addr:1037 sz:63 ]

Free(ptr[494])
returned 0
Free List [ Size 2 ]: [ addr:1013 sz:4 ][ addr:1024 sz:76 ]

Free(ptr[505])
returned 0
Free List [ Size 2 ]: [ addr:1011 sz:6 ][ addr:1024 sz:76 ]

Free(ptr[501])
returned 0
Free List [ Size 1 ]: [ addr:1011 sz:89 ]

Free(ptr[502])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:8 ][ addr:1011 sz:89 ]

ptr[506] = Alloc(4) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1004 sz:4 ][ addr:1011 sz:89 ]

ptr[507] = Alloc(6) returned 1011 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1004 sz:4 ][ addr:1017 sz:83 ]

Free(ptr[507])
returned 0
Free List [ Size 2 ]: [ addr:1004 sz:4 ][ addr:1011 sz:89 ]

Free(ptr[503])
returned 0
Free List [ Size 1 ]: [ addr:1004 sz:96 ]

Free(ptr[506])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[508] = Alloc(10) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1010 sz:90 ]

ptr[509] = Alloc(2) returned 1010 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1012 sz:88 ]

ptr[510] = Alloc(7) returned 1012 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1019 sz:81 ]

Free(ptr[509])
returned 0
Free List [ Size 2 ]: [ addr:1010 sz:2 ][ addr:1019 sz:81 ]

Free(ptr[510])
returned 0
Free List [ Size 1 ]: [ addr:1010 sz:90 ]

Free(ptr[508])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[511] = Alloc(9) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1009 sz:91 ]

ptr[512] = Alloc(7) returned 1009 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1016 sz:84 ]

Free(ptr[512])
returned 0
Free List [ Size 1 ]: [ addr:1009 sz:91 ]

ptr[513] = Alloc(4) returned 1009 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1013 sz:87 ]

Free(ptr[513])
returned 0
Free List [ Size 1 ]: [ addr:1009 sz:91 ]

Free(ptr[511])
returned 0
Free List [ Size 1 ]: [ addr:1000 sz:100 ]

ptr[514] = Alloc(2) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1002 sz:98 ]
```
</details>
</br>

### 6

修改分配操作的占比（`-P`），默认情况下 50% 分配操作，50% 释放操作。

接近 0 ，因为一开始没有分配，所以也不会一直处于释放状态，结果是 50% 分配 50% 释放。由于没有合并，空间释放后使得空闲列表长度增加，最优匹配遍历的长度增加。

```bash
./malloc.py -P 5 -c

# 输出
seed 0
size 100
baseAddr 1000
headerSize 0
alignment -1
policy BEST
listOrder ADDRSORT
coalesce False
numOps 10
range 10
percentAlloc 5
allocList 
compute True

ptr[0] = Alloc(8) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1008 sz:92 ]

Free(ptr[0])
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:8 ][ addr:1008 sz:92 ]

ptr[1] = Alloc(5) returned 1000 (searched 2 elements)
Free List [ Size 2 ]: [ addr:1005 sz:3 ][ addr:1008 sz:92 ]

Free(ptr[1])
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:5 ][ addr:1005 sz:3 ][ addr:1008 sz:92 ]

ptr[2] = Alloc(6) returned 1008 (searched 3 elements)
Free List [ Size 3 ]: [ addr:1000 sz:5 ][ addr:1005 sz:3 ][ addr:1014 sz:86 ]

Free(ptr[2])
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:5 ][ addr:1005 sz:3 ][ addr:1008 sz:6 ][ addr:1014 sz:86 ]

ptr[3] = Alloc(7) returned 1014 (searched 4 elements)
Free List [ Size 4 ]: [ addr:1000 sz:5 ][ addr:1005 sz:3 ][ addr:1008 sz:6 ][ addr:1021 sz:79 ]

Free(ptr[3])
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:5 ][ addr:1005 sz:3 ][ addr:1008 sz:6 ][ addr:1014 sz:7 ][ addr:1021 sz:79 ]

ptr[4] = Alloc(1) returned 1005 (searched 5 elements)
Free List [ Size 5 ]: [ addr:1000 sz:5 ][ addr:1006 sz:2 ][ addr:1008 sz:6 ][ addr:1014 sz:7 ][ addr:1021 sz:79 ]

Free(ptr[4])
returned 0
Free List [ Size 6 ]: [ addr:1000 sz:5 ][ addr:1005 sz:1 ][ addr:1006 sz:2 ][ addr:1008 sz:6 ][ addr:1014 sz:7 ][ addr:1021 sz:79 ]
```

接近 100，只有分配操作，空闲列表保持一整块，最优匹配只需要判断空闲块是否满足大小，然后进行分配即可。

```bash
./malloc.py -P 95 -c

# 输出
seed 0
size 100
baseAddr 1000
headerSize 0
alignment -1
policy BEST
listOrder ADDRSORT
coalesce False
numOps 10
range 10
percentAlloc 95
allocList 
compute True

ptr[0] = Alloc(8) returned 1000 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1008 sz:92 ]

ptr[1] = Alloc(3) returned 1008 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1011 sz:89 ]

ptr[2] = Alloc(5) returned 1011 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1016 sz:84 ]

ptr[3] = Alloc(4) returned 1016 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1020 sz:80 ]

ptr[4] = Alloc(6) returned 1020 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1026 sz:74 ]

ptr[5] = Alloc(6) returned 1026 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1032 sz:68 ]

ptr[6] = Alloc(8) returned 1032 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1040 sz:60 ]

ptr[7] = Alloc(3) returned 1040 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1043 sz:57 ]

ptr[8] = Alloc(10) returned 1043 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1053 sz:47 ]

ptr[9] = Alloc(10) returned 1053 (searched 1 elements)
Free List [ Size 1 ]: [ addr:1063 sz:37 ]
```

### 7

自定义操作序列（`-A`），生成高度碎片化的空闲空间，看起来使用最优匹配生成碎片化空间最容易xd

```bash
./malloc.py -A +1,-0,+2,-1,+3,-2,+4,-3,+5,-4,+6,-5,+7 -c

# 输出
seed 0
size 100
baseAddr 1000
headerSize 0
alignment -1
policy BEST
listOrder ADDRSORT
coalesce False
numOps 10
range 10
percentAlloc 50
allocList +1,-0,+2,-1,+3,-2,+4,-3,+5,-4,+6,-5,+7
compute True

ptr[0] = Alloc(1) returned 1000 (searched 1 elements)                   <---- 分配 1 字节空间给 ptr[0]
Free List [ Size 1 ]: [ addr:1001 sz:99 ]

Free(ptr[0])                                                            <---- 释放 ptr[0] 的空间
returned 0
Free List [ Size 2 ]: [ addr:1000 sz:1 ][ addr:1001 sz:99 ]

ptr[1] = Alloc(2) returned 1001 (searched 2 elements)                   <---- 分配 2 字节空间给 ptr[1]
Free List [ Size 2 ]: [ addr:1000 sz:1 ][ addr:1003 sz:97 ]

Free(ptr[1])                                                            <---- 释放 ptr[1] 的空间
returned 0
Free List [ Size 3 ]: [ addr:1000 sz:1 ][ addr:1001 sz:2 ][ addr:1003 sz:97 ]

ptr[2] = Alloc(3) returned 1003 (searched 3 elements)                   <---- 分配 3 字节空间给 ptr[2]
Free List [ Size 3 ]: [ addr:1000 sz:1 ][ addr:1001 sz:2 ][ addr:1006 sz:94 ]

Free(ptr[2])                                                            <---- 释放 ptr[2] 的空间
returned 0
Free List [ Size 4 ]: [ addr:1000 sz:1 ][ addr:1001 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:94 ]

ptr[3] = Alloc(4) returned 1006 (searched 4 elements)                   <---- 分配 4 字节空间给 ptr[3]
Free List [ Size 4 ]: [ addr:1000 sz:1 ][ addr:1001 sz:2 ][ addr:1003 sz:3 ][ addr:1010 sz:90 ]

Free(ptr[3])                                                            <---- 释放 ptr[3] 的空间
returned 0
Free List [ Size 5 ]: [ addr:1000 sz:1 ][ addr:1001 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:4 ][ addr:1010 sz:90 ]

ptr[4] = Alloc(5) returned 1010 (searched 5 elements)                   <---- 分配 5 字节空间给 ptr[4]
Free List [ Size 5 ]: [ addr:1000 sz:1 ][ addr:1001 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:4 ][ addr:1015 sz:85 ]

Free(ptr[4])                                                            <---- 释放 ptr[4] 的空间
returned 0
Free List [ Size 6 ]: [ addr:1000 sz:1 ][ addr:1001 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:4 ][ addr:1010 sz:5 ][ addr:1015 sz:85 ]

ptr[5] = Alloc(6) returned 1015 (searched 6 elements)                   <---- 分配 6 字节空间给 ptr[5]
Free List [ Size 6 ]: [ addr:1000 sz:1 ][ addr:1001 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:4 ][ addr:1010 sz:5 ][ addr:1021 sz:79 ]

Free(ptr[5])                                                            <---- 释放 ptr[5] 的空间
returned 0
Free List [ Size 7 ]: [ addr:1000 sz:1 ][ addr:1001 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:4 ][ addr:1010 sz:5 ][ addr:1015 sz:6 ][ addr:1021 sz:79 ]

ptr[6] = Alloc(7) returned 1021 (searched 7 elements)                   <---- 分配 7 字节空间给 ptr[6]
Free List [ Size 7 ]: [ addr:1000 sz:1 ][ addr:1001 sz:2 ][ addr:1003 sz:3 ][ addr:1006 sz:4 ][ addr:1010 sz:5 ][ addr:1015 sz:6 ][ addr:1028 sz:72 ]
```