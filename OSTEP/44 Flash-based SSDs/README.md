## 44 Flash-based SSDs

模拟固态存储（solid-state storage device）
- 闪存转换层（flash translation layer, FTL）
- 页状态
  - INVALID (i)
  - ERASED (E)
  - VALID (v)

```python
# 随机种子，默认为 0
parser.add_option('-s', '--seed',            default=0,          help='the random seed',                         action='store', type='int',    dest='seed')
# 随机操作的数量，默认为 10
parser.add_option('-n', '--num_cmds',        default=10,         help='number of commands to randomly generate', action='store', type='int',    dest='num_cmds')
# 随机情况下读/写/垃圾回收操作的比例
parser.add_option('-P', '--op_percentages',  default='40/50/10', help='if rand, percent of reads/writes/trims',  action='store', type='string', dest='op_percentages')
# 工作负载倾斜，例如 80% 的写操作针对 20% 的块
parser.add_option('-K', '--skew',            default='',         help='if non-empty, skew, e.g., 80/20: 80% of ops to 20% of blocks', action='store', type='string', dest='skew')
# 指定写操作数量后开始倾斜
parser.add_option('-k', '--skew_start',      default=0,          help='if --skew, skew after this many writes',  action='store', type='int',    dest='skew_start')
# 随机操作中可能失败的读操作的比例，默认为 0
parser.add_option('-r', '--read_fails',      default=0,          help='if rand, percent of reads that can fail', action='store', type='int',    dest='read_fail')
# 指定操作序列
parser.add_option('-L', '--cmd_list',        default='',         help='comma-separated list of commands (e.g., r10,w20:a)', action='store', type='string', dest='cmd_list')
# SSD 类型，理想、直接映射、日志结构
parser.add_option('-T', '--ssd_type',        default='direct',   help='SSD type: ideal, direct, log',            action='store', type='string', dest='ssd_type')
# 逻辑页数量，默认为 50
parser.add_option('-l', '--logical_pages',   default=50,         help='number of logical pages in interface',    action='store', type='int',    dest='num_logical_pages')
# SSD 中的物理块数量，默认为 7
parser.add_option('-B', '--num_blocks',      default=7,          help='number of physical blocks in SSD',        action='store', type='int',    dest='num_blocks')
# 每个物理块的页数量，默认为 10
parser.add_option('-p', '--pages_per_block', default=10,         help='pages per physical block',                action='store', type='int',    dest='pages_per_block')
# 启动垃圾回收前使用的块数，默认为 10
parser.add_option('-G', '--high_water_mark', default=10,         help='blocks used before gc trigger',           action='store', type='int',    dest='high_water_mark')
# 停止垃圾回收前回收的块数，默认为 8
parser.add_option('-g', '--low_water_mark',  default=8,          help='gc target before stopping gc',            action='store', type='int',    dest='low_water_mark')
# 读页的时间，默认为 10
parser.add_option('-R', '--read_time',       default=10,         help='page read time (usecs)',                  action='store', type='int',    dest='read_time')
# 操作页的时间，默认为 40
parser.add_option('-W', '--program_time',    default=40,         help='page program time (usecs)',               action='store', type='int',    dest='program_time')
# 擦除页的时间。默认为 1000
parser.add_option('-E', '--erase_time',      default=1000,       help='page erase time (usecs)',                 action='store', type='int',    dest='erase_time')
# 显示垃圾回收的行为，默认不打印
parser.add_option('-J', '--show_gc',         default=False,      help='show garbage collector behavior',         action='store_true',           dest='show_gc')
# 显示闪存状态，默认不显示
parser.add_option('-F', '--show_state',      default=False,      help='show flash state',                        action='store_true',           dest='show_state')
# 显示操作，默认不显示
parser.add_option('-C', '--show_cmds',       default=False,      help='show commands',                           action='store_true',           dest='show_cmds')
# 考察操作
parser.add_option('-q', '--quiz_cmds',       default=False,      help='quiz commands',                           action='store_true',           dest='quiz_cmds')
# 显示统计结果，默认不显示
parser.add_option('-S', '--show_stats',      default=False,      help='show statistics',                         action='store_true',           dest='show_stats')
# 计算结果
parser.add_option('-c', '--compute',         default=False,      help='compute answers for me',                  action='store_true',           dest='solve')
```

