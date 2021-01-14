## 26 Concurrency and Threads

模拟多线程执行汇编序列，不显示涉及操作系统代码（例如，上下文切换）；
汇编代码基于 x86 并有所简化，有 4 个通用寄存器（%ax、%bx、%cx、%dx），1 个程序计数器（Program Counter, PC），以及一小部分指令。

x86 有以下四种形式的地址：
- `2000`：地址
- `(%cx)`：寄存器 cx 的内容
- `1000(%dx)`：1000 + 寄存器 dx 的内容
- `10(%ax,%bx)`：10 + 寄存器 ax 的内容 + 寄存器 bx 的内容

示例
- 从地址 2000 加载值到 ax 寄存器
- 将 ax 寄存器中的值增加 1
  - `$1` 表示常数 1
- 将 ax 寄存器中的值存储到地址 2000

```
.main
mov 2000, %ax   # get the value at the address
add $1, %ax     # increment it
mov %ax, 2000   # store it back
halt
```

了解一下程序的参数和默认值

```python
parser = OptionParser()
# 随机种子，默认为 0
parser.add_option('-s', '--seed',      default=0,          help='the random seed',                  action='store',      type='int',    dest='seed')
# 线程数量，默认为 2
parser.add_option('-t', '--threads',   default=2,          help='number of threads',                action='store',      type='int',    dest='numthreads')
# 源程序
parser.add_option('-p', '--program',   default='',         help='source program (in .s)',           action='store',      type='string', dest='progfile')
# 中断间隔，默认为 50 条指令中断一次
parser.add_option('-i', '--interrupt', default=50,         help='interrupt frequency',              action='store',      type='int',    dest='intfreq')
# 随机中断
parser.add_option('-r', '--randints',  default=False,      help='if interrupts are random',         action='store_true',                dest='intrand')
# 设置寄存器的值
parser.add_option('-a', '--argv',      default='',
                  help='comma-separated per-thread args (e.g., ax=1,ax=2 sets thread 0 ax reg to 1 and thread 1 ax reg to 2); specify multiple regs per thread via colon-separated list (e.g., ax=1:bx=2,cx=3 sets thread 0 ax and bx and just cx for thread 1)',
                  action='store',      type='string', dest='argv')
# 加载代码的地址，默认为 1000
parser.add_option('-L', '--loadaddr',  default=1000,       help='address where to load code',       action='store',      type='int',    dest='loadaddr')
# 地址空间大小，默认为 128 KB
parser.add_option('-m', '--memsize',   default=128,        help='size of address space (KB)',       action='store',      type='int',    dest='memsize')
# 跟踪内存地址
parser.add_option('-M', '--memtrace',  default='',         help='comma-separated list of addrs to trace (e.g., 20000,20001)', action='store',
                  type='string', dest='memtrace')
# 跟踪寄存器
parser.add_option('-R', '--regtrace',  default='',         help='comma-separated list of regs to trace (e.g., ax,bx,cx,dx)',  action='store',
                  type='string', dest='regtrace')
# 跟踪条件
parser.add_option('-C', '--cctrace',   default=False,      help='should we trace condition codes',  action='store_true', dest='cctrace')
# 输出额外状态
parser.add_option('-S', '--printstats',default=False,      help='print some extra stats',           action='store_true', dest='printstats')
# 详细信息
parser.add_option('-v', '--verbose',   default=False,      help='print some extra info',            action='store_true', dest='verbose')
# 计算答案
parser.add_option('-c', '--compute',   default=False,      help='compute answers for me',           action='store_true', dest='solve')
(options, args) = parser.parse_args()
```

启动单线程运行 simple-race.s
- 每条指令执行的 python 代码、程序计数器（pc）的内容
- 总共 4 条指令，模拟速率每秒 7.43 千条指令

