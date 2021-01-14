## 41 Fast File System (FFS)

模拟快速文件系统

```python
# 随机种子，默认为 0
parser.add_option('-s', '--seed', default=0, help='the random seed', 
                  action='store', type='int', dest='seed')
# 块组数量，默认为 10
parser.add_option('-n', '--num_groups', default=10, help='number of block groups',
                  action='store', type='int', dest='num_groups')
# 块组中的数据块数量，默认为 30
parser.add_option('-d', '--datablocks_per_groups', default=30,
                  help='data blocks per group', action='store',
                  type='int', dest='blocks_per_group')
# 块组中的索引节点数量，默认为 10
parser.add_option('-i', '--inodes_per_group', default=10, help='inodes per group',
                  action='store', type='int', dest='inodes_per_group')
# 将文件扩展到下一组之前，块组中使用的块数，默认为 30
parser.add_option('-L', '--large_file_exception', default=30,
                  help='0:off, N>0:blocks in group before spreading file to next group',
                  action='store', type='int', dest='large_file_exception')
# 指令文件
parser.add_option('-f', '--input_file', default='/no/such/file', help='command file',
                  action='store', type='string', dest='input_file')
# 将索引节点均匀放置在块组中
parser.add_option('-I', '--spread_inodes', default=False,
                  help='Instead of putting file inodes in parent dir group, \
                  spread them evenly around all groups',
                  action='store_true', dest='spread_inodes')
# 将数据均匀放置在块组中
parser.add_option('-D', '--spread_data', default=False,
                  help='Instead of putting data near inode, \
                  spread them evenly around all groups',
                  action='store_true', dest='spread_data_blocks')
# 将组块分组，然后再进行选择
# 创建目录时，按顺序优先选择空余索引节点最多的组块
parser.add_option('-A', '--allocate_faraway', default=1,
                  help='When picking a group, examine this many groups at a time',
                  action='store', dest='allocate_faraway', type='int')
# 连续分配数据块
parser.add_option('-C', '--contig_allocation_policy', default=1,
                  help='number of contig free blocks needed to alloc',
                  action='store', type='int', dest='contig_allocation_policy')
# 显示文件和目录跨度
# 文件跨度：任意两个数据块之间或索引节点与任意数据块之间的最大距离
# 目录跨度：目录中索引节点和数据块的最大距离
parser.add_option('-T', '--show_spans', help='show file and directory spans',
                  default=False, action='store_true', dest='show_spans')
# 显示符号信息（符号、索引节点编号、文件路径、文件类型）
parser.add_option('-M', '--show_symbol_map', help='show symbol map',
                  default=False, action='store_true', dest='show_symbol_map')
# 在块组旁边显示块地址
parser.add_option('-B', '--show_block_addresses',
                  help='show block addresses alongside groups',
                  action='store_true', default=False, dest='show_block_addresses')
# 打印索引节点信息
parser.add_option('-S', '--do_per_file_stats',
                  help='print out detailed inode stats',
                  action='store_true', default=False, dest='do_per_file_stats')
# 打印操作是否成功
parser.add_option('-v', '--show_file_ops',
                  help='print out detailed per-op success/failure',
                  action='store_true', default=False, dest='show_file_ops')
# 计算结果
parser.add_option('-c', '--compute', help='compute answers for me', action='store_true',
                  default=False, dest='solve')
```

目录下包含多个指令文件，执行 [in.example1](file-ffs/in.example1) 中的指令
- 默认创建根目录，索引节点和数据块都放置在块组 0 中
- 目录 a 放置在块组 1 中
- 目录 b 放置在块组 2 中
- 文件（索引节点和数据）和父级索引节点在同一个块组中

