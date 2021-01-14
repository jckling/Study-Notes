## 43 Log-structured File System (LFS)

模拟日志结构文件系统（Log-structured File System, LFS）

```python
# 随机种子，默认为 0
parser.add_option('-s', '--seed', default=0, help='the random seed', action='store', type='int', dest='seed')
# 执行操作后不强制更新检查点，默认更新
parser.add_option('-N', '--no_force', help='Do not force checkpoint writes after updates', default=False, action='store_true', dest='no_force_checkpoints')
# 不打印文件系统的最终状态，默认打印
parser.add_option('-F', '--no_final', help='Do not show the final state of the file system', default=False, action='store_true', dest='no_final')
# 使用磁盘版本的检查点区域，默认不使用
parser.add_option('-D', '--use_disk_cr', help='use disk (maybe old) version of checkpoint region', default=False, action='store_true', dest='use_disk_cr')
# 计算结果
parser.add_option('-c', '--compute', help='compute answers for me', action='store_true', default=False, dest='solve')
# 打印操作，默认不打印
parser.add_option('-o', '--show_operations', help='print out operations as they occur', action='store_true', default=False, dest='show_operations')
# 打印状态变化，默认不打印
parser.add_option('-i', '--show_intermediate', help='print out state changes as they occur', action='store_true', default=False, dest='show_intermediate')
# 打印错误/返回码，默认不打印
parser.add_option('-e', '--show_return_codes', help='show error/return codes', action='store_true', default=False, dest='show_return_codes')
# 打印活块
parser.add_option('-v', '--show_live_paths', help='show live paths', action='store_true', default=False, dest='show_live_paths')
# 随机操作序列的数量
parser.add_option('-n', '--num_commands', help='generate N random commands', action='store', default=3, dest='num_commands')
# 创建文件，写入文件，创建目录，删除文件，链接文件，同步的概率
parser.add_option('-p', '--percentages', help='percent chance of: createfile,writefile,createdir,rmfile,linkfile,sync (example is c30,w30,d10,r20,l10,s0)', action='store', default='c30,w30,d10,r20,l10,s0', dest='percentages')
# 索引节点分配策略，默认顺序分配
parser.add_option('-a', '--allocation_policy', help='inode allocation policy: "r" for "random" or "s" for "sequential"', action='store', default='s', dest='inode_policy')
# 指定操作序列
parser.add_option('-L', '--command_list', default = '', action='store', type='str', dest='command_list', help='command list in format: "cmd1,arg1,...,argN:cmd2,arg1,...,argN:... where cmds are: c:createfile, d:createdir, r:delete, w:write, l:link, s:sync format: c,filepath d,dirpath r,filepath w,filepath,offset,numblks l,srcpath,dstpath s')
```

随机产生一个操作（`-n 1`）
- 检查点区域位于地址为 0 的块，大小为一个块的大小
- 一共有 16 个 inode 映射块，每个块有 16 个映射
  - inode 编号一共 16 * 16 = 256 个

```bash
./lfs.py -n 1 -o -i -v -c

# 输出
INITIAL file system contents:   <--- 初始文件系统状态
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- --     检查点区域，inode 映射块的位置
[   1 ] live [.,0] [..,0] -- -- -- -- -- --                                 根目录内容：[名称, inode 编号]
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- --            根目录：[类型, 大小, 引用计数, 块地址]
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- --    inode 映射块，第一块第一个编号为 0

create file /ku3    <--- 创建文件

[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   4 ] live [.,0] [..,0] [ku3,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 



FINAL file system contents:     <--- 最终文件系统状态
[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- --     （新）检查点区域
[   1 ]      [.,0] [..,0] -- -- -- -- -- --                                 （旧）根目录内容
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- --            （旧）根目录
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- --    （旧）inode 映射块
[   4 ] live [.,0] [..,0] [ku3,1] -- -- -- -- --                            根目录内容
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- --            根目录
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- --           文件
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- --     inode 映射块

Live directories:  []
Live files:  ['/ku3']
```

### 1/2

随机产生 3 个操作（`-n 3`）
- 创建文件 `/ku3`：inode 地址为 6，无数据地址
  - 根目录：inode 地址更新为 5，数据地址更新为 4
- 写入文件 `/ku3`：inode 地址更新为 9，数据地址更新为 8
- 创建文件 `/qg9`：inode 地址为 13，无数据地址
  - 根目录：inode 地址更新为 12，数据地址更新为 11

根目录 inode 地址：2 -> 5 -> 5 -> 12
检查点区域指向的 inode 块地址：3 -> 7 -> 10 -> 14

```bash
./lfs.py -n 3 -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create file /ku3    <--- 创建文件

[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   4 ] live [.,0] [..,0] [ku3,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /ku3 offset=7 size=4    <--- 写入大小为 4 的数据

[   0 ] live checkpoint: 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   8 ] live z0z0z0z0z0z0z0z0z0z0z0z0z0z0z0z0
[   9 ] live type:reg size:8 refs:1 ptrs: -- -- -- -- -- -- -- 8 
[  10 ] live chunk(imap): 5 9 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


create file /qg9    <--- 创建文件

[   0 ] live checkpoint: 14 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  11 ] live [.,0] [..,0] [ku3,1] [qg9,2] -- -- -- -- 
[  12 ] live type:dir size:1 refs:2 ptrs: 11 -- -- -- -- -- -- -- 
[  13 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  14 ] live chunk(imap): 12 9 13 -- -- -- -- -- -- -- -- -- -- -- -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 14 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ]      [.,0] [..,0] [ku3,1] -- -- -- -- -- 
[   5 ]      type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ]      type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ]      chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   8 ] live z0z0z0z0z0z0z0z0z0z0z0z0z0z0z0z0
[   9 ] live type:reg size:8 refs:1 ptrs: -- -- -- -- -- -- -- 8 
[  10 ]      chunk(imap): 5 9 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  11 ] live [.,0] [..,0] [ku3,1] [qg9,2] -- -- -- -- 
[  12 ] live type:dir size:1 refs:2 ptrs: 11 -- -- -- -- -- -- -- 
[  13 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  14 ] live chunk(imap): 12 9 13 -- -- -- -- -- -- -- -- -- -- -- -- -- 

Live directories:  []
Live files:  ['/ku3', '/qg9']
```

### 3

使用随机数种子 100（`-s 100`）
- 创建文件 `/us7`：inode 地址为 6，无数据地址
  - 根目录：inode 地址更新为 5，数据地址更新为 4
- 写入文件 `/us7` (offset=4 size=0)：inode 地址更新为 8
- 写入文件 `/us7` (offset=7 size=7)：inode 地址更新为 11，数据地址更新为 10

根目录 inode 地址：2 -> 5 -> 5 -> 5
检查点区域指向的 inode 块地址：3 -> 7 -> 9 -> 12

```bash
./lfs.py -s 100 -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create file /us7    <--- 创建文件

[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   4 ] live [.,0] [..,0] [us7,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /us7 offset=4 size=0    <--- 写入大小为 0 的数据

[   0 ] live checkpoint: 9 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   8 ] live type:reg size:4 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   9 ] live chunk(imap): 5 8 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /us7 offset=7 size=7    <--- 写入大小为 7 的数据

[   0 ] live checkpoint: 12 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  10 ] live i0i0i0i0i0i0i0i0i0i0i0i0i0i0i0i0
[  11 ] live type:reg size:8 refs:1 ptrs: -- -- -- -- -- -- -- 10 
[  12 ] live chunk(imap): 5 11 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 12 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ] live [.,0] [..,0] [us7,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ]      type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ]      chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   8 ]      type:reg size:4 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   9 ]      chunk(imap): 5 8 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  10 ] live i0i0i0i0i0i0i0i0i0i0i0i0i0i0i0i0
[  11 ] live type:reg size:8 refs:1 ptrs: -- -- -- -- -- -- -- 10 
[  12 ] live chunk(imap): 5 11 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

Live directories:  []
Live files:  ['/us7']
```

### 4