用默认参数运行，把能显示的都显示出来
- 直接映射，随机生成 10 个操作
  - 逻辑到物理映射相同
- 对于初始状态的块，先擦除再写入
- 待写入块已经有数据时，先读取，再擦除，最后写入
  - 写入放大

```bash
./ssd.py -J -F -C -S -c

# 输出
ARG seed 0                  <--- 随机种子
ARG num_cmds 10             <--- 操作数量
ARG op_percentages 40/50/10 <--- 读/写/擦除
ARG skew                    <--- 工作负载倾斜
ARG skew_start 0            <--- 工作负载倾斜前写入的数量
ARG read_fail 0             <--- 读操作失败比例
ARG cmd_list                <--- 操作序列
ARG ssd_type direct         <--- SSD 类型，直接映射
ARG num_logical_pages 50    <--- 逻辑页数量
ARG num_blocks 7            <--- 块数量
ARG pages_per_block 10      <--- 每块的页数量
ARG high_water_mark 10      <--- 启动垃圾回收前使用的块数
ARG low_water_mark 8        <--- 停止垃圾回收前使用的块数
ARG erase_time 1000         <--- 擦除时间
ARG program_time 40         <--- 编程时间
ARG read_time 10            <--- 读事件
ARG show_gc True            <--- 显示垃圾回收
ARG show_state True         <--- 显示状态
ARG show_cmds True          <--- 现实操作
ARG quiz_cmds False         <--- 考察操作
ARG show_stats True         <--- 显示统计结果
ARG compute True            <--- 计算结果

FTL   (empty)   <--- 初始状态
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               <--- 数据
Live                                                                               <--- 是否存活

cmd   0:: write(37, q) -> success   <--- 写入数据

FTL    37: 37   <--- 逻辑页: 物理页
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii EEEEEEEvEE iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                          q                                    
Live                                          +                                    

cmd   1:: write(39, i) -> success   <--- 写入数据

FTL    37: 37  39: 39 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii EEEEEEEvEv iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                          q i                                  
Live                                          + +                                  

cmd   2:: write(29, U) -> success   <--- 写入数据

FTL    29: 29  37: 37  39: 39 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii EEEEEEEEEv EEEEEEEvEv iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                 U        q i                                  
Live                                 +        + +                                  

cmd   3:: write(14, K) -> success   <--- 写入数据

FTL    14: 14  29: 29  37: 37  39: 39 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii EEEEvEEEEE EEEEEEEEEv EEEEEEEvEv iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                 K               U        q i                                  
Live                 +               +        + +                                  

cmd   4:: write(12, U) -> success   <--- 写入数据

FTL    12: 12  14: 14  29: 29  37: 37  39: 39 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii EEvEvEEEEE EEEEEEEEEv EEEEEEEvEv iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data               U K               U        q i                                  
Live               + +               +        + +                                  

cmd   5:: trim(12) -> success   <--- 删除数据

FTL    14: 14  29: 29  37: 37  39: 39 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii EEvEvEEEEE EEEEEEEEEv EEEEEEEvEv iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data               U K               U        q i                                  
Live                 +               +        + +                                  

cmd   6:: trim(39) -> success   <--- 删除数据

FTL    14: 14  29: 29  37: 37 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii EEvEvEEEEE EEEEEEEEEv EEEEEEEvEv iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data               U K               U        q i                                  
Live                 +               +        +                                    

cmd   7:: write(44, G) -> success   <--- 写入数据

FTL    14: 14  29: 29  37: 37  44: 44 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii EEvEvEEEEE EEEEEEEEEv EEEEEEEvEv EEEEvEEEEE iiiiiiiiii iiiiiiiiii 
Data               U K               U        q i     G                            
Live                 +               +        +       +                            

cmd   8:: write(5, q) -> success    <--- 写入数据

FTL     5:  5  14: 14  29: 29  37: 37  44: 44 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State EEEEEvEEEE EEvEvEEEEE EEEEEEEEEv EEEEEEEvEv EEEEvEEEEE iiiiiiiiii iiiiiiiiii 
Data       q       U K               U        q i     G                            
Live       +         +               +        +       +                            

cmd   9:: write(45, X) -> success   <--- 写入数据

FTL     5:  5  14: 14  29: 29  37: 37  44: 44  45: 45 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State EEEEEvEEEE EEvEvEEEEE EEEEEEEEEv EEEEEEEvEv EEEEvvEEEE iiiiiiiiii iiiiiiiiii 
Data       q       U K               U        q i     GX                           
Live       +         +               +        +       ++                           


Physical Operations Per Block   <--- 每块的物理操作
Erases   1          2          1          2          2          0          0          Sum: 8
Writes   1          3          1          3          3          0          0          Sum: 11
Reads    0          1          0          1          1          0          0          Sum: 3

Logical Operation Sums      <--- 逻辑操作
  Write count 8 (0 failed)
  Read count  0 (0 failed)
  Trim count  2 (0 failed)

Times
  Erase time 8000.00
  Write time 440.00
  Read time  30.00
  Total time 8470.00
```