```bash
./x86.py -p simple-race.s -t 1 -v -S

# 输出
ARG seed 0                          <---- 随机种子
ARG numthreads 1                    <---- 线程数量
ARG program simple-race.s           <---- 源程序
ARG interrupt frequency 50          <---- 中断频率
ARG interrupt randomness False      <---- 随机中断
ARG argv                            <---- 指令参数
ARG load address 1000               <---- 代码加载地址
ARG memsize 128                     <---- 内存大小
ARG memtrace                        <---- 跟踪内存
ARG regtrace                        <---- 跟踪寄存器
ARG cctrace False                   <---- 跟踪条件语句
ARG printstats True                 <---- 状态输出
ARG verbose True                    <---- 详细信息

ASSIGN LABEL .main --> 1000

pc:1000 LOADING   mov 2000(%bx), %ax --> self.move_m_to_r(2000, 2, 0, 1)
pc:1001 LOADING          add $1, %ax --> self.add_i_to_r(1, 1)
pc:1002 LOADING   mov %ax, 2000(%bx) --> self.move_r_to_m(1, 2000, 2, 0)
pc:1003 LOADING                 halt --> self.halt()

       Thread 0         
1000 mov 2000(%bx), %ax
1001 add $1, %ax
1002 mov %ax, 2000(%bx)
1003 halt

STATS:: Instructions    4
STATS:: Emulation Rate  7.43 kinst/sec
```

以下输出结果均省略参数部分。

跟踪内存地址 2000 的内容，跟踪寄存器 ax 和 bx
- **每行显示的是执行指令后的结果状态**

```bash
./x86.py -p simple-race.s -t 1 -M 2000 -R ax,bx -c

# 输出
 2000      ax    bx          Thread 0         
    0       0     0   
    0       0     0   1000 mov 2000(%bx), %ax
    0       1     0   1001 add $1, %ax
    1       1     0   1002 mov %ax, 2000(%bx)
    1       1     0   1003 halt
```

### 1

首先看一下 loop.s 中的指令序列，容易看出来是根据 dx 寄存器中的值进行循环
- `test`：指令比较两个参数的值，设置隐式条件，决定后续执行的指令
- `jgte`：`jump if greater than or equal to` 大于等于时跳转

```
.main
.top
sub  $1,%dx
test $0,%dx
jgte .top
halt
```

按照题目要求运行，dx 默认值为 0 ，因此只执行一次
- 单线程
- 每 100 条指令产生一个中断
- 追踪寄存器 dx

```bash
./x86.py -p loop.s -t 1 -i 100 -R dx -C -c

# 输出
   dx   >= >  <= <  != ==        Thread 0
    0   0  0  0  0  0  0                        <---- dx 默认值为 0
   -1   0  0  0  0  0  0  1000 sub  $1,%dx      <---- dx - 1 = -1
   -1   0  0  1  1  1  0  1001 test $0,%dx      <---- dx 和 0 进行比较
   -1   0  0  1  1  1  0  1002 jgte .top        <---- dx >=0 跳转到 .top 部分代码
   -1   0  0  1  1  1  0  1003 halt             <---- 终止
```

### 2

将 dx 寄存器的值设置为 3，并设置 2 个线程，总共执行 4 次
- 默认每 50 条指令产生一次中断
  - 两个线程顺序执行，执行结果完全相同
- `Halt;Switch` 表示线程切换

```bash
./x86.py -p loop.s -t 2 -i 100 -a dx=3,dx=3 -R dx -c

# 输出
   dx          Thread 0                Thread 1         
    3   
    2   1000 sub  $1,%dx
    2   1001 test $0,%dx
    2   1002 jgte .top
    1   1000 sub  $1,%dx
    1   1001 test $0,%dx
    1   1002 jgte .top
    0   1000 sub  $1,%dx
    0   1001 test $0,%dx
    0   1002 jgte .top
   -1   1000 sub  $1,%dx
   -1   1001 test $0,%dx
   -1   1002 jgte .top
   -1   1003 halt
    3   ----- Halt;Switch -----  ----- Halt;Switch -----  
    2                            1000 sub  $1,%dx
    2                            1001 test $0,%dx
    2                            1002 jgte .top
    1                            1000 sub  $1,%dx
    1                            1001 test $0,%dx
    1                            1002 jgte .top
    0                            1000 sub  $1,%dx
    0                            1001 test $0,%dx
    0                            1002 jgte .top
   -1                            1000 sub  $1,%dx
   -1                            1001 test $0,%dx
   -1                            1002 jgte .top
   -1                            1003 halt
```