使用随机种子 1 （`-s 1`）产生 2 0 个操作（`-n 20`）
- 创建文件 `/tg4`：inode 地址为 6，无数据地址
  - 根目录：inode 地址更新为 5，数据地址更新为 4
- 写入文件 `/tg4` (offset=6 size=0)：inode 地址更新为 8
- 创建文件 `/lt0`：inode 地址为 12，无数据地址
  - 根目录：inode 地址更新为 11，数据地址更新为 10
- 写入文件 `/lt0` (offset=1 size=7)：inode 地址为更新 21，数据地址更新为 14 15 16 17 18 19 20 
- **创建硬链接 `/tg4 - /oy3`**
  - 文件 `/tg4`：inode 地址更新为 25
  - 根目录：inode 地址更新为 24，数据地址更新为 23
- 创建文件 `/af4`：inode 地址为 29，无数据地址
- 写入文件 `/tg4` (offset=1 size=1)：inode 地址更新为 32，数据地址更新为 31
- 写入文件 `/lt0` (offset=0 size=6)：inode 地址更新为 40，数据地址更新为 34 35 36 37 38 39 19 20
- 写入文件 `/oy3` (offset=1 size=7)：inode 地址更新为 49，数据地址更新为 42 43 44 45 46 47 48
- 删除文件 `/tg4`
  - 根目录：inode 地址更新为 52，数据地址更新为 51
  - 文件 `/oy3`：inode 地址更新为 53
- 写入文件 `/af4` (offset=5 size=7)：inode 地址更新为 58，数据地址更新为 55 56 57
- 写入文件 `/af4` (offset=5 size=2)：inode 地址更新为 62，数据地址更新为 60 61 57
- 写入文件 `/af4` (offset=6 size=4)：inode 地址更新为 66，数据地址更新为 60 64 65
- 写入文件 `/lt0` (offset=1 size=6)：inode 地址更新为 74，数据地址更新为 34 68 69 70 71 72 73 20
- 写入文件 `/lt0` (offset=4 size=5)：inode 地址更新为 80，数据地址更新为 34 68 69 70 76 77 78 79
- 创建目录 `ln7`：inode 地址为 85，数据地址为 83
  - 根目录：inode 地址更新为 84，数据地址为 82
- 写入文件 `/oy3` (offset=3 size=0)：inode 地址更新为 87
- 创建文件 `/ln7/zp3`：inode 地址为 91，无数据地址
  - 目录 `/ln7`：inode 地址更新为 90，数据地址更新为 89
- 创建文件 `/ln7/zu5`：inode 地址为 95，无数据地址
  - 目录 `/ln7`：inode 地址更新为 94，数据地址更新为 93
- 删除文件 `/oy3`（`/tg4`）
  - 根目录：inode 地址更新为 98，数据地址更新为 97