```bash
./ffs.py -f in.example1 -T -M -B -S -v -c

# 输出
op mkdir /a ->success               <---- 创建目录
op mkdir /b ->success               <---- 创建目录
op create /a/c [size:2] ->success   <---- 创建文件
op create /a/d [size:2] ->success   <---- 创建文件
op create /a/e [size:2] ->success   <---- 创建文件
op create /b/f [size:2] ->success   <---- 创建文件

num_groups:       10    <---- 块组数量
inodes_per_group: 10    <---- 每个块组的索引节点
blocks_per_group: 30    <---- 每个块组的块数量

free data blocks: 289 (of 300)    <---- 空闲数据块数量
free inodes:      93 (of 100)     <---- 空闲索引节点数量

spread inodes?    False
spread data?      False
contig alloc:     1

     00000000000000000000 1111111111 2222222222
     01234567890123456789 0123456789 0123456789

group inodes    data
    0 /--------- /--------- ---------- ----------  [   0-  39]
    1 acde------ accddee--- ---------- ----------  [  40-  79]
    2 bf-------- bff------- ---------- ----------  [  80- 119]
    3 ---------- ---------- ---------- ----------  [ 120- 159]
    4 ---------- ---------- ---------- ----------  [ 160- 199]
    5 ---------- ---------- ---------- ----------  [ 200- 239]
    6 ---------- ---------- ---------- ----------  [ 240- 279]
    7 ---------- ---------- ---------- ----------  [ 280- 319]
    8 ---------- ---------- ---------- ----------  [ 320- 359]
    9 ---------- ---------- ---------- ----------  [ 360- 399]

symbol  inode#  filename     filetype   block_addresses
/            0  /            directory  0           <---- 目录
a           10  /a           directory  30          <---- 目录
c           11  /a/c         regular    31 32       <---- 文件
d           12  /a/d         regular    33 34       <---- 文件
e           13  /a/e         regular    35 36       <---- 文件
b           20  /b           directory  60          <---- 目录
f           21  /b/f         regular    61 62       <---- 文件

span: files
  file:       /a/c  filespan:  11
  file:       /a/d  filespan:  12
  file:       /a/e  filespan:  13
  file:       /b/f  filespan:  11
               avg  filespan:  11.75

span: directories
  dir:           /  dirspan:  10
  dir:          /a  dirspan:  16
  dir:          /b  dirspan:  12
               avg  dirspan:  12.67
```

### 1

执行 [in.largefile](file-ffs/in.largefile) 中的指令
- 创建一个大小为 40 个数据块的文件
- `-L 4`：每个组块中写入 4 个数据块就换到下一个组块中继续写入

```bash
./ffs.py -f in.largefile -L 4 -T -M -B -S -v -c

# 输出
op create /a [size:40] ->success

num_groups:       10
inodes_per_group: 10
blocks_per_group: 30

free data blocks: 259 (of 300)
free inodes:      98 (of 100)

spread inodes?    False
spread data?      False
contig alloc:     1

     00000000000000000000 1111111111 2222222222
     01234567890123456789 0123456789 0123456789

group inodes    data
    0 /a-------- /aaaa----- ---------- ----------  [   0-  39]
    1 ---------- aaaa------ ---------- ----------  [  40-  79]
    2 ---------- aaaa------ ---------- ----------  [  80- 119]
    3 ---------- aaaa------ ---------- ----------  [ 120- 159]
    4 ---------- aaaa------ ---------- ----------  [ 160- 199]
    5 ---------- aaaa------ ---------- ----------  [ 200- 239]
    6 ---------- aaaa------ ---------- ----------  [ 240- 279]
    7 ---------- aaaa------ ---------- ----------  [ 280- 319]
    8 ---------- aaaa------ ---------- ----------  [ 320- 359]
    9 ---------- aaaa------ ---------- ----------  [ 360- 399]

symbol  inode#  filename     filetype   block_addresses
/            0  /            directory  0 
a            1  /a           regular    1 2 3 4 30 31 32 33 60 61 62 63 90 91 92 93 120 121 122 123 150 151 152 153 180 181 182 183 210 211 212 213 240 241 242 243 270 271 272 273 

span: files
  file:         /a  filespan: 372
               avg  filespan: 372.00

span: directories
  dir:           /  dirspan: 373
               avg  dirspan: 373.00
```