### 3

随机并且每 3 条指令产生一次中断
- 至多执行 3 条指令后产生中断
- 并没有改变 2 个线程的执行结果

```bash
./x86.py -p loop.s -t 2 -i 3 -r -a dx=3,dx=3 -R dx -c

# 输出
   dx          Thread 0                Thread 1         
    3   
    2   1000 sub  $1,%dx
    2   1001 test $0,%dx
    2   1002 jgte .top
    3   ------ Interrupt ------  ------ Interrupt ------  
    2                            1000 sub  $1,%dx
    2                            1001 test $0,%dx
    2                            1002 jgte .top
    2   ------ Interrupt ------  ------ Interrupt ------  
    1   1000 sub  $1,%dx
    1   1001 test $0,%dx
    2   ------ Interrupt ------  ------ Interrupt ------  
    1                            1000 sub  $1,%dx
    1   ------ Interrupt ------  ------ Interrupt ------  
    1   1002 jgte .top
    0   1000 sub  $1,%dx
    1   ------ Interrupt ------  ------ Interrupt ------  
    1                            1001 test $0,%dx
    1                            1002 jgte .top
    0   ------ Interrupt ------  ------ Interrupt ------  
    0   1001 test $0,%dx
    0   1002 jgte .top
   -1   1000 sub  $1,%dx
    1   ------ Interrupt ------  ------ Interrupt ------  
    0                            1000 sub  $1,%dx
   -1   ------ Interrupt ------  ------ Interrupt ------  
   -1   1001 test $0,%dx
   -1   1002 jgte .top
    0   ------ Interrupt ------  ------ Interrupt ------  
    0                            1001 test $0,%dx
    0                            1002 jgte .top
   -1   ------ Interrupt ------  ------ Interrupt ------  
   -1   1003 halt
    0   ----- Halt;Switch -----  ----- Halt;Switch -----  
   -1                            1000 sub  $1,%dx
   -1                            1001 test $0,%dx
   -1   ------ Interrupt ------  ------ Interrupt ------  
   -1                            1002 jgte .top
   -1                            1003 halt
```

### 4

查看 looping-race-nolock.s 中的指令序列，多线程运行时， ax 寄存器是临界区，bx 寄存器是共享变量
- `jgt`：`jump if greater than` 大于时跳转
- 访问内存地址 2000 的共享变量
- 寄存器 bx 存储循环计数

简单来说就是 `do-while` 循环

```
# assumes %bx has loop count in it

.main
.top
# critical section
mov 2000, %ax  # get 'value' at address 2000
add $1, %ax    # increment it
mov %ax, 2000  # store it back

# see if we're still looping
sub  $1, %bx
test $0, %bx
jgt .top

halt
```

按照题目的要求运行，bx 寄存器默认值为 0 ，因此 ax 寄存器加 1 的操作只会执行一次
- 单线程
- 跟踪内存地址 2000
- `-R bx` 跟踪寄存器 bx

```bash
./x86.py -p looping-race-nolock.s -t 1 -M 2000 -R bx -c

# 输出
 2000      ax    bx          Thread 0         
    0       0     0   
    0       0     0   1000 mov 2000, %ax
    0       1     0   1001 add $1, %ax
    1       1     0   1002 mov %ax, 2000
    1       1    -1   1003 sub  $1, %bx
    1       1    -1   1004 test $0, %bx
    1       1    -1   1005 jgt .top
    1       1    -1   1006 halt
```

### 5

使用 2 个线程，循环 3 次
- 默认每 50 条指令产生一次中断，因此这里不会有中断，线程按顺序执行，最终 ax 寄存器中的值为 6