```bash
./lfs.py -s 1 -n 20 -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create file /tg4    <--- 创建文件

[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   4 ] live [.,0] [..,0] [tg4,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /tg4 offset=6 size=0    <--- 写入大小为 0 的数据

[   0 ] live checkpoint: 9 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   8 ] live type:reg size:6 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   9 ] live chunk(imap): 5 8 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


create file /lt0    <--- 创建文件

[   0 ] live checkpoint: 13 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  10 ] live [.,0] [..,0] [tg4,1] [lt0,2] -- -- -- -- 
[  11 ] live type:dir size:1 refs:2 ptrs: 10 -- -- -- -- -- -- -- 
[  12 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  13 ] live chunk(imap): 11 8 12 -- -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /lt0 offset=1 size=7    <--- 写入大小为 7 的数据

[   0 ] live checkpoint: 22 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  14 ] live n0n0n0n0n0n0n0n0n0n0n0n0n0n0n0n0
[  15 ] live y1y1y1y1y1y1y1y1y1y1y1y1y1y1y1y1
[  16 ] live p2p2p2p2p2p2p2p2p2p2p2p2p2p2p2p2
[  17 ] live l3l3l3l3l3l3l3l3l3l3l3l3l3l3l3l3
[  18 ] live h4h4h4h4h4h4h4h4h4h4h4h4h4h4h4h4
[  19 ] live o5o5o5o5o5o5o5o5o5o5o5o5o5o5o5o5
[  20 ] live y6y6y6y6y6y6y6y6y6y6y6y6y6y6y6y6
[  21 ] live type:reg size:8 refs:1 ptrs: -- 14 15 16 17 18 19 20 
[  22 ] live chunk(imap): 11 8 21 -- -- -- -- -- -- -- -- -- -- -- -- -- 


link file   /tg4 /oy3   <--- 创建硬链接

[   0 ] live checkpoint: 26 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  23 ] live [.,0] [..,0] [tg4,1] [lt0,2] [oy3,1] -- -- -- 
[  24 ] live type:dir size:1 refs:2 ptrs: 23 -- -- -- -- -- -- -- 
[  25 ] live type:reg size:6 refs:2 ptrs: -- -- -- -- -- -- -- -- 
[  26 ] live chunk(imap): 24 25 21 -- -- -- -- -- -- -- -- -- -- -- -- -- 


create file /af4    <--- 创建文件

[   0 ] live checkpoint: 30 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  27 ] live [.,0] [..,0] [tg4,1] [lt0,2] [oy3,1] [af4,3] -- -- 
[  28 ] live type:dir size:1 refs:2 ptrs: 27 -- -- -- -- -- -- -- 
[  29 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  30 ] live chunk(imap): 28 25 21 29 -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /tg4 offset=1 size=1    <--- 写入大小为 1 的数据

[   0 ] live checkpoint: 33 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  31 ] live a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0
[  32 ] live type:reg size:6 refs:2 ptrs: -- 31 -- -- -- -- -- -- 
[  33 ] live chunk(imap): 28 32 21 29 -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /lt0 offset=0 size=6    <--- 写入大小为 6 的数据

[   0 ] live checkpoint: 41 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  34 ] live u0u0u0u0u0u0u0u0u0u0u0u0u0u0u0u0
[  35 ] live v1v1v1v1v1v1v1v1v1v1v1v1v1v1v1v1
[  36 ] live x2x2x2x2x2x2x2x2x2x2x2x2x2x2x2x2
[  37 ] live t3t3t3t3t3t3t3t3t3t3t3t3t3t3t3t3
[  38 ] live v4v4v4v4v4v4v4v4v4v4v4v4v4v4v4v4
[  39 ] live n5n5n5n5n5n5n5n5n5n5n5n5n5n5n5n5
[  40 ] live type:reg size:8 refs:1 ptrs: 34 35 36 37 38 39 19 20 
[  41 ] live chunk(imap): 28 32 40 29 -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /oy3 offset=1 size=7    <--- 写入大小为 7 的数据

[   0 ] live checkpoint: 50 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  42 ] live o0o0o0o0o0o0o0o0o0o0o0o0o0o0o0o0
[  43 ] live l1l1l1l1l1l1l1l1l1l1l1l1l1l1l1l1
[  44 ] live b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2
[  45 ] live w3w3w3w3w3w3w3w3w3w3w3w3w3w3w3w3
[  46 ] live o4o4o4o4o4o4o4o4o4o4o4o4o4o4o4o4
[  47 ] live f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5
[  48 ] live n6n6n6n6n6n6n6n6n6n6n6n6n6n6n6n6
[  49 ] live type:reg size:8 refs:2 ptrs: -- 42 43 44 45 46 47 48 
[  50 ] live chunk(imap): 28 49 40 29 -- -- -- -- -- -- -- -- -- -- -- -- 


delete file /tg4    <--- 删除文件

[   0 ] live checkpoint: 54 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  51 ] live [.,0] [..,0] -- [lt0,2] [oy3,1] [af4,3] -- -- 
[  52 ] live type:dir size:1 refs:2 ptrs: 51 -- -- -- -- -- -- -- 
[  53 ] live type:reg size:8 refs:1 ptrs: -- 42 43 44 45 46 47 48 
[  54 ] live chunk(imap): 52 53 40 29 -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /af4 offset=5 size=7    <--- 写入大小为 7 的数据

[   0 ] live checkpoint: 59 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  55 ] live m0m0m0m0m0m0m0m0m0m0m0m0m0m0m0m0
[  56 ] live j1j1j1j1j1j1j1j1j1j1j1j1j1j1j1j1
[  57 ] live i2i2i2i2i2i2i2i2i2i2i2i2i2i2i2i2
[  58 ] live type:reg size:8 refs:1 ptrs: -- -- -- -- -- 55 56 57 
[  59 ] live chunk(imap): 52 53 40 58 -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /af4 offset=5 size=2    <--- 写入大小为 2 的数据

[   0 ] live checkpoint: 63 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  60 ] live a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0
[  61 ] live f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
[  62 ] live type:reg size:8 refs:1 ptrs: -- -- -- -- -- 60 61 57 
[  63 ] live chunk(imap): 52 53 40 62 -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /af4 offset=6 size=4    <--- 写入大小为 4 的数据

[   0 ] live checkpoint: 67 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  64 ] live e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0
[  65 ] live p1p1p1p1p1p1p1p1p1p1p1p1p1p1p1p1
[  66 ] live type:reg size:8 refs:1 ptrs: -- -- -- -- -- 60 64 65 
[  67 ] live chunk(imap): 52 53 40 66 -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /lt0 offset=1 size=6    <--- 写入大小为 6 的数据

[   0 ] live checkpoint: 75 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  68 ] live u0u0u0u0u0u0u0u0u0u0u0u0u0u0u0u0
[  69 ] live v1v1v1v1v1v1v1v1v1v1v1v1v1v1v1v1
[  70 ] live g2g2g2g2g2g2g2g2g2g2g2g2g2g2g2g2
[  71 ] live v3v3v3v3v3v3v3v3v3v3v3v3v3v3v3v3
[  72 ] live r4r4r4r4r4r4r4r4r4r4r4r4r4r4r4r4
[  73 ] live c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5
[  74 ] live type:reg size:8 refs:1 ptrs: 34 68 69 70 71 72 73 20 
[  75 ] live chunk(imap): 52 53 74 66 -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /lt0 offset=4 size=5    <--- 写入大小为 5 的数据

[   0 ] live checkpoint: 81 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  76 ] live a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0
[  77 ] live a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1
[  78 ] live t2t2t2t2t2t2t2t2t2t2t2t2t2t2t2t2
[  79 ] live g3g3g3g3g3g3g3g3g3g3g3g3g3g3g3g3
[  80 ] live type:reg size:8 refs:1 ptrs: 34 68 69 70 76 77 78 79 
[  81 ] live chunk(imap): 52 53 80 66 -- -- -- -- -- -- -- -- -- -- -- -- 


create dir  /ln7    <--- 创建目录

[   0 ] live checkpoint: 86 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  82 ] live [.,0] [..,0] [ln7,4] [lt0,2] [oy3,1] [af4,3] -- -- 
[  83 ] live [.,4] [..,0] -- -- -- -- -- -- 
[  84 ] live type:dir size:1 refs:3 ptrs: 82 -- -- -- -- -- -- -- 
[  85 ] live type:dir size:1 refs:2 ptrs: 83 -- -- -- -- -- -- -- 
[  86 ] live chunk(imap): 84 53 80 66 85 -- -- -- -- -- -- -- -- -- -- -- 


write file  /oy3 offset=3 size=0    <--- 写入大小为 0 的数据

[   0 ] live checkpoint: 88 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  87 ] live type:reg size:8 refs:1 ptrs: -- 42 43 44 45 46 47 48 
[  88 ] live chunk(imap): 84 87 80 66 85 -- -- -- -- -- -- -- -- -- -- -- 


create file /ln7/zp3    <--- 创建文件

[   0 ] live checkpoint: 92 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  89 ] live [.,4] [..,0] [zp3,5] -- -- -- -- -- 
[  90 ] live type:dir size:1 refs:2 ptrs: 89 -- -- -- -- -- -- -- 
[  91 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  92 ] live chunk(imap): 84 87 80 66 90 91 -- -- -- -- -- -- -- -- -- -- 


create file /ln7/zu5    <--- 创建文件

[   0 ] live checkpoint: 96 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  93 ] live [.,4] [..,0] [zp3,5] [zu5,6] -- -- -- -- 
[  94 ] live type:dir size:1 refs:2 ptrs: 93 -- -- -- -- -- -- -- 
[  95 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  96 ] live chunk(imap): 84 87 80 66 94 91 95 -- -- -- -- -- -- -- -- -- 


delete file /oy3    <--- 删除文件

[   0 ] live checkpoint: 99 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  97 ] live [.,0] [..,0] [ln7,4] [lt0,2] -- [af4,3] -- -- 
[  98 ] live type:dir size:1 refs:3 ptrs: 97 -- -- -- -- -- -- -- 
[  99 ] live chunk(imap): 98 -- 80 66 94 91 95 -- -- -- -- -- -- -- -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 99 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ]      [.,0] [..,0] [tg4,1] -- -- -- -- -- 
[   5 ]      type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ]      type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ]      chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   8 ]      type:reg size:6 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   9 ]      chunk(imap): 5 8 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  10 ]      [.,0] [..,0] [tg4,1] [lt0,2] -- -- -- -- 
[  11 ]      type:dir size:1 refs:2 ptrs: 10 -- -- -- -- -- -- -- 
[  12 ]      type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  13 ]      chunk(imap): 11 8 12 -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  14 ]      n0n0n0n0n0n0n0n0n0n0n0n0n0n0n0n0
[  15 ]      y1y1y1y1y1y1y1y1y1y1y1y1y1y1y1y1
[  16 ]      p2p2p2p2p2p2p2p2p2p2p2p2p2p2p2p2
[  17 ]      l3l3l3l3l3l3l3l3l3l3l3l3l3l3l3l3
[  18 ]      h4h4h4h4h4h4h4h4h4h4h4h4h4h4h4h4
[  19 ]      o5o5o5o5o5o5o5o5o5o5o5o5o5o5o5o5
[  20 ]      y6y6y6y6y6y6y6y6y6y6y6y6y6y6y6y6
[  21 ]      type:reg size:8 refs:1 ptrs: -- 14 15 16 17 18 19 20 
[  22 ]      chunk(imap): 11 8 21 -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  23 ]      [.,0] [..,0] [tg4,1] [lt0,2] [oy3,1] -- -- -- 
[  24 ]      type:dir size:1 refs:2 ptrs: 23 -- -- -- -- -- -- -- 
[  25 ]      type:reg size:6 refs:2 ptrs: -- -- -- -- -- -- -- -- 
[  26 ]      chunk(imap): 24 25 21 -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  27 ]      [.,0] [..,0] [tg4,1] [lt0,2] [oy3,1] [af4,3] -- -- 
[  28 ]      type:dir size:1 refs:2 ptrs: 27 -- -- -- -- -- -- -- 
[  29 ]      type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  30 ]      chunk(imap): 28 25 21 29 -- -- -- -- -- -- -- -- -- -- -- -- 
[  31 ]      a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0
[  32 ]      type:reg size:6 refs:2 ptrs: -- 31 -- -- -- -- -- -- 
[  33 ]      chunk(imap): 28 32 21 29 -- -- -- -- -- -- -- -- -- -- -- -- 
[  34 ] live u0u0u0u0u0u0u0u0u0u0u0u0u0u0u0u0
[  35 ]      v1v1v1v1v1v1v1v1v1v1v1v1v1v1v1v1
[  36 ]      x2x2x2x2x2x2x2x2x2x2x2x2x2x2x2x2
[  37 ]      t3t3t3t3t3t3t3t3t3t3t3t3t3t3t3t3
[  38 ]      v4v4v4v4v4v4v4v4v4v4v4v4v4v4v4v4
[  39 ]      n5n5n5n5n5n5n5n5n5n5n5n5n5n5n5n5
[  40 ]      type:reg size:8 refs:1 ptrs: 34 35 36 37 38 39 19 20 
[  41 ]      chunk(imap): 28 32 40 29 -- -- -- -- -- -- -- -- -- -- -- -- 
[  42 ]      o0o0o0o0o0o0o0o0o0o0o0o0o0o0o0o0
[  43 ]      l1l1l1l1l1l1l1l1l1l1l1l1l1l1l1l1
[  44 ]      b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2
[  45 ]      w3w3w3w3w3w3w3w3w3w3w3w3w3w3w3w3
[  46 ]      o4o4o4o4o4o4o4o4o4o4o4o4o4o4o4o4
[  47 ]      f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5
[  48 ]      n6n6n6n6n6n6n6n6n6n6n6n6n6n6n6n6
[  49 ]      type:reg size:8 refs:2 ptrs: -- 42 43 44 45 46 47 48 
[  50 ]      chunk(imap): 28 49 40 29 -- -- -- -- -- -- -- -- -- -- -- -- 
[  51 ]      [.,0] [..,0] -- [lt0,2] [oy3,1] [af4,3] -- -- 
[  52 ]      type:dir size:1 refs:2 ptrs: 51 -- -- -- -- -- -- -- 
[  53 ]      type:reg size:8 refs:1 ptrs: -- 42 43 44 45 46 47 48 
[  54 ]      chunk(imap): 52 53 40 29 -- -- -- -- -- -- -- -- -- -- -- -- 
[  55 ]      m0m0m0m0m0m0m0m0m0m0m0m0m0m0m0m0
[  56 ]      j1j1j1j1j1j1j1j1j1j1j1j1j1j1j1j1
[  57 ]      i2i2i2i2i2i2i2i2i2i2i2i2i2i2i2i2
[  58 ]      type:reg size:8 refs:1 ptrs: -- -- -- -- -- 55 56 57 
[  59 ]      chunk(imap): 52 53 40 58 -- -- -- -- -- -- -- -- -- -- -- -- 
[  60 ] live a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0
[  61 ]      f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
[  62 ]      type:reg size:8 refs:1 ptrs: -- -- -- -- -- 60 61 57 
[  63 ]      chunk(imap): 52 53 40 62 -- -- -- -- -- -- -- -- -- -- -- -- 
[  64 ] live e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0
[  65 ] live p1p1p1p1p1p1p1p1p1p1p1p1p1p1p1p1
[  66 ] live type:reg size:8 refs:1 ptrs: -- -- -- -- -- 60 64 65 
[  67 ]      chunk(imap): 52 53 40 66 -- -- -- -- -- -- -- -- -- -- -- -- 
[  68 ] live u0u0u0u0u0u0u0u0u0u0u0u0u0u0u0u0
[  69 ] live v1v1v1v1v1v1v1v1v1v1v1v1v1v1v1v1
[  70 ] live g2g2g2g2g2g2g2g2g2g2g2g2g2g2g2g2
[  71 ]      v3v3v3v3v3v3v3v3v3v3v3v3v3v3v3v3
[  72 ]      r4r4r4r4r4r4r4r4r4r4r4r4r4r4r4r4
[  73 ]      c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5
[  74 ]      type:reg size:8 refs:1 ptrs: 34 68 69 70 71 72 73 20 
[  75 ]      chunk(imap): 52 53 74 66 -- -- -- -- -- -- -- -- -- -- -- -- 
[  76 ] live a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0
[  77 ] live a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1
[  78 ] live t2t2t2t2t2t2t2t2t2t2t2t2t2t2t2t2
[  79 ] live g3g3g3g3g3g3g3g3g3g3g3g3g3g3g3g3
[  80 ] live type:reg size:8 refs:1 ptrs: 34 68 69 70 76 77 78 79 
[  81 ]      chunk(imap): 52 53 80 66 -- -- -- -- -- -- -- -- -- -- -- -- 
[  82 ]      [.,0] [..,0] [ln7,4] [lt0,2] [oy3,1] [af4,3] -- -- 
[  83 ]      [.,4] [..,0] -- -- -- -- -- -- 
[  84 ]      type:dir size:1 refs:3 ptrs: 82 -- -- -- -- -- -- -- 
[  85 ]      type:dir size:1 refs:2 ptrs: 83 -- -- -- -- -- -- -- 
[  86 ]      chunk(imap): 84 53 80 66 85 -- -- -- -- -- -- -- -- -- -- -- 
[  87 ]      type:reg size:8 refs:1 ptrs: -- 42 43 44 45 46 47 48 
[  88 ]      chunk(imap): 84 87 80 66 85 -- -- -- -- -- -- -- -- -- -- -- 
[  89 ]      [.,4] [..,0] [zp3,5] -- -- -- -- -- 
[  90 ]      type:dir size:1 refs:2 ptrs: 89 -- -- -- -- -- -- -- 
[  91 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  92 ]      chunk(imap): 84 87 80 66 90 91 -- -- -- -- -- -- -- -- -- -- 
[  93 ] live [.,4] [..,0] [zp3,5] [zu5,6] -- -- -- -- 
[  94 ] live type:dir size:1 refs:2 ptrs: 93 -- -- -- -- -- -- -- 
[  95 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  96 ]      chunk(imap): 84 87 80 66 94 91 95 -- -- -- -- -- -- -- -- -- 
[  97 ] live [.,0] [..,0] [ln7,4] [lt0,2] -- [af4,3] -- -- 
[  98 ] live type:dir size:1 refs:3 ptrs: 97 -- -- -- -- -- -- -- 
[  99 ] live chunk(imap): 98 -- 80 66 94 91 95 -- -- -- -- -- -- -- -- -- 

Live directories:  ['/ln7']
Live files:  ['/lt0', '/af4', '/ln7/zp3', '/ln7/zu5']
```