### 1/4

基于日志（`-T log`），使用随机数种子 1（`-s 1`）
- 按地址顺序映射
- 已有数据时，直接继续写入，不用读取-擦除-写入

```bash
./ssd.py -T log -s 1 -n 10 -C -S -c

# 结果
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               

cmd   0:: write(12, u) -> success   <--- 12:0
cmd   1:: write(32, M) -> success   <--- 32:1
cmd   2:: read(32) -> M
cmd   3:: write(38, 0) -> success   <--- 38:2
cmd   4:: write(36, e) -> success   <--- 36:3
cmd   5:: trim(36) -> success
cmd   6:: read(32) -> M
cmd   7:: trim(32) -> success
cmd   8:: read(12) -> u
cmd   9:: read(12) -> u

FTL    12:  0  38:  2 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State vvvvEEEEEE iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data  uM0e                                                                         
Live  + +                                                                          

Physical Operations Per Block
Erases   1          0          0          0          0          0          0          Sum: 1
Writes   4          0          0          0          0          0          0          Sum: 4
Reads    4          0          0          0          0          0          0          Sum: 4

Logical Operation Sums
  Write count 4 (0 failed)
  Read count  4 (0 failed)
  Trim count  2 (0 failed)

Times
  Erase time 1000.00
  Write time 160.00
  Read time  40.00
  Total time 1200.00                                                                        
```

### 2

基于日志（`-T log`），使用随机数种子 2（`-s 2`）
- 按地址顺序映射

```bash
./ssd.py -T log -s 2 -n 10 -C -S -c

# 结果
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               

cmd   0:: write(36, F) -> success   <--- 36:0
cmd   1:: write(29, 9) -> success   <--- 29:1
cmd   2:: write(19, I) -> success   <--- 19:2
cmd   3:: trim(19) -> success
cmd   4:: write(22, g) -> success   <--- 22:3
cmd   5:: read(29) -> 9
cmd   6:: read(22) -> g
cmd   7:: write(28, e) -> success   <--- 28:4
cmd   8:: read(36) -> F
cmd   9:: write(49, F) -> success   <--- 49:5

FTL    22:  3  28:  4  29:  1  36:  0  49:  5 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State vvvvvvEEEE iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data  F9IgeF                                                                       
Live  ++ +++                                                                       

Physical Operations Per Block
Erases   1          0          0          0          0          0          0          Sum: 1
Writes   6          0          0          0          0          0          0          Sum: 6
Reads    3          0          0          0          0          0          0          Sum: 3

Logical Operation Sums
  Write count 6 (0 failed)
  Read count  3 (0 failed)
  Trim count  1 (0 failed)

Times
  Erase time 1000.00
  Write time 240.00
  Read time  30.00
  Total time 1270.00
```