### 2

执行 [in.largefile](file-ffs/in.largefile) 中的指令
- 创建一个大小为 40 个数据块的文件
- `-L 30`：每个组块中写入 30 个数据块再换到下一个组块中继续写入

```bash
./ffs.py -f in.largefile -L 30 -T -M -B -S -v -c

# 输出
op create /a [size:40] ->success

num_groups:       10
inodes_per_group: 10
blocks_per_group: 30

free data blocks: 259 (of 300)
free inodes:      98 (of 100)

spread inodes?    False
spread data?      False
contig alloc:     1

     00000000000000000000 1111111111 2222222222
     01234567890123456789 0123456789 0123456789

group inodes    data
    0 /a-------- /aaaaaaaaa aaaaaaaaaa aaaaaaaaaa  [   0-  39]
    1 ---------- aaaaaaaaaa a--------- ----------  [  40-  79]
    2 ---------- ---------- ---------- ----------  [  80- 119]
    3 ---------- ---------- ---------- ----------  [ 120- 159]
    4 ---------- ---------- ---------- ----------  [ 160- 199]
    5 ---------- ---------- ---------- ----------  [ 200- 239]
    6 ---------- ---------- ---------- ----------  [ 240- 279]
    7 ---------- ---------- ---------- ----------  [ 280- 319]
    8 ---------- ---------- ---------- ----------  [ 320- 359]
    9 ---------- ---------- ---------- ----------  [ 360- 399]

symbol  inode#  filename     filetype   block_addresses
/            0  /            directory  0 
a            1  /a           regular    1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 

span: files
  file:         /a  filespan:  59
               avg  filespan:  59.00

span: directories
  dir:           /  dirspan:  60
               avg  dirspan:  60.00
```

### 3

执行 [in.largefile](file-ffs/in.largefile) 中的指令
- 创建一个大小为 40 个数据块的文件
- `-L 100`：每个组块中写入 100 个数据块再换到下一个组块中继续写入
  - 但是每个块组中只有 30 个数据块，因此写满后就换到下一个组块写入

```bash
./ffs.py -f in.largefile -L 100 -T -M -B -S -v -c

# 输出
op create /a [size:40] ->success

num_groups:       10
inodes_per_group: 10
blocks_per_group: 30

free data blocks: 259 (of 300)
free inodes:      98 (of 100)

spread inodes?    False
spread data?      False
contig alloc:     1

     00000000000000000000 1111111111 2222222222
     01234567890123456789 0123456789 0123456789

group inodes    data
    0 /a-------- /aaaaaaaaa aaaaaaaaaa aaaaaaaaaa  [   0-  39]
    1 ---------- aaaaaaaaaa a--------- ----------  [  40-  79]
    2 ---------- ---------- ---------- ----------  [  80- 119]
    3 ---------- ---------- ---------- ----------  [ 120- 159]
    4 ---------- ---------- ---------- ----------  [ 160- 199]
    5 ---------- ---------- ---------- ----------  [ 200- 239]
    6 ---------- ---------- ---------- ----------  [ 240- 279]
    7 ---------- ---------- ---------- ----------  [ 280- 319]
    8 ---------- ---------- ---------- ----------  [ 320- 359]
    9 ---------- ---------- ---------- ----------  [ 360- 399]

symbol  inode#  filename     filetype   block_addresses
/            0  /            directory  0 
a            1  /a           regular    1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 

span: files
  file:         /a  filespan:  59
               avg  filespan:  59.00

span: directories
  dir:           /  dirspan:  60
               avg  dirspan:  60.00
```

### 4/5

执行 [in.manyfiles](file-ffs/in.manyfiles) 中的指令
- 创建 9 个大小为 2 的文件
  - 在根目录所在的块组创建（0）
- 创建 2 个目录
  - 分别创建在 2 个块组中（1、2）