### 5

创建大小为 4 的文件，指定 5 个操作（`-L`），每次写入大小为 1 的数据
- 创建文件 `/foo`：inode 地址为 6，无数据地址
  - 根目录：inode 地址更新为 5，数据地址更新为 4
- 写入文件 `/foo` (offset=0 size=1)：inode 地址更新为 9，数据地址更新为 8
- 写入文件 `/foo` (offset=1 size=1)：inode 地址更新为 12，数据地址更新为 8 11
- 写入文件 `/foo` (offset=2 size=1)：inode 地址更新为 15，数据地址更新为 8 11 14
- 写入文件 `/foo` (offset=3 size=1)：inode 地址更新为 18，数据地址更新为 8 11 14 17

```bash
./lfs.py -L c,/foo:w,/foo,0,1:w,/foo,1,1:w,/foo,2,1:w,/foo,3,1 -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create file /foo    <--- 创建文件

[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /foo offset=0 size=1    <--- 写入大小为 1 的数据

[   0 ] live checkpoint: 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   8 ] live v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0
[   9 ] live type:reg size:1 refs:1 ptrs: 8 -- -- -- -- -- -- -- 
[  10 ] live chunk(imap): 5 9 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /foo offset=1 size=1    <--- 写入大小为 1 的数据

[   0 ] live checkpoint: 13 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  11 ] live t0t0t0t0t0t0t0t0t0t0t0t0t0t0t0t0
[  12 ] live type:reg size:2 refs:1 ptrs: 8 11 -- -- -- -- -- -- 
[  13 ] live chunk(imap): 5 12 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /foo offset=2 size=1    <--- 写入大小为 1 的数据

[   0 ] live checkpoint: 16 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  14 ] live k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0
[  15 ] live type:reg size:3 refs:1 ptrs: 8 11 14 -- -- -- -- -- 
[  16 ] live chunk(imap): 5 15 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /foo offset=3 size=1    <--- 写入大小为 1 的数据

[   0 ] live checkpoint: 19 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  17 ] live g0g0g0g0g0g0g0g0g0g0g0g0g0g0g0g0
[  18 ] live type:reg size:4 refs:1 ptrs: 8 11 14 17 -- -- -- -- 
[  19 ] live chunk(imap): 5 18 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 19 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ]      type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ]      chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   8 ] live v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0
[   9 ]      type:reg size:1 refs:1 ptrs: 8 -- -- -- -- -- -- -- 
[  10 ]      chunk(imap): 5 9 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  11 ] live t0t0t0t0t0t0t0t0t0t0t0t0t0t0t0t0
[  12 ]      type:reg size:2 refs:1 ptrs: 8 11 -- -- -- -- -- -- 
[  13 ]      chunk(imap): 5 12 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  14 ] live k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0
[  15 ]      type:reg size:3 refs:1 ptrs: 8 11 14 -- -- -- -- -- 
[  16 ]      chunk(imap): 5 15 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  17 ] live g0g0g0g0g0g0g0g0g0g0g0g0g0g0g0g0
[  18 ] live type:reg size:4 refs:1 ptrs: 8 11 14 17 -- -- -- -- 
[  19 ] live chunk(imap): 5 18 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

Live directories:  []
Live files:  ['/foo']
```