### 3

基于日志（`-T log`），使用随机数种子 1（`-s 1`），设置读取操作失败比例为 20%（`-r 20`）
- 部分操作失败，总体耗时减少

```bash
./ssd.py -T log -s 1 -n 10 -r 20 -C -S -c

# 结果
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               

cmd   0:: write(12, u) -> success   <--- 12:0
cmd   1:: write(32, M) -> success   <--- 32:1
cmd   2:: read(41) -> fail: uninitialized read  <--- 未初始化读
cmd   3:: write(38, 0) -> success   <--- 38:2
cmd   4:: write(36, e) -> success   <--- 36:3
cmd   5:: trim(36) -> success
cmd   6:: read(27) -> fail: uninitialized read  <--- 未初始化读
cmd   7:: trim(32) -> success
cmd   8:: read(12) -> u     <--- 读取成功
cmd   9:: read(12) -> u     <--- 读取成功

FTL    12:  0  38:  2 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State vvvvEEEEEE iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data  uM0e                                                                         
Live  + +                                                                          

Physical Operations Per Block
Erases   1          0          0          0          0          0          0          Sum: 1
Writes   4          0          0          0          0          0          0          Sum: 4
Reads    2          0          0          0          0          0          0          Sum: 2

Logical Operation Sums
  Write count 4 (0 failed)
  Read count  4 (2 failed)
  Trim count  2 (0 failed)

Times
  Erase time 1000.00
  Write time 160.00
  Read time  20.00
  Total time 1180.00
```

### 5

直接映射（`-T direct`），其余参数使用默认值

```bash
./ssd.py -T direct -C -S -c

# 结果
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               

cmd   0:: write(37, q) -> success   <--- 37:37
cmd   1:: write(39, i) -> success   <--- 39:39
cmd   2:: write(29, U) -> success   <--- 29:29
cmd   3:: write(14, K) -> success   <--- 14:14
cmd   4:: write(12, U) -> success   <--- 12:12
cmd   5:: trim(12) -> success
cmd   6:: trim(39) -> success
cmd   7:: write(44, G) -> success   <--- 44:44
cmd   8:: write(5, q) -> success    <--- 5:5
cmd   9:: write(45, X) -> success   <--- 45:45

FTL     5:  5  14: 14  29: 29  37: 37  44: 44  45: 45 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State EEEEEvEEEE EEvEvEEEEE EEEEEEEEEv EEEEEEEvEv EEEEvvEEEE iiiiiiiiii iiiiiiiiii 
Data       q       U K               U        q i     GX                           
Live       +         +               +        +       ++                           

Physical Operations Per Block
Erases   1          2          1          2          2          0          0          Sum: 8
Writes   1          3          1          3          3          0          0          Sum: 11
Reads    0          1          0          1          1          0          0          Sum: 3

Logical Operation Sums
  Write count 8 (0 failed)
  Read count  0 (0 failed)
  Trim count  2 (0 failed)

Times
  Erase time 8000.00
  Write time 440.00
  Read time  30.00
  Total time 8470.00
```

基于日志（`-T log`），相比直接映射效率高多了，物理操作的数量大大减少