```bash
./x86.py -p looping-race-nolock.s -t 2 -a bx=3 -M 2000 -R ax,bx -c

# 输出
 2000      ax    bx          Thread 0                Thread 1         
    0       0     3   
    0       0     3   1000 mov 2000, %ax
    0       1     3   1001 add $1, %ax
    1       1     3   1002 mov %ax, 2000
    1       1     2   1003 sub  $1, %bx
    1       1     2   1004 test $0, %bx
    1       1     2   1005 jgt .top
    1       1     2   1000 mov 2000, %ax
    1       2     2   1001 add $1, %ax
    2       2     2   1002 mov %ax, 2000
    2       2     1   1003 sub  $1, %bx
    2       2     1   1004 test $0, %bx
    2       2     1   1005 jgt .top
    2       2     1   1000 mov 2000, %ax
    2       3     1   1001 add $1, %ax
    3       3     1   1002 mov %ax, 2000
    3       3     0   1003 sub  $1, %bx
    3       3     0   1004 test $0, %bx
    3       3     0   1005 jgt .top
    3       3     0   1006 halt
    3       0     3   ----- Halt;Switch -----  ----- Halt;Switch -----  
    3       3     3                            1000 mov 2000, %ax
    3       4     3                            1001 add $1, %ax
    4       4     3                            1002 mov %ax, 2000
    4       4     2                            1003 sub  $1, %bx
    4       4     2                            1004 test $0, %bx
    4       4     2                            1005 jgt .top
    4       4     2                            1000 mov 2000, %ax
    4       5     2                            1001 add $1, %ax
    5       5     2                            1002 mov %ax, 2000
    5       5     1                            1003 sub  $1, %bx
    5       5     1                            1004 test $0, %bx
    5       5     1                            1005 jgt .top
    5       5     1                            1000 mov 2000, %ax
    5       6     1                            1001 add $1, %ax
    6       6     1                            1002 mov %ax, 2000
    6       6     0                            1003 sub  $1, %bx
    6       6     0                            1004 test $0, %bx
    6       6     0                            1005 jgt .top
    6       6     0                            1006 halt
```

### 6

随机且每 4 条指令产生一次中断
- 至多执行 4 条指令后产生中断


bx 寄存器的值默认为 0 ，如果两个线程按顺序执行，那么每个线程的循环部分都只执行一次，最终地址 2000 的值应该是 2 。

1. 随机种子为 0

增加内存地址 2000 的值，递减 bx 中的值，然后中断，最后再测试条件；
没有产生读写旧值的情况，因此运行结果正确。

```bash
./x86.py -p looping-race-nolock.s -t 2 -i 4 -r -s 0 -M 2000 -R ax,bx -c

# 输出
 2000      ax    bx          Thread 0                Thread 1         
    0       0     0   
    0       0     0   1000 mov 2000, %ax
    0       1     0   1001 add $1, %ax
    1       1     0   1002 mov %ax, 2000
    1       1    -1   1003 sub  $1, %bx
    1       0     0   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0                            1000 mov 2000, %ax
    1       2     0                            1001 add $1, %ax
    2       2     0                            1002 mov %ax, 2000
    2       2    -1                            1003 sub  $1, %bx
    2       1    -1   ------ Interrupt ------  ------ Interrupt ------  
    2       1    -1   1004 test $0, %bx
    2       1    -1   1005 jgt .top
    2       2    -1   ------ Interrupt ------  ------ Interrupt ------  
    2       2    -1                            1004 test $0, %bx
    2       2    -1                            1005 jgt .top
    2       1    -1   ------ Interrupt ------  ------ Interrupt ------  
    2       1    -1   1006 halt
    2       2    -1   ----- Halt;Switch -----  ----- Halt;Switch -----  
    2       2    -1                            1006 halt
```

2. 随机种子为 1

线程 0 读取内存地址 2000 的值后就被中断，线程 1 对旧值（本来应该由线程 0 更新）进行读写，并将 bx 寄存器的值减一；
中断后切换回线程 0 ，此时线程 0 并不知道内存地址 2000 的值已经更新，而对它的 ax 寄存器中旧值进行操作，结果是覆盖了线程 1 写的值；
bx 寄存器中的值不受影响，两个线程都只执行一次，最后的结果错误，为 1 。