### 6

创建大小为 4 的文件，指定 2 个操作（`-L`），一次性写入大小为 4 的数据
- 创建文件 `/foo`：inode 地址为 6，无数据地址
  - 根目录：inode 地址更新为 5，数据地址更新为 4
- 写入文件 `/foo` (offset=0 size=4)：inode 地址更新为 12，数据地址更新为 8 9 10 11

和 5 相比，一次性写入只需要更新一次 inode 地址。

```bash
./lfs.py -L c,/foo:w,/foo,0,4 -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create file /foo    <--- 创建文件

[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /foo offset=0 size=4    <--- 写入大小为 4 的数据

[   0 ] live checkpoint: 13 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   8 ] live v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0
[   9 ] live t1t1t1t1t1t1t1t1t1t1t1t1t1t1t1t1
[  10 ] live k2k2k2k2k2k2k2k2k2k2k2k2k2k2k2k2
[  11 ] live g3g3g3g3g3g3g3g3g3g3g3g3g3g3g3g3
[  12 ] live type:reg size:4 refs:1 ptrs: 8 9 10 11 -- -- -- -- 
[  13 ] live chunk(imap): 5 12 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 13 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ]      type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ]      chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   8 ] live v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0
[   9 ] live t1t1t1t1t1t1t1t1t1t1t1t1t1t1t1t1
[  10 ] live k2k2k2k2k2k2k2k2k2k2k2k2k2k2k2k2
[  11 ] live g3g3g3g3g3g3g3g3g3g3g3g3g3g3g3g3
[  12 ] live type:reg size:4 refs:1 ptrs: 8 9 10 11 -- -- -- -- 
[  13 ] live chunk(imap): 5 12 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

Live directories:  []
Live files:  ['/foo']
```

### 7

创建大小为 1 的文件，从偏移 0 开始写入，指定 2 个操作（`-L`）
- 创建文件 `/foo`：inode 地址为 6，无数据地址
  - 根目录：inode 地址更新为 5，数据地址更新为 4
- 写入文件 `/foo` (offset=0 size=1)：inode 地址更新为 9，数据地址更新为 8

写入后大小为 1

```bash
./lfs.py -L c,/foo:w,/foo,0,1 -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create file /foo    <--- 创建文件

[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /foo offset=0 size=1    <--- 写入大小为 1 的数据

[   0 ] live checkpoint: 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   8 ] live v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0
[   9 ] live type:reg size:1 refs:1 ptrs: 8 -- -- -- -- -- -- -- 
[  10 ] live chunk(imap): 5 9 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ]      type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ]      chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   8 ] live v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0
[   9 ] live type:reg size:1 refs:1 ptrs: 8 -- -- -- -- -- -- -- 
[  10 ] live chunk(imap): 5 9 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

Live directories:  []
Live files:  ['/foo']
```

创建大小为 1 的文件，从偏移 7 开始写入，指定 2 个操作（`-L`）
- 创建文件 `/foo`：inode 地址为 6，无数据地址
- 写入文件 `/foo` (offset=7 size=1)：inode 地址更新为 9，数据地址更新为 8

写入后大小为 8

```bash
./lfs.py -L c,/foo:w,/foo,7,1 -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create file /foo    <--- 创建文件

[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


write file  /foo offset=7 size=1    <--- 写入大小为 1 的数据

[   0 ] live checkpoint: 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   8 ] live v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0
[   9 ] live type:reg size:8 refs:1 ptrs: -- -- -- -- -- -- -- 8 
[  10 ] live chunk(imap): 5 9 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ]      type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ]      chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   8 ] live v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0v0
[   9 ] live type:reg size:8 refs:1 ptrs: -- -- -- -- -- -- -- 8 
[  10 ] live chunk(imap): 5 9 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

Live directories:  []
Live files:  ['/foo']
```

### 8

指定操作（`-L`）**创建文件**
- 创建文件 `/foo`：inode 地址为 6，无数据地址
  - 根目录：inode 地址更新为 5，数据地址更新为 4

```bash
./lfs.py -L c,/foo -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create file /foo    <--- 创建文件

[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

Live directories:  []
Live files:  ['/foo']
```

指定操作（`-L`）**创建目录**
- 创建目录 `/foo`：inode 地址为 7，数据地址为 5
  - 根目录：inode 地址更新为 6，数据地址更新为 4

```bash
./lfs.py -L d,/foo -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create dir  /foo    <--- 创建目录

[   0 ] live checkpoint: 8 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live [.,1] [..,0] -- -- -- -- -- -- 
[   6 ] live type:dir size:1 refs:3 ptrs: 4 -- -- -- -- -- -- -- 
[   7 ] live type:dir size:1 refs:2 ptrs: 5 -- -- -- -- -- -- -- 
[   8 ] live chunk(imap): 6 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 8 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live [.,1] [..,0] -- -- -- -- -- -- 
[   6 ] live type:dir size:1 refs:3 ptrs: 4 -- -- -- -- -- -- -- 
[   7 ] live type:dir size:1 refs:2 ptrs: 5 -- -- -- -- -- -- -- 
[   8 ] live chunk(imap): 6 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

Live directories:  ['/foo']
Live files:  []
```

### 9

指定 2 个操作（`-L`）
- 创建文件 `/foo`：inode 地址为 6，无数据地址
  - 根目录：inode 地址更新为 5，数据地址更新为 4
- 创建硬链接 `/foo - /bar`
  - 文件 `/foo`：inode 地址为 10
  - 根目录：inode 地址更新为 9，数据地址更新为 8
- 创建硬链接 `/foo - /goo`
  - 文件 `/foo`：inode 地址更新为 14
  - 根目录：inode 地址更新为 13，数据地址更新为 12

```bash
./lfs.py -L c,/foo:l,/foo,/bar:l,/foo,/goo -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create file /foo    <--- 创建文件

[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   4 ] live [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


link file   /foo /bar   <--- 创建硬链接

[   0 ] live checkpoint: 11 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   8 ] live [.,0] [..,0] [foo,1] [bar,1] -- -- -- -- 
[   9 ] live type:dir size:1 refs:2 ptrs: 8 -- -- -- -- -- -- -- 
[  10 ] live type:reg size:0 refs:2 ptrs: -- -- -- -- -- -- -- -- 
[  11 ] live chunk(imap): 9 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


link file   /foo /goo   <--- 创建硬链接

[   0 ] live checkpoint: 15 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  12 ] live [.,0] [..,0] [foo,1] [bar,1] [goo,1] -- -- -- 
[  13 ] live type:dir size:1 refs:2 ptrs: 12 -- -- -- -- -- -- -- 
[  14 ] live type:reg size:0 refs:3 ptrs: -- -- -- -- -- -- -- -- 
[  15 ] live chunk(imap): 13 14 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 15 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ]      [.,0] [..,0] [foo,1] -- -- -- -- -- 
[   5 ]      type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ]      type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ]      chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   8 ]      [.,0] [..,0] [foo,1] [bar,1] -- -- -- -- 
[   9 ]      type:dir size:1 refs:2 ptrs: 8 -- -- -- -- -- -- -- 
[  10 ]      type:reg size:0 refs:2 ptrs: -- -- -- -- -- -- -- -- 
[  11 ]      chunk(imap): 9 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  12 ] live [.,0] [..,0] [foo,1] [bar,1] [goo,1] -- -- -- 
[  13 ] live type:dir size:1 refs:2 ptrs: 12 -- -- -- -- -- -- -- 
[  14 ] live type:reg size:0 refs:3 ptrs: -- -- -- -- -- -- -- -- 
[  15 ] live chunk(imap): 13 14 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

Live directories:  []
Live files:  ['/foo', '/bar', '/goo']
```