- 创建 16 个文件，大小为 3 或 1
  - 和父索引节点在同一个块组中（1、2）

```bash
./ffs.py -f in.manyfiles -T -M -B -S -v -c

# 输出
op create /a [size:2] ->success
op create /b [size:2] ->success
op create /c [size:2] ->success
op create /d [size:2] ->success
op create /e [size:2] ->success
op create /f [size:2] ->success
op create /g [size:2] ->success
op create /h [size:2] ->success
op create /i [size:2] ->success
op mkdir /j ->success
op mkdir /t ->success
op create /t/u [size:3] ->success
op create /j/l [size:1] ->success
op create /t/v [size:3] ->success
op create /j/m [size:1] ->success
op create /t/w [size:3] ->success
op create /j/n [size:1] ->success
op create /t/x [size:3] ->success
op create /j/o [size:1] ->success
op create /t/y [size:3] ->success
op create /j/p [size:1] ->success
op create /t/z [size:3] ->success
op create /j/q [size:1] ->success
op create /t/A [size:3] ->success
op create /j/r [size:1] ->success
op create /t/B [size:3] ->success
op create /j/C [size:3] ->success

num_groups:       10
inodes_per_group: 10
blocks_per_group: 30

free data blocks: 245 (of 300)
free inodes:      72 (of 100)

spread inodes?    False
spread data?      False
contig alloc:     1

     00000000000000000000 1111111111 2222222222
     01234567890123456789 0123456789 0123456789

group inodes    data
    0 /abcdefghi /aabbccdde effgghhii- ----------  [   0-  39]
    1 jlmnopqrC- jlmnopqrCC C--------- ----------  [  40-  79]
    2 tuvwxyzAB- tuuuvvvwww xxxyyyzzzA AABBB-----  [  80- 119]
    3 ---------- ---------- ---------- ----------  [ 120- 159]
    4 ---------- ---------- ---------- ----------  [ 160- 199]
    5 ---------- ---------- ---------- ----------  [ 200- 239]
    6 ---------- ---------- ---------- ----------  [ 240- 279]
    7 ---------- ---------- ---------- ----------  [ 280- 319]
    8 ---------- ---------- ---------- ----------  [ 320- 359]
    9 ---------- ---------- ---------- ----------  [ 360- 399]

symbol  inode#  filename     filetype   block_addresses
/            0  /            directory  0 
a            1  /a           regular    1 2 
b            2  /b           regular    3 4 
c            3  /c           regular    5 6 
d            4  /d           regular    7 8 
e            5  /e           regular    9 10 
f            6  /f           regular    11 12 
g            7  /g           regular    13 14 
h            8  /h           regular    15 16 
i            9  /i           regular    17 18 
j           10  /j           directory  30 
C           18  /j/C         regular    38 39 40 
l           11  /j/l         regular    31 
m           12  /j/m         regular    32 
n           13  /j/n         regular    33 
o           14  /j/o         regular    34 
p           15  /j/p         regular    35 
q           16  /j/q         regular    36 
r           17  /j/r         regular    37 
t           20  /t           directory  60 
A           27  /t/A         regular    79 80 81 
B           28  /t/B         regular    82 83 84 
u           21  /t/u         regular    61 62 63 
v           22  /t/v         regular    64 65 66 
w           23  /t/w         regular    67 68 69 
x           24  /t/x         regular    70 71 72 
y           25  /t/y         regular    73 74 75 
z           26  /t/z         regular    76 77 78 

span: files
  file:         /a  filespan:  11
  file:         /b  filespan:  12
  file:         /c  filespan:  13
  file:         /d  filespan:  14
  file:         /e  filespan:  15
  file:         /f  filespan:  16
  file:         /g  filespan:  17
  file:         /h  filespan:  18
  file:         /i  filespan:  19
  file:       /t/u  filespan:  12
  file:       /j/l  filespan:  10
  file:       /t/v  filespan:  14
  file:       /j/m  filespan:  10
  file:       /t/w  filespan:  16
  file:       /j/n  filespan:  10
  file:       /t/x  filespan:  18
  file:       /j/o  filespan:  10
  file:       /t/y  filespan:  20
  file:       /j/p  filespan:  10
  file:       /t/z  filespan:  22
  file:       /j/q  filespan:  10
  file:       /t/A  filespan:  24
  file:       /j/r  filespan:  10
  file:       /t/B  filespan:  26
  file:       /j/C  filespan:  12
               avg  filespan:  14.76

span: directories
  dir:           /  dirspan:  28
  dir:          /j  dirspan:  20
  dir:          /t  dirspan:  34
               avg  dirspan:  27.33
```