```bash
./x86.py -p looping-race-nolock.s -t 2 -i 4 -r -s 1 -M 2000 -R ax,bx -c

# 输出
 2000      ax    bx          Thread 0                Thread 1         
    0       0     0   
    0       0     0   1000 mov 2000, %ax
    0       0     0   ------ Interrupt ------  ------ Interrupt ------  
    0       0     0                            1000 mov 2000, %ax
    0       1     0                            1001 add $1, %ax
    1       1     0                            1002 mov %ax, 2000
    1       1    -1                            1003 sub  $1, %bx
    1       0     0   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0   1001 add $1, %ax
    1       1     0   1002 mov %ax, 2000
    1       1    -1   1003 sub  $1, %bx
    1       1    -1   1004 test $0, %bx
    1       1    -1   ------ Interrupt ------  ------ Interrupt ------  
    1       1    -1                            1004 test $0, %bx
    1       1    -1                            1005 jgt .top
    1       1    -1   ------ Interrupt ------  ------ Interrupt ------  
    1       1    -1   1005 jgt .top
    1       1    -1   1006 halt
    1       1    -1   ----- Halt;Switch -----  ----- Halt;Switch -----  
    1       1    -1   ------ Interrupt ------  ------ Interrupt ------  
    1       1    -1                            1006 halt
```

3. 随机种子为 2
   
和随机种子为 0 时的过程差不多，唯一的区别在是在比较和跳转之间中断，并不影响线程运行的正确性，因此最后的结果是正确的。
- 线程拥有自己的上下文

```bash
./x86.py -p looping-race-nolock.s -t 2 -i 4 -r -s 2 -M 2000 -R ax,bx -c

# 输出
 2000      ax    bx          Thread 0                Thread 1         
    0       0     0   
    0       0     0   1000 mov 2000, %ax
    0       1     0   1001 add $1, %ax
    1       1     0   1002 mov %ax, 2000
    1       1    -1   1003 sub  $1, %bx
    1       0     0   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0                            1000 mov 2000, %ax
    1       2     0                            1001 add $1, %ax
    2       2     0                            1002 mov %ax, 2000
    2       2    -1                            1003 sub  $1, %bx
    2       1    -1   ------ Interrupt ------  ------ Interrupt ------  
    2       1    -1   1004 test $0, %bx
    2       2    -1   ------ Interrupt ------  ------ Interrupt ------  
    2       2    -1                            1004 test $0, %bx
    2       1    -1   ------ Interrupt ------  ------ Interrupt ------  
    2       1    -1   1005 jgt .top
    2       1    -1   1006 halt
    2       2    -1   ----- Halt;Switch -----  ----- Halt;Switch -----  
    2       2    -1                            1005 jgt .top
    2       2    -1                            1006 halt
```

### 7

bx 寄存器的值为 1，如果两个线程按顺序执行，那么每个线程都只执行一次，最终地址 2000 的值应该是 2 。

1. 每 1 条指令产生一次中断

每个线程的 ax 寄存器都保留着旧值，写内存地址 2000 时产生了覆盖，因此最后获得的结果是错误的 1 。

```bash
./x86.py -p looping-race-nolock.s -t 2 -a bx=1 -i 1 -M 2000 -R ax,bx -c

# 输出
 2000      ax    bx          Thread 0                Thread 1         
    0       0     1   
    0       0     1   1000 mov 2000, %ax
    0       0     1   ------ Interrupt ------  ------ Interrupt ------  
    0       0     1                            1000 mov 2000, %ax
    0       0     1   ------ Interrupt ------  ------ Interrupt ------  
    0       1     1   1001 add $1, %ax
    0       0     1   ------ Interrupt ------  ------ Interrupt ------  
    0       1     1                            1001 add $1, %ax
    0       1     1   ------ Interrupt ------  ------ Interrupt ------  
    1       1     1   1002 mov %ax, 2000
    1       1     1   ------ Interrupt ------  ------ Interrupt ------  
    1       1     1                            1002 mov %ax, 2000
    1       1     1   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0   1003 sub  $1, %bx
    1       1     1   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0                            1003 sub  $1, %bx
    1       1     0   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0   1004 test $0, %bx
    1       1     0   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0                            1004 test $0, %bx
    1       1     0   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0   1005 jgt .top
    1       1     0   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0                            1005 jgt .top
    1       1     0   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0   1006 halt
    1       1     0   ----- Halt;Switch -----  ----- Halt;Switch -----  
    1       1     0   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0                            1006 halt
```