### 10

顺序分配索引节点（默认 `-a s`），随机操作全部为创建文件（`-p c100`）
- 创建文件 `/kg5`：inode 地址为 6，无数据地址
  - 根目录：inode 地址更新为 5，数据地址更新为 4
- 创建文件 `/hm5`：inode 地址为 10，无数据地址
  - 目录：inode 地址更新为 9，数据地址更新为 8
- 创建文件 `/ht6`：inode 地址为 14，无数据地址
  - 目录：inode 地址更新为 13，数据地址更新为 12
- 创建文件 `/zv9`：inode 地址为 18，无数据地址
  - 目录：inode 地址更新为 17，数据地址更新为 16
- 创建文件 `/xr4`：inode 地址为 22，无数据地址
  - 目录：inode 地址更新为 21，数据地址更新为 20
- 创建文件 `/px9`：inode 地址为 26，无数据地址
  - 目录：inode 地址更新为 25，数据地址更新为 24
- 创建文件 `/gu5`：inode 地址为 30，无数据地址
  - 目录：inode 地址更新为 29，数据地址更新为 24 28
- 创建文件 `/kv6`：inode 地址为 34，无数据地址
  - 目录：inode 地址更新为 33，数据地址更新为 24 32
- 创建文件 `/wg3`：inode 地址为 38，无数据地址
  - 目录：inode 地址更新为 37，数据地址更新为 24 36
- 创建文件 `/og9`：inode 地址为 42，无数据地址
  - 目录：inode 地址更新为 41，数据地址更新为 24 40

```bash
./lfs.py -p c100 -n 10 -a s -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create file /kg5    <--- 创建文件

[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   4 ] live [.,0] [..,0] [kg5,1] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


create file /hm5    <--- 创建文件

[   0 ] live checkpoint: 11 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[   8 ] live [.,0] [..,0] [kg5,1] [hm5,2] -- -- -- -- 
[   9 ] live type:dir size:1 refs:2 ptrs: 8 -- -- -- -- -- -- -- 
[  10 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  11 ] live chunk(imap): 9 6 10 -- -- -- -- -- -- -- -- -- -- -- -- -- 


create file /ht6    <--- 创建文件

[   0 ] live checkpoint: 15 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  12 ] live [.,0] [..,0] [kg5,1] [hm5,2] [ht6,3] -- -- -- 
[  13 ] live type:dir size:1 refs:2 ptrs: 12 -- -- -- -- -- -- -- 
[  14 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  15 ] live chunk(imap): 13 6 10 14 -- -- -- -- -- -- -- -- -- -- -- -- 


create file /zv9    <--- 创建文件

[   0 ] live checkpoint: 19 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  16 ] live [.,0] [..,0] [kg5,1] [hm5,2] [ht6,3] [zv9,4] -- -- 
[  17 ] live type:dir size:1 refs:2 ptrs: 16 -- -- -- -- -- -- -- 
[  18 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  19 ] live chunk(imap): 17 6 10 14 18 -- -- -- -- -- -- -- -- -- -- -- 


create file /xr4    <--- 创建文件

[   0 ] live checkpoint: 23 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  20 ] live [.,0] [..,0] [kg5,1] [hm5,2] [ht6,3] [zv9,4] [xr4,5] -- 
[  21 ] live type:dir size:1 refs:2 ptrs: 20 -- -- -- -- -- -- -- 
[  22 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  23 ] live chunk(imap): 21 6 10 14 18 22 -- -- -- -- -- -- -- -- -- -- 


create file /px9    <--- 创建文件

[   0 ] live checkpoint: 27 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  24 ] live [.,0] [..,0] [kg5,1] [hm5,2] [ht6,3] [zv9,4] [xr4,5] [px9,6] 
[  25 ] live type:dir size:1 refs:2 ptrs: 24 -- -- -- -- -- -- -- 
[  26 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  27 ] live chunk(imap): 25 6 10 14 18 22 26 -- -- -- -- -- -- -- -- -- 


create file /gu5    <--- 创建文件

[   0 ] live checkpoint: 31 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  28 ] live [gu5,7] -- -- -- -- -- -- -- 
[  29 ] live type:dir size:2 refs:2 ptrs: 24 28 -- -- -- -- -- -- 
[  30 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  31 ] live chunk(imap): 29 6 10 14 18 22 26 30 -- -- -- -- -- -- -- -- 


create file /kv6    <--- 创建文件

[   0 ] live checkpoint: 35 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  32 ] live [gu5,7] [kv6,8] -- -- -- -- -- -- 
[  33 ] live type:dir size:2 refs:2 ptrs: 24 32 -- -- -- -- -- -- 
[  34 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  35 ] live chunk(imap): 33 6 10 14 18 22 26 30 34 -- -- -- -- -- -- -- 


create file /wg3    <--- 创建文件

[   0 ] live checkpoint: 39 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  36 ] live [gu5,7] [kv6,8] [wg3,9] -- -- -- -- -- 
[  37 ] live type:dir size:2 refs:2 ptrs: 24 36 -- -- -- -- -- -- 
[  38 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  39 ] live chunk(imap): 37 6 10 14 18 22 26 30 34 38 -- -- -- -- -- -- 


create file /og9    <--- 创建文件

[   0 ] live checkpoint: 43 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
...
[  40 ] live [gu5,7] [kv6,8] [wg3,9] [og9,10] -- -- -- -- 
[  41 ] live type:dir size:2 refs:2 ptrs: 24 40 -- -- -- -- -- -- 
[  42 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  43 ] live chunk(imap): 41 6 10 14 18 22 26 30 34 38 42 -- -- -- -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 43 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ]      [.,0] [..,0] [kg5,1] -- -- -- -- -- 
[   5 ]      type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ]      chunk(imap): 5 6 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   8 ]      [.,0] [..,0] [kg5,1] [hm5,2] -- -- -- -- 
[   9 ]      type:dir size:1 refs:2 ptrs: 8 -- -- -- -- -- -- -- 
[  10 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  11 ]      chunk(imap): 9 6 10 -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  12 ]      [.,0] [..,0] [kg5,1] [hm5,2] [ht6,3] -- -- -- 
[  13 ]      type:dir size:1 refs:2 ptrs: 12 -- -- -- -- -- -- -- 
[  14 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  15 ]      chunk(imap): 13 6 10 14 -- -- -- -- -- -- -- -- -- -- -- -- 
[  16 ]      [.,0] [..,0] [kg5,1] [hm5,2] [ht6,3] [zv9,4] -- -- 
[  17 ]      type:dir size:1 refs:2 ptrs: 16 -- -- -- -- -- -- -- 
[  18 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  19 ]      chunk(imap): 17 6 10 14 18 -- -- -- -- -- -- -- -- -- -- -- 
[  20 ]      [.,0] [..,0] [kg5,1] [hm5,2] [ht6,3] [zv9,4] [xr4,5] -- 
[  21 ]      type:dir size:1 refs:2 ptrs: 20 -- -- -- -- -- -- -- 
[  22 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  23 ]      chunk(imap): 21 6 10 14 18 22 -- -- -- -- -- -- -- -- -- -- 
[  24 ] live [.,0] [..,0] [kg5,1] [hm5,2] [ht6,3] [zv9,4] [xr4,5] [px9,6] 
[  25 ]      type:dir size:1 refs:2 ptrs: 24 -- -- -- -- -- -- -- 
[  26 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  27 ]      chunk(imap): 25 6 10 14 18 22 26 -- -- -- -- -- -- -- -- -- 
[  28 ]      [gu5,7] -- -- -- -- -- -- -- 
[  29 ]      type:dir size:2 refs:2 ptrs: 24 28 -- -- -- -- -- -- 
[  30 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  31 ]      chunk(imap): 29 6 10 14 18 22 26 30 -- -- -- -- -- -- -- -- 
[  32 ]      [gu5,7] [kv6,8] -- -- -- -- -- -- 
[  33 ]      type:dir size:2 refs:2 ptrs: 24 32 -- -- -- -- -- -- 
[  34 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  35 ]      chunk(imap): 33 6 10 14 18 22 26 30 34 -- -- -- -- -- -- -- 
[  36 ]      [gu5,7] [kv6,8] [wg3,9] -- -- -- -- -- 
[  37 ]      type:dir size:2 refs:2 ptrs: 24 36 -- -- -- -- -- -- 
[  38 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  39 ]      chunk(imap): 37 6 10 14 18 22 26 30 34 38 -- -- -- -- -- -- 
[  40 ] live [gu5,7] [kv6,8] [wg3,9] [og9,10] -- -- -- -- 
[  41 ] live type:dir size:2 refs:2 ptrs: 24 40 -- -- -- -- -- -- 
[  42 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  43 ] live chunk(imap): 41 6 10 14 18 22 26 30 34 38 42 -- -- -- -- -- 

Live directories:  []
Live files:  ['/kg5', '/hm5', '/ht6', '/zv9', '/xr4', '/px9', '/gu5', '/kv6', '/wg3', '/og9']
```