### 6

执行 [in.manyfiles](file-ffs/in.manyfiles) 中的指令
- `-i 5`：每个块组中索引节点数量为 5
- 创建 9 个大小为 2 的文件
  - 从根目录所在的块组开始创建（0、1）
- 创建 2 个目录
  - 分别创建在 2 个块组中（2、3）
- 创建 16 个文件，大小为 3 或 1
  - 从父索引节点的块组中开始创建（2、3、4、5）

```bash
./ffs.py -f in.manyfiles -i 5 -T -M -B -S -v -c

# 输出
op create /a [size:2] ->success
op create /b [size:2] ->success
op create /c [size:2] ->success
op create /d [size:2] ->success
op create /e [size:2] ->success
op create /f [size:2] ->success
op create /g [size:2] ->success
op create /h [size:2] ->success
op create /i [size:2] ->success
op mkdir /j ->success
op mkdir /t ->success
op create /t/u [size:3] ->success
op create /j/l [size:1] ->success
op create /t/v [size:3] ->success
op create /j/m [size:1] ->success
op create /t/w [size:3] ->success
op create /j/n [size:1] ->success
op create /t/x [size:3] ->success
op create /j/o [size:1] ->success
op create /t/y [size:3] ->success
op create /j/p [size:1] ->success
op create /t/z [size:3] ->success
op create /j/q [size:1] ->success
op create /t/A [size:3] ->success
op create /j/r [size:1] ->success
op create /t/B [size:3] ->success
op create /j/C [size:3] ->success

num_groups:       10
inodes_per_group: 5
blocks_per_group: 30

free data blocks: 245 (of 300)
free inodes:      22 (of 50)

spread inodes?    False
spread data?      False
contig alloc:     1

          0000000000 1111111111 2222222222
     012340123456789 0123456789 0123456789

group inodedata
    0 /abcd /aabbccdd- ---------- ----------  [   0-  34]
    1 efghi eeffgghhii ---------- ----------  [  35-  69]
    2 jlmno jlmno----- ---------- ----------  [  70- 104]
    3 tuvwx tuuuvvvwww xxx------- ----------  [ 105- 139]
    4 ypzqA yyypzzzqAA A--------- ----------  [ 140- 174]
    5 rBC-- rBBBCCC--- ---------- ----------  [ 175- 209]
    6 ----- ---------- ---------- ----------  [ 210- 244]
    7 ----- ---------- ---------- ----------  [ 245- 279]
    8 ----- ---------- ---------- ----------  [ 280- 314]
    9 ----- ---------- ---------- ----------  [ 315- 349]

symbol  inode#  filename     filetype   block_addresses
/            0  /            directory  0 
a            1  /a           regular    1 2 
b            2  /b           regular    3 4 
c            3  /c           regular    5 6 
d            4  /d           regular    7 8 
e            5  /e           regular    30 31 
f            6  /f           regular    32 33 
g            7  /g           regular    34 35 
h            8  /h           regular    36 37 
i            9  /i           regular    38 39 
j           10  /j           directory  60 
C           27  /j/C         regular    154 155 156 
l           11  /j/l         regular    61 
m           12  /j/m         regular    62 
n           13  /j/n         regular    63 
o           14  /j/o         regular    64 
p           21  /j/p         regular    123 
q           23  /j/q         regular    127 
r           25  /j/r         regular    150 
t           15  /t           directory  90 
A           24  /t/A         regular    128 129 130 
B           26  /t/B         regular    151 152 153 
u           16  /t/u         regular    91 92 93 
v           17  /t/v         regular    94 95 96 
w           18  /t/w         regular    97 98 99 
x           19  /t/x         regular    100 101 102 
y           20  /t/y         regular    120 121 122 
z           22  /t/z         regular    124 125 126 

span: files
  file:         /a  filespan:   6
  file:         /b  filespan:   7
  file:         /c  filespan:   8
  file:         /d  filespan:   9
  file:         /e  filespan:   6
  file:         /f  filespan:   7
  file:         /g  filespan:   8
  file:         /h  filespan:   9
  file:         /i  filespan:  10
  file:       /t/u  filespan:   7
  file:       /j/l  filespan:   5
  file:       /t/v  filespan:   9
  file:       /j/m  filespan:   5
  file:       /t/w  filespan:  11
  file:       /j/n  filespan:   5
  file:       /t/x  filespan:  13
  file:       /j/o  filespan:   5
  file:       /t/y  filespan:   7
  file:       /j/p  filespan:   7
  file:       /t/z  filespan:   9
  file:       /j/q  filespan:   9
  file:       /t/A  filespan:  11
  file:       /j/r  filespan:   5
  file:       /t/B  filespan:   7
  file:       /j/C  filespan:   9
               avg  filespan:   7.76

span: directories
  dir:           /  dirspan:  49
  dir:          /j  dirspan: 116
  dir:          /t  dirspan:  78
               avg  dirspan:  81.00
```