2. 每 2 条指令产生一次中断

已经把内存地址 2000 中的值读入 ax 寄存器并增加了 1 ，但是还没有写回内存时被中断，仍然是产生了写覆盖的问题，结果内存地址 2000 的值仍然是错误的，为 1 。

```bash
./x86.py -p looping-race-nolock.s -t 2 -a bx=1 -i 2 -M 2000 -R ax,bx -c

# 输出
 2000      ax    bx          Thread 0                Thread 1         
    0       0     1   
    0       0     1   1000 mov 2000, %ax
    0       1     1   1001 add $1, %ax
    0       0     1   ------ Interrupt ------  ------ Interrupt ------  
    0       0     1                            1000 mov 2000, %ax
    0       1     1                            1001 add $1, %ax
    0       1     1   ------ Interrupt ------  ------ Interrupt ------  
    1       1     1   1002 mov %ax, 2000
    1       1     0   1003 sub  $1, %bx
    1       1     1   ------ Interrupt ------  ------ Interrupt ------  
    1       1     1                            1002 mov %ax, 2000
    1       1     0                            1003 sub  $1, %bx
    1       1     0   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0   1004 test $0, %bx
    1       1     0   1005 jgt .top
    1       1     0   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0                            1004 test $0, %bx
    1       1     0                            1005 jgt .top
    1       1     0   ------ Interrupt ------  ------ Interrupt ------  
    1       1     0   1006 halt
    1       1     0   ----- Halt;Switch -----  ----- Halt;Switch -----  
    1       1     0                            1006 halt
```

3. 每 3 条指令产生一次中断

已经对内存地址 2000 的值进行了更新（并写回），因此中断不影响运行逻辑，寄存器 bx 不受影响（进而不会影响循环），因此最后的结果正确，为 2 。

```bash
./x86.py -p looping-race-nolock.s -t 2 -a bx=1 -i 3 -M 2000 -R bx -c

# 输出
 2000      bx          Thread 0                Thread 1         
    0       1   
    0       1   1000 mov 2000, %ax
    0       1   1001 add $1, %ax
    1       1   1002 mov %ax, 2000
    1       1   ------ Interrupt ------  ------ Interrupt ------  
    1       1                            1000 mov 2000, %ax
    1       1                            1001 add $1, %ax
    2       1                            1002 mov %ax, 2000
    2       1   ------ Interrupt ------  ------ Interrupt ------  
    2       0   1003 sub  $1, %bx
    2       0   1004 test $0, %bx
    2       0   1005 jgt .top
    2       1   ------ Interrupt ------  ------ Interrupt ------  
    2       0                            1003 sub  $1, %bx
    2       0                            1004 test $0, %bx
    2       0                            1005 jgt .top
    2       0   ------ Interrupt ------  ------ Interrupt ------  
    2       0   1006 halt
    2       0   ----- Halt;Switch -----  ----- Halt;Switch -----  
    2       0                            1006 halt
```

### 8

显然，只要保证数据更新并写回内存地址后再中断，就不会产生数据覆盖问题，对于 looping-race-nolock.s 程序，只需要确保前三条语句（临界区）始终是一起执行的（原子的）即可。

```bash
mov 2000, %ax  # get 'value' at address 2000
add $1, %ax    # increment it
mov %ax, 2000  # store it back
```

### 9

查看 wait-for-me.s 中的指令序列，
- `je`：`jump if equal` 等于时跳转
- `jne`：`jump if not equal` 不等于时跳转