```bash
./ssd.py -T log -C -S -c

# 结果
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               

cmd   0:: write(37, q) -> success   <--- 37:0
cmd   1:: write(39, i) -> success   <--- 39:1
cmd   2:: write(29, U) -> success   <--- 29:2
cmd   3:: write(14, K) -> success   <--- 14:3
cmd   4:: write(12, U) -> success   <--- 12:4
cmd   5:: trim(12) -> success
cmd   6:: trim(39) -> success
cmd   7:: write(44, G) -> success   <--- 44:5
cmd   8:: write(5, q) -> success    <--- 5:6
cmd   9:: write(45, X) -> success   <--- 45:7

FTL     5:  6  14:  3  29:  2  37:  0  44:  5  45:  7 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State vvvvvvvvEE iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data  qiUKUGqX                                                                     
Live  + ++ +++                                                                     

Physical Operations Per Block
Erases   1          0          0          0          0          0          0          Sum: 1
Writes   8          0          0          0          0          0          0          Sum: 8
Reads    0          0          0          0          0          0          0          Sum: 0

Logical Operation Sums
  Write count 8 (0 failed)
  Read count  0 (0 failed)
  Trim count  2 (0 failed)

Times
  Erase time 1000.00
  Write time 320.00
  Read time  0.00
  Total time 1320.00
```

### 6/7

基于日志（`-T log`），随机生成 1000 个操作（`-n 1000`）
- 高水位线（`-G 10`）：启动垃圾回收前使用的块数，默认为 10
- 低水位线（`-g 8`）：停止垃圾回收前使用的块数，默认为 8

```bash
./ssd.py -T log -n 1000 -S -c

# 结果
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               


FTL     5: 63   9: 43  27: 52  28: 40  42: 57 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv 
Data  qiUKUGqXg0 Pukzj6xXrz txTzZfdO1z 1g3ljJIppr KjSZIdP7h5 wSWTxCUYJC uqmoUB2I5d 
Live                                              +  +         +    +      +       

Physical Operations Per Block
Erases   1          1          1          1          1          1          1          Sum: 7
Writes  10         10         10         10         10         10         10          Sum: 70
Reads   10         15         23         19         27         38         33          Sum: 165

Logical Operation Sums
  Write count 520 (450 failed)  <--- 70 : 450
  Read count  374 (209 failed)  <--- 165 : 209
  Trim count  106 (67 failed)   <--- 39 : 67

Times
  Erase time 7000.00
  Write time 2800.00
  Read time  1650.00
  Total time 11450.00
```

### 8

理想（`-T ideal`），随机生成 1000 个操作（`-n 1000`），显示闪存状态（`-C`）和垃圾回收（`-J`）
- 操作全部成功，不进行擦除直接读写
- [ideal.txt](file-ssd/ideal.txt)

```bash
# ./ssd.py -T ideal -n 1000 -C -J -S -c > ideal.txt
./ssd.py -T ideal -n 1000 -S -c

# 输出
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               


FTL     2:  2   3:  3   4:  4   5:  5   7:  7   8:  8   9:  9  10: 10  12: 12  13: 13 
       14: 14  15: 15  16: 16  18: 18  19: 19  20: 20  21: 21  22: 22  23: 23  24: 24 
       25: 25  27: 27  28: 28  29: 29  30: 30  31: 31  33: 33  34: 34  35: 35  36: 36 
       37: 37  38: 38  39: 39  40: 40  41: 41  42: 42  43: 43  44: 44  45: 45  46: 46 
       48: 48  49: 49 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv iiiiiiiiii iiiiiiiiii 
Data  CpV4vO7pEO SFN4C2ZOhD AhM57YPmZB zF3IWfSfh4 A4MLxfbMrT                       
Live    ++++ +++ + +++++ ++ ++++++ +++ ++ +++++++ +++++++ ++                       

Physical Operations Per Block
Erases   0          0          0          0          0          0          0          Sum: 0
Writes 117        104         98        110         91          0          0          Sum: 520
Reads   76         74         71         76         77          0          0          Sum: 374

Logical Operation Sums
  Write count 520 (0 failed)
  Read count  374 (0 failed)
  Trim count  106 (0 failed)

Times
  Erase time 0.00
  Write time 20800.00
  Read time  3740.00
  Total time 24540.00
```