### 7

执行 [in.manyfiles](file-ffs/in.manyfiles) 中的指令
- `-i 5`：每个块组中索引节点数量为 5
- `-A 2`：将组块两两分组，每次选择最优的一组（包含 2 个组块）
- 创建 9 个大小为 2 的文件
  - 从根目录所在的块组开始创建（0、1）
- 创建 2 个目录
  - 分别创建在 2 个块组中（2、4）
- 创建 16 个文件，大小为 3 或 1
  - 从父索引节点的块组中开始创建（2/3、4/5）

```bash
./ffs.py -f in.manyfiles -i 5 -A 2 -T -M -B -S -v -c

# 输出
op create /a [size:2] ->success
op create /b [size:2] ->success
op create /c [size:2] ->success
op create /d [size:2] ->success
op create /e [size:2] ->success
op create /f [size:2] ->success
op create /g [size:2] ->success
op create /h [size:2] ->success
op create /i [size:2] ->success
op mkdir /j ->success
op mkdir /t ->success
op create /t/u [size:3] ->success
op create /j/l [size:1] ->success
op create /t/v [size:3] ->success
op create /j/m [size:1] ->success
op create /t/w [size:3] ->success
op create /j/n [size:1] ->success
op create /t/x [size:3] ->success
op create /j/o [size:1] ->success
op create /t/y [size:3] ->success
op create /j/p [size:1] ->success
op create /t/z [size:3] ->success
op create /j/q [size:1] ->success
op create /t/A [size:3] ->success
op create /j/r [size:1] ->success
op create /t/B [size:3] ->success
op create /j/C [size:3] ->success

num_groups:       10
inodes_per_group: 5
blocks_per_group: 30

free data blocks: 245 (of 300)
free inodes:      22 (of 50)

spread inodes?    False
spread data?      False
contig alloc:     1

          0000000000 1111111111 2222222222
     012340123456789 0123456789 0123456789

group inodedata
    0 /abcd /aabbccdd- ---------- ----------  [   0-  34]
    1 efghi eeffgghhii ---------- ----------  [  35-  69]
    2 jlmno jlmno----- ---------- ----------  [  70- 104]
    3 pqrC- pqrCCC---- ---------- ----------  [ 105- 139]
    4 tuvwx tuuuvvvwww xxx------- ----------  [ 140- 174]
    5 yzAB- yyyzzzAAAB BB-------- ----------  [ 175- 209]
    6 ----- ---------- ---------- ----------  [ 210- 244]
    7 ----- ---------- ---------- ----------  [ 245- 279]
    8 ----- ---------- ---------- ----------  [ 280- 314]
    9 ----- ---------- ---------- ----------  [ 315- 349]

symbol  inode#  filename     filetype   block_addresses
/            0  /            directory  0 
a            1  /a           regular    1 2 
b            2  /b           regular    3 4 
c            3  /c           regular    5 6 
d            4  /d           regular    7 8 
e            5  /e           regular    30 31 
f            6  /f           regular    32 33 
g            7  /g           regular    34 35 
h            8  /h           regular    36 37 
i            9  /i           regular    38 39 
j           10  /j           directory  60 
C           18  /j/C         regular    93 94 95 
l           11  /j/l         regular    61 
m           12  /j/m         regular    62 
n           13  /j/n         regular    63 
o           14  /j/o         regular    64 
p           15  /j/p         regular    90 
q           16  /j/q         regular    91 
r           17  /j/r         regular    92 
t           20  /t           directory  120 
A           27  /t/A         regular    156 157 158 
B           28  /t/B         regular    159 160 161 
u           21  /t/u         regular    121 122 123 
v           22  /t/v         regular    124 125 126 
w           23  /t/w         regular    127 128 129 
x           24  /t/x         regular    130 131 132 
y           25  /t/y         regular    150 151 152 
z           26  /t/z         regular    153 154 155 

span: files
  file:         /a  filespan:   6
  file:         /b  filespan:   7
  file:         /c  filespan:   8
  file:         /d  filespan:   9
  file:         /e  filespan:   6
  file:         /f  filespan:   7
  file:         /g  filespan:   8
  file:         /h  filespan:   9
  file:         /i  filespan:  10
  file:       /t/u  filespan:   7
  file:       /j/l  filespan:   5
  file:       /t/v  filespan:   9
  file:       /j/m  filespan:   5
  file:       /t/w  filespan:  11
  file:       /j/n  filespan:   5
  file:       /t/x  filespan:  13
  file:       /j/o  filespan:   5
  file:       /t/y  filespan:   7
  file:       /j/p  filespan:   5
  file:       /t/z  filespan:   9
  file:       /j/q  filespan:   5
  file:       /t/A  filespan:  11
  file:       /j/r  filespan:   5
  file:       /t/B  filespan:  13
  file:       /j/C  filespan:   7
               avg  filespan:   7.68

span: directories
  dir:           /  dirspan:  49
  dir:          /j  dirspan:  45
  dir:          /t  dirspan:  51
               avg  dirspan:  48.33
```