```
.main
test $1, %ax     # ax should be 1 (signaller) or 0 (waiter)
je .signaller

.waiter
mov  2000, %cx
test $1, %cx
jne .waiter
halt

.signaller
mov  $1, 2000
halt
```

按照题目要求运行
- 省略了 `-t 2` ，根据 `-a ax=1,ax=0` 设置 2 个线程的 ax 寄存器初始值
- ax 寄存器的值为 1 则运行 .signaller 部分代码，否则运行 .waiter 部分代码
- 内存地址 2000 的初始默认值为 0

线程 0 先运行，由于 ax 寄存器的值为 1 ，运行 .signaller 部分代码，将内存地址 2000 的值设置为 1；
挂起后切换线程 1 运行，ax 寄存器的值为 0，运行 .waiter 部分代码，内存地址 2000 的值为 1 ，挂起；
两个线程都挂起了:(

```bash
./x86.py -p wait-for-me.s -a ax=1,ax=0 -M 2000 -R ax -c

# 输出
 2000      ax          Thread 0                Thread 1         
    0       1   
    0       1   1000 test $1, %ax
    0       1   1001 je .signaller
    1       1   1006 mov  $1, 2000
    1       1   1007 halt
    1       0   ----- Halt;Switch -----  ----- Halt;Switch -----  
    1       0                            1000 test $1, %ax
    1       0                            1001 je .signaller
    1       0                            1002 mov  2000, %cx
    1       0                            1003 test $1, %cx
    1       0                            1004 jne .waiter
    1       0                            1005 halt
```


### 10

将两个线程的 ax 寄存器初始值交换
- 内存地址 2000 的初始默认值为 0
- 线程 0 的 ax 寄存器值为 0 ，运行 .waiter 部分代码，内存地址 2000 的值为 0 （不等于 1），继续运行
.waiter 部分代码，然后不断循环直到产生中断；【自旋等待】
- 线程 1 的 ax 寄存器的值为 1 ，运行 .signaller 部分代码，将内存地址 2000 的值设置为 1；
- 挂起切换到线程 0 ，线程 0 的 ax 寄存器值为 0 ，运行 .waiter 部分代码，内存地址 2000 的值为 1 ，挂起。

```bash
./x86.py -p wait-for-me.s -a ax=0,ax=1 -M 2000 -R ax -c

# 输出
 2000      ax          Thread 0                Thread 1         
    0       0   
    0       0   1000 test $1, %ax
    0       0   1001 je .signaller
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       1   ------ Interrupt ------  ------ Interrupt ------  
    0       1                            1000 test $1, %ax
    0       1                            1001 je .signaller
    1       1                            1006 mov  $1, 2000
    1       1                            1007 halt
    1       0   ----- Halt;Switch -----  ----- Halt;Switch -----  
    1       0   1002 mov  2000, %cx
    1       0   1003 test $1, %cx
    1       0   1004 jne .waiter
    1       0   1005 halt
```


改变中断间隔，每执行 1000 条指令产生一次中断
- 让线程 0 自旋等待，直到线程 1 改变了内存地址 2000 的值

<details>
  <summary>输出太长了，折一下_(´ཀ`」∠)_</summary>

```bash
./x86.py -p wait-for-me.s -a ax=0,ax=1 -i 1000 -M 2000 -R ax -c

# 输出
 2000      ax          Thread 0                Thread 1         
    0       0   
    0       0   1000 test $1, %ax
    0       0   1001 je .signaller
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       0   1004 jne .waiter
    0       0   1002 mov  2000, %cx
    0       0   1003 test $1, %cx
    0       1   ------ Interrupt ------  ------ Interrupt ------  
    0       1                            1000 test $1, %ax
    0       1                            1001 je .signaller
    1       1                            1006 mov  $1, 2000
    1       1                            1007 halt
    1       0   ----- Halt;Switch -----  ----- Halt;Switch -----  
    1       0   1004 jne .waiter
    1       0   1002 mov  2000, %cx
    1       0   1003 test $1, %cx
    1       0   1004 jne .waiter
    1       0   1005 halt
```
</details>