直接映射（`-T direct`），操作全部成功，但非常耗时
- [direct.txt](file-ssd/direct.txt)

```bash
# ./ssd.py -T direct -n 1000 -C -J -S -c > direct.txt
./ssd.py -T direct -n 1000 -S -c

# 输出
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               


FTL     2:  2   3:  3   4:  4   5:  5   7:  7   8:  8   9:  9  10: 10  12: 12  13: 13 
       14: 14  15: 15  16: 16  18: 18  19: 19  20: 20  21: 21  22: 22  23: 23  24: 24 
       25: 25  27: 27  28: 28  29: 29  30: 30  31: 31  33: 33  34: 34  35: 35  36: 36 
       37: 37  38: 38  39: 39  40: 40  41: 41  42: 42  43: 43  44: 44  45: 45  46: 46 
       48: 48  49: 49 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv iiiiiiiiii iiiiiiiiii 
Data  CpV4vO7pEO SFN4C2ZOhD AhM57YPmZB zF3IWfSfh4 A4MLxfbMrT                       
Live    ++++ +++ + +++++ ++ ++++++ +++ ++ +++++++ +++++++ ++                       

Physical Operations Per Block
Erases 117        104         98        110         91          0          0          Sum: 520
Writes 1062        924        883        1027        828          0          0          Sum: 4724
Reads  1128        988        944        1093        895          0          0          Sum: 5048

Logical Operation Sums
  Write count 520 (0 failed)
  Read count  374 (0 failed)
  Trim count  106 (0 failed)

Times
  Erase time 520000.00
  Write time 188960.00
  Read time  50480.00
  Total time 759440.00
```

基于日志（`-T log`），大部分操作都失败，因此耗时比理想情况下还少
- [log.txt](file-ssd/log.txt)

```bash
# ./ssd.py -T log -n 1000 -C -J -S -c > log.txt
./ssd.py -T log -n 1000 -S -c

# 输出
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               


FTL     5: 63   9: 43  27: 52  28: 40  42: 57 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv 
Data  qiUKUGqXg0 Pukzj6xXrz txTzZfdO1z 1g3ljJIppr KjSZIdP7h5 wSWTxCUYJC uqmoUB2I5d 
Live                                              +  +         +    +      +       

Physical Operations Per Block
Erases   1          1          1          1          1          1          1          Sum: 7
Writes  10         10         10         10         10         10         10          Sum: 70
Reads   10         15         23         19         27         38         33          Sum: 165

Logical Operation Sums
  Write count 520 (450 failed)
  Read count  374 (209 failed)
  Trim count  106 (67 failed)

Times
  Erase time 7000.00
  Write time 2800.00
  Read time  1650.00
  Total time 11450.00
```

### 9-1

直接映射（`-T direct`），工作负载倾斜设置为 80% 的写操作只针对 20% 的块（`-K 80/20`）
- 操作全部成功
- 读取-擦除-写入的过程非常耗时

```bash
./ssd.py -T direct -n 1000 -K 80/20 -S -c

# 输出
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               


FTL     0:  0   1:  1   2:  2   3:  3   4:  4   5:  5   6:  6   8:  8   9:  9  15: 15 
       16: 16  17: 17  20: 20  24: 24  29: 29  34: 34  36: 36  43: 43  46: 46  47: 47 
       48: 48 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State vvvvvvvvvv vEvvEvvvEv vvvvvvvvEv vvvEvvvvvv vvEvEEvvvv iiiiiiiiii iiiiiiiiii 
Data  JJK36oXJrP g GN NXt V 4rx96WHs D A4C NWpt6E MJ J  DeEK                       
Live  +++++++ ++      +++   +   +    +     + +       +  +++                        

Physical Operations Per Block
Erases 442         20         23         15         20          0          0          Sum: 520
Writes 4284        105        159         83        104          0          0          Sum: 4735
Reads  4460        162        200        100        151          0          0          Sum: 5073

Logical Operation Sums
  Write count 520 (0 failed)
  Read count  380 (0 failed)
  Trim count  100 (0 failed)

Times
  Erase time 520000.00
  Write time 189400.00
  Read time  50730.00
  Total time 760130.00
```