随机分配索引节点（默认`-a r`），随机操作全部为创建文件（`-p c100`）
- 创建文件 `/kg5`：inode 地址为 6，无数据地址
  - 根目录：inode 地址更新为 5，数据地址更新为 4
- 创建文件 `/hm5`：inode 地址为 11，无数据地址
  - 目录：inode 地址更新为 10，数据地址更新为 9
- 创建文件 `/ht6`：inode 地址为 16，无数据地址
  - 目录：inode 地址更新为 15，数据地址更新为 14
- 创建文件 `/zv9`：inode 地址为 21，无数据地址
  - 目录：inode 地址更新为 20，数据地址更新为 19
- 创建文件 `/xr4`：inode 地址为 26，无数据地址
  - 目录：inode 地址更新为 25，数据地址更新为 24
- 创建文件 `/px9`：inode 地址为 31，无数据地址
  - 目录：inode 地址更新为 30，数据地址更新为 29
- 创建文件 `/gu5`：inode 地址为 36，无数据地址
  - 目录：inode 地址更新为 35，数据地址更新为 29 34
- 创建文件 `/kv6`：inode 地址为 41，无数据地址
  - 目录：inode 地址更新为 40，数据地址更新为 29 39
- 创建文件 `/wg3`：inode 地址为 46，无数据地址
  - 目录：inode 地址更新为 45，数据地址更新为 29 44
- 创建文件 `/og9`：inode 地址为 51，无数据地址
  - 目录：inode 地址更新为 50，数据地址更新为 29 49

消耗的数据块数比顺序分配的多

```bash
./lfs.py -p c100 -n 10 -a r -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create file /kg5    <--- 创建文件

[   0 ] live checkpoint: 7 -- -- -- -- -- -- -- -- -- -- -- 8 -- -- -- 
...
[   4 ] live [.,0] [..,0] [kg5,205] -- -- -- -- -- 
[   5 ] live type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ] live chunk(imap): 5 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   8 ] live chunk(imap): -- -- -- -- -- -- -- -- -- -- -- -- -- 6 -- -- 


create file /hm5    <--- 创建文件

[   0 ] live checkpoint: 12 -- -- -- -- -- -- 13 -- -- -- -- 8 -- -- -- 
...
[   9 ] live [.,0] [..,0] [kg5,205] [hm5,114] -- -- -- -- 
[  10 ] live type:dir size:1 refs:2 ptrs: 9 -- -- -- -- -- -- -- 
[  11 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  12 ] live chunk(imap): 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  13 ] live chunk(imap): -- -- 11 -- -- -- -- -- -- -- -- -- -- -- -- -- 


create file /ht6    <--- 创建文件

[   0 ] live checkpoint: 17 18 -- -- -- -- -- 13 -- -- -- -- 8 -- -- -- 
...
[  14 ] live [.,0] [..,0] [kg5,205] [hm5,114] [ht6,20] -- -- -- 
[  15 ] live type:dir size:1 refs:2 ptrs: 14 -- -- -- -- -- -- -- 
[  16 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  17 ] live chunk(imap): 15 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  18 ] live chunk(imap): -- -- -- -- 16 -- -- -- -- -- -- -- -- -- -- -- 


create file /zv9    <--- 创建文件

[   0 ] live checkpoint: 22 18 -- -- -- 23 -- 13 -- -- -- -- 8 -- -- -- 
...
[  19 ] live [.,0] [..,0] [kg5,205] [hm5,114] [ht6,20] [zv9,81] -- -- 
[  20 ] live type:dir size:1 refs:2 ptrs: 19 -- -- -- -- -- -- -- 
[  21 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  22 ] live chunk(imap): 20 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  23 ] live chunk(imap): -- 21 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


create file /xr4    <--- 创建文件

[   0 ] live checkpoint: 27 18 -- -- -- 23 -- 13 28 -- -- -- 8 -- -- -- 
...
[  24 ] live [.,0] [..,0] [kg5,205] [hm5,114] [ht6,20] [zv9,81] [xr4,130] -- 
[  25 ] live type:dir size:1 refs:2 ptrs: 24 -- -- -- -- -- -- -- 
[  26 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  27 ] live chunk(imap): 25 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  28 ] live chunk(imap): -- -- 26 -- -- -- -- -- -- -- -- -- -- -- -- -- 


create file /px9    <--- 创建文件

[   0 ] live checkpoint: 32 18 -- -- -- 23 -- 13 28 -- -- -- 8 -- 33 -- 
...
[  29 ] live [.,0] [..,0] [kg5,205] [hm5,114] [ht6,20] [zv9,81] [xr4,130] [px9,238] 
[  30 ] live type:dir size:1 refs:2 ptrs: 29 -- -- -- -- -- -- -- 
[  31 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  32 ] live chunk(imap): 30 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  33 ] live chunk(imap): -- -- -- -- -- -- -- -- -- -- -- -- -- -- 31 -- 


create file /gu5    <--- 创建文件

[   0 ] live checkpoint: 37 38 -- -- -- 23 -- 13 28 -- -- -- 8 -- 33 -- 
...
[  34 ] live [gu5,27] -- -- -- -- -- -- -- 
[  35 ] live type:dir size:2 refs:2 ptrs: 29 34 -- -- -- -- -- -- 
[  36 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  37 ] live chunk(imap): 35 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  38 ] live chunk(imap): -- -- -- -- 16 -- -- -- -- -- -- 36 -- -- -- -- 


create file /kv6    <--- 创建文件

[   0 ] live checkpoint: 42 38 -- -- -- 23 -- 13 43 -- -- -- 8 -- 33 -- 
...
[  39 ] live [gu5,27] [kv6,141] -- -- -- -- -- -- 
[  40 ] live type:dir size:2 refs:2 ptrs: 29 39 -- -- -- -- -- -- 
[  41 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  42 ] live chunk(imap): 40 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  43 ] live chunk(imap): -- -- 26 -- -- -- -- -- -- -- -- -- -- 41 -- -- 


create file /wg3    <--- 创建文件

[   0 ] live checkpoint: 47 38 -- -- -- 23 -- 13 43 -- -- 48 8 -- 33 -- 
...
[  44 ] live [gu5,27] [kv6,141] [wg3,180] -- -- -- -- -- 
[  45 ] live type:dir size:2 refs:2 ptrs: 29 44 -- -- -- -- -- -- 
[  46 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  47 ] live chunk(imap): 45 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  48 ] live chunk(imap): -- -- -- -- 46 -- -- -- -- -- -- -- -- -- -- -- 


create file /og9    <--- 创建文件

[   0 ] live checkpoint: 52 38 -- -- -- 23 -- 13 53 -- -- 48 8 -- 33 -- 
...
[  49 ] live [gu5,27] [kv6,141] [wg3,180] [og9,140] -- -- -- -- 
[  50 ] live type:dir size:2 refs:2 ptrs: 29 49 -- -- -- -- -- -- 
[  51 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  52 ] live chunk(imap): 50 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  53 ] live chunk(imap): -- -- 26 -- -- -- -- -- -- -- -- -- 51 41 -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 52 38 -- -- -- 23 -- 13 53 -- -- 48 8 -- 33 -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ]      [.,0] [..,0] [kg5,205] -- -- -- -- -- 
[   5 ]      type:dir size:1 refs:2 ptrs: 4 -- -- -- -- -- -- -- 
[   6 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[   7 ]      chunk(imap): 5 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   8 ] live chunk(imap): -- -- -- -- -- -- -- -- -- -- -- -- -- 6 -- -- 
[   9 ]      [.,0] [..,0] [kg5,205] [hm5,114] -- -- -- -- 
[  10 ]      type:dir size:1 refs:2 ptrs: 9 -- -- -- -- -- -- -- 
[  11 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  12 ]      chunk(imap): 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  13 ] live chunk(imap): -- -- 11 -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  14 ]      [.,0] [..,0] [kg5,205] [hm5,114] [ht6,20] -- -- -- 
[  15 ]      type:dir size:1 refs:2 ptrs: 14 -- -- -- -- -- -- -- 
[  16 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  17 ]      chunk(imap): 15 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  18 ]      chunk(imap): -- -- -- -- 16 -- -- -- -- -- -- -- -- -- -- -- 
[  19 ]      [.,0] [..,0] [kg5,205] [hm5,114] [ht6,20] [zv9,81] -- -- 
[  20 ]      type:dir size:1 refs:2 ptrs: 19 -- -- -- -- -- -- -- 
[  21 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  22 ]      chunk(imap): 20 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  23 ] live chunk(imap): -- 21 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  24 ]      [.,0] [..,0] [kg5,205] [hm5,114] [ht6,20] [zv9,81] [xr4,130] -- 
[  25 ]      type:dir size:1 refs:2 ptrs: 24 -- -- -- -- -- -- -- 
[  26 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  27 ]      chunk(imap): 25 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  28 ]      chunk(imap): -- -- 26 -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  29 ] live [.,0] [..,0] [kg5,205] [hm5,114] [ht6,20] [zv9,81] [xr4,130] [px9,238] 
[  30 ]      type:dir size:1 refs:2 ptrs: 29 -- -- -- -- -- -- -- 
[  31 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  32 ]      chunk(imap): 30 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  33 ] live chunk(imap): -- -- -- -- -- -- -- -- -- -- -- -- -- -- 31 -- 
[  34 ]      [gu5,27] -- -- -- -- -- -- -- 
[  35 ]      type:dir size:2 refs:2 ptrs: 29 34 -- -- -- -- -- -- 
[  36 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  37 ]      chunk(imap): 35 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  38 ] live chunk(imap): -- -- -- -- 16 -- -- -- -- -- -- 36 -- -- -- -- 
[  39 ]      [gu5,27] [kv6,141] -- -- -- -- -- -- 
[  40 ]      type:dir size:2 refs:2 ptrs: 29 39 -- -- -- -- -- -- 
[  41 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  42 ]      chunk(imap): 40 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  43 ]      chunk(imap): -- -- 26 -- -- -- -- -- -- -- -- -- -- 41 -- -- 
[  44 ]      [gu5,27] [kv6,141] [wg3,180] -- -- -- -- -- 
[  45 ]      type:dir size:2 refs:2 ptrs: 29 44 -- -- -- -- -- -- 
[  46 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  47 ]      chunk(imap): 45 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  48 ] live chunk(imap): -- -- -- -- 46 -- -- -- -- -- -- -- -- -- -- -- 
[  49 ] live [gu5,27] [kv6,141] [wg3,180] [og9,140] -- -- -- -- 
[  50 ] live type:dir size:2 refs:2 ptrs: 29 49 -- -- -- -- -- -- 
[  51 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  52 ] live chunk(imap): 50 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  53 ] live chunk(imap): -- -- 26 -- -- -- -- -- -- -- -- -- 51 41 -- -- 

Live directories:  []
Live files:  ['/kg5', '/hm5', '/ht6', '/zv9', '/xr4', '/px9', '/gu5', '/kv6', '/wg3', '/og9']
```