### 8

执行 [in.fragmented](file-ffs/in.fragmented) 中的指令
- 创建 8 个大小为 1 的文件
- 删除其中的 4 个文件
- 创建 1 个大小为 8 的文件
  - 数据没有连续分布

```bash
./ffs.py -f in.fragmented -T -M -B -S -v -c

# 输出
op create /a [size:1] ->success
op create /b [size:1] ->success
op create /c [size:1] ->success
op create /d [size:1] ->success
op create /e [size:1] ->success
op create /f [size:1] ->success
op create /g [size:1] ->success
op create /h [size:1] ->success
op delete /a ->success
op delete /c ->success
op delete /e ->success
op delete /g ->success
op create /i [size:8] ->success

num_groups:       10
inodes_per_group: 10
blocks_per_group: 30

free data blocks: 287 (of 300)
free inodes:      94 (of 100)

spread inodes?    False
spread data?      False
contig alloc:     1

     00000000000000000000 1111111111 2222222222
     01234567890123456789 0123456789 0123456789

group inodes    data
    0 /ib-d-f-h- /ibidifihi iii------- ----------  [   0-  39]
    1 ---------- ---------- ---------- ----------  [  40-  79]
    2 ---------- ---------- ---------- ----------  [  80- 119]
    3 ---------- ---------- ---------- ----------  [ 120- 159]
    4 ---------- ---------- ---------- ----------  [ 160- 199]
    5 ---------- ---------- ---------- ----------  [ 200- 239]
    6 ---------- ---------- ---------- ----------  [ 240- 279]
    7 ---------- ---------- ---------- ----------  [ 280- 319]
    8 ---------- ---------- ---------- ----------  [ 320- 359]
    9 ---------- ---------- ---------- ----------  [ 360- 399]

symbol  inode#  filename     filetype   block_addresses
/            0  /            directory  0 
b            2  /b           regular    2 
d            4  /d           regular    4 
f            6  /f           regular    6 
h            8  /h           regular    8 
i            1  /i           regular    1 3 5 7 9 10 11 12 

span: files
  file:         /b  filespan:  10
  file:         /d  filespan:  10
  file:         /f  filespan:  10
  file:         /h  filespan:  10
  file:         /i  filespan:  21
               avg  filespan:  12.20

span: directories
  dir:           /  dirspan:  22
               avg  dirspan:  22.00
```