基于日志（`-T log`）
- 大部分操作都失败，最后甚至没有活数据

```bash
./ssd.py -T log -n 1000 -K 80/20 -S -c

# 输出
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               


FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv 
Data  givJ6XNouR vOAz5QoQzU uJGYqvFftj kobpguZZdw 6h8SWIkCtt JnAZFYjcX9 49TNUoEDFt 
Live                                                                               

Physical Operations Per Block
Erases   1          1          1          1          1          1          1          Sum: 7
Writes  10         10         10         10         10         10         10          Sum: 70
Reads   19          8         13          4         17          9         47          Sum: 117

Logical Operation Sums
  Write count 520 (450 failed)
  Read count  380 (263 failed)
  Trim count  100 (72 failed)

Times
  Erase time 7000.00
  Write time 2800.00
  Read time  1170.00
  Total time 10970.00
```

### 9-2

和 9-1 相同，但是在执行 100 个写入操作后（`-k 100`）再倾斜工作负载

直接映射（`-T direct`），工作负载倾斜设置为 80% 的写操作只针对 20% 的块（`-K 80/20`）
- 操作全部成功
- 更加耗时

```bash
./ssd.py -T direct -n 1000 -K 80/20 -k 100 -S -c

# 输出
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               


FTL     0:  0   3:  3   4:  4   5:  5   6:  6   8:  8   9:  9  15: 15  20: 20  24: 24 
       26: 26  29: 29  36: 36  43: 43  47: 47 
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State vvvvvvvvvv vEvEvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv iiiiiiiiii iiiiiiiiii 
Data  J3i3I1XJJ8 g G KN1txV 5rx96WHsdD z4C9qWpt67 MJNLGCWe0K                       
Live  +  ++++ ++      +     +   + +  +       +       +   +                         

Physical Operations Per Block
Erases 394         30         36         27         36          0          0          Sum: 523
Writes 3835        197        262        199        275          0          0          Sum: 4768
Reads  3982        249        303        244        312          0          0          Sum: 5090

Logical Operation Sums
  Write count 523 (0 failed)
  Read count  370 (0 failed)
  Trim count  107 (0 failed)

Times
  Erase time 523000.00
  Write time 190720.00
  Read time  50900.00
  Total time 764620.00
```

基于日志（`-T log`）
- 成功的操作数量增多，但大部分操作仍然失败
- 耗时略微增加

```bash
./ssd.py -T log -n 1000 -K 80/20 -k 100 -S -c

# 输出
...
FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii iiiiiiiiii 
Data                                                                               
Live                                                                               


FTL   (empty)
Block 0          1          2          3          4          5          6          
Page  0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 
      0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 
State vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv vvvvvvvvvv 
Data  qiUKUGqXg0 Pukzj6xXrz txTzZfdO1z 1g3ljJIppr KjSZIdP7h5 wSWTxCUYJC uqmoUB2I5d 
Live                                                                               

Physical Operations Per Block
Erases   1          1          1          1          1          1          1          Sum: 7
Writes  10         10         10         10         10         10         10          Sum: 70
Reads   10         12         25         12         25         46         27          Sum: 157

Logical Operation Sums
  Write count 523 (453 failed)
  Read count  370 (213 failed)
  Trim count  107 (63 failed)

Times
  Erase time 7000.00
  Write time 2800.00
  Read time  1570.00
  Total time 11370.00
```