### 11

使用随机数种子 1000（`-s 1000`），执行操作后不强制更新检查点（`-N`）
- 创建目录 `/jm5`：inode 地址为 7，数据地址为 5
  - 根目录：inode 地址更新为 6，数据地址更新为 4
- 创建文件 `/jm5/jm2`：inode 地址为 11，无数据地址
  - 目录 `/jm5`：inode 地址更新为 10，数据地址更新为 9
- 创建目录 `/lb9`：inode 地址为 16，数据地址为 14
  - 根目录：inode 地址更新为 15，数据地址更新为 13

不更新检查点可能导致读取旧数据（死块）

```bash
./lfs.py -s 1000 -N -o -i -v -c

# 输出
INITIAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ] live [.,0] [..,0] -- -- -- -- -- -- 
[   2 ] live type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ] live chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

create dir  /jm5    <--- 创建目录

[   4 ] live [.,0] [..,0] [jm5,1] -- -- -- -- -- 
[   5 ] live [.,1] [..,0] -- -- -- -- -- -- 
[   6 ] live type:dir size:1 refs:3 ptrs: 4 -- -- -- -- -- -- -- 
[   7 ] live type:dir size:1 refs:2 ptrs: 5 -- -- -- -- -- -- -- 
[   8 ] live chunk(imap): 6 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


create file /jm5/jm2    <--- 创建文件

[   9 ] live [.,1] [..,0] [jm2,2] -- -- -- -- -- 
[  10 ] live type:dir size:1 refs:2 ptrs: 9 -- -- -- -- -- -- -- 
[  11 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  12 ] live chunk(imap): 6 10 11 -- -- -- -- -- -- -- -- -- -- -- -- -- 


create dir  /lb9    <--- 创建目录

[  13 ] live [.,0] [..,0] [jm5,1] [lb9,3] -- -- -- -- 
[  14 ] live [.,3] [..,0] -- -- -- -- -- -- 
[  15 ] live type:dir size:1 refs:4 ptrs: 13 -- -- -- -- -- -- -- 
[  16 ] live type:dir size:1 refs:2 ptrs: 14 -- -- -- -- -- -- -- 
[  17 ] live chunk(imap): 15 10 11 16 -- -- -- -- -- -- -- -- -- -- -- -- 



FINAL file system contents:
[   0 ] live checkpoint: 3 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   1 ]      [.,0] [..,0] -- -- -- -- -- -- 
[   2 ]      type:dir size:1 refs:2 ptrs: 1 -- -- -- -- -- -- -- 
[   3 ]      chunk(imap): 2 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   4 ]      [.,0] [..,0] [jm5,1] -- -- -- -- -- 
[   5 ]      [.,1] [..,0] -- -- -- -- -- -- 
[   6 ]      type:dir size:1 refs:3 ptrs: 4 -- -- -- -- -- -- -- 
[   7 ]      type:dir size:1 refs:2 ptrs: 5 -- -- -- -- -- -- -- 
[   8 ]      chunk(imap): 6 7 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
[   9 ] live [.,1] [..,0] [jm2,2] -- -- -- -- -- 
[  10 ] live type:dir size:1 refs:2 ptrs: 9 -- -- -- -- -- -- -- 
[  11 ] live type:reg size:0 refs:1 ptrs: -- -- -- -- -- -- -- -- 
[  12 ]      chunk(imap): 6 10 11 -- -- -- -- -- -- -- -- -- -- -- -- -- 
[  13 ] live [.,0] [..,0] [jm5,1] [lb9,3] -- -- -- -- 
[  14 ] live [.,3] [..,0] -- -- -- -- -- -- 
[  15 ] live type:dir size:1 refs:4 ptrs: 13 -- -- -- -- -- -- -- 
[  16 ] live type:dir size:1 refs:2 ptrs: 14 -- -- -- -- -- -- -- 
[  17 ] live chunk(imap): 15 10 11 16 -- -- -- -- -- -- -- -- -- -- -- -- 

Live directories:  ['/jm5', '/lb9']
Live files:  ['/jm5/jm2']
```