### 9

执行 [in.fragmented](file-ffs/in.fragmented) 中的指令
- `-C 2`：尝试确保每个文件连续分配 2 个数据块
- 创建 8 个大小为 1 的文件
  - 大小为 1 直接分配，不需要使用 2 个连续的数据块
- 删除其中的 4 个文件
  - 中间空出来 4 个不连续的数据块
- 创建 1 个大小为 8 的文件
    - 中间的空闲数据块都不连续（只有一个），因此放置在后面（连续 8 个数据块）

```bash
./ffs.py  -f in.fragmented -C 2 -T -M -B -S -v -c

# 输出
op create /a [size:1] ->success
op create /b [size:1] ->success
op create /c [size:1] ->success
op create /d [size:1] ->success
op create /e [size:1] ->success
op create /f [size:1] ->success
op create /g [size:1] ->success
op create /h [size:1] ->success
op delete /a ->success
op delete /c ->success
op delete /e ->success
op delete /g ->success
op create /i [size:8] ->success

num_groups:       10
inodes_per_group: 10
blocks_per_group: 30

free data blocks: 287 (of 300)
free inodes:      94 (of 100)

spread inodes?    False
spread data?      False
contig alloc:     2

     00000000000000000000 1111111111 2222222222
     01234567890123456789 0123456789 0123456789

group inodes    data
    0 /ib-d-f-h- /-b-d-f-hi iiiiiii--- ----------  [   0-  39]
    1 ---------- ---------- ---------- ----------  [  40-  79]
    2 ---------- ---------- ---------- ----------  [  80- 119]
    3 ---------- ---------- ---------- ----------  [ 120- 159]
    4 ---------- ---------- ---------- ----------  [ 160- 199]
    5 ---------- ---------- ---------- ----------  [ 200- 239]
    6 ---------- ---------- ---------- ----------  [ 240- 279]
    7 ---------- ---------- ---------- ----------  [ 280- 319]
    8 ---------- ---------- ---------- ----------  [ 320- 359]
    9 ---------- ---------- ---------- ----------  [ 360- 399]

symbol  inode#  filename     filetype   block_addresses
/            0  /            directory  0 
b            2  /b           regular    2 
d            4  /d           regular    4 
f            6  /f           regular    6 
h            8  /h           regular    8 
i            1  /i           regular    9 10 11 12 13 14 15 16 

span: files
  file:         /b  filespan:  10
  file:         /d  filespan:  10
  file:         /f  filespan:  10
  file:         /h  filespan:  10
  file:         /i  filespan:  25
               avg  filespan:  13.00

span: directories
  dir:           /  dirspan:  26
               avg  dirspan:  26.00
```